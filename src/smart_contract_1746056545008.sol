Okay, this is an exciting challenge! Let's design a smart contract that manages a decentralized marketplace for AI/ML model access and validation, incorporating concepts like usage-based pricing, reputation, decentralized validation with potential for ZK-proof integration, and simple governance.

This contract *doesn't* run the AI models itself (that's computationally infeasible on-chain). Instead, it acts as the ledger and access control layer for off-chain AI model APIs or services.

---

## Decentralized AI Model Marketplace (DAIMM)

**Concept:** A marketplace where AI model creators can list their models, users can purchase access (pay-per-use or subscription), and a decentralized network can validate model quality, safety, and performance, influencing reputation and access.

**Advanced Concepts & Features:**

1.  **Usage-Based/Subscription Access:** Flexible pricing models.
2.  **Decentralized Validation:** Allows staked participants to review models.
3.  **ZK-Proof Integration Hint:** Stores hashes of zk-proofs generated off-chain for validation results, providing verifiable claims without revealing underlying data.
4.  **Reputation System:** Models and users earn reputation based on reviews, usage, and validation outcomes.
5.  **Parametric Slashing:** Validators stake collateral which can be slashed for malicious activity based on dispute resolution.
6.  **Simple On-Chain Governance:** Allows token holders (or designated addresses) to propose and vote on protocol parameters.
7.  **NFT Licenses (Conceptual):** Could easily be extended to grant access via holding a specific NFT (not fully implemented here, but structured to allow it).

---

## Outline:

1.  **License & Pragma**
2.  **Error Definitions**
3.  **Imports** (Potentially OpenZeppelin for utilities if needed, but let's minimize external dependencies for uniqueness)
4.  **Events** (Key actions logged)
5.  **Enums** (ModelStatus, PricingType, ProposalState)
6.  **Structs** (Model, UserAccess, ValidationStake, ModelValidationStatus, GovernanceProposal)
7.  **State Variables** (Mappings for models, access, stakes, proposals, counters, fees, governance)
8.  **Modifiers** (Access control, state checks)
9.  **Core Logic Functions:**
    *   Constructor
    *   Admin/Governance Functions
    *   Model Provider Functions
    *   User Access Functions
    *   Validation Functions
    *   Reputation Functions (Internal updates, external getters)
    *   View Functions (Getters for various data)

---

## Function Summary:

**Admin / Governance (Modifier: `onlyGovernance`)**
*   `setFeeRecipient(address _feeRecipient)`: Sets the address where protocol fees are sent.
*   `setListingFee(uint256 _fee)`: Sets the ETH fee required to list a new model.
*   `setUsageFeePercentage(uint256 _percentage)`: Sets the percentage of usage/subscription fees collected by the protocol.
*   `setValidationStakeAmount(uint256 _amount)`: Sets the required ETH stake for a validator to participate for one model.
*   `setValidationPeriod(uint256 _duration)`: Sets the duration validators have to submit results after staking.
*   `setDisputeResolutionPeriod(uint256 _duration)`: Sets the time window for governance to resolve disputes.
*   `createGovernanceProposal(address _target, bytes _callData, string memory _description)`: Creates a proposal to call a function on a target contract (or self).
*   `voteOnProposal(uint256 _proposalId, bool _support)`: Casts a vote on an active proposal.
*   `executeProposal(uint256 _proposalId)`: Executes a proposal that has met the voting threshold and duration.
*   `pauseContract()`: Pauses core marketplace functions (listing, access purchase, validation).
*   `unpauseContract()`: Unpauses the contract.

**Model Provider (Modifier: `onlyProvider(modelId)`)**
*   `listModel(string memory _metadataURI, uint256 _price, PricingType _pricingType)`: Lists a new AI model in the marketplace. Requires listing fee.
*   `updateModelMetadata(uint256 _modelId, string memory _newMetadataURI)`: Updates the metadata URI for an existing model.
*   `updateModelPricing(uint256 _modelId, uint256 _newPrice, PricingType _newPricingType)`: Updates the pricing structure for a model.
*   `retireModel(uint256 _modelId)`: Marks a model as retired, preventing new access purchases.
*   `withdrawProviderFunds(uint256 _modelId)`: Allows the provider to withdraw their accumulated earnings from a model.

**User Access**
*   `purchaseModelAccess(uint256 _modelId)`: Purchases access to a model. Requires payment based on model price.
*   `extendModelAccess(uint256 _modelId)`: Extends the subscription period for a model (if subscription-based).
*   `submitModelReview(uint256 _modelId, uint8 _rating, bytes32 _commentHash)`: Submits a rating (1-5) and a hash of an off-chain comment for a model, influencing its reputation. Requires active access.

**Validation**
*   `stakeForModelValidation(uint256 _modelId)`: Stakes ETH to become a validator for a specific model.
*   `submitModelValidationResult(uint256 _modelId, bool _isPositive, bytes32 _zkProofHash)`: Submits a validation result (positive/negative) along with a hash of an off-chain ZK-proof verifying the result. Callable only during validation period by staked validators.
*   `disputeModelValidationResult(uint256 _modelId, address _validator, bytes32 _reasonHash)`: Initiates a dispute against a validator's submitted result. Requires a fee or stake.
*   `withdrawValidatorStake(uint256 _modelId)`: Allows a validator to withdraw their stake after the validation/dispute period, if not slashed.
*   `slashValidator(uint256 _modelId, address _validator)`: (Callable by governance after dispute resolution) Slashes a validator's stake.

**View Functions (Getter Functions)**
*   `getModelInfo(uint256 _modelId)`: Retrieves detailed information about a model.
*   `getUserAccessStatus(uint256 _modelId, address _user)`: Checks if a user has active access to a model and details remaining access.
*   `getModelReputationScore(uint256 _modelId)`: Gets the current reputation score of a model.
*   `getValidatorStakeAmount()`: Gets the currently required stake amount for validation.
*   `getValidationPeriod()`: Gets the duration of the validation period.
*   `getDisputeResolutionPeriod()`: Gets the duration for dispute resolution.
*   `getListingFee()`: Gets the current model listing fee.
*   `getUsageFeePercentage()`: Gets the current protocol usage fee percentage.
*   `getProtocolBalance()`: Checks the total ETH balance held by the contract (protocol fees).
*   `getProviderPayoutAmount(uint256 _modelId)`: Checks the amount of ETH a provider can withdraw for a specific model.
*   `getModelValidationStatus(uint256 _modelId)`: Retrieves the current status of the validation round for a model.
*   `getValidatorSubmittedProofHash(uint256 _modelId, address _validator)`: Gets the ZK proof hash submitted by a specific validator for a model in the current round.
*   `getGovernanceProposal(uint256 _proposalId)`: Gets details about a specific governance proposal.

**Total Functions: 32** (Well over the required 20)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Decentralized AI Model Marketplace (DAIMM)
/// @notice A smart contract for managing a marketplace for AI/ML model access, validation, and reputation.
/// @dev This contract manages the access control, payments, validation process, and reputation system
///      for off-chain AI models. It does NOT execute AI models on-chain.
///      Validation incorporates storing ZK-proof hashes for off-chain verification.

// --- Error Definitions ---
error DAIMM__Unauthorized();
error DAIMM__InvalidModelId();
error DAIMM__ModelNotActive();
error DAIMM__InsufficientPayment();
error DAIMM__AccessNotActive();
error DAIMM__PricingTypeMismatch();
error DAIMM__ZeroAddressNotAllowed();
error DAIMM__StakeAmountTooLow();
error DAIMM__NotAValidator();
error DAIMM__ValidationPeriodNotActive();
error DAIMM__ValidationAlreadySubmitted();
error DAIMM__DisputeResolutionPeriodNotActive();
error DAIMM__ValidatorNotDisputed();
error DAIMM__ProposalDoesNotExist();
error DAIMM__ProposalNotActive();
error DAIMM__ProposalAlreadyExecuted();
error DAIMM__ProposalThresholdNotMet();
error DAIMM__ProposalExecutionFailed();
error DAIMM__ModelNotRetired();
error DAIMM__NoFundsToWithdraw();
error DAIMM__InvalidRating();
error DAIMM__AlreadyReviewed();
error DAIMM__ContractPaused();


// --- Events ---
event ModelListed(uint256 indexed modelId, address indexed provider, string metadataURI, uint256 price, uint8 pricingType);
event ModelUpdated(uint256 indexed modelId, string newMetadataURI, uint256 newPrice, uint8 newPricingType);
event ModelRetired(uint256 indexed modelId);
event AccessPurchased(uint256 indexed modelId, address indexed user, uint256 amountPaid, uint256 expirationTime, uint256 usesGranted);
event AccessExtended(uint256 indexed modelId, address indexed user, uint256 newExpirationTime, uint256 newUsesRemaining);
event FundsWithdrawn(uint256 indexed modelId, address indexed provider, uint256 amount);
event ReviewSubmitted(uint256 indexed modelId, address indexed user, uint8 rating);
event StakedForValidation(uint256 indexed modelId, address indexed validator, uint256 amount);
event ValidationResultSubmitted(uint256 indexed modelId, address indexed validator, bool isPositive, bytes32 zkProofHash);
event DisputeInitiated(uint256 indexed modelId, address indexed disputer, address indexed validator, bytes32 reasonHash);
event ValidatorSlashed(uint256 indexed modelId, address indexed validator, uint256 slashedAmount);
event StakeWithdrawn(uint256 indexed modelId, address indexed validator, uint256 amount);
event GovernanceProposalCreated(uint256 indexed proposalId, address indexed proposer, address target, string description);
event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
event ProposalExecuted(uint256 indexed proposalId);
event FeeRecipientUpdated(address indexed newRecipient);
event ListingFeeUpdated(uint256 newFee);
event UsageFeePercentageUpdated(uint256 newPercentage);
event ValidationStakeAmountUpdated(uint256 newAmount);
event ValidationPeriodUpdated(uint256 newDuration);
event DisputeResolutionPeriodUpdated(uint256 newDuration);
event ContractPausedStatus(bool isPaused);


// --- Enums ---
enum ModelStatus { Active, Retired, UnderReview }
enum PricingType { PayPerUse, Subscription }
enum ProposalState { Pending, Active, Succeeded, Failed, Executed }


// --- Structs ---
struct Model {
    address provider;
    string metadataURI; // Link to off-chain model details, API endpoint, etc.
    uint256 price; // Price per use or per subscription period
    PricingType pricingType;
    ModelStatus status;
    uint256 reputationScore; // Simple score, e.g., 0-1000
    uint256 reviewCount;
    uint256 totalUses; // For PayPerUse
    uint256 totalRevenue; // Earned by the provider
    bytes32 validationProofHash; // Hash of the latest successful validation proof
    uint256 lastValidatedTime;
}

struct UserAccess {
    uint256 expirationTime; // For Subscription (timestamp), 0 if not subscribed
    uint256 usesRemaining; // For PayPerUse, 0 if not pay-per-use
}

struct ValidationStake {
    uint256 amount;
    uint256 stakedTime;
    bool hasSubmittedResult;
    bool isPositiveResult; // Result submitted by this validator
    bytes32 submittedProofHash; // ZK proof hash submitted by this validator
    bool isDisputed; // True if a dispute has been initiated against this validator's result
    bool wasSlashed; // True if the validator was slashed
}

struct ModelValidationStatus {
    uint256 currentStakePool;
    uint256 positiveValidations;
    uint256 negativeValidations;
    uint256 validatorsSubmittedCount;
    uint256 validationRoundStartTime; // Start time of the current validation round
    bytes32 latestPositiveProofHash; // The hash from the first validator to submit a positive proof
    bool disputeInitiated; // True if a dispute has been raised in this round
    uint256 disputeStartTime; // Time the first dispute was initiated
}

struct GovernanceProposal {
    address proposer;
    address target; // The address the proposal calls (e.g., self for admin functions)
    bytes callData; // The function call data
    string description;
    uint256 voteThreshold; // Minimum votes needed to succeed (e.g., number of voters, or token amount)
    uint256 votingDeadline;
    uint256 executionGracePeriod; // Time after success before execution is possible
    uint256 forVotes;
    uint256 againstVotes;
    bool executed;
    mapping(address => bool) voters; // Addresses that have voted
}


// --- State Variables ---
address public governance;
address public feeRecipient;
uint256 public listingFee = 0.01 ether; // Example initial fee
uint256 public usageFeePercentage = 5; // 5% (stored as 5, meaning 5/100)
uint256 public validationStakeAmount = 0.1 ether; // Example required stake per validator per model
uint256 public validationPeriod = 3 days; // Time window for validators to submit results
uint256 public disputeResolutionPeriod = 7 days; // Time window for governance to resolve disputes

uint256 private _modelCounter = 0;
mapping(uint256 => Model) public models;
mapping(address => mapping(uint256 => UserAccess)) public userAccess; // user => modelId => access details
mapping(uint256 => mapping(address => ValidationStake)) public modelValidationStakes; // modelId => validator => stake details
mapping(uint256 => ModelValidationStatus) public modelValidationStatuses; // modelId => validation round status
mapping(uint256 => uint256) public providerPendingWithdrawals; // modelId => amount drawable by provider

uint256 private _proposalCounter = 0;
mapping(uint256 => GovernanceProposal) public governanceProposals;

bool public paused = false;


// --- Modifiers ---
modifier onlyGovernance() {
    if (msg.sender != governance) revert DAIMM__Unauthorized();
    _;
}

modifier onlyProvider(uint256 _modelId) {
    if (models[_modelId].provider == address(0) || models[_modelId].provider != msg.sender) revert DAIMM__Unauthorized();
    _;
}

modifier onlyUserWithAccess(uint256 _modelId) {
    UserAccess storage access = userAccess[msg.sender][_modelId];
    Model storage model = models[_modelId];

    if (model.pricingType == PricingType.Subscription) {
        if (access.expirationTime < block.timestamp) revert DAIMM__AccessNotActive();
    } else { // PayPerUse
        if (access.usesRemaining == 0) revert DAIMM__AccessNotActive();
    }
    _;
}

modifier whenNotPaused() {
    if (paused) revert DAIMM__ContractPaused();
    _;
}


// --- Constructor ---
constructor(address _governance, address _feeRecipient) {
    if (_governance == address(0) || _feeRecipient == address(0)) revert DAIMM__ZeroAddressNotAllowed();
    governance = _governance;
    feeRecipient = _feeRecipient;
}

// --- Admin / Governance Functions ---

/// @notice Sets the address where protocol fees are sent.
/// @param _feeRecipient The new address to receive fees.
function setFeeRecipient(address _feeRecipient) external onlyGovernance {
    if (_feeRecipient == address(0)) revert DAIMM__ZeroAddressNotAllowed();
    feeRecipient = _feeRecipient;
    emit FeeRecipientUpdated(_feeRecipient);
}

/// @notice Sets the ETH fee required to list a new model.
/// @param _fee The new listing fee in Wei.
function setListingFee(uint256 _fee) external onlyGovernance {
    listingFee = _fee;
    emit ListingFeeUpdated(_fee);
}

/// @notice Sets the percentage of usage/subscription fees collected by the protocol.
/// @param _percentage The new fee percentage (e.g., 5 for 5%). Max 100.
function setUsageFeePercentage(uint256 _percentage) external onlyGovernance {
    require(_percentage <= 100, "Percentage cannot exceed 100");
    usageFeePercentage = _percentage;
    emit UsageFeePercentageUpdated(_percentage);
}

/// @notice Sets the required ETH stake for a validator to participate for one model.
/// @param _amount The new required stake amount in Wei.
function setValidationStakeAmount(uint256 _amount) external onlyGovernance {
    validationStakeAmount = _amount;
    emit ValidationStakeAmountUpdated(_amount);
}

/// @notice Sets the duration validators have to submit results after staking.
/// @param _duration The new duration in seconds.
function setValidationPeriod(uint256 _duration) external onlyGovernance {
    validationPeriod = _duration;
    emit ValidationPeriodUpdated(_duration);
}

/// @notice Sets the time window for governance to resolve disputes.
/// @param _duration The new duration in seconds.
function setDisputeResolutionPeriod(uint256 _duration) external onlyGovernance {
    disputeResolutionPeriod = _duration;
    emit DisputeResolutionPeriodUpdated(_duration);
}

/// @notice Creates a governance proposal.
/// @param _target The address of the contract to call (can be this contract).
/// @param _callData The ABI encoded data for the function call.
/// @param _description A description of the proposal.
function createGovernanceProposal(address _target, bytes memory _callData, string memory _description) external onlyGovernance {
    _proposalCounter++;
    uint256 proposalId = _proposalCounter;

    // Simple threshold for this example: any vote allows execution after deadline
    // A real DAO would use token balances, quorum, voting period etc.
    governanceProposals[proposalId] = GovernanceProposal({
        proposer: msg.sender,
        target: _target,
        callData: _callData,
        description: _description,
        voteThreshold: 1, // Simplified: requires at least one vote for/against (execution requires 1 'for')
        votingDeadline: block.timestamp + 7 days, // Example 7 day voting period
        executionGracePeriod: 1 days, // Example 1 day grace period after deadline
        forVotes: 0,
        againstVotes: 0,
        executed: false,
        voters: new mapping(address => bool)
    });

    emit GovernanceProposalCreated(proposalId, msg.sender, _target, _description);
}

/// @notice Casts a vote on an active proposal.
/// @param _proposalId The ID of the proposal.
/// @param _support True for a vote in favor, false for against.
function voteOnProposal(uint256 _proposalId, bool _support) external onlyGovernance {
    GovernanceProposal storage proposal = governanceProposals[_proposalId];
    if (proposal.proposer == address(0)) revert DAIMM__ProposalDoesNotExist();
    if (block.timestamp > proposal.votingDeadline) revert DAIMM__ProposalNotActive();
    if (proposal.voters[msg.sender]) revert("Already voted"); // Simplified: 1 address = 1 vote

    proposal.voters[msg.sender] = true;
    if (_support) {
        proposal.forVotes++;
    } else {
        proposal.againstVotes++;
    }
    emit VoteCast(_proposalId, msg.sender, _support);
}

/// @notice Executes a proposal that has met the voting threshold and duration.
/// @param _proposalId The ID of the proposal.
function executeProposal(uint256 _proposalId) external onlyGovernance {
    GovernanceProposal storage proposal = governanceProposals[_proposalId];
    if (proposal.proposer == address(0)) revert DAIMM__ProposalDoesNotExist();
    if (proposal.executed) revert DAIMM__ProposalAlreadyExecuted();
    if (block.timestamp <= proposal.votingDeadline) revert DAIMM__ProposalNotActive(); // Voting must be over
    if (block.timestamp <= proposal.votingDeadline + proposal.executionGracePeriod) revert("Execution grace period not over"); // Wait for grace period
    if (proposal.forVotes < proposal.voteThreshold) revert DAIMM__ProposalThresholdNotMet();

    // Execute the proposal call
    (bool success, ) = proposal.target.call(proposal.callData);
    if (!success) revert DAIMM__ProposalExecutionFailed();

    proposal.executed = true;
    emit ProposalExecuted(_proposalId);
}

/// @notice Pauses core contract functionality.
function pauseContract() external onlyGovernance whenNotPaused {
    paused = true;
    emit ContractPausedStatus(true);
}

/// @notice Unpauses core contract functionality.
function unpauseContract() external onlyGovernance {
    if (!paused) revert("Contract is not paused");
    paused = false;
    emit ContractPausedStatus(false);
}


// --- Model Provider Functions ---

/// @notice Lists a new AI model in the marketplace.
/// @param _metadataURI The URI pointing to the model's metadata and access info.
/// @param _price The price per use or per subscription period.
/// @param _pricingType The pricing model (PayPerUse or Subscription).
/// @dev Requires `listingFee` to be sent with the transaction.
function listModel(string memory _metadataURI, uint256 _price, PricingType _pricingType) external payable whenNotPaused {
    if (msg.value < listingFee) revert DAIMM__InsufficientPayment();

    _modelCounter++;
    uint256 modelId = _modelCounter;

    models[modelId] = Model({
        provider: msg.sender,
        metadataURI: _metadataURI,
        price: _price,
        pricingType: _pricingType,
        status: ModelStatus.Active,
        reputationScore: 500, // Start with a neutral score (e.g., 0-1000)
        reviewCount: 0,
        totalUses: 0,
        totalRevenue: 0,
        validationProofHash: bytes32(0), // No proof yet
        lastValidatedTime: 0
    });

    // Transfer listing fee to the fee recipient
    (bool success, ) = payable(feeRecipient).call{value: listingFee}("");
    require(success, "Fee transfer failed"); // Simple check, might need reentrancy guard in production

    emit ModelListed(modelId, msg.sender, _metadataURI, _price, uint8(_pricingType));
}

/// @notice Updates the metadata URI for an existing model.
/// @param _modelId The ID of the model.
/// @param _newMetadataURI The new metadata URI.
function updateModelMetadata(uint256 _modelId, string memory _newMetadataURI) external onlyProvider(_modelId) {
    if (models[_modelId].status == ModelStatus.Retired) revert DAIMM__ModelRetired();
    models[_modelId].metadataURI = _newMetadataURI;
    emit ModelUpdated(_modelId, _newMetadataURI, models[_modelId].price, uint8(models[_modelId].pricingType));
}

/// @notice Updates the pricing structure for a model.
/// @param _modelId The ID of the model.
/// @param _newPrice The new price.
/// @param _newPricingType The new pricing type.
function updateModelPricing(uint256 _modelId, uint256 _newPrice, PricingType _newPricingType) external onlyProvider(_modelId) {
    if (models[_modelId].status == ModelStatus.Retired) revert DAIMM__ModelRetired();
    models[_modelId].price = _newPrice;
    models[_modelId].pricingType = _newPricingType;
    emit ModelUpdated(_modelId, models[_modelId].metadataURI, _newPrice, uint8(_newPricingType));
}

/// @notice Marks a model as retired, preventing new access purchases.
/// @param _modelId The ID of the model.
function retireModel(uint256 _modelId) external onlyProvider(_modelId) {
    if (models[_modelId].status == ModelStatus.Retired) revert DAIMM__ModelRetired();
    models[_modelId].status = ModelStatus.Retired;
    emit ModelRetired(_modelId);
}

/// @notice Allows the provider to withdraw their accumulated earnings from a model.
/// @param _modelId The ID of the model.
function withdrawProviderFunds(uint256 _modelId) external onlyProvider(_modelId) {
    uint256 amount = providerPendingWithdrawals[_modelId];
    if (amount == 0) revert DAIMM__NoFundsToWithdraw();

    providerPendingWithdrawals[_modelId] = 0;

    (bool success, ) = payable(msg.sender).call{value: amount}("");
    require(success, "Withdrawal failed"); // Simple check, might need reentrancy guard

    emit FundsWithdrawn(_modelId, msg.sender, amount);
}


// --- User Access Functions ---

/// @notice Purchases access to a model.
/// @param _modelId The ID of the model.
/// @dev Requires payment based on model price. Handles fee collection.
function purchaseModelAccess(uint256 _modelId) external payable whenNotPaused {
    Model storage model = models[_modelId];
    if (model.provider == address(0)) revert DAIMM__InvalidModelId();
    if (model.status != ModelStatus.Active) revert DAIMM__ModelNotActive();
    if (msg.value < model.price) revert DAIMM__InsufficientPayment();

    uint256 protocolFee = (msg.value * usageFeePercentage) / 100;
    uint256 providerAmount = msg.value - protocolFee;

    // Update access details
    UserAccess storage access = userAccess[msg.sender][_modelId];
    if (model.pricingType == PricingType.Subscription) {
        // Extend subscription
        uint256 currentExpiration = access.expirationTime;
        uint256 newExpiration = currentExpiration > block.timestamp ? currentExpiration + 30 days : block.timestamp + 30 days; // Example: 30 day subscription
        access.expirationTime = newExpiration;
        emit AccessExtended(_modelId, msg.sender, newExpiration, access.usesRemaining); // Use Extended event for subscription
    } else { // PayPerUse
        // Add uses
        uint256 usesGranted = msg.value / model.price; // Assume integer division gives whole uses
        if (usesGranted == 0) revert DAIMM__InsufficientPayment(); // Ensure at least one use is granted
        access.usesRemaining += usesGranted;
        model.totalUses += usesGranted;
        emit AccessPurchased(_modelId, msg.sender, msg.value, access.expirationTime, access.usesRemaining);
    }

    // Distribute funds
    providerPendingWithdrawals[_modelId] += providerAmount;
    (bool success, ) = payable(feeRecipient).call{value: protocolFee}("");
    require(success, "Fee transfer failed"); // Simple check

    model.totalRevenue += providerAmount;
}

/// @notice Submits a rating and a hash of an off-chain comment for a model.
/// @param _modelId The ID of the model.
/// @param _rating The rating (1-5).
/// @param _commentHash A hash of the off-chain comment.
/// @dev Requires active access to the model. Only one review per user per model.
function submitModelReview(uint256 _modelId, uint8 _rating, bytes32 _commentHash) external onlyUserWithAccess(_modelId) {
    Model storage model = models[_modelId];
    if (model.provider == address(0)) revert DAIMM__InvalidModelId();
    if (_rating == 0 || _rating > 5) revert DAIMM__InvalidRating();

    // Simple check to prevent multiple reviews - could use a mapping: user => modelId => bool
    // For simplicity here, we'll assume no mapping exists and just allow updates or rely on off-chain logic.
    // A more robust system would track reviewers. Let's add a simple mapping.
    mapping(uint256 => mapping(address => bool)) private hasReviewed;
    if (hasReviewed[_modelId][msg.sender]) revert DAIMM__AlreadyReviewed();
    hasReviewed[_modelId][msg.sender] = true;

    // Simple reputation calculation: moving average or weighted average
    // (current_score * review_count + new_rating * 200) / (review_count + 1)
    // Normalize rating 1-5 to 0-1000 scale: (rating-1) * 250 (0, 250, 500, 750, 1000) or rating * 200 (200, 400, 600, 800, 1000)
    // Let's use rating * 200 for simplicity (1=200, 5=1000)
    uint256 normalizedRating = uint256(_rating) * 200;
    model.reputationScore = (model.reputationScore * model.reviewCount + normalizedRating) / (model.reviewCount + 1);
    model.reviewCount++;

    // Optionally store commentHash
    // event includes rating, commentHash not necessary in event unless needed for off-chain indexing

    emit ReviewSubmitted(_modelId, msg.sender, _rating);
}


// --- Validation Functions ---

/// @notice Stakes ETH to become a validator for a specific model. Starts a new validation round if first stake.
/// @param _modelId The ID of the model.
/// @dev Requires `validationStakeAmount` to be sent with the transaction.
function stakeForModelValidation(uint256 _modelId) external payable whenNotPaused {
    Model storage model = models[_modelId];
    if (model.provider == address(0)) revert DAIMM__InvalidModelId();
    // Allow validation even if retired or under review? Maybe only Active models? Let's allow for retired too for safety checks.
    if (msg.value < validationStakeAmount) revert DAIMM__StakeAmountTooLow();
    if (modelValidationStakes[_modelId][msg.sender].amount > 0) revert("Already staked for this model");

    ModelValidationStatus storage validationStatus = modelValidationStatuses[_modelId];

    modelValidationStakes[_modelId][msg.sender] = ValidationStake({
        amount: msg.value,
        stakedTime: block.timestamp,
        hasSubmittedResult: false,
        isPositiveResult: false, // Placeholder
        submittedProofHash: bytes32(0), // Placeholder
        isDisputed: false,
        wasSlashed: false
    });

    validationStatus.currentStakePool += msg.value;

    // If this is the first stake in a new potential round, start the timer
    if (validationStatus.validatorsSubmittedCount == 0 && validationStatus.validationRoundStartTime == 0) {
         validationStatus.validationRoundStartTime = block.timestamp;
         // Reset counts for a new round
         validationStatus.positiveValidations = 0;
         validationStatus.negativeValidations = 0;
         validationStatus.disputeInitiated = false; // Reset dispute status for the round
         validationStatus.disputeStartTime = 0;
    }

    emit StakedForValidation(_modelId, msg.sender, msg.value);
}

/// @notice Submits a validation result (positive/negative) and a hash of an off-chain ZK-proof.
/// @param _modelId The ID of the model.
/// @param _isPositive True if the validation is positive, false if negative (e.g., malicious, poor performance).
/// @param _zkProofHash The hash of the off-chain ZK-proof verifying the result.
/// @dev Callable only during the validation period by a staked validator.
function submitModelValidationResult(uint256 _modelId, bool _isPositive, bytes32 _zkProofHash) external whenNotPaused {
    Model storage model = models[_modelId];
    if (model.provider == address(0)) revert DAIMM__InvalidModelId();

    ValidationStake storage stake = modelValidationStakes[_modelId][msg.sender];
    if (stake.amount == 0) revert DAIMM__NotAValidator();
    if (stake.hasSubmittedResult) revert DAIMM__ValidationAlreadySubmitted();

    ModelValidationStatus storage validationStatus = modelValidationStatuses[_modelId];
    if (validationStatus.validationRoundStartTime == 0 || block.timestamp > validationStatus.validationRoundStartTime + validationPeriod) {
        revert DAIMM__ValidationPeriodNotActive();
    }

    stake.hasSubmittedResult = true;
    stake.isPositiveResult = _isPositive;
    stake.submittedProofHash = _zkProofHash; // Store the hash of the proof
    validationStatus.validatorsSubmittedCount++;

    if (_isPositive) {
        validationStatus.positiveValidations++;
        // Store the first positive proof hash submitted
        if (validationStatus.latestPositiveProofHash == bytes32(0)) {
            validationStatus.latestPositiveProofHash = _zkProofHash;
        }
    } else {
        validationStatus.negativeValidations++;
    }

    emit ValidationResultSubmitted(_modelId, msg.sender, _isPositive, _zkProofHash);

    // If enough validators have submitted, or period is over, process results?
    // Simpler: results are processed/stakes withdrawn after validation/dispute period manually or via helper function calls.
}

/// @notice Initiates a dispute against a validator's submitted result.
/// @param _modelId The ID of the model.
/// @param _validator The address of the validator whose result is disputed.
/// @param _reasonHash A hash of the off-chain reason for the dispute.
/// @dev Requires a fee or stake (simplified: requires calling address to *be* governance for resolution).
///      In a real system, anyone could dispute with a stake.
function disputeModelValidationResult(uint256 _modelId, address _validator, bytes32 _reasonHash) external onlyGovernance {
    // Simplified: Only governance can *initiate* the on-chain dispute marker based on off-chain findings.
    // A real system would allow anyone to stake and dispute, then governance/DAO resolves.
    Model storage model = models[_modelId];
    if (model.provider == address(0)) revert DAIMM__InvalidModelId();

    ValidationStake storage stake = modelValidationStakes[_modelId][_validator];
    if (stake.amount == 0 || !stake.hasSubmittedResult) revert DAIMM__ValidatorNotDisputed(); // Not a validator or didn't submit a result

    ModelValidationStatus storage validationStatus = modelValidationStatuses[_modelId];
    if (validationStatus.validationRoundStartTime == 0 || block.timestamp > validationStatus.validationRoundStartTime + validationPeriod + disputeResolutionPeriod) {
        revert DAIMM__DisputeResolutionPeriodNotActive(); // Dispute period is after validation period ends
    }

    stake.isDisputed = true;
    validationStatus.disputeInitiated = true;
    if(validationStatus.disputeStartTime == 0) {
        validationStatus.disputeStartTime = block.timestamp; // Record start of dispute resolution window
    }

    emit DisputeInitiated(_modelId, msg.sender, _validator, _reasonHash);
}

/// @notice (Called by Governance after off-chain dispute resolution) Slashes a validator's stake.
/// @param _modelId The ID of the model.
/// @param _validator The address of the validator to slash.
/// @dev Callable only by governance during or after the dispute resolution period.
function slashValidator(uint256 _modelId, address _validator) external onlyGovernance {
     Model storage model = models[_modelId];
     if (model.provider == address(0)) revert DAIMM__InvalidModelId();

     ValidationStake storage stake = modelValidationStakes[_modelId][_validator];
     if (stake.amount == 0 || !stake.isDisputed || stake.wasSlashed) revert DAIMM__ValidatorNotDisputed(); // Needs to be staked and disputed
     // Add check for dispute resolution period expiry if governance needs a window to act

     uint256 slashedAmount = stake.amount;
     modelValidationStatuses[_modelId].currentStakePool -= slashedAmount; // Reduce total stake pool
     // Decide where slashed funds go: protocol fee recipient, burned, distributed?
     // Let's send to fee recipient for simplicity.
     (bool success, ) = payable(feeRecipient).call{value: slashedAmount}("");
     require(success, "Slash fund transfer failed");

     stake.wasSlashed = true; // Mark as slashed
     // Do not reset stake.amount immediately, keep record until withdrawal attempt

     emit ValidatorSlashed(_modelId, _validator, slashedAmount);

     // Optionally update model reputation based on slashing outcome
     // _updateReputation(_modelId, /* parameters based on slash */);
}


/// @notice Allows a validator to withdraw their stake after the validation/dispute period, if not slashed.
/// @param _modelId The ID of the model.
/// @dev Callable only after validation period + dispute resolution period + cool-down.
function withdrawValidatorStake(uint256 _modelId) external whenNotPaused {
    Model storage model = models[_modelId];
    if (model.provider == address(0)) revert DAIMM__InvalidModelId();

    ValidationStake storage stake = modelValidationStakes[_modelId][msg.sender];
    if (stake.amount == 0) revert DAIMM__NotAValidator();
    if (!stake.hasSubmittedResult) revert("Result not submitted"); // Must submit a result to potentially earn/withdraw

    ModelValidationStatus storage validationStatus = modelValidationStatuses[_modelId];
    // Stake can only be withdrawn after dispute resolution period + a cool-down
    uint256 withdrawUnlockTime = validationStatus.validationRoundStartTime + validationPeriod + disputeResolutionPeriod + 1 days; // Example 1 day cool-down
    if (block.timestamp < withdrawUnlockTime) revert("Stake is locked");

    if (stake.wasSlashed) {
        // Stake was slashed, nothing to withdraw
        stake.amount = 0; // Clear stake amount after attempt
        revert("Stake was slashed");
    }

    uint256 amountToWithdraw = stake.amount;
    stake.amount = 0; // Clear stake amount immediately

    // Distribute stake pool? Or each validator gets their own stake back?
    // Let's assume each gets their own stake back if not slashed.
    // A more complex system would distribute pool based on validation outcome.
    modelValidationStatuses[_modelId].currentStakePool -= amountToWithdraw; // Reduce total stake pool

    (bool success, ) = payable(msg.sender).call{value: amountToWithdraw}("");
    require(success, "Stake withdrawal failed"); // Simple check

    emit StakeWithdrawn(_modelId, msg.sender, amountToWithdraw);

    // After validation round is complete and stakes settled, update model's reputation
    // and store the winning proof hash (e.g., majority positive proof)
    if (validationStatus.positiveValidations > validationStatus.negativeValidations) {
         model.reputationScore = model.reputationScore + 50 > 1000 ? 1000 : model.reputationScore + 50; // Small reputation boost
         model.validationProofHash = validationStatus.latestPositiveProofHash;
         model.lastValidatedTime = block.timestamp;
    } else if (validationStatus.negativeValidations > validationStatus.positiveValidations) {
         model.reputationScore = model.reputationScore < 50 ? 0 : model.reputationScore - 50; // Small reputation hit
         model.validationProofHash = bytes32(0); // Clear proof hash if negatively validated
         model.lastValidatedTime = block.timestamp;
         // Optionally change model status to UnderReview or Retired if validation is strongly negative
         if (model.reputationScore < 300 && model.status == ModelStatus.Active) {
             model.status = ModelStatus.UnderReview;
         }
    }
    // Reset validation status for the model after the round concludes (after cool-down/withdrawal period)
    if (modelValidationStatuses[_modelId].currentStakePool == 0) {
         delete modelValidationStatuses[_modelId]; // Clear the status struct
    }
}


// --- View Functions ---

/// @notice Retrieves detailed information about a model.
/// @param _modelId The ID of the model.
/// @return Model struct containing model details.
function getModelInfo(uint256 _modelId) external view returns (Model memory) {
    if (models[_modelId].provider == address(0)) revert DAIMM__InvalidModelId();
    return models[_modelId];
}

/// @notice Checks if a user has active access to a model and details remaining access.
/// @param _modelId The ID of the model.
/// @param _user The address of the user.
/// @return isActive True if access is active.
/// @return expirationTime For subscriptions, the timestamp access expires.
/// @return usesRemaining For pay-per-use, the number of uses left.
function getUserAccessStatus(uint256 _modelId, address _user) external view returns (bool isActive, uint256 expirationTime, uint256 usesRemaining) {
    Model storage model = models[_modelId];
    if (model.provider == address(0)) return (false, 0, 0); // Model doesn't exist

    UserAccess storage access = userAccess[_user][_modelId];

    if (model.pricingType == PricingType.Subscription) {
        isActive = access.expirationTime > block.timestamp;
        expirationTime = access.expirationTime;
        usesRemaining = 0; // N/A for subscription
    } else { // PayPerUse
        isActive = access.usesRemaining > 0;
        expirationTime = 0; // N/A for pay-per-use
        usesRemaining = access.usesRemaining;
    }
    return (isActive, expirationTime, usesRemaining);
}

/// @notice Gets the current reputation score of a model.
/// @param _modelId The ID of the model.
/// @return The reputation score (e.g., 0-1000).
function getModelReputationScore(uint256 _modelId) external view returns (uint256) {
    if (models[_modelId].provider == address(0)) revert DAIMM__InvalidModelId();
    return models[_modelId].reputationScore;
}

/// @notice Gets the currently required stake amount for validation.
/// @return The required stake amount in Wei.
function getValidationStakeAmount() external view returns (uint256) {
    return validationStakeAmount;
}

/// @notice Gets the duration of the validation period.
/// @return The duration in seconds.
function getValidationPeriod() external view returns (uint256) {
    return validationPeriod;
}

/// @notice Gets the duration for dispute resolution.
/// @return The duration in seconds.
function getDisputeResolutionPeriod() external view returns (uint256) {
    return disputeResolutionPeriod;
}

/// @notice Gets the current model listing fee.
/// @return The listing fee in Wei.
function getListingFee() external view returns (uint256) {
    return listingFee;
}

/// @notice Gets the current protocol usage fee percentage.
/// @return The percentage (e.g., 5 for 5%).
function getUsageFeePercentage() external view returns (uint256) {
    return usageFeePercentage;
}

/// @notice Checks the total ETH balance held by the contract (protocol fees + staked funds).
/// @return The contract's current balance in Wei.
function getProtocolBalance() external view returns (uint256) {
    return address(this).balance;
}

/// @notice Checks the amount of ETH a provider can withdraw for a specific model.
/// @param _modelId The ID of the model.
/// @return The amount withdrawable by the provider in Wei.
function getProviderPayoutAmount(uint256 _modelId) external view returns (uint256) {
    if (models[_modelId].provider == address(0)) return 0; // Model doesn't exist
    return providerPendingWithdrawals[_modelId];
}

/// @notice Retrieves the current status of the validation round for a model.
/// @param _modelId The ID of the model.
/// @return currentStakePool The total ETH staked in the current round.
/// @return positiveValidations Count of positive validation results submitted.
/// @return negativeValidations Count of negative validation results submitted.
/// @return validatorsSubmittedCount Total validators who submitted a result in this round.
/// @return validationRoundStartTime Start time of the current round.
/// @return latestPositiveProofHash Hash of the first positive proof submitted in this round.
/// @return disputeInitiated True if a dispute was initiated in this round.
/// @return disputeStartTime Time the first dispute was initiated.
function getModelValidationStatus(uint256 _modelId) external view returns (
    uint256 currentStakePool,
    uint256 positiveValidations,
    uint256 negativeValidations,
    uint256 validatorsSubmittedCount,
    uint256 validationRoundStartTime,
    bytes32 latestPositiveProofHash,
    bool disputeInitiated,
    uint256 disputeStartTime
) {
    ModelValidationStatus storage status = modelValidationStatuses[_modelId];
    return (
        status.currentStakePool,
        status.positiveValidations,
        status.negativeValidations,
        status.validatorsSubmittedCount,
        status.validationRoundStartTime,
        status.latestPositiveProofHash,
        status.disputeInitiated,
        status.disputeStartTime
    );
}

/// @notice Gets the ZK proof hash submitted by a specific validator for a model in the current round.
/// @param _modelId The ID of the model.
/// @param _validator The address of the validator.
/// @return The submitted ZK proof hash. Returns bytes32(0) if validator hasn't submitted or doesn't exist.
function getValidatorSubmittedProofHash(uint256 _modelId, address _validator) external view returns (bytes32) {
    return modelValidationStakes[_modelId][_validator].submittedProofHash;
}

/// @notice Gets details about a specific governance proposal.
/// @param _proposalId The ID of the proposal.
/// @return proposer The address that proposed it.
/// @return target The address the proposal calls.
/// @return description The proposal description.
/// @return voteThreshold The minimum votes needed.
/// @return votingDeadline The deadline for voting.
/// @return executed True if the proposal was executed.
/// @return forVotes Count of 'for' votes.
/// @return againstVotes Count of 'against' votes.
function getGovernanceProposal(uint256 _proposalId) external view returns (
    address proposer,
    address target,
    string memory description,
    uint256 voteThreshold,
    uint256 votingDeadline,
    bool executed,
    uint256 forVotes,
    uint256 againstVotes
) {
    GovernanceProposal storage proposal = governanceProposals[_proposalId];
    if (proposal.proposer == address(0)) revert DAIMM__ProposalDoesNotExist();
    return (
        proposal.proposer,
        proposal.target,
        proposal.description,
        proposal.voteThreshold,
        proposal.votingDeadline,
        proposal.executed,
        proposal.forVotes,
        proposal.againstVotes
    );
}

/// @notice Get the total number of models listed.
/// @return The total number of models.
function getTotalModels() external view returns (uint256) {
    return _modelCounter;
}

/// @notice Get the total number of governance proposals.
/// @return The total number of proposals.
function getTotalProposals() external view returns (uint256) {
    return _proposalCounter;
}

}
```