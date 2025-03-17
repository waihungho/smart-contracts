```solidity
/**
 * @title Decentralized Skill Marketplace with Dynamic Reputation and Task-Based NFTs
 * @author Gemini (AI Assistant)
 * @dev A smart contract for a decentralized skill marketplace where users can offer and request skills,
 * build dynamic reputations, and complete tasks represented as NFTs.
 *
 * **Outline:**
 * 1. **Profile Management:**
 *    - `registerProfile()`: Register a user profile with skills.
 *    - `updateProfileSkills()`: Update skills in a user profile.
 *    - `viewProfile()`: View a user profile.
 *
 * 2. **Skill NFTs (Dynamic Badges):**
 *    - `mintSkillNFT()`: Mint an NFT representing a specific skill for a user. (Internal, triggered by skill registration/update)
 *    - `getSkillNFTOfUser()`: Get the Skill NFT ID of a user for a specific skill.
 *    - `transferSkillNFT()`: Allow users to transfer Skill NFTs (Optional, could be for showcasing).
 *
 * 3. **Task Request System:**
 *    - `createTaskRequest()`: Create a new task request specifying required skills and reward.
 *    - `updateTaskRequest()`: Update details of an existing task request (before assignment).
 *    - `cancelTaskRequest()`: Cancel a task request.
 *    - `viewTaskRequest()`: View details of a task request.
 *    - `listOpenTaskRequests()`: List all open task requests.
 *
 * 4. **Task Application and Assignment:**
 *    - `applyForTask()`: Apply for an open task request.
 *    - `withdrawApplication()`: Withdraw an application for a task.
 *    - `selectApplicant()`: Task requester selects an applicant for the task.
 *    - `viewTaskApplicants()`: View applicants for a specific task.
 *
 * 5. **Task Completion and Verification:**
 *    - `submitTaskCompletion()`: Worker submits task completion proof.
 *    - `verifyTaskCompletion()`: Task requester verifies task completion and releases reward.
 *    - `disputeTaskCompletion()`: Initiate a dispute for a task completion.
 *
 * 6. **Dynamic Reputation System:**
 *    - `increaseReputation()`: Increase a user's reputation (triggered by verified task completion). (Internal)
 *    - `decreaseReputation()`: Decrease a user's reputation (triggered by disputes or negative feedback - not implemented in this basic version). (Internal - placeholder for future)
 *    - `getReputation()`: Get a user's reputation score.
 *    - `getReputationTier()`: Get a user's reputation tier based on their score.
 *
 * 7. **Admin/Utility Functions:**
 *    - `setPlatformFee()`: Set the platform fee percentage. (Admin only)
 *    - `withdrawPlatformFees()`: Withdraw accumulated platform fees. (Admin only)
 *    - `pauseContract()`: Pause the contract functionalities. (Admin only)
 *    - `unpauseContract()`: Unpause the contract functionalities. (Admin only)
 *
 * **Function Summary:**
 * - `registerProfile(string _name, string[] _skills)`: Allows users to register their profile with a name and list of skills.
 * - `updateProfileSkills(string[] _newSkills)`: Allows users to update their listed skills.
 * - `viewProfile(address _user)`: Returns the profile information (name and skills) of a user.
 * - `mintSkillNFT(address _user, string _skill)`: (Internal) Mints a Skill NFT for a user and a specific skill.
 * - `getSkillNFTOfUser(address _user, string _skill)`: Returns the NFT ID of a Skill NFT for a user and skill, or 0 if not found.
 * - `transferSkillNFT(address _to, uint256 _tokenId)`: Allows transferring Skill NFTs.
 * - `createTaskRequest(string _title, string _description, string[] _requiredSkills, uint256 _reward)`: Creates a new task request with details, required skills, and reward amount.
 * - `updateTaskRequest(uint256 _taskId, string _description, uint256 _reward)`: Updates the description and reward of a task request (before assignment).
 * - `cancelTaskRequest(uint256 _taskId)`: Cancels a task request if it's still in 'Open' status.
 * - `viewTaskRequest(uint256 _taskId)`: Returns detailed information about a specific task request.
 * - `listOpenTaskRequests()`: Returns a list of IDs for all currently open task requests.
 * - `applyForTask(uint256 _taskId)`: Allows a user to apply for an open task request.
 * - `withdrawApplication(uint256 _taskId)`: Allows a user to withdraw their application from a task request.
 * - `selectApplicant(uint256 _taskId, address _applicant)`: Task requester selects an applicant to assign the task to.
 * - `viewTaskApplicants(uint256 _taskId)`: Returns a list of addresses of users who have applied for a specific task.
 * - `submitTaskCompletion(uint256 _taskId, string _completionProof)`: Worker submits proof of task completion.
 * - `verifyTaskCompletion(uint256 _taskId)`: Task requester verifies the task completion and pays the reward to the worker.
 * - `disputeTaskCompletion(uint256 _taskId, string _disputeReason)`: Allows the requester or worker to initiate a dispute for a task.
 * - `increaseReputation(address _user)`: (Internal) Increases a user's reputation score.
 * - `decreaseReputation(address _user)`: (Internal - Placeholder) Decreases a user's reputation score (Not fully implemented).
 * - `getReputation(address _user)`: Returns a user's current reputation score.
 * - `getReputationTier(address _user)`: Returns a user's reputation tier based on their score.
 * - `setPlatformFee(uint256 _feePercentage)`: (Admin) Sets the platform fee percentage.
 * - `withdrawPlatformFees()`: (Admin) Allows the admin to withdraw accumulated platform fees.
 * - `pauseContract()`: (Admin) Pauses the contract, disabling most functionalities.
 * - `unpauseContract()`: (Admin) Unpauses the contract, re-enabling functionalities.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DecentralizedSkillMarketplace is ERC721, Pausable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _skillNFTCounter;
    Counters.Counter private _taskCounter;

    // Structs and Enums
    struct UserProfile {
        string name;
        string[] skills;
        uint256 reputationScore;
    }

    struct TaskRequest {
        address requester;
        string title;
        string description;
        string[] requiredSkills;
        uint256 reward;
        TaskStatus status;
        address assignedWorker;
        address[] applicants;
        string completionProof;
        string disputeReason;
    }

    enum TaskStatus {
        Open,
        Assigned,
        Completed,
        Verified,
        Disputed,
        Cancelled
    }

    // State Variables
    mapping(address => UserProfile) public userProfiles;
    mapping(address => mapping(string => uint256)) public userSkillNFTs; // user => skill => NFT ID
    mapping(uint256 => TaskRequest) public taskRequests;
    mapping(address => uint256) public userReputation;

    uint256 public platformFeePercentage = 2; // Default 2% platform fee
    address payable public platformFeeWallet;
    uint256 public accumulatedPlatformFees;

    bool public contractPaused = false;

    // Events
    event ProfileRegistered(address user, string name, string[] skills);
    event ProfileSkillsUpdated(address user, string[] newSkills);
    event SkillNFTMinted(address user, uint256 tokenId, string skill);
    event TaskRequestCreated(uint256 taskId, address requester, string title);
    event TaskRequestUpdated(uint256 taskId, string description, uint256 reward);
    event TaskRequestCancelled(uint256 taskId);
    event TaskApplied(uint256 taskId, address applicant);
    event TaskApplicationWithdrawn(uint256 taskId, address applicant);
    event TaskApplicantSelected(uint256 taskId, address requester, address worker);
    event TaskCompletionSubmitted(uint256 taskId, address worker);
    event TaskCompletionVerified(uint256 taskId, address requester, address worker, uint256 reward);
    event TaskDisputed(uint256 taskId, address disputer, string reason);
    event ReputationIncreased(address user, uint256 newReputation);
    event PlatformFeePercentageSet(uint256 newFeePercentage);
    event PlatformFeesWithdrawn(uint256 amount, address wallet);
    event ContractPaused();
    event ContractUnpaused();

    // Reputation Tiers (Example - can be customized)
    mapping(uint256 => string) public reputationTiers = mapping(uint256 => string)(
        [0: "Beginner", 10: "Novice", 50: "Intermediate", 100: "Expert", 200: "Master"]
    );

    constructor(address payable _platformFeeWallet) ERC721("SkillBadge", "SBADGE") Ownable() {
        platformFeeWallet = _platformFeeWallet;
    }

    // Modifier for paused contract
    modifier ifNotPaused {
        require(!contractPaused, "Contract is currently paused");
        _;
    }

    // 1. Profile Management
    function registerProfile(string memory _name, string[] memory _skills) public ifNotPaused {
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(userProfiles[msg.sender].name.length == 0, "Profile already registered");

        userProfiles[msg.sender] = UserProfile({
            name: _name,
            skills: _skills,
            reputationScore: 0
        });

        for (uint i = 0; i < _skills.length; i++) {
            mintSkillNFT(msg.sender, _skills[i]);
        }

        emit ProfileRegistered(msg.sender, _name, _skills);
    }

    function updateProfileSkills(string[] memory _newSkills) public ifNotPaused {
        require(userProfiles[msg.sender].name.length > 0, "Profile not registered");
        userProfiles[msg.sender].skills = _newSkills;

        // Re-mint Skill NFTs if skills are updated (consider logic for removing old NFTs if needed)
        // For simplicity, we just re-mint for all new skills. More complex logic can be added.
        for (uint i = 0; i < _newSkills.length; i++) {
            mintSkillNFT(msg.sender, _newSkills[i]);
        }

        emit ProfileSkillsUpdated(msg.sender, _newSkills);
    }

    function viewProfile(address _user) public view returns (string memory name, string[] memory skills, uint256 reputation) {
        require(userProfiles[_user].name.length > 0, "Profile not registered");
        UserProfile memory profile = userProfiles[_user];
        return (profile.name, profile.skills, profile.reputationScore);
    }

    // 2. Skill NFTs (Dynamic Badges)
    function mintSkillNFT(address _user, string memory _skill) internal {
        _skillNFTCounter.increment();
        uint256 tokenId = _skillNFTCounter.current();
        _mint(_user, tokenId);
        userSkillNFTs[_user][_skill] = tokenId;
        emit SkillNFTMinted(_user, tokenId, _skill);
    }

    function getSkillNFTOfUser(address _user, string memory _skill) public view returns (uint256) {
        return userSkillNFTs[_user][_skill];
    }

    function transferSkillNFT(address _to, uint256 _tokenId) public ifNotPaused {
        safeTransferFrom(msg.sender, _to, _tokenId);
    }

    // 3. Task Request System
    function createTaskRequest(
        string memory _title,
        string memory _description,
        string[] memory _requiredSkills,
        uint256 _reward
    ) public payable ifNotPaused {
        require(userProfiles[msg.sender].name.length > 0, "Requester profile not registered");
        require(bytes(_title).length > 0 && bytes(_description).length > 0, "Title and description cannot be empty");
        require(_reward > 0, "Reward must be greater than zero");

        _taskCounter.increment();
        uint256 taskId = _taskCounter.current();

        taskRequests[taskId] = TaskRequest({
            requester: msg.sender,
            title: _title,
            description: _description,
            requiredSkills: _requiredSkills,
            reward: _reward,
            status: TaskStatus.Open,
            assignedWorker: address(0),
            applicants: new address[](0),
            completionProof: "",
            disputeReason: ""
        });

        emit TaskRequestCreated(taskId, msg.sender, _title);
    }

    function updateTaskRequest(uint256 _taskId, string memory _description, uint256 _reward) public ifNotPaused {
        require(taskRequests[_taskId].requester == msg.sender, "Only requester can update task");
        require(taskRequests[_taskId].status == TaskStatus.Open, "Task is not in Open status");
        require(bytes(_description).length > 0, "Description cannot be empty");
        require(_reward > 0, "Reward must be greater than zero");

        taskRequests[_taskId].description = _description;
        taskRequests[_taskId].reward = _reward;

        emit TaskRequestUpdated(_taskId, _description, _reward);
    }

    function cancelTaskRequest(uint256 _taskId) public ifNotPaused {
        require(taskRequests[_taskId].requester == msg.sender, "Only requester can cancel task");
        require(taskRequests[_taskId].status == TaskStatus.Open, "Task is not in Open status");

        taskRequests[_taskId].status = TaskStatus.Cancelled;
        emit TaskRequestCancelled(_taskId);
    }

    function viewTaskRequest(uint256 _taskId) public view returns (TaskRequest memory) {
        require(_taskId > 0 && _taskId <= _taskCounter.current(), "Invalid task ID");
        return taskRequests[_taskId];
    }

    function listOpenTaskRequests() public view returns (uint256[] memory) {
        uint256[] memory openTaskIds = new uint256[](_taskCounter.current()); // Max size, might have empty slots
        uint256 count = 0;
        for (uint256 i = 1; i <= _taskCounter.current(); i++) {
            if (taskRequests[i].status == TaskStatus.Open) {
                openTaskIds[count] = i;
                count++;
            }
        }

        // Resize to actual number of open tasks
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = openTaskIds[i];
        }
        return result;
    }

    // 4. Task Application and Assignment
    function applyForTask(uint256 _taskId) public ifNotPaused {
        require(userProfiles[msg.sender].name.length > 0, "Applicant profile not registered");
        require(taskRequests[_taskId].status == TaskStatus.Open, "Task is not in Open status");
        require(taskRequests[_taskId].assignedWorker == address(0), "Task already assigned");
        require(!isApplicant(_taskId, msg.sender), "Already applied for this task");

        // Check if applicant has required skills (basic check - can be made more sophisticated)
        bool hasRequiredSkills = true;
        string[] memory requiredSkills = taskRequests[_taskId].requiredSkills;
        string[] memory applicantSkills = userProfiles[msg.sender].skills;

        for (uint i = 0; i < requiredSkills.length; i++) {
            bool skillFound = false;
            for (uint j = 0; j < applicantSkills.length; j++) {
                if (keccak256(abi.encodePacked(applicantSkills[j])) == keccak256(abi.encodePacked(requiredSkills[i]))) {
                    skillFound = true;
                    break;
                }
            }
            if (!skillFound) {
                hasRequiredSkills = false;
                break;
            }
        }
        require(hasRequiredSkills, "Applicant does not possess all required skills");


        taskRequests[_taskId].applicants.push(msg.sender);
        emit TaskApplied(_taskId, msg.sender);
    }

    function withdrawApplication(uint256 _taskId) public ifNotPaused {
        require(taskRequests[_taskId].status == TaskStatus.Open, "Task is not in Open status");
        require(isApplicant(_taskId, msg.sender), "Not applied for this task");

        address[] storage applicants = taskRequests[_taskId].applicants;
        for (uint i = 0; i < applicants.length; i++) {
            if (applicants[i] == msg.sender) {
                // Remove applicant from the array (inefficient for large arrays, consider other data structures if needed)
                delete applicants[i];
                // Shift elements to fill the gap (maintaining array order is not strictly necessary here)
                for (uint j = i; j < applicants.length - 1; j++) {
                    applicants[j] = applicants[j + 1];
                }
                applicants.pop(); // Remove the last (duplicate or zeroed) element
                emit TaskApplicationWithdrawn(_taskId, msg.sender);
                return;
            }
        }
        // Should not reach here if isApplicant check is correct
    }

    function selectApplicant(uint256 _taskId, address _applicant) public ifNotPaused {
        require(taskRequests[_taskId].requester == msg.sender, "Only requester can select applicant");
        require(taskRequests[_taskId].status == TaskStatus.Open, "Task is not in Open status");
        require(isApplicant(_taskId, _applicant), "Applicant has not applied for this task");
        require(taskRequests[_taskId].assignedWorker == address(0), "Task already assigned");

        taskRequests[_taskId].assignedWorker = _applicant;
        taskRequests[_taskId].status = TaskStatus.Assigned;
        emit TaskApplicantSelected(_taskId, msg.sender, _applicant);
    }

    function viewTaskApplicants(uint256 _taskId) public view returns (address[] memory) {
        require(_taskId > 0 && _taskId <= _taskCounter.current(), "Invalid task ID");
        return taskRequests[_taskId].applicants;
    }

    // Helper function to check if an address is in the applicants list
    function isApplicant(uint256 _taskId, address _applicant) internal view returns (bool) {
        address[] memory applicants = taskRequests[_taskId].applicants;
        for (uint i = 0; i < applicants.length; i++) {
            if (applicants[i] == _applicant) {
                return true;
            }
        }
        return false;
    }

    // 5. Task Completion and Verification
    function submitTaskCompletion(uint256 _taskId, string memory _completionProof) public ifNotPaused {
        require(taskRequests[_taskId].assignedWorker == msg.sender, "Only assigned worker can submit completion");
        require(taskRequests[_taskId].status == TaskStatus.Assigned, "Task is not in Assigned status");
        require(bytes(_completionProof).length > 0, "Completion proof cannot be empty");

        taskRequests[_taskId].completionProof = _completionProof;
        taskRequests[_taskId].status = TaskStatus.Completed;
        emit TaskCompletionSubmitted(_taskId, msg.sender);
    }

    function verifyTaskCompletion(uint256 _taskId) public payable ifNotPaused {
        require(taskRequests[_taskId].requester == msg.sender, "Only requester can verify completion");
        require(taskRequests[_taskId].status == TaskStatus.Completed, "Task is not in Completed status");
        require(msg.value >= calculateFee(taskRequests[_taskId].reward), "Insufficient payment for reward and platform fee");

        uint256 rewardAmount = taskRequests[_taskId].reward;
        uint256 platformFee = calculateFee(rewardAmount);
        uint256 workerReward = rewardAmount - platformFee;

        // Transfer worker reward
        payable(taskRequests[_taskId].assignedWorker).transfer(workerReward);

        // Handle platform fees
        accumulatedPlatformFees += platformFee;
        if (platformFee > 0) {
             // Consider transferring fees to platform wallet immediately or accumulate and withdraw later
        }

        taskRequests[_taskId].status = TaskStatus.Verified;
        increaseReputation(taskRequests[_taskId].assignedWorker); // Increase worker's reputation
        emit TaskCompletionVerified(_taskId, msg.sender, taskRequests[_taskId].assignedWorker, workerReward);
    }

    function disputeTaskCompletion(uint256 _taskId, string memory _disputeReason) public ifNotPaused {
        require(taskRequests[_taskId].status == TaskStatus.Completed || taskRequests[_taskId].status == TaskStatus.Assigned, "Task must be in Completed or Assigned status to dispute");
        require(taskRequests[_taskId].requester == msg.sender || taskRequests[_taskId].assignedWorker == msg.sender, "Only requester or worker can dispute");
        require(bytes(_disputeReason).length > 0, "Dispute reason cannot be empty");

        taskRequests[_taskId].status = TaskStatus.Disputed;
        taskRequests[_taskId].disputeReason = _disputeReason;
        emit TaskDisputed(_taskId, msg.sender, _disputeReason);

        // In a real-world scenario, dispute resolution logic would be much more complex
        // This could involve admin intervention, voting, oracles, etc.
        // For this example, we just mark the task as disputed.
    }

    // 6. Dynamic Reputation System
    function increaseReputation(address _user) internal {
        userReputation[_user] += 1; // Simple increment - can be more complex based on task value, feedback, etc.
        emit ReputationIncreased(_user, userReputation[_user]);
    }

    function decreaseReputation(address _user) internal { // Placeholder - not fully implemented in this basic version
        if (userReputation[_user] > 0) {
           userReputation[_user] -= 1; // Simple decrement - trigger on disputes, negative feedback (future)
           emit ReputationIncreased(_user, userReputation[_user]); // Re-use event for simplicity, adjust if needed
        }
    }

    function getReputation(address _user) public view returns (uint256) {
        return userReputation[_user];
    }

    function getReputationTier(address _user) public view returns (string memory) {
        uint256 reputation = userReputation[_user];
        string memory currentTier = "Unranked"; // Default tier if no match
        for (uint256 tierScore; tierScore <= 200; tierScore += 1) { // Iterate through tiers
            if (reputationTiers[tierScore].length > 0 && reputation >= tierScore) {
                currentTier = reputationTiers[tierScore];
            }
        }
        return currentTier;
    }

    // 7. Admin/Utility Functions
    function setPlatformFee(uint256 _feePercentage) public onlyOwner {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100");
        platformFeePercentage = _feePercentage;
        emit PlatformFeePercentageSet(_feePercentage);
    }

    function withdrawPlatformFees() public onlyOwner {
        uint256 amountToWithdraw = accumulatedPlatformFees;
        accumulatedPlatformFees = 0;
        platformFeeWallet.transfer(amountToWithdraw);
        emit PlatformFeesWithdrawn(amountToWithdraw, platformFeeWallet);
    }

    function pauseContract() public onlyOwner {
        contractPaused = true;
        emit ContractPaused();
    }

    function unpauseContract() public onlyOwner {
        contractPaused = false;
        emit ContractUnpaused();
    }

    // Helper function to calculate platform fee
    function calculateFee(uint256 _amount) internal view returns (uint256) {
        return (_amount * platformFeePercentage) / 100;
    }

    // Fallback function to receive Ether for task rewards and platform fees
    receive() external payable {}
}
```