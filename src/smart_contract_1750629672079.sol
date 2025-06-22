Okay, let's design a smart contract around a concept that is not commonly found in standard open-source examples. We'll create a "HyperCube" contract that manages a network of interconnected "Nodes" within a simulated, abstract, multi-dimensional space.

This contract will explore concepts like:
1.  **Multidimensional State:** Nodes have properties that can be thought of as coordinates or attributes in a conceptual N-dimensional space.
2.  **Dynamic Topology:** Nodes can be created, destroyed, and linked together, forming a graph structure.
3.  **System-Level State:** The overall "HyperCube" has global properties and states that influence node behavior.
4.  **Capability-Based Access:** Instead of simple `msg.sender` ownership for nodes, we'll use a capability key system.
5.  **Complex Interactions:** Functions will simulate interactions like resonance propagation, flux distribution, and property decay based on system state and links.
6.  **Dimension Manipulation:** The structure of the space itself (number of dimensions, dimension properties) can be altered.

This is a complex, abstract model designed to showcase various interactions and state management patterns beyond typical token or simple data contracts.

---

**Outline and Function Summary:**

**Contract Name:** HyperCube

**Concept:** A contract managing a network of abstract "Nodes" within a mutable, multi-dimensional space (the "HyperCube"). Nodes interact based on their properties, links, and the global state of the HyperCube. Access to node manipulation is controlled by a capability key system.

**Core Data Structures:**
*   `Node`: Represents a point/entity in the HyperCube with various scalar properties (energy, stability, resonance, affinity), boolean state flags, links to other nodes, and a capability key ID.
*   `DimensionProperties`: Defines characteristics of each dimension in the HyperCube (e.g., influence on node stability, flux channeling).
*   `SystemState`: An enum representing the overall state of the HyperCube (e.g., Stable, Volatile, Expanding, Contracting).

**State Variables:**
*   `owner`: The contract deployer (admin).
*   `_nextNodeId`: Counter for unique node IDs.
*   `nodes`: Mapping from node ID (`uint256`) to `Node` struct.
*   `activeNodeCount`: Total number of non-deleted nodes.
*   `dimensions`: Current number of active dimensions (`uint8`).
*   `dimensionProps`: Mapping from dimension index (`uint8`) to `DimensionProperties`.
*   `globalFlux`: A system-wide scalar representing energy or activity.
*   `systemState`: Current overall `SystemState`.
*   `capabilityKeys`: Mapping from an address (`address`) to a capability key ID (`uint256`).
*   `nodeCapabilities`: Mapping from node ID (`uint256`) to its required capability key ID (`uint256`).
*   `_nextCapabilityKeyId`: Counter for unique capability key IDs.

**Modifiers:**
*   `onlyOwner`: Restricts access to the contract owner.
*   `hasCapability(uint256 _capabilityKeyId)`: Checks if `msg.sender` possesses the required capability key.
*   `nodeCapability(uint256 _nodeId)`: Checks if `msg.sender` has the capability key required for a specific node.

**Events:**
*   `NodeCreated(uint256 nodeId, address creator, uint256 capabilityKeyId)`
*   `NodeUpdated(uint256 nodeId)`
*   `NodeDeleted(uint256 nodeId)`
*   `LinkCreated(uint256 nodeId1, uint256 nodeId2)`
*   `LinkRemoved(uint256 nodeId1, uint256 nodeId2)`
*   `SystemStateChanged(SystemState newState, uint256 fluxLevel)`
*   `DimensionAdded(uint8 dimensionIndex)`
*   `DimensionRemoved(uint8 dimensionIndex)`
*   `DimensionPropertiesShifted(uint8 dimensionIndex)`
*   `CapabilityAssigned(address indexed recipient, uint256 capabilityKeyId)`
*   `CapabilityRevoked(address indexed recipient, uint256 capabilityKeyId)`
*   `FluxInduced(address indexed inducer, uint256 amount)`
*   `FluxDistributed(uint256 totalAmount, uint256 nodesAffected)`
*   `ResonancePropagated(uint256 indexed startNodeId, uint256 totalNodesAffected)`
*   `NodesDecayed(uint256 nodesProcessed, uint256 totalEnergyLoss)`

**Functions (>= 20):**

1.  `constructor(uint8 initialDimensions)`: Deploys the contract, sets owner, initial dimensions, and default dimension properties.
2.  `createCapabilityKey()`: Allows the owner to mint a new, unique capability key ID. Returns the new key ID. (Owner Only)
3.  `assignCapability(address _recipient, uint256 _capabilityKeyId)`: Assigns a specific capability key ID to an address. (Owner Only)
4.  `revokeCapability(address _holder)`: Revokes the capability key held by an address. (Owner Only)
5.  `checkCapability(address _addr, uint256 _capabilityKeyId) view`: Checks if an address holds a specific capability key.
6.  `getCapabilityKey(address _addr) view`: Returns the capability key ID held by an address.
7.  `createNode(uint256 _capabilityKeyId, uint256 initialEnergy, uint256 initialStability, uint256 initialResonance, uint256 initialAffinity, uint256 initialFlags) payable`: Creates a new Node. Requires the specified capability key. Initial properties are set. Can accept ETH (adds to global flux or node energy?). Let's say it adds to global flux.
8.  `deleteNode(uint256 _nodeId)`: Deletes a node if its energy is zero or below a threshold. Requires the node's capability key.
9.  `updateNodeScalarProperty(uint256 _nodeId, string calldata _property, uint256 _value)`: Updates one of the scalar properties (energy, stability, resonance, affinity) of a node. Requires the node's capability key. (Uses string for property name for flexibility, but less efficient).
10. `updateNodeStateFlag(uint256 _nodeId, uint8 _flagIndex, bool _setValue)`: Sets or unsets a specific bit (flag) in the node's `stateFlags`. Requires the node's capability key.
11. `transferEnergy(uint256 _fromNodeId, uint256 _toNodeId, uint256 _amount)`: Transfers energy between two nodes. Requires the capability key for the *source* node.
12. `createLink(uint256 _nodeId1, uint256 _nodeId2)`: Creates a directed link from `_nodeId1` to `_nodeId2`. Requires the capability key for `_nodeId1`. (Could be bidirectional, but directed is simpler here).
13. `removeLink(uint256 _nodeId1, uint256 _nodeId2)`: Removes a link from `_nodeId1` to `_nodeId2`. Requires the capability key for `_nodeId1`.
14. `getNodeDetails(uint256 _nodeId) view`: Retrieves all details for a specific node.
15. `getNodeCapabilityKey(uint256 _nodeId) view`: Gets the capability key ID associated with a node.
16. `getOwner() view`: Returns the contract owner's address.
17. `getNodeCount() view`: Returns the current number of active nodes.
18. `getDimensions() view`: Returns the current number of dimensions.
19. `getDimensionProperties(uint8 _dimensionIndex) view`: Returns properties for a specific dimension.
20. `getGlobalFlux() view`: Returns the current global flux level.
21. `getSystemState() view`: Returns the current system state.
22. `induceFlux() payable`: Allows anyone to send ETH, which is converted into `globalFlux`.
23. `distributeFlux(uint256 _maxNodesToProcess)`: Distributes a portion of `globalFlux` among a batch of nodes based on their properties (e.g., resonance, affinity, state flags). Can be called by anyone (incentivized by potentially boosting their nodes?).
24. `triggerSystemStateTransition()`: Attempts to transition the `systemState` based on `globalFlux` and aggregated node properties. Logic is internal (e.g., high flux -> volatile, stable low flux -> stable). Can be called by anyone? Maybe requires a minimum flux level or a specific system capability key. Let's require a system capability key (assigned by owner).
25. `addDimension()`: Increases the number of dimensions and initializes properties for the new dimension. Requires system capability key.
26. `removeDimension(uint8 _dimensionIndex)`: Decreases the number of dimensions. Nodes potentially affected. Requires system capability key.
27. `shiftDimensionProperties(uint8 _dimensionIndex, uint256 _newFluxFactor, uint256 _newStateInfluence, uint256 _newResonanceAlignment)`: Modifies properties of an existing dimension. Requires system capability key.
28. `propagateResonance(uint256 _startNodeId, uint256 _intensity, uint8 _maxDepth)`: Simulates resonance propagating from a start node to linked nodes, potentially affecting their properties based on resonance values and dimension alignments. Requires the start node's capability key. Limited by depth and intensity to manage gas.
29. `decayNodes(uint256 _batchSize)`: Applies a decay factor (e.g., energy loss, stability reduction) to a batch of nodes based on `systemState` and node properties. Can be called by anyone to process decay.
30. `calculateNodeResonance(uint256 _nodeId1, uint256 _nodeId2) view`: Pure function to calculate the resonance effect between two nodes based on their properties. (Pure function, does not modify state).
31. `alignNodeToDimension(uint256 _nodeId, uint8 _dimensionIndex)`: Attempts to modify a node's properties to align better with a specific dimension's properties. Requires the node's capability key. Costly based on alignment delta.
32. `withdrawFunds() payable`: Allows the owner to withdraw accumulated ETH (e.g., from `induceFlux`).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title HyperCube
 * @dev A smart contract simulating a mutable, multi-dimensional space containing interacting Nodes.
 *
 * Outline:
 * 1. Core Data Structures (Node, DimensionProperties, SystemState)
 * 2. State Variables
 * 3. Events
 * 4. Modifiers (Access Control)
 * 5. Capability Management Functions (Owner only + Public Check)
 * 6. Node Management Functions (Capability Required)
 * 7. Link Management Functions (Node Capability Required)
 * 8. HyperCube System Functions (Flux, State Transitions, Dimensions)
 * 9. Complex Interaction Simulation Functions (Resonance, Decay, Alignment)
 * 10. View/Getter Functions
 * 11. Utility Functions (Withdrawal)
 *
 * Function Summary:
 * - constructor: Initializes the HyperCube with initial dimensions.
 * - createCapabilityKey: Mints a new unique capability key (Owner).
 * - assignCapability: Assigns a capability key to an address (Owner).
 * - revokeCapability: Removes a capability key from an address (Owner).
 * - checkCapability: Checks if an address holds a specific capability key (View).
 * - getCapabilityKey: Gets the capability key held by an address (View).
 * - createNode: Creates a new Node with initial properties (Requires Capability, Payable).
 * - deleteNode: Deletes a Node (Requires Node Capability, Checks conditions).
 * - updateNodeScalarProperty: Updates a scalar property (Requires Node Capability).
 * - updateNodeStateFlag: Sets/unsets a state flag (Requires Node Capability).
 * - transferEnergy: Transfers energy between Nodes (Requires Source Node Capability).
 * - createLink: Creates a link between Nodes (Requires Source Node Capability).
 * - removeLink: Removes a link (Requires Source Node Capability).
 * - getNodeDetails: Gets all details of a Node (View).
 * - getNodeCapabilityKey: Gets the capability key required for a Node (View).
 * - getOwner: Gets the contract owner (View).
 * - getNodeCount: Gets the number of active Nodes (View).
 * - getDimensions: Gets the current number of dimensions (View).
 * - getDimensionProperties: Gets properties for a dimension (View).
 * - getGlobalFlux: Gets the current global flux (View).
 * - getSystemState: Gets the current system state (View).
 * - induceFlux: Adds to global flux (Payable).
 * - distributeFlux: Distributes global flux to Nodes (Callable by Anyone, Processes Batch).
 * - triggerSystemStateTransition: Attempts to change SystemState (Requires System Capability).
 * - addDimension: Increases dimensions (Requires System Capability).
 * - removeDimension: Decreases dimensions (Requires System Capability, Affects Nodes).
 * - shiftDimensionProperties: Modifies dimension properties (Requires System Capability).
 * - propagateResonance: Simulates resonance spread through links (Requires Start Node Capability, Limited Depth/Intensity).
 * - decayNodes: Applies decay to Nodes (Callable by Anyone, Processes Batch).
 * - calculateNodeResonance: Calculates resonance between two Nodes (Pure).
 * - alignNodeToDimension: Modifies Node to align with Dimension (Requires Node Capability).
 * - withdrawFunds: Withdraws contract balance (Owner Only).
 */
contract HyperCube {
    address public immutable owner;

    // --- Core Data Structures ---

    enum SystemState {
        Stable,
        Volatile,
        Expanding,
        Contracting
    }

    struct Node {
        uint256 id;
        uint256 energy;       // Core resource/state
        uint256 stability;    // Resistance to change/decay
        uint256 resonance;    // Interaction factor
        uint256 affinity;     // Alignment with overall system/dimensions
        uint256 stateFlags;   // Bitmask for various boolean states (e.g., 1=Active, 2=Locked, 4=Resonant)
        uint256[] linkedNodes; // IDs of nodes this node links TO (directed)
        uint256 capabilityKeyId; // The capability key required to modify this node
        bool isActive;        // True if the node exists and is active
    }

    struct DimensionProperties {
        uint256 fluxFactor;         // How this dimension channels flux
        uint256 stabilityInfluence; // How this dimension affects node stability
        uint256 resonanceAlignment; // Base resonance alignment for this dimension
        bool isFolded;              // If the dimension is "folded" (latent)
    }

    // --- State Variables ---

    uint256 private _nextNodeId;
    mapping(uint256 => Node) public nodes; // Node ID => Node struct
    uint256 public activeNodeCount;

    uint8 public dimensions; // Current number of dimensions
    mapping(uint8 => DimensionProperties) public dimensionProps; // Dimension Index => Properties

    uint256 public globalFlux; // System-wide energy/activity pool
    SystemState public systemState; // Overall state of the HyperCube

    // Capability System: Address maps to a capability key ID
    mapping(address => uint256) private capabilityKeys;
    // A special key ID reserved for system-level actions
    uint256 public constant SYSTEM_CAPABILITY_KEY = 1;
    // Capability Key counter (0 is invalid, 1 is system)
    uint256 private _nextCapabilityKeyId = 2; // Start from 2

    // --- Events ---

    event NodeCreated(uint256 nodeId, address creator, uint256 capabilityKeyId);
    event NodeUpdated(uint256 nodeId);
    event NodeDeleted(uint224 indexed nodeId); // Use smaller index for gas
    event LinkCreated(uint256 indexed nodeId1, uint256 indexed nodeId2);
    event LinkRemoved(uint256 indexed nodeId1, uint256 indexed nodeId2);
    event SystemStateChanged(SystemState newState, uint256 fluxLevel);
    event DimensionAdded(uint8 dimensionIndex);
    event DimensionRemoved(uint8 dimensionIndex);
    event DimensionPropertiesShifted(uint8 dimensionIndex);
    event CapabilityAssigned(address indexed recipient, uint256 capabilityKeyId);
    event CapabilityRevoked(address indexed recipient, uint256 oldCapabilityKeyId);
    event FluxInduced(address indexed inducer, uint256 amount);
    event FluxDistributed(uint256 totalAmount, uint256 nodesAffected);
    event ResonancePropagated(uint256 indexed startNodeId, uint256 totalNodesAffected);
    event NodesDecayed(uint256 nodesProcessed, uint256 totalEnergyLoss);
    event NodeAlignmentAttempt(uint256 indexed nodeId, uint8 indexed dimensionIndex, int256 alignmentCost);


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier hasCapability(uint256 _capabilityKeyId) {
        require(capabilityKeys[msg.sender] == _capabilityKeyId, "Requires specific capability key");
        _;
    }

     modifier nodeCapability(uint256 _nodeId) {
        require(nodes[_nodeId].isActive, "Node does not exist");
        require(capabilityKeys[msg.sender] == nodes[_nodeId].capabilityKeyId, "Requires node's capability key");
        _;
    }

    // --- Constructor ---

    constructor(uint8 initialDimensions) {
        owner = msg.sender;
        require(initialDimensions > 0, "Must have at least one dimension");
        dimensions = initialDimensions;
        systemState = SystemState.Stable; // Initial state

        // Initialize default properties for initial dimensions
        for (uint8 i = 0; i < dimensions; i++) {
            dimensionProps[i] = DimensionProperties({
                fluxFactor: 100, // Default values
                stabilityInfluence: 50,
                resonanceAlignment: 50,
                isFolded: false
            });
        }

        // Assign the initial SYSTEM_CAPABILITY_KEY to the owner
        capabilityKeys[owner] = SYSTEM_CAPABILITY_KEY;
        emit CapabilityAssigned(owner, SYSTEM_CAPABILITY_KEY);
    }

    // --- Capability Management (Owner Only + Public Check) ---

    /**
     * @dev Mints a new unique capability key ID. Only callable by the owner.
     * @return The newly created capability key ID.
     */
    function createCapabilityKey() external onlyOwner returns (uint256) {
        uint256 newKeyId = _nextCapabilityKeyId++;
        // Note: Key IDs are not directly assigned here, just minted.
        // Use assignCapability to link to an address.
        return newKeyId;
    }

    /**
     * @dev Assigns a capability key ID to a specific address. Only callable by the owner.
     * @param _recipient The address to assign the capability key to.
     * @param _capabilityKeyId The ID of the capability key to assign. Must have been minted.
     */
    function assignCapability(address _recipient, uint256 _capabilityKeyId) external onlyOwner {
        require(_capabilityKeyId > 0 && _capabilityKeyId < _nextCapabilityKeyId, "Invalid capability key ID");
        uint256 oldKeyId = capabilityKeys[_recipient];
        capabilityKeys[_recipient] = _capabilityKeyId;
        emit CapabilityAssigned(_recipient, _capabilityKeyId);
        if (oldKeyId != 0) {
            emit CapabilityRevoked(_recipient, oldKeyId); // Emit revoke for previous key if any
        }
    }

    /**
     * @dev Revokes the capability key currently held by an address. Only callable by the owner.
     * @param _holder The address whose capability key should be revoked.
     */
    function revokeCapability(address _holder) external onlyOwner {
        uint256 oldKeyId = capabilityKeys[_holder];
        require(oldKeyId != 0 && oldKeyId != SYSTEM_CAPABILITY_KEY, "Address has no capability key or holds system key");
        delete capabilityKeys[_holder];
        emit CapabilityRevoked(_holder, oldKeyId);
    }

    /**
     * @dev Checks if a given address holds a specific capability key ID.
     * @param _addr The address to check.
     * @param _capabilityKeyId The capability key ID to check for.
     * @return True if the address holds the key, false otherwise.
     */
    function checkCapability(address _addr, uint256 _capabilityKeyId) external view returns (bool) {
        return capabilityKeys[_addr] == _capabilityKeyId;
    }

     /**
     * @dev Gets the capability key ID held by an address.
     * @param _addr The address to query.
     * @return The capability key ID, or 0 if none is held.
     */
    function getCapabilityKey(address _addr) external view returns (uint256) {
        return capabilityKeys[_addr];
    }


    // --- Node Management (Capability Required) ---

    /**
     * @dev Creates a new Node in the HyperCube.
     * Requires the specified capability key to be held by msg.sender.
     * Accepts ETH which is added to globalFlux.
     * @param _capabilityKeyId The capability key ID required to create and manage this node.
     * @param initialEnergy Initial energy for the node.
     * @param initialStability Initial stability.
     * @param initialResonance Initial resonance.
     * @param initialAffinity Initial affinity.
     * @param initialFlags Initial state flags bitmask.
     */
    function createNode(
        uint256 _capabilityKeyId,
        uint256 initialEnergy,
        uint256 initialStability,
        uint256 initialResonance,
        uint256 initialAffinity,
        uint256 initialFlags
    ) external payable hasCapability(_capabilityKeyId) {
        require(_capabilityKeyId > 0 && _capabilityKeyId < _nextCapabilityKeyId, "Invalid capability key ID provided");

        uint256 nodeId = ++_nextNodeId;
        nodes[nodeId] = Node({
            id: nodeId,
            energy: initialEnergy,
            stability: initialStability,
            resonance: initialResonance,
            affinity: initialAffinity,
            stateFlags: initialFlags,
            linkedNodes: new uint256[](0),
            capabilityKeyId: _capabilityKeyId,
            isActive: true
        });
        activeNodeCount++;

        if (msg.value > 0) {
            globalFlux += msg.value; // Add received ETH to global flux
            emit FluxInduced(msg.sender, msg.value);
        }

        emit NodeCreated(nodeId, msg.sender, _capabilityKeyId);
        emit NodeUpdated(nodeId); // Indicate initial state set
    }

    /**
     * @dev Deletes a node. Requires the node's capability key.
     * Node must have zero energy or explicitly forced delete (requires high stability loss).
     * @param _nodeId The ID of the node to delete.
     */
    function deleteNode(uint256 _nodeId) external nodeCapability(_nodeId) {
        Node storage node = nodes[_nodeId];
        require(node.isActive, "Node is not active");
        require(node.energy == 0 || node.stability < 10, "Node must have zero energy or critically low stability to be deleted"); // Example condition

        // Remove incoming links from other nodes (potentially costly if many links exist)
        // In a more complex system, this might be batched or require iterating through *all* nodes
        // For simplicity here, we skip iterating incoming links and just mark as inactive.
        // A real system would need a robust link management index.

        node.isActive = false; // Mark as inactive instead of fully deleting for history/gas
        activeNodeCount--;

        emit NodeDeleted(uint224(_nodeId)); // Use smaller index for gas
    }

    /**
     * @dev Updates a single scalar property of a node.
     * Requires the node's capability key.
     * @param _nodeId The ID of the node to update.
     * @param _property The name of the scalar property ("energy", "stability", "resonance", "affinity").
     * @param _value The new value for the property.
     */
    function updateNodeScalarProperty(uint256 _nodeId, string calldata _property, uint256 _value) external nodeCapability(_nodeId) {
        Node storage node = nodes[_nodeId];
        require(node.isActive, "Node is not active");

        // Using string comparison is gas-expensive. In a high-performance scenario,
        // use function overloads or pass an enum/index.
        if (keccak256(abi.encodePacked(_property)) == keccak256(abi.encodePacked("energy"))) {
            node.energy = _value;
        } else if (keccak256(abi.encodePacked(_property)) == keccak256(abi.encodePacked("stability"))) {
             require(_value <= 1000, "Stability max is 1000"); // Example constraint
            node.stability = _value;
        } else if (keccak256(abi.encodePacked(_property)) == keccak256(abi.encodePacked("resonance"))) {
             require(_value <= 1000, "Resonance max is 1000"); // Example constraint
            node.resonance = _value;
        } else if (keccak256(abi.encodePacked(_property)) == keccak256(abi.encodePacked("affinity"))) {
             require(_value <= 1000, "Affinity max is 1000"); // Example constraint
            node.affinity = _value;
        } else {
            revert("Invalid property name");
        }

        emit NodeUpdated(_nodeId);
    }

    /**
     * @dev Sets or unsets a specific state flag (bit) for a node.
     * Requires the node's capability key.
     * @param _nodeId The ID of the node.
     * @param _flagIndex The index of the bit to set/unset (0-255).
     * @param _setValue True to set the flag, false to unset it.
     */
    function updateNodeStateFlag(uint255 _nodeId, uint8 _flagIndex, bool _setValue) external nodeCapability(_nodeId) {
         require(_flagIndex < 256, "Flag index out of bounds");
        Node storage node = nodes[_nodeId];
        require(node.isActive, "Node is not active");

        if (_setValue) {
            node.stateFlags |= (1 << _flagIndex); // Set the bit
        } else {
            node.stateFlags &= ~(1 << _flagIndex); // Unset the bit
        }

        emit NodeUpdated(_nodeId);
    }


    /**
     * @dev Transfers energy from one node to another.
     * Requires the capability key of the source node.
     * @param _fromNodeId The ID of the node to transfer energy from.
     * @param _toNodeId The ID of the node to transfer energy to.
     * @param _amount The amount of energy to transfer.
     */
    function transferEnergy(uint256 _fromNodeId, uint256 _toNodeId, uint256 _amount) external nodeCapability(_fromNodeId) {
        require(nodes[_fromNodeId].isActive, "Source node is not active");
        require(nodes[_toNodeId].isActive, "Target node is not active");
        require(nodes[_fromNodeId].energy >= _amount, "Insufficient energy in source node");

        nodes[_fromNodeId].energy -= _amount;
        nodes[_toNodeId].energy += _amount;

        emit NodeUpdated(_fromNodeId);
        emit NodeUpdated(_toNodeId);
    }

    // --- Link Management (Node Capability Required) ---

    /**
     * @dev Creates a directed link from _nodeId1 to _nodeId2.
     * Requires the capability key of _nodeId1.
     * @param _nodeId1 The ID of the source node.
     * @param _nodeId2 The ID of the target node.
     */
    function createLink(uint256 _nodeId1, uint256 _nodeId2) external nodeCapability(_nodeId1) {
        require(nodes[_nodeId1].isActive, "Source node is not active");
        require(nodes[_nodeId2].isActive, "Target node is not active");
        require(_nodeId1 != _nodeId2, "Cannot link a node to itself");

        Node storage node1 = nodes[_nodeId1];

        // Prevent duplicate links (basic check, could be optimized with a mapping)
        for (uint i = 0; i < node1.linkedNodes.length; i++) {
            if (node1.linkedNodes[i] == _nodeId2) {
                revert("Link already exists");
            }
        }

        node1.linkedNodes.push(_nodeId2);

        emit LinkCreated(_nodeId1, _nodeId2);
        emit NodeUpdated(_nodeId1); // Link change is an update to the node state
    }

    /**
     * @dev Removes a directed link from _nodeId1 to _nodeId2.
     * Requires the capability key of _nodeId1.
     * @param _nodeId1 The ID of the source node.
     * @param _nodeId2 The ID of the target node.
     */
    function removeLink(uint256 _nodeId1, uint256 _nodeId2) external nodeCapability(_nodeId1) {
        Node storage node1 = nodes[_nodeId1];
        require(node1.isActive, "Source node is not active");

        bool linkFound = false;
        for (uint i = 0; i < node1.linkedNodes.length; i++) {
            if (node1.linkedNodes[i] == _nodeId2) {
                // Swap with last element and pop (common Solidity pattern to remove from array)
                node1.linkedNodes[i] = node1.linkedNodes[node1.linkedNodes.length - 1];
                node1.linkedNodes.pop();
                linkFound = true;
                break;
            }
        }

        require(linkFound, "Link does not exist");

        emit LinkRemoved(_nodeId1, _nodeId2);
        emit NodeUpdated(_nodeId1); // Link change is an update to the node state
    }

    // --- HyperCube System Functions ---

    /**
     * @dev Allows anyone to add ETH to the global flux pool.
     * The ETH is converted 1:1 to flux units (simplification).
     */
    receive() external payable {
        if (msg.value > 0) {
             globalFlux += msg.value;
            emit FluxInduced(msg.sender, msg.value);
        }
    }

    /**
     * @dev Allows anyone to add ETH to the global flux pool (explicit function).
     * @dev Same as receive() but with a function signature.
     */
    function induceFlux() external payable {
         if (msg.value > 0) {
             globalFlux += msg.value;
            emit FluxInduced(msg.sender, msg.value);
        }
    }


    /**
     * @dev Distributes a portion of the global flux among active nodes.
     * Distribution logic is based on node resonance and affinity.
     * Processes up to `_maxNodesToProcess` nodes starting from the last processed ID.
     * Can be called by anyone (potentially for gas/processing incentive in a real system).
     * @param _maxNodesToProcess The maximum number of nodes to process in this call.
     */
    uint256 private _lastFluxProcessedNodeId = 0;
    function distributeFlux(uint256 _maxNodesToProcess) external {
        require(globalFlux > 0, "No flux to distribute");
        require(_maxNodesToProcess > 0, "Must process at least one node");

        uint256 processedCount = 0;
        uint256 totalDistributed = 0;
        uint256 startNodeId = _lastFluxProcessedNodeId + 1; // Start from the next node

        // Simple iteration, might need more advanced cursor/pagination for large number of nodes
        for (uint256 i = 0; i < _maxNodesToProcess; ++i) {
             uint256 currentNodeId = startNodeId + i;
             if (currentNodeId > _nextNodeId) {
                 // Wrap around if we reach the end of created IDs
                 currentNodeId = 1;
                 if (_nextNodeId == 0) break; // No nodes created yet
                 startNodeId = 1 - i; // Adjust start for next iteration
             }

            Node storage node = nodes[currentNodeId];

            if (node.isActive) {
                // Distribution logic: example based on resonance and affinity
                // Avoid division by zero
                uint256 distributionAmount = 0;
                if (node.resonance > 0 && node.affinity > 0) {
                    // Simple formula: resonance * affinity / some_scaling_factor
                    // Use shifting or division carefully to avoid overflow/underflow
                     distributionAmount = (globalFlux * node.resonance * node.affinity) / (1000 * 1000 * 1000); // Scaling example
                     distributionAmount = distributionAmount > globalFlux ? globalFlux : distributionAmount; // Cap at remaining flux
                     distributionAmount = distributionAmount > 0 ? distributionAmount : 1; // Minimum distribution to active nodes?
                } else {
                    // Minimal distribution for nodes with zero resonance/affinity
                     distributionAmount = globalFlux / (activeNodeCount > 0 ? activeNodeCount : 1);
                     distributionAmount = distributionAmount > globalFlux ? globalFlux : distributionAmount;
                     distributionAmount = distributionAmount > 0 ? distributionAmount : 1;
                }


                // Prevent distributing more than available global flux
                 if (distributionAmount > globalFlux) {
                     distributionAmount = globalFlux;
                 }


                node.energy += distributionAmount;
                globalFlux -= distributionAmount;
                totalDistributed += distributionAmount;
                processedCount++;
                emit NodeUpdated(currentNodeId);

                if (globalFlux == 0) {
                    _lastFluxProcessedNodeId = currentNodeId;
                    break; // No more flux to distribute
                }
            }
             _lastFluxProcessedNodeId = currentNodeId; // Update cursor even if node was inactive
             if (_lastFluxProcessedNodeId >= _nextNodeId) {
                _lastFluxProcessedNodeId = 0; // Reset cursor if we wrapped around or hit the end
             }
             if(processedCount >= _maxNodesToProcess) break; // Process up to the limit
        }


        emit FluxDistributed(totalDistributed, processedCount);
         if (globalFlux == 0 && systemState == SystemState.Volatile) {
             // Maybe trigger a state change if flux runs out in volatile state
             // _attemptSystemStateTransition(); // Internal helper
         }
    }

    /**
     * @dev Attempts to transition the overall system state based on global flux and potentially aggregated node properties.
     * Requires the SYSTEM_CAPABILITY_KEY.
     */
    function triggerSystemStateTransition() external hasCapability(SYSTEM_CAPABILITY_KEY) {
        SystemState oldState = systemState;
        SystemState newState = oldState; // Assume no change unless logic dictates otherwise

        // Example state transition logic (can be complex)
        if (globalFlux > 10000 ether) { // High flux
            newState = SystemState.Expanding;
        } else if (globalFlux < 1 ether && activeNodeCount < 10) { // Low flux, few nodes
             newState = SystemState.Contracting;
        } else if (globalFlux > 100 ether && globalFlux <= 10000 ether) { // Moderate flux
             // Maybe aggregate node properties? E.g., check average stability
             // For simplicity, let's transition between Stable and Volatile based on flux range
             if (systemState == SystemState.Stable) {
                 newState = SystemState.Volatile;
             }
        } else if (globalFlux <= 100 ether && systemState == SystemState.Volatile) {
             newState = SystemState.Stable;
        }
        // Add conditions for transitions to/from Expanding/Contracting based on more complex factors

        if (newState != oldState) {
            systemState = newState;
            emit SystemStateChanged(systemState, globalFlux);
        }
    }

    /**
     * @dev Increases the number of active dimensions in the HyperCube.
     * Initializes default properties for the new dimension.
     * Requires the SYSTEM_CAPABILITY_KEY.
     */
    function addDimension() external hasCapability(SYSTEM_CAPABILITY_KEY) {
        require(dimensions < 255, "Max dimensions reached"); // Prevent overflow
        uint8 newDimensionIndex = dimensions;
        dimensions++;

        // Initialize default properties for the new dimension
        dimensionProps[newDimensionIndex] = DimensionProperties({
             fluxFactor: 150, // New dimensions might have different defaults
             stabilityInfluence: 70,
             resonanceAlignment: 60,
             isFolded: false
        });

        emit DimensionAdded(newDimensionIndex);
    }

    /**
     * @dev Decreases the number of active dimensions.
     * Requires the SYSTEM_CAPABILITY_KEY.
     * Note: This might conceptually affect nodes, though the contract doesn't
     * automatically recalculate all node properties here due to gas limits.
     * A separate function or interaction would be needed to process node changes.
     * @param _dimensionIndex The index of the dimension to remove. Must be less than current dimensions.
     */
    function removeDimension(uint8 _dimensionIndex) external hasCapability(SYSTEM_CAPABILITY_KEY) {
        require(_dimensionIndex < dimensions, "Invalid dimension index");
        require(dimensions > 1, "Must have at least one dimension");

        // Simple removal: just decrease the counter.
        // Properties for this index remain in storage but are conceptually inactive
        // unless the array-like access is implemented carefully.
        // More robust: Shift remaining dimensions, e.g., dim[dimensions-1] -> dim[_dimensionIndex]
        // For simplicity here, we just decrement dimensions and note the implications.
        dimensions--;

        // Consider removing the properties mapping entry, but not strictly necessary if dimensions counter is respected.
        // delete dimensionProps[_dimensionIndex]; // Optional, gas cost

        emit DimensionRemoved(_dimensionIndex);

        // Note: Nodes whose affinity or other properties were tied to this dimension
        // would need manual updates or a decay process to reflect the change.
    }

    /**
     * @dev Modifies the properties of an existing dimension.
     * Requires the SYSTEM_CAPABILITY_KEY.
     * @param _dimensionIndex The index of the dimension to modify.
     * @param _newFluxFactor New flux factor.
     * @param _newStateInfluence New stability influence.
     * @param _newResonanceAlignment New resonance alignment.
     */
    function shiftDimensionProperties(
        uint8 _dimensionIndex,
        uint256 _newFluxFactor,
        uint256 _newStateInfluence,
        uint256 _newResonanceAlignment
    ) external hasCapability(SYSTEM_CAPABILITY_KEY) {
        require(_dimensionIndex < dimensions, "Invalid dimension index");

        DimensionProperties storage props = dimensionProps[_dimensionIndex];
        props.fluxFactor = _newFluxFactor;
        props.stabilityInfluence = _newStateInfluence;
        props.resonanceAlignment = _newResonanceAlignment;
        // isFolded property is changed via fold/unfold functions

        emit DimensionPropertiesShifted(_dimensionIndex);
    }

    /**
     * @dev Folds a dimension, making it latent. Nodes might behave differently.
     * Requires the SYSTEM_CAPABILITY_KEY.
     * @param _dimensionIndex The index of the dimension to fold.
     */
    function foldDimension(uint8 _dimensionIndex) external hasCapability(SYSTEM_CAPABILITY_KEY) {
        require(_dimensionIndex < dimensions, "Invalid dimension index");
        DimensionProperties storage props = dimensionProps[_dimensionIndex];
        require(!props.isFolded, "Dimension is already folded");
        props.isFolded = true;
        emit DimensionPropertiesShifted(_dimensionIndex); // Use same event
    }

    /**
     * @dev Unfolds a dimension, making it active again.
     * Requires the SYSTEM_CAPABILITY_KEY.
     * @param _dimensionIndex The index of the dimension to unfold.
     */
    function unfoldDimension(uint8 _dimensionIndex) external hasCapability(SYSTEM_CAPABILITY_KEY) {
         require(_dimensionIndex < dimensions, "Invalid dimension index");
        DimensionProperties storage props = dimensionProps[_dimensionIndex];
        require(props.isFolded, "Dimension is not folded");
        props.isFolded = false;
        emit DimensionPropertiesShifted(_dimensionIndex); // Use same event
    }


    // --- Complex Interaction Simulation ---

    /**
     * @dev Simulates resonance propagation starting from a node through its links.
     * Affects linked nodes' properties based on resonance values and dimension alignments.
     * Limited by depth and intensity to manage gas.
     * Requires the start node's capability key.
     * @param _startNodeId The ID of the node to start propagation from.
     * @param _intensity The initial intensity of the resonance wave (e.g., 1-1000).
     * @param _maxDepth The maximum depth to traverse through links.
     */
    function propagateResonance(uint256 _startNodeId, uint256 _intensity, uint8 _maxDepth) external nodeCapability(_startNodeId) {
        require(nodes[_startNodeId].isActive, "Start node is not active");
        require(_intensity > 0, "Intensity must be positive");
        require(_maxDepth > 0, "Max depth must be positive");

        // This function is potentially very gas-intensive depending on network structure.
        // A more robust solution would use off-chain computation to determine effects
        // and then submit a summary transaction, or process in batched calls.
        // This implementation is simplified for concept demonstration.

        uint256[] memory nodesToProcess = new uint256[](1);
        nodesToProcess[0] = _startNodeId;

        mapping(uint256 => uint8) visitedDepth;
        visitedDepth[_startNodeId] = 1;

        uint256 totalNodesAffected = 0;
        uint256 currentIntensity = _intensity;

        // Simple breadth-first traversal for demonstration
        for (uint8 depth = 1; depth <= _maxDepth && nodesToProcess.length > 0; ++depth) {
            uint256[] memory nextLayerNodes;
            // Using a fixed-size temp array might be better for gas, but dynamic for conceptual clarity
            uint256[] memory tempNextLayer = new uint256[](nodesToProcess.length * 5); // Estimate next layer size
            uint256 tempCount = 0;

            for (uint i = 0; i < nodesToProcess.length; ++i) {
                uint256 currentNodeId = nodesToProcess[i];
                Node storage currentNode = nodes[currentNodeId];

                if (currentNode.isActive) {
                    // Apply resonance effect to current node (example: boost energy, reduce stability slightly)
                     uint256 effect = (currentIntensity * currentNode.resonance) / 1000;
                     if (effect > 0) {
                         currentNode.energy += effect;
                         // currentNode.stability = currentNode.stability > effect / 10 ? currentNode.stability - effect / 10 : 0; // Example decay
                         emit NodeUpdated(currentNodeId);
                         totalNodesAffected++;
                     }


                    // Add linked nodes to the next layer if not visited at shallower depth
                    for (uint j = 0; j < currentNode.linkedNodes.length; ++j) {
                        uint256 linkedNodeId = currentNode.linkedNodes[j];
                        if (nodes[linkedNodeId].isActive && (visitedDepth[linkedNodeId] == 0 || visitedDepth[linkedNodeId] > depth + 1)) {
                             visitedDepth[linkedNodeId] = depth + 1;
                             if (tempCount < tempNextLayer.length) {
                                 tempNextLayer[tempCount++] = linkedNodeId;
                             } else {
                                 // Handle exceeding temp array capacity (reallocate or cap)
                                 // For this example, we'll just cap the propagation
                             }
                        }
                    }
                }
            }

             // Copy tempNextLayer to nextLayerNodes
             nextLayerNodes = new uint256[](tempCount);
             for(uint i=0; i<tempCount; ++i) {
                 nextLayerNodes[i] = tempNextLayer[i];
             }


            nodesToProcess = nextLayerNodes; // Move to the next layer
            currentIntensity = (currentIntensity * 80) / 100; // Intensity decays with depth (example 80% retention)
            if (currentIntensity == 0) break;
        }

        emit ResonancePropagated(_startNodeId, totalNodesAffected);
    }

    /**
     * @dev Applies a decay factor to a batch of nodes.
     * Decay rate depends on systemState and node properties (e.g., stability).
     * Can be called by anyone to process decay. Useful for upkeep.
     * Processes up to `_batchSize` nodes starting from the last processed ID.
     * @param _batchSize The maximum number of nodes to process in this call.
     */
    uint256 private _lastDecayProcessedNodeId = 0;
    function decayNodes(uint256 _batchSize) external {
         require(_batchSize > 0, "Batch size must be positive");

        uint256 processedCount = 0;
        uint256 totalEnergyLoss = 0;
         uint256 startNodeId = _lastDecayProcessedNodeId + 1;

         for (uint256 i = 0; i < _batchSize; ++i) {
             uint256 currentNodeId = startNodeId + i;
             if (currentNodeId > _nextNodeId) {
                 currentNodeId = 1; // Wrap around
                 if (_nextNodeId == 0) break;
                 startNodeId = 1 - i;
             }
            if (currentNodeId == 0) continue; // Skip invalid ID if _nextNodeId is 0

            Node storage node = nodes[currentNodeId];

            if (node.isActive) {
                // Decay logic: example based on stability and system state
                uint256 decayAmount = 0;
                uint256 baseDecay = 1; // Base decay unit

                if (systemState == SystemState.Volatile) baseDecay = baseDecay * 2;
                if (systemState == SystemState.Contracting) baseDecay = baseDecay * 3;

                // Decay is higher for low stability nodes
                uint256 stabilityFactor = node.stability == 0 ? 1000 : (1000000 / node.stability); // Inverse relation, scaled
                decayAmount = (baseDecay * stabilityFactor) / 1000; // Apply stability influence

                 // Apply dimension influence? (e.g., folded dimensions increase decay)
                 // This would require iterating dimensions the node is "aligned" with or checking system state related to dimensions

                 if (node.energy > decayAmount) {
                     node.energy -= decayAmount;
                     totalEnergyLoss += decayAmount;
                     emit NodeUpdated(currentNodeId);
                 } else if (node.energy > 0) {
                     totalEnergyLoss += node.energy;
                     node.energy = 0;
                     emit NodeUpdated(currentNodeId);
                     // Maybe trigger deletion if energy hits zero
                     // deleteNode(currentNodeId); // Would need careful re-entrancy handling if called directly
                 }

                processedCount++;
            }
            _lastDecayProcessedNodeId = currentNodeId;
             if (_lastDecayProcessedNodeId >= _nextNodeId) {
                _lastDecayProcessedNodeId = 0; // Reset cursor
             }
            if (processedCount >= _batchSize) break;
        }

        emit NodesDecayed(processedCount, totalEnergyLoss);
    }


    /**
     * @dev Calculates a hypothetical resonance value between two nodes. Pure function.
     * This could be used off-chain or within other complex functions.
     * @param _nodeId1 The ID of the first node.
     * @param _nodeId2 The ID of the second node.
     * @return A calculated resonance value.
     */
    function calculateNodeResonance(uint256 _nodeId1, uint256 _nodeId2) public view returns (uint256) {
        // Requires nodes to exist for meaningful calculation, but function is pure,
        // so it cannot access storage (`nodes` mapping).
        // This function is illustrative. In practice, a `view` function taking structs or properties
        // as arguments would be needed, or it would be calculated internally by state-changing functions.
        // For a pure function example:
        // return (node1_resonance + node2_resonance) / 2; // Example using hypothetical inputs

         // Let's provide a placeholder calculation as it cannot read state in 'pure'.
         // A real use case would pass node properties as arguments.
         // Example: return (_resonance1 * _resonance2) / 1000; // If properties were arguments

         // As a pure function, we cannot access `nodes`.
         // To make this callable and useful, it would need to be `view` and access state,
         // or take node properties as parameters and be `pure`.
         // We'll leave it as `view` and access state for demonstration purposes, despite the name.
         // In a strict interpretation of 'pure', this would be different.

        require(nodes[_nodeId1].isActive && nodes[_nodeId2].isActive, "Both nodes must exist to calculate resonance");
        // Example calculation: simple average, or product, or difference based on properties
        uint256 res1 = nodes[_nodeId1].resonance;
        uint256 res2 = nodes[_nodeId2].resonance;
        uint256 aff1 = nodes[_nodeId1].affinity;
        uint256 aff2 = nodes[_nodeId2].affinity;

        // Complex example: Higher resonance if affinities align and resonance values are similar
        uint256 affinityMatch = 1000 - (aff1 > aff2 ? aff1 - aff2 : aff2 - aff1); // 1000 if affinities match, 0 if max difference
        uint256 resonanceMatch = 1000 - (res1 > res2 ? res1 - res2 : res2 - res1); // 1000 if resonance values match

        // Combined score: simple product, scaled
        return (uint256(affinityMatch) * uint256(resonanceMatch) * uint256(res1 + res2)) / (1000 * 1000 * 2000); // Scaling example
    }

    /**
     * @dev Attempts to modify a node's properties (e.g., affinity, stability) to align better
     * with the properties of a specific dimension. Requires the node's capability key.
     * May cost energy or stability from the node based on the required 'shift'.
     * @param _nodeId The ID of the node to align.
     * @param _dimensionIndex The index of the dimension to align with.
     */
    function alignNodeToDimension(uint256 _nodeId, uint8 _dimensionIndex) external nodeCapability(_nodeId) {
        require(nodes[_nodeId].isActive, "Node is not active");
        require(_dimensionIndex < dimensions && !dimensionProps[_dimensionIndex].isFolded, "Invalid or folded dimension");

        Node storage node = nodes[_nodeId];
        DimensionProperties storage dimProps = dimensionProps[_dimensionIndex];

        // Example alignment logic: shift node affinity towards dimension's resonanceAlignment
        // The "cost" is proportional to the difference and the magnitude of the shift
        int256 affinityDelta = int256(dimProps.resonanceAlignment) - int256(node.affinity);
        uint256 cost = uint256(affinityDelta > 0 ? affinityDelta : -affinityDelta); // Absolute difference
        cost = (cost * cost) / 100; // Cost increases quadratically with delta

        // Simulate cost by reducing energy and/or stability
        int256 energyCost = int256(cost / 10);
        int256 stabilityCost = int256(cost / 50);

        if (node.energy < uint256(energyCost > 0 ? energyCost : 0) || node.stability < uint256(stabilityCost > 0 ? stabilityCost : 0)) {
             revert("Insufficient energy or stability for alignment");
        }

        // Apply the shift
        node.affinity = dimProps.resonanceAlignment; // Simple direct alignment for example

        // Deduct the cost
         if (energyCost > 0) node.energy -= uint256(energyCost);
         if (stabilityCost > 0) node.stability -= uint256(stabilityCost);

        emit NodeAlignmentAttempt(_nodeId, _dimensionIndex, affinityDelta);
        emit NodeUpdated(_nodeId);
    }


    // --- View / Getter Functions ---

     /**
     * @dev Gets all details for a specific node.
     * @param _nodeId The ID of the node.
     * @return A tuple containing node properties.
     */
    function getNodeDetails(uint256 _nodeId) external view returns (
        uint256 id,
        uint256 energy,
        uint256 stability,
        uint256 resonance,
        uint256 affinity,
        uint256 stateFlags,
        uint256[] memory linkedNodes,
        uint256 capabilityKeyId,
        bool isActive
    ) {
        Node storage node = nodes[_nodeId];
        require(node.isActive, "Node does not exist or is inactive"); // Only return details for active nodes
        return (
            node.id,
            node.energy,
            node.stability,
            node.resonance,
            node.affinity,
            node.stateFlags,
            node.linkedNodes,
            node.capabilityKeyId,
            node.isActive
        );
    }

     /**
     * @dev Gets the capability key ID required for a node.
     * @param _nodeId The ID of the node.
     * @return The capability key ID, or 0 if node doesn't exist or is inactive.
     */
    function getNodeCapabilityKey(uint256 _nodeId) external view returns (uint256) {
        if (nodes[_nodeId].isActive) {
             return nodes[_nodeId].capabilityKeyId;
        }
        return 0; // Return 0 for non-existent or inactive nodes
    }


    /**
     * @dev Returns the contract owner's address.
     */
    function getOwner() external view returns (address) {
        return owner;
    }

     /**
     * @dev Returns the current number of active nodes.
     */
    function getNodeCount() external view returns (uint256) {
        return activeNodeCount;
    }

     /**
     * @dev Returns the current number of dimensions.
     */
    function getDimensions() external view returns (uint8) {
        return dimensions;
    }

    /**
     * @dev Returns properties for a specific dimension.
     * @param _dimensionIndex The index of the dimension.
     * @return A tuple containing dimension properties.
     */
    function getDimensionProperties(uint8 _dimensionIndex) external view returns (
        uint256 fluxFactor,
        uint256 stabilityInfluence,
        uint256 resonanceAlignment,
        bool isFolded
    ) {
        require(_dimensionIndex < dimensions, "Invalid dimension index");
        DimensionProperties storage props = dimensionProps[_dimensionIndex];
        return (
            props.fluxFactor,
            props.stabilityInfluence,
            props.resonanceAlignment,
            props.isFolded
        );
    }

    /**
     * @dev Returns the current global flux level.
     */
    function getGlobalFlux() external view returns (uint256) {
        return globalFlux;
    }

    /**
     * @dev Returns the current system state.
     */
    function getSystemState() external view returns (SystemState) {
        return systemState;
    }

    // --- Utility Functions ---

    /**
     * @dev Allows the contract owner to withdraw the accumulated ETH balance.
     * Funds are accumulated via the `receive()` and `induceFlux()` functions.
     */
    function withdrawFunds() external onlyOwner payable {
        // Send the contract's balance to the owner
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "ETH withdrawal failed");
    }

    // Fallback function to receive plain ETH (same as receive())
    fallback() external payable {
        if (msg.value > 0) {
             globalFlux += msg.value;
             emit FluxInduced(msg.sender, msg.value);
        }
    }
}
```