Okay, here is a Solidity smart contract concept called `QuantumVault`. It's inspired by quantum mechanics (states, superposition, observation, collapse) applied to managing potential outcomes and asset distribution. It uses role-based access, pausable functionality, and a mechanism for conditional, probabilistic collapse triggered by external data (simulated).

It avoids duplicating standard ERC-20/721, simple DeFi, or DAO patterns directly, focusing on a unique state-management and probabilistic distribution model.

**Outline and Function Summary:**

1.  **Pragma and Imports:** Specify Solidity version.
2.  **Error Definitions:** Custom errors for clarity.
3.  **Events:** Log key actions like state changes, superposition, collapse, withdrawals, role management, pausing.
4.  **Structs:**
    *   `Claim`: Defines a potential recipient and their percentage share *within* a specific State.
    *   `State`: Represents a distinct potential outcome, containing a list of Claims, a probability weight, and a hash representing off-chain conditions.
5.  **State Variables:**
    *   Vault state: `_owner`, `_paused`, `_roles`, `_stateCounter`, `states`, `stateIds`, `isInSuperposition`, `superpositionStartTime`, `collapsedStateId`, `settledBalances`, `userStatePreferences`.
    *   Roles: Constants for different access levels (`ADMIN_ROLE`, `STATE_MANAGER_ROLE`, `COLLAPSE_MANAGER_ROLE`).
6.  **Modifiers:** Common access control and state modifiers (`onlyOwner`, `hasRole`, `whenNotPaused`, `whenInSuperposition`, `whenNotInSuperposition`, `whenCollapsed`, `stateExists`).
7.  **Constructor:** Initializes owner and grants admin role.
8.  **Receive Ether Function:** Allows Ether deposits into the vault.
9.  **Core Vault Management:**
    *   `getTotalVaultBalance()`: Get total Ether held.
    *   `getSettledBalance(address user)`: Get user's final balance after collapse.
    *   `withdrawSettledBalance()`: User withdraws their settled balance.
10. **State Definition & Management (Requires STATE_MANAGER_ROLE):**
    *   `defineState()`: Create a new potential outcome State.
    *   `updateState()`: Modify an existing State.
    *   `deleteState()`: Remove a State (only before superposition).
    *   `getStateDetails()`: Retrieve details of a State.
    *   `getAllStateIds()`: Get list of all defined State IDs.
    *   `getStateConditionHash()`: Get condition hash for a State.
    *   `getStateProbabilityWeight()`: Get probability weight for a State.
11. **Superposition Control (Requires STATE_MANAGER_ROLE):**
    *   `enterSuperposition()`: Transition the vault into the active probabilistic state phase.
    *   `exitSuperposition()`: Emergency exit from superposition (resets state definitions).
    *   `isSuperpositionActive()`: Check if superposition is active.
    *   `getSuperpositionStartTime()`: Get timestamp of superposition start.
12. **User Interaction (within Superposition):**
    *   `registerStatePreference()`: Users register their claim/preference for a specific State *if* it collapses. Makes them eligible for payout in that State.
    *   `hasRegisteredPreference()`: Check if a user registered for a State.
    *   `getUserPreferences()`: Get list of states a user registered for.
13. **Observation and Collapse (Requires COLLAPSE_MANAGER_ROLE):**
    *   `submitOracleDataHash()`: Simulates submitting relevant external data (or its hash) which influences collapse conditions. *Note: Actual oracle integration is complex and requires off-chain verification or dedicated oracle protocols. This is a simplified placeholder.*
    *   `triggerCollapseEvaluation()`: Initiates the collapse process. Requires providing the claimed `chosenStateId` and a `validationProof` (simulated proof that the `chosenStateId` matches conditions based on oracle data and state definitions). The contract trusts the `COLLAPSE_MANAGER_ROLE` and the `validationProof` format (which would be defined off-chain).
    *   `getCollapsedStateId()`: Get the ID of the State that was chosen after collapse.
    *   `isCollapsed()`: Check if the vault has collapsed.
14. **Role Management (Requires ADMIN_ROLE or relevant admin role):**
    *   `grantRole()`: Assign a role to an account.
    *   `revokeRole()`: Remove a role from an account.
    *   `hasRole()`: Check if an account has a role.
    *   `setRoleAdmin()`: Define which role can manage another role.
    *   `getRoleAdmin()`: Get the managing role for a given role.
15. **Pausable Functions (Requires ADMIN_ROLE):**
    *   `pause()`: Halt critical operations.
    *   `unpause()`: Resume operations.
    *   `paused()`: Check pause status.
16. **Ownership Management:**
    *   `transferOwnership()`: Transfer contract ownership.
    *   `renounceOwnership()`: Renounce ownership.
    *   `getOwner()`: Get current owner.

This structure provides over 30 public/external functions, covering the requirements.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumVault
 * @dev A smart contract simulating quantum-inspired state management for asset distribution.
 * Assets are held in a "Superposition" of potential "States" with associated
 * probabilities and conditions. An "Observation" process, potentially influenced
 * by external data (oracle), "Collapses" the superposition into a single
 * chosen State, and assets are distributed based on the claims defined in that State.
 * Users must register their "Preference" for a state to be eligible for payouts
 * if that state is chosen.
 *
 * Outline:
 * - Error Definitions
 * - Events
 * - Structs (Claim, State)
 * - State Variables (Vault state, Roles, Pausable)
 * - Modifiers (Access Control, State Checks)
 * - Constructor
 * - Receive Ether
 * - Core Vault Management
 * - State Definition & Management
 * - Superposition Control
 * - User Interaction (within Superposition)
 * - Observation and Collapse
 * - Role Management
 * - Pausable
 * - Ownership Management
 *
 * Function Summary (Over 20 functions implemented):
 * - getTotalVaultBalance: Returns the total Ether balance of the contract.
 * - getSettledBalance: Returns the final calculated balance for a user after collapse.
 * - withdrawSettledBalance: Allows a user to withdraw their settled balance.
 * - defineState: Allows a role-assigned manager to define a new potential outcome state.
 * - updateState: Allows a role-assigned manager to update an existing state (only before superposition).
 * - deleteState: Allows a role-assigned manager to delete a state (only before superposition).
 * - getStateDetails: Retrieves the claims, weight, and conditions hash for a specific state ID.
 * - getAllStateIds: Returns an array of all defined state IDs.
 * - getStateConditionHash: Gets the conditions hash for a state.
 * - getStateProbabilityWeight: Gets the probability weight for a state.
 * - enterSuperposition: Transitions the vault into the superposition phase (requires role, min states).
 * - exitSuperposition: Emergency exit from superposition (requires role, resets states).
 * - isSuperpositionActive: Checks if the vault is currently in superposition.
 * - getSuperpositionStartTime: Gets the timestamp when superposition started.
 * - registerStatePreference: Allows users to register their interest/eligibility for a specific state's payout if it collapses to that state.
 * - hasRegisteredPreference: Checks if a user has registered preference for a state.
 * - getUserPreferences: Gets the state IDs a user has registered preferences for.
 * - submitOracleDataHash: Allows a role-assigned oracle to submit data (or its hash) influencing conditions. (Simulated).
 * - triggerCollapseEvaluation: Allows a role-assigned manager to trigger the collapse, providing the chosen state ID and a validation proof based on off-chain evaluation of conditions and oracle data.
 * - getCollapsedStateId: Returns the ID of the state that was finally chosen after collapse.
 * - isCollapsed: Checks if the vault has collapsed.
 * - grantRole: Grants a role to an account.
 * - revokeRole: Revokes a role from an account.
 * - hasRole: Checks if an account has a specific role.
 * - setRoleAdmin: Defines which role can administer another role.
 * - getRoleAdmin: Gets the admin role for a given role.
 * - pause: Pauses contract operations (requires admin role).
 * - unpause: Unpauses contract operations (requires admin role).
 * - paused: Checks if the contract is paused.
 * - transferOwnership: Transfers contract ownership.
 * - renounceOwnership: Renounces contract ownership.
 * - getOwner: Gets the current owner.
 */
contract QuantumVault {

    // --- Error Definitions ---
    error NotOwner();
    error NotAdminRole();
    error NotStateManagerRole();
    error NotCollapseManagerRole();
    error Paused();
    error NotPaused();
    error SuperpositionActive();
    error SuperpositionNotActive();
    error AlreadyCollapsed();
    error NotCollapsed();
    error StateDoesNotExist(uint256 stateId);
    error MinStatesRequired(uint256 required);
    error InvalidStateClaims(string reason);
    error ClaimPercentageExceeds100();
    error NoSettledBalance();
    error StateCannotBeDeletedInSuperposition();
    error StateCannotBeUpdatedInSuperposition();
    error PreferenceRegistrationOnlyInSuperposition();
    error InvalidCollapseParameters();

    // --- Events ---
    event EtherDeposited(address indexed user, uint256 amount);
    event SettledBalanceWithdrawn(address indexed user, uint256 amount);
    event StateDefined(uint256 indexed stateId, bytes32 conditionsHash, uint256 probabilityWeight);
    event StateUpdated(uint256 indexed stateId, bytes32 conditionsHash, uint256 probabilityWeight);
    event StateDeleted(uint256 indexed stateId);
    event SuperpositionEntered(uint256 timestamp);
    event SuperpositionExitedWithoutCollapse();
    event StatePreferenceRegistered(address indexed user, uint256 indexed stateId);
    event OracleDataHashSubmitted(bytes32 indexed dataHash, uint256 timestamp);
    event CollapseEvaluationTriggered(uint256 indexed chosenStateId, bytes validationProof);
    event SuperpositionCollapsed(uint256 indexed chosenStateId, uint256 timestamp);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event Paused(address account);
    event Unpaused(address account);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // --- Structs ---

    /// @dev Defines a claim within a State: recipient address and their percentage share of the total vault balance.
    struct Claim {
        address recipient;
        uint256 percentage; // Percentage of the total vault balance (e.g., 5000 for 50.00%)
    }

    /// @dev Represents a potential outcome State with a set of claims, probability weight, and conditions.
    struct State {
        Claim[] claims;
        uint256 probabilityWeight; // Relative weight for probabilistic collapse (e.g., 1-100)
        bytes32 conditionsHash;  // Hash representing off-chain conditions for this state to be viable
        bool isDefined;          // Flag to check if this stateId is actively defined
    }

    // --- State Variables ---

    address private _owner;
    bool private _paused;

    // Role management
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant STATE_MANAGER_ROLE = keccak256("STATE_MANAGER_ROLE");
    bytes32 public constant COLLAPSE_MANAGER_ROLE = keccak256("COLLAPSE_MANAGER_ROLE");
    mapping(bytes32 => mapping(address => bool)) private _roles;
    mapping(bytes32 => bytes32) private _roleAdmin;

    // State definition
    uint256 private _stateCounter; // Used to generate unique state IDs
    mapping(uint256 => State) private states;
    uint256[] private stateIds; // Array to keep track of existing state IDs

    // Superposition state
    bool public isInSuperposition;
    uint256 public superpositionStartTime;

    // Collapse state
    bool public isCollapsed;
    uint256 public collapsedStateId; // 0 if not collapsed

    // Balances after collapse
    mapping(address => uint256) private settledBalances;

    // User preferences during superposition
    mapping(address => mapping(uint256 => bool)) private userStatePreferences; // user => stateId => registered

    // --- Modifiers ---

    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert NotOwner();
        }
        _;
    }

    modifier hasRole(bytes32 role) {
        if (!_roles[role][msg.sender]) {
            if (role == ADMIN_ROLE) revert NotAdminRole();
            if (role == STATE_MANAGER_ROLE) revert NotStateManagerRole();
            if (role == COLLAPSE_MANAGER_ROLE) revert NotCollapseManagerRole();
            // Fallback for other roles, though these are the main ones defined
            revert NotAdminRole(); // Generic permission error
        }
        _;
    }

    modifier whenNotPaused() {
        if (_paused) {
            revert Paused();
        }
        _;
    }

    modifier whenPaused() {
        if (!_paused) {
            revert NotPaused();
        }
        _;
    }

    modifier whenInSuperposition() {
        if (!isInSuperposition) {
            revert SuperpositionNotActive();
        }
        _;
    }

    modifier whenNotInSuperposition() {
        if (isInSuperposition) {
            revert SuperpositionActive();
        }
        _;
    }

    modifier whenCollapsed() {
        if (!isCollapsed) {
            revert NotCollapsed();
        }
        _;
    }

     modifier whenNotCollapsed() {
        if (isCollapsed) {
            revert AlreadyCollapsed();
        }
        _;
    }

    modifier stateExists(uint256 stateId) {
        if (!states[stateId].isDefined) {
            revert StateDoesNotExist(stateId);
        }
        _;
    }

    // --- Constructor ---

    constructor() {
        _owner = msg.sender;
        _grantRole(ADMIN_ROLE, msg.sender);
        _roleAdmin[ADMIN_ROLE] = ADMIN_ROLE; // Admin can manage itself
        _roleAdmin[STATE_MANAGER_ROLE] = ADMIN_ROLE;
        _roleAdmin[COLLAPSE_MANAGER_ROLE] = ADMIN_ROLE;

        _paused = false;
        isInSuperposition = false;
        isCollapsed = false;
        collapsedStateId = 0;
        _stateCounter = 0;
    }

    // --- Receive Ether ---

    /// @dev Allows users to deposit Ether into the vault.
    receive() external payable whenNotPaused whenNotCollapsed {
        emit EtherDeposited(msg.sender, msg.value);
    }

    // --- Core Vault Management ---

    /// @dev Returns the total Ether balance currently held by the contract.
    function getTotalVaultBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /// @dev Returns the final calculated balance for a specific user after the vault has collapsed.
    /// @param user The address to query the settled balance for.
    /// @return The settled balance for the user. Returns 0 if not yet collapsed or user has no settled balance.
    function getSettledBalance(address user) public view returns (uint256) {
        return settledBalances[user];
    }

    /// @dev Allows a user to withdraw their determined settled balance after the vault has collapsed.
    function withdrawSettledBalance() public whenCollapsed whenNotPaused {
        uint256 amount = settledBalances[msg.sender];
        if (amount == 0) {
            revert NoSettledBalance();
        }

        settledBalances[msg.sender] = 0;

        // Use a low-level call to avoid potential reentrancy issues from recipient logic,
        // while still allowing transfer to contracts/EOAs.
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed"); // Basic success check

        emit SettledBalanceWithdrawn(msg.sender, amount);
    }

    // --- State Definition & Management (Requires STATE_MANAGER_ROLE) ---

    /// @dev Defines a new potential outcome state for the vault.
    ///      Only callable when not in superposition and not paused.
    /// @param claims The list of claims defining asset distribution in this state.
    /// @param probabilityWeight The relative weight for this state in probabilistic collapse scenarios.
    /// @param conditionsHash A hash representing the off-chain conditions that make this state valid.
    function defineState(Claim[] calldata claims, uint256 probabilityWeight, bytes32 conditionsHash)
        external
        hasRole(STATE_MANAGER_ROLE)
        whenNotPaused
        whenNotInSuperposition
    {
        uint256 totalPercentage = 0;
        for (uint i = 0; i < claims.length; i++) {
            if (claims[i].recipient == address(0)) {
                revert InvalidStateClaims("Zero address recipient");
            }
            totalPercentage += claims[i].percentage;
        }
        if (totalPercentage > 10000) { // 10000 for 100%
            revert ClaimPercentageExceeds100();
        }

        _stateCounter++;
        uint256 newStateId = _stateCounter;
        states[newStateId] = State({
            claims: claims,
            probabilityWeight: probabilityWeight,
            conditionsHash: conditionsHash,
            isDefined: true
        });
        stateIds.push(newStateId);

        emit StateDefined(newStateId, conditionsHash, probabilityWeight);
    }

    /// @dev Updates an existing state. Only callable when not in superposition and not paused.
    /// @param stateId The ID of the state to update.
    /// @param claims The new list of claims.
    /// @param probabilityWeight The new probability weight.
    /// @param conditionsHash The new conditions hash.
    function updateState(uint256 stateId, Claim[] calldata claims, uint256 probabilityWeight, bytes32 conditionsHash)
        external
        hasRole(STATE_MANAGER_ROLE)
        whenNotPaused
        whenNotInSuperposition
        stateExists(stateId)
    {
         uint256 totalPercentage = 0;
        for (uint i = 0; i < claims.length; i++) {
             if (claims[i].recipient == address(0)) {
                revert InvalidStateClaims("Zero address recipient");
            }
            totalPercentage += claims[i].percentage;
        }
        if (totalPercentage > 10000) {
            revert ClaimPercentageExceeds100();
        }

        states[stateId].claims = claims;
        states[stateId].probabilityWeight = probabilityWeight;
        states[stateId].conditionsHash = conditionsHash;

        emit StateUpdated(stateId, conditionsHash, probabilityWeight);
    }

    /// @dev Deletes a defined state. Only callable when not in superposition and not paused.
    /// @param stateId The ID of the state to delete.
    function deleteState(uint256 stateId)
        external
        hasRole(STATE_MANAGER_ROLE)
        whenNotPaused
        whenNotInSuperposition
        stateExists(stateId)
    {
        states[stateId].isDefined = false; // Mark as undefined
        delete states[stateId]; // Clear storage

        // Remove from stateIds array (inefficient for large arrays)
        uint256 indexToRemove = type(uint256).max;
        for(uint i = 0; i < stateIds.length; i++) {
            if (stateIds[i] == stateId) {
                indexToRemove = i;
                break;
            }
        }
        if (indexToRemove != type(uint256).max) {
             stateIds[indexToRemove] = stateIds[stateIds.length - 1];
             stateIds.pop();
        }

        emit StateDeleted(stateId);
    }

    /// @dev Retrieves the claims, weight, and conditions hash for a specific state.
    /// @param stateId The ID of the state to query.
    /// @return claims The array of claims for the state.
    /// @return probabilityWeight The probability weight of the state.
    /// @return conditionsHash The conditions hash of the state.
    function getStateDetails(uint256 stateId)
        public
        view
        stateExists(stateId)
        returns (Claim[] memory claims, uint256 probabilityWeight, bytes32 conditionsHash)
    {
        State storage state = states[stateId];
        return (state.claims, state.probabilityWeight, state.conditionsHash);
    }

    /// @dev Returns a list of all currently defined state IDs.
    function getAllStateIds() public view returns (uint256[] memory) {
        uint256[] memory activeIds = new uint256[](stateIds.length);
        uint256 count = 0;
        for(uint i = 0; i < stateIds.length; i++) {
            if(states[stateIds[i]].isDefined) {
                activeIds[count] = stateIds[i];
                count++;
            }
        }
        // Resize array to remove undefined state placeholders
        uint256[] memory result = new uint256[](count);
        for(uint i = 0; i < count; i++) {
            result[i] = activeIds[i];
        }
        return result;
    }

    /// @dev Gets the conditions hash associated with a specific state.
    /// @param stateId The ID of the state.
    /// @return The conditions hash.
    function getStateConditionHash(uint256 stateId) public view stateExists(stateId) returns (bytes32) {
        return states[stateId].conditionsHash;
    }

    /// @dev Gets the probability weight associated with a specific state.
    /// @param stateId The ID of the state.
    /// @return The probability weight.
    function getStateProbabilityWeight(uint256 stateId) public view stateExists(stateId) returns (uint256) {
        return states[stateId].probabilityWeight;
    }


    // --- Superposition Control (Requires STATE_MANAGER_ROLE) ---

    /// @dev Transitions the vault into the "Superposition" state.
    ///      This locks state definitions and allows user preference registration.
    ///      Requires at least one state to be defined.
    function enterSuperposition()
        external
        hasRole(STATE_MANAGER_ROLE)
        whenNotPaused
        whenNotInSuperposition
        whenNotCollapsed
    {
        uint256 numStates = getAllStateIds().length;
        if (numStates < 1) {
            revert MinStatesRequired(1);
        }
        isInSuperposition = true;
        superpositionStartTime = block.timestamp;
        emit SuperpositionEntered(superpositionStartTime);
    }

    /// @dev Emergency exit from the superposition state.
    ///      Resets the vault to a pre-superposition state. Requires ADMIN_ROLE.
    ///      This will clear all state definitions and user preferences! Use with caution.
    function exitSuperposition()
        external
        hasRole(ADMIN_ROLE)
        whenNotPaused
        whenInSuperposition
        whenNotCollapsed
    {
        isInSuperposition = false;
        superpositionStartTime = 0;

        // Clear all states and preferences (emergency reset)
        for(uint i = 0; i < stateIds.length; i++) {
            delete states[stateIds[i]];
        }
        delete stateIds;
        _stateCounter = 0;

        // Clearing user preferences mapping is not practical iterating,
        // reliance is on `isInSuperposition` check for `registerStatePreference`.
        // Existing preferences are just orphaned data until new superposition.

        emit SuperpositionExitedWithoutCollapse();
    }


    /// @dev Checks if the vault is currently in the superposition phase.
    function isSuperpositionActive() public view returns (bool) {
        return isInSuperposition;
    }

    /// @dev Gets the timestamp when the vault entered the superposition phase. Returns 0 if not active.
    function getSuperpositionStartTime() public view returns (uint256) {
        return superpositionStartTime;
    }

    // --- User Interaction (within Superposition) ---

    /// @dev Allows a user to register their preference/claim for a specific state.
    ///      This makes them eligible for payout IF the vault collapses to this state.
    ///      Only possible when in superposition and not paused.
    /// @param stateId The ID of the state the user is registering for.
    function registerStatePreference(uint256 stateId)
        external
        whenNotPaused
        whenInSuperposition
        stateExists(stateId)
    {
        userStatePreferences[msg.sender][stateId] = true;
        emit StatePreferenceRegistered(msg.sender, stateId);
    }

    /// @dev Checks if a user has registered their preference for a specific state.
    /// @param user The address to check.
    /// @param stateId The state ID to check.
    /// @return True if the user has registered preference, false otherwise.
    function hasRegisteredPreference(address user, uint256 stateId)
        public
        view
        returns (bool)
    {
        return userStatePreferences[user][stateId];
    }

     /// @dev Gets a list of all state IDs that a user has registered preferences for.
     /// Note: This iterates over all *defined* state IDs, which could be inefficient if many states are defined.
     /// @param user The address to query.
     /// @return An array of state IDs the user registered for.
    function getUserPreferences(address user) public view returns (uint256[] memory) {
        uint256[] memory allStateIds = getAllStateIds();
        uint256[] memory registeredIds = new uint256[](allStateIds.length);
        uint256 count = 0;
        for(uint i = 0; i < allStateIds.length; i++) {
            if (userStatePreferences[user][allStateIds[i]]) {
                registeredIds[count] = allStateIds[i];
                count++;
            }
        }
        // Resize array
        uint256[] memory result = new uint256[](count);
         for(uint i = 0; i < count; i++) {
            result[i] = registeredIds[i];
        }
        return result;
    }


    // --- Observation and Collapse (Requires COLLAPSE_MANAGER_ROLE) ---

    // NOTE ON ORACLE/CONDITIONS:
    // The contract cannot natively execute complex off-chain logic or verify complex data like AI outputs.
    // The `conditionsHash` represents a commitment to off-chain logic.
    // The `submitOracleDataHash` and `triggerCollapseEvaluation` functions simulate
    // a process where off-chain systems (oracles, evaluators) determine which state(s)
    // meet their conditions based on real-world data, potentially considering
    // probabilities and user preferences.
    // The `triggerCollapseEvaluation` function then takes the *outcome* of this
    // off-chain process (the chosen state ID and a validation proof) and applies it
    // on-chain. The security relies on the trustworthiness of the
    // COLLAPSE_MANAGER_ROLE and the off-chain validation process.

    /// @dev Simulates submission of data (or its hash) from an oracle or off-chain source.
    ///      This data is used off-chain to evaluate state conditions.
    ///      Requires COLLAPSE_MANAGER_ROLE.
    /// @param dataHash The hash of the external data.
    function submitOracleDataHash(bytes32 dataHash)
        external
        hasRole(COLLAPSE_MANAGER_ROLE)
        whenNotPaused
        whenInSuperposition // Oracle data relevant when in superposition
        whenNotCollapsed
    {
        // In a real scenario, this might store the hash, timestamp, and oracle address
        // for off-chain processes to verify. Here, it's just an event placeholder.
        emit OracleDataHashSubmitted(dataHash, block.timestamp);
    }


    /// @dev Triggers the collapse of the superposition based on a claimed chosen state.
    ///      Requires COLLAPSE_MANAGER_ROLE.
    ///      This function relies on an off-chain process determining `chosenStateId`
    ///      based on oracle data, state conditions, probabilities, and preferences.
    ///      The `validationProof` is a placeholder for verifying this off-chain decision.
    /// @param chosenStateId The ID of the state claimed to be the result of the collapse.
    /// @param validationProof A proof (e.g., signature, ZK-proof fragment, simple data) validating the choice.
    function triggerCollapseEvaluation(uint256 chosenStateId, bytes calldata validationProof)
        external
        hasRole(COLLAPSE_MANAGER_ROLE)
        whenNotPaused
        whenInSuperposition
        whenNotCollapsed
        stateExists(chosenStateId)
    {
        // --- Off-chain Validation Assumption ---
        // In a real system, `validationProof` would be checked here against
        // recent oracle data (if stored), the chosen state's conditionsHash,
        // and potentially the probability weights or user preferences.
        // This on-chain verification is complex and highly dependent on the
        // specific proof mechanism (e.g., checking a signature from a trusted oracle,
        // verifying a ZK-SNARK proving conditions were met, etc.).
        // FOR THIS EXAMPLE CONTRACT, WE ASSUME THE VALIDATION PROOF IS SUFFICIENT
        // FOR THE COLLAPSE_MANAGER_ROLE to proceed.
        // A real implementation needs robust proof verification here.
        // Example basic check (not robust):
        // require(validationProof.length > 0, "Invalid validation proof");

        // Proceed with internal collapse logic
        _performCollapse(chosenStateId);

        emit CollapseEvaluationTriggered(chosenStateId, validationProof);
    }

    /// @dev Internal function to perform the collapse and distribute assets.
    ///      Calculates final balances based on claims in the chosen state *only for users
    ///      who registered preference for that state*.
    /// @param chosenStateId The state ID chosen for the collapse.
    function _performCollapse(uint256 chosenStateId) internal {
        isInSuperposition = false; // End superposition
        isCollapsed = true;      // Mark as collapsed
        collapsedStateId = chosenStateId;

        State storage chosenState = states[chosenStateId];
        uint256 totalVaultBalance = address(this).balance; // Balance at time of collapse

        // Calculate potential payouts for each recipient in the chosen state
        mapping(address => uint256) potentialPayouts;
        for (uint i = 0; i < chosenState.claims.length; i++) {
            address recipient = chosenState.claims[i].recipient;
            uint256 percentage = chosenState.claims[i].percentage;
            potentialPayouts[recipient] = (totalVaultBalance * percentage) / 10000; // Scale percentage
        }

        // Distribute calculated payouts ONLY to users who registered preference for this state
        // Iterate over all users who *potentially* registered preferences (we don't have a list,
        // so we'd typically query externally or iterate over the state's recipients).
        // For simplicity here, we iterate the claims in the chosen state and check if the recipient registered.
        // A more complex model might iterate all users who registered preferences.
        // This simplified model assumes Claims are the *only* way to get value, and registration
        // is just eligibility.

        // We need to know which users registered preference for this state to assign their share.
        // The current `userStatePreferences` mapping is `user => stateId => bool`.
        // We can iterate through the claims and check eligibility for each claim recipient.
        // This is still tricky without a list of all users who registered *for this specific state*.

        // ALTERNATIVE COLLAPSE LOGIC:
        // Calculate total potential distributed amount based on claims.
        // For each claim in the chosen state:
        // - If the recipient is NOT an address that registered preference for this state, send their share to a residual pool or owner? (Let's make it so only registered users get their share).
        // - If the recipient IS an address that registered preference: add their share to their settled balance.

        uint256 totalDistributed = 0;
        for (uint i = 0; i < chosenState.claims.length; i++) {
            address recipient = chosenState.claims[i].recipient;
            uint256 claimAmount = potentialPayouts[recipient];

            // In this model, a user only gets their share if they are listed in a claim
            // AND they registered their preference for this *chosen* state.
            if (userStatePreferences[recipient][chosenStateId]) {
                 // Prevent overflow
                settledBalances[recipient] += claimAmount;
                totalDistributed += claimAmount;
            }
             // Else: this claim amount goes to a residual pool / stays in contract
        }

        // The remaining balance stays in the contract, unless explicitly sent elsewhere.

        emit SuperpositionCollapsed(chosenStateId, block.timestamp);
    }


    /// @dev Gets the ID of the state that was chosen when the vault collapsed.
    /// @return The ID of the collapsed state, or 0 if not yet collapsed.
    function getCollapsedStateId() public view returns (uint256) {
        return collapsedStateId;
    }

    /// @dev Checks if the vault has collapsed.
    function isCollapsed() public view returns (bool) {
        return isCollapsed;
    }

    // --- Role Management ---

    /// @dev Grants a role to an account. Only callable by the admin role for that role.
    /// @param role The role to grant.
    /// @param account The address to grant the role to.
    function grantRole(bytes32 role, address account) public whenNotPaused {
        require(account != address(0), "Account must be non-zero address");
        bytes32 adminRole = _roleAdmin[role];
        if (!_roles[adminRole][msg.sender]) {
             if (adminRole == ADMIN_ROLE) revert NotAdminRole();
             if (adminRole == STATE_MANAGER_ROLE) revert NotStateManagerRole();
             if (adminRole == COLLAPSE_MANAGER_ROLE) revert NotCollapseManagerRole();
             revert NotAdminRole(); // Generic permission error
        }

        _grantRole(role, account);
        emit RoleGranted(role, account, msg.sender);
    }

    /// @dev Revokes a role from an account. Only callable by the admin role for that role.
    /// @param role The role to revoke.
    /// @param account The address to revoke the role from.
    function revokeRole(bytes32 role, address account) public whenNotPaused {
        require(account != address(0), "Account must be non-zero address");
        bytes32 adminRole = _roleAdmin[role];
         if (!_roles[adminRole][msg.sender]) {
             if (adminRole == ADMIN_ROLE) revert NotAdminRole();
             if (adminRole == STATE_MANAGER_ROLE) revert NotStateManagerRole();
             if (adminRole == COLLAPSE_MANAGER_ROLE) revert NotCollapseManagerRole();
             revert NotAdminRole(); // Generic permission error
        }
        _revokeRole(role, account);
        emit RoleRevoked(role, account, msg.sender);
    }

    /// @dev Internal function to grant a role.
    function _grantRole(bytes32 role, address account) internal {
        _roles[role][account] = true;
    }

    /// @dev Internal function to revoke a role.
    function _revokeRole(bytes32 role, address account) internal {
         _roles[role][account] = false;
    }

    /// @dev Sets the admin role for a given role. Only callable by the current admin role of `role`.
    /// @param role The role whose admin role is being set.
    /// @param adminRole The new admin role.
    function setRoleAdmin(bytes32 role, bytes32 adminRole) public whenNotPaused {
        bytes32 currentAdmin = _roleAdmin[role];
        if (!_roles[currentAdmin][msg.sender]) {
             if (currentAdmin == ADMIN_ROLE) revert NotAdminRole();
             if (currentAdmin == STATE_MANAGER_ROLE) revert NotStateManagerRole();
             if (currentAdmin == COLLAPSE_MANAGER_ROLE) revert NotCollapseManagerRole();
             revert NotAdminRole(); // Generic permission error
        }

        bytes32 previousAdminRole = _roleAdmin[role];
        _roleAdmin[role] = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

     /// @dev Gets the admin role for a given role.
     /// @param role The role to query.
     /// @return The admin role bytes32 value.
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roleAdmin[role];
    }

    /// @dev Checks if an account has a specific role.
    /// @param role The role to check.
    /// @param account The account to check.
    /// @return True if the account has the role, false otherwise.
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role][account];
    }


    // --- Pausable ---

    /// @dev Pauses the contract, preventing most state-changing operations. Requires ADMIN_ROLE.
    function pause() external hasRole(ADMIN_ROLE) whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /// @dev Unpauses the contract, allowing operations to resume. Requires ADMIN_ROLE.
    function unpause() external hasRole(ADMIN_ROLE) whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    /// @dev Checks if the contract is currently paused.
    function paused() public view returns (bool) {
        return _paused;
    }

    // --- Ownership Management ---

    /// @dev Returns the address of the current owner.
    function getOwner() public view returns (address) {
        return _owner;
    }

    /// @dev Transfers ownership of the contract to a new account. Requires being the current owner.
    /// @param newOwner The address of the new owner.
    function transferOwnership(address newOwner) public onlyOwner whenNotPaused {
        require(newOwner != address(0), "New owner must be non-zero address");
        address oldOwner = _owner;
        _owner = newOwner;
        // Note: Owner's ADMIN_ROLE is not automatically transferred.
        // The new owner must be granted the ADMIN_ROLE by the current ADMIN_ROLE holder(s).
        // Or, the transfer logic could include granting ADMIN_ROLE to newOwner.
        // Let's keep it separate for clearer role management. The new owner
        // will need the current admin to grant them the ADMIN_ROLE.
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /// @dev Renounces ownership of the contract. Requires being the current owner.
    ///      The contract will not have an owner after this.
    function renounceOwnership() public onlyOwner whenNotPaused {
        address oldOwner = _owner;
        _owner = address(0); // Set owner to zero address
        // Note: The renouncing owner's ADMIN_ROLE is not automatically revoked.
        // The renouncing owner would need to be removed from roles separately.
        emit OwnershipTransferred(oldOwner, address(0));
    }
}
```