Okay, here is a smart contract based on the concept of a **Decentralized AI Model Marketplace with Verifiable Computation Hooks and Subscription Models**.

This contract acts as the *on-chain coordination layer*. It manages registration, model listing, access control (purchase, subscription), validator staking/slashing, and hooks for off-chain validation results and usage tracking. The actual AI inference and complex validation computation would happen *off-chain*, with results or proofs potentially submitted back to the contract for state updates (like validation status or triggering slashing/rewards).

It incorporates concepts like role-based access, staking, slashing, subscription logic, state transitions, and hooks for external verification/usage reporting, aiming for complexity beyond basic token transfers or simple NFTs.

**Key Advanced/Trendy Concepts Used:**

1.  **Decentralized Marketplace:** Facilitates exchange without a central authority.
2.  **AI/ML Focus:** Specifically designed for trading access to AI models.
3.  **Role-Based System:** Distinct roles for Owner, Creators, Validators, and Users.
4.  **Staking & Slashing:** Validators stake collateral and can be slashed for misbehavior (triggering on-chain state change based on off-chain arbitration/proofs).
5.  **Subscription Models:** Allows for recurring access payments (simplified model, actual payment needs off-chain cron or pull mechanism).
6.  **Verifiable Computation Hooks:** Functions designed to integrate with off-chain validation processes, allowing on-chain recording of verification results or challenges.
7.  **Usage Tracking Hooks:** Functions to report usage (like per-inference calls) for flexible pricing models.
8.  **Reputation (Basic):** Allowing users to rate models.
9.  **Pausability:** For emergency situations.
10. **Fee Collection:** Marketplace charges a fee on transactions.

**Outline:**

1.  **State Variables:** Define core contract state.
2.  **Structs:** Define data structures for Users, Creators, Validators, Models, Subscriptions.
3.  **Enums:** Define relevant states or types.
4.  **Events:** Define events to log important actions.
5.  **Modifiers:** Define access control and state-checking modifiers.
6.  **Core Logic:**
    *   Admin/Owner Functions
    *   User Management Functions
    *   Creator Management Functions
    *   Validator Management Functions (including staking/slashing)
    *   Model Management Functions
    *   Access & Subscription Functions
    *   Validation & Reporting Hooks
    *   Reputation Functions
    *   Utility/View Functions

**Function Summary (26 Functions):**

*   **Admin/Owner (5 functions):**
    *   `constructor`: Initializes the contract owner and fee.
    *   `setFeePercentage`: Sets the marketplace fee percentage.
    *   `withdrawFees`: Allows the owner to withdraw collected fees.
    *   `pauseMarketplace`: Pauses sensitive contract operations.
    *   `unpauseMarketplace`: Resumes contract operations.
*   **User Management (2 functions):**
    *   `registerUser`: Allows an address to register as a user (for rating, tracking).
    *   `getUserProfile`: Retrieves a user's profile details.
*   **Creator Management (3 functions):**
    *   `registerCreator`: Allows a user to register as a creator.
    *   `updateCreatorProfile`: Allows a creator to update their profile details.
    *   `getCreatorProfile`: Retrieves a creator's profile details.
*   **Validator Management (5 functions):**
    *   `registerValidator`: Allows a user to register as a validator, requiring a stake.
    *   `stakeValidator`: Allows a validator to add more stake.
    *   `unstakeValidator`: Allows a validator to request unstaking (with cooldown).
    *   `getValidatorProfile`: Retrieves a validator's profile details.
    *   `slashValidator`: Allows owner/governance to slash a validator's stake based on off-chain findings.
*   **Model Management (5 functions):**
    *   `listModel`: Allows a creator to list a new AI model.
    *   `updateModelDetails`: Allows a creator to update non-price model details.
    *   `updateModelPrice`: Allows a creator to update the model's price.
    *   `delistModel`: Allows a creator to delist a model.
    *   `getModelDetails`: Retrieves a model's details.
*   **Access & Subscription (3 functions):**
    *   `purchaseModelAccess`: Allows a user to purchase one-time access to a model.
    *   `createSubscription`: Allows a user to create a recurring subscription to a model.
    *   `cancelSubscription`: Allows a user to cancel an active subscription.
*   **Validation & Reporting Hooks (2 functions):**
    *   `submitValidationResult`: Allows a validator to submit an off-chain validation result hash for a model.
    *   `reportInferenceUsage`: Hook for off-chain services to report model usage (for pay-per-inference models, not fully implemented pay logic).
*   **Reputation (1 function):**
    *   `submitModelRating`: Allows a user to submit a rating for a model.
*   **Utility/View (many implicitly exist via public state variables and get* functions, but let's add one explicit):**
    *   `checkAccessStatus`: Checks if a user has active access (purchase or subscription) to a model.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DecentralizedAIModelMarketplace
 * @dev A decentralized marketplace for AI models with roles, staking, subscriptions, and verification hooks.
 * This contract manages the on-chain state and logic for model listing, access control,
 * validator participation, and recording validation/usage data.
 * Actual AI inference and complex validation computation happen off-chain.
 */

// Outline:
// 1. State Variables
// 2. Structs
// 3. Enums
// 4. Events
// 5. Modifiers
// 6. Core Logic
//    - Admin/Owner
//    - User Management
//    - Creator Management
//    - Validator Management (Staking, Slashing)
//    - Model Management
//    - Access & Subscription
//    - Validation & Reporting Hooks
//    - Reputation
//    - Utility/View

// Function Summary (26 Functions):
// Admin/Owner:
// constructor(uint256 initialFeePercentage) - Initializes contract, owner, fee.
// setFeePercentage(uint256 newFeePercentage) - Sets the marketplace fee.
// withdrawFees() - Allows owner to withdraw accumulated fees.
// pauseMarketplace() - Pauses core marketplace operations.
// unpauseMarketplace() - Unpauses marketplace operations.

// User Management:
// registerUser() - Registers the caller as a marketplace user.
// getUserProfile(address userAddress) view - Retrieves user profile.

// Creator Management:
// registerCreator(string memory name, string memory profileURI) - Registers the caller as a creator.
// updateCreatorProfile(string memory name, string memory profileURI) - Updates creator profile.
// getCreatorProfile(address creatorAddress) view - Retrieves creator profile.

// Validator Management:
// registerValidator(string memory name, string memory profileURI) payable - Registers caller as validator with stake.
// stakeValidator() payable - Adds stake for a validator.
// unstakeValidator(uint256 amount) - Requests unstake for a validator (with cooldown assumption).
// getValidatorProfile(address validatorAddress) view - Retrieves validator profile.
// slashValidator(address validatorAddress, uint256 slashAmount, string memory reasonURI) - Slashes validator stake.

// Model Management:
// listModel(string memory name, string memory descriptionURI, address creatorAddress, uint256 price, uint256 subscriptionDuration, uint256 validatorStakeRequirement, bytes32 expectedInputHash, bytes32 expectedOutputHash) - Lists a new model.
// updateModelDetails(uint256 modelId, string memory descriptionURI, bytes32 expectedInputHash, bytes32 expectedOutputHash) - Updates model non-price details.
// updateModelPrice(uint256 modelId, uint256 newPrice, uint256 newSubscriptionDuration) - Updates model pricing.
// delistModel(uint256 modelId) - Delists a model.
// getModelDetails(uint256 modelId) view - Retrieves model details.

// Access & Subscription:
// purchaseModelAccess(uint256 modelId) payable - Purchases one-time access.
// createSubscription(uint256 modelId) payable - Creates/renews subscription.
// cancelSubscription(uint256 modelId) - Cancels active subscription.

// Validation & Reporting Hooks:
// submitValidationResult(uint256 modelId, bytes32 validationResultHash, uint256 validatorStakeAtSubmission) - Submits off-chain validation hash.
// reportInferenceUsage(uint256 modelId, address userAddress, uint256 usageUnits) - Hook for reporting model usage.

// Reputation:
// submitModelRating(uint256 modelId, uint8 rating) - Submits a rating for a model (1-5).

// Utility/View:
// checkAccessStatus(address userAddress, uint256 modelId) view - Checks if user has active access.


contract DecentralizedAIModelMarketplace {

    // --- 1. State Variables ---

    address payable public owner;
    uint256 public feePercentage; // Percentage of revenue taken by the marketplace (e.g., 5 = 5%)
    uint256 public totalFeesCollected;

    bool public paused = false;

    uint256 private nextModelId = 1;

    // --- 2. Structs ---

    struct User {
        bool isRegistered;
        // Future: reputation score, settings, etc.
    }

    struct Creator {
        bool isRegistered;
        string name;
        string profileURI; // Link to off-chain profile/details
        address payable wallet; // Address for receiving payouts
    }

    struct Validator {
        bool isRegistered;
        string name;
        string profileURI; // Link to off-chain profile/details
        uint256 stakedAmount;
        uint256 unstakeCooldownEnds; // Timestamp when unstake is available after request
        // Future: performance metrics, slashing history
    }

    struct Model {
        uint256 id;
        string name;
        string descriptionURI; // Link to off-chain details/format
        address creatorAddress;
        uint256 price; // Price for one-time access in wei
        uint256 subscriptionDuration; // Duration of subscription in seconds (0 if not available)
        uint256 validatorStakeRequirement; // Minimum stake required to validate this model type
        bytes32 expectedInputHash; // Hash representing expected input data structure/format
        bytes32 expectedOutputHash; // Hash representing expected output data structure/format
        bool isListed; // Whether the model is currently active and available
        // For validation:
        bytes32 latestValidationResultHash; // Hash of the latest submitted validation result
        uint256 lastValidatedTimestamp;
        // For rating:
        uint256 totalRatings;
        uint256 sumOfRatings; // Sum of (rating * 10) to handle uint8
    }

    struct UserAccess {
        bool hasOneTimeAccess;
        uint256 subscriptionEnds; // Timestamp when current subscription expires (0 if none active)
        // Future: usage tracking specific to access instance
    }

    // --- 3. Enums ---

    enum ValidationStatus {
        Unknown,
        PendingValidation, // Model needs validation
        Validated,         // Model passed latest validation
        Challenged,        // Latest validation result is challenged
        FailedValidation   // Model failed validation / validator slashed
    }

    // --- 4. Events ---

    event FeePercentageUpdated(uint256 oldFeePercentage, uint256 newFeePercentage);
    event FeesWithdrawn(address indexed receiver, uint256 amount);
    event Paused(address account);
    event Unpaused(address account);

    event UserRegistered(address indexed userAddress);
    event CreatorRegistered(address indexed creatorAddress, string name);
    event CreatorProfileUpdated(address indexed creatorAddress, string name, string profileURI);
    event ValidatorRegistered(address indexed validatorAddress, string name, uint256 stakedAmount);
    event ValidatorStaked(address indexed validatorAddress, uint256 addedAmount, uint256 newTotalStake);
    event ValidatorUnstakeRequested(address indexed validatorAddress, uint256 amount, uint256 cooldownEnds);
    event ValidatorUnstaked(address indexed validatorAddress, uint256 amount, uint256 newTotalStake);
    event ValidatorSlashed(address indexed validatorAddress, uint256 slashAmount, string reasonURI);

    event ModelListed(uint256 indexed modelId, address indexed creatorAddress, string name, uint256 price);
    event ModelDetailsUpdated(uint256 indexed modelId, string descriptionURI, bytes32 expectedInputHash, bytes32 expectedOutputHash);
    event ModelPriceUpdated(uint256 indexed modelId, uint256 newPrice, uint256 newSubscriptionDuration);
    event ModelDelisted(uint256 indexed modelId, address indexed creatorAddress);

    event AccessPurchased(uint256 indexed modelId, address indexed userAddress, uint256 amountPaid);
    event SubscriptionCreated(uint256 indexed modelId, address indexed userAddress, uint256 amountPaid, uint256 duration);
    event SubscriptionCancelled(uint256 indexed modelId, address indexed userAddress);

    event ValidationResultSubmitted(uint256 indexed modelId, address indexed validatorAddress, bytes32 validationResultHash);
    event InferenceUsageReported(uint256 indexed modelId, address indexed userAddress, uint256 usageUnits);
    event ModelRatingSubmitted(uint256 indexed modelId, address indexed userAddress, uint8 rating);

    // --- 5. Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyRegisteredUser() {
        require(users[msg.sender].isRegistered, "Caller must be a registered user");
        _;
    }

    modifier onlyRegisteredCreator() {
        require(creators[msg.sender].isRegistered, "Caller must be a registered creator");
        _;
    }

    modifier onlyRegisteredValidator() {
        require(validators[msg.sender].isRegistered, "Caller must be a registered validator");
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

    modifier isModelListed(uint256 modelId) {
        require(models[modelId].isListed, "Model is not listed");
        _;
    }

    // --- Mappings ---

    mapping(address => User) public users;
    mapping(address => Creator) public creators;
    mapping(address => Validator) public validators;
    mapping(uint256 => Model) public models;
    mapping(address => mapping(uint256 => UserAccess)) public userAccess; // userAddress => modelId => UserAccess

    // --- 6. Core Logic ---

    // Admin/Owner Functions

    constructor(uint256 initialFeePercentage) {
        require(initialFeePercentage <= 1000, "Fee percentage cannot exceed 10%"); // Max 10% (1000 / 100)
        owner = payable(msg.sender);
        feePercentage = initialFeePercentage; // e.g., 50 for 5%
    }

    /**
     * @dev Sets the fee percentage for the marketplace.
     * @param newFeePercentage The new fee percentage (scaled by 100, e.g., 500 for 5%).
     */
    function setFeePercentage(uint256 newFeePercentage) external onlyOwner whenNotPaused {
        require(newFeePercentage <= 1000, "Fee percentage cannot exceed 10%");
        emit FeePercentageUpdated(feePercentage, newFeePercentage);
        feePercentage = newFeePercentage;
    }

    /**
     * @dev Allows the owner to withdraw accumulated fees.
     */
    function withdrawFees() external onlyOwner {
        uint256 amount = totalFeesCollected;
        totalFeesCollected = 0;
        require(amount > 0, "No fees to withdraw");
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Fee withdrawal failed");
        emit FeesWithdrawn(owner, amount);
    }

    /**
     * @dev Pauses core marketplace functions.
     */
    function pauseMarketplace() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses core marketplace functions.
     */
    function unpauseMarketplace() external onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    // User Management Functions

    /**
     * @dev Registers the caller as a user. Required for submitting ratings or other user-specific actions.
     */
    function registerUser() external whenNotPaused {
        require(!users[msg.sender].isRegistered, "Already a registered user");
        users[msg.sender].isRegistered = true;
        emit UserRegistered(msg.sender);
    }

    /**
     * @dev Retrieves a user's profile details.
     * @param userAddress The address of the user.
     * @return isRegistered Whether the user is registered.
     */
    function getUserProfile(address userAddress) external view returns (bool isRegistered) {
        return users[userAddress].isRegistered;
    }


    // Creator Management Functions

    /**
     * @dev Registers the caller as a creator. Requires being a registered user.
     * @param name Creator's display name.
     * @param profileURI Link to off-chain creator profile details.
     */
    function registerCreator(string memory name, string memory profileURI) external onlyRegisteredUser whenNotPaused {
        require(!creators[msg.sender].isRegistered, "Already a registered creator");
        creators[msg.sender] = Creator({
            isRegistered: true,
            name: name,
            profileURI: profileURI,
            wallet: payable(msg.sender)
        });
        emit CreatorRegistered(msg.sender, name);
    }

    /**
     * @dev Updates a creator's profile details.
     * @param name Creator's display name.
     * @param profileURI Link to off-chain creator profile details.
     */
    function updateCreatorProfile(string memory name, string memory profileURI) external onlyRegisteredCreator whenNotPaused {
        creators[msg.sender].name = name;
        creators[msg.sender].profileURI = profileURI;
        emit CreatorProfileUpdated(msg.sender, name, profileURI);
    }

    /**
     * @dev Retrieves a creator's profile details.
     * @param creatorAddress The address of the creator.
     * @return isRegistered Whether the creator is registered.
     * @return name Creator's display name.
     * @return profileURI Link to off-chain profile.
     * @return wallet Creator's payout wallet address.
     */
    function getCreatorProfile(address creatorAddress) external view returns (bool isRegistered, string memory name, string memory profileURI, address wallet) {
        Creator storage creator = creators[creatorAddress];
        return (creator.isRegistered, creator.name, creator.profileURI, creator.wallet);
    }

    // Validator Management Functions

    /**
     * @dev Registers the caller as a validator, requiring a minimum stake. Requires being a registered user.
     * @param name Validator's display name.
     * @param profileURI Link to off-chain validator profile details.
     */
    function registerValidator(string memory name, string memory profileURI) external payable onlyRegisteredUser whenNotPaused {
        require(!validators[msg.sender].isRegistered, "Already a registered validator");
        // Minimum stake logic could be added here or handled off-chain before registration
        require(msg.value > 0, "Must stake an initial amount to register");

        validators[msg.sender] = Validator({
            isRegistered: true,
            name: name,
            profileURI: profileURI,
            stakedAmount: msg.value,
            unstakeCooldownEnds: 0 // No cooldown initially
        });
        emit ValidatorRegistered(msg.sender, name, msg.value);
    }

    /**
     * @dev Allows a validator to add more stake.
     */
    function stakeValidator() external payable onlyRegisteredValidator whenNotPaused {
        require(msg.value > 0, "Must send Ether to stake");
        validators[msg.sender].stakedAmount += msg.value;
        emit ValidatorStaked(msg.sender, msg.value, validators[msg.sender].stakedAmount);
    }

    /**
     * @dev Allows a validator to request unstaking a certain amount.
     * Funds become available after a cooldown period.
     * @param amount The amount to unstake.
     */
    function unstakeValidator(uint256 amount) external onlyRegisteredValidator whenNotPaused {
        Validator storage validator = validators[msg.sender];
        require(amount > 0 && amount <= validator.stakedAmount, "Invalid unstake amount");
        // Simplified cooldown: 7 days
        uint256 cooldownDuration = 7 days;
        validator.unstakeCooldownEnds = block.timestamp + cooldownDuration;
        validator.stakedAmount -= amount; // Amount removed from active stake immediately

        // Note: Actual withdrawal function needed after cooldown ends, omitted for brevity (would be ~func unstakeWithdrawal)
        // For this example, we just track the amount removed from stake and the cooldown
        emit ValidatorUnstakeRequested(msg.sender, amount, validator.unstakeCooldownEnds);
    }

     /**
     * @dev Retrieves a validator's profile details.
     * @param validatorAddress The address of the validator.
     * @return isRegistered Whether the validator is registered.
     * @return name Validator's display name.
     * @return profileURI Link to off-chain profile.
     * @return stakedAmount Current staked amount.
     * @return unstakeCooldownEnds Timestamp when cooldown ends.
     */
    function getValidatorProfile(address validatorAddress) external view returns (bool isRegistered, string memory name, string memory profileURI, uint256 stakedAmount, uint256 unstakeCooldownEnds) {
        Validator storage validator = validators[validatorAddress];
        return (validator.isRegistered, validator.name, validator.profileURI, validator.stakedAmount, validator.unstakeCooldownEnds);
    }

    /**
     * @dev Slashes a validator's stake. Callable by owner or potentially a DAO/governance process.
     * This function represents the on-chain consequence of off-chain misbehavior detection.
     * @param validatorAddress The address of the validator to slash.
     * @param slashAmount The amount of stake to slash.
     * @param reasonURI Link to off-chain justification/proof of misbehavior.
     */
    function slashValidator(address validatorAddress, uint256 slashAmount, string memory reasonURI) external onlyOwner whenNotPaused {
        Validator storage validator = validators[validatorAddress];
        require(validator.isRegistered, "Validator not registered");
        require(slashAmount > 0 && slashAmount <= validator.stakedAmount, "Invalid slash amount");

        validator.stakedAmount -= slashAmount;
        // Slashed funds can go to the fee pool, a community pool, or burned
        totalFeesCollected += slashAmount; // Example: Add to fees
        emit ValidatorSlashed(validatorAddress, slashAmount, reasonURI);
    }


    // Model Management Functions

    /**
     * @dev Allows a creator to list a new AI model on the marketplace.
     * @param name Model name.
     * @param descriptionURI Link to off-chain model description/details.
     * @param creatorAddress The creator's address. Must be registered.
     * @param price One-time access price in wei (0 for subscription-only).
     * @param subscriptionDuration Duration of subscription in seconds (0 for one-time only).
     * @param validatorStakeRequirement Minimum stake validator needs to validate this model.
     * @param expectedInputHash Hash representing the expected input data structure/format.
     * @param expectedOutputHash Hash representing the expected output data structure/format.
     */
    function listModel(
        string memory name,
        string memory descriptionURI,
        address creatorAddress,
        uint256 price,
        uint256 subscriptionDuration,
        uint256 validatorStakeRequirement,
        bytes32 expectedInputHash,
        bytes32 expectedOutputHash
    ) external onlyRegisteredCreator whenNotPaused {
        require(msg.sender == creatorAddress, "Can only list models for yourself");
        require(bytes(name).length > 0, "Model name cannot be empty");
        require(price > 0 || subscriptionDuration > 0, "Model must have a price or subscription option");

        uint256 modelId = nextModelId++;
        models[modelId] = Model({
            id: modelId,
            name: name,
            descriptionURI: descriptionURI,
            creatorAddress: creatorAddress,
            price: price,
            subscriptionDuration: subscriptionDuration,
            validatorStakeRequirement: validatorStakeRequirement,
            expectedInputHash: expectedInputHash,
            expectedOutputHash: expectedOutputHash,
            isListed: true,
            latestValidationResultHash: 0, // No validation result initially
            lastValidatedTimestamp: 0,
            totalRatings: 0,
            sumOfRatings: 0
        });

        emit ModelListed(modelId, creatorAddress, name, price);
    }

    /**
     * @dev Allows a creator to update details of their model (excluding price/subscription).
     * @param modelId The ID of the model to update.
     * @param descriptionURI New link to off-chain description.
     * @param expectedInputHash New expected input hash.
     * @param expectedOutputHash New expected output hash.
     */
    function updateModelDetails(uint256 modelId, string memory descriptionURI, bytes32 expectedInputHash, bytes32 expectedOutputHash) external onlyRegisteredCreator isModelListed(modelId) whenNotPaused {
        require(models[modelId].creatorAddress == msg.sender, "Only model creator can update details");

        models[modelId].descriptionURI = descriptionURI;
        models[modelId].expectedInputHash = expectedInputHash;
        models[modelId].expectedOutputHash = expectedOutputHash;

        emit ModelDetailsUpdated(modelId, descriptionURI, expectedInputHash, expectedOutputHash);
    }

     /**
     * @dev Allows a creator to update the price and subscription duration of their model.
     * May require off-chain notification to existing subscribers/users.
     * @param modelId The ID of the model to update.
     * @param newPrice New one-time access price in wei.
     * @param newSubscriptionDuration New subscription duration in seconds.
     */
    function updateModelPrice(uint256 modelId, uint256 newPrice, uint256 newSubscriptionDuration) external onlyRegisteredCreator isModelListed(modelId) whenNotPaused {
        require(models[modelId].creatorAddress == msg.sender, "Only model creator can update price");
        require(newPrice > 0 || newSubscriptionDuration > 0, "Model must still have a price or subscription");

        models[modelId].price = newPrice;
        models[modelId].subscriptionDuration = newSubscriptionDuration;

        emit ModelPriceUpdated(modelId, newPrice, newSubscriptionDuration);
    }


    /**
     * @dev Allows a creator to delist their model. Existing access/subscriptions remain valid until they expire.
     * @param modelId The ID of the model to delist.
     */
    function delistModel(uint256 modelId) external onlyRegisteredCreator isModelListed(modelId) whenNotPaused {
        require(models[modelId].creatorAddress == msg.sender, "Only model creator can delist");
        models[modelId].isListed = false;
        emit ModelDelisted(modelId, msg.sender);
    }

    /**
     * @dev Retrieves details of a specific model.
     * @param modelId The ID of the model.
     * @return model The Model struct.
     */
    function getModelDetails(uint256 modelId) external view returns (Model memory model) {
        require(models[modelId].id != 0, "Model does not exist"); // Check if modelId was ever used
        return models[modelId];
    }


    // Access & Subscription Functions

    /**
     * @dev Allows a user to purchase one-time access to a model.
     * Transfers payment to the creator and marketplace fee.
     * @param modelId The ID of the model to purchase.
     */
    function purchaseModelAccess(uint256 modelId) external payable onlyRegisteredUser isModelListed(modelId) whenNotPaused {
        Model storage model = models[modelId];
        require(model.price > 0, "One-time purchase not available for this model");
        require(msg.value >= model.price, "Insufficient payment");

        userAccess[msg.sender][modelId].hasOneTimeAccess = true;

        uint256 creatorShare = model.price - (model.price * feePercentage) / 10000; // feePercentage is scaled by 100
        uint256 marketplaceFee = model.price - creatorShare;

        totalFeesCollected += marketplaceFee;

        // Transfer to creator
        (bool creatorSendSuccess, ) = creators[model.creatorAddress].wallet.call{value: creatorShare}("");
        require(creatorSendSuccess, "Payment to creator failed"); // Basic check, could add refund logic

        // Refund excess payment if any
        if (msg.value > model.price) {
            (bool refundSuccess, ) = payable(msg.sender).call{value: msg.value - model.price}("");
            require(refundSuccess, "Refund failed"); // Should not fail
        }

        emit AccessPurchased(modelId, msg.sender, model.price);
    }

    /**
     * @dev Allows a user to create or renew a subscription to a model.
     * Requires sending the subscription price. Payment structure (monthly, yearly) assumed off-chain calculation for `msg.value`.
     * This implementation simply adds the subscription duration *from the moment of payment*.
     * @param modelId The ID of the model to subscribe to.
     */
    function createSubscription(uint256 modelId) external payable onlyRegisteredUser isModelListed(modelId) whenNotPaused {
        Model storage model = models[modelId];
        require(model.subscriptionDuration > 0, "Subscription not available for this model");
        // Assume msg.value is the correct amount for the subscription period defined off-chain
        // (e.g., monthly rate * number of months). Contract only cares about total amount and duration.
        // Require specific amount check here if implementing fixed subscription fees on-chain.
        // require(msg.value >= calculated_subscription_cost, "Insufficient payment for subscription");

        // If already subscribed, extend the end time
        uint256 currentEndTime = userAccess[msg.sender][modelId].subscriptionEnds;
        uint256 newStartTime = (block.timestamp > currentEndTime) ? block.timestamp : currentEndTime;

        userAccess[msg.sender][modelId].subscriptionEnds = newStartTime + model.subscriptionDuration;

        // Handle payment distribution (similar to purchase)
        uint256 amountPaid = msg.value; // Assuming msg.value is the correct payment
         uint256 creatorShare = amountPaid - (amountPaid * feePercentage) / 10000;
         uint256 marketplaceFee = amountPaid - creatorShare;
         totalFeesCollected += marketplaceFee;

         (bool creatorSendSuccess, ) = creators[model.creatorAddress].wallet.call{value: creatorShare}("");
         require(creatorSendSuccess, "Subscription payment to creator failed");

        emit SubscriptionCreated(modelId, msg.sender, amountPaid, model.subscriptionDuration);
    }

    /**
     * @dev Allows a user to cancel their active subscription. Access remains until expiry.
     * No refund logic is implemented here.
     * @param modelId The ID of the model.
     */
    function cancelSubscription(uint256 modelId) external onlyRegisteredUser whenNotPaused {
         UserAccess storage access = userAccess[msg.sender][modelId];
         require(access.subscriptionEnds > block.timestamp, "No active subscription to cancel");

         // Simply set the end time to the current time or mark cancelled.
         // Setting to block.timestamp effectively ends it now for future checks.
         access.subscriptionEnds = block.timestamp;

         // Note: No refund logic included for simplicity. Refund would be more complex.
         emit SubscriptionCancelled(modelId, msg.sender);
    }


    // Validation & Reporting Hooks

    /**
     * @dev Allows a registered validator to submit a hash representing the result of an off-chain validation process.
     * This function records the submission time and hash. The actual validation logic,
     * result verification, challenges, and reward/slashing decisions happen off-chain or
     * in separate governance calls triggered by off-chain systems.
     * @param modelId The ID of the model validated.
     * @param validationResultHash Hash of the off-chain validation result/report.
     * @param validatorStakeAtSubmission The amount of stake the validator had at the time of off-chain validation (for potential future slashing reference).
     */
    function submitValidationResult(uint256 modelId, bytes32 validationResultHash, uint256 validatorStakeAtSubmission) external onlyRegisteredValidator isModelListed(modelId) whenNotPaused {
        // Basic check if validator meets the requirement (could be stricter, e.g., >=)
        require(validators[msg.sender].stakedAmount >= models[modelId].validatorStakeRequirement, "Validator stake below model requirement");

        models[modelId].latestValidationResultHash = validationResultHash;
        models[modelId].lastValidatedTimestamp = block.timestamp;

        // Store validator and stake amount for this validation round? Needs more complex state.
        // For this simplified version, we just record the result hash and timestamp on the model.

        emit ValidationResultSubmitted(modelId, msg.sender, validationResultHash);

        // Future: Could transition model status here based on off-chain rules/proofs
        // models[modelId].validationStatus = ValidationStatus.Validated; // Or PendingArbitration
    }

    /**
     * @dev Hook for off-chain services to report usage for models (e.g., pay-per-inference).
     * This contract currently only records the report; actual payment based on usage
     * would require more complex accounting and payout logic (potentially off-chain aggregation + on-chain claim).
     * @param modelId The ID of the model used.
     * @param userAddress The user who consumed the usage.
     * @param usageUnits The amount of usage (e.g., number of inferences, compute time units).
     */
    function reportInferenceUsage(uint256 modelId, address userAddress, uint256 usageUnits) external whenNotPaused {
         // This function should likely have stricter access control,
         // callable only by trusted off-chain services/oracle.
         // For demo purposes, keeping it simple.

        require(models[modelId].id != 0 && models[modelId].isListed, "Model not found or not listed");
        require(users[userAddress].isRegistered, "User not registered");
        require(usageUnits > 0, "Usage units must be positive");

        // Logic here could update a user's usage balance for a model,
        // or trigger a micro-payment, depending on the model's pricing structure.
        // As implemented, it's purely a reporting hook.
        // Example: usageBalances[userAddress][modelId] += usageUnits;

        emit InferenceUsageReported(modelId, userAddress, usageUnits);
    }

    // Reputation Functions

    /**
     * @dev Allows a registered user to submit a rating for a model.
     * Simple average calculation. One rating per user per model.
     * @param modelId The ID of the model being rated.
     * @param rating The rating (1-5).
     */
    function submitModelRating(uint256 modelId, uint8 rating) external onlyRegisteredUser isModelListed(modelId) whenNotPaused {
        require(rating >= 1 && rating <= 5, "Rating must be between 1 and 5");
        // Add check if user has already rated? Requires another mapping (user => model => bool hasRated)

        Model storage model = models[modelId];
        model.sumOfRatings += rating * 10; // Store sum of ratings * 10 to keep precision before averaging
        model.totalRatings += 1;

        emit ModelRatingSubmitted(modelId, msg.sender, rating);
    }

    // Utility/View Functions

    /**
     * @dev Checks if a user has active access (either one-time purchase or active subscription) to a model.
     * @param userAddress The address of the user.
     * @param modelId The ID of the model.
     * @return hasAccess True if the user has active access.
     */
    function checkAccessStatus(address userAddress, uint256 modelId) external view returns (bool hasAccess) {
        UserAccess storage access = userAccess[userAddress][modelId];
        return access.hasOneTimeAccess || (access.subscriptionEnds > block.timestamp);
    }

    // --- Potential Future Functions (not included in the 26 function count) ---
    // - function unstakeWithdrawal() external onlyRegisteredValidator: Allows validator to withdraw after cooldown.
    // - function claimValidatorRewards(): Allows validators to claim earned rewards from a reward pool.
    // - function submitChallenge(uint256 modelId, bytes32 validationResultHash): User/validator challenges a validation result.
    // - function resolveChallenge(uint256 modelId, address winningValidator, address losingValidator): Owner/DAO resolves challenge, triggers slashing/rewards.
    // - function transferModelOwnership(uint256 modelId, address newCreator): Transfer model ownership to another creator.
    // - function setValidatorMinimumStake(uint256 minimumStake): Admin sets global min stake.
    // - function addTrustedReporter(address reporter): Admin adds address allowed to call reportInferenceUsage.
    // - function removeTrustedReporter(address reporter): Admin removes trusted reporter.
    // - function getModelAverageRating(uint256 modelId) view: Calculates and returns average rating.
    // - function getModelValidationStatus(uint256 modelId) view: Returns the current validation status enum.
    // - function getAllListedModelIds() view: Returns an array of all currently listed model IDs (gas intensive).
    // - function getModelsByCreator(address creatorAddress) view: Returns array of model IDs by a specific creator.

}
```