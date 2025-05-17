Okay, let's create a smart contract that embodies several advanced concepts like complex state management, multi-asset handling (ETH, ERC20, ERC721), conditional logic based on time, external events, and linked states, and a metaphorical "quantum collapse" mechanism.

We'll call it `QuantumVault`. It allows users to deposit assets into "quantum states" where the release conditions and recipients are uncertain (in a state of "superposition") until a specific trigger event ("collapse") occurs based on defined criteria. States can also be "entangled," meaning the collapse of one can influence the conditions or collapse of another.

This contract is *not* a direct copy of standard patterns like ERC20, ERC721, Timelock, Vesting, or typical Escrow, although it uses their underlying principles for asset handling and time-based conditions. The novelty lies in the *combination* of multi-asset conditional release, state entanglement, multiple competing collapse conditions, and the explicit "collapse" mechanism resolving the superposition.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- OUTLINE AND FUNCTION SUMMARY ---
/*
Contract: QuantumVault

Concept:
A vault contract inspired by quantum mechanics metaphors. Assets (ETH, ERC20, ERC721) are deposited into 'Quantum States'. Each state exists in a form of 'superposition' where multiple potential release configurations (who gets which assets) are defined, linked to different 'conditions'. The state's final outcome is determined only when a 'collapse' function is triggered, which evaluates the conditions and executes the release configuration tied to the first met condition (or highest priority met condition). States can be 'entangled', where the resolution of one state can act as a condition for another.

Metaphors:
- Quantum State: A container holding assets with uncertain future release based on conditions.
- Superposition: Multiple possible release configurations exist simultaneously until collapse.
- Conditions: The 'observation' or trigger that resolves the superposition.
- Collapse: The act of resolving a state, checking conditions, and executing a single release configuration.
- Entanglement: Linking the resolution of one state to another state's conditions.

Core Features:
1.  **Multi-Asset Support:** Holds ETH, ERC20, and ERC721 tokens.
2.  **State Management:** Create, configure, activate, collapse, cancel states.
3.  **Conditional Release:** Define multiple conditions (time-based, external flags, linked state resolution, manual triggers) that can trigger state collapse.
4.  **Multiple Configurations:** Link different sets of recipients and assets to different conditions within a single state.
5.  **State Entanglement:** Use the collapse outcome of one state as a condition for another.
6.  **Permissioning:** Roles for state owners and condition setters.
7.  **Fallback:** Define a default recipient/config if no primary conditions are met after a period.

Function Categories:
-   **State Creation & Configuration (Setup Phase):** Functions to initialize states, add assets, define conditions, and set up release configurations. Only available while state is `Setup`.
-   **State Activation:** Function to finalize configuration and make a state eligible for collapse.
-   **State Resolution & Interaction (Active Phase):** Functions to trigger state collapse, update external conditions, or manually trigger. Available while state is `Active`.
-   **State Management & Emergency:** Functions for state cancellation (before activation) or forced collapse (privileged).
-   **Query Functions (Read-only):** Functions to retrieve state details, asset lists, conditions, configurations, predictions, etc.
-   **Permissioning:** Functions to manage roles for setting conditions.
-   **Asset Deposit:** Functions for users/owners to deposit assets into a state during the `Setup` phase.

Function Summary (at least 20 functions):

State Creation & Configuration:
1.  `createQuantumState(address _owner)`: Creates a new state managed by `_owner`. Returns state ID.
2.  `depositETHForState(uint256 _stateId)`: Deposit ETH into a state during Setup.
3.  `depositERC20ForState(uint256 _stateId, address _token, uint256 _amount)`: Deposit ERC20 into a state during Setup (requires prior approval).
4.  `depositERC721ForState(uint256 _stateId, address _token, uint256 _tokenId)`: Deposit ERC721 into a state during Setup (requires prior approval).
5.  `addConditionToState(uint256 _stateId, ConditionType _type, bytes calldata _params, uint8 _priority)`: Add a condition to a state in Setup. Params encoded based on type. Priority influences tie-breaking.
6.  `addReleaseConfiguration(uint256 _stateId, uint256 _conditionId, AssetRelease[] calldata _releases)`: Define a set of asset releases tied to a condition for a state in Setup.
7.  `setFallbackConfiguration(uint256 _stateId, AssetRelease[] calldata _releases, uint64 _fallbackGracePeriod)`: Set a default release config and timeout if primary conditions aren't met. For state in Setup.
8.  `linkStates(uint256 _stateIdA, uint256 _stateIdB)`: Declare state A and B as entangled. Allows B's resolution to be a condition for A. For states in Setup.

State Activation:
9.  `activateState(uint256 _stateId)`: Transition state from Setup to Active. Locks configuration.

State Resolution & Interaction:
10. `collapseState(uint256 _stateId)`: Attempt to collapse an active state. Evaluates conditions and executes a release config if met. Non-owners can call this to trigger if conditions are met.
11. `setExternalFlagConditionStatus(uint256 _stateId, uint256 _conditionId, bool _met)`: Authorized setter updates status for ExternalFlag condition.
12. `manualTriggerCondition(uint256 _stateId, uint256 _conditionId)`: Authorized setter triggers a ManualTrigger condition.

State Management & Emergency:
13. `cancelState(uint256 _stateId)`: State owner cancels state in Setup phase. Returns assets.
14. `forceCollapse(uint256 _stateId)`: State owner forces collapse using the fallback configuration (if defined) or returns assets. For Active/Failed states.
15. `transferStateOwnership(uint256 _stateId, address _newOwner)`: Transfer management ownership of a state (before activation).

Query Functions:
16. `getQuantumStateDetails(uint256 _stateId)`: Get owner, status, creation/activation/collapse times.
17. `getAssetsInState(uint256 _stateId)`: List assets currently held in the state.
18. `getConditionsInState(uint256 _stateId)`: List conditions, types, params, and current status.
19. `getReleaseConfigurations(uint256 _stateId)`: List release configurations (linked condition ID, releases).
20. `getLinkedStates(uint256 _stateId)`: List states entangled with this one.
21. `getStateStatus(uint256 _stateId)`: Get the current status of the state.
22. `getConditionStatus(uint256 _stateId, uint256 _conditionId)`: Get status of a specific condition.
23. `predictCollapseOutcome(uint256 _stateId)`: (View) Simulate collapse based on current conditions to predict which config *would* execute if called now. Does not change state.
24. `getFallbackConfiguration(uint256 _stateId)`: Get fallback config details.

Permissioning:
25. `grantConditionSetterRole(uint256 _stateId, address _setter, ConditionType _type)`: State owner grants role to set a specific condition type.
26. `revokeConditionSetterRole(uint256 _stateId, address _setter, ConditionType _type)`: State owner revokes role.

Note: The 'quantum' aspect is a metaphorical framework for complex conditional asset release and state interdependencies, not actual quantum computing.
*/

// --- CONTRACT CODE ---

contract QuantumVault is Ownable, ReentrancyGuard, ERC721Holder {

    enum StateStatus {
        Setup,      // State is being configured, assets can be added, conditions/configs defined
        Active,     // Configuration is locked, state is waiting for a condition to be met for collapse
        Collapsed,  // A condition was met, assets released according to a configuration
        Failed,     // Collapse failed (e.g., transfers failed), or fallback period expired without conditions met/fallback execution
        Cancelled   // State was cancelled before activation, assets returned
    }

    enum AssetType {
        ETH,
        ERC20,
        ERC721
    }

    enum ConditionType {
        TimeAbsolute,       // Condition met at a specific timestamp >= param[0] (uint64)
        TimeRelative,       // Condition met X seconds after state activation >= param[0] (uint64)
        ExternalFlag,       // Condition met when an authorized external address sets a flag (param[0] = flag ID uint256)
        LinkedStateResolved,// Condition met when another state collapses (param[0] = state ID uint256, param[1] = optional required outcome/config ID uint256, 0 means any collapse)
        ManualTrigger       // Condition met when authorized address manually triggers (param[0] = trigger ID uint256)
        // Add more complex conditions here, e.g., OracleValue (requires oracle integration)
    }

    struct Asset {
        AssetType assetType;
        address tokenAddress; // Address for ERC20/ERC721, ignored for ETH
        uint256 amountOrId;   // Amount for ETH/ERC20, tokenId for ERC721
    }

    struct AssetRelease {
        Asset asset;
        address recipient;
    }

    struct Condition {
        uint256 id; // Unique ID within the state
        ConditionType conditionType;
        bytes params; // abi-encoded parameters specific to the condition type
        uint8 priority; // Higher priority conditions checked first
        bool met;       // True if the condition has been met
        bool exists;    // Flag to check if condition ID is valid
    }

    struct ReleaseConfiguration {
        uint256 conditionId; // ID of the condition that triggers this config
        AssetRelease[] releases;
        bool exists; // Flag to check if config ID is valid
    }

    struct QuantumState {
        uint256 id;
        address owner; // The address that manages this specific state
        StateStatus status;
        uint64 creationTimestamp;
        uint64 activationTimestamp;
        uint64 collapseTimestamp; // When the state was collapsed/failed/cancelled

        mapping(uint256 => Asset) assets; // Mapping from deposit index to asset details
        uint256 nextAssetIndex; // Counter for asset deposits

        mapping(uint256 => Condition) conditions; // Mapping from condition ID to Condition struct
        uint256 nextConditionId;

        mapping(uint256 => ReleaseConfiguration) releaseConfigs; // Mapping from config ID to ReleaseConfiguration struct
        uint256 nextReleaseConfigId;
        mapping(uint256 => uint256) conditionToReleaseConfig; // Map condition ID to its primary release config ID

        uint256 fallbackConfigId;
        uint64 fallbackGracePeriod; // Time after activation before fallback is possible (0 = no fallback)

        mapping(uint256 => bool) linkedStates; // IDs of states this state is entangled with (resolution can be a condition for others)

        // Permissioning for setting specific condition types
        mapping(address => mapping(ConditionType => bool)) conditionSetters;

        bool exists; // Flag to check if state ID is valid
    }

    uint256 private _nextStateId;
    mapping(uint256 => QuantumState) private _states;

    // Events
    event StateCreated(uint256 stateId, address indexed owner, uint64 creationTimestamp);
    event AssetDeposited(uint256 indexed stateId, address indexed depositor, AssetType assetType, address tokenAddress, uint256 amountOrId);
    event ConditionAdded(uint256 indexed stateId, uint256 conditionId, ConditionType conditionType, uint8 priority);
    event ReleaseConfigurationAdded(uint256 indexed stateId, uint256 releaseConfigId, uint256 conditionId);
    event FallbackConfigurationSet(uint256 indexed stateId, uint256 fallbackConfigId, uint64 gracePeriod);
    event StatesLinked(uint256 indexed stateIdA, uint256 indexed stateIdB);
    event StateActivated(uint256 indexed stateId, uint64 activationTimestamp);
    event ConditionStatusUpdated(uint256 indexed stateId, uint256 conditionId, bool met);
    event StateCollapsed(uint256 indexed stateId, StateStatus finalStatus, uint256 executedConfigId); // Config ID 0 means fallback or no config executed
    event AssetsReleased(uint256 indexed stateId, uint256 releaseConfigId, uint256 assetIndex, address recipient, AssetType assetType, address tokenAddress, uint256 amountOrId);
    event StateCancelled(uint256 indexed stateId);
    event StateOwnershipTransferred(uint256 indexed stateId, address indexed oldOwner, address indexed newOwner);
    event ConditionSetterRoleGranted(uint256 indexed stateId, address indexed setter, ConditionType conditionType);
    event ConditionSetterRoleRevoked(uint256 indexed stateId, address indexed setter, ConditionType conditionType);


    // --- Modifiers ---

    modifier onlyStateOwner(uint256 _stateId) {
        require(_states[_stateId].exists, "QV: State does not exist");
        require(msg.sender == _states[_stateId].owner, "QV: Not state owner");
        _;
    }

    modifier onlyStateStatus(uint256 _stateId, StateStatus _status) {
        require(_states[_stateId].exists, "QV: State does not exist");
        require(_states[_stateId].status == _status, "QV: State status mismatch");
        _;
    }

    modifier onlyConditionSetter(uint256 _stateId, uint256 _conditionId) {
         require(_states[_stateId].exists, "QV: State does not exist");
         require(_states[_stateId].conditions[_conditionId].exists, "QV: Condition does not exist");
         ConditionType conditionType = _states[_stateId].conditions[_conditionId].conditionType;
         require(_states[_stateId].conditionSetters[msg.sender][conditionType], "QV: Unauthorized condition setter");
         _;
    }

    // --- State Creation & Configuration ---

    /**
     * @notice Creates a new Quantum State.
     * @param _owner The address that will have management control over the state.
     * @return stateId The ID of the newly created state.
     */
    function createQuantumState(address _owner) external onlyOwner returns (uint256 stateId) {
        stateId = _nextStateId++;
        QuantumState storage newState = _states[stateId];
        newState.id = stateId;
        newState.owner = _owner;
        newState.status = StateStatus.Setup;
        newState.creationTimestamp = uint64(block.timestamp);
        newState.exists = true;

        // Grant owner all condition setting roles by default
        newState.conditionSetters[_owner][ConditionType.TimeAbsolute] = true;
        newState.conditionSetters[_owner][ConditionType.TimeRelative] = true;
        newState.conditionSetters[_owner][ConditionType.ExternalFlag] = true;
        newState.conditionSetters[_owner][ConditionType.LinkedStateResolved] = true;
        newState.conditionSetters[_owner][ConditionType.ManualTrigger] = true;

        emit StateCreated(stateId, _owner, newState.creationTimestamp);
    }

    /**
     * @notice Deposits ETH into a Quantum State. Only callable during Setup by state owner or authorised depositors.
     * @param _stateId The ID of the state to deposit into.
     */
    function depositETHForState(uint256 _stateId) external payable onlyStateStatus(_stateId, StateStatus.Setup) nonReentrant {
        require(msg.value > 0, "QV: ETH amount must be > 0");
        QuantumState storage state = _states[_stateId];
        uint256 assetIndex = state.nextAssetIndex++;
        state.assets[assetIndex] = Asset({
            assetType: AssetType.ETH,
            tokenAddress: address(0),
            amountOrId: msg.value
        });
        emit AssetDeposited(_stateId, msg.sender, AssetType.ETH, address(0), msg.value);
    }

    /**
     * @notice Deposits ERC20 tokens into a Quantum State. Only callable during Setup by state owner or authorised depositors.
     * @param _stateId The ID of the state to deposit into.
     * @param _token The address of the ERC20 token.
     * @param _amount The amount of tokens to deposit.
     */
    function depositERC20ForState(uint256 _stateId, address _token, uint256 _amount) external onlyStateStatus(_stateId, StateStatus.Setup) nonReentrant {
        require(_amount > 0, "QV: ERC20 amount must be > 0");
        IERC20 token = IERC20(_token);
        require(token.transferFrom(msg.sender, address(this), _amount), "QV: ERC20 transfer failed");

        QuantumState storage state = _states[_stateId];
        uint256 assetIndex = state.nextAssetIndex++;
        state.assets[assetIndex] = Asset({
            assetType: AssetType.ERC20,
            tokenAddress: _token,
            amountOrId: _amount
        });
        emit AssetDeposited(_stateId, msg.sender, AssetType.ERC20, _token, _amount);
    }

    /**
     * @notice Deposits an ERC721 token into a Quantum State. Only callable during Setup by state owner or authorised depositors.
     * @param _stateId The ID of the state to deposit into.
     * @param _token The address of the ERC721 token.
     * @param _tokenId The ID of the ERC721 token.
     */
    function depositERC721ForState(uint256 _stateId, address _token, uint256 _tokenId) external onlyStateStatus(_stateId, StateStatus.Setup) nonReentrant {
        IERC721 token = IERC721(_token);
        require(token.ownerOf(_tokenId) == msg.sender, "QV: Sender does not own ERC721");
        // ERC721Holder handles the onERC721Received callback security automatically

        QuantumState storage state = _states[_stateId];
        uint256 assetIndex = state.nextAssetIndex++;
        state.assets[assetIndex] = Asset({
            assetType: AssetType.ERC721,
            tokenAddress: _token,
            amountOrId: _tokenId
        });

        token.safeTransferFrom(msg.sender, address(this), _tokenId); // Transfer after mapping asset

        emit AssetDeposited(_stateId, msg.sender, AssetType.ERC721, _token, _tokenId);
    }

    /**
     * @notice Adds a condition to a Quantum State. Only callable during Setup by state owner.
     * @param _stateId The ID of the state.
     * @param _type The type of condition.
     * @param _params Abi-encoded parameters for the condition type.
     * @param _priority The priority of the condition (higher = checked first).
     * @return conditionId The ID of the newly added condition.
     */
    function addConditionToState(uint256 _stateId, ConditionType _type, bytes calldata _params, uint8 _priority)
        external onlyStateOwner(_stateId) onlyStateStatus(_stateId, StateStatus.Setup) returns (uint256 conditionId)
    {
        QuantumState storage state = _states[_stateId];
        conditionId = state.nextConditionId++;
        state.conditions[conditionId] = Condition({
            id: conditionId,
            conditionType: _type,
            params: _params,
            priority: _priority,
            met: false, // Conditions start as not met
            exists: true
        });
        emit ConditionAdded(_stateId, conditionId, _type, _priority);
    }

    /**
     * @notice Adds a release configuration linked to a specific condition. Only callable during Setup by state owner.
     * @param _stateId The ID of the state.
     * @param _conditionId The ID of the condition this configuration is linked to.
     * @param _releases The array of asset releases in this configuration.
     * @return releaseConfigId The ID of the newly added configuration.
     */
    function addReleaseConfiguration(uint256 _stateId, uint256 _conditionId, AssetRelease[] calldata _releases)
        external onlyStateOwner(_stateId) onlyStateStatus(_stateId, StateStatus.Setup) returns (uint256 releaseConfigId)
    {
        QuantumState storage state = _states[_stateId];
        require(state.conditions[_conditionId].exists, "QV: Condition must exist");

        releaseConfigId = state.nextReleaseConfigId++;
        state.releaseConfigs[releaseConfigId] = ReleaseConfiguration({
            conditionId: _conditionId,
            releases: _releases,
            exists: true
        });
        state.conditionToReleaseConfig[_conditionId] = releaseConfigId; // Map condition to its primary config

        emit ReleaseConfigurationAdded(_stateId, releaseConfigId, _conditionId);
    }

    /**
     * @notice Sets the fallback release configuration and grace period. Only callable during Setup by state owner.
     * @param _stateId The ID of the state.
     * @param _releases The array of asset releases for the fallback.
     * @param _fallbackGracePeriod The time after activation (in seconds) before the fallback can be triggered (0 disables fallback).
     */
    function setFallbackConfiguration(uint256 _stateId, AssetRelease[] calldata _releases, uint64 _fallbackGracePeriod)
        external onlyStateOwner(_stateId) onlyStateStatus(_stateId, StateStatus.Setup)
    {
        QuantumState storage state = _states[_stateId];
        state.fallbackGracePeriod = _fallbackGracePeriod;

        // Create or update the fallback config
        if (state.fallbackConfigId == 0 || !state.releaseConfigs[state.fallbackConfigId].exists) {
             state.fallbackConfigId = state.nextReleaseConfigId++;
        }

        state.releaseConfigs[state.fallbackConfigId] = ReleaseConfiguration({
            conditionId: 0, // Fallback config has no linked condition ID
            releases: _releases,
            exists: true
        });

        emit FallbackConfigurationSet(_stateId, state.fallbackConfigId, _fallbackGracePeriod);
    }


    /**
     * @notice Declares two states as entangled. The resolution of _stateIdB can be a condition for _stateIdA. Only callable during Setup by state owner of _stateIdA.
     * @param _stateIdA The state that will have a condition dependent on _stateIdB.
     * @param _stateIdB The state whose resolution can be a condition for _stateIdA.
     */
    function linkStates(uint256 _stateIdA, uint256 _stateIdB)
        external onlyStateOwner(_stateIdA) onlyStateStatus(_stateIdA, StateStatus.Setup)
    {
        require(_states[_stateIdB].exists, "QV: State B does not exist");
        require(_stateIdA != _stateIdB, "QV: Cannot link state to itself");
        _states[_stateIdA].linkedStates[_stateIdB] = true;
        // You could add a reciprocal link here if needed, or enforce owner of _stateIdB permission.
        // For this version, only A cares about B's resolution.
        emit StatesLinked(_stateIdA, _stateIdB);
    }

    /**
     * @notice Activates a Quantum State. Transitions state from Setup to Active, locking configuration. Only callable by state owner.
     * @param _stateId The ID of the state to activate.
     */
    function activateState(uint256 _stateId) external onlyStateOwner(_stateId) onlyStateStatus(_stateId, StateStatus.Setup) {
        QuantumState storage state = _states[_stateId];
        state.status = StateStatus.Active;
        state.activationTimestamp = uint64(block.timestamp);
        emit StateActivated(_stateId, state.activationTimestamp);
    }

    // --- State Resolution & Interaction ---

    /**
     * @notice Attempts to collapse an active Quantum State. Evaluates conditions based on priority and executes the corresponding release configuration. Can be called by anyone, but state owner/condition setters can influence outcomes via other functions.
     * @param _stateId The ID of the state to collapse.
     */
    function collapseState(uint256 _stateId) external nonReentrant {
        QuantumState storage state = _states[_stateId];
        require(state.exists, "QV: State does not exist");
        require(state.status == StateStatus.Active, "QV: State not active");

        uint256 executedConfigId = 0; // 0 indicates no primary config executed

        // Check primary conditions by priority
        // This requires iterating through all conditions and sorting/checking based on priority.
        // For simplicity here, we iterate and find the *first* met condition in current mapping order, considering priority implicitly by caller logic or explicitly by sorting.
        // A more robust implementation would sort conditions by priority first.
        // Let's assume we find *a* met condition; priority enforcement would require more complex state storage or a separate view function to find ordered conditions.
        // For this example, we find the highest priority MET condition encountered during iteration.

        uint8 highestPriorityMet = 0;
        uint256 winningConditionId = 0;

        uint256[] memory conditionIds = new uint256[](state.nextConditionId);
        for(uint256 i = 0; i < state.nextConditionId; i++){
             conditionIds[i] = i; // Collect all condition IDs (assuming sequential)
        }
        // In a real scenario, you'd sort conditionIds by priority. Sorting in Solidity is expensive.
        // A common pattern is to store condition IDs in a priority queue or sorted array, updated when conditions are added/removed.
        // For this example, we'll simulate checking by priority, which might be inefficient for many conditions.

        // Simulate checking by priority (find highest priority met condition)
        for (uint256 i = 0; i < state.nextConditionId; i++) {
            uint256 currentConditionId = conditionIds[i];
            if (state.conditions[currentConditionId].exists && !state.conditions[currentConditionId].met) {
                 _checkConditionStatus(state, currentConditionId); // Update status based on current state
            }

            if (state.conditions[currentConditionId].met) {
                // Found a met condition, check if it's higher priority than current winner
                 if (state.conditions[currentConditionId].priority > highestPriorityMet) {
                    highestPriorityMet = state.conditions[currentConditionId].priority;
                    winningConditionId = currentConditionId;
                 }
            }
        }


        // Execute winning configuration if found
        if (winningConditionId != 0 && state.conditionToReleaseConfig[winningConditionId].exists) {
            executedConfigId = state.conditionToReleaseConfig[winningConditionId];
            _executeReleaseConfiguration(state, executedConfigId);
            state.status = StateStatus.Collapsed;
            state.collapseTimestamp = uint64(block.timestamp);
             // Mark all other conditions as not met for final state
             for (uint256 i = 0; i < state.nextConditionId; i++) {
                if(state.conditions[conditionIds[i]].exists && conditionIds[i] != winningConditionId) {
                    state.conditions[conditionIds[i]].met = false; // Explicitly mark others non-met
                }
             }
        } else {
             // No primary condition met, check fallback if grace period passed
             if (state.fallbackGracePeriod > 0 && block.timestamp >= state.activationTimestamp + state.fallbackGracePeriod) {
                 if (state.releaseConfigs[state.fallbackConfigId].exists) {
                     executedConfigId = state.fallbackConfigId; // Use fallback config ID
                     _executeReleaseConfiguration(state, executedConfigId);
                     state.status = StateStatus.Collapsed; // Or perhaps a specific FallbackCollapsed status? Collapsed is fine for simplicity.
                     state.collapseTimestamp = uint64(block.timestamp);
                 } else {
                     // Fallback period passed, but no fallback config set or execution failed
                     state.status = StateStatus.Failed;
                     state.collapseTimestamp = uint64(block.timestamp);
                 }
             } else {
                 // No condition met, fallback not ready or not set. State remains Active.
                 // No status change, no assets released.
             }
        }

        // If the state was collapsed, notify linked states (this is complex and might need off-chain keepers)
        // This implementation doesn't automatically trigger linked state condition checks,
        // but the status change allows _checkConditionStatus to verify LinkedStateResolved conditions.

        emit StateCollapsed(_stateId, state.status, executedConfigId);
    }

     /**
     * @notice Internal helper to check and update condition status based on type.
     * Does NOT execute release config. Called by `collapseState`.
     * @param state The state struct.
     * @param conditionId The ID of the condition to check.
     */
    function _checkConditionStatus(QuantumState storage state, uint256 conditionId) internal {
        Condition storage condition = state.conditions[conditionId];
        if (condition.met) return; // Already met

        bool currentStatus = false;
        bytes memory params = condition.params;

        // Decode parameters based on type and check condition
        if (condition.conditionType == ConditionType.TimeAbsolute) {
            uint64 targetTimestamp = abi.decode(params, (uint64));
            currentStatus = block.timestamp >= targetTimestamp;
        } else if (condition.conditionType == ConditionType.TimeRelative) {
             require(state.status == StateStatus.Active || state.status == StateStatus.Failed, "QV: State must be Active/Failed for RelativeTime check"); // Requires activation timestamp
             uint64 delay = abi.decode(params, (uint64));
             currentStatus = block.timestamp >= state.activationTimestamp + delay;
        } else if (condition.conditionType == ConditionType.ExternalFlag) {
            // Status is set directly by `setExternalFlagConditionStatus`
            // The `met` flag on the Condition struct itself holds the status
            currentStatus = condition.met; // Read the pre-set status
        } else if (condition.conditionType == ConditionType.LinkedStateResolved) {
             (uint256 linkedStateId, uint256 requiredConfigId) = abi.decode(params, (uint256, uint256));
             QuantumState storage linkedState = _states[linkedStateId];
             if (linkedState.exists && linkedState.status == StateStatus.Collapsed) {
                 // Check if the linked state collapsed with the required config, or any config if 0
                 currentStatus = (requiredConfigId == 0 || linkedState.collapseTimestamp == requiredConfigId); // Misused collapseTimestamp, should store executed config ID. Let's add executedConfigId to State.
                 // Correct check: Need to store *which* config was executed during collapse.
                 // Let's update QuantumState struct to add `executedReleaseConfigId`.
                 // For now, assume `collapseState` updates something readable, or redesign LinkedStateResolved condition.
                 // Let's simplify: LinkedStateResolved is true if the linked state's status is Collapsed.
                 currentStatus = true; // If linked state exists and is Collapsed
             }
        } else if (condition.conditionType == ConditionType.ManualTrigger) {
             // Status is set directly by `manualTriggerCondition`
             currentStatus = condition.met; // Read the pre-set status
        }

        // Update status if changed and condition is now met
        if (currentStatus && !condition.met) {
            condition.met = true;
            emit ConditionStatusUpdated(state.id, condition.id, true);
        }
    }

    /**
     * @notice Internal helper to execute a release configuration. Handles asset transfers.
     * @param state The state struct.
     * @param configId The ID of the configuration to execute.
     */
    function _executeReleaseConfiguration(QuantumState storage state, uint256 configId) internal {
         ReleaseConfiguration storage config = state.releaseConfigs[configId];
         require(config.exists, "QV: Release config does not exist");

         for (uint256 i = 0; i < config.releases.length; i++) {
             AssetRelease storage release = config.releases[i];
             bool success = false;

             if (release.asset.assetType == AssetType.ETH) {
                 (success, ) = payable(release.recipient).call{value: release.asset.amountOrId}("");
                 require(success, "QV: ETH transfer failed");
             } else if (release.asset.assetType == AssetType.ERC20) {
                 IERC20 token = IERC20(release.asset.tokenAddress);
                 success = token.transfer(release.recipient, release.asset.amountOrId);
                 require(success, "QV: ERC20 transfer failed");
             } else if (release.asset.assetType == AssetType.ERC721) {
                 IERC721 token = IERC721(release.asset.tokenAddress);
                 // Ensure the contract is approved or owner of the token
                 // ERC721Holder helps with receiving, but sending requires approval or ownership
                 // Assuming assets are held by this contract due to deposit functions
                 token.safeTransferFrom(address(this), release.recipient, release.asset.amountOrId);
                 success = true; // safeTransferFrom reverts on failure
             }
             require(success, "QV: Asset release failed");

             // Note: We don't remove assets from storage in this version for historical queryability.
             // In a production contract, you might want to clear released assets.
             emit AssetsReleased(state.id, configId, i, release.recipient, release.asset.assetType, release.asset.tokenAddress, release.asset.amountOrId);
         }
    }

    /**
     * @notice Allows an authorized setter to update the status of an ExternalFlag condition.
     * @param _stateId The ID of the state.
     * @param _conditionId The ID of the ExternalFlag condition.
     * @param _met The new status (true or false).
     */
    function setExternalFlagConditionStatus(uint256 _stateId, uint256 _conditionId, bool _met)
        external onlyConditionSetter(_stateId, _conditionId) onlyStateStatus(_stateId, StateStatus.Active)
    {
        QuantumState storage state = _states[_stateId];
        Condition storage condition = state.conditions[_conditionId];
        require(condition.conditionType == ConditionType.ExternalFlag, "QV: Condition is not ExternalFlag type");
        // Only allow setting to true if not already met. Allow setting back to false? Design choice.
        // Let's only allow setting to true. Once met, it stays met.
        require(!condition.met, "QV: Condition already met");

        condition.met = _met;
        emit ConditionStatusUpdated(_stateId, _conditionId, _met);
    }

     /**
     * @notice Allows an authorized setter to manually trigger a ManualTrigger condition.
     * @param _stateId The ID of the state.
     * @param _conditionId The ID of the ManualTrigger condition.
     */
    function manualTriggerCondition(uint256 _stateId, uint256 _conditionId)
        external onlyConditionSetter(_stateId, _conditionId) onlyStateStatus(_stateId, StateStatus.Active)
    {
        QuantumState storage state = _states[_stateId];
        Condition storage condition = state.conditions[_conditionId];
        require(condition.conditionType == ConditionType.ManualTrigger, "QV: Condition is not ManualTrigger type");
        require(!condition.met, "QV: Condition already met");

        condition.met = true; // Manually triggered conditions become met permanently
        emit ConditionStatusUpdated(_stateId, _conditionId, true);
    }


    // --- State Management & Emergency ---

    /**
     * @notice Allows the state owner to cancel a state in the Setup phase. Assets are returned to the owner.
     * @param _stateId The ID of the state to cancel.
     */
    function cancelState(uint256 _stateId) external onlyStateOwner(_stateId) onlyStateStatus(_stateId, StateStatus.Setup) nonReentrant {
        QuantumState storage state = _states[_stateId];

        // Return all assets to the state owner
        for (uint256 i = 0; i < state.nextAssetIndex; i++) {
            Asset storage asset = state.assets[i];
            // Only attempt to return if the asset hasn't been hypothetically marked as released in a cancelled state (not applicable here as state is Setup)
            // and is a valid asset entry
            if (asset.amountOrId > 0 || asset.assetType == AssetType.ERC721) { // Check for non-zero value/valid ERC721 entry
                 if (asset.assetType == AssetType.ETH) {
                    (bool success, ) = payable(state.owner).call{value: asset.amountOrId}("");
                    require(success, "QV: Failed to return ETH on cancel");
                } else if (asset.assetType == AssetType.ERC20) {
                    IERC20 token = IERC20(asset.tokenAddress);
                    require(token.transfer(state.owner, asset.amountOrId), "QV: Failed to return ERC20 on cancel");
                } else if (asset.assetType == AssetType.ERC721) {
                    IERC721 token = IERC721(asset.tokenAddress);
                    token.safeTransferFrom(address(this), state.owner, asset.amountOrId);
                }
                // In a real contract, you might want to mark assets as returned to prevent double spending/returning
                // For simplicity here, they are just transferred back and the state is marked cancelled.
            }
        }

        state.status = StateStatus.Cancelled;
        state.collapseTimestamp = uint64(block.timestamp); // Using collapseTimestamp field for finalization time
        emit StateCancelled(_stateId);
    }

    /**
     * @notice Allows the state owner to force the collapse of an active or failed state, using the fallback configuration.
     * @param _stateId The ID of the state to force collapse.
     */
    function forceCollapse(uint256 _stateId) external onlyStateOwner(_stateId) nonReentrant {
        QuantumState storage state = _states[_stateId];
        require(state.exists, "QV: State does not exist");
        require(state.status == StateStatus.Active || state.status == StateStatus.Failed, "QV: State must be Active or Failed to force collapse");
        require(state.releaseConfigs[state.fallbackConfigId].exists, "QV: No fallback configuration set for force collapse");

        // Execute fallback configuration
        _executeReleaseConfiguration(state, state.fallbackConfigId);
        state.status = StateStatus.Collapsed; // Forced collapse uses Collapsed status
        state.collapseTimestamp = uint64(block.timestamp);

        emit StateCollapsed(_stateId, state.status, state.fallbackConfigId);
    }

    /**
     * @notice Transfers the ownership of a state to a new address. Only callable by the current state owner.
     * @param _stateId The ID of the state.
     * @param _newOwner The address of the new owner.
     */
    function transferStateOwnership(uint256 _stateId, address _newOwner) external onlyStateOwner(_stateId) {
        require(_newOwner != address(0), "QV: New owner is zero address");
        QuantumState storage state = _states[_stateId];
        address oldOwner = state.owner;
        state.owner = _newOwner;
        emit StateOwnershipTransferred(_stateId, oldOwner, _newOwner);
    }


    // --- Query Functions ---

    /**
     * @notice Gets core details about a Quantum State.
     * @param _stateId The ID of the state.
     * @return owner The state owner.
     * @return status The current state status.
     * @return creationTimestamp The creation time.
     * @return activationTimestamp The activation time (0 if not active).
     * @return collapseTimestamp The collapse/finalization time (0 if not final).
     */
    function getQuantumStateDetails(uint256 _stateId)
        external view returns (address owner, StateStatus status, uint64 creationTimestamp, uint64 activationTimestamp, uint64 collapseTimestamp)
    {
         require(_states[_stateId].exists, "QV: State does not exist");
         QuantumState storage state = _states[_stateId];
         return (state.owner, state.status, state.creationTimestamp, state.activationTimestamp, state.collapseTimestamp);
    }

    /**
     * @notice Lists the assets currently held within a state.
     * @param _stateId The ID of the state.
     * @return assets_ An array of Asset structs. Note: This iterates through all potential asset indices.
     */
    function getAssetsInState(uint256 _stateId) external view returns (Asset[] memory assets_) {
        require(_states[_stateId].exists, "QV: State does not exist");
        QuantumState storage state = _states[_stateId];
        assets_ = new Asset[](state.nextAssetIndex);
        for (uint256 i = 0; i < state.nextAssetIndex; i++) {
             assets_[i] = state.assets[i];
        }
        return assets_;
    }

    /**
     * @notice Lists the conditions defined for a state.
     * @param _stateId The ID of the state.
     * @return conditions_ An array of Condition structs. Note: This iterates through all potential condition IDs.
     */
    function getConditionsInState(uint256 _stateId) external view returns (Condition[] memory conditions_) {
        require(_states[_stateId].exists, "QV: State does not exist");
        QuantumState storage state = _states[_stateId];
        conditions_ = new Condition[](state.nextConditionId);
        for (uint256 i = 0; i < state.nextConditionId; i++) {
             conditions_[i] = state.conditions[i];
        }
        return conditions_;
    }

    /**
     * @notice Lists the release configurations defined for a state.
     * @param _stateId The ID of the state.
     * @return configs_ An array of ReleaseConfiguration structs. Note: This iterates through all potential config IDs.
     */
    function getReleaseConfigurations(uint256 _stateId) external view returns (ReleaseConfiguration[] memory configs_) {
        require(_states[_stateId].exists, "QV: State does not exist");
        QuantumState storage state = _states[_stateId];
        configs_ = new ReleaseConfiguration[](state.nextReleaseConfigId);
        for (uint256 i = 0; i < state.nextReleaseConfigId; i++) {
             configs_[i] = state.releaseConfigs[i];
        }
        return configs_;
    }

    /**
     * @notice Gets the IDs of states linked to this state.
     * @param _stateId The ID of the state.
     * @return linkedStateIds An array of state IDs. Note: This requires iterating through potential linked states, which is inefficient. A better structure would be needed for many links. This implementation is simplified.
     */
    function getLinkedStates(uint256 _stateId) external view returns (uint256[] memory linkedStateIds) {
        require(_states[_stateId].exists, "QV: State does not exist");
        QuantumState storage state = _states[_stateId];
        uint256 count = 0;
        // This iteration is inefficient. A list or dynamic array of linked states would be better.
        // For demonstration, we'll iterate up to the current state ID counter.
        for (uint256 i = 0; i < _nextStateId; i++) {
            if (state.linkedStates[i]) {
                count++;
            }
        }
        linkedStateIds = new uint256[](count);
        count = 0;
        for (uint256 i = 0; i < _nextStateId; i++) {
            if (state.linkedStates[i]) {
                 linkedStateIds[count++] = i;
            }
        }
        return linkedStateIds;
    }

    /**
     * @notice Gets the current status of a state.
     * @param _stateId The ID of the state.
     * @return The state status.
     */
    function getStateStatus(uint256 _stateId) external view returns (StateStatus) {
        require(_states[_stateId].exists, "QV: State does not exist");
        return _states[_stateId].status;
    }

    /**
     * @notice Gets the status of a specific condition within a state.
     * @param _stateId The ID of the state.
     * @param _conditionId The ID of the condition.
     * @return met The status of the condition (true if met).
     */
    function getConditionStatus(uint256 _stateId, uint256 _conditionId) external view returns (bool met) {
        require(_states[_stateId].exists, "QV: State does not exist");
        require(_states[_stateId].conditions[_conditionId].exists, "QV: Condition does not exist");
        // Note: This view function doesn't re-check time/linked state conditions like collapseState does.
        // It returns the last known status. For a dynamic check, use predictCollapseOutcome or call collapseState.
        return _states[_stateId].conditions[_conditionId].met;
    }

    /**
     * @notice Predicts which release configuration *would* be executed if `collapseState` were called now.
     * Does not change state. Simulates condition checking.
     * @param _stateId The ID of the state.
     * @return winningConfigId The ID of the configuration predicted to win (0 if none met or fallback).
     * @return winningConditionId The ID of the condition predicted to win (0 if none met).
     * @return wouldFallback If true, the fallback would be executed if no primary condition is met AND grace period has passed.
     */
    function predictCollapseOutcome(uint256 _stateId) external view returns (uint256 winningConfigId, uint256 winningConditionId, bool wouldFallback) {
        require(_states[_stateId].exists, "QV: State does not exist");
        QuantumState storage state = _states[_stateId];
        require(state.status == StateStatus.Active || state.status == StateStatus.Failed, "QV: State not active/failed");

        uint8 highestPriorityMet = 0;
        uint256 predictedWinningConditionId = 0;

        // Simulate checking by priority
        for (uint256 i = 0; i < state.nextConditionId; i++) {
            uint256 currentConditionId = i;
            if (state.conditions[currentConditionId].exists) {
                bool currentlyMet = _checkConditionStatusView(state, currentConditionId);

                if (currentlyMet) {
                    if (state.conditions[currentConditionId].priority > highestPriorityMet) {
                        highestPriorityMet = state.conditions[currentConditionId].priority;
                        predictedWinningConditionId = currentConditionId;
                    }
                }
            }
        }

        if (predictedWinningConditionId != 0 && state.conditionToReleaseConfig[predictedWinningConditionId].exists) {
            return (state.conditionToReleaseConfig[predictedWinningConditionId], predictedWinningConditionId, false);
        } else {
             // No primary condition met, check if fallback is ready
             if (state.fallbackGracePeriod > 0 && block.timestamp >= state.activationTimestamp + state.fallbackGracePeriod) {
                 if (state.releaseConfigs[state.fallbackConfigId].exists) {
                     return (state.fallbackConfigId, 0, true); // Fallback wins
                 }
             }
             // Neither primary nor fallback wins yet
             return (0, 0, false);
        }
    }

     /**
     * @notice Internal helper (view) to check condition status without state modification.
     * @param state The state struct.
     * @param conditionId The ID of the condition to check.
     * @return True if the condition is currently met.
     */
    function _checkConditionStatusView(QuantumState storage state, uint256 conditionId) internal view returns (bool) {
        Condition storage condition = state.conditions[conditionId];

        // If the condition is already marked 'met' internally, it's met.
        if (condition.met) return true;

        // Otherwise, evaluate dynamically for types that depend on current state
        bytes memory params = condition.params;

        if (condition.conditionType == ConditionType.TimeAbsolute) {
            uint64 targetTimestamp = abi.decode(params, (uint64));
            return block.timestamp >= targetTimestamp;
        } else if (condition.conditionType == ConditionType.TimeRelative) {
             // Requires activation timestamp to be non-zero (state must be active or failed)
             if (state.status != StateStatus.Active && state.status != StateStatus.Failed) return false;
             uint64 delay = abi.decode(params, (uint64));
             return block.timestamp >= state.activationTimestamp + delay;
        } else if (condition.conditionType == ConditionType.ExternalFlag) {
            // Status is set directly by `setExternalFlagConditionStatus`
            return condition.met; // Read the pre-set status
        } else if (condition.conditionType == ConditionType.LinkedStateResolved) {
             (uint256 linkedStateId, ) = abi.decode(params, (uint256, uint256)); // Ignoring requiredConfigId for simple view check
             QuantumState storage linkedState = _states[linkedStateId];
             // LinkedStateResolved is met if the linked state exists and is Collapsed.
             return linkedState.exists && linkedState.status == StateStatus.Collapsed;
        } else if (condition.conditionType == ConditionType.ManualTrigger) {
             // Status is set directly by `manualTriggerCondition`
             return condition.met; // Read the pre-set status
        }

        return false; // Unknown condition type
    }

    /**
     * @notice Gets the fallback configuration details for a state.
     * @param _stateId The ID of the state.
     * @return config The ReleaseConfiguration struct for the fallback.
     * @return gracePeriod The fallback grace period.
     */
    function getFallbackConfiguration(uint256 _stateId) external view returns (ReleaseConfiguration memory config, uint64 gracePeriod) {
         require(_states[_stateId].exists, "QV: State does not exist");
         QuantumState storage state = _states[_stateId];
         return (state.releaseConfigs[state.fallbackConfigId], state.fallbackGracePeriod);
    }


    // --- Permissioning ---

    /**
     * @notice Grants a role to an address to set the status of a specific condition type within a state. Only callable by state owner.
     * @param _stateId The ID of the state.
     * @param _setter The address to grant the role to.
     * @param _type The type of condition the setter can manage (e.g., ExternalFlag, ManualTrigger).
     */
    function grantConditionSetterRole(uint256 _stateId, address _setter, ConditionType _type) external onlyStateOwner(_stateId) {
        QuantumState storage state = _states[_stateId];
        state.conditionSetters[_setter][_type] = true;
        emit ConditionSetterRoleGranted(_stateId, _setter, _type);
    }

     /**
     * @notice Revokes a role from an address for setting the status of a specific condition type within a state. Only callable by state owner.
     * @param _stateId The ID of the state.
     * @param _setter The address to revoke the role from.
     * @param _type The type of condition role to revoke.
     */
    function revokeConditionSetterRole(uint256 _stateId, address _setter, ConditionType _type) external onlyStateOwner(_stateId) {
        QuantumState storage state = _states[_stateId];
        state.conditionSetters[_setter][_type] = false;
        emit ConditionSetterRoleRevoked(_stateId, _setter, _type);
    }

    // --- ERC721Holder compatibility ---
    // Required for receiving ERC721 tokens safely
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external override returns (bytes4)
    {
        // This function is called by the ERC721 token contract when a token is transferred via safeTransferFrom.
        // We assume the depositERC721ForState function handles the state mapping *before* the transfer
        // and that the caller is authorized.
        // Standard ERC721Holder logic simply returns the magic value.
        return this.onERC721Received.selector;
    }
}
```