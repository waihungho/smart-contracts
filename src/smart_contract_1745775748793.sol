Okay, here is a Solidity smart contract concept called `QuantumLink`. It's designed around abstract "Nodes" that can be linked together, influencing each other's state through a "Resonance" mechanism and having their state potentially change based on "Observation" and internal dynamics. The concept aims for state-dependent logic, dynamic relationships (links), and cascading effects, providing a unique interaction model.

This concept is original and does not replicate standard open-source tokens, NFTs, or common DeFi patterns. It focuses on managing a network of interacting abstract entities.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
// Using OpenZeppelin Ownable for basic admin functionality, which is standard and doesn't contradict
// the request to not duplicate *open source logic/concepts* for the *core functionality*.
// The core Node, Link, Resonance, Observation logic is custom.

/**
 * @title QuantumLink
 * @dev A contract managing a network of interconnected abstract nodes with dynamic states and parameters.
 * Nodes can be created, linked, and influenced by 'Resonance' and 'Observation' actions.
 * The state of nodes and properties of links evolve based on interactions and time decay.
 */

// --- Outline and Function Summary ---
//
// Contract Name: QuantumLink
// Inherits: Ownable
//
// Core Concepts:
// - Nodes: Abstract entities with dynamic parameters (Charge, PhaseSkew, StabilityFactor) and states (Dormant, Active, Decaying, Void).
// - Links: Directed connections between Nodes with properties (Strength, Type) that influence how Resonance propagates.
// - Resonance: A process triggered on a source node that propagates effects through active links to target nodes, modifying their parameters.
// - Observation: A process that checks a node's current parameters and potentially triggers a state transition based on internal conditions.
// - Decay: A time-based reduction in node parameters and link strength to introduce dynamics and prevent stagnation.
//
// State Variables:
// - Nodes mapping (uint256 => Node): Stores Node data by ID.
// - Links mapping (uint256 => Link): Stores Link data by ID.
// - Counters for next Node/Link ID.
// - Mappings to track nodes/links owned by addresses.
// - Global parameters for Decay and Resonance influence.
// - Timestamp of the last global decay process.
//
// Enums:
// - NodeState: Defines possible states of a Node.
// - LinkType: Defines different types of Links with varying effects during Resonance.
//
// Structs:
// - Node: Represents a node with ID, owner, parameters, state, and timestamps.
// - Link: Represents a link with ID, owner, source/target node IDs, properties, and status.
//
// Events: Log key actions for off-chain tracking.
//
// Functions (Grouped by Category):
//
// 1. Node Management (Creation, Modification, Ownership):
//    - createNode(): Creates a new node owned by the caller.
//    - adjustNodeParameters(uint256 nodeId, int256 chargeDelta, int256 phaseSkewDelta, int256 stabilityFactorDelta): Adjusts node parameters (owner only).
//    - transitionNodeState(uint256 nodeId, NodeState newState): Explicitly changes a node's state (admin/restricted).
//    - transferNodeOwnership(uint256 nodeId, address newOwner): Transfers ownership of a node.
//    - decayNode(uint256 nodeId): Applies decay to a specific node based on elapsed time. (Internal/Helper)
//    - decayAllNodes(): Triggers decay for all nodes based on global time since last decay (callable by anyone, but rate limited).
//
// 2. Link Management (Creation, Modification, Ownership):
//    - createLink(uint256 sourceNodeId, uint256 targetNodeId, LinkType linkType, uint256 initialStrength): Creates a new link between two nodes.
//    - adjustLinkProperties(uint256 linkId, uint256 newStrength): Adjusts the strength of a link (owner only).
//    - toggleLinkActivity(uint256 linkId, bool active): Activates or deactivates a link (owner only).
//    - transferLinkOwnership(uint256 linkId, address newOwner): Transfers ownership of a link.
//    - pruneInactiveLinks(): Removes links below a certain strength or inactive for a long time (callable by anyone).
//
// 3. Core Interaction Logic (Resonance, Observation, Propagation):
//    - resonateNode(uint256 nodeId, uint256 propagationDepth): Triggers resonance from a node, propagating effects through links up to a specified depth.
//    - observeNodeState(uint256 nodeId): Performs an observation on a node, potentially changing its state based on parameters and rules.
//    - applyResonanceEffect(uint256 targetNodeId, uint256 effectCharge, int256 effectPhase, uint256 effectStability): Applies calculated resonance effects to a node. (Internal/Helper)
//
// 4. Global Parameters & Admin:
//    - setGlobalResonanceFactor(uint256 factor): Sets a global multiplier for resonance effects (admin only).
//    - setDecayRate(uint256 chargeRate, uint256 phaseRate, uint256 stabilityRate, uint256 linkRate): Sets the rates for parameter decay (admin only).
//    - setObservationThresholds(...): Sets thresholds for state transitions during observation (admin only).
//    - setPruningThresholds(uint256 minStrength, uint256 inactiveDuration): Sets thresholds for link pruning (admin only).
//    - setResonanceGasLimit(uint256 limit): Sets a gas limit for single resonance calls to prevent abuse/DOS (admin only).
//
// 5. View & Query Functions:
//    - getNodeDetails(uint256 nodeId): Retrieves details of a specific node.
//    - getLinkDetails(uint256 linkId): Retrieves details of a specific link.
//    - getNodesByOwner(address owner): Retrieves IDs of nodes owned by an address.
//    - getLinksByOwner(address owner): Retrieves IDs of links owned by an address.
//    - getOutgoingLinks(uint256 nodeId): Retrieves IDs of links originating from a node.
//    - getIncomingLinks(uint256 nodeId): Retrieves IDs of links targeting a node.
//    - getTotalNodes(): Returns the total number of nodes.
//    - getTotalLinks(): Returns the total number of links.
//    - calculateNodePotential(uint256 nodeId): Calculates a derived metric based on node parameters (view).
//    - calculateLinkEffectiveness(uint256 linkId): Calculates a derived metric based on link properties (view).
//    - previewResonancePath(uint256 startNodeId, uint256 depth): Simulates resonance propagation without state changes (view). (Implementation might be simplified for this example due to gas/complexity in view functions).

contract QuantumLink is Ownable {

    // --- Enums ---
    enum NodeState { Dormant, Active, Decaying, Void }
    enum LinkType { Entangling, Reflecting, Dampening }

    // --- Structs ---
    struct Node {
        uint256 id;
        address owner;
        NodeState state;
        int256 chargeLevel; // Can be positive or negative
        int256 phaseSkew;   // Represents alignment/offset
        uint256 stabilityFactor; // Represents resistance to state change/decay
        uint256 createdAt;
        uint256 lastUpdatedAt;
        uint256 lastDecayedAt; // Timestamp of last decay application
    }

    struct Link {
        uint256 id;
        address owner;
        uint256 sourceNodeId;
        uint256 targetNodeId;
        LinkType linkType;
        uint256 strength; // Represents influence power (e.g., 0-1000)
        bool isActive;
        uint256 createdAt;
        uint256 lastUsedAt; // Timestamp of last use in resonance
    }

    // --- State Variables ---
    uint256 private _nextNodeId = 1;
    uint256 private _nextLinkId = 1;

    mapping(uint256 => Node) public nodes;
    mapping(uint256 => Link) public links;

    // Auxiliary mappings for owner lookup (simplified, could use EnumerableSet for gas optimization)
    mapping(address => uint256[]) private ownerToNodes;
    mapping(address => uint256[]) private ownerToLinks;
    // Need reverse lookups for removing from arrays (or just accept gas cost / use libraries)
    mapping(uint256 => uint256) private nodeIdToIndexInOwnerArray;
    mapping(uint256 => uint256) private linkIdToIndexInOwnerArray;

    // Auxiliary mappings for link traversal
    mapping(uint256 => uint256[]) private nodeOutgoingLinks;
    mapping(uint256 => uint256[]) private nodeIncomingLinks;
    // Need reverse lookups for removing from arrays

    // Global Parameters (Configurable by Owner)
    uint256 public globalResonanceFactor = 100; // Multiplier for resonance effects (e.g., 100 = 1x)
    uint256 public decayRateCharge = 1;     // per unit of time (e.g., per hour/day)
    uint256 public decayRatePhase = 1;      // per unit of time
    uint256 public decayRateStability = 1;  // per unit of time
    uint256 public decayRateLink = 1;       // per unit of time

    uint256 public lastGlobalDecayTimestamp;

    // Observation Thresholds (Example thresholds, configurable)
    int256 public obsChargeThresholdActive = 500;
    int256 public obsChargeThresholdDecaying = -300;
    uint256 public obsStabilityThresholdActive = 200;
    uint256 public obsStabilityThresholdDecaying = 50;
    int256 public obsPhaseRangeActiveMin = -50;
    int256 public obsPhaseRangeActiveMax = 50;

    // Link Pruning Thresholds
    uint256 public pruneMinStrength = 10;
    uint256 public pruneInactiveDuration = 365 days; // e.g., inactive for a year

    // Resonance Limits
    uint256 public resonanceGasLimit = 500000; // Limit gas consumption of a single resonateNode call


    // --- Events ---
    event NodeCreated(uint256 indexed nodeId, address indexed owner, uint256 timestamp);
    event LinkCreated(uint256 indexed linkId, uint256 indexed sourceNodeId, uint256 indexed targetNodeId, LinkType linkType, uint256 timestamp);
    event NodeParametersAdjusted(uint256 indexed nodeId, int256 chargeDelta, int256 phaseSkewDelta, uint256 stabilityDelta, uint256 timestamp);
    event NodeStateTransitioned(uint256 indexed nodeId, NodeState oldState, NodeState newState, string reason, uint256 timestamp);
    event LinkPropertiesAdjusted(uint256 indexed linkId, uint256 newStrength, bool isActive, uint256 timestamp);
    event NodeResonated(uint256 indexed nodeId, uint256 depth, uint256 timestamp);
    event NodeObserved(uint256 indexed nodeId, uint256 timestamp);
    event NodeDecayed(uint256 indexed nodeId, uint256 timeElapsed, int256 chargeDecay, int256 phaseDecay, uint256 stabilityDecay);
    event LinkPruned(uint256 indexed linkId, string reason);


    // --- Constructor ---
    constructor() Ownable(msg.sender) {
        lastGlobalDecayTimestamp = block.timestamp;
    }

    // --- Internal Helpers (Simplified array management for example) ---
    function _addNodeToOwner(address owner, uint256 nodeId) internal {
        ownerToNodes[owner].push(nodeId);
        nodeIdToIndexInOwnerArray[nodeId] = ownerToNodes[owner].length - 1;
    }

    function _removeNodeFromOwner(address owner, uint256 nodeId) internal {
        uint256 index = nodeIdToIndexInOwnerArray[nodeId];
        uint256 lastIndex = ownerToNodes[owner].length - 1;
        if (index != lastIndex) {
            uint256 lastNodeId = ownerToNodes[owner][lastIndex];
            ownerToNodes[owner][index] = lastNodeId;
            nodeIdToIndexInOwnerArray[lastNodeId] = index;
        }
        ownerToNodes[owner].pop();
        delete nodeIdToIndexInOwnerArray[nodeId];
    }

    function _addLinkToOwner(address owner, uint256 linkId) internal {
         ownerToLinks[owner].push(linkId);
         linkIdToIndexInOwnerArray[linkId] = ownerToLinks[owner].length - 1;
    }

     function _removeLinkFromOwner(address owner, uint256 linkId) internal {
        uint256 index = linkIdToIndexInOwnerArray[linkId];
        uint256 lastIndex = ownerToLinks[owner].length - 1;
        if (index != lastIndex) {
            uint256 lastLinkId = ownerToLinks[owner][lastIndex];
            ownerToLinks[owner][index] = lastLinkId;
            linkIdToIndexInOwnerArray[lastLinkId] = index;
        }
        ownerToLinks[owner].pop();
        delete linkIdToIndexInOwnerArray[linkId];
    }

    function _addLinkToNodeLinks(uint256 sourceId, uint256 targetId, uint256 linkId) internal {
        nodeOutgoingLinks[sourceId].push(linkId);
        nodeIncomingLinks[targetId].push(linkId);
        // Note: Need similar index tracking if deleting links frequently from these arrays
    }

    // Helper to apply decay to a single node
    function _applySingleNodeDecay(uint256 nodeId) internal {
         Node storage node = nodes[nodeId];
         require(node.id != 0, "Node does not exist");
         require(node.state != NodeState.Void, "Cannot decay a Void node");

         uint256 timeElapsed = block.timestamp - node.lastDecayedAt;
         if (timeElapsed == 0) return; // Decay already applied for this period

         int256 chargeDecayAmount = int256((uint256(node.stabilityFactor) * decayRateCharge * timeElapsed) / 1000); // Stability reduces decay? Or increases? Let's make it reduce decay influence (higher stability means less decay)
         int256 phaseDecayAmount = int256((decayRatePhase * timeElapsed) / 1000);
         uint256 stabilityDecayAmount = (decayRateStability * timeElapsed) / 1000;

         // Apply decay
         node.chargeLevel = node.chargeLevel - chargeDecayAmount;
         node.phaseSkew = node.phaseSkew - phaseDecayAmount;
         if (node.stabilityFactor > stabilityDecayAmount) {
             node.stabilityFactor = node.stabilityFactor - stabilityDecayAmount;
         } else {
             node.stabilityFactor = 0; // Cannot go below 0
         }

         node.lastDecayedAt = block.timestamp;
         node.lastUpdatedAt = block.timestamp; // Consider decay an update?

         emit NodeDecayed(nodeId, timeElapsed, chargeDecayAmount, phaseDecayAmount, stabilityDecayAmount);
    }


    // --- Node Management Functions ---

    /**
     * @dev Creates a new node with initial default parameters.
     * @return The ID of the newly created node.
     */
    function createNode() external returns (uint256) {
        uint256 newNodeId = _nextNodeId++;
        nodes[newNodeId] = Node({
            id: newNodeId,
            owner: msg.sender,
            state: NodeState.Dormant,
            chargeLevel: 0,
            phaseSkew: 0,
            stabilityFactor: 500, // Initial stability
            createdAt: block.timestamp,
            lastUpdatedAt: block.timestamp,
            lastDecayedAt: block.timestamp
        });
        _addNodeToOwner(msg.sender, newNodeId);
        emit NodeCreated(newNodeId, msg.sender, block.timestamp);
        return newNodeId;
    }

    /**
     * @dev Adjusts the parameters of a specific node. Only callable by the node's owner.
     * Parameter deltas allow relative adjustments.
     * @param nodeId The ID of the node to adjust.
     * @param chargeDelta The amount to add to the chargeLevel.
     * @param phaseSkewDelta The amount to add to the phaseSkew.
     * @param stabilityFactorDelta The amount to add/subtract from stabilityFactor (signed int for delta).
     */
    function adjustNodeParameters(uint256 nodeId, int256 chargeDelta, int256 phaseSkewDelta, int256 stabilityFactorDelta) external {
        Node storage node = nodes[nodeId];
        require(node.id != 0, "Node does not exist");
        require(node.owner == msg.sender, "Not node owner");
        require(node.state != NodeState.Void, "Cannot adjust Void node");

        node.chargeLevel += chargeDelta;
        node.phaseSkew += phaseSkewDelta;
        // Handle stability delta carefully
        if (stabilityFactorDelta > 0) {
             node.stabilityFactor += uint256(stabilityFactorDelta);
        } else {
             uint256 absDelta = uint256(-stabilityFactorDelta);
             if (node.stabilityFactor > absDelta) {
                 node.stabilityFactor -= absDelta;
             } else {
                 node.stabilityFactor = 0;
             }
        }

        node.lastUpdatedAt = block.timestamp;
        emit NodeParametersAdjusted(nodeId, chargeDelta, phaseSkewDelta, uint256(stabilityFactorDelta > 0 ? stabilityFactorDelta : -stabilityFactorDelta), block.timestamp);
    }

    /**
     * @dev Explicitly transitions a node to a new state. Restricted access (e.g., can be internal helper for observeNodeState, or admin function).
     * Added onlyOwner for demonstration, but real logic might be complex internal triggers.
     * @param nodeId The ID of the node to transition.
     * @param newState The target state.
     */
    function transitionNodeState(uint256 nodeId, NodeState newState) external onlyOwner {
        Node storage node = nodes[nodeId];
        require(node.id != 0, "Node does not exist");
        require(node.state != NodeState.Void, "Cannot transition Void node");
        require(node.state != newState, "Node is already in this state");

        NodeState oldState = node.state;
        node.state = newState;
        node.lastUpdatedAt = block.timestamp;

        emit NodeStateTransitioned(nodeId, oldState, newState, "Manual/Admin Transition", block.timestamp);
    }

    /**
     * @dev Transfers ownership of a node.
     * @param nodeId The ID of the node.
     * @param newOwner The address of the new owner.
     */
    function transferNodeOwnership(uint256 nodeId, address newOwner) external {
        Node storage node = nodes[nodeId];
        require(node.id != 0, "Node does not exist");
        require(node.owner == msg.sender, "Not node owner");
        require(newOwner != address(0), "Invalid new owner address");

        _removeNodeFromOwner(node.owner, nodeId);
        node.owner = newOwner;
        _addNodeToOwner(newOwner, nodeId);

        // Optional: Event for ownership transfer
    }

    /**
     * @dev Triggers the decay process for all nodes based on elapsed time since the last global decay.
     * This function can be called by anyone to push the state forward, but decay is only applied
     * for the duration passed since `lastGlobalDecayTimestamp`.
     * Note: Iterating over all nodes in a mapping can be gas-intensive for large numbers of nodes.
     * A real-world contract might require off-chain indexing or batch processing.
     */
    function decayAllNodes() external {
        // Calculate elapsed time since last global decay
        uint256 timeElapsed = block.timestamp - lastGlobalDecayTimestamp;
        if (timeElapsed == 0) return; // Decay already up-to-date globally

        // Update global timestamp *before* processing to prevent re-entrancy on the time check
        lastGlobalDecayTimestamp = block.timestamp;

        // Iterate through all potential node IDs up to the current max.
        // This is inefficient for sparse ID spaces or large counts.
        // A better approach involves tracking active node IDs, perhaps in an iterable mapping.
        // For this example, we iterate simply up to the current counter.
        for (uint256 i = 1; i < _nextNodeId; i++) {
             if (nodes[i].id != 0 && nodes[i].state != NodeState.Void) {
                // Only apply decay if the node hasn't been individually decayed more recently
                if (nodes[i].lastDecayedAt < block.timestamp) {
                     _applySingleNodeDecay(i); // This applies decay based on node's lastDecayedAt up to current block.timestamp
                }
             }
        }

        // Note: Link decay is handled within pruneInactiveLinks or could be added here.
    }


    // --- Link Management Functions ---

    /**
     * @dev Creates a directed link between two existing nodes.
     * @param sourceNodeId The ID of the source node.
     * @param targetNodeId The ID of the target node.
     * @param linkType The type of link (influences resonance effect).
     * @param initialStrength The initial strength of the link.
     * @return The ID of the newly created link.
     */
    function createLink(uint256 sourceNodeId, uint256 targetNodeId, LinkType linkType, uint256 initialStrength) external returns (uint256) {
        require(nodes[sourceNodeId].id != 0, "Source node does not exist");
        require(nodes[targetNodeId].id != 0, "Target node does not exist");
        require(sourceNodeId != targetNodeId, "Cannot link node to itself");

        uint256 newLinkId = _nextLinkId++;
        links[newLinkId] = Link({
            id: newLinkId,
            owner: msg.sender, // Link owner is the creator
            sourceNodeId: sourceNodeId,
            targetNodeId: targetNodeId,
            linkType: linkType,
            strength: initialStrength,
            isActive: true,
            createdAt: block.timestamp,
            lastUsedAt: block.timestamp // Mark as used upon creation? Or upon resonance? Let's say creation.
        });

        _addLinkToOwner(msg.sender, newLinkId);
        _addLinkToNodeLinks(sourceNodeId, targetNodeId, newLinkId);

        emit LinkCreated(newLinkId, sourceNodeId, targetNodeId, linkType, block.timestamp);
        return newLinkId;
    }

    /**
     * @dev Adjusts the strength of a specific link. Only callable by the link's owner.
     * @param linkId The ID of the link to adjust.
     * @param newStrength The new strength value.
     */
    function adjustLinkProperties(uint256 linkId, uint256 newStrength) external {
        Link storage link = links[linkId];
        require(link.id != 0, "Link does not exist");
        require(link.owner == msg.sender, "Not link owner");

        link.strength = newStrength;
        // isActive not modified here, use toggleLinkActivity

        // No timestamp update for simple property adjust? Or track last modified? Let's add it.
        // link.lastUsedAt = block.timestamp; // Maybe not 'used' but 'modified'? Let's keep lastUsedAt for resonance.
        emit LinkPropertiesAdjusted(linkId, link.strength, link.isActive, block.timestamp);
    }

    /**
     * @dev Activates or deactivates a link. Only callable by the link's owner.
     * @param linkId The ID of the link.
     * @param active The active status to set.
     */
    function toggleLinkActivity(uint256 linkId, bool active) external {
        Link storage link = links[linkId];
        require(link.id != 0, "Link does not exist");
        require(link.owner == msg.sender, "Not link owner");

        link.isActive = active;
         emit LinkPropertiesAdjusted(linkId, link.strength, link.isActive, block.timestamp);
    }

    /**
     * @dev Transfers ownership of a link.
     * @param linkId The ID of the link.
     * @param newOwner The address of the new owner.
     */
    function transferLinkOwnership(uint256 linkId, address newOwner) external {
         Link storage link = links[linkId];
         require(link.id != 0, "Link does not exist");
         require(link.owner == msg.sender, "Not link owner");
         require(newOwner != address(0), "Invalid new owner address");

         _removeLinkFromOwner(link.owner, linkId);
         link.owner = newOwner;
         _addLinkToOwner(newOwner, linkId);

         // Optional: Event for ownership transfer
    }


    /**
     * @dev Removes links that are below a minimum strength or have been inactive for a long time.
     * Callable by anyone.
     * Note: Iterating over all links is gas-intensive. Similar considerations as decayAllNodes apply.
     */
    function pruneInactiveLinks() external {
        uint256 currentTime = block.timestamp;
        // Iterate through all potential link IDs up to the current max.
        for (uint256 i = 1; i < _nextLinkId; i++) {
            Link storage link = links[i];
            // Check if link exists and is not already pruned (id=0 indicates pruned)
            if (link.id != 0) {
                bool shouldPrune = false;
                string memory reason = "None";

                // Check strength threshold
                if (link.strength < pruneMinStrength) {
                    shouldPrune = true;
                    reason = "Strength below threshold";
                }

                // Check inactivity duration (only if still active or wasn't pruned by strength)
                if (!shouldPrune && !link.isActive && (currentTime - link.lastUsedAt) > pruneInactiveDuration) {
                     shouldPrune = true;
                     reason = "Inactive for too long";
                }

                if (shouldPrune) {
                    // Remove from owner's list (simplified)
                    _removeLinkFromOwner(link.owner, link.id);
                    // Remove from node link lists (simplified - would need indexing for efficient removal)
                    // For this example, we'll just set strength to 0 and isActive to false, and rely on checks.
                    // A true prune would delete the struct data and clean up index arrays.
                    // To actually 'delete' in Solidity < 0.8.17 one would use `delete links[i];`
                    // Let's simulate pruning by invalidating the ID and resetting data.
                    emit LinkPruned(link.id, reason);
                    delete links[i]; // Using delete to truly remove from mapping
                     // Note: This leaves gaps in sequential IDs, but the counter _nextLinkId continues.
                     // Removing from ownerToLinks, nodeOutgoingLinks, nodeIncomingLinks arrays
                     // is needed for efficiency, but complex without indexed removal.
                     // We skip complex array cleanup here for brevity.
                } else {
                    // Apply decay to link strength if it's active? Or only prune?
                    // Let's add strength decay here based on time since last used/created.
                    uint256 timeElapsed = currentTime - link.createdAt; // Or lastUsedAt? Let's use createdAt for simple continuous decay
                    if (timeElapsed > 0) {
                         uint256 decayAmount = (link.strength * decayRateLink * timeElapsed) / 1000000; // Percentage decay based on rate and time
                         if (link.strength > decayAmount) {
                             link.strength -= decayAmount;
                         } else {
                             link.strength = 0;
                         }
                         // Check again after decay if it now meets pruning threshold
                         if (link.strength < pruneMinStrength) {
                             emit LinkPruned(link.id, "Decayed below threshold");
                             delete links[i]; // Prune after decay
                             _removeLinkFromOwner(link.owner, link.id);
                             // Array cleanup needed here...
                         }
                    }
                }
            }
        }
    }

    // --- Core Interaction Logic ---

    /**
     * @dev Triggers a resonance effect starting from a specific node.
     * Effects propagate through active links up to a defined depth or gas limit.
     * This is a complex function involving potential cascades.
     * @param nodeId The ID of the node initiating resonance.
     * @param propagationDepth The maximum depth the resonance effect can travel.
     * Note: Resonance can be gas-intensive depending on network structure and depth.
     * A gas limit is enforced.
     */
    function resonateNode(uint256 nodeId, uint256 propagationDepth) external {
         // Basic gas limit check at the start
         uint256 startGas = gasleft();

         require(nodes[nodeId].id != 0, "Source node does not exist");
         Node storage sourceNode = nodes[nodeId];
         require(sourceNode.state == NodeState.Active, "Source node must be Active to resonate");

         // Queue for iterative propagation (safer than recursion)
         // Each item: [currentNodeId, currentDepth, accumulatedEffectCharge, accumulatedEffectPhase, accumulatedEffectStability]
         // Using a simple array for queue; for very deep/wide graphs, might need a more complex structure or external computation.
         // Max queue size could also be a DoS vector.
         // For simplicity, let's limit queue processing steps within the gas limit.
         uint256[] memory queue = new uint256[](1); // Store source node ID
         queue[0] = nodeId;
         // Need to track visited nodes to prevent infinite loops in cycles
         mapping(uint256 => bool) visitedNodes;
         visitedNodes[nodeId] = true;

         uint256 head = 0;
         uint256 tail = 1; // Queue head and tail pointers

         emit NodeResonated(nodeId, propagationDepth, block.timestamp);

         // This iterative approach processes nodes layer by layer up to the depth limit
         // or until gas runs out.
         for (uint256 currentDepth = 0; currentDepth < propagationDepth; currentDepth++) {
             uint256 layerSize = tail - head; // Number of nodes at the current depth
             if (layerSize == 0) break; // No nodes left to process at this depth

             uint256 newTail = tail; // Where new nodes will be added for the next layer

             for (uint256 i = 0; i < layerSize; i++) {
                 if (gasleft() < resonanceGasLimit / 10) { // Keep some buffer
                      // Log an event indicating resonance was partial due to gas
                     emit NodeResonated(nodeId, currentDepth, block.timestamp); // Indicate partial depth
                     return; // Stop processing if gas is low
                 }

                 uint256 currentNodeId = queue[head + i];
                 // Refresh node data as it might have been modified by effects earlier in this layer
                 Node storage currentNode = nodes[currentNodeId];
                 // Ensure node is still valid and active (optional, but prevents propagating from decayed/void nodes)
                 if (currentNode.id == 0 || currentNode.state != NodeState.Active) continue;

                 // Iterate through outgoing links from the current node
                 uint256[] memory outgoingLinks = nodeOutgoingLinks[currentNodeId]; // Get link IDs
                 for (uint256 j = 0; j < outgoingLinks.length; j++) {
                     uint256 linkId = outgoingLinks[j];
                     Link storage link = links[linkId];

                     // Check if link exists, is active, and target node exists and is not Void
                     if (link.id != 0 && link.isActive && nodes[link.targetNodeId].id != 0 && nodes[link.targetNodeId].state != NodeState.Void) {

                         // Calculate effect based on link type, strength, and source node parameters
                         // Simple example logic:
                         int256 effectCharge = 0;
                         int256 effectPhase = 0;
                         uint256 effectStability = 0;

                         uint256 effectiveStrength = (link.strength * globalResonanceFactor) / 100; // Apply global factor

                         if (effectiveStrength > 0) {
                            if (link.linkType == LinkType.Entangling) {
                                // Entangling: Transfers/mixes charge and phase, potentially affects stability
                                effectCharge = (currentNode.chargeLevel * int256(effectiveStrength)) / 1000; // e.g., 10% of charge per 100 strength
                                effectPhase = (currentNode.phaseSkew * int256(effectiveStrength)) / 1000;
                                effectStability = (uint256(currentNode.stabilityFactor) * effectiveStrength) / 2000; // Less stability transfer
                            } else if (link.linkType == LinkType.Reflecting) {
                                // Reflecting: Reverses phase, boosts stability, dampens charge
                                effectCharge = -(currentNode.chargeLevel * int256(effectiveStrength)) / 2000; // Dampen and possibly reverse
                                effectPhase = -(currentNode.phaseSkew * int256(effectiveStrength)) / 500;   // Strongly reverse
                                effectStability = (uint256(currentNode.stabilityFactor) * effectiveStrength) / 500; // Boost stability
                            } else if (link.linkType == LinkType.Dampening) {
                                // Dampening: Reduces charge and phase skew, increases stability slightly
                                effectCharge = -(int256(effectiveStrength) * 10); // Fixed negative charge based on strength
                                effectPhase = -(currentNode.phaseSkew * int256(effectiveStrength)) / 1500; // Reduce skew
                                effectStability = effectiveStrength / 10; // Small stability boost
                            }

                            // Apply the calculated effects to the target node
                            applyResonanceEffect(link.targetNodeId, uint256(effectCharge > 0 ? effectCharge : 0), effectPhase, uint256(effectStability));
                             // Apply negative charge separately
                            if (effectCharge < 0) {
                                 nodes[link.targetNodeId].chargeLevel += effectCharge; // Add negative amount
                            }


                            // Mark link as used
                            link.lastUsedAt = block.timestamp;

                            // Add target node to the queue for the next layer if not visited and within depth
                            if (currentDepth + 1 < propagationDepth && !visitedNodes[link.targetNodeId]) {
                                // Check queue capacity before adding
                                if (newTail == queue.length) {
                                     // Dynamically resize queue (gas heavy) or cap size
                                     // For this example, let's cap or require a fixed max queue size.
                                     // Let's resize for the example, acknowledging the cost.
                                     uint256[] memory newQueue = new uint256[](queue.length * 2);
                                     for(uint256 k = 0; k < tail; k++) {
                                         newQueue[k] = queue[k];
                                     }
                                     queue = newQueue; // Replace old queue
                                }
                                queue[newTail++] = link.targetNodeId;
                                visitedNodes[link.targetNodeId] = true;
                            }
                         }
                     }
                 }
             }
             head = tail; // Move head to the start of the next layer
             tail = newTail; // Update tail to the end of the next layer
         }

         // Optional: Log total gas used for resonance
         // emit ResonanceGasUsed(nodeId, startGas - gasleft());
    }

    /**
     * @dev Internal helper to apply resonance effects to a target node.
     * Separated for clarity and potential reuse.
     * @param targetNodeId The ID of the node receiving effects.
     * @param effectCharge Positive charge amount to add.
     * @param effectPhase Signed phase shift to add.
     * @param effectStability Stability amount to add.
     */
    function applyResonanceEffect(uint256 targetNodeId, uint256 effectCharge, int256 effectPhase, uint256 effectStability) internal {
        Node storage targetNode = nodes[targetNodeId];
        require(targetNode.id != 0, "Target node does not exist for effect");
        require(targetNode.state != NodeState.Void, "Cannot apply effect to Void node");

        targetNode.chargeLevel += int256(effectCharge); // Add positive effect
        targetNode.phaseSkew += effectPhase;
        targetNode.stabilityFactor += effectStability;

        targetNode.lastUpdatedAt = block.timestamp;

        // Optional: Log effect application
        // emit ResonanceEffectApplied(targetNodeId, effectCharge, effectPhase, effectStability, block.timestamp);
    }


    /**
     * @dev Performs an 'observation' on a node. Checks its parameters against thresholds
     * and potentially triggers a state transition based on defined rules.
     * @param nodeId The ID of the node to observe.
     */
    function observeNodeState(uint256 nodeId) external {
        Node storage node = nodes[nodeId];
        require(node.id != 0, "Node does not exist");
        require(node.state != NodeState.Void, "Cannot observe Void node");

        // Apply any pending decay before observation for accurate state
        _applySingleNodeDecay(nodeId);

        NodeState currentState = node.state;
        NodeState newState = currentState; // Assume no change unless rules match

        // Define observation rules (examples)
        if (currentState == NodeState.Dormant) {
            // Rule: Dormant -> Active
            if (node.chargeLevel >= obsChargeThresholdActive &&
                node.stabilityFactor >= obsStabilityThresholdActive &&
                node.phaseSkew >= obsPhaseRangeActiveMin && node.phaseSkew <= obsPhaseRangeActiveMax) {
                newState = NodeState.Active;
            }
            // Rule: Dormant -> Decaying (low stability / negative charge threshold)
             else if (node.chargeLevel <= obsChargeThresholdDecaying || node.stabilityFactor < obsStabilityThresholdDecaying) {
                 newState = NodeState.Decaying;
             }
        } else if (currentState == NodeState.Active) {
            // Rule: Active -> Decaying (parameters outside Active range)
            if (node.chargeLevel < obsChargeThresholdActive ||
                node.stabilityFactor < obsStabilityThresholdActive ||
                node.phaseSkew < obsPhaseRangeActiveMin || node.phaseSkew > obsPhaseRangeActiveMax) {
                newState = NodeState.Decaying;
            }
            // Could add a rule for Active -> Void based on extreme parameters/time
        } else if (currentState == NodeState.Decaying) {
            // Rule: Decaying -> Void (stability hits zero, or charge very low)
            if (node.stabilityFactor == 0 || node.chargeLevel < obsChargeThresholdDecaying * 2) { // E.g., double decaying threshold
                newState = NodeState.Void;
                // When a node becomes Void, remove it from owner/link mappings (complex cleanup needed)
                 _removeNodeFromOwner(node.owner, nodeId);
                 // Need to iterate/clean up associated links referencing this node (gas heavy)
                 // For simplicity, pruneInactiveLinks can handle links to Void nodes later.
                 // A real contract needs robust cleanup here.
            }
            // Rule: Decaying -> Dormant (parameters recover)
            else if (node.chargeLevel >= 0 && node.stabilityFactor > obsStabilityThresholdDecaying && (node.phaseSkew > obsPhaseRangeActiveMin && node.phaseSkew < obsPhaseRangeActiveMax)) {
                 newState = NodeState.Dormant;
            }
        }
        // Void state is terminal

        if (newState != currentState) {
            node.state = newState;
            node.lastUpdatedAt = block.timestamp;
            emit NodeStateTransitioned(nodeId, currentState, newState, "Observed State Change", block.timestamp);
        }

        emit NodeObserved(nodeId, block.timestamp);
    }

    // --- Global Parameters & Admin Functions (Ownable) ---

    /**
     * @dev Sets the global resonance factor. Affects the power of all links.
     * @param factor New global resonance factor (e.g., 100 for 1x effect).
     */
    function setGlobalResonanceFactor(uint256 factor) external onlyOwner {
        globalResonanceFactor = factor;
    }

     /**
      * @dev Sets the rates at which node parameters decay over time.
      * @param chargeRate Decay rate for charge.
      * @param phaseRate Decay rate for phase skew.
      * @param stabilityRate Decay rate for stability factor.
      * @param linkRate Decay rate for link strength (applied in pruneInactiveLinks).
      */
    function setDecayRate(uint256 chargeRate, uint256 phaseRate, uint256 stabilityRate, uint256 linkRate) external onlyOwner {
        decayRateCharge = chargeRate;
        decayRatePhase = phaseRate;
        decayRateStability = stabilityRate;
        decayRateLink = linkRate;
    }

    /**
     * @dev Sets the thresholds used by the observeNodeState function to trigger state transitions.
     */
    function setObservationThresholds(
        int256 chargeActive, int256 chargeDecaying,
        uint256 stabilityActive, uint256 stabilityDecaying,
        int256 phaseMinActive, int256 phaseMaxActive
    ) external onlyOwner {
        obsChargeThresholdActive = chargeActive;
        obsChargeThresholdDecaying = chargeDecaying;
        obsStabilityThresholdActive = stabilityActive;
        obsStabilityThresholdDecaying = stabilityDecaying;
        obsPhaseRangeActiveMin = phaseMinActive;
        obsPhaseRangeActiveMax = phaseMaxActive;
    }

    /**
     * @dev Sets the thresholds used by pruneInactiveLinks function to remove links.
     * @param minStrength Minimum strength below which a link is pruned.
     * @param inactiveDuration Duration (in seconds) after which an inactive link is pruned.
     */
    function setPruningThresholds(uint256 minStrength, uint256 inactiveDuration) external onlyOwner {
        pruneMinStrength = minStrength;
        pruneInactiveDuration = inactiveDuration;
    }

    /**
     * @dev Sets the gas limit for the resonateNode function to prevent excessive computation in a single transaction.
     * @param limit The new gas limit.
     */
    function setResonanceGasLimit(uint256 limit) external onlyOwner {
         resonanceGasLimit = limit;
    }


    // --- View & Query Functions ---

    /**
     * @dev Retrieves the details of a specific node.
     * @param nodeId The ID of the node.
     * @return Node struct details.
     */
    function getNodeDetails(uint256 nodeId) external view returns (Node memory) {
        require(nodes[nodeId].id != 0, "Node does not exist");
        // Note: Accessing storage directly is fine in view.
        // This returns a memory copy.
        return nodes[nodeId];
    }

    /**
     * @dev Retrieves the details of a specific link.
     * @param linkId The ID of the link.
     * @return Link struct details.
     */
    function getLinkDetails(uint256 linkId) external view returns (Link memory) {
        require(links[linkId].id != 0, "Link does not exist");
        return links[linkId];
    }

    /**
     * @dev Retrieves the IDs of nodes owned by a specific address.
     * Note: This relies on the `ownerToNodes` mapping. Adding/removing nodes needs to keep this array accurate.
     * @param owner The address to query.
     * @return An array of node IDs.
     */
    function getNodesByOwner(address owner) external view returns (uint256[] memory) {
        return ownerToNodes[owner];
    }

    /**
     * @dev Retrieves the IDs of links owned by a specific address.
     * Note: This relies on the `ownerToLinks` mapping. Adding/removing links needs to keep this array accurate.
     * @param owner The address to query.
     * @return An array of link IDs.
     */
    function getLinksByOwner(address owner) external view returns (uint255[] memory) {
        return ownerToLinks[owner];
    }

    /**
     * @dev Retrieves the IDs of links originating from a specific node.
     * Note: Relies on `nodeOutgoingLinks`.
     * @param nodeId The ID of the source node.
     * @return An array of link IDs.
     */
    function getOutgoingLinks(uint256 nodeId) external view returns (uint256[] memory) {
         require(nodes[nodeId].id != 0, "Node does not exist");
         return nodeOutgoingLinks[nodeId];
    }

    /**
     * @dev Retrieves the IDs of links targeting a specific node.
     * Note: Relies on `nodeIncomingLinks`.
     * @param nodeId The ID of the target node.
     * @return An array of link IDs.
     */
    function getIncomingLinks(uint256 nodeId) external view returns (uint256[] memory) {
         require(nodes[nodeId].id != 0, "Node does not exist");
         return nodeIncomingLinks[nodeId];
    }


    /**
     * @dev Returns the total number of nodes created (including potentially Void nodes).
     * Note: This is a simple counter, not a count of currently active/valid nodes.
     * @return The total number of nodes.
     */
    function getTotalNodes() external view returns (uint256) {
        return _nextNodeId - 1;
    }

    /**
     * @dev Returns the total number of links created (including potentially pruned/inactive links).
     * Note: This is a simple counter, not a count of currently active/valid links.
     * @return The total number of links.
     */
    function getTotalLinks() external view returns (uint256) {
        return _nextLinkId - 1;
    }

    /**
     * @dev Calculates a derived metric representing a node's potential influence or stability.
     * (Example formula: stability + charge / 10 - abs(phaseSkew) / 5)
     * @param nodeId The ID of the node.
     * @return The calculated potential score.
     */
    function calculateNodePotential(uint256 nodeId) external view returns (int256) {
         Node memory node = getNodeDetails(nodeId); // Use the view function
         // Simple arbitrary calculation for demonstration
         int256 potential = int256(node.stabilityFactor) + (node.chargeLevel / 10) - (node.phaseSkew > 0 ? node.phaseSkew : -node.phaseSkew) / 5;
         if (node.state == NodeState.Void) return 0; // Void nodes have no potential
         if (node.state == NodeState.Decaying) potential = potential / 2; // Decaying nodes have reduced potential
         return potential;
    }

    /**
     * @dev Calculates a derived metric representing a link's effectiveness in propagating resonance.
     * (Example formula: strength * (isActive ? 1 : 0.1) * linkTypeMultiplier)
     * @param linkId The ID of the link.
     * @return The calculated effectiveness score.
     */
    function calculateLinkEffectiveness(uint256 linkId) external view returns (uint256) {
         Link memory link = getLinkDetails(linkId); // Use the view function

         uint256 baseEffectiveness = link.strength;
         if (!link.isActive) {
             baseEffectiveness = baseEffectiveness / 10; // Reduce effectiveness if inactive
         }

         uint256 typeMultiplier = 100; // Default multiplier (e.g., 1x)
         if (link.linkType == LinkType.Entangling) typeMultiplier = 120; // Entangling slightly more effective
         else if (link.linkType == LinkType.Reflecting) typeMultiplier = 80; // Reflecting slightly less effective (due to complexity?)
         // Dampening multiplier could be different depending on desired effect on score

         return (baseEffectiveness * typeMultiplier) / 100; // Apply type multiplier
    }

    /**
     * @dev Simulates a resonance path without modifying state. Useful for previewing effects.
     * Note: This is a basic simulation and may not perfectly match the full resonance logic,
     * especially concerning complex interactions or state changes during a live resonance.
     * Iteration depth is limited.
     * @param startNodeId The ID of the starting node.
     * @param depth The maximum simulation depth.
     * @return An array of node IDs potentially affected, in order of traversal.
     */
    function previewResonancePath(uint256 startNodeId, uint256 depth) external view returns (uint256[] memory) {
         require(nodes[startNodeId].id != 0, "Start node does not exist");

         uint256[] memory affectedNodes = new uint256[](0); // Dynamic array for affected nodes
         mapping(uint256 => bool) visited; // Track visited nodes to avoid cycles in simulation

         // Queue for iterative simulation
         uint256[] memory queue = new uint256[](1);
         queue[0] = startNodeId;
         visited[startNodeId] = true;

         affectedNodes = _appendToUintArray(affectedNodes, startNodeId);

         uint256 head = 0;
         uint256 tail = 1;

         for (uint256 currentDepth = 0; currentDepth < depth; currentDepth++) {
              uint256 layerSize = tail - head;
              if (layerSize == 0) break;

              uint256 newTail = tail;

              for (uint256 i = 0; i < layerSize; i++) {
                   uint256 currentNodeId = queue[head + i];

                   uint256[] memory outgoingLinks = nodeOutgoingLinks[currentNodeId];
                   for (uint256 j = 0; j < outgoingLinks.length; j++) {
                       uint256 linkId = outgoingLinks[j];
                       Link memory link = links[linkId]; // Use memory copy for view function

                       if (link.id != 0 && link.isActive && nodes[link.targetNodeId].id != 0 && nodes[link.targetNodeId].state != NodeState.Void) {
                            uint256 targetNodeId = link.targetNodeId;
                            if (!visited[targetNodeId]) {
                                 // Check queue capacity before adding
                                 if (newTail == queue.length) {
                                      uint256[] memory newQueue = new uint256[](queue.length * 2);
                                      for(uint256 k = 0; k < tail; k++) {
                                          newQueue[k] = queue[k];
                                      }
                                      queue = newQueue;
                                 }
                                 queue[newTail++] = targetNodeId;
                                 visited[targetNodeId] = true;
                                 affectedNodes = _appendToUintArray(affectedNodes, targetNodeId);
                            }
                       }
                   }
              }
              head = tail;
              tail = newTail;
         }

         return affectedNodes;
    }

    // Internal helper to dynamically append to a uint array (gas intensive for large arrays)
    function _appendToUintArray(uint256[] memory arr, uint256 element) internal pure returns (uint256[] memory) {
        uint256 newLength = arr.length + 1;
        uint256[] memory newArr = new uint256[](newLength);
        for (uint256 i = 0; i < arr.length; i++) {
            newArr[i] = arr[i];
        }
        newArr[arr.length] = element;
        return newArr;
    }
}
```

---

**Explanation and Concepts Highlighted:**

1.  **Abstract Entities (Nodes & Links):** Instead of representing physical or financial assets, the contract manages abstract units (`Node`) with internal parameters (`chargeLevel`, `phaseSkew`, `stabilityFactor`). These nodes can be linked (`Link`) in a directed graph structure.
2.  **Dynamic State Machine:** Nodes have discrete states (`Dormant`, `Active`, `Decaying`, `Void`) governed by rules triggered by `observeNodeState`. This introduces a state machine concept where actions depend on the current state and can cause transitions.
3.  **Parameter-Based State:** The transition rules within `observeNodeState` are based on the node's numerical parameters meeting certain configurable thresholds. This makes the state dynamic and influenced by interactions.
4.  **Resonance Propagation:** The `resonateNode` function implements a core, non-standard interaction. It doesn't just call another function; it calculates effects based on the source node's parameters and the specific link type (`Entangling`, `Reflecting`, `Dampening`), then *propagates* these effects to connected nodes. This simulates a cascading influence through the network structure. The iterative propagation loop is designed to manage depth and includes a basic gas check to prevent hitting block limits.
5.  **Link Types:** Different `LinkType` enums introduce behavioral polymorphism in how the `resonateNode` function calculates effects, adding complexity and strategic depth to how users might structure the network.
6.  **Decay Mechanism:** The `decayAllNodes` function introduces a time-based element, causing node parameters and potentially link strength to degrade over time. This prevents states from being permanent and necessitates user interaction (charging, etc.) to maintain desired states. The decay calculation is based on elapsed time and node stability.
7.  **Observation Triggered Transitions:** `observeNodeState` is a public function allowing anyone to trigger the state evaluation for a node. This decouples the state *check* from the actions that modify parameters, adding a layer where the "measurement" (observation) can be critical.
8.  **Pruning:** `pruneInactiveLinks` adds a maintenance function callable by anyone, allowing the network graph to be cleaned up based on inactivity or low strength, managing contract storage over time.
9.  **Derived Metrics (View Functions):** `calculateNodePotential` and `calculateLinkEffectiveness` are examples of view functions that calculate abstract scores based on the current state and parameters, providing external users with interpretive data about the network state.
10. **Preview Function:** `previewResonancePath` offers a simulation function (`view`) allowing users to see *which* nodes *might* be affected by a resonance without spending gas to execute it. This is an advanced feature for complex systems.
11. **Parameter Control:** The contract includes several admin functions (`setGlobalResonanceFactor`, `setDecayRate`, `setObservationThresholds`, `setPruningThresholds`, `setResonanceGasLimit`) allowing the owner to fine-tune the system's dynamics and rules, adding a level of centralized control over the simulation's parameters (though the core logic is fixed).
12. **Auxiliary Mappings for Graph Traversal:** The use of `nodeOutgoingLinks` and `nodeIncomingLinks` is necessary for efficiently traversing the link graph during resonance and preview functions.
13. **Gas Considerations:** Notes are included regarding the potential gas costs of iterating through mappings (`decayAllNodes`, `pruneInactiveLinks`) and complex graph traversal (`resonateNode`, `previewResonancePath`), which are significant considerations in Solidity. A gas limit is explicitly added to `resonateNode`.
14. **Ownership of Abstract Entities:** Both Nodes and Links have owners, allowing for individual control and transfer of these abstract components of the network.

This contract goes beyond simple data storage or token transfers, creating a simulation-like environment with internal rules, cascading effects, and dynamic states governed by parameters and interactions. The "Quantum" analogy is primarily in the state-dependent transitions and the non-trivial, linked propagation of effects, rather than a literal quantum simulation.