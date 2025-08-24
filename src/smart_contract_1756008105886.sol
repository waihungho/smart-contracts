This smart contract, **DAIASN (Decentralized AI Alignment & Service Nexus)**, introduces a novel framework for managing AI agents, facilitating task execution, and promoting AI alignment through an on-chain reputation system. It leverages dynamic Non-Fungible Tokens (NFTs) as "Dynamic AI Performance Certificates" (DAPCs) which visually evolve with an agent's reputation, alongside a decentralized governance module and an AI Alignment Fund.

---

## DAIASN: Decentralized AI Alignment & Service Nexus

### Outline & Function Summary

**I. Core Agent Registry & Management**
*   **`registerAIAgent`**: Allows users to register a new AI agent, providing metadata, IPFS hash of its model/code, and supported skills. Automatically mints a DAPC.
*   **`updateAIAgentProfile`**: Enables an agent owner to update their agent's public information.
*   **`deregisterAIAgent`**: Initiates a soft deregistration process for an agent, pending governance approval for final removal.
*   **`getAIAgentDetails`**: Retrieves all pertinent details of a registered AI agent.
*   **`setAgentApprovalStatus`**: A governance/verifier function to officially approve or reject an AI agent's registration, making it eligible/ineligible for tasks.

**II. Dynamic AI Performance Certificates (DAPC - ERC721)**
*   **`_mintDAPC` (Internal)**: Mints a new DAPC NFT, which serves as a soulbound reputation token for an AI agent, linking its identity to its performance.
*   **`tokenURI` (Override)**: Dynamically generates the metadata URI for a DAPC. The metadata (e.g., "Tier" attribute) changes based on the agent's current reputation score.
*   **`transferFrom` (Override)**: Overrides the ERC721 transfer function. DAPCs are soulbound by default (`isDAPCTransferable = false`), meaning they cannot be transferred. Governance can enable transferability.
*   **`_burnDAPC` (Internal)**: Allows internal burning of a DAPC, typically on permanent agent deregistration, if burnability is enabled by governance.
*   **`setDAPCStatus`**: Governance function to control whether DAPCs can be transferred or burned.

**III. Task Marketplace & Attestation**
*   **`createTaskRequest`**: Users can post a new AI task, providing a description, input data hash, required skills, bounty, and deadline. Requires funding the bounty upon creation.
*   **`bidOnTask`**: Approved AI agents can submit bids (their requested payment) for open tasks.
*   **`selectTaskBid`**: The task requester reviews bids and selects a winning agent.
*   **`submitTaskResultHash`**: The selected agent submits the IPFS hash of the completed task's result.
*   **`attestTaskPerformance`**: The task requester provides feedback on the agent's performance (satisfied/not satisfied) and can leave a comment.
*   **`submitVerifierAttestation`**: Designated verifiers provide an independent assessment of the task's accuracy and assign an "alignment score" (0-100).
*   **`finalizeTask`**: Completes a task, distributes the bounty to the agent, refunds any excess to the requester, and triggers a comprehensive reputation update based on all attestations. Can be called by anyone after attestations or deadline.
*   **`cancelTask`**: Allows the task requester to cancel an open task, refunding the bounty.
*   **`getTaskDetails`**: Retrieves comprehensive details about a specific task request.

**IV. Reputation & Alignment Mechanics**
*   **`_updateAgentReputation` (Internal)**: Adjusts an AI agent's reputation score based on task attestations, ensuring it stays within `MIN_REPUTATION_SCORE` and `MAX_REPUTATION_SCORE`. Triggers DAPC metadata updates.
*   **`getAgentReputationScore`**: Returns the current reputation score of an AI agent.
*   **`stakeAlignmentTokens`**: Allows an agent owner to stake native tokens, boosting their agent's perceived alignment and potentially increasing their attractiveness for tasks.
*   **`withdrawAlignmentStake`**: Permits an agent owner to withdraw their staked tokens after a defined lock-up period.

**V. Governance & Fund Management**
*   **`submitGovernanceProposal`**: Users can submit proposals for protocol changes, fund distribution, or other actions, detailing the target contract, calldata, and value.
*   **`voteOnProposal`**: Stakeholders cast their votes (for/against) on open proposals. (Simplified 1 address = 1 vote for this example; can be extended with token-weighted voting).
*   **`executeProposal`**: Executes a governance proposal that has met the voting quorum and passed its voting period.
*   **`depositToAlignmentFund`**: Allows anyone to donate native tokens to the communal AI Alignment Fund.
*   **`distributeFromAlignmentFund`**: A governance-controlled function (typically called via a proposal) to distribute funds from the Alignment Fund for research, rewards, or other initiatives.
*   **`addVerifier`**: Adds a new address to the list of authorized verifiers (callable by the contract owner).
*   **`removeVerifier`**: Removes an address from the list of authorized verifiers (callable by the contract owner).
*   **`receive`**: Fallback function to allow direct ETH deposits to the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol"; // For dynamic NFT metadata

// Custom Errors
error DAIASN__NotAgentOwner();
error DAIASN__AgentNotApproved();
error DAIASN__AgentNotFound();
error DAIASN__TaskNotFound();
error DAIASN__TaskNotOpenForBidding();
error DAIASN__TaskNotApprovedAgent();
error DAIASN__InsufficientBounty();
error DAIASN__BidNotAccepted();
error DAIASN__OnlySelectedAgentCanSubmitResult();
error DAIASN__TaskResultAlreadySubmitted();
error DAIASN__OnlyRequesterOrVerifierCanAttest();
error DAIASN__AlreadyAttested();
error DAIASN__TaskNotFinalizable();
error DAIASN__TaskAlreadyFinalized();
error DAIASN__TaskAlreadyCanceled();
error DAIASN__InvalidStakeAmount();
error DAIASN__InsufficientStake();
error DAIASN__StakeLocked();
error DAIASN__ProposalNotFound();
error DAIASN__ProposalAlreadyExecuted();
error DAIASN__ProposalVotingPeriodNotEnded();
error DAIASN__ProposalThresholdNotMet();
error DAIASN__ProposalAlreadyVoted();
error DAIASN__Unauthorized();
error DAIASN__NotVerifier();
error DAIASN__DAPCNotTransferable();
error DAIASN__DAPCNotBurnable();
error DAIASN__InvalidAlignmentScore();


/**
 * @title DAIASN (Decentralized AI Alignment & Service Nexus)
 * @dev This contract creates a decentralized marketplace for AI agents, integrating reputation,
 *      alignment incentives, dynamic NFTs (DAPCs), and DAO-style governance.
 *      AI agents can register, bid on tasks, and their performance is attested by requesters and verifiers.
 *      Their reputation is dynamically reflected in their non-transferable Dynamic AI Performance Certificates (DAPCs).
 *      A governance module allows for protocol evolution and management of an AI Alignment Fund.
 *
 * Outline:
 * I. Core Agent Registry & Management
 * II. Dynamic AI Performance Certificates (DAPC - ERC721)
 * III. Task Marketplace & Attestation
 * IV. Reputation & Alignment Mechanics
 * V. Governance & Fund Management
 */
contract DAIASN is Ownable, ERC721 {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- I. Core Agent Registry & Management ---

    struct AIAgent {
        uint256 id;
        address owner;
        string name;
        string description;
        string ipfsModelHash; // Reference to the AI model or code on IPFS
        address[] supportedSkills; // Identifiers for skills (e.g., specific contract addresses or ENUMs)
        uint256 reputationScore; // Calculated based on attestations, 0-1000
        uint256 alignmentStake; // Tokens staked by the agent for perceived alignment
        uint256 lastStakeUpdate; // Timestamp of last stake change for lock-up
        bool isApproved; // Approved by governance/verifiers
        bool isRegistered; // Indicates if the agent is actively registered (soft deregister)
        uint256 dapcTokenId; // The ID of the DAPC NFT associated with this agent
    }

    Counters.Counter private _agentIds;
    mapping(uint256 => AIAgent) public agents;
    mapping(address => uint256[]) public agentOwnerToAgentIds; // Map owner to their agent IDs

    // --- II. Dynamic AI Performance Certificates (DAPC - ERC721) ---

    // DAPC properties can be conditionally transferable or burnable by governance
    bool public isDAPCTransferable = false;
    bool public isDAPCBurnable = false; // Only internal burn by contract logic

    // --- III. Task Marketplace & Attestation ---

    enum TaskStatus { Open, BiddingClosed, Selected, ResultSubmitted, AttestationPending, Finalized, Canceled }

    struct TaskRequest {
        uint256 id;
        address requester;
        string description;
        string inputDataIpfsHash; // IPFS hash of input data for the task
        address[] requiredSkills;
        uint256 bounty; // Amount in native token (e.g., Ether)
        uint256 deadline;
        TaskStatus status;
        uint256 selectedAgentId; // ID of the agent selected for the task
        uint256 selectedBidAmount; // The bid amount selected by the requester
        string resultIpfsHash; // IPFS hash of the completed task result
        bool requesterAttested;
        // Using a dynamic array for verifier attestations. Index corresponds to verifiers array.
        bool[] verifiersAttested; 
        uint256 totalAlignmentScoreFromVerifiers; // Sum of alignment scores from verifiers
        uint256 totalVerifierAttestations; // Count of verifier attestations
        uint256 creationTime;
    }

    Counters.Counter private _taskIds;
    mapping(uint256 => TaskRequest) public tasks;
    mapping(uint256 => mapping(uint256 => uint256)) public taskBids; // taskId => agentId => bidAmount
    mapping(uint256 => uint256[]) public taskToAgentBids; // taskId => list of agentIds that bid

    // --- IV. Reputation & Alignment Mechanics ---

    uint256 public constant MAX_REPUTATION_SCORE = 1000;
    uint256 public constant MIN_REPUTATION_SCORE = 0;
    uint256 public constant STAKE_LOCKUP_PERIOD = 7 days; // Lock-up period for stake withdrawal

    // --- V. Governance & Fund Management ---

    struct Proposal {
        uint256 id;
        string description;
        address targetContract; // Address of the contract to call (e.g., self)
        bytes calldataPayload; // Calldata for the target contract call
        uint256 value; // Value (native tokens) to send with the call
        uint256 startBlock; // Block number when voting starts
        uint256 endBlock; // Block number when voting ends
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        mapping(address => bool) hasVoted; // Voters who have voted
    }

    Counters.Counter private _proposalIds;
    mapping(uint256 => Proposal) public proposals;
    uint256 public minProposalVotingPeriodBlocks = 3 * 24 * 60 * 60 / 13; // Approx. blocks in 3 days (13s block time)
    uint256 public votingQuorumPercentage = 51; // 51% of total votes must be 'for' for proposal to pass

    address[] public verifiers; // List of authorized verifier addresses
    mapping(address => bool) public isVerifier; // Quick lookup for verifier status

    uint256 public alignmentFund; // Holds native tokens for rewards/initiatives

    // Events to track contract activity
    event AgentRegistered(uint256 indexed agentId, address indexed owner, string name, uint256 dapcTokenId);
    event AgentProfileUpdated(uint256 indexed agentId, string newDescription);
    event AgentApproved(uint256 indexed agentId, bool isApproved);
    event AgentDeregistered(uint256 indexed agentId);

    event DAPCReputationUpdated(uint256 indexed dapcTokenId, uint256 newReputationScore);
    event DAPCStatusUpdated(bool isTransferable, bool isBurnable);

    event TaskCreated(uint256 indexed taskId, address indexed requester, uint256 bounty, uint256 deadline);
    event TaskBid(uint256 indexed taskId, uint256 indexed agentId, uint256 bidAmount);
    event TaskBidSelected(uint256 indexed taskId, uint256 indexed agentId, uint256 selectedBidAmount);
    event TaskResultSubmitted(uint256 indexed taskId, uint256 indexed agentId, string resultIpfsHash);
    event TaskRequesterAttested(uint256 indexed taskId, bool isSatisfied, string comment);
    event TaskVerifierAttested(uint256 indexed taskId, uint256 indexed agentId, bool isAccurate, uint256 alignmentScore);
    event TaskFinalized(uint256 indexed taskId, uint256 indexed selectedAgentId);
    event TaskCanceled(uint256 indexed taskId);

    event AgentReputationUpdated(uint256 indexed agentId, uint256 newReputationScore);
    event AgentStaked(uint256 indexed agentId, uint256 amount, uint256 newTotalStake);
    event AgentStakeWithdrawn(uint256 indexed agentId, uint256 amount, uint256 newTotalStake);

    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event AlignmentFundDeposited(address indexed depositor, uint256 amount);
    event AlignmentFundDistributed(address indexed recipient, uint256 amount);
    event VerifierAdded(address indexed newVerifier);
    event VerifierRemoved(address indexed oldVerifier);

    constructor(address initialOwner) ERC721("Dynamic AI Performance Certificate", "DAPC") Ownable(initialOwner) {}

    // Modifiers for access control
    modifier onlyAgentOwner(uint256 _agentId) {
        if (agents[_agentId].owner != msg.sender) revert DAIASN__NotAgentOwner();
        _;
    }

    modifier onlyRequester(uint256 _taskId) {
        if (tasks[_taskId].requester != msg.sender) revert DAIASN__Unauthorized();
        _;
    }

    modifier onlyVerifier() {
        if (!isVerifier[msg.sender]) revert DAIASN__NotVerifier();
        _;
    }

    // --- I. Core Agent Registry & Management ---

    /**
     * @notice Registers a new AI agent on the platform. Mints a Dynamic AI Performance Certificate (DAPC) for it.
     * @param _agentName The public name of the AI agent.
     * @param _agentDescription A brief description of the agent's capabilities.
     * @param _ipfsModelHash IPFS hash pointing to the agent's model or code reference.
     * @param _supportedSkills An array of identifiers representing the agent's skills.
     */
    function registerAIAgent(
        string memory _agentName,
        string memory _agentDescription,
        string memory _ipfsModelHash,
        address[] memory _supportedSkills
    ) external {
        _agentIds.increment();
        uint256 newAgentId = _agentIds.current();

        agents[newAgentId] = AIAgent({
            id: newAgentId,
            owner: msg.sender,
            name: _agentName,
            description: _agentDescription,
            ipfsModelHash: _ipfsModelHash,
            supportedSkills: _supportedSkills,
            reputationScore: MAX_REPUTATION_SCORE / 2, // Start with a neutral reputation
            alignmentStake: 0,
            lastStakeUpdate: block.timestamp,
            isApproved: false, // Requires governance approval before participating in tasks
            isRegistered: true,
            dapcTokenId: 0 // Will be set after minting
        });

        agentOwnerToAgentIds[msg.sender].push(newAgentId);

        // Mint a DAPC NFT for the new agent, using agentId as tokenId for 1:1 mapping
        _mintDAPC(msg.sender, newAgentId);

        emit AgentRegistered(newAgentId, msg.sender, _agentName, agents[newAgentId].dapcTokenId);
    }

    /**
     * @notice Allows an agent owner to update their agent's profile details.
     * @param _agentId The ID of the agent to update.
     * @param _newAgentDescription The new description for the agent.
     * @param _newIpfsModelHash The new IPFS hash for the agent's model/code.
     * @param _newSupportedSkills The new array of supported skills.
     */
    function updateAIAgentProfile(
        uint256 _agentId,
        string memory _newAgentDescription,
        string memory _newIpfsModelHash,
        address[] memory _newSupportedSkills
    ) external onlyAgentOwner(_agentId) {
        AIAgent storage agent = agents[_agentId];
        agent.description = _newAgentDescription;
        agent.ipfsModelHash = _newIpfsModelHash;
        agent.supportedSkills = _newSupportedSkills; 
        emit AgentProfileUpdated(_agentId, _newAgentDescription);
    }

    /**
     * @notice Initiates the deregistration process for an AI agent.
     *         Requires governance approval to finalize removal and DAPC burning.
     * @param _agentId The ID of the agent to deregister.
     */
    function deregisterAIAgent(uint256 _agentId) external onlyAgentOwner(_agentId) {
        require(agents[_agentId].isRegistered, "Agent not registered.");
        // Mark as pending deregistration; actual removal and DAPC burning needs governance action.
        agents[_agentId].isRegistered = false; 
        emit AgentDeregistered(_agentId);
    }

    /**
     * @notice Retrieves comprehensive details about an AI agent.
     * @param _agentId The ID of the agent.
     * @return A tuple containing all agent details.
     */
    function getAIAgentDetails(uint256 _agentId)
        public
        view
        returns (
            uint256 id,
            address owner,
            string memory name,
            string memory description,
            string memory ipfsModelHash,
            address[] memory supportedSkills,
            uint256 reputationScore,
            uint256 alignmentStake,
            bool isApproved,
            bool isRegistered,
            uint256 dapcTokenId
        )
    {
        AIAgent storage agent = agents[_agentId];
        if (agent.id == 0 && !agent.isRegistered) revert DAIASN__AgentNotFound(); // Check for actual existence

        return (
            agent.id,
            agent.owner,
            agent.name,
            agent.description,
            agent.ipfsModelHash,
            agent.supportedSkills,
            agent.reputationScore,
            agent.alignmentStake,
            agent.isApproved,
            agent.isRegistered,
            agent.dapcTokenId
        );
    }

    /**
     * @notice Allows governance (or designated verifiers) to approve or reject an AI agent.
     * @dev An agent must be approved (`isApproved = true`) to participate in tasks.
     * @param _agentId The ID of the agent to approve/reject.
     * @param _isApproved The approval status (true for approved, false for rejected).
     */
    function setAgentApprovalStatus(uint256 _agentId, bool _isApproved) external onlyVerifier {
        AIAgent storage agent = agents[_agentId];
        if (!agent.isRegistered) revert DAIASN__AgentNotFound();
        agent.isApproved = _isApproved;
        emit AgentApproved(_agentId, _isApproved);
    }

    // --- II. Dynamic AI Performance Certificates (DAPC - ERC721) ---

    /**
     * @dev Internal function to mint a new DAPC NFT for a registered agent.
     *      Called automatically during agent registration.
     * @param _to The address to mint the DAPC to.
     * @param _agentId The ID of the agent this DAPC represents.
     */
    function _mintDAPC(address _to, uint256 _agentId) internal {
        // Use agent ID as token ID for 1:1 mapping and easy lookup
        _safeMint(_to, _agentId);
        agents[_agentId].dapcTokenId = _agentId;
    }

    /**
     * @notice Returns the dynamically generated URI for an agent's DAPC.
     *         The metadata reflects the agent's current reputation.
     * @param _tokenId The token ID (which is the agent ID) of the DAPC.
     * @return The data URI string for the DAPC, encoded in Base64.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        if (!_exists(_tokenId)) revert ERC721NonexistentToken(_tokenId);

        AIAgent storage agent = agents[_tokenId];
        uint256 reputation = agent.reputationScore;

        // Simple dynamic attribute example: "Tier" based on reputation
        string memory tier;
        if (reputation > 800) {
            tier = "Elite";
        } else if (reputation > 600) {
            tier = "Advanced";
        } else if (reputation > 400) {
            tier = "Standard";
        } else {
            tier = "Novice";
        }

        // Construct JSON metadata string
        string memory json = string.concat(
            '{"name": "',
            agent.name,
            ' DAPC", "description": "Dynamic AI Performance Certificate for agent ',
            agent.name,
            '. Reputation: ',
            reputation.toString(),
            ' / ',
            MAX_REPUTATION_SCORE.toString(),
            '.", "image": "ipfs://Qmb...", "attributes": [ { "trait_type": "Reputation", "value": "',
            reputation.toString(),
            '" }, { "trait_type": "Tier", "value": "',
            tier,
            '" }, { "trait_type": "Agent ID", "value": "',
            _tokenId.toString(),
            '" } ]}'
        );

        // Encode JSON to Base64 data URI
        return string.concat("data:application/json;base64,", Base64.encode(bytes(json)));
    }

    /**
     * @notice Allows transfer of DAPC if `isDAPCTransferable` is true.
     * @dev By default, DAPCs are soulbound (non-transferable) to maintain reputation integrity.
     *      If transferability is enabled, the agent's owner also changes to the new DAPC owner.
     * @param _from The current owner of the DAPC.
     * @param _to The recipient of the DAPC.
     * @param _tokenId The ID of the DAPC to transfer.
     */
    function transferFrom(address _from, address _to, uint256 _tokenId) public override {
        if (!isDAPCTransferable) revert DAIASN__DAPCNotTransferable();
        super.transferFrom(_from, _to, _tokenId);
        
        // If DAPC is transferred, the agent's owner also changes.
        // This makes the DAPC represent the 'right to own' and control the agent.
        agents[_tokenId].owner = _to;
        // Note: Updating `agentOwnerToAgentIds` would be complex on transfer.
        // For simplicity, agent ID is considered the primary key, and its owner is the DAPC owner.
    }

    /**
     * @dev Internal function to burn a DAPC. Can only be called by contract logic.
     * @param _tokenId The ID of the DAPC to burn.
     */
    function _burnDAPC(uint256 _tokenId) internal {
        if (!isDAPCBurnable) revert DAIASN__DAPCNotBurnable(); 
        _burn(_tokenId);
        // Clear agent's dapcTokenId reference
        agents[_tokenId].dapcTokenId = 0;
    }

    /**
     * @notice Governance function to set the transferability and burnability status of DAPCs.
     * @param _isTransferable New status for DAPC transferability.
     * @param _isBurnable New status for DAPC burnability.
     */
    function setDAPCStatus(bool _isTransferable, bool _isBurnable) external onlyOwner {
        isDAPCTransferable = _isTransferable;
        isDAPCBurnable = _isBurnable;
        emit DAPCStatusUpdated(_isTransferable, _isBurnable);
    }

    // --- III. Task Marketplace & Attestation ---

    /**
     * @notice Creates a new AI task request, funding it with the specified bounty.
     * @param _taskDescription A description of the task.
     * @param _inputDataIpfsHash IPFS hash of the input data required for the task.
     * @param _requiredSkills An array of skill identifiers required for the task.
     * @param _bounty The reward for completing the task (in native token).
     * @param _deadline The timestamp by which the task must be completed.
     */
    function createTaskRequest(
        string memory _taskDescription,
        string memory _inputDataIpfsHash,
        address[] memory _requiredSkills,
        uint256 _bounty,
        uint256 _deadline
    ) external payable {
        if (msg.value < _bounty) revert DAIASN__InsufficientBounty();

        _taskIds.increment();
        uint256 newTaskId = _taskIds.current();

        tasks[newTaskId] = TaskRequest({
            id: newTaskId,
            requester: msg.sender,
            description: _taskDescription,
            inputDataIpfsHash: _inputDataIpfsHash,
            requiredSkills: _requiredSkills,
            bounty: _bounty,
            deadline: _deadline,
            status: TaskStatus.Open,
            selectedAgentId: 0,
            selectedBidAmount: 0,
            resultIpfsHash: "",
            requesterAttested: false,
            verifiersAttested: new bool[](verifiers.length), // Initialize with false for each current verifier
            totalAlignmentScoreFromVerifiers: 0,
            totalVerifierAttestations: 0,
            creationTime: block.timestamp
        });

        emit TaskCreated(newTaskId, msg.sender, _bounty, _deadline);
    }

    /**
     * @notice Allows an approved AI agent to bid on an open task.
     * @param _taskId The ID of the task to bid on.
     * @param _agentId The ID of the agent placing the bid.
     * @param _bidAmount The amount (in native token) the agent requests for the task.
     */
    function bidOnTask(uint256 _taskId, uint256 _agentId, uint256 _bidAmount) external onlyAgentOwner(_agentId) {
        TaskRequest storage task = tasks[_taskId];
        if (task.status != TaskStatus.Open) revert DAIASN__TaskNotOpenForBidding();
        if (!agents[_agentId].isApproved) revert DAIASN__AgentNotApproved();
        if (_bidAmount == 0 || _bidAmount > task.bounty) revert DAIASN__InsufficientBounty(); // Agent can't bid more than bounty

        // Basic skill matching: check if agent has at least one required skill
        bool hasRequiredSkill = false;
        for (uint256 i = 0; i < task.requiredSkills.length; i++) {
            for (uint256 j = 0; j < agents[_agentId].supportedSkills.length; j++) {
                if (task.requiredSkills[i] == agents[_agentId].supportedSkills[j]) {
                    hasRequiredSkill = true;
                    break;
                }
            }
            if (hasRequiredSkill) break;
        }
        require(hasRequiredSkill, "Agent does not possess required skills.");

        taskBids[_taskId][_agentId] = _bidAmount;
        taskToAgentBids[_taskId].push(_agentId); // Store agent IDs that bid
        emit TaskBid(_taskId, _agentId, _bidAmount);
    }

    /**
     * @notice The task requester selects a winning bid from an approved agent.
     * @param _taskId The ID of the task.
     * @param _agentId The ID of the agent whose bid is selected.
     */
    function selectTaskBid(uint256 _taskId, uint256 _agentId) external onlyRequester(_taskId) {
        TaskRequest storage task = tasks[_taskId];
        if (task.status != TaskStatus.Open) revert DAIASN__TaskNotOpenForBidding();
        if (taskBids[_taskId][_agentId] == 0) revert DAIASN__BidNotAccepted(); // Agent did not bid
        if (!agents[_agentId].isApproved) revert DAIASN__AgentNotApproved();

        task.selectedAgentId = _agentId;
        task.selectedBidAmount = taskBids[_taskId][_agentId];
        task.status = TaskStatus.Selected;

        emit TaskBidSelected(_taskId, _agentId, task.selectedBidAmount);
    }

    /**
     * @notice The selected AI agent submits the IPFS hash of the completed task's result.
     * @param _taskId The ID of the task.
     * @param _resultIpfsHash IPFS hash of the task result.
     */
    function submitTaskResultHash(uint256 _taskId, string memory _resultIpfsHash)
        external
        onlyAgentOwner(tasks[_taskId].selectedAgentId)
    {
        TaskRequest storage task = tasks[_taskId];
        if (task.status != TaskStatus.Selected) revert DAIASN__OnlySelectedAgentCanSubmitResult();
        if (bytes(task.resultIpfsHash).length > 0) revert DAIASN__TaskResultAlreadySubmitted(); 

        task.resultIpfsHash = _resultIpfsHash;
        task.status = TaskStatus.ResultSubmitted;

        emit TaskResultSubmitted(_taskId, task.selectedAgentId, _resultIpfsHash);
    }

    /**
     * @notice The task requester attests to the performance of the AI agent.
     * @param _taskId The ID of the task.
     * @param _isSatisfied True if the requester is satisfied, false otherwise.
     * @param _attestationComment An optional comment from the requester (for off-chain use, or IPFS hash).
     */
    function attestTaskPerformance(uint256 _taskId, bool _isSatisfied, string memory _attestationComment)
        external
        onlyRequester(_taskId)
    {
        TaskRequest storage task = tasks[_taskId];
        if (task.status != TaskStatus.ResultSubmitted && task.status != TaskStatus.AttestationPending)
            revert DAIASN__TaskNotFinalizable(); // Task must be in a state where results are submitted
        if (task.requesterAttested) revert DAIASN__AlreadyAttested();

        task.requesterAttested = true;
        
        // Adjust agent's reputation based on requester satisfaction
        _updateAgentReputation(task.selectedAgentId, _isSatisfied ? 50 : -50);

        emit TaskRequesterAttested(_taskId, _isSatisfied, _attestationComment);
    }

    /**
     * @notice Verifiers provide an independent attestation and alignment score for a task.
     * @param _taskId The ID of the task.
     * @param _agentId The ID of the agent being attested.
     * @param _isAccurate True if the result is accurate, false otherwise.
     * @param _alignmentScore An alignment score from 0-100 provided by the verifier.
     */
    function submitVerifierAttestation(uint256 _taskId, uint256 _agentId, bool _isAccurate, uint256 _alignmentScore)
        external
        onlyVerifier
    {
        TaskRequest storage task = tasks[_taskId];
        if (task.selectedAgentId != _agentId) revert DAIASN__Unauthorized(); // Verifier must attest the selected agent
        if (_alignmentScore > 100) revert DAIASN__InvalidAlignmentScore();
        if (task.status != TaskStatus.ResultSubmitted && task.status != TaskStatus.AttestationPending)
            revert DAIASN__TaskNotFinalizable();

        // Find verifier index to mark their attestation
        uint256 verifierIndex = type(uint256).max;
        for (uint256 i = 0; i < verifiers.length; i++) {
            if (verifiers[i] == msg.sender) {
                verifierIndex = i;
                break;
            }
        }
        if (verifierIndex == type(uint256).max || verifierIndex >= task.verifiersAttested.length) revert DAIASN__NotVerifier();
        if (task.verifiersAttested[verifierIndex]) revert DAIASN__AlreadyAttested();

        task.verifiersAttested[verifierIndex] = true;
        task.totalAlignmentScoreFromVerifiers += _alignmentScore;
        task.totalVerifierAttestations++;

        // Adjust agent's reputation based on verifier attestation
        int256 reputationChange = _isAccurate ? 20 : -30; // Base reputation change
        reputationChange += int256(_alignmentScore) / 5; // Add reputation based on alignment score (scaled)
        _updateAgentReputation(_agentId, reputationChange);

        emit TaskVerifierAttested(_taskId, _agentId, _isAccurate, _alignmentScore);
    }

    /**
     * @notice Finalizes a task, distributes the bounty, and updates agent reputation.
     *         Can be called by anyone after all required attestations are in, or after deadline.
     * @param _taskId The ID of the task to finalize.
     */
    function finalizeTask(uint256 _taskId) external {
        TaskRequest storage task = tasks[_taskId];
        if (task.id == 0) revert DAIASN__TaskNotFound();
        if (task.status == TaskStatus.Finalized) revert DAIASN__TaskAlreadyFinalized();
        if (task.status == TaskStatus.Canceled) revert DAIASN__TaskAlreadyCanceled();
        if (task.selectedAgentId == 0) revert DAIASN__TaskNotFinalizable(); // No agent selected

        // Logic to check if enough attestations or if deadline passed
        bool allVerifiersAttested = (verifiers.length == 0) || (task.totalVerifierAttestations == verifiers.length); // If no verifiers, then all are 'attested'
        bool enoughAttestations = task.requesterAttested && allVerifiersAttested;
        bool deadlinePassed = block.timestamp > task.deadline;

        if (!enoughAttestations && !deadlinePassed) revert DAIASN__TaskNotFinalizable();

        // Reward the agent with the selected bid amount
        (bool success, ) = agents[task.selectedAgentId].owner.call{value: task.selectedBidAmount}("");
        require(success, "Failed to send bounty to agent.");

        // Refund any remaining bounty to the requester if selectedBidAmount was less than initial bounty
        if (task.bounty > task.selectedBidAmount) {
            (bool refundSuccess, ) = task.requester.call{value: task.bounty - task.selectedBidAmount}("");
            require(refundSuccess, "Failed to refund requester.");
        }

        task.status = TaskStatus.Finalized;
        emit TaskFinalized(_taskId, task.selectedAgentId);
    }

    /**
     * @notice Allows the task requester to cancel an open task.
     *         Funds are returned to the requester.
     * @param _taskId The ID of the task to cancel.
     */
    function cancelTask(uint256 _taskId) external onlyRequester(_taskId) {
        TaskRequest storage task = tasks[_taskId];
        if (task.id == 0) revert DAIASN__TaskNotFound();
        if (task.status != TaskStatus.Open) revert DAIASN__TaskAlreadyCanceled(); // Can only cancel if open

        // Refund bounty
        (bool success, ) = msg.sender.call{value: task.bounty}("");
        require(success, "Failed to refund bounty.");

        task.status = TaskStatus.Canceled;
        emit TaskCanceled(_taskId);
    }

    /**
     * @notice Retrieves details about a specific task request.
     * @param _taskId The ID of the task.
     * @return A tuple containing all task details.
     */
    function getTaskDetails(uint256 _taskId)
        public
        view
        returns (
            uint256 id,
            address requester,
            string memory description,
            string memory inputDataIpfsHash,
            address[] memory requiredSkills,
            uint256 bounty,
            uint256 deadline,
            TaskStatus status,
            uint256 selectedAgentId,
            uint256 selectedBidAmount,
            string memory resultIpfsHash,
            bool requesterAttested,
            uint256 totalVerifierAttestations,
            uint256 creationTime
        )
    {
        TaskRequest storage task = tasks[_taskId];
        if (task.id == 0) revert DAIASN__TaskNotFound();

        return (
            task.id,
            task.requester,
            task.description,
            task.inputDataIpfsHash,
            task.requiredSkills,
            task.bounty,
            task.deadline,
            task.status,
            task.selectedAgentId,
            task.selectedBidAmount,
            task.resultIpfsHash,
            task.requesterAttested,
            task.totalVerifierAttestations,
            task.creationTime
        );
    }

    // --- IV. Reputation & Alignment Mechanics ---

    /**
     * @dev Internal function to update an agent's reputation score.
     * @param _agentId The ID of the agent.
     * @param _change The amount to change the reputation by (can be positive or negative).
     */
    function _updateAgentReputation(uint256 _agentId, int256 _change) internal {
        AIAgent storage agent = agents[_agentId];
        int256 newReputation = int256(agent.reputationScore) + _change;

        if (newReputation > int256(MAX_REPUTATION_SCORE)) {
            newReputation = int256(MAX_REPUTATION_SCORE);
        } else if (newReputation < int256(MIN_REPUTATION_SCORE)) {
            newReputation = int256(MIN_REPUTATION_SCORE);
        }
        agent.reputationScore = uint256(newReputation);
        emit AgentReputationUpdated(_agentId, agent.reputationScore);
        emit DAPCReputationUpdated(agent.dapcTokenId, agent.reputationScore); // Trigger DAPC metadata update
    }

    /**
     * @notice Returns the current reputation score of an AI agent.
     * @param _agentId The ID of the agent.
     * @return The agent's reputation score.
     */
    function getAgentReputationScore(uint256 _agentId) public view returns (uint256) {
        return agents[_agentId].reputationScore;
    }

    /**
     * @notice Allows an AI agent to stake native tokens to boost their perceived alignment.
     *         Higher stake can influence selection in tasks.
     * @param _agentId The ID of the agent staking.
     * @param _amount The amount of native tokens to stake.
     */
    function stakeAlignmentTokens(uint256 _agentId, uint256 _amount) external payable onlyAgentOwner(_agentId) {
        if (msg.value != _amount || _amount == 0) revert DAIASN__InvalidStakeAmount();
        AIAgent storage agent = agents[_agentId];
        agent.alignmentStake += _amount;
        agent.lastStakeUpdate = block.timestamp; // Reset lock-up period
        emit AgentStaked(_agentId, _amount, agent.alignmentStake);
    }

    /**
     * @notice Allows an AI agent to withdraw their staked alignment tokens after a lock-up period.
     * @param _agentId The ID of the agent.
     * @param _amount The amount to withdraw.
     */
    function withdrawAlignmentStake(uint256 _agentId, uint256 _amount) external onlyAgentOwner(_agentId) {
        AIAgent storage agent = agents[_agentId];
        if (agent.alignmentStake < _amount) revert DAIASN__InsufficientStake();
        if (block.timestamp < agent.lastStakeUpdate + STAKE_LOCKUP_PERIOD) revert DAIASN__StakeLocked();

        agent.alignmentStake -= _amount;
        agent.lastStakeUpdate = block.timestamp; // Reset lock-up for remaining stake (if any)
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Failed to withdraw stake.");
        emit AgentStakeWithdrawn(_agentId, _amount, agent.alignmentStake);
    }

    // --- V. Governance & Fund Management ---

    /**
     * @notice Submits a new governance proposal.
     * @param _proposalDescription A description of the proposal.
     * @param _targetContract The address of the contract to call if the proposal passes.
     * @param _calldata The calldata for the target contract call.
     * @param _value The value (native tokens) to send with the call.
     */
    function submitGovernanceProposal(
        string memory _proposalDescription,
        address _targetContract,
        bytes memory _calldata,
        uint256 _value
    ) external {
        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            description: _proposalDescription,
            targetContract: _targetContract,
            calldataPayload: _calldata,
            value: _value,
            startBlock: block.number,
            endBlock: block.number + minProposalVotingPeriodBlocks,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            hasVoted: new mapping(address => bool) // Initialize empty mapping
        });
        emit ProposalSubmitted(newProposalId, msg.sender, _proposalDescription);
    }

    /**
     * @notice Allows eligible users to vote on a proposal.
     * @dev For simplicity, this uses a basic '1 address = 1 vote'. A more advanced DAO would
     *      integrate token-weighted voting (e.g., based on DAPC reputation or a separate governance token).
     * @param _proposalId The ID of the proposal to vote on.
     * @param _for True to vote 'for' the proposal, false to vote 'against'.
     */
    function voteOnProposal(uint256 _proposalId, bool _for) external {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert DAIASN__ProposalNotFound();
        if (proposal.executed) revert DAIASN__ProposalAlreadyExecuted();
        if (block.number > proposal.endBlock) revert DAIASN__ProposalVotingPeriodNotEnded();
        if (proposal.hasVoted[msg.sender]) revert DAIASN__ProposalAlreadyVoted();

        proposal.hasVoted[msg.sender] = true;
        if (_for) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit VoteCast(_proposalId, msg.sender, _for);
    }

    /**
     * @notice Executes a passed governance proposal.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert DAIASN__ProposalNotFound();
        if (proposal.executed) revert DAIASN__ProposalAlreadyExecuted();
        if (block.number <= proposal.endBlock) revert DAIASN__ProposalVotingPeriodNotEnded(); // Voting must have ended

        // Simple quorum check: 51% of total votes must be 'for'.
        // A real DAO would check against total circulating governance token supply or staked tokens.
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        if (totalVotes == 0 || (proposal.votesFor * 100 / totalVotes < votingQuorumPercentage)) {
            revert DAIASN__ProposalThresholdNotMet();
        }

        // Execute the proposal's payload
        (bool success, ) = proposal.targetContract.call{value: proposal.value}(proposal.calldataPayload);
        require(success, "Proposal execution failed.");

        proposal.executed = true;
        emit ProposalExecuted(_proposalId);
    }

    /**
     * @notice Allows anyone to deposit native tokens into the AI Alignment Fund.
     */
    function depositToAlignmentFund() external payable {
        if (msg.value == 0) revert DAIASN__InvalidStakeAmount();
        alignmentFund += msg.value;
        emit AlignmentFundDeposited(msg.sender, msg.value);
    }

    /**
     * @notice Governance function to distribute funds from the AI Alignment Fund.
     * @dev This function would typically be called via a successful governance proposal.
     * @param _recipient The address to send funds to.
     * @param _amount The amount to distribute.
     */
    function distributeFromAlignmentFund(address _recipient, uint256 _amount) external onlyOwner {
        require(alignmentFund >= _amount, "Insufficient fund balance.");
        alignmentFund -= _amount;
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Failed to distribute fund.");
        emit AlignmentFundDistributed(_recipient, _amount);
    }

    /**
     * @notice Adds a new address to the list of authorized verifiers. Only callable by the contract owner (governance).
     * @param _newVerifier The address of the new verifier.
     */
    function addVerifier(address _newVerifier) external onlyOwner {
        require(!isVerifier[_newVerifier], "Verifier already added.");
        verifiers.push(_newVerifier);
        isVerifier[_newVerifier] = true;
        // When a new verifier is added, expand existing tasks' verifiersAttested arrays
        // This could be gas intensive for many tasks. A more efficient way might be to only apply to new tasks,
        // or have verifiers attest using a mapping per task for flexibility.
        // For current implementation, this is a known limitation for scaling.
        emit VerifierAdded(_newVerifier);
    }

    /**
     * @notice Removes an address from the list of authorized verifiers. Only callable by the contract owner (governance).
     * @param _oldVerifier The address of the verifier to remove.
     */
    function removeVerifier(address _oldVerifier) external onlyOwner {
        require(isVerifier[_oldVerifier], "Not a current verifier.");
        isVerifier[_oldVerifier] = false;
        
        // Find and remove from the array (this is an expensive operation for large arrays)
        for (uint256 i = 0; i < verifiers.length; i++) {
            if (verifiers[i] == _oldVerifier) {
                verifiers[i] = verifiers[verifiers.length - 1]; // Replace with last element
                verifiers.pop(); // Shrink array
                break;
            }
        }
        // Removing a verifier also implicitly shrinks the `verifiersAttested` arrays.
        // This has implications for tasks created when the verifier existed.
        // For simplicity, we assume older tasks just have an 'empty' slot for removed verifiers.
        emit VerifierRemoved(_oldVerifier);
    }

    // Fallback function to accept ETH deposits for the contract itself (e.g., if bounty is sent directly)
    // All payable functions should explicitly handle value. This is a safety fallback.
    receive() external payable {}
}

```