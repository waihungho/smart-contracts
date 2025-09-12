Here's a Solidity smart contract named `CogniForge` that introduces an advanced, creative, and trendy concept: a decentralized platform for AI model refinement, dynamic Refinement NFTs (rNFTs), and on-chain intellectual property (IP) licensing for AI-generated content, complete with a basic dispute resolution mechanism.

The core idea is to foster community-driven AI model improvement, where contributions are tokenized as evolving NFTs, and the resulting AI-generated outputs can be licensed on-chain. This contract avoids direct duplication of common open-source projects by combining these elements into a novel system focused on the AI/Web3 intersection.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Interface for a hypothetical Oracle contract that submits evaluation results
interface IEvaluatorOracle {
    function submitEvaluation(uint256 _batchId, int256 _score, string calldata _reportURI) external;
}

/**
 * @title CogniForge
 * @dev A decentralized platform for AI model refinement, evaluation, and intellectual property management.
 *      Trainers submit refinement batches, evaluators assess them, leading to minting of dynamic Refinement NFTs (rNFTs).
 *      rNFT holders can register and license AI-generated IP assets. Includes a basic dispute resolution system.
 */
contract CogniForge is ERC721, Ownable {
    using Counters for Counters.Counter;

    // --- Outline and Function Summary ---

    // I. Core Management (Admin/Platform Level)
    // 1.  constructor(): Initializes platform parameters (oracle, arbiter, fees) and the ERC721 contract.
    // 2.  setEvaluatorOracleAddress(address _oracle): Sets the address of the trusted oracle for evaluation results. (Owner)
    // 3.  setDisputeArbiterAddress(address _arbiter): Sets the address responsible for resolving disputes. (Owner)
    // 4.  registerBaseAIModel(string calldata _modelHash, string calldata _metadataURI): Registers a new foundational AI model on the platform. (Owner)
    // 5.  updateBaseAIModelMetadata(uint256 _modelId, string calldata _newMetadataURI): Updates metadata for an existing base model. (Owner)
    // 6.  setDisputeResolutionFee(uint256 _fee): Sets the fee required to initiate a dispute. (Owner)
    // 7.  setMinimumEvaluationStake(uint256 _amount): Sets the minimum ETH amount an evaluator must stake for a batch. (Owner)

    // II. Refinement Batch Submission & Management
    // 8.  submitRefinementBatch(uint256 _baseModelId, string calldata _refinementDataURI, string calldata _description):
    //     Allows a 'Trainer' to submit new refinement data (e.g., fine-tuned weights, dataset) for a base AI model.
    // 9.  getRefinementBatchDetails(uint256 _batchId): Retrieves comprehensive details about a specific refinement batch. (View)
    // 10. withdrawRefinementBatch(uint256 _batchId): Allows a Trainer to withdraw their batch before evaluation is proposed.

    // III. Decentralized Evaluation
    // 11. proposeEvaluation(uint256 _batchId): An 'Evaluator' stakes ETH to signal intent to evaluate a batch.
    // 12. submitEvaluationResult(uint256 _batchId, int256 _score, string calldata _reportURI):
    //     Called by the designated `evaluatorOracleAddress` to submit the official evaluation score and report.
    // 13. claimEvaluationStake(uint256 _batchId): Allows a successful Evaluator to reclaim their stake (and potentially rewards).

    // IV. Dynamic Refinement NFTs (rNFTs)
    // 14. _mintRefinementNFT(uint256 _batchId, address _owner): Internal function to mint an rNFT upon successful evaluation.
    // 15. updateRefinementNFTMetadata(uint256 _tokenId, string calldata _newMetadataURI):
    //     Allows an rNFT holder to update their NFT's associated metadata (e.g., project details).
    // 16. evolveRefinementNFT(uint256 _tokenId, uint256 _newImpactMetric):
    //     Triggers an 'evolution' of the rNFT, updating its associated metadata (and potentially visual representation off-chain)
    //     based on a new impact metric. (Owner or designated oracle)
    // 17. tokenURI(uint256 tokenId): Overrides ERC721's tokenURI to provide dynamic metadata capability. (View)

    // V. AI-Generated IP & Licensing
    // 18. registerAIGeneratedIP(uint256 _refinementNFTId, string calldata _ipAssetURI, string calldata _ipType):
    //     rNFT holders register specific AI-generated IP (e.g., unique output, fine-tuned model) derived from their refinement.
    // 19. setIPLicenseTerms(uint256 _ipAssetId, uint256 _price, uint256 _durationSeconds):
    //     IP owner defines licensing terms (price, duration) for their registered AI-generated IP.
    // 20. purchaseIPLicense(uint256 _ipAssetId): Users purchase a license for a specific AI-generated IP asset.
    // 21. revokeIPLicense(uint256 _ipAssetId, address _licensee, uint256 _licenseId): IP owner revokes an active license.
    // 22. hasValidLicense(uint256 _ipAssetId, address _licensee): Checks if an address holds a valid, active license. (View)

    // VI. Dispute Resolution
    // 23. initiateDispute(uint256 _contextId, DisputeType _type, address _challenger, address _defendant) payable:
    //     Starts a dispute process (e.g., challenging an evaluation outcome or claiming IP infringement), requiring a fee.
    //     This function also covers the "challenge evaluation" functionality.
    // 24. submitDisputeEvidence(uint256 _disputeId, string calldata _evidenceURI):
    //     Participants in a dispute submit evidence to support their claims.
    // 25. resolveDispute(uint256 _disputeId, Resolution _resolution, address _winner):
    //     Called by the designated `disputeArbiterAddress` to finalize a dispute and determine its outcome.

    // --- State Variables ---

    // Counters for unique IDs across different entities
    Counters.Counter private _baseModelIds;
    Counters.Counter private _batchIds;
    Counters.Counter private _ipAssetIds;
    Counters.Counter private _licenseIds; // For tracking individual licenses
    Counters.Counter private _disputeIds;

    // Core platform addresses for trusted roles
    address public evaluatorOracleAddress; // Trusted oracle for submitting evaluation results
    address public disputeArbiterAddress;  // Address responsible for resolving disputes (e.g., DAO, multisig)

    // Configuration parameters
    uint256 public disputeResolutionFee;        // Fee (in Wei) to initiate a dispute
    uint256 public minimumEvaluationStake;      // Minimum ETH (in Wei) an evaluator must stake
    uint256 public evaluationRewardPercentage;  // Percentage of (future) platform fees allocated as reward (e.g., 500 for 5%)

    // Data structures for platform entities
    struct BaseAIModel {
        uint256 id;
        string modelHash;      // Unique identifier for the base model, e.g., IPFS hash of a weights file
        string metadataURI;    // URI to additional details (description, purpose, etc.)
        bool isActive;
        uint256 registeredTime;
    }
    mapping(uint256 => BaseAIModel) public baseModels;

    enum BatchStatus { Submitted, ProposedForEvaluation, Evaluating, Evaluated_Success, Evaluated_Failed, Challenged, Withdrawn }
    struct RefinementBatch {
        uint256 id;
        uint256 baseModelId;
        address trainer;
        string refinementDataURI; // URI to the refinement data (e.g., IPFS hash of fine-tuned weights or dataset)
        string description;
        uint256 submissionTime;
        BatchStatus status;
        int256 evaluationScore;   // Score provided by the oracle (e.g., -100 to 100)
        string evaluationReportURI; // URI to the detailed evaluation report
        address proposedEvaluator; // The address that proposed and staked for evaluation
        uint256 evaluationStake;   // Amount staked by the proposed evaluator
        bool rNFTMinted;           // True if an rNFT has been minted for this batch
    }
    mapping(uint256 => RefinementBatch) public refinementBatches;

    // Mapping from rNFT tokenId to its corresponding RefinementBatch ID
    mapping(uint256 => uint256) public rNFTBatchMapping; // tokenId -> batchId

    enum DisputeType { EvaluationOutcome, IPLicenseInfringement }
    enum DisputeStatus { Open, EvidenceGathering, Resolved_Accepted, Resolved_Rejected, Resolved_Challenged }
    enum Resolution { Undecided, AcceptClaim, RejectClaim } // For arbiter to decide
    struct Dispute {
        uint256 id;
        uint256 contextId;      // The ID of the item being disputed (e.g., batchId or ipAssetId)
        DisputeType disputeType;
        address initiator;
        uint256 initiationTime;
        DisputeStatus status;
        address challenger;     // For evaluation disputes, the party challenging the result
        address defendant;      // For IP disputes, the alleged infringer
        mapping(address => string[]) evidenceURIs; // Party -> list of evidence URIs
        Resolution resolution;  // Arbiter's final decision
        address winner;         // The address determined to be "correct" by the arbiter
        uint256 feeAmount;      // The fee paid to initiate the dispute
    }
    mapping(uint256 => Dispute) public disputes;

    struct AIGeneratedIP {
        uint256 id;
        uint256 refinementNFTId; // The rNFT from which this IP asset is derived
        address owner;
        string ipAssetURI;       // URI to the specific AI-generated asset (e.g., unique image, text, model output)
        string ipType;           // e.g., "Image", "TextSnippet", "ModelOutput", "FineTunedWeights"
        bool isLicensed;         // Can be licensed
        uint256 licensePrice;    // Price in ETH (Wei) for a license
        uint256 licenseDurationSeconds; // Duration of the license
        uint256 registeredTime;
    }
    mapping(uint256 => AIGeneratedIP) public aiGeneratedIPs;

    struct IPLicense {
        uint256 id;
        uint256 ipAssetId;
        address licensee;
        uint256 purchaseTime;
        uint256 expiryTime;
        bool isRevoked;
    }
    mapping(uint256 => mapping(address => IPLicense[])) public activeIPLicenses; // ipAssetId -> licensee -> list of licenses (to handle renewals/multiple)

    // --- Events ---
    event BaseAIModelRegistered(uint256 indexed modelId, string modelHash, string metadataURI);
    event BaseAIModelMetadataUpdated(uint256 indexed modelId, string newMetadataURI);
    event RefinementBatchSubmitted(uint256 indexed batchId, uint256 baseModelId, address indexed trainer, string refinementDataURI);
    event EvaluationProposed(uint256 indexed batchId, address indexed evaluator, uint256 stakedAmount);
    event EvaluationResultSubmitted(uint256 indexed batchId, int256 score, string reportURI, address indexed evaluator);
    event RefinementBatchWithdrawn(uint256 indexed batchId, address indexed trainer);
    event RefinementNFTMinted(uint256 indexed tokenId, uint256 indexed batchId, address indexed owner);
    event RefinementNFTMetadataUpdated(uint256 indexed tokenId, string newMetadataURI);
    event RefinementNFTEvolved(uint256 indexed tokenId, uint256 newImpactMetric, string newMetadataURI);
    event AIGeneratedIPRegistered(uint256 indexed ipAssetId, uint256 indexed refinementNFTId, address indexed owner, string ipAssetURI);
    event IPLicenseTermsSet(uint256 indexed ipAssetId, uint256 price, uint256 durationSeconds);
    event IPLicensePurchased(uint256 indexed ipAssetId, address indexed licensee, uint256 licenseId, uint256 expiryTime);
    event IPLicenseRevoked(uint256 indexed ipAssetId, address indexed licensee, uint256 licenseId);
    event DisputeInitiated(uint256 indexed disputeId, uint256 contextId, DisputeType disputeType, address indexed initiator);
    event DisputeEvidenceSubmitted(uint256 indexed disputeId, address indexed participant, string evidenceURI);
    event DisputeResolved(uint256 indexed disputeId, Resolution resolution, address indexed winner);
    event DisputeFeeUpdated(uint256 newFee);
    event MinimumEvaluationStakeUpdated(uint256 newStake);
    event EvaluatorOracleAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event DisputeArbiterAddressUpdated(address indexed oldAddress, address indexed newAddress);


    // --- Constructor ---
    /**
     * @dev Initializes the CogniForge contract, setting up the ERC721 token and core platform addresses and parameters.
     * @param _evaluatorOracleAddress The initial address of the trusted oracle for evaluation results.
     * @param _disputeArbiterAddress The initial address of the entity responsible for resolving disputes.
     * @param _disputeResolutionFee The initial fee (in Wei) to initiate a dispute.
     * @param _minimumEvaluationStake The initial minimum ETH amount (in Wei) an evaluator must stake.
     * @param _evaluationRewardPercentage The percentage (in basis points, e.g., 500 for 5%) for evaluator rewards from fees.
     */
    constructor(
        address _evaluatorOracleAddress,
        address _disputeArbiterAddress,
        uint256 _disputeResolutionFee,
        uint256 _minimumEvaluationStake,
        uint256 _evaluationRewardPercentage // e.g., 500 for 5%, max 10000 for 100%
    ) ERC721("RefinementNFT", "rNFT") Ownable(msg.sender) {
        require(_evaluatorOracleAddress != address(0), "Invalid oracle address");
        require(_disputeArbiterAddress != address(0), "Invalid arbiter address");
        evaluatorOracleAddress = _evaluatorOracleAddress;
        disputeArbiterAddress = _disputeArbiterAddress;
        disputeResolutionFee = _disputeResolutionFee;
        minimumEvaluationStake = _minimumEvaluationStake;
        require(_evaluationRewardPercentage <= 10000, "Reward percentage too high (max 10000 = 100%)");
        evaluationRewardPercentage = _evaluationRewardPercentage;
    }

    // --- Modifiers ---
    modifier onlyEvaluatorOracle() {
        require(msg.sender == evaluatorOracleAddress, "Only the designated evaluator oracle can call this function");
        _;
    }

    modifier onlyDisputeArbiter() {
        require(msg.sender == disputeArbiterAddress, "Only the designated dispute arbiter can call this function");
        _;
    }

    // --- I. Core Management (Admin/Platform Level) ---

    /**
     * @dev Sets the address of the trusted oracle responsible for submitting evaluation results.
     *      Only the contract owner can call this.
     * @param _oracle The new address for the evaluator oracle.
     */
    function setEvaluatorOracleAddress(address _oracle) external onlyOwner {
        require(_oracle != address(0), "Invalid oracle address");
        emit EvaluatorOracleAddressUpdated(evaluatorOracleAddress, _oracle);
        evaluatorOracleAddress = _oracle;
    }

    /**
     * @dev Sets the address of the entity (e.g., DAO, multisig, or individual) responsible for resolving disputes.
     *      Only the contract owner can call this.
     * @param _arbiter The new address for the dispute arbiter.
     */
    function setDisputeArbiterAddress(address _arbiter) external onlyOwner {
        require(_arbiter != address(0), "Invalid arbiter address");
        emit DisputeArbiterAddressUpdated(disputeArbiterAddress, _arbiter);
        disputeArbiterAddress = _arbiter;
    }

    /**
     * @dev Registers a new foundational AI model that can be refined by trainers.
     *      Only the contract owner can call this.
     * @param _modelHash A unique identifier for the base model (e.g., IPFS hash of a weights file).
     * @param _metadataURI URI to additional details about the model.
     * @return The ID of the newly registered base model.
     */
    function registerBaseAIModel(string calldata _modelHash, string calldata _metadataURI) external onlyOwner returns (uint256) {
        _baseModelIds.increment();
        uint256 modelId = _baseModelIds.current();
        baseModels[modelId] = BaseAIModel({
            id: modelId,
            modelHash: _modelHash,
            metadataURI: _metadataURI,
            isActive: true,
            registeredTime: block.timestamp
        });
        emit BaseAIModelRegistered(modelId, _modelHash, _metadataURI);
        return modelId;
    }

    /**
     * @dev Updates the metadata URI for an existing base AI model.
     *      Can be used to provide updated documentation or details. Only the contract owner can call this.
     * @param _modelId The ID of the base model to update.
     * @param _newMetadataURI The new URI for the model's metadata.
     */
    function updateBaseAIModelMetadata(uint256 _modelId, string calldata _newMetadataURI) external onlyOwner {
        require(baseModels[_modelId].isActive, "Base model does not exist or is inactive");
        baseModels[_modelId].metadataURI = _newMetadataURI;
        emit BaseAIModelMetadataUpdated(_modelId, _newMetadataURI);
    }

    /**
     * @dev Sets the fee required to initiate a dispute. Only the contract owner can call this.
     * @param _fee The new dispute resolution fee in Wei.
     */
    function setDisputeResolutionFee(uint256 _fee) external onlyOwner {
        disputeResolutionFee = _fee;
        emit DisputeFeeUpdated(_fee);
    }

    /**
     * @dev Sets the minimum ETH amount an evaluator must stake to propose an evaluation.
     *      Only the contract owner can call this.
     * @param _amount The new minimum stake amount in Wei.
     */
    function setMinimumEvaluationStake(uint256 _amount) external onlyOwner {
        minimumEvaluationStake = _amount;
        emit MinimumEvaluationStakeUpdated(_amount);
    }

    // --- II. Refinement Batch Submission & Management ---

    /**
     * @dev Allows a trainer to submit a new AI model refinement batch.
     *      The refinement data itself (e.g., fine-tuned weights, dataset) is expected to be off-chain (e.g., IPFS)
     *      and referenced by `_refinementDataURI`.
     * @param _baseModelId The ID of the base AI model being refined.
     * @param _refinementDataURI URI pointing to the refinement data.
     * @param _description A brief description of the refinement.
     * @return The ID of the newly submitted refinement batch.
     */
    function submitRefinementBatch(uint256 _baseModelId, string calldata _refinementDataURI, string calldata _description) external returns (uint256) {
        require(baseModels[_baseModelId].isActive, "Base model does not exist or is inactive");
        require(bytes(_refinementDataURI).length > 0, "Refinement data URI cannot be empty");

        _batchIds.increment();
        uint256 batchId = _batchIds.current();
        refinementBatches[batchId] = RefinementBatch({
            id: batchId,
            baseModelId: _baseModelId,
            trainer: msg.sender,
            refinementDataURI: _refinementDataURI,
            description: _description,
            submissionTime: block.timestamp,
            status: BatchStatus.Submitted,
            evaluationScore: 0,
            evaluationReportURI: "",
            proposedEvaluator: address(0),
            evaluationStake: 0,
            rNFTMinted: false
        });
        emit RefinementBatchSubmitted(batchId, _baseModelId, msg.sender, _refinementDataURI);
        return batchId;
    }

    /**
     * @dev Retrieves comprehensive details about a specific refinement batch.
     * @param _batchId The ID of the refinement batch.
     * @return A tuple containing all details of the batch.
     */
    function getRefinementBatchDetails(uint256 _batchId) external view returns (
        uint256 id, uint256 baseModelId, address trainer, string memory refinementDataURI,
        string memory description, uint256 submissionTime, BatchStatus status,
        int256 evaluationScore, string memory evaluationReportURI, address proposedEvaluator,
        uint256 evaluationStake, bool rNFTMinted
    ) {
        RefinementBatch storage batch = refinementBatches[_batchId];
        require(batch.id != 0, "Batch does not exist");
        return (
            batch.id, batch.baseModelId, batch.trainer, batch.refinementDataURI,
            batch.description, batch.submissionTime, batch.status,
            batch.evaluationScore, batch.evaluationReportURI, batch.proposedEvaluator,
            batch.evaluationStake, batch.rNFTMinted
        );
    }

    /**
     * @dev Allows a trainer to withdraw their refinement batch if it hasn't been proposed for evaluation yet.
     *      This prevents evaluation if the trainer decides to pull their contribution.
     * @param _batchId The ID of the batch to withdraw.
     */
    function withdrawRefinementBatch(uint256 _batchId) external {
        RefinementBatch storage batch = refinementBatches[_batchId];
        require(batch.id != 0, "Batch does not exist");
        require(batch.trainer == msg.sender, "Only the trainer can withdraw this batch");
        require(batch.status == BatchStatus.Submitted, "Batch cannot be withdrawn at this stage");

        batch.status = BatchStatus.Withdrawn;
        emit RefinementBatchWithdrawn(_batchId, msg.sender);
    }

    // --- III. Decentralized Evaluation ---

    /**
     * @dev An evaluator stakes Ether to signal their intent to evaluate a refinement batch.
     *      This locks the batch for evaluation and commits the evaluator.
     * @param _batchId The ID of the refinement batch to evaluate.
     */
    function proposeEvaluation(uint256 _batchId) external payable {
        RefinementBatch storage batch = refinementBatches[_batchId];
        require(batch.id != 0, "Batch does not exist");
        require(batch.status == BatchStatus.Submitted, "Batch is not in a 'Submitted' state for evaluation");
        require(msg.value >= minimumEvaluationStake, "Not enough ETH staked for evaluation");
        require(batch.proposedEvaluator == address(0), "Evaluation already proposed for this batch");

        batch.proposedEvaluator = msg.sender;
        batch.evaluationStake = msg.value;
        batch.status = BatchStatus.ProposedForEvaluation;

        emit EvaluationProposed(_batchId, msg.sender, msg.value);
    }

    /**
     * @dev Called by the designated `evaluatorOracleAddress` to submit the official evaluation score and report.
     *      This is the critical step where off-chain AI model evaluation results are recorded on-chain.
     * @param _batchId The ID of the refinement batch.
     * @param _score The evaluation score (e.g., -100 to 100, where >=0 might be 'success').
     * @param _reportURI URI to the detailed evaluation report (e.g., IPFS hash).
     */
    function submitEvaluationResult(uint256 _batchId, int256 _score, string calldata _reportURI) external onlyEvaluatorOracle {
        RefinementBatch storage batch = refinementBatches[_batchId];
        require(batch.id != 0, "Batch does not exist");
        require(batch.status == BatchStatus.ProposedForEvaluation, "Batch is not awaiting evaluation result");

        batch.evaluationScore = _score;
        batch.evaluationReportURI = _reportURI;

        if (_score >= 0) { // Simple threshold for "success"
            batch.status = BatchStatus.Evaluated_Success;
            // Internally mint the rNFT
            _mintRefinementNFT(_batchId, batch.trainer);
        } else {
            batch.status = BatchStatus.Evaluated_Failed;
        }

        emit EvaluationResultSubmitted(_batchId, _score, _reportURI, batch.proposedEvaluator);
    }

    /**
     * @dev Allows the successful evaluator to claim back their staked ETH.
     *      Can only be called if the batch was evaluated successfully and no challenge was made,
     *      or a challenge was resolved in favor of the evaluator.
     * @param _batchId The ID of the refinement batch.
     */
    function claimEvaluationStake(uint256 _batchId) external {
        RefinementBatch storage batch = refinementBatches[_batchId];
        require(batch.id != 0, "Batch does not exist");
        require(batch.proposedEvaluator == msg.sender, "Only the proposed evaluator can claim stake");
        require(batch.status == BatchStatus.Evaluated_Success, "Batch not successfully evaluated or in challenged state");
        require(batch.evaluationStake > 0, "No stake to claim");

        uint256 stakeAmount = batch.evaluationStake;
        batch.evaluationStake = 0; // Prevent double claims
        batch.proposedEvaluator = address(0); // Clear evaluator to allow future re-evaluation if needed

        // Transfer stake back to the evaluator
        payable(msg.sender).transfer(stakeAmount);
        // Additional rewards (e.g., from platform fees) could be distributed here.
    }


    // --- IV. Dynamic Refinement NFTs (rNFTs) ---

    /**
     * @dev Internal function to mint a Refinement NFT (rNFT) after a batch is successfully evaluated.
     *      The rNFT represents the trainer's contribution.
     * @param _batchId The ID of the refinement batch associated with this NFT.
     * @param _owner The address to which the rNFT will be minted.
     * @return The ID of the newly minted rNFT.
     */
    function _mintRefinementNFT(uint256 _batchId, address _owner) internal returns (uint256) {
        RefinementBatch storage batch = refinementBatches[_batchId];
        require(batch.status == BatchStatus.Evaluated_Success, "Can only mint rNFT for successfully evaluated batches");
        require(!batch.rNFTMinted, "rNFT already minted for this batch");

        uint256 tokenId = _batchIds.current(); // Reusing batch counter for token id, assuming unique enough
        _safeMint(_owner, tokenId);
        rNFTBatchMapping[tokenId] = _batchId;
        batch.rNFTMinted = true;

        // Set initial metadata URI. In a truly dynamic setup, `tokenURI` would handle rendering.
        _setTokenURI(tokenId, string(abi.encodePacked("ipfs://", Strings.toString(tokenId), "/initial_metadata.json")));

        emit RefinementNFTMinted(tokenId, _batchId, _owner);
        return tokenId;
    }

    /**
     * @dev Allows an rNFT holder to update their NFT's associated metadata URI.
     *      This could be for adding more detailed project descriptions or external links.
     * @param _tokenId The ID of the rNFT to update.
     * @param _newMetadataURI The new URI for the rNFT's metadata.
     */
    function updateRefinementNFTMetadata(uint256 _tokenId, string calldata _newMetadataURI) external {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Only rNFT owner or approved can update metadata");
        _setTokenURI(_tokenId, _newMetadataURI);
        emit RefinementNFTMetadataUpdated(_tokenId, _newMetadataURI);
    }

    /**
     * @dev Triggers an "evolution" of an rNFT, updating its visual or functional metadata
     *      based on a new external impact metric. This function would typically be called
     *      by a trusted oracle or governance mechanism (e.g., based on real-world model adoption, usage, or citation counts).
     *      The `tokenURI` function will then reflect this new state.
     *      Only the contract owner can call this, or a specifically designated 'Impact Oracle'.
     * @param _tokenId The ID of the rNFT to evolve.
     * @param _newImpactMetric A new metric value reflecting the rNFT's impact or evolution stage.
     *      (e.g., 0-100 for impact, or an enum for different stages).
     */
    function evolveRefinementNFT(uint256 _tokenId, uint256 _newImpactMetric) external onlyOwner { // Or `onlyImpactOracle` if implemented
        require(_exists(_tokenId), "rNFT does not exist");
        
        // In a fully dynamic NFT, tokenURI function would query on-chain state to generate metadata.
        // For this contract, we simulate by updating the `tokenURI` itself to reflect a new state.
        string memory newURI = string(abi.encodePacked("ipfs://", Strings.toString(_tokenId), "/evolved_metadata_", Strings.toString(_newImpactMetric), ".json"));
        _setTokenURI(_tokenId, newURI);

        emit RefinementNFTEvolved(_tokenId, _newImpactMetric, newURI);
    }

    /**
     * @dev Overrides ERC721's tokenURI to provide dynamic metadata capability.
     *      This function can be extended to fetch metadata from an external service
     *      that constructs JSON based on the rNFT's on-chain state (e.g., impact metrics).
     * @param tokenId The ID of the rNFT.
     * @return The URI pointing to the rNFT's metadata.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");
        return super.tokenURI(tokenId); // Returns the last set URI, which could be dynamic.
    }


    // --- V. AI-Generated IP & Licensing ---

    /**
     * @dev An rNFT holder can register a specific AI-generated IP asset derived from their refinement.
     *      This could be a unique image, text, or a snippet of a fine-tuned model.
     * @param _refinementNFTId The ID of the rNFT from which this IP asset is derived.
     * @param _ipAssetURI URI pointing to the AI-generated asset (e.g., IPFS hash).
     * @param _ipType A string describing the type of IP (e.g., "Image", "TextSnippet", "ModelOutput").
     * @return The ID of the newly registered IP asset.
     */
    function registerAIGeneratedIP(uint256 _refinementNFTId, string calldata _ipAssetURI, string calldata _ipType) external returns (uint256) {
        require(_exists(_refinementNFTId), "rNFT does not exist");
        require(ERC721.ownerOf(_refinementNFTId) == msg.sender, "Only rNFT owner can register IP for it");
        require(bytes(_ipAssetURI).length > 0, "IP asset URI cannot be empty");
        require(bytes(_ipType).length > 0, "IP type cannot be empty");

        _ipAssetIds.increment();
        uint256 ipAssetId = _ipAssetIds.current();
        aiGeneratedIPs[ipAssetId] = AIGeneratedIP({
            id: ipAssetId,
            refinementNFTId: _refinementNFTId,
            owner: msg.sender,
            ipAssetURI: _ipAssetURI,
            ipType: _ipType,
            isLicensed: false, // Default to false, owner sets terms later
            licensePrice: 0,
            licenseDurationSeconds: 0,
            registeredTime: block.timestamp
        });
        emit AIGeneratedIPRegistered(ipAssetId, _refinementNFTId, msg.sender, _ipAssetURI);
        return ipAssetId;
    }

    /**
     * @dev Sets or updates the licensing terms (price and duration) for a registered AI-generated IP asset.
     * @param _ipAssetId The ID of the AI-generated IP asset.
     * @param _price The price in Wei for a license.
     * @param _durationSeconds The duration of the license in seconds.
     */
    function setIPLicenseTerms(uint256 _ipAssetId, uint256 _price, uint256 _durationSeconds) external {
        AIGeneratedIP storage ipAsset = aiGeneratedIPs[_ipAssetId];
        require(ipAsset.id != 0, "IP asset does not exist");
        require(ipAsset.owner == msg.sender, "Only the IP asset owner can set license terms");
        require(_price > 0 && _durationSeconds > 0, "License price and duration must be greater than zero");

        ipAsset.isLicensed = true;
        ipAsset.licensePrice = _price;
        ipAsset.licenseDurationSeconds = _durationSeconds;
        emit IPLicenseTermsSet(_ipAssetId, _price, _durationSeconds);
    }

    /**
     * @dev Allows a user to purchase a license for a specific AI-generated IP asset.
     *      Requires sending the exact license price in ETH.
     * @param _ipAssetId The ID of the AI-generated IP asset to license.
     * @return The ID of the newly created license.
     */
    function purchaseIPLicense(uint256 _ipAssetId) external payable returns (uint256) {
        AIGeneratedIP storage ipAsset = aiGeneratedIPs[_ipAssetId];
        require(ipAsset.id != 0, "IP asset does not exist");
        require(ipAsset.isLicensed, "IP asset is not available for licensing or terms not set");
        require(msg.value == ipAsset.licensePrice, "Incorrect ETH amount sent for license purchase");

        // Transfer funds to the IP owner
        payable(ipAsset.owner).transfer(msg.value);

        _licenseIds.increment();
        uint256 licenseId = _licenseIds.current();
        uint256 expiryTime = block.timestamp + ipAsset.licenseDurationSeconds;

        IPLicense memory newLicense = IPLicense({
            id: licenseId,
            ipAssetId: _ipAssetId,
            licensee: msg.sender,
            purchaseTime: block.timestamp,
            expiryTime: expiryTime,
            isRevoked: false
        });
        activeIPLicenses[_ipAssetId][msg.sender].push(newLicense);

        emit IPLicensePurchased(_ipAssetId, msg.sender, licenseId, expiryTime);
        return licenseId;
    }

    /**
     * @dev Allows the IP owner to revoke an active license from a specific licensee.
     *      This does not refund the licensee. Useful for breach of terms (off-chain enforcement).
     * @param _ipAssetId The ID of the IP asset.
     * @param _licensee The address of the licensee whose license is to be revoked.
     * @param _licenseId The specific license ID to revoke (in case a licensee has multiple for the same IP).
     */
    function revokeIPLicense(uint256 _ipAssetId, address _licensee, uint256 _licenseId) external {
        AIGeneratedIP storage ipAsset = aiGeneratedIPs[_ipAssetId];
        require(ipAsset.id != 0, "IP asset does not exist");
        require(ipAsset.owner == msg.sender, "Only the IP owner can revoke a license");

        IPLicense[] storage licenses = activeIPLicenses[_ipAssetId][_licensee];
        bool found = false;
        for (uint i = 0; i < licenses.length; i++) {
            if (licenses[i].id == _licenseId && !licenses[i].isRevoked) {
                licenses[i].isRevoked = true;
                found = true;
                break;
            }
        }
        require(found, "License not found or already revoked for this licensee");

        emit IPLicenseRevoked(_ipAssetId, _licensee, _licenseId);
    }

    /**
     * @dev Checks if an address holds a valid, active license for a given IP asset.
     * @param _ipAssetId The ID of the IP asset.
     * @param _licensee The address to check for a license.
     * @return True if an active license is found, false otherwise.
     */
    function hasValidLicense(uint256 _ipAssetId, address _licensee) public view returns (bool) {
        IPLicense[] storage licenses = activeIPLicenses[_ipAssetId][_licensee];
        for (uint i = 0; i < licenses.length; i++) {
            if (!licenses[i].isRevoked && licenses[i].expiryTime > block.timestamp) {
                return true;
            }
        }
        return false;
    }


    // --- VI. Dispute Resolution ---

    /**
     * @dev Initiates a dispute process for an evaluation outcome or an IP license infringement.
     *      Requires a `disputeResolutionFee`. The fee is held by the contract until resolution.
     *      For EvaluationOutcome disputes, `_challenger` is the sender, and `_defendant` is the evaluator.
     *      For IPLicenseInfringement disputes, `_challenger` is the sender (IP owner), and `_defendant` is the alleged infringer.
     * @param _contextId The ID of the item being disputed (e.g., `batchId` for evaluation, `ipAssetId` for IP).
     * @param _type The type of dispute (EvaluationOutcome or IPLicenseInfringement).
     * @param _challenger The address initiating the dispute or challenging an outcome.
     * @param _defendant The address against whom the dispute is initiated.
     */
    function initiateDispute(
        uint256 _contextId,
        DisputeType _type,
        address _challenger, // Challenger (e.g., Trainer for eval, IP owner for IP dispute)
        address _defendant   // Defendant (e.g., Evaluator for eval, alleged infringer for IP dispute)
    ) external payable {
        require(msg.value >= disputeResolutionFee, "Insufficient fee to initiate dispute");
        require(_contextId != 0, "Invalid context ID");
        require(_challenger != address(0), "Challenger must be specified");
        require(_defendant != address(0), "Defendant must be specified");
        require(_challenger == msg.sender, "Challenger must be the transaction sender");
        require(_challenger != _defendant, "Challenger and defendant cannot be the same");


        if (_type == DisputeType.EvaluationOutcome) {
            RefinementBatch storage batch = refinementBatches[_contextId];
            require(batch.id != 0, "Evaluation batch does not exist");
            require(
                batch.status == BatchStatus.Evaluated_Success || batch.status == BatchStatus.Evaluated_Failed,
                "Batch not in a disputable evaluation state"
            );
            require(
                msg.sender == batch.trainer || msg.sender == batch.proposedEvaluator,
                "Only trainer or evaluator can challenge evaluation"
            );
            require(
                _defendant == batch.proposedEvaluator || _defendant == batch.trainer,
                "Defendant must be the other party involved in the evaluation"
            );
            require(batch.proposedEvaluator != address(0), "No evaluator proposed for this batch");
            batch.status = BatchStatus.Challenged; // Mark batch as challenged
        } else if (_type == DisputeType.IPLicenseInfringement) {
            AIGeneratedIP storage ipAsset = aiGeneratedIPs[_contextId];
            require(ipAsset.id != 0, "IP asset does not exist");
            require(ipAsset.owner == msg.sender, "Only IP owner can initiate infringement dispute");
        } else {
            revert("Invalid dispute type");
        }

        _disputeIds.increment();
        uint256 disputeId = _disputeIds.current();

        disputes[disputeId] = Dispute({
            id: disputeId,
            contextId: _contextId,
            disputeType: _type,
            initiator: msg.sender,
            initiationTime: block.timestamp,
            status: DisputeStatus.EvidenceGathering,
            challenger: _challenger,
            defendant: _defendant,
            resolution: Resolution.Undecided,
            winner: address(0),
            feeAmount: msg.value
        });

        emit DisputeInitiated(disputeId, _contextId, _type, msg.sender);
    }

    /**
     * @dev Allows participants in a dispute to submit evidence (e.g., IPFS hash of documents, logs).
     * @param _disputeId The ID of the dispute.
     * @param _evidenceURI URI pointing to the evidence (e.g., IPFS CID).
     */
    function submitDisputeEvidence(uint256 _disputeId, string calldata _evidenceURI) external {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.id != 0, "Dispute does not exist");
        require(dispute.status == DisputeStatus.EvidenceGathering, "Dispute is not in evidence gathering phase");
        require(
            msg.sender == dispute.initiator || msg.sender == dispute.challenger || msg.sender == dispute.defendant,
            "Only involved parties can submit evidence"
        );
        require(bytes(_evidenceURI).length > 0, "Evidence URI cannot be empty");

        dispute.evidenceURIs[msg.sender].push(_evidenceURI);
        emit DisputeEvidenceSubmitted(_disputeId, msg.sender, _evidenceURI);
    }

    /**
     * @dev Called by the designated `disputeArbiterAddress` to finalize a dispute.
     *      Distributes the dispute fee to the winner and updates related statuses.
     * @param _disputeId The ID of the dispute to resolve.
     * @param _resolution The arbiter's decision (AcceptClaim or RejectClaim).
     * @param _winner The address determined to be the winner of the dispute.
     */
    function resolveDispute(uint256 _disputeId, Resolution _resolution, address _winner) external onlyDisputeArbiter {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.id != 0, "Dispute does not exist");
        require(dispute.status == DisputeStatus.EvidenceGathering, "Dispute is not in evidence gathering phase");
        require(_resolution != Resolution.Undecided, "Invalid resolution");
        require(_winner != address(0), "Winner address cannot be zero");

        dispute.resolution = _resolution;
        dispute.winner = _winner;
        dispute.status = (_resolution == Resolution.AcceptClaim) ? DisputeStatus.Resolved_Accepted : DisputeStatus.Resolved_Rejected;

        // Transfer dispute fee to the winner
        payable(_winner).transfer(dispute.feeAmount);

        // Update status of related entities based on dispute type
        if (dispute.disputeType == DisputeType.EvaluationOutcome) {
            RefinementBatch storage batch = refinementBatches[dispute.contextId];
            if (_winner == dispute.challenger) { // Challenger won (e.g., Trainer successfully challenged a bad evaluation)
                batch.status = BatchStatus.Submitted; // Reset to allow re-evaluation or mark as failed
                batch.proposedEvaluator = address(0); // Clear previous evaluator
                batch.evaluationStake = 0; // Clear stake (already claimed/lost)
            } else { // Defendant won (original evaluation stands)
                batch.status = BatchStatus.Evaluated_Success; // Assume if it stood, it was successful
                if (!batch.rNFTMinted) {
                     _mintRefinementNFT(dispute.contextId, batch.trainer);
                }
            }
        }
        // For IP disputes, the outcome is recorded, but specific enforcement might be off-chain (legal action or platform-level bans)

        emit DisputeResolved(_disputeId, _resolution, _winner);
    }

    // --- Fallback & Receive Functions (for ETH handling) ---
    receive() external payable {}
    fallback() external payable {}
}
```