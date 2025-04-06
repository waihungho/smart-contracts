```solidity
/**
 * @title Decentralized Skill-Based Reputation & Task Marketplace
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized platform where users can build reputation based on their skills,
 *      offer services, and request tasks. It incorporates advanced concepts like skill verification,
 *      reputation-based access control, dynamic reputation scoring, and a simple governance mechanism.
 *
 * **Outline and Function Summary:**
 *
 * **1. Membership & Profile Management:**
 *    - `joinCommunity()`: Allows users to register as members.
 *    - `leaveCommunity()`: Allows members to deregister.
 *    - `updateProfile(string _name, string _bio)`: Allows members to update their profile information.
 *    - `getUserProfile(address _user)`: Retrieves profile information of a member.
 *    - `isMember(address _user)`: Checks if an address is a registered member.
 *
 * **2. Skill Management:**
 *    - `addSkill(string _skillName)`: Allows members to add skills to their profile.
 *    - `removeSkill(string _skillName)`: Allows members to remove skills from their profile.
 *    - `verifySkill(address _user, string _skillName)`: Allows admin/reputable members to verify a user's skill.
 *    - `getSkillsForUser(address _user)`: Retrieves the list of skills for a given user.
 *    - `getAllSkills()`: Retrieves a list of all unique skills registered in the system.
 *
 * **3. Task Management:**
 *    - `createTask(string _title, string _description, string[] _requiredSkills, uint _reward)`: Allows members to create tasks.
 *    - `applyForTask(uint _taskId)`: Allows members to apply for a task.
 *    - `assignTask(uint _taskId, address _assignee)`: Allows task creator to assign a task to an applicant.
 *    - `submitTaskCompletion(uint _taskId)`: Allows assignee to submit task completion for review.
 *    - `approveTaskCompletion(uint _taskId)`: Allows task creator to approve task completion and reward the assignee.
 *    - `disputeTaskCompletion(uint _taskId, string _disputeReason)`: Allows task creator to dispute task completion.
 *    - `resolveDispute(uint _taskId, address _winner)`: Allows admin to resolve a dispute and reward the winner.
 *    - `getTaskDetails(uint _taskId)`: Retrieves details of a specific task.
 *    - `getActiveTasks()`: Retrieves a list of currently active tasks.
 *    - `getTasksCreatedByUser(address _user)`: Retrieves tasks created by a specific user.
 *    - `getTasksAssignedToUser(address _user)`: Retrieves tasks assigned to a specific user.
 *
 * **4. Reputation & Reward System:**
 *    - `earnReputation(address _user, uint _points)`: (Internal/Admin) Increases a user's reputation points.
 *    - `deductReputation(address _user, uint _points)`: (Internal/Admin) Decreases a user's reputation points.
 *    - `getReputation(address _user)`: Retrieves a user's reputation points.
 *    - `transferReputation(address _from, address _to, uint _points)`: Allows users to transfer reputation points (optional, can be enabled/disabled).
 *
 * **5. Governance & Community Management (Simple):**
 *    - `submitCommunityProposal(string _proposalDescription)`: Allows reputable members to submit community proposals.
 *    - `voteOnProposal(uint _proposalId, bool _vote)`: Allows members to vote on community proposals.
 *    - `executeProposal(uint _proposalId)`: (Admin) Executes a successful community proposal.
 *    - `setReputationThresholdForVerification(uint _threshold)`: (Admin) Sets the reputation threshold required to verify skills.
 *    - `setAdmin(address _newAdmin)`: (Admin) Changes the admin address.
 */
pragma solidity ^0.8.0;

contract SkillReputationMarketplace {

    // --- Structs ---

    struct UserProfile {
        string name;
        string bio;
        string[] skills;
        uint reputationPoints;
        bool isMember;
    }

    struct Task {
        uint id;
        address creator;
        string title;
        string description;
        string[] requiredSkills;
        uint reward;
        address assignee;
        bool isActive;
        bool isCompleted;
        bool isDisputed;
        string disputeReason;
        uint creationTimestamp;
    }

    struct Proposal {
        uint id;
        string description;
        address proposer;
        uint voteCount;
        bool isExecuted;
        uint creationTimestamp;
    }

    // --- State Variables ---

    address public admin;
    uint public reputationThresholdForVerification = 100; // Reputation needed to verify skills
    uint public nextTaskId = 1;
    uint public nextProposalId = 1;

    mapping(address => UserProfile) public userProfiles;
    mapping(uint => Task) public tasks;
    mapping(uint => Proposal) public proposals;
    mapping(string => bool) public registeredSkills; // List of all unique skills
    mapping(address => mapping(string => bool)) public skillVerifications; // User -> Skill -> Verified Status
    mapping(uint => address[]) public taskApplicants; // Task ID -> List of applicant addresses

    address[] public members; // List of all member addresses

    // --- Events ---

    event MembershipJoined(address indexed user);
    event MembershipLeft(address indexed user);
    event ProfileUpdated(address indexed user);
    event SkillAdded(address indexed user, string skillName);
    event SkillRemoved(address indexed user, string skillName);
    event SkillVerified(address indexed verifier, address indexed user, string skillName);
    event TaskCreated(uint taskId, address indexed creator, string title);
    event TaskApplied(uint taskId, address indexed applicant);
    event TaskAssigned(uint taskId, address indexed assignee);
    event TaskCompletionSubmitted(uint taskId, address indexed assignee);
    event TaskCompletionApproved(uint taskId, address indexed assignee, address indexed creator, uint reward);
    event TaskDisputed(uint taskId, address indexed disputer, string reason);
    event DisputeResolved(uint taskId, address indexed winner);
    event ReputationEarned(address indexed user, uint points);
    event ReputationDeducted(address indexed user, uint points);
    event ReputationTransferred(address indexed from, address indexed to, uint points);
    event CommunityProposalSubmitted(uint proposalId, address indexed proposer, string description);
    event ProposalVoted(uint proposalId, address indexed voter, bool vote);
    event ProposalExecuted(uint proposalId);
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);
    event ReputationThresholdUpdated(uint newThreshold);

    // --- Modifiers ---

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier onlyMember() {
        require(userProfiles[msg.sender].isMember, "Only members can call this function.");
        _;
    }

    modifier taskExists(uint _taskId) {
        require(tasks[_taskId].id != 0, "Task does not exist.");
        _;
    }

    modifier taskActive(uint _taskId) {
        require(tasks[_taskId].isActive, "Task is not active.");
        _;
    }

    modifier taskNotCompleted(uint _taskId) {
        require(!tasks[_taskId].isCompleted, "Task is already completed.");
        _;
    }

    modifier taskNotDisputed(uint _taskId) {
        require(!tasks[_taskId].isDisputed, "Task is already disputed.");
        _;
    }

    modifier taskCreator(uint _taskId) {
        require(tasks[_taskId].creator == msg.sender, "Only task creator can call this function.");
        _;
    }

    modifier taskAssignee(uint _taskId) {
        require(tasks[_taskId].assignee == msg.sender, "Only task assignee can call this function.");
        _;
    }

    modifier reputationAboveThreshold(address _user, uint _threshold) {
        require(userProfiles[_user].reputationPoints >= _threshold, "Insufficient reputation.");
        _;
    }

    // --- Constructor ---

    constructor() {
        admin = msg.sender;
    }

    // --- 1. Membership & Profile Management ---

    function joinCommunity() public {
        require(!userProfiles[msg.sender].isMember, "Already a member.");
        userProfiles[msg.sender].isMember = true;
        userProfiles[msg.sender].reputationPoints = 0; // Start with 0 reputation
        members.push(msg.sender);
        emit MembershipJoined(msg.sender);
    }

    function leaveCommunity() public onlyMember {
        userProfiles[msg.sender].isMember = false;
        // Remove from members array (optional, for iteration efficiency, can be skipped for simplicity)
        for (uint i = 0; i < members.length; i++) {
            if (members[i] == msg.sender) {
                members[i] = members[members.length - 1];
                members.pop();
                break;
            }
        }
        emit MembershipLeft(msg.sender);
    }

    function updateProfile(string memory _name, string memory _bio) public onlyMember {
        userProfiles[msg.sender].name = _name;
        userProfiles[msg.sender].bio = _bio;
        emit ProfileUpdated(msg.sender);
    }

    function getUserProfile(address _user) public view returns (UserProfile memory) {
        return userProfiles[_user];
    }

    function isMember(address _user) public view returns (bool) {
        return userProfiles[_user].isMember;
    }

    // --- 2. Skill Management ---

    function addSkill(string memory _skillName) public onlyMember {
        require(!registeredSkills[_skillName], "Skill already registered in system.");
        bool skillExists = false;
        for(uint i=0; i < userProfiles[msg.sender].skills.length; i++){
            if(keccak256(abi.encodePacked(userProfiles[msg.sender].skills[i])) == keccak256(abi.encodePacked(_skillName))){
                skillExists = true;
                break;
            }
        }
        require(!skillExists, "Skill already added to your profile.");

        userProfiles[msg.sender].skills.push(_skillName);
        registeredSkills[_skillName] = true;
        emit SkillAdded(msg.sender, _skillName);
    }

    function removeSkill(string memory _skillName) public onlyMember {
        bool skillRemoved = false;
        for (uint i = 0; i < userProfiles[msg.sender].skills.length; i++) {
            if (keccak256(abi.encodePacked(userProfiles[msg.sender].skills[i])) == keccak256(abi.encodePacked(_skillName))) {
                userProfiles[msg.sender].skills[i] = userProfiles[msg.sender].skills[userProfiles[msg.sender].skills.length - 1];
                userProfiles[msg.sender].skills.pop();
                skillRemoved = true;
                break;
            }
        }
        require(skillRemoved, "Skill not found in your profile.");
        emit SkillRemoved(msg.sender, _skillName);
    }

    function verifySkill(address _user, string memory _skillName) public onlyMember reputationAboveThreshold(msg.sender, reputationThresholdForVerification) {
        require(userProfiles[_user].isMember, "User is not a member.");
        bool hasSkill = false;
        for(uint i=0; i < userProfiles[_user].skills.length; i++){
            if(keccak256(abi.encodePacked(userProfiles[_user].skills[i])) == keccak256(abi.encodePacked(_skillName))){
                hasSkill = true;
                break;
            }
        }
        require(hasSkill, "User does not have this skill listed.");
        require(!skillVerifications[_user][_skillName], "Skill already verified for this user.");

        skillVerifications[_user][_skillName] = true;
        earnReputation(_user, 5); // Reward user for skill verification
        emit SkillVerified(msg.sender, _user, _skillName);
    }

    function getSkillsForUser(address _user) public view returns (string[] memory) {
        return userProfiles[_user].skills;
    }

    function getAllSkills() public view returns (string[] memory) {
        string[] memory skillsArray = new string[](0);
        uint index = 0;
        for (string memory skillName : registeredSkills) {
            if(registeredSkills[skillName]){ // Solidity mappings might iterate over deleted keys, this ensures we only include active ones
                string[] memory tempArray = new string[](skillsArray.length + 1);
                for(uint i=0; i < skillsArray.length; i++){
                    tempArray[i] = skillsArray[i];
                }
                tempArray[skillsArray.length] = skillName;
                skillsArray = tempArray;
            }
        }
        return skillsArray;
    }


    // --- 3. Task Management ---

    function createTask(string memory _title, string memory _description, string[] memory _requiredSkills, uint _reward) public onlyMember {
        require(_reward > 0, "Reward must be greater than 0.");
        Task storage newTask = tasks[nextTaskId];
        newTask.id = nextTaskId;
        newTask.creator = msg.sender;
        newTask.title = _title;
        newTask.description = _description;
        newTask.requiredSkills = _requiredSkills;
        newTask.reward = _reward;
        newTask.isActive = true;
        newTask.creationTimestamp = block.timestamp;
        nextTaskId++;
        emit TaskCreated(newTask.id, msg.sender, _title);
    }

    function applyForTask(uint _taskId) public onlyMember taskExists(_taskId) taskActive(_taskId) taskNotCompleted(_taskId) taskNotDisputed(_taskId) {
        Task storage task = tasks[_taskId];
        bool hasRequiredSkills = true;
        for (uint i = 0; i < task.requiredSkills.length; i++) {
            bool skillFound = false;
            for (uint j = 0; j < userProfiles[msg.sender].skills.length; j++) {
                if (keccak256(abi.encodePacked(userProfiles[msg.sender].skills[j])) == keccak256(abi.encodePacked(task.requiredSkills[i]))) {
                    skillFound = true;
                    break;
                }
            }
            if (!skillFound) {
                hasRequiredSkills = false;
                break;
            }
        }
        require(hasRequiredSkills, "You do not have all the required skills for this task.");
        bool alreadyApplied = false;
        for(uint i=0; i < taskApplicants[_taskId].length; i++){
            if(taskApplicants[_taskId][i] == msg.sender){
                alreadyApplied = true;
                break;
            }
        }
        require(!alreadyApplied, "You have already applied for this task.");

        taskApplicants[_taskId].push(msg.sender);
        emit TaskApplied(_taskId, msg.sender);
    }

    function assignTask(uint _taskId, address _assignee) public onlyMember taskExists(_taskId) taskActive(_taskId) taskNotCompleted(_taskId) taskNotDisputed(_taskId) taskCreator(_taskId) {
        require(userProfiles[_assignee].isMember, "Assignee is not a member.");
        bool isApplicant = false;
        for(uint i=0; i < taskApplicants[_taskId].length; i++){
            if(taskApplicants[_taskId][i] == _assignee){
                isApplicant = true;
                break;
            }
        }
        require(isApplicant, "Assignee has not applied for this task.");

        tasks[_taskId].assignee = _assignee;
        tasks[_taskId].isActive = false; // Task becomes inactive once assigned
        emit TaskAssigned(_taskId, _assignee);
    }

    function submitTaskCompletion(uint _taskId) public onlyMember taskExists(_taskId) taskNotCompleted(_taskId) taskNotDisputed(_taskId) taskAssignee(_taskId) {
        tasks[_taskId].isCompleted = true;
        emit TaskCompletionSubmitted(_taskId, msg.sender);
    }

    function approveTaskCompletion(uint _taskId) public onlyMember taskExists(_taskId) taskNotDisputed(_taskId) taskCreator(_taskId) taskNotActive(_taskId) { // Task inactive after assigned
        require(tasks[_taskId].assignee != address(0), "Task has not been assigned yet.");
        require(tasks[_taskId].isCompleted, "Task completion has not been submitted.");

        address assignee = tasks[_taskId].assignee;
        uint reward = tasks[_taskId].reward;

        // In a real application, you would transfer actual tokens/currency here.
        // For this example, we'll just increase reputation as a reward.
        earnReputation(assignee, reward);
        emit TaskCompletionApproved(_taskId, assignee, msg.sender, reward);
    }

    function disputeTaskCompletion(uint _taskId, string memory _disputeReason) public onlyMember taskExists(_taskId) taskNotCompleted(_taskId) taskNotDisputed(_taskId) taskCreator(_taskId) taskNotActive(_taskId) { // Task inactive after assigned
        require(tasks[_taskId].assignee != address(0), "Task has not been assigned yet.");
        require(tasks[_taskId].isCompleted, "Task completion has not been submitted.");
        tasks[_taskId].isDisputed = true;
        tasks[_taskId].disputeReason = _disputeReason;
        emit TaskDisputed(_taskId, msg.sender, _disputeReason);
    }

    function resolveDispute(uint _taskId, address _winner) public onlyAdmin taskExists(_taskId) taskNotCompleted(_taskId) taskDisputed(_taskId) {
        require(_winner == tasks[_taskId].creator || _winner == tasks[_taskId].assignee, "Winner must be either creator or assignee.");

        if (_winner == tasks[_taskId].assignee) {
            approveTaskCompletion(_taskId); // Reward assignee if they win
        } else {
            // Optionally, deduct reputation from assignee if creator wins (punishment for poor work, can be debated)
            if(tasks[_taskId].assignee != address(0)){
                deductReputation(tasks[_taskId].assignee, tasks[_taskId].reward / 2); // Example: Deduct half of the reward
            }
        }
        tasks[_taskId].isDisputed = false;
        emit DisputeResolved(_taskId, _winner);
    }

    function getTaskDetails(uint _taskId) public view taskExists(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }

    function getActiveTasks() public view returns (Task[] memory) {
        Task[] memory activeTaskList = new Task[](0);
        for (uint i = 1; i < nextTaskId; i++) {
            if (tasks[i].isActive) {
                Task[] memory tempTaskList = new Task[](activeTaskList.length + 1);
                for(uint j=0; j < activeTaskList.length; j++){
                    tempTaskList[j] = activeTaskList[j];
                }
                tempTaskList[activeTaskList.length] = tasks[i];
                activeTaskList = tempTaskList;
            }
        }
        return activeTaskList;
    }

    function getTasksCreatedByUser(address _user) public view onlyMember returns (Task[] memory) {
        Task[] memory userTaskList = new Task[](0);
        for (uint i = 1; i < nextTaskId; i++) {
            if (tasks[i].creator == _user) {
                Task[] memory tempTaskList = new Task[](userTaskList.length + 1);
                for(uint j=0; j < userTaskList.length; j++){
                    tempTaskList[j] = userTaskList[j];
                }
                tempTaskList[userTaskList.length] = tasks[i];
                userTaskList = tempTaskList;
            }
        }
        return userTaskList;
    }

    function getTasksAssignedToUser(address _user) public view onlyMember returns (Task[] memory) {
        Task[] memory assignedTaskList = new Task[](0);
        for (uint i = 1; i < nextTaskId; i++) {
            if (tasks[i].assignee == _user) {
                Task[] memory tempTaskList = new Task[](assignedTaskList.length + 1);
                for(uint j=0; j < assignedTaskList.length; j++){
                    tempTaskList[j] = assignedTaskList[j];
                }
                tempTaskList[assignedTaskList.length] = tasks[i];
                assignedTaskList = tempTaskList;
            }
        }
        return assignedTaskList;
    }


    // --- 4. Reputation & Reward System ---

    function earnReputation(address _user, uint _points) internal { // Internal function, admin or contract itself should call it
        userProfiles[_user].reputationPoints += _points;
        emit ReputationEarned(_user, _points);
    }

    function deductReputation(address _user, uint _points) internal { // Internal function, admin or contract itself should call it
        if (userProfiles[_user].reputationPoints >= _points) {
            userProfiles[_user].reputationPoints -= _points;
            emit ReputationDeducted(_user, _points);
        } else {
            userProfiles[_user].reputationPoints = 0; // Prevent negative reputation
            emit ReputationDeducted(_user, _points); // Event still emitted even if reputation goes to 0
        }
    }

    function getReputation(address _user) public view returns (uint) {
        return userProfiles[_user].reputationPoints;
    }

    function transferReputation(address _from, address _to, uint _points) public onlyMember {
        require(_from == msg.sender, "You can only transfer your own reputation.");
        require(userProfiles[_to].isMember, "Recipient is not a member.");
        require(userProfiles[_from].reputationPoints >= _points, "Insufficient reputation to transfer.");

        userProfiles[_from].reputationPoints -= _points;
        userProfiles[_to].reputationPoints += _points;
        emit ReputationTransferred(_from, _to, _points);
    }

    // --- 5. Governance & Community Management (Simple) ---

    function submitCommunityProposal(string memory _proposalDescription) public onlyMember reputationAboveThreshold(msg.sender, reputationThresholdForVerification * 2) { // Higher reputation to propose
        Proposal storage newProposal = proposals[nextProposalId];
        newProposal.id = nextProposalId;
        newProposal.description = _proposalDescription;
        newProposal.proposer = msg.sender;
        newProposal.creationTimestamp = block.timestamp;
        nextProposalId++;
        emit CommunityProposalSubmitted(newProposal.id, msg.sender, _proposalDescription);
    }

    function voteOnProposal(uint _proposalId, bool _vote) public onlyMember taskExists(_proposalId) { // Reusing taskExists modifier for proposalId check (could create a proposalExists modifier)
        require(!proposals[_proposalId].isExecuted, "Proposal already executed.");
        // Simple voting - just count 'yes' votes.  For a real DAO, you'd need more robust voting mechanisms.
        if (_vote) {
            proposals[_proposalId].voteCount++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _vote);
    }

    function executeProposal(uint _proposalId) public onlyAdmin taskExists(_proposalId) { // Reusing taskExists modifier for proposalId check
        require(!proposals[_proposalId].isExecuted, "Proposal already executed.");
        // Very basic execution - for demonstration. Real governance would have more complex logic and checks.
        if (proposals[_proposalId].voteCount > (members.length / 2)) { // Simple majority vote
            proposals[_proposalId].isExecuted = true;
            // Add logic to execute the proposal based on its description.
            // Example: if proposal is to change reputation threshold:
            if (keccak256(abi.encodePacked(proposals[_proposalId].description)) == keccak256(abi.encodePacked("Increase verification threshold to 200"))) { // Example - very basic string matching!
                setReputationThresholdForVerification(200);
            }
            emit ProposalExecuted(_proposalId);
        } else {
            revert("Proposal failed to pass."); // Or just emit an event "ProposalFailed"
        }
    }

    // --- Admin Functions ---

    function setReputationThresholdForVerification(uint _threshold) public onlyAdmin {
        reputationThresholdForVerification = _threshold;
        emit ReputationThresholdUpdated(_threshold);
    }

    function setAdmin(address _newAdmin) public onlyAdmin {
        require(_newAdmin != address(0), "Invalid admin address.");
        emit AdminChanged(admin, _newAdmin);
        admin = _newAdmin;
    }

    // --- Fallback and Receive (Optional for this contract, but good practice to consider) ---
    // receive() external payable {}
    // fallback() external payable {}
}
```