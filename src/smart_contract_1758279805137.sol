Here's a smart contract in Solidity called `AetherForge`, designed to be an advanced, creative, and trendy platform for decentralized AI/computational agents. It integrates concepts like dynamic reputation, verifiable off-chain computation (via proofs and oracles), and dynamic Non-Fungible Tokens (NFTs) to represent agent profiles.

---

### Contract: `AetherForge`

**Concept:** `AetherForge` is a decentralized marketplace and orchestration platform for AI/computational agents. It enables users (requesters) to post tasks requiring advanced computation (e.g., AI model execution, data analysis, complex simulations). Decentralized "AetherAgents" can register, offer their services, and get rewarded based on verifiable performance and a dynamic reputation system. Agents are represented by unique, evolving NFTs (`AgentProfileNFTs`), and task completion is verified through submitted proofs, which can be zero-knowledge proofs (ZK-proofs) or oracle-verified computations. The platform handles agent registration, task posting, assignment, proof submission, and reputation updates, creating a trusted environment for decentralized AI services.

---

**Function Summary:**

**I. Core Registry & Management (Agent Lifecycle)**
1.  `registerAetherAgent(string _name, string _description, string[] memory _capabilities)`: Registers a new AI agent, mints an `AgentProfileNFT`, and assigns an initial reputation. Requires a minimum stake.
2.  `updateAgentProfile(uint256 _agentId, string _name, string _description, string[] memory _capabilities)`: Allows an agent to update their profile details.
3.  `deregisterAetherAgent(uint256 _agentId)`: Initiates the process for an agent to deregister, burning their NFT and starting a cool-down period for stake release.
4.  `stakeForAgentService(uint256 _agentId, uint256 _amount)`: Agents stake additional tokens to unlock higher service tiers or improve visibility.
5.  `unstakeAgentFunds(uint256 _agentId)`: Allows deregistered agents to withdraw their staked funds after a cool-down.
6.  `pauseAgentService(uint256 _agentId)`: Agent can temporarily pause their task-taking ability.
7.  `resumeAgentService(uint256 _agentId)`: Agent can resume service.
8.  `getAgentProfile(uint256 _agentId)`: Retrieves the detailed profile of a specific agent.
9.  `listActiveAgents(uint256 _startIndex, uint256 _count)`: Returns a paginated list of currently active agents.
10. `transferAgentNFT(uint256 _agentId, address _to)`: Allows the owner of an AgentProfileNFT to transfer ownership, also transferring associated stakes and reputation within AetherForge.

**II. Task Orchestration & Execution**
11. `postAetherTask(string _title, string _description, bytes32 _inputCID, uint256 _rewardAmount, uint256 _deadline, string[] memory _requiredCapabilities)`: User posts a task, specifying requirements, reward, and deadline. Requires staking the reward amount.
12. `bidOnTask(uint256 _taskId, uint256 _agentId, uint256 _bidAmount)`: An agent places a bid on an open task (currently an event for intent; actual assignment happens via `assignTaskToAgent`).
13. `assignTaskToAgent(uint256 _taskId, uint256 _agentId)`: Requester assigns a task to a chosen agent after evaluating bids (or based on reputation).
14. `submitTaskProof(uint256 _taskId, bytes32 _proofCID, bytes32 _outputCID)`: Assigned agent submits the verifiable proof of computation and the output data CID.
15. `requestProofVerification(uint256 _taskId)`: Triggers an external oracle/verifier to process the submitted proof.
16. `_receiveProofVerificationResult(uint256 _taskId, bool _isValid)`: Internal callback from the verifier to update task status based on proof validity.
17. `confirmTaskCompletion(uint256 _taskId)`: Requester confirms satisfaction after proof verification, triggering reward payment and reputation update.
18. `disputeTaskOutcome(uint256 _taskId, string _reasonCID)`: Either requester or agent can initiate a dispute, sending it to an arbitration system.
19. `cancelTask(uint256 _taskId)`: Requester can cancel an unassigned task or assigned task under specific conditions (e.g., deadline expiry).
20. `claimTaskReward(uint256 _taskId)`: Agent claims their reward after successful task completion and verification (currently integrated into `confirmTaskCompletion`).
21. `getTaskDetails(uint256 _taskId)`: Retrieves detailed information about a specific task.
22. `listOpenTasks(uint256 _startIndex, uint256 _count, string[] memory _filterCapabilities)`: Paginated list of open tasks, filterable by required capabilities.
23. `listAgentTasks(uint256 _agentId, uint256 _startIndex, uint256 _count)`: Paginated list of tasks assigned to or completed by a specific agent.

**III. Reputation & Feedback**
24. `submitRequesterReview(uint256 _taskId, uint8 _rating, string _reviewCID)`: Requester provides a rating and optional review for the agent, impacting reputation.
25. `submitAgentReview(uint256 _taskId, uint8 _rating, string _reviewCID)`: Agent provides a rating and optional feedback for the requester (for data collection).
26. `getAgentReputationHistory(uint256 _agentId)`: Retrieves a log of reputation changes for an agent.

**IV. Administrative & System Functions**
27. `setArbitrationContract(address _arbitrationContract)`: Sets the address of the external arbitration contract.
28. `setProofVerifierAddress(address _proofVerifierAddress)`: Sets the address of the authorized proof verifier for `_receiveProofVerificationResult`.
29. `setReputationAlgorithmParams(int256 _baseTaskReputation, int256 _successfulProofReputation, int256 _positiveReview, int256 _negativeReview, int256 _disputePenalty, uint256 _minAgentStake, uint256 _deregCoolDown, uint256 _taskDispCoolDown)`: Allows admin to tune the reputation calculation parameters.
30. `rescueFunds(address _tokenAddress, uint256 _amount)`: Admin function to rescue accidentally sent ERC20 tokens (not primary reward token) to the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Minimal Strings library from OpenZeppelin for uint256 to string conversion
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
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

// --- Interfaces ---
/**
 * @dev Interface for the AgentProfileNFT ERC721 contract.
 *      This contract is assumed to be deployed separately and manages the actual NFTs.
 *      AetherForge interacts with it to mint, burn, and transfer agent NFTs.
 */
interface IAgentProfileNFT {
    function mint(address to, uint256 agentId) external returns (uint256 tokenId);
    function burn(uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    // Other standard ERC721 functions like approve, getApproved, setApprovalForAll, isApprovedForAll
    function supportsInterface(bytes4 interfaceId) external view returns (bool); // For ERC165
}

/**
 * @title AetherForge
 * @dev A decentralized marketplace and orchestration platform for AI/computational agents.
 *      It enables users to post tasks requiring advanced computation, agents to register and offer their services,
 *      and a robust reputation system to ensure quality and accountability. Agents are represented by unique,
 *      dynamic NFTs, and task completion is verified through submitted proofs, which can be ZK-proofs
 *      or oracle-verified computations.
 */
contract AetherForge is Ownable, ReentrancyGuard {

    // --- Enums ---
    enum AgentStatus { Inactive, Active, Paused, Deregistered }
    enum TaskStatus { Open, Assigned, ProofSubmitted, ProofVerified, Completed, Disputed, Cancelled }

    // --- Structs ---
    struct AgentProfile {
        address owner;
        string name;
        string description;
        string[] capabilities; // e.g., ["ZK-Proof Generation", "Image Classification", "Data Analysis"]
        int256 reputationScore; // Can be negative for bad actors
        AgentStatus status;
        uint256 stakeAmount; // Tokens staked by the agent
        uint256 agentNFTId; // The tokenId of the associated AgentProfileNFT
        uint256 lastActiveTimestamp; // Used for cool-down calculation for deregistration
    }

    struct Task {
        address requester;
        string title;
        string description;
        bytes32 inputCID; // IPFS CID for input data/parameters
        bytes32 outputCID; // IPFS CID for output data (submitted by agent)
        uint256 rewardAmount;
        uint256 deadline; // Timestamp
        TaskStatus status;
        uint256 assignedAgentId; // 0 if not assigned
        bytes32 proofCID; // IPFS CID for the verifiable proof of computation (submitted by agent)
        int256 reputationImpact; // Expected reputation change on completion (calculated internally)
        uint256 assignedAgentBidAmount; // The amount the assigned agent bid (if applicable), defaults to rewardAmount
        uint256 creationTimestamp;
        string[] requiredCapabilities;
    }

    struct ReputationLog {
        uint256 timestamp;
        int256 changeAmount;
        string reason; // e.g., "Task Completion", "Requester Review", "Dispute Penalty"
    }

    // --- State Variables ---
    uint256 private _agentCounter; // Incremental ID for new agents
    uint256 private _taskCounter;  // Incremental ID for new tasks

    mapping(uint256 => AgentProfile) public agents; // Agent ID => AgentProfile details
    mapping(address => uint256) public agentIdByOwner; // Agent owner address => Agent ID (one agent per owner)
    mapping(uint256 => Task) public tasks; // Task ID => Task details
    mapping(uint256 => uint256[]) public agentTasks; // Agent ID => List of task IDs assigned to/completed by agent
    mapping(address => uint256[]) public requesterTasks; // Requester address => List of task IDs posted by requester
    mapping(uint256 => ReputationLog[]) public agentReputationHistory; // Agent ID => History of reputation changes

    IAgentProfileNFT public agentNFTContract; // Address of the external AgentProfileNFT ERC721 contract
    IERC20 public rewardToken; // Address of the ERC20 token used for rewards and staking
    address public arbitrationContract; // Address of the external arbitration system (optional)
    address public proofVerifierAddress; // Address authorized to call _receiveProofVerificationResult

    // Reputation Algorithm Parameters (Admin configurable)
    struct ReputationParams {
        int256 baseTaskCompletionReputation;        // Base points for a successfully completed task
        int256 successfulProofVerificationReputation; // Additional points for verifiable proof
        int256 positiveReviewReputation;            // Points for a positive review (4-5 stars)
        int256 negativeReviewReputation;            // Points deducted for a negative review (1-2 stars)
        int256 disputePenaltyReputation;            // Points deducted if an agent loses a dispute
        uint256 minAgentStakeAmount;               // Minimum tokens required to register an agent
        uint256 deregistrationCoolDown;            // Time in seconds before a deregistered agent can withdraw stake
        uint256 taskDisputeCoolDown;               // Time window after task completion/proof for initiating a dispute
    }
    ReputationParams public reputationParams;

    // --- Events ---
    event AgentRegistered(uint256 indexed agentId, address indexed owner, string name, uint256 nftTokenId);
    event AgentProfileUpdated(uint256 indexed agentId, string name, string description, string[] capabilities);
    event AgentDeregistered(uint256 indexed agentId, address indexed owner);
    event AgentStaked(uint256 indexed agentId, uint256 amount);
    event AgentUnstaked(uint256 indexed agentId, uint256 amount);
    event AgentStatusChanged(uint256 indexed agentId, AgentStatus newStatus);
    event AgentNFTTransferred(uint256 indexed agentId, uint256 nftTokenId, address indexed from, address indexed to);

    event TaskPosted(uint256 indexed taskId, address indexed requester, uint256 rewardAmount, uint256 deadline);
    event TaskBid(uint256 indexed taskId, uint256 indexed agentId, uint256 bidAmount);
    event TaskAssigned(uint256 indexed taskId, uint256 indexed agentId);
    event TaskProofSubmitted(uint256 indexed taskId, uint256 indexed agentId, bytes32 proofCID, bytes32 outputCID);
    event TaskProofVerificationRequested(uint256 indexed taskId);
    event TaskProofVerified(uint256 indexed taskId, bool isValid);
    event TaskCompleted(uint256 indexed taskId, uint256 indexed agentId, address indexed requester, uint256 reward);
    event TaskDisputed(uint256 indexed taskId, address indexed disputer, string reasonCID);
    event TaskCancelled(uint256 indexed taskId, address indexed canceller);
    event TaskRewardClaimed(uint256 indexed taskId, uint256 indexed agentId, uint256 amount);

    event ReputationUpdated(uint256 indexed agentId, int256 oldScore, int256 newScore, string reason);
    event ReviewSubmitted(uint256 indexed taskId, uint256 indexed agentId, address indexed reviewer, uint8 rating, string reviewCID);

    // --- Constructor ---
    /**
     * @dev Constructor to initialize the contract with addresses for the AgentProfileNFT,
     *      the reward token (ERC20), and the authorized proof verifier.
     * @param _nftContract The address of the deployed IAgentProfileNFT contract.
     * @param _rewardToken The address of the ERC20 token used for rewards and staking.
     * @param _proofVerifierAddress The address authorized to call `_receiveProofVerificationResult`.
     */
    constructor(address _nftContract, address _rewardToken, address _proofVerifierAddress) Ownable(msg.sender) {
        require(_nftContract != address(0), "NFT contract address cannot be zero");
        require(_rewardToken != address(0), "Reward token address cannot be zero");
        require(_proofVerifierAddress != address(0), "Proof verifier address cannot be zero");

        agentNFTContract = IAgentProfileNFT(_nftContract);
        rewardToken = IERC20(_rewardToken);
        proofVerifierAddress = _proofVerifierAddress;

        // Set initial reputation parameters (can be adjusted by owner later)
        reputationParams = ReputationParams({
            baseTaskCompletionReputation: 10,
            successfulProofVerificationReputation: 20,
            positiveReviewReputation: 15,
            negativeReviewReputation: -25,
            disputePenaltyReputation: -50,
            minAgentStakeAmount: 1 * 10**18, // Example: 1 token (assuming 18 decimals)
            deregistrationCoolDown: 7 days,
            taskDisputeCoolDown: 3 days
        });
    }

    // --- Modifiers ---
    modifier onlyAgentOwner(uint256 _agentId) {
        require(agents[_agentId].owner == msg.sender, "Caller is not the agent owner");
        _;
    }

    modifier onlyRequester(uint256 _taskId) {
        require(tasks[_taskId].requester == msg.sender, "Caller is not the task requester");
        _;
    }

    modifier onlyAssignedAgent(uint256 _taskId) {
        require(tasks[_taskId].assignedAgentId != 0, "Task not assigned");
        require(agents[tasks[_taskId].assignedAgentId].owner == msg.sender, "Caller is not the assigned agent");
        _;
    }

    modifier onlyProofVerifier() {
        require(msg.sender == proofVerifierAddress, "Caller is not the authorized proof verifier");
        _;
    }

    // --- Helper Functions (Internal) ---

    /**
     * @dev Internal function to update an agent's reputation score and log the change.
     * @param _agentId The ID of the agent whose reputation to update.
     * @param _change The amount to change the reputation score by (can be positive or negative).
     * @param _reason A string describing the reason for the reputation change.
     */
    function _updateAgentReputation(uint256 _agentId, int256 _change, string memory _reason) internal {
        AgentProfile storage agent = agents[_agentId];
        int256 oldScore = agent.reputationScore;
        agent.reputationScore += _change;
        agentReputationHistory[_agentId].push(ReputationLog(block.timestamp, _change, _reason));
        emit ReputationUpdated(_agentId, oldScore, agent.reputationScore, _reason);
    }

    // --- I. Core Registry & Management (Agent Lifecycle) ---

    /**
     * @dev Registers a new AI agent, mints an `AgentProfileNFT`, and assigns an initial reputation.
     *      Requires a minimum stake to activate the agent.
     * @param _name The public name of the agent.
     * @param _description A description of the agent's capabilities and services.
     * @param _capabilities An array of strings describing the agent's specific capabilities (e.g., "Image Recognition", "ZK-Proof Generation").
     */
    function registerAetherAgent(
        string memory _name,
        string memory _description,
        string[] memory _capabilities
    ) external nonReentrant {
        require(agentIdByOwner[msg.sender] == 0, "Caller already owns an agent");
        require(bytes(_name).length > 0, "Agent name cannot be empty");
        require(bytes(_description).length > 0, "Agent description cannot be empty");
        require(_capabilities.length > 0, "Agent must specify at least one capability");
        require(rewardToken.balanceOf(msg.sender) >= reputationParams.minAgentStakeAmount, "Insufficient funds to stake");
        require(rewardToken.allowance(msg.sender, address(this)) >= reputationParams.minAgentStakeAmount, "Approve tokens for staking first");

        _agentCounter++;
        uint256 newAgentId = _agentCounter;

        // Transfer stake from agent owner to contract
        require(rewardToken.transferFrom(msg.sender, address(this), reputationParams.minAgentStakeAmount), "Stake transfer failed");

        // Mint AgentProfileNFT representing this agent
        uint256 nftTokenId = agentNFTContract.mint(msg.sender, newAgentId);

        agents[newAgentId] = AgentProfile({
            owner: msg.sender,
            name: _name,
            description: _description,
            capabilities: _capabilities,
            reputationScore: 100, // Initial reputation score
            status: AgentStatus.Active,
            stakeAmount: reputationParams.minAgentStakeAmount,
            agentNFTId: nftTokenId,
            lastActiveTimestamp: block.timestamp
        });
        agentIdByOwner[msg.sender] = newAgentId;

        emit AgentRegistered(newAgentId, msg.sender, _name, nftTokenId);
    }

    /**
     * @dev Allows an agent to update their profile details.
     * @param _agentId The ID of the agent to update.
     * @param _name The new name of the agent.
     * @param _description The new description.
     * @param _capabilities The new list of capabilities.
     */
    function updateAgentProfile(
        uint256 _agentId,
        string memory _name,
        string memory _description,
        string[] memory _capabilities
    ) external onlyAgentOwner(_agentId) {
        AgentProfile storage agent = agents[_agentId];
        require(agent.status != AgentStatus.Deregistered, "Agent is deregistered and cannot update profile");
        require(bytes(_name).length > 0, "Agent name cannot be empty");
        require(bytes(_description).length > 0, "Agent description cannot be empty");
        require(_capabilities.length > 0, "Agent must specify at least one capability");

        agent.name = _name;
        agent.description = _description;
        agent.capabilities = _capabilities;

        emit AgentProfileUpdated(_agentId, _name, _description, _capabilities);
    }

    /**
     * @dev Initiates the process for an agent to deregister.
     *      Burns the associated NFT and locks staked funds for a cool-down period.
     * @param _agentId The ID of the agent to deregister.
     */
    function deregisterAetherAgent(uint256 _agentId) external onlyAgentOwner(_agentId) nonReentrant {
        AgentProfile storage agent = agents[_agentId];
        require(agent.status != AgentStatus.Deregistered, "Agent already deregistered");
        
        // Ensure no active tasks
        for (uint256 i = 0; i < agentTasks[_agentId].length; i++) {
            uint256 taskId = agentTasks[_agentId][i];
            TaskStatus status = tasks[taskId].status;
            if (status == TaskStatus.Assigned || status == TaskStatus.ProofSubmitted || status == TaskStatus.ProofVerified || status == TaskStatus.Disputed) {
                revert("Cannot deregister with active or pending tasks");
            }
        }

        agent.status = AgentStatus.Deregistered;
        agent.lastActiveTimestamp = block.timestamp; // Mark time for cool-down start
        
        // Burn the associated NFT, signifying agent is no longer active
        agentNFTContract.burn(agent.agentNFTId);

        emit AgentDeregistered(_agentId, msg.sender);
        emit AgentStatusChanged(_agentId, AgentStatus.Deregistered);
    }

    /**
     * @dev Agents can stake additional tokens to unlock higher service tiers or improve visibility.
     * @param _agentId The ID of the agent.
     * @param _amount The amount of additional reward tokens to stake.
     */
    function stakeForAgentService(uint256 _agentId, uint256 _amount) external onlyAgentOwner(_agentId) nonReentrant {
        AgentProfile storage agent = agents[_agentId];
        require(agent.status != AgentStatus.Deregistered, "Cannot stake for a deregistered agent");
        require(_amount > 0, "Stake amount must be greater than zero");
        
        require(rewardToken.allowance(msg.sender, address(this)) >= _amount, "Approve tokens for staking");
        require(rewardToken.transferFrom(msg.sender, address(this), _amount), "Additional stake transfer failed");
        
        agent.stakeAmount += _amount;
        emit AgentStaked(_agentId, _amount);
    }

    /**
     * @dev Allows a deregistered agent to unstake their funds after the cool-down period.
     *      This effectively removes the agent from the active registry, though their historical data might remain.
     * @param _agentId The ID of the agent whose funds to unstake.
     */
    function unstakeAgentFunds(uint256 _agentId) external onlyAgentOwner(_agentId) nonReentrant {
        AgentProfile storage agent = agents[_agentId];
        require(agent.status == AgentStatus.Deregistered, "Agent must be deregistered to unstake funds");
        require(block.timestamp >= agent.lastActiveTimestamp + reputationParams.deregistrationCoolDown, "Deregistration cool-down period not over");
        require(agent.stakeAmount > 0, "No funds to unstake");

        uint256 amountToTransfer = agent.stakeAmount;
        agent.stakeAmount = 0;

        require(rewardToken.transfer(msg.sender, amountToTransfer), "Unstake transfer failed");
        
        // Clear agentIdByOwner mapping once funds are fully withdrawn
        delete agentIdByOwner[msg.sender];
        // Note: The agent's profile in the `agents` mapping remains for historical lookup,
        // but its status is Deregistered and stake is 0.

        emit AgentUnstaked(_agentId, amountToTransfer);
    }

    /**
     * @dev Agent can temporarily pause their task-taking ability.
     * @param _agentId The ID of the agent.
     */
    function pauseAgentService(uint256 _agentId) external onlyAgentOwner(_agentId) {
        AgentProfile storage agent = agents[_agentId];
        require(agent.status == AgentStatus.Active, "Agent is not active");
        agent.status = AgentStatus.Paused;
        emit AgentStatusChanged(_agentId, AgentStatus.Paused);
    }

    /**
     * @dev Agent can resume service.
     * @param _agentId The ID of the agent.
     */
    function resumeAgentService(uint256 _agentId) external onlyAgentOwner(_agentId) {
        AgentProfile storage agent = agents[_agentId];
        require(agent.status == AgentStatus.Paused, "Agent is not paused");
        agent.status = AgentStatus.Active;
        agent.lastActiveTimestamp = block.timestamp; // Update last active timestamp
        emit AgentStatusChanged(_agentId, AgentStatus.Active);
    }

    /**
     * @dev Retrieves the detailed profile of a specific agent.
     * @param _agentId The ID of the agent.
     * @return AgentProfile struct containing agent details.
     */
    function getAgentProfile(uint256 _agentId) external view returns (AgentProfile memory) {
        require(_agentId > 0 && _agentId <= _agentCounter, "Invalid agent ID");
        return agents[_agentId];
    }

    /**
     * @dev Returns a paginated list of active agents.
     * @param _startIndex The starting index for pagination (0-indexed).
     * @param _count The maximum number of agents to return.
     * @return An array of AgentProfile structs.
     */
    function listActiveAgents(uint256 _startIndex, uint256 _count) external view returns (AgentProfile[] memory) {
        require(_count > 0, "Count must be greater than zero");
        
        uint256 totalAgents = _agentCounter;
        uint256 resultCount = 0; // Count of active agents
        for (uint256 i = 1; i <= totalAgents; i++) {
            if (agents[i].status == AgentStatus.Active) {
                resultCount++;
            }
        }

        uint256 actualReturnCount = 0;
        if (_startIndex < resultCount) {
            actualReturnCount = resultCount - _startIndex;
            if (actualReturnCount > _count) {
                actualReturnCount = _count;
            }
        }
        
        AgentProfile[] memory activeAgents = new AgentProfile[](actualReturnCount);
        uint256 currentIndex = 0;
        uint256 processedCount = 0;

        for (uint256 i = 1; i <= totalAgents && currentIndex < actualReturnCount; i++) {
            if (agents[i].status == AgentStatus.Active) {
                if (processedCount >= _startIndex) {
                    activeAgents[currentIndex] = agents[i];
                    currentIndex++;
                }
                processedCount++;
            }
        }
        return activeAgents;
    }

    /**
     * @dev Allows the owner of an AgentProfileNFT to transfer ownership.
     *      This also transfers associated stakes and reputation within AetherForge.
     * @param _agentId The ID of the agent whose NFT is being transferred.
     * @param _to The address of the new owner.
     */
    function transferAgentNFT(uint256 _agentId, address _to) external onlyAgentOwner(_agentId) nonReentrant {
        require(_to != address(0), "Cannot transfer to zero address");
        require(agentIdByOwner[_to] == 0, "Recipient already owns an agent profile");

        AgentProfile storage agent = agents[_agentId];
        uint256 nftTokenId = agent.agentNFTId;

        // Transfer the NFT via the external contract
        agentNFTContract.transferFrom(msg.sender, _to, nftTokenId);

        // Update ownership in AetherForge's internal mapping
        delete agentIdByOwner[msg.sender];
        agentIdByOwner[_to] = _agentId;
        agent.owner = _to;

        emit AgentNFTTransferred(_agentId, nftTokenId, msg.sender, _to);
    }

    // --- II. Task Orchestration & Execution ---

    /**
     * @dev User posts a task, specifying requirements, reward, and deadline.
     *      Requires staking the reward amount with the contract.
     * @param _title The title of the task.
     * @param _description A detailed description of the task.
     * @param _inputCID IPFS CID for input data/parameters for the task.
     * @param _rewardAmount The amount of reward tokens for successful completion.
     * @param _deadline The timestamp by which the task must be completed by an agent.
     * @param _requiredCapabilities An array of capabilities the agent must possess to take on this task.
     */
    function postAetherTask(
        string memory _title,
        string memory _description,
        bytes32 _inputCID,
        uint256 _rewardAmount,
        uint256 _deadline,
        string[] memory _requiredCapabilities
    ) external nonReentrant {
        require(bytes(_title).length > 0, "Task title cannot be empty");
        require(bytes(_description).length > 0, "Task description cannot be empty");
        require(_inputCID != bytes32(0), "Input CID cannot be zero");
        require(_rewardAmount > 0, "Reward amount must be greater than zero");
        require(_deadline > block.timestamp, "Deadline must be in the future");
        require(_requiredCapabilities.length > 0, "Task must specify required capabilities");
        require(rewardToken.balanceOf(msg.sender) >= _rewardAmount, "Insufficient funds to stake reward");
        require(rewardToken.allowance(msg.sender, address(this)) >= _rewardAmount, "Approve tokens for reward staking first");

        // Transfer reward tokens from requester to the contract
        require(rewardToken.transferFrom(msg.sender, address(this), _rewardAmount), "Reward stake transfer failed");

        _taskCounter++;
        uint256 newTaskId = _taskCounter;

        tasks[newTaskId] = Task({
            requester: msg.sender,
            title: _title,
            description: _description,
            inputCID: _inputCID,
            outputCID: bytes32(0),
            rewardAmount: _rewardAmount,
            deadline: _deadline,
            status: TaskStatus.Open,
            assignedAgentId: 0,
            proofCID: bytes32(0),
            reputationImpact: 0, // Calculated later upon completion/dispute
            assignedAgentBidAmount: 0, // Will be set upon assignment
            creationTimestamp: block.timestamp,
            requiredCapabilities: _requiredCapabilities
        });

        requesterTasks[msg.sender].push(newTaskId);

        emit TaskPosted(newTaskId, msg.sender, _rewardAmount, _deadline);
    }

    /**
     * @dev An agent places a bid on an open task.
     *      This function primarily records the intent to bid and the proposed `_bidAmount`.
     *      The actual assignment is handled by `assignTaskToAgent`.
     * @param _taskId The ID of the task to bid on.
     * @param _agentId The ID of the agent placing the bid.
     * @param _bidAmount The amount of reward tokens the agent is willing to accept (can be less than task.rewardAmount).
     */
    function bidOnTask(uint256 _taskId, uint256 _agentId, uint256 _bidAmount) external onlyAgentOwner(_agentId) {
        Task storage task = tasks[_taskId];
        AgentProfile storage agent = agents[_agentId];

        require(task.status == TaskStatus.Open, "Task is not open for bidding");
        require(agent.status == AgentStatus.Active, "Agent is not active");
        require(_bidAmount <= task.rewardAmount, "Bid amount cannot exceed task reward");
        require(block.timestamp < task.deadline, "Task deadline has passed");

        // Note: For simplicity, this contract doesn't explicitly store multiple bids in state.
        // It assumes off-chain bid aggregation/selection, or a direct assignment model where the
        // requester specifies the `assignedAgentBidAmount` in `assignTaskToAgent`.
        // This event serves as an on-chain record of the bid being placed.
        emit TaskBid(_taskId, _agentId, _bidAmount);
    }

    /**
     * @dev Requester assigns a task to a chosen agent.
     *      The `_bidAmount` here is the *agreed* amount the agent will receive, which can be different
     *      from the initial `task.rewardAmount` if agents bid lower.
     * @param _taskId The ID of the task.
     * @param _agentId The ID of the agent to assign.
     * @param _agreedBidAmount The final agreed reward amount for the assigned agent.
     */
    function assignTaskToAgent(uint256 _taskId, uint256 _agentId, uint256 _agreedBidAmount) external onlyRequester(_taskId) nonReentrant {
        Task storage task = tasks[_taskId];
        AgentProfile storage agent = agents[_agentId];

        require(task.status == TaskStatus.Open, "Task is not open for assignment");
        require(agent.status == AgentStatus.Active, "Agent is not active or does not exist");
        require(block.timestamp < task.deadline, "Task deadline has passed");
        require(_agreedBidAmount > 0 && _agreedBidAmount <= task.rewardAmount, "Agreed bid amount invalid");
        
        // Check if agent has all required capabilities for the task
        for (uint256 i = 0; i < task.requiredCapabilities.length; i++) {
            bool capabilityFound = false;
            for (uint256 j = 0; j < agent.capabilities.length; j++) {
                if (keccak256(abi.encodePacked(task.requiredCapabilities[i])) == keccak256(abi.encodePacked(agent.capabilities[j]))) {
                    capabilityFound = true;
                    break;
                }
            }
            require(capabilityFound, string(abi.encodePacked("Agent lacks required capability: ", task.requiredCapabilities[i])));
        }

        task.assignedAgentId = _agentId;
        task.status = TaskStatus.Assigned;
        task.assignedAgentBidAmount = _agreedBidAmount;

        agentTasks[_agentId].push(_taskId); // Add task to agent's list

        emit TaskAssigned(_taskId, _agentId);
    }

    /**
     * @dev Assigned agent submits the verifiable proof of computation and the output data CID.
     * @param _taskId The ID of the task.
     * @param _proofCID IPFS CID for the verifiable proof (e.g., ZKProof, signed oracle data).
     * @param _outputCID IPFS CID for the final result data produced by the agent.
     */
    function submitTaskProof(uint256 _taskId, bytes32 _proofCID, bytes32 _outputCID) external onlyAssignedAgent(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Assigned, "Task is not in 'Assigned' status");
        require(block.timestamp < task.deadline, "Task deadline has passed, proof cannot be submitted");
        require(_proofCID != bytes32(0), "Proof CID cannot be empty");
        require(_outputCID != bytes32(0), "Output CID cannot be empty");

        task.proofCID = _proofCID;
        task.outputCID = _outputCID;
        task.status = TaskStatus.ProofSubmitted;

        emit TaskProofSubmitted(_taskId, task.assignedAgentId, _proofCID, _outputCID);
    }

    /**
     * @dev Triggers an external oracle/verifier to process the submitted proof.
     *      This function typically emits an event that an off-chain relayer/keeper monitors
     *      to initiate the actual verification process (e.g., submitting to a ZKP verifier,
     *      or a Chainlink Function call).
     * @param _taskId The ID of the task for which to verify the proof.
     */
    function requestProofVerification(uint256 _taskId) external {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.ProofSubmitted, "Task is not in 'ProofSubmitted' status");
        // Allow a grace period for verification after the deadline
        require(block.timestamp < task.deadline + (1 hours), "Verification window has passed"); 
        
        // Emit an event for an off-chain oracle/verifier to pick up
        emit TaskProofVerificationRequested(_taskId);
    }

    /**
     * @dev Internal callback function called by the designated `proofVerifierAddress`
     *      to update task status based on the outcome of the proof verification.
     * @param _taskId The ID of the task.
     * @param _isValid Boolean indicating if the proof was successfully verified.
     */
    function _receiveProofVerificationResult(uint256 _taskId, bool _isValid) external onlyProofVerifier {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.ProofSubmitted, "Task is not awaiting proof verification");

        task.status = TaskStatus.ProofVerified;
        emit TaskProofVerified(_taskId, _isValid);

        if (!_isValid) {
            // Proof failed: penalize agent and allow requester to re-assign or cancel
            _updateAgentReputation(task.assignedAgentId, reputationParams.negativeReviewReputation, "Proof Verification Failed");
            task.status = TaskStatus.Open; // Make it open again for other agents
            task.assignedAgentId = 0; // Unassign agent
            task.proofCID = bytes32(0); // Clear proof
            task.outputCID = bytes32(0); // Clear output
            task.assignedAgentBidAmount = 0; // Clear bid
            // Optionally, consider refunding a portion of the original reward to requester if the agent has a high stake.
        } else {
            // Proof successful: reward agent with reputation
            _updateAgentReputation(task.assignedAgentId, reputationParams.successfulProofVerificationReputation, "Proof Verified Successfully");
            // Task remains in ProofVerified status, awaiting requester's final confirmation (confirmTaskCompletion)
        }
    }

    /**
     * @dev Requester confirms satisfaction after proof verification.
     *      This triggers the final reward payment to the agent and a reputation update.
     * @param _taskId The ID of the task.
     */
    function confirmTaskCompletion(uint256 _taskId) external onlyRequester(_taskId) nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.ProofVerified, "Task is not in 'ProofVerified' status");
        require(block.timestamp < task.deadline + reputationParams.taskDisputeCoolDown, "Dispute window has closed");

        task.status = TaskStatus.Completed;

        // Pay the assigned agent their agreed bid amount
        require(rewardToken.transfer(agents[task.assignedAgentId].owner, task.assignedAgentBidAmount), "Reward transfer failed");
        
        // If there's any remaining reward (task.rewardAmount - task.assignedAgentBidAmount), refund to requester.
        if (task.rewardAmount > task.assignedAgentBidAmount) {
            require(rewardToken.transfer(task.requester, task.rewardAmount - task.assignedAgentBidAmount), "Reward surplus refund failed");
        }

        // Update agent's reputation for successful completion
        _updateAgentReputation(task.assignedAgentId, reputationParams.baseTaskCompletionReputation, "Task Completed Successfully");

        emit TaskCompleted(_taskId, task.assignedAgentId, msg.sender, task.assignedAgentBidAmount);
    }

    /**
     * @dev Either requester or agent can initiate a dispute, sending it to an external arbitration system.
     *      This puts the task into a `Disputed` state, pausing further actions until arbitration resolves.
     * @param _taskId The ID of the task.
     * @param _reasonCID IPFS CID for the detailed reason for the dispute.
     */
    function disputeTaskOutcome(uint256 _taskId, string memory _reasonCID) external nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Assigned || task.status == TaskStatus.ProofSubmitted || task.status == TaskStatus.ProofVerified, "Task cannot be disputed in current status");
        require(block.timestamp < task.deadline + reputationParams.taskDisputeCoolDown, "Dispute window has closed");
        require(msg.sender == task.requester || (task.assignedAgentId != 0 && msg.sender == agents[task.assignedAgentId].owner), "Only requester or assigned agent can dispute");
        require(arbitrationContract != address(0), "Arbitration contract not set by owner");
        require(bytes(_reasonCID).length > 0, "Reason CID cannot be empty");

        task.status = TaskStatus.Disputed;
        // In a real system, this would call a function on the arbitrationContract,
        // passing relevant task and party IDs along with _reasonCID.
        // IArbitration(arbitrationContract).submitDispute(_taskId, msg.sender, task.requester, agents[task.assignedAgentId].owner, _reasonCID);
        
        emit TaskDisputed(_taskId, msg.sender, _reasonCID);
    }

    /**
     * @dev Requester can cancel an unassigned task or assigned task under certain conditions.
     *      If cancelled after assignment and before deadline, there might be implications for agent reputation.
     * @param _taskId The ID of the task to cancel.
     */
    function cancelTask(uint256 _taskId) external onlyRequester(_taskId) nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Open || task.status == TaskStatus.Assigned, "Task cannot be cancelled in current state");
        
        if (task.status == TaskStatus.Assigned) {
            // If task was assigned but deadline passed without proof, requester can cancel without penalty to themself.
            require(block.timestamp > task.deadline, "Cannot cancel an assigned task before its deadline");
            _updateAgentReputation(task.assignedAgentId, reputationParams.negativeReviewReputation, "Task Cancelled due to Agent Deadline Expiry");
        }

        task.status = TaskStatus.Cancelled;

        // Refund the full original reward amount to the requester
        require(rewardToken.transfer(task.requester, task.rewardAmount), "Reward refund failed");

        emit TaskCancelled(_taskId, msg.sender);
    }

    /**
     * @dev Agent claims their reward after successful task completion and verification.
     *      Note: In this specific implementation, reward distribution for successful tasks
     *      is handled directly within `confirmTaskCompletion`. This function serves as a
     *      placeholder if a multi-step claim process were desired. For now, it will revert.
     * @param _taskId The ID of the task.
     */
    function claimTaskReward(uint256 _taskId) external onlyAssignedAgent(_taskId) nonReentrant {
        // This function is illustrative. In this implementation, rewards are paid directly
        // during `confirmTaskCompletion`. If a separate claim step was desired,
        // `confirmTaskCompletion` would mark reward as claimable, and this function would process it.
        revert("Rewards are distributed directly upon task confirmation.");
        /*
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Completed, "Task is not completed");
        require(task.rewardAmount > 0, "No reward to claim or already claimed"); // task.rewardAmount here would be 'claimableReward'

        uint256 reward = task.rewardAmount;
        task.rewardAmount = 0; // Mark as claimed

        require(rewardToken.transfer(msg.sender, reward), "Reward claim transfer failed");

        emit TaskRewardClaimed(_taskId, task.assignedAgentId, reward);
        */
    }

    /**
     * @dev Retrieves the detailed information about a specific task.
     * @param _taskId The ID of the task.
     * @return Task struct containing task details.
     */
    function getTaskDetails(uint256 _taskId) external view returns (Task memory) {
        require(_taskId > 0 && _taskId <= _taskCounter, "Invalid task ID");
        return tasks[_taskId];
    }

    /**
     * @dev Paginated list of open tasks, filterable by required capabilities.
     *      A task is considered open if its status is `Open` and its deadline has not passed.
     * @param _startIndex The starting index for pagination (0-indexed).
     * @param _count The maximum number of tasks to return.
     * @param _filterCapabilities An optional array of capabilities; only tasks requiring ALL specified capabilities will be returned.
     * @return An array of Task structs.
     */
    function listOpenTasks(
        uint256 _startIndex,
        uint256 _count,
        string[] memory _filterCapabilities
    ) external view returns (Task[] memory) {
        require(_count > 0, "Count must be greater than zero");
        
        uint256 totalTasks = _taskCounter;
        uint256[] memory matchingTaskIds = new uint256[](totalTasks); // Temporary array to store matching task IDs
        uint256 matchingCount = 0;

        for (uint256 i = 1; i <= totalTasks; i++) {
            if (tasks[i].status == TaskStatus.Open && tasks[i].deadline > block.timestamp) {
                bool meetsFilter = true;
                if (_filterCapabilities.length > 0) {
                    // Check if the task's required capabilities include ALL filter capabilities
                    for (uint256 j = 0; j < _filterCapabilities.length; j++) {
                        bool capabilityFound = false;
                        for (uint256 k = 0; k < tasks[i].requiredCapabilities.length; k++) {
                            if (keccak256(abi.encodePacked(_filterCapabilities[j])) == keccak256(abi.encodePacked(tasks[i].requiredCapabilities[k]))) {
                                capabilityFound = true;
                                break;
                            }
                        }
                        if (!capabilityFound) {
                            meetsFilter = false;
                            break;
                        }
                    }
                }
                if (meetsFilter) {
                    matchingTaskIds[matchingCount] = i;
                    matchingCount++;
                }
            }
        }

        uint256 actualReturnCount = 0;
        if (_startIndex < matchingCount) {
            actualReturnCount = matchingCount - _startIndex;
            if (actualReturnCount > _count) {
                actualReturnCount = _count;
            }
        }

        Task[] memory openTasks = new Task[](actualReturnCount);
        for (uint256 i = 0; i < actualReturnCount; i++) {
            openTasks[i] = tasks[matchingTaskIds[_startIndex + i]];
        }
        return openTasks;
    }

    /**
     * @dev Paginated list of tasks assigned to or completed by a specific agent.
     * @param _agentId The ID of the agent.
     * @param _startIndex The starting index for pagination (0-indexed).
     * @param _count The maximum number of tasks to return.
     * @return An array of Task structs.
     */
    function listAgentTasks(uint256 _agentId, uint256 _startIndex, uint256 _count) external view returns (Task[] memory) {
        require(_agentId > 0 && _agentId <= _agentCounter, "Invalid agent ID");
        require(_count > 0, "Count must be greater than zero");

        uint256[] storage agentTaskIds = agentTasks[_agentId];
        uint256 totalAgentTasks = agentTaskIds.length;

        uint256 actualReturnCount = 0;
        if (_startIndex < totalAgentTasks) {
            actualReturnCount = totalAgentTasks - _startIndex;
            if (actualReturnCount > _count) {
                actualReturnCount = _count;
            }
        }

        Task[] memory agentTasksList = new Task[](actualReturnCount);
        for (uint256 i = 0; i < actualReturnCount; i++) {
            agentTasksList[i] = tasks[agentTaskIds[_startIndex + i]];
        }
        return agentTasksList;
    }

    // --- III. Reputation & Feedback ---

    /**
     * @dev Requester provides a rating and optional review for the agent after task completion.
     *      This directly impacts the agent's on-chain reputation.
     * @param _taskId The ID of the task being reviewed.
     * @param _rating The rating given (1-5, where 1 is poor and 5 is excellent).
     * @param _reviewCID IPFS CID for a detailed text review, if provided.
     */
    function submitRequesterReview(uint256 _taskId, uint8 _rating, string memory _reviewCID) external onlyRequester(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Completed, "Review can only be submitted for completed tasks");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");

        int256 reputationChange = 0;
        if (_rating >= 4) { // Positive review (4 or 5 stars)
            reputationChange = reputationParams.positiveReviewReputation;
        } else if (_rating <= 2) { // Negative review (1 or 2 stars)
            reputationChange = reputationParams.negativeReviewReputation;
        }
        // No change for 3-star reviews by default
        if (reputationChange != 0) {
            _updateAgentReputation(task.assignedAgentId, reputationChange, string(abi.encodePacked("Requester Review (Rating: ", Strings.toString(_rating), ")")));
        }

        emit ReviewSubmitted(_taskId, task.assignedAgentId, msg.sender, _rating, _reviewCID);
    }

    /**
     * @dev Agent provides a rating and optional feedback for the requester (e.g., clarity of task description).
     *      This does not directly impact requester's on-chain reputation in this version, but is logged for data.
     * @param _taskId The ID of the task being reviewed.
     * @param _rating The rating given (1-5, where 1 is poor and 5 is excellent).
     * @param _reviewCID IPFS CID for a detailed text review, if provided.
     */
    function submitAgentReview(uint256 _taskId, uint8 _rating, string memory _reviewCID) external onlyAssignedAgent(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Completed, "Review can only be submitted for completed tasks");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");

        // Agent reviews are logged but do not directly impact on-chain reputation of requester in this version.
        // Can be used for off-chain metrics or future requester reputation system.
        emit ReviewSubmitted(_taskId, task.assignedAgentId, msg.sender, _rating, _reviewCID);
    }

    /**
     * @dev Retrieves a log of reputation changes for a specific agent.
     * @param _agentId The ID of the agent.
     * @return An array of ReputationLog structs detailing the history of reputation changes.
     */
    function getAgentReputationHistory(uint256 _agentId) external view returns (ReputationLog[] memory) {
        require(_agentId > 0 && _agentId <= _agentCounter, "Invalid agent ID");
        return agentReputationHistory[_agentId];
    }

    // --- IV. Administrative & System Functions ---

    /**
     * @dev Sets the address of the external arbitration contract. This contract would handle
     *      dispute resolution when `disputeTaskOutcome` is called.
     * @param _arbitrationContract The address of the arbitration contract.
     */
    function setArbitrationContract(address _arbitrationContract) external onlyOwner {
        require(_arbitrationContract != address(0), "Arbitration contract address cannot be zero");
        arbitrationContract = _arbitrationContract;
    }

    /**
     * @dev Sets the address of the authorized proof verifier. This address is allowed to call
     *      `_receiveProofVerificationResult` after an off-chain proof verification process.
     * @param _proofVerifierAddress The address of the proof verifier.
     */
    function setProofVerifierAddress(address _proofVerifierAddress) external onlyOwner {
        require(_proofVerifierAddress != address(0), "Proof verifier address cannot be zero");
        proofVerifierAddress = _proofVerifierAddress;
    }

    /**
     * @dev Allows the contract owner to tune the parameters used in the reputation calculation algorithm.
     * @param _baseTaskReputation Base reputation points for general task completion.
     * @param _successfulProofReputation Additional points for successful proof verification.
     * @param _positiveReview Points awarded for a positive requester review.
     * @param _negativeReview Points deducted for a negative requester review.
     * @param _disputePenalty Points deducted if an agent loses a dispute.
     * @param _minAgentStake Minimum tokens required for an agent to register.
     * @param _deregCoolDown Time in seconds for deregistration cool-down.
     * @param _taskDispCoolDown Time in seconds for the task dispute window.
     */
    function setReputationAlgorithmParams(
        int256 _baseTaskReputation,
        int256 _successfulProofReputation,
        int256 _positiveReview,
        int256 _negativeReview,
        int256 _disputePenalty,
        uint256 _minAgentStake,
        uint256 _deregCoolDown,
        uint256 _taskDispCoolDown
    ) external onlyOwner {
        reputationParams = ReputationParams({
            baseTaskCompletionReputation: _baseTaskReputation,
            successfulProofVerificationReputation: _successfulProofReputation,
            positiveReviewReputation: _positiveReview,
            negativeReviewReputation: _negativeReview,
            disputePenaltyReputation: _disputePenalty,
            minAgentStakeAmount: _minAgentStake,
            deregistrationCoolDown: _deregCoolDown,
            taskDisputeCoolDown: _taskDispCoolDown
        });
    }

    /**
     * @dev Admin function to rescue accidentally sent ERC20 tokens (that are NOT the primary `rewardToken`)
     *      to the contract address. This prevents funds from being permanently locked.
     * @param _tokenAddress The address of the ERC20 token to rescue.
     * @param _amount The amount of tokens to rescue.
     */
    function rescueFunds(address _tokenAddress, uint256 _amount) external onlyOwner nonReentrant {
        require(_tokenAddress != address(rewardToken), "Cannot rescue the primary reward token via this function; it's managed by contract logic"); 
        IERC20 token = IERC20(_tokenAddress);
        require(token.transfer(msg.sender, _amount), "Token rescue failed");
    }
}
```