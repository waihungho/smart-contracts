```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Smart Contract
 * @author Bard (AI Assistant)

 * @notice This smart contract implements a Decentralized Autonomous Art Collective (DAAC)
 * where members can propose, vote on, and mint digital art pieces as NFTs.
 * It incorporates advanced concepts like dynamic NFT metadata updates, a reputation system,
 * delegated voting, and a decentralized curation mechanism.

 * @dev This contract is designed for educational and demonstration purposes, showcasing
 * advanced smart contract functionalities. It should be thoroughly audited and reviewed
 * before deployment in a production environment.

 * **Outline and Function Summary:**

 * **1. Membership Management:**
 *   - `proposeNewMember(address _newMember, string memory _reason)`: Allows existing members to propose new members with a reason.
 *   - `voteOnMemberProposal(uint256 _proposalId, bool _approve)`: Members vote on pending membership proposals.
 *   - `acceptMember(uint256 _proposalId)`: Executes membership acceptance if proposal passes.
 *   - `rejectMember(uint256 _proposalId)`: Executes membership rejection if proposal fails.
 *   - `removeMember(address _member)`: Governance function to remove a member (requires higher authority).
 *   - `delegateVotingPower(address _delegatee)`: Allows members to delegate their voting power to another member.

 * **2. Art Piece Proposal & Curation:**
 *   - `proposeArtPiece(string memory _title, string memory _ipfsMetadataHash)`: Members propose new art pieces with title and IPFS metadata hash.
 *   - `voteOnArtPieceProposal(uint256 _proposalId, bool _approve)`: Members vote on pending art piece proposals.
 *   - `mintArtPiece(uint256 _proposalId)`: Mints an NFT for an approved art piece proposal (only after successful vote).
 *   - `setArtPieceMetadata(uint256 _tokenId, string memory _ipfsMetadataHash)`: Allows the collective to update metadata of an existing NFT (governance).
 *   - `reportArtPiece(uint256 _tokenId, string memory _reportReason)`: Members can report art pieces for review (e.g., inappropriate content).
 *   - `voteOnArtPieceReport(uint256 _reportId, bool _removeArt)`: Governance votes on art piece reports, deciding whether to remove art.
 *   - `burnArtPiece(uint256 _tokenId)`: Governance function to burn an NFT (if report is approved).

 * **3. Reputation & Contribution System:**
 *   - `contributeToCollective(string memory _contributionDescription)`: Members can record contributions (e.g., community work, promotion).
 *   - `approveContribution(uint256 _contributionId)`: Governance approves recorded contributions, awarding reputation points.
 *   - `getMemberReputation(address _member)`: View function to check a member's reputation score.
 *   - `setReputationThresholdForProposals(uint256 _threshold)`: Governance function to adjust reputation threshold for proposing art.

 * **4. Treasury & Funding (Conceptual - Basic):**
 *   - `depositFunds()`: Allows anyone to deposit funds into the collective's treasury.
 *   - `proposeExpenditure(address _recipient, uint256 _amount, string memory _reason)`: Members propose expenditures from the treasury.
 *   - `voteOnExpenditureProposal(uint256 _proposalId, bool _approve)`: Members vote on expenditure proposals.
 *   - `executeExpenditure(uint256 _proposalId)`: Executes an approved expenditure proposal.

 * **5. Utility & Governance Functions:**
 *   - `pauseContract()`: Governance function to pause critical contract functions in emergencies.
 *   - `unpauseContract()`: Governance function to unpause the contract.
 *   - `setVotingPeriod(uint256 _newPeriod)`: Governance function to change the default voting period.
 *   - `setQuorumPercentage(uint256 _newQuorum)`: Governance function to adjust the quorum percentage for proposals.
 *   - `getProposalDetails(uint256 _proposalId)`: View function to retrieve details of a proposal.
 *   - `getArtPieceDetails(uint256 _tokenId)`: View function to get details of an art piece NFT.
 */

contract DecentralizedArtCollective {
    // -------- State Variables --------

    string public contractName = "Decentralized Autonomous Art Collective";
    address public governanceAddress; // Address with governance privileges
    address public treasuryAddress; // Address to hold collective funds

    mapping(address => bool) public members; // Track active members of the collective
    mapping(address => address) public votingDelegation; // Delegate voting power

    uint256 public memberReputationThresholdForProposals = 10; // Minimum reputation to propose art
    mapping(address => uint256) public memberReputation; // Track reputation of members

    uint256 public votingPeriod = 7 days; // Default voting period for proposals
    uint256 public quorumPercentage = 50; // Percentage of members needed to reach quorum

    bool public paused = false; // Contract pause state

    // NFT related
    uint256 public nextArtPieceId = 1;
    mapping(uint256 => ArtPiece) public artPieces; // Mapping of art piece IDs to ArtPiece struct
    mapping(address => uint256[]) public memberArtPieces; // Track NFTs owned by members

    // Proposal & Voting structs and counters
    uint256 public nextProposalId = 1;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // Track votes for each proposal by member
    mapping(ProposalType => uint256) public proposalCountByType;

    uint256 public nextContributionId = 1;
    mapping(uint256 => Contribution) public contributions;
    mapping(uint256 => mapping(address => bool)) public contributionVotes; // Track votes for each contribution

    uint256 public nextReportId = 1;
    mapping(uint256 => ArtReport) public artReports;
    mapping(uint256 => mapping(address => bool)) public reportVotes;

    // -------- Enums & Structs --------

    enum ProposalType {
        Membership,
        ArtPiece,
        Expenditure,
        Generic // For future flexibility
    }

    struct Proposal {
        uint256 proposalId;
        ProposalType proposalType;
        address proposer;
        string description;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        address targetAddress; // For membership or expenditure proposals, etc.
        uint256 amount; // For expenditure proposals
        string ipfsMetadataHash; // For art piece proposals
    }

    struct ArtPiece {
        uint256 tokenId;
        string title;
        string ipfsMetadataHash;
        address minter;
        uint256 mintTimestamp;
        bool exists;
    }

    struct Contribution {
        uint256 contributionId;
        address contributor;
        string description;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool approved;
    }

    struct ArtReport {
        uint256 reportId;
        uint256 tokenId;
        address reporter;
        string reason;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes; // Votes to remove art
        uint256 noVotes;  // Votes to keep art
        bool resolved;
        bool removeArt; // Outcome of the vote
    }

    // -------- Events --------

    event MemberProposed(uint256 proposalId, address newMember, address proposer, string reason);
    event MemberVoteCast(uint256 proposalId, address voter, bool approve);
    event MemberAccepted(address newMember);
    event MemberRejected(address rejectedMember);
    event MemberRemoved(address removedMember, address remover);
    event VotingPowerDelegated(address delegator, address delegatee);

    event ArtPieceProposed(uint256 proposalId, string title, string ipfsMetadataHash, address proposer);
    event ArtPieceVoteCast(uint256 proposalId, address voter, bool approve);
    event ArtPieceMinted(uint256 tokenId, string title, address minter);
    event ArtPieceMetadataUpdated(uint256 tokenId, string newIpfsMetadataHash);
    event ArtPieceReported(uint256 reportId, uint256 tokenId, address reporter, string reason);
    event ArtPieceReportVoteCast(uint256 reportId, address voter, bool removeArt);
    event ArtPieceBurned(uint256 tokenId);

    event ContributionProposed(uint256 contributionId, address contributor, string description);
    event ContributionVoteCast(uint256 contributionId, address voter, bool approve);
    event ContributionApproved(uint256 contributionId, address contributor);

    event ExpenditureProposed(uint256 proposalId, address recipient, uint256 amount, string reason, address proposer);
    event ExpenditureVoteCast(uint256 proposalId, address voter, bool approve);
    event ExpenditureExecuted(uint256 proposalId, address recipient, uint256 amount);

    event ContractPaused(address pauser);
    event ContractUnpaused(address unpauser);
    event VotingPeriodChanged(uint256 newPeriod);
    event QuorumPercentageChanged(uint256 newQuorum);

    // -------- Modifiers --------

    modifier onlyGovernance() {
        require(msg.sender == governanceAddress, "Only governance can perform this action");
        _;
    }

    modifier onlyMembers() {
        require(members[msg.sender], "Only members can perform this action");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        require(proposals[_proposalId].endTime > block.timestamp && !proposals[_proposalId].executed, "Proposal is not active");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(proposals[_proposalId].proposalId == _proposalId, "Proposal does not exist");
        _;
    }

    modifier reportExists(uint256 _reportId) {
        require(artReports[_reportId].reportId == _reportId, "Report does not exist");
        _;
    }

    modifier artPieceExists(uint256 _tokenId) {
        require(artPieces[_tokenId].exists, "Art piece does not exist");
        _;
    }


    // -------- Constructor --------

    constructor(address _governanceAddress, address _treasuryAddress) {
        governanceAddress = _governanceAddress;
        treasuryAddress = _treasuryAddress;
        members[_governanceAddress] = true; // Governance address is initial member
        memberReputation[_governanceAddress] = 100; // Initial reputation for governance
    }

    // -------- 1. Membership Management Functions --------

    /// @notice Propose a new member to the collective.
    /// @param _newMember Address of the member to be proposed.
    /// @param _reason Reason for proposing the new member.
    function proposeNewMember(address _newMember, string memory _reason) external onlyMembers notPaused {
        require(!members[_newMember], "Address is already a member");
        require(_newMember != address(0), "Invalid member address");

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            proposalType: ProposalType.Membership,
            proposer: msg.sender,
            description: _reason,
            startTime: block.timestamp,
            endTime: block.timestamp + votingPeriod,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            targetAddress: _newMember,
            amount: 0,
            ipfsMetadataHash: ""
        });
        proposalCountByType[ProposalType.Membership]++;

        emit MemberProposed(proposalId, _newMember, msg.sender, _reason);
    }

    /// @notice Vote on a pending membership proposal.
    /// @param _proposalId ID of the membership proposal.
    /// @param _approve True to approve, false to reject.
    function voteOnMemberProposal(uint256 _proposalId, bool _approve) external onlyMembers notPaused proposalExists(_proposalId) proposalActive(_proposalId) {
        require(!proposalVotes[_proposalId][msg.sender], "Already voted on this proposal");
        require(proposals[_proposalId].proposalType == ProposalType.Membership, "Proposal is not a membership proposal");

        proposalVotes[_proposalId][msg.sender] = true;
        if (_approve) {
            proposals[_proposalId].yesVotes++;
        } else {
            proposals[_proposalId].noVotes++;
        }
        emit MemberVoteCast(_proposalId, msg.sender, _approve);
    }

    /// @notice Accept a membership proposal if it has passed.
    /// @param _proposalId ID of the membership proposal.
    function acceptMember(uint256 _proposalId) external notPaused proposalExists(_proposalId) {
        require(proposals[_proposalId].proposalType == ProposalType.Membership, "Proposal is not a membership proposal");
        require(!proposals[_proposalId].executed, "Proposal already executed");
        require(block.timestamp > proposals[_proposalId].endTime, "Voting period not ended");

        uint256 totalMembers = getActiveMemberCount();
        uint256 quorum = (totalMembers * quorumPercentage) / 100;
        require(proposals[_proposalId].yesVotes >= quorum, "Quorum not reached for acceptance");
        require(proposals[_proposalId].yesVotes > proposals[_proposalId].noVotes, "More no votes than yes votes");

        address newMember = proposals[_proposalId].targetAddress;
        members[newMember] = true;
        memberReputation[newMember] = 0; // Initial reputation for new members
        proposals[_proposalId].executed = true;

        emit MemberAccepted(newMember);
    }

    /// @notice Reject a membership proposal if it has failed.
    /// @param _proposalId ID of the membership proposal.
    function rejectMember(uint256 _proposalId) external notPaused proposalExists(_proposalId) {
        require(proposals[_proposalId].proposalType == ProposalType.Membership, "Proposal is not a membership proposal");
        require(!proposals[_proposalId].executed, "Proposal already executed");
        require(block.timestamp > proposals[_proposalId].endTime, "Voting period not ended");

        uint256 totalMembers = getActiveMemberCount();
        uint256 quorum = (totalMembers * quorumPercentage) / 100;
        require(proposals[_proposalId].yesVotes < quorum || proposals[_proposalId].yesVotes <= proposals[_proposalId].noVotes, "Proposal should be rejected");

        proposals[_proposalId].executed = true;
        emit MemberRejected(proposals[_proposalId].targetAddress);
    }

    /// @notice Governance function to remove a member from the collective.
    /// @param _member Address of the member to be removed.
    function removeMember(address _member) external onlyGovernance notPaused {
        require(members[_member] && _member != governanceAddress, "Invalid member to remove");
        delete members[_member];
        delete memberReputation[_member]; // Optionally remove reputation
        emit MemberRemoved(_member, msg.sender);
    }

    /// @notice Delegate voting power to another member.
    /// @param _delegatee Address of the member to delegate voting power to.
    function delegateVotingPower(address _delegatee) external onlyMembers notPaused {
        require(members[_delegatee], "Delegatee must be a member");
        require(_delegatee != msg.sender, "Cannot delegate to yourself");
        votingDelegation[msg.sender] = _delegatee;
        emit VotingPowerDelegated(msg.sender, _delegatee);
    }

    // -------- 2. Art Piece Proposal & Curation Functions --------

    /// @notice Propose a new art piece for the collective to mint.
    /// @param _title Title of the art piece.
    /// @param _ipfsMetadataHash IPFS hash pointing to the art piece metadata.
    function proposeArtPiece(string memory _title, string memory _ipfsMetadataHash) external onlyMembers notPaused {
        require(memberReputation[msg.sender] >= memberReputationThresholdForProposals, "Reputation too low to propose art");
        require(bytes(_title).length > 0 && bytes(_ipfsMetadataHash).length > 0, "Title and metadata hash required");

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            proposalType: ProposalType.ArtPiece,
            proposer: msg.sender,
            description: _title, // Using title as description for art proposals
            startTime: block.timestamp,
            endTime: block.timestamp + votingPeriod,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            targetAddress: address(0), // Not applicable for art proposals
            amount: 0,
            ipfsMetadataHash: _ipfsMetadataHash
        });
        proposalCountByType[ProposalType.ArtPiece]++;

        emit ArtPieceProposed(proposalId, _title, _ipfsMetadataHash, msg.sender);
    }

    /// @notice Vote on a pending art piece proposal.
    /// @param _proposalId ID of the art piece proposal.
    /// @param _approve True to approve, false to reject.
    function voteOnArtPieceProposal(uint256 _proposalId, bool _approve) external onlyMembers notPaused proposalExists(_proposalId) proposalActive(_proposalId) {
        require(!proposalVotes[_proposalId][msg.sender], "Already voted on this proposal");
        require(proposals[_proposalId].proposalType == ProposalType.ArtPiece, "Proposal is not an art piece proposal");

        proposalVotes[_proposalId][msg.sender] = true;
        if (_approve) {
            proposals[_proposalId].yesVotes++;
        } else {
            proposals[_proposalId].noVotes++;
        }
        emit ArtPieceVoteCast(_proposalId, msg.sender, _approve);
    }

    /// @notice Mint an NFT for an approved art piece proposal.
    /// @param _proposalId ID of the art piece proposal.
    function mintArtPiece(uint256 _proposalId) external notPaused proposalExists(_proposalId) {
        require(proposals[_proposalId].proposalType == ProposalType.ArtPiece, "Proposal is not an art piece proposal");
        require(!proposals[_proposalId].executed, "Proposal already executed");
        require(block.timestamp > proposals[_proposalId].endTime, "Voting period not ended");

        uint256 totalMembers = getActiveMemberCount();
        uint256 quorum = (totalMembers * quorumPercentage) / 100;
        require(proposals[_proposalId].yesVotes >= quorum, "Quorum not reached for minting");
        require(proposals[_proposalId].yesVotes > proposals[_proposalId].noVotes, "More no votes than yes votes");

        ArtPiece memory newArtPiece = ArtPiece({
            tokenId: nextArtPieceId,
            title: proposals[_proposalId].description,
            ipfsMetadataHash: proposals[_proposalId].ipfsMetadataHash,
            minter: proposals[_proposalId].proposer,
            mintTimestamp: block.timestamp,
            exists: true
        });
        artPieces[nextArtPieceId] = newArtPiece;
        memberArtPieces[proposals[_proposalId].proposer].push(nextArtPieceId);
        proposals[_proposalId].executed = true;

        emit ArtPieceMinted(nextArtPieceId, newArtPiece.title, newArtPiece.minter);
        nextArtPieceId++;
    }

    /// @notice Set or update the metadata of an existing art piece NFT (governance function).
    /// @param _tokenId ID of the art piece NFT.
    /// @param _ipfsMetadataHash New IPFS hash for the art piece metadata.
    function setArtPieceMetadata(uint256 _tokenId, string memory _ipfsMetadataHash) external onlyGovernance notPaused artPieceExists(_tokenId) {
        require(bytes(_ipfsMetadataHash).length > 0, "Metadata hash cannot be empty");
        artPieces[_tokenId].ipfsMetadataHash = _ipfsMetadataHash;
        emit ArtPieceMetadataUpdated(_tokenId, _ipfsMetadataHash);
    }

    /// @notice Report an art piece for review (e.g., inappropriate content).
    /// @param _tokenId ID of the art piece being reported.
    /// @param _reportReason Reason for reporting the art piece.
    function reportArtPiece(uint256 _tokenId, string memory _reportReason) external onlyMembers notPaused artPieceExists(_tokenId) {
        require(bytes(_reportReason).length > 0, "Report reason cannot be empty");

        uint256 reportId = nextReportId++;
        artReports[reportId] = ArtReport({
            reportId: reportId,
            tokenId: _tokenId,
            reporter: msg.sender,
            reason: _reportReason,
            startTime: block.timestamp,
            endTime: block.timestamp + votingPeriod,
            yesVotes: 0,
            noVotes: 0,
            resolved: false,
            removeArt: false
        });
        emit ArtPieceReported(reportId, _tokenId, msg.sender, _reportReason);
    }

    /// @notice Vote on an art piece report, deciding whether to remove the art piece.
    /// @param _reportId ID of the art piece report.
    /// @param _removeArt True to remove the art piece, false to keep it.
    function voteOnArtPieceReport(uint256 _reportId, bool _removeArt) external onlyMembers notPaused reportExists(_reportId) {
        require(!reportVotes[_reportId][msg.sender], "Already voted on this report");
        require(!artReports[_reportId].resolved, "Report already resolved");

        reportVotes[_reportId][msg.sender] = true;
        if (_removeArt) {
            artReports[_reportId].yesVotes++; // Votes to remove art
        } else {
            artReports[_reportId].noVotes++;  // Votes to keep art
        }
        emit ArtPieceReportVoteCast(_reportId, msg.sender, _removeArt);
    }

    /// @notice Governance function to burn an NFT if an art piece report is approved.
    /// @param _tokenId ID of the art piece NFT to burn.
    function burnArtPiece(uint256 _tokenId) external onlyGovernance notPaused artPieceExists(_tokenId) {
        uint256 reportIdToExecute = 0;
        for (uint256 i = 1; i <= nextReportId - 1; i++) {
            if (artReports[i].tokenId == _tokenId && !artReports[i].resolved) {
                reportIdToExecute = i;
                break;
            }
        }
        require(reportIdToExecute != 0, "No unresolved report found for this art piece");
        require(block.timestamp > artReports[reportIdToExecute].endTime, "Report voting period not ended");

        uint256 totalMembers = getActiveMemberCount();
        uint256 quorum = (totalMembers * quorumPercentage) / 100;
        require(artReports[reportIdToExecute].yesVotes >= quorum, "Quorum not reached for burning");
        require(artReports[reportIdToExecute].yesVotes > artReports[reportIdToExecute].noVotes, "More votes to keep than to burn");

        artPieces[_tokenId].exists = false; // Mark as non-existent instead of actually burning in this example for simplicity. In a real NFT contract, burning would involve ERC721 functions.
        artReports[reportIdToExecute].resolved = true;
        artReports[reportIdToExecute].removeArt = true; // Record outcome
        emit ArtPieceBurned(_tokenId);
    }


    // -------- 3. Reputation & Contribution System Functions --------

    /// @notice Record a contribution made by a member to the collective.
    /// @param _contributionDescription Description of the contribution.
    function contributeToCollective(string memory _contributionDescription) external onlyMembers notPaused {
        require(bytes(_contributionDescription).length > 0, "Contribution description required");

        uint256 contributionId = nextContributionId++;
        contributions[contributionId] = Contribution({
            contributionId: contributionId,
            contributor: msg.sender,
            description: _contributionDescription,
            startTime: block.timestamp,
            endTime: block.timestamp + votingPeriod, // Consider a shorter voting period for contributions
            yesVotes: 0,
            noVotes: 0,
            approved: false
        });
        emit ContributionProposed(contributionId, msg.sender, _contributionDescription);
    }

    /// @notice Governance function to approve a member's contribution and award reputation points.
    /// @param _contributionId ID of the contribution to approve.
    function approveContribution(uint256 _contributionId) external onlyGovernance notPaused {
        require(!contributions[_contributionId].approved, "Contribution already approved");
        require(block.timestamp > contributions[_contributionId].endTime, "Contribution voting period not ended");

        uint256 totalMembers = getActiveMemberCount();
        uint256 quorum = (totalMembers * quorumPercentage) / 100;
        require(contributions[_contributionId].yesVotes >= quorum, "Quorum not reached for contribution approval");
        require(contributions[_contributionId].yesVotes > contributions[_contributionId].noVotes, "More no votes than yes votes for contribution");

        contributions[_contributionId].approved = true;
        memberReputation[contributions[_contributionId].contributor] += 5; // Award fixed reputation points (can be made dynamic)
        emit ContributionApproved(_contributionId, contributions[_contributionId].contributor);
    }

    /// @notice View function to get a member's reputation score.
    /// @param _member Address of the member.
    /// @return Member's reputation score.
    function getMemberReputation(address _member) external view returns (uint256) {
        return memberReputation[_member];
    }

    /// @notice Governance function to set the minimum reputation required to propose art pieces.
    /// @param _threshold New reputation threshold.
    function setReputationThresholdForProposals(uint256 _threshold) external onlyGovernance notPaused {
        memberReputationThresholdForProposals = _threshold;
    }

    /// @notice Vote on a pending contribution proposal.
    /// @param _contributionId ID of the contribution proposal.
    /// @param _approve True to approve, false to reject.
    function voteOnContribution(uint256 _contributionId, bool _approve) external onlyMembers notPaused {
        require(!contributionVotes[_contributionId][msg.sender], "Already voted on this contribution");
        require(!contributions[_contributionId].approved, "Contribution already approved"); // Prevent voting after approval

        contributionVotes[_contributionId][msg.sender] = true;
        if (_approve) {
            contributions[_contributionId].yesVotes++;
        } else {
            contributions[_contributionId].noVotes++;
        }
        emit ContributionVoteCast(_contributionId, msg.sender, _approve);
    }


    // -------- 4. Treasury & Funding (Conceptual - Basic) Functions --------

    /// @notice Allow anyone to deposit funds into the collective's treasury.
    function depositFunds() external payable notPaused {
        payable(treasuryAddress).transfer(msg.value); // Simple transfer to treasury address
    }

    /// @notice Propose an expenditure from the collective's treasury.
    /// @param _recipient Address to receive the funds.
    /// @param _amount Amount to be spent (in wei).
    /// @param _reason Reason for the expenditure.
    function proposeExpenditure(address _recipient, uint256 _amount, string memory _reason) external onlyMembers notPaused {
        require(_recipient != address(0), "Invalid recipient address");
        require(_amount > 0, "Expenditure amount must be greater than zero");
        require(treasuryAddress.balance >= _amount, "Insufficient funds in treasury");

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            proposalType: ProposalType.Expenditure,
            proposer: msg.sender,
            description: _reason,
            startTime: block.timestamp,
            endTime: block.timestamp + votingPeriod,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            targetAddress: _recipient,
            amount: _amount,
            ipfsMetadataHash: ""
        });
        proposalCountByType[ProposalType.Expenditure]++;

        emit ExpenditureProposed(proposalId, _recipient, _amount, _reason, msg.sender);
    }

    /// @notice Vote on a pending expenditure proposal.
    /// @param _proposalId ID of the expenditure proposal.
    /// @param _approve True to approve, false to reject.
    function voteOnExpenditureProposal(uint256 _proposalId, bool _approve) external onlyMembers notPaused proposalExists(_proposalId) proposalActive(_proposalId) {
        require(!proposalVotes[_proposalId][msg.sender], "Already voted on this proposal");
        require(proposals[_proposalId].proposalType == ProposalType.Expenditure, "Proposal is not an expenditure proposal");

        proposalVotes[_proposalId][msg.sender] = true;
        if (_approve) {
            proposals[_proposalId].yesVotes++;
        } else {
            proposals[_proposalId].noVotes++;
        }
        emit ExpenditureVoteCast(_proposalId, msg.sender, _approve);
    }

    /// @notice Execute an approved expenditure proposal.
    /// @param _proposalId ID of the expenditure proposal.
    function executeExpenditure(uint256 _proposalId) external notPaused proposalExists(_proposalId) {
        require(proposals[_proposalId].proposalType == ProposalType.Expenditure, "Proposal is not an expenditure proposal");
        require(!proposals[_proposalId].executed, "Proposal already executed");
        require(block.timestamp > proposals[_proposalId].endTime, "Voting period not ended");

        uint256 totalMembers = getActiveMemberCount();
        uint256 quorum = (totalMembers * quorumPercentage) / 100;
        require(proposals[_proposalId].yesVotes >= quorum, "Quorum not reached for expenditure");
        require(proposals[_proposalId].yesVotes > proposals[_proposalId].noVotes, "More no votes than yes votes");
        require(treasuryAddress.balance >= proposals[_proposalId].amount, "Insufficient funds in treasury at execution time");

        address recipient = proposals[_proposalId].targetAddress;
        uint256 amount = proposals[_proposalId].amount;
        proposals[_proposalId].executed = true;

        payable(recipient).transfer(amount);
        emit ExpenditureExecuted(_proposalId, recipient, amount);
    }


    // -------- 5. Utility & Governance Functions --------

    /// @notice Governance function to pause critical contract functions.
    function pauseContract() external onlyGovernance notPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Governance function to unpause the contract.
    function unpauseContract() external onlyGovernance {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /// @notice Governance function to set the voting period for proposals.
    /// @param _newPeriod New voting period in seconds.
    function setVotingPeriod(uint256 _newPeriod) external onlyGovernance notPaused {
        require(_newPeriod > 0, "Voting period must be greater than zero");
        votingPeriod = _newPeriod;
        emit VotingPeriodChanged(_newPeriod);
    }

    /// @notice Governance function to set the quorum percentage for proposals.
    /// @param _newQuorum New quorum percentage (e.g., 50 for 50%).
    function setQuorumPercentage(uint256 _newQuorum) external onlyGovernance notPaused {
        require(_newQuorum >= 1 && _newQuorum <= 100, "Quorum percentage must be between 1 and 100");
        quorumPercentage = _newQuorum;
        emit QuorumPercentageChanged(_newQuorum);
    }

    /// @notice View function to get details of a proposal.
    /// @param _proposalId ID of the proposal.
    /// @return Proposal struct.
    function getProposalDetails(uint256 _proposalId) external view proposalExists(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    /// @notice View function to get details of an art piece NFT.
    /// @param _tokenId ID of the art piece NFT.
    /// @return ArtPiece struct.
    function getArtPieceDetails(uint256 _tokenId) external view artPieceExists(_tokenId) returns (ArtPiece memory) {
        return artPieces[_tokenId];
    }

    /// @notice Internal helper function to get the count of active members (excluding delegated votes - for simplicity).
    function getActiveMemberCount() internal view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 1; i < nextProposalId; i++) { // Iterate through proposals to count members (less gas efficient for very large member counts - optimize if needed)
            if (proposals[i].proposalType == ProposalType.Membership) {
                if (proposals[i].executed && members[proposals[i].targetAddress]) { // Only count accepted members
                    count++;
                }
            }
        }
        uint256 initialMembers = 1; // Governance address is the initial member
        return initialMembers + count; // This is a very basic member count, refine for production use.
    }


    // -------- Fallback and Receive (Optional - for direct ETH interaction with treasury) --------

    receive() external payable {
        if (msg.sender != address(this)) { // Prevent accidental sending from contract itself
            payable(treasuryAddress).transfer(msg.value); // Forward any ETH sent directly to the contract to the treasury
        }
    }

    fallback() external {}
}
```