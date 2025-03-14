```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic Reputation & Task Management Contract
 * @author Gemini AI Assistant
 * @dev A smart contract for managing reputation, tasks, and dynamic roles within a decentralized community or organization.
 *
 * **Outline & Function Summary:**
 *
 * **1. Reputation Management:**
 *    - `increaseReputation(address _user, uint256 _amount)`: Increases the reputation of a user. (Requires admin role)
 *    - `decreaseReputation(address _user, uint256 _amount)`: Decreases the reputation of a user. (Requires admin role)
 *    - `getReputation(address _user)`: Retrieves the reputation score of a user.
 *    - `setReputationThresholdForRole(string memory _roleName, uint256 _threshold)`: Sets the reputation threshold required for a specific role. (Requires admin role)
 *    - `getReputationThresholdForRole(string memory _roleName)`: Retrieves the reputation threshold for a given role.
 *
 * **2. Dynamic Role Assignment based on Reputation:**
 *    - `assignRoleBasedOnReputation(address _user)`: Automatically assigns roles to a user based on their reputation and defined thresholds.
 *    - `getUserRoles(address _user)`: Retrieves the roles assigned to a user.
 *    - `hasRole(address _user, string memory _roleName)`: Checks if a user has a specific role.
 *    - `removeRole(address _user, string memory _roleName)`: Manually removes a role from a user. (Requires admin or role manager)
 *
 * **3. Task Management & Reward System:**
 *    - `createTask(string memory _taskName, string memory _description, uint256 _reward, string[] memory _requiredRoles)`: Creates a new task with rewards and role requirements. (Requires task creator role)
 *    - `submitTaskCompletion(uint256 _taskId)`: Allows a user to submit a task for completion.
 *    - `approveTaskCompletion(uint256 _taskId, address _completer)`: Approves a task completion, rewarding the user and potentially increasing reputation. (Requires task reviewer role)
 *    - `rejectTaskCompletion(uint256 _taskId, address _completer)`: Rejects a task completion. (Requires task reviewer role)
 *    - `getTaskDetails(uint256 _taskId)`: Retrieves details of a specific task.
 *    - `getAvailableTasksForUser(address _user)`: Retrieves tasks available for a user based on their roles.
 *
 * **4. Reputation-Gated Features (Example - Voting Power):**
 *    - `getVotingPower(address _user)`: Calculates voting power based on reputation (example of reputation utility).
 *
 * **5.  Role Delegation & Management:**
 *    - `delegateRole(address _delegatee, string memory _roleName)`: Allows a role holder to temporarily delegate their role to another user.
 *    - `revokeDelegatedRole(address _delegatee, string memory _roleName)`: Revokes a delegated role.
 *    - `getDelegatedRoleDetails(address _delegatee, string memory _roleName)`: Retrieves details of a delegated role.
 *
 * **6.  Admin & Configuration:**
 *    - `addRoleManager(address _roleManager)`: Adds an address as a role manager. (Requires contract owner)
 *    - `removeRoleManager(address _roleManager)`: Removes an address from role managers. (Requires contract owner)
 *    - `isAdmin(address _user)`: Checks if an address is an admin.
 *    - `isRoleManager(address _user)`: Checks if an address is a role manager.
 *    - `pauseContract()`: Pauses the contract functionalities (emergency stop). (Requires contract owner)
 *    - `unpauseContract()`: Resumes the contract functionalities. (Requires contract owner)
 */

contract DynamicReputationTaskManagement {
    address public owner;
    bool public paused;

    mapping(address => uint256) public reputation;
    mapping(string => uint256) public roleReputationThresholds;
    mapping(address => mapping(string => bool)) public userRoles;
    mapping(address => mapping(string => Delegation)) public roleDelegations;
    mapping(address => bool) public roleManagers;

    uint256 public taskCount;
    mapping(uint256 => Task) public tasks;
    mapping(uint256 => mapping(address => TaskSubmissionStatus)) public taskSubmissions;

    string[] public availableRoles = ["Admin", "RoleManager", "TaskCreator", "TaskReviewer", "CommunityMember"]; // Example Roles

    struct Task {
        uint256 id;
        string name;
        string description;
        uint256 reward;
        string[] requiredRoles;
        address creator;
        bool isActive;
    }

    enum TaskSubmissionStatus {
        Pending,
        Approved,
        Rejected
    }

    struct Delegation {
        address delegator;
        uint256 delegationStartTime;
        uint256 delegationEndTime; // 0 for indefinite
        bool isActive;
    }


    event ReputationIncreased(address indexed user, uint256 amount, uint256 newReputation);
    event ReputationDecreased(address indexed user, uint256 amount, uint256 newReputation);
    event RoleAssigned(address indexed user, string roleName);
    event RoleRemoved(address indexed user, string roleName);
    event RoleThresholdSet(string roleName, uint256 threshold);
    event TaskCreated(uint256 taskId, string taskName, address creator);
    event TaskSubmitted(uint256 taskId, address completer);
    event TaskCompletionApproved(uint256 taskId, address completer);
    event TaskCompletionRejected(uint256 taskId, address completer);
    event RoleDelegated(address indexed delegatee, string roleName, address delegator);
    event RoleDelegationRevoked(address indexed delegatee, string roleName);
    event ContractPaused();
    event ContractUnpaused();
    event RoleManagerAdded(address indexed roleManager);
    event RoleManagerRemoved(address indexed roleManager);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyRoleManager() {
        require(msg.sender == owner || roleManagers[msg.sender], "Only owner or role manager can call this function.");
        _;
    }

    modifier onlyAdminRole() {
        require(hasRole(msg.sender, "Admin"), "Must have Admin role.");
        _;
    }

    modifier onlyRole(string memory _roleName) {
        require(hasRole(msg.sender, _roleName), string.concat("Must have ", _roleName));
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
        owner = msg.sender;
        roleManagers[owner] = true; // Owner is also a role manager by default
        _assignRole(owner, "Admin"); // Owner gets Admin role initially
        _assignRole(owner, "RoleManager"); // Owner gets RoleManager role initially
    }

    // -------------------- 1. Reputation Management --------------------

    function increaseReputation(address _user, uint256 _amount) external onlyAdminRole whenNotPaused {
        reputation[_user] += _amount;
        emit ReputationIncreased(_user, _amount, reputation[_user]);
        assignRoleBasedOnReputation(_user); // Check and assign roles after reputation change
    }

    function decreaseReputation(address _user, uint256 _amount) external onlyAdminRole whenNotPaused {
        require(reputation[_user] >= _amount, "Reputation cannot be negative.");
        reputation[_user] -= _amount;
        emit ReputationDecreased(_user, _amount, reputation[_user]);
        assignRoleBasedOnReputation(_user); // Check and adjust roles after reputation change
    }

    function getReputation(address _user) external view returns (uint256) {
        return reputation[_user];
    }

    function setReputationThresholdForRole(string memory _roleName, uint256 _threshold) external onlyAdminRole whenNotPaused {
        roleReputationThresholds[_roleName] = _threshold;
        emit RoleThresholdSet(_roleName, _threshold);
    }

    function getReputationThresholdForRole(string memory _roleName) external view returns (uint256) {
        return roleReputationThresholds[_roleName];
    }

    // -------------------- 2. Dynamic Role Assignment based on Reputation --------------------

    function assignRoleBasedOnReputation(address _user) public whenNotPaused {
        for (uint256 i = 0; i < availableRoles.length; i++) {
            string memory roleName = availableRoles[i];
            uint256 threshold = getReputationThresholdForRole(roleName);
            if (threshold > 0 && reputation[_user] >= threshold && !hasRole(_user, roleName) && keccak256(bytes(roleName)) != keccak256(bytes("Admin"))) { // Don't auto-assign Admin
                _assignRole(_user, roleName);
            } else if (threshold > 0 && reputation[_user] < threshold && hasRole(_user, roleName) && keccak256(bytes(roleName)) != keccak256(bytes("Admin")) && keccak256(bytes(roleName)) != keccak256(bytes("RoleManager"))) { // Don't auto-remove Admin or RoleManager
                _removeRole(_user, roleName);
            }
        }
    }

    function getUserRoles(address _user) external view returns (string[] memory) {
        string[] memory roles = new string[](availableRoles.length);
        uint256 roleCount = 0;
        for (uint256 i = 0; i < availableRoles.length; i++) {
            if (userRoles[_user][availableRoles[i]]) {
                roles[roleCount] = availableRoles[i];
                roleCount++;
            }
        }
        string[] memory userRoleList = new string[](roleCount);
        for (uint256 i = 0; i < roleCount; i++) {
            userRoleList[i] = roles[i];
        }
        return userRoleList;
    }

    function hasRole(address _user, string memory _roleName) public view returns (bool) {
        if (roleDelegations[_user][_roleName].isActive) {
            Delegation storage delegation = roleDelegations[_user][_roleName];
            if (delegation.delegationEndTime == 0 || block.timestamp <= delegation.delegationEndTime) {
                return true; // Delegated role is active and valid
            } else {
                return false; // Delegation expired
            }
        }
        return userRoles[_user][_roleName];
    }

    function removeRole(address _user, string memory _roleName) external onlyRoleManager whenNotPaused {
        _removeRole(_user, _roleName);
    }

    function _assignRole(address _user, string memory _roleName) private {
        if (!userRoles[_user][_roleName]) {
            userRoles[_user][_roleName] = true;
            emit RoleAssigned(_user, _roleName);
        }
    }

    function _removeRole(address _user, string memory _roleName) private {
        if (userRoles[_user][_roleName]) {
            userRoles[_user][_roleName] = false;
            emit RoleRemoved(_user, _roleName);
        }
    }


    // -------------------- 3. Task Management & Reward System --------------------

    function createTask(string memory _taskName, string memory _description, uint256 _reward, string[] memory _requiredRoles) external onlyRole("TaskCreator") whenNotPaused {
        taskCount++;
        tasks[taskCount] = Task({
            id: taskCount,
            name: _taskName,
            description: _description,
            reward: _reward,
            requiredRoles: _requiredRoles,
            creator: msg.sender,
            isActive: true
        });
        emit TaskCreated(taskCount, _taskName, msg.sender);
    }

    function submitTaskCompletion(uint256 _taskId) external whenNotPaused {
        require(tasks[_taskId].isActive, "Task is not active.");
        require(taskSubmissions[_taskId][msg.sender] == TaskSubmissionStatus.Pending || taskSubmissions[_taskId][msg.sender] == TaskSubmissionStatus.Rejected, "Task already submitted or finalized."); // Allow resubmission after rejection
        require(_isUserEligibleForTask(msg.sender, _taskId), "User is not eligible for this task.");

        taskSubmissions[_taskId][msg.sender] = TaskSubmissionStatus.Pending;
        emit TaskSubmitted(_taskId, msg.sender);
    }

    function approveTaskCompletion(uint256 _taskId, address _completer) external onlyRole("TaskReviewer") whenNotPaused {
        require(tasks[_taskId].isActive, "Task is not active.");
        require(taskSubmissions[_taskId][_completer] == TaskSubmissionStatus.Pending, "Submission is not pending.");

        taskSubmissions[_taskId][_completer] = TaskSubmissionStatus.Approved;
        _rewardUserForTask(_completer, tasks[_taskId].reward);
        increaseReputation(_completer, tasks[_taskId].reward / 10); // Example: Reputation increase based on reward
        emit TaskCompletionApproved(_taskId, _completer);
    }

    function rejectTaskCompletion(uint256 _taskId, address _completer) external onlyRole("TaskReviewer") whenNotPaused {
        require(tasks[_taskId].isActive, "Task is not active.");
        require(taskSubmissions[_taskId][_completer] == TaskSubmissionStatus.Pending, "Submission is not pending.");

        taskSubmissions[_taskId][_completer] = TaskSubmissionStatus.Rejected;
        emit TaskCompletionRejected(_taskId, _completer);
    }

    function getTaskDetails(uint256 _taskId) external view returns (Task memory) {
        return tasks[_taskId];
    }

    function getAvailableTasksForUser(address _user) external view returns (uint256[] memory) {
        uint256[] memory availableTaskIds = new uint256[](taskCount);
        uint256 count = 0;
        for (uint256 i = 1; i <= taskCount; i++) {
            if (tasks[i].isActive && _isUserEligibleForTask(_user, i)) {
                availableTaskIds[count] = i;
                count++;
            }
        }
        uint256[] memory resultTaskIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            resultTaskIds[i] = availableTaskIds[i];
        }
        return resultTaskIds;
    }

    function _isUserEligibleForTask(address _user, uint256 _taskId) private view returns (bool) {
        string[] memory requiredRoles = tasks[_taskId].requiredRoles;
        if (requiredRoles.length == 0) return true; // No role requirements, everyone is eligible

        for (uint256 i = 0; i < requiredRoles.length; i++) {
            if (hasRole(_user, requiredRoles[i])) {
                return true; // User has at least one required role
            }
        }
        return false; // User does not have any of the required roles
    }

    function _rewardUserForTask(address _user, uint256 _reward) private {
        payable(_user).transfer(_reward); // Simple reward in ETH. Could be tokens in a real-world scenario.
    }

    // -------------------- 4. Reputation-Gated Features (Example - Voting Power) --------------------

    function getVotingPower(address _user) external view returns (uint256) {
        // Example: Voting power increases linearly with reputation, with a base power of 1.
        return 1 + (reputation[_user] / 100); // Adjust the divisor for sensitivity
    }

    // -------------------- 5. Role Delegation & Management --------------------

    function delegateRole(address _delegatee, string memory _roleName, uint256 _durationInSeconds) external onlyRole(_roleName) whenNotPaused {
        require(!roleDelegations[_delegatee][_roleName].isActive, "Role already delegated to this user.");
        roleDelegations[_delegatee][_roleName] = Delegation({
            delegator: msg.sender,
            delegationStartTime: block.timestamp,
            delegationEndTime: block.timestamp + _durationInSeconds,
            isActive: true
        });
        emit RoleDelegated(_delegatee, _roleName, msg.sender);
    }

    function delegateRoleIndefinite(address _delegatee, string memory _roleName) external onlyRole(_roleName) whenNotPaused {
        require(!roleDelegations[_delegatee][_roleName].isActive, "Role already delegated to this user.");
        roleDelegations[_delegatee][_roleName] = Delegation({
            delegator: msg.sender,
            delegationStartTime: block.timestamp,
            delegationEndTime: 0, // 0 for indefinite delegation
            isActive: true
        });
        emit RoleDelegated(_delegatee, _roleName, msg.sender);
    }


    function revokeDelegatedRole(address _delegatee, string memory _roleName) external onlyRole(_roleName) whenNotPaused {
        require(roleDelegations[_delegatee][_roleName].isActive, "Role delegation is not active.");
        require(roleDelegations[_delegatee][_roleName].delegator == msg.sender, "Only delegator can revoke.");

        roleDelegations[_delegatee][_roleName].isActive = false;
        emit RoleDelegationRevoked(_delegatee, _roleName);
    }

    function getDelegatedRoleDetails(address _delegatee, string memory _roleName) external view returns (Delegation memory) {
        return roleDelegations[_delegatee][_roleName];
    }


    // -------------------- 6. Admin & Configuration --------------------

    function addRoleManager(address _roleManager) external onlyOwner whenNotPaused {
        roleManagers[_roleManager] = true;
        emit RoleManagerAdded(_roleManager);
    }

    function removeRoleManager(address _roleManager) external onlyOwner whenNotPaused {
        require(_roleManager != owner, "Cannot remove contract owner as role manager.");
        delete roleManagers[_roleManager];
        emit RoleManagerRemoved(_roleManager);
    }

    function isAdmin(address _user) external view returns (bool) {
        return hasRole(_user, "Admin");
    }

    function isRoleManager(address _user) external view returns (bool) {
        return roleManagers[_user];
    }

    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    // Fallback function to receive ETH for task rewards
    receive() external payable {}
}
```