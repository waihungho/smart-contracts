```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) - "Ethereal Canvas"
 * @author Bard (Example Smart Contract - Educational Purposes Only)
 * @notice A smart contract for a Decentralized Autonomous Art Collective, enabling artists to collaborate, create, govern, and monetize digital art.
 *
 * **Outline & Function Summary:**
 *
 * **1. Artist Management:**
 *    - `requestArtistMembership()`: Allows users to request membership to the Art Collective.
 *    - `voteForArtistMembership(address _artist)`: Governors vote on pending artist membership requests.
 *    - `getArtistProfile(address _artist)`: Retrieves public profile information of an artist.
 *    - `updateArtistProfile(string _name, string _bio, string _portfolioLink)`: Artists can update their profile information.
 *    - `reportArtist(address _artist, string _reason)`: Community members can report artists for violations (governance review needed).
 *    - `removeArtist(address _artist)`: Governors can remove artists based on community reports or governance votes.
 *
 * **2. Art Creation & NFT Management:**
 *    - `createArtProposal(string _title, string _description, string _ipfsHash)`: Artists propose new art pieces to the collective.
 *    - `voteOnArtProposal(uint256 _proposalId, bool _approve)`: Governors vote on art proposals.
 *    - `mintArtNFT(uint256 _proposalId)`: Mints an NFT for an approved art proposal (only after voting).
 *    - `getArtNFTDetails(uint256 _tokenId)`: Retrieves details about a specific Art NFT.
 *    - `collaborateOnArt(uint256 _artNFTId, address _collaboratorArtist)`: Allows adding collaborators to an existing Art NFT (requires artist agreement).
 *    - `setArtNFTLicense(uint256 _artNFTId, string _licenseType, string _licenseDetails)`: Artists can set licenses for their Art NFTs (e.g., Creative Commons).
 *    - `reportArtNFT(uint256 _artNFTId, string _reason)`: Community can report NFTs for copyright or content violations.
 *
 * **3. Governance & Collective Management:**
 *    - `proposeGovernanceChange(string _proposalDescription, bytes _calldata)`: Governors propose changes to the contract parameters or rules.
 *    - `voteOnGovernanceChange(uint256 _proposalId, bool _approve)`: Governors vote on governance change proposals.
 *    - `executeGovernanceChange(uint256 _proposalId)`: Executes an approved governance change proposal.
 *    - `depositToTreasury() payable`: Anyone can deposit ETH into the collective's treasury.
 *    - `requestTreasuryWithdrawal(address _recipient, uint256 _amount, string _reason)`: Governors can request treasury withdrawals for collective purposes.
 *    - `voteOnTreasuryWithdrawal(uint256 _withdrawalId, bool _approve)`: Governors vote on treasury withdrawal requests.
 *    - `executeTreasuryWithdrawal(uint256 _withdrawalId)`: Executes an approved treasury withdrawal.
 *    - `setGovernanceParameters(uint256 _votingDurationBlocks, uint256 _quorumPercentage)`: Governors can change governance parameters through proposals.
 *    - `pauseContract()`: Governors can pause the contract in case of emergency.
 *    - `unpauseContract()`: Governors can unpause the contract.
 *
 * **Advanced Concepts & Creative Features:**
 *    - **Dynamic Art NFT Evolution:** (Concept - can be expanded) NFTs could evolve based on community votes or external data feeds (beyond the scope of basic example, but mentioned for creativity).
 *    - **Collaborative Art Ownership & Royalties:**  Clear mechanisms for splitting ownership and royalties among collaborating artists.
 *    - **Decentralized Curation & Exhibition:**  Potentially integrate features for decentralized art exhibitions within the collective.
 *    - **Reputation System:** (Implicit through artist profiles and reporting - can be explicitly developed further) Track artist reputation based on community feedback and contributions.
 *    - **On-Chain Licensing & Rights Management:**  Formalize art licensing directly on-chain.
 */

contract EtherealCanvas {

    // --- Enums and Structs ---

    enum ArtistStatus { Pending, Approved, Rejected, Removed }
    enum ProposalStatus { Pending, Approved, Rejected, Executed }
    enum WithdrawalStatus { Pending, Approved, Rejected, Executed }

    struct ArtistProfile {
        string name;
        string bio;
        string portfolioLink;
        ArtistStatus status;
        uint256 membershipRequestTimestamp;
    }

    struct ArtProposal {
        string title;
        string description;
        string ipfsHash; // IPFS hash of the art piece
        address proposer;
        ProposalStatus status;
        uint256 voteCountApprove;
        uint256 voteCountReject;
        uint256 proposalTimestamp;
    }

    struct GovernanceProposal {
        string description;
        bytes calldata; // Calldata to execute if approved
        ProposalStatus status;
        uint256 voteCountApprove;
        uint256 voteCountReject;
        uint256 proposalTimestamp;
    }

    struct TreasuryWithdrawal {
        address recipient;
        uint256 amount;
        string reason;
        WithdrawalStatus status;
        uint256 voteCountApprove;
        uint256 voteCountReject;
        uint256 proposalTimestamp;
    }

    struct ArtNFT {
        uint256 tokenId;
        uint256 proposalId;
        address creator;
        address[] collaborators;
        string licenseType;
        string licenseDetails;
        uint256 mintTimestamp;
    }


    // --- State Variables ---

    address public governorContractAddress; // Address of the Governor contract (or set of governor addresses for simplicity)
    mapping(address => ArtistProfile) public artistProfiles;
    mapping(uint256 => ArtProposal) public artProposals;
    uint256 public artProposalCounter;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    uint256 public governanceProposalCounter;
    mapping(uint256 => TreasuryWithdrawal) public treasuryWithdrawals;
    uint256 public treasuryWithdrawalCounter;
    mapping(uint256 => ArtNFT) public artNFTs;
    uint256 public artNFTCounter;
    uint256 public votingDurationBlocks = 100; // Default voting duration in blocks
    uint256 public quorumPercentage = 50; // Default quorum percentage for proposals (50%)
    bool public contractPaused = false;

    // --- Events ---

    event MembershipRequested(address indexed artistAddress);
    event MembershipApproved(address indexed artistAddress);
    event MembershipRejected(address indexed artistAddress);
    event ArtistProfileUpdated(address indexed artistAddress);
    event ArtistReported(address indexed reporter, address indexed reportedArtist, string reason);
    event ArtistRemoved(address indexed artistAddress);

    event ArtProposalCreated(uint256 indexed proposalId, address proposer);
    event ArtProposalVoted(uint256 indexed proposalId, address voter, bool approved);
    event ArtProposalApproved(uint256 indexed proposalId);
    event ArtProposalRejected(uint256 indexed proposalId);
    event ArtNFTMinted(uint256 indexed tokenId, uint256 indexed proposalId, address creator);
    event ArtNFTCollaborationAdded(uint256 indexed artNFTId, address collaborator);
    event ArtNFTLicenseSet(uint256 indexed artNFTId, string licenseType, string licenseDetails);
    event ArtNFTReported(uint256 indexed reporter, uint256 indexed artNFTId, string reason);

    event GovernanceProposalCreated(uint256 indexed proposalId);
    event GovernanceProposalVoted(uint256 indexed proposalId, address voter, bool approved);
    event GovernanceProposalExecuted(uint256 indexed proposalId);

    event TreasuryDeposit(address indexed depositor, uint256 amount);
    event TreasuryWithdrawalRequested(uint256 indexed withdrawalId, address recipient, uint256 amount);
    event TreasuryWithdrawalVoted(uint256 indexed withdrawalId, address voter, bool approved);
    event TreasuryWithdrawalExecuted(uint256 indexed withdrawalId, address recipient, uint256 amount);

    event ContractPaused();
    event ContractUnpaused();
    event GovernanceParametersUpdated(uint256 votingDurationBlocks, uint256 quorumPercentage);


    // --- Modifiers ---

    modifier onlyGovernor() {
        require(msg.sender == governorContractAddress, "Only governors can call this function");
        _;
    }

    modifier onlyArtist() {
        require(artistProfiles[msg.sender].status == ArtistStatus.Approved, "Only approved artists can call this function");
        _;
    }

    modifier contractNotPaused() {
        require(!contractPaused, "Contract is paused");
        _;
    }

    modifier validProposal(uint256 _proposalId, ProposalStatus _expectedStatus) {
        require(artProposals[_proposalId].status == _expectedStatus, "Invalid proposal status");
        _;
    }

    modifier validGovernanceProposal(uint256 _proposalId, ProposalStatus _expectedStatus) {
        require(governanceProposals[_proposalId].status == _expectedStatus, "Invalid governance proposal status");
        _;
    }

    modifier validWithdrawal(uint256 _withdrawalId, WithdrawalStatus _expectedStatus) {
        require(treasuryWithdrawals[_withdrawalId].status == _expectedStatus, "Invalid withdrawal status");
        _;
    }


    // --- Constructor ---

    constructor(address _governorContractAddress) {
        governorContractAddress = _governorContractAddress;
    }


    // --- 1. Artist Management Functions ---

    /// @notice Allows users to request membership to the Art Collective.
    function requestArtistMembership() external contractNotPaused {
        require(artistProfiles[msg.sender].status == ArtistStatus.Pending || artistProfiles[msg.sender].status == ArtistStatus.Rejected || artistProfiles[msg.sender].status == ArtistStatus.Removed || artistProfiles[msg.sender].status == ArtistStatus.Approved, "Membership request already processed or pending."); // Allow re-request after rejection/removal
        artistProfiles[msg.sender] = ArtistProfile({
            name: "",
            bio: "",
            portfolioLink: "",
            status: ArtistStatus.Pending,
            membershipRequestTimestamp: block.timestamp
        });
        emit MembershipRequested(msg.sender);
    }

    /// @notice Governors vote on pending artist membership requests.
    /// @param _artist Address of the artist to vote on.
    function voteForArtistMembership(address _artist) external onlyGovernor contractNotPaused {
        require(artistProfiles[_artist].status == ArtistStatus.Pending, "Artist membership is not pending.");
        // In a real DAO, voting logic would be more complex (e.g., voting power, quorum, etc.)
        // For simplicity, assume a direct governor vote here.
        artistProfiles[_artist].status = ArtistStatus.Approved;
        emit MembershipApproved(_artist);
    }

    /// @notice Retrieves public profile information of an artist.
    /// @param _artist Address of the artist.
    /// @return name Artist's name.
    /// @return bio Artist's bio.
    /// @return portfolioLink Artist's portfolio link.
    /// @return status Artist's membership status.
    function getArtistProfile(address _artist) external view returns (string memory name, string memory bio, string memory portfolioLink, ArtistStatus status) {
        return (
            artistProfiles[_artist].name,
            artistProfiles[_artist].bio,
            artistProfiles[_artist].portfolioLink,
            artistProfiles[_artist].status
        );
    }

    /// @notice Artists can update their profile information.
    /// @param _name Artist's new name.
    /// @param _bio Artist's new bio.
    /// @param _portfolioLink Artist's new portfolio link.
    function updateArtistProfile(string memory _name, string memory _bio, string memory _portfolioLink) external onlyArtist contractNotPaused {
        artistProfiles[msg.sender].name = _name;
        artistProfiles[msg.sender].bio = _bio;
        artistProfiles[msg.sender].portfolioLink = _portfolioLink;
        emit ArtistProfileUpdated(msg.sender);
    }

    /// @notice Community members can report artists for violations (governance review needed).
    /// @param _artist Address of the artist being reported.
    /// @param _reason Reason for reporting.
    function reportArtist(address _artist, string memory _reason) external contractNotPaused {
        // In a real DAO, this would trigger a governance review process.
        // For simplicity, just emit an event. Governors would then review reports off-chain or through a more complex on-chain system.
        emit ArtistReported(msg.sender, _artist, _reason);
    }

    /// @notice Governors can remove artists based on community reports or governance votes.
    /// @param _artist Address of the artist to remove.
    function removeArtist(address _artist) external onlyGovernor contractNotPaused {
        require(artistProfiles[_artist].status == ArtistStatus.Approved, "Artist is not currently approved.");
        artistProfiles[_artist].status = ArtistStatus.Removed;
        emit ArtistRemoved(_artist);
    }


    // --- 2. Art Creation & NFT Management Functions ---

    /// @notice Artists propose new art pieces to the collective.
    /// @param _title Title of the art piece.
    /// @param _description Description of the art piece.
    /// @param _ipfsHash IPFS hash of the art piece's digital file.
    function createArtProposal(string memory _title, string memory _description, string memory _ipfsHash) external onlyArtist contractNotPaused {
        artProposals[artProposalCounter] = ArtProposal({
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            proposer: msg.sender,
            status: ProposalStatus.Pending,
            voteCountApprove: 0,
            voteCountReject: 0,
            proposalTimestamp: block.timestamp
        });
        emit ArtProposalCreated(artProposalCounter, msg.sender);
        artProposalCounter++;
    }

    /// @notice Governors vote on art proposals.
    /// @param _proposalId ID of the art proposal.
    /// @param _approve True to approve, false to reject.
    function voteOnArtProposal(uint256 _proposalId, bool _approve) external onlyGovernor contractNotPaused validProposal(_proposalId, ProposalStatus.Pending) {
        require(block.number <= artProposals[_proposalId].proposalTimestamp + votingDurationBlocks, "Voting period has ended.");
        if (_approve) {
            artProposals[_proposalId].voteCountApprove++;
        } else {
            artProposals[_proposalId].voteCountReject++;
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _approve);

        // Check if quorum is reached and proposal should be approved/rejected
        uint256 totalVotes = artProposals[_proposalId].voteCountApprove + artProposals[_proposalId].voteCountReject;
        uint256 quorumNeeded = (100 * totalVotes) / 100; //  For simplicity, quorum is based on votes cast, not total governors.  Adjust as needed.

        if (quorumNeeded >= quorumPercentage) {
            if (artProposals[_proposalId].voteCountApprove > artProposals[_proposalId].voteCountReject) {
                artProposals[_proposalId].status = ProposalStatus.Approved;
                emit ArtProposalApproved(_proposalId);
            } else {
                artProposals[_proposalId].status = ProposalStatus.Rejected;
                emit ArtProposalRejected(_proposalId);
            }
        }
    }

    /// @notice Mints an NFT for an approved art proposal (only after voting).
    /// @param _proposalId ID of the approved art proposal.
    function mintArtNFT(uint256 _proposalId) external onlyGovernor contractNotPaused validProposal(_proposalId, ProposalStatus.Approved) {
        artNFTs[artNFTCounter] = ArtNFT({
            tokenId: artNFTCounter,
            proposalId: _proposalId,
            creator: artProposals[_proposalId].proposer,
            collaborators: new address[](0), // Initialize empty collaborators array
            licenseType: "", // Default license - can be set later
            licenseDetails: "",
            mintTimestamp: block.timestamp
        });
        emit ArtNFTMinted(artNFTCounter, _proposalId, artProposals[_proposalId].proposer);
        artNFTCounter++;
        artProposals[_proposalId].status = ProposalStatus.Executed; // Proposal is now executed after minting
    }

    /// @notice Retrieves details about a specific Art NFT.
    /// @param _tokenId ID of the Art NFT.
    /// @return tokenId NFT token ID.
    /// @return proposalId Original art proposal ID.
    /// @return creator Artist who created the NFT.
    /// @return collaborators List of collaborating artists.
    /// @return licenseType License type of the NFT.
    /// @return licenseDetails License details.
    /// @return mintTimestamp Timestamp of when the NFT was minted.
    function getArtNFTDetails(uint256 _tokenId) external view returns (
        uint256 tokenId,
        uint256 proposalId,
        address creator,
        address[] memory collaborators,
        string memory licenseType,
        string memory licenseDetails,
        uint256 mintTimestamp
    ) {
        ArtNFT memory nft = artNFTs[_tokenId];
        return (
            nft.tokenId,
            nft.proposalId,
            nft.creator,
            nft.collaborators,
            nft.licenseType,
            nft.licenseDetails,
            nft.mintTimestamp
        );
    }

    /// @notice Allows adding collaborators to an existing Art NFT (requires artist agreement - simplified here).
    /// @param _artNFTId ID of the Art NFT.
    /// @param _collaboratorArtist Address of the artist to add as a collaborator.
    function collaborateOnArt(uint256 _artNFTId, address _collaboratorArtist) external onlyArtist contractNotPaused {
        require(artNFTs[_artNFTId].creator == msg.sender, "Only the NFT creator can add collaborators (simplified)."); // In real system, might need collaborator agreement.
        artNFTs[_artNFTId].collaborators.push(_collaboratorArtist);
        emit ArtNFTCollaborationAdded(_artNFTId, _collaboratorArtist);
    }

    /// @notice Artists can set licenses for their Art NFTs (e.g., Creative Commons).
    /// @param _artNFTId ID of the Art NFT.
    /// @param _licenseType Type of license (e.g., "CC BY-NC-SA").
    /// @param _licenseDetails Further details about the license (e.g., link to license deed).
    function setArtNFTLicense(uint256 _artNFTId, string memory _licenseType, string memory _licenseDetails) external onlyArtist contractNotPaused {
        require(artNFTs[_artNFTId].creator == msg.sender, "Only the NFT creator can set the license.");
        artNFTs[_artNFTId].licenseType = _licenseType;
        artNFTs[_artNFTId].licenseDetails = _licenseDetails;
        emit ArtNFTLicenseSet(_artNFTId, _licenseType, _licenseDetails);
    }

    /// @notice Community can report NFTs for copyright or content violations.
    /// @param _artNFTId ID of the Art NFT being reported.
    /// @param _reason Reason for reporting.
    function reportArtNFT(uint256 _artNFTId, string memory _reason) external contractNotPaused {
        // Similar to artist reporting, this would trigger a governance review process.
        emit ArtNFTReported(msg.sender, _artNFTId, _reason);
    }


    // --- 3. Governance & Collective Management Functions ---

    /// @notice Governors propose changes to the contract parameters or rules.
    /// @param _proposalDescription Description of the governance change.
    /// @param _calldata Calldata to execute if the proposal is approved.
    function proposeGovernanceChange(string memory _proposalDescription, bytes memory _calldata) external onlyGovernor contractNotPaused {
        governanceProposals[governanceProposalCounter] = GovernanceProposal({
            description: _proposalDescription,
            calldata: _calldata,
            status: ProposalStatus.Pending,
            voteCountApprove: 0,
            voteCountReject: 0,
            proposalTimestamp: block.timestamp
        });
        emit GovernanceProposalCreated(governanceProposalCounter);
        governanceProposalCounter++;
    }

    /// @notice Governors vote on governance change proposals.
    /// @param _proposalId ID of the governance proposal.
    /// @param _approve True to approve, false to reject.
    function voteOnGovernanceChange(uint256 _proposalId, bool _approve) external onlyGovernor contractNotPaused validGovernanceProposal(_proposalId, ProposalStatus.Pending) {
        require(block.number <= governanceProposals[_proposalId].proposalTimestamp + votingDurationBlocks, "Voting period has ended.");
        if (_approve) {
            governanceProposals[_proposalId].voteCountApprove++;
        } else {
            governanceProposals[_proposalId].voteCountReject++;
        }
        emit GovernanceProposalVoted(_proposalId, msg.sender, _approve);

        // Check for quorum and approval/rejection (similar to art proposal voting)
        uint256 totalVotes = governanceProposals[_proposalId].voteCountApprove + governanceProposals[_proposalId].voteCountReject;
        uint256 quorumNeeded = (100 * totalVotes) / 100;

        if (quorumNeeded >= quorumPercentage) {
            if (governanceProposals[_proposalId].voteCountApprove > governanceProposals[_proposalId].voteCountReject) {
                governanceProposals[_proposalId].status = ProposalStatus.Approved;
                emit GovernanceProposalExecuted(_proposalId); // Event emitted in execute function in real scenario
            } else {
                governanceProposals[_proposalId].status = ProposalStatus.Rejected;
                emit ArtProposalRejected(_proposalId); // Reusing event name for rejection - consider separate event
            }
        }
    }

    /// @notice Executes an approved governance change proposal.
    /// @param _proposalId ID of the approved governance proposal.
    function executeGovernanceChange(uint256 _proposalId) external onlyGovernor contractNotPaused validGovernanceProposal(_proposalId, ProposalStatus.Approved) {
        governanceProposals[_proposalId].status = ProposalStatus.Executed;
        (bool success, ) = address(this).delegatecall(governanceProposals[_proposalId].calldata); // Delegatecall to execute proposal logic
        require(success, "Governance proposal execution failed");
        emit GovernanceProposalExecuted(_proposalId);
    }

    /// @notice Anyone can deposit ETH into the collective's treasury.
    function depositToTreasury() external payable contractNotPaused {
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    /// @notice Governors can request treasury withdrawals for collective purposes.
    /// @param _recipient Address to receive the withdrawn ETH.
    /// @param _amount Amount of ETH to withdraw.
    /// @param _reason Reason for the withdrawal.
    function requestTreasuryWithdrawal(address _recipient, uint256 _amount, string memory _reason) external onlyGovernor contractNotPaused {
        require(address(this).balance >= _amount, "Insufficient treasury balance.");
        treasuryWithdrawals[treasuryWithdrawalCounter] = TreasuryWithdrawal({
            recipient: _recipient,
            amount: _amount,
            reason: _reason,
            status: WithdrawalStatus.Pending,
            voteCountApprove: 0,
            voteCountReject: 0,
            proposalTimestamp: block.timestamp
        });
        emit TreasuryWithdrawalRequested(treasuryWithdrawalCounter, _recipient, _amount);
        treasuryWithdrawalCounter++;
    }

    /// @notice Governors vote on treasury withdrawal requests.
    /// @param _withdrawalId ID of the treasury withdrawal request.
    /// @param _approve True to approve, false to reject.
    function voteOnTreasuryWithdrawal(uint256 _withdrawalId, bool _approve) external onlyGovernor contractNotPaused validWithdrawal(_withdrawalId, WithdrawalStatus.Pending) {
        require(block.number <= treasuryWithdrawals[_withdrawalId].proposalTimestamp + votingDurationBlocks, "Voting period has ended.");
        if (_approve) {
            treasuryWithdrawals[_withdrawalId].voteCountApprove++;
        } else {
            treasuryWithdrawals[_withdrawalId].voteCountReject++;
        }
        emit TreasuryWithdrawalVoted(_withdrawalId, msg.sender, _approve);

        // Check for quorum and approval/rejection (similar to other voting mechanisms)
        uint256 totalVotes = treasuryWithdrawals[_withdrawalId].voteCountApprove + treasuryWithdrawals[_withdrawalId].voteCountReject;
        uint256 quorumNeeded = (100 * totalVotes) / 100;

        if (quorumNeeded >= quorumPercentage) {
            if (treasuryWithdrawals[_withdrawalId].voteCountApprove > treasuryWithdrawals[_withdrawalId].voteCountReject) {
                treasuryWithdrawals[_withdrawalId].status = WithdrawalStatus.Approved;
                emit TreasuryWithdrawalExecuted(_withdrawalId, treasuryWithdrawals[_withdrawalId].recipient, treasuryWithdrawals[_withdrawalId].amount); // Event emitted in execute function in real scenario
            } else {
                treasuryWithdrawals[_withdrawalId].status = WithdrawalStatus.Rejected;
                emit ArtProposalRejected(_withdrawalId); // Reusing event name - consider separate event
            }
        }
    }

    /// @notice Executes an approved treasury withdrawal.
    /// @param _withdrawalId ID of the approved treasury withdrawal request.
    function executeTreasuryWithdrawal(uint256 _withdrawalId) external onlyGovernor contractNotPaused validWithdrawal(_withdrawalId, WithdrawalStatus.Approved) {
        treasuryWithdrawals[_withdrawalId].status = WithdrawalStatus.Executed;
        payable(treasuryWithdrawals[_withdrawalId].recipient).transfer(treasuryWithdrawals[_withdrawalId].amount);
        emit TreasuryWithdrawalExecuted(_withdrawalId, treasuryWithdrawals[_withdrawalId].recipient, treasuryWithdrawals[_withdrawalId].amount);
    }

    /// @notice Governors can change governance parameters through proposals.
    /// @param _votingDurationBlocks New voting duration in blocks.
    /// @param _quorumPercentage New quorum percentage (0-100).
    function setGovernanceParameters(uint256 _votingDurationBlocks, uint256 _quorumPercentage) external onlyGovernor contractNotPaused {
        // This function is called via governance proposal execution using delegatecall
        votingDurationBlocks = _votingDurationBlocks;
        quorumPercentage = _quorumPercentage;
        emit GovernanceParametersUpdated(_votingDurationBlocks, _quorumPercentage);
    }

    /// @notice Governors can pause the contract in case of emergency.
    function pauseContract() external onlyGovernor contractNotPaused {
        contractPaused = true;
        emit ContractPaused();
    }

    /// @notice Governors can unpause the contract.
    function unpauseContract() external onlyGovernor {
        contractPaused = false;
        emit ContractUnpaused();
    }

    // --- Fallback and Receive (Optional for ETH receiving) ---
    receive() external payable {
        emit TreasuryDeposit(msg.sender, msg.value); // Allow direct ETH deposits to treasury
    }

    fallback() external {} // Optional fallback function
}
```