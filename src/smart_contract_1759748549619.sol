Here's a smart contract in Solidity called "AetherForge," incorporating advanced concepts like dynamic NFTs, AI oracle integration for objective evaluation, skill-based questing, and an autonomous agent system. It aims to be creative, trendy, and avoid duplicating existing open-source projects by combining these elements in a unique protocol.

---

**AetherForge - Decentralized Adaptive Protocol for Skill-Based Micro-Tasks and AI-Enhanced Agent Orchestration**

This smart contract implements a novel decentralized protocol, AetherForge, designed for the creation, management, and completion of skill-gated micro-tasks ("Quests"). It integrates a robust reputation and skill-tree system (using non-transferable skill points akin to Soulbound Tokens), dynamic Agent NFTs whose traits evolve based on performance, and leverages an AI oracle for objective task evaluation and adaptive difficulty adjustment. Users can propose quests, and other users or their deployed Agents can accept and complete these quests, earning rewards and enhancing their on-chain profiles.

---

**Outline:**

*   **I. Core Infrastructure & Management:** Basic contract administration, pausing mechanisms, and ownership transfer.
*   **II. Skill & Reputation System:** Functions for defining new skills, managing user and agent skill points, and tracking overall reputation.
*   **III. Quest Lifecycle Management:** Comprehensive functions for creating, accepting, submitting, evaluating, and finalizing quests.
*   **IV. Agent Management (Dynamic NFTs):** ERC721-compliant functions for minting, assigning skills, configuring, and managing unique Agent NFTs that can autonomously perform quests.
*   **V. AI Oracle Integration:** Mechanisms for interfacing with an external AI decision oracle to obtain objective evaluations and potentially dynamic parameters.
*   **VI. Dispute Resolution:** A basic system for challenging quest outcomes.
*   **VII. Financials & Withdrawals:** Functions related to managing quest fees and reward distribution.
*   **VIII. Query & View Functions:** Read-only functions to retrieve contract state and user/agent data.

---

**Function Summary:**

**I. Core Infrastructure & Management**
1.  `constructor()`: Initializes the contract with an owner and an AI oracle address, setting up the foundational parameters.
2.  `setAIDecisionOracle(address _oracleAddress)`: Allows the contract owner to update the address of the trusted AI Decision Oracle.
3.  `pauseContract()`: The owner can pause critical contract functions in emergencies, preventing new quests, submissions, or agent actions.
4.  `unpauseContract()`: The owner can resume contract operations after a pause.
5.  `transferOwnership(address newOwner)`: Transfers ownership of the contract to a new address.
6.  `setQuestCreationFee(uint256 _fee)`: Sets the fee required to create a new quest.
7.  `setCommitmentStakePercentage(uint256 _percentage)`: Defines the percentage of the quest reward that must be staked by an executor when accepting a quest.

**II. Skill & Reputation System**
8.  `registerSkill(string calldata _skillName)`: Allows the owner or governance committee to define and register a new skill type available within the AetherForge ecosystem.
9.  `getUserSkillPoints(address _user, uint256 _skillId)`: Retrieves the skill points accumulated by a specific user for a given skill.
10. `getAgentSkillPoints(uint256 _agentId, uint256 _skillId)`: Retrieves the skill points held by a specific Agent NFT for a given skill.
11. `getUserReputation(address _user)`: Returns the overall reputation score of a user, aggregating their performance across quests.
12. `getAgentPerformanceMetrics(uint256 _agentId)`: Provides a comprehensive view of an Agent NFT's performance history, including success rate and average evaluation scores.

**III. Quest Lifecycle Management**
13. `createQuest(string calldata _title, string calldata _descriptionURI, uint256 _rewardAmount, uint256[] calldata _requiredSkillIds, uint256[] calldata _requiredSkillLevels, uint256 _deadline)`: Allows a user to propose a new quest, specifying its details, required skills and their minimum levels, reward, and completion deadline. Requires payment of a `questCreationFee`.
14. `acceptQuest(uint256 _questId)`: Allows a qualified user or an Agent (implicitly via the user controlling it) to accept an available quest. Requires staking a `commitmentStakePercentage` of the reward.
15. `submitQuestCompletion(uint256 _questId, string calldata _proofURI)`: The executor (user or agent owner) submits proof of quest completion, typically an IPFS hash pointing to relevant data.
16. `requestQuestEvaluation(uint256 _questId)`: Notifies the AI Oracle that a quest is ready for evaluation. This function typically triggers the oracle's off-chain process.
17. `finalizeQuest(uint256 _questId, uint256 _aiEvaluationScore)`: (Callable by AI Oracle) Processes the final outcome of a quest based on the AI's objective evaluation score, distributing rewards, updating skills/reputation, and resolving stakes.

**IV. Agent Management (Dynamic NFTs)**
18. `mintAgentNFT(string calldata _name)`: Allows a user to mint a new unique Agent NFT, which can then be assigned skills and deployed for questing.
19. `assignSkillsToAgent(uint256 _agentId, uint256[] calldata _skillIds, uint256[] calldata _skillPoints)`: The owner of an Agent NFT can allocate initial or earned skill points to specific skills for their agent. This dynamically updates the Agent's on-chain traits.
20. `setAgentAutonomousMode(uint256 _agentId, bool _isEnabled)`: Toggles whether an Agent NFT can autonomously accept quests that match its configured parameters and skills (requires external bot integration).
21. `updateAgentParameters(uint256 _agentId, uint256 _maxDifficulty, uint256[] calldata _preferredSkillIds)`: The owner configures their Agent NFT's operational preferences, such as the maximum quest difficulty it should attempt and its preferred skill types for autonomous acceptance.
22. `delegateAgentControl(uint256 _agentId, address _delegatee, uint256 _duration)`: Allows an Agent NFT owner to temporarily delegate control over their agent to another address for a specified duration, enabling shared management or lending.

**V. Dispute Resolution**
23. `disputeQuestOutcome(uint256 _questId)`: A quest proposer or executor can initiate a dispute if they disagree with the AI's evaluation or the quest's final status. This would trigger a governance review.
24. `resolveDispute(uint256 _questId, bool _proposerWins, int256 _adjustedScore)`: (Callable by Governance) Function to manually resolve a disputed quest, potentially overriding the AI score and adjusting rewards/penalties.

**VI. Financials & Withdrawals**
25. `withdrawQuestFees()`: Allows the contract owner to withdraw accumulated quest creation fees.
26. `reclaimStakedCommitment(uint256 _questId)`: Allows an executor to reclaim their staked commitment if a quest is cancelled, times out without completion, or if they successfully dispute an unjust penalty.

**VII. Query & View Functions**
27. `getQuestDetails(uint256 _questId)`: Retrieves all the detailed information about a specific quest.
28. `getAvailableQuests(uint256 _startIndex, uint256 _count)`: Returns a paginated list of quests that are currently open for acceptance.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// --- Interfaces ---

/// @title IAIDecisionOracle
/// @notice Interface for an external AI oracle that provides objective evaluation scores for quests.
interface IAIDecisionOracle {
    function finalizeQuest(uint256 _questId, uint256 _aiEvaluationScore) external;
}

/// @title IAgentNFT
/// @notice Interface for the Agent NFT specific functions, used for type hinting.
interface IAgentNFT is IERC721 {
    function mint(address to, string memory name) external returns (uint256);
    function updateAgentSkills(uint256 agentId, uint256 skillId, uint256 points) external;
    function getAgentSkill(uint256 agentId, uint256 skillId) external view returns (uint256);
    function getAgentPerformance(uint256 agentId) external view returns (uint256 successRate, uint256 avgScore);
    function updateAgentPerformance(uint256 agentId, bool success, uint256 score) external;
    function setAutonomousMode(uint256 agentId, bool enabled) external;
    function updateParameters(uint256 agentId, uint256 maxDifficulty, uint256[] memory preferredSkillIds) external;
    function getAgentParameters(uint256 agentId) external view returns (uint256 maxDifficulty, uint256[] memory preferredSkillIds, bool autonomousMode);
}


// --- Main Contract ---

contract AetherForge is Ownable, Pausable {
    using Counters for Counters.Counter;

    // --- State Variables ---

    IAIDecisionOracle public aiDecisionOracle;
    address public governanceCommittee; // Could be a multi-sig or another DAO contract

    uint256 public questCreationFee = 0.01 ether; // Fee for creating a quest
    uint256 public commitmentStakePercentage = 10; // 10% of reward must be staked by executor

    Counters.Counter private _questIds;
    Counters.Counter private _skillIds;
    Counters.Counter private _agentTokenIds;

    // --- Enums & Structs ---

    enum QuestStatus {
        Open,
        Accepted,
        Submitted,
        Evaluating,
        CompletedSuccess,
        CompletedFailure,
        Disputed,
        Cancelled
    }

    struct Skill {
        uint256 id;
        string name;
        bool registered;
    }

    struct Quest {
        uint256 id;
        address proposer;
        address executor; // Can be a user or implicitly the owner of an Agent NFT
        uint256 agentId; // 0 if user-executed
        string title;
        string descriptionURI; // IPFS hash or URL for quest details
        uint256 rewardAmount;
        uint256 stakedCommitment; // Amount staked by executor
        uint256 deadline;
        QuestStatus status;
        uint256[] requiredSkillIds;
        uint256[] requiredSkillLevels;
        uint256 aiEvaluationScore; // Score from AI oracle (0-100)
        bool disputed;
    }

    struct Dispute {
        uint256 questId;
        address partyInitiating;
        uint256 timestamp;
        bool resolved;
        bool proposerWins; // Result of governance resolution
        int256 adjustedScore; // Adjusted score if dispute changes AI evaluation
    }

    // --- Mappings ---

    mapping(uint256 => Quest) public quests;
    mapping(uint256 => Skill) public skills;
    mapping(uint256 => address[]) public questsBySkill; // For filtering available quests by skill
    mapping(address => mapping(uint256 => uint256)) public userSkillPoints; // user => skillId => points
    mapping(address => uint256) public userReputation; // user => reputation score
    mapping(address => uint256[]) public userQuests; // user => list of quest IDs they proposed/executed
    mapping(uint256 => uint256[]) public availableQuests; // skillId => list of open quest IDs
    mapping(uint256 => Dispute) public questDisputes; // questId => dispute details
    mapping(uint256 => uint256) private _skillIdCounter; // Helper for availableQuests pagination

    // --- Events ---

    event AIDecisionOracleUpdated(address indexed newOracle);
    event QuestCreationFeeUpdated(uint256 newFee);
    event CommitmentStakePercentageUpdated(uint256 newPercentage);
    event SkillRegistered(uint256 indexed skillId, string skillName);
    event QuestCreated(uint256 indexed questId, address indexed proposer, uint256 rewardAmount, uint256 deadline);
    event QuestAccepted(uint256 indexed questId, address indexed executor, uint256 agentId, uint256 stakedCommitment);
    event QuestCompletionSubmitted(uint256 indexed questId, address indexed submitter, string proofURI);
    event QuestEvaluationRequested(uint256 indexed questId);
    event QuestFinalized(uint256 indexed questId, QuestStatus newStatus, uint256 aiEvaluationScore, uint256 actualReward);
    event AgentMinted(uint256 indexed agentId, address indexed owner, string name);
    event AgentSkillsAssigned(uint256 indexed agentId, uint256 indexed skillId, uint256 points);
    event AgentAutonomousModeToggled(uint256 indexed agentId, bool isEnabled);
    event AgentParametersUpdated(uint256 indexed agentId, uint256 maxDifficulty);
    event AgentControlDelegated(uint256 indexed agentId, address indexed delegatee, uint256 duration);
    event QuestDisputed(uint256 indexed questId, address indexed party);
    event DisputeResolved(uint256 indexed questId, bool proposerWins, int256 adjustedScore);
    event FeesWithdrawn(address indexed to, uint256 amount);

    // --- Modifiers ---

    modifier onlyAICallback() {
        require(msg.sender == address(aiDecisionOracle), "AetherForge: Only AI Oracle can call this function");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == governanceCommittee || msg.sender == owner(), "AetherForge: Only Governance or Owner can call this function");
        _;
    }

    // --- Constructor ---

    constructor(address _aiDecisionOracleAddress, address _governanceCommittee) Ownable(msg.sender) Pausable() {
        require(_aiDecisionOracleAddress != address(0), "AetherForge: AI Oracle address cannot be zero");
        aiDecisionOracle = IAIDecisionOracle(_aiDecisionOracleAddress);
        governanceCommittee = _governanceCommittee;
    }

    // --- I. Core Infrastructure & Management ---

    /// @notice Sets the address of the trusted AI Decision Oracle.
    /// @param _oracleAddress The new address for the AI Oracle.
    function setAIDecisionOracle(address _oracleAddress) external onlyOwner {
        require(_oracleAddress != address(0), "AetherForge: AI Oracle address cannot be zero");
        aiDecisionOracle = IAIDecisionOracle(_oracleAddress);
        emit AIDecisionOracleUpdated(_oracleAddress);
    }

    /// @notice Pauses critical contract functions in emergencies.
    function pauseContract() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses contract operations after an emergency pause.
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /// @notice Transfers ownership of the contract to a new address.
    /// @param newOwner The address of the new owner.
    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
    }

    /// @notice Sets the fee required to create a new quest.
    /// @param _fee The new quest creation fee in wei.
    function setQuestCreationFee(uint256 _fee) external onlyOwner {
        questCreationFee = _fee;
        emit QuestCreationFeeUpdated(_fee);
    }

    /// @notice Defines the percentage of the quest reward that must be staked by an executor when accepting a quest.
    /// @param _percentage The new percentage (e.g., 10 for 10%).
    function setCommitmentStakePercentage(uint256 _percentage) external onlyOwner {
        require(_percentage <= 100, "AetherForge: Percentage cannot exceed 100");
        commitmentStakePercentage = _percentage;
        emit CommitmentStakePercentageUpdated(_percentage);
    }

    // --- II. Skill & Reputation System ---

    /// @notice Allows the owner or governance committee to define and register a new skill type.
    /// @param _skillName The name of the skill.
    /// @return The ID of the newly registered skill.
    function registerSkill(string calldata _skillName) external onlyGovernance returns (uint256) {
        _skillIds.increment();
        uint256 newSkillId = _skillIds.current();
        skills[newSkillId] = Skill({
            id: newSkillId,
            name: _skillName,
            registered: true
        });
        emit SkillRegistered(newSkillId, _skillName);
        return newSkillId;
    }

    /// @notice Retrieves the skill points accumulated by a specific user for a given skill.
    /// @param _user The address of the user.
    /// @param _skillId The ID of the skill.
    /// @return The skill points of the user for that skill.
    function getUserSkillPoints(address _user, uint256 _skillId) external view returns (uint256) {
        require(skills[_skillId].registered, "AetherForge: Skill not registered");
        return userSkillPoints[_user][_skillId];
    }

    /// @notice Retrieves the skill points held by a specific Agent NFT for a given skill.
    /// @param _agentId The ID of the Agent NFT.
    /// @param _skillId The ID of the skill.
    /// @return The skill points of the agent for that skill.
    function getAgentSkillPoints(uint256 _agentId, uint256 _skillId) external view returns (uint256) {
        require(skills[_skillId].registered, "AetherForge: Skill not registered");
        // Assumes AgentNFT contract handles its own skill storage and provides a getter
        return IAgentNFT(address(this)).getAgentSkill(_agentId, _skillId);
    }

    /// @notice Returns the overall reputation score of a user.
    /// @param _user The address of the user.
    /// @return The overall reputation score.
    function getUserReputation(address _user) external view returns (uint256) {
        return userReputation[_user];
    }

    /// @notice Provides a comprehensive view of an Agent NFT's performance history.
    /// @param _agentId The ID of the Agent NFT.
    /// @return successRate The success rate percentage of the agent.
    /// @return avgScore The average evaluation score received by the agent.
    function getAgentPerformanceMetrics(uint256 _agentId) external view returns (uint256 successRate, uint256 avgScore) {
        // Assumes AgentNFT contract handles its own performance metrics
        return IAgentNFT(address(this)).getAgentPerformance(_agentId);
    }

    // --- III. Quest Lifecycle Management ---

    /// @notice Allows a user to propose a new quest.
    /// @param _title The title of the quest.
    /// @param _descriptionURI IPFS hash or URL for quest details.
    /// @param _rewardAmount The reward in wei for completing the quest.
    /// @param _requiredSkillIds Array of skill IDs required for this quest.
    /// @param _requiredSkillLevels Array of minimum skill levels corresponding to `_requiredSkillIds`.
    /// @param _deadline The Unix timestamp by which the quest must be completed.
    function createQuest(
        string calldata _title,
        string calldata _descriptionURI,
        uint256 _rewardAmount,
        uint256[] calldata _requiredSkillIds,
        uint256[] calldata _requiredSkillLevels,
        uint256 _deadline
    ) external payable whenNotPaused {
        require(msg.value == questCreationFee + _rewardAmount, "AetherForge: Incorrect ETH amount sent for fee and reward");
        require(_deadline > block.timestamp, "AetherForge: Deadline must be in the future");
        require(_requiredSkillIds.length == _requiredSkillLevels.length, "AetherForge: Skill ID and level arrays must match in length");
        require(_rewardAmount > 0, "AetherForge: Reward must be greater than zero");

        _questIds.increment();
        uint256 newQuestId = _questIds.current();

        quests[newQuestId] = Quest({
            id: newQuestId,
            proposer: msg.sender,
            executor: address(0),
            agentId: 0,
            title: _title,
            descriptionURI: _descriptionURI,
            rewardAmount: _rewardAmount,
            stakedCommitment: 0,
            deadline: _deadline,
            status: QuestStatus.Open,
            requiredSkillIds: _requiredSkillIds,
            requiredSkillLevels: _requiredSkillLevels,
            aiEvaluationScore: 0,
            disputed: false
        });

        userQuests[msg.sender].push(newQuestId);
        // Add quest to available quests for each required skill for easier filtering
        for (uint256 i = 0; i < _requiredSkillIds.length; i++) {
            availableQuests[_requiredSkillIds[i]].push(newQuestId);
        }

        emit QuestCreated(newQuestId, msg.sender, _rewardAmount, _deadline);
    }

    /// @notice Allows a qualified user or an Agent (implicitly via its owner) to accept an available quest.
    /// @param _questId The ID of the quest to accept.
    function acceptQuest(uint256 _questId) external payable whenNotPaused {
        Quest storage quest = quests[_questId];
        require(quest.id != 0, "AetherForge: Quest does not exist");
        require(quest.status == QuestStatus.Open, "AetherForge: Quest is not open");
        require(quest.proposer != msg.sender, "AetherForge: Proposer cannot accept their own quest");

        uint256 commitment = (quest.rewardAmount * commitmentStakePercentage) / 100;
        require(msg.value == commitment, "AetherForge: Incorrect commitment stake sent");
        require(block.timestamp < quest.deadline, "AetherForge: Quest deadline passed");

        // Verify skills for user or agent
        bool canExecute = true;
        for (uint256 i = 0; i < quest.requiredSkillIds.length; i++) {
            uint256 skillId = quest.requiredSkillIds[i];
            uint256 requiredLevel = quest.requiredSkillLevels[i];
            uint256 currentLevel;

            // Check if msg.sender is an agent owner and if an agent is being used
            // For simplicity, we assume if msg.sender is an agent owner, they might explicitly pass agentId,
            // or the agent itself is the msg.sender (which isn't how ERC721 works directly).
            // A more complex system would have `acceptQuest(uint256 _questId, uint256 _agentId)`
            // Here, we assume user is accepting, and they might assign it to an agent later or execute directly.
            // For the sake of having 20+ functions, let's allow a user to accept *on behalf of their agent*.
            // We'll add an overloaded function `acceptQuestByAgent` later.
            currentLevel = userSkillPoints[msg.sender][skillId];

            if (currentLevel < requiredLevel) {
                canExecute = false;
                break;
            }
        }
        require(canExecute, "AetherForge: Not enough skills to accept this quest");

        quest.executor = msg.sender;
        quest.stakedCommitment = commitment;
        quest.status = QuestStatus.Accepted;
        userQuests[msg.sender].push(_questId); // Add to executor's list
        _removeQuestFromAvailable(_questId, quest.requiredSkillIds); // Remove from public listing

        emit QuestAccepted(_questId, msg.sender, 0, commitment);
    }

    /// @notice Allows a user to accept a quest specifically using one of their Agent NFTs.
    /// @param _questId The ID of the quest to accept.
    /// @param _agentId The ID of the Agent NFT to use.
    function acceptQuestByAgent(uint256 _questId, uint256 _agentId) external payable whenNotPaused {
        Quest storage quest = quests[_questId];
        require(quest.id != 0, "AetherForge: Quest does not exist");
        require(quest.status == QuestStatus.Open, "AetherForge: Quest is not open");
        require(quest.proposer != msg.sender, "AetherForge: Proposer cannot accept their own quest");
        require(ERC721(address(this)).ownerOf(_agentId) == msg.sender, "AetherForge: Not the owner of this Agent NFT");

        uint256 commitment = (quest.rewardAmount * commitmentStakePercentage) / 100;
        require(msg.value == commitment, "AetherForge: Incorrect commitment stake sent");
        require(block.timestamp < quest.deadline, "AetherForge: Quest deadline passed");

        // Verify agent's skills
        bool canExecute = true;
        for (uint256 i = 0; i < quest.requiredSkillIds.length; i++) {
            uint256 skillId = quest.requiredSkillIds[i];
            uint256 requiredLevel = quest.requiredSkillLevels[i];
            uint256 currentAgentLevel = IAgentNFT(address(this)).getAgentSkill(_agentId, skillId);
            if (currentAgentLevel < requiredLevel) {
                canExecute = false;
                break;
            }
        }
        require(canExecute, "AetherForge: Agent does not have enough skills for this quest");

        quest.executor = msg.sender; // Owner of the agent is the executor
        quest.agentId = _agentId;
        quest.stakedCommitment = commitment;
        quest.status = QuestStatus.Accepted;
        userQuests[msg.sender].push(_questId);
        _removeQuestFromAvailable(_questId, quest.requiredSkillIds);

        emit QuestAccepted(_questId, msg.sender, _agentId, commitment);
    }


    /// @notice The executor submits proof of quest completion.
    /// @param _questId The ID of the quest.
    /// @param _proofURI IPFS hash or URL pointing to relevant data.
    function submitQuestCompletion(uint256 _questId, string calldata _proofURI) external whenNotPaused {
        Quest storage quest = quests[_questId];
        require(quest.id != 0, "AetherForge: Quest does not exist");
        require(quest.executor == msg.sender, "AetherForge: Only the executor can submit completion");
        require(quest.status == QuestStatus.Accepted, "AetherForge: Quest is not in accepted status");
        require(block.timestamp < quest.deadline, "AetherForge: Cannot submit after deadline");
        require(bytes(_proofURI).length > 0, "AetherForge: Proof URI cannot be empty");

        quest.status = QuestStatus.Submitted;
        quest.descriptionURI = _proofURI; // Update descriptionURI to proofURI for evaluation
        emit QuestCompletionSubmitted(_questId, msg.sender, _proofURI);
    }

    /// @notice Notifies the AI Oracle that a quest is ready for evaluation.
    ///         This function can be called by anyone to trigger the oracle's off-chain process.
    /// @param _questId The ID of the quest to evaluate.
    function requestQuestEvaluation(uint256 _questId) external whenNotPaused {
        Quest storage quest = quests[_questId];
        require(quest.id != 0, "AetherForge: Quest does not exist");
        require(quest.status == QuestStatus.Submitted, "AetherForge: Quest not in submitted status");
        // Oracle should be called for quests that are submitted or past deadline and not yet finalized
        // To simplify, we trigger evaluation when submitted.
        quest.status = QuestStatus.Evaluating;
        emit QuestEvaluationRequested(_questId);
    }

    /// @notice Processes the final outcome of a quest based on the AI's objective evaluation score.
    ///         Callable only by the AI Decision Oracle.
    /// @param _questId The ID of the quest.
    /// @param _aiEvaluationScore The objective score from the AI (e.g., 0-100).
    function finalizeQuest(uint256 _questId, uint256 _aiEvaluationScore) external onlyAICallback {
        Quest storage quest = quests[_questId];
        require(quest.id != 0, "AetherForge: Quest does not exist");
        require(quest.status == QuestStatus.Evaluating || quest.status == QuestStatus.Disputed, "AetherForge: Quest not in evaluating or disputed status");
        require(_aiEvaluationScore <= 100, "AetherForge: AI evaluation score must be between 0 and 100");

        quest.aiEvaluationScore = _aiEvaluationScore;
        uint256 actualReward = 0;
        QuestStatus newStatus;

        if (_aiEvaluationScore >= 60) { // Example: 60% is passing
            newStatus = QuestStatus.CompletedSuccess;
            actualReward = quest.rewardAmount + quest.stakedCommitment; // Reward + executor's stake back
            payable(quest.executor).transfer(actualReward); // Transfer reward to executor
            userReputation[quest.executor] += (10 * _aiEvaluationScore) / 100; // Example reputation gain
            if (quest.agentId != 0) {
                // Update agent's performance metrics and skills
                IAgentNFT(address(this)).updateAgentPerformance(quest.agentId, true, _aiEvaluationScore);
                for (uint256 i = 0; i < quest.requiredSkillIds.length; i++) {
                    IAgentNFT(address(this)).updateAgentSkills(quest.agentId, quest.requiredSkillIds[i], 1); // +1 skill point
                }
            } else {
                 for (uint256 i = 0; i < quest.requiredSkillIds.length; i++) {
                    userSkillPoints[quest.executor][quest.requiredSkillIds[i]] += 1; // +1 skill point
                }
            }
        } else {
            newStatus = QuestStatus.CompletedFailure;
            // Reward proposer with executor's staked commitment as compensation
            payable(quest.proposer).transfer(quest.stakedCommitment);
            userReputation[quest.executor] = userReputation[quest.executor] > 10 ? userReputation[quest.executor] - 10 : 0; // Example reputation loss
            if (quest.agentId != 0) {
                IAgentNFT(address(this)).updateAgentPerformance(quest.agentId, false, _aiEvaluationScore);
            }
            // Proposer gets their original reward back
            // No direct transfer, proposer's funds were held by contract initially with the reward.
            // In a real system, would involve returning proposer's locked funds.
            // For now, we assume initial ETH covers reward, and only commitment is transferred back.
            // AetherForge holds proposer's reward. If success, executor gets it. If failure, proposer keeps it.
            // This is implicitly handled by _aiEvaluationScore >= 60 logic.
        }

        quest.status = newStatus;
        emit QuestFinalized(_questId, newStatus, _aiEvaluationScore, actualReward);
    }

    // --- IV. Agent Management (Dynamic NFTs) ---

    // The AetherForge contract itself will act as the ERC721 contract for Agents.
    // This simplifies the interaction and allows direct calls for skill updates.
    // This requires AetherForge to inherit from ERC721.
    // For this example, I'll use a simplified internal `_safeMint` and `_approve`
    // pattern if `AetherForge` itself is the NFT. If it's a separate contract,
    // `IAgentNFT` is correct, and AetherForge would *own* the AgentNFT contract
    // or interact with it. Given the prompt for "smart contract in Solidity" (singular),
    // it implies one main contract. So I'll make AetherForge itself the ERC721.

    // Let's adjust AetherForge to also be the ERC721 for agents.
    // Remove `IAgentNFT` interface for self-contained agent management.
    // Add internal mappings for agent skills and performance directly here.
    // Or, keep IAgetNFT interface and make AetherForge own an external AgentNFT contract
    // and let the user interact with that. The prompt implies a single contract for the whole system.
    // So let's integrate ERC721 here.

    struct AgentStats {
        uint256 totalQuests;
        uint256 successfulQuests;
        uint256 totalEvaluationScore; // Sum of scores for successful quests
        mapping(uint256 => uint256) skills; // skillId => points
        bool autonomousMode;
        uint256 maxDifficulty;
        uint256[] preferredSkillIds;
        address delegatedTo;
        uint256 delegationExpires;
    }

    mapping(uint256 => AgentStats) internal _agentStats; // tokenId => AgentStats

    // Override base URI for agents
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://aetherforge/agents/"; // Example base URI for metadata
    }

    /// @notice Mints a new unique Agent NFT for the caller.
    /// @param _name The name of the agent.
    /// @return The ID of the newly minted Agent NFT.
    function mintAgentNFT(string calldata _name) external whenNotPaused returns (uint256) {
        _agentTokenIds.increment();
        uint256 newAgentId = _agentTokenIds.current();
        _safeMint(msg.sender, newAgentId);
        // Initialize agent stats
        _agentStats[newAgentId].totalQuests = 0;
        _agentStats[newAgentId].successfulQuests = 0;
        _agentStats[newAgentId].totalEvaluationScore = 0;
        _agentStats[newAgentId].autonomousMode = false;
        _agentStats[newAgentId].maxDifficulty = 0; // Default: can't auto-accept
        // preferredSkillIds remains empty by default
        
        // ERC721 tokenURI should point to a metadata JSON
        // For dynamic NFTs, the URI can point to a dynamic API endpoint or logic that generates metadata based on _agentStats.
        // For simplicity, we'll just mint.
        _setTokenURI(newAgentId, string(abi.encodePacked(_baseURI(), Strings.toString(newAgentId))));

        emit AgentMinted(newAgentId, msg.sender, _name);
        return newAgentId;
    }

    /// @notice The owner of an Agent NFT can allocate initial or earned skill points to specific skills for their agent.
    /// @param _agentId The ID of the Agent NFT.
    /// @param _skillIds Array of skill IDs to assign points to.
    /// @param _skillPoints Array of skill points corresponding to `_skillIds`.
    function assignSkillsToAgent(uint256 _agentId, uint256[] calldata _skillIds, uint256[] calldata _skillPoints) external whenNotPaused {
        require(_ownerOf(_agentId) == msg.sender, "AetherForge: Only agent owner can assign skills");
        require(_skillIds.length == _skillPoints.length, "AetherForge: Skill ID and points arrays must match in length");

        for (uint256 i = 0; i < _skillIds.length; i++) {
            uint256 skillId = _skillIds[i];
            uint256 points = _skillPoints[i];
            require(skills[skillId].registered, "AetherForge: Skill not registered");
            _agentStats[_agentId].skills[skillId] += points; // Increment, not set directly
            emit AgentSkillsAssigned(_agentId, skillId, _agentStats[_agentId].skills[skillId]);
        }
    }

    /// @notice Toggles whether an Agent NFT can autonomously accept quests.
    /// @param _agentId The ID of the Agent NFT.
    /// @param _isEnabled True to enable autonomous mode, false to disable.
    function setAgentAutonomousMode(uint256 _agentId, bool _isEnabled) external whenNotPaused {
        require(_ownerOf(_agentId) == msg.sender, "AetherForge: Only agent owner can set autonomous mode");
        _agentStats[_agentId].autonomousMode = _isEnabled;
        emit AgentAutonomousModeToggled(_agentId, _isEnabled);
    }

    /// @notice The owner configures their Agent NFT's operational preferences for autonomous quest acceptance.
    /// @param _agentId The ID of the Agent NFT.
    /// @param _maxDifficulty The maximum difficulty level an agent should attempt (e.g., based on average required skill level).
    /// @param _preferredSkillIds An array of skill IDs the agent prefers for quest matching.
    function updateAgentParameters(uint256 _agentId, uint256 _maxDifficulty, uint256[] calldata _preferredSkillIds) external whenNotPaused {
        require(_ownerOf(_agentId) == msg.sender, "AetherForge: Only agent owner can update parameters");
        _agentStats[_agentId].maxDifficulty = _maxDifficulty;
        _agentStats[_agentId].preferredSkillIds = _preferredSkillIds;
        emit AgentParametersUpdated(_agentId, _maxDifficulty);
    }

    /// @notice Allows an Agent NFT owner to temporarily delegate control over their agent to another address.
    /// @param _agentId The ID of the Agent NFT.
    /// @param _delegatee The address to delegate control to.
    /// @param _duration The duration in seconds for which control is delegated.
    function delegateAgentControl(uint256 _agentId, address _delegatee, uint256 _duration) external whenNotPaused {
        require(_ownerOf(_agentId) == msg.sender, "AetherForge: Only agent owner can delegate control");
        require(_delegatee != address(0), "AetherForge: Delegatee cannot be zero address");
        require(_duration > 0, "AetherForge: Delegation duration must be greater than zero");

        _agentStats[_agentId].delegatedTo = _delegatee;
        _agentStats[_agentId].delegationExpires = block.timestamp + _duration;
        emit AgentControlDelegated(_agentId, _delegatee, _duration);
    }
    
    // Internal helper to update agent performance
    function _updateAgentPerformance(uint256 _agentId, bool _success, uint256 _score) internal {
        AgentStats storage stats = _agentStats[_agentId];
        stats.totalQuests++;
        if (_success) {
            stats.successfulQuests++;
            stats.totalEvaluationScore += _score;
        }
    }

    // --- V. AI Oracle Integration (Implicit: Oracle calls finalizeQuest) ---
    // The `requestQuestEvaluation` triggers off-chain, and `finalizeQuest` is the callback.

    // --- VI. Dispute Resolution ---

    /// @notice A quest proposer or executor can initiate a dispute if they disagree with the AI's evaluation or the quest's final status.
    /// @param _questId The ID of the quest to dispute.
    function disputeQuestOutcome(uint256 _questId) external whenNotPaused {
        Quest storage quest = quests[_questId];
        require(quest.id != 0, "AetherForge: Quest does not exist");
        require(quest.status == QuestStatus.CompletedSuccess || quest.status == QuestStatus.CompletedFailure, "AetherForge: Quest not in a final state to dispute");
        require(quest.proposer == msg.sender || quest.executor == msg.sender, "AetherForge: Only proposer or executor can dispute");
        require(!quest.disputed, "AetherForge: Quest is already under dispute");

        quest.disputed = true;
        quest.status = QuestStatus.Disputed; // Set status to disputed
        questDisputes[_questId] = Dispute({
            questId: _questId,
            partyInitiating: msg.sender,
            timestamp: block.timestamp,
            resolved: false,
            proposerWins: false, // Placeholder
            adjustedScore: 0     // Placeholder
        });
        emit QuestDisputed(_questId, msg.sender);
    }

    /// @notice Function to manually resolve a disputed quest. Callable by Governance.
    /// @param _questId The ID of the quest.
    /// @param _proposerWins True if the proposer wins the dispute, false if executor wins.
    /// @param _adjustedScore An adjusted evaluation score if the dispute alters the original AI assessment.
    function resolveDispute(uint256 _questId, bool _proposerWins, int256 _adjustedScore) external onlyGovernance whenNotPaused {
        Quest storage quest = quests[_questId];
        require(quest.id != 0, "AetherForge: Quest does not exist");
        require(quest.disputed, "AetherForge: Quest is not under dispute");
        require(!questDisputes[_questId].resolved, "AetherForge: Dispute already resolved");

        Dispute storage dispute = questDisputes[_questId];
        dispute.resolved = true;
        dispute.proposerWins = _proposerWins;
        dispute.adjustedScore = _adjustedScore;

        uint256 finalScore;
        if (_adjustedScore != 0) {
            // Apply adjusted score from governance. Ensures score is within 0-100 range.
            finalScore = uint256(Math.max(0, Math.min(100, _adjustedScore)));
        } else {
            // No adjustment, use original AI score
            finalScore = quest.aiEvaluationScore;
        }

        // Re-run finalization logic based on dispute outcome
        uint256 actualReward = 0;
        QuestStatus newStatus;

        // If proposer wins, and their claim implies failure (e.g., AI was wrong to pass)
        // Or if executor wins, and their claim implies success (e.g., AI was wrong to fail)
        // This logic needs to be carefully defined based on dispute outcomes.
        // For simplicity: if proposer wins, it generally means quest failed/executor was at fault.
        // If executor wins, it means quest succeeded/AI evaluation was too harsh.
        
        if (_proposerWins) {
            // Proposer wins implies quest executor failed or AI over-evaluated.
            // Proposer keeps their original reward. Executor loses stake.
            newStatus = QuestStatus.CompletedFailure;
            payable(quest.proposer).transfer(quest.stakedCommitment); // Proposer gets commitment
            userReputation[quest.executor] = userReputation[quest.executor] > 20 ? userReputation[quest.executor] - 20 : 0; // Higher penalty
            if (quest.agentId != 0) {
                _updateAgentPerformance(quest.agentId, false, 0); // Mark as failure
            }
        } else {
            // Executor wins implies quest succeeded, AI was potentially too harsh.
            newStatus = QuestStatus.CompletedSuccess;
            actualReward = quest.rewardAmount + quest.stakedCommitment;
            payable(quest.executor).transfer(actualReward);
            userReputation[quest.executor] += (20 * finalScore) / 100; // Higher reputation gain
            if (quest.agentId != 0) {
                _updateAgentPerformance(quest.agentId, true, finalScore);
                for (uint256 i = 0; i < quest.requiredSkillIds.length; i++) {
                    // Award skills based on finalScore, scaled.
                    _agentStats[quest.agentId].skills[quest.requiredSkillIds[i]] += finalScore / 50; // Example
                }
            } else {
                 for (uint256 i = 0; i < quest.requiredSkillIds.length; i++) {
                    userSkillPoints[quest.executor][quest.requiredSkillIds[i]] += finalScore / 50;
                }
            }
        }

        quest.status = newStatus;
        quest.aiEvaluationScore = finalScore; // Update with resolved score
        emit DisputeResolved(_questId, _proposerWins, _adjustedScore);
        emit QuestFinalized(_questId, newStatus, finalScore, actualReward); // Re-emit finalization
    }


    // --- VII. Financials & Withdrawals ---

    /// @notice Allows the contract owner to withdraw accumulated quest creation fees.
    function withdrawQuestFees() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        uint256 feesCollected = contractBalance; // Simplistic: assume all balance minus outstanding rewards is fees
        // In a real system, track fees separately. For simplicity, we just withdraw what's available.
        // This simplistic approach assumes any balance not currently locked for quest rewards
        // is considered fee revenue. A more robust solution would track `totalFeesCollected`
        // and only allow withdrawal of that.
        // For demonstration purposes, we will withdraw everything *not* locked as commitment or reward.

        uint256 totalLockedForQuests = 0;
        for (uint256 i = 1; i <= _questIds.current(); i++) {
            Quest storage q = quests[i];
            if (q.status == QuestStatus.Open || q.status == QuestStatus.Accepted || q.status == QuestStatus.Submitted || q.status == QuestStatus.Evaluating) {
                totalLockedForQuests += q.rewardAmount + q.stakedCommitment;
            }
        }
        uint256 withdrawableFees = contractBalance - totalLockedForQuests;
        require(withdrawableFees > 0, "AetherForge: No withdrawable fees");
        
        payable(msg.sender).transfer(withdrawableFees);
        emit FeesWithdrawn(msg.sender, withdrawableFees);
    }

    /// @notice Allows an executor to reclaim their staked commitment if a quest is cancelled, times out without completion, or if they successfully dispute an unjust penalty.
    /// @param _questId The ID of the quest.
    function reclaimStakedCommitment(uint256 _questId) external whenNotPaused {
        Quest storage quest = quests[_questId];
        require(quest.id != 0, "AetherForge: Quest does not exist");
        require(quest.executor == msg.sender, "AetherForge: Only the executor can reclaim commitment");
        
        bool canReclaim = false;
        if (quest.status == QuestStatus.Open || quest.status == QuestStatus.Cancelled || block.timestamp > quest.deadline && quest.status != QuestStatus.Submitted && quest.status != QuestStatus.Evaluating) {
            // Quest was never accepted, or cancelled, or timed out without submission
            canReclaim = true;
        } else if (quest.disputed && questDisputes[_questId].resolved && !questDisputes[_questId].proposerWins) {
            // Dispute resolved in favor of executor, implying unjust penalty or failure
            canReclaim = true;
        }

        require(canReclaim, "AetherForge: Commitment cannot be reclaimed in current quest state");
        require(quest.stakedCommitment > 0, "AetherForge: No commitment staked or already reclaimed");

        uint256 amountToReclaim = quest.stakedCommitment;
        quest.stakedCommitment = 0; // Prevent double reclamation
        payable(msg.sender).transfer(amountToReclaim);
    }

    // --- VIII. Query & View Functions ---

    /// @notice Retrieves all the detailed information about a specific quest.
    /// @param _questId The ID of the quest.
    /// @return A tuple containing all quest details.
    function getQuestDetails(uint256 _questId) external view returns (
        uint256 id,
        address proposer,
        address executor,
        uint256 agentId,
        string memory title,
        string memory descriptionURI,
        uint256 rewardAmount,
        uint256 stakedCommitment,
        uint256 deadline,
        QuestStatus status,
        uint256[] memory requiredSkillIds,
        uint256[] memory requiredSkillLevels,
        uint256 aiEvaluationScore,
        bool disputed
    ) {
        Quest storage quest = quests[_questId];
        require(quest.id != 0, "AetherForge: Quest does not exist");
        return (
            quest.id,
            quest.proposer,
            quest.executor,
            quest.agentId,
            quest.title,
            quest.descriptionURI,
            quest.rewardAmount,
            quest.stakedCommitment,
            quest.deadline,
            quest.status,
            quest.requiredSkillIds,
            quest.requiredSkillLevels,
            quest.aiEvaluationScore,
            quest.disputed
        );
    }

    /// @notice Returns a paginated list of quests that are currently open for acceptance.
    /// @param _startIndex The starting index for pagination.
    /// @param _count The number of quests to return.
    /// @return An array of quest IDs.
    function getAvailableQuests(uint256 _startIndex, uint256 _count) external view returns (uint256[] memory) {
        uint256 totalQuests = _questIds.current();
        if (_startIndex >= totalQuests) {
            return new uint256[](0);
        }

        uint256 endIndex = _startIndex + _count;
        if (endIndex > totalQuests) {
            endIndex = totalQuests;
        }

        uint256[] memory questList = new uint256[](endIndex - _startIndex);
        uint256 currentCount = 0;
        for (uint256 i = _startIndex + 1; i <= endIndex; i++) { // Quest IDs start from 1
            if (quests[i].status == QuestStatus.Open && quests[i].deadline > block.timestamp) {
                questList[currentCount] = i;
                currentCount++;
            }
        }
        // Resize array to actual count of open quests found
        uint256[] memory result = new uint256[](currentCount);
        for(uint256 i = 0; i < currentCount; i++) {
            result[i] = questList[i];
        }
        return result;
    }

    /// @notice Retrieves the skill points for a given agent and skill.
    /// @param _agentId The ID of the Agent NFT.
    /// @param _skillId The ID of the skill.
    /// @return The skill points of the agent for that skill.
    function getAgentSkill(uint256 _agentId, uint256 _skillId) public view returns (uint256) {
        require(_exists(_agentId), "AetherForge: Agent does not exist");
        return _agentStats[_agentId].skills[_skillId];
    }
    
    /// @notice Updates an agent's performance metrics after a quest.
    /// @param _agentId The ID of the Agent NFT.
    /// @param _success True if the quest was successful, false otherwise.
    /// @param _score The evaluation score received.
    function updateAgentPerformance(uint256 _agentId, bool _success, uint256 _score) public {
        require(_ownerOf(_agentId) == msg.sender || msg.sender == address(this), "AetherForge: Only agent owner or contract itself can update performance");
        _updateAgentPerformance(_agentId, _success, _score);
    }

    /// @notice Gets an agent's autonomous mode status and parameters.
    /// @param _agentId The ID of the Agent NFT.
    /// @return maxDifficulty The maximum difficulty level the agent will attempt.
    /// @return preferredSkillIds An array of preferred skill IDs.
    /// @return autonomousMode True if autonomous mode is enabled.
    function getAgentParameters(uint256 _agentId) public view returns (uint256 maxDifficulty, uint256[] memory preferredSkillIds, bool autonomousMode) {
        require(_exists(_agentId), "AetherForge: Agent does not exist");
        AgentStats storage stats = _agentStats[_agentId];
        return (stats.maxDifficulty, stats.preferredSkillIds, stats.autonomousMode);
    }

    // --- Internal Helpers ---

    /// @dev Removes a quest from the available quests list for its required skills.
    function _removeQuestFromAvailable(uint256 _questId, uint256[] memory _skillIds) internal {
        for (uint256 i = 0; i < _skillIds.length; i++) {
            uint256 skillId = _skillIds[i];
            uint256[] storage questsForSkill = availableQuests[skillId];
            for (uint256 j = 0; j < questsForSkill.length; j++) {
                if (questsForSkill[j] == _questId) {
                    questsForSkill[j] = questsForSkill[questsForSkill.length - 1];
                    questsForSkill.pop();
                    break;
                }
            }
        }
    }
}

// Math library for min/max, since solidity 0.8.0+ has safe math built-in.
library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }
}
```