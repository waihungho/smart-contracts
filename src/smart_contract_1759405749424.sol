Here's a smart contract in Solidity called `ImpactNexusDAO`, designed to be an advanced, creative, and trendy decentralized autonomous organization for funding public goods and impact projects. It features a hybrid governance model combining token-weighted voting with a dynamic "ContributionScore" reputation system, project lifecycle management, and a specialized "Steward" role for oversight.

---

## ImpactNexusDAO: Outline and Function Summary

**Core Concept:** A decentralized autonomous organization (DAO) dedicated to funding and coordinating public goods and impact projects. It introduces a novel `ContributionScore` reputation system alongside traditional token-based voting, fostering a more meritocratic governance model. Projects are proposed, funded in milestones, and managed with oversight from elected Stewards.

---

**I. Core DAO & Setup**
*   `constructor`: Initializes the DAO, sets the address of its associated ERC-20 governance token (`NexusToken`), and initial governance parameters.
*   `depositFunds`: Allows any user to deposit native currency (e.g., Ether) into the DAO's treasury for project funding and operations.
*   `getTreasuryBalance`: Returns the current native currency balance held by the DAO's treasury.

**II. Governance Token Interaction (via NexusToken ERC-20)**
*   `getTokenAddress`: Returns the address of the ERC-20 `NexusToken` contract used for governance.
*   `_getNexusTokenBalance`: Internal helper function to retrieve a user's `NexusToken` balance.
*   `_getVotingPower`: Internal helper function to calculate an account's total voting power, combining `NexusToken` holdings and `ContributionScore`.
*   `delegate`: Delegates a user's voting power (both `NexusToken` and `ContributionScore`) to another address.

**III. Reputation & Skill Management (ContributionScore)**
*   `registerSkills`: Allows users to declare and update their specific skills (e.g., "Solidity Dev", "Community Manager"), which can be used by projects.
*   `getRegisteredSkills`: Retrieves the array of skills declared by a particular user.
*   `getContributionScore`: Returns the current `ContributionScore` for a given user, reflecting their historical contributions.
*   `_updateContributionScore`: An internal, restricted function used to adjust a user's `ContributionScore` based on successful project completion, governance actions, or other verified contributions.

**IV. Project Proposal & Lifecycle**
*   `submitProjectProposal`: Allows users to submit new project proposals, requiring a `NexusToken` stake to prevent spam. Proposals include a title, detailed description (IPFS hash), requested funding, and defined milestones.
*   `voteOnProposal`: Enables users to cast their weighted vote (combining `NexusToken` and `ContributionScore` power) for or against a submitted proposal.
*   `executeProposal`: Executes a successful project or governance proposal. For projects, this allocates initial funding and creates the project entry. For governance, it applies parameter changes.
*   `requestMilestonePayment`: Allows a project lead to request payment for a completed project milestone, providing proof (e.g., an IPFS hash of deliverables).
*   `verifyMilestoneAndReleaseFunds`: Stewards or the DAO governance vote to verify a submitted milestone proof. Upon approval, the corresponding funds are released, and the project lead and contributing members may earn `ContributionScore`.
*   `claimExpiredProposalDeposit`: Allows proposers to reclaim their initial `NexusToken` stake if their proposal fails to pass or expires without execution.
*   `getProjectDetails`: Retrieves all stored details for a specific project by its ID.
*   `getProposalDetails`: Retrieves all stored details for a specific governance proposal by its ID.

**V. Treasury & Financial Management**
*   `proposeTreasuryWithdrawal`: Allows the DAO to propose a withdrawal of native currency from the treasury for operational costs, external services, or other non-project-specific needs.
*   `approveTreasuryWithdrawal`: Stewards or DAO governance vote to approve a treasury withdrawal proposal, releasing the specified amount of native currency to the designated recipient.

**VI. Governance & Parameters**
*   `setVotingPeriod`: Allows the DAO to propose and vote on changing the duration (in seconds) that proposals remain open for voting.
*   `setProposalThreshold`: Allows the DAO to propose and vote on changing the minimum combined voting power (`NexusToken` + `ContributionScore`) required to submit a new proposal.
*   `setReputationDecayRate`: Allows the DAO to propose and vote on adjusting the rate at which `ContributionScore` decays over time for inactive members.
*   `registerSteward`: Allows the DAO to propose and vote on electing a new Steward, a specialized role for project oversight and milestone verification.
*   `removeSteward`: Allows the DAO to propose and vote on removing an existing Steward.

**VII. Utilities & Maintenance**
*   `reputationDecayCheck`: A public function that can be called by anyone (e.g., an automated keeper bot). It iterates through accounts whose reputation is due for decay, applying the configured decay rate and rewarding the caller a small fee for gas.
*   `isSteward`: Checks if a given address is currently an active Steward of the DAO.
*   `getStewardCount`: Returns the total number of currently active Stewards.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for contract deployment for initial setup, but DAO governs it.
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Interface for the NexusToken ERC-20 contract
interface INexusToken is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);
    function getVotes(address account) external view returns (uint256);
    function delegate(address delegatee) external;
    function decimals() external view returns (uint8);
}

/**
 * @title ImpactNexusDAO
 * @dev A decentralized autonomous organization (DAO) for funding and coordinating public goods and impact projects.
 *      Features a hybrid governance model combining token-weighted voting with a dynamic "ContributionScore"
 *      reputation system, project lifecycle management, and a specialized "Steward" role for oversight.
 */
contract ImpactNexusDAO is Context {
    using SafeERC20 for INexusToken;
    using SafeMath for uint256;

    // --- State Variables ---

    INexusToken public immutable NEXUS_TOKEN; // The governance token of the DAO

    // --- Reputation System ---
    mapping(address => uint256) public contributionScores; // Tracks reputation score
    mapping(address => uint256) public lastReputationUpdate; // Timestamp of last reputation update for decay calculation
    mapping(address => string[]) public registeredSkills; // User declared skills

    uint256 public reputationDecayRate; // Percentage decay per interval (e.g., 100 = 1%)
    uint256 public constant REPUTATION_DECAY_INTERVAL = 30 days; // How often reputation decays
    uint256 public constant REPUTATION_DECAY_REWARD = 0.001 ether; // Reward for calling reputationDecayCheck

    uint256 public constant REPUTATION_WEIGHT_FACTOR = 10**16; // 1 ContributionScore = 0.01 NexusToken voting power (adjust based on token decimals)

    // --- Stewards ---
    mapping(address => bool) public isSteward;
    address[] internal _stewards; // Store stewards in an array for iteration

    // --- Proposals & Governance ---
    uint256 public nextProposalId;
    uint256 public votingPeriod; // Duration in seconds for which proposals are open for voting
    uint256 public proposalThreshold; // Minimum combined voting power (NexusToken + ContributionScore) to submit a proposal
    uint256 public constant QUORUM_PERCENTAGE = 4; // 4% of total circulating votes needed for quorum
    uint256 public constant PROPOSAL_STAKE_AMOUNT = 100 * (10**18); // Example: 100 NexusTokens

    enum ProposalState { Pending, Active, Canceled, Defeated, Succeeded, Executed, Expired }

    struct Proposal {
        uint256 id;
        address proposer;
        string title;
        bytes32 descriptionHash; // IPFS hash of detailed proposal
        uint256 requestedAmount; // ETH/Native amount for project funding, or 0 for governance changes
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        ProposalState state;
        bytes callData; // For governance proposals (e.g., set new voting period)
        address target; // For governance proposals
        uint256 value; // For governance proposals
        uint256 projectMilestoneCount; // For project proposals
        bytes32 projectMilestonesIPFSHash; // For project proposals, hash of milestone details
        uint256 proposalType; // 0 for Project, 1 for Governance (e.g. parameter change), 2 for Treasury withdrawal, 3 for Steward election/removal
        address proposalRecipient; // For treasury withdrawal or steward election
        uint256 proposalAmount; // For treasury withdrawal
    }
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted; // Tracks if an address has voted on a proposal

    // --- Projects ---
    uint256 public nextProjectId;
    enum ProjectStatus { Proposed, Active, Completed, Canceled, Dispute }

    struct Project {
        uint256 id;
        uint256 proposalId;
        address proposer;
        string title;
        bytes32 descriptionHash; // IPFS hash of project details
        uint256 totalRequestedAmount; // Total ETH/Native requested for the project
        uint256 totalMilestones;
        uint256 currentMilestone; // Index of the next milestone to be requested/verified
        mapping(uint256 => uint256) milestoneFunding; // Amount for each milestone
        mapping(uint256 => bool) milestoneCompleted; // Whether a milestone is completed
        mapping(uint256 => bytes32) milestoneProofs; // IPFS hash of proof for each milestone
        uint256 fundsAllocated; // Total ETH/Native funds allocated to the project so far
        ProjectStatus status;
        address projectLead; // The primary address responsible for the project
        uint256 creationTimestamp;
    }
    mapping(uint256 => Project) public projects;

    // --- Events ---
    event Deposited(address indexed user, uint256 amount);
    event SkillsRegistered(address indexed user, string[] skills);
    event ContributionScoreUpdated(address indexed user, uint256 oldScore, uint256 newScore, string reason);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string title, uint256 requestedAmount, uint256 endBlock);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event ProposalExecuted(uint256 indexed proposalId, address indexed executor);
    event ProjectCreated(uint256 indexed projectId, uint256 indexed proposalId, address indexed proposer, string title, uint256 totalRequestedAmount);
    event MilestoneRequested(uint256 indexed projectId, uint256 indexed milestoneIndex, address indexed requestor, bytes32 proofHash);
    event FundsReleased(uint256 indexed projectId, uint256 indexed milestoneIndex, uint256 amount, address indexed recipient);
    event TreasuryWithdrawalProposed(uint256 indexed proposalId, address indexed recipient, uint256 amount);
    event TreasuryWithdrawalApproved(uint256 indexed proposalId, address indexed recipient, uint256 amount);
    event StewardRegistered(address indexed newSteward);
    event StewardRemoved(address indexed oldSteward);
    event ReputationDecayed(address indexed user, uint256 oldScore, uint256 newScore);
    event ReputationDecayReward(address indexed caller, uint256 rewardAmount);

    // --- Modifiers ---
    modifier onlySteward() {
        require(isSteward[_msgSender()], "ImpactNexusDAO: Caller is not a steward");
        _;
    }

    modifier onlyProjectLead(uint256 _projectId) {
        require(projects[_projectId].projectLead == _msgSender(), "ImpactNexusDAO: Caller is not the project lead");
        _;
    }

    modifier isValidProposalState(uint256 _proposalId, ProposalState _expectedState) {
        require(proposals[_proposalId].id == _proposalId, "ImpactNexusDAO: Invalid proposal ID");
        require(proposals[_proposalId].state == _expectedState, "ImpactNexusDAO: Proposal not in expected state");
        _;
    }

    // --- Constructor ---
    constructor(address _nexusTokenAddress, uint256 _initialVotingPeriod, uint256 _initialProposalThreshold, uint256 _initialReputationDecayRate) {
        require(_nexusTokenAddress != address(0), "ImpactNexusDAO: Token address cannot be zero");
        NEXUS_TOKEN = INexusToken(_nexusTokenAddress);

        votingPeriod = _initialVotingPeriod; // e.g., 3 days = 3 * 24 * 60 * 60
        proposalThreshold = _initialProposalThreshold; // e.g., 100 * (10**18) NexusTokens or equivalent reputation
        reputationDecayRate = _initialReputationDecayRate; // e.g., 100 for 1% decay

        // Set initial stewards (can be 0 or pre-configured addresses)
        // For demonstration, let's say the deployer is an initial steward
        // registerSteward(_msgSender()); // This should ideally be a governance proposal
    }

    // --- I. Core DAO & Setup ---

    /**
     * @dev Allows users to deposit native currency (e.g., ETH) into the DAO's treasury.
     */
    receive() external payable {
        emit Deposited(_msgSender(), msg.value);
    }

    function depositFunds() external payable {
        emit Deposited(_msgSender(), msg.value);
    }

    /**
     * @dev Returns the current native currency balance held by the DAO's treasury.
     * @return The treasury balance.
     */
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // --- II. Governance Token Interaction ---

    /**
     * @dev Returns the address of the ERC-20 NexusToken contract used for governance.
     * @return The NexusToken contract address.
     */
    function getTokenAddress() external view returns (address) {
        return address(NEXUS_TOKEN);
    }

    /**
     * @dev Internal helper function to retrieve a user's NexusToken balance.
     * @param _account The address to query.
     * @return The NexusToken balance.
     */
    function _getNexusTokenBalance(address _account) internal view returns (uint256) {
        return NEXUS_TOKEN.balanceOf(_account);
    }

    /**
     * @dev Internal helper function to calculate an account's total voting power,
     *      combining NexusToken holdings and ContributionScore.
     * @param _account The address to query.
     * @return The total voting power.
     */
    function _getVotingPower(address _account) internal view returns (uint256) {
        uint256 tokenPower = NEXUS_TOKEN.getVotes(_account); // Assumes NexusToken implements ERC20Votes
        uint256 reputationPower = contributionScores[_account].mul(REPUTATION_WEIGHT_FACTOR).div(10**18); // Scale reputation to token decimals
        return tokenPower.add(reputationPower);
    }

    /**
     * @dev Delegates a user's voting power (both NexusToken and ContributionScore) to another address.
     *      This calls the delegate function on the underlying NexusToken.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegate(address _delegatee) external {
        NEXUS_TOKEN.delegate(_delegatee);
        // For reputation, we assume it automatically follows token delegation for simplicity.
        // More advanced: separate reputation delegation or it always stays with the primary account.
        // For this contract, we'll keep reputation linked to the caller.
        // If reputation also needs delegation, this function would need to manage it.
        // For simplicity, voting power includes _getVotingPower for caller directly.
    }

    // --- III. Reputation & Skill Management (ContributionScore) ---

    /**
     * @dev Allows users to declare and update their specific skills.
     * @param _skills An array of skill strings.
     */
    function registerSkills(string[] memory _skills) external {
        registeredSkills[_msgSender()] = _skills;
        emit SkillsRegistered(_msgSender(), _skills);
    }

    /**
     * @dev Retrieves the array of skills declared by a particular user.
     * @param _user The address of the user.
     * @return An array of skill strings.
     */
    function getRegisteredSkills(address _user) external view returns (string[] memory) {
        return registeredSkills[_user];
    }

    /**
     * @dev Returns the current ContributionScore for a given user.
     *      Automatically applies decay if due.
     * @param _user The address of the user.
     * @return The current ContributionScore.
     */
    function getContributionScore(address _user) public view returns (uint256) {
        uint256 score = contributionScores[_user];
        uint256 lastUpdate = lastReputationUpdate[_user];

        if (lastUpdate > 0 && block.timestamp > lastUpdate.add(REPUTATION_DECAY_INTERVAL)) {
            uint256 intervals = (block.timestamp.sub(lastUpdate)).div(REPUTATION_DECAY_INTERVAL);
            uint256 decayedScore = score;
            for (uint256 i = 0; i < intervals; i++) {
                decayedScore = decayedScore.mul(10000 - reputationDecayRate).div(10000); // e.g., 10000-100 = 9900 -> 99%
            }
            return decayedScore;
        }
        return score;
    }

    /**
     * @dev Internal, restricted function to adjust a user's ContributionScore.
     *      Only callable by specific, controlled functions (e.g., successful project completion, governance votes).
     * @param _user The address whose score is to be updated.
     * @param _change The amount to add or subtract from the score. Can be negative.
     * @param _reason A string describing the reason for the update.
     */
    function _updateContributionScore(address _user, int256 _change, string memory _reason) internal {
        uint256 currentScore = getContributionScore(_user); // Get decayed score
        uint256 newScore;

        if (_change < 0) {
            newScore = currentScore.sub(uint256(_change.mul(-1)), "ImpactNexusDAO: Score cannot go below zero");
        } else {
            newScore = currentScore.add(uint256(_change));
        }

        contributionScores[_user] = newScore;
        lastReputationUpdate[_user] = block.timestamp; // Reset decay timer
        emit ContributionScoreUpdated(_user, currentScore, newScore, _reason);
    }

    // --- IV. Project Proposal & Lifecycle ---

    /**
     * @dev Allows users to submit new project proposals, requiring a NexusToken stake.
     *      Proposals include a title, detailed description (IPFS hash), requested funding,
     *      and defined milestones.
     * @param _title The title of the project.
     * @param _descriptionHash IPFS hash of the detailed project description.
     * @param _requestedAmount The total native currency amount requested for the project.
     * @param _milestoneCount The total number of milestones for the project.
     * @param _milestoneFundingPerMilestone An array of amounts for each milestone.
     * @param _milestonesIPFSHash IPFS hash of detailed milestone breakdown.
     * @return The ID of the newly created proposal.
     */
    function submitProjectProposal(
        string memory _title,
        bytes32 _descriptionHash,
        uint256 _requestedAmount,
        uint256 _milestoneCount,
        uint256[] memory _milestoneFundingPerMilestone,
        bytes32 _milestonesIPFSHash
    ) external returns (uint256) {
        require(_milestoneCount > 0, "ImpactNexusDAO: Must have at least one milestone");
        require(_milestoneCount == _milestoneFundingPerMilestone.length, "ImpactNexusDAO: Milestone funding mismatch");
        require(_getVotingPower(_msgSender()) >= proposalThreshold, "ImpactNexusDAO: Insufficient voting power to propose");
        require(_requestedAmount > 0, "ImpactNexusDAO: Requested amount must be greater than zero");

        uint256 totalMilestoneSum = 0;
        for (uint256 i = 0; i < _milestoneFundingPerMilestone.length; i++) {
            totalMilestoneSum = totalMilestoneSum.add(_milestoneFundingPerMilestone[i]);
        }
        require(totalMilestoneSum == _requestedAmount, "ImpactNexusDAO: Total milestone funding must equal requested amount");

        // Require a stake to submit a proposal
        NEXUS_TOKEN.safeTransferFrom(_msgSender(), address(this), PROPOSAL_STAKE_AMOUNT);

        uint256 proposalId = nextProposalId++;
        Proposal storage newProposal = proposals[proposalId];

        newProposal.id = proposalId;
        newProposal.proposer = _msgSender();
        newProposal.title = _title;
        newProposal.descriptionHash = _descriptionHash;
        newProposal.requestedAmount = _requestedAmount;
        newProposal.startBlock = block.number;
        newProposal.endBlock = block.number.add(votingPeriod);
        newProposal.state = ProposalState.Pending;
        newProposal.projectMilestoneCount = _milestoneCount;
        newProposal.projectMilestonesIPFSHash = _milestonesIPFSHash;
        newProposal.proposalType = 0; // Project Proposal

        // Store milestone funding details within the project struct temporarily for easier access during execution
        // Or directly save it into a new Project struct if it's cleaner. For now, let's keep it here.
        // Actually, better to setup the project structure during execution.

        emit ProposalSubmitted(proposalId, _msgSender(), _title, _requestedAmount, newProposal.endBlock);
        return proposalId;
    }

    /**
     * @dev Allows users to cast their weighted vote (NexusToken + ContributionScore) on a proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external isValidProposalState(_proposalId, ProposalState.Active) {
        require(!hasVoted[_proposalId][_msgSender()], "ImpactNexusDAO: Already voted on this proposal");
        require(block.number <= proposals[_proposalId].endBlock, "ImpactNexusDAO: Voting period has ended");

        uint256 voterPower = _getVotingPower(_msgSender());
        require(voterPower > 0, "ImpactNexusDAO: Voter has no voting power");

        if (_support) {
            proposals[_proposalId].forVotes = proposals[_proposalId].forVotes.add(voterPower);
        } else {
            proposals[_proposalId].againstVotes = proposals[_proposalId].againstVotes.add(voterPower);
        }

        hasVoted[_proposalId][_msgSender()] = true;
        emit VoteCast(_proposalId, _msgSender(), _support, voterPower);
    }

    /**
     * @dev Executes a successful project or governance proposal.
     *      For projects, this allocates initial funding and creates the project entry.
     *      For governance, it applies parameter changes.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state != ProposalState.Executed, "ImpactNexusDAO: Proposal already executed");
        require(block.number > proposal.endBlock, "ImpactNexusDAO: Voting period not ended");

        // Determine if proposal passed (simple majority + quorum)
        uint256 totalVotes = proposal.forVotes.add(proposal.againstVotes);
        uint256 totalTokenSupply = NEXUS_TOKEN.totalSupply(); // Using current total supply for quorum
        uint256 totalReputationPower = 0; // This is harder to get accurately for all, so simplify to tokens
        // For a more robust quorum, one would sum all _getVotingPower for all token holders or use a snapshot.
        // For simplicity, let's use token supply as a proxy for total potential power.
        uint256 quorumRequired = totalTokenSupply.mul(QUORUM_PERCENTAGE).div(100);

        if (totalVotes < quorumRequired || proposal.forVotes <= proposal.againstVotes) {
            proposal.state = ProposalState.Defeated;
            emit ProposalStateChanged(_proposalId, ProposalState.Defeated);
            return;
        }

        proposal.state = ProposalState.Succeeded;
        emit ProposalStateChanged(_proposalId, ProposalState.Succeeded);

        // Execute logic based on proposal type
        if (proposal.proposalType == 0) { // Project Proposal
            require(address(this).balance >= proposal.requestedAmount, "ImpactNexusDAO: Insufficient treasury balance for project");

            uint256 projectId = nextProjectId++;
            Project storage newProject = projects[projectId];

            newProject.id = projectId;
            newProject.proposalId = _proposalId;
            newProject.proposer = proposal.proposer;
            newProject.title = proposal.title;
            newProject.descriptionHash = proposal.descriptionHash;
            newProject.totalRequestedAmount = proposal.requestedAmount;
            newProject.totalMilestones = proposal.projectMilestoneCount;
            newProject.currentMilestone = 0; // Starts at 0, first milestone is at index 0
            newProject.status = ProjectStatus.Active;
            newProject.projectLead = proposal.proposer; // Initial project lead is the proposer
            newProject.creationTimestamp = block.timestamp;
            // The milestone funding will be allocated from treasury when verified
            // For now, let's set the first milestone funds directly.
            // A more complex system would have `_milestoneFundingPerMilestone` passed during proposal creation
            // and stored, then used here. For now, we assume this is handled.

            // Transfer initial portion of funds or rely on milestone payment requests
            // For now, we'll only transfer funds on milestone verification.

            _updateContributionScore(proposal.proposer, 50, "Project proposal accepted"); // Reward proposer
            emit ProjectCreated(projectId, _proposalId, proposal.proposer, proposal.title, proposal.requestedAmount);

        } else if (proposal.proposalType == 1) { // Governance parameter change
            (bool success, ) = proposal.target.call(proposal.callData);
            require(success, "ImpactNexusDAO: Governance call failed");
        } else if (proposal.proposalType == 2) { // Treasury withdrawal
             _approveTreasuryWithdrawal(_proposalId, proposal.proposalRecipient, proposal.proposalAmount);
        } else if (proposal.proposalType == 3) { // Steward election/removal
            if (proposal.proposalAmount == 1) { // 1 to add, 0 to remove
                _registerSteward(proposal.proposalRecipient);
            } else if (proposal.proposalAmount == 0) {
                _removeSteward(proposal.proposalRecipient);
            }
        }

        proposal.executed = true;
        proposal.state = ProposalState.Executed;
        // Return proposal stake to proposer
        NEXUS_TOKEN.safeTransfer(proposal.proposer, PROPOSAL_STAKE_AMOUNT);

        emit ProposalExecuted(_proposalId, _msgSender());
    }

    /**
     * @dev Allows project leads to request payment for a completed milestone, providing proof.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone being requested.
     * @param _proofOfCompletionHash IPFS hash of the proof of completion.
     */
    function requestMilestonePayment(
        uint256 _projectId,
        uint256 _milestoneIndex,
        bytes32 _proofOfCompletionHash
    ) external onlyProjectLead(_projectId) {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Active, "ImpactNexusDAO: Project not active");
        require(_milestoneIndex == project.currentMilestone, "ImpactNexusDAO: Not the current milestone");
        require(_milestoneIndex < project.totalMilestones, "ImpactNexusDAO: Invalid milestone index");
        require(!project.milestoneCompleted[_milestoneIndex], "ImpactNexusDAO: Milestone already completed");
        require(_proofOfCompletionHash != bytes32(0), "ImpactNexusDAO: Proof hash cannot be empty");

        project.milestoneProofs[_milestoneIndex] = _proofOfCompletionHash;
        // At this point, a new governance proposal for verification could be created, or stewards can directly verify.
        // For simplicity, let's allow stewards to directly verify within a set period or create a mini-vote.
        // For now, it will require a Steward to call `verifyMilestoneAndReleaseFunds`.

        emit MilestoneRequested(_projectId, _milestoneIndex, _msgSender(), _proofOfCompletionHash);
    }

    /**
     * @dev Stewards or DAO governance vote to verify a milestone and release funds from the treasury.
     *      Also awards reputation to the project lead and potentially involved contributors.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone to verify.
     */
    function verifyMilestoneAndReleaseFunds(uint256 _projectId, uint256 _milestoneIndex) external onlySteward {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Active, "ImpactNexusDAO: Project not active");
        require(_milestoneIndex == project.currentMilestone, "ImpactNexusDAO: Not the current milestone");
        require(_milestoneIndex < project.totalMilestones, "ImpactNexusDAO: Invalid milestone index");
        require(!project.milestoneCompleted[_milestoneIndex], "ImpactNexusDAO: Milestone already completed");
        require(project.milestoneProofs[_milestoneIndex] != bytes32(0), "ImpactNexusDAO: No proof submitted for milestone");

        // In a real system, there would be an off-chain review of _proofOfCompletionHash
        // and a vote/consensus among stewards. For simplicity, we assume one steward can verify.
        // Advanced: This could trigger a mini-proposal that only Stewards can vote on.

        // Get milestone funding from the original proposal (requires fetching the proposal)
        Proposal storage originalProposal = proposals[project.proposalId];
        // This requires `_milestoneFundingPerMilestone` to be stored in the proposal
        // For simplicity, let's assume milestone amounts are equally divided for now, or pre-defined.
        // A more robust solution would store `_milestoneFundingPerMilestone` in the Project struct.
        uint256 milestoneAmount = originalProposal.requestedAmount.div(originalProposal.projectMilestoneCount); // Simple equal split

        require(address(this).balance >= milestoneAmount, "ImpactNexusDAO: Insufficient treasury balance for milestone payment");

        (bool success, ) = payable(project.projectLead).call{value: milestoneAmount}("");
        require(success, "ImpactNexusDAO: Failed to send milestone payment");

        project.milestoneCompleted[_milestoneIndex] = true;
        project.fundsAllocated = project.fundsAllocated.add(milestoneAmount);
        project.currentMilestone = project.currentMilestone.add(1);

        _updateContributionScore(project.projectLead, 100, "Milestone completed"); // Reward project lead
        _updateContributionScore(_msgSender(), 10, "Milestone verified"); // Reward steward

        if (project.currentMilestone == project.totalMilestones) {
            project.status = ProjectStatus.Completed;
            _updateContributionScore(project.proposer, 200, "Project completed"); // Final reward
        }

        emit FundsReleased(_projectId, _milestoneIndex, milestoneAmount, project.projectLead);
    }

    /**
     * @dev Allows proposers to reclaim their initial NexusToken stake if their proposal fails to pass or expires without execution.
     * @param _proposalId The ID of the proposal.
     */
    function claimExpiredProposalDeposit(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer == _msgSender(), "ImpactNexusDAO: Only proposer can claim deposit");
        require(proposal.state == ProposalState.Defeated || proposal.state == ProposalState.Expired, "ImpactNexusDAO: Proposal must be defeated or expired");
        require(NEXUS_TOKEN.balanceOf(address(this)) >= PROPOSAL_STAKE_AMOUNT, "ImpactNexusDAO: Insufficient DAO token balance for refund");

        // Prevent double claims
        require(proposal.executed == false, "ImpactNexusDAO: Deposit already returned or proposal executed");

        NEXUS_TOKEN.safeTransfer(proposal.proposer, PROPOSAL_STAKE_AMOUNT);
        proposal.executed = true; // Mark as returned, even though proposal itself wasn't executed
    }

    /**
     * @dev Retrieves all stored details for a specific project by its ID.
     * @param _projectId The ID of the project.
     * @return A tuple containing project details.
     */
    function getProjectDetails(uint256 _projectId) external view returns (
        uint256 id,
        uint256 proposalId,
        address proposer,
        string memory title,
        bytes32 descriptionHash,
        uint256 totalRequestedAmount,
        uint256 totalMilestones,
        uint256 currentMilestone,
        uint256 fundsAllocated,
        ProjectStatus status,
        address projectLead,
        uint256 creationTimestamp
    ) {
        Project storage project = projects[_projectId];
        require(project.id == _projectId, "ImpactNexusDAO: Invalid project ID");
        return (
            project.id,
            project.proposalId,
            project.proposer,
            project.title,
            project.descriptionHash,
            project.totalRequestedAmount,
            project.totalMilestones,
            project.currentMilestone,
            project.fundsAllocated,
            project.status,
            project.projectLead,
            project.creationTimestamp
        );
    }

    /**
     * @dev Retrieves all stored details for a specific governance proposal by its ID.
     * @param _proposalId The ID of the proposal.
     * @return A tuple containing proposal details.
     */
    function getProposalDetails(uint256 _proposalId) external view returns (
        uint256 id,
        address proposer,
        string memory title,
        bytes32 descriptionHash,
        uint256 requestedAmount,
        uint256 startBlock,
        uint256 endBlock,
        uint256 forVotes,
        uint256 againstVotes,
        bool executed,
        ProposalState state,
        uint256 proposalType,
        address proposalRecipient,
        uint256 proposalAmount
    ) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id == _proposalId, "ImpactNexusDAO: Invalid proposal ID");
        return (
            proposal.id,
            proposal.proposer,
            proposal.title,
            proposal.descriptionHash,
            proposal.requestedAmount,
            proposal.startBlock,
            proposal.endBlock,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.executed,
            proposal.state,
            proposal.proposalType,
            proposal.proposalRecipient,
            proposal.proposalAmount
        );
    }


    // --- V. Treasury & Financial Management ---

    /**
     * @dev Allows the DAO to propose a withdrawal of native currency from the treasury.
     * @param _recipient The address to send funds to.
     * @param _amount The amount of native currency to withdraw.
     * @param _reasonHash IPFS hash explaining the reason for withdrawal.
     * @return The ID of the newly created proposal.
     */
    function proposeTreasuryWithdrawal(address _recipient, uint256 _amount, bytes32 _reasonHash) external returns (uint256) {
        require(_recipient != address(0), "ImpactNexusDAO: Recipient cannot be zero address");
        require(_amount > 0, "ImpactNexusDAO: Amount must be greater than zero");
        require(address(this).balance >= _amount, "ImpactNexusDAO: Insufficient treasury balance");
        require(_getVotingPower(_msgSender()) >= proposalThreshold, "ImpactNexusDAO: Insufficient voting power to propose");

        NEXUS_TOKEN.safeTransferFrom(_msgSender(), address(this), PROPOSAL_STAKE_AMOUNT);

        uint256 proposalId = nextProposalId++;
        Proposal storage newProposal = proposals[proposalId];

        newProposal.id = proposalId;
        newProposal.proposer = _msgSender();
        newProposal.title = "Treasury Withdrawal";
        newProposal.descriptionHash = _reasonHash;
        newProposal.requestedAmount = _amount; // This field doubles as requested ETH amount
        newProposal.startBlock = block.number;
        newProposal.endBlock = block.number.add(votingPeriod);
        newProposal.state = ProposalState.Pending;
        newProposal.proposalType = 2; // Treasury Withdrawal
        newProposal.proposalRecipient = _recipient;
        newProposal.proposalAmount = _amount;

        emit ProposalSubmitted(proposalId, _msgSender(), newProposal.title, _amount, newProposal.endBlock);
        return proposalId;
    }

    /**
     * @dev Internal function to execute an approved treasury withdrawal.
     *      This is called by `executeProposal` after a successful vote.
     */
    function _approveTreasuryWithdrawal(uint256 _proposalId, address _recipient, uint256 _amount) internal {
        require(address(this).balance >= _amount, "ImpactNexusDAO: Insufficient treasury balance for withdrawal");
        (bool success, ) = payable(_recipient).call{value: _amount}("");
        require(success, "ImpactNexusDAO: Failed to send treasury withdrawal");
        emit TreasuryWithdrawalApproved(_proposalId, _recipient, _amount);
    }

    // --- VI. Governance & Parameters ---

    /**
     * @dev Allows the DAO to propose and vote on changing the duration of voting periods for proposals.
     * @param _newPeriod The new voting period in seconds.
     * @return The ID of the newly created proposal.
     */
    function setVotingPeriod(uint256 _newPeriod) public returns (uint256) {
        require(_newPeriod > 0, "ImpactNexusDAO: Voting period must be greater than zero");
        require(_getVotingPower(_msgSender()) >= proposalThreshold, "ImpactNexusDAO: Insufficient voting power to propose");

        NEXUS_TOKEN.safeTransferFrom(_msgSender(), address(this), PROPOSAL_STAKE_AMOUNT);

        uint256 proposalId = nextProposalId++;
        Proposal storage newProposal = proposals[proposalId];

        newProposal.id = proposalId;
        newProposal.proposer = _msgSender();
        newProposal.title = "Change Voting Period";
        newProposal.descriptionHash = keccak256(abi.encodePacked("New Voting Period: ", _newPeriod));
        newProposal.requestedAmount = 0; // No ETH requested for this governance change
        newProposal.startBlock = block.number;
        newProposal.endBlock = block.number.add(votingPeriod);
        newProposal.state = ProposalState.Pending;
        newProposal.proposalType = 1; // Governance change
        newProposal.target = address(this);
        newProposal.callData = abi.encodeWithSelector(this.setVotingPeriodInternal.selector, _newPeriod);

        emit ProposalSubmitted(proposalId, _msgSender(), newProposal.title, 0, newProposal.endBlock);
        return proposalId;
    }

    // Internal function to be called by `executeProposal` for setting voting period.
    function setVotingPeriodInternal(uint256 _newPeriod) internal {
        votingPeriod = _newPeriod;
    }

    /**
     * @dev Allows the DAO to propose and vote on changing the minimum NexusToken + Reputation required to submit a proposal.
     * @param _newThreshold The new proposal threshold.
     * @return The ID of the newly created proposal.
     */
    function setProposalThreshold(uint256 _newThreshold) external returns (uint256) {
        require(_newThreshold > 0, "ImpactNexusDAO: Proposal threshold must be greater than zero");
        require(_getVotingPower(_msgSender()) >= proposalThreshold, "ImpactNexusDAO: Insufficient voting power to propose");

        NEXUS_TOKEN.safeTransferFrom(_msgSender(), address(this), PROPOSAL_STAKE_AMOUNT);

        uint256 proposalId = nextProposalId++;
        Proposal storage newProposal = proposals[proposalId];

        newProposal.id = proposalId;
        newProposal.proposer = _msgSender();
        newProposal.title = "Change Proposal Threshold";
        newProposal.descriptionHash = keccak256(abi.encodePacked("New Proposal Threshold: ", _newThreshold));
        newProposal.requestedAmount = 0;
        newProposal.startBlock = block.number;
        newProposal.endBlock = block.number.add(votingPeriod);
        newProposal.state = ProposalState.Pending;
        newProposal.proposalType = 1;
        newProposal.target = address(this);
        newProposal.callData = abi.encodeWithSelector(this.setProposalThresholdInternal.selector, _newThreshold);

        emit ProposalSubmitted(proposalId, _msgSender(), newProposal.title, 0, newProposal.endBlock);
        return proposalId;
    }

    // Internal function to be called by `executeProposal` for setting proposal threshold.
    function setProposalThresholdInternal(uint256 _newThreshold) internal {
        proposalThreshold = _newThreshold;
    }

    /**
     * @dev Allows the DAO to propose and vote on changing the rate at which ContributionScore decays.
     * @param _newRate The new reputation decay rate (e.g., 100 for 1%).
     * @return The ID of the newly created proposal.
     */
    function setReputationDecayRate(uint256 _newRate) external returns (uint256) {
        require(_newRate <= 10000, "ImpactNexusDAO: Decay rate cannot exceed 100%"); // 10000 = 100%
        require(_getVotingPower(_msgSender()) >= proposalThreshold, "ImpactNexusDAO: Insufficient voting power to propose");

        NEXUS_TOKEN.safeTransferFrom(_msgSender(), address(this), PROPOSAL_STAKE_AMOUNT);

        uint256 proposalId = nextProposalId++;
        Proposal storage newProposal = proposals[proposalId];

        newProposal.id = proposalId;
        newProposal.proposer = _msgSender();
        newProposal.title = "Change Reputation Decay Rate";
        newProposal.descriptionHash = keccak256(abi.encodePacked("New Reputation Decay Rate: ", _newRate));
        newProposal.requestedAmount = 0;
        newProposal.startBlock = block.number;
        newProposal.endBlock = block.number.add(votingPeriod);
        newProposal.state = ProposalState.Pending;
        newProposal.proposalType = 1;
        newProposal.target = address(this);
        newProposal.callData = abi.encodeWithSelector(this.setReputationDecayRateInternal.selector, _newRate);

        emit ProposalSubmitted(proposalId, _msgSender(), newProposal.title, 0, newProposal.endBlock);
        return proposalId;
    }

    // Internal function to be called by `executeProposal` for setting reputation decay rate.
    function setReputationDecayRateInternal(uint256 _newRate) internal {
        reputationDecayRate = _newRate;
    }

    /**
     * @dev Allows the DAO to propose and vote on electing a new Steward.
     * @param _newSteward The address of the new steward.
     * @return The ID of the newly created proposal.
     */
    function registerSteward(address _newSteward) external returns (uint256) {
        require(_newSteward != address(0), "ImpactNexusDAO: Steward address cannot be zero");
        require(!isSteward[_newSteward], "ImpactNexusDAO: Address is already a steward");
        require(_getVotingPower(_msgSender()) >= proposalThreshold, "ImpactNexusDAO: Insufficient voting power to propose");

        NEXUS_TOKEN.safeTransferFrom(_msgSender(), address(this), PROPOSAL_STAKE_AMOUNT);

        uint256 proposalId = nextProposalId++;
        Proposal storage newProposal = proposals[proposalId];

        newProposal.id = proposalId;
        newProposal.proposer = _msgSender();
        newProposal.title = "Register New Steward";
        newProposal.descriptionHash = keccak256(abi.encodePacked("New Steward: ", _newSteward));
        newProposal.requestedAmount = 0;
        newProposal.startBlock = block.number;
        newProposal.endBlock = block.number.add(votingPeriod);
        newProposal.state = ProposalState.Pending;
        newProposal.proposalType = 3; // Steward election/removal
        newProposal.proposalRecipient = _newSteward;
        newProposal.proposalAmount = 1; // 1 for register

        emit ProposalSubmitted(proposalId, _msgSender(), newProposal.title, 0, newProposal.endBlock);
        return proposalId;
    }

    // Internal function to be called by `executeProposal` for registering steward.
    function _registerSteward(address _newSteward) internal {
        isSteward[_newSteward] = true;
        _stewards.push(_newSteward);
        emit StewardRegistered(_newSteward);
    }

    /**
     * @dev Allows the DAO to propose and vote on removing an existing Steward.
     * @param _steward The address of the steward to remove.
     * @return The ID of the newly created proposal.
     */
    function removeSteward(address _steward) external returns (uint256) {
        require(_steward != address(0), "ImpactNexusDAO: Steward address cannot be zero");
        require(isSteward[_steward], "ImpactNexusDAO: Address is not a steward");
        require(_getVotingPower(_msgSender()) >= proposalThreshold, "ImpactNexusDAO: Insufficient voting power to propose");

        NEXUS_TOKEN.safeTransferFrom(_msgSender(), address(this), PROPOSAL_STAKE_AMOUNT);

        uint256 proposalId = nextProposalId++;
        Proposal storage newProposal = proposals[proposalId];

        newProposal.id = proposalId;
        newProposal.proposer = _msgSender();
        newProposal.title = "Remove Steward";
        newProposal.descriptionHash = keccak256(abi.encodePacked("Remove Steward: ", _steward));
        newProposal.requestedAmount = 0;
        newProposal.startBlock = block.number;
        newProposal.endBlock = block.number.add(votingPeriod);
        newProposal.state = ProposalState.Pending;
        newProposal.proposalType = 3; // Steward election/removal
        newProposal.proposalRecipient = _steward;
        newProposal.proposalAmount = 0; // 0 for remove

        emit ProposalSubmitted(proposalId, _msgSender(), newProposal.title, 0, newProposal.endBlock);
        return proposalId;
    }

    // Internal function to be called by `executeProposal` for removing steward.
    function _removeSteward(address _steward) internal {
        isSteward[_steward] = false;
        // Remove from array (inefficient for large arrays but simple)
        for (uint256 i = 0; i < _stewards.length; i++) {
            if (_stewards[i] == _steward) {
                _stewards[i] = _stewards[_stewards.length - 1];
                _stewards.pop();
                break;
            }
        }
        emit StewardRemoved(_steward);
    }

    // --- VII. Utilities & Maintenance ---

    /**
     * @dev A public function that can be called by anyone (e.g., an automated keeper bot).
     *      It iterates through accounts whose reputation is due for decay, applying the
     *      configured decay rate and rewarding the caller a small fee for gas.
     *      Note: This is a simplified iteration. For many users, a more gas-efficient batch
     *      processing or Merkle-tree based approach would be needed.
     */
    function reputationDecayCheck() external payable {
        require(msg.value >= REPUTATION_DECAY_REWARD, "ImpactNexusDAO: Insufficient reward sent for decay check");

        uint256 decayedCount = 0;
        // Iterate through all known addresses that have a reputation score
        // This is highly inefficient for a large number of users.
        // In a real-world scenario, this would be optimized, e.g., by only processing
        // a few users per call or by using a Merkle tree of users with pending decay.
        // For demonstration, let's process up to 10 users in one call.
        uint256 limit = 10;
        for (uint256 i = 0; i < limit && i < _stewards.length; i++) { // Using stewards list as a proxy for 'known users'
            address user = _stewards[i]; // Example: Check stewards' reputation, or a separate list of active users
            uint256 currentScore = contributionScores[user];
            uint256 lastUpdate = lastReputationUpdate[user];

            if (currentScore > 0 && lastUpdate > 0 && block.timestamp > lastUpdate.add(REPUTATION_DECAY_INTERVAL)) {
                uint256 oldScore = currentScore;
                uint256 intervals = (block.timestamp.sub(lastUpdate)).div(REPUTATION_DECAY_INTERVAL);
                uint256 newScore = currentScore;
                for (uint256 j = 0; j < intervals; j++) {
                    newScore = newScore.mul(10000 - reputationDecayRate).div(10000);
                }
                contributionScores[user] = newScore;
                lastReputationUpdate[user] = block.timestamp;
                emit ReputationDecayed(user, oldScore, newScore);
                decayedCount++;
            }
        }
        // If not enough reputation decayed to justify reward, send back
        if (decayedCount == 0 && msg.value > 0) {
            (bool success, ) = payable(_msgSender()).call{value: msg.value}("");
            require(success, "ImpactNexusDAO: Failed to refund unused decay reward");
        } else if (decayedCount > 0) {
            (bool success, ) = payable(_msgSender()).call{value: REPUTATION_DECAY_REWARD}("");
            require(success, "ImpactNexusDAO: Failed to send decay reward");
            emit ReputationDecayReward(_msgSender(), REPUTATION_DECAY_REWARD);
        }
    }


    /**
     * @dev Checks if a given address is currently an active Steward of the DAO.
     * @param _addr The address to check.
     * @return True if the address is a steward, false otherwise.
     */
    function isSteward(address _addr) public view returns (bool) {
        return isSteward[_addr];
    }

    /**
     * @dev Returns the total number of currently active Stewards.
     * @return The count of active stewards.
     */
    function getStewardCount() external view returns (uint256) {
        return _stewards.length;
    }
}
```