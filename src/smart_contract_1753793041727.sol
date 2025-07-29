Here is a Solidity smart contract named `AetherMindCollective`, designed with an array of interesting, advanced, creative, and trendy functions. It focuses on decentralized AI model refinement, reputation, and dynamic NFTs.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For Math.min

// A minimal interface for an external oracle service.
// In a real scenario, this would be a Chainlink oracle or a custom decentralized oracle network.
interface IOracle {
    function requestData(string memory _query) external returns (bytes32 requestId);
    // function fulfillData(bytes32 _requestId, bytes memory _data) external; // Oracle would call back directly
}

/**
 * @title AetherMind Collective
 * @dev A decentralized protocol for collaborative AI model refinement, validation, and attribution.
 *      It integrates dynamic NFTs, a reputation system, performance bounties, and DAO governance
 *      to foster a community-driven approach to AI development.
 *
 * @outline
 * 1.  **Core Concept: Decentralized AI Model Refinement, Reputation, and Dynamic NFTs.**
 *     - **Decentralized Model Curation:** Community proposes, evaluates, and integrates AI models or improvements. This moves the traditional centralized AI development process to a transparent, on-chain, and community-driven one.
 *     - **Proof-of-Contribution:** Tracks and rewards various contributions (data provision, compute provision via off-chain verification, model evaluation) ensuring attribution and fair compensation.
 *     - **Dynamic Reputation & NFTs (AetherMinds):** Introduces "AetherMind" NFTs (ERC721) that are designed to be soulbound-like (one-per-user) and dynamically evolve. Their visual representation and on-chain attributes (e.g., "Knowledge Tier", "Contribution Score") change based on a participant's validated contributions and the success of AI models they supported.
 *     - **Economic Incentives:** Features a novel bounty system where participants can put up or claim rewards for improving specific AI model performance metrics, acting as a prediction market for AI progress. Staking mechanisms are included for validator roles.
 *     - **DAO Governance:** Integrates with an external Decentralized Autonomous Organization (DAO) to allow the community to collectively govern protocol parameters, approve models, and resolve disputes.
 *
 * 2.  **Contract Components:**
 *     - Inherits `Ownable` for initial setup and emergency controls (intended for DAO transition).
 *     - Manages `AetherMindNFT` (ERC721) for participant reputation and identity.
 *     - Integrates an `IERC20` token (e.g., $AETH) for staking, rewards, and bounties, creating an internal economy.
 *     - Leverages an `IOracle` interface for crucial off-chain data verification, such as AI model performance metrics or dataset quality assessments, bridging the on-chain and off-chain AI worlds.
 *     - Utilizes custom structs and mappings for robust management of AI models, evaluation rounds, performance bounties, and comprehensive participant data (reputation, staking status).
 *
 * @function_summary
 * **I. Initialization & Configuration**
 * - `constructor`: Deploys the contract and sets initial configurable parameters for the protocol.
 * - `initializeProtocol`: A post-deployment function (ideal for proxy patterns) to set critical external contract addresses (Aether Token, Oracle, DAO).
 * - `setOracleAddress`: Allows the DAO to update the address of the external oracle service.
 * - `setAetherTokenAddress`: Allows the DAO to update the address of the utility/governance token.
 * - `setDAOAddress`: Allows the owner/DAO to set or update the address of the governing DAO contract.
 * - `updateProtocolParameter`: A versatile function enabling the DAO to modify various core protocol parameters (e.g., evaluation periods, staking requirements).
 *
 * **II. AI Model Lifecycle Management**
 * - `proposeAIModel`: Enables any participant to propose a new AI model or a significant upgrade by submitting its decentralized storage hash (e.g., IPFS).
 * - `requestModelEvaluation`: Initiates a community-wide evaluation round for a proposed AI model, controlled by the DAO.
 * - `submitEvaluationResult`: Allows registered validators to submit their assessment of a model, including a hash of their detailed evaluation proof.
 * - `finalizeModelStatus`: The DAO or an authorized oracle finalizes the status of an AI model (e.g., `Finalized`, `Rejected`) based on the collected evaluations, potentially updating its performance metric.
 * - `registerDataContributor`: A conceptual function to register an address as a data provider (could be handled by whitelisting or open access).
 * - `submitDatasetHash`: Enables data providers to submit the decentralized storage hash of their datasets for potential use in AI model training.
 * - `verifyDatasetQuality`: A function (likely called by an oracle or DAO) to officially verify the quality and uniqueness of a submitted dataset.
 *
 * **III. Reputation & Dynamic AetherMind NFTs (ERC721)**
 * - `mintAetherMindNFT`: Mints a unique, initial AetherMind NFT to a participant. This NFT serves as their on-chain identity and reputation anchor in the collective. Designed as "one-per-user".
 * - `_updateAetherMindAttributes` (internal): A core internal function that dynamically updates the on-chain attributes (and consequently the metadata/visuals) of an AetherMind NFT based on the owner's validated contributions and achievements.
 * - `_updateAetherMindTier` (internal): An internal helper that calculates and updates the "Knowledge Tier" of an AetherMind NFT, reflecting increasing expertise and contribution.
 * - `redeemReputationForBoost`: Allows participants to spend their accumulated reputation points for various in-protocol benefits or boosts, such as increased voting power or priority access.
 * - `getAetherMindAttributes`: A view function to retrieve the current dynamic attributes of any specific AetherMind NFT.
 * - `tokenURI`: Overrides the standard ERC721 `tokenURI` function to dynamically generate and provide the metadata (including image and attributes) for AetherMind NFTs, reflecting their evolving state.
 *
 * **IV. Performance Bounty System**
 * - `createPerformanceBounty`: Allows any participant to create a bounty by depositing AETH tokens, incentivizing improvements to a specific AI model's performance metric.
 * - `submitBountyClaim`: Enables a participant to claim an active bounty by submitting a hash of their proof that the target metric has been achieved or surpassed.
 * - `verifyBountyClaim`: A function (called by validators or an oracle) to verify the legitimacy of a submitted bounty claim.
 * - `distributeBounty`: Distributes the AETH bounty rewards to the claimant if their claim has been successfully verified, and updates their reputation/NFT.
 * - `cancelBounty`: Provides a mechanism for the bounty creator or DAO to cancel an active bounty and retrieve the staked funds.
 *
 * **V. Staking & Rewards**
 * - `stakeForValidationRights`: Allows users to stake AETH tokens to gain the rights and responsibilities of becoming an AI model/dataset validator.
 * - `withdrawStakedTokens`: Enables validators to withdraw their staked tokens after a predefined lockup period, revoking their validator status.
 * - `claimContributionRewards`: Allows participants to claim their accumulated AETH rewards earned from various validated contributions (e.g., successful evaluations, dataset verifications).
 *
 * **VI. DAO Governance Integration (Simplified)**
 * - `proposeGovernanceChange`: A conceptual function that would interface with an external DAO contract, allowing proposals for critical protocol changes (e.g., parameter adjustments, contract upgrades).
 * - `voteOnProposal`: A placeholder representing a user's direct interaction with the external DAO contract to cast votes on proposals.
 * - `executeProposal`: A placeholder for the DAO executor role to trigger the execution of passed governance proposals.
 *
 * **VII. View & Utility Functions**
 * - `getProtocolParameters`: Retrieves all current configurable parameters of the AetherMind protocol.
 * - `getAIModelDetails`: Provides comprehensive details about any specific AI model registered in the collective.
 * - `getParticipantModelEvaluation`: Retrieves a specific validator's detailed evaluation record for a particular AI model.
 * - `getUserContributionStats`: Offers a summary of a user's total contributions, reputation, and staking status within the protocol.
 * - `getBountyDetails`: Fetches the full details of any active, claimed, or historical performance bounty.
 * - `toString` (internal): A utility helper function used internally to convert `uint256` values to `string` for dynamic metadata generation.
 */
contract AetherMindCollective is Ownable, ReentrancyGuard, ERC721 {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // Addresses of interconnected contracts
    IERC20 public aetherToken; // The utility/governance token for the protocol
    IOracle public oracle;     // External oracle for off-chain data verification (e.g., model performance, dataset quality)
    address public daoAddress; // Address of the DAO contract that governs the protocol

    // Counters for unique IDs
    Counters.Counter private _modelIds;
    Counters.Counter private _evaluationIds;
    Counters.Counter private _bountyIds;
    Counters.Counter private _aetherMindTokenIds; // For AetherMind NFTs

    // --- Protocol Parameters (configurable by DAO) ---
    struct ProtocolParameters {
        uint256 modelEvaluationPeriod;      // Duration in seconds for model evaluations
        uint256 datasetVerificationPeriod;  // Duration in seconds for dataset verification
        uint256 minStakeForValidator;       // Minimum AETH tokens required to be a validator (in smallest unit)
        uint256 reputationBoostCost;        // Cost in reputation points for a boost
        uint256 modelFinalizationThreshold; // Min number of positive evaluations for a model to be finalized
        uint256 bountyClaimPeriod;          // Duration for bounty claims to be verified
        uint256 stakingLockupPeriod;        // Time in seconds staked tokens are locked
        uint256 rewardPerEvaluation;        // Base AETH rewards per successful evaluation (in smallest unit)
        uint256 rewardPerDatasetVerification; // Base AETH rewards per successful dataset verification (in smallest unit)
    }
    ProtocolParameters public protocolParams;

    // --- Data Structures ---

    enum ModelStatus { Proposed, Evaluating, Finalized, Rejected, Deactivated }
    enum EvaluationStatus { Pending, Approved, Rejected, Disputed } // Disputed implies a later resolution mechanism
    enum BountyStatus { Active, Claimed, Verified, Distributed, Failed, Canceled }

    // AI Model struct
    struct AIModel {
        uint256 id;
        address proposer;
        string name;
        string modelHash; // IPFS/Arweave hash of the model artifacts
        string description;
        ModelStatus status;
        uint256 proposalTimestamp;
        uint256 lastEvaluationRequest; // Timestamp of the last evaluation request
        uint256 finalizedTimestamp; // Timestamp when model became Finalized
        uint256 totalPositiveEvaluations;
        uint256 totalNegativeEvaluations;
        string currentPerformanceMetric; // e.g., "accuracy: 0.92" (updated by oracle after finalization/bounty)
    }
    mapping(uint256 => AIModel) public aiModels; // modelId => AIModel

    // Evaluation struct
    struct Evaluation {
        uint256 id;
        uint256 modelId;
        address evaluator;
        bool isPositive; // True for approval, false for rejection
        string evaluationProofHash; // IPFS/Arweave hash of detailed evaluation report/logs
        EvaluationStatus status;
        uint256 submissionTimestamp;
    }
    // Mapping modelId => evaluatorAddress => Evaluation to ensure one evaluation per validator per model round.
    mapping(uint256 => mapping(address => Evaluation)) public modelEvaluations;

    // Dataset struct
    struct Dataset {
        uint256 id;
        address contributor;
        string datasetHash; // IPFS/Arweave hash of the dataset
        string description;
        bool verified; // True if dataset quality is verified
        uint256 submissionTimestamp;
        uint256 verificationTimestamp;
    }
    mapping(uint256 => Dataset) public datasets; // datasetId => Dataset

    // Bounty struct
    struct PerformanceBounty {
        uint256 id;
        address creator;
        uint256 modelId;
        uint256 amount; // Amount of AETH tokens
        string targetMetricImprovement; // e.g., "accuracy > 0.95"
        BountyStatus status;
        address claimant;
        uint256 claimTimestamp;
        string claimProofHash; // IPFS/Arweave hash of the claim's evidence
        uint256 verificationTimestamp;
    }
    mapping(uint256 => PerformanceBounty) public performanceBounties; // bountyId => PerformanceBounty

    // Participant Data (Reputation, Staking)
    struct Participant {
        uint256 reputation; // Accumulated reputation points
        uint256 stakedAmount; // AETH tokens staked
        uint256 stakingTimestamp; // Timestamp of staking for lockup
        bool isValidator; // True if eligible to be a validator
        uint256 lastClaimTimestamp; // Timestamp of last reward claim
        uint256 pendingAETHRewards; // AETH rewards that are accumulated and claimable
    }
    mapping(address => Participant) public participants;

    // AetherMind NFT attributes (on-chain for dynamism)
    struct AetherMindAttributes {
        uint256 knowledgeTier; // e.g., 0-5, based on evaluations/contributions
        uint256 contributionScore; // Total score from data, model, validation contributions (e.g., based on reputation)
        uint256 validationAccuracy; // Percentage of correct validations (simplified: starts high, decreases on bad eval)
        uint256 modelSuccessCount; // Number of models they contributed to that got finalized
        uint256 lastUpdateTimestamp;
    }
    mapping(uint256 => AetherMindAttributes) public aetherMindNFTAttributes; // tokenId => attributes

    // --- Events ---
    event ProtocolInitialized(address indexed owner, IERC20 indexed aetherTokenAddress, IOracle indexed oracleAddress, address daoAddress);
    event ProtocolParameterUpdated(string paramName, uint256 newValue);
    event AIModelProposed(uint256 indexed modelId, address indexed proposer, string name, string modelHash);
    event ModelEvaluationRequested(uint256 indexed modelId, uint256 evaluationPeriodEnd);
    event EvaluationSubmitted(uint256 indexed modelId, address indexed evaluator, bool isPositive, uint256 evaluationId);
    event ModelStatusFinalized(uint256 indexed modelId, ModelStatus newStatus, string currentPerformanceMetric);
    event DataContributorRegistered(address indexed contributor);
    event DatasetSubmitted(uint256 indexed datasetId, address indexed contributor, string datasetHash);
    event DatasetVerified(uint256 indexed datasetId, address indexed verifier);
    event AetherMindMinted(uint256 indexed tokenId, address indexed recipient);
    event AetherMindAttributesUpdated(uint256 indexed tokenId, uint256 knowledgeTier, uint256 contributionScore);
    event ReputationRedeemed(address indexed participant, uint256 amount, string benefit);
    event PerformanceBountyCreated(uint256 indexed bountyId, uint256 indexed modelId, address indexed creator, uint256 amount, string targetMetric);
    event BountyClaimed(uint256 indexed bountyId, address indexed claimant);
    event BountyVerified(uint256 indexed bountyId, address indexed verifier, bool success);
    event BountyDistributed(uint256 indexed bountyId, address indexed claimant, uint256 amount);
    event BountyCanceled(uint256 indexed bountyId, address indexed initiator);
    event StakedForValidation(address indexed participant, uint256 amount);
    event StakedTokensWithdrawn(address indexed participant, uint256 amount);
    event RewardsClaimed(address indexed participant, uint256 amount);
    event GovernanceProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description);

    // --- Modifiers ---
    modifier onlyDAO() {
        require(msg.sender == daoAddress, "AetherMindCollective: Caller is not the DAO");
        _;
    }

    modifier onlyValidator() {
        require(participants[msg.sender].isValidator, "AetherMindCollective: Caller is not a registered validator");
        _;
    }

    modifier onlyValidAetherMind(uint256 _tokenId) {
        require(_exists(_tokenId), "AetherMindCollective: Invalid AetherMind NFT");
        _;
    }

    // --- Constructor ---
    constructor() ERC721("AetherMind", "AMIND") Ownable(msg.sender) {
        // Initial parameters - can be updated by DAO later
        protocolParams = ProtocolParameters({
            modelEvaluationPeriod: 7 days,
            datasetVerificationPeriod: 5 days,
            minStakeForValidator: 1000 * 10 ** 18, // 1000 AETH (assuming 18 decimals)
            reputationBoostCost: 50,
            modelFinalizationThreshold: 3, // Requires 3 positive evaluations to finalize a model
            bountyClaimPeriod: 3 days,
            stakingLockupPeriod: 30 days,
            rewardPerEvaluation: 10 * 10 ** 18, // 10 AETH
            rewardPerDatasetVerification: 5 * 10 ** 18 // 5 AETH
        });
    }

    // --- I. Initialization & Configuration ---

    /// @notice Initializes the protocol by setting critical contract addresses. Designed for proxy patterns.
    /// @param _aetherTokenAddress Address of the Aether utility/governance token.
    /// @param _oracleAddress Address of the external oracle service.
    /// @param _daoAddress Address of the DAO governing this protocol.
    function initializeProtocol(IERC20 _aetherTokenAddress, IOracle _oracleAddress, address _daoAddress) external onlyOwner {
        require(address(aetherToken) == address(0), "AetherMindCollective: Already initialized");
        require(address(_aetherTokenAddress) != address(0), "AetherMindCollective: Invalid Aether Token address");
        require(address(_oracleAddress) != address(0), "AetherMindCollective: Invalid Oracle address");
        require(_daoAddress != address(0), "AetherMindCollective: Invalid DAO address");

        aetherToken = _aetherTokenAddress;
        oracle = _oracleAddress;
        daoAddress = _daoAddress;

        emit ProtocolInitialized(msg.sender, aetherToken, oracle, daoAddress);
    }

    /// @notice Sets the address of the external oracle service.
    /// @param _oracleAddress The new oracle contract address.
    function setOracleAddress(IOracle _oracleAddress) external onlyDAO {
        require(address(_oracleAddress) != address(0), "AetherMindCollective: Invalid address");
        oracle = _oracleAddress;
        emit ProtocolParameterUpdated("OracleAddress", uint256(uint160(_oracleAddress)));
    }

    /// @notice Sets the address of the utility/governance token.
    /// @param _aetherTokenAddress The new Aether token contract address.
    function setAetherTokenAddress(IERC20 _aetherTokenAddress) external onlyDAO {
        require(address(_aetherTokenAddress) != address(0), "AetherMindCollective: Invalid address");
        aetherToken = _aetherTokenAddress;
        emit ProtocolParameterUpdated("AetherTokenAddress", uint256(uint160(_aetherTokenAddress)));
    }

    /// @notice Sets the address of the DAO contract.
    /// @param _daoAddress The new DAO contract address.
    function setDAOAddress(address _daoAddress) external onlyDAO {
        require(_daoAddress != address(0), "AetherMindCollective: Invalid address");
        daoAddress = _daoAddress;
        emit ProtocolParameterUpdated("DAOAddress", uint256(uint160(_daoAddress)));
    }

    /// @notice Updates a configurable protocol parameter.
    /// @param _paramName The name of the parameter to update (e.g., "modelEvaluationPeriod").
    /// @param _newValue The new value for the parameter.
    function updateProtocolParameter(string calldata _paramName, uint256 _newValue) external onlyDAO {
        bytes32 paramHash = keccak256(abi.encodePacked(_paramName));
        if (paramHash == keccak256(abi.encodePacked("modelEvaluationPeriod"))) {
            protocolParams.modelEvaluationPeriod = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("datasetVerificationPeriod"))) {
            protocolParams.datasetVerificationPeriod = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("minStakeForValidator"))) {
            protocolParams.minStakeForValidator = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("reputationBoostCost"))) {
            protocolParams.reputationBoostCost = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("modelFinalizationThreshold"))) {
            protocolParams.modelFinalizationThreshold = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("bountyClaimPeriod"))) {
            protocolParams.bountyClaimPeriod = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("stakingLockupPeriod"))) {
            protocolParams.stakingLockupPeriod = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("rewardPerEvaluation"))) {
            protocolParams.rewardPerEvaluation = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("rewardPerDatasetVerification"))) {
            protocolParams.rewardPerDatasetVerification = _newValue;
        } else {
            revert("AetherMindCollective: Unknown parameter name");
        }
        emit ProtocolParameterUpdated(_paramName, _newValue);
    }

    // --- II. AI Model Lifecycle Management ---

    /// @notice Allows a participant to propose a new AI model or a significant upgrade.
    /// @param _name The name of the AI model.
    /// @param _modelHash IPFS/Arweave hash pointing to the model's artifacts (weights, architecture, etc.).
    /// @param _description A brief description of the model and its purpose.
    /// @return The unique ID of the proposed model.
    function proposeAIModel(string calldata _name, string calldata _modelHash, string calldata _description) external nonReentrant returns (uint256) {
        require(bytes(_name).length > 0, "AetherMindCollective: Model name cannot be empty");
        require(bytes(_modelHash).length > 0, "AetherMindCollective: Model hash cannot be empty");

        _modelIds.increment();
        uint256 newModelId = _modelIds.current();

        aiModels[newModelId] = AIModel({
            id: newModelId,
            proposer: msg.sender,
            name: _name,
            modelHash: _modelHash,
            description: _description,
            status: ModelStatus.Proposed,
            proposalTimestamp: block.timestamp,
            lastEvaluationRequest: 0,
            finalizedTimestamp: 0,
            totalPositiveEvaluations: 0,
            totalNegativeEvaluations: 0,
            currentPerformanceMetric: ""
        });

        emit AIModelProposed(newModelId, msg.sender, _name, _modelHash);
        return newModelId;
    }

    /// @notice Initiates an evaluation round for a proposed AI model. Can only be called by the DAO.
    /// @param _modelId The ID of the model to be evaluated.
    function requestModelEvaluation(uint256 _modelId) external onlyDAO {
        AIModel storage model = aiModels[_modelId];
        require(model.id != 0, "AetherMindCollective: Model not found");
        require(model.status == ModelStatus.Proposed || model.status == ModelStatus.Evaluating, "AetherMindCollective: Model not in evaluable state");

        model.status = ModelStatus.Evaluating;
        model.lastEvaluationRequest = block.timestamp;
        
        // Reset evaluation counts for a new round
        model.totalPositiveEvaluations = 0;
        model.totalNegativeEvaluations = 0;

        emit ModelEvaluationRequested(_modelId, block.timestamp + protocolParams.modelEvaluationPeriod);
    }

    /// @notice Allows a registered validator to submit their evaluation results for a model.
    /// @param _modelId The ID of the model being evaluated.
    /// @param _isPositive True if the evaluation is positive (model meets criteria), false otherwise.
    /// @param _evaluationProofHash IPFS/Arweave hash of detailed evaluation proof (e.g., test results, logs).
    function submitEvaluationResult(uint256 _modelId, bool _isPositive, string calldata _evaluationProofHash) external nonReentrant onlyValidator {
        AIModel storage model = aiModels[_modelId];
        require(model.id != 0, "AetherMindCollective: Model not found");
        require(model.status == ModelStatus.Evaluating, "AetherMindCollective: Model not currently under evaluation");
        require(block.timestamp <= model.lastEvaluationRequest + protocolParams.modelEvaluationPeriod, "AetherMindCollective: Evaluation period expired");
        require(modelEvaluations[_modelId][msg.sender].id == 0, "AetherMindCollective: Already submitted evaluation for this model in current round"); // Assumes one submission per validator per evaluation round.
        require(bytes(_evaluationProofHash).length > 0, "AetherMindCollective: Evaluation proof hash cannot be empty");

        _evaluationIds.increment();
        uint256 newEvaluationId = _evaluationIds.current();

        modelEvaluations[_modelId][msg.sender] = Evaluation({
            id: newEvaluationId,
            modelId: _modelId,
            evaluator: msg.sender,
            isPositive: _isPositive,
            evaluationProofHash: _evaluationProofHash,
            status: EvaluationStatus.Pending, // Awaiting DAO/Oracle finalization for this specific evaluation
            submissionTimestamp: block.timestamp
        });

        if (_isPositive) {
            model.totalPositiveEvaluations++;
        } else {
            model.totalNegativeEvaluations++;
        }

        // Accumulate rewards for the validator
        participants[msg.sender].pendingAETHRewards += protocolParams.rewardPerEvaluation;
        participants[msg.sender].reputation += 1; // Basic reputation point for evaluation participation

        // Trigger oracle call if sophisticated verification is needed for evaluation proof
        // oracle.requestData(string(abi.encodePacked("verifyEvaluationProof", _evaluationProofHash, model.modelHash, toString(_modelId), toString(newEvaluationId))));

        emit EvaluationSubmitted(_modelId, msg.sender, _isPositive, newEvaluationId);
    }

    /// @notice Finalizes the status of an AI model based on accumulated evaluations.
    /// @dev This function would typically be called by the DAO or an authorized oracle after evaluation period.
    /// @param _modelId The ID of the model to finalize.
    /// @param _newStatus The status to set for the model (e.g., Finalized, Rejected).
    /// @param _currentPerformanceMetric A string representing the current measured performance (e.g., "accuracy: 0.92").
    function finalizeModelStatus(uint256 _modelId, ModelStatus _newStatus, string calldata _currentPerformanceMetric) external onlyDAO {
        AIModel storage model = aiModels[_modelId];
        require(model.id != 0, "AetherMindCollective: Model not found");
        require(model.status == ModelStatus.Evaluating, "AetherMindCollective: Model not in evaluation state");
        require(block.timestamp > model.lastEvaluationRequest + protocolParams.modelEvaluationPeriod, "AetherMindCollective: Evaluation period not yet expired");

        if (_newStatus == ModelStatus.Finalized) {
            require(model.totalPositiveEvaluations >= protocolParams.modelFinalizationThreshold, "AetherMindCollective: Not enough positive evaluations to finalize");
            model.finalizedTimestamp = block.timestamp;
            model.currentPerformanceMetric = _currentPerformanceMetric;
            
            // Reward model proposer
            participants[model.proposer].reputation += 10; 
            participants[model.proposer].pendingAETHRewards += protocolParams.rewardPerEvaluation * 5; // Example: 5x reward for successful model

            // Update AetherMind NFT for proposer if they have one
            if (balanceOf(model.proposer) > 0) { 
                uint256 tokenId = tokenOfOwnerByIndex(model.proposer, 0); 
                AetherMindAttributes storage attrs = aetherMindNFTAttributes[tokenId];
                attrs.modelSuccessCount++;
                _updateAetherMindAttributes(tokenId); // Recalculates tier and score
            }
        } else if (_newStatus == ModelStatus.Rejected) {
            // Logic for rejection: perhaps totalNegativeEvaluations > totalPositiveEvaluations
            require(model.totalNegativeEvaluations > 0, "AetherMindCollective: Model cannot be rejected without negative evaluations");
            // No specific action needed for NFT/reputation on rejection for simplicity.
        } else if (_newStatus == ModelStatus.Deactivated) {
            // Allows DAO to deactivate a previously finalized model.
            require(model.status == ModelStatus.Finalized, "AetherMindCollective: Can only deactivate finalized models.");
        } else {
            revert("AetherMindCollective: Invalid status for finalization");
        }

        model.status = _newStatus;
        emit ModelStatusFinalized(_modelId, _newStatus, _currentPerformanceMetric);
    }

    /// @notice Registers a new data contributor in the protocol.
    /// @dev This function might be called by the DAO or a specific "DataCurator" role.
    /// @param _contributorAddress The address of the new data contributor.
    function registerDataContributor(address _contributorAddress) external onlyDAO {
        require(_contributorAddress != address(0), "AetherMindCollective: Invalid address");
        // No explicit state change for `Participant` struct `isDataContributor` for now, but conceptual.
        emit DataContributorRegistered(_contributorAddress);
    }

    /// @notice Allows registered (or any) data contributors to submit IPFS/Arweave hashes of their datasets.
    /// @param _datasetHash The IPFS/Arweave hash of the dataset.
    /// @param _description A description of the dataset content and quality.
    /// @return The unique ID of the submitted dataset.
    function submitDatasetHash(string calldata _datasetHash, string calldata _description) external nonReentrant returns (uint256) {
        require(bytes(_datasetHash).length > 0, "AetherMindCollective: Dataset hash cannot be empty");

        _modelIds.increment(); // Using shared counter for IDs, can be separated if preferred
        uint256 newDatasetId = _modelIds.current();

        datasets[newDatasetId] = Dataset({
            id: newDatasetId,
            contributor: msg.sender,
            datasetHash: _datasetHash,
            description: _description,
            verified: false,
            submissionTimestamp: block.timestamp,
            verificationTimestamp: 0
        });

        // Request oracle verification for dataset quality/uniqueness
        // oracle.requestData(string(abi.encodePacked("verifyDatasetQuality", _datasetHash, toString(newDatasetId))));

        emit DatasetSubmitted(newDatasetId, msg.sender, _datasetHash);
        return newDatasetId;
    }

    /// @notice Allows a validator (or oracle callback) to mark a dataset as verified.
    /// @param _datasetId The ID of the dataset to verify.
    /// @param _success True if the dataset is verified as high quality and unique, false otherwise.
    function verifyDatasetQuality(uint256 _datasetId, bool _success) external onlyDAO { // or restricted to oracle address
        Dataset storage dataset = datasets[_datasetId];
        require(dataset.id != 0, "AetherMindCollective: Dataset not found");
        require(!dataset.verified, "AetherMindCollective: Dataset already verified");
        require(block.timestamp < dataset.submissionTimestamp + protocolParams.datasetVerificationPeriod, "AetherMindCollective: Dataset verification period expired");

        dataset.verified = _success;
        dataset.verificationTimestamp = block.timestamp;

        if (_success) {
            participants[dataset.contributor].reputation += 5; // Reward data contributor
            participants[dataset.contributor].pendingAETHRewards += protocolParams.rewardPerDatasetVerification;
            emit DatasetVerified(_datasetId, msg.sender);

            // Update AetherMind NFT for data contributor
            if (balanceOf(dataset.contributor) > 0) {
                uint256 tokenId = tokenOfOwnerByIndex(dataset.contributor, 0);
                _updateAetherMindAttributes(tokenId); 
            }
        } else {
            // If verification fails, no rewards or potential penalty/flagging.
        }
    }

    // --- III. Reputation & Dynamic AetherMind NFTs (ERC721) ---

    /// @notice Mints an initial AetherMind NFT to a participant. This NFT represents their presence and evolving reputation.
    /// @dev This NFT is designed to be largely non-transferable (soulbound) and one-per-user.
    /// @param _recipient The address to mint the AetherMind NFT to.
    /// @return The ID of the newly minted AetherMind NFT.
    function mintAetherMindNFT(address _recipient) external nonReentrant returns (uint256) {
        require(balanceOf(_recipient) == 0, "AetherMindCollective: Recipient already has an AetherMind NFT");
        // Could add a cost to mint or specific conditions (e.g., minimum AETH stake)

        _aetherMindTokenIds.increment();
        uint256 newTokenId = _aetherMindTokenIds.current();

        _mint(_recipient, newTokenId);
        // Base URI is dynamically generated by tokenURI function

        aetherMindNFTAttributes[newTokenId] = AetherMindAttributes({
            knowledgeTier: 0,
            contributionScore: 0,
            validationAccuracy: 100, // Start high, intended to drop with incorrect validations (requires tracking correct/total)
            modelSuccessCount: 0,
            lastUpdateTimestamp: block.timestamp
        });

        emit AetherMindMinted(newTokenId, _recipient);
        return newTokenId;
    }

    /// @notice Internal function to update an AetherMind NFT's metadata based on validated contributions or model performance.
    /// @dev This function is called internally after successful contributions (e.g., evaluation, model finalization, bounty).
    /// @param _tokenId The ID of the AetherMind NFT to update.
    function _updateAetherMindAttributes(uint256 _tokenId) internal onlyValidAetherMind(_tokenId) {
        address owner = ownerOf(_tokenId);
        Participant storage participant = participants[owner];
        AetherMindAttributes storage attrs = aetherMindNFTAttributes[_tokenId];

        // Recalculate contribution score based on reputation (simplified for example)
        attrs.contributionScore = participant.reputation;
        
        // Validation accuracy would require tracking successful evaluations vs. total submitted evaluations
        // For simplicity, it remains static or is updated by specific oracle callbacks/manual review.
        // E.g., if an evaluation is disputed and found incorrect, reduce accuracy.

        attrs.lastUpdateTimestamp = block.timestamp;
        _updateAetherMindTier(_tokenId); // Recalculate tier based on new contribution score
        
        emit AetherMindAttributesUpdated(_tokenId, attrs.knowledgeTier, attrs.contributionScore);
    }

    /// @dev Internal function to determine and update the AetherMind NFT's knowledge tier.
    /// This logic would be more sophisticated, possibly based on multiple attributes, not just contributionScore.
    function _updateAetherMindTier(uint256 _tokenId) internal {
        AetherMindAttributes storage attrs = aetherMindNFTAttributes[_tokenId];
        uint256 score = attrs.contributionScore;

        if (score >= 500) {
            attrs.knowledgeTier = 5; // Master AetherMind
        } else if (score >= 200) {
            attrs.knowledgeTier = 4; // Advanced AetherMind
        } else if (score >= 80) {
            attrs.knowledgeTier = 3; // Proficient AetherMind
        } else if (score >= 20) {
            attrs.knowledgeTier = 2; // Skilled AetherMind
        } else if (score >= 5) {
            attrs.knowledgeTier = 1; // Novice AetherMind
        } else {
            attrs.knowledgeTier = 0; // Dormant AetherMind
        }
    }

    /// @notice Allows participants to spend accumulated reputation for protocol-defined boosts or benefits.
    /// @param _amount The amount of reputation to spend.
    /// @param _benefitType A string describing the benefit requested (e.g., "fast-pass-evaluation", "governance-weight-boost").
    function redeemReputationForBoost(uint256 _amount, string calldata _benefitType) external nonReentrant {
        Participant storage participant = participants[msg.sender];
        require(participant.reputation >= _amount, "AetherMindCollective: Insufficient reputation");
        require(_amount >= protocolParams.reputationBoostCost, "AetherMindCollective: Minimum redemption amount not met");
        // Further checks based on _benefitType (e.g., specific rules for each boost, allow only if benefit exists)
        // E.g., if _benefitType is "governance-weight-boost", apply a temporary multiplier to their voting power in the DAO.
        // This would require a direct call to the DAO contract or updating a state variable read by the DAO.

        participant.reputation -= _amount;

        emit ReputationRedeemed(msg.sender, _amount, _benefitType);

        // Update AetherMind NFT if reputation spending affects its attributes
        if (balanceOf(msg.sender) > 0) {
            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, 0);
            _updateAetherMindAttributes(tokenId);
        }
    }

    /// @notice Retrieves the current attributes of a specific AetherMind NFT.
    /// @param _tokenId The ID of the AetherMind NFT.
    /// @return A struct containing the NFT's dynamic attributes.
    function getAetherMindAttributes(uint256 _tokenId) external view onlyValidAetherMind(_tokenId) returns (AetherMindAttributes memory) {
        return aetherMindNFTAttributes[_tokenId];
    }

    /// @notice Overrides ERC721's tokenURI to provide dynamic metadata.
    /// @param _tokenId The ID of the NFT.
    /// @return The URI pointing to the metadata JSON.
    function tokenURI(uint256 _tokenId) public view override onlyValidAetherMind(_tokenId) returns (string memory) {
        AetherMindAttributes memory attrs = aetherMindNFTAttributes[_tokenId];

        // Image URI mapping to tiers. In practice, these would be hosted on IPFS/Arweave.
        string memory imageURI;
        if (attrs.knowledgeTier == 0) imageURI = "ipfs://QmEXAMPLE0/tier0.png"; // Example IPFS hash
        else if (attrs.knowledgeTier == 1) imageURI = "ipfs://QmEXAMPLE1/tier1.png";
        else if (attrs.knowledgeTier == 2) imageURI = "ipfs://QmEXAMPLE2/tier2.png";
        else if (attrs.knowledgeTier == 3) imageURI = "ipfs://QmEXAMPLE3/tier3.png";
        else if (attrs.knowledgeTier == 4) imageURI = "ipfs://QmEXAMPLE4/tier4.png";
        else if (attrs.knowledgeTier == 5) imageURI = "ipfs://QmEXAMPLE5/tier5.png";
        else imageURI = "ipfs://QmEXAMPLE_Default/default.png"; // Fallback

        string memory json = string(abi.encodePacked(
            '{"name": "AetherMind #', toString(_tokenId), '",',
            '"description": "An AetherMind NFT reflecting contributions to the Decentralized AI Collective. It evolves with your progress.",',
            '"image": "', imageURI, '",',
            '"attributes": [',
                '{"trait_type": "Knowledge Tier", "value": ', toString(attrs.knowledgeTier), '},',
                '{"trait_type": "Contribution Score", "value": ', toString(attrs.contributionScore), '},',
                '{"trait_type": "Validation Accuracy", "value": ', toString(attrs.validationAccuracy), '},',
                '{"trait_type": "Model Success Count", "value": ', toString(attrs.modelSuccessCount), '}',
            ']}'
        ));

        // In a production environment, you would encode this JSON to Base64:
        // return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
        return json; // Simplified for brevity in this example. Requires a Base64 library for full functionality.
    }

    // --- IV. Performance Bounty System ---

    /// @notice Allows anyone to create a bounty for improving a specific AI model's performance.
    /// The bounty amount is held in the contract.
    /// @param _modelId The ID of the AI model to improve.
    /// @param _amount The amount of AETH tokens offered as bounty.
    /// @param _targetMetricImprovement A string describing the specific metric target (e.g., "increase accuracy to >0.95").
    /// @return The ID of the newly created bounty.
    function createPerformanceBounty(uint256 _modelId, uint256 _amount, string calldata _targetMetricImprovement) external nonReentrant returns (uint256) {
        AIModel storage model = aiModels[_modelId];
        require(model.id != 0, "AetherMindCollective: Model not found");
        require(model.status == ModelStatus.Finalized, "AetherMindCollective: Model must be finalized to set bounty");
        require(_amount > 0, "AetherMindCollective: Bounty amount must be greater than zero");
        require(bytes(_targetMetricImprovement).length > 0, "AetherMindCollective: Target metric cannot be empty");
        
        // Pull AETH tokens from the bounty creator
        require(aetherToken.transferFrom(msg.sender, address(this), _amount), "AetherMindCollective: AETH transfer failed for bounty creation");

        _bountyIds.increment();
        uint256 newBountyId = _bountyIds.current();

        performanceBounties[newBountyId] = PerformanceBounty({
            id: newBountyId,
            creator: msg.sender,
            modelId: _modelId,
            amount: _amount,
            targetMetricImprovement: _targetMetricImprovement,
            status: BountyStatus.Active,
            claimant: address(0),
            claimTimestamp: 0,
            claimProofHash: "",
            verificationTimestamp: 0
        });

        emit PerformanceBountyCreated(newBountyId, _modelId, msg.sender, _amount, _targetMetricImprovement);
        return newBountyId;
    }

    /// @notice A participant claims to have met the bounty criteria by submitting proof.
    /// @param _bountyId The ID of the bounty being claimed.
    /// @param _claimProofHash IPFS/Arweave hash of the evidence proving the bounty criteria was met.
    function submitBountyClaim(uint256 _bountyId, string calldata _claimProofHash) external nonReentrant {
        PerformanceBounty storage bounty = performanceBounties[_bountyId];
        require(bounty.id != 0, "AetherMindCollective: Bounty not found");
        require(bounty.status == BountyStatus.Active, "AetherMindCollective: Bounty not active");
        require(bytes(_claimProofHash).length > 0, "AetherMindCollective: Claim proof hash cannot be empty");

        bounty.claimant = msg.sender;
        bounty.claimTimestamp = block.timestamp;
        bounty.claimProofHash = _claimProofHash;
        bounty.status = BountyStatus.Claimed;

        // Request oracle verification for the claim (e.g., re-evaluate model with claimant's improvements)
        // oracle.requestData(string(abi.encodePacked("verifyBountyClaim", _claimProofHash, bounty.targetMetricImprovement, toString(bounty.modelId), toString(_bountyId))));

        emit BountyClaimed(_bountyId, msg.sender);
    }

    /// @notice Validators (or oracle callback) verify the legitimacy of a bounty claim.
    /// @param _bountyId The ID of the bounty.
    /// @param _success True if the claim is verified as valid, false otherwise.
    function verifyBountyClaim(uint256 _bountyId, bool _success) external onlyDAO { // or restricted to oracle address
        PerformanceBounty storage bounty = performanceBounties[_bountyId];
        require(bounty.id != 0, "AetherMindCollective: Bounty not found");
        require(bounty.status == BountyStatus.Claimed, "AetherMindCollective: Bounty not in claimed state");
        require(block.timestamp < bounty.claimTimestamp + protocolParams.bountyClaimPeriod, "AetherMindCollective: Bounty claim verification period expired");

        bounty.verificationTimestamp = block.timestamp;
        if (_success) {
            bounty.status = BountyStatus.Verified;
        } else {
            bounty.status = BountyStatus.Failed;
            bounty.claimant = address(0); // Reset claimant if failed, allowing re-claim or new claims
        }
        emit BountyVerified(_bountyId, msg.sender, _success);
    }

    /// @notice Distributes the bounty rewards to the claimant if verified.
    /// @param _bountyId The ID of the bounty to distribute.
    function distributeBounty(uint256 _bountyId) external nonReentrant onlyDAO {
        PerformanceBounty storage bounty = performanceBounties[_bountyId];
        require(bounty.id != 0, "AetherMindCollective: Bounty not found");
        require(bounty.status == BountyStatus.Verified, "AetherMindCollective: Bounty not verified");
        require(bounty.claimant != address(0), "AetherMindCollective: No valid claimant");

        bounty.status = BountyStatus.Distributed;
        require(aetherToken.transfer(bounty.claimant, bounty.amount), "AetherMindCollective: Bounty transfer failed");

        // Reward the claimant with reputation and update NFT
        participants[bounty.claimant].reputation += (bounty.amount / (10 ** 18)) * 2; // Example: 2 reputation per AETH
        if (balanceOf(bounty.claimant) > 0) {
            uint256 tokenId = tokenOfOwnerByIndex(bounty.claimant, 0);
            _updateAetherMindAttributes(tokenId);
        }

        emit BountyDistributed(_bountyId, bounty.claimant, bounty.amount);
    }

    /// @notice Allows the bounty creator or DAO to cancel an active bounty and retrieve funds.
    /// @param _bountyId The ID of the bounty to cancel.
    function cancelBounty(uint256 _bountyId) external nonReentrant {
        PerformanceBounty storage bounty = performanceBounties[_bountyId];
        require(bounty.id != 0, "AetherMindCollective: Bounty not found");
        require(bounty.status == BountyStatus.Active, "AetherMindCollective: Bounty not in active state");
        require(msg.sender == bounty.creator || msg.sender == daoAddress, "AetherMindCollective: Only creator or DAO can cancel");

        bounty.status = BountyStatus.Canceled;
        require(aetherToken.transfer(bounty.creator, bounty.amount), "AetherMindCollective: Bounty refund failed");
        emit BountyCanceled(_bountyId, msg.sender);
    }

    // --- V. Staking & Rewards ---

    /// @notice Allows users to stake AETH tokens to become eligible validators.
    /// @param _amount The amount of AETH tokens to stake.
    function stakeForValidationRights(uint256 _amount) external nonReentrant {
        require(_amount >= protocolParams.minStakeForValidator, "AetherMindCollective: Stake amount too low for validation rights");
        require(aetherToken.transferFrom(msg.sender, address(this), _amount), "AetherMindCollective: AETH transfer failed");

        Participant storage participant = participants[msg.sender];
        participant.stakedAmount += _amount;
        participant.stakingTimestamp = block.timestamp;
        participant.isValidator = true; // Immediately grants validator status upon sufficient stake

        emit StakedForValidation(msg.sender, _amount);
    }

    /// @notice Allows validators to withdraw their staked tokens after a cooldown period.
    function withdrawStakedTokens() external nonReentrant {
        Participant storage participant = participants[msg.sender];
        require(participant.stakedAmount > 0, "AetherMindCollective: No tokens staked");
        require(block.timestamp >= participant.stakingTimestamp + protocolParams.stakingLockupPeriod, "AetherMindCollective: Staking lockup period not over");

        uint256 amountToWithdraw = participant.stakedAmount;
        participant.stakedAmount = 0;
        participant.isValidator = false; // Revoke validator status upon withdrawal

        require(aetherToken.transfer(msg.sender, amountToWithdraw), "AetherMindCollective: Withdrawal failed");
        emit StakedTokensWithdrawn(msg.sender, amountToWithdraw);
    }

    /// @notice Allows participants to claim accumulated rewards for various contributions.
    function claimContributionRewards() external nonReentrant {
        Participant storage participant = participants[msg.sender];
        require(participant.pendingAETHRewards > 0, "AetherMindCollective: No rewards to claim");
        require(participant.lastClaimTimestamp + 1 days < block.timestamp, "AetherMindCollective: Can only claim rewards once per day"); // Anti-spam

        uint256 amountToClaim = participant.pendingAETHRewards;
        participant.pendingAETHRewards = 0; // Reset pending rewards

        require(aetherToken.transfer(msg.sender, amountToClaim), "AetherMindCollective: Reward transfer failed");
        
        participant.lastClaimTimestamp = block.timestamp; // Update last claim time

        emit RewardsClaimed(msg.sender, amountToClaim);

        // Update AetherMind NFT (reputation isn't directly claimed, but earned for activity)
        if (balanceOf(msg.sender) > 0) {
            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, 0);
            _updateAetherMindAttributes(tokenId);
        }
    }

    // --- VI. DAO Governance Integration (Simplified) ---

    /// @notice Allows authorized entities (e.g., owner, or specific roles) to submit a proposal to the DAO.
    /// @dev This is a conceptual function and would interact with a real DAO contract's proposal function.
    /// @param _target The target contract address for the proposal (e.g., this contract itself for parameter changes).
    /// @param _value The value (ETH) to send with the proposal call.
    /// @param _signature The function signature to call on the target contract (e.g., "updateProtocolParameter(string,uint256)").
    /// @param _calldata The encoded calldata for the function call.
    /// @param _description A description of the proposal.
    function proposeGovernanceChange(address _target, uint256 _value, string calldata _signature, bytes calldata _calldata, string calldata _description) external onlyOwner { 
        require(daoAddress != address(0), "AetherMindCollective: DAO address not set");
        // In a real scenario, this would call a function on the DAO contract, e.g.:
        // IMyDAO(daoAddress).propose(_target, _value, abi.encodeWithSignature(_signature, _calldata), _description);
        emit GovernanceProposalSubmitted(0, msg.sender, _description); // Use a real proposal ID from DAO
    }

    /// @notice Placeholder for interaction with an external DAO contract's voting mechanism.
    /// @dev This function would typically be called externally by users interacting with the DAO directly.
    /// It's included here to demonstrate the conceptual flow.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support The vote (e.g., 0 for against, 1 for for, 2 for abstain for a Governor Bravo style DAO).
    function voteOnProposal(uint256 _proposalId, uint8 _support) external {
        require(daoAddress != address(0), "AetherMindCollective: DAO address not set");
        // IMyDAO(daoAddress).castVote(_proposalId, _support); // Conceptual call to external DAO
    }

    /// @notice Placeholder for interaction with an external DAO contract's execution mechanism.
    /// @dev This function would typically be called by the DAO executor after a proposal passes.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external onlyDAO {
        require(daoAddress != address(0), "AetherMindCollective: DAO address not set");
        // IMyDAO(daoAddress).execute(_proposalId); // Conceptual call to external DAO
    }

    // --- VII. View & Utility Functions ---

    /// @notice Retrieves the current configurable protocol parameters.
    /// @return A struct containing all current protocol parameters.
    function getProtocolParameters() external view returns (ProtocolParameters memory) {
        return protocolParams;
    }

    /// @notice Retrieves detailed information about a specific AI model.
    /// @param _modelId The ID of the AI model.
    /// @return An AIModel struct containing all model details.
    function getAIModelDetails(uint256 _modelId) external view returns (AIModel memory) {
        return aiModels[_modelId];
    }

    /// @notice Retrieves a specific participant's evaluation for a given model.
    /// @param _modelId The ID of the model.
    /// @param _evaluator The address of the evaluator.
    /// @return An Evaluation struct containing the details of the evaluation.
    function getParticipantModelEvaluation(uint256 _modelId, address _evaluator) external view returns (Evaluation memory) {
        return modelEvaluations[_modelId][_evaluator];
    }

    /// @notice Retrieves a summary of a user's contributions and reputation.
    /// @param _user The address of the user.
    /// @return A Participant struct containing user stats.
    function getUserContributionStats(address _user) external view returns (Participant memory) {
        return participants[_user];
    }

    /// @notice Retrieves details about a specific active or historical bounty.
    /// @param _bountyId The ID of the bounty.
    /// @return A PerformanceBounty struct.
    function getBountyDetails(uint256 _bountyId) external view returns (PerformanceBounty memory) {
        return performanceBounties[_bountyId];
    }

    // --- Internal Helpers ---

    /// @dev Converts a uint256 to a string. Helper for tokenURI.
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
```