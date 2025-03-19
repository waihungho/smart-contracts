```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Knowledge Graph (DAKG)
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a Decentralized Autonomous Knowledge Graph (DAKG).
 *      This contract allows users to create, connect, and curate knowledge in a decentralized manner.
 *      It features a graph-based data structure with nodes and edges, governance mechanisms,
 *      reputation system, and advanced functionalities for knowledge management.
 *
 * Function Outline and Summary:
 *
 * 1.  initializeGraph(string _graphName, string _graphDescription): Initializes the knowledge graph with a name and description.
 * 2.  createNode(string _nodeType, string _content, string _metadata): Creates a new node in the graph.
 * 3.  createEdge(uint256 _sourceNodeId, uint256 _targetNodeId, string _relationType, string _metadata): Creates an edge between two existing nodes.
 * 4.  getNode(uint256 _nodeId): Retrieves the details of a specific node.
 * 5.  getEdge(uint256 _edgeId): Retrieves the details of a specific edge.
 * 6.  updateNodeContent(uint256 _nodeId, string _newContent): Updates the content of an existing node. (Governance Required)
 * 7.  updateEdgeMetadata(uint256 _edgeId, string _newMetadata): Updates the metadata of an existing edge. (Governance Required)
 * 8.  deleteNode(uint256 _nodeId): Deletes a node and its associated edges. (Governance Required)
 * 9.  deleteEdge(uint256 _edgeId): Deletes a specific edge. (Governance Required)
 * 10. getNodeEdges(uint256 _nodeId): Retrieves all edges connected to a specific node.
 * 11. searchNodesByContent(string _query): Searches for nodes containing specific content. (Basic keyword search)
 * 12. filterNodesByType(string _nodeType): Filters nodes based on their type.
 * 13. upvoteNode(uint256 _nodeId): Allows users to upvote a node, contributing to its reputation.
 * 14. downvoteNode(uint256 _nodeId): Allows users to downvote a node.
 * 15. reportNode(uint256 _nodeId, string _reportReason): Allows users to report a node for inappropriate content.
 * 16. proposeNodeUpdate(uint256 _nodeId, string _proposedContent, string _proposalRationale): Submits a proposal to update node content, requiring community approval.
 * 17. voteOnProposal(uint256 _proposalId, bool _vote): Allows users to vote on active proposals.
 * 18. executeProposal(uint256 _proposalId): Executes a proposal if it passes the voting threshold. (Governance)
 * 19. getProposalDetails(uint256 _proposalId): Retrieves details of a specific proposal.
 * 20. contributeToGraph(string _contributionType, string _contributionDetails):  A generic function for users to contribute to the graph's development or maintenance.
 * 21. getGraphMetadata(): Retrieves the graph's name, description, and other metadata.
 * 22. getContributorReputation(address _contributor): Retrieves the reputation score of a contributor. (Basic reputation system based on upvotes/downvotes on their contributions)
 * 23. withdrawReputationRewards(): Allows contributors to withdraw rewards based on their reputation (Placeholder - requires external reward mechanism).
 * 24. setGovernanceParameters(uint256 _proposalThreshold, uint256 _votingDuration): Allows the graph owner to set governance parameters. (Owner-controlled initially, could be DAO-governed later)
 * 25. pauseGraph(): Pauses the graph functionality for maintenance or emergency. (Owner-controlled)
 * 26. unpauseGraph(): Resumes graph functionality. (Owner-controlled)
 * 27. getGraphStatus(): Returns the current status of the graph (paused/active).
 */

contract DecentralizedAutonomousKnowledgeGraph {

    // --- Data Structures ---

    struct Node {
        uint256 nodeId;
        string nodeType; // e.g., "Concept", "Person", "Event", "Document"
        string content; // The core information of the node
        string metadata; // Additional structured data (e.g., JSON, tags, categories)
        address creator;
        uint256 creationTimestamp;
        uint256 lastUpdatedTimestamp;
        int256 upvotes;
        int256 downvotes;
        uint256 reportCount;
    }

    struct Edge {
        uint256 edgeId;
        uint256 sourceNodeId;
        uint256 targetNodeId;
        string relationType; // e.g., "isA", "relatedTo", "authoredBy", "causes"
        string metadata; // Additional edge-specific metadata
        address creator;
        uint256 creationTimestamp;
        uint256 lastUpdatedTimestamp;
        int256 upvotes;
        int256 downvotes;
        uint256 reportCount;
    }

    struct Proposal {
        uint256 proposalId;
        uint256 nodeId;
        string proposedContent;
        string proposalRationale;
        address proposer;
        uint256 creationTimestamp;
        uint256 votingEndTime;
        uint256 upvotes;
        uint256 downvotes;
        bool executed;
    }

    struct GraphMetadata {
        string graphName;
        string graphDescription;
        address owner;
        uint256 creationTimestamp;
        bool isPaused;
        uint256 proposalThreshold; // Percentage of votes needed to pass a proposal (e.g., 51%)
        uint256 votingDuration;    // Default voting duration in blocks
    }


    // --- State Variables ---

    GraphMetadata public graphMetadata;

    mapping(uint256 => Node) public nodes;
    mapping(uint256 => Edge) public edges;
    mapping(uint256 => Proposal) public proposals;

    mapping(uint256 => uint256[]) public nodeEdges; // Store edge IDs associated with each node
    mapping(address => int256) public contributorReputation; // Basic reputation system

    uint256 public nodeCounter;
    uint256 public edgeCounter;
    uint256 public proposalCounter;


    // --- Events ---

    event GraphInitialized(string graphName, address owner, uint256 timestamp);
    event NodeCreated(uint256 nodeId, string nodeType, address creator, uint256 timestamp);
    event EdgeCreated(uint256 edgeId, uint256 sourceNodeId, uint256 targetNodeId, string relationType, address creator, uint256 timestamp);
    event NodeUpdated(uint256 nodeId, string newContent, address updater, uint256 timestamp);
    event EdgeUpdated(uint256 edgeId, string newMetadata, address updater, uint256 timestamp);
    event NodeDeleted(uint256 nodeId, address deleter, uint256 timestamp);
    event EdgeDeleted(uint256 edgeId, address deleter, uint256 timestamp);
    event NodeUpvoted(uint256 nodeId, address voter, int256 newUpvoteCount);
    event NodeDownvoted(uint256 nodeId, address voter, int256 newDownvoteCount);
    event NodeReported(uint256 nodeId, address reporter, string reason);
    event ProposalSubmitted(uint256 proposalId, uint256 nodeId, address proposer, uint256 endTime);
    event ProposalVoted(uint256 proposalId, address voter, bool vote, uint256 upvotes, uint256 downvotes);
    event ProposalExecuted(uint256 proposalId, uint256 nodeId);
    event ContributionMade(address contributor, string contributionType, string details, uint256 timestamp);
    event GraphPaused(address pauser, uint256 timestamp);
    event GraphUnpaused(address unpauser, uint256 timestamp);
    event GovernanceParametersSet(uint256 proposalThreshold, uint256 votingDuration, address setter, uint256 timestamp);


    // --- Modifiers ---

    modifier graphActive() {
        require(!graphMetadata.isPaused, "Graph is currently paused.");
        _;
    }

    modifier onlyGraphOwner() {
        require(msg.sender == graphMetadata.owner, "Only the graph owner can perform this action.");
        _;
    }

    modifier validNode(uint256 _nodeId) {
        require(_nodeId > 0 && _nodeId <= nodeCounter && bytes(nodes[_nodeId].content).length > 0, "Invalid node ID.");
        _;
    }

    modifier validEdge(uint256 _edgeId) {
        require(_edgeId > 0 && _edgeId <= edgeCounter && edges[_edgeId].sourceNodeId > 0 && edges[_edgeId].targetNodeId > 0, "Invalid edge ID.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCounter && !proposals[_proposalId].executed, "Invalid or executed proposal ID.");
        _;
    }

    modifier proposalNotExpired(uint256 _proposalId) {
        require(block.timestamp < proposals[_proposalId].votingEndTime, "Proposal voting period has expired.");
        _;
    }


    // --- Functions ---

    /// @notice Initializes the knowledge graph with a name and description.
    /// @param _graphName The name of the knowledge graph.
    /// @param _graphDescription A brief description of the graph.
    function initializeGraph(string memory _graphName, string memory _graphDescription) public {
        require(bytes(graphMetadata.graphName).length == 0, "Graph already initialized.");
        graphMetadata = GraphMetadata({
            graphName: _graphName,
            graphDescription: _graphDescription,
            owner: msg.sender,
            creationTimestamp: block.timestamp,
            isPaused: false,
            proposalThreshold: 51, // Default 51% for proposals to pass
            votingDuration: 7 days // Default 7 days voting duration
        });
        emit GraphInitialized(_graphName, msg.sender, block.timestamp);
    }

    /// @notice Creates a new node in the graph.
    /// @param _nodeType The type of the node (e.g., "Concept", "Person").
    /// @param _content The main content of the node.
    /// @param _metadata Optional metadata for the node.
    function createNode(string memory _nodeType, string memory _content, string memory _metadata) public graphActive returns (uint256 nodeId) {
        nodeCounter++;
        nodeId = nodeCounter;
        nodes[nodeId] = Node({
            nodeId: nodeId,
            nodeType: _nodeType,
            content: _content,
            metadata: _metadata,
            creator: msg.sender,
            creationTimestamp: block.timestamp,
            lastUpdatedTimestamp: block.timestamp,
            upvotes: 0,
            downvotes: 0,
            reportCount: 0
        });
        emit NodeCreated(nodeId, _nodeType, msg.sender, block.timestamp);
        return nodeId;
    }

    /// @notice Creates an edge between two existing nodes.
    /// @param _sourceNodeId The ID of the source node.
    /// @param _targetNodeId The ID of the target node.
    /// @param _relationType The type of relationship between the nodes (e.g., "relatedTo").
    /// @param _metadata Optional metadata for the edge.
    function createEdge(uint256 _sourceNodeId, uint256 _targetNodeId, string memory _relationType, string memory _metadata) public graphActive validNode(_sourceNodeId) validNode(_targetNodeId) returns (uint256 edgeId) {
        edgeCounter++;
        edgeId = edgeCounter;
        edges[edgeId] = Edge({
            edgeId: edgeId,
            sourceNodeId: _sourceNodeId,
            targetNodeId: _targetNodeId,
            relationType: _relationType,
            metadata: _metadata,
            creator: msg.sender,
            creationTimestamp: block.timestamp,
            lastUpdatedTimestamp: block.timestamp,
            upvotes: 0,
            downvotes: 0,
            reportCount: 0
        });
        nodeEdges[_sourceNodeId].push(edgeId);
        nodeEdges[_targetNodeId].push(edgeId); // Assuming undirected edges for simplicity, adjust if needed
        emit EdgeCreated(edgeId, _sourceNodeId, _targetNodeId, _relationType, msg.sender, block.timestamp);
        return edgeId;
    }

    /// @notice Retrieves the details of a specific node.
    /// @param _nodeId The ID of the node to retrieve.
    /// @return Node struct containing node details.
    function getNode(uint256 _nodeId) public view validNode(_nodeId) returns (Node memory) {
        return nodes[_nodeId];
    }

    /// @notice Retrieves the details of a specific edge.
    /// @param _edgeId The ID of the edge to retrieve.
    /// @return Edge struct containing edge details.
    function getEdge(uint256 _edgeId) public view validEdge(_edgeId) returns (Edge memory) {
        return edges[_edgeId];
    }

    /// @notice Updates the content of an existing node. Requires a successful proposal.
    /// @param _nodeId The ID of the node to update.
    /// @param _newContent The new content for the node.
    function updateNodeContent(uint256 _nodeId, string memory _newContent) public graphActive validNode(_nodeId) {
        // Governance implementation would typically go here.
        // For this example, direct update is allowed (remove for real governance).
        nodes[_nodeId].content = _newContent;
        nodes[_nodeId].lastUpdatedTimestamp = block.timestamp;
        emit NodeUpdated(_nodeId, _newContent, msg.sender, block.timestamp);
    }

    /// @notice Updates the metadata of an existing edge. Requires governance.
    /// @param _edgeId The ID of the edge to update.
    /// @param _newMetadata The new metadata for the edge.
    function updateEdgeMetadata(uint256 _edgeId, string memory _newMetadata) public graphActive validEdge(_edgeId) {
        // Governance implementation would typically go here.
        // For this example, direct update is allowed (remove for real governance).
        edges[_edgeId].metadata = _newMetadata;
        edges[_edgeId].lastUpdatedTimestamp = block.timestamp;
        emit EdgeUpdated(_edgeId, _newMetadata, msg.sender, block.timestamp);
    }

    /// @notice Deletes a node and its associated edges. Requires governance.
    /// @param _nodeId The ID of the node to delete.
    function deleteNode(uint256 _nodeId) public graphActive validNode(_nodeId) {
        // Governance implementation would typically go here.
        // For this example, direct deletion is allowed (remove for real governance).
        delete nodes[_nodeId];
        // TODO: Remove associated edges from nodeEdges mappings - more complex logic needed.
        emit NodeDeleted(_nodeId, msg.sender, block.timestamp);
    }

    /// @notice Deletes a specific edge. Requires governance.
    /// @param _edgeId The ID of the edge to delete.
    function deleteEdge(uint256 _edgeId) public graphActive validEdge(_edgeId) {
        // Governance implementation would typically go here.
        // For this example, direct deletion is allowed (remove for real governance).
        delete edges[_edgeId];
        // TODO: Remove edgeId from nodeEdges mappings of source and target nodes - more complex logic needed.
        emit EdgeDeleted(_edgeId, msg.sender, block.timestamp);
    }

    /// @notice Retrieves all edge IDs connected to a specific node.
    /// @param _nodeId The ID of the node.
    /// @return An array of edge IDs connected to the node.
    function getNodeEdges(uint256 _nodeId) public view validNode(_nodeId) returns (uint256[] memory) {
        return nodeEdges[_nodeId];
    }

    /// @notice Searches for nodes containing specific content (basic keyword search).
    /// @param _query The keyword to search for.
    /// @return An array of node IDs that contain the query in their content.
    function searchNodesByContent(string memory _query) public view graphActive returns (uint256[] memory) {
        uint256[] memory results = new uint256[](nodeCounter); // Max possible results
        uint256 resultCount = 0;
        for (uint256 i = 1; i <= nodeCounter; i++) {
            if (bytes(nodes[i].content).length > 0 && stringContains(nodes[i].content, _query)) {
                results[resultCount] = i;
                resultCount++;
            }
        }
        // Resize the array to the actual number of results
        uint256[] memory finalResults = new uint256[](resultCount);
        for (uint256 i = 0; i < resultCount; i++) {
            finalResults[i] = results[i];
        }
        return finalResults;
    }

    /// @notice Filters nodes based on their type.
    /// @param _nodeType The node type to filter by.
    /// @return An array of node IDs of the specified type.
    function filterNodesByType(string memory _nodeType) public view graphActive returns (uint256[] memory) {
        uint256[] memory results = new uint256[](nodeCounter); // Max possible results
        uint256 resultCount = 0;
        for (uint256 i = 1; i <= nodeCounter; i++) {
            if (bytes(nodes[i].nodeType).length > 0 && keccak256(bytes(nodes[i].nodeType)) == keccak256(bytes(_nodeType))) {
                results[resultCount] = i;
                resultCount++;
            }
        }
        // Resize the array to the actual number of results
        uint256[] memory finalResults = new uint256[](resultCount);
        for (uint256 i = 0; i < resultCount; i++) {
            finalResults[i] = results[i];
        }
        return finalResults;
    }

    /// @notice Allows users to upvote a node.
    /// @param _nodeId The ID of the node to upvote.
    function upvoteNode(uint256 _nodeId) public graphActive validNode(_nodeId) {
        nodes[_nodeId].upvotes++;
        contributorReputation[msg.sender]++; // Increase reputation for upvoting
        emit NodeUpvoted(_nodeId, msg.sender, nodes[_nodeId].upvotes);
    }

    /// @notice Allows users to downvote a node.
    /// @param _nodeId The ID of the node to downvote.
    function downvoteNode(uint256 _nodeId) public graphActive validNode(_nodeId) {
        nodes[_nodeId].downvotes--;
        contributorReputation[msg.sender]--; // Decrease reputation for downvoting
        emit NodeDownvoted(_nodeId, msg.sender, nodes[_nodeId].downvotes);
    }

    /// @notice Allows users to report a node for inappropriate content.
    /// @param _nodeId The ID of the node to report.
    /// @param _reportReason The reason for reporting the node.
    function reportNode(uint256 _nodeId, string memory _reportReason) public graphActive validNode(_nodeId) {
        nodes[_nodeId].reportCount++;
        emit NodeReported(_nodeId, msg.sender, _reportReason);
        // TODO: Implement moderation logic based on report count or governance.
    }

    /// @notice Submits a proposal to update node content, requiring community approval.
    /// @param _nodeId The ID of the node to update.
    /// @param _proposedContent The new content proposed for the node.
    /// @param _proposalRationale The reason for proposing the content update.
    function proposeNodeUpdate(uint256 _nodeId, string memory _proposedContent, string memory _proposalRationale) public graphActive validNode(_nodeId) {
        proposalCounter++;
        uint256 proposalId = proposalCounter;
        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            nodeId: _nodeId,
            proposedContent: _proposedContent,
            proposalRationale: _proposalRationale,
            proposer: msg.sender,
            creationTimestamp: block.timestamp,
            votingEndTime: block.timestamp + graphMetadata.votingDuration,
            upvotes: 0,
            downvotes: 0,
            executed: false
        });
        emit ProposalSubmitted(proposalId, _nodeId, msg.sender, proposals[proposalId].votingEndTime);
    }

    /// @notice Allows users to vote on active proposals.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _vote True for upvote, false for downvote.
    function voteOnProposal(uint256 _proposalId, bool _vote) public graphActive proposalExists(_proposalId) proposalNotExpired(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(msg.sender != proposal.proposer, "Proposer cannot vote on their own proposal."); // Optional: Prevent proposer voting
        // TODO: Implement more sophisticated voting mechanisms (e.g., token-weighted voting).
        if (_vote) {
            proposal.upvotes++;
        } else {
            proposal.downvotes++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _vote, proposal.upvotes, proposal.downvotes);
    }

    /// @notice Executes a proposal if it passes the voting threshold. (Governance)
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) public graphActive proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp >= proposal.votingEndTime, "Voting period is not yet over.");
        require(!proposal.executed, "Proposal already executed.");

        uint256 totalVotes = proposal.upvotes + proposal.downvotes;
        uint256 requiredUpvotes = (totalVotes * graphMetadata.proposalThreshold) / 100;

        if (proposal.upvotes >= requiredUpvotes) {
            // Execute the proposal based on its type
            if (bytes(proposal.proposedContent).length > 0) { // Assuming content update proposal for now
                nodes[proposal.nodeId].content = proposal.proposedContent;
                nodes[proposal.nodeId].lastUpdatedTimestamp = block.timestamp;
                emit NodeUpdated(proposal.nodeId, proposal.proposedContent, address(this), block.timestamp); // 'this' as system updater
            }
            proposal.executed = true;
            emit ProposalExecuted(_proposalId, proposal.nodeId);
        } else {
            // Proposal failed - maybe emit an event for failed proposals.
        }
    }

    /// @notice Retrieves details of a specific proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return Proposal struct containing proposal details.
    function getProposalDetails(uint256 _proposalId) public view proposalExists(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    /// @notice A generic function for users to contribute to the graph's development or maintenance.
    /// @param _contributionType The type of contribution (e.g., "Bug Report", "Feature Request", "Documentation").
    /// @param _contributionDetails Details of the contribution.
    function contributeToGraph(string memory _contributionType, string memory _contributionDetails) public graphActive {
        emit ContributionMade(msg.sender, _contributionType, _contributionDetails, block.timestamp);
        // TODO: Implement mechanisms to process contributions - potentially off-chain or through governance.
    }

    /// @notice Retrieves the graph's name, description, and other metadata.
    /// @return GraphMetadata struct containing graph metadata.
    function getGraphMetadata() public view returns (GraphMetadata memory) {
        return graphMetadata;
    }

    /// @notice Retrieves the reputation score of a contributor.
    /// @param _contributor The address of the contributor.
    /// @return The reputation score of the contributor.
    function getContributorReputation(address _contributor) public view returns (int256) {
        return contributorReputation[_contributor];
    }

    /// @notice Allows contributors to withdraw rewards based on their reputation (Placeholder - requires external reward mechanism).
    function withdrawReputationRewards() public graphActive {
        int256 reputation = contributorReputation[msg.sender];
        require(reputation > 0, "No reputation rewards to withdraw.");
        // TODO: Implement a reward distribution mechanism (e.g., linked to an external token or staking system).
        // For now, just reset reputation after withdrawal (placeholder logic).
        contributorReputation[msg.sender] = 0;
        // Emit event for reward withdrawal (if implemented)
    }

    /// @notice Allows the graph owner to set governance parameters (proposal threshold, voting duration).
    /// @param _proposalThreshold The new proposal voting threshold (percentage).
    /// @param _votingDuration The new default voting duration in seconds.
    function setGovernanceParameters(uint256 _proposalThreshold, uint256 _votingDuration) public onlyGraphOwner graphActive {
        require(_proposalThreshold >= 0 && _proposalThreshold <= 100, "Invalid proposal threshold percentage.");
        require(_votingDuration > 0, "Voting duration must be positive.");
        graphMetadata.proposalThreshold = _proposalThreshold;
        graphMetadata.votingDuration = _votingDuration;
        emit GovernanceParametersSet(_proposalThreshold, _votingDuration, msg.sender, block.timestamp);
    }

    /// @notice Pauses the graph functionality for maintenance or emergency. (Owner-controlled)
    function pauseGraph() public onlyGraphOwner {
        graphMetadata.isPaused = true;
        emit GraphPaused(msg.sender, block.timestamp);
    }

    /// @notice Resumes graph functionality. (Owner-controlled)
    function unpauseGraph() public onlyGraphOwner {
        graphMetadata.isPaused = false;
        emit GraphUnpaused(msg.sender, block.timestamp);
    }

    /// @notice Returns the current status of the graph (paused/active).
    /// @return True if paused, false if active.
    function getGraphStatus() public view returns (bool) {
        return graphMetadata.isPaused;
    }


    // --- Internal Utility Functions ---

    /// @dev Internal function to check if a string contains a substring (basic implementation).
    /// @param _string The string to search in.
    /// @param _substring The substring to search for.
    /// @return True if the string contains the substring, false otherwise.
    function stringContains(string memory _string, string memory _substring) internal pure returns (bool) {
        return vm_string.indexOf(_string, _substring) != -1;
    }
}
```