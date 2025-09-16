Okay, this is an exciting challenge! I'll design a Solidity smart contract called "ChronosNexus - Adaptive Resource & Reputation Orchestrator." This contract aims to create a dynamic ecosystem for task delegation, agent performance tracking, and decentralized achievement recognition, incorporating several advanced and trending concepts.

Here's a breakdown of the design:

*   **Agent System:** Users register as "Agents" with declared capabilities.
*   **Quest-Based Tasking:** Users can create "Quests" (tasks) with ERC20 token rewards, specifying required agent capabilities and deadlines.
*   **Dynamic Reputation:** Agents earn reputation for successful quest completion, lose it for failures or disputes, and experience time-based decay for inactivity. Higher reputation can unlock privileges or better quests.
*   **Skill Matching:** Quests are assigned to agents based on matching declared capabilities.
*   **Decentralized Dispute Resolution:** A mechanism for agents and quest creators to dispute outcomes, with a designated "Moderator" resolving the conflict based on submitted evidence (off-chain hashes).
*   **Achievement NFTs (Soulbound/Dynamic Concept):** Unique ERC-721 tokens are minted to agents upon reaching specific reputation milestones, acting as non-transferable (soulbound) verifiable credentials. The metadata of these NFTs could dynamically reflect the agent's ongoing achievements (though the dynamic part would be an off-chain metadata service querying the contract state).
*   **Time-Based Logic:** Quests can expire, and agent reputation can decay over time, managed by externally callable functions (e.g., by keeper bots).

---

## ChronosNexus - Adaptive Resource & Reputation Orchestrator

This smart contract creates a decentralized ecosystem for task delegation, agent reputation management, and achievement recognition. It allows users to register as "Agents", post "Quests" (tasks) with associated rewards, and track agent performance through a dynamic reputation system. Successful agents are rewarded with ERC20 tokens and unique "Achievement NFTs" upon reaching significant milestones. The contract includes features like skill matching, dispute resolution, and time-based reputation decay and quest expiration to foster an active and fair environment.

### I. Outline

1.  **Contract Configuration & Access Control:** Handles ownership, pausing mechanisms, and the crucial `moderator` role.
2.  **Data Structures:** Defines enums and structs for `Agent` profiles, `Quest` details, and their respective statuses.
3.  **Agent Management & Profile:** Functions for registration, updating agent information, and administrative status changes.
4.  **Quest Lifecycle Management:** Comprehensive functions covering quest creation, assignment, submission, verification, and cancellation.
5.  **Reputation & Reward System:** Manages the calculation, updates, and claiming of ERC20 rewards and the dynamic reputation scores for agents.
6.  **Dispute Resolution & Moderation:** Provides a structured process for disputing quest outcomes, submitting evidence, and resolution by the moderator.
7.  **Achievement NFT (ERC-721) Management:** Manages the minting of unique, non-transferable (soulbound) NFTs as verifiable accomplishments.
8.  **Time-Based Logic & Maintenance:** Functions that allow external parties (e.g., keeper bots) to trigger time-dependent state changes like quest expiration and reputation decay.
9.  **Utility & Fund Management:** General helper functions for contract balance and emergency withdrawals.

### II. Function Summary (26 Functions)

1.  `constructor`: Initializes the contract with an ERC20 reward token address and parameters for the internal Achievement NFT contract.
2.  `registerAgent`: Allows any address to register as an agent with a unique name and a list of hashed capabilities.
3.  `updateAgentProfile`: Enables a registered agent to modify their name or capabilities.
4.  `setAgentStatus`: (Owner/Moderator) Changes an agent's status (Active, Suspended, Deactivated) for administrative control.
5.  `getAgentDetails`: Retrieves comprehensive details for a given agent address.
6.  `getAgentReputation`: Returns the current reputation score of a specified agent.
7.  `createQuest`: Allows any user to post a new quest, specifying a title, description, ERC20 reward amount (transferred to contract as escrow), required capabilities, and a completion deadline.
8.  `assignQuest`: (Quest Creator) Assigns an `Open` quest to a specific, active agent, verifying the agent possesses all required capabilities.
9.  `submitQuestCompletion`: (Assigned Agent) Marks a quest as `CompletedPendingVerification` by the agent upon task completion.
10. `verifyQuestCompletion`: (Quest Creator) Verifies an agent's quest completion. If successful, triggers reward eligibility and reputation gain; if rejected, allows the agent to initiate a dispute.
11. `cancelQuest`: (Quest Creator) Cancels an `Open` or `Assigned` quest, returning the escrowed reward tokens to the creator.
12. `getQuestDetails`: Retrieves all details for a specific quest by its ID.
13. `initiateDispute`: (Agent/Creator) Initiates a dispute over a quest's outcome, providing a hash to off-chain evidence.
14. `submitDisputeEvidence`: (Agent/Creator) Allows parties involved in an active dispute to submit or update their evidence hashes.
15. `resolveDispute`: (Moderator) Resolves an active dispute, determining whether the agent or creator wins, adjusting reputation, and distributing/returning rewards accordingly.
16. `claimQuestReward`: (Assigned Agent) Claims the ERC20 reward for a quest that has been `Verified`.
17. `mintAchievementNFT`: (Internal) Mints a new unique Achievement NFT to an agent when they meet specific reputation milestones or other criteria.
18. `getAgentAchievementCount`: Returns the number of Achievement NFTs currently owned by a specific agent.
19. `expireQuest`: (Anyone) Marks a quest as `Expired` if its deadline has passed and it's not yet completed or verified, allowing for cleaner state management.
20. `decayReputation`: (Anyone) Periodically reduces an agent's reputation if they have been inactive for a defined interval, promoting continuous engagement.
21. `setModerator`: (Owner) Designates or changes the address of the contract's moderator.
22. `pause`: (Owner) Puts the contract into a paused state, halting most functions in emergencies.
23. `unpause`: (Owner) Resumes contract functionality from a paused state.
24. `withdrawERC20Rewards`: (Owner) Allows the owner to withdraw any non-`rewardToken` ERC20 tokens accidentally sent to the contract.
25. `withdrawNativeFunds`: (Owner) Allows the owner to withdraw any native currency (ETH) accidentally sent to the contract.
26. `getContractERC20Balance`: Returns the current balance of the designated `rewardToken` held by the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit uint256 arithmetic checks where needed, though 0.8.x handles overflow by default.

// =================================================================================
// ChronosNexus - Adaptive Resource & Reputation Orchestrator
// =================================================================================
// This smart contract creates a decentralized ecosystem for task delegation, agent
// reputation management, and achievement recognition. It allows users to register
// as "Agents", post "Quests" (tasks) with associated rewards, and track agent
// performance through a dynamic reputation system. Successful agents are rewarded
// with ERC20 tokens and unique "Achievement NFTs" upon reaching significant milestones.
// The contract includes features like skill matching, dispute resolution, and
// time-based reputation decay and quest expiration to foster an active and fair environment.

// =================================================================================
// I. Outline
// =================================================================================
// 1. Contract Configuration & Access Control: Ownable, Pausable, Moderator Role.
// 2. Data Structures: Defines structs for Agents, Quests, and enums for statuses.
// 3. Agent Management & Profile: Functions for registration, profile updates, and status changes.
// 4. Quest Lifecycle Management: Functions for creating, assigning, completing, verifying, and canceling quests.
// 5. Reputation & Reward System: Manages agent reputation scores and ERC20 reward distribution.
// 6. Dispute Resolution & Moderation: Mechanism for challenging quest outcomes and moderator intervention.
// 7. Achievement NFT (ERC-721) Management: Minting and tracking unique achievement tokens for agents.
// 8. Time-Based Logic & Maintenance: Functions to handle quest expiration and reputation decay.
// 9. Utility & Fund Management: General utilities, including fund withdrawals.

// =================================================================================
// II. Function Summary (At least 20 functions)
// =================================================================================
// 1.  constructor: Initializes the contract with an ERC20 reward token and Achievement NFT details.
// 2.  registerAgent: Allows a new user to register as an agent with a name and capabilities.
// 3.  updateAgentProfile: Allows an agent to update their registered name or capabilities.
// 4.  setAgentStatus: Owner/Moderator can activate, deactivate, or suspend an agent.
// 5.  getAgentDetails: Retrieves the full details for a specific agent.
// 6.  getAgentReputation: Returns the current reputation score of an agent.
// 7.  createQuest: Allows a user to post a new quest, specifying reward, skills, and deadline. ERC20 tokens are escrowed.
// 8.  assignQuest: Assigns an open quest to a registered agent, checking for skill match.
// 9.  submitQuestCompletion: Agent submits proof of quest completion.
// 10. verifyQuestCompletion: Quest creator (or moderator in dispute) verifies completion.
// 11. cancelQuest: Creator cancels an unassigned or uncompleted quest, releasing escrowed funds.
// 12. getQuestDetails: Retrieves the full details for a specific quest.
// 13. initiateDispute: An agent or creator can dispute a quest completion/rejection.
// 14. submitDisputeEvidence: Parties can submit a hash of off-chain evidence for a live dispute.
// 15. resolveDispute: Moderator resolves an active dispute, updating reputation and distributing rewards/penalties.
// 16. claimQuestReward: Agent claims their ERC20 reward after successful, verified quest completion.
// 17. mintAchievementNFT: Mints a unique Achievement NFT to an agent upon fulfilling specific criteria (e.g., reputation threshold).
// 18. getAgentAchievementCount: Returns the number of Achievement NFTs an agent holds.
// 19. expireQuest: Marks a quest as expired if its deadline passes. Can be called by anyone.
// 20. decayReputation: Periodically reduces agent reputation for inactivity (callable by anyone).
// 21. setModerator: Owner sets or changes the contract's moderator.
// 22. pause: Pauses contract functionality (emergency).
// 23. unpause: Unpauses contract functionality.
// 24. withdrawERC20Rewards: Owner withdraws any accidental ERC20 transfers or unclaimed fees from the contract.
// 25. withdrawNativeFunds: Owner withdraws any native currency from the contract.
// 26. getContractERC20Balance: Returns the current balance of the reward ERC20 token held by the contract.

// =================================================================================

contract ChronosNexus is Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256; // Explicitly use SafeMath for older versions or clarity, though 0.8.x provides overflow checks.

    // --- State Variables ---

    // Reward token for quests
    IERC20 public immutable rewardToken;
    
    // Reputation scoring constants
    // Reputation is stored as a scaled integer (e.g., 1000 = 1.0 reputation unit) to handle decimal values.
    uint256 public constant REPUTATION_MULTIPLIER = 1000;
    // How much reputation an agent gains for every 1 unit of `rewardToken` earned.
    uint256 public constant BASE_REPUTATION_GAIN_PER_UNIT_REWARD = 10; 
    
    // Achievement NFT constants
    uint256 public constant MIN_REPUTATION_FOR_NFT_TIER1 = 5000; // Example: 5 reputation units (5 * 1000)
    
    // Reputation decay constants
    uint256 public constant REPUTATION_DECAY_INTERVAL = 30 days; // How often reputation can decay for inactivity
    uint256 public constant REPUTATION_DECAY_AMOUNT = 100; // Amount of reputation to decay per interval (0.1 reputation unit)

    // Role-based access control
    address public moderator;

    // --- Data Structures ---

    enum AgentStatus { Active, Suspended, Deactivated }
    struct Agent {
        string name;
        bytes32[] capabilities; // Hashed representations of skills/capabilities (e.g., keccak256("web_dev"))
        uint256 reputation; // Scaled reputation score (e.g., 5000 for 5.0)
        AgentStatus status;
        uint256 registeredAt;
        uint256 lastActiveAt; // Timestamp of last significant interaction (quest completion/assignment/reputation decay)
    }

    mapping(address => Agent) public agents;
    mapping(address => bool) public isAgent; // Quick lookup if an address is a registered agent

    enum QuestStatus { Open, Assigned, CompletedPendingVerification, Verified, Disputed, Canceled, Expired }
    struct Quest {
        Counters.Counter id;
        address creator;
        string title;
        string description;
        address assignee; // Zero address if unassigned
        uint256 rewardAmount; // Amount of rewardToken escrowed for this quest
        bytes32[] requiredCapabilities;
        uint256 deadline;
        QuestStatus status;
        uint256 createdAt;
        uint256 completedAt;
        address disputeInitiator; // Address that initiated the dispute
        bytes32 creatorEvidenceHash; // Hash of off-chain evidence (e.g., IPFS CID) from creator
        bytes32 agentEvidenceHash; // Hash of off-chain evidence (e.g., IPFS CID) from agent
    }

    mapping(uint256 => Quest) public quests;
    Counters.Counter private _questIds; // Counter for unique quest IDs

    // Mapping for tracking achievement NFTs per agent (useful for multi-tier achievements)
    mapping(address => uint256) private _agentAchievementCount;

    // --- Events ---
    event AgentRegistered(address indexed agentAddress, string name, uint256 registeredAt);
    event AgentProfileUpdated(address indexed agentAddress, string newName, bytes32[] newCapabilities);
    event AgentStatusChanged(address indexed agentAddress, AgentStatus newStatus);
    event QuestCreated(uint256 indexed questId, address indexed creator, uint256 rewardAmount, uint256 deadline);
    event QuestAssigned(uint256 indexed questId, address indexed assignee);
    event QuestCompletionSubmitted(uint256 indexed questId, address indexed agent);
    event QuestVerified(uint256 indexed questId, address indexed verifier, uint256 rewardAmount);
    event QuestCanceled(uint256 indexed questId, address indexed creator);
    event QuestExpired(uint256 indexed questId);
    event ReputationUpdated(address indexed agentAddress, int256 change, uint256 newReputation);
    event DisputeInitiated(uint256 indexed questId, address indexed initiator);
    event DisputeResolved(uint256 indexed questId, address indexed resolver, bool agentWon);
    event AchievementNFTMinted(address indexed agentAddress, uint256 indexed tokenId, string tokenURI);
    event ModeratorSet(address indexed newModerator);

    // --- Custom Achievement NFT (ERC-721) ---
    // This is an internal contract, deployed by ChronosNexus, to manage achievement NFTs.
    ChronosAchievementNFT public achievementNFT;

    constructor(address _rewardToken, string memory _nftName, string memory _nftSymbol) Ownable(msg.sender) {
        require(_rewardToken != address(0), "Reward token cannot be zero address");
        rewardToken = IERC20(_rewardToken);
        // Deploy the Achievement NFT contract, making this ChronosNexus contract its minter.
        achievementNFT = new ChronosAchievementNFT(_nftName, _nftSymbol, address(this));
    }

    // --- Modifiers ---
    modifier onlyModerator() {
        require(msg.sender == moderator, "Only moderator can call this function");
        _;
    }

    modifier onlyAgent() {
        require(isAgent[msg.sender], "Caller is not a registered agent");
        require(agents[msg.sender].status == AgentStatus.Active, "Agent is not active");
        _;
    }

    modifier onlyQuestCreator(uint256 _questId) {
        require(quests[_questId].creator == msg.sender, "Only quest creator can perform this action");
        _;
    }

    // --- I. Contract Configuration & Access Control ---

    /**
     * @dev Sets or changes the moderator address. Only callable by the contract owner.
     * The moderator has specific permissions, e.g., resolving disputes, changing agent status.
     * @param _newModerator The address of the new moderator.
     */
    function setModerator(address _newModerator) external onlyOwner {
        require(_newModerator != address(0), "Moderator cannot be zero address");
        moderator = _newModerator;
        emit ModeratorSet(_newModerator);
    }

    /**
     * @dev Pauses the contract, preventing most state-changing operations.
     * Emergency function, callable only by the owner.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing operations to resume.
     * Callable only by the owner.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    // --- III. Agent Management & Profile (5 functions) ---

    /**
     * @dev Allows a new user to register as an agent.
     * Requires a unique name and optional capabilities (hashed strings/keywords).
     * @param _name The desired display name for the agent.
     * @param _capabilities An array of hashed strings representing agent skills/capabilities.
     */
    function registerAgent(string memory _name, bytes32[] memory _capabilities) external whenNotPaused {
        require(!isAgent[msg.sender], "Agent already registered");
        require(bytes(_name).length > 0, "Agent name cannot be empty");

        agents[msg.sender] = Agent({
            name: _name,
            capabilities: _capabilities,
            reputation: 0, // Start with 0 reputation
            status: AgentStatus.Active,
            registeredAt: block.timestamp,
            lastActiveAt: block.timestamp
        });
        isAgent[msg.sender] = true;

        emit AgentRegistered(msg.sender, _name, block.timestamp);
    }

    /**
     * @dev Allows an existing agent to update their profile (name and capabilities).
     * Only the registered agent can call this.
     * @param _newName The new display name for the agent.
     * @param _newCapabilities An updated array of hashed capabilities.
     */
    function updateAgentProfile(string memory _newName, bytes32[] memory _newCapabilities) external onlyAgent whenNotPaused {
        require(bytes(_newName).length > 0, "Agent name cannot be empty");

        Agent storage agent = agents[msg.sender];
        agent.name = _newName;
        agent.capabilities = _newCapabilities;
        agent.lastActiveAt = block.timestamp; // Mark as active

        emit AgentProfileUpdated(msg.sender, _newName, _newCapabilities);
    }

    /**
     * @dev Sets the status of an agent (Active, Suspended, Deactivated).
     * Callable only by the contract owner or moderator.
     * @param _agentAddress The address of the agent whose status is to be changed.
     * @param _newStatus The new status for the agent.
     */
    function setAgentStatus(address _agentAddress, AgentStatus _newStatus) external onlyModerator whenNotPaused {
        require(isAgent[_agentAddress], "Address is not a registered agent");
        require(agents[_agentAddress].status != _newStatus, "Agent already has this status");

        agents[_agentAddress].status = _newStatus;
        emit AgentStatusChanged(_agentAddress, _newStatus);
    }

    /**
     * @dev Retrieves the full details of a specific agent.
     * @param _agentAddress The address of the agent.
     * @return Agent struct details.
     */
    function getAgentDetails(address _agentAddress) external view returns (string memory name, bytes32[] memory capabilities, uint256 reputation, AgentStatus status, uint256 registeredAt, uint256 lastActiveAt) {
        require(isAgent[_agentAddress], "Address is not a registered agent");
        Agent storage agent = agents[_agentAddress];
        return (agent.name, agent.capabilities, agent.reputation, agent.status, agent.registeredAt, agent.lastActiveAt);
    }

    /**
     * @dev Retrieves the current reputation score of a specific agent.
     * @param _agentAddress The address of the agent.
     * @return The scaled reputation score.
     */
    function getAgentReputation(address _agentAddress) external view returns (uint256) {
        require(isAgent[_agentAddress], "Address is not a registered agent");
        return agents[_agentAddress].reputation;
    }

    // --- IV. Quest Lifecycle Management (6 functions) ---

    /**
     * @dev Allows a user to create a new quest.
     * Requires the reward amount to be transferred to the contract (escrow) and a deadline.
     * The quest creator does not need to be an agent.
     * @param _title The title of the quest.
     * @param _description The description of the quest.
     * @param _rewardAmount The amount of `rewardToken` to be paid to the agent.
     * @param _requiredCapabilities An array of hashed capabilities required for this quest.
     * @param _deadline The timestamp by which the quest must be completed.
     */
    function createQuest(
        string memory _title,
        string memory _description,
        uint256 _rewardAmount,
        bytes32[] memory _requiredCapabilities,
        uint256 _deadline
    ) external whenNotPaused returns (uint256) {
        require(bytes(_title).length > 0, "Quest title cannot be empty");
        require(_rewardAmount > 0, "Quest reward must be greater than zero");
        require(_deadline > block.timestamp, "Quest deadline must be in the future");
        
        // Transfer reward tokens to the contract (escrow)
        require(rewardToken.transferFrom(msg.sender, address(this), _rewardAmount), "ERC20 transfer failed. Ensure contract has allowance.");

        _questIds.increment();
        uint256 newQuestId = _questIds.current();

        quests[newQuestId] = Quest({
            id: Counters.toCounter(newQuestId),
            creator: msg.sender,
            title: _title,
            description: _description,
            assignee: address(0),
            rewardAmount: _rewardAmount,
            requiredCapabilities: _requiredCapabilities,
            deadline: _deadline,
            status: QuestStatus.Open,
            createdAt: block.timestamp,
            completedAt: 0,
            disputeInitiator: address(0),
            creatorEvidenceHash: bytes32(0),
            agentEvidenceHash: bytes32(0)
        });

        emit QuestCreated(newQuestId, msg.sender, _rewardAmount, _deadline);
        return newQuestId;
    }

    /**
     * @dev Assigns an open quest to a registered agent.
     * Can be called by the quest creator. Checks if the agent has required capabilities.
     * @param _questId The ID of the quest to assign.
     * @param _agentAddress The address of the agent to assign the quest to.
     */
    function assignQuest(uint256 _questId, address _agentAddress) external onlyQuestCreator(_questId) whenNotPaused {
        Quest storage quest = quests[_questId];
        require(quest.status == QuestStatus.Open, "Quest is not open for assignment");
        require(isAgent[_agentAddress], "Assignee is not a registered agent");
        require(agents[_agentAddress].status == AgentStatus.Active, "Assignee agent is not active");
        require(block.timestamp < quest.deadline, "Quest deadline has passed");

        // Capability matching: Check if the agent possesses all required capabilities
        Agent storage agent = agents[_agentAddress];
        for (uint i = 0; i < quest.requiredCapabilities.length; i++) {
            bool hasSkill = false;
            for (uint j = 0; j < agent.capabilities.length; j++) {
                if (quest.requiredCapabilities[i] == agent.capabilities[j]) {
                    hasSkill = true;
                    break;
                }
            }
            require(hasSkill, "Agent does not possess all required capabilities for this quest");
        }

        quest.assignee = _agentAddress;
        quest.status = QuestStatus.Assigned;
        agent.lastActiveAt = block.timestamp; // Update agent activity timestamp

        emit QuestAssigned(_questId, _agentAddress);
    }

    /**
     * @dev An assigned agent submits proof of quest completion.
     * This moves the quest to a pending verification state.
     * @param _questId The ID of the quest being completed.
     */
    function submitQuestCompletion(uint256 _questId) external onlyAgent whenNotPaused {
        Quest storage quest = quests[_questId];
        require(quest.assignee == msg.sender, "Caller is not the assignee of this quest");
        require(quest.status == QuestStatus.Assigned, "Quest is not in an assigned state");
        require(block.timestamp <= quest.deadline, "Quest completion submitted after deadline");

        quest.status = QuestStatus.CompletedPendingVerification;
        quest.completedAt = block.timestamp;
        agents[msg.sender].lastActiveAt = block.timestamp; // Update agent activity timestamp

        emit QuestCompletionSubmitted(_questId, msg.sender);
    }

    /**
     * @dev Quest creator verifies the completion of a quest.
     * If verified, rewards are enabled and agent reputation increases.
     * If rejected, the quest reverts to `Assigned` status, allowing the agent to re-submit or initiate a dispute.
     * @param _questId The ID of the quest to verify.
     * @param _isSuccessful True if completion is accepted, False if rejected.
     */
    function verifyQuestCompletion(uint256 _questId, bool _isSuccessful) external onlyQuestCreator(_questId) whenNotPaused {
        Quest storage quest = quests[_questId];
        require(quest.status == QuestStatus.CompletedPendingVerification, "Quest is not awaiting verification");
        require(quest.assignee != address(0), "Quest has no assignee");

        if (_isSuccessful) {
            quest.status = QuestStatus.Verified;
            // Calculate reputation gain based on reward amount. Scale for precision.
            _updateReputation(quest.assignee, int256(quest.rewardAmount.mul(BASE_REPUTATION_GAIN_PER_UNIT_REWARD)));
            _checkAndMintAchievement(quest.assignee); // Check for NFT milestones
            agents[quest.assignee].lastActiveAt = block.timestamp; // Update agent activity timestamp
            emit QuestVerified(_questId, msg.sender, quest.rewardAmount);
        } else {
            // Creator rejects, quest goes back to Assigned. Agent can then re-submit or initiate a dispute.
            quest.status = QuestStatus.Assigned;
            emit QuestCanceled(_questId, msg.sender); // Re-using event to indicate a form of closure, but not full cancellation.
        }
    }

    /**
     * @dev Cancels an unassigned or uncompleted quest.
     * Only the quest creator can cancel. Escrowed reward tokens are returned.
     * @param _questId The ID of the quest to cancel.
     */
    function cancelQuest(uint256 _questId) external onlyQuestCreator(_questId) whenNotPaused {
        Quest storage quest = quests[_questId];
        require(quest.status == QuestStatus.Open || quest.status == QuestStatus.Assigned, "Quest cannot be canceled in its current state");

        // Refund escrowed tokens to the creator
        require(rewardToken.transfer(quest.creator, quest.rewardAmount), "Reward refund failed");

        quest.status = QuestStatus.Canceled;
        quest.rewardAmount = 0; // Mark reward as processed
        emit QuestCanceled(_questId, msg.sender);
    }

    /**
     * @dev Retrieves the full details of a specific quest.
     * @param _questId The ID of the quest.
     * @return Quest struct details.
     */
    function getQuestDetails(uint256 _questId) external view returns (
        uint256 id, address creator, string memory title, string memory description,
        address assignee, uint256 rewardAmount, bytes32[] memory requiredCapabilities,
        uint256 deadline, QuestStatus status, uint256 createdAt, uint256 completedAt,
        address disputeInitiator, bytes32 creatorEvidenceHash, bytes32 agentEvidenceHash
    ) {
        Quest storage quest = quests[_questId];
        require(quest.id.current() == _questId, "Quest does not exist");
        return (
            quest.id.current(), quest.creator, quest.title, quest.description,
            quest.assignee, quest.rewardAmount, quest.requiredCapabilities,
            quest.deadline, quest.status, quest.createdAt, quest.completedAt,
            quest.disputeInitiator, quest.creatorEvidenceHash, quest.agentEvidenceHash
        );
    }

    // --- V. Reputation & Reward System (2 functions directly callable, others internal) ---

    /**
     * @dev Allows an agent to claim their reward for a successfully verified quest.
     * @param _questId The ID of the quest for which to claim the reward.
     */
    function claimQuestReward(uint256 _questId) external onlyAgent whenNotPaused {
        Quest storage quest = quests[_questId];
        require(quest.assignee == msg.sender, "Caller is not the assignee of this quest");
        require(quest.status == QuestStatus.Verified, "Quest is not in a verified state");
        require(quest.rewardAmount > 0, "No reward to claim or reward already claimed");

        // Transfer reward tokens from contract to agent
        uint256 rewardToTransfer = quest.rewardAmount;
        quest.rewardAmount = 0; // Mark reward as claimed
        require(rewardToken.transfer(msg.sender, rewardToTransfer), "Reward transfer failed");
        
        agents[msg.sender].lastActiveAt = block.timestamp; // Update agent activity timestamp

        // Emit QuestVerified with 0 reward to signify claimed status
        emit QuestVerified(_questId, msg.sender, 0); 
    }

    /**
     * @dev Internal function to update an agent's reputation.
     * Can be positive or negative. Ensures reputation doesn't drop below zero.
     * @param _agentAddress The address of the agent.
     * @param _reputationChange The amount of reputation to add (positive) or subtract (negative).
     */
    function _updateReputation(address _agentAddress, int256 _reputationChange) internal {
        require(isAgent[_agentAddress], "Address is not a registered agent");

        Agent storage agent = agents[_agentAddress];
        int256 currentReputation = int256(agent.reputation); // Cast to int256 for signed arithmetic
        int256 newReputation = currentReputation + _reputationChange;

        // Ensure reputation doesn't go below zero
        if (newReputation < 0) {
            newReputation = 0;
        }
        agent.reputation = uint256(newReputation);
        emit ReputationUpdated(_agentAddress, _reputationChange, agent.reputation);
    }

    // --- VI. Dispute Resolution & Moderation (3 functions) ---

    /**
     * @dev Allows an agent (if rejected) or creator (if agent didn't perform) to initiate a dispute.
     * Requires the quest to be in `Assigned` or `CompletedPendingVerification` status.
     * @param _questId The ID of the quest to dispute.
     * @param _evidenceHash A hash (e.g., IPFS CID) pointing to off-chain evidence relevant to the dispute.
     */
    function initiateDispute(uint256 _questId, bytes32 _evidenceHash) external whenNotPaused {
        Quest storage quest = quests[_questId];
        require(quest.status != QuestStatus.Verified && quest.status != QuestStatus.Canceled && quest.status != QuestStatus.Expired && quest.status != QuestStatus.Disputed, "Quest cannot be disputed in its current state or already in dispute");
        require(_evidenceHash != bytes32(0), "Evidence hash cannot be empty");

        if (msg.sender == quest.assignee) {
            require(quest.status == QuestStatus.Assigned || quest.status == QuestStatus.CompletedPendingVerification, "Agent can only dispute if assigned or pending verification");
            quest.agentEvidenceHash = _evidenceHash;
        } else if (msg.sender == quest.creator) {
            require(quest.status == QuestStatus.Assigned || quest.status == QuestStatus.CompletedPendingVerification, "Creator can only dispute if assigned or pending verification");
            quest.creatorEvidenceHash = _evidenceHash;
        } else {
            revert("Only agent or creator can initiate dispute for this quest");
        }

        quest.disputeInitiator = msg.sender;
        quest.status = QuestStatus.Disputed;
        emit DisputeInitiated(_questId, msg.sender);
    }

    /**
     * @dev Allows either party in a dispute to submit their evidence hash.
     * Can only be called if a dispute is active and the sender is a party.
     * @param _questId The ID of the disputed quest.
     * @param _evidenceHash The hash of the off-chain evidence (e.g., IPFS CID).
     */
    function submitDisputeEvidence(uint256 _questId, bytes32 _evidenceHash) external whenNotPaused {
        Quest storage quest = quests[_questId];
        require(quest.status == QuestStatus.Disputed, "Quest is not in dispute");
        require(_evidenceHash != bytes32(0), "Evidence hash cannot be empty");

        if (msg.sender == quest.creator) {
            quest.creatorEvidenceHash = _evidenceHash;
        } else if (msg.sender == quest.assignee) {
            quest.agentEvidenceHash = _evidenceHash;
        } else {
            revert("Only quest creator or assignee can submit evidence for this dispute");
        }
    }

    /**
     * @dev Moderator resolves an active dispute, determining the outcome.
     * Updates reputation and distributes/returns rewards accordingly.
     * @param _questId The ID of the quest in dispute.
     * @param _agentWon True if the agent's claim is upheld, False if the creator's.
     * @param _reputationPenaltyAgent Amount of reputation to penalize agent if they lose (scaled).
     * @param _reputationPenaltyCreator Amount of reputation to penalize creator if they lose (scaled).
     */
    function resolveDispute(uint256 _questId, bool _agentWon, uint256 _reputationPenaltyAgent, uint256 _reputationPenaltyCreator) external onlyModerator whenNotPaused {
        Quest storage quest = quests[_questId];
        require(quest.status == QuestStatus.Disputed, "Quest is not in dispute");
        require(quest.assignee != address(0), "Disputed quest must have an assignee");
        require(quest.rewardAmount > 0, "Reward already claimed or zero, cannot resolve dispute involving rewards");

        address agentAddress = quest.assignee;
        address creatorAddress = quest.creator;

        if (_agentWon) {
            // Agent wins: Agent gets reputation, quest status verified. Reward is claimed via `claimQuestReward`.
            quest.status = QuestStatus.Verified;
            _updateReputation(agentAddress, int256(quest.rewardAmount.mul(BASE_REPUTATION_GAIN_PER_UNIT_REWARD))); // Agent gains reputation
            
            // If the creator also happens to be an agent and loses, they get penalized.
            if (_reputationPenaltyCreator > 0 && isAgent[creatorAddress]) { 
                _updateReputation(creatorAddress, -int256(_reputationPenaltyCreator));
            }
            _checkAndMintAchievement(agentAddress); // Check for NFT milestones
            agents[agentAddress].lastActiveAt = block.timestamp; // Update agent activity timestamp
        } else {
            // Creator wins: Escrowed reward is returned to creator, agent loses reputation.
            quest.status = QuestStatus.Canceled; // Or a new status like `RejectedPermanently`
            require(rewardToken.transfer(creatorAddress, quest.rewardAmount), "Dispute reward return to creator failed");
            quest.rewardAmount = 0; // Mark as processed/returned
            _updateReputation(agentAddress, -int256(_reputationPenaltyAgent)); // Agent loses reputation
            agents[agentAddress].lastActiveAt = block.timestamp; // Still an interaction for the agent
        }
        
        // Clear dispute-related fields regardless of outcome
        quest.disputeInitiator = address(0);
        quest.creatorEvidenceHash = bytes32(0);
        quest.agentEvidenceHash = bytes32(0);

        emit DisputeResolved(_questId, msg.sender, _agentWon);
    }

    // --- VII. Achievement NFT (ERC-721) Management (2 functions) ---

    /**
     * @dev Internal function to check if an agent qualifies for a new achievement NFT and mints it.
     * This can be called upon significant events, like reaching a reputation threshold or completing N quests.
     * @param _agentAddress The address of the agent to check.
     */
    function _checkAndMintAchievement(address _agentAddress) internal {
        Agent storage agent = agents[_agentAddress];
        uint256 currentReputation = agent.reputation;
        uint256 agentAchievementCount = _agentAchievementCount[_agentAddress];

        // Example: Mint an NFT for reaching Tier 1 reputation
        if (currentReputation >= MIN_REPUTATION_FOR_NFT_TIER1 && agentAchievementCount == 0) {
            _agentAchievementCount[_agentAddress]++;
            // Placeholder URI. In a real dApp, this would resolve to dynamic metadata.
            string memory tokenURI = string(abi.encodePacked("ipfs://QmT...Tier1_", Strings.toString(_agentAchievementCount[_agentAddress])));
            achievementNFT.mint(_agentAddress, _agentAchievementCount[_agentAddress], tokenURI); 
            emit AchievementNFTMinted(_agentAddress, _agentAchievementCount[_agentAddress], tokenURI);
        }
        // Additional tiers/conditions for more NFTs could be added here (e.g., if agentAchievementCount == 1 and new reputation tier met)
    }

    /**
     * @dev Returns the number of achievement NFTs an agent currently holds (minted by this contract).
     * @param _agentAddress The address of the agent.
     * @return The count of achievement NFTs.
     */
    function getAgentAchievementCount(address _agentAddress) external view returns (uint256) {
        return _agentAchievementCount[_agentAddress];
    }

    // --- VIII. Time-Based Logic & Maintenance (2 functions) ---

    /**
     * @dev Marks a quest as expired if its deadline has passed and it's not completed/verified.
     * Can be called by anyone (e.g., a keeper bot) to keep the state clean.
     * Funds remain in escrow, allowing creator to manually cancel if needed or for the moderator to intervene.
     * @param _questId The ID of the quest to check.
     */
    function expireQuest(uint256 _questId) external whenNotPaused {
        Quest storage quest = quests[_questId];
        require(quest.status != QuestStatus.Verified && quest.status != QuestStatus.Canceled && quest.status != QuestStatus.Expired, "Quest is not in an open/assigned/pending state or already expired/canceled");
        require(block.timestamp > quest.deadline, "Quest deadline has not passed yet");

        quest.status = QuestStatus.Expired;
        emit QuestExpired(_questId);
    }

    /**
     * @dev Periodically reduces an agent's reputation for inactivity.
     * Can be called by anyone (e.g., a keeper bot) but only takes effect if the
     * `REPUTATION_DECAY_INTERVAL` has passed since the agent's `lastActiveAt`.
     * @param _agentAddress The address of the agent whose reputation might decay.
     */
    function decayReputation(address _agentAddress) external whenNotPaused {
        require(isAgent[_agentAddress], "Address is not a registered agent");
        Agent storage agent = agents[_agentAddress];
        require(agent.status == AgentStatus.Active, "Agent is not active, no decay needed");
        require(block.timestamp > agent.lastActiveAt + REPUTATION_DECAY_INTERVAL, "Reputation decay interval has not passed for this agent");
        require(agent.reputation > 0, "Agent already has 0 reputation, no decay needed");

        // Calculate actual decay amount, ensuring reputation doesn't drop below zero
        uint256 decayAmount = REPUTATION_DECAY_AMOUNT;
        if (agent.reputation < decayAmount) {
            decayAmount = agent.reputation; // Decay only what's left
        }

        _updateReputation(_agentAddress, -int256(decayAmount));
        agent.lastActiveAt = block.timestamp; // Reset lastActiveAt to prevent immediate re-decay until next interval
    }

    // --- IX. Utility & Fund Management (3 functions) ---

    /**
     * @dev Allows the owner to withdraw any ERC20 tokens sent to the contract
     * that are not part of active quest rewards (e.g., accidental transfers).
     * @param _token The address of the ERC20 token to withdraw.
     * @param _amount The amount of tokens to withdraw.
     */
    function withdrawERC20Rewards(address _token, uint256 _amount) external onlyOwner {
        require(_token != address(rewardToken), "Cannot withdraw the primary reward token through this function");
        IERC20(_token).transfer(owner(), _amount);
    }

    /**
     * @dev Allows the owner to withdraw any native currency (ETH) accidentally
     * sent to the contract.
     * @param _amount The amount of native currency to withdraw.
     */
    function withdrawNativeFunds(uint256 _amount) external onlyOwner {
        require(address(this).balance >= _amount, "Insufficient native balance in contract");
        payable(owner()).transfer(_amount);
    }

    /**
     * @dev Returns the current balance of the main reward ERC20 token held by the contract.
     * @return The balance of `rewardToken`.
     */
    function getContractERC20Balance() external view returns (uint256) {
        return rewardToken.balanceOf(address(this));
    }

    // --- Internal Achievement NFT Contract ---
    // This is a minimal ERC-721 contract specifically for ChronosNexus achievements.
    // It is deployed by ChronosNexus and its minting function is restricted to ChronosNexus.
    // By default, tokens are non-transferable (soulbound) to signify achievements.
    contract ChronosAchievementNFT is ERC721, Ownable {
        address public minterContract; // The address of the ChronosNexus contract

        Counters.Counter private _tokenIdCounter;

        constructor(string memory name, string memory symbol, address _minterContract) ERC721(name, symbol) Ownable(msg.sender) {
            minterContract = _minterContract;
        }

        // Modifier to restrict minting only to the ChronosNexus contract
        modifier onlyMinterContract() {
            require(msg.sender == minterContract, "Only the designated minter contract can mint NFTs");
            _;
        }

        /**
         * @dev Mints a new achievement NFT to an agent.
         * Only callable by the `minterContract` (ChronosNexus itself).
         * @param to The address of the recipient agent.
         * @param tier The tier of the achievement (can be used in tokenURI generation or logic).
         * @param tokenURI The URI for the NFT's metadata (e.g., IPFS CID), potentially dynamic.
         * @return The ID of the newly minted token.
         */
        function mint(address to, uint256 tier, string memory tokenURI) external onlyMinterContract returns (uint256) {
            _tokenIdCounter.increment();
            uint256 newTokenId = _tokenIdCounter.current();
            _safeMint(to, newTokenId);
            _setTokenURI(newTokenId, tokenURI); // Set the metadata URI for the new token

            // Optionally store tier if needed for on-chain queries, currently just in URI
            return newTokenId;
        }

        /**
         * @dev Overrides ERC721's internal transfer logic to make NFTs non-transferable.
         * This creates "soulbound" tokens, meaning they cannot be traded by users.
         * Minting (from address(0)) and burning (to address(0)) are still permitted.
         */
        function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
            if (from != address(0) && to != address(0)) { // Allow minting (from 0 address) and burning (to 0 address)
                revert("Achievement NFTs are non-transferable by users");
            }
            super._beforeTokenTransfer(from, to, tokenId);
        }

        /**
         * @dev Allows the `Ownable` contract owner to transfer an achievement NFT.
         * This serves as an emergency/administrative override for recovery or special cases,
         * balancing the "soulbound" concept with essential control.
         */
        function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyOwner {
            _transfer(from, to, tokenId);
        }

        /**
         * @dev Allows the `Ownable` contract owner to safely transfer an achievement NFT.
         * Administrative override similar to `transferFrom`.
         */
        function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyOwner {
            safeTransferFrom(from, to, tokenId, "");
        }

        /**
         * @dev Allows the `Ownable` contract owner to safely transfer an achievement NFT with data.
         * Administrative override similar to `transferFrom`.
         */
        function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override(ERC721, IERC721) onlyOwner {
            _safeTransfer(from, to, tokenId, data);
        }
    }
}
```