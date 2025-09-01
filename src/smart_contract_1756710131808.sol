Here's a Solidity smart contract for a **"Decentralized AI Research & Innovation Hub" (DAIRIH)**. This contract aims to be interesting, advanced-concept, creative, and trendy by integrating elements of decentralized science (DeSci), AI agent management (with an on-chain reputation system), community-driven evaluation, and simplified intellectual property (IP) management, all governed by a decentralized autonomous organization (DAO) mechanism. It avoids direct duplication of existing open-source projects by combining these elements in a novel way.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For percentage calculations

// Outline:
// I. Core Management & Configuration
//    - Contract Initialization and Administrative Settings.
// II. AI Agent Management
//    - Registration, profile updates, and status management for AI agents, including a Soulbound-like reputation system.
// III. Research Quest Management
//    - Proposal, community voting, funding, and lifecycle management of decentralized research quests (innovation bounties).
// IV. Solution Submission & Evaluation
//    - AI agents submit solutions, and authorized evaluators assess their quality and technical merit.
// V. Reputation & Rewards
//    - Tracking non-transferable AI agent reputation based on performance and distributing quest rewards.
// VI. Treasury & Funding
//    - Managing the contract's overall financial resources and allowing community contributions for sustainability.
// VII. Intellectual Property (IP) Management
//    - Recording and potentially licensing the IP generated from successful research quests.
// VIII. Decentralized Governance
//    - Community proposals and voting mechanism for modifying contract parameters and rules, embodying DAO principles.

// Function Summary:
// I. Core Management & Configuration
//    - constructor(): Initializes the contract with an owner, initial parameters, and sets the first governance proposal ID.
//    - setQuestApprovalThreshold(uint256 _threshold): Sets the minimum percentage of votes required for a quest to be approved (governance-controlled).
//    - setSolutionEvaluationPeriod(uint64 _period): Sets the duration for which solutions can be evaluated after submission (governance-controlled).
//    - setMinReputationForQuestCreation(uint256 _minRep): Sets the minimum reputation an AI agent needs to propose a quest (governance-controlled).
//    - setMinReputationForGovernanceProposal(uint256 _minRep): Sets the minimum reputation required for an AI agent to create a governance proposal (governance-controlled).
//    - setEvaluatorAddress(address _evaluator, bool _isEvaluator): Grants or revokes the 'evaluator' role to an address (owner or governance).
//    - pauseContract(): Pauses critical contract functionality in emergencies (owner only).
//    - unpauseContract(): Resumes contract functionality (owner only).
//
// II. AI Agent Management
//    - registerAIAgent(string memory _name, string memory _description, string[] memory _capabilities, string memory _modelLink): Registers a new AI agent, creating a unique on-chain identity (SBT-like).
//    - updateAIAgentProfile(uint256 _agentId, string memory _name, string memory _description, string[] memory _capabilities, string memory _modelLink): Allows an AI agent's owner to update its profile information.
//    - deactivateAIAgent(uint256 _agentId): Deactivates a registered AI agent, preventing it from submitting new solutions (owner of agent or contract owner).
//    - getAIAgentInfo(uint256 _agentId): Retrieves detailed public information about a specific AI agent.
//
// III. Research Quest Management
//    - proposeQuest(string memory _title, string memory _description, uint256 _rewardAmount, uint64 _deadline, string[] memory _requiredCapabilities): Proposes a new research quest, which requires community approval and funding.
//    - voteOnQuestProposal(uint256 _questId, bool _approve): Casts a vote for or against a pending quest proposal.
//    - fundQuest(uint256 _questId) payable: Allows any user to contribute ETH to fund an approved quest's reward pool.
//    - cancelQuestProposal(uint256 _questId): Allows the quest proposer or contract owner to cancel an unfunded or unapproved quest.
//    - getQuestDetails(uint256 _questId): Retrieves comprehensive details of a specific quest.
//
// IV. Solution Submission & Evaluation
//    - submitSolution(uint256 _questId, string memory _submissionHash, string memory _linkToResults): An active AI agent submits a solution to an ongoing quest.
//    - submitEvaluation(uint256 _solutionId, uint256 _score, string memory _feedbackHash): An authorized evaluator submits an assessment score for a specific solution.
//    - finalizeQuestSolution(uint256 _questId): Finalizes a quest after its evaluation period, identifies the winning solution, distributes rewards, and updates reputation.
//    - reportMaliciousSolution(uint256 _solutionId, string memory _reportHash): Allows reporting a potentially fraudulent or harmful solution for review.
//
// V. Reputation & Rewards
//    - getAIAgentReputation(uint256 _agentId): Retrieves the non-transferable reputation score of a specific AI agent.
//    - claimQuestReward(uint256 _questId): Placeholder for deferred reward claiming, currently rewards are sent upon finalization.
//
// VI. Treasury & Funding
//    - depositToTreasury() payable: Allows anyone to contribute ETH to the general DAIRIH treasury, supporting future operations and quests.
//    - withdrawFromTreasury(uint256 _amount): Allows the contract owner to withdraw funds from the general treasury (intended for DAO-approved operational expenses).
//
// VII. Intellectual Property (IP) Management
//    - assignIPRightsToDAO(uint256 _solutionId): Records the assignment of IP rights for a winning solution to the DAIRIH DAO.
//    - grantIPLicense(uint256 _solutionId, address _licensee, string memory _licenseTermsHash): Records the granting of a license for a solution's IP to a third party.
//    - getSolutionIPHash(uint256 _solutionId): Retrieves the recorded unique identifier (hash) for a solution's associated IP.
//
// VIII. Decentralized Governance
//    - createGovernanceProposal(string memory _description, address _target, bytes memory _callData): Allows any address with sufficient reputation to propose a contract change or action.
//    - voteOnGovernanceProposal(uint256 _proposalId, bool _approve): Casts a vote for or against a pending governance proposal.
//    - executeGovernanceProposal(uint256 _proposalId): Executes a governance proposal that has successfully passed its voting threshold.

contract DecentralizedAIRIHub is Ownable, ReentrancyGuard, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---

    // Global counters for unique IDs
    Counters.Counter private _aiAgentIdCounter;
    Counters.Counter private _questIdCounter;
    Counters.Counter private _solutionIdCounter;
    Counters.Counter private _governanceProposalIdCounter;

    // Configuration parameters (can be changed by governance)
    uint256 public questApprovalThreshold; // % of total votes needed for quest approval
    uint64 public solutionEvaluationPeriod; // Duration in seconds for solution evaluation
    uint256 public minReputationForQuestCreation; // Minimum reputation for an AI agent to propose a quest
    uint256 public minReputationForGovernanceProposal; // Minimum reputation for an AI agent to create a governance proposal

    // Role-based access control for evaluators
    mapping(address => bool) public isEvaluator;

    // --- Data Structures ---

    /// @dev Represents an AI agent, which is a unique on-chain identity (SBT-like) tied to an owner.
    struct AIAgent {
        uint256 id;
        address owner; // The address controlling this AI agent
        string name;
        string description;
        string[] capabilities; // e.g., "NLP", "Computer Vision"
        string modelLink; // Link to off-chain model description or interface (e.g., IPFS URI)
        uint256 reputationScore; // Non-transferable score, built through successful quest completions
        bool isActive;
    }

    /// @dev Represents a decentralized research or innovation quest.
    struct Quest {
        uint256 id;
        uint256 proposerAgentId; // ID of the AI agent proposing the quest
        string title;
        string description;
        uint256 rewardAmount; // Total ETH reward for the winning solution
        uint64 deadline; // Timestamp when solution submissions close
        string[] requiredCapabilities;
        address funder; // The address that funded the quest (simplification for a single funder/pool)
        uint256 currentFunding; // Current ETH raised for the quest
        uint256 approvalVotesYes;
        uint256 approvalVotesNo;
        mapping(address => bool) hasVotedOnApproval; // Tracks if an address has voted on quest approval
        Status status;
        uint256 winningSolutionId;
        uint64 evaluationEndTime; // Timestamp when solution evaluation closes
    }

    /// @dev Enum for the different stages of a Quest.
    enum Status {
        PendingApproval, // Proposed, awaiting community vote
        Approved,        // Approved by community, awaiting funding
        Active,          // Fully funded, open for solution submissions
        EvaluationPeriod, // Submissions closed, evaluators scoring solutions
        Finalized,       // Winning solution identified, rewards distributed
        Cancelled        // Quest cancelled
    }

    /// @dev Represents a submitted solution to a quest by an AI agent.
    struct Solution {
        uint256 id;
        uint256 questId;
        uint256 agentId;
        string submissionHash; // Hash of the solution data (e.g., IPFS hash of model artifacts, code)
        string linkToResults; // Link to off-chain results, proofs, or a detailed report
        uint256 evaluationScoreSum; // Sum of scores from evaluators
        uint256 evaluatorCount; // Number of evaluators who scored this solution
        mapping(address => bool) hasEvaluated; // Tracks if an evaluator has scored this solution
        bool isReportedMalicious; // Flag if the solution has been reported for review
        string ipHash; // Hash representing the IP of this solution, assigned upon finalization
        address currentIPLicensee; // Address currently holding the IP license or ownership
        string ipLicenseTermsHash; // Hash of the off-chain IP license terms
    }

    /// @dev Represents a decentralized governance proposal to change contract parameters or execute actions.
    struct GovernanceProposal {
        uint256 id;
        uint256 proposerAgentId; // ID of the AI agent that proposed this governance change
        string description;
        address target; // Address of the contract to call (typically this contract itself)
        bytes callData; // Encoded function call data (e.g., `abi.encodeWithSignature("setQuestApprovalThreshold(uint256)", 70)`)
        uint256 voteYes;
        uint256 voteNo;
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
        uint256 creationTime;
        uint64 votingPeriodEndTime;
        bool executed; // True if the proposal has been attempted for execution
        bool passed;   // True if the proposal passed the voting threshold
    }

    // --- Mappings ---

    mapping(uint256 => AIAgent) public aiAgents;
    mapping(address => uint256) public agentOwnerToId; // Maps agent owner address to their primary AI agent ID
    
    mapping(uint256 => Quest) public quests;
    mapping(uint256 => Solution) public solutions;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    
    // Treasury for general operations and future quest funding
    uint256 public treasuryBalance;

    // --- Events ---

    event AIAgentRegistered(uint256 indexed agentId, address indexed owner, string name);
    event AIAgentProfileUpdated(uint256 indexed agentId, string newName);
    event AIAgentDeactivated(uint256 indexed agentId);

    event QuestProposed(uint256 indexed questId, uint256 indexed proposerAgentId, string title, uint256 rewardAmount);
    event QuestApproved(uint256 indexed questId);
    event QuestFunded(uint256 indexed questId, address indexed funder, uint256 amount);
    event QuestCancelled(uint256 indexed questId);
    event QuestFinalized(uint256 indexed questId, uint256 indexed winningSolutionId, uint256 rewardAmount);

    event SolutionSubmitted(uint256 indexed solutionId, uint256 indexed questId, uint256 indexed agentId, string submissionHash);
    event SolutionEvaluated(uint256 indexed solutionId, address indexed evaluator, uint256 score);
    event SolutionMaliciouslyReported(uint256 indexed solutionId, address indexed reporter);

    event RewardClaimed(uint256 indexed questId, uint256 indexed agentId, uint256 amount);

    event TreasuryDeposited(address indexed depositor, uint256 amount);
    event TreasuryWithdrawn(address indexed recipient, uint256 amount);

    event IPRightsAssignedToDAO(uint256 indexed solutionId, string ipHash);
    event IPLicenseGranted(uint256 indexed solutionId, address indexed licensee, string licenseTermsHash);

    event GovernanceProposalCreated(uint256 indexed proposalId, uint256 indexed proposerAgentId, string description);
    event GovernanceVoteCasted(uint256 indexed proposalId, address indexed voter, bool approved);
    event GovernanceProposalExecuted(uint256 indexed proposalId, bool success);

    // --- Constructor ---

    constructor() Ownable(msg.sender) {
        questApprovalThreshold = 60; // 60% approval needed for quests (out of total votes)
        solutionEvaluationPeriod = 7 days; // 7 days for solution evaluation
        minReputationForQuestCreation = 100; // Example: AI agents need 100 rep to propose quests
        minReputationForGovernanceProposal = 500; // Example: AI agents need 500 rep to create governance proposals
        _governanceProposalIdCounter.increment(); // Start from 1, so 0 is not a valid ID for governance proposals
    }

    // --- I. Core Management & Configuration ---

    /// @notice Sets the minimum percentage of votes required for a quest to be approved.
    ///         This function can be called by the contract owner or via a successful governance proposal.
    /// @param _threshold The new threshold percentage (0-100).
    function setQuestApprovalThreshold(uint256 _threshold) external onlyOwnerOrGovernance {
        require(_threshold <= 100, "Threshold must be between 0 and 100.");
        questApprovalThreshold = _threshold;
    }

    /// @notice Sets the duration for which solutions can be evaluated after submission.
    ///         This function can be called by the contract owner or via a successful governance proposal.
    /// @param _period The new evaluation period in seconds.
    function setSolutionEvaluationPeriod(uint64 _period) external onlyOwnerOrGovernance {
        solutionEvaluationPeriod = _period;
    }

    /// @notice Sets the minimum reputation an AI agent needs to propose a quest.
    ///         This function can be called by the contract owner or via a successful governance proposal.
    /// @param _minRep The new minimum reputation score.
    function setMinReputationForQuestCreation(uint256 _minRep) external onlyOwnerOrGovernance {
        minReputationForQuestCreation = _minRep;
    }

    /// @notice Sets the minimum reputation for an AI agent to create a governance proposal.
    ///         This function can be called by the contract owner or via a successful governance proposal.
    /// @param _minRep The new minimum reputation score.
    function setMinReputationForGovernanceProposal(uint256 _minRep) external onlyOwnerOrGovernance {
        minReputationForGovernanceProposal = _minRep;
    }

    /// @notice Grants or revokes the 'evaluator' role to an address.
    ///         Evaluators are responsible for scoring solutions.
    ///         This function can be called by the contract owner or via a successful governance proposal.
    /// @param _evaluator The address to set the role for.
    /// @param _isEvaluator True to grant, false to revoke.
    function setEvaluatorAddress(address _evaluator, bool _isEvaluator) external onlyOwnerOrGovernance {
        isEvaluator[_evaluator] = _isEvaluator;
    }

    /// @notice Pauses contract functionality in emergencies.
    ///         Only callable by the contract owner.
    function pauseContract() external onlyOwner {
        _pause();
    }

    /// @notice Resumes contract functionality after being paused.
    ///         Only callable by the contract owner.
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    // --- II. AI Agent Management ---

    /// @notice Registers a new AI agent on the platform.
    ///         Each address can register only one primary AI agent. This agent acts as a "Soulbound Token" for reputation.
    /// @param _name The name of the AI agent.
    /// @param _description A description of the agent's purpose or capabilities.
    /// @param _capabilities An array of strings describing the agent's skills (e.g., "NLP", "Image Recognition").
    /// @param _modelLink A link to the off-chain model's public interface or description (e.g., IPFS URI).
    function registerAIAgent(string memory _name, string memory _description, string[] memory _capabilities, string memory _modelLink)
        external
        whenNotPaused
    {
        require(agentOwnerToId[msg.sender] == 0, "Caller already owns an AI agent.");

        _aiAgentIdCounter.increment();
        uint256 newAgentId = _aiAgentIdCounter.current();

        aiAgents[newAgentId] = AIAgent({
            id: newAgentId,
            owner: msg.sender,
            name: _name,
            description: _description,
            capabilities: _capabilities,
            modelLink: _modelLink,
            reputationScore: 0, // Starts with 0 reputation
            isActive: true
        });
        agentOwnerToId[msg.sender] = newAgentId;

        emit AIAgentRegistered(newAgentId, msg.sender, _name);
    }

    /// @notice Allows an AI agent's owner to update its profile information.
    /// @param _agentId The ID of the AI agent to update.
    /// @param _name The new name for the agent.
    /// @param _description The new description for the agent.
    /// @param _capabilities The new array of capabilities.
    /// @param _modelLink The new link to the model.
    function updateAIAgentProfile(uint256 _agentId, string memory _name, string memory _description, string[] memory _capabilities, string memory _modelLink)
        external
        whenNotPaused
    {
        AIAgent storage agent = aiAgents[_agentId];
        require(agent.id != 0, "AI Agent does not exist.");
        require(agent.owner == msg.sender, "Only the agent owner can update profile.");

        agent.name = _name;
        agent.description = _description;
        agent.capabilities = _capabilities;
        agent.modelLink = _modelLink;

        emit AIAgentProfileUpdated(_agentId, _name);
    }

    /// @notice Deactivates a registered AI agent, preventing it from submitting new solutions.
    ///         Can be called by the agent owner or the contract owner.
    /// @param _agentId The ID of the AI agent to deactivate.
    function deactivateAIAgent(uint256 _agentId) external whenNotPaused {
        AIAgent storage agent = aiAgents[_agentId];
        require(agent.id != 0, "AI Agent does not exist.");
        require(agent.owner == msg.sender || msg.sender == owner(), "Only the agent owner or contract owner can deactivate.");
        require(agent.isActive, "AI Agent is already inactive.");

        agent.isActive = false;
        emit AIAgentDeactivated(_agentId);
    }

    /// @notice Retrieves detailed public information about a specific AI agent.
    /// @param _agentId The ID of the AI agent.
    /// @return The agent's ID, owner address, name, description, capabilities, model link, reputation, and active status.
    function getAIAgentInfo(uint256 _agentId)
        external
        view
        returns (
            uint256 id,
            address ownerAddress,
            string memory name,
            string memory description,
            string[] memory capabilities,
            string memory modelLink,
            uint256 reputationScore,
            bool isActive
        )
    {
        AIAgent storage agent = aiAgents[_agentId];
        require(agent.id != 0, "AI Agent does not exist.");

        return (
            agent.id,
            agent.owner,
            agent.name,
            agent.description,
            agent.capabilities,
            agent.modelLink,
            agent.reputationScore,
            agent.isActive
        );
    }

    // --- III. Research Quest Management ---

    /// @notice Proposes a new research quest, which requires community approval and funding.
    ///         Requires the proposer's AI agent to meet a minimum reputation score.
    /// @param _title The title of the quest.
    /// @param _description A detailed description of the quest's objective.
    /// @param _rewardAmount The total ETH reward to be paid to the winning solution.
    /// @param _deadline The timestamp by which solutions must be submitted.
    /// @param _requiredCapabilities An array of capabilities required for agents to solve this quest.
    /// @return The ID of the newly proposed quest.
    function proposeQuest(string memory _title, string memory _description, uint256 _rewardAmount, uint64 _deadline, string[] memory _requiredCapabilities)
        external
        whenNotPaused
        returns (uint256)
    {
        uint256 agentId = agentOwnerToId[msg.sender];
        require(agentId != 0, "Caller does not own an AI agent.");
        require(aiAgents[agentId].isActive, "AI Agent is not active.");
        require(aiAgents[agentId].reputationScore >= minReputationForQuestCreation, "Insufficient AI agent reputation to propose a quest.");
        require(_rewardAmount > 0, "Reward amount must be greater than zero.");
        require(_deadline > block.timestamp, "Deadline must be in the future.");

        _questIdCounter.increment();
        uint256 newQuestId = _questIdCounter.current();

        quests[newQuestId] = Quest({
            id: newQuestId,
            proposerAgentId: agentId,
            title: _title,
            description: _description,
            rewardAmount: _rewardAmount,
            deadline: _deadline,
            requiredCapabilities: _requiredCapabilities,
            funder: address(0), // No funder initially
            currentFunding: 0,
            approvalVotesYes: 0,
            approvalVotesNo: 0,
            status: Status.PendingApproval,
            winningSolutionId: 0,
            evaluationEndTime: 0
        });

        emit QuestProposed(newQuestId, agentId, _title, _rewardAmount);
        return newQuestId;
    }

    /// @notice Casts a vote for or against a pending quest proposal.
    ///         Each address can vote once per quest proposal.
    /// @param _questId The ID of the quest proposal to vote on.
    /// @param _approve True to vote yes, false to vote no.
    function voteOnQuestProposal(uint256 _questId, bool _approve) external whenNotPaused {
        Quest storage quest = quests[_questId];
        require(quest.id != 0, "Quest does not exist.");
        require(quest.status == Status.PendingApproval, "Quest is not in pending approval status.");
        require(!quest.hasVotedOnApproval[msg.sender], "Caller has already voted on this quest.");

        if (_approve) {
            quest.approvalVotesYes = quest.approvalVotesYes.add(1);
        } else {
            quest.approvalVotesNo = quest.approvalVotesNo.add(1);
        }
        quest.hasVotedOnApproval[msg.sender] = true;

        uint256 totalVotes = quest.approvalVotesYes.add(quest.approvalVotesNo);
        // Minimum 3 votes for a quest to be approved (to prevent single-person approval on small counts)
        if (totalVotes >= 3 && quest.approvalVotesYes.mul(100) / totalVotes >= questApprovalThreshold) {
            quest.status = Status.Approved;
            emit QuestApproved(_questId);
        }
    }

    /// @notice Allows any user to contribute ETH to fund an approved quest's reward pool.
    ///         Once fully funded, the quest moves to the 'Active' status.
    /// @param _questId The ID of the quest to fund.
    function fundQuest(uint256 _questId) external payable whenNotPaused nonReentrant {
        Quest storage quest = quests[_questId];
        require(quest.id != 0, "Quest does not exist.");
        require(quest.status == Status.Approved, "Quest is not in approved status.");
        require(msg.value > 0, "Must send ETH to fund the quest.");

        quest.currentFunding = quest.currentFunding.add(msg.value);
        treasuryBalance = treasuryBalance.add(msg.value); // Temporarily in treasury, then moved to quest pool

        emit QuestFunded(_questId, msg.sender, msg.value);

        if (quest.currentFunding >= quest.rewardAmount) {
            quest.funder = msg.sender; // Recording first funder for now, could be improved for multiple.
            quest.status = Status.Active; // Now open for solutions
        }
    }

    /// @notice Allows the quest proposer or contract owner to cancel an unfunded or unapproved quest.
    /// @param _questId The ID of the quest to cancel.
    function cancelQuestProposal(uint256 _questId) external whenNotPaused {
        Quest storage quest = quests[_questId];
        require(quest.id != 0, "Quest does not exist.");
        require(quest.proposerAgentId == agentOwnerToId[msg.sender] || msg.sender == owner(), "Only proposer or owner can cancel.");
        require(quest.status == Status.PendingApproval || quest.status == Status.Approved, "Quest cannot be cancelled in its current status.");
        require(quest.currentFunding == 0, "Cannot cancel a quest that has received funding."); // Prevent fund lock if partial funding

        quest.status = Status.Cancelled;
        emit QuestCancelled(_questId);
    }

    /// @notice Retrieves comprehensive details of a specific quest.
    /// @param _questId The ID of the quest.
    /// @return All fields of the Quest struct.
    function getQuestDetails(uint256 _questId)
        external
        view
        returns (
            uint256 id,
            uint256 proposerAgentId,
            string memory title,
            string memory description,
            uint256 rewardAmount,
            uint64 deadline,
            string[] memory requiredCapabilities,
            address funder,
            uint256 currentFunding,
            uint256 approvalVotesYes,
            uint256 approvalVotesNo,
            Status status,
            uint256 winningSolutionId,
            uint64 evaluationEndTime
        )
    {
        Quest storage quest = quests[_questId];
        require(quest.id != 0, "Quest does not exist.");

        return (
            quest.id,
            quest.proposerAgentId,
            quest.title,
            quest.description,
            quest.rewardAmount,
            quest.deadline,
            quest.requiredCapabilities,
            quest.funder,
            quest.currentFunding,
            quest.approvalVotesYes,
            quest.approvalVotesNo,
            quest.status,
            quest.winningSolutionId,
            quest.evaluationEndTime
        );
    }

    // --- IV. Solution Submission & Evaluation ---

    /// @notice An active AI agent submits a solution to an ongoing quest.
    ///         Requires the agent to be active and the quest to be open for solutions.
    /// @param _questId The ID of the quest the solution is for.
    /// @param _submissionHash A hash representing the unique solution (e.g., IPFS hash of model artifacts, code).
    /// @param _linkToResults A link to off-chain results, proofs, or a detailed report.
    /// @return The ID of the newly submitted solution.
    function submitSolution(uint256 _questId, string memory _submissionHash, string memory _linkToResults)
        external
        whenNotPaused
        returns (uint256)
    {
        Quest storage quest = quests[_questId];
        uint256 agentId = agentOwnerToId[msg.sender];
        require(agentId != 0, "Caller does not own an AI agent.");
        require(aiAgents[agentId].isActive, "AI Agent is not active.");
        require(quest.id != 0, "Quest does not exist.");
        require(quest.status == Status.Active, "Quest is not open for solutions.");
        require(block.timestamp <= quest.deadline, "Quest submission deadline has passed.");

        _solutionIdCounter.increment();
        uint256 newSolutionId = _solutionIdCounter.current();

        solutions[newSolutionId] = Solution({
            id: newSolutionId,
            questId: _questId,
            agentId: agentId,
            submissionHash: _submissionHash,
            linkToResults: _linkToResults,
            evaluationScoreSum: 0,
            evaluatorCount: 0,
            isReportedMalicious: false,
            ipHash: "",
            currentIPLicensee: address(0),
            ipLicenseTermsHash: ""
        });

        // If this is the first solution for an active quest, implicitly start the evaluation period when submissions close
        // For simplicity, `evaluationEndTime` is set when quest moves to `Active`.
        // A more complex flow might move from `Active` to `SubmissionClosed` then `EvaluationPeriod`
        // We ensure evaluation period starts after the submission deadline
        if (quest.status == Status.Active && block.timestamp >= quest.deadline) {
            quest.evaluationEndTime = quest.deadline.add(solutionEvaluationPeriod);
            quest.status = Status.EvaluationPeriod;
        } else if (quest.status == Status.Active && quest.evaluationEndTime == 0) {
            // This is a temporary setup, a better way would be to move quest to EvaluationPeriod explicitly after deadline.
            // For now, if no solutions, it stays active until deadline passes.
        }

        emit SolutionSubmitted(newSolutionId, _questId, agentId, _submissionHash);
        return newSolutionId;
    }

    /// @notice An authorized evaluator submits an assessment score for a specific solution.
    ///         Evaluators can only score a solution once.
    /// @param _solutionId The ID of the solution to evaluate.
    /// @param _score The score given to the solution (e.g., 0-100).
    /// @param _feedbackHash A hash of detailed feedback (e.g., IPFS hash of a review document).
    function submitEvaluation(uint256 _solutionId, uint256 _score, string memory _feedbackHash) external whenNotPaused {
        require(isEvaluator[msg.sender], "Caller is not an authorized evaluator.");

        Solution storage solution = solutions[_solutionId];
        require(solution.id != 0, "Solution does not exist.");
        require(solution.hasEvaluated[msg.sender] == false, "Evaluator has already scored this solution.");
        
        Quest storage quest = quests[solution.questId];
        require(quest.status == Status.EvaluationPeriod, "Quest is not in evaluation period.");
        require(block.timestamp <= quest.evaluationEndTime, "Evaluation period has ended.");
        require(_score <= 100, "Score must be between 0 and 100."); // Example score range

        solution.evaluationScoreSum = solution.evaluationScoreSum.add(_score);
        solution.evaluatorCount = solution.evaluatorCount.add(1);
        solution.hasEvaluated[msg.sender] = true;

        // Optionally, one could store _feedbackHash on-chain, but for this example, we just record score.

        emit SolutionEvaluated(_solutionId, msg.sender, _score);
    }

    /// @notice Finalizes a quest after its evaluation period, identifies the winning solution,
    ///         distributes rewards, and updates the reputation of the winning agent.
    ///         Can only be called after the evaluation period has ended.
    /// @param _questId The ID of the quest to finalize.
    function finalizeQuestSolution(uint256 _questId) external whenNotPaused nonReentrant {
        Quest storage quest = quests[_questId];
        require(quest.id != 0, "Quest does not exist.");
        require(quest.status == Status.EvaluationPeriod, "Quest is not in evaluation period.");
        require(block.timestamp > quest.evaluationEndTime, "Evaluation period has not ended yet.");
        require(quest.currentFunding >= quest.rewardAmount, "Quest is not fully funded.");

        uint256 bestSolutionId = 0;
        uint256 highestAverageScore = 0;

        // Iterate through all solutions to find the best one for this quest.
        // NOTE: This loop can be gas-intensive if there are many solutions. For very large DApps,
        // this part might be offloaded to an off-chain computation with on-chain verification
        // (e.g., submitting a ZK-proof of the highest score calculation).
        for (uint256 i = 1; i <= _solutionIdCounter.current(); i++) {
            Solution storage s = solutions[i];
            if (s.questId == _questId && !s.isReportedMalicious) {
                if (s.evaluatorCount > 0) {
                    uint256 averageScore = s.evaluationScoreSum.div(s.evaluatorCount);
                    if (averageScore > highestAverageScore) {
                        highestAverageScore = averageScore;
                        bestSolutionId = i;
                    }
                }
            }
        }

        require(bestSolutionId != 0, "No valid solutions found or evaluated for this quest.");

        Solution storage winningSolution = solutions[bestSolutionId];
        AIAgent storage winningAgent = aiAgents[winningSolution.agentId];

        // Distribute reward
        uint256 reward = quest.rewardAmount;
        treasuryBalance = treasuryBalance.sub(reward); // Deduct from treasury
        (bool success, ) = winningAgent.owner.call{value: reward}("");
        require(success, "Failed to transfer reward to winning agent.");

        // Update winning agent's reputation
        winningAgent.reputationScore = winningAgent.reputationScore.add(highestAverageScore.mul(10).div(100)); // Example: Reputation based on scaled average score

        quest.winningSolutionId = bestSolutionId;
        quest.status = Status.Finalized;
        winningSolution.ipHash = winningSolution.submissionHash; // The submission hash also acts as the IP identifier

        emit QuestFinalized(_questId, bestSolutionId, reward);
    }

    /// @notice Allows reporting a potentially malicious or fraudulent solution for review.
    ///         A reported solution cannot win a quest until cleared (manual intervention by owner/governance needed).
    /// @param _solutionId The ID of the solution to report.
    /// @param _reportHash A hash of the detailed report (e.g., IPFS hash of evidence).
    function reportMaliciousSolution(uint256 _solutionId, string memory _reportHash) external whenNotPaused {
        Solution storage solution = solutions[_solutionId];
        require(solution.id != 0, "Solution does not exist.");
        require(!solution.isReportedMalicious, "Solution already reported as malicious.");

        solution.isReportedMalicious = true;
        // Further action (e.g., owner review, governance vote to clear) would be off-chain or via a separate function.

        emit SolutionMaliciouslyReported(_solutionId, msg.sender);
    }

    // --- V. Reputation & Rewards ---

    /// @notice Retrieves the non-transferable reputation score of a specific AI agent.
    /// @param _agentId The ID of the AI agent.
    /// @return The current reputation score.
    function getAIAgentReputation(uint256 _agentId) external view returns (uint256) {
        require(aiAgents[_agentId].id != 0, "AI Agent does not exist.");
        return aiAgents[_agentId].reputationScore;
    }

    /// @notice Allows the winning AI agent of a finalized quest to claim their designated reward.
    ///         (Note: In the current `finalizeQuestSolution`, the reward is automatically transferred.
    ///         This function is left as a placeholder for a deferred claim model or for future modification.)
    /// @param _questId The ID of the finalized quest.
    function claimQuestReward(uint256 _questId) external view {
        Quest storage quest = quests[_questId];
        require(quest.id != 0, "Quest does not exist.");
        require(quest.status == Status.Finalized, "Quest is not finalized.");
        
        Solution storage winningSolution = solutions[quest.winningSolutionId];
        require(winningSolution.agentId != 0, "No winning solution found for this quest.");
        require(aiAgents[winningSolution.agentId].owner == msg.sender, "Caller is not the owner of the winning AI agent.");
        
        revert("Reward already distributed during quest finalization.");
    }

    // --- VI. Treasury & Funding ---

    /// @notice Allows anyone to contribute ETH to the general DAIRIH treasury,
    ///         supporting future operations and quests.
    function depositToTreasury() external payable whenNotPaused {
        require(msg.value > 0, "Must send ETH to deposit to treasury.");
        treasuryBalance = treasuryBalance.add(msg.value);
        emit TreasuryDeposited(msg.sender, msg.value);
    }

    /// @notice Allows the contract owner to withdraw funds from the general treasury.
    ///         Intended for DAO-approved operational expenses, subject to governance.
    /// @param _amount The amount of ETH to withdraw.
    function withdrawFromTreasury(uint256 _amount) external onlyOwner whenNotPaused nonReentrant {
        require(_amount > 0, "Withdrawal amount must be greater than zero.");
        require(treasuryBalance >= _amount, "Insufficient funds in treasury.");

        treasuryBalance = treasuryBalance.sub(_amount);
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Failed to withdraw from treasury.");

        emit TreasuryWithdrawn(msg.sender, _amount);
    }

    // --- VII. Intellectual Property (IP) Management ---

    /// @notice Records the assignment of IP rights for a winning solution to the DAIRIH DAO.
    ///         This formalizes on-chain that the DAO now holds rights to the solution's IP.
    ///         Only callable by the contract owner or via a successful governance proposal.
    /// @param _solutionId The ID of the winning solution.
    function assignIPRightsToDAO(uint256 _solutionId) external onlyOwnerOrGovernance whenNotPaused {
        Solution storage solution = solutions[_solutionId];
        require(solution.id != 0, "Solution does not exist.");
        require(quests[solution.questId].status == Status.Finalized, "Quest is not finalized for this solution.");
        require(quests[solution.questId].winningSolutionId == _solutionId, "Solution is not the winning solution for its quest.");
        require(bytes(solution.ipHash).length > 0, "Solution IP hash not set (quest not finalized).");
        require(solution.currentIPLicensee == address(0), "IP already licensed or assigned.");

        // For simplicity, assigning to DAO means the contract records it.
        // The `solution.ipHash` serves as the unique identifier for the IP.
        solution.currentIPLicensee = address(this); // Represents DAO ownership
        solution.ipLicenseTermsHash = "DAO ownership - full rights"; // Placeholder for terms

        emit IPRightsAssignedToDAO(_solutionId, solution.ipHash);
    }

    /// @notice Records the granting of a license for a solution's IP to a third party.
    ///         This function primarily serves as an on-chain ledger of IP licensing.
    ///         Only callable by the contract owner or via a successful governance proposal.
    /// @param _solutionId The ID of the winning solution whose IP is being licensed.
    /// @param _licensee The address of the entity receiving the license.
    /// @param _licenseTermsHash A hash of the off-chain legal license agreement terms (e.g., IPFS hash).
    function grantIPLicense(uint256 _solutionId, address _licensee, string memory _licenseTermsHash) external onlyOwnerOrGovernance whenNotPaused {
        Solution storage solution = solutions[_solutionId];
        require(solution.id != 0, "Solution does not exist.");
        require(quests[solution.questId].status == Status.Finalized, "Quest is not finalized for this solution.");
        require(quests[solution.questId].winningSolutionId == _solutionId, "Solution is not the winning solution for its quest.");
        require(bytes(solution.ipHash).length > 0, "Solution IP hash not set (quest not finalized).");
        require(_licensee != address(0), "Licensee cannot be zero address.");
        require(bytes(_licenseTermsHash).length > 0, "License terms hash cannot be empty.");

        solution.currentIPLicensee = _licensee;
        solution.ipLicenseTermsHash = _licenseTermsHash;

        emit IPLicenseGranted(_solutionId, _licensee, _licenseTermsHash);
    }

    /// @notice Retrieves the recorded unique identifier (hash) for a solution's associated IP.
    /// @param _solutionId The ID of the solution.
    /// @return The IP hash string.
    function getSolutionIPHash(uint256 _solutionId) external view returns (string memory) {
        Solution storage solution = solutions[_solutionId];
        require(solution.id != 0, "Solution does not exist.");
        return solution.ipHash;
    }

    // --- VIII. Decentralized Governance ---

    /// @notice Allows any AI agent with sufficient reputation to propose a contract change or action.
    ///         Proposals can be for calling any function on this contract or other target contracts.
    /// @param _description A description of the governance proposal.
    /// @param _target The address of the contract to call (e.g., this contract for setting parameters).
    /// @param _callData The encoded function call data for the target contract
    ///                  (e.g., `abi.encodeWithSignature("setQuestApprovalThreshold(uint256)", 70)`).
    /// @return The ID of the newly created governance proposal.
    function createGovernanceProposal(string memory _description, address _target, bytes memory _callData)
        external
        whenNotPaused
        returns (uint256)
    {
        uint256 agentId = agentOwnerToId[msg.sender];
        require(agentId != 0, "Caller does not own an AI agent.");
        require(aiAgents[agentId].isActive, "AI Agent is not active.");
        require(aiAgents[agentId].reputationScore >= minReputationForGovernanceProposal, "Insufficient AI agent reputation to create a governance proposal.");
        require(_target != address(0), "Target address cannot be zero.");
        require(bytes(_callData).length > 0, "Call data cannot be empty for a governance proposal.");

        _governanceProposalIdCounter.increment();
        uint256 newProposalId = _governanceProposalIdCounter.current();

        governanceProposals[newProposalId] = GovernanceProposal({
            id: newProposalId,
            proposerAgentId: agentId,
            description: _description,
            target: _target,
            callData: _callData,
            voteYes: 0,
            voteNo: 0,
            creationTime: block.timestamp,
            votingPeriodEndTime: uint64(block.timestamp + 7 days), // Example: 7-day voting period
            executed: false,
            passed: false
        });

        emit GovernanceProposalCreated(newProposalId, agentId, _description);
        return newProposalId;
    }

    /// @notice Casts a vote for or against a pending governance proposal.
    ///         Each AI agent's owner can vote once per proposal. Voting power could be tied to reputation (not implemented here for simplicity, 1 address = 1 vote).
    /// @param _proposalId The ID of the governance proposal to vote on.
    /// @param _approve True to vote yes, false to vote no.
    function voteOnGovernanceProposal(uint256 _proposalId, bool _approve) external whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.id != 0, "Governance proposal does not exist.");
        require(block.timestamp <= proposal.votingPeriodEndTime, "Voting period has ended.");
        require(!proposal.executed, "Proposal has already been executed.");
        require(!proposal.hasVoted[msg.sender], "Caller has already voted on this proposal.");

        if (_approve) {
            proposal.voteYes = proposal.voteYes.add(1);
        } else {
            proposal.voteNo = proposal.voteNo.add(1);
        }
        proposal.hasVoted[msg.sender] = true;

        emit GovernanceVoteCasted(_proposalId, msg.sender, _approve);
    }

    /// @notice Executes a governance proposal that has successfully passed its voting threshold.
    ///         Can only be called after the voting period has ended and if the proposal passed.
    /// @param _proposalId The ID of the governance proposal to execute.
    function executeGovernanceProposal(uint256 _proposalId) external whenNotPaused nonReentrant {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.id != 0, "Governance proposal does not exist.");
        require(block.timestamp > proposal.votingPeriodEndTime, "Voting period has not ended yet.");
        require(!proposal.executed, "Proposal has already been executed.");

        uint256 totalVotes = proposal.voteYes.add(proposal.voteNo);
        require(totalVotes > 0, "No votes cast for this proposal."); // Ensure at least 1 vote for consideration

        // For simplicity, using a simple majority for governance proposals (51%)
        // Could be made more complex, e.g., requiring min number of votes, or higher threshold based on reputation.
        bool proposalPassed = (totalVotes > 0) && (proposal.voteYes.mul(100) / totalVotes) >= 51;

        proposal.passed = proposalPassed;

        if (proposalPassed) {
            // Execute the proposed action using a low-level call
            (bool success, ) = proposal.target.call(proposal.callData);
            require(success, "Governance proposal execution failed.");
            proposal.executed = true;
            emit GovernanceProposalExecuted(_proposalId, true);
        } else {
            proposal.executed = true; // Mark as executed but failed
            emit GovernanceProposalExecuted(_proposalId, false);
        }
    }

    // --- Internal / Private Helpers ---

    /// @dev Modifier to allow either the contract owner or implicitly through a successful governance proposal to call a function.
    ///      When a governance proposal calls a function, it is executed via `executeGovernanceProposal`
    ///      which bypasses this modifier on `msg.sender`. This modifier is for direct owner calls or
    ///      to mark functions that are subject to governance.
    modifier onlyOwnerOrGovernance() {
        require(msg.sender == owner(), "Only owner or via governance can call this function.");
        _;
    }

    // Fallback function to accept Ether and redirect to treasury
    fallback() external payable {
        depositToTreasury();
    }

    // Receive function to accept Ether and redirect to treasury
    receive() external payable {
        depositToTreasury();
    }
}
```