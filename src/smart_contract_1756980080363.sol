Okay, this is an exciting challenge! Creating a truly unique, advanced, and creative contract requires combining several concepts in a novel way.

Let's design a smart contract called **"DeSciDAO: Decentralized Scientific Research & Grant Fund"**.

This contract aims to create a decentralized ecosystem for funding and peer-reviewing scientific research proposals. It integrates:

1.  **Staked Reputation:** Participants stake ERC20 tokens to gain voting power and review eligibility, earning a dynamic reputation score.
2.  **Multi-Stage Proposals:** Research proposals go through a structured lifecycle including submission, peer-review by staked participants, and a public voting phase.
3.  **Milestone-Based Funding:** Approved projects receive funds incrementally upon verified completion of defined milestones, ensuring accountability.
4.  **On-Chain Dispute Resolution:** A mechanism for challenging milestone claims or reviews, resolved by community vote, with reputation and stake adjustments as outcomes.
5.  **Dynamic Governance:** Core parameters and dispute outcomes are managed through participant voting (simulated by `onlyOwner` for this example, but intended for a full DAO governance system).

---

### **Contract Outline & Function Summary**

**Contract Name:** `DeSciDAO`

**Purpose:** A Decentralized Autonomous Organization (DAO) facilitating funding, peer-review, and progress tracking for scientific research proposals. It aims to foster trust and accountability in decentralized science (DeSci) by leveraging staked reputation and structured milestone-based funding.

---

**I. Core Structures & State Management**
*   `Project`: Stores details of a research proposal, its milestones, funding, and voting status.
*   `Milestone`: Details for each stage of a project, including funding percentage, completion status, and verification.
*   `Participant`: Tracks reputation, staked tokens, and profile information for DAO members.
*   `Config`: Stores adjustable parameters for the DAO (e.g., proposal deposits, voting periods).

**II. Admin & Configuration Functions (Intended for DAO Governance)**
1.  `constructor()`: Initializes the contract, sets the owner, and the ERC20 token for staking.
2.  `updateConfig(bytes32 _paramNameHash, uint256 _newValue)`: Allows the DAO to update core operational parameters.
3.  `pauseContract()`: Emergency function to pause critical contract operations.
4.  `unpauseContract()`: Unpauses the contract.

**III. Funding & Treasury Management**
5.  `depositToDAO()`: Allows any external user to contribute funds to the DAO's research treasury.
6.  `withdrawDAORevenue(address _recipient, uint256 _amount)`: Allows the DAO (via governance) to withdraw funds from the treasury.

**IV. Participant & Reputation Management**
7.  `registerParticipant()`: Allows an address to register as a participant in the DeSciDAO, initializing their reputation.
8.  `updateParticipantProfile(string memory _ipfsHash)`: Updates a participant's profile IPFS hash (e.g., linking to their resume, research interests).
9.  `stakeTokens(uint256 _amount)`: Participants stake ERC20 tokens to gain eligibility for reviewing and voting, boosting their influence.
10. `unstakeTokens(uint256 _amount)`: Participants can unstake their tokens after a cooldown period.
11. `penalizeParticipant(address _participant, uint256 _reputationLoss)`: DAO (via governance) can reduce a participant's reputation for malicious actions.
12. `rewardParticipant(address _participant, uint256 _reputationGain)`: DAO (via governance) can increase a participant's reputation for exemplary contributions.

**V. Proposal Lifecycle Management**
13. `submitProposal(string memory _title, string memory _descriptionIpfsHash, uint256 _totalFundingRequested, Milestone[] memory _milestones)`: Proposers submit a new research project, including a deposit and detailed milestones.
14. `cancelProposal(uint256 _proposalId)`: A proposer can cancel their own proposal if it's still in the `PendingReview` stage.
15. `submitReview(uint256 _proposalId, string memory _reviewIpfsHash, bool _recommendation)`: Staked participants can submit a peer review for a `PendingReview` proposal.
16. `startProposalVoting(uint256 _proposalId)`: Initiates the public voting phase for a proposal after sufficient reviews have been submitted.
17. `voteOnProposal(uint256 _proposalId, bool _support)`: Registered participants vote on a proposal (weighted by their staked tokens and reputation).
18. `finalizeProposalVoting(uint256 _proposalId)`: Ends the voting period and determines if a proposal is approved or rejected based on votes.
19. `submitMilestoneCompletion(uint256 _proposalId, uint256 _milestoneIndex, string memory _proofIpfsHash)`: Project leads submit proof of milestone completion.
20. `verifyMilestone(uint256 _proposalId, uint256 _milestoneIndex, bool _isVerified)`: Designated verifiers (or DAO vote) confirm milestone completion.
21. `releaseMilestoneFunds(uint256 _proposalId, uint256 _milestoneIndex)`: Releases funds for a verified milestone to the project proposer.

**VI. Dispute Resolution**
22. `raiseDispute(uint256 _proposalId, uint256 _milestoneIndex, string memory _reasonIpfsHash)`: Allows any participant to raise a dispute against a milestone verification or completion. Requires a bond.
23. `voteOnDispute(uint256 _proposalId, uint256 _milestoneIndex, bool _resolution)`: Registered participants vote to resolve an active dispute.
24. `resolveDispute(uint256 _proposalId, uint256 _milestoneIndex)`: Finalizes a dispute, applies penalties/rewards to involved parties, and potentially reverts milestone status.

**VII. View Functions**
25. `getParticipantInfo(address _participant)`: Retrieves a participant's reputation, staked tokens, and profile hash.
26. `getProposal(uint256 _proposalId)`: Retrieves all details of a specific research proposal.
27. `getMilestone(uint256 _proposalId, uint256 _milestoneIndex)`: Retrieves details for a specific milestone of a project.
28. `getTotalAvailableFunds()`: Returns the total funds currently available in the DAO treasury.
29. `getProjectCount()`: Returns the total number of proposals submitted.
30. `getDAOConfig(bytes32 _paramNameHash)`: Retrieves the current value of a specific DAO configuration parameter.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- Contract Outline & Function Summary ---
// Contract Name: DeSciDAO
// Purpose: A Decentralized Autonomous Organization (DAO) facilitating funding, peer-review,
// and progress tracking for scientific research proposals. It aims to foster trust and
// accountability in decentralized science (DeSci) by leveraging staked reputation and
// structured milestone-based funding.

// I. Core Structures & State Management
//    - Project: Stores details of a research proposal, its milestones, funding, and voting status.
//    - Milestone: Details for each stage of a project, including funding percentage, completion status, and verification.
//    - Participant: Tracks reputation, staked tokens, and profile information for DAO members.
//    - Config: Stores adjustable parameters for the DAO (e.g., proposal deposits, voting periods).

// II. Admin & Configuration Functions (Intended for DAO Governance)
// 1.  constructor(): Initializes the contract, sets the owner, and the ERC20 token for staking.
// 2.  updateConfig(bytes32 _paramNameHash, uint256 _newValue): Allows the DAO to update core operational parameters.
// 3.  pauseContract(): Emergency function to pause critical contract operations.
// 4.  unpauseContract(): Unpauses the contract.

// III. Funding & Treasury Management
// 5.  depositToDAO(): Allows any external user to contribute funds to the DAO's research treasury.
// 6.  withdrawDAORevenue(address _recipient, uint256 _amount): Allows the DAO (via governance) to withdraw funds from the treasury.

// IV. Participant & Reputation Management
// 7.  registerParticipant(): Allows an address to register as a participant in the DeSciDAO, initializing their reputation.
// 8.  updateParticipantProfile(string memory _ipfsHash): Updates a participant's profile IPFS hash.
// 9.  stakeTokens(uint256 _amount): Participants stake ERC20 tokens to gain eligibility for reviewing and voting, boosting their influence.
// 10. unstakeTokens(uint256 _amount): Participants can unstake their tokens after a cooldown period.
// 11. penalizeParticipant(address _participant, uint256 _reputationLoss): DAO (via governance) can reduce a participant's reputation.
// 12. rewardParticipant(address _participant, uint256 _reputationGain): DAO (via governance) can increase a participant's reputation.

// V. Proposal Lifecycle Management
// 13. submitProposal(string memory _title, string memory _descriptionIpfsHash, uint256 _totalFundingRequested, Milestone[] memory _milestones): Proposers submit a new research project, including a deposit and detailed milestones.
// 14. cancelProposal(uint256 _proposalId): A proposer can cancel their own proposal if it's still in the PendingReview stage.
// 15. submitReview(uint256 _proposalId, string memory _reviewIpfsHash, bool _recommendation): Staked participants can submit a peer review.
// 16. startProposalVoting(uint256 _proposalId): Initiates the public voting phase for a proposal.
// 17. voteOnProposal(uint256 _proposalId, bool _support): Registered participants vote on a proposal.
// 18. finalizeProposalVoting(uint256 _proposalId): Ends the voting period and determines funding outcome.
// 19. submitMilestoneCompletion(uint256 _proposalId, uint256 _milestoneIndex, string memory _proofIpfsHash): Project leads submit proof of milestone completion.
// 20. verifyMilestone(uint256 _proposalId, uint256 _milestoneIndex, bool _isVerified): Designated verifiers (or DAO vote) confirm milestone completion.
// 21. releaseMilestoneFunds(uint256 _proposalId, uint256 _milestoneIndex): Releases funds for a verified milestone to the project proposer.

// VI. Dispute Resolution
// 22. raiseDispute(uint256 _proposalId, uint256 _milestoneIndex, string memory _reasonIpfsHash): Allows any participant to raise a dispute against a milestone.
// 23. voteOnDispute(uint256 _proposalId, uint256 _milestoneIndex, bool _resolution): Registered participants vote to resolve an active dispute.
// 24. resolveDispute(uint256 _proposalId, uint256 _milestoneIndex): Finalizes a dispute, applies penalties/rewards, and potentially reverts milestone status.

// VII. View Functions
// 25. getParticipantInfo(address _participant): Retrieves a participant's reputation, staked tokens, and profile hash.
// 26. getProposal(uint256 _proposalId): Retrieves all details of a specific research proposal.
// 27. getMilestone(uint256 _proposalId, uint256 _milestoneIndex): Retrieves details for a specific milestone of a project.
// 28. getTotalAvailableFunds(): Returns the total funds currently available in the DAO treasury.
// 29. getProjectCount(): Returns the total number of proposals submitted.
// 30. getDAOConfig(bytes32 _paramNameHash): Retrieves the current value of a specific DAO configuration parameter.
// --- End of Outline & Summary ---

contract DeSciDAO is Ownable, Pausable, ReentrancyGuard {

    // --- Configuration Constants & Events ---
    // In a real DAO, these parameters would be adjustable via governance proposals.
    // For this example, onlyOwner acts as a simplified governance.
    mapping(bytes32 => uint256) public daoConfig; // Keyed by hash of config name (e.g., "PROPOSAL_DEPOSIT_AMOUNT")

    // Events for off-chain monitoring
    event ParticipantRegistered(address indexed participant, uint256 initialReputation);
    event ParticipantProfileUpdated(address indexed participant, string ipfsHash);
    event TokensStaked(address indexed participant, uint256 amount);
    event TokensUnstaked(address indexed participant, uint256 amount);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string title, uint256 requestedFunding);
    event ProposalCanceled(uint256 indexed proposalId);
    event ReviewSubmitted(uint256 indexed proposalId, address indexed reviewer, string reviewIpfsHash, bool recommendation);
    event ProposalVotingStarted(uint256 indexed proposalId);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 voteWeight);
    event ProposalFinalized(uint256 indexed proposalId, bool approved, uint256 totalFor, uint256 totalAgainst);
    event MilestoneCompletionSubmitted(uint256 indexed proposalId, uint256 indexed milestoneIndex, address indexed submitter, string proofIpfsHash);
    event MilestoneVerified(uint256 indexed proposalId, uint256 indexed milestoneIndex, address indexed verifier);
    event FundsReleased(uint256 indexed proposalId, uint256 indexed milestoneIndex, address indexed recipient, uint256 amount);
    event DisputeRaised(uint256 indexed proposalId, uint256 indexed milestoneIndex, address indexed disputer, string reasonIpfsHash);
    event DisputeVoted(uint256 indexed proposalId, uint256 indexed milestoneIndex, address indexed voter, bool resolution);
    event DisputeResolved(uint256 indexed proposalId, uint256 indexed milestoneIndex, bool outcome);
    event DAOConfigUpdated(bytes32 indexed paramNameHash, uint256 newValue);
    event ParticipantReputationAdjusted(address indexed participant, uint256 oldReputation, uint256 newReputation);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);


    // --- Enums ---
    enum ProposalStatus {
        PendingReview,   // Initial state, awaiting reviews
        ReadyForVote,    // Sufficient reviews, ready for community vote
        Voting,          // Community is voting
        Approved,        // Approved by vote, ready for funding
        Rejected,        // Rejected by vote
        Cancelled        // Proposer cancelled
    }

    enum MilestoneStatus {
        Pending,
        Submitted,       // Project lead claims completion
        Verified,        // Verified by a reviewer/DAO
        Disputed,        // Milestone completion is under dispute
        Rejected         // Milestone claim was rejected
    }

    // --- Structs ---

    struct Milestone {
        string descriptionIpfsHash; // IPFS hash for detailed milestone description
        uint256 fundingPercentage;  // Percentage of total funding for this milestone
        MilestoneStatus status;     // Current status of the milestone
        uint256 releaseTimestamp;   // Timestamp when funds were released (0 if not released)
        string proofIpfsHash;       // IPFS hash for proof of completion (once submitted)
        uint256 verificationAttempts; // Number of times it was submitted for verification
    }

    struct Project {
        uint256 id;
        address proposer;
        string title;
        string descriptionIpfsHash; // IPFS hash for the full proposal text
        uint256 totalFundingRequested;
        uint256 currentFundedAmount; // Total funds disbursed for this project so far
        uint256 creationTimestamp;
        ProposalStatus status;
        Milestone[] milestones;

        // Voting specific
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        mapping(address => bool) hasVotedOnProposal; // Tracks if an address voted on this proposal

        // Review specific
        uint256 reviewCount;
        uint256 recommendationCount; // How many reviewers recommended approval
        mapping(address => bool) hasReviewed; // Tracks if an address reviewed this proposal

        // Dispute specific (only one active dispute per milestone at a time)
        mapping(uint256 => Dispute) activeDisputes; // Milestone index => Dispute
    }

    struct Participant {
        bool isRegistered;
        string profileIpfsHash;
        uint256 reputationScore; // Earned by contributing positively
        uint256 stakedTokens;    // ERC20 tokens staked for influence
        uint256 lastUnstakeRequest; // Timestamp for cooldown period
        mapping(uint256 => bool) hasReviewed; // Tracks reviews submitted by this participant
    }

    struct Dispute {
        address disputer;
        string reasonIpfsHash; // IPFS hash for the reason for dispute
        uint256 creationTime;
        uint256 votingEndTime;
        uint256 votesForResolution;   // Votes agreeing with the disputer
        uint256 votesAgainstResolution; // Votes disagreeing
        mapping(address => bool) hasVotedOnDispute; // Tracks if an address voted on this specific dispute
        bool isActive;
    }


    // --- State Variables ---
    IERC20 public stakeToken; // The ERC20 token used for staking and funding
    uint256 public nextProposalId; // Counter for proposals

    mapping(uint256 => Project) public projects; // Stores all proposals by ID
    mapping(address => Participant) public participants; // Stores participant data


    // --- Modifiers ---
    modifier onlyRegisteredParticipant() {
        require(participants[msg.sender].isRegistered, "DeSciDAO: Not a registered participant.");
        _;
    }

    modifier onlyProjectProposer(uint256 _proposalId) {
        require(projects[_proposalId].proposer == msg.sender, "DeSciDAO: Only the project proposer can call this function.");
        _;
    }

    modifier onlyIfStakeAvailable(uint256 _amount) {
        require(participants[msg.sender].stakedTokens >= _amount, "DeSciDAO: Insufficient staked tokens.");
        _;
    }

    // This modifier simulates DAO governance. In a real system, this would be a multi-sig or
    // a separate governance contract with voting.
    modifier onlyDAO() {
        require(msg.sender == owner(), "DeSciDAO: Only DAO (Owner) can call this function.");
        _;
    }


    // --- Constructor ---
    // 1. constructor(): Initializes the contract, sets the owner, and the ERC20 token for staking.
    constructor(address _stakeTokenAddress) Ownable(msg.sender) {
        require(_stakeTokenAddress != address(0), "DeSciDAO: Stake token address cannot be zero.");
        stakeToken = IERC20(_stakeTokenAddress);
        nextProposalId = 1;

        // Set initial DAO configuration parameters
        daoConfig[keccak256("PROPOSAL_DEPOSIT_AMOUNT")] = 10 ether; // Example: 10 of stakeToken
        daoConfig[keccak256("MIN_REVIEWS_FOR_VOTING")] = 3;
        daoConfig[keccak256("VOTING_PERIOD_DURATION")] = 7 days;
        daoConfig[keccak256("REVIEW_STAKE_REQUIREMENT")] = 100 ether; // Min stake to review a proposal
        daoConfig[keccak256("DISPUTE_BOND_AMOUNT")] = 5 ether; // Bond required to raise a dispute
        daoConfig[keccak256("DISPUTE_VOTING_PERIOD")] = 3 days;
        daoConfig[keccak256("UNSTAKE_COOLDOWN_PERIOD")] = 14 days; // Days until staked tokens can be fully withdrawn
        daoConfig[keccak256("MIN_REPUTATION_FOR_REVIEW")] = 100; // Min reputation to be eligible to review
        daoConfig[keccak256("MILESTONE_VERIFIER_REPUTATION_BOOST")] = 10;
        daoConfig[keccak256("REVIEWER_REPUTATION_BOOST")] = 5;
        daoConfig[keccak256("VOTER_REPUTATION_BOOST")] = 1;
        daoConfig[keccak256("DISPUTE_WINNER_REPUTATION_BOOST")] = 20;
        daoConfig[keccak256("DISPUTE_LOSER_REPUTATION_PENALTY")] = 15;
    }

    // --- Admin & Configuration Functions (Intended for DAO Governance) ---

    // 2. updateConfig(bytes32 _paramNameHash, uint256 _newValue): Allows the DAO to update core operational parameters.
    function updateConfig(bytes32 _paramNameHash, uint256 _newValue) external onlyDAO {
        daoConfig[_paramNameHash] = _newValue;
        emit DAOConfigUpdated(_paramNameHash, _newValue);
    }

    // 3. pauseContract(): Emergency function to pause critical contract operations.
    function pauseContract() external onlyDAO {
        _pause();
    }

    // 4. unpauseContract(): Unpauses the contract.
    function unpauseContract() external onlyDAO {
        _unpause();
    }

    // --- Funding & Treasury Management ---

    // 5. depositToDAO(): Allows any external user to contribute funds to the DAO's research treasury.
    function depositToDAO(uint256 _amount) external whenNotPaused nonReentrant {
        require(_amount > 0, "DeSciDAO: Amount must be greater than zero.");
        require(stakeToken.transferFrom(msg.sender, address(this), _amount), "DeSciDAO: Token transfer failed.");
        emit FundsDeposited(msg.sender, _amount);
    }

    // 6. withdrawDAORevenue(address _recipient, uint256 _amount): Allows the DAO (via governance) to withdraw funds from the treasury.
    function withdrawDAORevenue(address _recipient, uint256 _amount) external onlyDAO whenNotPaused nonReentrant {
        require(_recipient != address(0), "DeSciDAO: Recipient cannot be zero address.");
        require(_amount > 0, "DeSciDAO: Amount must be greater than zero.");
        require(stakeToken.balanceOf(address(this)) >= _amount, "DeSciDAO: Insufficient funds in DAO treasury.");
        require(stakeToken.transfer(_recipient, _amount), "DeSciDAO: Token transfer failed.");
        emit FundsWithdrawn(_recipient, _amount);
    }

    // --- Participant & Reputation Management ---

    // 7. registerParticipant(): Allows an address to register as a participant in the DeSciDAO, initializing their reputation.
    function registerParticipant() external whenNotPaused {
        require(!participants[msg.sender].isRegistered, "DeSciDAO: Already a registered participant.");
        participants[msg.sender].isRegistered = true;
        // Initial reputation score could be 0 or a small default.
        // For now, let's start at 0 and build up.
        participants[msg.sender].reputationScore = 0;
        emit ParticipantRegistered(msg.sender, 0);
    }

    // 8. updateParticipantProfile(string memory _ipfsHash): Updates a participant's profile IPFS hash.
    function updateParticipantProfile(string memory _ipfsHash) external onlyRegisteredParticipant whenNotPaused {
        participants[msg.sender].profileIpfsHash = _ipfsHash;
        emit ParticipantProfileUpdated(msg.sender, _ipfsHash);
    }

    // 9. stakeTokens(uint256 _amount): Participants stake ERC20 tokens to gain eligibility for reviewing and voting, boosting their influence.
    function stakeTokens(uint256 _amount) external onlyRegisteredParticipant whenNotPaused nonReentrant {
        require(_amount > 0, "DeSciDAO: Amount must be greater than zero.");
        require(stakeToken.transferFrom(msg.sender, address(this), _amount), "DeSciDAO: Token transfer failed.");
        participants[msg.sender].stakedTokens += _amount;
        emit TokensStaked(msg.sender, _amount);
    }

    // 10. unstakeTokens(uint256 _amount): Participants can unstake their tokens after a cooldown period.
    function unstakeTokens(uint256 _amount) external onlyRegisteredParticipant whenNotPaused nonReentrant onlyIfStakeAvailable(_amount) {
        require(participants[msg.sender].stakedTokens >= _amount, "DeSciDAO: Insufficient staked tokens to unstake.");
        
        uint256 cooldownPeriod = daoConfig[keccak256("UNSTAKE_COOLDOWN_PERIOD")];
        if (participants[msg.sender].lastUnstakeRequest != 0 && block.timestamp < participants[msg.sender].lastUnstakeRequest + cooldownPeriod) {
            revert("DeSciDAO: Unstaking cooldown period not over.");
        }
        
        participants[msg.sender].stakedTokens -= _amount;
        require(stakeToken.transfer(msg.sender, _amount), "DeSciDAO: Token transfer failed.");
        participants[msg.sender].lastUnstakeRequest = block.timestamp; // Reset cooldown for next unstake
        emit TokensUnstaked(msg.sender, _amount);
    }

    // 11. penalizeParticipant(address _participant, uint256 _reputationLoss): DAO (via governance) can reduce a participant's reputation.
    function penalizeParticipant(address _participant, uint256 _reputationLoss) external onlyDAO whenNotPaused {
        require(participants[_participant].isRegistered, "DeSciDAO: Participant not registered.");
        uint256 oldReputation = participants[_participant].reputationScore;
        participants[_participant].reputationScore = participants[_participant].reputationScore > _reputationLoss ? participants[_participant].reputationScore - _reputationLoss : 0;
        emit ParticipantReputationAdjusted(_participant, oldReputation, participants[_participant].reputationScore);
    }

    // 12. rewardParticipant(address _participant, uint256 _reputationGain): DAO (via governance) can increase a participant's reputation.
    function rewardParticipant(address _participant, uint256 _reputationGain) external onlyDAO whenNotPaused {
        require(participants[_participant].isRegistered, "DeSciDAO: Participant not registered.");
        uint256 oldReputation = participants[_participant].reputationScore;
        participants[_participant].reputationScore += _reputationGain;
        emit ParticipantReputationAdjusted(_participant, oldReputation, participants[_participant].reputationScore);
    }

    // --- Proposal Lifecycle Management ---

    // 13. submitProposal(...): Proposers submit a new research project, including a deposit and detailed milestones.
    function submitProposal(
        string memory _title,
        string memory _descriptionIpfsHash,
        uint256 _totalFundingRequested,
        Milestone[] memory _milestones
    ) external onlyRegisteredParticipant whenNotPaused nonReentrant {
        require(bytes(_title).length > 0, "DeSciDAO: Title cannot be empty.");
        require(bytes(_descriptionIpfsHash).length > 0, "DeSciDAO: Description IPFS hash cannot be empty.");
        require(_totalFundingRequested > 0, "DeSciDAO: Funding requested must be greater than zero.");
        require(_milestones.length > 0, "DeSciDAO: Must have at least one milestone.");

        uint256 totalPercentage = 0;
        for (uint256 i = 0; i < _milestones.length; i++) {
            require(bytes(_milestones[i].descriptionIpfsHash).length > 0, "DeSciDAO: Milestone description cannot be empty.");
            require(_milestones[i].fundingPercentage > 0, "DeSciDAO: Milestone funding percentage must be greater than zero.");
            _milestones[i].status = MilestoneStatus.Pending; // Set initial status
            totalPercentage += _milestones[i].fundingPercentage;
        }
        require(totalPercentage == 100, "DeSciDAO: Milestone percentages must sum to 100.");

        // Require a deposit for submitting a proposal
        uint256 proposalDepositAmount = daoConfig[keccak256("PROPOSAL_DEPOSIT_AMOUNT")];
        require(stakeToken.transferFrom(msg.sender, address(this), proposalDepositAmount), "DeSciDAO: Proposal deposit failed.");

        uint256 proposalId = nextProposalId++;
        projects[proposalId] = Project({
            id: proposalId,
            proposer: msg.sender,
            title: _title,
            descriptionIpfsHash: _descriptionIpfsHash,
            totalFundingRequested: _totalFundingRequested,
            currentFundedAmount: 0,
            creationTimestamp: block.timestamp,
            status: ProposalStatus.PendingReview,
            milestones: _milestones,
            votingStartTime: 0,
            votingEndTime: 0,
            totalVotesFor: 0,
            totalVotesAgainst: 0
        });
        // Initialize mappings within the struct (Solidity does this automatically for new struct instances)

        emit ProposalSubmitted(proposalId, msg.sender, _title, _totalFundingRequested);
    }

    // 14. cancelProposal(uint256 _proposalId): A proposer can cancel their own proposal if it's still in the PendingReview stage.
    function cancelProposal(uint256 _proposalId) external onlyProjectProposer(_proposalId) whenNotPaused nonReentrant {
        Project storage project = projects[_proposalId];
        require(project.status == ProposalStatus.PendingReview, "DeSciDAO: Proposal can only be cancelled in PendingReview status.");

        project.status = ProposalStatus.Cancelled;

        // Refund the proposal deposit
        uint256 proposalDepositAmount = daoConfig[keccak256("PROPOSAL_DEPOSIT_AMOUNT")];
        require(stakeToken.transfer(msg.sender, proposalDepositAmount), "DeSciDAO: Failed to refund proposal deposit.");

        emit ProposalCanceled(_proposalId);
    }

    // 15. submitReview(uint256 _proposalId, string memory _reviewIpfsHash, bool _recommendation): Staked participants can submit a peer review.
    function submitReview(uint256 _proposalId, string memory _reviewIpfsHash, bool _recommendation) external onlyRegisteredParticipant whenNotPaused {
        Project storage project = projects[_proposalId];
        Participant storage participant = participants[msg.sender];

        require(project.status == ProposalStatus.PendingReview, "DeSciDAO: Proposal is not in review phase.");
        require(!project.hasReviewed[msg.sender], "DeSciDAO: Participant has already reviewed this proposal.");
        require(msg.sender != project.proposer, "DeSciDAO: Proposer cannot review their own proposal.");

        uint256 minReviewStake = daoConfig[keccak256("REVIEW_STAKE_REQUIREMENT")];
        require(participant.stakedTokens >= minReviewStake, "DeSciDAO: Insufficient staked tokens to review.");

        uint256 minReviewReputation = daoConfig[keccak256("MIN_REPUTATION_FOR_REVIEW")];
        require(participant.reputationScore >= minReviewReputation, "DeSciDAO: Insufficient reputation to review.");

        project.hasReviewed[msg.sender] = true;
        project.reviewCount++;
        if (_recommendation) {
            project.recommendationCount++;
        }

        // Reward reviewer with reputation
        participant.reputationScore += daoConfig[keccak256("REVIEWER_REPUTATION_BOOST")];
        emit ParticipantReputationAdjusted(msg.sender, participant.reputationScore - daoConfig[keccak256("REVIEWER_REPUTATION_BOOST")], participant.reputationScore);

        emit ReviewSubmitted(_proposalId, msg.sender, _reviewIpfsHash, _recommendation);

        // If enough reviews, transition to voting phase
        if (project.reviewCount >= daoConfig[keccak256("MIN_REVIEWS_FOR_VOTING")]) {
            project.status = ProposalStatus.ReadyForVote;
            // Optionally, auto-start voting:
            // startProposalVoting(_proposalId);
        }
    }

    // 16. startProposalVoting(uint256 _proposalId): Initiates the public voting phase for a proposal after sufficient reviews have been submitted.
    function startProposalVoting(uint256 _proposalId) external onlyDAO whenNotPaused {
        Project storage project = projects[_proposalId];
        require(project.status == ProposalStatus.ReadyForVote, "DeSciDAO: Proposal not ready for voting.");

        project.status = ProposalStatus.Voting;
        project.votingStartTime = block.timestamp;
        project.votingEndTime = block.timestamp + daoConfig[keccak256("VOTING_PERIOD_DURATION")];
        emit ProposalVotingStarted(_proposalId);
    }

    // 17. voteOnProposal(uint256 _proposalId, bool _support): Registered participants vote on a proposal (weighted by their staked tokens and reputation).
    function voteOnProposal(uint256 _proposalId, bool _support) external onlyRegisteredParticipant whenNotPaused {
        Project storage project = projects[_proposalId];
        Participant storage participant = participants[msg.sender];

        require(project.status == ProposalStatus.Voting, "DeSciDAO: Proposal is not in active voting phase.");
        require(block.timestamp >= project.votingStartTime && block.timestamp <= project.votingEndTime, "DeSciDAO: Voting is not open.");
        require(!project.hasVotedOnProposal[msg.sender], "DeSciDAO: Participant has already voted on this proposal.");

        // Vote weight combines staked tokens and reputation (could be more complex, e.g., quadratic)
        uint256 voteWeight = participant.stakedTokens + participant.reputationScore;
        require(voteWeight > 0, "DeSciDAO: Voter has no influence (no staked tokens or reputation).");

        if (_support) {
            project.totalVotesFor += voteWeight;
        } else {
            project.totalVotesAgainst += voteWeight;
        }
        project.hasVotedOnProposal[msg.sender] = true;

        // Reward voter with a small reputation boost
        participant.reputationScore += daoConfig[keccak256("VOTER_REPUTATION_BOOST")];
        emit ParticipantReputationAdjusted(msg.sender, participant.reputationScore - daoConfig[keccak256("VOTER_REPUTATION_BOOST")], participant.reputationScore);

        emit ProposalVoted(_proposalId, msg.sender, _support, voteWeight);
    }

    // 18. finalizeProposalVoting(uint256 _proposalId): Ends the voting period and determines if a proposal is approved or rejected based on votes.
    function finalizeProposalVoting(uint256 _proposalId) external onlyDAO whenNotPaused nonReentrant {
        Project storage project = projects[_proposalId];
        require(project.status == ProposalStatus.Voting, "DeSciDAO: Proposal is not in voting phase.");
        require(block.timestamp > project.votingEndTime, "DeSciDAO: Voting period has not ended yet.");

        bool approved = project.totalVotesFor > project.totalVotesAgainst;
        if (approved) {
            project.status = ProposalStatus.Approved;
        } else {
            project.status = ProposalStatus.Rejected;
            // Optionally refund proposal deposit if rejected, or keep it for DAO.
            // For now, let's keep it in the DAO.
        }

        emit ProposalFinalized(_proposalId, approved, project.totalVotesFor, project.totalVotesAgainst);
    }

    // 19. submitMilestoneCompletion(uint256 _proposalId, uint256 _milestoneIndex, string memory _proofIpfsHash): Project leads submit proof of milestone completion.
    function submitMilestoneCompletion(uint256 _proposalId, uint256 _milestoneIndex, string memory _proofIpfsHash) external onlyProjectProposer(_proposalId) whenNotPaused {
        Project storage project = projects[_proposalId];
        require(project.status == ProposalStatus.Approved, "DeSciDAO: Project is not approved for funding.");
        require(_milestoneIndex < project.milestones.length, "DeSciDAO: Invalid milestone index.");
        require(project.milestones[_milestoneIndex].status == MilestoneStatus.Pending || project.milestones[_milestoneIndex].status == MilestoneStatus.Rejected, "DeSciDAO: Milestone is not in a state to be submitted.");
        require(bytes(_proofIpfsHash).length > 0, "DeSciDAO: Proof IPFS hash cannot be empty.");

        project.milestones[_milestoneIndex].status = MilestoneStatus.Submitted;
        project.milestones[_milestoneIndex].proofIpfsHash = _proofIpfsHash;
        project.milestones[_milestoneIndex].verificationAttempts++; // Increment attempt counter
        emit MilestoneCompletionSubmitted(_proposalId, _milestoneIndex, msg.sender, _proofIpfsHash);
    }

    // 20. verifyMilestone(uint256 _proposalId, uint256 _milestoneIndex, bool _isVerified): Designated verifiers (or DAO vote) confirm milestone completion.
    function verifyMilestone(uint256 _proposalId, uint256 _milestoneIndex, bool _isVerified) external onlyDAO whenNotPaused {
        Project storage project = projects[_proposalId];
        require(project.status == ProposalStatus.Approved, "DeSciDAO: Project is not approved.");
        require(_milestoneIndex < project.milestones.length, "DeSciDAO: Invalid milestone index.");
        require(project.milestones[_milestoneIndex].status == MilestoneStatus.Submitted, "DeSciDAO: Milestone is not submitted for verification.");

        Milestone storage milestone = project.milestones[_milestoneIndex];

        if (_isVerified) {
            milestone.status = MilestoneStatus.Verified;
            // Reward verifier with reputation (the 'owner' in this simplified example)
            participants[msg.sender].reputationScore += daoConfig[keccak256("MILESTONE_VERIFIER_REPUTATION_BOOST")];
            emit ParticipantReputationAdjusted(msg.sender, participants[msg.sender].reputationScore - daoConfig[keccak256("MILESTONE_VERIFIER_REPUTATION_BOOST")], participants[msg.sender].reputationScore);
        } else {
            milestone.status = MilestoneStatus.Rejected;
            milestone.proofIpfsHash = ""; // Clear proof for re-submission
            // Optionally, penalize proposer if milestone is repeatedly rejected
        }
        emit MilestoneVerified(_proposalId, _milestoneIndex, msg.sender);
    }

    // 21. releaseMilestoneFunds(uint256 _proposalId, uint256 _milestoneIndex): Releases funds for a verified milestone to the project proposer.
    function releaseMilestoneFunds(uint256 _proposalId, uint256 _milestoneIndex) external onlyDAO whenNotPaused nonReentrant {
        Project storage project = projects[_proposalId];
        require(project.status == ProposalStatus.Approved, "DeSciDAO: Project is not approved.");
        require(_milestoneIndex < project.milestones.length, "DeSciDAO: Invalid milestone index.");
        require(project.milestones[_milestoneIndex].status == MilestoneStatus.Verified, "DeSciDAO: Milestone is not verified.");
        require(project.milestones[_milestoneIndex].releaseTimestamp == 0, "DeSciDAO: Funds for this milestone already released.");

        Milestone storage milestone = project.milestones[_milestoneIndex];

        uint256 amountToRelease = (project.totalFundingRequested * milestone.fundingPercentage) / 100;
        require(stakeToken.balanceOf(address(this)) >= amountToRelease, "DeSciDAO: Insufficient DAO funds for milestone.");
        require(stakeToken.transfer(project.proposer, amountToRelease), "DeSciDAO: Failed to transfer milestone funds.");

        project.currentFundedAmount += amountToRelease;
        milestone.releaseTimestamp = block.timestamp;

        emit FundsReleased(_proposalId, _milestoneIndex, project.proposer, amountToRelease);
    }


    // --- Dispute Resolution ---

    // 22. raiseDispute(uint256 _proposalId, uint256 _milestoneIndex, string memory _reasonIpfsHash): Allows any participant to raise a dispute against a milestone verification or completion. Requires a bond.
    function raiseDispute(uint256 _proposalId, uint256 _milestoneIndex, string memory _reasonIpfsHash) external onlyRegisteredParticipant whenNotPaused nonReentrant {
        Project storage project = projects[_proposalId];
        require(_milestoneIndex < project.milestones.length, "DeSciDAO: Invalid milestone index.");
        require(project.milestones[_milestoneIndex].status != MilestoneStatus.Pending && project.milestones[_milestoneIndex].status != MilestoneStatus.Disputed, "DeSciDAO: Milestone cannot be disputed in its current state.");
        require(!project.activeDisputes[_milestoneIndex].isActive, "DeSciDAO: Another dispute is already active for this milestone.");

        // Require a bond to prevent spamming disputes
        uint256 disputeBond = daoConfig[keccak256("DISPUTE_BOND_AMOUNT")];
        require(stakeToken.transferFrom(msg.sender, address(this), disputeBond), "DeSciDAO: Dispute bond transfer failed.");

        project.milestones[_milestoneIndex].status = MilestoneStatus.Disputed;
        project.activeDisputes[_milestoneIndex] = Dispute({
            disputer: msg.sender,
            reasonIpfsHash: _reasonIpfsHash,
            creationTime: block.timestamp,
            votingEndTime: block.timestamp + daoConfig[keccak256("DISPUTE_VOTING_PERIOD")],
            votesForResolution: 0,
            votesAgainstResolution: 0,
            isActive: true
        });
        // Initialize mapping within the struct

        emit DisputeRaised(_proposalId, _milestoneIndex, msg.sender, _reasonIpfsHash);
    }

    // 23. voteOnDispute(uint256 _proposalId, uint256 _milestoneIndex, bool _resolution): Registered participants vote to resolve an active dispute.
    function voteOnDispute(uint256 _proposalId, uint256 _milestoneIndex, bool _resolution) external onlyRegisteredParticipant whenNotPaused {
        Project storage project = projects[_proposalId];
        require(_milestoneIndex < project.milestones.length, "DeSciDAO: Invalid milestone index.");
        Dispute storage dispute = project.activeDisputes[_milestoneIndex];

        require(dispute.isActive, "DeSciDAO: No active dispute for this milestone.");
        require(block.timestamp <= dispute.votingEndTime, "DeSciDAO: Dispute voting period has ended.");
        require(!dispute.hasVotedOnDispute[msg.sender], "DeSciDAO: Participant has already voted on this dispute.");

        // Vote weight (same as proposal voting)
        uint256 voteWeight = participants[msg.sender].stakedTokens + participants[msg.sender].reputationScore;
        require(voteWeight > 0, "DeSciDAO: Voter has no influence (no staked tokens or reputation).");

        if (_resolution) { // True means supporting the disputer's claim
            dispute.votesForResolution += voteWeight;
        } else { // False means opposing the disputer's claim
            dispute.votesAgainstResolution += voteWeight;
        }
        dispute.hasVotedOnDispute[msg.sender] = true;

        // Reward voter with a small reputation boost
        participants[msg.sender].reputationScore += daoConfig[keccak256("VOTER_REPUTATION_BOOST")];
        emit ParticipantReputationAdjusted(msg.sender, participants[msg.sender].reputationScore - daoConfig[keccak256("VOTER_REPUTATION_BOOST")], participants[msg.sender].reputationScore);

        emit DisputeVoted(_proposalId, _milestoneIndex, msg.sender, _resolution);
    }

    // 24. resolveDispute(uint256 _proposalId, uint256 _milestoneIndex): Finalizes a dispute, applies penalties/rewards, and potentially reverts milestone status.
    function resolveDispute(uint256 _proposalId, uint256 _milestoneIndex) external onlyDAO whenNotPaused nonReentrant {
        Project storage project = projects[_proposalId];
        require(_milestoneIndex < project.milestones.length, "DeSciDAO: Invalid milestone index.");
        Dispute storage dispute = project.activeDisputes[_milestoneIndex];

        require(dispute.isActive, "DeSciDAO: No active dispute for this milestone.");
        require(block.timestamp > dispute.votingEndTime, "DeSciDAO: Dispute voting period has not ended yet.");

        uint256 disputeBond = daoConfig[keccak256("DISPUTE_BOND_AMOUNT")];
        uint256 reputationBoost = daoConfig[keccak256("DISPUTE_WINNER_REPUTATION_BOOST")];
        uint256 reputationPenalty = daoConfig[keccak256("DISPUTE_LOSER_REPUTATION_PENALTY")];

        bool disputerWon = dispute.votesForResolution > dispute.votesAgainstResolution;

        if (disputerWon) {
            // Disputer wins: milestone status is reverted/rejected, disputer gets bond back + reward
            if (project.milestones[_milestoneIndex].status == MilestoneStatus.Verified) {
                project.milestones[_milestoneIndex].status = MilestoneStatus.Rejected; // Revert verification
                project.milestones[_milestoneIndex].proofIpfsHash = ""; // Clear proof
            } else if (project.milestones[_milestoneIndex].status == MilestoneStatus.Submitted) {
                project.milestones[_milestoneIndex].status = MilestoneStatus.Rejected; // Confirm rejection
                project.milestones[_milestoneIndex].proofIpfsHash = "";
            }
            // Refund bond and reward disputer
            require(stakeToken.transfer(dispute.disputer, disputeBond), "DeSciDAO: Failed to refund disputer bond.");
            participants[dispute.disputer].reputationScore += reputationBoost;
            emit ParticipantReputationAdjusted(dispute.disputer, participants[dispute.disputer].reputationScore - reputationBoost, participants[dispute.disputer].reputationScore);

            // Penalize the original verifier/proposer (depending on dispute context)
            // For simplicity, let's say original verifier (if any) or project proposer.
            // This would need more granular logic to determine who to penalize based on dispute type.
            // For now, let's penalize proposer if it's a 'completion' dispute.
             if (participants[project.proposer].isRegistered) {
                uint256 oldProposerReputation = participants[project.proposer].reputationScore;
                participants[project.proposer].reputationScore = oldProposerReputation > reputationPenalty ? oldProposerReputation - reputationPenalty : 0;
                emit ParticipantReputationAdjusted(project.proposer, oldProposerReputation, participants[project.proposer].reputationScore);
            }


        } else {
            // Disputer loses: milestone status remains unchanged, disputer loses bond, original verifier/proposer might get reward
            // Dispute bond is kept by the DAO
            // Reward the counter-party (e.g., the original verifier, or proposer if dispute was on completion)
            // This would also need more granular logic. For now, general DAO treasury benefits.
            participants[dispute.disputer].reputationScore = participants[dispute.disputer].reputationScore > reputationPenalty ? participants[dispute.disputer].reputationScore - reputationPenalty : 0;
            emit ParticipantReputationAdjusted(dispute.disputer, participants[dispute.disputer].reputationScore + reputationPenalty, participants[dispute.disputer].reputationScore);
        }

        dispute.isActive = false; // Deactivate dispute
        emit DisputeResolved(_proposalId, _milestoneIndex, disputerWon);
    }


    // --- View Functions ---

    // 25. getParticipantInfo(address _participant): Retrieves a participant's reputation, staked tokens, and profile hash.
    function getParticipantInfo(address _participant) external view returns (bool isRegistered, string memory profileIpfsHash, uint256 reputationScore, uint256 stakedTokens) {
        Participant storage p = participants[_participant];
        return (p.isRegistered, p.profileIpfsHash, p.reputationScore, p.stakedTokens);
    }

    // 26. getProposal(uint256 _proposalId): Retrieves all details of a specific research proposal.
    function getProposal(uint256 _proposalId) external view returns (
        uint256 id,
        address proposer,
        string memory title,
        string memory descriptionIpfsHash,
        uint256 totalFundingRequested,
        uint256 currentFundedAmount,
        uint256 creationTimestamp,
        ProposalStatus status,
        uint256 totalMilestones,
        uint256 votingStartTime,
        uint256 votingEndTime,
        uint256 totalVotesFor,
        uint256 totalVotesAgainst,
        uint256 reviewCount,
        uint256 recommendationCount
    ) {
        Project storage project = projects[_proposalId];
        require(project.id != 0, "DeSciDAO: Proposal does not exist."); // Check if project exists
        return (
            project.id,
            project.proposer,
            project.title,
            project.descriptionIpfsHash,
            project.totalFundingRequested,
            project.currentFundedAmount,
            project.creationTimestamp,
            project.status,
            project.milestones.length,
            project.votingStartTime,
            project.votingEndTime,
            project.totalVotesFor,
            project.totalVotesAgainst,
            project.reviewCount,
            project.recommendationCount
        );
    }

    // 27. getMilestone(uint256 _proposalId, uint256 _milestoneIndex): Retrieves details for a specific milestone of a project.
    function getMilestone(uint256 _proposalId, uint256 _milestoneIndex) external view returns (
        string memory descriptionIpfsHash,
        uint256 fundingPercentage,
        MilestoneStatus status,
        uint256 releaseTimestamp,
        string memory proofIpfsHash,
        uint256 verificationAttempts,
        bool hasActiveDispute
    ) {
        Project storage project = projects[_proposalId];
        require(project.id != 0, "DeSciDAO: Proposal does not exist.");
        require(_milestoneIndex < project.milestones.length, "DeSciDAO: Invalid milestone index.");
        Milestone storage milestone = project.milestones[_milestoneIndex];
        return (
            milestone.descriptionIpfsHash,
            milestone.fundingPercentage,
            milestone.status,
            milestone.releaseTimestamp,
            milestone.proofIpfsHash,
            milestone.verificationAttempts,
            project.activeDisputes[_milestoneIndex].isActive
        );
    }

    // 28. getTotalAvailableFunds(): Returns the total funds currently available in the DAO treasury.
    function getTotalAvailableFunds() external view returns (uint256) {
        return stakeToken.balanceOf(address(this));
    }

    // 29. getProjectCount(): Returns the total number of proposals submitted.
    function getProjectCount() external view returns (uint256) {
        return nextProposalId - 1;
    }

    // 30. getDAOConfig(bytes32 _paramNameHash): Retrieves the current value of a specific DAO configuration parameter.
    function getDAOConfig(bytes32 _paramNameHash) external view returns (uint256) {
        return daoConfig[_paramNameHash];
    }
}
```