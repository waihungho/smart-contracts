Okay, here is a Solidity smart contract for a Decentralized AI Model Marketplace. It incorporates concepts like model registration, versioning, access control, pay-per-inference, staking for visibility/trust, reporting, rating, fees, and admin controls, aiming for complexity and creativity beyond basic marketplaces.

It's important to note that while the *metadata* and *access logic* are on-chain, the AI models themselves and the computation would necessarily reside *off-chain*. This contract manages the *rights*, *payments*, and *discovery* aspects.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DecentralizedAIMarketplace
 * @dev A marketplace for decentralized AI model access, licensing, and inference requests.
 *
 * Outline:
 * 1. State Variables: Core data storage for models, users, stakes, fees, etc.
 * 2. Structs: Data structures defining models, stakes, etc.
 * 3. Events: Signals emitted for important state changes.
 * 4. Modifiers: Reusable checks for access control and contract state.
 * 5. Core Logic:
 *    - Model Management: Registration, updates, versioning, listing, deactivation, ownership transfer.
 *    - Marketplace Access: Purchasing access, requesting inferences (pay-per-use).
 *    - Revenue Management: Creator withdrawals, fee collection.
 *    - Staking & Reputation: Staking on models for visibility/trust, claiming stakes, reporting models, rating models.
 *    - Admin & Governance: Setting fees, pausing, role management, report resolution (on-chain marker).
 * 6. View Functions: Read-only functions to query contract state.
 *
 * Summary:
 * This contract creates a decentralized marketplace where AI model creators can register,
 * list, and manage their models. Buyers can purchase access rights or pay per inference
 * request. The contract handles payments, distributes revenue, and allows for platform fees.
 * Advanced features include model versioning, user staking on models to signal confidence
 * or boost visibility, a basic reporting mechanism, and a simple rating system.
 * Admin roles are included for potential off-chain moderation actions reflected on-chain
 * (like marking reports as resolved).
 *
 * This contract does NOT:
 * - Host AI models or perform AI computations on-chain.
 * - Provide off-chain dispute resolution or complex arbitration.
 * - Guarantee the quality or functionality of off-chain models.
 * - Implement complex staking rewards or slashing logic.
 * - Handle complex subscription models beyond simple access purchase.
 */
contract DecentralizedAIMarketplace {

    address public owner;
    address public feeCollector;
    uint256 public marketplaceFeeBasisPoints; // Fee in basis points (e.g., 100 for 1%)
    uint256 private totalCollectedFees;

    // State variables
    uint256 private nextModelId = 1;
    uint256 private nextStakeId = 1;

    // --- Structs ---

    struct Model {
        address creator;
        string name;
        string description;
        string baseAccessUri; // URI template for accessing the model API/resource
        uint256 pricePerAccess; // Price to purchase general access (0 if only pay-per-inference)
        uint256 pricePerInference; // Price for a single inference request (0 if only access purchase)
        uint256 creationTime;
        uint256 latestVersion;
        bool isListed;      // Is the model actively listed for sale/access?
        bool isActive;      // Is the model currently usable/not deactivated?
        uint256 totalAccessSold;
        uint256 totalInferenceRequests;
        uint256 totalRevenueGross; // Total revenue before fees
        mapping(uint256 => bytes32) versionHashes; // Hash of the model file/config for each version
    }

    struct Stake {
        address staker;
        uint256 amount;
        uint256 startTime;
        uint256 modelId;
        bool active; // False if claimed
    }

    // --- Mappings ---

    mapping(uint256 => Model) public models;
    mapping(address => uint256[]) public creatorModels; // Creator address to list of model IDs

    // Access control: modelId => buyerAddress => hasAccess (true/false)
    mapping(uint256 => mapping(address => bool)) private modelAccessMap;

    // User balances for withdrawal: creatorAddress => amount
    mapping(address => uint256) private pendingWithdrawals;

    // Staking records: stakeId => Stake details
    mapping(uint256 => Stake) public stakes;
    // Mapping to quickly find stakes by user and model: stakerAddress => modelId => list of stakeIds
    mapping(address => mapping(uint256 => uint256[])) public userModelStakes;
    // Total active stake amount per model: modelId => totalStakedAmount
    mapping(uint256 => uint256) public totalStakedOnModel;

    // Reputation: modelId => reporterAddress => reported (true/false) - simple binary report
    mapping(uint256 => mapping(address => bool)) private modelReportedBy;
    mapping(uint256 => uint256) public modelReportsCount; // Total unique reports for a model

    // Reputation: modelId => raterAddress => rating (e.g., 1-5)
    mapping(uint256 => mapping(address => uint8)) private modelRatings;
    mapping(uint256 => uint256) public modelRatingsCount; // Total unique ratings for a model

    // Admin roles
    mapping(address => bool) public admins;

    // Pause functionality
    bool public paused = false;

    // --- Events ---

    event ModelRegistered(uint256 indexed modelId, address indexed creator, string name, uint256 creationTime);
    event ModelUpdated(uint256 indexed modelId, address indexed creator);
    event ModelVersionAdded(uint256 indexed modelId, uint256 indexed version, bytes32 versionHash);
    event ModelListed(uint256 indexed modelId, address indexed creator, uint256 pricePerAccess, uint256 pricePerInference);
    event ModelUnlisted(uint256 indexed modelId, address indexed creator);
    event ModelDeactivated(uint256 indexed modelId, address indexed creator);
    event ModelOwnershipTransferred(uint256 indexed modelId, address indexed oldOwner, address indexed newOwner);

    event ModelAccessPurchased(uint256 indexed modelId, address indexed buyer, uint256 pricePaid);
    event InferenceRequested(uint256 indexed modelId, address indexed requester, uint256 pricePaid);

    event EarningsWithdrawn(address indexed creator, uint256 amount);
    event FeesWithdrawn(address indexed feeCollector, uint256 amount);
    event FeeUpdated(uint256 oldFeeBasisPoints, uint256 newFeeBasisPoints);

    event ModelStaked(uint256 indexed stakeId, uint256 indexed modelId, address indexed staker, uint256 amount);
    event StakeClaimed(uint256 indexed stakeId, uint256 indexed modelId, address indexed staker, uint256 amount);

    event ModelReported(uint256 indexed modelId, address indexed reporter);
    event ModelReportResolved(uint256 indexed modelId, address indexed admin); // Marker for admin action

    event ModelRated(uint256 indexed modelId, address indexed rater, uint8 rating);

    event AdminGranted(address indexed admin);
    event AdminRevoked(address indexed admin);

    event Paused(address account);
    event Unpaused(address account);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }

    modifier onlyCreator(uint256 _modelId) {
        require(models[_modelId].creator == msg.sender, "Only model creator can call this");
        _;
    }

    modifier onlyCreatorOrAdmin(uint256 _modelId) {
        require(models[_modelId].creator == msg.sender || admins[msg.sender], "Only creator or admin");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Only admin can call this");
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

    // --- Constructor ---

    constructor(address _feeCollector, uint256 _marketplaceFeeBasisPoints) {
        owner = msg.sender;
        feeCollector = _feeCollector;
        marketplaceFeeBasisPoints = _marketplaceFeeBasisPoints;
        admins[msg.sender] = true; // Owner is also an admin initially
    }

    // --- Core Logic Functions (> 20 total planned) ---

    /**
     * @dev Registers a new AI model on the marketplace.
     * @param _name The name of the model.
     * @param _description A brief description of the model.
     * @param _baseAccessUri The base URI for accessing the model (e.g., API endpoint).
     * @param _pricePerAccess Price for full access license (set to 0 if only pay-per-inference).
     * @param _pricePerInference Price per single inference request (set to 0 if only access purchase).
     * @param _versionHash Hash of the initial version of the model.
     */
    function registerModel(
        string calldata _name,
        string calldata _description,
        string calldata _baseAccessUri,
        uint256 _pricePerAccess,
        uint256 _pricePerInference,
        bytes32 _versionHash
    ) external whenNotPaused {
        require(bytes(_name).length > 0, "Name required");
        require(bytes(_description).length > 0, "Description required");
        require(bytes(_baseAccessUri).length > 0, "Access URI required");
        require(_versionHash != bytes32(0), "Initial version hash required");
        require(_pricePerAccess > 0 || _pricePerInference > 0, "Must set a price for access or inference");

        uint256 modelId = nextModelId++;
        uint256 initialVersion = 1;

        models[modelId] = Model({
            creator: msg.sender,
            name: _name,
            description: _description,
            baseAccessUri: _baseAccessUri,
            pricePerAccess: _pricePerAccess,
            pricePerInference: _pricePerInference,
            creationTime: block.timestamp,
            latestVersion: initialVersion,
            isListed: false, // Starts unlisted
            isActive: true,
            totalAccessSold: 0,
            totalInferenceRequests: 0,
            totalRevenueGross: 0
        });

        models[modelId].versionHashes[initialVersion] = _versionHash;

        creatorModels[msg.sender].push(modelId);

        emit ModelRegistered(modelId, msg.sender, _name, block.timestamp);
        emit ModelVersionAdded(modelId, initialVersion, _versionHash);
    }

    /**
     * @dev Updates the details of an existing model.
     * @param _modelId The ID of the model to update.
     * @param _name The new name (empty string to keep current).
     * @param _description The new description (empty string to keep current).
     * @param _baseAccessUri The new base access URI (empty string to keep current).
     */
    function updateModelDetails(
        uint256 _modelId,
        string calldata _name,
        string calldata _description,
        string calldata _baseAccessUri
    ) external onlyCreator(_modelId) whenNotPaused {
        Model storage model = models[_modelId];
        require(model.creator != address(0), "Model does not exist");

        if (bytes(_name).length > 0) {
            model.name = _name;
        }
        if (bytes(_description).length > 0) {
            model.description = _description;
        }
        if (bytes(_baseAccessUri).length > 0) {
             require(bytes(_baseAccessUri).length > 0, "Access URI cannot be empty if updating");
            model.baseAccessUri = _baseAccessUri;
        }

        emit ModelUpdated(_modelId, msg.sender);
    }

    /**
     * @dev Adds a new version to an existing model.
     * @param _modelId The ID of the model.
     * @param _versionHash The hash of the new model version.
     */
    function addModelVersion(uint256 _modelId, bytes32 _versionHash)
        external onlyCreator(_modelId) whenNotPaused
    {
        Model storage model = models[_modelId];
        require(model.creator != address(0), "Model does not exist");
        require(_versionHash != bytes32(0), "Version hash required");

        uint256 newVersion = model.latestVersion + 1;
        model.versionHashes[newVersion] = _versionHash;
        model.latestVersion = newVersion;

        emit ModelVersionAdded(_modelId, newVersion, _versionHash);
    }

    /**
     * @dev Sets the price for a model and lists it on the marketplace.
     * @param _modelId The ID of the model.
     * @param _pricePerAccess Price for full access license (set to 0 if only pay-per-inference).
     * @param _pricePerInference Price per single inference request (set to 0 if only access purchase).
     */
    function listModel(uint256 _modelId, uint256 _pricePerAccess, uint256 _pricePerInference)
        external onlyCreator(_modelId) whenNotPaused
    {
        Model storage model = models[_modelId];
        require(model.creator != address(0), "Model does not exist");
        require(model.isActive, "Model is deactivated");
        require(_pricePerAccess > 0 || _pricePerInference > 0, "Must set a price for access or inference");

        model.pricePerAccess = _pricePerAccess;
        model.pricePerInference = _pricePerInference;
        model.isListed = true;

        emit ModelListed(_modelId, msg.sender, _pricePerAccess, _pricePerInference);
    }

     /**
      * @dev Unlists a model from the marketplace.
      * @param _modelId The ID of the model.
      */
    function unlistModel(uint256 _modelId)
        external onlyCreator(_modelId) whenNotPaused
    {
        Model storage model = models[_modelId];
        require(model.creator != address(0), "Model does not exist");
        require(model.isListed, "Model is not listed");

        model.isListed = false;

        emit ModelUnlisted(_modelId, msg.sender);
    }

     /**
      * @dev Deactivates a model (e.g., due to security issues, deprecation). Access/Inference requests will fail.
      * Can only be done by creator or admin.
      * @param _modelId The ID of the model.
      */
    function deactivateModel(uint256 _modelId)
        external onlyCreatorOrAdmin(_modelId) whenNotPaused
    {
        Model storage model = models[_modelId];
        require(model.creator != address(0), "Model does not exist");
        require(model.isActive, "Model is already deactivated");

        model.isActive = false;
        model.isListed = false; // Also unlist if deactivated

        emit ModelDeactivated(_modelId, msg.sender);
    }

    /**
     * @dev Transfers ownership of a model to a new address.
     * @param _modelId The ID of the model.
     * @param _newOwner The address of the new owner.
     */
    function transferModelOwnership(uint256 _modelId, address _newOwner)
        external onlyCreator(_modelId) whenNotPaused
    {
        Model storage model = models[_modelId];
        require(model.creator != address(0), "Model does not exist");
        require(_newOwner != address(0), "New owner cannot be the zero address");
        require(_newOwner != model.creator, "New owner is already the creator");

        address oldOwner = model.creator;
        model.creator = _newOwner;

        // Note: Does not automatically transfer pending withdrawals. Old creator must withdraw first.
        // Does not update creatorModels array efficiently on-chain. Off-chain indexers needed.

        emit ModelOwnershipTransferred(_modelId, oldOwner, _newOwner);
    }

    /**
     * @dev Purchases access to a model if the pricePerAccess is set (> 0).
     * Requires sending the exact `pricePerAccess` in Ether.
     * @param _modelId The ID of the model to purchase access for.
     */
    function purchaseModelAccess(uint256 _modelId) external payable whenNotPaused {
        Model storage model = models[_modelId];
        require(model.creator != address(0), "Model does not exist");
        require(model.isListed, "Model is not listed for sale");
        require(model.isActive, "Model is deactivated");
        require(model.pricePerAccess > 0, "Model not available for access purchase");
        require(msg.value == model.pricePerAccess, "Incorrect payment amount");
        require(!modelAccessMap[_modelId][msg.sender], "Access already owned");

        modelAccessMap[_modelId][msg.sender] = true;
        model.totalAccessSold++;
        model.totalRevenueGross += msg.value;

        uint256 fee = (msg.value * marketplaceFeeBasisPoints) / 10000;
        uint256 creatorRevenue = msg.value - fee;

        totalCollectedFees += fee;
        pendingWithdrawals[model.creator] += creatorRevenue;

        emit ModelAccessPurchased(_modelId, msg.sender, msg.value);
    }

    /**
     * @dev Requests an inference from a model. Requires either prior access purchase OR
     * paying the `pricePerInference` if set (> 0). Access purchase takes precedence.
     * @param _modelId The ID of the model.
     * @param _version The specific version to request inference from.
     * @param _inferenceDataHash Optional hash of the inference request data (for logging/auditing off-chain).
     */
    function requestInference(uint256 _modelId, uint256 _version, bytes32 _inferenceDataHash) external payable whenNotPaused {
        Model storage model = models[_modelId];
        require(model.creator != address(0), "Model does not exist");
        require(model.isActive, "Model is deactivated"); // Must be active to request inference
        require(_version > 0 && _version <= model.latestVersion, "Invalid model version");
        require(model.versionHashes[_version] != bytes32(0), "Model version hash not found");

        bool hasAccess = modelAccessMap[_modelId][msg.sender];
        uint256 paymentRequired = 0;

        if (!hasAccess) {
            require(model.pricePerInference > 0, "Model requires access purchase or pay-per-inference");
            paymentRequired = model.pricePerInference;
            require(msg.value >= paymentRequired, "Insufficient payment for inference");
             // Refund excess if any (using low-level call for safety)
            if (msg.value > paymentRequired) {
                (bool success, ) = payable(msg.sender).call{value: msg.value - paymentRequired}("");
                require(success, "Refund failed");
            }
        } else {
             require(msg.value == 0, "No payment expected if access is owned");
        }

        model.totalInferenceRequests++;
        model.totalRevenueGross += paymentRequired; // Adds 0 if access owned

        if (paymentRequired > 0) {
            uint256 fee = (paymentRequired * marketplaceFeeBasisPoints) / 10000;
            uint256 creatorRevenue = paymentRequired - fee;
            totalCollectedFees += fee;
            pendingWithdrawals[model.creator] += creatorRevenue;
        }

        // Note: The actual inference happens off-chain. This function records the request/payment.
        // The off-chain system would check `checkModelAccess` or listen for `InferenceRequested` event.

        emit InferenceRequested(_modelId, msg.sender, paymentRequired);
        // Optionally emit _inferenceDataHash in the event if desired
    }

    /**
     * @dev Checks if a user has purchased access to a model.
     * @param _modelId The ID of the model.
     * @param _user The address of the user.
     * @return bool True if the user has access.
     */
    function checkModelAccess(uint256 _modelId, address _user) external view returns (bool) {
        require(models[_modelId].creator != address(0), "Model does not exist");
        return modelAccessMap[_modelId][_user];
    }

    // Note: checkInferenceAllowance is implicitly handled by the requestInference function's logic.

    /**
     * @dev Allows a model creator to withdraw their pending earnings.
     */
    function withdrawEarnings() external whenNotPaused {
        uint256 amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "No pending withdrawals");

        pendingWithdrawals[msg.sender] = 0; // Clear balance before sending

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdrawal failed");

        emit EarningsWithdrawn(msg.sender, amount);
    }

    /**
     * @dev Allows the fee collector to withdraw accumulated marketplace fees.
     */
    function withdrawFees() external whenNotPaused {
        require(msg.sender == feeCollector, "Only fee collector can withdraw fees");
        uint256 amount = totalCollectedFees;
        require(amount > 0, "No fees to withdraw");

        totalCollectedFees = 0; // Clear balance before sending

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Fee withdrawal failed");

        emit FeesWithdrawn(msg.sender, amount);
    }

    /**
     * @dev Stakes Ether on a specific model, potentially boosting its visibility or signaling trust.
     * The stake amount is locked for a period (not enforced on-chain in this version, but implies off-chain cool-down).
     * @param _modelId The ID of the model to stake on.
     */
    function stakeOnModel(uint256 _modelId) external payable whenNotPaused {
        require(msg.value > 0, "Stake amount must be greater than 0");
        Model storage model = models[_modelId];
        require(model.creator != address(0), "Model does not exist");
        require(model.isActive, "Cannot stake on deactivated model");

        uint256 stakeId = nextStakeId++;

        stakes[stakeId] = Stake({
            staker: msg.sender,
            amount: msg.value,
            startTime: block.timestamp,
            modelId: _modelId,
            active: true
        });

        userModelStakes[msg.sender][_modelId].push(stakeId);
        totalStakedOnModel[_modelId] += msg.value;

        emit ModelStaked(stakeId, _modelId, msg.sender, msg.value);
    }

    /**
     * @dev Allows a user to claim their staked Ether back.
     * (In a real system, this might have a required cool-down period enforced off-chain or with a state change).
     * @param _stakeId The ID of the stake to claim.
     */
    function claimStake(uint256 _stakeId) external whenNotPaused {
        Stake storage stake = stakes[_stakeId];
        require(stake.staker != address(0), "Stake does not exist");
        require(stake.staker == msg.sender, "Only stake owner can claim");
        require(stake.active, "Stake already claimed");

        stake.active = false;
        totalStakedOnModel[stake.modelId] -= stake.amount; // Deduct from total staked

        uint256 amount = stake.amount;
        stake.amount = 0; // Set amount to 0 after marking inactive

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Stake claim failed");

        emit StakeClaimed(_stakeId, stake.modelId, msg.sender, amount);
    }

     /**
      * @dev Allows a user to report a model, potentially for malicious content, non-functionality, etc.
      * This is a simple on-chain marker; actual moderation is off-chain.
      * @param _modelId The ID of the model to report.
      */
    function reportModel(uint256 _modelId) external whenNotPaused {
        require(models[_modelId].creator != address(0), "Model does not exist");
        require(!modelReportedBy[_modelId][msg.sender], "Already reported by this user");

        modelReportedBy[_modelId][msg.sender] = true;
        modelReportsCount[_modelId]++;

        emit ModelReported(_modelId, msg.sender);
    }

     /**
      * @dev Admin action to mark a report for a model as resolved off-chain.
      * Does not clear individual user reports, just provides an on-chain marker.
      * @param _modelId The ID of the model whose reports are resolved.
      */
    function resolveModelReport(uint256 _modelId) external onlyAdmin whenNotPaused {
        require(models[_modelId].creator != address(0), "Model does not exist");
        // Note: This doesn't reset modelReportsCount or individual reports.
        // It's merely an event marker that an admin took action.
        emit ModelReportResolved(_modelId, msg.sender);
    }

    /**
     * @dev Allows a user to rate a model (e.g., out of 5).
     * @param _modelId The ID of the model to rate.
     * @param _rating The rating value (e.g., 1-5).
     */
    function rateModel(uint256 _modelId, uint8 _rating) external whenNotPaused {
        require(models[_modelId].creator != address(0), "Model does not exist");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");

        // Prevent rating your own model
        require(models[_modelId].creator != msg.sender, "Cannot rate your own model");

        // Check if user has interacted with the model (e.g., purchased access or requested inference)
        // This is a basic check to prevent spam ratings. Can be removed or modified.
        // require(modelAccessMap[_modelId][msg.sender] || models[_modelId].totalInferenceRequests > 0, "Must interact with model to rate"); // Simplified: just require interaction

        // Simplified check: require access *or* >=1 inference requests by *this user* (hard to track user inference requests)
        // Let's just require access purchase for simplicity to avoid tracking per-user inference counts
        require(modelAccessMap[_modelId][msg.sender], "Must purchase access to rate model");


        // Overwrite previous rating if exists
        if (modelRatings[_modelId][msg.sender] == 0) {
             modelRatingsCount[_modelId]++;
        }
        modelRatings[_modelId][msg.sender] = _rating;

        emit ModelRated(_modelId, msg.sender, _rating);
    }

    /**
     * @dev Sets the marketplace fee percentage.
     * @param _marketplaceFeeBasisPoints The new fee in basis points (0-10000).
     */
    function setMarketplaceFee(uint256 _marketplaceFeeBasisPoints) external onlyOwner whenNotPaused {
        require(_marketplaceFeeBasisPoints <= 10000, "Fee cannot exceed 100%");
        uint256 oldFee = marketplaceFeeBasisPoints;
        marketplaceFeeBasisPoints = _marketplaceFeeBasisPoints;
        emit FeeUpdated(oldFee, _marketplaceFeeBasisPoints);
    }

    /**
     * @dev Grants admin role to an address.
     * Admins can deactivate models and mark reports as resolved.
     * @param _admin The address to grant admin role to.
     */
    function grantAdminRole(address _admin) external onlyOwner {
        require(_admin != address(0), "Admin address cannot be zero");
        require(!admins[_admin], "Address is already an admin");
        admins[_admin] = true;
        emit AdminGranted(_admin);
    }

    /**
     * @dev Revokes admin role from an address.
     * @param _admin The address to revoke admin role from.
     */
    function revokeAdminRole(address _admin) external onlyOwner {
        require(_admin != address(0), "Admin address cannot be zero");
        require(admins[_admin], "Address is not an admin");
        require(_admin != msg.sender, "Cannot revoke your own admin role"); // Owner cannot revoke own role
        admins[_admin] = false;
        emit AdminRevoked(_admin);
    }


    /**
     * @dev Pauses the contract, preventing most state-changing operations.
     */
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses the contract, allowing state-changing operations again.
     */
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    // --- View Functions (> 20 total planned - counting the core ones + views) ---

    /**
     * @dev Gets the details of a model.
     * @param _modelId The ID of the model.
     * @return tuple Model details.
     */
    function getModelDetails(uint256 _modelId)
        external view
        returns (
            address creator,
            string memory name,
            string memory description,
            string memory baseAccessUri,
            uint256 pricePerAccess,
            uint256 pricePerInference,
            uint256 creationTime,
            uint256 latestVersion,
            bool isListed,
            bool isActive,
            uint256 totalAccessSold,
            uint256 totalInferenceRequests,
            uint256 totalRevenueGross
        )
    {
        Model storage model = models[_modelId];
        require(model.creator != address(0), "Model does not exist");
        return (
            model.creator,
            model.name,
            model.description,
            model.baseAccessUri,
            model.pricePerAccess,
            model.pricePerInference,
            model.creationTime,
            model.latestVersion,
            model.isListed,
            model.isActive,
            model.totalAccessSold,
            model.totalInferenceRequests,
            model.totalRevenueGross
        );
    }

    /**
     * @dev Gets the version hash for a specific model version.
     * @param _modelId The ID of the model.
     * @param _version The version number.
     * @return bytes32 The hash of the model version.
     */
    function getModelVersionHash(uint256 _modelId, uint256 _version)
        external view
        returns (bytes32)
    {
        Model storage model = models[_modelId];
        require(model.creator != address(0), "Model does not exist");
        require(_version > 0 && _version <= model.latestVersion, "Invalid version number");
        return model.versionHashes[_version];
    }

    /**
     * @dev Gets the total number of registered models.
     * @return uint256 The total count of models.
     */
    function getModelCount() external view returns (uint256) {
        return nextModelId - 1;
    }

     /**
      * @dev Gets the list of model IDs created by a specific address.
      * Note: This array is append-only. Removing models or changing ownership
      * does not modify this array for gas efficiency. Off-chain indexers are
      * recommended for accurate lists.
      * @param _creator The address of the creator.
      * @return uint256[] An array of model IDs.
      */
    function getCreatorModels(address _creator) external view returns (uint256[] memory) {
        return creatorModels[_creator];
    }

     /**
      * @dev Gets the details of a specific stake.
      * @param _stakeId The ID of the stake.
      * @return tuple Stake details.
      */
    function getStakeDetails(uint256 _stakeId)
        external view
        returns (
            address staker,
            uint256 amount,
            uint256 startTime,
            uint256 modelId,
            bool active
        )
    {
        Stake storage stake = stakes[_stakeId];
         require(stake.staker != address(0), "Stake does not exist");
        return (stake.staker, stake.amount, stake.startTime, stake.modelId, stake.active);
    }

    /**
     * @dev Gets the total active staked amount on a specific model.
     * @param _modelId The ID of the model.
     * @return uint256 Total staked amount.
     */
    function getTotalStakedOnModel(uint256 _modelId) external view returns (uint256) {
        require(models[_modelId].creator != address(0), "Model does not exist");
        return totalStakedOnModel[_modelId];
    }

     /**
      * @dev Gets the number of unique reports for a model.
      * @param _modelId The ID of the model.
      * @return uint256 The count of unique reports.
      */
    function getReportCount(uint256 _modelId) external view returns (uint256) {
        require(models[_modelId].creator != address(0), "Model does not exist");
        return modelReportsCount[_modelId];
    }

     /**
      * @dev Gets a user's specific rating for a model. Returns 0 if no rating exists.
      * @param _modelId The ID of the model.
      * @param _user The address of the user.
      * @return uint8 The rating (1-5) or 0 if no rating.
      */
    function getUserRating(uint256 _modelId, address _user) external view returns (uint8) {
        require(models[_modelId].creator != address(0), "Model does not exist");
        return modelRatings[_modelId][_user];
    }

     /**
      * @dev Gets the total number of unique ratings for a model.
      * @param _modelId The ID of the model.
      * @return uint256 The count of unique ratings.
      */
     function getModelRatingsCount(uint256 _modelId) external view returns (uint256) {
         require(models[_modelId].creator != address(0), "Model does not exist");
         return modelRatingsCount[_modelId];
     }

    /**
     * @dev Gets the current marketplace fee in basis points.
     * @return uint256 Fee in basis points.
     */
    function getMarketplaceFeeBasisPoints() external view returns (uint256) {
        return marketplaceFeeBasisPoints;
    }

    /**
     * @dev Checks if the contract is currently paused.
     * @return bool True if paused, false otherwise.
     */
    function isPaused() external view returns (bool) {
        return paused;
    }

    /**
     * @dev Checks if an address has the admin role.
     * @param _addr The address to check.
     * @return bool True if the address is an admin.
     */
    function isAdmin(address _addr) external view returns (bool) {
        return admins[_addr];
    }

     /**
      * @dev Gets the amount of pending withdrawals for a creator.
      * @param _creator The address of the creator.
      * @return uint256 The amount of pending Ether.
      */
    function getPendingWithdrawals(address _creator) external view returns (uint256) {
        return pendingWithdrawals[_creator];
    }

    /**
     * @dev Gets the total fees collected by the marketplace owner/fee collector.
     * @return uint256 The total collected fees.
     */
    function getTotalCollectedFees() external view returns (uint256) {
        return totalCollectedFees;
    }

    // Need a few more functions to reach 20, let's add some utility/view functions:

    /**
     * @dev Checks if a user has reported a specific model.
     * @param _modelId The ID of the model.
     * @param _user The address of the user.
     * @return bool True if the user has reported the model.
     */
    function hasUserReportedModel(uint256 _modelId, address _user) external view returns (bool) {
        require(models[_modelId].creator != address(0), "Model does not exist");
        return modelReportedBy[_modelId][_user];
    }

    /**
     * @dev Gets the list of stake IDs associated with a user and a model.
     * @param _staker The address of the staker.
     * @param _modelId The ID of the model.
     * @return uint256[] An array of stake IDs.
     */
    function getUserStakeIdsForModel(address _staker, uint256 _modelId) external view returns (uint256[] memory) {
        require(models[_modelId].creator != address(0), "Model does not exist");
        return userModelStakes[_staker][_modelId];
    }

    /**
     * @dev Gets the creator's address for a specific model ID.
     * @param _modelId The ID of the model.
     * @return address The creator's address.
     */
    function getModelCreator(uint256 _modelId) external view returns (address) {
         require(models[_modelId].creator != address(0), "Model does not exist");
        return models[_modelId].creator;
    }

    // Let's recount the functions now:
    // 1. registerModel
    // 2. updateModelDetails
    // 3. addModelVersion
    // 4. listModel
    // 5. unlistModel
    // 6. deactivateModel
    // 7. transferModelOwnership
    // 8. purchaseModelAccess (payable)
    // 9. requestInference (payable)
    // 10. withdrawEarnings
    // 11. withdrawFees
    // 12. stakeOnModel (payable)
    // 13. claimStake
    // 14. reportModel
    // 15. resolveModelReport
    // 16. rateModel
    // 17. setMarketplaceFee
    // 18. grantAdminRole
    // 19. revokeAdminRole
    // 20. pauseContract
    // 21. unpauseContract
    // 22. getModelDetails (view)
    // 23. getModelVersionHash (view)
    // 24. getModelCount (view)
    // 25. getCreatorModels (view)
    // 26. getStakeDetails (view)
    // 27. getTotalStakedOnModel (view)
    // 28. getReportCount (view)
    // 29. getUserRating (view)
    // 30. getModelRatingsCount (view)
    // 31. getMarketplaceFeeBasisPoints (view)
    // 32. isPaused (view)
    // 33. isAdmin (view)
    // 34. getPendingWithdrawals (view)
    // 35. getTotalCollectedFees (view)
    // 36. checkModelAccess (view)
    // 37. hasUserReportedModel (view)
    // 38. getUserStakeIdsForModel (view)
    // 39. getModelCreator (view)

    // Okay, that's 39 functions, well over the 20 requirement.

}
```