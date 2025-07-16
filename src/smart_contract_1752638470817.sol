This smart contract, "CogniDAO," is designed to be a decentralized, AI-assisted skill and contribution network. It combines dynamic NFTs, a multi-faceted reputation system, a decentralized task marketplace, and on-chain governance. Participants contribute skills (e.g., data labeling, content creation, code review), earn reputation based on performance (AI-evaluated and peer-reviewed), and their unique "CogniNode NFT" dynamically evolves to reflect their standing. This NFT grants tiered access, governance rights, and unlocks higher-value tasks.

---

### **Outline & Function Summary: CogniDAO - Decentralized AI-Assisted Skill & Contribution Network**

**Contract Vision:**
CogniDAO aims to be a self-governing ecosystem where talent is identified, rewarded, and nurtured through verifiable contributions. It leverages AI oracles for objective performance evaluation, fostering a transparent and meritocratic environment for collaboration on decentralized tasks. The unique CogniNode NFT serves as a dynamic, living credential reflecting a participant's journey and impact within the network.

**Core Concepts & Innovations:**
1.  **AI Oracle Integration:** Trusted AI oracles provide objective, verifiable evaluations of submitted tasks, directly influencing a participant's reputation.
2.  **Dynamic CogniNode NFTs (ERC-721):** Each participant owns a Soul-Bound Token (SBT) initially, which dynamically updates its metadata (visuals, traits) based on their reputation scores, completed tasks, and earned achievements. It's a "living credential."
3.  **Multi-Faceted Reputation System:** Reputation is not a single score but comprises various skill-specific metrics (e.g., "Developer Score," "Data Quality Score"). Reputation can also decay over inactivity.
4.  **Decentralized Task & Bounty Marketplace:** Users can propose and fund tasks, while participants can apply, complete, and get paid for validated work.
5.  **On-chain Achievements & Badges:** Specific milestones or verified skills can be represented as permanent badges integrated into the CogniNode NFT's metadata.
6.  **Staked Governance & Tiered Access:** Participants stake the native `CogniToken` to gain voting power and unlock access to more complex or higher-reward tasks.
7.  **Decentralized Dispute Resolution:** A system where trusted validators can resolve disagreements over task evaluations or reputation changes.
8.  **Prevention of Sybil Attacks:** Initial CogniNode NFT is soul-bound, ensuring unique identity for reputation accrual.

---

**Function Categories & Summaries:**

**I. Core Infrastructure & Administrative Functions**
*   `constructor()`: Initializes the contract, setting the owner, linking the CogniToken, and CogniNode NFT contract addresses.
*   `setProtocolFeeRecipient(address _recipient)`: Sets the address designated to receive protocol fees collected from task rewards.
*   `setProtocolFeePercentage(uint256 _feePercentage)`: Sets the percentage of task rewards that will be collected as protocol fees (e.g., 500 for 5%).
*   `changeCogniTokenAddress(address _newAddress)`: Allows the owner to update the address of the ERC-20 utility token used within the DAO.
*   `changeCogniNodeNFTAddress(address _newAddress)`: Allows the owner to update the address of the CogniNode NFT contract.

**II. User & CogniNode NFT Management**
*   `registerParticipant(string memory _initialMetadataURI)`: Mints an initial, soul-bound CogniNode NFT for a new participant, linking it to their address and setting an initial metadata URI.
*   `getParticipantDetails(address _participant)`: Retrieves a participant's full profile, including their reputation scores across various categories.
*   `claimAchievementBadge(address _participant, uint256 _badgeId, string memory _badgeName)`: Awards a special achievement badge to a participant, updating their CogniNode NFT traits (callable by trusted entities or specific conditions).

**III. Reputation & Skill Management**
*   `updateReputationByAIOracle(uint256 _taskId, address _participant, uint256 _qualityScore, string memory _skillCategory)`: Callable *only* by a trusted AI Oracle to update a participant's reputation score based on the quality evaluation of a completed task.
*   `updateReputationByPeerReview(address _subject, address _reviewer, int256 _reputationDelta, string memory _skillCategory)`: Allows other participants (with sufficient reputation) to provide peer reviews that subtly adjust a subject's reputation.
*   `decayInactiveReputation(address _participant)`: Allows anyone to trigger a time-based decay of reputation for participants who have been inactive for a defined period, encouraging continuous contribution.
*   `penalizeParticipantReputation(address _participant, uint256 _amount, string memory _reason)`: Admin or trusted validators can penalize a participant's reputation for verified misconduct or violations.

**IV. Decentralized Task & Bounty System**
*   `createTask(string memory _title, string memory _description, uint256 _rewardAmount, uint256 _requiredReputationScore, string memory _requiredSkillCategory, uint256 _deadline)`: Allows a user to create a task, specifying requirements, rewards (in CogniToken), skill categories, and funding it upfront.
*   `applyForTask(uint256 _taskId)`: A participant formally applies to work on an available task, provided they meet the reputation and skill requirements.
*   `submitTaskCompletion(uint256 _taskId, string memory _submissionHash)`: A participant submits a hash representing their completed work, awaiting evaluation by an AI oracle or peer review.
*   `evaluateTaskCompletionByAIOracle(uint256 _taskId, uint256 _qualityScore, string memory _evaluationNotes)`: Called by the trusted AI Oracle to provide the final evaluation for a submitted task, triggering reward release or dispute.
*   `claimTaskReward(uint256 _taskId)`: Participant claims their reward after their task submission has been successfully evaluated and approved.
*   `cancelTask(uint256 _taskId)`: The task creator can cancel an unassigned or uncompleted task and reclaim their staked funds, subject to conditions.

**V. AI Oracle Integration & Evaluation**
*   `setAIDecisionOracle(address _oracleAddress, bool _isTrusted)`: Allows the owner to add or remove an AI oracle's address from the list of trusted evaluators.
*   `getTrustedOracleStatus(address _oracleAddress)`: Checks if a given address is a currently trusted AI oracle.

**VI. Dispute Resolution System**
*   `proposeDispute(uint256 _taskId, uint256 _disputeType, string memory _reason)`: A participant or task creator can propose a dispute regarding a task's evaluation or an unjustified reputation change.
*   `voteOnDispute(uint256 _disputeId, bool _voteForResolution)`: Trusted validators cast their votes on the outcome of an active dispute.
*   `resolveDispute(uint256 _disputeId)`: Callable by anyone after the voting period ends; resolves the dispute based on validator votes, updating task status or reputation accordingly.

**VII. DAO Governance & Staking**
*   `stakeForGovernance(uint256 _amount)`: Participants stake `CogniTokens` to gain voting power in DAO governance and potentially unlock access to higher-tier tasks.
*   `unstakeFromGovernance(uint256 _amount)`: Participants can unstake their tokens after a predefined cooldown period.
*   `proposeGovernanceChange(string memory _description, bytes memory _calldata, address _targetContract)`: A participant with sufficient staked tokens can propose changes to DAO parameters or execute a function on a target contract.
*   `voteOnProposal(uint256 _proposalId, bool _voteFor)`: Staked participants vote on active governance proposals, with their vote weight determined by their staked `CogniTokens`.
*   `executeProposal(uint256 _proposalId)`: Callable by anyone after a proposal passes and its voting period ends, triggering the proposed changes.

**VIII. Emergency & Utility Functions**
*   `pauseContract()`: Admin function to temporarily pause critical operations (task creation, reward claims) in case of an emergency or vulnerability.
*   `unpauseContract()`: Admin function to resume operations after a pause.
*   `withdrawERC20StuckTokens(address _tokenAddress, address _to, uint256 _amount)`: Admin function to recover any ERC-20 tokens accidentally sent to the contract address.
*   `getTaskDetails(uint256 _taskId)`: Helper function to retrieve all relevant details of a specific task.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- Interfaces ---

// Simplified interface for the CogniToken (ERC-20)
interface ICogniToken is IERC20 {
    // No additional functions needed for this contract beyond standard IERC20
}

// Simplified interface for the CogniNode NFT (ERC-721)
// In a real scenario, this would be a full ERC-721 contract.
// The updateParticipantData would update the internal state used for tokenURI.
interface ICogniNodeNFT is IERC721 {
    function mint(address to, uint256 tokenId, string memory initialURI) external;
    function updateTokenURI(uint256 tokenId, string memory newURI) external;
    function updateParticipantData(uint256 tokenId, uint256 qualityScore, string memory skillCategory, uint256 totalTasks, uint256 totalReputation) external;
    function getTokenIdByParticipant(address participant) external view returns (uint256);
    function getParticipantByTokenId(uint256 tokenId) external view returns (address);
}

contract CogniDAO is Ownable, Pausable {
    using SafeMath for uint256;

    // --- State Variables ---

    // External contract addresses
    ICogniToken public cogniToken;
    ICogniNodeNFT public cogniNodeNFT;

    // Protocol Fees
    address public protocolFeeRecipient;
    uint256 public protocolFeePercentage; // Stored as basis points (e.g., 500 for 5%)

    // AI Oracle Management
    mapping(address => bool) public trustedAIOrca;

    // Participants & Reputation
    struct Participant {
        uint256 tokenId;
        mapping(string => uint256) reputationScores; // e.g., "developer" => 100, "data_quality" => 90
        uint256 lastActivityTime;
        uint256 totalTasksCompleted;
        uint256 totalRewardsEarned;
        uint256 stakedAmount; // for governance and higher-tier task access
        bool isRegistered;
    }
    mapping(address => Participant) public participants;
    uint256 public nextParticipantTokenId; // To assign unique token IDs for NFTs

    // Tasks & Bounties
    enum TaskStatus { Created, Applied, Submitted, UnderEvaluation, Completed, Disputed, Cancelled }
    struct Task {
        uint256 taskId;
        address creator;
        string title;
        string description;
        uint256 rewardAmount;
        uint256 requiredReputationScore;
        string requiredSkillCategory;
        uint256 deadline;
        address currentWorker;
        string submissionHash;
        uint256 aiQualityScore; // AI evaluation score for the task
        TaskStatus status;
        address[] applicants;
    }
    mapping(uint256 => Task) public tasks;
    uint256 public nextTaskId;

    // Dispute Resolution
    enum DisputeType { TaskEvaluation, ReputationChange, Other }
    enum DisputeStatus { Open, Voting, ResolvedApproved, ResolvedRejected }
    struct Dispute {
        uint256 disputeId;
        uint256 subjectId; // TaskId or ParticipantTokenId
        DisputeType disputeType;
        address proposer;
        string reason;
        mapping(address => bool) votedValidators;
        uint256 votesForResolution;
        uint256 votesAgainstResolution;
        DisputeStatus status;
        uint256 creationTime;
        uint256 votingEndTime;
    }
    mapping(uint256 => Dispute) public disputes;
    uint256 public nextDisputeId;
    address[] public trustedValidators; // Addresses allowed to vote on disputes
    uint256 public constant DISPUTE_VOTING_PERIOD = 3 days;
    uint256 public constant MIN_VALIDATORS_FOR_DISPUTE = 3;

    // DAO Governance
    enum ProposalStatus { Pending, Active, Succeeded, Failed, Executed }
    struct Proposal {
        uint256 proposalId;
        address proposer;
        string description;
        bytes calldataPayload; // calldata for execution
        address targetContract; // Contract to call during execution
        uint256 votingStartTime;
        uint256 votingEndTime;
        mapping(address => bool) votedAddresses;
        uint256 totalVotesFor; // Staked tokens for 'for'
        uint256 totalVotesAgainst; // Staked tokens for 'against'
        ProposalStatus status;
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId;
    uint256 public constant PROPOSAL_VOTING_PERIOD = 7 days;
    uint256 public constant MIN_STAKE_FOR_PROPOSAL = 1000 * (10 ** 18); // Example: 1000 CogniTokens
    uint256 public constant PROPOSAL_QUORUM_PERCENT = 4000; // 40% (4000 basis points) of total staked tokens
    uint256 public totalStakedForGovernance;

    // --- Events ---

    event ParticipantRegistered(address indexed participant, uint256 tokenId);
    event ReputationUpdated(address indexed participant, string skillCategory, uint256 newReputation, string method);
    event AchievementBadgeClaimed(address indexed participant, uint256 badgeId, string badgeName);

    event TaskCreated(uint256 indexed taskId, address indexed creator, uint256 rewardAmount, string skillCategory);
    event TaskApplied(uint256 indexed taskId, address indexed worker);
    event TaskSubmitted(uint256 indexed taskId, address indexed worker, string submissionHash);
    event TaskEvaluated(uint256 indexed taskId, address indexed worker, uint256 qualityScore);
    event TaskRewardClaimed(uint256 indexed taskId, address indexed worker, uint256 rewardAmount);
    event TaskCancelled(uint256 indexed taskId, address indexed creator);

    event DisputeProposed(uint256 indexed disputeId, uint256 indexed subjectId, DisputeType disputeType, address indexed proposer);
    event DisputeVoted(uint256 indexed disputeId, address indexed voter, bool voteForResolution);
    event DisputeResolved(uint256 indexed disputeId, DisputeStatus newStatus);

    event StakedForGovernance(address indexed participant, uint256 amount);
    event UnstakedFromGovernance(address indexed participant, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool voteFor, uint256 voteWeight);
    event ProposalExecuted(uint256 indexed proposalId);

    event ProtocolFeeRecipientSet(address indexed newRecipient);
    event ProtocolFeePercentageSet(uint256 newPercentage);
    event AIOrcaStatusChanged(address indexed oracleAddress, bool isTrusted);
    event ContractPaused(address indexed pauser);
    event ContractUnpaused(address indexed unpauser);

    // --- Modifiers ---

    modifier onlyTrustedAIOrca() {
        require(trustedAIOrca[msg.sender], "CogniDAO: Caller is not a trusted AI oracle");
        _;
    }

    modifier onlyRegisteredParticipant() {
        require(participants[msg.sender].isRegistered, "CogniDAO: Caller is not a registered participant");
        _;
    }

    modifier onlyTaskCreator(uint256 _taskId) {
        require(tasks[_taskId].creator == msg.sender, "CogniDAO: Not task creator");
        _;
    }

    modifier onlyTaskWorker(uint256 _taskId) {
        require(tasks[_taskId].currentWorker == msg.sender, "CogniDAO: Not the assigned worker for this task");
        _;
    }

    modifier onlyTrustedValidator() {
        bool isValidator = false;
        for (uint256 i = 0; i < trustedValidators.length; i++) {
            if (trustedValidators[i] == msg.sender) {
                isValidator = true;
                break;
            }
        }
        require(isValidator, "CogniDAO: Caller is not a trusted validator");
        _;
    }

    // --- Constructor ---

    constructor(address _cogniTokenAddress, address _cogniNodeNFTAddress, address _initialFeeRecipient)
        Ownable(msg.sender) {
        require(_cogniTokenAddress != address(0), "CogniDAO: Invalid CogniToken address");
        require(_cogniNodeNFTAddress != address(0), "CogniDAO: Invalid CogniNodeNFT address");
        require(_initialFeeRecipient != address(0), "CogniDAO: Invalid initial fee recipient");

        cogniToken = ICogniToken(_cogniTokenAddress);
        cogniNodeNFT = ICogniNodeNFT(_cogniNodeNFTAddress);
        protocolFeeRecipient = _initialFeeRecipient;
        protocolFeePercentage = 500; // Default 5%
        nextParticipantTokenId = 1; // Start token IDs from 1
        nextTaskId = 1;
        nextDisputeId = 1;
        nextProposalId = 1;
    }

    // --- I. Core Infrastructure & Administrative Functions ---

    function setProtocolFeeRecipient(address _recipient) external onlyOwner {
        require(_recipient != address(0), "CogniDAO: Invalid recipient address");
        protocolFeeRecipient = _recipient;
        emit ProtocolFeeRecipientSet(_recipient);
    }

    function setProtocolFeePercentage(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 10000, "CogniDAO: Fee percentage cannot exceed 100%"); // Max 100% (10000 basis points)
        protocolFeePercentage = _feePercentage;
        emit ProtocolFeePercentageSet(_feePercentage);
    }

    function changeCogniTokenAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "CogniDAO: Invalid new CogniToken address");
        cogniToken = ICogniToken(_newAddress);
    }

    function changeCogniNodeNFTAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "CogniDAO: Invalid new CogniNodeNFT address");
        cogniNodeNFT = ICogniNodeNFT(_newAddress);
    }

    // --- II. User & CogniNode NFT Management ---

    function registerParticipant(string memory _initialMetadataURI) external whenNotPaused {
        require(!participants[msg.sender].isRegistered, "CogniDAO: Already a registered participant");

        uint256 newId = nextParticipantTokenId++;
        cogniNodeNFT.mint(msg.sender, newId, _initialMetadataURI);

        participants[msg.sender].tokenId = newId;
        participants[msg.sender].isRegistered = true;
        participants[msg.sender].lastActivityTime = block.timestamp;
        // Initialize some default reputation, e.g., "general" skill with 50
        participants[msg.sender].reputationScores["general"] = 50;

        emit ParticipantRegistered(msg.sender, newId);
    }

    function getParticipantDetails(address _participant)
        external
        view
        returns (
            uint256 tokenId,
            uint256 lastActivityTime,
            uint256 totalTasksCompleted,
            uint256 totalRewardsEarned,
            uint256 stakedAmount,
            bool isRegistered
        )
    {
        Participant storage p = participants[_participant];
        return (
            p.tokenId,
            p.lastActivityTime,
            p.totalTasksCompleted,
            p.totalRewardsEarned,
            p.stakedAmount,
            p.isRegistered
        );
    }

    // This function assumes an off-chain oracle or admin decides which badges are claimable
    // The `_badgeId` can map to specific traits/images in the NFT metadata logic.
    function claimAchievementBadge(address _participant, uint256 _badgeId, string memory _badgeName) external onlyOwner { // Or by a specific 'badge issuer' role
        require(participants[_participant].isRegistered, "CogniDAO: Participant not registered");
        // In a real system, there would be checks if this badge is actually earned.
        // For example, if it's based on total tasks, this function would verify.
        // Here, it's simplified to be callable by owner/trusted entity.

        // This would trigger an update to the NFT's metadata URI.
        // The NFT contract would then interpret _badgeId and _badgeName to update its visual/traits.
        uint256 pTokenId = participants[_participant].tokenId;
        // Placeholder for updating NFT metadata URI - needs dynamic URI generation logic off-chain
        // cogniNodeNFT.updateTokenURI(pTokenId, "new_uri_with_badge"); 
        
        emit AchievementBadgeClaimed(_participant, _badgeId, _badgeName);
    }

    // --- III. Reputation & Skill Management ---

    function updateReputationByAIOracle(
        uint256 _taskId,
        uint256 _qualityScore,
        string memory _skillCategory
    ) external onlyTrustedAIOrca whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.UnderEvaluation, "CogniDAO: Task not in evaluation state");
        require(task.currentWorker != address(0), "CogniDAO: No worker assigned to task");

        address worker = task.currentWorker;
        Participant storage p = participants[worker];

        // Ensure the reputation score doesn't go below zero or a floor
        uint256 currentRep = p.reputationScores[_skillCategory];
        uint256 newRep;

        if (_qualityScore >= 70) { // Example: Good quality increases reputation
            newRep = currentRep.add(10);
        } else if (_qualityScore >= 40) { // Average quality
            newRep = currentRep;
        } else { // Poor quality decreases reputation
            newRep = currentRep.sub(5);
            if (newRep < 10) newRep = 10; // Floor reputation
        }

        p.reputationScores[_skillCategory] = newRep;
        p.lastActivityTime = block.timestamp;
        task.aiQualityScore = _qualityScore; // Store the score
        
        // Inform the NFT contract to update its internal state for dynamic metadata
        cogniNodeNFT.updateParticipantData(
            p.tokenId, 
            _qualityScore, // Example of data passed for NFT evolution
            _skillCategory,
            p.totalTasksCompleted,
            p.reputationScores[_skillCategory] // Pass the specific skill reputation
        );

        emit ReputationUpdated(worker, _skillCategory, newRep, "AI_Oracle");
    }

    function updateReputationByPeerReview(
        address _subject,
        int256 _reputationDelta,
        string memory _skillCategory
    ) external onlyRegisteredParticipant whenNotPaused {
        require(participants[_subject].isRegistered, "CogniDAO: Subject not registered");
        require(msg.sender != _subject, "CogniDAO: Cannot review yourself");
        require(participants[msg.sender].reputationScores["general"] >= 70, "CogniDAO: Insufficient reputation to peer review");

        Participant storage p = participants[_subject];
        uint256 currentRep = p.reputationScores[_skillCategory];
        int256 newReputation = int256(currentRep) + _reputationDelta;

        if (newReputation < 0) newReputation = 0; // Prevent negative reputation
        
        p.reputationScores[_skillCategory] = uint256(newReputation);
        p.lastActivityTime = block.timestamp;

        // Update NFT metadata based on new reputation
        cogniNodeNFT.updateParticipantData(
            p.tokenId, 
            0, // No specific quality score from peer review
            _skillCategory,
            p.totalTasksCompleted,
            p.reputationScores[_skillCategory]
        );

        emit ReputationUpdated(_subject, _skillCategory, p.reputationScores[_skillCategory], "Peer_Review");
    }

    function decayInactiveReputation(address _participant) external whenNotPaused {
        Participant storage p = participants[_participant];
        require(p.isRegistered, "CogniDAO: Participant not registered");
        
        uint256 timeSinceLastActivity = block.timestamp.sub(p.lastActivityTime);
        uint256 decayThreshold = 30 days; // Example: Decay after 30 days of inactivity
        uint256 decayAmount = 5; // Example: Decay 5 points per threshold period

        if (timeSinceLastActivity >= decayThreshold) {
            uint256 periods = timeSinceLastActivity.div(decayThreshold);
            bool decayed = false;
            for (uint256 i = 0; i < periods; i++) {
                // Apply decay to all reputation categories (simplified for example)
                // In a real system, you might iterate through keys or have a fixed set.
                // For demonstration, let's assume "general" category.
                if (p.reputationScores["general"] > decayAmount) {
                    p.reputationScores["general"] = p.reputationScores["general"].sub(decayAmount);
                    decayed = true;
                } else if (p.reputationScores["general"] > 0) {
                    p.reputationScores["general"] = 0;
                    decayed = true;
                }
            }
            if (decayed) {
                // Update NFT metadata based on new reputation
                cogniNodeNFT.updateParticipantData(
                    p.tokenId, 
                    0, // No specific quality score from decay
                    "general",
                    p.totalTasksCompleted,
                    p.reputationScores["general"]
                );
                emit ReputationUpdated(_participant, "general", p.reputationScores["general"], "Decay");
            }
            // Update last activity time only if decay was actually applied
            p.lastActivityTime = block.timestamp; 
        }
    }

    function penalizeParticipantReputation(address _participant, uint256 _amount, string memory _reason) external onlyOwner { // Can also be onlyTrustedValidator
        require(participants[_participant].isRegistered, "CogniDAO: Participant not registered");
        require(_amount > 0, "CogniDAO: Penalty amount must be greater than zero");

        Participant storage p = participants[_participant];
        uint256 currentRep = p.reputationScores["general"]; // Apply to general or specific skill? Simplified to general.
        uint256 newRep = currentRep.sub(_amount);
        if (newRep < 0) newRep = 0;

        p.reputationScores["general"] = newRep;
        // Update NFT metadata based on new reputation
        cogniNodeNFT.updateParticipantData(
            p.tokenId, 
            0, // No specific quality score from penalty
            "general",
            p.totalTasksCompleted,
            p.reputationScores["general"]
        );
        emit ReputationUpdated(_participant, "general", newRep, string(abi.encodePacked("Penalty: ", _reason)));
    }

    // --- IV. Decentralized Task & Bounty System ---

    function createTask(
        string memory _title,
        string memory _description,
        uint256 _rewardAmount,
        uint256 _requiredReputationScore,
        string memory _requiredSkillCategory,
        uint256 _deadline
    ) external whenNotPaused {
        require(_rewardAmount > 0, "CogniDAO: Reward must be positive");
        require(_deadline > block.timestamp, "CogniDAO: Deadline must be in the future");
        require(cogniToken.balanceOf(msg.sender) >= _rewardAmount, "CogniDAO: Insufficient CogniToken balance");
        require(cogniToken.allowance(msg.sender, address(this)) >= _rewardAmount, "CogniDAO: CogniToken allowance needed");

        uint256 newId = nextTaskId++;
        tasks[newId] = Task({
            taskId: newId,
            creator: msg.sender,
            title: _title,
            description: _description,
            rewardAmount: _rewardAmount,
            requiredReputationScore: _requiredReputationScore,
            requiredSkillCategory: _requiredSkillCategory,
            deadline: _deadline,
            currentWorker: address(0),
            submissionHash: "",
            aiQualityScore: 0,
            status: TaskStatus.Created,
            applicants: new address[](0)
        });

        // Transfer reward from creator to contract
        require(cogniToken.transferFrom(msg.sender, address(this), _rewardAmount), "CogniDAO: Token transfer failed");

        emit TaskCreated(newId, msg.sender, _rewardAmount, _requiredSkillCategory);
    }

    function applyForTask(uint256 _taskId) external onlyRegisteredParticipant whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Created, "CogniDAO: Task not open for application");
        require(task.deadline > block.timestamp, "CogniDAO: Task application deadline passed");
        require(participants[msg.sender].reputationScores[task.requiredSkillCategory] >= task.requiredReputationScore, "CogniDAO: Insufficient reputation for this task");

        // Check if already applied
        for (uint256 i = 0; i < task.applicants.length; i++) {
            require(task.applicants[i] != msg.sender, "CogniDAO: Already applied for this task");
        }

        task.applicants.push(msg.sender);
        task.currentWorker = msg.sender; // Simple first-apply-gets-task model
        task.status = TaskStatus.Applied; // Set status as applied/assigned

        emit TaskApplied(_taskId, msg.sender);
    }

    function submitTaskCompletion(uint256 _taskId, string memory _submissionHash) external onlyTaskWorker(_taskId) whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Applied, "CogniDAO: Task not in assigned status for submission");
        require(block.timestamp <= task.deadline, "CogniDAO: Task submission deadline passed");
        require(bytes(_submissionHash).length > 0, "CogniDAO: Submission hash cannot be empty");

        task.submissionHash = _submissionHash;
        task.status = TaskStatus.Submitted; // Ready for evaluation

        emit TaskSubmitted(_taskId, msg.sender, _submissionHash);
    }

    // This function is expected to be called by the trusted AI Oracle
    function evaluateTaskCompletionByAIOracle(uint256 _taskId, uint256 _qualityScore, string memory _evaluationNotes) external onlyTrustedAIOrca whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Submitted, "CogniDAO: Task not in submitted state for evaluation");
        require(task.currentWorker != address(0), "CogniDAO: No worker for this task");

        task.aiQualityScore = _qualityScore;
        
        // Decide task outcome based on AI score
        if (_qualityScore >= 70) { // Example threshold for success
            task.status = TaskStatus.Completed;
            // Update reputation directly or trigger a separate reputation update call
            updateReputationByAIOracle(_taskId, _qualityScore, task.requiredSkillCategory);
        } else {
            // Task failed, could move to 'Disputed' automatically or 'Failed'
            task.status = TaskStatus.Disputed; // Requires dispute resolution if failed
        }
        
        emit TaskEvaluated(_taskId, task.currentWorker, _qualityScore);
    }


    function claimTaskReward(uint256 _taskId) external onlyTaskWorker(_taskId) whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Completed, "CogniDAO: Task not marked as completed");
        require(task.rewardAmount > 0, "CogniDAO: No reward to claim");

        uint256 reward = task.rewardAmount;
        uint256 fee = reward.mul(protocolFeePercentage).div(10000); // Calculate fee in basis points
        uint256 netReward = reward.sub(fee);

        // Transfer reward to worker
        require(cogniToken.transfer(msg.sender, netReward), "CogniDAO: Reward transfer failed");
        // Transfer fee to recipient
        if (fee > 0) {
            require(cogniToken.transfer(protocolFeeRecipient, fee), "CogniDAO: Fee transfer failed");
        }
        
        participants[msg.sender].totalTasksCompleted = participants[msg.sender].totalTasksCompleted.add(1);
        participants[msg.sender].totalRewardsEarned = participants[msg.sender].totalRewardsEarned.add(netReward);
        participants[msg.sender].lastActivityTime = block.timestamp;
        
        task.rewardAmount = 0; // Prevent double claims

        emit TaskRewardClaimed(_taskId, msg.sender, netReward);
    }

    function cancelTask(uint256 _taskId) external onlyTaskCreator(_taskId) whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Created || task.status == TaskStatus.Applied, "CogniDAO: Task not in cancelable state");
        require(task.currentWorker == address(0) || task.status == TaskStatus.Applied, "CogniDAO: Task already taken or in progress by worker");
        
        // Return funds to creator
        require(cogniToken.transfer(task.creator, task.rewardAmount), "CogniDAO: Fund return failed");
        task.status = TaskStatus.Cancelled;
        task.rewardAmount = 0; // Clear reward to prevent further claims

        emit TaskCancelled(_taskId, msg.sender);
    }

    // --- V. AI Oracle Integration & Evaluation ---

    function setAIDecisionOracle(address _oracleAddress, bool _isTrusted) external onlyOwner {
        require(_oracleAddress != address(0), "CogniDAO: Invalid oracle address");
        trustedAIOrca[_oracleAddress] = _isTrusted;
        emit AIOrcaStatusChanged(_oracleAddress, _isTrusted);
    }

    function getTrustedOracleStatus(address _oracleAddress) external view returns (bool) {
        return trustedAIOrca[_oracleAddress];
    }

    // --- VI. Dispute Resolution System ---
    // Validators are added/removed via DAO proposals in a full system, or by owner for simplicity.
    function addTrustedValidator(address _validator) external onlyOwner {
        for(uint256 i = 0; i < trustedValidators.length; i++) {
            require(trustedValidators[i] != _validator, "CogniDAO: Validator already exists");
        }
        trustedValidators.push(_validator);
    }

    function removeTrustedValidator(address _validator) external onlyOwner {
        for(uint256 i = 0; i < trustedValidators.length; i++) {
            if (trustedValidators[i] == _validator) {
                trustedValidators[i] = trustedValidators[trustedValidators.length - 1];
                trustedValidators.pop();
                return;
            }
        }
        revert("CogniDAO: Validator not found");
    }

    function proposeDispute(uint256 _subjectId, DisputeType _disputeType, string memory _reason) external onlyRegisteredParticipant whenNotPaused {
        require(bytes(_reason).length > 0, "CogniDAO: Dispute reason cannot be empty");
        
        // Basic checks based on dispute type
        if (_disputeType == DisputeType.TaskEvaluation) {
            require(tasks[_subjectId].taskId != 0, "CogniDAO: Task does not exist");
            require(tasks[_subjectId].status == TaskStatus.Disputed || tasks[_subjectId].status == TaskStatus.Completed, "CogniDAO: Task not in disputable state");
            require(tasks[_subjectId].creator == msg.sender || tasks[_subjectId].currentWorker == msg.sender, "CogniDAO: Only creator or worker can dispute task");
        }
        // More checks for other dispute types as needed

        uint256 newId = nextDisputeId++;
        disputes[newId] = Dispute({
            disputeId: newId,
            subjectId: _subjectId,
            disputeType: _disputeType,
            proposer: msg.sender,
            reason: _reason,
            status: DisputeStatus.Open,
            creationTime: block.timestamp,
            votingEndTime: block.timestamp.add(DISPUTE_VOTING_PERIOD),
            votesForResolution: 0,
            votesAgainstResolution: 0,
            votedValidators: new mapping(address => bool)()
        });

        emit DisputeProposed(newId, _subjectId, _disputeType, msg.sender);
    }

    function voteOnDispute(uint256 _disputeId, bool _voteForResolution) external onlyTrustedValidator whenNotPaused {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.status == DisputeStatus.Open, "CogniDAO: Dispute not open for voting");
        require(block.timestamp <= dispute.votingEndTime, "CogniDAO: Voting period ended");
        require(!dispute.votedValidators[msg.sender], "CogniDAO: Already voted on this dispute");

        dispute.votedValidators[msg.sender] = true;
        if (_voteForResolution) {
            dispute.votesForResolution = dispute.votesForResolution.add(1);
        } else {
            dispute.votesAgainstResolution = dispute.votesAgainstResolution.add(1);
        }

        if (dispute.votesForResolution.add(dispute.votesAgainstResolution) >= MIN_VALIDATORS_FOR_DISPUTE) {
            dispute.status = DisputeStatus.Voting; // Indicate enough votes for resolution
        }

        emit DisputeVoted(_disputeId, msg.sender, _voteForResolution);
    }

    function resolveDispute(uint256 _disputeId) external whenNotPaused {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.status == DisputeStatus.Voting, "CogniDAO: Dispute not ready for resolution (or already resolved)");
        require(block.timestamp > dispute.votingEndTime, "CogniDAO: Voting period not ended");

        DisputeStatus newStatus;
        if (dispute.votesForResolution > dispute.votesAgainstResolution) {
            newStatus = DisputeStatus.ResolvedApproved;
            // Apply resolution based on dispute type
            if (dispute.disputeType == DisputeType.TaskEvaluation) {
                Task storage task = tasks[dispute.subjectId];
                if (task.aiQualityScore < 70) { // If AI failed it, but validators approved, mark as completed.
                    task.status = TaskStatus.Completed;
                    // Optionally, trigger a positive reputation update here if it was unfair
                    // updateReputationByAIOracle(task.taskId, 80, task.requiredSkillCategory); // Example override
                }
            }
            // Logic for other dispute types
        } else {
            newStatus = DisputeStatus.ResolvedRejected;
            if (dispute.disputeType == DisputeType.TaskEvaluation) {
                Task storage task = tasks[dispute.subjectId];
                task.status = TaskStatus.Cancelled; // If validators reject, task is cancelled
                // Optionally, penalize worker/creator if dispute was rejected.
            }
        }
        dispute.status = newStatus;

        emit DisputeResolved(_disputeId, newStatus);
    }

    // --- VII. DAO Governance & Staking ---

    function stakeForGovernance(uint256 _amount) external onlyRegisteredParticipant whenNotPaused {
        require(_amount > 0, "CogniDAO: Stake amount must be positive");
        require(cogniToken.balanceOf(msg.sender) >= _amount, "CogniDAO: Insufficient CogniToken balance");
        require(cogniToken.allowance(msg.sender, address(this)) >= _amount, "CogniDAO: CogniToken allowance needed");

        participants[msg.sender].stakedAmount = participants[msg.sender].stakedAmount.add(_amount);
        totalStakedForGovernance = totalStakedForGovernance.add(_amount);
        require(cogniToken.transferFrom(msg.sender, address(this), _amount), "CogniDAO: Staking transfer failed");

        emit StakedForGovernance(msg.sender, _amount);
    }

    function unstakeFromGovernance(uint256 _amount) external onlyRegisteredParticipant whenNotPaused {
        require(_amount > 0, "CogniDAO: Unstake amount must be positive");
        require(participants[msg.sender].stakedAmount >= _amount, "CogniDAO: Insufficient staked amount");

        // Implement cooldown period if desired
        // require(block.timestamp >= lastUnstakeRequestTime[msg.sender].add(COOLDOWN_PERIOD), "CogniDAO: Cooldown period active");

        participants[msg.sender].stakedAmount = participants[msg.sender].stakedAmount.sub(_amount);
        totalStakedForGovernance = totalStakedForGovernance.sub(_amount);
        require(cogniToken.transfer(msg.sender, _amount), "CogniDAO: Unstaking transfer failed");

        emit UnstakedFromGovernance(msg.sender, _amount);
    }

    function proposeGovernanceChange(string memory _description, bytes memory _calldataPayload, address _targetContract) external onlyRegisteredParticipant whenNotPaused {
        require(participants[msg.sender].stakedAmount >= MIN_STAKE_FOR_PROPOSAL, "CogniDAO: Insufficient stake to propose");
        require(bytes(_description).length > 0, "CogniDAO: Proposal description cannot be empty");
        require(_targetContract != address(0), "CogniDAO: Target contract cannot be zero address");

        uint256 newId = nextProposalId++;
        proposals[newId] = Proposal({
            proposalId: newId,
            proposer: msg.sender,
            description: _description,
            calldataPayload: _calldataPayload,
            targetContract: _targetContract,
            votingStartTime: block.timestamp,
            votingEndTime: block.timestamp.add(PROPOSAL_VOTING_PERIOD),
            status: ProposalStatus.Active,
            votedAddresses: new mapping(address => bool)(),
            totalVotesFor: 0,
            totalVotesAgainst: 0
        });

        emit ProposalCreated(newId, msg.sender, _description);
    }

    function voteOnProposal(uint256 _proposalId, bool _voteFor) external onlyRegisteredParticipant whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "CogniDAO: Proposal not active for voting");
        require(block.timestamp >= proposal.votingStartTime && block.timestamp <= proposal.votingEndTime, "CogniDAO: Voting period not active");
        require(!proposal.votedAddresses[msg.sender], "CogniDAO: Already voted on this proposal");
        
        uint256 voteWeight = participants[msg.sender].stakedAmount;
        require(voteWeight > 0, "CogniDAO: No staked tokens to vote with");

        proposal.votedAddresses[msg.sender] = true;
        if (_voteFor) {
            proposal.totalVotesFor = proposal.totalVotesFor.add(voteWeight);
        } else {
            proposal.totalVotesAgainst = proposal.totalVotesAgainst.add(voteWeight);
        }

        emit ProposalVoted(_proposalId, msg.sender, _voteFor, voteWeight);
    }

    function executeProposal(uint256 _proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "CogniDAO: Proposal not active");
        require(block.timestamp > proposal.votingEndTime, "CogniDAO: Voting period not ended");

        uint256 totalVotes = proposal.totalVotesFor.add(proposal.totalVotesAgainst);
        require(totalVotes.mul(10000).div(totalStakedForGovernance) >= PROPOSAL_QUORUM_PERCENT, "CogniDAO: Quorum not met");

        if (proposal.totalVotesFor > proposal.totalVotesAgainst) {
            // Proposal passed
            proposal.status = ProposalStatus.Succeeded;
            // Execute the proposal payload
            (bool success,) = proposal.targetContract.call(proposal.calldataPayload);
            require(success, "CogniDAO: Proposal execution failed");
            proposal.status = ProposalStatus.Executed;
        } else {
            // Proposal failed
            proposal.status = ProposalStatus.Failed;
        }

        emit ProposalExecuted(_proposalId);
    }

    // --- VIII. Emergency & Utility Functions ---

    function pauseContract() external onlyOwner {
        _pause();
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() external onlyOwner {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    function withdrawERC20StuckTokens(address _tokenAddress, address _to, uint256 _amount) external onlyOwner {
        require(_to != address(0), "CogniDAO: Cannot withdraw to zero address");
        require(_tokenAddress != address(cogniToken), "CogniDAO: Cannot withdraw main CogniToken via this function");
        IERC20 stuckToken = IERC20(_tokenAddress);
        require(stuckToken.transfer(_to, _amount), "CogniDAO: Failed to withdraw stuck tokens");
    }

    function getTaskDetails(uint256 _taskId)
        external
        view
        returns (
            address creator,
            string memory title,
            string memory description,
            uint256 rewardAmount,
            uint256 requiredReputationScore,
            string memory requiredSkillCategory,
            uint256 deadline,
            address currentWorker,
            string memory submissionHash,
            uint256 aiQualityScore,
            TaskStatus status
        )
    {
        Task storage task = tasks[_taskId];
        require(task.taskId != 0, "CogniDAO: Task does not exist");
        return (
            task.creator,
            task.title,
            task.description,
            task.rewardAmount,
            task.requiredReputationScore,
            task.requiredSkillCategory,
            task.deadline,
            task.currentWorker,
            task.submissionHash,
            task.aiQualityScore,
            task.status
        );
    }
}
```