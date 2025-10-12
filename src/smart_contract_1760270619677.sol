The `QuantumLeapLabs` (QLL) smart contract is designed to power a Decentralized Autonomous Research & Development Lab (DARL). It provides a comprehensive framework for proposing, funding, managing, and validating research projects (called "Research Sprints") within broader "Innovation Tracks."

This contract incorporates several advanced, creative, and trendy concepts:
*   **Dynamic Reputation System (DRS):** Users earn category-specific reputation scores (General, Researcher, Reviewer, TrackManager) based on their active participation and successful contributions. These scores influence governance and privileges.
*   **Adaptive Governance (AG):** Voting power for crucial proposals (like new Innovation Tracks) is not solely based on token holdings but dynamically incorporates a user's staked governance tokens (`QLLToken`) *and* their general reputation score, fostering meritocracy.
*   **Milestone-Based Escrowed Funding (MBEF):** Research Sprint budgets are locked in escrow within the contract. Funds are released progressively to researchers only upon successful completion and peer review of predefined milestones, ensuring accountability.
*   **On-chain Proof-of-Work/Research (PoWR):** Deliverables for milestones and full research proposals are attested on-chain using IPFS hashes, providing an immutable record of research outcomes.
*   **Incentivized Peer Review:** A dedicated system for assigning and rewarding reviewers ensures quality control. Reviewers earn reputation and `QLLToken` rewards for their contributions.
*   **Dynamic NFT Rewards (DNR):** The contract includes a mechanism to award unique, potentially dynamic, NFT badges to users for significant achievements, high reputation tiers, or successful project completions (requires an external NFT contract).
*   **Role-Based Access Control:** Utilizes modifiers to restrict sensitive actions to specific roles (e.g., `onlyOwner`, `onlyTrackManager`, `onlyResearcher`, `onlyAssignedReviewer`).
*   **Pausable Functionality:** An emergency pause mechanism ensures contract safety in unforeseen circumstances.

---

### **Outline and Function Summary:**

This contract facilitates a Decentralized Autonomous Research & Development Lab (DARL) called "QuantumLeap Labs" (QLL). It enables proposing and funding innovation tracks, managing research sprints within those tracks, a reputation system for participants, and milestone-based fund releases.

**I. Core Management & Setup**
1.  **`constructor(address _qllTokenAddress, address _nftContractAddress)`**: Initializes the contract owner, the address of the QLL governance token (ERC20), and an optional NFT contract address for rewards.
2.  **`updateQLLTokenAddress(address _newAddress)`**: Allows the contract owner to update the QLL ERC20 token address.
3.  **`updateNFTContractAddress(address _newAddress)`**: Allows the contract owner to update the associated NFT contract address.
4.  **`pauseContract()`**: Emergency function for the owner to pause critical contract functionalities.
5.  **`unpauseContract()`**: Function for the owner to unpause the contract after an emergency.

**II. Innovation Track Management (High-level research domains)**
6.  **`proposeInnovationTrack(string memory _name, string memory _description, uint256 _requiredQLLStake, address _managerCandidate)`**: Allows any user to propose a new, broad innovation track. Requires a QLL token stake as a commitment, acting as a token-curated registry entry.
7.  **`voteOnInnovationTrackProposal(uint256 _trackProposalId, bool _for)`**: Allows QLL token stakers to vote on proposed innovation tracks. Voting power is dynamically calculated based on staked QLL tokens and the voter's general reputation score.
8.  **`executeInnovationTrackProposal(uint256 _trackProposalId)`**: Finalizes an innovation track proposal if it has passed voting. This activates the track, distributes rewards/stakes, and initializes its budget.
9.  **`depositToTrackBudget(uint256 _trackId, uint256 _amount)`**: Allows anyone to contribute QLL tokens to an active innovation track's budget pool.
10. **`updateTrackManager(uint256 _trackId, address _newManager)`**: Allows the current track manager to assign a new manager for a track, impacting reputation scores.

**III. Researcher Profile Management**
11. **`createResearcherProfile(string memory _name, string memory _bio, string[] memory _expertiseTags, string memory _linkedSocialsIpfsHash)`**: Enables users to establish a public researcher profile within QuantumLeap Labs, detailing their expertise and external links.
12. **`updateResearcherProfile(string memory _name, string memory _bio, string memory _linkedSocialsIpfsHash)`**: Allows researchers to modify their existing profile details.
13. **`updateResearcherExpertise(string[] memory _newExpertiseTags)`**: Allows researchers to update the list of expertise tags associated with their profile.

**IV. Research Sprint Management (Specific projects within tracks)**
14. **`proposeResearchSprint(uint256 _trackId, string memory _title, string memory _abstract, string memory _ipfsHashOfProposal, Milestone[] memory _milestones, uint256 _allocatedBudget)`**: Researchers propose specific, time-bound research projects (sprints) within an active innovation track, including detailed milestones and a requested budget.
15. **`approveResearchSprintProposal(uint256 _sprintId)`**: The track manager approves a proposed research sprint. This action transfers the allocated budget from the track's general pool into the sprint's escrow, and updates reputations.
16. **`submitMilestoneDeliverable(uint256 _sprintId, uint256 _milestoneIndex, string memory _ipfsHashOfDeliverable)`**: A researcher submits verifiable proof (e.g., IPFS hash of results/code) for a completed milestone.

**V. Review & Validation System**
17. **`assignReviewersToSprint(uint256 _sprintId, address[] memory _reviewerAddresses)`**: The track manager assigns a set of qualified reviewers to a specific research sprint, ideally considering their expertise and reputation.
18. **`submitMilestoneReview(uint256 _sprintId, uint256 _milestoneIndex, bool _approved, string memory _feedbackIpfsHash)`**: An assigned reviewer submits their evaluation for a milestone deliverable, approving or rejecting it. This action updates the reviewer's reputation.
19. **`claimReviewerReward(uint256 _reviewId)`**: Allows reviewers to claim QLL token rewards for their approved and completed reviews.

**VI. Fund Release & Completion**
20. **`releaseMilestonePayment(uint256 _sprintId, uint256 _milestoneIndex)`**: Releases a portion of the sprint's escrowed budget to the researcher upon successful review and approval of a milestone. Automatically advances the sprint to the next milestone or marks it as completed.
21. **`completeResearchSprint(uint256 _sprintId)`**: Marks a research sprint as fully completed after all its milestones have been reviewed and paid out, awarding significant researcher reputation. This can also be triggered automatically by `releaseMilestonePayment` for the last milestone.

**VII. Reputation & Rewards**
22. **`getReputationScore(address _user, ReputationCategory _category)`**: Retrieves a user's current reputation score within a specific category (e.g., Researcher, Reviewer, General).
23. **`awardNFTBadge(address _recipient, uint256 _nftId, string memory _tokenURI)`**: Awards a dynamic NFT badge to a user, typically for significant achievements or reputation tiers. This interacts with an external NFT contract.

**VIII. Governance & Tokenomics (Simplified)**
24. **`stakeQLLForVoting(uint256 _amount)`**: Allows users to stake QLL tokens to increase their voting power for various governance proposals and gain general reputation.
25. **`unstakeQLLForVoting(uint256 _amount)`**: Allows users to unstake their QLL tokens, reducing their voting power and reversing general reputation gains.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // For NFT integration idea, using an interface

// Interface for a custom NFT contract that QuantumLeapLabs will interact with.
// This allows for "dynamic" NFT rewards where the tokenURI (metadata) can be
// set at mint time, or potentially updated by the NFT contract owner later.
interface IQLLNFT is IERC721 {
    function mint(address to, uint256 tokenId, string calldata tokenURI) external;
    // Potentially add functions like `updateTokenURI(uint256 tokenId, string calldata newTokenURI)`
    // if dynamic metadata updates are desired and handled by the external NFT contract.
}

// Outline and Function Summary for QuantumLeapLabs Smart Contract:
// This contract facilitates a Decentralized Autonomous Research & Development Lab (DARL)
// called "QuantumLeap Labs" (QLL). It enables proposing and funding innovation tracks,
// managing research sprints within those tracks, a reputation system for participants,
// and milestone-based fund releases.

// I. Core Management & Setup
// 1.  constructor(address _qllTokenAddress, address _nftContractAddress): Initializes the contract owner,
//     the address of the QLL governance token (ERC20), and an optional NFT contract address for rewards.
// 2.  updateQLLTokenAddress(address _newAddress): Allows the contract owner to update the QLL ERC20 token address.
// 3.  updateNFTContractAddress(address _newAddress): Allows the contract owner to update the associated NFT contract address.
// 4.  pauseContract(): Emergency function for the owner to pause critical contract functionalities.
// 5.  unpauseContract(): Function for the owner to unpause the contract after an emergency.

// II. Innovation Track Management (High-level research domains)
// 6.  proposeInnovationTrack(string memory _name, string memory _description, uint256 _requiredQLLStake, address _managerCandidate):
//     Allows any user to propose a new, broad innovation track. Requires a QLL token stake as a commitment.
// 7.  voteOnInnovationTrackProposal(uint256 _trackProposalId, bool _for):
//     Allows QLL token stakers to vote on proposed innovation tracks. Voting power is dynamically calculated
//     based on staked QLL tokens and the voter's general reputation score.
// 8.  executeInnovationTrackProposal(uint256 _trackProposalId):
//     Finalizes an innovation track proposal if it has passed voting. This activates the track,
//     transfers stakes, and initializes its budget.
// 9.  depositToTrackBudget(uint256 _trackId, uint256 _amount):
//     Allows anyone to contribute QLL tokens to an active innovation track's budget pool.
// 10. updateTrackManager(uint256 _trackId, address _newManager):
//     Allows the current track manager (or potentially through a future DAO vote) to assign a new manager for a track.

// III. Researcher Profile Management
// 11. createResearcherProfile(string memory _name, string memory _bio, string[] memory _expertiseTags, string memory _linkedSocialsIpfsHash):
//     Enables users to establish a public researcher profile within QuantumLeap Labs, detailing their expertise.
// 12. updateResearcherProfile(string memory _name, string memory _bio, string memory _linkedSocialsIpfsHash):
//     Allows researchers to modify their existing profile details (name, bio, external links).
// 13. updateResearcherExpertise(string[] memory _newExpertiseTags):
//     Allows researchers to update the list of expertise tags associated with their profile.

// IV. Research Sprint Management (Specific projects within tracks)
// 14. proposeResearchSprint(uint256 _trackId, string memory _title, string memory _abstract, string memory _ipfsHashOfProposal, Milestone[] memory _milestones, uint256 _allocatedBudget):
//     Researchers propose specific, time-bound research projects (sprints) within an active innovation track,
//     including detailed milestones and a requested budget.
// 15. approveResearchSprintProposal(uint256 _sprintId):
//     The track manager (or through a separate DAO vote) approves a proposed research sprint. This action
//     transfers the allocated budget from the track's general pool into the sprint's escrow.
// 16. submitMilestoneDeliverable(uint256 _sprintId, uint256 _milestoneIndex, string memory _ipfsHashOfDeliverable):
//     A researcher submits verifiable proof (e.g., IPFS hash of results/code) for a completed milestone.

// V. Review & Validation System
// 17. assignReviewersToSprint(uint256 _sprintId, address[] memory _reviewerAddresses):
//     The track manager assigns a set of qualified reviewers to a specific research sprint, considering their expertise and reputation.
// 18. submitMilestoneReview(uint256 _sprintId, uint256 _milestoneIndex, bool _approved, string memory _feedbackIpfsHash):
//     An assigned reviewer submits their evaluation for a milestone deliverable, approving or rejecting it.
//     This action updates the reviewer's reputation.
// 19. claimReviewerReward(uint256 _reviewId):
//     Allows reviewers to claim QLL token rewards for their approved and completed reviews.

// VI. Fund Release & Completion
// 20. releaseMilestonePayment(uint256 _sprintId, uint256 _milestoneIndex):
//     Releases a portion of the sprint's escrowed budget to the researcher upon successful review and approval of a milestone.
// 21. completeResearchSprint(uint256 _sprintId):
//     Marks a research sprint as fully completed after all its milestones have been reviewed and paid out.
//     Awards researcher reputation.

// VII. Reputation & Rewards
// 22. getReputationScore(address _user, ReputationCategory _category):
//     Retrieves a user's current reputation score within a specific category (e.g., Researcher, Reviewer, General).
// 23. awardNFTBadge(address _recipient, uint256 _nftId, string memory _tokenURI):
//     Awards a dynamic NFT badge to a user, typically for significant achievements or reputation tiers.
//     This interacts with an external NFT contract.

// VIII. Governance & Tokenomics (Simplified)
// 24. stakeQLLForVoting(uint256 _amount):
//     Allows users to stake QLL tokens to increase their voting power for various governance proposals.
// 25. unstakeQLLForVoting(uint256 _amount):
//     Allows users to unstake their QLL tokens, reducing their voting power.

// Internal Helper Functions (Not direct external calls, but part of contract logic)
// - _updateReputation(address _user, ReputationCategory _category, int256 _delta): Internal function to modify reputation scores.
// - _calculateVotingPower(address _voter, uint256 _snapshotBlock): Internal function to determine a voter's influence.

contract QuantumLeapLabs is Ownable, Pausable {
    IERC20 public qllToken; // Governance and utility token
    IQLLNFT public qllNftContract; // NFT contract for badges and achievements

    // --- Counters for unique IDs ---
    uint256 public nextInnovationTrackId;
    uint256 public nextResearchSprintId;
    uint256 public nextResearcherProfileId;
    uint256 public nextReviewId;
    uint256 public nextTrackProposalId;

    // --- Enums ---
    enum TrackStatus { Proposed, Active, Paused, Completed, Cancelled }
    enum SprintStatus { Proposed, Active, MilestonePendingReview, ReviewApproved, ReviewRejected, Completed, Cancelled }
    enum ReviewStatus { Pending, Approved, Rejected }
    enum ReputationCategory { General, Researcher, Reviewer, TrackManager }

    // --- Structs ---
    struct InnovationTrack {
        uint256 trackId;
        string name;
        string description;
        address managerAddress;
        uint256 budgetPool; // QLL tokens held for this track. Funds track sprints and reviewer rewards.
        TrackStatus status;
        uint256 creationTime;
        uint256 completionTime;
        uint256 requiredQLLStakeForProposal; // Minimum QLL stake required to propose this track
        uint256 totalSprints; // Count of sprints under this track
    }

    struct Milestone {
        string description;
        uint256 targetCompletionDate;
        uint256 paymentPercentage; // Percentage of sprint's total budget, e.g., 2500 for 25%
        bool isCompleted; // True if researcher has submitted deliverable
        bool isReviewed; // True if a review has been submitted
        bool isApproved; // True if the milestone passed review
        string ipfsHashOfDeliverable; // IPFS hash pointing to the milestone deliverable
        uint256 reviewId; // Link to the associated review entry
    }

    struct ResearchSprint {
        uint256 sprintId;
        uint256 trackId;
        address researcherAddress;
        string title;
        string abstract;
        string ipfsHashOfProposal; // IPFS hash of the initial sprint proposal document
        uint256 allocatedBudget; // Total QLL tokens allocated for this sprint (escrowed)
        Milestone[] milestones; // Array of milestones for the sprint
        uint256 currentMilestoneIndex; // Index of the milestone currently being worked on/reviewed
        SprintStatus status;
        uint256 creationTime;
        uint256 completionTime;
        uint256 requiredReviewers; // Number of reviewers required for each milestone
        address[] assignedReviewers; // Addresses of reviewers assigned to the current milestone
        mapping(address => bool) hasAssignedReviewer; // Helper to quickly check reviewer assignment
        mapping(uint256 => bool) milestonePaid; // Tracks if a specific milestone payment has been released
    }

    struct ResearcherProfile {
        uint256 profileId;
        address userAddress;
        string name;
        string bio;
        string[] expertiseTags; // Array of strings for researcher's expertise
        string linkedSocialsIpfsHash; // IPFS hash to a JSON file or similar for linked socials/portfolio
        uint256 activeSprints; // Number of sprints currently active for this researcher
        uint256 completedSprints; // Number of sprints successfully completed by this researcher
    }

    struct Review {
        uint256 reviewId;
        uint256 sprintId;
        uint256 milestoneIndex;
        address reviewerAddress;
        ReviewStatus reviewStatus;
        string feedbackIpfsHash; // IPFS hash of the reviewer's feedback
        uint256 reviewTime;
        bool rewardClaimed;
    }

    struct TrackProposal {
        uint256 proposalId;
        address proposer;
        InnovationTrack trackDetails; // Details of the proposed track
        uint256 requiredStakeAmount; // QLL tokens required to propose
        uint256 stakedTokens; // Actual tokens staked for this proposal
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed; // True if the proposal has been processed (pass or fail)
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
        // For truly adaptive governance, this would involve a snapshot of token balances
        // and reputation at `snapshotBlock`. For simplicity, `stakedQLLForVoting` and
        // current reputation are used in `_calculateVotingPower`.
        uint256 snapshotBlock; // Block number at which to consider voting power
    }

    // --- Mappings ---
    mapping(uint256 => InnovationTrack) public innovationTracks;
    mapping(uint256 => ResearchSprint) public researchSprints;
    mapping(address => ResearcherProfile) public researcherProfiles; // Address -> ResearcherProfile
    mapping(uint256 => Review) public reviews;
    mapping(ReputationCategory => mapping(address => uint256)) public reputationScores; // Category -> User Address -> Score
    mapping(address => uint256) public stakedQLLForVoting; // User Address -> Amount of QLL staked for general voting
    mapping(uint256 => TrackProposal) public trackProposals;

    // --- Events ---
    event QLLTokenAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event NFTContractAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event InnovationTrackProposed(uint256 indexed proposalId, address indexed proposer, string name, uint256 requiredStake);
    event InnovationTrackVoted(uint256 indexed proposalId, address indexed voter, bool _for, uint256 votePower);
    event InnovationTrackExecuted(uint256 indexed trackId, address indexed manager, string name, bool passed);
    event InnovationTrackBudgetDeposited(uint256 indexed trackId, address indexed depositor, uint256 amount);
    event TrackManagerUpdated(uint256 indexed trackId, address indexed oldManager, address indexed newManager);
    event ResearcherProfileCreated(uint256 indexed profileId, address indexed userAddress);
    event ResearcherProfileUpdated(uint256 indexed profileId, address indexed userAddress);
    event ResearchSprintProposed(uint256 indexed sprintId, uint256 indexed trackId, address indexed researcher, uint256 allocatedBudget);
    event ResearchSprintApproved(uint256 indexed sprintId, address indexed approver, uint256 allocatedBudget);
    event MilestoneDeliverableSubmitted(uint256 indexed sprintId, uint256 indexed milestoneIndex, address indexed researcher, string ipfsHash);
    event ReviewersAssigned(uint256 indexed sprintId, address indexed trackManager, address[] reviewers);
    event MilestoneReviewed(uint256 indexed reviewId, uint256 indexed sprintId, uint256 indexed milestoneIndex, address indexed reviewer, bool approved);
    event ReviewerRewardClaimed(uint256 indexed reviewId, address indexed reviewer, uint256 amount);
    event MilestonePaymentReleased(uint256 indexed sprintId, uint256 indexed milestoneIndex, address indexed researcher, uint256 amount);
    event ResearchSprintCompleted(uint256 indexed sprintId);
    event ReputationUpdated(address indexed user, ReputationCategory category, uint256 newScore);
    event NFTBadgeAwarded(address indexed recipient, uint256 tokenId, string tokenURI);
    event QLLStaked(address indexed staker, uint256 amount);
    event QLLUnstaked(address indexed unstaker, uint256 amount);


    // --- Modifiers ---
    modifier onlyTrackManager(uint256 _trackId) {
        require(innovationTracks[_trackId].managerAddress == msg.sender, "QLL: Only track manager can perform this action");
        _;
    }

    modifier onlyResearcher(uint256 _sprintId) {
        require(researchSprints[_sprintId].researcherAddress == msg.sender, "QLL: Only sprint researcher can perform this action");
        _;
    }

    modifier onlyAssignedReviewer(uint256 _sprintId, address _reviewer) {
        require(researchSprints[_sprintId].hasAssignedReviewer[_reviewer], "QLL: Caller is not an assigned reviewer for this sprint's current milestone");
        _;
    }

    constructor(address _qllTokenAddress, address _nftContractAddress) Ownable(msg.sender) {
        require(_qllTokenAddress != address(0), "QLL: QLL token address cannot be zero");
        qllToken = IERC20(_qllTokenAddress);
        if (_nftContractAddress != address(0)) {
            qllNftContract = IQLLNFT(_nftContractAddress);
        }

        nextInnovationTrackId = 1;
        nextResearchSprintId = 1;
        nextResearcherProfileId = 1;
        nextReviewId = 1;
        nextTrackProposalId = 1;
    }

    // I. Core Management & Setup

    // 2. Update QLL Token Address
    function updateQLLTokenAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "QLL: New QLL token address cannot be zero");
        emit QLLTokenAddressUpdated(address(qllToken), _newAddress);
        qllToken = IERC20(_newAddress);
    }

    // 3. Update NFT Contract Address
    function updateNFTContractAddress(address _newAddress) external onlyOwner {
        if (_newAddress == address(0)) {
            qllNftContract = IQLLNFT(address(0)); // Allow setting to zero to disable NFT features
        } else {
            qllNftContract = IQLLNFT(_newAddress);
        }
        emit NFTContractAddressUpdated(address(qllNftContract), _newAddress);
    }

    // 4. Pause Contract
    function pauseContract() external onlyOwner {
        _pause();
    }

    // 5. Unpause Contract
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    // II. Innovation Track Management

    // 6. Propose Innovation Track
    function proposeInnovationTrack(
        string memory _name,
        string memory _description,
        uint256 _requiredQLLStake,
        address _managerCandidate
    ) external whenNotPaused {
        require(bytes(_name).length > 0, "QLL: Track name cannot be empty");
        require(bytes(_description).length > 0, "QLL: Track description cannot be empty");
        require(_requiredQLLStake > 0, "QLL: Required QLL stake must be greater than zero");
        require(_managerCandidate != address(0), "QLL: Manager candidate cannot be zero address");
        require(qllToken.transferFrom(msg.sender, address(this), _requiredQLLStake), "QLL: Failed to transfer stake tokens for proposal");

        uint256 proposalId = nextTrackProposalId++;
        TrackProposal storage proposal = trackProposals[proposalId];
        proposal.proposalId = proposalId;
        proposal.proposer = msg.sender;
        // Temporary trackDetails, actual trackId assigned upon execution
        proposal.trackDetails = InnovationTrack({
            trackId: 0,
            name: _name,
            description: _description,
            managerAddress: _managerCandidate,
            budgetPool: 0,
            status: TrackStatus.Proposed,
            creationTime: block.timestamp,
            completionTime: 0,
            requiredQLLStakeForProposal: _requiredQLLStake,
            totalSprints: 0
        });
        proposal.requiredStakeAmount = _requiredQLLStake;
        proposal.stakedTokens = _requiredQLLStake; // The tokens staked by the proposer
        proposal.voteStartTime = block.timestamp;
        proposal.voteEndTime = block.timestamp + 7 days; // 7-day voting period example
        proposal.snapshotBlock = block.number; // Snapshot block for voting power

        emit InnovationTrackProposed(proposalId, msg.sender, _name, _requiredQLLStake);
    }

    // Internal helper for calculating voting power. For a true snapshot,
    // the QLL token contract would need a `balanceOfAt(address, uint256)` function.
    // For simplicity here, `stakedQLLForVoting` is used as a proxy for the 'at snapshot' balance.
    function _calculateVotingPower(address _voter, uint256 _snapshotBlock) internal view returns (uint256) {
        // Voting power = staked QLL + (General Reputation / 100)
        uint256 stakedBalance = stakedQLLForVoting[_voter];
        uint256 generalRep = reputationScores[ReputationCategory.General][_voter];

        // Ensure reputation adds a meaningful but not overwhelming influence
        uint256 reputationInfluence = generalRep / 100; // e.g., 100 General Rep = 1 QLL voting power
        return stakedBalance + reputationInfluence;
    }

    // 7. Vote On Innovation Track Proposal
    function voteOnInnovationTrackProposal(uint256 _trackProposalId, bool _for) external whenNotPaused {
        TrackProposal storage proposal = trackProposals[_trackProposalId];
        require(proposal.proposalId != 0, "QLL: Proposal does not exist");
        require(block.timestamp >= proposal.voteStartTime && block.timestamp <= proposal.voteEndTime, "QLL: Voting period not active");
        require(!proposal.hasVoted[msg.sender], "QLL: Already voted on this proposal");
        
        uint256 votePower = _calculateVotingPower(msg.sender, proposal.snapshotBlock);
        require(votePower > 0, "QLL: Caller has no voting power");

        proposal.hasVoted[msg.sender] = true;
        if (_for) {
            proposal.forVotes += votePower;
        } else {
            proposal.againstVotes += votePower;
        }
        emit InnovationTrackVoted(_trackProposalId, msg.sender, _for, votePower);
    }

    // 8. Execute Innovation Track Proposal
    function executeInnovationTrackProposal(uint256 _trackProposalId) external whenNotPaused {
        TrackProposal storage proposal = trackProposals[_trackProposalId];
        require(proposal.proposalId != 0, "QLL: Proposal does not exist");
        require(block.timestamp > proposal.voteEndTime, "QLL: Voting period not ended");
        require(!proposal.executed, "QLL: Proposal already executed");

        // Simple majority vote: for votes must be greater than against votes.
        // A more complex DAO would have quorum requirements, tiered voting, etc.
        bool proposalPassed = proposal.forVotes > proposal.againstVotes;

        proposal.executed = true; // Mark as executed regardless of outcome

        if (proposalPassed) {
            uint256 newTrackId = nextInnovationTrackId++;
            InnovationTrack storage newTrack = innovationTracks[newTrackId];
            newTrack = proposal.trackDetails; // Copy details from proposal
            newTrack.trackId = newTrackId;
            newTrack.status = TrackStatus.Active;
            newTrack.completionTime = 0; // Reset for actual track completion
            // The stake from proposal.stakedTokens implicitly remains in the contract's overall QLL balance.
            // It could be considered an initial contribution to the track's budget pool if desired.

            _updateReputation(proposal.proposer, ReputationCategory.General, 50); // Reward proposer for successful track
            _updateReputation(newTrack.managerAddress, ReputationCategory.TrackManager, 100); // Reward new manager

            emit InnovationTrackExecuted(newTrackId, newTrack.managerAddress, newTrack.name, true);
        } else {
            // If proposal fails, return the stake to the proposer
            require(qllToken.transfer(proposal.proposer, proposal.stakedTokens), "QLL: Failed to return stake for failed proposal");
            _updateReputation(proposal.proposer, ReputationCategory.General, -20); // Minor penalty for failed proposal
            emit InnovationTrackExecuted(0, address(0), proposal.trackDetails.name, false); // Emit with trackId 0 for failed
        }
    }

    // 9. Deposit To Track Budget
    function depositToTrackBudget(uint256 _trackId, uint256 _amount) external whenNotPaused {
        InnovationTrack storage track = innovationTracks[_trackId];
        require(track.trackId != 0, "QLL: Track does not exist");
        require(track.status == TrackStatus.Active, "QLL: Track is not active");
        require(_amount > 0, "QLL: Deposit amount must be greater than zero");
        require(qllToken.transferFrom(msg.sender, address(this), _amount), "QLL: Failed to transfer QLL to track budget");

        track.budgetPool += _amount;
        emit InnovationTrackBudgetDeposited(_trackId, msg.sender, _amount);
    }

    // 10. Update Track Manager
    function updateTrackManager(uint256 _trackId, address _newManager) external whenNotPaused onlyTrackManager(_trackId) {
        InnovationTrack storage track = innovationTracks[_trackId];
        require(_newManager != address(0), "QLL: New manager address cannot be zero");
        require(track.managerAddress != _newManager, "QLL: New manager is already the current manager");
        require(researcherProfiles[_newManager].profileId != 0, "QLL: New manager must have a researcher profile"); // Ensure legitimacy

        address oldManager = track.managerAddress;
        track.managerAddress = _newManager;
        _updateReputation(oldManager, ReputationCategory.TrackManager, -50); // Small rep decrease for stepping down
        _updateReputation(_newManager, ReputationCategory.TrackManager, 50); // Small rep increase for new manager

        emit TrackManagerUpdated(_trackId, oldManager, _newManager);
    }

    // III. Researcher Profile Management

    // 11. Create Researcher Profile
    function createResearcherProfile(
        string memory _name,
        string memory _bio,
        string[] memory _expertiseTags,
        string memory _linkedSocialsIpfsHash
    ) external whenNotPaused {
        require(researcherProfiles[msg.sender].profileId == 0, "QLL: Profile already exists for this address");
        require(bytes(_name).length > 0, "QLL: Name cannot be empty");

        uint256 profileId = nextResearcherProfileId++;
        ResearcherProfile storage profile = researcherProfiles[msg.sender];
        profile.profileId = profileId;
        profile.userAddress = msg.sender;
        profile.name = _name;
        profile.bio = _bio;
        profile.expertiseTags = _expertiseTags;
        profile.linkedSocialsIpfsHash = _linkedSocialsIpfsHash;

        _updateReputation(msg.sender, ReputationCategory.General, 10); // Reward for creating a profile
        emit ResearcherProfileCreated(profileId, msg.sender);
    }

    // 12. Update Researcher Profile
    function updateResearcherProfile(
        string memory _name,
        string memory _bio,
        string memory _linkedSocialsIpfsHash
    ) external whenNotPaused {
        ResearcherProfile storage profile = researcherProfiles[msg.sender];
        require(profile.profileId != 0, "QLL: Profile does not exist");

        profile.name = _name;
        profile.bio = _bio;
        profile.linkedSocialsIpfsHash = _linkedSocialsIpfsHash;

        emit ResearcherProfileUpdated(profile.profileId, msg.sender);
    }

    // 13. Update Researcher Expertise
    function updateResearcherExpertise(string[] memory _newExpertiseTags) external whenNotPaused {
        ResearcherProfile storage profile = researcherProfiles[msg.sender];
        require(profile.profileId != 0, "QLL: Profile does not exist");
        // Clear existing tags and add new ones (more gas efficient than individual add/remove)
        delete profile.expertiseTags;
        for (uint i = 0; i < _newExpertiseTags.length; i++) {
            profile.expertiseTags.push(_newExpertiseTags[i]);
        }
        // No specific event for expertise, covered by general profile update if needed or implicit.
    }

    // IV. Research Sprint Management

    // 14. Propose Research Sprint
    function proposeResearchSprint(
        uint256 _trackId,
        string memory _title,
        string memory _abstract,
        string memory _ipfsHashOfProposal,
        Milestone[] memory _milestones,
        uint256 _allocatedBudget
    ) external whenNotPaused {
        require(researcherProfiles[msg.sender].profileId != 0, "QLL: Only registered researchers can propose sprints");
        InnovationTrack storage track = innovationTracks[_trackId];
        require(track.trackId != 0 && track.status == TrackStatus.Active, "QLL: Innovation track is not active or does not exist");
        require(bytes(_title).length > 0, "QLL: Sprint title cannot be empty");
        require(_milestones.length > 0, "QLL: Sprint must have at least one milestone");
        require(_allocatedBudget > 0, "QLL: Allocated budget must be greater than zero");

        uint256 totalPercentage;
        for (uint i = 0; i < _milestones.length; i++) {
            require(_milestones[i].paymentPercentage > 0, "QLL: Milestone payment percentage must be positive");
            totalPercentage += _milestones[i].paymentPercentage;
        }
        require(totalPercentage == 10000, "QLL: Total milestone payment percentages must sum to 100% (10000 basis points)");

        // Budget check is done at approval time to allow tracks to gather funds
        // before approving a sprint, or for multiple sprints to wait for approval.

        uint256 sprintId = nextResearchSprintId++;
        ResearchSprint storage newSprint = researchSprints[sprintId];
        newSprint.sprintId = sprintId;
        newSprint.trackId = _trackId;
        newSprint.researcherAddress = msg.sender;
        newSprint.title = _title;
        newSprint.abstract = _abstract;
        newSprint.ipfsHashOfProposal = _ipfsHashOfProposal;
        newSprint.allocatedBudget = _allocatedBudget;
        newSprint.milestones = _milestones;
        newSprint.currentMilestoneIndex = 0;
        newSprint.status = SprintStatus.Proposed;
        newSprint.creationTime = block.timestamp;
        newSprint.requiredReviewers = 1; // Example: requires at least 1 reviewer per milestone. Can be track-specific.

        track.totalSprints++;
        researcherProfiles[msg.sender].activeSprints++; // Mark as active once proposed, to track workload

        _updateReputation(msg.sender, ReputationCategory.Researcher, 15); // Reward researcher for proposing a sprint
        emit ResearchSprintProposed(sprintId, _trackId, msg.sender, _allocatedBudget);
    }

    // 15. Approve Research Sprint Proposal
    function approveResearchSprintProposal(uint256 _sprintId) external whenNotPaused onlyTrackManager(researchSprints[_sprintId].trackId) {
        ResearchSprint storage sprint = researchSprints[_sprintId];
        require(sprint.sprintId != 0, "QLL: Sprint does not exist");
        require(sprint.status == SprintStatus.Proposed, "QLL: Sprint is not in proposed status");

        InnovationTrack storage track = innovationTracks[sprint.trackId];
        require(track.budgetPool >= sprint.allocatedBudget, "QLL: Insufficient track budget for sprint approval");

        // Transfer allocated budget from track pool to this contract (escrow for sprint).
        // The funds remain in the contract but are logically reserved for this sprint.
        track.budgetPool -= sprint.allocatedBudget;

        sprint.status = SprintStatus.Active;
        _updateReputation(sprint.researcherAddress, ReputationCategory.Researcher, 20); // Reward researcher for approved sprint
        _updateReputation(msg.sender, ReputationCategory.TrackManager, 10); // Reward manager for approving

        emit ResearchSprintApproved(_sprintId, msg.sender, sprint.allocatedBudget);
    }

    // 16. Submit Milestone Deliverable
    function submitMilestoneDeliverable(
        uint256 _sprintId,
        uint256 _milestoneIndex,
        string memory _ipfsHashOfDeliverable
    ) external whenNotPaused onlyResearcher(_sprintId) {
        ResearchSprint storage sprint = researchSprints[_sprintId];
        require(sprint.sprintId != 0, "QLL: Sprint does not exist");
        require(sprint.status == SprintStatus.Active || sprint.status == SprintStatus.ReviewRejected, "QLL: Sprint not active or currently under review for a different milestone");
        require(_milestoneIndex < sprint.milestones.length, "QLL: Invalid milestone index");
        require(_milestoneIndex == sprint.currentMilestoneIndex, "QLL: Deliverable can only be submitted for the current milestone");
        require(!sprint.milestones[_milestoneIndex].isCompleted, "QLL: Milestone already completed");
        require(bytes(_ipfsHashOfDeliverable).length > 0, "QLL: IPFS hash of deliverable cannot be empty");

        sprint.milestones[_milestoneIndex].isCompleted = true;
        sprint.milestones[_milestoneIndex].ipfsHashOfDeliverable = _ipfsHashOfDeliverable;
        sprint.status = SprintStatus.MilestonePendingReview; // Change status to indicate review is needed

        // Reset assigned reviewers for this milestone if there were any, as new ones might be needed or old ones re-assigned.
        for(uint i = 0; i < sprint.assignedReviewers.length; i++) {
            sprint.hasAssignedReviewer[sprint.assignedReviewers[i]] = false;
        }
        delete sprint.assignedReviewers; // Clear the array

        emit MilestoneDeliverableSubmitted(_sprintId, _milestoneIndex, msg.sender, _ipfsHashOfDeliverable);
    }

    // V. Review & Validation System

    // 17. Assign Reviewers To Sprint
    function assignReviewersToSprint(uint256 _sprintId, address[] memory _reviewerAddresses) external whenNotPaused onlyTrackManager(researchSprints[_sprintId].trackId) {
        ResearchSprint storage sprint = researchSprints[_sprintId];
        require(sprint.sprintId != 0, "QLL: Sprint does not exist");
        require(sprint.status == SprintStatus.MilestonePendingReview, "QLL: Sprint not in 'milestone pending review' status");
        require(_reviewerAddresses.length >= sprint.requiredReviewers, "QLL: Not enough reviewers assigned");

        // Clear previous assignments for this milestone before assigning new ones
        for(uint i = 0; i < sprint.assignedReviewers.length; i++) {
            sprint.hasAssignedReviewer[sprint.assignedReviewers[i]] = false;
        }
        delete sprint.assignedReviewers;

        for (uint i = 0; i < _reviewerAddresses.length; i++) {
            address reviewer = _reviewerAddresses[i];
            require(researcherProfiles[reviewer].profileId != 0, "QLL: Reviewer must have a researcher profile");
            require(reputationScores[ReputationCategory.Reviewer][reviewer] >= 10, "QLL: Reviewer does not meet minimum reputation requirement (10)"); // Example minimum rep
            require(!sprint.hasAssignedReviewer[reviewer], "QLL: Duplicate reviewer assignment");
            
            sprint.assignedReviewers.push(reviewer);
            sprint.hasAssignedReviewer[reviewer] = true;
        }

        emit ReviewersAssigned(_sprintId, msg.sender, _reviewerAddresses);
    }

    // 18. Submit Milestone Review
    function submitMilestoneReview(
        uint256 _sprintId,
        uint256 _milestoneIndex,
        bool _approved,
        string memory _feedbackIpfsHash
    ) external whenNotPaused onlyAssignedReviewer(_sprintId, msg.sender) {
        ResearchSprint storage sprint = researchSprints[_sprintId];
        require(sprint.sprintId != 0, "QLL: Sprint does not exist");
        require(_milestoneIndex < sprint.milestones.length, "QLL: Invalid milestone index");
        require(_milestoneIndex == sprint.currentMilestoneIndex, "QLL: Review can only be submitted for the current milestone");
        require(sprint.milestones[_milestoneIndex].isCompleted, "QLL: Deliverable not submitted for this milestone yet");
        require(!sprint.milestones[_milestoneIndex].isReviewed, "QLL: Milestone already reviewed");
        require(bytes(_feedbackIpfsHash).length > 0, "QLL: Feedback IPFS hash cannot be empty");

        uint256 reviewId = nextReviewId++;
        Review storage newReview = reviews[reviewId];
        newReview.reviewId = reviewId;
        newReview.sprintId = _sprintId;
        newReview.milestoneIndex = _milestoneIndex;
        newReview.reviewerAddress = msg.sender;
        newReview.reviewStatus = _approved ? ReviewStatus.Approved : ReviewStatus.Rejected;
        newReview.feedbackIpfsHash = _feedbackIpfsHash;
        newReview.reviewTime = block.timestamp;

        sprint.milestones[_milestoneIndex].isReviewed = true;
        sprint.milestones[_milestoneIndex].isApproved = _approved;
        sprint.milestones[_milestoneIndex].reviewId = reviewId;

        // Reputation update for reviewer
        if (_approved) {
            _updateReputation(msg.sender, ReputationCategory.Reviewer, 25);
            sprint.status = SprintStatus.ReviewApproved;
        } else {
            _updateReputation(msg.sender, ReputationCategory.Reviewer, -10); // Small penalty for rejecting, encourage constructive review
            sprint.status = SprintStatus.ReviewRejected;
        }

        // Remove reviewer from assigned list for this milestone
        sprint.hasAssignedReviewer[msg.sender] = false;

        emit MilestoneReviewed(reviewId, _sprintId, _milestoneIndex, msg.sender, _approved);
    }

    // 19. Claim Reviewer Reward
    function claimReviewerReward(uint256 _reviewId) external whenNotPaused {
        Review storage review = reviews[_reviewId];
        require(review.reviewId != 0, "QLL: Review does not exist");
        require(review.reviewerAddress == msg.sender, "QLL: Only the reviewer can claim their reward");
        require(review.reviewStatus == ReviewStatus.Approved, "QLL: Only approved reviews are eligible for rewards");
        require(!review.rewardClaimed, "QLL: Reward already claimed");

        // Example reward calculation: 50 QLL per approved review
        uint256 rewardAmount = 50 * (10 ** qllToken.decimals()); // Adjust for token decimals if needed
        
        // Reward comes from the track's budget pool
        ResearchSprint storage sprint = researchSprints[review.sprintId];
        InnovationTrack storage track = innovationTracks[sprint.trackId];
        require(track.budgetPool >= rewardAmount, "QLL: Insufficient track budget for reviewer reward");
        track.budgetPool -= rewardAmount;

        require(qllToken.transfer(review.reviewerAddress, rewardAmount), "QLL: Failed to transfer reviewer reward");
        review.rewardClaimed = true;

        emit ReviewerRewardClaimed(_reviewId, msg.sender, rewardAmount);
    }

    // VI. Fund Release & Completion

    // 20. Release Milestone Payment
    function releaseMilestonePayment(uint256 _sprintId, uint256 _milestoneIndex) external whenNotPaused onlyTrackManager(researchSprints[_sprintId].trackId) {
        ResearchSprint storage sprint = researchSprints[_sprintId];
        require(sprint.sprintId != 0, "QLL: Sprint does not exist");
        require(_milestoneIndex < sprint.milestones.length, "QLL: Invalid milestone index");
        require(_milestoneIndex == sprint.currentMilestoneIndex, "QLL: Payment can only be released for the current milestone");
        require(sprint.milestones[_milestoneIndex].isApproved, "QLL: Milestone not approved for payment");
        require(!sprint.milestonePaid[_milestoneIndex], "QLL: Milestone already paid");

        uint256 paymentAmount = (sprint.allocatedBudget * sprint.milestones[_milestoneIndex].paymentPercentage) / 10000; // 10000 = 100%

        require(qllToken.transfer(sprint.researcherAddress, paymentAmount), "QLL: Failed to transfer milestone payment");
        sprint.milestonePaid[_milestoneIndex] = true;

        _updateReputation(sprint.researcherAddress, ReputationCategory.Researcher, 30); // Reward researcher for milestone payment

        // Advance to next milestone
        sprint.currentMilestoneIndex++;
        
        // If this was the last milestone, mark sprint as completed
        if (sprint.currentMilestoneIndex == sprint.milestones.length) {
            sprint.status = SprintStatus.Completed;
            researcherProfiles[sprint.researcherAddress].completedSprints++;
            researcherProfiles[sprint.researcherAddress].activeSprints--;
            _updateReputation(sprint.researcherAddress, ReputationCategory.Researcher, 100); // Significant reward for sprint completion
            sprint.completionTime = block.timestamp;
            emit ResearchSprintCompleted(_sprintId);
        } else {
            sprint.status = SprintStatus.Active; // Reset status for the next milestone
        }

        emit MilestonePaymentReleased(_sprintId, _milestoneIndex, sprint.researcherAddress, paymentAmount);
    }

    // 21. Complete Research Sprint
    function completeResearchSprint(uint256 _sprintId) external whenNotPaused onlyTrackManager(researchSprints[_sprintId].trackId) {
        ResearchSprint storage sprint = researchSprints[_sprintId];
        require(sprint.sprintId != 0, "QLL: Sprint does not exist");
        require(sprint.status != SprintStatus.Completed, "QLL: Sprint already completed");
        require(sprint.currentMilestoneIndex == sprint.milestones.length, "QLL: Not all milestones processed for this sprint.");

        sprint.status = SprintStatus.Completed;
        researcherProfiles[sprint.researcherAddress].completedSprints++;
        researcherProfiles[sprint.researcherAddress].activeSprints--;
        _updateReputation(sprint.researcherAddress, ReputationCategory.Researcher, 100); // Ensure final rep update
        sprint.completionTime = block.timestamp;
        emit ResearchSprintCompleted(_sprintId);
    }


    // VII. Reputation & Rewards

    // Internal function to update reputation scores
    function _updateReputation(address _user, ReputationCategory _category, int256 _delta) internal {
        uint256 currentScore = reputationScores[_category][_user];
        if (_delta > 0) {
            reputationScores[_category][_user] = currentScore + uint256(_delta);
        } else {
            uint256 deltaAbs = uint256(-_delta);
            if (currentScore >= deltaAbs) {
                reputationScores[_category][_user] = currentScore - deltaAbs;
            } else {
                reputationScores[_category][_user] = 0; // Reputation cannot go below zero
            }
        }
        emit ReputationUpdated(_user, _category, reputationScores[_category][_user]);
    }

    // 22. Get Reputation Score
    function getReputationScore(address _user, ReputationCategory _category) external view returns (uint256) {
        return reputationScores[_category][_user];
    }

    // 23. Award NFT Badge
    function awardNFTBadge(address _recipient, uint256 _nftId, string memory _tokenURI) external onlyOwner whenNotPaused {
        require(address(qllNftContract) != address(0), "QLL: NFT contract not set");
        qllNftContract.mint(_recipient, _nftId, _tokenURI);
        emit NFTBadgeAwarded(_recipient, _nftId, _tokenURI);
    }

    // VIII. Governance & Tokenomics (Simplified)

    // 24. Stake QLL For Voting
    function stakeQLLForVoting(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "QLL: Stake amount must be positive");
        require(qllToken.transferFrom(msg.sender, address(this), _amount), "QLL: Failed to transfer QLL for staking");
        stakedQLLForVoting[msg.sender] += _amount;
        // Example: 10 QLL staked adds 1 General Rep (adjust based on token decimals and desired influence)
        _updateReputation(msg.sender, ReputationCategory.General, int256(_amount / (10 ** qllToken.decimals()) / 10));
        emit QLLStaked(msg.sender, _amount);
    }

    // 25. Unstake QLL From Voting
    function unstakeQLLForVoting(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "QLL: Unstake amount must be positive");
        require(stakedQLLForVoting[msg.sender] >= _amount, "QLL: Insufficient staked QLL");
        stakedQLLForVoting[msg.sender] -= _amount;
        require(qllToken.transfer(msg.sender, _amount), "QLL: Failed to transfer QLL back to user");
        // Reverse reputation gain proportionally
        _updateReputation(msg.sender, ReputationCategory.General, -int256(_amount / (10 ** qllToken.decimals()) / 10));
        emit QLLUnstaked(msg.sender, _amount);
    }

    // --- View/Getter Functions (for external data retrieval) ---

    function getTrackProposalVotingStatus(uint256 _proposalId)
        external
        view
        returns (
            uint256 forVotes,
            uint256 againstVotes,
            bool votingEnded,
            bool executed,
            bool passed
        )
    {
        TrackProposal storage proposal = trackProposals[_proposalId];
        require(proposal.proposalId != 0, "QLL: Proposal does not exist");
        forVotes = proposal.forVotes;
        againstVotes = proposal.againstVotes;
        votingEnded = block.timestamp > proposal.voteEndTime;
        executed = proposal.executed;
        passed = votingEnded && proposal.forVotes > proposal.againstVotes;
        return (forVotes, againstVotes, votingEnded, executed, passed);
    }

    function getInnovationTrack(uint256 _trackId)
        external
        view
        returns (
            uint256 trackId,
            string memory name,
            string memory description,
            address managerAddress,
            uint256 budgetPool,
            TrackStatus status,
            uint256 creationTime,
            uint256 completionTime,
            uint256 requiredQLLStakeForProposal,
            uint256 totalSprints
        )
    {
        InnovationTrack storage track = innovationTracks[_trackId];
        return (
            track.trackId,
            track.name,
            track.description,
            track.managerAddress,
            track.budgetPool,
            track.status,
            track.creationTime,
            track.completionTime,
            track.requiredQLLStakeForProposal,
            track.totalSprints
        );
    }

    function getResearchSprint(uint256 _sprintId)
        external
        view
        returns (
            uint256 sprintId,
            uint256 trackId,
            address researcherAddress,
            string memory title,
            string memory _abstract,
            string memory ipfsHashOfProposal,
            uint256 allocatedBudget,
            Milestone[] memory milestones,
            uint256 currentMilestoneIndex,
            SprintStatus status,
            uint256 creationTime,
            uint256 completionTime,
            uint256 requiredReviewers,
            address[] memory assignedReviewers
        )
    {
        ResearchSprint storage sprint = researchSprints[_sprintId];
        // Create a memory array to return assigned reviewers, as storage arrays cannot be returned directly
        address[] memory currentAssignedReviewers = new address[](sprint.assignedReviewers.length);
        for(uint i=0; i < sprint.assignedReviewers.length; i++){
            currentAssignedReviewers[i] = sprint.assignedReviewers[i];
        }

        return (
            sprint.sprintId,
            sprint.trackId,
            sprint.researcherAddress,
            sprint.title,
            sprint.abstract,
            sprint.ipfsHashOfProposal,
            sprint.allocatedBudget,
            sprint.milestones,
            sprint.currentMilestoneIndex,
            sprint.status,
            sprint.creationTime,
            sprint.completionTime,
            sprint.requiredReviewers,
            currentAssignedReviewers
        );
    }

    function getResearcherProfile(address _userAddress)
        external
        view
        returns (
            uint256 profileId,
            address userAddress,
            string memory name,
            string memory bio,
            string[] memory expertiseTags,
            string memory linkedSocialsIpfsHash,
            uint256 activeSprints,
            uint256 completedSprints
        )
    {
        ResearcherProfile storage profile = researcherProfiles[_userAddress];
        return (
            profile.profileId,
            profile.userAddress,
            profile.name,
            profile.bio,
            profile.expertiseTags,
            profile.linkedSocialsIpfsHash,
            profile.activeSprints,
            profile.completedSprints
        );
    }

    function getReviewDetails(uint256 _reviewId)
        external
        view
        returns (
            uint256 reviewId,
            uint256 sprintId,
            uint256 milestoneIndex,
            address reviewerAddress,
            ReviewStatus reviewStatus,
            string memory feedbackIpfsHash,
            uint256 reviewTime,
            bool rewardClaimed
        )
    {
        Review storage review = reviews[_reviewId];
        return (
            review.reviewId,
            review.sprintId,
            review.milestoneIndex,
            review.reviewerAddress,
            review.reviewStatus,
            review.feedbackIpfsHash,
            review.reviewTime,
            review.rewardClaimed
        );
    }

    function getStakedQLLAmount(address _user) external view returns (uint256) {
        return stakedQLLForVoting[_user];
    }
}
```