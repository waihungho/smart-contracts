```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Gemini AI (Conceptual Example)
 * @dev A smart contract for a Decentralized Autonomous Art Collective, enabling artists, curators, and collectors to interact in a novel way.
 *
 * **Outline and Function Summary:**
 *
 * **Core Art Management:**
 *  1. `submitArtwork(string _artworkCID, string _metadataCID, uint256 _royaltyPercentage)`: Allows members to submit artwork proposals to the collective.
 *  2. `voteOnArtwork(uint256 _submissionId, VoteType _vote)`: Curators vote on submitted artworks to decide if they are accepted into the collective.
 *  3. `mintArtworkNFT(uint256 _submissionId)`: Mints an NFT for an approved artwork, representing ownership and collective recognition.
 *  4. `setArtworkMetadata(uint256 _artworkId, string _newMetadataCID)`: Allows updating the metadata of an existing artwork NFT (governance-controlled).
 *  5. `burnArtworkNFT(uint256 _artworkId)`: Allows the collective to burn an artwork NFT under specific governance conditions.
 *  6. `reportArtwork(uint256 _artworkId, string _reportReason)`: Members can report artworks for policy violations or copyright concerns.
 *  7. `resolveArtworkReport(uint256 _reportId, ReportResolution _resolution)`: Curators resolve artwork reports through voting.
 *
 * **Governance & Collective Control:**
 *  8. `proposeNewCurator(address _candidateAddress)`: Members can propose new curators to join the collective.
 *  9. `voteOnCuratorProposal(uint256 _proposalId, VoteType _vote)`: Existing curators vote on new curator proposals.
 *  10. `removeCurator(address _curatorAddress)`:  Curators can be removed through a governance proposal and voting process.
 *  11. `proposeParameterChange(string _parameterName, uint256 _newValue)`: Allows proposing changes to key contract parameters (e.g., voting durations, fees).
 *  12. `voteOnParameterChange(uint256 _proposalId, VoteType _vote)`: Members vote on parameter change proposals.
 *  13. `delegateVotingPower(address _delegateAddress)`: Members can delegate their voting power to another member.
 *  14. `revokeVotingDelegation()`: Members can revoke their voting power delegation.
 *
 * **Treasury & Financial Functions:**
 *  15. `depositToTreasury()`: Allows anyone to deposit ETH into the collective's treasury.
 *  16. `proposeTreasurySpending(address _recipient, uint256 _amount, string _reason)`:  Members can propose spending funds from the treasury.
 *  17. `voteOnTreasurySpending(uint256 _proposalId, VoteType _vote)`: Members vote on treasury spending proposals.
 *  18. `withdrawFromTreasury(uint256 _proposalId)`: Executes a treasury withdrawal after a successful spending proposal vote.
 *  19. `setPlatformFee(uint256 _newFeePercentage)`:  Allows setting a platform fee for artwork sales or future features (governance-controlled).
 *
 * **Community & Utility Functions:**
 *  20. `joinCollective()`: Allows artists to request membership in the collective.
 *  21. `approveMembership(address _memberAddress)`: Curators approve membership requests.
 *  22. `leaveCollective()`: Allows members to leave the collective.
 *  23. `getArtworkDetails(uint256 _artworkId)`: Retrieves detailed information about a specific artwork.
 *  24. `getProposalDetails(uint256 _proposalId)`: Retrieves details of a specific governance proposal.
 *  25. `emergencyPause(string _reason)`: Owner-controlled emergency pause function to halt critical operations.
 *  26. `emergencyUnpause()`: Owner-controlled unpause function to resume operations.
 */

contract DecentralizedArtCollective {
    // --- Enums and Structs ---

    enum ArtworkStatus { Pending, Approved, Rejected, Minted, Reported, Burned }
    enum VoteType { Approve, Reject, Abstain }
    enum ProposalStatus { Pending, Active, Passed, Rejected, Executed }
    enum ReportResolution { Pending, Resolved, Rejected }

    struct ArtworkSubmission {
        address artist;
        string artworkCID; // IPFS CID for the artwork file
        string metadataCID; // IPFS CID for artwork metadata (title, description, etc.)
        uint256 royaltyPercentage;
        ArtworkStatus status;
        uint256 submissionTimestamp;
        uint256 upvotes;
        uint256 downvotes;
    }

    struct Proposal {
        ProposalType proposalType;
        address proposer;
        ProposalStatus status;
        uint256 startTime;
        uint256 endTime;
        uint256 upvotes;
        uint256 downvotes;
        bytes proposalData; // Generic data field to store proposal-specific information
    }

    enum ProposalType {
        CuratorAddition,
        CuratorRemoval,
        ParameterChange,
        TreasurySpending,
        ArtworkReportResolution
    }

    struct Report {
        uint256 artworkId;
        address reporter;
        string reason;
        ReportResolution resolutionStatus;
        uint256 resolutionProposalId; // ID of the proposal to resolve this report
    }


    // --- State Variables ---

    address public owner;
    address[] public curators;
    mapping(address => bool) public isCurator;
    mapping(address => bool) public isMember;
    mapping(address => address) public votingDelegation; // Member -> Delegate address

    uint256 public artworkSubmissionCounter;
    mapping(uint256 => ArtworkSubmission) public artworkSubmissions;
    mapping(uint256 => mapping(address => VoteType)) public artworkVotes; // submissionId => voter => vote

    uint256 public proposalCounter;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => VoteType)) public proposalVotes; // proposalId => voter => vote

    uint256 public reportCounter;
    mapping(uint256 => Report) public artworkReports;
    mapping(uint256 => mapping(address => VoteType)) public reportVotes; // reportId => voter => vote

    mapping(uint256 => address) public artworkNFTs; // artworkId => NFT contract address (if we were integrating NFTs)
    uint256 public treasuryBalance;
    uint256 public platformFeePercentage = 5; // Default platform fee percentage

    uint256 public votingDuration = 7 days; // Default voting duration
    uint256 public curatorVotingThreshold = 50; // Percentage threshold for curator votes to pass artwork submissions
    uint256 public governanceVotingThreshold = 60; // Percentage threshold for governance proposals

    bool public paused = false;

    // --- Events ---

    event ArtworkSubmitted(uint256 submissionId, address artist, string artworkCID, string metadataCID);
    event ArtworkVotedOn(uint256 submissionId, address curator, VoteType vote);
    event ArtworkMinted(uint256 artworkId, address nftContractAddress); // In a real scenario, would emit NFT contract address
    event ArtworkMetadataUpdated(uint256 artworkId, string newMetadataCID);
    event ArtworkBurned(uint256 artworkId);
    event ArtworkReported(uint256 reportId, uint256 artworkId, address reporter, string reason);
    event ArtworkReportResolved(uint256 reportId, ReportResolution resolution);

    event CuratorProposed(uint256 proposalId, address candidateAddress, address proposer);
    event CuratorProposalVotedOn(uint256 proposalId, address curator, VoteType vote);
    event CuratorAdded(address curatorAddress);
    event CuratorRemoved(address curatorAddress);

    event ParameterChangeProposed(uint256 proposalId, string parameterName, uint256 newValue, address proposer);
    event ParameterChangeVotedOn(uint256 proposalId, address voter, VoteType vote);
    event ParameterChanged(string parameterName, uint256 newValue);

    event TreasuryDeposit(address sender, uint256 amount);
    event TreasurySpendingProposed(uint256 proposalId, address recipient, uint256 amount, string reason, address proposer);
    event TreasurySpendingVotedOn(uint256 proposalId, address voter, VoteType vote);
    event TreasuryWithdrawal(uint256 proposalId, address recipient, uint256 amount);

    event VotingPowerDelegated(address delegator, address delegate);
    event VotingPowerRevoked(address delegator);

    event MembershipRequested(address memberAddress);
    event MembershipApproved(address memberAddress);
    event MemberLeft(address memberAddress);

    event EmergencyPaused(string reason);
    event EmergencyUnpaused();


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyCurator() {
        require(isCurator[msg.sender], "Only curators can call this function.");
        _;
    }

    modifier onlyMember() {
        require(isMember[msg.sender], "Only members can call this function.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier validSubmissionId(uint256 _submissionId) {
        require(_submissionId > 0 && _submissionId <= artworkSubmissionCounter, "Invalid submission ID.");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCounter, "Invalid proposal ID.");
        _;
    }

    modifier validReportId(uint256 _reportId) {
        require(_reportId > 0 && _reportId <= reportCounter, "Invalid report ID.");
        _;
    }


    // --- Constructor ---

    constructor(address[] memory _initialCurators) payable {
        owner = msg.sender;
        treasuryBalance = msg.value;
        for (uint256 i = 0; i < _initialCurators.length; i++) {
            curators.push(_initialCurators[i]);
            isCurator[_initialCurators[i]] = true;
        }
    }

    // --- Core Art Management Functions ---

    /// @notice Allows members to submit artwork proposals to the collective.
    /// @param _artworkCID IPFS CID of the artwork file.
    /// @param _metadataCID IPFS CID of the artwork metadata.
    /// @param _royaltyPercentage Percentage of future sales royalties the artist should receive (0-100).
    function submitArtwork(string memory _artworkCID, string memory _metadataCID, uint256 _royaltyPercentage)
        external
        onlyMember
        notPaused
    {
        require(_royaltyPercentage <= 100, "Royalty percentage must be between 0 and 100.");
        artworkSubmissionCounter++;
        artworkSubmissions[artworkSubmissionCounter] = ArtworkSubmission({
            artist: msg.sender,
            artworkCID: _artworkCID,
            metadataCID: _metadataCID,
            royaltyPercentage: _royaltyPercentage,
            status: ArtworkStatus.Pending,
            submissionTimestamp: block.timestamp,
            upvotes: 0,
            downvotes: 0
        });
        emit ArtworkSubmitted(artworkSubmissionCounter, msg.sender, _artworkCID, _metadataCID);
    }

    /// @notice Curators vote on submitted artworks.
    /// @param _submissionId ID of the artwork submission.
    /// @param _vote Type of vote (Approve, Reject, Abstain).
    function voteOnArtwork(uint256 _submissionId, VoteType _vote)
        external
        onlyCurator
        validSubmissionId(_submissionId)
        notPaused
    {
        require(artworkSubmissions[_submissionId].status == ArtworkStatus.Pending, "Artwork is not pending review.");
        require(proposalVotes[_submissionId][msg.sender] == VoteType.Abstain, "Already voted on this artwork."); // Prevent double voting

        proposalVotes[_submissionId][msg.sender] = _vote; // Record curator's vote

        if (_vote == VoteType.Approve) {
            artworkSubmissions[_submissionId].upvotes++;
        } else if (_vote == VoteType.Reject) {
            artworkSubmissions[_submissionId].downvotes++;
        }

        emit ArtworkVotedOn(_submissionId, msg.sender, _vote);

        // Check if voting threshold reached (simplified logic - can be refined)
        uint256 totalCurators = curators.length;
        uint256 approvalVotes = 0;
        for (uint256 i = 0; i < totalCurators; i++) {
            if (proposalVotes[_submissionId][curators[i]] == VoteType.Approve) {
                approvalVotes++;
            }
        }

        if ((approvalVotes * 100) / totalCurators >= curatorVotingThreshold) {
            artworkSubmissions[_submissionId].status = ArtworkStatus.Approved;
        } else if (((totalCurators - approvalVotes) * 100) / totalCurators > (100 - curatorVotingThreshold)) { // Check reject threshold
            artworkSubmissions[_submissionId].status = ArtworkStatus.Rejected;
        }
        // In a real system, you might want a more robust voting completion mechanism (e.g., time-based, quorum-based)
    }

    /// @notice Mints an NFT for an approved artwork. (Conceptual - in reality, would integrate with an NFT contract)
    /// @param _submissionId ID of the approved artwork submission.
    function mintArtworkNFT(uint256 _submissionId)
        external
        onlyCurator
        validSubmissionId(_submissionId)
        notPaused
    {
        require(artworkSubmissions[_submissionId].status == ArtworkStatus.Approved, "Artwork must be approved to mint NFT.");
        artworkSubmissions[_submissionId].status = ArtworkStatus.Minted;
        // In a real implementation, this function would:
        // 1. Deploy or interact with an existing NFT contract.
        // 2. Mint an NFT representing the artwork, potentially linking metadata from artworkSubmissions[_submissionId].metadataCID.
        // 3. Store the NFT contract address in artworkNFTs[_submissionId].
        address mockNFTContractAddress = address(uint160(submissionIdToAddress(_submissionId))); // Mock address for demonstration
        artworkNFTs[_submissionId] = mockNFTContractAddress; // Store mock NFT contract address
        emit ArtworkMinted(_submissionId, mockNFTContractAddress);
    }

    // Mock function to generate a different address based on submission ID (for demonstration)
    function submissionIdToAddress(uint256 _submissionId) private pure returns (address) {
        return address(uint160(keccak256(abi.encodePacked(_submissionId))));
    }


    /// @notice Allows updating the metadata of an existing artwork NFT (governance-controlled).
    /// @param _artworkId ID of the artwork.
    /// @param _newMetadataCID New IPFS CID for the artwork metadata.
    function setArtworkMetadata(uint256 _artworkId, string memory _newMetadataCID)
        external
        onlyCurator // Example: Curators control metadata updates, could be different governance mechanism
        notPaused
    {
        require(artworkNFTs[_artworkId] != address(0), "Artwork must have an NFT minted."); // Ensure NFT exists (mock check)
        // In a real implementation, this would likely involve updating metadata on the NFT contract.
        artworkSubmissions[_artworkId].metadataCID = _newMetadataCID; // Update metadata CID in our record
        emit ArtworkMetadataUpdated(_artworkId, _newMetadataCID);
    }

    /// @notice Allows the collective to burn an artwork NFT under specific governance conditions.
    /// @param _artworkId ID of the artwork to burn.
    function burnArtworkNFT(uint256 _artworkId)
        external
        onlyCurator // Example: Curators initiate burns, could be different governance mechanism
        notPaused
    {
        require(artworkNFTs[_artworkId] != address(0), "Artwork must have an NFT minted to be burned."); // Ensure NFT exists (mock check)
        // In a real implementation, this would involve calling a burn function on the NFT contract.
        artworkSubmissions[_artworkId].status = ArtworkStatus.Burned;
        emit ArtworkBurned(_artworkId);
        delete artworkNFTs[_artworkId]; // Remove NFT mapping (mock cleanup)
    }

    /// @notice Members can report artworks for policy violations or copyright concerns.
    /// @param _artworkId ID of the artwork being reported.
    /// @param _reportReason Reason for reporting the artwork.
    function reportArtwork(uint256 _artworkId, string memory _reportReason)
        external
        onlyMember
        notPaused
    {
        require(artworkNFTs[_artworkId] != address(0), "Artwork must have an NFT minted to be reported."); // Ensure NFT exists (mock check)
        reportCounter++;
        artworkReports[reportCounter] = Report({
            artworkId: _artworkId,
            reporter: msg.sender,
            reason: _reportReason,
            resolutionStatus: ReportResolution.Pending,
            resolutionProposalId: 0 // Will be set when a resolution proposal is created
        });
        artworkSubmissions[_artworkId].status = ArtworkStatus.Reported;
        emit ArtworkReported(reportCounter, _artworkId, msg.sender, _reportReason);
    }

    /// @notice Curators resolve artwork reports through voting.
    /// @param _reportId ID of the artwork report.
    /// @param _resolution Resolution of the report (Resolved, Rejected).
    function resolveArtworkReport(uint256 _reportId, ReportResolution _resolution)
        external
        onlyCurator
        validReportId(_reportId)
        notPaused
    {
        require(artworkReports[_reportId].resolutionStatus == ReportResolution.Pending, "Report already resolved.");

        proposalCounter++;
        proposals[proposalCounter] = Proposal({
            proposalType: ProposalType.ArtworkReportResolution,
            proposer: msg.sender,
            status: ProposalStatus.Active,
            startTime: block.timestamp,
            endTime: block.timestamp + votingDuration,
            upvotes: 0,
            downvotes: 0,
            proposalData: abi.encode(_reportId, _resolution) // Store report ID and resolution in proposal data
        });
        artworkReports[_reportId].resolutionProposalId = proposalCounter;

        // Start voting process for curators on the resolution proposal (similar to voteOnArtwork logic)
        // ... (Implementation of curator voting on report resolution would go here)
        // For simplicity, we are skipping the voting logic in this example and just setting the resolution directly.
        artworkReports[_reportId].resolutionStatus = _resolution;
        emit ArtworkReportResolved(_reportId, _resolution);

        if (_resolution == ReportResolution.Resolved) {
            // Actions upon resolution (e.g., burn artwork, remove from platform, etc.)
            burnArtworkNFT(artworkReports[_reportId].artworkId); // Example: Burn the artwork if report is resolved
        } else {
            artworkSubmissions[artworkReports[_reportId].artworkId].status = ArtworkStatus.Minted; // Revert status if rejected
        }

    }


    // --- Governance & Collective Control Functions ---

    /// @notice Allows members to propose new curators to join the collective.
    /// @param _candidateAddress Address of the curator candidate.
    function proposeNewCurator(address _candidateAddress)
        external
        onlyMember
        notPaused
    {
        require(!isCurator[_candidateAddress], "Address is already a curator.");
        proposalCounter++;
        proposals[proposalCounter] = Proposal({
            proposalType: ProposalType.CuratorAddition,
            proposer: msg.sender,
            status: ProposalStatus.Active,
            startTime: block.timestamp,
            endTime: block.timestamp + votingDuration,
            upvotes: 0,
            downvotes: 0,
            proposalData: abi.encode(_candidateAddress) // Store candidate address in proposal data
        });
        emit CuratorProposed(proposalCounter, _candidateAddress, msg.sender);
    }

    /// @notice Existing curators vote on new curator proposals.
    /// @param _proposalId ID of the curator addition proposal.
    /// @param _vote Type of vote (Approve, Reject, Abstain).
    function voteOnCuratorProposal(uint256 _proposalId, VoteType _vote)
        external
        onlyCurator
        validProposalId(_proposalId)
        notPaused
    {
        require(proposals[_proposalId].proposalType == ProposalType.CuratorAddition, "Invalid proposal type.");
        require(proposals[_proposalId].status == ProposalStatus.Active, "Proposal is not active.");
        require(proposalVotes[_proposalId][msg.sender] == VoteType.Abstain, "Already voted on this proposal."); // Prevent double voting

        proposalVotes[_proposalId][msg.sender] = _vote; // Record curator's vote

        if (_vote == VoteType.Approve) {
            proposals[_proposalId].upvotes++;
        } else if (_vote == VoteType.Reject) {
            proposals[_proposalId].downvotes++;
        }

        emit CuratorProposalVotedOn(_proposalId, msg.sender, _vote);

        if (block.timestamp > proposals[_proposalId].endTime) {
            proposals[_proposalId].status = ProposalStatus.Rejected; // Default to rejected if voting ends without quorum
            uint256 totalCurators = curators.length;
            uint256 approvalVotes = proposals[_proposalId].upvotes;
            if ((approvalVotes * 100) / totalCurators >= governanceVotingThreshold) {
                proposals[_proposalId].status = ProposalStatus.Passed;
                address candidateAddress = abi.decode(proposals[_proposalId].proposalData, (address));
                _addCurator(candidateAddress);
                proposals[_proposalId].status = ProposalStatus.Executed;
            }
        }
    }

    /// @dev Internal function to add a curator.
    function _addCurator(address _curatorAddress) private {
        curators.push(_curatorAddress);
        isCurator[_curatorAddress] = true;
        emit CuratorAdded(_curatorAddress);
    }


    /// @notice Curators can be removed through a governance proposal and voting process.
    /// @param _curatorAddress Address of the curator to remove.
    function removeCurator(address _curatorAddress)
        external
        onlyCurator
        notPaused
    {
        require(isCurator[_curatorAddress], "Address is not a curator.");
        require(_curatorAddress != msg.sender, "Curator cannot propose to remove themselves."); // Prevent self-removal proposal

        proposalCounter++;
        proposals[proposalCounter] = Proposal({
            proposalType: ProposalType.CuratorRemoval,
            proposer: msg.sender,
            status: ProposalStatus.Active,
            startTime: block.timestamp,
            endTime: block.timestamp + votingDuration,
            upvotes: 0,
            downvotes: 0,
            proposalData: abi.encode(_curatorAddress) // Store curator address to remove in proposal data
        });
    }

    /// @notice Allows proposing changes to key contract parameters (e.g., voting durations, fees).
    /// @param _parameterName Name of the parameter to change (e.g., "votingDuration", "platformFeePercentage").
    /// @param _newValue New value for the parameter.
    function proposeParameterChange(string memory _parameterName, uint256 _newValue)
        external
        onlyMember
        notPaused
    {
        proposalCounter++;
        proposals[proposalCounter] = Proposal({
            proposalType: ProposalType.ParameterChange,
            proposer: msg.sender,
            status: ProposalStatus.Active,
            startTime: block.timestamp,
            endTime: block.timestamp + votingDuration,
            upvotes: 0,
            downvotes: 0,
            proposalData: abi.encode(_parameterName, _newValue) // Store parameter name and new value
        });
        emit ParameterChangeProposed(proposalCounter, _parameterName, _newValue, msg.sender);
    }

    /// @notice Members vote on parameter change proposals.
    /// @param _proposalId ID of the parameter change proposal.
    /// @param _vote Type of vote (Approve, Reject, Abstain).
    function voteOnParameterChange(uint256 _proposalId, VoteType _vote)
        external
        onlyMember // Members vote on parameter changes
        validProposalId(_proposalId)
        notPaused
    {
        require(proposals[_proposalId].proposalType == ProposalType.ParameterChange, "Invalid proposal type.");
        require(proposals[_proposalId].status == ProposalStatus.Active, "Proposal is not active.");
        require(proposalVotes[_proposalId][msg.sender] == VoteType.Abstain, "Already voted on this proposal."); // Prevent double voting

        address voter = votingDelegation[msg.sender] != address(0) ? votingDelegation[msg.sender] : msg.sender; // Use delegated vote if available
        proposalVotes[_proposalId][voter] = _vote; // Record vote (using delegated voter if applicable)

        if (_vote == VoteType.Approve) {
            proposals[_proposalId].upvotes++;
        } else if (_vote == VoteType.Reject) {
            proposals[_proposalId].downvotes++;
        }

        emit ParameterChangeVotedOn(_proposalId, msg.sender, _vote);

        if (block.timestamp > proposals[_proposalId].endTime) {
            proposals[_proposalId].status = ProposalStatus.Rejected; // Default to rejected if voting ends without quorum
            uint256 totalMembers = 0; // In a real system, track active members more effectively
            // Simplified member count - replace with actual member tracking if needed.
            // For demonstration, assume number of members is large enough for quorum consideration.
            uint256 approvalVotes = proposals[_proposalId].upvotes;

            // Simplified quorum check - replace with more robust quorum logic if needed
            if (approvalVotes > proposals[_proposalId].downvotes && (approvalVotes * 100 / (approvalVotes + proposals[_proposalId].downvotes)) >= governanceVotingThreshold) {
                proposals[_proposalId].status = ProposalStatus.Passed;
                (string memory parameterName, uint256 newValue) = abi.decode(proposals[_proposalId].proposalData, (string, uint256));
                _setParameter(parameterName, newValue);
                proposals[_proposalId].status = ProposalStatus.Executed;
            }
        }
    }

    /// @dev Internal function to set contract parameters.
    function _setParameter(string memory _parameterName, uint256 _newValue) private {
        if (keccak256(bytes(_parameterName)) == keccak256(bytes("votingDuration"))) {
            votingDuration = _newValue;
        } else if (keccak256(bytes(_parameterName)) == keccak256(bytes("platformFeePercentage"))) {
            platformFeePercentage = _newValue;
        } else if (keccak256(bytes(_parameterName)) == keccak256(bytes("curatorVotingThreshold"))) {
            curatorVotingThreshold = _newValue;
        } else if (keccak256(bytes(_parameterName)) == keccak256(bytes("governanceVotingThreshold"))) {
            governanceVotingThreshold = _newValue;
        }
        emit ParameterChanged(_parameterName, _newValue);
    }


    /// @notice Members can delegate their voting power to another member.
    /// @param _delegateAddress Address of the member to delegate voting power to.
    function delegateVotingPower(address _delegateAddress)
        external
        onlyMember
        notPaused
    {
        require(isMember[_delegateAddress], "Delegate address must be a member.");
        require(_delegateAddress != msg.sender, "Cannot delegate to yourself.");
        votingDelegation[msg.sender] = _delegateAddress;
        emit VotingPowerDelegated(msg.sender, _delegateAddress);
    }

    /// @notice Members can revoke their voting power delegation.
    function revokeVotingDelegation()
        external
        onlyMember
        notPaused
    {
        require(votingDelegation[msg.sender] != address(0), "No voting delegation in place.");
        delete votingDelegation[msg.sender];
        emit VotingPowerRevoked(msg.sender);
    }


    // --- Treasury & Financial Functions ---

    /// @notice Allows anyone to deposit ETH into the collective's treasury.
    function depositToTreasury() external payable notPaused {
        treasuryBalance += msg.value;
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    /// @notice Members can propose spending funds from the treasury.
    /// @param _recipient Address to receive the treasury funds.
    /// @param _amount Amount of ETH to spend (in wei).
    /// @param _reason Reason for the treasury spending.
    function proposeTreasurySpending(address _recipient, uint256 _amount, string memory _reason)
        external
        onlyMember
        notPaused
    {
        require(_recipient != address(0), "Invalid recipient address.");
        require(_amount > 0, "Amount must be greater than zero.");
        require(_amount <= treasuryBalance, "Insufficient treasury balance.");

        proposalCounter++;
        proposals[proposalCounter] = Proposal({
            proposalType: ProposalType.TreasurySpending,
            proposer: msg.sender,
            status: ProposalStatus.Active,
            startTime: block.timestamp,
            endTime: block.timestamp + votingDuration,
            upvotes: 0,
            downvotes: 0,
            proposalData: abi.encode(_recipient, _amount, _reason) // Store recipient, amount, and reason
        });
        emit TreasurySpendingProposed(proposalCounter, _recipient, _amount, _reason, msg.sender);
    }

    /// @notice Members vote on treasury spending proposals.
    /// @param _proposalId ID of the treasury spending proposal.
    /// @param _vote Type of vote (Approve, Reject, Abstain).
    function voteOnTreasurySpending(uint256 _proposalId, VoteType _vote)
        external
        onlyMember // Members vote on treasury spending
        validProposalId(_proposalId)
        notPaused
    {
        require(proposals[_proposalId].proposalType == ProposalType.TreasurySpending, "Invalid proposal type.");
        require(proposals[_proposalId].status == ProposalStatus.Active, "Proposal is not active.");
        require(proposalVotes[_proposalId][msg.sender] == VoteType.Abstain, "Already voted on this proposal."); // Prevent double voting

        address voter = votingDelegation[msg.sender] != address(0) ? votingDelegation[msg.sender] : msg.sender; // Use delegated vote if available
        proposalVotes[_proposalId][voter] = _vote; // Record vote (using delegated voter if applicable)

        if (_vote == VoteType.Approve) {
            proposals[_proposalId].upvotes++;
        } else if (_vote == VoteType.Reject) {
            proposals[_proposalId].downvotes++;
        }

        emit TreasurySpendingVotedOn(_proposalId, msg.sender, _vote);

        if (block.timestamp > proposals[_proposalId].endTime) {
            proposals[_proposalId].status = ProposalStatus.Rejected; // Default to rejected if voting ends without quorum
            uint256 totalMembers = 0; // Replace with actual member tracking if needed
            uint256 approvalVotes = proposals[_proposalId].upvotes;

            if (approvalVotes > proposals[_proposalId].downvotes && (approvalVotes * 100 / (approvalVotes + proposals[_proposalId].downvotes)) >= governanceVotingThreshold) {
                proposals[_proposalId].status = ProposalStatus.Passed;
                withdrawFromTreasury(_proposalId); // Execute withdrawal if passed
                proposals[_proposalId].status = ProposalStatus.Executed;
            }
        }
    }

    /// @notice Executes a treasury withdrawal after a successful spending proposal vote.
    /// @param _proposalId ID of the passed treasury spending proposal.
    function withdrawFromTreasury(uint256 _proposalId) private {
        require(proposals[_proposalId].status == ProposalStatus.Passed, "Proposal must be passed to withdraw.");
        require(proposals[_proposalId].proposalType == ProposalType.TreasurySpending, "Invalid proposal type for withdrawal.");

        (address recipient, uint256 amount, ) = abi.decode(proposals[_proposalId].proposalData, (address, uint256, string));
        require(amount <= treasuryBalance, "Insufficient treasury balance (post-vote check)."); // Re-check balance before transfer

        treasuryBalance -= amount;
        (bool success, ) = recipient.call{value: amount}(""); // Low-level call for ETH transfer
        require(success, "Treasury withdrawal failed.");

        emit TreasuryWithdrawal(_proposalId, recipient, amount);
    }

    /// @notice Allows setting a platform fee for artwork sales or future features (governance-controlled).
    /// @param _newFeePercentage New platform fee percentage (0-100).
    function setPlatformFee(uint256 _newFeePercentage)
        external
        onlyCurator // Example: Curators set platform fee, could be different governance mechanism
        notPaused
    {
        require(_newFeePercentage <= 100, "Platform fee percentage must be between 0 and 100.");
        platformFeePercentage = _newFeePercentage;
        emit ParameterChanged("platformFeePercentage", _newFeePercentage);
    }


    // --- Community & Utility Functions ---

    /// @notice Allows artists to request membership in the collective.
    function joinCollective() external notPaused {
        require(!isMember[msg.sender], "Already a member.");
        isMember[msg.sender] = true; // For simplicity, auto-approve membership in this example.
        // In a real system, you might have a membership application process and curator approval.
        emit MembershipRequested(msg.sender);
        emit MembershipApproved(msg.sender); // Auto-approve in this simplified version
    }

    /// @notice Curators approve membership requests (if membership is not auto-approved).
    /// @param _memberAddress Address of the member to approve.
    function approveMembership(address _memberAddress) external onlyCurator notPaused {
        require(!isMember[_memberAddress], "Address is already a member.");
        isMember[_memberAddress] = true;
        emit MembershipApproved(_memberAddress);
    }


    /// @notice Allows members to leave the collective.
    function leaveCollective() external onlyMember notPaused {
        require(isMember[msg.sender], "Not a member.");
        isMember[msg.sender] = false;
        delete votingDelegation[msg.sender]; // Revoke any delegation on leaving
        emit MemberLeft(msg.sender);
    }

    /// @notice Retrieves detailed information about a specific artwork.
    /// @param _artworkId ID of the artwork.
    /// @return ArtworkSubmission struct containing artwork details.
    function getArtworkDetails(uint256 _artworkId) external view validSubmissionId(_artworkId) returns (ArtworkSubmission memory) {
        return artworkSubmissions[_artworkId];
    }

    /// @notice Retrieves details of a specific governance proposal.
    /// @param _proposalId ID of the proposal.
    /// @return Proposal struct containing proposal details.
    function getProposalDetails(uint256 _proposalId) external view validProposalId(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }


    // --- Emergency Pause/Unpause Functions ---

    /// @notice Owner-controlled emergency pause function to halt critical operations.
    /// @param _reason Reason for pausing the contract.
    function emergencyPause(string memory _reason) external onlyOwner {
        paused = true;
        emit EmergencyPaused(_reason);
    }

    /// @notice Owner-controlled unpause function to resume operations.
    function emergencyUnpause() external onlyOwner {
        paused = false;
        emit EmergencyUnpaused();
    }

    // --- Fallback and Receive Functions ---

    receive() external payable {
        depositToTreasury(); // Allow direct ETH deposits to treasury
    }

    fallback() external {}
}
```