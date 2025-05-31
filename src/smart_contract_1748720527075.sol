Okay, let's design a complex, creative, and non-standard smart contract.

**Concept:** **"Symbiotic Digital Art Network (SDAN)"**

This contract manages unique, non-transferable (soulbound-like) digital assets called "Symbiotic Nodes". These Nodes don't just exist; they can be staked in "Evolution Pools" to earn "Resonance Points". Resonance Points are then used to "evolve" the Node, changing its on-chain attributes and potentially its visual representation (off-chain metadata). Nodes can also be merged, burned, or delegated. This creates a dynamic, interactive ecosystem centered around evolving digital entities linked to specific addresses.

**Key Advanced/Creative Concepts:**

1.  **Non-Transferable, Mutable Assets:** Not a standard ERC-721. Assets are tied to an address but can change properties.
2.  **Staking for Resource Generation:** Nodes staked in pools generate an internal resource (Resonance).
3.  **On-Chain Resource Management:** Resonance points are accrued and spent within the contract for specific actions (evolution).
4.  **Dynamic On-Chain Attributes:** Node properties change based on user actions (evolution).
5.  **Evolution Pools:** Collaborative or competitive environments affecting resource generation and potential evolution paths.
6.  **Node Merging/Burning:** Mechanics for asset destruction or combination, potentially transferring attributes or history.
7.  **Delegated Interaction:** Owners can delegate control over Node actions (staking, evolution) to another address.
8.  **Internal State Machine:** Nodes progress through evolution stages.
9.  **Admin-Controlled Dynamic Events:** Catalysts can be triggered in pools to alter mechanics.

**Outline and Function Summary:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC165/ERC165.sol"; // For interface support (can be omitted if not needed elsewhere)

/**
 * @title SymbioticDigitalArtNetwork (SDAN)
 * @dev A contract managing mutable, non-transferable digital assets (Symbiotic Nodes)
 *      that evolve through staking in pools and spending generated Resonance Points.
 */
contract SymbioticDigitalArtNetwork is Ownable, ReentrancyGuard, ERC165 {

    // --- Contract State ---
    uint256 public nextNodeId = 1;
    uint256 public nextPoolId = 1;
    bool public paused = false;

    // --- Data Structures ---

    struct SymbioticNode {
        uint256 id;
        address owner;
        uint256 creationTime;
        uint256 level; // Evolution level/stage
        mapping(uint256 => uint256) attributes; // Dynamic key-value attributes (e.g., color: 100, energy: 50)
        uint256 resonancePoints; // Points accumulated/available for this node
        uint256 stakedPoolId; // 0 if not staked, otherwise pool ID
        uint256 stakeStartTime; // Timestamp when staked
        address delegate; // Address allowed to perform actions on behalf of the owner
    }

    struct EvolutionPool {
        uint256 id;
        address creator; // Could be owner or specific role
        bool active;
        mapping(uint256 => uint256) parameters; // Pool-specific parameters (e.g., resonance rate: 10, attribute bonus: 5)
        uint256 totalResonanceDistributed; // Stats
        uint256[] stakedNodes; // List of node IDs currently staked in this pool
        mapping(uint256 => bool) isNodeStakedInPool; // Helper for quicker lookup
    }

    mapping(uint256 => SymbioticNode) public nodes; // Node ID to Node struct
    mapping(address => uint256[]) public ownerNodes; // Owner address to list of owned node IDs
    mapping(uint256 => EvolutionPool) public evolutionPools; // Pool ID to Pool struct
    mapping(address => address) public nodeDelegates; // Node owner => delegate address (Alternative: delegate stored per node) - Let's use per node.

    // --- Events ---
    event NodeMinted(uint256 indexed nodeId, address indexed owner, uint256 creationTime);
    event NodeAttributesUpdated(uint256 indexed nodeId, uint256 attributeKey, uint256 newValue);
    event NodeLeveledUp(uint256 indexed nodeId, uint256 newLevel);
    event ResonanceEarned(uint256 indexed nodeId, uint256 earnedPoints);
    event ResonanceSpent(uint256 indexed nodeId, uint256 spentPoints);
    event NodeStaked(uint256 indexed nodeId, uint256 indexed poolId, uint256 stakeTime);
    event NodeUnstaked(uint256 indexed nodeId, uint256 indexed poolId, uint256 unstakeTime);
    event NodeMerged(uint256 indexed newNodeId, uint256 indexed mergedNodeId1, uint256 indexed mergedNodeId2);
    event NodeBurned(uint256 indexed nodeId, address indexed owner);
    event PoolCreated(uint256 indexed poolId, address indexed creator);
    event PoolParametersUpdated(uint256 indexed poolId);
    event PoolCatalystTriggered(uint256 indexed poolId, uint256 indexed catalystType, uint256 value);
    event DelegateSet(uint256 indexed nodeId, address indexed delegate);
    event DelegateRemoved(uint256 indexed nodeId);
    event ContractPaused(address indexed account);
    event ContractUnpaused(address indexed account);


    // --- Function Summaries ---

    // --- Admin & Setup (5 functions) ---
    /// @notice Pauses contract functionality. Only callable by owner.
    function pause() external onlyOwner;
    /// @notice Unpauses contract functionality. Only callable by owner.
    function unpause() external onlyOwner;
    /// @notice Sets initial attributes for newly minted nodes. Only callable by owner.
    /// @param initialAttributes Array of key-value pairs (attributeKey, attributeValue).
    function setInitialNodeAttributes(uint256[] calldata initialAttributes) external onlyOwner;
    /// @notice Creates a new Evolution Pool. Only callable by owner.
    /// @param parameters Array of key-value pairs (parameterKey, parameterValue) for the pool.
    function createEvolutionPool(uint256[] calldata parameters) external onlyOwner returns (uint256 poolId);
    /// @notice Updates parameters for an existing Evolution Pool. Only callable by owner.
    /// @param poolId The ID of the pool to update.
    /// @param newParameters Array of key-value pairs (parameterKey, parameterValue) to update.
    function updatePoolParameters(uint256 poolId, uint256[] calldata newParameters) external onlyOwner;

    // --- Node Lifecycle (8 functions) ---
    /// @notice Mints a new Symbiotic Node for the caller. Can have cost or requirements.
    /// @return nodeId The ID of the newly minted node.
    function mintNode() external nonReentrant returns (uint256 nodeId);
    /// @notice Allows the owner or delegate to evolve a node, spending Resonance Points.
    /// @param nodeId The ID of the node to evolve.
    /// @param evolutionType Specific evolution path or attribute focus (e.g., 1 for Growth, 2 for Mutation).
    function evolveNode(uint256 nodeId, uint256 evolutionType) external nonReentrant;
    /// @notice Allows the owner to burn (destroy) one of their nodes.
    /// @param nodeId The ID of the node to burn.
    function burnNode(uint256 nodeId) external nonReentrant;
    /// @notice Allows the owner to merge two of their nodes into a single new or existing node.
    /// @param nodeId1 The ID of the first node.
    /// @param nodeId2 The ID of the second node.
    /// @dev Implement specific merge logic: combine attributes, burn originals, create new node or modify one of the inputs. This implementation modifies nodeId1 and burns nodeId2.
    function mergeNodes(uint256 nodeId1, uint256 nodeId2) external nonReentrant;
    /// @notice Sets or updates a delegate address allowed to perform actions for a specific node.
    /// @param nodeId The ID of the node.
    /// @param delegateAddress The address to set as delegate (address(0) to remove).
    function setNodeDelegate(uint256 nodeId, address delegateAddress) external nonReentrant;
    /// @notice Gets the delegate address for a specific node.
    /// @param nodeId The ID of the node.
    /// @return The delegate address.
    function getNodeDelegate(uint256 nodeId) external view returns (address);
    /// @notice Checks if an address is authorized to perform actions on a node (owner or delegate).
    /// @param nodeId The ID of the node.
    /// @param account The address to check.
    /// @return True if authorized, false otherwise.
    function isAuthorized(uint256 nodeId, address account) public view returns (bool);
     /// @notice Internal helper to calculate and distribute earned resonance when a node state changes (unstake, claim).
     /// @param nodeId The ID of the node.
     function _distributeResonance(uint256 nodeId) internal;

    // --- Evolution Pool Interaction (6 functions) ---
    /// @notice Allows an authorized address to stake a node into an Evolution Pool.
    /// @param nodeId The ID of the node to stake.
    /// @param poolId The ID of the pool to stake into.
    function stakeNode(uint256 nodeId, uint256 poolId) external nonReentrant;
    /// @notice Allows an authorized address to unstake a node from its Evolution Pool.
    /// @param nodeId The ID of the node to unstake.
    function unstakeNode(uint256 nodeId) external nonReentrant;
    /// @notice Allows an authorized address to trigger resonance distribution for a staked node without unstaking.
    /// @param nodeId The ID of the node.
    function claimResonance(uint256 nodeId) external nonReentrant;
    /// @notice Allows the owner to trigger a pool-specific catalyst event affecting all staked nodes.
    /// @param poolId The ID of the pool.
    /// @param catalystType The type of catalyst (defines effect).
    /// @param value A value associated with the catalyst.
    function triggerPoolCatalyst(uint256 poolId, uint256 catalystType, uint256 value) external onlyOwner nonReentrant;
    /// @notice Gets the ID of the pool a node is currently staked in.
    /// @param nodeId The ID of the node.
    /// @return The pool ID (0 if not staked).
    function getNodeStakedPoolId(uint256 nodeId) external view returns (uint256);
    /// @notice Gets the list of node IDs currently staked in a pool.
    /// @param poolId The ID of the pool.
    /// @return An array of staked node IDs.
    function getPoolStakedNodes(uint256 poolId) external view returns (uint256[] memory);


    // --- View Functions (7 functions) ---
    /// @notice Gets the full details of a Symbiotic Node.
    /// @param nodeId The ID of the node.
    /// @return The SymbioticNode struct data.
    function getNodeDetails(uint256 nodeId) external view returns (SymbioticNode memory); // Note: Cannot return mapping from struct directly in memory
    /// @notice Gets a specific attribute value for a node.
    /// @param nodeId The ID of the node.
    /// @param attributeKey The key of the attribute.
    /// @return The value of the attribute.
    function getNodeAttribute(uint256 nodeId, uint256 attributeKey) external view returns (uint256);
    /// @notice Gets the Resonance Points balance for a node.
    /// @param nodeId The ID of the node.
    /// @return The current resonance points.
    function getNodeResonancePoints(uint256 nodeId) external view returns (uint256);
    /// @notice Gets the full details of an Evolution Pool.
    /// @param poolId The ID of the pool.
    /// @return The EvolutionPool struct data (excluding stakedNodes mapping).
    function getPoolDetails(uint256 poolId) external view returns (EvolutionPool memory); // Note: Cannot return mapping/array from struct directly in memory
     /// @notice Gets a specific parameter value for a pool.
     /// @param poolId The ID of the pool.
     /// @param parameterKey The key of the parameter.
     /// @return The value of the parameter.
     function getPoolParameter(uint256 poolId, uint256 parameterKey) external view returns (uint256);
    /// @notice Gets the list of node IDs owned by an address.
    /// @param owner The address of the owner.
    /// @return An array of node IDs.
    function getUserNodes(address owner) external view returns (uint256[] memory);
    /// @notice Gets the current total number of nodes minted.
    /// @return The total node count.
    function getTotalNodes() external view returns (uint256);

    // Total Functions: 5 (Admin) + 8 (Node Lifecycle) + 6 (Pool Interaction) + 7 (Views) = 26 Functions.

    // --- Interface Support (Optional) ---
    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // Add any interfaces this contract *actually* implements beyond ERC165 if needed.
        // E.g., return interfaceId == type(IERCXXX).interfaceId || super.supportsInterface(interfaceId);
        return super.supportsInterface(interfaceId);
    }

    // --- Internal Logic (Not counted in function summary, but part of the code) ---
    // _checkAuthorization, _addNodeToOwner, _removeNodeFromOwner, _addNodeToPool, _removeNodeFromPool, _calculateResonanceEarned etc.
}
```

```solidity
// Full Smart Contract Code

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol"; // For _msgSender()
import "@openzeppelin/contracts/utils/Arrays.sol"; // For array removal helper (if needed, or manual)
import "@openzeppelin/contracts/token/ERC165/ERC165.sol"; // Optional, for interface compliance if needed

/**
 * @title SymbioticDigitalArtNetwork (SDAN)
 * @dev A contract managing mutable, non-transferable digital assets (Symbiotic Nodes)
 *      that evolve through staking in pools and spending generated Resonance Points.
 *      Features include staking, resource accumulation, dynamic attributes,
 *      node merging/burning, delegation, and admin-controlled pool events.
 */
contract SymbioticDigitalArtNetwork is Ownable, ReentrancyGuard, ERC165 {

    // --- Contract State ---
    uint256 public nextNodeId = 1;
    uint256 public nextPoolId = 1;
    bool public paused = false;

    // --- Data Structures ---

    struct SymbioticNode {
        uint256 id;
        address owner;
        uint256 creationTime;
        uint256 level; // Evolution level/stage
        // We use mappings for dynamic attributes. Direct mapping access in storage struct is fine.
        mapping(uint256 => uint256) attributes; // Dynamic key-value attributes (e.g., color: 100, energy: 50)
        uint256 resonancePoints; // Points accumulated/available for this node
        uint256 stakedPoolId; // 0 if not staked, otherwise pool ID
        uint256 stakeStartTime; // Timestamp when staked
        address delegate; // Address allowed to perform actions on behalf of the owner
        uint256 lastResonanceCalculationTime; // Timestamp of the last resonance calculation
    }

    struct EvolutionPool {
        uint256 id;
        address creator; // Could be owner or specific role
        bool active;
        // Mappings for dynamic parameters.
        mapping(uint256 => uint256) parameters; // Pool-specific parameters (e.g., resonance_rate_per_sec: 10, attribute_bonus_key: 5)
        uint256 totalResonanceDistributed; // Stats
        uint256[] stakedNodes; // List of node IDs currently staked in this pool
        mapping(uint256 => uint256) stakedNodeIndex; // Helper: Node ID => index in stakedNodes array (-1 means not in array)
    }

    mapping(uint256 => SymbioticNode) public nodes; // Node ID to Node struct
    mapping(address => uint256[]) private _ownerNodes; // Owner address to list of owned node IDs
    mapping(uint256 => EvolutionPool) public evolutionPools; // Pool ID to Pool struct

    // Initial attributes applied to new nodes. Stored as a packed array [key1, value1, key2, value2...]
    uint256[] private _initialNodeAttributes;

    // --- Events ---
    event NodeMinted(uint256 indexed nodeId, address indexed owner, uint256 creationTime);
    event NodeAttributesUpdated(uint256 indexed nodeId, uint256 attributeKey, uint256 newValue);
    event NodeLeveledUp(uint256 indexed nodeId, uint256 newLevel);
    event ResonanceEarned(uint256 indexed nodeId, uint256 earnedPoints);
    event ResonanceSpent(uint256 indexed nodeId, uint256 spentPoints);
    event NodeStaked(uint256 indexed nodeId, uint256 indexed poolId, uint256 stakeTime);
    event NodeUnstaked(uint256 indexed nodeId, uint256 indexed poolId, uint256 unstakeTime);
    event NodeMerged(uint256 indexed newNodeId, uint256 indexed mergedNodeId1, uint256 indexed mergedNodeId2); // newNodeId might be nodeId1
    event NodeBurned(uint256 indexed nodeId, address indexed owner);
    event PoolCreated(uint256 indexed poolId, address indexed creator);
    event PoolParametersUpdated(uint256 indexed poolId);
    event PoolCatalystTriggered(uint256 indexed poolId, uint256 indexed catalystType, uint256 value);
    event DelegateSet(uint256 indexed nodeId, address indexed delegate);
    event DelegateRemoved(uint256 indexed nodeId); // Delegate address will be address(0) in Node struct
    event ContractPaused(address indexed account);
    event ContractUnpaused(address indexed account);


    // --- Function Summaries ---

    // --- Admin & Setup (5 functions) ---
    /// @notice Pauses contract functionality. Only callable by owner.
    function pause() external onlyOwner {
        paused = true;
        emit ContractPaused(_msgSender());
    }

    /// @notice Unpauses contract functionality. Only callable by owner.
    function unpause() external onlyOwner {
        paused = false;
        emit ContractUnpaused(_msgSender());
    }

    /// @notice Sets initial attributes for newly minted nodes. Stored as key-value pairs in a packed array.
    /// @param initialAttributes Array of key-value pairs [key1, value1, key2, value2...]. Length must be even.
    function setInitialNodeAttributes(uint256[] calldata initialAttributes) external onlyOwner {
        require(initialAttributes.length % 2 == 0, "SDAN: Initial attributes must be key-value pairs");
        _initialNodeAttributes = initialAttributes;
    }

    /// @notice Creates a new Evolution Pool. Parameters are key-value pairs in a packed array.
    /// @param parameters Array of key-value pairs [key1, value1, key2, value2...] for the pool. Length must be even.
    /// @return The ID of the newly created pool.
    function createEvolutionPool(uint256[] calldata parameters) external onlyOwner returns (uint256 poolId) {
        require(!paused, "SDAN: Contract is paused");
        require(parameters.length % 2 == 0, "SDAN: Pool parameters must be key-value pairs");

        poolId = nextPoolId++;
        EvolutionPool storage pool = evolutionPools[poolId];
        pool.id = poolId;
        pool.creator = _msgSender();
        pool.active = true;

        for (uint i = 0; i < parameters.length; i += 2) {
            pool.parameters[parameters[i]] = parameters[i+1];
        }

        emit PoolCreated(poolId, _msgSender());
    }

    /// @notice Updates parameters for an existing Evolution Pool. Parameters are key-value pairs.
    /// @param poolId The ID of the pool to update.
    /// @param newParameters Array of key-value pairs [key1, value1, key2, value2...] to update. Length must be even.
    function updatePoolParameters(uint256 poolId, uint256[] calldata newParameters) external onlyOwner {
        require(!paused, "SDAN: Contract is paused");
        require(evolutionPools[poolId].active, "SDAN: Pool does not exist or is inactive");
        require(newParameters.length % 2 == 0, "SDAN: New parameters must be key-value pairs");

        EvolutionPool storage pool = evolutionPools[poolId];
         for (uint i = 0; i < newParameters.length; i += 2) {
            pool.parameters[newParameters[i]] = newParameters[i+1];
        }

        emit PoolParametersUpdated(poolId);
    }

    // --- Node Lifecycle (8 functions) ---
    /// @notice Mints a new Symbiotic Node for the caller. Can have cost or requirements.
    /// @return The ID of the newly minted node.
    function mintNode() external nonReentrant returns (uint256 nodeId) {
        require(!paused, "SDAN: Contract is paused");
        // Add checks here for minting cost, requirements, etc.
        // require(msg.value >= MINT_PRICE, "SDAN: Insufficient funds");

        nodeId = nextNodeId++;
        SymbioticNode storage newNode = nodes[nodeId];
        newNode.id = nodeId;
        newNode.owner = _msgSender();
        newNode.creationTime = block.timestamp;
        newNode.level = 1; // Starting level
        newNode.resonancePoints = 0;
        newNode.stakedPoolId = 0; // Not staked initially
        newNode.stakeStartTime = 0;
        newNode.delegate = address(0); // No delegate initially
        newNode.lastResonanceCalculationTime = block.timestamp; // Start time for resonance calculation

        // Apply initial attributes
        for (uint i = 0; i < _initialNodeAttributes.length; i += 2) {
            newNode.attributes[_initialNodeAttributes[i]] = _initialNodeAttributes[i+1];
        }

        _ownerNodes[_msgSender()].push(nodeId);

        emit NodeMinted(nodeId, _msgSender(), newNode.creationTime);
        // Consider sending msg.value to a treasury address if there's a mint price
    }

    /// @notice Allows the owner or delegate to evolve a node, spending Resonance Points.
    /// @param nodeId The ID of the node to evolve.
    /// @param evolutionType Specific evolution path or attribute focus (e.g., 1 for Growth, 2 for Mutation). Costs differ based on type.
    function evolveNode(uint256 nodeId, uint256 evolutionType) external nonReentrant {
        require(!paused, "SDAN: Contract is paused");
        SymbioticNode storage node = nodes[nodeId];
        require(node.owner != address(0), "SDAN: Node does not exist");
        require(isAuthorized(nodeId, _msgSender()), "SDAN: Caller is not authorized");
        require(node.stakedPoolId == 0, "SDAN: Cannot evolve staked node");
        // Check for evolution requirements (e.g., minimum level, specific attributes, time since last evolution)

        uint256 requiredResonance = _calculateEvolutionCost(node.level, evolutionType); // Internal logic for cost
        require(node.resonancePoints >= requiredResonance, "SDAN: Insufficient Resonance Points");

        // Consume resonance
        node.resonancePoints -= requiredResonance;
        emit ResonanceSpent(nodeId, requiredResonance);

        // Apply evolution effects (update attributes, potentially level up)
        _applyEvolution(node, evolutionType); // Internal logic for applying effects

        // Potentially increase level
        uint256 oldLevel = node.level;
        node.level = _calculateNewLevel(node); // Internal logic for new level
        if (node.level > oldLevel) {
            emit NodeLeveledUp(nodeId, node.level);
        }
         // Update the last calculation time after spending points
        node.lastResonanceCalculationTime = block.timestamp;

        // Emit attribute changes if any within _applyEvolution
    }

    /// @notice Allows the owner to burn (destroy) one of their nodes.
    /// @param nodeId The ID of the node to burn.
    function burnNode(uint256 nodeId) external nonReentrant {
        require(!paused, "SDAN: Contract is paused");
        SymbioticNode storage node = nodes[nodeId];
        require(node.owner != address(0), "SDAN: Node does not exist");
        require(node.owner == _msgSender(), "SDAN: Caller is not the owner");
        require(node.stakedPoolId == 0, "SDAN: Cannot burn staked node");

        address owner = node.owner;

        // Remove from owner's list
        _removeNodeFromOwner(owner, nodeId);

        // Delete node data (clears storage)
        delete nodes[nodeId];

        emit NodeBurned(nodeId, owner);
    }

    /// @notice Allows the owner to merge two of their nodes into a single new or existing node.
    /// @param nodeId1 The ID of the first node.
    /// @param nodeId2 The ID of the second node.
    /// @dev This implementation merges nodeId2 into nodeId1 and burns nodeId2. Requires specific merge logic.
    function mergeNodes(uint256 nodeId1, uint256 nodeId2) external nonReentrant {
        require(!paused, "SDAN: Contract is paused");
        require(nodeId1 != nodeId2, "SDAN: Cannot merge a node with itself");

        SymbioticNode storage node1 = nodes[nodeId1];
        SymbioticNode storage node2 = nodes[nodeId2];

        require(node1.owner != address(0) && node2.owner != address(0), "SDAN: One or both nodes do not exist");
        require(node1.owner == _msgSender() && node2.owner == _msgSender(), "SDAN: Caller is not the owner of both nodes");
        require(node1.stakedPoolId == 0 && node2.stakedPoolId == 0, "SDAN: Cannot merge staked nodes");

        // Perform merge logic (example: combine resonance, average/sum attributes, keep higher level)
        // Recalculate resonance before merging to include time staked before unstaking (if applicable)
        if(node1.stakedPoolId != 0) _distributeResonance(nodeId1); // Should be unstaked, but defensive
        if(node2.stakedPoolId != 0) _distributeResonance(nodeId2); // Should be unstaked, but defensive


        node1.resonancePoints += node2.resonancePoints; // Add resonance

        // Example attribute merge: Add node2 attributes to node1
        // NOTE: Iterating mappings in Solidity is not straightforward. A simple example:
        // In a real scenario, you'd likely have defined attributes and iterate keys.
        // For demonstration, let's just say we add a specific attribute.
        uint256 exampleAttributeKey = 1; // Assume 1 is an attribute key
        node1.attributes[exampleAttributeKey] += node2.attributes[exampleAttributeKey];
        emit NodeAttributesUpdated(nodeId1, exampleAttributeKey, node1.attributes[exampleAttributeKey]);

        node1.level = Math.max(node1.level, node2.level) + 1; // Example: Keep higher level, maybe add 1
        emit NodeLeveledUp(nodeId1, node1.level);


        // Burn the second node
        address owner = node2.owner;
        _removeNodeFromOwner(owner, nodeId2);
        delete nodes[nodeId2];
        emit NodeBurned(nodeId2, owner);

        emit NodeMerged(nodeId1, nodeId1, nodeId2); // Node1 is the resulting node
    }

    /// @notice Sets or updates a delegate address allowed to perform actions for a specific node.
    /// @param nodeId The ID of the node.
    /// @param delegateAddress The address to set as delegate (address(0) to remove).
    function setNodeDelegate(uint256 nodeId, address delegateAddress) external nonReentrant {
        require(!paused, "SDAN: Contract is paused");
        SymbioticNode storage node = nodes[nodeId];
        require(node.owner != address(0), "SDAN: Node does not exist");
        require(node.owner == _msgSender(), "SDAN: Caller is not the owner");

        node.delegate = delegateAddress;
        if (delegateAddress == address(0)) {
            emit DelegateRemoved(nodeId);
        } else {
            emit DelegateSet(nodeId, delegateAddress);
        }
    }

    /// @notice Gets the delegate address for a specific node.
    /// @param nodeId The ID of the node.
    /// @return The delegate address.
    function getNodeDelegate(uint256 nodeId) external view returns (address) {
        require(nodes[nodeId].owner != address(0), "SDAN: Node does not exist");
        return nodes[nodeId].delegate;
    }

     /// @notice Checks if an address is authorized to perform actions on a node (owner or delegate).
    /// @param nodeId The ID of the node.
    /// @param account The address to check.
    /// @return True if authorized, false otherwise.
    function isAuthorized(uint256 nodeId, address account) public view returns (bool) {
        SymbioticNode storage node = nodes[nodeId];
        if (node.owner == address(0)) return false; // Node doesn't exist
        return node.owner == account || node.delegate == account;
    }

     /// @notice Internal helper to calculate and distribute earned resonance when a node state changes (unstake, claim).
     /// @param nodeId The ID of the node.
     function _distributeResonance(uint256 nodeId) internal {
        SymbioticNode storage node = nodes[nodeId];
        if (node.stakedPoolId == 0 || !evolutionPools[node.stakedPoolId].active) {
            // If not staked or pool inactive, no resonance is currently being earned.
            // Still update last calc time to prevent retroactive earning if pool becomes active/node gets staked.
            node.lastResonanceCalculationTime = block.timestamp;
            return;
        }

        EvolutionPool storage pool = evolutionPools[node.stakedPoolId];
        uint256 resonanceRate = pool.parameters[1]; // Assume parameter key 1 is resonance rate per second
        if (resonanceRate == 0) {
             node.lastResonanceCalculationTime = block.timestamp;
             return; // Pool gives no resonance
        }

        uint256 duration = block.timestamp - node.lastResonanceCalculationTime;
        if (duration == 0) return; // No time has passed

        uint256 earned = duration * resonanceRate;

        node.resonancePoints += earned;
        pool.totalResonanceDistributed += earned;
        node.lastResonanceCalculationTime = block.timestamp; // Update timestamp

        emit ResonanceEarned(nodeId, earned);
     }


    // --- Evolution Pool Interaction (6 functions) ---
    /// @notice Allows an authorized address to stake a node into an Evolution Pool.
    /// @param nodeId The ID of the node to stake.
    /// @param poolId The ID of the pool to stake into.
    function stakeNode(uint256 nodeId, uint256 poolId) external nonReentrant {
        require(!paused, "SDAN: Contract is paused");
        SymbioticNode storage node = nodes[nodeId];
        require(node.owner != address(0), "SDAN: Node does not exist");
        require(isAuthorized(nodeId, _msgSender()), "SDAN: Caller is not authorized");
        require(node.stakedPoolId == 0, "SDAN: Node is already staked");

        EvolutionPool storage pool = evolutionPools[poolId];
        require(pool.active, "SDAN: Pool does not exist or is inactive");
        // Add pool-specific staking requirements here (e.g., node level, attributes)
        // require(_meetsStakingRequirements(node, pool), "SDAN: Node does not meet pool requirements");


        // Calculate any pending resonance before staking begins in a new pool
        _distributeResonance(nodeId); // This will update lastResonanceCalculationTime to now

        node.stakedPoolId = poolId;
        node.stakeStartTime = block.timestamp; // Record stake start time
        node.lastResonanceCalculationTime = block.timestamp; // Reset calculation time for the new stake period

        // Add node to pool's staked list and index
        pool.stakedNodeIndex[nodeId] = pool.stakedNodes.length;
        pool.stakedNodes.push(nodeId);
        pool.isNodeStakedInPool[nodeId] = true; // Helper mapping

        emit NodeStaked(nodeId, poolId, block.timestamp);
    }

    /// @notice Allows an authorized address to unstake a node from its Evolution Pool.
    /// @param nodeId The ID of the node to unstake.
    function unstakeNode(uint256 nodeId) external nonReentrant {
        require(!paused, "SDAN: Contract is paused");
        SymbioticNode storage node = nodes[nodeId];
        require(node.owner != address(0), "SDAN: Node does not exist");
        require(isAuthorized(nodeId, _msgSender()), "SDAN: Caller is not authorized");
        require(node.stakedPoolId != 0, "SDAN: Node is not staked");

        uint256 poolId = node.stakedPoolId;
        EvolutionPool storage pool = evolutionPools[poolId];

        // Distribute earned resonance points upon unstaking
        _distributeResonance(nodeId);

        // Remove node from pool's staked list and index
        uint256 index = pool.stakedNodeIndex[nodeId];
        uint224 lastIndex = uint224(pool.stakedNodes.length - 1);
        uint256 lastNodeId = pool.stakedNodes[lastIndex];

        if (index != lastIndex) {
            pool.stakedNodes[index] = lastNodeId;
            pool.stakedNodeIndex[lastNodeId] = index;
        }
        pool.stakedNodes.pop();
        delete pool.stakedNodeIndex[nodeId]; // Clean up index mapping
        delete pool.isNodeStakedInPool[nodeId];

        // Reset node staking state
        node.stakedPoolId = 0;
        node.stakeStartTime = 0;
        node.lastResonanceCalculationTime = block.timestamp; // Reset calculation time upon unstake

        emit NodeUnstaked(nodeId, poolId, block.timestamp);
    }

    /// @notice Allows an authorized address to trigger resonance distribution for a staked node without unstaking.
    /// @param nodeId The ID of the node.
    function claimResonance(uint256 nodeId) external nonReentrant {
        require(!paused, "SDAN: Contract is paused");
        SymbioticNode storage node = nodes[nodeId];
        require(node.owner != address(0), "SDAN: Node does not exist");
        require(isAuthorized(nodeId, _msgSender()), "SDAN: Caller is not authorized");
        require(node.stakedPoolId != 0, "SDAN: Node is not staked");
        require(evolutionPools[node.stakedPoolId].active, "SDAN: Node is staked in an inactive pool");

        // Distribute earned resonance points
        _distributeResonance(nodeId);
        // _distributeResonance already emits ResonanceEarned
    }

    /// @notice Allows the owner to trigger a pool-specific catalyst event affecting all staked nodes.
    /// @param poolId The ID of the pool.
    /// @param catalystType The type of catalyst (defines effect).
    /// @param value A value associated with the catalyst.
    function triggerPoolCatalyst(uint256 poolId, uint256 catalystType, uint256 value) external onlyOwner nonReentrant {
        require(!paused, "SDAN: Contract is paused");
        EvolutionPool storage pool = evolutionPools[poolId];
        require(pool.active, "SDAN: Pool does not exist or is inactive");

        // --- Implement catalyst logic here ---
        // This could affect resonance rates temporarily, grant bonus resonance,
        // change attribute gain/loss for staked nodes, trigger mini-evolution events, etc.
        // This example just emits an event.
        // Iterating through pool.stakedNodes and applying effects to each node is possible but can be gas-intensive.
        // Alternatively, effects can be stored in the pool and applied to nodes when they unstake or evolve.

        emit PoolCatalystTriggered(poolId, catalystType, value);
    }

    /// @notice Gets the ID of the pool a node is currently staked in.
    /// @param nodeId The ID of the node.
    /// @return The pool ID (0 if not staked).
    function getNodeStakedPoolId(uint256 nodeId) external view returns (uint256) {
         require(nodes[nodeId].owner != address(0), "SDAN: Node does not exist");
         return nodes[nodeId].stakedPoolId;
    }

    /// @notice Gets the list of node IDs currently staked in a pool.
    /// @param poolId The ID of the pool.
    /// @return An array of staked node IDs.
    function getPoolStakedNodes(uint256 poolId) external view returns (uint256[] memory) {
        require(evolutionPools[poolId].active, "SDAN: Pool does not exist or is inactive");
        return evolutionPools[poolId].stakedNodes;
    }


    // --- View Functions (7 functions) ---
    /// @notice Gets the static details of a Symbiotic Node (excludes dynamic mappings like attributes).
    /// @param nodeId The ID of the node.
    /// @return id, owner, creationTime, level, resonancePoints, stakedPoolId, stakeStartTime, delegate.
    function getNodeDetails(uint256 nodeId) external view returns (
        uint256 id,
        address owner,
        uint256 creationTime,
        uint256 level,
        uint256 resonancePoints,
        uint256 stakedPoolId,
        uint256 stakeStartTime,
        address delegate
    ) {
        SymbioticNode storage node = nodes[nodeId];
        require(node.owner != address(0), "SDAN: Node does not exist");
        // Note: Cannot directly return the struct with mappings in memory. Return individual fields.
        // To get attributes, use getNodeAttribute.
        return (
            node.id,
            node.owner,
            node.creationTime,
            node.level,
            node.resonancePoints,
            node.stakedPoolId,
            node.stakeStartTime,
            node.delegate
        );
    }

    /// @notice Gets a specific attribute value for a node.
    /// @param nodeId The ID of the node.
    /// @param attributeKey The key of the attribute.
    /// @return The value of the attribute. Returns 0 if attribute not set.
    function getNodeAttribute(uint256 nodeId, uint256 attributeKey) external view returns (uint256) {
         require(nodes[nodeId].owner != address(0), "SDAN: Node does not exist");
         return nodes[nodeId].attributes[attributeKey];
    }

    /// @notice Gets the Resonance Points balance for a node. Includes pending resonance if staked.
    /// @param nodeId The ID of the node.
    /// @return The current resonance points + any pending resonance.
    function getNodeResonancePoints(uint256 nodeId) external view returns (uint256) {
        SymbioticNode storage node = nodes[nodeId];
        require(node.owner != address(0), "SDAN: Node does not exist");

        uint256 currentResonance = node.resonancePoints;

        if (node.stakedPoolId != 0 && evolutionPools[node.stakedPoolId].active) {
            EvolutionPool storage pool = evolutionPools[node.stakedPoolId];
             uint256 resonanceRate = pool.parameters[1]; // Assume parameter key 1 is resonance rate per second
             if (resonanceRate > 0) {
                 uint256 duration = block.timestamp - node.lastResonanceCalculationTime;
                 currentResonance += duration * resonanceRate;
             }
        }
        return currentResonance;
    }

    /// @notice Gets the static details of an Evolution Pool (excludes dynamic mappings like parameters or stakedNodes).
    /// @param poolId The ID of the pool.
    /// @return id, creator, active, totalResonanceDistributed.
    function getPoolDetails(uint256 poolId) external view returns (
        uint256 id,
        address creator,
        bool active,
        uint256 totalResonanceDistributed
    ) {
        EvolutionPool storage pool = evolutionPools[poolId];
        require(pool.active, "SDAN: Pool does not exist or is inactive");
        // Note: Cannot directly return the struct with mappings/arrays in memory. Return individual fields.
        // To get parameters or staked nodes, use getPoolParameter or getPoolStakedNodes.
        return (
            pool.id,
            pool.creator,
            pool.active,
            pool.totalResonanceDistributed
        );
    }

     /// @notice Gets a specific parameter value for a pool.
     /// @param poolId The ID of the pool.
     /// @param parameterKey The key of the parameter.
     /// @return The value of the parameter. Returns 0 if parameter not set.
     function getPoolParameter(uint256 poolId, uint256 parameterKey) external view returns (uint256) {
        require(evolutionPools[poolId].active, "SDAN: Pool does not exist or is inactive");
        return evolutionPools[poolId].parameters[parameterKey];
     }

    /// @notice Gets the list of node IDs owned by an address.
    /// @param owner The address of the owner.
    /// @return An array of node IDs.
    function getUserNodes(address owner) external view returns (uint256[] memory) {
        return _ownerNodes[owner];
    }

    /// @notice Gets the current total number of nodes minted.
    /// @return The total node count.
    function getTotalNodes() external view returns (uint256) {
        return nextNodeId - 1; // Subtract 1 because nextNodeId is the ID for the *next* node
    }

    // Total Functions: 5 (Admin) + 8 (Node Lifecycle) + 6 (Pool Interaction) + 7 (Views) = 26 Functions.

    // --- Interface Support (Optional) ---
    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // Add any interfaces this contract *actually* implements beyond ERC165 if needed.
        // E.g., return interfaceId == type(IERCXXX).interfaceId || super.supportsInterface(interfaceId);
        // For this custom contract, we mostly just support ERC165 itself unless adding specific interfaces.
        return super.supportsInterface(interfaceId);
    }

    // --- Internal Logic ---
    // Helper to remove node from owner's dynamic array. Basic implementation, could be optimized.
    function _removeNodeFromOwner(address owner, uint256 nodeId) internal {
        uint256[] storage nodesList = _ownerNodes[owner];
        for (uint i = 0; i < nodesList.length; i++) {
            if (nodesList[i] == nodeId) {
                // Swap last element with the one to be removed
                nodesList[i] = nodesList[nodesList.length - 1];
                nodesList.pop(); // Remove the last element
                return;
            }
        }
        // Should not happen if node exists and is owned by this address, but good practice for robustness.
    }

    // Placeholder for evolution cost calculation logic
    function _calculateEvolutionCost(uint256 level, uint256 evolutionType) internal pure returns (uint256) {
        // Example: Cost increases with level, different types have different base costs
        if (evolutionType == 1) return level * 100; // Growth
        if (evolutionType == 2) return level * 150; // Mutation
        return level * 50; // Default/Other
    }

     // Placeholder for applying evolution effects
    function _applyEvolution(SymbioticNode storage node, uint256 evolutionType) internal {
        // Example: Modify attributes based on evolution type
        if (evolutionType == 1) {
            // Growth: Increase base attributes
            node.attributes[1] += 10; // Assume attribute 1 is 'size'
            node.attributes[2] += 5;  // Assume attribute 2 is 'structure'
             emit NodeAttributesUpdated(node.id, 1, node.attributes[1]);
             emit NodeAttributesUpdated(node.id, 2, node.attributes[2]);
        } else if (evolutionType == 2) {
            // Mutation: Randomly boost or change some attributes
            // For on-chain randomness, integrate Chainlink VRF or similar.
            // Simple example: Boost attribute 3
             node.attributes[3] += 20; // Assume attribute 3 is 'energy'
             emit NodeAttributesUpdated(node.id, 3, node.attributes[3]);
        }
        // Add more complex attribute interactions here
    }

    // Placeholder for calculating new level
    function _calculateNewLevel(SymbioticNode storage node) internal view returns (uint256) {
        // Example: Level up based on total resonance spent on evolution or reaching attribute thresholds
        // This example just increments level if total attribute value crosses a threshold based on current level
        uint256 totalAttributes = 0;
        // Note: Cannot iterate attributes mapping here. Need to know keys or store total separately.
        // Simple example: Hardcode check for one attribute key
        if (node.attributes[1] > node.level * 50) { // If attribute 1 exceeds level*50 threshold
             return node.level + 1;
        }
        return node.level; // No level up
    }

    // Placeholder for checking pool staking requirements (optional)
    // function _meetsStakingRequirements(SymbioticNode storage node, EvolutionPool storage pool) internal view returns (bool) {
    //     // Check pool.parameters against node.level or node.attributes
    //     // return node.level >= pool.parameters[2]; // Assume parameter key 2 is min_level
    //     return true; // No requirements for now
    // }

    // --- Math Library (Minimal) ---
    // Using OpenZeppelin's Math if needed, or a simple local implementation
    library Math {
        function max(uint256 a, uint256 b) internal pure returns (uint256) {
            return a >= b ? a : b;
        }
    }
}
```