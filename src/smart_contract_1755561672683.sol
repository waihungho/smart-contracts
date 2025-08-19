The smart contract `CogniChain` is designed as a sophisticated, decentralized AI agent protocol. It enables users to post tasks for AI agents, manage agent profiles, build on-chain reputation, and track verified skills. A key feature is the "CogniNFT," a dynamic NFT that evolves based on an agent's performance and achievements within the protocol.

This contract integrates concepts from decentralized finance (staking, bounties), non-fungible tokens (dynamic NFTs), and reputation systems, all tailored for an emerging AI agent economy. It aims to provide a robust framework for trust and verifiable performance in autonomous agent interactions.

---

## CogniChain: Decentralized AI Agent Protocol

### Outline

1.  **Protocol Administration & Configuration:** Core functions for the contract owner to manage fees, pause functionality, and set critical external addresses (e.g., dispute oracle).
2.  **AI Agent Management & Registry:** Functions for AI agents (or their human proxies) to register, manage their profiles, stake tokens, and deregister from the platform.
3.  **Task & Bounty System:** A comprehensive module for users to post tasks with bounties, agents to bid, task posters to select agents, and manage task completion, verification, and potential disputes.
4.  **Reputation & Dynamic NFT (CogniNFT) System:** An on-chain reputation mechanism that updates based on task outcomes. This reputation directly influences a unique "CogniNFT" assigned to each agent, which dynamically changes its metadata to reflect the agent's standing.
5.  **Skill Tree & Verifiable Proofs:** Allows agents to declare specific skills and provides a mechanism (via an oracle or governance) to verify these skills on-chain using external proofs (e.g., ZK-proofs, attestations), building a verifiable "skill tree."
6.  **Internal & Utility Functions:** Helper functions for core logic, security, and data retrieval.

---

### Function Summary

**I. Protocol Administration & Configuration (Owner/Admin Only)**

1.  `constructor(address _initialFeeRecipient, uint256 _initialProtocolFeeBps, address _bountyTokenAddress, string memory _cogniNFTBaseURI)`: Initializes the contract, setting the initial fee recipient, protocol fee percentage, the ERC20 token used for bounties, and the base URI for CogniNFTs.
2.  `setProtocolFeeRecipient(address _newRecipient)`: Allows the owner to change the address that receives protocol fees.
3.  `updateProtocolFee(uint256 _newFeeBps)`: Allows the owner to adjust the protocol fee percentage, applied to successful task bounties (in basis points).
4.  `withdrawProtocolFees(address _tokenAddress)`: Enables the owner to withdraw accumulated protocol fees for a specific ERC20 token.
5.  `setDisputeResolutionOracle(address _oracleAddress)`: Designates a trusted address (e.g., a multi-sig or DAO contract) responsible for resolving task disputes.
6.  `pauseContract()`: Emergency function to pause critical contract operations, preventing new tasks, bids, or agent registrations.
7.  `unpauseContract()`: Resumes normal contract operations after a pause.
8.  `setCogniNFTBaseURI(string memory _newURI)`: Updates the base URI used for constructing CogniNFT metadata URLs, allowing for updates to NFT presentation.

**II. AI Agent Management & Registry (Agent/Owner Interaction)**

9.  `registerAIAgent(string memory _profileURI, uint256 _initialStakeAmount)`: Allows a user to register an AI agent, providing an off-chain profile URI and an initial stake in the bounty token. This action also mints a unique CogniNFT for the agent.
10. `updateAIAgentProfile(string memory _newProfileURI)`: Enables a registered agent to update their associated off-chain profile URI.
11. `deregisterAIAgent()`: Allows an agent to initiate deregistration. Their stake will be unlocked once all active tasks and disputes are resolved.
12. `fundAgentStake(uint256 _amount)`: Allows an agent to add more tokens to their stake.
13. `withdrawAgentStake(uint256 _amount)`: Allows an agent to withdraw a portion of their stake, provided it's not locked by ongoing tasks or minimum requirements.

**III. Task & Bounty System (User/Agent Interaction)**

14. `postTaskBounty(uint256 _bountyAmount, string memory _taskURI, bytes32[] memory _requiredSkillsHashes, uint256 _deadline)`: A user posts a new task, specifying the bounty amount (in the designated bounty token), an off-chain task description URI, a list of required skill hashes, and a deadline.
15. `bidOnTask(uint256 _taskId)`: A registered AI agent bids on an open task.
16. `selectAgentForTask(uint256 _taskId, address _agentAddress)`: The task poster selects an agent from the submitted bids. The bounty funds are then locked in the contract.
17. `submitTaskCompletion(uint256 _taskId, string memory _proofURI)`: The selected agent submits proof of task completion via an off-chain URI.
18. `verifyTaskCompletion(uint256 _taskId)`: The task poster verifies the submitted work. If approved, the bounty is released to the agent (minus protocol fees), and the agent's reputation is updated.
19. `disputeTaskOutcome(uint256 _taskId)`: Either the task poster or the selected agent can raise a dispute if they disagree with the task outcome or verification status.
20. `resolveDispute(uint256 _taskId, address _winningParty)`: The designated `disputeResolutionOracle` resolves a dispute, distributing funds and updating reputation accordingly.
21. `cancelTask(uint256 _taskId)`: Allows the task poster to cancel a task if no agent has been selected, refunding the bounty.
22. `reclaimTaskFunds(uint256 _taskId)`: Allows the task poster to reclaim the bounty if the selected agent fails to submit work by the deadline or if the task is failed.

**IV. Reputation & Dynamic NFT (CogniNFT) System (Internal/View)**

23. `getAgentReputation(address _agent)`: Returns the current reputation score of a specified AI agent.
24. `updateCogniNFT(address _agent)`: Triggers an internal update to the CogniNFT's metadata for a given agent, reflecting their current reputation and verified skills. This function is typically called internally after significant changes (e.g., successful task completion, skill verification).

**V. Skill Tree & Verifiable Proofs (Agent/Oracle Interaction)**

25. `declareAgentSkill(string memory _skillName, string memory _proofURI)`: Allows an agent to declare a new skill they possess, along with an off-chain URI pointing to a proof of this skill (e.g., a ZK-proof, attestation document).
26. `verifyAgentSkill(address _agent, bytes32 _skillHash)`: The `disputeResolutionOracle` (or governance) calls this function to mark a declared skill as verified for an agent after off-chain validation of the provided proof. This also updates the CogniNFT.
27. `getAgentSkillStatus(address _agent, bytes32 _skillHash)`: Checks if a specific skill (identified by its hash) is verified for a given agent.

---
**Note on "Non-Duplication":** While standard components like OpenZeppelin's `ERC721`, `Pausable`, and `Ownable` are used for security and efficiency, the core logic for the AI agent economy, dynamic reputation-based NFTs, multi-stage task lifecycle (bid, select, submit, verify, dispute, resolve), and on-chain verifiable skill trees are designed specifically for this `CogniChain` protocol and are not direct copies of existing open-source projects. The unique combination and interaction of these advanced concepts form the novelty.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Outline:
// I. Protocol Administration & Configuration
// II. AI Agent Management & Registry
// III. Task & Bounty System
// IV. Reputation & Dynamic NFT (CogniNFT) System
// V. Skill Tree & Verifiable Proofs
// VI. Internal & Utility Functions

// Function Summary:
// I. Protocol Administration & Configuration (Owner Only)
// 1. constructor: Initializes owner, fee recipient, bounty token, and NFT base URI.
// 2. setProtocolFeeRecipient: Changes the address receiving protocol fees.
// 3. updateProtocolFee: Adjusts the protocol fee percentage.
// 4. withdrawProtocolFees: Owner withdraws accumulated fees for a specific token.
// 5. setDisputeResolutionOracle: Sets the trusted oracle for dispute resolution.
// 6. pauseContract: Emergency function to pause core operations.
// 7. unpauseContract: Resumes core operations.
// 8. setCogniNFTBaseURI: Updates the base URI for CogniNFT metadata.

// II. AI Agent Management & Registry (Agent/Owner Interaction)
// 9. registerAIAgent: Registers a new AI agent, stakes tokens, and mints a CogniNFT.
// 10. updateAIAgentProfile: Allows an agent to update their profile URI.
// 11. deregisterAIAgent: Initiates agent deregistration, unlocks stake after tasks/disputes.
// 12. fundAgentStake: Allows an agent to add more tokens to their stake.
// 13. withdrawAgentStake: Allows an agent to withdraw excess stake not locked by tasks.

// III. Task & Bounty System (User/Agent Interaction)
// 14. postTaskBounty: User posts a task with bounty, description, required skills, and deadline.
// 15. bidOnTask: Agent bids on an open task.
// 16. selectAgentForTask: Task poster selects an agent from bids, locking bounty funds.
// 17. submitTaskCompletion: Agent submits proof of work for a selected task.
// 18. verifyTaskCompletion: Task poster verifies work, releases bounty, updates reputation.
// 19. disputeTaskOutcome: Allows poster or agent to dispute a task outcome.
// 20. resolveDispute: Oracle resolves a disputed task, distributing funds and updating reputation.
// 21. cancelTask: Task poster cancels an open task, refunds bounty.
// 22. reclaimTaskFunds: Task poster reclaims funds if agent fails to submit by deadline.

// IV. Reputation & Dynamic NFT (CogniNFT) System (Internal/View)
// 23. getAgentReputation: Returns an agent's current reputation score.
// 24. updateCogniNFT: Internal function to update an agent's CogniNFT metadata.

// V. Skill Tree & Verifiable Proofs (Agent/Oracle Interaction)
// 25. declareAgentSkill: Agent declares a new skill with an off-chain proof URI.
// 26. verifyAgentSkill: Oracle marks a declared skill as verified after off-chain validation.
// 27. getAgentSkillStatus: Checks if a specific skill is verified for an agent.

contract CogniChain is Ownable, Pausable, ERC721 {
    using Strings for uint256;

    // --- Events ---
    event ProtocolFeeRecipientUpdated(address indexed newRecipient);
    event ProtocolFeeUpdated(uint256 newFeeBps);
    event ProtocolFeesWithdrawn(address indexed token, uint256 amount);
    event DisputeResolutionOracleUpdated(address indexed newOracle);

    event AIAgentRegistered(address indexed agentAddress, uint256 tokenId, string profileURI);
    event AIAgentProfileUpdated(address indexed agentAddress, string newProfileURI);
    event AIAgentDeregistered(address indexed agentAddress);
    event AgentStakeUpdated(address indexed agentAddress, uint256 newStake);
    event AgentStakeSlashed(address indexed agentAddress, uint256 amount, string reason);

    event TaskBountyPosted(
        uint256 indexed taskId,
        address indexed poster,
        address tokenAddress,
        uint256 bountyAmount,
        string taskURI
    );
    event TaskBid(uint256 indexed taskId, address indexed agentAddress, uint256 bidAmount);
    event AgentSelected(uint256 indexed taskId, address indexed selectedAgent);
    event TaskCompleted(uint256 indexed taskId, address indexed agentAddress, string proofURI);
    event TaskVerified(uint256 indexed taskId, uint256 amountPaid);
    event TaskDisputed(uint256 indexed taskId, address indexed disputer);
    event DisputeResolved(uint256 indexed taskId, address indexed winningParty);
    event TaskCancelled(uint256 indexed taskId);
    event TaskFundsReclaimed(uint256 indexed taskId);

    event AgentReputationUpdated(address indexed agentAddress, int256 reputationDelta, uint256 newReputation);
    event CogniNFTMetadataUpdated(uint256 indexed tokenId, string newURI);

    event AgentSkillDeclared(address indexed agentAddress, bytes32 indexed skillHash, string skillName, string proofURI);
    event AgentSkillVerified(address indexed agentAddress, bytes32 indexed skillHash);

    // --- State Variables ---
    address public protocolFeeRecipient;
    uint256 public protocolFeeBps; // Basis points (e.g., 100 = 1%)
    address public disputeResolutionOracle;
    address public immutable BOUNTY_TOKEN; // The primary ERC20 token used for bounties and staking

    uint256 public nextTaskId;
    uint256 public nextCogniNFTId; // Counter for CogniNFT token IDs

    // --- Data Structures ---
    enum TaskStatus {
        Open,
        BiddingClosed, // Agent selected, funds locked
        PendingVerification, // Agent submitted completion
        Completed,
        Disputed,
        Failed, // e.g., agent failed to submit by deadline, or work rejected
        Cancelled
    }

    struct AIAgent {
        address agentAddress; // The address controlling the agent (redundant with mapping key but good for clarity)
        string profileURI; // IPFS hash or URL for agent's public profile (metadata, off-chain description)
        uint256 stake;
        uint256 reputationScore; // starts at a base, evolves with performance
        uint256 tasksCompleted;
        uint256 tasksFailed;
        bool isRegistered;
        uint256 cogniNFTId; // The ID of the CogniNFT owned by this agent
        // A mapping to track skills can be added here, or separately for gas efficiency
    }

    struct Task {
        address poster;
        address selectedAgent; // The agent chosen to execute
        uint256 bountyAmount;
        string taskURI; // IPFS hash or URL for task description
        bytes32[] requiredSkillsHashes; // Hashes of required skills (keccak256 of skill name)
        TaskStatus status;
        uint256 deadline;
        uint256 submittedAt; // Timestamp when agent submitted completion
        string completionProofURI; // URI to agent's completion proof
        bool disputeRaised;
        mapping(address => uint256) bids; // Agent address => bid amount (for now, simpler flat bids)
        address[] bidders; // To iterate bids easily
    }

    struct AgentSkill {
        string skillName;
        string proofURI; // URI to proof document/ZK proof artifact
        bool isVerified; // True if oracle/governance verified the skill
    }

    // --- Mappings ---
    mapping(address => AIAgent) public agents;
    mapping(uint256 => Task) public tasks;
    mapping(address => mapping(bytes32 => AgentSkill)) public agentSkills; // agentAddress => skillHash => AgentSkill
    mapping(address => uint256) public lockedAgentStakes; // Agent address => amount locked in ongoing tasks/disputes
    mapping(address => uint256) public protocolCollectedFees; // tokenAddress => amount

    string public cogniNFTBaseURI; // Base URI for CogniNFT metadata

    // --- Modifiers ---
    modifier onlyAgent(address _agent) {
        require(agents[_agent].isRegistered, "CogniChain: Caller is not a registered AI agent.");
        require(msg.sender == _agent || msg.sender == agents[_agent].owner, "CogniChain: Not the agent owner.");
        _;
    }

    modifier onlyTaskPoster(uint256 _taskId) {
        require(tasks[_taskId].poster == msg.sender, "CogniChain: Only task poster can call this.");
        _;
    }

    modifier onlyDisputeOracle() {
        require(msg.sender == disputeResolutionOracle, "CogniChain: Only dispute oracle can call this.");
        _;
    }

    // --- Constructor ---
    // 1. constructor
    constructor(
        address _initialFeeRecipient,
        uint256 _initialProtocolFeeBps,
        address _bountyTokenAddress,
        string memory _cogniNFTBaseURI
    ) ERC721("CogniChain AI Agent NFT", "COGNICHAIN") Ownable(msg.sender) Pausable() {
        require(_initialProtocolFeeBps <= 10000, "CogniChain: Fee BPS cannot exceed 10000 (100%)");
        protocolFeeRecipient = _initialFeeRecipient;
        protocolFeeBps = _initialProtocolFeeBps;
        BOUNTY_TOKEN = _bountyTokenAddress;
        cogniNFTBaseURI = _cogniNFTBaseURI;
        nextTaskId = 1;
        nextCogniNFTId = 1;
        emit ProtocolFeeRecipientUpdated(_initialFeeRecipient);
        emit ProtocolFeeUpdated(_initialProtocolFeeBps);
    }

    // --- I. Protocol Administration & Configuration ---

    // 2. setProtocolFeeRecipient
    function setProtocolFeeRecipient(address _newRecipient) public onlyOwner {
        require(_newRecipient != address(0), "CogniChain: Invalid recipient address");
        protocolFeeRecipient = _newRecipient;
        emit ProtocolFeeRecipientUpdated(_newRecipient);
    }

    // 3. updateProtocolFee
    function updateProtocolFee(uint256 _newFeeBps) public onlyOwner {
        require(_newFeeBps <= 10000, "CogniChain: Fee BPS cannot exceed 10000 (100%)");
        protocolFeeBps = _newFeeBps;
        emit ProtocolFeeUpdated(_newFeeBps);
    }

    // 4. withdrawProtocolFees
    function withdrawProtocolFees(address _tokenAddress) public onlyOwner {
        uint256 fees = protocolCollectedFees[_tokenAddress];
        require(fees > 0, "CogniChain: No fees to withdraw for this token.");
        protocolCollectedFees[_tokenAddress] = 0;
        IERC20(_tokenAddress).transfer(protocolFeeRecipient, fees);
        emit ProtocolFeesWithdrawn(_tokenAddress, fees);
    }

    // 5. setDisputeResolutionOracle
    function setDisputeResolutionOracle(address _oracleAddress) public onlyOwner {
        require(_oracleAddress != address(0), "CogniChain: Invalid oracle address");
        disputeResolutionOracle = _oracleAddress;
        emit DisputeResolutionOracleUpdated(_oracleAddress);
    }

    // 6. pauseContract
    function pauseContract() public onlyOwner {
        _pause();
    }

    // 7. unpauseContract
    function unpauseContract() public onlyOwner {
        _unpause();
    }

    // 8. setCogniNFTBaseURI
    function setCogniNFTBaseURI(string memory _newURI) public onlyOwner {
        cogniNFTBaseURI = _newURI;
    }

    // --- II. AI Agent Management & Registry ---

    // 9. registerAIAgent
    function registerAIAgent(string memory _profileURI, uint256 _initialStakeAmount) public whenNotPaused {
        require(!agents[msg.sender].isRegistered, "CogniChain: Address already registered as an AI agent.");
        require(_initialStakeAmount > 0, "CogniChain: Initial stake must be greater than zero.");
        IERC20(BOUNTY_TOKEN).transferFrom(msg.sender, address(this), _initialStakeAmount);

        uint256 tokenId = nextCogniNFTId++;
        _mint(msg.sender, tokenId);

        agents[msg.sender] = AIAgent({
            agentAddress: msg.sender,
            profileURI: _profileURI,
            stake: _initialStakeAmount,
            reputationScore: 1000, // Initial reputation
            tasksCompleted: 0,
            tasksFailed: 0,
            isRegistered: true,
            cogniNFTId: tokenId
        });

        _updateCogniNFT(msg.sender); // Update NFT metadata immediately

        emit AIAgentRegistered(msg.sender, tokenId, _profileURI);
        emit AgentStakeUpdated(msg.sender, _initialStakeAmount);
    }

    // 10. updateAIAgentProfile
    function updateAIAgentProfile(string memory _newProfileURI) public onlyAgent(msg.sender) whenNotPaused {
        agents[msg.sender].profileURI = _newProfileURI;
        emit AIAgentProfileUpdated(msg.sender, _newProfileURI);
    }

    // 11. deregisterAIAgent
    function deregisterAIAgent() public onlyAgent(msg.sender) whenNotPaused {
        AIAgent storage agent = agents[msg.sender];
        require(lockedAgentStakes[msg.sender] == 0, "CogniChain: Agent has locked stake in ongoing tasks/disputes.");

        uint256 remainingStake = agent.stake;
        agent.isRegistered = false;
        agent.stake = 0;

        // Burn the CogniNFT
        _burn(agent.cogniNFTId);

        if (remainingStake > 0) {
            IERC20(BOUNTY_TOKEN).transfer(msg.sender, remainingStake);
        }
        emit AIAgentDeregistered(msg.sender);
        emit AgentStakeUpdated(msg.sender, 0);
    }

    // 12. fundAgentStake
    function fundAgentStake(uint256 _amount) public onlyAgent(msg.sender) whenNotPaused {
        require(_amount > 0, "CogniChain: Amount must be greater than zero.");
        IERC20(BOUNTY_TOKEN).transferFrom(msg.sender, address(this), _amount);
        agents[msg.sender].stake += _amount;
        emit AgentStakeUpdated(msg.sender, agents[msg.sender].stake);
    }

    // 13. withdrawAgentStake
    function withdrawAgentStake(uint256 _amount) public onlyAgent(msg.sender) whenNotPaused {
        AIAgent storage agent = agents[msg.sender];
        require(agent.stake - lockedAgentStakes[msg.sender] >= _amount, "CogniChain: Not enough unlocked stake.");
        require(_amount > 0, "CogniChain: Amount must be greater than zero.");
        agent.stake -= _amount;
        IERC20(BOUNTY_TOKEN).transfer(msg.sender, _amount);
        emit AgentStakeUpdated(msg.sender, agent.stake);
    }

    // --- III. Task & Bounty System ---

    // 14. postTaskBounty
    function postTaskBounty(
        uint256 _bountyAmount,
        string memory _taskURI,
        bytes32[] memory _requiredSkillsHashes,
        uint256 _deadline
    ) public whenNotPaused {
        require(_bountyAmount > 0, "CogniChain: Bounty must be greater than zero.");
        require(_deadline > block.timestamp, "CogniChain: Deadline must be in the future.");
        IERC20(BOUNTY_TOKEN).transferFrom(msg.sender, address(this), _bountyAmount);

        uint256 taskId = nextTaskId++;
        tasks[taskId] = Task({
            poster: msg.sender,
            selectedAgent: address(0), // No agent selected yet
            bountyAmount: _bountyAmount,
            taskURI: _taskURI,
            requiredSkillsHashes: _requiredSkillsHashes,
            status: TaskStatus.Open,
            deadline: _deadline,
            submittedAt: 0,
            completionProofURI: "",
            disputeRaised: false,
            bidders: new address[](0) // Initialize empty
        });

        emit TaskBountyPosted(taskId, msg.sender, BOUNTY_TOKEN, _bountyAmount, _taskURI);
    }

    // 15. bidOnTask
    function bidOnTask(uint256 _taskId) public onlyAgent(msg.sender) whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.poster != address(0), "CogniChain: Task does not exist.");
        require(task.status == TaskStatus.Open, "CogniChain: Task is not open for bidding.");
        require(task.deadline > block.timestamp, "CogniChain: Task bidding deadline passed.");
        require(task.bids[msg.sender] == 0, "CogniChain: Agent has already bid on this task.");

        // Check if agent has required skills (optional, can be done by poster during selection)
        // For stricter on-chain enforcement:
        for (uint256 i = 0; i < task.requiredSkillsHashes.length; i++) {
            require(
                agentSkills[msg.sender][task.requiredSkillsHashes[i]].isVerified,
                "CogniChain: Agent lacks a required verified skill."
            );
        }

        task.bids[msg.sender] = agents[msg.sender].reputationScore; // Simple bid based on reputation for now
        task.bidders.push(msg.sender);

        emit TaskBid(_taskId, msg.sender, task.bids[msg.sender]);
    }

    // 16. selectAgentForTask
    function selectAgentForTask(uint256 _taskId, address _agentAddress) public onlyTaskPoster(_taskId) whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Open, "CogniChain: Task is not open for selection.");
        require(agents[_agentAddress].isRegistered, "CogniChain: Selected address is not a registered agent.");
        require(task.bids[_agentAddress] > 0, "CogniChain: Agent did not bid on this task.");
        require(task.deadline > block.timestamp, "CogniChain: Task deadline passed.");

        task.selectedAgent = _agentAddress;
        task.status = TaskStatus.BiddingClosed;

        // Lock agent's stake (e.g., a percentage of bounty, or fixed amount)
        // For simplicity, let's lock a fixed 10% of bounty or a minimum of 10 units if smaller.
        uint256 stakeToLock = task.bountyAmount / 10; // 10%
        if (stakeToLock == 0) stakeToLock = 10; // Minimum lock
        require(agents[_agentAddress].stake - lockedAgentStakes[_agentAddress] >= stakeToLock, "CogniChain: Agent's unlocked stake is insufficient.");
        lockedAgentStakes[_agentAddress] += stakeToLock;

        emit AgentSelected(_taskId, _agentAddress);
    }

    // 17. submitTaskCompletion
    function submitTaskCompletion(uint256 _taskId, string memory _proofURI) public onlyAgent(msg.sender) whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.poster != address(0), "CogniChain: Task does not exist.");
        require(task.selectedAgent == msg.sender, "CogniChain: Only the selected agent can submit completion.");
        require(task.status == TaskStatus.BiddingClosed, "CogniChain: Task not in correct status for submission.");
        require(block.timestamp <= task.deadline, "CogniChain: Task deadline has passed.");

        task.completionProofURI = _proofURI;
        task.submittedAt = block.timestamp;
        task.status = TaskStatus.PendingVerification;

        emit TaskCompleted(_taskId, msg.sender, _proofURI);
    }

    // 18. verifyTaskCompletion
    function verifyTaskCompletion(uint256 _taskId) public onlyTaskPoster(_taskId) whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.poster != address(0), "CogniChain: Task does not exist.");
        require(task.status == TaskStatus.PendingVerification, "CogniChain: Task is not pending verification.");
        require(!task.disputeRaised, "CogniChain: Task is currently under dispute.");

        task.status = TaskStatus.Completed;

        uint256 protocolFee = (task.bountyAmount * protocolFeeBps) / 10000;
        uint256 amountToAgent = task.bountyAmount - protocolFee;

        IERC20(BOUNTY_TOKEN).transfer(task.selectedAgent, amountToAgent);
        protocolCollectedFees[BOUNTY_TOKEN] += protocolFee;

        // Unlock agent's stake and update reputation
        _unlockAgentStake(task.selectedAgent, task.bountyAmount / 10 > 0 ? task.bountyAmount / 10 : 10); // Use same amount as locked
        _updateAgentReputation(task.selectedAgent, 100); // Positive reputation boost

        agents[task.selectedAgent].tasksCompleted++;

        emit TaskVerified(_taskId, amountToAgent);
        emit AgentReputationUpdated(task.selectedAgent, 100, agents[task.selectedAgent].reputationScore);
    }

    // 19. disputeTaskOutcome
    function disputeTaskOutcome(uint256 _taskId) public whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.poster != address(0), "CogniChain: Task does not exist.");
        require(task.status == TaskStatus.PendingVerification || task.status == TaskStatus.Completed, "CogniChain: Task cannot be disputed in its current status.");
        require(!task.disputeRaised, "CogniChain: Task already under dispute.");
        require(msg.sender == task.poster || msg.sender == task.selectedAgent, "CogniChain: Only task poster or selected agent can dispute.");

        task.disputeRaised = true;
        task.status = TaskStatus.Disputed;
        emit TaskDisputed(_taskId, msg.sender);
    }

    // 20. resolveDispute
    function resolveDispute(uint256 _taskId, address _winningParty) public onlyDisputeOracle whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.poster != address(0), "CogniChain: Task does not exist.");
        require(task.status == TaskStatus.Disputed, "CogniChain: Task is not under dispute.");
        require(
            _winningParty == task.poster || _winningParty == task.selectedAgent,
            "CogniChain: Winning party must be the poster or the agent."
        );

        uint256 stakeToUnlock = task.bountyAmount / 10 > 0 ? task.bountyAmount / 10 : 10;
        _unlockAgentStake(task.selectedAgent, stakeToUnlock);

        if (_winningParty == task.selectedAgent) {
            // Agent wins dispute, receives bounty
            uint256 protocolFee = (task.bountyAmount * protocolFeeBps) / 10000;
            uint256 amountToAgent = task.bountyAmount - protocolFee;
            IERC20(BOUNTY_TOKEN).transfer(task.selectedAgent, amountToAgent);
            protocolCollectedFees[BOUNTY_TOKEN] += protocolFee;

            _updateAgentReputation(task.selectedAgent, 50); // Smaller boost for winning dispute
            agents[task.selectedAgent].tasksCompleted++;
            task.status = TaskStatus.Completed;
            emit TaskVerified(_taskId, amountToAgent); // Re-use event as it's a "successful" outcome
        } else {
            // Poster wins dispute, gets bounty back, agent stake slashed
            IERC20(BOUNTY_TOKEN).transfer(task.poster, task.bountyAmount);
            _slashAgentStake(task.selectedAgent, stakeToUnlock, "Dispute loss"); // Slash the locked stake amount
            _updateAgentReputation(task.selectedAgent, -200); // Significant reputation loss
            agents[task.selectedAgent].tasksFailed++;
            task.status = TaskStatus.Failed;
        }

        task.disputeRaised = false;
        emit DisputeResolved(_taskId, _winningParty);
    }

    // 21. cancelTask
    function cancelTask(uint256 _taskId) public onlyTaskPoster(_taskId) whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.poster != address(0), "CogniChain: Task does not exist.");
        require(task.status == TaskStatus.Open, "CogniChain: Only open tasks can be cancelled.");
        require(task.selectedAgent == address(0), "CogniChain: Cannot cancel after an agent is selected.");

        IERC20(BOUNTY_TOKEN).transfer(msg.sender, task.bountyAmount);
        task.status = TaskStatus.Cancelled;
        emit TaskCancelled(_taskId);
    }

    // 22. reclaimTaskFunds
    function reclaimTaskFunds(uint256 _taskId) public onlyTaskPoster(_taskId) whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.poster != address(0), "CogniChain: Task does not exist.");
        require(
            task.status == TaskStatus.BiddingClosed || task.status == TaskStatus.PendingVerification,
            "CogniChain: Task not in reclaimable status."
        );
        require(task.selectedAgent != address(0), "CogniChain: No agent selected for this task.");

        // Reclaim if deadline passed AND agent hasn't submitted
        require(block.timestamp > task.deadline && task.submittedAt == 0, "CogniChain: Agent has not failed deadline or already submitted.");

        // Reclaim if poster rejects submission and no dispute initiated (or dispute lost by agent)
        if (task.status == TaskStatus.PendingVerification && !task.disputeRaised) {
            // If poster explicitly rejects but doesn't dispute, we assume failure.
            // This path should ideally be handled by a dispute or explicit rejection function,
            // but for this example, we'll allow reclaim if poster doesn't verify.
            // A more robust system would require explicit rejection before reclaim.
        }

        // Refund bounty to poster
        IERC20(BOUNTY_TOKEN).transfer(task.poster, task.bountyAmount);

        // Slash agent's stake (since they failed to submit by deadline)
        uint256 stakeToSlash = task.bountyAmount / 10 > 0 ? task.bountyAmount / 10 : 10;
        _unlockAgentStake(task.selectedAgent, stakeToSlash); // First unlock
        _slashAgentStake(task.selectedAgent, stakeToSlash, "Failed to submit by deadline"); // Then slash

        _updateAgentReputation(task.selectedAgent, -150); // Reputation hit for failing
        agents[task.selectedAgent].tasksFailed++;
        task.status = TaskStatus.Failed;

        emit TaskFundsReclaimed(_taskId);
        emit AgentReputationUpdated(task.selectedAgent, -150, agents[task.selectedAgent].reputationScore);
    }

    // --- IV. Reputation & Dynamic NFT (CogniNFT) System ---

    // 23. getAgentReputation
    function getAgentReputation(address _agent) public view returns (uint256) {
        return agents[_agent].reputationScore;
    }

    // 24. updateCogniNFT (Internal / Called by other functions)
    function _updateCogniNFT(address _agent) internal {
        AIAgent storage agent = agents[_agent];
        uint256 tokenId = agent.cogniNFTId;
        string memory newURI = string(
            abi.encodePacked(
                cogniNFTBaseURI,
                tokenId.toString(),
                "_",
                agent.reputationScore.toString(),
                "_",
                agent.tasksCompleted.toString(),
                "_",
                agent.tasksFailed.toString(),
                ".json"
            )
        );
        _setTokenURI(tokenId, newURI); // This updates the tokenURI for the NFT
        emit CogniNFTMetadataUpdated(tokenId, newURI);
    }

    // Overrides ERC721's tokenURI to be dynamic
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        address ownerOfToken = ownerOf(tokenId);
        AIAgent storage agent = agents[ownerOfToken];
        require(agent.cogniNFTId == tokenId, "CogniChain: Mismatch in CogniNFT ID for agent.");

        // Construct the URI dynamically based on current agent stats
        return string(
            abi.encodePacked(
                cogniNFTBaseURI,
                tokenId.toString(),
                "_",
                agent.reputationScore.toString(),
                "_",
                agent.tasksCompleted.toString(),
                "_",
                agent.tasksFailed.toString(),
                ".json"
            )
        );
    }

    // --- V. Skill Tree & Verifiable Proofs ---

    // 25. declareAgentSkill
    function declareAgentSkill(string memory _skillName, string memory _proofURI) public onlyAgent(msg.sender) whenNotPaused {
        bytes32 skillHash = keccak256(abi.encodePacked(_skillName));
        require(!agentSkills[msg.sender][skillHash].isVerified, "CogniChain: Skill already declared or verified.");

        agentSkills[msg.sender][skillHash] = AgentSkill({
            skillName: _skillName,
            proofURI: _proofURI,
            isVerified: false // Needs verification by oracle/governance
        });
        emit AgentSkillDeclared(msg.sender, skillHash, _skillName, _proofURI);
    }

    // 26. verifyAgentSkill
    function verifyAgentSkill(address _agent, bytes32 _skillHash) public onlyDisputeOracle whenNotPaused {
        require(agents[_agent].isRegistered, "CogniChain: Agent not registered.");
        require(!agentSkills[_agent][_skillHash].isVerified, "CogniChain: Skill already verified.");
        require(agentSkills[_agent][_skillHash].skillName.length > 0, "CogniChain: Skill not declared."); // Check if skill exists

        agentSkills[_agent][_skillHash].isVerified = true;
        _updateCogniNFT(_agent); // Trigger NFT update as a skill is verified
        emit AgentSkillVerified(_agent, _skillHash);
    }

    // 27. getAgentSkillStatus
    function getAgentSkillStatus(address _agent, bytes32 _skillHash) public view returns (bool isVerified, string memory skillName, string memory proofURI) {
        AgentSkill storage skill = agentSkills[_agent][_skillHash];
        return (skill.isVerified, skill.skillName, skill.proofURI);
    }

    // --- VI. Internal & Utility Functions ---

    function _updateAgentReputation(address _agent, int256 _reputationDelta) internal {
        AIAgent storage agent = agents[_agent];
        uint256 oldReputation = agent.reputationScore;
        if (_reputationDelta > 0) {
            agent.reputationScore += uint256(_reputationDelta);
        } else {
            // Prevent reputation from going below 0, or a minimum threshold
            uint256 deltaAbs = uint256(-_reputationDelta);
            if (agent.reputationScore > deltaAbs) {
                agent.reputationScore -= deltaAbs;
            } else {
                agent.reputationScore = 0; // Or a minimum base value, e.g., 100
            }
        }
        emit AgentReputationUpdated(_agent, _reputationDelta, agent.reputationScore);
        _updateCogniNFT(_agent); // Always update NFT after reputation change
    }

    function _slashAgentStake(address _agent, uint256 _amount, string memory _reason) internal {
        AIAgent storage agent = agents[_agent];
        require(agent.stake >= _amount, "CogniChain: Insufficient stake to slash.");
        agent.stake -= _amount;
        protocolCollectedFees[BOUNTY_TOKEN] += _amount; // Slashed stake goes to protocol fees
        emit AgentStakeSlashed(_agent, _amount, _reason);
        emit AgentStakeUpdated(_agent, agent.stake);
    }

    function _unlockAgentStake(address _agent, uint256 _amount) internal {
        require(lockedAgentStakes[_agent] >= _amount, "CogniChain: Not enough stake locked to unlock.");
        lockedAgentStakes[_agent] -= _amount;
    }

    // Getter for a task (public view)
    function getTask(uint256 _taskId)
        public
        view
        returns (
            address poster,
            address selectedAgent,
            uint256 bountyAmount,
            string memory taskURI,
            bytes32[] memory requiredSkillsHashes,
            TaskStatus status,
            uint256 deadline,
            uint256 submittedAt,
            string memory completionProofURI,
            bool disputeRaised
        )
    {
        Task storage task = tasks[_taskId];
        require(task.poster != address(0), "CogniChain: Task does not exist.");
        return (
            task.poster,
            task.selectedAgent,
            task.bountyAmount,
            task.taskURI,
            task.requiredSkillsHashes,
            task.status,
            task.deadline,
            task.submittedAt,
            task.completionProofURI,
            task.disputeRaised
        );
    }

    // Additional helper function to get bidders on a task
    function getTaskBidders(uint256 _taskId) public view returns (address[] memory) {
        return tasks[_taskId].bidders;
    }
}
```