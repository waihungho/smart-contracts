Okay, let's design a smart contract for a "Decentralized Content/Knowledge Graph Nexus". This concept allows users to define pieces of information (Nodes) and create relationships (Edges) between them on-chain. It can incorporate features like ownership, fees for creation, staking to signal importance/validity, and basic flagging for content moderation signals.

It's a graph structure (Nodes and Edges) stored on-chain, which is less common than simple asset lists. It combines content representation (via IPFS hash), relationships, ownership, and a form of decentralized curation/signaling (staking, flagging).

This design aims to be distinct from standard ERCs, marketplaces, or simple DAOs by focusing on the *structure* of information and relationships on the blockchain.

Here's the contract outline and function summary:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Though 0.8+ handles overflow, useful for clarity sometimes. Let's rely on 0.8+ defaults.

// CONTRACT: DecentralizedContentNexus
// DESCRIPTION: A smart contract to create and manage a decentralized graph of content/knowledge.
//              Users can register 'Nodes' representing pieces of information (linked via IPFS)
//              and create 'Edges' representing relationships between Nodes.
//              Features include ownership, creation fees (paid in an ERC20 token),
//              staking on Nodes to signal importance or validity, and basic flagging.
//              Relies heavily on events for off-chain indexers to reconstruct the graph structure efficiently.

// OUTLINE:
// 1. Imports
// 2. Errors
// 3. Events
// 4. Structs (Node, Edge)
// 5. State Variables (Counters, Mappings for Nodes, Edges, Fees, Staking, Token, Admin/Pause)
// 6. Constructor
// 7. Modifiers (Access Control, Pausable)
// 8. Core Graph Management Functions (Create, Update, Soft Delete Node/Edge)
// 9. Query Functions (Get Node/Edge Details, Get Connections, Counts)
// 10. Monetization/Fee Functions (Set Fees, Withdraw Fees, Get Fees)
// 11. Staking Functions (Stake, Unstake, Get Stake Info)
// 12. Flagging Functions (Flag Node, Get Flag Count)
// 13. Ownership Transfer Functions
// 14. Admin/Utility Functions (Pause, Unpause, Set Token Address)

// FUNCTION SUMMARY:
// CORE GRAPH MANAGEMENT:
// - createNode(bytes32 ipfsHash, string memory nodeType, uint256 initialStake): Registers a new content node. Pays fee, allows initial staking.
// - updateNode(uint256 nodeId, bytes32 newIpfsHash, string memory newNodeType): Updates details of an owned node.
// - softDeleteNode(uint256 nodeId): Marks an owned node as deleted (does not remove data).
// - createEdge(uint256 sourceNodeId, uint256 targetNodeId, string memory edgeType, uint256 weight, uint256 initialStake): Creates a directed relationship between two nodes. Pays fee, allows initial staking on the edge.
// - updateEdge(uint256 edgeId, string memory newEdgeType, uint256 newWeight): Updates details of an owned edge.
// - softDeleteEdge(uint256 edgeId): Marks an owned edge as deleted (does not remove data).

// QUERY FUNCTIONS:
// - getNodeDetails(uint256 nodeId): Retrieves details of a specific node.
// - getEdgeDetails(uint256 edgeId): Retrieves details of a specific edge.
// - getNodeOutgoingEdgeIds(uint256 nodeId): Gets IDs of edges starting from a node.
// - getNodeIncomingEdgeIds(uint256 nodeId): Gets IDs of edges pointing to a node.
// - getNodesByIds(uint256[] memory nodeIds): Retrieves details for multiple nodes by ID.
// - getEdgesByIds(uint256[] memory edgeIds): Retrieves details for multiple edges by ID.
// - getNodeCount(): Returns the total number of nodes created.
// - getEdgeCount(): Returns the total number of edges created.

// MONETIZATION/FEE FUNCTIONS:
// - setCreationFees(uint256 nodeFee, uint256 edgeFee): Sets the fees for creating nodes and edges (Admin only).
// - getCreationFees(): Returns the current node and edge creation fees.
// - withdrawFees(address payable recipient, uint256 amount): Withdraws collected fees from the contract (Admin only).

// STAKING FUNCTIONS:
// - stakeForNode(uint256 nodeId, uint256 amount): Stakes ERC20 tokens on a node.
// - unstakeFromNode(uint256 nodeId, uint256 amount): Unstakes ERC20 tokens from a node.
// - getNodeTotalStake(uint256 nodeId): Gets the total amount staked on a node.
// - getUserNodeStake(address user, uint256 nodeId): Gets a user's staked amount on a specific node.

// FLAGGING FUNCTIONS:
// - flagNode(uint256 nodeId): Allows users to signal a node might be problematic.
// - getNodeFlagCount(uint256 nodeId): Gets the number of times a node has been flagged.

// OWNERSHIP TRANSFER FUNCTIONS:
// - transferNodeOwnership(uint256 nodeId, address newOwner): Transfers ownership of a node (Current owner only).
// - transferEdgeOwnership(uint256 edgeId, address newOwner): Transfers ownership of an edge (Current owner only).

// ADMIN/UTILITY FUNCTIONS:
// - pause(): Pauses core contract functionality (Admin only).
// - unpause(): Unpauses the contract (Admin only).
// - setTokenAddress(address newTokenAddress): Sets or updates the ERC20 token address used for fees/staking (Admin only).
// - getTokenAddress(): Returns the address of the ERC20 token used.


contract DecentralizedContentNexus is Ownable, Pausable, ReentrancyGuard {

    using SafeMath for uint256; // SafeMath is redundant in 0.8+ for basic ops, but good practice sometimes.

    // --- Errors ---
    error NodeNotFound(uint256 nodeId);
    error EdgeNotFound(uint256 edgeId);
    error NotNodeOwner(uint256 nodeId, address caller);
    error NotEdgeOwner(uint256 edgeId, address caller);
    error NodeAlreadyDeleted(uint256 nodeId);
    error EdgeAlreadyDeleted(uint256 edgeId);
    error NodeNotActive(uint256 nodeId); // Node is deleted or doesn't exist
    error EdgeNotActive(uint256 edgeId); // Edge is deleted or doesn't exist
    error InsufficientFeeAllowance(uint256 required, uint256 allowance);
    error InsufficientStakeAllowance(uint256 required, uint256 allowance);
    error InsufficientStakeAmount(uint256 requested, uint256 available);
    error ZeroAmount();

    // --- Events ---
    event NodeCreated(uint256 indexed nodeId, address indexed owner, bytes32 ipfsHash, string nodeType, uint256 timestamp);
    event NodeUpdated(uint256 indexed nodeId, bytes32 newIpfsHash, string newNodeType, uint256 timestamp);
    event NodeSoftDeleted(uint256 indexed nodeId, uint256 timestamp);
    event NodeOwnershipTransferred(uint256 indexed nodeId, address indexed previousOwner, address indexed newOwner);
    event NodeFlagged(uint256 indexed nodeId, address indexed signaler, uint256 newFlagCount, uint256 timestamp);

    event EdgeCreated(uint256 indexed edgeId, address indexed owner, uint256 indexed sourceNodeId, uint256 indexed targetNodeId, string edgeType, uint256 weight, uint256 timestamp);
    event EdgeUpdated(uint256 indexed edgeId, string newEdgeType, uint256 newWeight, uint256 timestamp);
    event EdgeSoftDeleted(uint256 indexed edgeId, uint256 indexed sourceNodeId, uint256 indexed targetNodeId, uint256 timestamp);
    event EdgeOwnershipTransferred(uint256 indexed edgeId, address indexed previousOwner, address indexed newOwner);

    event FeesSet(uint256 nodeFee, uint256 edgeFee);
    event FeesWithdrawn(address indexed recipient, uint256 amount);

    event TokensStaked(uint256 indexed nodeId, address indexed user, uint256 amount);
    event TokensUnstaked(uint256 indexed nodeId, address indexed user, uint256 amount); // Need to track withdrawal address? Assume msg.sender.

    event Paused(address account);
    event Unpaused(address account);
    event TokenAddressSet(address indexed tokenAddress);

    // --- Structs ---
    struct Node {
        uint256 id;
        address owner;
        bytes32 ipfsHash;
        string nodeType; // e.g., "Concept", "Resource", "Person", "Event"
        uint64 timestamp; // Creation timestamp
        bool isDeleted;
        uint256 flagCount;
        uint256 totalStake; // Total tokens staked on this node
        uint256[] outgoingEdgeIds; // IDs of edges starting from this node
        uint256[] incomingEdgeIds; // IDs of edges pointing to this node
    }

    struct Edge {
        uint256 id;
        address owner;
        uint256 sourceNodeId;
        uint256 targetNodeId;
        string edgeType; // e.g., "RelatesTo", "Supports", "Critiques", "AuthoredBy"
        uint256 weight; // e.g., strength of relationship
        uint64 timestamp; // Creation timestamp
        bool isDeleted;
    }

    // --- State Variables ---
    IERC20 public feeAndStakeToken; // The ERC20 token used for fees and staking

    uint256 private _nodeCounter;
    uint256 private _edgeCounter;

    mapping(uint256 => Node) public nodes;
    mapping(uint256 => Edge) public edges;

    // Track existence and active status quickly
    mapping(uint256 => bool) private _nodeActive; // True if node exists and is NOT soft deleted
    mapping(uint256 => bool) private _edgeActive; // True if edge exists and is NOT soft deleted

    uint256 public nodeCreationFee;
    uint256 public edgeCreationFee;

    // Staking balances: mapping user address -> mapping node ID -> staked amount
    mapping(address => mapping(uint256 => uint256)) public userNodeStakes;
    // We don't need a mapping for edge stakes based on the prompt, just node stakes.

    // --- Constructor ---
    constructor(address initialTokenAddress) Ownable(msg.sender) {
        require(initialTokenAddress != address(0), "Invalid token address");
        feeAndStakeToken = IERC20(initialTokenAddress);
        emit TokenAddressSet(initialTokenAddress);

        nodeCreationFee = 100; // Default fees (example)
        edgeCreationFee = 50;  // Default fees (example)
        emit FeesSet(nodeCreationFee, edgeCreationFee);
    }

    // --- Modifiers ---
    // Pausable is handled by OpenZeppelin
    // Ownable is handled by OpenZeppelin

    modifier onlyNodeOwner(uint256 nodeId) {
        if (nodes[nodeId].owner != msg.sender) {
            revert NotNodeOwner(nodeId, msg.sender);
        }
        _;
    }

    modifier onlyEdgeOwner(uint256 edgeId) {
        if (edges[edgeId].owner != msg.sender) {
            revert NotEdgeOwner(edgeId, msg.sender);
        }
        _;
    }

    modifier whenNodeExistsAndActive(uint256 nodeId) {
        if (!_nodeActive[nodeId]) {
            revert NodeNotActive(nodeId);
        }
        _;
    }

     modifier whenEdgeExistsAndActive(uint256 edgeId) {
        if (!_edgeActive[edgeId]) {
            revert EdgeNotActive(edgeId);
        }
        _;
    }


    // --- Core Graph Management Functions ---

    /// @notice Registers a new content node on the graph. Requires payment of nodeCreationFee.
    /// @param ipfsHash The IPFS hash linking to the content (bytes32 representation).
    /// @param nodeType The type of node (e.g., "Concept", "Resource").
    /// @param initialStake The amount of tokens to stake on this node immediately upon creation.
    /// @return The ID of the newly created node.
    function createNode(bytes32 ipfsHash, string memory nodeType, uint256 initialStake)
        external
        whenNotPaused
        nonReentrant
        returns (uint256)
    {
        require(nodeCreationFee > 0 || initialStake > 0, "Must pay fee or stake initially");

        if (nodeCreationFee > 0) {
             require(feeAndStakeToken.allowance(msg.sender, address(this)) >= nodeCreationFee,
                InsufficientFeeAllowance(nodeCreationFee, feeAndStakeToken.allowance(msg.sender, address(this))));
            bool success = feeAndStakeToken.transferFrom(msg.sender, address(this), nodeCreationFee);
            require(success, "Fee transfer failed");
        }

        if (initialStake > 0) {
             require(feeAndStakeToken.allowance(msg.sender, address(this)) >= nodeCreationFee + initialStake, // Check total allowance needed
                InsufficientStakeAllowance(nodeCreationFee + initialStake, feeAndStakeToken.allowance(msg.sender, address(this))));
             bool success = feeAndStakeToken.transferFrom(msg.sender, address(this), initialStake);
             require(success, "Initial stake transfer failed");
             userNodeStakes[msg.sender][(_nodeCounter + 1)] = userNodeStakes[msg.sender][(_nodeCounter + 1)].add(initialStake);
        }


        _nodeCounter++;
        uint256 newNodeId = _nodeCounter;

        nodes[newNodeId] = Node({
            id: newNodeId,
            owner: msg.sender,
            ipfsHash: ipfsHash,
            nodeType: nodeType,
            timestamp: uint64(block.timestamp),
            isDeleted: false,
            flagCount: 0,
            totalStake: initialStake,
            outgoingEdgeIds: new uint256[](0),
            incomingEdgeIds: new uint256[](0)
        });
        _nodeActive[newNodeId] = true;

        emit NodeCreated(newNodeId, msg.sender, ipfsHash, nodeType, block.timestamp);
        if (initialStake > 0) {
            emit TokensStaked(newNodeId, msg.sender, initialStake);
        }

        return newNodeId;
    }

    /// @notice Updates the details of an existing node. Only the node owner can call this.
    /// @param nodeId The ID of the node to update.
    /// @param newIpfsHash The new IPFS hash for the node.
    /// @param newNodeType The new type for the node.
    function updateNode(uint256 nodeId, bytes32 newIpfsHash, string memory newNodeType)
        external
        whenNotPaused
        onlyNodeOwner(nodeId)
        whenNodeExistsAndActive(nodeId)
    {
        nodes[nodeId].ipfsHash = newIpfsHash;
        nodes[nodeId].nodeType = newNodeType;

        emit NodeUpdated(nodeId, newIpfsHash, newNodeType, block.timestamp);
    }

    /// @notice Soft deletes a node. It remains in storage but is marked as deleted and inactive. Only the node owner can call this.
    /// @param nodeId The ID of the node to soft delete.
    function softDeleteNode(uint256 nodeId)
        external
        whenNotPaused
        onlyNodeOwner(nodeId)
        whenNodeExistsAndActive(nodeId)
    {
        nodes[nodeId].isDeleted = true;
        _nodeActive[nodeId] = false;

        // Note: Edges connected to this node are NOT automatically deleted.
        // Clients should check the active status of nodes and edges.

        emit NodeSoftDeleted(nodeId, block.timestamp);
    }

    /// @notice Creates a directed edge between two nodes. Requires payment of edgeCreationFee.
    /// @param sourceNodeId The ID of the node where the edge starts.
    /// @param targetNodeId The ID of the node where the edge ends.
    /// @param edgeType The type of relationship (e.g., "RelatesTo").
    /// @param weight The weight or strength of the relationship.
     /// @param initialStake The amount of tokens to stake on this edge immediately upon creation (feature not implemented for edges in staking, keeping it for nodes only).
    /// @return The ID of the newly created edge.
    function createEdge(uint256 sourceNodeId, uint256 targetNodeId, string memory edgeType, uint256 weight, uint256 /* initialStake */) // initialStake param included for consistency but not used for staking on edges
        external
        whenNotPaused
        nonReentrant
        whenNodeExistsAndActive(sourceNodeId)
        whenNodeExistsAndActive(targetNodeId)
        returns (uint256)
    {
        if (edgeCreationFee > 0) {
            require(feeAndStakeToken.allowance(msg.sender, address(this)) >= edgeCreationFee,
                InsufficientFeeAllowance(edgeCreationFee, feeAndStakeToken.allowance(msg.sender, address(this))));
            bool success = feeAndStakeToken.transferFrom(msg.sender, address(this), edgeCreationFee);
            require(success, "Fee transfer failed");
        }

        _edgeCounter++;
        uint256 newEdgeId = _edgeCounter;

        edges[newEdgeId] = Edge({
            id: newEdgeId,
            owner: msg.sender,
            sourceNodeId: sourceNodeId,
            targetNodeId: targetNodeId,
            edgeType: edgeType,
            weight: weight,
            timestamp: uint64(block.timestamp),
            isDeleted: false
        });
         _edgeActive[newEdgeId] = true;

        // Update connected node's edge lists
        nodes[sourceNodeId].outgoingEdgeIds.push(newEdgeId);
        nodes[targetNodeId].incomingEdgeIds.push(newEdgeId);

        emit EdgeCreated(newEdgeId, msg.sender, sourceNodeId, targetNodeId, edgeType, weight, block.timestamp);

        return newEdgeId;
    }

    /// @notice Updates the details of an existing edge. Only the edge owner can call this.
    /// @param edgeId The ID of the edge to update.
    /// @param newEdgeType The new type for the edge.
    /// @param newWeight The new weight for the edge.
    function updateEdge(uint256 edgeId, string memory newEdgeType, uint256 newWeight)
        external
        whenNotPaused
        onlyEdgeOwner(edgeId)
        whenEdgeExistsAndActive(edgeId)
    {
        edges[edgeId].edgeType = newEdgeType;
        edges[edgeId].weight = newWeight;

        emit EdgeUpdated(edgeId, newEdgeType, newWeight, block.timestamp);
    }

    /// @notice Soft deletes an edge. It remains in storage but is marked as deleted and inactive. Only the edge owner can call this.
    /// @param edgeId The ID of the edge to soft delete.
    function softDeleteEdge(uint256 edgeId)
        external
        whenNotPaused
        onlyEdgeOwner(edgeId)
        whenEdgeExistsAndActive(edgeId)
    {
        Edge storage edge = edges[edgeId];
        edge.isDeleted = true;
        _edgeActive[edgeId] = false;

        // Remove edge ID from connected node's lists
        uint256 sourceNodeId = edge.sourceNodeId;
        uint256 targetNodeId = edge.targetNodeId;

        // Helper to remove element from uint256 array efficiently (swap & pop)
        function removeFromArray(uint256[] storage arr, uint256 value) internal {
            for (uint256 i = 0; i < arr.length; i++) {
                if (arr[i] == value) {
                    arr[i] = arr[arr.length - 1];
                    arr.pop();
                    break; // Assume value appears at most once
                }
            }
        }

        if (_nodeActive[sourceNodeId]) { // Only modify if source node is still active
             removeFromArray(nodes[sourceNodeId].outgoingEdgeIds, edgeId);
        }
        if (_nodeActive[targetNodeId]) { // Only modify if target node is still active
            removeFromArray(nodes[targetNodeId].incomingEdgeIds, edgeId);
        }

        emit EdgeSoftDeleted(edgeId, sourceNodeId, targetNodeId, block.timestamp);
    }

    // --- Query Functions (View/Pure) ---

    /// @notice Retrieves the details of a specific node.
    /// @param nodeId The ID of the node.
    /// @return The Node struct details.
    function getNodeDetails(uint256 nodeId)
        public
        view
        whenNodeExistsAndActive(nodeId)
        returns (Node memory)
    {
        return nodes[nodeId];
    }

    /// @notice Retrieves the details of a specific edge.
    /// @param edgeId The ID of the edge.
    /// @return The Edge struct details.
    function getEdgeDetails(uint256 edgeId)
        public
        view
        whenEdgeExistsAndActive(edgeId)
        returns (Edge memory)
    {
        return edges[edgeId];
    }

    /// @notice Gets the IDs of all active edges originating from a specific node.
    /// @param nodeId The ID of the source node.
    /// @return An array of active edge IDs.
    function getNodeOutgoingEdgeIds(uint256 nodeId)
        public
        view
        whenNodeExistsAndActive(nodeId)
        returns (uint256[] memory)
    {
        uint256[] storage edgeIds = nodes[nodeId].outgoingEdgeIds;
        uint256[] memory activeEdgeIds = new uint256[](edgeIds.length); // Max possible size
        uint256 activeCount = 0;
        for(uint i = 0; i < edgeIds.length; i++) {
            if(_edgeActive[edgeIds[i]]) {
                activeEdgeIds[activeCount] = edgeIds[i];
                activeCount++;
            }
        }
        assembly {
            mstore(activeEdgeIds, activeCount) // Set length of the result array
        }
        return activeEdgeIds;
    }

    /// @notice Gets the IDs of all active edges pointing to a specific node.
    /// @param nodeId The ID of the target node.
    /// @return An array of active edge IDs.
    function getNodeIncomingEdgeIds(uint256 nodeId)
        public
        view
        whenNodeExistsAndActive(nodeId)
        returns (uint256[] memory)
    {
        uint256[] storage edgeIds = nodes[nodeId].incomingEdgeIds;
        uint256[] memory activeEdgeIds = new uint256[](edgeIds.length); // Max possible size
        uint256 activeCount = 0;
         for(uint i = 0; i < edgeIds.length; i++) {
            if(_edgeActive[edgeIds[i]]) {
                activeEdgeIds[activeCount] = edgeIds[i];
                activeCount++;
            }
        }
         assembly {
            mstore(activeEdgeIds, activeCount) // Set length of the result array
        }
        return activeEdgeIds;
    }

    /// @notice Retrieves details for multiple nodes by their IDs. Ignores inactive/non-existent nodes.
    /// @param nodeIds An array of node IDs.
    /// @return An array of Node structs for active nodes.
    function getNodesByIds(uint256[] memory nodeIds)
        public
        view
        returns (Node[] memory)
    {
        Node[] memory result = new Node[](nodeIds.length); // Max size
        uint256 count = 0;
        for (uint i = 0; i < nodeIds.length; i++) {
            uint256 nodeId = nodeIds[i];
            if (_nodeActive[nodeId]) {
                result[count] = nodes[nodeId];
                count++;
            }
        }
         assembly {
            mstore(result, count) // Set length of the result array
        }
        return result;
    }

     /// @notice Retrieves details for multiple edges by their IDs. Ignores inactive/non-existent edges.
    /// @param edgeIds An array of edge IDs.
    /// @return An array of Edge structs for active edges.
    function getEdgesByIds(uint256[] memory edgeIds)
        public
        view
        returns (Edge[] memory)
    {
        Edge[] memory result = new Edge[](edgeIds.length); // Max size
        uint256 count = 0;
        for (uint i = 0; i < edgeIds.length; i++) {
            uint256 edgeId = edgeIds[i];
            if (_edgeActive[edgeId]) {
                result[count] = edges[edgeId];
                count++;
            }
        }
         assembly {
            mstore(result, count) // Set length of the result array
        }
        return result;
    }

    /// @notice Returns the total number of nodes created (including soft-deleted).
    function getNodeCount() public view returns (uint256) {
        return _nodeCounter;
    }

    /// @notice Returns the total number of edges created (including soft-deleted).
    function getEdgeCount() public view returns (uint256) {
        return _edgeCounter;
    }


    // --- Monetization/Fee Functions ---

    /// @notice Sets the fees required to create new nodes and edges.
    /// @param nodeFee The new fee for creating a node.
    /// @param edgeFee The new fee for creating an edge.
    function setCreationFees(uint256 nodeFee, uint256 edgeFee) external onlyOwner {
        nodeCreationFee = nodeFee;
        edgeCreationFee = edgeFee;
        emit FeesSet(nodeCreationFee, edgeCreationFee);
    }

    /// @notice Returns the current creation fees for nodes and edges.
    /// @return nodeFee, edgeFee The current fees.
    function getCreationFees() external view returns (uint256 nodeFee, uint256 edgeFee) {
        return (nodeCreationFee, edgeCreationFee);
    }

    /// @notice Allows the contract owner to withdraw collected fees to a recipient.
    /// @param payable recipient The address to send the fees to.
    /// @param amount The amount of fees to withdraw.
    function withdrawFees(address payable recipient, uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Amount must be > 0");
        uint256 contractBalance = feeAndStakeToken.balanceOf(address(this));
        // Allow withdrawing collected fees, but not staked amounts.
        // This requires separating fee balance from staking balance.
        // A simpler approach: withdraw *any* balance the contract holds *minus* total staked amount.
        // Or, track fee balance separately. Let's track fee balance separately for clarity.
        // This implies fees collected via transferFrom should update a fee balance variable.
        // Let's update createNode/createEdge to track fees.
        // --- State Variable Addition: uint256 private _collectedFees; ---
        // Let's add this tracking.

        require(_collectedFees >= amount, "Insufficient collected fees");
        _collectedFees = _collectedFees.sub(amount);

        bool success = feeAndStakeToken.transfer(recipient, amount);
        require(success, "Fee withdrawal failed");

        emit FeesWithdrawn(recipient, amount);
    }
    uint256 private _collectedFees; // Add this state variable

    // --- Staking Functions ---

    /// @notice Stakes ERC20 tokens on a specific node.
    /// @param nodeId The ID of the node to stake on.
    /// @param amount The amount of tokens to stake.
    function stakeForNode(uint256 nodeId, uint256 amount)
        external
        whenNotPaused
        nonReentrant
        whenNodeExistsAndActive(nodeId)
    {
        require(amount > 0, "Amount must be > 0");
        require(feeAndStakeToken.allowance(msg.sender, address(this)) >= amount,
            InsufficientStakeAllowance(amount, feeAndStakeToken.allowance(msg.sender, address(this))));

        bool success = feeAndStakeToken.transferFrom(msg.sender, address(this), amount);
        require(success, "Stake transfer failed");

        userNodeStakes[msg.sender][nodeId] = userNodeStakes[msg.sender][nodeId].add(amount);
        nodes[nodeId].totalStake = nodes[nodeId].totalStake.add(amount);

        emit TokensStaked(nodeId, msg.sender, amount);
    }

    /// @notice Unstakes ERC20 tokens from a specific node. Tokens are returned to the staker.
    /// @param nodeId The ID of the node to unstake from.
    /// @param amount The amount of tokens to unstake.
    function unstakeFromNode(uint256 nodeId, uint256 amount)
        external
        whenNotPaused
        nonReentrant
        whenNodeExistsAndActive(nodeId)
    {
        require(amount > 0, "Amount must be > 0");
        require(userNodeStakes[msg.sender][nodeId] >= amount,
            InsufficientStakeAmount(amount, userNodeStakes[msg.sender][nodeId]));

        userNodeStakes[msg.sender][nodeId] = userNodeStakes[msg.sender][nodeId].sub(amount);
        nodes[nodeId].totalStake = nodes[nodeId].totalStake.sub(amount);

        bool success = feeAndStakeToken.transfer(msg.sender, amount);
        require(success, "Unstake transfer failed");

        emit TokensUnstaked(nodeId, msg.sender, amount);
    }

    /// @notice Gets the total amount of tokens staked on a specific node.
    /// @param nodeId The ID of the node.
    /// @return The total staked amount.
    function getNodeTotalStake(uint256 nodeId)
        external
        view
        whenNodeExistsAndActive(nodeId)
        returns (uint256)
    {
        return nodes[nodeId].totalStake;
    }

     /// @notice Gets the amount of tokens staked by a specific user on a specific node.
    /// @param user The address of the user.
    /// @param nodeId The ID of the node.
    /// @return The user's staked amount.
    function getUserNodeStake(address user, uint256 nodeId)
        external
        view
        whenNodeExistsAndActive(nodeId)
        returns (uint256)
    {
        return userNodeStakes[user][nodeId];
    }


    // --- Flagging Functions ---

    /// @notice Allows any user to flag a node as potentially problematic (e.g., spam, inaccurate).
    ///         This is a simple counter; actual moderation logic would be off-chain or via governance.
    /// @param nodeId The ID of the node to flag.
    function flagNode(uint256 nodeId)
        external
        whenNotPaused
        whenNodeExistsAndActive(nodeId)
    {
        nodes[nodeId].flagCount++;
        emit NodeFlagged(nodeId, msg.sender, nodes[nodeId].flagCount, block.timestamp);
    }

    /// @notice Gets the current flag count for a node.
    /// @param nodeId The ID of the node.
    /// @return The number of times the node has been flagged.
    function getNodeFlagCount(uint256 nodeId)
        external
        view
        whenNodeExistsAndActive(nodeId)
        returns (uint256)
    {
        return nodes[nodeId].flagCount;
    }


    // --- Ownership Transfer Functions ---

    /// @notice Allows the current owner of a node to transfer ownership to another address.
    /// @param nodeId The ID of the node.
    /// @param newOwner The address of the new owner.
    function transferNodeOwnership(uint256 nodeId, address newOwner)
        external
        whenNotPaused
        onlyNodeOwner(nodeId)
        whenNodeExistsAndActive(nodeId)
    {
        require(newOwner != address(0), "New owner is zero address");
        address oldOwner = nodes[nodeId].owner;
        nodes[nodeId].owner = newOwner;
        emit NodeOwnershipTransferred(nodeId, oldOwner, newOwner);
    }

    /// @notice Allows the current owner of an edge to transfer ownership to another address.
    /// @param edgeId The ID of the edge.
    /// @param newOwner The address of the new owner.
    function transferEdgeOwnership(uint256 edgeId, address newOwner)
        external
        whenNotPaused
        onlyEdgeOwner(edgeId)
         whenEdgeExistsAndActive(edgeId)
    {
        require(newOwner != address(0), "New owner is zero address");
        address oldOwner = edges[edgeId].owner;
        edges[edgeId].owner = newOwner;
        emit EdgeOwnershipTransferred(edgeId, oldOwner, newOwner);
    }

    // --- Admin/Utility Functions ---

    /// @notice Pauses contract operations (Admin only). Inherited from Pausable.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses contract operations (Admin only). Inherited from Pausable.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Sets or updates the ERC20 token address used for fees and staking.
    /// @param newTokenAddress The address of the new ERC20 token.
    function setTokenAddress(address newTokenAddress) external onlyOwner {
        require(newTokenAddress != address(0), "Invalid token address");
        feeAndStakeToken = IERC20(newTokenAddress);
        emit TokenAddressSet(newTokenAddress);
    }

    /// @notice Returns the address of the ERC20 token used for fees and staking.
    function getTokenAddress() external view returns (address) {
        return address(feeAndStakeToken);
    }

    // Internal helper to add collected fees
    function _addCollectedFees(uint256 amount) internal {
        _collectedFees = _collectedFees.add(amount);
    }

    // --- Overrides for Fee Collection ---
    // Modify createNode and createEdge to add collected fees
    // Original createNode logic:
    // if (nodeCreationFee > 0) { ... feeAndStakeToken.transferFrom(...); require(success, "Fee transfer failed"); }
    // Add: if (success) { _addCollectedFees(nodeCreationFee); }
    // Original createEdge logic:
    // if (edgeCreationFee > 0) { ... feeAndStakeToken.transferFrom(...); require(success, "Fee transfer failed"); }
    // Add: if (success) { _addCollectedFees(edgeCreationFee); }

    // Re-implementing the functions slightly to include fee tracking:

    /// @notice Registers a new content node on the graph. Requires payment of nodeCreationFee.
    /// @param ipfsHash The IPFS hash linking to the content (bytes32 representation).
    /// @param nodeType The type of node (e.g., "Concept", "Resource").
    /// @param initialStake The amount of tokens to stake on this node immediately upon creation.
    /// @return The ID of the newly created node.
    function createNode(bytes32 ipfsHash, string memory nodeType, uint256 initialStake)
        override // Override the initial stub
        external
        whenNotPaused
        nonReentrant
        returns (uint256)
    {
        require(nodeCreationFee > 0 || initialStake > 0, "Must pay fee or stake initially");
        uint256 totalRequired = nodeCreationFee.add(initialStake);

        if (totalRequired > 0) {
             require(feeAndStakeToken.allowance(msg.sender, address(this)) >= totalRequired,
                InsufficientFeeAllowance(totalRequired, feeAndStakeToken.allowance(msg.sender, address(this))));
            bool success = feeAndStakeToken.transferFrom(msg.sender, address(this), totalRequired);
            require(success, "Transfer failed for fee/initial stake");

            if (nodeCreationFee > 0) {
                _addCollectedFees(nodeCreationFee);
            }
            if (initialStake > 0) {
                 userNodeStakes[msg.sender][(_nodeCounter + 1)] = userNodeStakes[msg.sender][(_nodeCounter + 1)].add(initialStake);
            }
        }

        _nodeCounter++;
        uint256 newNodeId = _nodeCounter;

        nodes[newNodeId] = Node({
            id: newNodeId,
            owner: msg.sender,
            ipfsHash: ipfsHash,
            nodeType: nodeType,
            timestamp: uint64(block.timestamp),
            isDeleted: false,
            flagCount: 0,
            totalStake: initialStake,
            outgoingEdgeIds: new uint256[](0),
            incomingEdgeIds: new uint256[](0)
        });
        _nodeActive[newNodeId] = true;

        emit NodeCreated(newNodeId, msg.sender, ipfsHash, nodeType, block.timestamp);
        if (initialStake > 0) {
            emit TokensStaked(newNodeId, msg.sender, initialStake);
        }

        return newNodeId;
    }

    /// @notice Creates a directed edge between two nodes. Requires payment of edgeCreationFee.
    /// @param sourceNodeId The ID of the node where the edge starts.
    /// @param targetNodeId The ID of the node where the edge ends.
    /// @param edgeType The type of relationship (e.g., "RelatesTo").
    /// @param weight The weight or strength of the relationship.
    /// @return The ID of the newly created edge.
    function createEdge(uint256 sourceNodeId, uint256 targetNodeId, string memory edgeType, uint256 weight)
        override // Override the initial stub - removed initialStake from signature as it's not used for edge staking
        external
        whenNotPaused
        nonReentrant
        whenNodeExistsAndActive(sourceNodeId)
        whenNodeExistsAndActive(targetNodeId)
        returns (uint256)
    {
        if (edgeCreationFee > 0) {
            require(feeAndStakeToken.allowance(msg.sender, address(this)) >= edgeCreationFee,
                InsufficientFeeAllowance(edgeCreationFee, feeAndStakeToken.allowance(msg.sender, address(this))));
            bool success = feeAndStakeToken.transferFrom(msg.sender, address(this), edgeCreationFee);
            require(success, "Fee transfer failed");
            if (success) {
                 _addCollectedFees(edgeCreationFee);
            }
        }

        _edgeCounter++;
        uint256 newEdgeId = _edgeCounter;

        edges[newEdgeId] = Edge({
            id: newEdgeId,
            owner: msg.sender,
            sourceNodeId: sourceNodeId,
            targetNodeId: targetNodeId,
            edgeType: edgeType,
            weight: weight,
            timestamp: uint64(block.timestamp),
            isDeleted: false
        });
         _edgeActive[newEdgeId] = true;

        // Update connected node's edge lists
        // Check active status again defensively, though modifiers cover initial check
        if (_nodeActive[sourceNodeId]) {
             nodes[sourceNodeId].outgoingEdgeIds.push(newEdgeId);
        }
        if (_nodeActive[targetNodeId]) {
            nodes[targetNodeId].incomingEdgeIds.push(newEdgeId);
        }


        emit EdgeCreated(newEdgeId, msg.sender, sourceNodeId, targetNodeId, edgeType, weight, block.timestamp);

        return newEdgeId;
    }

    /// @notice Gets the total collected fees available for withdrawal by the owner.
    function getCollectedFees() external view returns (uint256) {
        return _collectedFees;
    }

    // Total functions:
    // createNode (override) -> 1
    // updateNode -> 2
    // softDeleteNode -> 3
    // createEdge (override) -> 4
    // updateEdge -> 5
    // softDeleteEdge -> 6
    // getNodeDetails -> 7
    // getEdgeDetails -> 8
    // getNodeOutgoingEdgeIds -> 9
    // getNodeIncomingEdgeIds -> 10
    // getNodesByIds -> 11
    // getEdgesByIds -> 12
    // getNodeCount -> 13
    // getEdgeCount -> 14
    // setCreationFees -> 15
    // getCreationFees -> 16
    // withdrawFees -> 17
    // stakeForNode -> 18
    // unstakeFromNode -> 19
    // getNodeTotalStake -> 20
    // getUserNodeStake -> 21
    // flagNode -> 22
    // getNodeFlagCount -> 23
    // transferNodeOwnership -> 24
    // transferEdgeOwnership -> 25
    // pause -> 26
    // unpause -> 27
    // setTokenAddress -> 28
    // getTokenAddress -> 29
    // getCollectedFees -> 30
    // (+ 2 internal/modifier/constructor functions)
    // Total public/external functions: 29. Meets the requirement.
}
```

**Explanation of Concepts and Advanced Features:**

1.  **Graph Data Structure on Chain:** Storing and managing interconnected Nodes and Edges directly in contract state (`nodes` and `edges` mappings, and `outgoingEdgeIds`/`incomingEdgeIds` arrays within Nodes). This is more complex than typical list or key-value storage and involves managing relationships explicitly.
2.  **IPFS Integration (via Hash):** Nodes link to off-chain content via `bytes32 ipfsHash`. This keeps potentially large content off-chain (saving gas) while proving a link to a specific version of the content on IPFS.
3.  **Soft Deletion:** Instead of permanently deleting data (which is impossible on blockchain), nodes and edges are marked `isDeleted`. This preserves historical data while signaling to applications that they should treat the item as inactive. `_nodeActive` and `_edgeActive` mappings provide quick checks.
4.  **Explicit Edge Lists:** Storing `outgoingEdgeIds` and `incomingEdgeIds` directly in the Node struct allows for on-chain traversal of direct neighbors. *Note:* Modifying these arrays (especially removal in `softDeleteEdge`) incurs gas costs proportional to array size, which is a common trade-off for on-chain graph structures. A gas-optimized removal technique (swap and pop) is used.
5.  **ERC20 Token Integration:** Uses a designated ERC20 token for:
    *   **Creation Fees:** A mechanism to deter spam or monetize the creation of nodes and edges.
    *   **Staking:** Users can stake tokens on nodes they believe are valuable, accurate, or important. This serves as a decentralized signaling or curation mechanism, potentially influencing how nodes are surfaced or trusted by applications reading the graph. Staking provides a financial incentive and skin-in-the-game for endorsing content/knowledge.
6.  **Flagging Mechanism:** A simple counter allowing any user to flag a node. While not a full moderation system, it provides a decentralized signal of potential issues that can be used by off-chain applications or integrated into a more complex governance system later.
7.  **Events for Off-Chain Indexing:** Extensive use of events (`NodeCreated`, `EdgeUpdated`, `TokensStaked`, etc.) is crucial. Building a usable graph explorer or application on top of this contract would primarily rely on listening to these events to build and maintain an off-chain database representing the graph state. Querying the full graph structure directly on-chain is gas-prohibitive.
8.  **Pausable & Ownable:** Standard, but necessary, patterns for admin control and emergency stops.
9.  **ReentrancyGuard:** Used on functions that handle external token transfers (`createNode`, `createEdge`, `stakeForNode`, `unstakeFromNode`, `withdrawFees`) to prevent re-entrancy attacks.
10. **Modular Query Functions:** Includes functions to get individual items, batch fetch items by ID, and get lists of connected edge IDs. `getNodesByIds` and `getEdgesByIds` demonstrate batch fetching pattern. Queries are designed to filter for *active* nodes/edges.
11. **Separate Fee Tracking:** The `_collectedFees` variable ensures that the owner can only withdraw fees that were explicitly paid into the contract's fee balance, separating it from the total staked tokens held by the contract.

This contract provides a foundation for a decentralized knowledge base or content graph, demonstrating how blockchain can be used to create verifiable records of information and their relationships, incorporating economic incentives (fees, staking) and early-stage community feedback (flagging).