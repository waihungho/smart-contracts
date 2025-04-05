```solidity
/**
 * @title Decentralized AI Model Marketplace - "Synapse Marketplace"
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized marketplace where AI model creators can register,
 * sell access to, and manage their models. Consumers can discover, purchase access, and utilize these models.
 * This contract incorporates advanced concepts like reputation, royalties, data privacy (metadata URI),
 * and marketplace governance. It aims to be a creative and trendy application of blockchain in the AI space.
 *
 * **Outline:**
 * 1. **Model Registration & Management:** Functions for AI model providers to register, update, and manage their models.
 * 2. **Model Discovery & Access:** Functions for consumers to browse, search, and purchase access to models.
 * 3. **Access Control & Usage Tracking:** Mechanisms to control model access and potentially track usage (conceptually within the smart contract).
 * 4. **Payment & Royalties:**  Handling payments for model access and potential royalty distribution.
 * 5. **Reputation System:** A basic reputation system for model providers based on consumer feedback.
 * 6. **Data Privacy (Metadata URI):**  Using IPFS or similar for storing model metadata and ensuring data ownership.
 * 7. **Marketplace Governance (Basic):**  Simple functions for marketplace administration and dispute resolution.
 * 8. **Advanced Features:** Ideas for future expansion like model versioning, subscription models, and data integration.
 *
 * **Function Summary:**
 * 1. `registerModel(string _modelName, string _modelDescription, uint256 _accessPrice, string _metadataURI)`: Allows model providers to register a new AI model on the marketplace.
 * 2. `updateModelMetadata(uint256 _modelId, string _newMetadataURI)`: Allows model providers to update the metadata URI of their registered model.
 * 3. `updateModelPrice(uint256 _modelId, uint256 _newAccessPrice)`: Allows model providers to change the access price of their model.
 * 4. `setModelStatus(uint256 _modelId, ModelStatus _newStatus)`: Allows model providers to change the status of their model (Active, Inactive, Under Review).
 * 5. `getModelDetails(uint256 _modelId)`: Retrieves detailed information about a specific AI model.
 * 6. `purchaseModelAccess(uint256 _modelId)`: Allows consumers to purchase access to a model.
 * 7. `hasAccess(uint256 _modelId, address _consumer)`: Checks if a consumer has access to a specific model.
 * 8. `extendAccess(uint256 _modelId, address _consumer, uint256 _durationInSeconds)`: Allows extending access time for a consumer (e.g., for subscriptions or renewals).
 * 9. `submitModelFeedback(uint256 _modelId, uint8 _rating, string _comment)`: Allows consumers to submit feedback and ratings for a model they have used.
 * 10. `getModelAverageRating(uint256 _modelId)`: Retrieves the average rating for a specific model.
 * 11. `withdrawProviderEarnings()`: Allows model providers to withdraw their earnings from model access sales.
 * 12. `setMarketplaceFee(uint256 _newFeePercentage)`: Allows the marketplace owner to set the marketplace fee percentage.
 * 13. `getMarketplaceFee()`: Retrieves the current marketplace fee percentage.
 * 14. `pauseMarketplace()`: Allows the marketplace owner to pause the entire marketplace.
 * 15. `unpauseMarketplace()`: Allows the marketplace owner to unpause the marketplace.
 * 16. `reportModel(uint256 _modelId, string _reportReason)`: Allows users to report a model for policy violations or issues.
 * 17. `resolveReport(uint256 _reportId, ResolutionStatus _resolution)`: Allows the marketplace owner to resolve a reported model issue.
 * 18. `getModelCount()`: Returns the total number of registered models.
 * 19. `getActiveModelCount()`: Returns the number of currently active models.
 * 20. `getModelsByProvider(address _provider)`: Returns a list of model IDs registered by a specific provider.
 * 21. `searchModels(string _searchTerm)`: (Conceptual) Allows searching for models based on keywords (implementation would require off-chain indexing for efficiency in a real-world scenario).
 * 22. `getAccessExpiry(uint256 _modelId, address _consumer)`: Returns the expiry timestamp of a consumer's access to a model.
 */
pragma solidity ^0.8.0;

contract SynapseMarketplace {
    enum ModelStatus { Active, Inactive, UnderReview, Deprecated }
    enum ResolutionStatus { Resolved, Rejected }

    struct Model {
        uint256 id;
        address provider;
        string name;
        string description;
        uint256 accessPrice;
        string metadataURI; // IPFS URI or similar for model details
        ModelStatus status;
        uint256 registrationTimestamp;
        uint256 averageRating; // Basic reputation score
        uint256 feedbackCount;
    }

    struct AccessRecord {
        uint256 expiryTimestamp;
    }

    struct Report {
        uint256 id;
        uint256 modelId;
        address reporter;
        string reason;
        ResolutionStatus status;
        uint256 reportTimestamp;
    }

    mapping(uint256 => Model) public models;
    mapping(uint256 => mapping(address => AccessRecord)) public modelAccess; // modelId => (consumer => AccessRecord)
    mapping(uint256 => Report) public reports;
    mapping(uint256 => uint8[]) public modelRatings; // modelId => array of ratings

    uint256 public modelCount = 0;
    uint256 public reportCount = 0;
    uint256 public marketplaceFeePercentage = 5; // 5% marketplace fee
    address public marketplaceOwner;
    bool public marketplacePaused = false;

    event ModelRegistered(uint256 modelId, address provider, string modelName);
    event ModelMetadataUpdated(uint256 modelId, string newMetadataURI);
    event ModelPriceUpdated(uint256 modelId, uint256 newPrice);
    event ModelStatusUpdated(uint256 modelId, ModelStatus newStatus);
    event AccessPurchased(uint256 modelId, address consumer);
    event FeedbackSubmitted(uint256 modelId, address consumer, uint8 rating, string comment);
    event EarningsWithdrawn(address provider, uint256 amount);
    event MarketplaceFeeUpdated(uint256 newFeePercentage);
    event MarketplacePaused();
    event MarketplaceUnpaused();
    event ModelReported(uint256 reportId, uint256 modelId, address reporter, string reason);
    event ReportResolved(uint256 reportId, ResolutionStatus resolution);

    modifier onlyOwner() {
        require(msg.sender == marketplaceOwner, "Only marketplace owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!marketplacePaused, "Marketplace is currently paused.");
        _;
    }

    modifier modelExists(uint256 _modelId) {
        require(_modelId > 0 && _modelId <= modelCount && models[_modelId].id == _modelId, "Model does not exist.");
        _;
    }

    modifier onlyModelProvider(uint256 _modelId) {
        require(models[_modelId].provider == msg.sender, "Only model provider can call this function.");
        _;
    }

    constructor() {
        marketplaceOwner = msg.sender;
    }

    /// ------------------------------------------------------------------------
    ///                            Model Registration & Management
    /// ------------------------------------------------------------------------

    /**
     * @dev Registers a new AI model on the marketplace.
     * @param _modelName The name of the AI model.
     * @param _modelDescription A brief description of the model.
     * @param _accessPrice The price to access the model.
     * @param _metadataURI URI pointing to the model's metadata (e.g., IPFS hash).
     */
    function registerModel(
        string memory _modelName,
        string memory _modelDescription,
        uint256 _accessPrice,
        string memory _metadataURI
    ) public whenNotPaused {
        require(bytes(_modelName).length > 0 && bytes(_modelName).length <= 100, "Model name must be between 1 and 100 characters.");
        require(bytes(_modelDescription).length <= 500, "Model description must be at most 500 characters.");
        require(_accessPrice > 0, "Access price must be greater than zero.");
        require(bytes(_metadataURI).length > 0 && bytes(_metadataURI).length <= 200, "Metadata URI must be between 1 and 200 characters.");

        modelCount++;
        models[modelCount] = Model({
            id: modelCount,
            provider: msg.sender,
            name: _modelName,
            description: _modelDescription,
            accessPrice: _accessPrice,
            metadataURI: _metadataURI,
            status: ModelStatus.Active,
            registrationTimestamp: block.timestamp,
            averageRating: 0,
            feedbackCount: 0
        });

        emit ModelRegistered(modelCount, msg.sender, _modelName);
    }

    /**
     * @dev Updates the metadata URI of a registered model.
     * @param _modelId The ID of the model to update.
     * @param _newMetadataURI The new metadata URI.
     */
    function updateModelMetadata(uint256 _modelId, string memory _newMetadataURI)
        public
        modelExists(_modelId)
        onlyModelProvider(_modelId)
        whenNotPaused
    {
        require(bytes(_newMetadataURI).length > 0 && bytes(_newMetadataURI).length <= 200, "Metadata URI must be between 1 and 200 characters.");
        models[_modelId].metadataURI = _newMetadataURI;
        emit ModelMetadataUpdated(_modelId, _newMetadataURI);
    }

    /**
     * @dev Updates the access price of a registered model.
     * @param _modelId The ID of the model to update.
     * @param _newAccessPrice The new access price.
     */
    function updateModelPrice(uint256 _modelId, uint256 _newAccessPrice)
        public
        modelExists(_modelId)
        onlyModelProvider(_modelId)
        whenNotPaused
    {
        require(_newAccessPrice > 0, "Access price must be greater than zero.");
        models[_modelId].accessPrice = _newAccessPrice;
        emit ModelPriceUpdated(_modelId, _newAccessPrice);
    }

    /**
     * @dev Sets the status of a registered model (Active, Inactive, Under Review, Deprecated).
     * @param _modelId The ID of the model to update.
     * @param _newStatus The new status for the model.
     */
    function setModelStatus(uint256 _modelId, ModelStatus _newStatus)
        public
        modelExists(_modelId)
        onlyModelProvider(_modelId)
        whenNotPaused
    {
        models[_modelId].status = _newStatus;
        emit ModelStatusUpdated(_modelId, _newStatus);
    }

    /// ------------------------------------------------------------------------
    ///                            Model Discovery & Access
    /// ------------------------------------------------------------------------

    /**
     * @dev Retrieves detailed information about a specific AI model.
     * @param _modelId The ID of the model to retrieve details for.
     * @return Model struct containing model details.
     */
    function getModelDetails(uint256 _modelId)
        public
        view
        modelExists(_modelId)
        returns (Model memory)
    {
        return models[_modelId];
    }

    /**
     * @dev Allows consumers to purchase access to a model.
     * @param _modelId The ID of the model to purchase access to.
     */
    function purchaseModelAccess(uint256 _modelId)
        public
        payable
        modelExists(_modelId)
        whenNotPaused
    {
        require(models[_modelId].status == ModelStatus.Active, "Model is not currently active.");
        require(!hasAccess(_modelId, msg.sender), "You already have access to this model.");
        require(msg.value >= models[_modelId].accessPrice, "Insufficient payment to access the model.");

        uint256 marketplaceFee = (models[_modelId].accessPrice * marketplaceFeePercentage) / 100;
        uint256 providerShare = models[_modelId].accessPrice - marketplaceFee;

        // Transfer funds to the model provider (after deducting marketplace fee)
        payable(models[_modelId].provider).transfer(providerShare);

        // Transfer marketplace fee to the marketplace owner
        payable(marketplaceOwner).transfer(marketplaceFee);

        // Grant access for a default duration (e.g., 30 days - can be configurable)
        modelAccess[_modelId][msg.sender].expiryTimestamp = block.timestamp + (30 days); // Example: 30 days access

        emit AccessPurchased(_modelId, msg.sender);
    }

    /**
     * @dev Checks if a consumer has access to a specific model.
     * @param _modelId The ID of the model to check access for.
     * @param _consumer The address of the consumer to check.
     * @return True if the consumer has access, false otherwise.
     */
    function hasAccess(uint256 _modelId, address _consumer)
        public
        view
        modelExists(_modelId)
        returns (bool)
    {
        return modelAccess[_modelId][_consumer].expiryTimestamp > block.timestamp;
    }

    /**
     * @dev Extends access time for a consumer to a specific model. (For subscription models or renewals)
     * @param _modelId The ID of the model to extend access for.
     * @param _consumer The address of the consumer whose access to extend.
     * @param _durationInSeconds The duration in seconds to extend access for.
     */
    function extendAccess(uint256 _modelId, address _consumer, uint256 _durationInSeconds)
        public
        modelExists(_modelId)
        onlyModelProvider(_modelId) // Or allow consumer to extend their own access with payment
        whenNotPaused
    {
        modelAccess[_modelId][_consumer].expiryTimestamp += _durationInSeconds;
    }

    /// ------------------------------------------------------------------------
    ///                            Reputation System & Feedback
    /// ------------------------------------------------------------------------

    /**
     * @dev Allows consumers to submit feedback and a rating for a model they have used.
     * @param _modelId The ID of the model to provide feedback for.
     * @param _rating A rating out of 5 (e.g., 1 to 5).
     * @param _comment Optional comment about the model.
     */
    function submitModelFeedback(uint256 _modelId, uint8 _rating, string memory _comment)
        public
        modelExists(_modelId)
        whenNotPaused
    {
        require(hasAccess(_modelId, msg.sender), "You must have access to the model to provide feedback.");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5.");
        require(bytes(_comment).length <= 200, "Comment must be at most 200 characters.");

        modelRatings[_modelId].push(_rating);
        models[_modelId].feedbackCount++;

        uint256 ratingSum = 0;
        for (uint8 rating in modelRatings[_modelId]) {
            ratingSum += rating;
        }
        models[_modelId].averageRating = ratingSum / modelRatings[_modelId].length; // Simple average

        emit FeedbackSubmitted(_modelId, msg.sender, _rating, _comment);
    }

    /**
     * @dev Retrieves the average rating for a specific model.
     * @param _modelId The ID of the model to get the average rating for.
     * @return The average rating (out of 5).
     */
    function getModelAverageRating(uint256 _modelId)
        public
        view
        modelExists(_modelId)
        returns (uint256)
    {
        return models[_modelId].averageRating;
    }

    /// ------------------------------------------------------------------------
    ///                            Payment & Royalties (Withdrawal)
    /// ------------------------------------------------------------------------

    /**
     * @dev Allows model providers to withdraw their accumulated earnings from model access sales.
     *  (In this simplified example, earnings are directly transferred in `purchaseModelAccess`,
     *   but in a more complex system, earnings could accumulate in the contract).
     */
    function withdrawProviderEarnings() public {
        // In this example, earnings are transferred directly during purchase.
        // In a real-world scenario, you might track provider balances and allow withdrawal.
        // For simplicity, this function is left as a placeholder, or could be used for withdrawing
        // any marketplace fees that might have been accidentally sent to the provider address.

        // For demonstration, let's assume providers could accidentally send funds to this contract.
        // This function would allow them to withdraw any such funds.
        uint256 balance = address(this).balance;
        require(balance > 0, "No earnings to withdraw.");

        payable(msg.sender).transfer(balance); // Transfer entire contract balance to the provider (msg.sender)
        emit EarningsWithdrawn(msg.sender, balance);
    }


    /// ------------------------------------------------------------------------
    ///                            Marketplace Governance & Administration
    /// ------------------------------------------------------------------------

    /**
     * @dev Sets the marketplace fee percentage. Only callable by the marketplace owner.
     * @param _newFeePercentage The new marketplace fee percentage (e.g., 5 for 5%).
     */
    function setMarketplaceFee(uint256 _newFeePercentage) public onlyOwner {
        require(_newFeePercentage <= 20, "Marketplace fee percentage cannot exceed 20%."); // Example limit
        marketplaceFeePercentage = _newFeePercentage;
        emit MarketplaceFeeUpdated(_newFeePercentage);
    }

    /**
     * @dev Retrieves the current marketplace fee percentage.
     * @return The current marketplace fee percentage.
     */
    function getMarketplaceFee() public view returns (uint256) {
        return marketplaceFeePercentage;
    }

    /**
     * @dev Pauses the entire marketplace, preventing new model registrations and purchases.
     *  Only callable by the marketplace owner.
     */
    function pauseMarketplace() public onlyOwner {
        marketplacePaused = true;
        emit MarketplacePaused();
    }

    /**
     * @dev Unpauses the marketplace, allowing normal operations.
     * Only callable by the marketplace owner.
     */
    function unpauseMarketplace() public onlyOwner {
        marketplacePaused = false;
        emit MarketplaceUnpaused();
    }

    /**
     * @dev Allows users to report a model for policy violations or other issues.
     * @param _modelId The ID of the model being reported.
     * @param _reportReason The reason for reporting the model.
     */
    function reportModel(uint256 _modelId, string memory _reportReason) public whenNotPaused {
        require(modelExists(_modelId), "Cannot report a non-existent model.");
        require(bytes(_reportReason).length > 0 && bytes(_reportReason).length <= 500, "Report reason must be between 1 and 500 characters.");

        reportCount++;
        reports[reportCount] = Report({
            id: reportCount,
            modelId: _modelId,
            reporter: msg.sender,
            reason: _reportReason,
            status: ResolutionStatus.Rejected, // Default status upon reporting
            reportTimestamp: block.timestamp
        });
        emit ModelReported(reportCount, _modelId, msg.sender, _reportReason);
    }

    /**
     * @dev Allows the marketplace owner to resolve a reported model issue.
     * @param _reportId The ID of the report to resolve.
     * @param _resolution The resolution status (Resolved or Rejected).
     */
    function resolveReport(uint256 _reportId, ResolutionStatus _resolution) public onlyOwner whenNotPaused {
        require(_reportId > 0 && _reportId <= reportCount && reports[_reportId].id == _reportId, "Report does not exist.");
        reports[_reportId].status = _resolution;
        if (_resolution == ResolutionStatus.Resolved) {
            // Example action upon resolving a report - could be to deprecate the model, etc.
            setModelStatus(reports[_reportId].modelId, ModelStatus.UnderReview);
        }
        emit ReportResolved(_reportId, _resolution);
    }


    /// ------------------------------------------------------------------------
    ///                            Utility & Getter Functions
    /// ------------------------------------------------------------------------

    /**
     * @dev Returns the total number of registered models.
     * @return The total model count.
     */
    function getModelCount() public view returns (uint256) {
        return modelCount;
    }

    /**
     * @dev Returns the number of currently active models.
     * @return The count of active models.
     */
    function getActiveModelCount() public view returns (uint256) {
        uint256 activeCount = 0;
        for (uint256 i = 1; i <= modelCount; i++) {
            if (models[i].status == ModelStatus.Active) {
                activeCount++;
            }
        }
        return activeCount;
    }

    /**
     * @dev Returns a list of model IDs registered by a specific provider.
     * @param _provider The address of the model provider.
     * @return An array of model IDs.
     */
    function getModelsByProvider(address _provider) public view returns (uint256[] memory) {
        uint256[] memory providerModels = new uint256[](modelCount); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i <= modelCount; i++) {
            if (models[i].provider == _provider) {
                providerModels[count] = models[i].id;
                count++;
            }
        }
        // Resize the array to the actual number of models
        assembly {
            mstore(providerModels, count) // Update array length in memory
        }
        return providerModels;
    }

    /**
     * @dev (Conceptual - Requires off-chain indexing for efficiency in real-world use)
     * Allows searching for models based on keywords in their name or description.
     * @param _searchTerm The search term.
     * @return An array of model IDs that match the search term (conceptually - would need off-chain indexing).
     */
    function searchModels(string memory _searchTerm) public view returns (uint256[] memory) {
        // In a real-world application, this kind of on-chain string search is inefficient for a large number of models.
        // Efficient search would typically be handled off-chain with indexing (e.g., using The Graph, or a dedicated search index).
        // This is a conceptual example - for practical use, implement off-chain indexing.

        uint256[] memory searchResults = new uint256[](modelCount); // Max possible size
        uint256 count = 0;
        string memory lowerSearchTerm = _stringToLowerCase(_searchTerm);

        for (uint256 i = 1; i <= modelCount; i++) {
            string memory lowerModelName = _stringToLowerCase(models[i].name);
            string memory lowerModelDescription = _stringToLowerCase(models[i].description);

            if (_stringContains(lowerModelName, lowerSearchTerm) || _stringContains(lowerModelDescription, lowerSearchTerm)) {
                searchResults[count] = models[i].id;
                count++;
            }
        }
        // Resize the array
        assembly {
            mstore(searchResults, count)
        }
        return searchResults;
    }

    /**
     * @dev Returns the expiry timestamp of a consumer's access to a model.
     * @param _modelId The ID of the model.
     * @param _consumer The address of the consumer.
     * @return The expiry timestamp (0 if no access).
     */
    function getAccessExpiry(uint256 _modelId, address _consumer) public view modelExists(_modelId) returns (uint256) {
        return modelAccess[_modelId][_consumer].expiryTimestamp;
    }


    // --- Internal Helper Functions (String Manipulation for conceptual search - use with caution on-chain) ---
    function _stringToLowerCase(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            if ((bStr[i] >= uint8('A')) && (bStr[i] <= uint8('Z'))) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    function _stringContains(string memory haystack, string memory needle) internal pure returns (bool) {
        return stringContains(haystack, needle);
    }

    // --- Pure function for string contains (Gas intensive for on-chain search, use with caution) ---
    function stringContains(string memory haystack, string memory needle) public pure returns (bool) {
        bytes memory h = bytes(haystack);
        bytes memory n = bytes(needle);
        if (n.length == 0) {
            return true;
        }
        if (h.length < n.length) {
            return false;
        }
        uint nLengthMinus1 = n.length - 1;

        outer: for (uint i = 0; i <= (h.length - n.length); i++) {
            if (h[i] == n[0]) {
                for (uint j = 1; j <= nLengthMinus1; j++) {
                    if (h[i + j] != n[j]) {
                        continue outer;
                    }
                }
                return true;
            }
        }
        return false;
    }
}
```