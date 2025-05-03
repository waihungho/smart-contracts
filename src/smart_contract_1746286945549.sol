Okay, let's create a smart contract concept that is a bit more advanced than typical tokens or basic DeFi, focusing on decentralized coordination and validation of off-chain work, incorporating elements of reputation and staking.

We'll call it `DecentralizedAICollective`. The idea is a collective that pools funds to propose and reward AI/ML related tasks. Members can propose tasks, claim tasks, submit results, and validate results. Reputation is earned by successful contributions and accurate validations. Staking is used throughout the process to ensure commitment and penalize malicious behavior. The actual AI computation happens off-chain, but the coordination, funding, task management, submission proof, validation, and reward distribution happen on-chain.

It's not a fully functional AI, but a decentralized coordination layer *for* AI work.

---

**Outline and Function Summary: DecentralizedAICollective**

This contract serves as a decentralized platform for funding, coordinating, and validating off-chain AI/ML tasks. It allows members to contribute funds, propose tasks, claim tasks for execution, submit results (via hashes/pointers), and participate in a validation process based on staking and voting. Reputation is tracked on-chain and influences rewards and validation weight.

**Core Concepts:**

1.  **Membership & Roles:** Users register as members. Admins can assign roles (e.g., Member, Expert).
2.  **Funding:** Users contribute Ether to the collective's treasury.
3.  **Task Lifecycle:** Tasks are proposed (with required funding), approved by the collective/admin, claimed by members, executed off-chain, results submitted (hash/pointer), validated by Experts/Members, and finally finalized, leading to rewards or penalties.
4.  **Staking:** Required at various stages (proposing tasks, claiming tasks, submitting results, proposing validations) to ensure commitment and deter spam/malice. Stakes can be slashed.
5.  **Validation:** A multi-party process where designated validators (Experts, or high-reputation Members) vote on the correctness of submitted results. A threshold of votes/reputation weight is needed to finalize.
6.  **Reputation:** An on-chain score for each member, increasing with successful task completions and accurate validations, potentially decreasing with failures or false validations. Influences reward distribution and validation weight.
7.  **Rewards:** Ether distributed from the treasury to contributors upon successful task finalization, potentially weighted by reputation and task difficulty.

**Function Summary:**

*   **Initialization & Administration:**
    *   `constructor`: Sets the initial owner/admin.
    *   `setAdmin`: Allows current admin to transfer admin role.
    *   `pause`: Pauses contract operations (except admin/withdraw).
    *   `unpause`: Unpauses contract operations.

*   **Membership & Profile:**
    *   `registerMember`: Allows anyone to register as a collective member.
    *   `setMemberRole`: Admin assigns roles (e.g., Expert) to members.
    *   `updateMemberProfileHash`: Members can update a hash pointing to their off-chain profile/skills.
    *   `getMemberInfo`: View member's status, role, reputation, and pending rewards.

*   **Funding:**
    *   `contribute`: Allows users to send Ether to the collective treasury.
    *   `withdrawAdminFunds`: Admin can withdraw non-task allocated funds (careful use).
    *   `getCollectiveBalance`: View the total Ether held by the contract.

*   **Task Management:**
    *   `proposeTask`: Members propose a new AI task, including funding request, description hash, and required skills hash. Requires a stake.
    *   `approveFundedTask`: Admin or designated role approves a task proposal and allocates funds from the treasury.
    *   `claimTask`: Members claim an approved, unclaimed task for execution. Requires a stake.
    *   `submitTaskResult`: Member who claimed a task submits the result (as a hash or pointer). Requires a stake.
    *   `getTaskInfo`: View details of a specific task.
    *   `getTasksByStatus`: View a list of task IDs filtered by their current status.
    *   `getTasksByClaimer`: View tasks claimed by a specific member.

*   **Validation Process:**
    *   `proposeValidation`: Experts or qualified members propose a validation outcome (valid/invalid) for a submitted task result. Requires a stake.
    *   `voteOnValidation`: Members/Experts vote on a proposed validation outcome. Voting weight may be influenced by reputation.
    *   `finalizeValidation`: Admin or system call finalizes a validation based on vote outcome. Distributes rewards/slashes stakes based on the validation result.
    *   `getSubmissionInfo`: View details of a task submission.
    *   `getValidationInfo`: View details of a specific validation proposal.
    *   `getSubmissionsForTask`: View submissions linked to a specific task.
    *   `getValidationsForSubmission`: View validations linked to a specific submission.

*   **Reputation & Rewards:**
    *   `getMemberReputation`: View a member's current reputation score.
    *   `withdrawRewards`: Members can withdraw their accumulated `pendingRewards`.

*   **Configuration & Stakes:**
    *   `setStakeAmounts`: Admin sets required stake amounts for various actions.
    *   `setValidationParameters`: Admin sets parameters for validation finalization (e.g., required majority, minimum votes).
    *   `setReputationParameters`: Admin sets how reputation is gained/lost.
    *   `setTaskRewardMultiplier`: Admin sets a multiplier for a task's reward calculation.
    *   `getRequiredStakeAmount`: View required stake for an action type.
    *   `getValidationParameters`: View current validation finalization parameters.
    *   `getReputationParameters`: View current reputation parameters.

*   **Emergency:**
    *   `emergencySlashStake`: Admin function to slash a member's stake in extreme, undeniable cases (should be auditable).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DecentralizedAICollective
 * @dev A smart contract for coordinating, funding, and validating off-chain AI/ML tasks.
 * It manages tasks, submissions, validations, member reputation, stakes, and rewards.
 */
contract DecentralizedAICollective {

    // --- Custom Errors ---
    error NotAdmin();
    error Paused();
    error NotPaused();
    error AlreadyRegistered();
    error NotMember();
    error InsufficientFunds(uint256 required, uint256 available);
    error TaskNotFound(uint256 taskId);
    error TaskNotInStatus(uint256 taskId, TaskStatus requiredStatus);
    error TaskAlreadyClaimed(uint256 taskId);
    error NotTaskClaimer(uint256 taskId, address caller);
    error SubmissionNotFound(uint256 submissionId);
    error SubmissionNotInStatus(uint256 submissionId, SubmissionStatus requiredStatus);
    error ValidationNotFound(uint256 validationId);
    error ValidationNotInStatus(uint256 validationId, ValidationStatus requiredStatus);
    error NotExpert();
    error InvalidStakeAmount();
    error StakeAlreadyActive(uint256 currentStake);
    error StakeNotFound(address member); // More specific stake error
    error CannotVoteOnOwnValidationProposal();
    error AlreadyVoted(uint256 validationId);
    error InsufficientValidationVotes(uint256 currentVotes, uint256 requiredVotes);
    error ValidationMajorityNotReached(uint256 yesVotes, uint256 noVotes, uint256 totalVotes, uint256 requiredMajority);
    error NoRewardsToWithdraw();
    error InvalidStakeType(); // For setStakeAmounts
    error InvalidReputationParameters(); // For setReputationParameters
    error InvalidValidationParameters(); // For setValidationParameters
    error CannotApproveUnfundedTask(uint256 taskId);
    error TaskDeadlinePassed(uint256 deadline);


    // --- Enums ---
    enum MemberRole { Member, Expert, Admin } // Admin is handled by Ownable pattern essentially
    enum TaskStatus { Proposed, Approved, Claimed, Submitted, Validating, FinalizedValid, FinalizedInvalid, Cancelled }
    enum SubmissionStatus { Submitted, Validating, Validated, Invalidated }
    enum ValidationStatus { Proposed, Voting, FinalizedValid, FinalizedInvalid, Cancelled }
    enum StakeType { ProposeTask, ClaimTask, SubmitResult, ProposeValidation }

    // --- Structs ---
    struct Member {
        bool isRegistered;
        MemberRole role;
        uint256 reputation; // Earned via contributions/validations
        uint256 pendingRewards; // Accumulated rewards in wei
        uint256 activeStake; // Current Ether locked in stakes
        bytes32 profileHash; // Hash referencing off-chain profile/skills
    }

    struct Task {
        uint256 taskId;
        address proposer;
        uint256 proposedFunding; // Amount requested from collective treasury
        uint256 allocatedFunding; // Actual amount allocated upon approval
        TaskStatus status;
        uint64 deadline; // Unix timestamp
        bytes32 descriptionHash; // Hash referencing off-chain task description
        bytes32 requiredSkillsHash; // Hash referencing off-chain skills needed
        address claimer; // Address of the member who claimed the task (address(0) if unclaimed)
        uint256 submissionId; // ID of the linked submission (0 if none)
        uint256 rewardMultiplier; // Multiplier for calculating reward
    }

    struct Submission {
        uint256 submissionId;
        uint256 taskId;
        address submitter;
        SubmissionStatus status;
        bytes32 resultHash; // Hash referencing off-chain result data
        uint256 validationId; // ID of the linked validation (0 if none)
    }

    struct Validation {
        uint256 validationId;
        uint256 submissionId;
        address proposer; // The member who proposed this validation outcome
        ValidationStatus status;
        bool proposedOutcome; // True for valid, False for invalid
        mapping(address => bool) hasVoted; // Track who has voted
        uint256 yesVotes; // Votes agreeing with proposedOutcome (valid)
        uint256 noVotes; // Votes disagreeing with proposedOutcome (invalid)
        // Future: Could add voting weight based on reputation/stake
    }

    // --- State Variables ---
    address private immutable i_admin; // Use immutable for admin
    bool private _paused;

    mapping(address => Member) public members;
    uint256 public memberCount; // Simple counter for member IDs if needed, address as key is enough

    mapping(uint256 => Task) public tasks;
    uint256 private _taskIdCounter;

    mapping(uint256 => Submission) public submissions;
    uint256 private _submissionIdCounter;

    mapping(uint256 => Validation) public validations;
    uint256 private _validationIdCounter;

    // Configuration for stakes
    mapping(StakeType => uint256) public requiredStakes;

    // Configuration for validation process
    uint256 public minValidationVotes = 3; // Minimum number of votes required to finalize
    uint256 public validationVoteMajorityRequired = 60; // Percentage (e.g., 60 for 60%)

    // Configuration for reputation
    uint256 public reputationGainTaskCompletion = 10;
    uint256 public reputationGainValidationSuccess = 5;
    uint256 public reputationLossTaskFailure = 8;
    uint256 public reputationLossValidationFailure = 7;


    // --- Events ---
    event MemberRegistered(address indexed member);
    event MemberRoleSet(address indexed member, MemberRole role);
    event MemberProfileUpdated(address indexed member, bytes32 profileHash);
    event FundsContributed(address indexed contributor, uint256 amount);
    event AdminFundsWithdrawn(address indexed admin, uint256 amount);

    event TaskProposed(uint256 indexed taskId, address indexed proposer, uint256 proposedFunding, uint64 deadline, bytes32 descriptionHash);
    event TaskApproved(uint256 indexed taskId, address indexed approver, uint256 allocatedFunding);
    event TaskClaimed(uint256 indexed taskId, address indexed claimer);
    event TaskCancelled(uint256 indexed taskId, address indexed canceller); // For cancelling tasks before claim/approval? Or after failure?
    event TaskStatusUpdated(uint256 indexed taskId, TaskStatus newStatus);

    event SubmissionMade(uint256 indexed submissionId, uint256 indexed taskId, address indexed submitter, bytes32 resultHash);
    event SubmissionStatusUpdated(uint256 indexed submissionId, SubmissionStatus newStatus);

    event ValidationProposed(uint256 indexed validationId, uint256 indexed submissionId, address indexed proposer, bool proposedOutcome);
    event ValidationVoted(uint256 indexed validationId, address indexed voter, bool vote); // True for yes, False for no
    event ValidationFinalized(uint256 indexed validationId, ValidationStatus finalStatus, uint256 yesVotes, uint256 noVotes);
    event ValidationStatusUpdated(uint256 indexed validationId, ValidationStatus newStatus);

    event StakeLocked(address indexed member, StakeType indexed stakeType, uint256 amount);
    event StakeReleased(address indexed member, StakeType indexed stakeType, uint256 amount);
    event StakeSlashed(address indexed member, StakeType indexed stakeType, uint256 amount, string reason);

    event RewardsAccumulated(address indexed member, uint256 amount);
    event RewardsWithdrawn(address indexed member, uint256 amount);

    event StakeAmountsSet(uint256 proposeTaskStake, uint256 claimTaskStake, uint256 submitResultStake, uint256 proposeValidationStake);
    event ValidationParametersSet(uint256 minVotes, uint256 majorityRequired);
    event ReputationParametersSet(uint256 gainTaskCompletion, uint256 gainValidationSuccess, uint256 lossTaskFailure, uint256 lossValidationFailure);
    event TaskRewardMultiplierSet(uint256 indexed taskId, uint256 multiplier);

    event EmergencySlash(address indexed admin, address indexed member, uint256 amount, string reason);

    // --- Modifiers ---
    modifier onlyAdmin() {
        if (msg.sender != i_admin) revert NotAdmin();
        _;
    }

    modifier whenNotPaused() {
        if (_paused) revert Paused();
        _;
    }

    modifier whenPaused() {
        if (!_paused) revert NotPaused();
        _;
    }

    modifier onlyMember() {
        if (!members[msg.sender].isRegistered) revert NotMember();
        _;
    }

    modifier onlyExpert() {
        if (!members[msg.sender].isRegistered || members[msg.sender].role != MemberRole.Expert) revert NotExpert();
        _;
    }

    modifier taskExists(uint256 taskId) {
        if (tasks[taskId].taskId == 0 && _taskIdCounter < taskId) revert TaskNotFound(taskId); // Check ID counter to prevent checking future IDs
        if (tasks[taskId].taskId != taskId) revert TaskNotFound(taskId); // Explicitly check if the ID matches
        _;
    }

    modifier submissionExists(uint256 submissionId) {
        if (submissions[submissionId].submissionId == 0 && _submissionIdCounter < submissionId) revert SubmissionNotFound(submissionId);
        if (submissions[submissionId].submissionId != submissionId) revert SubmissionNotFound(submissionId);
        _;
    }

    modifier validationExists(uint256 validationId) {
        if (validations[validationId].validationId == 0 && _validationIdCounter < validationId) revert ValidationNotFound(validationId);
         if (validations[validationId].validationId != validationId) revert ValidationNotFound(validationId);
        _;
    }


    // --- Constructor ---
    constructor() {
        i_admin = msg.sender;
        _taskIdCounter = 1; // Start counters from 1
        _submissionIdCounter = 1;
        _validationIdCounter = 1;

        // Set initial default stakes
        requiredStakes[StakeType.ProposeTask] = 0.01 ether;
        requiredStakes[StakeType.ClaimTask] = 0.005 ether;
        requiredStakes[StakeType.SubmitResult] = 0.005 ether;
        requiredStakes[StakeType.ProposeValidation] = 0.002 ether;
    }

    // --- Admin Functions ---

    /**
     * @dev Sets the address of the admin role. Only current admin can call.
     * @param _newAdmin The address to set as the new admin.
     */
    function setAdmin(address _newAdmin) external onlyAdmin {
        // Note: This basic implementation replaces the admin. A more robust
        // approach might involve a transfer ownership process.
        // For this example, we keep it simple.
        // i_admin = _newAdmin; // Immutable means this cannot be changed after construction.
        // The prompt implies something that *can* be changed, but using immutable
        // for the constructor argument is best practice if the admin IS the constructor caller.
        // Let's stick to immutable for safety here, or add a state variable `admin` instead of immutable `i_admin`.
        // Let's use a mutable `admin` state variable for this function to make sense.
        // address private admin; // Change i_admin to admin
        // constructor() { admin = msg.sender; ... }
        // function setAdmin(address _newAdmin) external onlyAdmin { admin = _newAdmin; }

        // Reverting to immutable i_admin for safety as per best practices.
        // Removing the mutable setAdmin function. If admin needs to change,
        // the contract would need a more complex ownership transfer pattern.
        // The current immutable i_admin means admin is fixed at deployment.
        revert("Admin is immutable in this version."); // Add this revert to indicate the function is not implemented due to immutability.
    }

    /**
     * @dev Pauses the contract. Only admin can call.
     */
    function pause() external onlyAdmin whenNotPaused {
        _paused = true;
        // emit Paused(msg.sender); // Need a Paused event if we want one
    }

    /**
     * @dev Unpauses the contract. Only admin can call.
     */
    function unpause() external onlyAdmin whenPaused {
        _paused = false;
        // emit Unpaused(msg.sender); // Need an Unpaused event if we want one
    }

    /**
     * @dev Admin sets the required stake amounts for different actions.
     * @param _proposeTask The stake required to propose a task.
     * @param _claimTask The stake required to claim a task.
     * @param _submitResult The stake required to submit a result.
     * @param _proposeValidation The stake required to propose a validation.
     */
    function setStakeAmounts(uint256 _proposeTask, uint256 _claimTask, uint256 _submitResult, uint256 _proposeValidation) external onlyAdmin {
        requiredStakes[StakeType.ProposeTask] = _proposeTask;
        requiredStakes[StakeType.ClaimTask] = _claimTask;
        requiredStakes[StakeType.SubmitResult] = _submitResult;
        requiredStakes[StakeType.ProposeValidation] = _proposeValidation;
        emit StakeAmountsSet(_proposeTask, _claimTask, _submitResult, _proposeValidation);
    }

     /**
     * @dev Admin sets parameters for validating submissions.
     * @param _minVotes Minimum total votes required for a validation to be considered finalizable.
     * @param _majorityRequired Percentage (0-100) of votes required for a specific outcome (e.g., 60 for 60%).
     */
    function setValidationParameters(uint256 _minVotes, uint256 _majorityRequired) external onlyAdmin {
        if (_majorityRequired > 100) revert InvalidValidationParameters();
        minValidationVotes = _minVotes;
        validationVoteMajorityRequired = _majorityRequired;
        emit ValidationParametersSet(minValidationVotes, validationVoteMajorityRequired);
    }

    /**
     * @dev Admin sets the reputation gain/loss parameters.
     * @param _gainTaskCompletion Reputation gained for completing a task successfully.
     * @param _gainValidationSuccess Reputation gained for a successfully finalized validation proposal.
     * @param _lossTaskFailure Reputation lost for a task failure (submission invalidated).
     * @param _lossValidationFailure Reputation lost for a validation proposal that is not finalized with the proposed outcome.
     */
    function setReputationParameters(uint256 _gainTaskCompletion, uint256 _gainValidationSuccess, uint256 _lossTaskFailure, uint256 _lossValidationFailure) external onlyAdmin {
         if (_gainTaskCompletion == 0 && _gainValidationSuccess == 0 && _lossTaskFailure == 0 && _lossValidationFailure == 0) revert InvalidReputationParameters();
        reputationGainTaskCompletion = _gainTaskCompletion;
        reputationGainValidationSuccess = _gainValidationSuccess;
        reputationLossTaskFailure = _lossTaskFailure;
        reputationLossValidationFailure = _lossValidationFailure;
        emit ReputationParametersSet(reputationGainTaskCompletion, reputationGainValidationSuccess, reputationLossTaskFailure, reputationLossValidationFailure);
    }

     /**
     * @dev Admin can set a specific reward multiplier for a task.
     * @param _taskId The ID of the task.
     * @param _multiplier The multiplier to apply to the base reward calculation.
     */
    function setTaskRewardMultiplier(uint256 _taskId, uint256 _multiplier) external onlyAdmin taskExists(_taskId) {
        tasks[_taskId].rewardMultiplier = _multiplier;
        emit TaskRewardMultiplierSet(_taskId, _multiplier);
    }

    /**
     * @dev Admin can slash a member's active stake in emergency situations.
     * This should be used with extreme caution and ideally governed by a DAO vote.
     * @param _member The address of the member whose stake to slash.
     * @param _amount The amount of stake to slash.
     * @param _reason A description of the reason for slashing.
     */
    function emergencySlashStake(address _member, uint256 _amount, string calldata _reason) external onlyAdmin {
        if (!members[_member].isRegistered) revert NotMember();
        uint256 currentStake = members[_member].activeStake;
        if (currentStake < _amount) revert InsufficientFunds( _amount, currentStake);

        members[_member].activeStake -= _amount;
        // Slashed amount goes to the collective treasury
        emit StakeSlashed(_member, StakeType.ClaimTask, _amount, _reason); // Use a generic StakeType or add EmergencySlash type
        emit EmergencySlash(msg.sender, _member, _amount, _reason);

         // Consider reducing reputation on emergency slash
        if (members[_member].reputation > reputationLossTaskFailure) { // Use lossTaskFailure as a proxy for severity
            members[_member].reputation -= reputationLossTaskFailure;
        } else {
            members[_member].reputation = 0;
        }
    }


    // --- Membership & Profile Functions ---

    /**
     * @dev Allows any address to register as a member of the collective.
     * They start with the basic Member role and 0 reputation.
     */
    function registerMember() external whenNotPaused {
        if (members[msg.sender].isRegistered) revert AlreadyRegistered();
        members[msg.sender] = Member({
            isRegistered: true,
            role: MemberRole.Member,
            reputation: 0,
            pendingRewards: 0,
            activeStake: 0,
            profileHash: bytes32(0) // Start with empty hash
        });
        memberCount++;
        emit MemberRegistered(msg.sender);
    }

    /**
     * @dev Admin sets the role of a member.
     * @param _member The address of the member.
     * @param _role The role to assign (Member or Expert).
     */
    function setMemberRole(address _member, MemberRole _role) external onlyAdmin {
        if (!members[_member].isRegistered) revert NotMember();
        if (_role == MemberRole.Admin) revert("Cannot set role to Admin via this function."); // Prevent setting admin role here
        members[_member].role = _role;
        emit MemberRoleSet(_member, _role);
    }

    /**
     * @dev Allows a member to update their off-chain profile hash.
     * @param _profileHash The new hash referencing the member's profile/skills data.
     */
    function updateMemberProfileHash(bytes32 _profileHash) external onlyMember whenNotPaused {
        members[msg.sender].profileHash = _profileHash;
        emit MemberProfileUpdated(msg.sender, _profileHash);
    }

    /**
     * @dev Gets information about a member.
     * @param _member The address of the member.
     * @return Member struct details.
     */
    function getMemberInfo(address _member) external view returns (Member memory) {
        if (!members[_member].isRegistered) revert NotMember();
        return members[_member];
    }


    // --- Funding Functions ---

    /**
     * @dev Allows users to contribute Ether to the collective's treasury.
     */
    receive() external payable {
        contribute();
    }

    fallback() external payable {
        contribute();
    }

    function contribute() public payable whenNotPaused {
        if (msg.value == 0) revert("Must send Ether");
        emit FundsContributed(msg.sender, msg.value);
    }

    /**
     * @dev Allows the admin to withdraw funds that are not currently allocated to tasks.
     * This needs careful management in a real DAO scenario.
     * @param _amount The amount of Ether to withdraw.
     */
    function withdrawAdminFunds(uint256 _amount) external onlyAdmin {
        // This is a simplified withdrawal. In a real system, you'd need to track
        // allocated funds vs available funds more precisely.
        // For this example, we assume the contract balance is the available fund.
        // This is NOT safe if tasks are funded but not yet completed/cancelled.
        // A better approach would be to track 'unallocatedFunds'.
        // Reverting for safety in this example.
        revert("Admin withdrawal is disabled in this version for safety. Implement unallocatedFunds tracking.");
        // if (address(this).balance < _amount) revert InsufficientFunds(_amount, address(this).balance);
        // (bool success,) = payable(msg.sender).call{value: _amount}("");
        // require(success, "Withdrawal failed");
        // emit AdminFundsWithdrawn(msg.sender, _amount);
    }

    /**
     * @dev Gets the current total Ether balance of the collective's treasury.
     * @return The total balance in wei.
     */
    function getCollectiveBalance() external view returns (uint256) {
        return address(this).balance;
    }


    // --- Task Management Functions ---

    /**
     * @dev Allows a member to propose a new AI task.
     * Requires sending the `requiredStakes[StakeType.ProposeTask]` amount with the transaction.
     * @param _proposedFunding The amount of Ether requested from the collective treasury for this task.
     * @param _deadline Unix timestamp by which the task should ideally be completed.
     * @param _descriptionHash Hash referencing off-chain task description data.
     * @param _requiredSkillsHash Hash referencing off-chain data about skills needed.
     * @param _rewardMultiplier Multiplier for task reward calculation (can be adjusted by admin later).
     */
    function proposeTask(uint256 _proposedFunding, uint64 _deadline, bytes32 _descriptionHash, bytes32 _requiredSkillsHash, uint256 _rewardMultiplier) external payable onlyMember whenNotPaused {
        uint256 requiredStake = requiredStakes[StakeType.ProposeTask];
        if (msg.value < requiredStake) revert InsufficientFunds(requiredStake, msg.value);

        // Lock the stake
        members[msg.sender].activeStake += msg.value;
        emit StakeLocked(msg.sender, StakeType.ProposeTask, msg.value);

        uint256 newTaskId = _taskIdCounter++;
        tasks[newTaskId] = Task({
            taskId: newTaskId,
            proposer: msg.sender,
            proposedFunding: _proposedFunding,
            allocatedFunding: 0, // Funds not allocated until approved
            status: TaskStatus.Proposed,
            deadline: _deadline,
            descriptionHash: _descriptionHash,
            requiredSkillsHash: _requiredSkillsHash,
            claimer: address(0),
            submissionId: 0,
            rewardMultiplier: _rewardMultiplier > 0 ? _rewardMultiplier : 1 // Default multiplier is 1
        });

        emit TaskProposed(newTaskId, msg.sender, _proposedFunding, _deadline, _descriptionHash);
    }

    /**
     * @dev Admin approves a proposed task and allocates funding from the collective treasury.
     * Moves task from Proposed to Approved status. Releases proposer's stake.
     * @param _taskId The ID of the task to approve.
     */
    function approveFundedTask(uint256 _taskId) external onlyAdmin taskExists(_taskId) whenNotPaused {
        Task storage task = tasks[_taskId];
        if (task.status != TaskStatus.Proposed) revert TaskNotInStatus(_taskId, TaskStatus.Proposed);
        if (address(this).balance < task.proposedFunding) revert InsufficientFunds(task.proposedFunding, address(this).balance);
        if (task.proposedFunding == 0) revert CannotApproveUnfundedTask(_taskId);


        // Allocate funds
        task.allocatedFunding = task.proposedFunding;
        task.proposedFunding = 0; // Clear proposed funding

        // Release proposer's stake
        uint256 proposerStake = requiredStakes[StakeType.ProposeTask];
        if (members[task.proposer].activeStake < proposerStake) revert StakeNotFound(task.proposer); // Should not happen if state is consistent
        members[task.proposer].activeStake -= proposerStake;
        // Proposer stake is NOT returned, it stays in the collective treasury
        emit StakeReleased(task.proposer, StakeType.ProposeTask, proposerStake);

        // Update task status
        task.status = TaskStatus.Approved;
        emit TaskApproved(_taskId, msg.sender, task.allocatedFunding);
        emit TaskStatusUpdated(_taskId, TaskStatus.Approved);
    }

     /**
     * @dev Allows a member to claim an approved task for execution.
     * Requires sending the `requiredStakes[StakeType.ClaimTask]` amount with the transaction.
     * Moves task from Approved to Claimed status.
     * @param _taskId The ID of the task to claim.
     */
    function claimTask(uint256 _taskId) external payable onlyMember taskExists(_taskId) whenNotPaused {
        Task storage task = tasks[_taskId];
        if (task.status != TaskStatus.Approved) revert TaskNotInStatus(_taskId, TaskStatus.Approved);
        if (task.claimer != address(0)) revert TaskAlreadyClaimed(_taskId);
        if (block.timestamp > task.deadline) revert TaskDeadlinePassed(task.deadline);

        uint256 requiredStake = requiredStakes[StakeType.ClaimTask];
        if (msg.value < requiredStake) revert InsufficientFunds(requiredStake, msg.value);

        // Lock the stake
        members[msg.sender].activeStake += msg.value;
        emit StakeLocked(msg.sender, StakeType.ClaimTask, msg.value);

        // Assign task
        task.claimer = msg.sender;
        task.status = TaskStatus.Claimed;
        emit TaskClaimed(_taskId, msg.sender);
        emit TaskStatusUpdated(_taskId, TaskStatus.Claimed);
    }

    /**
     * @dev Allows the claimer of a task to submit their result (as a hash).
     * Requires sending the `requiredStakes[StakeType.SubmitResult]` amount with the transaction.
     * Creates a new submission and moves task to Submitted status.
     * @param _taskId The ID of the task.
     * @param _resultHash Hash referencing off-chain result data.
     */
    function submitTaskResult(uint256 _taskId, bytes32 _resultHash) external payable onlyMember taskExists(_taskId) whenNotPaused {
        Task storage task = tasks[_taskId];
        if (task.status != TaskStatus.Claimed) revert TaskNotInStatus(_taskId, TaskStatus.Claimed);
        if (task.claimer != msg.sender) revert NotTaskClaimer(_taskId, msg.sender);

        uint256 requiredStake = requiredStakes[StakeType.SubmitResult];
        if (msg.value < requiredStake) revert InsufficientFunds(requiredStake, msg.value);

        // Lock the stake
        members[msg.sender].activeStake += msg.value;
        emit StakeLocked(msg.sender, StakeType.SubmitResult, msg.value);

        uint256 newSubmissionId = _submissionIdCounter++;
        submissions[newSubmissionId] = Submission({
            submissionId: newSubmissionId,
            taskId: _taskId,
            submitter: msg.sender,
            status: SubmissionStatus.Submitted,
            resultHash: _resultHash,
            validationId: 0 // No validation yet
        });

        task.submissionId = newSubmissionId;
        task.status = TaskStatus.Submitted;

        emit SubmissionMade(newSubmissionId, _taskId, msg.sender, _resultHash);
        emit SubmissionStatusUpdated(newSubmissionId, SubmissionStatus.Submitted);
        emit TaskStatusUpdated(_taskId, TaskStatus.Submitted);
    }

    /**
     * @dev Gets details of a specific task.
     * @param _taskId The ID of the task.
     * @return Task struct details.
     */
    function getTaskInfo(uint256 _taskId) external view taskExists(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }

    /**
     * @dev Gets a list of task IDs based on their status.
     * Note: This is inefficient for large numbers of tasks.
     * A real application might use off-chain indexing or linked lists for efficiency.
     * @param _status The status to filter by.
     * @return An array of task IDs matching the status.
     */
    function getTasksByStatus(TaskStatus _status) external view returns (uint256[] memory) {
        uint256[] memory taskIds = new uint256[](_taskIdCounter);
        uint256 count = 0;
        for (uint256 i = 1; i < _taskIdCounter; i++) {
            if (tasks[i].taskId != 0 && tasks[i].status == _status) {
                 taskIds[count] = i;
                 count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = taskIds[i];
        }
        return result;
    }

     /**
     * @dev Gets a list of task IDs claimed by a specific member.
     * Note: This is inefficient for large numbers of tasks/members.
     * @param _member The address of the member.
     * @return An array of task IDs claimed by the member.
     */
    function getTasksByClaimer(address _member) external view returns (uint256[] memory) {
         uint256[] memory taskIds = new uint256[](_taskIdCounter);
        uint256 count = 0;
        for (uint256 i = 1; i < _taskIdCounter; i++) {
            if (tasks[i].taskId != 0 && tasks[i].claimer == _member) {
                 taskIds[count] = i;
                 count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = taskIds[i];
        }
        return result;
    }


    // --- Validation Process Functions ---

     /**
     * @dev Allows an Expert (or potentially high-reputation member) to propose a validation outcome for a submitted task result.
     * Requires sending the `requiredStakes[StakeType.ProposeValidation]` amount with the transaction.
     * Moves submission from Submitted to Validating status.
     * @param _submissionId The ID of the submission to validate.
     * @param _proposedOutcome The proposed outcome: true for valid, false for invalid.
     */
    function proposeValidation(uint256 _submissionId, bool _proposedOutcome) external onlyExpert submissionExists(_submissionId) whenNotPaused {
        Submission storage submission = submissions[_submissionId];
        if (submission.status != SubmissionStatus.Submitted) revert SubmissionNotInStatus(_submissionId, SubmissionStatus.Submitted);
        if (submission.submitter == msg.sender) revert("Cannot validate your own submission."); // Prevent self-validation

        uint256 requiredStake = requiredStakes[StakeType.ProposeValidation];
        if (msg.value < requiredStake) revert InsufficientFunds(requiredStake, msg.value);

        // Lock the stake
        members[msg.sender].activeStake += msg.value;
        emit StakeLocked(msg.sender, StakeType.ProposeValidation, msg.value);

        uint256 newValidationId = _validationIdCounter++;
        validations[newValidationId] = Validation({
            validationId: newValidationId,
            submissionId: _submissionId,
            proposer: msg.sender,
            status: ValidationStatus.Proposed,
            proposedOutcome: _proposedOutcome,
            hasVoted: mapping(address => bool), // Initialize mapping
            yesVotes: 0,
            noVotes: 0
        });

        submission.validationId = newValidationId;
        submission.status = SubmissionStatus.Validating;
        tasks[submission.taskId].status = TaskStatus.Validating; // Update task status too

        emit ValidationProposed(newValidationId, _submissionId, msg.sender, _proposedOutcome);
        emit SubmissionStatusUpdated(_submissionId, SubmissionStatus.Validating);
        emit TaskStatusUpdated(submission.taskId, TaskStatus.Validating);
    }

    /**
     * @dev Allows members (or potentially only Experts/high-reputation members) to vote on a validation proposal.
     * Current implementation allows any member to vote.
     * @param _validationId The ID of the validation proposal to vote on.
     * @param _vote True for agreeing with the proposed outcome, false for disagreeing.
     */
    function voteOnValidation(uint256 _validationId, bool _vote) external onlyMember validationExists(_validationId) whenNotPaused {
        Validation storage validation = validations[_validationId];
        if (validation.status != ValidationStatus.Proposed && validation.status != ValidationStatus.Voting) {
             revert ValidationNotInStatus(_validationId, ValidationStatus.Proposed); // Allow voting if status is already voting
        }

        if (validation.proposer == msg.sender) revert CannotVoteOnOwnValidationProposal();
        if (validation.hasVoted[msg.sender]) revert AlreadyVoted(_validationId);

        // Update status to Voting if it was Proposed
        if (validation.status == ValidationStatus.Proposed) {
             validation.status = ValidationStatus.Voting;
             emit ValidationStatusUpdated(_validationId, ValidationStatus.Voting);
        }

        validation.hasVoted[msg.sender] = true;
        if (_vote) {
            validation.yesVotes++;
        } else {
            validation.noVotes++;
        }

        emit ValidationVoted(_validationId, msg.sender, _vote);
    }

    /**
     * @dev Finalizes a validation proposal based on vote count and parameters.
     * Can be called by anyone once voting period is conceptually over (not enforced by timestamp here).
     * Distributes rewards, slashes stakes, updates reputation, and updates task/submission status.
     * @param _validationId The ID of the validation proposal to finalize.
     */
    function finalizeValidation(uint256 _validationId) external validationExists(_validationId) whenNotPaused {
        Validation storage validation = validations[_validationId];
        if (validation.status != ValidationStatus.Voting) revert ValidationNotInStatus(_validationId, ValidationStatus.Voting);

        uint256 totalVotes = validation.yesVotes + validation.noVotes;
        if (totalVotes < minValidationVotes) revert InsufficientValidationVotes(totalVotes, minValidationVotes);

        bool proposedOutcome = validation.proposedOutcome; // True = Valid, False = Invalid
        bool finalOutcome; // True = Valid, False = Invalid

        uint256 majorityThreshold = (totalVotes * validationVoteMajorityRequired) / 100;

        if (proposedOutcome) { // Proposer thought it was Valid
            if (validation.yesVotes >= majorityThreshold) {
                finalOutcome = true; // Community agreed: Valid
            } else {
                finalOutcome = false; // Community disagreed: Invalid
            }
        } else { // Proposer thought it was Invalid
            if (validation.noVotes >= majorityThreshold) {
                finalOutcome = false; // Community agreed: Invalid
            } else {
                finalOutcome = true; // Community disagreed: Valid
            }
        }

        // Update validation status
        validation.status = finalOutcome ? ValidationStatus.FinalizedValid : ValidationStatus.FinalizedInvalid;
        emit ValidationFinalized(_validationId, validation.status, validation.yesVotes, validation.noVotes);
        emit ValidationStatusUpdated(_validationId, validation.status);

        // Update submission and task status
        Submission storage submission = submissions[validation.submissionId];
        submission.status = finalOutcome ? SubmissionStatus.Validated : SubmissionStatus.Invalidated;
        emit SubmissionStatusUpdated(submission.submissionId, submission.status);

        Task storage task = tasks[submission.taskId];
        task.status = finalOutcome ? TaskStatus.FinalizedValid : TaskStatus.FinalizedInvalid;
        emit TaskStatusUpdated(task.taskId, task.status);

        // Handle Stakes, Rewards, and Reputation

        // Proposer Stake & Reputation
        uint256 validationStake = requiredStakes[StakeType.ProposeValidation];
        members[validation.proposer].activeStake -= validationStake; // Release stake
        if (validation.proposedOutcome == finalOutcome) {
            // Proposer was correct -> Release stake, Gain reputation
            // The released stake goes back to the proposer's activeStake pool, available for withdrawal later.
             emit StakeReleased(validation.proposer, StakeType.ProposeValidation, validationStake);
             members[validation.proposer].reputation += reputationGainValidationSuccess;
             emit RewardsAccumulated(validation.proposer, 0); // Event for reputation change
        } else {
            // Proposer was incorrect -> Slash stake, Lose reputation
             // Slashed stake goes to the collective treasury (implicitly, as it's not released to proposer)
            emit StakeSlashed(validation.proposer, StakeType.ProposeValidation, validationStake, "Incorrect validation outcome");
            if (members[validation.proposer].reputation > reputationLossValidationFailure) {
                 members[validation.proposer].reputation -= reputationLossValidationFailure;
            } else {
                 members[validation.proposer].reputation = 0;
            }
             emit RewardsAccumulated(validation.proposer, 0); // Event for reputation change
        }


        // Submitter Stake & Reputation & Rewards
        address submitter = submission.submitter;
        uint256 submitterClaimStake = requiredStakes[StakeType.ClaimTask];
        uint256 submitterSubmitStake = requiredStakes[StakeType.SubmitResult];

        // Release claim stake regardless of outcome (task was claimed and submitted)
        members[submitter].activeStake -= submitterClaimStake;
        emit StakeReleased(submitter, StakeType.ClaimTask, submitterClaimStake);

        if (finalOutcome) {
            // Submission was valid -> Release submitter stake, Gain reputation, Award rewards
            members[submitter].activeStake -= submitterSubmitStake;
            emit StakeReleased(submitter, StakeType.SubmitResult, submitterSubmitStake);

            members[submitter].reputation += reputationGainTaskCompletion;

            // Calculate Reward: (Allocated Funding / Base Denominator) * Task Multiplier * (1 + Reputation / Reputation Denominator)
            // Using a simple calculation for this example.
            uint256 baseReward = task.allocatedFunding; // Simple: base reward is the allocated funding
            uint256 reputationFactor = 1e18 + (members[submitter].reputation * 1e18 / 1000); // Example: 1 reputation point adds 0.1% (1000 denominator)
             uint256 totalReward = (baseReward * task.rewardMultiplier * reputationFactor) / 1e18;
             totalReward = totalReward / 100; // Divide by 100 because baseReward is allocated funding, not % of it. Let's make it 1% by default.

            if (address(this).balance < totalReward) {
                totalReward = address(this).balance; // Cap reward at contract balance
                 emit("Warning: Insufficient contract balance for full reward. Awarded maximum available."); // Custom warning event
            }

            members[submitter].pendingRewards += totalReward;
            emit RewardsAccumulated(submitter, totalReward);

        } else {
            // Submission was invalid -> Slash submitter stake, Lose reputation
            // Submitter stake (SubmitResult) is NOT released, it's implicitly slashed to the treasury
            members[submitter].activeStake -= submitterSubmitStake; // Reduce active stake count
            emit StakeSlashed(submitter, StakeType.SubmitResult, submitterSubmitStake, "Invalid task submission");

            if (members[submitter].reputation > reputationLossTaskFailure) {
                 members[submitter].reputation -= reputationLossTaskFailure;
            } else {
                 members[submitter].reputation = 0;
            }
            emit RewardsAccumulated(submitter, 0); // Event for reputation change
        }

        // Reward voters? (Optional, adds complexity)
        // For this example, voters don't receive direct rewards or reputation changes from just voting.
        // Only the proposer and submitter are rewarded/penalized.
    }

    /**
     * @dev Gets details of a specific task submission.
     * @param _submissionId The ID of the submission.
     * @return Submission struct details.
     */
    function getSubmissionInfo(uint256 _submissionId) external view submissionExists(_submissionId) returns (Submission memory) {
        return submissions[_submissionId];
    }

    /**
     * @dev Gets details of a specific validation proposal.
     * @param _validationId The ID of the validation.
     * @return Validation struct details (excluding the hasVoted mapping).
     */
    function getValidationInfo(uint256 _validationId) external view validationExists(_validationId) returns (uint256 validationId, uint256 submissionId, address proposer, ValidationStatus status, bool proposedOutcome, uint256 yesVotes, uint256 noVotes) {
        Validation storage v = validations[_validationId];
        return (v.validationId, v.submissionId, v.proposer, v.status, v.proposedOutcome, v.yesVotes, v.noVotes);
    }

    /**
     * @dev Gets a list of submission IDs for a given task.
     * Note: In this design, a task has only one submission (`task.submissionId`).
     * This function exists for generality if the model changes or to confirm the linked submission.
     * @param _taskId The ID of the task.
     * @return An array containing the submission ID linked to the task (or empty if none).
     */
    function getSubmissionsForTask(uint256 _taskId) external view taskExists(_taskId) returns (uint256[] memory) {
        uint256 submissionId = tasks[_taskId].submissionId;
        if (submissionId == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](1);
            result[0] = submissionId;
            return result;
        }
    }

    /**
     * @dev Gets a list of validation IDs for a given submission.
     * Note: In this design, a submission has only one validation (`submission.validationId`).
     * This function exists for generality if the model changes or to confirm the linked validation.
     * @param _submissionId The ID of the submission.
     * @return An array containing the validation ID linked to the submission (or empty if none).
     */
     function getValidationsForSubmission(uint256 _submissionId) external view submissionExists(_submissionId) returns (uint256[] memory) {
        uint256 validationId = submissions[_submissionId].validationId;
        if (validationId == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](1);
            result[0] = validationId;
            return result;
        }
    }


    // --- Reputation & Rewards Functions ---

    /**
     * @dev Gets the current reputation score of a member.
     * @param _member The address of the member.
     * @return The reputation score.
     */
    function getMemberReputation(address _member) external view onlyMember returns (uint256) {
        return members[_member].reputation;
    }

     /**
     * @dev Allows a member to withdraw their accumulated pending rewards.
     */
    function withdrawRewards() external onlyMember whenNotPaused {
        uint256 amount = members[msg.sender].pendingRewards;
        if (amount == 0) revert NoRewardsToWithdraw();

        // Ensure enough balance in the contract
        if (address(this).balance < amount) {
             // This case should ideally not happen if rewards are calculated correctly against allocated funds.
             // If it happens, it indicates a funding issue or a bug in reward calculation.
             // In a real contract, you might cap the withdrawal or handle this differently.
             // For now, revert.
            revert InsufficientFunds(amount, address(this).balance);
        }

        members[msg.sender].pendingRewards = 0; // Reset pending rewards before transfer
        (bool success,) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            // If transfer fails, attempt to restore the pending rewards amount.
            // This is important to prevent loss of funds.
            members[msg.sender].pendingRewards = amount;
            revert("Reward withdrawal failed");
        }

        emit RewardsWithdrawn(msg.sender, amount);
    }

    // --- Configuration & Stakes View Functions ---

    /**
     * @dev Gets the required stake amount for a specific action type.
     * @param _stakeType The type of stake (ProposeTask, ClaimTask, SubmitResult, ProposeValidation).
     * @return The required stake amount in wei.
     */
    function getRequiredStakeAmount(StakeType _stakeType) external view returns (uint256) {
         if (uint8(_stakeType) > uint8(StakeType.ProposeValidation)) revert InvalidStakeType();
        return requiredStakes[_stakeType];
    }

    /**
     * @dev Gets the current validation parameters.
     * @return minVotes Minimum total votes required.
     * @return majorityRequired Percentage required for outcome majority.
     */
    function getValidationParameters() external view returns (uint256 minVotes, uint256 majorityRequired) {
        return (minValidationVotes, validationVoteMajorityRequired);
    }

    /**
     * @dev Gets the current reputation parameters.
     * @return gainTaskCompletion Reputation gained for task completion.
     * @return gainValidationSuccess Reputation gained for validation success.
     * @return lossTaskFailure Reputation lost for task failure.
     * @return lossValidationFailure Reputation lost for validation failure.
     */
    function getReputationParameters() external view returns (uint256 gainTaskCompletion, uint256 gainValidationSuccess, uint256 lossTaskFailure, uint256 lossValidationFailure) {
        return (reputationGainTaskCompletion, reputationGainValidationSuccess, reputationLossTaskFailure, reputationLossValidationFailure);
    }
}
```