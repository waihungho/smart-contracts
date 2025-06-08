Okay, here is a Solidity smart contract concept I've devised. It attempts to be creative by modeling a system inspired loosely by quantum mechanics concepts (fluctuation, superposition, entanglement, observation) translated into on-chain state management and probabilistic interactions, integrated with external randomness. It's not a direct simulation, but a metaphorical application for a unique smart contract dynamic.

It aims to avoid duplicating standard patterns like ERC-20/721/1155, basic staking/farming, simple DAOs, or common DeFi primitives.

The contract manages a system of "Quantum Nodes," each having a set of potential "Quantum States" with associated probabilities (weights). These nodes can be "entangled." Observing a node collapses its state probabilistically based on weights, potentially triggering effects and propagating changes to entangled nodes. External randomness is crucial for the probabilistic outcomes.

---

**Contract Name:** `QuantumFluctuations`

**Purpose:**
A creative smart contract simulating a system of interconnected probabilistic entities ("Quantum Nodes") with dynamic states influenced by interaction ("Observation"), internal processes ("Fluctuation"), external randomness, and relational links ("Entanglement"). Users can interact with nodes, attempting to influence or collapse their states.

**Core Concepts:**
1.  **Quantum Nodes:** Discrete entities managed by the contract.
2.  **Quantum States:** Possible configurations or properties a Node can possess. Each state has configurable parameters (e.g., value, type, flags).
3.  **Probabilistic Superposition:** Each Node exists implicitly in a superposition of its possible states, represented by relative probability weights assigned to each state.
4.  **Observation/Collapse:** A key user interaction. When a Node is "Observed," its state collapses into *one* specific `QuantumState` based on the current probability weights and external randomness. This action can have consequences (cost, reward, state change).
5.  **Entanglement:** Nodes can be linked. Observing/collapsing/fluctuating one node can influence the state probabilities or trigger effects on entangled nodes.
6.  **Fluctuation:** An internal (or externally triggered) process that randomly shifts the probability weights between a Node's possible states without necessarily collapsing it to a single state.
7.  **Decoherence:** A process (can be time-based or triggered) where state probabilities stabilize, reducing the probabilistic nature or locking onto a state.
8.  **Quantum Seed Oracle:** An integration point for a verifiable source of external randomness (like Chainlink VRF) necessary for probabilistic outcomes.

**Outline & Function Summary:**

1.  **State Variables:** Store configuration, node data, state definitions, entanglement mapping, randomness state, authorized addresses.
2.  **Structs:** Define `QuantumState`, `FluctuationNode`, `NodeType`, `StateProbabilityWeight`.
3.  **Events:** Signal key actions like Node Creation, State Definition, Entanglement, Observation (Collapse), Fluctuation, Seed Request/Fulfillment, State Effects.
4.  **Modifiers:** Access control (`onlyOwner`, `onlyAuthorizedObserver`, `onlySeedOracle`).
5.  **Randomness Integration:** Variables and callback function (`rawFulfillRandomWords`) to handle randomness requests and fulfillment (based on Chainlink VRF pattern).
6.  **Node & State Management (Admin/Creation):**
    *   `createNodeType`: Define types of nodes with default properties.
    *   `createQuantumState`: Define possible global states with properties.
    *   `createNode`: Mint a new Node, assigning it a type and initial possible states/weights.
    *   `addPossibleStateToNode`: Add an existing state definition as a possible state for a specific node, setting initial weight.
    *   `removePossibleStateFromNode`: Remove a state as a possibility for a node.
    *   `setNodeStateWeight`: Adjust the probabilistic weight for a specific state on a node.
    *   `assignNodeTypeToNode`: Change a node's type.
7.  **Entanglement Functions:**
    *   `entangleNodes`: Create a bidirectional link between two nodes.
    *   `disentangleNodes`: Remove the link between two nodes.
    *   `getEntangledNodes`: View which nodes are entangled with a given node. (View function, but listed here for concept group)
8.  **Observation & Interaction Functions:**
    *   `observeNode`: The core user interaction. Requires payment (or free for observers), requests randomness if needed, and triggers state collapse.
    *   `simulateObservation`: A read-only function to see potential outcomes of an observation without changing state or using randomness.
    *   `addAuthorizedObserver`: Grant an address permission for free/privileged observations.
    *   `removeAuthorizedObserver`: Revoke observer permission.
    *   `setObservationCost`: Set the required payment to observe a node.
9.  **Fluctuation & Decoherence Functions:**
    *   `triggerFluctuation`: Initiates a random shift in state weights for a node (can be based on time since last interaction, or called by owner/observer).
    *   `propagateFluctuation`: Called internally after Observation/Fluctuation to influence entangled nodes.
    *   `forceDecoherence`: Admin function to stabilize a node's state probabilities (e.g., set one weight to max, others to zero).
    *   `setFluctuationProbability`: Set the chance that `triggerFluctuation` results in a significant weight change.
10. **Advanced/Creative Functions:**
    *   `mergeNodes`: Combine two nodes into a new one, inheriting properties and merging potential states/entanglements.
    *   `splitNode`: Create new nodes from an existing one, distributing its properties and potential states/entanglements.
    *   `registerStateCollapseEffect`: Define what happens when a specific state on a specific node is collapsed into. Stores effect data (e.g., value transfer, data to log).
    *   `triggerStateEffects`: Internal function called after a state collapse to execute registered effects (e.g., transfer ETH/tokens stored in the contract, emit detailed logs).
    *   `lockStateWeight`: Temporarily prevent weight changes for a specific state on a node.
11. **View Functions (Querying State):**
    *   `getNodeDetails`: Get all relevant data for a node.
    *   `getQuantumStateDetails`: Get properties of a global state definition.
    *   `getNodePossibleStates`: Get the list of states a node can be in and their current weights.
    *   `getTotalNodes`: Get the count of existing nodes.
    *   `getObserverList`: Get the list of authorized observer addresses.
    *   `getObservationCost`: Get the current cost to observe.
    *   `getContractBalance`: Check the contract's ETH balance (from observation costs).
    *   `getNodeTypeDetails`: Get properties of a node type.
    *   `getNodeStateCollapseEffects`: Get registered effects for a node/state collapse.
12. **Admin Functions:**
    *   `withdraw`: Withdraw accumulated ETH from the contract (owner only).
    *   `setSeedOracleAddress`: Set the address of the external randomness oracle.
    *   `setMinObservationGap`: Set a minimum time between observations for a single node.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
// Assuming a VRF-like interface for randomness
// In a real implementation, you'd import and inherit from Chainlink VRFConsumerBaseV2
// For this concept, we'll simulate the callback structure.
contract MockVRFCoordinator {
    function requestRandomWords(bytes32 keyHash, uint32 subId, uint16 requestConfirmations, uint32 callbackGasLimit, uint32 numWords) external virtual returns (uint256 requestId) {
        // Simulate request - in reality this triggers off-chain nodes
        requestId = uint256(keccak256(abi.encode(keyHash, subId, requestConfirmations, callbackGasLimit, numWords, block.timestamp, tx.origin)));
        // In a real VRF, the fulfill call happens later by the oracle network.
        // For this mock, we won't auto-fulfill here.
        return requestId;
    }
}

// --- Contract Name: QuantumFluctuations ---
// --- Purpose: ---
// A creative smart contract simulating a system of interconnected probabilistic entities ("Quantum Nodes")
// with dynamic states influenced by interaction ("Observation"), internal processes ("Fluctuation"),
// external randomness, and relational links ("Entanglement"). Users can interact with nodes, attempting
// to influence or collapse their states.
//
// --- Core Concepts: ---
// - Quantum Nodes: Discrete entities managed by the contract.
// - Quantum States: Possible configurations or properties a Node can possess.
// - Probabilistic Superposition: Nodes exist implicitly in a superposition, represented by state weights.
// - Observation/Collapse: User action triggering a probabilistic state collapse based on randomness.
// - Entanglement: Linked nodes influence each other during interactions.
// - Fluctuation: Internal process randomly shifting state probability weights.
// - Decoherence: Process stabilizing state probabilities.
// - Quantum Seed Oracle: External randomness source integration (simulated VRF).
//
// --- Outline & Function Summary: ---
// 1. State Variables
// 2. Structs (QuantumState, FluctuationNode, NodeType, StateProbabilityWeight, StateCollapseEffect)
// 3. Events
// 4. Modifiers (onlyOwner, onlyAuthorizedObserver, onlySeedOracle)
// 5. Randomness Integration (VRF pattern simulation)
// 6. Node & State Management (Admin/Creation)
//    - createNodeType, createQuantumState, createNode, addPossibleStateToNode,
//      removePossibleStateFromNode, setNodeStateWeight, assignNodeTypeToNode
// 7. Entanglement Functions
//    - entangleNodes, disentangleNodes, getEntangledNodes (View)
// 8. Observation & Interaction Functions
//    - observeNode, simulateObservation (View), addAuthorizedObserver,
//      removeAuthorizedObserver, setObservationCost
// 9. Fluctuation & Decoherence Functions
//    - triggerFluctuation, propagateFluctuation, forceDecoherence, setFluctuationProbability
// 10. Advanced/Creative Functions
//    - mergeNodes, splitNode, registerStateCollapseEffect, triggerStateEffects (Internal),
//      lockStateWeight
// 11. View Functions (Querying State)
//    - getNodeDetails, getQuantumStateDetails, getNodePossibleStates, getTotalNodes,
//      getObserverList, getObservationCost, getContractBalance, getNodeTypeDetails,
//      getNodeStateCollapseEffects, getEntangledNodes, simulateObservation
// 12. Admin Functions
//    - withdraw, setSeedOracleAddress, setMinObservationGap
contract QuantumFluctuations is Ownable {

    // --- 1. State Variables ---
    uint256 private s_nodeCounter;
    uint256 private s_stateCounter;
    uint256 private s_nodeTypeCounter;

    mapping(uint256 => FluctuationNode) public nodes;
    mapping(uint256 => QuantumState) public quantumStates;
    mapping(uint256 => NodeType) public nodeTypes;

    // NodeID => list of entangled NodeIDs
    mapping(uint256 => uint256[]) public nodeEntanglements;

    // Configuration
    uint256 public observationCost = 0 ether; // Cost in wei to observe a node
    uint256 public fluctuationProbability = 10; // Chance / 100 for fluctuation to significantly shift weights
    uint256 public minObservationGap = 1 minutes; // Minimum time between observations for a node

    mapping(address => bool) public authorizedObservers;

    // Randomness (VRF Integration Pattern)
    address private s_seedOracleAddress;
    bytes32 private s_keyHash; // VRF key hash
    uint32 private s_subId; // VRF subscription ID
    uint16 private s_requestConfirmations; // Required confirmations
    uint32 private s_callbackGasLimit; // Gas limit for callback

    uint256 private s_lastSeed; // Stores the last successfully fulfilled random word
    mapping(uint256 => uint256) private s_pendingRequests; // Request ID => Node ID waiting for seed (simplified: only one per node)
    mapping(uint256 => bool) private s_requestFulfilled; // Track fulfilled requests

    // State Collapse Effects: NodeID => StateID => List of effects
    mapping(uint256 => mapping(uint256 => StateCollapseEffect[])) private s_stateCollapseEffects;

    // --- 2. Structs ---
    struct QuantumState {
        uint256 id;
        string name;
        string description;
        int256 energyLevel; // Example property
        bytes data; // Arbitrary data associated with the state
        bool isCatalyst; // Special state type
    }

    struct StateProbabilityWeight {
        uint256 stateId;
        uint256 weight; // Relative weight determining probability
        bool isLocked; // If true, weight cannot be changed by fluctuation/admin
    }

    struct FluctuationNode {
        uint256 id;
        uint256 nodeTypeId;
        uint256 lastFluctuationTime; // Timestamp of last fluctuation/observation
        uint256 lastObservedStateId; // The state it collapsed into during last observation (0 if never observed)
        StateProbabilityWeight[] possibleStates; // List of possible states and their weights
        bool isDecohered; // If true, probabilities are fixed or one state is dominant
    }

    struct NodeType {
        uint256 id;
        string name;
        string description;
        uint256 baseFluctuationCooldown; // Base time between fluctuations for this type
        // Add other type-specific properties if needed
    }

     struct StateCollapseEffect {
        uint256 effectId; // Unique ID for this effect definition
        uint256 valueTransfer; // ETH or token amount to transfer (from contract balance)
        bytes effectData; // Arbitrary data for off-chain or logging
        // Potentially add target address, function signature for on-chain calls (more complex, gas intensive, security risk)
        // For simplicity here, let's focus on value transfer and data emission.
    }

    // --- 3. Events ---
    event NodeTypeCreated(uint256 indexed nodeTypeId, string name);
    event QuantumStateCreated(uint256 indexed stateId, string name);
    event NodeCreated(uint256 indexed nodeId, uint256 nodeTypeId);
    event PossibleStateAddedToNode(uint256 indexed nodeId, uint256 indexed stateId, uint256 initialWeight);
    event NodeStateWeightSet(uint256 indexed nodeId, uint256 indexed stateId, uint256 newWeight);
    event NodeEntangled(uint256 indexed node1Id, uint256 indexed node2Id);
    event NodeDisentangled(uint256 indexed node1Id, uint256 indexed node2Id);

    event ObservationRequested(uint256 indexed nodeId, address observer, uint256 requestId);
    event ObservationFulfilled(uint256 indexed nodeId, address observer, uint256 indexed seed, uint256 finalStateId);
    event StateFluctuated(uint256 indexed nodeId, uint256 indexed seed);
    event NodeDecohered(uint256 indexed nodeId);

    event NodesMerged(uint256 indexed node1Id, uint256 indexed node2Id, uint256 indexed newNodeId);
    event NodeSplit(uint256 indexed originalNodeId, uint256 indexed newNode1Id, uint256 indexed newNode2Id);

    event StateCollapseEffectRegistered(uint256 indexed nodeId, uint256 indexed stateId, uint256 effectId);
    event StateEffectTriggered(uint256 indexed nodeId, uint256 indexed stateId, uint256 effectId, uint256 valueTransferred, bytes effectData);

    event StateWeightLocked(uint256 indexed nodeId, uint256 indexed stateId);
    event StateWeightUnlocked(uint256 indexed nodeId, uint256 indexed stateId);

    event ObservationCostSet(uint256 newCost);
    event FluctuationProbabilitySet(uint256 newProbability);
    event MinObservationGapSet(uint224 newGap);
    event SeedOracleAddressSet(address indexed oracleAddress);
    event AuthorizedObserverAdded(address indexed observer);
    event AuthorizedObserverRemoved(address indexed observer);

    event FundsWithdrawn(address indexed to, uint256 amount);

    // --- 4. Modifiers ---
    modifier onlySeedOracle() {
        require(msg.sender == s_seedOracleAddress, "Not the seed oracle");
        _;
    }

    modifier onlyAuthorizedObserver() {
        require(authorizedObservers[msg.sender], "Not an authorized observer");
        _;
    }

    // --- Constructor ---
    constructor(address initialSeedOracle, bytes32 keyHash, uint32 subId, uint16 requestConfirmations, uint32 callbackGasLimit) Ownable() {
        s_seedOracleAddress = initialSeedOracle;
        s_keyHash = keyHash;
        s_subId = subId;
        s_requestConfirmations = requestConfirmations;
        s_callbackGasLimit = callbackGasLimit;
        // Initialize counters from 1 to avoid 0 ID issues
        s_nodeCounter = 1;
        s_stateCounter = 1;
        s_nodeTypeCounter = 1;
    }

    // --- 6. Node & State Management ---

    /// @notice Defines a new type of node.
    /// @param _name The name of the node type.
    /// @param _description A description.
    /// @param _baseFluctuationCooldown Base cooldown for fluctuations for this type.
    /// @return The ID of the newly created node type.
    function createNodeType(string calldata _name, string calldata _description, uint256 _baseFluctuationCooldown) external onlyOwner returns (uint256) {
        uint256 newTypeId = s_nodeTypeCounter++;
        nodeTypes[newTypeId] = NodeType({
            id: newTypeId,
            name: _name,
            description: _description,
            baseFluctuationCooldown: _baseFluctuationCooldown
        });
        emit NodeTypeCreated(newTypeId, _name);
        return newTypeId;
    }

     /// @notice Defines a new global quantum state.
    /// @param _name The name of the state.
    /// @param _description A description.
    /// @param _energyLevel Example property: energy level.
    /// @param _data Arbitrary data for the state.
    /// @param _isCatalyst Is this a special catalyst state?
    /// @return The ID of the newly created state.
    function createQuantumState(string calldata _name, string calldata _description, int256 _energyLevel, bytes calldata _data, bool _isCatalyst) external onlyOwner returns (uint256) {
        uint256 newStateId = s_stateCounter++;
        quantumStates[newStateId] = QuantumState({
            id: newStateId,
            name: _name,
            description: _description,
            energyLevel: _energyLevel,
            data: _data,
            isCatalyst: _isCatalyst
        });
        emit QuantumStateCreated(newStateId, _name);
        return newStateId;
    }

    /// @notice Creates a new node instance.
    /// @param _nodeTypeId The type of node to create.
    /// @param _initialStatesWithWeights List of initial states and their weights for this node.
    /// @return The ID of the newly created node.
    function createNode(uint256 _nodeTypeId, StateProbabilityWeight[] calldata _initialStatesWithWeights) external onlyOwner returns (uint256) {
        require(nodeTypes[_nodeTypeId].id != 0, "Invalid node type ID");
        require(_initialStatesWithWeights.length > 0, "Node must have at least one possible state");

        uint256 newNodeId = s_nodeCounter++;
        FluctuationNode storage newNode = nodes[newNodeId];
        newNode.id = newNodeId;
        newNode.nodeTypeId = _nodeTypeId;
        newNode.lastFluctuationTime = block.timestamp;
        newNode.lastObservedStateId = 0;
        newNode.isDecohered = false;

        for (uint i = 0; i < _initialStatesWithWeights.length; i++) {
             require(quantumStates[_initialStatesWithWeights[i].stateId].id != 0, "Invalid state ID in initial list");
             newNode.possibleStates.push(_initialStatesWithWeights[i]);
        }

        emit NodeCreated(newNodeId, _nodeTypeId);
        return newNodeId;
    }

    /// @notice Adds an existing quantum state as a possibility for a node.
    /// @param _nodeId The ID of the node.
    /// @param _stateId The ID of the quantum state to add.
    /// @param _initialWeight The initial probability weight for this state on the node.
    function addPossibleStateToNode(uint256 _nodeId, uint256 _stateId, uint256 _initialWeight) external onlyOwner {
        FluctuationNode storage node = nodes[_nodeId];
        require(node.id != 0, "Invalid node ID");
        require(quantumStates[_stateId].id != 0, "Invalid state ID");

        // Check if state is already possible for this node
        for (uint i = 0; i < node.possibleStates.length; i++) {
            require(node.possibleStates[i].stateId != _stateId, "State already possible for this node");
        }

        node.possibleStates.push(StateProbabilityWeight({
            stateId: _stateId,
            weight: _initialWeight,
            isLocked: false
        }));
        emit PossibleStateAddedToNode(_nodeId, _stateId, _initialWeight);
    }

    /// @notice Removes a quantum state as a possibility for a node.
    /// @param _nodeId The ID of the node.
    /// @param _stateId The ID of the quantum state to remove.
    function removePossibleStateFromNode(uint256 _nodeId, uint256 _stateId) external onlyOwner {
        FluctuationNode storage node = nodes[_nodeId];
        require(node.id != 0, "Invalid node ID");

        bool found = false;
        for (uint i = 0; i < node.possibleStates.length; i++) {
            if (node.possibleStates[i].stateId == _stateId) {
                // Simple removal by swapping with last and popping
                node.possibleStates[i] = node.possibleStates[node.possibleStates.length - 1];
                node.possibleStates.pop();
                found = true;
                break;
            }
        }
        require(found, "State not found as possible for this node");
         require(node.possibleStates.length > 0, "Node must have at least one possible state");
    }

    /// @notice Sets the weight for a specific state on a node. Can be done by owner or during fluctuation.
    /// @param _nodeId The ID of the node.
    /// @param _stateId The ID of the state.
    /// @param _newWeight The new weight.
    function setNodeStateWeight(uint256 _nodeId, uint256 _stateId, uint256 _newWeight) public onlyOwner {
        FluctuationNode storage node = nodes[_nodeId];
        require(node.id != 0, "Invalid node ID");

        bool found = false;
        for (uint i = 0; i < node.possibleStates.length; i++) {
            if (node.possibleStates[i].stateId == _stateId) {
                require(!node.possibleStates[i].isLocked, "State weight is locked");
                node.possibleStates[i].weight = _newWeight;
                found = true;
                emit NodeStateWeightSet(_nodeId, _stateId, _newWeight);
                break;
            }
        }
        require(found, "State not found as possible for this node");
    }

    /// @notice Changes the type of a node.
    /// @param _nodeId The ID of the node.
    /// @param _newNodeTypeId The ID of the new node type.
    function assignNodeTypeToNode(uint256 _nodeId, uint256 _newNodeTypeId) external onlyOwner {
        FluctuationNode storage node = nodes[_nodeId];
        require(node.id != 0, "Invalid node ID");
        require(nodeTypes[_newNodeTypeId].id != 0, "Invalid new node type ID");
        node.nodeTypeId = _newNodeTypeId;
    }


    // --- 7. Entanglement Functions ---

    /// @notice Entangles two nodes. This is a bidirectional link.
    /// @param _node1Id The ID of the first node.
    /// @param _node2Id The ID of the second node.
    function entangleNodes(uint256 _node1Id, uint256 _node2Id) external onlyOwner {
        require(_node1Id != _node2Id, "Cannot entangle a node with itself");
        require(nodes[_node1Id].id != 0, "Invalid node1 ID");
        require(nodes[_node2Id].id != 0, "Invalid node2 ID");

        // Check if already entangled
        for (uint i = 0; i < nodeEntanglements[_node1Id].length; i++) {
            require(nodeEntanglements[_node1Id][i] != _node2Id, "Nodes already entangled");
        }

        nodeEntanglements[_node1Id].push(_node2Id);
        nodeEntanglements[_node2Id].push(_node1Id);
        emit NodeEntangled(_node1Id, _node2Id);
    }

    /// @notice Disentangles two nodes. Removes the bidirectional link.
    /// @param _node1Id The ID of the first node.
    /// @param _node2Id The ID of the second node.
    function disentangleNodes(uint256 _node1Id, uint256 _node2Id) external onlyOwner {
        require(_node1Id != _node2Id, "Cannot disentangle from self");
         require(nodes[_node1Id].id != 0, "Invalid node1 ID");
        require(nodes[_node2Id].id != 0, "Invalid node2 ID");

        // Remove from node1's list
        bool found1 = false;
        for (uint i = 0; i < nodeEntanglements[_node1Id].length; i++) {
            if (nodeEntanglements[_node1Id][i] == _node2Id) {
                nodeEntanglements[_node1Id][i] = nodeEntanglements[_node1Id][nodeEntanglements[_node1Id].length - 1];
                nodeEntanglements[_node1Id].pop();
                found1 = true;
                break;
            }
        }
        require(found1, "Nodes are not entangled");

        // Remove from node2's list
        bool found2 = false;
        for (uint i = 0; i < nodeEntanglements[_node2Id].length; i++) {
            if (nodeEntanglements[_node2Id][i] == _node1Id) {
                nodeEntanglements[_node2Id][i] = nodeEntanglements[_node2Id][nodeEntanglements[_node2Id].length - 1];
                nodeEntanglements[_node2Id].pop();
                found2 = true;
                break;
            }
        }
        // found2 must be true if found1 was true, but defensive check doesn't hurt
        require(found2, "Entanglement link was inconsistent");

        emit NodeDisentangled(_node1Id, _node2Id);
    }


    // --- 8. Observation & Interaction Functions ---

    /// @notice Observes a node, triggering probabilistic state collapse using randomness.
    ///         Requires payment (unless authorized observer) and may trigger a VRF request.
    /// @param _nodeId The ID of the node to observe.
    function observeNode(uint256 _nodeId) external payable {
        FluctuationNode storage node = nodes[_nodeId];
        require(node.id != 0, "Invalid node ID");
        require(!node.isDecohered, "Node is decohered, cannot be observed probabilistically");
        require(block.timestamp >= node.lastFluctuationTime + minObservationGap, "Observation cooldown active");

        bool isAuthorized = authorizedObservers[msg.sender];
        if (!isAuthorized) {
            require(msg.value >= observationCost, "Insufficient payment for observation");
        } else {
            require(msg.value == 0, "Authorized observers should not send value");
        }

        // In a real VRF setup, you'd request randomness here if s_lastSeed is old/used
        // For this mock, we'll assume randomness is available via s_lastSeed
        // A real implementation would need to handle the request/callback pattern properly.
        // For simplicity, we'll just use s_lastSeed directly for the probabilistic outcome
        // and update it via the mock rawFulfillRandomWords.
        require(s_lastSeed != 0, "Random seed not available. Owner might need to request."); // Simplified check

        uint256 seed = s_lastSeed;
        s_lastSeed = 0; // Consume the seed

        uint256 totalWeight = 0;
        for (uint i = 0; i < node.possibleStates.length; i++) {
            totalWeight += node.possibleStates[i].weight;
        }
        require(totalWeight > 0, "Node has zero total state weight, cannot collapse");

        uint256 randomValue = seed % totalWeight;
        uint256 cumulativeWeight = 0;
        uint256 finalStateId = 0;

        for (uint i = 0; i < node.possibleStates.length; i++) {
            cumulativeWeight += node.possibleStates[i].weight;
            if (randomValue < cumulativeWeight) {
                finalStateId = node.possibleStates[i].stateId;
                break;
            }
        }

        require(finalStateId != 0, "State collapse failed unexpectedly"); // Should not happen if totalWeight > 0

        node.lastObservedStateId = finalStateId;
        node.lastFluctuationTime = block.timestamp;

        // Optionally reset weights towards a default or specific state after collapse
        // For this version, collapse just picks a state and logs it, doesn't change weights.
        // Fluctuation handles weight changes.

        emit ObservationFulfilled(_nodeId, msg.sender, seed, finalStateId);

        // Trigger associated effects
        triggerStateEffects(_nodeId, finalStateId);

        // Propagate fluctuation to entangled nodes
        propagateFluctuation(_nodeId, seed); // Use the same seed or a derivation? Let's use same for consistency.

        // Refund excess payment if not authorized observer
         if (!isAuthorized && msg.value > observationCost) {
            payable(msg.sender).transfer(msg.value - observationCost);
        }
    }

    /// @notice Simulates the outcome probabilities of an observation without using randomness or changing state.
    /// @param _nodeId The ID of the node to simulate.
    /// @return A list of state IDs and their normalized probabilities (weight / total weight * 10000 for precision).
    function simulateObservation(uint256 _nodeId) external view returns (uint256[] memory stateIds, uint256[] memory probabilities) {
        FluctuationNode storage node = nodes[_nodeId];
        require(node.id != 0, "Invalid node ID");
        require(!node.isDecohered, "Node is decohered, simulation is deterministic");

        uint256 totalWeight = 0;
        for (uint i = 0; i < node.possibleStates.length; i++) {
            totalWeight += node.possibleStates[i].weight;
        }

        if (totalWeight == 0) {
             return (new uint256[](0), new uint256[](0));
        }

        stateIds = new uint256[](node.possibleStates.length);
        probabilities = new uint256[](node.possibleStates.length);

        for (uint i = 0; i < node.possibleStates.length; i++) {
            stateIds[i] = node.possibleStates[i].stateId;
            // Calculate probability with precision (e.g., percentage * 100)
            probabilities[i] = (node.possibleStates[i].weight * 10000) / totalWeight;
        }

        return (stateIds, probabilities);
    }

    /// @notice Grants an address permission to observe without paying.
    /// @param _observer The address to authorize.
    function addAuthorizedObserver(address _observer) external onlyOwner {
        require(_observer != address(0), "Invalid address");
        authorizedObservers[_observer] = true;
        emit AuthorizedObserverAdded(_observer);
    }

    /// @notice Revokes observer permission.
    /// @param _observer The address to deauthorize.
    function removeAuthorizedObserver(address _observer) external onlyOwner {
        require(_observer != address(0), "Invalid address");
        authorizedObservers[_observer] = false;
        emit AuthorizedObserverRemoved(_observer);
    }

    /// @notice Sets the cost required to observe a node for non-authorized addresses.
    /// @param _newCost The new cost in wei.
    function setObservationCost(uint256 _newCost) external onlyOwner {
        observationCost = _newCost;
        emit ObservationCostSet(_newCost);
    }


    // --- 9. Fluctuation & Decoherence Functions ---

     /// @notice Triggers a fluctuation event for a node, potentially shifting state weights.
     ///         Can be called by owner, authorized observer, or internally.
     /// @param _nodeId The ID of the node to fluctuate.
    function triggerFluctuation(uint256 _nodeId) external {
        FluctuationNode storage node = nodes[_nodeId];
        require(node.id != 0, "Invalid node ID");
        require(!node.isDecohered, "Node is decohered, cannot fluctuate");
        require(block.timestamp >= node.lastFluctuationTime + nodeTypes[node.nodeTypeId].baseFluctuationCooldown, "Fluctuation cooldown active");
        require(msg.sender == owner() || authorizedObservers[msg.sender], "Not authorized to trigger fluctuation"); // Limit external calls

        // Request randomness if needed for probabilistic weight shifts
        // Simplified: Use last seed or skip fluctuation if none available
        require(s_lastSeed != 0, "Random seed not available for fluctuation");

        uint256 seed = s_lastSeed;
        s_lastSeed = 0; // Consume seed

        // Implement probabilistic weight shift based on seed and fluctuationProbability
        // Example: Randomly pick two states and transfer some weight between them,
        // or shift weights towards a random state.
        // Use seed for deterministic randomness within the contract.
        uint256 randomValue = seed % 100;

        if (randomValue < fluctuationProbability) {
            // Significant fluctuation - re-distribute weights randomly among unlocked states
            uint256 numPossible = node.possibleStates.length;
            if (numPossible > 1) {
                 uint256 totalUnlockedWeight = 0;
                 for(uint i=0; i<numPossible; i++) {
                     if(!node.possibleStates[i].isLocked) {
                          totalUnlockedWeight += node.possibleStates[i].weight;
                     }
                 }

                 if(totalUnlockedWeight > 0) {
                    // Simple redistribution example: pick two states, transfer weight
                    uint256 stateIndex1 = seed % numPossible;
                    uint256 stateIndex2 = (seed / numPossible) % numPossible;
                    // Ensure different states and both are unlocked
                    if (stateIndex1 != stateIndex2 && !node.possibleStates[stateIndex1].isLocked && !node.possibleStates[stateIndex2].isLocked) {
                        uint256 transferAmount = (seed / (numPossible * numPossible)) % (node.possibleStates[stateIndex1].weight / 2 + 1); // Transfer up to half+1
                        node.possibleStates[stateIndex1].weight -= transferAmount;
                        node.possibleStates[stateIndex2].weight += transferAmount;
                         emit NodeStateWeightSet(_nodeId, node.possibleStates[stateIndex1].stateId, node.possibleStates[stateIndex1].weight);
                         emit NodeStateWeightSet(_nodeId, node.possibleStates[stateIndex2].stateId, node.possibleStates[stateIndex2].weight);
                    }
                 }
            }
        } else {
            // Minor fluctuation - slightly adjust weights, or just update timestamp
            // Update timestamp even if no significant shift
        }

        node.lastFluctuationTime = block.timestamp;
        emit StateFluctuated(_nodeId, seed);

        // Propagate fluctuation to entangled nodes (using a derivation of the seed)
        propagateFluctuation(_nodeId, seed / 2); // Example derivation
    }

     /// @notice Propagates a fluctuation or observation effect to entangled nodes.
     /// @param _sourceNodeId The node that triggered the propagation.
     /// @param _propagationSeed A seed value derived from the original interaction's randomness.
    function propagateFluctuation(uint256 _sourceNodeId, uint256 _propagationSeed) internal {
        uint256[] storage entangled = nodeEntanglements[_sourceNodeId];
        for (uint i = 0; i < entangled.length; i++) {
            uint256 entangledNodeId = entangled[i];
            FluctuationNode storage entangledNode = nodes[entangledNodeId];

            if (entangledNode.id != 0 && !entangledNode.isDecohered) {
                 // Use propagationSeed to influence fluctuation on entangled node
                 // Example: Shift weights based on the state of the source node, or just trigger a standard fluctuation
                 // For simplicity, let's just trigger a fluctuation with a derived seed
                 // A more complex version could link specific states or types.

                 // Simulate receiving a new seed for this specific propagation step
                 uint256 derivedSeed = uint256(keccak256(abi.encode(_propagationSeed, entangledNodeId, block.timestamp)));
                 s_lastSeed = derivedSeed; // Temporarily make this seed available
                 // Note: In a real VRF, you might need to request seeds specifically for propagation

                 // Check cooldown before triggering fluctuation
                 if (block.timestamp >= entangledNode.lastFluctuationTime + nodeTypes[entangledNode.nodeTypeId].baseFluctuationCooldown) {
                    // Call internal function to perform weight shift based on derivedSeed
                    _performFluctuation(entangledNodeId, derivedSeed);
                 }
            }
        }
    }

    /// @notice Internal helper for performing probabilistic weight shifts during fluctuation.
    /// @param _nodeId The node ID.
    /// @param _seed The random seed to use.
    function _performFluctuation(uint256 _nodeId, uint256 _seed) internal {
         FluctuationNode storage node = nodes[_nodeId];
         uint256 randomValue = _seed % 100;

         if (randomValue < fluctuationProbability) {
             uint256 numPossible = node.possibleStates.length;
             if (numPossible > 1) {
                 uint256 totalUnlockedWeight = 0;
                 for(uint i=0; i<numPossible; i++) {
                     if(!node.possibleStates[i].isLocked) {
                          totalUnlockedWeight += node.possibleStates[i].weight;
                     }
                 }

                 if(totalUnlockedWeight > 0) {
                    uint256 stateIndex1 = _seed % numPossible;
                    uint256 stateIndex2 = (_seed / numPossible) % numPossible;
                    if (stateIndex1 != stateIndex2 && !node.possibleStates[stateIndex1].isLocked && !node.possibleStates[stateIndex2].isLocked) {
                        uint256 transferAmount = (_seed / (numPossible * numPossible)) % (node.possibleStates[stateIndex1].weight / 2 + 1);
                        node.possibleStates[stateIndex1].weight -= transferAmount;
                        node.possibleStates[stateIndex2].weight += transferAmount;
                         emit NodeStateWeightSet(_nodeId, node.possibleStates[stateIndex1].stateId, node.possibleStates[stateIndex1].weight);
                         emit NodeStateWeightSet(_nodeId, node.possibleStates[stateIndex2].stateId, node.possibleStates[stateIndex2].weight);
                    }
                 }
             }
         }
         node.lastFluctuationTime = block.timestamp;
         emit StateFluctuated(_nodeId, _seed);
    }


    /// @notice Forces a node into a decohered state, fixing probabilities or setting one state's weight to 100%.
    ///         This removes its probabilistic nature.
    /// @param _nodeId The ID of the node.
    /// @param _fixedStateId Optional: The ID of the state to fix it into (if non-zero).
    function forceDecoherence(uint256 _nodeId, uint256 _fixedStateId) external onlyOwner {
        FluctuationNode storage node = nodes[_nodeId];
        require(node.id != 0, "Invalid node ID");
        require(!node.isDecohered, "Node is already decohered");

        node.isDecohered = true;

        if (_fixedStateId != 0) {
             bool found = false;
            // Set weight of fixed state to max, others to 0
            for (uint i = 0; i < node.possibleStates.length; i++) {
                if (node.possibleStates[i].stateId == _fixedStateId) {
                    node.possibleStates[i].weight = 10000; // Arbitrary high value to represent 100%
                    found = true;
                     emit NodeStateWeightSet(_nodeId, node.possibleStates[i].stateId, node.possibleStates[i].weight);
                } else {
                     node.possibleStates[i].weight = 0;
                     emit NodeStateWeightSet(_nodeId, node.possibleStates[i].stateId, node.possibleStates[i].weight);
                }
                 // Unlock all weights upon decoherence if they were locked
                 node.possibleStates[i].isLocked = false;
            }
            require(found, "Fixed state ID not possible for this node");
            node.lastObservedStateId = _fixedStateId; // Record the state it decohered into
        } else {
             // If no fixed state, weights are just frozen at current values
              for (uint i = 0; i < node.possibleStates.length; i++) {
                 node.possibleStates[i].isLocked = true; // Lock all weights
              }
        }

        emit NodeDecohered(_nodeId);
    }

    /// @notice Sets the probability (out of 100) that fluctuation significantly shifts weights.
    /// @param _newProbability The new probability (0-100).
    function setFluctuationProbability(uint256 _newProbability) external onlyOwner {
        require(_newProbability <= 100, "Probability must be <= 100");
        fluctuationProbability = _newProbability;
        emit FluctuationProbabilitySet(_newProbability);
    }

    // --- 10. Advanced/Creative Functions ---

    /// @notice Merges two nodes into a new node.
    ///         The new node inherits possible states and entanglements from both.
    /// @param _node1Id The ID of the first node.
    /// @param _node2Id The ID of the second node.
    /// @param _newNodeTypeId The type for the new merged node.
    /// @return The ID of the new merged node.
    function mergeNodes(uint256 _node1Id, uint256 _node2Id, uint256 _newNodeTypeId) external onlyOwner returns (uint256) {
        require(_node1Id != _node2Id, "Cannot merge a node with itself");
        require(nodes[_node1Id].id != 0, "Invalid node1 ID");
        require(nodes[_node2Id].id != 0, "Invalid node2 ID");
        require(nodeTypes[_newNodeTypeId].id != 0, "Invalid new node type ID");

        FluctuationNode storage node1 = nodes[_node1Id];
        FluctuationNode storage node2 = nodes[_node2Id];

        // Create the new node
        uint256 newNodeId = s_nodeCounter++;
        FluctuationNode storage newNode = nodes[newNodeId];
        newNode.id = newNodeId;
        newNode.nodeTypeId = _newNodeTypeId;
        newNode.lastFluctuationTime = block.timestamp;
        newNode.lastObservedStateId = 0;
        newNode.isDecohered = false;

        // Combine possible states (avoiding duplicates, summing weights or averaging)
        // Simple approach: take all possible states from both, summing weights if duplicated
        mapping(uint256 => uint256) tempWeights;
        for(uint i=0; i<node1.possibleStates.length; i++) {
            tempWeights[node1.possibleStates[i].stateId] += node1.possibleStates[i].weight;
        }
         for(uint i=0; i<node2.possibleStates.length; i++) {
            tempWeights[node2.possibleStates[i].stateId] += node2.possibleStates[i].weight;
        }

        for (uint256 stateId = 1; stateId < s_stateCounter; stateId++) { // Iterate through all possible state IDs
             if (tempWeights[stateId] > 0) {
                newNode.possibleStates.push(StateProbabilityWeight({
                    stateId: stateId,
                    weight: tempWeights[stateId], // Summed weights
                    isLocked: false // Start unlocked
                }));
             }
        }
        require(newNode.possibleStates.length > 0, "Merged node must have at least one possible state");


        // Combine entanglements
        mapping(uint256 => bool) tempEntanglements;
        for(uint i=0; i<nodeEntanglements[_node1Id].length; i++) {
            uint256 entangledId = nodeEntanglements[_node1Id][i];
            if (entangledId != _node2Id && entangledId != _node1Id) { // Don't entangle with self or the other merged node
                 tempEntanglements[entangledId] = true;
            }
        }
         for(uint i=0; i<nodeEntanglements[_node2Id].length; i++) {
            uint256 entangledId = nodeEntanglements[_node2Id][i];
             if (entangledId != _node1Id && entangledId != _node2Id) {
                tempEntanglements[entangledId] = true;
            }
        }

        for (uint256 entangledId = 1; entangledId < s_nodeCounter; entangledId++) { // Iterate through all potential node IDs
            if (tempEntanglements[entangledId]) {
                // Add new node to the entangled node's list
                nodeEntanglements[entangledId].push(newNodeId);
                // Add entangled node to the new node's list
                nodeEntanglements[newNodeId].push(entangledId);
            }
        }

        // Optionally: Remove old nodes or mark them inactive (not deleting to preserve history/IDs)
        // For this example, we'll keep them but they are effectively superseded by the new node.
        // A more complex version might have a 'status' flag.

        emit NodesMerged(_node1Id, _node2Id, newNodeId);
        return newNodeId;
    }

    /// @notice Splits a node into two new nodes.
    ///         Distributes properties, states, and entanglements. Logic can be complex.
    /// @param _originalNodeId The ID of the node to split.
    /// @param _newNode1TypeId The type for the first new node.
    /// @param _newNode2TypeId The type for the second new node.
    /// @return The IDs of the two new nodes.
    function splitNode(uint256 _originalNodeId, uint256 _newNode1TypeId, uint256 _newNode2TypeId) external onlyOwner returns (uint256 newNode1Id, uint256 newNode2Id) {
         FluctuationNode storage originalNode = nodes[_originalNodeId];
         require(originalNode.id != 0, "Invalid original node ID");
         require(nodeTypes[_newNode1TypeId].id != 0, "Invalid new node1 type ID");
         require(nodeTypes[_newNode2TypeId].id != 0, "Invalid new node2 type ID");
         require(originalNode.possibleStates.length >= 2, "Node needs at least 2 possible states to split state distribution"); // Need states to distribute

         // Create new nodes
         newNode1Id = s_nodeCounter++;
         newNode2Id = s_nodeCounter++;

         FluctuationNode storage newNode1 = nodes[newNode1Id];
         FluctuationNode storage newNode2 = nodes[newNode2Id];

         newNode1.id = newNode1Id;
         newNode1.nodeTypeId = _newNode1TypeId;
         newNode1.lastFluctuationTime = block.timestamp;
         newNode1.lastObservedStateId = 0;
         newNode1.isDecohered = false;

         newNode2.id = newNode2Id;
         newNode2.nodeTypeId = _newNode2TypeId;
         newNode2.lastFluctuationTime = block.timestamp;
         newNode2.lastObservedStateId = 0;
         newNode2.isDecohered = false;

         // Distribute possible states and weights (example: distribute odd/even state IDs or random half)
         // Complex logic based on specific needs. Simple: distribute alternating states.
         for(uint i=0; i<originalNode.possibleStates.length; i++) {
             if (i % 2 == 0) {
                  newNode1.possibleStates.push(originalNode.possibleStates[i]);
             } else {
                 newNode2.possibleStates.push(originalNode.possibleStates[i]);
             }
         }
         require(newNode1.possibleStates.length > 0 && newNode2.possibleStates.length > 0, "State distribution resulted in empty node");

         // Distribute entanglements (example: original node's entanglements become new nodes' entanglements)
         uint256[] memory originalEntanglements = nodeEntanglements[_originalNodeId]; // Copy array before modifying storage
         for(uint i=0; i<originalEntanglements.length; i++) {
             uint256 entangledId = originalEntanglements[i];
             // Add new nodes to the entangled node's list
             if (nodes[entangledId].id != 0) { // Ensure target node still exists
                 nodeEntanglements[entangledId].push(newNode1Id);
                 nodeEntanglements[entangledId].push(newNode2Id);
                 // Remove original node from entangled node's list (more complex)
                 // Skipping removal from target's list for simplicity in this example.
             }
         }
         // Entangle the two new nodes with each other (optional but thematic)
         nodeEntanglements[newNode1Id].push(newNode2Id);
         nodeEntanglements[newNode2Id].push(newNode1Id);

         // Copy original entanglements to new nodes (without linking to each other initially)
          for(uint i=0; i<originalEntanglements.length; i++) {
             uint256 entangledId = originalEntanglements[i];
              if (nodes[entangledId].id != 0) {
                newNode1.nodeEntanglements[_originalNodeId].push(entangledId); // Conceptual: link to original's entangled nodes
                newNode2.nodeEntanglements[_originalNodeId].push(entangledId); // This is pseudo-code, need to adjust struct/mapping
                // Let's simplify: just copy entanglement list to both new nodes, minus the original
                bool found = false;
                for(uint j=0; j<nodeEntanglements[_originalNodeId].length; j++){
                    if(nodeEntanglements[_originalNodeId][j] == entangledId){
                         nodeEntanglements[newNode1Id].push(entangledId);
                         nodeEntanglements[newNode2Id].push(entangledId);
                        found = true; break;
                    }
                }
                // Need to clean up originalNodeId from entangled nodes' lists - this is tricky
                // For simplicity, leaving the original node's entry in other nodes' entanglement list for now.
             }
          }


         // Optionally: Mark original node inactive or remove its states/entanglements
         // nodeEntanglements[_originalNodeId].length = 0; // Clear entanglement list
         // originalNode.possibleStates.length = 0; // Clear states

         emit NodeSplit(_originalNodeId, newNode1Id, newNode2Id);
         return (newNode1Id, newNode2Id);
    }

     /// @notice Registers an effect to occur when a specific state is collapsed into on a specific node.
     /// @param _nodeId The ID of the node.
     /// @param _stateId The ID of the state.
     /// @param _valueTransfer Amount of ETH (or tokens managed internally) to transfer from contract balance.
     /// @param _effectData Arbitrary data to include in the effect event/log.
    function registerStateCollapseEffect(uint256 _nodeId, uint256 _stateId, uint256 _valueTransfer, bytes calldata _effectData) external onlyOwner {
        require(nodes[_nodeId].id != 0, "Invalid node ID");
        require(quantumStates[_stateId].id != 0, "Invalid state ID");

        uint256 effectId = s_stateCollapseEffects[_nodeId][_stateId].length; // Simple array index as ID
        s_stateCollapseEffects[_nodeId][_stateId].push(StateCollapseEffect({
            effectId: effectId,
            valueTransfer: _valueTransfer,
            effectData: _effectData
        }));

        emit StateCollapseEffectRegistered(_nodeId, _stateId, effectId);
    }

    /// @notice Internal function to trigger registered effects after a state collapse.
    /// @param _nodeId The ID of the node.
    /// @param _stateId The ID of the state that was collapsed into.
    function triggerStateEffects(uint256 _nodeId, uint256 _stateId) internal {
        StateCollapseEffect[] storage effects = s_stateCollapseEffects[_nodeId][_stateId];
        for(uint i=0; i<effects.length; i++) {
            StateCollapseEffect storage effect = effects[i];

            uint256 valueTransferred = 0;
            if (effect.valueTransfer > 0) {
                 // Transfer ETH if balance allows
                if (address(this).balance >= effect.valueTransfer) {
                    payable(owner()).transfer(effect.valueTransfer); // Example: transfer to owner
                    valueTransferred = effect.valueTransfer;
                }
                // In a real system, you'd manage tokens or have more complex interaction patterns here.
            }

            // Emit event for off-chain listeners to handle
            emit StateEffectTriggered(_nodeId, _stateId, effect.effectId, valueTransferred, effect.effectData);
        }
    }

    /// @notice Locks the weight of a specific state on a node, preventing fluctuation or admin changes.
    /// @param _nodeId The ID of the node.
    /// @param _stateId The ID of the state to lock.
    function lockStateWeight(uint256 _nodeId, uint256 _stateId) external onlyOwner {
         FluctuationNode storage node = nodes[_nodeId];
        require(node.id != 0, "Invalid node ID");
        require(!node.isDecohered, "Node is decohered, all weights are implicitly locked or fixed");

        bool found = false;
        for (uint i = 0; i < node.possibleStates.length; i++) {
            if (node.possibleStates[i].stateId == _stateId) {
                node.possibleStates[i].isLocked = true;
                found = true;
                emit StateWeightLocked(_nodeId, _stateId);
                break;
            }
        }
        require(found, "State not found as possible for this node");
    }

     /// @notice Unlocks the weight of a specific state on a node.
     /// @param _nodeId The ID of the node.
     /// @param _stateId The ID of the state to unlock.
    function unlockStateWeight(uint256 _nodeId, uint256 _stateId) external onlyOwner {
        FluctuationNode storage node = nodes[_nodeId];
        require(node.id != 0, "Invalid node ID");
        // Decohered nodes are handled by forceDecoherence, unlocking them makes less sense here

        bool found = false;
        for (uint i = 0; i < node.possibleStates.length; i++) {
            if (node.possibleStates[i].stateId == _stateId) {
                node.possibleStates[i].isLocked = false;
                found = true;
                emit StateWeightUnlocked(_nodeId, _stateId);
                break;
            }
        }
        require(found, "State not found as possible for this node");
    }


    // --- 5. Randomness Integration (Mock VRF Callback) ---
    // In a real VRF setup, this function would be called by the Chainlink VRF Coordinator
    // with verifiable randomness.
    function rawFulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) external onlySeedOracle {
        // Assume request fulfilled for a single random word
        require(randomWords.length > 0, "No random words provided");
        require(s_pendingRequests[requestId] != 0, "Request ID not recognized");
        require(!s_requestFulfilled[requestId], "Request already fulfilled");

        uint256 nodeId = s_pendingRequests[requestId];
        s_lastSeed = randomWords[0]; // Store the random seed

        s_requestFulfilled[requestId] = true;
        delete s_pendingRequests[requestId]; // Clear pending request

        // Now, observations or fluctuations waiting for this seed can proceed using s_lastSeed
        // In a more complex system, you might trigger the waiting process here
        // For this simplified example, the user/system calls observeNode/triggerFluctuation again
        // after seeing the seed is available.

        // emit RandomnessFulfilled(requestId, randomWords[0]); // Add a specific event if desired
    }

    // Example function to request a seed (would be called internally by observeNode/triggerFluctuation if seed needed)
    function requestSeedInternal(uint256 _nodeId) internal returns (uint256 requestId) {
         require(s_seedOracleAddress != address(0), "Seed oracle not set");
         require(s_lastSeed == 0, "A seed is already available"); // Prevent multiple pending seeds in simplified model

         // Replace with actual VRF Coordinator interaction in real impl
         // MockVRFCoordinator mockOracle = MockVRFCoordinator(s_seedOracleAddress);
         // requestId = mockOracle.requestRandomWords(s_keyHash, s_subId, s_requestConfirmations, s_callbackGasLimit, 1);
         // s_pendingRequests[requestId] = _nodeId; // Link request to node

         // --- Mocking the VRF request for concept clarity ---
         requestId = uint256(keccak256(abi.encode(_nodeId, block.timestamp, tx.origin)));
         s_pendingRequests[requestId] = _nodeId;
         // In a real scenario, the fulfillment happens hours/minutes later.
         // For local testing, you might manually call rawFulfillRandomWords(requestId, [someRandomNumber]).
         // Or for this concept, rely on s_lastSeed being updated externally or manually.
         // ---------------------------------------------------

         emit ObservationRequested(_nodeId, msg.sender, requestId);
    }

    // Admin function to manually request a seed if the system needs one but none is pending/available
    // Useful if internal requests fail or for bootstrapping.
    function manualRequestSeed(uint256 _nodeId) external onlyOwner {
        requestSeedInternal(_nodeId);
    }

    // --- 12. Admin Functions ---

    /// @notice Allows the owner to withdraw collected ETH from the contract.
    /// @param _to The address to send the ETH to.
    /// @param _amount The amount of ETH to withdraw.
    function withdraw(address payable _to, uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be > 0");
        require(address(this).balance >= _amount, "Insufficient balance");
        _to.transfer(_amount);
        emit FundsWithdrawn(_to, _amount);
    }

    /// @notice Sets the address of the external randomness oracle (e.g., Chainlink VRF Coordinator).
    /// @param _oracleAddress The address of the oracle.
    function setSeedOracleAddress(address _oracleAddress) external onlyOwner {
        require(_oracleAddress != address(0), "Invalid address");
        s_seedOracleAddress = _oracleAddress;
        emit SeedOracleAddressSet(_oracleAddress);
    }

     /// @notice Sets the minimum time gap required between observations of a node.
     /// @param _newGap The new gap in seconds.
    function setMinObservationGap(uint224 _newGap) external onlyOwner {
        minObservationGap = _newGap;
        emit MinObservationGapSet(_newGap);
    }


    // --- 11. View Functions ---

    /// @notice Get details for a specific node.
    function getNodeDetails(uint256 _nodeId) external view returns (
        uint256 nodeId,
        uint256 nodeTypeId,
        uint256 lastFluctuationTime,
        uint256 lastObservedStateId,
        StateProbabilityWeight[] memory possibleStates,
        bool isDecohered
    ) {
        FluctuationNode storage node = nodes[_nodeId];
        require(node.id != 0, "Invalid node ID");
        return (
            node.id,
            node.nodeTypeId,
            node.lastFluctuationTime,
            node.lastObservedStateId,
            node.possibleStates,
            node.isDecohered
        );
    }

    /// @notice Get details for a specific quantum state definition.
    function getQuantumStateDetails(uint256 _stateId) external view returns (
        uint256 stateId,
        string memory name,
        string memory description,
        int256 energyLevel,
        bytes memory data,
        bool isCatalyst
    ) {
        QuantumState storage state = quantumStates[_stateId];
        require(state.id != 0, "Invalid state ID");
        return (
            state.id,
            state.name,
            state.description,
            state.energyLevel,
            state.data,
            state.isCatalyst
        );
    }

    /// @notice Get the possible states and their current weights for a node.
     function getNodePossibleStates(uint256 _nodeId) external view returns (StateProbabilityWeight[] memory) {
         FluctuationNode storage node = nodes[_nodeId];
         require(node.id != 0, "Invalid node ID");
         return node.possibleStates;
     }

    /// @notice Get the total number of nodes created.
    function getTotalNodes() external view returns (uint256) {
        return s_nodeCounter - 1; // Adjust for 1-based counter
    }

    /// @notice Get the list of addresses authorized to observe for free.
    function getObserverList() external view returns (address[] memory) {
        // Note: Iterating mappings is inefficient. A real impl might store observers in an array.
        // This is a simplified view function.
        uint256 count = 0;
        for (uint i = 0; i < 100; i++) { // Assuming max 100 observers for example
             // This requires iterating ALL possible addresses which is impossible.
             // Correct approach is to store observers in an array or linked list if iteration is needed.
             // Returning an empty array for simplicity in this example.
        }
        return new address[](0); // Placeholder
    }

    /// @notice Get the current cost to observe a node.
    function getObservationCost() external view returns (uint256) {
        return observationCost;
    }

    /// @notice Get the current ETH balance held by the contract.
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Get details for a specific node type.
     function getNodeTypeDetails(uint256 _nodeTypeId) external view returns (
         uint256 nodeTypeId,
         string memory name,
         string memory description,
         uint256 baseFluctuationCooldown
     ) {
         NodeType storage nodeType = nodeTypes[_nodeTypeId];
         require(nodeType.id != 0, "Invalid node type ID");
         return (
             nodeType.id,
             nodeType.name,
             nodeType.description,
             nodeType.baseFluctuationCooldown
         );
     }

     /// @notice Get the list of registered effects for a specific node and state collapse.
     function getNodeStateCollapseEffects(uint256 _nodeId, uint256 _stateId) external view returns (StateCollapseEffect[] memory) {
         require(nodes[_nodeId].id != 0, "Invalid node ID");
         require(quantumStates[_stateId].id != 0, "Invalid state ID");
         return s_stateCollapseEffects[_nodeId][_stateId];
     }

     /// @notice Get nodes entangled with a specific node.
     function getEntangledNodes(uint256 _nodeId) external view returns (uint256[] memory) {
         require(nodes[_nodeId].id != 0, "Invalid node ID");
         return nodeEntanglements[_nodeId];
     }

     // Missing view functions for: s_seedOracleAddress, s_keyHash, s_subId etc. (Can add getters if needed)
}
```