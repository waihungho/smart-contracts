Okay, let's design a smart contract that acts as a "Synergistic State Engine". This engine manages different "Nodes" which have states, attributes, and relationships with other nodes. The interesting, advanced, and creative part will be how the states, attributes, and relationships dynamically influence each other through specific interaction and temporal functions.

This is *not* a token contract, *not* a typical DeFi protocol, *not* a standard DAO governance, and *not* a simple registry. It's a custom system simulating dynamic interactions.

---

**Outline:**

1.  **Contract Name:** `SynergisticStateEngine`
2.  **Core Concepts:** Nodes, States, Attributes, Relationships, Synergy, Temporal Dynamics, State Propagation.
3.  **Key Data Structures:**
    *   `NodeState` (enum): Defines the possible operational states of a node.
    *   `NodeType` (enum): Defines different categories of nodes with potentially different base behaviors/attributes.
    *   `RelationshipType` (enum): Defines types of connections between nodes (e.g., Symbiotic, Antagonistic, Neutral).
    *   `Node` (struct): Represents a single entity in the engine. Contains ID, type, state, attributes, last updated timestamp.
    *   `Relationship` (mapping): Stores connections between nodes and their types.
4.  **Key Mechanisms:**
    *   **Node Management:** Creation, deletion, attribute update.
    *   **State Transitions:** Functions to change a node's state based on conditions.
    *   **Relationship Management:** Creating and removing links between nodes.
    *   **Synergy & Interaction:** Functions to calculate and apply effects based on node states and relationships.
    *   **Temporal Effects:** Applying changes based on time elapsed.
    *   **State Propagation:** A state change in one node potentially influencing its neighbors.
    *   **Querying:** Retrieving information about nodes, states, and relationships.
    *   **Admin/Setup:** Functions for the contract owner to configure base parameters.

**Function Summary:**

1.  `constructor()`: Initializes the contract, setting the owner.
2.  `setNodeBaseAttributes(NodeType _type, uint256[] memory _attributes)`: Owner sets base attribute values for a specific node type.
3.  `setRelationshipEffects(RelationshipType _type, int256[] memory _attributeModifiers)`: Owner sets how a relationship type modifies neighbor attributes during synergy calculation.
4.  `createNode(NodeType _type)`: Creates a new node of a specified type.
5.  `deleteNode(uint256 _nodeId)`: Deletes a node. Requires specific conditions (e.g., state is Dormant or Degraded).
6.  `updateNodeAttributes(uint256 _nodeId, uint256[] memory _newAttributes)`: Allows owner/specific role to manually update node attributes.
7.  `transitionNodeState(uint256 _nodeId, NodeState _newState)`: Attempts to change a node's state. Checks for valid transitions (logic internal to the function or based on state/attributes).
8.  `activateNode(uint256 _nodeId)`: Specific helper to transition node to Active state (if allowed).
9.  `deactivateNode(uint256 _nodeId)`: Specific helper to transition node to Dormant state (if allowed).
10. `corruptNode(uint256 _nodeId)`: Specific helper to transition node to Degraded state (if allowed/triggered).
11. `createRelationship(uint256 _node1Id, uint256 _node2Id, RelationshipType _type)`: Creates a directed relationship from node1 to node2 with a type.
12. `removeRelationship(uint256 _node1Id, uint256 _node2Id)`: Removes a relationship between two nodes.
13. `triggerSynergyEffect(uint256 _nodeId)`: Calculates and applies attribute modifications to a node based on its relationships and neighbors' states/attributes and the defined `relationshipEffects`.
14. `applyTemporalEffects(uint256 _nodeId)`: Applies time-based changes (decay, growth) to a node's attributes based on its state and elapsed time since last update. Updates the `lastUpdated` timestamp.
15. `propagateStateChange(uint256 _nodeId)`: When a node changes state, this function is called internally or externally to check if its state change should influence the states of its immediate neighbors (e.g., Degraded node might push neighbors towards Dormant). This is a core interactive function.
16. `calculateInfluenceScore(uint256 _nodeId)`: Computes a dynamic score based on a node's current state, attributes, and the states/relationships of its neighbors. (View function).
17. `getNode(uint256 _nodeId)`: Retrieves the full data for a specific node. (View function).
18. `getNodeState(uint256 _nodeId)`: Retrieves only the state of a node. (View function).
19. `getNodeAttribute(uint256 _nodeId, uint256 _attributeIndex)`: Retrieves a specific attribute of a node. (View function).
20. `getRelationshipType(uint256 _node1Id, uint256 _node2Id)`: Retrieves the type of relationship between two nodes. (View function).
21. `getTotalNodes()`: Returns the total number of nodes created. (View function).
22. `getNodesByState(NodeState _state)`: Returns an array of node IDs that are currently in the specified state. (View function - gas caution).
23. `canTransitionState(uint256 _nodeId, NodeState _newState)`: Checks if a specific state transition is currently valid for a node based on internal rules/conditions. (View function).
24. `simulateSystemTick(uint256[] memory _nodeIds)`: Applies both `applyTemporalEffects` and `triggerSynergyEffect` to a batch of specified nodes. (Callable by authorized entity or owner due to gas).
25. `attuneNode(uint256 _nodeId, uint256 _targetNodeId)`: Attempts to align some attributes or state parameters of `_nodeId` with `_targetNodeId` if a suitable relationship exists. (Creative interaction).
26. `initiateCascade(uint256 _startingNodeId, NodeState _triggerState)`: Initiates a multi-step process (or limited steps for gas) where a node in a trigger state attempts to push neighbors into certain states, and those neighbors *might* propagate further. (Advanced, gas caution).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Outline:
// 1. Contract Name: SynergisticStateEngine
// 2. Core Concepts: Nodes, States, Attributes, Relationships, Synergy, Temporal Dynamics, State Propagation.
// 3. Key Data Structures: NodeState, NodeType, RelationshipType (enums), Node (struct), Relationship (mapping).
// 4. Key Mechanisms: Node Management, State Transitions, Relationship Management, Synergy & Interaction, Temporal Effects, State Propagation, Querying, Admin/Setup.

// Function Summary:
// 1. constructor(): Initializes the contract, setting the owner.
// 2. setNodeBaseAttributes(NodeType _type, uint256[] memory _attributes): Owner sets base attribute values for a specific node type.
// 3. setRelationshipEffects(RelationshipType _type, int256[] memory _attributeModifiers): Owner sets how a relationship type modifies neighbor attributes during synergy calculation.
// 4. createNode(NodeType _type): Creates a new node of a specified type.
// 5. deleteNode(uint256 _nodeId): Deletes a node (requires specific state).
// 6. updateNodeAttributes(uint256 _nodeId, uint256[] memory _newAttributes): Owner/admin updates node attributes.
// 7. transitionNodeState(uint256 _nodeId, NodeState _newState): Attempts state change based on rules.
// 8. activateNode(uint256 _nodeId): Helper to transition to Active.
// 9. deactivateNode(uint256 _nodeId): Helper to transition to Dormant.
// 10. corruptNode(uint256 _nodeId): Helper to transition to Degraded.
// 11. createRelationship(uint256 _node1Id, uint256 _node2Id, RelationshipType _type): Creates a directed relationship.
// 12. removeRelationship(uint256 _node1Id, uint256 _node2Id): Removes a relationship.
// 13. triggerSynergyEffect(uint256 _nodeId): Calculates and applies effects based on relationships/neighbors.
// 14. applyTemporalEffects(uint256 _nodeId): Applies time-based changes (decay/growth).
// 15. propagateStateChange(uint256 _nodeId): Influences neighbors' states based on a node's state change.
// 16. calculateInfluenceScore(uint256 _nodeId): Computes a dynamic score. (View)
// 17. getNode(uint256 _nodeId): Retrieves full node data. (View)
// 18. getNodeState(uint256 _nodeId): Retrieves node state. (View)
// 19. getNodeAttribute(uint256 _nodeId, uint256 _attributeIndex): Retrieves a specific attribute. (View)
// 20. getRelationshipType(uint256 _node1Id, uint256 _node2Id): Retrieves relationship type. (View)
// 21. getTotalNodes(): Returns total node count. (View)
// 22. getNodesByState(NodeState _state): Returns IDs of nodes in a state. (View - gas caution).
// 23. canTransitionState(uint256 _nodeId, NodeState _newState): Checks if a transition is possible. (View)
// 24. simulateSystemTick(uint256[] memory _nodeIds): Applies temporal & synergy effects to batch.
// 25. attuneNode(uint256 _nodeId, uint256 _targetNodeId): Attempts to align nodes based on relationships.
// 26. initiateCascade(uint256 _startingNodeId, NodeState _triggerState): Initiates a state-changing cascade through neighbors. (Advanced, gas caution).

contract SynergisticStateEngine {

    address public owner;
    uint256 private nextNodeId;

    enum NodeState {
        Inactive, // Default state, not participating in effects
        Active,   // Fully participating, potentially growing
        Dormant,  // Reduced activity, potentially decaying slowly
        Degraded  // Negative state, decaying rapidly, negative influence
    }

    enum NodeType {
        Basic,
        Advanced,
        Catalyst,
        Regenerator
    }

    enum RelationshipType {
        Neutral,     // No significant effect
        Symbiotic,   // Positive effect on neighbor
        Antagonistic,// Negative effect on neighbor
        Directive    // Node1 attempts to control Node2's state/attributes
    }

    struct Node {
        uint256 id;
        NodeType nodeType;
        NodeState state;
        uint256[] attributes; // e.g., [0: Power, 1: Resilience, 2: Complexity]
        uint40 lastUpdated; // Timestamp of last temporal/synergy update
        bool exists;        // Helper to check if ID is valid
    }

    mapping(uint256 => Node) public nodes;
    // mapping node1Id => mapping node2Id => RelationshipType
    mapping(uint256 => mapping(uint256 => RelationshipType)) private relationships;
    // To easily find neighbors for propagation/synergy, need inverse mapping or track relationships explicitly
    mapping(uint256 => uint256[]) private nodeNeighbors; // node1Id => list of node2Ids it has a relationship *to*
    mapping(uint256 => uint256[]) private nodeInverseNeighbors; // node2Id => list of node1Ids that have a relationship *to* it

    // Configuration: Base attributes for each Node Type
    mapping(NodeType => uint256[]) private nodeBaseAttributes;
    // Configuration: Attribute modifiers based on Relationship Type during synergy effect
    // Indexed by attribute index (0, 1, 2...)
    mapping(RelationshipType => int256[]) private relationshipEffects;

    // State Transition Rules (simplified: checks inside transitionNodeState)
    // For a more complex system, this could be a mapping:
    // mapping(NodeState => mapping(NodeState => bool)) private stateTransitionAllowed;
    // Or even mapping(NodeState => mapping(NodeState => bytes)) for condition logic bytes

    event NodeCreated(uint256 nodeId, NodeType nodeType, NodeState initialState);
    event NodeDeleted(uint256 nodeId);
    event NodeStateChanged(uint256 nodeId, NodeState oldState, NodeState newState);
    event NodeAttributesUpdated(uint256 nodeId, uint256[] newAttributes);
    event RelationshipCreated(uint256 node1Id, uint256 node2Id, RelationshipType relationshipType);
    event RelationshipRemoved(uint256 node1Id, uint256 node2Id);
    event SynergyEffectApplied(uint256 nodeId, int256[] attributeModifiers);
    event TemporalEffectsApplied(uint256 nodeId, int256[] attributeChanges);
    event StatePropagationAttempted(uint256 fromNodeId, uint256 toNodeId, NodeState fromState);
    event CascadeInitiated(uint256 startingNodeId, NodeState triggerState);


    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
        nextNodeId = 1; // Start node IDs from 1
    }

    // --- Admin & Setup Functions ---

    /**
     * @notice Sets the base attributes for a specific Node Type.
     * @param _type The NodeType to configure.
     * @param _attributes An array of base attribute values.
     */
    function setNodeBaseAttributes(NodeType _type, uint256[] memory _attributes) public onlyOwner {
        // Basic validation: ensure attribute array is not empty (or matches a expected length)
        require(_attributes.length > 0, "Attributes cannot be empty");
        nodeBaseAttributes[_type] = _attributes;
    }

    /**
     * @notice Sets the attribute modifiers for a specific Relationship Type.
     *         These modifiers are applied during synergy calculations.
     * @param _type The RelationshipType to configure.
     * @param _attributeModifiers An array of int256 modifiers.
     *                          Length should match the number of attributes.
     */
    function setRelationshipEffects(RelationshipType _type, int256[] memory _attributeModifiers) public onlyOwner {
         // Basic validation: ensure modifier array is not empty (or matches a expected length)
        require(_attributeModifiers.length > 0, "Attribute modifiers cannot be empty");
        relationshipEffects[_type] = _attributeModifiers;
    }

    // --- Node Management Functions ---

    /**
     * @notice Creates a new node of a specified type.
     *         Initial state is Inactive, attributes are set from base.
     * @param _type The NodeType of the new node.
     * @return The ID of the newly created node.
     */
    function createNode(NodeType _type) public returns (uint256) {
        require(nodeBaseAttributes[_type].length > 0, "Base attributes not set for this type");

        uint256 newNodeId = nextNodeId++;
        nodes[newNodeId] = Node({
            id: newNodeId,
            nodeType: _type,
            state: NodeState.Inactive,
            attributes: nodeBaseAttributes[_type], // Copy base attributes
            lastUpdated: uint40(block.timestamp),
            exists: true
        });

        emit NodeCreated(newNodeId, _type, NodeState.Inactive);
        return newNodeId;
    }

    /**
     * @notice Deletes a node. Only allowed if the node is in a specific state (e.g., Dormant or Degraded).
     *         Removes related relationships.
     * @param _nodeId The ID of the node to delete.
     */
    function deleteNode(uint256 _nodeId) public onlyOwner {
        require(nodes[_nodeId].exists, "Node does not exist");
        Node storage nodeToDelete = nodes[_nodeId];

        // Example condition: Only delete if Dormant or Degraded
        require(nodeToDelete.state == NodeState.Dormant || nodeToDelete.state == NodeState.Degraded,
            "Node must be Dormant or Degraded to be deleted");

        // Clean up relationships involving this node
        uint256[] memory neighborsToRemove = new uint256[](nodeNeighbors[_nodeId].length);
        for(uint i = 0; i < nodeNeighbors[_nodeId].length; i++) {
            neighborsToRemove[i] = nodeNeighbors[_nodeId][i];
        }
         for(uint i = 0; i < neighborsToRemove.length; i++) {
            removeRelationship(_nodeId, neighborsToRemove[i]);
        }

        uint256[] memory inverseNeighborsToRemove = new uint256[](nodeInverseNeighbors[_nodeId].length);
        for(uint i = 0; i < nodeInverseNeighbors[_nodeId].length; i++) {
            inverseNeighborsToRemove[i] = nodeInverseNeighbors[_nodeId][i];
        }
        for(uint i = 0; i < inverseNeighborsToRemove.length; i++) {
             removeRelationship(inverseNeighborsToRemove[i], _nodeId);
        }

        // Mark as non-existent (cannot truly delete from mapping)
        nodeToDelete.exists = false;
        // Optionally clear data to save gas on future reads, though `exists` check is sufficient
        // delete nodes[_nodeId]; // Use this if you don't rely on historical non-existent entries

        emit NodeDeleted(_nodeId);
    }


    /**
     * @notice Allows the owner to directly update a node's attributes.
     *         Can be used for admin adjustments or specific game mechanics.
     * @param _nodeId The ID of the node to update.
     * @param _newAttributes The new array of attribute values.
     */
    function updateNodeAttributes(uint256 _nodeId, uint256[] memory _newAttributes) public onlyOwner {
        require(nodes[_nodeId].exists, "Node does not exist");
        Node storage node = nodes[_nodeId];
        require(_newAttributes.length == node.attributes.length, "Attribute array length mismatch");

        node.attributes = _newAttributes;
        emit NodeAttributesUpdated(_nodeId, _newAttributes);
    }

    // --- State Transition Functions ---

    /**
     * @notice Attempts to transition a node to a new state.
     *         Includes internal checks for valid transitions based on current state/attributes.
     * @param _nodeId The ID of the node.
     * @param _newState The desired new state.
     */
    function transitionNodeState(uint256 _nodeId, NodeState _newState) public {
        require(nodes[_nodeId].exists, "Node does not exist");
        Node storage node = nodes[_nodeId];
        NodeState oldState = node.state;

        if (oldState == _newState) {
            return; // No change needed
        }

        bool allowed = false;
        // --- Example State Transition Logic (can be complex) ---
        if (oldState == NodeState.Inactive) {
            if (_newState == NodeState.Active) {
                // Example: Requires minimum Power attribute to become Active
                if (node.attributes.length > 0 && node.attributes[0] >= 50) allowed = true;
            } else if (_newState == NodeState.Dormant) {
                 // Example: Inactive can freely go to Dormant
                 allowed = true;
            }
        } else if (oldState == NodeState.Active) {
             if (_newState == NodeState.Dormant) {
                 // Example: Can go Dormant if Resilience is low
                 if (node.attributes.length > 1 && node.attributes[1] < 30) allowed = true;
                 // Or if manually triggered
                 if (msg.sender == owner) allowed = true; // Owner override
            } else if (_newState == NodeState.Degraded) {
                 // Example: Can become Degraded if Resilience is very low AND Power is low
                 if (node.attributes.length > 1 && node.attributes[1] < 10 && node.attributes[0] < 20) allowed = true;
            }
        } else if (oldState == NodeState.Dormant) {
            if (_newState == NodeState.Active) {
                // Example: Requires manual activation AND high complexity
                if (msg.sender == owner && node.attributes.length > 2 && node.attributes[2] >= 80) allowed = true;
            } else if (_newState == NodeState.Degraded) {
                // Example: Dormant can become Degraded if time passes without activation (handled by temporal effects often)
                 // Or if manually triggered by owner
                 if (msg.sender == owner) allowed = true;
            } else if (_newState == NodeState.Inactive) {
                 // Example: Dormant can return to Inactive
                 allowed = true;
            }
        } else if (oldState == NodeState.Degraded) {
            if (_newState == NodeState.Inactive) {
                // Example: Degraded can only become Inactive if Resilience is somehow restored (unlikely state transition)
                 // Or manual reset by owner
                 if (msg.sender == owner && node.attributes.length > 1 && node.attributes[1] >= 50) allowed = true;
            }
             // Degraded usually cannot go to Active or Dormant without complex healing/reset
        }
        // --- End Example State Transition Logic ---

        require(allowed, "Invalid state transition");

        node.state = _newState;
        node.lastUpdated = uint40(block.timestamp); // Reset timer on state change
        emit NodeStateChanged(_nodeId, oldState, _newState);

        // Automatically attempt state propagation after a change
        propagateStateChange(_nodeId);
    }

    // Helper functions for specific common transitions
    function activateNode(uint256 _nodeId) public {
        transitionNodeState(_nodeId, NodeState.Active);
    }

    function deactivateNode(uint256 _nodeId) public {
         transitionNodeState(_nodeId, NodeState.Dormant);
    }

     function corruptNode(uint256 _nodeId) public {
        transitionNodeState(_nodeId, NodeState.Degraded);
    }

    // --- Relationship Management Functions ---

    /**
     * @notice Creates a directed relationship from _node1Id to _node2Id.
     * @param _node1Id The source node ID.
     * @param _node2Id The target node ID.
     * @param _type The type of relationship.
     */
    function createRelationship(uint256 _node1Id, uint256 _node2Id, RelationshipType _type) public {
        require(nodes[_node1Id].exists, "Node 1 does not exist");
        require(nodes[_node2Id].exists, "Node 2 does not exist");
        require(_node1Id != _node2Id, "Cannot create relationship to self");

        // Prevent duplicate relationships
        if (relationships[_node1Id][_node2Id] != RelationshipType.Neutral || nodeNeighbors[_node1Id].length > 0) {
             // Check if it already exists in the neighbors list
             bool exists = false;
             for(uint i = 0; i < nodeNeighbors[_node1Id].length; i++) {
                 if (nodeNeighbors[_node1Id][i] == _node2Id) {
                     exists = true;
                     break;
                 }
             }
             require(!exists, "Relationship already exists");
        }


        relationships[_node1Id][_node2Id] = _type;
        nodeNeighbors[_node1Id].push(_node2Id);
        nodeInverseNeighbors[_node2Id].push(_node1Id);

        emit RelationshipCreated(_node1Id, _node2Id, _type);
    }

    /**
     * @notice Removes a relationship from _node1Id to _node2Id.
     * @param _node1Id The source node ID.
     * @param _node2Id The target node ID.
     */
    function removeRelationship(uint256 _node1Id, uint256 _node2Id) public {
        require(nodes[_node1Id].exists, "Node 1 does not exist");
        require(nodes[_node2Id].exists, "Node 2 does not exist");
        require(relationships[_node1Id][_node2Id] != RelationshipType.Neutral, "Relationship does not exist"); // Check if it was set away from default

        delete relationships[_node1Id][_node2Id];

        // Remove from nodeNeighbors (linear scan, gas intensive for many neighbors)
        uint265 neighborIndex = type(uint265).max;
        for (uint i = 0; i < nodeNeighbors[_node1Id].length; i++) {
            if (nodeNeighbors[_node1Id][i] == _node2Id) {
                neighborIndex = i;
                break;
            }
        }
        require(neighborIndex != type(uint265).max, "Relationship not found in neighbors list"); // Should not happen if relationships mapping is correct

        // Swap last element with the one to remove and pop
        if (neighborIndex < nodeNeighbors[_node1Id].length - 1) {
            nodeNeighbors[_node1Id][neighborIndex] = nodeNeighbors[_node1Id][nodeNeighbors[_node1Id].length - 1];
        }
        nodeNeighbors[_node1Id].pop();


        // Remove from nodeInverseNeighbors (linear scan)
         uint265 inverseNeighborIndex = type(uint265).max;
        for (uint i = 0; i < nodeInverseNeighbors[_node2Id].length; i++) {
            if (nodeInverseNeighbors[_node2Id][i] == _node1Id) {
                inverseNeighborIndex = i;
                break;
            }
        }
         require(inverseNeighborIndex != type(uint265).max, "Relationship not found in inverse neighbors list"); // Should not happen

        // Swap last element with the one to remove and pop
        if (inverseNeighborIndex < nodeInverseNeighbors[_node2Id].length - 1) {
            nodeInverseNeighbors[_node2Id][inverseNeighborIndex] = nodeInverseNeighbors[_node2Id][nodeInverseNeighbors[_node2Id].length - 1];
        }
        nodeInverseNeighbors[_node2Id].pop();


        emit RelationshipRemoved(_node1Id, _node2Id);
    }

    // --- Interaction & Dynamic Effect Functions ---

    /**
     * @notice Calculates and applies attribute changes to a node based on its incoming relationships
     *         and the states/types of the nodes connecting to it (its inverse neighbors).
     *         The effects are based on the configured `relationshipEffects`.
     * @param _nodeId The ID of the node receiving the synergy effect.
     */
    function triggerSynergyEffect(uint256 _nodeId) public {
         require(nodes[_nodeId].exists, "Node does not exist");
         Node storage node = nodes[_nodeId];

         if (node.state == NodeState.Inactive) {
             // Inactive nodes don't receive synergy effects
             return;
         }

         int256[] memory totalAttributeModifiers = new int256[](node.attributes.length);
         // Initialize with zeros
         for(uint i = 0; i < totalAttributeModifiers.length; i++) {
             totalAttributeModifiers[i] = 0;
         }

         uint256[] memory incomingNeighbors = nodeInverseNeighbors[_nodeId];

         for(uint i = 0; i < incomingNeighbors.length; i++) {
             uint256 neighborId = incomingNeighbors[i];
             Node storage neighborNode = nodes[neighborId];

             // Synergy depends on neighbor's state and the relationship type
             if (neighborNode.exists && neighborNode.state != NodeState.Inactive) {
                 RelationshipType relType = relationships[neighborId][_nodeId];
                 int256[] memory modifiers = relationshipEffects[relType];

                 // Ensure modifier length matches node attribute length
                 if (modifiers.length == node.attributes.length) {
                     for(uint j = 0; j < node.attributes.length; j++) {
                          int256 modifier = modifiers[j];

                         // Example logic: Antagonistic effects are stronger if neighbor is Degraded
                         if (relType == RelationshipType.Antagonistic && neighborNode.state == NodeState.Degraded) {
                             modifier = modifier * 2; // Double the negative impact
                         }
                          // Example logic: Symbiotic effects are stronger if neighbor is Active
                         if (relType == RelationshipType.Symbiotic && neighborNode.state == NodeState.Active) {
                             modifier = modifier * 2; // Double the positive impact
                         }
                         // Example logic: Directive relationship might scale modifier by neighbor's Complexity attribute (index 2)
                          if (relType == RelationshipType.Directive && neighborNode.attributes.length > 2) {
                              modifier = (modifier * int256(neighborNode.attributes[2])) / 100; // Scale by complexity (assuming complexity is 0-100)
                          }


                         totalAttributeModifiers[j] += modifier;
                     }
                 }
             }
         }

         // Apply the calculated modifiers to the node's attributes
         bool attributesChanged = false;
         for(uint i = 0; i < node.attributes.length; i++) {
             int256 currentAttr = int256(node.attributes[i]);
             int256 newAttr = currentAttr + totalAttributeModifiers[i];

             // Prevent attributes from going negative
             if (newAttr < 0) newAttr = 0;

             if (uint256(newAttr) != node.attributes[i]) {
                 node.attributes[i] = uint256(newAttr);
                 attributesChanged = true;
             }
         }

         if (attributesChanged) {
             emit SynergyEffectApplied(_nodeId, totalAttributeModifiers);
             // Note: state transition might be triggered as a *result* of attribute changes
             // This could be checked here or by a separate function that monitors attributes
         }
         node.lastUpdated = uint40(block.timestamp); // Update timestamp as effects were applied
    }

    /**
     * @notice Applies time-based changes (decay or growth) to a node's attributes
     *         based on its current state and the time elapsed since its last update.
     * @param _nodeId The ID of the node.
     */
    function applyTemporalEffects(uint256 _nodeId) public {
         require(nodes[_nodeId].exists, "Node does not exist");
         Node storage node = nodes[_nodeId];
         uint256 timeElapsed = block.timestamp - node.lastUpdated;

         if (timeElapsed == 0 || node.state == NodeState.Inactive) {
             // No time passed or Inactive nodes don't change over time
             return;
         }

         // Example Temporal Logic:
         int256 decayRate = 1; // Base decay per unit of time
         int256 growthRate = 1; // Base growth per unit of time
         int256[] memory attributeChanges = new int256[](node.attributes.length);


         if (node.state == NodeState.Active) {
              // Active nodes grow some attributes, decay others slower
              // e.g., Power (0) grows, Resilience (1) decays slowly
              if (node.attributes.length > 0) attributeChanges[0] += int256(timeElapsed) * growthRate;
               if (node.attributes.length > 1) attributeChanges[1] -= int256(timeElapsed) * (decayRate / 2); // Slower decay
         } else if (node.state == NodeState.Dormant) {
              // Dormant nodes decay attributes
             for(uint i = 0; i < attributeChanges.length; i++) {
                 attributeChanges[i] -= int256(timeElapsed) * decayRate;
             }
         } else if (node.state == NodeState.Degraded) {
             // Degraded nodes decay rapidly
             for(uint i = 0; i < attributeChanges.length; i++) {
                 attributeChanges[i] -= int256(timeElapsed) * (decayRate * 2); // Faster decay
             }
         }
         // Inactive state handled by the initial check

         bool attributesChanged = false;
         for(uint i = 0; i < node.attributes.length; i++) {
             int256 currentAttr = int256(node.attributes[i]);
             int256 newAttr = currentAttr + attributeChanges[i];

             // Prevent attributes from going negative
             if (newAttr < 0) newAttr = 0;

              // Simple cap on max value (e.g., attributes cannot exceed 1000)
             if (newAttr > 1000) newAttr = 1000;


             if (uint256(newAttr) != node.attributes[i]) {
                 node.attributes[i] = uint256(newAttr);
                 attributesChanged = true;
             }
         }

         if (attributesChanged) {
              emit TemporalEffectsApplied(_nodeId, attributeChanges);
         }
         node.lastUpdated = uint40(block.timestamp); // Update timestamp
         // Note: state transition might be triggered as a *result* of attribute changes
    }

    /**
     * @notice Attempts to propagate a state change from _nodeId to its immediate neighbors.
     *         The rules for propagation are defined internally based on the source node's new state
     *         and the relationship type to the neighbor. Limited depth for gas safety.
     * @param _nodeId The ID of the node whose state changed.
     */
    function propagateStateChange(uint256 _nodeId) public {
        require(nodes[_nodeId].exists, "Node does not exist");
        Node storage sourceNode = nodes[_nodeId];
        NodeState sourceState = sourceNode.state;

        uint256[] memory neighbors = nodeNeighbors[_nodeId]; // Neighbors this node has a relationship *to*

        for(uint i = 0; i < neighbors.length; i++) {
            uint256 neighborId = neighbors[i];
            if (!nodes[neighborId].exists) continue; // Skip if neighbor was deleted

            Node storage neighborNode = nodes[neighborId];
            RelationshipType relType = relationships[_nodeId][neighborId];

            // --- Example Propagation Logic ---
            // A Degraded source node might try to push neighbors to Dormant
            if (sourceState == NodeState.Degraded) {
                 if (neighborNode.state != NodeState.Degraded && neighborNode.state != NodeState.Inactive) {
                     // If relationship is Antagonistic, strongly push to Dormant
                     if (relType == RelationshipType.Antagonistic) {
                         // Attempt transition, but check if allowed by neighbor's rules
                         if (canTransitionState(neighborId, NodeState.Dormant)) {
                              neighborNode.state = NodeState.Dormant;
                              neighborNode.lastUpdated = uint40(block.timestamp); // Reset timer
                              emit NodeStateChanged(neighborId, neighborNode.state, NodeState.Dormant);
                              emit StatePropagationAttempted(_nodeId, neighborId, sourceState);
                              // Note: This doesn't trigger *further* propagation from the neighbor to prevent cascades running wild
                              // A more complex system might put neighbors in a queue for later processing
                         }
                     }
                      // If relationship is Directive, try to force Dormant/Degraded regardless of neighbor state
                      if (relType == RelationshipType.Directive && msg.sender == owner) { // Directive might need owner consent/trigger
                           if (neighborNode.state != NodeState.Degraded) {
                                neighborNode.state = NodeState.Degraded; // Force Degradation
                                neighborNode.lastUpdated = uint40(block.timestamp);
                                emit NodeStateChanged(neighborId, neighborNode.state, NodeState.Degraded);
                                emit StatePropagationAttempted(_nodeId, neighborId, sourceState);
                           }
                      }
                 }
            }
            // An Active source node might try to pull neighbors to Active if Symbiotic
            if (sourceState == NodeState.Active && neighborNode.state == NodeState.Dormant && relType == RelationshipType.Symbiotic) {
                 if (canTransitionState(neighborId, NodeState.Active)) {
                      neighborNode.state = NodeState.Active;
                       neighborNode.lastUpdated = uint40(block.timestamp);
                      emit NodeStateChanged(neighborId, neighborNode.state, NodeState.Active);
                      emit StatePropagationAttempted(_nodeId, neighborId, sourceState);
                 }
            }
            // --- End Example Propagation Logic ---
        }
        // Note: Inverse neighbors (nodes pointing *to* this node) could also be influenced
        // but for simplicity and gas, this example only propagates forward.
    }

    /**
     * @notice Initiates a cascade effect. A node in a specific trigger state
     *         attempts to push neighbors into target states, and *those* neighbors
     *         might then attempt to push their neighbors, up to a limited depth.
     *         **Caution:** Can be very gas-intensive for large networks.
     * @param _startingNodeId The node where the cascade begins.
     * @param _triggerState The state the starting node must be in to trigger the cascade.
     */
    function initiateCascade(uint256 _startingNodeId, NodeState _triggerState) public onlyOwner { // Restrict to owner due to gas
        require(nodes[_startingNodeId].exists, "Starting node does not exist");
        Node storage startNode = nodes[_startingNodeId];
        require(startNode.state == _triggerState, "Starting node is not in the trigger state");

        emit CascadeInitiated(_startingNodeId, _triggerState);

        // Use a simple queue-like structure (array) and a visited map
        uint256[] memory queue = new uint256[](1);
        queue[0] = _startingNodeId;
        mapping(uint256 => bool) visited;
        visited[_startingNodeId] = true;

        uint256 head = 0;
        uint256 maxDepth = 2; // Limit cascade depth for gas safety

        while (head < queue.length && head < maxDepth + 1) {
            uint256 currentNodeId = queue[head];
            head++;

            Node storage currentNode = nodes[currentNodeId];
             // Only nodes in certain states propagate effects further in this example
            if (currentNode.state != NodeState.Degraded && currentNode.state != NodeState.Active) {
                 continue;
            }


            uint224[] memory neighborsToQueue = new uint224[](nodeNeighbors[currentNodeId].length);
            uint256 neighborsCount = 0;

            uint256[] memory neighbors = nodeNeighbors[currentNodeId];

            for(uint i = 0; i < neighbors.length; i++) {
                uint256 neighborId = neighbors[i];
                if (!nodes[neighborId].exists || visited[neighborId]) continue;

                Node storage neighborNode = nodes[neighborId];
                RelationshipType relType = relationships[currentNodeId][neighborId];

                bool influenced = false;
                 // --- Example Cascade Logic ---
                 if (currentNode.state == NodeState.Degraded) {
                     // Degraded node attempts to push any neighbor (unless already Degraded/Inactive) towards Dormant/Degraded
                     if (neighborNode.state != NodeState.Degraded && neighborNode.state != NodeState.Inactive) {
                         if (relType == RelationshipType.Antagonistic || relType == RelationshipType.Directive) {
                              NodeState targetState = (relType == RelationshipType.Directive && msg.sender == owner) ? NodeState.Degraded : NodeState.Dormant;
                              if (canTransitionState(neighborId, targetState)) {
                                  neighborNode.state = targetState;
                                  neighborNode.lastUpdated = uint40(block.timestamp);
                                  emit NodeStateChanged(neighborId, neighborNode.state, targetState);
                                  emit StatePropagationAttempted(currentNodeId, neighborId, currentNode.state);
                                  influenced = true;
                              }
                         } else { // Other relationship types also get a smaller chance of influence
                             if (canTransitionState(neighborId, NodeState.Dormant)) { // Maybe only push to Dormant
                                NodeState targetState = NodeState.Dormant;
                                if (canTransitionState(neighborId, targetState)){
                                     neighborNode.state = targetState;
                                     neighborNode.lastUpdated = uint40(block.timestamp);
                                     emit NodeStateChanged(neighborId, neighborNode.state, targetState);
                                     emit StatePropagationAttempted(currentNodeId, neighborId, currentNode.state);
                                     influenced = true;
                                }
                             }
                         }
                     }
                 } else if (currentNode.state == NodeState.Active) {
                      // Active node attempts to pull Symbiotic/Directive neighbors towards Active
                      if (neighborNode.state == NodeState.Dormant || neighborNode.state == NodeState.Inactive) {
                           if (relType == RelationshipType.Symbiotic || relType == RelationshipType.Directive) {
                                NodeState targetState = NodeState.Active;
                                if (canTransitionState(neighborId, targetState)) {
                                    neighborNode.state = targetState;
                                    neighborNode.lastUpdated = uint40(block.timestamp);
                                    emit NodeStateChanged(neighborId, neighborNode.state, targetState);
                                    emit StatePropagationAttempted(currentNodeId, neighborId, currentNode.state);
                                    influenced = true;
                                }
                           }
                      }
                 }
                // --- End Example Cascade Logic ---

                // If the neighbor was influenced AND hasn't been visited in *this cascade*
                if (influenced && !visited[neighborId]) {
                    visited[neighborId] = true;
                    neighborsToQueue[neighborsCount] = uint224(neighborId); // Add to temporary list
                    neighborsCount++;
                }
            }

             // Add successfully influenced & unvisited neighbors to the queue
             if (neighborsCount > 0) {
                 uint256 currentQueueLength = queue.length;
                 // Increase queue size
                 assembly {
                      let newQueue := mload(0x40) // Get free memory pointer
                      let newSize := add(currentQueueLength, neighborsCount)
                      mstore(newQueue, newSize) // Store new size at the start
                      mstore(0x40, add(newQueue, mul(newSize, 0x20))) // Update free memory pointer

                     // Copy existing queue elements
                      let oldQueueData := add(queue, 0x20) // Pointer to the actual data of the old queue
                      let newQueueData := add(newQueue, 0x20)
                     // Using copy effectively requires manual copying element by element or using a helper like arrayCopy
                     // For simplicity and gas, let's manually extend and copy
                 }

                // Manual copy/append (less gas efficient than assembly but safer)
                 uint256[] memory newQueue = new uint256[](currentQueueLength + neighborsCount);
                 for(uint k = 0; k < currentQueueLength; k++) {
                     newQueue[k] = queue[k];
                 }
                 for(uint k = 0; k < neighborsCount; k++) {
                      newQueue[currentQueueLength + k] = neighborsToQueue[k];
                 }
                 queue = newQueue; // Replace queue with the extended one

             }
        }
        // Cascade simulation ends due to queue exhaustion or maxDepth limit
    }


     /**
      * @notice Applies both temporal effects and synergy effects to a batch of nodes.
      *         Useful for processing multiple nodes in one transaction.
      * @param _nodeIds An array of node IDs to process.
      */
    function simulateSystemTick(uint265[] memory _nodeIds) public onlyOwner { // Restrict to owner due to potential gas cost
         for(uint i = 0; i < _nodeIds.length; i++) {
             uint256 nodeId = _nodeIds[i];
             if (nodes[nodeId].exists && nodes[nodeId].state != NodeState.Inactive) {
                 applyTemporalEffects(nodeId); // Apply time-based changes
                 triggerSynergyEffect(nodeId); // Apply neighbor-based changes
                 // Note: State transitions might occur *after* these effects change attributes.
                 // A more complex system might re-evaluate state transitions here.
             }
         }
    }

    /**
     * @notice Attempts to align attributes or state of _nodeId with _targetNodeId
     *         if a Directive or Symbiotic relationship exists.
     * @param _nodeId The node to attune.
     * @param _targetNodeId The node to attune towards.
     */
    function attuneNode(uint256 _nodeId, uint256 _targetNodeId) public {
        require(nodes[_nodeId].exists, "Node does not exist");
        require(nodes[_targetNodeId].exists, "Target node does not exist");
        require(_nodeId != _targetNodeId, "Cannot attune to self");

        RelationshipType relType1 = relationships[_nodeId][_targetNodeId]; // Relationship FROM node TO target
        RelationshipType relType2 = relationships[_targetNodeId][_nodeId]; // Relationship FROM target TO node

        bool canAttune = false;
        if (relType1 == RelationshipType.Directive) canAttune = true; // Node is directed by target
        if (relType2 == RelationshipType.Directive && msg.sender == owner) canAttune = true; // Owner forces target to direct node
        if (relType1 == RelationshipType.Symbiotic && relType2 == RelationshipType.Symbiotic) canAttune = true; // Mutual Symbiosis

        require(canAttune, "Nodes are not configured for attunement");

        Node storage node = nodes[_nodeId];
        Node storage targetNode = nodes[_targetNodeId];

        // --- Example Attunement Logic ---
        // If Directive: Try to match State and some attributes (e.g., Complexity)
        if (relType1 == RelationshipType.Directive && msg.sender != owner) { // Non-owner triggered Directive attunement
             // Try to transition node to target's state (if valid transition)
             if (canTransitionState(_nodeId, targetNode.state)) {
                  transitionNodeState(_nodeId, targetNode.state);
             }
             // Try to pull Complexity attribute (index 2) towards target's complexity (limited pull)
             if (node.attributes.length > 2 && targetNode.attributes.length > 2) {
                  uint256 complexityDiff = 0;
                  if (targetNode.attributes[2] > node.attributes[2]) {
                      complexityDiff = targetNode.attributes[2] - node.attributes[2];
                      node.attributes[2] += complexityDiff / 10; // Pull 10% of the difference
                  } else if (node.attributes[2] > targetNode.attributes[2]) {
                       complexityDiff = node.attributes[2] - targetNode.attributes[2];
                       node.attributes[2] -= complexityDiff / 10; // Pull 10% of the difference
                  }
                   emit NodeAttributesUpdated(_nodeId, node.attributes);
             }
        } else if (relType1 == RelationshipType.Symbiotic && relType2 == RelationshipType.Symbiotic) {
             // Mutual Symbiosis: Average some attributes?
             if (node.attributes.length > 0 && targetNode.attributes.length > 0) {
                  uint256 minLen = node.attributes.length < targetNode.attributes.length ? node.attributes.length : targetNode.attributes.length;
                  bool changed = false;
                  for(uint i = 0; i < minLen; i++) {
                      uint256 avg = (node.attributes[i] + targetNode.attributes[i]) / 2;
                      if (node.attributes[i] != avg) {
                           node.attributes[i] = avg;
                           changed = true;
                      }
                  }
                  if (changed) {
                       emit NodeAttributesUpdated(_nodeId, node.attributes);
                  }
             }
        }
        // --- End Example Attunement Logic ---

         node.lastUpdated = uint40(block.timestamp); // Consider attunement an update
         targetNode.lastUpdated = uint40(block.timestamp); // Also update target? Depends on logic.
    }


    // --- Querying Functions ---

    /**
     * @notice Calculates a dynamic influence score for a node based on its state, attributes,
     *         and the states/relationships of its neighbors.
     * @param _nodeId The ID of the node.
     * @return The calculated influence score.
     */
    function calculateInfluenceScore(uint256 _nodeId) public view returns (int256) {
        require(nodes[_nodeId].exists, "Node does not exist");
        Node storage node = nodes[_nodeId];

        int256 score = 0;

        // Base score from state
        if (node.state == NodeState.Active) score += 100;
        else if (node.state == NodeState.Dormant) score += 20;
        else if (node.state == NodeState.Degraded) score -= 50; // Negative influence

        // Score from attributes (example: sum of attributes)
        for(uint i = 0; i < node.attributes.length; i++) {
            score += int256(node.attributes[i]);
        }

        // Score from relationships and neighbors (example: sum of neighbor power, modified by relationship type)
        uint256[] memory neighbors = nodeNeighbors[_nodeId]; // Nodes this node influences
        for(uint i = 0; i < neighbors.length; i++) {
            uint256 neighborId = neighbors[i];
            if (!nodes[neighborId].exists) continue;

            Node storage neighborNode = nodes[neighborId];
            RelationshipType relType = relationships[_nodeId][neighborId];

            // Example: Positive influence if pushing towards Active/Healthy states, negative if pushing towards Degraded
            if (neighborNode.state == NodeState.Active && relType == RelationshipType.Symbiotic) score += 10;
            if (neighborNode.state == NodeState.Degraded && relType == RelationshipType.Antagonistic) score -= 15;

             // Example: Add neighbor's Power (attribute 0) scaled by relationship type
             if (neighborNode.attributes.length > 0) {
                  int256 neighborPower = int256(neighborNode.attributes[0]);
                  if (relType == RelationshipType.Symbiotic) score += neighborPower / 5; // Add some scaled power
                  else if (relType == RelationshipType.Antagonistic) score -= neighborPower / 10; // Subtract some scaled power
             }
        }

         uint256[] memory inverseNeighbors = nodeInverseNeighbors[_nodeId]; // Nodes influencing this node
         for(uint i = 0; i < inverseNeighbors.length; i++) {
              uint256 neighborId = inverseNeighbors[i];
              if (!nodes[neighborId].exists) continue;

              Node storage neighborNode = nodes[neighborId];
              RelationshipType relType = relationships[neighborId][_nodeId];

              // Example: Score based on how others influence THIS node
              if (relType == RelationshipType.Directive) score += 20; // Being 'important' enough to be directed
              if (relType == RelationshipType.Antagonistic && neighborNode.state == NodeState.Degraded) score -= 30; // Strongly negatively influenced
         }


        return score;
    }


    /**
     * @notice Retrieves the full data struct for a node.
     * @param _nodeId The ID of the node.
     * @return The Node struct data.
     */
    function getNode(uint256 _nodeId) public view returns (Node memory) {
        require(nodes[_nodeId].exists, "Node does not exist");
        return nodes[_nodeId];
    }

     /**
     * @notice Retrieves the current state of a node.
     * @param _nodeId The ID of the node.
     * @return The NodeState of the node.
     */
    function getNodeState(uint256 _nodeId) public view returns (NodeState) {
        require(nodes[_nodeId].exists, "Node does not exist");
        return nodes[_nodeId].state;
    }

    /**
     * @notice Retrieves a specific attribute value of a node.
     * @param _nodeId The ID of the node.
     * @param _attributeIndex The index of the attribute (e.g., 0 for Power).
     * @return The value of the requested attribute.
     */
    function getNodeAttribute(uint256 _nodeId, uint256 _attributeIndex) public view returns (uint256) {
        require(nodes[_nodeId].exists, "Node does not exist");
        require(_attributeIndex < nodes[_nodeId].attributes.length, "Attribute index out of bounds");
        return nodes[_nodeId].attributes[_attributeIndex];
    }

    /**
     * @notice Retrieves the type of relationship from _node1Id to _node2Id.
     * @param _node1Id The source node ID.
     * @param _node2Id The target node ID.
     * @return The RelationshipType between the nodes. Returns Neutral if no explicit relationship exists.
     */
    function getRelationshipType(uint256 _node1Id, uint256 _node2Id) public view returns (RelationshipType) {
         require(nodes[_node1Id].exists, "Node 1 does not exist");
         require(nodes[_node2Id].exists, "Node 2 does not exist");
         return relationships[_node1Id][_node2Id]; // Returns default (Neutral) if not set
    }

     /**
     * @notice Returns the total count of nodes created (including deleted but not cleared).
     * @return The total number of nodes created.
     */
    function getTotalNodes() public view returns (uint256) {
        return nextNodeId - 1; // nextNodeId is one more than the last created ID
    }

    /**
     * @notice Returns an array of node IDs that are currently in the specified state.
     *         **Caution:** Can be very gas-intensive if there are many nodes.
     * @param _state The state to filter by.
     * @return An array of node IDs.
     */
    function getNodesByState(NodeState _state) public view returns (uint256[] memory) {
         uint256[] memory nodeIds = new uint256[](getTotalNodes()); // Max possible size
         uint256 count = 0;
         // Iterate through all possible IDs up to the last created one
         for(uint256 i = 1; i < nextNodeId; i++) {
             if (nodes[i].exists && nodes[i].state == _state) {
                 nodeIds[count] = i;
                 count++;
             }
         }
         // Return a correctly sized array
         uint256[] memory result = new uint256[](count);
         for(uint i = 0; i < count; i++) {
             result[i] = nodeIds[i];
         }
         return result;
    }

    /**
     * @notice Checks if a specific state transition is currently valid for a node
     *         based on internal rules/conditions (same logic as in `transitionNodeState`).
     *         Does NOT actually perform the transition.
     * @param _nodeId The ID of the node.
     * @param _newState The desired new state.
     * @return True if the transition is allowed, false otherwise.
     */
    function canTransitionState(uint256 _nodeId, NodeState _newState) public view returns (bool) {
        if (!nodes[_nodeId].exists) return false;
        Node storage node = nodes[_nodeId];
        NodeState oldState = node.state;

        if (oldState == _newState) return false; // No transition

        // --- Copy of Example State Transition Logic from transitionNodeState ---
        if (oldState == NodeState.Inactive) {
            if (_newState == NodeState.Active) {
                return node.attributes.length > 0 && node.attributes[0] >= 50;
            } else if (_newState == NodeState.Dormant) {
                 return true;
            }
        } else if (oldState == NodeState.Active) {
             if (_newState == NodeState.Dormant) {
                 return (node.attributes.length > 1 && node.attributes[1] < 30) || msg.sender == owner;
            } else if (_newState == NodeState.Degraded) {
                 return node.attributes.length > 1 && node.attributes[1] < 10 && node.attributes[0] < 20;
            }
        } else if (oldState == NodeState.Dormant) {
            if (_newState == NodeState.Active) {
                return msg.sender == owner && node.attributes.length > 2 && node.attributes[2] >= 80;
            } else if (_newState == NodeState.Degraded) {
                 return msg.sender == owner; // Manual trigger by owner
            } else if (_newState == NodeState.Inactive) {
                 return true;
            }
        } else if (oldState == NodeState.Degraded) {
            if (_newState == NodeState.Inactive) {
                return msg.sender == owner && node.attributes.length > 1 && node.attributes[1] >= 50;
            }
        }
        // --- End Copy ---

        return false; // Default: transition not allowed
    }

     // --- Advanced/Creative Functions ---
     // simulateSystemTick is above (function 24)
     // attuneNode is above (function 25)
     // initiateCascade is above (function 26)

    // Filler functions to meet 20+ count if needed, focusing on query/status
    // (We already have 26, but demonstrating how to add more simple ones)

    // function getNodeNeighbors(uint256 _nodeId) public view returns (uint256[] memory) {
    //     require(nodes[_nodeId].exists, "Node does not exist");
    //     return nodeNeighbors[_nodeId]; // Returns array of node IDs this node points *to*
    // }

    // function getNodeInverseNeighbors(uint256 _nodeId) public view returns (uint256[] memory) {
    //      require(nodes[_nodeId].exists, "Node does not exist");
    //      return nodeInverseNeighbors[_nodeId]; // Returns array of node IDs that point *to* this node
    // }

     // function getNodeType(uint256 _nodeId) public view returns (NodeType) {
     //     require(nodes[_nodeId].exists, "Node does not exist");
     //     return nodes[_nodeId].nodeType;
     // }

     // function getTimeSinceLastUpdate(uint256 _nodeId) public view returns (uint256) {
     //     require(nodes[_nodeId].exists, "Node does not exist");
     //     return block.timestamp - nodes[_nodeId].lastUpdated;
     // }

     // function getBaseAttributes(NodeType _type) public view returns (uint256[] memory) {
     //     return nodeBaseAttributes[_type];
     // }

     // function getRelationshipEffectModifiers(RelationshipType _type) public view returns (int256[] memory) {
     //      return relationshipEffects[_type];
     // }
}
```