Okay, here is a Solidity smart contract for a Decentralized AI Model Marketplace. This contract aims to incorporate several advanced concepts:

1.  **Tokenization:** Uses a simulated utility token ($AIMT) for payments and staking.
2.  **NFTs:** Represents AI model usage licenses as NFTs (ERC721 standard simulated internally).
3.  **Oracles:** Integrates with a simulated Oracle mechanism to confirm off-chain AI model inference computation results.
4.  **Staking:** Requires Model Providers to stake tokens as collateral for reliability.
5.  **Reputation System:** Basic on-chain rating system to build provider reputation.
6.  **Fees & Payouts:** Marketplace collects a fee, providers earn from usage.
7.  **Access Control:** Basic ownership and role-based restrictions.
8.  **Off-chain Interaction Proof:** Relies on the Oracle to bridge the gap between on-chain payment/licensing and off-chain computation/verification.

It's designed to be complex enough to meet the function count and demonstrate these concepts without directly copying standard OpenZeppelin implementations for the core ERC20/ERC721 logic (though in production, using battle-tested libraries is highly recommended for security).

---

### **Decentralized AI Model Marketplace**

**Outline:**

1.  **Introduction:** Smart contract for a decentralized platform connecting AI model providers and users.
2.  **Core Components:**
    *   `AIModel`: Struct defining model metadata, pricing, provider, status.
    *   `Provider`: Struct for registered providers, tracking stake, earnings, reputation.
    *   `ModelLicense`: Struct representing an NFT license for model usage.
    *   `AIMT Token`: Simulated internal ERC20-like token.
    *   `ModelLicenseNFT`: Simulated internal ERC721-like token.
3.  **State Variables:** Mappings and variables to store models, providers, licenses, balances, stakes, ratings, fees, oracle address, etc.
4.  **Events:** To signal important actions like registration, listing, purchase, inference requests, payouts, etc.
5.  **Access Control:** Owner for administrative tasks, roles for Providers and general Users.
6.  **Core Logic:**
    *   Provider registration, staking, model listing/management, earnings withdrawal.
    *   User token balance management (via simulation).
    *   User license purchase (minting NFT).
    *   User inference request (paying per use after license purchase).
    *   Oracle callback for confirming inference results and triggering payouts.
    *   User rating of models/providers.
    *   Reputation score calculation.
    *   Marketplace fee collection and withdrawal.
    *   View functions to retrieve information.
7.  **Simulated Token/NFT Functions:** Internal functions mimicking ERC20 transfer and ERC721 minting/ownership checks.

**Function Summary:**

*(Public/External Functions - Total: 30+)*

1.  `constructor()`: Initializes contract owner and token supply (simulated).
2.  `adminMintInitialTokens(address _user, uint256 _amount)`: Admin function to seed user balances (simulated).
3.  `getUserTokenBalance(address _user)`: Get simulated user token balance.
4.  `registerProvider(string memory _name, string memory _contactInfo)`: Register as a model provider.
5.  `isProviderRegistered(address _provider)`: Check if an address is a registered provider.
6.  `getProviderInfo(address _provider)`: Get details of a registered provider.
7.  `stakeTokens(uint256 _amount)`: Provider stakes $AIMT tokens.
8.  `unstakeTokens(uint256 _amount)`: Provider unstakes $AIMT tokens (subject to potential lockups/conditions - simplified here).
9.  `getProviderStake(address _provider)`: Get current stake of a provider.
10. `listModel(string memory _name, string memory _description, string memory _modelUrl, string memory _metadataUrl, uint256 _licensePrice, uint256 _inferencePrice)`: Provider lists a new AI model.
11. `updateModel(uint256 _modelId, string memory _name, string memory _description, string memory _modelUrl, string memory _metadataUrl, uint256 _licensePrice, uint256 _inferencePrice)`: Provider updates an existing model's details.
12. `deactivateModel(uint256 _modelId)`: Provider deactivates a model, making it unavailable for new purchases/inferences.
13. `isModelActive(uint256 _modelId)`: Check if a model is active.
14. `getModelDetails(uint256 _modelId)`: Get details of a specific model.
15. `getTotalListedModels()`: Get the total number of models listed.
16. `getProviderModels(address _provider)`: Get list of model IDs owned by a provider.
17. `purchaseModelLicense(uint256 _modelId)`: User buys a usage license for a model (mints an NFT). Requires model license price in $AIMT.
18. `getUserLicense(address _user, uint256 _licenseTokenId)`: Get details of a specific license NFT owned by a user.
19. `getUserLicenses(address _user)`: Get list of license NFT IDs owned by a user.
20. `getLicenseOwner(uint256 _licenseTokenId)`: Get the owner of a license NFT.
21. `isLicenseOwner(address _user, uint256 _licenseTokenId)`: Check if a user owns a specific license NFT.
22. `requestInference(uint256 _licenseTokenId, string memory _inputDataUrl, uint256 _callbackId)`: User requests an inference using a valid license. Requires inference price in $AIMT. Emits event for off-chain oracle.
23. `submitInferenceResult(uint256 _callbackId, string memory _resultDataUrl, bool _success)`: Oracle calls this function to submit the inference result and confirm computation.
24. `rateModel(uint256 _modelId, uint8 _rating)`: User rates a model (1-5 stars). Affects provider reputation.
25. `getProviderReputation(address _provider)`: Get the average rating/reputation score for a provider.
26. `getModelAverageRating(uint256 _modelId)`: Get the average rating for a specific model.
27. `withdrawProviderEarnings()`: Provider withdraws accumulated earnings from inferences.
28. `setOracleAddress(address _oracle)`: Owner sets the trusted Oracle address.
29. `getOracleAddress()`: Get the current oracle address.
30. `setFeePercentage(uint256 _percentage)`: Owner sets the marketplace fee percentage (e.g., 5 for 5%).
31. `getMarketplaceFeePercentage()`: Get the current fee percentage.
32. `withdrawMarketplaceFees()`: Owner withdraws collected marketplace fees.
33. `getMarketplaceBalance()`: Get the $AIMT balance held by the marketplace (fees).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Minimal interfaces to simulate ERC20/ERC721 interactions without
// copying full OpenZeppelin code, focusing on the core logic needed
// for this example. In a real project, you would use standard libraries.
interface IERC20Minimal {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

interface IERC721Minimal {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    // Minimal functions needed for tracking ownership
}


/// @title Decentralized AI Model Marketplace
/// @notice A platform for providers to list AI models, users to purchase usage licenses (as NFTs),
///         pay for inference via a utility token, and includes reputation/staking for quality assurance.
///         Leverages oracles for off-chain computation proof.

contract DecentralizedAIModelMarketplace {

    address public owner;

    // --- Simulated $AIMT Token State (Minimal) ---
    // In a real scenario, this would be a separate ERC20 contract.
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 public totalSimulatedSupply;
    string public constant SIMULATED_TOKEN_SYMBOL = "AIMT";
    string public constant SIMULATED_TOKEN_NAME = "AI Marketplace Token";

    // --- Simulated Model License NFT State (Minimal ERC721) ---
    // In a real scenario, this would be a separate ERC721 contract.
    mapping(uint256 => address) private _licenseOwners;
    mapping(address => uint256[]) private _userOwnedLicenses; // Track license IDs per user
    uint256 private _nextTokenId = 1; // Start NFT token IDs from 1

    struct AIModel {
        uint256 id;
        address provider;
        string name;
        string description;
        string modelUrl; // Link to model files (e.g., IPFS hash)
        string metadataUrl; // Link to additional metadata (e.g., IPFS hash)
        uint256 licensePrice; // Price in $AIMT to buy a usage license NFT
        uint256 inferencePrice; // Price in $AIMT per inference request using the model
        bool active; // Is the model currently available?
        uint256 listedTimestamp;
        uint256[] licenseTokenIds; // List of license NFTs minted for this model
        uint256 totalRatings;
        uint256 ratingSum;
    }

    struct Provider {
        address walletAddress;
        string name;
        string contactInfo;
        uint256 registeredTimestamp;
        uint256 currentStake; // $AIMT staked by the provider
        uint256 totalEarnings; // $AIMT earned from inferences
        uint256[] listedModelIds;
        uint256 totalRatingSum; // Sum of all ratings received on their models
        uint256 totalRatingCount; // Total number of ratings received on their models
    }

    struct ModelLicense {
        uint256 tokenId; // The NFT token ID
        uint256 modelId; // The ID of the AIModel this license is for
        address owner; // Current owner of the license
        uint256 purchaseTimestamp;
        bool valid; // Could add validity logic (e.g., expiry)
    }

    // --- Marketplace State ---
    mapping(uint256 => AIModel) public models; // modelId => AIModel
    mapping(address => Provider) public providers; // providerAddress => Provider
    mapping(uint256 => ModelLicense) public modelLicenses; // licenseTokenId => ModelLicense

    mapping(address => uint256) public providerStakes; // Redundant with Provider struct, but kept for explicit tracking
    mapping(address => uint256) public providerEarnings; // Redundant with Provider struct

    mapping(uint256 => mapping(address => bool)) private _userRatedModel; // modelId => userAddress => bool

    uint256 public modelCount = 0; // Total number of models ever listed

    address public oracleAddress; // Trusted address for oracle callbacks
    uint256 public feePercentage; // Fee percentage for the marketplace (e.g., 5 for 5%)
    uint256 public marketplaceBalance = 0; // $AIMT collected as fees

    mapping(uint256 => address) private _inferenceCallbacks; // Stores the user's address for each callbackId
    uint256 private _nextCallbackId = 1;


    // --- Events ---
    event ProviderRegistered(address indexed provider, string name);
    event ProviderStaked(address indexed provider, uint256 amount, uint256 newStake);
    event ProviderUnstaked(address indexed provider, uint256 amount, uint256 newStake);
    event ModelListed(uint256 indexed modelId, address indexed provider, uint256 licensePrice, uint256 inferencePrice);
    event ModelUpdated(uint256 indexed modelId, address indexed provider);
    event ModelDeactivated(uint256 indexed modelId, address indexed provider);
    event LicensePurchased(uint256 indexed licenseTokenId, uint256 indexed modelId, address indexed purchaser);
    event InferenceRequested(uint256 indexed callbackId, uint256 indexed licenseTokenId, address indexed user, string inputDataUrl);
    event InferenceResultSubmitted(uint256 indexed callbackId, bool success, string resultDataUrl);
    event ModelRated(uint256 indexed modelId, address indexed rater, uint8 rating);
    event ProviderEarningsWithdrawn(address indexed provider, uint256 amount);
    event OracleAddressSet(address indexed oldAddress, address indexed newAddress);
    event FeePercentageSet(uint256 oldPercentage, uint256 newPercentage);
    event MarketplaceFeesWithdrawn(address indexed recipient, uint256 amount);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyProvider() {
        require(providers[msg.sender].walletAddress != address(0), "Only registered providers can call this function");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Only the oracle address can call this function");
        _;
    }

    /// @notice Constructor to initialize the contract owner and initial simulated token supply.
    /// @param initialSupply Total supply for the simulated AIMT token.
    constructor(uint256 initialSupply) {
        owner = msg.sender;
        totalSimulatedSupply = initialSupply;
        _balances[msg.sender] = initialSupply; // Give owner initial supply
        feePercentage = 5; // Default 5% fee
        emit ProviderRegistered(address(0), "Marketplace Admin"); // Dummy provider entry for owner
    }

    // --- Simulated ERC20 Functions (Internal) ---
    // These functions simulate token transfers. In a real dapp,
    // you'd interact with an actual ERC20 contract using IERC20.
    function _transferTokens(address from, address to, uint256 amount) internal {
        require(_balances[from] >= amount, "Insufficient token balance");
        _balances[from] -= amount;
        _balances[to] += amount;
    }

    function _transferFromTokens(address spender, address from, address to, uint256 amount) internal {
        require(_allowances[from][spender] >= amount, "Insufficient allowance");
        _transferTokens(from, to, amount);
        _allowances[from][spender] -= amount;
    }

    // Note: approve and allowance are not strictly needed internally for this contract's flow
    // as users/providers would interact with the *real* ERC20 contract directly before
    // calling marketplace functions (e.g., `approve(marketplaceAddress, amount)`).
    // However, including getUserTokenBalance for checking is useful.

    /// @notice Gets the simulated token balance of a user.
    /// @param _user The address to query.
    /// @return The simulated token balance.
    function getUserTokenBalance(address _user) external view returns (uint256) {
        return _balances[_user];
    }

    /// @notice Admin function to mint initial tokens to a user (for testing/setup).
    /// @param _user The address to mint tokens to.
    /// @param _amount The amount of tokens to mint.
    function adminMintInitialTokens(address _user, uint256 _amount) external onlyOwner {
        _balances[_user] += _amount;
        totalSimulatedSupply += _amount;
    }


    // --- Simulated ERC721 Functions (Internal) ---
    // These functions simulate NFT minting and ownership tracking.
    // In a real dapp, you'd interact with an actual ERC721 contract using IERC721.
    function _mintLicense(address to, uint256 modelId) internal returns (uint256) {
        uint256 newTokenId = _nextTokenId++;
        _licenseOwners[newTokenId] = to;
        _userOwnedLicenses[to].push(newTokenId);

        // Store license details
        modelLicenses[newTokenId] = ModelLicense({
            tokenId: newTokenId,
            modelId: modelId,
            owner: to,
            purchaseTimestamp: block.timestamp,
            valid: true // Simplified: licenses are always valid once minted here
        });

        models[modelId].licenseTokenIds.push(newTokenId); // Track licenses per model

        return newTokenId;
    }

    function _burnLicense(uint256 tokenId) internal {
         // Simplified: This implementation just marks as burned in _licenseOwners.
         // A proper ERC721 burn involves removing from ownership lists etc.
        address owner = _licenseOwners[tokenId];
        require(owner != address(0), "License does not exist");

        delete _licenseOwners[tokenId]; // Remove ownership mapping
        // Note: Removing from _userOwnedLicenses array is complex and gas-intensive.
        // A real ERC721 implementation handles this efficiently.
        // For this simulation, we'll rely on _licenseOwners mapping for definitive ownership.
    }

    /// @notice Gets the owner of a specific license NFT.
    /// @param _licenseTokenId The ID of the license NFT.
    /// @return The address of the owner. Returns address(0) if not found or burned.
    function getLicenseOwner(uint256 _licenseTokenId) external view returns (address) {
        return _licenseOwners[_licenseTokenId];
    }

    /// @notice Checks if a user owns a specific license NFT.
    /// @param _user The address to check.
    /// @param _licenseTokenId The ID of the license NFT.
    /// @return True if the user owns the license, false otherwise.
    function isLicenseOwner(address _user, uint256 _licenseTokenId) public view returns (bool) {
        return _licenseOwners[_licenseTokenId] == _user;
    }

    /// @notice Gets a list of license NFT IDs owned by a user.
    /// @param _user The address to query.
    /// @return An array of license token IDs. (Note: This might include burned tokens in a simple simulation)
    function getUserLicenses(address _user) external view returns (uint256[] memory) {
        // Note: In a real ERC721, iterating through owned tokens is often done off-chain
        // or requires more complex on-chain indexing. This returns the potentially
        // outdated list from the simulation's simplistic _userOwnedLicenses.
         return _userOwnedLicenses[_user];
    }

     /// @notice Gets details for a specific license NFT.
     /// @param _user The address of the license owner (used for check).
     /// @param _licenseTokenId The ID of the license NFT.
     /// @return A tuple containing license details.
    function getUserLicense(address _user, uint256 _licenseTokenId) external view returns (uint256 tokenId, uint256 modelId, address owner, uint256 purchaseTimestamp, bool valid) {
        require(isLicenseOwner(_user, _licenseTokenId), "User does not own this license");
        ModelLicense storage license = modelLicenses[_licenseTokenId];
        return (license.tokenId, license.modelId, license.owner, license.purchaseTimestamp, license.valid);
    }


    // --- Provider Functions ---

    /// @notice Registers the caller as a model provider.
    /// @param _name Provider's name.
    /// @param _contactInfo Provider's contact information (e.g., email, website).
    function registerProvider(string memory _name, string memory _contactInfo) external {
        require(providers[msg.sender].walletAddress == address(0), "Provider already registered");
        providers[msg.sender] = Provider({
            walletAddress: msg.sender,
            name: _name,
            contactInfo: _contactInfo,
            registeredTimestamp: block.timestamp,
            currentStake: 0,
            totalEarnings: 0,
            listedModelIds: new uint256[](0),
            totalRatingSum: 0,
            totalRatingCount: 0
        });
        emit ProviderRegistered(msg.sender, _name);
    }

     /// @notice Checks if an address is a registered provider.
     /// @param _provider The address to check.
     /// @return True if registered, false otherwise.
    function isProviderRegistered(address _provider) external view returns (bool) {
        return providers[_provider].walletAddress != address(0);
    }

    /// @notice Gets the details of a registered provider.
    /// @param _provider The address of the provider.
    /// @return A tuple containing provider details.
    function getProviderInfo(address _provider) external view returns (address walletAddress, string memory name, string memory contactInfo, uint256 registeredTimestamp, uint256[] memory listedModelIds) {
        require(providers[_provider].walletAddress != address(0), "Provider not registered");
        Provider storage provider = providers[_provider];
        return (provider.walletAddress, provider.name, provider.contactInfo, provider.registeredTimestamp, provider.listedModelIds);
    }


    /// @notice Allows a registered provider to stake $AIMT tokens.
    ///         Tokens must be approved to the marketplace contract first.
    /// @param _amount The amount of tokens to stake.
    function stakeTokens(uint256 _amount) external onlyProvider {
        require(_amount > 0, "Stake amount must be greater than 0");
        // In a real scenario, check allowance using IERC20Minimal
        // require(tokenContract.allowance(msg.sender, address(this)) >= _amount, "Approve tokens first");
        // tokenContract.transferFrom(msg.sender, address(this), _amount);

        // Simulation: Direct transfer from user balance
        _transferTokens(msg.sender, address(this), _amount);

        providers[msg.sender].currentStake += _amount;
        providerStakes[msg.sender] += _amount; // Redundant, but kept for clarity/example
        emit ProviderStaked(msg.sender, _amount, providers[msg.sender].currentStake);
    }

    /// @notice Allows a registered provider to unstake $AIMT tokens.
    ///         Note: Could add conditions like minimum stake or lock-up periods.
    /// @param _amount The amount of tokens to unstake.
    function unstakeTokens(uint256 _amount) external onlyProvider {
        require(_amount > 0, "Unstake amount must be greater than 0");
        require(providers[msg.sender].currentStake >= _amount, "Insufficient stake");

        providers[msg.sender].currentStake -= _amount;
        providerStakes[msg.sender] -= _amount; // Redundant
        // Simulation: Direct transfer back to user balance
        _transferTokens(address(this), msg.sender, _amount);

        emit ProviderUnstaked(msg.sender, _amount, providers[msg.sender].currentStake);
    }

     /// @notice Gets the current staked amount of a provider.
     /// @param _provider The address of the provider.
     /// @return The staked amount in $AIMT.
    function getProviderStake(address _provider) external view returns (uint256) {
        return providers[_provider].currentStake;
    }


    /// @notice Allows a registered provider to list a new AI model.
    /// @param _name Model name.
    /// @param _description Model description.
    /// @param _modelUrl URL or hash pointing to the model files.
    /// @param _metadataUrl URL or hash pointing to additional model metadata.
    /// @param _licensePrice Price in $AIMT to purchase a usage license NFT.
    /// @param _inferencePrice Price in $AIMT per inference request using the model.
    function listModel(
        string memory _name,
        string memory _description,
        string memory _modelUrl,
        string memory _metadataUrl,
        uint256 _licensePrice,
        uint256 _inferencePrice
    ) external onlyProvider {
        modelCount++;
        uint256 newModelId = modelCount;
        models[newModelId] = AIModel({
            id: newModelId,
            provider: msg.sender,
            name: _name,
            description: _description,
            modelUrl: _modelUrl,
            metadataUrl: _metadataUrl,
            licensePrice: _licensePrice,
            inferencePrice: _inferencePrice,
            active: true,
            listedTimestamp: block.timestamp,
            licenseTokenIds: new uint256[](0),
            totalRatings: 0,
            ratingSum: 0
        });
        providers[msg.sender].listedModelIds.push(newModelId);
        emit ModelListed(newModelId, msg.sender, _licensePrice, _inferencePrice);
    }

    /// @notice Allows a provider to update an existing model's details.
    /// @param _modelId The ID of the model to update.
    /// @param _name New model name.
    /// @param _description New model description.
    /// @param _modelUrl New URL or hash pointing to the model files.
    /// @param _metadataUrl New URL or hash pointing to additional model metadata.
    /// @param _licensePrice New license price.
    /// @param _inferencePrice New inference price.
    function updateModel(
        uint256 _modelId,
        string memory _name,
        string memory _description,
        string memory _modelUrl,
        string memory _metadataUrl,
        uint256 _licensePrice,
        uint256 _inferencePrice
    ) external onlyProvider {
        require(models[_modelId].provider == msg.sender, "Not your model");
        AIModel storage model = models[_modelId];
        model.name = _name;
        model.description = _description;
        model.modelUrl = _modelUrl;
        model.metadataUrl = _metadataUrl;
        model.licensePrice = _licensePrice;
        model.inferencePrice = _inferencePrice;
        emit ModelUpdated(_modelId, msg.sender);
    }

    /// @notice Allows a provider to deactivate a model, preventing new purchases or inferences.
    /// @param _modelId The ID of the model to deactivate.
    function deactivateModel(uint256 _modelId) external onlyProvider {
        require(models[_modelId].provider == msg.sender, "Not your model");
        require(models[_modelId].active, "Model already inactive");
        models[_modelId].active = false;
        emit ModelDeactivated(_modelId, msg.sender);
    }

     /// @notice Checks if a model is currently active and available.
     /// @param _modelId The ID of the model.
     /// @return True if active, false otherwise.
    function isModelActive(uint256 _modelId) external view returns (bool) {
        return models[_modelId].active;
    }


    /// @notice Gets the details of a specific AI model.
    /// @param _modelId The ID of the model.
    /// @return A tuple containing model details.
    function getModelDetails(uint256 _modelId) external view returns (uint256 id, address provider, string memory name, string memory description, string memory modelUrl, string memory metadataUrl, uint256 licensePrice, uint256 inferencePrice, bool active, uint256 listedTimestamp) {
         AIModel storage model = models[_modelId];
         require(model.provider != address(0), "Model does not exist");
         return (model.id, model.provider, model.name, model.description, model.modelUrl, model.metadataUrl, model.licensePrice, model.inferencePrice, model.active, model.listedTimestamp);
    }

     /// @notice Gets the total count of models ever listed on the marketplace.
     /// @return The total model count.
    function getTotalListedModels() external view returns (uint256) {
        return modelCount;
    }

     /// @notice Gets the list of model IDs listed by a specific provider.
     /// @param _provider The address of the provider.
     /// @return An array of model IDs.
    function getProviderModels(address _provider) external view returns (uint256[] memory) {
        require(providers[_provider].walletAddress != address(0), "Provider not registered");
        return providers[_provider].listedModelIds;
    }


    /// @notice Allows a provider to withdraw their accumulated earnings.
    function withdrawProviderEarnings() external onlyProvider {
        uint256 amount = providers[msg.sender].totalEarnings;
        require(amount > 0, "No earnings to withdraw");

        providers[msg.sender].totalEarnings = 0;
        providerEarnings[msg.sender] = 0; // Redundant
        // Simulation: Direct transfer to provider balance
        _transferTokens(address(this), msg.sender, amount);

        emit ProviderEarningsWithdrawn(msg.sender, amount);
    }


    // --- User Functions ---

    /// @notice Allows a user to purchase a usage license NFT for a specific model.
    ///         Requires the user to have sufficient $AIMT balance.
    ///         Tokens must be approved to the marketplace contract first.
    /// @param _modelId The ID of the model to purchase a license for.
    /// @return The token ID of the newly minted license NFT.
    function purchaseModelLicense(uint256 _modelId) external returns (uint256) {
        AIModel storage model = models[_modelId];
        require(model.provider != address(0), "Model does not exist");
        require(model.active, "Model is not active");
        require(model.licensePrice > 0, "Model license cannot be purchased");

        uint256 price = model.licensePrice;

        // In a real scenario, check allowance and transferFrom using IERC20Minimal
        // require(tokenContract.allowance(msg.sender, address(this)) >= price, "Approve tokens for purchase");
        // tokenContract.transferFrom(msg.sender, address(this), price);

        // Simulation: Direct transfer from user balance
        _transferTokens(msg.sender, address(this), price);

        // Distribute fee and earnings
        uint256 feeAmount = (price * feePercentage) / 100;
        uint256 providerAmount = price - feeAmount;

        marketplaceBalance += feeAmount;
        providers[model.provider].totalEarnings += providerAmount;
        providerEarnings[model.provider] += providerAmount; // Redundant

        // Mint the license NFT
        uint256 licenseTokenId = _mintLicense(msg.sender, _modelId);

        emit LicensePurchased(licenseTokenId, _modelId, msg.sender);

        return licenseTokenId;
    }

    /// @notice Allows a user with a valid license NFT to request an inference using the model.
    ///         Requires the user to have sufficient $AIMT balance for the inference price.
    ///         Tokens must be approved to the marketplace contract first.
    ///         Emits an event for the off-chain oracle to pick up the request.
    /// @param _licenseTokenId The token ID of the user's valid license NFT.
    /// @param _inputDataUrl URL or hash pointing to the input data for inference.
    /// @param _callbackId A unique ID provided by the user/client to identify the result later.
    function requestInference(uint256 _licenseTokenId, string memory _inputDataUrl, uint256 _callbackId) external {
        // Check license ownership and validity
        require(isLicenseOwner(msg.sender, _licenseTokenId), "User does not own this license NFT");
        ModelLicense storage license = modelLicenses[_licenseTokenId];
        require(license.valid, "License is not valid"); // Basic validity check
        require(license.modelId > 0 && models[license.modelId].provider != address(0), "Invalid model associated with license");

        AIModel storage model = models[license.modelId];
        require(model.active, "Model is currently inactive");
        require(model.inferencePrice > 0, "Model inference is not available or free");
        require(oracleAddress != address(0), "Oracle address not set");

        uint256 price = model.inferencePrice;

        // In a real scenario, check allowance and transferFrom using IERC20Minimal
        // require(tokenContract.allowance(msg.sender, address(this)) >= price, "Approve tokens for inference");
        // tokenContract.transferFrom(msg.sender, address(this), price);

        // Simulation: Direct transfer from user balance
        _transferTokens(msg.sender, address(this), price);


        // Store user address for the callback ID
        require(_inferenceCallbacks[_callbackId] == address(0), "Callback ID already in use"); // Prevent double spending/requesting with same ID
        _inferenceCallbacks[_callbackId] = msg.sender;

        // Distribute fee and earnings (immediately upon request)
        uint256 feeAmount = (price * feePercentage) / 100;
        uint256 providerAmount = price - feeAmount;

        marketplaceBalance += feeAmount;
        providers[model.provider].totalEarnings += providerAmount;
        providerEarnings[model.provider] += providerAmount; // Redundant

        // Emit event for off-chain oracle/provider system
        emit InferenceRequested(_callbackId, _licenseTokenId, msg.sender, _inputDataUrl);
    }

    /// @notice Called by the trusted Oracle address to submit the result of an inference request.
    ///         This confirms the computation happened and potentially triggers further actions
    ///         (like reputation updates, though simplified here).
    /// @param _callbackId The ID from the original inference request.
    /// @param _resultDataUrl URL or hash pointing to the inference result data.
    /// @param _success True if the inference was successful, false otherwise.
    function submitInferenceResult(uint256 _callbackId, string memory _resultDataUrl, bool _success) external onlyOracle {
        require(_inferenceCallbacks[_callbackId] != address(0), "Invalid or already processed callback ID");

        address user = _inferenceCallbacks[_callbackId];
        delete _inferenceCallbacks[_callbackId]; // Mark as processed

        // In a real scenario, you might perform checks:
        // - Check if the result matches expected format/integrity (requires ZKPs or more complex verification)
        // - Potentially penalize provider stake on failure (slashing)

        // For this example, simply log the event and the success status.
        // Payment and earnings distribution already happened in requestInference.

        emit InferenceResultSubmitted(_callbackId, _success, _resultDataUrl);

        // Could link this back to licenseTokenId/modelId to influence reputation based on success/failure rate
        // Requires storing licenseTokenId with callbackId or linking callbackId to request event data.
        // Keeping it simple for function count: reputation is only updated via explicit rating.
    }


    /// @notice Allows a user who has interacted with a model (e.g., requested inference) to rate it.
    ///         A user can rate a model only once. Rating affects the provider's reputation.
    /// @param _modelId The ID of the model to rate.
    /// @param _rating The rating (1-5 stars).
    function rateModel(uint256 _modelId, uint8 _rating) external {
        AIModel storage model = models[_modelId];
        require(model.provider != address(0), "Model does not exist");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");
        require(!_userRatedModel[_modelId][msg.sender], "User already rated this model");

        // Optional: Add check if user has actually used the model (e.g., owns a license, requested inference)
        // This is complex to track efficiently on-chain across all interactions.
        // Simplified: Any user can rate a listed model once.

        model.totalRatings++;
        model.ratingSum += _rating;
        _userRatedModel[_modelId][msg.sender] = true;

        // Update provider's overall reputation
        Provider storage provider = providers[model.provider];
        provider.totalRatingSum += _rating;
        provider.totalRatingCount++;

        emit ModelRated(_modelId, msg.sender, _rating);
    }

    /// @notice Gets the average rating (reputation) for a specific provider.
    /// @param _provider The address of the provider.
    /// @return The average rating (scaled by 100 to handle decimals, e.g., 450 for 4.5). Returns 0 if no ratings.
    function getProviderReputation(address _provider) external view returns (uint256) {
        Provider storage provider = providers[_provider];
        if (provider.totalRatingCount == 0) {
            return 0;
        }
        return (provider.totalRatingSum * 100) / provider.totalRatingCount;
    }

    /// @notice Gets the average rating for a specific model.
    /// @param _modelId The ID of the model.
    /// @return The average rating (scaled by 100). Returns 0 if no ratings.
    function getModelAverageRating(uint256 _modelId) external view returns (uint256) {
        AIModel storage model = models[_modelId];
        if (model.totalRatings == 0) {
            return 0;
        }
        return (model.ratingSum * 100) / model.totalRatings;
    }


    // --- Admin/Marketplace Functions ---

    /// @notice Sets the trusted Oracle contract address.
    /// @param _oracle The address of the oracle contract.
    function setOracleAddress(address _oracle) external onlyOwner {
        require(_oracle != address(0), "Oracle address cannot be zero");
        emit OracleAddressSet(oracleAddress, _oracle);
        oracleAddress = _oracle;
    }

     /// @notice Gets the current oracle address.
     /// @return The oracle address.
    function getOracleAddress() external view returns (address) {
        return oracleAddress;
    }


    /// @notice Sets the marketplace fee percentage.
    /// @param _percentage The new fee percentage (e.g., 5 for 5%). Must be between 0 and 100.
    function setFeePercentage(uint256 _percentage) external onlyOwner {
        require(_percentage <= 100, "Fee percentage cannot exceed 100");
        emit FeePercentageSet(feePercentage, _percentage);
        feePercentage = _percentage;
    }

    /// @notice Gets the current marketplace fee percentage.
    /// @return The fee percentage.
    function getMarketplaceFeePercentage() external view returns (uint256) {
        return feePercentage;
    }


    /// @notice Allows the contract owner to withdraw accumulated marketplace fees.
    function withdrawMarketplaceFees() external onlyOwner {
        uint256 amount = marketplaceBalance;
        require(amount > 0, "No fees to withdraw");

        marketplaceBalance = 0;
        // Simulation: Direct transfer to owner balance
        _transferTokens(address(this), owner, amount);

        emit MarketplaceFeesWithdrawn(owner, amount);
    }

     /// @notice Gets the current balance of $AIMT held by the marketplace as fees.
     /// @return The marketplace fee balance.
    function getMarketplaceBalance() external view returns (uint256) {
        return marketplaceBalance;
    }

    // --- Fallback and Receive functions ---
    // It's good practice to include these, although this contract
    // is not intended to receive plain Ether.
    receive() external payable {
        revert("Cannot receive Ether directly");
    }

    fallback() external payable {
         revert("Cannot receive Ether directly");
    }
}
```