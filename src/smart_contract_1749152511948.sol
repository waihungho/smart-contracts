Okay, let's design a smart contract for a Decentralized AI Model Marketplace. This goes beyond simple token transfers or basic NFTs by managing licenses, tracking usage conceptually (via licenses), handling earnings distribution, and incorporating features like tagging and rating.

It's complex enough to offer various functions (aiming for 20+), uses the trendy concept of AI/ML (managing access to off-chain models), and incorporates mechanisms like licensing, platform fees, and a basic rating system. It's not a direct copy of standard OpenZeppelin contracts or basic examples.

**Concept:** A marketplace where AI model developers (Providers) can list their models (accessible off-chain via URIs/APIs), and users (Consumers) can purchase perpetual licenses to access these models. The contract manages the payments, distributes earnings to providers (minus a platform fee), and tracks licenses.

---

**Outline and Function Summary:**

**Contract Name:** `DecentralizedAIModelHub`

**Core Concept:** A decentralized marketplace for AI model licenses. Providers list models with prices, consumers purchase licenses, the contract handles payments and distribution, and tracks licenses.

**Key Features:**
1.  **Model Listing:** Providers can register their AI models with details, access URIs, and prices.
2.  **License Purchase:** Consumers can buy perpetual licenses for listed models. Payment in ETH is handled by the contract.
3.  **Earnings Distribution:** Purchased license funds (minus platform fee) are held by the contract and can be withdrawn by providers.
4.  **License Management:** Tracks purchased licenses per consumer and model.
5.  **Model Discovery:** Functions to query models by provider, tags, or get overall lists/counts.
6.  **Rating System:** Consumers with licenses can rate models.
7.  **Platform Fees:** Configurable fee for the marketplace owner.
8.  **Admin Controls:** Owner functions for setting fees and recipient.

**Data Structures:**
*   `Model`: Stores details about an AI model (provider, name, description, price, access URI, status, tags, rating info).
*   `License`: Stores details about a purchased license (model ID, consumer, purchase timestamp, price paid).

**Functions Summary (26 Functions):**

*   **Provider Functions:**
    1.  `listModel`: Register a new AI model for sale.
    2.  `updateModelDetails`: Update name, description, or access URI of an owned model.
    3.  `updateModelPrice`: Change the price of an owned model.
    4.  `delistModel`: Temporarily remove an owned model from the marketplace.
    5.  `relistModel`: Make a delisted model available again.
    6.  `withdrawEarnings`: Withdraw accumulated earnings from sold licenses.
    7.  `addModelTag`: Add a tag to an owned model.
    8.  `removeModelTag`: Remove a tag from an owned model.

*   **Consumer Functions:**
    9.  `purchaseLicense`: Buy a perpetual license for a specified model. Pays in ETH.
    10. `getUserLicenses`: Get a list of license IDs owned by the caller.
    11. `getModelLicenseDetails`: Get details of a specific license ID.
    12. `checkLicenseHolder`: Check if a specific address holds a license for a given model.
    13. `rateModel`: Submit a rating for a model after purchasing a license.

*   **Query & Discovery Functions:**
    14. `getModelDetails`: Get details of a specific model ID.
    15. `getAllListedModelIds`: Get a list of all currently listed model IDs (caution: gas).
    16. `getModelsByProvider`: Get a list of model IDs owned by a specific provider.
    17. `getProviderEarnings`: Check the pending earnings for a provider.
    18. `getTotalModels`: Get the total number of models registered.
    19. `getTotalLicenses`: Get the total number of licenses ever purchased.
    20. `getModelTags`: Get the list of tags for a specific model.
    21. `getModelsByTag`: Get a list of model IDs associated with a specific tag (caution: gas).
    22. `getAverageModelRating`: Get the average rating for a specific model.
    23. `hasUserRatedModel`: Check if a user has already rated a specific model.

*   **Admin Functions (Owner Only):**
    24. `setPlatformFee`: Set the marketplace platform fee percentage (in basis points).
    25. `setPlatformFeeRecipient`: Set the address that receives the platform fees.
    26. `getPlatformFee`: Get the current platform fee percentage.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DecentralizedAIModelHub
 * @dev A decentralized marketplace for AI model licenses.
 * Providers can list models, Consumers can purchase perpetual licenses.
 * The contract handles payment distribution, license tracking, and platform fees.
 * Features include tagging, basic rating, and admin controls.
 */
contract DecentralizedAIModelHub {

    address public immutable owner;
    uint256 private nextModelId;
    uint256 private nextLicenseId;

    // Platform fee in basis points (e.g., 100 = 1%, 500 = 5%)
    uint256 public platformFeeBasisPoints;
    address payable public platformFeeRecipient;

    // --- Data Structures ---

    enum ModelStatus { Listed, Delisted }

    struct Model {
        address provider;
        string name;
        string description;
        string accessURI; // URI or endpoint for accessing the model off-chain
        uint256 price; // Price in Wei
        ModelStatus status;
        string[] tags;
        uint256 totalRatings;
        uint256 ratingSum; // Sum of all ratings (e.g., out of 5)
    }

    struct License {
        uint256 modelId;
        address consumer;
        uint256 purchaseTimestamp;
        uint256 pricePaid; // Price paid at the time of purchase
        // Note: This example uses perpetual licenses. Expiration logic could be added.
    }

    // --- State Variables ---

    mapping(uint256 => Model) public models;
    mapping(address => uint256[]) public modelsByProvider; // Provider address => List of model IDs
    mapping(uint256 => uint256[]) public modelTagsIndex; // Tag hash/ID => List of model IDs (less gas-efficient for dynamic tags) - Let's store tags in struct and potentially build an index off-chain or add a mapping here. Storing in struct is simpler for now.
    mapping(uint256 => mapping(address => bool)) public userRatedModel; // modelId => consumerAddress => bool (has rated)

    mapping(uint256 => License) public licenses;
    mapping(address => uint256[]) public licensesByConsumer; // Consumer address => List of license IDs

    mapping(address => uint256) public providerEarnings; // Provider address => Accumulated earnings (Wei)

    // --- Events ---

    event ModelListed(uint256 indexed modelId, address indexed provider, string name, uint256 price);
    event ModelUpdated(uint256 indexed modelId, address indexed provider, string name);
    event ModelStatusUpdated(uint256 indexed modelId, ModelStatus newStatus);
    event ModelPriceUpdated(uint256 indexed modelId, uint256 newPrice);
    event ModelTagAdded(uint256 indexed modelId, string tag);
    event ModelTagRemoved(uint256 indexed modelId, string tag);

    event LicensePurchased(uint256 indexed licenseId, uint256 indexed modelId, address indexed consumer, uint256 pricePaid);

    event EarningsWithdrawn(address indexed provider, uint256 amount);

    event PlatformFeeUpdated(uint256 newFeeBasisPoints);
    event PlatformFeeRecipientUpdated(address indexed newRecipient);

    event ModelRated(uint256 indexed modelId, address indexed consumer, uint256 rating);


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyProvider(uint256 _modelId) {
        require(models[_modelId].provider == msg.sender, "Only model provider");
        _;
    }

    modifier modelExists(uint256 _modelId) {
        require(models[_modelId].provider != address(0), "Model does not exist");
        _;
    }

    modifier isListed(uint256 _modelId) {
        require(models[_modelId].status == ModelStatus.Listed, "Model not listed");
        _;
    }

    modifier hasLicenseForModel(uint256 _modelId, address _consumer) {
         // Iterate through consumer's licenses to find one for this model
         bool found = false;
         uint256[] storage consumerLicenses = licensesByConsumer[_consumer];
         for (uint i = 0; i < consumerLicenses.length; i++) {
             if (licenses[consumerLicenses[i]].modelId == _modelId) {
                 // For perpetual licenses, presence is enough. For timed, check expiry here.
                 found = true;
                 break;
             }
         }
         require(found, "Consumer does not have a license for this model");
         _;
    }


    // --- Constructor ---

    constructor(uint256 _initialFeeBasisPoints, address payable _initialFeeRecipient) {
        owner = msg.sender;
        nextModelId = 1;
        nextLicenseId = 1;
        platformFeeBasisPoints = _initialFeeBasisPoints;
        platformFeeRecipient = _initialFeeRecipient;
        require(_initialFeeBasisPoints <= 10000, "Fee cannot exceed 100%"); // 10000 basis points = 100%
        require(_initialFeeRecipient != address(0), "Fee recipient cannot be zero address");
    }

    // --- Provider Functions ---

    /**
     * @dev Lists a new AI model on the marketplace.
     * @param _name The name of the model.
     * @param _description A description of the model.
     * @param _accessURI The URI or endpoint for accessing the model off-chain.
     * @param _price The price of a perpetual license in Wei.
     * @param _tags Initial tags for the model.
     */
    function listModel(string memory _name, string memory _description, string memory _accessURI, uint256 _price, string[] memory _tags) external {
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_accessURI).length > 0, "Access URI cannot be empty");
        require(_price > 0, "Price must be greater than zero");

        uint256 modelId = nextModelId++;
        models[modelId] = Model({
            provider: msg.sender,
            name: _name,
            description: _description,
            accessURI: _accessURI,
            price: _price,
            status: ModelStatus.Listed,
            tags: _tags, // Directly assign tags
            totalRatings: 0,
            ratingSum: 0
        });

        modelsByProvider[msg.sender].push(modelId);

        emit ModelListed(modelId, msg.sender, _name, _price);
    }

    /**
     * @dev Updates the details (name, description, accessURI) of an owned model.
     * @param _modelId The ID of the model to update.
     * @param _name The new name.
     * @param _description The new description.
     * @param _accessURI The new access URI.
     */
    function updateModelDetails(uint256 _modelId, string memory _name, string memory _description, string memory _accessURI)
        external
        modelExists(_modelId)
        onlyProvider(_modelId)
    {
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_accessURI).length > 0, "Access URI cannot be empty");

        Model storage model = models[_modelId];
        model.name = _name;
        model.description = _description;
        model.accessURI = _accessURI;

        emit ModelUpdated(_modelId, msg.sender, _name);
    }

    /**
     * @dev Updates the price of an owned model.
     * @param _modelId The ID of the model to update.
     * @param _newPrice The new price in Wei.
     */
    function updateModelPrice(uint256 _modelId, uint256 _newPrice)
        external
        modelExists(_modelId)
        onlyProvider(_modelId)
    {
        require(_newPrice > 0, "Price must be greater than zero");
        models[_modelId].price = _newPrice;

        emit ModelPriceUpdated(_modelId, _newPrice);
    }

    /**
     * @dev Delists an owned model, preventing new licenses from being purchased.
     * Existing licenses remain valid.
     * @param _modelId The ID of the model to delist.
     */
    function delistModel(uint256 _modelId)
        external
        modelExists(_modelId)
        onlyProvider(_modelId)
        isListed(_modelId)
    {
        models[_modelId].status = ModelStatus.Delisted;
        emit ModelStatusUpdated(_modelId, ModelStatus.Delisted);
    }

    /**
     * @dev Relists an owned model that was previously delisted.
     * @param _modelId The ID of the model to relist.
     */
    function relistModel(uint256 _modelId)
        external
        modelExists(_modelId)
        onlyProvider(_modelId)
    {
        require(models[_modelId].status == ModelStatus.Delisted, "Model is not delisted");
        models[_modelId].status = ModelStatus.Listed;
        emit ModelStatusUpdated(_modelId, ModelStatus.Listed);
    }

    /**
     * @dev Allows a provider to withdraw their accumulated earnings.
     */
    function withdrawEarnings() external {
        uint256 amount = providerEarnings[msg.sender];
        require(amount > 0, "No earnings to withdraw");

        providerEarnings[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");

        emit EarningsWithdrawn(msg.sender, amount);
    }

    /**
     * @dev Adds a tag to an owned model.
     * @param _modelId The ID of the model.
     * @param _tag The tag to add.
     */
    function addModelTag(uint256 _modelId, string memory _tag)
        external
        modelExists(_modelId)
        onlyProvider(_modelId)
    {
        require(bytes(_tag).length > 0, "Tag cannot be empty");

        Model storage model = models[_modelId];
        // Check if tag already exists (simple check, could be optimized)
        for (uint i = 0; i < model.tags.length; i++) {
            if (keccak256(bytes(model.tags[i])) == keccak256(bytes(_tag))) {
                return; // Tag already exists, do nothing
            }
        }

        model.tags.push(_tag);
        emit ModelTagAdded(_modelId, _tag);
    }

    /**
     * @dev Removes a tag from an owned model.
     * @param _modelId The ID of the model.
     * @param _tag The tag to remove.
     */
    function removeModelTag(uint256 _modelId, string memory _tag)
        external
        modelExists(_modelId)
        onlyProvider(_modelId)
    {
        require(bytes(_tag).length > 0, "Tag cannot be empty");

        Model storage model = models[_modelId];
        uint256 tagIndex = type(uint256).max;

        // Find the index of the tag
        for (uint i = 0; i < model.tags.length; i++) {
            if (keccak256(bytes(model.tags[i])) == keccak256(bytes(_tag))) {
                tagIndex = i;
                break;
            }
        }

        require(tagIndex != type(uint256).max, "Tag not found");

        // Remove tag by swapping with last element and reducing array length
        if (tagIndex < model.tags.length - 1) {
            model.tags[tagIndex] = model.tags[model.tags.length - 1];
        }
        model.tags.pop();

        emit ModelTagRemoved(_modelId, _tag);
    }


    // --- Consumer Functions ---

    /**
     * @dev Purchases a perpetual license for a listed model.
     * Requires sending the exact model price in ETH with the transaction.
     * @param _modelId The ID of the model to purchase a license for.
     */
    function purchaseLicense(uint256 _modelId)
        external
        payable
        modelExists(_modelId)
        isListed(_modelId)
    {
        Model storage model = models[_modelId];
        require(msg.value >= model.price, "Insufficient ETH sent");

        // Check if the user already has a license for this model
        uint256[] storage consumerLicenses = licensesByConsumer[msg.sender];
         for (uint i = 0; i < consumerLicenses.length; i++) {
             if (licenses[consumerLicenses[i]].modelId == _modelId) {
                 // Already has a license, refund all ETH
                 (bool success, ) = msg.sender.call{value: msg.value}("");
                 require(success, "Refund failed on existing license");
                 return; // Do not issue a new license
             }
         }

        uint256 licenseId = nextLicenseId++;
        uint256 platformCut = (model.price * platformFeeBasisPoints) / 10000; // Calculate fee

        licenses[licenseId] = License({
            modelId: _modelId,
            consumer: msg.sender,
            purchaseTimestamp: block.timestamp,
            pricePaid: model.price
        });

        licensesByConsumer[msg.sender].push(licenseId);

        // Distribute funds
        uint256 providerAmount = model.price - platformCut;

        // Transfer platform fee
        if (platformCut > 0) {
            (bool successFee, ) = platformFeeRecipient.call{value: platformCut}("");
            require(successFee, "Platform fee transfer failed");
        }

        // Add remaining to provider's earnings
        if (providerAmount > 0) {
            providerEarnings[model.provider] += providerAmount;
        }

        // Refund any excess ETH sent
        if (msg.value > model.price) {
            (bool successRefund, ) = msg.sender.call{value: msg.value - model.price}("");
            require(successRefund, "Excess ETH refund failed");
        }

        emit LicensePurchased(licenseId, _modelId, msg.sender, model.price);
    }

    /**
     * @dev Gets a list of license IDs owned by the caller.
     * @return An array of license IDs.
     */
    function getUserLicenses() external view returns (uint256[] memory) {
        return licensesByConsumer[msg.sender];
    }

    /**
     * @dev Gets the details for a specific license ID.
     * @param _licenseId The ID of the license.
     * @return The License struct details.
     */
    function getModelLicenseDetails(uint256 _licenseId) external view returns (License memory) {
        require(licenses[_licenseId].consumer != address(0), "License does not exist");
        require(licenses[_licenseId].consumer == msg.sender, "Not your license");
        return licenses[_licenseId];
    }

     /**
      * @dev Checks if a specific address holds a license for a given model.
      * Useful for integration with off-chain model access control.
      * @param _modelId The ID of the model.
      * @param _consumer The address to check.
      * @return True if the address holds a license for the model, false otherwise.
      */
    function checkLicenseHolder(uint256 _modelId, address _consumer) external view modelExists(_modelId) returns (bool) {
         uint256[] storage consumerLicenses = licensesByConsumer[_consumer];
         for (uint i = 0; i < consumerLicenses.length; i++) {
             if (licenses[consumerLicenses[i]].modelId == _modelId) {
                 // For perpetual licenses, presence is enough. For timed, check expiry here.
                 return true;
             }
         }
         return false;
    }

    /**
     * @dev Allows a user who holds a license for a model to rate it.
     * Users can only rate a model once.
     * @param _modelId The ID of the model to rate.
     * @param _rating The rating value (e.g., 1-5).
     */
    function rateModel(uint256 _modelId, uint256 _rating)
        external
        modelExists(_modelId)
        hasLicenseForModel(_modelId, msg.sender)
    {
        require(_rating > 0 && _rating <= 5, "Rating must be between 1 and 5");
        require(!userRatedModel[_modelId][msg.sender], "User has already rated this model");

        Model storage model = models[_modelId];
        model.ratingSum += _rating;
        model.totalRatings += 1;
        userRatedModel[_modelId][msg.sender] = true;

        emit ModelRated(_modelId, msg.sender, _rating);
    }

    // --- Query & Discovery Functions ---

    /**
     * @dev Gets the details of a specific model by ID.
     * @param _modelId The ID of the model.
     * @return The Model struct details.
     */
    function getModelDetails(uint256 _modelId) external view modelExists(_modelId) returns (Model memory) {
        return models[_modelId];
    }

    /**
     * @dev Gets a list of all currently listed model IDs.
     * @dev WARNING: This function can be very gas-intensive if there are many models.
     * Consider using off-chain indexing or fetching models by provider/tag instead.
     * @return An array of listed model IDs.
     */
    function getAllListedModelIds() external view returns (uint256[] memory) {
        uint256[] memory listedIds = new uint256[](nextModelId - 1);
        uint256 count = 0;
        for (uint i = 1; i < nextModelId; i++) {
            if (models[i].status == ModelStatus.Listed) {
                listedIds[count] = i;
                count++;
            }
        }
        // Resize array to actual count
        uint26 storage listedIdsRef = listedIds; // Using a smaller type for reference helps avoid stack too deep
        uint256[] memory finalListedIds = new uint256[](count);
        for (uint i = 0; i < count; i++) {
            finalListedIds[i] = listedIdsRef[i]; // Use the reference
        }
        return finalListedIds;
    }


    /**
     * @dev Gets a list of model IDs owned by a specific provider.
     * @param _provider The address of the provider.
     * @return An array of model IDs.
     */
    function getModelsByProvider(address _provider) external view returns (uint256[] memory) {
        return modelsByProvider[_provider];
    }

    /**
     * @dev Gets the current pending earnings for a provider.
     * @param _provider The address of the provider.
     * @return The amount of earnings in Wei.
     */
    function getProviderEarnings(address _provider) external view returns (uint256) {
        return providerEarnings[_provider];
    }

    /**
     * @dev Gets the total number of models ever registered.
     * @return The total count.
     */
    function getTotalModels() external view returns (uint256) {
        return nextModelId - 1;
    }

    /**
     * @dev Gets the total number of licenses ever purchased.
     * @return The total count.
     */
    function getTotalLicenses() external view returns (uint256) {
        return nextLicenseId - 1;
    }

    /**
     * @dev Gets the list of tags associated with a specific model.
     * @param _modelId The ID of the model.
     * @return An array of tags.
     */
    function getModelTags(uint256 _modelId) external view modelExists(_modelId) returns (string[] memory) {
        return models[_modelId].tags;
    }

     /**
      * @dev Gets a list of model IDs that have a specific tag.
      * Searches through all models. Could be gas-intensive for many models/tags.
      * @param _tag The tag to search for.
      * @return An array of model IDs matching the tag.
      */
    function getModelsByTag(string memory _tag) external view returns (uint256[] memory) {
        require(bytes(_tag).length > 0, "Tag cannot be empty");

        uint256[] memory taggedModelIds = new uint256[](nextModelId - 1); // Max possible size
        uint256 count = 0;
        bytes32 tagHash = keccak256(bytes(_tag));

        for (uint i = 1; i < nextModelId; i++) {
            Model storage model = models[i];
             if (model.provider != address(0)) { // Ensure model exists
                for (uint j = 0; j < model.tags.length; j++) {
                    if (keccak256(bytes(model.tags[j])) == tagHash) {
                        taggedModelIds[count] = i;
                        count++;
                        break; // Found tag in this model, move to next model
                    }
                }
            }
        }

        // Resize array to actual count
        uint256[] memory finalTaggedModelIds = new uint256[](count);
        for (uint i = 0; i < count; i++) {
            finalTaggedModelIds[i] = taggedModelIds[i];
        }
        return finalTaggedModelIds;
    }


    /**
     * @dev Calculates and gets the average rating for a specific model.
     * Returns 0 if no ratings exist.
     * @param _modelId The ID of the model.
     * @return The average rating, multiplied by 100 to retain precision (e.g., 450 for 4.5 rating).
     */
    function getAverageModelRating(uint256 _modelId) external view modelExists(_modelId) returns (uint256) {
        Model storage model = models[_modelId];
        if (model.totalRatings == 0) {
            return 0; // No ratings yet
        }
        // Calculate average * 100 for basic fixed-point representation
        return (model.ratingSum * 100) / model.totalRatings;
    }

    /**
     * @dev Checks if a specific user has already rated a specific model.
     * @param _modelId The ID of the model.
     * @param _consumer The address of the user.
     * @return True if the user has rated, false otherwise.
     */
    function hasUserRatedModel(uint256 _modelId, address _consumer) external view modelExists(_modelId) returns (bool) {
        return userRatedModel[_modelId][_consumer];
    }


    // --- Admin Functions (Owner Only) ---

    /**
     * @dev Sets the marketplace platform fee percentage.
     * @param _newFeeBasisPoints The new fee percentage in basis points (0-10000).
     */
    function setPlatformFee(uint256 _newFeeBasisPoints) external onlyOwner {
        require(_newFeeBasisPoints <= 10000, "Fee cannot exceed 100%");
        platformFeeBasisPoints = _newFeeBasisPoints;
        emit PlatformFeeUpdated(_newFeeBasisPoints);
    }

    /**
     * @dev Sets the recipient address for platform fees.
     * @param _newRecipient The new recipient address.
     */
    function setPlatformFeeRecipient(address payable _newRecipient) external onlyOwner {
        require(_newRecipient != address(0), "Recipient cannot be zero address");
        platformFeeRecipient = _newRecipient;
        emit PlatformFeeRecipientUpdated(_newRecipient);
    }

    /**
     * @dev Gets the current platform fee percentage in basis points.
     * @return The current fee in basis points.
     */
    function getPlatformFee() external view returns (uint256) {
        return platformFeeBasisPoints;
    }

    // Fallback function to prevent accidental ETH sends without calling a payable function
    fallback() external payable {
        revert("ETH sent directly without calling a function");
    }

    receive() external payable {
        revert("ETH sent directly without calling a function");
    }
}
```