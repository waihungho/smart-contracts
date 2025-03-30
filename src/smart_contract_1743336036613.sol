```solidity
pragma solidity ^0.8.0;

/**
 * @title Dynamic Reputation and Influence System (DRIS)
 * @author Gemini AI (Conceptual Contract)
 * @notice A smart contract for managing decentralized reputation and influence within a community.
 *
 * **Outline:**
 *
 * **I. Core Profile and Reputation Management:**
 *    1. `createProfile(string _username, string _metadataURI)`: Allows users to create profiles with usernames and metadata.
 *    2. `updateProfileMetadata(uint256 _profileId, string _newMetadataURI)`: Allows users to update their profile metadata.
 *    3. `getUsername(uint256 _profileId)`: Retrieves the username associated with a profile ID.
 *    4. `getProfileMetadataURI(uint256 _profileId)`: Retrieves the metadata URI for a profile.
 *    5. `getReputation(uint256 _profileId)`: Retrieves the reputation score of a profile.
 *    6. `increaseReputation(uint256 _profileId, uint256 _amount)`: Increases the reputation score of a profile (Admin/DAO controlled).
 *    7. `decreaseReputation(uint256 _profileId, uint256 _amount)`: Decreases the reputation score of a profile (Admin/DAO controlled).
 *    8. `transferReputation(uint256 _fromProfileId, uint256 _toProfileId, uint256 _amount)`: Allows transferring reputation between profiles (Potentially limited or gated).
 *    9. `burnReputation(uint256 _profileId, uint256 _amount)`: Allows users to burn their own reputation for specific actions or perks.
 *
 * **II. Influence and Role-Based Features:**
 *    10. `assignRole(uint256 _profileId, string _roleName)`: Assigns a specific role to a profile (Admin/DAO controlled).
 *    11. `revokeRole(uint256 _profileId, string _roleName)`: Revokes a role from a profile (Admin/DAO controlled).
 *    12. `hasRole(uint256 _profileId, string _roleName)`: Checks if a profile has a specific role.
 *    13. `getProfilesByRole(string _roleName)`: Retrieves a list of profile IDs that have a specific role.
 *    14. `delegateInfluence(uint256 _delegatorProfileId, uint256 _delegateeProfileId, uint256 _influencePoints)`: Allows users to delegate a portion of their influence to another profile.
 *    15. `getDelegatedInfluence(uint256 _profileId)`: Retrieves the total influence delegated to a profile.
 *    16. `withdrawDelegatedInfluence(uint256 _delegateeProfileId, uint256 _amount)`: Allows a delegatee to withdraw delegated influence (if applicable, based on rules).
 *
 * **III. Reputation-Gated Actions and Perks:**
 *    17. `setActionReputationGate(string _actionName, uint256 _requiredReputation)`: Sets a reputation requirement for performing a specific action. (Admin/DAO controlled).
 *    18. `getActionReputationGate(string _actionName)`: Retrieves the reputation requirement for a specific action.
 *    19. `checkReputationGate(uint256 _profileId, string _actionName)`: Checks if a profile meets the reputation requirement for an action.
 *    20. `claimPerk(uint256 _profileId, string _perkName)`: Allows users to claim perks if they meet reputation or role requirements (Perk logic needs further definition - could trigger external calls, token transfers etc. -  simplified here).
 *
 * **IV. Governance and Admin Functions:**
 *    21. `setAdmin(address _newAdmin)`: Changes the admin address. (Only current admin).
 *    22. `isAdmin(address _account)`: Checks if an address is the admin.
 *
 * **Function Summary:**
 * This contract provides a comprehensive system for managing user profiles, reputation scores, roles, and influence within a decentralized community. It allows for reputation to be earned, potentially transferred or burned, and used to gate access to actions or claim perks. Influence delegation adds another layer of community interaction.  Admin and DAO control mechanisms are included for managing reputation and roles.
 */

contract DynamicReputationProfile {

    // ** State Variables **

    address public admin; // Admin address for privileged functions
    uint256 public profileCounter; // Counter for profile IDs

    struct Profile {
        address owner;          // Address of the profile owner
        string username;         // User-defined username
        string metadataURI;      // URI pointing to profile metadata (off-chain)
        uint256 reputation;      // Reputation score
    }

    mapping(uint256 => Profile) public profiles; // Mapping from profile ID to Profile struct
    mapping(address => uint256) public addressToProfileId; // Mapping from address to profile ID for easy lookup
    mapping(uint256 => mapping(string => bool)) public profileRoles; // Mapping for profile roles (profileId => roleName => hasRole)
    mapping(string => uint256) public actionReputationGates; // Mapping for action reputation gates (actionName => requiredReputation)
    mapping(uint256 => mapping(uint256 => uint256)) public delegatedInfluence; // Mapping for delegated influence (delegatorProfileId => delegateeProfileId => amount)
    mapping(uint256 => uint256) public receivedDelegatedInfluence; // Mapping for total received delegated influence (delegateeProfileId => total amount)
    mapping(string => uint256[]) public profilesByRole; // Mapping to list profiles by role (roleName => array of profileIds)


    // ** Events **

    event ProfileCreated(uint256 profileId, address owner, string username);
    event ProfileMetadataUpdated(uint256 profileId, string newMetadataURI);
    event ReputationIncreased(uint256 profileId, uint256 amount, address indexed by);
    event ReputationDecreased(uint256 profileId, uint256 amount, address indexed by);
    event ReputationTransferred(uint256 fromProfileId, uint256 toProfileId, uint256 amount);
    event ReputationBurned(uint256 profileId, uint256 amount);
    event RoleAssigned(uint256 profileId, string roleName, address indexed by);
    event RoleRevoked(uint256 profileId, string roleName, address indexed by);
    event InfluenceDelegated(uint256 delegatorProfileId, uint256 delegateeProfileId, uint256 amount);
    event InfluenceWithdrawn(uint256 delegateeProfileId, uint256 amount);
    event ActionReputationGateSet(string actionName, uint256 requiredReputation, address indexed by);
    event PerkClaimed(uint256 profileId, string perkName);
    event AdminChanged(address newAdmin, address indexed by);


    // ** Modifiers **

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier profileExists(uint256 _profileId) {
        require(profiles[_profileId].owner != address(0), "Profile does not exist.");
        _;
    }

    modifier onlyProfileOwner(uint256 _profileId) {
        require(profiles[_profileId].owner == msg.sender, "Only profile owner can call this.");
        _;
    }

    modifier reputationSufficient(uint256 _profileId, string _actionName) {
        uint256 requiredReputation = actionReputationGates[_actionName];
        require(getReputation(_profileId) >= requiredReputation, "Insufficient reputation for this action.");
        _;
    }


    // ** Constructor **

    constructor() {
        admin = msg.sender; // Set contract deployer as initial admin
        profileCounter = 1; // Start profile IDs from 1
    }


    // ** I. Core Profile and Reputation Management Functions **

    /**
     * @dev Creates a new user profile.
     * @param _username The desired username for the profile.
     * @param _metadataURI URI pointing to off-chain profile metadata (e.g., IPFS).
     */
    function createProfile(string memory _username, string memory _metadataURI) public {
        require(addressToProfileId[msg.sender] == 0, "Profile already exists for this address.");
        require(bytes(_username).length > 0 && bytes(_username).length <= 32, "Username must be between 1 and 32 characters."); // Basic username validation - can be more robust

        uint256 newProfileId = profileCounter;
        profiles[newProfileId] = Profile({
            owner: msg.sender,
            username: _username,
            metadataURI: _metadataURI,
            reputation: 0 // Initial reputation is 0
        });
        addressToProfileId[msg.sender] = newProfileId;
        profileCounter++;

        emit ProfileCreated(newProfileId, msg.sender, _username);
    }

    /**
     * @dev Updates the metadata URI of an existing profile.
     * @param _profileId The ID of the profile to update.
     * @param _newMetadataURI The new metadata URI.
     */
    function updateProfileMetadata(uint256 _profileId, string memory _newMetadataURI) public profileExists(_profileId) onlyProfileOwner(_profileId) {
        profiles[_profileId].metadataURI = _newMetadataURI;
        emit ProfileMetadataUpdated(_profileId, _newMetadataURI);
    }

    /**
     * @dev Retrieves the username associated with a profile ID.
     * @param _profileId The ID of the profile.
     * @return The username of the profile.
     */
    function getUsername(uint256 _profileId) public view profileExists(_profileId) returns (string memory) {
        return profiles[_profileId].username;
    }

    /**
     * @dev Retrieves the metadata URI of a profile.
     * @param _profileId The ID of the profile.
     * @return The metadata URI of the profile.
     */
    function getProfileMetadataURI(uint256 _profileId) public view profileExists(_profileId) returns (string memory) {
        return profiles[_profileId].metadataURI;
    }

    /**
     * @dev Retrieves the reputation score of a profile.
     * @param _profileId The ID of the profile.
     * @return The reputation score.
     */
    function getReputation(uint256 _profileId) public view profileExists(_profileId) returns (uint256) {
        return profiles[_profileId].reputation;
    }

    /**
     * @dev Increases the reputation score of a profile. (Admin/DAO controlled function)
     * @param _profileId The ID of the profile to increase reputation for.
     * @param _amount The amount of reputation to increase.
     */
    function increaseReputation(uint256 _profileId, uint256 _amount) public onlyAdmin profileExists(_profileId) {
        profiles[_profileId].reputation += _amount;
        emit ReputationIncreased(_profileId, _amount, msg.sender);
    }

    /**
     * @dev Decreases the reputation score of a profile. (Admin/DAO controlled function)
     * @param _profileId The ID of the profile to decrease reputation for.
     * @param _amount The amount of reputation to decrease.
     */
    function decreaseReputation(uint256 _profileId, uint256 _amount) public onlyAdmin profileExists(_profileId) {
        profiles[_profileId].reputation -= _amount;
        emit ReputationDecreased(_profileId, _amount, msg.sender);
    }

    /**
     * @dev Allows transferring reputation between profiles. (Potentially gated or limited logic can be added)
     * @param _fromProfileId The ID of the profile sending reputation.
     * @param _toProfileId The ID of the profile receiving reputation.
     * @param _amount The amount of reputation to transfer.
     */
    function transferReputation(uint256 _fromProfileId, uint256 _toProfileId, uint256 _amount) public profileExists(_fromProfileId) profileExists(_toProfileId) onlyProfileOwner(_fromProfileId) {
        require(_fromProfileId != _toProfileId, "Cannot transfer reputation to self.");
        require(profiles[_fromProfileId].reputation >= _amount, "Insufficient reputation to transfer.");

        profiles[_fromProfileId].reputation -= _amount;
        profiles[_toProfileId].reputation += _amount;
        emit ReputationTransferred(_fromProfileId, _toProfileId, _amount);
    }

    /**
     * @dev Allows users to burn their own reputation. (For specific actions or perks - perk logic is simplified here)
     * @param _profileId The ID of the profile burning reputation.
     * @param _amount The amount of reputation to burn.
     */
    function burnReputation(uint256 _profileId, uint256 _amount) public profileExists(_profileId) onlyProfileOwner(_profileId) {
        require(profiles[_profileId].reputation >= _amount, "Insufficient reputation to burn.");
        profiles[_profileId].reputation -= _amount;
        emit ReputationBurned(_profileId, _amount);
        // Add logic here for what happens when reputation is burned (e.g., trigger a perk, update UI, etc.)
        // Example:  claimPerkInternal(_profileId, "BurnPerk"); // Internal function for perk logic
    }


    // ** II. Influence and Role-Based Features Functions **

    /**
     * @dev Assigns a role to a profile. (Admin/DAO controlled function)
     * @param _profileId The ID of the profile to assign the role to.
     * @param _roleName The name of the role to assign (e.g., "Moderator", "Contributor").
     */
    function assignRole(uint256 _profileId, string memory _roleName) public onlyAdmin profileExists(_profileId) {
        require(bytes(_roleName).length > 0 && bytes(_roleName).length <= 32, "Role name must be between 1 and 32 characters.");
        if (!profileRoles[_profileId][_roleName]) { // Prevent duplicate role assignments
            profileRoles[_profileId][_roleName] = true;
            profilesByRole[_roleName].push(_profileId);
            emit RoleAssigned(_profileId, _roleName, msg.sender);
        }
    }

    /**
     * @dev Revokes a role from a profile. (Admin/DAO controlled function)
     * @param _profileId The ID of the profile to revoke the role from.
     * @param _roleName The name of the role to revoke.
     */
    function revokeRole(uint256 _profileId, string memory _roleName) public onlyAdmin profileExists(_profileId) {
        if (profileRoles[_profileId][_roleName]) {
            profileRoles[_profileId][_roleName] = false;
            // Remove profileId from profilesByRole array (more complex - can optimize if needed for gas)
            uint256[] storage roleProfiles = profilesByRole[_roleName];
            for (uint256 i = 0; i < roleProfiles.length; i++) {
                if (roleProfiles[i] == _profileId) {
                    roleProfiles[i] = roleProfiles[roleProfiles.length - 1]; // Move last element to current position
                    roleProfiles.pop(); // Remove last element (now duplicate)
                    break;
                }
            }
            emit RoleRevoked(_profileId, _roleName, msg.sender);
        }
    }

    /**
     * @dev Checks if a profile has a specific role.
     * @param _profileId The ID of the profile to check.
     * @param _roleName The name of the role to check for.
     * @return True if the profile has the role, false otherwise.
     */
    function hasRole(uint256 _profileId, string memory _roleName) public view profileExists(_profileId) returns (bool) {
        return profileRoles[_profileId][_roleName];
    }

    /**
     * @dev Retrieves a list of profile IDs that have a specific role.
     * @param _roleName The name of the role to search for.
     * @return An array of profile IDs with the given role.
     */
    function getProfilesByRole(string memory _roleName) public view returns (uint256[] memory) {
        return profilesByRole[_roleName];
    }

    /**
     * @dev Allows a user to delegate a portion of their influence (represented by reputation) to another profile.
     * @param _delegatorProfileId The ID of the profile delegating influence.
     * @param _delegateeProfileId The ID of the profile receiving delegated influence.
     * @param _influencePoints The amount of influence points (reputation) to delegate.
     */
    function delegateInfluence(uint256 _delegatorProfileId, uint256 _delegateeProfileId, uint256 _influencePoints) public profileExists(_delegatorProfileId) profileExists(_delegateeProfileId) onlyProfileOwner(_delegatorProfileId) {
        require(_delegatorProfileId != _delegateeProfileId, "Cannot delegate influence to self.");
        require(profiles[_delegatorProfileId].reputation >= _influencePoints, "Insufficient reputation to delegate.");
        require(_influencePoints > 0, "Delegation amount must be positive.");

        delegatedInfluence[_delegatorProfileId][_delegateeProfileId] += _influencePoints;
        receivedDelegatedInfluence[_delegateeProfileId] += _influencePoints;
        profiles[_delegatorProfileId].reputation -= _influencePoints; // Delegated influence reduces delegator's current visible reputation (conceptually)
        emit InfluenceDelegated(_delegatorProfileId, _delegateeProfileId, _influencePoints);
    }

    /**
     * @dev Retrieves the total influence delegated to a profile.
     * @param _profileId The ID of the profile to check delegated influence for.
     * @return The total delegated influence received by the profile.
     */
    function getDelegatedInfluence(uint256 _profileId) public view profileExists(_profileId) returns (uint256) {
        return receivedDelegatedInfluence[_profileId];
    }

    /**
     * @dev Allows a delegatee to withdraw delegated influence (if applicable - logic can be defined based on rules).
     * @param _delegateeProfileId The ID of the profile withdrawing delegated influence.
     * @param _amount The amount of influence to withdraw.
     */
    function withdrawDelegatedInfluence(uint256 _delegateeProfileId, uint256 _amount) public profileExists(_delegateeProfileId) {
        // Add logic for withdrawal conditions and limitations if needed.
        // For simplicity, allowing withdrawal up to received delegated influence.
        require(receivedDelegatedInfluence[_delegateeProfileId] >= _amount, "Insufficient delegated influence to withdraw.");
        require(_amount > 0, "Withdrawal amount must be positive.");

        receivedDelegatedInfluence[_delegateeProfileId] -= _amount;
        profiles[_delegateeProfileId].reputation += _amount; // Withdrawn influence adds to delegatee's reputation (conceptually)

        // Need to iterate through delegators and reduce their delegation amounts accordingly.
        uint256 withdrawnAmountRemaining = _amount;
        uint256[] memory delegatorProfileIds = getDelegatorsForProfile(_delegateeProfileId); // Function to get delegators (needs implementation)

        for (uint256 i = 0; i < delegatorProfileIds.length && withdrawnAmountRemaining > 0; i++) {
            uint256 delegatorId = delegatorProfileIds[i];
            uint256 delegationAmount = delegatedInfluence[delegatorId][_delegateeProfileId];
            uint256 amountToReduce = Math.min(delegationAmount, withdrawnAmountRemaining);

            delegatedInfluence[delegatorId][_delegateeProfileId] -= amountToReduce;
            profiles[delegatorId].reputation += amountToReduce; // Restore reputation to delegator
            withdrawnAmountRemaining -= amountToReduce;
        }

        emit InfluenceWithdrawn(_delegateeProfileId, _amount);
    }

    // Helper function to get delegators for a profile (needs implementation - can be optimized)
    function getDelegatorsForProfile(uint256 _profileId) internal view returns (uint256[] memory) {
        uint256[] memory delegators;
        uint256 delegatorCount = 0;
        for (uint256 delegatorId = 1; delegatorId < profileCounter; delegatorId++) { // Iterate through all possible profile IDs (inefficient for large number of profiles)
            if (delegatedInfluence[delegatorId][_profileId] > 0) {
                delegatorCount++;
            }
        }
        delegators = new uint256[](delegatorCount);
        uint256 index = 0;
        for (uint256 delegatorId = 1; delegatorId < profileCounter; delegatorId++) {
            if (delegatedInfluence[delegatorId][_profileId] > 0) {
                delegators[index] = delegatorId;
                index++;
            }
        }
        return delegators;
    }


    // ** III. Reputation-Gated Actions and Perks Functions **

    /**
     * @dev Sets a reputation requirement for performing a specific action. (Admin/DAO controlled function)
     * @param _actionName The name of the action (e.g., "PostComment", "VoteProposal").
     * @param _requiredReputation The minimum reputation required to perform the action.
     */
    function setActionReputationGate(string memory _actionName, uint256 _requiredReputation) public onlyAdmin {
        require(bytes(_actionName).length > 0 && bytes(_actionName).length <= 64, "Action name must be between 1 and 64 characters.");
        actionReputationGates[_actionName] = _requiredReputation;
        emit ActionReputationGateSet(_actionName, _requiredReputation, msg.sender);
    }

    /**
     * @dev Retrieves the reputation requirement for a specific action.
     * @param _actionName The name of the action.
     * @return The required reputation score for the action.
     */
    function getActionReputationGate(string memory _actionName) public view returns (uint256) {
        return actionReputationGates[_actionName];
    }

    /**
     * @dev Checks if a profile meets the reputation requirement for a specific action.
     * @param _profileId The ID of the profile to check.
     * @param _actionName The name of the action to check against.
     * @return True if the profile meets the requirement, false otherwise.
     */
    function checkReputationGate(uint256 _profileId, string memory _actionName) public view profileExists(_profileId) returns (bool) {
        return getReputation(_profileId) >= actionReputationGates[_actionName];
    }

    /**
     * @dev Allows users to claim perks if they meet reputation or role requirements. (Simplified perk claiming logic)
     * @param _profileId The ID of the profile claiming the perk.
     * @param _perkName The name of the perk being claimed.
     */
    function claimPerk(uint256 _profileId, string memory _perkName) public profileExists(_profileId) {
        // Example Perk Logic - Expand based on specific perk requirements and actions
        if (keccak256(bytes(_perkName)) == keccak256(bytes("EarlyAccessPerk"))) { // Example perk: "EarlyAccessPerk"
            require(getReputation(_profileId) >= 1000, "Reputation too low for Early Access Perk.");
            // ... Add logic to grant early access (e.g., update user status, trigger external call, etc.)
            emit PerkClaimed(_profileId, _perkName);
        } else if (keccak256(bytes(_perkName)) == keccak256(bytes("RoleBasedPerk"))) { // Example perk: "RoleBasedPerk"
            require(hasRole(_profileId, "VIP"), "Role requirement not met for Role Based Perk.");
            // ... Add logic to grant role-based perk
            emit PerkClaimed(_profileId, _perkName);
        } else {
            revert("Invalid Perk Name.");
        }
    }

    // Internal function example for perk logic (can be expanded for different perks)
    // function claimPerkInternal(uint256 _profileId, string memory _perkName) internal {
    //     // ... Perk specific logic ...
    //     emit PerkClaimed(_profileId, _perkName);
    // }


    // ** IV. Governance and Admin Functions **

    /**
     * @dev Sets a new admin address. (Only callable by current admin)
     * @param _newAdmin The address of the new admin.
     */
    function setAdmin(address _newAdmin) public onlyAdmin {
        require(_newAdmin != address(0), "New admin address cannot be zero address.");
        address oldAdmin = admin;
        admin = _newAdmin;
        emit AdminChanged(_newAdmin, oldAdmin);
    }

    /**
     * @dev Checks if an address is the current admin.
     * @param _account The address to check.
     * @return True if the address is the admin, false otherwise.
     */
    function isAdmin(address _account) public view returns (bool) {
        return _account == admin;
    }

    // ** Optional: Math Library (if needed for more complex calculations) **
    library Math {
        function min(uint256 a, uint256 b) internal pure returns (uint256) {
            return a < b ? a : b;
        }
    }
    using Math for uint256;
}
```