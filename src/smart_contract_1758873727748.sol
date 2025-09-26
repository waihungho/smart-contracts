This smart contract, "Decentralized AI Protocol," aims to create a novel marketplace for AI models and a platform for executing verifiable AI tasks. It integrates advanced concepts like **AI Model NFTs**, **Verifiable Computation (conceptually via ZK-proof hashes)**, **Dynamic Pricing mechanisms**, **Reputation and Slashing for Compute Providers**, and **Lightweight On-Chain Governance**. The core idea is to foster trust and efficiency in decentralized AI.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Outline:
// I. Core Infrastructure & Security
// II. AI Model Management (ERC721-based NFTs)
// III. Compute Provider Management & Reputation
// IV. AI Task Execution & Verification
// V. Economic & Payment Mechanisms
// VI. Decentralized Governance (Lightweight)

// Function Summary:
// I. Core Infrastructure & Security
// 1. constructor(address initialOwner): Initializes the contract, sets the owner, and ERC721 properties.
// 2. pause(): Pauses contract operations in emergencies (Owner only).
// 3. unpause(): Resumes contract operations (Owner only).
// 4. setProtocolFee(uint256 _newFee): Sets the protocol fee percentage for task payments (Owner only).
// 5. setZKVerifierContract(address _zkVerifier): Sets the address of an external ZK-Proof verifier contract (Owner only).
// 6. withdrawProtocolFees(): Allows the owner to withdraw accumulated protocol fees.

// II. AI Model Management (ERC721-based NFTs)
// 7. registerAIModel(string calldata _metadataCID, bytes32 _inputSchemaHash, bytes32 _outputSchemaHash, bool _privateModel): Registers a new AI model as an ERC721 NFT, minting it to the caller.
// 8. updateAIModelMetadata(uint256 _modelId, string calldata _newMetadataCID): Updates the IPFS CID for a registered AI model's metadata (Model owner only).
// 9. deactivateAIModel(uint256 _modelId): Marks an AI model as inactive, preventing new tasks (Model owner only).
// 10. reactivateAIModel(uint256 _modelId): Reactivates a previously deactivated AI model (Model owner only).
// 11. listAIModelForSale(uint256 _modelId, uint256 _price): Lists an owned AI model NFT for sale at a specified price (Model owner only).
// 12. cancelModelListing(uint256 _modelId): Cancels the sale listing for an AI model NFT (Model owner only).
// 13. buyAIModelNFT(uint256 _modelId): Purchases a listed AI model NFT (Requires exact payment).
// 14. grantModelAccess(uint256 _modelId, address _user): Grants a specific user access to a private AI model (Model owner only).
// 15. revokeModelAccess(uint256 _modelId, address _user): Revokes access for a specific user from a private AI model (Model owner only).
// 16. getModelDetails(uint256 _modelId): Retrieves comprehensive details about a specific AI model.

// III. Compute Provider Management & Reputation
// 17. registerComputeProvider(string calldata _profileCID): Registers the caller as a compute provider with an initial stake.
// 18. updateComputeProviderProfile(string calldata _newProfileCID): Updates the IPFS CID for a provider's profile (Provider only).
// 19. stakeCollateral(): Allows a provider to add more collateral to their stake.
// 20. withdrawCollateral(uint256 _amount): Allows a provider to withdraw part of their stake after a cooldown period.
// 21. slashProvider(address _provider, uint256 _amount): Slashes a provider's stake due to malicious behavior or dispute loss (Owner/DAO only).
// 22. setProviderAvailability(bool _isAvailable): Toggles the provider's availability status for new tasks (Provider only).
// 23. getProviderDetails(address _provider): Retrieves comprehensive details about a specific compute provider.

// IV. AI Task Execution & Verification
// 24. requestAITask(uint256 _modelId, string calldata _inputCID, address _preferredProvider, uint256 _maxPayment, bool _requiresZKProof): Requests an AI task, depositing funds into escrow.
// 25. submitAITaskResult(uint256 _taskId, string calldata _resultCID, bytes32 _proofHash, uint256 _gasUsed): Compute provider submits the result and optional ZK-proof hash for a requested task.
// 26. verifyAITaskResult(uint256 _taskId): Marks a task as verified, either automatically (if no ZK proof) or conceptually awaiting off-chain ZK verification.
// 27. disputeAITaskResult(uint256 _taskId, string calldata _reason): Allows a user to dispute a submitted task result.
// 28. resolveDispute(uint256 _disputeId, bool _challengerWins, uint256 _slashAmount): Resolves a dispute, releasing funds or slashing provider (Owner/DAO only).

// V. Economic & Payment Mechanisms
// 29. setDynamicPricingParams(uint256 _basePrice, uint256 _reputationFactor, uint256 _demandFactor): Sets parameters for dynamic task pricing (Owner/DAO only).
// 30. fundTaskEscrow(uint256 _taskId): Allows a requester to add more funds to a task's escrow.
// 31. releaseTaskPayment(uint256 _taskId): Releases payment from escrow to the provider and protocol fees after successful verification (System triggered/Owner).

// VI. Decentralized Governance (Lightweight)
// 32. proposeParameterChange(string calldata _description, string calldata _paramName, uint256 _newValue, uint256 _votingDuration): Proposes a change to a configurable contract parameter.
// 33. voteOnProposal(uint256 _proposalId, bool _for): Allows registered compute providers to vote on an active proposal.
// 34. executeProposal(uint256 _proposalId): Executes an approved proposal after its voting period ends.

contract DecentralizedAIProtocol is Ownable, Pausable, ERC721Enumerable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- Enums ---
    enum AIModelStatus { Active, Deactivated, OnSale }
    enum TaskStatus { Requested, InProgress, ResultSubmitted, Verified, Disputed, Resolved, Failed }
    enum ComputeProviderStatus { Active, Inactive, Slashed }
    enum ProposalStatus { Pending, Approved, Rejected, Executed }

    // --- Structs ---

    struct AIModel {
        uint256 modelId;
        address owner;
        string metadataCID;          // IPFS CID pointing to model description, capabilities, etc.
        bytes32 inputSchemaHash;     // Hash of the expected input data schema
        bytes32 outputSchemaHash;    // Hash of the expected output data schema
        AIModelStatus status;
        uint256 price;               // Price if listed for sale (in WEI)
        mapping(address => bool) accessList; // For private models, who can request tasks
        bool isPrivate;
    }

    struct ComputeProvider {
        address providerAddress;
        string profileCID;           // IPFS CID for provider's profile (hardware, reputation, etc.)
        uint256 stake;               // Collateral staked by the provider
        int256 reputationScore;      // Higher score indicates better performance (can be negative)
        ComputeProviderStatus status;
        uint256 lastHeartbeat;       // Timestamp of last active check (conceptual)
        uint256 lastWithdrawalRequest; // Timestamp of last stake withdrawal request
        bool isAvailable;            // Indicates if the provider is accepting new tasks
    }

    struct AITask {
        uint256 taskId;
        uint256 modelId;
        address requester;
        address provider;            // The compute provider assigned/chosen
        string inputCID;             // IPFS CID of the input data
        string resultCID;            // IPFS CID of the computed result
        uint256 maxPayment;          // Max payment requester is willing to pay (in WEI)
        uint256 actualPayment;       // Actual payment for the task after verification
        uint256 escrowAmount;        // Funds held in escrow for this task
        uint256 submissionTime;      // Timestamp when result was submitted
        uint256 requestTime;         // Timestamp when task was requested
        TaskStatus status;
        bytes32 proofHash;           // Hash of the ZK-proof (if verificationRequired is true)
        bool verificationRequired;   // Whether this task requires ZK-proof verification
        uint256 disputeId;           // Reference to an active dispute for this task
    }

    struct Dispute {
        uint256 disputeId;
        uint256 taskId;
        address challenger;
        string reason;
        uint256 startTime;
        ProposalStatus status; // Reusing ProposalStatus for dispute resolution state
        bool challengerVote;   // For simplicity, just challenger's initial vote
    }

    struct Proposal {
        uint256 proposalId;
        address proposer;
        string description;
        string paramName;            // The name of the parameter to change (e.g., "protocolFee")
        uint256 newValue;            // The new value for the parameter
        uint256 startTime;
        uint256 endTime;
        uint256 forVotes;
        uint256 againstVotes;
        ProposalStatus status;
        mapping(address => bool) hasVoted; // Tracks if a provider has voted
    }

    // --- State Variables ---

    Counters.Counter private _modelIds;
    Counters.Counter private _taskIds;
    Counters.Counter private _disputeIds;
    Counters.Counter private _proposalIds;

    mapping(uint256 => AIModel) public aiModels;
    mapping(address => ComputeProvider) public computeProviders;
    mapping(uint256 => AITask) public aiTasks;
    mapping(uint256 => Dispute) public disputes;
    mapping(uint256 => Proposal) public proposals;

    uint256 public protocolFeePercent;       // Percentage of task payment taken as fee (e.g., 500 = 5%)
    address public zkVerifierContract;       // Address of an external ZK-Proof verifier contract (conceptual)
    uint256 public constant MIN_PROVIDER_STAKE = 1 ether; // Minimum stake required for a compute provider
    uint252 public constant STAKE_WITHDRAWAL_COOLDOWN = 7 days; // Cooldown period for stake withdrawals
    uint256 public constant DISPUTE_RESOLUTION_PERIOD = 3 days; // Time to resolve a dispute

    // Dynamic Pricing Parameters
    uint256 public dynamicPricing_basePrice;
    uint256 public dynamicPricing_reputationFactor; // Multiplier for reputation
    uint256 public dynamicPricing_demandFactor;     // Multiplier for demand (conceptual, based on active tasks)

    // Governance Parameters
    uint256 public proposalVotingPeriod; // Duration in seconds for proposals to be voted on
    uint256 public minVotesForProposal; // Minimum number of votes required for a proposal to be valid
    uint256 public minProviderReputationForVoting; // Minimum reputation score for a provider to vote

    uint256 public totalProtocolFees; // Accumulated fees

    // --- Events ---
    event AIModelRegistered(uint256 indexed modelId, address indexed owner, string metadataCID);
    event AIModelMetadataUpdated(uint256 indexed modelId, string newMetadataCID);
    event AIModelStatusChanged(uint256 indexed modelId, AIModelStatus newStatus);
    event AIModelListedForSale(uint256 indexed modelId, uint256 price);
    event AIModelListingCancelled(uint256 indexed modelId);
    event AIModelPurchased(uint256 indexed modelId, address indexed oldOwner, address indexed newOwner, uint256 price);
    event ModelAccessGranted(uint256 indexed modelId, address indexed user);
    event ModelAccessRevoked(uint256 indexed modelId, address indexed user);

    event ComputeProviderRegistered(address indexed providerAddress, uint256 stake);
    event ComputeProviderUpdated(address indexed providerAddress, string profileCID);
    event CollateralStaked(address indexed providerAddress, uint256 amount, uint256 newStake);
    event CollateralWithdrawn(address indexed providerAddress, uint256 amount, uint256 newStake);
    event ProviderSlashed(address indexed providerAddress, uint256 amount, string reason);
    event ProviderAvailabilityChanged(address indexed providerAddress, bool isAvailable);

    event AITaskRequested(uint256 indexed taskId, uint256 indexed modelId, address indexed requester, address preferredProvider, uint256 maxPayment);
    event AITaskResultSubmitted(uint256 indexed taskId, address indexed provider, string resultCID, bytes32 proofHash);
    event AITaskVerified(uint256 indexed taskId, address indexed provider, uint256 actualPayment);
    event AITaskDisputed(uint256 indexed taskId, uint256 indexed disputeId, address indexed challenger);
    event DisputeResolved(uint256 indexed disputeId, uint256 indexed taskId, bool challengerWins, uint256 slashAmount);

    event ProtocolFeeSet(uint256 newFee);
    event ZKVerifierContractSet(address indexed zkVerifier);
    event ProtocolFeesWithdrawn(address indexed recipient, uint224 amount);

    event DynamicPricingParamsSet(uint256 basePrice, uint256 reputationFactor, uint256 demandFactor);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool _for);
    event ProposalExecuted(uint256 indexed proposalId);

    // --- Modifiers ---
    modifier onlyModelOwner(uint256 _modelId) {
        require(aiModels[_modelId].owner == msg.sender, "Caller is not the model owner");
        _;
    }

    modifier onlyProvider() {
        require(computeProviders[msg.sender].status == ComputeProviderStatus.Active, "Caller is not an active compute provider");
        _;
    }

    modifier onlyIfModelAccess(uint256 _modelId, address _user) {
        AIModel storage model = aiModels[_modelId];
        require(model.status == AIModelStatus.Active, "Model is not active");
        require(
            !model.isPrivate || model.owner == _user || model.accessList[_user],
            "Access denied to private model"
        );
        _;
    }

    modifier onlyIfTaskProvider(uint256 _taskId) {
        require(aiTasks[_taskId].provider == msg.sender, "Caller is not the task provider");
        _;
    }

    modifier onlyIfTaskRequester(uint256 _taskId) {
        require(aiTasks[_taskId].requester == msg.sender, "Caller is not the task requester");
        _;
    }

    // --- Constructor ---
    constructor(address initialOwner)
        Ownable(initialOwner)
        ERC721("AIMarketplaceModels", "AIM")
    {
        _pause(); // Start paused, owner must unpause
        protocolFeePercent = 500; // 5%
        minVotesForProposal = 3; // Minimum 3 votes for a proposal to be considered
        proposalVotingPeriod = 3 days;
        minProviderReputationForVoting = 0; // Default, can be changed by governance
        dynamicPricing_basePrice = 100000000000000; // 0.0001 ETH
        dynamicPricing_reputationFactor = 100; // 100 = 1x base reputation effect
        dynamicPricing_demandFactor = 100;     // 100 = 1x base demand effect (conceptual)
    }

    // --- I. Core Infrastructure & Security ---

    // 1. (See constructor above)
    // 2. Pauses contract operations in emergencies (Owner only).
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    // 3. Resumes contract operations (Owner only).
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    // 4. Sets the protocol fee percentage for task payments (Owner only).
    function setProtocolFee(uint256 _newFee) public onlyOwner {
        require(_newFee <= 10000, "Fee cannot exceed 100%"); // 10000 = 100%
        protocolFeePercent = _newFee;
        emit ProtocolFeeSet(_newFee);
    }

    // 5. Sets the address of an external ZK-Proof verifier contract (Owner only).
    function setZKVerifierContract(address _zkVerifier) public onlyOwner {
        require(_zkVerifier != address(0), "ZK Verifier address cannot be zero");
        zkVerifierContract = _zkVerifier;
        emit ZKVerifierContractSet(_zkVerifier);
    }

    // 6. Allows the owner to withdraw accumulated protocol fees.
    function withdrawProtocolFees() public onlyOwner {
        uint256 amount = totalProtocolFees;
        require(amount > 0, "No fees to withdraw");
        totalProtocolFees = 0;
        payable(owner()).transfer(amount);
        emit ProtocolFeesWithdrawn(owner(), amount);
    }

    // --- II. AI Model Management (ERC721-based NFTs) ---

    // 7. Registers a new AI model as an ERC721 NFT, minting it to the caller.
    function registerAIModel(string calldata _metadataCID, bytes32 _inputSchemaHash, bytes32 _outputSchemaHash, bool _isPrivate)
        public
        whenNotPaused
        returns (uint256)
    {
        _modelIds.increment();
        uint256 newModelId = _modelIds.current();

        AIModel storage newModel = aiModels[newModelId];
        newModel.modelId = newModelId;
        newModel.owner = msg.sender;
        newModel.metadataCID = _metadataCID;
        newModel.inputSchemaHash = _inputSchemaHash;
        newModel.outputSchemaHash = _outputSchemaHash;
        newModel.status = AIModelStatus.Active;
        newModel.isPrivate = _isPrivate;

        _mint(msg.sender, newModelId); // Mint ERC721 token
        emit AIModelRegistered(newModelId, msg.sender, _metadataCID);
        return newModelId;
    }

    // 8. Updates the IPFS CID for a registered AI model's metadata (Model owner only).
    function updateAIModelMetadata(uint256 _modelId, string calldata _newMetadataCID)
        public
        whenNotPaused
        onlyModelOwner(_modelId)
    {
        aiModels[_modelId].metadataCID = _newMetadataCID;
        emit AIModelMetadataUpdated(_modelId, _newMetadataCID);
    }

    // 9. Marks an AI model as inactive, preventing new tasks (Model owner only).
    function deactivateAIModel(uint256 _modelId) public whenNotPaused onlyModelOwner(_modelId) {
        require(aiModels[_modelId].status != AIModelStatus.Deactivated, "Model already deactivated");
        aiModels[_modelId].status = AIModelStatus.Deactivated;
        emit AIModelStatusChanged(_modelId, AIModelStatus.Deactivated);
    }

    // 10. Reactivates a previously deactivated AI model (Model owner only).
    function reactivateAIModel(uint256 _modelId) public whenNotPaused onlyModelOwner(_modelId) {
        require(aiModels[_modelId].status == AIModelStatus.Deactivated, "Model is not deactivated");
        aiModels[_modelId].status = AIModelStatus.Active;
        emit AIModelStatusChanged(_modelId, AIModelStatus.Active);
    }

    // 11. Lists an owned AI model NFT for sale at a specified price (Model owner only).
    function listAIModelForSale(uint256 _modelId, uint256 _price) public whenNotPaused onlyModelOwner(_modelId) {
        require(_price > 0, "Price must be greater than zero");
        aiModels[_modelId].status = AIModelStatus.OnSale;
        aiModels[_modelId].price = _price;
        emit AIModelListedForSale(_modelId, _price);
    }

    // 12. Cancels the sale listing for an AI model NFT (Model owner only).
    function cancelModelListing(uint256 _modelId) public whenNotPaused onlyModelOwner(_modelId) {
        require(aiModels[_modelId].status == AIModelStatus.OnSale, "Model is not listed for sale");
        aiModels[_modelId].status = AIModelStatus.Active;
        aiModels[_modelId].price = 0;
        emit AIModelListingCancelled(_modelId);
    }

    // 13. Purchases a listed AI model NFT (Requires exact payment).
    function buyAIModelNFT(uint256 _modelId) public payable whenNotPaused nonReentrant {
        AIModel storage model = aiModels[_modelId];
        require(model.status == AIModelStatus.OnSale, "Model is not listed for sale");
        require(msg.value == model.price, "Incorrect payment amount");
        require(msg.sender != model.owner, "Cannot buy your own model");

        address oldOwner = model.owner;
        model.owner = msg.sender;
        model.status = AIModelStatus.Active;
        model.price = 0;

        _transfer(oldOwner, msg.sender, _modelId); // Transfer ERC721 token
        payable(oldOwner).transfer(msg.value); // Transfer payment to old owner

        emit AIModelPurchased(_modelId, oldOwner, msg.sender, msg.value);
    }

    // 14. Grants a specific user access to a private AI model (Model owner only).
    function grantModelAccess(uint256 _modelId, address _user) public whenNotPaused onlyModelOwner(_modelId) {
        require(aiModels[_modelId].isPrivate, "Model is not private");
        aiModels[_modelId].accessList[_user] = true;
        emit ModelAccessGranted(_modelId, _user);
    }

    // 15. Revokes access for a specific user from a private AI model (Model owner only).
    function revokeModelAccess(uint256 _modelId, address _user) public whenNotPaused onlyModelOwner(_modelId) {
        require(aiModels[_modelId].isPrivate, "Model is not private");
        aiModels[_modelId].accessList[_user] = false;
        emit ModelAccessRevoked(_modelId, _user);
    }

    // 16. Retrieves comprehensive details about a specific AI model.
    function getModelDetails(uint256 _modelId)
        public
        view
        returns (
            uint256 modelId,
            address owner,
            string memory metadataCID,
            bytes32 inputSchemaHash,
            bytes32 outputSchemaHash,
            AIModelStatus status,
            uint256 price,
            bool isPrivate
        )
    {
        AIModel storage model = aiModels[_modelId];
        return (
            model.modelId,
            model.owner,
            model.metadataCID,
            model.inputSchemaHash,
            model.outputSchemaHash,
            model.status,
            model.price,
            model.isPrivate
        );
    }

    // --- III. Compute Provider Management & Reputation ---

    // 17. Registers the caller as a compute provider with an initial stake.
    function registerComputeProvider(string calldata _profileCID) public payable whenNotPaused {
        require(msg.value >= MIN_PROVIDER_STAKE, "Insufficient initial stake");
        require(computeProviders[msg.sender].providerAddress == address(0), "Already a registered provider");

        ComputeProvider storage provider = computeProviders[msg.sender];
        provider.providerAddress = msg.sender;
        provider.profileCID = _profileCID;
        provider.stake = msg.value;
        provider.reputationScore = 100; // Initial reputation
        provider.status = ComputeProviderStatus.Active;
        provider.lastHeartbeat = block.timestamp;
        provider.isAvailable = true;

        emit ComputeProviderRegistered(msg.sender, msg.value);
    }

    // 18. Updates the IPFS CID for a provider's profile (Provider only).
    function updateComputeProviderProfile(string calldata _newProfileCID) public whenNotPaused onlyProvider {
        computeProviders[msg.sender].profileCID = _newProfileCID;
        emit ComputeProviderUpdated(msg.sender, _newProfileCID);
    }

    // 19. Allows a provider to add more collateral to their stake.
    function stakeCollateral() public payable whenNotPaused onlyProvider {
        require(msg.value > 0, "Amount to stake must be greater than zero");
        computeProviders[msg.sender].stake += msg.value;
        emit CollateralStaked(msg.sender, msg.value, computeProviders[msg.sender].stake);
    }

    // 20. Allows a provider to withdraw part of their stake after a cooldown period.
    function withdrawCollateral(uint256 _amount) public whenNotPaused onlyProvider nonReentrant {
        ComputeProvider storage provider = computeProviders[msg.sender];
        require(provider.stake - _amount >= MIN_PROVIDER_STAKE, "Withdrawal leaves stake below minimum");
        require(block.timestamp >= provider.lastWithdrawalRequest + STAKE_WITHDRAWAL_COOLDOWN, "Withdrawal cooldown in effect");
        // Additional checks: ensure no active tasks, no pending disputes

        provider.stake -= _amount;
        provider.lastWithdrawalRequest = block.timestamp;
        payable(msg.sender).transfer(_amount);
        emit CollateralWithdrawn(msg.sender, _amount, provider.stake);
    }

    // 21. Slashes a provider's stake due to malicious behavior or dispute loss (Owner/DAO only).
    function slashProvider(address _provider, uint256 _amount, string calldata _reason) public onlyOwner { // Can be extended to DAO
        ComputeProvider storage provider = computeProviders[_provider];
        require(provider.providerAddress != address(0), "Provider not registered");
        require(_amount > 0 && provider.stake >= _amount, "Invalid slash amount");

        provider.stake -= _amount;
        provider.reputationScore -= 10; // Penalty to reputation
        if (provider.stake < MIN_PROVIDER_STAKE) {
            provider.status = ComputeProviderStatus.Slashed; // Deactivate if stake too low
        }
        totalProtocolFees += _amount; // Slashed funds go to protocol fees
        emit ProviderSlashed(_provider, _amount, _reason);
    }

    // 22. Toggles the provider's availability status for new tasks (Provider only).
    function setProviderAvailability(bool _isAvailable) public whenNotPaused onlyProvider {
        computeProviders[msg.sender].isAvailable = _isAvailable;
        emit ProviderAvailabilityChanged(msg.sender, _isAvailable);
    }

    // 23. Retrieves comprehensive details about a specific compute provider.
    function getProviderDetails(address _provider)
        public
        view
        returns (
            address providerAddress,
            string memory profileCID,
            uint256 stake,
            int256 reputationScore,
            ComputeProviderStatus status,
            bool isAvailable
        )
    {
        ComputeProvider storage provider = computeProviders[_provider];
        return (
            provider.providerAddress,
            provider.profileCID,
            provider.stake,
            provider.reputationScore,
            provider.status,
            provider.isAvailable
        );
    }

    // --- IV. AI Task Execution & Verification ---

    // 24. Requests an AI task, depositing funds into escrow.
    function requestAITask(uint256 _modelId, string calldata _inputCID, address _preferredProvider, uint256 _maxPayment, bool _requiresZKProof)
        public
        payable
        whenNotPaused
        onlyIfModelAccess(_modelId, msg.sender)
        returns (uint256)
    {
        AIModel storage model = aiModels[_modelId];
        require(model.status == AIModelStatus.Active, "AI Model is not active");
        require(msg.value >= _maxPayment, "Insufficient funds for max payment");
        require(_maxPayment > 0, "Max payment must be greater than zero");
        if (_requiresZKProof) {
            require(zkVerifierContract != address(0), "ZK Verifier contract not set for ZK-proof tasks");
        }

        address chosenProvider = address(0);
        if (_preferredProvider != address(0)) {
            require(computeProviders[_preferredProvider].status == ComputeProviderStatus.Active, "Preferred provider is not active");
            require(computeProviders[_preferredProvider].isAvailable, "Preferred provider is not available");
            chosenProvider = _preferredProvider;
        } else {
            // Placeholder for a more advanced provider selection logic (e.g., matching algorithm, auction)
            // For now, it could be a random selection or simply allow _preferredProvider = address(0) for a "first come, first served"
            // Or leave it to providers to pick up tasks.
            // For this implementation, if no preferred provider, task is open for any provider to pick up.
        }

        _taskIds.increment();
        uint256 newTaskId = _taskIds.current();

        AITask storage newTask = aiTasks[newTaskId];
        newTask.taskId = newTaskId;
        newTask.modelId = _modelId;
        newTask.requester = msg.sender;
        newTask.provider = chosenProvider; // Can be address(0) if no preferred provider
        newTask.inputCID = _inputCID;
        newTask.maxPayment = _maxPayment;
        newTask.escrowAmount = msg.value; // Store the full sent amount
        newTask.requestTime = block.timestamp;
        newTask.status = TaskStatus.Requested;
        newTask.verificationRequired = _requiresZKProof;

        emit AITaskRequested(newTaskId, _modelId, msg.sender, chosenProvider, _maxPayment);
        return newTaskId;
    }

    // 25. Compute provider submits the result and optional ZK-proof hash for a requested task.
    function submitAITaskResult(uint256 _taskId, string calldata _resultCID, bytes32 _proofHash, uint256 _gasUsed)
        public
        whenNotPaused
        onlyProvider
        nonReentrant
    {
        AITask storage task = aiTasks[_taskId];
        require(task.status == TaskStatus.Requested, "Task not in Requested state");
        require(task.modelId != 0, "Task does not exist");
        if (task.provider != address(0)) { // If a specific provider was assigned
            require(task.provider == msg.sender, "Caller is not the assigned provider for this task");
        } else { // If task was open for any provider
            task.provider = msg.sender; // Assign provider to task
        }

        if (task.verificationRequired) {
            require(_proofHash != bytes32(0), "ZK-proof hash is required for this task");
        }

        task.resultCID = _resultCID;
        task.proofHash = _proofHash;
        task.submissionTime = block.timestamp;
        task.status = TaskStatus.ResultSubmitted;

        // Reputation adjustment based on gas used (conceptual, could be more complex)
        if (_gasUsed > 0) {
            computeProviders[msg.sender].reputationScore -= int256(_gasUsed / 100000000000000); // Small penalty for high gas
        }

        emit AITaskResultSubmitted(_taskId, msg.sender, _resultCID, _proofHash);
    }

    // 26. Marks a task as verified, either automatically (if no ZK proof) or conceptually awaiting off-chain ZK verification.
    function verifyAITaskResult(uint256 _taskId) public whenNotPaused {
        AITask storage task = aiTasks[_taskId];
        require(task.status == TaskStatus.ResultSubmitted, "Task not in ResultSubmitted state");
        require(task.requester == msg.sender || owner() == msg.sender, "Only requester or owner can verify");

        // If ZK-proof is required, this function implies an off-chain verification
        // has taken place and confirmed the proof. In a real system, this would
        // trigger a call to the ZKVerifierContract or rely on a specific oracle.
        // For simplicity, we assume external verification and state change.
        if (task.verificationRequired) {
             // Conceptual: In a real system, interact with zkVerifierContract here
             // For instance: `IZKVerifier(zkVerifierContract).verify(task.proofHash, ...)`
             // And then expect a callback or another function call to confirm.
             // For this contract, we're assuming the requester implicitly "verifies"
             // by calling this, implying they've seen the proof and are satisfied.
             // Or an admin/oracle could call this.
        }

        // Adjust provider reputation: good job!
        computeProviders[task.provider].reputationScore += 5; // Positive reputation boost

        task.status = TaskStatus.Verified;
        // Determine actual payment
        task.actualPayment = task.maxPayment; // For simplicity, full payment if verified

        // Release payment
        _releaseTaskPayment(task.taskId, task.provider, task.requester, task.actualPayment);

        emit AITaskVerified(_taskId, task.provider, task.actualPayment);
    }

    // 27. Allows a user to dispute a submitted task result.
    function disputeAITaskResult(uint256 _taskId, string calldata _reason) public whenNotPaused onlyIfTaskRequester(_taskId) {
        AITask storage task = aiTasks[_taskId];
        require(task.status == TaskStatus.ResultSubmitted, "Task not in ResultSubmitted state for dispute");
        require(task.disputeId == 0, "Task already has an active dispute");

        _disputeIds.increment();
        uint256 newDisputeId = _disputeIds.current();

        Dispute storage newDispute = disputes[newDisputeId];
        newDispute.disputeId = newDisputeId;
        newDispute.taskId = _taskId;
        newDispute.challenger = msg.sender;
        newDispute.reason = _reason;
        newDispute.startTime = block.timestamp;
        newDispute.status = ProposalStatus.Pending; // Pending resolution

        task.status = TaskStatus.Disputed;
        task.disputeId = newDisputeId;

        // Penalize provider reputation immediately for dispute
        computeProviders[task.provider].reputationScore -= 3;

        emit AITaskDisputed(_taskId, newDisputeId, msg.sender);
    }

    // 28. Resolves a dispute, releasing funds or slashing provider (Owner/DAO only).
    function resolveDispute(uint256 _disputeId, bool _challengerWins, uint256 _slashAmount) public onlyOwner { // Can be extended to DAO
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.status == ProposalStatus.Pending, "Dispute is not pending resolution");
        require(block.timestamp >= dispute.startTime + DISPUTE_RESOLUTION_PERIOD, "Dispute resolution period not over");

        AITask storage task = aiTasks[dispute.taskId];
        address provider = task.provider;

        dispute.status = ProposalStatus.Executed; // Dispute resolved

        if (_challengerWins) {
            // Requester wins, provider is penalized
            require(_slashAmount <= computeProviders[provider].stake, "Slash amount exceeds provider stake");
            _slashProvider(provider, _slashAmount, "Lost dispute for task result");
            task.status = TaskStatus.Failed;
            // Funds potentially returned to requester if no other resolution.
            // For simplicity, we assume maxPayment is returned to requester.
            payable(task.requester).transfer(task.escrowAmount);
            computeProviders[provider].reputationScore -= 7; // Further reputation loss
        } else {
            // Provider wins, requester's dispute was invalid
            _releaseTaskPayment(task.taskId, provider, task.requester, task.maxPayment); // Release full payment
            task.status = TaskStatus.Verified;
            computeProviders[provider].reputationScore += 3; // Reputation boost for successfully defending
        }
        task.disputeId = 0; // Clear dispute reference

        emit DisputeResolved(_disputeId, task.taskId, _challengerWins, _slashAmount);
    }

    // --- V. Economic & Payment Mechanisms ---

    // 29. Sets parameters for dynamic task pricing (Owner/DAO only).
    function setDynamicPricingParams(uint256 _basePrice, uint256 _reputationFactor, uint256 _demandFactor) public onlyOwner { // Can be extended to DAO
        dynamicPricing_basePrice = _basePrice;
        dynamicPricing_reputationFactor = _reputationFactor;
        dynamicPricing_demandFactor = _demandFactor;
        emit DynamicPricingParamsSet(_basePrice, _reputationFactor, _demandFactor);
    }

    // 30. Allows a requester to add more funds to a task's escrow.
    function fundTaskEscrow(uint256 _taskId) public payable whenNotPaused onlyIfTaskRequester(_taskId) {
        AITask storage task = aiTasks[_taskId];
        require(task.status < TaskStatus.Verified, "Task already completed or verified");
        require(msg.value > 0, "Amount to fund must be greater than zero");
        task.escrowAmount += msg.value;
    }

    // 31. Releases payment from escrow to the provider and protocol fees after successful verification (System triggered/Owner).
    function _releaseTaskPayment(uint256 _taskId, address _provider, address _requester, uint256 _amount) internal nonReentrant {
        AITask storage task = aiTasks[_taskId];
        require(task.escrowAmount >= _amount, "Escrow insufficient for payment"); // Should not happen if logic is correct

        uint256 protocolFee = (_amount * protocolFeePercent) / 10000; // e.g., 5% of 10000 = 500
        uint256 providerPayment = _amount - protocolFee;

        totalProtocolFees += protocolFee;
        task.escrowAmount -= _amount; // Deduct paid amount from escrow

        // Transfer to provider
        payable(_provider).transfer(providerPayment);

        // Refund any excess escrow back to requester
        if (task.escrowAmount > 0) {
            payable(_requester).transfer(task.escrowAmount);
            task.escrowAmount = 0;
        }
    }

    // 32. Allows remaining funds in escrow to be withdrawn by the requester if a task fails or is cancelled.
    function withdrawFunds(uint256 _taskId) public whenNotPaused onlyIfTaskRequester(_taskId) nonReentrant {
        AITask storage task = aiTasks[_taskId];
        require(task.status == TaskStatus.Failed || task.status == TaskStatus.Disputed, "Task must be failed or disputed to withdraw funds");
        require(task.escrowAmount > 0, "No funds in escrow to withdraw");

        uint256 amountToRefund = task.escrowAmount;
        task.escrowAmount = 0;
        payable(msg.sender).transfer(amountToRefund);
    }

    // --- VI. Decentralized Governance (Lightweight) ---

    // 33. Proposes a change to a configurable contract parameter.
    function proposeParameterChange(string calldata _description, string calldata _paramName, uint256 _newValue, uint256 _votingDuration)
        public
        whenNotPaused
        onlyProvider // Only registered providers can propose
    {
        require(computeProviders[msg.sender].reputationScore >= minProviderReputationForVoting, "Insufficient reputation to propose");
        require(_votingDuration > 0, "Voting duration must be greater than zero");

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        Proposal storage newProposal = proposals[newProposalId];
        newProposal.proposalId = newProposalId;
        newProposal.proposer = msg.sender;
        newProposal.description = _description;
        newProposal.paramName = _paramName;
        newProposal.newValue = _newValue;
        newProposal.startTime = block.timestamp;
        newProposal.endTime = block.timestamp + _votingDuration;
        newProposal.status = ProposalStatus.Pending;

        emit ProposalCreated(newProposalId, msg.sender, _description);
    }

    // 34. Allows registered compute providers to vote on an active proposal.
    function voteOnProposal(uint256 _proposalId, bool _for) public whenNotPaused onlyProvider {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "Proposal is not active for voting");
        require(block.timestamp <= proposal.endTime, "Voting period has ended");
        require(computeProviders[msg.sender].reputationScore >= minProviderReputationForVoting, "Insufficient reputation to vote");
        require(!proposal.hasVoted[msg.sender], "You have already voted on this proposal");

        if (_for) {
            proposal.forVotes++;
        } else {
            proposal.againstVotes++;
        }
        proposal.hasVoted[msg.sender] = true;

        emit ProposalVoted(_proposalId, msg.sender, _for);
    }

    // 35. Executes an approved proposal after its voting period ends.
    function executeProposal(uint256 _proposalId) public whenNotPaused onlyOwner { // Can be extended to DAO
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "Proposal is not pending");
        require(block.timestamp > proposal.endTime, "Voting period has not ended");
        require(proposal.forVotes + proposal.againstVotes >= minVotesForProposal, "Not enough votes cast for proposal to be valid");

        if (proposal.forVotes > proposal.againstVotes) {
            // Proposal Approved, execute the change
            if (keccak256(abi.encodePacked(proposal.paramName)) == keccak256(abi.encodePacked("protocolFee"))) {
                setProtocolFee(proposal.newValue);
            } else if (keccak256(abi.encodePacked(proposal.paramName)) == keccak256(abi.encodePacked("minVotesForProposal"))) {
                minVotesForProposal = proposal.newValue;
            } else if (keccak256(abi.encodePacked(proposal.paramName)) == keccak256(abi.encodePacked("proposalVotingPeriod"))) {
                proposalVotingPeriod = proposal.newValue;
            } else if (keccak256(abi.encodePacked(proposal.paramName)) == keccak256(abi.encodePacked("minProviderReputationForVoting"))) {
                minProviderReputationForVoting = int256(proposal.newValue); // Cast as int256
            } else if (keccak256(abi.encodePacked(proposal.paramName)) == keccak256(abi.encodePacked("basePrice"))) {
                dynamicPricing_basePrice = proposal.newValue;
            } else if (keccak256(abi.encodePacked(proposal.paramName)) == keccak256(abi.encodePacked("reputationFactor"))) {
                dynamicPricing_reputationFactor = proposal.newValue;
            } else if (keccak256(abi.encodePacked(proposal.paramName)) == keccak256(abi.encodePacked("demandFactor"))) {
                dynamicPricing_demandFactor = proposal.newValue;
            } else {
                revert("Unknown parameter for proposal execution");
            }
            proposal.status = ProposalStatus.Executed;
        } else {
            proposal.status = ProposalStatus.Rejected;
        }
        emit ProposalExecuted(_proposalId);
    }

    // --- Internal/Private Helpers (for better modularity) ---
    // (example of a private helper, already in slashProvider)
    function _slashProvider(address _provider, uint256 _amount, string calldata _reason) internal {
        ComputeProvider storage provider = computeProviders[_provider];
        provider.stake -= _amount;
        provider.reputationScore -= 10;
        if (provider.stake < MIN_PROVIDER_STAKE) {
            provider.status = ComputeProviderStatus.Slashed;
        }
        totalProtocolFees += _amount;
        emit ProviderSlashed(_provider, _amount, _reason);
    }
}
```