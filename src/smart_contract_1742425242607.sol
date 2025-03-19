```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Skill-Based Reputation & Task Marketplace with Dynamic NFTs
 * @author Gemini AI Assistant
 * @dev This smart contract implements a decentralized marketplace where users can build reputation based on their skills
 *      and complete tasks. It introduces dynamic NFTs that evolve based on user reputation and task completion.
 *      This contract is designed to be creative and incorporate advanced concepts, avoiding duplication of common open-source contracts.
 *
 * **Outline and Function Summary:**
 *
 * **Core Functionality:**
 * 1. `registerUser(string _name, string _profileDescription, string[] _skills)`: Allows users to register on the platform, defining their profile and skills.
 * 2. `updateProfile(string _name, string _profileDescription, string[] _skills)`: Allows registered users to update their profile information and skills.
 * 3. `getUserProfile(address _userAddress)`: Retrieves the profile information of a registered user.
 * 4. `createTask(string _title, string _description, uint256 _reward, string[] _requiredSkills)`: Allows registered users to create new tasks, specifying details, reward, and required skills.
 * 5. `getTaskDetails(uint256 _taskId)`: Retrieves detailed information about a specific task.
 * 6. `applyForTask(uint256 _taskId)`: Allows registered users to apply for a task if they possess the required skills.
 * 7. `acceptTaskApplication(uint256 _taskId, address _applicantAddress)`: Allows the task creator to accept an application for their task.
 * 8. `submitTaskWork(uint256 _taskId, string _submissionHash)`: Allows the assigned user to submit their work for a task, providing a hash of the submission.
 * 9. `approveTaskCompletion(uint256 _taskId)`: Allows the task creator to approve the completed work and pay the reward.
 * 10. `rejectTaskCompletion(uint256 _taskId, string _rejectionReason)`: Allows the task creator to reject the completed work with a reason, potentially triggering a dispute.
 * 11. `reportUser(address _reportedUser, string _reportReason)`: Allows users to report other users for misconduct, affecting their reputation.
 * 12. `endorseUserSkill(address _endorsedUser, string _skill)`: Allows users to endorse other users for specific skills, boosting their reputation in those areas.
 * 13. `getReputation(address _userAddress)`: Retrieves the reputation score of a user.
 * 14. `getSkillReputation(address _userAddress, string _skill)`: Retrieves the reputation score of a user for a specific skill.
 * 15. `listTasksBySkill(string _skill)`: Lists all tasks that require a specific skill.
 * 16. `listTasksByUser(address _userAddress)`: Lists all tasks created or applied for by a specific user.
 *
 * **Advanced Concepts & Dynamic NFTs:**
 * 17. `mintDynamicNFT(address _userAddress)`: Mints a dynamic NFT for a user, initially based on their registered profile.
 * 18. `getDynamicNFTMetadata(uint256 _tokenId)`: Retrieves the dynamic metadata URI for a user's NFT, which reflects their reputation and skills.
 * 19. `updateDynamicNFTMetadata(address _userAddress)`: (Internal/Automatic) Updates the metadata of a user's dynamic NFT based on reputation changes and task completions. This would be triggered by other functions.
 *
 * **Platform & Governance (Basic):**
 * 20. `setPlatformFee(uint256 _feePercentage)`: Allows the contract owner to set a platform fee percentage for task rewards.
 * 21. `withdrawPlatformFees()`: Allows the contract owner to withdraw accumulated platform fees.
 * 22. `pauseContract()`:  Allows the contract owner to pause core functionalities in case of emergency.
 * 23. `unpauseContract()`: Allows the contract owner to resume contract functionalities.
 */

contract ReputationTaskMarketplace {
    // --- State Variables ---

    address public owner;
    uint256 public platformFeePercentage = 2; // Default 2% platform fee
    bool public paused = false;

    uint256 public nextTaskId = 1;
    uint256 public nextNFTTokenId = 1;

    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => Task) public tasks;
    mapping(uint256 => address) public taskApplications; // taskId => applicant address
    mapping(address => uint256) public userReputation; // Overall reputation score
    mapping(address => mapping(string => uint256)) public skillReputation; // Skill-based reputation

    mapping(uint256 => address) public nftOwner; // tokenId => user address
    mapping(uint256 => string) public nftMetadataURIs; // tokenId => metadata URI

    string public baseMetadataURI = "ipfs://your_base_metadata_uri/"; // Replace with your IPFS base URI

    struct UserProfile {
        address userAddress;
        string name;
        string profileDescription;
        string[] skills;
        bool registered;
    }

    enum TaskStatus { Open, Applied, Assigned, Submitted, Completed, Rejected, Dispute }

    struct Task {
        uint256 taskId;
        address creator;
        string title;
        string description;
        uint256 reward;
        string[] requiredSkills;
        TaskStatus status;
        address assignee;
        string submissionHash;
        string rejectionReason;
        address[] applicants;
    }

    // --- Events ---
    event UserRegistered(address userAddress, string name);
    event ProfileUpdated(address userAddress);
    event TaskCreated(uint256 taskId, address creator);
    event TaskApplication(uint256 taskId, address applicant);
    event TaskApplicationAccepted(uint256 taskId, address applicant);
    event TaskSubmitted(uint256 taskId, address assignee);
    event TaskCompleted(uint256 taskId, address creator, address assignee, uint256 reward);
    event TaskRejected(uint256 taskId, address creator, address assignee, string reason);
    event UserReported(address reporter, address reportedUser, string reason);
    event SkillEndorsed(address endorser, address endorsedUser, string skill);
    event ReputationUpdated(address userAddress, uint256 newReputation);
    event DynamicNFTMinted(address userAddress, uint256 tokenId);
    event DynamicNFTMetadataUpdated(uint256 tokenId, string metadataURI);
    event PlatformFeeSet(uint256 feePercentage);
    event PlatformFeesWithdrawn(address owner, uint256 amount);
    event ContractPaused();
    event ContractUnpaused();


    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
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

    modifier onlyRegisteredUser() {
        require(userProfiles[msg.sender].registered, "User not registered.");
        _;
    }

    modifier taskExists(uint256 _taskId) {
        require(tasks[_taskId].taskId != 0, "Task does not exist.");
        _;
    }

    modifier onlyTaskCreator(uint256 _taskId) {
        require(tasks[_taskId].creator == msg.sender, "Only task creator can call this function.");
        _;
    }

    modifier onlyTaskAssignee(uint256 _taskId) {
        require(tasks[_taskId].assignee == msg.sender, "Only task assignee can call this function.");
        _;
    }

    modifier taskStatus(uint256 _taskId, TaskStatus _status) {
        require(tasks[_taskId].status == _status, "Task status is not correct.");
        _;
    }

    modifier hasRequiredSkills(uint256 _taskId, address _userAddress) {
        bool hasSkills = true;
        string[] memory requiredSkills = tasks[_taskId].requiredSkills;
        string[] memory userSkills = userProfiles[_userAddress].skills;

        if (requiredSkills.length > 0) {
            for (uint i = 0; i < requiredSkills.length; i++) {
                bool skillFound = false;
                for (uint j = 0; j < userSkills.length; j++) {
                    if (keccak256(abi.encodePacked(userSkills[j])) == keccak256(abi.encodePacked(requiredSkills[i]))) {
                        skillFound = true;
                        break;
                    }
                }
                if (!skillFound) {
                    hasSkills = false;
                    break;
                }
            }
        }
        require(hasSkills, "User does not have all required skills.");
        _;
    }


    // --- Constructor ---
    constructor() {
        owner = msg.sender;
    }

    // --- User Profile Functions ---

    /// @notice Registers a new user on the platform.
    /// @param _name The name of the user.
    /// @param _profileDescription A brief description of the user's profile.
    /// @param _skills An array of skills the user possesses.
    function registerUser(string memory _name, string memory _profileDescription, string[] memory _skills) external whenNotPaused {
        require(!userProfiles[msg.sender].registered, "User already registered.");
        userProfiles[msg.sender] = UserProfile({
            userAddress: msg.sender,
            name: _name,
            profileDescription: _profileDescription,
            skills: _skills,
            registered: true
        });
        userReputation[msg.sender] = 100; // Initial reputation
        emit UserRegistered(msg.sender, _name);
        mintDynamicNFT(msg.sender); // Mint dynamic NFT on registration
    }

    /// @notice Updates the profile information of a registered user.
    /// @param _name The new name of the user.
    /// @param _profileDescription The new profile description.
    /// @param _skills The updated array of skills.
    function updateProfile(string memory _name, string memory _profileDescription, string[] memory _skills) external onlyRegisteredUser whenNotPaused {
        userProfiles[msg.sender].name = _name;
        userProfiles[msg.sender].profileDescription = _profileDescription;
        userProfiles[msg.sender].skills = _skills;
        emit ProfileUpdated(msg.sender);
        updateDynamicNFTMetadata(msg.sender); // Update NFT on profile change
    }

    /// @notice Retrieves the profile information of a registered user.
    /// @param _userAddress The address of the user to query.
    /// @return UserProfile struct containing user profile details.
    function getUserProfile(address _userAddress) external view returns (UserProfile memory) {
        require(userProfiles[_userAddress].registered, "User not registered.");
        return userProfiles[_userAddress];
    }


    // --- Task Management Functions ---

    /// @notice Creates a new task on the platform.
    /// @param _title The title of the task.
    /// @param _description A detailed description of the task.
    /// @param _reward The reward amount for completing the task.
    /// @param _requiredSkills An array of skills required to complete the task.
    function createTask(string memory _title, string memory _description, uint256 _reward, string[] memory _requiredSkills) external onlyRegisteredUser whenNotPaused {
        require(_reward > 0, "Reward must be greater than zero.");
        tasks[nextTaskId] = Task({
            taskId: nextTaskId,
            creator: msg.sender,
            title: _title,
            description: _description,
            reward: _reward,
            requiredSkills: _requiredSkills,
            status: TaskStatus.Open,
            assignee: address(0),
            submissionHash: "",
            rejectionReason: "",
            applicants: new address[](0)
        });
        emit TaskCreated(nextTaskId, msg.sender);
        nextTaskId++;
    }

    /// @notice Retrieves detailed information about a specific task.
    /// @param _taskId The ID of the task to query.
    /// @return Task struct containing task details.
    function getTaskDetails(uint256 _taskId) external view taskExists(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }

    /// @notice Allows a registered user to apply for a task.
    /// @param _taskId The ID of the task to apply for.
    function applyForTask(uint256 _taskId) external onlyRegisteredUser whenNotPaused taskExists(_taskId) taskStatus(_taskId, TaskStatus.Open) hasRequiredSkills(_taskId, msg.sender) {
        require(taskApplications[_taskId] == address(0), "Task already has an application."); // Basic single application for now, could be expanded
        require(!isApplicant(tasks[_taskId].applicants, msg.sender), "Already applied for this task.");

        tasks[_taskId].applicants.push(msg.sender);
        emit TaskApplication(_taskId, msg.sender);
    }

    function isApplicant(address[] memory _applicants, address _user) private pure returns (bool) {
        for (uint i = 0; i < _applicants.length; i++) {
            if (_applicants[i] == _user) {
                return true;
            }
        }
        return false;
    }

    /// @notice Allows the task creator to accept an application for their task.
    /// @param _taskId The ID of the task.
    /// @param _applicantAddress The address of the applicant to accept.
    function acceptTaskApplication(uint256 _taskId, address _applicantAddress) external onlyRegisteredUser whenNotPaused taskExists(_taskId) onlyTaskCreator(_taskId) taskStatus(_taskId, TaskStatus.Open) {
        require(isApplicant(tasks[_taskId].applicants, _applicantAddress), "Applicant has not applied for this task.");
        tasks[_taskId].status = TaskStatus.Assigned;
        tasks[_taskId].assignee = _applicantAddress;
        emit TaskApplicationAccepted(_taskId, _applicantAddress);
    }

    /// @notice Allows the assigned user to submit their work for a task.
    /// @param _taskId The ID of the task.
    /// @param _submissionHash A hash representing the submitted work (e.g., IPFS hash).
    function submitTaskWork(uint256 _taskId, string memory _submissionHash) external onlyRegisteredUser whenNotPaused taskExists(_taskId) onlyTaskAssignee(_taskId) taskStatus(_taskId, TaskStatus.Assigned) {
        tasks[_taskId].status = TaskStatus.Submitted;
        tasks[_taskId].submissionHash = _submissionHash;
        emit TaskSubmitted(_taskId, msg.sender);
    }

    /// @notice Allows the task creator to approve the completed work and pay the reward.
    /// @param _taskId The ID of the task.
    function approveTaskCompletion(uint256 _taskId) external payable onlyRegisteredUser whenNotPaused taskExists(_taskId) onlyTaskCreator(_taskId) taskStatus(_taskId, TaskStatus.Submitted) {
        uint256 platformFee = (tasks[_taskId].reward * platformFeePercentage) / 100;
        uint256 workerReward = tasks[_taskId].reward - platformFee;

        require(msg.value >= tasks[_taskId].reward, "Insufficient funds sent for reward and platform fee.");

        payable(tasks[_taskId].assignee).transfer(workerReward);
        payable(owner).transfer(platformFee); // Platform fee goes to owner

        tasks[_taskId].status = TaskStatus.Completed;
        emit TaskCompleted(_taskId, msg.sender, tasks[_taskId].assignee, workerReward);

        // Update Reputation - Positive for worker, slightly positive for creator
        updateReputation(tasks[_taskId].assignee, 20); // Worker gets more reputation
        updateReputation(msg.sender, 5);
        updateDynamicNFTMetadata(tasks[_taskId].assignee);
        updateDynamicNFTMetadata(msg.sender);
    }

    /// @notice Allows the task creator to reject the completed work with a reason.
    /// @param _taskId The ID of the task.
    /// @param _rejectionReason A reason for rejecting the task.
    function rejectTaskCompletion(uint256 _taskId, string memory _rejectionReason) external onlyRegisteredUser whenNotPaused taskExists(_taskId) onlyTaskCreator(_taskId) taskStatus(_taskId, TaskStatus.Submitted) {
        tasks[_taskId].status = TaskStatus.Rejected;
        tasks[_taskId].rejectionReason = _rejectionReason;
        emit TaskRejected(_taskId, msg.sender, tasks[_taskId].assignee, _rejectionReason);

        // Update Reputation - Negative for worker, slightly negative for creator (for potential bad task design/communication)
        updateReputation(tasks[_taskId].assignee, -15);
        updateReputation(msg.sender, -3);
        updateDynamicNFTMetadata(tasks[_taskId].assignee);
        updateDynamicNFTMetadata(msg.sender);
    }


    // --- Reputation Functions ---

    /// @notice Allows users to report another user for misconduct.
    /// @param _reportedUser The address of the user being reported.
    /// @param _reportReason The reason for the report.
    function reportUser(address _reportedUser, string memory _reportReason) external onlyRegisteredUser whenNotPaused {
        require(_reportedUser != msg.sender, "Cannot report yourself.");
        emit UserReported(msg.sender, _reportedUser, _reportReason);

        // Reputation penalty for reported user (can be adjusted based on severity, dispute resolution etc.)
        updateReputation(_reportedUser, -10);
        updateDynamicNFTMetadata(_reportedUser);
    }

    /// @notice Allows users to endorse another user for a specific skill.
    /// @param _endorsedUser The address of the user being endorsed.
    /// @param _skill The skill for which the user is being endorsed.
    function endorseUserSkill(address _endorsedUser, string memory _skill) external onlyRegisteredUser whenNotPaused {
        require(_endorsedUser != msg.sender, "Cannot endorse yourself.");
        emit SkillEndorsed(msg.sender, _endorsedUser, _skill);

        // Skill-based reputation boost
        skillReputation[_endorsedUser][_skill] += 5; // Can adjust boost value
        updateReputation(_endorsedUser, 2); // Small overall reputation boost too
        updateDynamicNFTMetadata(_endorsedUser);
    }

    /// @notice Retrieves the overall reputation score of a user.
    /// @param _userAddress The address of the user.
    /// @return The overall reputation score.
    function getReputation(address _userAddress) external view returns (uint256) {
        return userReputation[_userAddress];
    }

    /// @notice Retrieves the reputation score of a user for a specific skill.
    /// @param _userAddress The address of the user.
    /// @param _skill The skill to query reputation for.
    /// @return The skill-based reputation score.
    function getSkillReputation(address _userAddress, string memory _skill) external view returns (uint256) {
        return skillReputation[_userAddress][_skill];
    }

    /// @dev Internal function to update user reputation and emit event.
    /// @param _userAddress The address of the user whose reputation is being updated.
    /// @param _reputationChange The change in reputation score (positive or negative).
    function updateReputation(address _userAddress, int256 _reputationChange) internal {
        // Using int256 to handle negative changes, then convert back to uint256 for storage (clamping at 0)
        int256 currentReputation = int256(userReputation[_userAddress]);
        int256 newReputation = currentReputation + _reputationChange;

        if (newReputation < 0) {
            userReputation[_userAddress] = 0;
        } else {
            userReputation[_userAddress] = uint256(newReputation);
        }
        emit ReputationUpdated(_userAddress, userReputation[_userAddress]);
    }


    // --- Task Listing Functions ---

    /// @notice Lists all tasks that require a specific skill.
    /// @param _skill The skill to filter tasks by.
    /// @return An array of task IDs that require the specified skill.
    function listTasksBySkill(string memory _skill) external view returns (uint256[] memory) {
        uint256[] memory taskIds = new uint256[](nextTaskId - 1); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i < nextTaskId; i++) {
            Task storage task = tasks[i];
            if (task.taskId != 0) { // Check if task exists (in case of deletions in future - not implemented here)
                for (uint j = 0; j < task.requiredSkills.length; j++) {
                    if (keccak256(abi.encodePacked(task.requiredSkills[j])) == keccak256(abi.encodePacked(_skill))) {
                        taskIds[count] = task.taskId;
                        count++;
                        break; // Move to next task once skill is found
                    }
                }
            }
        }

        // Resize the array to the actual number of tasks found
        uint256[] memory resultTaskIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            resultTaskIds[i] = taskIds[i];
        }
        return resultTaskIds;
    }

    /// @notice Lists all tasks created or applied for by a specific user.
    /// @param _userAddress The address of the user.
    /// @return An array of task IDs associated with the user.
    function listTasksByUser(address _userAddress) external view returns (uint256[] memory) {
        uint256[] memory taskIds = new uint256[](nextTaskId - 1); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i < nextTaskId; i++) {
            Task storage task = tasks[i];
            if (task.taskId != 0) {
                if (task.creator == _userAddress || task.assignee == _userAddress || isApplicant(task.applicants, _userAddress)) {
                    taskIds[count] = task.taskId;
                    count++;
                }
            }
        }

        // Resize result array
        uint256[] memory resultTaskIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            resultTaskIds[i] = taskIds[i];
        }
        return resultTaskIds;
    }


    // --- Dynamic NFT Functions ---

    /// @notice Mints a dynamic NFT for a user upon registration.
    /// @param _userAddress The address of the user to mint NFT for.
    function mintDynamicNFT(address _userAddress) internal {
        uint256 tokenId = nextNFTTokenId;
        nftOwner[tokenId] = _userAddress;
        nftMetadataURIs[tokenId] = generateMetadataURI(_userAddress); // Initial metadata
        emit DynamicNFTMinted(_userAddress, tokenId);
        nextNFTTokenId++;
    }

    /// @notice Retrieves the dynamic metadata URI for a user's NFT.
    /// @param _tokenId The ID of the NFT token.
    /// @return The metadata URI.
    function getDynamicNFTMetadata(uint256 _tokenId) external view returns (string memory) {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist for this token ID.");
        return nftMetadataURIs[_tokenId];
    }

    /// @dev Internal function to update the dynamic NFT metadata for a user.
    /// @param _userAddress The address of the user whose NFT metadata needs updating.
    function updateDynamicNFTMetadata(address _userAddress) internal {
        uint256 tokenId = 0;
        // Find the tokenId associated with the user (assuming 1 NFT per user for now)
        for (uint256 i = 1; i < nextNFTTokenId; i++) {
            if (nftOwner[i] == _userAddress) {
                tokenId = i;
                break;
            }
        }
        if (tokenId > 0) {
            string memory newMetadataURI = generateMetadataURI(_userAddress);
            nftMetadataURIs[tokenId] = newMetadataURI;
            emit DynamicNFTMetadataUpdated(tokenId, newMetadataURI);
        }
        // If no NFT found for user (unlikely after registration), consider minting a new one or handling error
    }

    /// @dev Internal function to generate dynamic metadata URI based on user's profile and reputation.
    /// @param _userAddress The address of the user.
    /// @return The generated metadata URI string.
    function generateMetadataURI(address _userAddress) internal view returns (string memory) {
        UserProfile memory profile = userProfiles[_userAddress];
        uint256 reputation = userReputation[_userAddress];

        // ***  This is a simplified example - In a real application, you would likely use an off-chain service ***
        // ***  (like IPFS, Pinata, or a custom metadata server) to dynamically generate and host the metadata JSON. ***
        // ***  Here, we are just constructing a basic URI string.  ***

        string memory metadataString = string(abi.encodePacked(
            baseMetadataURI,
            "user_",
            addressToString(_userAddress),
            "_reputation_",
            uint2str(reputation),
            ".json" // Or .jsonld for linked data
        ));

        // In a real scenario, the JSON at this URI would be dynamically generated and could include:
        // - User Name, Profile Description
        // - Reputation Score
        // - List of Skills and Skill Reputations
        // - Visual representation of reputation level (e.g., different NFT image tiers based on reputation)
        // - Links to tasks completed, endorsements received, etc.

        return metadataString;
    }

    // --- Platform Management Functions ---

    /// @notice Sets the platform fee percentage for task rewards. Only callable by the contract owner.
    /// @param _feePercentage The new platform fee percentage (e.g., 2 for 2%).
    function setPlatformFee(uint256 _feePercentage) external onlyOwner whenNotPaused {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100.");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage);
    }

    /// @notice Allows the contract owner to withdraw accumulated platform fees.
    function withdrawPlatformFees() external onlyOwner whenNotPaused {
        uint256 balance = address(this).balance;
        uint256 feesToWithdraw = 0;

        // Calculate total fees collected (assuming fees are simply contract balance beyond initial deployment cost)
        //  A more robust system would track fees separately during task completion.
        feesToWithdraw = balance; // In this simplified example, withdraw all contract balance

        require(feesToWithdraw > 0, "No platform fees to withdraw.");

        payable(owner).transfer(feesToWithdraw);
        emit PlatformFeesWithdrawn(owner, feesToWithdraw);
    }

    /// @notice Pauses the core functionalities of the contract. Only callable by the contract owner.
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /// @notice Resumes the core functionalities of the contract. Only callable by the contract owner.
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }


    // --- Utility Functions ---

    /// @dev Helper function to convert address to string for metadata URI generation (basic, not gas efficient for general use).
    function addressToString(address _address) private pure returns (string memory) {
        bytes memory str = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 byte = bytes1(uint8(uint256(_address) / (2**(8*(19 - i)))));
            uint8 hi = uint8(byte) / 16;
            uint8 lo = uint8(byte) % 16;
            str[2*i] = hi < 10 ? bytes1(uint8('0') + hi) : bytes1(uint8('a') + hi - 10);
            str[2*i+1] = lo < 10 ? bytes1(uint8('0') + lo) : bytes1(uint8('a') + lo - 10);
        }
        return string(str);
    }

    /// @dev Helper function to convert uint256 to string for metadata URI generation (basic).
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    receive() external payable {} // To receive ETH for task rewards and platform fees
}
```