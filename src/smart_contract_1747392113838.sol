Okay, here is a Solidity smart contract for a Decentralized AI Model Marketplace.

This contract incorporates several concepts:
*   **Decentralized Marketplace:** Facilitates direct interactions between AI model providers and users.
*   **Licensing:** Handles the acquisition and validation of licenses to use models.
*   **Reputation System:** Allows users to rate models they have licensed.
*   **Staking:** Providers and users can stake funds, potentially for reputation boosting, priority, or future governance (though governance isn't fully implemented here, the staking mechanism is present).
*   **Off-chain Data/Attestation Linking:** Stores hashes pointing to off-chain data (model parameters, training data, performance attestations) on decentralized storage like IPFS. The contract verifies the integrity of these *pointers*.
*   **Profile Management:** Basic user/provider profiles.
*   **Fee Mechanism:** Platform fees and listing fees.

It aims to avoid standard ERC20/ERC721 implementations themselves, focusing on the marketplace logic built *around* potential token transfers (using native currency for simplicity here, but could be adapted for ERC20). It's also not a typical DeFi lending/swapping protocol or a simple escrow.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DecentralizedAIModelMarketplace
 * @dev A decentralized marketplace for AI models. Providers can list models,
 *      users can acquire licenses, rate models, and both can stake funds.
 *      Uses hashes to link to off-chain data on decentralized storage.
 */
contract DecentralizedAIModelMarketplace {

    // --- Contract Outline ---
    // 1. State Variables & Data Structures
    // 2. Events
    // 3. Modifiers
    // 4. Constructor
    // 5. Profile Management Functions (Register, Update, Get)
    // 6. Model Management Functions (List, Update, Get, Query)
    // 7. License Management Functions (Buy, Get, Query, Check Validity)
    // 8. Rating/Reputation Functions (Rate, Get Average)
    // 9. Staking Functions (Stake, Withdraw, Get Stake)
    // 10. Off-chain Data/Attestation Functions (Link Data, Record Attestation)
    // 11. Fee & Withdrawal Functions (Set Fees, Withdraw Platform Fees)
    // 12. Utility & Query Functions (Get Counters, Balances, Pause)

    // --- Function Summary ---
    // Profile Management:
    // - registerProfile(): Register a user or provider profile.
    // - updateProfile(): Update an existing user/provider profile.
    // - getUserProfile(): Retrieve a user/provider profile.
    // - getTotalRegisteredUsers(): Get the total count of registered users/providers.

    // Model Management:
    // - listModel(): Provider lists a new AI model for licensing. Requires listing fee.
    // - updateModelDetails(): Provider updates details of their listed model.
    // - getModelDetails(): Retrieve details of a specific model.
    // - getAllModelIds(): Get a list of all active model IDs.
    // - getModelsByProvider(): Get a list of model IDs listed by a specific provider.
    // - getTotalModels(): Get the total count of listed models.
    // - toggleModelActiveStatus(): Provider can activate/deactivate their model listing.

    // License Management:
    // - buyLicense(): User purchases a license for a model. Pays license fee.
    // - getLicenseDetails(): Retrieve details of a specific license.
    // - getLicensesByUser(): Get a list of license IDs owned by a specific user.
    // - checkLicenseValidity(): Check if a specific license is currently valid.
    // - getTotalLicenses(): Get the total count of licenses ever issued.

    // Rating/Reputation:
    // - rateModel(): User with a valid license can rate a model.
    // - getAverageRating(): Get the average rating for a model.

    // Staking:
    // - stakeForProvider(): Provider stakes funds (e.g., for priority, reputation).
    // - withdrawProviderStake(): Provider withdraws staked funds.
    // - stakeForUser(): User stakes funds (e.g., for benefits, voting rights).
    // - withdrawUserStake(): User withdraws staked funds.
    // - getProviderStake(): Get the current staked amount for a provider.
    // - getUserStake(): Get the current staked amount for a user.

    // Off-chain Data/Attestation:
    // - linkDataHashToModel(): Link a hash pointing to off-chain dataset info (e.g., IPFS).
    // - recordAttestationHash(): Record a hash pointing to an off-chain attestation or verification report.

    // Fee & Withdrawal:
    // - setListingFee(): Owner sets the fee required to list a model.
    // - setPlatformFeePercentage(): Owner sets the percentage of license fees taken by the platform.
    // - withdrawPlatformFees(): Owner withdraws accumulated platform fees.

    // Utility & Query:
    // - getPlatformBalance(): Check the contract's current ETH balance (platform fees).
    // - pauseContract(): Owner pauses contract operations.
    // - unpauseContract(): Owner unpauses contract operations.

    // --- State Variables ---

    address public owner;
    bool public paused = false;

    uint256 private _modelIdCounter;
    uint256 private _licenseIdCounter;
    uint256 private _registeredUserCounter; // Counts unique registered addresses

    uint256 public listingFee; // Fee required to list a model (in native currency)
    uint256 public platformFeePercentage; // Percentage of license fee taken by the platform (0-100)
    uint256 public totalPlatformFeesCollected; // Accumulated platform fees

    // --- Data Structures ---

    struct UserProfile {
        bool isRegistered;
        bool isProvider; // Can list models
        bool isUser;     // Can buy licenses/rate
        string name;     // Display name
        bytes32 contactInfoHash; // Hash of off-chain contact info / profile data
        uint256 registeredAt;
    }

    struct Model {
        uint256 id;
        address provider;
        string name;
        string description;
        bytes32 metadataHash; // Hash of off-chain model parameters/description link (e.g., IPFS hash)
        uint256 licensePrice; // Price in native currency
        uint256 licenseDuration; // Duration in seconds (0 for perpetual)
        uint256 listedAt;
        bool active; // Is the listing currently active?
        uint256 totalRatings;
        uint256 ratingSum; // Sum of all ratings (e.g., 1-5)
        bytes32 dataHash; // Hash linking to associated data (e.g., training/evaluation data details)
        bytes32 attestationHash; // Hash linking to off-chain attestation/verification report
    }

    struct License {
        uint256 id;
        uint256 modelId;
        address licensee;
        uint256 purchasedAt;
        uint256 validUntil; // 0 if perpetual
        bool active; // Can be deactivated by contract (e.g., if duration expires)
    }

    // --- Mappings ---

    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => Model) public models;
    mapping(uint256 => License) public licenses;
    mapping(address => uint256) public providerStakes; // Provider address => staked amount
    mapping(address => uint255) public userStakes;     // User address => staked amount (uint255 to differentiate, though uint256 fine)
    mapping(uint256 => mapping(address => uint8)) public modelRatings; // modelId => userAddress => rating (1-5)

    // To easily retrieve models by provider and licenses by user
    mapping(address => uint256[]) public providerModelIds;
    mapping(address => uint256[]) public userLicenseIds;

    // --- Events ---

    event ProfileRegistered(address indexed account, bool isProvider, bool isUser, uint256 registeredAt);
    event ProfileUpdated(address indexed account);
    event ModelListed(uint256 indexed modelId, address indexed provider, uint256 price, uint256 duration, uint256 listedAt);
    event ModelUpdated(uint256 indexed modelId, address indexed provider);
    event ModelStatusToggled(uint256 indexed modelId, bool indexed newStatus);
    event LicensePurchased(uint256 indexed licenseId, uint256 indexed modelId, address indexed licensee, uint256 validUntil, uint256 purchasedAt);
    event ModelRated(uint256 indexed modelId, address indexed user, uint8 rating, uint256 totalRatings, uint256 ratingSum);
    event FundsStaked(address indexed account, uint256 amount, uint256 totalStake);
    event StakeWithdrawn(address indexed account, uint256 amount, uint256 remainingStake);
    event DataHashLinked(uint256 indexed modelId, bytes32 indexed dataHash);
    event AttestationHashRecorded(uint256 indexed modelId, bytes32 indexed attestationHash);
    event PlatformFeePercentageSet(uint256 indexed percentage);
    event ListingFeeSet(uint256 indexed fee);
    event PlatformFeesWithdrawn(address indexed owner, uint256 amount);
    event Paused(address account);
    event Unpaused(address account);

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

    modifier onlyRegisteredUser() {
        require(userProfiles[msg.sender].isRegistered, "Caller is not a registered user");
        _;
    }

     modifier onlyProvider(uint256 modelId) {
        require(models[modelId].provider == msg.sender, "Caller is not the model provider");
        _;
    }

    modifier modelExists(uint256 modelId) {
        require(models[modelId].id != 0, "Model does not exist"); // Assuming ID 0 is invalid
        _;
    }

    modifier licenseExists(uint256 licenseId) {
        require(licenses[licenseId].id != 0, "License does not exist"); // Assuming ID 0 is invalid
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        _modelIdCounter = 1; // Start IDs from 1
        _licenseIdCounter = 1;
        _registeredUserCounter = 0;
        listingFee = 0.01 ether; // Example default fee
        platformFeePercentage = 5; // Example default 5%
    }

    // --- Profile Management ---

    /// @notice Registers a new user or provider profile.
    /// @param _name Display name for the profile.
    /// @param _isProvider Role flag: true if the account can list models.
    /// @param _isUser Role flag: true if the account can buy licenses/rate.
    /// @param _contactInfoHash Hash linking to off-chain contact/profile details.
    function registerProfile(string calldata _name, bool _isProvider, bool _isUser, bytes32 _contactInfoHash) external whenNotPaused {
        require(!userProfiles[msg.sender].isRegistered, "Account is already registered");
        require(_isProvider || _isUser, "Account must be either a provider or a user (or both)");

        userProfiles[msg.sender] = UserProfile({
            isRegistered: true,
            isProvider: _isProvider,
            isUser: _isUser,
            name: _name,
            contactInfoHash: _contactInfoHash,
            registeredAt: block.timestamp
        });
        _registeredUserCounter++;

        emit ProfileRegistered(msg.sender, _isProvider, _isUser, block.timestamp);
    }

    /// @notice Updates an existing user or provider profile.
    /// @param _name New display name.
    /// @param _isProvider New role flag for provider.
    /// @param _isUser New role flag for user.
    /// @param _contactInfoHash New hash linking to off-chain contact/profile details.
    function updateProfile(string calldata _name, bool _isProvider, bool _isUser, bytes32 _contactInfoHash) external onlyRegisteredUser whenNotPaused {
        require(_isProvider || _isUser, "Account must be either a provider or a user (or both)");

        UserProfile storage profile = userProfiles[msg.sender];
        profile.name = _name;
        profile.isProvider = _isProvider;
        profile.isUser = _isUser;
        profile.contactInfoHash = _contactInfoHash;

        emit ProfileUpdated(msg.sender);
    }

    /// @notice Retrieves a user/provider profile.
    /// @param _account The address of the profile owner.
    /// @return profile The UserProfile struct.
    function getUserProfile(address _account) external view returns (UserProfile memory) {
        return userProfiles[_account];
    }

    /// @notice Gets the total number of registered user/provider accounts.
    /// @return count The total count.
    function getTotalRegisteredUsers() external view returns (uint256) {
        return _registeredUserCounter;
    }

    // --- Model Management ---

    /// @notice Provider lists a new AI model in the marketplace.
    /// @param _name Model name.
    /// @param _description Model description.
    /// @param _metadataHash Hash linking to off-chain model details/parameters.
    /// @param _licensePrice Price for a license in native currency.
    /// @param _licenseDuration Duration of the license in seconds (0 for perpetual).
    function listModel(
        string calldata _name,
        string calldata _description,
        bytes32 _metadataHash,
        uint256 _licensePrice,
        uint256 _licenseDuration
    ) external payable onlyRegisteredUser whenNotPaused {
        require(userProfiles[msg.sender].isProvider, "Caller must be a provider to list models");
        require(msg.value >= listingFee, "Insufficient listing fee");
        require(_licensePrice > 0, "License price must be greater than zero");

        uint256 newModelId = _modelIdCounter++;
        models[newModelId] = Model({
            id: newModelId,
            provider: msg.sender,
            name: _name,
            description: _description,
            metadataHash: _metadataHash,
            licensePrice: _licensePrice,
            licenseDuration: _licenseDuration,
            listedAt: block.timestamp,
            active: true,
            totalRatings: 0,
            ratingSum: 0,
            dataHash: bytes32(0), // No data hash initially
            attestationHash: bytes32(0) // No attestation hash initially
        });

        providerModelIds[msg.sender].push(newModelId);

        emit ModelListed(newModelId, msg.sender, _licensePrice, _licenseDuration, block.timestamp);
    }

    /// @notice Provider updates details of an existing model.
    /// @param _modelId The ID of the model to update.
    /// @param _name New model name.
    /// @param _description New model description.
    /// @param _metadataHash New hash linking to off-chain model details/parameters.
    /// @param _licensePrice New price for a license.
    /// @param _licenseDuration New duration of the license in seconds (0 for perpetual).
    function updateModelDetails(
        uint256 _modelId,
        string calldata _name,
        string calldata _description,
        bytes32 _metadataHash,
        uint256 _licensePrice,
        uint256 _licenseDuration
    ) external onlyProvider(_modelId) modelExists(_modelId) whenNotPaused {
         require(_licensePrice > 0, "License price must be greater than zero");

        Model storage model = models[_modelId];
        model.name = _name;
        model.description = _description;
        model.metadataHash = _metadataHash;
        model.licensePrice = _licensePrice;
        model.licenseDuration = _licenseDuration; // Note: Does not affect existing licenses

        emit ModelUpdated(_modelId, msg.sender);
    }

     /// @notice Provider activates or deactivates their model listing.
     /// @param _modelId The ID of the model.
     /// @param _status The new active status (true to activate, false to deactivate).
     function toggleModelActiveStatus(uint256 _modelId, bool _status) external onlyProvider(_modelId) modelExists(_modelId) whenNotPaused {
         models[_modelId].active = _status;
         emit ModelStatusToggled(_modelId, _status);
     }

    /// @notice Retrieves details of a specific model.
    /// @param _modelId The ID of the model.
    /// @return model The Model struct.
    function getModelDetails(uint256 _modelId) external view modelExists(_modelId) returns (Model memory) {
        return models[_modelId];
    }

    /// @notice Gets a list of all active model IDs currently listed.
    /// @return modelIds An array of active model IDs.
    function getAllModelIds() external view returns (uint256[] memory) {
        uint256[] memory activeIds = new uint256[](getTotalModels()); // Max possible size
        uint256 currentIndex = 0;
        for (uint256 i = 1; i < _modelIdCounter; i++) {
            if (models[i].id != 0 && models[i].active) { // Check if exists and is active
                activeIds[currentIndex] = models[i].id;
                currentIndex++;
            }
        }
        // Resize array to actual count
        uint256[] memory result = new uint256[](currentIndex);
        for (uint256 i = 0; i < currentIndex; i++) {
            result[i] = activeIds[i];
        }
        return result;
    }


    /// @notice Gets a list of model IDs listed by a specific provider.
    /// @param _provider The address of the provider.
    /// @return modelIds An array of model IDs.
    function getModelsByProvider(address _provider) external view returns (uint256[] memory) {
         // Note: This returns all models ever listed, including inactive ones.
         // Filter `getAllModelIds` or add specific filtering here if needed.
        return providerModelIds[_provider];
    }

    /// @notice Gets the total number of models ever listed.
    /// @return count The total count.
    function getTotalModels() public view returns (uint256) {
         // Counter includes potentially inactive/deleted models.
         // To get active count, iterate getAllModelIds.
        return _modelIdCounter - 1; // Adjust for starting ID from 1
    }


    // --- License Management ---

    /// @notice User purchases a license for a specific model.
    /// @param _modelId The ID of the model to license.
    function buyLicense(uint256 _modelId) external payable onlyRegisteredUser whenNotPaused modelExists(_modelId) {
        require(userProfiles[msg.sender].isUser, "Caller must be a user to buy licenses");
        Model storage model = models[_modelId];
        require(model.active, "Model is not active for licensing");
        require(msg.value >= model.licensePrice, "Insufficient payment for license");

        uint256 providerShare = model.licensePrice * (100 - platformFeePercentage) / 100;
        uint256 platformShare = model.licensePrice - providerShare;

        // Send funds to provider
        (bool providerSuccess, ) = payable(model.provider).call{value: providerShare}("");
        require(providerSuccess, "Payment to provider failed");

        // Keep platform share in the contract balance
        totalPlatformFeesCollected += platformShare;

        uint256 newLicenseId = _licenseIdCounter++;
        uint256 validUntil = model.licenseDuration == 0 ? 0 : block.timestamp + model.licenseDuration;

        licenses[newLicenseId] = License({
            id: newLicenseId,
            modelId: _modelId,
            licensee: msg.sender,
            purchasedAt: block.timestamp,
            validUntil: validUntil,
            active: true // Initially active, check validity using validUntil later
        });

        userLicenseIds[msg.sender].push(newLicenseId);

        // Refund excess payment if any
        if (msg.value > model.licensePrice) {
            payable(msg.sender).transfer(msg.value - model.licensePrice);
        }

        emit LicensePurchased(newLicenseId, _modelId, msg.sender, validUntil, block.timestamp);
    }

    /// @notice Retrieves details of a specific license.
    /// @param _licenseId The ID of the license.
    /// @return license The License struct.
    function getLicenseDetails(uint256 _licenseId) external view licenseExists(_licenseId) returns (License memory) {
        return licenses[_licenseId];
    }

    /// @notice Gets a list of license IDs owned by a specific user.
    /// @param _user The address of the user.
    /// @return licenseIds An array of license IDs.
    function getLicensesByUser(address _user) external view returns (uint256[] memory) {
        return userLicenseIds[_user];
    }

    /// @notice Checks if a specific license is currently valid based on its duration.
    /// @param _licenseId The ID of the license.
    /// @return isValid True if the license is valid, false otherwise.
    function checkLicenseValidity(uint256 _licenseId) public view licenseExists(_licenseId) returns (bool) {
        License storage license = licenses[_licenseId];
        // Perptual license or duration has not expired
        return license.active && (license.validUntil == 0 || block.timestamp < license.validUntil);
    }

    /// @notice Gets the total number of licenses ever issued.
    /// @return count The total count.
    function getTotalLicenses() external view returns (uint256) {
        return _licenseIdCounter - 1; // Adjust for starting ID from 1
    }

    // --- Rating/Reputation ---

    /// @notice Allows a user to rate a model they have a valid license for.
    /// @param _modelId The ID of the model to rate.
    /// @param _rating The rating (e.g., 1-5).
    function rateModel(uint256 _modelId, uint8 _rating) external onlyRegisteredUser whenNotPaused modelExists(_modelId) {
        require(userProfiles[msg.sender].isUser, "Caller must be a user to rate models");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");

        // Check if the user has any valid license for this model
        bool hasValidLicense = false;
        uint256[] storage userLicenses = userLicenseIds[msg.sender];
        for(uint i = 0; i < userLicenses.length; i++){
            License storage userLicense = licenses[userLicenses[i]];
            if(userLicense.modelId == _modelId && checkLicenseValidity(userLicense.id)){
                 hasValidLicense = true;
                 break; // Found a valid license
            }
        }
        require(hasValidLicense, "User must have a valid license to rate this model");

        require(modelRatings[_modelId][msg.sender] == 0, "User has already rated this model");

        Model storage model = models[_modelId];
        model.totalRatings++;
        model.ratingSum += _rating;
        modelRatings[_modelId][msg.sender] = _rating;

        emit ModelRated(_modelId, msg.sender, _rating, model.totalRatings, model.ratingSum);
    }

    /// @notice Gets the average rating for a model.
    /// @param _modelId The ID of the model.
    /// @return averageRating The average rating (multiplied by 100 to avoid decimals).
    function getAverageRating(uint256 _modelId) external view modelExists(_modelId) returns (uint256 averageRating) {
        Model storage model = models[_modelId];
        if (model.totalRatings == 0) {
            return 0; // No ratings yet
        }
        // Calculate average (integer division) and multiply by 100 for precision display off-chain
        return (model.ratingSum * 100) / model.totalRatings;
    }

    // --- Staking ---

    /// @notice Allows a provider to stake funds.
    /// @param _amount The amount to stake.
    function stakeForProvider(uint256 _amount) external payable onlyRegisteredUser whenNotPaused {
        require(userProfiles[msg.sender].isProvider, "Caller must be a provider to stake as provider");
        require(msg.value == _amount && _amount > 0, "Payment must match the staking amount and be positive");
        providerStakes[msg.sender] += _amount;
        emit FundsStaked(msg.sender, _amount, providerStakes[msg.sender]);
    }

     /// @notice Allows a user to stake funds.
    /// @param _amount The amount to stake.
    function stakeForUser(uint256 _amount) external payable onlyRegisteredUser whenNotPaused {
        require(userProfiles[msg.sender].isUser, "Caller must be a user to stake as user");
         require(msg.value == _amount && _amount > 0, "Payment must match the staking amount and be positive");
        userStakes[msg.sender] += uint255(_amount); // Cast to uint255
         emit FundsStaked(msg.sender, _amount, userStakes[msg.sender]);
    }

    /// @notice Allows a provider to withdraw their staked funds.
    /// @param _amount The amount to withdraw.
    function withdrawProviderStake(uint256 _amount) external onlyRegisteredUser whenNotPaused {
         require(userProfiles[msg.sender].isProvider, "Caller must be a provider to withdraw provider stake");
        require(providerStakes[msg.sender] >= _amount, "Insufficient staked funds");
        providerStakes[msg.sender] -= _amount;
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdrawal failed");
        emit StakeWithdrawn(msg.sender, _amount, providerStakes[msg.sender]);
    }

    /// @notice Allows a user to withdraw their staked funds.
    /// @param _amount The amount to withdraw.
    function withdrawUserStake(uint256 _amount) external onlyRegisteredUser whenNotPaused {
         require(userProfiles[msg.sender].isUser, "Caller must be a user to withdraw user stake");
         // Convert userStake to uint256 for comparison
        require(uint256(userStakes[msg.sender]) >= _amount, "Insufficient staked funds");
        userStakes[msg.sender] -= uint255(_amount); // Cast back to uint255
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdrawal failed");
        emit StakeWithdrawn(msg.sender, _amount, userStakes[msg.sender]);
    }

    /// @notice Gets the current staked amount for a provider.
    /// @param _provider The provider's address.
    /// @return amount The staked amount.
    function getProviderStake(address _provider) external view returns (uint256) {
        return providerStakes[_provider];
    }

    /// @notice Gets the current staked amount for a user.
    /// @param _user The user's address.
    /// @return amount The staked amount.
    function getUserStake(address _user) external view returns (uint256) {
        return uint256(userStakes[_user]); // Return as uint256 for consistency
    }

    // --- Off-chain Data/Attestation ---

    /// @notice Provider links a hash pointing to off-chain associated data for their model.
    /// @param _modelId The ID of the model.
    /// @param _dataHash The hash linking to the data details (e.g., IPFS hash of a data descriptor).
    function linkDataHashToModel(uint256 _modelId, bytes32 _dataHash) external onlyProvider(_modelId) modelExists(_modelId) whenNotPaused {
        models[_modelId].dataHash = _dataHash;
        emit DataHashLinked(_modelId, _dataHash);
    }

     /// @notice Provider records a hash pointing to an off-chain attestation or verification report for their model.
    /// @param _modelId The ID of the model.
    /// @param _attestationHash The hash linking to the attestation details (e.g., IPFS hash of a report).
    function recordAttestationHash(uint256 _modelId, bytes32 _attestationHash) external onlyProvider(_modelId) modelExists(_modelId) whenNotPaused {
        models[_modelId].attestationHash = _attestationHash;
        emit AttestationHashRecorded(_modelId, _attestationHash);
    }

    // --- Fee & Withdrawal ---

    /// @notice Owner sets the fee required to list a model.
    /// @param _fee The new listing fee in native currency.
    function setListingFee(uint256 _fee) external onlyOwner {
        listingFee = _fee;
        emit ListingFeeSet(_fee);
    }

    /// @notice Owner sets the percentage of license fees taken by the platform.
    /// @param _percentage The new percentage (0-100).
    function setPlatformFeePercentage(uint256 _percentage) external onlyOwner {
        require(_percentage <= 100, "Percentage cannot exceed 100");
        platformFeePercentage = _percentage;
        emit PlatformFeePercentageSet(_percentage);
    }

    /// @notice Owner withdraws accumulated platform fees.
    function withdrawPlatformFees() external onlyOwner {
        uint256 amount = totalPlatformFeesCollected;
        require(amount > 0, "No platform fees to withdraw");
        totalPlatformFeesCollected = 0;
        (bool success, ) = payable(owner).call{value: amount}("");
        require(success, "Platform fee withdrawal failed");
        emit PlatformFeesWithdrawn(owner, amount);
    }

    // --- Utility & Query ---

     /// @notice Gets the contract's current balance (primarily accumulated platform fees).
     /// @return balance The contract's balance in native currency.
    function getPlatformBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Owner pauses critical contract functions.
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /// @notice Owner unpauses critical contract functions.
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    // Fallback function to allow receiving payments (e.g., listing fees, license fees)
    receive() external payable {}
    fallback() external payable {}
}
```