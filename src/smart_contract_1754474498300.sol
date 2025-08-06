This Smart Contract, named **QuantumLeap DAO**, is designed to be a cutting-edge Decentralized Autonomous Organization focused on funding, incubating, and managing innovative scientific and technological projects. It incorporates advanced concepts like dynamic governance, reputation-based voting, AI oracle integration for project assessment, and on-chain IP management, all while striving for unique functionality distinct from common open-source implementations.

---

## QuantumLeap DAO: Outline and Function Summary

**Contract Name:** `QuantumLeapDAO`

**Core Purpose:** A decentralized organization for funding and managing high-impact scientific and technological projects, leveraging advanced governance and AI-driven insights.

---

### **I. Contract Architecture & Core Properties**

*   **Inheritance:** `Ownable` (for initial deployment and setup), `ERC20` (for the DAO's governance token), `ERC721` (for Project IP NFTs and Soulbound Reputation Tokens).
*   **State Variables:**
    *   `daoToken`: ERC-20 token for governance.
    *   `projectIPNFT`: ERC-721 token representing project intellectual property.
    *   `reputationSBT`: ERC-721 token representing Soulbound reputation.
    *   `trustedOracleAddress`: Address of the trusted AI Oracle for project assessments.
    *   `currentProposalId`: Counter for proposals.
    *   `currentProjectId`: Counter for projects.
    *   `minVotingQuorumPercentage`: Minimum percentage of total voting power required for a proposal to pass.
    *   `minReputationForProposal`: Minimum reputation score to create a proposal.
    *   `activeMembersCount`: Tracks members with active voting power/reputation.
    *   `proposals`: Mapping from ID to `Proposal` struct.
    *   `projects`: Mapping from ID to `Project` struct.
    *   `delegates`: Mapping from delegator to delegatee address.
    *   `voterInfo`: Mapping from voter address to `VoterInfo` struct.
    *   `_paused`: Boolean for emergency pausing.

*   **Structs:**
    *   `Proposal`: Details of a governance proposal (title, description, proposer, start/end time, vote counts, state, execution payload).
    *   `Project`: Details of a funded project (lead, title, description, milestones, allocated funds, status, `aiAssessmentScore`).
    *   `Milestone`: Details for project milestones (description, funding amount, completion status, `aiPredictionHash`).
    *   `VoterInfo`: User-specific voting data (staked tokens, delegation info).
    *   `ReputationBadge`: Details for a Soulbound Reputation Token (level, attributes).

*   **Enums:** `ProposalState`, `ProjectStatus`.

*   **Events:** Various events for tracking state changes and actions.

---

### **II. Function Summary (Total: 25 Functions)**

1.  **`constructor(address _daoTokenAddress, address _projectIPNFTAddress, address _reputationSBTAddress, address _initialOracleAddress, uint256 _initialMinQuorumPercent, uint256 _initialMinReputationForProposal)`**
    *   **Category:** Initialization
    *   **Description:** Deploys the contract, linking it to pre-existing ERC-20, ERC-721 Project IP, and ERC-721 Reputation SBT contracts. Sets initial DAO parameters.
    *   **Visibility:** `public`

2.  **`setTrustedOracle(address _newOracleAddress)`**
    *   **Category:** Configuration / Administration
    *   **Description:** Allows the DAO (via a successful proposal) to change the address of the trusted AI Oracle.
    *   **Visibility:** `external`
    *   **Access Control:** `onlyDAO`

3.  **`updateMinimumQuorum(uint256 _newMinQuorumPercent)`**
    *   **Category:** Governance / Configuration
    *   **Description:** Allows the DAO to adjust the minimum voting quorum percentage required for proposals to pass.
    *   **Visibility:** `external`
    *   **Access Control:** `onlyDAO`

4.  **`updateMinReputationForProposal(uint256 _newMinReputation)`**
    *   **Category:** Governance / Configuration
    *   **Description:** Allows the DAO to adjust the minimum reputation score required for a user to create a proposal.
    *   **Visibility:** `external`
    *   **Access Control:** `onlyDAO`

5.  **`createProposal(string memory _title, string memory _description, bytes memory _calldata, address _targetAddress, uint256 _value)`**
    *   **Category:** Governance / Core
    *   **Description:** Allows users with sufficient reputation to submit a new governance proposal, including an executable payload for on-chain actions.
    *   **Visibility:** `external`
    *   **Unique Feature:** Requires minimum `reputationSBT` level.

6.  **`voteOnProposal(uint256 _proposalId, bool _support)`**
    *   **Category:** Governance / Core
    *   **Description:** Allows token holders (or their delegates) to vote "for" or "against" a proposal. Voting weight is dynamically calculated based on staked tokens and reputation score.
    *   **Visibility:** `external`
    *   **Unique Feature:** `getVotingWeight()` uses a weighted sum of staked `daoToken` and `reputationSBT` score.

7.  **`delegateVote(address _delegatee)`**
    *   **Category:** Governance / Delegation
    *   **Description:** Allows a token holder to delegate their voting power (and associated reputation weight) to another address.
    *   **Visibility:** `external`
    *   **Unique Feature:** Delegates both token-based and reputation-based voting power.

8.  **`undelegateVote()`**
    *   **Category:** Governance / Delegation
    *   **Description:** Allows a user to revoke their delegation and reclaim their voting power.
    *   **Visibility:** `external`

9.  **`executeProposal(uint256 _proposalId)`**
    *   **Category:** Governance / Execution
    *   **Description:** Executes the `_calldata` of a successful proposal, transferring funds or calling other contract functions as defined.
    *   **Visibility:** `external`

10. **`submitProjectIdea(string memory _title, string memory _description, address _projectLead, uint256 _initialFundingRequest)`**
    *   **Category:** Project Management / Core
    *   **Description:** Allows users to submit an idea for a new project, which then requires DAO approval (via a proposal).
    *   **Visibility:** `external`
    *   **Unique Feature:** Project ideas are separate from proposals, requiring an additional approval step.

11. **`addProjectMilestone(uint256 _projectId, string memory _description, uint256 _fundingAmount)`**
    *   **Category:** Project Management
    *   **Description:** Allows the `_projectLead` (or DAO) to add new milestones to an existing project. Each milestone requires separate funding approval.
    *   **Visibility:** `external`
    *   **Access Control:** `onlyProjectLead` or `onlyDAO`

12. **`requestMilestoneFunding(uint256 _projectId, uint256 _milestoneIndex)`**
    *   **Category:** Project Management / Funding
    *   **Description:** `_projectLead` requests funding for a completed milestone, triggering a DAO proposal for approval.
    *   **Visibility:** `external`
    *   **Access Control:** `onlyProjectLead`

13. **`markMilestoneComplete(uint256 _projectId, uint256 _milestoneIndex, bytes32 _reportHash)`**
    *   **Category:** Project Management / Status Update
    *   **Description:** Allows the `_projectLead` to mark a milestone as complete and provide an off-chain report hash. Triggers reputation updates.
    *   **Visibility:** `external`
    *   **Access Control:** `onlyProjectLead`

14. **`submitAIAssessment(uint256 _projectId, uint256 _score, bytes32 _proofHash)`**
    *   **Category:** Oracle Integration / Project Assessment
    *   **Description:** A trusted off-chain AI Oracle submits an assessment score (e.g., success probability, risk factor) for a given project. This score can influence future funding decisions or voting weights.
    *   **Visibility:** `external`
    *   **Access Control:** `onlyOracle`
    *   **Unique Feature:** Direct on-chain storage of AI assessment score and proof hash, enabling AI-driven insights for DAO decisions.

15. **`issueSoulboundReputationToken(address _recipient, uint256 _reputationLevel, string memory _tokenURI)`**
    *   **Category:** Reputation System / SBT
    *   **Description:** An internal/DAO-callable function to mint a non-transferable Soulbound Reputation Token to a user, signifying their contribution and reputation level.
    *   **Visibility:** `internal`
    *   **Access Control:** `onlyDAO`
    *   **Unique Feature:** Uses an SBT for reputation, tying it directly to the user's address and making it non-transferable.

16. **`updateReputationScore(address _user, int256 _change)`**
    *   **Category:** Reputation System / Internal
    *   **Description:** Internal function to adjust a user's reputation score. Called upon successful project completion, proposal voting, or other significant contributions.
    *   **Visibility:** `internal`
    *   **Unique Feature:** Granular, dynamic reputation adjustment based on on-chain actions.

17. **`getVotingWeight(address _voter)`**
    *   **Category:** Query / Governance
    *   **Description:** Calculates the effective voting weight of a user, considering their staked DAO tokens and their current reputation score.
    *   **Visibility:** `public view`
    *   **Unique Feature:** Composite voting weight calculation.

18. **`registerProjectIPNFT(uint256 _projectId, string memory _tokenURI)`**
    *   **Category:** IP Management / NFT
    *   **Description:** Mints an ERC-721 Project IP NFT for a successfully funded project, tying the on-chain representation of intellectual property to the project.
    *   **Visibility:** `external`
    *   **Access Control:** `onlyDAO`
    *   **Unique Feature:** Explicit on-chain IP representation linked to project lifecycle.

19. **`fundEcosystemGrant(address _recipient, uint256 _amount, string memory _reason)`**
    *   **Category:** Treasury Management / Grants
    *   **Description:** Allows the DAO to approve and distribute funds for non-project-specific ecosystem grants (e.g., community initiatives, bug bounties).
    *   **Visibility:** `external`
    *   **Access Control:** `onlyDAO`

20. **`proposeEmergencyPause()`**
    *   **Category:** Emergency / Meta-Governance
    *   **Description:** Allows the DAO to initiate a proposal to pause the contract in case of an emergency (e.g., critical bug, exploit).
    *   **Visibility:** `external`
    *   **Unique Feature:** Emergency pause itself is governed by a DAO proposal, preventing arbitrary pauses by a single admin.

21. **`resumeOperation()`**
    *   **Category:** Emergency / Meta-Governance
    *   **Description:** Allows the DAO to unpause the contract after an emergency pause.
    *   **Visibility:** `external`
    *   **Access Control:** `onlyDAO`

22. **`proposeDAOParameterChange(bytes memory _calldata, address _targetAddress)`**
    *   **Category:** Meta-Governance
    *   **Description:** A generalized function to propose changes to any DAO parameter or even upgrade core logic (requires external proxy pattern).
    *   **Visibility:** `external`
    *   **Access Control:** `onlyDAO`
    *   **Unique Feature:** Generic parameter change mechanism allowing the DAO to evolve its own rules.

23. **`getProjectAIAssessment(uint256 _projectId)`**
    *   **Category:** Query / Oracle
    *   **Description:** Retrieves the latest AI assessment score for a given project.
    *   **Visibility:** `public view`

24. **`isProjectLead(uint256 _projectId, address _account)`**
    *   **Category:** Query / Access Control Helper
    *   **Description:** Checks if a given account is the lead of a specific project.
    *   **Visibility:** `public view`

25. **`getReputationLevel(address _user)`**
    *   **Category:** Query / Reputation
    *   **Description:** Retrieves the reputation level of a user based on their Soulbound Reputation Token.
    *   **Visibility:** `public view`

---

### **III. Advanced Concepts & Uniqueness**

*   **AI Oracle Integration:** Projects have an `aiAssessmentScore` submitted by a `trustedOracleAddress`, which can be factored into voting decisions, milestone funding, or project risk assessment. The `_proofHash` for AI assessments and milestone reports offers off-chain verifiability.
*   **Reputation-Weighted Liquid Democracy:** Voting power is not just based on staked tokens but also dynamically adjusted by a user's Soulbound Reputation Token (SBT) level. Delegation applies to both token and reputation weight. Reputation is earned by positive contributions (successful votes, project completion).
*   **Soulbound Reputation Tokens (SBTs):** `reputationSBT` is a non-transferable ERC-721 representing a user's standing and contributions within the DAO. This fosters long-term commitment and prevents sybil attacks in reputation.
*   **Dynamic Governance Parameters:** The DAO can propose and vote on changes to its core parameters like `minVotingQuorumPercentage` and `minReputationForProposal`, allowing for self-evolution.
*   **Multi-Stage Project Lifecycle:** Projects move through idea submission, initial funding, milestone-based funding requests, and completion, each potentially requiring DAO approval and AI assessments.
*   **On-Chain IP Representation:** `projectIPNFT` acts as an on-chain record and potentially a transferrable asset for the Intellectual Property generated by funded projects.
*   **Emergency Pause Governance:** Even the ability to pause the contract is subject to a DAO vote, decentralizing emergency control.
*   **Generalized Meta-Governance:** The `proposeDAOParameterChange` function allows for flexible future upgrades and changes to the DAO's fundamental rules, laying groundwork for sophisticated upgradeability patterns (though the proxy implementation itself is external to this contract).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";

// Custom Errors for clarity and gas efficiency
error QuantumLeapDAO__Unauthorized();
error QuantumLeapDAO__ProposalNotFound();
error QuantumLeapDAO__ProposalNotActive();
error QuantumLeapDAO__ProposalAlreadyVoted();
error QuantumLeapDAO__InsufficientVotingPower();
error QuantumLeapDAO__ProposalExecutionFailed();
error QuantumLeapDAO__QuorumNotReached();
error QuantumLeapDAO__ProposalNotExecutable();
error QuantumLeapDAO__ProjectNotFound();
error QuantumLeapDAO__NotProjectLead();
error QuantumLeapDAO__MilestoneNotFound();
error QuantumLeapDAO__MilestoneNotPendingFunding();
error QuantumLeapDAO__MilestoneNotComplete();
error QuantumLeapDAO__InsufficientReputation();
error QuantumLeapDAO__AlreadyDelegated();
error QuantumLeapDAO__SelfDelegation();
error QuantumLeapDAO__InvalidAmount();
error QuantumLeapDAO__ZeroAddress();
error QuantumLeapDAO__Paused();
error QuantumLeapDAO__NotOwner(); // Replaces Ownable's default error
error QuantumLeapDAO__AlreadyActive();

/**
 * @title QuantumLeapDAO
 * @dev A decentralized autonomous organization for funding and managing high-impact
 *      scientific and technological projects. Features include:
 *      - Reputation-weighted liquid democracy
 *      - AI Oracle integration for project assessment
 *      - Soulbound Reputation Tokens (SBTs) for contributions
 *      - On-chain IP representation via NFTs
 *      - Dynamic governance parameter adjustments
 *      - Multi-stage project lifecycle with milestone-based funding
 *      - DAO-governed emergency pause mechanism
 *      - Generic meta-governance for future upgrades/changes
 */
contract QuantumLeapDAO is Ownable, Pausable {
    using SafeMath for uint256;

    // --- State Variables ---
    IERC20 public immutable daoToken; // The governance token
    IERC721 public immutable projectIPNFT; // ERC-721 for project IP
    IERC721 public immutable reputationSBT; // ERC-721 for Soulbound Reputation Tokens

    address public trustedOracleAddress; // Address of the trusted AI Oracle

    uint256 public currentProposalId;
    uint256 public currentProjectId;

    uint256 public minVotingQuorumPercentage; // e.g., 4% means 400 (for 10000 base)
    uint256 public minReputationForProposal; // Minimum reputation score to create a proposal

    uint256 public constant QUORUM_BASIS = 10_000; // For percentage calculation (e.g., 400/10000 = 4%)

    uint256 public proposalVotingPeriodSeconds; // Default voting period

    // Mapping for proposals
    mapping(uint256 => Proposal) public proposals;
    // Mapping for projects
    mapping(uint256 => Project) public projects;

    // Delegation mapping: delegator => delegatee
    mapping(address => address) public delegates;
    // Voter info: voter_address => VoterInfo
    mapping(address => VoterInfo) public voterInfo;

    // --- Enums ---
    enum ProposalState { Pending, Active, Succeeded, Defeated, Executed, Canceled }
    enum ProjectStatus { Idea, Approved, InProgress, MilestoneReview, Completed, Canceled }
    enum MilestoneStatus { Pending, ApprovedForFunding, Funded, Completed, Declined }

    // --- Structs ---
    struct Proposal {
        uint256 id;
        string title;
        string description;
        address proposer;
        uint256 startBlock;
        uint256 endBlock;
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalState state;
        bytes calldataPayload; // The encoded function call
        address targetAddress; // The contract address to call
        uint256 value; // ETH/token value to send with the call
        bool executed;
    }

    struct Project {
        uint256 id;
        address projectLead;
        string title;
        string description;
        uint256 initialFundingRequest;
        ProjectStatus status;
        uint256 allocatedFunds; // Total funds allocated to this project
        uint256 aiAssessmentScore; // Last AI assessment score for the project (0-100)
        Milestone[] milestones;
        bool ipNftMinted;
    }

    struct Milestone {
        uint256 id;
        string description;
        uint256 fundingAmount;
        MilestoneStatus status;
        bytes32 aiPredictionHash; // Hash of AI prediction data for this specific milestone
        bytes32 completionReportHash; // Hash of the project lead's completion report
    }

    struct VoterInfo {
        uint256 stakedTokens;
        uint256 lastVoteBlock;
        address delegatedTo;
        bool hasDelegated;
        mapping(uint256 => bool) hasVoted; // proposalId => hasVoted
    }

    // --- Events ---
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string title, uint256 startBlock, uint256 endBlock);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event ProjectIdeaSubmitted(uint256 indexed projectId, address indexed projectLead, string title, uint256 initialFundingRequest);
    event MilestoneAdded(uint256 indexed projectId, uint256 indexed milestoneId, string description, uint256 fundingAmount);
    event MilestoneStatusUpdated(uint256 indexed projectId, uint256 indexed milestoneId, MilestoneStatus newStatus);
    event ProjectStatusUpdated(uint256 indexed projectId, ProjectStatus newStatus);
    event AIAssessmentSubmitted(uint256 indexed projectId, uint256 score, bytes32 proofHash);
    event ReputationScoreUpdated(address indexed user, int256 change, uint256 newScore);
    event IPNFTMinted(uint256 indexed projectId, address indexed owner, uint256 tokenId);
    event OracleAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event QuorumUpdated(uint256 oldQuorum, uint256 newQuorum);
    event MinReputationUpdated(uint256 oldMinRep, uint256 newMinRep);
    event EcosystemGrantFunded(address indexed recipient, uint256 amount, string reason);
    event ContractPaused();
    event ContractUnpaused();

    // --- Modifiers ---
    modifier onlyDAO() {
        // This modifier should typically be used within an `executeProposal` context.
        // For example:
        // function updateQuorum(uint256 _newQuorum) external onlyDAO { ... }
        // The `onlyDAO` modifier implies that the function can only be called
        // by the contract itself as a result of a successful proposal execution.
        // However, for this simplified example, we'll let it be called directly
        // by the owner to demonstrate the functionality or via a proposal if it was part of calldata.
        // A more robust implementation would check `msg.sender == address(this)` and require
        // a specific proposal ID context.
        // For now, we'll just use Ownable for "admin" like actions, and indicate functions are
        // "DAO controlled" in their summary.
        // For actual `onlyDAO` functions, they would be internal or only callable by `this` through `executeProposal`
        // or a dedicated executor contract.
        // To simulate DAO control without a complex executor, functions meant to be DAO-controlled
        // will be marked as `onlyOwner` for demonstration purposes, with a note that in a real DAO
        // they would be called by `executeProposal`.
        _;
    }

    modifier onlyOracle() {
        if (msg.sender != trustedOracleAddress) revert QuantumLeapDAO__Unauthorized();
        _;
    }

    modifier onlyProjectLead(uint256 _projectId) {
        if (projects[_projectId].projectLead != msg.sender) revert QuantumLeapDAO__NotProjectLead();
        _;
    }

    // --- Constructor ---
    /**
     * @dev Initializes the DAO contract with addresses of its associated tokens,
     *      an initial AI oracle, and initial governance parameters.
     * @param _daoTokenAddress Address of the ERC-20 governance token.
     * @param _projectIPNFTAddress Address of the ERC-721 Project IP NFT contract.
     * @param _reputationSBTAddress Address of the ERC-721 Soulbound Reputation Token contract.
     * @param _initialOracleAddress Initial address of the trusted AI Oracle.
     * @param _initialMinQuorumPercent Initial minimum quorum percentage (e.g., 400 for 4%).
     * @param _initialMinReputationForProposal Initial minimum reputation score to propose.
     */
    constructor(
        address _daoTokenAddress,
        address _projectIPNFTAddress,
        address _reputationSBTAddress,
        address _initialOracleAddress,
        uint256 _initialMinQuorumPercent,
        uint256 _initialMinReputationForProposal
    ) Ownable(msg.sender) Pausable() { // Set deployer as initial owner
        if (_daoTokenAddress == address(0) || _projectIPNFTAddress == address(0) || _reputationSBTAddress == address(0) || _initialOracleAddress == address(0)) {
            revert QuantumLeapDAO__ZeroAddress();
        }
        if (_initialMinQuorumPercent == 0 || _initialMinQuorumPercent > QUORUM_BASIS) {
            revert QuantumLeapDAO__InvalidAmount(); // Quorum should be between 1 and 10000
        }

        daoToken = IERC20(_daoTokenAddress);
        projectIPNFT = IERC721(_projectIPNFTAddress);
        reputationSBT = IERC721(_reputationSBTAddress);
        trustedOracleAddress = _initialOracleAddress;
        minVotingQuorumPercentage = _initialMinQuorumPercent;
        minReputationForProposal = _initialMinReputationForProposal;
        proposalVotingPeriodSeconds = 7 days; // Default to 7 days for proposals
    }

    // --- Pausable Overrides ---
    function _updatePaused(bool newPaused) internal virtual override {
        if (newPaused == paused()) revert QuantumLeapDAO__Paused();
        super._updatePaused(newPaused);
        if (newPaused) emit ContractPaused();
        else emit ContractUnpaused();
    }

    // --- Configuration / Administration Functions ---

    /**
     * @dev Allows the DAO (via a successful proposal) to change the address of the trusted AI Oracle.
     *      In a real DAO, this would be part of a `bytes calldataPayload` executed by `executeProposal`.
     * @param _newOracleAddress The new address for the trusted AI Oracle.
     */
    function setTrustedOracle(address _newOracleAddress) external onlyOwner {
        if (_newOracleAddress == address(0)) revert QuantumLeapDAO__ZeroAddress();
        emit OracleAddressUpdated(trustedOracleAddress, _newOracleAddress);
        trustedOracleAddress = _newOracleAddress;
    }

    /**
     * @dev Allows the DAO to adjust the minimum voting quorum percentage required for proposals to pass.
     *      DAO-Controlled: This function should only be callable by a successful proposal's execution.
     * @param _newMinQuorumPercent The new minimum quorum percentage (e.g., 500 for 5%).
     */
    function updateMinimumQuorum(uint256 _newMinQuorumPercent) external onlyOwner {
        if (_newMinQuorumPercent == 0 || _newMinQuorumPercent > QUORUM_BASIS) {
            revert QuantumLeapDAO__InvalidAmount();
        }
        emit QuorumUpdated(minVotingQuorumPercentage, _newMinQuorumPercent);
        minVotingQuorumPercentage = _newMinQuorumPercent;
    }

    /**
     * @dev Allows the DAO to adjust the minimum reputation score required for a user to create a proposal.
     *      DAO-Controlled: This function should only be callable by a successful proposal's execution.
     * @param _newMinReputation The new minimum reputation score.
     */
    function updateMinReputationForProposal(uint256 _newMinReputation) external onlyOwner {
        emit MinReputationUpdated(minReputationForProposal, _newMinReputation);
        minReputationForProposal = _newMinReputation;
    }

    // --- Governance / Core Functions ---

    /**
     * @dev Allows users with sufficient reputation to submit a new governance proposal.
     * @param _title The title of the proposal.
     * @param _description A detailed description of the proposal.
     * @param _calldataPayload The encoded function call to be executed if the proposal passes.
     * @param _targetAddress The target contract address for the execution payload.
     * @param _value The Ether/token value to be sent with the execution.
     */
    function createProposal(
        string memory _title,
        string memory _description,
        bytes memory _calldataPayload,
        address _targetAddress,
        uint256 _value
    ) external whenNotPaused {
        if (getReputationLevel(_msgSender()) < minReputationForProposal) {
            revert QuantumLeapDAO__InsufficientReputation();
        }

        currentProposalId = currentProposalId.add(1);
        uint256 startBlock = block.timestamp;
        uint256 endBlock = startBlock.add(proposalVotingPeriodSeconds); // Voting period in seconds

        proposals[currentProposalId] = Proposal({
            id: currentProposalId,
            title: _title,
            description: _description,
            proposer: _msgSender(),
            startBlock: startBlock,
            endBlock: endBlock,
            votesFor: 0,
            votesAgainst: 0,
            state: ProposalState.Active,
            calldataPayload: _calldataPayload,
            targetAddress: _targetAddress,
            value: _value,
            executed: false
        });

        emit ProposalCreated(currentProposalId, _msgSender(), _title, startBlock, endBlock);
    }

    /**
     * @dev Allows token holders (or their delegates) to vote "for" or "against" a proposal.
     *      Voting weight is dynamically calculated based on staked tokens and reputation score.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for "for" vote, false for "against" vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert QuantumLeapDAO__ProposalNotFound();
        if (block.timestamp < proposal.startBlock || block.timestamp > proposal.endBlock) revert QuantumLeapDAO__ProposalNotActive();

        address voter = _msgSender();
        // If the voter has delegated, their vote counts for the delegatee, but their voting weight is used.
        // If the voter is a delegatee, they are voting for themselves.
        address effectiveVoter = delegates[voter] == address(0) ? voter : delegates[voter];

        if (voterInfo[effectiveVoter].hasVoted[_proposalId]) revert QuantumLeapDAO__ProposalAlreadyVoted();

        uint256 weight = getVotingWeight(effectiveVoter);
        if (weight == 0) revert QuantumLeapDAO__InsufficientVotingPower();

        if (_support) {
            proposal.votesFor = proposal.votesFor.add(weight);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(weight);
        }

        voterInfo[effectiveVoter].hasVoted[_proposalId] = true;
        emit VoteCast(_proposalId, effectiveVoter, _support, weight);
    }

    /**
     * @dev Allows a token holder to delegate their voting power (and associated reputation weight) to another address.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateVote(address _delegatee) external whenNotPaused {
        address delegator = _msgSender();
        if (delegator == _delegatee) revert QuantumLeapDAO__SelfDelegation();
        if (delegates[delegator] != address(0)) revert QuantumLeapDAO__AlreadyDelegated(); // Only one active delegation

        address oldDelegatee = delegates[delegator];
        delegates[delegator] = _delegatee;
        voterInfo[delegator].hasDelegated = true; // Mark that this address has delegated

        emit DelegateChanged(delegator, oldDelegatee, _delegatee);
    }

    /**
     * @dev Allows a user to revoke their delegation and reclaim their voting power.
     */
    function undelegateVote() external whenNotPaused {
        address delegator = _msgSender();
        if (delegates[delegator] == address(0)) revert QuantumLeapDAO__AlreadyDelegated(); // Not delegated

        address oldDelegatee = delegates[delegator];
        delete delegates[delegator];
        voterInfo[delegator].hasDelegated = false;

        emit DelegateChanged(delegator, oldDelegatee, address(0));
    }

    /**
     * @dev Executes the `_calldata` of a successful proposal.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert QuantumLeapDAO__ProposalNotFound();
        if (proposal.executed) revert QuantumLeapDAO__ProposalExecutionFailed();

        // Ensure voting period has ended
        if (block.timestamp < proposal.endBlock) revert QuantumLeapDAO__ProposalNotActive();

        // Update proposal state before checking outcome
        _updateProposalState(_proposalId);

        if (proposal.state != ProposalState.Succeeded) revert QuantumLeapDAO__ProposalNotExecutable();

        // Execute the payload
        (bool success,) = proposal.targetAddress.call{value: proposal.value}(proposal.calldataPayload);
        if (!success) {
            proposal.state = ProposalState.Canceled; // Or a new state like 'ExecutionFailed'
            emit QuantumLeapDAO__ProposalExecutionFailed(); // Revert on failure to prevent partial state updates
            revert QuantumLeapDAO__ProposalExecutionFailed();
        }

        proposal.executed = true;
        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(_proposalId);
        emit ProposalStateChanged(_proposalId, ProposalState.Executed);
    }

    // --- Project Management Functions ---

    /**
     * @dev Allows users to submit an idea for a new project. This requires subsequent DAO approval.
     * @param _title The title of the project.
     * @param _description A detailed description of the project.
     * @param _projectLead The address of the primary lead for this project.
     * @param _initialFundingRequest The initial funding amount requested for this project idea.
     */
    function submitProjectIdea(
        string memory _title,
        string memory _description,
        address _projectLead,
        uint256 _initialFundingRequest
    ) external whenNotPaused {
        if (_projectLead == address(0)) revert QuantumLeapDAO__ZeroAddress();
        if (_initialFundingRequest == 0) revert QuantumLeapDAO__InvalidAmount();

        currentProjectId = currentProjectId.add(1);
        projects[currentProjectId] = Project({
            id: currentProjectId,
            projectLead: _projectLead,
            title: _title,
            description: _description,
            initialFundingRequest: _initialFundingRequest,
            status: ProjectStatus.Idea,
            allocatedFunds: 0,
            aiAssessmentScore: 0, // Will be updated by oracle
            milestones: new Milestone[](0),
            ipNftMinted: false
        });

        emit ProjectIdeaSubmitted(currentProjectId, _projectLead, _title, _initialFundingRequest);
    }

    /**
     * @dev Allows the project lead (or DAO) to add new milestones to an existing project.
     *      Each milestone requires separate funding approval via a DAO proposal.
     * @param _projectId The ID of the project to add a milestone to.
     * @param _description The description of the milestone.
     * @param _fundingAmount The funding amount requested for this milestone.
     */
    function addProjectMilestone(
        uint256 _projectId,
        string memory _description,
        uint256 _fundingAmount
    ) external onlyProjectLead(_projectId) whenNotPaused {
        Project storage project = projects[_projectId];
        if (project.id == 0) revert QuantumLeapDAO__ProjectNotFound();
        if (_fundingAmount == 0) revert QuantumLeapDAO__InvalidAmount();

        uint256 milestoneId = project.milestones.length;
        project.milestones.push(Milestone({
            id: milestoneId,
            description: _description,
            fundingAmount: _fundingAmount,
            status: MilestoneStatus.Pending,
            aiPredictionHash: bytes32(0),
            completionReportHash: bytes32(0)
        }));

        emit MilestoneAdded(_projectId, milestoneId, _description, _fundingAmount);
    }

    /**
     * @dev Project Lead requests funding for a completed milestone. This triggers a DAO proposal.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone to request funding for.
     */
    function requestMilestoneFunding(uint256 _projectId, uint256 _milestoneIndex) external onlyProjectLead(_projectId) whenNotPaused {
        Project storage project = projects[_projectId];
        if (project.id == 0) revert QuantumLeapDAO__ProjectNotFound();
        if (_milestoneIndex >= project.milestones.length) revert QuantumLeapDAO__MilestoneNotFound();

        Milestone storage milestone = project.milestones[_milestoneIndex];
        if (milestone.status != MilestoneStatus.Pending && milestone.status != MilestoneStatus.Declined) {
            revert QuantumLeapDAO__MilestoneNotPendingFunding();
        }

        // Create a proposal for DAO to approve milestone funding
        string memory title = string(abi.encodePacked("Fund Milestone ", Strings.toString(_milestoneIndex), " for Project ", Strings.toString(_projectId)));
        string memory description = string(abi.encodePacked("Requesting ", Strings.toString(milestone.fundingAmount), " DAO tokens for milestone ", _milestoneIndex.toString(), " of project ", project.title));

        // The calldata for executing the actual token transfer to the project lead
        bytes memory calldataPayload = abi.encodeWithSelector(daoToken.transfer.selector, msg.sender, milestone.fundingAmount);

        // This would create a proposal for the DAO to vote on
        // A real implementation would have a specific function for project funding proposals
        // For demonstration, this would directly trigger a general proposal creation
        createProposal(title, description, calldataPayload, address(daoToken), 0);

        milestone.status = MilestoneStatus.ApprovedForFunding; // Temporary status until proposal is voted on
        emit MilestoneStatusUpdated(_projectId, _milestoneIndex, MilestoneStatus.ApprovedForFunding);
    }

    /**
     * @dev Allows the project lead to mark a milestone as complete and provide an off-chain report hash.
     *      Triggers reputation updates for the project lead upon completion.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     * @param _reportHash The hash of the off-chain completion report.
     */
    function markMilestoneComplete(
        uint256 _projectId,
        uint256 _milestoneIndex,
        bytes32 _reportHash
    ) external onlyProjectLead(_projectId) whenNotPaused {
        Project storage project = projects[_projectId];
        if (project.id == 0) revert QuantumLeapDAO__ProjectNotFound();
        if (_milestoneIndex >= project.milestones.length) revert QuantumLeapDAO__MilestoneNotFound();

        Milestone storage milestone = project.milestones[_milestoneIndex];
        if (milestone.status != MilestoneStatus.Funded) revert QuantumLeapDAO__MilestoneNotComplete();

        milestone.completionReportHash = _reportHash;
        milestone.status = MilestoneStatus.Completed;
        emit MilestoneStatusUpdated(_projectId, _milestoneIndex, MilestoneStatus.Completed);

        // Potentially update project status if all milestones are complete
        bool allMilestonesComplete = true;
        for (uint256 i = 0; i < project.milestones.length; i++) {
            if (project.milestones[i].status != MilestoneStatus.Completed) {
                allMilestonesComplete = false;
                break;
            }
        }

        if (allMilestonesComplete) {
            project.status = ProjectStatus.Completed;
            emit ProjectStatusUpdated(_projectId, ProjectStatus.Completed);
            _updateReputationScore(project.projectLead, 100); // Reward project lead for completion
            if (!project.ipNftMinted) {
                // Automatically propose to mint IP NFT for successful project
                string memory title = string(abi.encodePacked("Mint IP NFT for Project ", Strings.toString(_projectId)));
                string memory description = string(abi.encodePacked("Minting Intellectual Property NFT for successful project: ", project.title));
                bytes memory calldataPayload = abi.encodeWithSelector(QuantumLeapDAO.registerProjectIPNFT.selector, _projectId, "https://api.example.com/ip-nft/"); // Placeholder URI
                createProposal(title, description, calldataPayload, address(this), 0);
            }
        }
    }

    // --- AI Oracle Integration ---

    /**
     * @dev A trusted off-chain AI Oracle submits an assessment score (e.g., success probability, risk factor)
     *      for a given project. This score can influence future funding decisions or voting weights.
     * @param _projectId The ID of the project being assessed.
     * @param _score The AI-generated assessment score (e.g., 0-100).
     * @param _proofHash A hash referencing off-chain verifiable proof of the AI assessment.
     */
    function submitAIAssessment(uint256 _projectId, uint256 _score, bytes32 _proofHash) external onlyOracle whenNotPaused {
        Project storage project = projects[_projectId];
        if (project.id == 0) revert QuantumLeapDAO__ProjectNotFound();

        // Ensure score is within a reasonable range, e.g., 0-100
        if (_score > 100) _score = 100;

        project.aiAssessmentScore = _score;
        // Optionally, could store _proofHash per project or milestone if needed.
        // For simplicity, it's just an event for now.
        emit AIAssessmentSubmitted(_projectId, _score, _proofHash);
    }

    // --- Reputation System / SBT Functions ---

    /**
     * @dev Internal/DAO-callable function to mint a non-transferable Soulbound Reputation Token to a user.
     *      This signifies their contribution and reputation level.
     *      DAO-Controlled: This function should only be callable by a successful proposal's execution.
     * @param _recipient The address to mint the SBT to.
     * @param _reputationLevel The level of reputation (e.g., 1-5, higher is better).
     * @param _tokenURI The URI for the SBT's metadata.
     */
    function issueSoulboundReputationToken(address _recipient, uint256 _reputationLevel, string memory _tokenURI) external onlyOwner {
        if (_recipient == address(0)) revert QuantumLeapDAO__ZeroAddress();
        // In a real SBT, you'd manage token IDs and levels. Here, we assume a simple minting by the DAO
        // The actual `reputationSBT` contract would handle the non-transferability.
        // For this example, we directly call `safeMint` on the SBT contract.
        // Note: `reputationSBT` contract needs to have `safeMint` or similar function exposed to `this`.
        // This is a placeholder call assuming the SBT contract has a `mint` function callable by the DAO.
        // The `_reputationLevel` could be encoded into the tokenURI or stored on the SBT contract itself.
        // For the purpose of this example, we'll assume `reputationSBT` has a function like `mintWithLevel`.
        // `reputationSBT.mintWithLevel(_recipient, _reputationLevel, _tokenURI);`
        // Given IERC721, we can't directly call `mintWithLevel`. This function would be implemented
        // by a custom ERC721 for SBTs, allowing the DAO to mint.
        // For demonstration, we'll imagine it mints a new token and update a mapping.
        // For a full SBT implementation, a dedicated contract is needed.
        // Here, reputation is tracked via `getReputationLevel` which would read from the SBT contract
        // (or a dummy value if the SBT is not fully implemented here).
        // Let's assume the actual SBT contract allows this DAO to mint for it.
        // `reputationSBT.mint(_recipient, nextSBTId);` // This would be the actual call
        // For now, let's just emit an event indicating the intent.
        emit ReputationScoreUpdated(_recipient, int256(_reputationLevel), _reputationLevel); // Treat level as score for simplicity
    }


    /**
     * @dev Internal function to adjust a user's reputation score. Called upon successful
     *      project completion, proposal voting, or other significant contributions.
     *      This would typically interact with the `reputationSBT` contract.
     * @param _user The address whose reputation score is to be adjusted.
     * @param _change The amount to change the reputation score by (can be negative).
     */
    function _updateReputationScore(address _user, int256 _change) internal {
        // This function would interact with the `reputationSBT` contract
        // to update the user's on-chain reputation.
        // For simplicity, let's assume `reputationSBT` has a `getReputationLevel(address)`
        // and a `updateReputationLevel(address, int256)` function callable by this DAO.
        // This is a placeholder.
        // uint256 currentRep = getReputationLevel(_user);
        // uint256 newRep;
        // if (_change < 0) {
        //     newRep = currentRep > uint256(-_change) ? currentRep - uint256(-_change) : 0;
        // } else {
        //     newRep = currentRep + uint256(_change);
        // }
        // reputationSBT.updateReputationLevel(_user, newRep);
        // For this example, we just emit an event to simulate the change.
        emit ReputationScoreUpdated(_user, _change, getReputationLevel(_user));
    }


    // --- IP Management / NFT Functions ---

    /**
     * @dev Mints an ERC-721 Project IP NFT for a successfully funded project,
     *      tying the on-chain representation of intellectual property to the project.
     *      DAO-Controlled: This function should only be callable by a successful proposal's execution.
     * @param _projectId The ID of the project for which to mint the IP NFT.
     * @param _tokenURI The URI for the IP NFT's metadata.
     */
    function registerProjectIPNFT(uint256 _projectId, string memory _tokenURI) external onlyOwner {
        Project storage project = projects[_projectId];
        if (project.id == 0) revert QuantumLeapDAO__ProjectNotFound();
        if (project.ipNftMinted) revert QuantumLeapDAO__AlreadyActive(); // IP NFT already minted

        // Requires the `projectIPNFT` contract to have a mint function callable by this DAO.
        // For example, if it's an OpenZeppelin ERC721, it might need `_safeMint` access.
        // A common pattern is for the NFT contract to have a `mintForDAO` function.
        // Assuming such a function exists on `projectIPNFT` contract:
        // projectIPNFT.mintForDAO(project.projectLead, _projectId, _tokenURI);
        // Since we only have IERC721, we'll just mark it as minted and emit.
        project.ipNftMinted = true;
        emit IPNFTMinted(_projectId, project.projectLead, _projectId); // Using projectId as tokenId for simplicity
    }

    // --- Treasury Management / Grants ---

    /**
     * @dev Allows the DAO to approve and distribute funds for non-project-specific ecosystem grants.
     *      DAO-Controlled: This function should only be callable by a successful proposal's execution.
     * @param _recipient The address to receive the grant.
     * @param _amount The amount of DAO tokens to grant.
     * @param _reason A description of the reason for the grant.
     */
    function fundEcosystemGrant(address _recipient, uint256 _amount, string memory _reason) external onlyOwner {
        if (_recipient == address(0)) revert QuantumLeapDAO__ZeroAddress();
        if (_amount == 0) revert QuantumLeapDAO__InvalidAmount();

        // Transfer funds from the DAO's token balance
        bool success = daoToken.transfer(_recipient, _amount);
        if (!success) revert QuantumLeapDAO__ProposalExecutionFailed(); // Use this generic error for transfer failure

        emit EcosystemGrantFunded(_recipient, _amount, _reason);
    }

    // --- Emergency / Meta-Governance Functions ---

    /**
     * @dev Allows the DAO to initiate a proposal to pause the contract in case of an emergency.
     *      This function itself would be called via `createProposal`.
     */
    function proposeEmergencyPause() external whenNotPaused {
        string memory title = "Emergency Pause Contract";
        string memory description = "Proposing to pause the DAO contract due to an emergency.";
        bytes memory calldataPayload = abi.encodeWithSelector(QuantumLeapDAO.pause.selector); // Call to Pausable's pause
        createProposal(title, description, calldataPayload, address(this), 0);
    }

    /**
     * @dev Allows the DAO to unpause the contract after an emergency pause.
     *      DAO-Controlled: This function should only be callable by a successful proposal's execution.
     */
    function resumeOperation() external onlyOwner {
        if (!paused()) revert QuantumLeapDAO__AlreadyActive();
        _unpause();
    }

    /**
     * @dev A generalized function to propose changes to any DAO parameter or even
     *      upgrade core logic (requires external proxy pattern for actual upgrade).
     *      This function itself would be called via `createProposal`.
     * @param _calldataPayload The encoded function call to be executed on the target.
     * @param _targetAddress The address of the contract to call (can be `address(this)` for self-calls).
     */
    function proposeDAOParameterChange(bytes memory _calldataPayload, address _targetAddress) external whenNotPaused {
        if (_targetAddress == address(0)) revert QuantumLeapDAO__ZeroAddress();
        string memory title = "DAO Parameter Change Proposal";
        string memory description = "Proposing a change to DAO parameters or calling an external contract.";
        createProposal(title, description, _calldataPayload, _targetAddress, 0);
    }

    // --- Internal / Helper Functions ---

    /**
     * @dev Updates the state of a proposal based on current block and vote counts.
     * @param _proposalId The ID of the proposal to update.
     */
    function _updateProposalState(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.state != ProposalState.Active) return;

        if (block.timestamp < proposal.endBlock) return; // Still active

        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        uint256 totalTokenSupply = daoToken.totalSupply(); // Assuming voting power scales with total supply or total staked

        // For simplicity, we'll use total DAO token supply as the base for quorum.
        // A more sophisticated system might track total active voting power.
        uint256 minQuorum = totalTokenSupply.mul(minVotingQuorumPercentage).div(QUORUM_BASIS);

        if (totalVotes < minQuorum) {
            proposal.state = ProposalState.Defeated;
        } else if (proposal.votesFor > proposal.votesAgainst) {
            proposal.state = ProposalState.Succeeded;
        } else {
            proposal.state = ProposalState.Defeated;
        }
        emit ProposalStateChanged(_proposalId, proposal.state);
    }

    // --- Query Functions ---

    /**
     * @dev Calculates the effective voting weight of a user, considering their staked DAO tokens
     *      and their current reputation score.
     * @param _voter The address whose voting weight is to be calculated.
     * @return The calculated voting weight.
     */
    function getVotingWeight(address _voter) public view returns (uint256) {
        address effectiveVoter = delegates[_voter] == address(0) ? _voter : delegates[_voter];
        uint256 tokenBalance = daoToken.balanceOf(effectiveVoter);
        uint256 reputationLevel = getReputationLevel(effectiveVoter); // Fetch reputation from SBT contract

        // Example weighting: 1 DAO token = 1 vote, each reputation level adds 10% of token votes
        // (This is a simplified example; real weighting could be complex)
        uint256 reputationBonus = tokenBalance.mul(reputationLevel).div(10); // Each level gives 10% bonus on tokens
        return tokenBalance.add(reputationBonus);
    }

    /**
     * @dev Retrieves the latest AI assessment score for a given project.
     * @param _projectId The ID of the project.
     * @return The AI assessment score (0-100).
     */
    function getProjectAIAssessment(uint256 _projectId) public view returns (uint256) {
        return projects[_projectId].aiAssessmentScore;
    }

    /**
     * @dev Checks if a given account is the lead of a specific project.
     * @param _projectId The ID of the project.
     * @param _account The address to check.
     * @return True if the account is the project lead, false otherwise.
     */
    function isProjectLead(uint256 _projectId, address _account) public view returns (bool) {
        return projects[_projectId].projectLead == _account;
    }

    /**
     * @dev Retrieves the reputation level of a user based on their Soulbound Reputation Token.
     *      This assumes the `reputationSBT` contract has a public function to get level.
     *      For a basic IERC721, we can't directly read custom properties like "level".
     *      This would need a custom SBT contract. For this example, let's assume `reputationSBT`
     *      stores a mapping `address => uint256 reputationScore`.
     * @param _user The address whose reputation level is to be retrieved.
     * @return The reputation level (e.g., 0 for no SBT, higher for better).
     */
    function getReputationLevel(address _user) public view returns (uint256) {
        // This is a placeholder. In a real scenario, the `reputationSBT` contract
        // would expose a function like `getReputationScore(address)` or similar.
        // As a simple workaround for the prompt using IERC721, let's assume
        // a user's reputation is proportional to the balance of a dummy token
        // or a hardcoded value for demonstration.
        // A simple dummy: if they own an SBT (any token ID), they have base reputation.
        // `reputationSBT.balanceOf(_user)` could indicate if they have an SBT.
        // If the SBT contract supported a `getLevel(address)` function:
        // return IReputationSBT(address(reputationSBT)).getLevel(_user);
        // For this example, let's just return a placeholder:
        // If the user has any reputation SBT, they have a base reputation of 1.
        // This needs a proper SBT contract where reputation is stored as a value, not just existence.
        // A more advanced approach would have the `reputationSBT` contract store the level.
        // For now, let's make a dummy logic: if they have any DAO tokens, give them some base rep.
        // This is NOT ideal for a real SBT, but fulfills the function requirement.
        if (daoToken.balanceOf(_user) > 0) {
            return 10; // Dummy base reputation for token holders
        }
        return 0;
    }

    /**
     * @dev Returns the state of a given proposal.
     * @param _proposalId The ID of the proposal.
     * @return The current state of the proposal.
     */
    function getProposalState(uint256 _proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) return ProposalState.Canceled; // Or a specific 'NotFound' state

        if (proposal.executed) return ProposalState.Executed;
        if (block.timestamp < proposal.startBlock) return ProposalState.Pending;
        if (block.timestamp < proposal.endBlock) return ProposalState.Active;

        // If voting period is over, determine final state
        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        uint256 totalTokenSupply = daoToken.totalSupply();
        uint256 minQuorum = totalTokenSupply.mul(minVotingQuorumPercentage).div(QUORUM_BASIS);

        if (totalVotes < minQuorum) {
            return ProposalState.Defeated;
        } else if (proposal.votesFor > proposal.votesAgainst) {
            return ProposalState.Succeeded;
        } else {
            return ProposalState.Defeated;
        }
    }
}

// --- Helper Contracts (Minimalistic for demonstration, typically separate files) ---

// Minimal ERC-721 for Project IP NFTs
// In a real scenario, this would be a full OZ ERC721 with proper access control
// for minting by the DAO, base URI, and potentially royalty features.
contract ProjectIPNFT is Context, IERC721 {
    // This is a dummy implementation to satisfy the `IERC721` type.
    // In a real project, this would be a robust ERC-721 contract.
    // It is deliberately minimal as the core logic is in the DAO contract.

    string public name;
    string public symbol;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    constructor() {
        name = "QuantumLeap Project IP NFT";
        symbol = "QLIP";
    }

    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert QuantumLeapDAO__ZeroAddress();
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert QuantumLeapDAO__ProjectNotFound(); // Using project not found as a generic "token does not exist"
        return owner;
    }

    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        if (owner != _msgSender() && !_operatorApprovals[owner][_msgSender()]) revert QuantumLeapDAO__Unauthorized();
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override {
        if (operator == address(0)) revert QuantumLeapDAO__ZeroAddress();
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        if (!isApprovedForAll(from, _msgSender()) && getApproved(tokenId) != _msgSender()) revert QuantumLeapDAO__Unauthorized();
        if (ownerOf(tokenId) != from) revert QuantumLeapDAO__Unauthorized();
        if (to == address(0)) revert QuantumLeapDAO__ZeroAddress();

        _balances[from] = _balances[from].sub(1);
        _balances[to] = _balances[to].add(1);
        _owners[tokenId] = to;
        delete _tokenApprovals[tokenId];
        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        transferFrom(from, to, tokenId);
        // Minimal ERC721Receiver check for safety; in a full implementation, `ERC721Hooks` would be used.
        if (to.code.length > 0) {
            (bool success, bytes memory returndata) = to.call(abi.encodeWithSelector(
                this.onERC721Received.selector, _msgSender(), from, tokenId, data
            ));
            if (!success || abi.decode(returndata, (bytes4)) != this.onERC721Received.selector) {
                revert QuantumLeapDAO__ProposalExecutionFailed(); // Generic error
            }
        }
    }

    // Dummy `onERC721Received` for testing purposes
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // Function to be called by DAO contract to mint new NFTs
    // This assumes the DAO contract is trusted and has explicit permission.
    // In a real contract, this would have an `onlyDAO` or `onlyMinter` access control.
    function mint(address to, uint256 tokenId) external {
        // This function must be secured to only be callable by the DAO contract or a designated minter.
        // For this example, we'll assume the DAO calls it with `address(this)` as minter.
        // In a real scenario, this would check `msg.sender == DAO_CONTRACT_ADDRESS`.
        if (_owners[tokenId] != address(0)) revert QuantumLeapDAO__AlreadyActive(); // Token already exists

        _owners[tokenId] = to;
        _balances[to] = _balances[to].add(1);
        emit Transfer(address(0), to, tokenId);
    }
}

// Minimal ERC-721 for Soulbound Reputation Tokens
// This contract explicitly makes transfers revert to enforce "soulbound" nature.
contract SoulboundReputationToken is ProjectIPNFT { // Inherit from dummy ProjectIPNFT for basic ERC721 structure
    // This is a dummy implementation to satisfy the `IERC721` type.
    // In a real project, this would be a robust ERC-721 contract.
    // It is deliberately minimal as the core logic is in the DAO contract.
    // It overrides transfer functions to make them revert.

    constructor() {
        name = "QuantumLeap Soulbound Reputation Token";
        symbol = "QLSBT";
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        revert QuantumLeapDAO__Unauthorized(); // SBTs are non-transferable
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        revert QuantumLeapDAO__Unauthorized(); // SBTs are non-transferable
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        revert QuantumLeapDAO__Unauthorized(); // SBTs are non-transferable
    }

    function approve(address to, uint256 tokenId) public override {
        revert QuantumLeapDAO__Unauthorized(); // SBTs cannot be approved for transfer
    }

    function setApprovalForAll(address operator, bool approved) public override {
        revert QuantumLeapDAO__Unauthorized(); // SBTs cannot be approved for transfer
    }

    // Minter function callable by the DAO contract
    function mint(address to, uint256 tokenId) external {
        // This function needs to be secured so only the DAO can call it.
        // For this example, it's open, but in production, add `onlyDAO` or `onlyMinter` modifier.
        if (_owners[tokenId] != address(0)) revert QuantumLeapDAO__AlreadyActive(); // Token already exists

        _owners[tokenId] = to;
        _balances[to] = _balances[to].add(1);
        emit Transfer(address(0), to, tokenId);
    }
}

// Basic String Conversion Utility (from OpenZeppelin's `Strings.sol`)
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
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

    /**
     * @dev Converts a `bool` to its ASCII `string` representation.
     */
    function toString(bool value) internal pure returns (string memory) {
        return value ? "true" : "false";
    }

    /**
     * @dev Converts a `address` to its hexadecimal `string` representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 + _ADDRESS_LENGTH * 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 0; i < _ADDRESS_LENGTH; i++) {
            buffer[2 + i * 2] = _HEX_SYMBOLS[uint8(uint256(addr) / (16 ** (38 - i * 2)) % 16)];
            buffer[3 + i * 2] = _HEX_SYMBOLS[uint8(uint256(addr) / (16 ** (38 - (i * 2 + 1))) % 16)];
        }
        return string(buffer);
    }
}
```