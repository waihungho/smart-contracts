```solidity
pragma solidity ^0.8.0;

/**
 * @title Dynamic Reputation and Task Marketplace Contract
 * @author Gemini AI Assistant
 * @dev A smart contract that implements a dynamic reputation system and a task marketplace
 *  with gamified elements, reputation-based access, and dynamic NFT rewards.
 *
 * **Outline:**
 * 1. **Reputation System:**
 *    - Users earn reputation points for completing tasks and positive interactions.
 *    - Reputation levels unlock access to higher-value tasks and features.
 *    - Reputation can decay over time if inactive.
 *
 * 2. **Task Marketplace:**
 *    - Task posters can create tasks with descriptions, requirements, and rewards.
 *    - Users can browse and accept tasks based on their reputation level and skills.
 *    - Task completion is verified by the task poster and/or community voting.
 *    - Rewards can be in ERC20 tokens, platform-specific tokens, or dynamic NFTs.
 *
 * 3. **Dynamic NFT Rewards:**
 *    - NFTs awarded as task rewards can have dynamic properties that change based on user reputation, task type, or platform events.
 *    - NFT properties can unlock additional benefits within the platform or elsewhere.
 *
 * 4. **Gamification and Community Engagement:**
 *    - Leaderboards based on reputation and task completion.
 *    - Challenges and achievements to earn bonus reputation and rewards.
 *    - Community voting for task verification and platform governance (optional).
 *
 * **Function Summary:**
 *
 * **Reputation Management:**
 * 1. `updateReputation(address _user, int256 _reputationChange)`:  Updates a user's reputation score.
 * 2. `getReputation(address _user)`: Returns the reputation score of a user.
 * 3. `setReputationThreshold(uint256 _level, uint256 _threshold)`: Sets reputation threshold for a level.
 * 4. `getReputationLevel(address _user)`: Returns the reputation level of a user based on thresholds.
 * 5. `decayReputation(address _user)`: Periodically reduces user reputation if inactive.
 *
 * **Task Management:**
 * 6. `createTask(string memory _title, string memory _description, uint256 _rewardAmount, address _rewardToken, uint256 _requiredReputation)`: Creates a new task.
 * 7. `acceptTask(uint256 _taskId)`: Allows a user to accept an available task.
 * 8. `submitTask(uint256 _taskId, string memory _submissionDetails)`: Allows a user to submit a completed task.
 * 9. `verifyTaskCompletion(uint256 _taskId, address _taskCompleter)`: Allows task poster to verify a task as completed.
 * 10. `requestTaskVerificationVote(uint256 _taskId)`: Allows a task completer to request community vote for verification if poster is unresponsive.
 * 11. `voteOnTaskVerification(uint256 _taskId, bool _vote)`: Allows users with sufficient reputation to vote on task verification.
 * 12. `getTaskDetails(uint256 _taskId)`: Returns details of a specific task.
 * 13. `getAvailableTasks()`: Returns a list of available tasks based on user reputation.
 * 14. `getMyAcceptedTasks()`: Returns a list of tasks accepted by the caller.
 *
 * **Reward and NFT Management:**
 * 15. `setRewardToken(address _tokenAddress)`: Sets the reward token for tasks (ERC20).
 * 16. `withdrawRewardTokens(uint256 _amount)`: Allows the contract owner to withdraw reward tokens.
 * 17. `awardDynamicNFT(address _recipient, uint256 _taskId)`: Mints and awards a dynamic NFT as task reward.
 * 18. `getDynamicNFTProperties(uint256 _tokenId)`: Returns dynamic properties of a given NFT.
 * 19. `updateDynamicNFTProperty(uint256 _tokenId, string memory _propertyName, string memory _propertyValue)`: Updates a dynamic NFT property (Owner only).
 *
 * **Platform Management:**
 * 20. `setPlatformFee(uint256 _feePercentage)`: Sets the platform fee percentage for tasks.
 * 21. `withdrawPlatformFees()`: Allows the contract owner to withdraw accumulated platform fees.
 * 22. `pauseContract()`: Pauses the contract functionalities (Owner only).
 * 23. `unpauseContract()`: Resumes the contract functionalities (Owner only).
 */
contract DynamicReputationTaskMarketplace {
    // --- State Variables ---

    address public owner;
    bool public paused;
    uint256 public platformFeePercentage; // Percentage of task reward taken as platform fee
    address public rewardTokenAddress; // Address of the ERC20 reward token

    // Reputation Management
    mapping(address => int256) public userReputation;
    mapping(uint256 => uint256) public reputationThresholds; // Level => Threshold
    uint256 public reputationDecayRate; // Rate of reputation decay per time unit

    // Task Management
    uint256 public taskCounter;
    struct Task {
        uint256 id;
        string title;
        string description;
        address poster;
        uint256 rewardAmount;
        address rewardToken;
        uint256 requiredReputation;
        address completer;
        string submissionDetails;
        bool isCompleted;
        bool verificationRequested;
        uint256 verificationVotesPositive;
        uint256 verificationVotesNegative;
        bool isActive;
    }
    mapping(uint256 => Task) public tasks;
    mapping(uint256 => address[]) public taskVerificationVoters; // TaskId => Array of voters

    // Dynamic NFT Management (Simplified - Could be expanded with ERC721Enumerable, Metadata, etc.)
    uint256 public dynamicNFTCounter;
    mapping(uint256 => address) public nftOwner;
    mapping(uint256 => mapping(string => string)) public nftProperties; // TokenId => PropertyName => PropertyValue


    // --- Events ---
    event ReputationUpdated(address user, int256 reputationChange, int256 newReputation);
    event TaskCreated(uint256 taskId, address poster, string title, uint256 rewardAmount);
    event TaskAccepted(uint256 taskId, address completer);
    event TaskSubmitted(uint256 taskId, address completer);
    event TaskVerified(uint256 taskId, address completer, address verifier);
    event TaskVerificationRequested(uint256 taskId, address requester);
    event TaskVerificationVote(uint256 taskId, address voter, bool vote);
    event DynamicNFTAwarded(uint256 tokenId, address recipient, uint256 taskId);
    event DynamicNFTPropertyChanged(uint256 tokenId, string propertyName, string propertyValue);
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

    modifier taskExists(uint256 _taskId) {
        require(tasks[_taskId].id != 0, "Task does not exist.");
        _;
    }

    modifier taskIsActive(uint256 _taskId) {
        require(tasks[_taskId].isActive, "Task is not active.");
        _;
    }

    modifier taskIsNotCompleted(uint256 _taskId) {
        require(!tasks[_taskId].isCompleted, "Task is already completed.");
        _;
    }

    modifier reputationRequirementMet(uint256 _requiredReputation) {
        require(getReputation(msg.sender) >= _requiredReputation, "Insufficient reputation to perform this action.");
        _;
    }

    modifier onlyTaskPoster(uint256 _taskId) {
        require(tasks[_taskId].poster == msg.sender, "Only task poster can call this function.");
        _;
    }

    modifier onlyTaskCompleter(uint256 _taskId) {
        require(tasks[_taskId].completer == msg.sender, "Only task completer can call this function.");
        _;
    }

    modifier notTaskCompleter(uint256 _taskId) {
        require(tasks[_taskId].completer != msg.sender, "Task completer cannot call this function.");
        _;
    }


    // --- Constructor ---
    constructor(address _rewardTokenAddress) payable {
        owner = msg.sender;
        paused = false;
        platformFeePercentage = 5; // Default 5% platform fee
        rewardTokenAddress = _rewardTokenAddress;
        reputationDecayRate = 1; // Example decay rate - adjust as needed

        // Initialize default reputation thresholds (Example levels)
        reputationThresholds[1] = 100;
        reputationThresholds[2] = 500;
        reputationThresholds[3] = 1000;
    }

    // --- Reputation Management Functions ---

    /**
     * @dev Updates a user's reputation score.
     * @param _user The address of the user.
     * @param _reputationChange The amount to change the reputation by (can be positive or negative).
     */
    function updateReputation(address _user, int256 _reputationChange) external onlyOwner {
        userReputation[_user] += _reputationChange;
        emit ReputationUpdated(_user, _reputationChange, userReputation[_user]);
    }

    /**
     * @dev Gets the reputation score of a user.
     * @param _user The address of the user.
     * @return The user's reputation score.
     */
    function getReputation(address _user) public view returns (int256) {
        return userReputation[_user];
    }

    /**
     * @dev Sets the reputation threshold for a specific reputation level.
     * @param _level The reputation level (e.g., 1, 2, 3...).
     * @param _threshold The reputation points required to reach this level.
     */
    function setReputationThreshold(uint256 _level, uint256 _threshold) external onlyOwner {
        reputationThresholds[_level] = _threshold;
    }

    /**
     * @dev Gets the reputation level of a user based on the defined thresholds.
     * @param _user The address of the user.
     * @return The user's reputation level (0 if below level 1).
     */
    function getReputationLevel(address _user) public view returns (uint256) {
        uint256 reputationScore = uint256(getReputation(_user));
        for (uint256 level = 1; ; level++) {
            if (reputationThresholds[level] == 0 || reputationScore < reputationThresholds[level]) {
                return level - 1; // Return previous level if threshold not met or level not defined
            }
        }
    }

    /**
     * @dev Periodically decays user reputation if inactive (Example - requires external triggering, could be automated with Chainlink Keepers or similar).
     * @param _user The address of the user whose reputation should decay.
     */
    function decayReputation(address _user) external onlyOwner { // Owner triggered for demonstration - consider automation
        // Example: Decay by a fixed amount or percentage based on last activity time (not tracked in this simplified example)
        int256 decayAmount = -int256(reputationDecayRate);
        userReputation[_user] += decayAmount;
        if (userReputation[_user] < 0) {
            userReputation[_user] = 0; // Reputation cannot be negative
        }
        emit ReputationUpdated(_user, decayAmount, userReputation[_user]);
    }


    // --- Task Management Functions ---

    /**
     * @dev Creates a new task.
     * @param _title The title of the task.
     * @param _description The description of the task.
     * @param _rewardAmount The reward amount for completing the task.
     * @param _rewardToken The address of the reward token (should match contract's rewardTokenAddress).
     * @param _requiredReputation The minimum reputation required to accept this task.
     */
    function createTask(
        string memory _title,
        string memory _description,
        uint256 _rewardAmount,
        address _rewardToken,
        uint256 _requiredReputation
    ) external whenNotPaused reputationRequirementMet(_requiredReputation) {
        require(_rewardToken == rewardTokenAddress, "Reward token must be the platform's reward token.");
        require(_rewardAmount > 0, "Reward amount must be greater than zero.");

        taskCounter++;
        tasks[taskCounter] = Task({
            id: taskCounter,
            title: _title,
            description: _description,
            poster: msg.sender,
            rewardAmount: _rewardAmount,
            rewardToken: _rewardToken,
            requiredReputation: _requiredReputation,
            completer: address(0), // No completer assigned yet
            submissionDetails: "",
            isCompleted: false,
            verificationRequested: false,
            verificationVotesPositive: 0,
            verificationVotesNegative: 0,
            isActive: true
        });

        emit TaskCreated(taskCounter, msg.sender, _title, _rewardAmount);
    }

    /**
     * @dev Allows a user to accept an available task.
     * @param _taskId The ID of the task to accept.
     */
    function acceptTask(uint256 _taskId)
        external
        whenNotPaused
        taskExists(_taskId)
        taskIsActive(_taskId)
        taskIsNotCompleted(_taskId)
        reputationRequirementMet(tasks[_taskId].requiredReputation)
        notTaskCompleter(_taskId)
    {
        require(tasks[_taskId].completer == address(0), "Task already accepted."); // Ensure task is not already accepted

        tasks[_taskId].completer = msg.sender;
        emit TaskAccepted(_taskId, msg.sender);
    }

    /**
     * @dev Allows a user to submit a completed task.
     * @param _taskId The ID of the task being submitted.
     * @param _submissionDetails Details of the submission (e.g., link to work, description).
     */
    function submitTask(uint256 _taskId, string memory _submissionDetails)
        external
        whenNotPaused
        taskExists(_taskId)
        taskIsActive(_taskId)
        taskIsNotCompleted(_taskId)
        onlyTaskCompleter(_taskId)
    {
        require(bytes(_submissionDetails).length > 0, "Submission details cannot be empty.");

        tasks[_taskId].submissionDetails = _submissionDetails;
        emit TaskSubmitted(_taskId, msg.sender);
    }

    /**
     * @dev Allows the task poster to verify a task as completed and reward the completer.
     * @param _taskId The ID of the task to verify.
     * @param _taskCompleter The address of the task completer.
     */
    function verifyTaskCompletion(uint256 _taskId, address _taskCompleter)
        external
        whenNotPaused
        taskExists(_taskId)
        taskIsActive(_taskId)
        taskIsNotCompleted(_taskId)
        onlyTaskPoster(_taskId)
    {
        require(tasks[_taskId].completer == _taskCompleter, "Completer address does not match task completer.");

        tasks[_taskId].isCompleted = true;
        tasks[_taskId].isActive = false; // Deactivate task after completion

        // Transfer reward tokens (minus platform fee)
        uint256 platformFee = (tasks[_taskId].rewardAmount * platformFeePercentage) / 100;
        uint256 rewardForCompleter = tasks[_taskId].rewardAmount - platformFee;

        // Transfer platform fee to contract (for owner withdrawal) - In a real app, manage fees more carefully
        // (Simplified - assumes contract has enough balance or tokens are pre-deposited)
        // Consider using a separate fee wallet/contract for more robust fee management in production
        IERC20(rewardTokenAddress).transfer(address(this), platformFee);

        // Transfer reward to task completer
        IERC20(rewardTokenAddress).transfer(_taskCompleter, rewardForCompleter);

        // Award dynamic NFT as additional reward
        awardDynamicNFT(_taskCompleter, _taskId);

        emit TaskVerified(_taskId, _taskCompleter, msg.sender);
    }


    /**
     * @dev Allows a task completer to request community verification if the task poster is unresponsive.
     * @param _taskId The ID of the task for which verification is requested.
     */
    function requestTaskVerificationVote(uint256 _taskId)
        external
        whenNotPaused
        taskExists(_taskId)
        taskIsActive(_taskId)
        taskIsNotCompleted(_taskId)
        onlyTaskCompleter(_taskId)
    {
        require(!tasks[_taskId].verificationRequested, "Verification already requested.");
        tasks[_taskId].verificationRequested = true;
        emit TaskVerificationRequested(_taskId, msg.sender);
    }

    /**
     * @dev Allows users with sufficient reputation to vote on task verification.
     * @param _taskId The ID of the task being voted on.
     * @param _vote True for verification approved, false for rejected.
     */
    function voteOnTaskVerification(uint256 _taskId, bool _vote)
        external
        whenNotPaused
        taskExists(_taskId)
        taskIsActive(_taskId)
        taskIsNotCompleted(_taskId)
        reputationRequirementMet(reputationThresholds[2]) // Example: Level 2 reputation required to vote
    {
        require(tasks[_taskId].verificationRequested, "Verification not requested for this task.");
        require(!_hasVoted(msg.sender, _taskId), "User has already voted.");

        taskVerificationVoters[_taskId].push(msg.sender); // Record voter

        if (_vote) {
            tasks[_taskId].verificationVotesPositive++;
        } else {
            tasks[_taskId].verificationVotesNegative++;
        }
        emit TaskVerificationVote(_taskId, msg.sender, _vote);

        // Example: Auto-verify task if enough positive votes and reject if enough negative votes
        uint256 requiredVotes = 3; // Example: Require 3 positive votes
        if (tasks[_taskId].verificationVotesPositive >= requiredVotes) {
            verifyTaskCompletion(_taskId, tasks[_taskId].completer); // Auto-verify if enough positive votes
        } else if (tasks[_taskId].verificationVotesNegative >= requiredVotes) {
            tasks[_taskId].isActive = false; // Deactivate task if rejected by community vote
        }
    }

    /**
     * @dev Helper function to check if a user has already voted on a task.
     * @param _user The address of the user.
     * @param _taskId The ID of the task.
     * @return True if the user has voted, false otherwise.
     */
    function _hasVoted(address _user, uint256 _taskId) internal view returns (bool) {
        address[] storage voters = taskVerificationVoters[_taskId];
        for (uint256 i = 0; i < voters.length; i++) {
            if (voters[i] == _user) {
                return true;
            }
        }
        return false;
    }


    /**
     * @dev Gets details of a specific task.
     * @param _taskId The ID of the task.
     * @return Task struct containing task details.
     */
    function getTaskDetails(uint256 _taskId) external view taskExists(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }

    /**
     * @dev Gets a list of available tasks based on the caller's reputation level.
     * @return Array of task IDs that are available to the caller.
     */
    function getAvailableTasks() external view returns (uint256[] memory) {
        uint256[] memory availableTaskIds = new uint256[](taskCounter); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i <= taskCounter; i++) {
            if (tasks[i].isActive && !tasks[i].isCompleted && tasks[i].completer == address(0) && getReputation(msg.sender) >= tasks[i].requiredReputation) {
                availableTaskIds[count] = tasks[i].id;
                count++;
            }
        }
        // Resize array to actual number of tasks
        uint256[] memory resizedTaskIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            resizedTaskIds[i] = availableTaskIds[i];
        }
        return resizedTaskIds;
    }

    /**
     * @dev Gets a list of tasks accepted by the calling user.
     * @return Array of task IDs accepted by the caller.
     */
    function getMyAcceptedTasks() external view returns (uint256[] memory) {
        uint256[] memory acceptedTaskIds = new uint256[](taskCounter); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i <= taskCounter; i++) {
            if (tasks[i].isActive && !tasks[i].isCompleted && tasks[i].completer == msg.sender) {
                acceptedTaskIds[count] = tasks[i].id;
                count++;
            }
        }
         // Resize array to actual number of tasks
        uint256[] memory resizedTaskIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            resizedTaskIds[i] = acceptedTaskIds[i];
        }
        return resizedTaskIds;
    }


    // --- Reward and NFT Management Functions ---

    /**
     * @dev Sets the reward token address for tasks.
     * @param _tokenAddress The address of the ERC20 reward token.
     */
    function setRewardToken(address _tokenAddress) external onlyOwner {
        rewardTokenAddress = _tokenAddress;
    }

    /**
     * @dev Allows the contract owner to withdraw reward tokens from the contract balance.
     * @param _amount The amount of tokens to withdraw.
     */
    function withdrawRewardTokens(uint256 _amount) external onlyOwner {
        IERC20(rewardTokenAddress).transfer(owner, _amount);
        // Consider adding events for token withdrawals
    }


    /**
     * @dev Mints and awards a dynamic NFT to a user as a task reward.
     * @param _recipient The address to receive the NFT.
     * @param _taskId The ID of the task for which the NFT is awarded.
     */
    function awardDynamicNFT(address _recipient, uint256 _taskId) internal {
        dynamicNFTCounter++;
        uint256 tokenId = dynamicNFTCounter;
        nftOwner[tokenId] = _recipient;

        // Initialize dynamic NFT properties based on task and user reputation (Example)
        nftProperties[tokenId]["TaskReward"] = tasks[_taskId].title;
        nftProperties[tokenId]["ReputationLevel"] = string.concat(Strings.toString(getReputationLevel(_recipient)), " Level");
        nftProperties[tokenId]["CompletionDate"] = Strings.toString(block.timestamp);

        emit DynamicNFTAwarded(tokenId, _recipient, _taskId);
    }

    /**
     * @dev Gets the dynamic properties of a given NFT.
     * @param _tokenId The ID of the NFT.
     * @return Mapping of property names to property values.
     */
    function getDynamicNFTProperties(uint256 _tokenId) external view returns (mapping(string => string) memory) {
        return nftProperties[_tokenId];
    }

    /**
     * @dev Updates a dynamic NFT property (Owner only - In a real scenario, consider more nuanced update logic).
     * @param _tokenId The ID of the NFT.
     * @param _propertyName The name of the property to update.
     * @param _propertyValue The new value of the property.
     */
    function updateDynamicNFTProperty(uint256 _tokenId, string memory _propertyName, string memory _propertyValue) external onlyOwner {
        nftProperties[_tokenId][_propertyName] = _propertyValue;
        emit DynamicNFTPropertyChanged(_tokenId, _propertyName, _propertyValue);
    }


    // --- Platform Management Functions ---

    /**
     * @dev Sets the platform fee percentage for tasks.
     * @param _feePercentage The new platform fee percentage (0-100).
     */
    function setPlatformFee(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100.");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage);
    }

    /**
     * @dev Allows the contract owner to withdraw accumulated platform fees.
     */
    function withdrawPlatformFees() external onlyOwner {
        uint256 balance = IERC20(rewardTokenAddress).balanceOf(address(this));
        IERC20(rewardTokenAddress).transfer(owner, balance);
        emit PlatformFeesWithdrawn(owner, balance);
    }

    /**
     * @dev Pauses the contract, preventing most functionalities.
     */
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /**
     * @dev Unpauses the contract, restoring functionalities.
     */
    function unpauseContract() external onlyOwner {
        paused = false;
        emit ContractUnpaused();
    }

    // --- Helper Functions ---

    /**
     * @dev Helper library for converting uint to string.
     */
    library Strings {
        function toString(uint256 value) internal pure returns (string memory) {
            // ... (Standard implementation of uint256 to string conversion - can be found online or use external library)
            // Simplified version for brevity (not fully robust for very large numbers)
            if (value == 0) {
                return "0";
            }
            uint256 temp = value;
            uint256 digits;
            while (temp != 0) {
                digits++;
                temp /= 10;
            }
            bytes memory buffer = new bytes(digits);
            while (value != 0) {
                digits -= 1;
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
            }
            return string(buffer);
        }
    }
}
```