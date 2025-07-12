Okay, let's create a smart contract for a Decentralized Autonomous Talent Pool (DATP). This concept combines elements of DAOs, reputation systems, staking, and decentralized task/gig management with on-chain dispute resolution via a jury system.

It's complex and incorporates several advanced ideas:

1.  **DAO Governance:** Protocol parameters (fees, dispute juror stake) are managed by token holders.
2.  **Staking:** Users stake tokens for eligibility in the dispute jury pool and potentially boosted reputation/rewards.
3.  **Reputation System:** Tracks user performance based on completed projects and ratings.
4.  **On-Chain Jury Dispute Resolution:** A system where staked token holders are randomly selected to vote on project disputes.
5.  **Escrow:** Funds for projects are held in escrow until completion or dispute resolution.
6.  **Native Token:** A utility and governance token for staking, rewards, and governance.

This contract is *conceptual* and high-level. A production system would require significantly more robust error handling, edge case management, gas optimization, security audits, and potentially external oracle interactions for certain data (though we'll avoid that for simplicity here). The jury randomness is also limited by blockchain determinism – a real system might use VRFs or commit-reveal schemes.

---

**Decentralized Autonomous Talent Pool (DATP) Contract**

**Outline:**

1.  **Contract Description:** A decentralized platform for matching talent with projects, managing escrow, reputation, and disputes via DAO governance and a jury system.
2.  **Key Features:**
    *   User Registration & Profiles
    *   Project Posting & Application
    *   Escrow Management
    *   Reputation Tracking
    *   Staking Mechanism
    *   On-Chain Jury Dispute Resolution
    *   DAO Governance for Protocol Parameters
    *   Native DATP Token (ERC20-like)
3.  **State Variables:** Store user data, project details, applications, disputes, governance proposals, token balances, staking info, protocol parameters.
4.  **Enums:** Define states for Users, Projects, Applications, Disputes, and Proposals.
5.  **Events:** Log key actions and state changes.
6.  **Structs:** Define data structures for User, Project, Application, Dispute, Proposal, etc.
7.  **Function Categories:**
    *   **Token Management:** Minting (initial/rewards), Transfer (internal), Balance check.
    *   **User Management:** Registration, Profile Update, Get Profile, Get Total Users.
    *   **Staking:** Stake Tokens, Unstake Tokens, Check Staked Amount, Claim Staking Rewards.
    *   **Project Management:** Post Project, Cancel Project, Get Project Details, List Projects, Select Applicant, Submit Completion, Confirm Completion, Reject Completion.
    *   **Application Management:** Apply for Project, Withdraw Application, List Project Applications, Get Application Details.
    *   **Reputation:** Leave Rating, Get User Reputation.
    *   **Escrow:** (Implicitly managed within project/dispute functions).
    *   **Dispute Resolution:** Raise Dispute, Submit Evidence, Select Jurors (internal/trigger), Cast Jury Vote, Tally Jury Votes & Resolve, Get Dispute Details, List Active Disputes.
    *   **Governance:** Submit Proposal, Vote on Proposal, Tally Governance Votes & Execute, Get Proposal Details, List Open Proposals, Update Protocol Parameters (via execution).
    *   **Protocol/Fees:** Set Fee Rate (via governance), Withdraw Protocol Fees.
    *   **Utility:** Get States (Project, Dispute, Proposal), Check Juror Eligibility.

**Function Summary (27 functions):**

1.  `registerUser(string _name, string _skills)`: Registers a new user profile.
2.  `updateProfile(string _name, string _skills)`: Updates the calling user's profile.
3.  `getUserProfile(address _user)`: Retrieves a user's profile information.
4.  `getTotalUsers()`: Returns the total number of registered users.
5.  `stakeTokens(uint _amount)`: Stakes DATP tokens to become eligible for jury duty and rewards.
6.  `unstakeTokens(uint _amount)`: Unstakes DATP tokens (subject to cooldown).
7.  `checkStakedAmount(address _user)`: Checks a user's currently staked token amount.
8.  `claimStakingRewards()`: Allows users to claim accrued staking rewards.
9.  `postProject(string _title, string _description, uint _budget, uint _applicationDeadline, uint _completionDeadline)`: Posts a new project, funding the budget into escrow.
10. `cancelProject(uint _projectId)`: Allows project owner to cancel before applicant selection, returning escrowed funds.
11. `getProjectDetails(uint _projectId)`: Retrieves details for a specific project.
12. `listProjects(ProjectState _state)`: Lists projects filtered by their current state.
13. `selectApplicant(uint _projectId, uint _applicationId)`: Project owner selects an applicant, locking the funds for that specific application fee.
14. `submitProjectCompletion(uint _projectId)`: Worker submits project completion claim.
15. `confirmProjectCompletion(uint _projectId, uint _rating)`: Project owner confirms completion, releases funds to worker, and leaves a rating.
16. `rejectProjectCompletion(uint _projectId)`: Project owner rejects completion, potentially initiating a dispute.
17. `applyForProject(uint _projectId, uint _proposedFee, string _coverLetter)`: A user applies for a project with a proposed fee.
18. `withdrawApplication(uint _applicationId)`: Applicant withdraws their application.
19. `listProjectApplications(uint _projectId)`: Lists applications submitted for a project.
20. `leaveRating(uint _entityId, bool _isProject, uint _rating)`: Leaves a rating for a user (after project completion) or a juror decision (after dispute).
21. `getUserReputation(address _user)`: Retrieves a user's reputation score.
22. `raiseDispute(uint _projectId, string _reason)`: Either party (owner/worker) raises a dispute.
23. `submitEvidence(uint _disputeId, string _evidence)`: Parties submit evidence for a dispute.
24. `castJuryVote(uint _disputeId, uint _outcome)`: A selected juror casts their vote on the dispute outcome.
25. `tallyJuryVotesAndResolve(uint _disputeId)`: Triggers tallying of jury votes and resolves the dispute.
26. `getDisputeDetails(uint _disputeId)`: Retrieves details for a specific dispute.
27. `submitGovernanceProposal(address _target, bytes memory _calldata, string memory _description)`: Allows token holders to submit a proposal for protocol changes.
28. `voteOnProposal(uint _proposalId, bool _support)`: Allows token holders to vote on an open proposal.
29. `tallyGovernanceVotesAndExecute(uint _proposalId)`: Tally votes for a proposal and executes it if passed.
30. `getProposalDetails(uint _proposalId)`: Retrieves details for a specific proposal.
31. `withdrawProtocolFees(address _recipient)`: Allows governance/treasury to withdraw collected protocol fees.

*(Total functions: 31)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable initially, could be replaced by DAO later
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Redundant in 0.8+, kept for clarity on intent
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Note: SafeMath is not strictly necessary in Solidity 0.8+ due to default overflow/underflow checks.
// ReentrancyGuard is crucial for functions involving external calls and state changes.

/**
 * @title DecentralizedAutonomousTalentPool (DATP)
 * @dev A decentralized platform for managing talent, projects, escrow, reputation,
 *      disputes via a jury system, and protocol governance via DAO.
 *
 * Outline:
 * 1. Contract Description: Decentralized platform for talent, projects, escrow, reputation, disputes, and governance.
 * 2. Key Features: User Profiles, Project/Application System, Escrow, Reputation, Staking, Jury Disputes, DAO Governance, Native Token.
 * 3. State Variables: Users, Projects, Applications, Disputes, Proposals, Token data, Staking data, Protocol Parameters.
 * 4. Enums: States for Users, Projects, Applications, Disputes, Proposals.
 * 5. Events: Logging key actions (User, Project, Application, Dispute, Governance, Staking).
 * 6. Structs: Data models for core entities (User, Project, Application, Dispute, Proposal).
 * 7. Function Categories: Token, User, Staking, Project, Application, Reputation, Dispute, Governance, Protocol/Fees, Utility.
 * 8. Function Summary: (See list above code)
 */
contract DecentralizedAutonomousTalentPool is ERC20, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint; // Using SafeMath concepts explicitly for clarity, even if compiler handles it.

    // --- Enums ---
    enum UserState {
        Registered,
        Suspended // Potential future feature for DAO governance
    }

    enum ProjectState {
        OpenForApplications,
        ApplicationSelected,
        InProgress,
        CompletionSubmitted,
        Completed,
        Cancelled,
        UnderDispute
    }

    enum ApplicationState {
        Submitted,
        Selected,
        Rejected, // By owner
        Withdrawn
    }

    enum DisputeState {
        Raised,
        EvidenceSubmitted,
        JurySelected,
        VotingPeriod,
        Resolved
    }

    enum ProposalState {
        Pending,
        VotingPeriod,
        Succeeded,
        Failed,
        Executed
    }

    // --- Structs ---
    struct User {
        address userAddress;
        UserState state;
        string name;
        string skills;
        uint reputationScore; // Simple score, could be weighted average etc.
        uint stakedAmount;
        uint lastActivityTime; // For potential rewards/eligibility
    }

    struct Project {
        uint id;
        address owner;
        string title;
        string description;
        uint budget; // Total budget in DATP tokens
        uint selectedApplicantId; // Refers to Application struct ID
        ProjectState state;
        uint applicationDeadline;
        uint completionDeadline; // Deadline for worker to submit completion
        uint escrowedAmount; // Amount currently held in escrow for this project
        address currentWorker; // Address of the selected applicant
    }

    struct Application {
        uint id;
        uint projectId;
        address applicant;
        uint proposedFee; // Amount requested by applicant
        string coverLetter;
        ApplicationState state;
    }

    struct Dispute {
        uint id;
        uint projectId;
        address initiator;
        address counterparty;
        DisputeState state;
        uint winningParty; // 0=None, 1=Initiator, 2=Counterparty, 3=Split/Other (future)
        string initiatorEvidence;
        string counterpartyEvidence;
        uint[] jurorVotes; // Array of outcomes voted for by jurors (1 or 2)
        mapping(address => bool) hasJurorVoted; // Track if a specific juror voted
        address[] jurors; // Addresses of selected jurors
        uint voteDeadline;
        uint jurorMajorityOutcome; // The outcome that received majority votes
        uint jurorRewardClaimedCount; // How many jurors claimed rewards
    }

    struct GovernanceProposal {
        uint id;
        address proposer;
        string description;
        bytes callData; // Data to execute if proposal passes
        address targetContract; // Contract to call (usually 'this')
        uint voteStartTime;
        uint voteEndTime;
        uint yesVotes;
        uint noVotes;
        ProposalState state;
        bool executed;
        mapping(address => bool) hasVoted; // Track if a token holder voted
        uint quorumRequired; // Number of votes needed to make proposal valid
        uint majorityThreshold; // Percentage of yes votes required (e.g., 51%)
    }

    // --- State Variables ---
    Counters.Counter private _userIdCounter;
    Counters.Counter private _projectIdCounter;
    Counters.Counter private _applicationIdCounter;
    Counters.Counter private _disputeIdCounter;
    Counters.Counter private _proposalIdCounter;

    mapping(address => User) public users;
    mapping(uint => Project) public projects;
    mapping(uint => Application) public applications;
    mapping(uint => Dispute) public disputes;
    mapping(uint => GovernanceProposal) public proposals;

    // List of all dispute and proposal IDs (for listing functions)
    uint[] public allDisputeIds;
    uint[] public allProposalIds;

    // Protocol Parameters (Managed by Governance)
    uint public protocolFeeRate = 5; // 5% fee (multiplied by 100, so 500 for 5%)
    uint public minStakeForJuror = 1000 * (10**decimals()); // Example: 1000 DATP tokens
    uint public jurorPoolSize = 7; // Number of jurors per dispute
    uint public disputeVotingPeriod = 3 days;
    uint public proposalVotingPeriod = 7 days;
    uint public proposalQuorumPercentage = 10; // 10% of total supply needs to vote
    uint public proposalMajorityPercentage = 51; // 51% of votes cast need to be 'yes'
    uint public stakingUnstakeCooldown = 7 days; // Cooldown before unstaked tokens are available
    mapping(address => uint) public unstakeCooldownEnd; // User address to timestamp

    uint public totalProtocolFeesCollected;

    // --- Events ---
    event UserRegistered(address indexed user, string name);
    event ProfileUpdated(address indexed user);
    event TokensStaked(address indexed user, uint amount);
    event TokensUnstaked(address indexed user, uint amount);
    event ProjectPosted(uint indexed projectId, address indexed owner, uint budget);
    event ProjectCancelled(uint indexed projectId);
    event ApplicationSubmitted(uint indexed applicationId, uint indexed projectId, address indexed applicant, uint proposedFee);
    event ApplicationWithdrawn(uint indexed applicationId);
    event ApplicantSelected(uint indexed projectId, uint indexed applicationId, address indexed worker);
    event CompletionSubmitted(uint indexed projectId, address indexed worker);
    event ProjectCompleted(uint indexed projectId, address indexed worker, uint rating);
    event CompletionRejected(uint indexed projectId, address indexed owner);
    event RatingLeft(address indexed rater, address indexed ratedUser, uint entityId, bool isProject, uint rating);
    event DisputeRaised(uint indexed disputeId, uint indexed projectId, address indexed initiator, address counterparty);
    event EvidenceSubmitted(uint indexed disputeId, address indexed participant);
    event JurorSelected(uint indexed disputeId, address juror); // Emitted for each juror
    event JuryVoteCast(uint indexed disputeId, address indexed juror);
    event DisputeResolved(uint indexed disputeId, uint winningParty, uint awardedAmount);
    event GovernanceProposalSubmitted(uint indexed proposalId, address indexed proposer, string description);
    event GovernanceVoteCast(uint indexed proposalId, address indexed voter, bool support);
    event GovernanceProposalExecuted(uint indexed proposalId);
    event ProtocolFeeCollected(address indexed recipient, uint amount);
    event StakingRewardsClaimed(address indexed user, uint amount);


    // --- Constructor ---
    constructor(string memory name, string memory symbol, uint initialSupply) ERC20(name, symbol) Ownable(msg.sender) {
        // Mint initial supply to the contract owner or a treasury
        _mint(msg.sender, initialSupply * (10**decimals()));
    }

    // --- Token Management Functions ---

    // The basic ERC20 functions (_mint, _transfer, etc.) are handled by inheriting ERC20.
    // Custom minting for rewards or initial supply is handled internally or via constructor/governance.

    // --- User Management Functions ---

    /**
     * @dev Registers a new user profile.
     * @param _name The user's desired name.
     * @param _skills A description of the user's skills.
     */
    function registerUser(string memory _name, string memory _skills) public {
        require(users[msg.sender].userAddress == address(0), "DATP: User already registered");
        _userIdCounter.increment();
        users[msg.sender] = User({
            userAddress: msg.sender,
            state: UserState.Registered,
            name: _name,
            skills: _skills,
            reputationScore: 100, // Starting reputation
            stakedAmount: 0,
            lastActivityTime: block.timestamp
        });
        emit UserRegistered(msg.sender, _name);
    }

    /**
     * @dev Updates the calling user's profile.
     * @param _name The new name.
     * @param _skills The new skills description.
     */
    function updateProfile(string memory _name, string memory _skills) public {
        require(users[msg.sender].userAddress != address(0), "DATP: User not registered");
        users[msg.sender].name = _name;
        users[msg.sender].skills = _skills;
        emit ProfileUpdated(msg.sender);
    }

    /**
     * @dev Retrieves a user's profile information.
     * @param _user The address of the user.
     * @return User struct containing profile data.
     */
    function getUserProfile(address _user) public view returns (User memory) {
        require(users[_user].userAddress != address(0), "DATP: User not registered");
        return users[_user];
    }

    /**
     * @dev Returns the total number of registered users.
     */
    function getTotalUsers() public view returns (uint) {
        return _userIdCounter.current();
    }

    // --- Staking Functions ---

    /**
     * @dev Stakes DATP tokens to become eligible for juror duty and rewards.
     * @param _amount The amount of tokens to stake.
     */
    function stakeTokens(uint _amount) public nonReentrant {
        require(users[msg.sender].userAddress != address(0), "DATP: User not registered");
        require(_amount > 0, "DATP: Amount must be greater than 0");
        require(balanceOf(msg.sender) >= _amount, "DATP: Insufficient token balance");

        _transfer(msg.sender, address(this), _amount);
        users[msg.sender].stakedAmount = users[msg.sender].stakedAmount.add(_amount);

        emit TokensStaked(msg.sender, _amount);
    }

    /**
     * @dev Initiates unstaking of tokens. Tokens are subject to a cooldown period.
     * @param _amount The amount of tokens to unstake.
     */
    function unstakeTokens(uint _amount) public nonReentrant {
        require(users[msg.sender].userAddress != address(0), "DATP: User not registered");
        require(_amount > 0, "DATP: Amount must be greater than 0");
        require(users[msg.sender].stakedAmount >= _amount, "DATP: Insufficient staked tokens");

        // Note: Tokens are still 'staked' but marked for withdrawal.
        // The actual transfer happens after the cooldown.
        users[msg.sender].stakedAmount = users[msg.sender].stakedAmount.sub(_amount);
        // A more complex system would track individual unstake requests.
        // For simplicity, this sets a cooldown for *all* staked tokens after *any* unstake request.
        // A real system would track separate cooldowns or use a withdrawal queue.
        unstakeCooldownEnd[msg.sender] = block.timestamp + stakingUnstakeCooldown;

        emit TokensUnstaked(msg.sender, _amount);
    }

    /**
     * @dev Allows claiming unstaked tokens after the cooldown period.
     * Note: This simple model assumes the remaining `stakedAmount` after `unstakeTokens`
     * represents the available amount after cooldown. A real system needs queues.
     * This function effectively claims the *entire* current staked amount *if* the cooldown is over.
     * This is simplified for this example.
     */
    function claimUnstakedTokens() public nonReentrant {
         require(users[msg.sender].userAddress != address(0), "DATP: User not registered");
         require(block.timestamp >= unstakeCooldownEnd[msg.sender], "DATP: Unstaking cooldown not over");
         // This simplified version lets them claim their remaining staked amount if cooldown is over.
         // A real system would need a separate balance tracking tokens pending withdrawal.
         uint amountToClaim = users[msg.sender].stakedAmount; // Simplified: treats remaining stakedAmount as claimable
         require(amountToClaim > 0, "DATP: No tokens available to claim");

         users[msg.sender].stakedAmount = 0; // Reset staked amount after claiming all
         _transfer(address(this), msg.sender, amountToClaim);

         // Optionally reset cooldown end if claiming everything, or keep if partial unstakes are allowed
         // delete unstakeCooldownEnd[msg.sender]; // If claiming all clears cooldown

         // No specific event for claiming unstaked in summary, but useful to add
    }


    /**
     * @dev Checks a user's currently staked token amount.
     * Note: This shows the *active* stake, not tokens pending withdrawal.
     * @param _user The address of the user.
     * @return The amount of DATP tokens staked by the user.
     */
    function checkStakedAmount(address _user) public view returns (uint) {
        require(users[_user].userAddress != address(0), "DATP: User not registered");
        return users[_user].stakedAmount;
    }

     /**
     * @dev Claims accrued staking rewards. Rewards are distributed based on activity (jury duty, completed projects).
     *      This function is a placeholder; reward calculation logic needs to be implemented.
     *      A common pattern is to track points or reward balances per user.
     */
    function claimStakingRewards() public nonReentrant {
        require(users[msg.sender].userAddress != address(0), "DATP: User not registered");

        // --- REWARD CALCULATION LOGIC GOES HERE ---
        // This is a complex piece often involving points accumulated from:
        // - Successfully completed projects as worker
        // - Participating in successful jury outcomes
        // - Staking duration / amount (optional passive reward)
        // The actual reward pool might come from protocol fees or dedicated minting.
        // For this example, we'll simulate claiming a fixed reward (replace with real logic).
        uint rewardAmount = calculatePendingRewards(msg.sender); // Placeholder function

        require(rewardAmount > 0, "DATP: No rewards to claim");

        // Assuming rewards are minted or come from a pool the contract holds
        // Example: Minting rewards (inflationary)
        // _mint(msg.sender, rewardAmount);

        // Example: Transferring from collected fees (less inflationary)
        // require(balanceOf(address(this)) >= rewardAmount, "DATP: Insufficient reward pool balance");
        // _transfer(address(this), msg.sender, rewardAmount);

        // Let's use a simple placeholder transferring from contract balance for demonstration
         require(balanceOf(address(this)) >= rewardAmount, "DATP: Insufficient reward pool balance");
         _transfer(address(this), msg.sender, rewardAmount); // Simplified reward source

        // Reset pending rewards for the user after claiming
        resetPendingRewards(msg.sender); // Placeholder function

        emit StakingRewardsClaimed(msg.sender, rewardAmount);
    }

    // Placeholder for reward calculation - needs detailed implementation
    function calculatePendingRewards(address _user) internal view returns (uint) {
        // Based on user's activity, successful jury votes, etc.
        // Return 0 for now - replace with actual logic
        return 0;
    }

    // Placeholder for resetting pending rewards - needs detailed implementation
    function resetPendingRewards(address _user) internal {
        // Clear accumulated reward points/balances for _user
        // No-op for now - replace with actual logic
    }


    // --- Project Management Functions ---

    /**
     * @dev Posts a new project, funding the budget into the contract's escrow.
     * @param _title Project title.
     * @param _description Project description.
     * @param _budget Total budget for the project (in DATP tokens).
     * @param _applicationDeadline Timestamp when applications close.
     * @param _completionDeadline Timestamp when worker must submit completion.
     */
    function postProject(string memory _title, string memory _description, uint _budget, uint _applicationDeadline, uint _completionDeadline) public nonReentrant {
        require(users[msg.sender].userAddress != address(0), "DATP: User not registered");
        require(_budget > 0, "DATP: Budget must be greater than 0");
        require(_applicationDeadline > block.timestamp, "DATP: Application deadline must be in the future");
        require(_completionDeadline > _applicationDeadline, "DATP: Completion deadline must be after application deadline");
        require(balanceOf(msg.sender) >= _budget, "DATP: Insufficient token balance for budget");

        _projectIdCounter.increment();
        uint projectId = _projectIdCounter.current();

        // Transfer project budget into contract as escrow
        _transfer(msg.sender, address(this), _budget);

        projects[projectId] = Project({
            id: projectId,
            owner: msg.sender,
            title: _title,
            description: _description,
            budget: _budget,
            selectedApplicantId: 0, // No applicant selected yet
            state: ProjectState.OpenForApplications,
            applicationDeadline: _applicationDeadline,
            completionDeadline: _completionDeadline,
            escrowedAmount: _budget,
            currentWorker: address(0)
        });

        emit ProjectPosted(projectId, msg.sender, _budget);
    }

    /**
     * @dev Allows project owner to cancel a project before an applicant is selected.
     * @param _projectId The ID of the project to cancel.
     */
    function cancelProject(uint _projectId) public nonReentrant {
        Project storage project = projects[_projectId];
        require(project.owner == msg.sender, "DATP: Only project owner can cancel");
        require(project.state == ProjectState.OpenForApplications, "DATP: Project cannot be cancelled in this state");
        require(block.timestamp <= project.applicationDeadline, "DATP: Cannot cancel after application deadline");

        uint amountToRefund = project.escrowedAmount;
        project.state = ProjectState.Cancelled;
        project.escrowedAmount = 0;

        // Refund escrowed funds to the owner
        _transfer(address(this), project.owner, amountToRefund);

        emit ProjectCancelled(_projectId);
    }

    /**
     * @dev Retrieves details for a specific project.
     * @param _projectId The ID of the project.
     * @return Project struct containing project data.
     */
    function getProjectDetails(uint _projectId) public view returns (Project memory) {
        require(projects[_projectId].owner != address(0), "DATP: Project does not exist");
        return projects[_projectId];
    }

    /**
     * @dev Lists projects filtered by their current state.
     *      Note: This is a simplified list; iterating through all projects is gas-intensive.
     *      A real dApp would use off-chain indexing or query events.
     * @param _state The state to filter by. Use a value >= 0 to filter, or a special value (e.g., 99) for all (not implemented here for simplicity).
     * @return An array of project IDs matching the state.
     */
    function listProjects(ProjectState _state) public view returns (uint[] memory) {
        uint[] memory projectIds = new uint[](_projectIdCounter.current());
        uint count = 0;
        for (uint i = 1; i <= _projectIdCounter.current(); i++) {
            if (projects[i].owner != address(0) && projects[i].state == _state) {
                 projectIds[count] = i;
                 count++;
            }
        }
        uint[] memory filteredIds = new uint[](count);
        for (uint i = 0; i < count; i++) {
            filteredIds[i] = projectIds[i];
        }
        return filteredIds;
    }


    /**
     * @dev Project owner selects an applicant. Locks the specific fee amount within escrow.
     * @param _projectId The ID of the project.
     * @param _applicationId The ID of the selected application.
     */
    function selectApplicant(uint _projectId, uint _applicationId) public nonReentrant {
        Project storage project = projects[_projectId];
        Application storage application = applications[_applicationId];

        require(project.owner == msg.sender, "DATP: Only project owner can select applicant");
        require(project.id != 0, "DATP: Project does not exist");
        require(application.id != 0, "DATP: Application does not exist");
        require(application.projectId == _projectId, "DATP: Application does not belong to this project");
        require(project.state == ProjectState.OpenForApplications, "DATP: Cannot select applicant in this state");
        require(block.timestamp <= project.applicationDeadline, "DATP: Cannot select applicant after application deadline");
        require(application.state == ApplicationState.Submitted, "DATP: Application is not in submitted state");
        require(users[application.applicant].userAddress != address(0), "DATP: Applicant not registered");
        require(project.budget >= application.proposedFee, "DATP: Proposed fee exceeds project budget");

        // Ensure the applicant is not the project owner
        require(application.applicant != project.owner, "DATP: Cannot select project owner as applicant");


        project.selectedApplicantId = _applicationId;
        project.state = ProjectState.ApplicationSelected; // Transition to selected
        project.currentWorker = application.applicant;
        application.state = ApplicationState.Selected;

        // Reject all other applications for this project
        // This is computationally intensive; in production, use events and off-chain processing.
        for (uint i = 1; i <= _applicationIdCounter.current(); i++) {
            if (applications[i].projectId == _projectId && applications[i].state == ApplicationState.Submitted) {
                 applications[i].state = ApplicationState.Rejected; // Mark others as rejected
            }
        }


        emit ApplicantSelected(_projectId, _applicationId, application.applicant);
    }

    /**
     * @dev Worker submits claim that project is completed.
     * @param _projectId The ID of the project.
     */
    function submitProjectCompletion(uint _projectId) public {
        Project storage project = projects[_projectId];
        require(project.id != 0, "DATP: Project does not exist");
        require(project.currentWorker == msg.sender, "DATP: Only the assigned worker can submit completion");
        require(project.state == ProjectState.ApplicationSelected || project.state == ProjectState.InProgress, "DATP: Project must be in selected or in-progress state");
        require(block.timestamp <= project.completionDeadline, "DATP: Cannot submit completion after deadline"); // Optional: Allow late submission?

        project.state = ProjectState.CompletionSubmitted;

        emit CompletionSubmitted(_projectId, msg.sender);
    }

    /**
     * @dev Project owner confirms project completion, releases funds, and leaves a rating.
     * @param _projectId The ID of the project.
     * @param _rating The rating for the worker (1-5).
     */
    function confirmProjectCompletion(uint _projectId, uint _rating) public nonReentrant {
        Project storage project = projects[_projectId];
        require(project.owner == msg.sender, "DATP: Only project owner can confirm completion");
        require(project.state == ProjectState.CompletionSubmitted, "DATP: Project not in completion submitted state");
        require(_rating >= 1 && _rating <= 5, "DATP: Rating must be between 1 and 5");

        Application storage application = applications[project.selectedApplicantId];
        address worker = application.applicant;
        uint feeToPay = application.proposedFee;
        uint protocolFee = feeToPay.mul(protocolFeeRate).div(10000); // Fee is protocolFeeRate / 10000 (e.g., 500/10000 = 0.05 = 5%)
        uint amountToWorker = feeToPay.sub(protocolFee);
        uint remainingEscrow = project.escrowedAmount.sub(feeToPay);


        // Release funds to worker
        require(balanceOf(address(this)) >= amountToWorker, "DATP: Insufficient contract balance to pay worker");
        _transfer(address(this), worker, amountToWorker);

        // Collect protocol fee
         require(balanceOf(address(this)) >= protocolFee, "DATP: Insufficient contract balance for protocol fee");
         // Fee stays in contract balance until withdrawn by governance
         totalProtocolFeesCollected = totalProtocolFeesCollected.add(protocolFee);


        // Refund remaining escrow to owner (if budget was > proposed fee)
        if (remainingEscrow > 0) {
            require(balanceOf(address(this)) >= remainingEscrow, "DATP: Insufficient contract balance to refund owner");
            _transfer(address(this), project.owner, remainingEscrow);
        }


        project.escrowedAmount = 0; // Escrow fully distributed
        project.state = ProjectState.Completed;

        // Update worker reputation
        updateReputation(worker, _rating);

        emit ProjectCompleted(_projectId, worker, _rating);
        emit ProtocolFeeCollected(address(this), protocolFee); // Recipient is the contract itself initially
    }

     /**
     * @dev Project owner rejects project completion, which can lead to a dispute.
     * @param _projectId The ID of the project.
     */
    function rejectProjectCompletion(uint _projectId) public {
        Project storage project = projects[_projectId];
        require(project.owner == msg.sender, "DATP: Only project owner can reject completion");
        require(project.state == ProjectState.CompletionSubmitted, "DATP: Project not in completion submitted state");

        // Rejecting completion automatically raises a dispute
        raiseDispute(_projectId, "Completion rejected by owner");

        emit CompletionRejected(_projectId, msg.sender);
    }

    // --- Application Management Functions ---

    /**
     * @dev Allows a user to apply for an open project.
     * @param _projectId The ID of the project.
     * @param _proposedFee The fee the applicant proposes (in DATP tokens).
     * @param _coverLetter An optional cover letter.
     */
    function applyForProject(uint _projectId, uint _proposedFee, string memory _coverLetter) public {
        require(users[msg.sender].userAddress != address(0), "DATP: User not registered");
        Project storage project = projects[_projectId];
        require(project.id != 0, "DATP: Project does not exist");
        require(project.state == ProjectState.OpenForApplications, "DATP: Project is not open for applications");
        require(block.timestamp <= project.applicationDeadline, "DATP: Application deadline has passed");
        require(_proposedFee > 0, "DATP: Proposed fee must be greater than 0");
        require(_proposedFee <= project.budget, "DATP: Proposed fee exceeds project budget");
        // Ensure applicant is not the project owner
        require(msg.sender != project.owner, "DATP: Cannot apply for your own project");

        // Check if user already applied (prevent duplicate applications) - requires iterating applications, gas intensive.
        // Skipping this check for simplicity in this example, assuming dApp handles it.

        _applicationIdCounter.increment();
        uint applicationId = _applicationIdCounter.current();

        applications[applicationId] = Application({
            id: applicationId,
            projectId: _projectId,
            applicant: msg.sender,
            proposedFee: _proposedFee,
            coverLetter: _coverLetter,
            state: ApplicationState.Submitted
        });

        emit ApplicationSubmitted(applicationId, _projectId, msg.sender, _proposedFee);
    }

    /**
     * @dev Allows an applicant to withdraw their application.
     * @param _applicationId The ID of the application to withdraw.
     */
    function withdrawApplication(uint _applicationId) public {
        Application storage application = applications[_applicationId];
        require(application.id != 0, "DATP: Application does not exist");
        require(application.applicant == msg.sender, "DATP: Only the applicant can withdraw");
        require(application.state == ApplicationState.Submitted, "DATP: Application cannot be withdrawn in this state");

        Project storage project = projects[application.projectId];
        require(project.state == ProjectState.OpenForApplications, "DATP: Cannot withdraw application after project is no longer open for applications");


        application.state = ApplicationState.Withdrawn;

        emit ApplicationWithdrawn(_applicationId);
    }

    /**
     * @dev Lists applications submitted for a specific project.
     *      Note: Iterating applications is gas-intensive. Use off-chain indexing in production.
     * @param _projectId The ID of the project.
     * @return An array of application IDs for the project.
     */
    function listProjectApplications(uint _projectId) public view returns (uint[] memory) {
         require(projects[_projectId].owner != address(0), "DATP: Project does not exist");

        uint[] memory applicationIds = new uint[](_applicationIdCounter.current());
        uint count = 0;
        for (uint i = 1; i <= _applicationIdCounter.current(); i++) {
            if (applications[i].projectId == _projectId) {
                 applicationIds[count] = i;
                 count++;
            }
        }
        uint[] memory filteredIds = new uint[](count);
        for (uint i = 0; i < count; i++) {
            filteredIds[i] = applicationIds[i];
        }
        return filteredIds;
    }

    /**
     * @dev Retrieves details for a specific application.
     * @param _applicationId The ID of the application.
     * @return Application struct containing application data.
     */
     function getApplicationDetails(uint _applicationId) public view returns (Application memory) {
         require(applications[_applicationId].id != 0, "DATP: Application does not exist");
         return applications[_applicationId];
     }


    // --- Reputation Functions ---

    /**
     * @dev Allows a user to leave a rating (1-5) for another user after a completed interaction (project or dispute).
     * @param _userToRate The address of the user being rated.
     * @param _rating The rating (1-5).
     * @dev Currently called only internally from confirmProjectCompletion. Could be extended for dispute ratings.
     */
    function leaveRating(address _userToRate, uint _rating) internal {
        require(users[_userToRate].userAddress != address(0), "DATP: User being rated is not registered");
        require(_rating >= 1 && _rating <= 5, "DATP: Rating must be between 1 and 5");

        // Simple reputation calculation: Weighted average or just adding/subtracting points.
        // This is a basic additive/subtractive model for simplicity.
        // A real system would use a more sophisticated algorithm (e.g., ELO system).
        int reputationChange = 0;
        if (_rating == 5) reputationChange = 10;
        else if (_rating == 4) reputationChange = 5;
        else if (_rating == 3) reputationChange = 0;
        else if (_rating == 2) reputationChange = -5;
        else if (_rating == 1) reputationChange = -10;

        uint currentReputation = users[_userToRate].reputationScore;
        if (reputationChange > 0) {
            users[_userToRate].reputationScore = currentReputation.add(uint(reputationChange));
        } else if (reputationChange < 0) {
             // Prevent reputation from dropping below 0
             users[_userToRate].reputationScore = currentReputation > uint(-reputationChange) ? currentReputation.sub(uint(-reputationChange)) : 0;
        }

        // Note: No rater address or entity ID tracked in this basic version.
        // event RatingLeft(address indexed rater, address indexed ratedUser, uint entityId, bool isProject, uint rating);
        // If called from confirmProjectCompletion, rater is project.owner, ratedUser is project.currentWorker, entityId is project.id, isProject is true
         emit RatingLeft(msg.sender, _userToRate, 0, true, _rating); // Simplified event
    }


    /**
     * @dev Retrieves a user's reputation score.
     * @param _user The address of the user.
     * @return The user's reputation score.
     */
    function getUserReputation(address _user) public view returns (uint) {
        require(users[_user].userAddress != address(0), "DATP: User not registered");
        return users[_user].reputationScore;
    }


    // --- Dispute Resolution Functions ---

    /**
     * @dev Raises a dispute for a project. Can be initiated by either the owner or the worker.
     * @param _projectId The ID of the project in dispute.
     * @param _reason A brief reason for the dispute.
     */
    function raiseDispute(uint _projectId, string memory _reason) public {
        Project storage project = projects[_projectId];
        require(project.id != 0, "DATP: Project does not exist");
        require(project.state == ProjectState.CompletionSubmitted || project.state == ProjectState.ApplicationSelected, // Can dispute rejection or after selection before completion
            "DATP: Project not in a disputable state");

        address owner = project.owner;
        address worker = project.currentWorker;
        require(msg.sender == owner || msg.sender == worker, "DATP: Only project owner or worker can raise dispute");

        // Prevent duplicate disputes for the same project
        for (uint i = 0; i < allDisputeIds.length; i++) {
            if (disputes[allDisputeIds[i]].projectId == _projectId && disputes[allDisputeIds[i]].state != DisputeState.Resolved) {
                 revert("DATP: A dispute for this project is already active");
            }
        }

        _disputeIdCounter.increment();
        uint disputeId = _disputeIdCounter.current();
        allDisputeIds.push(disputeId);

        disputes[disputeId] = Dispute({
            id: disputeId,
            projectId: _projectId,
            initiator: msg.sender,
            counterparty: (msg.sender == owner ? worker : owner),
            state: DisputeState.Raised,
            winningParty: 0, // Undetermined
            initiatorEvidence: "", // Placeholder
            counterpartyEvidence: "", // Placeholder
            jurorVotes: new uint[](0), // Placeholder
            hasJurorVoted: mapping(address => bool)(),
            jurors: new address[](0), // Placeholder
            voteDeadline: 0, // Placeholder
            jurorMajorityOutcome: 0, // Placeholder
            jurorRewardClaimedCount: 0
        });

        project.state = ProjectState.UnderDispute; // Update project state

        emit DisputeRaised(disputeId, _projectId, msg.sender, (msg.sender == owner ? worker : owner));
    }

    /**
     * @dev Allows parties involved in a dispute to submit evidence.
     * @param _disputeId The ID of the dispute.
     * @param _evidence A link or hash pointing to the evidence (e.g., IPFS hash).
     */
    function submitEvidence(uint _disputeId, string memory _evidence) public {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.id != 0, "DATP: Dispute does not exist");
        require(dispute.state == DisputeState.Raised || dispute.state == DisputeState.EvidenceSubmitted, "DATP: Evidence cannot be submitted in this state");
        require(msg.sender == dispute.initiator || msg.sender == dispute.counterparty, "DATP: Only parties in dispute can submit evidence");

        if (msg.sender == dispute.initiator) {
            dispute.initiatorEvidence = _evidence;
        } else {
            dispute.counterpartyEvidence = _evidence;
        }

        // If both have submitted evidence, move to Jury Selection
        if (bytes(dispute.initiatorEvidence).length > 0 && bytes(dispute.counterpartyEvidence).length > 0 && dispute.state == DisputeState.Raised) {
             dispute.state = DisputeState.EvidenceSubmitted;
             // Trigger juror selection immediately after evidence submission
             _selectJurors(_disputeId);
        } else if (bytes(dispute.initiatorEvidence).length > 0 && bytes(dispute.counterpartyEvidence).length > 0 && dispute.state == DisputeState.EvidenceSubmitted) {
            // Allow updating evidence even after moving to next state, up until voting starts
            // Re-selecting jurors or resetting state might be needed in a real system if evidence changes
            // For simplicity, just update the evidence string here.
        }


        emit EvidenceSubmitted(_disputeId, msg.sender);
    }

    /**
     * @dev Internal function to select jurors from the pool of stakers.
     *      Note: On-chain randomness is hard and this method is simplified.
     *      A real system needs a robust, potentially off-chain verified randomness source.
     * @param _disputeId The ID of the dispute.
     */
    function _selectJurors(uint _disputeId) internal {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.state == DisputeState.EvidenceSubmitted, "DATP: Dispute must be in EvidenceSubmitted state to select jurors");

        address[] memory eligibleJurors = new address[](_userIdCounter.current());
        uint eligibleCount = 0;

        // Build a list of eligible jurors (registered users with sufficient stake)
        // This iterates through all users - gas intensive for large user base.
        // A better approach would be to maintain a list of active stakers.
        for (uint i = 1; i <= _userIdCounter.current(); i++) {
            address userAddr = users[i].userAddress; // Assuming sequential user IDs map to addresses
            if (userAddr != address(0) && users[userAddr].stakedAmount >= minStakeForJuror && users[userAddr].userAddress != dispute.initiator && users[userAddr].userAddress != dispute.counterparty) {
                 eligibleJurors[eligibleCount] = userAddr;
                 eligibleCount++;
            }
        }

        require(eligibleCount >= jurorPoolSize, "DATP: Not enough eligible jurors available");

        // Simple pseudo-random selection based on blockhash and timestamp.
        // DO NOT use this for production contracts requiring strong randomness.
        // Use Chainlink VRF or similar.
        address[] memory selected = new address[](jurorPoolSize);
        uint seed = uint(keccak256(abi.encodePacked(block.timestamp, block.number, tx.origin, eligibleCount)));

        for (uint i = 0; i < jurorPoolSize; i++) {
            uint randomIndex = (seed + i) % eligibleCount;
            selected[i] = eligibleJurors[randomIndex];
            // Simple way to prevent selecting the same juror multiple times in this sample:
            // Remove selected juror by swapping with last and decrementing eligibleCount.
            // This modifies eligibleJurors in place, but we only need it for this loop iteration.
            eligibleJurors[randomIndex] = eligibleJurors[eligibleCount - 1];
            eligibleCount--;
            seed = uint(keccak256(abi.encodePacked(seed, randomIndex))); // Mix seed for next selection
        }

        dispute.jurors = selected;
        dispute.state = DisputeState.JurySelected;
        dispute.voteDeadline = block.timestamp + disputeVotingPeriod;

        for(uint i=0; i<selected.length; i++) {
            emit JurorSelected(_disputeId, selected[i]);
        }
        // Transition to VotingPeriod could happen after a delay, or immediately.
        // Let's move to VotingPeriod directly after selection for simplicity.
        dispute.state = DisputeState.VotingPeriod;
    }

     /**
     * @dev Allows a selected juror to cast their vote on the dispute outcome.
     * @param _disputeId The ID of the dispute.
     * @param _outcome The vote: 1 for initiator wins, 2 for counterparty wins.
     */
    function castJuryVote(uint _disputeId, uint _outcome) public {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.id != 0, "DATP: Dispute does not exist");
        require(dispute.state == DisputeState.VotingPeriod, "DATP: Dispute is not in voting period");
        require(block.timestamp <= dispute.voteDeadline, "DATP: Voting period has ended");
        require(_outcome == 1 || _outcome == 2, "DATP: Invalid vote outcome (1 or 2)");

        bool isJuror = false;
        for (uint i = 0; i < dispute.jurors.length; i++) {
            if (dispute.jurors[i] == msg.sender) {
                isJuror = true;
                break;
            }
        }
        require(isJuror, "DATP: Only selected jurors can vote");
        require(!dispute.hasJurorVoted[msg.sender], "DATP: Juror has already voted");

        dispute.jurorVotes.push(_outcome);
        dispute.hasJurorVoted[msg.sender] = true;

        emit JuryVoteCast(_disputeId, msg.sender);
    }

     /**
     * @dev Tally the jury votes and resolve the dispute. Callable by anyone after the voting deadline.
     * @param _disputeId The ID of the dispute to resolve.
     */
    function tallyJuryVotesAndResolve(uint _disputeId) public nonReentrant {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.id != 0, "DATP: Dispute does not exist");
        require(dispute.state == DisputeState.VotingPeriod, "DATP: Dispute is not in voting period");
        require(block.timestamp > dispute.voteDeadline, "DATP: Voting period is not over yet");
        require(dispute.jurorVotes.length == dispute.jurors.length, "DATP: Not all jurors have voted yet (optional: could resolve with fewer votes after deadline)"); // Strict requirement

        uint initiatorVotes = 0;
        uint counterpartyVotes = 0;

        for (uint i = 0; i < dispute.jurorVotes.length; i++) {
            if (dispute.jurorVotes[i] == 1) {
                initiatorVotes++;
            } else if (dispute.jurorVotes[i] == 2) {
                counterpartyVotes++;
            }
        }

        address winner;
        uint awardedAmount = 0;
        Project storage project = projects[dispute.projectId];
        Application storage application = applications[project.selectedApplicantId];
        uint totalDisputedAmount = application.proposedFee; // The amount locked for the worker
        uint protocolFee = totalDisputedAmount.mul(protocolFeeRate).div(10000);

        // Determine outcome
        if (initiatorVotes > counterpartyVotes) {
            // Initiator wins (e.g., Owner rejected completion and jury agreed)
            // Funds return to the initiator (Project Owner)
            winner = dispute.initiator;
            awardedAmount = project.escrowedAmount; // Refund everything back to owner
            dispute.winningParty = 1;
            dispute.jurorMajorityOutcome = 1;
        } else if (counterpartyVotes > initiatorVotes) {
            // Counterparty wins (e.g., Worker submitted completion and jury agreed)
            // Funds go to the counterparty (Worker), minus fees
            winner = dispute.counterparty;
            awardedAmount = totalDisputedAmount.sub(protocolFee);
            uint remainingEscrow = project.escrowedAmount.sub(totalDisputedAmount);

            // Transfer worker's awarded amount
            require(balanceOf(address(this)) >= awardedAmount, "DATP: Insufficient contract balance for worker award");
            _transfer(address(this), winner, awardedAmount);

            // Transfer protocol fee
             require(balanceOf(address(this)) >= protocolFee, "DATP: Insufficient contract balance for protocol fee");
             totalProtocolFeesCollected = totalProtocolFeesCollected.add(protocolFee);
             emit ProtocolFeeCollected(address(this), protocolFee);

            // Refund remaining escrow to owner
            if (remainingEscrow > 0) {
                 require(balanceOf(address(this)) >= remainingEscrow, "DATP: Insufficient contract balance for owner refund");
                 _transfer(address(this), project.owner, remainingEscrow);
            }

            dispute.winningParty = 2;
            dispute.jurorMajorityOutcome = 2;

            // Optionally update reputation based on winning/losing dispute
             updateReputation(dispute.counterparty, 5); // Winning dispute is positive
             updateReputation(dispute.initiator, 1); // Losing dispute is negative

        } else {
            // Tie votes or no votes - Default outcome (e.g., funds returned to owner)
            winner = dispute.initiator; // Default to owner winning (status quo)
            awardedAmount = project.escrowedAmount; // Refund everything back to owner
            dispute.winningParty = 0; // Indicate tie or no clear winner
             dispute.jurorMajorityOutcome = 0; // Indicate tie
        }

        project.escrowedAmount = 0; // Escrow fully distributed/returned
        project.state = (dispute.winningParty == 2) ? ProjectState.Completed : ProjectState.Cancelled; // Mark project state based on outcome
        dispute.state = DisputeState.Resolved;

         // Reward jurors who voted with the majority
         // This needs careful implementation. For simplicity, reward *each* juror who voted with the majority.
         uint jurorRewardPerVote = protocolFee > 0 ? protocolFee.div(dispute.jurors.length) : 0; // Simplified distribution
         for(uint i=0; i<dispute.jurors.length; i++){
             if(dispute.jurorVotes[i] == dispute.jurorMajorityOutcome && dispute.jurorMajorityOutcome != 0){ // Reward only if there was a clear majority
                  // Add rewards to a pending rewards balance for the juror
                  // This requires a separate mapping like `pendingRewards[address]`
                  // For simplicity here, we just acknowledge the concept.
                  // Jurors claim via `claimStakingRewards`. Reward calculation needs to factor this.
                  // A real system would add `jurorRewardPerVote` to a user's claimable balance.
                  // Example: pendingRewards[dispute.jurors[i]] = pendingRewards[dispute.jurors[i]].add(jurorRewardPerVote);
                  dispute.jurorRewardClaimedCount++; // Track how many were eligible for reward
             }
         }
        // Note: The actual transfer of juror rewards happens when they call claimStakingRewards.

        emit DisputeResolved(_disputeId, dispute.winningParty, awardedAmount);

        // If the dispute was a tie or initiator won, refund owner now (if not already done above)
        if (dispute.winningParty == 1 || dispute.winningParty == 0) {
            require(balanceOf(address(this)) >= awardedAmount, "DATP: Insufficient contract balance for owner refund in dispute resolve");
            _transfer(address(this), winner, awardedAmount); // AwardedAmount is the full escrow here
        }
    }

    /**
     * @dev Retrieves details for a specific dispute.
     * @param _disputeId The ID of the dispute.
     * @return Dispute struct containing dispute data.
     */
    function getDisputeDetails(uint _disputeId) public view returns (Dispute memory) {
        require(disputes[_disputeId].id != 0, "DATP: Dispute does not exist");
        return disputes[_disputeId];
    }

    /**
     * @dev Lists IDs of all active disputes.
     *      Note: Iterating allDisputeIds is gas-intensive for many disputes.
     *      Use off-chain indexing in production.
     * @return An array of active dispute IDs.
     */
     function listActiveDisputes() public view returns (uint[] memory) {
        uint[] memory activeIds = new uint[](allDisputeIds.length);
        uint count = 0;
        for (uint i = 0; i < allDisputeIds.length; i++) {
            if (disputes[allDisputeIds[i]].state != DisputeState.Resolved) {
                 activeIds[count] = allDisputeIds[i];
                 count++;
            }
        }
        uint[] memory filteredIds = new uint[](count);
        for (uint i = 0; i < count; i++) {
            filteredIds[i] = activeIds[i];
        }
        return filteredIds;
     }


    // --- Governance Functions ---

    /**
     * @dev Allows token holders (or potentially stakers) to submit a proposal for protocol changes.
     * @param _target The address of the contract to call (usually 'this' contract).
     * @param _calldata The encoded function call data for the proposal execution.
     * @param _description A description of the proposal.
     */
    function submitGovernanceProposal(address _target, bytes memory _calldata, string memory _description) public {
        // Require minimum token balance or stake to submit proposal
        // require(balanceOf(msg.sender) >= minTokensToPropose, "DATP: Insufficient tokens to submit proposal"); // Example requirement

        _proposalIdCounter.increment();
        uint proposalId = _proposalIdCounter.current();
        allProposalIds.push(proposalId);

        proposals[proposalId] = GovernanceProposal({
            id: proposalId,
            proposer: msg.sender,
            description: _description,
            callData: _calldata,
            targetContract: _target,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + proposalVotingPeriod,
            yesVotes: 0,
            noVotes: 0,
            state: ProposalState.VotingPeriod, // Starts in voting period
            executed: false,
            hasVoted: mapping(address => bool)(),
            quorumRequired: totalSupply().mul(proposalQuorumPercentage).div(100), // Quorum is % of total supply
            majorityThreshold: proposalMajorityPercentage
        });

        emit GovernanceProposalSubmitted(proposalId, msg.sender, _description);
    }

     /**
     * @dev Allows token holders to vote on an open proposal. Vote weight is based on token balance at time of vote.
     * @param _proposalId The ID of the proposal.
     * @param _support True for 'yes', False for 'no'.
     */
    function voteOnProposal(uint _proposalId, bool _support) public {
        GovernanceProposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "DATP: Proposal does not exist");
        require(proposal.state == ProposalState.VotingPeriod, "DATP: Proposal is not in voting period");
        require(block.timestamp <= proposal.voteEndTime, "DATP: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "DATP: Address has already voted on this proposal");

        uint voteWeight = balanceOf(msg.sender); // Simple token balance vote weight
        require(voteWeight > 0, "DATP: Voter must hold tokens");

        if (_support) {
            proposal.yesVotes = proposal.yesVotes.add(voteWeight);
        } else {
            proposal.noVotes = proposal.noVotes.add(voteWeight);
        }

        proposal.hasVoted[msg.sender] = true;

        emit GovernanceVoteCast(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Tally votes for a proposal and execute it if it passes quorum and majority. Callable by anyone after voting ends.
     * @param _proposalId The ID of the proposal.
     */
    function tallyGovernanceVotesAndExecute(uint _proposalId) public nonReentrant {
        GovernanceProposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "DATP: Proposal does not exist");
        require(proposal.state == ProposalState.VotingPeriod, "DATP: Proposal is not in voting period");
        require(block.timestamp > proposal.voteEndTime, "DATP: Voting period is not over yet");
        require(!proposal.executed, "DATP: Proposal has already been executed");

        // Check Quorum: Total votes cast must meet the required quorum
        uint totalVotesCast = proposal.yesVotes.add(proposal.noVotes);
        bool quorumMet = totalVotesCast >= proposal.quorumRequired;

        // Check Majority: Yes votes must meet the required percentage of *votes cast*
        bool majorityMet = false;
        if (totalVotesCast > 0) {
             majorityMet = proposal.yesVotes.mul(100) > totalVotesCast.mul(proposal.majorityThreshold);
        }


        if (quorumMet && majorityMet) {
            // Proposal succeeds, attempt execution
            proposal.state = ProposalState.Succeeded;
            bool success;
            // Execute the proposal by calling the target contract with the provided calldata
            (success,) = proposal.targetContract.call(proposal.callData); // Low-level call

            if (success) {
                proposal.executed = true;
                proposal.state = ProposalState.Executed;
                emit GovernanceProposalExecuted(_proposalId);
            } else {
                // Execution failed
                // Note: Reverting here would consume gas. A better approach logs failure.
                // For simplicity, we mark failed execution but don't revert state changes
                // of proposal state.
                // revert("DATP: Proposal execution failed"); // Don't revert
                 proposal.state = ProposalState.Failed; // Indicate execution failed
            }
        } else {
            // Proposal fails (either no quorum or no majority)
            proposal.state = ProposalState.Failed;
        }
    }

    /**
     * @dev Retrieves details for a specific governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return GovernanceProposal struct containing proposal data.
     */
    function getProposalDetails(uint _proposalId) public view returns (GovernanceProposal memory) {
        require(proposals[_proposalId].id != 0, "DATP: Proposal does not exist");
        return proposals[_proposalId];
    }

    /**
     * @dev Lists IDs of all open governance proposals (in VotingPeriod state).
     *      Note: Iterating allProposalIds is gas-intensive for many proposals.
     *      Use off-chain indexing in production.
     * @return An array of open proposal IDs.
     */
     function listOpenProposals() public view returns (uint[] memory) {
        uint[] memory openIds = new uint[](allProposalIds.length);
        uint count = 0;
        for (uint i = 0; i < allProposalIds.length; i++) {
            if (proposals[allProposalIds[i]].state == ProposalState.VotingPeriod && block.timestamp <= proposals[allProposalIds[i]].voteEndTime) {
                 openIds[count] = allProposalIds[i];
                 count++;
            }
        }
        uint[] memory filteredIds = new uint[](count);
        for (uint i = 0; i < count; i++) {
            filteredIds[i] = openIds[i];
        }
        return filteredIds;
     }

    // --- Protocol / Fee Management Functions ---

     /**
     * @dev Allows the governance mechanism to withdraw collected protocol fees.
     *      This function should only be callable by a successful governance proposal execution.
     * @param _recipient The address to send the fees to (e.g., DAO treasury, specific address).
     */
    function withdrawProtocolFees(address _recipient) public onlyOwner nonReentrant {
         // Ensure this function is *only* callable by the DAO's executeProposal function,
         // or potentially initially by the owner if the DAO isn't fully implemented yet.
         // For this example, I'm leaving it as onlyOwner, but ideally it should be protected
         // by a mechanism ensuring it comes from a passed governance proposal.
         // Example: Add a modifier `onlyGovernance` that checks if the caller is the contract itself
         // and if the callstack matches an ongoing proposal execution.

        uint feesToWithdraw = totalProtocolFeesCollected;
        require(feesToWithdraw > 0, "DATP: No protocol fees collected");
        require(balanceOf(address(this)) >= feesToWithdraw, "DATP: Insufficient contract balance for fees");

        totalProtocolFeesCollected = 0; // Reset collected fees
        _transfer(address(this), _recipient, feesToWithdraw);

        emit ProtocolFeeCollected(_recipient, feesToWithdraw);
    }

    /**
     * @dev Allows governance to set the protocol fee rate.
     *      This function should only be callable by a successful governance proposal execution.
     * @param _newRate The new fee rate (multiplied by 100, e.g., 500 for 5%).
     */
     function setProtocolFeeRate(uint _newRate) public onlyOwner {
         // Similar to withdrawProtocolFees, this should be protected by a governance mechanism.
         protocolFeeRate = _newRate;
     }

    // --- Utility Functions ---

    /**
     * @dev Get the current state of a project.
     * @param _projectId The ID of the project.
     * @return The ProjectState enum value.
     */
    function getProjectState(uint _projectId) public view returns (ProjectState) {
        require(projects[_projectId].owner != address(0), "DATP: Project does not exist");
        return projects[_projectId].state;
    }

    /**
     * @dev Get the current state of a dispute.
     * @param _disputeId The ID of the dispute.
     * @return The DisputeState enum value.
     */
    function getDisputeState(uint _disputeId) public view returns (DisputeState) {
        require(disputes[_disputeId].id != 0, "DATP: Dispute does not exist");
        return disputes[_disputeId].state;
    }

     /**
     * @dev Get the current state of a governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return The ProposalState enum value.
     */
    function getProposalState(uint _proposalId) public view returns (ProposalState) {
        require(proposals[_proposalId].id != 0, "DATP: Proposal does not exist");
        return proposals[_proposalId].state;
    }

     /**
     * @dev Check if a user is currently eligible to be selected as a juror.
     * @param _user The address of the user.
     * @return True if eligible, false otherwise.
     */
    function checkJurorEligibility(address _user) public view returns (bool) {
        // Eligible if registered and staked above minimum requirement
        return users[_user].userAddress != address(0) &&
               users[_user].state == UserState.Registered && // Ensure user is active
               users[_user].stakedAmount >= minStakeForJuror;
    }
}
```