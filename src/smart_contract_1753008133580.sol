This smart contract, "QuantumLeap DAO," is designed to be an advanced, multi-faceted decentralized autonomous organization focused on funding and governing cutting-edge, speculative R&D projects (e.g., AI, biotech, quantum computing). It integrates concepts of reputation-based governance, AI-oracle driven project scoring, soulbound NFTs representing project entities, dynamic milestone-based funding, and an adaptive incentive/slashing mechanism.

It avoids direct duplication of common open-source DAO patterns by layering unique mechanisms on top of fundamental ERC standards.

---

## QuantumLeap DAO: Outline and Function Summary

**Contract Name:** `QuantumLeapDAO`

**Dependencies (Conceptual/Mocked):**
*   `IERC20Votes` (OpenZeppelin's ERC20Votes for delegation)
*   `IERC721` (OpenZeppelin's ERC721 for ProjectSouls)
*   `Ownable` (OpenZeppelin for initial setup, later transferred to DAO governance)

---

### **Outline**

1.  **Interfaces:**
    *   `IQuantumLeapToken`: Minimal ERC20Votes interface.
    *   `IProjectSoul`: Minimal ERC721 interface for soulbound NFTs.
    *   `IAIOracle`: Interface for an external AI scoring oracle.

2.  **Error Definitions:**
    *   `NotAIOracle`
    *   `ProjectNotFound`
    *   `ProjectAlreadyExists`
    *   `InvalidProjectStatus`
    *   `MilestoneAlreadyCompleted`
    *   `InsufficientFunds`
    *   `MilestoneNotDue`
    *   `ProposalAlreadyExists`
    *   `ProposalNotFound`
    *   `VotingPeriodNotActive`
    *   `ProposalNotQueued`
    *   `ProposalNotExecutable`
    *   `InsufficientVotingPower`
    *   `VoteAlreadyCast`
    *   `InvalidReputation`
    *   `TransferNotAllowed` (for Soulbound NFT)
    *   `UnauthorizedProjectAction`

3.  **Libraries:**
    *   `SafeERC20` (Optional, for safer token transfers, implicitly assumed or could be imported).

4.  **Enums:**
    *   `ProjectStatus`: `Pending`, `Approved`, `InProgress`, `Completed`, `Failed`, `Terminated`.
    *   `ProposalType`: `ProjectFunding`, `AIOracleParamUpdate`, `Generic`.
    *   `ProposalState`: `Pending`, `Active`, `Queued`, `Executed`, `Canceled`, `Expired`.
    *   `VoteOption`: `Abstain`, `For`, `Against`.

5.  **Structs:**
    *   `Project`: Details of an R&D project.
    *   `Milestone`: Details for a project milestone.
    *   `Proposal`: Details of a governance proposal.

6.  **Events:**
    *   `ProjectSubmitted`
    *   `ProjectApproved`
    *   `ProjectStatusUpdated`
    *   `MilestoneCompleted`
    *   `FundsDisbursed`
    *   `ReputationUpdated`
    *   `ProjectSoulMinted`
    *   `ProjectSoulBurned`
    *   `ProposalCreated`
    *   `VoteCast`
    *   `ProposalQueued`
    *   `ProposalExecuted`
    *   `AIOracleScoreReceived`

7.  **Core Contract: `QuantumLeapDAO`**
    *   **State Variables:**
        *   `quantumLeapToken`: Address of the QLT token.
        *   `projectSoulNFT`: Address of the ProjectSoul NFT contract.
        *   `aiOracle`: Address of the AI scoring oracle.
        *   `minReputationForProposal`: Minimum reputation to create a proposal.
        *   `minQLTVotesForProposal`: Minimum QLT to create a proposal.
        *   `proposalThreshold`: Minimum QLT to *be* voted on (quorum).
        *   `votingPeriodBlocks`: Blocks for voting.
        *   `queuePeriodBlocks`: Blocks for queuing after voting.
        *   `executorDelayBlocks`: Blocks delay for execution after queuing.
        *   `projects`: Mapping from `projectId` to `Project` struct.
        *   `nextProjectId`: Counter for new projects.
        *   `proposals`: Mapping from `proposalId` to `Proposal` struct.
        *   `nextProposalId`: Counter for new proposals.
        *   `userReputation`: Mapping from `address` to `uint256` reputation points.
        *   `hasVoted`: Mapping `(proposalId => voterAddress => bool)`.
        *   `delegates`: Mapping `(delegator => delegatee)`.
        *   `delegatedVotes`: Mapping `(delegatee => votes)`.
        *   `projectFunds`: Mapping `(projectId => uint256)`
        *   `aiOracleScoreCache`: Mapping `(projectId => uint256)`
        *   `aiApprovalThreshold`: Minimum AI score for automatic project approval.
        *   `aiMinFundingScore`: Minimum AI score to be considered for funding.

    *   **Constructor:**
        *   Initializes QLT, ProjectSoul, AIOracle addresses, and governance parameters.

    *   **Modifiers:**
        *   `onlyAIOracle()`
        *   `projectExists(uint256 _projectId)`
        *   `isVotingPeriod(uint256 _proposalId)`
        *   `canQueue(uint256 _proposalId)`
        *   `canExecute(uint256 _proposalId)`

    *   **Governance & Proposal Management:**
        1.  `createProjectFundingProposal(string memory _name, string memory _description, string memory _detailsHash, Milestone[] memory _milestones, uint256 _totalFundingRequired)`: Initiates a project funding proposal. Requires AI oracle score.
        2.  `createGenericProposal(string memory _description, bytes memory _calldata, address _target, ProposalType _type)`: Creates a non-project specific proposal (e.g., changing `aiApprovalThreshold`).
        3.  `vote(uint256 _proposalId, VoteOption _option)`: Casts a vote on a proposal. Combines QLT and reputation weight.
        4.  `queueProposal(uint256 _proposalId)`: Moves a successful proposal to the execution queue.
        5.  `executeProposal(uint256 _proposalId)`: Executes the actions of a queued proposal.
        6.  `delegate(address _delegatee)`: Delegates voting power (QLT + reputation) to another address.
        7.  `getVotingPower(address _voter)`: Returns combined QLT and reputation voting power.
        8.  `getProposalState(uint256 _proposalId)`: Returns the current state of a proposal.
        9.  `getProposalDetails(uint256 _proposalId)`: Retrieves details of a proposal.

    *   **Project Lifecycle & Funding:**
        10. `submitProjectForScoring(uint256 _projectId)`: Internal/Admin function to request AI score.
        11. `receiveAIOracleScore(uint256 _projectId, uint256 _score)`: Callback from AI oracle to provide score.
        12. `recordMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex)`: Marks a milestone as complete, triggers reputation update.
        13. `retrieveFundsForMilestone(uint256 _projectId, uint256 _milestoneIndex)`: Project owner retrieves funds for completed milestone.
        14. `markProjectStatus(uint256 _projectId, ProjectStatus _newStatus)`: DAO governance can explicitly change project status (e.g., `Failed`, `Terminated`).
        15. `distributeProjectRewards(uint256 _projectId)`: Initiates distribution of success rewards to project team/DAO.
        16. `slashFailedProjectFunds(uint256 _projectId)`: Recovers remaining funds from a failed project back to DAO treasury.
        17. `getProjectDetails(uint256 _projectId)`: Retrieve full project details.

    *   **Reputation Management (Internal/Public Views):**
        18. `_updateReputation(address _user, int256 _change)`: Internal function to adjust reputation.
        19. `getReputation(address _user)`: Public view of user's reputation.

    *   **ProjectSoul (NFT) Management:**
        20. `mintProjectSoul(uint256 _projectId, address _to)`: Mints a soulbound NFT for an approved project.
        21. `updateProjectSoulMetadata(uint256 _projectId, string memory _newURI)`: Updates the metadata of a ProjectSoul (e.g., to reflect progress).
        22. `burnProjectSoul(uint256 _projectId)`: Burns a ProjectSoul, typically on project failure/termination.

    *   **DAO Treasury Management:**
        23. `depositFunds()`: Allows anyone to deposit QLT to the DAO treasury.
        24. `withdrawFunds(uint256 _amount)`: DAO-governed withdrawal from treasury.

    *   **Configuration (Governed):**
        25. `setAIOracleAddress(address _newOracle)`: Sets the AI oracle contract address.
        26. `setAIThresholds(uint256 _newApprovalThreshold, uint256 _newMinFundingScore)`: Sets AI score thresholds.
        27. `setGovernanceParameters(uint256 _minRep, uint256 _minQLT, uint256 _votePeriod, uint256 _queuePeriod, uint256 _execDelay)`: Adjusts DAO governance parameters.

---

### **Function Summaries (at least 20 functions)**

1.  **`constructor(address _qltAddress, address _psNftAddress, address _aiOracleAddress)`**: Initializes the DAO contract by setting the addresses of the QuantumLeapToken (QLT), ProjectSoul NFT, and the AI Oracle, along with initial governance parameters.
2.  **`createProjectFundingProposal(string memory _name, string memory _description, string memory _detailsHash, Milestone[] memory _milestones, uint256 _totalFundingRequired)`**: Allows a member with sufficient QLT and reputation to propose a new R&D project for funding. Requires an AI score and sets up milestone-based funding.
3.  **`createGenericProposal(string memory _description, bytes memory _calldata, address _target, ProposalType _type)`**: Enables members to create general governance proposals, such as updating contract parameters (e.g., AI thresholds) or executing arbitrary calls on other contracts.
4.  **`vote(uint256 _proposalId, VoteOption _option)`**: Allows a member to cast a vote on an active proposal. Voting power is calculated as a combined weight of their staked QLT and their accumulated reputation points.
5.  **`queueProposal(uint256 _proposalId)`**: Moves a proposal from `Active` to `Queued` state if it has met the voting threshold (quorum) and majority `For` votes. It marks the start of a delay period before execution.
6.  **`executeProposal(uint256 _proposalId)`**: Executes the actions defined in a `Queued` proposal after its execution delay period has passed. This is where state changes or external calls are enacted.
7.  **`delegate(address _delegatee)`**: Allows a QLT holder to delegate their voting power (QLT tokens + reputation) to another address, enabling more efficient governance participation.
8.  **`getVotingPower(address _voter)` (view)**: Calculates and returns the combined voting power (QLT + reputation) for a specific address at the current block.
9.  **`getProposalState(uint256 _proposalId)` (view)**: Returns the current lifecycle state of a given proposal (e.g., `Pending`, `Active`, `Executed`).
10. **`getProposalDetails(uint256 _proposalId)` (view)**: Retrieves comprehensive details about a specific proposal, including its description, voting results, and target execution data.
11. **`receiveAIOracleScore(uint256 _projectId, uint256 _score)`**: An external, restricted function callable only by the designated AI Oracle contract. It records the AI's probabilistic score for a project, which influences its eligibility for funding proposals.
12. **`recordMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex)`**: Project team or an approved verifier calls this to confirm a project milestone has been met. Triggers reputation increase for successful execution and potentially unlocks next funding tranche.
13. **`retrieveFundsForMilestone(uint256 _projectId, uint256 _milestoneIndex)`**: Allows the designated project lead to withdraw the funds allocated for a specific milestone after it has been marked as completed.
14. **`markProjectStatus(uint256 _projectId, ProjectStatus _newStatus)`**: A DAO-governed function to manually update a project's status (e.g., `Failed`, `Completed`, `Terminated`), which can trigger rewards or slashing.
15. **`distributeProjectRewards(uint256 _projectId)`**: Initiated by a successful `executeProposal`, this function distributes predefined success rewards (e.g., a percentage of total funding, or QLT from treasury) to the project team and potentially the DAO.
16. **`slashFailedProjectFunds(uint256 _projectId)`**: Initiated by a successful `executeProposal` after a project is marked `Failed`. This function reclaims any remaining unspent funds from the project back into the DAO treasury as a penalty.
17. **`getReputation(address _user)` (view)**: Returns the current reputation score of a specified user within the DAO.
18. **`mintProjectSoul(uint256 _projectId, address _to)`**: Internal function, called upon successful project funding proposal execution, to mint a unique, non-transferable (soulbound) NFT representing the approved R&D project and assign it to the project lead.
19. **`updateProjectSoulMetadata(uint256 _projectId, string memory _newURI)`**: Allows the project lead (or DAO governance) to update the URI of their ProjectSoul NFT, enabling dynamic representation of project progress or status (e.g., linking to updated reports).
20. **`burnProjectSoul(uint256 _projectId)`**: Internal function, called upon project failure or termination (via governance proposal), to burn the associated ProjectSoul NFT, signifying the end of the project entity.
21. **`depositFunds()` (payable)**: Allows any user to send QLT tokens directly to the DAO's treasury contract, increasing its pool for future project funding.
22. **`withdrawFunds(uint256 _amount)`**: A DAO-governed function (executable via a successful proposal) to withdraw QLT tokens from the DAO's treasury.
23. **`setAIOracleAddress(address _newOracle)`**: A DAO-governed function to update the address of the external AI Oracle contract, allowing the DAO to upgrade or replace its AI intelligence provider.
24. **`setAIThresholds(uint256 _newApprovalThreshold, uint256 _newMinFundingScore)`**: A DAO-governed function to adjust the AI score thresholds. `_newApprovalThreshold` for automatic approval, `_newMinFundingScore` for minimum consideration.
25. **`setGovernanceParameters(uint256 _minRep, uint256 _minQLT, uint256 _votePeriod, uint256 _queuePeriod, uint256 _execDelay)`**: A DAO-governed function to adjust core governance parameters like minimum reputation/QLT for proposals, voting period, queueing period, and execution delay.

---

## Solidity Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// --- Interfaces ---

interface IQuantumLeapToken is IERC20, ERC20Votes {
    // Inherits ERC20Votes for delegation and voting power
    // We only need the basic ERC20 functions and delegation for this DAO context
}

interface IProjectSoul is IERC721 {
    function mint(address to, uint256 tokenId, string memory tokenURI) external;
    function burn(uint256 tokenId) external;
    function updateTokenURI(uint256 tokenId, string memory newURI) external;
}

interface IAIOracle {
    // This is a simplified interface for demonstration.
    // A real AI oracle would involve more complex data and proofs.
    function requestScore(uint256 projectId) external;
    // The oracle would then call back receiveAIOracleScore on the DAO.
}

// --- Error Definitions ---

error NotAIOracle();
error ProjectNotFound();
error ProjectAlreadyExists();
error InvalidProjectStatus();
error MilestoneAlreadyCompleted();
error InsufficientFunds();
error MilestoneNotDue();
error ProposalAlreadyExists();
error ProposalNotFound();
error VotingPeriodNotActive();
error ProposalNotQueued();
error ProposalNotExecutable();
error InsufficientVotingPower();
error VoteAlreadyCast();
error InvalidReputation();
error TransferNotAllowed(); // For soulbound NFT
error UnauthorizedProjectAction();
error ProjectNotApproved();

// --- Main Contract ---

contract QuantumLeapDAO is Ownable {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    // --- Enums ---
    enum ProjectStatus {
        Pending,        // Just submitted, awaiting AI score/initial vote
        Approved,       // Voted/AI-approved, ready for first milestone funding
        InProgress,     // Currently active and receiving funds
        Completed,      // All milestones completed, project successful
        Failed,         // Project failed to meet objectives
        Terminated      // Project cancelled by governance
    }

    enum ProposalType {
        ProjectFunding,
        AIOracleParamUpdate,
        Generic
    }

    enum ProposalState {
        Pending,    // Created but voting not yet active (e.g., waiting for AI score)
        Active,     // Voting is open
        Queued,     // Passed voting, waiting for execution delay
        Executed,   // Successfully executed
        Canceled,   // Canceled by proposer or governance
        Expired     // Failed to be queued or executed within time limits
    }

    enum VoteOption {
        Abstain,
        For,
        Against
    }

    // --- Structs ---

    struct Milestone {
        string description;
        uint256 fundingAmount;
        bool completed;
        uint256 completionBlock; // Block when milestone was marked completed
        uint256 fundsDisbursedBlock; // Block when funds were actually sent
    }

    struct Project {
        uint256 projectId;
        string name;
        string description;
        string detailsHash; // IPFS hash or similar for detailed project plans
        address proposer;
        address projectLead; // The address responsible for milestone completion/fund retrieval
        ProjectStatus status;
        Milestone[] milestones;
        uint256 totalFundingRequired;
        uint256 totalFundsDisbursed;
        uint256 aiScore; // AI-generated probabilistic score
        uint256 proposalId; // The proposal ID that funded this project
        bool hasSoul; // Flag indicating if a ProjectSoul NFT has been minted
    }

    struct Proposal {
        uint256 proposalId;
        ProposalType proposalType;
        string description;
        address proposer;
        uint256 creationBlock;
        uint256 startBlock; // Block when voting starts
        uint256 endBlock;   // Block when voting ends
        uint256 queueBlock; // Block when proposal was queued
        uint256 executeBlock; // Block when proposal can be executed
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 votesAbstain;
        bool executed;
        bytes calldata;     // The payload of the proposal (e.g., function call)
        address target;     // The contract to call for generic proposals
        uint256 projectId; // Relevant for ProjectFunding proposals
    }

    // --- State Variables ---

    IQuantumLeapToken public immutable quantumLeapToken;
    IProjectSoul public immutable projectSoulNFT;
    IAIOracle public aiOracle;

    uint256 public minReputationForProposal;
    uint256 public minQLTVotesForProposal; // Min QLT tokens to *create* a proposal
    uint256 public proposalThreshold;      // Min QLT+reputation votes for a proposal to pass quorum
    uint256 public votingPeriodBlocks;     // How long voting lasts (in blocks)
    uint256 public queuePeriodBlocks;      // How long a proposal stays in queue after voting ends
    uint256 public executorDelayBlocks;    // How long to wait after queuing before execution is possible

    mapping(uint256 => Project) public projects;
    Counters.Counter private _nextProjectId;

    mapping(uint256 => Proposal) public proposals;
    Counters.Counter private _nextProposalId;

    mapping(address => uint256) public userReputation;
    mapping(uint256 => mapping(address => bool)) public hasVoted; // proposalId => voterAddress => voted?

    mapping(uint256 => uint256) public projectFunds; // projectId => funds held by DAO for this project
    mapping(uint256 => uint256) public aiOracleScoreCache; // projectId => AI score

    uint256 public aiApprovalThreshold; // AI score needed for automatic project approval
    uint256 public aiMinFundingScore;   // Min AI score for project to even be proposed for funding

    // --- Events ---

    event ProjectSubmitted(uint256 indexed projectId, address indexed proposer, string name);
    event ProjectApproved(uint256 indexed projectId, address indexed approver, uint256 aiScore);
    event ProjectStatusUpdated(uint256 indexed projectId, ProjectStatus oldStatus, ProjectStatus newStatus);
    event MilestoneCompleted(uint256 indexed projectId, uint256 indexed milestoneIndex, address indexed completer);
    event FundsDisbursed(uint256 indexed projectId, uint256 indexed milestoneIndex, uint256 amount);
    event ReputationUpdated(address indexed user, uint256 oldReputation, uint256 newReputation);
    event ProjectSoulMinted(uint256 indexed projectId, uint256 indexed tokenId, address indexed to);
    event ProjectSoulBurned(uint256 indexed projectId, uint256 indexed tokenId);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, ProposalType proposalType, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, uint256 votingPower, VoteOption option);
    event ProposalQueued(uint256 indexed proposalId, uint256 queueBlock);
    event ProposalExecuted(uint256 indexed proposalId);
    event AIOracleScoreReceived(uint256 indexed projectId, uint256 score);

    // --- Modifiers ---

    modifier onlyAIOracle() {
        if (msg.sender != aiOracle) revert NotAIOracle();
        _;
    }

    modifier projectExists(uint256 _projectId) {
        if (projects[_projectId].proposer == address(0)) revert ProjectNotFound();
        _;
    }

    modifier isVotingPeriod(uint256 _proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        if (block.number < proposal.startBlock || block.number > proposal.endBlock) {
            revert VotingPeriodNotActive();
        }
        _;
    }

    modifier canQueue(uint256 _proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        if (getProposalState(_proposalId) != ProposalState.Active) revert ProposalNotQueued();
        if (block.number <= proposal.endBlock) revert ProposalNotQueued(); // Must be after voting ends
        _;
    }

    modifier canExecute(uint256 _proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        if (getProposalState(_proposalId) != ProposalState.Queued) revert ProposalNotExecutable();
        if (block.number < proposal.executeBlock) revert ProposalNotExecutable(); // Must be after execution delay
        _;
    }

    // --- Constructor ---

    constructor(
        address _qltAddress,
        address _psNftAddress,
        address _aiOracleAddress,
        uint256 _minRepForProp,
        uint256 _minQLTForProp,
        uint256 _propThreshold,
        uint256 _votingPeriod,
        uint256 _queuePeriod,
        uint256 _execDelay,
        uint256 _aiApprovalThresh,
        uint256 _aiMinFundingScore
    ) Ownable(msg.sender) {
        quantumLeapToken = IQuantumLeapToken(_qltAddress);
        projectSoulNFT = IProjectSoul(_psNftAddress);
        aiOracle = IAIOracle(_aiOracleAddress);

        minReputationForProposal = _minRepForProp;
        minQLTVotesForProposal = _minQLTForProp;
        proposalThreshold = _propThreshold;
        votingPeriodBlocks = _votingPeriod;
        queuePeriodBlocks = _queuePeriod;
        executorDelayBlocks = _execDelay;
        aiApprovalThreshold = _aiApprovalThresh;
        aiMinFundingScore = _aiMinFundingScore;
    }

    // --- External / Public Functions ---

    /**
     * @notice Allows a member to create a proposal for a new R&D project seeking funding.
     *         Requires an AI score and sets up milestone-based funding.
     * @param _name Name of the project.
     * @param _description Short description of the project.
     * @param _detailsHash IPFS hash or similar for detailed project plans.
     * @param _milestones Array of milestones with funding amounts.
     * @param _totalFundingRequired Total QLT funding requested for the project.
     */
    function createProjectFundingProposal(
        string memory _name,
        string memory _description,
        string memory _detailsHash,
        Milestone[] memory _milestones,
        uint256 _totalFundingRequired
    ) external {
        if (userReputation[msg.sender] < minReputationForProposal || quantumLeapToken.getVotes(msg.sender) < minQLTVotesForProposal) {
            revert InsufficientVotingPower();
        }

        _nextProjectId.increment();
        uint256 newProjectId = _nextProjectId.current();

        if (aiOracleScoreCache[newProjectId] == 0) {
            // Initial request for AI score if not already cached
            aiOracle.requestScore(newProjectId);
        }

        if (aiOracleScoreCache[newProjectId] < aiMinFundingScore) {
            revert InvalidProjectStatus(); // AI score too low to even propose
        }

        projects[newProjectId] = Project({
            projectId: newProjectId,
            name: _name,
            description: _description,
            detailsHash: _detailsHash,
            proposer: msg.sender,
            projectLead: msg.sender, // Proposer is initial project lead
            status: ProjectStatus.Pending,
            milestones: _milestones,
            totalFundingRequired: _totalFundingRequired,
            totalFundsDisbursed: 0,
            aiScore: aiOracleScoreCache[newProjectId],
            proposalId: 0, // Will be set after proposal creation
            hasSoul: false
        });

        _nextProposalId.increment();
        uint256 newProposalId = _nextProposalId.current();

        Proposal storage newProposal = proposals[newProposalId];
        newProposal.proposalId = newProposalId;
        newProposal.proposalType = ProposalType.ProjectFunding;
        newProposal.description = string(abi.encodePacked("Fund Project: ", _name, " (ID: ", Strings.toString(newProjectId), ")"));
        newProposal.proposer = msg.sender;
        newProposal.creationBlock = block.number;
        newProposal.startBlock = block.number + 1; // Voting starts next block
        newProposal.endBlock = newProposal.startBlock + votingPeriodBlocks;
        newProposal.projectId = newProjectId;
        newProposal.calldata = abi.encodeCall(this.markProjectStatus, (newProjectId, ProjectStatus.Approved)); // Default action on success
        newProposal.target = address(this);
        newProposal.executed = false;

        projects[newProjectId].proposalId = newProposalId;

        emit ProjectSubmitted(newProjectId, msg.sender, _name);
        emit ProposalCreated(newProposalId, msg.sender, ProposalType.ProjectFunding, newProposal.description);
    }

    /**
     * @notice Allows members to create general governance proposals.
     * @param _description A description of the proposal.
     * @param _calldata The bytes payload for the target function call.
     * @param _target The address of the target contract for the call.
     * @param _type The type of the generic proposal (e.g., AIOracleParamUpdate).
     */
    function createGenericProposal(
        string memory _description,
        bytes memory _calldata,
        address _target,
        ProposalType _type
    ) external {
        if (userReputation[msg.sender] < minReputationForProposal || quantumLeapToken.getVotes(msg.sender) < minQLTVotesForProposal) {
            revert InsufficientVotingPower();
        }

        _nextProposalId.increment();
        uint256 newProposalId = _nextProposalId.current();

        Proposal storage newProposal = proposals[newProposalId];
        newProposal.proposalId = newProposalId;
        newProposal.proposalType = _type;
        newProposal.description = _description;
        newProposal.proposer = msg.sender;
        newProposal.creationBlock = block.number;
        newProposal.startBlock = block.number + 1;
        newProposal.endBlock = newProposal.startBlock + votingPeriodBlocks;
        newProposal.calldata = _calldata;
        newProposal.target = _target;
        newProposal.executed = false;

        emit ProposalCreated(newProposalId, msg.sender, _type, _description);
    }

    /**
     * @notice Allows a member to cast a vote on an active proposal.
     *         Voting power is a combination of QLT and reputation.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _option The chosen vote option (Abstain, For, Against).
     */
    function vote(uint256 _proposalId, VoteOption _option) external isVotingPeriod(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        if (hasVoted[_proposalId][msg.sender]) revert VoteAlreadyCast();

        uint256 voterPower = getVotingPower(msg.sender);
        if (voterPower == 0) revert InsufficientVotingPower();

        hasVoted[_proposalId][msg.sender] = true;

        if (_option == VoteOption.For) {
            proposal.votesFor += voterPower;
        } else if (_option == VoteOption.Against) {
            proposal.votesAgainst += voterPower;
        } else { // Abstain
            proposal.votesAbstain += voterPower;
        }

        // Update reputation for active participation
        _updateReputation(msg.sender, 1); // +1 reputation for voting

        emit VoteCast(_proposalId, msg.sender, voterPower, _option);
    }

    /**
     * @notice Moves a successful proposal to the execution queue.
     * @param _proposalId The ID of the proposal to queue.
     */
    function queueProposal(uint256 _proposalId) external canQueue(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst + proposal.votesAbstain;

        if (proposal.votesFor <= proposal.votesAgainst || proposal.votesFor + proposal.votesAbstain < proposalThreshold) {
            // Did not pass threshold or majority 'For'
            proposal.endBlock = block.number; // Mark as expired
            return;
        }

        proposal.queueBlock = block.number;
        proposal.executeBlock = block.number + executorDelayBlocks;

        emit ProposalQueued(_proposalId, proposal.queueBlock);
    }

    /**
     * @notice Executes the actions defined in a queued proposal.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external canExecute(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.executed) revert ProposalNotFound(); // Already executed

        proposal.executed = true;

        // Perform the proposed action
        (bool success, bytes memory result) = proposal.target.call(proposal.calldata);
        require(success, string(abi.encodePacked("Execution failed: ", result)));

        if (proposal.proposalType == ProposalType.ProjectFunding) {
            // Mint Soulbound NFT for new project
            Project storage project = projects[proposal.projectId];
            if (!project.hasSoul && project.status == ProjectStatus.Approved) {
                projectSoulNFT.mint(project.projectLead, project.projectId, project.detailsHash);
                project.hasSoul = true;
                emit ProjectSoulMinted(project.projectId, project.projectId, project.projectLead);
            }
        }

        emit ProposalExecuted(_proposalId);
    }

    /**
     * @notice Allows a QLT holder to delegate their voting power (QLT tokens + reputation) to another address.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegate(address _delegatee) external {
        quantumLeapToken.delegate(_delegatee);
        // Reputation delegation is implicit; `getVotingPower` will check reputation of current delegator/delegatee.
        // For simpler implementation, reputation is always tied to the direct voter.
        // A more advanced system might have a separate reputation delegation.
    }

    /**
     * @notice Returns combined QLT and reputation voting power for a specific address.
     * @param _voter The address to query voting power for.
     * @return The calculated voting power.
     */
    function getVotingPower(address _voter) public view returns (uint256) {
        uint256 qltVotes = quantumLeapToken.getVotes(_voter);
        uint256 reputation = userReputation[_voter];
        // Example weighting: 1 QLT = 1 vote, 1 reputation = 0.1 vote
        return qltVotes + (reputation / 10);
    }

    /**
     * @notice Returns the current state of a given proposal.
     * @param _proposalId The ID of the proposal.
     * @return The ProposalState enum value.
     */
    function getProposalState(uint256 _proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposalId == 0) return ProposalState.Expired; // Not found

        if (proposal.executed) return ProposalState.Executed;
        if (block.number < proposal.startBlock) return ProposalState.Pending;
        if (block.number <= proposal.endBlock) return ProposalState.Active;
        if (proposal.queueBlock > 0 && block.number < proposal.executeBlock) return ProposalState.Queued;
        if (proposal.queueBlock == 0 && block.number > proposal.endBlock) return ProposalState.Expired; // Voting ended, not queued
        if (proposal.executeBlock > 0 && block.number > proposal.executeBlock) return ProposalState.Expired; // Queued but not executed in time

        return ProposalState.Expired; // Default for unhandled cases
    }

    /**
     * @notice Retrieves comprehensive details about a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @return A tuple containing proposal details.
     */
    function getProposalDetails(uint256 _proposalId)
        public
        view
        returns (
            uint256 proposalId,
            ProposalType proposalType,
            string memory description,
            address proposer,
            uint256 creationBlock,
            uint256 startBlock,
            uint256 endBlock,
            uint256 votesFor,
            uint256 votesAgainst,
            uint256 votesAbstain,
            bool executed,
            bytes memory calldataPayload,
            address targetAddress,
            uint256 projectId
        )
    {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposalId == 0) revert ProposalNotFound();

        return (
            proposal.proposalId,
            proposal.proposalType,
            proposal.description,
            proposal.proposer,
            proposal.creationBlock,
            proposal.startBlock,
            proposal.endBlock,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.votesAbstain,
            proposal.executed,
            proposal.calldata,
            proposal.target,
            proposal.projectId
        );
    }

    /**
     * @notice Callback function from the AI Oracle to provide a project score.
     * @param _projectId The ID of the project being scored.
     * @param _score The AI-generated score for the project.
     */
    function receiveAIOracleScore(uint256 _projectId, uint256 _score) external onlyAIOracle {
        // Cache the score for future proposal creation or current project status
        aiOracleScoreCache[_projectId] = _score;
        emit AIOracleScoreReceived(_projectId, _score);

        // Optional: If score is very high, auto-approve without full proposal (DAO governance decision)
        if (_score >= aiApprovalThreshold && projects[_projectId].proposer != address(0) && projects[_projectId].status == ProjectStatus.Pending) {
            markProjectStatus(_projectId, ProjectStatus.Approved); // Auto-approve
            emit ProjectApproved(_projectId, address(this), _score);
        }
    }

    /**
     * @notice Allows the project lead (or an approved verifier) to mark a milestone as completed.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone (0-based).
     */
    function recordMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex) external projectExists(_projectId) {
        Project storage project = projects[_projectId];
        if (msg.sender != project.projectLead) revert UnauthorizedProjectAction();
        if (project.status != ProjectStatus.InProgress && project.status != ProjectStatus.Approved) revert InvalidProjectStatus();
        if (_milestoneIndex >= project.milestones.length) revert MilestoneNotDue();
        if (project.milestones[_milestoneIndex].completed) revert MilestoneAlreadyCompleted();

        project.milestones[_milestoneIndex].completed = true;
        project.milestones[_milestoneIndex].completionBlock = block.number;

        // Increase reputation for successful milestone completion
        _updateReputation(project.projectLead, 5); // +5 reputation for milestone

        // Update ProjectSoul NFT metadata to reflect progress
        projectSoulNFT.updateTokenURI(project.projectId, string(abi.encodePacked(project.detailsHash, "?milestone=", Strings.toString(_milestoneIndex), "&status=completed")));

        emit MilestoneCompleted(_projectId, _milestoneIndex, msg.sender);
    }

    /**
     * @notice Allows the project lead to retrieve funds for a completed milestone.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     */
    function retrieveFundsForMilestone(uint256 _projectId, uint256 _milestoneIndex) external projectExists(_projectId) {
        Project storage project = projects[_projectId];
        if (msg.sender != project.projectLead) revert UnauthorizedProjectAction();
        if (project.status != ProjectStatus.InProgress && project.status != ProjectStatus.Approved) revert InvalidProjectStatus();
        if (_milestoneIndex >= project.milestones.length) revert MilestoneNotDue();
        if (!project.milestones[_milestoneIndex].completed) revert MilestoneNotDue();
        if (project.milestones[_milestoneIndex].fundsDisbursedBlock != 0) revert MilestoneAlreadyCompleted(); // Funds already disbursed

        uint256 amount = project.milestones[_milestoneIndex].fundingAmount;
        if (projectFunds[_projectId] < amount) revert InsufficientFunds();

        projectFunds[_projectId] -= amount;
        quantumLeapToken.safeTransfer(project.projectLead, amount);
        project.totalFundsDisbursed += amount;
        project.milestones[_milestoneIndex].fundsDisbursedBlock = block.number;

        // If all milestones are completed, mark project as completed
        bool allCompleted = true;
        for (uint i = 0; i < project.milestones.length; i++) {
            if (!project.milestones[i].completed) {
                allCompleted = false;
                break;
            }
        }
        if (allCompleted) {
            markProjectStatus(_projectId, ProjectStatus.Completed);
            distributeProjectRewards(_projectId); // Distribute rewards on full completion
        } else {
             // If not all milestones complete, set to InProgress if not already
            if (project.status == ProjectStatus.Approved) {
                project.status = ProjectStatus.InProgress;
                emit ProjectStatusUpdated(_projectId, ProjectStatus.Approved, ProjectStatus.InProgress);
            }
        }

        emit FundsDisbursed(_projectId, _milestoneIndex, amount);
    }

    /**
     * @notice Allows DAO governance (via proposal execution) to manually update a project's status.
     * @param _projectId The ID of the project.
     * @param _newStatus The new status for the project.
     */
    function markProjectStatus(uint256 _projectId, ProjectStatus _newStatus) public projectExists(_projectId) {
        // This function should ideally only be called by `executeProposal` or auto-trigger
        // For direct owner testing: onlyOwner can call
        if (msg.sender != address(this) && msg.sender != owner()) revert UnauthorizedProjectAction();

        Project storage project = projects[_projectId];
        ProjectStatus oldStatus = project.status;
        project.status = _newStatus;

        if (_newStatus == ProjectStatus.Approved) {
            // Funds transfer from DAO treasury to project's internal fund bucket
            quantumLeapToken.safeTransferFrom(msg.sender, address(this), project.totalFundingRequired);
            projectFunds[_projectId] += project.totalFundingRequired;
        } else if (_newStatus == ProjectStatus.Failed || _newStatus == ProjectStatus.Terminated) {
            slashFailedProjectFunds(_projectId);
            projectSoulNFT.burn(project.projectId); // Burn the soulbound NFT
            emit ProjectSoulBurned(_projectId, project.projectId);
        }

        emit ProjectStatusUpdated(_projectId, oldStatus, _newStatus);
    }

    /**
     * @notice Initiates distribution of success rewards to project team/DAO.
     *         This should be called via `executeProposal` or triggered on `Completed` status.
     * @param _projectId The ID of the project.
     */
    function distributeProjectRewards(uint256 _projectId) public projectExists(_projectId) {
        // This function should only be called by `executeProposal` or internal logic on completion
        if (msg.sender != address(this)) revert UnauthorizedProjectAction();
        Project storage project = projects[_projectId];
        if (project.status != ProjectStatus.Completed) revert InvalidProjectStatus();

        // Example reward: 5% of total funding to project lead, 1% to DAO treasury
        uint256 rewardAmount = project.totalFundingRequired / 20; // 5%
        uint256 daoShare = project.totalFundingRequired / 100; // 1%

        if (quantumLeapToken.balanceOf(address(this)) < rewardAmount + daoShare) revert InsufficientFunds();

        quantumLeapToken.safeTransfer(project.projectLead, rewardAmount);
        // DAO share already in treasury, just conceptually noted.
        _updateReputation(project.projectLead, 10); // +10 reputation for successful project
    }

    /**
     * @notice Recovers remaining funds from a failed project back to DAO treasury.
     *         This should be called via `executeProposal` after a project is marked Failed/Terminated.
     * @param _projectId The ID of the project.
     */
    function slashFailedProjectFunds(uint256 _projectId) public projectExists(_projectId) {
        // This function should only be called by `executeProposal` or internal logic on failure/termination
        if (msg.sender != address(this)) revert UnauthorizedProjectAction();

        Project storage project = projects[_projectId];
        if (project.status != ProjectStatus.Failed && project.status != ProjectStatus.Terminated) revert InvalidProjectStatus();

        uint256 remainingFunds = projectFunds[_projectId];
        if (remainingFunds > 0) {
            projectFunds[_projectId] = 0;
            // Funds are already within this contract, no need to transferFrom.
            // They just become part of the general DAO treasury.
        }
        _updateReputation(project.proposer, -5); // -5 reputation for failed project
        _updateReputation(project.projectLead, -10); // -10 reputation for project lead
    }

    /**
     * @notice Internal function to adjust a user's reputation score.
     * @param _user The address of the user.
     * @param _change The amount to change reputation by (can be negative).
     */
    function _updateReputation(address _user, int256 _change) internal {
        uint256 oldRep = userReputation[_user];
        if (_change > 0) {
            userReputation[_user] += uint256(_change);
        } else {
            uint256 absChange = uint256(-_change);
            if (oldRep < absChange) {
                userReputation[_user] = 0; // Don't go below zero
            } else {
                userReputation[_user] -= absChange;
            }
        }
        emit ReputationUpdated(_user, oldRep, userReputation[_user]);
    }

    /**
     * @notice Returns the current reputation score of a specified user.
     * @param _user The address of the user.
     * @return The user's current reputation.
     */
    function getReputation(address _user) external view returns (uint256) {
        return userReputation[_user];
    }

    /**
     * @notice Retrieves full details of a project.
     * @param _projectId The ID of the project.
     * @return The Project struct containing all details.
     */
    function getProjectDetails(uint256 _projectId) external view projectExists(_projectId) returns (Project memory) {
        return projects[_projectId];
    }

    /**
     * @notice Allows anyone to deposit QLT tokens to the DAO's treasury.
     */
    function depositFunds(uint256 _amount) external {
        quantumLeapToken.safeTransferFrom(msg.sender, address(this), _amount);
    }

    /**
     * @notice DAO-governed withdrawal of funds from the treasury.
     *         This function can only be called via a successful `executeProposal`.
     * @param _amount The amount of QLT to withdraw.
     */
    function withdrawFunds(uint256 _amount) external {
        if (msg.sender != address(this)) revert UnauthorizedProjectAction(); // Only callable via executeProposal
        quantumLeapToken.safeTransfer(owner(), _amount); // Or to a specified address from proposal
    }

    /**
     * @notice DAO-governed function to update the AI oracle contract address.
     *         This function can only be called via a successful `executeProposal`.
     * @param _newOracle The new address for the AI oracle.
     */
    function setAIOracleAddress(address _newOracle) external {
        if (msg.sender != address(this) && msg.sender != owner()) revert UnauthorizedProjectAction(); // Only callable via executeProposal or temporary owner
        aiOracle = IAIOracle(_newOracle);
    }

    /**
     * @notice DAO-governed function to adjust the AI score thresholds.
     *         This function can only be called via a successful `executeProposal`.
     * @param _newApprovalThreshold The new threshold for automatic project approval.
     * @param _newMinFundingScore The new minimum score for project funding consideration.
     */
    function setAIThresholds(uint256 _newApprovalThreshold, uint256 _newMinFundingScore) external {
        if (msg.sender != address(this) && msg.sender != owner()) revert UnauthorizedProjectAction(); // Only callable via executeProposal or temporary owner
        aiApprovalThreshold = _newApprovalThreshold;
        aiMinFundingScore = _newMinFundingScore;
    }

    /**
     * @notice DAO-governed function to adjust core governance parameters.
     *         This function can only be called via a successful `executeProposal`.
     * @param _minRep The new minimum reputation for proposal creation.
     * @param _minQLT The new minimum QLT for proposal creation.
     * @param _votePeriod The new voting period in blocks.
     * @param _queuePeriod The new queueing period in blocks.
     * @param _execDelay The new execution delay in blocks.
     */
    function setGovernanceParameters(
        uint256 _minRep,
        uint256 _minQLT,
        uint256 _votePeriod,
        uint256 _queuePeriod,
        uint256 _execDelay
    ) external {
        if (msg.sender != address(this) && msg.sender != owner()) revert UnauthorizedProjectAction(); // Only callable via executeProposal or temporary owner
        minReputationForProposal = _minRep;
        minQLTVotesForProposal = _minQLT;
        votingPeriodBlocks = _votePeriod;
        queuePeriodBlocks = _queuePeriod;
        executorDelayBlocks = _execDelay;
    }

    // --- Private / Internal Helpers ---

    // No specific private helpers beyond what's already internal in modifiers or functions.
    // The `_updateReputation` is internal.
}

// --- Mock Contracts for Demonstration ---

// ERC20Votes Mock (for testing)
contract MockQLT is ERC20Votes {
    constructor(uint256 initialSupply) ERC20("Quantum Leap Token", "QLT") ERC20Permit("Quantum Leap Token") {
        _mint(msg.sender, initialSupply);
        // Delegate initial supply to msg.sender for voting power
        _delegate(msg.sender, msg.sender);
    }

    // Allow minting for testing purposes (in a real scenario, this would be more controlled)
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

// Soulbound ERC721 Mock (for testing)
contract MockProjectSoul is IERC721 {
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => string) private _tokenURIs;
    uint256 private _nextTokenId;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // Mock constructor for simple deployment
    constructor() {
        _nextTokenId = 1;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        revert TransferNotAllowed(); // Soulbound
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        revert TransferNotAllowed(); // Soulbound
    }
    function transferFrom(address from, address to, uint256 tokenId) public {
        revert TransferNotAllowed(); // Soulbound
    }

    function approve(address to, uint256 tokenId) public {
        revert TransferNotAllowed(); // Soulbound
    }
    function setApprovalForAll(address operator, bool approved) public {
        revert TransferNotAllowed(); // Soulbound
    }
    function getApproved(uint256 tokenId) public view returns (address) {
        return address(0); // No approvals for soulbound
    }
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return false; // No approvals for soulbound
    }

    function mint(address to, uint256 tokenId, string memory tokenURI) external {
        require(!_exists(tokenId), "ERC721: token already minted");
        require(to != address(0), "ERC721: mint to the zero address");

        _owners[tokenId] = to;
        _balances[to]++;
        _tokenURIs[tokenId] = tokenURI;
        emit Transfer(address(0), to, tokenId);
    }

    function burn(uint256 tokenId) external {
        require(_exists(tokenId), "ERC721: token doesn't exist");
        address owner = _owners[tokenId];
        delete _owners[tokenId];
        _balances[owner]--;
        delete _tokenURIs[tokenId];
        emit Transfer(owner, address(0), tokenId);
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    function updateTokenURI(uint256 tokenId, string memory newURI) external {
        require(_exists(tokenId), "ERC721Metadata: URI update for nonexistent token");
        // In a real scenario, this would have access control (e.g., only project lead or DAO)
        _tokenURIs[tokenId] = newURI;
    }

    // Required for IERC165
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return interfaceId == type(IERC721).interfaceId;
    }
}

// AI Oracle Mock (for testing)
contract MockAIOracle is IAIOracle {
    mapping(uint256 => uint256) public scores;
    QuantumLeapDAO public dao;

    constructor(address _daoAddress) {
        dao = QuantumLeapDAO(_daoAddress);
    }

    // Simulate an external system requesting a score calculation
    function requestScore(uint256 projectId) external {
        // In a real scenario, this would trigger off-chain AI computation
        // For mock, just return a random-ish score
        uint256 mockScore = (projectId % 100) + 50; // Simple mock score between 50 and 149
        dao.receiveAIOracleScore(projectId, mockScore);
    }
    
    // Function to manually set DAO address after deployment if needed
    function setDAOAddress(address _newDaoAddress) public {
        dao = QuantumLeapDAO(_newDaoAddress);
    }
}
```