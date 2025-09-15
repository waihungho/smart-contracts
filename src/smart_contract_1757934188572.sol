Here's a smart contract named `AetherForge` written in Solidity, designed to be interesting, advanced, creative, and trendy. It focuses on the decentralized creation, training, and ownership of AI models, incorporating NFTs, data contribution with ZKP attestations, royalty distribution, and basic governance.

---

## Outline: AetherForge - Decentralized AI Model Training & Ownership Platform

This contract facilitates the decentralized creation, training, and ownership of AI models. It allows users to register AI model templates (blueprints), contribute data to train specific instances (represented as ERC721 NFTs), record off-chain training milestones, manage royalties for model usage, and participate in basic governance. A key concept is the integration point for Zero-Knowledge Proof (ZKP) attestations regarding data contributions, ensuring privacy while verifying contribution quality and rewarding contributors.

---

## Function Summary:

### I. Core AI Model & Template Management (NFTs)

1.  **`registerAIModelTemplate`**: Registers a new, unique AI model architecture template. This template serves as a blueprint from which trained AI model instances can be minted.
2.  **`updateAIModelTemplateURI`**: Allows the contract owner to update the metadata URI for an existing AI model template, enabling updates to its descriptive information.
3.  **`deregisterAIModelTemplate`**: Marks an AI model template as deprecated, preventing any new trained AI model instances from being minted from it.
4.  **`mintTrainedAIModelInstance`**: Mints a new ERC721 NFT, representing a specific, trained instance derived from an approved `AIModelTemplate`. This NFT is the core asset representing an AI model.
5.  **`transferTrainedAIModel`**: Allows the owner of a `TrainedAIModelInstance` NFT to transfer its ownership to another address, adhering to ERC721 standards.

### II. Data Contribution & Training Orchestration

6.  **`submitDataContribution`**: Records a data contribution made by a user to a specific `TrainedAIModelInstance`. This includes a hash of the data (kept off-chain) and a ZKP attestation hash for verifiable privacy and quality.
7.  **`verifyDataContributionAttestation`**: (Conceptual Integration) Marks a data contribution as verified. In a real-world scenario, this would involve an off-chain ZKP verification process or oracle attestation before being recorded on-chain.
8.  **`proposeTrainingMilestone`**: Allows the owner of a `TrainedAIModelInstance` to propose a new training milestone (e.g., achieving a certain performance metric), setting a goal and a potential reward allocation for contributors.
9.  **`approveTrainingMilestone`**: Allows the model owner to approve a proposed milestone, making it an active target for training efforts.
10. **`recordOffChainTrainingResult`**: Records the outcome of an off-chain training phase for an active and approved milestone, including the model's new checkpoint hash and a performance metric.

### III. Royalty & Usage Management

11. **`setAIModelInstanceRoyalty`**: Sets the royalty percentage that the `TrainedAIModelInstance` owner(s) and its data contributors will receive from its commercial usage.
12. **`recordModelUsagePayment`**: Records a payment (in ETH) received for the usage of a specific `TrainedAIModelInstance`. These funds accumulate for later distribution.
13. **`distributeRoyalties`**: Triggers the distribution of accumulated usage payments. A portion goes to the model owner, and the remaining funds are distributed among verified data contributors based on their `contributionAmount`.
14. **`claimContributorRewards`**: Allows individual data contributors to claim their share of earned royalties that have been distributed to the contract and allocated to them.

### IV. Governance & Staking

15. **`proposeModelParameterUpdate`**: Initiates a basic governance proposal to update a core parameter of a `TrainedAIModelInstance` (e.g., inference cost, minimum data quality requirements).
16. **`voteOnProposal`**: Allows designated voters (e.g., model owners for their specific models) to cast their vote (for or against) on an active governance proposal.
17. **`stakeForModelGuarantee`**: Enables users to stake funds (ETH) against a `TrainedAIModelInstance`'s promised performance or to gain access to premium features/data, with a defined unlock period.
18. **`unstakeFromModelGuarantee`**: Allows users to withdraw their staked funds once the specified unlock period has passed and conditions are met.

### V. Utility & Administrative

19. **`pauseContract`**: An emergency function, callable only by the contract owner, to temporarily halt critical operations of the contract.
20. **`unpauseContract`**: Function, callable only by the contract owner, to resume critical contract operations after a pause.
21. **`withdrawFunds`**: Allows the contract owner to withdraw accumulated protocol fees or other excess ETH held by the contract.
22. **`getAIModelTemplateDetails`**: Public view function to retrieve all stored details of a specific AI model template.
23. **`getTrainedAIModelInstanceDetails`**: Public view function to retrieve all stored details of a specific trained AI model instance.
24. **`getPendingContributorRewards`**: Public view function to check the total aggregated pending rewards for a specific contributor across all their contributions.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Explicitly used for clarity in calculations

// Outline: AetherForge - Decentralized AI Model Training & Ownership Platform
// This contract facilitates the decentralized creation, training, and ownership of AI models.
// It allows users to register AI model templates (blueprints), contribute data to train specific instances (represented as ERC721 NFTs),
// record off-chain training milestones, manage royalties for model usage, and participate in basic governance.
// A key concept is the integration point for Zero-Knowledge Proof (ZKP) attestations regarding data contributions,
// ensuring privacy while verifying contribution quality and rewarding contributors.

// Function Summary:

// I. Core AI Model & Template Management (NFTs)
// 1. registerAIModelTemplate: Registers a new, unique AI model architecture template.
// 2. updateAIModelTemplateURI: Updates the metadata URI for an existing AI model template.
// 3. deregisterAIModelTemplate: Marks an AI model template as deprecated.
// 4. mintTrainedAIModelInstance: Mints a new ERC721 NFT for a specific, trained instance.
// 5. transferTrainedAIModel: Allows transfer of a trained AI model instance NFT.

// II. Data Contribution & Training Orchestration
// 6. submitDataContribution: Records a data contribution to a trained AI model instance, with ZKP attestation hash.
// 7. verifyDataContributionAttestation: (Conceptual) Marks a contribution as verified after off-chain ZKP verification.
// 8. proposeTrainingMilestone: Allows model owner to propose a training milestone with a reward percentage.
// 9. approveTrainingMilestone: Allows model owner to approve a proposed milestone.
// 10. recordOffChainTrainingResult: Records off-chain training outcomes for an active milestone.

// III. Royalty & Usage Management
// 11. setAIModelInstanceRoyalty: Sets the royalty percentage for a trained model instance.
// 12. recordModelUsagePayment: Records a payment received for model usage.
// 13. distributeRoyalties: Distributes accumulated usage payments to model owner and contributors.
// 14. claimContributorRewards: Allows individual contributors to claim their allocated rewards.

// IV. Governance & Staking
// 15. proposeModelParameterUpdate: Proposes a governance vote to update model parameters.
// 16. voteOnProposal: Allows designated voters to cast their vote on a proposal.
// 17. stakeForModelGuarantee: Allows users to stake funds for model performance guarantees or access.
// 18. unstakeFromModelGuarantee: Allows users to withdraw staked funds after unlock period.

// V. Utility & Administrative
// 19. pauseContract: Emergency function to pause critical contract operations (owner-only).
// 20. unpauseContract: Function to resume critical contract operations (owner-only).
// 21. withdrawFunds: Allows contract owner to withdraw accumulated ETH.
// 22. getAIModelTemplateDetails: Public view function to retrieve details of a template.
// 23. getTrainedAIModelInstanceDetails: Public view function to retrieve details of a trained instance.
// 24. getPendingContributorRewards: Public view function to check pending rewards for a contributor.


contract AetherForge is ERC721, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables & Structs ---

    // The ERC721 token itself represents a 'Trained AI Model Instance'.
    // The constructor sets up the NFT collection name and symbol.
    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_) // e.g., "Trained AI Models", "TAIM"
        Ownable(msg.sender)
    {}

    // --- 1. AI Model Templates (Blueprints) ---
    Counters.Counter private _templateIds;

    struct AIModelTemplate {
        uint256 templateId;
        string name;
        string symbol; // Internal symbol for clarity, not ERC721 token symbol
        string uri; // Base URI for template metadata
        bytes32 modelArchitectureHash; // Unique hash of the model architecture (e.g., hash of a neural network config)
        address registeredBy;
        bool deprecated; // True if template is no longer active for minting
        uint256 createdAt;
    }

    mapping(uint256 => AIModelTemplate) public aiModelTemplates;
    mapping(bytes32 => bool) private _registeredArchitectureHashes; // Prevents duplicate architecture registration

    // --- 2. Trained AI Model Instances (ERC721 NFTs) ---
    Counters.Counter private _instanceIds;

    struct TrainedAIModelInstance {
        uint256 instanceId; // This is the ERC721 tokenId
        uint256 templateId; // Link to the base template this instance was minted from
        string modelSpecificUri; // URI for instance-specific metadata (e.g., trained parameters, performance report)
        address owner; // Cached owner for convenience (ERC721 handles actual ownership)
        uint96 royaltyNumerator; // Numerator for royalty calculation (e.g., 5 for 5%)
        uint96 royaltyDenominator; // Denominator for royalty calculation (e.g., 100 for 5%, or 1,000,000 for basis points)
        uint256 totalRoyaltiesCollected; // ETH collected for this model, awaiting distribution
        uint256 lastRoyaltyDistributionBlock; // Block number of the last royalty distribution
        uint256 createdAt;
        uint256[] dataContributionIds; // List of data contributions made to this model instance
        uint256[] milestoneIds; // List of training milestones for this instance
        bytes32 currentModelCheckpointHash; // Hash of the latest off-chain trained model checkpoint
        uint256 currentPerformanceMetric; // Latest recorded performance metric
    }

    mapping(uint256 => TrainedAIModelInstance) public trainedAIModelInstances; // instanceId => TrainedAIModelInstance data

    // --- 3. Data Contributions ---
    Counters.Counter private _contributionIds;

    struct DataContribution {
        uint256 contributionId;
        uint256 instanceId; // The model instance this data was contributed to
        address contributor;
        bytes32 dataHash; // Hash of the raw data (data itself remains off-chain)
        uint256 dataType; // Category of data (e.g., 0=text, 1=image, 2=audio, etc.)
        uint256 contributionAmount; // A quantitative metric for the volume/quality of the contribution
        bytes32 zkpAttestationHash; // Hash of a ZKP attestation, verifiable off-chain, proving data properties without revealing it
        bool isVerified; // True if the ZKP attestation (or other verification) passed
        uint256 submittedAt;
        uint256 earnedRoyalties; // Royalties accrued for this specific contribution, awaiting claim
        bool rewardsClaimed; // True if the contributor has claimed these rewards
    }

    mapping(uint256 => DataContribution) public dataContributions;
    mapping(address => uint256[]) public contributorToContributionIds; // contributor => list of their contribution IDs
    mapping(address => uint256) public pendingContributorRewards; // Aggregate pending rewards per contributor

    // --- 4. Training Milestones ---
    Counters.Counter private _milestoneIds;

    struct TrainingMilestone {
        uint256 milestoneId;
        uint256 instanceId;
        string description;
        uint256 rewardPoolPercentage; // % of `contributorPool` allocated to this milestone upon completion
        address proposedBy;
        bool approved; // Approved by model owner
        bytes32 modelCheckpointHash; // Final model checkpoint for this milestone
        uint256 performanceMetric; // Achieved performance metric for this milestone
        uint256 recordedAt; // Timestamp when result was recorded
        bool completed; // True if milestone outcome has been recorded
    }

    mapping(uint256 => TrainingMilestone) public trainingMilestones;

    // --- 5. Governance Proposals ---
    Counters.Counter private _proposalIds;

    enum ProposalStatus { Pending, Active, Succeeded, Failed, Executed }

    struct GovernanceProposal {
        uint256 proposalId;
        uint256 instanceId; // If related to a specific model instance, 0 otherwise for general proposals
        address proposer;
        string description;
        bytes32 parameterKey; // Hash of the parameter name (e.g., keccak256("inferenceCost"))
        bytes32 newValue; // Hash of the new value (e.g., keccak256(abi.encodePacked(100 ether)))
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 forVotes;
        uint256 againstVotes;
        ProposalStatus status;
        mapping(address => bool) hasVoted; // address => hasVoted (simplistic 1-vote per owner)
    }

    mapping(uint256 => GovernanceProposal) public governanceProposals;

    // --- 6. Staking for Guarantees/Access ---
    struct ModelStake {
        uint256 amount;
        uint256 stakedAt;
        uint256 unlockTime; // Block number when stake can be unstaked
        bool claimed;
    }

    mapping(uint256 => mapping(address => ModelStake)) public modelStakes; // instanceId => staker => stakeInfo
    mapping(uint256 => uint256) public totalStakedForModel; // instanceId => total amount staked

    // --- Events ---
    event AIModelTemplateRegistered(uint256 templateId, address indexed registeredBy, string name, bytes32 modelArchitectureHash);
    event AIModelTemplateUpdated(uint256 templateId, string newUri);
    event AIModelTemplateDeprecated(uint256 templateId);
    event TrainedAIModelMinted(uint256 indexed instanceId, uint256 templateId, address indexed owner);
    event DataContributionSubmitted(uint256 indexed contributionId, uint256 indexed instanceId, address indexed contributor, bytes32 dataHash, bytes32 zkpAttestationHash);
    event DataContributionVerified(uint256 indexed contributionId, uint256 indexed instanceId);
    event TrainingMilestoneProposed(uint256 indexed milestoneId, uint256 indexed instanceId, string description);
    event TrainingMilestoneApproved(uint256 indexed milestoneId, uint256 indexed instanceId);
    event OffChainTrainingResultRecorded(uint256 indexed instanceId, uint256 indexed milestoneId, bytes32 modelCheckpointHash, uint256 performanceMetric);
    event RoyaltyPercentageSet(uint256 indexed instanceId, uint96 royaltyNumerator, uint96 royaltyDenominator);
    event ModelUsagePaymentRecorded(uint256 indexed instanceId, uint256 amount);
    event RoyaltiesDistributed(uint256 indexed instanceId, uint256 distributedAmount);
    event ContributorRewardsClaimed(uint256 indexed contributionId, address indexed contributor, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, uint256 indexed instanceId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalStatusChanged(uint256 indexed proposalId, ProposalStatus newStatus);
    event StakedForModel(uint256 indexed instanceId, address indexed staker, uint256 amount, uint256 unlockTime);
    event UnstakedFromModel(uint256 indexed instanceId, address indexed staker, uint256 amount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);

    // --- Modifiers ---
    modifier onlyModelOwner(uint256 _instanceId) {
        require(trainedAIModelInstances[_instanceId].instanceId != 0, "AetherForge: Model instance does not exist");
        require(ownerOf(_instanceId) == _msgSender(), "AetherForge: Not the owner of this model instance");
        _;
    }

    // --- I. Core AI Model & Template Management (NFTs) ---

    /**
     * @notice Registers a new, unique AI model architecture template.
     * @param _name The name of the AI model template.
     * @param _symbol An internal symbol/short code for the template.
     * @param _uri The base URI for metadata associated with this template.
     * @param _modelArchitectureHash A unique hash identifying the AI model's architecture.
     * @return The ID of the newly registered template.
     */
    function registerAIModelTemplate(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        bytes32 _modelArchitectureHash
    ) public onlyOwner whenNotPaused returns (uint256) {
        require(!_registeredArchitectureHashes[_modelArchitectureHash], "AetherForge: Architecture hash already registered");

        _templateIds.increment();
        uint256 newTemplateId = _templateIds.current();

        aiModelTemplates[newTemplateId] = AIModelTemplate({
            templateId: newTemplateId,
            name: _name,
            symbol: _symbol,
            uri: _uri,
            modelArchitectureHash: _modelArchitectureHash,
            registeredBy: _msgSender(),
            deprecated: false,
            createdAt: block.timestamp
        });

        _registeredArchitectureHashes[_modelArchitectureHash] = true;

        emit AIModelTemplateRegistered(newTemplateId, _msgSender(), _name, _modelArchitectureHash);
        return newTemplateId;
    }

    /**
     * @notice Updates the metadata URI for an existing AI model template.
     * @param _templateId The ID of the template to update.
     * @param _newUri The new URI for the template's metadata.
     */
    function updateAIModelTemplateURI(
        uint256 _templateId,
        string memory _newUri
    ) public onlyOwner whenNotPaused {
        require(aiModelTemplates[_templateId].templateId != 0, "AetherForge: Template does not exist");
        aiModelTemplates[_templateId].uri = _newUri;
        emit AIModelTemplateUpdated(_templateId, _newUri);
    }

    /**
     * @notice Marks an AI model template as deprecated, preventing further minting from it.
     * @param _templateId The ID of the template to deprecate.
     */
    function deregisterAIModelTemplate(uint256 _templateId) public onlyOwner whenNotPaused {
        require(aiModelTemplates[_templateId].templateId != 0, "AetherForge: Template does not exist");
        require(!aiModelTemplates[_templateId].deprecated, "AetherForge: Template already deprecated");
        aiModelTemplates[_templateId].deprecated = true;
        emit AIModelTemplateDeprecated(_templateId);
    }

    /**
     * @notice Mints a new ERC721 NFT representing a specific, trained instance derived from a template.
     * @param _templateId The ID of the template to use as a blueprint.
     * @param _owner The address that will own the new trained AI model instance NFT.
     * @param _modelSpecificUri The URI for instance-specific metadata (e.g., trained weights, performance).
     * @return The ID of the newly minted trained AI model instance.
     */
    function mintTrainedAIModelInstance(
        uint256 _templateId,
        address _owner,
        string memory _modelSpecificUri
    ) public whenNotPaused returns (uint256) {
        require(aiModelTemplates[_templateId].templateId != 0, "AetherForge: Template does not exist");
        require(!aiModelTemplates[_templateId].deprecated, "AetherForge: Template is deprecated");
        require(_owner != address(0), "AetherForge: Invalid owner address");

        _instanceIds.increment();
        uint256 newInstanceId = _instanceIds.current();

        _mint(_owner, newInstanceId); // ERC721 minting
        _setTokenURI(newInstanceId, _modelSpecificUri); // Set URI for the instance NFT

        trainedAIModelInstances[newInstanceId] = TrainedAIModelInstance({
            instanceId: newInstanceId,
            templateId: _templateId,
            modelSpecificUri: _modelSpecificUri,
            owner: _owner, // Cache the owner, will be updated by ERC721 transfers
            royaltyNumerator: 0, // Default to 0, can be set later
            royaltyDenominator: 1000000, // Default basis points
            totalRoyaltiesCollected: 0,
            lastRoyaltyDistributionBlock: block.number,
            createdAt: block.timestamp,
            dataContributionIds: new uint256[](0),
            milestoneIds: new uint256[](0),
            currentModelCheckpointHash: bytes32(0),
            currentPerformanceMetric: 0
        });

        emit TrainedAIModelMinted(newInstanceId, _templateId, _owner);
        return newInstanceId;
    }

    /**
     * @notice Allows the owner to transfer a trained AI model instance NFT to another address.
     * @param _instanceId The ID of the trained AI model instance to transfer.
     * @param _to The recipient address.
     */
    function transferTrainedAIModel(uint256 _instanceId, address _to) public whenNotPaused {
        require(_exists(_instanceId), "AetherForge: Trained AI Model does not exist");
        require(ownerOf(_instanceId) == _msgSender(), "AetherForge: Caller is not the owner of the model instance");
        // Using ERC721's safeTransferFrom ensures _to is a contract that can receive ERC721 tokens if applicable.
        safeTransferFrom(_msgSender(), _to, _instanceId);
        trainedAIModelInstances[_instanceId].owner = _to; // Update the cached owner in our struct
    }

    // --- II. Data Contribution & Training Orchestration ---

    /**
     * @notice Records a data contribution made by a user to a specific trained AI model instance.
     * @param _instanceId The ID of the model instance receiving the contribution.
     * @param _dataHash A hash of the actual data (kept off-chain for privacy and storage reasons).
     * @param _dataType A numerical categorization of the data (e.g., 0 for text, 1 for images).
     * @param _contributionAmount A metric representing the volume or quality of the data contributed.
     * @param _zkpAttestationHash A hash of a Zero-Knowledge Proof attestation, to be verified off-chain.
     */
    function submitDataContribution(
        uint256 _instanceId,
        bytes32 _dataHash,
        uint256 _dataType,
        uint256 _contributionAmount,
        bytes32 _zkpAttestationHash
    ) public whenNotPaused {
        require(trainedAIModelInstances[_instanceId].instanceId != 0, "AetherForge: Model instance does not exist");
        require(_contributionAmount > 0, "AetherForge: Contribution amount must be positive");

        _contributionIds.increment();
        uint256 newContributionId = _contributionIds.current();

        dataContributions[newContributionId] = DataContribution({
            contributionId: newContributionId,
            instanceId: _instanceId,
            contributor: _msgSender(),
            dataHash: _dataHash,
            dataType: _dataType,
            contributionAmount: _contributionAmount,
            zkpAttestationHash: _zkpAttestationHash,
            isVerified: false,
            submittedAt: block.timestamp,
            earnedRoyalties: 0,
            rewardsClaimed: false
        });

        trainedAIModelInstances[_instanceId].dataContributionIds.push(newContributionId);
        contributorToContributionIds[_msgSender()].push(newContributionId);

        emit DataContributionSubmitted(newContributionId, _instanceId, _msgSender(), _dataHash, _zkpAttestationHash);
    }

    /**
     * @notice (Conceptual Integration) Marks a data contribution as verified after an off-chain ZKP verification.
     * @dev In a full implementation, this function would typically involve an external ZKP verifier contract
     *      or an oracle that attests to the validity of the ZKP. For this example, the model owner serves
     *      as the attester, representing the success of an off-chain verification process.
     * @param _contributionId The ID of the data contribution to verify.
     */
    function verifyDataContributionAttestation(
        uint256 _contributionId
    ) public onlyModelOwner(dataContributions[_contributionId].instanceId) whenNotPaused {
        require(dataContributions[_contributionId].contributionId != 0, "AetherForge: Contribution does not exist");
        require(!dataContributions[_contributionId].isVerified, "AetherForge: Contribution already verified");
        require(dataContributions[_contributionId].instanceId != 0, "AetherForge: Contribution not linked to valid instance");

        // Conceptual: Here, an external call to a ZKP verifier contract (e.g., IVerifier(ZK_VERIFIER_ADDRESS).verify(...))
        // or a trusted off-chain process would confirm the ZKP attestation.
        // For simplicity, we assume the model owner triggers this after off-chain confirmation.
        dataContributions[_contributionId].isVerified = true;

        emit DataContributionVerified(_contributionId, dataContributions[_contributionId].instanceId);
    }

    /**
     * @notice Allows the model owner to propose a new training milestone for an AI model instance.
     * @param _instanceId The ID of the model instance.
     * @param _milestoneDescription A description of the milestone (e.g., "Achieve 90% accuracy on X dataset").
     * @param _rewardPoolPercentage The percentage of the remaining undistributed royalties that
     *        will be allocated to this milestone's contributors upon completion.
     * @return The ID of the newly proposed milestone.
     */
    function proposeTrainingMilestone(
        uint256 _instanceId,
        string memory _milestoneDescription,
        uint256 _rewardPoolPercentage
    ) public onlyModelOwner(_instanceId) whenNotPaused returns (uint256) {
        require(trainedAIModelInstances[_instanceId].instanceId != 0, "AetherForge: Model instance does not exist");
        require(_rewardPoolPercentage <= 100, "AetherForge: Reward percentage cannot exceed 100");

        _milestoneIds.increment();
        uint256 newMilestoneId = _milestoneIds.current();

        trainingMilestones[newMilestoneId] = TrainingMilestone({
            milestoneId: newMilestoneId,
            instanceId: _instanceId,
            description: _milestoneDescription,
            rewardPoolPercentage: _rewardPoolPercentage,
            proposedBy: _msgSender(),
            approved: false,
            modelCheckpointHash: bytes32(0),
            performanceMetric: 0,
            recordedAt: 0,
            completed: false
        });

        trainedAIModelInstances[_instanceId].milestoneIds.push(newMilestoneId);

        emit TrainingMilestoneProposed(newMilestoneId, _instanceId, _milestoneDescription);
        return newMilestoneId;
    }

    /**
     * @notice Allows the model owner to approve a proposed training milestone, making it active.
     * @param _milestoneId The ID of the milestone to approve.
     */
    function approveTrainingMilestone(uint256 _milestoneId) public onlyModelOwner(trainingMilestones[_milestoneId].instanceId) whenNotPaused {
        require(trainingMilestones[_milestoneId].milestoneId != 0, "AetherForge: Milestone does not exist");
        require(!trainingMilestones[_milestoneId].approved, "AetherForge: Milestone already approved");
        trainingMilestones[_milestoneId].approved = true;
        emit TrainingMilestoneApproved(_milestoneId, trainingMilestones[_milestoneId].instanceId);
    }

    /**
     * @notice Records the outcome of an off-chain training phase for an active and approved milestone.
     * @param _milestoneId The ID of the milestone for which results are being recorded.
     * @param _modelCheckpointHash The hash of the model checkpoint achieved after this training phase.
     * @param _performanceMetric The numerical performance metric achieved (e.g., accuracy, F1 score).
     */
    function recordOffChainTrainingResult(
        uint256 _milestoneId,
        bytes32 _modelCheckpointHash,
        uint256 _performanceMetric
    ) public onlyModelOwner(trainingMilestones[_milestoneId].instanceId) whenNotPaused {
        require(trainingMilestones[_milestoneId].milestoneId != 0, "AetherForge: Milestone does not exist");
        require(trainingMilestones[_milestoneId].approved, "AetherForge: Milestone not yet approved");
        require(!trainingMilestones[_milestoneId].completed, "AetherForge: Milestone already completed");

        trainingMilestones[_milestoneId].modelCheckpointHash = _modelCheckpointHash;
        trainingMilestones[_milestoneId].performanceMetric = _performanceMetric;
        trainingMilestones[_milestoneId].recordedAt = block.timestamp;
        trainingMilestones[_milestoneId].completed = true;

        // Update the overall instance's latest checkpoint and performance
        uint256 instanceId = trainingMilestones[_milestoneId].instanceId;
        trainedAIModelInstances[instanceId].currentModelCheckpointHash = _modelCheckpointHash;
        trainedAIModelInstances[instanceId].currentPerformanceMetric = _performanceMetric;

        emit OffChainTrainingResultRecorded(instanceId, _milestoneId, _modelCheckpointHash, _performanceMetric);
    }

    // --- III. Royalty & Usage Management ---

    /**
     * @notice Sets the royalty percentage that the trained model instance owner(s) and contributors
     *         will receive from its usage.
     * @param _instanceId The ID of the model instance.
     * @param _royaltyNumerator The numerator of the royalty fraction (e.g., 5 for 5%).
     * @param _royaltyDenominator The denominator of the royalty fraction (e.g., 100 for 5%).
     */
    function setAIModelInstanceRoyalty(
        uint256 _instanceId,
        uint96 _royaltyNumerator,
        uint96 _royaltyDenominator
    ) public onlyModelOwner(_instanceId) whenNotPaused {
        require(trainedAIModelInstances[_instanceId].instanceId != 0, "AetherForge: Model instance does not exist");
        require(_royaltyDenominator > 0, "AetherForge: Denominator must be greater than 0");
        require(_royaltyNumerator <= _royaltyDenominator, "AetherForge: Numerator cannot exceed denominator");

        trainedAIModelInstances[_instanceId].royaltyNumerator = _royaltyNumerator;
        trainedAIModelInstances[_instanceId].royaltyDenominator = _royaltyDenominator;

        emit RoyaltyPercentageSet(_instanceId, _royaltyNumerator, _royaltyDenominator);
    }

    /**
     * @notice Records a payment received for the usage of a specific AI model instance.
     *         The `msg.value` sent with this transaction is added to the model's royalty pool.
     * @param _instanceId The ID of the model instance for which payment is being made.
     */
    function recordModelUsagePayment(uint256 _instanceId) public payable whenNotPaused nonReentrant {
        require(trainedAIModelInstances[_instanceId].instanceId != 0, "AetherForge: Model instance does not exist");
        require(msg.value > 0, "AetherForge: Payment amount must be positive");

        trainedAIModelInstances[_instanceId].totalRoyaltiesCollected = trainedAIModelInstances[_instanceId].totalRoyaltiesCollected.add(msg.value);

        emit ModelUsagePaymentRecorded(_instanceId, msg.value);
    }

    /**
     * @notice Triggers the distribution of accumulated usage payments for a specific model instance.
     * @dev Funds are split between the model owner and verified data contributors based on their
     *      `contributionAmount`. The `royaltyNumerator`/`royaltyDenominator` define the owner's share.
     *      The remaining pool is split among contributors.
     * @param _instanceId The ID of the model instance for which royalties are to be distributed.
     */
    function distributeRoyalties(uint256 _instanceId) public whenNotPaused nonReentrant {
        TrainedAIModelInstance storage model = trainedAIModelInstances[_instanceId];
        require(model.instanceId != 0, "AetherForge: Model instance does not exist");
        require(model.totalRoyaltiesCollected > 0, "AetherForge: No royalties to distribute for this model");

        uint256 availableFunds = model.totalRoyaltiesCollected;
        model.totalRoyaltiesCollected = 0; // Reset for next cycle

        uint256 modelOwnerShare = availableFunds.mul(model.royaltyNumerator).div(model.royaltyDenominator);
        uint256 contributorPool = availableFunds.sub(modelOwnerShare);

        // Distribute to model owner
        if (modelOwnerShare > 0) {
            payable(model.owner).transfer(modelOwnerShare);
        }

        uint256 totalVerifiedContributionAmount = 0;
        for (uint256 i = 0; i < model.dataContributionIds.length; i++) {
            DataContribution storage contribution = dataContributions[model.dataContributionIds[i]];
            if (contribution.isVerified) {
                totalVerifiedContributionAmount = totalVerifiedContributionAmount.add(contribution.contributionAmount);
            }
        }

        // Distribute to contributors
        if (contributorPool > 0 && totalVerifiedContributionAmount > 0) {
            for (uint256 i = 0; i < model.dataContributionIds.length; i++) {
                DataContribution storage contribution = dataContributions[model.dataContributionIds[i]];
                if (contribution.isVerified) {
                    uint256 contributorShare = contributorPool.mul(contribution.contributionAmount).div(totalVerifiedContributionAmount);
                    if (contributorShare > 0) {
                        contribution.earnedRoyalties = contribution.earnedRoyalties.add(contributorShare);
                        pendingContributorRewards[contribution.contributor] = pendingContributorRewards[contribution.contributor].add(contributorShare);
                    }
                }
            }
        }

        model.lastRoyaltyDistributionBlock = block.number;

        emit RoyaltiesDistributed(_instanceId, availableFunds);
    }

    /**
     * @notice Allows individual data contributors to claim their share of earned royalties.
     * @param _contributionId The ID of the specific data contribution for which rewards are claimed.
     */
    function claimContributorRewards(uint256 _contributionId) public whenNotPaused nonReentrant {
        DataContribution storage contribution = dataContributions[_contributionId];
        require(contribution.contributionId != 0, "AetherForge: Contribution does not exist");
        require(contribution.contributor == _msgSender(), "AetherForge: Not the contributor of this data");
        require(contribution.earnedRoyalties > 0, "AetherForge: No pending rewards for this contribution");
        require(!contribution.rewardsClaimed, "AetherForge: Rewards already claimed for this contribution");

        uint256 rewards = contribution.earnedRoyalties;
        contribution.earnedRoyalties = 0;
        contribution.rewardsClaimed = true;

        pendingContributorRewards[_msgSender()] = pendingContributorRewards[_msgSender()].sub(rewards);

        payable(_msgSender()).transfer(rewards);

        emit ContributorRewardsClaimed(_contributionId, _msgSender(), rewards);
    }

    // --- IV. Governance & Staking ---

    /**
     * @notice Proposes a governance vote to update a core parameter of a trained AI model instance.
     * @dev This is a simplified voting mechanism.
     * @param _instanceId The ID of the model instance for which the parameter update is proposed.
     * @param _description A detailed description of the proposed change.
     * @param _parameterKey A hash representing the parameter to be updated (e.g., `keccak256("inferenceCost")`).
     * @param _newValue A hash representing the new value for the parameter (can encode complex data).
     * @param _votingPeriodBlocks The number of blocks for which the voting will be active.
     * @return The ID of the newly created proposal.
     */
    function proposeModelParameterUpdate(
        uint256 _instanceId,
        string memory _description,
        bytes32 _parameterKey,
        bytes32 _newValue,
        uint256 _votingPeriodBlocks
    ) public onlyModelOwner(_instanceId) whenNotPaused returns (uint256) {
        require(trainedAIModelInstances[_instanceId].instanceId != 0, "AetherForge: Model instance does not exist");
        require(_votingPeriodBlocks > 0, "AetherForge: Voting period must be positive");

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        GovernanceProposal storage proposal = governanceProposals[newProposalId];
        proposal.proposalId = newProposalId;
        proposal.instanceId = _instanceId;
        proposal.proposer = _msgSender();
        proposal.description = _description;
        proposal.parameterKey = _parameterKey;
        proposal.newValue = _newValue;
        proposal.voteStartTime = block.number;
        proposal.voteEndTime = block.number.add(_votingPeriodBlocks);
        proposal.status = ProposalStatus.Active;

        emit ProposalCreated(newProposalId, _instanceId, _msgSender(), _description);
        return newProposalId;
    }

    /**
     * @notice Allows designated voters (currently only the model owner for their model's proposals)
     *         to cast their vote on an active proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public onlyModelOwner(governanceProposals[_proposalId].instanceId) whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.proposalId != 0, "AetherForge: Proposal does not exist");
        require(proposal.status == ProposalStatus.Active, "AetherForge: Proposal not active");
        require(block.number >= proposal.voteStartTime && block.number <= proposal.voteEndTime, "AetherForge: Voting period is closed");
        require(!proposal.hasVoted[_msgSender()], "AetherForge: Already voted on this proposal");

        if (_support) {
            proposal.forVotes = proposal.forVotes.add(1); // Simplistic: 1 vote per model owner
        } else {
            proposal.againstVotes = proposal.againstVotes.add(1);
        }
        proposal.hasVoted[_msgSender()] = true;

        emit Voted(_proposalId, _msgSender(), _support);

        // Optionally, auto-resolve proposal if voting period ends or certain conditions are met
        _checkAndResolveProposal(_proposalId);
    }

    /**
     * @notice Internal function to check and resolve proposal status once voting period ends.
     * @param _proposalId The ID of the proposal to check.
     */
    function _checkAndResolveProposal(uint256 _proposalId) internal {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        // Only resolve if active and voting period has ended
        if (proposal.status == ProposalStatus.Active && block.number > proposal.voteEndTime) {
            if (proposal.forVotes > proposal.againstVotes) {
                proposal.status = ProposalStatus.Succeeded;
                // In a real system, a separate `executeProposal` function would be called
                // by anyone after a proposal succeeds, to enact the changes safely.
                // For this example, we'll just set the status.
            } else {
                proposal.status = ProposalStatus.Failed;
            }
            emit ProposalStatusChanged(_proposalId, proposal.status);
        }
    }

    /**
     * @notice Allows users to stake funds against a trained AI model's promised performance
     *         or to gain access to premium features/data related to the model.
     * @param _instanceId The ID of the model instance to stake against.
     * @param _unlockPeriodBlocks The number of blocks for which the stake will be locked.
     */
    function stakeForModelGuarantee(uint256 _instanceId, uint256 _unlockPeriodBlocks) public payable whenNotPaused nonReentrant {
        require(trainedAIModelInstances[_instanceId].instanceId != 0, "AetherForge: Model instance does not exist");
        require(msg.value > 0, "AetherForge: Stake amount must be positive");
        require(_unlockPeriodBlocks > 0, "AetherForge: Unlock period must be positive");
        // Simplified: only one stake per address per model at a time. Could be extended.
        require(modelStakes[_instanceId][_msgSender()].amount == 0, "AetherForge: Already staked for this model");

        modelStakes[_instanceId][_msgSender()] = ModelStake({
            amount: msg.value,
            stakedAt: block.timestamp,
            unlockTime: block.number.add(_unlockPeriodBlocks),
            claimed: false
        });

        totalStakedForModel[_instanceId] = totalStakedForModel[_instanceId].add(msg.value);

        emit StakedForModel(_instanceId, _msgSender(), msg.value, modelStakes[_instanceId][_msgSender()].unlockTime);
    }

    /**
     * @notice Allows users to withdraw their staked funds after the specified unlock period has passed.
     * @param _instanceId The ID of the model instance from which to unstake.
     */
    function unstakeFromModelGuarantee(uint256 _instanceId) public whenNotPaused nonReentrant {
        ModelStake storage stake = modelStakes[_instanceId][_msgSender()];
        require(stake.amount > 0, "AetherForge: No active stake found for this model from sender");
        require(block.number >= stake.unlockTime, "AetherForge: Stake is still locked");
        require(!stake.claimed, "AetherForge: Stake already claimed");

        stake.claimed = true;
        totalStakedForModel[_instanceId] = totalStakedForModel[_instanceId].sub(stake.amount);

        payable(_msgSender()).transfer(stake.amount);

        emit UnstakedFromModel(_instanceId, _msgSender(), stake.amount);
    }

    // --- V. Utility & Administrative ---

    /**
     * @notice Emergency function to pause critical contract operations (owner-only).
     *         Inherited from OpenZeppelin's Pausable.
     */
    function pauseContract() public onlyOwner {
        _pause();
    }

    /**
     * @notice Function to resume critical contract operations (owner-only).
     *         Inherited from OpenZeppelin's Pausable.
     */
    function unpauseContract() public onlyOwner {
        _unpause();
    }

    /**
     * @notice Allows the contract owner to withdraw accumulated protocol fees or other excess ETH.
     * @param _recipient The address to send the funds to.
     * @param _amount The amount of ETH to withdraw.
     */
    function withdrawFunds(address _recipient, uint256 _amount) public onlyOwner nonReentrant {
        require(_recipient != address(0), "AetherForge: Invalid recipient address");
        require(address(this).balance >= _amount, "AetherForge: Insufficient contract balance");

        payable(_recipient).transfer(_amount);

        emit FundsWithdrawn(_recipient, _amount);
    }

    // --- Public View Functions ---

    /**
     * @notice Public view function to retrieve all stored details of an AI model template.
     * @param _templateId The ID of the template.
     * @return A `AIModelTemplate` struct containing all details.
     */
    function getAIModelTemplateDetails(uint256 _templateId) public view returns (AIModelTemplate memory) {
        return aiModelTemplates[_templateId];
    }

    /**
     * @notice Public view function to retrieve all stored details of a trained AI model instance.
     * @param _instanceId The ID of the trained model instance.
     * @return A `TrainedAIModelInstance` struct containing all details.
     */
    function getTrainedAIModelInstanceDetails(uint256 _instanceId) public view returns (TrainedAIModelInstance memory) {
        return trainedAIModelInstances[_instanceId];
    }

    /**
     * @notice Public view function to check the total aggregated pending rewards for a specific contributor.
     * @param _contributor The address of the contributor.
     * @return The total amount of ETH pending for the contributor.
     */
    function getPendingContributorRewards(address _contributor) public view returns (uint256) {
        return pendingContributorRewards[_contributor];
    }

    // --- Fallback and Receive functions ---
    // These functions allow the contract to receive plain ETH transfers.
    // However, it's generally recommended for users to interact via specific functions
    // (e.g., `recordModelUsagePayment`, `stakeForModelGuarantee`) to ensure correct logic.
    receive() external payable {
        // Log direct ETH transfers or revert if not explicitly allowed for general purpose.
        // For this contract, specific functions handle ETH, so direct receives might be unexpected.
        // Reverting here to encourage proper function calls for clarity.
        revert("AetherForge: Direct ETH transfers not allowed. Please use specific functions like recordModelUsagePayment or stakeForModelGuarantee.");
    }

    fallback() external payable {
        // Fallback should also revert unless a specific, implicit behavior is desired.
        revert("AetherForge: Fallback triggered. Please use specific functions.");
    }
}
```