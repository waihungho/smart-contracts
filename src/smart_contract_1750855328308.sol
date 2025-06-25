Okay, here is a Solidity smart contract for a Decentralized AI Model Registry and Usage Platform. It incorporates concepts like registration, versioning, usage tracking, rating, verification, and access control, avoiding direct duplication of standard token or NFT contracts while aiming for complexity and trendiness around AI/ML concepts managed on-chain.

It includes over 20 functions covering registration, updates, retrieval, querying, usage tracking, rating, verification, and administrative tasks.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- Contract Outline ---
// 1. State Variables & Data Structures
//    - Model struct: Stores model metadata and versions.
//    - ModelVersion struct: Stores version-specific details like IPFS hash, framework, stats.
//    - Rating struct: Stores user ratings and comments.
//    - VerifierAttestation struct: Stores attestation details from registered verifiers.
//    - Enums: ModelStatus for tracking model/version lifecycle.
//    - Mappings:
//      - models: modelId -> Model struct
//      - modelVersions: modelId -> versionIndex -> ModelVersion struct
//      - userVersionUsage: userAddress -> modelId -> versionIndex -> count
//      - versionRatingList: modelId -> versionIndex -> array of Rating structs
//      - modelRatings: modelId -> versionIndex -> userAddress -> bool (to prevent double rating)
//      - verifiers: verifierAddress -> bool
//      - versionAttestations: modelId -> versionIndex -> array of VerifierAttestation structs
//      - _tags: tag (string) -> modelId -> bool (for efficient tag search)
//    - Arrays:
//      - _modelIds: Stores all registered model IDs (for enumeration).
//    - Counters: _nextModelId.
//    - Fees: _registrationFee, _feesCollected.
//    - Access Control: _owner.

// 2. Events
//    - ModelRegistered, VersionAdded, ModelDetailsUpdated, ModelStatusUpdated,
//      OwnershipTransferred, UsageRecorded, RatingSubmitted, VerifierRegistered,
//      VerifierAttestationSubmitted, TagAdded, TagRemoved, FeeSet, FeesWithdrawn.

// 3. Modifiers
//    - onlyModelOwner: Restricts calls to the owner of a specific model.
//    - onlyVerifier: Restricts calls to registered verifiers.

// 4. Constructor: Initializes owner and registration fee.

// 5. Core Model Management Functions (>= 7 functions)
//    - registerModel: Register a new AI model (payable).
//    - addModelVersion: Add a new version to an existing model.
//    - updateModelDetails: Update general model metadata.
//    - deprecateModel: Mark a model as deprecated.
//    - deprecateModelVersion: Mark a specific version as deprecated.
//    - transferModelOwnership: Transfer ownership of a model.
//    - getModelDetails: Retrieve details of a model.

// 6. Version & Retrieval Functions (>= 5 functions)
//    - getModelVersionDetails: Retrieve details of a specific model version.
//    - getTotalModels: Get the total number of registered models.
//    - getModelIdByIndex: Get model ID by its index in the list (for enumeration).
//    - getModelVersions: List all version indices for a model.
//    - getModelsByOwner: List all model IDs owned by an address.

// 7. Tagging Functions (>= 3 functions)
//    - addTagsToModel: Add tags to a model.
//    - removeTagsFromModel: Remove tags from a model.
//    - getModelsByTag: Retrieve a list of models associated with a tag.

// 8. Usage Tracking Functions (>= 3 functions)
//    - recordModelUsage: Record a single usage instance for a version.
//    - getUserUsageCount: Get the usage count for a specific user and version.
//    - getTotalUsageCountForVersion: Get the total usage count for a specific version.

// 9. Rating & Reputation Functions (>= 3 functions)
//    - submitRating: Submit a rating and comment for a version.
//    - getRatingsForVersion: Retrieve all ratings for a version.
//    - getAverageRatingForVersion: Calculate and get the average rating for a version.

// 10. Verification Functions (>= 4 functions)
//    - registerVerifier: Grant verifier status (Owner only).
//    - removeVerifier: Revoke verifier status (Owner only).
//    - isVerifier: Check if an address is a verifier.
//    - submitVerifierAttestation: Submit an attestation for a version (Verifiers only).
//    - getVerifierAttestationsForVersion: Retrieve all attestations for a version.

// 11. Fee & Administrative Functions (>= 3 functions)
//    - setRegistrationFee: Set the fee for registering new models (Owner only).
//    - getRegistrationFee: Get the current registration fee.
//    - withdrawFees: Withdraw collected fees (Owner only).

// Total functions: ~30 (exceeds 20 requirement)

// --- Function Summary ---

// Core Model Management:
// registerModel(string memory name, string memory description, string memory ipfsHash, string memory framework, string memory inputDescription, string memory outputDescription): Registers a new model and its initial version. Requires payment of the registration fee.
// addModelVersion(uint256 modelId, string memory ipfsHash, string memory framework, string memory inputDescription, string memory outputDescription): Adds a new version to an existing model. Only callable by the model owner.
// updateModelDetails(uint256 modelId, string memory name, string memory description): Updates the name and description of a model. Only callable by the model owner.
// deprecateModel(uint256 modelId): Sets the status of a model to DEPRECATED. Only callable by the model owner.
// deprecateModelVersion(uint256 modelId, uint256 versionIndex): Sets the status of a specific version to DEPRECATED. Only callable by the model owner.
// transferModelOwnership(uint256 modelId, address newOwner): Transfers ownership of a model to a new address. Only callable by the current model owner.
// getModelDetails(uint256 modelId): Retrieves the Model struct details for a given ID.

// Version & Retrieval:
// getModelVersionDetails(uint256 modelId, uint256 versionIndex): Retrieves the ModelVersion struct details for a given model and version index.
// getTotalModels(): Returns the total count of registered models.
// getModelIdByIndex(uint256 index): Returns the model ID at a specific index in the internal list of all models.
// getModelVersions(uint256 modelId): Returns an array of all version indices for a given model.
// getModelsByOwner(address owner): Returns an array of model IDs owned by a given address.

// Tagging:
// addTagsToModel(uint256 modelId, string[] memory tags): Adds multiple tags to a model. Only callable by the model owner.
// removeTagsFromModel(uint256 modelId, string[] memory tags): Removes multiple tags from a model. Only callable by the model owner.
// getModelsByTag(string memory tag): Returns an array of model IDs that have the specified tag.

// Usage Tracking:
// recordModelUsage(uint256 modelId, uint256 versionIndex): Records that a specific version of a model was used by the caller. Intended to be called by off-chain services or users confirming usage.
// getUserUsageCount(address user, uint256 modelId, uint256 versionIndex): Retrieves the number of times a specific user recorded usage for a version.
// getTotalUsageCountForVersion(uint256 modelId, uint256 versionIndex): Retrieves the total usage count for a specific version across all users.

// Rating & Reputation:
// submitRating(uint256 modelId, uint256 versionIndex, uint256 score, string memory comment): Allows a user to submit a rating (1-5) and optional comment for a model version. Each user can rate a specific version only once.
// getRatingsForVersion(uint256 modelId, uint256 versionIndex): Retrieves all submitted Rating structs for a specific version.
// getAverageRatingForVersion(uint256 modelId, uint256 versionIndex): Calculates and returns the average rating for a specific version, scaled by 100 to avoid floating-point issues.

// Verification:
// registerVerifier(address verifierAddress): Grants the role of a registered verifier to an address. Only callable by the contract owner.
// removeVerifier(address verifierAddress): Revokes the role of a registered verifier. Only callable by the contract owner.
// isVerifier(address verifierAddress): Checks if an address is a registered verifier.
// submitVerifierAttestation(uint256 modelId, uint256 versionIndex, string memory details): Allows a registered verifier to submit an attestation (e.g., "tested for bias", "performance benchmarked") for a version.
// getVerifierAttestationsForVersion(uint256 modelId, uint256 versionIndex): Retrieves all VerifierAttestation structs for a specific version.

// Fee & Administrative:
// setRegistrationFee(uint256 fee): Sets the amount of Ether required to register a new model. Only callable by the contract owner.
// getRegistrationFee(): Returns the current model registration fee.
// withdrawFees(): Allows the contract owner to withdraw accumulated registration fees. Uses ReentrancyGuard.

contract DecentralizedAIModelRegistry is Ownable, ReentrancyGuard {

    enum ModelStatus { ACTIVE, DEPRECATED }

    struct Model {
        address owner;
        string name;
        string description;
        ModelStatus status;
        uint256 creationTimestamp;
        uint256 updateTimestamp;
        uint256[] versionIndices; // Indices of versions in the modelVersions mapping
        // Tags handled via separate mapping _tags
    }

    struct ModelVersion {
        uint256 versionNumber; // e.g., 1, 2, 3...
        string ipfsHash; // IPFS hash or similar off-chain pointer to model files
        string framework; // e.g., "TensorFlow", "PyTorch", "Scikit-learn"
        string inputDescription; // Description of expected input data
        string outputDescription; // Description of expected output data
        ModelStatus status;
        uint256 creationTimestamp;
        uint256 totalUsageCount;
        uint256 totalRatingScore; // Sum of all submitted scores
        uint256 ratingCount; // Number of submitted ratings
    }

    struct Rating {
        address user;
        uint256 score; // e.g., 1-5
        string comment;
        uint256 timestamp;
    }

     struct VerifierAttestation {
        address verifier;
        string details; // Attestation details (e.g., "tested against benchmark X", "reviewed for bias")
        uint256 timestamp;
    }

    // --- State Variables & Mappings ---

    uint256 private _nextModelId; // Counter for unique model IDs
    uint256[] private _modelIds; // List of all model IDs for enumeration

    mapping(uint256 => Model) public models;
    mapping(uint256 => mapping(uint256 => ModelVersion)) public modelVersions; // modelId => versionIndex => ModelVersion
    mapping(address => uint256[]) private _modelsByOwner; // ownerAddress => array of modelIds

    // Usage Tracking: userAddress => modelId => versionIndex => count
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) public userVersionUsage;

    // Rating: modelId => versionIndex => userAddress => Rating struct (to check if rated)
    mapping(uint256 => mapping(uint256 => mapping(address => Rating))) private modelRatings;
     // Rating list: modelId => versionIndex => array of Rating structs (for retrieval)
    mapping(uint256 => mapping(uint256 => Rating[])) public versionRatingList;

    // Verification: verifierAddress => isVerifier
    mapping(address => bool) private _verifiers;
    // Attestations: modelId => versionIndex => array of VerifierAttestation structs
    mapping(uint256 => mapping(uint256 => VerifierAttestation[])) public versionAttestations;

    // Tagging: tag (string) => modelId => bool (more gas efficient for adding/removing and lookup than string[] in struct)
    mapping(string => mapping(uint256 => bool)) private _tags;

    uint256 private _registrationFee;
    uint256 private _feesCollected;

    // --- Events ---

    event ModelRegistered(uint256 indexed modelId, address indexed owner, string name, uint256 initialVersionIndex, uint256 timestamp);
    event VersionAdded(uint256 indexed modelId, uint256 indexed versionIndex, string ipfsHash, uint256 timestamp);
    event ModelDetailsUpdated(uint256 indexed modelId, string newName, string newDescription, uint256 timestamp);
    event ModelStatusUpdated(uint256 indexed modelId, ModelStatus newStatus, uint256 timestamp);
    event ModelVersionStatusUpdated(uint256 indexed modelId, uint256 indexed versionIndex, ModelStatus newStatus, uint256 timestamp);
    event OwnershipTransferred(uint256 indexed modelId, address indexed previousOwner, address indexed newOwner, uint256 timestamp);
    event UsageRecorded(address indexed user, uint256 indexed modelId, uint256 indexed versionIndex, uint256 count, uint256 timestamp);
    event RatingSubmitted(address indexed user, uint256 indexed modelId, uint256 indexed versionIndex, uint256 score, uint256 timestamp);
    event VerifierRegistered(address indexed verifier, uint256 timestamp);
    event VerifierRemoved(address indexed verifier, uint256 timestamp);
    event VerifierAttestationSubmitted(address indexed verifier, uint256 indexed modelId, uint256 indexed versionIndex, uint256 timestamp);
    event TagAdded(uint256 indexed modelId, string tag, uint256 timestamp);
    event TagRemoved(uint256 indexed modelId, string tag, uint256 timestamp);
    event FeeSet(uint256 oldFee, uint256 newFee, uint256 timestamp);
    event FeesWithdrawn(address indexed receiver, uint256 amount, uint256 timestamp);

    // --- Modifiers ---

    modifier onlyModelOwner(uint256 modelId) {
        require(models[modelId].owner == msg.sender, "Not model owner");
        _;
    }

    modifier onlyVerifier() {
        require(_verifiers[msg.sender], "Caller is not a registered verifier");
        _;
    }

    // --- Constructor ---

    constructor(uint256 initialRegistrationFee) Ownable(msg.sender) {
        _nextModelId = 1; // Start model IDs from 1
        _registrationFee = initialRegistrationFee;
        _feesCollected = 0;
    }

    // --- Core Model Management Functions ---

    /**
     * @notice Registers a new AI model and its initial version.
     * @param name The name of the model.
     * @param description A brief description of the model.
     * @param ipfsHash The IPFS hash or link to the model files.
     * @param framework The AI framework used (e.g., TensorFlow, PyTorch).
     * @param inputDescription Description of expected model input.
     * @param outputDescription Description of model output.
     */
    function registerModel(
        string memory name,
        string memory description,
        string memory ipfsHash,
        string memory framework,
        string memory inputDescription,
        string memory outputDescription
    ) external payable nonReentrant {
        require(msg.value >= _registrationFee, "Insufficient registration fee");

        uint256 modelId = _nextModelId++;
        uint256 initialVersionIndex = 0; // First version is index 0
        uint256 timestamp = block.timestamp;

        models[modelId] = Model({
            owner: msg.sender,
            name: name,
            description: description,
            status: ModelStatus.ACTIVE,
            creationTimestamp: timestamp,
            updateTimestamp: timestamp,
            versionIndices: new uint256[](0) // Will add the first version index below
        });

        // Add the initial version
        models[modelId].versionIndices.push(initialVersionIndex);
        modelVersions[modelId][initialVersionIndex] = ModelVersion({
            versionNumber: 1, // First version is number 1
            ipfsHash: ipfsHash,
            framework: framework,
            inputDescription: inputDescription,
            outputDescription: outputDescription,
            status: ModelStatus.ACTIVE,
            creationTimestamp: timestamp,
            totalUsageCount: 0,
            totalRatingScore: 0,
            ratingCount: 0
        });

        _modelIds.push(modelId); // Add to global list of IDs
        _modelsByOwner[msg.sender].push(modelId); // Add to owner's list

        // Collect fee
        _feesCollected += msg.value;

        emit ModelRegistered(modelId, msg.sender, name, initialVersionIndex, timestamp);
    }

    /**
     * @notice Adds a new version to an existing model.
     * @param modelId The ID of the model.
     * @param ipfsHash The IPFS hash or link for the new version.
     * @param framework The AI framework used.
     * @param inputDescription Description of expected input.
     * @param outputDescription Description of output.
     */
    function addModelVersion(
        uint256 modelId,
        string memory ipfsHash,
        string memory framework,
        string memory inputDescription,
        string memory outputDescription
    ) external onlyModelOwner(modelId) {
        require(models[modelId].status == ModelStatus.ACTIVE, "Model is not active");

        uint256 versionIndex = models[modelId].versionIndices.length;
        uint256 versionNumber = versionIndex + 1; // Version numbers start from 1
        uint256 timestamp = block.timestamp;

        models[modelId].versionIndices.push(versionIndex); // Add new index to model's list
        modelVersions[modelId][versionIndex] = ModelVersion({
            versionNumber: versionNumber,
            ipfsHash: ipfsHash,
            framework: framework,
            inputDescription: inputDescription,
            outputDescription: outputDescription,
            status: ModelStatus.ACTIVE,
            creationTimestamp: timestamp,
            totalUsageCount: 0,
            totalRatingScore: 0,
            ratingCount: 0
        });

        models[modelId].updateTimestamp = timestamp;

        emit VersionAdded(modelId, versionIndex, ipfsHash, timestamp);
    }

    /**
     * @notice Updates the general details (name, description) of a model.
     * @param modelId The ID of the model.
     * @param name The new name.
     * @param description The new description.
     */
    function updateModelDetails(uint256 modelId, string memory name, string memory description)
        external onlyModelOwner(modelId)
    {
        Model storage model = models[modelId];
        model.name = name;
        model.description = description;
        model.updateTimestamp = block.timestamp;

        emit ModelDetailsUpdated(modelId, name, description, block.timestamp);
    }

    /**
     * @notice Deprecates an entire model, marking it as no longer recommended for use.
     * @param modelId The ID of the model to deprecate.
     */
    function deprecateModel(uint256 modelId) external onlyModelOwner(modelId) {
        Model storage model = models[modelId];
        require(model.status == ModelStatus.ACTIVE, "Model is already deprecated");
        model.status = ModelStatus.DEPRECATED;
        model.updateTimestamp = block.timestamp;

        // Optionally deprecate all versions too
        for (uint i = 0; i < model.versionIndices.length; i++) {
             uint256 versionIndex = model.versionIndices[i];
             modelVersions[modelId][versionIndex].status = ModelStatus.DEPRECATED;
             emit ModelVersionStatusUpdated(modelId, versionIndex, ModelStatus.DEPRECATED, block.timestamp);
        }

        emit ModelStatusUpdated(modelId, ModelStatus.DEPRECATED, block.timestamp);
    }

    /**
     * @notice Deprecates a specific version of a model.
     * @param modelId The ID of the model.
     * @param versionIndex The index of the version to deprecate.
     */
    function deprecateModelVersion(uint256 modelId, uint256 versionIndex)
        external onlyModelOwner(modelId)
    {
         require(versionIndex < models[modelId].versionIndices.length, "Invalid version index");
         require(models[modelId].versionIndices[versionIndex] == versionIndex, "Version index mismatch"); // Safety check
         ModelVersion storage version = modelVersions[modelId][versionIndex];
         require(version.status == ModelStatus.ACTIVE, "Version is already deprecated");
         version.status = ModelStatus.DEPRECATED;

         models[modelId].updateTimestamp = block.timestamp;

         emit ModelVersionStatusUpdated(modelId, versionIndex, ModelStatus.DEPRECATED, block.timestamp);
    }


    /**
     * @notice Transfers ownership of a model to a new address.
     * @param modelId The ID of the model.
     * @param newOwner The address to transfer ownership to.
     */
    function transferModelOwnership(uint256 modelId, address newOwner)
        external onlyModelOwner(modelId)
    {
        require(newOwner != address(0), "New owner cannot be the zero address");

        address oldOwner = models[modelId].owner;
        models[modelId].owner = newOwner;
        models[modelId].updateTimestamp = block.timestamp;

        // Update owner mappings (less efficient way for demo, linked list better for scale)
        // Find and remove modelId from old owner's list
        uint256[] storage oldOwnerModels = _modelsByOwner[oldOwner];
        for (uint i = 0; i < oldOwnerModels.length; i++) {
            if (oldOwnerModels[i] == modelId) {
                oldOwnerModels[i] = oldOwnerModels[oldOwnerModels.length - 1];
                oldOwnerModels.pop();
                break;
            }
        }
        // Add modelId to new owner's list
        _modelsByOwner[newOwner].push(modelId);

        emit OwnershipTransferred(modelId, oldOwner, newOwner, block.timestamp);
    }

    /**
     * @notice Retrieves the details of a registered model.
     * @param modelId The ID of the model.
     * @return Model struct containing model information.
     */
    function getModelDetails(uint256 modelId) external view returns (Model memory) {
        require(models[modelId].creationTimestamp > 0, "Model does not exist"); // Check if model exists
        return models[modelId];
    }

    // --- Version & Retrieval Functions ---

     /**
     * @notice Retrieves the details of a specific model version.
     * @param modelId The ID of the model.
     * @param versionIndex The index of the version.
     * @return ModelVersion struct containing version information.
     */
    function getModelVersionDetails(uint256 modelId, uint256 versionIndex)
        external view
        returns (ModelVersion memory)
    {
        require(models[modelId].creationTimestamp > 0, "Model does not exist");
        require(versionIndex < models[modelId].versionIndices.length, "Invalid version index");
        require(models[modelId].versionIndices[versionIndex] == versionIndex, "Version index mismatch"); // Safety check
        return modelVersions[modelId][versionIndex];
    }

    /**
     * @notice Gets the total number of registered models.
     * @return The total count of models.
     */
    function getTotalModels() external view returns (uint256) {
        return _modelIds.length;
    }

     /**
     * @notice Gets a model ID by its index in the internal list of all models.
     * Can be used to iterate through all registered models.
     * @param index The index (0 to getTotalModels() - 1).
     * @return The model ID at the given index.
     */
    function getModelIdByIndex(uint256 index) external view returns (uint256) {
        require(index < _modelIds.length, "Index out of bounds");
        return _modelIds[index];
    }

    /**
     * @notice Lists all version indices for a given model.
     * @param modelId The ID of the model.
     * @return An array of version indices.
     */
    function getModelVersions(uint256 modelId) external view returns (uint256[] memory) {
        require(models[modelId].creationTimestamp > 0, "Model does not exist");
        return models[modelId].versionIndices;
    }

    /**
     * @notice Lists all model IDs owned by a specific address.
     * @param owner The address of the owner.
     * @return An array of model IDs.
     */
    function getModelsByOwner(address owner) external view returns (uint256[] memory) {
        return _modelsByOwner[owner];
    }

    // --- Tagging Functions ---

    /**
     * @notice Adds multiple tags to a model.
     * @param modelId The ID of the model.
     * @param tags An array of tags to add.
     */
    function addTagsToModel(uint256 modelId, string[] memory tags)
        external onlyModelOwner(modelId)
    {
        require(models[modelId].creationTimestamp > 0, "Model does not exist");
        for (uint i = 0; i < tags.length; i++) {
            if (!_tags[tags[i]][modelId]) {
                _tags[tags[i]][modelId] = true;
                emit TagAdded(modelId, tags[i], block.timestamp);
            }
        }
        models[modelId].updateTimestamp = block.timestamp;
    }

    /**
     * @notice Removes multiple tags from a model.
     * @param modelId The ID of the model.
     * @param tags An array of tags to remove.
     */
    function removeTagsFromModel(uint256 modelId, string[] memory tags)
        external onlyModelOwner(modelId)
    {
        require(models[modelId].creationTimestamp > 0, "Model does not exist");
        for (uint i = 0; i < tags.length; i++) {
            if (_tags[tags[i]][modelId]) {
                _tags[tags[i]][modelId] = false; // Simply mark as false, don't delete from mapping
                emit TagRemoved(modelId, tags[i], block.timestamp);
            }
        }
        models[modelId].updateTimestamp = block.timestamp;
    }

    /**
     * @notice Retrieves a list of model IDs that have the specified tag.
     * @param tag The tag to search for.
     * @return An array of model IDs with the given tag.
     */
    function getModelsByTag(string memory tag) external view returns (uint256[] memory) {
        // This requires iterating over all potentially tagged models for this tag.
        // Gas cost scales with the number of models ever tagged with this tag.
        // If this list becomes very long, this function could hit gas limits.
        // A more complex linked list mapping could be used for better scalability on retrieval.
        uint256[] memory taggedModelIds = new uint256[](_modelIds.length); // Max possible size
        uint256 count = 0;
        for (uint i = 0; i < _modelIds.length; i++) {
            uint256 modelId = _modelIds[i];
            if (_tags[tag][modelId]) {
                taggedModelIds[count] = modelId;
                count++;
            }
        }
        // Resize the array to the actual count
        uint256[] memory result = new uint256[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = taggedModelIds[i];
        }
        return result;
    }


    // --- Usage Tracking Functions ---

    /**
     * @notice Records a single usage instance for a model version by the caller.
     * Intended to be called by an off-chain system that verifies actual usage,
     * or by users themselves to track their usage for future incentives/airdrop criteria.
     * @param modelId The ID of the model.
     * @param versionIndex The index of the version used.
     */
    function recordModelUsage(uint256 modelId, uint256 versionIndex) external {
        require(models[modelId].creationTimestamp > 0, "Model does not exist");
        require(versionIndex < models[modelId].versionIndices.length, "Invalid version index");
        require(models[modelId].versionIndices[versionIndex] == versionIndex, "Version index mismatch"); // Safety check
        require(modelVersions[modelId][versionIndex].status == ModelStatus.ACTIVE, "Version is deprecated");

        userVersionUsage[msg.sender][modelId][versionIndex]++;
        modelVersions[modelId][versionIndex].totalUsageCount++;

        emit UsageRecorded(msg.sender, modelId, versionIndex, userVersionUsage[msg.sender][modelId][versionIndex], block.timestamp);
    }

    /**
     * @notice Gets the usage count for a specific user and model version.
     * @param user The address of the user.
     * @param modelId The ID of the model.
     * @param versionIndex The index of the version.
     * @return The number of times the user recorded usage for this version.
     */
    function getUserUsageCount(address user, uint256 modelId, uint256 versionIndex) external view returns (uint256) {
         require(models[modelId].creationTimestamp > 0, "Model does not exist");
         require(versionIndex < models[modelId].versionIndices.length, "Invalid version index");
         require(models[modelId].versionIndices[versionIndex] == versionIndex, "Version index mismatch"); // Safety check
         return userVersionUsage[user][modelId][versionIndex];
    }

    /**
     * @notice Gets the total usage count for a specific model version across all users.
     * @param modelId The ID of the model.
     * @param versionIndex The index of the version.
     * @return The total number of times this version was recorded as used.
     */
    function getTotalUsageCountForVersion(uint256 modelId, uint256 versionIndex) external view returns (uint256) {
        require(models[modelId].creationTimestamp > 0, "Model does not exist");
        require(versionIndex < models[modelId].versionIndices.length, "Invalid version index");
        require(models[modelId].versionIndices[versionIndex] == versionIndex, "Version index mismatch"); // Safety check
        return modelVersions[modelId][versionIndex].totalUsageCount;
    }


    // --- Rating & Reputation Functions ---

    /**
     * @notice Allows a user to submit a rating (1-5) and optional comment for a model version.
     * Each user can rate a specific version only once.
     * @param modelId The ID of the model.
     * @param versionIndex The index of the version.
     * @param score The rating score (1-5).
     * @param comment An optional comment.
     */
    function submitRating(uint256 modelId, uint256 versionIndex, uint256 score, string memory comment) external {
        require(models[modelId].creationTimestamp > 0, "Model does not exist");
        require(versionIndex < models[modelId].versionIndices.length, "Invalid version index");
         require(models[modelId].versionIndices[versionIndex] == versionIndex, "Version index mismatch"); // Safety check
        require(score >= 1 && score <= 5, "Score must be between 1 and 5");
        require(modelRatings[modelId][versionIndex][msg.sender].timestamp == 0, "User has already rated this version"); // Check if user has rated

        ModelVersion storage version = modelVersions[modelId][versionIndex];
        uint256 timestamp = block.timestamp;

        Rating memory newRating = Rating({
            user: msg.sender,
            score: score,
            comment: comment,
            timestamp: timestamp
        });

        modelRatings[modelId][versionIndex][msg.sender] = newRating; // Record that user rated
        versionRatingList[modelId][versionIndex].push(newRating); // Add to list for retrieval

        // Update total score and count for average calculation
        version.totalRatingScore += score;
        version.ratingCount++;
        models[modelId].updateTimestamp = timestamp; // Consider rating an update

        emit RatingSubmitted(msg.sender, modelId, versionIndex, score, timestamp);
    }

    /**
     * @notice Retrieves all submitted Rating structs for a specific version.
     * @param modelId The ID of the model.
     * @param versionIndex The index of the version.
     * @return An array of Rating structs.
     */
    function getRatingsForVersion(uint256 modelId, uint256 versionIndex)
        external view
        returns (Rating[] memory)
    {
        require(models[modelId].creationTimestamp > 0, "Model does not exist");
        require(versionIndex < models[modelId].versionIndices.length, "Invalid version index");
         require(models[modelId].versionIndices[versionIndex] == versionIndex, "Version index mismatch"); // Safety check
        return versionRatingList[modelId][versionIndex];
    }

    /**
     * @notice Calculates and returns the average rating for a specific version.
     * Returns 0 if no ratings exist. The average is scaled by 100 (e.g., 450 means 4.50).
     * @param modelId The ID of the model.
     * @param versionIndex The index of the version.
     * @return The average rating scaled by 100.
     */
    function getAverageRatingForVersion(uint256 modelId, uint256 versionIndex)
        external view
        returns (uint256)
    {
        require(models[modelId].creationTimestamp > 0, "Model does not exist");
        require(versionIndex < models[modelId].versionIndices.length, "Invalid version index");
         require(models[modelId].versionIndices[versionIndex] == versionIndex, "Version index mismatch"); // Safety check

        ModelVersion storage version = modelVersions[modelId][versionIndex];
        if (version.ratingCount == 0) {
            return 0;
        }
        // Calculate average and scale by 100
        return (version.totalRatingScore * 100) / version.ratingCount;
    }


    // --- Verification Functions ---

    /**
     * @notice Grants the role of a registered verifier to an address. Only callable by the contract owner.
     * Registered verifiers can submit attestations about model versions.
     * @param verifierAddress The address to grant verifier status to.
     */
    function registerVerifier(address verifierAddress) external onlyOwner {
        require(verifierAddress != address(0), "Verifier address cannot be zero");
        require(!_verifiers[verifierAddress], "Address is already a verifier");
        _verifiers[verifierAddress] = true;
        emit VerifierRegistered(verifierAddress, block.timestamp);
    }

    /**
     * @notice Revokes the role of a registered verifier. Only callable by the contract owner.
     * @param verifierAddress The address to revoke verifier status from.
     */
    function removeVerifier(address verifierAddress) external onlyOwner {
        require(verifierAddress != address(0), "Verifier address cannot be zero");
        require(_verifiers[verifierAddress], "Address is not a verifier");
        _verifiers[verifierAddress] = false;
        emit VerifierRemoved(verifierAddress, block.timestamp);
    }

    /**
     * @notice Checks if an address is a registered verifier.
     * @param verifierAddress The address to check.
     * @return True if the address is a verifier, false otherwise.
     */
    function isVerifier(address verifierAddress) external view returns (bool) {
        return _verifiers[verifierAddress];
    }

    /**
     * @notice Allows a registered verifier to submit an attestation for a model version.
     * Examples: "Tested against benchmark X", "Reviewed for bias", "Verified reproducibility".
     * @param modelId The ID of the model.
     * @param versionIndex The index of the version.
     * @param details The attestation details.
     */
    function submitVerifierAttestation(uint256 modelId, uint256 versionIndex, string memory details)
        external onlyVerifier
    {
        require(models[modelId].creationTimestamp > 0, "Model does not exist");
        require(versionIndex < models[modelId].versionIndices.length, "Invalid version index");
        require(models[modelId].versionIndices[versionIndex] == versionIndex, "Version index mismatch"); // Safety check

        VerifierAttestation memory newAttestation = VerifierAttestation({
            verifier: msg.sender,
            details: details,
            timestamp: block.timestamp
        });

        versionAttestations[modelId][versionIndex].push(newAttestation);
        models[modelId].updateTimestamp = block.timestamp; // Consider attestation an update

        emit VerifierAttestationSubmitted(msg.sender, modelId, versionIndex, block.timestamp);
    }

    /**
     * @notice Retrieves all VerifierAttestation structs for a specific version.
     * @param modelId The ID of the model.
     * @param versionIndex The index of the version.
     * @return An array of VerifierAttestation structs.
     */
    function getVerifierAttestationsForVersion(uint256 modelId, uint256 versionIndex)
        external view
        returns (VerifierAttestation[] memory)
    {
        require(models[modelId].creationTimestamp > 0, "Model does not exist");
        require(versionIndex < models[modelId].versionIndices.length, "Invalid version index");
        require(models[modelId].versionIndices[versionIndex] == versionIndex, "Version index mismatch"); // Safety check
        return versionAttestations[modelId][versionIndex];
    }


    // --- Fee & Administrative Functions ---

    /**
     * @notice Sets the fee required to register a new model. Only callable by the contract owner.
     * @param fee The new registration fee in Wei.
     */
    function setRegistrationFee(uint256 fee) external onlyOwner {
        uint256 oldFee = _registrationFee;
        _registrationFee = fee;
        emit FeeSet(oldFee, fee, block.timestamp);
    }

    /**
     * @notice Gets the current model registration fee.
     * @return The current registration fee in Wei.
     */
    function getRegistrationFee() external view returns (uint256) {
        return _registrationFee;
    }

    /**
     * @notice Allows the contract owner to withdraw accumulated registration fees.
     * Uses ReentrancyGuard.
     */
    function withdrawFees() external onlyOwner nonReentrant {
        uint256 balance = _feesCollected;
        require(balance > 0, "No fees to withdraw");

        _feesCollected = 0;
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Fee withdrawal failed");

        emit FeesWithdrawn(owner(), balance, block.timestamp);
    }

    // Fallback function to receive ether for registration
    receive() external payable {
        // Although registerModel is payable, a direct send/transfer to the contract
        // could hit this if not calling the function directly.
        // We don't want to accept random ether without registration intent.
        // Could potentially accept and track unsolicited ether, but rejecting is safer.
        revert("Direct ether deposit not allowed. Use registerModel function.");
    }
}
```