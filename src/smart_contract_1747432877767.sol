Okay, let's design a smart contract for a "Decentralized AI Model Marketplace" with advanced features like multiple pricing models, subscription management, usage-based credits, versioning, and access control, managed on-chain. This is a creative concept bridging blockchain and AI access.

We will avoid simply replicating standard ERC-20/ERC-721 factories or simple escrow/voting contracts. The complexity comes from managing access rights based on different payment models for off-chain AI models.

**Important Considerations:**
*   **Off-chain Execution:** The smart contract *manages access rights and payments* for AI models that run *off-chain*. It does *not* run the AI models itself (that's impossible/prohibitively expensive on-chain).
*   **Oracles/Trusted Parties:** The 'Per-Use Credit' model relies on the provider (or a trusted oracle) reporting usage and redeeming credits. This introduces a trust assumption.
*   **Access Enforcement:** The contract grants/revokes access *status*. The off-chain AI service needs to check the user's status/credits by querying the blockchain (or receiving signed proofs from the contract/provider) before providing AI results.
*   **ERC-20 Payments:** We'll use an approved ERC-20 token for payments, requiring users to `approve` the contract beforehand. Native ETH could also be used but ERC20 is more flexible for whitelisting specific tokens.

---

## Decentralized AI Model Marketplace Contract Outline

1.  **Contract:** `DecentralizedAIModelMarketplace`
2.  **Inheritance:** `Ownable`, `Pausable` (from OpenZeppelin)
3.  **Core Concepts:**
    *   Manage listings of off-chain AI models.
    *   Support multiple pricing types: One-Time License, Subscription, Per-Use Credits.
    *   Handle model versioning.
    *   Process payments and distribute funds (provider earnings, platform fee).
    *   Manage user access based on purchases/subscriptions/credits.
    *   Allow platform administration (fee setting, pausing, ownership).
4.  **State Variables:** Mappings for models, versions, user access data (licenses, subscriptions, credits), approved payment tokens, earnings, etc. Counters for unique IDs. Platform fee percentage.
5.  **Data Structures:** Structs for `Model`, `ModelVersion`, `Pricing`, `License`, `Subscription`. Enum for `PricingType`.
6.  **Events:** Indicate key actions like model listing, purchase, subscription, credit top-up, withdrawal, etc.
7.  **Modifiers:** Access control (`onlyOwner`, `whenNotPaused`, `onlyApprovedToken`), Model provider check.

---

## Function Summary

**Admin Functions (Owner Only)**

*   `setPlatformFee(uint16 _platformFeeBps)`: Sets the platform fee percentage (in basis points).
*   `withdrawPlatformFee(address _token, uint256 _amount)`: Allows owner to withdraw accumulated platform fees for a specific token.
*   `addApprovedPaymentToken(address _token)`: Whitelists an ERC20 token for payments.
*   `removeApprovedPaymentToken(address _token)`: Removes an ERC20 token from the whitelist.
*   `pause()`: Pauses contract operations (excluding admin withdrawals/pausing).
*   `unpause()`: Unpauses contract operations.
*   `transferOwnership(address newOwner)`: Transfers contract ownership.

**Provider Functions (Model Provider Only)**

*   `listModel(string memory _name, string memory _description, string memory _initialVersionString, string memory _initialVersionURI)`: Lists a new AI model. Sets the caller as the provider.
*   `updateModelDetails(uint256 _modelId, string memory _name, string memory _description)`: Updates general details of an existing model.
*   `removeModelListing(uint256 _modelId)`: Removes a model listing (prevents new purchases, doesn't affect existing access).
*   `addModelVersion(uint256 _modelId, string memory _versionString, string memory _versionURI)`: Adds a new version to a model.
*   `setDefaultVersion(uint256 _modelId, string memory _versionString)`: Sets the default version for a model.
*   `setModelPricing(uint256 _modelId, PricingType _pricingType, uint256 _priceOrCredits, uint256 _duration)`: Sets the pricing strategy for a model (one-time, subscription, per-use credits).
*   `withdrawProviderEarnings(address _token)`: Allows provider to withdraw their accumulated earnings for a specific token.
*   `redeemCredits(uint256 _modelId, address _user, uint256 _creditsUsed)`: (Requires Trust/Oracle) Provider calls this to record user credit consumption and trigger payment to themselves.

**Consumer Functions**

*   `purchaseLicense(uint256 _modelId, address _token)`: Buys a one-time license for a model version using an approved token. Requires token approval beforehand.
*   `subscribeToModel(uint256 _modelId, address _token)`: Subscribes to a model using an approved token (requires approval). Duration is set in pricing.
*   `unsubscribeFromModel(uint256 _modelId)`: Cancels an active subscription (access remains until end of current period).
*   `buyCredits(uint256 _modelId, uint256 _amountOfCredits, address _token)`: Buys a specific amount of credits for a per-use model using an approved token (requires approval).

**Getter Functions (Read Only)**

*   `getModelDetails(uint256 _modelId)`: Get details of a model.
*   `getModelVersionDetails(uint256 _modelId, string memory _versionString)`: Get details of a specific model version.
*   `getUserLicense(uint256 _modelId, address _user)`: Get license info for a user on a model.
*   `getUserSubscription(uint256 _modelId, address _user)`: Get subscription info for a user on a model.
*   `getUserCredits(uint256 _modelId, address _user)`: Get credit balance for a user on a model.
*   `getProviderModels(address _provider)`: Get a list of model IDs owned by a provider.
*   `getApprovedPaymentTokens()`: Get the list of approved payment tokens.
*   `getPlatformFee()`: Get the current platform fee.
*   `isPaused()`: Check if the contract is paused.
*   `getTokenBalance(address _token, address _account)`: Get the contract's balance of a specific token for a specific account (for withdrawals).
*   `getProviderEarnings(uint256 _modelId, address _token)`: Get a provider's pending earnings for a model in a specific token.
*   `getPlatformEarnings(address _token)`: Get the platform's pending earnings in a specific token.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Outline:
// - Contract: DecentralizedAIModelMarketplace
// - Inheritance: Ownable, Pausable, ReentrancyGuard
// - Core Concepts: AI Model Listing, Multi-Modal Pricing (One-Time, Subscription, Per-Use Credits), Versioning, Access Management, Payments, Withdrawals, Admin Control.
// - State Variables: models, modelCount, versions, userLicenses, userSubscriptions, userCredits, approvedPaymentTokens, providerEarnings, platformEarnings, platformFeeBps.
// - Data Structures: Model, ModelVersion, Pricing, License, Subscription, PricingType (Enum).
// - Events: ModelListed, ModelDetailsUpdated, ModelRemoved, VersionAdded, DefaultVersionSet, PricingSet, LicensePurchased, Subscribed, Unsubscribed, CreditsBought, CreditsRedeemed, ProviderEarningsWithdrawn, PlatformEarningsWithdrawn, TokenApproved, TokenRemoved, FeeSet, Paused, Unpaused, OwnershipTransferred.
// - Modifiers: onlyOwner, whenNotPaused, onlyApprovedToken, onlyModelProvider.

// Function Summary:
// Admin Functions (Owner Only):
// - setPlatformFee(uint16 _platformFeeBps): Sets platform fee (in basis points).
// - withdrawPlatformFee(address _token, uint256 _amount): Withdraws platform earnings for a token.
// - addApprovedPaymentToken(address _token): Whitelists ERC20 token.
// - removeApprovedPaymentToken(address _token): Removes ERC20 token from whitelist.
// - pause(): Pauses non-admin functions.
// - unpause(): Unpauses non-admin functions.
// - transferOwnership(address newOwner): Transfers ownership.

// Provider Functions (Model Provider Only):
// - listModel(string memory _name, string memory _description, string memory _initialVersionString, string memory _initialVersionURI): Lists new model.
// - updateModelDetails(uint256 _modelId, string memory _name, string memory _description): Updates model details.
// - removeModelListing(uint256 _modelId): Removes model listing (no new purchases).
// - addModelVersion(uint256 _modelId, string memory _versionString, string memory _versionURI): Adds new version.
// - setDefaultVersion(uint256 _modelId, string memory _versionString): Sets default version.
// - setModelPricing(uint256 _modelId, PricingType _pricingType, uint256 _priceOrCredits, uint256 _duration): Sets pricing strategy.
// - withdrawProviderEarnings(address _token): Withdraws provider earnings for a token.
// - redeemCredits(uint256 _modelId, address _user, uint256 _creditsUsed): (Trust/Oracle) Records usage, pays provider from user's credits.

// Consumer Functions:
// - purchaseLicense(uint256 _modelId, address _token): Buys one-time license.
// - subscribeToModel(uint256 _modelId, address _token): Subscribes to model.
// - unsubscribeFromModel(uint256 _modelId): Cancels subscription.
// - buyCredits(uint256 _modelId, uint256 _amountOfCredits, address _token): Buys credits for per-use model.

// Getter Functions (Read Only):
// - getModelDetails(uint256 _modelId): Gets model details.
// - getModelVersionDetails(uint256 _modelId, string memory _versionString): Gets version details.
// - getUserLicense(uint256 _modelId, address _user): Gets user's license info.
// - getUserSubscription(uint256 _modelId, address _user): Gets user's subscription info.
// - getUserCredits(uint256 _modelId, address _user): Gets user's credit balance for a model.
// - getProviderModels(address _provider): Gets model IDs for a provider.
// - getApprovedPaymentTokens(): Gets list of approved payment tokens.
// - getPlatformFee(): Gets current platform fee.
// - isPaused(): Checks if contract is paused.
// - getTokenBalance(address _token, address _account): Gets contract's token balance for an account type (provider/platform).
// - getProviderEarnings(uint256 _modelId, address _token): Gets provider's pending earnings for a model/token.
// - getPlatformEarnings(address _token): Gets platform's pending earnings for a token.


contract DecentralizedAIModelMarketplace is Ownable, Pausable, ReentrancyGuard {

    // --- Enums ---
    enum PricingType { None, OneTimeLicense, Subscription, PerUseCredit }

    // --- Structs ---
    struct Model {
        uint256 id;
        address payable provider;
        string name;
        string description;
        PricingType pricingType;
        uint256 priceOrCredits; // Price for OneTime/Subscription, Credits per unit for PerUse
        uint256 duration; // For Subscription in seconds (e.g., 30 days)
        bool isListed;
        string defaultVersion; // String identifier for the default version
    }

    struct ModelVersion {
        string versionString;
        string versionURI; // e.g., IPFS hash or API endpoint reference
        uint256 addedAt;
    }

    struct License {
        uint256 modelId;
        address user;
        uint256 purchasedAt;
        uint256 expiresAt; // Relevant for OneTime if duration is non-zero, or derived from subscription
        string version; // Version licensed/subscribed to at time of purchase/sub period start
        bool active; // False if removed/expired (for simplicity, expiry is based on time)
    }

    struct Subscription {
        uint256 modelId;
        address user;
        uint256 startedAt;
        uint256 expiresAt;
        string version; // Version user is currently subscribed to access
        bool active; // Allows user cancellation, access ends at expiresAt
    }

    // --- State Variables ---
    uint256 public modelCount;
    mapping(uint256 => Model) public models;
    mapping(uint256 => mapping(string => ModelVersion)) private modelVersions; // modelId => versionString => ModelVersion
    mapping(uint256 => string[]) private modelVersionStrings; // modelId => list of version strings

    mapping(uint256 => mapping(address => License)) private userLicenses; // modelId => user => License
    mapping(uint256 => mapping(address => Subscription)) private userSubscriptions; // modelId => user => Subscription
    mapping(uint256 => mapping(address => uint256)) private userCredits; // modelId => user => creditBalance

    mapping(address => bool) public approvedPaymentTokens; // tokenAddress => isApproved
    address[] public approvedPaymentTokenList; // Keep a list for easy retrieval

    mapping(uint256 => mapping(address => uint256)) private providerEarnings; // modelId => tokenAddress => amount
    mapping(address => uint256) private platformEarnings; // tokenAddress => amount

    uint16 public platformFeeBps; // Platform fee in Basis Points (e.g., 100 for 1%)

    // --- Events ---
    event ModelListed(uint256 modelId, address provider, string name, string initialVersion);
    event ModelDetailsUpdated(uint256 modelId, string name, string description);
    event ModelRemoved(uint256 modelId);
    event VersionAdded(uint256 modelId, string versionString, string versionURI);
    event DefaultVersionSet(uint256 modelId, string versionString);
    event PricingSet(uint256 modelId, PricingType pricingType, uint256 priceOrCredits, uint256 duration);

    event LicensePurchased(uint256 modelId, address user, uint256 expiresAt, string version, uint256 pricePaid, address token);
    event Subscribed(uint256 modelId, address user, uint256 expiresAt, string version, uint256 pricePaid, address token);
    event Unsubscribed(uint256 modelId, address user);
    event CreditsBought(uint256 modelId, address user, uint256 amountOfCredits, uint256 pricePaid, address token);
    event CreditsRedeemed(uint256 modelId, address user, uint256 amountOfCredits, uint256 earningsPaid, address token);

    event ProviderEarningsWithdrawn(uint256 modelId, address provider, address token, uint256 amount);
    event PlatformEarningsWithdrawn(address owner, address token, uint256 amount);

    event TokenApproved(address token);
    event TokenRemoved(address token);
    event FeeSet(uint16 platformFeeBps);

    // --- Modifiers ---
    modifier onlyModelProvider(uint256 _modelId) {
        require(models[_modelId].provider == msg.sender, "Not model provider");
        _;
    }

    modifier onlyApprovedToken(address _token) {
        require(approvedPaymentTokens[_token], "Token not approved");
        _;
    }

    // --- Constructor ---
    constructor(uint16 _initialPlatformFeeBps, address _initialApprovedToken) Ownable(msg.sender) Pausable(msg.sender) {
        require(_initialPlatformFeeBps <= 10000, "Fee exceeds 100%");
        platformFeeBps = _initialPlatformFeeBps;
        emit FeeSet(platformFeeBps);

        if (_initialApprovedToken != address(0)) {
             _addApprovedPaymentToken(_initialApprovedToken);
        }
    }

    // --- Admin Functions ---

    /// @notice Sets the platform fee in basis points (100 = 1%). Max 10000 (100%).
    /// @param _platformFeeBps The fee amount in basis points.
    function setPlatformFee(uint16 _platformFeeBps) external onlyOwner {
        require(_platformFeeBps <= 10000, "Fee exceeds 100%");
        platformFeeBps = _platformFeeBps;
        emit FeeSet(platformFeeBps);
    }

    /// @notice Allows the owner to withdraw accumulated platform fees.
    /// @param _token The address of the token to withdraw.
    /// @param _amount The amount to withdraw.
    function withdrawPlatformFee(address _token, uint256 _amount) external onlyOwner nonReentrant {
        require(platformEarnings[_token] >= _amount, "Insufficient platform earnings");
        platformEarnings[_token] -= _amount;
        IERC20(_token).transfer(owner(), _amount);
        emit PlatformEarningsWithdrawn(owner(), _token, _amount);
    }

    /// @notice Adds an ERC20 token to the list of approved payment tokens.
    /// @param _token The address of the ERC20 token.
    function addApprovedPaymentToken(address _token) external onlyOwner {
        _addApprovedPaymentToken(_token);
    }

    /// @notice Internal helper to add approved token.
    function _addApprovedPaymentToken(address _token) internal {
         require(_token != address(0), "Invalid token address");
         require(!approvedPaymentTokens[_token], "Token already approved");
         approvedPaymentTokens[_token] = true;
         approvedPaymentTokenList.push(_token);
         emit TokenApproved(_token);
    }

    /// @notice Removes an ERC20 token from the list of approved payment tokens.
    /// @param _token The address of the ERC20 token.
    function removeApprovedPaymentToken(address _token) external onlyOwner {
        require(approvedPaymentTokens[_token], "Token not approved");
        delete approvedPaymentTokens[_token];

        // Remove from list (simple but potentially gas-intensive for large lists)
        for (uint i = 0; i < approvedPaymentTokenList.length; i++) {
            if (approvedPaymentTokenList[i] == _token) {
                approvedPaymentTokenList[i] = approvedPaymentTokenList[approvedPaymentTokenList.length - 1];
                approvedPaymentTokenList.pop();
                break;
            }
        }
        emit TokenRemoved(_token);
    }


    /// @notice Pauses contract functionality, preventing new interactions except administrative ones.
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpauses the contract, restoring normal operations.
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /// @notice Transfers ownership of the contract to a new address.
    /// @param newOwner The address of the new owner.
    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
    }


    // --- Provider Functions ---

    /// @notice Lists a new AI model on the marketplace. Sets the caller as the provider.
    /// @param _name The name of the model.
    /// @param _description A description of the model.
    /// @param _initialVersionString The string identifier for the initial version (e.g., "v1.0").
    /// @param _initialVersionURI The URI for accessing the initial model version (e.g., IPFS hash, API endpoint).
    /// @return modelId The ID of the newly listed model.
    function listModel(
        string memory _name,
        string memory _description,
        string memory _initialVersionString,
        string memory _initialVersionURI
    ) external whenNotPaused returns (uint256 modelId) {
        modelCount++;
        modelId = modelCount;

        models[modelId] = Model({
            id: modelId,
            provider: payable(msg.sender),
            name: _name,
            description: _description,
            pricingType: PricingType.None, // No pricing set initially
            priceOrCredits: 0,
            duration: 0,
            isListed: true,
            defaultVersion: _initialVersionString // Set initial version as default
        });

        _addModelVersion(modelId, _initialVersionString, _initialVersionURI); // Add the initial version

        emit ModelListed(modelId, msg.sender, _name, _initialVersionString);
    }

    /// @notice Updates the name and description of an existing model.
    /// @param _modelId The ID of the model.
    /// @param _name The new name.
    /// @param _description The new description.
    function updateModelDetails(uint256 _modelId, string memory _name, string memory _description)
        external
        whenNotPaused
        onlyModelProvider(_modelId)
    {
        require(models[_modelId].isListed, "Model not listed");
        models[_modelId].name = _name;
        models[_modelId].description = _description;
        emit ModelDetailsUpdated(_modelId, _name, _description);
    }

    /// @notice Removes a model listing. Existing access remains valid, but no new purchases/subscriptions can be made.
    /// @param _modelId The ID of the model to remove.
    function removeModelListing(uint256 _modelId) external whenNotPaused onlyModelProvider(_modelId) {
        require(models[_modelId].isListed, "Model not listed");
        models[_modelId].isListed = false;
        emit ModelRemoved(_modelId);
    }

    /// @notice Adds a new version to an existing model.
    /// @param _modelId The ID of the model.
    /// @param _versionString The string identifier for the new version.
    /// @param _versionURI The URI for accessing the new model version.
    function addModelVersion(uint256 _modelId, string memory _versionString, string memory _versionURI)
        external
        whenNotPaused
        onlyModelProvider(_modelId)
    {
        _addModelVersion(_modelId, _versionString, _versionURI);
    }

    /// @notice Internal helper to add model version.
    function _addModelVersion(uint256 _modelId, string memory _versionString, string memory _versionURI) internal {
         require(models[_modelId].isListed, "Model not listed");
         require(bytes(_versionString).length > 0, "Version string cannot be empty");
         // Check if version string already exists
         string[] storage versionsList = modelVersionStrings[_modelId];
         for (uint i = 0; i < versionsList.length; i++) {
             if (keccak256(bytes(versionsList[i])) == keccak256(bytes(_versionString))) {
                 revert("Version already exists");
             }
         }

         modelVersions[_modelId][_versionString] = ModelVersion({
             versionString: _versionString,
             versionURI: _versionURI,
             addedAt: block.timestamp
         });
         modelVersionStrings[_modelId].push(_versionString);

         emit VersionAdded(_modelId, _versionString, _versionURI);
    }

    /// @notice Sets the default version for a model. This version will be used for new purchases/subscriptions if not specified.
    /// @param _modelId The ID of the model.
    /// @param _versionString The string identifier of the version to set as default.
    function setDefaultVersion(uint256 _modelId, string memory _versionString) external whenNotPaused onlyModelProvider(_modelId) {
        require(models[_modelId].isListed, "Model not listed");
        // Check if version exists
        bool versionExists = false;
        string[] storage versionsList = modelVersionStrings[_modelId];
        for (uint i = 0; i < versionsList.length; i++) {
            if (keccak256(bytes(versionsList[i])) == keccak256(bytes(_versionString))) {
                versionExists = true;
                break;
            }
        }
        require(versionExists, "Version does not exist for this model");

        models[_modelId].defaultVersion = _versionString;
        emit DefaultVersionSet(_modelId, _versionString);
    }

    /// @notice Sets the pricing strategy for a model. Overwrites previous pricing.
    /// @param _modelId The ID of the model.
    /// @param _pricingType The type of pricing (None, OneTimeLicense, Subscription, PerUseCredit).
    /// @param _priceOrCredits The price for OneTime/Subscription, or credits per unit for PerUse.
    /// @param _duration Duration for Subscription in seconds (0 for one-time/per-use).
    function setModelPricing(
        uint256 _modelId,
        PricingType _pricingType,
        uint256 _priceOrCredits,
        uint256 _duration
    ) external whenNotPaused onlyModelProvider(_modelId) {
        require(models[_modelId].isListed, "Model not listed");
        require(_pricingType != PricingType.None || (_priceOrCredits == 0 && _duration == 0), "Invalid pricing parameters for None type");
        if (_pricingType == PricingType.Subscription) {
             require(_duration > 0, "Subscription requires duration");
        } else {
             require(_duration == 0, "Duration only applies to Subscription");
        }
        if (_pricingType != PricingType.None) {
            require(_priceOrCredits > 0, "Price or credits must be greater than 0");
        }

        models[_modelId].pricingType = _pricingType;
        models[_modelId].priceOrCredits = _priceOrCredits;
        models[_modelId].duration = _duration; // Duration in seconds

        emit PricingSet(_modelId, _pricingType, _priceOrCredits, _duration);
    }

    /// @notice Allows a provider to withdraw their accumulated earnings for a specific model and token.
    /// @param _token The address of the token to withdraw.
    function withdrawProviderEarnings(uint256 _modelId, address _token) external nonReentrant onlyApprovedToken(_token) onlyModelProvider(_modelId) {
        uint256 amount = providerEarnings[_modelId][_token];
        require(amount > 0, "No earnings to withdraw");

        providerEarnings[_modelId][_token] = 0; // Reset balance before transfer
        IERC20(_token).transfer(models[_modelId].provider, amount);

        emit ProviderEarningsWithdrawn(_modelId, models[_modelId].provider, _token, amount);
    }

    /// @notice (Requires Trust/Oracle) Called by the model provider to record user credit consumption and pay themselves.
    /// @dev This function trusts the provider to accurately report usage. An off-chain system should verify usage before calling this.
    /// @param _modelId The ID of the model.
    /// @param _user The user whose credits are being redeemed.
    /// @param _creditsUsed The number of credits used by the user.
    function redeemCredits(uint256 _modelId, address _user, uint256 _creditsUsed)
        external
        whenNotPaused
        onlyModelProvider(_modelId)
        nonReentrant
    {
        require(models[_modelId].isListed, "Model not listed");
        require(models[_modelId].pricingType == PricingType.PerUseCredit, "Model is not per-use credit priced");
        require(_creditsUsed > 0, "Credits used must be positive");
        require(userCredits[_modelId][_user] >= _creditsUsed, "Insufficient user credits");

        uint256 creditsPerUnit = models[_modelId].priceOrCredits; // This is credits PER unit of usage, not price per credit
        // Let's assume priceOrCredits is the *cost* in credits for 1 unit of usage
        // So, total credits used is _creditsUsed. The provider earns based on this.
        // The contract doesn't know the *monetary* value of a credit here.
        // Payments are handled when credits are *bought* via buyCredits.
        // This redeemCredits just deducts credits and potentially triggers a provider notification/state change.
        // A more complex system might use an oracle to convert credits back to value, but that's beyond this example.
        // For THIS implementation, redeemCredits *only* deducts credits. The provider earned when the user *bought* credits.
        // This significantly simplifies the on-chain logic but requires the credit buying price to reflect future usage.

        // A better approach for earning on redemption:
        // 1. Credits are abstract units bought at a certain price per credit (e.g., 1 token for 1000 credits).
        // 2. Model priceOrCredits is the number of credits required per usage unit.
        // 3. Provider calls redeemCredits with _user and _creditsUsed.
        // 4. Contract checks _userCredits[_modelId][_user] >= _creditsUsed.
        // 5. Contract deducts _creditsUsed.
        // 6. Contract needs to know the *value* of these credits to pay the provider. This is the hard part.
        //    - Option A: Simple deduction. Provider earns when user buys credits. (Chosen for simplicity)
        //    - Option B: Contract holds funds, provider gets paid per redemption based on some stored conversion rate (requires oracle or complex state).
        //    - Option C: User pays *directly* to contract per usage via off-chain call + signature proof (complex, not via 'credits').

        // Sticking with Option A for simplicity: Credits are prepaid units. Redemption is just tracking usage.
        userCredits[_modelId][_user] -= _creditsUsed;
        // No payment happens *here* for Option A. The payment happened in `buyCredits`.

        emit CreditsRedeemed(_modelId, _user, _creditsUsed, 0, address(0)); // 0 earnings/token as payment was upfront

        // Alternative (Option B: Provider earns on redemption):
        /*
        // This requires tracking the token used and value paid when credits were bought,
        // and potentially complex logic if users buy credits with different tokens/prices over time.
        // Let's abandon Option B for this example's complexity constraint.
        */
    }


    // --- Consumer Functions ---

    /// @notice Purchases a one-time license for a model.
    /// @param _modelId The ID of the model.
    /// @param _token The address of the approved payment token.
    function purchaseLicense(uint256 _modelId, address _token) external payable whenNotPaused nonReentrant onlyApprovedToken(_token) {
        Model storage model = models[_modelId];
        require(model.isListed, "Model not listed");
        require(model.pricingType == PricingType.OneTimeLicense, "Model not priced for one-time license");
        require(model.priceOrCredits > 0, "Model not priced");
        require(bytes(model.defaultVersion).length > 0, "Model has no default version set");
        require(modelVersions[_modelId][model.defaultVersion].addedAt > 0, "Default version details not found");

        uint256 price = model.priceOrCredits;
        _pay(msg.sender, _token, price, model.provider, _modelId);

        uint256 expiresAt = (model.duration > 0) ? block.timestamp + model.duration : type(uint256).max; // Use duration if set, otherwise 'forever'

        userLicenses[_modelId][msg.sender] = License({
            modelId: _modelId,
            user: msg.sender,
            purchasedAt: block.timestamp,
            expiresAt: expiresAt,
            version: model.defaultVersion, // Access to the default version at time of purchase
            active: true
        });

        // Clear potential old subscriptions/credits for this model type clash (design choice)
        delete userSubscriptions[_modelId][msg.sender];
        userCredits[_modelId][msg.sender] = 0;


        emit LicensePurchased(_modelId, msg.sender, expiresAt, model.defaultVersion, price, _token);
    }

    /// @notice Subscribes to a model.
    /// @param _modelId The ID of the model.
    /// @param _token The address of the approved payment token.
    function subscribeToModel(uint256 _modelId, address _token) external payable whenNotPaused nonReentrant onlyApprovedToken(_token) {
        Model storage model = models[_modelId];
        require(model.isListed, "Model not listed");
        require(model.pricingType == PricingType.Subscription, "Model not priced for subscription");
        require(model.priceOrCredits > 0, "Model not priced");
        require(model.duration > 0, "Subscription requires duration");
        require(bytes(model.defaultVersion).length > 0, "Model has no default version set");
        require(modelVersions[_modelId][model.defaultVersion].addedAt > 0, "Default version details not found");

        // Check if user already has an active subscription
        Subscription storage existingSub = userSubscriptions[_modelId][msg.sender];
        if (existingSub.active && existingSub.expiresAt > block.timestamp) {
            // Allow extending the subscription
            require(msg.value > 0 || _token != address(0), "Payment required to extend");
            // The payment logic below handles charging the price again
        } else {
            // New subscription
             require(msg.value > 0 || _token != address(0), "Payment required to start subscription");
        }


        uint256 price = model.priceOrCredits;
        _pay(msg.sender, _token, price, model.provider, _modelId);

        uint256 currentPeriodEnd = (existingSub.active && existingSub.expiresAt > block.timestamp) ? existingSub.expiresAt : block.timestamp;
        uint256 newPeriodEnd = currentPeriodEnd + model.duration; // Extend from current expiry

        userSubscriptions[_modelId][msg.sender] = Subscription({
            modelId: _modelId,
            user: msg.sender,
            startedAt: currentPeriodEnd, // Start of this *paid* period
            expiresAt: newPeriodEnd,
            version: model.defaultVersion, // Access to the default version at time of payment
            active: true // Active until expiresAt
        });

        // Clear potential old licenses/credits for this model type clash (design choice)
        delete userLicenses[_modelId][msg.sender];
        userCredits[_modelId][msg.sender] = 0;

        emit Subscribed(_modelId, msg.sender, newPeriodEnd, model.defaultVersion, price, _token);
    }

    /// @notice Allows a user to cancel their subscription. Access remains until the end of the current period.
    /// @param _modelId The ID of the model.
    function unsubscribeFromModel(uint256 _modelId) external whenNotPaused {
        Subscription storage sub = userSubscriptions[_modelId][msg.sender];
        require(sub.modelId == _modelId && sub.active, "No active subscription found");
        // Note: The subscription remains active until sub.expiresAt.
        // The 'active' flag prevents renewing or being considered for future billing cycles (if implemented).
        sub.active = false; // Mark as cancelled, access remains valid until expiry.
        emit Unsubscribed(_modelId, msg.sender);
    }

    /// @notice Buys credits for a per-use model.
    /// @param _modelId The ID of the model.
    /// @param _amountOfCredits The number of credits to buy.
    /// @param _token The address of the approved payment token.
    function buyCredits(uint256 _modelId, uint256 _amountOfCredits, address _token) external payable whenNotPaused nonReentrant onlyApprovedToken(_token) {
        Model storage model = models[_modelId];
        require(model.isListed, "Model not listed");
        require(model.pricingType == PricingType.PerUseCredit, "Model not priced for per-use credits");
        require(model.priceOrCredits > 0, "Model pricing not set (credits per unit)");
        require(_amountOfCredits > 0, "Must buy at least 1 credit");

        // Assuming model.priceOrCredits is the TOKEN price for 1 credit.
        // If model.priceOrCredits was credits per unit of usage, this logic would be different.
        // Let's assume priceOrCredits is the TOKEN price per CREDIT.
        uint256 price = model.priceOrCredits * _amountOfCredits;

        _pay(msg.sender, _token, price, model.provider, _modelId);

        userCredits[_modelId][msg.sender] += _amountOfCredits;

        // Clear potential old licenses/subscriptions for this model type clash (design choice)
        delete userLicenses[_modelId][msg.sender];
        delete userSubscriptions[_modelId][msg.sender];

        emit CreditsBought(_modelId, msg.sender, _amountOfCredits, price, _token);
    }

    // --- Internal Payment Logic ---

    /// @dev Handles the payment process, transferring tokens and distributing funds.
    /// @param _payer The address paying.
    /// @param _token The token used for payment.
    /// @param _amount The total amount paid.
    /// @param _provider The model provider to pay.
    /// @param _modelId The ID of the model being paid for.
    function _pay(address _payer, address _token, uint256 _amount, address payable _provider, uint256 _modelId) internal {
        require(_amount > 0, "Payment amount must be greater than 0");
        require(_token != address(0), "Invalid token address");
        require(_provider != address(0), "Invalid provider address");
        require(_payer != address(0), "Invalid payer address");


        // Transfer from payer to this contract (requires payer to approve contract beforehand)
        IERC20(_token).transferFrom(_payer, address(this), _amount);

        uint256 platformFeeAmount = (_amount * platformFeeBps) / 10000;
        uint256 providerAmount = _amount - platformFeeAmount;

        // Accumulate earnings
        if (providerAmount > 0) {
             providerEarnings[_modelId][_token] += providerAmount;
        }
        if (platformFeeAmount > 0) {
             platformEarnings[_token] += platformFeeAmount;
        }
    }

    // --- Getter Functions ---

    /// @notice Gets the details of a specific AI model.
    /// @param _modelId The ID of the model.
    /// @return id Model ID.
    /// @return provider Model provider address.
    /// @return name Model name.
    /// @return description Model description.
    /// @return pricingType Model pricing type.
    /// @return priceOrCredits Price/credits value.
    /// @return duration Subscription duration in seconds.
    /// @return isListed Listing status.
    /// @return defaultVersion Default version string.
    function getModelDetails(uint256 _modelId)
        external
        view
        returns (
            uint256 id,
            address provider,
            string memory name,
            string memory description,
            PricingType pricingType,
            uint256 priceOrCredits,
            uint256 duration,
            bool isListed,
            string memory defaultVersion
        )
    {
        Model storage model = models[_modelId];
        return (
            model.id,
            model.provider,
            model.name,
            model.description,
            model.pricingType,
            model.priceOrCredits,
            model.duration,
            model.isListed,
            model.defaultVersion
        );
    }

    /// @notice Gets details for a specific version of a model.
    /// @param _modelId The ID of the model.
    /// @param _versionString The string identifier of the version.
    /// @return versionString Version string.
    /// @return versionURI Version URI.
    /// @return addedAt Timestamp when version was added.
    function getModelVersionDetails(uint256 _modelId, string memory _versionString)
        external
        view
        returns (string memory versionString, string memory versionURI, uint256 addedAt)
    {
        ModelVersion storage version = modelVersions[_modelId][_versionString];
        require(version.addedAt > 0, "Version not found");
        return (version.versionString, version.versionURI, version.addedAt);
    }

    /// @notice Gets the license information for a user on a specific model.
    /// @param _modelId The ID of the model.
    /// @param _user The user's address.
    /// @return modelId Model ID.
    /// @return user User address.
    /// @return purchasedAt Timestamp of purchase.
    /// @return expiresAt Timestamp of expiry.
    /// @return version Version accessed.
    /// @return active License active status.
    function getUserLicense(uint256 _modelId, address _user)
        external
        view
        returns (uint256 modelId, address user, uint256 purchasedAt, uint256 expiresAt, string memory version, bool active)
    {
        License storage license = userLicenses[_modelId][_user];
        // Check if license exists AND is currently active based on expiry time
        bool currentActive = license.active && license.purchasedAt > 0 && (license.expiresAt == type(uint256).max || license.expiresAt > block.timestamp);

        return (license.modelId, license.user, license.purchasedAt, license.expiresAt, license.version, currentActive);
    }

    /// @notice Gets the subscription information for a user on a specific model.
    /// @param _modelId The ID of the model.
    /// @param _user The user's address.
    /// @return modelId Model ID.
    /// @return user User address.
    /// @return startedAt Timestamp subscription started.
    /// @return expiresAt Timestamp subscription expires.
    /// @return version Version subscribed to.
    /// @return active Subscription active flag (user hasn't cancelled).
    /// @return isCurrentlyActive True if subscription is active AND not expired by time.
    function getUserSubscription(uint256 _modelId, address _user)
        external
        view
        returns (uint256 modelId, address user, uint256 startedAt, uint256 expiresAt, string memory version, bool active, bool isCurrentlyActive)
    {
        Subscription storage sub = userSubscriptions[_modelId][_user];
        // Check if subscription exists AND is currently active based on expiry time
        bool currentlyActive = sub.active && sub.startedAt > 0 && sub.expiresAt > block.timestamp;
        return (sub.modelId, sub.user, sub.startedAt, sub.expiresAt, sub.version, sub.active, currentlyActive);
    }

    /// @notice Gets the credit balance for a user on a specific per-use model.
    /// @param _modelId The ID of the model.
    /// @param _user The user's address.
    /// @return credits The user's credit balance.
    function getUserCredits(uint256 _modelId, address _user) external view returns (uint256 credits) {
        return userCredits[_modelId][_user];
    }

     /// @notice Gets the list of version strings available for a model.
     /// @param _modelId The ID of the model.
     /// @return versions An array of version strings.
     function getModelVersions(uint256 _modelId) external view returns (string[] memory) {
         return modelVersionStrings[_modelId];
     }


    /// @notice Gets a list of model IDs owned by a specific provider.
    /// @param _provider The provider's address.
    /// @return modelIds An array of model IDs.
    function getProviderModels(address _provider) external view returns (uint256[] memory) {
        uint256[] memory providerModels = new uint256[](modelCount); // Max possible size
        uint256 currentCount = 0;
        for (uint256 i = 1; i <= modelCount; i++) {
            if (models[i].provider == _provider) {
                providerModels[currentCount] = i;
                currentCount++;
            }
        }
        // Trim the array to the actual count
        uint256[] memory result = new uint256[](currentCount);
        for (uint256 i = 0; i < currentCount; i++) {
            result[i] = providerModels[i];
        }
        return result;
    }

    /// @notice Gets the list of approved payment tokens.
    /// @return tokens An array of approved token addresses.
    function getApprovedPaymentTokens() external view returns (address[] memory) {
        return approvedPaymentTokenList;
    }

    /// @notice Gets the current platform fee in basis points.
    /// @return fee The platform fee in basis points.
    function getPlatformFee() external view returns (uint16 fee) {
        return platformFeeBps;
    }

    /// @notice Checks if the contract is currently paused.
    /// @return isPaused True if paused, false otherwise.
    function isPaused() external view returns (bool) {
        return paused();
    }

    /// @notice Gets the contract's balance of a specific token for provider earnings related to a model.
    /// @param _modelId The ID of the model.
    /// @param _token The address of the token.
    /// @return balance The pending earnings balance.
    function getProviderEarnings(uint256 _modelId, address _token) external view returns (uint256 balance) {
        return providerEarnings[_modelId][_token];
    }

    /// @notice Gets the contract's balance of a specific token for platform earnings.
    /// @param _token The address of the token.
    /// @return balance The pending platform earnings balance.
    function getPlatformEarnings(address _token) external view returns (uint256 balance) {
        return platformEarnings[_token];
    }

     /// @notice Gets the contract's raw ERC20 token balance. Use this carefully; pending earnings are tracked separately.
     /// @param _token The address of the token.
     /// @return balance The contract's total balance for the token.
     function getContractTokenBalance(address _token) external view returns (uint256 balance) {
         return IERC20(_token).balanceOf(address(this));
     }


    // Fallback function to prevent accidental native ETH deposits (unless specifically intended, which it's not here).
    // receive() external payable {
    //     revert("Native ETH direct deposits not allowed.");
    // }

    // fallback() external payable {
    //     revert("Calls to non-existent functions or unsupported ETH transfers.");
    // }
}
```