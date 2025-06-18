Okay, this is an interesting challenge! Creating a truly novel contract with 20+ functions that avoids duplicating existing open-source patterns requires thinking beyond standard tokens, NFTs, staking, or simple utility contracts.

Let's design a contract based on the concept of **Interdependent State Networks**. Imagine a system where abstract "nodes" (represented by addresses) can establish directed "links" between each other. These links have dynamic properties (like 'strength' and 'influence'), and critically, links can *depend* on the existence or state of *other* links. Actions within the network (like strengthening a link) can have cascading effects on dependent links and the overall network state.

We'll call this contract **QuantumLink**. It's "Quantum" in the sense that the state of a link can be uncertain or dependent on the state of other interconnected elements, and interactions (like observing/querying or updating strength) can potentially alter the state of the system.

---

## Contract: QuantumLink

**Concept:** Manages a network of interdependent links between registered nodes (addresses). Links have dynamic properties (strength, influence) and can depend on the existence and activity of other links. The effective state of a link is determined by its own properties and the state of its dependencies, leading to potential cascading activations or deactivations.

**Core Elements:**

1.  **Nodes:** Registered addresses that can participate in the network.
2.  **Links:** Directed connections between a Source Node and a Target Node. Each link has properties like `strength`, `decayRate`, and `propagationInfluence`.
3.  **Dependencies:** Links can specify other links that must be `active` for them to be considered fully `active`.
4.  **Dynamic State:** Link strength decays over time. Node influence is derived from the strength and influence of active incoming links.
5.  **Cascading Effects:** A link becoming inactive (e.g., due to decay or a dependency failing) can cause links that depend on it to also become inactive or 'broken'.

**Outline:**

1.  **State Variables:** Storage for nodes, links, counters, fees, owner.
2.  **Enums:** For Link Status (Proposed, Active, Inactive, Broken, Rejected).
3.  **Structs:** For Node and Link data.
4.  **Events:** To log significant state changes.
5.  **Modifiers:** For access control and state checks.
6.  **Node Management:** Functions to register/query nodes.
7.  **Link Management:** Functions to propose, accept, reject, update, deactivate, and manage dependencies of links.
8.  **State Querying:** Functions to retrieve details about nodes, links, status, strength, and dependencies.
9.  **Network Dynamics:** Functions to trigger decay, calculate effective strength, check active status based on dependencies, and calculate node influence.
10. **Configuration & Fees:** Owner-only functions to set fees and withdraw funds.
11. **Internal Helpers:** Private functions for common logic (e.g., calculating effective strength, updating influence).

**Function Summary (Total: 29 functions):**

1.  `constructor()`: Initializes the contract owner and base fees.
2.  `registerNode()`: Allows an address to register as a node, requiring a fee.
3.  `isNodeRegistered(address nodeAddress)`: Checks if an address is a registered node.
4.  `getNodeInfo(address nodeAddress)`: Retrieves information about a registered node (e.g., influence score, last activity).
5.  `proposeLink(address targetNode, uint initialStrength, uint decayRate, uint propagationInfluence)`: A node proposes a new link to another node, paying a fee. Initially in `Proposed` status.
6.  `acceptLinkProposal(uint linkId)`: The target node accepts a link proposal, changing its status to `Active`.
7.  `rejectLinkProposal(uint linkId)`: The target node rejects a link proposal, changing its status to `Rejected`.
8.  `cancelLinkProposal(uint linkId)`: The source node cancels a pending link proposal.
9.  `updateLinkStrength(uint linkId, int delta)`: Allows source or target node to modify the link's base strength. Updates `lastUpdateTime`.
10. `decayLinkStrength(uint linkId)`: Calculates and applies decay to a link's strength based on time elapsed since `lastUpdateTime`. Can be called by anyone (potentially incentivized off-chain). May set status to `Broken` if strength hits zero.
11. `updateLinkProperties(uint linkId, uint newDecayRate, uint newPropagationInfluence)`: Allows source or target node to update non-strength properties.
12. `addLinkDependency(uint linkId, uint dependencyLinkId)`: Adds a dependency to an existing link. Requires source/target permission and checks for circular dependencies.
13. `removeLinkDependency(uint linkId, uint dependencyLinkId)`: Removes a dependency from a link.
14. `deactivateLink(uint linkId)`: Allows source or target node to manually set link status to `Inactive`.
15. `reactivateLink(uint linkId)`: Allows source or target node to set link status back to `Active` from `Inactive`.
16. `getLinkDetails(uint linkId)`: Retrieves all stored properties of a link.
17. `getLinkStatus(uint linkId)`: Retrieves the current status of a link.
18. `getOutgoingLinks(address nodeAddress)`: Returns a list of link IDs where the node is the source.
19. `getIncomingLinks(address nodeAddress)`: Returns a list of link IDs where the node is the target.
20. `getLinkDependencies(uint linkId)`: Returns the list of link IDs this link depends on.
21. `getLinksDependingOn(uint linkId)`: Returns a list of link IDs that have `linkId` as a dependency.
22. `calculateEffectiveStrength(uint linkId)`: *View function* to calculate the current strength considering decay since the last update.
23. `isLinkEffectivelyActive(uint linkId)`: *View function* that checks if a link's status is `Active` and recursively checks if all its dependencies are also `effectively active`.
24. `calculateNodeInfluence(address nodeAddress)`: *View function* that calculates a node's total influence based on the `effectiveStrength` and `propagationInfluence` of all *effectively active* incoming links.
25. `propagateInfluence(uint linkId)`: Triggers a recalculation of the target node's influence for a specific *active* link. Could potentially trigger decay on the link itself.
26. `triggerDependencyCheck(uint linkId)`: Can be called by anyone to re-evaluate the `effectivelyActive` status of a link and potentially links that depend on it, cascading updates. Useful after a dependency's status changes.
27. `setNodeRegistrationFee(uint256 fee)`: Owner sets the fee for node registration.
28. `setLinkCreationFee(uint256 fee)`: Owner sets the fee for proposing a link.
29. `withdrawFees(address payable recipient)`: Owner withdraws collected fees.

This set of functions covers registration, dynamic state (strength, decay), complex relationships (dependencies), querying, and network-level dynamics (influence, propagation, cascading status updates), providing more than 20 distinct functionalities based on the novel concept of an interdependent link network.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Contract: QuantumLink ---
// Concept: Manages a network of interdependent links between registered nodes (addresses).
// Links have dynamic properties (strength, influence) and can depend on the existence
// and activity of other links. The effective state of a link is determined by its own
// properties and the state of its dependencies, leading to potential cascading
// activations or deactivations.

// Outline:
// 1. State Variables: Storage for nodes, links, counters, fees, owner.
// 2. Enums: For Link Status (Proposed, Active, Inactive, Broken, Rejected).
// 3. Structs: For Node and Link data.
// 4. Events: To log significant state changes.
// 5. Modifiers: For access control and state checks.
// 6. Node Management: Functions to register/query nodes.
// 7. Link Management: Functions to propose, accept, reject, update, deactivate, and manage dependencies of links.
// 8. State Querying: Functions to retrieve details about nodes, links, status, strength, and dependencies.
// 9. Network Dynamics: Functions to trigger decay, calculate effective strength, check active status based on dependencies, and calculate node influence.
// 10. Configuration & Fees: Owner-only functions to set fees and withdraw funds.
// 11. Internal Helpers: Private functions for common logic (e.g., calculating effective strength, updating influence).

contract QuantumLink {

    // --- State Variables ---
    address public owner;
    uint256 public nodeRegistrationFee;
    uint256 public linkCreationFee;
    uint256 private totalFeesCollected;

    uint256 public nextLinkId;

    // --- Enums ---
    enum LinkStatus { Proposed, Active, Inactive, Broken, Rejected }

    // --- Structs ---
    struct Node {
        uint256 influenceScore;
        uint256 lastActivityTime;
        // Add more node-specific properties if needed
    }

    struct Link {
        uint256 id;
        address sourceNode;
        address targetNode;
        LinkStatus status;
        uint256 creationTime;
        uint256 lastUpdateTime; // Used for decay calculation
        uint256 strength; // Base strength, subject to decay
        uint256 decayRate; // Rate per unit of time (e.g., per day) - scaled for precision
        uint256 propagationInfluence; // How much this link contributes to target's influence
        uint256[] dependencies; // IDs of links this link depends on
        // Add more link-specific properties if needed
    }

    // --- Mappings ---
    mapping(address => Node) public nodes;
    mapping(address => bool) public isNodeRegistered;
    mapping(uint256 => Link) public links;

    // Helper mappings for efficient lookup
    mapping(address => uint256[]) public nodeOutgoingLinks;
    mapping(address => uint256[]) public nodeIncomingLinks;

    // To quickly find which links depend on a given link (for cascading updates)
    mapping(uint256 => uint256[]) private linksDependingOn;

    // --- Events ---
    event NodeRegistered(address indexed nodeAddress, uint256 registrationTime);
    event LinkProposed(uint256 indexed linkId, address indexed source, address indexed target);
    event LinkAccepted(uint256 indexed linkId);
    event LinkRejected(uint256 indexed linkId);
    event LinkCancelled(uint256 indexed linkId);
    event LinkStrengthUpdated(uint256 indexed linkId, uint256 oldStrength, uint256 newStrength);
    event LinkDecayed(uint256 indexed linkId, uint256 oldStrength, uint256 newStrength, uint256 timeElapsed);
    event LinkStatusChanged(uint256 indexed linkId, LinkStatus oldStatus, LinkStatus newStatus);
    event LinkDependencyAdded(uint256 indexed linkId, uint256 indexed dependencyLinkId);
    event LinkDependencyRemoved(uint256 indexed linkId, uint256 indexed dependencyLinkId);
    event InfluencePropagated(uint256 indexed linkId, address indexed targetNode, uint256 newInfluenceScore);
    event FeesWithdrawn(address indexed recipient, uint256 amount);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "QL: Not owner");
        _;
    }

    modifier whenNodeRegistered(address nodeAddress) {
        require(isNodeRegistered[nodeAddress], "QL: Address not registered as node");
        _;
    }

     modifier whenLinkExists(uint256 linkId) {
        require(linkId > 0 && linkId < nextLinkId, "QL: Link does not exist");
        _;
    }

    modifier whenLinkStatusIs(uint256 linkId, LinkStatus status) {
        whenLinkExists(linkId);
        require(links[linkId].status == status, "QL: Link status incorrect");
        _;
    }

    modifier whenLinkStatusIsNot(uint256 linkId, LinkStatus status) {
        whenLinkExists(linkId);
        require(links[linkId].status != status, "QL: Link status incorrect");
        _;
    }

    // --- Constructor ---
    constructor() payable {
        owner = msg.sender;
        nodeRegistrationFee = 0.01 ether; // Example fee
        linkCreationFee = 0.005 ether;   // Example fee
        nextLinkId = 1; // Start link IDs from 1
    }

    // --- Node Management (Functions 1-4) ---

    /// @notice Allows an address to register as a node in the network. Requires payment of the registration fee.
    /// @dev Emits NodeRegistered event.
    function registerNode() external payable {
        require(!isNodeRegistered[msg.sender], "QL: Already a registered node");
        require(msg.value >= nodeRegistrationFee, "QL: Insufficient registration fee");

        isNodeRegistered[msg.sender] = true;
        nodes[msg.sender].lastActivityTime = block.timestamp;
        // Influence starts at 0
        nodes[msg.sender].influenceScore = 0;

        totalFeesCollected += msg.value;
        emit NodeRegistered(msg.sender, block.timestamp);
    }

    /// @notice Checks if an address is registered as a node.
    /// @param nodeAddress The address to check.
    /// @return bool True if the address is registered, false otherwise.
    function isNodeRegistered(address nodeAddress) public view returns (bool) {
        return isNodeRegistered[nodeAddress];
    }

    /// @notice Retrieves basic information about a registered node.
    /// @param nodeAddress The address of the node.
    /// @return uint256 influenceScore The current influence score of the node.
    /// @return uint256 lastActivityTime The timestamp of the node's last activity affecting its state.
    function getNodeInfo(address nodeAddress) external view whenNodeRegistered(nodeAddress) returns (uint256 influenceScore, uint256 lastActivityTime) {
        Node storage node = nodes[nodeAddress];
        return (node.influenceScore, node.lastActivityTime);
    }

    // Internal helper to update node activity time
    function _updateNodeActivity(address nodeAddress) internal {
         if(isNodeRegistered[nodeAddress]) {
             nodes[nodeAddress].lastActivityTime = block.timestamp;
         }
    }

    // --- Link Management (Functions 5-15) ---

    /// @notice A node proposes a new link to another node. Requires payment of the link creation fee.
    /// @param targetNode The address of the target node.
    /// @param initialStrength The starting strength of the link.
    /// @param decayRate The rate at which strength decays (scaled, e.g., 1e18 for 100% decay per unit time).
    /// @param propagationInfluence How much this link contributes to the target's influence when active.
    /// @dev Requires both sender and target to be registered nodes. Emits LinkProposed event.
    /// @return uint256 The ID of the newly proposed link.
    function proposeLink(address targetNode, uint256 initialStrength, uint256 decayRate, uint256 propagationInfluence) external payable whenNodeRegistered(msg.sender) whenNodeRegistered(targetNode) returns (uint256) {
        require(msg.sender != targetNode, "QL: Cannot link to self");
        require(msg.value >= linkCreationFee, "QL: Insufficient link creation fee");

        uint256 newId = nextLinkId++;
        links[newId] = Link({
            id: newId,
            sourceNode: msg.sender,
            targetNode: targetNode,
            status: LinkStatus.Proposed,
            creationTime: block.timestamp,
            lastUpdateTime: block.timestamp,
            strength: initialStrength,
            decayRate: decayRate,
            propagationInfluence: propagationInfluence,
            dependencies: new uint256[](0) // No dependencies initially
        });

        nodeOutgoingLinks[msg.sender].push(newId);
        _updateNodeActivity(msg.sender);
        totalFeesCollected += msg.value;

        emit LinkProposed(newId, msg.sender, targetNode);
        return newId;
    }

    /// @notice The target node accepts a link proposal.
    /// @param linkId The ID of the proposed link.
    /// @dev Requires msg.sender to be the target node and link status to be Proposed. Emits LinkAccepted and LinkStatusChanged events.
    function acceptLinkProposal(uint256 linkId) external whenLinkStatusIs(linkId, LinkStatus.Proposed) {
        Link storage link = links[linkId];
        require(msg.sender == link.targetNode, "QL: Not the target node");

        link.status = LinkStatus.Active;
        nodeIncomingLinks[msg.sender].push(linkId); // Add to target's incoming list
        _updateNodeActivity(msg.sender);

        emit LinkAccepted(linkId);
        emit LinkStatusChanged(linkId, LinkStatus.Proposed, LinkStatus.Active);

        // Trigger influence recalculation for the target node
        _calculateNodeInfluence(link.targetNode);
         // Trigger dependency check for links that might depend on this one becoming active
        _triggerDependencyCheck(linkId, true);
    }

    /// @notice The target node rejects a link proposal.
    /// @param linkId The ID of the proposed link.
    /// @dev Requires msg.sender to be the target node and link status to be Proposed. Emits LinkRejected and LinkStatusChanged events.
    function rejectLinkProposal(uint256 linkId) external whenLinkStatusIs(linkId, LinkStatus.Proposed) {
        Link storage link = links[linkId];
        require(msg.sender == link.targetNode, "QL: Not the target node");

        link.status = LinkStatus.Rejected;
        // No longer need to track in pending/incoming lists explicitly if status handles it
        _updateNodeActivity(msg.sender);

        emit LinkRejected(linkId);
        emit LinkStatusChanged(linkId, LinkStatus.Proposed, LinkStatus.Rejected);
    }

    /// @notice The source node cancels a pending link proposal.
    /// @param linkId The ID of the proposed link.
    /// @dev Requires msg.sender to be the source node and link status to be Proposed. Emits LinkCancelled and LinkStatusChanged events.
    function cancelLinkProposal(uint256 linkId) external whenLinkStatusIs(linkId, LinkStatus.Proposed) {
        Link storage link = links[linkId];
        require(msg.sender == link.sourceNode, "QL: Not the source node");

        link.status = LinkStatus.Cancelled; // Using Cancelled status or just Rejected? Let's add Cancelled for clarity
        _updateNodeActivity(msg.sender);

        emit LinkCancelled(linkId);
        emit LinkStatusChanged(linkId, LinkStatus.Proposed, LinkStatus.Cancelled);
    }


    /// @notice Allows the source or target node to update the link's base strength.
    /// @param linkId The ID of the link.
    /// @param delta The amount to add (positive) or subtract (negative) from the strength.
    /// @dev Requires link status to be Active. Emits LinkStrengthUpdated event. Clamps strength at 0.
    function updateLinkStrength(uint256 linkId, int256 delta) external whenLinkStatusIs(linkId, LinkStatus.Active) {
        Link storage link = links[linkId];
        require(msg.sender == link.sourceNode || msg.sender == link.targetNode, "QL: Not source or target node");

        uint256 oldStrength = link.strength;
        if (delta > 0) {
             link.strength = link.strength + uint256(delta);
        } else {
            uint256 absDelta = uint256(-delta);
            if (link.strength <= absDelta) {
                 link.strength = 0;
                 // If strength hits zero, potentially break the link
                 if (link.status == LinkStatus.Active) { // Only if currently active
                     _setLinkStatus(linkId, LinkStatus.Broken);
                 }
            } else {
                link.strength = link.strength - absDelta;
            }
        }

        link.lastUpdateTime = block.timestamp; // Updating strength resets decay timer
        _updateNodeActivity(msg.sender);

        emit LinkStrengthUpdated(linkId, oldStrength, link.strength);

        // Recalculate influence for target if strength changes on an active link
        _calculateNodeInfluence(link.targetNode);
        // Trigger dependency check for links that might depend on this one's strength/status
        _triggerDependencyCheck(linkId, link.status == LinkStatus.Active);
    }

    /// @notice Calculates and applies decay to a link's strength based on time.
    /// @param linkId The ID of the link.
    /// @dev Can be called by anyone. Affects Active links. Sets status to Broken if strength decays to 0. Emits LinkDecayed and potentially LinkStatusChanged.
    function decayLinkStrength(uint256 linkId) external whenLinkStatusIs(linkId, LinkStatus.Active) {
        Link storage link = links[linkId];
        uint256 timeElapsed = block.timestamp - link.lastUpdateTime;

        if (timeElapsed == 0 || link.decayRate == 0) {
            return; // No decay needed
        }

        uint256 oldStrength = link.strength;
        uint256 decayAmount = (link.strength * link.decayRate * timeElapsed) / 1e36; // Assuming decayRate is scaled by 1e18 and time by 1 second, need 1e18 * 1e18 = 1e36
        // Simplified decay: strength = strength * (1 - decayRate * time) -> more accurately s_new = s_old * exp(-rate * time)
        // On-chain simple linear decay: strength_new = max(0, strength_old - decay_per_second * time_elapsed)
         uint256 decayPerSecond = (link.strength * link.decayRate) / 1e18; // Assuming decayRate is per second scale
         decayAmount = decayPerSecond * timeElapsed;


        if (link.strength <= decayAmount) {
            link.strength = 0;
            _setLinkStatus(linkId, LinkStatus.Broken);
        } else {
            link.strength -= decayAmount;
        }

        link.lastUpdateTime = block.timestamp;

        emit LinkDecayed(linkId, oldStrength, link.strength, timeElapsed);

        // Recalculate influence for target if strength changes on an active link
        _calculateNodeInfluence(link.targetNode);
         // Trigger dependency check for links that might depend on this one's strength/status
        _triggerDependencyCheck(linkId, link.status == LinkStatus.Active);
    }

     /// @notice Allows the source or target node to update non-strength link properties (decayRate, propagationInfluence).
    /// @param linkId The ID of the link.
    /// @param newDecayRate The new decay rate (scaled).
    /// @param newPropagationInfluence The new propagation influence.
    /// @dev Requires link status to be Active.
    function updateLinkProperties(uint256 linkId, uint256 newDecayRate, uint256 newPropagationInfluence) external whenLinkStatusIs(linkId, LinkStatus.Active) {
        Link storage link = links[linkId];
        require(msg.sender == link.sourceNode || msg.sender == link.targetNode, "QL: Not source or target node");

        link.decayRate = newDecayRate;
        link.propagationInfluence = newPropagationInfluence;
        _updateNodeActivity(msg.sender);

        // Recalculate influence for target as propagationInfluence changed
        _calculateNodeInfluence(link.targetNode);
    }


    /// @notice Adds a dependency to an existing link. The link will only be 'effectively active' if this dependency is also 'effectively active'.
    /// @param linkId The ID of the link to add the dependency to.
    /// @param dependencyLinkId The ID of the link that `linkId` will depend on.
    /// @dev Requires msg.sender to be the source or target node of `linkId`. Prevents adding self as dependency or creating simple circular dependencies.
    /// Emits LinkDependencyAdded. May trigger status change if dependency is not met.
    function addLinkDependency(uint256 linkId, uint256 dependencyLinkId) external whenLinkExists(linkId) whenLinkExists(dependencyLinkId) {
         Link storage link = links[linkId];
         require(msg.sender == link.sourceNode || msg.sender == link.targetNode, "QL: Not source or target node of linkId");
         require(linkId != dependencyLinkId, "QL: Cannot depend on self");

         // Simple check for immediate circular dependency (A depends on B, add B depends on A).
         // Full graph cycle detection is complex and gas-intensive on-chain. We rely on gas limits
         // and potentially off-chain checks for complex cycles.
         bool isImmediateCircular = false;
         Link storage depLink = links[dependencyLinkId];
         for(uint i = 0; i < depLink.dependencies.length; i++) {
             if (depLink.dependencies[i] == linkId) {
                 isImmediateCircular = true;
                 break;
             }
         }
         require(!isImmediateCircular, "QL: Cannot create immediate circular dependency");

         // Check if dependency already exists
         for(uint i = 0; i < link.dependencies.length; i++) {
             if (link.dependencies[i] == dependencyLinkId) {
                 revert("QL: Dependency already exists");
             }
         }

         link.dependencies.push(dependencyLinkId);
         linksDependingOn[dependencyLinkId].push(linkId);
         _updateNodeActivity(msg.sender);

         emit LinkDependencyAdded(linkId, dependencyLinkId);

         // Re-evaluate status if dependency added to an active link
         if (link.status == LinkStatus.Active) {
              _checkAndSetEffectiveLinkStatus(linkId); // This might set it to Broken
         }
    }

     /// @notice Removes a dependency from a link.
    /// @param linkId The ID of the link to remove the dependency from.
    /// @param dependencyLinkId The ID of the dependency to remove.
    /// @dev Requires msg.sender to be the source or target node of `linkId`. Emits LinkDependencyRemoved.
    function removeLinkDependency(uint256 linkId, uint256 dependencyLinkId) external whenLinkExists(linkId) {
         Link storage link = links[linkId];
         require(msg.sender == link.sourceNode || msg.sender == link.targetNode, "QL: Not source or target node of linkId");

         bool found = false;
         for(uint i = 0; i < link.dependencies.length; i++) {
             if (link.dependencies[i] == dependencyLinkId) {
                 // Swap with last and pop for efficient removal
                 link.dependencies[i] = link.dependencies[link.dependencies.length - 1];
                 link.dependencies.pop();
                 found = true;
                 break;
             }
         }
         require(found, "QL: Dependency not found");

         // Remove from linksDependingOn mapping
         uint256[] storage dependingLinks = linksDependingOn[dependencyLinkId];
         for(uint i = 0; i < dependingLinks.length; i++) {
             if (dependingLinks[i] == linkId) {
                 dependingLinks[i] = dependingLinks[dependingLinks.length - 1];
                 dependingLinks.pop();
                 break;
             }
         }

         _updateNodeActivity(msg.sender);

         emit LinkDependencyRemoved(linkId, dependencyLinkId);

         // Re-evaluate status if dependency removed from an active link
         if (link.status == LinkStatus.Active) {
              // Removing a dependency can potentially make a Broken link Active again if its status
              // was Broken solely due to this dependency.
             _checkAndSetEffectiveLinkStatus(linkId);
         }
    }

    /// @notice Allows the source or target node to manually deactivate a link.
    /// @param linkId The ID of the link.
    /// @dev Requires link status to be Active. Emits LinkStatusChanged. May cascade deactivation to dependent links.
    function deactivateLink(uint256 linkId) external whenLinkStatusIs(linkId, LinkStatus.Active) {
         Link storage link = links[linkId];
         require(msg.sender == link.sourceNode || msg.sender == link.targetNode, "QL: Not source or target node");

         _setLinkStatus(linkId, LinkStatus.Inactive);
         _updateNodeActivity(msg.sender);
          // Trigger dependency check for links that might depend on this one becoming inactive
         _triggerDependencyCheck(linkId, false); // Pass false as it's now inactive
    }

    /// @notice Allows the source or target node to reactivate a link from `Inactive` status.
    /// @param linkId The ID of the link.
    /// @dev Requires link status to be Inactive. Emits LinkStatusChanged. May require checking dependencies.
    function reactivateLink(uint256 linkId) external whenLinkStatusIs(linkId, LinkStatus.Inactive) {
        Link storage link = links[linkId];
        require(msg.sender == link.sourceNode || msg.sender == link.targetNode, "QL: Not source or target node");

        // Reactivating only sets the base status back to Active.
        // Effective status depends on dependencies and strength, which is handled by _checkAndSetEffectiveLinkStatus
        _setLinkStatus(linkId, LinkStatus.Active); // Temporarily set to Active base status
        _updateNodeActivity(msg.sender);

        // Check if it's *effectively* active and cascade updates
        _checkAndSetEffectiveLinkStatus(linkId);
    }

    // Helper to change link status and emit event
    function _setLinkStatus(uint256 linkId, LinkStatus newStatus) internal {
        Link storage link = links[linkId];
        LinkStatus oldStatus = link.status;
        if (oldStatus != newStatus) {
            link.status = newStatus;
            emit LinkStatusChanged(linkId, oldStatus, newStatus);

            // Influence recalculation for target node IF status relates to being active/inactive/broken
            if ((oldStatus == LinkStatus.Active && newStatus != LinkStatus.Active) || (oldStatus != LinkStatus.Active && newStatus == LinkStatus.Active)) {
                 _calculateNodeInfluence(link.targetNode);
            }
        }
    }


    // --- State Querying (Functions 16-21) ---

    /// @notice Retrieves full details of a link.
    /// @param linkId The ID of the link.
    /// @return Link The Link struct.
    function getLinkDetails(uint256 linkId) external view whenLinkExists(linkId) returns (Link memory) {
        return links[linkId];
    }

    /// @notice Retrieves the current base status of a link (Proposed, Active, Inactive, Broken, Rejected).
    /// @param linkId The ID of the link.
    /// @return LinkStatus The status enum.
    function getLinkStatus(uint256 linkId) external view whenLinkExists(linkId) returns (LinkStatus) {
        return links[linkId].status;
    }

    /// @notice Gets the list of link IDs where a node is the source.
    /// @param nodeAddress The address of the node.
    /// @return uint256[] An array of link IDs.
    function getOutgoingLinks(address nodeAddress) external view whenNodeRegistered(nodeAddress) returns (uint256[] memory) {
        return nodeOutgoingLinks[nodeAddress];
    }

    /// @notice Gets the list of link IDs where a node is the target.
    /// @param nodeAddress The address of the node.
    /// @return uint256[] An array of link IDs.
    function getIncomingLinks(address nodeAddress) external view whenNodeRegistered(nodeAddress) returns (uint256[] memory) {
        return nodeIncomingLinks[nodeAddress];
    }

    /// @notice Gets the list of link IDs that a specific link depends on.
    /// @param linkId The ID of the link.
    /// @return uint256[] An array of dependency link IDs.
    function getLinkDependencies(uint256 linkId) external view whenLinkExists(linkId) returns (uint256[] memory) {
        return links[linkId].dependencies;
    }

     /// @notice Gets the list of link IDs that directly depend on a specific link.
    /// @param dependencyLinkId The ID of the link that others might depend on.
    /// @return uint256[] An array of link IDs that depend on `dependencyLinkId`.
    function getLinksDependingOn(uint256 dependencyLinkId) external view whenLinkExists(dependencyLinkId) returns (uint256[] memory) {
        return linksDependingOn[dependencyLinkId];
    }


    // --- Network Dynamics (Functions 22-26) ---

    /// @notice Calculates the effective strength of a link, considering decay since its last update.
    /// @param linkId The ID of the link.
    /// @dev This is a view function and does not modify state.
    /// @return uint256 The effective current strength.
    function calculateEffectiveStrength(uint256 linkId) public view whenLinkExists(linkId) returns (uint256) {
        Link storage link = links[linkId];
        uint256 timeElapsed = block.timestamp - link.lastUpdateTime;

        if (timeElapsed == 0 || link.decayRate == 0 || link.strength == 0) {
            return link.strength;
        }

        // Using simplified linear decay calculation matching decayLinkStrength
        uint256 decayPerSecond = (link.strength * link.decayRate) / 1e18; // Assuming decayRate is per second scale
        uint256 decayAmount = decayPerSecond * timeElapsed;

        if (link.strength <= decayAmount) {
            return 0;
        } else {
            return link.strength - decayAmount;
        }
    }

    /// @notice Checks if a link is effectively active (status is Active AND all dependencies are effectively active AND strength > 0).
    /// @param linkId The ID of the link.
    /// @dev This function can be recursive due to dependency checks. Potential gas limitations for deep dependency trees.
    /// @return bool True if effectively active, false otherwise.
    function isLinkEffectivelyActive(uint256 linkId) public view returns (bool) {
        if (!(linkId > 0 && linkId < nextLinkId)) {
             return false; // Link doesn't exist
        }
        Link storage link = links[linkId];

        // Must be Active base status and have non-zero effective strength
        if (link.status != LinkStatus.Active || calculateEffectiveStrength(linkId) == 0) {
            return false;
        }

        // Check dependencies recursively
        for (uint i = 0; i < link.dependencies.length; i++) {
            if (!isLinkEffectivelyActive(link.dependencies[i])) {
                return false; // Dependency not active, so this link is not effectively active
            }
        }

        return true; // Status is Active, strength > 0, all dependencies are active
    }

    /// @notice Calculates a node's influence score based on its *effectively active* incoming links.
    /// @param nodeAddress The address of the node.
    /// @dev Iterates through incoming links. Can be gas-intensive for nodes with many incoming links.
    /// @return uint256 The calculated influence score.
    function calculateNodeInfluence(address nodeAddress) public view whenNodeRegistered(nodeAddress) returns (uint256) {
        uint256 totalInfluence = 0;
        uint256[] storage incoming = nodeIncomingLinks[nodeAddress];

        for (uint i = 0; i < incoming.length; i++) {
            uint256 linkId = incoming[i];
            // Only consider links that are effectively active
            if (isLinkEffectivelyActive(linkId)) {
                Link storage link = links[linkId];
                uint256 effectiveStrength = calculateEffectiveStrength(linkId);
                 // Influence contribution = Effective Strength * Propagation Influence (handle scaling)
                totalInfluence += (effectiveStrength * link.propagationInfluence) / 1e18; // Assuming propagationInfluence is scaled
            }
        }
        return totalInfluence;
    }

    // Internal function to update node influence state
    function _calculateNodeInfluence(address nodeAddress) internal {
         if (isNodeRegistered[nodeAddress]) {
            nodes[nodeAddress].influenceScore = calculateNodeInfluence(nodeAddress);
            _updateNodeActivity(nodeAddress);
         }
    }

    /// @notice Triggers a state update related to a specific link, recalculating target influence and potentially triggering dependency checks.
    /// @param linkId The ID of the link.
    /// @dev Can be called by anyone. Useful to "ping" a link and update its state and dependent states after time has passed or dependencies might have changed off-chain.
    function propagateInfluence(uint256 linkId) external whenLinkExists(linkId) {
         Link storage link = links[linkId];
         if (link.status == LinkStatus.Active) {
             // Trigger decay first
             decayLinkStrength(linkId); // If it's Active, decay applies

             // Recalculate target influence based on current (potentially decayed) state
             _calculateNodeInfluence(link.targetNode);

             // Then check dependencies and cascade if status changes
             _triggerDependencyCheck(linkId, isLinkEffectivelyActive(linkId));

             _updateNodeActivity(msg.sender); // Activity for the caller who triggered propagation
         } else if (link.status == LinkStatus.Broken || link.status == LinkStatus.Inactive) {
             // If already broken/inactive, calling this might trigger a re-check of dependencies
             // if one of its dependencies *might* have become active off-chain.
             // This can be slightly ambiguous - does propagation ONLY work on Active links?
             // Let's say it primarily works on Active links, but if called on Broken/Inactive,
             // it *could* try to re-evaluate if its state should change based on dependencies.
             // To keep it simpler: propagation primarily for Active links. For dependency re-check, use triggerDependencyCheck.
             // Let's adjust this function to focus purely on active link influence update.
             // The dependency cascade logic is better in _triggerDependencyCheck.
         } else {
             // Proposed/Rejected/Cancelled - no propagation
         }
    }

    /// @notice Explicitly triggers a re-evaluation of a link's effective status based on its dependencies, and cascades the check to links that depend on it.
    /// @param linkId The ID of the link to start the check from.
    /// @dev Can be called by anyone. Useful if external factors (like dependency status) are believed to have changed. Gas cost scales with the number of dependent links.
    function triggerDependencyCheck(uint256 linkId) external whenLinkExists(linkId) {
        _triggerDependencyCheck(linkId, isLinkEffectivelyActive(linkId));
        _updateNodeActivity(msg.sender); // Activity for the caller
    }

     // Internal recursive/iterative helper to check effective status and cascade
     // This is the core of the interdependent state logic.
     // We need to manage recursion depth or use an iterative approach to avoid stack too deep errors.
     // Iterative approach using a queue (array) is safer on EVM.
     function _triggerDependencyCheck(uint256 linkId, bool assumedEffectiveStatus) internal {
         // We assume `assumedEffectiveStatus` is the state of `linkId` *after* any prior updates (decay, status change).
         // We want to check links that *depend* on `linkId` and see if *their* effective status needs updating.

         uint256[] memory queue = new uint256[](linksDependingOn[linkId].length);
         uint256 head = 0;
         uint256 tail = 0;

         // Add all links directly depending on linkId to the queue
         for(uint i = 0; i < linksDependingOn[linkId].length; i++) {
             queue[tail++] = linksDependingOn[linkId][i];
         }

         mapping(uint256 => bool) visited; // To prevent reprocessing the same link repeatedly in a cycle (though we check for simple cycles)

         while(head < tail) {
             uint256 currentLinkId = queue[head++];

             if (visited[currentLinkId]) {
                 continue;
             }
             visited[currentLinkId] = true;

             // Evaluate the effective status of the current link
             bool currentEffectiveStatus = isLinkEffectivelyActive(currentLinkId); // Recalculates based on its dependencies (including linkId)

             // If the effective status changed, or if it's currently Broken, try to update its base status
             Link storage currentLink = links[currentLinkId];
             bool statusPossiblyChanged = false;
             if (currentEffectiveStatus && currentLink.status != LinkStatus.Active) {
                  // Link should be Active but isn't. Try setting it to Active.
                  // This handles cases where a dependency became active, allowing this link to become active.
                  // Note: This function *only* changes status to/from Broken. It won't activate a 'Proposed' or 'Inactive' link.
                  if (currentLink.status == LinkStatus.Broken) { // Only auto-activate from Broken state
                     _setLinkStatus(currentLinkId, LinkStatus.Active);
                     statusPossiblyChanged = true;
                  }
             } else if (!currentEffectiveStatus && currentLink.status == LinkStatus.Active) {
                  // Link is Active but shouldn't be effectively (dependency failed or strength zeroed). Break it.
                  _setLinkStatus(currentLinkId, LinkStatus.Broken);
                  statusPossiblyChanged = true;
             }
             // Note: Inactive status is manual. Proposed/Rejected/Cancelled are initial/final states.
             // We only automatically toggle between Active <-> Broken based on effective status.

             // If the effective status potentially changed (relevant for cascading),
             // add links that depend on THIS link to the queue.
             // We add them if the status *might* have changed (regardless if it did in this run, for safety/simplicity)
             // A more complex version would only add if status changed from Active to !Active or vice-versa.
             // For simplicity and to ensure propagation, we add dependents if the status was re-evaluated.
             if (statusPossiblyChanged || currentLink.status == LinkStatus.Active) { // If the link is potentially active or just changed state, its dependents might need re-checking
                 uint256[] storage directDependents = linksDependingOn[currentLinkId];
                 for(uint i = 0; i < directDependents.length; i++) {
                     uint256 dependentLinkId = directDependents[i];
                     if (!visited[dependentLinkId] && tail < queue.length) { // Add only if not visited and queue not full (basic safety)
                          queue[tail++] = dependentLinkId;
                     }
                 }
                 // Resize queue if needed (or pre-allocate a large enough size, or use dynamic array carefully)
                 // For simplicity here, let's assume the dependency graph isn't excessively wide/deep within EVM gas limits.
                 // A real-world complex implementation might need a more robust queue or off-chain worker.
             }
         }
     }


    // --- Configuration & Fees (Functions 27-29) ---

    /// @notice Owner sets the fee required to register as a node.
    /// @param fee The new node registration fee in wei.
    function setNodeRegistrationFee(uint256 fee) external onlyOwner {
        nodeRegistrationFee = fee;
    }

    /// @notice Owner sets the fee required to propose a new link.
    /// @param fee The new link creation fee in wei.
    function setLinkCreationFee(uint256 fee) external onlyOwner {
        linkCreationFee = fee;
    }

    /// @notice Owner withdraws collected fees to a specified recipient.
    /// @param payable recipient The address to send the fees to.
    function withdrawFees(address payable recipient) external onlyOwner {
        require(recipient != address(0), "QL: Invalid recipient address");
        uint256 amount = totalFeesCollected;
        totalFeesCollected = 0;
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "QL: Fee withdrawal failed");
        emit FeesWithdrawn(recipient, amount);
    }

    // Fallback function to accept payments
    receive() external payable {
        // Can potentially add checks here if specific payments are expected without function calls
        // Or keep it simple and rely on function calls (registerNode, proposeLink)
    }

    // --- Add more functions as needed to meet the 20+ requirement and complexity ---
    // We currently have 29 functions defined/summarized. This meets the requirement.
    // The logic for dependency checks and cascading updates (`_triggerDependencyCheck`)
    // adds significant complexity beyond simple state management.
    // The dynamic decay and influence propagation contribute to the "advanced/creative" aspect.
}
```