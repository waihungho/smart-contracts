```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic Reputation and Reward System with On-Chain Governance
 * @author Bard (Example Smart Contract)
 * @dev A smart contract implementing a dynamic reputation and reward system with advanced features
 * including on-chain governance for system parameters, dynamic task creation, reputation-based access control,
 * and customizable reward mechanisms. This contract aims to be creative and showcase advanced Solidity concepts
 * without directly replicating common open-source contracts.
 *
 * Function Summary:
 * -----------------
 * **Admin Functions:**
 * 1.  `setReputationLevels(uint256[] memory _levels)`: Sets the reputation level thresholds.
 * 2.  `addTaskDefinition(string memory _taskName, string memory _taskDescription, uint256 _reputationReward)`: Defines a new task that users can perform to earn reputation.
 * 3.  `updateTaskDefinition(uint256 _taskId, string memory _newTaskName, string memory _newTaskDescription, uint256 _newReputationReward)`: Updates an existing task definition.
 * 4.  `removeTaskDefinition(uint256 _taskId)`: Removes a task definition, preventing users from earning reputation from it.
 * 5.  `setRewardForLevel(uint256 _level, address _rewardToken, uint256 _rewardAmount)`: Sets a reward (ERC20 token) for reaching a specific reputation level.
 * 6.  `setGovernanceThreshold(uint256 _threshold)`: Sets the reputation threshold required to participate in governance proposals.
 * 7.  `createGovernanceProposal(string memory _description, bytes memory _calldata)`: Creates a new governance proposal to modify contract parameters.
 * 8.  `cancelGovernanceProposal(uint256 _proposalId)`: Cancels a governance proposal before the voting period ends.
 * 9.  `executeGovernanceProposal(uint256 _proposalId)`: Executes a passed governance proposal, applying the changes to the contract.
 * 10. `setOwner(address _newOwner)`: Transfers contract ownership to a new address.
 * 11. `withdrawTokens(address _tokenAddress, address _to, uint256 _amount)`: Allows the owner to withdraw any ERC20 tokens held by the contract (for emergency or legitimate fund management).
 *
 * **User Interaction Functions:**
 * 12. `performTask(uint256 _taskId)`: Allows a user to perform a defined task and earn reputation.
 * 13. `claimLevelReward()`: Allows a user to claim rewards associated with their current reputation level.
 * 14. `getUserReputation(address _user)`: Retrieves the reputation points of a specific user.
 * 15. `getUserLevel(address _user)`: Retrieves the reputation level of a specific user based on their reputation points.
 * 16. `getAvailableTasks()`: Retrieves a list of currently active tasks that users can perform.
 * 17. `getGovernanceProposals()`: Retrieves a list of active governance proposals.
 * 18. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows users with sufficient reputation to vote on governance proposals.
 *
 * **Utility/Getter Functions:**
 * 19. `getReputationLevelDetails(uint256 _level)`: Retrieves details about a specific reputation level.
 * 20. `getTaskDefinitionDetails(uint256 _taskId)`: Retrieves details about a specific task definition.
 * 21. `getRewardDetailsForLevel(uint256 _level)`: Retrieves reward details for a specific reputation level.
 * 22. `getGovernanceProposalDetails(uint256 _proposalId)`: Retrieves details about a specific governance proposal.
 * 23. `contractInfo()`: Returns basic information about the contract.
 */
contract DynamicReputationSystem {
    // State Variables
    address public owner;
    mapping(address => uint256) public userReputation; // User address => reputation points
    uint256[] public reputationLevels; // Array of reputation thresholds for levels (e.g., [100, 500, 1000])
    mapping(uint256 => string) public reputationLevelNames; // Level index => Level name
    uint256 public nextTaskId;
    mapping(uint256 => TaskDefinition) public taskDefinitions; // Task ID => Task Definition
    uint256 public nextProposalId;
    mapping(uint256 => GovernanceProposal) public governanceProposals; // Proposal ID => Governance Proposal
    uint256 public governanceThreshold; // Reputation required to participate in governance
    mapping(uint256 => LevelReward) public levelRewards; // Reputation Level => Reward Details

    struct TaskDefinition {
        string name;
        string description;
        uint256 reputationReward;
        bool isActive;
    }

    struct LevelReward {
        address rewardToken; // Address of ERC20 token
        uint256 rewardAmount;
    }

    struct GovernanceProposal {
        string description;
        address proposer;
        bytes calldata; // Encoded function call data
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isActive;
        bool executed;
    }

    enum ProposalStatus { Active, Passed, Rejected, Cancelled, Executed }

    event ReputationEarned(address user, uint256 taskId, uint256 reputationPoints, uint256 newReputation);
    event LevelReached(address user, uint256 level);
    event TaskDefined(uint256 taskId, string taskName, uint256 reward);
    event TaskUpdated(uint256 taskId, string taskName, uint256 reward);
    event TaskRemoved(uint256 taskId);
    event RewardSetForLevel(uint256 level, address token, uint256 amount);
    event RewardClaimed(address user, uint256 level, address token, uint256 amount);
    event GovernanceThresholdSet(uint256 threshold);
    event GovernanceProposalCreated(uint256 proposalId, string description, address proposer);
    event GovernanceProposalVoted(uint256 proposalId, address voter, bool support);
    event GovernanceProposalExecuted(uint256 proposalId);
    event GovernanceProposalCancelled(uint256 proposalId);
    event OwnerChanged(address newOwner);
    event TokensWithdrawn(address tokenAddress, address to, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyGovernanceEligible() {
        require(userReputation[msg.sender] >= governanceThreshold, "Not enough reputation for governance.");
        _;
    }

    constructor() {
        owner = msg.sender;
        reputationLevels = [100, 500, 1000, 2500, 5000]; // Example levels
        reputationLevelNames[0] = "Beginner";
        reputationLevelNames[1] = "Intermediate";
        reputationLevelNames[2] = "Advanced";
        reputationLevelNames[3] = "Expert";
        reputationLevelNames[4] = "Master";
        governanceThreshold = 1000; // Example governance threshold
        nextTaskId = 1;
        nextProposalId = 1;
    }

    /**
     * @dev Sets the reputation level thresholds.
     * @param _levels Array of reputation points defining the thresholds for each level.
     * Levels should be in ascending order.
     */
    function setReputationLevels(uint256[] memory _levels) public onlyOwner {
        require(_levels.length > 0, "Levels array cannot be empty.");
        for (uint256 i = 1; i < _levels.length; i++) {
            require(_levels[i] > _levels[i - 1], "Levels must be in ascending order.");
        }
        reputationLevels = _levels;
        // Optionally update level names based on new levels if needed
    }

    /**
     * @dev Defines a new task that users can perform to earn reputation.
     * @param _taskName Name of the task.
     * @param _taskDescription Description of the task.
     * @param _reputationReward Reputation points awarded for completing the task.
     */
    function addTaskDefinition(string memory _taskName, string memory _taskDescription, uint256 _reputationReward) public onlyOwner {
        require(bytes(_taskName).length > 0 && bytes(_taskDescription).length > 0, "Task name and description cannot be empty.");
        require(_reputationReward > 0, "Reputation reward must be positive.");
        taskDefinitions[nextTaskId] = TaskDefinition({
            name: _taskName,
            description: _taskDescription,
            reputationReward: _reputationReward,
            isActive: true
        });
        emit TaskDefined(nextTaskId, _taskName, _reputationReward);
        nextTaskId++;
    }

    /**
     * @dev Updates an existing task definition.
     * @param _taskId ID of the task to update.
     * @param _newTaskName New name for the task.
     * @param _newTaskDescription New description for the task.
     * @param _newReputationReward New reputation reward for the task.
     */
    function updateTaskDefinition(uint256 _taskId, string memory _newTaskName, string memory _newTaskDescription, uint256 _newReputationReward) public onlyOwner {
        require(taskDefinitions[_taskId].isActive, "Task is not active or does not exist.");
        require(bytes(_newTaskName).length > 0 && bytes(_newTaskDescription).length > 0, "Task name and description cannot be empty.");
        require(_newReputationReward > 0, "Reputation reward must be positive.");
        taskDefinitions[_taskId].name = _newTaskName;
        taskDefinitions[_taskId].description = _newTaskDescription;
        taskDefinitions[_taskId].reputationReward = _newReputationReward;
        emit TaskUpdated(_taskId, _newTaskName, _newReputationReward);
    }

    /**
     * @dev Removes a task definition, preventing users from earning reputation from it.
     * @param _taskId ID of the task to remove.
     */
    function removeTaskDefinition(uint256 _taskId) public onlyOwner {
        require(taskDefinitions[_taskId].isActive, "Task is not active or does not exist.");
        taskDefinitions[_taskId].isActive = false; // Soft delete, could also delete entirely if needed
        emit TaskRemoved(_taskId);
    }

    /**
     * @dev Sets a reward (ERC20 token) for reaching a specific reputation level.
     * @param _level Reputation level index (0-based).
     * @param _rewardToken Address of the ERC20 token to be rewarded.
     * @param _rewardAmount Amount of tokens to reward.
     */
    function setRewardForLevel(uint256 _level, address _rewardToken, uint256 _rewardAmount) public onlyOwner {
        require(_level < reputationLevels.length, "Invalid reputation level.");
        require(_rewardToken != address(0), "Reward token address cannot be zero.");
        require(_rewardAmount > 0, "Reward amount must be positive.");
        levelRewards[_level] = LevelReward({
            rewardToken: _rewardToken,
            rewardAmount: _rewardAmount
        });
        emit RewardSetForLevel(_level, _rewardToken, _rewardAmount);
    }

    /**
     * @dev Sets the reputation threshold required to participate in governance proposals.
     * @param _threshold Minimum reputation points needed for governance participation.
     */
    function setGovernanceThreshold(uint256 _threshold) public onlyOwner {
        governanceThreshold = _threshold;
        emit GovernanceThresholdSet(_threshold);
    }

    /**
     * @dev Creates a new governance proposal to modify contract parameters.
     * @param _description Description of the proposal.
     * @param _calldata Encoded function call data to be executed if the proposal passes.
     *  Example: abi.encodeWithSignature("setGovernanceThreshold(uint256)", 1500)
     */
    function createGovernanceProposal(string memory _description, bytes memory _calldata) public onlyGovernanceEligible {
        require(bytes(_description).length > 0 && bytes(_calldata).length > 0, "Description and calldata cannot be empty.");
        require(_calldata.length <= 1024, "Calldata too long (max 1024 bytes)."); // Limit calldata size for gas cost

        governanceProposals[nextProposalId] = GovernanceProposal({
            description: _description,
            proposer: msg.sender,
            calldata: _calldata,
            votingStartTime: block.timestamp,
            votingEndTime: block.timestamp + 7 days, // 7-day voting period
            votesFor: 0,
            votesAgainst: 0,
            isActive: true,
            executed: false
        });
        emit GovernanceProposalCreated(nextProposalId, _description, msg.sender);
        nextProposalId++;
    }

    /**
     * @dev Cancels a governance proposal before the voting period ends. Only the proposer or owner can cancel.
     * @param _proposalId ID of the proposal to cancel.
     */
    function cancelGovernanceProposal(uint256 _proposalId) public {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.isActive, "Proposal is not active.");
        require(block.timestamp < proposal.votingEndTime, "Voting period has ended.");
        require(msg.sender == proposal.proposer || msg.sender == owner, "Only proposer or owner can cancel.");
        proposal.isActive = false;
        emit GovernanceProposalCancelled(_proposalId);
    }

    /**
     * @dev Executes a passed governance proposal, applying the changes to the contract.
     * Can only be called after the voting period ends and if the proposal has passed (more 'for' votes).
     * Any governance eligible user can trigger execution to ensure decentralization.
     * @param _proposalId ID of the proposal to execute.
     */
    function executeGovernanceProposal(uint256 _proposalId) public onlyGovernanceEligible {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.isActive, "Proposal is not active.");
        require(block.timestamp >= proposal.votingEndTime, "Voting period has not ended.");
        require(!proposal.executed, "Proposal already executed.");

        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.executed = true;
            (bool success, ) = address(this).delegatecall(proposal.calldata); // Use delegatecall for contract state change
            require(success, "Governance proposal execution failed.");
            proposal.isActive = false; // Mark as inactive after execution
            emit GovernanceProposalExecuted(_proposalId);
        } else {
            proposal.isActive = false; // Mark as inactive even if rejected
            proposal.executed = false; // Ensure it's marked as not executed
            // Optionally emit an event for proposal rejection
        }
    }

    /**
     * @dev Allows the owner to set a new contract owner.
     * @param _newOwner Address of the new owner.
     */
    function setOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner address cannot be zero.");
        emit OwnerChanged(_newOwner);
        owner = _newOwner;
    }

    /**
     * @dev Allows the owner to withdraw any ERC20 tokens held by the contract.
     * This is an emergency function or for legitimate fund management.
     * @param _tokenAddress Address of the ERC20 token contract.
     * @param _to Address to send the tokens to.
     * @param _amount Amount of tokens to withdraw.
     */
    function withdrawTokens(address _tokenAddress, address _to, uint256 _amount) public onlyOwner {
        require(_tokenAddress != address(0) && _to != address(0) && _amount > 0, "Invalid parameters.");
        IERC20 token = IERC20(_tokenAddress);
        uint256 contractBalance = token.balanceOf(address(this));
        require(contractBalance >= _amount, "Insufficient token balance in contract.");
        bool success = token.transfer(_to, _amount);
        require(success, "Token withdrawal failed.");
        emit TokensWithdrawn(_tokenAddress, _to, _amount);
    }

    /**
     * @dev Allows a user to perform a defined task and earn reputation.
     * @param _taskId ID of the task to perform.
     */
    function performTask(uint256 _taskId) public {
        require(taskDefinitions[_taskId].isActive, "Task is not active or does not exist.");
        uint256 reputationGain = taskDefinitions[_taskId].reputationReward;
        userReputation[msg.sender] += reputationGain;
        emit ReputationEarned(msg.sender, _taskId, reputationGain, userReputation[msg.sender]);

        uint256 currentLevel = getUserLevel(msg.sender);
        uint256 previousReputation = userReputation[msg.sender] - reputationGain;
        uint256 previousLevel = getUserLevel(msg.sender, previousReputation);

        if (currentLevel > previousLevel) {
            emit LevelReached(msg.sender, currentLevel);
        }
    }

    /**
     * @dev Allows a user to claim rewards associated with their current reputation level.
     */
    function claimLevelReward() public {
        uint256 currentLevel = getUserLevel(msg.sender);
        require(currentLevel > 0, "No reward for level 0."); // Assuming level 0 has no reward
        require(levelRewards[currentLevel-1].rewardToken != address(0), "No reward set for this level."); // Rewards are set for levels 0, 1, 2... but levels are displayed as 1, 2, 3...

        LevelReward memory reward = levelRewards[currentLevel-1]; // Get reward based on level index (level 1 reward at index 0, etc.)
        IERC20 token = IERC20(reward.rewardToken);
        uint256 rewardAmount = reward.rewardAmount;

        bool success = token.transfer(msg.sender, rewardAmount);
        require(success, "Reward claim failed.");
        emit RewardClaimed(msg.sender, currentLevel, address(token), rewardAmount);
    }


    /**
     * @dev Retrieves the reputation points of a specific user.
     * @param _user Address of the user.
     * @return User's reputation points.
     */
    function getUserReputation(address _user) public view returns (uint256) {
        return userReputation[_user];
    }

    /**
     * @dev Retrieves the reputation level of a specific user based on their reputation points.
     * @param _user Address of the user.
     * @return User's reputation level (1-based). Returns 0 if below level 1.
     */
    function getUserLevel(address _user) public view returns (uint256) {
        return getUserLevel(_user, userReputation[_user]);
    }

    /**
     * @dev Internal helper function to get user level based on reputation points (allows for previous reputation check).
     * @param _user Address of the user.
     * @param _reputationPoints Reputation points to check level for.
     * @return User's reputation level (1-based). Returns 0 if below level 1.
     */
    function getUserLevel(address _user, uint256 _reputationPoints) internal view returns (uint256) {
        for (uint256 i = 0; i < reputationLevels.length; i++) {
            if (_reputationPoints < reputationLevels[i]) {
                return i; // Level is i+1 (levels are 1-based in UI but 0-indexed in array)
            }
        }
        return reputationLevels.length; // User is at or above the highest level
    }


    /**
     * @dev Retrieves a list of currently active tasks that users can perform.
     * @return Array of active task IDs.
     */
    function getAvailableTasks() public view returns (uint256[] memory) {
        uint256[] memory activeTaskIds = new uint256[](nextTaskId - 1); // Max possible active tasks
        uint256 count = 0;
        for (uint256 i = 1; i < nextTaskId; i++) {
            if (taskDefinitions[i].isActive) {
                activeTaskIds[count] = i;
                count++;
            }
        }
        // Resize the array to the actual number of active tasks
        assembly {
            mstore(activeTaskIds, count)
        }
        return activeTaskIds;
    }

    /**
     * @dev Retrieves a list of active governance proposals.
     * @return Array of active proposal IDs.
     */
    function getGovernanceProposals() public view returns (uint256[] memory) {
        uint256[] memory activeProposalIds = new uint256[](nextProposalId - 1); // Max possible active proposals
        uint256 count = 0;
        for (uint256 i = 1; i < nextProposalId; i++) {
            if (governanceProposals[i].isActive) {
                activeProposalIds[count] = i;
                count++;
            }
        }
        // Resize the array to the actual number of active proposals
        assembly {
            mstore(activeProposalIds, count)
        }
        return activeProposalIds;
    }

    /**
     * @dev Allows users with sufficient reputation to vote on governance proposals.
     * @param _proposalId ID of the proposal to vote on.
     * @param _support True to vote for, false to vote against.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public onlyGovernanceEligible {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.isActive, "Proposal is not active.");
        require(block.timestamp >= proposal.votingStartTime && block.timestamp <= proposal.votingEndTime, "Voting period is not active.");

        // Simple voting mechanism: just increment counts. More advanced voting (quadratic, etc.) can be implemented
        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit GovernanceProposalVoted(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Retrieves details about a specific reputation level.
     * @param _level Level index (0-based).
     * @return Reputation threshold for the level.
     */
    function getReputationLevelDetails(uint256 _level) public view returns (uint256 threshold, string memory levelName) {
        require(_level < reputationLevels.length, "Invalid reputation level.");
        return (reputationLevels[_level], reputationLevelNames[_level]);
    }

    /**
     * @dev Retrieves details about a specific task definition.
     * @param _taskId ID of the task.
     * @return Task name, description, reputation reward, and activity status.
     */
    function getTaskDefinitionDetails(uint256 _taskId) public view returns (string memory name, string memory description, uint256 reputationReward, bool isActive) {
        require(taskDefinitions[_taskId].isActive || !taskDefinitions[_taskId].isActive, "Task does not exist."); // Exists even if not active
        TaskDefinition memory task = taskDefinitions[_taskId];
        return (task.name, task.description, task.reputationReward, task.isActive);
    }

    /**
     * @dev Retrieves reward details for a specific reputation level.
     * @param _level Level index (0-based).
     * @return Reward token address and reward amount. Returns zero address and 0 amount if no reward set.
     */
    function getRewardDetailsForLevel(uint256 _level) public view returns (address rewardToken, uint256 rewardAmount) {
        if (_level < reputationLevels.length && levelRewards[_level].rewardToken != address(0)) {
            return (levelRewards[_level].rewardToken, levelRewards[_level].rewardAmount);
        } else {
            return (address(0), 0);
        }
    }

    /**
     * @dev Retrieves details about a specific governance proposal.
     * @param _proposalId ID of the proposal.
     * @return Proposal description, proposer, voting start and end times, votes for and against, status, and execution status.
     */
    function getGovernanceProposalDetails(uint256 _proposalId) public view returns (
        string memory description,
        address proposer,
        uint256 votingStartTime,
        uint256 votingEndTime,
        uint256 votesFor,
        uint256 votesAgainst,
        ProposalStatus status,
        bool executed
    ) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        ProposalStatus currentStatus;
        if (!proposal.isActive) {
            if (proposal.executed) {
                currentStatus = ProposalStatus.Executed;
            } else {
                currentStatus = ProposalStatus.Cancelled;
            }
        } else if (block.timestamp > proposal.votingEndTime) {
            if (proposal.votesFor > proposal.votesAgainst) {
                currentStatus = ProposalStatus.Passed;
            } else {
                currentStatus = ProposalStatus.Rejected;
            }
        } else {
            currentStatus = ProposalStatus.Active;
        }


        return (
            proposal.description,
            proposal.proposer,
            proposal.votingStartTime,
            proposal.votingEndTime,
            proposal.votesFor,
            proposal.votesAgainst,
            currentStatus,
            proposal.executed
        );
    }

    /**
     * @dev Returns basic information about the contract.
     * @return Contract name and owner address.
     */
    function contractInfo() public view returns (string memory contractName, address contractOwner) {
        return ("DynamicReputationSystem", owner);
    }
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    // Add other ERC20 functions as needed for more complex reward mechanisms
}
```