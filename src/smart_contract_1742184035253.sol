```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Knowledge Graph (DAKG)
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a decentralized, community-driven knowledge graph.
 *
 * **Outline and Function Summary:**
 *
 * **Knowledge Node Management:**
 *   1. `createNode(string _nodeType, string _nodeContent)`: Allows registered contributors to create new knowledge nodes.
 *   2. `getNodeInfo(uint256 _nodeId)`: Retrieves information about a specific knowledge node.
 *   3. `updateNodeContent(uint256 _nodeId, string _newNodeContent)`: Allows the node creator or community-approved users to update node content.
 *   4. `getNodeByType(string _nodeType)`: Returns a list of node IDs of a specific type.
 *   5. `searchNodesByContent(string _keyword)`: Searches for nodes whose content contains a specific keyword.
 *   6. `endorseNode(uint256 _nodeId)`: Allows users to endorse a node, increasing its reputation.
 *   7. `getNodeEndorsementCount(uint256 _nodeId)`: Retrieves the endorsement count for a node.
 *   8. `reportNode(uint256 _nodeId, string _reportReason)`: Allows users to report nodes for inaccuracies or policy violations.
 *
 * **Relationship Management:**
 *   9. `createRelationship(uint256 _sourceNodeId, uint256 _targetNodeId, string _relationshipType)`: Creates a relationship between two existing knowledge nodes.
 *   10. `getRelationshipsForNode(uint256 _nodeId)`: Retrieves all relationships associated with a specific node (both incoming and outgoing).
 *   11. `getNodesByRelationship(uint256 _nodeId, string _relationshipType)`: Retrieves nodes connected to a given node through a specific relationship type.
 *   12. `deleteRelationship(uint256 _relationshipId)`: Allows the creators of the relationship or community-approved users to delete a relationship.
 *
 * **Contributor & Reputation System:**
 *   13. `registerContributor()`: Allows users to register as contributors to the knowledge graph.
 *   14. `isContributor(address _user)`: Checks if an address is a registered contributor.
 *   15. `getContributorReputation(address _contributor)`: Retrieves the reputation score of a contributor. (Reputation increases with positive actions like node creation, endorsements, and accurate reports; decreases with negative actions like creating low-quality nodes or false reports).
 *   16. `upvoteContributor(address _contributor)`: Allows contributors to upvote another contributor, increasing their reputation.
 *   17. `downvoteContributor(address _contributor)`: Allows contributors to downvote another contributor, decreasing their reputation.
 *
 * **Governance & Community Features:**
 *   18. `proposeNodeUpdate(uint256 _nodeId, string _proposedContent)`: Allows contributors to propose updates to existing node content, requiring community approval.
 *   19. `voteOnProposal(uint256 _proposalId, bool _vote)`: Allows contributors to vote on pending node update proposals.
 *   20. `executeProposal(uint256 _proposalId)`: Executes an approved node update proposal.
 *   21. `donateToNode(uint256 _nodeId)`: Allows users to donate ETH to a specific knowledge node, potentially rewarding creators or maintainers (implementation can be extended).
 *   22. `withdrawNodeDonations(uint256 _nodeId)`: Allows the node creator (or designated maintainer) to withdraw accumulated donations.
 */
contract DecentralizedAutonomousKnowledgeGraph {

    // --- Data Structures ---

    struct Node {
        uint256 nodeId;
        string nodeType; // e.g., "Concept", "Person", "Event"
        string nodeContent;
        address creator;
        uint256 creationTimestamp;
        uint256 endorsementCount;
        int256 reputationScore; // Node-specific reputation
        bool exists;
    }

    struct Relationship {
        uint256 relationshipId;
        uint256 sourceNodeId;
        uint256 targetNodeId;
        string relationshipType; // e.g., "IsA", "RelatedTo", "Causes"
        address creator;
        uint256 creationTimestamp;
        bool exists;
    }

    struct Proposal {
        uint256 proposalId;
        uint256 nodeId;
        string proposedContent;
        address proposer;
        uint256 votingEndTime;
        uint256 positiveVotes;
        uint256 negativeVotes;
        bool executed;
        bool exists;
    }

    mapping(uint256 => Node) public nodes;
    uint256 public nodeCounter;

    mapping(uint256 => Relationship) public relationships;
    uint256 public relationshipCounter;

    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCounter;

    mapping(address => bool) public isContributorRegistry;
    mapping(address => int256) public contributorReputation;

    mapping(uint256 => mapping(address => bool)) public nodeEndorsements; // nodeId => user => endorsed?

    // --- Events ---

    event NodeCreated(uint256 nodeId, string nodeType, address creator);
    event NodeUpdated(uint256 nodeId, address updater);
    event RelationshipCreated(uint256 relationshipId, uint256 sourceNodeId, uint256 targetNodeId, string relationshipType, address creator);
    event RelationshipDeleted(uint256 relationshipId, address deleter);
    event ContributorRegistered(address contributor);
    event ContributorReputationChanged(address contributor, int256 newReputation);
    event NodeEndorsed(uint256 nodeId, address endorser);
    event NodeReported(uint256 nodeId, address reporter, string reason);
    event ProposalCreated(uint256 proposalId, uint256 nodeId, address proposer);
    event ProposalVoted(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId);
    event DonationReceived(uint256 nodeId, address donor, uint256 amount);
    event DonationWithdrawn(uint256 nodeId, address withdrawer, uint256 amount);


    // --- Modifiers ---

    modifier onlyContributor() {
        require(isContributorRegistry[msg.sender], "Only registered contributors can perform this action.");
        _;
    }

    modifier nodeExists(uint256 _nodeId) {
        require(nodes[_nodeId].exists, "Node does not exist.");
        _;
    }

    modifier relationshipExists(uint256 _relationshipId) {
        require(relationships[_relationshipId].exists, "Relationship does not exist.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(proposals[_proposalId].exists, "Proposal does not exist.");
        _;
    }

    modifier proposalNotExecuted(uint256 _proposalId) {
        require(!proposals[_proposalId].executed, "Proposal already executed.");
        _;
    }

    // --- Functions ---

    // 1. Create Node
    function createNode(string memory _nodeType, string memory _nodeContent) public onlyContributor {
        nodeCounter++;
        nodes[nodeCounter] = Node({
            nodeId: nodeCounter,
            nodeType: _nodeType,
            nodeContent: _nodeContent,
            creator: msg.sender,
            creationTimestamp: block.timestamp,
            endorsementCount: 0,
            reputationScore: 0,
            exists: true
        });
        emit NodeCreated(nodeCounter, _nodeType, msg.sender);
        _increaseContributorReputation(msg.sender, 5); // Reward for node creation
    }

    // 2. Get Node Info
    function getNodeInfo(uint256 _nodeId) public view nodeExists(_nodeId) returns (Node memory) {
        return nodes[_nodeId];
    }

    // 3. Update Node Content
    function updateNodeContent(uint256 _nodeId, string memory _newNodeContent) public nodeExists(_nodeId) {
        require(msg.sender == nodes[_nodeId].creator || _isCommunityApprovedUpdater(_nodeId, msg.sender), "Only creator or community-approved updaters can update content directly.");
        nodes[_nodeId].nodeContent = _newNodeContent;
        emit NodeUpdated(_nodeId, msg.sender);
        // Consider reputation changes for node updates
    }

    // 4. Get Node By Type
    function getNodeByType(string memory _nodeType) public view returns (uint256[] memory) {
        uint256[] memory nodeIds = new uint256[](nodeCounter); // Maximum possible size
        uint256 count = 0;
        for (uint256 i = 1; i <= nodeCounter; i++) {
            if (nodes[i].exists && keccak256(abi.encode(nodes[i].nodeType)) == keccak256(abi.encode(_nodeType))) {
                nodeIds[count] = i;
                count++;
            }
        }
        // Resize the array to the actual number of results
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = nodeIds[i];
        }
        return result;
    }

    // 5. Search Nodes By Content
    function searchNodesByContent(string memory _keyword) public view returns (uint256[] memory) {
        uint256[] memory nodeIds = new uint256[](nodeCounter); // Maximum possible size
        uint256 count = 0;
        for (uint256 i = 1; i <= nodeCounter; i++) {
            if (nodes[i].exists && stringContains(nodes[i].nodeContent, _keyword)) {
                nodeIds[count] = i;
                count++;
            }
        }
        // Resize the array to the actual number of results
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = nodeIds[i];
        }
        return result;
    }

    // 6. Endorse Node
    function endorseNode(uint256 _nodeId) public onlyContributor nodeExists(_nodeId) {
        require(!nodeEndorsements[_nodeId][msg.sender], "You have already endorsed this node.");
        nodes[_nodeId].endorsementCount++;
        nodeEndorsements[_nodeId][msg.sender] = true;
        emit NodeEndorsed(_nodeId, msg.sender);
        _increaseContributorReputation(msg.sender, 1); // Small reward for endorsement
        _increaseNodeReputation(_nodeId, 1); // Increase node reputation
    }

    // 7. Get Node Endorsement Count
    function getNodeEndorsementCount(uint256 _nodeId) public view nodeExists(_nodeId) returns (uint256) {
        return nodes[_nodeId].endorsementCount;
    }

    // 8. Report Node
    function reportNode(uint256 _nodeId, string memory _reportReason) public onlyContributor nodeExists(_nodeId) {
        emit NodeReported(_nodeId, msg.sender, _reportReason);
        _decreaseNodeReputation(_nodeId, 1); // Decrease node reputation upon report
        // In a real application, implement a mechanism to review reports and potentially penalize false reporters.
    }

    // 9. Create Relationship
    function createRelationship(uint256 _sourceNodeId, uint256 _targetNodeId, string memory _relationshipType) public onlyContributor nodeExists(_sourceNodeId) nodeExists(_targetNodeId) {
        relationshipCounter++;
        relationships[relationshipCounter] = Relationship({
            relationshipId: relationshipCounter,
            sourceNodeId: _sourceNodeId,
            targetNodeId: _targetNodeId,
            relationshipType: _relationshipType,
            creator: msg.sender,
            creationTimestamp: block.timestamp,
            exists: true
        });
        emit RelationshipCreated(relationshipCounter, _sourceNodeId, _targetNodeId, _relationshipType, msg.sender);
        _increaseContributorReputation(msg.sender, 3); // Reward for relationship creation
    }

    // 10. Get Relationships For Node
    function getRelationshipsForNode(uint256 _nodeId) public view nodeExists(_nodeId) returns (uint256[] memory) {
        uint256[] memory relationshipIds = new uint256[](relationshipCounter); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i <= relationshipCounter; i++) {
            if (relationships[i].exists && (relationships[i].sourceNodeId == _nodeId || relationships[i].targetNodeId == _nodeId)) {
                relationshipIds[count] = i;
                count++;
            }
        }
        // Resize the array
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = relationshipIds[i];
        }
        return result;
    }

    // 11. Get Nodes By Relationship
    function getNodesByRelationship(uint256 _nodeId, string memory _relationshipType) public view nodeExists(_nodeId) returns (uint256[] memory sourceNodes, uint256[] memory targetNodes) {
        uint256[] memory sourceNodeIds = new uint256[](relationshipCounter); // Max size
        uint256[] memory targetNodeIds = new uint256[](relationshipCounter); // Max size
        uint256 sourceCount = 0;
        uint256 targetCount = 0;

        for (uint256 i = 1; i <= relationshipCounter; i++) {
            if (relationships[i].exists && keccak256(abi.encode(relationships[i].relationshipType)) == keccak256(abi.encode(_relationshipType))) {
                if (relationships[i].sourceNodeId == _nodeId) {
                    targetNodeIds[targetCount] = relationships[i].targetNodeId;
                    targetCount++;
                } else if (relationships[i].targetNodeId == _nodeId) {
                    sourceNodeIds[sourceCount] = relationships[i].sourceNodeId;
                    sourceCount++;
                }
            }
        }

        // Resize source nodes array
        sourceNodes = new uint256[](sourceCount);
        for (uint256 i = 0; i < sourceCount; i++) {
            sourceNodes[i] = sourceNodeIds[i];
        }

        // Resize target nodes array
        targetNodes = new uint256[](targetCount);
        for (uint256 i = 0; i < targetCount; i++) {
            targetNodes[i] = targetNodeIds[i];
        }
    }


    // 12. Delete Relationship
    function deleteRelationship(uint256 _relationshipId) public relationshipExists(_relationshipId) {
        require(msg.sender == relationships[_relationshipId].creator || _isCommunityApprovedDeleter(_relationshipId, msg.sender), "Only creator or community-approved deleters can delete relationships.");
        relationships[_relationshipId].exists = false;
        emit RelationshipDeleted(_relationshipId, msg.sender);
        // Consider reputation changes for relationship deletion
    }

    // 13. Register Contributor
    function registerContributor() public {
        require(!isContributorRegistry[msg.sender], "Already registered as a contributor.");
        isContributorRegistry[msg.sender] = true;
        contributorReputation[msg.sender] = 0; // Initial reputation
        emit ContributorRegistered(msg.sender);
    }

    // 14. Is Contributor
    function isContributor(address _user) public view returns (bool) {
        return isContributorRegistry[_user];
    }

    // 15. Get Contributor Reputation
    function getContributorReputation(address _contributor) public view returns (int256) {
        return contributorReputation[_contributor];
    }

    // 16. Upvote Contributor
    function upvoteContributor(address _contributor) public onlyContributor {
        require(msg.sender != _contributor, "Cannot upvote yourself.");
        _increaseContributorReputation(_contributor, 2); // Reward for being upvoted
        emit ContributorReputationChanged(_contributor, contributorReputation[_contributor]);
    }

    // 17. Downvote Contributor
    function downvoteContributor(address _contributor) public onlyContributor {
        require(msg.sender != _contributor, "Cannot downvote yourself.");
        _decreaseContributorReputation(_contributor, 2); // Penalty for being downvoted
        emit ContributorReputationChanged(_contributor, contributorReputation[_contributor]);
        // In a real application, consider adding limits to downvoting and potential penalties for abuse.
    }

    // 18. Propose Node Update
    function proposeNodeUpdate(uint256 _nodeId, string memory _proposedContent) public onlyContributor nodeExists(_nodeId) {
        proposalCounter++;
        proposals[proposalCounter] = Proposal({
            proposalId: proposalCounter,
            nodeId: _nodeId,
            proposedContent: _proposedContent,
            proposer: msg.sender,
            votingEndTime: block.timestamp + 7 days, // Example voting period
            positiveVotes: 0,
            negativeVotes: 0,
            executed: false,
            exists: true
        });
        emit ProposalCreated(proposalCounter, _nodeId, msg.sender);
    }

    // 19. Vote On Proposal
    function voteOnProposal(uint256 _proposalId, bool _vote) public onlyContributor proposalExists(_proposalId) proposalNotExecuted(_proposalId) {
        require(block.timestamp <= proposals[_proposalId].votingEndTime, "Voting period has ended.");
        // Prevent double voting (can be implemented with mapping if needed for stricter control)
        if (_vote) {
            proposals[_proposalId].positiveVotes++;
        } else {
            proposals[_proposalId].negativeVotes++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _vote);
    }

    // 20. Execute Proposal
    function executeProposal(uint256 _proposalId) public proposalExists(_proposalId) proposalNotExecuted(_proposalId) {
        require(block.timestamp > proposals[_proposalId].votingEndTime, "Voting period has not ended yet.");
        require(proposals[_proposalId].positiveVotes > proposals[_proposalId].negativeVotes, "Proposal not approved by community.");

        proposals[_proposalId].executed = true;
        nodes[proposals[_proposalId].nodeId].nodeContent = proposals[_proposalId].proposedContent;
        emit ProposalExecuted(_proposalId);
        emit NodeUpdated(proposals[_proposalId].nodeId, address(this)); // Updated by contract on proposal execution
    }

    // 21. Donate To Node
    function donateToNode(uint256 _nodeId) public payable nodeExists(_nodeId) {
        require(msg.value > 0, "Donation amount must be greater than zero.");
        address payable nodeCreatorPayable = payable(nodes[_nodeId].creator); // Assuming creator benefits. Can be modified for different reward mechanisms.
        payable(address(this)).transfer(msg.value); // Contract holds donations temporarily (for potential future features like node maintenance funds)
        emit DonationReceived(_nodeId, msg.sender, msg.value);
    }

    // 22. Withdraw Node Donations
    function withdrawNodeDonations(uint256 _nodeId) public nodeExists(_nodeId) {
        require(msg.sender == nodes[_nodeId].creator, "Only node creator can withdraw donations.");
        uint256 balance = address(this).balance; // Get contract balance (all donations for simplicity in this example)
        require(balance > 0, "No donations to withdraw.");
        payable(nodes[_nodeId].creator).transfer(balance); // Transfer all contract balance to creator
        emit DonationWithdrawn(_nodeId, msg.sender, balance);
    }


    // --- Internal Helper Functions ---

    function _increaseContributorReputation(address _contributor, int256 _amount) internal {
        contributorReputation[_contributor] += _amount;
        emit ContributorReputationChanged(_contributor, contributorReputation[_contributor]);
    }

    function _decreaseContributorReputation(address _contributor, int256 _amount) internal {
        contributorReputation[_contributor] -= _amount;
        emit ContributorReputationChanged(_contributor, contributorReputation[_contributor]);
    }

    function _increaseNodeReputation(uint256 _nodeId, int256 _amount) internal nodeExists(_nodeId) {
        nodes[_nodeId].reputationScore += _amount;
    }

    function _decreaseNodeReputation(uint256 _nodeId, int256 _amount) internal nodeExists(_nodeId) {
        nodes[_nodeId].reputationScore -= _amount;
    }

    function _isCommunityApprovedUpdater(uint256 _nodeId, address _updater) internal view nodeExists(_nodeId) returns (bool) {
        // Example: Community approval logic could be based on contributor reputation, voting, or other mechanisms.
        // For simplicity, this example always returns false, requiring direct creator update or proposal for changes.
        return false;
    }

     function _isCommunityApprovedDeleter(uint256 _relationshipId, address _deleter) internal view relationshipExists(_relationshipId) returns (bool) {
        // Example: Community approval logic for relationship deletion.
        // For simplicity, this example always returns false, requiring relationship creator deletion or a proposal system for deletion.
        return false;
    }

    // Simple string contains function (for demonstration, can be replaced with more efficient library if needed)
    function stringContains(string memory _haystack, string memory _needle) internal pure returns (bool) {
        if (bytes(_needle).length == 0) {
            return true; // Empty needle is always found
        }
        if (bytes(_haystack).length < bytes(_needle).length) {
            return false; // Needle longer than haystack, cannot be found
        }
        for (uint256 i = 0; i <= bytes(_haystack).length - bytes(_needle).length; i++) {
            bool match = true;
            for (uint256 j = 0; j < bytes(_needle).length; j++) {
                if (bytes(_haystack)[i + j] != bytes(_needle)[j]) {
                    match = false;
                    break;
                }
            }
            if (match) {
                return true;
            }
        }
        return false;
    }
}
```