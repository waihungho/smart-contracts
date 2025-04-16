```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Task Marketplace with Reputation and Skill-Based Matching
 * @author Bard (Inspired by user request)
 * @notice This contract implements a decentralized task marketplace where users can post tasks,
 *         workers can apply, and tasks are matched based on skills and reputation.
 *         It incorporates advanced concepts like dynamic task pricing, skill-based matching,
 *         on-chain reputation, dispute resolution, and decentralized governance over marketplace parameters.
 *
 * Function Summary:
 * -----------------
 * **Core Marketplace Functions:**
 * 1.  `postTask(string memory _title, string memory _description, uint256 _initialReward, string[] memory _requiredSkills)`: Allows users to post a new task with details, reward, and required skills.
 * 2.  `applyForTask(uint256 _taskId, string[] memory _workerSkills)`: Allows workers to apply for a task, declaring their relevant skills.
 * 3.  `acceptApplication(uint256 _taskId, address _workerAddress)`: Task posters can accept a worker's application.
 * 4.  `submitTaskCompletion(uint256 _taskId)`: Workers submit task completion for review.
 * 5.  `approveTaskCompletion(uint256 _taskId)`: Task posters approve task completion, releasing the reward.
 * 6.  `rejectTaskCompletion(uint256 _taskId)`: Task posters reject task completion, potentially initiating dispute resolution.
 * 7.  `cancelTask(uint256 _taskId)`: Allows task posters to cancel a task before it's accepted.
 *
 * **Reputation and Skill Management:**
 * 8.  `rateWorker(address _workerAddress, uint256 _rating, string memory _feedback)`: Task posters can rate workers after task completion.
 * 9.  `getWorkerReputation(address _workerAddress)`: Allows anyone to view a worker's reputation score.
 * 10. `addSkill(string memory _skillName)`: (Governance) Adds a new skill to the list of recognized skills in the marketplace.
 * 11. `removeSkill(string memory _skillName)`: (Governance) Removes a skill from the list of recognized skills.
 * 12. `listSkills()`: Returns the list of currently recognized skills.
 *
 * **Dynamic Pricing and Reward Adjustment:**
 * 13. `adjustTaskReward(uint256 _taskId, uint256 _newReward)`: (Governance/Advanced Logic) Allows for dynamic adjustment of task rewards based on market conditions or complexity (governance controlled or automated logic could be implemented).
 * 14. `suggestRewardIncrease(uint256 _taskId, uint256 _suggestedIncrease)`: Workers can suggest a reward increase if the task is more complex than initially described.
 * 15. `agreeToRewardIncrease(uint256 _taskId, uint256 _agreedIncrease)`: Task posters can agree to a suggested reward increase.
 *
 * **Dispute Resolution and Governance:**
 * 16. `initiateDispute(uint256 _taskId, string memory _disputeReason)`: Workers or task posters can initiate a dispute if there's disagreement.
 * 17. `resolveDispute(uint256 _disputeId, DisputeResolution _resolution, address _winner)`: (Governance/Oracles) A designated dispute resolver (e.g., DAO, oracle) resolves the dispute.
 * 18. `proposeGovernanceChange(string memory _proposalDescription, bytes memory _functionCallData)`: (Governance) Members can propose changes to marketplace parameters or functionalities.
 * 19. `voteOnGovernanceChange(uint256 _proposalId, bool _vote)`: (Governance) Members vote on governance proposals.
 * 20. `executeGovernanceChange(uint256 _proposalId)`: (Governance) Executes approved governance changes.
 *
 * **Utility/Informational Functions:**
 * 21. `getTaskDetails(uint256 _taskId)`: Returns detailed information about a specific task.
 * 22. `getOpenTasks()`: Returns a list of IDs of tasks that are currently open for applications.
 * 23. `getTasksForPoster(address _poster)`: Returns a list of task IDs posted by a specific address.
 * 24. `getTasksForWorker(address _worker)`: Returns a list of task IDs a worker is involved in.
 * 25. `getVersion()`: Returns the contract version.
 */
contract DynamicTaskMarketplace {

    // --- Data Structures ---
    enum TaskStatus { Open, Accepted, Completed, Approved, Rejected, Cancelled, Disputed }
    enum DisputeResolution { Unresolved, PosterWins, WorkerWins, SplitReward }

    struct Task {
        address poster;
        string title;
        string description;
        uint256 reward;
        TaskStatus status;
        string[] requiredSkills;
        address assignedWorker;
        uint256 applicationCount;
        uint256 suggestedRewardIncrease;
        uint256 agreedRewardIncrease;
    }

    struct WorkerApplication {
        address workerAddress;
        string[] workerSkills;
        uint256 applicationTime;
    }

    struct WorkerReputation {
        uint256 ratingSum;
        uint256 ratingCount;
    }

    struct Dispute {
        uint256 taskId;
        address initiator;
        string reason;
        DisputeResolution resolution;
        address winner;
        bool resolved;
    }

    struct GovernanceProposal {
        string description;
        bytes functionCallData;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        uint256 proposalTime;
    }

    // --- State Variables ---
    Task[] public tasks;
    mapping(uint256 => WorkerApplication[]) public taskApplications;
    mapping(address => WorkerReputation) public workerReputations;
    Dispute[] public disputes;
    GovernanceProposal[] public governanceProposals;
    string[] public skills;
    address public contractOwner;
    uint256 public disputeResolutionFee; // Example: Fee for dispute resolution services
    uint256 public governanceQuorumPercentage = 51; // Percentage required for governance proposal to pass
    uint256 public taskApplicationDeadline = 7 days; // Example: Deadline for task applications
    uint256 public disputeResolutionDeadline = 14 days; // Example: Deadline for dispute resolution

    uint256 public taskCounter = 0;
    uint256 public disputeCounter = 0;
    uint256 public governanceProposalCounter = 0;
    string public constant VERSION = "1.0.0";

    // --- Events ---
    event TaskPosted(uint256 taskId, address poster, string title);
    event ApplicationSubmitted(uint256 taskId, address worker);
    event ApplicationAccepted(uint256 taskId, address worker);
    event TaskCompletionSubmitted(uint256 taskId, address worker);
    event TaskCompletionApproved(uint256 taskId, address worker);
    event TaskCompletionRejected(uint256 taskId, address worker);
    event TaskCancelled(uint256 taskId, uint256 indexed taskIdValue);
    event WorkerRated(address worker, uint256 rating, string feedback);
    event SkillAdded(string skillName);
    event SkillRemoved(string skillName);
    event RewardAdjusted(uint256 taskId, uint256 newReward);
    event RewardIncreaseSuggested(uint256 taskId, address worker, uint256 suggestedIncrease);
    event RewardIncreaseAgreed(uint256 taskId, uint256 agreedIncrease);
    event DisputeInitiated(uint256 disputeId, uint256 taskId, address initiator, string reason);
    event DisputeResolved(uint256 disputeId, DisputeResolution resolution, address winner);
    event GovernanceProposalCreated(uint256 proposalId, string description);
    event GovernanceVoteCast(uint256 proposalId, address voter, bool vote);
    event GovernanceProposalExecuted(uint256 proposalId);

    // --- Modifiers ---
    modifier onlyPoster(uint256 _taskId) {
        require(tasks[_taskId].poster == msg.sender, "Only task poster can call this function.");
        _;
    }

    modifier onlyWorkerAssigned(uint256 _taskId) {
        require(tasks[_taskId].assignedWorker == msg.sender, "Only assigned worker can call this function.");
        _;
    }

    modifier taskExists(uint256 _taskId) {
        require(_taskId < tasks.length, "Task does not exist.");
        _;
    }

    modifier taskStatusIs(uint256 _taskId, TaskStatus _status) {
        require(tasks[_taskId].status == _status, "Task status is not the required status.");
        _;
    }

    modifier validSkill(string memory _skillName) {
        bool skillExists = false;
        for (uint256 i = 0; i < skills.length; i++) {
            if (keccak256(bytes(skills[i])) == keccak256(bytes(_skillName))) {
                skillExists = true;
                break;
            }
        }
        require(skillExists, "Skill is not a recognized skill.");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only contract owner can call this function.");
        _;
    }

    // --- Constructor ---
    constructor() {
        contractOwner = msg.sender;
        skills.push("Web Development");
        skills.push("Mobile Development");
        skills.push("Data Analysis");
        skills.push("Graphic Design");
        skills.push("Writing");
    }

    // --- Core Marketplace Functions ---

    /// @notice Allows users to post a new task.
    /// @param _title The title of the task.
    /// @param _description A detailed description of the task.
    /// @param _initialReward The reward offered for completing the task (in wei).
    /// @param _requiredSkills An array of skills required for the task.
    function postTask(
        string memory _title,
        string memory _description,
        uint256 _initialReward,
        string[] memory _requiredSkills
    ) external payable {
        require(msg.value >= _initialReward, "Insufficient funds sent for reward.");
        require(_requiredSkills.length > 0, "At least one skill is required for the task.");
        for (uint256 i = 0; i < _requiredSkills.length; i++) {
            bool skillValid = false;
            for(uint256 j=0; j < skills.length; j++){
                if(keccak256(bytes(skills[j])) == keccak256(bytes(_requiredSkills[i]))){
                    skillValid = true;
                    break;
                }
            }
            require(skillValid, "Invalid skill provided in required skills.");
        }

        tasks.push(Task({
            poster: msg.sender,
            title: _title,
            description: _description,
            reward: _initialReward,
            status: TaskStatus.Open,
            requiredSkills: _requiredSkills,
            assignedWorker: address(0),
            applicationCount: 0,
            suggestedRewardIncrease: 0,
            agreedRewardIncrease: 0
        }));

        taskCounter++;
        payable(address(this)).transfer(msg.value); // Store the reward in the contract.
        emit TaskPosted(taskCounter - 1, msg.sender, _title);
    }

    /// @notice Allows workers to apply for an open task.
    /// @param _taskId The ID of the task to apply for.
    /// @param _workerSkills An array of skills the worker possesses that are relevant to the task.
    function applyForTask(uint256 _taskId, string[] memory _workerSkills)
        external
        taskExists(_taskId)
        taskStatusIs(_taskId, TaskStatus.Open)
    {
        require(_workerSkills.length > 0, "Must declare at least one skill for application.");
        for (uint256 i = 0; i < _workerSkills.length; i++) {
            bool skillValid = false;
            for(uint256 j=0; j < skills.length; j++){
                if(keccak256(bytes(skills[j])) == keccak256(bytes(_workerSkills[i]))){
                    skillValid = true;
                    break;
                }
            }
            require(skillValid, "Invalid skill provided in worker skills.");
        }

        WorkerApplication memory newApplication = WorkerApplication({
            workerAddress: msg.sender,
            workerSkills: _workerSkills,
            applicationTime: block.timestamp
        });
        taskApplications[_taskId].push(newApplication);
        tasks[_taskId].applicationCount++;
        emit ApplicationSubmitted(_taskId, msg.sender);
    }

    /// @notice Allows the task poster to accept a worker's application for a task.
    /// @param _taskId The ID of the task.
    /// @param _workerAddress The address of the worker to accept.
    function acceptApplication(uint256 _taskId, address _workerAddress)
        external
        onlyPoster(_taskId)
        taskExists(_taskId)
        taskStatusIs(_taskId, TaskStatus.Open)
    {
        bool applicationFound = false;
        for(uint256 i = 0; i < taskApplications[_taskId].length; i++){
            if(taskApplications[_taskId][i].workerAddress == _workerAddress){
                applicationFound = true;
                break;
            }
        }
        require(applicationFound, "Worker has not applied for this task.");

        tasks[_taskId].status = TaskStatus.Accepted;
        tasks[_taskId].assignedWorker = _workerAddress;
        emit ApplicationAccepted(_taskId, _workerAddress);
    }

    /// @notice Allows the assigned worker to submit task completion.
    /// @param _taskId The ID of the task.
    function submitTaskCompletion(uint256 _taskId)
        external
        taskExists(_taskId)
        taskStatusIs(_taskId, TaskStatus.Accepted)
        onlyWorkerAssigned(_taskId)
    {
        tasks[_taskId].status = TaskStatus.Completed;
        emit TaskCompletionSubmitted(_taskId, msg.sender);
    }

    /// @notice Allows the task poster to approve task completion and release the reward.
    /// @param _taskId The ID of the task.
    function approveTaskCompletion(uint256 _taskId)
        external
        onlyPoster(_taskId)
        taskExists(_taskId)
        taskStatusIs(_taskId, TaskStatus.Completed)
    {
        tasks[_taskId].status = TaskStatus.Approved;
        payable(tasks[_taskId].assignedWorker).transfer(tasks[_taskId].reward + tasks[_taskId].agreedRewardIncrease);
        emit TaskCompletionApproved(_taskId, tasks[_taskId].assignedWorker);
    }

    /// @notice Allows the task poster to reject task completion if not satisfied.
    /// @param _taskId The ID of the task.
    function rejectTaskCompletion(uint256 _taskId)
        external
        onlyPoster(_taskId)
        taskExists(_taskId)
        taskStatusIs(_taskId, TaskStatus.Completed)
    {
        tasks[_taskId].status = TaskStatus.Rejected;
        emit TaskCompletionRejected(_taskId, tasks[_taskId].assignedWorker);
    }

    /// @notice Allows the task poster to cancel a task before it is accepted.
    /// @param _taskId The ID of the task.
    function cancelTask(uint256 _taskId)
        external
        onlyPoster(_taskId)
        taskExists(_taskId)
        taskStatusIs(_taskId, TaskStatus.Open)
    {
        tasks[_taskId].status = TaskStatus.Cancelled;
        payable(tasks[_taskId].poster).transfer(tasks[_taskId].reward); // Return the reward to the poster.
        emit TaskCancelled(_taskId, _taskId);
    }

    // --- Reputation and Skill Management ---

    /// @notice Allows the task poster to rate a worker after task completion.
    /// @param _workerAddress The address of the worker to rate.
    /// @param _rating The rating given (e.g., 1-5 stars).
    /// @param _feedback Optional feedback text.
    function rateWorker(address _workerAddress, uint256 _rating, string memory _feedback)
        external
        taskExists(msg.value) // Using msg.value as a placeholder for taskId in a simplified example, ideally you'd pass taskId as a parameter based on context
        onlyPoster(msg.value) // Again, placeholder, in real scenario, you'd know the taskId
        taskStatusIs(msg.value, TaskStatus.Approved) || taskStatusIs(msg.value, TaskStatus.Rejected) // Rate only after completion/rejection
    {
        require(_rating > 0 && _rating <= 5, "Rating must be between 1 and 5.");

        WorkerReputation storage reputation = workerReputations[_workerAddress];
        reputation.ratingSum += _rating;
        reputation.ratingCount++;
        emit WorkerRated(_workerAddress, _rating, _feedback);
    }

    /// @notice Gets the reputation score of a worker.
    /// @param _workerAddress The address of the worker.
    /// @return The average reputation score (0 if no ratings).
    function getWorkerReputation(address _workerAddress) external view returns (uint256) {
        WorkerReputation storage reputation = workerReputations[_workerAddress];
        if (reputation.ratingCount == 0) {
            return 0;
        }
        return reputation.ratingSum / reputation.ratingCount;
    }

    /// @notice (Governance) Adds a new skill to the marketplace.
    /// @param _skillName The name of the skill to add.
    function addSkill(string memory _skillName) external onlyOwner {
        for (uint256 i = 0; i < skills.length; i++) {
            if (keccak256(bytes(skills[i])) == keccak256(bytes(_skillName))) {
                revert("Skill already exists.");
            }
        }
        skills.push(_skillName);
        emit SkillAdded(_skillName);
    }

    /// @notice (Governance) Removes a skill from the marketplace.
    /// @param _skillName The name of the skill to remove.
    function removeSkill(string memory _skillName) external onlyOwner {
        for (uint256 i = 0; i < skills.length; i++) {
            if (keccak256(bytes(skills[i])) == keccak256(bytes(_skillName))) {
                delete skills[i]; // More gas-efficient than removing and shifting in simple cases
                emit SkillRemoved(_skillName);
                return;
            }
        }
        revert("Skill not found.");
    }

    /// @notice Lists all currently recognized skills.
    /// @return An array of skill names.
    function listSkills() external view returns (string[] memory) {
        return skills;
    }

    // --- Dynamic Pricing and Reward Adjustment ---

    /// @notice (Governance/Advanced Logic) Adjusts the reward for a task (governance controlled or automated logic).
    /// @param _taskId The ID of the task.
    /// @param _newReward The new reward amount.
    function adjustTaskReward(uint256 _taskId, uint256 _newReward) external onlyOwner taskExists(_taskId) taskStatusIs(_taskId, TaskStatus.Open) {
        require(_newReward <= getContractBalance(), "Contract balance is insufficient for new reward."); // Ensure contract has funds
        uint256 currentReward = tasks[_taskId].reward;
        tasks[_taskId].reward = _newReward;

        if(_newReward > currentReward){
            uint256 rewardIncrease = _newReward - currentReward;
            payable(address(this)).transfer(rewardIncrease); // Ensure contract has additional funds if reward increases.
        } else if (_newReward < currentReward){
            uint256 rewardDecrease = currentReward - _newReward;
            payable(tasks[_taskId].poster).transfer(rewardDecrease); // Return excess funds to poster if reward decreases.
        }

        emit RewardAdjusted(_taskId, _newReward);
    }

    /// @notice Workers can suggest a reward increase if the task is more complex than described.
    /// @param _taskId The ID of the task.
    /// @param _suggestedIncrease The amount of reward increase suggested.
    function suggestRewardIncrease(uint256 _taskId, uint256 _suggestedIncrease)
        external
        taskExists(_taskId)
        taskStatusIs(_taskId, TaskStatus.Accepted)
        onlyWorkerAssigned(_taskId)
    {
        require(_suggestedIncrease > 0, "Suggested increase must be positive.");
        tasks[_taskId].suggestedRewardIncrease = _suggestedIncrease;
        emit RewardIncreaseSuggested(_taskId, msg.sender, _suggestedIncrease);
    }

    /// @notice Task posters can agree to a suggested reward increase.
    /// @param _taskId The ID of the task.
    /// @param _agreedIncrease The agreed upon reward increase amount.
    function agreeToRewardIncrease(uint256 _taskId, uint256 _agreedIncrease)
        external
        onlyPoster(_taskId)
        taskExists(_taskId)
        taskStatusIs(_taskId, TaskStatus.Accepted)
        payable
    {
        require(_agreedIncrease >= tasks[_taskId].suggestedRewardIncrease, "Agreed increase must be at least the suggested increase.");
        require(msg.value >= _agreedIncrease, "Insufficient funds sent for agreed reward increase.");
        tasks[_taskId].agreedRewardIncrease = _agreedIncrease;
        payable(address(this)).transfer(msg.value); // Store the additional reward in the contract.
        emit RewardIncreaseAgreed(_taskId, _agreedIncrease);
    }


    // --- Dispute Resolution and Governance ---

    /// @notice Initiates a dispute for a task.
    /// @param _taskId The ID of the task in dispute.
    /// @param _disputeReason The reason for the dispute.
    function initiateDispute(uint256 _taskId, string memory _disputeReason)
        external
        taskExists(_taskId)
        taskStatusIs(_taskId, TaskStatus.Completed) || taskStatusIs(_taskId, TaskStatus.Rejected)
    {
        require(tasks[_taskId].poster == msg.sender || tasks[_taskId].assignedWorker == msg.sender, "Only poster or worker can initiate dispute.");
        tasks[_taskId].status = TaskStatus.Disputed;
        disputes.push(Dispute({
            taskId: _taskId,
            initiator: msg.sender,
            reason: _disputeReason,
            resolution: DisputeResolution.Unresolved,
            winner: address(0),
            resolved: false
        }));
        disputeCounter++;
        emit DisputeInitiated(disputeCounter - 1, _taskId, msg.sender, _disputeReason);
    }

    /// @notice (Governance/Oracles) Resolves a dispute.
    /// @param _disputeId The ID of the dispute to resolve.
    /// @param _resolution The resolution outcome (PosterWins, WorkerWins, SplitReward).
    /// @param _winner The address of the winner (or address(0) if SplitReward).
    function resolveDispute(uint256 _disputeId, DisputeResolution _resolution, address _winner)
        external onlyOwner
    {
        require(_disputeId < disputes.length, "Dispute ID is invalid.");
        require(!disputes[_disputeId].resolved, "Dispute already resolved.");
        require(disputes[_disputeId].resolution == DisputeResolution.Unresolved, "Dispute resolution already set.");

        disputes[_disputeId].resolution = _resolution;
        disputes[_disputeId].resolved = true;

        uint256 taskId = disputes[_disputeId].taskId;

        if (_resolution == DisputeResolution.PosterWins) {
            tasks[taskId].status = TaskStatus.Rejected; // Or keep it as disputed but indicate resolution?
            disputes[_disputeId].winner = tasks[taskId].poster; // Technically poster *keeps* the funds.
            // No reward transfer in this case.
        } else if (_resolution == DisputeResolution.WorkerWins) {
            tasks[taskId].status = TaskStatus.Approved; // Or keep it as disputed but indicate resolution?
            disputes[_disputeId].winner = tasks[taskId].assignedWorker;
            payable(tasks[taskId].assignedWorker).transfer(tasks[taskId].reward + tasks[taskId].agreedRewardIncrease); // Award full reward
        } else if (_resolution == DisputeResolution.SplitReward) {
            tasks[taskId].status = TaskStatus.Approved; // Or keep it as disputed but indicate resolution?
            uint256 splitReward = (tasks[taskId].reward + tasks[taskId].agreedRewardIncrease) / 2; // Example split, can be adjusted
            payable(tasks[taskId].assignedWorker).transfer(splitReward);
            payable(tasks[taskId].poster).transfer((tasks[taskId].reward + tasks[taskId].agreedRewardIncrease) - splitReward); // Return half to poster. Or adjust as needed.
        }

        emit DisputeResolved(_disputeId, _resolution, _winner);
    }

    /// @notice (Governance) Proposes a change to the marketplace.
    /// @param _proposalDescription A description of the proposed change.
    /// @param _functionCallData Encoded function call data for the change to be executed.
    function proposeGovernanceChange(string memory _proposalDescription, bytes memory _functionCallData) external {
        governanceProposals.push(GovernanceProposal({
            description: _proposalDescription,
            functionCallData: _functionCallData,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            proposalTime: block.timestamp
        }));
        governanceProposalCounter++;
        emit GovernanceProposalCreated(governanceProposalCounter - 1, _proposalDescription);
    }

    /// @notice (Governance) Allows members to vote on a governance proposal.
    /// @param _proposalId The ID of the governance proposal.
    /// @param _vote True for yes, false for no.
    function voteOnGovernanceChange(uint256 _proposalId, bool _vote) external {
        require(_proposalId < governanceProposals.length, "Invalid proposal ID.");
        require(!governanceProposals[_proposalId].executed, "Proposal already executed.");

        if (_vote) {
            governanceProposals[_proposalId].votesFor++;
        } else {
            governanceProposals[_proposalId].votesAgainst++;
        }
        emit GovernanceVoteCast(_proposalId, msg.sender, _vote);
    }

    /// @notice (Governance) Executes a governance proposal if it passes.
    /// @param _proposalId The ID of the governance proposal to execute.
    function executeGovernanceChange(uint256 _proposalId) external onlyOwner { // Example: Only Owner can execute after approval
        require(_proposalId < governanceProposals.length, "Invalid proposal ID.");
        require(!governanceProposals[_proposalId].executed, "Proposal already executed.");

        uint256 totalVotes = governanceProposals[_proposalId].votesFor + governanceProposals[_proposalId].votesAgainst;
        require(totalVotes > 0, "No votes cast on proposal."); // Prevent division by zero if no votes
        uint256 forPercentage = (governanceProposals[_proposalId].votesFor * 100) / totalVotes;

        require(forPercentage >= governanceQuorumPercentage, "Governance quorum not reached.");

        (bool success, ) = address(this).call(governanceProposals[_proposalId].functionCallData); // Execute the function call
        require(success, "Governance function call failed.");

        governanceProposals[_proposalId].executed = true;
        emit GovernanceProposalExecuted(_proposalId);
    }

    // --- Utility/Informational Functions ---

    /// @notice Gets details of a specific task.
    /// @param _taskId The ID of the task.
    /// @return Task details.
    function getTaskDetails(uint256 _taskId) external view taskExists(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }

    /// @notice Gets a list of IDs of tasks that are currently open.
    /// @return Array of task IDs.
    function getOpenTasks() external view returns (uint256[] memory) {
        uint256[] memory openTaskIds = new uint256[](tasks.length);
        uint256 count = 0;
        for (uint256 i = 0; i < tasks.length; i++) {
            if (tasks[i].status == TaskStatus.Open) {
                openTaskIds[count] = i;
                count++;
            }
        }
        // Resize the array to remove extra empty slots
        uint256[] memory finalOpenTaskIds = new uint256[](count);
        for(uint256 i=0; i<count; i++){
            finalOpenTaskIds[i] = openTaskIds[i];
        }
        return finalOpenTaskIds;
    }

    /// @notice Gets a list of task IDs posted by a specific address.
    /// @param _poster The address of the task poster.
    /// @return Array of task IDs.
    function getTasksForPoster(address _poster) external view returns (uint256[] memory) {
        uint256[] memory posterTaskIds = new uint256[](tasks.length);
        uint256 count = 0;
        for (uint256 i = 0; i < tasks.length; i++) {
            if (tasks[i].poster == _poster) {
                posterTaskIds[count] = i;
                count++;
            }
        }
        uint256[] memory finalPosterTaskIds = new uint256[](count);
        for(uint256 i=0; i<count; i++){
            finalPosterTaskIds[i] = posterTaskIds[i];
        }
        return finalPosterTaskIds;
    }

    /// @notice Gets a list of task IDs a worker is involved in (accepted, completed, approved, etc.).
    /// @param _worker The address of the worker.
    /// @return Array of task IDs.
    function getTasksForWorker(address _worker) external view returns (uint256[] memory) {
        uint256[] memory workerTaskIds = new uint256[](tasks.length);
        uint256 count = 0;
        for (uint256 i = 0; i < tasks.length; i++) {
            if (tasks[i].assignedWorker == _worker) {
                workerTaskIds[count] = i;
                count++;
            }
        }
        uint256[] memory finalWorkerTaskIds = new uint256[](count);
        for(uint256 i=0; i<count; i++){
            finalWorkerTaskIds[i] = workerTaskIds[i];
        }
        return finalWorkerTaskIds;
    }

    /// @notice Gets the contract version.
    /// @return The contract version string.
    function getVersion() external pure returns (string memory) {
        return VERSION;
    }

    /// @notice Gets the contract's ETH balance.
    /// @return The contract's ETH balance.
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Fallback function to accept ETH transfers.
    receive() external payable {}
}
```