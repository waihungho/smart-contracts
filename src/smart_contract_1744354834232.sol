```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Task Marketplace with Skill-Based Reputation
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized marketplace where users can offer and complete tasks.
 *      It features dynamic task assignment based on member skills, a skill-based reputation system,
 *      and various governance mechanisms. This contract aims to be a creative and advanced example
 *      of a decentralized application, avoiding duplication of common open-source contracts.
 *
 * **Outline:**
 *
 * **I. Contract Metadata and Basic Functions:**
 *    1. contractName() - Returns the name of the contract.
 *    2. contractVersion() - Returns the version of the contract.
 *    3. contractOwner() - Returns the address of the contract owner.
 *    4. getContractBalance() - Returns the contract's Ether balance.
 *    5. pauseContract() - Pauses the contract functionality (owner only).
 *    6. unpauseContract() - Resumes contract functionality (owner only).
 *    7. isContractPaused() - Checks if the contract is paused.
 *
 * **II. Member Management and Skills:**
 *    8. joinMarketplace(string[] memory _skills) - Allows users to join the marketplace with specified skills.
 *    9. leaveMarketplace() - Allows members to leave the marketplace.
 *    10. updateSkills(string[] memory _newSkills) - Allows members to update their skills.
 *    11. getMemberSkills(address _member) - Returns the skills of a marketplace member.
 *    12. getAllSkills() - Returns a list of all unique skills registered in the marketplace.
 *    13. isMember(address _user) - Checks if an address is a marketplace member.
 *    14. getMemberCount() - Returns the total number of marketplace members.
 *
 * **III. Task Management and Assignment:**
 *    15. createTask(string memory _title, string memory _description, uint256 _reward, string[] memory _requiredSkills) - Creates a new task with reward and skill requirements.
 *    16. applyForTask(uint256 _taskId) - Allows members to apply for a task.
 *    17. assignTask(uint256 _taskId, address _member) - Assigns a task to a specific member (owner or designated task assigner).
 *    18. submitTaskCompletion(uint256 _taskId, string memory _proofOfWork) - Allows assigned members to submit proof of task completion.
 *    19. reviewTaskCompletion(uint256 _taskId, bool _taskApproved) - Reviews submitted task completion and approves or rejects it (task assigner/owner).
 *    20. getTaskDetails(uint256 _taskId) - Returns details of a specific task.
 *    21. getTasksByStatus(TaskStatus _status) - Returns a list of task IDs based on their status.
 *    22. getTasksAssignedToMember(address _member) - Returns a list of task IDs assigned to a specific member.
 *
 * **IV. Reputation and Incentive System:**
 *    23. awardReputation(address _member, uint256 _reputationPoints) - Awards reputation points to a member (owner/task reviewer).
 *    24. deductReputation(address _member, uint256 _reputationPoints) - Deducts reputation points from a member (owner/task reviewer).
 *    25. getMemberReputation(address _member) - Returns the reputation points of a member.
 *    26. redeemReputationForBonus(uint256 _reputationPointsToRedeem) - Allows members to redeem reputation points for a bonus (example: small ETH reward).
 *
 * **V. Governance and Settings:**
 *    27. setTaskAssigner(address _taskAssigner) - Sets an address authorized to assign tasks (owner only).
 *    28. getTaskAssigner() - Returns the address of the current task assigner.
 *    29. setReputationThresholdForBonus(uint256 _threshold) - Sets the reputation threshold required to redeem bonuses (owner only).
 *    30. getReputationThresholdForBonus() - Returns the current reputation threshold for bonuses.
 *
 * **Events:**
 *    - MemberJoined(address member, string[] skills)
 *    - MemberLeft(address member)
 *    - SkillsUpdated(address member, string[] newSkills)
 *    - TaskCreated(uint256 taskId, string title, address creator, uint256 reward, string[] requiredSkills)
 *    - TaskApplied(uint256 taskId, address applicant)
 *    - TaskAssigned(uint256 taskId, address assignee)
 *    - TaskCompletionSubmitted(uint256 taskId, address submitter, string proofOfWork)
 *    - TaskApproved(uint256 taskId, address reviewer, address assignee)
 *    - TaskRejected(uint256 taskId, address reviewer, address assignee)
 *    - ReputationAwarded(address member, uint256 reputationPoints, string reason)
 *    - ReputationDeducted(address member, uint256 reputationPoints, string reason)
 *    - BonusRedeemed(address member, uint256 reputationPointsRedeemed, uint256 bonusAmount)
 *    - ContractPaused()
 *    - ContractUnpaused()
 *    - TaskAssignerSet(address newTaskAssigner, address setter)
 *    - ReputationThresholdSet(uint256 newThreshold, address setter)
 */
contract DynamicTaskMarketplace {
    string public contractName = "DynamicTaskMarketplace";
    string public contractVersion = "1.0";
    address public contractOwner;
    address public taskAssigner;
    bool public paused = false;
    uint256 public reputationThresholdForBonus = 100; // Default threshold for bonus redemption

    uint256 public taskCounter = 0;
    mapping(address => Member) public members;
    mapping(uint256 => Task) public tasks;
    mapping(address => uint256) public memberReputation;
    mapping(string => bool) public availableSkills; // Track unique skills
    address[] public memberList;

    enum TaskStatus { Open, Applied, Assigned, Completed, Reviewed, Rejected }

    struct Member {
        address memberAddress;
        string[] skills;
        bool isActive;
    }

    struct Task {
        uint256 taskId;
        string title;
        string description;
        address creator;
        uint256 reward;
        string[] requiredSkills;
        TaskStatus status;
        address assignee;
        string proofOfWork;
    }

    // Events
    event MemberJoined(address member, string[] skills);
    event MemberLeft(address member);
    event SkillsUpdated(address member, string[] newSkills);
    event TaskCreated(uint256 taskId, string title, address creator, uint256 reward, string[] requiredSkills);
    event TaskApplied(uint256 taskId, address applicant);
    event TaskAssigned(uint256 taskId, address assignee);
    event TaskCompletionSubmitted(uint256 taskId, address submitter, string proofOfWork);
    event TaskApproved(uint256 taskId, address reviewer, address assignee);
    event TaskRejected(uint256 taskId, address reviewer, address assignee);
    event ReputationAwarded(address member, uint256 reputationPoints, string reason);
    event ReputationDeducted(address member, uint256 reputationPoints, string reason);
    event BonusRedeemed(address member, uint256 reputationPointsRedeemed, uint256 bonusAmount);
    event ContractPaused();
    event ContractUnpaused();
    event TaskAssignerSet(address newTaskAssigner, address setter);
    event ReputationThresholdSet(uint256 newThreshold, address setter);

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only owner can call this function.");
        _;
    }

    modifier onlyTaskAssignerOrOwner() {
        require(msg.sender == taskAssigner || msg.sender == contractOwner, "Only task assigner or owner can call this function.");
        _;
    }

    modifier onlyMembers() {
        require(isMember(msg.sender), "Only marketplace members can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused.");
        _;
    }

    constructor() {
        contractOwner = msg.sender;
        taskAssigner = msg.sender; // Initially, owner is also the task assigner.
    }

    // --- I. Contract Metadata and Basic Functions ---

    function contractName() public view returns (string memory) {
        return contractName;
    }

    function contractVersion() public view returns (string memory) {
        return contractVersion;
    }

    function contractOwner() public view returns (address) {
        return contractOwner;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    function unpauseContract() public onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    function isContractPaused() public view returns (bool) {
        return paused;
    }

    // --- II. Member Management and Skills ---

    function joinMarketplace(string[] memory _skills) public whenNotPaused {
        require(!isMember(msg.sender), "Already a marketplace member.");
        members[msg.sender] = Member({
            memberAddress: msg.sender,
            skills: _skills,
            isActive: true
        });
        memberList.push(msg.sender);
        for (uint i = 0; i < _skills.length; i++) {
            availableSkills[_skills[i]] = true;
        }
        emit MemberJoined(msg.sender, _skills);
    }

    function leaveMarketplace() public onlyMembers whenNotPaused {
        require(members[msg.sender].isActive, "Not an active member.");
        members[msg.sender].isActive = false;
        // Option to remove from memberList for optimization if needed, but can be skipped for simplicity
        emit MemberLeft(msg.sender);
    }

    function updateSkills(string[] memory _newSkills) public onlyMembers whenNotPaused {
        require(members[msg.sender].isActive, "Member is not active.");
        members[msg.sender].skills = _newSkills;
        for (uint i = 0; i < _newSkills.length; i++) {
            availableSkills[_newSkills[i]] = true; // Ensure new skills are tracked
        }
        emit SkillsUpdated(msg.sender, _newSkills);
    }

    function getMemberSkills(address _member) public view returns (string[] memory) {
        require(isMember(_member), "Address is not a marketplace member.");
        return members[_member].skills;
    }

    function getAllSkills() public view returns (string[] memory) {
        string[] memory skillsArray = new string[](0);
        uint256 index = 0;
        for (bytes32 skillHash in availableSkills) {
            if (availableSkills[string(skillHash)]) {
                string memory skill = string(skillHash);
                skillsArray = _arrayPush(skillsArray, skill);
                index++;
            }
        }
        return skillsArray;
    }

    function _arrayPush(string[] memory _array, string memory _value) private pure returns (string[] memory) {
        string[] memory newArray = new string[](_array.length + 1);
        for (uint256 i = 0; i < _array.length; i++) {
            newArray[i] = _array[i];
        }
        newArray[_array.length] = _value;
        return newArray;
    }


    function isMember(address _user) public view returns (bool) {
        return members[_user].isActive;
    }

    function getMemberCount() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < memberList.length; i++) {
            if (members[memberList[i]].isActive) {
                count++;
            }
        }
        return count;
    }

    // --- III. Task Management and Assignment ---

    function createTask(
        string memory _title,
        string memory _description,
        uint256 _reward,
        string[] memory _requiredSkills
    ) public onlyMembers whenNotPaused {
        taskCounter++;
        tasks[taskCounter] = Task({
            taskId: taskCounter,
            title: _title,
            description: _description,
            creator: msg.sender,
            reward: _reward,
            requiredSkills: _requiredSkills,
            status: TaskStatus.Open,
            assignee: address(0),
            proofOfWork: ""
        });
        emit TaskCreated(taskCounter, _title, msg.sender, _reward, _requiredSkills);
    }

    function applyForTask(uint256 _taskId) public onlyMembers whenNotPaused {
        require(tasks[_taskId].status == TaskStatus.Open, "Task is not open for application.");
        tasks[_taskId].status = TaskStatus.Applied; // Simple application, can be improved with application list if needed
        emit TaskApplied(_taskId, msg.sender);
    }

    function assignTask(uint256 _taskId, address _member) public onlyTaskAssignerOrOwner whenNotPaused {
        require(tasks[_taskId].status == TaskStatus.Applied || tasks[_taskId].status == TaskStatus.Open, "Task is not in an applicable status for assignment.");
        require(isMember(_member), "Target address is not a marketplace member.");
        // Optional: Add skill matching logic here before assignment
        tasks[_taskId].status = TaskStatus.Assigned;
        tasks[_taskId].assignee = _member;
        emit TaskAssigned(_taskId, _member);
    }

    function submitTaskCompletion(uint256 _taskId, string memory _proofOfWork) public onlyMembers whenNotPaused {
        require(tasks[_taskId].status == TaskStatus.Assigned, "Task is not assigned to you or not in assigned status.");
        require(tasks[_taskId].assignee == msg.sender, "Task is not assigned to you.");
        tasks[_taskId].status = TaskStatus.Completed;
        tasks[_taskId].proofOfWork = _proofOfWork;
        emit TaskCompletionSubmitted(_taskId, msg.sender, _proofOfWork);
    }

    function reviewTaskCompletion(uint256 _taskId, bool _taskApproved) public onlyTaskAssignerOrOwner whenNotPaused {
        require(tasks[_taskId].status == TaskStatus.Completed, "Task is not in completed status.");
        require(tasks[_taskId].assignee != address(0), "Task has no assignee.");
        if (_taskApproved) {
            tasks[_taskId].status = TaskStatus.Reviewed;
            payable(tasks[_taskId].assignee).transfer(tasks[_taskId].reward);
            emit TaskApproved(_taskId, msg.sender, tasks[_taskId].assignee);
            awardReputation(tasks[_taskId].assignee, 10, "Task Completion Bonus"); // Example reputation reward
        } else {
            tasks[_taskId].status = TaskStatus.Rejected;
            emit TaskRejected(_taskId, msg.sender, tasks[_taskId].assignee);
            deductReputation(tasks[_taskId].assignee, 5, "Task Rejection Penalty"); // Example reputation penalty
        }
    }

    function getTaskDetails(uint256 _taskId) public view returns (Task memory) {
        require(tasks[_taskId].taskId == _taskId, "Invalid Task ID."); // Basic validation
        return tasks[_taskId];
    }

    function getTasksByStatus(TaskStatus _status) public view returns (uint256[] memory) {
        uint256[] memory taskIds = new uint256[](0);
        for (uint256 i = 1; i <= taskCounter; i++) {
            if (tasks[i].taskId == i && tasks[i].status == _status) {
                taskIds = _arrayPushUint(taskIds, i);
            }
        }
        return taskIds;
    }

    function getTasksAssignedToMember(address _member) public view returns (uint256[] memory) {
        require(isMember(_member), "Address is not a marketplace member.");
        uint256[] memory taskIds = new uint256[](0);
        for (uint256 i = 1; i <= taskCounter; i++) {
            if (tasks[i].taskId == i && tasks[i].assignee == _member) {
                taskIds = _arrayPushUint(taskIds, i);
            }
        }
        return taskIds;
    }

    function _arrayPushUint(uint256[] memory _array, uint256 _value) private pure returns (uint256[] memory) {
        uint256[] memory newArray = new uint256[](_array.length + 1);
        for (uint256 i = 0; i < _array.length; i++) {
            newArray[i] = _array[i];
        }
        newArray[_array.length] = _value;
        return newArray;
    }


    // --- IV. Reputation and Incentive System ---

    function awardReputation(address _member, uint256 _reputationPoints, string memory _reason) public onlyTaskAssignerOrOwner whenNotPaused {
        require(isMember(_member), "Address is not a marketplace member.");
        memberReputation[_member] += _reputationPoints;
        emit ReputationAwarded(_member, _reputationPoints, _reason);
    }

    function deductReputation(address _member, uint256 _reputationPoints, string memory _reason) public onlyTaskAssignerOrOwner whenNotPaused {
        require(isMember(_member), "Address is not a marketplace member.");
        // Prevent reputation from going negative (optional, can be removed if negative rep is desired)
        if (memberReputation[_member] >= _reputationPoints) {
            memberReputation[_member] -= _reputationPoints;
        } else {
            memberReputation[_member] = 0; // Set to 0 if deduction exceeds current reputation
        }
        emit ReputationDeducted(_member, _reputationPoints, _reason);
    }

    function getMemberReputation(address _member) public view returns (uint256) {
        require(isMember(_member), "Address is not a marketplace member.");
        return memberReputation[_member];
    }

    function redeemReputationForBonus(uint256 _reputationPointsToRedeem) public onlyMembers whenNotPaused payable {
        require(memberReputation[msg.sender] >= _reputationPointsToRedeem, "Not enough reputation points to redeem.");
        require(_reputationPointsToRedeem >= reputationThresholdForBonus, "Reputation points must meet redemption threshold.");
        uint256 bonusAmount = _reputationPointsToRedeem / 100; // Example bonus calculation: 1 ETH for every 100 rep points
        require(address(this).balance >= bonusAmount, "Contract balance too low for bonus.");

        memberReputation[msg.sender] -= _reputationPointsToRedeem;
        payable(msg.sender).transfer(bonusAmount);
        emit BonusRedeemed(msg.sender, _reputationPointsToRedeem, bonusAmount);
    }

    // --- V. Governance and Settings ---

    function setTaskAssigner(address _taskAssigner) public onlyOwner whenNotPaused {
        require(_taskAssigner != address(0), "Invalid task assigner address.");
        taskAssigner = _taskAssigner;
        emit TaskAssignerSet(_taskAssigner, msg.sender);
    }

    function getTaskAssigner() public view returns (address) {
        return taskAssigner;
    }

    function setReputationThresholdForBonus(uint256 _threshold) public onlyOwner whenNotPaused {
        reputationThresholdForBonus = _threshold;
        emit ReputationThresholdSet(_threshold, msg.sender);
    }

    function getReputationThresholdForBonus() public view returns (uint256) {
        return reputationThresholdForBonus;
    }

    // Fallback function to receive Ether for task rewards and bonuses
    receive() external payable {}
}
```