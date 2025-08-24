```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SynapticNexus
 * @dev A decentralized knowledge graph and AI-driven research collaboration platform.
 *      This contract enables researchers to contribute knowledge nodes, establish relationships,
 *      propose and validate hypotheses through a prediction market, and fund "AI Agents"
 *      for exploration. It incorporates a unique "Synergy Score" for reputation,
 *      and advanced DAO-based governance for evolving the knowledge base.
 *      The design prioritizes verifiable contributions, collective intelligence,
 *      and an extensible architecture for future AI/oracle integration.
 *
 * Outline:
 * 1.  Interfaces
 * 2.  Events
 * 3.  Errors
 * 4.  Data Structures (Enums, Structs, Mappings)
 * 5.  State Variables
 * 6.  Constructor
 * 7.  Modifiers
 * 8.  Emergency & Ownership Functions
 * 9.  Researcher Profile Management (SBT-like)
 * 10. Knowledge Graph Management (Nodes & Edges)
 * 11. Hypothesis Generation & Validation
 * 12. Synergy Scoring & Reputation & Dispute
 * 13. Agent Grants & Funding (DeSci/AI-like)
 * 14. Decentralized Autonomous Organization (DAO) Governance
 * 15. External Oracle Integration
 * 16. Utility & View Functions
 *
 * Function Summary:
 *
 * Researcher Profile Management:
 * - registerResearcher(): Creates a unique, non-transferable researcher profile (SBT-like).
 * - updateResearcherProfile(): Allows researchers to update their public profile metadata.
 *
 * Knowledge Graph Management:
 * - addKnowledgeNode(): Adds a new data point or concept to the graph.
 * - linkKnowledgeNodes(): Establishes a directional relationship between two existing nodes.
 * - updateNodeContent(): Proposes and updates the content of an existing knowledge node, subject to governance.
 * - proposeNodeMerge(): Initiates a governance proposal to merge two redundant or similar nodes.
 * - voteOnNodeMerge(): Allows DAO members to vote on node merge proposals.
 * - finalizeNodeMerge(): Executes the node merge if the proposal passes.
 * - proposeNodeDeprecation(): Initiates a proposal to mark a node as deprecated due to obsolescence or inaccuracy.
 * - voteOnNodeDeprecation(): Allows DAO members to vote on node deprecation proposals.
 * - finalizeNodeDeprecation(): Marks a node as deprecated if the proposal passes.
 *
 * Hypothesis Generation & Validation:
 * - proposeHypothesis(): Submits a new research hypothesis linked to specific knowledge nodes.
 * - stakeOnHypothesisValidity(): Participants stake ETH, betting on the True/False validity of a hypothesis.
 * - resolveHypothesis(): Finalizes the status of a hypothesis based on prediction market consensus or oracle input.
 * - claimHypothesisWinnings(): Allows successful stakers to claim their ETH rewards.
 *
 * Synergy Scoring & Reputation & Dispute:
 * - submitPeerReview(): Allows researchers to review contributions, influencing Synergy Scores.
 * - reportContentDispute(): Allows a researcher to dispute content or a review, initiating a governance vote.
 * - finalizeContentDispute(): Resolves a content dispute based on governance vote, potentially affecting Synergy Scores.
 * - getSynergyScore(): Retrieves the current "Synergy Score" for a given researcher.
 *
 * Agent Grants & Funding:
 * - requestAgentGrant(): Proposes a project for an "AI Agent" (or human agent) to explore a specific topic/node.
 * - voteOnAgentGrant(): DAO members vote on agent grant proposals.
 * - distributeAgentGrant(): Disburses ETH funds to approved agent grant projects.
 * - submitAgentReport(): An agent submits findings, potentially updating the knowledge graph or hypotheses.
 *
 * DAO Governance:
 * - proposeGovernanceChange(): Initiates a proposal for system-wide parameter changes or upgrades.
 * - voteOnGovernanceChange(): DAO members vote on governance proposals.
 * - executeGovernanceChange(): Implements a governance proposal that has successfully passed.
 *
 * External Oracle & Utilities:
 * - setOracleAddress(): Sets or updates the address of the external oracle for truth resolution.
 * - withdrawFunds(): Allows the owner/DAO to withdraw accumulated fees or unspent funds.
 * - emergencyPause(): Pauses critical contract functions in an emergency.
 * - unpause(): Unpauses the contract.
 * - getResearcherDetails(): Retrieves detailed information about a researcher.
 * - getNodeDetails(): Retrieves detailed information about a knowledge node.
 * - getHypothesisDetails(): Retrieves detailed information about a hypothesis.
 * - getGrantDetails(): Retrieves detailed information about an agent grant.
 */

interface INexusOracle {
    function getHypothesisTruth(uint256 hypothesisId) external view returns (bool, bool); // (isResolved, isTrue)
    function getDisputeResolution(uint256 disputeId) external view returns (bool, bool); // (isResolved, isChallengerWinning)
}

contract SynapticNexus {

    /* ============ Events ============ */
    event ResearcherRegistered(address indexed researcher, string name);
    event ResearcherProfileUpdated(address indexed researcher, string newName);

    event KnowledgeNodeAdded(uint256 indexed nodeId, bytes32 contentHash, address indexed contributor);
    event KnowledgeNodeLinked(uint256 indexed edgeId, uint256 indexed fromNodeId, uint256 indexed toNodeId, string relationshipType);
    event NodeContentUpdated(uint256 indexed nodeId, bytes32 newContentHash, address indexed updater);
    event NodeMergeProposed(uint256 indexed proposalId, uint256 indexed nodeToMerge, uint256 indexed targetNode);
    event NodeMerged(uint256 indexed originalNodeId, uint256 indexed mergedToNodeId);
    event NodeDeprecationProposed(uint256 indexed proposalId, uint256 indexed nodeId);
    event NodeDeprecationFinalized(uint256 indexed nodeId, bool deprecated);

    event HypothesisProposed(uint256 indexed hypothesisId, address indexed proposer, bytes32 statementHash);
    event HypothesisStaked(uint256 indexed hypothesisId, address indexed staker, bool supportsTrue, uint256 amount);
    event HypothesisResolved(uint256 indexed hypothesisId, bool isTrue);
    event HypothesisWinningsClaimed(uint256 indexed hypothesisId, address indexed winner, uint256 amount);

    event PeerReviewSubmitted(uint256 indexed reviewId, address indexed reviewer, address indexed reviewedResearcher, uint256 nodeId, int256 scoreChange);
    event ContentDisputeProposed(uint256 indexed disputeId, address indexed challenger, uint256 indexed targetNodeIdOrReviewId, bool isNodeDispute);
    event ContentDisputeFinalized(uint256 indexed disputeId, bool challengerWon, address indexed penalizedAddress, int256 scoreChange);

    event AgentGrantRequested(uint256 indexed grantId, address indexed proposer, uint256 targetNodeId, uint256 amount);
    event AgentGrantApproved(uint256 indexed grantId, uint256 amount);
    event AgentGrantDistributed(uint256 indexed grantId, address indexed recipient, uint256 amount);
    event AgentReportSubmitted(uint256 indexed grantId, bytes32 reportHash);

    event GovernanceProposalProposed(uint256 indexed proposalId, address indexed proposer, string description);
    event GovernanceProposalVoted(uint256 indexed proposalId, address indexed voter, bool supports);
    event GovernanceProposalExecuted(uint256 indexed proposalId);

    event OracleAddressSet(address indexed oldAddress, address indexed newAddress);
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event Paused(address account);
    event Unpaused(address account);

    /* ============ Errors ============ */
    error NotResearcher();
    error ResearcherAlreadyRegistered();
    error ResearcherNotFound();
    error NodeNotFound();
    error EdgeNotFound();
    error NodeAlreadyDeprecated();
    error NodeNotDeprecated();
    error NodeAlreadyMerged();
    error NodeCannotBeMergedToSelf();
    error InvalidNodeForMerge();
    error InsufficientBalance();
    error HypothesisNotFound();
    error HypothesisAlreadyResolved();
    error HypothesisNotResolved();
    error StakingPeriodEnded();
    error AlreadyStakedOnHypothesis();
    error NoWinningsToClaim();
    error NotEnoughVotes();
    error ProposalNotFound();
    error ProposalAlreadyVoted();
    error ProposalNotYetPassed();
    error ProposalAlreadyExecuted();
    error InvalidProposalState();
    error GrantNotFound();
    error GrantAlreadyApprovedOrRejected();
    error GrantNotApproved();
    error GrantAlreadyDistributed();
    error CallerNotOwner();
    error ContractPaused();
    error ContractNotPaused();
    error InvalidOracleAddress();
    error DisputeNotFound();
    error DisputeAlreadyResolved();
    error OracleNotResolved();
    error InvalidReview();

    /* ============ Enums ============ */
    enum HypothesisStatus { Pending, ResolvedTrue, ResolvedFalse }
    enum ProposalStatus { Pending, Succeeded, Failed, Executed }
    enum GrantStatus { Proposed, Approved, Rejected, Completed }
    enum VoteType { For, Against }

    /* ============ Structs ============ */

    struct Researcher {
        string name;
        string bio;
        uint256 synergyScore; // Reputation score
        bool registered;
    }

    struct KnowledgeNode {
        bytes32 contentHash; // IPFS/Arweave hash of the node's content
        address contributor;
        uint256 timestamp;
        bool isDeprecated;
        bool isMerged;
        uint256 mergedToId; // If merged, points to the new node
    }

    struct KnowledgeEdge {
        uint256 fromNodeId;
        uint256 toNodeId;
        string relationshipType;
        address contributor;
        uint256 timestamp;
    }

    struct Hypothesis {
        address proposer;
        bytes32 statementHash; // IPFS/Arweave hash of the hypothesis statement
        uint256[] linkedNodes; // Nodes that this hypothesis references
        HypothesisStatus status;
        uint256 predictionMarketEndTime;
        uint256 trueStakes;
        uint256 falseStakes;
    }

    struct HypothesisStakes {
        uint256 trueAmount;
        uint256 falseAmount;
    }

    struct AgentGrant {
        address proposer;
        uint256 targetNodeId;
        uint256 amount; // ETH amount
        GrantStatus status;
        bytes32 reportHash; // Hash of the final report
        uint256 voteFor;
        uint256 voteAgainst;
        mapping(address => bool) hasVoted;
    }

    struct GovernanceProposal {
        address proposer;
        string description; // Description of the proposed change
        bytes callData; // Encoded function call for execution
        address targetContract; // Contract to call
        ProposalStatus status;
        uint256 voteFor;
        uint256 voteAgainst;
        uint256 creationTime;
        mapping(address => bool) hasVoted;
    }

    struct MergeProposal {
        uint256 nodeToMerge;
        uint256 targetNode;
        ProposalStatus status;
        uint256 voteFor;
        uint256 voteAgainst;
        uint256 creationTime;
        mapping(address => bool) hasVoted;
    }

    struct DeprecationProposal {
        uint256 nodeId;
        ProposalStatus status;
        uint256 voteFor;
        uint256 voteAgainst;
        uint256 creationTime;
        mapping(address => bool) hasVoted;
    }

    struct NodeContentUpdateProposal {
        uint256 nodeId;
        bytes32 newContentHash;
        address proposer;
        ProposalStatus status;
        uint256 voteFor;
        uint256 voteAgainst;
        uint256 creationTime;
        mapping(address => bool) hasVoted;
    }

    struct ContentDispute {
        address challenger;
        uint256 targetId; // NodeId or reviewId
        bool isNodeDispute; // True if disputing node, false if disputing review
        ProposalStatus status;
        uint256 voteForChallenger; // Votes supporting the challenger
        uint256 voteAgainstChallenger; // Votes supporting the original content/review
        uint256 creationTime;
        mapping(address => bool) hasVoted;
    }

    /* ============ State Variables ============ */

    // Contract Ownership & Pausability
    address private _owner;
    bool private _paused;

    // Oracle for external truth resolution
    INexusOracle private _nexusOracle;

    // Researcher Data (SBT-like, non-transferable by design)
    mapping(address => Researcher) public researchers;
    address[] public registeredResearchers; // To iterate or count

    // Knowledge Graph
    uint256 public nextNodeId;
    mapping(uint256 => KnowledgeNode) public knowledgeNodes;
    uint256 public nextEdgeId;
    mapping(uint256 => KnowledgeEdge) public knowledgeEdges;

    // Hypothesis & Prediction Market
    uint256 public nextHypothesisId;
    mapping(uint256 => Hypothesis) public hypotheses;
    mapping(uint256 => mapping(address => HypothesisStakes)) public hypothesisStakes; // hypothesisId => staker => stakes

    // Agent Grants
    uint256 public nextGrantId;
    mapping(uint256 => AgentGrant) public agentGrants;
    uint256 public constant MIN_GRANT_VOTES = 5; // Minimum votes for a grant to pass

    // Governance
    uint256 public nextGovernanceProposalId;
    mapping(uint256 => GovernanceProposal) public governanceProposals;

    uint256 public nextMergeProposalId;
    mapping(uint256 => MergeProposal) public mergeProposals;

    uint256 public nextDeprecationProposalId;
    mapping(uint256 => DeprecationProposal) public deprecationProposals;

    uint256 public nextNodeUpdateProposalId;
    mapping(uint256 => NodeContentUpdateProposal) public nodeUpdateProposals;

    uint256 public nextDisputeId;
    mapping(uint256 => ContentDispute) public contentDisputes;

    uint256 public constant MIN_GOVERNANCE_VOTES = 10; // Minimum votes for a governance proposal to pass
    uint256 public constant MIN_MERGE_VOTES = 5;
    uint256 public constant MIN_DEPRECATION_VOTES = 5;
    uint256 public constant MIN_NODE_UPDATE_VOTES = 5;
    uint256 public constant MIN_DISPUTE_VOTES = 5;

    uint256 public constant VOTING_PERIOD_SECONDS = 7 days; // 7 days for proposals

    // Configuration
    uint256 public constant HYPOTHESIS_PREDICTION_PERIOD = 30 days; // Time to stake on a hypothesis

    /* ============ Constructor ============ */

    constructor() {
        _owner = msg.sender;
        nextNodeId = 1;
        nextEdgeId = 1;
        nextHypothesisId = 1;
        nextGrantId = 1;
        nextGovernanceProposalId = 1;
        nextMergeProposalId = 1;
        nextDeprecationProposalId = 1;
        nextNodeUpdateProposalId = 1;
        nextDisputeId = 1;
    }

    /* ============ Modifiers ============ */

    modifier onlyOwner() {
        if (msg.sender != _owner) revert CallerNotOwner();
        _;
    }

    modifier whenNotPaused() {
        if (_paused) revert ContractPaused();
        _;
    }

    modifier whenPaused() {
        if (!_paused) revert ContractNotPaused();
        _;
    }

    modifier onlyResearcher() {
        if (!researchers[msg.sender].registered) revert NotResearcher();
        _;
    }

    modifier onlyDAO() {
        // For simplicity, DAO members are considered all registered researchers.
        // In a more complex DAO, this would check token holdings or specific roles.
        if (!researchers[msg.sender].registered) revert NotResearcher();
        _;
    }

    // Fallback function to receive Ether for grants/stakes
    receive() external payable {}

    /* ============ Emergency & Ownership Functions ============ */

    function emergencyPause() external onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    /* ============ Researcher Profile Management (SBT-like) ============ */

    /**
     * @dev Registers the caller as a researcher with a unique profile.
     *      This profile is non-transferable (soulbound-like) by virtue of being tied to `msg.sender`.
     * @param _name The public name of the researcher.
     * @param _bio A short biography or description of the researcher's interests.
     */
    function registerResearcher(string calldata _name, string calldata _bio) external whenNotPaused {
        if (researchers[msg.sender].registered) revert ResearcherAlreadyRegistered();

        researchers[msg.sender] = Researcher({
            name: _name,
            bio: _bio,
            synergyScore: 100, // Initial score
            registered: true
        });
        registeredResearchers.push(msg.sender); // Add to list for iteration/counting
        emit ResearcherRegistered(msg.sender, _name);
    }

    /**
     * @dev Allows a registered researcher to update their profile information.
     * @param _newName The new public name.
     * @param _newBio The new biography.
     */
    function updateResearcherProfile(string calldata _newName, string calldata _newBio) external onlyResearcher whenNotPaused {
        researchers[msg.sender].name = _newName;
        researchers[msg.sender].bio = _newBio;
        emit ResearcherProfileUpdated(msg.sender, _newName);
    }

    /* ============ Knowledge Graph Management (Nodes & Edges) ============ */

    /**
     * @dev Adds a new knowledge node to the graph.
     * @param _contentHash IPFS/Arweave hash pointing to the node's content.
     */
    function addKnowledgeNode(bytes32 _contentHash) external onlyResearcher whenNotPaused returns (uint256) {
        uint256 nodeId = nextNodeId++;
        knowledgeNodes[nodeId] = KnowledgeNode({
            contentHash: _contentHash,
            contributor: msg.sender,
            timestamp: block.timestamp,
            isDeprecated: false,
            isMerged: false,
            mergedToId: 0
        });
        emit KnowledgeNodeAdded(nodeId, _contentHash, msg.sender);
        return nodeId;
    }

    /**
     * @dev Links two existing knowledge nodes with a specified relationship.
     * @param _fromNodeId The ID of the starting node.
     * @param _toNodeId The ID of the ending node.
     * @param _relationshipType A string describing the relationship (e.g., "expandsOn", "contradicts", "supports").
     */
    function linkKnowledgeNodes(uint256 _fromNodeId, uint256 _toNodeId, string calldata _relationshipType) external onlyResearcher whenNotPaused returns (uint256) {
        if (knowledgeNodes[_fromNodeId].contributor == address(0) || knowledgeNodes[_fromNodeId].isDeprecated) revert NodeNotFound();
        if (knowledgeNodes[_toNodeId].contributor == address(0) || knowledgeNodes[_toNodeId].isDeprecated) revert NodeNotFound();
        if (_fromNodeId == _toNodeId) revert InvalidNodeForMerge(); // Cannot link a node to itself

        uint256 edgeId = nextEdgeId++;
        knowledgeEdges[edgeId] = KnowledgeEdge({
            fromNodeId: _fromNodeId,
            toNodeId: _toNodeId,
            relationshipType: _relationshipType,
            contributor: msg.sender,
            timestamp: block.timestamp
        });
        emit KnowledgeNodeLinked(edgeId, _fromNodeId, _toNodeId, _relationshipType);
        return edgeId;
    }

    /**
     * @dev Proposes an update to an existing knowledge node's content, subject to DAO governance.
     * @param _nodeId The ID of the node to update.
     * @param _newContentHash The IPFS/Arweave hash of the new content.
     */
    function updateNodeContent(uint256 _nodeId, bytes32 _newContentHash) external onlyResearcher whenNotPaused returns (uint256) {
        if (knowledgeNodes[_nodeId].contributor == address(0)) revert NodeNotFound();
        if (knowledgeNodes[_nodeId].isDeprecated) revert NodeAlreadyDeprecated();

        uint256 proposalId = nextNodeUpdateProposalId++;
        nodeUpdateProposals[proposalId] = NodeContentUpdateProposal({
            nodeId: _nodeId,
            newContentHash: _newContentHash,
            proposer: msg.sender,
            status: ProposalStatus.Pending,
            voteFor: 0,
            voteAgainst: 0,
            creationTime: block.timestamp,
            hasVoted: new mapping(address => bool)
        });
        // This implicitly means the *proposer* cannot vote initially, but it can be changed.
        emit GovernanceProposalProposed(proposalId, msg.sender, string(abi.encodePacked("Node Content Update for Node #", Strings.toString(_nodeId))));
        return proposalId;
    }

    /**
     * @dev Allows DAO members to vote on a node content update proposal.
     * @param _proposalId The ID of the update proposal.
     * @param _supports True for "For", False for "Against".
     */
    function voteOnNodeContentUpdate(uint256 _proposalId, bool _supports) external onlyDAO whenNotPaused {
        NodeContentUpdateProposal storage proposal = nodeUpdateProposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound();
        if (proposal.status != ProposalStatus.Pending) revert InvalidProposalState();
        if (proposal.hasVoted[msg.sender]) revert ProposalAlreadyVoted();

        proposal.hasVoted[msg.sender] = true;
        if (_supports) {
            proposal.voteFor++;
        } else {
            proposal.voteAgainst++;
        }
        emit GovernanceProposalVoted(_proposalId, msg.sender, _supports);
    }

    /**
     * @dev Finalizes a node content update proposal, executing it if successful.
     * @param _proposalId The ID of the update proposal.
     */
    function finalizeNodeContentUpdate(uint256 _proposalId) external onlyDAO whenNotPaused {
        NodeContentUpdateProposal storage proposal = nodeUpdateProposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound();
        if (proposal.status != ProposalStatus.Pending) revert InvalidProposalState();
        if (block.timestamp < proposal.creationTime + VOTING_PERIOD_SECONDS) revert ProposalNotYetPassed();

        if (proposal.voteFor > proposal.voteAgainst && proposal.voteFor >= MIN_NODE_UPDATE_VOTES) {
            knowledgeNodes[proposal.nodeId].contentHash = proposal.newContentHash;
            proposal.status = ProposalStatus.Executed;
            emit NodeContentUpdated(proposal.nodeId, proposal.newContentHash, proposal.proposer);
        } else {
            proposal.status = ProposalStatus.Failed;
        }
        emit GovernanceProposalExecuted(_proposalId);
    }


    /**
     * @dev Proposes to merge two knowledge nodes into one, subject to DAO governance.
     *      The nodeToMerge will be marked as merged and point to targetNode.
     * @param _nodeToMerge The ID of the node to be merged.
     * @param _targetNode The ID of the node it should be merged into.
     */
    function proposeNodeMerge(uint256 _nodeToMerge, uint256 _targetNode) external onlyResearcher whenNotPaused returns (uint256) {
        if (knowledgeNodes[_nodeToMerge].contributor == address(0) || knowledgeNodes[_nodeToMerge].isDeprecated || knowledgeNodes[_nodeToMerge].isMerged) revert InvalidNodeForMerge();
        if (knowledgeNodes[_targetNode].contributor == address(0) || knowledgeNodes[_targetNode].isDeprecated) revert InvalidNodeForMerge();
        if (_nodeToMerge == _targetNode) revert NodeCannotBeMergedToSelf();

        uint256 proposalId = nextMergeProposalId++;
        mergeProposals[proposalId] = MergeProposal({
            nodeToMerge: _nodeToMerge,
            targetNode: _targetNode,
            status: ProposalStatus.Pending,
            voteFor: 0,
            voteAgainst: 0,
            creationTime: block.timestamp,
            hasVoted: new mapping(address => bool)
        });
        emit GovernanceProposalProposed(proposalId, msg.sender, string(abi.encodePacked("Merge Node #", Strings.toString(_nodeToMerge), " into #", Strings.toString(_targetNode))));
        return proposalId;
    }

    /**
     * @dev Allows DAO members to vote on a node merge proposal.
     * @param _proposalId The ID of the merge proposal.
     * @param _supports True for "For", False for "Against".
     */
    function voteOnNodeMerge(uint256 _proposalId, bool _supports) external onlyDAO whenNotPaused {
        MergeProposal storage proposal = mergeProposals[_proposalId];
        if (proposal.nodeToMerge == 0) revert ProposalNotFound();
        if (proposal.status != ProposalStatus.Pending) revert InvalidProposalState();
        if (proposal.hasVoted[msg.sender]) revert ProposalAlreadyVoted();

        proposal.hasVoted[msg.sender] = true;
        if (_supports) {
            proposal.voteFor++;
        } else {
            proposal.voteAgainst++;
        }
        emit GovernanceProposalVoted(_proposalId, msg.sender, _supports);
    }

    /**
     * @dev Finalizes a node merge proposal, executing the merge if successful.
     * @param _proposalId The ID of the merge proposal.
     */
    function finalizeNodeMerge(uint256 _proposalId) external onlyDAO whenNotPaused {
        MergeProposal storage proposal = mergeProposals[_proposalId];
        if (proposal.nodeToMerge == 0) revert ProposalNotFound();
        if (proposal.status != ProposalStatus.Pending) revert InvalidProposalState();
        if (block.timestamp < proposal.creationTime + VOTING_PERIOD_SECONDS) revert ProposalNotYetPassed();

        if (proposal.voteFor > proposal.voteAgainst && proposal.voteFor >= MIN_MERGE_VOTES) {
            knowledgeNodes[proposal.nodeToMerge].isMerged = true;
            knowledgeNodes[proposal.nodeToMerge].mergedToId = proposal.targetNode;
            proposal.status = ProposalStatus.Executed;
            emit NodeMerged(proposal.nodeToMerge, proposal.targetNode);
        } else {
            proposal.status = ProposalStatus.Failed;
        }
        emit GovernanceProposalExecuted(_proposalId);
    }

    /**
     * @dev Proposes to deprecate a knowledge node, marking it as outdated or inaccurate. Subject to DAO governance.
     * @param _nodeId The ID of the node to deprecate.
     */
    function proposeNodeDeprecation(uint256 _nodeId) external onlyResearcher whenNotPaused returns (uint256) {
        if (knowledgeNodes[_nodeId].contributor == address(0)) revert NodeNotFound();
        if (knowledgeNodes[_nodeId].isDeprecated) revert NodeAlreadyDeprecated();

        uint256 proposalId = nextDeprecationProposalId++;
        deprecationProposals[proposalId] = DeprecationProposal({
            nodeId: _nodeId,
            status: ProposalStatus.Pending,
            voteFor: 0,
            voteAgainst: 0,
            creationTime: block.timestamp,
            hasVoted: new mapping(address => bool)
        });
        emit GovernanceProposalProposed(proposalId, msg.sender, string(abi.encodePacked("Deprecate Node #", Strings.toString(_nodeId))));
        return proposalId;
    }

    /**
     * @dev Allows DAO members to vote on a node deprecation proposal.
     * @param _proposalId The ID of the deprecation proposal.
     * @param _supports True for "For", False for "Against".
     */
    function voteOnNodeDeprecation(uint256 _proposalId, bool _supports) external onlyDAO whenNotPaused {
        DeprecationProposal storage proposal = deprecationProposals[_proposalId];
        if (proposal.nodeId == 0) revert ProposalNotFound();
        if (proposal.status != ProposalStatus.Pending) revert InvalidProposalState();
        if (proposal.hasVoted[msg.sender]) revert ProposalAlreadyVoted();

        proposal.hasVoted[msg.sender] = true;
        if (_supports) {
            proposal.voteFor++;
        } else {
            proposal.voteAgainst++;
        }
        emit GovernanceProposalVoted(_proposalId, msg.sender, _supports);
    }

    /**
     * @dev Finalizes a node deprecation proposal, marking the node as deprecated if successful.
     * @param _proposalId The ID of the deprecation proposal.
     */
    function finalizeNodeDeprecation(uint256 _proposalId) external onlyDAO whenNotPaused {
        DeprecationProposal storage proposal = deprecationProposals[_proposalId];
        if (proposal.nodeId == 0) revert ProposalNotFound();
        if (proposal.status != ProposalStatus.Pending) revert InvalidProposalState();
        if (block.timestamp < proposal.creationTime + VOTING_PERIOD_SECONDS) revert ProposalNotYetPassed();

        if (proposal.voteFor > proposal.voteAgainst && proposal.voteFor >= MIN_DEPRECATION_VOTES) {
            knowledgeNodes[proposal.nodeId].isDeprecated = true;
            proposal.status = ProposalStatus.Executed;
            emit NodeDeprecationFinalized(proposal.nodeId, true);
        } else {
            proposal.status = ProposalStatus.Failed;
            emit NodeDeprecationFinalized(proposal.nodeId, false);
        }
        emit GovernanceProposalExecuted(_proposalId);
    }

    /* ============ Hypothesis Generation & Validation ============ */

    /**
     * @dev Proposes a new research hypothesis, linking it to relevant knowledge nodes.
     * @param _statementHash IPFS/Arweave hash of the hypothesis statement.
     * @param _linkedNodes An array of node IDs that this hypothesis references.
     */
    function proposeHypothesis(bytes32 _statementHash, uint256[] calldata _linkedNodes) external onlyResearcher whenNotPaused returns (uint256) {
        // Basic validation for linked nodes
        for (uint256 i = 0; i < _linkedNodes.length; i++) {
            if (knowledgeNodes[_linkedNodes[i]].contributor == address(0)) revert NodeNotFound();
        }

        uint256 hypothesisId = nextHypothesisId++;
        hypotheses[hypothesisId] = Hypothesis({
            proposer: msg.sender,
            statementHash: _statementHash,
            linkedNodes: _linkedNodes,
            status: HypothesisStatus.Pending,
            predictionMarketEndTime: block.timestamp + HYPOTHESIS_PREDICTION_PERIOD,
            trueStakes: 0,
            falseStakes: 0
        });
        emit HypothesisProposed(hypothesisId, msg.sender, _statementHash);
        return hypothesisId;
    }

    /**
     * @dev Allows participants to stake ETH on whether a hypothesis is True or False.
     * @param _hypothesisId The ID of the hypothesis to stake on.
     * @param _supportsTrue True if staking for the hypothesis being true, False otherwise.
     */
    function stakeOnHypothesisValidity(uint256 _hypothesisId, bool _supportsTrue) external payable whenNotPaused {
        Hypothesis storage hypothesis = hypotheses[_hypothesisId];
        if (hypothesis.proposer == address(0)) revert HypothesisNotFound();
        if (hypothesis.status != HypothesisStatus.Pending) revert HypothesisAlreadyResolved();
        if (block.timestamp >= hypothesis.predictionMarketEndTime) revert StakingPeriodEnded();
        if (msg.value == 0) revert InsufficientBalance();

        HypothesisStakes storage stakerStakes = hypothesisStakes[_hypothesisId][msg.sender];
        if (_supportsTrue) {
            stakerStakes.trueAmount += msg.value;
            hypothesis.trueStakes += msg.value;
        } else {
            stakerStakes.falseAmount += msg.value;
            hypothesis.falseStakes += msg.value;
        }
        emit HypothesisStaked(_hypothesisId, msg.sender, _supportsTrue, msg.value);
    }

    /**
     * @dev Resolves a hypothesis based on oracle input after the prediction market ends.
     *      Only the contract owner or a designated DAO member can trigger this using oracle data.
     * @param _hypothesisId The ID of the hypothesis to resolve.
     */
    function resolveHypothesis(uint256 _hypothesisId) external onlyDAO whenNotPaused {
        Hypothesis storage hypothesis = hypotheses[_hypothesisId];
        if (hypothesis.proposer == address(0)) revert HypothesisNotFound();
        if (hypothesis.status != HypothesisStatus.Pending) revert HypothesisAlreadyResolved();
        if (block.timestamp < hypothesis.predictionMarketEndTime) revert StakingPeriodEnded(); // Ensure staking period is over

        (bool isResolved, bool isTrue) = _nexusOracle.getHypothesisTruth(_hypothesisId);
        if (!isResolved) revert OracleNotResolved(); // Oracle has not yet provided a resolution

        hypothesis.status = isTrue ? HypothesisStatus.ResolvedTrue : HypothesisStatus.ResolvedFalse;
        
        // Adjust proposer's synergy score based on resolution
        if (isTrue) {
            researchers[hypothesis.proposer].synergyScore += 10; // Reward successful hypothesis
        } else {
            researchers[hypothesis.proposer].synergyScore -= 5; // Penalize failed hypothesis
        }
        
        emit HypothesisResolved(_hypothesisId, isTrue);
    }

    /**
     * @dev Allows stakers on a resolved hypothesis to claim their winnings.
     *      Winners split the total pool of the losing side.
     * @param _hypothesisId The ID of the hypothesis.
     */
    function claimHypothesisWinnings(uint256 _hypothesisId) external whenNotPaused {
        Hypothesis storage hypothesis = hypotheses[_hypothesisId];
        if (hypothesis.proposer == address(0)) revert HypothesisNotFound();
        if (hypothesis.status == HypothesisStatus.Pending) revert HypothesisNotResolved();

        HypothesisStakes storage stakerStakes = hypothesisStakes[_hypothesisId][msg.sender];
        uint256 winnings = 0;
        uint256 stake = 0;

        if (hypothesis.status == HypothesisStatus.ResolvedTrue) {
            stake = stakerStakes.trueAmount;
            if (stake > 0 && hypothesis.trueStakes > 0) {
                // Winning true stakers get their stake back + a share of false stakes
                winnings = stake + (stake * hypothesis.falseStakes / hypothesis.trueStakes);
            }
        } else { // ResolvedFalse
            stake = stakerStakes.falseAmount;
            if (stake > 0 && hypothesis.falseStakes > 0) {
                // Winning false stakers get their stake back + a share of true stakes
                winnings = stake + (stake * hypothesis.trueStakes / hypothesis.falseStakes);
            }
        }

        if (winnings == 0) revert NoWinningsToClaim();

        // Zero out stakes to prevent double claiming
        stakerStakes.trueAmount = 0;
        stakerStakes.falseAmount = 0;

        (bool success,) = msg.sender.call{value: winnings}("");
        if (!success) revert InsufficientBalance(); // Should not happen if previous checks pass
        emit HypothesisWinningsClaimed(_hypothesisId, msg.sender, winnings);
    }

    /* ============ Synergy Scoring & Reputation & Dispute ============ */

    /**
     * @dev Allows a researcher to submit a peer review for another researcher's contribution (a node).
     *      This influences the reviewed researcher's Synergy Score.
     * @param _reviewedResearcher The address of the researcher being reviewed.
     * @param _nodeId The ID of the node being reviewed.
     * @param _scoreChange A signed integer indicating the proposed change to the Synergy Score.
     *                     Positive for good review, negative for critical. (e.g., +5, -3)
     */
    function submitPeerReview(address _reviewedResearcher, uint256 _nodeId, int256 _scoreChange) external onlyResearcher whenNotPaused {
        if (!researchers[_reviewedResearcher].registered) revert ResearcherNotFound();
        if (knowledgeNodes[_nodeId].contributor == address(0)) revert NodeNotFound();
        if (_reviewedResearcher == msg.sender) revert InvalidReview(); // Cannot review self

        researchers[_reviewedResearcher].synergyScore = _calculateNewSynergyScore(researchers[_reviewedResearcher].synergyScore, _scoreChange);
        emit PeerReviewSubmitted(nextDisputeId, msg.sender, _reviewedResearcher, _nodeId, _scoreChange); // Using nextDisputeId as a pseudo-review ID
    }

    /**
     * @dev Proposes a dispute against a node's content or a peer review. Subject to DAO governance.
     *      A successful dispute can result in score changes for the original contributor/reviewer.
     * @param _targetId The ID of the knowledge node or a pseudo-review ID (e.g., from PeerReviewSubmitted event).
     * @param _isNodeDispute True if disputing a node's content, False if disputing a peer review.
     * @param _reasonHash IPFS/Arweave hash of the dispute reason.
     */
    function reportContentDispute(uint256 _targetId, bool _isNodeDispute, bytes32 _reasonHash) external onlyResearcher whenNotPaused returns (uint256) {
        if (_isNodeDispute && knowledgeNodes[_targetId].contributor == address(0)) revert NodeNotFound();
        // For review disputes, _targetId would map to some internal record or simply be used as a reference.
        // For this contract, we'll assume _targetId for a review refers to the `_reviewedResearcher`'s address encoded as uint256 if needed or just metadata.
        // Let's refine: for review dispute, `_targetId` will be the `_reviewedResearcher` address cast to uint256.
        if (!_isNodeDispute && !researchers[address(uint160(_targetId))].registered) revert ResearcherNotFound();

        uint256 disputeId = nextDisputeId++;
        contentDisputes[disputeId] = ContentDispute({
            challenger: msg.sender,
            targetId: _targetId,
            isNodeDispute: _isNodeDispute,
            status: ProposalStatus.Pending,
            voteForChallenger: 0,
            voteAgainstChallenger: 0,
            creationTime: block.timestamp,
            hasVoted: new mapping(address => bool)
        });
        emit ContentDisputeProposed(disputeId, msg.sender, _targetId, _isNodeDispute);
        return disputeId;
    }

    /**
     * @dev Allows DAO members to vote on a content dispute proposal.
     * @param _disputeId The ID of the dispute proposal.
     * @param _supportsChallenger True if supporting the challenger, False if supporting the original content/review.
     */
    function voteOnContentDispute(uint256 _disputeId, bool _supportsChallenger) external onlyDAO whenNotPaused {
        ContentDispute storage dispute = contentDisputes[_disputeId];
        if (dispute.challenger == address(0)) revert DisputeNotFound();
        if (dispute.status != ProposalStatus.Pending) revert DisputeAlreadyResolved();
        if (dispute.hasVoted[msg.sender]) revert ProposalAlreadyVoted();

        dispute.hasVoted[msg.sender] = true;
        if (_supportsChallenger) {
            dispute.voteForChallenger++;
        } else {
            dispute.voteAgainstChallenger++;
        }
        emit GovernanceProposalVoted(_disputeId, msg.sender, _supportsChallenger);
    }

    /**
     * @dev Finalizes a content dispute based on DAO vote or oracle resolution.
     *      Adjusts Synergy Scores accordingly.
     * @param _disputeId The ID of the dispute to finalize.
     */
    function finalizeContentDispute(uint256 _disputeId) external onlyDAO whenNotPaused {
        ContentDispute storage dispute = contentDisputes[_disputeId];
        if (dispute.challenger == address(0)) revert DisputeNotFound();
        if (dispute.status != ProposalStatus.Pending) revert DisputeAlreadyResolved();
        if (block.timestamp < dispute.creationTime + VOTING_PERIOD_SECONDS) revert ProposalNotYetPassed();

        bool challengerWon;
        // Check oracle for dispute resolution, if available and appropriate
        (bool isResolvedByOracle, bool oracleSaysChallengerWon) = _nexusOracle.getDisputeResolution(_disputeId);
        
        if (isResolvedByOracle) {
            challengerWon = oracleSaysChallengerWon;
        } else {
            // Fallback to DAO vote if oracle hasn't resolved or is not configured
            if (dispute.voteForChallenger > dispute.voteAgainstChallenger && dispute.voteForChallenger >= MIN_DISPUTE_VOTES) {
                challengerWon = true;
            } else {
                challengerWon = false;
            }
        }

        address penalizedAddress = address(0);
        int256 scoreChange = 0;

        if (challengerWon) {
            // Challenger wins: Challenger gets points, target (node contributor/reviewed researcher) loses points
            researchers[dispute.challenger].synergyScore = _calculateNewSynergyScore(researchers[dispute.challenger].synergyScore, 5); // Reward challenger
            scoreChange = -10; // Penalty for original contributor/reviewer
            if (dispute.isNodeDispute) {
                penalizedAddress = knowledgeNodes[dispute.targetId].contributor;
            } else { // Dispute over a review
                penalizedAddress = address(uint160(dispute.targetId)); // Assuming targetId for review is the reviewed address
            }
            if (researchers[penalizedAddress].registered) {
                researchers[penalizedAddress].synergyScore = _calculateNewSynergyScore(researchers[penalizedAddress].synergyScore, scoreChange);
            }
        } else {
            // Challenger loses: Challenger loses points
            scoreChange = -5; // Penalty for failed challenge
            researchers[dispute.challenger].synergyScore = _calculateNewSynergyScore(researchers[dispute.challenger].synergyScore, scoreChange);
        }

        dispute.status = ProposalStatus.Executed;
        emit ContentDisputeFinalized(_disputeId, challengerWon, penalizedAddress, scoreChange);
    }

    /**
     * @dev Internal helper to calculate new synergy score, ensuring it doesn't go below zero.
     * @param _currentScore The current score.
     * @param _change The change to apply.
     * @return The new synergy score.
     */
    function _calculateNewSynergyScore(uint256 _currentScore, int256 _change) internal pure returns (uint256) {
        if (_change > 0) {
            return _currentScore + uint256(_change);
        } else {
            return _currentScore > uint256(uint256(-_change)) ? _currentScore - uint256(uint256(-_change)) : 0;
        }
    }

    /**
     * @dev Retrieves the Synergy Score for a given researcher.
     * @param _researcher The address of the researcher.
     * @return The Synergy Score.
     */
    function getSynergyScore(address _researcher) external view returns (uint256) {
        if (!researchers[_researcher].registered) revert ResearcherNotFound();
        return researchers[_researcher].synergyScore;
    }

    /* ============ Agent Grants & Funding (DeSci/AI-like) ============ */

    /**
     * @dev Proposes a project for an "AI Agent" (or human agent) to explore a specific topic/node.
     *      Requires a funding amount in ETH. Subject to DAO governance.
     * @param _targetNodeId The ID of the knowledge node the agent will research.
     * @param _amount The ETH amount requested for the grant.
     * @param _descriptionHash IPFS/Arweave hash of the detailed grant proposal.
     */
    function requestAgentGrant(uint256 _targetNodeId, uint256 _amount, bytes32 _descriptionHash) external onlyResearcher whenNotPaused returns (uint256) {
        if (knowledgeNodes[_targetNodeId].contributor == address(0)) revert NodeNotFound();
        if (_amount == 0) revert InsufficientBalance(); // Must request some amount

        uint256 grantId = nextGrantId++;
        agentGrants[grantId] = AgentGrant({
            proposer: msg.sender,
            targetNodeId: _targetNodeId,
            amount: _amount,
            status: GrantStatus.Proposed,
            reportHash: bytes32(0),
            voteFor: 0,
            voteAgainst: 0,
            hasVoted: new mapping(address => bool)
        });
        emit AgentGrantRequested(grantId, msg.sender, _targetNodeId, _amount);
        return grantId;
    }

    /**
     * @dev Allows DAO members to vote on agent grant proposals.
     * @param _grantId The ID of the grant proposal.
     * @param _supports True for "For", False for "Against".
     */
    function voteOnAgentGrant(uint256 _grantId, bool _supports) external onlyDAO whenNotPaused {
        AgentGrant storage grant = agentGrants[_grantId];
        if (grant.proposer == address(0)) revert GrantNotFound();
        if (grant.status != GrantStatus.Proposed) revert GrantAlreadyApprovedOrRejected();
        if (grant.hasVoted[msg.sender]) revert ProposalAlreadyVoted();

        grant.hasVoted[msg.sender] = true;
        if (_supports) {
            grant.voteFor++;
        } else {
            grant.voteAgainst++;
        }
        emit GovernanceProposalVoted(_grantId, msg.sender, _supports);
    }

    /**
     * @dev Distributes funds for an approved agent grant. Only callable after voting period and if approved.
     *      The contract must hold sufficient ETH to cover the grant.
     * @param _grantId The ID of the grant to distribute.
     */
    function distributeAgentGrant(uint256 _grantId) external onlyDAO whenNotPaused {
        AgentGrant storage grant = agentGrants[_grantId];
        if (grant.proposer == address(0)) revert GrantNotFound();
        if (grant.status != GrantStatus.Proposed) revert GrantAlreadyApprovedOrRejected();
        // Assuming voting period check for grants is implicitly handled by _finalizeGrantVoting
        if (grant.voteFor <= grant.voteAgainst || grant.voteFor < MIN_GRANT_VOTES) {
            grant.status = GrantStatus.Rejected;
            revert GrantNotApproved();
        }

        if (address(this).balance < grant.amount) revert InsufficientBalance();

        grant.status = GrantStatus.Approved; // Mark as approved first
        (bool success,) = grant.proposer.call{value: grant.amount}("");
        if (!success) {
            // If transfer fails, revert status back to approved but not distributed
            // Or implement a retry mechanism. For simplicity, we just revert.
            grant.status = GrantStatus.Proposed; // Revert status on failure
            revert InsufficientBalance(); // Or a more specific error like "TransferFailed"
        }
        grant.status = GrantStatus.Completed; // Mark as completed after distribution
        emit AgentGrantDistributed(_grantId, grant.proposer, grant.amount);
    }

    /**
     * @dev Allows an agent (the original proposer) to submit findings after completing their grant.
     *      This report can influence the knowledge graph or propose new hypotheses.
     * @param _grantId The ID of the completed grant.
     * @param _reportHash IPFS/Arweave hash of the agent's report.
     */
    function submitAgentReport(uint256 _grantId, bytes32 _reportHash) external onlyResearcher whenNotPaused {
        AgentGrant storage grant = agentGrants[_grantId];
        if (grant.proposer == address(0)) revert GrantNotFound();
        if (grant.proposer != msg.sender) revert CallerNotOwner(); // Only the proposer can submit the report
        if (grant.status != GrantStatus.Completed) revert GrantNotApproved(); // Must be a distributed/completed grant
        if (grant.reportHash != bytes32(0)) revert GrantAlreadyDistributed(); // Report already submitted

        grant.reportHash = _reportHash;
        researchers[msg.sender].synergyScore = _calculateNewSynergyScore(researchers[msg.sender].synergyScore, 15); // Reward for submitting report
        emit AgentReportSubmitted(_grantId, _reportHash);

        // Future: Logic here could automatically trigger new node additions, links, or hypothesis proposals
        // based on the report content (e.g., via an oracle or further governance).
    }


    /* ============ Decentralized Autonomous Organization (DAO) Governance ============ */

    /**
     * @dev Proposes a system-wide governance change or upgrade. This can be for parameters or external calls.
     *      Subject to DAO member voting.
     * @param _description A description of the proposed change.
     * @param _targetContract The address of the contract to call (can be this contract).
     * @param _callData The encoded function call to execute if the proposal passes.
     */
    function proposeGovernanceChange(string calldata _description, address _targetContract, bytes calldata _callData) external onlyResearcher whenNotPaused returns (uint256) {
        uint256 proposalId = nextGovernanceProposalId++;
        governanceProposals[proposalId] = GovernanceProposal({
            proposer: msg.sender,
            description: _description,
            callData: _callData,
            targetContract: _targetContract,
            status: ProposalStatus.Pending,
            voteFor: 0,
            voteAgainst: 0,
            creationTime: block.timestamp,
            hasVoted: new mapping(address => bool)
        });
        emit GovernanceProposalProposed(proposalId, msg.sender, _description);
        return proposalId;
    }

    /**
     * @dev Allows DAO members to vote on a governance proposal.
     * @param _proposalId The ID of the governance proposal.
     * @param _supports True for "For", False for "Against".
     */
    function voteOnGovernanceChange(uint256 _proposalId, bool _supports) external onlyDAO whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound();
        if (proposal.status != ProposalStatus.Pending) revert InvalidProposalState();
        if (proposal.hasVoted[msg.sender]) revert ProposalAlreadyVoted();

        proposal.hasVoted[msg.sender] = true;
        if (_supports) {
            proposal.voteFor++;
        } else {
            proposal.voteAgainst++;
        }
        emit GovernanceProposalVoted(_proposalId, msg.sender, _supports);
    }

    /**
     * @dev Executes a governance proposal that has successfully passed its voting period.
     * @param _proposalId The ID of the governance proposal.
     */
    function executeGovernanceChange(uint256 _proposalId) external onlyDAO whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound();
        if (proposal.status != ProposalStatus.Pending) revert InvalidProposalState();
        if (block.timestamp < proposal.creationTime + VOTING_PERIOD_SECONDS) revert ProposalNotYetPassed();

        if (proposal.voteFor > proposal.voteAgainst && proposal.voteFor >= MIN_GOVERNANCE_VOTES) {
            (bool success,) = proposal.targetContract.call(proposal.callData);
            if (!success) {
                // Handle potential failure of the called function.
                // For simplicity, we just mark as failed. A more robust system might re-queue or allow dispute.
                proposal.status = ProposalStatus.Failed;
                revert InvalidProposalState(); // Indicate execution failure
            }
            proposal.status = ProposalStatus.Executed;
        } else {
            proposal.status = ProposalStatus.Failed;
        }
        emit GovernanceProposalExecuted(_proposalId);
    }

    /* ============ External Oracle Integration ============ */

    /**
     * @dev Sets or updates the address of the external Nexus Oracle.
     *      Only the contract owner can set this.
     * @param _newOracleAddress The address of the new oracle contract.
     */
    function setOracleAddress(address _newOracleAddress) external onlyOwner {
        if (_newOracleAddress == address(0)) revert InvalidOracleAddress();
        address oldOracleAddress = address(_nexusOracle);
        _nexusOracle = INexusOracle(_newOracleAddress);
        emit OracleAddressSet(oldOracleAddress, _newOracleAddress);
    }

    /* ============ Utility & View Functions ============ */

    /**
     * @dev Allows the owner to withdraw unspent funds from the contract.
     *      In a full DAO, this would be managed by DAO governance.
     * @param _recipient The address to send funds to.
     * @param _amount The amount of ETH to withdraw.
     */
    function withdrawFunds(address _recipient, uint256 _amount) external onlyOwner {
        if (_amount == 0 || address(this).balance < _amount) revert InsufficientBalance();
        (bool success,) = _recipient.call{value: _amount}("");
        if (!success) revert InsufficientBalance(); // Transfer failed
        emit FundsWithdrawn(_recipient, _amount);
    }

    /**
     * @dev Retrieves detailed information about a researcher.
     * @param _researcher The address of the researcher.
     * @return name, bio, synergyScore, registered status.
     */
    function getResearcherDetails(address _researcher) external view returns (string memory name, string memory bio, uint256 synergyScore, bool registered) {
        Researcher storage r = researchers[_researcher];
        if (!r.registered) revert ResearcherNotFound();
        return (r.name, r.bio, r.synergyScore, r.registered);
    }

    /**
     * @dev Retrieves detailed information about a knowledge node.
     * @param _nodeId The ID of the knowledge node.
     * @return contentHash, contributor, timestamp, isDeprecated, isMerged, mergedToId.
     */
    function getNodeDetails(uint256 _nodeId) external view returns (bytes32 contentHash, address contributor, uint256 timestamp, bool isDeprecated, bool isMerged, uint256 mergedToId) {
        KnowledgeNode storage n = knowledgeNodes[_nodeId];
        if (n.contributor == address(0)) revert NodeNotFound();
        return (n.contentHash, n.contributor, n.timestamp, n.isDeprecated, n.isMerged, n.mergedToId);
    }

    /**
     * @dev Retrieves detailed information about a hypothesis.
     * @param _hypothesisId The ID of the hypothesis.
     * @return proposer, statementHash, linkedNodes, status, predictionMarketEndTime, trueStakes, falseStakes.
     */
    function getHypothesisDetails(uint256 _hypothesisId) external view returns (address proposer, bytes32 statementHash, uint256[] memory linkedNodes, HypothesisStatus status, uint256 predictionMarketEndTime, uint256 trueStakes, uint256 falseStakes) {
        Hypothesis storage h = hypotheses[_hypothesisId];
        if (h.proposer == address(0)) revert HypothesisNotFound();
        return (h.proposer, h.statementHash, h.linkedNodes, h.status, h.predictionMarketEndTime, h.trueStakes, h.falseStakes);
    }

    /**
     * @dev Retrieves detailed information about an agent grant.
     * @param _grantId The ID of the grant.
     * @return proposer, targetNodeId, amount, status, reportHash, voteFor, voteAgainst.
     */
    function getGrantDetails(uint256 _grantId) external view returns (address proposer, uint256 targetNodeId, uint256 amount, GrantStatus status, bytes32 reportHash, uint256 voteFor, uint256 voteAgainst) {
        AgentGrant storage g = agentGrants[_grantId];
        if (g.proposer == address(0)) revert GrantNotFound();
        return (g.proposer, g.targetNodeId, g.amount, g.status, g.reportHash, g.voteFor, g.voteAgainst);
    }

    // --- Helper functions for string conversion (Solidity standard library might have this, but for self-containment)
    library Strings {
        function toString(uint256 value) internal pure returns (string memory) {
            if (value == 0) {
                return "0";
            }
            uint256 temp = value;
            uint256 digits;
            while (temp != 0) {
                digits++;
                temp /= 10;
            }
            bytes memory buffer = new bytes(digits);
            while (value != 0) {
                digits--;
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
            }
            return string(buffer);
        }
    }
}
```