```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 *  Smart Contract Outline and Function Summary: Decentralized Skill-Based Reputation & Task Marketplace
 *
 *  Contract Name: SkillDAO
 *
 *  Description:
 *  This smart contract implements a decentralized platform for skill-based reputation and task marketplace.
 *  It allows users to create profiles showcasing their skills, earn reputation through contributions,
 *  and participate in a decentralized task marketplace where reputation plays a role in task assignment
 *  and rewards.  The contract aims to foster a transparent and meritocratic system for skill validation
 *  and collaborative work within a decentralized community.
 *
 *  Function Summary:
 *
 *  Profile Management:
 *    1. createProfile(string _name, string _description, string[] _skills): Allows users to create profiles with name, description, and skills.
 *    2. updateProfile(string _name, string _description, string[] _skills): Allows users to update their profile information.
 *    3. getProfile(address _user): Retrieves profile details for a given user address.
 *    4. isProfileExists(address _user): Checks if a profile exists for a given user.
 *    5. addSkillToProfile(address _user, string _skill): Adds a skill to a user's profile.
 *    6. removeSkillFromProfile(address _user, string _skill): Removes a skill from a user's profile.
 *
 *  Skill Management & Validation:
 *    7. addSkill(string _skillName):  Admin function to add a new skill to the allowed skill list.
 *    8. removeSkill(string _skillName): Admin function to remove a skill from the allowed skill list.
 *    9. isSkillValid(string _skillName): Checks if a skill is in the allowed skill list.
 *    10. getSkillList(): Returns the list of all valid skills.
 *
 *  Reputation System:
 *    11. recordContribution(address _user, string _skill, string _contributionDescription): Allows users to record a contribution related to a skill.
 *    12. getContributionDetails(uint _contributionId): Retrieves details of a specific contribution.
 *    13. voteOnContribution(uint _contributionId, bool _upvote): Allows users to upvote or downvote a contribution to influence reputation.
 *    14. getReputation(address _user): Retrieves the reputation score of a user.
 *    15. setReputationThreshold(uint _threshold): Admin function to set the reputation threshold for certain actions (e.g., task posting).
 *
 *  Task Marketplace:
 *    16. postTask(string _taskDescription, string _requiredSkill, uint _reward): Allows users with sufficient reputation to post tasks.
 *    17. bidOnTask(uint _taskId, string _bidDescription): Allows users to bid on open tasks.
 *    18. acceptBid(uint _taskId, address _bidder): Allows task poster to accept a bid and assign the task.
 *    19. completeTask(uint _taskId): Allows task assignee to mark a task as completed.
 *    20. submitReview(uint _taskId, string _reviewText, uint _rating): Allows task poster to submit a review and rating after task completion.
 *    21. getTaskDetails(uint _taskId): Retrieves details of a specific task.
 *    22. getOpenTasks(): Returns a list of IDs of currently open tasks.
 *    23. getTasksByUser(address _user): Returns a list of task IDs related to a user (posted or assigned).
 *
 *  Admin & Utility Functions:
 *    24. addAdmin(address _newAdmin): Allows the contract owner to add new admin addresses.
 *    25. removeAdmin(address _adminToRemove): Allows the contract owner to remove admin addresses.
 *    26. isAdmin(address _user): Checks if an address is an admin.
 *    27. renounceAdmin(): Allows an admin to renounce their admin role.
 *    28. setVotingDuration(uint _durationInBlocks): Admin function to set the voting duration for contributions.
 *    29. getContractBalance(): Returns the contract's ETH balance (for potential future reward distribution).
 *
 *  Events:
 *    - ProfileCreated(address user, string name)
 *    - ProfileUpdated(address user)
 *    - SkillAddedToProfile(address user, string skill)
 *    - SkillRemovedFromProfile(address user, string skill)
 *    - SkillAdded(string skillName)
 *    - SkillRemoved(string skillName)
 *    - ContributionRecorded(uint contributionId, address user, string skill)
 *    - VoteCast(uint contributionId, address voter, bool upvote)
 *    - ReputationUpdated(address user, int reputationChange, int newReputation)
 *    - TaskPosted(uint taskId, address poster, string requiredSkill)
 *    - TaskBid(uint taskId, address bidder)
 *    - BidAccepted(uint taskId, address assignee)
 *    - TaskCompleted(uint taskId, address assignee)
 *    - ReviewSubmitted(uint taskId, address reviewer, uint rating)
 *    - AdminAdded(address newAdmin)
 *    - AdminRemoved(address removedAdmin)
 *
 *  Advanced Concepts Used:
 *    - Decentralized Reputation System:  Voting-based reputation based on contributions.
 *    - Skill-Based Profiles: Profiles are centered around skills, enabling skill-based matching.
 *    - Task Marketplace:  Facilitates decentralized task assignment and reward.
 *    - Access Control:  Admin roles and reputation-based access for certain functions.
 *    - Voting Mechanism:  Simple upvote/downvote for contribution validation.
 *    - Events:  Extensive use of events for off-chain monitoring and data indexing.
 *
 *  Creative & Trendy Aspects:
 *    - Focus on skills and reputation in a decentralized context, aligning with the growing gig economy and decentralized work trends.
 *    - Combines profile management, reputation, and a task marketplace in a single contract for a cohesive ecosystem.
 *    - Aims to create a meritocratic system where reputation earned through contributions is valued.
 */
contract SkillDAO {
    // State Variables

    // --- Profile Management ---
    struct Profile {
        string name;
        string description;
        string[] skills;
        bool exists; // Flag to check if profile exists to avoid storage reads
    }
    mapping(address => Profile) public profiles;

    // --- Skill Management ---
    string[] public validSkills;
    mapping(string => bool) public isSkillValidMap; // For faster skill validation

    // --- Reputation System ---
    mapping(address => int256) public reputationScores; // Using int256 to allow negative reputation
    uint public reputationThreshold = 10; // Minimum reputation to post tasks
    struct Contribution {
        address user;
        string skill;
        string description;
        uint upvotes;
        uint downvotes;
        uint votingEndTime;
        bool exists;
    }
    mapping(uint => Contribution) public contributions;
    uint public contributionCount = 0;
    uint public votingDurationBlocks = 100; // Default voting duration in blocks

    // --- Task Marketplace ---
    enum TaskStatus { Open, Assigned, Completed, Reviewed }
    struct Task {
        address poster;
        string description;
        string requiredSkill;
        uint reward;
        TaskStatus status;
        address assignee;
        string reviewText;
        uint rating;
        bool exists;
    }
    mapping(uint => Task) public tasks;
    uint public taskCount = 0;

    // --- Admin Management ---
    mapping(address => bool) public admins;
    address public owner;

    // --- Events ---
    event ProfileCreated(address indexed user, string name);
    event ProfileUpdated(address indexed user);
    event SkillAddedToProfile(address indexed user, string skill);
    event SkillRemovedFromProfile(address indexed user, string skill);
    event SkillAdded(string skillName);
    event SkillRemoved(string skillName);
    event ContributionRecorded(uint indexed contributionId, address indexed user, string skill);
    event VoteCast(uint indexed contributionId, address indexed voter, bool upvote);
    event ReputationUpdated(address indexed user, int256 reputationChange, int256 newReputation);
    event TaskPosted(uint indexed taskId, address indexed poster, string requiredSkill);
    event TaskBid(uint indexed taskId, address indexed bidder);
    event BidAccepted(uint indexed taskId, uint indexed taskIndex, address indexed assignee);
    event TaskCompleted(uint indexed taskId, address indexed assignee);
    event ReviewSubmitted(uint indexed taskId, address indexed reviewer, uint rating);
    event AdminAdded(address indexed newAdmin);
    event AdminRemoved(address indexed removedAdmin);

    // --- Modifiers ---
    modifier onlyProfileOwner(address _user) {
        require(msg.sender == _user, "Only profile owner can call this function.");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Only admin can call this function.");
        _;
    }

    modifier reputationAboveThreshold() {
        require(reputationScores[msg.sender] >= int256(reputationThreshold), "Reputation too low.");
        _;
    }

    modifier validTask(uint _taskId) {
        require(tasks[_taskId].exists, "Task does not exist.");
        _;
    }

    modifier validContribution(uint _contributionId) {
        require(contributions[_contributionId].exists, "Contribution does not exist.");
        _;
    }

    modifier taskOpen(uint _taskId) {
        require(tasks[_taskId].status == TaskStatus.Open, "Task is not open for bids.");
        _;
    }

    modifier taskAssigned(uint _taskId) {
        require(tasks[_taskId].status == TaskStatus.Assigned, "Task is not assigned.");
        _;
    }

    modifier taskPoster(uint _taskId) {
        require(tasks[_taskId].poster == msg.sender, "Only task poster can call this function.");
        _;
    }

    modifier taskAssignee(uint _taskId) {
        require(tasks[_taskId].assignee == msg.sender, "Only task assignee can call this function.");
        _;
    }


    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        admins[owner] = true;
    }

    // --- Admin Functions ---
    function addAdmin(address _newAdmin) public onlyAdmin {
        admins[_newAdmin] = true;
        emit AdminAdded(_newAdmin);
    }

    function removeAdmin(address _adminToRemove) public onlyAdmin {
        require(_adminToRemove != owner, "Cannot remove contract owner as admin.");
        admins[_adminToRemove] = false;
        emit AdminRemoved(_adminToRemove);
    }

    function isAdmin(address _user) public view returns (bool) {
        return admins[_user];
    }

    function renounceAdmin() public {
        admins[msg.sender] = false;
        emit AdminRemoved(msg.sender);
    }

    function setVotingDuration(uint _durationInBlocks) public onlyAdmin {
        votingDurationBlocks = _durationInBlocks;
    }

    function setReputationThreshold(uint _threshold) public onlyAdmin {
        reputationThreshold = _threshold;
    }

    function addSkill(string memory _skillName) public onlyAdmin {
        require(!isSkillValidMap[_skillName], "Skill already exists.");
        validSkills.push(_skillName);
        isSkillValidMap[_skillName] = true;
        emit SkillAdded(_skillName);
    }

    function removeSkill(string memory _skillName) public onlyAdmin {
        require(isSkillValidMap[_skillName], "Skill does not exist.");
        isSkillValidMap[_skillName] = false;
        // Remove from validSkills array (inefficient for large arrays, consider alternative for production)
        for (uint i = 0; i < validSkills.length; i++) {
            if (keccak256(bytes(validSkills[i])) == keccak256(bytes(_skillName))) {
                validSkills[i] = validSkills[validSkills.length - 1];
                validSkills.pop();
                break;
            }
        }
        emit SkillRemoved(_skillName);
    }

    function getSkillList() public view returns (string[] memory) {
        return validSkills;
    }

    function isSkillValid(string memory _skillName) public view returns (bool) {
        return isSkillValidMap[_skillName];
    }


    // --- Profile Management Functions ---
    function createProfile(string memory _name, string memory _description, string[] memory _skills) public {
        require(!profiles[msg.sender].exists, "Profile already exists for this address.");
        Profile storage newProfile = profiles[msg.sender];
        newProfile.name = _name;
        newProfile.description = _description;
        for (uint i = 0; i < _skills.length; i++) {
            require(isSkillValidMap[_skills[i]], "Invalid skill provided.");
            newProfile.skills.push(_skills[i]);
        }
        newProfile.exists = true;
        emit ProfileCreated(msg.sender, _name);
    }

    function updateProfile(string memory _name, string memory _description, string[] memory _skills) public onlyProfileOwner(msg.sender) {
        require(profiles[msg.sender].exists, "Profile does not exist.");
        Profile storage existingProfile = profiles[msg.sender];
        existingProfile.name = _name;
        existingProfile.description = _description;
        existingProfile.skills = new string[](_skills.length); // Reset skills and re-add
        for (uint i = 0; i < _skills.length; i++) {
            require(isSkillValidMap[_skills[i]], "Invalid skill provided.");
            existingProfile.skills[i] = _skills[i];
        }
        emit ProfileUpdated(msg.sender);
    }

    function getProfile(address _user) public view returns (Profile memory) {
        return profiles[_user];
    }

    function isProfileExists(address _user) public view returns (bool) {
        return profiles[_user].exists;
    }

    function addSkillToProfile(address _user, string memory _skill) public onlyProfileOwner(_user) {
        require(profiles[_user].exists, "Profile does not exist.");
        require(isSkillValidMap[_skill], "Invalid skill provided.");
        Profile storage userProfile = profiles[_user];
        // Check if skill already exists (simple linear search for now, optimize if needed for large skill lists)
        for (uint i = 0; i < userProfile.skills.length; i++) {
            if (keccak256(bytes(userProfile.skills[i])) == keccak256(bytes(_skill))) {
                revert("Skill already added to profile.");
            }
        }
        userProfile.skills.push(_skill);
        emit SkillAddedToProfile(_user, _skill);
    }

    function removeSkillFromProfile(address _user, string memory _skill) public onlyProfileOwner(_user) {
        require(profiles[_user].exists, "Profile does not exist.");
        Profile storage userProfile = profiles[_user];
        for (uint i = 0; i < userProfile.skills.length; i++) {
            if (keccak256(bytes(userProfile.skills[i])) == keccak256(bytes(_skill))) {
                userProfile.skills[i] = userProfile.skills[userProfile.skills.length - 1];
                userProfile.skills.pop();
                emit SkillRemovedFromProfile(_user, _skill);
                return;
            }
        }
        revert("Skill not found in profile.");
    }


    // --- Reputation System Functions ---
    function recordContribution(address _user, string memory _skill, string memory _contributionDescription) public {
        require(profiles[_user].exists, "User profile does not exist.");
        require(isSkillValidMap[_skill], "Invalid skill provided.");

        contributionCount++;
        Contribution storage newContribution = contributions[contributionCount];
        newContribution.user = _user;
        newContribution.skill = _skill;
        newContribution.description = _contributionDescription;
        newContribution.votingEndTime = block.number + votingDurationBlocks;
        newContribution.exists = true;

        emit ContributionRecorded(contributionCount, _user, _skill);
    }

    function getContributionDetails(uint _contributionId) public view validContribution(_contributionId) returns (Contribution memory) {
        return contributions[_contributionId];
    }

    function voteOnContribution(uint _contributionId, bool _upvote) public validContribution(_contributionId) {
        require(block.number <= contributions[_contributionId].votingEndTime, "Voting time expired.");
        // Prevent self-voting (optional, can be removed if self-validation is desired)
        require(contributions[_contributionId].user != msg.sender, "Cannot vote on your own contribution.");

        if (_upvote) {
            contributions[_contributionId].upvotes++;
            _updateReputation(contributions[_contributionId].user, 1); // Small reputation gain for upvotes
        } else {
            contributions[_contributionId].downvotes++;
            _updateReputation(contributions[_contributionId].user, -1); // Small reputation loss for downvotes
        }
        emit VoteCast(_contributionId, msg.sender, _upvote);
    }

    function getReputation(address _user) public view returns (int256) {
        return reputationScores[_user];
    }

    function _updateReputation(address _user, int256 _change) private {
        reputationScores[_user] += _change;
        emit ReputationUpdated(_user, _change, reputationScores[_user]);
    }


    // --- Task Marketplace Functions ---
    function postTask(string memory _taskDescription, string memory _requiredSkill, uint _reward) public reputationAboveThreshold {
        require(profiles[msg.sender].exists, "Task poster profile does not exist.");
        require(isSkillValidMap[_requiredSkill], "Invalid required skill.");
        require(_reward > 0, "Reward must be greater than zero."); // Basic reward validation

        taskCount++;
        Task storage newTask = tasks[taskCount];
        newTask.poster = msg.sender;
        newTask.description = _taskDescription;
        newTask.requiredSkill = _requiredSkill;
        newTask.reward = _reward;
        newTask.status = TaskStatus.Open;
        newTask.exists = true;

        emit TaskPosted(taskCount, msg.sender, _requiredSkill);
    }

    function bidOnTask(uint _taskId, string memory _bidDescription) public validTask(_taskId) taskOpen(_taskId) {
        require(profiles[msg.sender].exists, "Bidder profile does not exist.");
        require(profiles[msg.sender].skills.length > 0 , "Bidder profile must have at least one skill."); // Basic skill check for bidding
        bool hasRequiredSkill = false;
        for(uint i = 0; i < profiles[msg.sender].skills.length; i++){
            if(keccak256(bytes(profiles[msg.sender].skills[i])) == keccak256(bytes(tasks[_taskId].requiredSkill))){
                hasRequiredSkill = true;
                break;
            }
        }
        require(hasRequiredSkill, "Bidder does not possess the required skill for this task.");

        // In a real-world scenario, you might want to store bids associated with tasks
        // For simplicity, this example just emits an event for bidding.
        emit TaskBid(_taskId, msg.sender);
    }

    function acceptBid(uint _taskId, address _bidder) public validTask(_taskId) taskOpen(_taskId) taskPoster(_taskId) {
        tasks[_taskId].status = TaskStatus.Assigned;
        tasks[_taskId].assignee = _bidder;
        emit BidAccepted(_taskId, _taskId, _bidder);
    }

    function completeTask(uint _taskId) public validTask(_taskId) taskAssigned(_taskId) taskAssignee(_taskId) {
        tasks[_taskId].status = TaskStatus.Completed;
        emit TaskCompleted(_taskId, msg.sender);
        // In a real-world application, you would handle reward distribution here, potentially using escrow or other mechanisms.
        // For simplicity, reward distribution is not implemented in this example.
    }

    function submitReview(uint _taskId, string memory _reviewText, uint _rating) public validTask(_taskId) taskAssigned(_taskId) taskPoster(_taskId) {
        require(tasks[_taskId].status == TaskStatus.Completed, "Task must be completed before reviewing.");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5."); // Basic rating validation

        tasks[_taskId].status = TaskStatus.Reviewed;
        tasks[_taskId].reviewText = _reviewText;
        tasks[_taskId].rating = _rating;
        emit ReviewSubmitted(_taskId, msg.sender, _rating);
    }

    function getTaskDetails(uint _taskId) public view validTask(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }

    function getOpenTasks() public view returns (uint[] memory) {
        uint[] memory openTaskIds = new uint[](taskCount); // Max possible open tasks is taskCount
        uint openTaskCount = 0;
        for (uint i = 1; i <= taskCount; i++) {
            if (tasks[i].exists && tasks[i].status == TaskStatus.Open) {
                openTaskIds[openTaskCount] = i;
                openTaskCount++;
            }
        }
        // Resize the array to the actual number of open tasks
        assembly {
            mstore(openTaskIds, openTaskCount) // Update the length of the array
        }
        return openTaskIds;
    }

    function getTasksByUser(address _user) public view returns (uint[] memory) {
        uint[] memory userTaskIds = new uint[](taskCount); // Max possible tasks for a user is taskCount
        uint userTaskCount = 0;
        for (uint i = 1; i <= taskCount; i++) {
            if (tasks[i].exists && (tasks[i].poster == _user || tasks[i].assignee == _user)) {
                userTaskIds[userTaskCount] = i;
                userTaskCount++;
            }
        }
        // Resize the array to the actual number of user tasks
        assembly {
            mstore(userTaskIds, userTaskCount) // Update the length of the array
        }
        return userTaskIds;
    }

    // --- Utility Function ---
    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    // --- Fallback and Receive (Optional for this contract, but good practice for contracts interacting with ETH) ---
    receive() external payable {}
    fallback() external payable {}
}
```