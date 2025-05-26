Okay, this is an exciting challenge! Let's design a contract around a creative, slightly abstract concept that allows for a variety of interactions.

**Concept:** "Quantum Entanglement Simulation" - A contract that allows "Nodes" (owned entities within the contract) to become "entangled". When entangled, certain operations performed on one node can instantaneously affect its entangled partner, simulating a kind of linked destiny or shared state. This allows for synchronized state changes, value transfers, and other paired interactions not possible with standard independent entities. We'll add elements of external influence (oracle) and simulated "decoherence" (probabilistic breaking).

**Outline & Function Summary**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
Outline:
1.  **Core State & Structs:** Define the fundamental Node entity and mappings for entanglement and state.
2.  **Admin & Configuration:** Functions for the contract owner to set parameters (fees, policies).
3.  **Node Management:** Functions to create, retrieve, and manage ownership of individual Nodes.
4.  **Entanglement Lifecycle:** Functions for requesting, accepting, breaking, and querying entanglement between Nodes.
5.  **Node Value Management:** Functions to deposit and withdraw value associated with Nodes.
6.  **Entangled Operations:** The core unique functions that perform synchronized actions on entangled Node pairs (value, state, events).
7.  **External Influence & Simulation:** Functions showing how external factors (oracle) or probabilistic checks can affect entanglement ("Decoherence").
8.  **Queries & Status:** Helper functions to get detailed information about Nodes and their entanglement status.
9.  **Events:** To signal key state changes and actions.
10. **Receive/Fallback:** To accept Ether deposits.
*/

/*
Function Summary:

-   **Admin & Configuration:**
    -   `setEntanglementFee(uint256 _fee)`: Owner sets the fee required to establish entanglement.
    -   `setEntanglementPolicy(uint256 minDuration, uint256 maxNodesPerOwner)`: Owner sets rules for entanglement.
    -   `withdrawFees()`: Owner withdraws accumulated fees.
    -   `transferOwnership(address newOwner)`: Standard Ownable function.

-   **Node Management:**
    -   `createNode()`: Creates a new Node owned by the caller.
    -   `getNodeInfo(uint256 nodeId)`: Retrieves details of a specific Node.
    -   `deleteNode(uint256 nodeId)`: Deletes a Node (only if not entangled).
    -   `transferNodeOwnership(uint256 nodeId, address newOwner)`: Transfers ownership of a Node.

-   **Entanglement Lifecycle:**
    -   `requestEntanglement(uint256 nodeIdA, uint256 nodeIdB)`: NodeOwnerA requests entanglement with NodeOwnerB's NodeB.
    -   `acceptEntanglement(uint256 nodeIdA, uint256 nodeIdB)`: NodeOwnerB accepts NodeOwnerA's request, pays fee.
    -   `breakEntanglement(uint256 nodeId)`: Either owner of an entangled pair can break the entanglement.
    -   `simulateDecoherenceCheck(uint256 nodeId)`: Allows anyone to trigger a check that might probabilistically break entanglement.

-   **Node Value Management:**
    -   `depositValueToNode(uint256 nodeId)`: Deposit Ether into the contract associated with a Node.
    -   `withdrawValueFromNode(uint256 nodeId, uint256 amount)`: Withdraw Ether associated with a Node.

-   **Entangled Operations:**
    -   `transferValueEntangledSplit(uint256 nodeIdA)`: Deposit value to NodeA, it's split 50/50 with its entangled partner NodeB.
    -   `transferValueBetweenEntangled(uint256 nodeIdA, uint256 amount)`: Transfer value from NodeA's balance to its entangled partner NodeB's balance.
    -   `applySynchronizedStateChange(uint256 nodeIdA, bool newState)`: Set a specific boolean state variable (`isActive`) to the same value on both NodeA and its entangled partner NodeB.
    -   `swapStateEntangled(uint256 nodeIdA)`: Swap the `isActive` state flag between NodeA and its entangled partner NodeB.
    -   `incrementPairedCounter(uint256 nodeIdA, uint256 amount)`: Increment a shared counter or state variable on both entangled nodes by a specified amount.
    -   `splitStateOnBreak(uint256 nodeId)`: A function *intended* to be called upon breaking entanglement, distributing a cumulative state variable (like the paired counter) between the two nodes based on a rule. (Implemented as a callable function for demonstration).
    -   `triggerPairedEvent(uint256 nodeIdA, string calldata message)`: Emits a custom event for both nodes in the entangled pair.
    -   `influenceEntanglementByOracle(uint256 nodeIdA, int256 oracleValue)`: (Simulated Oracle) Uses an external value to affect the entangled pair's state or a check.

-   **Queries & Status:**
    -   `getEntanglementStatus(uint256 nodeId)`: Returns the entanglement status of a Node (None, PendingRequest, Entangled).
    -   `getPartnerNode(uint256 nodeId)`: Returns the ID of the entangled partner Node, if any.
    -   `queryEntangledNetValue(uint256 nodeId)`: Returns the sum of values held by an entangled pair.
    -   `getNodeOperationCount(uint256 nodeId)`: Returns the number of entangled operations a Node has participated in.
    -   `getPendingRequest(uint256 nodeId)`: Returns the Node ID of a pending entanglement request targetting this node.

*/
```

```solidity
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Good practice, though 0.8+ checks by default

contract QuantumEntanglement is Ownable {
    using SafeMath for uint256;

    struct Node {
        address owner;
        uint256 id; // Redundant but useful for mapping keys sometimes
        uint256 creationTimestamp;
        uint256 pairedOperationCount; // Counter for entangled ops
        bool isActive; // Example state flag
        // Add more state variables here as needed
    }

    enum EntanglementStatus { None, PendingRequest, Entangled }

    // Node storage
    uint256 private _nextNodeId = 1;
    mapping(uint256 => Node) public nodes;
    mapping(uint256 => bool) public nodeExists; // Easier check than mapping(id => Node).owner != address(0)

    // Entanglement state
    mapping(uint256 => uint256) public entangledPartner; // nodeId => partnerNodeId
    mapping(uint256 => uint256) public pendingEntanglementRequests; // nodeIdA => nodeIdB (A requested B)
    mapping(uint256 => uint256) public entanglementTimestamp; // nodeId => timestamp of entanglement

    // Node Balances (Ether held by contract for nodes)
    mapping(uint256 => uint256) private nodeBalances;

    // Configuration & Fees
    uint256 public entanglementFee = 0.01 ether; // Fee to accept entanglement
    uint256 public feesCollected;

    // Policy
    uint256 public entanglementMinDuration = 1 days; // Minimum time before easily breaking
    uint256 public maxNodesPerOwner = 10; // Limit nodes per address

    // Events
    event NodeCreated(uint256 nodeId, address owner, uint256 timestamp);
    event NodeDeleted(uint256 nodeId);
    event NodeOwnershipTransferred(uint256 nodeId, address oldOwner, address newOwner);

    event EntanglementRequested(uint256 nodeIdA, uint256 nodeIdB, uint256 timestamp);
    event EntanglementAccepted(uint256 nodeIdA, uint256 nodeIdB, uint256 timestamp);
    event EntanglementBroken(uint256 nodeIdA, uint256 nodeIdB, uint256 timestamp, string reason);
    event DecoherenceSimulated(uint256 nodeIdA, uint256 nodeIdB, bool broken, uint256 timestamp);

    event ValueDeposited(uint256 nodeId, uint256 amount);
    event ValueWithdrawn(uint256 nodeId, uint256 amount);
    event ValueSplitEntangled(uint256 nodeIdA, uint256 nodeIdB, uint256 amount);
    event ValueTransferredEntangled(uint256 nodeIdA, uint256 nodeIdB, uint256 amount);

    event SynchronizedStateChange(uint256 nodeIdA, uint256 nodeIdB, bool newState);
    event StateSwappedEntangled(uint256 nodeIdA, uint256 nodeIdB);
    event PairedCounterIncremented(uint256 nodeIdA, uint256 nodeIdB, uint256 increment);
    event StateSplitUponBreak(uint256 nodeIdA, uint256 nodeIdB, uint256 finalValueA, uint256 finalValueB);
    event PairedEventTriggered(uint256 nodeIdA, uint256 nodeIdB, string message);
    event OracleInfluenceApplied(uint256 nodeIdA, uint256 nodeIdB, int256 oracleValue);

    // Modifiers
    modifier onlyNodeOwner(uint256 nodeId) {
        require(nodeExists[nodeId], "Node does not exist");
        require(nodes[nodeId].owner == msg.sender, "Not node owner");
        _;
    }

    modifier notEntangled(uint256 nodeId) {
        require(nodeExists[nodeId], "Node does not exist");
        require(entangledPartner[nodeId] == 0, "Node is already entangled");
        _;
    }

    modifier isEntangled(uint256 nodeId) {
        require(nodeExists[nodeId], "Node does not exist");
        require(entangledPartner[nodeId] != 0, "Node is not entangled");
        _;
    }

    modifier areEntangled(uint256 nodeIdA, uint256 nodeIdB) {
        require(isEntangled(nodeIdA), "NodeA not entangled");
        require(entangledPartner[nodeIdA] == nodeIdB, "Nodes are not entangled with each other");
        require(isEntangled(nodeIdB), "NodeB not entangled"); // Double check
        require(entangledPartner[nodeIdB] == nodeIdA, "Nodes are not entangled with each other"); // Double check
        _;
    }

    constructor() {
        // Oracle address could be set here or via a function
        // Chainlink VRF coordinator could be set here if using real randomness
    }

    // --- Admin & Configuration ---

    function setEntanglementFee(uint256 _fee) external onlyOwner {
        entanglementFee = _fee;
    }

    function setEntanglementPolicy(uint256 minDuration, uint256 maxNodes) external onlyOwner {
        entanglementMinDuration = minDuration;
        maxNodesPerOwner = maxNodes;
    }

    function withdrawFees() external onlyOwner {
        uint256 amount = feesCollected;
        feesCollected = 0;
        // Use a low-level call for robustness against reentrancy
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Fee withdrawal failed");
    }

    // Inherits transferOwnership from Ownable

    // --- Node Management ---

    function createNode() external notEntangled(0) { // Use 0 check to avoid potential conflicts, though unlikely
        uint256 ownerNodeCount = 0;
        // Simple count - inefficient for many nodes, better with a mapping nodesPerOwner
        uint256 currentId = 1;
        while(currentId < _nextNodeId) {
            if (nodeExists[currentId] && nodes[currentId].owner == msg.sender) {
                ownerNodeCount++;
            }
            currentId++;
        }
        require(ownerNodeCount < maxNodesPerOwner, "Owner reached max node limit");

        uint256 newNodeId = _nextNodeId++;
        nodes[newNodeId] = Node(
            msg.sender,
            newNodeId,
            block.timestamp,
            0, // pairedOperationCount
            false // isActive
            // Initialize other state variables
        );
        nodeExists[newNodeId] = true;

        emit NodeCreated(newNodeId, msg.sender, block.timestamp);
    }

    function getNodeInfo(uint256 nodeId) external view returns (address owner, uint256 creationTimestamp, uint256 operationCount, bool isActive, uint256 balance, EntanglementStatus status, uint256 partnerId) {
        require(nodeExists[nodeId], "Node does not exist");
        EntanglementStatus nodeStatus = getEntanglementStatus(nodeId);
        uint256 partner = entangledPartner[nodeId]; // 0 if not entangled or pending
        if (nodeStatus == EntanglementStatus.PendingRequest) {
             partner = pendingEntanglementRequests[partner]; // Get the target of the pending request
        } else if (nodeStatus == EntanglementStatus.Entangled) {
             partner = entangledPartner[nodeId];
        } else {
             partner = 0;
        }


        return (
            nodes[nodeId].owner,
            nodes[nodeId].creationTimestamp,
            nodes[nodeId].pairedOperationCount,
            nodes[nodeId].isActive,
            nodeBalances[nodeId],
            nodeStatus,
            partner
        );
    }

    function deleteNode(uint256 nodeId) external onlyNodeOwner(nodeId) notEntangled(nodeId) {
        // Cannot delete if entangled
        require(pendingEntanglementRequests[nodeId] == 0 && pendingEntanglementRequests[entangledPartner[nodeId]] != nodeId, "Node has pending entanglement requests");

        delete nodes[nodeId];
        delete nodeExists[nodeId];
        // Do not delete nodeBalances[nodeId] directly if there might be value.
        // A better approach: require balance is 0 before deletion or send balance with deletion.
        require(nodeBalances[nodeId] == 0, "Node balance must be zero to delete");

        emit NodeDeleted(nodeId);
    }

    function transferNodeOwnership(uint256 nodeId, address newOwner) external onlyNodeOwner(nodeId) {
        require(newOwner != address(0), "New owner cannot be zero address");
        nodes[nodeId].owner = newOwner;
        emit NodeOwnershipTransferred(nodeId, msg.sender, newOwner);
    }

    // --- Entanglement Lifecycle ---

    function requestEntanglement(uint256 nodeIdA, uint256 nodeIdB) external onlyNodeOwner(nodeIdA) notEntangled(nodeIdA) notEntangled(nodeIdB) {
        require(nodeIdA != nodeIdB, "Cannot request entanglement with self");
        require(nodeExists[nodeIdB], "Target node does not exist");
        require(nodes[nodeIdB].owner != msg.sender, "Cannot request entanglement with your own node"); // Or allow self-entanglement? Let's disallow for now.
        require(pendingEntanglementRequests[nodeIdA] == 0, "NodeA already has a pending request");
        // Check if nodeIdB already has a pending request *targeting nodeIdA* to prevent race conditions/spam
        require(pendingEntanglementRequests[nodeIdB] != nodeIdA, "NodeB already requested entanglement with NodeA");


        // Store request: A requests B
        pendingEntanglementRequests[nodeIdA] = nodeIdB;

        emit EntanglementRequested(nodeIdA, nodeIdB, block.timestamp);
    }

    function acceptEntanglement(uint256 nodeIdA, uint256 nodeIdB) external payable onlyNodeOwner(nodeIdB) notEntangled(nodeIdA) notEntangled(nodeIdB) {
        require(nodeExists[nodeIdA], "Requester node does not exist");
        // Check if B is accepting A's request for B
        require(pendingEntanglementRequests[nodeIdA] == nodeIdB, "No pending entanglement request from NodeA to NodeB");
        require(msg.value >= entanglementFee, "Insufficient entanglement fee");

        // Clear the pending request
        delete pendingEntanglementRequests[nodeIdA];

        // Establish entanglement
        entangledPartner[nodeIdA] = nodeIdB;
        entangledPartner[nodeIdB] = nodeIdA;
        entanglementTimestamp[nodeIdA] = block.timestamp;
        entanglementTimestamp[nodeIdB] = block.timestamp; // Store symmetrically

        // Collect fee
        feesCollected = feesCollected.add(msg.value);

        // Emit event
        emit EntanglementAccepted(nodeIdA, nodeIdB, block.timestamp);
    }

     function breakEntanglement(uint256 nodeId) external onlyNodeOwner(nodeId) isEntangled(nodeId) {
        uint256 partnerId = entangledPartner[nodeId];
        require(nodes[partnerId].owner == msg.sender || nodes[nodeId].owner == msg.sender, "Must be owner of one of the entangled nodes");
        // Optional policy: require minimum duration unless both agree (more complex)
        // require(block.timestamp >= entanglementTimestamp[nodeId] + entanglementMinDuration, "Cannot break before minimum duration"); // Or add a function for mutual breaking

        _breakEntanglement(nodeId, partnerId, "Voluntary Break");
    }

    // Internal helper for breaking entanglement
    function _breakEntanglement(uint256 nodeIdA, uint256 nodeIdB, string memory reason) internal {
         require(areEntangled(nodeIdA, nodeIdB), "Nodes are not entangled with each other");

        // Perform any state splitting/distribution here if needed
        // For example, call splitStateOnBreak(nodeIdA); or handle internal logic

        delete entangledPartner[nodeIdA];
        delete entangledPartner[nodeIdB];
        delete entanglementTimestamp[nodeIdA];
        delete entanglementTimestamp[nodeIdB];

        emit EntanglementBroken(nodeIdA, nodeIdB, block.timestamp, reason);
    }


    function simulateDecoherenceCheck(uint256 nodeId) external isEntangled(nodeId) {
        uint256 partnerId = entangledPartner[nodeId];

        // --- Simple Pseudo-Randomness Simulation ---
        // DO NOT use block.timestamp or block.difficulty for secure randomness
        // Use Chainlink VRF or similar for real-world applications.
        uint256 blockValue = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, nodeId, partnerId, msg.sender)));
        uint256 threshold = 50; // 50% chance simulation

        bool broken = false;
        if (blockValue % 100 < threshold) {
            _breakEntanglement(nodeId, partnerId, "Simulated Decoherence");
            broken = true;
        }
        // --- End Simulation ---

        emit DecoherenceSimulated(nodeId, partnerId, broken, block.timestamp);
    }


    // --- Node Value Management ---

    receive() external payable {
        // Allows contract to receive direct Ether, but it won't be assigned to a node automatically.
        // It would go to `address(this).balance`. Requires separate function to assign/deposit.
        // It's better to use the deposit function directly.
        revert("Direct Ether deposits not supported. Use depositValueToNode.");
    }

    function depositValueToNode(uint256 nodeId) external payable onlyNodeOwner(nodeId) {
        require(msg.value > 0, "Must deposit non-zero value");
        nodeBalances[nodeId] = nodeBalances[nodeId].add(msg.value);
        emit ValueDeposited(nodeId, msg.value);
    }

    function withdrawValueFromNode(uint256 nodeId, uint256 amount) external onlyNodeOwner(nodeId) {
        require(nodeBalances[nodeId] >= amount, "Insufficient node balance");
        nodeBalances[nodeId] = nodeBalances[nodeId].sub(amount);
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdrawal failed");
        emit ValueWithdrawn(nodeId, amount);
    }


    // --- Entangled Operations ---

    function transferValueEntangledSplit(uint256 nodeIdA) external payable isEntangled(nodeIdA) {
        require(msg.value > 0, "Must deposit non-zero value");
        uint256 nodeIdB = entangledPartner[nodeIdA];
        require(nodes[nodeIdA].owner == msg.sender || nodes[nodeIdB].owner == msg.sender, "Must own one of the entangled nodes");

        uint256 amountToSplit = msg.value;
        uint256 splitAmount = amountToSplit.div(2);
        uint256 remainder = amountToSplit.sub(splitAmount.mul(2)); // Handle odd amounts

        nodeBalances[nodeIdA] = nodeBalances[nodeIdA].add(splitAmount);
        nodeBalances[nodeIdB] = nodeBalances[nodeIdB].add(splitAmount);
        // Remainder could go to fees, or back to caller, or to one node. Let's add to fees.
        feesCollected = feesCollected.add(remainder);


        nodes[nodeIdA].pairedOperationCount++;
        nodes[nodeIdB].pairedOperationCount++;

        emit ValueSplitEntangled(nodeIdA, nodeIdB, splitAmount);
    }

     function transferValueBetweenEntangled(uint256 nodeIdA, uint256 amount) external isEntangled(nodeIdA) {
        uint256 nodeIdB = entangledPartner[nodeIdA];
        require(nodes[nodeIdA].owner == msg.sender, "Must own NodeA to transfer from it"); // Owner of A initiates
        require(nodeBalances[nodeIdA] >= amount, "Insufficient balance on NodeA");
        require(amount > 0, "Cannot transfer zero");

        nodeBalances[nodeIdA] = nodeBalances[nodeIdA].sub(amount);
        nodeBalances[nodeIdB] = nodeBalances[nodeIdB].add(amount);

        nodes[nodeIdA].pairedOperationCount++;
        nodes[nodeIdB].pairedOperationCount++;

        emit ValueTransferredEntangled(nodeIdA, nodeIdB, amount);
    }


    function applySynchronizedStateChange(uint256 nodeIdA, bool newState) external isEntangled(nodeIdA) {
        uint256 nodeIdB = entangledPartner[nodeIdA];
        require(nodes[nodeIdA].owner == msg.sender || nodes[nodeIdB].owner == msg.sender, "Must own one of the entangled nodes");

        nodes[nodeIdA].isActive = newState;
        nodes[nodeIdB].isActive = newState;

        nodes[nodeIdA].pairedOperationCount++;
        nodes[nodeIdB].pairedOperationCount++;

        emit SynchronizedStateChange(nodeIdA, nodeIdB, newState);
    }

    function swapStateEntangled(uint256 nodeIdA) external isEntangled(nodeIdA) {
        uint256 nodeIdB = entangledPartner[nodeIdA];
        require(nodes[nodeIdA].owner == msg.sender || nodes[nodeIdB].owner == msg.sender, "Must own one of the entangled nodes");

        bool stateA = nodes[nodeIdA].isActive;
        bool stateB = nodes[nodeIdB].isActive;

        nodes[nodeIdA].isActive = stateB;
        nodes[nodeIdB].isActive = stateA;

        nodes[nodeIdA].pairedOperationCount++;
        nodes[nodeIdB].pairedOperationCount++;

        emit StateSwappedEntangled(nodeIdA, nodeIdB);
    }

    function incrementPairedCounter(uint256 nodeIdA, uint256 amount) external isEntangled(nodeIdA) {
         uint256 nodeIdB = entangledPartner[nodeIdA];
         require(nodes[nodeIdA].owner == msg.sender || nodes[nodeIdB].owner == msg.sender, "Must own one of the entangled nodes");
         require(amount > 0, "Increment amount must be positive");

         // Let's make pairedOperationCount the shared counter for this function
         nodes[nodeIdA].pairedOperationCount = nodes[nodeIdA].pairedOperationCount.add(amount);
         nodes[nodeIdB].pairedOperationCount = nodes[nodeIdB].pairedOperationCount.add(amount);

         // Note: This increments the *same* counter used for tracking ops.
         // A separate `sharedCounter` state variable in the Node struct would be better
         // if this were a distinct concept. Using existing counter for demo function count.

         emit PairedCounterIncremented(nodeIdA, nodeIdB, amount);
    }

    function splitStateOnBreak(uint256 nodeId) external isEntangled(nodeId) {
        // This function is callable manually for demonstration,
        // but in a real scenario might be part of the _breakEntanglement logic.
        uint256 nodeIdA = nodeId;
        uint256 nodeIdB = entangledPartner[nodeIdA];
        require(nodes[nodeIdA].owner == msg.sender || nodes[nodeIdB].owner == msg.sender, "Must own one of the entangled nodes");

        // Example: Split the `pairedOperationCount` between the two nodes
        // based on some logic, e.g., 50/50.
        uint256 totalOps = nodes[nodeIdA].pairedOperationCount; // Since they are paired, their counters should be the same after incrementPairedCounter

        uint256 shareA = totalOps.div(2);
        uint256 shareB = totalOps.sub(shareA);

        // If pairedOperationCount was *only* incremented via incrementPairedCounter,
        // the values would be identical. If it tracks *all* entangled ops, this split
        // might need more complex logic based on contributions.
        // For simplicity here, let's imagine a hypothetical `cumulativeSharedValue` field.
        // We will just emit the current shared counter value split.

        emit StateSplitUponBreak(nodeIdA, nodeIdB, shareA, shareB);

        // In a real scenario, you would update state here, e.g.:
        // nodes[nodeIdA].postSplitValue = shareA;
        // nodes[nodeIdB].postSplitValue = shareB;
    }

    function triggerPairedEvent(uint256 nodeIdA, string calldata message) external isEntangled(nodeIdA) {
        uint256 nodeIdB = entangledPartner[nodeIdA];
        require(nodes[nodeIdA].owner == msg.sender || nodes[nodeIdB].owner == msg.sender, "Must own one of the entangled nodes");

        // This function primarily serves to emit an event associated with the pair
        emit PairedEventTriggered(nodeIdA, nodeIdB, message);

        nodes[nodeIdA].pairedOperationCount++;
        nodes[nodeIdB].pairedOperationCount++;
    }

    function influenceEntanglementByOracle(uint256 nodeIdA, int256 oracleValue) external isEntangled(nodeIdA) {
         // In a real DApp, this would be called by a trusted Oracle contract
         // e.g., checking a price feed or external data source.
         // We simulate passing the value directly for demonstration.
         uint256 nodeIdB = entangledPartner[nodeIdA];
         require(nodes[nodeIdA].owner == msg.sender || nodes[nodeIdB].owner == msg.sender, "Must own one of the entangled nodes to initiate oracle influence");


         // Example logic: if oracle value is negative, potentially trigger a state change or decoherence chance.
         if (oracleValue < 0) {
             // Could increase decoherence chance, or flip the isActive state
             bool currentState = nodes[nodeIdA].isActive; // State is synchronized
             nodes[nodeIdA].isActive = !currentState;
             nodes[nodeIdB].isActive = !currentState;
             emit SynchronizedStateChange(nodeIdA, nodeIdB, !currentState);
             // Could also call simulateDecoherenceCheck(nodeIdA) internally with a higher chance
         } else {
             // Positive value could reinforce entanglement, maybe add to a 'stability' score
             // Or trigger a positive state change
              nodes[nodeIdA].isActive = true; // Example positive effect
              nodes[nodeIdB].isActive = true;
              emit SynchronizedStateChange(nodeIdA, nodeIdB, true);
         }

         emit OracleInfluenceApplied(nodeIdA, nodeIdB, oracleValue);
         // Paired operation count update is optional for this influenced event. Let's not count it.
    }


    // --- Queries & Status ---

    function getEntanglementStatus(uint256 nodeId) public view returns (EntanglementStatus) {
        if (!nodeExists[nodeId]) {
            return EntanglementStatus.None; // Or revert, depending on desired behavior for non-existent nodes
        }
        if (entangledPartner[nodeId] != 0) {
            return EntanglementStatus.Entangled;
        }
        // Check if *this* node is the target of a pending request
        // This requires iterating through pending requests or using a reverse mapping (more gas)
        // Simpler: Check if *this* node has made a pending request *or* is the target.
        // A pending request for A->B means pendingEntanglementRequests[A] == B.
        // How to check if B is a target? A reverse mapping is needed.
        // Let's add a reverse mapping `isTargetOfPendingRequest[nodeId] = requesterId`.
        // This adds complexity. A simpler approach for the query function: only check if *this* node
        // *initiated* a pending request. For checking if it's a *target*, the user would need to
        // call getPendingRequest(PotentialRequesterId).

        // Let's implement the reverse mapping `isTargetOfPendingRequest` for a more complete status query.
        // Add `mapping(uint256 => uint256) private isTargetOfPendingRequest; // nodeIdB => nodeIdA`
        // Update requestEntanglement and acceptEntanglement to manage this mapping.
        // ... (Adding this mapping and logic would increase complexity and gas, let's stick to the summary's simpler status for now or note the limitation)

        // Re-simplifying: Query only checks if *this* node initiated or is entangled.
        // To see if it's a target, the user needs to check pending requests from potential partners.
         if (pendingEntanglementRequests[nodeId] != 0) {
             // This node has initiated a request
             return EntanglementStatus.PendingRequest;
         }
        // Okay, let's add the reverse mapping `isTargetOfPendingRequest` anyway to make this query more useful.
        // *Self-correction*: Added `isTargetOfPendingRequest` mapping in the state variables.

        if (isTargetOfPendingRequest[nodeId] != 0) {
            // This node is the target of a pending request
             return EntanglementStatus.PendingRequest;
        }

        return EntanglementStatus.None;
    }

     // Re-implementing request/accept with reverse mapping management
     function requestEntanglement_v2(uint256 nodeIdA, uint256 nodeIdB) external onlyNodeOwner(nodeIdA) notEntangled(nodeIdA) notEntangled(nodeIdB) {
        require(nodeIdA != nodeIdB, "Cannot request entanglement with self");
        require(nodeExists[nodeIdB], "Target node does not exist");
        require(nodes[nodeIdB].owner != msg.sender, "Cannot request entanglement with your own node");
        require(pendingEntanglementRequests[nodeIdA] == 0, "NodeA already has initiated a pending request");
        require(isTargetOfPendingRequest[nodeIdA] == 0, "NodeA is already a target of a pending request");
        require(isTargetOfPendingRequest[nodeIdB] == 0, "NodeB is already a target of a pending request"); // NodeB cannot be target of another request

        // Store request: A requests B
        pendingEntanglementRequests[nodeIdA] = nodeIdB;
        isTargetOfPendingRequest[nodeIdB] = nodeIdA; // B is target of A's request

        emit EntanglementRequested(nodeIdA, nodeIdB, block.timestamp);
    }

    function acceptEntanglement_v2(uint256 nodeIdA, uint256 nodeIdB) external payable onlyNodeOwner(nodeIdB) notEntangled(nodeIdA) notEntangled(nodeIdB) {
        require(nodeExists[nodeIdA], "Requester node does not exist");
        // Check if B is accepting A's request for B
        require(pendingEntanglementRequests[nodeIdA] == nodeIdB, "No pending entanglement request from NodeA to NodeB");
        require(isTargetOfPendingRequest[nodeIdB] == nodeIdA, "Pending request state mismatch"); // Redundant check but good safety

        require(msg.value >= entanglementFee, "Insufficient entanglement fee");

        // Clear the pending request mappings
        delete pendingEntanglementRequests[nodeIdA];
        delete isTargetOfPendingRequest[nodeIdB];

        // Establish entanglement
        entangledPartner[nodeIdA] = nodeIdB;
        entangledPartner[nodeIdB] = nodeIdA;
        entanglementTimestamp[nodeIdA] = block.timestamp;
        entanglementTimestamp[nodeIdB] = block.timestamp;

        // Collect fee
        feesCollected = feesCollected.add(msg.value);

        // Emit event
        emit EntanglementAccepted(nodeIdA, nodeIdB, block.timestamp);
    }

    // Replace the original request/accept functions with _v2 in the final code, but keeping originals commented for thought process.

    function getPartnerNode(uint256 nodeId) external view returns (uint256) {
         require(nodeExists[nodeId], "Node does not exist");
         return entangledPartner[nodeId]; // Returns 0 if not entangled
    }

    function queryEntangledNetValue(uint256 nodeId) external view isEntangled(nodeId) returns (uint256) {
        uint256 partnerId = entangledPartner[nodeId];
        return nodeBalances[nodeId].add(nodeBalances[partnerId]);
    }

     function getNodeOperationCount(uint256 nodeId) external view returns (uint256) {
        require(nodeExists[nodeId], "Node does not exist");
        return nodes[nodeId].pairedOperationCount;
     }

    function getPendingRequest(uint256 nodeId) external view returns (uint256 targetNodeId) {
         // Checks if *this* node initiated a request
         return pendingEntanglementRequests[nodeId];
    }

    function getPendingRequestTargeting(uint256 nodeId) external view returns (uint256 requesterNodeId) {
        // Checks if *this* node is the target of a request
        return isTargetOfPendingRequest[nodeId];
    }


    // Add helper mapping for getEntanglementStatus more efficiently
    mapping(uint256 => uint256) private isTargetOfPendingRequest; // nodeIdB => nodeIdA (B is target of A's request)

    // Final check on function count:
    // 1. setEntanglementFee
    // 2. setEntanglementPolicy
    // 3. withdrawFees
    // 4. transferOwnership (from Ownable)
    // 5. createNode
    // 6. getNodeInfo
    // 7. deleteNode
    // 8. transferNodeOwnership
    // 9. requestEntanglement_v2
    // 10. acceptEntanglement_v2
    // 11. breakEntanglement
    // 12. simulateDecoherenceCheck
    // 13. depositValueToNode
    // 14. withdrawValueFromNode
    // 15. transferValueEntangledSplit
    // 16. transferValueBetweenEntangled
    // 17. applySynchronizedStateChange
    // 18. swapStateEntangled
    // 19. incrementPairedCounter
    // 20. splitStateOnBreak (callable demo)
    // 21. triggerPairedEvent
    // 22. influenceEntanglementByOracle
    // 23. getEntanglementStatus
    // 24. getPartnerNode
    // 25. queryEntangledNetValue
    // 26. getNodeOperationCount
    // 27. getPendingRequest (initiated by node)
    // 28. getPendingRequestTargeting (node is target)
    // 29. receive() - although it reverts, it's a function header. Let's count public/external/receive.

    // Okay, 28 or 29 functions depending on how you count receive(). Definitely over 20.

    // Final clean up: Use _v2 functions and remove commented originals. Add isTargetOfPendingRequest state var.
    // Add import for SafeMath if needed (0.8+ doesn't strictly need it for basic ops but good habit or for complex math). Keeping it.
    // Add NatSpec comments to functions.

}
```

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title QuantumEntanglement
 * @dev A smart contract simulating a concept of "entanglement" between owned entities (Nodes).
 * Operations on one entangled Node can synchronously affect its partner. Includes state,
 * value, and event synchronization, external influence (simulated oracle), and probabilistic
 * "decoherence". Designed with a variety of functions exploring paired interactions.
 */
contract QuantumEntanglement is Ownable {
    using SafeMath for uint256;

    /*
    Outline:
    1.  **Core State & Structs:** Define the fundamental Node entity and mappings for entanglement and state.
    2.  **Admin & Configuration:** Functions for the contract owner to set parameters (fees, policies).
    3.  **Node Management:** Functions to create, retrieve, and manage ownership of individual Nodes.
    4.  **Entanglement Lifecycle:** Functions for requesting, accepting, breaking, and querying entanglement between Nodes, including simulated decoherence.
    5.  **Node Value Management:** Functions to deposit and withdraw value associated with Nodes.
    6.  **Entangled Operations:** The core unique functions that perform synchronized actions on entangled Node pairs (value, state, events, counters).
    7.  **External Influence:** Function showing how external factors (simulated oracle) can affect entanglement or state.
    8.  **Queries & Status:** Helper functions to get detailed information about Nodes and their entanglement status, including pending requests.
    9.  **Events:** To signal key state changes and actions.
    10. **Receive/Fallback:** To accept Ether deposits (though handled by a specific deposit function).
    */

    /*
    Function Summary:

    -   **Admin & Configuration:**
        -   `setEntanglementFee(uint256 _fee)`: Owner sets the fee required to establish entanglement.
        -   `setEntanglementPolicy(uint256 minDuration, uint256 maxNodesPerOwner)`: Owner sets rules for entanglement duration and node limits per owner.
        -   `withdrawFees()`: Owner withdraws accumulated fees collected from entanglement.
        -   `transferOwnership(address newOwner)`: Standard Ownable function to transfer contract ownership.

    -   **Node Management:**
        -   `createNode()`: Creates a new independent Node owned by the caller.
        -   `getNodeInfo(uint256 nodeId)`: Retrieves comprehensive details of a specific Node.
        -   `deleteNode(uint256 nodeId)`: Deletes a Node (only if owned, not entangled, and balance is zero).
        -   `transferNodeOwnership(uint256 nodeId, address newOwner)`: Transfers ownership of an existing Node to a new address.

    -   **Entanglement Lifecycle:**
        -   `requestEntanglement(uint256 nodeIdA, uint256 nodeIdB)`: Owner of NodeA requests entanglement with NodeB (owned by someone else).
        -   `acceptEntanglement(uint256 nodeIdA, uint256 nodeIdB)`: Owner of NodeB accepts NodeA's request and pays the entanglement fee.
        -   `breakEntanglement(uint256 nodeId)`: Either owner of an entangled pair can initiate breaking the entanglement.
        -   `simulateDecoherenceCheck(uint256 nodeId)`: Allows anyone to trigger a probabilistic check that might randomly break entanglement based on simulated randomness.

    -   **Node Value Management:**
        -   `depositValueToNode(uint256 nodeId)`: Deposit sent Ether into the contract, associating it with a specific Node's internal balance.
        -   `withdrawValueFromNode(uint256 nodeId, uint256 amount)`: Withdraw Ether from a Node's internal balance.

    -   **Entangled Operations:**
        -   `transferValueEntangledSplit(uint256 nodeIdA)`: Deposit sent Ether to NodeA; the value is split 50/50 between NodeA and its entangled partner NodeB.
        -   `transferValueBetweenEntangled(uint256 nodeIdA, uint256 amount)`: Transfer a specified amount of internal balance from NodeA to its entangled partner NodeB.
        -   `applySynchronizedStateChange(uint256 nodeIdA, bool newState)`: Sets the `isActive` state variable to the same value on both NodeA and its entangled partner NodeB.
        -   `swapStateEntangled(uint256 nodeIdA)`: Swaps the `isActive` state flag between NodeA and its entangled partner NodeB.
        -   `incrementPairedCounter(uint256 nodeIdA, uint256 amount)`: Increments a shared counter (using `pairedOperationCount`) on both entangled nodes by a specified amount.
        -   `splitStateOnBreak(uint256 nodeId)`: A demo function to show how a cumulative state (like the paired counter) *could* be split between nodes upon breaking entanglement.
        -   `triggerPairedEvent(uint256 nodeIdA, string calldata message)`: Emits a custom event (`PairedEventTriggered`) for both nodes in the entangled pair.

    -   **External Influence:**
        -   `influenceEntanglementByOracle(uint256 nodeIdA, int256 oracleValue)`: Simulates influence from an external oracle value, potentially triggering state changes based on the value.

    -   **Queries & Status:**
        -   `getEntanglementStatus(uint256 nodeId)`: Returns the current entanglement status of a Node (None, PendingRequest, Entangled).
        -   `getPartnerNode(uint256 nodeId)`: Returns the ID of the entangled partner Node (0 if not entangled).
        -   `queryEntangledNetValue(uint256 nodeId)`: Returns the sum of internal balances held by an entangled pair.
        -   `getNodeOperationCount(uint256 nodeId)`: Returns the number of entangled operations a Node has participated in.
        -   `getPendingRequest(uint256 nodeId)`: Returns the Node ID that this node (nodeId) *initiated* a request to (0 if none).
        -   `getPendingRequestTargeting(uint256 nodeId)`: Returns the Node ID that *requested* entanglement with this node (nodeId) (0 if none).

    -   **Receive/Fallback:**
        -   `receive()`: Explicitly rejects direct Ether transfers not routed through `depositValueToNode`.

    */

    struct Node {
        address owner;
        uint256 id;
        uint256 creationTimestamp;
        uint256 pairedOperationCount;
        bool isActive; // Example state flag for synchronized changes
        // Add more state variables here as needed
    }

    enum EntanglementStatus { None, PendingRequest, Entangled }

    // Node storage
    uint256 private _nextNodeId = 1;
    mapping(uint256 => Node) public nodes;
    mapping(uint256 => bool) public nodeExists; // Faster check

    // Entanglement state
    mapping(uint256 => uint256) public entangledPartner; // nodeId => partnerNodeId (0 if not entangled)
    mapping(uint256 => uint256) public pendingEntanglementRequests; // nodeIdA => nodeIdB (A requested B)
    mapping(uint256 => uint256) private isTargetOfPendingRequest; // nodeIdB => nodeIdA (B is target of A's request) - for status query
    mapping(uint256 => uint256) public entanglementTimestamp; // nodeId => timestamp of entanglement

    // Node Balances (Ether held by contract for nodes)
    mapping(uint256 => uint256) private nodeBalances;

    // Configuration & Fees
    uint256 public entanglementFee = 0.01 ether; // Fee to accept entanglement
    uint256 public feesCollected;

    // Policy
    uint256 public entanglementMinDuration = 1 days; // Minimum time before easy breaking (policy example)
    uint256 public maxNodesPerOwner = 10; // Limit nodes per address (policy example)

    // Events
    event NodeCreated(uint256 indexed nodeId, address indexed owner, uint256 timestamp);
    event NodeDeleted(uint256 indexed nodeId);
    event NodeOwnershipTransferred(uint256 indexed nodeId, address indexed oldOwner, address indexed newOwner);

    event EntanglementRequested(uint256 indexed nodeIdA, uint256 indexed nodeIdB, uint256 timestamp);
    event EntanglementAccepted(uint256 indexed nodeIdA, uint256 indexed nodeIdB, uint256 timestamp);
    event EntanglementBroken(uint256 indexed nodeIdA, uint256 indexed nodeIdB, uint256 timestamp, string reason);
    event DecoherenceSimulated(uint256 indexed nodeIdA, uint256 indexed nodeIdB, bool broken, uint256 timestamp);

    event ValueDeposited(uint256 indexed nodeId, uint256 amount);
    event ValueWithdrawn(uint256 indexed nodeId, uint256 amount);
    event ValueSplitEntangled(uint256 indexed nodeIdA, uint256 indexed nodeIdB, uint256 amount);
    event ValueTransferredEntangled(uint256 indexed nodeIdA, uint256 indexed nodeIdB, uint256 amount);

    event SynchronizedStateChange(uint256 indexed nodeIdA, uint256 indexed nodeIdB, bool newState);
    event StateSwappedEntangled(uint256 indexed nodeIdA, uint256 indexed nodeIdB);
    event PairedCounterIncremented(uint256 indexed nodeIdA, uint256 indexed nodeIdB, uint256 increment);
    event StateSplitUponBreak(uint256 indexed nodeIdA, uint256 indexed nodeIdB, uint256 finalValueA, uint256 finalValueB);
    event PairedEventTriggered(uint256 indexed nodeIdA, uint256 indexed nodeIdB, string message);
    event OracleInfluenceApplied(uint256 indexed nodeIdA, uint256 indexed nodeIdB, int256 oracleValue);


    // Modifiers
    modifier onlyNodeOwner(uint256 nodeId) {
        require(nodeExists[nodeId], "QE: Node does not exist");
        require(nodes[nodeId].owner == msg.sender, "QE: Not node owner");
        _;
    }

    modifier notEntangled(uint256 nodeId) {
        require(nodeExists[nodeId], "QE: Node does not exist");
        require(entangledPartner[nodeId] == 0, "QE: Node is already entangled");
        _;
    }

    modifier isEntangled(uint256 nodeId) {
        require(nodeExists[nodeId], "QE: Node does not exist");
        require(entangledPartner[nodeId] != 0, "QE: Node is not entangled");
        _;
    }

     modifier areEntangled(uint256 nodeIdA, uint256 nodeIdB) {
        require(isEntangled(nodeIdA), "QE: NodeA not entangled");
        uint256 partnerA = entangledPartner[nodeIdA];
        require(partnerA == nodeIdB, "QE: Nodes are not entangled with each other");
        // Redundant check, but good safety
        require(isEntangled(nodeIdB), "QE: NodeB not entangled");
        require(entangledPartner[nodeIdB] == nodeIdA, "QE: Nodes are not entangled with each other (symmetric check failed)");
        _;
    }

    constructor() {}

    // --- Admin & Configuration ---

    /**
     * @dev Sets the fee required for the recipient of an entanglement request to accept it.
     * @param _fee The new entanglement fee in wei.
     */
    function setEntanglementFee(uint256 _fee) external onlyOwner {
        entanglementFee = _fee;
    }

    /**
     * @dev Sets policy rules for entanglement, such as minimum duration or node limits per owner.
     * @param minDuration Minimum duration entanglement must last before easy breaking (in seconds).
     * @param maxNodes Maximum number of nodes an single owner can create.
     */
    function setEntanglementPolicy(uint256 minDuration, uint256 maxNodes) external onlyOwner {
        entanglementMinDuration = minDuration;
        maxNodesPerOwner = maxNodes;
    }

    /**
     * @dev Allows the contract owner to withdraw collected entanglement fees.
     */
    function withdrawFees() external onlyOwner {
        uint256 amount = feesCollected;
        feesCollected = 0;
        // Use a low-level call for robustness against reentrancy
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "QE: Fee withdrawal failed");
    }

    // --- Node Management ---

    /**
     * @dev Creates a new independent Node owned by the caller.
     * Enforces the maxNodesPerOwner policy.
     */
    function createNode() external notEntangled(0) { // Use 0 check to avoid potential conflicts
        // Count existing nodes for the owner (can be inefficient for many nodes)
        // For a very large number of nodes, a separate mapping like `mapping(address => uint256) nodesPerOwner;`
        // updated on creation/deletion would be more gas efficient for counting.
        uint256 ownerNodeCount = 0;
        uint256 currentId = 1;
        while(currentId < _nextNodeId) {
            if (nodeExists[currentId] && nodes[currentId].owner == msg.sender) {
                ownerNodeCount++;
            }
            currentId++;
        }
        require(ownerNodeCount < maxNodesPerOwner, "QE: Owner reached max node limit");

        uint256 newNodeId = _nextNodeId++;
        nodes[newNodeId] = Node(
            msg.sender,
            newNodeId,
            block.timestamp,
            0, // pairedOperationCount
            false // isActive
            // Initialize other state variables
        );
        nodeExists[newNodeId] = true;

        emit NodeCreated(newNodeId, msg.sender, block.timestamp);
    }

    /**
     * @dev Retrieves comprehensive details about a specific Node.
     * @param nodeId The ID of the Node to query.
     * @return owner The address that owns the node.
     * @return creationTimestamp The timestamp when the node was created.
     * @return operationCount The number of entangled operations this node has participated in.
     * @return isActive The current state of the isActive flag.
     * @return balance The internal Ether balance associated with this node.
     * @return status The current entanglement status (None, PendingRequest, Entangled).
     * @return partnerId The ID of the entangled partner or pending request target/requester (0 if none).
     */
    function getNodeInfo(uint256 nodeId) external view returns (address owner, uint256 creationTimestamp, uint256 operationCount, bool isActive, uint256 balance, EntanglementStatus status, uint256 partnerId) {
        require(nodeExists[nodeId], "QE: Node does not exist");
        EntanglementStatus nodeStatus = getEntanglementStatus(nodeId);
        uint256 partner = 0;

        if (nodeStatus == EntanglementStatus.PendingRequest) {
             // Could be initiating or target. Return the ID of the other party in the request.
             if (pendingEntanglementRequests[nodeId] != 0) {
                 partner = pendingEntanglementRequests[nodeId];
             } else if (isTargetOfPendingRequest[nodeId] != 0) {
                 partner = isTargetOfPendingRequest[nodeId];
             }
        } else if (nodeStatus == EntanglementStatus.Entangled) {
             partner = entangledPartner[nodeId];
        }

        return (
            nodes[nodeId].owner,
            nodes[nodeId].creationTimestamp,
            nodes[nodeId].pairedOperationCount,
            nodes[nodeId].isActive,
            nodeBalances[nodeId],
            nodeStatus,
            partner
        );
    }

    /**
     * @dev Deletes a Node. Only possible if owned by caller, not entangled, and balance is zero.
     * @param nodeId The ID of the Node to delete.
     */
    function deleteNode(uint256 nodeId) external onlyNodeOwner(nodeId) notEntangled(nodeId) {
        // Check if Node is involved in any pending requests
        require(pendingEntanglementRequests[nodeId] == 0 && isTargetOfPendingRequest[nodeId] == 0, "QE: Node has pending entanglement requests");

        require(nodeBalances[nodeId] == 0, "QE: Node balance must be zero to delete");

        delete nodes[nodeId];
        delete nodeExists[nodeId];
        // Node balance is already checked to be 0, no need to delete mapping entry with non-zero value.

        emit NodeDeleted(nodeId);
    }

    /**
     * @dev Transfers ownership of a Node to a new address.
     * @param nodeId The ID of the Node to transfer.
     * @param newOwner The address of the new owner.
     */
    function transferNodeOwnership(uint256 nodeId, address newOwner) external onlyNodeOwner(nodeId) {
        require(newOwner != address(0), "QE: New owner cannot be zero address");
        address oldOwner = nodes[nodeId].owner;
        nodes[nodeId].owner = newOwner;
        emit NodeOwnershipTransferred(nodeId, oldOwner, newOwner);
    }

    // --- Entanglement Lifecycle ---

    /**
     * @dev Initiates a request for entanglement between two Nodes.
     * Requires the caller to own nodeIdA. Neither node can be already entangled or involved in pending requests.
     * @param nodeIdA The ID of the Node initiating the request (owned by caller).
     * @param nodeIdB The ID of the Node being requested (owned by another address).
     */
    function requestEntanglement(uint256 nodeIdA, uint256 nodeIdB) external onlyNodeOwner(nodeIdA) notEntangled(nodeIdA) notEntangled(nodeIdB) {
        require(nodeIdA != nodeIdB, "QE: Cannot request entanglement with self");
        require(nodeExists[nodeIdB], "QE: Target node does not exist");
        require(nodes[nodeIdB].owner != msg.sender, "QE: Cannot request entanglement with your own node");
        require(pendingEntanglementRequests[nodeIdA] == 0, "QE: NodeA already initiated a pending request");
        require(isTargetOfPendingRequest[nodeIdA] == 0, "QE: NodeA is already a target of a pending request");
        require(isTargetOfPendingRequest[nodeIdB] == 0, "QE: NodeB is already a target of a pending request"); // NodeB cannot be target of another request

        // Store request: A requests B
        pendingEntanglementRequests[nodeIdA] = nodeIdB;
        isTargetOfPendingRequest[nodeIdB] = nodeIdA; // B is target of A's request

        emit EntanglementRequested(nodeIdA, nodeIdB, block.timestamp);
    }

    /**
     * @dev Accepts a pending entanglement request.
     * Requires the caller to own nodeIdB and pay the entanglement fee.
     * Establishes entanglement between nodeIdA and nodeIdB.
     * @param nodeIdA The ID of the Node that initiated the request.
     * @param nodeIdB The ID of the Node accepting the request (owned by caller).
     */
    function acceptEntanglement(uint256 nodeIdA, uint256 nodeIdB) external payable onlyNodeOwner(nodeIdB) notEntangled(nodeIdA) notEntangled(nodeIdB) {
        require(nodeExists[nodeIdA], "QE: Requester node does not exist");
        // Check if B is accepting A's request for B
        require(pendingEntanglementRequests[nodeIdA] == nodeIdB, "QE: No pending entanglement request from NodeA to NodeB");
        require(isTargetOfPendingRequest[nodeIdB] == nodeIdA, "QE: Pending request state mismatch"); // Redundant check but good safety

        require(msg.value >= entanglementFee, "QE: Insufficient entanglement fee");

        // Clear the pending request mappings
        delete pendingEntanglementRequests[nodeIdA];
        delete isTargetOfPendingRequest[nodeIdB];

        // Establish entanglement
        entangledPartner[nodeIdA] = nodeIdB;
        entangledPartner[nodeIdB] = nodeIdA;
        entanglementTimestamp[nodeIdA] = block.timestamp;
        entanglementTimestamp[nodeIdB] = block.timestamp;

        // Collect fee
        feesCollected = feesCollected.add(msg.value);

        // Emit event
        emit EntanglementAccepted(nodeIdA, nodeIdB, block.timestamp);
    }

     /**
     * @dev Breaks the entanglement of a Node.
     * Requires the caller to own one of the entangled Nodes.
     * @param nodeId The ID of one of the entangled Nodes.
     */
    function breakEntanglement(uint256 nodeId) external isEntangled(nodeId) {
        uint256 partnerId = entangledPartner[nodeId];
        require(nodes[nodeId].owner == msg.sender || nodes[partnerId].owner == msg.sender, "QE: Must be owner of one of the entangled nodes");
        // Optional policy: require minimum duration unless both agree (more complex)
        // require(block.timestamp >= entanglementTimestamp[nodeId] + entanglementMinDuration, "Cannot break before minimum duration"); // Or add a function for mutual breaking

        _breakEntanglement(nodeId, partnerId, "Voluntary Break");
    }

    /**
     * @dev Internal helper function to break entanglement state.
     * @param nodeIdA The ID of the first node in the pair.
     * @param nodeIdB The ID of the second node in the pair.
     * @param reason A string explaining why the entanglement was broken.
     */
    function _breakEntanglement(uint256 nodeIdA, uint256 nodeIdB, string memory reason) internal areEntangled(nodeIdA, nodeIdB) {
        // Perform any state splitting/distribution here if needed BEFORE breaking state
        // Example: splitStateOnBreak(nodeIdA); // This would be internal logic, not callable external normally

        delete entangledPartner[nodeIdA];
        delete entangledPartner[nodeIdB];
        delete entanglementTimestamp[nodeIdA];
        delete entanglementTimestamp[nodeIdB];

        emit EntanglementBroken(nodeIdA, nodeIdB, block.timestamp, reason);
    }

    /**
     * @dev Simulates "Decoherence" - a probabilistic chance for entanglement to break randomly.
     * Can be triggered by anyone for an entangled node. Uses simple block data for pseudo-randomness.
     * **WARNING:** Using block.timestamp or block.difficulty for randomness is insecure in production.
     * Use Chainlink VRF or similar for secure randomness.
     * @param nodeId The ID of one of the entangled Nodes to check.
     */
    function simulateDecoherenceCheck(uint256 nodeId) external isEntangled(nodeId) {
        uint256 partnerId = entangledPartner[nodeId];

        // --- Simple Pseudo-Randomness Simulation (DO NOT USE IN PRODUCTION) ---
        // For demonstration purposes only. Replace with a secure VRF.
        uint256 blockValue = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, nodeId, partnerId, msg.sender)));
        uint256 threshold = 50; // 50% chance simulation

        bool broken = false;
        if (blockValue % 100 < threshold) {
            _breakEntanglement(nodeId, partnerId, "Simulated Decoherence");
            broken = true;
        }
        // --- End Simulation ---

        emit DecoherenceSimulated(nodeId, partnerId, broken, block.timestamp);
    }

    // --- Node Value Management ---

    /**
     * @dev Reverts if Ether is sent directly to the contract address without calling a specific function.
     * Forces users to use `depositValueToNode`.
     */
    receive() external payable {
        revert("QE: Direct Ether deposits not supported. Use depositValueToNode.");
    }

    /**
     * @dev Deposits Ether sent with the transaction into the contract, associated with a specific Node.
     * Requires the caller to own the Node.
     * @param nodeId The ID of the Node to deposit value for.
     */
    function depositValueToNode(uint256 nodeId) external payable onlyNodeOwner(nodeId) {
        require(msg.value > 0, "QE: Must deposit non-zero value");
        nodeBalances[nodeId] = nodeBalances[nodeId].add(msg.value);
        emit ValueDeposited(nodeId, msg.value);
    }

    /**
     * @dev Withdraws Ether from a Node's internal balance to the Node owner.
     * Requires the caller to own the Node.
     * @param nodeId The ID of the Node to withdraw value from.
     * @param amount The amount of Ether to withdraw (in wei).
     */
    function withdrawValueFromNode(uint256 nodeId, uint256 amount) external onlyNodeOwner(nodeId) {
        require(nodeBalances[nodeId] >= amount, "QE: Insufficient node balance");
        require(amount > 0, "QE: Cannot withdraw zero");
        nodeBalances[nodeId] = nodeBalances[nodeId].sub(amount);
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "QE: Withdrawal failed");
        emit ValueWithdrawn(nodeId, amount);
    }

    // --- Entangled Operations ---

    /**
     * @dev Deposits Ether sent with the transaction, splitting it equally between an entangled Node pair.
     * Requires the caller to own one of the entangled Nodes.
     * Any remainder from an odd amount is added to contract fees.
     * @param nodeIdA The ID of one of the entangled Nodes.
     */
    function transferValueEntangledSplit(uint256 nodeIdA) external payable isEntangled(nodeIdA) {
        require(msg.value > 0, "QE: Must deposit non-zero value");
        uint256 nodeIdB = entangledPartner[nodeIdA];
        require(nodes[nodeIdA].owner == msg.sender || nodes[nodeIdB].owner == msg.sender, "QE: Must own one of the entangled nodes");

        uint256 amountToSplit = msg.value;
        uint256 splitAmount = amountToSplit.div(2);
        uint256 remainder = amountToSplit.sub(splitAmount.mul(2));

        nodeBalances[nodeIdA] = nodeBalances[nodeIdA].add(splitAmount);
        nodeBalances[nodeIdB] = nodeBalances[nodeIdB].add(splitAmount);
        feesCollected = feesCollected.add(remainder);

        nodes[nodeIdA].pairedOperationCount++;
        nodes[nodeIdB].pairedOperationCount++;

        emit ValueSplitEntangled(nodeIdA, nodeIdB, splitAmount);
    }

    /**
     * @dev Transfers value from the internal balance of one Node to its entangled partner.
     * Requires the caller to own the sending Node (nodeIdA).
     * @param nodeIdA The ID of the Node to transfer value from (must be owned by caller).
     * @param amount The amount of internal balance to transfer.
     */
     function transferValueBetweenEntangled(uint256 nodeIdA, uint256 amount) external isEntangled(nodeIdA) {
        uint256 nodeIdB = entangledPartner[nodeIdA];
        require(nodes[nodeIdA].owner == msg.sender, "QE: Must own NodeA to transfer from it"); // Owner of A initiates
        require(nodeBalances[nodeIdA] >= amount, "QE: Insufficient balance on NodeA");
        require(amount > 0, "QE: Cannot transfer zero");

        nodeBalances[nodeIdA] = nodeBalances[nodeIdA].sub(amount);
        nodeBalances[nodeIdB] = nodeBalances[nodeIdB].add(amount);

        nodes[nodeIdA].pairedOperationCount++;
        nodes[nodeIdB].pairedOperationCount++;

        emit ValueTransferredEntangled(nodeIdA, nodeIdB, amount);
    }

    /**
     * @dev Synchronizes the `isActive` state flag for both Nodes in an entangled pair.
     * Requires the caller to own one of the entangled Nodes.
     * @param nodeIdA The ID of one of the entangled Nodes.
     * @param newState The desired new state for the `isActive` flag.
     */
    function applySynchronizedStateChange(uint256 nodeIdA, bool newState) external isEntangled(nodeIdA) {
        uint256 nodeIdB = entangledPartner[nodeIdA];
        require(nodes[nodeIdA].owner == msg.sender || nodes[nodeIdB].owner == msg.sender, "QE: Must own one of the entangled nodes");

        nodes[nodeIdA].isActive = newState;
        nodes[nodeIdB].isActive = newState;

        nodes[nodeIdA].pairedOperationCount++;
        nodes[nodeIdB].pairedOperationCount++;

        emit SynchronizedStateChange(nodeIdA, nodeIdB, newState);
    }

    /**
     * @dev Swaps the `isActive` state flag between two Nodes in an entangled pair.
     * Requires the caller to own one of the entangled Nodes.
     * @param nodeIdA The ID of one of the entangled Nodes.
     */
    function swapStateEntangled(uint256 nodeIdA) external isEntangled(nodeIdA) {
        uint256 nodeIdB = entangledPartner[nodeIdA];
        require(nodes[nodeIdA].owner == msg.sender || nodes[nodeIdB].owner == msg.sender, "QE: Must own one of the entangled nodes");

        bool stateA = nodes[nodeIdA].isActive;
        bool stateB = nodes[nodeIdB].isActive;

        nodes[nodeIdA].isActive = stateB;
        nodes[nodeIdB].isActive = stateA;

        nodes[nodeIdA].pairedOperationCount++;
        nodes[nodeIdB].pairedOperationCount++;

        emit StateSwappedEntangled(nodeIdA, nodeIdB);
    }

     /**
     * @dev Increments the `pairedOperationCount` on both Nodes in an entangled pair by a specified amount.
     * Requires the caller to own one of the entangled Nodes.
     * @param nodeIdA The ID of one of the entangled Nodes.
     * @param amount The amount to increment the counter by.
     */
    function incrementPairedCounter(uint256 nodeIdA, uint256 amount) external isEntangled(nodeIdA) {
         uint256 nodeIdB = entangledPartner[nodeIdA];
         require(nodes[nodeIdA].owner == msg.sender || nodes[nodeIdB].owner == msg.sender, "QE: Must own one of the entangled nodes");
         require(amount > 0, "QE: Increment amount must be positive");

         nodes[nodeIdA].pairedOperationCount = nodes[nodeIdA].pairedOperationCount.add(amount);
         nodes[nodeIdB].pairedOperationCount = nodes[nodeIdB].pairedOperationCount.add(amount);

         emit PairedCounterIncremented(nodeIdA, nodeIdB, amount);
    }

    /**
     * @dev Demonstrates splitting a cumulative state (like the `pairedOperationCount`) upon breaking entanglement.
     * This version is callable manually for demonstration; in practice, this logic would be inside `_breakEntanglement`.
     * Requires the caller to own one of the entangled Nodes. Emits the calculated split values.
     * @param nodeId The ID of one of the entangled Nodes.
     */
    function splitStateOnBreak(uint256 nodeId) external isEntangled(nodeId) {
        uint256 nodeIdA = nodeId;
        uint256 nodeIdB = entangledPartner[nodeIdA];
        require(nodes[nodeIdA].owner == msg.sender || nodes[nodeIdB].owner == msg.sender, "QE: Must own one of the entangled nodes");

        // Example: Split the `pairedOperationCount` 50/50
        uint256 totalOps = nodes[nodeIdA].pairedOperationCount; // Assuming they are synchronized
        uint256 shareA = totalOps.div(2);
        uint256 shareB = totalOps.sub(shareA);

        // This function *demonstrates* the split values. It does *not* actually break entanglement
        // nor does it modify the pairedOperationCount (which should likely be reset or distributed internally).
        // If this were part of _breakEntanglement, you'd update node states here.

        emit StateSplitUponBreak(nodeIdA, nodeIdB, shareA, shareB);
    }

     /**
     * @dev Triggers a custom event (`PairedEventTriggered`) for both Nodes in an entangled pair.
     * Requires the caller to own one of the entangled Nodes.
     * @param nodeIdA The ID of one of the entangled Nodes.
     * @param message A string message to include in the event.
     */
    function triggerPairedEvent(uint256 nodeIdA, string calldata message) external isEntangled(nodeIdA) {
        uint256 nodeIdB = entangledPartner[nodeIdA];
        require(nodes[nodeIdA].owner == msg.sender || nodes[nodeIdB].owner == msg.sender, "QE: Must own one of the entangled nodes");

        emit PairedEventTriggered(nodeIdA, nodeIdB, message);

        nodes[nodeIdA].pairedOperationCount++;
        nodes[nodeIdB].pairedOperationCount++;
    }


    // --- External Influence ---

    /**
     * @dev Simulates the influence of an external oracle value on an entangled pair.
     * In a real system, this function would be called by a trusted oracle contract.
     * Example logic: Negative value flips state, positive value sets state to true.
     * Requires the caller to own one of the entangled Nodes to initiate the influence check.
     * @param nodeIdA The ID of one of the entangled Nodes.
     * @param oracleValue A simulated value from an external source.
     */
    function influenceEntanglementByOracle(uint256 nodeIdA, int256 oracleValue) external isEntangled(nodeIdA) {
         uint256 nodeIdB = entangledPartner[nodeIdA];
         require(nodes[nodeIdA].owner == msg.sender || nodes[nodeIdB].owner == msg.sender, "QE: Must own one of the entangled nodes to initiate oracle influence");

         // Example logic reacting to oracle value
         bool currentState = nodes[nodeIdA].isActive; // State is synchronized
         bool newState = currentState;

         if (oracleValue < 0 && currentState == true) {
             // Negative influence flips true to false
             newState = false;
             nodes[nodeIdA].isActive = newState;
             nodes[nodeIdB].isActive = newState;
              emit SynchronizedStateChange(nodeIdA, nodeIdB, newState);

         } else if (oracleValue > 0 && currentState == false) {
             // Positive influence flips false to true
             newState = true;
             nodes[nodeIdA].isActive = newState;
             nodes[nodeIdB].isActive = newState;
             emit SynchronizedStateChange(nodeIdA, nodeIdB, newState);
         }
         // If oracleValue is 0, or condition doesn't match, state is unchanged.

         emit OracleInfluenceApplied(nodeIdA, nodeIdB, oracleValue);
         // Not counting this as a 'paired operation' for the counter
    }


    // --- Queries & Status ---

    /**
     * @dev Gets the current entanglement status of a Node.
     * @param nodeId The ID of the Node to query.
     * @return The entanglement status (None, PendingRequest, Entangled).
     */
    function getEntanglementStatus(uint256 nodeId) public view returns (EntanglementStatus) {
        if (!nodeExists[nodeId]) {
            return EntanglementStatus.None;
        }
        if (entangledPartner[nodeId] != 0) {
            return EntanglementStatus.Entangled;
        }
        // Check if this node initiated a request OR is the target of a request
        if (pendingEntanglementRequests[nodeId] != 0 || isTargetOfPendingRequest[nodeId] != 0) {
             return EntanglementStatus.PendingRequest;
        }
        return EntanglementStatus.None;
    }

    /**
     * @dev Gets the Node ID of the entangled partner.
     * @param nodeId The ID of the Node to query.
     * @return The partner Node ID (0 if not entangled).
     */
    function getPartnerNode(uint256 nodeId) external view returns (uint256) {
         require(nodeExists[nodeId], "QE: Node does not exist");
         return entangledPartner[nodeId];
    }

    /**
     * @dev Gets the total combined internal balance of an entangled pair.
     * Requires the Node to be entangled.
     * @param nodeId The ID of one of the entangled Nodes.
     * @return The sum of the internal balances of the entangled pair.
     */
    function queryEntangledNetValue(uint256 nodeId) external view isEntangled(nodeId) returns (uint256) {
        uint256 partnerId = entangledPartner[nodeId];
        return nodeBalances[nodeId].add(nodeBalances[partnerId]);
    }

     /**
     * @dev Gets the count of entangled operations a Node has participated in.
     * @param nodeId The ID of the Node to query.
     * @return The paired operation count for the Node.
     */
     function getNodeOperationCount(uint256 nodeId) external view returns (uint256) {
        require(nodeExists[nodeId], "QE: Node does not exist");
        return nodes[nodeId].pairedOperationCount;
     }

    /**
     * @dev Gets the Node ID of the target node if this node (nodeId) has initiated a pending request.
     * @param nodeId The ID of the Node to query (the potential requester).
     * @return The Node ID of the request target (0 if no request initiated by this node).
     */
    function getPendingRequest(uint256 nodeId) external view returns (uint256 targetNodeId) {
         require(nodeExists[nodeId], "QE: Node does not exist");
         return pendingEntanglementRequests[nodeId];
    }

    /**
     * @dev Gets the Node ID of the requester node if this node (nodeId) is the target of a pending request.
     * @param nodeId The ID of the Node to query (the potential target).
     * @return The Node ID of the pending request's initiator (0 if not a target of a pending request).
     */
    function getPendingRequestTargeting(uint256 nodeId) external view returns (uint256 requesterNodeId) {
        require(nodeExists[nodeId], "QE: Node does not exist");
        return isTargetOfPendingRequest[nodeId];
    }
}
```