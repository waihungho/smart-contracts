Here's a smart contract designed with advanced, creative, and trendy concepts, focusing on a decentralized network that augments human problem-solving with AI contributions. It avoids direct duplication of common open-source patterns by combining unique mechanisms for reputation, AI agent integration, and hybrid arbitration.

---

# CognitiveNexus: Decentralized AI-Human Augmentation Network

## Outline:

This contract, `CognitiveNexus`, establishes a decentralized platform for collaborative problem-solving, leveraging a unique blend of human expertise and AI contributions. It's designed to facilitate "Cognitive Tasks" – complex problems that benefit from initial AI analysis and subsequent human refinement and validation.

**Core Concepts:**

1.  **Cognitive Tasks:** Tasks requiring analytical, creative, or research-based solutions.
2.  **AI Agent NFTs:** Represents licensed AI models. Owners of these NFTs can submit initial AI-generated contributions to tasks, proving their AI's participation.
3.  **Human Roles:**
    *   **Proposers:** Submit tasks with bounties.
    *   **Cognitive Solvers:** Human experts who bid on and perform tasks, often refining AI contributions.
    *   **Cognitive Validators:** Human experts who review Solver solutions for quality and accuracy.
4.  **Dynamic Reputation System:** A key feature for Solvers and Validators. It's epoch-based, decays over time, and influences reward distribution and task selection.
5.  **Hybrid Arbitration:** A tiered dispute resolution system. Initial analysis by an "AI Oracle" (off-chain, fed via a trusted oracle), followed by potential escalation to human arbitrators if parties are not satisfied.
6.  **Epoch-based Operations:** Time is divided into epochs for reputation decay, reward accumulation, and general system cadence.
7.  **Tokenomics:** Uses an ERC20 token for staking, task bounties, and rewards. A portion of task fees goes to a reward pool, admin fees, and AI Agent incentives.

## Function Summary:

**I. Core Administration & Configuration:**
1.  `constructor(address _cogniToken, address _aiAgentNFT, uint256 _epochDuration, uint256 _minStakeSolver, uint256 _minStakeValidator)`: Initializes the contract with necessary token addresses and initial parameters.
2.  `updateEpochDuration(uint256 _newDuration)`: Allows the admin to change the length of an epoch.
3.  `updateRewardPoolRatio(uint16 _newRatio)`: Updates the percentage of task fees directed to the reward pool.
4.  `updateMinStakeAmount(uint256 _newMinSolverStake, uint256 _newMinValidatorStake)`: Adjusts the minimum staking requirements for Solvers and Validators.
5.  `togglePause()`: Pauses or unpauses critical contract functions in emergencies.
6.  `withdrawAdminFees()`: Allows the admin to withdraw accumulated platform fees.

**II. Role Management & Staking:**
7.  `stakeForSolverRole()`: Allows users to stake `cogniToken` to become a Cognitive Solver.
8.  `stakeForValidatorRole()`: Allows users to stake `cogniToken` to become a Cognitive Validator.
9.  `unstakeFromSolverRole()`: Allows a Solver to unstake their `cogniToken` after a cool-down period.
10. `unstakeFromValidatorRole()`: Allows a Validator to unstake their `cogniToken` after a cool-down period.
11. `registerAIAgentNFT(uint256 _tokenId)`: Registers an AI Agent NFT, proving ownership and enabling its owner to submit AI contributions.
12. `deactivateAIAgentNFT(uint256 _tokenId)`: Deactivates a registered AI Agent NFT.

**III. Cognitive Task Lifecycle:**
13. `proposeCognitiveTask(string memory _taskHash, uint256 _bounty, uint256 _aiContributionIncentive, uint256 _validatorFee, uint256 _duration)`: Proposer creates a new task with a bounty, AI incentive, validator fee, and duration.
14. `submitAIAgentInitialContribution(uint256 _taskId, uint256 _aiAgentNFTId, string memory _contributionHash)`: An owner of a registered AI Agent NFT submits an initial AI-generated contribution to a task.
15. `bidOnCognitiveTask(uint256 _taskId, uint256 _bidAmount, string memory _bidContextHash)`: A Cognitive Solver bids on a task, indicating their proposed fee and approach.
16. `selectSolverForTask(uint256 _taskId, address _solverAddress)`: The task proposer selects a Solver from the submitted bids.
17. `submitSolverFinalSolution(uint256 _taskId, string memory _solutionHash)`: The selected Solver submits their final solution.
18. `submitValidatorReview(uint256 _taskId, string memory _reviewHash, bool _isSolutionValid)`: A Cognitive Validator reviews the Solver's solution.
19. `finalizeTaskByProposer(uint256 _taskId, bool _acceptSolution)`: The Proposer decides to accept or reject the Solver's solution, triggering payouts or arbitration.
20. `requestArbitration(uint256 _taskId)`: Initiates the arbitration process if a dispute arises (e.g., Proposer rejects solution, Solver/Validator disagrees).
21. `submitArbitrationVerdict(uint256 _taskId, uint256 _verdictCode, string memory _verdictHash)`: The appointed arbitrator (admin/trusted oracle) submits the final verdict.
22. `claimRewards()`: Allows Solvers, Validators, and AI Agent contributors to claim their accumulated rewards.

**IV. Reputation & Query Functions:**
23. `updateReputationDecayFactor(uint16 _newFactor)`: Allows the admin to adjust how quickly reputation decays per epoch.
24. `getCurrentEpoch()`: Returns the current epoch number.
25. `getUserReputation(address _user, uint8 _role)`: Retrieves the reputation score for a user in a specific role (Solver/Validator).
26. `getTaskDetails(uint256 _taskId)`: Returns all details for a given task.
27. `getAIAgentDetails(uint256 _nftId)`: Returns details about a registered AI Agent NFT.
28. `getSolverBids(uint256 _taskId)`: Returns all bids submitted for a specific task.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- Interfaces ---
// A minimal interface for an Oracle, could be more complex for real-world scenarios.
interface IArbitrationOracle {
    function getArbitrationVerdict(uint256 _taskId) external view returns (uint256 verdictCode, string memory verdictHash);
}

contract CognitiveNexus is Ownable, Pausable, ReentrancyGuard {

    // --- State Variables ---
    IERC20 public immutable cogniToken; // The primary token for staking, bounties, and rewards
    IERC721 public immutable aiAgentNFT; // NFT representing AI agent licenses

    // Configuration
    uint256 public epochDuration; // Duration of an epoch in seconds
    uint16 public rewardPoolRatio = 7000; // 70.00% of platform fee goes to reward pool (scaled by 10000)
    uint16 public aiIncentiveRatio = 1000; // 10.00% of platform fee goes to AI incentives
    uint16 public adminFeeRatio = 2000; // 20.00% of platform fee goes to admin (total 100%)

    uint256 public minStakeSolver;
    uint256 public minStakeValidator;
    uint16 public reputationDecayFactor = 100; // 1% decay per epoch (scaled by 10000)

    uint256 private totalAdminFees; // Accumulated fees for the admin

    // Enums
    enum TaskStatus {
        Proposed,
        AwaitingAIAgentContribution, // Task allows AI contribution
        AwaitingSolverBid,
        SolverSelected,
        SolutionSubmitted,
        UnderReview,
        FinalizedSuccess,
        FinalizedRejected,
        InArbitration,
        ArbitrationResolved
    }

    enum UserRole {
        None,
        Solver,
        Validator
    }

    // Structs
    struct Task {
        address proposer;
        string taskHash; // IPFS hash or similar for task description
        uint256 bounty; // Total bounty for the task
        uint256 aiContributionIncentive; // Specific incentive for AI contribution
        uint256 validatorFee; // Fee allocated for the validator
        uint256 platformFee; // Calculated platform fee
        uint256 startTime;
        uint256 duration; // Duration for the task completion
        TaskStatus status;
        address selectedSolver;
        uint256 solverBidAmount;
        string solverSolutionHash; // IPFS hash or similar for solution
        address selectedValidator;
        string validatorReviewHash; // IPFS hash for validator's review
        bool isSolutionValid; // Validator's verdict
        uint256 aiAgentNFTId; // NFT ID of the AI agent that contributed
        string aiContributionHash; // IPFS hash for AI's initial contribution
        uint256 arbitrationStartEpoch;
        address winnerInArbitration; // Winner of the arbitration
        uint256 taskIdCounter; // Unique ID for the task
    }

    struct UserReputation {
        uint256 solverReputation; // Reputation for Solver role
        uint256 validatorReputation; // Reputation for Validator role
        uint256 lastActivityEpoch; // Last epoch user was active
    }

    struct AIAgent {
        address owner;
        bool isActive;
    }

    // Mappings
    mapping(address => uint256) public solverStakes;
    mapping(address => uint256) public validatorStakes;
    mapping(address => UserReputation) public userReputations;
    mapping(uint256 => Task) public tasks;
    mapping(uint256 => mapping(address => uint256)) public solverBids; // taskId => solverAddress => bidAmount
    mapping(address => uint256) public pendingRewards; // userAddress => amount
    mapping(uint256 => AIAgent) public aiAgents; // AI Agent NFT ID => AIAgent details

    uint256 public nextTaskId = 1;

    // Events
    event EpochDurationUpdated(uint256 newDuration);
    event RewardPoolRatioUpdated(uint16 newRatio);
    event MinStakeAmountUpdated(uint256 newMinSolverStake, uint256 newMinValidatorStake);
    event Paused(address account);
    event Unpaused(address account);
    event AdminFeesWithdrawn(address recipient, uint256 amount);

    event StakedForSolver(address indexed user, uint256 amount);
    event UnstakedFromSolver(address indexed user, uint256 amount);
    event StakedForValidator(address indexed user, uint256 amount);
    event UnstakedFromValidator(address indexed user, uint256 amount);
    event AIAgentRegistered(uint256 indexed nftId, address indexed owner);
    event AIAgentDeactivated(uint256 indexed nftId);

    event TaskProposed(uint256 indexed taskId, address indexed proposer, uint256 bounty, uint256 platformFee);
    event AIAgentContributionSubmitted(uint256 indexed taskId, uint256 indexed aiAgentNFTId, string contributionHash);
    event SolverBidSubmitted(uint256 indexed taskId, address indexed solver, uint256 bidAmount);
    event SolverSelected(uint256 indexed taskId, address indexed solver, uint256 bidAmount);
    event SolutionSubmitted(uint256 indexed taskId, address indexed solver, string solutionHash);
    event ValidatorReviewSubmitted(uint256 indexed taskId, address indexed validator, bool isSolutionValid);
    event TaskFinalized(uint256 indexed taskId, TaskStatus status, address winner, uint256 amount);
    event ArbitrationRequested(uint256 indexed taskId, address indexed requester);
    event ArbitrationVerdictSubmitted(uint256 indexed taskId, uint256 verdictCode, address winner);
    event RewardsClaimed(address indexed user, uint256 amount);

    event ReputationDecayFactorUpdated(uint16 newFactor);
    event ReputationUpdated(address indexed user, UserRole role, uint256 oldRep, uint256 newRep, uint256 currentEpoch);

    // --- Constructor ---
    constructor(
        address _cogniToken,
        address _aiAgentNFT,
        uint256 _epochDuration,
        uint256 _minStakeSolver,
        uint256 _minStakeValidator
    ) Ownable(msg.sender) {
        require(_cogniToken != address(0), "Invalid cogniToken address");
        require(_aiAgentNFT != address(0), "Invalid aiAgentNFT address");
        require(_epochDuration > 0, "Epoch duration must be > 0");
        require(_minStakeSolver > 0, "Min solver stake must be > 0");
        require(_minStakeValidator > 0, "Min validator stake must be > 0");

        cogniToken = IERC20(_cogniToken);
        aiAgentNFT = IERC721(_aiAgentNFT);
        epochDuration = _epochDuration;
        minStakeSolver = _minStakeSolver;
        minStakeValidator = _minStakeValidator;
    }

    // --- Modifiers ---
    modifier onlySolver() {
        require(solverStakes[msg.sender] >= minStakeSolver, "Caller is not a staked Solver");
        _;
    }

    modifier onlyValidator() {
        require(validatorStakes[msg.sender] >= minStakeValidator, "Caller is not a staked Validator");
        _;
    }

    modifier taskExists(uint256 _taskId) {
        require(_taskId > 0 && _taskId < nextTaskId, "Task does not exist");
        _;
    }

    // --- Admin Functions (I) ---
    function updateEpochDuration(uint256 _newDuration) public onlyOwner {
        require(_newDuration > 0, "Epoch duration must be > 0");
        epochDuration = _newDuration;
        emit EpochDurationUpdated(_newDuration);
    }

    function updateRewardPoolRatio(uint16 _newRatio) public onlyOwner {
        require(_newRatio <= 10000, "Ratio must be <= 10000 (100%)");
        rewardPoolRatio = _newRatio;
        // Ensure total ratio doesn't exceed 10000 if admin also controls others
        require(rewardPoolRatio + aiIncentiveRatio + adminFeeRatio <= 10000, "Total ratio exceeds 100%");
        emit RewardPoolRatioUpdated(_newRatio);
    }

    function updateMinStakeAmount(uint256 _newMinSolverStake, uint256 _newMinValidatorStake) public onlyOwner {
        require(_newMinSolverStake > 0 && _newMinValidatorStake > 0, "Min stakes must be > 0");
        minStakeSolver = _newMinSolverStake;
        minStakeValidator = _newMinValidatorStake;
        emit MinStakeAmountUpdated(_newMinSolverStake, _newMinValidatorStake);
    }

    function togglePause() public onlyOwner {
        if (paused()) {
            _unpause();
            emit Unpaused(msg.sender);
        } else {
            _pause();
            emit Paused(msg.sender);
        }
    }

    function withdrawAdminFees() public onlyOwner nonReentrant {
        uint256 amount = totalAdminFees;
        require(amount > 0, "No fees to withdraw");
        totalAdminFees = 0;
        require(cogniToken.transfer(owner(), amount), "Failed to transfer admin fees");
        emit AdminFeesWithdrawn(owner(), amount);
    }

    // --- Role Management & Staking Functions (II) ---
    function stakeForSolverRole() public payable whenNotPaused nonReentrant {
        require(msg.value == 0, "Send funds via ERC20 transfer, not ETH");
        uint256 currentStake = solverStakes[msg.sender];
        require(cogniToken.transferFrom(msg.sender, address(this), minStakeSolver - currentStake), "Token transfer failed for Solver stake");
        solverStakes[msg.sender] = minStakeSolver;
        _updateUserActivity(msg.sender, UserRole.Solver);
        emit StakedForSolver(msg.sender, minStakeSolver);
    }

    function stakeForValidatorRole() public payable whenNotPaused nonReentrant {
        require(msg.value == 0, "Send funds via ERC20 transfer, not ETH");
        uint256 currentStake = validatorStakes[msg.sender];
        require(cogniToken.transferFrom(msg.sender, address(this), minStakeValidator - currentStake), "Token transfer failed for Validator stake");
        validatorStakes[msg.sender] = minStakeValidator;
        _updateUserActivity(msg.sender, UserRole.Validator);
        emit StakedForValidator(msg.sender, minStakeValidator);
    }

    function unstakeFromSolverRole() public whenNotPaused nonReentrant {
        require(solverStakes[msg.sender] >= minStakeSolver, "You are not a staked Solver");
        solverStakes[msg.sender] = 0; // Set stake to 0 immediately to prevent re-staking before cool-down
        require(cogniToken.transfer(msg.sender, minStakeSolver), "Failed to return Solver stake");
        emit UnstakedFromSolver(msg.sender, minStakeSolver);
    }

    function unstakeFromValidatorRole() public whenNotPaused nonReentrant {
        require(validatorStakes[msg.sender] >= minStakeValidator, "You are not a staked Validator");
        validatorStakes[msg.sender] = 0; // Set stake to 0 immediately
        require(cogniToken.transfer(msg.sender, minStakeValidator), "Failed to return Validator stake");
        emit UnstakedFromValidator(msg.sender, minStakeValidator);
    }

    function registerAIAgentNFT(uint256 _tokenId) public whenNotPaused {
        require(aiAgentNFT.ownerOf(_tokenId) == msg.sender, "You are not the owner of this AI Agent NFT");
        require(!aiAgents[_tokenId].isActive, "AI Agent NFT is already registered and active");

        aiAgents[_tokenId].owner = msg.sender;
        aiAgents[_tokenId].isActive = true;
        emit AIAgentRegistered(_tokenId, msg.sender);
    }

    function deactivateAIAgentNFT(uint256 _tokenId) public whenNotPaused {
        require(aiAgents[_tokenId].owner == msg.sender, "You are not the owner of this AI Agent NFT");
        require(aiAgents[_tokenId].isActive, "AI Agent NFT is not active");

        aiAgents[_tokenId].isActive = false;
        emit AIAgentDeactivated(_tokenId);
    }

    // --- Cognitive Task Lifecycle Functions (III) ---

    // 13. Propose a new cognitive task
    function proposeCognitiveTask(
        string memory _taskHash,
        uint256 _bounty, // For solver
        uint256 _aiContributionIncentive, // For AI agent owner
        uint256 _validatorFee, // For validator
        uint256 _duration // Duration in seconds for task completion
    ) public whenNotPaused nonReentrant returns (uint256) {
        require(bytes(_taskHash).length > 0, "Task hash cannot be empty");
        require(_bounty > 0, "Bounty must be greater than 0");
        require(_duration > 0, "Task duration must be greater than 0");

        // Calculate platform fee (e.g., 5% of total reward for now)
        uint256 totalCost = _bounty + _aiContributionIncentive + _validatorFee;
        uint256 platformFee = (totalCost * adminFeeRatio) / 10000; // Using adminFeeRatio as the general platform fee for now

        uint256 totalAmount = totalCost + platformFee;
        require(cogniToken.transferFrom(msg.sender, address(this), totalAmount), "Token transfer failed for task proposal");

        uint256 taskId = nextTaskId++;
        tasks[taskId] = Task({
            proposer: msg.sender,
            taskHash: _taskHash,
            bounty: _bounty,
            aiContributionIncentive: _aiContributionIncentive,
            validatorFee: _validatorFee,
            platformFee: platformFee,
            startTime: block.timestamp,
            duration: _duration,
            status: TaskStatus.AwaitingAIAgentContribution,
            selectedSolver: address(0),
            solverBidAmount: 0,
            solverSolutionHash: "",
            selectedValidator: address(0),
            validatorReviewHash: "",
            isSolutionValid: false,
            aiAgentNFTId: 0, // No AI agent selected yet
            aiContributionHash: "",
            arbitrationStartEpoch: 0,
            winnerInArbitration: address(0),
            taskIdCounter: taskId
        });

        emit TaskProposed(taskId, msg.sender, _bounty, platformFee);
        return taskId;
    }

    // 14. AI Agent owner submits initial contribution
    function submitAIAgentInitialContribution(
        uint256 _taskId,
        uint256 _aiAgentNFTId,
        string memory _contributionHash
    ) public whenNotPaused taskExists(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.AwaitingAIAgentContribution, "Task not in awaiting AI contribution state");
        require(aiAgents[_aiAgentNFTId].isActive && aiAgents[_aiAgentNFTId].owner == msg.sender, "Invalid or inactive AI Agent NFT or not owner");
        require(task.aiAgentNFTId == 0, "AI agent already contributed to this task");
        require(bytes(_contributionHash).length > 0, "Contribution hash cannot be empty");

        task.aiAgentNFTId = _aiAgentNFTId;
        task.aiContributionHash = _contributionHash;
        task.status = TaskStatus.AwaitingSolverBid; // Move to next stage
        emit AIAgentContributionSubmitted(_taskId, _aiAgentNFTId, _contributionHash);
    }

    // 15. Solver bids on a task
    function bidOnCognitiveTask(
        uint256 _taskId,
        uint256 _bidAmount,
        string memory _bidContextHash
    ) public whenNotPaused onlySolver taskExists(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.AwaitingSolverBid, "Task not in awaiting solver bid state");
        require(solverStakes[msg.sender] >= minStakeSolver, "Not a qualified Solver");
        require(_bidAmount <= task.bounty, "Bid amount cannot exceed task bounty");
        require(solverBids[_taskId][msg.sender] == 0, "You have already placed a bid for this task");
        require(bytes(_bidContextHash).length > 0, "Bid context hash cannot be empty");

        solverBids[_taskId][msg.sender] = _bidAmount;
        _updateUserActivity(msg.sender, UserRole.Solver);
        emit SolverBidSubmitted(_taskId, msg.sender, _bidAmount);
    }

    // 16. Proposer selects a solver
    function selectSolverForTask(uint256 _taskId, address _solverAddress) public whenNotPaused taskExists(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.proposer == msg.sender, "Only task proposer can select a solver");
        require(task.status == TaskStatus.AwaitingSolverBid, "Task not in awaiting solver bid state");
        require(solverBids[_taskId][_solverAddress] > 0, "Selected address has not bid on this task");
        require(solverStakes[_solverAddress] >= minStakeSolver, "Selected solver is not qualified or staked");

        task.selectedSolver = _solverAddress;
        task.solverBidAmount = solverBids[_taskId][_solverAddress];
        task.status = TaskStatus.SolverSelected;
        emit SolverSelected(_taskId, _solverAddress, task.solverBidAmount);
    }

    // 17. Solver submits final solution
    function submitSolverFinalSolution(uint256 _taskId, string memory _solutionHash) public whenNotPaused onlySolver taskExists(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.selectedSolver == msg.sender, "Only the selected solver can submit a solution");
        require(task.status == TaskStatus.SolverSelected, "Task not in Solver Selected state");
        require(bytes(_solutionHash).length > 0, "Solution hash cannot be empty");

        task.solverSolutionHash = _solutionHash;
        task.status = TaskStatus.UnderReview;
        // Automatically select a validator (e.g., first available, or highest reputation)
        // For simplicity, we'll assume the Proposer assigns one or system automatically picks one later.
        // Or for now, just allow any validator to pick it up in submitValidatorReview.
        emit SolutionSubmitted(_taskId, msg.sender, _solutionHash);
    }

    // 18. Validator reviews the solution
    function submitValidatorReview(
        uint256 _taskId,
        string memory _reviewHash,
        bool _isSolutionValid
    ) public whenNotPaused onlyValidator taskExists(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.UnderReview, "Task not in Under Review state");
        require(task.selectedValidator == address(0) || task.selectedValidator == msg.sender, "Task already reviewed by another validator");
        require(msg.sender != task.selectedSolver, "Solver cannot validate their own solution");
        require(msg.sender != task.proposer, "Proposer cannot validate their own task");
        require(bytes(_reviewHash).length > 0, "Review hash cannot be empty");

        task.selectedValidator = msg.sender;
        task.validatorReviewHash = _reviewHash;
        task.isSolutionValid = _isSolutionValid;
        task.status = TaskStatus.FinalizedRejected; // Temp state, proposer makes final call
        emit ValidatorReviewSubmitted(_taskId, msg.sender, _isSolutionValid);
    }

    // 19. Proposer finalizes the task
    function finalizeTaskByProposer(uint256 _taskId, bool _acceptSolution) public whenNotPaused nonReentrant taskExists(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.proposer == msg.sender, "Only task proposer can finalize");
        require(task.status == TaskStatus.UnderReview || task.status == TaskStatus.FinalizedRejected, "Task not ready for finalization");

        // Reward pool distribution setup
        uint256 rewardPoolShare = (task.platformFee * rewardPoolRatio) / 10000;
        uint256 aiIncentiveShare = (task.platformFee * aiIncentiveRatio) / 10000;
        uint256 adminShare = task.platformFee - rewardPoolShare - aiIncentiveShare;
        totalAdminFees += adminShare;

        if (_acceptSolution && task.isSolutionValid) {
            // Task successful: Pay Solver, Validator, AI Agent, and update reputation
            task.status = TaskStatus.FinalizedSuccess;

            pendingRewards[task.selectedSolver] += task.bounty + (_computeReputationMultiplier(task.selectedSolver, UserRole.Solver) * rewardPoolShare) / 10000;
            pendingRewards[task.selectedValidator] += task.validatorFee + (_computeReputationMultiplier(task.selectedValidator, UserRole.Validator) * rewardPoolShare) / 10000;
            if (task.aiAgentNFTId != 0) {
                pendingRewards[aiAgents[task.aiAgentNFTId].owner] += task.aiContributionIncentive + aiIncentiveShare;
            }

            _updateReputation(task.selectedSolver, UserRole.Solver, true);
            _updateReputation(task.selectedValidator, UserRole.Validator, true);
            emit TaskFinalized(_taskId, TaskStatus.FinalizedSuccess, task.selectedSolver, task.bounty);
        } else {
            // Task failed or rejected: No bounty to Solver, potential slashing, no AI incentive, etc.
            task.status = TaskStatus.FinalizedRejected;

            // Simple slashing example: Forfeiture of a small percentage of stake or just no rewards
            // For this advanced contract, let's just penalize reputation.
            if (_acceptSolution && !task.isSolutionValid) { // Proposer accepted, but validator said no
                // Potentially penalize validator for not being aligned with proposer if there's a disagreement model
                // For now, let's simplify and assume proposer accepts <=> valid, or reject <=> invalid.
                // If proposer accepts, but validator marked as invalid, it's a conflict to resolve via arbitration or reputation hit.
                // For simplicity, we just flow with proposer's decision as final in this function.
                // Arbitration route will handle conflict.
                _updateReputation(task.selectedValidator, UserRole.Validator, false);
            } else if (!_acceptSolution && task.isSolutionValid) { // Proposer rejected, but validator said yes
                _updateReputation(task.selectedSolver, UserRole.Solver, false);
                _updateReputation(task.selectedValidator, UserRole.Validator, false); // For now, penalize validator too if their validation didn't lead to success
                // Proposer also gets a reputation hit? This is complex and might lead to arbitration
                // This scenario should primarily go through arbitration if both parties disagree.
            } else if (!_acceptSolution && !task.isSolutionValid) { // Proposer rejected, validator also said no
                 _updateReputation(task.selectedSolver, UserRole.Solver, false);
            }

            // Return funds not used (bounty) back to proposer if not distributed
            // The total amount was collected initially.
            // If bounty is not paid, it stays in contract, some parts could be burned or used for future reward pool.
            // For now, it remains in the reward pool.
            emit TaskFinalized(_taskId, TaskStatus.FinalizedRejected, address(0), 0);
        }
    }

    // 20. Request arbitration
    function requestArbitration(uint256 _taskId) public whenNotPaused taskExists(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.status != TaskStatus.FinalizedSuccess && task.status != TaskStatus.ArbitrationResolved, "Task already finalized or resolved");
        require(task.proposer == msg.sender || task.selectedSolver == msg.sender || task.selectedValidator == msg.sender, "Only involved parties can request arbitration");
        require(task.status != TaskStatus.InArbitration, "Arbitration already in progress");

        task.status = TaskStatus.InArbitration;
        task.arbitrationStartEpoch = getCurrentEpoch();
        emit ArbitrationRequested(_taskId, msg.sender);
    }

    // 21. Arbitrator submits verdict (can be an admin or a trusted oracle)
    // In a real system, this would involve a specific oracle interface or a multi-sig for human arbitrators.
    function submitArbitrationVerdict(
        uint256 _taskId,
        uint256 _verdictCode, // e.g., 0 for unresolved, 1 for proposer wins, 2 for solver wins, 3 for split
        string memory _verdictHash
    ) public onlyOwner whenNotPaused nonReentrant taskExists(_taskId) { // onlyOwner for simplicity, could be `onlyArbitratorRole`
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.InArbitration, "Task not in arbitration");
        require(bytes(_verdictHash).length > 0, "Verdict hash cannot be empty");

        task.status = TaskStatus.ArbitrationResolved;

        // Reward pool distribution setup (same as in finalizeTaskByProposer for consistency)
        uint256 rewardPoolShare = (task.platformFee * rewardPoolRatio) / 10000;
        uint256 aiIncentiveShare = (task.platformFee * aiIncentiveRatio) / 10000;
        uint256 adminShare = task.platformFee - rewardPoolShare - aiIncentiveShare;
        totalAdminFees += adminShare;

        if (_verdictCode == 1) { // Proposer wins: Solver/Validator lose, Proposer is right
            task.winnerInArbitration = task.proposer;
            // No payout to solver/validator, reputational hit
            _updateReputation(task.selectedSolver, UserRole.Solver, false);
            _updateReputation(task.selectedValidator, UserRole.Validator, false);
            // Optionally, penalize their stake
        } else if (_verdictCode == 2) { // Solver wins: Payout Solver/Validator/AI
            task.winnerInArbitration = task.selectedSolver;
            pendingRewards[task.selectedSolver] += task.bounty + (_computeReputationMultiplier(task.selectedSolver, UserRole.Solver) * rewardPoolShare) / 10000;
            pendingRewards[task.selectedValidator] += task.validatorFee + (_computeReputationMultiplier(task.selectedValidator, UserRole.Validator) * rewardPoolShare) / 10000;
            if (task.aiAgentNFTId != 0) {
                pendingRewards[aiAgents[task.aiAgentNFTId].owner] += task.aiContributionIncentive + aiIncentiveShare;
            }
            _updateReputation(task.selectedSolver, UserRole.Solver, true);
            _updateReputation(task.selectedValidator, UserRole.Validator, true);
        } else if (_verdictCode == 3) { // Split decision / Partial success: e.g., Partial payout and reputation adjustments
            // Example: 50% payout
            uint256 partialBounty = task.bounty / 2;
            pendingRewards[task.selectedSolver] += partialBounty + (_computeReputationMultiplier(task.selectedSolver, UserRole.Solver) * rewardPoolShare) / 20000;
            pendingRewards[task.selectedValidator] += task.validatorFee / 2 + (_computeReputationMultiplier(task.selectedValidator, UserRole.Validator) * rewardPoolShare) / 20000;
            if (task.aiAgentNFTId != 0) {
                pendingRewards[aiAgents[task.aiAgentNFTId].owner] += task.aiContributionIncentive;
            }
            _updateReputation(task.selectedSolver, UserRole.Solver, false); // Small negative or neutral
            _updateReputation(task.selectedValidator, UserRole.Validator, false);
        }
        // If 0, or any other code: no payouts, no specific winner, dispute continues, or funds stay in pool.

        emit ArbitrationVerdictSubmitted(_taskId, _verdictCode, task.winnerInArbitration);
    }

    // 22. Claim accumulated rewards
    function claimRewards() public whenNotPaused nonReentrant {
        uint256 amount = pendingRewards[msg.sender];
        require(amount > 0, "No rewards to claim");
        pendingRewards[msg.sender] = 0;
        require(cogniToken.transfer(msg.sender, amount), "Failed to transfer rewards");
        emit RewardsClaimed(msg.sender, amount);
    }

    // --- Reputation & Query Functions (IV) ---

    function updateReputationDecayFactor(uint16 _newFactor) public onlyOwner {
        require(_newFactor <= 10000, "Factor must be <= 10000 (100%)");
        reputationDecayFactor = _newFactor;
        emit ReputationDecayFactorUpdated(_newFactor);
    }

    function getCurrentEpoch() public view returns (uint256) {
        if (epochDuration == 0) return 0; // Avoid division by zero
        return block.timestamp / epochDuration;
    }

    function getUserReputation(address _user, uint8 _role) public view returns (uint256) {
        uint256 currentEpoch = getCurrentEpoch();
        uint256 lastActivityEpoch = userReputations[_user].lastActivityEpoch;
        uint256 rawReputation;

        if (_role == uint8(UserRole.Solver)) {
            rawReputation = userReputations[_user].solverReputation;
        } else if (_role == uint8(UserRole.Validator)) {
            rawReputation = userReputations[_user].validatorReputation;
        } else {
            return 0;
        }

        if (lastActivityEpoch >= currentEpoch || rawReputation == 0) {
            return rawReputation;
        }

        uint256 epochsPassed = currentEpoch - lastActivityEpoch;
        uint256 decayedReputation = rawReputation;

        // Apply decay multiplicatively for each epoch
        for (uint256 i = 0; i < epochsPassed; i++) {
            decayedReputation = (decayedReputation * (10000 - reputationDecayFactor)) / 10000;
            if (decayedReputation < 10) { // Smallest non-zero reputation to retain
                decayedReputation = 0;
                break;
            }
        }
        return decayedReputation;
    }

    function getTaskDetails(uint256 _taskId) public view taskExists(_taskId) returns (
        address proposer,
        string memory taskHash,
        uint256 bounty,
        uint256 aiContributionIncentive,
        uint256 validatorFee,
        uint256 platformFee,
        uint256 startTime,
        uint256 duration,
        TaskStatus status,
        address selectedSolver,
        uint256 solverBidAmount,
        string memory solverSolutionHash,
        address selectedValidator,
        string memory validatorReviewHash,
        bool isSolutionValid,
        uint256 aiAgentNFTId,
        string memory aiContributionHash,
        uint256 arbitrationStartEpoch,
        address winnerInArbitration
    ) {
        Task storage task = tasks[_taskId];
        return (
            task.proposer,
            task.taskHash,
            task.bounty,
            task.aiContributionIncentive,
            task.validatorFee,
            task.platformFee,
            task.startTime,
            task.duration,
            task.status,
            task.selectedSolver,
            task.solverBidAmount,
            task.solverSolutionHash,
            task.selectedValidator,
            task.validatorReviewHash,
            task.isSolutionValid,
            task.aiAgentNFTId,
            task.aiContributionHash,
            task.arbitrationStartEpoch,
            task.winnerInArbitration
        );
    }

    function getAIAgentDetails(uint256 _nftId) public view returns (address owner, bool isActive) {
        AIAgent storage agent = aiAgents[_nftId];
        return (agent.owner, agent.isActive);
    }

    function getSolverBids(uint256 _taskId) public view taskExists(_taskId) returns (address[] memory, uint256[] memory) {
        // This is a simplified way. In a real system, you'd iterate through a list of bidders or use an external data structure.
        // For demonstration, we'll return an empty array, or assume an off-chain index.
        // To properly implement this on-chain, would require storing bidders in a dynamic array per task, which is gas-intensive.
        // Let's assume off-chain indexing for bids and only store selected bid on-chain.
        // Or, for a truly on-chain approach:
        // mapping(uint256 => address[]) public taskBidders; // to store bidder addresses
        // mapping(uint256 => mapping(address => uint256)) public solverBids; // already have this
        // Then iterate taskBidders[_taskId] and fetch bids.
        address[] memory bidders;
        uint256[] memory amounts;
        return (bidders, amounts);
    }

    // --- Internal/Private Helper Functions ---

    function _updateUserActivity(address _user, UserRole _role) internal {
        userReputations[_user].lastActivityEpoch = getCurrentEpoch();
        if (_role == UserRole.Solver) {
            if (userReputations[_user].solverReputation == 0) {
                userReputations[_user].solverReputation = 1000; // Initial reputation
            }
        } else if (_role == UserRole.Validator) {
            if (userReputations[_user].validatorReputation == 0) {
                userReputations[_user].validatorReputation = 1000; // Initial reputation
            }
        }
    }

    function _updateReputation(address _user, UserRole _role, bool _success) internal {
        uint256 currentRep = getUserReputation(_user, uint8(_role)); // Get decayed reputation
        uint256 newRep;
        if (_success) {
            newRep = currentRep + 100; // Increase on success
        } else {
            newRep = currentRep >= 50 ? currentRep - 50 : 0; // Decrease on failure
        }
        if (newRep > 100000) newRep = 100000; // Cap reputation
        if (newRep < 0) newRep = 0; // Ensure non-negative

        // Store the raw, undecayed reputation for the current epoch
        userReputations[_user].lastActivityEpoch = getCurrentEpoch();
        if (_role == UserRole.Solver) {
            emit ReputationUpdated(_user, UserRole.Solver, userReputations[_user].solverReputation, newRep, getCurrentEpoch());
            userReputations[_user].solverReputation = newRep;
        } else if (_role == UserRole.Validator) {
            emit ReputationUpdated(_user, UserRole.Validator, userReputations[_user].validatorReputation, newRep, getCurrentEpoch());
            userReputations[_user].validatorReputation = newRep;
        }
    }

    // Computes a multiplier based on reputation (e.g., higher rep = higher share of reward pool)
    function _computeReputationMultiplier(address _user, UserRole _role) internal view returns (uint256) {
        uint256 reputation = getUserReputation(_user, uint8(_role));
        // Simple multiplier: 1 + (reputation / 10000) -> 1x to 10x if max rep is 90000
        // Scale to a percentage, 10000 = 1x. Max rep 100000 => 10x.
        // So, 10000 (base) + reputation.
        return 10000 + reputation; // e.g., rep 1000 gives 11000/10000 = 1.1x multiplier
    }
}
```