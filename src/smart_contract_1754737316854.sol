Here's a Solidity smart contract named "CognitoNet" that implements an advanced, creative, and trendy concept focusing on decentralized AI model refinement and inference, incorporating a reputation system and dynamic NFTs.

---

## CognitoNet - Decentralized AI Model Refinement & Inference Network

### Outline and Function Summary

**I. Core Infrastructure & Configuration**
1.  **`constructor()`**: Initializes the contract, sets the ERC721 name/symbol, and initial admin.
2.  **`setVerifierAddress(address _verifier)`**: Sets the address authorized to act as a task verifier (e.g., an oracle or a governance contract).
3.  **`setRewardTokenAddress(address _rewardToken)`**: Sets the ERC20 token address used for rewards and staking.
4.  **`setBaseNodeStakeAmount(uint256 _amount)`**: Sets the minimum required stake for node operators to register.
5.  **`setVerificationFee(uint256 _fee)`**: Sets the fee paid to verifiers for each successful verification.
6.  **`setCognitionPointThresholds(uint256[] calldata _thresholds, string[] calldata _uris)`**: Configures Cognition Point (CP) thresholds for NFT evolution stages and their corresponding metadata URIs.
7.  **`pauseContract(bool _paused)`**: Pauses/unpauses core contract functionalities (e.g., task creation/submission) in emergencies.

**II. Node Operator Management**
8.  **`registerNodeOperator()`**: Allows a user to become a node operator by staking the `baseNodeStakeAmount`.
9.  **`deregisterNodeOperator()`**: Allows an active operator to initiate deregistration, making them inactive. A cooldown period applies before funds can be fully withdrawn.
10. **`withdrawDeregisteredStake()`**: Allows an operator to withdraw their stake after the deregistration cooldown.
11. **`topUpNodeStake(uint256 _amount)`**: Allows an operator to increase their staked amount.
12. **`withdrawNodeStake(uint256 _amount)`**: Allows an operator to withdraw excess stake, if above the minimum required stake.
13. **`getNodeOperatorProfile(address _operator)`**: Retrieves comprehensive profile details for a specific node operator.

**III. Model & Task Management**
14. **`proposeAIModel(string calldata _modelDescriptionURI, string calldata _inputSchemaURI, string calldata _outputSchemaURI, uint256 _rewardPerTask, uint256 _stakePerTask, uint256 _maxTaskExecutions)`**: Allows a model owner to propose a new AI model/task with its specifications and required resources.
15. **`depositModelReward(uint256 _modelId)`**: Allows a model owner to deposit the total required reward tokens for their proposed model, activating it for task execution.
16. **`getAvailableModels()`**: Retrieves a list of AI models currently active and open for task execution.
17. **`bidForTaskExecution(uint256 _modelId)`**: Allows a node operator to express interest in executing a task for a specific model.
18. **`assignTaskToNode(uint256 _modelId, string calldata _inputURI, address _nodeOperator)`**: (Admin/Off-chain/DAO) Assigns a specific task instance to a selected node operator.
19. **`submitTaskOutput(uint256 _taskId, string calldata _outputURI)`**: Allows an assigned node operator to submit the task output (e.g., IPFS hash of results).
20. **`reportMaliciousOutput(uint256 _taskId)`**: Allows a model owner to report a suspected malicious or incorrect output for their task, initiating a dispute.

**IV. Verification & Reward Distribution**
21. **`verifyTaskOutput(uint256 _taskId, bool _isCorrect)`**: (Verifier Role) Verifies the submitted output. Awards Cognition Points (CP) and distributes rewards for correct output; triggers penalty for incorrect.
22. **`disputeTaskResult(uint256 _taskId)`**: Allows a node operator to dispute an 'incorrect' verification outcome.
23. **`resolveDispute(uint256 _taskId, bool _operatorWins)`**: (Admin/DAO) Resolves a dispute, distributing/slashing funds and adjusting CP based on the outcome.
24. **`claimRewards()`**: Allows a node operator to claim their accumulated rewards.
25. **`penalizeNodeOperator(address _operator, uint256 _slashAmount, uint256 _cpReduction)`**: (Admin/DAO) Explicitly penalizes a node operator for severe misconduct.

**V. Dynamic NFT (BrainNodeNFT) Management**
26. **`mintBrainNodeNFT()`**: Allows a node operator to mint their unique BrainNodeNFT once they meet the initial CP threshold.
27. **`_updateBrainNodeNFTMetadata(uint256 _tokenId, uint256 _currentCP)`**: (Internal) Updates the NFT's metadata URI based on the current Cognition Points, triggering visual evolution.
28. **`getBrainNodeNFTMetadataURI(uint256 _tokenId)`**: Retrieves the current metadata URI for a BrainNodeNFT, reflecting its evolved state.
29. **`transferFrom(address from, address to, uint256 tokenId)`**: Standard ERC721 transfer (inherited but listed for completeness).

**VI. Reputation & Query Functions**
30. **`getCognitionPoints(address _operator)`**: Retrieves the Cognition Points for a specific node operator.
31. **`getTaskStatus(uint256 _taskId)`**: Retrieves the current status and details of a specific task.
32. **`getReputationRanking()`**: (View) Retrieves a simplified sorted list of top node operators by Cognition Points (on-chain ranking is complex, so this is a conceptual placeholder).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Dummy ERC20 Interface for interaction with an external reward token
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/**
 * @title CognitoNet - Decentralized AI Model Refinement & Inference Network
 * @dev This contract creates a decentralized marketplace for AI model training, fine-tuning, and inference.
 *      It incorporates a reputation system (Cognition Points), dynamic NFTs (BrainNodeNFTs) that evolve based on performance,
 *      and a task bidding/assignment mechanism with on-chain verification.
 *      NOTE: For a real-world system, 'verifierAddress' would likely be a robust oracle network (e.g., Chainlink)
 *      or a decentralized governance mechanism, and 'assignTaskToNode' would be part of an off-chain coordinator
 *      or DAO logic. This contract simulates simplified roles for demonstration purposes.
 */
contract CognitoNet is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    /* ====================================================================================================
     * DATA STRUCTURES AND STATE VARIABLES
     * ==================================================================================================== */

    // External dependencies
    IERC20 public rewardToken; // The ERC20 token used for staking and rewards

    // Counters for unique IDs
    Counters.Counter private _modelIdCounter;
    Counters.Counter private _taskIdCounter;
    Counters.Counter private _brainNodeTokenIdCounter;

    // Core Contract Settings
    address public verifierAddress; // Address authorized to verify tasks
    uint256 public baseNodeStakeAmount; // Minimum stake required for node operators
    uint256 public verificationFee; // Fee paid to verifiers per correct verification
    bool public paused; // Global pause switch for emergency

    // Reputation System: Cognition Points (CP)
    mapping(address => uint256) public cognitionPoints; // operator address => CP
    // NFT Evolution: CP thresholds and corresponding metadata URIs
    uint256[] public cpEvolutionThresholds; // Sorted list of CP thresholds for NFT evolution
    string[] public cpEvolutionUris; // Corresponding metadata URIs for each evolution stage

    // Node Operator Profiles
    struct NodeOperator {
        uint256 stakedAmount; // Total tokens staked by this operator
        uint256 lastDeregisterRequest; // Timestamp of last deregister request (for cooldown)
        uint256 activeTasksCount; // Number of tasks currently assigned to this operator
        uint256 pendingRewards; // Rewards accumulated but not yet claimed
        bool isActive; // True if operator has enough stake and is active
        uint256 brainNodeTokenId; // The ID of the operator's BrainNodeNFT (0 if not minted)
    }
    mapping(address => NodeOperator) public nodeOperators; // address => NodeOperator profile

    // Model Definitions
    enum ModelStatus { Proposed, Active, Completed, Disputed, Canceled }
    struct AIModel {
        uint256 id;
        address owner;
        string modelDescriptionURI; // IPFS hash or URL for model description
        string inputSchemaURI;      // IPFS hash for input data schema
        string outputSchemaURI;     // IPFS hash for expected output schema
        uint256 rewardPerTask;      // Reward paid to node for one successful task execution
        uint256 stakePerTask;       // Stake required from node per task instance
        uint256 totalRewardPool;    // Total tokens deposited by owner for all tasks
        uint256 remainingTasks;     // Number of tasks remaining to be executed for this model
        uint256 maxTaskExecutions;  // Max instances for this model
        ModelStatus status;
    }
    mapping(uint256 => AIModel) public aiModels; // modelId => AIModel details

    // Task Instances
    enum TaskStatus { PendingAssignment, Assigned, Submitted, VerifiedCorrect, VerifiedIncorrect, DisputedByOperator, DisputedByModelOwner, Resolved }
    struct TaskInstance {
        uint256 id;
        uint256 modelId;
        address modelOwner;
        address nodeOperator;
        string inputURI;            // IPFS hash or URL for task input data
        string outputURI;           // IPFS hash or URL for submitted output data
        TaskStatus status;
        uint256 assignedAt;         // Timestamp when task was assigned
        uint256 submittedAt;        // Timestamp when output was submitted
        bool isDisputed;            // True if the task is currently under dispute
    }
    mapping(uint256 => TaskInstance) public taskInstances; // taskId => TaskInstance details
    mapping(uint256 => address[]) public modelBids; // modelId => array of addresses that bid on it (simplified bidding)

    // Events
    event VerifierAddressUpdated(address indexed newVerifier);
    event RewardTokenAddressUpdated(address indexed newRewardToken);
    event BaseNodeStakeAmountUpdated(uint256 newAmount);
    event VerificationFeeUpdated(uint256 newFee);
    event NodeOperatorRegistered(address indexed operator, uint256 stakedAmount);
    event NodeOperatorDeregistered(address indexed operator);
    event NodeStakeUpdated(address indexed operator, uint256 newStake);
    event AIModelProposed(uint256 indexed modelId, address indexed owner, uint256 rewardPerTask);
    event ModelRewardDeposited(uint256 indexed modelId, uint256 amount);
    event TaskBid(uint256 indexed modelId, address indexed operator);
    event TaskAssigned(uint256 indexed taskId, uint256 indexed modelId, address indexed nodeOperator);
    event TaskOutputSubmitted(uint256 indexed taskId, address indexed nodeOperator, string outputURI);
    event TaskVerified(uint256 indexed taskId, address indexed verifier, bool isCorrect);
    event TaskDisputed(uint256 indexed taskId, address indexed disputer);
    event DisputeResolved(uint256 indexed taskId, bool operatorWins);
    event RewardsClaimed(address indexed operator, uint256 amount);
    event NodeOperatorPenalized(address indexed operator, uint256 slashAmount, uint256 cpReduction);
    event CognitionPointsUpdated(address indexed operator, uint256 newCP);
    event BrainNodeNFTMinted(address indexed owner, uint256 indexed tokenId);
    event BrainNodeNFTEvolved(uint256 indexed tokenId, string newURI);
    event Paused(bool _paused);

    // Cooldown for deregistration
    uint256 public constant DEREGISTER_COOLDOWN = 7 days; // 7 days cooldown for unstaking

    /* ====================================================================================================
     * MODIFIERS
     * ==================================================================================================== */

    modifier onlyVerifier() {
        require(msg.sender == verifierAddress, "CognitoNet: Only verifier can call this function");
        _;
    }

    modifier onlyActiveNodeOperator() {
        require(nodeOperators[msg.sender].isActive, "CognitoNet: Not an active node operator");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "CognitoNet: Contract is paused");
        _;
    }

    /* ====================================================================================================
     * I. Core Infrastructure & Configuration
     * ==================================================================================================== */

    constructor() ERC721("BrainNodeNFT", "BNN") Ownable(msg.sender) {
        // Initialize with default values
        verifierAddress = address(0); // Must be set by owner
        baseNodeStakeAmount = 1000 * (10 ** 18); // Example: 1000 tokens (assuming 18 decimals)
        verificationFee = 10 * (10 ** 18); // Example: 10 tokens
        paused = false;
        _modelIdCounter.increment(); // Start from 1
        _taskIdCounter.increment();
        _brainNodeTokenIdCounter.increment();
    }

    /**
     * @dev Sets the address authorized to act as a task verifier.
     * @param _verifier The address of the verifier.
     */
    function setVerifierAddress(address _verifier) public onlyOwner {
        require(_verifier != address(0), "CognitoNet: Verifier address cannot be zero");
        verifierAddress = _verifier;
        emit VerifierAddressUpdated(_verifier);
    }

    /**
     * @dev Sets the ERC20 token address used for rewards and staking.
     * @param _rewardToken The address of the ERC20 reward token.
     */
    function setRewardTokenAddress(address _rewardToken) public onlyOwner {
        require(_rewardToken != address(0), "CognitoNet: Reward token address cannot be zero");
        rewardToken = IERC20(_rewardToken);
        emit RewardTokenAddressUpdated(_rewardToken);
    }

    /**
     * @dev Sets the minimum required stake for node operators.
     * @param _amount The new base stake amount.
     */
    function setBaseNodeStakeAmount(uint256 _amount) public onlyOwner {
        require(_amount > 0, "CognitoNet: Base stake must be greater than zero");
        baseNodeStakeAmount = _amount;
        emit BaseNodeStakeAmountUpdated(_amount);
    }

    /**
     * @dev Sets the fee paid to verifiers for each successful verification.
     * @param _fee The new verification fee.
     */
    function setVerificationFee(uint256 _fee) public onlyOwner {
        verificationFee = _fee;
        emit VerificationFeeUpdated(_fee);
    }

    /**
     * @dev Configures thresholds for NFT evolution stages and their corresponding metadata URIs.
     *      _thresholds must be sorted in ascending order.
     *      _uris must have the same length as _thresholds.
     * @param _thresholds Array of Cognition Point thresholds.
     * @param _uris Array of metadata URIs corresponding to the thresholds.
     */
    function setCognitionPointThresholds(uint256[] calldata _thresholds, string[] calldata _uris) public onlyOwner {
        require(_thresholds.length == _uris.length, "CognitoNet: Thresholds and URIs must have same length");
        for (uint i = 0; i < _thresholds.length; i++) {
            if (i > 0) {
                require(_thresholds[i] > _thresholds[i-1], "CognitoNet: Thresholds must be sorted in ascending order");
            }
        }
        cpEvolutionThresholds = _thresholds;
        cpEvolutionUris = _uris;
    }

    /**
     * @dev Pauses/unpauses core contract functionalities (e.g., task creation/submission) in emergencies.
     * @param _paused True to pause, false to unpause.
     */
    function pauseContract(bool _paused) public onlyOwner {
        paused = _paused;
        emit Paused(_paused);
    }

    /* ====================================================================================================
     * II. Node Operator Management
     * ==================================================================================================== */

    /**
     * @dev Allows a user to become a node operator by staking the base amount.
     *      Requires baseNodeStakeAmount to be approved for transfer by rewardToken.
     */
    function registerNodeOperator() public whenNotPaused {
        NodeOperator storage operator = nodeOperators[msg.sender];
        require(!operator.isActive, "CognitoNet: Already an active node operator");
        require(operator.stakedAmount == 0, "CognitoNet: Pending deregistration or partial stake exists. Withdraw first."); // To prevent weird states

        require(rewardToken.transferFrom(msg.sender, address(this), baseNodeStakeAmount), "CognitoNet: Token transfer failed for stake");

        operator.stakedAmount = baseNodeStakeAmount;
        operator.isActive = true;
        operator.lastDeregisterRequest = 0; // Reset any previous request
        emit NodeOperatorRegistered(msg.sender, baseNodeStakeAmount);
    }

    /**
     * @dev Allows an operator to unstake and cease being an active node.
     *      A cooldown period applies before funds can be fully withdrawn.
     */
    function deregisterNodeOperator() public onlyActiveNodeOperator whenNotPaused {
        NodeOperator storage operator = nodeOperators[msg.sender];
        require(operator.activeTasksCount == 0, "CognitoNet: Cannot deregister with active tasks");
        require(operator.lastDeregisterRequest == 0, "CognitoNet: Deregistration already initiated");

        operator.isActive = false; // Mark as inactive immediately
        operator.lastDeregisterRequest = block.timestamp;
        emit NodeOperatorDeregistered(msg.sender);
    }

    /**
     * @dev Allows an operator to withdraw their stake after deregistration cooldown.
     */
    function withdrawDeregisteredStake() public {
        NodeOperator storage operator = nodeOperators[msg.sender];
        require(operator.stakedAmount > 0, "CognitoNet: No stake to withdraw");
        require(!operator.isActive, "CognitoNet: Operator is still active. Initiate deregistration first.");
        require(operator.lastDeregisterRequest > 0, "CognitoNet: Deregistration not initiated");
        require(block.timestamp >= operator.lastDeregisterRequest.add(DEREGISTER_COOLDOWN), "CognitoNet: Deregister cooldown not over");
        require(operator.activeTasksCount == 0, "CognitoNet: Cannot withdraw with active tasks");

        uint256 amountToWithdraw = operator.stakedAmount;
        operator.stakedAmount = 0;
        operator.lastDeregisterRequest = 0; // Reset
        
        require(rewardToken.transfer(msg.sender, amountToWithdraw), "CognitoNet: Stake withdrawal failed");
        emit NodeStakeUpdated(msg.sender, 0);
    }

    /**
     * @dev Allows an operator to increase their staked amount.
     * @param _amount The additional amount to stake.
     */
    function topUpNodeStake(uint256 _amount) public onlyActiveNodeOperator whenNotPaused {
        require(_amount > 0, "CognitoNet: Amount must be greater than zero");
        require(rewardToken.transferFrom(msg.sender, address(this), _amount), "CognitoNet: Token transfer failed for top-up");
        nodeOperators[msg.sender].stakedAmount = nodeOperators[msg.sender].stakedAmount.add(_amount);
        emit NodeStakeUpdated(msg.sender, nodeOperators[msg.sender].stakedAmount);
    }

    /**
     * @dev Allows an operator to withdraw excess stake, if above the minimum.
     * @param _amount The amount to withdraw.
     */
    function withdrawNodeStake(uint256 _amount) public onlyActiveNodeOperator whenNotPaused {
        NodeOperator storage operator = nodeOperators[msg.sender];
        uint256 currentStake = operator.stakedAmount;
        require(_amount > 0, "CognitoNet: Amount must be greater than zero");
        require(currentStake.sub(_amount) >= baseNodeStakeAmount, "CognitoNet: Cannot withdraw below base stake amount");
        require(rewardToken.transfer(msg.sender, _amount), "CognitoNet: Stake withdrawal failed");
        operator.stakedAmount = currentStake.sub(_amount);
        emit NodeStakeUpdated(msg.sender, operator.stakedAmount);
    }

    /**
     * @dev Retrieves comprehensive profile details for a node operator.
     * @param _operator The address of the node operator.
     * @return stakedAmount The total staked tokens.
     * @return lastDeregisterRequest Timestamp of last deregister request.
     * @return activeTasksCount Number of tasks currently assigned.
     * @return pendingRewards Rewards accumulated but not yet claimed.
     * @return isActive True if operator is active.
     * @return brainNodeTokenId The ID of the operator's BrainNodeNFT (0 if not minted).
     * @return cp Cognition Points of the operator.
     */
    function getNodeOperatorProfile(address _operator) public view returns (uint256 stakedAmount, uint256 lastDeregisterRequest, uint256 activeTasksCount, uint256 pendingRewards, bool isActive, uint256 brainNodeTokenId, uint256 cp) {
        NodeOperator storage operator = nodeOperators[_operator];
        return (
            operator.stakedAmount,
            operator.lastDeregisterRequest,
            operator.activeTasksCount,
            operator.pendingRewards,
            operator.isActive,
            operator.brainNodeTokenId,
            cognitionPoints[_operator]
        );
    }

    /* ====================================================================================================
     * III. Model & Task Management
     * ==================================================================================================== */

    /**
     * @dev Allows a model owner to propose a new AI model/task with its specifications and required resources.
     *      The reward for all maxTaskExecutions must be deposited separately via `depositModelReward`.
     * @param _modelDescriptionURI IPFS hash/URL for model description.
     * @param _inputSchemaURI IPFS hash/URL for input data schema.
     * @param _outputSchemaURI IPFS hash/URL for expected output schema.
     * @param _rewardPerTask Reward paid to node for one successful task execution.
     * @param _stakePerTask Stake required from node per task instance.
     * @param _maxTaskExecutions Maximum number of times this model/task can be executed.
     * @return The ID of the newly proposed model.
     */
    function proposeAIModel(
        string calldata _modelDescriptionURI,
        string calldata _inputSchemaURI,
        string calldata _outputSchemaURI,
        uint256 _rewardPerTask,
        uint256 _stakePerTask,
        uint256 _maxTaskExecutions
    ) public whenNotPaused returns (uint256) {
        require(_rewardPerTask > 0, "CognitoNet: Reward per task must be greater than zero");
        require(_stakePerTask > 0, "CognitoNet: Stake per task must be greater than zero");
        require(_maxTaskExecutions > 0, "CognitoNet: Max executions must be greater than zero");

        uint256 newModelId = _modelIdCounter.current();
        _modelIdCounter.increment();

        aiModels[newModelId] = AIModel({
            id: newModelId,
            owner: msg.sender,
            modelDescriptionURI: _modelDescriptionURI,
            inputSchemaURI: _inputSchemaURI,
            outputSchemaURI: _outputSchemaURI,
            rewardPerTask: _rewardPerTask,
            stakePerTask: _stakePerTask,
            totalRewardPool: 0, // Must be deposited separately
            remainingTasks: _maxTaskExecutions,
            maxTaskExecutions: _maxTaskExecutions,
            status: ModelStatus.Proposed
        });

        emit AIModelProposed(newModelId, msg.sender, _rewardPerTask);
        return newModelId;
    }

    /**
     * @dev Allows a model owner to deposit the total required reward tokens for their proposed model.
     *      This activates the model for task execution.
     * @param _modelId The ID of the model to fund.
     */
    function depositModelReward(uint256 _modelId) public whenNotPaused {
        AIModel storage model = aiModels[_modelId];
        require(model.owner == msg.sender, "CognitoNet: Only model owner can deposit rewards");
        require(model.status == ModelStatus.Proposed, "CognitoNet: Model is not in Proposed status");

        uint256 totalRequiredReward = model.rewardPerTask.mul(model.maxTaskExecutions);
        require(totalRequiredReward > 0, "CognitoNet: No reward specified for this model");

        // Allow partial deposits, but ensure full amount is reached to activate
        uint256 amountToDeposit = totalRequiredReward.sub(model.totalRewardPool);
        require(amountToDeposit > 0, "CognitoNet: Model already fully funded");

        require(rewardToken.transferFrom(msg.sender, address(this), amountToDeposit), "CognitoNet: Reward token transfer failed");

        model.totalRewardPool = model.totalRewardPool.add(amountToDeposit);

        if (model.totalRewardPool == totalRequiredReward) {
            model.status = ModelStatus.Active;
        }
        emit ModelRewardDeposited(_modelId, amountToDeposit);
    }

    /**
     * @dev Retrieves a list of AI models currently open for task execution.
     *      (Simplified: returns IDs, detailed info requires separate call)
     */
    function getAvailableModels() public view returns (uint256[] memory) {
        uint256[] memory activeModelIds = new uint256[](_modelIdCounter.current());
        uint256 count = 0;
        for (uint256 i = 1; i < _modelIdCounter.current(); i++) {
            if (aiModels[i].status == ModelStatus.Active && aiModels[i].remainingTasks > 0) {
                activeModelIds[count] = i;
                count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = activeModelIds[i];
        }
        return result;
    }

    /**
     * @dev Allows a node operator to bid on executing a task for a specific model.
     *      Requires staking `stakePerTask` from the operator's total stake.
     * @param _modelId The ID of the model for which to bid.
     */
    function bidForTaskExecution(uint256 _modelId) public onlyActiveNodeOperator whenNotPaused {
        AIModel storage model = aiModels[_modelId];
        require(model.status == ModelStatus.Active, "CognitoNet: Model is not active or has no tasks remaining");
        require(model.remainingTasks > 0, "CognitoNet: No tasks remaining for this model");

        NodeOperator storage operator = nodeOperators[msg.sender];
        require(operator.stakedAmount >= model.stakePerTask, "CognitoNet: Insufficient staked amount for this task");

        // Check if operator already bid (simplified: no duplicate bids for same model)
        for (uint256 i = 0; i < modelBids[_modelId].length; i++) {
            require(modelBids[_modelId][i] != msg.sender, "CognitoNet: Already bid on this model");
        }

        // Add to list of bidders for this model (actual assignment happens off-chain or by admin/DAO)
        modelBids[_modelId].push(msg.sender);
        emit TaskBid(_modelId, msg.sender);
    }

    /**
     * @dev Assigns a specific task instance to a node operator.
     *      This function is typically called by an off-chain coordinator or a DAO after a bidding process.
     * @param _modelId The ID of the model.
     * @param _inputURI The IPFS hash/URL for the specific task input data.
     * @param _nodeOperator The address of the node operator to assign the task to.
     * @return The ID of the newly assigned task.
     */
    function assignTaskToNode(uint256 _modelId, string calldata _inputURI, address _nodeOperator) public onlyOwner whenNotPaused returns (uint256) {
        AIModel storage model = aiModels[_modelId];
        require(model.status == ModelStatus.Active, "CognitoNet: Model is not active");
        require(model.remainingTasks > 0, "CognitoNet: No tasks remaining for this model");
        require(nodeOperators[_nodeOperator].isActive, "CognitoNet: Node operator is not active");
        
        // Check if _nodeOperator has enough stake
        require(nodeOperators[_nodeOperator].stakedAmount >= model.stakePerTask, "CognitoNet: Assigned node has insufficient stake");

        uint256 newTaskId = _taskIdCounter.current();
        _taskIdCounter.increment();

        taskInstances[newTaskId] = TaskInstance({
            id: newTaskId,
            modelId: _modelId,
            modelOwner: model.owner,
            nodeOperator: _nodeOperator,
            inputURI: _inputURI,
            outputURI: "",
            status: TaskStatus.Assigned,
            assignedAt: block.timestamp,
            submittedAt: 0,
            isDisputed: false
        });

        nodeOperators[_nodeOperator].activeTasksCount = nodeOperators[_nodeOperator].activeTasksCount.add(1);
        model.remainingTasks = model.remainingTasks.sub(1); // Decrement remaining tasks

        emit TaskAssigned(newTaskId, _modelId, _nodeOperator);
        return newTaskId;
    }

    /**
     * @dev Allows an assigned node operator to submit the task output (IPFS hash).
     * @param _taskId The ID of the task.
     * @param _outputURI The IPFS hash or URL for the submitted output data.
     */
    function submitTaskOutput(uint256 _taskId, string calldata _outputURI) public whenNotPaused {
        TaskInstance storage task = taskInstances[_taskId];
        require(task.nodeOperator == msg.sender, "CognitoNet: Only assigned operator can submit output");
        require(task.status == TaskStatus.Assigned, "CognitoNet: Task is not in Assigned status");
        require(bytes(_outputURI).length > 0, "CognitoNet: Output URI cannot be empty");

        task.outputURI = _outputURI;
        task.submittedAt = block.timestamp;
        task.status = TaskStatus.Submitted;

        nodeOperators[msg.sender].activeTasksCount = nodeOperators[msg.sender].activeTasksCount.sub(1);
        emit TaskOutputSubmitted(_taskId, msg.sender, _outputURI);
    }

    /**
     * @dev Allows a model owner to report a suspected malicious or incorrect output for their task.
     *      This initiates a dispute process.
     * @param _taskId The ID of the task to report.
     */
    function reportMaliciousOutput(uint256 _taskId) public whenNotPaused {
        TaskInstance storage task = taskInstances[_taskId];
        require(task.modelOwner == msg.sender, "CognitoNet: Only model owner can report for their task");
        require(task.status == TaskStatus.Submitted || task.status == TaskStatus.VerifiedCorrect, "CognitoNet: Task not in a reportable state"); // Can report even if verified correct if new evidence
        require(!task.isDisputed, "CognitoNet: Task already under dispute");

        task.status = TaskStatus.DisputedByModelOwner;
        task.isDisputed = true;
        emit TaskDisputed(_taskId, msg.sender);
    }


    /* ====================================================================================================
     * IV. Verification & Reward Distribution
     * ==================================================================================================== */

    /**
     * @dev (Verifier Role) Verifies the submitted output.
     *      Awards Cognition Points and distributes rewards for correct output; triggers penalty for incorrect.
     *      This function would typically be called by an off-chain oracle (e.g., Chainlink External Adapter)
     *      after performing off-chain validation of the outputURI.
     * @param _taskId The ID of the task to verify.
     * @param _isCorrect True if the output is verified as correct, false otherwise.
     */
    function verifyTaskOutput(uint256 _taskId, bool _isCorrect) public onlyVerifier whenNotPaused {
        TaskInstance storage task = taskInstances[_taskId];
        require(task.status == TaskStatus.Submitted, "CognitoNet: Task is not in Submitted status");
        require(!task.isDisputed, "CognitoNet: Task is currently under dispute");

        AIModel storage model = aiModels[task.modelId];
        NodeOperator storage operator = nodeOperators[task.nodeOperator];

        // Reward verifier first
        require(rewardToken.transfer(verifierAddress, verificationFee), "CognitoNet: Failed to pay verifier fee");
        
        if (_isCorrect) {
            task.status = TaskStatus.VerifiedCorrect;
            // Reward Node Operator
            operator.pendingRewards = operator.pendingRewards.add(model.rewardPerTask);
            // Increase Cognition Points
            cognitionPoints[task.nodeOperator] = cognitionPoints[task.nodeOperator].add(10); // Example: 10 CP per correct task
            _updateBrainNodeNFTMetadata(operator.brainNodeTokenId, cognitionPoints[task.nodeOperator]); // Trigger NFT evolution
            emit CognitionPointsUpdated(task.nodeOperator, cognitionPoints[task.nodeOperator]);

        } else {
            task.status = TaskStatus.VerifiedIncorrect;
            // Penalize Node Operator (slash stake, reduce CP)
            uint256 slashAmount = model.stakePerTask; // Example: Slash the full stake for this task
            uint256 cpReduction = 5; // Example: Reduce 5 CP for incorrect task

            if (operator.stakedAmount >= slashAmount) {
                operator.stakedAmount = operator.stakedAmount.sub(slashAmount);
            } else {
                operator.stakedAmount = 0; // Slash everything if not enough for full slash
            }

            if (cognitionPoints[task.nodeOperator] >= cpReduction) {
                cognitionPoints[task.nodeOperator] = cognitionPoints[task.nodeOperator].sub(cpReduction);
            } else {
                cognitionPoints[task.nodeOperator] = 0;
            }
            _updateBrainNodeNFTMetadata(operator.brainNodeTokenId, cognitionPoints[task.nodeOperator]); // Trigger NFT evolution
            emit NodeOperatorPenalized(task.nodeOperator, slashAmount, cpReduction);
            emit CognitionPointsUpdated(task.nodeOperator, cognitionPoints[task.nodeOperator]);

            // Re-activate model for another execution if an operator failed
            if (model.status == ModelStatus.Completed) {
                 model.status = ModelStatus.Active; // Re-open if was marked completed prematurely
            }
            model.remainingTasks = model.remainingTasks.add(1); // Task slot re-opened
        }
        
        // Simplified check for model completion: if all tasks that were assigned have been processed
        if (model.remainingTasks == 0 && model.status != ModelStatus.Completed) {
             // A more robust system would verify all task instances associated with the model have reached a final state.
             model.status = ModelStatus.Completed;
        }

        emit TaskVerified(_taskId, msg.sender, _isCorrect);
    }

    /**
     * @dev Allows a node operator to dispute an 'incorrect' verification outcome.
     * @param _taskId The ID of the task to dispute.
     */
    function disputeTaskResult(uint256 _taskId) public whenNotPaused {
        TaskInstance storage task = taskInstances[_taskId];
        require(task.nodeOperator == msg.sender, "CognitoNet: Only assigned operator can dispute");
        require(task.status == TaskStatus.VerifiedIncorrect, "CognitoNet: Task not verified incorrect or already disputed");
        require(!task.isDisputed, "CognitoNet: Task already under dispute");

        task.status = TaskStatus.DisputedByOperator;
        task.isDisputed = true;
        emit TaskDisputed(_taskId, msg.sender);
    }

    /**
     * @dev (Admin/DAO) Resolves a dispute, distributing/slashing funds and adjusting CP based on the outcome.
     *      This would typically be called by a governance mechanism or a dispute resolution oracle.
     * @param _taskId The ID of the task under dispute.
     * @param _operatorWins True if the node operator's claim is upheld, false otherwise.
     */
    function resolveDispute(uint256 _taskId, bool _operatorWins) public onlyOwner whenNotPaused { // Simplified to onlyOwner for demo
        TaskInstance storage task = taskInstances[_taskId];
        require(task.isDisputed, "CognitoNet: Task is not under dispute");
        require(task.status == TaskStatus.DisputedByOperator || task.status == TaskStatus.DisputedByModelOwner, "CognitoNet: Task is not in a dispute state");

        AIModel storage model = aiModels[task.modelId];
        NodeOperator storage operator = nodeOperators[task.nodeOperator];

        task.isDisputed = false; // Dispute resolved
        task.status = TaskStatus.Resolved; // Set to resolved state

        if (_operatorWins) {
            // If operator wins, reverse any penalties and award rewards
            // This assumes the initial verification was "VerifiedIncorrect" and caused a penalty
            if (task.status == TaskStatus.DisputedByOperator) { // Only if operator initiated dispute against incorrect verdict
                 // Reverse original penalty (simplified logic):
                 uint256 slashAmount = model.stakePerTask;
                 uint256 cpReduction = 5; // Example: reverse 5 CP reduction

                 operator.stakedAmount = operator.stakedAmount.add(slashAmount); // Return slashed stake
                 cognitionPoints[task.nodeOperator] = cognitionPoints[task.nodeOperator].add(cpReduction); // Return CP
            }
            
            // Give rewards if operator was correct
            operator.pendingRewards = operator.pendingRewards.add(model.rewardPerTask);
            cognitionPoints[task.nodeOperator] = cognitionPoints[task.nodeOperator].add(10); // Award CP for correct task
            _updateBrainNodeNFTMetadata(operator.brainNodeTokenId, cognitionPoints[task.nodeOperator]); // Trigger NFT evolution
            emit CognitionPointsUpdated(task.nodeOperator, cognitionPoints[task.nodeOperator]);

        } else {
            // If operator loses (or model owner wins dispute), confirm/apply penalties
            uint256 slashAmount = model.stakePerTask; // Example: Slash the full stake for this task
            uint256 cpReduction = 15; // Example: Higher penalty for losing a dispute

            if (operator.stakedAmount >= slashAmount) {
                operator.stakedAmount = operator.stakedAmount.sub(slashAmount);
            } else {
                operator.stakedAmount = 0;
            }
            if (cognitionPoints[task.nodeOperator] >= cpReduction) {
                cognitionPoints[task.nodeOperator] = cognitionPoints[task.nodeOperator].sub(cpReduction);
            } else {
                cognitionPoints[task.nodeOperator] = 0;
            }
            _updateBrainNodeNFTMetadata(operator.brainNodeTokenId, cognitionPoints[task.nodeOperator]);
            emit NodeOperatorPenalized(task.nodeOperator, slashAmount, cpReduction);
            emit CognitionPointsUpdated(task.nodeOperator, cognitionPoints[task.nodeOperator]);
        }
        emit DisputeResolved(_taskId, _operatorWins);
    }

    /**
     * @dev Allows a node operator to claim their accumulated rewards.
     */
    function claimRewards() public onlyActiveNodeOperator whenNotPaused {
        NodeOperator storage operator = nodeOperators[msg.sender];
        uint256 amountToClaim = operator.pendingRewards;
        require(amountToClaim > 0, "CognitoNet: No rewards to claim");

        operator.pendingRewards = 0;
        require(rewardToken.transfer(msg.sender, amountToClaim), "CognitoNet: Reward claim failed");
        emit RewardsClaimed(msg.sender, amountToClaim);
    }

    /**
     * @dev (Admin/DAO) Explicitly penalizes a node operator for severe misconduct.
     *      This is an administrative override for critical situations.
     * @param _operator The address of the operator to penalize.
     * @param _slashAmount The amount of stake to slash.
     * @param _cpReduction The amount of Cognition Points to reduce.
     */
    function penalizeNodeOperator(address _operator, uint256 _slashAmount, uint256 _cpReduction) public onlyOwner {
        NodeOperator storage operator = nodeOperators[_operator];
        
        if (operator.stakedAmount >= _slashAmount) {
            operator.stakedAmount = operator.stakedAmount.sub(_slashAmount);
        } else {
            operator.stakedAmount = 0;
        }

        if (cognitionPoints[_operator] >= _cpReduction) {
            cognitionPoints[_operator] = cognitionPoints[_operator].sub(_cpReduction);
        } else {
            cognitionPoints[_operator] = 0;
        }
        _updateBrainNodeNFTMetadata(operator.brainNodeTokenId, cognitionPoints[_operator]); // Trigger NFT evolution
        emit NodeOperatorPenalized(_operator, _slashAmount, _cpReduction);
        emit CognitionPointsUpdated(_operator, cognitionPoints[_operator]);
    }

    /* ====================================================================================================
     * V. Dynamic NFT (BrainNodeNFT) Management
     * ==================================================================================================== */

    /**
     * @dev Allows a node operator to mint their unique BrainNodeNFT once they meet the initial CP threshold.
     *      The initial threshold is cpEvolutionThresholds[0].
     */
    function mintBrainNodeNFT() public onlyActiveNodeOperator whenNotPaused {
        NodeOperator storage operator = nodeOperators[msg.sender];
        require(operator.brainNodeTokenId == 0, "CognitoNet: You already own a BrainNodeNFT");
        require(cpEvolutionThresholds.length > 0, "CognitoNet: NFT evolution thresholds not set");
        require(cognitionPoints[msg.sender] >= cpEvolutionThresholds[0], "CognitoNet: Insufficient Cognition Points to mint NFT");

        uint256 newTokenId = _brainNodeTokenIdCounter.current();
        _brainNodeTokenIdCounter.increment();

        _safeMint(msg.sender, newTokenId);
        operator.brainNodeTokenId = newTokenId;

        _updateBrainNodeNFTMetadata(newTokenId, cognitionPoints[msg.sender]);
        emit BrainNodeNFTMinted(msg.sender, newTokenId);
    }

    /**
     * @dev Internal function to update the NFT's metadata URI based on the current Cognition Points,
     *      triggering visual evolution. Called whenever CP changes.
     * @param _tokenId The ID of the BrainNodeNFT.
     * @param _currentCP The current Cognition Points of the NFT owner.
     */
    function _updateBrainNodeNFTMetadata(uint256 _tokenId, uint256 _currentCP) internal {
        if (_tokenId == 0) { return; } // No NFT minted yet
        
        string memory newURI = "";
        // Find the correct URI based on CP thresholds (iterating backwards to find highest met threshold)
        for (uint i = cpEvolutionThresholds.length; i > 0; i--) {
            if (_currentCP >= cpEvolutionThresholds[i-1]) {
                newURI = cpEvolutionUris[i-1];
                break;
            }
        }
        
        // If no threshold met (CP too low or no thresholds set), default to the base URI if available
        if (bytes(newURI).length == 0 && cpEvolutionUris.length > 0) {
            newURI = cpEvolutionUris[0]; // Fallback to base URI (lowest stage)
        }

        // Only update if the URI has changed
        string memory currentURI = tokenURI(_tokenId);
        if (bytes(newURI).length > 0 && keccak256(abi.encodePacked(currentURI)) != keccak256(abi.encodePacked(newURI))) {
            _setTokenURI(_tokenId, newURI);
            emit BrainNodeNFTEvolved(_tokenId, newURI);
        }
    }

    /**
     * @dev Retrieves the current metadata URI for a BrainNodeNFT, reflecting its evolved state.
     * @param _tokenId The ID of the BrainNodeNFT.
     * @return The metadata URI.
     */
    function getBrainNodeNFTMetadataURI(uint256 _tokenId) public view returns (string memory) {
        return tokenURI(_tokenId);
    }
    
    // Inherited from ERC721. Listing for completeness.
    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) {
        super.transferFrom(from, to, tokenId);
    }

    /* ====================================================================================================
     * VI. Reputation & Query Functions
     * ==================================================================================================== */

    /**
     * @dev Retrieves the Cognition Points for a specific node operator.
     * @param _operator The address of the node operator.
     * @return The Cognition Points.
     */
    function getCognitionPoints(address _operator) public view returns (uint256) {
        return cognitionPoints[_operator];
    }

    /**
     * @dev Retrieves the current status and details of a specific task.
     * @param _taskId The ID of the task.
     * @return The TaskInstance struct details.
     */
    function getTaskStatus(uint256 _taskId) public view returns (TaskInstance memory) {
        return taskInstances[_taskId];
    }

    /**
     * @dev Retrieves a simplified sorted list of top node operators by Cognition Points.
     *      (Note: Iterating over all addresses on-chain for a true ranking is gas-prohibitive.
     *      This is a placeholder; a real implementation would use off-chain indexing or a
     *      more complex on-chain data structure like a sorted list/tree for top N).
     *      For demonstration, this function doesn't actually sort, just returns empty arrays.
     */
    function getReputationRanking() public view returns (address[] memory, uint256[] memory) {
        // In a real application, you'd use a subgraph or off-chain indexer for this.
        // On-chain iteration for ranking is very gas-intensive and scales poorly.
        // This is a placeholder for the concept.
        address[] memory topOperators = new address[](0);
        uint256[] memory topCPs = new uint256[](0);
        return (topOperators, topCPs);
    }
}
```