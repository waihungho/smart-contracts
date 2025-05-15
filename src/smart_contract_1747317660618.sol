Okay, let's design a smart contract that combines a few interesting and modern Web3 concepts: a Decentralized Marketplace for AI Model Inference Credits, featuring model versioning, provider staking, and a reputation system.

This contract will allow AI model developers to list their models, sell usage rights in the form of "inference credits," and manage different versions of their models. Users can buy these credits to perform computations off-chain using the specified model version. The contract also includes provider staking for quality assurance and a basic user-driven reputation system. Payment will be handled using a specified ERC-20 token.

It integrates:
1.  **Tokenization of Utility:** Selling usage rights (inference credits) as digital assets.
2.  **Marketplace Mechanics:** Listing, selling, withdrawing earnings.
3.  **Version Control:** Managing different iterations of a digital asset (the model).
4.  **Staking:** Aligning incentives and potentially guaranteeing service quality (conceptually, the enforcement would be off-chain).
5.  **Reputation:** On-chain, user-generated feedback mechanism.
6.  **ERC-20 Integration:** Using a custom token for the ecosystem.
7.  **Implied Off-Chain Interaction:** The `logInferenceUsage` function signifies interaction with off-chain compute resources that consume the on-chain credits.

This is not a direct copy of standard OpenZeppelin or typical DeFi/NFT contracts. While it uses basic patterns (like Ownable, Pausable, ERC20 interaction), the specific business logic around AI models, versions, inference credits, integrated staking, and reputation creates a novel combination.

---

**Outline and Function Summary**

**Contract Name:** `DecentralizedAIModelMarketplace`

**Purpose:** A smart contract facilitating a decentralized marketplace for listing AI models and selling inference credits (usage rights) for specific model versions. Features include provider staking, a user reputation system, and payments via a specified ERC-20 token.

**Core Concepts:**
*   **Models & Versions:** Providers list models, each having multiple versions.
*   **Inference Credits:** ERC-20 token-based credits representing the right to perform a certain number of inferences (computations) using a specific model version off-chain.
*   **Provider Staking:** Providers stake tokens to list models, incentivizing good behavior and participation.
*   **Reputation:** Users rate models/providers after purchasing credits, building an on-chain reputation score.
*   **ERC-20 Payments:** All transactions use a designated ERC-20 token.

**State Variables:**
*   `owner`: Contract deployer/administrator.
*   `paused`: Pausing state for emergency stops.
*   `paymentToken`: Address of the ERC-20 token used for payments, staking, and rewards.
*   `platformFeeBps`: Platform fee percentage (in basis points).
*   `feeRecipient`: Address receiving platform fees.
*   `requiredProviderStake`: Minimum stake required for a provider to list models.
*   `nextModelId`: Counter for assigning unique model IDs.
*   `models`: Mapping from model ID to `Model` struct.
*   `modelVersions`: Nested mapping `modelId => versionId => ModelVersion` struct.
*   `modelVersionIndex`: Nested mapping `modelId => versionNumber (string) => versionId`.
*   `providerModels`: Mapping from provider address to a list of their model IDs.
*   `providerStake`: Mapping from provider address to their staked token balance.
*   `providerEarnings`: Mapping from provider address to their accumulated earnings (from credit sales).
*   `userInferenceCredits`: Nested mapping `userId => modelId => versionId => remaining credits`.
*   `modelRatings`: Nested mapping `modelId => versionId => list of ratings`.
*   `providerReputation`: Mapping from provider address to `Reputation` struct.
*   `isProviderRegistered`: Mapping to check if an address is a registered provider.

**Structs:**
*   `Model`: Contains model metadata (provider, name, description, active status).
*   `ModelVersion`: Contains version-specific data (version number, price per credit, metadata URI, active status).
*   `Reputation`: Stores total rating sum and total rating count for a provider.

**Events:**
*   `ProviderRegistered`: When a new provider registers.
*   `ModelListed`: When a new model is listed.
*   `ModelVersionAdded`: When a new version is added to a model.
*   `ModelUpdated`: When model details are updated.
*   `ModelDeactivated`: When a model is deactivated.
*   `InferenceCreditsPurchased`: When a user buys credits.
*   `InferenceUsageLogged`: When inference usage is logged (credits deducted).
*   `ProviderEarningsWithdrawn`: When a provider withdraws earnings.
*   `PlatformFeesWithdrawn`: When platform fees are withdrawn.
*   `ModelRated`: When a model version is rated.
*   `ProviderStaked`: When a provider stakes tokens.
*   `ProviderUnstaked`: When a provider unstakes tokens.
*   `PlatformFeeSet`: When the platform fee is updated.
*   `FeeRecipientSet`: When the fee recipient is updated.
*   `RequiredStakeSet`: When the required provider stake is updated.
*   `Paused`/`Unpaused`: Contract pausing status changes.

**Functions (28 Total):**

**I. Provider Management**
1.  `registerProvider()`: Registers the caller as a provider (requires staking).
2.  `isProviderRegistered(address provider)`: View if an address is a registered provider.
3.  `getProviderStake(address provider)`: View a provider's current stake.

**II. Staking**
4.  `stakeTokens(uint256 amount)`: Allows a registered provider to increase their stake.
5.  `unstakeTokens(uint256 amount)`: Allows a registered provider to withdraw stake (requires sufficient stake remaining to list models).
6.  `getRequiredStake()`: View the current required provider stake.

**III. Model Management**
7.  `listModel(string calldata name, string calldata description, string calldata initialVersionNumber, uint256 initialPricePerCredit, string calldata initialMetadataURI)`: Allows a registered provider with sufficient stake to list a new model with its first version.
8.  `addModelVersion(uint256 modelId, string calldata versionNumber, uint256 pricePerCredit, string calldata metadataURI)`: Allows the owner of a model to add a new version.
9.  `updateModel(uint256 modelId, string calldata name, string calldata description)`: Allows the owner of a model to update its general information.
10. `deactivateModel(uint256 modelId)`: Allows the owner to deactivate a model (prevents new purchases).
11. `getModelInfo(uint256 modelId)`: View details of a specific model.
12. `getModelVersionInfo(uint256 modelId, uint256 versionId)`: View details of a specific model version.
13. `getProviderModels(address provider)`: View list of model IDs owned by a provider.
14. `getModelVersionIdByNumber(uint256 modelId, string calldata versionNumber)`: View version ID for a specific version number string.

**IV. Marketplace (Buying Credits)**
15. `buyInferenceCredits(uint256 modelId, uint256 versionId, uint256 numberOfCredits)`: Allows a user to buy inference credits for a specific model version. Requires ERC-20 approval beforehand.

**V. Inference Usage (Off-Chain Interaction)**
16. `logInferenceUsage(uint256 modelId, uint256 versionId, uint256 creditsUsed)`: **(Callable by trusted Oracle/Executor)** Logs that a user has consumed credits off-chain and deducts them from their balance. This function implies interaction with a decentralized AI compute layer or oracle.
17. `getUserCreditsForModel(address user, uint256 modelId, uint256 versionId)`: View remaining inference credits for a user on a specific model version.

**VI. Payments and Withdrawals**
18. `withdrawProviderEarnings()`: Allows a provider to withdraw accumulated earnings from credit sales.
19. `withdrawPlatformFees()`: Allows the fee recipient (or owner) to withdraw accumulated platform fees.
20. `getProviderEarnings(address provider)`: View a provider's pending earnings.
21. `getPlatformFees()`: View accumulated platform fees.

**VII. Reputation System**
22. `submitModelRating(uint256 modelId, uint256 versionId, uint8 rating)`: Allows a user who has purchased credits for a model version to submit a rating (1-5).
23. `getModelAverageRating(uint256 modelId, uint256 versionId)`: View the average rating for a specific model version.
24. `getProviderReputation(address provider)`: View the total rating count and sum for a provider.

**VIII. Admin & Governance**
25. `setPlatformFee(uint16 feeBps)`: Sets the platform fee percentage (by owner).
26. `setFeeRecipient(address recipient)`: Sets the address receiving platform fees (by owner).
27. `setRequiredStake(uint256 amount)`: Sets the minimum required stake for providers (by owner).
28. `pauseContract()`: Pauses the contract (by owner).
29. `unpauseContract()`: Unpauses the contract (by owner).
30. `transferOwnership(address newOwner)`: Transfers contract ownership (by owner).

*(Note: Total functions exceed 20, providing ample features)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Outline and Function Summary are located at the top of this source file.

contract DecentralizedAIModelMarketplace is Ownable, Pausable {
    using SafeMath for uint256;

    // --- Structs ---
    struct Model {
        address provider;
        string name;
        string description;
        bool active; // Can credits be bought?
        uint256[] versionIds; // Ordered list of version IDs
        uint256 latestVersionId; // Convenience pointer to the latest version
    }

    struct ModelVersion {
        uint256 modelId;
        string versionNumber;
        uint256 pricePerCredit; // Price in paymentToken wei
        string metadataURI; // Link to model details, performance metrics, etc.
        bool active; // Can credits for this specific version be bought?
    }

    struct Reputation {
        uint256 totalRatingSum;
        uint256 totalRatingCount;
    }

    // --- State Variables ---
    IERC20 public immutable paymentToken;
    uint16 public platformFeeBps; // Basis points, e.g., 100 = 1%
    address public feeRecipient;
    uint256 public requiredProviderStake;

    uint256 private nextModelId = 1;
    uint256 private nextVersionId = 1; // Global version ID counter

    mapping(uint256 => Model) public models;
    mapping(uint256 => ModelVersion) public modelVersions; // Maps global version ID to version details
    mapping(uint256 => mapping(string => uint256)) public modelVersionIdByNumber; // modelId => versionNumber => versionId

    mapping(address => uint256[]) public providerModels; // Provider address => list of model IDs
    mapping(address => uint256) public providerStake;
    mapping(address => uint256) public providerEarnings; // Unclaimed earnings for providers

    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) public userInferenceCredits; // user => modelId => versionId => remaining credits

    mapping(uint256 => mapping(uint256 => uint8[])) private modelRatings; // modelId => versionId => list of ratings
    mapping(address => Reputation) public providerReputation;

    mapping(address => bool) public isProviderRegistered;
    mapping(address => mapping(uint256 => mapping(uint256 => bool))) private userHasRatedVersion; // Prevent multiple ratings

    uint256 public totalPlatformFees;

    // --- Events ---
    event ProviderRegistered(address indexed provider);
    event ModelListed(uint256 indexed modelId, address indexed provider, string name, string initialVersion);
    event ModelVersionAdded(uint256 indexed modelId, uint256 indexed versionId, string versionNumber, uint256 pricePerCredit);
    event ModelUpdated(uint256 indexed modelId, string name, string description);
    event ModelDeactivated(uint256 indexed modelId);
    event InferenceCreditsPurchased(address indexed buyer, uint256 indexed modelId, uint256 indexed versionId, uint256 numberOfCredits, uint256 totalPrice);
    event InferenceUsageLogged(address indexed user, uint256 indexed modelId, uint256 indexed versionId, uint256 creditsUsed, uint256 remainingCredits);
    event ProviderEarningsWithdrawn(address indexed provider, uint256 amount);
    event PlatformFeesWithdrawn(address indexed recipient, uint256 amount);
    event ModelRated(address indexed rater, uint256 indexed modelId, uint256 indexed versionId, uint8 rating);
    event ProviderStaked(address indexed provider, uint256 amount, uint256 newTotalStake);
    event ProviderUnstaked(address indexed provider, uint256 amount, uint256 newTotalStake);
    event PlatformFeeSet(uint16 feeBps);
    event FeeRecipientSet(address indexed recipient);
    event RequiredStakeSet(uint256 amount);

    // --- Modifiers ---
    modifier onlyRegisteredProvider() {
        require(isProviderRegistered[msg.sender], "Only registered providers can perform this action");
        _;
    }

    modifier onlyModelOwner(uint256 _modelId) {
        require(models[_modelId].provider == msg.sender, "Only model owner can perform this action");
        _;
    }

    modifier modelExists(uint256 _modelId) {
        require(models[_modelId].provider != address(0), "Model does not exist");
        _;
    }

    modifier modelVersionExists(uint256 _versionId) {
        require(modelVersions[_versionId].modelId != 0, "Model version does not exist");
        _;
    }

     modifier modelActive(uint256 _modelId) {
        require(models[_modelId].active, "Model is not active");
        _;
    }

     modifier modelVersionActive(uint256 _versionId) {
        require(modelVersions[_versionId].active, "Model version is not active");
        _;
    }

    // --- Constructor ---
    constructor(address _paymentToken, address _feeRecipient, uint16 _platformFeeBps, uint256 _requiredProviderStake) Ownable(msg.sender) Pausable(false) {
        require(_paymentToken != address(0), "Payment token address cannot be zero");
        require(_feeRecipient != address(0), "Fee recipient address cannot be zero");
        require(_platformFeeBps <= 10000, "Fee must be <= 10000 basis points (100%)");

        paymentToken = IERC20(_paymentToken);
        feeRecipient = _feeRecipient;
        platformFeeBps = _platformFeeBps;
        requiredProviderStake = _requiredProviderStake;
    }

    // --- I. Provider Management ---

    /// @notice Registers the caller as a provider, requiring a minimum stake.
    function registerProvider() external whenNotPaused {
        require(!isProviderRegistered[msg.sender], "Already registered as a provider");
        require(providerStake[msg.sender] >= requiredProviderStake, "Insufficient stake");

        isProviderRegistered[msg.sender] = true;
        emit ProviderRegistered(msg.sender);
    }

    /// @notice Checks if an address is a registered provider.
    /// @param provider The address to check.
    /// @return bool True if registered, false otherwise.
    function isProviderRegistered(address provider) public view returns (bool) {
        return isProviderRegistered[provider];
    }

     /// @notice Gets the current stake amount for a provider.
     /// @param provider The provider's address.
     /// @return uint256 The staked amount.
    function getProviderStake(address provider) public view returns (uint256) {
        return providerStake[provider];
    }


    // --- II. Staking ---

    /// @notice Allows a registered provider to increase their stake.
    /// @param amount The amount of paymentToken to stake.
    function stakeTokens(uint256 amount) external onlyRegisteredProvider whenNotPaused {
        require(amount > 0, "Stake amount must be greater than zero");
        // ERC20 approve must be called by msg.sender before calling this function
        require(paymentToken.transferFrom(msg.sender, address(this), amount), "ERC20 transfer failed");

        providerStake[msg.sender] = providerStake[msg.sender].add(amount);
        emit ProviderStaked(msg.sender, amount, providerStake[msg.sender]);
    }

    /// @notice Allows a registered provider to withdraw part of their stake.
    /// @param amount The amount of paymentToken to unstake.
    function unstakeTokens(uint256 amount) external onlyRegisteredProvider whenNotPaused {
        require(amount > 0, "Unstake amount must be greater than zero");
        require(providerStake[msg.sender] >= amount, "Insufficient stake");
        // Ensure remaining stake is enough if models are listed
        if (providerModels[msg.sender].length > 0) {
             require(providerStake[msg.sender].sub(amount) >= requiredProviderStake, "Remaining stake is below required minimum for listing models");
        }


        providerStake[msg.sender] = providerStake[msg.sender].sub(amount);
        require(paymentToken.transfer(msg.sender, amount), "ERC20 transfer failed");
        emit ProviderUnstaked(msg.sender, amount, providerStake[msg.sender]);
    }

    /// @notice Gets the current required provider stake amount.
    /// @return uint256 The required stake amount in paymentToken wei.
    function getRequiredStake() public view returns (uint256) {
        return requiredProviderStake;
    }


    // --- III. Model Management ---

    /// @notice Allows a registered provider with sufficient stake to list a new AI model.
    /// @param name Model name.
    /// @param description Model description.
    /// @param initialVersionNumber First version number string.
    /// @param initialPricePerCredit Price per credit for the first version.
    /// @param initialMetadataURI URI pointing to model details/metadata.
    function listModel(
        string calldata name,
        string calldata description,
        string calldata initialVersionNumber,
        uint256 initialPricePerCredit,
        string calldata initialMetadataURI
    ) external onlyRegisteredProvider whenNotPaused {
        require(bytes(name).length > 0, "Model name cannot be empty");
        require(bytes(initialVersionNumber).length > 0, "Initial version number cannot be empty");
        require(providerStake[msg.sender] >= requiredProviderStake, "Insufficient stake to list a new model");

        uint256 modelId = nextModelId++;
        uint256 versionId = nextVersionId++;

        models[modelId] = Model({
            provider: msg.sender,
            name: name,
            description: description,
            active: true,
            versionIds: new uint256[](0), // Will add versionId below
            latestVersionId: 0 // Will update below
        });

        models[modelId].versionIds.push(versionId); // Add versionId to the model's list
        models[modelId].latestVersionId = versionId; // Set as latest

        modelVersions[versionId] = ModelVersion({
            modelId: modelId,
            versionNumber: initialVersionNumber,
            pricePerCredit: initialPricePerCredit,
            metadataURI: initialMetadataURI,
            active: true
        });

        modelVersionIdByNumber[modelId][initialVersionNumber] = versionId;

        providerModels[msg.sender].push(modelId);

        emit ModelListed(modelId, msg.sender, name, initialVersionNumber);
        emit ModelVersionAdded(modelId, versionId, initialVersionNumber, initialPricePerCredit);
    }

    /// @notice Allows the owner of a model to add a new version.
    /// @param modelId The ID of the model.
    /// @param versionNumber The new version number string.
    /// @param pricePerCredit Price per credit for this version.
    /// @param metadataURI URI pointing to version-specific details.
    function addModelVersion(
        uint256 modelId,
        string calldata versionNumber,
        uint256 pricePerCredit,
        string calldata metadataURI
    ) external onlyModelOwner(modelId) modelExists(modelId) whenNotPaused {
        require(bytes(versionNumber).length > 0, "Version number cannot be empty");
        require(modelVersionIdByNumber[modelId][versionNumber] == 0, "Version number already exists for this model");

        uint256 versionId = nextVersionId++;

        modelVersions[versionId] = ModelVersion({
            modelId: modelId,
            versionNumber: versionNumber,
            pricePerCredit: pricePerCredit,
            metadataURI: metadataURI,
            active: true
        });

        models[modelId].versionIds.push(versionId);
        models[modelId].latestVersionId = versionId; // Update latest version

        modelVersionIdByNumber[modelId][versionNumber] = versionId;

        emit ModelVersionAdded(modelId, versionId, versionNumber, pricePerCredit);
    }

    /// @notice Allows the owner of a model to update its general information.
    /// @param modelId The ID of the model.
    /// @param name New model name.
    /// @param description New model description.
    function updateModel(uint256 modelId, string calldata name, string calldata description)
        external
        onlyModelOwner(modelId)
        modelExists(modelId)
        whenNotPaused
    {
        require(bytes(name).length > 0, "Model name cannot be empty");

        models[modelId].name = name;
        models[modelId].description = description;

        emit ModelUpdated(modelId, name, description);
    }

    /// @notice Allows the owner to deactivate a model, preventing new credit purchases.
    /// @param modelId The ID of the model to deactivate.
    function deactivateModel(uint256 modelId) external onlyModelOwner(modelId) modelExists(modelId) whenNotPaused {
        require(models[modelId].active, "Model is already inactive");
        models[modelId].active = false;
        // Optionally deactivate all versions too, or leave them individually controllable
        // For simplicity, deactivating model prevents buying any version credits

        emit ModelDeactivated(modelId);
    }

    /// @notice Gets the details of a specific model.
    /// @param modelId The ID of the model.
    /// @return model struct details.
    function getModelInfo(uint256 modelId) public view modelExists(modelId) returns (Model memory) {
        return models[modelId];
    }

     /// @notice Gets the details of a specific model version.
     /// @param modelId The ID of the model.
     /// @param versionId The global ID of the model version.
     /// @return model version struct details.
    function getModelVersionInfo(uint256 modelId, uint256 versionId) public view modelExists(modelId) modelVersionExists(versionId) returns (ModelVersion memory) {
         require(modelVersions[versionId].modelId == modelId, "Version does not belong to this model");
        return modelVersions[versionId];
    }

    /// @notice Gets the list of model IDs owned by a provider.
    /// @param provider The provider's address.
    /// @return uint256[] List of model IDs.
    function getProviderModels(address provider) public view returns (uint256[] memory) {
        return providerModels[provider];
    }

     /// @notice Gets the global version ID for a specific version number string within a model.
     /// @param modelId The ID of the model.
     /// @param versionNumber The version number string.
     /// @return uint256 The global version ID. Returns 0 if not found.
    function getModelVersionIdByNumber(uint256 modelId, string calldata versionNumber)
        public
        view
        modelExists(modelId)
        returns (uint256)
    {
        return modelVersionIdByNumber[modelId][versionNumber];
    }

    // --- IV. Marketplace (Buying Credits) ---

    /// @notice Allows a user to buy inference credits for a specific model version.
    /// @param modelId The ID of the model.
    /// @param versionId The global ID of the model version.
    /// @param numberOfCredits The number of credits to buy.
    function buyInferenceCredits(uint256 modelId, uint256 versionId, uint256 numberOfCredits)
        external
        whenNotPaused
        modelExists(modelId)
        modelVersionExists(versionId)
        modelActive(modelId)
        modelVersionActive(versionId)
    {
        require(modelVersions[versionId].modelId == modelId, "Version does not belong to this model");
        require(numberOfCredits > 0, "Must buy at least one credit");

        ModelVersion storage version = modelVersions[versionId];
        Model storage model = models[modelId];

        uint256 totalPrice = version.pricePerCredit.mul(numberOfCredits);
        uint256 platformFee = totalPrice.mul(platformFeeBps).div(10000);
        uint256 providerAmount = totalPrice.sub(platformFee);

        // Transfer payment from buyer to contract
        // Approve must be called by msg.sender before calling this function
        require(paymentToken.transferFrom(msg.sender, address(this), totalPrice), "ERC20 transfer failed");

        // Credit the provider and platform
        providerEarnings[model.provider] = providerEarnings[model.provider].add(providerAmount);
        totalPlatformFees = totalPlatformFees.add(platformFee);

        // Issue credits to the user
        userInferenceCredits[msg.sender][modelId][versionId] = userInferenceCredits[msg.sender][modelId][versionId].add(numberOfCredits);

        emit InferenceCreditsPurchased(msg.sender, modelId, versionId, numberOfCredits, totalPrice);
    }

    // --- V. Inference Usage (Off-Chain Interaction) ---

    /// @notice Logs that a user has consumed credits off-chain and deducts them.
    /// This function is intended to be called by a trusted oracle or a decentralized compute executor
    /// that interacts with the off-chain AI model and verifies usage. The contract itself doesn't
    /// execute the AI model.
    /// @param user The address of the user whose credits are consumed.
    /// @param modelId The ID of the model used.
    /// @param versionId The global ID of the model version used.
    /// @param creditsUsed The number of credits consumed.
    function logInferenceUsage(address user, uint256 modelId, uint256 versionId, uint256 creditsUsed)
        external // Consider adding modifier like onlyOracle or onlyExecutor later
        whenNotPaused
        modelExists(modelId)
        modelVersionExists(versionId)
    {
        require(modelVersions[versionId].modelId == modelId, "Version does not belong to this model");
        require(creditsUsed > 0, "Must use at least one credit");
        require(userInferenceCredits[user][modelId][versionId] >= creditsUsed, "Insufficient inference credits");

        userInferenceCredits[user][modelId][versionId] = userInferenceCredits[user][modelId][versionId].sub(creditsUsed);

        emit InferenceUsageLogged(user, modelId, versionId, creditsUsed, userInferenceCredits[user][modelId][versionId]);

        // Optional: Add a mechanism here to reward the caller (oracle/executor) for verifying/logging
    }

    /// @notice Gets the remaining inference credits for a user on a specific model version.
    /// @param user The user's address.
    /// @param modelId The ID of the model.
    /// @param versionId The global ID of the model version.
    /// @return uint256 Remaining credits.
    function getUserCreditsForModel(address user, uint256 modelId, uint256 versionId)
        public
        view
        modelExists(modelId)
        modelVersionExists(versionId)
        returns (uint256)
    {
         require(modelVersions[versionId].modelId == modelId, "Version does not belong to this model");
        return userInferenceCredits[user][modelId][versionId];
    }

    // --- VI. Payments and Withdrawals ---

    /// @notice Allows a provider to withdraw their accumulated earnings.
    function withdrawProviderEarnings() external onlyRegisteredProvider whenNotPaused {
        uint256 amount = providerEarnings[msg.sender];
        require(amount > 0, "No earnings to withdraw");

        providerEarnings[msg.sender] = 0;
        require(paymentToken.transfer(msg.sender, amount), "ERC20 transfer failed");

        emit ProviderEarningsWithdrawn(msg.sender, amount);
    }

    /// @notice Allows the fee recipient to withdraw accumulated platform fees.
    function withdrawPlatformFees() external whenNotPaused {
        require(msg.sender == feeRecipient || msg.sender == owner(), "Only fee recipient or owner can withdraw fees");
        uint256 amount = totalPlatformFees;
        require(amount > 0, "No platform fees to withdraw");

        totalPlatformFees = 0;
        require(paymentToken.transfer(feeRecipient, amount), "ERC20 transfer failed");

        emit PlatformFeesWithdrawn(feeRecipient, amount);
    }

     /// @notice Gets a provider's pending earnings.
     /// @param provider The provider's address.
     /// @return uint256 The pending earnings amount.
    function getProviderEarnings(address provider) public view returns (uint256) {
        return providerEarnings[provider];
    }

    /// @notice Gets the total accumulated platform fees.
    /// @return uint256 The platform fees amount.
    function getPlatformFees() public view returns (uint256) {
        return totalPlatformFees;
    }


    // --- VII. Reputation System ---

    /// @notice Allows a user who bought credits to rate a model version (1-5).
    /// @param modelId The ID of the model.
    /// @param versionId The global ID of the model version.
    /// @param rating The rating (1-5).
    function submitModelRating(uint256 modelId, uint256 versionId, uint8 rating)
        external
        whenNotPaused
        modelExists(modelId)
        modelVersionExists(versionId)
    {
        require(modelVersions[versionId].modelId == modelId, "Version does not belong to this model");
        require(rating >= 1 && rating <= 5, "Rating must be between 1 and 5");
        // Require user to have purchased *any* credits for this specific version previously
        // This simple check prevents rating models you haven't interacted with via purchase
        // A more complex system might require *using* credits via logInferenceUsage
        require(userInferenceCredits[msg.sender][modelId][versionId] > 0 || userHasRatedVersion[msg.sender][modelId][versionId], "Must have purchased credits for this version to rate");
        require(!userHasRatedVersion[msg.sender][modelId][versionId], "Already rated this model version");

        modelRatings[modelId][versionId].push(rating);
        userHasRatedVersion[msg.sender][modelId][versionId] = true; // Mark user as having rated this version

        address provider = models[modelId].provider;
        providerReputation[provider].totalRatingSum = providerReputation[provider].totalRatingSum.add(rating);
        providerReputation[provider].totalRatingCount = providerReputation[provider].totalRatingCount.add(1);

        emit ModelRated(msg.sender, modelId, versionId, rating);
    }

    /// @notice Gets the average rating for a specific model version.
    /// @param modelId The ID of the model.
    /// @param versionId The global ID of the model version.
    /// @return uint256 The average rating (multiplied by 100 to keep decimal places), or 0 if no ratings.
    function getModelAverageRating(uint256 modelId, uint256 versionId)
        public
        view
        modelExists(modelId)
        modelVersionExists(versionId)
        returns (uint256)
    {
        require(modelVersions[versionId].modelId == modelId, "Version does not belong to this model");
        uint8[] storage ratings = modelRatings[modelId][versionId];
        if (ratings.length == 0) {
            return 0;
        }
        uint256 sum = 0;
        for (uint i = 0; i < ratings.length; i++) {
            sum = sum.add(ratings[i]);
        }
        // Return average multiplied by 100 for two decimal places precision
        return sum.mul(100).div(ratings.length);
    }

    /// @notice Gets the reputation details for a provider.
    /// @param provider The provider's address.
    /// @return uint256 totalRatingSum The sum of all ratings received.
    /// @return uint256 totalRatingCount The total number of ratings received.
    function getProviderReputation(address provider) public view returns (uint256 totalRatingSum, uint256 totalRatingCount) {
        return (providerReputation[provider].totalRatingSum, providerReputation[provider].totalRatingCount);
    }


    // --- VIII. Admin & Governance ---

    /// @notice Sets the platform fee percentage in basis points.
    /// @param feeBps The new fee percentage (0-10000).
    function setPlatformFee(uint16 feeBps) external onlyOwner {
        require(feeBps <= 10000, "Fee must be <= 10000 basis points");
        platformFeeBps = feeBps;
        emit PlatformFeeSet(feeBps);
    }

    /// @notice Sets the address receiving platform fees.
    /// @param recipient The new fee recipient address.
    function setFeeRecipient(address recipient) external onlyOwner {
        require(recipient != address(0), "Fee recipient address cannot be zero");
        feeRecipient = recipient;
        emit FeeRecipientSet(recipient);
    }

    /// @notice Sets the minimum required stake for providers.
    /// @param amount The new required stake amount in paymentToken wei.
    function setRequiredStake(uint256 amount) external onlyOwner {
        requiredProviderStake = amount;
        emit RequiredStakeSet(amount);
    }

    /// @notice Pauses the contract (emergency stop).
    function pauseContract() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract.
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /// @notice Gets the current platform fee percentage in basis points.
    /// @return uint16 The platform fee percentage.
    function getPlatformFee() public view returns (uint16) {
        return platformFeeBps;
    }

    /// @notice Gets the current fee recipient address.
    /// @return address The fee recipient address.
    function getFeeRecipient() public view returns (address) {
        return feeRecipient;
    }

    /// @notice Checks if the contract is currently paused.
    /// @return bool True if paused, false otherwise.
    function isPaused() public view returns (bool) {
        return paused();
    }

    // --- Getters / Views for counts (Added to meet >= 20 functions) ---
    /// @notice Gets the total number of models listed.
    /// @return uint256 Total models.
    function getTotalModels() public view returns (uint256) {
        return nextModelId - 1;
    }
}
```