This smart contract, named `AxiomEngine`, is a dynamic, on-chain policy engine designed for decentralized autonomous organizations (DAOs) and other DApps. It enables the creation, management, and execution of complex rules (policies) based on a variety of on-chain conditions, external data (via oracle), and user reputation. The architecture emphasizes modularity, allowing policies to be composed from reusable condition and action sets, making the system highly adaptable and extensible.

It goes beyond basic access control or simple voting mechanisms by allowing for:
*   **Event-Driven Policies:** Policies can be triggered by specific on-chain events.
*   **Composability:** Conditions and actions are defined separately and combined into policies.
*   **Reputation System Integration:** Policies can require minimum reputation scores and can modify reputation or award badges.
*   **Oracle Integration (Conceptual):** Policies can incorporate external data for their conditions.
*   **Generic Execution:** A flexible system for defining and executing arbitrary on-chain calls as actions.
*   **Self-Amending/Dynamic Rules:** Policies themselves can be updated or deactivated by authorized roles.

---

### **AxiomEngine: Dynamic On-Chain Policy Engine**

**Outline & Function Summary:**

**I. Core Management (Policy Lifecycle)**
*   **1. `createPolicy(...)`**: Defines and registers a new policy. Requires `POLICY_MANAGER_ROLE`.
*   **2. `updatePolicy(...)`**: Modifies an existing policy's details, conditions, actions, or triggers. Requires `POLICY_MANAGER_ROLE`.
*   **3. `deactivatePolicy(bytes32 policyId)`**: Disables a policy, preventing its execution. Requires `POLICY_MANAGER_ROLE`.
*   **4. `activatePolicy(bytes32 policyId)`**: Re-enables a deactivated policy. Requires `POLICY_MANAGER_ROLE`.
*   **5. `deletePolicy(bytes32 policyId)`**: Permanently removes a policy from the system. Requires `ADMIN_ROLE`.
*   **6. `getPolicyDetails(bytes32 policyId)`**: Retrieves all parameters and configuration of a specific policy.
*   **7. `getPoliciesByTrigger(bytes32 triggerEventHash)`**: Lists all policy IDs configured to be activated by a particular event hash.

**II. Policy Evaluation & Execution**
*   **8. `triggerPolicyEvaluation(bytes32 policyId, address targetActor, bytes memory eventData)`**: Manually or programmatically initiates the evaluation and execution of a specific policy for a given `targetActor`. May require a specific `requiredRoleToExecute` defined by the policy.
*   **9. `processEventTrigger(bytes32 triggerEventHash, address targetActor, bytes memory eventData)`**: An external entry point for trusted callers (e.g., event relayer, oracle) to signal an event. It automatically identifies and attempts to execute all policies linked to the `triggerEventHash`.
*   **10. `_evaluateConditionSet(bytes32 conditionSetId, address targetActor, bytes memory eventData)`**: *Internal*. Evaluates a collection of conditions. Returns `true` if conditions are met according to the logic operator (AND/OR) and the net reputation change.
*   **11. `_executeActionSet(bytes32 actionSetId, address targetActor, bytes memory eventData)`**: *Internal*. Executes a collection of actions. Returns `true` if all actions succeed and the net reputation change.
*   **12. `_triggerPolicyEvaluationInternal(...)`**: *Internal*. Centralized logic for evaluating and executing a policy, used by both public trigger functions.

**III. Reputation & Identity Integration**
*   **13. `updateReputationScore(address user, int256 scoreChange)`**: Directly adjusts a user's reputation score. Requires `REPUTATION_MANAGER_ROLE`.
*   **14. `awardBadge(address user, bytes32 badgeId)`**: Grants a specific badge to a user. Requires `REPUTATION_MANAGER_ROLE`.
*   **15. `revokeBadge(address user, bytes32 badgeId)`**: Removes a specific badge from a user. Requires `REPUTATION_MANAGER_ROLE`.
*   **16. `getReputationProfile(address user)`**: Retrieves a user's current reputation score, a list of their held badges, and the last update timestamp.

**IV. Condition & Action Definitions (Configurable Policy Primitives)**
*   **17. `defineConditionSet(bytes32 conditionSetId, string memory name, Condition[] memory conditions, bytes32 logicOperator)`**: Creates a reusable collection of conditions. Requires `CONDITION_ACTION_MANAGER_ROLE`.
*   **18. `updateConditionSet(bytes32 conditionSetId, string memory name, Condition[] memory conditions, bytes32 logicOperator)`**: Modifies an existing condition set. Requires `CONDITION_ACTION_MANAGER_ROLE`.
*   **19. `defineActionSet(bytes32 actionSetId, string memory name, Action[] memory actions)`**: Creates a reusable collection of actions. Requires `CONDITION_ACTION_MANAGER_ROLE`.
*   **20. `updateActionSet(bytes32 actionSetId, string memory name, Action[] memory actions)`**: Modifies an existing action set. Requires `CONDITION_ACTION_MANAGER_ROLE`.

**V. Access Control & System Configuration**
*   **21. `grantRole(bytes32 role, address account)`**: Grants a specified role to an address (inherited from OpenZeppelin AccessControl). Requires `DEFAULT_ADMIN_ROLE` (which is `ADMIN_ROLE` in this contract).
*   **22. `revokeRole(bytes32 role, address account)`**: Revokes a specified role from an address (inherited from OpenZeppelin AccessControl). Requires `DEFAULT_ADMIN_ROLE`.
*   **23. `setOracleAddress(address _oracleAddress)`**: Configures the address of the trusted oracle contract for external data queries. Requires `ADMIN_ROLE`.
*   **24. `setMinReputationForPolicyCreation(uint256 _minReputation)`**: Sets a minimum reputation threshold required for any address to create new policies. Requires `ADMIN_ROLE`.
*   **25. `pause()`**: Enters a paused state, preventing all policy evaluations/executions. Requires `ADMIN_ROLE`.
*   **26. `unpause()`**: Exits the paused state, re-enabling policy executions. Requires `ADMIN_ROLE`.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// Note: For a real-world scenario, oracle interaction would be more robust, e.g., using Chainlink.
// For this example, we'll simulate a simple external data fetch with a conceptual interface.
interface IOracle {
    function getUint256(bytes32 key) external view returns (uint256);
    function getAddress(bytes32 key) external view returns (address);
    // Add more types as needed for oracle data
}

/**
 * @title AxiomEngine
 * @dev An advanced, dynamic on-chain policy engine for DAOs and DApps.
 *      It allows defining, managing, and executing complex policies based on
 *      on-chain conditions, external data (via oracle), user reputation,
 *      and event triggers. Policies can be composed of reusable condition
 *      and action sets, offering a highly modular and adaptable system.
 *
 * @notice This contract is designed for illustrative purposes of advanced concepts.
 *         Production usage would require extensive security audits, gas optimizations,
 *         and potentially more robust error handling and external contract integrations.
 *         The generic `bytes` payload for conditions and actions offers flexibility
 *         but requires careful off-chain encoding and on-chain decoding/dispatching logic.
 *
 * Outline & Function Summary:
 *
 * I. Core Management (Policy Lifecycle)
 *    1.  `createPolicy(bytes32 policyId, string memory name, string memory description, bytes32 policyType, bytes32 conditionSetId, bytes32 actionSetId, bytes32 triggerEventHash, bytes32 requiredRoleToExecute, uint256 minReputationToTrigger)`: Creates a new policy. Requires `POLICY_MANAGER_ROLE`.
 *    2.  `updatePolicy(bytes32 policyId, string memory name, string memory description, bytes32 policyType, bytes32 conditionSetId, bytes32 actionSetId, bytes32 triggerEventHash, bytes32 requiredRoleToExecute, uint256 minReputationToTrigger)`: Updates an existing policy's parameters. Requires `POLICY_MANAGER_ROLE`.
 *    3.  `deactivatePolicy(bytes32 policyId)`: Deactivates a policy, preventing its execution. Requires `POLICY_MANAGER_ROLE`.
 *    4.  `activatePolicy(bytes32 policyId)`: Re-activates a previously deactivated policy. Requires `POLICY_MANAGER_ROLE`.
 *    5.  `deletePolicy(bytes32 policyId)`: Permanently deletes a policy. Requires `ADMIN_ROLE`.
 *    6.  `getPolicyDetails(bytes32 policyId)`: Retrieves all details of a specific policy.
 *    7.  `getPoliciesByTrigger(bytes32 triggerEventHash)`: Returns a list of policy IDs associated with a given trigger event hash.
 *
 * II. Policy Evaluation & Execution
 *    8.  `triggerPolicyEvaluation(bytes32 policyId, address targetActor, bytes memory eventData)`: Public entry point to manually or programmatically trigger a policy's evaluation. Requires specific `requiredRoleToExecute` if set on policy.
 *    9.  `processEventTrigger(bytes32 triggerEventHash, address targetActor, bytes memory eventData)`: Entry point for external contracts or oracles to signal an event, which in turn triggers all associated policies. Can be restricted to specific callers.
 *    10. `_evaluateConditionSet(bytes32 conditionSetId, address targetActor, bytes memory eventData)`: Internal function to evaluate a given condition set for a `targetActor` with `eventData`. Returns `bool` for success and `int256` for net reputation change.
 *    11. `_executeActionSet(bytes32 actionSetId, address targetActor, bytes memory eventData)`: Internal function to execute a given action set for a `targetActor` with `eventData`. Returns `bool` for success and `int256` for net reputation change.
 *    12. `_triggerPolicyEvaluationInternal(bytes32 policyId, address targetActor, bytes memory eventData, address triggerer)`: Internal function encapsulating the core policy evaluation and execution logic.
 *
 * III. Reputation & Identity Integration
 *    13. `updateReputationScore(address user, int256 scoreChange)`: Directly updates a user's reputation score. Requires `REPUTATION_MANAGER_ROLE` (or can be triggered by policy execution).
 *    14. `awardBadge(address user, bytes32 badgeId)`: Awards a specific badge to a user. Requires `REPUTATION_MANAGER_ROLE` (or can be triggered by policy execution).
 *    15. `revokeBadge(address user, bytes32 badgeId)`: Revokes a specific badge from a user. Requires `REPUTATION_MANAGER_ROLE`.
 *    16. `getReputationProfile(address user)`: Retrieves a user's current reputation score, a list of their badges, and last update time.
 *
 * IV. Condition & Action Definitions (Configurable Policy Primitives)
 *    17. `defineConditionSet(bytes32 conditionSetId, string memory name, Condition[] memory conditions, bytes32 logicOperator)`: Defines a reusable set of conditions. Requires `CONDITION_ACTION_MANAGER_ROLE`.
 *    18. `updateConditionSet(bytes32 conditionSetId, string memory name, Condition[] memory conditions, bytes32 logicOperator)`: Updates an existing condition set. Requires `CONDITION_ACTION_MANAGER_ROLE`.
 *    19. `defineActionSet(bytes32 actionSetId, string memory name, Action[] memory actions)`: Defines a reusable set of actions. Requires `CONDITION_ACTION_MANAGER_ROLE`.
 *    20. `updateActionSet(bytes32 actionSetId, string memory name, Action[] memory actions)`: Updates an existing action set. Requires `CONDITION_ACTION_MANAGER_ROLE`.
 *
 * V. Access Control & System Configuration
 *    21. `grantRole(bytes32 role, address account)`: Grants a role to an account (inherited from AccessControl).
 *    22. `revokeRole(bytes32 role, address account)`: Revokes a role from an account (inherited from AccessControl).
 *    23. `setOracleAddress(address _oracleAddress)`: Sets the address of a trusted oracle contract. Requires `ADMIN_ROLE`.
 *    24. `setMinReputationForPolicyCreation(uint256 _minReputation)`: Sets the minimum reputation required to create policies. Requires `ADMIN_ROLE`.
 *    25. `pause()`: Pauses the system, preventing policy executions. Requires `ADMIN_ROLE`.
 *    26. `unpause()`: Unpauses the system. Requires `ADMIN_ROLE`.
 */
contract AxiomEngine is AccessControl, Pausable {

    // --- Roles ---
    // DEFAULT_ADMIN_ROLE (from OpenZeppelin AccessControl) will be aliased to ADMIN_ROLE in constructor.
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant POLICY_MANAGER_ROLE = keccak256("POLICY_MANAGER_ROLE");
    bytes32 public constant CONDITION_ACTION_MANAGER_ROLE = keccak256("CONDITION_ACTION_MANAGER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    bytes32 public constant REPUTATION_MANAGER_ROLE = keccak256("REPUTATION_MANAGER_ROLE"); // For direct reputation manipulation

    // --- Struct Definitions ---

    struct Condition {
        bytes32 conditionType; // e.g., "BALANCE_GT", "HAS_BADGE", "ORACLE_VALUE_GT", "MIN_REPUTATION", "CALL_EXTERNAL_VIEW"
        address targetAddress; // Optional: relevant for balance checks (token address) or specific contract checks
        uint256 comparisonValue; // For numeric comparisons (e.g., balance amount, min score)
        bytes32 badgeId; // For "HAS_BADGE"
        bytes dataPayload; // For complex conditions or oracle queries (e.g., encoded function call data, oracle key)
        int256 reputationChangeIfMet; // Reputation adjustment if this specific condition is met
    }

    struct ConditionSet {
        bytes32 conditionSetId;
        string name;
        Condition[] conditions;
        bytes32 logicOperator; // "AND", "OR"
        address creator;
    }

    struct Action {
        bytes32 actionType; // e.g., "TRANSFER_ERC20", "MINT_ERC721", "CALL_EXTERNAL", "UPDATE_REPUTATION", "AWARD_BADGE", "REVOKE_BADGE"
        address targetAddress; // Recipient, or contract to call
        uint256 value; // Amount for transfers, or token ID for ERC721 mint
        bytes dataPayload; // ABI-encoded call data for CALL_EXTERNAL, or specific parameters for other actions
        bytes32 badgeId; // For badge actions
        int256 reputationChangeOnSuccess; // Reputation adjustment if this specific action succeeds
    }

    struct ActionSet {
        bytes32 actionSetId;
        string name;
        Action[] actions;
        address creator;
    }

    struct Policy {
        bytes32 policyId;
        string name;
        string description;
        bool isActive;
        bytes32 policyType; // e.g., "ACCESS", "GOVERNANCE", "REPUTATION_ADJUSTMENT"
        bytes32 conditionSetId; // Reference to a defined ConditionSet
        bytes32 actionSetId;    // Reference to a defined ActionSet
        bytes32 triggerEventHash; // Hash of the event signature that triggers it, or a custom string identifier
        bytes32 requiredRoleToExecute; // Role required for an external caller to trigger this policy's execution
        uint256 minReputationToTrigger; // Minimum reputation for the `targetActor` to be eligible for this policy
        address creator;
        uint256 createdAt;
        uint256 lastUpdated;
    }

    // ReputationProfile structure to allow iterable badges.
    struct ReputationProfile {
        int256 score;
        bytes32[] ownedBadgeIds; // List of badges currently held by the user
        mapping(bytes32 => uint256) badgeIdToIndex; // badgeId => index in ownedBadgeIds + 1 (0 means not found)
        uint256 lastUpdated;
    }

    // --- State Variables ---

    mapping(bytes32 => Policy) public policies;
    mapping(bytes32 => ConditionSet) public conditionSets;
    mapping(bytes32 => ActionSet) public actionSets;
    mapping(address => ReputationProfile) private _userReputationProfiles; // Private to control access via getter

    // Stores policy IDs for each trigger hash, allowing efficient lookup of policies by event.
    // NOTE: Removing policies from this array requires shifting elements, which is O(N).
    // For very high frequency updates/deletes of policies, a more optimized data structure might be needed.
    mapping(bytes32 => bytes32[]) public policyTriggers; // triggerEventHash => policyIds[]

    address public oracleAddress;
    uint256 public minReputationForPolicyCreation;

    // --- Events ---
    event PolicyCreated(bytes32 indexed policyId, address indexed creator, bytes32 policyType, bytes32 triggerEventHash);
    event PolicyUpdated(bytes32 indexed policyId, address indexed updater);
    event PolicyDeactivated(bytes32 indexed policyId, address indexed admin);
    event PolicyActivated(bytes32 indexed policyId, address indexed admin);
    event PolicyDeleted(bytes32 indexed policyId, address indexed admin);

    event ConditionSetDefined(bytes32 indexed conditionSetId, address indexed creator);
    event ConditionSetUpdated(bytes33 indexed conditionSetId, address indexed updater);
    event ActionSetDefined(bytes32 indexed actionSetId, address indexed creator);
    event ActionSetUpdated(bytes32 indexed actionSetId, address indexed updater);

    event PolicyTriggered(bytes32 indexed policyId, address indexed triggerer, address indexed targetActor, bool conditionsMet, bool actionsExecuted);
    event PolicyEvaluationResult(bytes32 indexed policyId, address indexed targetActor, bool conditionsMet, bool actionsExecuted, int256 netReputationChange);

    event ReputationUpdated(address indexed user, int256 newScore, int256 scoreChange);
    event BadgeAwarded(address indexed user, bytes32 indexed badgeId);
    event BadgeRevoked(address indexed user, bytes32 indexed badgeId);

    event OracleAddressSet(address indexed oldAddress, address indexed newAddress);
    event MinReputationForPolicyCreationSet(uint256 oldThreshold, uint256 newThreshold);
    event SystemPaused(uint256 timestamp);
    event SystemUnpaused(uint256 timestamp);

    // --- Constructor ---
    constructor(address initialAdmin) {
        // Grant OpenZeppelin's DEFAULT_ADMIN_ROLE to initialAdmin. This role is then used by the custom ADMIN_ROLE below.
        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        // Grant custom ADMIN_ROLE, which will be the primary admin role for this contract.
        _grantRole(ADMIN_ROLE, initialAdmin);
        // Grant other initial roles to the admin for setup. In a real system, these would likely be separate addresses.
        _grantRole(POLICY_MANAGER_ROLE, initialAdmin);
        _grantRole(CONDITION_ACTION_MANAGER_ROLE, initialAdmin);
        _grantRole(REPUTATION_MANAGER_ROLE, initialAdmin);
        // EXECUTOR_ROLE is typically for external callers or specific privileged contracts that trigger policies.
    }

    // --- Internal Helpers ---

    /**
     * @dev Checks if the policy creator has the minimum required reputation.
     */
    modifier _onlyIfSufficientReputationForCreation() {
        if (minReputationForPolicyCreation > 0) {
            require(_userReputationProfiles[msg.sender].score >= int256(minReputationForPolicyCreation), "AxiomEngine: Caller has insufficient reputation for creation");
        }
        _;
    }

    /**
     * @dev Throws if `_role` is required and `msg.sender` doesn't have it.
     */
    modifier _checkRoleIfRequired(bytes32 _role) {
        if (_role != bytes32(0)) { // bytes32(0) means no specific role is required
            require(hasRole(_role, _msgSender()), "AxiomEngine: Caller does not have the required role");
        }
        _;
    }

    // --- I. Core Management (Policy Lifecycle) ---

    /**
     * @dev Creates a new policy with specified conditions, actions, and trigger.
     * @param policyId Unique identifier for the policy.
     * @param name Name of the policy.
     * @param description Description of the policy.
     * @param policyType Type of the policy (e.g., "ACCESS", "GOVERNANCE").
     * @param conditionSetId ID of the ConditionSet to use.
     * @param actionSetId ID of the ActionSet to use.
     * @param triggerEventHash Hash of the event signature or custom ID that triggers this policy. bytes32(0) for no direct trigger.
     * @param requiredRoleToExecute Role required to call `triggerPolicyEvaluation` for this policy. bytes32(0) for no specific role.
     * @param minReputationToTrigger Minimum reputation for `targetActor` to be eligible.
     */
    function createPolicy(
        bytes32 policyId,
        string memory name,
        string memory description,
        bytes32 policyType,
        bytes32 conditionSetId,
        bytes32 actionSetId,
        bytes32 triggerEventHash,
        bytes32 requiredRoleToExecute,
        uint256 minReputationToTrigger
    ) external onlyRole(POLICY_MANAGER_ROLE) _onlyIfSufficientReputationForCreation {
        require(policyId != bytes32(0), "AxiomEngine: Invalid policy ID");
        require(policies[policyId].policyId == bytes32(0), "AxiomEngine: Policy ID already exists");
        require(conditionSets[conditionSetId].conditionSetId != bytes32(0), "AxiomEngine: ConditionSet not found");
        require(actionSets[actionSetId].actionSetId != bytes32(0), "AxiomEngine: ActionSet not found");

        policies[policyId] = Policy({
            policyId: policyId,
            name: name,
            description: description,
            isActive: true,
            policyType: policyType,
            conditionSetId: conditionSetId,
            actionSetId: actionSetId,
            triggerEventHash: triggerEventHash,
            requiredRoleToExecute: requiredRoleToExecute,
            minReputationToTrigger: minReputationToTrigger,
            creator: _msgSender(),
            createdAt: block.timestamp,
            lastUpdated: block.timestamp
        });

        if (triggerEventHash != bytes32(0)) {
            policyTriggers[triggerEventHash].push(policyId);
        }

        emit PolicyCreated(policyId, _msgSender(), policyType, triggerEventHash);
    }

    /**
     * @dev Updates an existing policy's parameters.
     * @param policyId Unique identifier for the policy.
     * @param name Name of the policy.
     * @param description Description of the policy.
     * @param policyType Type of the policy (e.g., "ACCESS", "GOVERNANCE").
     * @param conditionSetId ID of the ConditionSet to use.
     * @param actionSetId ID of the ActionSet to use.
     * @param triggerEventHash Hash of the event signature or custom ID that triggers this policy. bytes32(0) for no direct trigger.
     * @param requiredRoleToExecute Role required to call `triggerPolicyEvaluation` for this policy. bytes32(0) for no specific role.
     * @param minReputationToTrigger Minimum reputation for `targetActor` to be eligible.
     */
    function updatePolicy(
        bytes32 policyId,
        string memory name,
        string memory description,
        bytes32 policyType,
        bytes32 conditionSetId,
        bytes32 actionSetId,
        bytes32 triggerEventHash,
        bytes32 requiredRoleToExecute,
        uint256 minReputationToTrigger
    ) external onlyRole(POLICY_MANAGER_ROLE) {
        Policy storage policy = policies[policyId];
        require(policy.policyId != bytes32(0), "AxiomEngine: Policy not found");
        require(conditionSets[conditionSetId].conditionSetId != bytes32(0), "AxiomEngine: ConditionSet not found");
        require(actionSets[actionSetId].actionSetId != bytes32(0), "AxiomEngine: ActionSet not found");

        // Remove from old trigger if changed
        if (policy.triggerEventHash != triggerEventHash) {
            bytes32[] storage oldTriggerPolicies = policyTriggers[policy.triggerEventHash];
            for (uint i = 0; i < oldTriggerPolicies.length; i++) {
                if (oldTriggerPolicies[i] == policyId) {
                    oldTriggerPolicies[i] = oldTriggerPolicies[oldTriggerPolicies.length - 1]; // Move last element to current position
                    oldTriggerPolicies.pop(); // Remove last element
                    break;
                }
            }
            if (triggerEventHash != bytes32(0)) {
                policyTriggers[triggerEventHash].push(policyId);
            }
        }

        policy.name = name;
        policy.description = description;
        policy.policyType = policyType;
        policy.conditionSetId = conditionSetId;
        policy.actionSetId = actionSetId;
        policy.triggerEventHash = triggerEventHash;
        policy.requiredRoleToExecute = requiredRoleToExecute;
        policy.minReputationToTrigger = minReputationToTrigger;
        policy.lastUpdated = block.timestamp;

        emit PolicyUpdated(policyId, _msgSender());
    }

    /**
     * @dev Deactivates a policy, preventing its execution.
     * @param policyId The ID of the policy to deactivate.
     */
    function deactivatePolicy(bytes32 policyId) external onlyRole(POLICY_MANAGER_ROLE) {
        Policy storage policy = policies[policyId];
        require(policy.policyId != bytes32(0), "AxiomEngine: Policy not found");
        require(policy.isActive, "AxiomEngine: Policy is already inactive");

        policy.isActive = false;
        policy.lastUpdated = block.timestamp;
        emit PolicyDeactivated(policyId, _msgSender());
    }

    /**
     * @dev Re-activates a previously deactivated policy.
     * @param policyId The ID of the policy to activate.
     */
    function activatePolicy(bytes32 policyId) external onlyRole(POLICY_MANAGER_ROLE) {
        Policy storage policy = policies[policyId];
        require(policy.policyId != bytes32(0), "AxiomEngine: Policy not found");
        require(!policy.isActive, "AxiomEngine: Policy is already active");

        policy.isActive = true;
        policy.lastUpdated = block.timestamp;
        emit PolicyActivated(policyId, _msgSender());
    }

    /**
     * @dev Permanently deletes a policy. Only callable by ADMIN_ROLE.
     * @param policyId The ID of the policy to delete.
     */
    function deletePolicy(bytes32 policyId) external onlyRole(ADMIN_ROLE) {
        Policy storage policy = policies[policyId];
        require(policy.policyId != bytes32(0), "AxiomEngine: Policy not found");

        // Remove from trigger mapping
        if (policy.triggerEventHash != bytes32(0)) {
            bytes32[] storage triggerPolicies = policyTriggers[policy.triggerEventHash];
            for (uint i = 0; i < triggerPolicies.length; i++) {
                if (triggerPolicies[i] == policyId) {
                    triggerPolicies[i] = triggerPolicies[triggerPolicies.length - 1];
                    triggerPolicies.pop();
                    break;
                }
            }
        }

        delete policies[policyId];
        emit PolicyDeleted(policyId, _msgSender());
    }

    /**
     * @dev Retrieves all details of a specific policy.
     * @param policyId The ID of the policy.
     * @return Policy struct containing all details.
     */
    function getPolicyDetails(bytes32 policyId) external view returns (Policy memory) {
        require(policies[policyId].policyId != bytes32(0), "AxiomEngine: Policy not found");
        return policies[policyId];
    }

    /**
     * @dev Returns a list of policy IDs associated with a given trigger event hash.
     * @param triggerEventHash The hash of the event signature or custom ID.
     * @return An array of policy IDs.
     */
    function getPoliciesByTrigger(bytes32 triggerEventHash) external view returns (bytes32[] memory) {
        return policyTriggers[triggerEventHash];
    }

    // --- II. Policy Evaluation & Execution ---

    /**
     * @dev Public entry point to manually or programmatically trigger a policy's evaluation.
     *      Can be restricted by the policy's `requiredRoleToExecute`.
     * @param policyId The ID of the policy to trigger.
     * @param targetActor The address whose context the policy conditions/actions apply to.
     * @param eventData Any additional data relevant to the trigger (e.g., calldata from an external event).
     * @return success True if conditions met and actions executed successfully.
     */
    function triggerPolicyEvaluation(
        bytes32 policyId,
        address targetActor,
        bytes memory eventData
    ) external payable pausable _checkRoleIfRequired(policies[policyId].requiredRoleToExecute) returns (bool success) {
        Policy storage policy = policies[policyId];
        require(policy.policyId != bytes32(0), "AxiomEngine: Policy not found");
        require(policy.isActive, "AxiomEngine: Policy is inactive");
        require(_userReputationProfiles[targetActor].score >= int256(policy.minReputationToTrigger), "AxiomEngine: Target actor reputation too low");

        return _triggerPolicyEvaluationInternal(policyId, targetActor, eventData, _msgSender());
    }

    /**
     * @dev Entry point for external contracts or oracles to signal an event,
     *      which in turn triggers all associated policies.
     *      This function can be further restricted (e.g., only specific contracts can call it).
     * @param triggerEventHash The specific event hash that occurred.
     * @param targetActor The address whose context the policy conditions/actions apply to.
     * @param eventData Any additional data relevant to the event (e.g., calldata from an external event).
     */
    function processEventTrigger(
        bytes32 triggerEventHash,
        address targetActor,
        bytes memory eventData
    ) external pausable {
        // This function can be restricted by `onlyRole(EVENT_RELAYER_ROLE)` for trusted event sources.
        // For this example, it's generally accessible but policies themselves might have role checks.
        
        bytes32[] memory policyIdsToTrigger = policyTriggers[triggerEventHash];
        require(policyIdsToTrigger.length > 0, "AxiomEngine: No policies registered for this trigger");

        for (uint i = 0; i < policyIdsToTrigger.length; i++) {
            bytes32 policyId = policyIdsToTrigger[i];
            Policy storage policy = policies[policyId];

            // Only attempt to process active policies
            if (policy.policyId != bytes32(0) && policy.isActive) {
                // If a policy requires a specific role to execute, and this call came from an external trusted source
                // (e.g., an oracle or event relayer), this check would need to be `hasRole(policy.requiredRoleToExecute, msg.sender)`
                // or `policy.requiredRoleToExecute == bytes32(0)`.
                // For simplicity, `processEventTrigger` assumes the policy's `requiredRoleToExecute` might be bypassed
                // if the `processEventTrigger` caller itself is trusted (e.g., has a `EVENT_RELAYER_ROLE`).
                // Or, more strictly:
                if (policy.requiredRoleToExecute != bytes32(0) && !hasRole(policy.requiredRoleToExecute, _msgSender())) {
                    continue; // Skip if caller doesn't have the role for this specific policy
                }
                
                // Also check min reputation for the targetActor for *each* policy.
                if (_userReputationProfiles[targetActor].score >= int256(policy.minReputationToTrigger)) {
                    _triggerPolicyEvaluationInternal(policyId, targetActor, eventData, _msgSender());
                }
            }
        }
    }

    /**
     * @dev Internal function to trigger and evaluate a policy. Used by both `triggerPolicyEvaluation` and `processEventTrigger`.
     * @param policyId The ID of the policy to trigger.
     * @param targetActor The address whose context the policy conditions/actions apply to.
     * @param eventData Any additional data relevant to the trigger.
     * @param triggerer The address that initiated the trigger (could be msg.sender for direct, or another contract for `processEventTrigger`).
     * @return success True if conditions met and actions executed.
     */
    function _triggerPolicyEvaluationInternal(
        bytes32 policyId,
        address targetActor,
        bytes memory eventData,
        address triggerer
    ) internal returns (bool success) {
        Policy storage policy = policies[policyId];
        emit PolicyTriggered(policyId, triggerer, targetActor, false, false); // Initial event

        int256 totalReputationChange = 0;
        (bool conditionsMet, int256 conditionRepChange) = _evaluateConditionSet(policy.conditionSetId, targetActor, eventData);
        totalReputationChange += conditionRepChange;

        bool actionsExecuted = false;
        if (conditionsMet) {
            (actionsExecuted, int256 actionRepChange) = _executeActionSet(policy.actionSetId, targetActor, eventData);
            totalReputationChange += actionRepChange;
        }

        if (totalReputationChange != 0) {
            _updateReputationScore(targetActor, totalReputationChange);
        }

        emit PolicyEvaluationResult(policyId, targetActor, conditionsMet, actionsExecuted, totalReputationChange);
        return conditionsMet && actionsExecuted;
    }

    /**
     * @dev Internal function to evaluate a given condition set for a `targetActor`.
     * @param conditionSetId The ID of the ConditionSet to evaluate.
     * @param targetActor The address whose context the conditions apply to.
     * @param eventData Additional data from the triggering event.
     * @return bool True if all conditions (according to logicOperator) are met.
     * @return int256 The net reputation change from condition evaluations.
     */
    function _evaluateConditionSet(
        bytes32 conditionSetId,
        address targetActor,
        bytes memory eventData
    ) internal view returns (bool, int256) {
        ConditionSet storage cSet = conditionSets[conditionSetId];
        require(cSet.conditionSetId != bytes32(0), "AxiomEngine: ConditionSet not found for evaluation");

        bool overallResult = (cSet.logicOperator == keccak256("AND")); // Start with true for AND, false for OR
        int256 netReputationChange = 0;

        for (uint i = 0; i < cSet.conditions.length; i++) {
            Condition storage cond = cSet.conditions[i];
            bool conditionMet = false;

            if (cond.conditionType == keccak256("BALANCE_GT")) {
                require(cond.targetAddress != address(0), "AxiomEngine: BALANCE_GT requires targetAddress (token)");
                conditionMet = IERC20(cond.targetAddress).balanceOf(targetActor) > cond.comparisonValue;
            } else if (cond.conditionType == keccak256("HAS_BADGE")) {
                require(cond.badgeId != bytes32(0), "AxiomEngine: HAS_BADGE requires badgeId");
                conditionMet = _userReputationProfiles[targetActor].badgeIdToIndex[cond.badgeId] != 0; // Check if badge index is not 0 (meaning it exists)
            } else if (cond.conditionType == keccak256("ORACLE_VALUE_GT")) {
                require(oracleAddress != address(0), "AxiomEngine: Oracle address not set");
                // dataPayload expected to be the bytes32 key for the oracle query.
                require(cond.dataPayload.length == 32, "AxiomEngine: ORACLE_VALUE_GT dataPayload must be bytes32 key");
                bytes32 oracleKey;
                assembly { oracleKey := mload(add(cond.dataPayload, 32)) } // Extract bytes32 from bytes
                conditionMet = IOracle(oracleAddress).getUint256(oracleKey) > cond.comparisonValue;
            } else if (cond.conditionType == keccak256("MIN_REPUTATION")) {
                conditionMet = _userReputationProfiles[targetActor].score >= int256(cond.comparisonValue);
            } else if (cond.conditionType == keccak256("CALL_EXTERNAL_VIEW")) {
                // This condition type allows calling an external contract's view function.
                // dataPayload should be ABI-encoded function call, targetAddress is the contract address.
                // For simplicity, we assume the external call returns a boolean directly (as a uint256 0 or 1).
                (bool success, bytes memory result) = cond.targetAddress.staticcall(cond.dataPayload);
                require(success, "AxiomEngine: External view call failed");
                require(result.length == 32, "AxiomEngine: Expected bytes32 result from external view call"); // e.g., a boolean true/false as uint256
                uint256 val;
                assembly { val := mload(add(result, 32)) }
                conditionMet = (val == 1); // Interpret non-zero as true, 0 as false
            }
            // Add more condition types as needed (e.g., ERC721_OWNED, VOTE_COUNT_EXCEEDS, CUSTOM_EVENT_DATA_MATCH)

            if (conditionMet) {
                netReputationChange += cond.reputationChangeIfMet;
            }

            if (cSet.logicOperator == keccak256("AND")) {
                overallResult = overallResult && conditionMet;
            } else if (cSet.logicOperator == keccak256("OR")) {
                overallResult = overallResult || conditionMet;
            } else {
                revert("AxiomEngine: Invalid logic operator");
            }
        }
        return (overallResult, netReputationChange);
    }

    /**
     * @dev Internal function to execute a given action set for a `targetActor`.
     * @param actionSetId The ID of the ActionSet to execute.
     * @param targetActor The address whose context the actions apply to.
     * @param eventData Additional data from the triggering event.
     * @return bool True if all actions succeed.
     * @return int256 The net reputation change from action executions.
     */
    function _executeActionSet(
        bytes32 actionSetId,
        address targetActor,
        bytes memory eventData
    ) internal returns (bool, int256) {
        ActionSet storage aSet = actionSets[actionSetId];
        require(aSet.actionSetId != bytes32(0), "AxiomEngine: ActionSet not found for execution");

        int256 netReputationChange = 0;
        bool allActionsSuccessful = true;

        for (uint i = 0; i < aSet.actions.length; i++) {
            Action storage act = aSet.actions[i];
            bool actionSuccessful = false;

            if (act.actionType == keccak256("TRANSFER_ERC20")) {
                require(act.targetAddress != address(0), "AxiomEngine: TRANSFER_ERC20 requires targetAddress (token)");
                // dataPayload for TRANSFER_ERC20 would be ABI-encoded recipient address
                (address recipient, uint256 amount) = abi.decode(act.dataPayload, (address, uint256));
                require(amount == act.value, "AxiomEngine: TRANSFER_ERC20 value mismatch with dataPayload amount");
                actionSuccessful = IERC20(act.targetAddress).transfer(recipient, amount);
            } else if (act.actionType == keccak256("MINT_ERC721")) {
                require(act.targetAddress != address(0), "AxiomEngine: MINT_ERC721 requires targetAddress (NFT contract)");
                // dataPayload for MINT_ERC721 would be ABI-encoded recipient address and token ID
                (address recipient, uint256 tokenId) = abi.decode(act.dataPayload, (address, uint256));
                require(tokenId == act.value, "AxiomEngine: MINT_ERC721 token ID mismatch with dataPayload tokenID");
                try IERC721(act.targetAddress).safeMint(recipient, tokenId) returns (bytes memory) {
                    actionSuccessful = true;
                } catch {
                    actionSuccessful = false; // SafeMint can revert if recipient is a contract without ERC721Receiver
                }
            } else if (act.actionType == keccak256("CALL_EXTERNAL")) {
                // targetAddress is the contract to call, dataPayload is the ABI-encoded call data.
                (bool success, ) = act.targetAddress.call{value: act.value}(act.dataPayload);
                actionSuccessful = success;
            } else if (act.actionType == keccak256("UPDATE_REPUTATION")) {
                // targetAddress is the user whose reputation is updated. `value` is the change amount.
                // Assuming `act.value` could represent a positive or negative change.
                _updateReputationScore(act.targetAddress, int256(act.value));
                actionSuccessful = true;
            } else if (act.actionType == keccak256("AWARD_BADGE")) {
                require(act.badgeId != bytes32(0), "AxiomEngine: AWARD_BADGE requires badgeId");
                _awardBadge(act.targetAddress, act.badgeId);
                actionSuccessful = true;
            } else if (act.actionType == keccak256("REVOKE_BADGE")) {
                require(act.badgeId != bytes32(0), "AxiomEngine: REVOKE_BADGE requires badgeId");
                _revokeBadge(act.targetAddress, act.badgeId);
                actionSuccessful = true;
            }
            // Add more action types as needed (e.g., TRANSFER_ERC721, UPGRADE_CONTRACT_PROXY, PROPOSE_GOVERNANCE_ACTION)

            if (!actionSuccessful) {
                allActionsSuccessful = false;
                // In a production system, one might choose to revert the entire transaction on first failure,
                // or log and continue. Here, we log failure and continue.
            } else {
                netReputationChange += act.reputationChangeOnSuccess;
            }
        }
        return (allActionsSuccessful, netReputationChange);
    }

    // --- III. Reputation & Identity Integration ---

    /**
     * @dev Internal function to update a user's reputation score.
     *      Can be called by policies or direct managers.
     * @param user The address of the user.
     * @param scoreChange The amount to change the score by (can be positive or negative).
     */
    function _updateReputationScore(address user, int256 scoreChange) internal {
        ReputationProfile storage profile = _userReputationProfiles[user];
        profile.score += scoreChange;
        profile.lastUpdated = block.timestamp;
        emit ReputationUpdated(user, profile.score, scoreChange);
    }

    /**
     * @dev Updates a user's reputation score. Callable by `REPUTATION_MANAGER_ROLE`.
     * @param user The address of the user.
     * @param scoreChange The amount to change the score by (can be positive or negative).
     */
    function updateReputationScore(address user, int256 scoreChange) external onlyRole(REPUTATION_MANAGER_ROLE) {
        _updateReputationScore(user, scoreChange);
    }

    /**
     * @dev Internal function to award a specific badge to a user. Manages `ownedBadgeIds` and `badgeIdToIndex`.
     * @param user The address of the user.
     * @param badgeId The ID of the badge to award.
     */
    function _awardBadge(address user, bytes32 badgeId) internal {
        ReputationProfile storage profile = _userReputationProfiles[user];
        if (profile.badgeIdToIndex[badgeId] == 0) { // If badge not found (index is 0)
            profile.ownedBadgeIds.push(badgeId);
            // Store 1-based index to differentiate from 0 (not found)
            profile.badgeIdToIndex[badgeId] = profile.ownedBadgeIds.length;
            profile.lastUpdated = block.timestamp;
            emit BadgeAwarded(user, badgeId);
        }
    }

    /**
     * @dev Awards a specific badge to a user. Callable by `REPUTATION_MANAGER_ROLE`.
     * @param user The address of the user.
     * @param badgeId The ID of the badge to award.
     */
    function awardBadge(address user, bytes32 badgeId) external onlyRole(REPUTATION_MANAGER_ROLE) {
        _awardBadge(user, badgeId);
    }

    /**
     * @dev Internal function to revoke a specific badge from a user. Manages `ownedBadgeIds` and `badgeIdToIndex`.
     * @param user The address of the user.
     * @param badgeId The ID of the badge to revoke.
     */
    function _revokeBadge(address user, bytes32 badgeId) internal {
        ReputationProfile storage profile = _userReputationProfiles[user];
        uint256 index = profile.badgeIdToIndex[badgeId];
        if (index != 0) { // If badge found (index is not 0)
            uint256 lastIndex = profile.ownedBadgeIds.length - 1;
            bytes32 lastBadge = profile.ownedBadgeIds[lastIndex];

            if (lastBadge != badgeId) { // If the badge to remove is not the last one, swap it
                profile.ownedBadgeIds[index - 1] = lastBadge; // Move last element to the position of the one being removed
                profile.badgeIdToIndex[lastBadge] = index; // Update the index of the moved element
            }

            profile.ownedBadgeIds.pop(); // Remove the last element (either the original or the swapped one)
            delete profile.badgeIdToIndex[badgeId]; // Remove mapping entry for the revoked badge
            profile.lastUpdated = block.timestamp;
            emit BadgeRevoked(user, badgeId);
        }
    }

    /**
     * @dev Revokes a specific badge from a user. Callable by `REPUTATION_MANAGER_ROLE`.
     * @param user The address of the user.
     * @param badgeId The ID of the badge to revoke.
     */
    function revokeBadge(address user, bytes32 badgeId) external onlyRole(REPUTATION_MANAGER_ROLE) {
        _revokeBadge(user, badgeId);
    }

    /**
     * @dev Retrieves a user's current reputation score, a list of their badges, and last update time.
     * @param user The address of the user.
     * @return score The user's reputation score.
     * @return badgeIds An array of badge IDs the user possesses.
     * @return lastUpdated The timestamp of the last reputation update.
     */
    function getReputationProfile(address user) external view returns (int256 score, bytes32[] memory badgeIds, uint256 lastUpdated) {
        ReputationProfile storage profile = _userReputationProfiles[user];
        score = profile.score;
        lastUpdated = profile.lastUpdated;
        
        // Return a copy of the ownedBadgeIds array
        uint256 badgeCount = profile.ownedBadgeIds.length;
        badgeIds = new bytes32[](badgeCount);
        for(uint k = 0; k < badgeCount; k++) {
            badgeIds[k] = profile.ownedBadgeIds[k];
        }
        return (score, badgeIds, lastUpdated);
    }
    
    // --- IV. Condition & Action Definitions (Configurable Policy Primitives) ---

    /**
     * @dev Defines a reusable set of conditions.
     * @param conditionSetId Unique ID for this set.
     * @param name Name of the condition set.
     * @param conditions An array of Condition structs.
     * @param logicOperator "AND" or "OR" logic for evaluation.
     */
    function defineConditionSet(
        bytes32 conditionSetId,
        string memory name,
        Condition[] memory conditions,
        bytes32 logicOperator
    ) external onlyRole(CONDITION_ACTION_MANAGER_ROLE) {
        require(conditionSetId != bytes32(0), "AxiomEngine: Invalid ConditionSet ID");
        require(conditionSets[conditionSetId].conditionSetId == bytes32(0), "AxiomEngine: ConditionSet ID already exists");
        require(logicOperator == keccak256("AND") || logicOperator == keccak256("OR"), "AxiomEngine: Invalid logic operator");
        require(conditions.length > 0, "AxiomEngine: Condition set must have at least one condition");

        conditionSets[conditionSetId] = ConditionSet({
            conditionSetId: conditionSetId,
            name: name,
            conditions: conditions,
            logicOperator: logicOperator,
            creator: _msgSender()
        });
        emit ConditionSetDefined(conditionSetId, _msgSender());
    }

    /**
     * @dev Updates an existing condition set.
     * @param conditionSetId ID of the condition set to update.
     * @param name New name for the condition set.
     * @param conditions New array of Condition structs.
     * @param logicOperator New logic operator.
     */
    function updateConditionSet(
        bytes32 conditionSetId,
        string memory name,
        Condition[] memory conditions,
        bytes32 logicOperator
    ) external onlyRole(CONDITION_ACTION_MANAGER_ROLE) {
        ConditionSet storage cSet = conditionSets[conditionSetId];
        require(cSet.conditionSetId != bytes32(0), "AxiomEngine: ConditionSet not found");
        require(logicOperator == keccak256("AND") || logicOperator == keccak256("OR"), "AxiomEngine: Invalid logic operator");
        require(conditions.length > 0, "AxiomEngine: Condition set must have at least one condition");

        cSet.name = name;
        cSet.conditions = conditions; // Overwrites existing conditions
        cSet.logicOperator = logicOperator;
        // Creator remains unchanged
        emit ConditionSetUpdated(conditionSetId, _msgSender());
    }

    /**
     * @dev Defines a reusable set of actions.
     * @param actionSetId Unique ID for this set.
     * @param name Name of the action set.
     * @param actions An array of Action structs.
     */
    function defineActionSet(
        bytes32 actionSetId,
        string memory name,
        Action[] memory actions
    ) external onlyRole(CONDITION_ACTION_MANAGER_ROLE) {
        require(actionSetId != bytes32(0), "AxiomEngine: Invalid ActionSet ID");
        require(actionSets[actionSetId].actionSetId == bytes32(0), "AxiomEngine: ActionSet ID already exists");
        require(actions.length > 0, "AxiomEngine: Action set must have at least one action");

        actionSets[actionSetId] = ActionSet({
            actionSetId: actionSetId,
            name: name,
            actions: actions,
            creator: _msgSender()
        });
        emit ActionSetDefined(actionSetId, _msgSender());
    }

    /**
     * @dev Updates an existing action set.
     * @param actionSetId ID of the action set to update.
     * @param name New name for the action set.
     * @param actions New array of Action structs.
     */
    function updateActionSet(
        bytes32 actionSetId,
        string memory name,
        Action[] memory actions
    ) external onlyRole(CONDITION_ACTION_MANAGER_ROLE) {
        ActionSet storage aSet = actionSets[actionSetId];
        require(aSet.actionSetId != bytes32(0), "AxiomEngine: ActionSet not found");
        require(actions.length > 0, "AxiomEngine: Action set must have at least one action");

        aSet.name = name;
        aSet.actions = actions; // Overwrites existing actions
        // Creator remains unchanged
        emit ActionSetUpdated(actionSetId, _msgSender());
    }

    // --- V. Access Control & System Configuration ---

    // `grantRole` and `revokeRole` are inherited from OpenZeppelin's `AccessControl`
    // and automatically protected by `DEFAULT_ADMIN_ROLE`.
    // In our constructor, `ADMIN_ROLE` is also granted to the `initialAdmin`, meaning
    // `initialAdmin` has both `DEFAULT_ADMIN_ROLE` and `ADMIN_ROLE`.
    // So, `grantRole(ADMIN_ROLE, account)` can be called by initialAdmin to give other addresses `ADMIN_ROLE`.
    // `grantRole(DEFAULT_ADMIN_ROLE, account)` is also possible but less common.

    /**
     * @dev Sets the address of the trusted oracle contract.
     * @param _oracleAddress The new oracle contract address.
     */
    function setOracleAddress(address _oracleAddress) external onlyRole(ADMIN_ROLE) {
        require(_oracleAddress != address(0), "AxiomEngine: Oracle address cannot be zero");
        emit OracleAddressSet(oracleAddress, _oracleAddress);
        oracleAddress = _oracleAddress;
    }

    /**
     * @dev Sets the minimum reputation required for an address to create policies.
     * @param _minReputation The new minimum reputation threshold.
     */
    function setMinReputationForPolicyCreation(uint256 _minReputation) external onlyRole(ADMIN_ROLE) {
        emit MinReputationForPolicyCreationSet(minReputationForPolicyCreation, _minReputation);
        minReputationForPolicyCreation = _minReputation;
    }

    /**
     * @dev Pauses the system, preventing policy executions. Only callable by ADMIN_ROLE.
     */
    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
        emit SystemPaused(block.timestamp);
    }

    /**
     * @dev Unpauses the system. Only callable by ADMIN_ROLE.
     */
    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
        emit SystemUnpaused(block.timestamp);
    }

    // --- Overrides for OpenZeppelin AccessControl & Pausable (Internal) ---
    // These ensure the contract adheres to upgradeability patterns if used with proxies,
    // and correctly integrates the role management.

    // This function is required by UUPS proxies if `AccessControl` is used as its admin mechanism.
    // While this contract itself is not a UUPS proxy, this method is part of `AccessControl`'s
    // upgradeable interface and needs to be present if `AccessControl` is imported.
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    // _beforeRoleTransfer is a hook from AccessControl that can be used to add custom logic
    // before a role is granted or revoked.
    function _beforeRoleTransfer(
        bytes32 role,
        address account,
        address newAdmin
    ) internal virtual override {
        // No custom logic needed for this example, but can be extended.
    }
}
```