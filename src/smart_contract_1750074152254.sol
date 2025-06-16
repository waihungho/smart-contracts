Okay, let's create a smart contract for a Decentralized AI Model and Service Marketplace. This involves concepts like digital asset listing (similar to NFTs but for models/datasets/services), licensing, payments, potential validation, and hooks for off-chain computation via oracles.

It won't duplicate standard ERC-20/721/1155, DeFi protocols, or simple escrow/marketplace contracts. It focuses on managing the *rights* and *metadata* associated with off-chain AI assets and coordinating payments/service requests.

---

**Outline and Function Summary**

**Contract Name:** `DecentralizedAIModelMarketplace`

**Description:**
A smart contract platform enabling creators to list, license, and monetize AI models, datasets, and inference services. Users can discover, purchase licenses for, and potentially request execution of these assets. It includes features for marketplace administration, model validation, and integration points for off-chain computation or data verification via oracle patterns.

**Key Concepts:**
*   **Model/Asset Listing:** Representing off-chain AI models/datasets/services with on-chain metadata and terms.
*   **Licensing:** Managing perpetual or time-limited access rights to listed assets.
*   **Payments:** Handling payment for licenses and potential usage fees (via oracle requests).
*   **Validation:** A mechanism for trusted parties (validators) to attest to the quality or properties of listed assets.
*   **Oracle Integration:** Providing hooks for requesting and receiving results from off-chain AI inference triggered by on-chain actions.
*   **Access Control:** Role-based permissions for owner, validators, and users.
*   **Pausability:** Emergency mechanism to pause sensitive operations.

**Functions Summary (26 Functions):**

1.  `constructor`: Initializes the contract owner and sets an initial marketplace fee.
2.  `setMarketplaceFee`: Allows the owner to update the fee percentage charged on license purchases.
3.  `withdrawMarketplaceFees`: Allows the owner to withdraw accumulated marketplace fees.
4.  `pauseContractActions`: Allows the owner to pause certain user actions (like buying licenses, requesting inference).
5.  `unpauseContractActions`: Allows the owner to unpause contract actions.
6.  `registerValidator`: Allows the owner to grant validator status to an address.
7.  `revokeValidator`: Allows the owner to remove validator status from an address.
8.  `isValidator`: Checks if an address is a registered validator. (View function)
9.  `listModel`: Allows a creator to list a new AI model/dataset/service. Requires metadata hash, price, and available license types. Emits `ModelListed`.
10. `updateModelMetadata`: Allows the model owner to update the off-chain metadata hash for their model. Emits `ModelUpdated`.
11. `updateModelPrice`: Allows the model owner to update the price per license for their model. Emits `ModelUpdated`.
12. `updateModelLicenseOptions`: Allows the model owner to update the available license types/terms for their model. Emits `ModelUpdated`.
13. `delistModel`: Allows the model owner to remove their model listing from the active marketplace. Emits `ModelDelisted`.
14. `transferModelOwnership`: Allows the current model owner to transfer ownership of the model listing to another address (akin to transferring an NFT). Emits `ModelOwnershipTransferred`.
15. `withdrawModelEarnings`: Allows the model owner to withdraw their accumulated earnings from license sales.
16. `purchaseLicense`: Allows a user to purchase a license for a listed model. Requires sending the correct payment. Calculates and deducts marketplace fee. Emits `LicensePurchased`.
17. `checkLicenseValidity`: Allows anyone to check if a specific address holds a valid license of a certain type for a model. (View function)
18. `getLicenseDetails`: Allows a user to retrieve the details of their specific license for a model and license type. (View function)
19. `requestInference`: Allows a user with a valid license to request off-chain AI inference using the model. Simulates an oracle request trigger. Requires payment for compute if applicable. Emits `InferenceRequested`.
20. `fulfillInferenceRequest`: (Intended for Oracle callback) Receives and stores the result hash of an off-chain inference request. Emits `InferenceFulfilled`. (Requires trust in the oracle or a ZKP layer off-chain).
21. `getInferenceResult`: Allows the requester to retrieve the result hash of their fulfilled inference request. (View function)
22. `submitModelValidation`: Allows a registered validator to submit a validation score or report hash for a specific model. Emits `ModelValidated`.
23. `getModelValidation`: Allows anyone to view the latest validation score/report details for a model. (View function)
24. `reportModel`: Allows any user to report a model listing for review (e.g., inappropriate content, non-functional asset). Emits `ModelReported`.
25. `getReportDetails`: Allows the owner/admin to view the details of a specific report. (View function)
26. `resolveReport`: Allows the owner/admin to mark a report as resolved after review. Emits `ReportResolved`.
27. `getModelDetails`: Allows anyone to view the public details of a listed model. (View function)
28. `getTotalListedModels`: Returns the total number of models that have ever been listed (includes delisted ones). (View function)
29. `getModelIdByIndex`: Helper function to get a model ID by its index in the internal list (for iterating through all models). (View function)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DecentralizedAIModelMarketplace
 * @dev A smart contract for listing, licensing, and managing AI models, datasets, and services.
 * It facilitates payments, tracks licenses, integrates potential validation, and provides oracle hooks
 * for triggering off-chain AI computation.
 *
 * Outline:
 * - State Variables & Data Structures: Defines structs for Model, License, InferenceRequest, Report, enums for status.
 * - Events: Defines events for transparency and off-chain monitoring.
 * - Modifiers: Custom modifiers for access control and contract state.
 * - Access Control: Owner, Validator, Oracle roles.
 * - Core Marketplace Logic: Listing, updating, delisting models.
 * - Licensing Logic: Purchasing, checking licenses.
 * - Payment Handling: Calculating fees, distributing earnings.
 * - Oracle Integration: Requesting and fulfilling off-chain computation.
 * - Validation Mechanism: Allowing validators to score models.
 * - Reporting Mechanism: Allowing users to report listings.
 * - Utility & View Functions: Getting model details, counts, etc.
 *
 * Function Summary:
 * (See detailed summary above the contract code)
 * constructor - Initialize owner and fees.
 * setMarketplaceFee - Update marketplace fee.
 * withdrawMarketplaceFees - Owner withdraws fees.
 * pauseContractActions - Owner pauses.
 * unpauseContractActions - Owner unpauses.
 * registerValidator - Owner grants validator status.
 * revokeValidator - Owner revokes validator status.
 * isValidator - Check validator status.
 * listModel - Creator lists a model.
 * updateModelMetadata - Model owner updates metadata.
 * updateModelPrice - Model owner updates price.
 * updateModelLicenseOptions - Model owner updates license types.
 * delistModel - Model owner delists model.
 * transferModelOwnership - Model owner transfers listing ownership.
 * withdrawModelEarnings - Model owner withdraws earnings.
 * purchaseLicense - User buys a license.
 * checkLicenseValidity - Check license validity.
 * getLicenseDetails - Get user's license details.
 * requestInference - User requests off-chain inference (via oracle).
 * fulfillInferenceRequest - Oracle callback for inference result.
 * getInferenceResult - Get inference result hash.
 * submitModelValidation - Validator submits score.
 * getModelValidation - Get validation score.
 * reportModel - User reports a model.
 * getReportDetails - Get report details (admin).
 * resolveReport - Admin resolves a report.
 * getModelDetails - Get public model details.
 * getTotalListedModels - Get total models ever listed.
 * getModelIdByIndex - Get model ID by index.
 */
contract DecentralizedAIModelMarketplace {

    address public immutable owner;
    uint256 public marketplaceFeePermille; // Fee in per mille (parts per 1000), e.g., 50 = 5%
    uint256 private marketplaceFeeBalance;

    enum ModelStatus { Listed, Delisted }
    enum ReportStatus { Open, Resolved }
    enum InferenceStatus { Requested, Fulfilled, Failed }

    struct Model {
        uint256 id;
        address owner;
        string metadataHash; // e.g., IPFS CID pointing to model details, files
        uint256 pricePerLicense; // Price in native token (wei) per license type
        uint256[] availableLicenseTypes; // e.g., 1=Personal, 2=Commercial, 3=Enterprise (defined off-chain)
        ModelStatus status;
        uint256 creationTime;
        uint256 lastUpdated;
        uint256 validationScore; // e.g., 0-100
        address validatorAddress; // Address of the last validator
        string validationReportHash; // e.g., IPFS CID for validation report
        uint256 validationTime;
        uint256 totalLicensesSold;
    }

    struct License {
        uint256 modelId;
        address licensee;
        uint256 purchaseTime;
        uint256 licenseType;
        // Potential future fields: uint256 expirationTime, uint256 usageCredits
    }

    struct InferenceRequest {
        uint256 requestId;
        uint256 modelId;
        address requester;
        string inputHash; // e.g., IPFS CID of input data
        string outputHash; // e.g., IPFS CID of output data (set by oracle)
        InferenceStatus status;
        uint256 requestTime;
        uint256 fulfillmentTime;
        // Potential future fields: uint256 paymentForCompute
    }

    struct Report {
        uint256 reportId;
        uint256 modelId;
        address reporter;
        string detailsHash; // e.g., IPFS CID for report details/evidence
        uint256 reportTime;
        ReportStatus status;
        address resolvedBy;
        uint256 resolvedTime;
    }

    mapping(uint256 => Model) public idToModel;
    uint256[] private listedModelIds; // Appended list, check status to see if active

    // modelId => licensee => licenseType => License details
    mapping(uint256 => mapping(address => mapping(uint256 => License))) public modelIdToLicenses;

    // For inference requests
    mapping(uint256 => InferenceRequest) public idToInferenceRequest;
    mapping(address => uint256[]) private userToInferenceRequests; // Track requests per user
    uint256 private nextInferenceRequestId = 1;

    // For reporting
    mapping(uint256 => Report) public idToReport;
    uint256 private nextReportId = 1;

    // For validation
    mapping(address => bool) public isValidator;
    // Note: Latest validation stored directly in the Model struct

    uint256 private nextModelId = 1;
    bool public paused = false;

    // Oracle address (example - could be a specific Chainlink Oracle contract address)
    address public oracleAddress; // Set by owner to allow only this address to fulfill requests

    // Events
    event MarketplaceFeeUpdated(uint256 indexed newFeePermille);
    event MarketplaceFeesWithdrawn(address indexed recipient, uint256 amount);
    event Paused(address account);
    event Unpaused(address account);
    event ValidatorRegistered(address indexed validator);
    event ValidatorRevoked(address indexed validator);
    event ModelListed(uint256 indexed modelId, address indexed owner, string metadataHash, uint256 price, uint256[] licenseTypes);
    event ModelUpdated(uint256 indexed modelId, address indexed updater, string metadataHash, uint256 price, uint256[] licenseTypes);
    event ModelDelisted(uint256 indexed modelId, address indexed owner);
    event ModelOwnershipTransferred(uint256 indexed modelId, address indexed previousOwner, address indexed newOwner);
    event ModelEarningsWithdrawn(uint256 indexed modelId, address indexed owner, uint256 amount);
    event LicensePurchased(uint256 indexed modelId, address indexed licensee, uint256 licenseType, uint256 pricePaid);
    event InferenceRequested(uint256 indexed requestId, uint256 indexed modelId, address indexed requester, string inputHash);
    event InferenceFulfilled(uint256 indexed requestId, string outputHash);
    event ModelValidated(uint256 indexed modelId, address indexed validator, uint256 score, string reportHash);
    event ModelReported(uint256 indexed reportId, uint256 indexed modelId, address indexed reporter, string detailsHash);
    event ReportResolved(uint256 indexed reportId, address indexed resolver);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyModelOwner(uint256 _modelId) {
        require(idToModel[_modelId].owner == msg.sender, "Only model owner");
        _;
    }

     // This modifier requires integration with a specific Oracle pattern (e.g., Chainlink's ChainlinkClient)
     // For this example, we simulate it with a simple address check.
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Only oracle");
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

    /// @dev Initializes the contract, setting the owner and initial marketplace fee.
    /// @param _initialMarketplaceFeePermille The initial fee percentage (in per mille, e.g., 50 for 5%).
    /// @param _oracleAddress The address of the trusted oracle contract/account for inference.
    constructor(uint256 _initialMarketplaceFeePermille, address _oracleAddress) {
        owner = msg.sender;
        marketplaceFeePermille = _initialMarketplaceFeePermille;
        oracleAddress = _oracleAddress;
    }

    // --- Admin Functions ---

    /// @notice Sets the marketplace fee percentage.
    /// @dev Fee is calculated per mille (parts per 1000). Max 1000 (100%).
    /// @param _newFeePermille The new fee percentage.
    function setMarketplaceFee(uint256 _newFeePermille) external onlyOwner {
        require(_newFeePermille <= 1000, "Fee must be <= 1000 permille (100%)");
        marketplaceFeePermille = _newFeePermille;
        emit MarketplaceFeeUpdated(_newFeePermille);
    }

    /// @notice Allows the owner to withdraw collected marketplace fees.
    function withdrawMarketplaceFees() external onlyOwner {
        uint256 balance = marketplaceFeeBalance;
        marketplaceFeeBalance = 0;
        require(balance > 0, "No fees to withdraw");
        (bool success, ) = payable(owner).call{value: balance}("");
        require(success, "Fee withdrawal failed");
        emit MarketplaceFeesWithdrawn(owner, balance);
    }

    /// @notice Pauses sensitive contract actions.
    function pauseContractActions() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /// @notice Unpauses sensitive contract actions.
    function unpauseContractActions() external onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /// @notice Grants validator status to an address.
    /// @param _validator The address to grant validator status.
    function registerValidator(address _validator) external onlyOwner {
        require(_validator != address(0), "Invalid address");
        require(!isValidator[_validator], "Address is already a validator");
        isValidator[_validator] = true;
        emit ValidatorRegistered(_validator);
    }

    /// @notice Revokes validator status from an address.
    /// @param _validator The address to revoke validator status.
    function revokeValidator(address _validator) external onlyOwner {
        require(isValidator[_validator], "Address is not a validator");
        isValidator[_validator] = false;
        emit ValidatorRevoked(_validator);
    }

    /// @notice Checks if an address is a registered validator.
    /// @param _addr The address to check.
    /// @return True if the address is a validator, false otherwise.
    function isValidator(address _addr) external view returns (bool) {
        return isValidator[_addr];
    }

    // --- Model Management Functions ---

    /// @notice Lists a new AI model, dataset, or service on the marketplace.
    /// @param _metadataHash IPFS hash or similar pointer to off-chain model details.
    /// @param _pricePerLicense Price in native tokens per license type.
    /// @param _availableLicenseTypes Array of license types available (interpreted off-chain).
    /// @return The ID of the newly listed model.
    function listModel(
        string memory _metadataHash,
        uint256 _pricePerLicense,
        uint256[] memory _availableLicenseTypes
    ) external whenNotPaused returns (uint256) {
        require(bytes(_metadataHash).length > 0, "Metadata hash required");
        require(_pricePerLicense > 0, "Price must be greater than 0");
        require(_availableLicenseTypes.length > 0, "At least one license type required");

        uint256 modelId = nextModelId++;
        idToModel[modelId] = Model({
            id: modelId,
            owner: msg.sender,
            metadataHash: _metadataHash,
            pricePerLicense: _pricePerLicense,
            availableLicenseTypes: _availableLicenseTypes,
            status: ModelStatus.Listed,
            creationTime: block.timestamp,
            lastUpdated: block.timestamp,
            validationScore: 0, // Default to 0
            validatorAddress: address(0),
            validationReportHash: "",
            validationTime: 0,
            totalLicensesSold: 0
        });

        listedModelIds.push(modelId); // Add to list of all model IDs ever created

        emit ModelListed(modelId, msg.sender, _metadataHash, _pricePerLicense, _availableLicenseTypes);
        return modelId;
    }

    /// @notice Allows the model owner to update the metadata hash for their model.
    /// @param _modelId The ID of the model to update.
    /// @param _newMetadataHash The new metadata hash.
    function updateModelMetadata(uint256 _modelId, string memory _newMetadataHash) external onlyModelOwner(_modelId) {
        require(bytes(_newMetadataHash).length > 0, "New metadata hash required");
        Model storage model = idToModel[_modelId];
        model.metadataHash = _newMetadataHash;
        model.lastUpdated = block.timestamp;
        // Note: We don't change status if it's delisted. Update happens regardless.
        emit ModelUpdated(_modelId, msg.sender, model.metadataHash, model.pricePerLicense, model.availableLicenseTypes);
    }

    /// @notice Allows the model owner to update the price per license for their model.
    /// @param _modelId The ID of the model to update.
    /// @param _newPricePerLicense The new price per license in native tokens.
    function updateModelPrice(uint256 _modelId, uint256 _newPricePerLicense) external onlyModelOwner(_modelId) {
         require(_newPricePerLicense > 0, "Price must be greater than 0");
        Model storage model = idToModel[_modelId];
        model.pricePerLicense = _newPricePerLicense;
        model.lastUpdated = block.timestamp;
        emit ModelUpdated(_modelId, msg.sender, model.metadataHash, model.pricePerLicense, model.availableLicenseTypes);
    }

     /// @notice Allows the model owner to update the available license types for their model.
    /// @param _modelId The ID of the model to update.
    /// @param _newAvailableLicenseTypes The new array of available license types.
    function updateModelLicenseOptions(uint256 _modelId, uint256[] memory _newAvailableLicenseTypes) external onlyModelOwner(_modelId) {
        require(_newAvailableLicenseTypes.length > 0, "At least one license type required");
        Model storage model = idToModel[_modelId];
        model.availableLicenseTypes = _newAvailableLicenseTypes; // Overwrite old options
        model.lastUpdated = block.timestamp;
        emit ModelUpdated(_modelId, msg.sender, model.metadataHash, model.pricePerLicense, model.availableLicenseTypes);
    }

    /// @notice Delists a model, making it unavailable for new license purchases.
    /// Existing licenses remain valid unless otherwise specified by terms off-chain.
    /// @param _modelId The ID of the model to delist.
    function delistModel(uint256 _modelId) external onlyModelOwner(_modelId) {
        Model storage model = idToModel[_modelId];
        require(model.status == ModelStatus.Listed, "Model not listed");
        model.status = ModelStatus.Delisted;
        model.lastUpdated = block.timestamp;
        emit ModelDelisted(_modelId, msg.sender);
    }

    /// @notice Transfers ownership of a model listing (and associated earnings/management rights).
    /// @param _modelId The ID of the model.
    /// @param _newOwner The address to transfer ownership to.
    function transferModelOwnership(uint256 _modelId, address _newOwner) external onlyModelOwner(_modelId) {
        require(_newOwner != address(0), "Invalid new owner address");
        Model storage model = idToModel[_modelId];
        address previousOwner = model.owner;
        model.owner = _newOwner;
        model.lastUpdated = block.timestamp;
        emit ModelOwnershipTransferred(_modelId, previousOwner, _newOwner);
    }

    /// @notice Allows the model owner to withdraw their accumulated earnings from license sales.
    /// Earnings are sent directly to the model owner's address.
    /// @param _modelId The ID of the model to withdraw earnings for.
    function withdrawModelEarnings(uint256 _modelId) external onlyModelOwner(_modelId) {
        Model storage model = idToModel[_modelId];
        // Earnings are implicitly tracked by payable function calls.
        // Need a mechanism to explicitly track withdrawable balance per model.
        // For simplicity here, assuming total balance owned by this address is for this model.
        // A more complex implementation would need a mapping: modelId => owner => balance.

        // For this example, let's assume earnings are transferred instantly on purchase,
        // minus fee. This function is slightly redundant unless we implement a hold.
        // Let's modify purchaseLicense to *hold* the owner's share and implement withdrawal here.
        // (Refactored purchaseLicense logic below reflects this).
        // Need a mapping: modelId => ownerAddress => withdrawableBalance
        mapping(uint256 => mapping(address => uint256)) private modelOwnerBalances;

        uint256 amount = modelOwnerBalances[_modelId][msg.sender];
        require(amount > 0, "No earnings to withdraw for this model");

        modelOwnerBalances[_modelId][msg.sender] = 0; // Reset balance before transfer
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Earnings withdrawal failed");

        emit ModelEarningsWithdrawn(_modelId, msg.sender, amount);
    }


    // --- Licensing Functions ---

    /// @notice Allows a user to purchase a license for a model.
    /// @param _modelId The ID of the model to purchase a license for.
    /// @param _licenseType The type of license to purchase (must be available for the model).
    function purchaseLicense(uint256 _modelId, uint256 _licenseType) external payable whenNotPaused {
        Model storage model = idToModel[_modelId];
        require(model.status == ModelStatus.Listed, "Model is not listed");
        require(msg.value >= model.pricePerLicense, "Insufficient payment");

        bool licenseTypeAvailable = false;
        for (uint i = 0; i < model.availableLicenseTypes.length; i++) {
            if (model.availableLicenseTypes[i] == _licenseType) {
                licenseTypeAvailable = true;
                break;
            }
        }
        require(licenseTypeAvailable, "Requested license type not available");

        // Check if they already have this specific license type
        // This assumes unique licenses per type per user.
        // If users can buy multiple licenses of the *same* type, this check needs adjustment.
        // Let's assume one license of each type is sufficient.
        require(modelIdToLicenses[_modelId][msg.sender][_licenseType].purchaseTime == 0, "License already owned");

        uint256 totalPrice = model.pricePerLicense;
        uint256 feeAmount = (totalPrice * marketplaceFeePermille) / 1000;
        uint256 ownerAmount = totalPrice - feeAmount;

        // Store fee and owner's earnings
        marketplaceFeeBalance += feeAmount;
        modelOwnerBalances[_modelId][model.owner] += ownerAmount; // Track earnings per model owner

        // Create the license record
        modelIdToLicenses[_modelId][msg.sender][_licenseType] = License({
            modelId: _modelId,
            licensee: msg.sender,
            purchaseTime: block.timestamp,
            licenseType: _licenseType
        });

        model.totalLicensesSold++; // Increment sales count

        // Refund any overpayment
        if (msg.value > totalPrice) {
            uint256 refundAmount = msg.value - totalPrice;
            (bool success, ) = payable(msg.sender).call{value: refundAmount}("");
            require(success, "Refund failed"); // Refund failure should revert the entire transaction
        }

        emit LicensePurchased(_modelId, msg.sender, _licenseType, totalPrice);
    }

    /// @notice Checks if a specific address holds a valid license of a certain type for a model.
    /// @param _modelId The ID of the model.
    /// @param _licensee The address to check.
    /// @param _licenseType The type of license to check for.
    /// @return True if the license exists, false otherwise.
    function checkLicenseValidity(uint256 _modelId, address _licensee, uint256 _licenseType) external view returns (bool) {
        // A license is considered valid if the purchaseTime is non-zero.
        // Future: could add expiration checks here.
        return modelIdToLicenses[_modelId][_licensee][_licenseType].purchaseTime > 0;
    }

    /// @notice Gets the details of a user's license for a specific model and license type.
    /// @param _modelId The ID of the model.
    /// @param _licenseType The type of license.
    /// @return modelId, licensee, purchaseTime, licenseType. purchaseTime will be 0 if no license exists.
    function getLicenseDetails(uint256 _modelId, uint256 _licenseType) external view returns (uint256, address, uint256, uint256) {
        License storage license = modelIdToLicenses[_modelId][msg.sender][_licenseType];
        return (license.modelId, license.licensee, license.purchaseTime, license.licenseType);
    }

    // --- Oracle Integration Functions ---

    /// @notice Requests off-chain AI inference for a model using an oracle.
    /// Requires the sender to have a valid license for the model.
    /// Requires a payment for compute if specified (passed via msg.value).
    /// @param _modelId The ID of the model to use for inference.
    /// @param _licenseType The type of license held by the requester.
    /// @param _inputHash IPFS hash or similar pointer to the input data for the inference.
    /// @param _computePayment Required payment for off-chain compute (can be 0).
    /// (Potential future: oracleJobId parameter if using a system like Chainlink)
    function requestInference(uint256 _modelId, uint256 _licenseType, string memory _inputHash, uint256 _computePayment) external payable whenNotPaused {
        require(checkLicenseValidity(_modelId, msg.sender, _licenseType), "Requires valid license");
        require(bytes(_inputHash).length > 0, "Input hash required");
        require(msg.value >= _computePayment, "Insufficient payment for compute");

        uint256 requestId = nextInferenceRequestId++;
        idToInferenceRequest[requestId] = InferenceRequest({
            requestId: requestId,
            modelId: _modelId,
            requester: msg.sender,
            inputHash: _inputHash,
            outputHash: "", // Will be filled by oracle
            status: InferenceStatus.Requested,
            requestTime: block.timestamp,
            fulfillmentTime: 0
            // Potential future: paymentForCompute: _computePayment
        });

        userToInferenceRequests[msg.sender].push(requestId);

        // Implicitly "sends" the request to the oracle off-chain system.
        // In a real Chainlink integration, this would involve a ChainlinkClient.request() call.
        // For this example, we just store the request details on-chain.

        // Transfer compute payment to oracle address
        if (_computePayment > 0) {
            (bool success, ) = payable(oracleAddress).call{value: _computePayment}("");
            require(success, "Compute payment transfer failed");
        }


        emit InferenceRequested(requestId, _modelId, msg.sender, _inputHash);
    }

    /// @notice Called by the trusted oracle to fulfill an inference request.
    /// Provides the result hash (e.g., IPFS CID) of the computation output.
    /// @param _requestId The ID of the original inference request.
    /// @param _outputHash IPFS hash or similar pointer to the output data.
    /// (Potential future: paymentToRequester if results have value, require(oracleJobId == expectedId))
    function fulfillInferenceRequest(uint256 _requestId, string memory _outputHash) external onlyOracle {
        InferenceRequest storage request = idToInferenceRequest[_requestId];
        require(request.status == InferenceStatus.Requested, "Request not in requested status");
        require(bytes(_outputHash).length > 0, "Output hash required");

        request.outputHash = _outputHash;
        request.status = InferenceStatus.Fulfilled;
        request.fulfillmentTime = block.timestamp;

        emit InferenceFulfilled(_requestId, _outputHash);
    }

    /// @notice Allows the requester to retrieve the result hash of their fulfilled inference request.
    /// @param _requestId The ID of the inference request.
    /// @return The output hash of the fulfilled request. Returns empty string if not fulfilled or not found.
    function getInferenceResult(uint256 _requestId) external view returns (string memory) {
        InferenceRequest storage request = idToInferenceRequest[_requestId];
        require(request.requester == msg.sender, "Only the requester can get the result");
        require(request.status == InferenceStatus.Fulfilled, "Request not yet fulfilled");
        return request.outputHash;
    }

    /// @notice Allows a user to get a list of their inference request IDs.
    /// @return An array of inference request IDs initiated by the caller.
    function getUserInferenceRequests() external view returns (uint256[] memory) {
        return userToInferenceRequests[msg.sender];
    }


    // --- Validation Functions ---

    /// @notice Allows a registered validator to submit a validation score and optional report hash for a model.
    /// Overwrites any previous validation score for that model.
    /// @param _modelId The ID of the model being validated.
    /// @param _score The validation score (e.g., 0-100).
    /// @param _reportHash Optional IPFS hash for a detailed validation report.
    function submitModelValidation(uint256 _modelId, uint256 _score, string memory _reportHash) external isValidator[msg.sender] whenNotPaused {
        require(idToModel[_modelId].owner != address(0), "Model does not exist"); // Check if model exists
        require(_score <= 100, "Score must be <= 100"); // Example score max

        Model storage model = idToModel[_modelId];
        model.validationScore = _score;
        model.validatorAddress = msg.sender;
        model.validationReportHash = _reportHash;
        model.validationTime = block.timestamp;
        model.lastUpdated = block.timestamp; // Mark model as updated

        emit ModelValidated(_modelId, msg.sender, _score, _reportHash);
    }

    /// @notice Gets the latest validation details for a specific model.
    /// @param _modelId The ID of the model.
    /// @return score, validatorAddress, validationReportHash, validationTime. Returns default values if not validated.
    function getModelValidation(uint256 _modelId) external view returns (uint256, address, string memory, uint256) {
        Model storage model = idToModel[_modelId];
        // No require here, just return default values if model doesn't exist or isn't validated
        return (model.validationScore, model.validatorAddress, model.validationReportHash, model.validationTime);
    }

    // --- Reporting Functions ---

    /// @notice Allows any user to report a model listing for potential issues.
    /// @param _modelId The ID of the model being reported.
    /// @param _detailsHash IPFS hash or similar pointer to the details of the report.
    /// @return The ID of the newly created report.
    function reportModel(uint256 _modelId, string memory _detailsHash) external whenNotPaused returns (uint256) {
        require(idToModel[_modelId].owner != address(0), "Model does not exist");
        require(bytes(_detailsHash).length > 0, "Report details hash required");

        uint256 reportId = nextReportId++;
        idToReport[reportId] = Report({
            reportId: reportId,
            modelId: _modelId,
            reporter: msg.sender,
            detailsHash: _detailsHash,
            reportTime: block.timestamp,
            status: ReportStatus.Open,
            resolvedBy: address(0),
            resolvedTime: 0
        });

        emit ModelReported(reportId, _modelId, msg.sender, _detailsHash);
        return reportId;
    }

    /// @notice Allows the owner/admin to view the details of a specific report.
    /// @param _reportId The ID of the report.
    /// @return modelId, reporter, detailsHash, reportTime, status.
    function getReportDetails(uint256 _reportId) external view onlyOwner returns (uint256, address, string memory, uint256, ReportStatus) {
         Report storage report = idToReport[_reportId];
         require(report.reportId == _reportId, "Report does not exist"); // Ensure report exists
         return (report.modelId, report.reporter, report.detailsHash, report.reportTime, report.status);
    }

    /// @notice Allows the owner/admin to mark a report as resolved.
    /// Does not take action on the model itself; requires manual review and potential separate action (e.g., delisting).
    /// @param _reportId The ID of the report to resolve.
    function resolveReport(uint256 _reportId) external onlyOwner {
        Report storage report = idToReport[_reportId];
        require(report.reportId == _reportId, "Report does not exist");
        require(report.status == ReportStatus.Open, "Report is not open");

        report.status = ReportStatus.Resolved;
        report.resolvedBy = msg.sender;
        report.resolvedTime = block.timestamp;

        emit ReportResolved(_reportId, msg.sender);
    }


    // --- View & Utility Functions ---

    /// @notice Gets the public details of a model listing.
    /// @param _modelId The ID of the model.
    /// @return modelId, owner, metadataHash, pricePerLicense, availableLicenseTypes, status, creationTime, lastUpdated.
    function getModelDetails(uint256 _modelId) external view returns (
        uint256 modelId,
        address owner,
        string memory metadataHash,
        uint256 pricePerLicense,
        uint256[] memory availableLicenseTypes,
        ModelStatus status,
        uint256 creationTime,
        uint256 lastUpdated
    ) {
        Model storage model = idToModel[_modelId];
        require(model.owner != address(0), "Model does not exist"); // Check if model exists

        return (
            model.id,
            model.owner,
            model.metadataHash,
            model.pricePerLicense,
            model.availableLicenseTypes,
            model.status,
            model.creationTime,
            model.lastUpdated
        );
    }

    /// @notice Gets the total number of models that have ever been listed on the marketplace.
    /// Includes models that may now be delisted.
    /// @return The total count of model IDs generated.
    function getTotalListedModels() external view returns (uint256) {
        return nextModelId - 1; // nextModelId is always 1 higher than the last ID used
    }

     /// @notice Gets a model ID from the internal list by its index.
     /// Useful for iterating through all models (consider gas limits for large lists off-chain).
     /// @param _index The index in the list.
     /// @return The model ID at that index.
    function getModelIdByIndex(uint256 _index) external view returns (uint256) {
        require(_index < listedModelIds.length, "Index out of bounds");
        return listedModelIds[_index];
    }
}
```