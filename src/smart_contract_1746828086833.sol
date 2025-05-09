Okay, let's design a smart contract for a **Decentralized AI Model Marketplace with Staking, Validation, and Reputation**. This concept involves providers listing AI models (represented by metadata/hashes), validators verifying model quality/safety off-chain and reporting results on-chain, and users purchasing access to use these validated models. It includes staking, potential slashing, reputation tracking, and a basic dispute mechanism.

This is a reasonably advanced concept because it requires coordinating off-chain work (AI model validation and inference) with on-chain incentives (staking, rewards, slashing) and state management. It's creative as it applies blockchain to a specific, non-financial service market (AI). It's trendy due to the focus on AI and decentralized networks.

We'll aim for more than 20 functions by including functions for providers, validators, users, and administrative/helper tasks.

---

**Outline:**

1.  **Contract Purpose:** Facilitate a decentralized marketplace for AI models. Providers list models, stake tokens, and get rewarded for usage. Validators stake tokens, review models off-chain, and get rewarded for honest validation. Users pay to gain access to validated models.
2.  **Roles:** Owner (admin), Provider, Validator, User.
3.  **Key Concepts:**
    *   Model Listing with Metadata (off-chain model details).
    *   Staking for Providers (commitment to model quality).
    *   Staking for Validators (commitment to honest validation).
    *   Validation Process: Validators select models, perform off-chain checks, submit on-chain votes.
    *   Validation Finalization: Determines model status (Active/Rejected) based on validator consensus, handles rewards/slashing.
    *   Model Access Purchase: Users pay a fee to unlock usage of a model.
    *   Usage Tracking: Contract tracks purchased usage credits. (Actual inference happens off-chain, verified implicitly or via separate proofs if needed, but for this contract, we track the *right* to use).
    *   Reputation System: Tracks reliability of Providers and Validators.
    *   Dispute Mechanism: Basic system to report models or validators.
    *   Marketplace Fees.
4.  **Data Structures:** Structs for `Model`, `ProviderInfo`, `ValidatorInfo`, `ValidationVote`, `UserAccess`. Enums for `ModelStatus`, `ValidationStatus`, `DisputeStatus`.
5.  **Events:** Crucial for off-chain services to monitor contract state changes (new models, status changes, payments, etc.).

**Function Summary:**

*   **Provider Functions:**
    1.  `submitModel`: List a new AI model, stake required amount.
    2.  `updateModelMetadata`: Update off-chain details link for a model.
    3.  `stakeAsProvider`: Add more stake to become/remain a provider or support a model.
    4.  `withdrawProviderStake`: Withdraw unlocked staked tokens.
    5.  `claimProviderEarnings`: Claim revenue from model usage after fees.
    6.  `pauseOwnModel`: Temporarily deactivate a submitted or active model.
    7.  `unpauseOwnModel`: Reactivate a paused model.
    8.  `getProviderInfo`: Retrieve provider's staking and reputation info.
    9.  `getProviderModels`: Get a list of models submitted by a provider.
*   **Validator Functions:**
    10. `registerAsValidator`: Become a validator, stake required amount.
    11. `stakeAsValidator`: Add more stake to become/remain a validator.
    12. `withdrawValidatorStake`: Withdraw unlocked staked tokens.
    13. `selectModelForValidation`: Signal intent to validate a specific model (moves it to UnderValidation).
    14. `submitValidationResult`: Submit off-chain validation outcome (valid/invalid) and proof link.
    15. `claimValidatorRewards`: Claim rewards for correct validations.
    16. `getValidatorInfo`: Retrieve validator's staking and reputation info.
    17. `getValidationVote`: Get a validator's vote on a specific model.
*   **User Functions:**
    18. `depositForUsage`: Deposit tokens into contract balance for purchasing access.
    19. `purchaseModelAccess`: Buy N inference credits for a specific active model.
    20. `logModelUsage`: Signal one inference credit used for a model. (Off-chain service calls this after user consumes service).
    21. `submitModelRating`: Rate a model after using it.
    22. `withdrawUserFunds`: Withdraw unused deposited tokens.
    23. `getUserAccessPermissions`: Get remaining usage credits for a model.
*   **Marketplace/Admin Functions:**
    24. `finalizeModelValidation`: Finalize validation process for a model, update status, reward/slash.
    25. `reportFaultyModel`: User reports a model that is not working as advertised (initiates dispute).
    26. `reportMaliciousValidator`: Provider/User reports a validator (initiates dispute).
    27. `resolveDispute`: Placeholder for complex dispute resolution logic (e.g., admin action, committee vote).
    28. `setMarketplaceFee`: Owner sets the marketplace fee percentage.
    29. `setMinStakes`: Owner sets minimum stakes for providers/validators.
    30. `setValidationPeriod`: Owner sets the duration for the validation phase.
    31. `setRequiredValidators`: Owner sets the number of validators needed for a model.
    32. `getMarketplaceState`: Get various configuration parameters.
    33. `getModelDetails`: Get full details for a specific model.
    34. `getModelsByStatus`: Get a list of model IDs filtering by status (e.g., `Submitted` for validators to pick).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Added for SafeMath

// This is a conceptual contract. Off-chain components for actual AI inference,
// validation proof generation, and metadata hosting are required.
// Oracle dependence: Validation outcomes and potentially dispute resolution
// might depend on data provided by trusted or decentralized oracles.
// This implementation simplifies some aspects (e.g., dispute resolution is basic).

contract DecentralizedAIModelMarketplace is Ownable, ReentrancyGuard {
    using SafeMath for uint256; // Using SafeMath for arithmetic operations

    // --- Events ---
    event ModelSubmitted(uint256 indexed modelId, address indexed provider, string metadataURI, uint256 inferenceCost, uint256 stakeAmount);
    event ModelMetadataUpdated(uint256 indexed modelId, string newMetadataURI);
    event ModelStatusUpdated(uint256 indexed modelId, ModelStatus newStatus);
    event ProviderStaked(address indexed provider, uint256 amount);
    event ProviderStakeWithdrawn(address indexed provider, uint256 amount);
    event ProviderEarningsClaimed(address indexed provider, uint256 amount);
    event ValidatorRegistered(address indexed validator, uint256 stakeAmount);
    event ValidatorStaked(address indexed validator, uint256 amount);
    event ValidatorStakeWithdrawn(address indexed validator, uint256 amount);
    event ValidatorSelectedModel(uint256 indexed modelId, address indexed validator);
    event ValidationResultSubmitted(uint256 indexed modelId, address indexed validator, bool isValid, string proofURI);
    event ModelValidationFinalized(uint256 indexed modelId, ValidationStatus status, uint256 rewardPool, uint256 slashAmount);
    event ValidatorRewardsClaimed(address indexed validator, uint256 amount);
    event UserDeposited(address indexed user, uint256 amount);
    event UserModelAccessPurchased(address indexed user, uint256 indexed modelId, uint256 numberOfUses, uint256 totalCost);
    event ModelUsageLogged(address indexed user, uint256 indexed modelId, uint256 remainingUses);
    event ModelRated(address indexed user, uint256 indexed modelId, uint8 rating);
    event UserFundsWithdrawn(address indexed user, uint256 amount);
    event DisputeReported(uint256 indexed disputeId, DisputeType indexed disputeType, uint256 indexed subjectId, address reporter, string reason);
    event DisputeResolved(uint256 indexed disputeId, DisputeResult indexed result);
    event MarketplaceFeeUpdated(uint256 newFeeBps); // Fee in basis points (1/10000)
    event MinStakesUpdated(uint256 minProvider, uint256 minValidator);
    event ValidationPeriodUpdated(uint256 periodInSeconds);
    event RequiredValidatorsUpdated(uint256 count);

    // --- Enums ---
    enum ModelStatus { Submitted, UnderValidation, Active, Rejected, Paused, ReportedForDispute }
    enum ValidationStatus { Pending, Validated, RejectedByValidators, ConsensusReached, DisputeResolvedStatus } // Status of the *validation process* for a model
    enum DisputeType { FaultyModel, MaliciousValidator }
    enum DisputeResult { Unresolved, ResolvedValid, ResolvedInvalid } // Outcome of a dispute resolution

    // --- Structs ---
    struct Model {
        address provider;
        string metadataURI; // Link to IPFS/Arweave containing model details, API endpoint info etc.
        uint256 inferenceCost; // Cost per single inference, in wei or token units
        uint256 providerStake; // Stake locked by the provider for this model
        ModelStatus status;
        ValidationStatus validationStatus; // Current status of the validation process
        uint256 submissionTimestamp; // Time the model was submitted
        uint256 validationStartTime; // Time validation period started (after first validator selection)
        mapping(address => ValidationVote) validationVotes;
        address[] validators; // List of validators who voted or were selected for this model
        uint256 votesForValid;
        uint256 votesForInvalid;
        uint256 totalUses; // Total times this model has been logged as used
        uint256 ratingSum; // Sum of all ratings received (e.g., 1-5)
        uint256 numberOfRatings;
        uint256 disputeId; // 0 if no active dispute
        uint256 unlockedStakeTimestamp; // Timestamp when provider stake is unlocked (e.g., after validation/dispute)
        uint256 totalEarned; // Total earnings accumulated for this model
    }

    struct ValidationVote {
        bool hasVoted;
        bool isValid; // True if validator thinks the model is valid
        string proofURI; // Link to off-chain validation results/proof
        uint256 stakedAmount; // Stake locked by validator for this vote
        bool rewarded; // Has validator been rewarded for this vote?
        bool slashed; // Has validator been slashed for this vote?
    }

    struct ProviderInfo {
        uint256 totalStake;
        uint256 unlockedStake; // Stake that can be withdrawn
        uint256 lockedStake; // Stake currently locked (e.g., on models, disputes)
        uint256 reputation; // Simple reputation score (higher is better)
        uint256 totalEarnings;
        mapping(uint256 => uint256) modelStakes; // Stake per model
        mapping(uint256 => uint256) unlockedModelStakes; // Unlocked stake per model
    }

    struct ValidatorInfo {
        uint256 totalStake;
        uint256 unlockedStake; // Stake that can be withdrawn
        uint256 lockedStake; // Stake currently locked on validations/disputes
        uint256 reputation; // Simple reputation score (higher is better)
        bool isActive; // Flag if validator is currently active
        uint256 totalRewards;
        mapping(uint256 => uint256) voteStakes; // Stake per vote on a model
        mapping(uint256 => uint256) unlockedVoteStakes; // Unlocked stake per vote
    }

    struct UserAccess {
        uint256 remainingUses; // Number of inferences the user can perform
        uint256 lastUsageTimestamp;
    }

    struct Dispute {
        uint256 indexed subjectId; // modelId or validator address (packed into uint)
        DisputeType disputeType;
        address reporter;
        string reason;
        uint256 reportTimestamp;
        DisputeStatus status;
        // Could add more fields for evidence, voting, etc.
    }

    // --- State Variables ---
    IERC20 public marketplaceToken; // The token used for staking, payment, rewards

    uint256 public minProviderStake;
    uint256 public minValidatorStake;
    uint256 public validationPeriod; // Duration in seconds for the validation process
    uint256 public requiredValidators; // Minimum number of validators needed to finalize validation
    uint256 public marketplaceFeeBps; // Fee taken by the marketplace, in basis points (e.g., 100 = 1%)

    uint256 private modelCounter; // To generate unique model IDs
    uint256 private disputeCounter; // To generate unique dispute IDs

    mapping(uint256 => Model) public models;
    mapping(address => ProviderInfo) public providers;
    mapping(address => ValidatorInfo) public validators;
    mapping(address => mapping(uint256 => UserAccess)) private userModelAccess; // userAddress => modelId => UserAccess
    mapping(uint256 => Dispute) public disputes; // disputeId => Dispute

    // --- Constructor ---
    constructor(address tokenAddress, uint256 _minProviderStake, uint256 _minValidatorStake, uint256 _validationPeriod, uint256 _requiredValidators, uint256 _marketplaceFeeBps) Ownable(msg.sender) {
        marketplaceToken = IERC20(tokenAddress);
        minProviderStake = _minProviderStake;
        minValidatorStake = _minValidatorStake;
        validationPeriod = _validationPeriod;
        requiredValidators = _requiredValidators;
        marketplaceFeeBps = _marketplaceFeeBps; // e.g., 100 for 1%
        require(marketplaceFeeBps <= 10000, "Fee cannot exceed 100%");
    }

    // --- Modifiers ---
    modifier onlyProvider() {
        require(providers[msg.sender].totalStake >= minProviderStake, "Caller is not a registered provider");
        _;
    }

    modifier onlyValidator() {
        require(validators[msg.sender].totalStake >= minValidatorStake && validators[msg.sender].isActive, "Caller is not an active validator");
        _;
    }

    modifier modelExists(uint256 _modelId) {
        require(_modelId > 0 && _modelId <= modelCounter, "Model does not exist");
        _;
    }

    modifier isModelProvider(uint256 _modelId) {
        require(models[_modelId].provider == msg.sender, "Caller is not the model provider");
        _;
    }

    modifier isActiveModel(uint256 _modelId) {
        require(models[_modelId].status == ModelStatus.Active, "Model is not active");
        _;
    }

    modifier nonZeroAmount(uint256 amount) {
        require(amount > 0, "Amount must be greater than 0");
        _;
    }

    // --- Provider Functions ---

    /**
     * @notice Provider submits a new AI model to the marketplace.
     * Requires staking minProviderStake amount of tokens.
     * @param _metadataURI Link to off-chain model details (IPFS, Arweave, etc.).
     * @param _inferenceCost Cost per single use of the model, in token units.
     * @param _stakeAmount Amount of tokens to stake for this specific model (must be >= minProviderStake).
     */
    function submitModel(string calldata _metadataURI, uint256 _inferenceCost, uint256 _stakeAmount) external nonReentrant nonZeroAmount(_stakeAmount) {
        require(_stakeAmount >= minProviderStake, "Stake amount must be at least minProviderStake");
        require(bytes(_metadataURI).length > 0, "Metadata URI cannot be empty");

        modelCounter++;
        uint256 modelId = modelCounter;

        // Transfer stake from provider to contract
        require(marketplaceToken.transferFrom(msg.sender, address(this), _stakeAmount), "Token transfer failed for provider stake");

        models[modelId] = Model({
            provider: msg.sender,
            metadataURI: _metadataURI,
            inferenceCost: _inferenceCost,
            providerStake: _stakeAmount,
            status: ModelStatus.Submitted,
            validationStatus: ValidationStatus.Pending,
            submissionTimestamp: block.timestamp,
            validationStartTime: 0, // Will be set when validation starts
            votesForValid: 0,
            votesForInvalid: 0,
            totalUses: 0,
            ratingSum: 0,
            numberOfRatings: 0,
            disputeId: 0,
            unlockedStakeTimestamp: 0, // Will be set after validation/dispute
            totalEarned: 0,
            validators: new address[](0) // Initialize empty array
        });

        // Update provider info
        providers[msg.sender].totalStake = providers[msg.sender].totalStake.add(_stakeAmount);
        providers[msg.sender].lockedStake = providers[msg.sender].lockedStake.add(_stakeAmount);
        providers[msg.sender].modelStakes[modelId] = _stakeAmount;
        // Reputation update logic can be added here (e.g., small positive boost for submission)
        providers[msg.sender].reputation = providers[msg.sender].reputation.add(1); // Basic reputation gain

        emit ModelSubmitted(modelId, msg.sender, _metadataURI, _inferenceCost, _stakeAmount);
    }

    /**
     * @notice Provider updates the metadata URI for their model.
     * Can only be done if the model is not currently in validation or active.
     * @param _modelId The ID of the model to update.
     * @param _newMetadataURI The new link to off-chain model details.
     */
    function updateModelMetadata(uint256 _modelId, string calldata _newMetadataURI) external modelExists(_modelId) isModelProvider(_modelId) {
        Model storage model = models[_modelId];
        require(model.status != ModelStatus.UnderValidation && model.status != ModelStatus.Active, "Cannot update metadata when model is under validation or active");
        require(bytes(_newMetadataURI).length > 0, "Metadata URI cannot be empty");

        model.metadataURI = _newMetadataURI;

        emit ModelMetadataUpdated(_modelId, _newMetadataURI);
    }

    /**
     * @notice Allows a provider to increase their overall stake or add stake to a specific model.
     * @param _amount The amount of tokens to stake.
     * @param _modelId Optional: The ID of the model to add stake to (0 to just add to general stake).
     */
    function stakeAsProvider(uint256 _amount, uint256 _modelId) external nonReentrant nonZeroAmount(_amount) {
        require(marketplaceToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed for provider stake");

        ProviderInfo storage provider = providers[msg.sender];
        provider.totalStake = provider.totalStake.add(_amount);

        if (_modelId > 0) {
            require(_modelId <= modelCounter, "Model does not exist");
            require(models[_modelId].provider == msg.sender, "Can only add stake to your own model");
            Model storage model = models[_modelId];
            model.providerStake = model.providerStake.add(_amount);
            provider.modelStakes[_modelId] = provider.modelStakes[_modelId].add(_amount);
            provider.lockedStake = provider.lockedStake.add(_amount); // New stake is locked
        } else {
            provider.unlockedStake = provider.unlockedStake.add(_amount); // New stake is unlocked if not tied to a specific model
        }

        emit ProviderStaked(msg.sender, _amount);
    }

    /**
     * @notice Allows a provider to withdraw their unlocked stake.
     * @param _amount The amount to withdraw.
     */
    function withdrawProviderStake(uint256 _amount) external nonReentrant nonZeroAmount(_amount) {
        ProviderInfo storage provider = providers[msg.sender];
        require(provider.unlockedStake >= _amount, "Insufficient unlocked stake");

        provider.unlockedStake = provider.unlockedStake.sub(_amount);
        provider.totalStake = provider.totalStake.sub(_amount);

        require(marketplaceToken.transfer(msg.sender, _amount), "Token transfer failed for provider withdrawal");

        emit ProviderStakeWithdrawn(msg.sender, _amount);
    }

    /**
     * @notice Allows a provider to claim their accumulated earnings from active models.
     */
    function claimProviderEarnings() external nonReentrant onlyProvider {
        ProviderInfo storage provider = providers[msg.sender];
        uint256 totalClaimable = 0;

        // Assuming provider earnings are tracked within the ProviderInfo struct or derived
        // For simplicity here, let's assume totalEarned is managed directly on the Model struct
        // and transferred to the provider balance upon successful use/finalization.
        // A more robust system would track a pending balance per provider.

        // Let's add a claimable balance variable to ProviderInfo
        // uint256 claimableEarnings; (Add to ProviderInfo struct)

        // totalClaimable = provider.claimableEarnings; // Assuming this exists
        // require(totalClaimable > 0, "No earnings to claim");
        // provider.claimableEarnings = 0;

        // require(marketplaceToken.transfer(msg.sender, totalClaimable), "Token transfer failed for earnings claim");
        // emit ProviderEarningsClaimed(msg.sender, totalClaimable);

        // --- Simplified implementation: Iterate models and claim finalized earnings ---
        // This requires models to have an unlocked/claimable earnings state.
        // Let's add `uint256 claimableEarnings` to Model struct and update it upon usage.
        // Then iterate models owned by provider. (Requires tracking models per provider)
        // For this version, let's assume earnings are automatically added to totalEarned
        // and provider needs a separate claimable balance.
        // Need a mapping: `mapping(address => uint256) public providerClaimableEarnings;`

        uint256 claimable = providers[msg.sender].totalEarned;
        require(claimable > 0, "No earnings to claim");

        providers[msg.sender].totalEarned = 0; // Reset claimable balance

        require(marketplaceToken.transfer(msg.sender, claimable), "Token transfer failed for earnings claim");
        emit ProviderEarningsClaimed(msg.sender, claimable);
    }

    /**
     * @notice Allows a provider to pause their active model.
     * @param _modelId The ID of the model to pause.
     */
    function pauseOwnModel(uint256 _modelId) external modelExists(_modelId) isModelProvider(_modelId) {
        Model storage model = models[_modelId];
        require(model.status == ModelStatus.Active, "Model is not active and cannot be paused");
        model.status = ModelStatus.Paused;
        emit ModelStatusUpdated(_modelId, ModelStatus.Paused);
    }

    /**
     * @notice Allows a provider to unpause their paused model.
     * @param _modelId The ID of the model to unpause.
     */
    function unpauseOwnModel(uint256 _modelId) external modelExists(_modelId) isModelProvider(_modelId) {
        Model storage model = models[_modelId];
        require(model.status == ModelStatus.Paused, "Model is not paused and cannot be unpaused");
        model.status = ModelStatus.Active;
        emit ModelStatusUpdated(_modelId, ModelStatus.Active);
    }

    /**
     * @notice Get information about a provider.
     * @param _provider Address of the provider.
     * @return ProviderInfo struct.
     */
    function getProviderInfo(address _provider) external view returns (ProviderInfo memory) {
        return providers[_provider];
    }

    /**
     * @notice Get a list of model IDs submitted by a provider.
     * NOTE: This mapping requires iterating all models or maintaining a separate list,
     * which can be gas-intensive. A helper view or off-chain indexing is better for production.
     * This simplified version demonstrates the concept.
     * @param _provider Address of the provider.
     * @return Array of model IDs.
     */
    function getProviderModels(address _provider) external view returns (uint256[] memory) {
        uint256[] memory providerModelIds = new uint256[](modelCounter);
        uint256 count = 0;
        for (uint256 i = 1; i <= modelCounter; i++) {
            if (models[i].provider == _provider) {
                providerModelIds[count] = i;
                count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = providerModelIds[i];
        }
        return result;
    }


    // --- Validator Functions ---

    /**
     * @notice Allows an address to register as a validator.
     * Requires staking minValidatorStake amount of tokens.
     * @param _stakeAmount Amount of tokens to stake (must be >= minValidatorStake).
     */
    function registerAsValidator(uint256 _stakeAmount) external nonReentrant nonZeroAmount(_stakeAmount) {
        require(_stakeAmount >= minValidatorStake, "Stake amount must be at least minValidatorStake");
        require(!validators[msg.sender].isActive, "Validator is already registered");

        require(marketplaceToken.transferFrom(msg.sender, address(this), _stakeAmount), "Token transfer failed for validator stake");

        validators[msg.sender] = ValidatorInfo({
            totalStake: _stakeAmount,
            unlockedStake: _stakeAmount,
            lockedStake: 0,
            reputation: 1, // Basic reputation gain
            isActive: true,
            totalRewards: 0
        });

        emit ValidatorRegistered(msg.sender, _stakeAmount);
    }

    /**
     * @notice Allows a validator to increase their stake.
     * @param _amount The amount of tokens to stake.
     */
    function stakeAsValidator(uint256 _amount) external nonReentrant nonZeroAmount(_amount) {
        require(validators[msg.sender].isActive, "Validator is not registered");
        require(marketplaceToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed for validator stake");

        ValidatorInfo storage validator = validators[msg.sender];
        validator.totalStake = validator.totalStake.add(_amount);
        validator.unlockedStake = validator.unlockedStake.unlockedStake.add(_amount); // New stake is unlocked initially

        emit ValidatorStaked(msg.sender, _amount);
    }

    /**
     * @notice Allows a validator to withdraw their unlocked stake.
     * @param _amount The amount to withdraw.
     */
    function withdrawValidatorStake(uint256 _amount) external nonReentrant nonZeroAmount(_amount) {
        ValidatorInfo storage validator = validators[msg.sender];
        require(validator.unlockedStake >= _amount, "Insufficient unlocked stake");

        validator.unlockedStake = validator.unlockedStake.sub(_amount);
        validator.totalStake = validator.totalStake.sub(_amount);

        // Deactivate if total stake falls below minimum? Or require explicit de-registration.
        // Let's require totalStake >= minValidatorStake to remain active
        if (validator.totalStake < minValidatorStake) {
            validator.isActive = false;
        }

        require(marketplaceToken.transfer(msg.sender, _amount), "Token transfer failed for validator withdrawal");

        emit ValidatorStakeWithdrawn(msg.sender, _amount);
    }

    /**
     * @notice A validator signals their intent to validate a specific submitted model.
     * Locks a portion of the validator's stake.
     * @param _modelId The ID of the model to validate.
     * @param _stakeAmount The amount of validator stake to commit to this validation.
     */
    function selectModelForValidation(uint256 _modelId, uint256 _stakeAmount) external nonReentrant onlyValidator nonZeroAmount(_stakeAmount) modelExists(_modelId) {
        Model storage model = models[_modelId];
        ValidatorInfo storage validator = validators[msg.sender];

        require(model.status == ModelStatus.Submitted, "Model is not in Submitted status");
        require(!model.validationVotes[msg.sender].hasVoted, "Validator has already participated in this validation");
        require(validator.unlockedStake >= _stakeAmount, "Insufficient unlocked validator stake to commit");

        validator.unlockedStake = validator.unlockedStake.sub(_stakeAmount);
        validator.lockedStake = validator.lockedStake.add(_stakeAmount);

        model.validationVotes[msg.sender] = ValidationVote({
            hasVoted: false, // Not voted yet, just selected
            isValid: false, // Placeholder
            proofURI: "", // Placeholder
            stakedAmount: _stakeAmount,
            rewarded: false,
            slashed: false
        });
        model.validators.push(msg.sender); // Add validator to the list for this model

        // Transition model to UnderValidation status if this is the first validator
        if (model.validationStatus == ValidationStatus.Pending) {
             model.status = ModelStatus.UnderValidation;
             model.validationStatus = ValidationStatus.Pending; // Still Pending until votes are cast
             model.validationStartTime = block.timestamp; // Start the timer
             emit ModelStatusUpdated(_modelId, ModelStatus.UnderValidation);
        }

        emit ValidatorSelectedModel(_modelId, msg.sender);
    }


    /**
     * @notice A validator submits their validation result (vote and proof).
     * Can only be done during the validation period after selecting the model.
     * @param _modelId The ID of the model validated.
     * @param _isValid True if the validator found the model valid, false otherwise.
     * @param _proofURI Link to off-chain proof/report.
     */
    function submitValidationResult(uint256 _modelId, bool _isValid, string calldata _proofURI) external nonReentrant onlyValidator modelExists(_modelId) {
        Model storage model = models[_modelId];
        ValidationVote storage vote = model.validationVotes[msg.sender];

        require(model.status == ModelStatus.UnderValidation, "Model is not currently under validation");
        require(vote.stakedAmount > 0 && !vote.hasVoted, "Validator has not selected this model or has already voted");
        require(block.timestamp <= model.validationStartTime.add(validationPeriod), "Validation period has ended");
        require(bytes(_proofURI).length > 0, "Proof URI cannot be empty");

        vote.hasVoted = true;
        vote.isValid = _isValid;
        vote.proofURI = _proofURI;

        if (_isValid) {
            model.votesForValid++;
        } else {
            model.votesForInvalid++;
        }

        // Reputation update logic can be added here (e.g., small positive boost for voting)
        validators[msg.sender].reputation = validators[msg.sender].reputation.add(1);

        emit ValidationResultSubmitted(_modelId, msg.sender, _isValid, _proofURI);
    }

     /**
     * @notice Allows a validator to claim their accumulated rewards.
     */
    function claimValidatorRewards() external nonReentrant onlyValidator {
        // Similar to provider earnings, requires a claimable balance tracking.
        // Need a mapping: `mapping(address => uint256) public validatorClaimableRewards;`

        uint256 claimable = validators[msg.sender].totalRewards;
        require(claimable > 0, "No rewards to claim");

        validators[msg.sender].totalRewards = 0; // Reset claimable balance

        require(marketplaceToken.transfer(msg.sender, claimable), "Token transfer failed for validator rewards");
        emit ValidatorRewardsClaimed(msg.sender, claimable);
    }

    /**
     * @notice Get information about a validator.
     * @param _validator Address of the validator.
     * @return ValidatorInfo struct.
     */
    function getValidatorInfo(address _validator) external view returns (ValidatorInfo memory) {
        return validators[_validator];
    }

    /**
     * @notice Get a specific validator's vote details for a model validation.
     * @param _modelId The model ID.
     * @param _validator Address of the validator.
     * @return ValidationVote struct.
     */
    function getValidationVote(uint256 _modelId, address _validator) external view modelExists(_modelId) returns (ValidationVote memory) {
         return models[_modelId].validationVotes[_validator];
    }

    // --- User Functions ---

    /**
     * @notice Allows a user to deposit tokens into their contract balance for purchasing model access.
     * @param _amount The amount of tokens to deposit.
     */
    function depositForUsage(uint256 _amount) external nonReentrant nonZeroAmount(_amount) {
        require(marketplaceToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed for user deposit");
        // A mapping for user balances is needed: `mapping(address => uint256) public userBalances;`
        // Let's add this to the UserAccess struct, although it's technically a separate balance.
        // Reusing UserAccess struct for overall user state might be confusing.
        // Let's create a separate `userBalances` mapping.
        // `mapping(address => uint256) public userBalances;` (Add as state variable)

        userBalances[msg.sender] = userBalances[msg.sender].add(_amount);

        emit UserDeposited(msg.sender, _amount);
    }

    /**
     * @notice Allows a user to purchase access (inference credits) for an active model.
     * Pays from the user's deposited balance.
     * @param _modelId The ID of the model to purchase access for.
     * @param _numberOfUses The number of inferences to purchase.
     */
    function purchaseModelAccess(uint256 _modelId, uint256 _numberOfUses) external nonReentrant nonZeroAmount(_numberOfUses) isActiveModel(_modelId) {
        Model storage model = models[_modelId];
        uint256 totalCost = model.inferenceCost.mul(_numberOfUses);

        // Check user's deposited balance
        require(userBalances[msg.sender] >= totalCost, "Insufficient deposited balance");

        // Deduct from user balance
        userBalances[msg.sender] = userBalances[msg.sender].sub(totalCost);

        // Grant access credits
        UserAccess storage access = userModelAccess[msg.sender][_modelId];
        access.remainingUses = access.remainingUses.add(_numberOfUses);
        access.lastUsageTimestamp = block.timestamp; // Or timestamp of purchase? Let's use purchase.

        // Add cost to model's accumulated earnings (before fee)
        // Model earnings will be distributed to provider + marketplace after finalization.
        // Need a mechanism to track pending earnings for each model/provider until finalization.
        // Let's simplify: earnings go directly to provider's claimable balance and marketplace's balance.
        // This implies model.inferenceCost is the *gross* cost.

        uint256 marketplaceFee = totalCost.mul(marketplaceFeeBps).div(10000);
        uint256 providerShare = totalCost.sub(marketplaceFee);

        // Add shares to respective claimable balances
        providers[model.provider].totalEarned = providers[model.provider].totalEarned.add(providerShare);
        // Need a marketplace treasury balance: `uint256 public marketplaceTreasury;`
        marketplaceTreasury = marketplaceTreasury.add(marketplaceFee);

        emit UserModelAccessPurchased(msg.sender, _modelId, _numberOfUses, totalCost);
    }

    /**
     * @notice User (or an off-chain service on their behalf) signals one inference credit has been used.
     * Decrements remaining usage credits.
     * @param _modelId The ID of the model that was used.
     */
    function logModelUsage(uint256 _modelId) external modelExists(_modelId) {
        // Note: This function logs *that* a use happened based on purchased access.
        // It doesn't verify the actual off-chain computation result.
        // More advanced versions would require proof-of-computation.

        UserAccess storage access = userModelAccess[msg.sender][_modelId];
        require(access.remainingUses > 0, "No usage credits available for this model");
        isActiveModel(_modelId); // Ensure model is active

        access.remainingUses = access.remainingUses.sub(1);
        access.lastUsageTimestamp = block.timestamp;

        // Update model total uses count
        models[_modelId].totalUses++;

        emit ModelUsageLogged(msg.sender, _modelId, access.remainingUses);
    }

    /**
     * @notice Allows a user to rate a model after using it.
     * Simple average rating calculation.
     * @param _modelId The ID of the model to rate.
     * @param _rating The rating (e.g., 1 to 5).
     */
    function submitModelRating(uint256 _modelId, uint8 _rating) external modelExists(_modelId) {
        require(_rating > 0 && _rating <= 5, "Rating must be between 1 and 5");
        UserAccess storage access = userModelAccess[msg.sender][_modelId];
        // Require user to have purchased access at some point
        require(access.remainingUses > 0 || models[_modelId].totalUses > userModelAccess[msg.sender][_modelId].remainingUses, "User must have used the model to rate");
         // Basic check: user has used the model at least once more than their remaining credits
        // A better check would be to track if a user has rated a specific model before.
        // Or track usage count per user per model separately.
        // For simplicity, we just check if they have/had credits.

        Model storage model = models[_modelId];
        model.ratingSum = model.ratingSum.add(_rating);
        model.numberOfRatings++;

        // Update provider reputation based on rating?
        providers[model.provider].reputation = providers[model.provider].reputation.add(_rating); // Basic gain

        emit ModelRated(msg.sender, _modelId, _rating);
    }

    /**
     * @notice Allows a user to withdraw their remaining deposited tokens.
     * @param _amount The amount to withdraw.
     */
    function withdrawUserFunds(uint256 _amount) external nonReentrant nonZeroAmount(_amount) {
         require(userBalances[msg.sender] >= _amount, "Insufficient deposited balance");

        userBalances[msg.sender] = userBalances[msg.sender].sub(_amount);

        require(marketplaceToken.transfer(msg.sender, _amount), "Token transfer failed for user withdrawal");
        emit UserFundsWithdrawn(msg.sender, _amount);
    }

     /**
     * @notice Get the remaining usage permissions for a user on a specific model.
     * @param _user Address of the user.
     * @param _modelId The model ID.
     * @return Remaining usage credits.
     */
    function getUserAccessPermissions(address _user, uint256 _modelId) external view modelExists(_modelId) returns (uint256 remainingUses) {
        return userModelAccess[_user][_modelId].remainingUses;
    }


    // --- Marketplace/Admin Functions ---

    /**
     * @notice Finalizes the validation process for a model after the validation period ends.
     * Determines if the model is Active or Rejected based on validator votes.
     * Handles rewards/slashing for validators and unlocks provider stake.
     * Anyone can call this after the validation period.
     * @param _modelId The ID of the model to finalize validation for.
     */
    function finalizeModelValidation(uint256 _modelId) external nonReentrant modelExists(_modelId) {
        Model storage model = models[_modelId];
        require(model.status == ModelStatus.UnderValidation, "Model is not under validation");
        require(block.timestamp > model.validationStartTime.add(validationPeriod), "Validation period has not ended yet");
        require(model.validators.length >= requiredValidators, "Not enough validators have selected this model"); // Ensure minimum participation

        // Determine outcome based on majority vote
        ValidationStatus finalValidationStatus;
        uint256 totalVotesCast = model.votesForValid.add(model.votesForInvalid);
        uint256 rewardPool = model.providerStake.div(2); // Example: 50% of provider stake goes to validators
        uint256 slashAmountPerInvalidVote = 0; // Example: Slashing logic can be complex

        if (totalVotesCast == 0) {
             // Should not happen if requiredValidators > 0 and period ended, but as a safeguard
             finalValidationStatus = ValidationStatus.Pending; // Cannot finalize without votes
             // Keep status as UnderValidation, perhaps allow extending period or cancellation by owner
        } else if (model.votesForValid > model.votesForInvalid) {
            // Model validated as valid
            finalValidationStatus = ValidationStatus.Validated;
            model.status = ModelStatus.Active;
            model.unlockedStakeTimestamp = block.timestamp; // Provider stake unlocked immediately (or after delay?)
            // Reward validators who voted "valid"
            uint256 validVoterCount = model.votesForValid;
            if (validVoterCount > 0) {
                uint256 rewardPerValidator = rewardPool.div(validVoterCount);
                 for (uint256 i = 0; i < model.validators.length; i++) {
                    address validatorAddress = model.validators[i];
                    ValidationVote storage vote = model.validationVotes[validatorAddress];
                     if (vote.hasVoted && vote.isValid && !vote.rewarded) {
                        // Add reward to validator's claimable balance
                        validators[validatorAddress].totalRewards = validators[validatorAddress].totalRewards.add(rewardPerValidator);
                        validators[validatorAddress].reputation = validators[validatorAddress].reputation.add(10); // Reputation boost
                        // Unlock validator's stake for this vote
                         validators[validatorAddress].lockedStake = validators[validatorAddress].lockedStake.sub(vote.stakedAmount);
                         validators[validatorAddress].unlockedStake = validators[validatorAddress].unlockedStake.add(vote.stakedAmount);
                        vote.rewarded = true;
                     } else if (vote.hasVoted && !vote.isValid && !vote.slashed) {
                         // Slash validators who voted "invalid" against consensus
                         // Example slashing: slash a percentage of their staked amount for this vote
                         // uint256 slashAmount = vote.stakedAmount.div(4); // Example: 25% slash
                         // validators[validatorAddress].totalStake = validators[validatorAddress].totalStake.sub(slashAmount);
                         // validators[validatorAddress].lockedStake = validators[validatorAddress].lockedStake.sub(slashAmount); // The rest is unlocked

                         // For simplicity, let's just penalize reputation and unlock stake
                         validators[validatorAddress].reputation = validators[validatorAddress].reputation.sub(5); // Reputation penalty
                         validators[validatorAddress].lockedStake = validators[validatorAddress].lockedStake.sub(vote.stakedAmount);
                         validators[validatorAddress].unlockedStake = validators[validatorAddress].unlockedStake.add(vote.stakedAmount);
                         vote.slashed = true; // Mark as processed
                     } else if (vote.stakedAmount > 0 && !vote.hasVoted) {
                         // Validator selected but didn't vote
                         // Penalize reputation and unlock stake
                         validators[validatorAddress].reputation = validators[validatorAddress].reputation.sub(2);
                         validators[validatorAddress].lockedStake = validators[validatorAddress].lockedStake.sub(vote.stakedAmount);
                         validators[validatorAddress].unlockedStake = validators[validatorAddress].unlockedStake.add(vote.stakedAmount);
                     }
                 }
            }
        } else { // model.votesForInvalid >= model.votesForValid (or tie, treat as rejected)
            // Model rejected by validators
            finalValidationStatus = ValidationStatus.RejectedByValidators;
            model.status = ModelStatus.Rejected;
            model.unlockedStakeTimestamp = block.timestamp; // Provider stake unlocked immediately (or after dispute period?)
            // Slash provider stake? Example: slash 50% of provider stake
            // uint256 providerSlash = model.providerStake.div(2);
            // providers[model.provider].totalStake = providers[model.provider].totalStake.sub(providerSlash);
            // providers[model.provider].lockedStake = providers[model.provider].lockedStake.sub(model.providerStake); // Subtract full locked stake first
            // providers[model.provider].unlockedStake = providers[model.provider].unlockedStake.add(model.providerStake.sub(providerSlash)); // Add remaining as unlocked
             // For simplicity, just unlock stake and maybe reputation penalty
            providers[model.provider].reputation = providers[model.provider].reputation.sub(20); // Significant reputation penalty

             // Reward validators who voted "invalid"
            uint256 invalidVoterCount = model.votesForInvalid;
            if (invalidVoterCount > 0) {
                uint256 rewardPerValidator = rewardPool.div(invalidVoterCount); // Reward pool for correct votes
                for (uint256 i = 0; i < model.validators.length; i++) {
                    address validatorAddress = model.validators[i];
                    ValidationVote storage vote = model.validationVotes[validatorAddress];
                     if (vote.hasVoted && !vote.isValid && !vote.rewarded) {
                         validators[validatorAddress].totalRewards = validators[validatorAddress].totalRewards.add(rewardPerValidator);
                         validators[validatorAddress].reputation = validators[validatorAddress].reputation.add(10); // Reputation boost
                          validators[validatorAddress].lockedStake = validators[validatorAddress].lockedStake.sub(vote.stakedAmount);
                         validators[validatorAddress].unlockedStake = validators[validatorAddress].unlockedStake.add(vote.stakedAmount);
                        vote.rewarded = true;
                     } else if (vote.hasVoted && vote.isValid && !vote.slashed) {
                         // Slash validators who voted "valid" against consensus
                         // Example slashing: 25% slash
                         // uint256 slashAmount = vote.stakedAmount.div(4);
                         // validators[validatorAddress].totalStake = validators[validatorAddress].totalStake.sub(slashAmount);
                         // validators[validatorAddress].lockedStake = validators[validatorAddress].lockedStake.sub(vote.stakedAmount);
                         // validators[validatorAddress].unlockedStake = validators[validatorAddress].unlockedStake.add(vote.stakedAmount.sub(slashAmount));

                         // For simplicity, just penalize reputation and unlock stake
                         validators[validatorAddress].reputation = validators[validatorAddress].reputation.sub(5);
                         validators[validatorAddress].lockedStake = validators[validatorAddress].lockedStake.sub(vote.stakedAmount);
                         validators[validatorAddress].unlockedStake = validators[validatorAddress].unlockedStake.add(vote.stakedAmount);
                         vote.slashed = true;
                     } else if (vote.stakedAmount > 0 && !vote.hasVoted) {
                          // Validator selected but didn't vote
                         validators[validatorAddress].reputation = validators[validatorAddress].reputation.sub(2);
                         validators[validatorAddress].lockedStake = validators[validatorAddress].lockedStake.sub(vote.stakedAmount);
                         validators[validatorAddress].unlockedStake = validators[validatorAddress].unlockedStake.add(vote.stakedAmount);
                     }
                }
            }
        }

        model.validationStatus = finalValidationStatus;
        model.unlockedStakeTimestamp = block.timestamp; // Provider stake unlocked now (can be claimed later)
        providers[model.provider].lockedStake = providers[model.provider].lockedStake.sub(model.providerStake);
        providers[model.provider].unlockedStake = providers[model.provider].unlockedStake.add(model.providerStake); // Full stake unlocked

        emit ModelValidationFinalized(_modelId, finalValidationStatus, rewardPool, slashAmountPerInvalidVote); // SlashAmount is just example param
        emit ModelStatusUpdated(_modelId, model.status);
    }

     /**
     * @notice Allows a user to report a faulty model. Initiates a dispute.
     * Requires purchasing access to the model.
     * @param _modelId The ID of the model being reported.
     * @param _reason Description of why the model is faulty.
     */
    function reportFaultyModel(uint256 _modelId, string calldata _reason) external nonReentrant modelExists(_modelId) {
        // Check if user has purchased access to this model at least once
        require(userModelAccess[msg.sender][_modelId].lastUsageTimestamp > 0, "User must have purchased access to report a model");
        Model storage model = models[_modelId];
        require(model.status != ModelStatus.ReportedForDispute, "Model is already reported");
        require(bytes(_reason).length > 0, "Reason cannot be empty");

        disputeCounter++;
        uint256 disputeId = disputeCounter;

        disputes[disputeId] = Dispute({
            subjectId: _modelId, // Model ID as subject
            disputeType: DisputeType.FaultyModel,
            reporter: msg.sender,
            reason: _reason,
            reportTimestamp: block.timestamp,
            status: DisputeStatus.Unresolved
        });

        model.status = ModelStatus.ReportedForDispute;
        model.disputeId = disputeId;

        emit DisputeReported(disputeId, DisputeType.FaultyModel, _modelId, msg.sender, _reason);
        emit ModelStatusUpdated(_modelId, ModelStatus.ReportedForDispute);
    }

    /**
     * @notice Allows a provider or user to report a potentially malicious validator. Initiates a dispute.
     * Requires having interacted with the validator (e.g., used a model validated by them, or provider of a model validated by them).
     * @param _validatorAddress The address of the validator being reported.
     * @param _reason Description of the alleged malicious behavior.
     */
     function reportMaliciousValidator(address _validatorAddress, string calldata _reason) external nonReentrant {
         require(_validatorAddress != msg.sender, "Cannot report yourself");
         require(validators[_validatorAddress].totalStake > 0, "Address is not a validator");
         require(bytes(_reason).length > 0, "Reason cannot be empty");

         // Add checks requiring reporter interaction with validator's activities
         // e.g., msg.sender used a model validated by _validatorAddress, or msg.sender's model was validated by _validatorAddress

         disputeCounter++;
        uint256 disputeId = disputeCounter;

        // Pack address into uint256 for subjectId
        uint256 subjectIdPacked = uint256(uint160(_validatorAddress));

         disputes[disputeId] = Dispute({
            subjectId: subjectIdPacked, // Validator address as subject (packed)
            disputeType: DisputeType.MaliciousValidator,
            reporter: msg.sender,
            reason: _reason,
            reportTimestamp: block.timestamp,
            status: DisputeStatus.Unresolved
        });

         // Could add a status to ValidatorInfo like `ReportedForDispute`

        emit DisputeReported(disputeId, DisputeType.MaliciousValidator, subjectIdPacked, msg.sender, _reason);
     }


    /**
     * @notice Resolves a dispute. This is a placeholder for complex logic (e.g., governance vote, oracle).
     * Only the owner can call this in this basic implementation.
     * @param _disputeId The ID of the dispute to resolve.
     * @param _result The outcome of the dispute (ResolvedValid or ResolvedInvalid relative to the report).
     */
    function resolveDispute(uint256 _disputeId, DisputeResult _result) external onlyOwner nonReentrant {
        require(_disputeId > 0 && _disputeId <= disputeCounter, "Dispute does not exist");
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.status == DisputeStatus.Unresolved, "Dispute is already resolved");
        require(_result == DisputeResult.ResolvedValid || _result == DisputeResult.ResolvedInvalid, "Invalid dispute result");

        dispute.status = _result;

        if (dispute.disputeType == DisputeType.FaultyModel) {
            uint256 modelId = dispute.subjectId;
            Model storage model = models[modelId];
             require(model.status == ModelStatus.ReportedForDispute, "Model status mismatch for dispute");

            if (_result == DisputeResult.ResolvedInvalid) { // Report was valid -> Model is faulty
                model.status = ModelStatus.Rejected;
                // Slash provider stake, potentially refund users who purchased access, etc.
                // Complex logic omitted for brevity. Example: slash 50% provider stake, refund users their purchase cost for this model.
                // providers[model.provider].lockedStake -= slashAmount; providers[model.provider].unlockedStake += remainingStake;
                // Need to iterate users who bought access to this model and refund. Requires tracking this data.
                // For simplicity, just update status and reputation.
                 providers[model.provider].reputation = providers[model.provider].reputation.sub(30); // Significant penalty
            } else { // Report was invalid -> Model is not faulty (or report was unfounded)
                model.status = ModelStatus.Active; // Or return to its previous state? Let's set Active if it was active.
                 // Reward reporter for honest report? Penalize for false report?
                 // Example: Penalize reporter reputation
                 // providers[dispute.reporter].reputation -= 5; // If reporter is provider
                 // validators[dispute.reporter].reputation -= 5; // If reporter is validator
                 // (Reputation for users is not explicitly tracked, could add it)
            }
            model.disputeId = 0; // Clear dispute ID
             emit ModelStatusUpdated(modelId, model.status);

        } else if (dispute.disputeType == DisputeType.MaliciousValidator) {
            address validatorAddress = address(uint160(dispute.subjectId));
            ValidatorInfo storage validator = validators[validatorAddress];

            if (_result == DisputeResult.ResolvedInvalid) { // Report was valid -> Validator was malicious
                validator.isActive = false; // Deactivate validator
                // Slash validator stake, potentially reward reporter.
                // Example: slash 100% of validator's locked stake, penalize reputation.
                // uint256 slashedAmount = validator.lockedStake;
                // validator.totalStake -= slashedAmount;
                // validator.lockedStake = 0;
                 validator.reputation = validator.reputation.sub(50); // Severe penalty
            } else { // Report was invalid -> Validator was not malicious
                 // Penalize reporter reputation/stake.
                 // Example: providers[dispute.reporter].reputation -= 10;
                 validator.reputation = validator.reputation.add(10); // Small boost for being cleared
            }
             // Need to unlock any stake the validator had locked on active validations/disputes if they were deactivated.
             // This requires tracking which validations/disputes a validator is involved in.
        }

        emit DisputeResolved(_disputeId, _result);
    }

    /**
     * @notice Owner sets the marketplace fee percentage.
     * @param _marketplaceFeeBps Fee in basis points (1/10000).
     */
    function setMarketplaceFee(uint256 _marketplaceFeeBps) external onlyOwner {
        require(_marketplaceFeeBps <= 10000, "Fee cannot exceed 100%");
        marketplaceFeeBps = _marketplaceFeeBps;
        emit MarketplaceFeeUpdated(marketplaceFeeBps);
    }

    /**
     * @notice Owner sets the minimum staking amounts for providers and validators.
     * @param _minProviderStake Minimum stake for providers.
     * @param _minValidatorStake Minimum stake for validators.
     */
    function setMinStakes(uint256 _minProviderStake, uint256 _minValidatorStake) external onlyOwner {
        minProviderStake = _minProviderStake;
        minValidatorStake = _minValidatorStake;
        emit MinStakesUpdated(minProviderStake, minValidatorStake);
    }

    /**
     * @notice Owner sets the duration of the model validation period.
     * @param _periodInSeconds Duration in seconds.
     */
    function setValidationPeriod(uint256 _periodInSeconds) external onlyOwner {
        require(_periodInSeconds > 0, "Validation period must be greater than 0");
        validationPeriod = _periodInSeconds;
        emit ValidationPeriodUpdated(validationPeriod);
    }

    /**
     * @notice Owner sets the minimum number of validators required to attempt validation finalization.
     * @param _count Minimum number of validators.
     */
    function setRequiredValidators(uint256 _count) external onlyOwner {
        require(_count > 0, "Required validators must be greater than 0");
        requiredValidators = _count;
        emit RequiredValidatorsUpdated(requiredValidators);
    }

    /**
     * @notice Get various configuration parameters of the marketplace.
     * @return A tuple containing fee, min stakes, validation period, required validators, and treasury balance.
     */
    function getMarketplaceState() external view returns (uint256 feeBps, uint256 minProvStake, uint256 minValStake, uint256 valPeriod, uint256 reqVals, uint256 treasury) {
        return (marketplaceFeeBps, minProviderStake, minValidatorStake, validationPeriod, requiredValidators, marketplaceTreasury);
    }

     /**
     * @notice Get details for a specific model.
     * @param _modelId The ID of the model.
     * @return Model struct details (excluding mappings for gas efficiency).
     */
    function getModelDetails(uint256 _modelId) external view modelExists(_modelId) returns (
        address provider,
        string memory metadataURI,
        uint256 inferenceCost,
        uint256 providerStake,
        ModelStatus status,
        ValidationStatus validationStatus,
        uint256 submissionTimestamp,
        uint256 validationStartTime,
        uint256 votesForValid,
        uint256 votesForInvalid,
        uint256 totalUses,
        uint256 ratingSum,
        uint256 numberOfRatings,
        uint256 disputeId,
        uint256 unlockedStakeTimestamp,
        uint256 totalEarned,
        address[] memory validatorsList
    ) {
        Model storage model = models[_modelId];
        return (
            model.provider,
            model.metadataURI,
            model.inferenceCost,
            model.providerStake,
            model.status,
            model.validationStatus,
            model.submissionTimestamp,
            model.validationStartTime,
            model.votesForValid,
            model.votesForInvalid,
            model.totalUses,
            model.ratingSum,
            model.numberOfRatings,
            model.disputeId,
            model.unlockedStakeTimestamp,
            model.totalEarned,
            model.validators // Return the list of validators who selected/voted
        );
    }

     /**
     * @notice Get a list of model IDs filtered by status.
     * NOTE: Similar to getProviderModels, iterating all models is gas-intensive for large numbers.
     * Off-chain indexing is better. This is for demonstration.
     * @param _status The ModelStatus to filter by.
     * @return Array of model IDs matching the status.
     */
    function getModelsByStatus(ModelStatus _status) external view returns (uint256[] memory) {
        uint256[] memory filteredModelIds = new uint256[](modelCounter);
        uint256 count = 0;
        for (uint256 i = 1; i <= modelCounter; i++) {
            if (models[i].status == _status) {
                filteredModelIds[count] = i;
                count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = filteredModelIds[i];
        }
        return result;
    }

    // Internal mapping for user balances
    mapping(address => uint256) public userBalances;
    // Internal variable for marketplace treasury balance
    uint256 public marketplaceTreasury;


    // Fallback and Receive functions to handle Ether (if needed),
    // but we are using an ERC20 token here, so they are not strictly necessary
    // unless the contract needs to receive native currency for some reason.

    // receive() external payable {
    //     // Optional: handle receiving native currency if needed
    // }

    // fallback() external payable {
    //     // Optional: handle receiving native currency if needed
    // }
}
```