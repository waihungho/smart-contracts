This smart contract, named **DAIMCOP (Decentralized AI Model Co-creation & Ownership Platform)**, is designed to enable the collaborative creation, ownership, and monetization of AI model components and complete AI model blueprints. It leverages advanced concepts like tokenized AI assets (NFTs for components), dynamic royalty distribution, decentralized evaluation mechanisms, and a basic on-chain governance system.

---

### **Contract Outline & Function Summary**

**Contract Name:** `DAIMCOP`

**Core Concepts:**
*   **Tokenized AI Components:** Each unique AI component (e.g., a specific neural network layer, a dataset, a pre-trained weight set) is represented by an NFT, conferring ownership.
*   **Model Blueprints:** Users can create "blueprints" for complete AI models, which are then assembled by contributing various AI components.
*   **Dynamic Royalty Distribution:** When a finalized model blueprint is licensed, royalties are distributed to component contributors based on their proportional "value" contributed.
*   **Decentralized Evaluation:** A mechanism to request and record external, verifiable evaluations (e.g., performance, ethical compliance) for blueprints.
*   **Lightweight Governance:** A system for submitting proposals, voting, and executing administrative or upgrade actions.

---

**Function Categories & Summary:**

**I. Core Administration & Access Control (6 functions)**
1.  `constructor()`: Initializes the contract with an admin, fee recipient, and platform fee.
2.  `changeAdmin(address newAdmin)`: Transfers administrative control to a new address.
3.  `pauseContract()`: Puts the contract into a paused state, preventing most operations.
4.  `unpauseContract()`: Resumes operations from a paused state.
5.  `setFeeRecipient(address newRecipient)`: Updates the address that receives platform fees.
6.  `setPlatformFee(uint256 newFeePercentage)`: Adjusts the percentage of royalties taken by the platform.

**II. AI Component Management (ERC-721-like) (4 functions)**
7.  `registerComponent(string memory _name, string memory _uri, ComponentType _type, uint256 _baseValueEstimate)`: Creates a new unique AI component NFT and assigns ownership.
8.  `updateComponentURI(uint256 _componentId, string memory _newUri)`: Allows the owner to update the metadata URI of their component.
9.  `transferComponentOwnership(uint256 _componentId, address _to)`: Transfers ownership of an AI component NFT.
10. `deprecateComponent(uint256 _componentId)`: Marks an AI component as deprecated (e.g., if it's found to be faulty or outdated).

**III. Model Blueprint Creation & Contribution (4 functions)**
11. `createModelBlueprint(string memory _name, string memory _description, string memory _targetApplication, uint256 _minRequiredComponents)`: Initiates a new AI model blueprint, defining its purpose and minimum component requirements.
12. `contributeToBlueprint(uint256 _blueprintId, uint256 _componentId, uint256 _contributionWeight)`: Allows a component owner to contribute their component to a specific blueprint, providing an initial weight for its value.
13. `removeContribution(uint256 _blueprintId, uint256 _componentId)`: Allows a component owner to withdraw their component from a blueprint before it's finalized.
14. `finalizeBlueprint(uint256 _blueprintId)`: Locks in the components and calculates final contribution percentages for a blueprint, making it ready for evaluation/licensing.

**IV. Blueprint Evaluation & Licensing (4 functions)**
15. `requestEvaluation(uint256 _blueprintId, string memory _evaluationProofURI)`: Initiates an external evaluation request for a blueprint, providing a URI to off-chain verifiable proofs.
16. `recordEvaluationResult(uint256 _blueprintId, bytes32 _evalHash, uint256 _score, address _evaluator)`: An authorized evaluator records the outcome of an evaluation.
17. `setBlueprintLicenseFee(uint256 _blueprintId, uint256 _feeAmount, uint256 _usageDuration)`: Sets the licensing terms (fee and duration) for a finalized blueprint.
18. `licenseBlueprint(uint256 _blueprintId) payable`: Allows a user to purchase a license for a blueprint, triggering royalty distribution to contributors.

**V. Royalty & Fund Management (3 functions)**
19. `claimRoyalties(uint256 _blueprintId)`: Allows component contributors to claim their accumulated royalties from a licensed blueprint.
20. `withdrawPlatformFees()`: Enables the designated fee recipient to withdraw accumulated platform fees.
21. `setAuthorizedEvaluator(address _evaluator, bool _isAuthorized)`: Grants or revokes permission for an address to submit evaluation results.

**VI. DAO Governance & Dispute Resolution (4 functions)**
22. `submitProposal(bytes memory _callData, string memory _description)`: Allows a user to propose an administrative action or contract upgrade.
23. `voteOnProposal(uint256 _proposalId, bool _support)`: Enables eligible users to cast their vote on an active proposal.
24. `executeProposal(uint256 _proposalId)`: Executes a successfully voted-on proposal.
25. `updateMinVotingWeight(uint256 _newWeight)`: Sets the minimum aggregated component `_baseValueEstimate` required for an address to submit or vote on a proposal.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// This contract is DAIMCOP (Decentralized AI Model Co-creation & Ownership Platform)
// It facilitates the registration of AI components as NFTs, their contribution to model blueprints,
// and the fair distribution of royalties when blueprints are licensed.
// It also includes basic governance for platform evolution.

contract DAIMCOP is Ownable, Pausable, ReentrancyGuard {

    // --- Enums ---
    enum ComponentType {
        Layer,              // e.g., a specific type of neural network layer (Transformer, CNN, RNN)
        Dataset,            // e.g., a structured dataset or a data preprocessing pipeline
        PretrainedWeights,  // e.g., weights for a specific sub-module
        ActivationFunction, // e.g., a novel activation function
        DataPipeline,       // e.g., an ETL process for AI
        Other               // Catch-all for other AI building blocks
    }

    enum ProposalStatus {
        Pending,
        Active,
        Succeeded,
        Failed,
        Executed
    }

    // --- Structs ---

    struct Component {
        uint256 id;
        string name;
        string uri; // IPFS hash or URL for detailed metadata
        ComponentType componentType;
        address owner;
        uint256 baseValueEstimate; // An initial estimated value for this component
        bool isDeprecated;
    }

    struct Contribution {
        uint256 blueprintId;
        uint256 componentId;
        address contributor;
        uint256 contributionWeight; // Weight of this component's value within the blueprint
        uint256 finalSharePercentage; // Calculated percentage of royalties for this component in this blueprint (e.g., 10000 = 100%)
    }

    struct Blueprint {
        uint256 id;
        string name;
        string description;
        string targetApplication;
        address creator;
        uint256 minRequiredComponents;
        bool isFinalized;
        uint256 totalEstimatedBlueprintValue; // Sum of all contributionWeights
        uint256 licenseFee; // Fee to license this blueprint (in wei)
        uint256 licenseDuration; // Duration of license in seconds (0 for perpetual)
        bytes32 evaluationHash; // Hash of evaluation results, linking to off-chain proofs
        uint256 evaluationScore; // A score from evaluation (e.g., 0-100)
        bool hasBeenEvaluated;
    }

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        bytes callData; // The function call to execute if proposal passes
        uint256 voteCountYes;
        uint256 voteCountNo;
        uint256 deadline;
        ProposalStatus status;
        mapping(address => bool) hasVoted; // Check if an address has voted on this proposal
    }

    // --- State Variables ---

    address private _admin; // Can be changed via changeAdmin or governance
    address public feeRecipient;
    uint256 public platformFeePercentage; // e.g., 500 = 5%

    uint256 public nextComponentId;
    uint256 public nextBlueprintId;
    uint256 public nextProposalId;
    uint256 public minVotingWeight; // Minimum total component value to propose/vote

    mapping(uint256 => Component) public idToComponent;
    mapping(uint256 => Blueprint) public idToBlueprint;
    mapping(uint256 => mapping(uint256 => Contribution)) public blueprintComponentContributions; // blueprintId => componentId => Contribution
    mapping(uint256 => uint256[]) public blueprintComponentsList; // blueprintId => list of componentIds

    mapping(uint256 => uint256) public blueprintRoyaltyPool; // blueprintId => accumulated royalties for distribution
    mapping(uint256 => mapping(uint256 => uint256)) public componentClaimedRoyalties; // blueprintId => componentId => claimed amount

    uint256 public platformFeePool; // Accumulated platform fees

    mapping(address => bool) public authorizedEvaluators;

    mapping(uint256 => Proposal) public idToProposal;
    mapping(address => uint256) public totalComponentValueOwned; // For voting weight

    // --- Events ---

    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);
    event FeeRecipientChanged(address indexed oldRecipient, address indexed newRecipient);
    event PlatformFeeChanged(uint256 oldFee, uint256 newFee);

    event ComponentRegistered(uint256 indexed componentId, address indexed owner, string name, ComponentType cType);
    event ComponentUpdated(uint256 indexed componentId, string newUri);
    event ComponentTransferred(uint256 indexed componentId, address indexed from, address indexed to);
    event ComponentDeprecated(uint256 indexed componentId);

    event BlueprintCreated(uint256 indexed blueprintId, address indexed creator, string name);
    event ComponentContributed(uint256 indexed blueprintId, uint256 indexed componentId, address indexed contributor, uint256 weight);
    event ContributionRemoved(uint256 indexed blueprintId, uint256 indexed componentId, address indexed contributor);
    event BlueprintFinalized(uint256 indexed blueprintId, uint256 totalValue);

    event EvaluationRequested(uint256 indexed blueprintId, address indexed requester, string evaluationProofURI);
    event EvaluationResultRecorded(uint256 indexed blueprintId, bytes32 evalHash, uint256 score, address indexed evaluator);

    event BlueprintLicenseFeeSet(uint256 indexed blueprintId, uint256 feeAmount, uint256 usageDuration);
    event BlueprintLicensed(uint256 indexed blueprintId, address indexed licensee, uint256 amountPaid);
    event RoyaltiesClaimed(uint256 indexed blueprintId, uint256 indexed componentId, address indexed claimant, uint256 amount);
    event PlatformFeesWithdrawn(address indexed recipient, uint256 amount);

    event AuthorizedEvaluatorSet(address indexed evaluator, bool isAuthorized);

    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event MinVotingWeightUpdated(uint256 oldWeight, uint256 newWeight);


    // --- Modifiers ---

    modifier onlyAdmin() {
        require(_admin == msg.sender, "DAIMCOP: Only admin can call this function");
        _;
    }

    modifier onlyBlueprintCreatorOrAdmin(uint256 _blueprintId) {
        require(idToBlueprint[_blueprintId].creator == msg.sender || _admin == msg.sender, "DAIMCOP: Only blueprint creator or admin");
        _;
    }

    modifier onlyComponentOwner(uint256 _componentId) {
        require(idToComponent[_componentId].owner == msg.sender, "DAIMCOP: Only component owner");
        _;
    }

    modifier onlyAuthorizedEvaluator() {
        require(authorizedEvaluators[msg.sender], "DAIMCOP: Only authorized evaluators");
        _;
    }

    // --- Constructor ---

    constructor(address initialFeeRecipient, uint256 initialPlatformFeePercentage) Ownable(msg.sender) {
        _admin = msg.sender;
        feeRecipient = initialFeeRecipient;
        platformFeePercentage = initialPlatformFeePercentage; // e.g., 500 for 5%
        nextComponentId = 1;
        nextBlueprintId = 1;
        nextProposalId = 1;
        minVotingWeight = 1000 ether; // Example: requires components totaling 1000 wei baseValueEstimate to propose/vote

        emit AdminChanged(address(0), _admin);
        emit PlatformFeeChanged(0, platformFeePercentage);
        emit FeeRecipientChanged(address(0), feeRecipient);
        emit MinVotingWeightUpdated(0, minVotingWeight);
    }

    // --- I. Core Administration & Access Control ---

    /**
     * @notice Transfers administrative control to a new address.
     * @param newAdmin The address of the new administrator.
     */
    function changeAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "DAIMCOP: New admin cannot be zero address");
        emit AdminChanged(_admin, newAdmin);
        _admin = newAdmin;
    }

    /**
     * @notice Puts the contract into a paused state.
     *         Only admin can call this.
     */
    function pauseContract() external onlyAdmin whenNotPaused {
        _pause();
    }

    /**
     * @notice Resumes contract operations from a paused state.
     *         Only admin can call this.
     */
    function unpauseContract() external onlyAdmin whenPaused {
        _unpause();
    }

    /**
     * @notice Sets the address that receives platform fees.
     * @param newRecipient The new address for platform fees.
     */
    function setFeeRecipient(address newRecipient) external onlyAdmin {
        require(newRecipient != address(0), "DAIMCOP: New fee recipient cannot be zero address");
        emit FeeRecipientChanged(feeRecipient, newRecipient);
        feeRecipient = newRecipient;
    }

    /**
     * @notice Sets the percentage of royalties taken by the platform.
     *         The value is in basis points (e.g., 500 for 5%). Max 10000 (100%).
     * @param newFeePercentage The new platform fee percentage.
     */
    function setPlatformFee(uint256 newFeePercentage) external onlyAdmin {
        require(newFeePercentage <= 10000, "DAIMCOP: Fee percentage cannot exceed 100%");
        emit PlatformFeeChanged(platformFeePercentage, newFeePercentage);
        platformFeePercentage = newFeePercentage;
    }

    // --- II. AI Component Management (ERC-721-like) ---

    /**
     * @notice Registers a new AI component as an NFT.
     * @param _name The name of the component.
     * @param _uri The URI (e.g., IPFS hash) pointing to the component's metadata.
     * @param _type The type of AI component (e.g., Layer, Dataset).
     * @param _baseValueEstimate An initial estimated value for this component. Used for governance weighting.
     * @return The ID of the newly registered component.
     */
    function registerComponent(
        string memory _name,
        string memory _uri,
        ComponentType _type,
        uint256 _baseValueEstimate
    ) external whenNotPaused nonReentrant returns (uint256) {
        require(bytes(_name).length > 0, "DAIMCOP: Component name cannot be empty");
        require(bytes(_uri).length > 0, "DAIMCOP: Component URI cannot be empty");
        require(_baseValueEstimate > 0, "DAIMCOP: Base value estimate must be greater than zero");

        uint256 componentId = nextComponentId++;
        idToComponent[componentId] = Component({
            id: componentId,
            name: _name,
            uri: _uri,
            componentType: _type,
            owner: msg.sender,
            baseValueEstimate: _baseValueEstimate,
            isDeprecated: false
        });

        totalComponentValueOwned[msg.sender] += _baseValueEstimate;

        emit ComponentRegistered(componentId, msg.sender, _name, _type);
        return componentId;
    }

    /**
     * @notice Allows the component owner to update its metadata URI.
     * @param _componentId The ID of the component.
     * @param _newUri The new URI for the component's metadata.
     */
    function updateComponentURI(uint256 _componentId, string memory _newUri) external onlyComponentOwner(_componentId) whenNotPaused {
        require(bytes(_newUri).length > 0, "DAIMCOP: New URI cannot be empty");
        idToComponent[_componentId].uri = _newUri;
        emit ComponentUpdated(_componentId, _newUri);
    }

    /**
     * @notice Transfers ownership of an AI component NFT.
     * @param _componentId The ID of the component to transfer.
     * @param _to The address of the new owner.
     */
    function transferComponentOwnership(uint256 _componentId, address _to) external onlyComponentOwner(_componentId) whenNotPaused nonReentrant {
        require(_to != address(0), "DAIMCOP: Cannot transfer to zero address");
        require(_to != msg.sender, "DAIMCOP: Cannot transfer to self");

        address from = msg.sender;
        idToComponent[_componentId].owner = _to;

        uint256 componentValue = idToComponent[_componentId].baseValueEstimate;
        totalComponentValueOwned[from] -= componentValue;
        totalComponentValueOwned[_to] += componentValue;

        emit ComponentTransferred(_componentId, from, _to);
    }

    /**
     * @notice Marks an AI component as deprecated. Deprecated components cannot be contributed to new blueprints.
     *         Only the component owner or admin can deprecate.
     * @param _componentId The ID of the component to deprecate.
     */
    function deprecateComponent(uint256 _componentId) external whenNotPaused {
        require(idToComponent[_componentId].owner == msg.sender || _admin == msg.sender, "DAIMCOP: Only component owner or admin can deprecate");
        require(!idToComponent[_componentId].isDeprecated, "DAIMCOP: Component is already deprecated");

        idToComponent[_componentId].isDeprecated = true;
        emit ComponentDeprecated(_componentId);
    }

    // --- III. Model Blueprint Creation & Contribution ---

    /**
     * @notice Initiates a new AI model blueprint.
     * @param _name The name of the model blueprint.
     * @param _description A description of the model's purpose.
     * @param _targetApplication The intended application area for the model.
     * @param _minRequiredComponents The minimum number of components required to finalize this blueprint.
     * @return The ID of the newly created blueprint.
     */
    function createModelBlueprint(
        string memory _name,
        string memory _description,
        string memory _targetApplication,
        uint256 _minRequiredComponents
    ) external whenNotPaused returns (uint256) {
        require(bytes(_name).length > 0, "DAIMCOP: Blueprint name cannot be empty");
        require(_minRequiredComponents > 0, "DAIMCOP: Must require at least one component");

        uint256 blueprintId = nextBlueprintId++;
        idToBlueprint[blueprintId] = Blueprint({
            id: blueprintId,
            name: _name,
            description: _description,
            targetApplication: _targetApplication,
            creator: msg.sender,
            minRequiredComponents: _minRequiredComponents,
            isFinalized: false,
            totalEstimatedBlueprintValue: 0,
            licenseFee: 0,
            licenseDuration: 0,
            evaluationHash: bytes32(0),
            evaluationScore: 0,
            hasBeenEvaluated: false
        });

        emit BlueprintCreated(blueprintId, msg.sender, _name);
        return blueprintId;
    }

    /**
     * @notice Allows a component owner to contribute their component to a specific blueprint.
     *         This component will be part of the final model.
     * @param _blueprintId The ID of the blueprint to contribute to.
     * @param _componentId The ID of the component being contributed.
     * @param _contributionWeight A weight representing the component's value within this blueprint.
     */
    function contributeToBlueprint(
        uint256 _blueprintId,
        uint256 _componentId,
        uint256 _contributionWeight
    ) external onlyComponentOwner(_componentId) whenNotPaused nonReentrant {
        Blueprint storage blueprint = idToBlueprint[_blueprintId];
        require(blueprint.creator != address(0), "DAIMCOP: Blueprint does not exist");
        require(!blueprint.isFinalized, "DAIMCOP: Blueprint is already finalized");
        require(!idToComponent[_componentId].isDeprecated, "DAIMCOP: Cannot contribute deprecated components");
        require(_contributionWeight > 0, "DAIMCOP: Contribution weight must be positive");

        // Ensure this component isn't already contributed to this blueprint by this user
        require(blueprintComponentContributions[_blueprintId][_componentId].contributor == address(0), "DAIMCOP: Component already contributed to this blueprint");

        blueprintComponentContributions[_blueprintId][_componentId] = Contribution({
            blueprintId: _blueprintId,
            componentId: _componentId,
            contributor: msg.sender,
            contributionWeight: _contributionWeight,
            finalSharePercentage: 0 // Will be calculated upon finalization
        });
        blueprintComponentsList[_blueprintId].push(_componentId);
        blueprint.totalEstimatedBlueprintValue += _contributionWeight;

        emit ComponentContributed(_blueprintId, _componentId, msg.sender, _contributionWeight);
    }

    /**
     * @notice Allows a component owner to withdraw their contribution from a blueprint before it's finalized.
     * @param _blueprintId The ID of the blueprint.
     * @param _componentId The ID of the component to remove.
     */
    function removeContribution(uint256 _blueprintId, uint256 _componentId) external onlyComponentOwner(_componentId) whenNotPaused nonReentrant {
        Blueprint storage blueprint = idToBlueprint[_blueprintId];
        require(blueprint.creator != address(0), "DAIMCOP: Blueprint does not exist");
        require(!blueprint.isFinalized, "DAIMCOP: Blueprint is already finalized");

        Contribution storage contribution = blueprintComponentContributions[_blueprintId][_componentId];
        require(contribution.contributor == msg.sender, "DAIMCOP: Not your contribution or not contributed");

        // Remove from blueprintComponentsList (inefficient for large arrays, but simple)
        uint256[] storage components = blueprintComponentsList[_blueprintId];
        for (uint i = 0; i < components.length; i++) {
            if (components[i] == _componentId) {
                components[i] = components[components.length - 1];
                components.pop();
                break;
            }
        }

        blueprint.totalEstimatedBlueprintValue -= contribution.contributionWeight;
        delete blueprintComponentContributions[_blueprintId][_componentId]; // Clear the contribution data

        emit ContributionRemoved(_blueprintId, _componentId, msg.sender);
    }

    /**
     * @notice Finalizes a blueprint, locking in its components and calculating final contribution percentages.
     *         Only the blueprint creator or admin can finalize.
     *         After finalization, no more components can be added or removed.
     * @param _blueprintId The ID of the blueprint to finalize.
     */
    function finalizeBlueprint(uint256 _blueprintId) external onlyBlueprintCreatorOrAdmin(_blueprintId) whenNotPaused {
        Blueprint storage blueprint = idToBlueprint[_blueprintId];
        require(blueprint.creator != address(0), "DAIMCOP: Blueprint does not exist");
        require(!blueprint.isFinalized, "DAIMCOP: Blueprint is already finalized");
        require(blueprintComponentsList[_blueprintId].length >= blueprint.minRequiredComponents, "DAIMCOP: Not enough components to finalize");
        require(blueprint.totalEstimatedBlueprintValue > 0, "DAIMCOP: Blueprint must have a positive total estimated value");

        // Calculate final share percentages
        for (uint i = 0; i < blueprintComponentsList[_blueprintId].length; i++) {
            uint256 componentId = blueprintComponentsList[_blueprintId][i];
            Contribution storage contribution = blueprintComponentContributions[_blueprintId][componentId];
            // Percentage is calculated out of 10,000 to allow for two decimal places (e.g., 500 = 5.00%)
            contribution.finalSharePercentage = (contribution.contributionWeight * 10000) / blueprint.totalEstimatedBlueprintValue;
        }

        blueprint.isFinalized = true;
        emit BlueprintFinalized(_blueprintId, blueprint.totalEstimatedBlueprintValue);
    }

    // --- IV. Blueprint Evaluation & Licensing ---

    /**
     * @notice Initiates an external evaluation request for a finalized blueprint.
     *         _evaluationProofURI should point to off-chain verifiable computation/proofs.
     * @param _blueprintId The ID of the blueprint to evaluate.
     * @param _evaluationProofURI URI for the off-chain evaluation proof.
     */
    function requestEvaluation(uint256 _blueprintId, string memory _evaluationProofURI) external whenNotPaused {
        Blueprint storage blueprint = idToBlueprint[_blueprintId];
        require(blueprint.creator != address(0), "DAIMCOP: Blueprint does not exist");
        require(blueprint.isFinalized, "DAIMCOP: Blueprint must be finalized for evaluation");
        require(bytes(_evaluationProofURI).length > 0, "DAIMCOP: Evaluation proof URI cannot be empty");

        emit EvaluationRequested(_blueprintId, msg.sender, _evaluationProofURI);
    }

    /**
     * @notice An authorized evaluator records the result of a blueprint evaluation.
     * @param _blueprintId The ID of the blueprint that was evaluated.
     * @param _evalHash A hash representing the evaluation data (e.g., hash of a ZK proof or verifiable computation).
     * @param _score The numerical score of the evaluation (e.g., accuracy, bias score).
     * @param _evaluator The address of the evaluator (for record-keeping, should be msg.sender).
     */
    function recordEvaluationResult(
        uint256 _blueprintId,
        bytes32 _evalHash,
        uint256 _score,
        address _evaluator
    ) external onlyAuthorizedEvaluator whenNotPaused {
        Blueprint storage blueprint = idToBlueprint[_blueprintId];
        require(blueprint.creator != address(0), "DAIMCOP: Blueprint does not exist");
        require(blueprint.isFinalized, "DAIMCOP: Blueprint must be finalized");
        require(_evaluator == msg.sender, "DAIMCOP: Evaluator address must match msg.sender"); // Prevent spoofing

        blueprint.evaluationHash = _evalHash;
        blueprint.evaluationScore = _score;
        blueprint.hasBeenEvaluated = true;

        emit EvaluationResultRecorded(_blueprintId, _evalHash, _score, _evaluator);
    }

    /**
     * @notice Sets the license fee and duration for a finalized blueprint.
     *         Only the blueprint creator or admin can set this.
     * @param _blueprintId The ID of the blueprint.
     * @param _feeAmount The fee to license this blueprint (in wei).
     * @param _usageDuration The duration of the license in seconds (0 for perpetual).
     */
    function setBlueprintLicenseFee(
        uint256 _blueprintId,
        uint256 _feeAmount,
        uint256 _usageDuration
    ) external onlyBlueprintCreatorOrAdmin(_blueprintId) whenNotPaused {
        Blueprint storage blueprint = idToBlueprint[_blueprintId];
        require(blueprint.creator != address(0), "DAIMCOP: Blueprint does not exist");
        require(blueprint.isFinalized, "DAIMCOP: Blueprint must be finalized");
        require(_feeAmount > 0, "DAIMCOP: License fee must be greater than zero");

        blueprint.licenseFee = _feeAmount;
        blueprint.licenseDuration = _usageDuration; // Allows for time-limited licenses

        emit BlueprintLicenseFeeSet(_blueprintId, _feeAmount, _usageDuration);
    }

    /**
     * @notice Allows a user to purchase a license for a finalized blueprint.
     *         The payment is distributed as royalties to component contributors and platform fees.
     * @param _blueprintId The ID of the blueprint to license.
     */
    function licenseBlueprint(uint256 _blueprintId) external payable whenNotPaused nonReentrant {
        Blueprint storage blueprint = idToBlueprint[_blueprintId];
        require(blueprint.creator != address(0), "DAIMCOP: Blueprint does not exist");
        require(blueprint.isFinalized, "DAIMCOP: Blueprint must be finalized");
        require(blueprint.licenseFee > 0, "DAIMCOP: License fee not set or is zero");
        require(msg.value == blueprint.licenseFee, "DAIMCOP: Incorrect license fee paid");

        // Calculate platform fee
        uint256 platformFee = (msg.value * platformFeePercentage) / 10000;
        platformFeePool += platformFee;

        // Remaining amount goes to royalty pool
        uint256 royaltyAmount = msg.value - platformFee;
        blueprintRoyaltyPool[_blueprintId] += royaltyAmount;

        emit BlueprintLicensed(_blueprintId, msg.sender, msg.value);
    }

    // --- V. Royalty & Fund Management ---

    /**
     * @notice Allows component contributors to claim their accumulated royalties from a specific blueprint.
     * @param _blueprintId The ID of the blueprint to claim royalties from.
     */
    function claimRoyalties(uint256 _blueprintId) external whenNotPaused nonReentrant {
        Blueprint storage blueprint = idToBlueprint[_blueprintId];
        require(blueprint.creator != address(0), "DAIMCOP: Blueprint does not exist");
        require(blueprint.isFinalized, "DAIMCOP: Blueprint must be finalized");
        require(blueprintRoyaltyPool[_blueprintId] > 0, "DAIMCOP: No royalties available for this blueprint");

        uint256 payableAmount = 0;
        uint256[] storage componentIds = blueprintComponentsList[_blueprintId];

        for (uint i = 0; i < componentIds.length; i++) {
            uint256 componentId = componentIds[i];
            Contribution storage contribution = blueprintComponentContributions[_blueprintId][componentId];

            if (contribution.contributor == msg.sender) {
                // Calculate portion of the available royalty pool based on finalSharePercentage
                uint256 potentialClaim = (blueprintRoyaltyPool[_blueprintId] * contribution.finalSharePercentage) / 10000;
                
                // Only allow claiming if the component owner is still the contributor
                // This prevents users who transferred their component from claiming old royalties
                if (idToComponent[componentId].owner == msg.sender) {
                    uint256 alreadyClaimed = componentClaimedRoyalties[_blueprintId][componentId];
                    uint256 unclaimedAmount = potentialClaim - alreadyClaimed;
                    
                    if (unclaimedAmount > 0) {
                        payableAmount += unclaimedAmount;
                        componentClaimedRoyalties[_blueprintId][componentId] += unclaimedAmount;
                        emit RoyaltiesClaimed(_blueprintId, componentId, msg.sender, unclaimedAmount);
                    }
                }
            }
        }

        require(payableAmount > 0, "DAIMCOP: No unclaimed royalties for msg.sender in this blueprint");

        // Transfer collected royalties
        // This simple distribution method might lead to front-running if not handled carefully,
        // but for a fixed-share model, it's generally safe as overall pool is fixed per license.
        (bool success, ) = msg.sender.call{value: payableAmount}("");
        require(success, "DAIMCOP: Failed to transfer royalties");
    }


    /**
     * @notice Allows the designated fee recipient to withdraw accumulated platform fees.
     */
    function withdrawPlatformFees() external nonReentrant {
        require(msg.sender == feeRecipient, "DAIMCOP: Only fee recipient can withdraw");
        require(platformFeePool > 0, "DAIMCOP: No platform fees to withdraw");

        uint256 amount = platformFeePool;
        platformFeePool = 0;

        (bool success, ) = feeRecipient.call{value: amount}("");
        require(success, "DAIMCOP: Failed to withdraw platform fees");
        emit PlatformFeesWithdrawn(feeRecipient, amount);
    }

    /**
     * @notice Grants or revokes permission for an address to submit evaluation results.
     * @param _evaluator The address to set authorization for.
     * @param _isAuthorized True to authorize, false to revoke.
     */
    function setAuthorizedEvaluator(address _evaluator, bool _isAuthorized) external onlyAdmin {
        require(_evaluator != address(0), "DAIMCOP: Evaluator address cannot be zero");
        authorizedEvaluators[_evaluator] = _isAuthorized;
        emit AuthorizedEvaluatorSet(_evaluator, _isAuthorized);
    }

    // --- VI. DAO Governance & Dispute Resolution (Simplified) ---

    /**
     * @notice Submits a proposal for governance vote. Requires min voting weight.
     * @param _callData The encoded function call to execute if the proposal passes.
     * @param _description A description of the proposal.
     * @return The ID of the submitted proposal.
     */
    function submitProposal(bytes memory _callData, string memory _description) external whenNotPaused returns (uint256) {
        require(totalComponentValueOwned[msg.sender] >= minVotingWeight, "DAIMCOP: Not enough voting weight to submit proposal");
        require(bytes(_description).length > 0, "DAIMCOP: Proposal description cannot be empty");
        require(_callData.length > 0, "DAIMCOP: Proposal callData cannot be empty");

        uint256 proposalId = nextProposalId++;
        idToProposal[proposalId].id = proposalId;
        idToProposal[proposalId].proposer = msg.sender;
        idToProposal[proposalId].description = _description;
        idToProposal[proposalId].callData = _callData;
        idToProposal[proposalId].deadline = block.timestamp + 7 days; // 7 days voting period
        idToProposal[proposalId].status = ProposalStatus.Active;

        emit ProposalSubmitted(proposalId, msg.sender, _description);
        return proposalId;
    }

    /**
     * @notice Allows an eligible user to cast their vote on an active proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'yes', false for 'no'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused {
        Proposal storage proposal = idToProposal[_proposalId];
        require(proposal.status == ProposalStatus.Active, "DAIMCOP: Proposal is not active");
        require(block.timestamp <= proposal.deadline, "DAIMCOP: Voting period has ended");
        require(totalComponentValueOwned[msg.sender] >= minVotingWeight, "DAIMCOP: Not enough voting weight to vote");
        require(!proposal.hasVoted[msg.sender], "DAIMCOP: Already voted on this proposal");

        if (_support) {
            proposal.voteCountYes += totalComponentValueOwned[msg.sender];
        } else {
            proposal.voteCountNo += totalComponentValueOwned[msg.sender];
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(_proposalId, msg.sender, _support);
    }

    /**
     * @notice Executes a successfully voted-on proposal.
     *         Can be called by anyone after the voting period ends.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external whenNotPaused nonReentrant {
        Proposal storage proposal = idToProposal[_proposalId];
        require(proposal.status == ProposalStatus.Active, "DAIMCOP: Proposal is not active");
        require(block.timestamp > proposal.deadline, "DAIMCOP: Voting period not yet ended");

        if (proposal.voteCountYes > proposal.voteCountNo) {
            // Proposal passed
            proposal.status = ProposalStatus.Succeeded;
            (bool success, ) = address(this).call(proposal.callData);
            require(success, "DAIMCOP: Proposal execution failed");
            proposal.status = ProposalStatus.Executed;
            emit ProposalExecuted(_proposalId);
        } else {
            // Proposal failed
            proposal.status = ProposalStatus.Failed;
        }
    }

    /**
     * @notice Sets the minimum aggregated component `_baseValueEstimate` required for an address to submit or vote on a proposal.
     *         Only admin can update this.
     * @param _newWeight The new minimum voting weight.
     */
    function updateMinVotingWeight(uint256 _newWeight) external onlyAdmin {
        require(_newWeight > 0, "DAIMCOP: Minimum voting weight must be positive");
        emit MinVotingWeightUpdated(minVotingWeight, _newWeight);
        minVotingWeight = _newWeight;
    }

    // --- View Functions (Helpers) ---

    function getBlueprintComponents(uint256 _blueprintId) external view returns (uint256[] memory) {
        return blueprintComponentsList[_blueprintId];
    }

    function getComponentOwner(uint256 _componentId) external view returns (address) {
        return idToComponent[_componentId].owner;
    }

    function getProposalStatus(uint256 _proposalId) external view returns (ProposalStatus) {
        Proposal storage proposal = idToProposal[_proposalId];
        if (proposal.status == ProposalStatus.Active && block.timestamp > proposal.deadline) {
            if (proposal.voteCountYes > proposal.voteCountNo) {
                return ProposalStatus.Succeeded;
            } else {
                return ProposalStatus.Failed;
            }
        }
        return proposal.status;
    }

    function getAdmin() external view returns (address) {
        return _admin;
    }
}
```