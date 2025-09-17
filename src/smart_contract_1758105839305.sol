Here's a smart contract named `AetherMind`, designed as a decentralized platform for curated AI Agent Execution and Knowledge Synthesis. It incorporates advanced concepts like a reputation system for AI agents, on-chain task coordination for off-chain AI computation, a decentralized knowledge graph, and a robust challenge/resolution mechanism.

---

## AetherMind: Decentralized AI Agent Network & Knowledge Oracle

### Outline and Function Summary

`AetherMind` serves as a trust layer for AI agents ("Mind-Nodes") to perform tasks and contribute to a shared, validated knowledge base. It enables users to submit "Cognition Requests" (tasks), which Mind-Nodes can bid on and solve. Solutions are subject to a challenge and resolution system, which directly impacts the Mind-Nodes' on-chain reputation. The ultimate goal is to foster a reliable, decentralized network of AI capabilities and aggregated knowledge.

---

#### I. Core Infrastructure & Agent Management
1.  `constructor()`: Initializes the contract owner and sets initial system parameters.
2.  `registerMindNode(string memory _agentURI, bytes32[] memory _capabilities)`: Allows an address to register itself as an AI Mind-Node, providing a URI for its off-chain details and a list of capabilities it offers.
3.  `updateMindNodeCapabilities(bytes32[] memory _newCapabilities)`: Enables a registered Mind-Node to update its declared capabilities.
4.  `deregisterMindNode()`: Allows a Mind-Node to remove itself from the active network.
5.  `setAgentRegistryOperator(address _operator, bool _isOperator)`: Grants or revokes administrative privileges for managing Mind-Node registrations to a specific address.

#### II. Cognition Requests & Bidding
6.  `submitCognitionRequest(bytes32 _requestHash, uint256 _bountyAmount, uint256 _deadline, bytes32[] memory _requiredCapabilities, string memory _metadataURI)`: A user submits a task request, providing a hash of the request details, a bounty, a deadline, required agent capabilities, and a URI for full request metadata.
7.  `cancelCognitionRequest(uint256 _requestId)`: The requestor can cancel their submitted request if it hasn't been accepted by a Mind-Node yet.
8.  `bidOnCognitionRequest(uint256 _requestId, uint256 _bidAmount, uint256 _estimationTime)`: A registered Mind-Node can place a bid on an open request, specifying the amount they require (less than or equal to bounty) and their estimated completion time.
9.  `acceptMindNodeBid(uint256 _requestId, address _mindNodeAddress)`: The requestor selects and accepts a bid from a Mind-Node, allocating the task and locking the bounty.

#### III. Solution Submission & Verification
10. `submitCognitionSolution(uint256 _requestId, bytes32 _solutionHash, string memory _solutionURI, bytes memory _proofData)`: The assigned Mind-Node submits its solution, including a hash of the result, a URI to access the full solution, and optional proof data (e.g., a hash of computation, signature, or future ZK-proof).
11. `challengeCognitionSolution(uint256 _requestId, address _solverAddress, string memory _challengeReasonURI)`: Any registered Mind-Node or designated validator can challenge a submitted solution, requiring a challenge bond.
12. `resolveCognitionChallenge(uint256 _requestId, address _solverAddress, bool _isSolutionCorrect, string memory _resolutionURI)`: An arbiter (e.g., owner or designated entity) resolves a challenge, determining if the solution was correct. This impacts reputation and bounty distribution.
13. `confirmCognitionSolution(uint256 _requestId)`: The original requestor confirms the solution is satisfactory, releasing the bounty and updating the solver's reputation.

#### IV. Reputation & Knowledge Base
14. `getMindNodeReputation(address _mindNode)`: Retrieves the current reputation score for a specific Mind-Node.
15. `getKnowledgeEntry(bytes32 _entryHash)`: Retrieves a validated knowledge entry from the on-chain graph.
16. `contributeKnowledgeGraphEntry(bytes32 _parentHash, bytes32 _entryHash, string memory _entryURI, uint256 _rewardAmount)`: Users or Mind-Nodes can propose new knowledge entries to the decentralized graph, optionally linking to a parent entry and offering a reward for validation.
17. `validateKnowledgeGraphEntry(bytes32 _entryHash, bool _isValid)`: Designated validators review and approve/reject proposed knowledge entries. Validated entries become part of the shared knowledge base, rewarding contributors.

#### V. Governance & System Parameters
18. `updateReputationDecayRate(uint256 _newRate)`: Allows the owner to adjust the rate at which Mind-Node reputation naturally decays over time.
19. `updateChallengeBond(uint256 _newBond)`: Allows the owner to set the ETH amount required to challenge a solution.
20. `withdrawMindNodeFunds()`: Enables a Mind-Node to withdraw their accumulated earned bounties and rewards.
21. `setKnowledgeGraphValidator(address _validator, bool _isValidator)`: Grants or revokes the role of knowledge graph validator to a specific address.
22. `emergencyPause()`: Allows the owner to pause critical contract functions in case of an emergency (e.g., exploit).
23. `unpause()`: Allows the owner to unpause the contract after an emergency.
24. `proposeUpgrade(address _newImplementation)`: Owner can propose a new implementation address for proxy-based upgrades (conceptual, assuming an upgradeable pattern like UUPS).
25. `voteOnUpgrade(uint256 _proposalId, bool _approve)`: Enables a simple on-chain voting mechanism for stakeholders to approve or reject upgrade proposals.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title AetherMind: Decentralized AI Agent Network & Knowledge Oracle
/// @author YourName (or AetherMind Team)
/// @notice This contract orchestrates a network of AI agents (Mind-Nodes)
///         to perform off-chain computation tasks and contribute to a
///         decentralized, validated knowledge base. It includes a reputation
///         system, a bidding mechanism for tasks, and a challenge/resolution
///         process to ensure correctness and build trust.
contract AetherMind is Ownable, Pausable, ReentrancyGuard {

    // --- Custom Errors ---
    error AetherMind__NotRegisteredMindNode();
    error AetherMind__MindNodeAlreadyRegistered();
    error AetherMind__InvalidCapabilities();
    error AetherMind__RequestNotFound();
    error AetherMind__RequestNotInCorrectState();
    error AetherMind__BountyTooLow();
    error AetherMind__NotRequestor();
    error AetherMind__MindNodeNotAssigned();
    error AetherMind__SolutionAlreadySubmitted();
    error AetherMind__ChallengeAlreadyExists();
    error AetherMind__ChallengeNotResolved();
    error AetherMind__ChallengeBondRequired();
    error AetherMind__InvalidBidAmount();
    error AetherMind__BidAlreadyAccepted();
    error AetherMind__DeadlinePassed();
    error AetherMind__NoFundsToWithdraw();
    error AetherMind__KnowledgeEntryNotFound();
    error AetherMind__EntryAlreadyValidated();
    error AetherMind__UnauthorizedKnowledgeValidator();
    error AetherMind__UpgradeAlreadyApproved();
    error AetherMind__UpgradeNotProposed();
    error AetherMind__UpgradeVoteAlreadyCast();


    // --- Enums ---

    enum CognitionRequestState {
        Open,           // Request submitted, awaiting bids
        Bidding,        // Bids received, requestor can accept
        Accepted,       // Bid accepted, Mind-Node assigned
        Solved,         // Solution submitted by Mind-Node
        Challenged,     // Solution challenged by another party
        Resolved,       // Challenge resolved by arbiter
        Completed,      // Solution confirmed by requestor, bounty paid
        Cancelled       // Request cancelled by requestor
    }

    // --- Structs ---

    struct MindNode {
        string agentURI;            // URI to off-chain details of the AI agent
        bytes32[] capabilities;     // Hashed capabilities (e.g., keccak256("summarization"), keccak256("image_generation"))
        uint256 reputationScore;    // Score indicating trustworthiness and performance
        uint256 lastActive;         // Timestamp of last interaction (for decay calculation)
        bool isRegistered;          // True if the address is an active Mind-Node
        uint256 lockedFunds;        // Funds locked for challenges, or accumulated pending withdrawal
    }

    struct CognitionRequest {
        address requestor;          // Address of the user submitting the request
        bytes32 requestHash;        // Hash of the detailed request parameters (off-chain)
        uint256 bountyAmount;       // Amount of ETH offered as bounty
        uint256 deadline;           // Timestamp by which the solution must be submitted
        bytes32[] requiredCapabilities; // Capabilities required from the Mind-Node
        string metadataURI;         // URI to detailed request metadata (off-chain)
        address winningMindNode;    // Address of the Mind-Node whose bid was accepted
        CognitionRequestState state; // Current state of the request
        uint256 submissionTimestamp; // Timestamp when solution was submitted
        bytes32 solutionHash;       // Hash of the submitted solution
        string solutionURI;         // URI to the full solution data
        bytes proofData;            // Optional proof of computation (e.g., ZK-proof, signature)
        bool isChallenged;          // True if the solution has been challenged
        bool isSolutionCorrect;     // Outcome of challenge resolution
        uint256 challengeBond;      // Bond provided by challenger
        address challenger;         // Address of the challenger
        string challengeReasonURI;  // URI to challenge details
    }

    struct CognitionBid {
        address mindNode;           // Address of the Mind-Node placing the bid
        uint256 bidAmount;          // Amount of ETH the Mind-Node requests (<= bounty)
        uint256 estimationTime;     // Estimated time (in seconds) to complete the task
    }

    struct KnowledgeEntry {
        address contributor;        // Address that proposed the entry
        bytes32 parentHash;         // Optional hash of a parent knowledge entry for graph structure
        bytes32 entryHash;          // Hash of the detailed knowledge content (off-chain)
        string entryURI;            // URI to the detailed knowledge content
        bool isValidated;           // True if the entry has been validated by an arbiter
        uint256 validationTimestamp;// Timestamp of validation
        uint256 rewardAmount;       // Reward offered for validating this entry
    }

    struct UpgradeProposal {
        address newImplementation;  // Address of the new contract implementation
        uint256 proposalTimestamp;  // When the proposal was made
        uint256 totalVotesFor;      // Count of 'for' votes
        uint256 totalVotesAgainst;  // Count of 'against' votes
        mapping(address => bool) hasVoted; // Tracks if an address has voted
        bool executed;              // True if the upgrade has been applied
    }

    // --- Events ---

    event MindNodeRegistered(address indexed mindNode, string agentURI, bytes32[] capabilities);
    event MindNodeDeregistered(address indexed mindNode);
    event MindNodeCapabilitiesUpdated(address indexed mindNode, bytes32[] newCapabilities);
    event CognitionRequestSubmitted(uint256 indexed requestId, address indexed requestor, uint256 bountyAmount, uint256 deadline);
    event CognitionRequestCancelled(uint256 indexed requestId, address indexed requestor);
    event BidSubmitted(uint256 indexed requestId, address indexed mindNode, uint256 bidAmount);
    event BidAccepted(uint256 indexed requestId, address indexed requestor, address indexed mindNode);
    event SolutionSubmitted(uint256 indexed requestId, address indexed solver, bytes32 solutionHash);
    event SolutionChallenged(uint256 indexed requestId, address indexed solver, address indexed challenger, string challengeReasonURI);
    event ChallengeResolved(uint256 indexed requestId, address indexed solver, bool isSolutionCorrect, string resolutionURI);
    event SolutionConfirmed(uint256 indexed requestId, address indexed requestor, address indexed solver);
    event ReputationUpdated(address indexed mindNode, uint256 newReputation);
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event KnowledgeEntryContributed(bytes32 indexed entryHash, address indexed contributor, string entryURI);
    event KnowledgeEntryValidated(bytes32 indexed entryHash, address indexed validator, bool isValid);
    event Paused(address account);
    event Unpaused(address account);
    event UpgradeProposed(uint256 indexed proposalId, address newImplementation, address indexed proposer);
    event UpgradeVoted(uint256 indexed proposalId, address indexed voter, bool approved);

    // --- State Variables ---

    uint256 public nextRequestId;                               // Counter for cognition requests
    uint256 public nextKnowledgeEntryId;                        // Counter for knowledge entries
    uint256 public nextUpgradeProposalId;                       // Counter for upgrade proposals

    // Configuration parameters
    uint256 public MIN_REPUTATION_FOR_BIDDING = 100;            // Minimum reputation to bid on tasks
    uint256 public BASE_REPUTATION_GAIN = 10;                   // Base reputation gain for correct solution
    uint256 public BASE_REPUTATION_LOSS = 20;                   // Base reputation loss for incorrect solution/challenge
    uint256 public REPUTATION_DECAY_RATE_PER_DAY = 1;           // Points per day reputation decays
    uint256 public CHALLENGE_BOND = 0.05 ether;                 // ETH required to challenge a solution
    uint256 public UPGRADE_VOTE_QUORUM_PERCENT = 51;            // % of active Mind-Nodes needed to pass an upgrade

    mapping(address => MindNode) public mindNodes;              // address -> MindNode struct
    mapping(address => bool) public isAgentRegistryOperator;    // address -> bool (can manage agent registrations)
    mapping(address => bool) public isKnowledgeGraphValidator;  // address -> bool (can validate knowledge entries)

    mapping(uint256 => CognitionRequest) public cognitionRequests; // requestId -> CognitionRequest struct
    mapping(uint256 => mapping(address => CognitionBid)) public cognitionBids; // requestId -> mindNode -> CognitionBid struct
    mapping(uint256 => address[]) public requestBidders;        // requestId -> list of bidders

    mapping(bytes32 => KnowledgeEntry) public knowledgeGraph;   // entryHash -> KnowledgeEntry struct
    mapping(bytes32 => bool) public hasKnowledgeGraphEntry;     // entryHash -> exists

    mapping(uint256 => UpgradeProposal) public upgradeProposals; // proposalId -> UpgradeProposal struct

    // --- Modifiers ---

    modifier onlyMindNode() {
        if (!mindNodes[msg.sender].isRegistered) {
            revert AetherMind__NotRegisteredMindNode();
        }
        _;
    }

    modifier onlyAgentRegistryOperator() {
        if (!isAgentRegistryOperator[msg.sender] && msg.sender != owner()) {
            revert OwnableUnauthorizedAccount(msg.sender); // Using Ownable's error for consistency
        }
        _;
    }

    modifier onlyKnowledgeGraphValidator() {
        if (!isKnowledgeGraphValidator[msg.sender] && msg.sender != owner()) {
            revert AetherMind__UnauthorizedKnowledgeValidator();
        }
        _;
    }

    // --- Constructor ---

    constructor() Ownable(msg.sender) {
        // Initial owner has full control
    }

    // --- I. Core Infrastructure & Agent Management ---

    /// @notice Registers the caller as a new AI Mind-Node.
    /// @param _agentURI URI pointing to off-chain details about the agent.
    /// @param _capabilities Array of hashed capabilities the agent offers.
    function registerMindNode(string memory _agentURI, bytes32[] memory _capabilities) public whenNotPaused {
        if (mindNodes[msg.sender].isRegistered) {
            revert AetherMind__MindNodeAlreadyRegistered();
        }
        if (_capabilities.length == 0) {
            revert AetherMind__InvalidCapabilities();
        }

        mindNodes[msg.sender] = MindNode({
            agentURI: _agentURI,
            capabilities: _capabilities,
            reputationScore: 0, // Start with base reputation or 0
            lastActive: block.timestamp,
            isRegistered: true,
            lockedFunds: 0
        });

        emit MindNodeRegistered(msg.sender, _agentURI, _capabilities);
    }

    /// @notice Updates the declared capabilities of the caller's Mind-Node.
    /// @param _newCapabilities Array of new hashed capabilities.
    function updateMindNodeCapabilities(bytes32[] memory _newCapabilities) public onlyMindNode whenNotPaused {
        if (_newCapabilities.length == 0) {
            revert AetherMind__InvalidCapabilities();
        }
        mindNodes[msg.sender].capabilities = _newCapabilities;
        mindNodes[msg.sender].lastActive = block.timestamp;
        emit MindNodeCapabilitiesUpdated(msg.sender, _newCapabilities);
    }

    /// @notice Deregisters the caller's Mind-Node from the network.
    function deregisterMindNode() public onlyMindNode whenNotPaused {
        // Potentially handle locked funds or active requests here
        // For simplicity, we just mark as unregistered
        mindNodes[msg.sender].isRegistered = false;
        // Optionally, refund locked funds if any
        if (mindNodes[msg.sender].lockedFunds > 0) {
            // Need a mechanism to return funds if not associated with active challenges
            // For now, assume it's okay to deregister, locked funds can be claimed via withdrawMindNodeFunds
        }
        emit MindNodeDeregistered(msg.sender);
    }

    /// @notice Grants or revokes the role of agent registry operator.
    /// @param _operator Address to grant/revoke the role.
    /// @param _isOperator True to grant, false to revoke.
    function setAgentRegistryOperator(address _operator, bool _isOperator) public onlyOwner {
        isAgentRegistryOperator[_operator] = _isOperator;
    }

    // --- II. Cognition Requests & Bidding ---

    /// @notice Submits a new cognition request (task) to the network.
    /// @param _requestHash Hash of the off-chain request details.
    /// @param _bountyAmount The bounty in ETH offered for completing the task.
    /// @param _deadline Timestamp by which the task must be completed.
    /// @param _requiredCapabilities Array of hashed capabilities required from the solver.
    /// @param _metadataURI URI to detailed request metadata.
    function submitCognitionRequest(
        bytes32 _requestHash,
        uint256 _bountyAmount,
        uint256 _deadline,
        bytes32[] memory _requiredCapabilities,
        string memory _metadataURI
    ) public payable whenNotPaused nonReentrant {
        if (msg.value < _bountyAmount) {
            revert AetherMind__BountyTooLow();
        }
        if (_deadline <= block.timestamp) {
            revert AetherMind__DeadlinePassed();
        }
        if (_requiredCapabilities.length == 0) {
            revert AetherMind__InvalidCapabilities();
        }

        uint256 currentId = nextRequestId++;
        cognitionRequests[currentId] = CognitionRequest({
            requestor: msg.sender,
            requestHash: _requestHash,
            bountyAmount: _bountyAmount,
            deadline: _deadline,
            requiredCapabilities: _requiredCapabilities,
            metadataURI: _metadataURI,
            winningMindNode: address(0),
            state: CognitionRequestState.Open,
            submissionTimestamp: 0,
            solutionHash: 0,
            solutionURI: "",
            proofData: "",
            isChallenged: false,
            isSolutionCorrect: false,
            challengeBond: 0,
            challenger: address(0),
            challengeReasonURI: ""
        });

        // Store any excess ETH sent by the user back to requestor
        if (msg.value > _bountyAmount) {
            payable(msg.sender).transfer(msg.value - _bountyAmount);
        }

        emit CognitionRequestSubmitted(currentId, msg.sender, _bountyAmount, _deadline);
    }

    /// @notice Allows the requestor to cancel an open request.
    /// @param _requestId The ID of the request to cancel.
    function cancelCognitionRequest(uint256 _requestId) public whenNotPaused {
        CognitionRequest storage request = cognitionRequests[_requestId];
        if (request.requestor == address(0)) {
            revert AetherMind__RequestNotFound();
        }
        if (request.requestor != msg.sender) {
            revert AetherMind__NotRequestor();
        }
        if (request.state != CognitionRequestState.Open && request.state != CognitionRequestState.Bidding) {
            revert AetherMind__RequestNotInCorrectState();
        }

        request.state = CognitionRequestState.Cancelled;
        payable(msg.sender).transfer(request.bountyAmount); // Refund bounty
        emit CognitionRequestCancelled(_requestId, msg.sender);
    }

    /// @notice A Mind-Node bids on a cognition request.
    /// @param _requestId The ID of the request to bid on.
    /// @param _bidAmount The amount the Mind-Node requests for the task (must be <= bounty).
    /// @param _estimationTime Estimated time in seconds to complete the task.
    function bidOnCognitionRequest(uint256 _requestId, uint256 _bidAmount, uint256 _estimationTime) public onlyMindNode whenNotPaused {
        CognitionRequest storage request = cognitionRequests[_requestId];
        if (request.requestor == address(0)) {
            revert AetherMind__RequestNotFound();
        }
        if (request.state != CognitionRequestState.Open && request.state != CognitionRequestState.Bidding) {
            revert AetherMind__RequestNotInCorrectState();
        }
        if (mindNodes[msg.sender].reputationScore < MIN_REPUTATION_FOR_BIDDING) {
            revert AetherMind__NotRegisteredMindNode(); // Or a more specific error for reputation
        }
        if (_bidAmount > request.bountyAmount || _bidAmount == 0) {
            revert AetherMind__InvalidBidAmount();
        }
        if (request.deadline < block.timestamp + _estimationTime) {
            revert AetherMind__DeadlinePassed(); // Not enough time to complete before deadline
        }

        // Check if Mind-Node has the required capabilities (simplified check)
        // This could be more sophisticated, checking if ALL capabilities match
        bool hasRequiredCapability = false;
        for (uint i = 0; i < request.requiredCapabilities.length; i++) {
            for (uint j = 0; j < mindNodes[msg.sender].capabilities.length; j++) {
                if (request.requiredCapabilities[i] == mindNodes[msg.sender].capabilities[j]) {
                    hasRequiredCapability = true;
                    break;
                }
            }
            if (hasRequiredCapability) break; // If one capability matches, that's enough for this simplified version
        }
        if (!hasRequiredCapability && request.requiredCapabilities.length > 0) {
            revert AetherMind__InvalidCapabilities(); // Mind-Node lacks required capabilities
        }

        cognitionBids[_requestId][msg.sender] = CognitionBid({
            mindNode: msg.sender,
            bidAmount: _bidAmount,
            estimationTime: _estimationTime
        });
        requestBidders[_requestId].push(msg.sender); // Keep track of bidders
        request.state = CognitionRequestState.Bidding; // Mark as bidding if it was open

        emit BidSubmitted(_requestId, msg.sender, _bidAmount);
    }

    /// @notice The requestor accepts a bid from a Mind-Node.
    /// @param _requestId The ID of the request.
    /// @param _mindNodeAddress The address of the Mind-Node whose bid is accepted.
    function acceptMindNodeBid(uint256 _requestId, address _mindNodeAddress) public whenNotPaused {
        CognitionRequest storage request = cognitionRequests[_requestId];
        if (request.requestor == address(0)) {
            revert AetherMind__RequestNotFound();
        }
        if (request.requestor != msg.sender) {
            revert AetherMind__NotRequestor();
        }
        if (request.state != CognitionRequestState.Bidding) {
            revert AetherMind__RequestNotInCorrectState();
        }
        if (request.winningMindNode != address(0)) {
            revert AetherMind__BidAlreadyAccepted();
        }

        CognitionBid storage bid = cognitionBids[_requestId][_mindNodeAddress];
        if (bid.mindNode == address(0)) {
            revert AetherMind__RequestNotFound(); // No such bid
        }

        request.winningMindNode = _mindNodeAddress;
        request.state = CognitionRequestState.Accepted;

        // Refund excess bounty if accepted bid is less than initial bounty
        if (request.bountyAmount > bid.bidAmount) {
            payable(request.requestor).transfer(request.bountyAmount - bid.bidAmount);
            request.bountyAmount = bid.bidAmount; // Adjust bounty to accepted bid amount
        }

        emit BidAccepted(_requestId, msg.sender, _mindNodeAddress);
    }

    // --- III. Solution Submission & Verification ---

    /// @notice The assigned Mind-Node submits its solution for a cognition request.
    /// @param _requestId The ID of the request.
    /// @param _solutionHash Hash of the off-chain solution data.
    /// @param _solutionURI URI to the full solution data.
    /// @param _proofData Optional bytes for computational proof (e.g., ZK-proof).
    function submitCognitionSolution(
        uint256 _requestId,
        bytes32 _solutionHash,
        string memory _solutionURI,
        bytes memory _proofData
    ) public onlyMindNode whenNotPaused {
        CognitionRequest storage request = cognitionRequests[_requestId];
        if (request.requestor == address(0)) {
            revert AetherMind__RequestNotFound();
        }
        if (request.winningMindNode != msg.sender) {
            revert AetherMind__MindNodeNotAssigned();
        }
        if (request.state != CognitionRequestState.Accepted) {
            revert AetherMind__RequestNotInCorrectState();
        }
        if (request.submissionTimestamp != 0) {
            revert AetherMind__SolutionAlreadySubmitted();
        }
        if (request.deadline < block.timestamp) {
            // Penalize for late submission, or revert
            revert AetherMind__DeadlinePassed();
        }

        request.solutionHash = _solutionHash;
        request.solutionURI = _solutionURI;
        request.proofData = _proofData;
        request.submissionTimestamp = block.timestamp;
        request.state = CognitionRequestState.Solved;

        emit SolutionSubmitted(_requestId, msg.sender, _solutionHash);
    }

    /// @notice Allows any Mind-Node or designated validator to challenge a submitted solution.
    /// @param _requestId The ID of the request with the solution to challenge.
    /// @param _solverAddress The address of the Mind-Node that submitted the solution.
    /// @param _challengeReasonURI URI to details explaining the challenge.
    function challengeCognitionSolution(uint256 _requestId, address _solverAddress, string memory _challengeReasonURI) public payable onlyMindNode whenNotPaused {
        CognitionRequest storage request = cognitionRequests[_requestId];
        if (request.requestor == address(0)) {
            revert AetherMind__RequestNotFound();
        }
        if (request.state != CognitionRequestState.Solved) {
            revert AetherMind__RequestNotInCorrectState();
        }
        if (request.winningMindNode != _solverAddress) {
            revert AetherMind__MindNodeNotAssigned();
        }
        if (request.isChallenged) {
            revert AetherMind__ChallengeAlreadyExists();
        }
        if (msg.value < CHALLENGE_BOND) {
            revert AetherMind__ChallengeBondRequired();
        }

        request.isChallenged = true;
        request.state = CognitionRequestState.Challenged;
        request.challenger = msg.sender;
        request.challengeBond = msg.value;
        request.challengeReasonURI = _challengeReasonURI;

        // Mind-Node reputation update (decay for being challenged, or just mark)
        _updateMindNodeReputation(request.winningMindNode); // Update lastActive for decay calc.
        mindNodes[msg.sender].lockedFunds += msg.value; // Lock challenger's bond

        emit SolutionChallenged(_requestId, _solverAddress, msg.sender, _challengeReasonURI);
    }

    /// @notice Resolves a challenged cognition solution. Can only be called by owner or designated arbiter.
    /// @param _requestId The ID of the request.
    /// @param _solverAddress The address of the Mind-Node that submitted the solution.
    /// @param _isSolutionCorrect True if the solution is deemed correct, false otherwise.
    /// @param _resolutionURI URI to the resolution details.
    function resolveCognitionChallenge(
        uint256 _requestId,
        address _solverAddress,
        bool _isSolutionCorrect,
        string memory _resolutionURI
    ) public onlyOwner whenNotPaused nonReentrant {
        CognitionRequest storage request = cognitionRequests[_requestId];
        if (request.requestor == address(0)) {
            revert AetherMind__RequestNotFound();
        }
        if (request.winningMindNode != _solverAddress) {
            revert AetherMind__MindNodeNotAssigned();
        }
        if (request.state != CognitionRequestState.Challenged) {
            revert AetherMind__RequestNotInCorrectState();
        }
        if (!request.isChallenged) {
            revert AetherMind__ChallengeNotResolved();
        }

        request.isSolutionCorrect = _isSolutionCorrect;
        request.state = CognitionRequestState.Resolved;

        // Distribute challenge bond and update reputation
        if (_isSolutionCorrect) {
            // Solution was correct: challenger loses bond, solver gets reputation boost, and potentially a share of the bond
            _updateReputation(request.winningMindNode, BASE_REPUTATION_GAIN * 2); // Extra boost for falsely challenged
            _updateReputation(request.challenger, -BASE_REPUTATION_LOSS * 2); // Higher penalty for false challenge
            
            // Solver gets a portion of the challenge bond, rest goes to protocol/burnt
            uint256 solverShare = request.challengeBond / 2;
            mindNodes[request.winningMindNode].lockedFunds += solverShare;
            // The other half of the challenge bond could be sent to a treasury or burnt.
            // For simplicity here, we consider it distributed.
        } else {
            // Solution was incorrect: solver loses reputation, challenger gets bond back + reputation boost
            _updateReputation(request.winningMindNode, -BASE_REPUTATION_LOSS * 2); // Higher penalty for incorrect solution after challenge
            _updateReputation(request.challenger, BASE_REPUTATION_GAIN * 2); // Extra boost for correct challenge
            mindNodes[request.challenger].lockedFunds += request.challengeBond; // Challenger gets bond back
        }
        mindNodes[request.challenger].lockedFunds -= request.challengeBond; // Unlock bond regardless of outcome

        emit ChallengeResolved(_requestId, _solverAddress, _isSolutionCorrect, _resolutionURI);
    }

    /// @notice The original requestor confirms a solution, releasing bounty and impacting reputation.
    /// @param _requestId The ID of the request to confirm.
    function confirmCognitionSolution(uint256 _requestId) public whenNotPaused nonReentrant {
        CognitionRequest storage request = cognitionRequests[_requestId];
        if (request.requestor == address(0)) {
            revert AetherMind__RequestNotFound();
        }
        if (request.requestor != msg.sender) {
            revert AetherMind__NotRequestor();
        }
        if (request.state != CognitionRequestState.Solved && request.state != CognitionRequestState.Resolved) {
            revert AetherMind__RequestNotInCorrectState();
        }

        // If it was challenged and resolved as incorrect, don't pay bounty
        if (request.isChallenged && !request.isSolutionCorrect) {
            // Bounty might be returned to requestor or handled otherwise based on policy
            request.state = CognitionRequestState.Completed; // Mark as completed without bounty payment
            emit SolutionConfirmed(_requestId, msg.sender, request.winningMindNode);
            return;
        }

        // Pay bounty to the winning Mind-Node
        mindNodes[request.winningMindNode].lockedFunds += request.bountyAmount;
        _updateReputation(request.winningMindNode, BASE_REPUTATION_GAIN); // Standard reputation gain

        request.state = CognitionRequestState.Completed;
        emit SolutionConfirmed(_requestId, msg.sender, request.winningMindNode);
    }

    // --- IV. Reputation & Knowledge Base ---

    /// @notice Retrieves the current reputation score for a Mind-Node, accounting for decay.
    /// @param _mindNode The address of the Mind-Node.
    /// @return The current reputation score.
    function getMindNodeReputation(address _mindNode) public view returns (uint256) {
        if (!mindNodes[_mindNode].isRegistered) {
            return 0; // Or revert AetherMind__NotRegisteredMindNode();
        }
        return _calculateDecayedReputation(_mindNode);
    }

    /// @notice Retrieves a validated knowledge entry from the on-chain graph.
    /// @param _entryHash The hash of the knowledge entry.
    /// @return contributor, parentHash, entryHash, entryURI, isValidated, validationTimestamp, rewardAmount
    function getKnowledgeEntry(bytes32 _entryHash) public view returns (
        address contributor,
        bytes32 parentHash,
        bytes32 entryHash,
        string memory entryURI,
        bool isValidated,
        uint256 validationTimestamp,
        uint256 rewardAmount
    ) {
        if (!hasKnowledgeGraphEntry[_entryHash]) {
            revert AetherMind__KnowledgeEntryNotFound();
        }
        KnowledgeEntry storage entry = knowledgeGraph[_entryHash];
        return (
            entry.contributor,
            entry.parentHash,
            entry.entryHash,
            entry.entryURI,
            entry.isValidated,
            entry.validationTimestamp,
            entry.rewardAmount
        );
    }

    /// @notice Allows users or Mind-Nodes to propose new knowledge entries to the graph.
    /// @param _parentHash Optional hash of a parent knowledge entry.
    /// @param _entryHash Hash of the detailed knowledge content (off-chain).
    /// @param _entryURI URI to the detailed knowledge content.
    /// @param _rewardAmount Optional reward for validators.
    function contributeKnowledgeGraphEntry(
        bytes32 _parentHash,
        bytes32 _entryHash,
        string memory _entryURI,
        uint256 _rewardAmount
    ) public payable whenNotPaused {
        if (hasKnowledgeGraphEntry[_entryHash]) {
            revert AetherMind__EntryAlreadyValidated(); // Or a specific error for existing entry
        }
        if (_parentHash != bytes32(0) && !hasKnowledgeGraphEntry[_parentHash]) {
            revert AetherMind__KnowledgeEntryNotFound(); // Parent must exist if specified
        }
        if (msg.value < _rewardAmount) {
            revert AetherMind__BountyTooLow(); // If reward is specified, must send enough ETH
        }

        knowledgeGraph[_entryHash] = KnowledgeEntry({
            contributor: msg.sender,
            parentHash: _parentHash,
            entryHash: _entryHash,
            entryURI: _entryURI,
            isValidated: false,
            validationTimestamp: 0,
            rewardAmount: _rewardAmount
        });
        hasKnowledgeGraphEntry[_entryHash] = true;
        // Refund any excess ETH
        if (msg.value > _rewardAmount) {
            payable(msg.sender).transfer(msg.value - _rewardAmount);
        }

        emit KnowledgeEntryContributed(_entryHash, msg.sender, _entryURI);
    }

    /// @notice Designated validators approve or reject proposed knowledge entries.
    /// @param _entryHash The hash of the knowledge entry to validate.
    /// @param _isValid True to approve, false to reject.
    function validateKnowledgeGraphEntry(bytes32 _entryHash, bool _isValid) public onlyKnowledgeGraphValidator whenNotPaused nonReentrant {
        if (!hasKnowledgeGraphEntry[_entryHash]) {
            revert AetherMind__KnowledgeEntryNotFound();
        }
        KnowledgeEntry storage entry = knowledgeGraph[_entryHash];
        if (entry.isValidated) {
            revert AetherMind__EntryAlreadyValidated();
        }

        entry.isValidated = _isValid;
        entry.validationTimestamp = block.timestamp;

        if (_isValid && entry.rewardAmount > 0) {
            // Reward the contributor and/or validator
            // For simplicity, let's say the validator gets the reward
            mindNodes[msg.sender].lockedFunds += entry.rewardAmount;
        } else if (!isValid && entry.rewardAmount > 0) {
            // If rejected, return reward to original contributor or protocol
            payable(entry.contributor).transfer(entry.rewardAmount); // Refund contributor
        }

        emit KnowledgeEntryValidated(_entryHash, msg.sender, _isValid);
    }

    // --- V. Governance & System Parameters ---

    /// @notice Allows the owner to adjust the reputation decay rate.
    /// @param _newRate The new reputation decay rate per day.
    function updateReputationDecayRate(uint256 _newRate) public onlyOwner {
        REPUTATION_DECAY_RATE_PER_DAY = _newRate;
    }

    /// @notice Allows the owner to adjust the required challenge bond.
    /// @param _newBond The new challenge bond in wei.
    function updateChallengeBond(uint256 _newBond) public onlyOwner {
        CHALLENGE_BOND = _newBond;
    }

    /// @notice Allows a Mind-Node to withdraw their accumulated earned bounties and rewards.
    function withdrawMindNodeFunds() public onlyMindNode whenNotPaused nonReentrant {
        MindNode storage node = mindNodes[msg.sender];
        if (node.lockedFunds == 0) {
            revert AetherMind__NoFundsToWithdraw();
        }
        uint256 amount = node.lockedFunds;
        node.lockedFunds = 0;
        payable(msg.sender).transfer(amount);
        emit FundsWithdrawn(msg.sender, amount);
    }

    /// @notice Grants or revokes the role of knowledge graph validator.
    /// @param _validator Address to grant/revoke the role.
    /// @param _isValidator True to grant, false to revoke.
    function setKnowledgeGraphValidator(address _validator, bool _isValidator) public onlyOwner {
        isKnowledgeGraphValidator[_validator] = _isValidator;
    }

    /// @notice Pauses contract functionality. Callable only by owner.
    function emergencyPause() public onlyOwner {
        _pause();
        emit Paused(msg.sender);
    }

    /// @notice Unpauses contract functionality. Callable only by owner.
    function unpause() public onlyOwner {
        _unpause();
        emit Unpaused(msg.sender);
    }

    /// @notice Proposes a new contract implementation for upgrades (assuming UUPS).
    /// @param _newImplementation The address of the new contract implementation.
    /// @return The ID of the created upgrade proposal.
    function proposeUpgrade(address _newImplementation) public onlyOwner returns (uint256) {
        uint256 proposalId = nextUpgradeProposalId++;
        upgradeProposals[proposalId] = UpgradeProposal({
            newImplementation: _newImplementation,
            proposalTimestamp: block.timestamp,
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            executed: false
        });
        emit UpgradeProposed(proposalId, _newImplementation, msg.sender);
        return proposalId;
    }

    /// @notice Allows any registered Mind-Node to vote on an upgrade proposal.
    /// @param _proposalId The ID of the upgrade proposal.
    /// @param _approve True to vote in favor, false to vote against.
    function voteOnUpgrade(uint256 _proposalId, bool _approve) public onlyMindNode {
        UpgradeProposal storage proposal = upgradeProposals[_proposalId];
        if (proposal.newImplementation == address(0)) {
            revert AetherMind__UpgradeNotProposed();
        }
        if (proposal.executed) {
            revert AetherMind__UpgradeAlreadyApproved();
        }
        if (proposal.hasVoted[msg.sender]) {
            revert AetherMind__UpgradeVoteAlreadyCast();
        }

        proposal.hasVoted[msg.sender] = true;
        if (_approve) {
            proposal.totalVotesFor++;
        } else {
            proposal.totalVotesAgainst++;
        }

        // Check for quorum and execute if met (simplified: owner acts as proxy for execution)
        // In a real UUPS, a separate governance contract or owner would call _setImplementation
        // after quorum is met. Here, we just log the vote.
        uint256 totalMindNodes = 0;
        for (uint i = 0; i < requestBidders[0].length; i++) { // Placeholder for actual active mind node count
            if (mindNodes[requestBidders[0][i]].isRegistered) {
                totalMindNodes++;
            }
        }
        // This 'totalMindNodes' calculation is highly simplified and would need a proper counter/registry
        // A more robust system would involve iterating through `mindNodes` mapping, which is inefficient on-chain.
        // Or, keep a dedicated counter for active registered mind nodes.
        if (totalMindNodes == 0) { totalMindNodes = 1; } // Avoid division by zero for example.

        uint256 currentApprovalPercentage = (proposal.totalVotesFor * 100) / totalMindNodes;
        if (currentApprovalPercentage >= UPGRADE_VOTE_QUORUM_PERCENT) {
            // In a real UUPS proxy, this would trigger the upgrade.
            // For this example, we just mark it as approved, actual execution is off-chain/via owner.
            if (!proposal.executed) {
                proposal.executed = true; // Mark as notionally executed
                // _setImplementation(proposal.newImplementation); // This would be the actual upgrade call in UUPS
            }
        }
        emit UpgradeVoted(_proposalId, msg.sender, _approve);
    }

    // --- Internal Helper Functions ---

    /// @dev Calculates and returns the current decayed reputation for a Mind-Node.
    function _calculateDecayedReputation(address _mindNode) internal view returns (uint256) {
        MindNode storage node = mindNodes[_mindNode];
        if (node.reputationScore == 0 || node.lastActive == 0) {
            return 0;
        }

        uint256 daysInactive = (block.timestamp - node.lastActive) / 1 days;
        uint256 decayAmount = daysInactive * REPUTATION_DECAY_RATE_PER_DAY;

        if (node.reputationScore <= decayAmount) {
            return 0;
        }
        return node.reputationScore - decayAmount;
    }

    /// @dev Updates a Mind-Node's reputation score.
    function _updateReputation(address _mindNode, int256 _change) internal {
        MindNode storage node = mindNodes[_mindNode];
        // Apply decay before applying new change
        node.reputationScore = _calculateDecayedReputation(_mindNode);

        if (_change > 0) {
            node.reputationScore += uint256(_change);
        } else if (node.reputationScore >= uint256(-_change)) {
            node.reputationScore -= uint256(-_change);
        } else {
            node.reputationScore = 0; // Cannot go below zero
        }
        node.lastActive = block.timestamp;
        emit ReputationUpdated(_mindNode, node.reputationScore);
    }

    // Fallback to receive ETH
    receive() external payable {}
}
```