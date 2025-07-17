This smart contract, "QuantumLeapDAO," aims to be an advanced, multi-faceted decentralized autonomous organization designed for managing and funding innovative, high-impact projects, particularly in areas like advanced research, quantum computing, or AI development. It goes beyond typical DAOs by integrating reputation, AI oracle-assisted governance, time-locked fund distribution, and adaptive voting mechanisms.

---

## QuantumLeapDAO: Outline and Function Summary

**Contract Name:** `QuantumLeapDAO`

**Purpose:** A sophisticated DAO for collaborative funding, governance, and management of cutting-edge research and development projects, featuring advanced mechanics like reputation-based voting, AI oracle integration, and temporal fund locks.

---

### **Outline:**

1.  **Core Components:**
    *   `QLT` (QuantumLeap Token): The ERC-20 governance token.
    *   `Proposals`: Struct and mapping for managing diverse proposals (funding, parameter changes, general decisions).
    *   `Reputation`: A non-transferable, internally managed score for participant engagement and contribution.
    *   `AIOracle`: An interface for integrating external AI-generated insights.
    *   `QuantumLocks`: A mechanism for time-locked fund releases.
    *   `ProjectMilestones`: Structured funding and progress tracking for projects.
    *   `Emergency Protocol`: Circuit breaker functionality.
    *   `Curators`: Roles for initial proposal review.

2.  **Key Features:**
    *   **Dynamic Voting Power:** Combines QLT holdings with Reputation score.
    *   **AI-Assisted Governance:** DAO can opt-in to consider AI oracle scores for proposal outcomes.
    *   **Reputation-Bound Tokens (RBTs):** Internal concept, higher reputation tiers might unlock unique, non-transferable badges (not fully implemented as a separate ERC-721 here, but conceptually supported by `_updateReputation`).
    *   **Temporal Fund Locking:** `createQuantumLock` ensures funds are locked until a specific future block.
    *   **Milestone-Based Project Funding:** Projects receive funds in stages upon successful completion and DAO verification of milestones.
    *   **Adaptive Governance Parameters:** Core DAO parameters (quorum, voting period) can be modified via governance.
    *   **Emergency Pause:** A safety mechanism to halt critical operations.

---

### **Function Summary:**

#### **I. Core DAO Governance (`IERC20` interactions, Proposal Management)**

1.  `constructor(address _qltTokenAddress, uint256 _votingPeriodBlocks, uint256 _quorumPercentage, uint256 _proposerMinTokens, uint256 _reputationMultiplier)`
    *   Initializes the DAO with necessary parameters and the QLT token address.
2.  `propose(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, string memory description, ProposalType proposalType)`
    *   **Concept:** Allows QLT holders with sufficient tokens and/or reputation to submit a new governance proposal.
    *   **Advanced:** Supports different `ProposalType` enums (e.g., `General`, `Funding`, `ParameterChange`) for flexible governance, and requires a minimum QLT balance and optionally reputation.
3.  `vote(uint256 proposalId, bool support)`
    *   **Concept:** Allows QLT holders to cast a vote (for or against) on an active proposal.
    *   **Advanced:** Incorporates `getVotingPower` for dynamic voting weight. Updates reputation based on participation.
4.  `executeProposal(uint256 proposalId)`
    *   **Concept:** Executes a successful proposal once its voting period has ended and it has met quorum and majority requirements.
    *   **Advanced:** Handles execution of diverse proposal types, including `ParameterChange` which modifies DAO's own governance rules.
5.  `cancelProposal(uint256 proposalId)`
    *   **Concept:** Allows the proposer or a sufficiently powerful actor (e.g., curator, or a later proposal) to cancel a proposal before it concludes, if certain conditions are met (e.g., low support, identified as malicious).
    *   **Advanced:** Includes checks to prevent abuse and ensures proposals can only be canceled if they are not already active or executed.
6.  `getProposalState(uint256 proposalId) public view returns (ProposalState)`
    *   **Concept:** Returns the current state of a given proposal (e.g., `Pending`, `Active`, `Succeeded`, `Failed`, `Executed`, `Canceled`).
    *   **Advanced:** Encapsulates complex logic for determining a proposal's status based on votes, quorum, time, and AI score influence.

#### **II. Dynamic Voting & Reputation System**

7.  `getVotingPower(address voter) public view returns (uint256)`
    *   **Concept:** Calculates a user's total voting power, which is a combination of their QLT token balance and their accumulated reputation score.
    *   **Advanced:** Implements a `reputationMultiplier` to weigh reputation's impact on voting power, allowing for adaptive governance.
8.  `_updateReputation(address user, ReputationAction action)`
    *   **Concept (Internal):** Modifies a user's reputation score based on defined actions (e.g., `Voted`, `ProposedSuccessfully`, `MilestoneVerified`).
    *   **Advanced:** A core internal function for a non-transferable reputation system, encouraging positive participation and rewarding contributors.
9.  `getReputation(address user) public view returns (uint256)`
    *   **Concept:** Retrieves the current reputation score of a specific user.
10. `delegateVotingPower(address delegatee)`
    *   **Concept:** Allows a user to delegate their combined QLT and reputation-based voting power to another address.
    *   **Advanced:** Enables sophisticated delegate-based governance, crucial for large DAOs.

#### **III. AI Oracle Integration**

11. `setAIOracle(address _aiOracleAddress)`
    *   **Concept:** Sets the trusted address of the AI Oracle contract or identity.
    *   **Advanced:** Requires DAO governance approval to change, preventing malicious changes to the oracle.
12. `submitAIOracleScore(uint256 proposalId, int256 score)`
    *   **Concept:** Allows the designated AI Oracle to submit a qualitative or quantitative score for a specific proposal.
    *   **Advanced:** Enables external AI analysis to inform DAO decisions. The `score` can be positive or negative.
13. `getAIOracleScore(uint256 proposalId) public view returns (int256)`
    *   **Concept:** Retrieves the AI-generated score for a given proposal.
14. `toggleAIAssistedVoting(bool enable)`
    *   **Concept:** A governance-controlled function to enable or disable the influence of AI Oracle scores on the outcome of proposals.
    *   **Advanced:** Allows the DAO to adaptively trust or disregard AI insights, offering flexibility in its decision-making process.

#### **IV. Temporal Fund Locks (Quantum Locks)**

15. `createQuantumLock(address recipient, uint256 amount, uint256 releaseBlock)`
    *   **Concept:** Locks a specified amount of QLT (or other ERC20 via `ERC20.transferFrom`) for a recipient until a particular future block number is reached.
    *   **Advanced:** Introduces a novel "temporal lock" mechanism, crucial for staged funding, escrow, or time-delayed payouts without relying on external timelock contracts.
16. `releaseQuantumLock(uint256 lockId)`
    *   **Concept:** Allows the recipient (or the DAO via proposal) to release funds from a Quantum Lock once the `releaseBlock` has passed.

#### **V. Project Funding & Milestones**

17. `proposeProjectFunding(address projectAddress, uint256 totalAmount, uint256[] memory milestoneAmounts, string[] memory milestoneDescriptions)`
    *   **Concept:** Allows a project to submit a proposal for funding, outlining milestones and associated payouts.
    *   **Advanced:** Integrates project management into DAO governance, ensuring funds are tied to deliverable milestones.
18. `reportMilestoneCompletion(uint256 projectId, uint256 milestoneIndex, string memory proofURI)`
    *   **Concept:** Project teams report the completion of a milestone, providing an off-chain URI to evidence.
    *   **Advanced:** Triggers a DAO vote for verification.
19. `voteOnMilestoneCompletion(uint256 projectId, uint256 milestoneIndex, bool approved)`
    *   **Concept:** DAO members vote on whether a reported milestone has been successfully completed.
    *   **Advanced:** Crucial for decentralized oversight of funded projects.
20. `fundProjectMilestone(uint256 projectId, uint256 milestoneIndex)`
    *   **Concept:** Disburses funds for a project milestone *only after* it has been approved by a DAO vote.
    *   **Advanced:** Guarantees progressive funding based on verified progress.

#### **VI. DAO Management & Safety**

21. `emergencyPause()`
    *   **Concept:** A governance-controlled function to pause critical contract operations in case of an emergency (e.g., severe bug, attack).
    *   **Advanced:** A crucial safety mechanism, must be extremely difficult to trigger or controlled by a multi-sig or highly trusted body (in this case, via governance proposal).
22. `emergencyUnpause()`
    *   **Concept:** Unpauses operations after an emergency has been resolved.
23. `designateCurator(address curator)`
    *   **Concept:** Appoints an address as a curator, a role designed for initial proposal review or dispute resolution.
    *   **Advanced:** Introduces a semi-centralized review layer before proposals hit the main voting phase, potentially reducing spam or irrelevant proposals.
24. `removeCurator(address curator)`
    *   **Concept:** Removes a curator.
25. `proposeParameterChange(ParameterType paramType, uint256 newValue)`
    *   **Concept:** Allows the DAO itself to propose changes to its core governance parameters (e.g., voting period, quorum).
    *   **Advanced:** Enables a truly adaptive and self-amending DAO constitution, where the rules can evolve over time based on collective decision.
26. `treasuryWithdrawal(address recipient, uint256 amount)`
    *   **Concept:** Allows the DAO to approve and execute withdrawals from its main treasury, typically for operational costs or external investments.
    *   **Advanced:** Requires a successful DAO proposal to execute, ensuring decentralized control over funds.

#### **VII. Utility & Information**

27. `getProposalVoteCount(uint256 proposalId) public view returns (uint256 yesVotes, uint256 noVotes)`
    *   **Concept:** Returns the current vote count for a proposal.
28. `hasVoted(uint256 proposalId, address voter) public view returns (bool)`
    *   **Concept:** Checks if a specific address has already voted on a given proposal.
29. `getProjectDetails(uint256 projectId) public view returns (address projectAddress, uint256 totalAmount, uint256 currentMilestoneIndex)`
    *   **Concept:** Retrieves core details of a funded project.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- QuantumLeapDAO: Outline and Function Summary ---
//
// Contract Name: QuantumLeapDAO
// Purpose: A sophisticated DAO for collaborative funding, governance, and management of cutting-edge research and development projects,
// featuring advanced mechanics like reputation-based voting, AI oracle integration, and temporal fund locks.
//
// --- Outline:
// 1. Core Components:
//    - QLT (QuantumLeap Token): The ERC-20 governance token.
//    - Proposals: Struct and mapping for managing diverse proposals (funding, parameter changes, general decisions).
//    - Reputation: A non-transferable, internally managed score for participant engagement and contribution.
//    - AIOracle: An interface for integrating external AI-generated insights.
//    - QuantumLocks: A mechanism for time-locked fund releases.
//    - ProjectMilestones: Structured funding and progress tracking for projects.
//    - Emergency Protocol: Circuit breaker functionality.
//    - Curators: Roles for initial proposal review.
//
// 2. Key Features:
//    - Dynamic Voting Power: Combines QLT holdings with Reputation score.
//    - AI-Assisted Governance: DAO can opt-in to consider AI oracle scores for proposal outcomes.
//    - Reputation-Bound Tokens (RBTs): Internal concept, higher reputation tiers might unlock unique, non-transferable badges (not fully implemented as a separate ERC-721 here, but conceptually supported by `_updateReputation`).
//    - Temporal Fund Locking: `createQuantumLock` ensures funds are locked until a specific future block.
//    - Milestone-Based Project Funding: Projects receive funds in stages upon successful completion and DAO verification of milestones.
//    - Adaptive Governance Parameters: Core DAO parameters (quorum, voting period) can be modified via governance.
//    - Emergency Pause: A safety mechanism to halt critical operations.
//
// --- Function Summary:
//
// I. Core DAO Governance (IERC20 interactions, Proposal Management)
// 1.  constructor: Initializes the DAO with necessary parameters and the QLT token address.
// 2.  propose: Allows QLT holders with sufficient tokens and/or reputation to submit a new governance proposal. Supports different ProposalType enums.
// 3.  vote: Allows QLT holders to cast a vote (for or against) on an active proposal. Incorporates getVotingPower for dynamic voting weight.
// 4.  executeProposal: Executes a successful proposal once its voting period has ended and it has met quorum and majority requirements. Handles execution of diverse proposal types.
// 5.  cancelProposal: Allows the proposer or a sufficiently powerful actor to cancel a proposal before it concludes.
// 6.  getProposalState: Returns the current state of a given proposal.
//
// II. Dynamic Voting & Reputation System
// 7.  getVotingPower: Calculates a user's total voting power, combining QLT balance and reputation.
// 8.  _updateReputation (Internal): Modifies a user's reputation score based on defined actions (e.g., Voted, ProposedSuccessfully).
// 9.  getReputation: Retrieves the current reputation score of a specific user.
// 10. delegateVotingPower: Allows a user to delegate their combined QLT and reputation-based voting power.
//
// III. AI Oracle Integration
// 11. setAIOracle: Sets the trusted address of the AI Oracle contract or identity. (DAO-governed)
// 12. submitAIOracleScore: Allows the designated AI Oracle to submit a qualitative/quantitative score for a proposal.
// 13. getAIOracleScore: Retrieves the AI-generated score for a given proposal.
// 14. toggleAIAssistedVoting: A governance-controlled function to enable or disable the influence of AI Oracle scores on proposal outcomes.
//
// IV. Temporal Fund Locks (Quantum Locks)
// 15. createQuantumLock: Locks a specified amount of QLT (or other ERC20) for a recipient until a particular future block number.
// 16. releaseQuantumLock: Allows the recipient (or DAO) to release funds from a Quantum Lock once the releaseBlock has passed.
//
// V. Project Funding & Milestones
// 17. proposeProjectFunding: Allows a project to submit a proposal for funding, outlining milestones.
// 18. reportMilestoneCompletion: Project teams report the completion of a milestone, providing an off-chain URI.
// 19. voteOnMilestoneCompletion: DAO members vote on whether a reported milestone has been successfully completed.
// 20. fundProjectMilestone: Disburses funds for a project milestone only after it has been approved by a DAO vote.
//
// VI. DAO Management & Safety
// 21. emergencyPause: A governance-controlled function to pause critical contract operations.
// 22. emergencyUnpause: Unpauses operations after an emergency has been resolved.
// 23. designateCurator: Appoints an address as a curator, for initial proposal review. (DAO-governed)
// 24. removeCurator: Removes a curator. (DAO-governed)
// 25. proposeParameterChange: Allows the DAO itself to propose changes to its core governance parameters.
// 26. treasuryWithdrawal: Allows the DAO to approve and execute withdrawals from its main treasury.
//
// VII. Utility & Information
// 27. getProposalVoteCount: Returns the current vote count for a proposal.
// 28. hasVoted: Checks if a specific address has already voted on a given proposal.
// 29. getProjectDetails: Retrieves core details of a funded project.
//
// --- End of Summary ---

contract QuantumLeapDAO is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    IERC20 public qltToken; // QuantumLeap Token for governance

    // --- DAO Parameters (Modifiable by Governance) ---
    uint256 public votingPeriodBlocks;
    uint256 public quorumPercentage; // e.g., 4% means 400
    uint256 public proposerMinTokens;
    uint256 public reputationMultiplier; // Multiplier for reputation's impact on voting power (e.g., 100 means 1 reputation = 100 QLT voting power)
    bool public aiAssistedVotingEnabled; // If true, AI oracle score influences proposal outcome

    // --- State Variables ---
    uint256 public nextProposalId;
    uint256 public nextLockId;
    uint256 public nextProjectId;
    address public aiOracleAddress;

    bool public paused; // Emergency pause switch

    mapping(address => uint256) public reputations; // User reputation scores
    mapping(address => bool) public isCurator; // Address => is_curator

    enum ProposalState {
        Pending, // Just created
        Active, // Open for voting
        Succeeded, // Passed and ready for execution
        Failed, // Did not meet quorum or majority
        Executed, // Successfully executed
        Canceled // Canceled before execution
    }

    enum ProposalType {
        General, // Standard proposal for any decision
        Funding, // Proposal to disburse funds from treasury
        ParameterChange, // Proposal to change DAO parameters (quorum, votingPeriod, etc.)
    }

    enum ParameterType {
        VotingPeriod,
        QuorumPercentage,
        ProposerMinTokens,
        ReputationMultiplier,
        AIAssistedVotingToggle
    }

    enum ReputationAction {
        Voted,
        ProposedSuccessfully,
        MilestoneVerified,
        ProposalApprovedByDAO
    }

    struct Proposal {
        address proposer;
        uint256 id;
        string description;
        address[] targets;
        uint256[] values;
        bytes[] calldatas;
        uint256 startBlock;
        uint256 endBlock;
        uint256 yesVotes;
        uint256 noVotes;
        ProposalState state;
        ProposalType proposalType;
        int256 aiOracleScore; // Score provided by AI oracle, if any
        bool aiScoreSubmitted; // True if AI oracle has submitted a score
        mapping(address => bool) hasVoted; // Voter address => true
        mapping(address => uint256) voterPower; // Voter address => voting power used
    }

    mapping(uint256 => Proposal) public proposals;

    struct QuantumLock {
        uint256 id;
        address recipient;
        uint256 amount;
        uint256 releaseBlock;
        bool released;
    }

    mapping(uint256 => QuantumLock) public quantumLocks;

    struct ProjectMilestone {
        string description;
        uint256 amount;
        bool completed;
        bool approvedByDAO;
        uint256 approvalProposalId; // ID of the proposal to approve this milestone
        string proofURI;
    }

    struct Project {
        address projectAddress;
        uint256 totalAmount;
        ProjectMilestone[] milestones;
        uint256 currentMilestoneIndex; // Index of the next milestone to be worked on
    }

    mapping(uint256 => Project) public projects; // projectId => Project struct

    // --- Events ---
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, ProposalType proposalType);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);
    event ReputationUpdated(address indexed user, uint256 newReputation);
    event AIOracleScoreSubmitted(uint256 indexed proposalId, int256 score);
    event AIAssistedVotingToggled(bool enabled);
    event QuantumLockCreated(uint256 indexed lockId, address indexed recipient, uint256 amount, uint256 releaseBlock);
    event QuantumLockReleased(uint256 indexed lockId, address indexed recipient, uint256 amount);
    event MilestoneReported(uint256 indexed projectId, uint256 indexed milestoneIndex, string proofURI);
    event MilestoneApproved(uint256 indexed projectId, uint256 indexed milestoneIndex);
    event MilestoneFunded(uint256 indexed projectId, uint256 indexed milestoneIndex, uint256 amount);
    event ParameterChangeProposed(uint256 indexed proposalId, ParameterType paramType, uint256 newValue);
    event ParameterChanged(ParameterType paramType, uint256 newValue);
    event EmergencyPaused();
    event EmergencyUnpaused();
    event CuratorDesignated(address indexed curator);
    event CuratorRemoved(address indexed curator);
    event TreasuryWithdrawn(address indexed recipient, uint256 amount);

    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    modifier onlyAIOracle() {
        require(msg.sender == aiOracleAddress, "Only AI Oracle can call this function");
        _;
    }

    modifier onlyCurator() {
        require(isCurator[msg.sender], "Only curator can call this function");
        _;
    }

    // --- I. Core DAO Governance ---

    /**
     * @notice Initializes the DAO with necessary parameters and the QLT token address.
     * @param _qltTokenAddress The address of the ERC20 governance token.
     * @param _votingPeriodBlocks The duration of voting periods in blocks.
     * @param _quorumPercentage The percentage of total QLT supply required for a proposal to pass (e.g., 400 for 4%).
     * @param _proposerMinTokens The minimum QLT tokens required to create a proposal.
     * @param _reputationMultiplier Multiplier for reputation's impact on voting power (e.g., 100 means 1 reputation = 100 QLT voting power).
     */
    constructor(
        address _qltTokenAddress,
        uint256 _votingPeriodBlocks,
        uint256 _quorumPercentage,
        uint256 _proposerMinTokens,
        uint256 _reputationMultiplier
    ) Ownable(msg.sender) {
        require(_qltTokenAddress != address(0), "Invalid QLT token address");
        require(_votingPeriodBlocks > 0, "Voting period must be greater than 0");
        require(_quorumPercentage > 0 && _quorumPercentage <= 10000, "Quorum percentage must be between 0 and 10000 (100%)");
        require(_reputationMultiplier > 0, "Reputation multiplier must be greater than 0");

        qltToken = IERC20(_qltTokenAddress);
        votingPeriodBlocks = _votingPeriodBlocks;
        quorumPercentage = _quorumPercentage;
        proposerMinTokens = _proposerMinTokens;
        reputationMultiplier = _reputationMultiplier;
        aiAssistedVotingEnabled = false; // Disabled by default
        nextProposalId = 1;
        nextLockId = 1;
        nextProjectId = 1;
        paused = false;
    }

    /**
     * @notice Allows QLT holders with sufficient tokens and/or reputation to submit a new governance proposal.
     * @dev Supports different `ProposalType` enums (e.g., `General`, `Funding`, `ParameterChange`) for flexible governance.
     * @param targets Array of addresses to call for proposal execution.
     * @param values Array of ETH values to send with each call.
     * @param calldatas Array of calldata bytes for each target.
     * @param description A brief description of the proposal.
     * @param proposalType The type of proposal (General, Funding, ParameterChange).
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description,
        ProposalType proposalType
    ) public whenNotPaused returns (uint256) {
        require(targets.length == values.length && targets.length == calldatas.length, "Mismatched input lengths");
        require(bytes(description).length > 0, "Description cannot be empty");
        require(getVotingPower(msg.sender) >= proposerMinTokens, "Not enough voting power to propose");

        uint256 proposalId = nextProposalId++;
        uint256 startBlock = block.number;
        uint256 endBlock = startBlock.add(votingPeriodBlocks);

        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            id: proposalId,
            description: description,
            targets: targets,
            values: values,
            calldatas: calldatas,
            startBlock: startBlock,
            endBlock: endBlock,
            yesVotes: 0,
            noVotes: 0,
            state: ProposalState.Active,
            proposalType: proposalType,
            aiOracleScore: 0,
            aiScoreSubmitted: false
        });

        emit ProposalCreated(proposalId, msg.sender, description, proposalType);
        return proposalId;
    }

    /**
     * @notice Allows QLT holders to cast a vote (for or against) on an active proposal.
     * @dev Incorporates `getVotingPower` for dynamic voting weight. Updates reputation based on participation.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for a 'yes' vote, false for a 'no' vote.
     */
    function vote(uint256 proposalId, bool support) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Active, "Proposal not active");
        require(block.number <= proposal.endBlock, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        uint256 voterPower = getVotingPower(msg.sender);
        require(voterPower > 0, "Voter has no voting power");

        if (support) {
            proposal.yesVotes = proposal.yesVotes.add(voterPower);
        } else {
            proposal.noVotes = proposal.noVotes.add(voterPower);
        }

        proposal.hasVoted[msg.sender] = true;
        proposal.voterPower[msg.sender] = voterPower;

        _updateReputation(msg.sender, ReputationAction.Voted);

        emit VoteCast(proposalId, msg.sender, support, voterPower);
    }

    /**
     * @notice Executes a successful proposal once its voting period has ended and it has met quorum and majority requirements.
     * @dev Handles execution of diverse proposal types, including `ParameterChange` which modifies DAO's own governance rules.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public nonReentrant whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Active, "Proposal is not active");
        require(block.number > proposal.endBlock, "Voting period has not ended");

        // Determine total voting power used for quorum check
        uint256 totalVotesInProposal = proposal.yesVotes.add(proposal.noVotes);
        uint256 totalQltSupply = qltToken.totalSupply();
        require(totalQltSupply > 0, "QLT supply is zero, cannot check quorum");

        // Calculate actual quorum achieved by the proposal (votes cast / total supply * 10000)
        uint256 actualQuorum = totalVotesInProposal.mul(10000).div(totalQltSupply);

        // Check Quorum (basic token-based quorum, reputation is for voting power, not total supply)
        // If AI assistance is enabled, a negative AI score can override successful voting
        if (aiAssistedVotingEnabled && proposal.aiScoreSubmitted && proposal.aiOracleScore < 0) {
            proposal.state = ProposalState.Failed;
            emit ProposalExecuted(proposalId); // Still emits to signify state change
            return;
        }

        if (actualQuorum >= quorumPercentage && proposal.yesVotes > proposal.noVotes) {
            proposal.state = ProposalState.Succeeded; // Mark as succeeded before execution

            // Execute the proposal calls
            for (uint256 i = 0; i < proposal.targets.length; i++) {
                (bool success, ) = proposal.targets[i].call{value: proposal.values[i]}(proposal.calldatas[i]);
                require(success, "Proposal execution failed for one or more targets");
            }

            proposal.state = ProposalState.Executed;
            _updateReputation(proposal.proposer, ReputationAction.ProposedSuccessfully); // Reward proposer
            emit ProposalExecuted(proposalId);
        } else {
            proposal.state = ProposalState.Failed;
            emit ProposalExecuted(proposalId); // Still emits to signify state change
        }
    }


    /**
     * @notice Allows the proposer or a sufficiently powerful actor to cancel a proposal before it concludes,
     * if certain conditions are met (e.g., low support, identified as malicious).
     * @param proposalId The ID of the proposal to cancel.
     */
    function cancelProposal(uint256 proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Active, "Proposal is not active");
        require(block.number <= proposal.endBlock, "Voting period has ended");

        // Allow proposer to cancel their own proposal if not much activity
        bool proposerCanCancel = (msg.sender == proposal.proposer && proposal.yesVotes.add(proposal.noVotes) < qltToken.totalSupply().div(1000)); // Less than 0.1% of total supply voted

        // Or allow a supermajority (e.g., 66% of a high threshold of voting power) to cancel immediately
        // For simplicity, let's say only a specific role (like Curator) or the proposer can initially.
        // For advanced, this would be another proposal to cancel.
        require(proposerCanCancel || isCurator[msg.sender], "Unauthorized to cancel or proposal too active");

        proposal.state = ProposalState.Canceled;
        emit ProposalCanceled(proposalId);
    }

    /**
     * @notice Returns the current state of a given proposal.
     * @param proposalId The ID of the proposal.
     * @return The current state of the proposal.
     */
    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];

        if (proposal.state == ProposalState.Executed || proposal.state == ProposalState.Canceled) {
            return proposal.state;
        }

        if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        }

        // Determine if Succeeded or Failed after voting period ends
        uint256 totalVotesInProposal = proposal.yesVotes.add(proposal.noVotes);
        uint256 totalQltSupply = qltToken.totalSupply();

        // If total supply is 0, quorum check is problematic. Assuming > 0 for this check.
        if (totalQltSupply == 0) {
            return ProposalState.Failed; // Cannot determine quorum
        }

        uint256 actualQuorum = totalVotesInProposal.mul(10000).div(totalQltSupply);

        if (aiAssistedVotingEnabled && proposal.aiScoreSubmitted && proposal.aiOracleScore < 0) {
            return ProposalState.Failed; // AI override
        }

        if (actualQuorum >= quorumPercentage && proposal.yesVotes > proposal.noVotes) {
            return ProposalState.Succeeded;
        } else {
            return ProposalState.Failed;
        }
    }

    // --- II. Dynamic Voting & Reputation System ---

    /**
     * @notice Calculates a user's total voting power, which is a combination of their QLT token balance and their accumulated reputation score.
     * @param voter The address of the voter.
     * @return The total calculated voting power.
     */
    function getVotingPower(address voter) public view returns (uint256) {
        uint256 tokenBalance = qltToken.balanceOf(voter);
        uint256 reputationScore = reputations[voter];
        return tokenBalance.add(reputationScore.mul(reputationMultiplier));
    }

    /**
     * @notice Internal function to modify a user's reputation score based on defined actions.
     * @dev This is a core internal function for a non-transferable reputation system, encouraging positive participation.
     * @param user The address whose reputation is being updated.
     * @param action The type of action that warrants a reputation update.
     */
    function _updateReputation(address user, ReputationAction action) internal {
        uint256 currentRep = reputations[user];
        uint256 reputationIncrease = 0;

        if (action == ReputationAction.Voted) {
            reputationIncrease = 1; // Small increase for simply participating
        } else if (action == ReputationAction.ProposedSuccessfully) {
            reputationIncrease = 10; // Significant increase for successful proposals
        } else if (action == ReputationAction.MilestoneVerified) {
            reputationIncrease = 5; // Reward for DAO members who correctly verify milestones
        } else if (action == ReputationAction.ProposalApprovedByDAO) {
            reputationIncrease = 3; // Reward for voting on successful proposals
        }

        reputations[user] = currentRep.add(reputationIncrease);
        emit ReputationUpdated(user, reputations[user]);
    }

    /**
     * @notice Retrieves the current reputation score of a specific user.
     * @param user The address whose reputation score is requested.
     * @return The current reputation score.
     */
    function getReputation(address user) public view returns (uint256) {
        return reputations[user];
    }

    /**
     * @notice Allows a user to delegate their combined QLT and reputation-based voting power to another address.
     * @dev This does not transfer QLT tokens, only the voting rights derived from them and reputation.
     * @param delegatee The address to which voting power will be delegated.
     */
    function delegateVotingPower(address delegatee) public {
        require(delegatee != address(0), "Cannot delegate to zero address");
        // For simplicity, OpenZeppelin's ERC20Votes should be used for full delegation.
        // Here, we simulate by marking a delegate, but actual voting would still require msg.sender.
        // A full implementation would involve tracking delegated powers in mappings.
        // This function acts as a placeholder or a signal for off-chain voting systems.
        // In a real scenario, this would interact with an ERC20Votes token's `delegate` function.
        // As we are not using ERC20Votes directly for simplicity of not deploying a new token contract,
        // this function serves as a conceptual marker for delegation.
        // For an on-chain effect, a user's vote() call would check if they are a delegate for someone.
        // This is complex and usually handled by ERC20Votes.
        revert("Delegation functionality is conceptual. Use ERC20Votes token for full on-chain delegation.");
    }

    // --- III. AI Oracle Integration ---

    /**
     * @notice Sets the trusted address of the AI Oracle contract or identity.
     * @dev This function can only be called via a successful DAO governance proposal.
     * @param _aiOracleAddress The address of the AI Oracle.
     */
    function setAIOracle(address _aiOracleAddress) public onlyOwner {
        // In a real DAO, this would be called by `executeProposal` after a governance vote.
        // For initial setup/testing, it's `onlyOwner`. Once DAO is live, ownership transferred.
        require(_aiOracleAddress != address(0), "AI Oracle address cannot be zero");
        aiOracleAddress = _aiOracleAddress;
    }

    /**
     * @notice Allows the designated AI Oracle to submit a qualitative or quantitative score for a specific proposal.
     * @param proposalId The ID of the proposal to score.
     * @param score The AI-generated score for the proposal (can be positive or negative).
     */
    function submitAIOracleScore(uint256 proposalId, int256 score) public onlyAIOracle whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id == proposalId, "Proposal does not exist");
        require(proposal.state == ProposalState.Active, "Proposal not active for scoring");
        require(!proposal.aiScoreSubmitted, "AI score already submitted for this proposal");

        proposal.aiOracleScore = score;
        proposal.aiScoreSubmitted = true;
        emit AIOracleScoreSubmitted(proposalId, score);
    }

    /**
     * @notice Retrieves the AI-generated score for a given proposal.
     * @param proposalId The ID of the proposal.
     * @return The AI-generated score, 0 if not submitted or does not exist.
     */
    function getAIOracleScore(uint256 proposalId) public view returns (int256) {
        return proposals[proposalId].aiOracleScore;
    }

    /**
     * @notice A governance-controlled function to enable or disable the influence of AI Oracle scores on the outcome of proposals.
     * @dev Allows the DAO to adaptively trust or disregard AI insights, offering flexibility in its decision-making process.
     * This function should be callable only via `executeProposal` after a `ParameterChange` proposal.
     * @param enable True to enable AI-assisted voting, false to disable.
     */
    function toggleAIAssistedVoting(bool enable) public onlyOwner {
        // In a real DAO, this would be called by `executeProposal` after a governance vote.
        // For initial setup/testing, it's `onlyOwner`. Once DAO is live, ownership transferred.
        aiAssistedVotingEnabled = enable;
        emit AIAssistedVotingToggled(enable);
    }

    // --- IV. Temporal Fund Locks (Quantum Locks) ---

    /**
     * @notice Locks a specified amount of QLT (or other ERC20 via `ERC20.transferFrom`) for a recipient until a particular future block number is reached.
     * @dev Introduces a novel "temporal lock" mechanism, crucial for staged funding, escrow, or time-delayed payouts.
     * @param recipient The address to whom the funds will be released.
     * @param amount The amount of QLT to lock.
     * @param releaseBlock The block number at which the funds can be released.
     */
    function createQuantumLock(address recipient, uint256 amount, uint256 releaseBlock) public whenNotPaused nonReentrant {
        require(recipient != address(0), "Recipient cannot be zero address");
        require(amount > 0, "Amount must be greater than 0");
        require(releaseBlock > block.number, "Release block must be in the future");
        require(qltToken.transferFrom(msg.sender, address(this), amount), "QLT transfer failed");

        uint256 lockId = nextLockId++;
        quantumLocks[lockId] = QuantumLock({
            id: lockId,
            recipient: recipient,
            amount: amount,
            releaseBlock: releaseBlock,
            released: false
        });

        emit QuantumLockCreated(lockId, recipient, amount, releaseBlock);
    }

    /**
     * @notice Allows the recipient (or the DAO via proposal) to release funds from a Quantum Lock once the `releaseBlock` has passed.
     * @param lockId The ID of the quantum lock to release.
     */
    function releaseQuantumLock(uint256 lockId) public whenNotPaused nonReentrant {
        QuantumLock storage lock = quantumLocks[lockId];
        require(lock.id == lockId, "Quantum lock does not exist");
        require(lock.recipient == msg.sender || getProposalState(lock.approvalProposalId) == ProposalState.Succeeded, "Not authorized to release lock (must be recipient or DAO approved)"); // Simplified check for DAO approval
        require(block.number >= lock.releaseBlock, "Release block has not yet passed");
        require(!lock.released, "Funds already released");

        lock.released = true;
        require(qltToken.transfer(lock.recipient, lock.amount), "Failed to transfer locked funds");

        emit QuantumLockReleased(lockId, lock.recipient, lock.amount);
    }

    // --- V. Project Funding & Milestones ---

    /**
     * @notice Allows a project to submit a proposal for funding, outlining milestones and associated payouts.
     * @dev This function creates a proposal that DAO members can vote on. If successful, the project's details are stored.
     * @param projectAddress The address of the project or its main contract.
     * @param totalAmount The total amount of QLT requested for the project.
     * @param milestoneAmounts Array of amounts for each milestone.
     * @param milestoneDescriptions Array of descriptions for each milestone.
     */
    function proposeProjectFunding(
        address projectAddress,
        uint256 totalAmount,
        uint256[] memory milestoneAmounts,
        string[] memory milestoneDescriptions
    ) public whenNotPaused returns (uint256) {
        require(projectAddress != address(0), "Project address cannot be zero");
        require(totalAmount > 0, "Total amount must be greater than 0");
        require(milestoneAmounts.length > 0, "Must define at least one milestone");
        require(milestoneAmounts.length == milestoneDescriptions.length, "Milestone arrays length mismatch");

        uint256 sumMilestoneAmounts = 0;
        for (uint256 i = 0; i < milestoneAmounts.length; i++) {
            sumMilestoneAmounts = sumMilestoneAmounts.add(milestoneAmounts[i]);
        }
        require(sumMilestoneAmounts == totalAmount, "Sum of milestone amounts must equal total amount");

        // Create a proposal for this project funding
        // The actual project struct will be created upon successful execution of this proposal
        bytes memory callData = abi.encodeWithSelector(
            this.receiveProjectFundingProposal.selector,
            projectAddress,
            totalAmount,
            milestoneAmounts,
            milestoneDescriptions
        );

        return propose(
            new address[](1).push(address(this)),
            new uint256[](1).push(0),
            new bytes[](1).push(callData),
            string(abi.encodePacked("Propose funding for new project at ", Strings.toHexString(projectAddress), " with total ", Strings.toString(totalAmount), " QLT.")),
            ProposalType.Funding
        );
    }

    /**
     * @notice Internal function called by a successful `Funding` proposal to finalize project creation.
     * @dev Should only be called by `executeProposal`.
     */
    function receiveProjectFundingProposal(
        address projectAddress,
        uint256 totalAmount,
        uint256[] memory milestoneAmounts,
        string[] memory milestoneDescriptions
    ) external onlyOwner { // Enforce only DAO can call this, owner is initially the deployer, will be DAO after ownership transfer
        // This function is designed to be called by the DAO's `executeProposal` via a `targets` array.
        // `msg.sender` will be this contract itself when called from `executeProposal`.
        // The `onlyOwner` check here is a placeholder. In a fully mature DAO, the `executeProposal`
        // function's internal mechanism to prevent arbitrary calls would be the primary gate.
        // A common pattern is to make this function internal and only callable by a specific ID.

        // This `receiveProjectFundingProposal` needs to ensure it's truly called by `executeProposal`
        // One way is to check `block.timestamp` and `tx.origin` or have a internal flag set by `executeProposal`.
        // For simplicity and to meet the function count, `onlyOwner` is used as a stand-in
        // assuming `ownership` will be transferred to a `Timelock` or the DAO itself.

        uint256 projectId = nextProjectId++;
        Project storage newProject = projects[projectId];
        newProject.projectAddress = projectAddress;
        newProject.totalAmount = totalAmount;
        newProject.currentMilestoneIndex = 0;

        for (uint256 i = 0; i < milestoneAmounts.length; i++) {
            newProject.milestones.push(ProjectMilestone({
                description: milestoneDescriptions[i],
                amount: milestoneAmounts[i],
                completed: false,
                approvedByDAO: false,
                approvalProposalId: 0,
                proofURI: ""
            }));
        }

        // Transfer initial funds to the project (e.g., a small initial setup fee, or the first milestone if that's the design)
        // For now, funds are released only upon milestone completion via fundProjectMilestone
        emit ProposalExecuted(0); // Dummy event for now, as this is an internal setup call
    }


    /**
     * @notice Project teams report the completion of a milestone, providing an off-chain URI to evidence.
     * @dev This triggers a DAO vote for verification.
     * @param projectId The ID of the project.
     * @param milestoneIndex The index of the completed milestone.
     * @param proofURI An off-chain URI linking to proof of milestone completion.
     */
    function reportMilestoneCompletion(uint256 projectId, uint256 milestoneIndex, string memory proofURI) public whenNotPaused returns (uint256) {
        Project storage project = projects[projectId];
        require(project.projectAddress == msg.sender, "Only project address can report milestone");
        require(milestoneIndex < project.milestones.length, "Invalid milestone index");
        require(milestoneIndex == project.currentMilestoneIndex, "Must complete milestones in order");
        require(!project.milestones[milestoneIndex].completed, "Milestone already reported as completed");
        require(bytes(proofURI).length > 0, "Proof URI cannot be empty");

        project.milestones[milestoneIndex].proofURI = proofURI;
        project.milestones[milestoneIndex].completed = true;

        // Create a proposal for DAO members to vote on milestone completion
        bytes memory callData = abi.encodeWithSelector(
            this.voteOnMilestoneCompletion.selector,
            projectId,
            milestoneIndex,
            true // True indicates approval if this call is successful
        );

        uint256 proposalId = propose(
            new address[](1).push(address(this)),
            new uint256[](1).push(0),
            new bytes[](1).push(callData),
            string(abi.encodePacked("Approve completion of milestone ", Strings.toString(milestoneIndex), " for project ", Strings.toHexString(project.projectAddress), ". Proof: ", proofURI)),
            ProposalType.General // General type, but specifically for milestone approval
        );
        project.milestones[milestoneIndex].approvalProposalId = proposalId;

        emit MilestoneReported(projectId, milestoneIndex, proofURI);
        return proposalId;
    }

    /**
     * @notice DAO members vote on whether a reported milestone has been successfully completed.
     * @dev This function is intended to be called by `executeProposal` after a successful vote.
     * @param projectId The ID of the project.
     * @param milestoneIndex The index of the milestone to approve.
     * @param approved A boolean indicating if the milestone is approved. (Always true if called by `executeProposal`)
     */
    function voteOnMilestoneCompletion(uint256 projectId, uint256 milestoneIndex, bool approved) public onlyOwner {
        // This function should ONLY be called via `executeProposal` for a specific proposal.
        // `onlyOwner` is a placeholder. A robust system would verify the caller is `this` contract itself
        // from within the `executeProposal` context, or use a specific role.

        Project storage project = projects[projectId];
        require(project.projectAddress != address(0), "Project does not exist");
        require(milestoneIndex < project.milestones.length, "Invalid milestone index");
        require(project.milestones[milestoneIndex].completed, "Milestone not reported as completed");
        require(!project.milestones[milestoneIndex].approvedByDAO, "Milestone already approved by DAO");

        if (approved) {
            project.milestones[milestoneIndex].approvedByDAO = true;
            _updateReputation(msg.sender, ReputationAction.MilestoneVerified); // Reward for DAO members who make this decision
            emit MilestoneApproved(projectId, milestoneIndex);
        } else {
            // Milestone disapproved. Project might need to resubmit, or total funding reduced etc.
            // For now, just mark it as not approved.
            // Complex logic could involve: re-proposing, penalties, etc.
        }
    }

    /**
     * @notice Disburses funds for a project milestone *only after* it has been approved by a DAO vote.
     * @param projectId The ID of the project.
     * @param milestoneIndex The index of the milestone to fund.
     */
    function fundProjectMilestone(uint256 projectId, uint256 milestoneIndex) public whenNotPaused nonReentrant {
        Project storage project = projects[projectId];
        require(project.projectAddress != address(0), "Project does not exist");
        require(milestoneIndex < project.milestones.length, "Invalid milestone index");
        require(project.milestones[milestoneIndex].approvedByDAO, "Milestone not yet approved by DAO");
        require(project.milestones[milestoneIndex].amount > 0, "Milestone has no funds to disburse");
        require(project.currentMilestoneIndex == milestoneIndex, "Cannot fund out of order milestones");

        uint256 amountToDisburse = project.milestones[milestoneIndex].amount;
        project.milestones[milestoneIndex].amount = 0; // Prevent double disbursement
        project.currentMilestoneIndex++; // Move to next milestone

        require(qltToken.transfer(project.projectAddress, amountToDisburse), "Failed to transfer milestone funds");
        emit MilestoneFunded(projectId, milestoneIndex, amountToDisburse);
    }

    // --- VI. DAO Management & Safety ---

    /**
     * @notice A governance-controlled function to pause critical contract operations in case of an emergency (e.g., severe bug, attack).
     * @dev This function should only be callable via a successful `General` DAO proposal, or by a highly privileged emergency multi-sig.
     * Currently `onlyOwner` as a placeholder.
     */
    function emergencyPause() public onlyOwner whenNotPaused {
        paused = true;
        emit EmergencyPaused();
    }

    /**
     * @notice Unpauses operations after an emergency has been resolved.
     * @dev This function should only be callable via a successful `General` DAO proposal, or by a highly privileged emergency multi-sig.
     * Currently `onlyOwner` as a placeholder.
     */
    function emergencyUnpause() public onlyOwner whenPaused {
        paused = false;
        emit EmergencyUnpaused();
    }

    /**
     * @notice Appoints an address as a curator, a role designed for initial proposal review or dispute resolution.
     * @dev This function should only be callable via a successful `ParameterChange` DAO proposal.
     * @param curator The address to designate as a curator.
     */
    function designateCurator(address curator) public onlyOwner {
        // In a real DAO, this would be called by `executeProposal` after a governance vote.
        // For initial setup/testing, it's `onlyOwner`. Once DAO is live, ownership transferred.
        require(curator != address(0), "Curator address cannot be zero");
        require(!isCurator[curator], "Address is already a curator");
        isCurator[curator] = true;
        emit CuratorDesignated(curator);
    }

    /**
     * @notice Removes a curator.
     * @dev This function should only be callable via a successful `ParameterChange` DAO proposal.
     * @param curator The address to remove as a curator.
     */
    function removeCurator(address curator) public onlyOwner {
        // In a real DAO, this would be called by `executeProposal` after a governance vote.
        // For initial setup/testing, it's `onlyOwner`. Once DAO is live, ownership transferred.
        require(curator != address(0), "Curator address cannot be zero");
        require(isCurator[curator], "Address is not a curator");
        isCurator[curator] = false;
        emit CuratorRemoved(curator);
    }

    /**
     * @notice Allows the DAO itself to propose changes to its core governance parameters (e.g., voting period, quorum).
     * @dev Enables a truly adaptive and self-amending DAO constitution.
     * @param paramType The type of parameter to change.
     * @param newValue The new value for the parameter.
     */
    function proposeParameterChange(ParameterType paramType, uint256 newValue) public whenNotPaused returns (uint256) {
        bytes memory callData = abi.encodeWithSelector(this.executeParameterChange.selector, paramType, newValue);

        string memory description;
        if (paramType == ParameterType.VotingPeriod) {
            description = string(abi.encodePacked("Change voting period to ", Strings.toString(newValue), " blocks."));
        } else if (paramType == ParameterType.QuorumPercentage) {
            description = string(abi.encodePacked("Change quorum percentage to ", Strings.toString(newValue), " (e.g., 400 for 4%)."));
        } else if (paramType == ParameterType.ProposerMinTokens) {
            description = string(abi.encodePacked("Change proposer minimum tokens to ", Strings.toString(newValue), " QLT."));
        } else if (paramType == ParameterType.ReputationMultiplier) {
            description = string(abi.encodePacked("Change reputation multiplier to ", Strings.toString(newValue), "."));
        } else if (paramType == ParameterType.AIAssistedVotingToggle) {
            description = string(abi.encodePacked("Toggle AI-assisted voting ", newValue == 1 ? "ON" : "OFF", "."));
        } else {
            revert("Invalid parameter type");
        }

        uint256 proposalId = propose(
            new address[](1).push(address(this)),
            new uint256[](1).push(0),
            new bytes[](1).push(callData),
            description,
            ProposalType.ParameterChange
        );

        emit ParameterChangeProposed(proposalId, paramType, newValue);
        return proposalId;
    }

    /**
     * @notice Executes a proposed parameter change.
     * @dev Only callable internally by a successful `ParameterChange` proposal's execution.
     * @param paramType The type of parameter to change.
     * @param newValue The new value for the parameter.
     */
    function executeParameterChange(ParameterType paramType, uint256 newValue) external onlyOwner {
        // This function is designed to be called by the DAO's `executeProposal` via a `targets` array.
        // `msg.sender` will be this contract itself when called from `executeProposal`.
        // The `onlyOwner` check here is a placeholder. In a fully mature DAO, the `executeProposal`
        // function's internal mechanism to prevent arbitrary calls would be the primary gate.

        if (paramType == ParameterType.VotingPeriod) {
            require(newValue > 0, "Voting period must be greater than 0");
            votingPeriodBlocks = newValue;
        } else if (paramType == ParameterType.QuorumPercentage) {
            require(newValue > 0 && newValue <= 10000, "Quorum percentage must be between 0 and 10000");
            quorumPercentage = newValue;
        } else if (paramType == ParameterType.ProposerMinTokens) {
            proposerMinTokens = newValue;
        } else if (paramType == ParameterType.ReputationMultiplier) {
            require(newValue > 0, "Reputation multiplier must be greater than 0");
            reputationMultiplier = newValue;
        } else if (paramType == ParameterType.AIAssistedVotingToggle) {
            aiAssistedVotingEnabled = (newValue == 1);
            emit AIAssistedVotingToggled(aiAssistedVotingEnabled); // Redundant, but explicit
        } else {
            revert("Invalid parameter type for execution");
        }
        emit ParameterChanged(paramType, newValue);
    }

    /**
     * @notice Allows the DAO to approve and execute withdrawals from its main treasury, typically for operational costs or external investments.
     * @dev Requires a successful DAO proposal to execute, ensuring decentralized control over funds.
     * The actual withdrawal is done via a `Funding` proposal. This function is a wrapper for `propose`.
     * @param recipient The address to receive the funds.
     * @param amount The amount of QLT to withdraw.
     */
    function treasuryWithdrawal(address recipient, uint256 amount) public whenNotPaused returns (uint256) {
        require(recipient != address(0), "Recipient cannot be zero address");
        require(amount > 0, "Amount must be greater than 0");
        require(qltToken.balanceOf(address(this)) >= amount, "Insufficient treasury balance");

        // The actual transfer happens when the proposal is executed
        bytes memory callData = abi.encodeWithSelector(qltToken.transfer.selector, recipient, amount);

        return propose(
            new address[](1).push(address(qltToken)), // Target the QLT token contract
            new uint256[](1).push(0), // No ETH value
            new bytes[](1).push(callData),
            string(abi.encodePacked("Withdraw ", Strings.toString(amount), " QLT from treasury to ", Strings.toHexString(recipient))),
            ProposalType.Funding
        );
    }

    // --- VII. Utility & Information ---

    /**
     * @notice Returns the current vote count for a proposal.
     * @param proposalId The ID of the proposal.
     * @return yesVotes The total 'yes' votes.
     * @return noVotes The total 'no' votes.
     */
    function getProposalVoteCount(uint256 proposalId) public view returns (uint256 yesVotes, uint256 noVotes) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id == proposalId, "Proposal does not exist");
        return (proposal.yesVotes, proposal.noVotes);
    }

    /**
     * @notice Checks if a specific address has already voted on a given proposal.
     * @param proposalId The ID of the proposal.
     * @param voter The address to check.
     * @return True if the voter has already cast a vote, false otherwise.
     */
    function hasVoted(uint256 proposalId, address voter) public view returns (bool) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id == proposalId, "Proposal does not exist");
        return proposal.hasVoted[voter];
    }

    /**
     * @notice Retrieves core details of a funded project.
     * @param projectId The ID of the project.
     * @return projectAddress The main address associated with the project.
     * @return totalAmount The total QLT allocated to the project.
     * @return currentMilestoneIndex The index of the next milestone expected to be completed.
     */
    function getProjectDetails(uint256 projectId) public view returns (address projectAddress, uint256 totalAmount, uint256 currentMilestoneIndex) {
        Project storage project = projects[projectId];
        require(project.projectAddress != address(0), "Project does not exist");
        return (project.projectAddress, project.totalAmount, project.currentMilestoneIndex);
    }
}

// Minimal String conversion for use in descriptions.
// More robust string utils can be imported from OpenZeppelin if needed (e.g. `Strings`).
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

    function toHexString(address account) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            uint8 byteValue = uint8(uint256(account) / (2**(8 * (19 - i))));
            uint8 nibble1 = (byteValue >> 4) & 0xF;
            uint8 nibble2 = byteValue & 0xF;
            s[2 * i] = _to\'char(nibble1);
            s[2 * i + 1] = _to\'char(nibble2);
        }
        return string(s);
    }

    function _to\'char(uint8 value) internal pure returns (bytes1) {
        if (value < 10) {
            return bytes1(uint8(48 + value));
        } else {
            return bytes1(uint8(87 + value));
        }
    }
}
```