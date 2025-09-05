This smart contract, `SentientDigitalTwinNetwork`, introduces a novel concept of **dynamic, AI-enhanced Digital Twins (NFTs)**. These Twins are not static digital collectibles but rather evolve and learn through user interaction and integration with an off-chain AI Oracle. The contract facilitates inter-twin dynamics, collaborative tasks, and a micro-economy around their development and insights.

---

### **Contract Name:** `SentientDigitalTwinNetwork`

### **Purpose:**
To create and manage a decentralized network of "Digital Twins" represented as ERC721 NFTs. Each Twin possesses dynamic traits, a sentiment score, and can evolve based on user training and the validated output of an external AI Oracle. The contract enables complex interactions between Twins, collaborative tasks with rewards, and a governance mechanism for network-wide evolution policies.

### **Core Concepts & Innovations:**
1.  **Dynamic NFTs:** Twin NFTs are not static; their metadata and underlying characteristics (traits, sentiment) change over time based on on-chain events and off-chain AI processing.
2.  **AI Oracle Integration (Request-Fulfill Pattern):** The contract securely interfaces with an external, trusted AI Oracle service. Users submit training data hashes, and the contract requests the Oracle to process this data. The Oracle then submits validated results back to the contract, updating Twin states. This mimics verifiable AI computation without executing AI on-chain.
3.  **Inter-Twin Dynamics:** Twins can interact with each other, leading to collaborative or competitive outcomes that influence their respective traits.
4.  **Collaborative Task System:** Twins can collectively participate in defined tasks, contributing data or effort, and receiving shared rewards upon successful, AI-verified completion.
5.  **Decentralized Evolution Policy:** A simplified governance model allows Twin owners to propose and vote on network-wide evolution policies, guiding the future development or rule changes for the Digital Twin ecosystem.
6.  **Micro-Economy:** A system for users to deposit fees for AI services (training, interaction outcomes) and for the AI Oracle to withdraw those fees. Rewards can also be distributed for valuable Twin insights or task completion.

### **Outline & Function Summary:**

**I. Core Twin Lifecycle & ERC721 Compliance**
*   `constructor()`: Initializes the contract with an AI Oracle address.
*   `mintTwin(string memory _name)`: Mints a new Digital Twin NFT for the caller, assigning it a unique ID and initial traits.
*   `getTwinDetails(uint256 _twinId)`: Retrieves all detailed information about a specific Digital Twin.
*   `tokenURI(uint256 _twinId)`: Returns the dynamic metadata URI for a Twin, reflecting its current evolving state.
*   `updateTwinName(uint256 _twinId, string memory _newName)`: Allows the owner to update their Twin's displayed name.
*   `_baseURI()`: Internal helper for `tokenURI`.
*   `supportsInterface(bytes4 interfaceId)`: ERC165 standard.

**II. AI Oracle Interaction & Twin Evolution**
*   `requestTwinTraitUpdate(uint256 _twinId, string[] memory _traitKeys, bytes32 _trainingDataHash)`: Initiates a request for the AI Oracle to update a Twin's specific traits based on submitted training data (represented by a hash). Requires a fee deposit.
*   `fulfillTwinTraitUpdate(uint256 _twinId, string[] memory _traitKeys, int256[] memory _traitValues, bytes32 _trainingDataHash, bytes32 _oracleProof)`: Only callable by the designated AI Oracle. Validates and applies trait updates to a Twin based on the Oracle's computation.
*   `requestTwinSentimentAnalysis(uint256 _twinId, bytes32 _interactionHistoryHash)`: Requests the AI Oracle to analyze a Twin's interaction history (represented by a hash) and provide a sentiment score.
*   `fulfillTwinSentimentAnalysis(uint256 _twinId, int256 _sentimentScore, bytes32 _oracleProof)`: Only callable by the AI Oracle. Updates a Twin's sentiment score.

**III. Inter-Twin Dynamics & Collaboration**
*   `initiateTwinInteraction(uint256 _twin1Id, uint256 _twin2Id, string memory _interactionContext)`: An owner proposes an interaction between their Twin and another.
*   `acceptTwinInteraction(uint256 _interactionId)`: The owner of the target Twin accepts the interaction.
*   `requestInteractionOutcome(uint256 _interactionId)`: Requests the AI Oracle to determine the outcome of a completed interaction.
*   `fulfillInteractionOutcome(uint256 _interactionId, uint256[] memory _targetTwinIds, string[] memory _traitKeys, int256[] memory _traitValues, bytes32 _oracleProof)`: Oracle updates traits for participating Twins based on the interaction outcome.
*   `registerCollaborativeTask(string memory _taskDescription, uint256 _rewardPool, uint256[] memory _participantTwinIds)`: Registers a new collaborative task, defining its description, reward, and initial participants.
*   `submitTaskContribution(uint256 _taskId, uint256 _twinId, bytes32 _contributionHash)`: A participant Twin's owner submits their contribution to a registered task.
*   `requestTaskCompletionEvaluation(uint256 _taskId)`: Requests the AI Oracle to evaluate if a collaborative task has been successfully completed.
*   `fulfillTaskCompletionEvaluation(uint256 _taskId, bool _success, bytes32 _oracleProof)`: Oracle finalizes the task, marking it as successful or failed, and enables reward claiming if successful.
*   `claimTaskReward(uint256 _taskId)`: Allows an owner of a participating Twin in a successful task to claim their share of the reward.

**IV. Economic & Utility Functions**
*   `depositOracleServiceFees()`: Allows users to deposit ETH into the contract to cover fees for AI Oracle services (e.g., trait updates, interaction outcomes).
*   `withdrawOracleFees(address _recipient, uint256 _amount)`: Allows the AI Oracle to withdraw accumulated fees for its services.
*   `setInteractionCost(uint256 _newCost)`: Owner function to adjust the cost of initiating inter-twin interactions.
*   `setTrainingCost(uint256 _newCost)`: Owner function to adjust the cost of requesting trait updates.

**V. Admin & Governance**
*   `setAIOracleAddress(address _newOracle)`: Owner function to update the trusted AI Oracle address.
*   `proposeEvolutionPolicy(string memory _policyDescription, bytes32 _policyHash, uint256 _votingDuration)`: Allows a Twin owner to propose a network-wide evolution policy (e.g., new trait categories, rule changes).
*   `voteOnEvolutionPolicy(uint256 _policyId, bool _support)`: Allows Twin owners to vote on an active evolution policy proposal.
*   `executeEvolutionPolicy(uint256 _policyId)`: Allows the contract owner to execute a policy that has passed its voting period and received enough votes (simplified for this example, could be more decentralized).
*   `pause()`: Pauses contract functionality in case of emergency.
*   `unpause()`: Unpauses contract functionality.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title SentientDigitalTwinNetwork
 * @dev Manages a network of dynamic, AI-enhanced Digital Twins (NFTs) that evolve through user interaction
 *      and AI oracle integration, facilitating inter-twin dynamics and a micro-economy.
 *
 * This contract introduces a novel concept of dynamic, AI-enhanced Digital Twins (NFTs).
 * These Twins are not static digital collectibles but rather evolve and learn through user interaction
 * and integration with an off-chain AI Oracle.
 *
 * Core Concepts & Innovations:
 * 1.  Dynamic NFTs: Twin NFTs are not static; their metadata and underlying characteristics (traits, sentiment)
 *     change over time based on on-chain events and off-chain AI processing.
 * 2.  AI Oracle Integration (Request-Fulfill Pattern): The contract securely interfaces with an external,
 *     trusted AI Oracle service. Users submit training data hashes, and the contract requests the Oracle to
 *     process this data. The Oracle then submits validated results back to the contract, updating Twin states.
 *     This mimics verifiable AI computation without executing AI on-chain.
 * 3.  Inter-Twin Dynamics: Twins can interact with each other, leading to collaborative or competitive
 *     outcomes that influence their respective traits.
 * 4.  Collaborative Task System: Twins can collectively participate in defined tasks, contributing data or effort,
 *     and receiving shared rewards upon successful, AI-verified completion.
 * 5.  Decentralized Evolution Policy: A simplified governance model allows Twin owners to propose and vote on
 *     network-wide evolution policies, guiding the future development or rule changes for the Digital Twin ecosystem.
 * 6.  Micro-Economy: A system for users to deposit fees for AI services (training, interaction outcomes) and
 *     for the AI Oracle to withdraw those fees. Rewards can also be distributed for valuable Twin insights or
 *     task completion.
 */
contract SentientDigitalTwinNetwork is ERC721, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---
    Counters.Counter private _twinIds;
    Counters.Counter private _interactionIds;
    Counters.Counter private _taskIds;
    Counters.Counter private _policyIds;

    address private _aiOracleAddress;
    uint256 public trainingCost = 0.01 ether; // Cost for AI oracle to process a trait update request
    uint256 public interactionCost = 0.005 ether; // Cost for AI oracle to process an interaction outcome

    // Stores funds deposited by users for AI Oracle services
    mapping(address => uint256) public oracleFeeDeposits;
    // Tracks accumulated fees for the AI Oracle
    uint256 public aiOracleBalance;

    string private _baseTokenURI;

    // --- Structs ---

    struct Twin {
        uint256 id;
        address owner;
        string name;
        mapping(string => int256) traits; // Dynamic traits (e.g., "intelligence", "creativity")
        int256 sentimentScore; // Overall sentiment, updated by AI
        uint256 lastUpdated;
        bytes32 currentMetadataHash; // Hash of off-chain metadata JSON, allows for dynamic updates
        string[] traitKeys; // To iterate over traits
    }

    struct TwinInteraction {
        uint256 twin1Id;
        uint256 twin2Id;
        address initiator;
        uint256 requestTime;
        Status status;
        bytes32 outcomeHash; // Hash of the AI oracle's outcome, for verification/reference
    }

    struct CollaborativeTask {
        uint256 id;
        string description;
        uint256 rewardPool; // Funds for participants, distributed upon success
        mapping(uint256 => bool) participants; // twinId => isParticipant
        uint256[] participantTwinIds; // Array of twin IDs
        mapping(uint256 => bytes32) contributions; // twinId => contributionHash
        uint256 creationTime;
        Status status;
        bytes32 outcomeHash; // Hash of the AI oracle's outcome
        mapping(uint256 => bool) claimedRewards; // twinId => hasClaimed
    }

    struct EvolutionPolicy {
        uint256 id;
        address proposer;
        string description;
        bytes32 policyHash; // Hash of the proposed policy document
        uint256 votingDeadline;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
    }

    enum Status { Pending, Active, Resolved, Failed, Approved, Rejected }

    // --- Mappings ---
    mapping(uint256 => Twin) public twins;
    mapping(uint256 => TwinInteraction) public interactions;
    mapping(uint256 => CollaborativeTask) public tasks;
    mapping(uint256 => EvolutionPolicy) public policies;
    mapping(uint256 => mapping(address => bool)) public policyVoters; // policyId => voterAddress => hasVoted

    // --- Events ---
    event TwinMinted(uint256 indexed twinId, address indexed owner, string name, uint256 timestamp);
    event TwinNameUpdated(uint256 indexed twinId, string newName, uint256 timestamp);
    event TraitUpdateRequest(uint256 indexed twinId, address indexed requester, bytes32 trainingDataHash, uint256 timestamp);
    event TraitUpdateFulfilled(uint256 indexed twinId, bytes32 oracleProof, uint256 timestamp);
    event TwinSentimentAnalysisRequested(uint256 indexed twinId, bytes32 interactionHistoryHash, uint256 timestamp);
    event TwinSentimentAnalysisFulfilled(uint256 indexed twinId, int256 sentimentScore, bytes32 oracleProof, uint256 timestamp);
    event InteractionInitiated(uint256 indexed interactionId, uint256 indexed twin1Id, uint256 indexed twin2Id, address indexed initiator, string context);
    event InteractionAccepted(uint256 indexed interactionId, uint256 indexed twin1Id, uint256 indexed twin2Id);
    event InteractionOutcomeRequested(uint256 indexed interactionId);
    event InteractionOutcomeFulfilled(uint256 indexed interactionId, bytes32 oracleProof);
    event CollaborativeTaskRegistered(uint256 indexed taskId, string description, uint256 rewardPool, address indexed creator);
    event TaskContributionSubmitted(uint256 indexed taskId, uint256 indexed twinId, bytes32 contributionHash);
    event TaskCompletionEvaluationRequested(uint256 indexed taskId);
    event TaskCompletionEvaluationFulfilled(uint256 indexed taskId, bool success, bytes32 oracleProof);
    event TaskRewardClaimed(uint256 indexed taskId, uint256 indexed twinId, address indexed claimant, uint256 rewardAmount);
    event EvolutionPolicyProposed(uint256 indexed policyId, address indexed proposer, string description, uint256 votingDeadline);
    event PolicyVoted(uint256 indexed policyId, address indexed voter, bool support);
    event PolicyExecuted(uint256 indexed policyId, bool success);
    event OracleFeeDeposited(address indexed depositor, uint256 amount);
    event OracleFeesWithdrawn(address indexed recipient, uint256 amount);
    event AIOracleAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event InteractionCostUpdated(uint256 newCost);
    event TrainingCostUpdated(uint256 newCost);


    // --- Modifiers ---
    modifier onlyTwinOwner(uint256 _twinId) {
        require(_exists(_twinId), "Twin does not exist");
        require(ownerOf(_twinId) == _msgSender(), "Caller is not the twin owner");
        _;
    }

    modifier onlyAIOracle() {
        require(_msgSender() == _aiOracleAddress, "Caller is not the AI Oracle");
        _;
    }

    modifier onlyActiveInteraction(uint256 _interactionId) {
        require(interactions[_interactionId].status == Status.Active, "Interaction is not active");
        _;
    }

    modifier onlyPendingInteraction(uint256 _interactionId) {
        require(interactions[_interactionId].status == Status.Pending, "Interaction is not pending");
        _;
    }

    modifier onlyActiveTask(uint256 _taskId) {
        require(tasks[_taskId].status == Status.Active, "Task is not active");
        _;
    }

    modifier onlyParticipatingTwin(uint256 _taskId, uint256 _twinId) {
        require(tasks[_taskId].participants[_twinId], "Twin is not a participant in this task");
        _;
    }

    // --- Constructor ---
    constructor(address initialAIOracleAddress)
        ERC721("SentientDigitalTwin", "SDT")
        Ownable(msg.sender)
    {
        require(initialAIOracleAddress != address(0), "AI Oracle address cannot be zero");
        _aiOracleAddress = initialAIOracleAddress;
        _baseTokenURI = "ipfs://Qmbj8Fv7xQ2W1g2R6S8j0E9X1yZ3M4N5P6O7I8H9G0F/"; // Placeholder base URI
    }

    // --- I. Core Twin Lifecycle & ERC721 Compliance ---

    /**
     * @dev Mints a new Digital Twin NFT for the caller.
     * @param _name The desired name for the new Twin.
     */
    function mintTwin(string memory _name) public payable whenNotPaused nonReentrant {
        _twinIds.increment();
        uint256 newTwinId = _twinIds.current();

        require(bytes(_name).length > 0, "Twin name cannot be empty");

        _safeMint(_msgSender(), newTwinId);

        twins[newTwinId].id = newTwinId;
        twins[newTwinId].owner = _msgSender();
        twins[newTwinId].name = _name;
        twins[newTwinId].sentimentScore = 0; // Initial sentiment
        twins[newTwinId].lastUpdated = block.timestamp;
        // Initialize with some default traits
        twins[newTwinId].traits["intelligence"] = 50;
        twins[newTwinId].traits["creativity"] = 50;
        twins[newTwinId].traits["empathy"] = 50;
        twins[newTwinId].traitKeys.push("intelligence");
        twins[newTwinId].traitKeys.push("creativity");
        twins[newTwinId].traitKeys.push("empathy");

        // Placeholder for initial metadata hash, would be generated by off-chain service
        twins[newTwinId].currentMetadataHash = keccak256(abi.encodePacked(newTwinId, _name, block.timestamp));

        emit TwinMinted(newTwinId, _msgSender(), _name, block.timestamp);
    }

    /**
     * @dev Retrieves comprehensive details of a specific Digital Twin.
     * @param _twinId The ID of the Twin to query.
     * @return A tuple containing all Twin properties.
     */
    function getTwinDetails(uint256 _twinId)
        public
        view
        returns (
            uint256 id,
            address owner,
            string memory name,
            int256 sentimentScore,
            uint256 lastUpdated,
            bytes32 currentMetadataHash,
            string[] memory traitKeys,
            int256[] memory traitValues
        )
    {
        require(_exists(_twinId), "Twin does not exist");
        Twin storage twin = twins[_twinId];

        uint256 numTraits = twin.traitKeys.length;
        int256[] memory values = new int256[](numTraits);
        for (uint256 i = 0; i < numTraits; i++) {
            values[i] = twin.traits[twin.traitKeys[i]];
        }

        return (
            twin.id,
            twin.owner,
            twin.name,
            twin.sentimentScore,
            twin.lastUpdated,
            twin.currentMetadataHash,
            twin.traitKeys,
            values
        );
    }

    /**
     * @dev Returns the dynamic metadata URI for a Twin. The actual metadata would be served off-chain,
     *      reflecting the Twin's current evolving state based on `currentMetadataHash`.
     * @param _twinId The ID of the Twin.
     * @return The URI pointing to the Twin's metadata.
     */
    function tokenURI(uint256 _twinId) public view override returns (string memory) {
        require(_exists(_twinId), "ERC721Metadata: URI query for nonexistent token");
        // In a real scenario, _baseTokenURI would point to a service that dynamically generates
        // JSON metadata based on the Twin's state (e.g., using currentMetadataHash).
        return string(abi.encodePacked(_baseTokenURI, _twinId.toString(), ".json"));
    }

    /**
     * @dev Allows the owner to update their Twin's displayed name.
     * @param _twinId The ID of the Twin.
     * @param _newName The new name for the Twin.
     */
    function updateTwinName(uint256 _twinId, string memory _newName) public onlyTwinOwner(_twinId) whenNotPaused {
        require(bytes(_newName).length > 0, "Twin name cannot be empty");
        twins[_twinId].name = _newName;
        // A new metadata hash would typically be generated off-chain after this update
        // and then potentially set via fulfillTwinTraitUpdate or a dedicated oracle call.
        emit TwinNameUpdated(_twinId, _newName, block.timestamp);
    }

    /**
     * @dev Internal function to set the base URI.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // --- II. AI Oracle Interaction & Twin Evolution ---

    /**
     * @dev Initiates a request for the AI Oracle to update specific traits of a Twin.
     *      Requires payment for the oracle service.
     * @param _twinId The ID of the Twin to update.
     * @param _traitKeys The keys of the traits to potentially update (e.g., "intelligence").
     * @param _trainingDataHash A hash representing the off-chain training data provided by the user.
     */
    function requestTwinTraitUpdate(
        uint256 _twinId,
        string[] memory _traitKeys,
        bytes32 _trainingDataHash
    ) public payable onlyTwinOwner(_twinId) whenNotPaused nonReentrant {
        require(msg.value >= trainingCost, "Insufficient funds for AI oracle training service");
        aiOracleBalance += msg.value; // Funds held for the oracle

        // In a real system, this would trigger an off-chain oracle job.
        // The oracle would then call fulfillTwinTraitUpdate.
        emit TraitUpdateRequest(_twinId, _msgSender(), _trainingDataHash, block.timestamp);
    }

    /**
     * @dev Callable only by the designated AI Oracle. Validates and applies trait updates to a Twin.
     *      The `_oracleProof` would ideally be a verifiable proof of computation (e.g., ZK-SNARK hash)
     *      but is a placeholder here.
     * @param _twinId The ID of the Twin to update.
     * @param _traitKeys The keys of the traits being updated.
     * @param _traitValues The new values for the respective traits (can be positive or negative deltas).
     * @param _trainingDataHash The hash of the training data that led to this update.
     * @param _oracleProof A placeholder for a verifiable proof from the AI oracle.
     */
    function fulfillTwinTraitUpdate(
        uint256 _twinId,
        string[] memory _traitKeys,
        int256[] memory _traitValues,
        bytes32 _trainingDataHash, // For verification, ensure it matches request
        bytes32 _oracleProof // Placeholder for an actual oracle proof
    ) public onlyAIOracle whenNotPaused nonReentrant {
        require(_exists(_twinId), "Twin does not exist");
        require(_traitKeys.length == _traitValues.length, "Trait keys and values mismatch");

        Twin storage twin = twins[_twinId];

        // This is where oracle proof validation would happen in a more advanced system.
        // For this example, we trust the `onlyAIOracle` modifier.
        // For example: require(OracleSystem.verifyProof(_oracleProof, keccak256(abi.encodePacked(_twinId, _traitKeys, _traitValues, _trainingDataHash))), "Invalid oracle proof");

        for (uint256 i = 0; i < _traitKeys.length; i++) {
            bool found = false;
            for (uint256 j = 0; j < twin.traitKeys.length; j++) {
                if (keccak256(abi.encodePacked(twin.traitKeys[j])) == keccak256(abi.encodePacked(_traitKeys[i]))) {
                    twin.traits[_traitKeys[i]] += _traitValues[i];
                    found = true;
                    break;
                }
            }
            if (!found) { // If it's a new trait, add it
                twin.traits[_traitKeys[i]] = _traitValues[i];
                twin.traitKeys.push(_traitKeys[i]);
            }
        }
        twin.lastUpdated = block.timestamp;
        // A new metadata hash reflecting updated traits would be generated off-chain and set.
        twin.currentMetadataHash = keccak256(abi.encodePacked(twin.id, twin.name, twin.lastUpdated, _oracleProof));

        emit TraitUpdateFulfilled(_twinId, _oracleProof, block.timestamp);
    }

    /**
     * @dev Requests the AI Oracle to analyze a Twin's interaction history and provide a sentiment score.
     * @param _twinId The ID of the Twin for sentiment analysis.
     * @param _interactionHistoryHash A hash representing the off-chain interaction history data.
     */
    function requestTwinSentimentAnalysis(
        uint256 _twinId,
        bytes32 _interactionHistoryHash
    ) public onlyTwinOwner(_twinId) whenNotPaused nonReentrant {
        // This could also have a fee similar to trait updates.
        require(_exists(_twinId), "Twin does not exist");
        emit TwinSentimentAnalysisRequested(_twinId, _interactionHistoryHash, block.timestamp);
    }

    /**
     * @dev Only callable by the AI Oracle. Updates a Twin's sentiment score based on AI analysis.
     * @param _twinId The ID of the Twin.
     * @param _sentimentScore The new sentiment score (e.g., -100 to 100).
     * @param _oracleProof Placeholder for a verifiable proof from the AI oracle.
     */
    function fulfillTwinSentimentAnalysis(
        uint256 _twinId,
        int256 _sentimentScore,
        bytes32 _oracleProof
    ) public onlyAIOracle whenNotPaused nonReentrant {
        require(_exists(_twinId), "Twin does not exist");
        twins[_twinId].sentimentScore = _sentimentScore;
        twins[_twinId].lastUpdated = block.timestamp;
        twins[_twinId].currentMetadataHash = keccak256(abi.encodePacked(twins[_twinId].id, twins[_twinId].name, twins[_twinId].lastUpdated, _oracleProof));
        emit TwinSentimentAnalysisFulfilled(_twinId, _sentimentScore, _oracleProof, block.timestamp);
    }

    // --- III. Inter-Twin Dynamics & Collaboration ---

    /**
     * @dev An owner proposes an interaction between their Twin and another Twin.
     *      Requires payment for the AI oracle service to process the outcome.
     * @param _twin1Id The ID of the initiating Twin.
     * @param _twin2Id The ID of the target Twin.
     * @param _interactionContext A description or context for the interaction.
     */
    function initiateTwinInteraction(
        uint256 _twin1Id,
        uint256 _twin2Id,
        string memory _interactionContext
    ) public payable onlyTwinOwner(_twin1Id) whenNotPaused nonReentrant {
        require(_exists(_twin2Id), "Target Twin does not exist");
        require(_twin1Id != _twin2Id, "Cannot interact with itself");
        require(msg.value >= interactionCost, "Insufficient funds for AI oracle interaction service");

        _interactionIds.increment();
        uint256 newInteractionId = _interactionIds.current();

        interactions[newInteractionId] = TwinInteraction({
            twin1Id: _twin1Id,
            twin2Id: _twin2Id,
            initiator: _msgSender(),
            requestTime: block.timestamp,
            status: Status.Pending, // Awaiting acceptance from twin2 owner
            outcomeHash: bytes32(0)
        });

        aiOracleBalance += msg.value; // Hold funds for oracle outcome processing

        emit InteractionInitiated(newInteractionId, _twin1Id, _twin2Id, _msgSender(), _interactionContext);
    }

    /**
     * @dev The owner of the target Twin accepts the proposed interaction.
     * @param _interactionId The ID of the pending interaction.
     */
    function acceptTwinInteraction(uint256 _interactionId) public onlyPendingInteraction(_interactionId) whenNotPaused {
        TwinInteraction storage interaction = interactions[_interactionId];
        require(ownerOf(interaction.twin2Id) == _msgSender(), "Caller is not the owner of the target twin");

        interaction.status = Status.Active; // Now active, outcome can be requested.
        emit InteractionAccepted(_interactionId, interaction.twin1Id, interaction.twin2Id);
    }

    /**
     * @dev Requests the AI Oracle to determine the outcome of a completed interaction.
     *      Assumes interaction is processed off-chain after acceptance.
     * @param _interactionId The ID of the active interaction.
     */
    function requestInteractionOutcome(uint256 _interactionId) public onlyActiveInteraction(_interactionId) whenNotPaused {
        TwinInteraction storage interaction = interactions[_interactionId];
        // Only one of the participants can request the outcome.
        require(ownerOf(interaction.twin1Id) == _msgSender() || ownerOf(interaction.twin2Id) == _msgSender(), "Only participating twin owners can request outcome");

        // This would trigger an off-chain oracle job.
        emit InteractionOutcomeRequested(_interactionId);
    }

    /**
     * @dev Oracle function to fulfill interaction outcomes, updating traits for participating Twins.
     * @param _interactionId The ID of the interaction.
     * @param _targetTwinIds An array of Twin IDs whose traits are being updated (can be one or both).
     * @param _traitKeys The keys of the traits being updated.
     * @param _traitValues The new values for the respective traits (deltas).
     * @param _oracleProof Placeholder for a verifiable proof from the AI oracle.
     */
    function fulfillInteractionOutcome(
        uint256 _interactionId,
        uint256[] memory _targetTwinIds,
        string[] memory _traitKeys,
        int256[] memory _traitValues,
        bytes32 _oracleProof
    ) public onlyAIOracle whenNotPaused nonReentrant {
        TwinInteraction storage interaction = interactions[_interactionId];
        require(interaction.status == Status.Active, "Interaction not active for outcome fulfillment");
        require(_traitKeys.length == _traitValues.length, "Trait keys and values mismatch");

        // Update traits for each target twin
        for (uint256 twinIdx = 0; twinIdx < _targetTwinIds.length; twinIdx++) {
            uint256 currentTwinId = _targetTwinIds[twinIdx];
            require(currentTwinId == interaction.twin1Id || currentTwinId == interaction.twin2Id, "Twin not part of this interaction");
            Twin storage twin = twins[currentTwinId];

            for (uint256 i = 0; i < _traitKeys.length; i++) {
                bool found = false;
                for (uint256 j = 0; j < twin.traitKeys.length; j++) {
                    if (keccak256(abi.encodePacked(twin.traitKeys[j])) == keccak256(abi.encodePacked(_traitKeys[i]))) {
                        twin.traits[_traitKeys[i]] += _traitValues[i];
                        found = true;
                        break;
                    }
                }
                if (!found) { // If it's a new trait, add it
                    twin.traits[_traitKeys[i]] = _traitValues[i];
                    twin.traitKeys.push(_traitKeys[i]);
                }
            }
            twin.lastUpdated = block.timestamp;
            twin.currentMetadataHash = keccak256(abi.encodePacked(twin.id, twin.name, twin.lastUpdated, _oracleProof));
        }

        interaction.status = Status.Resolved;
        interaction.outcomeHash = _oracleProof; // Store the proof/hash for reference
        emit InteractionOutcomeFulfilled(_interactionId, _oracleProof);
    }

    /**
     * @dev Registers a new collaborative task with a reward pool and initial participants.
     *      Funds for the reward pool must be provided by the caller.
     * @param _taskDescription A description of the task.
     * @param _rewardPool The amount of ETH to be distributed as rewards.
     * @param _participantTwinIds An array of Twin IDs initially participating in the task.
     */
    function registerCollaborativeTask(
        string memory _taskDescription,
        uint256 _rewardPool,
        uint256[] memory _participantTwinIds
    ) public payable whenNotPaused nonReentrant {
        require(msg.value >= _rewardPool, "Insufficient funds for the reward pool");
        require(_participantTwinIds.length > 0, "At least one participant is required");
        require(bytes(_taskDescription).length > 0, "Task description cannot be empty");

        _taskIds.increment();
        uint256 newTaskId = _taskIds.current();

        CollaborativeTask storage newTask = tasks[newTaskId];
        newTask.id = newTaskId;
        newTask.description = _taskDescription;
        newTask.rewardPool = _rewardPool;
        newTask.creationTime = block.timestamp;
        newTask.status = Status.Active;

        for (uint256 i = 0; i < _participantTwinIds.length; i++) {
            uint256 twinId = _participantTwinIds[i];
            require(_exists(twinId), "Participant twin does not exist");
            newTask.participants[twinId] = true;
            newTask.participantTwinIds.push(twinId);
        }

        emit CollaborativeTaskRegistered(newTaskId, _taskDescription, _rewardPool, _msgSender());
    }

    /**
     * @dev A Twin's owner submits their contribution to a registered task.
     * @param _taskId The ID of the task.
     * @param _twinId The ID of the contributing Twin.
     * @param _contributionHash A hash representing the off-chain contribution data.
     */
    function submitTaskContribution(
        uint256 _taskId,
        uint256 _twinId,
        bytes32 _contributionHash
    ) public onlyActiveTask(_taskId) onlyTwinOwner(_twinId) onlyParticipatingTwin(_taskId, _twinId) whenNotPaused {
        tasks[_taskId].contributions[_twinId] = _contributionHash;
        emit TaskContributionSubmitted(_taskId, _twinId, _contributionHash);
    }

    /**
     * @dev Requests the AI Oracle to evaluate if a collaborative task has been successfully completed.
     *      Typically called after all participants have submitted contributions.
     * @param _taskId The ID of the task to evaluate.
     */
    function requestTaskCompletionEvaluation(uint256 _taskId) public onlyActiveTask(_taskId) whenNotPaused {
        // Only task creator or a designated admin can request evaluation
        // For simplicity, allowing any participant twin owner to request.
        bool isParticipantOwner = false;
        for(uint256 i = 0; i < tasks[_taskId].participantTwinIds.length; i++) {
            if (ownerOf(tasks[_taskId].participantTwinIds[i]) == _msgSender()) {
                isParticipantOwner = true;
                break;
            }
        }
        require(isParticipantOwner, "Only participant twin owners can request task evaluation.");

        // This would trigger an off-chain oracle job.
        emit TaskCompletionEvaluationRequested(_taskId);
    }

    /**
     * @dev Oracle function to finalize a task, marking it as successful or failed,
     *      and enabling reward claiming if successful.
     * @param _taskId The ID of the task.
     * @param _success True if the task was successful, false otherwise.
     * @param _oracleProof Placeholder for a verifiable proof from the AI oracle.
     */
    function fulfillTaskCompletionEvaluation(
        uint256 _taskId,
        bool _success,
        bytes32 _oracleProof
    ) public onlyAIOracle whenNotPaused nonReentrant {
        CollaborativeTask storage task = tasks[_taskId];
        require(task.status == Status.Active, "Task not active for completion evaluation");

        task.status = _success ? Status.Resolved : Status.Failed;
        task.outcomeHash = _oracleProof;

        emit TaskCompletionEvaluationFulfilled(_taskId, _success, _oracleProof);
    }

    /**
     * @dev Allows an owner of a participating Twin in a successful task to claim their share of the reward.
     * @param _taskId The ID of the task.
     */
    function claimTaskReward(uint256 _taskId) public onlyTwinOwner(tasks[_taskId].participantTwinIds[0]) whenNotPaused nonReentrant { // Simplified: only owner of first participant twin can claim
        CollaborativeTask storage task = tasks[_taskId];
        require(task.status == Status.Resolved, "Task is not resolved successfully");
        require(!task.claimedRewards[_msgSender()], "Reward already claimed by this address for this task"); // Check if owner already claimed

        uint256 numParticipants = task.participantTwinIds.length;
        require(numParticipants > 0, "No participants to claim reward.");

        uint256 individualReward = task.rewardPool / numParticipants;
        require(address(this).balance >= individualReward, "Contract balance too low for reward");

        // Distribute to the owner of each participant twin
        for(uint256 i = 0; i < numParticipants; i++) {
            address participantOwner = ownerOf(task.participantTwinIds[i]);
            if (!task.claimedRewards[task.participantTwinIds[i]]) { // Ensure each twin's reward is claimed once
                (bool sent, ) = payable(participantOwner).call{value: individualReward}("");
                require(sent, "Failed to send reward");
                task.claimedRewards[task.participantTwinIds[i]] = true; // Mark twin's reward as claimed
                emit TaskRewardClaimed(_taskId, task.participantTwinIds[i], participantOwner, individualReward);
            }
        }
    }


    // --- IV. Economic & Utility Functions ---

    /**
     * @dev Allows users to deposit ETH into the contract to cover fees for AI Oracle services.
     */
    function depositOracleServiceFees() public payable whenNotPaused {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        oracleFeeDeposits[_msgSender()] += msg.value;
        emit OracleFeeDeposited(_msgSender(), msg.value);
    }

    /**
     * @dev Allows the AI Oracle to withdraw accumulated fees for its services.
     * @param _recipient The address to send the withdrawn funds to.
     * @param _amount The amount to withdraw.
     */
    function withdrawOracleFees(address _recipient, uint256 _amount) public onlyAIOracle whenNotPaused nonReentrant {
        require(_recipient != address(0), "Recipient address cannot be zero");
        require(_amount > 0, "Withdrawal amount must be greater than zero");
        require(aiOracleBalance >= _amount, "Insufficient oracle balance");

        aiOracleBalance -= _amount;
        (bool sent, ) = payable(_recipient).call{value: _amount}("");
        require(sent, "Failed to send withdrawal funds");
        emit OracleFeesWithdrawn(_recipient, _amount);
    }

    /**
     * @dev Owner function to adjust the cost of initiating inter-twin interactions.
     * @param _newCost The new cost in wei.
     */
    function setInteractionCost(uint256 _newCost) public onlyOwner {
        require(_newCost >= 0, "Cost cannot be negative");
        interactionCost = _newCost;
        emit InteractionCostUpdated(_newCost);
    }

    /**
     * @dev Owner function to adjust the cost of requesting trait updates.
     * @param _newCost The new cost in wei.
     */
    function setTrainingCost(uint256 _newCost) public onlyOwner {
        require(_newCost >= 0, "Cost cannot be negative");
        trainingCost = _newCost;
        emit TrainingCostUpdated(_newCost);
    }

    // --- V. Admin & Governance ---

    /**
     * @dev Owner function to update the trusted AI Oracle address.
     * @param _newOracle The address of the new AI Oracle.
     */
    function setAIOracleAddress(address _newOracle) public onlyOwner {
        require(_newOracle != address(0), "New AI Oracle address cannot be zero");
        address oldOracle = _aiOracleAddress;
        _aiOracleAddress = _newOracle;
        emit AIOracleAddressUpdated(oldOracle, _newOracle);
    }

    /**
     * @dev Allows a Twin owner to propose a network-wide evolution policy.
     * @param _policyDescription A description of the proposed policy.
     * @param _policyHash A hash of the detailed policy document (e.g., IPFS hash).
     * @param _votingDuration The duration in seconds for which the policy will be open for voting.
     */
    function proposeEvolutionPolicy(
        string memory _policyDescription,
        bytes32 _policyHash,
        uint256 _votingDuration
    ) public whenNotPaused {
        require(bytes(_policyDescription).length > 0, "Policy description cannot be empty");
        require(_policyHash != bytes32(0), "Policy hash cannot be empty");
        require(_votingDuration > 0, "Voting duration must be positive");

        _policyIds.increment();
        uint256 newPolicyId = _policyIds.current();

        policies[newPolicyId] = EvolutionPolicy({
            id: newPolicyId,
            proposer: _msgSender(),
            description: _policyDescription,
            policyHash: _policyHash,
            votingDeadline: block.timestamp + _votingDuration,
            votesFor: 0,
            votesAgainst: 0,
            executed: false
        });

        emit EvolutionPolicyProposed(newPolicyId, _msgSender(), _policyDescription, policies[newPolicyId].votingDeadline);
    }

    /**
     * @dev Allows Twin owners to vote on an active evolution policy proposal.
     *      Each unique Twin owner can vote once per policy.
     * @param _policyId The ID of the policy to vote on.
     * @param _support True for a 'for' vote, false for an 'against' vote.
     */
    function voteOnEvolutionPolicy(uint256 _policyId, bool _support) public whenNotPaused {
        EvolutionPolicy storage policy = policies[_policyId];
        require(policy.proposer != address(0), "Policy does not exist");
        require(block.timestamp < policy.votingDeadline, "Voting period has ended");
        require(!policy.executed, "Policy already executed");
        require(!policyVoters[_policyId][_msgSender()], "Already voted on this policy");

        policyVoters[_policyId][_msgSender()] = true;

        if (_support) {
            policy.votesFor++;
        } else {
            policy.votesAgainst++;
        }

        emit PolicyVoted(_policyId, _msgSender(), _support);
    }

    /**
     * @dev Allows the contract owner to execute a policy that has passed its voting period
     *      and received sufficient votes.
     *      Simplified for this example: simply checks if votesFor > votesAgainst.
     *      In a real DAO, more complex quorum/thresholds would apply.
     * @param _policyId The ID of the policy to execute.
     */
    function executeEvolutionPolicy(uint256 _policyId) public onlyOwner whenNotPaused {
        EvolutionPolicy storage policy = policies[_policyId];
        require(policy.proposer != address(0), "Policy does not exist");
        require(block.timestamp >= policy.votingDeadline, "Voting period has not ended");
        require(!policy.executed, "Policy already executed");

        if (policy.votesFor > policy.votesAgainst) {
            // In a real system, this would involve parsing `policy.policyHash` off-chain
            // and applying the changes (e.g., updating contract parameters, deploying new logic).
            // For this example, we simply mark it as executed.
            policy.executed = true;
            emit PolicyExecuted(_policyId, true);
        } else {
            policy.executed = true; // Mark as executed even if failed to prevent re-execution attempts
            emit PolicyExecuted(_policyId, false);
        }
    }

    /**
     * @dev Pauses the contract. Only the owner can call this.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Only the owner can call this.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    // Fallback function to accept Ether
    receive() external payable {
        // Ether sent directly to the contract without a function call will be added to the oracleFeeDeposits
        // or can be used for general contract balance if not specifically for oracle fees.
        // For simplicity, we'll direct it to owner's oracleFeeDeposits as an example.
        oracleFeeDeposits[owner()] += msg.value; // Or just add to a general treasury
    }
}
```