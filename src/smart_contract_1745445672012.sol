Okay, here is a Solidity smart contract for a Decentralized AI Model Marketplace with a focus on staking for validation, dynamic pricing concepts, and detailed model metadata management.

This contract allows users to register AI models, define usage prices, receive payments, and allows other users to stake tokens (ETH in this example) to validate the models. Stakers can earn rewards and participate in challenging models. It incorporates several functions related to managing models, payments, staking, challenges, and reputation/ratings.

**Outline and Function Summary**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Outline ---
// 1. Contract Setup: Owner, Fee Management, Pausing.
// 2. Data Structures: Model details, Stake information, Ratings.
// 3. State Variables: Mappings to store Models, Stakes, Payments, Ratings, Challenge data. Counters.
// 4. Events: Notifications for key actions (Registration, Updates, Stakes, Payments, Challenges, etc.).
// 5. Modifiers: Access control and state checks (e.g., only owner, model owner, active model).
// 6. Core Functionality:
//    - Model Registration & Management: Registering, updating, activating, deactivating, retiring models.
//    - Usage Payments: Users paying for model access/usage credits.
//    - Earnings & Withdrawals: Model owners and protocol withdrawing funds.
//    - Staking for Validation: Users staking ETH to validate models.
//    - Unstaking: Users withdrawing staked ETH after cooldown.
//    - Model Challenges: Stakers or users challenging model claims (e.g., accuracy, availability).
//    - Challenge Resolution: Owner resolves challenges, distributing stakes.
//    - Validation Rewards: Distributing a portion of model earnings to stakers.
//    - Model Rating & Reputation: Users rating models, tracking average ratings.
// 7. Query Functions: Reading state data (model details, stakes, ratings, lists).

// --- Function Summary ---

// Setup & Management:
// 1. constructor(uint256 _protocolFeePercentage): Initializes contract owner and fee percentage.
// 2. pauseContract(): Owner function to pause contract operations.
// 3. unpauseContract(): Owner function to unpause contract operations.
// 4. updateFeePercentage(uint256 _newPercentage): Owner function to update the protocol fee percentage.
// 5. updateStakeCooldown(uint256 _newCooldown): Owner function to update unstaking cooldown period.
// 6. updateChallengeStakeRequirement(uint256 _newRequirement): Owner function to update stake needed to challenge.

// Model Registration & Management:
// 7. registerModel(string calldata _metadataHash, uint256 _pricePerUse, uint256 _stakeRequirement, string calldata _description): Registers a new AI model.
// 8. updateModelMetadata(uint256 _modelId, string calldata _newMetadataHash, string calldata _newDescription): Model owner updates metadata/description.
// 9. updateModelPrice(uint256 _modelId, uint256 _newPrice): Model owner updates usage price.
// 10. deactivateModel(uint256 _modelId): Model owner temporarily deactivates a model.
// 11. activateModel(uint256 _modelId): Model owner reactivates a model.
// 12. retireModel(uint256 _modelId): Model owner permanently retires a model (prevents new usage/stakes).

// Usage Payments:
// 13. payForModelUsage(uint256 _modelId) payable: User pays ETH for usage credits on a model.
// (Note: Off-chain system would verify payment amount vs. pricePerUse to determine usage credits).

// Earnings & Withdrawals:
// 14. withdrawModelEarnings(uint256 _modelId): Model owner withdraws accumulated earnings (minus fees).
// 15. withdrawProtocolFees(): Owner withdraws total accumulated protocol fees.
// 16. claimValidationRewards(uint256 _modelId): Staker claims their share of accumulated validation rewards for a model.

// Staking & Validation:
// 17. stakeForModelValidation(uint256 _modelId) payable: User stakes ETH to validate a model. Requires minimum stake.
// 18. unstakeFromModelValidation(uint256 _modelId): Staker initiates unstaking, starts cooldown.
// 19. finalizeUnstake(uint256 _modelId): Staker completes unstaking after cooldown.

// Model Challenges:
// 20. challengeModelAccuracy(uint256 _modelId) payable: User/Staker challenges a model. Requires challenge stake.
// 21. resolveChallenge(uint256 _modelId, bool _challengerWon): Owner resolves a challenge. Distributes stakes based on outcome.

// Rating & Reputation:
// 22. rateModel(uint256 _modelId, uint8 _rating): User rates a model (e.g., 1-5).

// Query Functions (Read-only):
// 23. getModelDetails(uint256 _modelId) view: Get all details for a specific model.
// 24. listActiveModels() view: Get a list of IDs for active models.
// 25. listModelsByOwner(address _owner) view: Get a list of IDs for models owned by an address.
// 26. listModelsUnderChallenge() view: Get a list of IDs for models currently challenged.
// 27. getStakedValidators(uint256 _modelId) view: Get list of addresses staking on a model.
// 28. getValidatorStake(uint256 _modelId, address _staker) view: Get stake details for a staker on a model.
// 29. getUserModelPayments(uint256 _modelId, address _user) view: Get total ETH paid by a user for a model.
// 30. getModelAverageRating(uint256 _modelId) view: Get the current average rating for a model.
// 31. getTotalProtocolFees() view: Get total accumulated protocol fees.
// 32. getModelEarnings(uint256 _modelId) view: Get total accumulated earnings for a model (before owner withdrawal).
// 33. getModelChallengeInfo(uint256 _modelId) view: Get challenge details for a model.

```

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract DecentralizedAIModelMarketplace {

    address public owner;
    bool public paused;

    // Configuration
    uint256 public protocolFeePercentage; // e.g., 5 for 5%
    uint256 public unstakeCooldownPeriod = 7 days; // Stakers must wait before finalizing unstake
    uint256 public challengeStakeRequirement = 1 ether; // Minimum stake required to initiate a challenge

    // Counters
    uint256 public nextModelId = 1; // Start model IDs from 1

    // --- Data Structures ---

    enum ModelStatus { Registered, Active, Deactivated, Challenged, Retired }

    struct Model {
        address payable owner; // Owner of the model
        string metadataHash;   // IPFS hash or link to model details/files
        string description;    // Human-readable description
        uint256 pricePerUse;   // Price in wei per usage credit (off-chain service interprets this)
        uint256 stakeRequirement; // Minimum stake required per validator
        ModelStatus status;    // Current status of the model

        uint256 totalUsageCount; // Total times usage was paid for
        uint256 totalEarnings;   // Total ETH earned by the model (before protocol fees and owner withdrawal)

        // Rating info
        uint256 totalRatingSum;
        uint256 ratingCount;
        uint8 averageRating; // Rounded average

        // Challenge Info
        address challengerAddress;
        uint256 challengeStake;
    }

    struct StakeInfo {
        uint256 amount; // Amount staked
        uint256 stakedAt; // Timestamp when staked
        uint256 unstakeInitiatedAt; // Timestamp when unstake was initiated (0 if not initiated)
        uint256 rewardsClaimed; // Total rewards claimed by this staker
    }

    // --- State Variables ---

    // Stores model data: modelId => Model
    mapping(uint256 => Model) public models;

    // Stores total stake for each model: modelId => totalStake
    mapping(uint256 => uint256) public totalModelStake;

    // Stores stake details for each validator: modelId => stakerAddress => StakeInfo
    mapping(uint256 => mapping(address => StakeInfo)) public modelStakes;

    // Stores a list of validator addresses for each model (for easier iteration/querying, requires careful management)
    mapping(uint256 => address[]) public modelValidators;
    // Helper to track if an address is already in the validators list to avoid duplicates
    mapping(uint256 => mapping(address => bool)) private isModelValidator;

    // Stores payments made by users for models: modelId => userAddress => totalPaid
    mapping(uint256 => mapping(address => uint256)) public userModelPayments;

    // Stores user ratings for models: modelId => userAddress => rating (1-5)
    mapping(uint256 => mapping(address => uint8)) public userModelRatings;

    // Accumulates total protocol fees
    uint256 public totalProtocolFees;

    // Lists for easier querying (less gas efficient for very large numbers, but useful for dApp frontend)
    uint256[] public activeModelIds;
    mapping(uint256 => bool) private isActiveModelId; // Helper for list management

    uint256[] public challengedModelIds;
     mapping(uint256 => bool) private isChallengedModelId; // Helper for list management

    // --- Events ---

    event ModelRegistered(uint256 indexed modelId, address indexed owner, string metadataHash, uint256 pricePerUse);
    event ModelUpdated(uint256 indexed modelId, string newMetadataHash, uint256 newPrice, string newDescription);
    event ModelStatusChanged(uint256 indexed modelId, ModelStatus newStatus);
    event UsagePaid(uint256 indexed modelId, address indexed user, uint256 amountPaid);
    event ModelEarningsWithdrawn(uint256 indexed modelId, address indexed owner, uint256 amount);
    event ProtocolFeesWithdrawn(address indexed owner, uint256 amount);
    event StakedForValidation(uint256 indexed modelId, address indexed staker, uint256 amount);
    event UnstakeInitiated(uint256 indexed modelId, address indexed staker, uint256 unstakeAvailableAt);
    event UnstakeFinalized(uint256 indexed modelId, address indexed staker, uint256 amount);
    event ModelChallenged(uint256 indexed modelId, address indexed challenger, uint256 challengeStake);
    event ChallengeResolved(uint256 indexed modelId, address indexed challenger, bool challengerWon, uint256 redistributedStake);
    event ValidationRewardsDistributed(uint256 indexed modelId, uint256 totalRewardsDistributed);
    event ValidationRewardsClaimed(uint256 indexed modelId, address indexed staker, uint256 amount);
    event ModelRated(uint256 indexed modelId, address indexed user, uint8 rating, uint8 newAverageRating);
    event ContractPaused(address indexed caller);
    event ContractUnpaused(address indexed caller);
    event FeePercentageUpdated(uint256 newPercentage);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    modifier isModelOwner(uint256 _modelId) {
        require(models[_modelId].owner == msg.sender, "Only model owner can perform this action");
        _;
    }

    modifier modelExists(uint256 _modelId) {
        require(_modelId > 0 && _modelId < nextModelId, "Model does not exist");
        _;
    }

    modifier modelIs(uint256 _modelId, ModelStatus _status) {
        require(models[_modelId].status == _status, "Model is not in the required status");
        _;
    }

     modifier isModelValidator(uint256 _modelId) {
        require(modelStakes[_modelId][msg.sender].amount > 0, "Caller is not a validator for this model");
        _;
    }

    // --- Constructor ---

    constructor(uint256 _protocolFeePercentage) {
        owner = payable(msg.sender);
        require(_protocolFeePercentage <= 100, "Fee percentage cannot exceed 100");
        protocolFeePercentage = _protocolFeePercentage;
        paused = false; // Initially not paused
    }

    // --- Setup & Management Functions ---

    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    function updateFeePercentage(uint256 _newPercentage) external onlyOwner {
        require(_newPercentage <= 100, "Fee percentage cannot exceed 100");
        protocolFeePercentage = _newPercentage;
        emit FeePercentageUpdated(_newPercentage);
    }

    function updateStakeCooldown(uint256 _newCooldown) external onlyOwner {
         require(_newCooldown > 0, "Cooldown must be greater than 0");
         unstakeCooldownPeriod = _newCooldown;
    }

    function updateChallengeStakeRequirement(uint256 _newRequirement) external onlyOwner {
        require(_newRequirement > 0, "Challenge stake must be greater than 0");
        challengeStakeRequirement = _newRequirement;
    }

    // --- Model Registration & Management ---

    function registerModel(string calldata _metadataHash, uint256 _pricePerUse, uint256 _stakeRequirement, string calldata _description)
        external
        whenNotPaused
        returns (uint256)
    {
        require(bytes(_metadataHash).length > 0, "Metadata hash is required");
        require(_pricePerUse > 0, "Price per use must be greater than 0");
        require(_stakeRequirement > 0, "Stake requirement must be greater than 0");

        uint256 modelId = nextModelId;
        models[modelId] = Model({
            owner: payable(msg.sender),
            metadataHash: _metadataHash,
            description: _description,
            pricePerUse: _pricePerUse,
            stakeRequirement: _stakeRequirement,
            status: ModelStatus.Active, // Automatically set to Active upon registration
            totalUsageCount: 0,
            totalEarnings: 0,
            totalRatingSum: 0,
            ratingCount: 0,
            averageRating: 0,
            challengerAddress: address(0),
            challengeStake: 0
        });

        // Add to active models list
        activeModelIds.push(modelId);
        isActiveModelId[modelId] = true;

        nextModelId++;

        emit ModelRegistered(modelId, msg.sender, _metadataHash, _pricePerUse);

        return modelId;
    }

    function updateModelMetadata(uint256 _modelId, string calldata _newMetadataHash, string calldata _newDescription)
        external
        modelExists(_modelId)
        isModelOwner(_modelId)
        whenNotPaused
    {
         require(bytes(_newMetadataHash).length > 0, "Metadata hash is required");

        models[_modelId].metadataHash = _newMetadataHash;
        models[_modelId].description = _newDescription;
        emit ModelUpdated(_modelId, _newMetadataHash, models[_modelId].pricePerUse, _newDescription);
    }

     function updateModelPrice(uint256 _modelId, uint256 _newPrice)
        external
        modelExists(_modelId)
        isModelOwner(_modelId)
        whenNotPaused
    {
        require(_newPrice > 0, "Price per use must be greater than 0");
        models[_modelId].pricePerUse = _newPrice;
        emit ModelUpdated(_modelId, models[_modelId].metadataHash, _newPrice, models[_modelId].description);
    }


    function deactivateModel(uint256 _modelId)
        external
        modelExists(_modelId)
        isModelOwner(_modelId)
        modelIs(_modelId, ModelStatus.Active)
        whenNotPaused
    {
        models[_modelId].status = ModelStatus.Deactivated;
        _removeModelFromActiveList(_modelId); // Remove from active list
        emit ModelStatusChanged(_modelId, ModelStatus.Deactivated);
    }

    function activateModel(uint256 _modelId)
        external
        modelExists(_modelId)
        isModelOwner(_modelId)
        modelIs(_modelId, ModelStatus.Deactivated)
        whenNotPaused
    {
        models[_modelId].status = ModelStatus.Active;
         _addModelToActiveList(_modelId); // Add back to active list
        emit ModelStatusChanged(_modelId, ModelStatus.Active);
    }

    function retireModel(uint256 _modelId)
        external
        modelExists(_modelId)
        isModelOwner(_modelId)
        whenNotPaused
    {
        ModelStatus currentStatus = models[_modelId].status;
        require(currentStatus != ModelStatus.Retired, "Model is already retired");
        require(currentStatus != ModelStatus.Challenged, "Cannot retire a challenged model");

        models[_modelId].status = ModelStatus.Retired;

        // Clean up lists
        if (currentStatus == ModelStatus.Active) {
            _removeModelFromActiveList(_modelId);
        }
        // Note: Retired models might still have stakes that need to be finalized by stakers

        emit ModelStatusChanged(_modelId, ModelStatus.Retired);
    }

     // --- Helper functions for managing dynamic lists (can be optimized, naive implementation) ---

    function _addModelToActiveList(uint256 _modelId) private {
        if (!isActiveModelId[_modelId]) {
             activeModelIds.push(_modelId);
             isActiveModelId[_modelId] = true;
        }
    }

     function _removeModelFromActiveList(uint256 _modelId) private {
        if (isActiveModelId[_modelId]) {
            // Find and remove the modelId from the array
            for (uint i = 0; i < activeModelIds.length; i++) {
                if (activeModelIds[i] == _modelId) {
                    activeModelIds[i] = activeModelIds[activeModelIds.length - 1];
                    activeModelIds.pop();
                    isActiveModelId[_modelId] = false;
                    break;
                }
            }
        }
    }

    function _addModelToChallengedList(uint256 _modelId) private {
         if (!isChallengedModelId[_modelId]) {
             challengedModelIds.push(_modelId);
             isChallengedModelId[_modelId] = true;
        }
    }

     function _removeModelFromChallengedList(uint256 _modelId) private {
        if (isChallengedModelId[_modelId]) {
            for (uint i = 0; i < challengedModelIds.length; i++) {
                if (challengedModelIds[i] == _modelId) {
                    challengedModelIds[i] = challengedModelIds[challengedModelIds.length - 1];
                    challengedModelIds.pop();
                    isChallengedModelId[_modelId] = false;
                    break;
                }
            }
        }
    }


    // --- Usage Payments ---
    // Off-chain service integrating with the model would check userModelPayments[modelId][userAddress]
    // and models[modelId].pricePerUse to determine how many usage credits the user has purchased.
    // The off-chain service then tracks usage and deducts credits, prompting the user to pay again if needed.

    function payForModelUsage(uint256 _modelId)
        external
        payable
        modelExists(_modelId)
        modelIs(_modelId, ModelStatus.Active)
        whenNotPaused
    {
        require(msg.value > 0, "Payment amount must be greater than 0");

        Model storage model = models[_modelId];

        uint256 paymentAmount = msg.value;

        // Calculate protocol fee
        uint256 protocolFee = (paymentAmount * protocolFeePercentage) / 100;
        uint256 modelShare = paymentAmount - protocolFee;

        totalProtocolFees += protocolFee;
        model.totalEarnings += modelShare;
        userModelPayments[_modelId][msg.sender] += paymentAmount; // Track total paid by user

        // Optional: Distribute a small portion of earnings to active validators immediately?
        // Or let validators claim rewards from the accumulated earnings later. Let's go with claiming later.

        emit UsagePaid(_modelId, msg.sender, paymentAmount);
         // totalUsageCount update is typically done by the off-chain service after successful usage
         // models[_modelId].totalUsageCount++;
    }

    // --- Earnings & Withdrawals ---

    function withdrawModelEarnings(uint256 _modelId)
        external
        modelExists(_modelId)
        isModelOwner(_modelId)
        whenNotPaused
    {
        Model storage model = models[_modelId];
        uint256 amountToWithdraw = model.totalEarnings;
        require(amountToWithdraw > 0, "No earnings to withdraw");

        model.totalEarnings = 0; // Reset earnings after withdrawal

        // Use low-level call for robustness against reentrancy in withdrawal
        (bool success, ) = model.owner.call{value: amountToWithdraw}("");
        require(success, "ETH transfer failed");

        emit ModelEarningsWithdrawn(_modelId, msg.sender, amountToWithdraw);
    }

    function withdrawProtocolFees() external onlyOwner {
        uint256 amountToWithdraw = totalProtocolFees;
        require(amountToWithdraw > 0, "No protocol fees to withdraw");

        totalProtocolFees = 0; // Reset fees after withdrawal

        // Use low-level call
        (bool success, ) = owner.call{value: amountToWithdraw}("");
        require(success, "ETH transfer failed");

        emit ProtocolFeesWithdrawn(msg.sender, amountToWithdraw);
    }

    function claimValidationRewards(uint256 _modelId)
        external
        modelExists(_modelId)
        isModelValidator(_modelId)
        whenNotPaused
    {
        // Calculate pending rewards based on current stake and model earnings
        // This requires tracking earnings accrued *since* the last claim or stake change.
        // A simpler approach: accrue rewards into a pool per model, and let stakers claim
        // based on their proportion of the *current* total stake. This is less precise
        // if stake amounts change often between claims, but simpler.
        // Let's go with the simpler pool approach for this example.

        // For this basic implementation, rewards distribution happens via distributeValidationRewards
        // and then stakers can claim from their accrued balance.
        // This assumes distributeValidationRewards updates an internal balance for each staker.
        // Let's add a mapping for accrued rewards:
        // mapping(uint256 => mapping(address => uint256)) public pendingValidationRewards;
        // distributeValidationRewards would add to this. claimValidationRewards withdraws from this.

        uint256 rewardsToClaim = pendingValidationRewards[_modelId][msg.sender];
        require(rewardsToClaim > 0, "No rewards to claim");

        pendingValidationRewards[_modelId][msg.sender] = 0; // Reset pending rewards
        modelStakes[_modelId][msg.sender].rewardsClaimed += rewardsToClaim; // Track total claimed

        // Use low-level call
        (bool success, ) = msg.sender.call{value: rewardsToClaim}("");
        require(success, "ETH transfer failed");

        emit ValidationRewardsClaimed(_modelId, msg.sender, rewardsToClaim);
    }

     // --- Staking & Validation ---

    mapping(uint256 => mapping(address => uint256)) public pendingValidationRewards; // Added mapping

    function stakeForModelValidation(uint256 _modelId)
        external
        payable
        modelExists(_modelId)
        modelIs(_modelId, ModelStatus.Active) // Can only stake on active models
        whenNotPaused
    {
        require(msg.value >= models[_modelId].stakeRequirement, "Staked amount must meet minimum requirement");

        uint256 currentStake = modelStakes[_modelId][msg.sender].amount;

        // If this is the first stake, add to validators list
        if (currentStake == 0) {
             modelValidators[_modelId].push(msg.sender);
             isModelValidator[_modelId][msg.sender] = true;
        }

        // Update stake info
        modelStakes[_modelId][msg.sender].amount += msg.value;
        modelStakes[_modelId][msg.sender].stakedAt = block.timestamp; // Update stakedAt on *any* stake deposit
        modelStakes[_modelId][msg.sender].unstakeInitiatedAt = 0; // Reset unstake timer

        // Update total stake for the model
        totalModelStake[_modelId] += msg.value;

        emit StakedForValidation(_modelId, msg.sender, msg.value);
    }

    function unstakeFromModelValidation(uint256 _modelId)
        external
        modelExists(_modelId)
        isModelValidator(_modelId)
        whenNotPaused
    {
        StakeInfo storage stake = modelStakes[_modelId][msg.sender];
        require(stake.amount > 0, "No active stake to unstake");
        require(stake.unstakeInitiatedAt == 0, "Unstake already initiated");
        require(models[_modelId].status != ModelStatus.Challenged, "Cannot unstake from a challenged model");

        stake.unstakeInitiatedAt = block.timestamp;

        emit UnstakeInitiated(_modelId, msg.sender, stake.unstakeInitiatedAt + unstakeCooldownPeriod);
    }

    function finalizeUnstake(uint256 _modelId)
        external
        modelExists(_modelId)
        isModelValidator(_modelId)
        whenNotPaused
    {
        StakeInfo storage stake = modelStakes[_modelId][msg.sender];
        require(stake.unstakeInitiatedAt > 0, "Unstake was not initiated");
        require(block.timestamp >= stake.unstakeInitiatedAt + unstakeCooldownPeriod, "Unstake cooldown period not over");
         require(models[_modelId].status != ModelStatus.Challenged, "Cannot finalize unstake from a challenged model");

        uint256 amountToUnstake = stake.amount;
        require(amountToUnstake > 0, "No stake to finalize");

        // Reset stake info
        delete modelStakes[_modelId][msg.sender];
        totalModelStake[_modelId] -= amountToUnstake;

        // Remove from validators list (less critical if stake amount is 0, but good practice)
        isModelValidator[_modelId][msg.sender] = false;
         // Simple list removal (less efficient for large lists)
        address[] storage validators = modelValidators[_modelId];
        for (uint i = 0; i < validators.length; i++) {
            if (validators[i] == msg.sender) {
                validators[i] = validators[validators.length - 1];
                validators.pop();
                break;
            }
        }


        // Use low-level call for withdrawal
        (bool success, ) = msg.sender.call{value: amountToUnstake}("");
        require(success, "ETH transfer failed");

        emit UnstakeFinalized(_modelId, msg.sender, amountToUnstake);
    }

    // Function to allow anyone to trigger reward distribution
    // This pulls from the model's earnings and adds to stakers' pending rewards.
    // Rewards are distributed based on the *current* stake proportions.
    // This incentivizes staking over longer periods and claiming less often.
    function distributeValidationRewards(uint256 _modelId)
        external
        modelExists(_modelId)
        whenNotPaused
    {
        Model storage model = models[_modelId];
        require(model.status == ModelStatus.Active, "Rewards can only be distributed for active models");
        require(totalModelStake[_modelId] > 0, "No active stakers for this model");
        require(model.totalEarnings > 0, "No model earnings to distribute");

        // Decide portion of earnings to distribute to stakers (e.g., 50% of current earnings)
        uint256 rewardsPool = model.totalEarnings / 2; // Example: 50% goes to stakers
        model.totalEarnings -= rewardsPool; // Deduct from model's earnings

        uint256 distributedAmount = 0;

        // Iterate through current validators and distribute proportionally
        // NOTE: Iterating over a potentially large array can hit gas limits.
        // A more scalable approach uses checkpoints or requires stakers to pull based on global state changes.
        // For this example, we use direct iteration.
        address[] storage validators = modelValidators[_modelId];
        uint256 currentTotalStake = totalModelStake[_modelId]; // Use total stake at time of distribution

        for (uint i = 0; i < validators.length; i++) {
            address stakerAddress = validators[i];
            uint256 stakerStake = modelStakes[_modelId][stakerAddress].amount;

            // Ensure staker is still valid and hasn't initiated unstake
             if (stakerStake > 0 && modelStakes[_modelId][stakerAddress].unstakeInitiatedAt == 0) {
                 // Calculate staker's share (proportion of their stake to total stake)
                uint256 stakerReward = (rewardsPool * stakerStake) / currentTotalStake;
                pendingValidationRewards[_modelId][stakerAddress] += stakerReward;
                distributedAmount += stakerReward;
             }
        }

        // Any small remainder from calculations stays in model.totalEarnings or could be sent to protocol fees

        emit ValidationRewardsDistributed(_modelId, distributedAmount);
    }

    // --- Model Challenges ---

    function challengeModelAccuracy(uint256 _modelId)
        external
        payable
        modelExists(_modelId)
        modelIs(_modelId, ModelStatus.Active) // Can only challenge active models
        whenNotPaused
    {
        require(msg.value >= challengeStakeRequirement, "Insufficient challenge stake");
        require(models[_modelId].challengerAddress == address(0), "Model is already under challenge");

        Model storage model = models[_modelId];
        model.status = ModelStatus.Challenged;
        model.challengerAddress = msg.sender;
        model.challengeStake = msg.value;

        _removeModelFromActiveList(_modelId); // Remove from active list
        _addModelToChallengedList(_modelId); // Add to challenged list

        emit ModelChallenged(_modelId, msg.sender, msg.value);
    }

    // Resolution is handled by the contract owner (or could be a DAO/oracle in a more complex version)
    function resolveChallenge(uint256 _modelId, bool _challengerWon)
        external
        onlyOwner // Centralized resolution for simplicity in this example
        modelExists(_modelId)
        modelIs(_modelId, ModelStatus.Challenged)
    {
        Model storage model = models[_modelId];
        address challenger = model.challengerAddress;
        uint256 challengeStake = model.challengeStake;

        uint256 redistributedAmount = 0;

        if (_challengerWon) {
            // Challenger wins: Challenger gets stake back + potentially penalty from model owner/stakers
            // Simple: Challenger gets their stake back.
             (bool success, ) = payable(challenger).call{value: challengeStake}("");
             require(success, "ETH transfer failed (challenger win)");
             redistributedAmount = challengeStake;

            // Optional: Implement slashing for model owner or stakers.
            // e.g., slash 10% of model owner's remaining earnings or staker's stake.
            // Skipping complex slashing for this example.

            model.status = ModelStatus.Deactivated; // Challenged model is deactivated upon losing
            _removeModelFromChallengedList(_modelId);

        } else {
            // Challenger loses: Challenger loses stake, distributed to model stakers
            require(totalModelStake[_modelId] > 0, "No stakers to receive lost challenge stake");

            // Distribute challenge stake proportionally to current stakers
            address[] storage validators = modelValidators[_modelId];
            uint256 currentTotalStake = totalModelStake[_modelId]; // Use total stake at time of resolution

            for (uint i = 0; i < validators.length; i++) {
                 address stakerAddress = validators[i];
                 uint256 stakerStake = modelStakes[_modelId][stakerAddress].amount;

                 if (stakerStake > 0) { // Ensure staker is still valid
                    uint256 stakerShare = (challengeStake * stakerStake) / currentTotalStake;
                    pendingValidationRewards[_modelId][stakerAddress] += stakerShare; // Add to pending rewards
                    redistributedAmount += stakerShare;
                 }
            }
             // Any small remainder stays in contract or sent to protocol

            model.status = ModelStatus.Active; // Model returns to active if challenger loses
            _removeModelFromChallengedList(_modelId);
            _addModelToActiveList(_modelId); // Add back to active list
        }

        // Reset challenge info
        model.challengerAddress = address(0);
        model.challengeStake = 0;

        emit ChallengeResolved(_modelId, challenger, _challengerWon, redistributedAmount);
        emit ModelStatusChanged(_modelId, model.status);
    }

    // --- Rating & Reputation ---

    function rateModel(uint256 _modelId, uint8 _rating)
        external
        modelExists(_modelId)
        whenNotPaused
    {
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");
        // Optional: Require user to have paid for usage or staked on the model to rate
        // require(userModelPayments[_modelId][msg.sender] > 0 || modelStakes[_modelId][msg.sender].amount > 0, "Must have used or staked on the model to rate");
        require(userModelRatings[_modelId][msg.sender] == 0, "You have already rated this model"); // Allow only one rating per user

        Model storage model = models[_modelId];

        userModelRatings[_modelId][msg.sender] = _rating;
        model.totalRatingSum += _rating;
        model.ratingCount++;
        model.averageRating = uint8(model.totalRatingSum / model.ratingCount); // Integer division

        emit ModelRated(_modelId, msg.sender, _rating, model.averageRating);
    }

    // --- Query Functions (Read-only) ---

    function getModelDetails(uint256 _modelId)
        public
        view
        modelExists(_modelId)
        returns (
            uint256 modelId,
            address ownerAddress,
            string memory metadataHash,
            string memory description,
            uint256 pricePerUse,
            uint256 stakeRequirement,
            ModelStatus status,
            uint256 totalUsageCount,
            uint256 totalEarnings,
            uint8 averageRating,
            address challengerAddress,
            uint256 challengeStake,
            uint256 currentTotalStake
        )
    {
        Model storage model = models[_modelId];
        return (
            _modelId,
            model.owner,
            model.metadataHash,
            model.description,
            model.pricePerUse,
            model.stakeRequirement,
            model.status,
            model.totalUsageCount,
            model.totalEarnings,
            model.averageRating,
            model.challengerAddress,
            model.challengeStake,
            totalModelStake[_modelId]
        );
    }

    function listActiveModels() external view returns (uint256[] memory) {
        // Return a copy of the activeModelIds array
        uint256[] memory activeIds = new uint256[](activeModelIds.length);
        for(uint i = 0; i < activeModelIds.length; i++) {
            activeIds[i] = activeModelIds[i];
        }
        return activeIds;
    }

     function listModelsByOwner(address _owner) external view returns (uint256[] memory) {
        uint256[] memory ownedModelIds = new uint256[](0); // Dynamic array is inefficient, better off-chain query
        uint256 count = 0;
        // Iterate through all possible model IDs (inefficient for many models)
        // In a real dapp, a mapping address => uint[] modelIds might be better,
        // or rely on off-chain indexing events.
        // For demonstration, we iterate up to nextModelId.
        for (uint256 i = 1; i < nextModelId; i++) {
            if (models[i].owner == _owner) {
                 count++;
            }
        }
        ownedModelIds = new uint256[](count);
        count = 0; // Reset counter for filling array
         for (uint256 i = 1; i < nextModelId; i++) {
            if (models[i].owner == _owner) {
                 ownedModelIds[count] = i;
                 count++;
            }
        }
        return ownedModelIds;
    }


    function listModelsUnderChallenge() external view returns (uint256[] memory) {
        // Return a copy of the challengedModelIds array
        uint256[] memory challengedIds = new uint256[](challengedModelIds.length);
        for(uint i = 0; i < challengedModelIds.length; i++) {
            challengedIds[i] = challengedModelIds[i];
        }
        return challengedIds;
    }


    function getStakedValidators(uint256 _modelId)
        external
        view
        modelExists(_modelId)
        returns (address[] memory)
    {
        // Return a copy of the modelValidators array for this model
        address[] memory validators = new address[](modelValidators[_modelId].length);
         uint256 count = 0;
         // Only include addresses that still have a non-zero stake
         for(uint i = 0; i < modelValidators[_modelId].length; i++) {
             address validatorAddress = modelValidators[_modelId][i];
             if (modelStakes[_modelId][validatorAddress].amount > 0) {
                 validators[count] = validatorAddress;
                 count++;
             }
         }
        // Resize array to actual count
        address[] memory finalValidators = new address[](count);
        for(uint i = 0; i < count; i++) {
            finalValidators[i] = validators[i];
        }
        return finalValidators;
    }


    function getValidatorStake(uint256 _modelId, address _staker)
        external
        view
        modelExists(_modelId)
        returns (uint256 amount, uint256 stakedAt, uint256 unstakeInitiatedAt, uint256 rewardsClaimed, uint256 pendingRewards)
    {
        StakeInfo storage stake = modelStakes[_modelId][_staker];
        return (
            stake.amount,
            stake.stakedAt,
            stake.unstakeInitiatedAt,
            stake.rewardsClaimed,
            pendingValidationRewards[_modelId][_staker] // Also return pending rewards
        );
    }

    function getUserModelPayments(uint256 _modelId, address _user)
        external
        view
        modelExists(_modelId)
        returns (uint256)
    {
        return userModelPayments[_modelId][_user];
    }

    function getModelAverageRating(uint256 _modelId)
        external
        view
        modelExists(_modelId)
        returns (uint8)
    {
        return models[_modelId].averageRating;
    }

    // Function 31 already exists: getTotalProtocolFees() is a public state variable getter

    function getModelEarnings(uint256 _modelId)
        external
        view
        modelExists(_modelId)
        returns (uint256)
    {
        return models[_modelId].totalEarnings;
    }

     function getModelChallengeInfo(uint256 _modelId)
        external
        view
        modelExists(_modelId)
        returns (address challenger, uint256 challengeStakeAmount)
    {
         Model storage model = models[_modelId];
         return (model.challengerAddress, model.challengeStake);
     }

}
```