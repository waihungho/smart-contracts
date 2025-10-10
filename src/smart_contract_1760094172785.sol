Here's a smart contract written in Solidity that embodies advanced concepts, creative functionality, and trendy themes like decentralized AI marketplaces, data monetization, reputation systems, and collaborative training, ensuring it does not duplicate existing popular open-source contracts.

---

### AetherBrain: Decentralized AI Model & Data Nexus

**Description:**
A smart contract facilitating a decentralized marketplace for AI models and datasets. It features a robust reputation system, mechanisms for collaborative training, and data monetization capabilities. AetherBrain acts as an on-chain coordinator for off-chain AI computation and data access, rewarding participants based on their contributions and reputation. It incorporates conceptual hooks for ZK-proofs to ensure integrity without on-chain computation.

**Core Concepts:**
*   **Native Token (`AetherToken`):** An ERC20 token used for staking, payments (inference, licensing), and rewards within the ecosystem.
*   **Reputation System:** Users earn reputation by staking tokens and making valuable contributions. Reputation gates access to certain actions and influences trust.
*   **AI Model Marketplace:** Providers can register, update, and license AI models. Consumers can request inference or acquire licenses.
*   **Data Management & Monetization:** Data providers can register datasets, set licensing fees, and receive payments when their data is used. Users can report data quality issues.
*   **Collaborative Training:** A decentralized framework for proposing and executing AI model training tasks, allowing data and compute providers to contribute and earn rewards.
*   **ZK-Proof Integration (Conceptual):** Placeholder proof hashes (`bytes32`) are used to represent off-chain verification of computation integrity without performing the actual ZK-proof validation on-chain.
*   **Protocol Governance & Fees:** Owner-controlled functions for pausing, fee management, and critical updates ensure a baseline level of control.

**Function Summary:**

**I. Core Infrastructure & Protocol Control**
1.  `constructor()`: Initializes the contract with an owner and the address of the native utility token.
2.  `setNativeToken(address _newToken)`: Allows the owner to update the address of the native utility token.
3.  `pause()`: Puts the contract into a paused state, preventing most user interactions (Owner-only).
4.  `unpause()`: Resumes normal contract operations from a paused state (Owner-only).
5.  `withdrawProtocolFees(address recipient)`: Enables the owner to withdraw accumulated service fees to a specified recipient.
6.  `updateServiceFeeRate(uint256 newRate)`: Allows the owner to adjust the percentage of fees charged on transactions.

**II. Reputation & Staking System**
7.  `stakeForReputation(uint256 amount)`: Users stake native tokens to earn reputation points, granting access and influence.
8.  `unstakeFromReputation(uint256 amount)`: Users can unstake tokens, reducing their reputation score.
9.  `delegateReputation(address delegatee, uint256 amount)`: Allows a user to temporarily delegate a portion of their reputation to another address for specific tasks, affecting the delegator's *effective* reputation.
10. `undelegateReputation(address delegatee, uint256 amount)`: Revokes previously delegated reputation, restoring the delegator's effective reputation.
11. `penalizeReputation(address target, uint256 amount)`: Owner/approved entity can decrease a user's reputation due to malicious activity or poor performance.
12. `rewardReputation(address target, uint256 amount)`: Owner/approved entity can increase a user's reputation for valuable contributions.
13. `getUserReputation(address user)`: Retrieves the current reputation score of a user.

**III. AI Model Management**
14. `registerAIModel(string calldata modelName, string calldata modelCID, uint256 inferenceFee, uint256 licenseFee, uint256 requiredReputation)`: Registers a new AI model with its metadata, inference fees, and licensing terms.
15. `updateModelDetails(uint256 modelId, uint256 newInferenceFee, uint256 newLicenseFee)`: Allows a model provider to modify the fees or other details of their registered model.
16. `deactivateAIModel(uint256 modelId)`: Allows a model provider to temporarily take their model offline.
17. `getAIModelDetails(uint256 modelId)`: Retrieves all public details of a registered AI model.
18. `requestInference(uint256 modelId, string calldata inputCID)`: Initiates an off-chain AI inference request using a specified model, paying the inference fee.
19. `confirmInferenceResult(uint256 requestId, string calldata resultCID, bytes32 proofHash)`: Model provider confirms the completion of an inference request, attaching a result CID and a computation proof hash. This triggers payment to the model provider.
20. `licenseAIModel(uint256 modelId, address licensee)`: Allows a user to acquire a perpetual license to use a specific AI model for a fee.
21. `disputeInferenceResult(uint256 requestId, string calldata reason)`: User disputes an inference result, typically due to inaccuracy or fraud, marking it for review.

**IV. Data Management & Monetization**
22. `registerDataset(string calldata datasetName, string calldata datasetCID, uint256 dataLicenseFee, uint256 qualityScore, uint256 requiredReputation)`: Registers a new dataset, including its content identifier, licensing fee, and initial quality score.
23. `updateDatasetDetails(uint256 datasetId, uint256 newDataLicenseFee)`: Allows a data provider to modify the licensing fee or metadata of their registered dataset.
24. `licenseDataset(uint256 datasetId, address licensee)`: Enables a user to license a specific dataset for a fee, primarily for training purposes.
25. `reportDataQualityIssue(uint256 datasetId, string calldata issueDescription)`: Users can report issues with a dataset, potentially leading to a review and reputation adjustment for the data provider.
26. `getDatasetDetails(uint256 datasetId)`: Retrieves all public details of a registered dataset.

**V. Collaborative Training & Reward Distribution**
27. `proposeTrainingTask(string calldata taskDescription, uint256 requiredDataReputation, uint256 requiredComputeReputation, uint256 rewardPool)`: A user proposes a collaborative AI model training task, setting requirements and funding a reward pool.
28. `contributeToTrainingTask(uint256 taskId, uint256 datasetId)`: Data providers contribute their registered datasets to an ongoing training task.
29. `offerComputeForTraining(uint256 taskId, uint256 stakeAmount)`: Compute providers register their intent to offer computational resources for a specific training task, potentially by staking tokens.
30. `distributeTrainingRewards(uint256 taskId, address[] calldata recipients, uint256[] calldata amounts)`: Facilitates the distribution of rewards from a completed training task to participating data and compute providers (callable by task proposer or oracle).
31. `submitModelUpdateProof(uint256 modelId, string calldata newModelCID, bytes32 trainingProofHash)`: Allows a model developer to submit an updated version of a model, citing a successful collaborative training task and an integrity proof hash.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Custom Errors for better gas efficiency and clarity
error InvalidAmount();
error InsufficientReputation(uint256 currentReputation, uint256 requiredReputation);
error NotModelProvider();
error NotDatasetProvider();
error ModelNotActive();
error DatasetNotActive();
error ModelNotFound();
error DatasetNotFound();
error InferenceRequestNotFound();
error TrainingTaskNotFound();
error UnauthorizedAction();
error InvalidState();
error AlreadyLicensed();
error NotLicensed();
error NothingToWithdraw();
error ZeroAddress();
error SelfDelegationNotAllowed();
error DelegationAmountTooHigh();
error InsufficientBalance();

/// @title AetherBrain: Decentralized AI Model & Data Nexus
/// @author Your Name/AI
/// @notice A smart contract facilitating a decentralized marketplace for AI models and datasets,
/// featuring a robust reputation system, collaborative training mechanisms, and data monetization capabilities.
/// It acts as an on-chain coordinator for off-chain AI computation and data access.
///
/// @dev This contract relies on off-chain computation and data storage (e.g., IPFS, Arweave)
/// and assumes the existence of a native ERC20 utility token for all transactions and staking.
contract AetherBrain is Ownable, Pausable {

    // --- I. Core Infrastructure & Protocol Control ---

    /// @notice The ERC20 token used for staking, payments, and rewards within the AetherBrain ecosystem.
    IERC20 public nativeToken;
    /// @notice The percentage fee charged by the protocol on certain transactions (e.g., model inference, data licensing).
    uint256 public serviceFeeRate; // Basis points, e.g., 500 for 5%
    /// @notice Accumulated fees waiting to be withdrawn by the protocol owner.
    uint256 public totalProtocolFees;

    /// @dev Emitted when the native token address is updated.
    /// @param oldToken The previous native token address.
    /// @param newToken The new native token address.
    event NativeTokenUpdated(address oldToken, address newToken);
    /// @dev Emitted when protocol fees are withdrawn.
    /// @param recipient The address receiving the fees.
    /// @param amount The amount of fees withdrawn.
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);
    /// @dev Emitted when the service fee rate is updated.
    /// @param oldRate The previous service fee rate.
    /// @param newRate The new service fee rate.
    event ServiceFeeRateUpdated(uint256 oldRate, uint256 newRate);

    /// @notice Constructor to initialize the contract with an owner and the native utility token address.
    /// @param _nativeToken The address of the ERC20 token used for all transactions and staking.
    constructor(address _nativeToken) Ownable(msg.sender) {
        if (_nativeToken == address(0)) revert ZeroAddress();
        nativeToken = IERC20(_nativeToken);
        serviceFeeRate = 500; // Default 5% (500 basis points)
    }

    /// @notice Allows the owner to update the address of the native utility token.
    /// @dev This should be used with extreme caution as it changes the core currency of the ecosystem.
    /// @param _newToken The address of the new ERC20 token.
    function setNativeToken(address _newToken) public onlyOwner {
        if (_newToken == address(0)) revert ZeroAddress();
        emit NativeTokenUpdated(address(nativeToken), _newToken);
        nativeToken = IERC20(_newToken);
    }

    /// @notice Pauses the contract, preventing most user interactions. Only callable by the owner.
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract, allowing user interactions again. Only callable by the owner.
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Allows the owner to withdraw accumulated service fees to a specified recipient.
    /// @param recipient The address to send the collected fees to.
    function withdrawProtocolFees(address recipient) public onlyOwner {
        if (totalProtocolFees == 0) revert NothingToWithdraw();
        if (recipient == address(0)) revert ZeroAddress();

        uint256 amount = totalProtocolFees;
        totalProtocolFees = 0;
        if (!nativeToken.transfer(recipient, amount)) revert InsufficientBalance(); // Check for successful transfer
        emit ProtocolFeesWithdrawn(recipient, amount);
    }

    /// @notice Allows the owner to adjust the percentage of fees charged on transactions.
    /// @param newRate The new service fee rate in basis points (e.g., 500 for 5%). Max 10000 (100%).
    function updateServiceFeeRate(uint256 newRate) public onlyOwner {
        if (newRate > 10000) revert InvalidAmount(); // Max 100%
        emit ServiceFeeRateUpdated(serviceFeeRate, newRate);
        serviceFeeRate = newRate;
    }

    // --- II. Reputation & Staking System ---

    /// @notice Maps user addresses to their current reputation score.
    /// @dev Reputation points are directly proportional to staked tokens (1 token = 1 reputation point) initially,
    /// but can be adjusted by governance actions (penalize/reward) and delegation.
    mapping(address => uint256) public reputations;
    /// @notice Maps a delegator to a delegatee to the amount of reputation delegated.
    mapping(address => mapping(address => uint256)) public delegatedReputations;

    /// @dev Emitted when a user stakes tokens for reputation.
    /// @param user The address of the user.
    /// @param amount The amount of tokens staked.
    /// @param newReputation The user's new reputation score.
    event ReputationStaked(address indexed user, uint256 amount, uint256 newReputation);
    /// @dev Emitted when a user unstakes tokens from reputation.
    /// @param user The address of the user.
    /// @param amount The amount of tokens unstaked.
    /// @param newReputation The user's new reputation score.
    event ReputationUnstaked(address indexed user, uint256 amount, uint256 newReputation);
    /// @dev Emitted when a user delegates reputation to another address.
    /// @param delegator The address delegating reputation.
    /// @param delegatee The address receiving the delegated reputation.
    /// @param amount The amount of reputation delegated.
    event ReputationDelegated(address indexed delegator, address indexed delegatee, uint256 amount);
    /// @dev Emitted when a user undelegates reputation from another address.
    /// @param delegator The address undelegating reputation.
    /// @param delegatee The address from which reputation is undelegated.
    /// @param amount The amount of reputation undelegated.
    event ReputationUndelegated(address indexed delegator, address indexed delegatee, uint256 amount);
    /// @dev Emitted when a user's reputation is penalized.
    /// @param target The address whose reputation was penalized.
    /// @param amount The amount of reputation deducted.
    /// @param newReputation The user's new reputation score.
    event ReputationPenalized(address indexed target, uint256 amount, uint256 newReputation);
    /// @dev Emitted when a user's reputation is rewarded.
    /// @param target The address whose reputation was rewarded.
    /// @param amount The amount of reputation added.
    /// @param newReputation The user's new reputation score.
    event ReputationRewarded(address indexed target, uint256 amount, uint256 newReputation);

    /// @notice Users stake native tokens to earn reputation points.
    /// @dev Reputation points are directly proportional to staked tokens (1 token = 1 reputation point).
    /// These tokens are held by the contract, increasing the user's reputation score.
    /// @param amount The amount of native tokens to stake.
    function stakeForReputation(uint256 amount) public whenNotPaused {
        if (amount == 0) revert InvalidAmount();
        if (!nativeToken.transferFrom(msg.sender, address(this), amount)) revert InsufficientBalance();
        reputations[msg.sender] += amount;
        emit ReputationStaked(msg.sender, amount, reputations[msg.sender]);
    }

    /// @notice Users can unstake tokens from their reputation stake.
    /// @dev This reduces their reputation score. Ensures user cannot unstake more than their current reputation.
    /// @param amount The amount of native tokens to unstake.
    function unstakeFromReputation(uint256 amount) public whenNotPaused {
        if (amount == 0) revert InvalidAmount();
        if (reputations[msg.sender] < amount) revert InvalidAmount(); // Cannot unstake more than owned reputation

        reputations[msg.sender] -= amount;
        if (!nativeToken.transfer(msg.sender, amount)) revert InsufficientBalance();
        emit ReputationUnstaked(msg.sender, amount, reputations[msg.sender]);
    }

    /// @notice Allows a user to temporarily delegate a portion of their reputation to another address for specific tasks.
    /// @dev The delegator's *effective* reputation for checks within the contract decreases,
    /// but their total staked tokens (and underlying reputation potential) remain unchanged.
    /// @param delegatee The address to which reputation is delegated.
    /// @param amount The amount of reputation to delegate.
    function delegateReputation(address delegatee, uint256 amount) public whenNotPaused {
        if (amount == 0) revert InvalidAmount();
        if (msg.sender == delegatee) revert SelfDelegationNotAllowed();
        // Check if delegator has enough *effective* reputation to delegate.
        // This prevents delegating more than they possess after accounting for previous delegations.
        if (reputations[msg.sender] < amount) revert DelegationAmountTooHigh();

        delegatedReputations[msg.sender][delegatee] += amount;
        reputations[msg.sender] -= amount; // Reduce delegator's effective reputation
        emit ReputationDelegated(msg.sender, delegatee, amount);
    }

    /// @notice Revokes previously delegated reputation, restoring it to the delegator.
    /// @param delegatee The address from which reputation is undelegated.
    /// @param amount The amount of reputation to undelegate.
    function undelegateReputation(address delegatee, uint256 amount) public whenNotPaused {
        if (amount == 0) revert InvalidAmount();
        if (delegatedReputations[msg.sender][delegatee] < amount) revert InvalidAmount();

        delegatedReputations[msg.sender][delegatee] -= amount;
        reputations[msg.sender] += amount; // Restore delegator's effective reputation
        emit ReputationUndelegated(msg.sender, delegatee, amount);
    }

    /// @notice Owner/approved entity can decrease a user's reputation due to malicious activity or poor performance.
    /// @param target The address whose reputation will be penalized.
    /// @param amount The amount of reputation to deduct.
    function penalizeReputation(address target, uint256 amount) public onlyOwner {
        if (amount == 0) revert InvalidAmount();
        if (reputations[target] < amount) {
            reputations[target] = 0;
        } else {
            reputations[target] -= amount;
        }
        emit ReputationPenalized(target, amount, reputations[target]);
    }

    /// @notice Owner/approved entity can increase a user's reputation for valuable contributions.
    /// @param target The address whose reputation will be rewarded.
    /// @param amount The amount of reputation to add.
    function rewardReputation(address target, uint256 amount) public onlyOwner {
        if (amount == 0) revert InvalidAmount();
        reputations[target] += amount;
        emit ReputationRewarded(target, amount, reputations[target]);
    }

    /// @notice Retrieves the current reputation score of a user.
    /// @param user The address of the user.
    /// @return The reputation score.
    function getUserReputation(address user) public view returns (uint256) {
        return reputations[user];
    }

    /// @dev Modifier to check if the caller has enough reputation.
    /// @param _requiredReputation The minimum reputation score needed.
    modifier hasEnoughReputation(uint256 _requiredReputation) {
        if (reputations[msg.sender] < _requiredReputation) {
            revert InsufficientReputation(reputations[msg.sender], _requiredReputation);
        }
        _;
    }

    // --- III. AI Model Management ---

    /// @dev Represents an AI model registered on the platform.
    struct AIModel {
        uint256 id;                 /// Unique identifier for the model.
        address provider;           /// Address of the model provider.
        string name;                /// Human-readable name of the model.
        string modelCID;            /// Content Identifier (e.g., IPFS hash) pointing to the model artifacts.
        uint256 inferenceFee;       /// Fee in native tokens per inference request.
        uint256 licenseFee;         /// Fee in native tokens for perpetual licensing.
        uint256 registeredAt;       /// Timestamp when the model was registered.
        bool isActive;              /// Indicates if the model is available for use.
        uint256 requiredReputation; /// Minimum reputation required for provider to register this model.
    }

    /// @dev Represents an AI inference request.
    struct InferenceRequest {
        uint256 id;                 /// Unique identifier for the request.
        uint256 modelId;            /// ID of the model used for inference.
        address requester;          /// Address of the user who requested the inference.
        string inputCID;            /// Content Identifier for the input data.
        string resultCID;           /// Content Identifier for the inference result (set upon confirmation).
        uint256 requestedAt;        /// Timestamp when the request was made.
        uint256 completedAt;        /// Timestamp when the request was completed.
        bytes32 proofHash;          /// Hash of the ZK-proof or integrity proof for the computation (set upon confirmation).
        uint256 feePaid;            /// The net fee paid to the model provider for this specific inference.
        bool isCompleted;           /// True if the inference has been confirmed.
        bool isDisputed;            /// True if the inference result has been disputed.
    }

    /// @notice Counter for unique AI model IDs.
    uint256 public nextModelId;
    /// @notice Counter for unique inference request IDs.
    uint256 public nextInferenceRequestId;

    /// @notice Maps model IDs to their `AIModel` struct.
    mapping(uint256 => AIModel) public models;
    /// @notice Maps provider addresses to a list of model IDs they own.
    mapping(address => uint256[]) public modelIdsByProvider;
    /// @notice Maps inference request IDs to their `InferenceRequest` struct.
    mapping(uint256 => InferenceRequest) public inferenceRequests;
    /// @notice Records if a user has licensed a specific model (true for perpetual license).
    mapping(uint256 => mapping(address => bool)) public modelLicenses; // modelId => licensee => isLicensed

    /// @dev Emitted when a new AI model is registered.
    /// @param modelId The ID of the new model.
    /// @param provider The address of the model provider.
    /// @param name The name of the model.
    /// @param inferenceFee The fee for inference.
    /// @param licenseFee The fee for licensing.
    event AIModelRegistered(
        uint256 indexed modelId,
        address indexed provider,
        string name,
        uint256 inferenceFee,
        uint256 licenseFee
    );
    /// @dev Emitted when an AI model's details are updated.
    /// @param modelId The ID of the updated model.
    /// @param newInferenceFee The new inference fee.
    /// @param newLicenseFee The new license fee.
    event AIModelUpdated(uint256 indexed modelId, uint256 newInferenceFee, uint256 newLicenseFee);
    /// @dev Emitted when an AI model is deactivated.
    /// @param modelId The ID of the deactivated model.
    event AIModelDeactivated(uint256 indexed modelId);
    /// @dev Emitted when an inference request is made.
    /// @param requestId The ID of the request.
    /// @param modelId The ID of the model used.
    /// @param requester The address of the requester.
    /// @param inputCID The CID of the input data.
    /// @param feePaid The net fee paid to the model provider.
    event InferenceRequested(
        uint256 indexed requestId,
        uint256 indexed modelId,
        address indexed requester,
        string inputCID,
        uint256 feePaid
    );
    /// @dev Emitted when an inference result is confirmed.
    /// @param requestId The ID of the request.
    /// @param resultCID The CID of the result.
    /// @param proofHash The hash of the computation proof.
    event InferenceResultConfirmed(uint256 indexed requestId, string resultCID, bytes32 proofHash);
    /// @dev Emitted when an inference result is disputed.
    /// @param requestId The ID of the request.
    /// @param reason The reason for the dispute.
    event InferenceDisputed(uint256 indexed requestId, string reason);
    /// @dev Emitted when an AI model is licensed.
    /// @param modelId The ID of the licensed model.
    /// @param licensee The address of the licensee.
    /// @param feePaid The net fee paid for the license.
    event AIModelLicensed(uint256 indexed modelId, address indexed licensee, uint256 feePaid);

    /// @notice Registers a new AI model with its metadata, inference fees, and licensing terms.
    /// @param modelName Human-readable name of the model.
    /// @param modelCID Content Identifier (e.g., IPFS hash) pointing to the model artifacts.
    /// @param inferenceFee Fee in native tokens per inference request.
    /// @param licenseFee Fee in native tokens for perpetual licensing.
    /// @param requiredReputation Minimum reputation required for the provider to register this model.
    function registerAIModel(
        string calldata modelName,
        string calldata modelCID,
        uint256 inferenceFee,
        uint256 licenseFee,
        uint256 requiredReputation
    ) public whenNotPaused hasEnoughReputation(requiredReputation) {
        uint256 newModelId = nextModelId++;
        models[newModelId] = AIModel({
            id: newModelId,
            provider: msg.sender,
            name: modelName,
            modelCID: modelCID,
            inferenceFee: inferenceFee,
            licenseFee: licenseFee,
            registeredAt: block.timestamp,
            isActive: true,
            requiredReputation: requiredReputation
        });
        modelIdsByProvider[msg.sender].push(newModelId);
        emit AIModelRegistered(newModelId, msg.sender, modelName, inferenceFee, licenseFee);
    }

    /// @notice Allows a model provider to modify the fees or other details of their registered model.
    /// @param modelId The ID of the model to update.
    /// @param newInferenceFee The new inference fee.
    /// @param newLicenseFee The new license fee.
    function updateModelDetails(
        uint256 modelId,
        uint256 newInferenceFee,
        uint256 newLicenseFee
    ) public whenNotPaused {
        AIModel storage model = models[modelId];
        if (model.provider == address(0)) revert ModelNotFound(); // Check for uninitialized struct
        if (model.provider != msg.sender) revert NotModelProvider();

        model.inferenceFee = newInferenceFee;
        model.licenseFee = newLicenseFee;
        emit AIModelUpdated(modelId, newInferenceFee, newLicenseFee);
    }

    /// @notice Allows a model provider to temporarily take their model offline.
    /// @param modelId The ID of the model to deactivate.
    function deactivateAIModel(uint256 modelId) public whenNotPaused {
        AIModel storage model = models[modelId];
        if (model.provider == address(0)) revert ModelNotFound();
        if (model.provider != msg.sender) revert NotModelProvider();
        if (!model.isActive) revert InvalidState(); // Already inactive

        model.isActive = false;
        emit AIModelDeactivated(modelId);
    }

    /// @notice Retrieves all public details of a registered AI model.
    /// @param modelId The ID of the model to query.
    /// @return A tuple containing model details.
    function getAIModelDetails(
        uint256 modelId
    )
        public
        view
        returns (
            uint256 id,
            address provider,
            string memory name,
            string memory modelCID,
            uint256 inferenceFee,
            uint256 licenseFee,
            uint256 registeredAt,
            bool isActive,
            uint256 requiredReputation
        )
    {
        AIModel storage model = models[modelId];
        if (model.provider == address(0)) revert ModelNotFound();

        return (
            model.id,
            model.provider,
            model.name,
            model.modelCID,
            model.inferenceFee,
            model.licenseFee,
            model.registeredAt,
            model.isActive,
            model.requiredReputation
        );
    }

    /// @notice Initiates an off-chain AI inference request using a specified model, paying the inference fee.
    /// @dev The actual computation happens off-chain, and `confirmInferenceResult` is called later by the provider.
    /// @param modelId The ID of the model to use for inference.
    /// @param inputCID Content Identifier for the input data.
    function requestInference(uint256 modelId, string calldata inputCID) public whenNotPaused {
        AIModel storage model = models[modelId];
        if (model.provider == address(0) || !model.isActive) revert ModelNotFound();
        if (model.inferenceFee == 0) revert InvalidAmount(); // Must have a fee for this process

        if (!nativeToken.transferFrom(msg.sender, address(this), model.inferenceFee)) revert InsufficientBalance();

        uint256 serviceFee = (model.inferenceFee * serviceFeeRate) / 10000;
        totalProtocolFees += serviceFee; // Collect protocol fee
        uint256 netFeeToProvider = model.inferenceFee - serviceFee;

        uint256 newRequestId = nextInferenceRequestId++;
        inferenceRequests[newRequestId] = InferenceRequest({
            id: newRequestId,
            modelId: modelId,
            requester: msg.sender,
            inputCID: inputCID,
            resultCID: "", // Will be set by confirmInferenceResult
            requestedAt: block.timestamp,
            completedAt: 0,
            proofHash: 0, // Will be set by confirmInferenceResult
            feePaid: netFeeToProvider,
            isCompleted: false,
            isDisputed: false
        });
        emit InferenceRequested(newRequestId, modelId, msg.sender, inputCID, netFeeToProvider);
    }

    /// @notice Model provider confirms the completion of an inference request, attaching a result CID and a computation proof hash.
    /// @dev This function transfers the net inference fee to the model provider.
    /// @param requestId The ID of the inference request to confirm.
    /// @param resultCID Content Identifier for the inference result.
    /// @param proofHash Hash of the ZK-proof or integrity proof for the computation.
    function confirmInferenceResult(
        uint256 requestId,
        string calldata resultCID,
        bytes32 proofHash
    ) public whenNotPaused {
        InferenceRequest storage req = inferenceRequests[requestId];
        if (req.requester == address(0)) revert InferenceRequestNotFound();
        if (req.isCompleted) revert InvalidState(); // Already completed
        if (req.isDisputed) revert InvalidState(); // Cannot confirm a disputed request

        AIModel storage model = models[req.modelId];
        if (model.provider != msg.sender) revert NotModelProvider();

        req.resultCID = resultCID;
        req.proofHash = proofHash;
        req.isCompleted = true;
        req.completedAt = block.timestamp;

        if (!nativeToken.transfer(model.provider, req.feePaid)) revert InsufficientBalance();
        emit InferenceResultConfirmed(requestId, resultCID, proofHash);
    }

    /// @notice Allows a user to acquire a perpetual license to use a specific AI model for a fee.
    /// @param modelId The ID of the model to license.
    /// @param licensee The address acquiring the license.
    function licenseAIModel(uint256 modelId, address licensee) public whenNotPaused {
        AIModel storage model = models[modelId];
        if (model.provider == address(0) || !model.isActive) revert ModelNotFound();
        if (model.licenseFee == 0) revert InvalidAmount();
        if (modelLicenses[modelId][licensee]) revert AlreadyLicensed();

        if (!nativeToken.transferFrom(msg.sender, address(this), model.licenseFee)) revert InsufficientBalance();

        uint256 serviceFee = (model.licenseFee * serviceFeeRate) / 10000;
        totalProtocolFees += serviceFee; // Collect protocol fee
        uint256 netFeeToProvider = model.licenseFee - serviceFee;

        modelLicenses[modelId][licensee] = true;
        if (!nativeToken.transfer(model.provider, netFeeToProvider)) revert InsufficientBalance();
        emit AIModelLicensed(modelId, licensee, netFeeToProvider);
    }

    /// @notice User disputes an inference result, typically due to inaccuracy or fraud.
    /// @dev This marks the request as disputed, triggering potential manual review or automated penalties.
    /// @param requestId The ID of the inference request to dispute.
    /// @param reason A description of the dispute.
    function disputeInferenceResult(uint256 requestId, string calldata reason) public whenNotPaused {
        InferenceRequest storage req = inferenceRequests[requestId];
        if (req.requester == address(0)) revert InferenceRequestNotFound();
        if (req.requester != msg.sender) revert UnauthorizedAction();
        if (req.isDisputed) revert InvalidState(); // Already disputed

        req.isDisputed = true;
        // Further dispute resolution logic would involve governance or oracles.
        // For simplicity, this simply marks it and emits an event.
        emit InferenceDisputed(requestId, reason);
    }

    // --- IV. Data Management & Monetization ---

    /// @dev Represents a dataset registered on the platform.
    struct Dataset {
        uint256 id;                 /// Unique identifier for the dataset.
        address provider;           /// Address of the data provider.
        string name;                /// Human-readable name of the dataset.
        string datasetCID;          /// Content Identifier (e.g., IPFS hash) pointing to the dataset or its metadata/schema.
        uint256 licenseFee;         /// Fee in native tokens for licensing the dataset.
        uint256 qualityScore;       /// A score indicating the perceived quality or usefulness of the dataset.
        uint256 registeredAt;       /// Timestamp when the dataset was registered.
        bool isActive;              /// Indicates if the dataset is available for licensing.
        uint256 requiredReputation; /// Minimum reputation required for provider to register this dataset.
    }

    /// @notice Counter for unique Dataset IDs.
    uint256 public nextDatasetId;

    /// @notice Maps dataset IDs to their `Dataset` struct.
    mapping(uint256 => Dataset) public datasets;
    /// @notice Maps provider addresses to a list of dataset IDs they own.
    mapping(address => uint256[]) public datasetIdsByProvider;
    /// @notice Records if a user has licensed a specific dataset (true for perpetual license).
    mapping(uint256 => mapping(address => bool)) public datasetLicenses; // datasetId => licensee => isLicensed

    /// @dev Emitted when a new dataset is registered.
    /// @param datasetId The ID of the new dataset.
    /// @param provider The address of the data provider.
    /// @param name The name of the dataset.
    /// @param licenseFee The fee for licensing.
    /// @param qualityScore The initial quality score.
    event DatasetRegistered(
        uint256 indexed datasetId,
        address indexed provider,
        string name,
        uint256 licenseFee,
        uint256 qualityScore
    );
    /// @dev Emitted when a dataset's details are updated.
    /// @param datasetId The ID of the updated dataset.
    /// @param newLicenseFee The new license fee.
    event DatasetUpdated(uint256 indexed datasetId, uint256 newLicenseFee);
    /// @dev Emitted when a dataset is licensed.
    /// @param datasetId The ID of the licensed dataset.
    /// @param licensee The address of the licensee.
    /// @param feePaid The net fee paid for the license.
    event DatasetLicensed(uint256 indexed datasetId, address indexed licensee, uint256 feePaid);
    /// @dev Emitted when a data quality issue is reported.
    /// @param datasetId The ID of the dataset.
    /// @param reporter The address who reported the issue.
    /// @param issueDescription A description of the issue.
    event DataQualityIssueReported(uint256 indexed datasetId, address indexed reporter, string issueDescription);

    /// @notice Registers a new dataset, including its content identifier, licensing fee, and initial quality score.
    /// @param datasetName Human-readable name of the dataset.
    /// @param datasetCID Content Identifier pointing to the dataset or its metadata/schema.
    /// @param dataLicenseFee Fee in native tokens for perpetual licensing.
    /// @param qualityScore An initial score reflecting the dataset's quality.
    /// @param requiredReputation Minimum reputation required for the provider to register this dataset.
    function registerDataset(
        string calldata datasetName,
        string calldata datasetCID,
        uint256 dataLicenseFee,
        uint256 qualityScore,
        uint256 requiredReputation
    ) public whenNotPaused hasEnoughReputation(requiredReputation) {
        uint256 newDatasetId = nextDatasetId++;
        datasets[newDatasetId] = Dataset({
            id: newDatasetId,
            provider: msg.sender,
            name: datasetName,
            datasetCID: datasetCID,
            licenseFee: dataLicenseFee,
            qualityScore: qualityScore,
            registeredAt: block.timestamp,
            isActive: true,
            requiredReputation: requiredReputation
        });
        datasetIdsByProvider[msg.sender].push(newDatasetId);
        emit DatasetRegistered(newDatasetId, msg.sender, datasetName, dataLicenseFee, qualityScore);
    }

    /// @notice Allows a data provider to modify the licensing fee or metadata of their registered dataset.
    /// @param datasetId The ID of the dataset to update.
    /// @param newDataLicenseFee The new license fee.
    function updateDatasetDetails(uint256 datasetId, uint256 newDataLicenseFee) public whenNotPaused {
        Dataset storage dataset = datasets[datasetId];
        if (dataset.provider == address(0)) revert DatasetNotFound();
        if (dataset.provider != msg.sender) revert NotDatasetProvider();

        dataset.licenseFee = newDataLicenseFee;
        emit DatasetUpdated(datasetId, newDataLicenseFee);
    }

    /// @notice Enables a user to license a specific dataset for a fee, primarily for training purposes.
    /// @param datasetId The ID of the dataset to license.
    /// @param licensee The address acquiring the license.
    function licenseDataset(uint256 datasetId, address licensee) public whenNotPaused {
        Dataset storage dataset = datasets[datasetId];
        if (dataset.provider == address(0) || !dataset.isActive) revert DatasetNotFound();
        if (dataset.licenseFee == 0) revert InvalidAmount();
        if (datasetLicenses[datasetId][licensee]) revert AlreadyLicensed();

        if (!nativeToken.transferFrom(msg.sender, address(this), dataset.licenseFee)) revert InsufficientBalance();

        uint256 serviceFee = (dataset.licenseFee * serviceFeeRate) / 10000;
        totalProtocolFees += serviceFee; // Collect protocol fee
        uint252 netFeeToProvider = dataset.licenseFee - serviceFee;

        datasetLicenses[datasetId][licensee] = true;
        if (!nativeToken.transfer(dataset.provider, netFeeToProvider)) revert InsufficientBalance();
        emit DatasetLicensed(datasetId, licensee, netFeeToProvider);
    }

    /// @notice Users can report issues with a dataset, potentially leading to a review and reputation adjustment for the data provider.
    /// @dev This function does not automatically adjust reputation; it merely records the report.
    /// A more complex system would have a dispute resolution or governance vote.
    /// @param datasetId The ID of the dataset with the issue.
    /// @param issueDescription A detailed description of the reported issue.
    function reportDataQualityIssue(uint256 datasetId, string calldata issueDescription) public whenNotPaused {
        Dataset storage dataset = datasets[datasetId];
        if (dataset.provider == address(0)) revert DatasetNotFound();

        emit DataQualityIssueReported(datasetId, msg.sender, issueDescription);
        // An automated system could reduce dataset.qualityScore and/or provider's reputation here based on severity.
    }

    /// @notice Retrieves all public details of a registered dataset.
    /// @param datasetId The ID of the dataset to query.
    /// @return A tuple containing dataset details.
    function getDatasetDetails(
        uint256 datasetId
    )
        public
        view
        returns (
            uint256 id,
            address provider,
            string memory name,
            string memory datasetCID,
            uint256 licenseFee,
            uint256 qualityScore,
            uint256 registeredAt,
            bool isActive,
            uint256 requiredReputation
        )
    {
        Dataset storage dataset = datasets[datasetId];
        if (dataset.provider == address(0)) revert DatasetNotFound();

        return (
            dataset.id,
            dataset.provider,
            dataset.name,
            dataset.datasetCID,
            dataset.licenseFee,
            dataset.qualityScore,
            dataset.registeredAt,
            dataset.isActive,
            dataset.requiredReputation
        );
    }

    // --- V. Collaborative Training & Reward Distribution ---

    /// @dev Represents an AI model training task.
    struct TrainingTask {
        uint256 id;                         /// Unique identifier for the task.
        address proposer;                   /// Address of the user who proposed the task.
        string description;                 /// Description of the training task.
        uint256 rewardPool;                 /// Total native tokens allocated for rewards.
        uint256 requiredDataReputation;     /// Min reputation for data providers to contribute.
        uint256 requiredComputeReputation;  /// Min reputation for compute providers to offer resources.
        bool isActive;                      /// True if the task is open for contributions.
        uint256 createdAt;                  /// Timestamp when the task was created.
        uint256[] contributingDatasets;     /// List of dataset IDs contributed to this task.
        address[] contributingComputeProviders; /// List of compute provider addresses for this task.
        mapping(uint256 => bool) hasDatasetContributed; // Track unique dataset contributions
        mapping(address => bool) hasComputeContributed; // Track unique compute contributions
    }

    /// @notice Counter for unique training task IDs.
    uint256 public nextTrainingTaskId;

    /// @notice Maps training task IDs to their `TrainingTask` struct.
    mapping(uint256 => TrainingTask) public trainingTasks;

    /// @dev Emitted when a new training task is proposed.
    /// @param taskId The ID of the new task.
    /// @param proposer The address of the task proposer.
    /// @param rewardPool The total reward pool amount.
    event TrainingTaskProposed(uint256 indexed taskId, address indexed proposer, uint256 rewardPool);
    /// @dev Emitted when a dataset is contributed to a training task.
    /// @param taskId The ID of the task.
    /// @param datasetId The ID of the contributed dataset.
    /// @param contributor The address of the data provider.
    event DatasetContributedToTask(uint256 indexed taskId, uint256 indexed datasetId, address indexed contributor);
    /// @dev Emitted when compute resources are offered for a training task.
    /// @param taskId The ID of the task.
    /// @param computeProvider The address of the compute provider.
    /// @param stakeAmount The amount staked by the compute provider.
    event ComputeOfferedForTask(uint256 indexed taskId, address indexed computeProvider, uint256 stakeAmount);
    /// @dev Emitted when training rewards are distributed.
    /// @param taskId The ID of the task.
    /// @param recipients An array of addresses receiving rewards.
    /// @param amounts An array of corresponding reward amounts.
    event TrainingRewardsDistributed(uint256 indexed taskId, address[] recipients, uint256[] amounts);
    /// @dev Emitted when an updated model is submitted with training proof.
    /// @param modelId The ID of the updated model.
    /// @param newModelCID The CID of the new model version.
    /// @param trainingProofHash The hash of the training integrity proof.
    event ModelUpdateSubmitted(uint256 indexed modelId, string newModelCID, bytes32 trainingProofHash);

    /// @notice A user proposes a collaborative AI model training task, setting requirements and funding a reward pool.
    /// @param taskDescription A description of the training task.
    /// @param requiredDataReputation Minimum reputation for data providers to contribute.
    /// @param requiredComputeReputation Minimum reputation for compute providers to offer resources.
    /// @param rewardPool Amount of native tokens to fund the task's reward pool.
    function proposeTrainingTask(
        string calldata taskDescription,
        uint256 requiredDataReputation,
        uint256 requiredComputeReputation,
        uint256 rewardPool
    ) public whenNotPaused {
        if (rewardPool == 0) revert InvalidAmount();
        if (!nativeToken.transferFrom(msg.sender, address(this), rewardPool)) revert InsufficientBalance();

        uint256 newTaskId = nextTrainingTaskId++;
        trainingTasks[newTaskId] = TrainingTask({
            id: newTaskId,
            proposer: msg.sender,
            description: taskDescription,
            rewardPool: rewardPool,
            requiredDataReputation: requiredDataReputation,
            requiredComputeReputation: requiredComputeReputation,
            isActive: true,
            createdAt: block.timestamp,
            contributingDatasets: new uint256[](0),
            contributingComputeProviders: new address[](0)
        });
        // Initialize internal mappings for unique contributions (can't do it directly in struct init in ^0.8.0)
        // Accessing them later will lazy-initialize them.
        emit TrainingTaskProposed(newTaskId, msg.sender, rewardPool);
    }

    /// @notice Data providers contribute their registered datasets to an ongoing training task.
    /// @param taskId The ID of the training task.
    /// @param datasetId The ID of the dataset to contribute.
    function contributeToTrainingTask(uint256 taskId, uint256 datasetId) public whenNotPaused {
        TrainingTask storage task = trainingTasks[taskId];
        if (task.proposer == address(0) || !task.isActive) revert TrainingTaskNotFound();

        Dataset storage dataset = datasets[datasetId];
        if (dataset.provider == address(0) || !dataset.isActive) revert DatasetNotFound();
        if (dataset.provider != msg.sender) revert NotDatasetProvider();
        if (task.hasDatasetContributed[datasetId]) revert InvalidState(); // Dataset already contributed

        if (reputations[msg.sender] < task.requiredDataReputation) {
            revert InsufficientReputation(reputations[msg.sender], task.requiredDataReputation);
        }

        task.contributingDatasets.push(datasetId);
        task.hasDatasetContributed[datasetId] = true;
        emit DatasetContributedToTask(taskId, datasetId, msg.sender);
    }

    /// @notice Compute providers register their intent to offer computational resources for a specific training task.
    /// @dev Compute providers typically stake tokens to secure their participation. This stake is added to the reward pool.
    /// @param taskId The ID of the training task.
    /// @param stakeAmount The amount of tokens the compute provider stakes.
    function offerComputeForTraining(uint256 taskId, uint256 stakeAmount) public whenNotPaused {
        TrainingTask storage task = trainingTasks[taskId];
        if (task.proposer == address(0) || !task.isActive) revert TrainingTaskNotFound();
        if (stakeAmount == 0) revert InvalidAmount();
        if (task.hasComputeContributed[msg.sender]) revert InvalidState(); // Already contributed compute

        if (reputations[msg.sender] < task.requiredComputeReputation) {
            revert InsufficientReputation(reputations[msg.sender], task.requiredComputeReputation);
        }

        if (!nativeToken.transferFrom(msg.sender, address(this), stakeAmount)) revert InsufficientBalance();
        task.rewardPool += stakeAmount; // Add stake to task's reward pool
        task.contributingComputeProviders.push(msg.sender);
        task.hasComputeContributed[msg.sender] = true;
        emit ComputeOfferedForTask(taskId, msg.sender, stakeAmount);
    }

    /// @notice Facilitates the distribution of rewards from a completed training task to participating data and compute providers.
    /// @dev This function is intended to be called by the `task.proposer` or an approved oracle/governance post-verification.
    /// @param taskId The ID of the task for which rewards are being distributed.
    /// @param recipients An array of addresses receiving rewards.
    /// @param amounts An array of corresponding reward amounts.
    function distributeTrainingRewards(
        uint256 taskId,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) public whenNotPaused {
        TrainingTask storage task = trainingTasks[taskId];
        if (task.proposer == address(0)) revert TrainingTaskNotFound();
        if (!task.isActive) revert InvalidState(); // Task must be active to distribute rewards
        if (msg.sender != task.proposer && msg.sender != owner()) revert UnauthorizedAction(); // Only proposer or owner can distribute for now

        if (recipients.length != amounts.length) revert InvalidAmount();

        uint252 totalDistributed = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            if (recipients[i] == address(0)) revert ZeroAddress();
            totalDistributed += amounts[i];
        }

        if (totalDistributed > task.rewardPool) revert InvalidAmount(); // Cannot distribute more than available

        task.rewardPool -= totalDistributed; // Reduce pool by distributed amount
        task.isActive = false; // Mark task as completed after distribution

        for (uint256 i = 0; i < recipients.length; i++) {
            if (amounts[i] > 0) {
                if (!nativeToken.transfer(recipients[i], amounts[i])) revert InsufficientBalance();
                // Reward reputation for successful contribution (e.g., 1 reputation per 100 tokens rewarded)
                reputations[recipients[i]] += amounts[i] / 100;
            }
        }

        // Refund any remaining reward pool balance to the task proposer
        if (task.rewardPool > 0) {
            if (!nativeToken.transfer(task.proposer, task.rewardPool)) revert InsufficientBalance();
            task.rewardPool = 0; // Clear the pool after refund
        }

        emit TrainingRewardsDistributed(taskId, recipients, amounts);
    }

    /// @notice Allows a model developer to submit an updated version of a model, citing a successful collaborative training task and an integrity proof.
    /// @dev This function assumes the `msg.sender` is the original model provider or an authorized updater.
    /// @param modelId The ID of the model to be updated.
    /// @param newModelCID The Content Identifier for the new, updated model version.
    /// @param trainingProofHash A hash representing the integrity proof of the training process (e.g., ZK-proof).
    function submitModelUpdateProof(
        uint256 modelId,
        string calldata newModelCID,
        bytes32 trainingProofHash
    ) public whenNotPaused {
        AIModel storage model = models[modelId];
        if (model.provider == address(0)) revert ModelNotFound();
        if (model.provider != msg.sender) revert NotModelProvider();

        model.modelCID = newModelCID;
        // The `trainingProofHash` is recorded but not verified on-chain due to complexity and gas costs.
        // Off-chain verification by a network of validators or oracles would be required to ensure the proof's validity.

        emit ModelUpdateSubmitted(modelId, newModelCID, trainingProofHash);
    }
}
```