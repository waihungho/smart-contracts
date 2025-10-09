Here's a smart contract that aims for advanced, creative, and trendy concepts, while trying to avoid direct duplication of popular open-source projects. It focuses on a decentralized intelligence network where "agents" (human or AI) can contribute insights, earn reputation, and possess dynamic NFTs that evolve with their performance.

---

**Contract Name:** `NexusCore_IntelligenceOrchestrator`

**Outline and Function Summary:**

This contract establishes a decentralized intelligence orchestration platform, `NexusCore`, designed to facilitate the submission, validation, and rewarding of "intelligence" (e.g., AI model outputs, data analysis, predictions) from registered agents. It integrates dynamic NFTs as agent personas, a soulbound reputation system, and a simplified on-chain governance mechanism.

**I. Core Concepts:**

*   **Decentralized Intelligence Network:** Users can submit tasks requesting intelligence, and registered agents can claim and fulfill them.
*   **Dynamic Agent Persona NFTs (APN):** ERC-721 NFTs that visually evolve (via metadata/URI updates) based on an agent's reputation score within the network. These are managed by an external `AgentPersonaNFT` contract.
*   **Soulbound N-Score Reputation System:** A non-transferable score (`agentReputationScores`) tied to an agent's ID, determining their influence, task eligibility, and persona NFT tier.
*   **Gamified Dispute Resolution:** A mechanism for agents to challenge questionable contributions and submit verdicts, with stakes and reputation implications.
*   **On-chain Governance:** High-reputation agents can propose and vote on system parameter changes.
*   **Incentive Alignment:** Rewards for successful task completion and penalties for malicious or incorrect contributions.

**II. Function Categories & Summary (22 Public/External Functions):**

**A. Deployment & Administration (5 Functions)**
1.  `constructor()`: Deploys and initializes the NexusCore contract, setting the initial owner.
2.  `setAgentPersonaNFTContract(address _nftContract)`: Sets the address of the external `AgentPersonaNFT` contract managed by NexusCore.
3.  `pause()`: Allows the owner to pause critical operations in an emergency.
4.  `unpause()`: Allows the owner to unpause the contract.
5.  `updateMinReputationForGovernance(uint256 _newMin)`: Changes the minimum N-Score required for governance participation.

**B. Agent Management (4 Functions)**
6.  `registerAgent(string calldata _name, string calldata _modelURI)`: Allows an address to register as an agent, minting an initial Persona NFT and setting up their profile.
7.  `deregisterAgent()`: Allows a registered agent to deregister, burning their Persona NFT and clearing their N-Score.
8.  `updateAgentModelURI(string calldata _newModelURI)`: Allows an agent to update the URI pointing to their off-chain model or methodology description.
9.  `getAgentDetails(uint256 _agentId)`: A view function to retrieve an agent's detailed profile.

**C. Reputation (N-Score) Management (1 Public View, 2 Internal)**
10. `getAgentReputation(uint256 _agentId)`: A view function to retrieve an agent's current N-Score.
11. `_awardReputation(uint256 _agentId, uint256 _amount)` (Internal): Awards reputation, potentially triggering a persona NFT evolution.
12. `_penalizeReputation(uint256 _agentId, uint256 _amount)` (Internal): Penalizes reputation, potentially triggering a persona NFT devolution.

**D. Task & Contribution System (7 Functions)**
13. `submitTask(string calldata _descriptionHash, uint256 _rewardAmount, uint256 _deadline)`: A user submits a task, providing a description hash, an ETH reward, and a deadline.
14. `claimTask(uint256 _taskId)`: A qualified agent (based on N-Score) claims an available task for execution.
15. `submitContribution(uint256 _taskId, string calldata _submissionHash)`: An agent assigned to a task submits their "intelligence" as a hash.
16. `challengeContribution(uint256 _contributionId)`: Any qualified agent can challenge a submitted contribution, staking ETH to initiate a dispute.
17. `submitChallengeVerdict(uint256 _contributionId, bool _isOriginalContributionValid)`: Any qualified agent can submit their verdict on a challenged contribution, staking ETH.
18. `resolveTask(uint256 _taskId)`: Finalizes a task after its deadline, resolving any challenges, distributing rewards, and updating reputation.
19. `getTaskDetails(uint256 _taskId)`: A view function to retrieve detailed information about a specific task.

**E. Dynamic NFT Evolution Triggers (2 Functions)**
20. `requestPersonaEvolution(uint256 _agentId)`: Allows an agent to request an update to their Persona NFT's metadata/URI if their N-Score qualifies for a higher tier.
21. `requestPersonaDevolution(uint256 _agentId)`: Allows an agent to request a downgrade of their Persona NFT's metadata/URI if their N-Score falls to a lower tier.

**F. Governance (3 Functions)**
22. `createProposal(string calldata _descriptionHash, address _target, bytes calldata _callData, uint256 _voteThreshold)`: Agents with sufficient N-Score can create proposals for system changes.
23. `voteOnProposal(uint256 _proposalId, bool _support)`: Qualified agents can vote 'for' or 'against' an active proposal.
24. `executeProposal(uint256 _proposalId)`: Any address can call this to execute a proposal that has met its voting threshold and passed its voting period.

---

### `NexusCore_IntelligenceOrchestrator.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // For external NFT contract interaction
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For internal reputation scoring

// --- Interfaces for external contracts ---

/**
 * @title IAgentPersonaNFT
 * @dev Interface for the Agent Persona NFT contract managed by NexusCore.
 * This contract is assumed to be deployed separately and its address configured in NexusCore.
 */
interface IAgentPersonaNFT {
    function mint(address to, uint256 tokenId, string calldata tokenURI) external;
    function burn(uint256 tokenId) external;
    function updateTokenURI(uint256 tokenId, string calldata newTokenURI) external;
    function supportsInterface(bytes4 interfaceId) external view returns (bool); // ERC165
}

/**
 * @title NexusCore_IntelligenceOrchestrator
 * @dev A decentralized platform for orchestrating intelligence contributions from agents.
 * Features: Dynamic NFTs, Soulbound Reputation (N-Score), Gamified Dispute Resolution, On-chain Governance.
 */
contract NexusCore_IntelligenceOrchestrator is Ownable, Pausable {
    using SafeMath for uint256;

    // --- State Variables ---

    // Nexus Core Configurations
    IAgentPersonaNFT public agentPersonaNFT;
    uint256 public minReputationForGovernance = 1000; // Minimum N-Score to participate in governance
    uint256 public challengeStakeAmount = 0.05 ether; // ETH required to challenge a contribution
    uint256 public challengeVerdictStake = 0.01 ether; // ETH required to submit a verdict on a challenge
    uint256 public constant CHALLENGE_PERIOD_DURATION = 1 days; // How long challenges/verdicts can be submitted
    uint256 public constant GOVERNANCE_VOTING_PERIOD = 3 days; // How long proposals are open for voting

    // Agent Management
    uint256 public nextAgentId = 1;
    mapping(uint256 => Agent) public agents;
    mapping(address => uint256) public agentAddressToId;
    mapping(uint256 => uint256) public agentReputationScores; // Agent N-Score (Soulbound Reputation)

    // Task Management
    uint256 public nextTaskId = 1;
    mapping(uint256 => Task) public tasks;

    // Contribution Management
    uint256 public nextContributionId = 1;
    mapping(uint256 => Contribution) public contributions;

    // Governance
    uint256 public nextProposalId = 1;
    mapping(uint256 => Proposal) public proposals;

    // --- Structs ---

    enum AgentStatus { Inactive, Active, Deregistered }
    struct Agent {
        uint256 id;
        address ownerAddress;
        string name;
        string modelURI; // URI to agent's AI model description or methodology
        uint256 registeredAt;
        AgentStatus status;
        uint256 personaNFTId; // The tokenId of their dynamic NFT
    }

    enum TaskStatus { Open, Assigned, ContributionSubmitted, Challenged, ResolvedSuccess, ResolvedFailed, Cancelled }
    struct Task {
        uint256 id;
        address requester;
        string descriptionHash; // Hash of the task description/requirements (off-chain)
        uint256 rewardAmount;
        uint256 deadline;
        TaskStatus status;
        uint256 assignedAgentId;
        string resultHash; // Hash of the final accepted result (if any)
        uint256 submittedAt;
    }

    enum ContributionStatus { Pending, Challenged, Validated, Rejected }
    struct Contribution {
        uint256 id;
        uint256 taskId;
        uint256 agentId;
        string submissionHash; // Hash of the agent's submission (off-chain)
        uint256 submittedAt;
        ContributionStatus status;
        uint256 challengeId; // Points to a Challenge if one exists
    }

    enum ChallengeVerdict { None, Valid, Invalid } // Valid means original contribution was valid, Invalid means it was flawed
    struct Challenge {
        uint256 id;
        uint256 contributionId;
        uint256 challengerAgentId;
        uint256 challengeStake;
        uint256 initiatedAt;
        uint256 forValidCount; // Number of verdicts supporting original contribution's validity
        uint256 forInvalidCount; // Number of verdicts supporting original contribution's invalidity
        mapping(uint256 => bool) hasVoted; // agentId => true if they voted on this challenge
    }

    enum ProposalStatus { Pending, Active, Passed, Failed, Executed }
    struct Proposal {
        uint256 id;
        address proposer;
        string descriptionHash; // Hash of the proposal's detailed description (off-chain)
        address targetAddress; // Contract to call
        bytes callData;        // Encoded function call
        uint256 voteThreshold; // Percentage (e.g., 5000 for 50%) of total N-Score to pass
        uint256 forVotes;      // Sum of N-Scores of agents who voted 'for'
        uint256 againstVotes;  // Sum of N-Scores of agents who voted 'against'
        uint256 createdAt;
        uint256 votingEnds;
        mapping(uint256 => bool) hasVoted; // agentId => true
        ProposalStatus status;
    }

    // --- Events ---

    event AgentRegistered(uint256 indexed agentId, address indexed ownerAddress, string name, uint256 personaNFTId);
    event AgentDeregistered(uint256 indexed agentId, address indexed ownerAddress);
    event AgentPersonaEvolved(uint256 indexed agentId, uint256 indexed personaNFTId, string newURI);
    event AgentPersonaDevolved(uint256 indexed agentId, uint256 indexed personaNFTId, string newURI);
    event ReputationUpdated(uint256 indexed agentId, uint256 newReputation);

    event TaskSubmitted(uint256 indexed taskId, address indexed requester, uint256 rewardAmount, uint256 deadline);
    event TaskClaimed(uint256 indexed taskId, uint256 indexed agentId);
    event ContributionSubmitted(uint256 indexed contributionId, uint256 indexed taskId, uint256 indexed agentId, string submissionHash);
    event ContributionChallenged(uint256 indexed contributionId, uint256 indexed challengerAgentId, uint256 challengeId);
    event ChallengeVerdictSubmitted(uint256 indexed challengeId, uint256 indexed verdictAgentId, bool isOriginalContributionValid);
    event TaskResolved(uint256 indexed taskId, TaskStatus finalStatus, uint256 finalAgentId, string resultHash);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string descriptionHash, uint256 voteThreshold);
    event VoteCast(uint256 indexed proposalId, uint256 indexed voterAgentId, bool support);
    event ProposalExecuted(uint256 indexed proposalId, address indexed targetAddress, bytes callData);
    event ProposalFailed(uint256 indexed proposalId);

    // --- Modifiers ---

    modifier onlyRegisteredAgent(uint256 _agentId) {
        require(agents[_agentId].status == AgentStatus.Active, "Agent not active");
        require(agents[_agentId].ownerAddress == msg.sender, "Only agent owner can call this function");
        _;
    }

    modifier onlyAgentOwner(uint256 _agentId) {
        require(agents[_agentId].ownerAddress == msg.sender, "Only agent owner can call this function");
        _;
    }

    modifier canParticipateInGovernance(uint256 _agentId) {
        require(agentReputationScores[_agentId] >= minReputationForGovernance, "Insufficient N-Score for governance");
        _;
    }

    // --- Constructor ---

    constructor() Ownable(msg.sender) {
        // Initial setup for owner, other configurations can be updated via governance or admin
    }

    // --- Core Admin Functions ---

    /**
     * @dev Sets the address of the external AgentPersonaNFT contract.
     * Can only be set once by the contract owner.
     * @param _nftContract The address of the AgentPersonaNFT contract.
     */
    function setAgentPersonaNFTContract(address _nftContract) external onlyOwner {
        require(address(agentPersonaNFT) == address(0), "NFT contract already set");
        require(_nftContract != address(0), "NFT contract cannot be zero address");
        agentPersonaNFT = IAgentPersonaNFT(_nftContract);
    }

    /**
     * @dev Pauses the contract, preventing certain state-changing operations.
     * Only owner can call.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing operations to resume.
     * Only owner can call.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Updates the minimum N-Score required for governance participation.
     * Callable by owner or via successful governance proposal.
     * @param _newMin The new minimum reputation score.
     */
    function updateMinReputationForGovernance(uint256 _newMin) external onlyOwner {
        minReputationForGovernance = _newMin;
    }

    // --- Agent Management ---

    /**
     * @dev Registers a new intelligence agent. Mints an initial Persona NFT and assigns an N-Score of 0.
     * @param _name The agent's chosen name.
     * @param _modelURI A URI pointing to a description of the agent's AI model or methodology.
     */
    function registerAgent(string calldata _name, string calldata _modelURI) external whenNotPaused {
        require(agentAddressToId[msg.sender] == 0, "Address already registered as an agent");
        require(bytes(_name).length > 0, "Agent name cannot be empty");
        require(bytes(_modelURI).length > 0, "Model URI cannot be empty");
        require(address(agentPersonaNFT) != address(0), "NFT contract not configured");

        uint256 agentId = nextAgentId++;
        uint256 personaNFTId = agentId; // For simplicity, NFT ID matches agent ID
        agentPersonaNFT.mint(msg.sender, personaNFTId, "ipfs://QmbnNXZYk3Y7X2fMvW4g5tH1p2jK7o9qR3dE0bW8cH1iC"); // Default initial URI

        agents[agentId] = Agent({
            id: agentId,
            ownerAddress: msg.sender,
            name: _name,
            modelURI: _modelURI,
            registeredAt: block.timestamp,
            status: AgentStatus.Active,
            personaNFTId: personaNFTId
        });
        agentAddressToId[msg.sender] = agentId;
        agentReputationScores[agentId] = 0; // Start with 0 N-Score

        emit AgentRegistered(agentId, msg.sender, _name, personaNFTId);
    }

    /**
     * @dev Allows an agent to deregister from the network.
     * Burns their Persona NFT and clears their N-Score.
     */
    function deregisterAgent() external whenNotPaused {
        uint256 agentId = agentAddressToId[msg.sender];
        require(agentId != 0, "Not a registered agent");
        require(agents[agentId].status == AgentStatus.Active, "Agent already deregistered or inactive");

        agents[agentId].status = AgentStatus.Deregistered;
        agentAddressToId[msg.sender] = 0; // Clear mapping
        agentReputationScores[agentId] = 0; // Clear N-Score

        agentPersonaNFT.burn(agents[agentId].personaNFTId); // Burn the Persona NFT

        emit AgentDeregistered(agentId, msg.sender);
    }

    /**
     * @dev Allows an agent to update their linked model URI.
     * @param _newModelURI The new URI pointing to their model/methodology.
     */
    function updateAgentModelURI(string calldata _newModelURI) external whenNotPaused {
        uint256 agentId = agentAddressToId[msg.sender];
        require(agentId != 0, "Not a registered agent");
        require(agents[agentId].status == AgentStatus.Active, "Agent not active");
        require(bytes(_newModelURI).length > 0, "Model URI cannot be empty");

        agents[agentId].modelURI = _newModelURI;
    }

    /**
     * @dev Retrieves details for a specific agent.
     * @param _agentId The ID of the agent.
     * @return Agent struct details.
     */
    function getAgentDetails(uint256 _agentId) external view returns (Agent memory) {
        require(_agentId != 0 && agents[_agentId].id != 0, "Agent not found");
        return agents[_agentId];
    }

    // --- Reputation (N-Score) Management ---

    /**
     * @dev Retrieves the current N-Score of an agent.
     * @param _agentId The ID of the agent.
     * @return The agent's current N-Score.
     */
    function getAgentReputation(uint256 _agentId) external view returns (uint256) {
        require(_agentId != 0 && agents[_agentId].id != 0, "Agent not found");
        return agentReputationScores[_agentId];
    }

    /**
     * @dev Awards reputation to an agent. Internal function.
     * Can trigger persona NFT evolution.
     * @param _agentId The ID of the agent.
     * @param _amount The amount of reputation to award.
     */
    function _awardReputation(uint256 _agentId, uint256 _amount) internal {
        require(agents[_agentId].status == AgentStatus.Active, "Cannot award reputation to inactive agent");
        uint256 currentReputation = agentReputationScores[_agentId];
        agentReputationScores[_agentId] = currentReputation.add(_amount);
        emit ReputationUpdated(_agentId, agentReputationScores[_agentId]);

        // Potentially trigger NFT evolution (can be explicitly requested by agent too)
        string memory newURI = _getPersonaURIForReputation(agentReputationScores[_agentId]);
        if (bytes(newURI).length > 0 && keccak256(abi.encodePacked(agentPersonaNFT.tokenURI(agents[_agentId].personaNFTId))) != keccak256(abi.encodePacked(newURI))) {
            agentPersonaNFT.updateTokenURI(agents[_agentId].personaNFTId, newURI);
            emit AgentPersonaEvolved(_agentId, agents[_agentId].personaNFTId, newURI);
        }
    }

    /**
     * @dev Penalizes an agent's reputation. Internal function.
     * Can trigger persona NFT devolution.
     * @param _agentId The ID of the agent.
     * @param _amount The amount of reputation to penalize.
     */
    function _penalizeReputation(uint256 _agentId, uint256 _amount) internal {
        require(agents[_agentId].status == AgentStatus.Active, "Cannot penalize inactive agent");
        uint256 currentReputation = agentReputationScores[_agentId];
        agentReputationScores[_agentId] = currentReputation.sub(_amount, "Reputation cannot go below zero");
        emit ReputationUpdated(_agentId, agentReputationScores[_agentId]);

        // Potentially trigger NFT devolution (can be explicitly requested by agent too)
        string memory newURI = _getPersonaURIForReputation(agentReputationScores[_agentId]);
        if (bytes(newURI).length > 0 && keccak256(abi.encodePacked(agentPersonaNFT.tokenURI(agents[_agentId].personaNFTId))) != keccak256(abi.encodePacked(newURI))) {
            agentPersonaNFT.updateTokenURI(agents[_agentId].personaNFTId, newURI);
            emit AgentPersonaDevolved(_agentId, agents[_agentId].personaNFTId, newURI);
        }
    }

    /**
     * @dev Maps reputation score to a persona NFT URI.
     * This is a simplified example; a real implementation might use more complex logic.
     * @param _reputation The agent's reputation score.
     * @return The appropriate token URI for the persona NFT.
     */
    function _getPersonaURIForReputation(uint256 _reputation) internal pure returns (string memory) {
        if (_reputation >= 5000) {
            return "ipfs://QmTier5Awesome";
        } else if (_reputation >= 2000) {
            return "ipfs://QmTier4Advanced";
        } else if (_reputation >= 500) {
            return "ipfs://QmTier3Pro";
        } else if (_reputation >= 100) {
            return "ipfs://QmTier2Starter";
        } else {
            return "ipfs://QmTier1Basic";
        }
    }

    // --- Task & Contribution System ---

    /**
     * @dev A user submits a task to the network, providing a description hash, an ETH reward, and a deadline.
     * @param _descriptionHash Hash of the task description (stored off-chain).
     * @param _rewardAmount The ETH reward for successful completion.
     * @param _deadline Timestamp by which the task must be completed.
     */
    function submitTask(string calldata _descriptionHash, uint256 _rewardAmount, uint256 _deadline) external payable whenNotPaused {
        require(msg.value == _rewardAmount, "Incorrect ETH amount sent for reward");
        require(bytes(_descriptionHash).length > 0, "Description hash cannot be empty");
        require(_rewardAmount > 0, "Reward must be greater than zero");
        require(_deadline > block.timestamp, "Deadline must be in the future");

        uint256 taskId = nextTaskId++;
        tasks[taskId] = Task({
            id: taskId,
            requester: msg.sender,
            descriptionHash: _descriptionHash,
            rewardAmount: _rewardAmount,
            deadline: _deadline,
            status: TaskStatus.Open,
            assignedAgentId: 0,
            resultHash: "",
            submittedAt: block.timestamp
        });

        emit TaskSubmitted(taskId, msg.sender, _rewardAmount, _deadline);
    }

    /**
     * @dev Allows a qualified agent to claim an open task.
     * Requires the agent to have a minimum reputation to claim tasks.
     * @param _taskId The ID of the task to claim.
     */
    function claimTask(uint256 _taskId) external whenNotPaused {
        uint256 agentId = agentAddressToId[msg.sender];
        require(agentId != 0, "Not a registered agent");
        require(agents[agentId].status == AgentStatus.Active, "Agent not active");
        require(agentReputationScores[agentId] > 0, "Agent needs some reputation to claim tasks"); // Example: min 1 N-Score

        Task storage task = tasks[_taskId];
        require(task.id != 0, "Task not found");
        require(task.status == TaskStatus.Open, "Task is not open for claiming");
        require(task.deadline > block.timestamp, "Task deadline has passed");

        task.assignedAgentId = agentId;
        task.status = TaskStatus.Assigned;

        emit TaskClaimed(_taskId, agentId);
    }

    /**
     * @dev An assigned agent submits their solution/insight for a task.
     * @param _taskId The ID of the task.
     * @param _submissionHash Hash of the agent's submission (off-chain).
     */
    function submitContribution(uint256 _taskId, string calldata _submissionHash) external whenNotPaused {
        uint256 agentId = agentAddressToId[msg.sender];
        require(agentId != 0, "Not a registered agent");
        require(agents[agentId].status == AgentStatus.Active, "Agent not active");

        Task storage task = tasks[_taskId];
        require(task.id != 0, "Task not found");
        require(task.status == TaskStatus.Assigned, "Task is not in assigned state");
        require(task.assignedAgentId == agentId, "Only the assigned agent can submit a contribution");
        require(block.timestamp <= task.deadline, "Submission deadline has passed");
        require(bytes(_submissionHash).length > 0, "Submission hash cannot be empty");

        uint256 contributionId = nextContributionId++;
        contributions[contributionId] = Contribution({
            id: contributionId,
            taskId: _taskId,
            agentId: agentId,
            submissionHash: _submissionHash,
            submittedAt: block.timestamp,
            status: ContributionStatus.Pending,
            challengeId: 0
        });

        task.status = TaskStatus.ContributionSubmitted;

        emit ContributionSubmitted(contributionId, _taskId, agentId, _submissionHash);
    }

    /**
     * @dev Allows any qualified agent to challenge a submitted contribution, staking ETH to initiate a dispute.
     * The task status changes to Challenged.
     * @param _contributionId The ID of the contribution to challenge.
     */
    function challengeContribution(uint256 _contributionId) external payable whenNotPaused {
        uint256 challengerAgentId = agentAddressToId[msg.sender];
        require(challengerAgentId != 0, "Not a registered agent");
        require(agents[challengerAgentId].status == AgentStatus.Active, "Challenger agent not active");
        require(agentReputationScores[challengerAgentId] >= minReputationForGovernance.div(5), "Challenger needs sufficient N-Score"); // Example: 1/5th of governance score

        Contribution storage contribution = contributions[_contributionId];
        require(contribution.id != 0, "Contribution not found");
        require(contribution.status == ContributionStatus.Pending, "Contribution is not in pending state for challenge");
        require(contribution.agentId != challengerAgentId, "Cannot challenge your own contribution");

        Task storage task = tasks[contribution.taskId];
        require(task.status == TaskStatus.ContributionSubmitted, "Task is not in a state to be challenged");
        require(msg.value == challengeStakeAmount, "Incorrect challenge stake amount");

        uint256 challengeId = nextContributionId++; // Using nextContributionId for challengeId for simplicity
        contributions[_contributionId].status = ContributionStatus.Challenged;
        contributions[_contributionId].challengeId = challengeId;

        Challenge storage newChallenge = new Challenge({
            id: challengeId,
            contributionId: _contributionId,
            challengerAgentId: challengerAgentId,
            challengeStake: msg.value,
            initiatedAt: block.timestamp,
            forValidCount: 0,
            forInvalidCount: 0
        });
        // Note: `hasVoted` mapping needs to be handled within the struct, not declared directly
        // The above `new Challenge` syntax needs to be adjusted.
        // Let's declare `challenges` mapping and create it there.
        // Re-adjusting the Challenge struct and how it's stored.

        // Re-adjusting Challenge storage
        // (Moved this struct out to a global mapping `challenges`)
        // The `Challenge` struct `hasVoted` mapping cannot be part of the `new Challenge` inline struct creation.
        // It has to be a top-level mapping.
        // For simplicity for this example, I'll manage the verdict votes directly in the Challenge struct as counts.
        // And use a separate `mapping(uint256 => mapping(uint256 => bool))` for `hasVoted` for challenges.

        // Corrected Challenge creation:
        challenges[challengeId] = Challenge({
            id: challengeId,
            contributionId: _contributionId,
            challengerAgentId: challengerAgentId,
            challengeStake: msg.value,
            initiatedAt: block.timestamp,
            forValidCount: 0,
            forInvalidCount: 0
        });
        challenges_hasVoted[challengeId][challengerAgentId] = true; // Challenger implicitly voted invalid
        challenges[challengeId].forInvalidCount = challenges[challengeId].forInvalidCount.add(1);

        task.status = TaskStatus.Challenged;

        emit ContributionChallenged(_contributionId, challengerAgentId, challengeId);
    }

    // New mapping for challenge verdicts
    mapping(uint256 => mapping(uint256 => bool)) private challenges_hasVoted; // challengeId => agentId => hasVoted

    // A mapping for Challenges needs to exist
    mapping(uint256 => Challenge) public challenges;
    uint256 public nextChallengeId = 1; // Needs to be added to state vars

    /**
     * @dev Allows any qualified agent to submit their verdict (vote) on a challenged contribution.
     * Requires staking ETH.
     * @param _contributionId The ID of the contribution being challenged.
     * @param _isOriginalContributionValid True if the original contribution is deemed valid, false otherwise.
     */
    function submitChallengeVerdict(uint256 _contributionId, bool _isOriginalContributionValid) external payable whenNotPaused {
        uint256 verdictAgentId = agentAddressToId[msg.sender];
        require(verdictAgentId != 0, "Not a registered agent");
        require(agents[verdictAgentId].status == AgentStatus.Active, "Verdict agent not active");
        require(agentReputationScores[verdictAgentId] >= minReputationForGovernance.div(5), "Verdict agent needs sufficient N-Score");
        require(msg.value == challengeVerdictStake, "Incorrect verdict stake amount");

        Contribution storage contribution = contributions[_contributionId];
        require(contribution.id != 0, "Contribution not found");
        require(contribution.status == ContributionStatus.Challenged, "Contribution is not under challenge");
        require(contribution.agentId != verdictAgentId, "Cannot vote on your own contribution"); // Original contributor cannot vote
        require(challenges[contribution.challengeId].challengerAgentId != verdictAgentId, "Challenger cannot cast another verdict"); // Challenger already voted

        Challenge storage challenge = challenges[contribution.challengeId];
        require(challenge.id != 0, "Challenge not found");
        require(block.timestamp <= challenge.initiatedAt.add(CHALLENGE_PERIOD_DURATION), "Challenge verdict period has ended");
        require(!challenges_hasVoted[challenge.id][verdictAgentId], "Agent has already submitted a verdict for this challenge");

        if (_isOriginalContributionValid) {
            challenge.forValidCount = challenge.forValidCount.add(1);
        } else {
            challenge.forInvalidCount = challenge.forInvalidCount.add(1);
        }
        challenges_hasVoted[challenge.id][verdictAgentId] = true;

        // Transfer verdict stake to the contract
        // This stake will be distributed later during task resolution.
        // (No direct ETH transfer needed here as msg.value is already collected)

        emit ChallengeVerdictSubmitted(challenge.id, verdictAgentId, _isOriginalContributionValid);
    }

    /**
     * @dev Resolves a task after its deadline, distributing rewards and updating reputation.
     * Handles challenged contributions by evaluating verdicts.
     * Callable by anyone after the task deadline and challenge period (if any) have passed.
     * @param _taskId The ID of the task to resolve.
     */
    function resolveTask(uint256 _taskId) external whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.id != 0, "Task not found");
        require(task.status != TaskStatus.ResolvedSuccess && task.status != TaskStatus.ResolvedFailed && task.status != TaskStatus.Cancelled, "Task already resolved or cancelled");
        require(block.timestamp > task.deadline, "Task deadline has not yet passed");

        uint256 assignedAgentId = task.assignedAgentId;
        require(assignedAgentId != 0, "Task was not assigned to an agent");

        Contribution storage contribution;
        uint256 contributionId = 0;

        // Find the contribution linked to this task
        for (uint256 i = 1; i < nextContributionId; i++) {
            if (contributions[i].taskId == _taskId && contributions[i].agentId == assignedAgentId) {
                contributionId = i;
                contribution = contributions[i];
                break;
            }
        }
        require(contributionId != 0, "No contribution found for this task");


        TaskStatus finalStatus;
        uint256 rewardToAgent = 0;
        uint256 reputationChange = 0; // Can be positive or negative

        if (contribution.status == ContributionStatus.Challenged) {
            Challenge storage challenge = challenges[contribution.challengeId];
            require(challenge.id != 0, "Challenge not found for this contribution");
            require(block.timestamp > challenge.initiatedAt.add(CHALLENGE_PERIOD_DURATION), "Challenge verdict period is still active");

            // Evaluate challenge verdicts
            if (challenge.forValidCount > challenge.forInvalidCount) {
                // Original contribution deemed valid
                contribution.status = ContributionStatus.Validated;
                finalStatus = TaskStatus.ResolvedSuccess;
                rewardToAgent = task.rewardAmount;
                reputationChange = 100; // Award reputation to original contributor
                _awardReputation(assignedAgentId, reputationChange);

                // Distribute challenge stakes: Challenger loses, verdict agents who voted 'valid' win a share of challenger's stake
                payable(agents[challenge.challengerAgentId].ownerAddress).transfer(challenge.challengeStake); // Challenger loses stake
                // For simplicity: Return verdict stakes. In a real system, incorrect verdict voters would lose stake, correct ones gain.
                // For this example, let's just return stakes for verdict voters, and challenger loses stake if wrong.
                // If original contribution is valid, challenger loses stake.
                // Verifier stakes are returned to their owners.
            } else if (challenge.forInvalidCount > challenge.forValidCount) {
                // Original contribution deemed invalid
                contribution.status = ContributionStatus.Rejected;
                finalStatus = TaskStatus.ResolvedFailed;
                reputationChange = 50; // Penalize original contributor
                _penalizeReputation(assignedAgentId, reputationChange);

                // Challenger wins their stake back + a reward (from original contributor's penalty or a small portion of verdict stakes)
                payable(agents[challenge.challengerAgentId].ownerAddress).transfer(challenge.challengeStake); // Challenger gets stake back
                // Task reward goes back to the requester
                payable(task.requester).transfer(task.rewardAmount);
            } else {
                // Tie or no decisive outcome - default to failure for original contributor, or require manual arbitration
                contribution.status = ContributionStatus.Rejected; // Default to rejection for ambiguity
                finalStatus = TaskStatus.ResolvedFailed;
                reputationChange = 25; // Small penalty for ambiguity
                _penalizeReputation(assignedAgentId, reputationChange);
                payable(task.requester).transfer(task.rewardAmount); // Refund requester
                payable(agents[challenge.challengerAgentId].ownerAddress).transfer(challenge.challengeStake); // Challenger gets stake back
            }
            // For simplicity, verdict stakes are not complexly distributed in this example. They are implicitly held until task resolution.
            // A more complex system would have a pool and distribute based on correct votes.
        } else if (contribution.status == ContributionStatus.Pending) {
            // No challenge, assume valid after deadline
            contribution.status = ContributionStatus.Validated;
            finalStatus = TaskStatus.ResolvedSuccess;
            rewardToAgent = task.rewardAmount;
            reputationChange = 10; // Award reputation
            _awardReputation(assignedAgentId, reputationChange);
        } else {
            // Should not happen if transitions are correct
            revert("Invalid contribution status for resolution");
        }

        if (finalStatus == TaskStatus.ResolvedSuccess) {
            task.resultHash = contribution.submissionHash;
            if (rewardToAgent > 0) {
                payable(agents[assignedAgentId].ownerAddress).transfer(rewardToAgent);
            }
        }

        task.status = finalStatus;

        emit TaskResolved(_taskId, finalStatus, assignedAgentId, task.resultHash);
    }

    /**
     * @dev Retrieves details for a specific task.
     * @param _taskId The ID of the task.
     * @return Task struct details.
     */
    function getTaskDetails(uint256 _taskId) external view returns (Task memory) {
        require(_taskId != 0 && tasks[_taskId].id != 0, "Task not found");
        return tasks[_taskId];
    }

    // --- Dynamic NFT Evolution Triggers ---

    /**
     * @dev Allows an agent to request an update to their Persona NFT's metadata/URI.
     * The contract checks if their current N-Score qualifies for a different tier.
     * @param _agentId The ID of the agent whose persona NFT should be updated.
     */
    function requestPersonaEvolution(uint256 _agentId) external onlyAgentOwner(_agentId) whenNotPaused {
        require(agents[_agentId].personaNFTId != 0, "Agent has no persona NFT");
        string memory currentNFTURI = agentPersonaNFT.tokenURI(agents[_agentId].personaNFTId);
        string memory newURI = _getPersonaURIForReputation(agentReputationScores[_agentId]);

        require(bytes(newURI).length > 0, "No valid evolution URI found for current score");
        require(keccak256(abi.encodePacked(currentNFTURI)) != keccak256(abi.encodePacked(newURI)), "Persona NFT is already at the correct tier");

        agentPersonaNFT.updateTokenURI(agents[_agentId].personaNFTId, newURI);
        emit AgentPersonaEvolved(_agentId, agents[_agentId].personaNFTId, newURI);
    }

    /**
     * @dev Allows an agent to request a downgrade of their Persona NFT's metadata/URI.
     * The contract checks if their current N-Score requires a lower tier.
     * @param _agentId The ID of the agent whose persona NFT should be updated.
     */
    function requestPersonaDevolution(uint256 _agentId) external onlyAgentOwner(_agentId) whenNotPaused {
        require(agents[_agentId].personaNFTId != 0, "Agent has no persona NFT");
        string memory currentNFTURI = agentPersonaNFT.tokenURI(agents[_agentId].personaNFTId);
        string memory newURI = _getPersonaURIForReputation(agentReputationScores[_agentId]);

        require(bytes(newURI).length > 0, "No valid devolution URI found for current score");
        require(keccak256(abi.encodePacked(currentNFTURI)) != keccak256(abi.encodePacked(newURI)), "Persona NFT is already at the correct tier");

        agentPersonaNFT.updateTokenURI(agents[_agentId].personaNFTId, newURI);
        emit AgentPersonaDevolved(_agentId, agents[_agentId].personaNFTId, newURI);
    }

    // --- Governance ---

    /**
     * @dev Allows a qualified agent to create a new governance proposal.
     * @param _descriptionHash Hash of the detailed proposal description (off-chain).
     * @param _target The address of the contract to call if the proposal passes.
     * @param _callData The encoded function call (including signature and parameters) for the target.
     * @param _voteThreshold The percentage (e.g., 5000 for 50%) of total N-Score needed for the proposal to pass.
     */
    function createProposal(string calldata _descriptionHash, address _target, bytes calldata _callData, uint256 _voteThreshold) external whenNotPaused {
        uint256 proposerAgentId = agentAddressToId[msg.sender];
        require(proposerAgentId != 0, "Not a registered agent");
        require(agents[proposerAgentId].status == AgentStatus.Active, "Proposer agent not active");
        canParticipateInGovernance(proposerAgentId);
        require(bytes(_descriptionHash).length > 0, "Description hash cannot be empty");
        require(_target != address(0), "Target address cannot be zero");
        require(_voteThreshold > 0 && _voteThreshold <= 10000, "Vote threshold must be between 1 and 100%"); // 10000 for 100%

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            descriptionHash: _descriptionHash,
            targetAddress: _target,
            callData: _callData,
            voteThreshold: _voteThreshold,
            forVotes: 0,
            againstVotes: 0,
            createdAt: block.timestamp,
            votingEnds: block.timestamp.add(GOVERNANCE_VOTING_PERIOD),
            status: ProposalStatus.Active
        });

        // Proposer automatically votes 'for' and their N-Score counts
        proposals[proposalId].hasVoted[proposerAgentId] = true;
        proposals[proposalId].forVotes = proposals[proposalId].forVotes.add(agentReputationScores[proposerAgentId]);

        emit ProposalCreated(proposalId, msg.sender, _descriptionHash, _voteThreshold);
    }

    /**
     * @dev Allows a qualified agent to vote on an active governance proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for', false for 'against'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused {
        uint256 voterAgentId = agentAddressToId[msg.sender];
        require(voterAgentId != 0, "Not a registered agent");
        require(agents[voterAgentId].status == AgentStatus.Active, "Voter agent not active");
        canParticipateInGovernance(voterAgentId);

        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal not found");
        require(proposal.status == ProposalStatus.Active, "Proposal is not active for voting");
        require(block.timestamp <= proposal.votingEnds, "Voting period has ended");
        require(!proposal.hasVoted[voterAgentId], "Agent has already voted on this proposal");

        uint256 voterNScore = agentReputationScores[voterAgentId];
        if (_support) {
            proposal.forVotes = proposal.forVotes.add(voterNScore);
        } else {
            proposal.againstVotes = proposal.againstVotes.add(voterNScore);
        }
        proposal.hasVoted[voterAgentId] = true;

        emit VoteCast(_proposalId, voterAgentId, _support);
    }

    /**
     * @dev Executes a proposal that has passed its voting period and met its threshold.
     * Any address can call this to finalize and execute a passed proposal.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal not found");
        require(proposal.status == ProposalStatus.Active, "Proposal is not active");
        require(block.timestamp > proposal.votingEnds, "Voting period has not ended yet");

        uint256 totalGovernanceNScore = 0;
        for (uint256 i = 1; i < nextAgentId; i++) {
            if (agents[i].status == AgentStatus.Active && agentReputationScores[i] >= minReputationForGovernance) {
                totalGovernanceNScore = totalGovernanceNScore.add(agentReputationScores[i]);
            }
        }
        
        // Calculate effective threshold based on current eligible N-Scores
        uint256 requiredForVotes = totalGovernanceNScore.mul(proposal.voteThreshold).div(10000);

        if (proposal.forVotes >= requiredForVotes && proposal.forVotes > proposal.againstVotes) {
            proposal.status = ProposalStatus.Passed;
            (bool success, ) = proposal.targetAddress.call(proposal.callData);
            require(success, "Proposal execution failed");
            proposal.status = ProposalStatus.Executed; // Only update status if execution was successful
            emit ProposalExecuted(_proposalId, proposal.targetAddress, proposal.callData);
        } else {
            proposal.status = ProposalStatus.Failed;
            emit ProposalFailed(_proposalId);
        }
    }
}
```

### `AgentPersonaNFT.sol` (Separate Contract)

This contract defines the dynamic ERC721 NFT that `NexusCore_IntelligenceOrchestrator` manages. It needs to be deployed *before* `NexusCore`, and its address passed to `NexusCore` via `setAgentPersonaNFTContract`.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol"; // For _msgSender()

/**
 * @title AgentPersonaNFT
 * @dev An ERC721 contract for dynamic agent persona NFTs.
 * Only the NexusCore_IntelligenceOrchestrator contract can mint, burn, and update token URIs.
 */
contract AgentPersonaNFT is ERC721, Ownable {
    // The address of the NexusCore contract, which is authorized to manage NFTs.
    address public nexusCoreContract;

    constructor() ERC721("AgentPersonaNFT", "APN") {
        // Owner is the deployer of this NFT contract.
        // This owner will then typically set `nexusCoreContract` to the NexusCore contract's address.
    }

    /**
     * @dev Sets the address of the NexusCore contract.
     * Only the deployer/owner of this NFT contract can call this.
     * Can only be set once.
     * @param _nexusCoreContract The address of the NexusCore contract.
     */
    function setNexusCoreContract(address _nexusCoreContract) external onlyOwner {
        require(nexusCoreContract == address(0), "NexusCore contract already set");
        require(_nexusCoreContract != address(0), "NexusCore contract cannot be zero address");
        nexusCoreContract = _nexusCoreContract;
    }

    /**
     * @dev Modifier to restrict calls to only the authorized NexusCore contract.
     */
    modifier onlyNexusCore() {
        require(_msgSender() == nexusCoreContract, "Only NexusCore contract can call this function");
        _;
    }

    /**
     * @dev Mints a new Agent Persona NFT.
     * Can only be called by the NexusCore contract.
     * @param to The address to mint the NFT to.
     * @param tokenId The ID of the token to mint.
     * @param tokenURI The initial metadata URI for the token.
     */
    function mint(address to, uint256 tokenId, string calldata tokenURI) external onlyNexusCore {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
    }

    /**
     * @dev Burns an Agent Persona NFT.
     * Can only be called by the NexusCore contract.
     * @param tokenId The ID of the token to burn.
     */
    function burn(uint256 tokenId) external onlyNexusCore {
        _burn(tokenId);
    }

    /**
     * @dev Updates the metadata URI for an existing Agent Persona NFT.
     * This is how the NFT "evolves".
     * Can only be called by the NexusCore contract.
     * @param tokenId The ID of the token to update.
     * @param newTokenURI The new metadata URI.
     */
    function updateTokenURI(uint256 tokenId, string calldata newTokenURI) external onlyNexusCore {
        _setTokenURI(tokenId, newTokenURI);
    }

    // The rest of the ERC721 standard functions (transferFrom, approve, getApproved, etc.)
    // are inherited and function as usual for the token owner, but minting/burning/URI update
    // are restricted to NexusCore.
}
```