Okay, let's design a smart contract for a Decentralized Knowledge Graph. This concept is interesting because it allows users to collaboratively build a structured dataset of entities and their relationships on-chain, validated through a community-driven process leveraging reputation.

It's more complex than simple token contracts or basic data storage. It involves multiple interconnected data structures (nodes, edges, proposals), access control, validation logic, and a basic reputation system.

**Core Concepts:**

*   **Nodes:** Represent entities (people, organizations, concepts, events, etc.). Each node has a type and associated data (likely a hash or URI pointing to off-chain content).
*   **Edges:** Represent relationships between two nodes. Each edge has a type (e.g., "knows", "employs", "isA", "relatedTo") and direction (source -> target).
*   **Types:** Node and Edge types are defined and managed within the contract, allowing a structured graph.
*   **Proposals:** Users propose adding new nodes or edges. These aren't immediately added to the graph.
*   **Validation:** Designated "Curators" (users with a specific role) review proposals and validate or challenge them.
*   **Reputation:** Curators and Proposers earn/lose reputation based on the outcome of the validation process, incentivizing truthful and accurate contributions.
*   **Access Control:** Different roles (Admin, Curator, User) have different permissions.

**Why it's Interesting/Advanced/Creative:**

*   **Structured Data On-Chain:** Moving beyond simple key-value stores to represent interconnected data.
*   **Community Curation:** Using on-chain roles and validation processes for data quality.
*   **Reputation System:** Integrating a basic on-chain mechanism to track and leverage user trustworthiness for data validation.
*   **Proposal Flow:** Data isn't added directly; it goes through a lifecycle.

---

**Outline and Function Summary**

**Contract Name:** `DecentralizedKnowledgeGraph`

**Purpose:** To create and manage a decentralized, community-curated knowledge graph consisting of nodes (entities) and edges (relationships), validated through a proposal and reputation system.

**Data Structures:**

*   `Role`: Enum { User, Curator, Admin } - User roles.
*   `ProposalStatus`: Enum { Pending, Approved, Rejected, Challenged } - Status of a data proposal.
*   `NodeType`: Struct { bytes32 name; bool isValid; } - Definition of a node type.
*   `EdgeType`: Struct { bytes32 name; bool isValid; } - Definition of an edge type.
*   `Node`: Struct { uint256 id; bytes32 nodeType; address creator; string dataURI; uint256 creationTime; } - Represents a node in the graph.
*   `Edge`: Struct { uint256 id; uint256 sourceNodeId; uint256 targetNodeId; bytes32 edgeType; address creator; string dataURI; uint256 creationTime; } - Represents an edge between two nodes.
*   `Proposal`: Struct { uint256 id; address proposer; bool isNodeProposal; // true for Node, false for Edge ProposalStatus status; uint256 validationCount; uint256 challengeCount; uint256 creationTime; bytes memory data; // ABI encoded Node or Edge struct data mapping(address => bool) hasValidated; mapping(address => bool) hasChallenged; } - Represents a proposal to add data.

**State Variables:**

*   `admin`: Address of the contract administrator.
*   `paused`: Boolean indicating if the contract is paused.
*   `nextNodeId`: Counter for unique node IDs.
*   `nextEdgeId`: Counter for unique edge IDs.
*   `nextProposalId`: Counter for unique proposal IDs.
*   `nodes`: Mapping from node ID to `Node` struct.
*   `edges`: Mapping from edge ID to `Edge` struct.
*   `nodeTypes`: Mapping from bytes32 type name to `NodeType` struct.
*   `edgeTypes`: Mapping from bytes32 type name to `EdgeType` struct.
*   `proposals`: Mapping from proposal ID to `Proposal` struct.
*   `userReputation`: Mapping from user address to their reputation score (uint256).
*   `userRoles`: Mapping from user address to their `Role`.
*   `nodeIdsByType`: Mapping from bytes32 node type to array of node IDs (cached for query).
*   `edgeIdsByType`: Mapping from bytes32 edge type to array of edge IDs (cached for query).
*   `edgeIdsBySourceNode`: Mapping from source node ID to array of edge IDs (cached for query).
*   `edgeIdsByTargetNode`: Mapping from target node ID to array of edge IDs (cached for query).
*   `pendingProposals`: Array of pending proposal IDs (for easier listing).
*   `validationThreshold`: Minimum `validationCount` for a proposal to potentially be approved (admin configurable).
*   `challengeThreshold`: Minimum `challengeCount` for a proposal to potentially be rejected (admin configurable).
*   `reputationGainPerValidation`: Reputation added for successful validation/proposal approval.
*   `reputationLossPerChallenge`: Reputation subtracted for successful challenge/proposal rejection.

**Events:**

*   `NodeAdded(uint256 nodeId, bytes32 nodeType, address indexed creator)`
*   `EdgeAdded(uint256 edgeId, uint256 indexed sourceNodeId, uint256 indexed targetNodeId, bytes32 edgeType, address indexed creator)`
*   `NodeTypeDefined(bytes32 nodeType)`
*   `EdgeTypeDefined(bytes32 edgeType)`
*   `ProposalCreated(uint256 proposalId, address indexed proposer, bool isNodeProposal, bytes32 dataType)`
*   `ProposalStatusChanged(uint256 proposalId, ProposalStatus newStatus)`
*   `ProposalValidated(uint256 proposalId, address indexed validator)`
*   `ProposalChallenged(uint256 proposalId, address indexed challenger)`
*   `RoleAssigned(address indexed user, Role newRole)`
*   `RoleRemoved(address indexed user, Role role)`
*   `ReputationUpdated(address indexed user, uint256 newReputation)`
*   `ContractPaused(address indexed admin)`
*   `ContractUnpaused(address indexed admin)`

**Modifiers:**

*   `onlyAdmin()`: Restricts access to the contract admin.
*   `onlyCuratorOrAdmin()`: Restricts access to curators or the admin.
*   `whenNotPaused()`: Prevents function execution when the contract is paused.
*   `whenPaused()`: Allows function execution only when the contract is paused.
*   `isValidNodeType(bytes32 _nodeType)`: Checks if a node type is defined and valid.
*   `isValidEdgeType(bytes32 _edgeType)`: Checks if an edge type is defined and valid.

**Functions (20+):**

1.  `constructor()`: Initializes the contract, setting the admin.
2.  `assignRole(address user, Role role)`: Assigns a specific role to a user (Admin only).
3.  `removeRole(address user, Role role)`: Removes a specific role from a user (Admin only).
4.  `getUserRole(address user)`: Gets the role of a user.
5.  `pauseContract()`: Pauses the contract, restricting most functions (Admin only).
6.  `unpauseContract()`: Unpauses the contract (Admin only).
7.  `defineNodeType(bytes32 nodeType)`: Defines a new valid node type (Admin only).
8.  `defineEdgeType(bytes32 edgeType)`: Defines a new valid edge type (Admin only).
9.  `proposeNode(bytes32 nodeType, string dataURI)`: Proposes adding a new node (Any user).
10. `proposeEdge(uint256 sourceNodeId, uint256 targetNodeId, bytes32 edgeType, string dataURI)`: Proposes adding a new edge (Any user).
11. `validateProposal(uint256 proposalId)`: Validates a pending proposal (Curator or Admin). Updates validation count and potentially approves the proposal.
12. `challengeProposal(uint256 proposalId)`: Challenges a pending proposal (Curator or Admin). Updates challenge count and potentially rejects the proposal.
13. `getProposal(uint256 proposalId)`: Retrieves details of a specific proposal.
14. `getUserProposals(address user)`: Gets a list of proposal IDs created by a specific user. (Requires storing user's proposal IDs, or iterate pending - inefficient. Let's return `pendingProposals` and filter off-chain, or add a mapping `userProposals[address] => uint256[]`. Mapping is better). *Revised*: Use mapping `userProposalIds`.
15. `getPendingProposals()`: Gets a list of IDs for all proposals with status `Pending`.
16. `getNode(uint256 nodeId)`: Retrieves details of a specific node.
17. `getEdge(uint256 edgeId)`: Retrieves details of a specific edge.
18. `getEdgesBySourceNode(uint256 sourceNodeId)`: Gets a list of edge IDs originating from a node.
19. `getEdgesByTargetNode(uint256 targetNodeId)`: Gets a list of edge IDs pointing to a node.
20. `getEdgesBetweenNodes(uint256 sourceNodeId, uint256 targetNodeId)`: Gets a list of edge IDs connecting two nodes. (Requires iterating source/target edges).
21. `getNodesByType(bytes32 nodeType)`: Gets a list of node IDs of a specific type.
22. `getEdgesByType(bytes32 edgeType)`: Gets a list of edge IDs of a specific type.
23. `getUserReputation(address user)`: Gets the reputation score of a user.
24. `getTotalNodes()`: Gets the total number of nodes in the graph.
25. `getTotalEdges()`: Gets the total number of edges in the graph.
26. `getTotalProposals()`: Gets the total number of proposals created.
27. `setValidationThreshold(uint256 threshold)`: Sets the required validation count for proposal approval (Admin only).
28. `setChallengeThreshold(uint256 threshold)`: Sets the required challenge count for proposal rejection (Admin only).
29. `setReputationRewards(uint256 gain, uint256 loss)`: Sets the reputation gain/loss amounts (Admin only).
30. `getNodeCreator(uint256 nodeId)`: Gets the address of the creator of a node.
31. `getEdgeCreator(uint256 edgeId)`: Gets the address of the creator of an edge.

This provides over 30 functions, covering core graph operations, type management, a detailed proposal/validation workflow, reputation tracking, and access control. The caching arrays/mappings for types and edges improve read performance but add complexity to write operations (updating these lists).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Outline and Function Summary ---
// Contract Name: DecentralizedKnowledgeGraph
// Purpose: To create and manage a decentralized, community-curated knowledge graph consisting of nodes (entities) and edges (relationships), validated through a proposal and reputation system.
//
// Data Structures:
// - Role: Enum { User, Curator, Admin }
// - ProposalStatus: Enum { Pending, Approved, Rejected, Challenged }
// - NodeType: Struct { bytes32 name; bool isValid; }
// - EdgeType: Struct { bytes32 name; bool isValid; }
// - Node: Struct { uint256 id; bytes32 nodeType; address creator; string dataURI; uint256 creationTime; }
// - Edge: Struct { uint256 id; uint256 sourceNodeId; uint256 targetNodeId; bytes32 edgeType; address creator; string dataURI; uint256 creationTime; }
// - Proposal: Struct { uint256 id; address proposer; bool isNodeProposal; ProposalStatus status; uint256 validationCount; uint256 challengeCount; uint256 creationTime; bytes memory data; mapping(address => bool) hasValidated; mapping(address => bool) hasChallenged; }
//
// State Variables:
// - admin: Address of the contract administrator.
// - paused: Boolean indicating if the contract is paused.
// - nextNodeId: Counter for unique node IDs.
// - nextEdgeId: Counter for unique edge IDs.
// - nextProposalId: Counter for unique proposal IDs.
// - nodes: Mapping from node ID to Node struct.
// - edges: Mapping from edge ID to Edge struct.
// - nodeTypes: Mapping from bytes32 type name to NodeType struct.
// - edgeTypes: Mapping from bytes32 type name to EdgeType struct.
// - proposals: Mapping from proposal ID to Proposal struct.
// - userReputation: Mapping from user address to their reputation score.
// - userRoles: Mapping from user address to Role.
// - nodeIdsByType: Mapping from bytes32 node type to array of node IDs.
// - edgeIdsByType: Mapping from bytes32 edge type to array of edge IDs.
// - edgeIdsBySourceNode: Mapping from source node ID to array of edge IDs.
// - edgeIdsByTargetNode: Mapping from target node ID to array of edge IDs.
// - userProposalIds: Mapping from user address to array of proposal IDs.
// - pendingProposals: Array of pending proposal IDs.
// - validationThreshold: Min validationCount for approval.
// - challengeThreshold: Min challengeCount for rejection.
// - reputationGainPerValidation: Reputation added for approval.
// - reputationLossPerChallenge: Reputation subtracted for rejection.
//
// Events:
// - NodeAdded, EdgeAdded, NodeTypeDefined, EdgeTypeDefined, ProposalCreated, ProposalStatusChanged, ProposalValidated, ProposalChallenged, RoleAssigned, RoleRemoved, ReputationUpdated, ContractPaused, ContractUnpaused.
//
// Modifiers:
// - onlyAdmin(), onlyCuratorOrAdmin(), whenNotPaused(), whenPaused(), isValidNodeType(), isValidEdgeType().
//
// Functions (31 Total):
// 1. constructor()
// 2. assignRole()
// 3. removeRole()
// 4. getUserRole()
// 5. pauseContract()
// 6. unpauseContract()
// 7. defineNodeType()
// 8. defineEdgeType()
// 9. proposeNode()
// 10. proposeEdge()
// 11. validateProposal()
// 12. challengeProposal()
// 13. getProposal()
// 14. getUserProposals()
// 15. getPendingProposals()
// 16. getNode()
// 17. getEdge()
// 18. getEdgesBySourceNode()
// 19. getEdgesByTargetNode()
// 20. getEdgesBetweenNodes()
// 21. getNodesByType()
// 22. getEdgesByType()
// 23. getUserReputation()
// 24. getTotalNodes()
// 25. getTotalEdges()
// 26. getTotalProposals()
// 27. setValidationThreshold()
// 28. setChallengeThreshold()
// 29. setReputationRewards()
// 30. getNodeCreator()
// 31. getEdgeCreator()
// --- End Outline ---

contract DecentralizedKnowledgeGraph {

    enum Role { User, Curator, Admin }
    enum ProposalStatus { Pending, Approved, Rejected, Challenged }

    struct NodeType {
        bytes32 name;
        bool isValid;
    }

    struct EdgeType {
        bytes32 name;
        bool isValid;
    }

    struct Node {
        uint256 id;
        bytes32 nodeType; // Reference to bytes32 type name
        address creator;
        string dataURI; // URI or hash pointing to off-chain data
        uint256 creationTime;
    }

    struct Edge {
        uint256 id;
        uint256 sourceNodeId;
        uint256 targetNodeId;
        bytes32 edgeType; // Reference to bytes32 type name
        address creator;
        string dataURI; // URI or hash pointing to off-chain data
        uint256 creationTime;
    }

    struct Proposal {
        uint256 id;
        address proposer;
        bool isNodeProposal; // true if proposing a Node, false if proposing an Edge
        ProposalStatus status;
        uint256 validationCount;
        uint256 challengeCount;
        uint256 creationTime;
        bytes data; // ABI encoded Node or Edge struct data
        mapping(address => bool) hasValidated; // Tracks if a specific address has validated this proposal
        mapping(address => bool) hasChallenged; // Tracks if a specific address has challenged this proposal
    }

    address public admin;
    bool public paused;

    uint256 private nextNodeId = 1;
    uint256 private nextEdgeId = 1;
    uint256 private nextProposalId = 1;

    mapping(uint256 => Node) public nodes;
    mapping(uint256 => Edge) public edges;
    mapping(bytes32 => NodeType) private nodeTypes; // Using private as getter handles validity check
    mapping(bytes32 => EdgeType) private edgeTypes; // Using private as getter handles validity check
    mapping(uint256 => Proposal) public proposals;

    mapping(address => uint256) public userReputation;
    mapping(address => Role) private userRoles; // Using private as getter handles default role

    // Caching for efficient queries
    mapping(bytes32 => uint256[]) private nodeIdsByType;
    mapping(bytes32 => uint256[]) private edgeIdsByType;
    mapping(uint256 => uint256[]) private edgeIdsBySourceNode;
    mapping(uint256 => uint256[]) private edgeIdsByTargetNode;
    mapping(address => uint256[]) private userProposalIds;
    uint256[] private pendingProposals; // Simple array to list pending proposal IDs

    uint256 public validationThreshold = 3; // Default: 3 curators needed to validate
    uint256 public challengeThreshold = 2; // Default: 2 curators needed to challenge

    uint256 public reputationGainPerValidation = 10; // Reputation gain for successful validation/approval
    uint256 public reputationLossPerChallenge = 5; // Reputation loss for successful challenge/rejection

    // --- Events ---
    event NodeAdded(uint256 indexed nodeId, bytes32 nodeType, address indexed creator);
    event EdgeAdded(uint256 indexed edgeId, uint256 indexed sourceNodeId, uint256 indexed targetNodeId, bytes32 edgeType, address indexed creator);
    event NodeTypeDefined(bytes32 nodeType);
    event EdgeTypeDefined(bytes32 edgeType);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, bool isNodeProposal, bytes32 dataType); // dataType is nodeType or edgeType
    event ProposalStatusChanged(uint256 indexed proposalId, ProposalStatus newStatus);
    event ProposalValidated(uint256 indexed proposalId, address indexed validator);
    event ProposalChallenged(uint256 indexed proposalId, address indexed challenger);
    event RoleAssigned(address indexed user, Role newRole);
    event RoleRemoved(address indexed user, Role role);
    event ReputationUpdated(address indexed user, uint256 newReputation);
    event ContractPaused(address indexed admin);
    event ContractUnpaused(address indexed admin);

    // --- Modifiers ---
    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    modifier onlyCuratorOrAdmin() {
        require(userRoles[msg.sender] == Role.Curator || msg.sender == admin, "Not curator or admin");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    modifier isValidNodeType(bytes32 _nodeType) {
        require(nodeTypes[_nodeType].isValid, "Invalid node type");
        _;
    }

    modifier isValidEdgeType(bytes32 _edgeType) {
        require(edgeTypes[_edgeType].isValid, "Invalid edge type");
        _;
    }

    // --- Constructor ---
    constructor() {
        admin = msg.sender;
        userRoles[msg.sender] = Role.Admin; // Assign initial admin role
        emit RoleAssigned(msg.sender, Role.Admin);

        // Define some initial types (optional, can be done via define functions)
        nodeTypes["Concept"].isValid = true; emit NodeTypeDefined("Concept");
        nodeTypes["Person"].isValid = true; emit NodeTypeDefined("Person");
        edgeTypes["relatedTo"].isValid = true; emit EdgeTypeDefined("relatedTo");
        edgeTypes["knows"].isValid = true; emit EdgeTypeDefined("knows");
    }

    // --- Admin Functions (5 total) ---

    // 2. Assign a role to a user
    function assignRole(address user, Role role) public onlyAdmin {
        require(user != address(0), "Invalid address");
        require(role != Role.Admin || userRoles[user] != Role.Admin, "Cannot re-assign admin role"); // Prevent removing admin this way
        userRoles[user] = role;
        emit RoleAssigned(user, role);
    }

    // 3. Remove a specific role from a user (reverts to User role)
    function removeRole(address user, Role role) public onlyAdmin {
         require(user != address(0), "Invalid address");
         require(userRoles[user] == role, "User does not have this role");
         require(user != admin || role != Role.Admin, "Cannot remove admin role from admin"); // Prevent removing admin role from admin
         userRoles[user] = Role.User; // Default role
         emit RoleRemoved(user, role);
    }

    // 4. Get a user's role
    function getUserRole(address user) public view returns (Role) {
        return userRoles[user];
    }

    // 5. Pause the contract
    function pauseContract() public onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    // 6. Unpause the contract
    function unpauseContract() public onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    // --- Type Management Functions (2 total definition + 2 check = 4 total) ---

    // 7. Define a new valid node type
    function defineNodeType(bytes32 nodeType) public onlyAdmin whenNotPaused {
        require(!nodeTypes[nodeType].isValid, "Node type already defined");
        nodeTypes[nodeType].name = nodeType;
        nodeTypes[nodeType].isValid = true;
        emit NodeTypeDefined(nodeType);
    }

    // 8. Define a new valid edge type
    function defineEdgeType(bytes32 edgeType) public onlyAdmin whenNotPaused {
        require(!edgeTypes[edgeType].isValid, "Edge type already defined");
        edgeTypes[edgeType].name = edgeType;
        edgeTypes[edgeType].isValid = true;
        emit EdgeTypeDefined(edgeType);
    }

     // 9. Check if a node type is valid
    function isNodeTypeValid(bytes32 _nodeType) public view returns (bool) {
        return nodeTypes[_nodeType].isValid;
    }

    // 10. Check if an edge type is valid
    function isEdgeTypeValid(bytes32 _edgeType) public view returns (bool) {
        return edgeTypes[_edgeType].isValid;
    }


    // --- Proposal Functions (2 creation + 2 validation + 3 getters = 7 total) ---

    // 11. Propose adding a new node
    function proposeNode(bytes32 nodeType, string calldata dataURI)
        public
        whenNotPaused
        isValidNodeType(nodeType)
    {
        uint256 proposalId = nextProposalId++;
        Node memory newNodeData;
        newNodeData.nodeType = nodeType;
        newNodeData.dataURI = dataURI;
        // ID, creator, creationTime set during approval
        newNodeData.id = 0; // Placeholder

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            isNodeProposal: true,
            status: ProposalStatus.Pending,
            validationCount: 0,
            challengeCount: 0,
            creationTime: block.timestamp,
            data: abi.encode(newNodeData),
            hasValidated: new mapping(address => bool),
            hasChallenged: new mapping(address => bool)
        });

        userProposalIds[msg.sender].push(proposalId);
        pendingProposals.push(proposalId);

        emit ProposalCreated(proposalId, msg.sender, true, nodeType);
    }

    // 12. Propose adding a new edge
    function proposeEdge(uint256 sourceNodeId, uint256 targetNodeId, bytes32 edgeType, string calldata dataURI)
        public
        whenNotPaused
        isValidEdgeType(edgeType)
    {
        require(nodes[sourceNodeId].id != 0, "Source node does not exist");
        require(nodes[targetNodeId].id != 0, "Target node does not exist");
        require(sourceNodeId != targetNodeId, "Cannot create self-referential edge");

        uint256 proposalId = nextProposalId++;
        Edge memory newEdgeData;
        newEdgeData.sourceNodeId = sourceNodeId;
        newEdgeData.targetNodeId = targetNodeId;
        newEdgeData.edgeType = edgeType;
        newEdgeData.dataURI = dataURI;
        // ID, creator, creationTime set during approval
         newEdgeData.id = 0; // Placeholder

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            isNodeProposal: false,
            status: ProposalStatus.Pending,
            validationCount: 0,
            challengeCount: 0,
            creationTime: block.timestamp,
            data: abi.encode(newEdgeData),
            hasValidated: new mapping(address => bool),
            hasChallenged: new mapping(address => bool)
        });

        userProposalIds[msg.sender].push(proposalId);
         pendingProposals.push(proposalId);

        bytes32 dataType = edgeType; // Use edge type for event
        emit ProposalCreated(proposalId, msg.sender, false, dataType);
    }

    // 13. Validate a pending proposal
    function validateProposal(uint256 proposalId)
        public
        onlyCuratorOrAdmin
        whenNotPaused
    {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.status == ProposalStatus.Pending, "Proposal is not pending");
        require(!proposal.hasValidated[msg.sender], "Already validated this proposal");
        require(!proposal.hasChallenged[msg.sender], "Cannot validate after challenging");

        proposal.hasValidated[msg.sender] = true;
        proposal.validationCount++;

        emit ProposalValidated(proposalId, msg.sender);

        // Check for approval threshold
        if (proposal.validationCount >= validationThreshold) {
             // To be approved, validations must significantly outweigh challenges
             // Simple check: Validations meet threshold AND are at least double challenges
             // More complex logic could involve curator reputation weighting
             if (proposal.validationCount > proposal.challengeCount * 2) {
                  _approveProposal(proposalId);
             }
        }
    }

    // 14. Challenge a pending proposal
    function challengeProposal(uint256 proposalId)
        public
        onlyCuratorOrAdmin
        whenNotPaused
    {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.status == ProposalStatus.Pending, "Proposal is not pending");
        require(!proposal.hasChallenged[msg.sender], "Already challenged this proposal");
        require(!proposal.hasValidated[msg.sender], "Cannot challenge after validating");

        proposal.hasChallenged[msg.sender] = true;
        proposal.challengeCount++;

        emit ProposalChallenged(proposalId, msg.sender);

         // Check for rejection threshold
        if (proposal.challengeCount >= challengeThreshold) {
             // To be rejected, challenges must significantly outweigh validations
             // Simple check: Challenges meet threshold AND are at least double validations
             if (proposal.challengeCount > proposal.validationCount * 2) {
                  _rejectProposal(proposalId);
             }
        }
    }

    // Internal function to approve a proposal
    function _approveProposal(uint256 proposalId) internal {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.status == ProposalStatus.Pending, "Proposal is not pending"); // Should be pending

        proposal.status = ProposalStatus.Approved;
        emit ProposalStatusChanged(proposalId, ProposalStatus.Approved);

        // Process data and add to graph
        if (proposal.isNodeProposal) {
            Node memory newNodeData = abi.decode(proposal.data, (Node));
            uint256 nodeId = nextNodeId++;
            nodes[nodeId] = Node({
                id: nodeId,
                nodeType: newNodeData.nodeType,
                creator: proposal.proposer,
                dataURI: newNodeData.dataURI,
                creationTime: block.timestamp
            });
            nodeIdsByType[newNodeData.nodeType].push(nodeId);
            emit NodeAdded(nodeId, newNodeData.nodeType, proposal.proposer);
        } else {
            Edge memory newEdgeData = abi.decode(proposal.data, (Edge));
            uint256 edgeId = nextEdgeId++;
            edges[edgeId] = Edge({
                id: edgeId,
                sourceNodeId: newEdgeData.sourceNodeId,
                targetNodeId: newEdgeData.targetNodeId,
                edgeType: newEdgeData.edgeType,
                creator: proposal.proposer,
                dataURI: newEdgeData.dataURI,
                creationTime: block.timestamp
            });
            edgeIdsByType[newEdgeData.edgeType].push(edgeId);
            edgeIdsBySourceNode[newEdgeData.sourceNodeId].push(edgeId);
            edgeIdsByTargetNode[newEdgeData.targetNodeId].push(edgeId);
            emit EdgeAdded(edgeId, newEdgeData.sourceNodeId, newEdgeData.targetNodeId, newEdgeData.edgeType, proposal.proposer);
        }

        // Update reputation for proposer and validators
        userReputation[proposal.proposer] += reputationGainPerValidation;
        emit ReputationUpdated(proposal.proposer, userReputation[proposal.proposer]);

        // Iterate through validators and update their reputation
        // Note: Iterating mappings isn't possible. A better approach for production
        // would store validators in a list or use events/off-chain data to track.
        // For this example, we'll simulate by just rewarding the proposer.
        // A more robust system would need to reward *all* validators of an approved proposal.
        // Let's skip iterating the mapping here to avoid gas issues and complexity.
        // Assume off-chain logic or event listening handles rewarding specific validators.
        // Or, if `hasValidated` tracked validation power, it could be summed.

         // Remove from pending list (basic implementation)
        _removePendingProposal(proposalId);
    }

    // Internal function to reject a proposal
    function _rejectProposal(uint256 proposalId) internal {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.status == ProposalStatus.Pending, "Proposal is not pending"); // Should be pending

        proposal.status = ProposalStatus.Rejected;
        emit ProposalStatusChanged(proposalId, ProposalStatus.Rejected);

        // Update reputation for proposer and challengers
        if (userReputation[proposal.proposer] >= reputationLossPerChallenge) {
             userReputation[proposal.proposer] -= reputationLossPerChallenge;
        } else {
             userReputation[proposal.proposer] = 0;
        }
        emit ReputationUpdated(proposal.proposer, userReputation[proposal.proposer]);

        // Similar limitation as _approveProposal for rewarding challengers.
        // Assume off-chain logic or event listening handles rewarding specific challengers.

         // Remove from pending list (basic implementation)
        _removePendingProposal(proposalId);
    }

     // Helper to remove a proposal from the pending list (inefficient for large lists)
     // In a real-world scenario with potentially many pending proposals, a different data structure
     // (like a linked list in storage or managing off-chain) would be required.
    function _removePendingProposal(uint256 proposalId) internal {
        uint256 index = pendingProposals.length;
        for (uint256 i = 0; i < pendingProposals.length; i++) {
            if (pendingProposals[i] == proposalId) {
                index = i;
                break;
            }
        }

        if (index < pendingProposals.length) {
            // Swap last element with the one to be removed
            pendingProposals[index] = pendingProposals[pendingProposals.length - 1];
            // Shrink the array
            pendingProposals.pop();
        }
    }


    // 15. Get a specific proposal by ID
    function getProposal(uint256 proposalId)
        public
        view
        returns (
            uint256 id,
            address proposer,
            bool isNodeProposal,
            ProposalStatus status,
            uint256 validationCount,
            uint256 challengeCount,
            uint256 creationTime,
            bytes memory data // Raw ABI encoded data
        )
    {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        return (
            proposal.id,
            proposal.proposer,
            proposal.isNodeProposal,
            proposal.status,
            proposal.validationCount,
            proposal.challengeCount,
            proposal.creationTime,
            proposal.data
        );
    }

    // 16. Get proposals created by a user
    function getUserProposals(address user) public view returns (uint256[] memory) {
        return userProposalIds[user];
    }

    // 17. Get IDs of all pending proposals
    function getPendingProposals() public view returns (uint256[] memory) {
        return pendingProposals;
    }

    // --- Graph Query Functions (6 total) ---

    // 18. Get a node by ID
    function getNode(uint256 nodeId) public view returns (Node memory) {
        require(nodes[nodeId].id != 0, "Node does not exist");
        return nodes[nodeId];
    }

    // 19. Get an edge by ID
    function getEdge(uint256 edgeId) public view returns (Edge memory) {
        require(edges[edgeId].id != 0, "Edge does not exist");
        return edges[edgeId];
    }

    // 20. Get all edge IDs originating from a source node
    function getEdgesBySourceNode(uint256 sourceNodeId) public view returns (uint256[] memory) {
         require(nodes[sourceNodeId].id != 0, "Source node does not exist");
         return edgeIdsBySourceNode[sourceNodeId];
    }

     // 21. Get all edge IDs pointing to a target node
    function getEdgesByTargetNode(uint256 targetNodeId) public view returns (uint256[] memory) {
        require(nodes[targetNodeId].id != 0, "Target node does not exist");
        return edgeIdsByTargetNode[targetNodeId];
    }

    // 22. Get all edge IDs between two nodes (source -> target)
    // Note: This is less efficient than specific source/target queries as it iterates edgesBySourceNode
    function getEdgesBetweenNodes(uint256 sourceNodeId, uint256 targetNodeId) public view returns (uint256[] memory) {
        require(nodes[sourceNodeId].id != 0, "Source node does not exist");
        require(nodes[targetNodeId].id != 0, "Target node does not exist");

        uint256[] memory sourceEdges = edgeIdsBySourceNode[sourceNodeId];
        uint256[] memory result = new uint256[](sourceEdges.length); // Max possible edges
        uint256 count = 0;

        for (uint256 i = 0; i < sourceEdges.length; i++) {
            if (edges[sourceEdges[i]].targetNodeId == targetNodeId) {
                result[count] = sourceEdges[i];
                count++;
            }
        }

        // Resize the result array
        uint256[] memory finalResult = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            finalResult[i] = result[i];
        }
        return finalResult;
    }


    // 23. Get all node IDs of a specific type
    function getNodesByType(bytes32 nodeType) public view isValidNodeType(nodeType) returns (uint256[] memory) {
        return nodeIdsByType[nodeType];
    }

    // 24. Get all edge IDs of a specific type
    function getEdgesByType(bytes32 edgeType) public view isValidEdgeType(edgeType) returns (uint256[] memory) {
        return edgeIdsByType[edgeType];
    }


    // --- Reputation Functions (1 total) ---

    // 25. Get user reputation
    function getUserReputation(address user) public view returns (uint256) {
        return userReputation[user];
    }

    // --- General Getters (3 total) ---

    // 26. Get total number of nodes
    function getTotalNodes() public view returns (uint256) {
        return nextNodeId - 1;
    }

    // 27. Get total number of edges
    function getTotalEdges() public view returns (uint256) {
        return nextEdgeId - 1;
    }

    // 28. Get total number of proposals (including approved/rejected)
    function getTotalProposals() public view returns (uint256) {
        return nextProposalId - 1;
    }

    // --- Admin Configuration (3 total) ---

    // 29. Set the threshold for proposal validation
    function setValidationThreshold(uint256 threshold) public onlyAdmin {
        require(threshold > 0, "Threshold must be positive");
        validationThreshold = threshold;
    }

    // 30. Set the threshold for proposal challenge
    function setChallengeThreshold(uint256 threshold) public onlyAdmin {
        require(threshold > 0, "Threshold must be positive");
        challengeThreshold = threshold;
    }

     // 31. Set the reputation rewards/losses for proposal outcomes
    function setReputationRewards(uint256 gain, uint256 loss) public onlyAdmin {
        reputationGainPerValidation = gain;
        reputationLossPerChallenge = loss;
    }

     // --- Creator Getters (2 total) ---

     // 32. Get the creator of a node
     function getNodeCreator(uint256 nodeId) public view returns (address) {
         require(nodes[nodeId].id != 0, "Node does not exist");
         return nodes[nodeId].creator;
     }

     // 33. Get the creator of an edge
     function getEdgeCreator(uint256 edgeId) public view returns (address) {
         require(edges[edgeId].id != 0, "Edge does not exist");
         return edges[edgeId].creator;
     }
}
```