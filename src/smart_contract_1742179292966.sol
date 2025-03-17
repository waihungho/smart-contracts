```solidity
/**
 * @title Dynamic Reputation and Credentialing System
 * @author Bard (Example Smart Contract - No Duplication of Open Source)
 * @dev A smart contract implementing a dynamic reputation and credentialing system.
 *      This contract allows for the issuance of reputation points and verifiable credentials (badges)
 *      to users based on their actions, contributions, or achievements within a system.
 *      It incorporates role-based access control, action-based reputation/credential rewards,
 *      and governance mechanisms for evolving the system.
 *
 * **Outline and Function Summary:**
 *
 * **1. Core Data Structures:**
 *    - `ReputationPoints`: Mapping to store reputation points for each address.
 *    - `Credentials`: Mapping to store issued credentials (NFT-like) for each address, with metadata.
 *    - `Roles`: Enum to define different roles within the system (Admin, Verifier, Issuer, etc.).
 *    - `RoleAssignments`: Mapping to track role assignments for each address.
 *    - `ActionDefinitions`: Struct to define actions and associated reputation/credential rewards.
 *    - `ActionRegistry`: Mapping to store defined actions.
 *
 * **2. Admin Functions (Controlled Access):**
 *    - `setAdmin(address _newAdmin)`:  Changes the contract administrator.
 *    - `defineRole(uint8 _roleId, string memory _roleName)`: Defines a new role within the system.
 *    - `defineAction(uint256 _actionId, string memory _actionName, uint256 _reputationReward, uint256 _credentialIdReward)`: Defines a new action and its rewards.
 *    - `updateActionReward(uint256 _actionId, uint256 _newReputationReward, uint256 _newCredentialIdReward)`: Updates rewards for an existing action.
 *    - `pauseContract()`: Pauses critical functions of the contract.
 *    - `unpauseContract()`: Resumes paused contract functions.
 *
 * **3. Reputation Management Functions:**
 *    - `grantReputation(address _user, uint256 _amount)`: Grants reputation points to a user (Admin/Issuer role).
 *    - `revokeReputation(address _user, uint256 _amount)`: Revokes reputation points from a user (Admin/Issuer role).
 *    - `transferReputation(address _recipient, uint256 _amount)`: Allows users to transfer reputation points to others.
 *    - `getReputation(address _user)`: Retrieves the reputation points of a user.
 *
 * **4. Credential Management Functions:**
 *    - `issueCredential(address _user, uint256 _credentialId, string memory _credentialUri)`: Issues a credential (badge) to a user (Admin/Issuer role).
 *    - `revokeCredential(address _user, uint256 _credentialId)`: Revokes a credential from a user (Admin/Issuer role).
 *    - `verifyCredential(address _user, uint256 _credentialId)`: Checks if a user holds a specific credential.
 *    - `getCredentialsByOwner(address _user)`: Retrieves a list of credential IDs held by a user.
 *    - `getCredentialDetails(uint256 _credentialId, address _user)`: Retrieves details (URI) of a specific credential held by a user.
 *
 * **5. Role Management Functions:**
 *    - `assignRole(address _user, uint8 _roleId)`: Assigns a role to a user (Admin role).
 *    - `revokeRole(address _user, uint8 _roleId)`: Revokes a role from a user (Admin role).
 *    - `getRolesForUser(address _user)`: Retrieves a list of role IDs assigned to a user.
 *    - `checkRole(address _user, uint8 _roleId)`: Checks if a user has a specific role.
 *
 * **6. Action and Reward Functions:**
 *    - `reportAction(uint256 _actionId, address _user)`: Allows a user (or system) to report an action performed by a user.
 *    - `verifyActionReport(uint256 _actionId, address _user)`: Allows a Verifier role to verify an action report and trigger rewards.
 *    - `getActionReputationReward(uint256 _actionId)`: Retrieves the reputation reward for an action.
 *    - `getActionCredentialReward(uint256 _actionId)`: Retrieves the credential reward for an action.
 *    - `getActionDetails(uint256 _actionId)`: Retrieves details of a defined action.
 *
 * **7. Utility/Info Functions:**
 *    - `isAdmin(address _user)`: Checks if an address is the contract administrator.
 *    - `isContractPaused()`: Checks if the contract is currently paused.
 *    - `contractVersion()`: Returns the contract version.
 */
pragma solidity ^0.8.0;

contract DynamicReputationCredential {

    // --- Core Data Structures ---

    mapping(address => uint256) public reputationPoints; // User address => Reputation Points
    mapping(address => mapping(uint256 => string)) public credentials; // User address => (Credential ID => Credential URI)
    mapping(uint8 => string) public roleDefinitions; // Role ID => Role Name
    mapping(address => mapping(uint8 => bool)) public userRoles; // User address => (Role ID => Has Role)
    mapping(uint256 => ActionDefinition) public actionRegistry; // Action ID => Action Definition

    struct ActionDefinition {
        string actionName;
        uint256 reputationReward;
        uint256 credentialIdReward; // 0 if no credential is rewarded
    }

    // --- Enums ---

    enum Roles {
        ADMIN,
        ISSUER,
        VERIFIER,
        USER // Default role for all addresses initially
    }

    // --- Events ---

    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);
    event RoleDefined(uint8 indexed roleId, string roleName);
    event RoleAssigned(address indexed user, uint8 indexed roleId);
    event RoleRevoked(address indexed user, uint8 indexed roleId);
    event ReputationGranted(address indexed user, uint256 amount);
    event ReputationRevoked(address indexed user, uint256 amount);
    event ReputationTransferred(address indexed from, address indexed to, uint256 amount);
    event CredentialIssued(address indexed user, uint256 indexed credentialId, string credentialUri);
    event CredentialRevoked(address indexed user, uint256 indexed credentialId);
    event ActionDefined(uint256 indexed actionId, string actionName, uint256 reputationReward, uint256 credentialIdReward);
    event ActionRewardUpdated(uint256 indexed actionId, uint256 newReputationReward, uint256 newCredentialIdReward);
    event ActionReported(uint256 indexed actionId, address indexed user);
    event ActionVerified(uint256 indexed actionId, address indexed user, uint256 reputationRewarded, uint256 credentialRewarded);
    event ContractPaused();
    event ContractUnpaused();

    // --- State Variables ---

    address public admin;
    bool public paused;
    uint256 public currentCredentialId = 1; // Starting credential ID, incremented on issue
    uint256 public currentActionId = 1; // Starting action ID, incremented on action definition
    string public version = "1.0.0";

    // --- Modifiers ---

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlyRole(uint8 _roleId) {
        require(userRoles[msg.sender][_roleId], "Sender does not have required role");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    // --- Constructor ---

    constructor() {
        admin = msg.sender;
        emit AdminChanged(address(0), admin);
        // Define default roles (optional, can be done via functions later as well)
        defineRole(uint8(Roles.ADMIN), "Administrator");
        defineRole(uint8(Roles.ISSUER), "Credential Issuer");
        defineRole(uint8(Roles.VERIFIER), "Action Verifier");
        defineRole(uint8(Roles.USER), "User"); // Default role
        assignRole(admin, uint8(Roles.ADMIN)); // Assign Admin role to contract deployer
    }

    // --- 1. Admin Functions ---

    /**
     * @dev Sets a new contract administrator.
     * @param _newAdmin The address of the new administrator.
     */
    function setAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "New admin cannot be zero address");
        emit AdminChanged(admin, _newAdmin);
        admin = _newAdmin;
        assignRole(_newAdmin, uint8(Roles.ADMIN)); // Ensure new admin has admin role
        revokeRole(msg.sender, uint8(Roles.ADMIN)); // Revoke admin role from old admin
    }

    /**
     * @dev Defines a new role in the system.
     * @param _roleId The ID for the role.
     * @param _roleName The name of the role.
     */
    function defineRole(uint8 _roleId, string memory _roleName) public onlyAdmin {
        require(bytes(_roleName).length > 0, "Role name cannot be empty");
        roleDefinitions[_roleId] = _roleName;
        emit RoleDefined(_roleId, _roleName);
    }

    /**
     * @dev Defines a new action with associated reputation and credential rewards.
     * @param _actionId Unique identifier for the action.
     * @param _actionName Name of the action.
     * @param _reputationReward Reputation points awarded for completing the action.
     * @param _credentialIdReward Credential ID awarded for completing the action (0 if no credential).
     */
    function defineAction(uint256 _actionId, string memory _actionName, uint256 _reputationReward, uint256 _credentialIdReward) public onlyAdmin {
        require(bytes(_actionName).length > 0, "Action name cannot be empty");
        require(actionRegistry[_actionId].actionName.length == 0, "Action ID already exists"); // Prevent overwrite
        actionRegistry[_actionId] = ActionDefinition({
            actionName: _actionName,
            reputationReward: _reputationReward,
            credentialIdReward: _credentialIdReward
        });
        emit ActionDefined(_actionId, _actionName, _reputationReward, _credentialIdReward);
    }

    /**
     * @dev Updates the reputation and credential rewards for an existing action.
     * @param _actionId The ID of the action to update.
     * @param _newReputationReward The new reputation reward amount.
     * @param _newCredentialIdReward The new credential ID reward (0 if no credential).
     */
    function updateActionReward(uint256 _actionId, uint256 _newReputationReward, uint256 _newCredentialIdReward) public onlyAdmin {
        require(actionRegistry[_actionId].actionName.length > 0, "Action ID does not exist");
        actionRegistry[_actionId].reputationReward = _newReputationReward;
        actionRegistry[_actionId].credentialIdReward = _newCredentialIdReward;
        emit ActionRewardUpdated(_actionId, _newReputationReward, _newCredentialIdReward);
    }

    /**
     * @dev Pauses the contract, disabling critical functions.
     */
    function pauseContract() public onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /**
     * @dev Unpauses the contract, re-enabling critical functions.
     */
    function unpauseContract() public onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    // --- 2. Reputation Management Functions ---

    /**
     * @dev Grants reputation points to a user.
     * @param _user The address to grant reputation to.
     * @param _amount The amount of reputation points to grant.
     */
    function grantReputation(address _user, uint256 _amount) public onlyRole(uint8(Roles.ISSUER)) whenNotPaused {
        require(_user != address(0), "Invalid user address");
        reputationPoints[_user] += _amount;
        emit ReputationGranted(_user, _amount);
    }

    /**
     * @dev Revokes reputation points from a user.
     * @param _user The address to revoke reputation from.
     * @param _amount The amount of reputation points to revoke.
     */
    function revokeReputation(address _user, uint256 _amount) public onlyRole(uint8(Roles.ISSUER)) whenNotPaused {
        require(_user != address(0), "Invalid user address");
        require(reputationPoints[_user] >= _amount, "Insufficient reputation to revoke");
        reputationPoints[_user] -= _amount;
        emit ReputationRevoked(_user, _amount);
    }

    /**
     * @dev Allows a user to transfer reputation points to another user.
     * @param _recipient The address to receive reputation points.
     * @param _amount The amount of reputation points to transfer.
     */
    function transferReputation(address _recipient, uint256 _amount) public whenNotPaused {
        require(_recipient != address(0), "Invalid recipient address");
        require(reputationPoints[msg.sender] >= _amount, "Insufficient reputation to transfer");
        reputationPoints[msg.sender] -= _amount;
        reputationPoints[_recipient] += _amount;
        emit ReputationTransferred(msg.sender, _recipient, _amount);
    }

    /**
     * @dev Retrieves the reputation points of a user.
     * @param _user The address to query reputation for.
     * @return The reputation points of the user.
     */
    function getReputation(address _user) public view returns (uint256) {
        return reputationPoints[_user];
    }

    // --- 3. Credential Management Functions ---

    /**
     * @dev Issues a credential (badge) to a user.
     * @param _user The address to issue the credential to.
     * @param _credentialId A unique identifier for the credential.
     * @param _credentialUri URI pointing to the credential metadata (e.g., IPFS link).
     */
    function issueCredential(address _user, uint256 _credentialId, string memory _credentialUri) public onlyRole(uint8(Roles.ISSUER)) whenNotPaused {
        require(_user != address(0), "Invalid user address");
        require(bytes(_credentialUri).length > 0, "Credential URI cannot be empty");
        credentials[_user][_credentialId] = _credentialUri;
        emit CredentialIssued(_user, _credentialId, _credentialUri);
    }

    /**
     * @dev Revokes a credential from a user.
     * @param _user The address to revoke the credential from.
     * @param _credentialId The ID of the credential to revoke.
     */
    function revokeCredential(address _user, uint256 _credentialId) public onlyRole(uint8(Roles.ISSUER)) whenNotPaused {
        require(_user != address(0), "Invalid user address");
        require(bytes(credentials[_user][_credentialId]).length > 0, "Credential does not exist for this user");
        delete credentials[_user][_credentialId];
        emit CredentialRevoked(_user, _credentialId);
    }

    /**
     * @dev Checks if a user holds a specific credential.
     * @param _user The address to check for the credential.
     * @param _credentialId The ID of the credential to verify.
     * @return True if the user holds the credential, false otherwise.
     */
    function verifyCredential(address _user, uint256 _credentialId) public view returns (bool) {
        return bytes(credentials[_user][_credentialId]).length > 0;
    }

    /**
     * @dev Retrieves a list of credential IDs held by a user.
     * @param _user The address to query for credentials.
     * @return An array of credential IDs held by the user.
     */
    function getCredentialsByOwner(address _user) public view returns (uint256[] memory) {
        uint256[] memory credentialIds = new uint256[](credentialCount(_user));
        uint256 index = 0;
        for (uint256 i = 1; i < currentCredentialId; i++) { // Iterate through possible credential IDs
            if (bytes(credentials[_user][i]).length > 0) {
                credentialIds[index] = i;
                index++;
            }
        }
        return credentialIds;
    }

    /**
     * @dev Retrieves details (URI) of a specific credential held by a user.
     * @param _credentialId The ID of the credential.
     * @param _user The address of the credential holder.
     * @return The URI of the credential, or an empty string if not found.
     */
    function getCredentialDetails(uint256 _credentialId, address _user) public view returns (string memory) {
        return credentials[_user][_credentialId];
    }

    // --- 4. Role Management Functions ---

    /**
     * @dev Assigns a role to a user.
     * @param _user The address to assign the role to.
     * @param _roleId The ID of the role to assign.
     */
    function assignRole(address _user, uint8 _roleId) public onlyAdmin {
        require(_user != address(0), "Invalid user address");
        userRoles[_user][_roleId] = true;
        emit RoleAssigned(_user, _roleId);
    }

    /**
     * @dev Revokes a role from a user.
     * @param _user The address to revoke the role from.
     * @param _roleId The ID of the role to revoke.
     */
    function revokeRole(address _user, uint8 _roleId) public onlyAdmin {
        require(_user != address(0), "Invalid user address");
        require(userRoles[_user][_roleId], "User does not have this role");
        userRoles[_user][_roleId] = false;
        emit RoleRevoked(_user, _roleId);
    }

    /**
     * @dev Retrieves a list of role IDs assigned to a user.
     * @param _user The address to query for roles.
     * @return An array of role IDs assigned to the user.
     */
    function getRolesForUser(address _user) public view returns (uint8[] memory) {
        uint8[] memory roles = new uint8[](roleCount(_user));
        uint256 index = 0;
        for (uint8 i = 0; i < uint8(type(Roles).max); i++) { // Iterate through possible role IDs
            if (userRoles[_user][i]) {
                roles[index] = i;
                index++;
            }
        }
        return roles;
    }

    /**
     * @dev Checks if a user has a specific role.
     * @param _user The address to check for the role.
     * @param _roleId The ID of the role to check.
     * @return True if the user has the role, false otherwise.
     */
    function checkRole(address _user, uint8 _roleId) public view returns (bool) {
        return userRoles[_user][_roleId];
    }

    // --- 5. Action and Reward Functions ---

    /**
     * @dev Allows a user to report that another user has performed a specific action.
     * @param _actionId The ID of the action performed.
     * @param _user The address of the user who performed the action.
     */
    function reportAction(uint256 _actionId, address _user) public whenNotPaused {
        require(_user != address(0), "Invalid user address");
        require(actionRegistry[_actionId].actionName.length > 0, "Action ID not defined");
        // In a real-world system, you might add checks to prevent spam reporting,
        // ensure action is valid within context, etc.
        emit ActionReported(_actionId, _user);
        // Verification process would follow, potentially off-chain or via another contract call
    }

    /**
     * @dev Allows a Verifier role to verify an action report and trigger reputation/credential rewards.
     * @param _actionId The ID of the action that was reported.
     * @param _user The address of the user who performed the action and is being verified.
     */
    function verifyActionReport(uint256 _actionId, address _user) public onlyRole(uint8(Roles.VERIFIER)) whenNotPaused {
        require(_user != address(0), "Invalid user address");
        require(actionRegistry[_actionId].actionName.length > 0, "Action ID not defined");

        uint256 reputationReward = actionRegistry[_actionId].reputationReward;
        uint256 credentialIdReward = actionRegistry[_actionId].credentialIdReward;

        if (reputationReward > 0) {
            reputationPoints[_user] += reputationReward;
            emit ReputationGranted(_user, reputationReward);
        }
        if (credentialIdReward > 0) {
            issueCredential(_user, credentialIdReward, "ipfs://default-credential-uri/" ); // Replace with dynamic URI logic if needed
            emit CredentialIssued(_user, credentialIdReward, "ipfs://default-credential-uri/");
        }
        emit ActionVerified(_actionId, _user, reputationReward, credentialIdReward);
    }

    /**
     * @dev Retrieves the reputation reward for a given action ID.
     * @param _actionId The ID of the action.
     * @return The reputation points reward for the action.
     */
    function getActionReputationReward(uint256 _actionId) public view returns (uint256) {
        return actionRegistry[_actionId].reputationReward;
    }

    /**
     * @dev Retrieves the credential ID reward for a given action ID.
     * @param _actionId The ID of the action.
     * @return The credential ID rewarded for the action (0 if no credential).
     */
    function getActionCredentialReward(uint256 _actionId) public view returns (uint256) {
        return actionRegistry[_actionId].credentialIdReward;
    }

    /**
     * @dev Retrieves details of a defined action.
     * @param _actionId The ID of the action.
     * @return ActionDefinition struct containing action details.
     */
    function getActionDetails(uint256 _actionId) public view returns (ActionDefinition memory) {
        return actionRegistry[_actionId];
    }

    // --- 6. Utility/Info Functions ---

    /**
     * @dev Checks if an address is the contract administrator.
     * @param _user The address to check.
     * @return True if the address is the admin, false otherwise.
     */
    function isAdmin(address _user) public view returns (bool) {
        return _user == admin;
    }

    /**
     * @dev Checks if the contract is currently paused.
     * @return True if the contract is paused, false otherwise.
     */
    function isContractPaused() public view returns (bool) {
        return paused;
    }

    /**
     * @dev Returns the contract version string.
     * @return The contract version.
     */
    function contractVersion() public view returns (string memory) {
        return version;
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Internal helper function to count credentials for a user.
     * @param _user The address to count credentials for.
     * @return The number of credentials held by the user.
     */
    function credentialCount(address _user) internal view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 1; i < currentCredentialId; i++) { // Iterate through possible credential IDs
            if (bytes(credentials[_user][i]).length > 0) {
                count++;
            }
        }
        return count;
    }

    /**
     * @dev Internal helper function to count roles for a user.
     * @param _user The address to count roles for.
     * @return The number of roles assigned to the user.
     */
    function roleCount(address _user) internal view returns (uint256) {
        uint256 count = 0;
        for (uint8 i = 0; i < uint8(type(Roles).max); i++) {
            if (userRoles[_user][i]) {
                count++;
            }
        }
        return count;
    }
}
```