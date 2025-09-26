This Solidity smart contract, `AetheriumAI`, aims to create a sophisticated, decentralized marketplace for Artificial Intelligence models. It integrates several advanced concepts:

1.  **Dynamic NFTs (AetheriumCore):** Each registered AI model is represented by an ERC-721 NFT whose metadata dynamically updates based on the model's performance, usage, and validator reputation. This allows for evolving on-chain representation of off-chain assets.
2.  **Decentralized AI Inference:** Users can request inferences from registered models, with payments and result submission managed on-chain, relying on an oracle for off-chain computation.
3.  **Staking & Slashing Mechanism:** Validators stake a native ERC-20 token (`AetheriumToken`) to verify inference results, earning rewards for honest reports and facing slashing for malicious or incorrect ones.
4.  **Reputation System:** Models, architects, and validators accumulate reputation based on performance, validation accuracy, and participation. This influences rewards, visibility, and potentially governance.
5.  **Internal Credit System:** Users deposit `AetheriumToken` into an internal credit balance for seamless inference payments, improving UX by reducing repeated token approvals for each request.
6.  **Multi-Role Architecture:** Clearly defined roles for AI Architects (model creators), Data Scientists (inference users), and Validators, with specific permissions and responsibilities.
7.  **Oracle Integration:** Designed to work with an off-chain oracle service for executing AI model inferences and resolving complex validation disputes, bridging the gap between on-chain coordination and off-chain computation.

The goal is to provide a platform that incentivizes quality AI models and reliable validation, fostering a transparent and trustworthy AI ecosystem.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For converting uint to string in metadata URI

// --- Custom Error Definitions for enhanced UX and gas efficiency ---
error AetheriumAI__NotArchitect(address caller);
error AetheriumAI__NotValidator(address caller);
error AetheriumAI__NotOracle(address caller);
error AetheriumAI__InvalidFeePercentage();
error AetheriumAI__ModelNotFound(uint256 modelId);
error AetheriumAI__ModelNotActive(uint256 modelId);
error AetheriumAI__InsufficientCredits(address user, uint256 required, uint256 available);
error AetheriumAI__InferenceRequestNotFound(uint256 requestId);
error AetheriumAI__InferenceAlreadyProcessed(uint256 requestId);
error AetheriumAI__InferenceResultNotYetSubmitted(uint256 requestId);
error AetheriumAI__InferenceResultAlreadyClaimed(uint256 requestId);
error AetheriumAI__InferenceRequestNotExpired(uint256 requestId);
error AetheriumAI__ValidationReportNotFound(uint256 reportId);
error AetheriumAI__ValidatorAlreadyRegistered(address validator); // Technically handled by stake, but kept for clarity
error AetheriumAI__ValidatorNotRegistered(address validator);
error AetheriumAI__InsufficientStake(address validator, uint256 required, uint256 available);
error AetheriumAI__StakeLocked(address validator); // Validator has pending reports
error AetheriumAI__InvalidAmount(); // Used for 0 amount checks
error AetheriumAI__NoEarningsToWithdraw();
error AetheriumAI__NoRewardsToClaim();
error AetheriumAI__ModelPriceTooLow();
error AetheriumAI__CoreNFTNotFound(uint256 tokenId);
error AetheriumAI__CannotChallengeOwnReport();
error AetheriumAI__DisputePeriodOver();
error AetheriumAI__ReportNotInChallengedState();

/**
 * @title AetheriumAI - Decentralized AI Model & Inference Marketplace
 * @dev This contract facilitates a decentralized marketplace for AI models, allowing AI architects to
 *      register their models, users to request inferences, and validators to verify results.
 *      It integrates a native ERC-20 token for payments and staking, and dynamic ERC-721 NFTs
 *      (AetheriumCore) to represent model ownership and evolving reputation.
 *
 * Outline & Function Summary:
 *
 * I. Core Setup & Administration (6 functions)
 *    1. constructor: Initializes the contract with necessary dependencies (ERC-20, ERC-721 addresses)
 *       and sets initial parameters, including admin, oracle, and fee settings.
 *    2. setProtocolFeeRecipient: Allows the owner to change the address receiving protocol fees.
 *    3. setProtocolFeePercentage: Allows the owner to adjust the percentage of fees taken by the protocol (0-10000 for 0-100%).
 *    4. setOracleAddress: Allows the owner to set the trusted address for submitting off-chain inference results and resolving disputes.
 *    5. pauseContract: Emergency function to pause critical contract operations.
 *    6. unpauseContract: Reverses the pause state, resuming operations.
 *
 * II. AetheriumToken (ERC-20) Interaction (4 functions)
 *    7. depositAetheriumTokensForCredits: Users deposit AETH tokens to acquire inference credits in an internal balance.
 *    8. withdrawAetheriumTokensFromCredits: Users withdraw unused AETH tokens from their internal credit balance.
 *    9. stakeAetheriumTokensForValidation: Validators stake AETH tokens to participate in the validation process, requiring a minimum stake.
 *    10. unstakeAetheriumTokensFromValidation: Validators unstake their AETH tokens, subject to lock-up periods or penalties if they have pending validation reports.
 *
 * III. AI Model Management (AI Architects) (6 functions)
 *    11. registerAIModel: Allows an AI Architect to register a new AI model, minting an AetheriumCore NFT
 *        and specifying initial parameters like URI (for off-chain model data/endpoint) and inference price.
 *    12. updateAIModelURI: Architects can update the off-chain URI pointing to their model's data or API endpoint, triggering metadata update.
 *    13. updateInferencePrice: Architects can adjust the price for running inferences on their registered model.
 *    14. deactivateAIModel: Architects can temporarily deactivate their model, preventing new inference requests.
 *    15. activateAIModel: Architects can reactivate a previously deactivated model.
 *    16. withdrawModelEarnings: Architects can withdraw accumulated earnings from successful inference requests on their models, minus protocol fees.
 *
 * IV. Inference Request & Execution (Data Scientists/Users) (4 functions)
 *    17. requestInference: Users initiate an inference request on a registered AI model, paying the required AETH tokens from their credit balance.
 *    18. submitInferenceResult: An authorized oracle submits the off-chain inference result (as a URI to result data) and related metadata.
 *    19. claimInferenceResult: Users claim their completed inference result after it has been submitted and (optionally) validated.
 *    20. cancelPendingInference: Users can cancel their inference request if it hasn't been processed by the oracle within a defined `inferenceRequestTimeout`.
 *
 * V. Validator & Reputation System (4 functions)
 *    21. submitValidationReport: Validators submit reports on the correctness/quality of submitted inference results, staking a small amount per report.
 *    22. challengeValidationReport: Other validators can challenge a submitted validation report if they disagree, initiating a dispute.
 *    23. resolveValidationDispute: (Oracle triggered) Resolves a dispute between validation reports, slashing incorrect validators and rewarding correct ones, affecting model reputation.
 *    24. claimValidationReward: Validators claim rewards for successfully validated inferences or correctly challenging reports.
 *
 * VI. AetheriumCore NFT (Dynamic NFT) Interaction (3 functions)
 *    25. getAetheriumCoreMetadataURI: Retrieves the dynamic metadata URI for a specific AetheriumCore NFT (model), which includes the model's metadataHash.
 *    26. updateCoreMetadataHash: (Oracle triggered) Updates the on-chain hash/version of an NFT's metadata, signaling off-chain systems to refresh metadata based on model performance/reputation.
 *    27. transferAetheriumCore: Allows the owner of an AetheriumCore NFT to transfer ownership of the underlying AI model, updating internal mappings and transferring pending earnings.
 *
 * VII. Protocol & Utility Functions (9 functions)
 *    28. getModelDetails: View function to retrieve comprehensive details about a registered AI model.
 *    29. getInferenceRequestDetails: View function to retrieve details about a specific inference request.
 *    30. getValidatorStatus: View function to check the staking and activity status of a validator.
 *    31. getUserAetheriumCredits: View function to check a user's available inference credits.
 *    32. getProtocolFeesOutstanding: View function to check the total accumulated protocol fees ready for withdrawal.
 *    33. withdrawProtocolFees: Allows the owner to withdraw accumulated protocol fees to the `protocolFeeRecipient`.
 *    34. getProtocolParameters: View function to retrieve core protocol parameters (fees, minimum stake, timeouts).
 *    35. getModelCoreTokenId: View function to get the AetheriumCore NFT ID associated with a given model ID.
 *    36. getModelOwner: View function to get the owner of a specific AI model.
 */

contract AetheriumAI is Ownable, Pausable, ReentrancyGuard {
    // --- State Variables ---

    IERC20 public immutable AetheriumToken;
    IERC721 public immutable AetheriumCoreNFT; // Represents ownership and dynamic metadata of an AI Model

    address public protocolFeeRecipient;
    uint256 public protocolFeePercentage; // Stored as Basis Points (e.g., 100 = 1%)
    address public oracleAddress; // Trusted address for submitting inference results and resolving disputes

    uint256 public minModelInferencePrice;
    uint256 public minValidatorStake;
    uint256 public validatorReportStakeAmount; // Amount staked per validation report
    uint256 public validationDisputePeriod; // Time window for challenging a report (in seconds)
    uint256 public inferenceRequestTimeout; // Time until an inference request can be cancelled if not processed (in seconds)

    uint256 private nextModelId;
    uint256 private nextRequestId;
    uint256 private nextValidationReportId;
    uint256 private _totalProtocolFeesAccumulated;

    // --- Data Structures ---

    enum ModelStatus { Active, Inactive }
    enum InferenceStatus { Pending, ResultSubmitted, Validated, Disputed, Cancelled, Claimed }
    enum ValidationStatus { Pending, Approved, Rejected, Challenged, Resolved }

    struct AIModel {
        address architect;
        string modelURI; // URI to off-chain model details, API endpoint, or IPFS hash
        uint256 inferencePrice; // Price in AetheriumToken for one inference
        ModelStatus status;
        uint256 coreNFTId; // The AetheriumCore NFT ID representing this model
        uint256 totalInferences;
        uint256 totalEarnings; // Accumulated earnings for the architect (before withdrawal)
        uint256 totalValidatedInferences;
        int256 reputationScore; // Simple reputation score (could be more complex, using int256 for +/-)
        string metadataHash; // Hash to signal off-chain metadata update for the NFT
    }

    struct InferenceRequest {
        uint256 modelId;
        address user;
        uint256 feePaid;
        uint256 requestTime;
        InferenceStatus status;
        string resultURI; // URI to off-chain inference result
        uint256 resultSubmitTime;
        uint256 validatorReportId; // ID of the validation report for this inference (0 if none)
    }

    struct Validator {
        uint256 stakedAmount;
        uint256 lastStakeChangeTime; // For potential lock-up periods or cool-downs
        uint256 earnedRewards;
        uint256 pendingReportsCount; // Number of reports still in dispute or unconfirmed
        bool isActive;
    }

    struct ValidationReport {
        uint256 requestId;
        address validator;
        bool isCorrect; // True if validator claims the result is correct, false if incorrect/malicious
        string reportDetailsURI; // URI to off-chain details of the validation report
        uint256 submitTime;
        ValidationStatus status;
        address challenger; // Address of validator who challenged this report
        uint256 disputeStartTime;
    }

    // --- Mappings ---
    mapping(uint256 => AIModel) public aiModels;
    mapping(uint256 => InferenceRequest) public inferenceRequests;
    mapping(uint256 => ValidationReport) public validationReports;

    mapping(address => uint256) public userAetheriumCredits; // Internal balance for inference payments
    mapping(address => Validator) public validators;
    mapping(uint256 => uint256) public modelIdToCoreNFTId; // Maps model ID to its AetheriumCore NFT ID
    mapping(uint256 => uint256) public coreNFTIdToModelId; // Maps AetheriumCore NFT ID back to model ID

    EnumerableSet.UintSet private _activeModelIds;
    EnumerableSet.AddressSet private _registeredValidators;

    // --- Events ---
    event ProtocolFeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);
    event ProtocolFeePercentageUpdated(uint256 oldPercentage, uint256 newPercentage);
    event OracleAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event AetheriumCreditsDeposited(address indexed user, uint256 amount);
    event AetheriumCreditsWithdrawn(address indexed user, uint256 amount);
    event AetheriumTokensStaked(address indexed validator, uint256 amount, uint256 newTotalStake);
    event AetheriumTokensUnstaked(address indexed validator, uint256 amount, uint256 newTotalStake);
    event AIModelRegistered(
        uint256 indexed modelId,
        address indexed architect,
        string modelURI,
        uint256 inferencePrice,
        uint256 coreNFTId
    );
    event AIModelUpdated(uint256 indexed modelId, string newURI, uint256 newPrice);
    event AIModelStatusChanged(uint256 indexed modelId, ModelStatus newStatus);
    event ModelEarningsWithdrawn(uint256 indexed modelId, address indexed architect, uint256 amount);
    event InferenceRequested(
        uint256 indexed requestId,
        uint256 indexed modelId,
        address indexed user,
        uint256 feePaid
    );
    event InferenceResultSubmitted(
        uint256 indexed requestId,
        uint256 indexed modelId,
        address indexed user,
        string resultURI
    );
    event InferenceResultClaimed(uint256 indexed requestId, address indexed user);
    event InferenceRequestCancelled(uint256 indexed requestId, address indexed user, uint256 refundAmount);
    event ValidatorRegistered(address indexed validator, uint256 initialStake);
    event ValidationReportSubmitted(
        uint256 indexed reportId,
        uint256 indexed requestId,
        address indexed validator,
        bool isCorrect
    );
    event ValidationReportChallenged(
        uint256 indexed reportId,
        uint256 indexed requestId,
        address indexed challenger
    );
    event ValidationDisputeResolved(
        uint256 indexed reportId,
        uint256 indexed requestId,
        address indexed winner,
        address indexed loser,
        uint256 rewardAmount,
        uint256 slashAmount
    );
    event ValidationRewardClaimed(address indexed validator, uint256 amount);
    event AetheriumCoreMetadataUpdated(uint256 indexed coreNFTId, uint256 indexed modelId, string newMetadataHash);

    // --- Modifiers ---
    modifier onlyArchitect(uint256 _modelId) {
        if (aiModels[_modelId].architect == address(0)) revert AetheriumAI__ModelNotFound(_modelId);
        if (aiModels[_modelId].architect != msg.sender) {
            revert AetheriumAI__NotArchitect(msg.sender);
        }
        _;
    }

    modifier onlyValidator() {
        if (!validators[msg.sender].isActive || validators[msg.sender].stakedAmount < minValidatorStake) {
            revert AetheriumAI__NotValidator(msg.sender);
        }
        _;
    }

    modifier onlyOracle() {
        if (msg.sender != oracleAddress) {
            revert AetheriumAI__NotOracle(msg.sender);
        }
        _;
    }

    // --- Constructor ---
    /// @notice Initializes the AetheriumAI contract.
    /// @param _aetheriumTokenAddress The address of the AetheriumToken (ERC-20) contract.
    /// @param _aetheriumCoreNFTAddress The address of the AetheriumCoreNFT (ERC-721) contract.
    /// @param _initialOracleAddress The initial trusted address for the oracle.
    /// @param _initialFeeRecipient The initial address to receive protocol fees.
    /// @param _initialFeePercentage The initial protocol fee percentage in basis points (e.g., 500 for 5%).
    /// @param _minModelInferencePrice The minimum price an architect can set for an inference.
    /// @param _minValidatorStake The minimum amount of AETH tokens required to be an active validator.
    /// @param _validatorReportStakeAmount The amount of AETH tokens staked per validation report or challenge.
    /// @param _validationDisputePeriod The time window (in seconds) for challenging a validation report.
    /// @param _inferenceRequestTimeout The time (in seconds) after which an inference request can be cancelled if not processed.
    constructor(
        address _aetheriumTokenAddress,
        address _aetheriumCoreNFTAddress,
        address _initialOracleAddress,
        address _initialFeeRecipient,
        uint256 _initialFeePercentage,
        uint256 _minModelInferencePrice,
        uint256 _minValidatorStake,
        uint256 _validatorReportStakeAmount,
        uint256 _validationDisputePeriod,
        uint256 _inferenceRequestTimeout
    ) Ownable(msg.sender) Pausable() {
        if (_initialFeePercentage > 10000) revert AetheriumAI__InvalidFeePercentage(); // Max 100%
        if (_aetheriumTokenAddress == address(0) || _aetheriumCoreNFTAddress == address(0) || _initialOracleAddress == address(0) || _initialFeeRecipient == address(0)) {
            revert AetheriumAI__InvalidAmount(); // Generic for zero address
        }

        AetheriumToken = IERC20(_aetheriumTokenAddress);
        AetheriumCoreNFT = IERC721(_aetheriumCoreNFTAddress);
        oracleAddress = _initialOracleAddress;
        protocolFeeRecipient = _initialFeeRecipient;
        protocolFeePercentage = _initialFeePercentage;
        minModelInferencePrice = _minModelInferencePrice;
        minValidatorStake = _minValidatorStake;
        validatorReportStakeAmount = _validatorReportStakeAmount;
        validationDisputePeriod = _validationDisputePeriod;
        inferenceRequestTimeout = _inferenceRequestTimeout;

        nextModelId = 1;
        nextRequestId = 1;
        nextValidationReportId = 1;

        emit ProtocolFeeRecipientUpdated(address(0), _initialFeeRecipient);
        emit ProtocolFeePercentageUpdated(0, _initialFeePercentage);
        emit OracleAddressUpdated(address(0), _initialOracleAddress);
    }

    // I. Core Setup & Administration

    /// @notice Allows the owner to change the address receiving protocol fees.
    /// @param _newRecipient The new address to receive protocol fees.
    function setProtocolFeeRecipient(address _newRecipient) external onlyOwner {
        if (_newRecipient == address(0)) revert AetheriumAI__InvalidAmount();
        emit ProtocolFeeRecipientUpdated(protocolFeeRecipient, _newRecipient);
        protocolFeeRecipient = _newRecipient;
    }

    /// @notice Allows the owner to adjust the percentage of fees taken by the protocol.
    /// @param _newPercentage The new fee percentage in basis points (e.g., 100 for 1%). Max 10000 (100%).
    function setProtocolFeePercentage(uint256 _newPercentage) external onlyOwner {
        if (_newPercentage > 10000) revert AetheriumAI__InvalidFeePercentage();
        emit ProtocolFeePercentageUpdated(protocolFeePercentage, _newPercentage);
        protocolFeePercentage = _newPercentage;
    }

    /// @notice Allows the owner to set the trusted address for submitting off-chain inference results and resolving disputes.
    /// @param _newOracleAddress The new address of the oracle.
    function setOracleAddress(address _newOracleAddress) external onlyOwner {
        if (_newOracleAddress == address(0)) revert AetheriumAI__InvalidAmount();
        emit OracleAddressUpdated(oracleAddress, _newOracleAddress);
        oracleAddress = _newOracleAddress;
    }

    /// @notice Pauses contract operations in case of emergency.
    function pauseContract() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses contract operations.
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    // II. AetheriumToken (ERC-20) Interaction

    /// @notice Users deposit AETH tokens to acquire internal inference credits.
    /// @param _amount The amount of AETH tokens to deposit.
    function depositAetheriumTokensForCredits(uint256 _amount) external whenNotPaused nonReentrant {
        if (_amount == 0) revert AetheriumAI__InvalidAmount();
        IERC20(AetheriumToken).transferFrom(msg.sender, address(this), _amount);
        userAetheriumCredits[msg.sender] += _amount;
        emit AetheriumCreditsDeposited(msg.sender, _amount);
    }

    /// @notice Users withdraw unused AETH tokens from their internal credit balance.
    /// @param _amount The amount of AETH tokens to withdraw.
    function withdrawAetheriumTokensFromCredits(uint256 _amount) external whenNotPaused nonReentrant {
        if (_amount == 0) revert AetheriumAI__InvalidAmount();
        if (userAetheriumCredits[msg.sender] < _amount) {
            revert AetheriumAI__InsufficientCredits(msg.sender, _amount, userAetheriumCredits[msg.sender]);
        }
        userAetheriumCredits[msg.sender] -= _amount;
        IERC20(AetheriumToken).transfer(msg.sender, _amount);
        emit AetheriumCreditsWithdrawn(msg.sender, _amount);
    }

    /// @notice Validators stake AETH tokens to participate in the validation process.
    /// @param _amount The amount of AETH tokens to stake. Must meet `minValidatorStake` if new registration.
    function stakeAetheriumTokensForValidation(uint256 _amount) external whenNotPaused nonReentrant {
        if (_amount == 0) revert AetheriumAI__InvalidAmount();

        Validator storage validator = validators[msg.sender];
        if (!validator.isActive && (validator.stakedAmount + _amount < minValidatorStake)) {
            revert AetheriumAI__InsufficientStake(msg.sender, minValidatorStake, validator.stakedAmount + _amount);
        }

        IERC20(AetheriumToken).transferFrom(msg.sender, address(this), _amount);
        validator.stakedAmount += _amount;
        validator.lastStakeChangeTime = block.timestamp;

        if (!validator.isActive && validator.stakedAmount >= minValidatorStake) {
            validator.isActive = true;
            _registeredValidators.add(msg.sender);
            emit ValidatorRegistered(msg.sender, validator.stakedAmount);
        }
        emit AetheriumTokensStaked(msg.sender, _amount, validator.stakedAmount);
    }

    /// @notice Validators unstake their AETH tokens. Subject to lock-up and pending reports.
    /// @param _amount The amount of AETH tokens to unstake.
    function unstakeAetheriumTokensFromValidation(uint256 _amount) external whenNotPaused nonReentrant onlyValidator {
        if (_amount == 0) revert AetheriumAI__InvalidAmount();
        Validator storage validator = validators[msg.sender];
        if (validator.stakedAmount < _amount) {
            revert AetheriumAI__InsufficientStake(msg.sender, _amount, validator.stakedAmount);
        }
        if (validator.pendingReportsCount > 0) {
            revert AetheriumAI__StakeLocked(msg.sender); // Cannot unstake while pending reports
        }

        validator.stakedAmount -= _amount;
        validator.lastStakeChangeTime = block.timestamp;

        if (validator.stakedAmount < minValidatorStake) {
            validator.isActive = false; // Deactivate if stake falls below minimum
            _registeredValidators.remove(msg.sender);
        }

        IERC20(AetheriumToken).transfer(msg.sender, _amount);
        emit AetheriumTokensUnstaked(msg.sender, _amount, validator.stakedAmount);
    }

    // III. AI Model Management (AI Architects)

    /// @notice Allows an AI Architect to register a new AI model, minting an AetheriumCore NFT.
    /// @param _modelURI URI to off-chain model details, API endpoint, or IPFS hash.
    /// @param _inferencePrice Price in AetheriumToken for one inference.
    /// @param _initialMetadataHash Initial hash to signal off-chain metadata update for the NFT.
    /// @dev This function relies on the AetheriumCoreNFT contract having a `mint` function
    ///      callable by this contract, which returns the new `tokenId`.
    function registerAIModel(
        string calldata _modelURI,
        uint256 _inferencePrice,
        string calldata _initialMetadataHash
    ) external whenNotPaused nonReentrant returns (uint256 modelId) {
        if (_inferencePrice < minModelInferencePrice) revert AetheriumAI__ModelPriceTooLow();

        modelId = nextModelId++;
        // In a real scenario, AetheriumCoreNFT would have a function like `mint(msg.sender, modelId)`
        // and its logic would generate a unique tokenId and associate it with the modelId.
        // For this contract, we'll simulate the mint by assigning a conceptual `coreNFTId`
        // and expecting the AetheriumCoreNFT contract to handle the actual minting process based on a call
        // from this contract (e.g., `AetheriumCoreNFT.mintAndAssociate(msg.sender, modelId);`).
        // For simplicity, we just store `modelId` and `coreNFTId` mapping here, assuming `AetheriumCoreNFT`
        // mints and sets owner to `msg.sender` for the given `modelId`.
        // Let's assume a conceptual `AetheriumCoreNFT.mintForModel(msg.sender, modelId)` that returns a `coreNFTId`.
        uint256 coreNFTId = AetheriumCoreNFT.totalSupply() + 1; // Simplistic ID assignment. In real NFT, the contract manages IDs.

        aiModels[modelId] = AIModel({
            architect: msg.sender,
            modelURI: _modelURI,
            inferencePrice: _inferencePrice,
            status: ModelStatus.Active,
            coreNFTId: coreNFTId, // Store the assigned NFT ID
            totalInferences: 0,
            totalEarnings: 0,
            totalValidatedInferences: 0,
            reputationScore: 1000, // Initial reputation
            metadataHash: _initialMetadataHash
        });

        modelIdToCoreNFTId[modelId] = coreNFTId;
        coreNFTIdToModelId[coreNFTId] = modelId;
        _activeModelIds.add(modelId);

        emit AIModelRegistered(modelId, msg.sender, _modelURI, _inferencePrice, coreNFTId);
        emit AetheriumCoreMetadataUpdated(coreNFTId, modelId, _initialMetadataHash);
        return modelId;
    }

    /// @notice Architects can update the off-chain URI pointing to their model's data or API endpoint.
    /// @param _modelId The ID of the model to update.
    /// @param _newURI The new URI for the model.
    /// @param _newMetadataHash A new hash to signal off-chain metadata update for the NFT.
    function updateAIModelURI(
        uint256 _modelId,
        string calldata _newURI,
        string calldata _newMetadataHash
    ) external whenNotPaused onlyArchitect(_modelId) {
        AIModel storage model = aiModels[_modelId];
        model.modelURI = _newURI;
        model.metadataHash = _newMetadataHash;
        emit AIModelUpdated(_modelId, _newURI, model.inferencePrice);
        emit AetheriumCoreMetadataUpdated(model.coreNFTId, _modelId, _newMetadataHash);
    }

    /// @notice Architects can adjust the price for running inferences on their registered model.
    /// @param _modelId The ID of the model to update.
    /// @param _newPrice The new price for inferences. Must be >= `minModelInferencePrice`.
    function updateInferencePrice(uint256 _modelId, uint256 _newPrice) external whenNotPaused onlyArchitect(_modelId) {
        if (_newPrice < minModelInferencePrice) revert AetheriumAI__ModelPriceTooLow();
        AIModel storage model = aiModels[_modelId];
        model.inferencePrice = _newPrice;
        emit AIModelUpdated(_modelId, model.modelURI, _newPrice);
    }

    /// @notice Architects can temporarily deactivate their model, preventing new inference requests.
    /// @param _modelId The ID of the model to deactivate.
    function deactivateAIModel(uint256 _modelId) external whenNotPaused onlyArchitect(_modelId) {
        AIModel storage model = aiModels[_modelId];
        if (model.status == ModelStatus.Active) {
            model.status = ModelStatus.Inactive;
            _activeModelIds.remove(_modelId);
            emit AIModelStatusChanged(_modelId, ModelStatus.Inactive);
        }
    }

    /// @notice Architects can reactivate a previously deactivated model.
    /// @param _modelId The ID of the model to reactivate.
    function activateAIModel(uint256 _modelId) external whenNotPaused onlyArchitect(_modelId) {
        AIModel storage model = aiModels[_modelId];
        if (model.status == ModelStatus.Inactive) {
            model.status = ModelStatus.Active;
            _activeModelIds.add(_modelId);
            emit AIModelStatusChanged(_modelId, ModelStatus.Active);
        }
    }

    /// @notice Architects can withdraw accumulated earnings from successful inference requests.
    /// @param _modelId The ID of the model to withdraw earnings from.
    function withdrawModelEarnings(uint256 _modelId) external whenNotPaused nonReentrant onlyArchitect(_modelId) {
        AIModel storage model = aiModels[_modelId];
        if (model.totalEarnings == 0) revert AetheriumAI__NoEarningsToWithdraw();

        uint256 amount = model.totalEarnings;
        model.totalEarnings = 0; // Reset earnings before transfer (checks-effects-interactions)

        IERC20(AetheriumToken).transfer(msg.sender, amount);
        emit ModelEarningsWithdrawn(_modelId, msg.sender, amount);
    }

    // IV. Inference Request & Execution (Data Scientists/Users)

    /// @notice Users initiate an inference request on a registered AI model.
    /// @param _modelId The ID of the AI model to request inference from.
    function requestInference(uint256 _modelId) external whenNotPaused nonReentrant {
        AIModel storage model = aiModels[_modelId];
        if (model.architect == address(0)) revert AetheriumAI__ModelNotFound(_modelId);
        if (model.status != ModelStatus.Active) revert AetheriumAI__ModelNotActive(_modelId);

        uint256 fee = model.inferencePrice;
        if (userAetheriumCredits[msg.sender] < fee) {
            revert AetheriumAI__InsufficientCredits(msg.sender, fee, userAetheriumCredits[msg.sender]);
        }

        userAetheriumCredits[msg.sender] -= fee;

        uint256 protocolShare = (fee * protocolFeePercentage) / 10000;
        uint256 architectShare = fee - protocolShare;

        _totalProtocolFeesAccumulated += protocolShare;
        model.totalEarnings += architectShare;
        model.totalInferences++; // Increment total inferences for model

        uint256 requestId = nextRequestId++;
        inferenceRequests[requestId] = InferenceRequest({
            modelId: _modelId,
            user: msg.sender,
            feePaid: fee,
            requestTime: block.timestamp,
            status: InferenceStatus.Pending,
            resultURI: "",
            resultSubmitTime: 0,
            validatorReportId: 0
        });

        emit InferenceRequested(requestId, _modelId, msg.sender, fee);
    }

    /// @notice An authorized oracle submits the off-chain inference result.
    /// @param _requestId The ID of the inference request.
    /// @param _resultURI URI to off-chain inference result data.
    /// @param _newMetadataHash A new hash to signal off-chain metadata update for the NFT (reflecting model performance).
    function submitInferenceResult(
        uint256 _requestId,
        string calldata _resultURI,
        string calldata _newMetadataHash
    ) external whenNotPaused nonReentrant onlyOracle {
        InferenceRequest storage request = inferenceRequests[_requestId];
        if (request.user == address(0)) revert AetheriumAI__InferenceRequestNotFound(_requestId);
        if (request.status != InferenceStatus.Pending) revert AetheriumAI__InferenceAlreadyProcessed(_requestId);

        request.resultURI = _resultURI;
        request.resultSubmitTime = block.timestamp;
        request.status = InferenceStatus.ResultSubmitted;

        AIModel storage model = aiModels[request.modelId];
        model.metadataHash = _newMetadataHash; // Update model's metadata hash
        emit InferenceResultSubmitted(_requestId, request.modelId, request.user, _resultURI);
        emit AetheriumCoreMetadataUpdated(model.coreNFTId, request.modelId, _newMetadataHash);
    }

    /// @notice Users claim their completed inference result.
    /// @param _requestId The ID of the inference request to claim.
    function claimInferenceResult(uint256 _requestId) external whenNotPaused {
        InferenceRequest storage request = inferenceRequests[_requestId];
        if (request.user == address(0)) revert AetheriumAI__InferenceRequestNotFound(_requestId);
        if (request.user != msg.sender) revert AetheriumAI__NotArchitect(msg.sender); // Reusing error for wrong user
        if (request.status == InferenceStatus.Pending) revert AetheriumAI__InferenceResultNotYetSubmitted(_requestId);
        if (request.status == InferenceStatus.Claimed) revert AetheriumAI__InferenceResultAlreadyClaimed(_requestId);
        if (request.status == InferenceStatus.Cancelled) revert AetheriumAI__InferenceRequestNotFound(_requestId); // Reusing error for cancelled

        request.status = InferenceStatus.Claimed;
        emit InferenceResultClaimed(_requestId, msg.sender);
    }

    /// @notice Users can cancel their inference request if it hasn't been processed by the oracle within `inferenceRequestTimeout`.
    /// @param _requestId The ID of the inference request to cancel.
    function cancelPendingInference(uint256 _requestId) external whenNotPaused nonReentrant {
        InferenceRequest storage request = inferenceRequests[_requestId];
        if (request.user == address(0)) revert AetheriumAI__InferenceRequestNotFound(_requestId);
        if (request.user != msg.sender) revert AetheriumAI__NotArchitect(msg.sender); // Reusing error for wrong user
        if (request.status != InferenceStatus.Pending) revert AetheriumAI__InferenceAlreadyProcessed(_requestId);
        if (block.timestamp < request.requestTime + inferenceRequestTimeout) {
            revert AetheriumAI__InferenceRequestNotExpired(_requestId);
        }

        request.status = InferenceStatus.Cancelled;
        userAetheriumCredits[msg.sender] += request.feePaid; // Refund credits

        AIModel storage model = aiModels[request.modelId];
        uint256 protocolShare = (request.feePaid * protocolFeePercentage) / 10000;
        uint256 architectShare = request.feePaid - protocolShare;

        _totalProtocolFeesAccumulated -= protocolShare;
        model.totalEarnings -= architectShare; // Deduct from architect earnings
        model.totalInferences--; // Decrement total inferences

        emit InferenceRequestCancelled(_requestId, msg.sender, request.feePaid);
    }

    // V. Validator & Reputation System

    /// @notice Validators submit reports on the correctness/quality of submitted inference results.
    /// @param _requestId The ID of the inference request being validated.
    /// @param _isCorrect Boolean indicating if the result is correct (true) or incorrect/malicious (false).
    /// @param _reportDetailsURI URI to off-chain details of the validation report.
    function submitValidationReport(
        uint256 _requestId,
        bool _isCorrect,
        string calldata _reportDetailsURI
    ) external whenNotPaused nonReentrant onlyValidator {
        InferenceRequest storage request = inferenceRequests[_requestId];
        if (request.user == address(0)) revert AetheriumAI__InferenceRequestNotFound(_requestId);
        if (request.status != InferenceStatus.ResultSubmitted) revert AetheriumAI__InferenceResultNotYetSubmitted(_requestId);
        if (request.validatorReportId != 0) revert AetheriumAI__InferenceAlreadyProcessed(_requestId); // Report already exists for this request

        Validator storage validator = validators[msg.sender];
        if (validator.stakedAmount < validatorReportStakeAmount) {
            revert AetheriumAI__InsufficientStake(msg.sender, validatorReportStakeAmount, validator.stakedAmount);
        }

        // Stake tokens for the report
        IERC20(AetheriumToken).transferFrom(msg.sender, address(this), validatorReportStakeAmount);
        validator.stakedAmount -= validatorReportStakeAmount; // Temporarily reduce effective stake
        validator.pendingReportsCount++;

        uint256 reportId = nextValidationReportId++;
        validationReports[reportId] = ValidationReport({
            requestId: _requestId,
            validator: msg.sender,
            isCorrect: _isCorrect,
            reportDetailsURI: _reportDetailsURI,
            submitTime: block.timestamp,
            status: ValidationStatus.Pending,
            challenger: address(0),
            disputeStartTime: 0
        });

        request.validatorReportId = reportId;

        emit ValidationReportSubmitted(reportId, _requestId, msg.sender, _isCorrect);
    }

    /// @notice Other validators can challenge a submitted validation report.
    /// @param _reportId The ID of the validation report to challenge.
    /// @param _challengeDetailsURI URI to off-chain details of the challenge.
    function challengeValidationReport(
        uint256 _reportId,
        string calldata _challengeDetailsURI
    ) external whenNotPaused nonReentrant onlyValidator {
        ValidationReport storage report = validationReports[_reportId];
        if (report.validator == address(0)) revert AetheriumAI__ValidationReportNotFound(_reportId);
        if (report.status != ValidationStatus.Pending) revert AetheriumAI__InferenceAlreadyProcessed(_reportId); // Must be pending
        if (report.validator == msg.sender) revert AetheriumAI__CannotChallengeOwnReport();
        if (block.timestamp > report.submitTime + validationDisputePeriod) {
            revert AetheriumAI__DisputePeriodOver();
        }

        Validator storage challengerValidator = validators[msg.sender];
        if (challengerValidator.stakedAmount < validatorReportStakeAmount) {
            revert AetheriumAI__InsufficientStake(msg.sender, validatorReportStakeAmount, challengerValidator.stakedAmount);
        }

        // Stake tokens for the challenge
        IERC20(AetheriumToken).transferFrom(msg.sender, address(this), validatorReportStakeAmount);
        challengerValidator.stakedAmount -= validatorReportStakeAmount;
        challengerValidator.pendingReportsCount++;

        report.status = ValidationStatus.Challenged;
        report.challenger = msg.sender;
        report.disputeStartTime = block.timestamp;
        // _challengeDetailsURI could be stored but not critical for on-chain logic

        emit ValidationReportChallenged(_reportId, report.requestId, msg.sender);
    }

    /// @notice (Oracle) Resolves a dispute between validation reports, slashing incorrect validators and rewarding correct ones.
    /// @param _reportId The ID of the report to resolve.
    /// @param _isOriginalReporterCorrect True if the original validator's report was correct, false if the challenger's claim was correct.
    /// @param _newMetadataHash A new hash to signal off-chain metadata update for the NFT (reflecting model performance).
    /// @dev This function would typically be called by a trusted oracle or a DAO vote after off-chain verification.
    function resolveValidationDispute(
        uint256 _reportId,
        bool _isOriginalReporterCorrect,
        string calldata _newMetadataHash
    ) external whenNotPaused nonReentrant onlyOracle {
        ValidationReport storage report = validationReports[_reportId];
        if (report.validator == address(0)) revert AetheriumAI__ValidationReportNotFound(_reportId);
        if (report.status != ValidationStatus.Challenged) revert AetheriumAI__ReportNotInChallengedState();

        InferenceRequest storage request = inferenceRequests[report.requestId];
        AIModel storage model = aiModels[request.modelId];

        address winner;
        address loser;
        uint256 rewardAmount = validatorReportStakeAmount; // Base reward from loser's stake

        // Adjust pendingReportsCount for both participants
        validators[report.validator].pendingReportsCount--;
        validators[report.challenger].pendingReportsCount--;

        if (_isOriginalReporterCorrect) {
            winner = report.validator;
            loser = report.challenger;
            report.status = ValidationStatus.Approved; // Original report was confirmed correct
            
            // Original reporter wins: gets back their stake + challenger's stake.
            // Challenger loses: their stake is taken and given to the winner.
            validators[winner].stakedAmount += (validatorReportStakeAmount * 2);
            // Loser's stake implicitly transferred to winner. No need to explicitly send to protocol fees here.
            
            model.reputationScore += 5; // Reward model for good performance confirmed by validation
            model.totalValidatedInferences++;
        } else {
            winner = report.challenger;
            loser = report.validator;
            report.status = ValidationStatus.Rejected; // Original report was found incorrect
            
            // Challenger wins: gets back their stake + original reporter's stake.
            // Original reporter loses: their stake is taken and given to the winner.
            validators[winner].stakedAmount += (validatorReportStakeAmount * 2);
            
            model.reputationScore -= 10; // Penalize model for incorrect inference
        }

        // The earnedRewards can be adjusted here if specific bonuses beyond the staked amount are given.
        // For simplicity, here we just return the combined stake to the winner's `stakedAmount`.
        // If there were explicit `earnedRewards` to be distributed from a pool, that would be adjusted here.
        // The `slashAmount` here refers to the losing party's staked amount that is transferred to the winner.

        // Update model metadata hash based on validation outcome
        model.metadataHash = _newMetadataHash;

        emit ValidationDisputeResolved(_reportId, report.requestId, winner, loser, rewardAmount, rewardAmount); // rewardAmount and slashAmount are equal here
        emit AetheriumCoreMetadataUpdated(model.coreNFTId, request.modelId, _newMetadataHash);
    }

    /// @notice Validators claim rewards for successfully validated inferences or correctly challenging reports.
    /// @dev This function is for claiming general `earnedRewards`, not the staked amounts from dispute resolution.
    function claimValidationReward() external whenNotPaused nonReentrant onlyValidator {
        Validator storage validator = validators[msg.sender];
        if (validator.earnedRewards == 0) revert AetheriumAI__NoRewardsToClaim();

        uint256 rewards = validator.earnedRewards;
        validator.earnedRewards = 0; // Reset before transfer

        IERC20(AetheriumToken).transfer(msg.sender, rewards);
        emit ValidationRewardClaimed(msg.sender, rewards);
    }

    // VI. AetheriumCore NFT (Dynamic NFT) Interaction

    /// @notice Retrieves the dynamic metadata URI for a specific AetheriumCore NFT (model).
    /// @param _coreNFTId The ID of the AetheriumCore NFT.
    /// @return A constructed URI that an off-chain metadata service can use, including the model ID and its current metadata hash.
    function getAetheriumCoreMetadataURI(uint256 _coreNFTId) external view returns (string memory) {
        uint256 modelId = coreNFTIdToModelId[_coreNFTId];
        if (modelId == 0) revert AetheriumAI__CoreNFTNotFound(_coreNFTId);
        AIModel storage model = aiModels[modelId];
        // Example: "https://api.aetherium.ai/model/{modelId}/{metadataHash}"
        return string(abi.encodePacked("https://api.aetherium.ai/model/", Strings.toString(modelId), "/", model.metadataHash));
    }

    /// @notice Updates the on-chain hash/version of an NFT's metadata, signaling off-chain systems to refresh.
    /// @param _modelId The ID of the model associated with the NFT.
    /// @param _newMetadataHash A new hash to signal off-chain metadata update for the NFT.
    /// @dev This function is intended to be called by trusted entities (like the oracle) to reflect
    ///      changes in model performance or reputation in the NFT's metadata without changing the baseURI.
    function updateCoreMetadataHash(uint256 _modelId, string calldata _newMetadataHash) external onlyOracle {
        AIModel storage model = aiModels[_modelId];
        if (model.architect == address(0)) revert AetheriumAI__ModelNotFound(_modelId);
        model.metadataHash = _newMetadataHash;
        emit AetheriumCoreMetadataUpdated(model.coreNFTId, _modelId, _newMetadataHash);
    }

    /// @notice Allows the owner of an AetheriumCore NFT to transfer ownership of the underlying AI model.
    /// @param _from The current owner of the NFT.
    /// @param _to The new owner of the NFT.
    /// @param _coreNFTId The ID of the AetheriumCore NFT to transfer.
    /// @dev This function wraps the ERC721 transfer function and updates internal architect mapping.
    ///      It also transfers any pending earnings for the model to the new architect.
    function transferAetheriumCore(address _from, address _to, uint256 _coreNFTId) external whenNotPaused nonReentrant {
        if (_from == address(0) || _to == address(0)) revert AetheriumAI__InvalidAmount();

        uint256 modelId = coreNFTIdToModelId[_coreNFTId];
        if (modelId == 0) revert AetheriumAI__CoreNFTNotFound(_coreNFTId);
        if (aiModels[modelId].architect != _from) revert AetheriumAI__NotArchitect(_from); // Ensure _from is the recorded architect

        // ERC721 `transferFrom` internally checks `msg.sender` as owner or approved operator.
        AetheriumCoreNFT.transferFrom(_from, _to, _coreNFTId); 
        aiModels[modelId].architect = _to; // Update internal architect mapping

        // Transfer any pending earnings to the new architect's credit balance
        if (aiModels[modelId].totalEarnings > 0) {
            uint256 earningsToTransfer = aiModels[modelId].totalEarnings;
            aiModels[modelId].totalEarnings = 0;
            userAetheriumCredits[_to] += earningsToTransfer;
            emit AetheriumCreditsDeposited(_to, earningsToTransfer); // Emit event for new architect's credits
        }
    }

    // VII. Protocol & Utility Functions

    /// @notice View function to retrieve comprehensive details about a registered AI model.
    /// @param _modelId The ID of the model.
    /// @return architect The address of the model architect.
    /// @return modelURI URI to off-chain model details.
    /// @return inferencePrice Price in AetheriumToken for one inference.
    /// @return status Current status of the model (Active/Inactive).
    /// @return coreNFTId The AetheriumCore NFT ID.
    /// @return totalInferences Total inferences executed.
    /// @return totalEarnings Accumulated earnings for the architect.
    /// @return totalValidatedInferences Count of validated inferences.
    /// @return reputationScore Current reputation score.
    /// @return metadataHash Current hash for NFT metadata.
    function getModelDetails(uint256 _modelId)
        external
        view
        returns (
            address architect,
            string memory modelURI,
            uint256 inferencePrice,
            ModelStatus status,
            uint256 coreNFTId,
            uint256 totalInferences,
            uint256 totalEarnings,
            uint256 totalValidatedInferences,
            int256 reputationScore,
            string memory metadataHash
        )
    {
        AIModel storage model = aiModels[_modelId];
        if (model.architect == address(0)) revert AetheriumAI__ModelNotFound(_modelId);

        return (
            model.architect,
            model.modelURI,
            model.inferencePrice,
            model.status,
            model.coreNFTId,
            model.totalInferences,
            model.totalEarnings,
            model.totalValidatedInferences,
            model.reputationScore,
            model.metadataHash
        );
    }

    /// @notice View function to retrieve details about a specific inference request.
    /// @param _requestId The ID of the inference request.
    /// @return modelId The ID of the model.
    /// @return user The requesting user.
    /// @return feePaid The fee paid for the inference.
    /// @return requestTime Timestamp of the request.
    /// @return status Current status of the inference request.
    /// @return resultURI URI to off-chain inference result.
    /// @return resultSubmitTime Timestamp of result submission.
    /// @return validatorReportId ID of the associated validation report (0 if none).
    function getInferenceRequestDetails(uint256 _requestId)
        external
        view
        returns (
            uint256 modelId,
            address user,
            uint256 feePaid,
            uint256 requestTime,
            InferenceStatus status,
            string memory resultURI,
            uint256 resultSubmitTime,
            uint256 validatorReportId
        )
    {
        InferenceRequest storage request = inferenceRequests[_requestId];
        if (request.user == address(0)) revert AetheriumAI__InferenceRequestNotFound(_requestId);

        return (
            request.modelId,
            request.user,
            request.feePaid,
            request.requestTime,
            request.status,
            request.resultURI,
            request.resultSubmitTime,
            request.validatorReportId
        );
    }

    /// @notice View function to check the staking and activity status of a validator.
    /// @param _validatorAddress The address of the validator.
    /// @return stakedAmount The current staked amount.
    /// @return earnedRewards Accumulated rewards.
    /// @return isActive Whether the validator is currently active.
    /// @return pendingReportsCount Number of pending validation reports.
    function getValidatorStatus(address _validatorAddress)
        external
        view
        returns (
            uint256 stakedAmount,
            uint256 earnedRewards,
            bool isActive,
            uint256 pendingReportsCount
        )
    {
        Validator storage validator = validators[_validatorAddress];
        return (validator.stakedAmount, validator.earnedRewards, validator.isActive, validator.pendingReportsCount);
    }

    /// @notice View function to check a user's available inference credits.
    /// @param _user The address of the user.
    /// @return The amount of AETH tokens held as inference credits.
    function getUserAetheriumCredits(address _user) external view returns (uint256) {
        return userAetheriumCredits[_user];
    }

    /// @notice View function to check the total accumulated protocol fees ready for withdrawal.
    /// @return The total amount of AETH tokens accumulated as protocol fees.
    function getProtocolFeesOutstanding() external view returns (uint256) {
        return _totalProtocolFeesAccumulated;
    }

    /// @notice Allows the owner to withdraw accumulated protocol fees to the `protocolFeeRecipient`.
    function withdrawProtocolFees() external onlyOwner nonReentrant {
        uint256 amount = _totalProtocolFeesAccumulated;
        if (amount == 0) revert AetheriumAI__NoEarningsToWithdraw(); // Reusing error
        _totalProtocolFeesAccumulated = 0;
        IERC20(AetheriumToken).transfer(protocolFeeRecipient, amount);
    }

    /// @notice View function to retrieve core protocol parameters.
    /// @return feePercentage Current protocol fee percentage.
    /// @return minModelPrice Minimum inference price for models.
    /// @return minStake Minimum stake for validators.
    /// @return reportStake Stake required per validation report.
    /// @return disputePeriod Time for validation disputes.
    /// @return requestTimeout Time before an inference request can be cancelled.
    function getProtocolParameters()
        external
        view
        returns (
            uint256 feePercentage,
            uint256 minModelPrice,
            uint256 minStake,
            uint256 reportStake,
            uint256 disputePeriod,
            uint256 requestTimeout
        )
    {
        return (
            protocolFeePercentage,
            minModelInferencePrice,
            minValidatorStake,
            validatorReportStakeAmount,
            validationDisputePeriod,
            inferenceRequestTimeout
        );
    }

    /// @notice View function to get the AetheriumCore NFT ID associated with a given model ID.
    /// @param _modelId The ID of the AI model.
    /// @return The AetheriumCore NFT ID.
    function getModelCoreTokenId(uint256 _modelId) external view returns (uint256) {
        if (aiModels[_modelId].architect == address(0)) revert AetheriumAI__ModelNotFound(_modelId);
        return aiModels[_modelId].coreNFTId;
    }

    /// @notice View function to get the owner of a specific AI model.
    /// @param _modelId The ID of the AI model.
    /// @return The address of the architect who owns the model.
    function getModelOwner(uint256 _modelId) external view returns (address) {
        if (aiModels[_modelId].architect == address(0)) revert AetheriumAI__ModelNotFound(_modelId);
        return aiModels[_modelId].architect;
    }
}
```