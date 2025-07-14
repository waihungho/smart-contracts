Okay, let's design an interesting, advanced, and creative smart contract.

**Concept:** **The Ethereal Nexus**

This contract simulates a decentralized, abstract network composed of "Nodes" and "Connections". Nodes can represent anything abstract - data points, AI agents, concepts, entities. Connections represent relationships, trust, data flow, or influence. The network has an internal resource called "Energy" needed to perform operations. Nodes can have reputation/scores, and users can make attestations about them. Advanced functions include simulating pathfinding, influence propagation, and dynamic state changes based on interactions.

This is **not** a standard ERC-20, ERC-721, or simple staking contract. It focuses on managing a dynamic graph structure on-chain with resource constraints and interaction logic.

---

## Outline and Function Summary

**Contract Name:** `EtherealNexus`

**Core Concept:** Manages a decentralized network graph of Nodes and Connections, powered by an internal 'Energy' resource. Nodes represent abstract entities, Connections represent relationships. Features include dynamic state, scoring, attestations, resource management, and graph simulation functions.

**Data Structures:**
*   `Node`: Represents an entity in the network (ID, owner, state, stake, score, etc.).
*   `Connection`: Represents a link between two Nodes (IDs, type, weight, etc.).
*   `SystemParameters`: Configurable costs and rates for network operations.
*   Enums for NodeState and ConnectionType.

**Key State Variables:**
*   `nodes`: Mapping from Node ID to Node struct.
*   `connections`: Mapping from Connection ID to Connection struct.
*   `nodeOutConnectionIds`, `nodeInConnectionIds`: Mappings tracking connection IDs originating/terminating at a node.
*   `energyBalances`: Mapping from address to Energy balance.
*   `attestations`: Mapping storing claims about nodes.
*   `nodeStakes`: Mapping storing ETH staked to nodes.
*   Counters for Node and Connection IDs.
*   `systemParameters`: Instance of SystemParameters struct.
*   `protocolFees`: ETH collected by the protocol.

**Function Categories:**

1.  **Initialization & Parameters (2 functions):**
    *   `constructor`: Sets owner and initial system parameters.
    *   `updateSystemParameter`: Allows owner to update parameters.

2.  **Energy Management (4 functions):**
    *   `mintEnergy`: Owner/controlled function to create new Energy.
    *   `transferEnergy`: Allows users to send Energy to others.
    *   `burnEnergy`: Allows users to destroy Energy.
    *   `getEnergyBalance`: Checks an address's Energy balance.

3.  **Node Management (7 functions):**
    *   `createNode`: Creates a new Node. Requires Energy.
    *   `updateNodeState`: Changes a Node's state. Requires Energy.
    *   `transferNodeOwnership`: Transfers Node ownership. Requires Energy.
    *   `destroyNode`: Removes a Node and its connections. Requires Energy.
    *   `stakeToNode`: Stakes ETH to a Node, increasing its influence/score potential. Accepts ETH.
    *   `withdrawStakeFromNode`: Withdraws staked ETH from a Node. Requires Energy.
    *   `getNodeDetails`: Retrieves details of a specific Node.

4.  **Connection Management (5 functions):**
    *   `createConnection`: Creates a link between two Nodes. Requires Energy.
    *   `updateConnectionWeight`: Adjusts a Connection's weight. Requires Energy.
    *   `updateConnectionType`: Changes a Connection's type. Requires Energy.
    *   `destroyConnection`: Removes a Connection. Requires Energy.
    *   `getConnectionDetails`: Retrieves details of a specific Connection.

5.  **Attestation System (2 functions):**
    *   `attestToNode`: Allows users to make a string-based claim about a Node. Requires Energy.
    *   `getAttestationsForNode`: Retrieves all attestations for a Node.

6.  **Network Query & Analysis (7 functions):**
    *   `getNodeScore`: Computes a dynamic score for a Node based on stake, connections, and attestations.
    *   `getConnectedNodes`: Retrieves IDs of nodes connected from a given node.
    *   `getConnectingNodes`: Retrieves IDs of nodes connecting to a given node.
    *   `getConnectionsBetween`: Retrieves details of connections between two specific nodes.
    *   `queryPathExistence`: **Advanced:** Checks if a path exists between two nodes within a certain depth. Requires Energy based on search complexity.
    *   `simulateInfluencePropagation`: **Advanced/Creative:** Simulates influence spreading from a source node through connections, potentially updating node scores/states. Requires significant Energy based on simulation depth/breadth.
    *   `getNodesByState`: Retrieves IDs of nodes currently in a specific state (potentially gas-intensive for large networks).

7.  **Advanced Network Dynamics (3 functions):**
    *   `synthesizeEssence`: **Creative:** Creates a *new* Node whose initial state/score is influenced by properties of *multiple* source Nodes provided. Requires high Energy cost and potentially stake.
    *   `decayConnection`: **Dynamic:** Explicitly applies a decay rate to a Connection's weight based on time elapsed since last update/creation. Requires Energy to process.
    *   `requestScopedQuery`: **Advanced:** Allows requesting a complex query (e.g., pathfinding, influence) with a defined scope, calculating Energy cost upfront and executing. (Could be integrated into query functions, but explicit separate function highlights the concept). *Let's refine this and make `queryPathExistence` and `simulateInfluencePropagation` the core advanced queries.* Replaced with `getNodesByScoreRange`.

8.  **Protocol Functions (1 function):**
    *   `withdrawProtocolFees`: Allows the owner to withdraw accumulated ETH fees.

**Total Functions:** 2 + 4 + 7 + 5 + 2 + 7 + 3 + 1 = **31 functions**.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EtherealNexus
 * @notice A smart contract simulating a decentralized network graph of Nodes and Connections,
 * powered by an internal 'Energy' resource required for operations. Features dynamic state,
 * scoring, attestations, resource management, and advanced graph simulation functions.
 * This contract is designed as a conceptual exploration of complex on-chain data structures
 * and interactions beyond standard token or NFT mechanics.
 *
 * Outline and Function Summary:
 *
 * Core Concept: Manages a decentralized network graph of abstract Nodes and Connections, powered by internal Energy.
 *
 * Data Structures:
 * - Node: Represents an entity (ID, owner, state, stake, score, etc.).
 * - Connection: Represents a link (IDs, type, weight).
 * - SystemParameters: Configurable costs/rates.
 * - Enums: NodeState, ConnectionType.
 *
 * State Variables:
 * - nodes: Mapping Node ID -> Node struct.
 * - connections: Mapping Connection ID -> Connection struct.
 * - nodeOutConnectionIds, nodeInConnectionIds: Mappings tracking connection IDs per node.
 * - energyBalances: Mapping address -> Energy balance.
 * - attestations: Mapping Node ID -> Attestor Address -> Claims (string[]).
 * - nodeStakes: Mapping Node ID -> Staker Address -> Staked Amount (uint).
 * - nodeTotalStakes: Mapping Node ID -> Total Staked Amount (uint).
 * - nodeCounter, connectionCounter: Counters for unique IDs.
 * - systemParameters: Global configuration.
 * - protocolFees: Accumulated ETH fees.
 * - owner: Contract deployer/controller.
 *
 * Function Categories & Summary:
 * 1.  Initialization & Parameters (2)
 *     - constructor: Deploy and set initial parameters.
 *     - updateSystemParameter: Owner updates system costs/rates.
 * 2.  Energy Management (4)
 *     - mintEnergy: Owner/controlled energy creation.
 *     - transferEnergy: Send energy between addresses.
 *     - burnEnergy: Destroy energy.
 *     - getEnergyBalance: Check energy balance.
 * 3.  Node Management (7)
 *     - createNode: Create a new Node (requires Energy).
 *     - updateNodeState: Change Node's state (requires Energy).
 *     - transferNodeOwnership: Transfer Node ownership (requires Energy).
 *     - destroyNode: Remove a Node and its connections (requires Energy).
 *     - stakeToNode: Stake ETH to a Node (accepts ETH).
 *     - withdrawStakeFromNode: Withdraw staked ETH (requires Energy).
 *     - getNodeDetails: View Node details.
 * 4.  Connection Management (5)
 *     - createConnection: Link two Nodes (requires Energy).
 *     - updateConnectionWeight: Adjust Connection weight (requires Energy).
 *     - updateConnectionType: Change Connection type (requires Energy).
 *     - destroyConnection: Remove a Connection (requires Energy).
 *     - getConnectionDetails: View Connection details.
 * 5.  Attestation System (2)
 *     - attestToNode: Make a claim about a Node (requires Energy).
 *     - getAttestationsForNode: View attestations for a Node.
 * 6.  Network Query & Analysis (7)
 *     - getNodeScore: Compute dynamic Node score.
 *     - getConnectedNodes: View nodes connected FROM a node.
 *     - getConnectingNodes: View nodes connected TO a node.
 *     - getConnectionsBetween: View connections between two nodes.
 *     - queryPathExistence: Advanced: Check path between nodes up to depth (requires Energy).
 *     - simulateInfluencePropagation: Advanced: Simulate influence spread (requires Energy).
 *     - getNodesByScoreRange: View nodes within a score range (potentially gas heavy).
 * 7.  Advanced Network Dynamics (3)
 *     - synthesizeEssence: Creative: Create a new Node from multiple sources (high Energy).
 *     - decayConnection: Apply time-based weight decay to a Connection (requires Energy).
 *     - updateNodeScoreBasedOnNetwork: Trigger an update to a node's score considering current network state (requires Energy).
 * 8.  Protocol Functions (1)
 *     - withdrawProtocolFees: Owner withdraws accumulated ETH fees.
 *
 * Total Functions: 31
 */

contract EtherealNexus {

    // --- Errors ---
    error InsufficientEnergy(uint256 required, uint256 has);
    error NodeNotFound(uint256 nodeId);
    error ConnectionNotFound(uint256 connectionId);
    error NotNodeOwner(uint256 nodeId, address caller);
    error InsufficientStake(uint256 nodeId, address caller, uint256 requested, uint256 has);
    error InvalidNodeState();
    error InvalidConnectionType();
    error SelfConnectionNotAllowed();
    error PathQueryDepthTooHigh(uint256 maxDepth);
    error InfluencePropagationDepthTooHigh(uint256 maxDepth);
    error InvalidParameterValue();
    error OnlyOwner();
    error NoFeesToWithdraw();
    error NodeExists(uint256 nodeId); // Should not happen with counter, but good practice
    error ConnectionExists(uint256 connectionId); // Should not happen with counter

    // --- Enums ---
    enum NodeState {
        Inactive,       // Node exists but is not actively participating
        Active,         // Node is fully participating
        Quarantined,    // Node has issues, limited participation
        Destroyed       // Node is marked for removal (internal state)
    }

    enum ConnectionType {
        Trust,          // Represents trust or endorsement
        DataFlow,       // Represents data link or information source
        Influence,      // Represents influence or control flow
        AttestationLink // Represents a link for attestation propagation
    }

    // --- Structs ---
    struct Node {
        uint256 id;
        address owner;
        NodeState state;
        uint256 stakeAmount; // Total ETH staked to this node
        int256 score;       // Dynamic score/reputation
        uint64 creationTime; // Timestamp
        bool exists;        // To handle "deletion" without array issues
    }

    struct Connection {
        uint256 id;
        uint256 fromNodeId;
        uint256 toNodeId;
        uint256 weight;         // Strength or capacity of the connection
        ConnectionType connectionType;
        uint64 creationTime;    // Timestamp
        bool exists;            // To handle "deletion"
    }

    struct SystemParameters {
        uint256 nodeCreationCost;       // Energy cost to create a node
        uint256 connectionCreationCost; // Energy cost to create a connection
        uint256 attestationCost;        // Energy cost to make an attestation
        uint256 stakeWithdrawalCost;    // Energy cost to withdraw stake
        uint256 nodeStateUpdateCost;    // Energy cost to change node state
        uint256 connectionUpdateCost;   // Energy cost to update connection
        uint256 nodeTransferCost;       // Energy cost to transfer node ownership
        uint256 nodeDestructionCost;    // Energy cost to destroy node
        uint256 connectionDestructionCost; // Energy cost to destroy connection
        uint256 queryPathBaseCost;      // Base energy cost for path query
        uint256 queryPathCostPerHop;    // Additional energy cost per hop in path query
        uint256 maxPathQueryDepth;      // Max depth for path queries
        uint256 influencePropagationBaseCost; // Base energy cost for influence simulation
        uint256 influencePropagationCostPerHop; // Additional energy cost per hop for influence
        uint256 maxInfluencePropagationDepth; // Max depth for influence simulation
        uint256 decayRatePerSecond;     // Weight decay rate (applied per second, * 1e18 for precision)
        uint256 decayProcessingCost;    // Energy cost to process decay on a connection
        uint256 scoreUpdateCost;        // Energy cost to manually update a node's score
        uint256 synthesizeEssenceCost;  // High energy cost for synthesizing a new node
        uint256 synthesizeEssenceMinSources; // Minimum source nodes for synthesis
    }

    // --- State Variables ---
    address public immutable owner;

    mapping(uint256 => Node) private nodes;
    mapping(uint256 => Connection) private connections;

    // Store connection IDs originating/terminating at a node
    mapping(uint256 => uint256[]) private nodeOutConnectionIds;
    mapping(uint256 => uint256[]) private nodeInConnectionIds;

    mapping(address => uint256) private energyBalances;

    // node ID => attestor address => claims (string can be costly, consider bytes32 hash in production)
    mapping(uint256 => mapping(address => string[])) private attestations;

    // node ID => staker address => staked amount
    mapping(uint256 => mapping(address => uint256)) private nodeStakes;
    mapping(uint256 => uint256) private nodeTotalStakes; // Redundant sum for convenience

    uint256 private nodeCounter = 0; // Starts at 1
    uint256 private connectionCounter = 0; // Starts at 1

    SystemParameters public systemParameters;

    uint256 public protocolFees = 0;

    // --- Events ---
    event NodeCreated(uint256 indexed nodeId, address indexed owner, uint64 creationTime);
    event NodeStateUpdated(uint256 indexed nodeId, NodeState newState);
    event NodeOwnershipTransferred(uint256 indexed nodeId, address indexed oldOwner, address indexed newOwner);
    event NodeDestroyed(uint256 indexed nodeId);
    event NodeStaked(uint256 indexed nodeId, address indexed staker, uint256 amount);
    event NodeStakeWithdrawn(uint256 indexed nodeId, address indexed staker, uint256 amount);

    event ConnectionCreated(uint256 indexed connectionId, uint256 indexed fromNodeId, uint256 indexed toNodeId, ConnectionType connectionType, uint256 weight, uint64 creationTime);
    event ConnectionUpdated(uint256 indexed connectionId, uint256 newWeight, ConnectionType newType);
    event ConnectionDestroyed(uint256 indexed connectionId);

    event EnergyMinted(address indexed recipient, uint256 amount);
    event EnergyTransferred(address indexed from, address indexed to, uint256 amount);
    event EnergyBurned(address indexed burner, uint256 amount);

    event AttestationMade(uint256 indexed nodeId, address indexed attestor, string claim);

    event ParameterUpdated(string name, uint256 value);

    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    modifier requiresEnergy(uint256 amount) {
        if (energyBalances[msg.sender] < amount) {
            revert InsufficientEnergy(amount, energyBalances[msg.sender]);
        }
        unchecked { energyBalances[msg.sender] -= amount; }
        _;
    }

    modifier nodeExists(uint256 _nodeId) {
        if (!nodes[_nodeId].exists) revert NodeNotFound(_nodeId);
        _;
    }

    modifier connectionExists(uint256 _connectionId) {
        if (!connections[_connectionId].exists) revert ConnectionNotFound(_connectionId);
        _;
    }

    // --- Constructor ---
    constructor(SystemParameters memory initialParams) {
        owner = msg.sender;
        systemParameters = initialParams;

        // Basic validation for initial parameters
        if (initialParams.maxPathQueryDepth == 0 || initialParams.maxInfluencePropagationDepth == 0 || initialParams.synthesizeEssenceMinSources == 0) {
             // Simple check, add more robust validation as needed
             revert InvalidParameterValue();
        }
         if (initialParams.decayRatePerSecond > 1e18) { // Decay rate shouldn't be > 100% per second
             revert InvalidParameterValue();
         }
    }

    // --- 1. Initialization & Parameters ---

    /// @notice Updates a specific system parameter. Callable only by owner.
    /// @param paramName The name of the parameter to update (string).
    /// @param newValue The new value for the parameter.
    function updateSystemParameter(string calldata paramName, uint256 newValue) external onlyOwner {
        bytes memory paramNameBytes = bytes(paramName);

        if (keccak256(paramNameBytes) == keccak256("nodeCreationCost")) systemParameters.nodeCreationCost = newValue;
        else if (keccak256(paramNameBytes) == keccak256("connectionCreationCost")) systemParameters.connectionCreationCost = newValue;
        else if (keccak256(paramNameBytes) == keccak256("attestationCost")) systemParameters.attestationCost = newValue;
        else if (keccak256(paramNameBytes) == keccak256("stakeWithdrawalCost")) systemParameters.stakeWithdrawalCost = newValue;
        else if (keccak256(paramNameBytes) == keccak256("nodeStateUpdateCost")) systemParameters.nodeStateUpdateCost = newValue;
        else if (keccak256(paramNameBytes) == keccak256("connectionUpdateCost")) systemParameters.connectionUpdateCost = newValue;
        else if (keccak256(paramNameBytes) == keccak256("nodeTransferCost")) systemParameters.nodeTransferCost = newValue;
        else if (keccak256(paramNameBytes) == keccak256("nodeDestructionCost")) systemParameters.nodeDestructionCost = newValue;
        else if (keccak256(paramNameBytes) == keccak256("connectionDestructionCost")) systemParameters.connectionDestructionCost = newValue;
        else if (keccak256(paramNameBytes) == keccak256("queryPathBaseCost")) systemParameters.queryPathBaseCost = newValue;
        else if (keccak256(paramNameBytes) == keccak256("queryPathCostPerHop")) systemParameters.queryPathCostPerHop = newValue;
        else if (keccak256(paramNameBytes) == keccak256("maxPathQueryDepth")) {
            if (newValue == 0) revert InvalidParameterValue();
            systemParameters.maxPathQueryDepth = newValue;
        }
        else if (keccak256(paramNameBytes) == keccak256("influencePropagationBaseCost")) systemParameters.influencePropagationBaseCost = newValue;
        else if (keccak256(paramNameBytes) == keccak256("influencePropagationCostPerHop")) systemParameters.influencePropagationCostPerHop = newValue;
        else if (keccak256(paramNameBytes) == keccak256("maxInfluencePropagationDepth")) {
             if (newValue == 0) revert InvalidParameterValue();
             systemParameters.maxInfluencePropagationDepth = newValue;
        }
        else if (keccak256(paramNameBytes) == keccak256("decayRatePerSecond")) {
            if (newValue > 1e18) revert InvalidParameterValue(); // Max 100% decay/sec
            systemParameters.decayRatePerSecond = newValue;
        }
        else if (keccak256(paramNameBytes) == keccak256("decayProcessingCost")) systemParameters.decayProcessingCost = newValue;
        else if (keccak256(paramNameBytes) == keccak256("scoreUpdateCost")) systemParameters.scoreUpdateCost = newValue;
         else if (keccak256(paramNameBytes) == keccak256("synthesizeEssenceCost")) systemParameters.synthesizeEssenceCost = newValue;
         else if (keccak256(paramNameBytes) == keccak256("synthesizeEssenceMinSources")) {
             if (newValue == 0) revert InvalidParameterValue();
             systemParameters.synthesizeEssenceMinSources = newValue;
         }

        else revert InvalidParameterValue(); // Unknown parameter name

        emit ParameterUpdated(paramName, newValue);
    }


    // --- 2. Energy Management ---

    /// @notice Mints Energy tokens to a recipient. Callable only by owner.
    /// @param recipient The address to receive the minted energy.
    /// @param amount The amount of energy to mint.
    function mintEnergy(address recipient, uint256 amount) external onlyOwner {
        energyBalances[recipient] += amount;
        emit EnergyMinted(recipient, amount);
    }

    /// @notice Transfers Energy tokens from the caller to another address.
    /// @param to The address to send the energy to.
    /// @param amount The amount of energy to transfer.
    function transferEnergy(address to, uint256 amount) external requiresEnergy(amount) {
        energyBalances[to] += amount;
        emit EnergyTransferred(msg.sender, to, amount);
    }

    /// @notice Burns Energy tokens from the caller's balance.
    /// @param amount The amount of energy to burn.
    function burnEnergy(uint256 amount) external requiresEnergy(amount) {
        // Energy already deducted by modifier
        emit EnergyBurned(msg.sender, amount);
    }

    /// @notice Gets the Energy balance of an address.
    /// @param account The address to check.
    /// @return The energy balance of the account.
    function getEnergyBalance(address account) external view returns (uint256) {
        return energyBalances[account];
    }


    // --- 3. Node Management ---

    /// @notice Creates a new Node in the network.
    /// @return The ID of the newly created node.
    function createNode() external requiresEnergy(systemParameters.nodeCreationCost) returns (uint256) {
        nodeCounter++;
        uint256 newNodeId = nodeCounter;
        uint64 currentTime = uint64(block.timestamp);

        nodes[newNodeId] = Node({
            id: newNodeId,
            owner: msg.sender,
            state: NodeState.Active, // Default state
            stakeAmount: 0,
            score: 0, // Initial score
            creationTime: currentTime,
            exists: true
        });

        emit NodeCreated(newNodeId, msg.sender, currentTime);
        return newNodeId;
    }

    /// @notice Updates the state of a Node. Only callable by the Node's owner.
    /// @param nodeId The ID of the node to update.
    /// @param newState The new state for the node.
    function updateNodeState(uint256 nodeId, NodeState newState) external requiresEnergy(systemParameters.nodeStateUpdateCost) nodeExists(nodeId) {
        Node storage node = nodes[nodeId];
        if (node.owner != msg.sender) revert NotNodeOwner(nodeId, msg.sender);
        if (uint8(newState) > uint8(NodeState.Destroyed)) revert InvalidNodeState(); // Prevent setting to invalid enum value

        // Cannot change state if marked as destroyed internally
        if (node.state == NodeState.Destroyed) revert NodeNotFound(nodeId); // Use NodeNotFound as it's effectively deleted

        node.state = newState;
        emit NodeStateUpdated(nodeId, newState);
    }

    /// @notice Transfers ownership of a Node to another address. Only callable by the current Node owner.
    /// @param nodeId The ID of the node to transfer.
    /// @param newOwner The address of the new owner.
    function transferNodeOwnership(uint256 nodeId, address newOwner) external requiresEnergy(systemParameters.nodeTransferCost) nodeExists(nodeId) {
        Node storage node = nodes[nodeId];
        if (node.owner != msg.sender) revert NotNodeOwner(nodeId, msg.sender);
         // Cannot transfer if marked as destroyed internally
        if (node.state == NodeState.Destroyed) revert NodeNotFound(nodeId); // Use NodeNotFound as it's effectively deleted

        node.owner = newOwner;
        emit NodeOwnershipTransferred(nodeId, msg.sender, newOwner);
    }

    /// @notice Destroys a Node and removes all its connections. Only callable by the Node's owner.
    /// @dev Note: This is a logical delete by marking `exists = false`. Associated connections/stakes are cleared.
    /// @param nodeId The ID of the node to destroy.
    function destroyNode(uint256 nodeId) external requiresEnergy(systemParameters.nodeDestructionCost) nodeExists(nodeId) {
        Node storage node = nodes[nodeId];
        if (node.owner != msg.sender) revert NotNodeOwner(nodeId, msg.sender);

        // Cannot destroy if already marked as destroyed
        if (node.state == NodeState.Destroyed) revert NodeNotFound(nodeId); // Use NodeNotFound as it's effectively deleted

        // Clear associated connections (logical delete)
        uint256[] memory outConnections = nodeOutConnectionIds[nodeId];
        for (uint i = 0; i < outConnections.length; i++) {
            uint256 connId = outConnections[i];
            if (connections[connId].exists) {
                connections[connId].exists = false;
                // Note: Removing from nodeInConnectionIds of the target node is more complex
                // and skipped here to avoid expensive array operations. Querying should filter by exists=true.
                // In a production system, a more robust indexing/deletion strategy would be needed.
            }
        }
        delete nodeOutConnectionIds[nodeId]; // Clear the list for this node

        uint256[] memory inConnections = nodeInConnectionIds[nodeId];
         for (uint i = 0; i < inConnections.length; i++) {
            uint256 connId = inConnections[i];
            if (connections[connId].exists) {
                 connections[connId].exists = false;
                 // Note: Removing from nodeOutConnectionIds of the source node skipped for gas.
            }
         }
         delete nodeInConnectionIds[nodeId]; // Clear the list for this node

        // Clear stakes
        // Note: Iterating all stakers is not feasible on-chain. A system
        // where stakers withdraw before destruction, or a separate stake
        // contract is used, would be better. Here we just zero out the total.
        // Individual stake amounts persist in the mapping but are effectively orphaned.
        delete nodeStakes[nodeId]; // Clears mapping for this node
        nodeTotalStakes[nodeId] = 0;

        // Mark node as destroyed
        node.state = NodeState.Destroyed; // Mark as destroyed internally
        node.exists = false; // Primary existence flag

        emit NodeDestroyed(nodeId);
    }


    /// @notice Stakes ETH to a Node. Adds to the Node's influence/score potential.
    /// @param nodeId The ID of the node to stake to.
    function stakeToNode(uint256 nodeId) external payable nodeExists(nodeId) {
        if (msg.value == 0) return; // No value sent

         // Cannot stake to a destroyed node
        if (nodes[nodeId].state == NodeState.Destroyed) revert NodeNotFound(nodeId); // Use NodeNotFound as it's effectively deleted

        nodeStakes[nodeId][msg.sender] += msg.value;
        nodeTotalStakes[nodeId] += msg.value;

        // Optionally trigger a score update or flag for score recalculation
        // _updateNodeScore(nodeId); // Could be done here, or triggered separately

        emit NodeStaked(nodeId, msg.sender, msg.value);
    }

    /// @notice Withdraws staked ETH from a Node.
    /// @param nodeId The ID of the node to withdraw from.
    /// @param amount The amount of ETH to withdraw.
    function withdrawStakeFromNode(uint256 nodeId, uint256 amount) external requiresEnergy(systemParameters.stakeWithdrawalCost) nodeExists(nodeId) {
         // Cannot withdraw from a destroyed node
        if (nodes[nodeId].state == NodeState.Destroyed) revert NodeNotFound(nodeId); // Use NodeNotFound as it's effectively deleted

        if (nodeStakes[nodeId][msg.sender] < amount) {
            revert InsufficientStake(nodeId, msg.sender, amount, nodeStakes[nodeId][msg.sender]);
        }

        unchecked {
            nodeStakes[nodeId][msg.sender] -= amount;
            nodeTotalStakes[nodeId] -= amount;
        }

        // Transfer ETH to the staker
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "ETH transfer failed"); // Standard check

        // Optionally trigger a score update
        // _updateNodeScore(nodeId);

        emit NodeStakeWithdrawn(nodeId, msg.sender, amount);
    }

    /// @notice Retrieves details of a specific Node.
    /// @param nodeId The ID of the node to query.
    /// @return nodeData A tuple containing the node's details.
    function getNodeDetails(uint256 nodeId) external view nodeExists(nodeId) returns (
        uint256 id,
        address owner,
        NodeState state,
        uint256 stakeAmount,
        int256 score,
        uint64 creationTime
    ) {
         // Cannot get details if marked as destroyed internally
        if (nodes[nodeId].state == NodeState.Destroyed) revert NodeNotFound(nodeId); // Use NodeNotFound as it's effectively deleted

        Node storage node = nodes[nodeId];
        return (
            node.id,
            node.owner,
            node.state,
            node.stakeAmount,
            node.score,
            node.creationTime
        );
    }


    // --- 4. Connection Management ---

    /// @notice Creates a directed connection between two Nodes.
    /// @param fromNodeId The ID of the source node.
    /// @param toNodeId The ID of the target node.
    /// @param connectionType The type of the connection.
    /// @param weight The initial weight of the connection.
    /// @return The ID of the newly created connection.
    function createConnection(uint256 fromNodeId, uint256 toNodeId, ConnectionType connectionType, uint256 weight)
        external
        requiresEnergy(systemParameters.connectionCreationCost)
        nodeExists(fromNodeId)
        nodeExists(toNodeId)
        returns (uint256)
    {
        if (fromNodeId == toNodeId) revert SelfConnectionNotAllowed();
         if (uint8(connectionType) > uint8(ConnectionType.AttestationLink)) revert InvalidConnectionType();

         // Cannot connect to/from destroyed nodes
        if (nodes[fromNodeId].state == NodeState.Destroyed) revert NodeNotFound(fromNodeId);
        if (nodes[toNodeId].state == NodeState.Destroyed) revert NodeNotFound(toNodeId);


        connectionCounter++;
        uint256 newConnectionId = connectionCounter;
        uint64 currentTime = uint64(block.timestamp);

        connections[newConnectionId] = Connection({
            id: newConnectionId,
            fromNodeId: fromNodeId,
            toNodeId: toNodeId,
            weight: weight,
            connectionType: connectionType,
            creationTime: currentTime,
            exists: true
        });

        nodeOutConnectionIds[fromNodeId].push(newConnectionId);
        nodeInConnectionIds[toNodeId].push(newConnectionId);

        emit ConnectionCreated(newConnectionId, fromNodeId, toNodeId, connectionType, weight, currentTime);
        return newConnectionId;
    }

    /// @notice Updates the weight of a Connection. Only callable by the owner of the source node.
    /// @param connectionId The ID of the connection to update.
    /// @param newWeight The new weight for the connection.
    function updateConnectionWeight(uint256 connectionId, uint256 newWeight) external requiresEnergy(systemParameters.connectionUpdateCost) connectionExists(connectionId) {
        Connection storage conn = connections[connectionId];
        // Only source node owner can update weight
        if (nodes[conn.fromNodeId].owner != msg.sender) revert NotNodeOwner(conn.fromNodeId, msg.sender);

         // Cannot update if connection is logically destroyed
        if (!conn.exists) revert ConnectionNotFound(connectionId);

        conn.weight = newWeight;
        // Optionally update creationTime or lastUpdated time to reset decay timer
        conn.creationTime = uint64(block.timestamp); // Reset decay timer

        emit ConnectionUpdated(connectionId, newWeight, conn.connectionType);
    }

    /// @notice Updates the type of a Connection. Only callable by the owner of the source node.
    /// @param connectionId The ID of the connection to update.
    /// @param newType The new type for the connection.
    function updateConnectionType(uint256 connectionId, ConnectionType newType) external requiresEnergy(systemParameters.connectionUpdateCost) connectionExists(connectionId) {
        Connection storage conn = connections[connectionId];
        // Only source node owner can update type
        if (nodes[conn.fromNodeId].owner != msg.sender) revert NotNodeOwner(conn.fromNodeId, msg.sender);
        if (uint8(newType) > uint8(ConnectionType.AttestationLink)) revert InvalidConnectionType();

        // Cannot update if connection is logically destroyed
        if (!conn.exists) revert ConnectionNotFound(connectionId);

        conn.connectionType = newType;
        // Optionally update creationTime or lastUpdated time
        conn.creationTime = uint64(block.timestamp); // Reset decay timer

        emit ConnectionUpdated(connectionId, conn.weight, newType);
    }


    /// @notice Destroys a Connection. Callable by the owner of either the source or target node.
    /// @dev Note: This is a logical delete by marking `exists = false`. Does *not* clean up nodeOut/InConnectionIds arrays for gas efficiency. Queries must filter by `exists`.
    /// @param connectionId The ID of the connection to destroy.
    function destroyConnection(uint256 connectionId) external requiresEnergy(systemParameters.connectionDestructionCost) connectionExists(connectionId) {
        Connection storage conn = connections[connectionId];

        // Callable by owner of either source or target node
        bool isOwner = (nodes[conn.fromNodeId].exists && nodes[conn.fromNodeId].owner == msg.sender) ||
                       (nodes[conn.toNodeId].exists && nodes[conn.toNodeId].owner == msg.sender);

        if (!isOwner) revert NodeNotFound(0); // Revert with generic error if neither owner

        // Cannot destroy if already logically destroyed
        if (!conn.exists) revert ConnectionNotFound(connectionId);

        conn.exists = false; // Logical delete

        // Note: We don't clean up the nodeOutConnectionIds or nodeInConnectionIds arrays here
        // to save gas. This means they might contain IDs of non-existent connections.
        // Functions iterating these arrays MUST check `connections[connId].exists`.
        // A future version might implement a cleanup mechanism (e.g., via governance or user incentives).

        emit ConnectionDestroyed(connectionId);
    }

    /// @notice Retrieves details of a specific Connection.
    /// @param connectionId The ID of the connection to query.
    /// @return connectionData A tuple containing the connection's details.
    function getConnectionDetails(uint256 connectionId) external view connectionExists(connectionId) returns (
        uint256 id,
        uint256 fromNodeId,
        uint256 toNodeId,
        uint256 weight,
        ConnectionType connectionType,
        uint64 creationTime
    ) {
         // Cannot get details if connection is logically destroyed
        if (!connections[connectionId].exists) revert ConnectionNotFound(connectionId);

        Connection storage conn = connections[connectionId];
        return (
            conn.id,
            conn.fromNodeId,
            conn.toNodeId,
            conn.weight,
            conn.connectionType,
            conn.creationTime
        );
    }


    // --- 5. Attestation System ---

    /// @notice Allows an address to make a string-based claim about a Node.
    /// @dev Note: Storing arbitrary strings is gas-intensive. In production, use bytes32 hashes of claims or a predefined registry.
    /// @param nodeId The ID of the node being attested about.
    /// @param claim The string representation of the attestation/claim.
    function attestToNode(uint256 nodeId, string calldata claim) external requiresEnergy(systemParameters.attestationCost) nodeExists(nodeId) {
        // Cannot attest to a destroyed node
        if (nodes[nodeId].state == NodeState.Destroyed) revert NodeNotFound(nodeId);

        attestations[nodeId][msg.sender].push(claim);

        // Attestations could influence score, potentially trigger update here
        // _updateNodeScore(nodeId);

        emit AttestationMade(nodeId, msg.sender, claim);
    }

    /// @notice Retrieves all attestations made about a specific Node.
    /// @param nodeId The ID of the node to query attestations for.
    /// @return A mapping from attestor address to an array of their claims (strings).
    function getAttestationsForNode(uint256 nodeId) external view nodeExists(nodeId) returns (mapping(address => string[]) storage) {
         // Cannot get attestations for a destroyed node
        if (nodes[nodeId].state == NodeState.Destroyed) revert NodeNotFound(nodeId);

        // Note: Returning storage mapping directly is fine for view functions
        return attestations[nodeId];
    }


    // --- 6. Network Query & Analysis ---

    /// @notice Computes a dynamic score for a Node based on its attributes, stake, connections, and attestations.
    /// @dev This is a simplified example score calculation. Real logic could be much more complex.
    /// @param nodeId The ID of the node to score.
    /// @return The computed integer score.
    function getNodeScore(uint256 nodeId) public view nodeExists(nodeId) returns (int256) {
         // Cannot score a destroyed node
        if (nodes[nodeId].state == NodeState.Destroyed) revert NodeNotFound(nodeId);

        Node storage node = nodes[nodeId];
        int256 score = 0;

        // Base score based on state
        if (node.state == NodeState.Active) score += 100;
        else if (node.state == NodeState.Quarantined) score -= 50;
        // Inactive state gets base 0

        // Influence of staked ETH (scaled)
        score += int256(node.stakeAmount / 1 ether); // 1 score point per staked ETH (example scaling)

        // Influence from incoming connections (e.g., Trust, Influence types)
        uint256[] memory inConnections = nodeInConnectionIds[nodeId];
        for (uint i = 0; i < inConnections.length; i++) {
            uint256 connId = inConnections[i];
            Connection storage conn = connections[connId];
            // Check if connection exists and source node exists/is active
            if (conn.exists && nodes[conn.fromNodeId].exists && nodes[conn.fromNodeId].state == NodeState.Active) {
                if (conn.connectionType == ConnectionType.Trust) score += int256(conn.weight / 10); // Trust adds positively
                else if (conn.connectionType == ConnectionType.Influence) score += int256(conn.weight / 5); // Influence adds more
                 // DataFlow, AttestationLink might not directly impact score this way
            }
        }

        // Influence from outgoing connections (e.g., DataFlow, Influence types spreading out)
         uint256[] memory outConnections = nodeOutConnectionIds[nodeId];
         for (uint i = 0; i < outConnections.length; i++) {
             uint256 connId = outConnections[i];
             Connection storage conn = connections[connId];
              // Check if connection exists and target node exists/is active
             if (conn.exists && nodes[conn.toNodeId].exists && nodes[conn.toNodeId].state == NodeState.Active) {
                 if (conn.connectionType == ConnectionType.DataFlow) score += int256(conn.weight / 20); // Having data links adds slightly
                  else if (conn.connectionType == ConnectionType.Influence) score -= int256(conn.weight / 10); // Outgoing influence might cost score? (example logic)
             }
         }

        // Influence from attestations (simple count example)
        // Note: Iterating mappings is not possible. This needs helper storage or is omitted.
        // For simplicity here, we'll skip attestation influence unless attestations were stored differently.
        // A production contract would need to track attestation counts or aggregate scores separately.

        return score;
    }

    /// @notice Retrieves the IDs of nodes that the given node has outgoing connections to.
    /// @param fromNodeId The ID of the source node.
    /// @return An array of target Node IDs. Filters out destroyed connections.
    function getConnectedNodes(uint256 fromNodeId) external view nodeExists(fromNodeId) returns (uint256[] memory) {
        // Cannot query connections for a destroyed node
        if (nodes[fromNodeId].state == NodeState.Destroyed) revert NodeNotFound(fromNodeId);

        uint256[] memory connIds = nodeOutConnectionIds[fromNodeId];
        uint256[] memory connectedNodeIds = new uint256[](connIds.length); // Max size, will resize
        uint256 count = 0;

        for (uint i = 0; i < connIds.length; i++) {
            uint256 connId = connIds[i];
            if (connections[connId].exists) { // Filter out logically destroyed connections
                connectedNodeIds[count] = connections[connId].toNodeId;
                count++;
            }
        }

        // Resize the array to actual count
        uint256[] memory result = new uint256[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = connectedNodeIds[i];
        }
        return result;
    }

     /// @notice Retrieves the IDs of nodes that have incoming connections to the given node.
     /// @param toNodeId The ID of the target node.
     /// @return An array of source Node IDs. Filters out destroyed connections.
     function getConnectingNodes(uint256 toNodeId) external view nodeExists(toNodeId) returns (uint256[] memory) {
         // Cannot query connections for a destroyed node
        if (nodes[toNodeId].state == NodeState.Destroyed) revert NodeNotFound(toNodeId);

         uint256[] memory connIds = nodeInConnectionIds[toNodeId];
         uint256[] memory connectingNodeIds = new uint256[](connIds.length); // Max size, will resize
         uint256 count = 0;

         for (uint i = 0; i < connIds.length; i++) {
             uint256 connId = connIds[i];
             if (connections[connId].exists) { // Filter out logically destroyed connections
                 connectingNodeIds[count] = connections[connId].fromNodeId;
                 count++;
             }
         }

         // Resize the array
         uint256[] memory result = new uint256[](count);
         for (uint i = 0; i < count; i++) {
             result[i] = connectingNodeIds[i];
         }
         return result;
     }

    /// @notice Retrieves details of all existing connections between two specific nodes (from -> to).
    /// @param fromNodeId The ID of the source node.
    /// @param toNodeId The ID of the target node.
    /// @return An array of Connection structs between the two nodes. Filters out destroyed connections.
    function getConnectionsBetween(uint256 fromNodeId, uint256 toNodeId) external view nodeExists(fromNodeId) nodeExists(toNodeId) returns (Connection[] memory) {
        // Cannot query connections if either node is destroyed
        if (nodes[fromNodeId].state == NodeState.Destroyed) revert NodeNotFound(fromNodeId);
        if (nodes[toNodeId].state == NodeState.Destroyed) revert NodeNotFound(toNodeId);

        uint224[] memory connIds = new uint224[](nodeOutConnectionIds[fromNodeId].length); // Use smaller type for temp storage
        uint256 tempCount = 0;

        // First pass to find relevant, existing connection IDs
        for (uint i = 0; i < nodeOutConnectionIds[fromNodeId].length; i++) {
            uint256 connId = nodeOutConnectionIds[fromNodeId][i];
            // Check existence first
            if (connections[connId].exists) {
                Connection storage conn = connections[connId];
                if (conn.toNodeId == toNodeId) {
                    connIds[tempCount] = uint224(connId); // Store ID
                    tempCount++;
                }
            }
        }

        // Create result array and populate with details
        Connection[] memory result = new Connection[](tempCount);
        for (uint i = 0; i < tempCount; i++) {
            uint256 connId = uint256(connIds[i]);
             // Retrieve and copy details
            result[i] = connections[connId];
        }

        return result;
    }


    /// @notice **Advanced:** Checks if a path exists between a source and target node within a maximum depth.
    /// @dev This is a simplified BFS/DFS simulation. Gas cost scales with depth and branching factor.
    /// @param startNodeId The starting node ID.
    /// @param endNodeId The target node ID.
    /// @param maxDepth The maximum number of hops to search.
    /// @return True if a path is found, false otherwise.
    function queryPathExistence(uint256 startNodeId, uint256 endNodeId, uint256 maxDepth)
        external
        requiresEnergy(systemParameters.queryPathBaseCost + systemParameters.queryPathCostPerHop * maxDepth)
        nodeExists(startNodeId)
        nodeExists(endNodeId)
        returns (bool)
    {
        if (startNodeId == endNodeId) return true;
        if (maxDepth == 0) return false;
        if (maxDepth > systemParameters.maxPathQueryDepth) revert PathQueryDepthTooHigh(systemParameters.maxPathQueryDepth);

        // Cannot query path if either node is destroyed
        if (nodes[startNodeId].state == NodeState.Destroyed) revert NodeNotFound(startNodeId);
        if (nodes[endNodeId].state == NodeState.Destroyed) revert NodeNotFound(endNodeId);


        // Simple BFS simulation
        uint256[] memory queue = new uint256[](nodeCounter); // Max nodes possible
        mapping(uint256 => uint256) visitedDepths; // Node ID => Depth visited

        queue[0] = startNodeId;
        visitedDepths[startNodeId] = 1; // Start at depth 1
        uint256 head = 0;
        uint256 tail = 1; // Next available slot in queue

        while (head < tail) {
            uint256 currentNodeId = queue[head];
            head++;
            uint256 currentDepth = visitedDepths[currentNodeId];

            if (currentDepth > maxDepth) continue; // Stop exploring beyond max depth

            uint256[] memory outConnIds = nodeOutConnectionIds[currentNodeId];
            for (uint i = 0; i < outConnIds.length; i++) {
                uint256 connId = outConnIds[i];
                 // Check if connection exists and target node exists/is not destroyed
                if (connections[connId].exists && nodes[connections[connId].toNodeId].exists && nodes[connections[connId].toNodeId].state != NodeState.Destroyed) {
                    uint256 neighborNodeId = connections[connId].toNodeId;

                    if (neighborNodeId == endNodeId) {
                        // Path found! Gas cost is already estimated/required upfront.
                        return true;
                    }

                    // Visit if not visited or found shorter path
                    if (visitedDepths[neighborNodeId] == 0 || visitedDepths[neighborNodeId] > currentDepth + 1) {
                         // Prevent queue overflow in case of very dense graphs, although size is capped by nodeCounter
                         if (tail >= nodeCounter) continue; // Skip if queue is full (shouldn't happen with nodeCounter limit)

                        visitedDepths[neighborNodeId] = currentDepth + 1;
                        queue[tail] = neighborNodeId;
                        tail++;
                    }
                }
            }
        }

        return false; // No path found within max depth
    }


     /// @notice **Advanced/Creative:** Simulates influence propagation from a source node through connections, potentially updating scores or states.
     /// @dev This is a conceptual simulation within the contract. The logic is simplified.
     /// Gas cost is significant and scales with depth and branching factor.
     /// @param startNodeId The node from which influence originates.
     /// @param maxDepth The maximum depth for propagation.
     /// @param influenceType An identifier for the type of influence (e.g., 1 for positive, 2 for negative).
     /// @param initialStrength The starting strength of the influence.
     function simulateInfluencePropagation(uint256 startNodeId, uint256 maxDepth, uint8 influenceType, int256 initialStrength)
         external
         requiresEnergy(systemParameters.influencePropagationBaseCost + systemParameters.influencePropagationCostPerHop * maxDepth)
         nodeExists(startNodeId)
     {
         if (maxDepth == 0 || initialStrength == 0) return;
         if (maxDepth > systemParameters.maxInfluencePropagationDepth) revert InfluencePropagationDepthTooHigh(systemParameters.maxInfluencePropagationDepth);

         // Cannot propagate from a destroyed node
        if (nodes[startNodeId].state == NodeState.Destroyed) revert NodeNotFound(startNodeId);


         // Simple propagation simulation (e.g., BFS-like traversal)
         mapping(uint256 => uint256) visitedDepths;
         mapping(uint256 => int256) propagatedStrengths; // Node ID => Influence Strength received
         uint256[] memory queue = new uint256[](nodeCounter); // Max nodes possible

         queue[0] = startNodeId;
         visitedDepths[startNodeId] = 1;
         propagatedStrengths[startNodeId] = initialStrength; // Influence starts at the source
         uint256 head = 0;
         uint256 tail = 1;

         while (head < tail) {
             uint256 currentNodeId = queue[head];
             head++;
             uint256 currentDepth = visitedDepths[currentNodeId];
             int256 currentStrength = propagatedStrengths[currentNodeId];

             if (currentDepth > maxDepth || currentStrength == 0) continue;

             // Influence logic: How does this node's influence affect itself? (Optional)
             // nodes[currentNodeId].score += currentStrength; // Example: Add influence to score

             uint256[] memory outConnIds = nodeOutConnectionIds[currentNodeId];
             for (uint i = 0; i < outConnIds.length; i++) {
                 uint256 connId = outConnIds[i];
                  // Check if connection exists and target node exists/is not destroyed
                 if (connections[connId].exists && nodes[connections[connId].toNodeId].exists && nodes[connections[connId].toNodeId].state != NodeState.Destroyed) {
                     Connection storage conn = connections[connId];
                     uint256 neighborNodeId = conn.toNodeId;

                     // Calculate influence passed to neighbor
                     int256 influencePassed = 0;
                     // Simplified rule: influence strength modified by connection weight and type
                     if (influenceType == 1 && conn.connectionType == ConnectionType.Influence) { // Positive influence via Influence link
                         influencePassed = (currentStrength * int256(conn.weight)) / 1000; // Example scaling
                     } else if (influenceType == 2 && conn.connectionType == ConnectionType.Trust) { // Negative influence via Trust link? (Example)
                         influencePassed = -(currentStrength * int256(conn.weight)) / 500; // Example scaling
                     }
                     // Add more complex rules based on conn.connectionType, weight, influenceType, etc.

                     if (influencePassed != 0) {
                         // Apply influence to neighbor's score or state
                         nodes[neighborNodeId].score += influencePassed; // Example: Update score

                         // Enqueue neighbor for further propagation if within depth and hasn't received stronger influence yet
                         if (currentDepth + 1 <= maxDepth) {
                             // Check if visited, and if new path offers stronger combined influence
                             // (More complex than simple BFS visited check, could track max strength received)
                             // For simplicity here, we'll just add to the queue if within depth and not yet visited at this depth
                            if (visitedDepths[neighborNodeId] == 0 || visitedDepths[neighborNodeId] > currentDepth + 1) {
                                // Prevent queue overflow
                                if (tail >= nodeCounter) continue;

                                 visitedDepths[neighborNodeId] = currentDepth + 1;
                                 propagatedStrengths[neighborNodeId] = influencePassed; // Strength passed becomes starting point for neighbor
                                 queue[tail] = neighborNodeId;
                                 tail++;
                            }
                         }
                     }
                 }
             }
         }
         // Note: Actual state changes (like score updates) are permanent on-chain.
         // A true simulation might return results instead of changing state. This example
         // changes state to demonstrate the concept.
     }

    /// @notice Retrieves the IDs of nodes whose score falls within a specified range.
    /// @dev Iterating through all nodes can be gas-intensive. This function might fail for large networks.
    /// Consider implementing pagination or off-chain indexing for production systems.
    /// @param minScore The minimum score (inclusive).
    /// @param maxScore The maximum score (inclusive).
    /// @return An array of node IDs within the score range.
    function getNodesByScoreRange(int256 minScore, int256 maxScore) external view returns (uint256[] memory) {
        uint256[] memory matchedNodeIds = new uint256[](nodeCounter); // Max possible size
        uint256 count = 0;

        // Iterate through potential node IDs from 1 to nodeCounter
        // NOTE: This iteration pattern is gas-heavy for sparse node IDs or large nodeCounter.
        // A production system would need a better way to list/index active node IDs.
        for (uint256 i = 1; i <= nodeCounter; i++) {
            // Check existence first
            if (nodes[i].exists && nodes[i].state != NodeState.Destroyed) {
                 // Call getNodeScore, which also checks existence and state
                 int256 score = getNodeScore(i); // Reverts if node not found or destroyed

                 if (score >= minScore && score <= maxScore) {
                     matchedNodeIds[count] = i;
                     count++;
                 }
            }
        }

        // Resize the array
        uint256[] memory result = new uint256[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = matchedNodeIds[i];
        }
        return result;
    }


    // --- 7. Advanced Network Dynamics ---

     /// @notice **Creative:** Synthesizes a *new* Node whose initial properties (e.g., score, state) are influenced by properties of *multiple* source Nodes.
     /// @dev This is a highly abstract function. The "synthesis" logic is simplified here.
     /// Requires a high Energy cost and a minimum number of source nodes.
     /// @param sourceNodeIds An array of IDs of existing nodes used for synthesis.
     /// @return The ID of the newly synthesized node.
     function synthesizeEssence(uint256[] calldata sourceNodeIds) external requiresEnergy(systemParameters.synthesizeEssenceCost) returns (uint256) {
         if (sourceNodeIds.length < systemParameters.synthesizeEssenceMinSources) {
             revert InvalidParameterValue(); // Not enough source nodes
         }

         int256 totalScoreInfluence = 0;
         uint256 totalStakeInfluence = 0;
         uint256 activeSourceCount = 0;

         // Aggregate properties from source nodes
         for (uint i = 0; i < sourceNodeIds.length; i++) {
             uint256 sourceId = sourceNodeIds[i];
             // Ensure source node exists and is active/valid for synthesis
             if (nodes[sourceId].exists && nodes[sourceId].state == NodeState.Active) {
                 activeSourceCount++;
                 // Example aggregation: Sum of scores, sum of total stake
                 totalScoreInfluence += getNodeScore(sourceId); // Use calculated score
                 totalStakeInfluence += nodeTotalStakes[sourceId]; // Use total staked ETH
                 // Add other properties influence here (e.g., connection types, attestation count)
             }
         }

         if (activeSourceCount < systemParameters.synthesizeEssenceMinSources) {
              revert InvalidParameterValue(); // Not enough *valid* active source nodes
         }


         // Create the new node
         nodeCounter++;
         uint256 newNodeId = nodeCounter;
         uint64 currentTime = uint64(block.timestamp);

         // Determine initial properties based on aggregated influence
         int256 initialScore = totalScoreInfluence / int256(activeSourceCount); // Average score
         NodeState initialState = (totalStakeInfluence > 0 && initialScore > 0) ? NodeState.Active : NodeState.Inactive; // Example state logic

         nodes[newNodeId] = Node({
             id: newNodeId,
             owner: msg.sender, // Synthesizer becomes owner
             state: initialState,
             stakeAmount: 0, // No initial stake transferred (can be added later)
             score: initialScore,
             creationTime: currentTime,
             exists: true
         });

         // Optional: Automatically create connections from source nodes to the new node
         // for (uint i = 0; i < sourceNodeIds.length; i++) {
         //     uint256 sourceId = sourceNodeIds[i];
         //      if (nodes[sourceId].exists && nodes[sourceId].state == NodeState.Active) {
         //          // createConnection(sourceId, newNodeId, ConnectionType.DataFlow, 1); // Example auto-connection (costs extra energy!)
         //      }
         // }

         emit NodeCreated(newNodeId, msg.sender, currentTime); // Reuse NodeCreated event
         return newNodeId;
     }


     /// @notice **Dynamic:** Explicitly applies a decay rate to a Connection's weight based on time elapsed since last update/creation.
     /// @dev Callable by anyone, but costs Energy. Allows users to "maintain" network state.
     /// @param connectionId The ID of the connection to decay.
     function decayConnection(uint256 connectionId) external requiresEnergy(systemParameters.decayProcessingCost) connectionExists(connectionId) {
         Connection storage conn = connections[connectionId];

         // Cannot decay if connection is logically destroyed
         if (!conn.exists) revert ConnectionNotFound(connectionId);

         uint64 lastInteractionTime = conn.creationTime; // Using creationTime as last update time
         uint64 currentTime = uint64(block.timestamp);

         // Calculate time elapsed since last update/creation
         // Using uint64 to avoid overflow for time differences in seconds
         uint64 timeElapsed = currentTime - lastInteractionTime;

         // Calculate decay amount: weight * (decay rate per second) * seconds elapsed
         // Using fixed point arithmetic scaled by 1e18 for decayRatePerSecond
         // decayAmount = (weight * decayRatePerSecond * timeElapsed) / 1e18
         uint256 decayAmount = (uint256(conn.weight) * systemParameters.decayRatePerSecond * uint256(timeElapsed)) / 1e18;

         // Apply decay, ensure weight doesn't go below zero (or a minimum threshold)
         if (conn.weight > decayAmount) {
             conn.weight -= decayAmount;
         } else {
             conn.weight = 0; // Or a defined minimum weight
         }

         // Update creationTime to current time to reset decay timer for next call
         conn.creationTime = currentTime;

         // Emit update event to reflect the new weight
         emit ConnectionUpdated(connectionId, conn.weight, conn.connectionType);
     }

    /// @notice Trigger an update to a node's score considering current network state.
    /// @dev This is separate from the `getNodeScore` view function. It *writes* the computed score to storage.
    /// Necessary if score updates need to be triggered based on network changes or require Gas.
    /// @param nodeId The ID of the node whose score needs updating.
    function updateNodeScoreBasedOnNetwork(uint256 nodeId) external requiresEnergy(systemParameters.scoreUpdateCost) nodeExists(nodeId) {
        // Cannot update score for a destroyed node
        if (nodes[nodeId].state == NodeState.Destroyed) revert NodeNotFound(nodeId);

        // Recalculate and store the score
        nodes[nodeId].score = getNodeScore(nodeId); // Use the view function logic to compute
        // Note: No specific event for score update unless needed.
    }


    // --- 8. Protocol Functions ---

    /// @notice Allows the contract owner to withdraw accumulated ETH fees from staking operations.
    function withdrawProtocolFees() external onlyOwner {
        if (protocolFees == 0) revert NoFeesToWithdraw();

        uint256 amount = protocolFees;
        protocolFees = 0;

        (bool success, ) = payable(owner).call{value: amount}("");
        require(success, "Fee withdrawal failed");

        emit ProtocolFeesWithdrawn(owner, amount);
    }

    // --- Internal Helper Functions ---
    // (No need for external interface, e.g., internal score calculation could be here)
    // The current getNodeScore is a public view, which is simpler for this example.

    // --- Fallback/Receive (Optional but good practice if accepting ETH) ---
    receive() external payable {
        // ETH sent directly to the contract could be treated as protocol fees or rejected.
        // Let's add it to protocolFees for simplicity.
        protocolFees += msg.value;
        // Consider emitting an event here.
    }
}
```