```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For arithmetic, although Solidity 0.8+ has built-in checks
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol"; // Useful for managing sets of IDs, e.g. active models/verifiers.

/**
 * @title AetherMind Collective
 * @dev A decentralized autonomous collective for AI model training and verification.
 *      This contract facilitates the submission of AI models, contribution of data,
 *      decentralized verification of model performance, and a reputation-based
 *      reward system for participants. It introduces concepts like collateralized
 *      model submissions, stake-based verification, challenge mechanisms, and
 *      dynamic participant reputation, aiming for a truly decentralized AI development ecosystem.
 *
 *      This contract integrates several advanced concepts:
 *      -   **Collateralized Submissions/Staking:** Participants stake tokens to ensure honest behavior.
 *      -   **Decentralized Verification Market:** Verifiers compete to verify models.
 *      -   **Challenge Mechanism:** Peer-to-peer challenging of verification results, resolved by an authorized role.
 *      -   **Reputation System:** Participants gain/lose reputation based on their performance and honesty.
 *      -   **Role-Based Access Control:** Differentiated permissions for various administrative and operational tasks.
 *      -   **Pausable Functionality:** Emergency halt mechanism.
 *      -   **IPFS Integration (via CIDs):** References off-chain data and models without storing them on-chain directly.
 *      -   **Dynamic Parameters:** Adjustable minimum stakes and time periods by governance.
 *
 * @outline
 * 1.  **Core Infrastructure & Access Control:**
 *     -   Initial setup, token deposits/withdrawals, and role-based access management using OpenZeppelin's `AccessControl` and `Pausable` patterns.
 *     -   Defines `ADMIN_ROLE` for system-wide configuration and `RESOLVER_ROLE` for dispute resolution.
 * 2.  **AI Model Management:**
 *     -   Functions for submitting new AI models with a required collateral, updating their associated metadata (IPFS CIDs),
 *         and managing the release or slashing of this collateral based on the outcome of the verification process.
 * 3.  **Data Source & Contribution:**
 *     -   Manages the registration of unique data sources and the process of linking specific data contributions (referenced by IPFS CIDs)
 *         to AI models, including the ability for data sources to revoke their contributions.
 * 4.  **Decentralized Verification & Challenge System:**
 *     -   Implements a robust, stake-based system for verifiers to register, propose verification tasks for models,
 *         submit their performance results (e.g., accuracy scores and detailed reports), and challenge other verifiers' results.
 *     -   Includes a mechanism for `RESOLVER_ROLE` to adjudicate challenges and distribute stakes/rewards accordingly.
 * 5.  **Reputation & Dynamic Parameters:**
 *     -   Tracks a reputation score for each participant, which can be implicitly updated by system actions (e.g., successful verification, failed challenge)
 *         or explicitly adjusted by `ADMIN_ROLE`.
 *     -   Provides methods to query individual reputation, aggregate collective statistics, and set critical operational parameters (like minimum stakes and timeframes).
 *
 * @function_summary (Total 28 Functions)
 *
 *   **I. Core Infrastructure & Access Control (8 Functions)**
 *   -   `constructor(address _collectiveToken)`: Initializes the contract, sets the ERC20 collective token, and assigns initial roles.
 *   -   `deposit(uint256 amount)`: Allows users to deposit the `_collectiveToken` into their internal contract balance.
 *   -   `withdraw(uint256 amount)`: Allows users to withdraw their available `_collectiveToken` balance.
 *   -   `grantRole(bytes32 role, address account)`: Grants a specified role to an `account` (requires `DEFAULT_ADMIN_ROLE`).
 *   -   `revokeRole(bytes32 role, address account)`: Revokes a specified role from an `account` (requires `DEFAULT_ADMIN_ROLE`).
 *   -   `renounceRole(bytes32 role)`: Allows an `account` to remove a specified role from themselves.
 *   -   `pause()`: Pauses core contract functionalities, restricting sensitive actions (requires `DEFAULT_ADMIN_ROLE`).
 *   -   `unpause()`: Unpauses the contract, re-enabling restricted actions (requires `DEFAULT_ADMIN_ROLE`).
 *
 *   **II. AI Model Management (5 Functions)**
 *   -   `submitModel(string calldata modelCID, string calldata descriptionCID, uint256 requiredCollateral)`: Submits a new AI model with associated CIDs and required collateral. Returns a unique `modelId`.
 *   -   `updateModelMetadata(bytes32 modelId, string calldata newModelCID, string calldata newDescriptionCID)`: Allows the model owner to update the IPFS CIDs of an existing model.
 *   -   `releaseModelCollateral(bytes32 modelId)`: Releases the collateral to the model owner if the model is successfully verified and approved.
 *   -   `slashModelCollateral(bytes32 modelId)`: Slashes the collateral (transfers to treasury) for a failed or malicious model (requires `RESOLVER_ROLE`).
 *   -   `getModelInfo(bytes32 modelId)`: Public view function to retrieve comprehensive details about an AI model.
 *
 *   **III. Data Source & Contribution (4 Functions)**
 *   -   `registerDataSource(string calldata dataSourceCID, string calldata descriptionCID)`: Registers a new data source with its associated CIDs. Returns a unique `dataSourceId`.
 *   -   `linkDataToModel(bytes32 modelId, bytes32 dataSourceId, string calldata dataContributionCID)`: Associates a specific data contribution (its IPFS hash) from a registered data source with a model. Returns a unique `dataLinkId`.
 *   -   `revokeDataLink(bytes32 dataLinkId)`: Allows a data source to revoke a previously linked data contribution.
 *   -   `getDataSourceInfo(bytes32 dataSourceId)`: Public view function to retrieve details about a registered data source.
 *
 *   **IV. Decentralized Verification & Challenge System (7 Functions)**
 *   -   `registerVerifier(string calldata verifierProfileCID, uint256 initialStake)`: Registers a new verifier with an initial token stake and a profile CID. Returns a unique `verifierId`.
 *   -   `proposeVerificationTask(bytes32 modelId, uint256 taskStake)`: A registered verifier proposes to verify a specific model, staking for the task. Returns a unique `verificationTaskId`.
 *   -   `submitVerificationResult(bytes32 verificationTaskId, uint256 accuracyScore, string calldata reportCID)`: The assigned verifier submits the verification outcome, including an accuracy score and a detailed report's IPFS hash.
 *   -   `challengeVerificationResult(bytes32 verificationTaskId, string calldata challengeReportCID, uint256 challengeStake)`: Any registered verifier can challenge a submitted result, staking and providing a counter-report CID.
 *   -   `resolveChallenge(bytes32 verificationTaskId, bool challengerWins)`: A `RESOLVER_ROLE` determines the outcome of a challenge, triggering stake distribution/slashing and reputation updates.
 *   -   `claimVerificationRewards(bytes32 verificationTaskId)`: A verifier claims their stake and rewards for a successfully completed and unchallenged verification task.
 *   -   `getVerificationTaskInfo(bytes32 verificationTaskId)`: Public view function to retrieve details about a specific verification task.
 *
 *   **V. Reputation & Dynamic Parameters (4 Functions)**
 *   -   `getReputationScore(address participant)`: Public view function to check a participant's current reputation score.
 *   -   `adjustReputation(address participant, int256 scoreChange)`: Manually adjusts a participant's reputation score (requires `ADMIN_ROLE` or `RESOLVER_ROLE`).
 *   -   `setMinimumStakes(uint256 minModelCollateral, uint256 minVerifierStake, uint256 minTaskStake, uint256 minChallengeStake)`: Sets various minimum stake requirements for participation (requires `ADMIN_ROLE`).
 *   -   `getCollectiveMetrics()`: Public view function returning aggregated statistics and current parameters of the collective.
 */
contract AetherMindCollective is AccessControl, Pausable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;

    // --- Roles ---
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant RESOLVER_ROLE = keccak256("RESOLVER_ROLE"); // For resolving challenges, potentially by a DAO or trusted oracle

    // --- Collective Token ---
    IERC20 public immutable collectiveToken;
    mapping(address => uint256) public balances; // Internal balance tracking for deposits/withdrawals

    // --- Configuration Parameters ---
    uint256 public minModelCollateral;
    uint256 public minVerifierStake;
    uint256 public minTaskStake;
    uint256 public minChallengeStake;
    uint256 public verificationPeriod; // Time allowed for verification in seconds
    uint256 public challengePeriod;    // Time allowed for challenges in seconds
    uint256 public challengeResolutionPeriod; // Time for resolver to act

    // --- Reputation System ---
    mapping(address => int256) public reputationScores; // Initialized to 0

    // --- AI Models ---
    struct Model {
        bytes32 modelId;
        address owner;
        string modelCID; // IPFS CID for the model itself
        string descriptionCID; // IPFS CID for model description/metadata
        uint256 collateralAmount;
        uint256 submittedAt;
        ModelStatus status;
        address currentVerifier; // Who is currently verifying it
        bytes32 currentVerificationTaskId; // The ID of the active verification task
        bytes32 approvedDataSourceLink; // ID of the data link used for approval (if any)
    }

    enum ModelStatus {
        Submitted,
        UnderVerification,
        Verified,
        Failed,
        Challenged,
        CollateralReleased,
        CollateralSlashed
    }
    mapping(bytes32 => Model) public models;
    EnumerableSet.Bytes32Set private _allModelIds; // To keep track of all models

    // --- Data Sources ---
    struct DataSource {
        bytes32 dataSourceId;
        address owner;
        string dataSourceCID; // IPFS CID for the dataset itself
        string descriptionCID; // IPFS CID for dataset description/metadata
        uint256 registeredAt;
    }
    mapping(bytes32 => DataSource) public dataSources;
    EnumerableSet.Bytes32Set private _allDataSourceIds;

    // --- Data Links (Linking specific data contributions to a model) ---
    struct DataLink {
        bytes32 dataLinkId;
        bytes32 modelId;
        bytes32 dataSourceId;
        address contributor;
        string dataContributionCID; // IPFS CID of the specific data slice used for the model
        uint256 linkedAt;
        bool revoked;
    }
    mapping(bytes32 => DataLink) public dataLinks;
    EnumerableSet.Bytes32Set private _allDataLinkIds;

    // --- Verifiers ---
    struct Verifier {
        bytes32 verifierId;
        address account;
        string verifierProfileCID; // IPFS CID for verifier's profile/credentials
        uint256 initialStake; // Initial stake when registering as a verifier
        bool isActive;
        EnumerableSet.Bytes32Set activeVerificationTasks; // Tasks currently undertaken by this verifier
    }
    mapping(bytes32 => Verifier) public verifiers;
    mapping(address => bytes32) public addressToVerifierId; // Map address to verifierId
    EnumerableSet.Bytes32Set private _allVerifierIds;

    // --- Verification Tasks ---
    struct VerificationTask {
        bytes32 verificationTaskId;
        bytes32 modelId;
        bytes32 verifierId;
        address verifierAddress;
        uint256 taskStake;
        uint256 proposedAt;
        uint256 completedAt; // Timestamp when result was submitted
        uint256 accuracyScore; // Score submitted by verifier (e.g., 0-10000 for 0-100%)
        string reportCID; // IPFS CID for the verification report
        VerificationTaskStatus status;
        address challenger; // Who challenged this task
        uint256 challengeStake;
        string challengeReportCID; // IPFS CID for the challenge report
        uint256 challengedAt;
        uint256 resolvedAt;
        bool challengerWon; // True if challenger won, false if original verifier won
    }

    enum VerificationTaskStatus {
        Proposed,
        InProgress,
        ResultSubmitted,
        Challenged,
        ResolvedSuccess, // Original verifier won challenge or no challenge
        ResolvedFailure // Challenger won challenge
    }
    mapping(bytes32 => VerificationTask) public verificationTasks;
    EnumerableSet.Bytes32Set private _allVerificationTaskIds;

    // --- Events ---
    event TokensDeposited(address indexed user, uint256 amount);
    event TokensWithdrawn(address indexed user, uint256 amount);
    event ModelSubmitted(bytes32 indexed modelId, address indexed owner, string modelCID, uint256 collateralAmount);
    event ModelMetadataUpdated(bytes32 indexed modelId, string newModelCID, string newDescriptionCID);
    event ModelCollateralReleased(bytes32 indexed modelId, address indexed owner, uint256 amount);
    event ModelCollateralSlashed(bytes32 indexed modelId, address indexed owner, uint256 amount);
    event DataSourceRegistered(bytes32 indexed dataSourceId, address indexed owner, string dataSourceCID);
    event DataLinkedToModel(bytes32 indexed dataLinkId, bytes32 indexed modelId, bytes32 indexed dataSourceId, string dataContributionCID);
    event DataLinkRevoked(bytes32 indexed dataLinkId);
    event VerifierRegistered(bytes32 indexed verifierId, address indexed account, uint256 initialStake);
    event VerificationTaskProposed(bytes32 indexed verificationTaskId, bytes32 indexed modelId, bytes32 indexed verifierId, uint256 taskStake);
    event VerificationResultSubmitted(bytes32 indexed verificationTaskId, uint256 accuracyScore, string reportCID);
    event VerificationResultChallenged(bytes32 indexed verificationTaskId, address indexed challenger, uint256 challengeStake);
    event ChallengeResolved(bytes32 indexed verificationTaskId, bool challengerWon);
    event VerificationRewardsClaimed(bytes32 indexed verificationTaskId, address indexed verifier, uint256 rewardsAmount);
    event ReputationAdjusted(address indexed participant, int256 change, int256 newScore);
    event MinimumStakesSet(uint256 minModelCollateral, uint256 minVerifierStake, uint256 minTaskStake, uint256 minChallengeStake);


    constructor(address _collectiveToken) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender); // Grant ADMIN_ROLE to deployer
        _grantRole(RESOLVER_ROLE, msg.sender); // Grant RESOLVER_ROLE to deployer

        collectiveToken = IERC20(_collectiveToken);

        // Set initial minimums and periods (can be changed by ADMIN_ROLE)
        minModelCollateral = 100 ether;
        minVerifierStake = 50 ether;
        minTaskStake = 20 ether;
        minChallengeStake = 30 ether;
        verificationPeriod = 7 days; // 7 days for verifiers to submit results
        challengePeriod = 3 days;    // 3 days to challenge a result
        challengeResolutionPeriod = 7 days; // 7 days for resolver to act
    }

    // --- I. Core Infrastructure & Access Control ---

    /**
     * @dev Allows users to deposit the collective token into their internal contract balance.
     *      Tokens are transferred from the user's wallet to the contract's balance.
     * @param amount The amount of tokens to deposit.
     */
    function deposit(uint256 amount) external whenNotPaused {
        require(amount > 0, "Deposit amount must be > 0");
        require(collectiveToken.transferFrom(msg.sender, address(this), amount), "Token transfer failed");
        balances[msg.sender] = balances[msg.sender].add(amount);
        emit TokensDeposited(msg.sender, amount);
    }

    /**
     * @dev Allows users to withdraw their available collective token balance from the contract.
     * @param amount The amount of tokens to withdraw.
     */
    function withdraw(uint256 amount) external whenNotPaused {
        require(amount > 0, "Withdraw amount must be > 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] = balances[msg.sender].sub(amount);
        require(collectiveToken.transfer(msg.sender, amount), "Token transfer failed");
        emit TokensWithdrawn(msg.sender, amount);
    }

    /**
     * @dev Grants a specified role to an account.
     *      Requires `DEFAULT_ADMIN_ROLE`.
     * @param role The bytes32 hash of the role to grant.
     * @param account The address to grant the role to.
     */
    function grantRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes a specified role from an account.
     *      Requires `DEFAULT_ADMIN_ROLE`.
     * @param role The bytes32 hash of the role to revoke.
     * @param account The address to revoke the role from.
     */
    function revokeRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(role, account);
    }

    /**
     * @dev Allows an account to remove a specified role from themselves.
     * @param role The bytes32 hash of the role to renounce.
     */
    function renounceRole(bytes32 role) public override {
        _renounceRole(role);
    }

    /**
     * @dev Pauses core contract functionalities, restricting sensitive actions.
     *      Can only be called by an account with `DEFAULT_ADMIN_ROLE`.
     */
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev Unpauses the contract, re-enabling restricted actions.
     *      Can only be called by an account with `DEFAULT_ADMIN_ROLE`.
     */
    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    // --- II. AI Model Management ---

    /**
     * @dev Submits a new AI model to the collective for verification.
     *      Requires the model owner to stake `requiredCollateral`.
     * @param modelCID IPFS Content Identifier for the AI model's code/artifacts.
     * @param descriptionCID IPFS Content Identifier for the model's description or whitepaper.
     * @param requiredCollateral The amount of tokens to stake as collateral for the model.
     * @return modelId The unique identifier for the submitted model.
     */
    function submitModel(
        string calldata modelCID,
        string calldata descriptionCID,
        uint256 requiredCollateral
    ) external whenNotPaused returns (bytes32 modelId) {
        require(requiredCollateral >= minModelCollateral, "Collateral below minimum");
        require(balances[msg.sender] >= requiredCollateral, "Insufficient balance for collateral");

        modelId = keccak256(abi.encodePacked(block.timestamp, msg.sender, modelCID));
        require(!_allModelIds.contains(modelId), "Model already exists");

        balances[msg.sender] = balances[msg.sender].sub(requiredCollateral);

        models[modelId] = Model({
            modelId: modelId,
            owner: msg.sender,
            modelCID: modelCID,
            descriptionCID: descriptionCID,
            collateralAmount: requiredCollateral,
            submittedAt: block.timestamp,
            status: ModelStatus.Submitted,
            currentVerifier: address(0),
            currentVerificationTaskId: bytes32(0),
            approvedDataSourceLink: bytes32(0)
        });
        _allModelIds.add(modelId);
        emit ModelSubmitted(modelId, msg.sender, modelCID, requiredCollateral);
    }

    /**
     * @dev Allows the model owner to update the IPFS CIDs of an existing model.
     *      Only possible if the model is still in `Submitted` status.
     * @param modelId The ID of the model to update.
     * @param newModelCID The new IPFS CID for the model.
     * @param newDescriptionCID The new IPFS CID for the model description.
     */
    function updateModelMetadata(
        bytes32 modelId,
        string calldata newModelCID,
        string calldata newDescriptionCID
    ) external whenNotPaused {
        Model storage model = models[modelId];
        require(model.owner == msg.sender, "Not model owner");
        require(model.status == ModelStatus.Submitted, "Model not in updatable status");

        model.modelCID = newModelCID;
        model.descriptionCID = newDescriptionCID;
        emit ModelMetadataUpdated(modelId, newModelCID, newDescriptionCID);
    }

    /**
     * @dev Releases the collateral to the model owner if the model is successfully verified and approved.
     * @param modelId The ID of the model for which to release collateral.
     */
    function releaseModelCollateral(bytes32 modelId) external whenNotPaused {
        Model storage model = models[modelId];
        require(model.owner == msg.sender, "Not model owner");
        require(
            model.status == ModelStatus.Verified,
            "Model not in verified status"
        );
        require(model.collateralAmount > 0, "No collateral to release");

        uint256 amount = model.collateralAmount;
        model.collateralAmount = 0; // Prevent double-release
        model.status = ModelStatus.CollateralReleased;
        balances[msg.sender] = balances[msg.sender].add(amount);

        emit ModelCollateralReleased(modelId, msg.sender, amount);
    }

    /**
     * @dev Slashes the collateral (transfers to treasury/community pool) for a failed or malicious model.
     *      Can only be called by an account with `RESOLVER_ROLE`.
     * @param modelId The ID of the model whose collateral should be slashed.
     */
    function slashModelCollateral(bytes32 modelId) external whenNotPaused onlyRole(RESOLVER_ROLE) {
        Model storage model = models[modelId];
        require(
            model.status == ModelStatus.Failed || model.status == ModelStatus.CollateralSlashed,
            "Model not in a slashable status (Failed)"
        );
        require(model.collateralAmount > 0, "No collateral to slash");

        uint256 amount = model.collateralAmount;
        model.collateralAmount = 0; // Prevent double-slashing
        model.status = ModelStatus.CollateralSlashed;
        // Collateral is added to the general collective balance, can be later distributed via governance
        // For simplicity, we add it to the contract's internal balance. A more complex system might have a separate treasury.
        balances[address(this)] = balances[address(this)].add(amount);

        emit ModelCollateralSlashed(modelId, model.owner, amount);
    }

    /**
     * @dev Public view function to retrieve comprehensive details about an AI model.
     * @param modelId The unique identifier of the model.
     * @return Model struct containing all model details.
     */
    function getModelInfo(bytes32 modelId) external view returns (Model memory) {
        require(_allModelIds.contains(modelId), "Model does not exist");
        return models[modelId];
    }

    // --- III. Data Source & Contribution ---

    /**
     * @dev Registers a new data source with its associated CIDs.
     * @param dataSourceCID IPFS Content Identifier for the raw dataset or dataset gateway.
     * @param descriptionCID IPFS Content Identifier for the dataset's description/metadata.
     * @return dataSourceId The unique identifier for the registered data source.
     */
    function registerDataSource(
        string calldata dataSourceCID,
        string calldata descriptionCID
    ) external whenNotPaused returns (bytes32 dataSourceId) {
        dataSourceId = keccak256(abi.encodePacked(block.timestamp, msg.sender, dataSourceCID));
        require(!_allDataSourceIds.contains(dataSourceId), "Data source already registered");

        dataSources[dataSourceId] = DataSource({
            dataSourceId: dataSourceId,
            owner: msg.sender,
            dataSourceCID: dataSourceCID,
            descriptionCID: descriptionCID,
            registeredAt: block.timestamp
        });
        _allDataSourceIds.add(dataSourceId);
        emit DataSourceRegistered(dataSourceId, msg.sender, dataSourceCID);
    }

    /**
     * @dev Associates a specific data contribution (its IPFS hash) from a registered data source with a model.
     *      The `dataSourceId` must be owned by `msg.sender`.
     * @param modelId The ID of the model to link data to.
     * @param dataSourceId The ID of the registered data source.
     * @param dataContributionCID IPFS Content Identifier for the specific data slice used for the model.
     * @return dataLinkId The unique identifier for this data link.
     */
    function linkDataToModel(
        bytes32 modelId,
        bytes32 dataSourceId,
        string calldata dataContributionCID
    ) external whenNotPaused returns (bytes32 dataLinkId) {
        require(_allModelIds.contains(modelId), "Model does not exist");
        require(_allDataSourceIds.contains(dataSourceId), "Data source does not exist");
        require(dataSources[dataSourceId].owner == msg.sender, "Not data source owner");

        dataLinkId = keccak256(abi.encodePacked(block.timestamp, msg.sender, modelId, dataSourceId, dataContributionCID));
        require(!_allDataLinkIds.contains(dataLinkId), "Data link already exists");

        dataLinks[dataLinkId] = DataLink({
            dataLinkId: dataLinkId,
            modelId: modelId,
            dataSourceId: dataSourceId,
            contributor: msg.sender,
            dataContributionCID: dataContributionCID,
            linkedAt: block.timestamp,
            revoked: false
        });
        _allDataLinkIds.add(dataLinkId);
        emit DataLinkedToModel(dataLinkId, modelId, dataSourceId, dataContributionCID);
    }

    /**
     * @dev Allows a data source to revoke a previously linked data contribution.
     *      Cannot revoke if the data link has been "approved" for a verified model.
     * @param dataLinkId The ID of the data link to revoke.
     */
    function revokeDataLink(bytes32 dataLinkId) external whenNotPaused {
        DataLink storage link = dataLinks[dataLinkId];
        require(_allDataLinkIds.contains(dataLinkId), "Data link does not exist");
        require(link.contributor == msg.sender, "Not data link owner");
        require(!link.revoked, "Data link already revoked");
        
        Model storage model = models[link.modelId];
        require(model.approvedDataSourceLink != dataLinkId, "Cannot revoke approved data link for a verified model");

        link.revoked = true;
        emit DataLinkRevoked(dataLinkId);
    }

    /**
     * @dev Public view function to retrieve details about a registered data source.
     * @param dataSourceId The unique identifier of the data source.
     * @return DataSource struct containing all data source details.
     */
    function getDataSourceInfo(bytes32 dataSourceId) external view returns (DataSource memory) {
        require(_allDataSourceIds.contains(dataSourceId), "Data source does not exist");
        return dataSources[dataSourceId];
    }

    // --- IV. Decentralized Verification & Challenge System ---

    /**
     * @dev Registers a new verifier with an initial token stake and a profile CID.
     * @param verifierProfileCID IPFS Content Identifier for the verifier's profile or credentials.
     * @param initialStake The amount of tokens to stake to become a verifier.
     * @return verifierId The unique identifier for the registered verifier.
     */
    function registerVerifier(string calldata verifierProfileCID, uint256 initialStake) external whenNotPaused returns (bytes32 verifierId) {
        require(addressToVerifierId[msg.sender] == bytes32(0), "Already registered as a verifier");
        require(initialStake >= minVerifierStake, "Initial stake below minimum");
        require(balances[msg.sender] >= initialStake, "Insufficient balance for initial stake");

        verifierId = keccak256(abi.encodePacked(block.timestamp, msg.sender, verifierProfileCID));
        
        balances[msg.sender] = balances[msg.sender].sub(initialStake);

        verifiers[verifierId] = Verifier({
            verifierId: verifierId,
            account: msg.sender,
            verifierProfileCID: verifierProfileCID,
            initialStake: initialStake,
            isActive: true,
            activeVerificationTasks: EnumerableSet.Bytes32Set(0)
        });
        addressToVerifierId[msg.sender] = verifierId;
        _allVerifierIds.add(verifierId);
        emit VerifierRegistered(verifierId, msg.sender, initialStake);
    }

    /**
     * @dev A registered verifier proposes to verify a specific model, staking for the task.
     *      Model must be in `Submitted` status.
     * @param modelId The ID of the model to verify.
     * @param taskStake The amount of tokens to stake for this specific verification task.
     * @return verificationTaskId The unique identifier for the proposed verification task.
     */
    function proposeVerificationTask(bytes32 modelId, uint256 taskStake) external whenNotPaused returns (bytes32 verificationTaskId) {
        require(taskStake >= minTaskStake, "Task stake below minimum");
        bytes32 verifierId = addressToVerifierId[msg.sender];
        require(verifierId != bytes32(0), "Caller is not a registered verifier");
        require(verifiers[verifierId].isActive, "Verifier is not active");
        require(balances[msg.sender] >= taskStake, "Insufficient balance for task stake");

        Model storage model = models[modelId];
        require(_allModelIds.contains(modelId), "Model does not exist");
        require(model.status == ModelStatus.Submitted, "Model not in 'Submitted' status");

        // Prevent a single model from being verified by multiple parties concurrently (or re-verified without new submission)
        require(model.currentVerifier == address(0), "Model already under verification or has a pending task");

        verificationTaskId = keccak256(abi.encodePacked(block.timestamp, msg.sender, modelId, taskStake));
        require(!_allVerificationTaskIds.contains(verificationTaskId), "Verification task already proposed");

        balances[msg.sender] = balances[msg.sender].sub(taskStake);

        verificationTasks[verificationTaskId] = VerificationTask({
            verificationTaskId: verificationTaskId,
            modelId: modelId,
            verifierId: verifierId,
            verifierAddress: msg.sender,
            taskStake: taskStake,
            proposedAt: block.timestamp,
            completedAt: 0,
            accuracyScore: 0,
            reportCID: "",
            status: VerificationTaskStatus.Proposed,
            challenger: address(0),
            challengeStake: 0,
            challengeReportCID: "",
            challengedAt: 0,
            resolvedAt: 0,
            challengerWon: false
        });
        _allVerificationTaskIds.add(verificationTaskId);

        model.status = ModelStatus.UnderVerification;
        model.currentVerifier = msg.sender;
        model.currentVerificationTaskId = verificationTaskId;
        verifiers[verifierId].activeVerificationTasks.add(verificationTaskId);

        emit VerificationTaskProposed(verificationTaskId, modelId, verifierId, taskStake);
    }

    /**
     * @dev The assigned verifier submits the verification outcome, including an accuracy score and a detailed report's IPFS hash.
     *      Must be within the `verificationPeriod`.
     * @param verificationTaskId The ID of the verification task.
     * @param accuracyScore The accuracy score (e.g., 0-10000 representing 0-100%).
     * @param reportCID IPFS Content Identifier for the detailed verification report.
     */
    function submitVerificationResult(
        bytes32 verificationTaskId,
        uint256 accuracyScore,
        string calldata reportCID
    ) external whenNotPaused {
        VerificationTask storage task = verificationTasks[verificationTaskId];
        require(_allVerificationTaskIds.contains(verificationTaskId), "Task does not exist");
        require(task.verifierAddress == msg.sender, "Not the assigned verifier for this task");
        require(task.status == VerificationTaskStatus.Proposed, "Task not in 'Proposed' status");
        require(block.timestamp <= task.proposedAt.add(verificationPeriod), "Verification period expired");

        task.accuracyScore = accuracyScore;
        task.reportCID = reportCID;
        task.completedAt = block.timestamp;
        task.status = VerificationTaskStatus.ResultSubmitted;

        emit VerificationResultSubmitted(verificationTaskId, accuracyScore, reportCID);
    }

    /**
     * @dev Any registered verifier can challenge a submitted result, staking and providing a counter-report CID.
     *      Must be within the `challengePeriod` after result submission.
     * @param verificationTaskId The ID of the verification task to challenge.
     * @param challengeReportCID IPFS Content Identifier for the detailed challenge report.
     * @param challengeStake The amount of tokens to stake for this challenge.
     */
    function challengeVerificationResult(
        bytes32 verificationTaskId,
        string calldata challengeReportCID,
        uint256 challengeStake
    ) external whenNotPaused {
        require(challengeStake >= minChallengeStake, "Challenge stake below minimum");
        bytes32 challengerVerifierId = addressToVerifierId[msg.sender];
        require(challengerVerifierId != bytes32(0), "Caller is not a registered verifier");
        require(verifiers[challengerVerifierId].isActive, "Challenger verifier is not active");
        require(balances[msg.sender] >= challengeStake, "Insufficient balance for challenge stake");

        VerificationTask storage task = verificationTasks[verificationTaskId];
        require(_allVerificationTaskIds.contains(verificationTaskId), "Task does not exist");
        require(task.status == VerificationTaskStatus.ResultSubmitted, "Task not in 'ResultSubmitted' status");
        require(task.verifierAddress != msg.sender, "Cannot challenge your own verification result");
        require(block.timestamp <= task.completedAt.add(challengePeriod), "Challenge period expired");

        balances[msg.sender] = balances[msg.sender].sub(challengeStake);

        task.status = VerificationTaskStatus.Challenged;
        task.challenger = msg.sender;
        task.challengeStake = challengeStake;
        task.challengeReportCID = challengeReportCID;
        task.challengedAt = block.timestamp;

        models[task.modelId].status = ModelStatus.Challenged;

        emit VerificationResultChallenged(verificationTaskId, msg.sender, challengeStake);
    }

    /**
     * @dev A `RESOLVER_ROLE` determines the outcome of a challenge, triggering stake distribution/slashing and reputation updates.
     *      Must be called within `challengeResolutionPeriod`.
     * @param verificationTaskId The ID of the verification task with a pending challenge.
     * @param challengerWins True if the challenger's claim is valid and they win, false if the original verifier's result stands.
     */
    function resolveChallenge(bytes32 verificationTaskId, bool challengerWins) external whenNotPaused onlyRole(RESOLVER_ROLE) {
        VerificationTask storage task = verificationTasks[verificationTaskId];
        require(_allVerificationTaskIds.contains(verificationTaskId), "Task does not exist");
        require(task.status == VerificationTaskStatus.Challenged, "Task not in 'Challenged' status");
        require(block.timestamp <= task.challengedAt.add(challengeResolutionPeriod), "Challenge resolution period expired");

        address originalVerifier = task.verifierAddress;
        address challenger = task.challenger;

        task.resolvedAt = block.timestamp;
        task.challengerWon = challengerWins;

        if (challengerWins) {
            // Challenger wins: Original verifier's stake slashed, challenger gets reward.
            // Challenger gets their stake back + original verifier's stake.
            balances[challenger] = balances[challenger].add(task.challengeStake).add(task.taskStake);
            _adjustReputation(challenger, 50); // Challenger gains reputation
            _adjustReputation(originalVerifier, -100); // Original verifier loses significant reputation
            task.status = VerificationTaskStatus.ResolvedFailure;
            models[task.modelId].status = ModelStatus.Failed; // Model verification failed
        } else {
            // Original verifier wins: Original verifier gets reward + challenger's stake slashed.
            // Original verifier gets their stake back + challenger's stake.
            balances[originalVerifier] = balances[originalVerifier].add(task.taskStake).add(task.challengeStake);
            _adjustReputation(originalVerifier, 50); // Original verifier gains reputation
            _adjustReputation(challenger, -50); // Challenger loses reputation
            task.status = VerificationTaskStatus.ResolvedSuccess;
            models[task.modelId].status = ModelStatus.Verified; // Model verification succeeded
        }

        // Clean up verifier's active task list
        bytes32 originalVerifierId = addressToVerifierId[originalVerifier];
        if (originalVerifierId != bytes32(0)) {
            verifiers[originalVerifierId].activeVerificationTasks.remove(verificationTaskId);
        }

        emit ChallengeResolved(verificationTaskId, challengerWins);
    }

    /**
     * @dev A verifier claims their stake and rewards for a successfully completed and unchallenged verification task.
     *      Can be called after `challengePeriod` has passed and no challenge was made, or after successful resolution.
     * @param verificationTaskId The ID of the verification task.
     */
    function claimVerificationRewards(bytes32 verificationTaskId) external whenNotPaused {
        VerificationTask storage task = verificationTasks[verificationTaskId];
        require(_allVerificationTaskIds.contains(verificationTaskId), "Task does not exist");
        require(task.verifierAddress == msg.sender, "Not the verifier for this task");

        require(
            (task.status == VerificationTaskStatus.ResultSubmitted && block.timestamp > task.completedAt.add(challengePeriod)) ||
            (task.status == VerificationTaskStatus.ResolvedSuccess),
            "Task not yet eligible for reward claim (either challenge period not over, or challenge in progress/failed)"
        );
        require(task.taskStake > 0, "Rewards already claimed or no stake");

        uint256 rewards = task.taskStake;
        task.taskStake = 0; // Prevent double claim

        balances[msg.sender] = balances[msg.sender].add(rewards);
        _adjustReputation(msg.sender, 20); // Verifier gains reputation

        // If no challenge, mark as resolved success
        if (task.status == VerificationTaskStatus.ResultSubmitted) {
             task.status = VerificationTaskStatus.ResolvedSuccess;
             models[task.modelId].status = ModelStatus.Verified;
        }

        // Clean up verifier's active task list
        bytes32 verifierId = addressToVerifierId[msg.sender];
        if (verifierId != bytes32(0)) {
            verifiers[verifierId].activeVerificationTasks.remove(verificationTaskId);
        }
        
        emit VerificationRewardsClaimed(verificationTaskId, msg.sender, rewards);
    }

    /**
     * @dev Public view function to retrieve details about a specific verification task.
     * @param verificationTaskId The unique identifier of the verification task.
     * @return VerificationTask struct containing all task details.
     */
    function getVerificationTaskInfo(bytes32 verificationTaskId) external view returns (VerificationTask memory) {
        require(_allVerificationTaskIds.contains(verificationTaskId), "Verification task does not exist");
        return verificationTasks[verificationTaskId];
    }

    // --- V. Reputation & Dynamic Parameters ---

    /**
     * @dev Public view function to check a participant's current reputation score.
     * @param participant The address of the participant.
     * @return The current reputation score.
     */
    function getReputationScore(address participant) external view returns (int256) {
        return reputationScores[participant];
    }

    /**
     * @dev Internal function to adjust a participant's reputation score.
     *      Used internally by `resolveChallenge` and `claimVerificationRewards`.
     * @param participant The address of the participant.
     * @param scoreChange The amount to change the reputation score by (can be positive or negative).
     */
    function _adjustReputation(address participant, int256 scoreChange) internal {
        reputationScores[participant] = reputationScores[participant].add(scoreChange);
        emit ReputationAdjusted(participant, scoreChange, reputationScores[participant]);
    }
    
    /**
     * @dev Manually adjusts a participant's reputation score.
     *      Can only be called by an account with `ADMIN_ROLE` or `RESOLVER_ROLE`.
     *      This provides a manual override for exceptional circumstances or initial seeding.
     * @param participant The address of the participant.
     * @param scoreChange The amount to change the reputation score by (can be positive or negative).
     */
    function adjustReputation(address participant, int256 scoreChange) external onlyRole(ADMIN_ROLE) {
        _adjustReputation(participant, scoreChange);
    }

    /**
     * @dev Sets various minimum stake requirements for participation.
     *      Can only be called by an account with `ADMIN_ROLE`.
     * @param _minModelCollateral Minimum collateral for model submission.
     * @param _minVerifierStake Minimum stake to register as a verifier.
     * @param _minTaskStake Minimum stake for proposing a verification task.
     * @param _minChallengeStake Minimum stake for challenging a verification result.
     */
    function setMinimumStakes(
        uint256 _minModelCollateral,
        uint256 _minVerifierStake,
        uint256 _minTaskStake,
        uint256 _minChallengeStake
    ) external onlyRole(ADMIN_ROLE) {
        require(_minModelCollateral > 0 && _minVerifierStake > 0 && _minTaskStake > 0 && _minChallengeStake > 0, "Minimum stakes must be positive");
        minModelCollateral = _minModelCollateral;
        minVerifierStake = _minVerifierStake;
        minTaskStake = _minTaskStake;
        minChallengeStake = _minChallengeStake;
        emit MinimumStakesSet(_minModelCollateral, _minVerifierStake, _minTaskStake, _minChallengeStake);
    }

    /**
     * @dev Public view function returning aggregated statistics and current parameters of the collective.
     * @return totalModels Total number of models submitted.
     * @return activeVerifiers Total number of registered active verifiers.
     * @return totalStakedTokens Total amount of collective tokens currently held as stakes/collateral within the contract.
     * @return currentMinModelCollateral Current minimum collateral for models.
     * @return currentMinVerifierStake Current minimum stake for verifiers.
     * @return currentMinTaskStake Current minimum stake for verification tasks.
     * @return currentMinChallengeStake Current minimum stake for challenges.
     */
    function getCollectiveMetrics() external view returns (
        uint256 totalModels,
        uint256 activeVerifiers,
        uint256 totalStakedTokens,
        uint256 currentMinModelCollateral,
        uint256 currentMinVerifierStake,
        uint256 currentMinTaskStake,
        uint256 currentMinChallengeStake
    ) {
        totalModels = _allModelIds.length();
        activeVerifiers = _allVerifierIds.length(); // Simplified: counts all registered, not just 'actively participating'
        totalStakedTokens = collectiveToken.balanceOf(address(this)); // Reflects all tokens held by the contract.
        
        currentMinModelCollateral = minModelCollateral;
        currentMinVerifierStake = minVerifierStake;
        currentMinTaskStake = minTaskStake;
        currentMinChallengeStake = minChallengeStake;
    }
}
```