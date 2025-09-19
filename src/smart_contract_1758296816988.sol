This smart contract, `SynapseForge`, is designed to be a Decentralized Autonomous Organization (DAO) that facilitates the discovery, funding, curation, and access to decentralized AI models and their associated training data sets. It incorporates several advanced and trendy concepts: Dynamic NFTs (dNFTs) for AI models, a stake-based curation and validation system, a simplified quadratic funding mechanism for model grants, a reputation system, NFT-gated access control, and a full governance module for decentralized decision-making and dispute resolution.

---

**Outline:**

*   **I. Core Structures & Enums:** Definitions for AI models, datasets, proposals, disputes, and various states/outcomes.
*   **II. Token & NFT Management:** Integration with a custom ERC20 AIDAO token, `AIModelNFT` (a dNFT representing AI models), and `AccessGrantNFT` (for timed access to models).
*   **III. AI Model & Dataset Registry:** Functions for creators and providers to submit their AI models and datasets for review.
*   **IV. Curation & Validation System:** Mechanisms for curators to stake AIDAO, validate submitted assets, claim rewards for successful validations, and be penalized (slashed) for malicious actions.
*   **V. Funding & Grants:** A system for users to contribute to AI model funding pools, and a simplified quadratic matching logic for the DAO to add matching funds.
*   **VI. Access Control & Subscriptions:** Users can purchase `AccessGrantNFTs` to gain timed access to specific approved AI models.
*   **VII. Reputation System:** Tracks the credibility and contribution quality of model creators and curators.
*   **VIII. Governance Module:** Allows users to create proposals, vote using their AIDAO tokens, and execute approved actions, enabling decentralized control over the protocol.
*   **IX. Dispute Resolution:** A mechanism to formally dispute models, datasets, or validation outcomes, involving AIDAO staking and governance resolution.
*   **X. Utility & Configuration:** Functions for the DAO to manage its treasury and adjust protocol parameters.
*   **XI. Event Definitions:** Comprehensive event logging for all major state changes.

---

**Function Summary:**

1.  `registerAIDAOToken(address _token)`: Sets the address of the AIDAO ERC20 token used for staking, rewards, and governance. (Admin-only initially, then governance)
2.  `submitAIModel(string memory _ipfsHash, string memory _name, string memory _description, uint256 _estimatedCost, uint256[] memory _requiredDatasetIds)`: Allows an AI model creator to register a new AI model for community review and funding.
3.  `submitDataset(string memory _ipfsHash, string memory _name, string memory _description, uint256 _pricePerUse)`: Allows a data provider to register a new dataset.
4.  `stakeForCuration(uint256 _amount)`: Enables users to stake AIDAO tokens to qualify as active curators/validators.
5.  `unstakeForCuration(uint256 _amount)`: Allows a curator to unstake their AIDAO tokens after a cooldown period.
6.  `submitModelValidation(uint256 _modelId, ValidationOutcome _outcome, string memory _reviewHash)`: Curators submit their review and validation outcome (Approve/Reject) for an AI model.
7.  `submitDatasetValidation(uint256 _datasetId, ValidationOutcome _outcome, string memory _reviewHash)`: Curators submit their review and validation outcome for a dataset.
8.  `claimCurationReward(uint256[] memory _modelIds, uint256[] memory _datasetIds)`: Allows successful curators to claim their earned AIDAO rewards for positive validations.
9.  `slashCurator(address _curator, uint256 _amount, uint256 _proposalId)`: Enables governance to penalize a malicious or negligent curator by slashing their staked tokens. (Callable only via governance execution)
10. `contributeToModelFunding(uint256 _modelId, uint256 _amount)`: Users contribute AIDAO to a specific model's funding pool, which can trigger quadratic matching calculations.
11. `distributeModelFunding(uint256 _modelId)`: Distributes collected user funds and DAO matching funds (based on a simplified quadratic logic) to the creator of a successfully funded and validated model. Also triggers the minting of an `AIModelNFT`.
12. `mintAIModelNFT(address _to, uint256 _modelId, string memory _tokenURI)`: Mints a Dynamic NFT representing a *validated and funded* AI model to its creator. (Internal/Governance-controlled)
13. `updateAIModelNFTMetadata(uint256 _tokenId, string memory _newTokenURI)`: Updates the metadata URI of an existing `AIModelNFT`, allowing for dynamic changes reflecting performance, updates, or reviews.
14. `purchaseAccessGrant(uint256 _modelId, uint256 _durationInDays)`: Users can purchase an `AccessGrantNFT` for a specific model for a defined duration, granting them access.
15. `isAccessGrantValid(uint256 _grantNFTId)`: Checks if a given `AccessGrantNFT` is still within its active duration. (Public View)
16. `getCreatorReputation(address _creator)`: Retrieves the accumulated reputation score for an AI model creator. (Public View)
17. `getCuratorReputation(address _curator)`: Retrieves the accumulated reputation score for a curator. (Public View)
18. `createProposal(string memory _description, address _target, bytes memory _calldata, uint256 _value)`: Allows eligible users (with sufficient stake) to submit a governance proposal for actions like parameter changes or treasury withdrawals.
19. `voteOnProposal(uint256 _proposalId, bool _support)`: Users vote on an active proposal using their AIDAO tokens (staked or liquid balance contributes to voting power).
20. `executeProposal(uint256 _proposalId)`: Executes a proposal that has successfully passed the voting phase and met quorum requirements.
21. `initiateDispute(uint256 _entityId, DisputeType _type, string memory _reasonHash, uint256 _stakeAmount)`: Initiates a formal dispute against a model, dataset, or validation outcome, requiring a stake from the initiator.
22. `resolveDispute(uint256 _disputeId, DisputeOutcome _outcome)`: Governance votes to resolve an ongoing dispute, determining outcomes such as stake distribution or penalties. (Callable only via governance execution)
23. `getAIModelDetails(uint256 _modelId)`: Returns comprehensive details about a registered AI model. (Public View)
24. `getDatasetDetails(uint256 _datasetId)`: Returns comprehensive details about a registered dataset. (Public View)
25. `getProposalDetails(uint256 _proposalId)`: Returns details about a specific governance proposal. (Public View)
26. `setGovernanceParameters(uint256 _minVotingPeriod, uint256 _minQuorumPercentage, uint256 _stakeForProposal)`: Sets key governance parameters like voting period, quorum percentage, and proposal stake. (Callable only via governance execution)
27. `setCurationParameters(uint256 _minStake, uint256 _validationReward, uint256 _slashPenalty)`: Sets parameters for the curation system, including minimum stake, rewards, and penalties. (Callable only via governance execution)
28. `withdrawDAOFunds(address _to, uint256 _amount)`: Allows the DAO to transfer AIDAO tokens from its treasury to another address. (Callable only via governance execution)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit clarity, though 0.8.0+ handles basic overflows.

/**
 * @title SynapseForge
 * @dev A Decentralized Autonomous Organization (DAO) for Curated AI Models & Data Sets.
 *      This contract enables the submission, curation, funding, and access management
 *      of AI models and datasets through a set of interconnected advanced mechanisms.
 *      It integrates dynamic NFTs, stake-based validation, simplified quadratic funding,
 *      a reputation system, and on-chain governance.
 */
contract SynapseForge is Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // --- I. Core Structures & Enums ---

    enum EntityStatus { Pending, Approved, Rejected, Disputed }
    enum ValidationOutcome { Approve, Reject }
    enum ProposalState { Pending, Active, Canceled, Defeated, Succeeded, Executed }
    enum DisputeType { Model, Dataset, Validation }
    enum DisputeOutcome { Undecided, CreatorWin, ChallengerWin, SplitStake }

    struct AIModel {
        uint256 id;
        address creator;
        string ipfsHash; // IPFS hash for model code/details
        string name;
        string description;
        uint256 estimatedCost; // Estimated cost in AIDAO tokens for development/maintenance
        uint256[] requiredDatasetIds; // IDs of datasets this model relies on
        EntityStatus status;
        uint256 approvalCount;
        uint256 rejectionCount;
        uint256 totalFundingReceived;
        uint256 aiModelNFTId; // 0 if NFT not minted yet. Model ID is also the NFT ID.
        uint256 submittedAt;
    }

    struct Dataset {
        uint256 id;
        address provider;
        string ipfsHash; // IPFS hash for dataset content/metadata
        string name;
        string description;
        uint256 pricePerUse; // Price in AIDAO tokens for using this dataset
        EntityStatus status;
        uint256 approvalCount;
        uint256 rejectionCount;
        uint256 submittedAt;
    }

    struct CuratorStake {
        uint256 amount;
        uint256 stakedAt;
        uint256 cooldownEndsAt; // Timestamp when unstaking cooldown period ends
    }

    struct Proposal {
        uint256 id;
        string description;
        address proposer;
        address target; // Target contract for execution
        bytes calldataPayload; // Calldata for execution
        uint256 value; // ETH value to send with execution
        uint256 voteStart;
        uint256 voteEnd;
        uint256 ForVotes;
        uint256 AgainstVotes;
        ProposalState state;
        mapping(address => bool) hasVoted; // Tracks if an address has voted
    }

    struct Dispute {
        uint256 id;
        DisputeType disputeType;
        uint256 entityId; // ID of the model, dataset, or validation being disputed
        address initiator;
        uint256 initiatorStake; // AIDAO stake for initiating the dispute
        string reasonHash; // IPFS hash of detailed reason/evidence
        uint256 createdAt;
        DisputeOutcome outcome;
    }

    // --- II. Token & NFT Management (AIDAO Token, AIModelNFT, AccessGrantNFT) ---

    // IERC20 interface for the native AIDAO token
    IERC20 public AIDAOToken;

    // Custom ERC721 contract for AI Model NFTs (Dynamic NFTs)
    AIModelNFT public aiModelNFT;

    // Custom ERC721 contract for Access Grant NFTs
    AccessGrantNFT public accessGrantNFT;

    // --- III. AI Model & Dataset Registry ---
    Counters.Counter private _modelIdCounter;
    Counters.Counter private _datasetIdCounter;
    mapping(uint256 => AIModel) public models;
    mapping(uint256 => Dataset) public datasets;

    // --- IV. Curation & Validation System ---
    mapping(address => CuratorStake) public curatorStakes;
    mapping(uint256 => mapping(address => bool)) public modelValidatedBy; // modelId => curatorAddress => hasValidated
    mapping(uint256 => mapping(address => bool)) public datasetValidatedBy; // datasetId => curatorAddress => hasValidated
    uint256 public minCuratorStake = 1000 * 10**18; // 1000 AIDAO (example)
    uint256 public validationReward = 50 * 10**18; // 50 AIDAO (example)
    uint256 public slashPenalty = 200 * 10**18; // 200 AIDAO (example)
    uint256 public unstakeCooldownPeriod = 7 days; // 7 days cooldown for unstaking

    // --- V. Funding & Grants (Quadratic Funding Logic) ---
    // modelId => contributor => amount contributed
    mapping(uint256 => mapping(address => uint256)) public modelContributions;
    mapping(uint256 => uint256) public modelFundingTotalDirect; // Total direct contributions to a model
    mapping(uint256 => uint256) public modelFundingTotalQuadraticMatched; // Total DAO matching funds for a model

    // --- VII. Reputation System ---
    mapping(address => uint256) public creatorReputation; // Boosted by successful models, reduced by disputes
    mapping(address => uint256) public curatorReputation; // Boosted by successful validations, reduced by slashing

    // --- VIII. Governance Module ---
    Counters.Counter private _proposalIdCounter;
    mapping(uint256 => Proposal) public proposals;
    uint256 public minVotingPeriod = 3 days; // Minimum duration for voting on a proposal
    uint256 public minQuorumPercentage = 5; // 5% of total AIDAO supply needed for a proposal to pass
    uint256 public stakeForProposal = 500 * 10**18; // 500 AIDAO required to create a proposal

    // --- IX. Dispute Resolution ---
    Counters.Counter private _disputeIdCounter;
    mapping(uint256 => Dispute) public disputes;

    // --- X. Utility & Configuration ---
    address public DAO_TREASURY_ADDRESS; // This contract itself acts as the treasury for AIDAO tokens

    // --- XI. Events ---
    event AIDAOTokenRegistered(address indexed tokenAddress);
    event AIModelSubmitted(uint256 indexed modelId, address indexed creator, string ipfsHash);
    event DatasetSubmitted(uint256 indexed datasetId, address indexed provider, string ipfsHash);
    event CuratorStaked(address indexed curator, uint256 amount, uint256 totalStake);
    event CuratorUnstaked(address indexed curator, uint256 amount, uint256 remainingStake);
    event ModelValidated(uint256 indexed modelId, address indexed curator, ValidationOutcome outcome);
    event DatasetValidated(uint256 indexed datasetId, address indexed curator, ValidationOutcome outcome);
    event CurationRewardClaimed(address indexed curator, uint256 amount);
    event CuratorSlashed(address indexed curator, uint256 amount, uint256 proposalId);
    event ModelContribution(uint256 indexed modelId, address indexed contributor, uint256 amount);
    event ModelFundingDistributed(uint224 indexed modelId, address indexed creator, uint256 totalFunding);
    event AIModelNFTMinted(uint256 indexed modelId, address indexed to, uint256 nftId);
    event AIModelNFTMetadataUpdated(uint256 indexed nftId, string newURI);
    event AccessGrantPurchased(uint256 indexed modelId, address indexed buyer, uint256 grantNFTId, uint256 duration);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event DisputeInitiated(uint256 indexed disputeId, address indexed initiator, DisputeType dType, uint256 entityId);
    event DisputeResolved(uint256 indexed disputeId, DisputeOutcome outcome);
    event GovernanceParametersUpdated(uint256 minVotingPeriod, uint256 minQuorumPercentage, uint256 stakeForProposal);
    event CurationParametersUpdated(uint256 minStake, uint256 validationReward, uint256 slashPenalty);

    // --- Modifiers ---

    modifier onlyCurator() {
        require(curatorStakes[msg.sender].amount >= minCuratorStake, "SynapseForge: Not an active curator or insufficient stake");
        _;
    }

    modifier onlyIfAIDAOTokenRegistered() {
        require(address(AIDAOToken) != address(0), "SynapseForge: AIDAO Token not registered");
        _;
    }

    // --- Constructor ---

    constructor() Ownable(msg.sender) {
        // Initialize nested NFT contracts. Ownership will be transferred to SynapseForge itself.
        aiModelNFT = new AIModelNFT("SynapseForge AI Model NFT", "SF-AIM");
        accessGrantNFT = new AccessGrantNFT("SynapseForge Access Grant NFT", "SF-AG");
        DAO_TREASURY_ADDRESS = address(this); // The contract itself serves as the DAO treasury
    }

    // --- II. Token & NFT Management (Detailed) ---

    /**
     * @notice Registers the ERC20 AIDAO token address.
     * @dev Callable only once by the initial owner. Transfers ownership of NFT contracts to SynapseForge.
     * @param _token The address of the AIDAO ERC20 token.
     */
    function registerAIDAOToken(address _token) external onlyOwner {
        require(address(AIDAOToken) == address(0), "AIDAO Token already registered");
        AIDAOToken = IERC20(_token);
        // Transfer ownership of the NFT contracts to this SynapseForge contract
        // so it can manage minting and updates via governance actions.
        aiModelNFT.transferOwnership(address(this));
        accessGrantNFT.transferOwnership(address(this));
        emit AIDAOTokenRegistered(_token);
    }

    /**
     * @notice Mints a new Dynamic NFT representing a *validated and funded* AI model.
     * @dev This function is intended to be called internally (e.g., after model funding distribution)
     *      or via governance action. It transfers ownership of the NFT to the model creator.
     * @param _to The recipient of the NFT (usually the model creator).
     * @param _modelId The ID of the AI model.
     * @param _tokenURI The initial URI for the NFT metadata, typically an IPFS hash.
     */
    function mintAIModelNFT(address _to, uint256 _modelId, string memory _tokenURI) public onlyIfAIDAOTokenRegistered {
        require(_to != address(0), "AIModelNFT: mint to the zero address");
        require(models[_modelId].creator != address(0), "AIModelNFT: Invalid model ID");
        require(models[_modelId].aiModelNFTId == 0, "AIModelNFT: NFT already minted for this model");
        // Ensure this function is called by the SynapseForge contract itself (e.g., from distributeModelFunding)
        // or via a governance proposal targeting this function.
        require(msg.sender == address(this), "AIModelNFT: Only SynapseForge contract can directly mint AIModelNFTs");

        uint256 newNFTId = _modelId; // Using model ID as NFT ID for direct mapping
        aiModelNFT.mint(_to, newNFTId, _tokenURI);
        models[_modelId].aiModelNFTId = newNFTId;
        emit AIModelNFTMinted(_modelId, _to, newNFTId);
    }

    /**
     * @notice Updates the metadata URI of an existing AI Model NFT.
     * @dev This can be used to reflect performance updates, new versions, or community reviews.
     *      Can be called by the current NFT owner or by the SynapseForge contract (via governance).
     * @param _tokenId The ID of the AI Model NFT.
     * @param _newTokenURI The new URI for the NFT metadata.
     */
    function updateAIModelNFTMetadata(uint256 _tokenId, string memory _newTokenURI) public onlyIfAIDAOTokenRegistered {
        require(aiModelNFT.exists(_tokenId), "AIModelNFT: NFT does not exist");
        // Allow NFT owner to update their own NFT's metadata, or the SynapseForge contract (governance)
        require(aiModelNFT.ownerOf(_tokenId) == msg.sender || msg.sender == address(this),
                "SynapseForge: Not authorized to update this NFT's metadata");
        
        aiModelNFT.updateTokenURI(_tokenId, _newTokenURI);
        emit AIModelNFTMetadataUpdated(_tokenId, _newTokenURI);
    }

    /**
     * @notice Allows a user to purchase an `AccessGrantNFT` for a specific model for a defined duration.
     * @dev The price for access is currently calculated based on the model's `estimatedCost` per day.
     * @param _modelId The ID of the AI model to gain access to.
     * @param _durationInDays The duration of access in days.
     * @return The tokenId of the minted AccessGrantNFT.
     */
    function purchaseAccessGrant(uint256 _modelId, uint256 _durationInDays) public onlyIfAIDAOTokenRegistered returns (uint256) {
        AIModel storage model = models[_modelId];
        require(model.creator != address(0), "SynapseForge: Invalid model ID");
        require(model.status == EntityStatus.Approved, "SynapseForge: Model not yet approved for access");
        require(_durationInDays > 0, "SynapseForge: Duration must be positive");

        // Example pricing: estimatedCost / 30 days * actual days, ensuring a minimum cost
        uint256 costPerDay = model.estimatedCost.div(30).add(1); // Min 1 AIDAO per day if estimatedCost is low
        uint256 accessCost = costPerDay.mul(_durationInDays);
        require(accessCost > 0, "SynapseForge: Access cost too low or invalid duration");

        require(AIDAOToken.transferFrom(msg.sender, DAO_TREASURY_ADDRESS, accessCost), "SynapseForge: AIDAO transfer failed for access grant. Check approval.");

        uint256 grantNFTId = accessGrantNFT.mint(msg.sender, _modelId, _durationInDays);
        emit AccessGrantPurchased(_modelId, msg.sender, grantNFTId, _durationInDays);
        return grantNFTId;
    }

    /**
     * @notice Checks if a given AccessGrantNFT is still within its active duration.
     * @param _grantNFTId The tokenId of the AccessGrantNFT.
     * @return True if the grant is valid, false otherwise.
     */
    function isAccessGrantValid(uint256 _grantNFTId) public view returns (bool) {
        return accessGrantNFT.isValid(_grantNFTId);
    }

    // --- III. AI Model & Dataset Registry ---

    /**
     * @notice Allows a creator to register a new AI model for review.
     * @param _ipfsHash IPFS hash pointing to the model's description/code.
     * @param _name Name of the model.
     * @param _description Description of the model.
     * @param _estimatedCost Estimated cost in AIDAO for development/maintenance.
     * @param _requiredDatasetIds IDs of datasets required for this model (if any).
     */
    function submitAIModel(
        string memory _ipfsHash,
        string memory _name,
        string memory _description,
        uint256 _estimatedCost,
        uint256[] memory _requiredDatasetIds
    ) public {
        _modelIdCounter.increment();
        uint256 newModelId = _modelIdCounter.current();
        models[newModelId] = AIModel({
            id: newModelId,
            creator: msg.sender,
            ipfsHash: _ipfsHash,
            name: _name,
            description: _description,
            estimatedCost: _estimatedCost,
            requiredDatasetIds: _requiredDatasetIds,
            status: EntityStatus.Pending,
            approvalCount: 0,
            rejectionCount: 0,
            totalFundingReceived: 0,
            aiModelNFTId: 0,
            submittedAt: block.timestamp
        });
        emit AIModelSubmitted(newModelId, msg.sender, _ipfsHash);
    }

    /**
     * @notice Allows a provider to register a new dataset.
     * @param _ipfsHash IPFS hash pointing to the dataset.
     * @param _name Name of the dataset.
     * @param _description Description of the dataset.
     * @param _pricePerUse Price per use of the dataset in AIDAO.
     */
    function submitDataset(
        string memory _ipfsHash,
        string memory _name,
        string memory _description,
        uint256 _pricePerUse
    ) public {
        _datasetIdCounter.increment();
        uint256 newDatasetId = _datasetIdCounter.current();
        datasets[newDatasetId] = Dataset({
            id: newDatasetId,
            provider: msg.sender,
            ipfsHash: _ipfsHash,
            name: _name,
            description: _description,
            pricePerUse: _pricePerUse,
            status: EntityStatus.Pending,
            approvalCount: 0,
            rejectionCount: 0,
            submittedAt: block.timestamp
        });
        emit DatasetSubmitted(newDatasetId, msg.sender, _ipfsHash);
    }

    /**
     * @notice Retrieves comprehensive details about a registered AI model.
     * @param _modelId The ID of the AI model.
     * @return A tuple containing model details.
     */
    function getAIModelDetails(uint256 _modelId) public view returns (
        uint256 id, address creator, string memory ipfsHash, string memory name,
        string memory description, uint256 estimatedCost, uint256[] memory requiredDatasetIds,
        EntityStatus status, uint256 approvalCount, uint256 rejectionCount,
        uint256 totalFundingReceived, uint256 aiModelNFTId, uint256 submittedAt
    ) {
        AIModel storage model = models[_modelId];
        return (
            model.id, model.creator, model.ipfsHash, model.name, model.description,
            model.estimatedCost, model.requiredDatasetIds, model.status,
            model.approvalCount, model.rejectionCount, model.totalFundingReceived,
            model.aiModelNFTId, model.submittedAt
        );
    }

    /**
     * @notice Retrieves comprehensive details about a registered dataset.
     * @param _datasetId The ID of the dataset.
     * @return A tuple containing dataset details.
     */
    function getDatasetDetails(uint256 _datasetId) public view returns (
        uint256 id, address provider, string memory ipfsHash, string memory name,
        string memory description, uint256 pricePerUse, EntityStatus status,
        uint256 approvalCount, uint256 rejectionCount, uint256 submittedAt
    ) {
        Dataset storage dataset = datasets[_datasetId];
        return (
            dataset.id, dataset.provider, dataset.ipfsHash, dataset.name,
            dataset.description, dataset.pricePerUse, dataset.status,
            dataset.approvalCount, dataset.rejectionCount, dataset.submittedAt
        );
    }

    // --- IV. Curation & Validation System ---

    /**
     * @notice Enables users to stake AIDAO tokens to become active curators/validators.
     * @param _amount The amount of AIDAO tokens to stake. Requires prior `approve` call on AIDAOToken.
     */
    function stakeForCuration(uint256 _amount) public onlyIfAIDAOTokenRegistered {
        require(_amount > 0, "SynapseForge: Stake amount must be positive");
        require(AIDAOToken.transferFrom(msg.sender, address(this), _amount), "SynapseForge: AIDAO transfer failed for stake. Check approval.");

        curatorStakes[msg.sender].amount = curatorStakes[msg.sender].amount.add(_amount);
        curatorStakes[msg.sender].stakedAt = block.timestamp; // Update last stake time
        curatorStakes[msg.sender].cooldownEndsAt = 0; // Reset cooldown on new stake or increase
        emit CuratorStaked(msg.sender, _amount, curatorStakes[msg.sender].amount);
    }

    /**
     * @notice Allows a curator to unstake their AIDAO tokens after a cooldown period.
     * @param _amount The amount of AIDAO tokens to unstake.
     */
    function unstakeForCuration(uint256 _amount) public onlyIfAIDAOTokenRegistered {
        CuratorStake storage stake = curatorStakes[msg.sender];
        require(_amount > 0, "SynapseForge: Unstake amount must be positive");
        require(stake.amount >= _amount, "SynapseForge: Insufficient staked amount");

        // Initiate cooldown if not already in one or previous one is over
        if (stake.cooldownEndsAt == 0 || block.timestamp > stake.cooldownEndsAt) {
            stake.cooldownEndsAt = block.timestamp.add(unstakeCooldownPeriod);
        }
        require(block.timestamp >= stake.cooldownEndsAt, "SynapseForge: Unstaking cooldown period not over");

        stake.amount = stake.amount.sub(_amount);
        require(AIDAOToken.transfer(msg.sender, _amount), "SynapseForge: AIDAO transfer failed for unstake");

        // If remaining stake falls below minCuratorStake, they are no longer an active curator for new tasks
        if (stake.amount < minCuratorStake) {
            stake.cooldownEndsAt = 0; // Clear cooldown if no longer a curator
        }

        emit CuratorUnstaked(msg.sender, _amount, stake.amount);
    }

    /**
     * @notice Curators submit their review and validation outcome for an AI model.
     * @param _modelId The ID of the AI model.
     * @param _outcome The validation outcome (Approve/Reject).
     * @param _reviewHash IPFS hash of the detailed review.
     */
    function submitModelValidation(uint256 _modelId, ValidationOutcome _outcome, string memory _reviewHash) public onlyCurator {
        AIModel storage model = models[_modelId];
        require(model.creator != address(0), "SynapseForge: Invalid model ID");
        require(model.status == EntityStatus.Pending, "SynapseForge: Model not in pending state");
        require(!modelValidatedBy[_modelId][msg.sender], "SynapseForge: Already validated this model");

        modelValidatedBy[_modelId][msg.sender] = true;
        if (_outcome == ValidationOutcome.Approve) {
            model.approvalCount = model.approvalCount.add(1);
            curatorReputation[msg.sender] = curatorReputation[msg.sender].add(10); // Boost reputation
        } else {
            model.rejectionCount = model.rejectionCount.add(1);
            curatorReputation[msg.sender] = curatorReputation[msg.sender].div(2); // Modest penalty for rejecting
        }

        // Simplified majority: If 3 approvals or rejections, update status
        if (model.approvalCount >= 3) {
            model.status = EntityStatus.Approved;
        } else if (model.rejectionCount >= 3) {
            model.status = EntityStatus.Rejected;
        }

        emit ModelValidated(_modelId, msg.sender, _outcome);
    }

    /**
     * @notice Curators submit their review and validation outcome for a dataset.
     * @param _datasetId The ID of the dataset.
     * @param _outcome The validation outcome (Approve/Reject).
     * @param _reviewHash IPFS hash of the detailed review.
     */
    function submitDatasetValidation(uint256 _datasetId, ValidationOutcome _outcome, string memory _reviewHash) public onlyCurator {
        Dataset storage dataset = datasets[_datasetId];
        require(dataset.provider != address(0), "SynapseForge: Invalid dataset ID");
        require(dataset.status == EntityStatus.Pending, "SynapseForge: Dataset not in pending state");
        require(!datasetValidatedBy[_datasetId][msg.sender], "SynapseForge: Already validated this dataset");

        datasetValidatedBy[_datasetId][msg.sender] = true;
        if (_outcome == ValidationOutcome.Approve) {
            dataset.approvalCount = dataset.approvalCount.add(1);
            curatorReputation[msg.sender] = curatorReputation[msg.sender].add(10); // Boost reputation
        } else {
            dataset.rejectionCount = dataset.rejectionCount.add(1);
            curatorReputation[msg.sender] = curatorReputation[msg.sender].div(2); // Modest penalty
        }

        if (dataset.approvalCount >= 3) {
            dataset.status = EntityStatus.Approved;
        } else if (dataset.rejectionCount >= 3) {
            dataset.status = EntityStatus.Rejected;
        }
        emit DatasetValidated(_datasetId, msg.sender, _outcome);
    }

    /**
     * @notice Allows successful curators to claim their earned AIDAO rewards.
     * @dev Curators get rewarded for contributing to a validation process that results in an Approved status.
     * @param _modelIds Array of model IDs for which to claim rewards.
     * @param _datasetIds Array of dataset IDs for which to claim rewards.
     */
    function claimCurationReward(uint256[] memory _modelIds, uint256[] memory _datasetIds) public onlyIfAIDAOTokenRegistered {
        uint256 totalReward = 0;
        for (uint256 i = 0; i < _modelIds.length; i++) {
            uint256 modelId = _modelIds[i];
            AIModel storage model = models[modelId];
            // Check if model is approved and curator approved it and hasn't claimed yet
            if (model.status == EntityStatus.Approved && modelValidatedBy[modelId][msg.sender]) {
                modelValidatedBy[modelId][msg.sender] = false; // Mark as claimed
                totalReward = totalReward.add(validationReward);
            }
        }
        for (uint256 i = 0; i < _datasetIds.length; i++) {
            uint256 datasetId = _datasetIds[i];
            Dataset storage dataset = datasets[datasetId];
            // Check if dataset is approved and curator approved it and hasn't claimed yet
            if (dataset.status == EntityStatus.Approved && datasetValidatedBy[datasetId][msg.sender]) {
                datasetValidatedBy[datasetId][msg.sender] = false; // Mark as claimed
                totalReward = totalReward.add(validationReward);
            }
        }
        require(totalReward > 0, "SynapseForge: No rewards to claim for these validations");
        require(AIDAOToken.transfer(msg.sender, totalReward), "SynapseForge: Failed to transfer reward");
        emit CurationRewardClaimed(msg.sender, totalReward);
    }

    /**
     * @notice Enables governance to penalize a malicious or negligent curator by slashing their staked tokens.
     * @dev This function is intended to be called via governance execution, not directly.
     * @param _curator The address of the curator to slash.
     * @param _amount The amount of AIDAO tokens to slash.
     * @param _proposalId The governance proposal ID that authorized this slashing.
     */
    function slashCurator(address _curator, uint256 _amount, uint256 _proposalId) public {
        require(msg.sender == address(this), "SynapseForge: Only governance can call slashCurator directly"); // Must be called via governance execution
        CuratorStake storage stake = curatorStakes[_curator];
        require(stake.amount >= _amount, "SynapseForge: Insufficient stake to slash");
        stake.amount = stake.amount.sub(_amount);
        curatorReputation[_curator] = curatorReputation[_curator].div(2); // Halve reputation
        // Slashed funds remain in DAO treasury (address(this))
        emit CuratorSlashed(_curator, _amount, _proposalId);
    }

    // --- V. Funding & Grants (Quadratic Funding Logic) ---

    /**
     * @notice Users contribute AIDAO to a specific model's funding pool.
     * @dev Requires prior `approve` call on AIDAOToken.
     * @param _modelId The ID of the AI model.
     * @param _amount The amount of AIDAO tokens to contribute.
     */
    function contributeToModelFunding(uint256 _modelId, uint256 _amount) public onlyIfAIDAOTokenRegistered {
        AIModel storage model = models[_modelId];
        require(model.creator != address(0), "SynapseForge: Invalid model ID");
        require(model.status == EntityStatus.Approved, "SynapseForge: Model not yet approved for funding");
        require(_amount > 0, "SynapseForge: Contribution amount must be positive");
        require(AIDAOToken.transferFrom(msg.sender, DAO_TREASURY_ADDRESS, _amount), "SynapseForge: AIDAO transfer failed for contribution. Check approval.");

        modelContributions[_modelId][msg.sender] = modelContributions[_modelId][msg.sender].add(_amount);
        modelFundingTotalDirect[_modelId] = modelFundingTotalDirect[_modelId].add(_amount);
        emit ModelContribution(_modelId, msg.sender, _amount);
    }

    /**
     * @notice Distributes collected user funds and DAO matching funds to the creator of a successfully funded and validated model.
     * @dev This function implements a simplified quadratic funding matching logic. It is called once per model.
     *      True quadratic funding (sum of sqrt of contributions squared) is challenging to implement gas-efficiently
     *      on-chain for an arbitrary number of contributors. This implementation approximates by providing a base
     *      match and a bonus proportional to direct contributions if certain conditions (like strong approval) are met.
     * @param _modelId The ID of the AI model to distribute funding for.
     */
    function distributeModelFunding(uint256 _modelId) public onlyIfAIDAOTokenRegistered {
        AIModel storage model = models[_modelId];
        require(model.creator != address(0), "SynapseForge: Invalid model ID");
        require(model.status == EntityStatus.Approved, "SynapseForge: Model not approved for funding distribution");
        require(model.totalFundingReceived == 0, "SynapseForge: Funding already distributed for this model");
        require(modelFundingTotalDirect[_modelId] > 0, "SynapseForge: No direct contributions to distribute");

        uint256 totalDirectContributions = modelFundingTotalDirect[_modelId];
        uint256 DAO_matching_fund = 0;

        // Simplified QF-like matching:
        // If the model has strong community approval (e.g., high approval count), provide matching.
        if (model.approvalCount >= 5) { // Arbitrary threshold for strong community signal
            // Base matching: e.g., 20% of direct contributions
            DAO_matching_fund = DAO_matching_fund.add(totalDirectContributions.div(5));

            // Dynamic bonus for "quadratic effect" based on relative funding goal.
            // If direct contributions meet or exceed estimated cost, provide a further match.
            uint256 requiredForFullFunding = model.estimatedCost;
            if (totalDirectContributions >= requiredForFullFunding) {
                DAO_matching_fund = DAO_matching_fund.add(totalDirectContributions.div(4)); // Add 25% bonus
            } else {
                DAO_matching_fund = DAO_matching_fund.add(totalDirectContributions.div(10)); // Smaller 10% bonus
            }
        }
        
        // Ensure DAO treasury has enough AIDAO for the matching funds
        require(AIDAOToken.balanceOf(address(this)) >= DAO_matching_fund, "SynapseForge: Insufficient DAO treasury for matching funds");

        uint256 totalFundsToDistribute = totalDirectContributions.add(DAO_matching_fund);
        modelFundingTotalQuadraticMatched[_modelId] = DAO_matching_fund;
        model.totalFundingReceived = totalFundsToDistribute;

        // Transfer funds to the model creator
        creatorReputation[model.creator] = creatorReputation[model.creator].add(totalFundsToDistribute.div(10**18).div(100)); // Reputation boost based on funding (simplified)
        require(AIDAOToken.transfer(model.creator, totalFundsToDistribute), "SynapseForge: Failed to transfer model funding");

        // Mint AIModelNFT for the creator after successful funding and distribution
        // The tokenURI could initially point to model details + funding status
        string memory initialNFTURI = string(abi.encodePacked("ipfs://", model.ipfsHash, "/funded_v1_", Strings.toString(block.timestamp)));
        mintAIModelNFT(model.creator, _modelId, initialNFTURI);

        emit ModelFundingDistributed(_modelId, model.creator, totalFundsToDistribute);
    }

    // --- VII. Reputation System ---

    /**
     * @notice Retrieves the accumulated reputation score for an AI model creator.
     * @param _creator The address of the creator.
     * @return The reputation score.
     */
    function getCreatorReputation(address _creator) public view returns (uint256) {
        return creatorReputation[_creator];
    }

    /**
     * @notice Retrieves the accumulated reputation score for a curator.
     * @param _curator The address of the curator.
     * @return The reputation score.
     */
    function getCuratorReputation(address _curator) public view returns (uint256) {
        return curatorReputation[_curator];
    }

    // --- VIII. Governance Module ---

    /**
     * @notice Creates a new governance proposal.
     * @dev Requires a minimum AIDAO stake or balance from the proposer.
     * @param _description A detailed description of the proposal.
     * @param _target The target contract address for the proposal's action.
     * @param _calldataPayload The encoded calldata to be executed on the target contract.
     * @param _value The ETH value (if any) to be sent with the execution.
     */
    function createProposal(
        string memory _description,
        address _target,
        bytes memory _calldataPayload,
        uint256 _value
    ) public onlyIfAIDAOTokenRegistered {
        require(AIDAOToken.balanceOf(msg.sender).add(curatorStakes[msg.sender].amount) >= stakeForProposal,
                "SynapseForge: Insufficient AIDAO balance or stake to create proposal");

        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            description: _description,
            proposer: msg.sender,
            target: _target,
            calldataPayload: _calldataPayload,
            value: _value,
            voteStart: block.timestamp,
            voteEnd: block.timestamp.add(minVotingPeriod),
            ForVotes: 0,
            AgainstVotes: 0,
            state: ProposalState.Active
        });

        emit ProposalCreated(newProposalId, msg.sender, _description);
    }

    /**
     * @notice Allows users to vote on an active proposal.
     * @param _proposalId The ID of the proposal.
     * @param _support True for "for" vote, false for "against" vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public onlyIfAIDAOTokenRegistered {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "SynapseForge: Invalid proposal ID");
        require(proposal.state == ProposalState.Active, "SynapseForge: Proposal not in active state");
        require(block.timestamp >= proposal.voteStart && block.timestamp <= proposal.voteEnd, "SynapseForge: Voting period not active");
        require(!proposal.hasVoted[msg.sender], "SynapseForge: Already voted on this proposal");

        uint256 votingPower = AIDAOToken.balanceOf(msg.sender).add(curatorStakes[msg.sender].amount);
        require(votingPower > 0, "SynapseForge: No voting power based on AIDAO holdings or stake");

        proposal.hasVoted[msg.sender] = true;

        if (_support) {
            proposal.ForVotes = proposal.ForVotes.add(votingPower);
        } else {
            proposal.AgainstVotes = proposal.AgainstVotes.add(votingPower);
        }
        emit VoteCast(_proposalId, msg.sender, _support, votingPower);
    }

    /**
     * @dev Internal function to update the state of a proposal based on voting outcome and time.
     * @param _proposalId The ID of the proposal.
     */
    function _updateProposalState(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.state != ProposalState.Active) return; // Only update active proposals

        if (block.timestamp <= proposal.voteEnd) {
            return; // Voting period still active
        }

        uint256 totalVotes = proposal.ForVotes.add(proposal.AgainstVotes);
        uint256 totalAIDAOsupply = AIDAOToken.totalSupply();
        uint256 requiredQuorum = totalAIDAOsupply.mul(minQuorumPercentage).div(100);

        if (totalVotes < requiredQuorum) {
            proposal.state = ProposalState.Defeated;
            emit ProposalStateChanged(_proposalId, ProposalState.Defeated);
            return;
        }

        if (proposal.ForVotes > proposal.AgainstVotes) {
            proposal.state = ProposalState.Succeeded;
            emit ProposalStateChanged(_proposalId, ProposalState.Succeeded);
        } else {
            proposal.state = ProposalState.Defeated;
            emit ProposalStateChanged(_proposalId, ProposalState.Defeated);
        }
    }

    /**
     * @notice Executes a proposal that has passed the voting phase and quorum requirements.
     * @param _proposalId The ID of the proposal.
     */
    function executeProposal(uint256 _proposalId) public {
        _updateProposalState(_proposalId); // Ensure state is up-to-date before execution
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "SynapseForge: Invalid proposal ID");
        require(proposal.state == ProposalState.Succeeded, "SynapseForge: Proposal not succeeded or already executed");
        require(proposal.target != address(0), "SynapseForge: Target address cannot be zero");

        proposal.state = ProposalState.Executed;
        // Execute the call to the target contract
        (bool success, ) = proposal.target.call{value: proposal.value}(proposal.calldataPayload);
        require(success, "SynapseForge: Proposal execution failed");

        emit ProposalStateChanged(_proposalId, ProposalState.Executed);
    }

    /**
     * @notice Returns details about a specific governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return A tuple containing proposal details.
     */
    function getProposalDetails(uint256 _proposalId) public view returns (
        uint256 id, string memory description, address proposer, address target,
        bytes memory calldataPayload, uint256 value, uint256 voteStart,
        uint256 voteEnd, uint256 ForVotes, uint256 AgainstVotes, ProposalState state
    ) {
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.id, proposal.description, proposal.proposer, proposal.target,
            proposal.calldataPayload, proposal.value, proposal.voteStart,
            proposal.voteEnd, proposal.ForVotes, proposal.AgainstVotes, proposal.state
        );
    }

    // --- IX. Dispute Resolution ---

    /**
     * @notice Initiates a formal dispute against a model, dataset, or validation.
     * @dev Requires a stake from the initiator. Requires prior `approve` call on AIDAOToken.
     * @param _entityId The ID of the entity (model or dataset).
     * @param _type The type of dispute (Model, Dataset, Validation).
     * @param _reasonHash IPFS hash of the detailed reason and evidence for the dispute.
     * @param _stakeAmount The amount of AIDAO to stake for initiating the dispute.
     */
    function initiateDispute(uint256 _entityId, DisputeType _type, string memory _reasonHash, uint256 _stakeAmount) public onlyIfAIDAOTokenRegistered {
        require(_stakeAmount > 0, "SynapseForge: Dispute stake must be positive");
        require(AIDAOToken.transferFrom(msg.sender, DAO_TREASURY_ADDRESS, _stakeAmount), "SynapseForge: AIDAO transfer failed for dispute stake. Check approval.");

        _disputeIdCounter.increment();
        uint256 newDisputeId = _disputeIdCounter.current();

        disputes[newDisputeId] = Dispute({
            id: newDisputeId,
            disputeType: _type,
            entityId: _entityId,
            initiator: msg.sender,
            initiatorStake: _stakeAmount,
            reasonHash: _reasonHash,
            createdAt: block.timestamp,
            outcome: DisputeOutcome.Undecided
        });

        // Mark the entity as disputed to prevent further actions until resolution
        if (_type == DisputeType.Model) {
            models[_entityId].status = EntityStatus.Disputed;
        } else if (_type == DisputeType.Dataset) {
            datasets[_entityId].status = EntityStatus.Disputed;
        }

        emit DisputeInitiated(newDisputeId, msg.sender, _type, _entityId);
    }

    /**
     * @notice Governance votes to resolve an ongoing dispute.
     * @dev This function is intended to be called via governance execution, not directly.
     * @param _disputeId The ID of the dispute to resolve.
     * @param _outcome The resolution outcome (e.g., CreatorWin, ChallengerWin, SplitStake).
     */
    function resolveDispute(uint256 _disputeId, DisputeOutcome _outcome) public {
        require(msg.sender == address(this), "SynapseForge: Only governance can call resolveDispute directly"); // Must be called via governance execution
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.initiator != address(0), "SynapseForge: Invalid dispute ID");
        require(dispute.outcome == DisputeOutcome.Undecided, "SynapseForge: Dispute already resolved");
        require(_outcome != DisputeOutcome.Undecided, "SynapseForge: Outcome cannot be undecided");

        dispute.outcome = _outcome;

        if (_outcome == DisputeOutcome.CreatorWin) { // If the original entity creator/validator is vindicated
            require(AIDAOToken.transfer(dispute.initiator, dispute.initiatorStake), "SynapseForge: Failed to return dispute stake");
            // Revert entity status from Disputed to Approved/Pending if applicable
            if (dispute.disputeType == DisputeType.Model) models[dispute.entityId].status = EntityStatus.Approved;
            if (dispute.disputeType == DisputeType.Dataset) datasets[dispute.entityId].status = EntityStatus.Approved;
            // Optionally, penalize the initiator if they lost and were malicious (not implemented explicitly here).
        } else if (_outcome == DisputeOutcome.ChallengerWin) { // If the initiator (challenger) wins
            // Return initiator's stake + a bonus (e.g., 50%)
            require(AIDAOToken.transfer(dispute.initiator, dispute.initiatorStake.add(dispute.initiatorStake.div(2))), "SynapseForge: Failed to reward dispute challenger");
            // Penalize the original entity creator/provider/curator
            if (dispute.disputeType == DisputeType.Model) creatorReputation[models[dispute.entityId].creator] = creatorReputation[models[dispute.entityId].creator].div(2);
            if (dispute.disputeType == DisputeType.Dataset) creatorReputation[datasets[dispute.entityId].provider] = creatorReputation[datasets[dispute.entityId].provider].div(2);
            // If it was a validation dispute, this would require logic to identify and slash the specific curator.
            // For simplicity, we apply general reputation penalties.
        } else if (_outcome == DisputeOutcome.SplitStake) {
            // Initiator's stake remains in DAO treasury (effectively burned from their perspective)
            // No direct rewards or penalties, status of entity remains disputed or is set to Pending again.
            if (dispute.disputeType == DisputeType.Model) models[dispute.entityId].status = EntityStatus.Pending;
            if (dispute.disputeType == DisputeType.Dataset) datasets[dispute.entityId].status = EntityStatus.Pending;
        }

        emit DisputeResolved(_disputeId, _outcome);
    }

    // --- X. Utility & Configuration ---

    /**
     * @notice Sets key governance parameters.
     * @dev Callable only via governance execution.
     * @param _minVotingPeriod Minimum duration for voting on a proposal in seconds.
     * @param _minQuorumPercentage Minimum percentage of total AIDAO supply needed for a proposal to pass.
     * @param _stakeForProposal Amount of AIDAO required to create a proposal.
     */
    function setGovernanceParameters(
        uint256 _minVotingPeriod,
        uint256 _minQuorumPercentage,
        uint256 _stakeForProposal
    ) public {
        require(msg.sender == address(this), "SynapseForge: Only governance can call setGovernanceParameters directly");
        minVotingPeriod = _minVotingPeriod;
        minQuorumPercentage = _minQuorumPercentage;
        stakeForProposal = _stakeForProposal;
        emit GovernanceParametersUpdated(_minVotingPeriod, _minQuorumPercentage, _stakeForProposal);
    }

    /**
     * @notice Sets parameters for the curation system.
     * @dev Callable only via governance execution.
     * @param _minStake Minimum AIDAO tokens required to be an active curator.
     * @param _validationReward AIDAO reward for a successful validation.
     * @param _slashPenalty AIDAO penalty for a malicious/incorrect validation.
     */
    function setCurationParameters(
        uint256 _minStake,
        uint256 _validationReward,
        uint256 _slashPenalty
    ) public {
        require(msg.sender == address(this), "SynapseForge: Only governance can call setCurationParameters directly");
        minCuratorStake = _minStake;
        validationReward = _validationReward;
        slashPenalty = _slashPenalty;
        emit CurationParametersUpdated(_minStake, _validationReward, _slashPenalty);
    }

    /**
     * @notice Allows the DAO to transfer AIDAO funds from its treasury.
     * @dev Callable only via governance execution.
     * @param _to The recipient address.
     * @param _amount The amount of AIDAO tokens to transfer.
     */
    function withdrawDAOFunds(address _to, uint256 _amount) public onlyIfAIDAOTokenRegistered {
        require(msg.sender == address(this), "SynapseForge: Only governance can call withdrawDAOFunds directly");
        require(AIDAOToken.transfer(_to, _amount), "SynapseForge: Failed to withdraw DAO funds");
    }

    // --- Internal NFT Contracts (Nested for self-contained example) ---

    /**
     * @title AIModelNFT
     * @dev An ERC721 contract for representing AI Models as dynamic NFTs.
     *      Metadata can be updated to reflect model performance, versions, or community reviews.
     */
    contract AIModelNFT is ERC721, Ownable {
        constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {}

        /**
         * @dev Mints a new AI Model NFT. Callable only by the owner of this contract (SynapseForge).
         * @param to The address to mint the NFT to.
         * @param tokenId The ID of the token.
         * @param tokenURI The initial metadata URI for the token.
         */
        function mint(address to, uint256 tokenId, string memory tokenURI) internal {
            _mint(to, tokenId);
            _setTokenURI(tokenId, tokenURI);
        }

        /**
         * @dev Updates the metadata URI of an existing AI Model NFT.
         *      Callable only by the owner of this contract (SynapseForge).
         *      The SynapseForge contract itself will implement logic to allow individual NFT owners
         *      or governance to trigger this.
         * @param tokenId The ID of the token to update.
         * @param newTokenURI The new metadata URI.
         */
        function updateTokenURI(uint256 tokenId, string memory newTokenURI) internal onlyOwner {
            require(_exists(tokenId), "AIModelNFT: token does not exist");
            _setTokenURI(tokenId, newTokenURI);
        }

        /**
         * @dev Checks if a token ID exists.
         * @param tokenId The ID of the token.
         * @return True if the token exists, false otherwise.
         */
        function exists(uint256 tokenId) internal view returns (bool) {
            return _exists(tokenId);
        }
    }

    /**
     * @title AccessGrantNFT
     * @dev An ERC721 contract for granting timed access to specific AI Models.
     *      Each NFT represents a unique access right.
     */
    contract AccessGrantNFT is ERC721, Ownable {
        using Counters for Counters.Counter;
        Counters.Counter private _tokenIdCounter;

        struct Grant {
            uint256 modelId;
            uint256 startTime;
            uint256 durationInDays;
        }

        mapping(uint256 => Grant) public grants; // tokenId => Grant details

        constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {}

        /**
         * @dev Mints a new Access Grant NFT. Callable only by the owner of this contract (SynapseForge).
         * @param to The address to mint the NFT to.
         * @param _modelId The ID of the AI model this grant is for.
         * @param _durationInDays The duration of access granted in days.
         * @return The tokenId of the newly minted AccessGrantNFT.
         */
        function mint(address to, uint256 _modelId, uint256 _durationInDays) internal returns (uint256) {
            _tokenIdCounter.increment();
            uint256 newTokenId = _tokenIdCounter.current();
            _mint(to, newTokenId);
            grants[newTokenId] = Grant({
                modelId: _modelId,
                startTime: block.timestamp,
                durationInDays: _durationInDays
            });
            // Optionally set tokenURI for the grant NFT, e.g., "ipfs://grant/modelId/duration"
            _setTokenURI(newTokenId, string(abi.encodePacked("ipfs://access-grant/", Strings.toString(_modelId), "/", Strings.toString(_durationInDays))));
            return newTokenId;
        }

        /**
         * @dev Checks if a given Access Grant NFT is still valid (within its active duration).
         * @param tokenId The ID of the AccessGrantNFT.
         * @return True if the grant is valid, false otherwise.
         */
        function isValid(uint256 tokenId) public view returns (bool) {
            Grant storage grant = grants[tokenId];
            if (grant.durationInDays == 0 || grant.modelId == 0) return false; // Invalid or non-existent grant
            return block.timestamp <= grant.startTime.add(grant.durationInDays.mul(1 days));
        }
    }
}
```