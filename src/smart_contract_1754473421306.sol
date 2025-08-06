Okay, here's a Solidity smart contract named `AetherForge` that aims to be unique by combining several advanced and trendy concepts: a decentralized AI model marketplace, a collaborative AI model training platform with a conceptual Zero-Knowledge Proof (ZKP) integration, a reputation system, and on-chain dispute resolution for AI assets.

The core idea is to create an ecosystem where:
*   **Model Creators** can register and sell access to their AI models.
*   **Data Providers** can register and license their datasets.
*   **Compute Providers** can contribute computational resources to collaboratively train AI models for rewards, with their contributions conceptually verifiable via ZKP.
*   All interactions are underpinned by a **Reputation System** and a **Dispute Resolution** mechanism to maintain trust and quality within the ecosystem.

This design aims to avoid direct duplication of existing open-source projects by focusing on the specific interplay of these elements within an AI-centric decentralized application.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Interface for our custom AFG Token.
// This contract expects to interact with an ERC20 token for payments and rewards.
interface IAFGToken is IERC20 {
    // Standard ERC20 functions (transfer, transferFrom, approve, allowance, balanceOf, totalSupply, name, symbol, decimals)
    // are inherited from IERC20. No additional custom functions are strictly needed for this contract's logic,
    // assuming AFG tokens are pre-minted or minted by a separate authority.
}

// Outline: AetherForge - Decentralized AI Model & Training Platform
// This contract facilitates a decentralized ecosystem for AI models and datasets,
// enabling creators to list and monetize their models, data providers to share and license datasets,
// and compute providers to collaboratively train models for rewards, all underpinned by a
// reputation system and a conceptual framework for ZK-proof based verifications.

// Function Summary:
// I. Platform Management & Security:
//   1. constructor: Initializes contract owner, the address of the AFG token, and the platform fee percentage.
//   2. updateAFGTokenAddress: Allows the owner to update the associated AFG token contract address.
//   3. updateSystemFeeRecipient: Allows the owner to change the address designated to receive platform fees.
//   4. updatePlatformFeePercentage: Allows the owner to adjust the percentage of fees collected on transactions.
//   5. pauseContract: Triggers the Pausable mechanism, stopping critical operations in emergencies.
//   6. unpauseContract: Resumes contract operations after a pause.

// II. User Roles & Reputation Management:
//   7. registerActor: Enables a user to register as a Model Creator, Data Provider, or Compute Provider, setting up their initial profile and reputation.
//   8. updateActorProfile: Allows a registered actor to update their off-chain metadata URI (e.g., a link to their public profile).
//   9. getUserReputation: A public view function to query the current reputation score of any registered actor.
//   10. internalIncreaseReputation: Internal helper function to increase an actor's reputation score, typically triggered by positive actions (e.g., successful sales, validated contributions).
//   11. internalDecreaseReputation: Internal helper function to decrease an actor's reputation score, typically triggered by negative actions or dispute resolutions.

// III. AI Model Lifecycle (NFT-like Asset Management):
//   12. registerAIModel: Allows a Model Creator to register a new AI model with its metadata, initial price, and license type. Generates a unique model ID.
//   13. updateAIModelMetadata: Allows the model owner to update the off-chain metadata URI (e.g., for model version updates).
//   14. setAIModelPrice: Allows the model owner to change the price of their model in AFG tokens.
//   15. listAIModel: Makes a registered model available for purchase on the marketplace.
//   16. delistAIModel: Removes a model from active listing on the marketplace.
//   17. transferAIModelOwnership: Allows a model owner to transfer the ownership of their registered model (and its associated ID) to another registered Model Creator.

// IV. Dataset Lifecycle:
//   18. registerDataset: Allows a Data Provider to register a new dataset with its metadata, initial price, and license type. Generates a unique dataset ID.
//   19. updateDatasetMetadata: Allows the dataset owner to update the off-chain metadata URI of their registered dataset.
//   20. setDatasetPrice: Allows the dataset owner to change the price of their dataset in AFG tokens.

// V. Marketplace & Access Control:
//   21. purchaseAIModelAccess: Allows a user to purchase perpetual access to a listed AI model using AFG tokens, transferring funds to the model creator and platform.
//   22. purchaseDatasetAccess: Allows a user to purchase perpetual access to a listed dataset using AFG tokens, transferring funds to the data provider and platform.
//   23. checkModelAccess: A public view function to verify if a specific user has access to a given AI model.
//   24. checkDatasetAccess: A public view function to verify if a specific user has access to a given dataset.

// VI. Collaborative Training & Rewards (Advanced Concepts):
//   25. proposeTrainingTask: Allows a Model Creator to define and propose a collaborative AI model training task, specifying the target model, a reward pool, and required dataset hashes. Funds the reward pool with AFG tokens.
//   26. submitTrainingProof: Allows a Compute Provider to submit a cryptographic proof (e.g., a ZK-SNARK) and a hash of their training results for a specific task. This proof is conceptually verified off-chain.
//   27. verifyTrainingProofAndReward: (Intended for an Oracle or Admin role) Confirms the off-chain verification of a training proof submitted by a Compute Provider and updates the task status, making rewards claimable.
//   28. claimTrainingReward: Allows a Compute Provider to claim their accumulated AFG token rewards for successfully verified training tasks, once the task is finalized.
//   29. finalizeTrainingTask: Allows the Model Creator who proposed the task to finalize it after the deadline, enabling Compute Providers to claim their rewards.

// VII. Reviews & Dispute Resolution:
//   30. submitModelReview: Allows users who have purchased access to a model to submit a rating and an off-chain review, impacting the model creator's reputation.
//   31. submitDatasetReview: Allows users who have purchased access to a dataset to submit a rating and an off-chain review, impacting the data provider's reputation.
//   32. initiateDispute: Allows any registered actor to formally initiate a dispute regarding a model, dataset, or training task, providing off-chain evidence.
//   33. resolveDispute: (Intended for an Admin or Dispute Resolver role) Resolves an active dispute, potentially adjusting reputations of involved parties based on the verdict.

// VIII. Payouts:
//   34. withdrawFunds: Allows any actor to withdraw their accumulated AFG token earnings (e.g., from sales or training rewards) from the contract to their wallet.

// Total Public/External Functions: 34

contract AetherForge is Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---

    IAFGToken public afgToken; // Interface to the AFG ERC20 token
    address public systemFeeRecipient; // Address that receives platform fees
    uint256 public platformFeePercentage; // Percentage of sale/reward as fee (e.g., 500 for 5%, 10000 for 100%)

    // Counters for unique IDs for models, datasets, training tasks, and disputes
    Counters.Counter private _modelIds;
    Counters.Counter private _datasetIds;
    Counters.Counter private _taskIds;
    Counters.Counter private _disputeIds;

    // --- Enums ---

    // Defines the different types of actors within the AetherForge ecosystem
    enum ActorType {
        None,             // Default state, not a registered actor
        ModelCreator,     // Can register, list, and manage AI models
        DataProvider,     // Can register and manage datasets
        ComputeProvider   // Can participate in training tasks by submitting proofs
    }

    // Defines the licensing models for AI models
    enum ModelLicenseType {
        PerpetualAccess,  // Buyer gets indefinite access
        SubscriptionBased // Placeholder for more complex, time-bound access (not fully implemented in this version)
    }

    // Defines the licensing models for datasets
    enum DatasetLicenseType {
        PerpetualAccess,  // Buyer gets indefinite access
        OneTimeUse,       // License for a single use case or task
        AttributionRequired // Requires attribution when used
    }

    // Defines the types of disputes that can be initiated
    enum DisputeType {
        ModelQuality,         // Dispute regarding the quality or performance of an AI model
        DatasetIntegrity,     // Dispute regarding the accuracy or integrity of a dataset
        TrainingProofFraud,   // Dispute alleging fraudulent or invalid training proof submission
        General               // General category for other disputes
    }

    // Defines the status of a dispute
    enum DisputeStatus {
        Open,             // Dispute is active and awaiting resolution
        ResolvedAccepted, // Dispute was found to be valid, claim accepted
        ResolvedRejected  // Dispute was found to be invalid, claim rejected
    }

    // Defines the verdict given during dispute resolution
    enum DisputeVerdict {
        Accept, // The dispute initiator's claim is deemed valid
        Reject  // The dispute initiator's claim is deemed invalid
    }

    // --- Structs ---

    // Stores profile information for each registered actor
    struct ActorProfile {
        ActorType actorType;    // The role of the actor
        string metadataURI;     // URI to off-chain profile details (e.g., IPFS hash of a JSON file)
        uint256 reputation;     // A numeric reputation score, starting at 1000
        bool exists;            // True if the address is a registered actor
    }

    // Represents an AI model registered on the platform
    struct AIModel {
        address owner;          // Address of the Model Creator who owns the model
        string metadataURI;     // URI to off-chain model details (e.g., model weights, documentation)
        uint256 price;          // Price of the model in AFG tokens for perpetual access
        ModelLicenseType licenseType; // The licensing model for this model
        bool listedForSale;     // True if the model is currently available for purchase
        uint256 totalPurchases; // Counter for how many times this model has been purchased
    }

    // Represents a dataset registered on the platform
    struct Dataset {
        address owner;          // Address of the Data Provider who owns the dataset
        string metadataURI;     // URI to off-chain dataset details (e.g., dataset description, access methods)
        uint256 price;          // Price of the dataset in AFG tokens
        DatasetLicenseType licenseType; // The licensing model for this dataset
        bool listedForSale;     // True if the dataset is currently available for purchase
        uint256 totalPurchases; // Counter for how many times this dataset has been purchased
    }

    // Represents a collaborative AI model training task
    struct TrainingTask {
        address creator;        // Address of the Model Creator who proposed the task
        uint256 targetModelId;  // ID of the AI model to be trained/improved
        string taskDetailsURI;  // URI to off-chain task description (e.g., objectives, metrics)
        uint256 rewardPool;     // Total AFG tokens allocated as rewards for this task
        bytes32[] requiredDatasetHashes; // Hashes of specific datasets required for training (for proof verification)
        uint256 deadline;       // Unix timestamp by which proofs must be submitted
        address[] computeProviders; // List of addresses who have submitted proofs for this task
        mapping(address => bytes32) computeProviderResultHashes; // Maps provider address to their submitted result hash
        mapping(address => bytes) computeProviderZKProofs;      // Maps provider address to their submitted ZK proof
        mapping(address => bool) proofVerified;                 // Tracks if a provider's proof has been verified (off-chain)
        mapping(address => bool) rewardClaimed;                 // Tracks if a provider has claimed their reward
        uint256 totalVerifiedProviders;                         // Count of unique providers whose proofs have been verified
        bool finalized;                                         // True if the task has been closed by the creator, enabling reward claims
    }

    // Represents an initiated dispute
    struct Dispute {
        address initiator;          // Address of the party who initiated the dispute
        uint256 targetAssetId;      // ID of the model, dataset, or training task being disputed
        DisputeType disputeType;    // The type of the dispute
        string evidenceURI;         // URI to off-chain evidence supporting the dispute
        DisputeStatus status;       // Current status of the dispute (Open, ResolvedAccepted, ResolvedRejected)
        address[] affectedParties;  // Addresses of other parties directly involved in the dispute
        string resolutionNotesURI;  // URI to off-chain notes regarding the dispute resolution
    }

    // --- Mappings ---

    // Maps actor addresses to their ActorProfile structs
    mapping(address => ActorProfile) public actors;
    // Maps unique model IDs to their AIModel structs
    mapping(uint256 => AIModel) public aiModels;
    // Maps unique dataset IDs to their Dataset structs
    mapping(uint256 => Dataset) public datasets;
    // Maps unique training task IDs to their TrainingTask structs
    mapping(uint256 => TrainingTask) public trainingTasks;
    // Maps unique dispute IDs to their Dispute structs
    mapping(uint256 => Dispute) public disputes;

    // Tracks which users have purchased access to which AI models
    mapping(address => mapping(uint256 => bool)) public userModelAccess;
    // Tracks which users have purchased access to which datasets
    mapping(address => mapping(uint256 => bool)) public userDatasetAccess;

    // Stores the accumulated AFG token earnings for each actor, awaiting withdrawal
    mapping(address => uint256) public pendingWithdrawals;

    // --- Events ---

    event AFGTokenAddressUpdated(address indexed newAddress);
    event SystemFeeRecipientUpdated(address indexed newRecipient);
    event PlatformFeePercentageUpdated(uint256 newPercentage);

    event ActorRegistered(address indexed actorAddress, ActorType actorType, string metadataURI);
    event ActorProfileUpdated(address indexed actorAddress, string newMetadataURI);
    event ReputationIncreased(address indexed actorAddress, uint256 amount, uint256 newReputation);
    event ReputationDecreased(address indexed actorAddress, uint256 amount, uint256 newReputation);

    event AIModelRegistered(uint256 indexed modelId, address indexed creator, string metadataURI, uint256 price);
    event AIModelUpdated(uint256 indexed modelId, string newMetadataURI);
    event AIModelPriceUpdated(uint256 indexed modelId, uint256 newPrice);
    event AIModelListed(uint256 indexed modelId);
    event AIModelDelisted(uint256 indexed modelId);
    event AIModelOwnershipTransferred(uint256 indexed modelId, address indexed from, address indexed to);

    event DatasetRegistered(uint256 indexed datasetId, address indexed provider, string metadataURI, uint256 price);
    event DatasetUpdated(uint256 indexed datasetId, string newMetadataURI);
    event DatasetPriceUpdated(uint256 indexed datasetId, uint256 newPrice);

    event ModelAccessPurchased(address indexed purchaser, uint256 indexed modelId, uint256 pricePaid);
    event DatasetAccessPurchased(address indexed purchaser, uint256 indexed datasetId, uint256 pricePaid);

    event TrainingTaskProposed(uint256 indexed taskId, address indexed creator, uint256 targetModelId, uint256 rewardPool);
    event TrainingProofSubmitted(uint256 indexed taskId, address indexed computeProvider, bytes32 resultHash);
    event TrainingProofVerifiedAndRewarded(uint256 indexed taskId, address indexed computeProvider); // Emitted when proof is verified
    event TrainingRewardClaimed(uint256 indexed taskId, address indexed computeProvider, uint256 amount);
    event TrainingTaskFinalized(uint256 indexed taskId);

    event ModelReviewed(uint256 indexed modelId, address indexed reviewer, uint8 rating);
    event DatasetReviewed(uint256 indexed datasetId, address indexed reviewer, uint8 rating);

    event DisputeInitiated(uint256 indexed disputeId, address indexed initiator, DisputeType disputeType, uint256 targetAssetId);
    event DisputeResolved(uint256 indexed disputeId, DisputeStatus verdict);

    event FundsWithdrawn(address indexed beneficiary, uint256 amount);

    // --- Modifiers ---

    // Ensures the caller is a registered actor of a specific type
    modifier onlyActorType(ActorType _type) {
        require(actors[msg.sender].actorType == _type, "AetherForge: Not authorized for this actor type");
        _;
    }

    // Ensures the caller is a registered actor of any type
    modifier onlyActorExists() {
        require(actors[msg.sender].exists, "AetherForge: Actor not registered");
        _;
    }

    // Ensures the caller is the owner of the specified AI model
    modifier onlyModelOwner(uint256 _modelId) {
        require(aiModels[_modelId].owner != address(0), "AetherForge: Model does not exist."); // Ensure model exists before checking ownership
        require(aiModels[_modelId].owner == msg.sender, "AetherForge: Not model owner");
        _;
    }

    // Ensures the caller is the owner of the specified dataset
    modifier onlyDatasetOwner(uint256 _datasetId) {
        require(datasets[_datasetId].owner != address(0), "AetherForge: Dataset does not exist."); // Ensure dataset exists before checking ownership
        require(datasets[_datasetId].owner == msg.sender, "AetherForge: Not dataset owner");
        _;
    }

    // --- Constructor ---

    constructor(address _afgTokenAddress, address _systemFeeRecipient, uint256 _platformFeePercentage)
        Ownable(msg.sender) // Initializes the contract owner
        Pausable()         // Enables pausing/unpausing functionality
    {
        require(_afgTokenAddress != address(0), "AetherForge: Invalid AFG token address");
        require(_systemFeeRecipient != address(0), "AetherForge: Invalid system fee recipient");
        require(_platformFeePercentage <= 10000, "AetherForge: Fee percentage too high (max 100%)"); // Max 100% (10000 basis points)

        afgToken = IAFGToken(_afgTokenAddress);
        systemFeeRecipient = _systemFeeRecipient;
        platformFeePercentage = _platformFeePercentage;
    }

    // --- I. Platform Management & Security ---

    /**
     * @notice Updates the address of the AFG token contract that AetherForge interacts with.
     * @dev Only the contract owner can call this function.
     * @param _newAddress The new address of the AFG token contract.
     */
    function updateAFGTokenAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "AetherForge: New address cannot be zero");
        afgToken = IAFGToken(_newAddress);
        emit AFGTokenAddressUpdated(_newAddress);
    }

    /**
     * @notice Updates the address designated to receive platform fees.
     * @dev Only the contract owner can call this function.
     * @param _newRecipient The new address for fee collection.
     */
    function updateSystemFeeRecipient(address _newRecipient) external onlyOwner {
        require(_newRecipient != address(0), "AetherForge: New recipient cannot be zero");
        systemFeeRecipient = _newRecipient;
        emit SystemFeeRecipientUpdated(_newRecipient);
    }

    /**
     * @notice Updates the percentage of fees collected by the platform on transactions.
     * @dev Only the contract owner can call this function.
     * @param _newPercentage The new fee percentage (e.g., 500 for 5%). Max 10000 (100%).
     */
    function updatePlatformFeePercentage(uint256 _newPercentage) external onlyOwner {
        require(_newPercentage <= 10000, "AetherForge: Fee percentage too high (max 100%)");
        platformFeePercentage = _newPercentage;
        emit PlatformFeePercentageUpdated(_newPercentage);
    }

    /**
     * @notice Pauses contract operations in case of an emergency or upgrade.
     * @dev Only the contract owner can call this function. Utilizes OpenZeppelin's Pausable.
     */
    function pauseContract() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses contract operations after a pause.
     * @dev Only the contract owner can call this function. Utilizes OpenZeppelin's Pausable.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    // --- II. User Roles & Reputation Management ---

    /**
     * @notice Registers the caller as a specific type of actor within the AetherForge ecosystem.
     * @param _actorType The type of role the user wishes to register as (ModelCreator, DataProvider, ComputeProvider).
     * @param _metadataURI URI to off-chain profile details (e.g., IPFS hash of a JSON file with bio, links).
     */
    function registerActor(ActorType _actorType, string calldata _metadataURI)
        external
        whenNotPaused
    {
        require(_actorType != ActorType.None, "AetherForge: Invalid actor type");
        require(!actors[msg.sender].exists, "AetherForge: Actor already registered");

        actors[msg.sender] = ActorProfile({
            actorType: _actorType,
            metadataURI: _metadataURI,
            reputation: 1000, // All new actors start with a base reputation
            exists: true
        });

        emit ActorRegistered(msg.sender, _actorType, _metadataURI);
    }

    /**
     * @notice Allows a registered actor to update their off-chain profile metadata URI.
     * @param _newMetadataURI The new URI pointing to updated profile information.
     */
    function updateActorProfile(string calldata _newMetadataURI)
        external
        onlyActorExists
        whenNotPaused
    {
        actors[msg.sender].metadataURI = _newMetadataURI;
        emit ActorProfileUpdated(msg.sender, _newMetadataURI);
    }

    /**
     * @notice Retrieves the current reputation score of a given actor address.
     * @param _actor The address of the actor whose reputation to query.
     * @return The current reputation score. Returns 0 if the actor is not registered.
     */
    function getUserReputation(address _actor) public view returns (uint256) {
        return actors[_actor].reputation;
    }

    /**
     * @dev Internal function to increase an actor's reputation.
     * @param _actor The address of the actor whose reputation to increase.
     * @param _amount The amount by which to increase the reputation.
     */
    function internalIncreaseReputation(address _actor, uint256 _amount) internal {
        if (actors[_actor].exists) {
            actors[_actor].reputation += _amount;
            emit ReputationIncreased(_actor, _amount, actors[_actor].reputation);
        }
    }

    /**
     * @dev Internal function to decrease an actor's reputation.
     * @param _actor The address of the actor whose reputation to decrease.
     * @param _amount The amount by which to decrease the reputation. Reputation cannot go below zero.
     */
    function internalDecreaseReputation(address _actor, uint256 _amount) internal {
        if (actors[_actor].exists) {
            if (actors[_actor].reputation > _amount) {
                actors[_actor].reputation -= _amount;
            } else {
                actors[_actor].reputation = 0; // Ensure reputation does not go negative
            }
            emit ReputationDecreased(_actor, _amount, actors[_actor].reputation);
        }
    }

    // --- III. AI Model Lifecycle (NFT-like Asset Management) ---

    /**
     * @notice Allows a Model Creator to register a new AI model with the platform.
     * @dev This creates a unique model ID and stores initial model details.
     * @param _metadataURI URI to off-chain model details (e.g., IPFS hash of model files, documentation).
     * @param _initialPrice The initial price of access to this model, in AFG tokens.
     * @param _licenseType The type of license offered for this model (e.g., PerpetualAccess).
     */
    function registerAIModel(string calldata _metadataURI, uint256 _initialPrice, ModelLicenseType _licenseType)
        external
        onlyActorType(ActorType.ModelCreator)
        whenNotPaused
    {
        _modelIds.increment();
        uint256 newModelId = _modelIds.current();

        aiModels[newModelId] = AIModel({
            owner: msg.sender,
            metadataURI: _metadataURI,
            price: _initialPrice,
            licenseType: _licenseType,
            listedForSale: false, // Models are not listed for sale by default upon registration
            totalPurchases: 0
        });

        emit AIModelRegistered(newModelId, msg.sender, _metadataURI, _initialPrice);
    }

    /**
     * @notice Allows the owner of an AI model to update its off-chain metadata URI.
     * @param _modelId The ID of the model to update.
     * @param _newMetadataURI The new URI pointing to updated model information.
     */
    function updateAIModelMetadata(uint256 _modelId, string calldata _newMetadataURI)
        external
        onlyModelOwner(_modelId)
        whenNotPaused
    {
        aiModels[_modelId].metadataURI = _newMetadataURI;
        emit AIModelUpdated(_modelId, _newMetadataURI);
    }

    /**
     * @notice Allows the owner of an AI model to change its price.
     * @param _modelId The ID of the model whose price to change.
     * @param _newPrice The new price of the model in AFG tokens.
     */
    function setAIModelPrice(uint256 _modelId, uint256 _newPrice)
        external
        onlyModelOwner(_modelId)
        whenNotPaused
    {
        aiModels[_modelId].price = _newPrice;
        emit AIModelPriceUpdated(_modelId, _newPrice);
    }

    /**
     * @notice Makes a registered AI model available for purchase on the marketplace.
     * @param _modelId The ID of the model to list.
     */
    function listAIModel(uint256 _modelId)
        external
        onlyModelOwner(_modelId)
        whenNotPaused
    {
        require(aiModels[_modelId].price > 0, "AetherForge: Model price must be set before listing");
        aiModels[_modelId].listedForSale = true;
        emit AIModelListed(_modelId);
    }

    /**
     * @notice Removes an AI model from active listing on the marketplace.
     * @param _modelId The ID of the model to delist.
     */
    function delistAIModel(uint256 _modelId)
        external
        onlyModelOwner(_modelId)
        whenNotPaused
    {
        aiModels[_modelId].listedForSale = false;
        emit AIModelDelisted(_modelId);
    }

    /**
     * @notice Allows an AI model owner to transfer ownership of their model to another registered Model Creator.
     * @param _modelId The ID of the model to transfer.
     * @param _newOwner The address of the new Model Creator owner.
     */
    function transferAIModelOwnership(uint256 _modelId, address _newOwner)
        external
        onlyModelOwner(_modelId)
        whenNotPaused
    {
        require(_newOwner != address(0), "AetherForge: New owner cannot be zero address");
        require(actors[_newOwner].actorType == ActorType.ModelCreator, "AetherForge: New owner must be a registered Model Creator");

        address oldOwner = aiModels[_modelId].owner;
        aiModels[_modelId].owner = _newOwner;

        emit AIModelOwnershipTransferred(_modelId, oldOwner, _newOwner);
    }


    // --- IV. Dataset Lifecycle ---

    /**
     * @notice Allows a Data Provider to register a new dataset with the platform.
     * @param _metadataURI URI to off-chain dataset details (e.g., description, access method).
     * @param _initialPrice The initial price of access to this dataset, in AFG tokens.
     * @param _licenseType The type of license offered for this dataset.
     */
    function registerDataset(string calldata _metadataURI, uint256 _initialPrice, DatasetLicenseType _licenseType)
        external
        onlyActorType(ActorType.DataProvider)
        whenNotPaused
    {
        _datasetIds.increment();
        uint256 newDatasetId = _datasetIds.current();

        datasets[newDatasetId] = Dataset({
            owner: msg.sender,
            metadataURI: _metadataURI,
            price: _initialPrice,
            licenseType: _licenseType,
            listedForSale: true, // Datasets are listed by default upon registration
            totalPurchases: 0
        });

        emit DatasetRegistered(newDatasetId, msg.sender, _metadataURI, _initialPrice);
    }

    /**
     * @notice Allows the owner of a dataset to update its off-chain metadata URI.
     * @param _datasetId The ID of the dataset to update.
     * @param _newMetadataURI The new URI pointing to updated dataset information.
     */
    function updateDatasetMetadata(uint256 _datasetId, string calldata _newMetadataURI)
        external
        onlyDatasetOwner(_datasetId)
        whenNotPaused
    {
        datasets[_datasetId].metadataURI = _newMetadataURI;
        emit DatasetUpdated(_datasetId, _newMetadataURI);
    }

    /**
     * @notice Allows the owner of a dataset to change its price.
     * @param _datasetId The ID of the dataset whose price to change.
     * @param _newPrice The new price of the dataset in AFG tokens.
     */
    function setDatasetPrice(uint256 _datasetId, uint256 _newPrice)
        external
        onlyDatasetOwner(_datasetId)
        whenNotPaused
    {
        datasets[_datasetId].price = _newPrice;
        emit DatasetPriceUpdated(_datasetId, _newPrice);
    }

    // --- V. Marketplace & Access Control ---

    /**
     * @notice Allows a user to purchase perpetual access to a listed AI model.
     * @dev The buyer must have approved AetherForge to transfer the required AFG tokens.
     * Funds are split between the model creator and the platform fee recipient.
     * @param _modelId The ID of the AI model to purchase access for.
     */
    function purchaseAIModelAccess(uint256 _modelId)
        external
        nonReentrant
        whenNotPaused
    {
        AIModel storage model = aiModels[_modelId];
        require(model.owner != address(0), "AetherForge: Model does not exist");
        require(model.listedForSale, "AetherForge: Model is not listed for sale");
        require(msg.sender != model.owner, "AetherForge: Cannot purchase your own model");
        require(!userModelAccess[msg.sender][_modelId], "AetherForge: Already have access to this model");

        uint256 price = model.price;
        require(price > 0, "AetherForge: Model has no price set");

        uint256 platformFee = (price * platformFeePercentage) / 10000;
        uint256 creatorShare = price - platformFee;

        // Transfer AFG tokens from buyer to contract's balance
        require(afgToken.transferFrom(msg.sender, address(this), price), "AetherForge: AFG transfer failed");

        // Distribute shares to pending withdrawals
        if (creatorShare > 0) {
            pendingWithdrawals[model.owner] += creatorShare;
        }
        if (platformFee > 0) {
            pendingWithdrawals[systemFeeRecipient] += platformFee;
        }

        userModelAccess[msg.sender][_modelId] = true; // Grant access
        model.totalPurchases++;
        internalIncreaseReputation(model.owner, 10); // Reward creator for a successful sale

        emit ModelAccessPurchased(msg.sender, _modelId, price);
    }

    /**
     * @notice Allows a user to purchase perpetual access to a listed dataset.
     * @dev Similar to model purchase, funds are split between data provider and platform.
     * @param _datasetId The ID of the dataset to purchase access for.
     */
    function purchaseDatasetAccess(uint256 _datasetId)
        external
        nonReentrant
        whenNotPaused
    {
        Dataset storage dataset = datasets[_datasetId];
        require(dataset.owner != address(0), "AetherForge: Dataset does not exist");
        require(dataset.listedForSale, "AetherForge: Dataset is not listed for sale");
        require(msg.sender != dataset.owner, "AetherForge: Cannot purchase your own dataset");
        require(!userDatasetAccess[msg.sender][_datasetId], "AetherForge: Already have access to this dataset");

        uint256 price = dataset.price;
        require(price > 0, "AetherForge: Dataset has no price set");

        uint256 platformFee = (price * platformFeePercentage) / 10000;
        uint256 providerShare = price - platformFee;

        require(afgToken.transferFrom(msg.sender, address(this), price), "AetherForge: AFG transfer failed");

        if (providerShare > 0) {
            pendingWithdrawals[dataset.owner] += providerShare;
        }
        if (platformFee > 0) {
            pendingWithdrawals[systemFeeRecipient] += platformFee;
        }

        userDatasetAccess[msg.sender][_datasetId] = true; // Grant access
        dataset.totalPurchases++;
        internalIncreaseReputation(dataset.owner, 5); // Reward provider for a successful sale

        emit DatasetAccessPurchased(msg.sender, _datasetId, price);
    }

    /**
     * @notice Checks if a specific user has access to a particular AI model.
     * @param _user The address of the user to check.
     * @param _modelId The ID of the AI model.
     * @return True if the user has access, false otherwise.
     */
    function checkModelAccess(address _user, uint256 _modelId) public view returns (bool) {
        return userModelAccess[_user][_modelId];
    }

    /**
     * @notice Checks if a specific user has access to a particular dataset.
     * @param _user The address of the user to check.
     * @param _datasetId The ID of the dataset.
     * @return True if the user has access, false otherwise.
     */
    function checkDatasetAccess(address _user, uint256 _datasetId) public view returns (bool) {
        return userDatasetAccess[_user][_datasetId];
    }

    // --- VI. Collaborative Training & Rewards (Advanced Concepts) ---

    /**
     * @notice Allows a Model Creator to propose a new collaborative training task for one of their models.
     * @dev Requires the creator to fund a reward pool in AFG tokens for participating Compute Providers.
     * @param _targetModelId The ID of the AI model that this task aims to train or improve.
     * @param _taskDetailsURI URI to off-chain detailed description of the training task.
     * @param _rewardPool The total amount of AFG tokens allocated as rewards for this task.
     * @param _requiredDatasetHashes Hashes of specific datasets that must be used for training, for verification purposes.
     */
    function proposeTrainingTask(
        uint256 _targetModelId,
        string calldata _taskDetailsURI,
        uint256 _rewardPool,
        bytes32[] calldata _requiredDatasetHashes
    ) external
      onlyActorType(ActorType.ModelCreator)
      nonReentrant
      whenNotPaused
    {
        require(aiModels[_targetModelId].owner != address(0), "AetherForge: Target model does not exist.");
        require(aiModels[_targetModelId].owner == msg.sender, "AetherForge: Must own the target model to propose a task");
        require(_rewardPool > 0, "AetherForge: Reward pool must be greater than zero");
        require(_requiredDatasetHashes.length > 0, "AetherForge: Must specify at least one required dataset hash for verification.");

        // Transfer the reward pool funds from the creator to the contract
        require(afgToken.transferFrom(msg.sender, address(this), _rewardPool), "AetherForge: Failed to transfer reward pool to contract");

        _taskIds.increment();
        uint256 newTaskId = _taskIds.current();

        TrainingTask storage newTask = trainingTasks[newTaskId];
        newTask.creator = msg.sender;
        newTask.targetModelId = _targetModelId;
        newTask.taskDetailsURI = _taskDetailsURI;
        newTask.rewardPool = _rewardPool;
        newTask.requiredDatasetHashes = _requiredDatasetHashes;
        newTask.deadline = block.timestamp + 7 days; // Example deadline: 7 days from the proposal time
        newTask.finalized = false;

        emit TrainingTaskProposed(newTaskId, msg.sender, _targetModelId, _rewardPool);
    }

    /**
     * @notice Allows a Compute Provider to submit a cryptographic proof (e.g., ZK-SNARK) and a result hash for a completed training task.
     * @dev This function assumes off-chain ZKP generation and verification will happen. The proof bytes are stored for later conceptual verification.
     * @param _taskId The ID of the training task.
     * @param _resultHash A cryptographic hash of the training results (e.g., model weights, evaluation metrics).
     * @param _zkProof The actual Zero-Knowledge Proof bytes, generated off-chain, proving valid computation.
     */
    function submitTrainingProof(uint256 _taskId, bytes32 _resultHash, bytes calldata _zkProof)
        external
        onlyActorType(ActorType.ComputeProvider)
        whenNotPaused
    {
        TrainingTask storage task = trainingTasks[_taskId];
        require(task.creator != address(0), "AetherForge: Training task does not exist");
        require(block.timestamp <= task.deadline, "AetherForge: Training task deadline passed for submission");
        require(!task.finalized, "AetherForge: Training task is finalized, no more submissions");
        require(task.computeProviderResultHashes[msg.sender] == bytes32(0), "AetherForge: You have already submitted a proof for this task");
        require(_zkProof.length > 0, "AetherForge: ZK proof cannot be empty");

        // Record the provider's submission
        task.computeProviders.push(msg.sender);
        task.computeProviderResultHashes[msg.sender] = _resultHash;
        task.computeProviderZKProofs[msg.sender] = _zkProof; // Store the proof for conceptual off-chain verification

        emit TrainingProofSubmitted(_taskId, msg.sender, _resultHash);
    }

    /**
     * @notice Confirms the off-chain verification of a training proof submitted by a Compute Provider.
     * @dev This function is designed to be called by a trusted entity (e.g., the contract owner acting as an oracle, or a DAO)
     * after they have successfully verified the `_zkProof` off-chain.
     * It marks the provider's contribution as verified, enabling them to claim rewards once the task is finalized.
     * @param _taskId The ID of the training task.
     * @param _computeProvider The address of the Compute Provider whose proof is being verified.
     */
    function verifyTrainingProofAndReward(uint256 _taskId, address _computeProvider)
        external
        onlyOwner // For simplicity, the contract owner acts as the oracle/admin role
        nonReentrant
        whenNotPaused
    {
        TrainingTask storage task = trainingTasks[_taskId];
        require(task.creator != address(0), "AetherForge: Training task does not exist");
        require(!task.finalized, "AetherForge: Training task is finalized, cannot verify new proofs");
        require(task.computeProviderResultHashes[_computeProvider] != bytes32(0), "AetherForge: No proof submitted by this provider for this task");
        require(!task.proofVerified[_computeProvider], "AetherForge: Proof already verified for this provider");

        // In a full implementation, `task.computeProviderZKProofs[_computeProvider]` would have been
        // used by an off-chain verifier. This call simply registers the successful outcome.
        task.proofVerified[_computeProvider] = true;
        task.totalVerifiedProviders++;

        emit TrainingProofVerifiedAndRewarded(_taskId, _computeProvider);
    }

    /**
     * @notice Allows a Compute Provider to claim their share of the reward pool for a finalized and successfully verified training task.
     * @param _taskId The ID of the training task from which to claim rewards.
     */
    function claimTrainingReward(uint256 _taskId)
        external
        nonReentrant
        whenNotPaused
    {
        TrainingTask storage task = trainingTasks[_taskId];
        require(task.creator != address(0), "AetherForge: Training task does not exist");
        require(task.proofVerified[msg.sender], "AetherForge: Your proof for this task is not yet verified");
        require(!task.rewardClaimed[msg.sender], "AetherForge: Rewards already claimed for this task");
        require(task.finalized, "AetherForge: Task must be finalized by creator before claiming rewards.");
        require(task.totalVerifiedProviders > 0, "AetherForge: No providers verified for this task to calculate share.");

        // Calculate reward share based on the total number of verified providers for the task
        uint256 rewardShare = task.rewardPool / task.totalVerifiedProviders;

        task.rewardClaimed[msg.sender] = true;
        pendingWithdrawals[msg.sender] += rewardShare; // Add to their pending withdrawal balance

        emit TrainingRewardClaimed(_taskId, msg.sender, rewardShare);
        internalIncreaseReputation(msg.sender, 20); // Reward reputation for successful training contribution
    }

    /**
     * @notice Allows the Model Creator who proposed a task to finalize it.
     * @dev Finalizing a task closes it for new proof submissions and enables verified Compute Providers to claim their rewards.
     * It can only be finalized after its deadline has passed.
     * @param _taskId The ID of the training task to finalize.
     */
    function finalizeTrainingTask(uint256 _taskId)
        external
        onlyActorType(ActorType.ModelCreator)
        whenNotPaused
    {
        TrainingTask storage task = trainingTasks[_taskId];
        require(task.creator == msg.sender, "AetherForge: Only task creator can finalize.");
        require(!task.finalized, "AetherForge: Task already finalized.");
        require(block.timestamp > task.deadline, "AetherForge: Deadline not reached yet. Task cannot be finalized early.");

        task.finalized = true;

        // Optionally, logic could be added here to refund any remaining rewardPool
        // to the creator if `task.totalVerifiedProviders` is less than expected,
        // or redistribute it, depending on the desired tokenomics.
        // For simplicity, remaining funds stay in the contract's balance in this version.

        emit TrainingTaskFinalized(_taskId);
    }


    // --- VII. Reviews & Dispute Resolution ---

    /**
     * @notice Allows a user who has purchased model access to submit a review and rating.
     * @dev Reviews influence the model creator's reputation. A basic reputation adjustment based on rating is applied.
     * @param _modelId The ID of the model being reviewed.
     * @param _rating The rating given (1-5, where 5 is best).
     * @param _reviewURI URI to off-chain detailed review content.
     */
    function submitModelReview(uint256 _modelId, uint8 _rating, string calldata _reviewURI)
        external
        whenNotPaused
    {
        require(aiModels[_modelId].owner != address(0), "AetherForge: Model does not exist");
        require(_rating >= 1 && _rating <= 5, "AetherForge: Rating must be between 1 and 5");
        require(userModelAccess[msg.sender][_modelId], "AetherForge: Must have purchased access to review this model");
        require(msg.sender != aiModels[_modelId].owner, "AetherForge: Creator cannot review their own model");

        // Basic reputation adjustment: positive rating increases creator reputation, negative decreases.
        if (_rating >= 4) {
            internalIncreaseReputation(aiModels[_modelId].owner, 5);
        } else if (_rating <= 2) {
            internalDecreaseReputation(aiModels[_modelId].owner, 5);
        }

        // The actual review content (_reviewURI) is stored off-chain.
        emit ModelReviewed(_modelId, msg.sender, _rating);
    }

    /**
     * @notice Allows a user who has purchased dataset access to submit a review and rating.
     * @dev Similar to model reviews, influences the data provider's reputation.
     * @param _datasetId The ID of the dataset being reviewed.
     * @param _rating The rating given (1-5, where 5 is best).
     * @param _reviewURI URI to off-chain detailed review content.
     */
    function submitDatasetReview(uint256 _datasetId, uint8 _rating, string calldata _reviewURI)
        external
        whenNotPaused
    {
        require(datasets[_datasetId].owner != address(0), "AetherForge: Dataset does not exist");
        require(_rating >= 1 && _rating <= 5, "AetherForge: Rating must be between 1 and 5");
        require(userDatasetAccess[msg.sender][_datasetId], "AetherForge: Must have purchased access to review this dataset");
        require(msg.sender != datasets[_datasetId].owner, "AetherForge: Provider cannot review their own dataset");

        if (_rating >= 4) {
            internalIncreaseReputation(datasets[_datasetId].owner, 3);
        } else if (_rating <= 2) {
            internalDecreaseReputation(datasets[_datasetId].owner, 3);
        }

        emit DatasetReviewed(_datasetId, msg.sender, _rating);
    }

    /**
     * @notice Allows any registered actor to formally initiate a dispute concerning a model, dataset, or training task.
     * @dev Requires providing a URI to off-chain evidence and specifying the parties affected by the dispute.
     * @param _targetAssetId The ID of the asset (model, dataset, or task) that is the subject of the dispute.
     * @param _type The type of dispute (e.g., ModelQuality, TrainingProofFraud).
     * @param _evidenceURI URI to off-chain evidence (e.g., IPFS hash of documents, logs, analyses).
     * @param _affectedParties An array of addresses of other actors directly impacted by this dispute.
     */
    function initiateDispute(
        uint256 _targetAssetId,
        DisputeType _type,
        string calldata _evidenceURI,
        address[] calldata _affectedParties
    ) external
      onlyActorExists
      whenNotPaused
    {
        require(_evidenceURI.length > 0, "AetherForge: Evidence URI cannot be empty");
        require(_affectedParties.length > 0, "AetherForge: Must specify at least one affected party");
        for (uint i = 0; i < _affectedParties.length; i++) {
            require(actors[_affectedParties[i]].exists, "AetherForge: Affected party must be a registered actor");
            require(_affectedParties[i] != msg.sender, "AetherForge: Cannot dispute yourself as an affected party"); // Initiator is separate
        }

        _disputeIds.increment();
        uint256 newDisputeId = _disputeIds.current();

        disputes[newDisputeId] = Dispute({
            initiator: msg.sender,
            targetAssetId: _targetAssetId,
            disputeType: _type,
            evidenceURI: _evidenceURI,
            status: DisputeStatus.Open,
            affectedParties: _affectedParties,
            resolutionNotesURI: "" // Will be set upon resolution
        });

        emit DisputeInitiated(newDisputeId, msg.sender, _type, _targetAssetId);
    }

    /**
     * @notice Resolves an active dispute, updating its status and adjusting reputations based on the verdict.
     * @dev This function is intended to be called by a designated dispute resolver (e.g., contract owner, a DAO, or an arbitration oracle).
     * Reputation of initiator and affected parties are adjusted based on the outcome.
     * @param _disputeId The ID of the dispute to resolve.
     * @param _verdict The resolution verdict (Accept or Reject).
     * @param _resolutionNotesURI URI to off-chain notes explaining the resolution decision.
     */
    function resolveDispute(uint256 _disputeId, DisputeVerdict _verdict, string calldata _resolutionNotesURI)
        external
        onlyOwner // For this example, the contract owner acts as the dispute resolver.
        whenNotPaused
    {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.initiator != address(0), "AetherForge: Dispute does not exist");
        require(dispute.status == DisputeStatus.Open, "AetherForge: Dispute already resolved");
        require(_resolutionNotesURI.length > 0, "AetherForge: Resolution notes URI cannot be empty");

        dispute.status = _verdict == DisputeVerdict.Accept ? DisputeStatus.ResolvedAccepted : DisputeStatus.ResolvedRejected;
        dispute.resolutionNotesURI = _resolutionNotesURI;

        // Apply reputation adjustments based on the dispute verdict
        if (_verdict == DisputeVerdict.Accept) {
            internalIncreaseReputation(dispute.initiator, 50); // Reward the initiator for a valid claim
            for (uint i = 0; i < dispute.affectedParties.length; i++) {
                internalDecreaseReputation(dispute.affectedParties[i], 50); // Penalize affected parties for validated grievance
                // More complex logic could be added here, e.g., refunding funds for model quality issues.
            }
        } else { // DisputeVerdict.Reject (Initiator's claim was deemed invalid)
            internalDecreaseReputation(dispute.initiator, 25); // Penalize initiator for a frivolous dispute
            for (uint i = 0; i < dispute.affectedParties.length; i++) {
                internalIncreaseReputation(dispute.affectedParties[i], 10); // Reward affected parties if their conduct was validated
            }
        }

        emit DisputeResolved(_disputeId, dispute.status);
    }

    // --- VIII. Payouts ---

    /**
     * @notice Allows any actor to withdraw their accumulated AFG token earnings from the contract's balance.
     * @dev Uses ReentrancyGuard to prevent re-entrancy attacks during token transfer.
     */
    function withdrawFunds() external nonReentrant whenNotPaused {
        uint256 amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "AetherForge: No funds to withdraw");

        pendingWithdrawals[msg.sender] = 0; // Reset pending balance before transfer
        require(afgToken.transfer(msg.sender, amount), "AetherForge: AFG token withdrawal failed");

        emit FundsWithdrawn(msg.sender, amount);
    }
}
```