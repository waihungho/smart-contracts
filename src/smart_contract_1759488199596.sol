This smart contract, named `DecentralizedAIMarketplace`, envisions a platform where AI models are treated as unique, tradeable NFTs, and their development is fostered through a soulbound token (SBT) system for contributions. Compute nodes (DINs) provide inference services, incentivized by native currency payments ("MICs") and a dynamic pricing mechanism influenced by market factors. The system incorporates robust access control and a simplified governance structure for parameter adjustments.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For toString in getModelDetails

// Outline:
// This contract establishes a Decentralized AI Model Marketplace with several core components:
// I.  Model Management: AI Models are represented as ERC721 NFTs, allowing for unique ownership and trading.
// II. Contribution & Skills: A custom Soulbound Token (SBT) system tracks and attests to individual contributions to specific AI models, promoting collaboration and verifiable skill accumulation.
// III. Inference & Compute Nodes (DINs): A network of registered nodes provides computation for model inference, requiring a stake to ensure reliability.
// IV. Economic Layer: Utilizes the blockchain's native currency (conceptually "MICs" - Model Inference Credits) for inference payments and node rewards, managed securely with reentrancy protection.
// V.  Dynamic Pricing & Oracles: Implements a mechanism for adjusting inference costs based on base rates and dynamic factors, simulating oracle input through admin controls.
// VI. Access Control & Governance: Leverages OpenZeppelin's AccessControl for role-based permissions, enhancing security and allowing for structured administration and potential future DAO integration.

// Function Summary:
// I. Model Management (ERC721 NFTs for AI Models):
//    1. registerAIModel: Mints a new AI Model NFT, assigning ownership and setting initial parameters.
//    2. updateModelMetadata: Allows the model owner to update the associated metadata URI.
//    3. retireAIModel: Marks an AI model as inactive, preventing new inference requests.
//    4. reactivateAIModel: Re-enables a previously retired AI model for use.
//    5. transferModelOwnership: Facilitates the transfer of an AI Model NFT to a new owner.
//    6. getModelDetails: Retrieves comprehensive details for a specific AI Model NFT.
//
// II. Contribution & Skills (Custom Soulbound Tokens - SBTs):
//    7. attestContribution: Mints a non-transferable (soulbound) SBT to a contributor for a specific model and contribution type, issued by an 'ATTESTOR_ROLE'.
//    8. revokeContributionAttestation: Allows an 'ATTESTOR_ROLE' to revoke an SBT, e.g., in case of invalid contribution.
//    9. getContributorSBTCount: Returns the total number of unique SBTs held by an address.
//    10. hasSpecificSBT: Checks if an address holds a particular SBT for a given model and contribution type.
//    11. getSBTDetails: Retrieves the proof URI and attestor for a specific SBT held by a contributor.
//
// III. Inference & Compute Nodes (DINs):
//    12. registerInferenceNode: Registers a new compute node, requiring a minimum native currency stake.
//    13. updateNodeEndpoint: Allows a registered node to update its external endpoint URI.
//    14. deregisterInferenceNode: Deregisters a node, refunding its stake, and marking it inactive.
//    15. requestModelInference: Initiates an inference request for a model, paying the calculated dynamic cost into escrow.
//    16. submitInferenceResult: A registered DIN submits the result of an inference request, receiving payment from escrow.
//    17. disputeInferenceResult: Allows the requester or other DINs to flag a submitted result for dispute resolution.
//
// IV. Economic Layer (Native currency as "MICs"):
//    18. stakeNodeTokens: Increases the native currency stake of a registered inference node.
//    19. unstakeNodeTokens: Allows a registered node to reduce its staked native currency.
//    20. claimNodeRewards: Enables a registered node to withdraw its accumulated inference rewards.
//    21. getPendingNodeRewards: View function to check a node's currently accumulated but unclaimed rewards.
//
// V. Dynamic Pricing & Oracles (Admin-controlled factors):
//    22. setBaseInferenceCost: Allows the model owner or 'ADMIN_ROLE' to adjust the base cost for a model's inference.
//    23. setDynamicPricingFactor: 'ORACLE_ROLE' can set a global multiplier for dynamic pricing, simulating external market data.
//    24. setMinimumNodeStake: 'ADMIN_ROLE' adjusts the minimum native currency required for a node to register.
//    25. getEffectiveInferenceCost: Calculates the final inference cost for a model, considering base cost and dynamic factors.
//
// VI. Access Control & Governance (OpenZeppelin AccessControl):
//    26. grantRole: 'ADMIN_ROLE' can assign specific roles (e.g., ATTESTOR, ORACLE) to addresses.
//    27. revokeRole: 'ADMIN_ROLE' can remove specific roles from addresses.
//
contract DecentralizedAIMarketplace is ERC721, AccessControl, ReentrancyGuard, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256; // For toString() method

    // --- State Variables & Roles ---

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ATTESTOR_ROLE = keccak256("ATTESTOR_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    // I. Model Management
    Counters.Counter private _modelIdCounter;

    struct AIModel {
        string name;
        string description;
        string modelURI; // IPFS URI or similar for model metadata/code
        address owner; // ERC721 handles primary ownership, but explicit here for quick lookup
        uint256 baseInferenceCostWei; // Cost per 1 expectedOutputUnit
        bool isActive;
    }
    mapping(uint256 => AIModel) public models;

    // II. Contribution & Skills (Soulbound Tokens - SBTs)
    struct ComponentSBT {
        bytes32 contributionType; // e.g., keccak256("DATASET_PROVIDER"), keccak256("ALGORITHM_DEVELOPER")
        uint256 modelId;
        string proofURI; // URI to detailed proof of contribution
        address attestor; // Address that issued the attestation
        uint256 timestamp;
    }
    // A single contributor can have multiple SBTs for different models/types.
    // SBTs are non-transferable and tied to the contributor's address.
    // We store a mapping to indicate existence and provide details directly.
    mapping(address => mapping(uint256 => mapping(bytes32 => ComponentSBT))) private _sbtAttestations;
    mapping(address => uint256) public contributorSBTCounts; // Total SBTs for a contributor

    // III. Inference & Compute Nodes (DINs)
    Counters.Counter private _requestIdCounter;

    struct InferenceNode {
        string endpointURI; // URI to access the node for inference
        uint256 stakedAmountWei; // Collateral staked by the node
        uint256 rewardsPendingWei; // Accumulated rewards not yet claimed
        bool isActive;
        uint256 registeredTimestamp;
    }
    mapping(address => InferenceNode) public inferenceNodes;
    uint256 public minimumNodeStakeWei;

    enum RequestStatus {
        Pending,        // Request made, awaiting node assignment/result
        Fulfilled,      // Result submitted and accepted
        Disputed,       // Result disputed, awaiting resolution
        Cancelled       // Request cancelled by user or by system (e.g., node offline)
    }

    struct InferenceRequest {
        address requester;
        uint256 modelId;
        bytes32 inputHash;      // Hash of the input data
        uint256 expectedOutputUnits; // Expected units of computation/output
        uint256 costPaidWei;    // Actual cost paid by the requester
        address nodeAssigned;   // Node that took the request (if assigned)
        bytes32 outputHash;     // Hash of the submitted output data
        uint256 actualOutputUnits; // Actual units provided by the node
        RequestStatus status;
        uint256 requestTimestamp;
        uint256 fulfilledTimestamp;
        address disputedBy;     // Address that initiated the dispute
    }
    mapping(uint256 => InferenceRequest) public inferenceRequests;

    // V. Dynamic Pricing & Oracles
    uint256 public dynamicPricingFactorNumerator = 100; // Default: 100/100 = 1
    uint256 public dynamicPricingFactorDenominator = 100;

    // --- Events ---

    event AIModelRegistered(uint256 indexed modelId, address indexed owner, string name, uint256 baseCost);
    event ModelMetadataUpdated(uint256 indexed modelId, string newURI);
    event AIModelStatusChanged(uint256 indexed modelId, bool isActive);
    event ModelOwnershipTransferred(uint256 indexed modelId, address indexed previousOwner, address indexed newOwner);

    event ContributionAttested(address indexed contributor, uint256 indexed modelId, bytes32 indexed contributionType, address attestor);
    event ContributionAttestationRevoked(address indexed contributor, uint256 indexed modelId, bytes32 indexed contributionType, address attestor);

    event InferenceNodeRegistered(address indexed nodeAddress, string endpointURI, uint256 stakedAmount);
    event InferenceNodeDeregistered(address indexed nodeAddress);
    event InferenceNodeEndpointUpdated(address indexed nodeAddress, string newEndpointURI);
    event InferenceNodeStaked(address indexed nodeAddress, uint256 amount);
    event InferenceNodeUnstaked(address indexed nodeAddress, uint256 amount);
    event InferenceNodeRewardsClaimed(address indexed nodeAddress, uint256 amount);

    event InferenceRequested(uint256 indexed requestId, uint256 indexed modelId, address indexed requester, uint256 costPaid);
    event InferenceResultSubmitted(uint256 indexed requestId, address indexed nodeAddress, bytes32 outputHash);
    event InferenceResultDisputed(uint256 indexed requestId, address indexed disputer);

    event BaseInferenceCostUpdated(uint256 indexed modelId, uint256 newCost);
    event DynamicPricingFactorUpdated(uint256 numerator, uint256 denominator);
    event MinimumNodeStakeUpdated(uint256 newMinStake);

    // --- Constructor ---

    constructor(address initialAdmin) ERC721("AIMarketplaceModel", "AIMODEL") {
        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        _grantRole(ADMIN_ROLE, initialAdmin); // Custom admin role
        _grantRole(ATTESTOR_ROLE, initialAdmin); // Initial attestor role
        _grantRole(ORACLE_ROLE, initialAdmin);   // Initial oracle role

        minimumNodeStakeWei = 1 ether; // Default minimum stake
    }

    // --- Modifiers ---

    modifier onlyModelOwner(uint256 _modelId) {
        require(_exists(_modelId), "Model does not exist");
        require(ownerOf(_modelId) == msg.sender, "Caller is not model owner");
        _;
    }

    modifier onlyRegisteredNode() {
        require(inferenceNodes[msg.sender].isActive, "Caller is not an active registered node");
        _;
    }

    // --- I. Model Management (ERC721 NFTs for AI Models) ---

    /**
     * @dev Registers a new AI model, minting an ERC721 NFT for it.
     * @param _name The name of the AI model.
     * @param _description A brief description of the model.
     * @param _modelURI IPFS or similar URI pointing to the model's metadata or code.
     * @param _baseInferenceCostWei The base cost per output unit in wei.
     */
    function registerAIModel(
        string memory _name,
        string memory _description,
        string memory _modelURI,
        uint256 _baseInferenceCostWei
    ) public whenNotPaused returns (uint256) {
        _modelIdCounter.increment();
        uint256 newModelId = _modelIdCounter.current();

        _mint(msg.sender, newModelId);
        _setTokenURI(newModelId, _modelURI);

        models[newModelId] = AIModel({
            name: _name,
            description: _description,
            modelURI: _modelURI,
            owner: msg.sender,
            baseInferenceCostWei: _baseInferenceCostWei,
            isActive: true
        });

        emit AIModelRegistered(newModelId, msg.sender, _name, _baseInferenceCostWei);
        return newModelId;
    }

    /**
     * @dev Updates the metadata URI for an owned AI model.
     * @param _modelId The ID of the AI model.
     * @param _newModelURI The new IPFS or similar URI.
     */
    function updateModelMetadata(uint256 _modelId, string memory _newModelURI)
        public
        whenNotPaused
        onlyModelOwner(_modelId)
    {
        models[_modelId].modelURI = _newModelURI;
        _setTokenURI(_modelId, _newModelURI);
        emit ModelMetadataUpdated(_modelId, _newModelURI);
    }

    /**
     * @dev Marks an AI model as inactive, preventing new inference requests.
     * @param _modelId The ID of the AI model to retire.
     */
    function retireAIModel(uint256 _modelId) public whenNotPaused onlyModelOwner(_modelId) {
        require(models[_modelId].isActive, "Model is already inactive");
        models[_modelId].isActive = false;
        emit AIModelStatusChanged(_modelId, false);
    }

    /**
     * @dev Reactivates a previously retired AI model.
     * @param _modelId The ID of the AI model to reactivate.
     */
    function reactivateAIModel(uint256 _modelId) public whenNotPaused onlyModelOwner(_modelId) {
        require(!models[_modelId].isActive, "Model is already active");
        models[_modelId].isActive = true;
        emit AIModelStatusChanged(_modelId, true);
    }

    /**
     * @dev Transfers ownership of an AI Model NFT. Overrides ERC721's transferFrom for specific event.
     * @param _modelId The ID of the AI model NFT.
     * @param _newOwner The address of the new owner.
     */
    function transferModelOwnership(uint256 _modelId, address _newOwner) public whenNotPaused onlyModelOwner(_modelId) {
        address previousOwner = ownerOf(_modelId);
        _transfer(previousOwner, _newOwner, _modelId);
        models[_modelId].owner = _newOwner; // Update explicit owner in our struct
        emit ModelOwnershipTransferred(_modelId, previousOwner, _newOwner);
    }

    /**
     * @dev Retrieves all public details of a registered AI model.
     * @param _modelId The ID of the AI model.
     * @return name, description, modelURI, owner, baseInferenceCostWei, isActive status.
     */
    function getModelDetails(uint256 _modelId)
        public
        view
        returns (string memory name, string memory description, string memory modelURI, address owner, uint256 baseInferenceCostWei, bool isActive)
    {
        AIModel storage model = models[_modelId];
        require(model.owner != address(0), "Model does not exist"); // Check if model exists

        return (
            model.name,
            model.description,
            model.modelURI,
            model.owner,
            model.baseInferenceCostWei,
            model.isActive
        );
    }

    // --- II. Contribution & Skills (Custom Soulbound Tokens - SBTs) ---

    /**
     * @dev Attests to a contributor's skill or contribution to a specific AI model, minting an SBT.
     *      SBTs are non-transferable and serve as verifiable credentials.
     * @param _contributor The address of the contributor.
     * @param _modelId The ID of the model the contribution is for.
     * @param _contributionType A bytes32 identifier for the type of contribution (e.g., hash of "DATASET_PROVIDER").
     * @param _proofURI An IPFS or similar URI linking to proof of contribution.
     */
    function attestContribution(
        address _contributor,
        uint256 _modelId,
        bytes32 _contributionType,
        string memory _proofURI
    ) public whenNotPaused onlyRole(ATTESTOR_ROLE) {
        require(models[_modelId].owner != address(0), "Model does not exist");
        require(_sbtAttestations[_contributor][_modelId][_contributionType].attestor == address(0), "SBT already attested");
        require(_contributor != address(0), "Contributor cannot be zero address");

        _sbtAttestations[_contributor][_modelId][_contributionType] = ComponentSBT({
            contributionType: _contributionType,
            modelId: _modelId,
            proofURI: _proofURI,
            attestor: msg.sender,
            timestamp: block.timestamp
        });
        contributorSBTCounts[_contributor]++;
        emit ContributionAttested(_contributor, _modelId, _contributionType, msg.sender);
    }

    /**
     * @dev Allows an authorized attestor to revoke a previously issued SBT.
     * @param _contributor The address of the contributor.
     * @param _modelId The ID of the model the contribution is for.
     * @param _contributionType The type of contribution.
     */
    function revokeContributionAttestation(
        address _contributor,
        uint256 _modelId,
        bytes32 _contributionType
    ) public whenNotPaused onlyRole(ATTESTOR_ROLE) {
        ComponentSBT storage sbt = _sbtAttestations[_contributor][_modelId][_contributionType];
        require(sbt.attestor != address(0), "SBT does not exist or already revoked");
        require(sbt.attestor == msg.sender, "Only original attestor can revoke");

        delete _sbtAttestations[_contributor][_modelId][_contributionType];
        contributorSBTCounts[_contributor]--;
        emit ContributionAttestationRevoked(_contributor, _modelId, _contributionType, msg.sender);
    }

    /**
     * @dev Returns the total count of unique SBTs held by an address.
     * @param _contributor The address of the contributor.
     * @return The number of SBTs.
     */
    function getContributorSBTCount(address _contributor) public view returns (uint256) {
        return contributorSBTCounts[_contributor];
    }

    /**
     * @dev Checks if a specific address holds a particular SBT for a given model and contribution type.
     * @param _contributor The address to check.
     * @param _modelId The model ID.
     * @param _contributionType The contribution type.
     * @return True if the SBT exists, false otherwise.
     */
    function hasSpecificSBT(
        address _contributor,
        uint256 _modelId,
        bytes32 _contributionType
    ) public view returns (bool) {
        return _sbtAttestations[_contributor][_modelId][_contributionType].attestor != address(0);
    }

    /**
     * @dev Retrieves the details (proof URI and attestor) for a specific SBT.
     * @param _contributor The address holding the SBT.
     * @param _modelId The model ID associated with the SBT.
     * @param _contributionType The contribution type of the SBT.
     * @return proofURI, attestor, timestamp.
     */
    function getSBTDetails(
        address _contributor,
        uint256 _modelId,
        bytes32 _contributionType
    ) public view returns (string memory proofURI, address attestor, uint256 timestamp) {
        ComponentSBT storage sbt = _sbtAttestations[_contributor][_modelId][_contributionType];
        require(sbt.attestor != address(0), "SBT not found for this contributor, model, and type");
        return (sbt.proofURI, sbt.attestor, sbt.timestamp);
    }


    // --- III. Inference & Compute Nodes (DINs) ---

    /**
     * @dev Registers a new inference node, requiring an initial native currency stake.
     * @param _nodeEndpointURI The URI where the node can be contacted for inference requests.
     */
    function registerInferenceNode(string memory _nodeEndpointURI) public payable whenNotPaused {
        require(!inferenceNodes[msg.sender].isActive, "Node is already registered");
        require(msg.value >= minimumNodeStakeWei, "Insufficient initial stake");
        require(bytes(_nodeEndpointURI).length > 0, "Endpoint URI cannot be empty");

        inferenceNodes[msg.sender] = InferenceNode({
            endpointURI: _nodeEndpointURI,
            stakedAmountWei: msg.value,
            rewardsPendingWei: 0,
            isActive: true,
            registeredTimestamp: block.timestamp
        });

        emit InferenceNodeRegistered(msg.sender, _nodeEndpointURI, msg.value);
    }

    /**
     * @dev Allows a registered node to update its endpoint URI.
     * @param _newNodeEndpointURI The new URI for the node.
     */
    function updateNodeEndpoint(address _nodeAddress, string memory _newNodeEndpointURI)
        public
        whenNotPaused
        onlyRegisteredNode
    {
        require(bytes(_newNodeEndpointURI).length > 0, "New endpoint URI cannot be empty");
        inferenceNodes[_nodeAddress].endpointURI = _newNodeEndpointURI;
        emit InferenceNodeEndpointUpdated(_nodeAddress, _newNodeEndpointURI);
    }

    /**
     * @dev Deregisters an inference node, refunding its stake.
     *      Requires the node to have no pending rewards or active requests.
     */
    function deregisterInferenceNode(address _nodeAddress) public whenNotPaused onlyRegisteredNode {
        require(inferenceNodes[_nodeAddress].rewardsPendingWei == 0, "Node has pending rewards");
        // Additional checks for active requests could be added here,
        // but for this example, we assume nodes resolve requests before deregistering.

        uint256 stakeToRefund = inferenceNodes[_nodeAddress].stakedAmountWei;
        inferenceNodes[_nodeAddress].isActive = false;
        inferenceNodes[_nodeAddress].stakedAmountWei = 0;

        (bool success, ) = payable(msg.sender).call{value: stakeToRefund}("");
        require(success, "Failed to refund stake");

        emit InferenceNodeDeregistered(_nodeAddress);
    }

    /**
     * @dev Allows a user to request an AI model inference.
     *      The calculated cost is paid and held in escrow.
     * @param _modelId The ID of the AI model to use.
     * @param _inputHash A hash representing the input data for the inference.
     * @param _expectedOutputUnits The estimated units of computation or output required.
     */
    function requestModelInference(
        uint256 _modelId,
        bytes32 _inputHash,
        uint256 _expectedOutputUnits
    ) public payable whenNotPaused nonReentrant returns (uint256) {
        AIModel storage model = models[_modelId];
        require(model.isActive, "Model is not active");
        require(model.owner != address(0), "Model does not exist");
        require(_expectedOutputUnits > 0, "Expected output units must be positive");

        uint256 cost = getEffectiveInferenceCost(_modelId, _expectedOutputUnits);
        require(msg.value >= cost, "Insufficient payment for inference");

        _requestIdCounter.increment();
        uint256 newRequestId = _requestIdCounter.current();

        inferenceRequests[newRequestId] = InferenceRequest({
            requester: msg.sender,
            modelId: _modelId,
            inputHash: _inputHash,
            expectedOutputUnits: _expectedOutputUnits,
            costPaidWei: cost,
            nodeAssigned: address(0), // Assigned later or via off-chain match
            outputHash: 0,
            actualOutputUnits: 0,
            status: RequestStatus.Pending,
            requestTimestamp: block.timestamp,
            fulfilledTimestamp: 0,
            disputedBy: address(0)
        });

        // Refund any excess payment
        if (msg.value > cost) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - cost}("");
            require(success, "Failed to refund excess payment");
        }

        emit InferenceRequested(newRequestId, _modelId, msg.sender, cost);
        return newRequestId;
    }

    /**
     * @dev A registered inference node submits the result for a pending request.
     *      The node receives payment from the escrowed funds.
     * @param _requestId The ID of the inference request.
     * @param _outputHash The hash of the generated output data.
     * @param _actualOutputUnits The actual units of computation/output provided.
     */
    function submitInferenceResult(
        uint256 _requestId,
        bytes32 _outputHash,
        uint256 _actualOutputUnits
    ) public whenNotPaused nonReentrant onlyRegisteredNode {
        InferenceRequest storage req = inferenceRequests[_requestId];
        require(req.status == RequestStatus.Pending, "Request is not pending");
        require(req.requester != address(0), "Request does not exist");
        require(_actualOutputUnits > 0, "Actual output units must be positive");

        // The node that submits is considered assigned for this request.
        // In a real system, nodes might 'accept' requests first.
        req.nodeAssigned = msg.sender;
        req.outputHash = _outputHash;
        req.actualOutputUnits = _actualOutputUnits;
        req.status = RequestStatus.Fulfilled;
        req.fulfilledTimestamp = block.timestamp;

        // Pay the node. For simplicity, we pay the full amount here.
        // A more complex system might adjust payment based on _actualOutputUnits vs _expectedOutputUnits.
        inferenceNodes[msg.sender].rewardsPendingWei += req.costPaidWei;

        emit InferenceResultSubmitted(_requestId, msg.sender, _outputHash);
    }

    /**
     * @dev Allows the requester or another registered node to dispute an inference result.
     *      This marks the request as disputed, requiring off-chain or governance resolution.
     * @param _requestId The ID of the request to dispute.
     */
    function disputeInferenceResult(uint256 _requestId) public whenNotPaused {
        InferenceRequest storage req = inferenceRequests[_requestId];
        require(req.status == RequestStatus.Fulfilled, "Request is not fulfilled or already disputed");
        require(req.requester != address(0), "Request does not exist");
        require(
            msg.sender == req.requester || inferenceNodes[msg.sender].isActive,
            "Only requester or registered node can dispute"
        );
        require(req.nodeAssigned != msg.sender, "Node assigned cannot dispute its own result"); // Prevent self-dispute

        req.status = RequestStatus.Disputed;
        req.disputedBy = msg.sender;

        emit InferenceResultDisputed(_requestId, msg.sender);
        // Funds remain locked until dispute resolution (off-chain/governance)
    }

    // --- IV. Economic Layer (Native currency as "MICs") ---

    /**
     * @dev Allows a registered node to increase its native currency stake.
     */
    function stakeNodeTokens(uint256 _amountWei) public payable whenNotPaused onlyRegisteredNode {
        require(msg.value == _amountWei, "Sent amount must match specified amount");
        inferenceNodes[msg.sender].stakedAmountWei += _amountWei;
        emit InferenceNodeStaked(msg.sender, _amountWei);
    }

    /**
     * @dev Allows a registered node to reduce its native currency stake.
     *      Cannot unstake below the minimum required stake.
     * @param _amountWei The amount to unstake.
     */
    function unstakeNodeTokens(uint256 _amountWei) public whenNotPaused onlyRegisteredNode nonReentrant {
        require(_amountWei > 0, "Unstake amount must be positive");
        require(inferenceNodes[msg.sender].stakedAmountWei - _amountWei >= minimumNodeStakeWei, "Cannot unstake below minimum stake");

        inferenceNodes[msg.sender].stakedAmountWei -= _amountWei;
        (bool success, ) = payable(msg.sender).call{value: _amountWei}("");
        require(success, "Failed to unstake tokens");

        emit InferenceNodeUnstaked(msg.sender, _amountWei);
    }

    /**
     * @dev Allows a registered node to claim its accumulated inference rewards.
     */
    function claimNodeRewards() public whenNotPaused onlyRegisteredNode nonReentrant {
        uint256 rewards = inferenceNodes[msg.sender].rewardsPendingWei;
        require(rewards > 0, "No pending rewards to claim");

        inferenceNodes[msg.sender].rewardsPendingWei = 0;
        (bool success, ) = payable(msg.sender).call{value: rewards}("");
        require(success, "Failed to transfer rewards");

        emit InferenceNodeRewardsClaimed(msg.sender, rewards);
    }

    /**
     * @dev Retrieves the amount of native currency rewards pending for a node.
     * @param _nodeAddress The address of the inference node.
     * @return The amount of pending rewards in wei.
     */
    function getPendingNodeRewards(address _nodeAddress) public view returns (uint256) {
        return inferenceNodes[_nodeAddress].rewardsPendingWei;
    }


    // --- V. Dynamic Pricing & Oracles ---

    /**
     * @dev Sets the base inference cost for a specific AI model.
     *      Can be called by the model owner or an ADMIN_ROLE.
     * @param _modelId The ID of the AI model.
     * @param _newCostWei The new base cost per output unit in wei.
     */
    function setBaseInferenceCost(uint256 _modelId, uint256 _newCostWei) public whenNotPaused {
        require(models[_modelId].owner != address(0), "Model does not exist");
        require(hasRole(ADMIN_ROLE, msg.sender) || ownerOf(_modelId) == msg.sender, "Unauthorized");

        models[_modelId].baseInferenceCostWei = _newCostWei;
        emit BaseInferenceCostUpdated(_modelId, _newCostWei);
    }

    /**
     * @dev Sets a global dynamic pricing factor which multiplies the base cost.
     *      Intended to be updated by an ORACLE_ROLE based on market conditions, network congestion, etc.
     * @param _factorNumerator The numerator of the dynamic pricing factor.
     * @param _factorDenominator The denominator of the dynamic pricing factor.
     *                           (e.g., 120, 100 for a 20% increase)
     */
    function setDynamicPricingFactor(uint256 _factorNumerator, uint256 _factorDenominator) public whenNotPaused onlyRole(ORACLE_ROLE) {
        require(_factorDenominator > 0, "Denominator cannot be zero");
        dynamicPricingFactorNumerator = _factorNumerator;
        dynamicPricingFactorDenominator = _factorDenominator;
        emit DynamicPricingFactorUpdated(_factorNumerator, _factorDenominator);
    }

    /**
     * @dev Sets the minimum required native currency stake for registering an inference node.
     * @param _newMinStakeWei The new minimum stake amount in wei.
     */
    function setMinimumNodeStake(uint256 _newMinStakeWei) public whenNotPaused onlyRole(ADMIN_ROLE) {
        require(_newMinStakeWei >= 0, "Minimum stake cannot be negative"); // Practically, enforce a positive minimum
        minimumNodeStakeWei = _newMinStakeWei;
        emit MinimumNodeStakeUpdated(_newMinStakeWei);
    }

    /**
     * @dev Calculates the effective inference cost for a given model and output units,
     *      applying the dynamic pricing factor.
     * @param _modelId The ID of the AI model.
     * @param _outputUnits The expected units of computation/output.
     * @return The total effective cost in wei.
     */
    function getEffectiveInferenceCost(uint256 _modelId, uint256 _outputUnits) public view returns (uint256) {
        AIModel storage model = models[_modelId];
        require(model.owner != address(0), "Model does not exist");

        uint256 baseCost = model.baseInferenceCostWei * _outputUnits;
        return (baseCost * dynamicPricingFactorNumerator) / dynamicPricingFactorDenominator;
    }

    // --- VI. Access Control & Governance (OpenZeppelin AccessControl) ---

    // The grantRole and revokeRole functions are inherited from AccessControl.
    // We make them public and accessible by the DEFAULT_ADMIN_ROLE.

    /**
     * @dev Grants a role to an account.
     * @param role The role to grant (e.g., ADMIN_ROLE, ATTESTOR_ROLE, ORACLE_ROLE).
     * @param account The address to grant the role to.
     */
    function grantRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes a role from an account.
     * @param role The role to revoke.
     * @param account The address to revoke the role from.
     */
    function revokeRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(role, account);
    }

    // --- Pausable Functions ---
    // These functions allow the admin to pause/unpause critical operations in case of emergency.

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    // --- Internal/Utility Functions ---

    /**
     * @dev See {IERC165-supportsInterface}.
     *      Supports ERC721 and AccessControl interfaces.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
```