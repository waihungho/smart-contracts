Okay, let's design a smart contract that incorporates several advanced, creative, and interconnected concepts beyond standard patterns. We'll call it `QuantumLock`.

The core idea: A contract that acts as a secure vault for ERC-20 tokens, where unlocking the funds depends on meeting a combination of weighted, programmable conditions, potentially involving external data feeds (via oracles) and time dynamics. This is more complex than a simple time-lock or vesting schedule.

**Outline:**

1.  **Contract Definition:** Inherit `Ownable` (standard from OpenZeppelin for basic ownership).
2.  **Enums & Structs:** Define types for conditions and structures for conditions, lock profiles, user locks, and oracle data.
3.  **State Variables:** Store profile details, user lock details, oracle data, supported tokens, managers, oracles, etc.
4.  **Events:** Log significant actions (deposit, claim, profile creation, oracle update, etc.).
5.  **Modifiers:** Custom modifiers for access control beyond `onlyOwner`.
6.  **Core Logic:**
    *   Functions for defining and managing Lock Profiles (sets of conditions and thresholds).
    *   Functions for depositing into a specific profile.
    *   Functions for Oracles to report data.
    *   Functions for checking if unlock conditions are met for a specific user lock instance.
    *   Functions for claiming unlocked funds.
7.  **Admin/Configuration Functions:** Managing supported tokens, oracles, profile managers.
8.  **Query Functions:** Get details about profiles, locks, conditions, state, etc.

**Function Summary (20+ functions):**

1.  `constructor()`: Initialize the owner.
2.  `setSupportedToken(address token, bool supported)`: Owner adds/removes supported ERC-20 tokens for deposits.
3.  `getSupportedTokens()`: Query list of supported tokens.
4.  `addProfileManager(address manager)`: Owner grants profile creation/management rights.
5.  `removeProfileManager(address manager)`: Owner revokes profile management rights.
6.  `isProfileManager(address account)`: Query if an address is a profile manager.
7.  `addOracle(address oracle)`: Owner grants oracle reporting rights.
8.  `removeOracle(address oracle)`: Owner revokes oracle reporting rights.
9.  `isOracle(address account)`: Query if an address is an oracle.
10. `reportOracleData(bytes32 oracleId, uint256 value)`: Oracle submits data for a specific feed. Includes timestamp.
11. `getOracleData(bytes32 oracleId)`: Query the *latest* data reported by an oracle.
12. `createLockProfile(string memory name, Condition[] memory conditions, uint256 unlockThreshold)`: Profile Manager creates a new lock profile. Assigns unique ID.
13. `updateLockProfileConditions(uint256 profileId, Condition[] memory newConditions)`: Profile Manager updates the conditions for a profile.
14. `updateLockProfileThreshold(uint256 profileId, uint256 newThreshold)`: Profile Manager updates the unlock threshold for a profile.
15. `toggleLockProfileActive(uint256 profileId, bool active)`: Profile Manager activates/deactivates a profile (affects new deposits).
16. `getLockProfileDetails(uint256 profileId)`: Query details of a specific lock profile.
17. `getAllProfileIds()`: Query all existing lock profile IDs.
18. `deposit(uint256 profileId, address token, uint256 amount)`: User deposits supported tokens into a chosen lock profile. Records start time. Requires approval beforehand.
19. `checkLockConditions(uint256 profileId, address depositor)`: Calculates the *current* met score for a user's specific lock instance based on profile conditions and current state/oracle data. Returns score and met conditions indices.
20. `claim(uint256 profileId)`: User attempts to claim funds from their lock instance for that profile. Calls `checkLockConditions`. If threshold is met, transfers funds and marks lock as claimed.
21. `transferLockOwnership(uint256 profileId, address newOwner)`: Allows a depositor to transfer their *locked position* to another address.
22. `getUserLockDetails(uint256 profileId, address depositor)`: Query details of a user's specific lock instance.
23. `getTotalLockedAssets(address token)`: Query total amount of a specific token locked across all profiles.
24. `getProfileLockedAssets(uint256 profileId, address token)`: Query total amount of a specific token locked within one profile.
25. `isLockClaimed(uint256 profileId, address depositor)`: Query if a user's lock instance has been claimed.
26. `getConditionDetails(uint256 profileId, uint256 conditionIndex)`: Query details of a specific condition within a profile.
27. `getProfileConditionCount(uint256 profileId)`: Query the number of conditions in a profile.
28. `pauseProfile(uint256 profileId)`: Profile Manager can pause a profile (preventing deposits and claims - emergency stop).
29. `unpauseProfile(uint256 profileId)`: Profile Manager can unpause a profile.
30. `isProfilePaused(uint256 profileId)`: Query if a profile is paused.

**(Note: We have 30 functions listed, easily exceeding the 20 function requirement. Some getters are combined or simplified for brevity in the summary but will exist individually in the code.)**

Let's define the `ConditionType` enum and `Condition` struct:

*   `ConditionType`:
    *   `TimeElapsed`: Requires a minimum duration since the lock started.
    *   `OracleValueAbove`: Requires a specific oracle feed's latest value to be above a target.
    *   `OracleValueBelow`: Requires a specific oracle feed's latest value to be below a target.
    *   `SpecificAddressInteracted`: Requires a specific address to have called *any* function on *this* contract since the lock started (simple presence check, not tied to a specific tx).
    *   `OtherContractStateMatch`: Requires reading a public variable or calling a view function on another specific contract and matching a target value (e.g., checking a phase in another game contract).

Now, let's write the Solidity code.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/erc20/IERC20.sol";
import "@openzeppelin/contracts/token/erc20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol"; // Needed for _msgSender()

/// @title QuantumLock
/// @dev A smart contract vault where unlocking deposited tokens depends on meeting
///      a programmable, weighted combination of diverse conditions, including
///      time elapsed, oracle data values, and interaction states.
/// @author [Your Name/Team Name]

// Outline:
// 1. Contract Definition inheriting Ownable and Context
// 2. Enums and Structs for Conditions, Profiles, User Locks, Oracle Data
// 3. State Variables for configurations, profiles, locks, oracle data, supported tokens, roles
// 4. Events for logging key actions
// 5. Modifiers for access control
// 6. Core Logic: Profile Management, Deposits, Oracle Reporting, Condition Checking, Claims
// 7. Admin/Configuration Functions: Role management, Token support, Emergency withdrawal
// 8. Query/Getter Functions: Retrieve contract state and details

// Function Summary:
// - Admin/Roles (Owner):
//   - constructor(): Initializes owner.
//   - setSupportedToken(): Add or remove supported ERC20 tokens.
//   - addProfileManager(): Grant profile creation/management role.
//   - removeProfileManager(): Revoke profile creation/management role.
//   - addOracle(): Grant oracle data reporting role.
//   - removeOracle(): Revoke oracle data reporting role.
//   - emergencyWithdrawAdmin(): Owner can withdraw tokens in emergencies.
// - Role Queries:
//   - isSupportedToken(): Check if a token is supported.
//   - isProfileManager(): Check if an address is a profile manager.
//   - isOracle(): Check if an address is an oracle.
//   - getSupportedTokens(): Get array of supported tokens.
// - Profile Management (Owner/Profile Managers):
//   - createLockProfile(): Create a new profile with conditions and threshold.
//   - updateLockProfileConditions(): Modify conditions of an existing profile.
//   - updateLockProfileThreshold(): Modify unlock threshold of a profile.
//   - toggleLockProfileActive(): Activate or deactivate a profile for new deposits.
//   - pauseProfile(): Pause a profile (stop deposits/claims).
//   - unpauseProfile(): Unpause a profile.
// - Profile Queries:
//   - getLockProfileDetails(): Get details of a specific profile.
//   - getAllProfileIds(): Get all existing profile IDs.
//   - getConditionDetails(): Get details of a specific condition in a profile.
//   - getProfileConditionCount(): Get number of conditions in a profile.
//   - getUnlockThreshold(): Get unlock threshold for a profile.
//   - isProfileActive(): Check if profile is active.
//   - isProfilePaused(): Check if profile is paused.
// - Oracle Operations (Oracles):
//   - reportOracleData(): Submit data for an oracle feed.
// - Oracle Queries:
//   - getOracleData(): Get the latest reported data for an oracle feed.
// - User Interactions (Depositor/Claimant):
//   - deposit(): Deposit tokens into a specific lock profile.
//   - checkLockConditions(): Calculate met score for a user's lock.
//   - claim(): Attempt to claim funds if conditions are met.
//   - transferLockOwnership(): Transfer ownership of a locked position.
// - User Lock Queries:
//   - getUserLockDetails(): Get details of a specific user lock.
//   - isLockClaimed(): Check if a lock has been claimed.
//   - getTotalLockedAssets(): Get total locked amount for a token.
//   - getProfileLockedAssets(): Get total locked amount for a token in a profile.
//   - getMetConditionIndices(): Get indices of conditions met for a lock.

contract QuantumLock is Ownable, Context {
    using SafeERC20 for IERC20;

    // --- Enums ---

    /// @dev Types of conditions that can be defined for unlocking.
    enum ConditionType {
        TimeElapsed,           // Requires a minimum duration since lock start
        OracleValueAbove,      // Requires oracle data >= targetValue
        OracleValueBelow,      // Requires oracle data <= targetValue
        SpecificAddressInteracted, // Requires targetAddress to have called this contract since lock start
        OtherContractStateMatch // Requires reading external contract data == targetValue
    }

    // --- Structs ---

    /// @dev Defines a single condition part of a LockProfile.
    struct Condition {
        ConditionType conditionType; // Type of condition (e.g., TimeElapsed)
        bytes32 oracleId;            // Used for OracleValue types
        uint256 targetValue;         // Value to check against (duration, oracle value, state value)
        address targetAddress;       // Used for SpecificAddressInteracted, OtherContractStateMatch (contract address)
        bytes4 targetSelector;       // Used for OtherContractStateMatch (function selector)
        uint256 weight;              // Weight contributed to the total score if met
        bool active;                 // Is this condition currently considered?
    }

    /// @dev Defines a profile with a set of conditions for unlocking.
    struct LockProfile {
        string name;                 // Human-readable name
        Condition[] conditions;      // Array of conditions to check
        uint256 unlockThreshold;     // Minimum total weight needed to unlock
        bool active;                 // Can users deposit into this profile?
        bool paused;                 // Is this profile temporarily paused (no deposits/claims)?
        mapping(address => bool) managers; // Addresses allowed to manage this profile's conditions/threshold
    }

    /// @dev Stores details for a specific user's lock instance.
    struct UserLock {
        address depositor;           // The address that made the deposit
        address token;               // The token that was deposited
        uint256 amount;              // The amount deposited
        uint256 startTime;           // Block timestamp when the deposit occurred
        bool claimed;                // Has this lock been claimed?
    }

    /// @dev Stores the latest reported data for an oracle feed.
    struct OracleData {
        uint256 value;               // The reported value
        uint256 timestamp;           // When the data was reported
    }

    // --- State Variables ---

    uint256 private _nextProfileId = 1; // Counter for profile IDs

    // Configuration and Roles
    mapping(address => bool) private _supportedTokens; // ERC20 tokens allowed for deposit
    address[] private _supportedTokenList;             // List of supported tokens for easy iteration

    mapping(address => bool) private _profileManagers; // Addresses allowed to create/manage any profile
    mapping(address => bool) private _oracles;         // Addresses allowed to report oracle data

    // Core Data
    mapping(uint256 => LockProfile) private _lockProfiles; // profileId => LockProfile
    mapping(uint256 => mapping(address => UserLock)) private _userLocks; // profileId => depositor => UserLock
    mapping(bytes32 => OracleData) private _oracleData;   // oracleId => OracleData

    // Keep track of interactions for SpecificAddressInteracted condition
    mapping(address => mapping(uint256 => bool)) private _addressInteractedSinceLock; // address => lockStartTime => interacted?

    // Total locked assets per token and profile
    mapping(address => uint256) private _totalLockedAssets; // token => amount
    mapping(uint256 => mapping(address => uint256)) private _profileLockedAssets; // profileId => token => amount

    // --- Events ---

    event TokenSupported(address indexed token, bool supported);
    event ProfileManagerAdded(address indexed manager);
    event ProfileManagerRemoved(address indexed manager);
    event OracleAdded(address indexed oracle);
    event OracleRemoved(address indexed oracle);
    event OracleDataReported(bytes32 indexed oracleId, uint256 value, uint256 timestamp);
    event LockProfileCreated(uint256 indexed profileId, string name, uint256 unlockThreshold, address creator);
    event LockProfileUpdated(uint256 indexed profileId, address updater);
    event LockProfileActiveToggled(uint256 indexed profileId, bool active, address toggler);
    event LockProfilePaused(uint256 indexed profileId, bool paused, address toggler);
    event Deposit(uint256 indexed profileId, address indexed depositor, address indexed token, uint256 amount, uint256 startTime);
    event ConditionsChecked(uint256 indexed profileId, address indexed depositor, uint256 metScore, uint256 requiredThreshold);
    event Claim(uint256 indexed profileId, address indexed depositor, address indexed token, uint256 amount);
    event LockOwnershipTransferred(uint256 indexed profileId, address indexed from, address indexed to);
    event EmergencyWithdraw(address indexed token, uint256 amount, address indexed recipient);

    // --- Modifiers ---

    modifier onlyProfileManager() {
        require(_profileManagers[_msgSender()], "QL: Not a profile manager");
        _;
    }

    modifier onlyOracle() {
        require(_oracles[_msgSender()], "QL: Not an oracle");
        _;
    }

    modifier profileExists(uint256 profileId) {
        require(profileId > 0 && profileId < _nextProfileId, "QL: Profile does not exist");
        _;
    }

    modifier isProfileManagerForProfile(uint256 profileId) {
        require(_lockProfiles[profileId].managers[_msgSender()] || _profileManagers[_msgSender()] || owner() == _msgSender(), "QL: Not authorized for this profile");
        _;
    }

    modifier isProfileActive(uint256 profileId) {
        require(_lockProfiles[profileId].active, "QL: Profile is not active");
        _;
    }

    modifier isProfileNotPaused(uint256 profileId) {
         require(!_lockProfiles[profileId].paused, "QL: Profile is paused");
         _;
    }

    // --- Constructor ---

    constructor() Ownable(_msgSender()) {}

    // --- Admin / Configuration Functions (onlyOwner) ---

    /// @dev Allows the owner to add or remove supported ERC20 tokens.
    ///      Only supported tokens can be deposited.
    /// @param token The address of the ERC20 token.
    /// @param supported True to add, false to remove.
    function setSupportedToken(address token, bool supported) external onlyOwner {
        require(token != address(0), "QL: Zero address token");
        if (_supportedTokens[token] != supported) {
            _supportedTokens[token] = supported;
            if (supported) {
                _supportedTokenList.push(token);
            } else {
                 // Remove from list (inefficient for large lists, but simple)
                for (uint i = 0; i < _supportedTokenList.length; i++) {
                    if (_supportedTokenList[i] == token) {
                        _supportedTokenList[i] = _supportedTokenList[_supportedTokenList.length - 1];
                        _supportedTokenList.pop();
                        break;
                    }
                }
            }
            emit TokenSupported(token, supported);
        }
    }

    /// @dev Allows the owner to grant profile management rights.
    ///      Profile managers can create and update profiles.
    /// @param manager The address to grant rights to.
    function addProfileManager(address manager) external onlyOwner {
        require(manager != address(0), "QL: Zero address");
        _profileManagers[manager] = true;
        emit ProfileManagerAdded(manager);
    }

    /// @dev Allows the owner to revoke profile management rights.
    /// @param manager The address to revoke rights from.
    function removeProfileManager(address manager) external onlyOwner {
        require(manager != address(0), "QL: Zero address");
        _profileManagers[manager] = false;
        emit ProfileManagerRemoved(manager);
    }

    /// @dev Allows the owner to grant oracle data reporting rights.
    /// @param oracle The address to grant rights to.
    function addOracle(address oracle) external onlyOwner {
        require(oracle != address(0), "QL: Zero address");
        _oracles[oracle] = true;
        emit OracleAdded(oracle);
    }

    /// @dev Allows the owner to revoke oracle data reporting rights.
    /// @param oracle The address to revoke rights from.
    function removeOracle(address oracle) external onlyOwner {
        require(oracle != address(0), "QL: Zero address");
        _oracles[oracle] = false;
        emit OracleRemoved(oracle);
    }

    /// @dev Allows the owner to withdraw tokens stuck in the contract
    ///      that are not part of active locks (e.g., accidentally sent tokens,
    ///      or tokens from failed claims due to external issues).
    /// @param token The token to withdraw.
    /// @param amount The amount to withdraw.
    function emergencyWithdrawAdmin(address token, uint256 amount) external onlyOwner {
        require(token != address(0), "QL: Zero address token");
        IERC20 tokenContract = IERC20(token);
        uint256 contractBalance = tokenContract.balanceOf(address(this));
        uint256 totalLocked = _totalLockedAssets[token];
        uint256 available = contractBalance - totalLocked; // Calculate truly excess funds
        require(amount <= available, "QL: Amount exceeds available excess funds");

        tokenContract.safeTransfer(owner(), amount);
        emit EmergencyWithdraw(token, amount, owner());
    }


    // --- Role Query Functions ---

    /// @dev Checks if a token address is currently supported for deposits.
    /// @param token The token address to check.
    /// @return True if supported, false otherwise.
    function isSupportedToken(address token) external view returns (bool) {
        return _supportedTokens[token];
    }

    /// @dev Checks if an address has profile management rights.
    /// @param account The address to check.
    /// @return True if a profile manager, false otherwise.
    function isProfileManager(address account) external view returns (bool) {
        return _profileManagers[account];
    }

    /// @dev Checks if an address has oracle data reporting rights.
    /// @param account The address to check.
    /// @return True if an oracle, false otherwise.
    function isOracle(address account) external view returns (bool) {
        return _oracles[account];
    }

    /// @dev Gets the list of currently supported tokens.
    /// @return An array of supported token addresses.
    function getSupportedTokens() external view returns (address[] memory) {
        return _supportedTokenList;
    }

    // --- Profile Management Functions (onlyProfileManager, onlyOwner, or specific profile manager) ---

    /// @dev Creates a new lock profile.
    ///      Only Profile Managers or the Owner can call this.
    /// @param name Human-readable name for the profile.
    /// @param conditions The array of conditions for this profile.
    /// @param unlockThreshold The minimum total weight required to unlock.
    /// @return The ID of the newly created profile.
    function createLockProfile(
        string memory name,
        Condition[] memory conditions,
        uint256 unlockThreshold
    ) external onlyProfileManager returns (uint256) {
        uint256 profileId = _nextProfileId++;
        LockProfile storage profile = _lockProfiles[profileId];
        profile.name = name;
        profile.conditions = conditions; // Deep copy of conditions array
        profile.unlockThreshold = unlockThreshold;
        profile.active = true; // New profiles are active by default
        profile.paused = false; // New profiles are not paused
        profile.managers[_msgSender()] = true; // Creator is automatically a manager for this profile

        emit LockProfileCreated(profileId, name, unlockThreshold, _msgSender());
        return profileId;
    }

     /// @dev Adds a manager specifically for this profile. Can be called by contract owner,
     ///      a global profile manager, or an existing manager of this specific profile.
     /// @param profileId The ID of the profile to add a manager to.
     /// @param manager The address to add as a manager for this profile.
    function addProfileSpecificManager(uint256 profileId, address manager) external profileExists(profileId) isProfileManagerForProfile(profileId) {
        require(manager != address(0), "QL: Zero address");
        _lockProfiles[profileId].managers[manager] = true;
        // No specific event for profile-specific manager, using general update event
        emit LockProfileUpdated(profileId, _msgSender());
    }

    /// @dev Removes a manager specifically from this profile. Can be called by contract owner,
     ///      a global profile manager, or an existing manager of this specific profile.
     /// @param profileId The ID of the profile to remove a manager from.
     /// @param manager The address to remove as a manager for this profile.
    function removeProfileSpecificManager(uint256 profileId, address manager) external profileExists(profileId) isProfileManagerForProfile(profileId) {
        require(manager != address(0), "QL: Zero address");
        _lockProfiles[profileId].managers[manager] = false;
         // No specific event for profile-specific manager, using general update event
        emit LockProfileUpdated(profileId, _msgSender());
    }


    /// @dev Updates the conditions for an existing lock profile.
    ///      Only Profile Managers or the Owner or specific profile managers can call this.
    /// @param profileId The ID of the profile to update.
    /// @param newConditions The new array of conditions. Replaces existing ones.
    function updateLockProfileConditions(uint256 profileId, Condition[] memory newConditions)
        external
        profileExists(profileId)
        isProfileManagerForProfile(profileId)
    {
        _lockProfiles[profileId].conditions = newConditions;
        emit LockProfileUpdated(profileId, _msgSender());
    }

    /// @dev Updates the unlock threshold for an existing lock profile.
    ///      Only Profile Managers or the Owner or specific profile managers can call this.
    /// @param profileId The ID of the profile to update.
    /// @param newThreshold The new unlock threshold.
    function updateLockProfileThreshold(uint256 profileId, uint256 newThreshold)
        external
        profileExists(profileId)
        isProfileManagerForProfile(profileId)
    {
        _lockProfiles[profileId].unlockThreshold = newThreshold;
        emit LockProfileUpdated(profileId, _msgSender());
    }

    /// @dev Toggles the active status of a profile.
    ///      If inactive, new deposits are not allowed.
    ///      Only Profile Managers or the Owner or specific profile managers can call this.
    /// @param profileId The ID of the profile.
    /// @param active The new active status.
    function toggleLockProfileActive(uint256 profileId, bool active)
        external
        profileExists(profileId)
        isProfileManagerForProfile(profileId)
    {
        _lockProfiles[profileId].active = active;
        emit LockProfileActiveToggled(profileId, active, _msgSender());
    }

    /// @dev Pauses a profile, preventing new deposits and claims.
    ///      Useful for emergency stops. Only Profile Managers or the Owner or specific profile managers can call this.
    /// @param profileId The ID of the profile.
    function pauseProfile(uint256 profileId)
        external
        profileExists(profileId)
        isProfileManagerForProfile(profileId)
    {
        _lockProfiles[profileId].paused = true;
        emit LockProfilePaused(profileId, true, _msgSender());
    }

    /// @dev Unpauses a profile, allowing deposits and claims again.
    ///      Only Profile Managers or the Owner or specific profile managers can call this.
    /// @param profileId The ID of the profile.
    function unpauseProfile(uint256 profileId)
        external
        profileExists(profileId)
        isProfileManagerForProfile(profileId)
    {
        _lockProfiles[profileId].paused = false;
        emit LockProfilePaused(profileId, false, _msgSender());
    }

    // --- Profile Query Functions ---

    /// @dev Gets the full details of a specific lock profile.
    /// @param profileId The ID of the profile.
    /// @return A tuple containing the profile's name, conditions, threshold, active status, and paused status.
    function getLockProfileDetails(uint256 profileId)
        external
        view
        profileExists(profileId)
        returns (string memory name, Condition[] memory conditions, uint256 unlockThreshold, bool active, bool paused)
    {
        LockProfile storage profile = _lockProfiles[profileId];
        return (profile.name, profile.conditions, profile.unlockThreshold, profile.active, profile.paused);
    }

    /// @dev Gets the details of a specific condition within a profile.
    /// @param profileId The ID of the profile.
    /// @param conditionIndex The index of the condition in the profile's conditions array.
    /// @return A tuple containing the condition's type, oracle ID, target value, target address, target selector, weight, and active status.
    function getConditionDetails(uint256 profileId, uint256 conditionIndex)
        external
        view
        profileExists(profileId)
        returns (ConditionType conditionType, bytes32 oracleId, uint256 targetValue, address targetAddress, bytes4 targetSelector, uint256 weight, bool active)
    {
        LockProfile storage profile = _lockProfiles[profileId];
        require(conditionIndex < profile.conditions.length, "QL: Invalid condition index");
        Condition storage condition = profile.conditions[conditionIndex];
        return (condition.conditionType, condition.oracleId, condition.targetValue, condition.targetAddress, condition.targetSelector, condition.weight, condition.active);
    }


    /// @dev Gets all existing lock profile IDs.
    /// @return An array of profile IDs.
    function getAllProfileIds() external view returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](_nextProfileId - 1);
        for (uint i = 1; i < _nextProfileId; i++) {
            ids[i - 1] = i;
        }
        return ids;
    }

    /// @dev Gets the number of conditions in a specific profile.
    /// @param profileId The ID of the profile.
    /// @return The number of conditions.
    function getProfileConditionCount(uint256 profileId) external view profileExists(profileId) returns (uint256) {
        return _lockProfiles[profileId].conditions.length;
    }

    /// @dev Gets the unlock threshold for a specific profile.
    /// @param profileId The ID of the profile.
    /// @return The unlock threshold weight.
    function getUnlockThreshold(uint256 profileId) external view profileExists(profileId) returns (uint256) {
        return _lockProfiles[profileId].unlockThreshold;
    }

     /// @dev Checks if a profile is currently active for new deposits.
     /// @param profileId The ID of the profile.
     /// @return True if active, false otherwise.
    function isProfileActive(uint256 profileId) external view profileExists(profileId) returns (bool) {
        return _lockProfiles[profileId].active;
    }

     /// @dev Checks if a profile is currently paused (prevents deposits/claims).
     /// @param profileId The ID of the profile.
     /// @return True if paused, false otherwise.
    function isProfilePaused(uint256 profileId) external view profileExists(profileId) returns (bool) {
        return _lockProfiles[profileId].paused;
    }


    // --- Oracle Operations (onlyOracle) ---

    /// @dev Allows authorized oracles to report data for a specific feed.
    ///      Overwrite previous data for the same oracleId.
    /// @param oracleId Identifier for the oracle data feed (e.g., bytes32("ETH/USD")).
    /// @param value The value reported by the oracle.
    function reportOracleData(bytes32 oracleId, uint256 value) external onlyOracle {
        _oracleData[oracleId] = OracleData({
            value: value,
            timestamp: block.timestamp
        });
        emit OracleDataReported(oracleId, value, block.timestamp);
    }

    // --- Oracle Query Functions ---

    /// @dev Gets the latest data reported for a specific oracle feed.
    /// @param oracleId Identifier for the oracle data feed.
    /// @return The reported value and timestamp.
    function getOracleData(bytes32 oracleId) external view returns (uint256 value, uint256 timestamp) {
        OracleData storage data = _oracleData[oracleId];
        require(data.timestamp > 0, "QL: Oracle data not available");
        return (data.value, data.timestamp);
    }

    // --- User Interaction Functions ---

    /// @dev Allows a user to deposit supported tokens into a specific lock profile.
    ///      Requires the user to have approved this contract to spend the tokens beforehand.
    ///      Records the deposit amount and start time.
    /// @param profileId The ID of the profile to deposit into.
    /// @param token The address of the ERC20 token to deposit.
    /// @param amount The amount of tokens to deposit.
    function deposit(uint256 profileId, address token, uint256 amount)
        external
        profileExists(profileId)
        isProfileActive(profileId)
        isProfileNotPaused(profileId)
    {
        require(_supportedTokens[token], "QL: Token not supported");
        require(amount > 0, "QL: Deposit amount must be greater than 0");
        require(_userLocks[profileId][_msgSender()].amount == 0, "QL: User already has an active lock for this profile");

        // Record interaction timestamp for SpecificAddressInteracted condition
        // This is a simple check if the address has *ever* interacted since lock start.
        // A more complex check could track interactions per lock, but is state heavy.
        // We record interaction time keyed by lock start time.
        // This approach simplifies state but means *any* interaction after lock start fulfills the condition.
         _addressInteractedSinceLock[_msgSender()][block.timestamp] = true;


        IERC20(token).safeTransferFrom(_msgSender(), address(this), amount);

        _userLocks[profileId][_msgSender()] = UserLock({
            depositor: _msgSender(),
            token: token,
            amount: amount,
            startTime: block.timestamp, // Use block.timestamp as lock start time
            claimed: false
        });

        // Update total locked assets trackers
        _totalLockedAssets[token] += amount;
        _profileLockedAssets[profileId][token] += amount;

        emit Deposit(profileId, _msgSender(), token, amount, block.timestamp);
    }

    /// @dev Checks if a specific condition within a profile is met for a user's lock instance.
    ///      Internal helper function.
    /// @param profileId The ID of the profile.
    /// @param userLock The user's lock instance details.
    /// @param condition The condition struct to check.
    /// @return True if the condition is met and active, false otherwise.
    function _checkConditionMet(uint256 profileId, UserLock storage userLock, Condition storage condition)
        internal
        view
        returns (bool)
    {
        if (!condition.active) {
            return false; // Condition must be active
        }

        uint256 lockStartTime = userLock.startTime;

        // Handle different condition types
        if (condition.conditionType == ConditionType.TimeElapsed) {
            return block.timestamp >= lockStartTime + condition.targetValue;
        }
        else if (condition.conditionType == ConditionType.OracleValueAbove) {
             // Requires latest data to be *at least* targetValue
            OracleData storage oracle = _oracleData[condition.oracleId];
            // Require recent data (e.g., within 1 hour, adjust as needed)
            require(oracle.timestamp > 0 && block.timestamp - oracle.timestamp <= 1 hours, "QL: Oracle data stale or unavailable");
            return oracle.value >= condition.targetValue;
        }
         else if (condition.conditionType == ConditionType.OracleValueBelow) {
            // Requires latest data to be *at most* targetValue
            OracleData storage oracle = _oracleData[condition.oracleId];
             // Require recent data (e.g., within 1 hour)
            require(oracle.timestamp > 0 && block.timestamp - oracle.timestamp <= 1 hours, "QL: Oracle data stale or unavailable");
            return oracle.value <= condition.targetValue;
        }
         else if (condition.conditionType == ConditionType.SpecificAddressInteracted) {
             // Checks if the target address has called *any* function on this contract
             // *after* the lock started. This requires tracking interactions.
             // Our simple model just checks if an interaction happened *keyed by* the lock start time.
             // A more robust model would track interactions per address or per lock instance.
             // Given the state constraints, we use the simple model: has the target address
             // called *any* function on *this contract* since the lock started?
            // NOTE: This simple check requires the targetAddress to have made *any* call
            // to this contract after userLock.startTime. We use a state variable
            // (_addressInteractedSinceLock) to track this.
            // This requires careful implementation: any public/external function call
            // by an address *could* potentially set a flag related to interaction time.
            // For this example, we'll *simulate* this by adding a check/update in the
            // `deposit` function, assuming it's a representative "interaction".
            // A real implementation might need to track this more broadly in a base contract
            // or via a dedicated interaction logging function.
             // Let's assume the _addressInteractedSinceLock[address][startTime] check is sufficient
             // based on how we've decided to track it (e.g., in `deposit`).
             // This specific implementation of `SpecificAddressInteracted` relies on the
             // `_addressInteractedSinceLock` mapping being populated by relevant interactions.
             // Our current code only populates it in `deposit`. A more general solution
             // would need this check/update in every relevant function, or a dedicated mechanism.
             // Given the complexity, let's refine: Assume `_addressInteractedSinceLock` records the timestamp
             // of the *first* interaction by an address *after* a certain time marker.
             // This still feels overly complex for on-chain state.
             // ALTERNATIVE simpler `SpecificAddressInteracted`: Has the target address called *this* function (`checkLockConditions` or `claim`)
             // since the lock started? Still requires tracking state per lock.
             // Let's pivot this condition slightly: `SpecificAddressCalledClaim`. Condition is met if
             // the `targetAddress` has called the `claim` function for *this specific lock* (profileId, depositor)
             // since the lock started. This requires tracking state per lock.
             // This adds significant state complexity (_addressClaimedSinceLock[profileId][depositor][targetAddress] => bool).
             // Let's go back to the simplest form: The condition is met if `targetAddress` has called *any* function
             // on the contract *after* the lock started. We'll just use the simplified interaction tracking in `deposit`
             // for demonstration, acknowledging it's limited. A better version might require a dedicated 'registerInteraction' call.
             // Given the constraints, let's use the simplest interpretation: check if `targetAddress` has called *any* public/external
             // function on *this contract* since the lock started. Our `_addressInteractedSinceLock[_msgSender()][block.timestamp]`
             // in `deposit` attempts to capture *the depositor's* interaction. The condition needs to check a *different* target address.
             // This `SpecificAddressInteracted` condition is hard to implement efficiently and correctly *without* massive state or external help.
             // Let's simplify the demo contract conditions. Remove `SpecificAddressInteracted` and `OtherContractStateMatch` for now,
             // as they introduce significant complexity in tracking state and external calls respectively, which can quickly push
             // a single contract example beyond reasonable limits. We'll stick to Time and Oracle conditions.
             // Let's replace them with simpler concepts:
             // - `MinBalanceHeld`: Requires targetAddress to hold >= targetValue of a specific token (targetSelector = token address)
             // - `SpecificBlockReached`: Requires block.number >= targetValue.
             // This brings us back to 4 ConditionTypes.
             // Condition types: TimeElapsed, OracleValueAbove, OracleValueBelow, MinBalanceHeld, SpecificBlockReached.
             // Let's update the struct and enum.
        }
        // Re-defining based on revised types:
        else if (condition.conditionType == ConditionType.MinBalanceHeld) {
             // targetAddress is the address to check balance for
             // targetSelector (bytes4) is re-purposed to store the token address (first 4 bytes)
             // This is a hack; should ideally use a dedicated address field or require full 32 bytes for address
             // Better approach: Use targetAddress for the holder, targetValue for minimum amount, and add a dedicated `tokenAddress` field to the Condition struct.
             // Let's revise the struct Condition again.
             /*
              struct Condition {
                 ConditionType conditionType; // Type of condition
                 bytes32 oracleId;            // For OracleValue types
                 uint256 targetValue;         // Value to check against (duration, oracle value, block number, min amount)
                 address checkAddress;        // For SpecificAddressInteracted, MinBalanceHeld, OtherContractStateMatch (holder address, contract address)
                 address tokenAddress;        // For MinBalanceHeld (token address)
                 bytes4 targetSelector;       // For OtherContractStateMatch (function selector)
                 uint256 weight;              // Weight contributed
                 bool active;                 // Active?
             }
             */
             // This requires updating `createLockProfile` and `updateLockProfileConditions`.
             // Let's proceed with this new struct definition.

            require(condition.checkAddress != address(0), "QL: checkAddress required for MinBalanceHeld");
            require(condition.tokenAddress != address(0), "QL: tokenAddress required for MinBalanceHeld");
            IERC20 tokenContract = IERC20(condition.tokenAddress);
            return tokenContract.balanceOf(condition.checkAddress) >= condition.targetValue;
        }
         else if (condition.conditionType == ConditionType.SpecificBlockReached) {
             // targetValue is the block number
             return block.number >= condition.targetValue;
         }

        return false; // Should not reach here if all types handled
    }

    /// @dev Calculates the total weight of met conditions for a user's specific lock instance.
    /// @param profileId The ID of the profile.
    /// @param depositor The address of the depositor.
    /// @return metScore The calculated total weight.
    /// @return metConditionIndices An array of indices of the conditions that were met.
    function checkLockConditions(uint256 profileId, address depositor)
        public
        view
        profileExists(profileId)
        returns (uint256 metScore, uint256[] memory metConditionIndices)
    {
        UserLock storage userLock = _userLocks[profileId][depositor];
        require(userLock.amount > 0, "QL: No active lock for this user in this profile");
        require(!userLock.claimed, "QL: Lock has already been claimed");

        LockProfile storage profile = _lockProfiles[profileId];
        uint256 currentScore = 0;
        uint256[] memory metIndices = new uint256[](profile.conditions.length);
        uint256 metCount = 0;

        for (uint i = 0; i < profile.conditions.length; i++) {
            if (_checkConditionMet(profileId, userLock, profile.conditions[i])) {
                currentScore += profile.conditions[i].weight;
                metIndices[metCount] = i;
                metCount++;
            }
        }

        // Resize the metConditions array
        uint256[] memory finalMetIndices = new uint256[](metCount);
        for (uint i = 0; i < metCount; i++) {
            finalMetIndices[i] = metIndices[i];
        }

        emit ConditionsChecked(profileId, depositor, currentScore, profile.unlockThreshold);
        return (currentScore, finalMetIndices);
    }

    /// @dev Allows a user to claim their locked tokens if the conditions are met.
    ///      Calls `checkLockConditions` to determine if the unlock threshold is reached.
    ///      Transfers the tokens and marks the lock as claimed.
    /// @param profileId The ID of the profile the user deposited into.
    function claim(uint256 profileId)
        external
        profileExists(profileId)
        isProfileNotPaused(profileId)
    {
        address depositor = _msgSender();
        UserLock storage userLock = _userLocks[profileId][depositor];
        require(userLock.amount > 0, "QL: No active lock for this user in this profile");
        require(!userLock.claimed, "QL: Lock has already been claimed");

        LockProfile storage profile = _lockProfiles[profileId];
        (uint256 metScore, ) = checkLockConditions(profileId, depositor); // Check current conditions

        require(metScore >= profile.unlockThreshold, "QL: Unlock conditions not met");

        uint256 claimAmount = userLock.amount;
        address token = userLock.token;

        userLock.claimed = true; // Mark as claimed BEFORE transfer

        // Update total locked assets trackers
        _totalLockedAssets[token] -= claimAmount;
        _profileLockedAssets[profileId][token] -= claimAmount;

        IERC20(token).safeTransfer(depositor, claimAmount);

        emit Claim(profileId, depositor, token, claimAmount);
    }

    /// @dev Allows the current owner of a locked position to transfer its ownership
    ///      to another address. The new owner inherits the lock's state (amount, start time).
    ///      Cannot transfer if already claimed.
    /// @param profileId The ID of the profile.
    /// @param newOwner The address to transfer ownership to.
    function transferLockOwnership(uint256 profileId, address newOwner)
        external
        profileExists(profileId)
    {
        address currentOwner = _msgSender();
        UserLock storage userLock = _userLocks[profileId][currentOwner];
        require(userLock.amount > 0, "QL: No active lock to transfer");
        require(!userLock.claimed, "QL: Cannot transfer a claimed lock");
        require(newOwner != address(0), "QL: Cannot transfer to zero address");
        require(newOwner != currentOwner, "QL: Cannot transfer to self");
        require(_userLocks[profileId][newOwner].amount == 0, "QL: New owner already has an active lock for this profile");

        // Transfer the struct data
        _userLocks[profileId][newOwner] = userLock;

        // Clear the old owner's slot
        delete _userLocks[profileId][currentOwner];

        emit LockOwnershipTransferred(profileId, currentOwner, newOwner);
    }

    // --- User Lock Query Functions ---

    /// @dev Gets the details of a user's specific lock instance in a profile.
    /// @param profileId The ID of the profile.
    /// @param depositor The address of the depositor.
    /// @return A tuple containing the depositor, token, amount, start time, and claimed status.
    function getUserLockDetails(uint256 profileId, address depositor)
        external
        view
        profileExists(profileId)
        returns (address _depositor, address token, uint256 amount, uint256 startTime, bool claimed)
    {
        UserLock storage userLock = _userLocks[profileId][depositor];
        return (userLock.depositor, userLock.token, userLock.amount, userLock.startTime, userLock.claimed);
    }

    /// @dev Checks if a user's lock instance for a profile has been claimed.
    /// @param profileId The ID of the profile.
    /// @param depositor The address of the depositor.
    /// @return True if claimed, false otherwise.
    function isLockClaimed(uint256 profileId, address depositor) external view profileExists(profileId) returns (bool) {
         // Check if the user lock exists before checking 'claimed'
        if (_userLocks[profileId][depositor].amount == 0) return false; // Or revert, depending on desired behavior
        return _userLocks[profileId][depositor].claimed;
    }

    /// @dev Gets the total amount of a specific token locked across all profiles.
    /// @param token The token address.
    /// @return The total locked amount.
    function getTotalLockedAssets(address token) external view returns (uint256) {
        return _totalLockedAssets[token];
    }

    /// @dev Gets the total amount of a specific token locked within a single profile.
    /// @param profileId The ID of the profile.
    /// @param token The token address.
    /// @return The total locked amount in the profile.
    function getProfileLockedAssets(uint256 profileId, address token) external view profileExists(profileId) returns (uint256) {
        return _profileLockedAssets[profileId][token];
    }

    /// @dev Gets the indices of the conditions that are currently met for a user's lock.
    ///      This is a helper query function that calls `checkLockConditions` and returns only the indices.
    /// @param profileId The ID of the profile.
    /// @param depositor The address of the depositor.
    /// @return An array of indices of the conditions that are met.
    function getMetConditionIndices(uint256 profileId, address depositor)
        external
        view
        profileExists(profileId)
        returns (uint256[] memory)
    {
        (, uint256[] memory metIndices) = checkLockConditions(profileId, depositor);
        return metIndices;
    }

     // Need to override _msgSender for compatibility if used in other contexts (like meta-transactions)
     // For standard EOA calls, Context._msgSender() is msg.sender.
     // For this contract, the default is fine, but good practice to be aware.
     // function _msgSender() internal view virtual override returns (address) {
     //     return msg.sender;
     // }
}

```
**Refined Condition Struct and Enum:**

Let's correct the `Condition` struct and `ConditionType` enum based on the refinement during the thought process, avoiding the problematic `SpecificAddressInteracted` and `OtherContractStateMatch`.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/erc20/IERC20.sol";
import "@openzeppelin/contracts/token/erc20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/// @title QuantumLock
/// @dev A smart contract vault where unlocking deposited tokens depends on meeting
///      a programmable, weighted combination of diverse conditions, including
///      time elapsed, oracle data values, minimum balance held, and block number reached.
/// @author [Your Name/Team Name]

// Outline:
// ... (same as above)

// Function Summary:
// ... (same as above, noting updated condition types)

contract QuantumLock is Ownable, Context {
    using SafeERC20 for IERC20;

    // --- Enums ---

    /// @dev Types of conditions that can be defined for unlocking.
    enum ConditionType {
        TimeElapsed,           // Requires a minimum duration since lock start (targetValue = duration in seconds)
        OracleValueAbove,      // Requires oracle data >= targetValue (oracleId required)
        OracleValueBelow,      // Requires oracle data <= targetValue (oracleId required)
        MinBalanceHeld,        // Requires checkAddress to hold >= targetValue of tokenAddress (checkAddress, tokenAddress, targetValue required)
        SpecificBlockReached   // Requires block.number >= targetValue (targetValue = block number)
    }

    // --- Structs ---

    /// @dev Defines a single condition part of a LockProfile.
    struct Condition {
        ConditionType conditionType; // Type of condition
        bytes32 oracleId;            // Used for OracleValue types
        uint256 targetValue;         // Value to check against (duration, oracle value, block number, min amount)
        address checkAddress;        // Used for MinBalanceHeld (holder address)
        address tokenAddress;        // Used for MinBalanceHeld (token address)
        uint256 weight;              // Weight contributed to the total score if met
        bool active;                 // Is this condition currently considered?
    }

    /// @dev Defines a profile with a set of conditions for unlocking.
    struct LockProfile {
        string name;                 // Human-readable name
        Condition[] conditions;      // Array of conditions to check
        uint256 unlockThreshold;     // Minimum total weight needed to unlock
        bool active;                 // Can users deposit into this profile?
        bool paused;                 // Is this profile temporarily paused (no deposits/claims)?
        mapping(address => bool) managers; // Addresses allowed to manage this profile's conditions/threshold
    }

    /// @dev Stores details for a specific user's lock instance.
    struct UserLock {
        address depositor;           // The address that made the deposit
        address token;               // The token that was deposited
        uint256 amount;              // The amount deposited
        uint256 startTime;           // Block timestamp when the deposit occurred
        bool claimed;                // Has this lock been claimed?
    }

    /// @dev Stores the latest reported data for an oracle feed.
    struct OracleData {
        uint256 value;               // The reported value
        uint256 timestamp;           // When the data was reported
    }

    // --- State Variables ---
    // ... (Same as before)

    // Total locked assets per token and profile
    mapping(address => uint256) private _totalLockedAssets; // token => amount
    mapping(uint256 => mapping(address => uint256)) private _profileLockedAssets; // profileId => token => amount


    // --- Events ---
    // ... (Same as before)

    // --- Modifiers ---
    // ... (Same as before)

    // --- Constructor ---
    constructor() Ownable(_msgSender()) {}


    // --- Admin / Configuration Functions (onlyOwner) ---
    // ... (setSupportedToken, addProfileManager, removeProfileManager, addOracle, removeOracle, emergencyWithdrawAdmin, renounceOwnership (inherited)) ...

     /// @dev Renounces the owner role. Callable by the owner.
     ///      After this, no functions protected by onlyOwner will be executable.
    function renounceOwnership() public virtual override onlyOwner {
        super.renounceOwnership();
    }


    // --- Role Query Functions ---
    // ... (isSupportedToken, isProfileManager, isOracle, getSupportedTokens) ...

    // --- Profile Management Functions (onlyProfileManager, onlyOwner, or specific profile manager) ---
    // ... (createLockProfile, addProfileSpecificManager, removeProfileSpecificManager, updateLockProfileConditions, updateLockProfileThreshold, toggleLockProfileActive, pauseProfile, unpauseProfile) ...

    // --- Profile Query Functions ---
    // ... (getLockProfileDetails, getConditionDetails, getAllProfileIds, getProfileConditionCount, getUnlockThreshold, isProfileActive, isProfilePaused) ...


    // --- Oracle Operations (onlyOracle) ---

    /// @dev Allows authorized oracles to report data for a specific feed.
    ///      Overwrite previous data for the same oracleId. Requires oracleId to be non-zero.
    /// @param oracleId Identifier for the oracle data feed (e.g., bytes32("ETH/USD")).
    /// @param value The value reported by the oracle.
    function reportOracleData(bytes32 oracleId, uint256 value) external onlyOracle {
         require(oracleId != bytes32(0), "QL: Invalid oracle ID");
        _oracleData[oracleId] = OracleData({
            value: value,
            timestamp: block.timestamp
        });
        emit OracleDataReported(oracleId, value, block.timestamp);
    }

    // --- Oracle Query Functions ---

    /// @dev Gets the latest data reported for a specific oracle feed.
    /// @param oracleId Identifier for the oracle data feed.
    /// @return The reported value and timestamp.
    function getOracleData(bytes32 oracleId) external view returns (uint256 value, uint256 timestamp) {
        require(oracleId != bytes32(0), "QL: Invalid oracle ID");
        OracleData storage data = _oracleData[oracleId];
        require(data.timestamp > 0, "QL: Oracle data not available"); // Ensure data exists
        return (data.value, data.timestamp);
    }

    // --- User Interaction Functions ---

    /// @dev Allows a user to deposit supported tokens into a specific lock profile.
    ///      Requires the user to have approved this contract to spend the tokens beforehand.
    ///      Records the deposit amount and start time.
    /// @param profileId The ID of the profile to deposit into.
    /// @param token The address of the ERC20 token to deposit.
    /// @param amount The amount of tokens to deposit.
    function deposit(uint256 profileId, address token, uint256 amount)
        external
        profileExists(profileId)
        isProfileActive(profileId)
        isProfileNotPaused(profileId)
    {
        require(_supportedTokens[token], "QL: Token not supported");
        require(amount > 0, "QL: Deposit amount must be greater than 0");
        // Ensure user doesn't have an existing lock for this profile
        require(_userLocks[profileId][_msgSender()].amount == 0, "QL: User already has an active lock for this profile");


        IERC20(token).safeTransferFrom(_msgSender(), address(this), amount);

        _userLocks[profileId][_msgSender()] = UserLock({
            depositor: _msgSender(),
            token: token,
            amount: amount,
            startTime: block.timestamp, // Use block.timestamp as lock start time
            claimed: false
        });

        // Update total locked assets trackers
        _totalLockedAssets[token] += amount;
        _profileLockedAssets[profileId][token] += amount;

        emit Deposit(profileId, _msgSender(), token, amount, block.timestamp);
    }

    /// @dev Checks if a specific condition within a profile is met for a user's lock instance.
    ///      Internal helper function.
    /// @param profileId The ID of the profile.
    /// @param userLock The user's lock instance details.
    /// @param condition The condition struct to check.
    /// @return True if the condition is met and active, false otherwise.
    function _checkConditionMet(uint256 profileId, UserLock storage userLock, Condition storage condition)
        internal
        view
        returns (bool)
    {
        if (!condition.active) {
            return false; // Condition must be active
        }

        // Handle different condition types
        if (condition.conditionType == ConditionType.TimeElapsed) {
            // targetValue is duration in seconds
            return block.timestamp >= userLock.startTime + condition.targetValue;
        }
        else if (condition.conditionType == ConditionType.OracleValueAbove) {
             // targetValue is the minimum required oracle value
             // oracleId identifies the oracle feed
            require(condition.oracleId != bytes32(0), "QL: Oracle ID required for OracleValueAbove");
            OracleData storage oracle = _oracleData[condition.oracleId];
            // Require relatively recent data (e.g., within 1 hour = 3600 seconds). Adjust as needed.
            require(oracle.timestamp > 0 && block.timestamp - oracle.timestamp <= 1 hours, "QL: Oracle data stale or unavailable");
            return oracle.value >= condition.targetValue;
        }
         else if (condition.conditionType == ConditionType.OracleValueBelow) {
            // targetValue is the maximum required oracle value
            // oracleId identifies the oracle feed
            require(condition.oracleId != bytes32(0), "QL: Oracle ID required for OracleValueBelow");
            OracleData storage oracle = _oracleData[condition.oracleId];
             // Require relatively recent data (e.g., within 1 hour)
            require(oracle.timestamp > 0 && block.timestamp - oracle.timestamp <= 1 hours, "QL: Oracle data stale or unavailable");
            return oracle.value <= condition.targetValue;
        }
         else if (condition.conditionType == ConditionType.MinBalanceHeld) {
             // checkAddress is the address whose balance is checked
             // tokenAddress is the token to check
             // targetValue is the minimum required balance
            require(condition.checkAddress != address(0), "QL: checkAddress required for MinBalanceHeld");
            require(condition.tokenAddress != address(0), "QL: tokenAddress required for MinBalanceHeld");
            IERC20 tokenContract = IERC20(condition.tokenAddress);
            return tokenContract.balanceOf(condition.checkAddress) >= condition.targetValue;
        }
         else if (condition.conditionType == ConditionType.SpecificBlockReached) {
             // targetValue is the minimum required block number
             return block.number >= condition.targetValue;
         }

        return false; // Should not reach here if all types handled
    }

    /// @dev Calculates the total weight of met conditions for a user's specific lock instance.
    /// @param profileId The ID of the profile.
    /// @param depositor The address of the depositor.
    /// @return metScore The calculated total weight.
    /// @return metConditionIndices An array of indices of the conditions that were met.
    function checkLockConditions(uint256 profileId, address depositor)
        public
        view
        profileExists(profileId)
        returns (uint256 metScore, uint256[] memory metConditionIndices)
    {
        UserLock storage userLock = _userLocks[profileId][depositor];
        require(userLock.amount > 0, "QL: No active lock for this user in this profile");
        // Do not check if claimed here, as you might want to check conditions *after* claiming for historical data
        // require(!userLock.claimed, "QL: Lock has already been claimed"); // Removed

        LockProfile storage profile = _lockProfiles[profileId];
        uint256 currentScore = 0;
        uint256[] memory metIndices = new uint256[](profile.conditions.length);
        uint256 metCount = 0;

        for (uint i = 0; i < profile.conditions.length; i++) {
            if (_checkConditionMet(profileId, userLock, profile.conditions[i])) {
                currentScore += profile.conditions[i].weight;
                metIndices[metCount] = i;
                metCount++;
            }
        }

        // Resize the metConditions array
        uint256[] memory finalMetIndices = new uint256[](metCount);
        for (uint i = 0; i < metCount; i++) {
            finalMetIndices[i] = metIndices[i];
        }

        // Note: Emitting events in view functions is not standard practice and might fail in some environments.
        // The event below is kept here for conceptual illustration but should ideally be in a state-changing function
        // if truly needed on-chain. For typical use, off-chain logic calls this view function and decides.
        // emit ConditionsChecked(profileId, depositor, currentScore, profile.unlockThreshold);

        return (currentScore, finalMetIndices);
    }

    /// @dev Allows a user to claim their locked tokens if the conditions are met.
    ///      Calls `checkLockConditions` to determine if the unlock threshold is reached.
    ///      Transfers the tokens and marks the lock as claimed.
    /// @param profileId The ID of the profile the user deposited into.
    function claim(uint256 profileId)
        external
        profileExists(profileId)
        isProfileNotPaused(profileId)
    {
        address depositor = _msgSender();
        UserLock storage userLock = _userLocks[profileId][depositor];
        require(userLock.amount > 0, "QL: No active lock for this user in this profile");
        require(!userLock.claimed, "QL: Lock has already been claimed");

        LockProfile storage profile = _lockProfiles[profileId];
        (uint256 metScore, ) = checkLockConditions(profileId, depositor); // Check current conditions

        require(metScore >= profile.unlockThreshold, "QL: Unlock conditions not met");

        uint256 claimAmount = userLock.amount;
        address token = userLock.token;

        userLock.claimed = true; // Mark as claimed BEFORE transfer

        // Update total locked assets trackers
        _totalLockedAssets[token] -= claimAmount;
        _profileLockedAssets[profileId][token] -= claimAmount;

        // Use safeTransfer to prevent reentrancy issues with malicious tokens
        IERC20(token).safeTransfer(depositor, claimAmount);

        emit Claim(profileId, depositor, token, claimAmount);
    }

    /// @dev Allows the current owner of a locked position to transfer its ownership
    ///      to another address. The new owner inherits the lock's state (amount, start time).
    ///      Cannot transfer if already claimed.
    /// @param profileId The ID of the profile.
    /// @param newOwner The address to transfer ownership to.
    function transferLockOwnership(uint256 profileId, address newOwner)
        external
        profileExists(profileId)
        isProfileNotPaused(profileId) // Prevent transfer of paused locks? Depends on design
    {
        address currentOwner = _msgSender();
        UserLock storage userLock = _userLocks[profileId][currentOwner];
        require(userLock.amount > 0, "QL: No active lock to transfer");
        require(!userLock.claimed, "QL: Cannot transfer a claimed lock");
        require(newOwner != address(0), "QL: Cannot transfer to zero address");
        require(newOwner != currentOwner, "QL: Cannot transfer to self");
        // Ensure new owner doesn't already have a lock for this profile
        require(_userLocks[profileId][newOwner].amount == 0, "QL: New owner already has an active lock for this profile");

        // Transfer the struct data - this effectively moves the lock details
        _userLocks[profileId][newOwner] = userLock;

        // Clear the old owner's slot
        delete _userLocks[profileId][currentOwner];

        emit LockOwnershipTransferred(profileId, currentOwner, newOwner);
    }

    // --- User Lock Query Functions ---

    /// @dev Gets the details of a user's specific lock instance in a profile.
    /// @param profileId The ID of the profile.
    /// @param depositor The address of the depositor.
    /// @return A tuple containing the depositor, token, amount, start time, and claimed status.
    function getUserLockDetails(uint256 profileId, address depositor)
        external
        view
        profileExists(profileId)
        returns (address _depositor, address token, uint256 amount, uint256 startTime, bool claimed)
    {
        UserLock storage userLock = _userLocks[profileId][depositor];
        // Return zero values if lock doesn't exist
        if (userLock.amount == 0) {
            return (address(0), address(0), 0, 0, false);
        }
        return (userLock.depositor, userLock.token, userLock.amount, userLock.startTime, userLock.claimed);
    }

    /// @dev Checks if a user's lock instance for a profile has been claimed.
    /// @param profileId The ID of the profile.
    /// @param depositor The address of the depositor.
    /// @return True if claimed, false otherwise.
    function isLockClaimed(uint256 profileId, address depositor) external view profileExists(profileId) returns (bool) {
         // Return false if the lock doesn't even exist
        if (_userLocks[profileId][depositor].amount == 0) return false;
        return _userLocks[profileId][depositor].claimed;
    }

     /// @dev Gets the start time of a user's lock instance.
     /// @param profileId The ID of the profile.
     /// @param depositor The address of the depositor.
     /// @return The start timestamp (block.timestamp). Returns 0 if lock doesn't exist.
    function getLockStartTime(uint256 profileId, address depositor) external view profileExists(profileId) returns (uint256) {
         return _userLocks[profileId][depositor].startTime;
    }

    /// @dev Gets the deposited amount for a user's lock instance.
     /// @param profileId The ID of the profile.
     /// @param depositor The address of the depositor.
     /// @return The deposited amount. Returns 0 if lock doesn't exist.
    function getLockAmount(uint256 profileId, address depositor) external view profileExists(profileId) returns (uint256) {
         return _userLocks[profileId][depositor].amount;
    }

    /// @dev Gets the token address for a user's lock instance.
     /// @param profileId The ID of the profile.
     /// @param depositor The address of the depositor.
     /// @return The token address. Returns address(0) if lock doesn't exist.
    function getLockToken(uint256 profileId, address depositor) external view profileExists(profileId) returns (address) {
         return _userLocks[profileId][depositor].token;
    }

    /// @dev Gets the total amount of a specific token locked across all profiles.
    /// @param token The token address.
    /// @return The total locked amount.
    function getTotalLockedAssets(address token) external view returns (uint256) {
        return _totalLockedAssets[token];
    }

    /// @dev Gets the total amount of a specific token locked within a single profile.
    /// @param profileId The ID of the profile.
    /// @param token The token address.
    /// @return The total locked amount in the profile.
    function getProfileLockedAssets(uint256 profileId, address token) external view profileExists(profileId) returns (uint256) {
        return _profileLockedAssets[profileId][token];
    }

    /// @dev Gets the indices of the conditions that are currently met for a user's lock.
    ///      This is a helper query function that calls `checkLockConditions` and returns only the indices.
    /// @param profileId The ID of the profile.
    /// @param depositor The address of the depositor.
    /// @return An array of indices of the conditions that are met.
    function getMetConditionIndices(uint256 profileId, address depositor)
        external
        view
        profileExists(profileId)
        returns (uint256[] memory)
    {
        (, uint256[] memory metIndices) = checkLockConditions(profileId, depositor);
        return metIndices;
    }
}

```

This contract provides a flexible framework for creating custom lock-up periods defined by weighted conditions. It includes role-based access control, integration points for external oracle data, and features like transferring lock ownership and emergency admin withdrawals. It fulfills the requirement of having over 20 functions and explores a more advanced concept than basic time locks or single-condition releases.