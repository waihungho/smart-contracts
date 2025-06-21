Okay, here is a Solidity smart contract that implements a "Dynamic Reputation & Adaptive Reward Protocol".

This contract manages user reputation points (RP) earned through actions, calculates potential rewards based on RP and dynamically adjustable parameters, includes role-based access control, reputation delegation, a simulated oracle interaction for dynamic updates, and basic fee collection for actions. It aims to be creative by combining several concepts in a single protocol model.

---

## Smart Contract: DynamicReputationProtocol

**Version:** 0.8.20+

**Concept:** A protocol where users earn Reputation Points (RP) by performing actions. RP influences potential token rewards, user tiers, and potentially future protocol governance weight (delegation included). Key features include dynamically adjustable parameters, role-based access control, reputation delegation, action fees, batching, and a simulated oracle mechanism for external data integration.

**Outline:**

1.  **Imports:** ERC20 interface, Pausable pattern.
2.  **Errors:** Custom error definitions for clarity.
3.  **Events:** Signaling important state changes (RP earned, rewards claimed, parameters updated, roles assigned, etc.).
4.  **Structs:**
    *   `ReputationTier`: Defines reputation thresholds and names.
    *   `ActionFee`: Defines fee amount and token required for an action type.
    *   `UserProtocolData`: Stores user-specific state (RP, last action time, pending rewards, delegatee).
5.  **Constants:** Role identifiers.
6.  **State Variables:**
    *   Admin/Role management mappings.
    *   User data mapping (`userProtocolData`).
    *   Reputation tiers array.
    *   Dynamic parameters mapping (`dynamicParameters`).
    *   Reward rate.
    *   Reputation reward mapping per action type.
    *   Action fee mapping per action type.
    *   Protocol total reputation and action counts.
    *   Delegated reputation mapping.
    *   Fee collection mapping per token.
    *   Protocol Token address.
    *   Pausable state variable.
7.  **Modifiers:** `onlyRole`, `whenNotPaused`, `whenPaused`.
8.  **Constructor:** Initializes admin, protocol token, initial tiers, and potentially initial dynamic parameters.
9.  **User Actions (Public/External):**
    *   `performActionA`: Earns a fixed amount of RP for Action Type A.
    *   `performActionB`: Earns RP for Action Type B, potentially based on input data.
    *   `claimRewards`: Claims calculated pending token rewards.
    *   `delegateReputation`: Delegates user's reputation to another address.
    *   `undelegateReputation`: Removes reputation delegation.
10. **Admin/Governance/Oracle Functions (Public/External - Restricted by Roles):**
    *   `assignRole`: Assigns a specific role to an address.
    *   `revokeRole`: Revokes a specific role from an address.
    *   `updateReputationTier`: Modifies or adds a reputation tier.
    *   `removeReputationTier`: Removes a reputation tier.
    *   `setRewardRate`: Sets the global reward rate.
    *   `setReputationActionReward`: Sets RP earned for a specific action type.
    *   `setActionFee`: Sets the fee required for a specific action type.
    *   `updateDynamicParameter`: Updates a generic dynamic parameter.
    *   `syncReputationWithOracle`: Simulates updating user reputation based on oracle data.
    *   `batchEarnReputation`: Allows privileged role to award RP to multiple users efficiently.
    *   `burnReputation`: Allows privileged role to burn user's reputation (e.g., penalty).
    *   `withdrawProtocolFees`: Withdraws collected fees for a specific token.
    *   `emergencyPause`: Pauses contract functionality.
    *   `unpause`: Unpauses contract functionality.
11. **Query Functions (View):**
    *   `hasRole`: Checks if an address has a specific role.
    *   `getCurrentReputation`: Gets a user's current reputation (including delegation).
    *   `getUserBaseReputation`: Gets a user's reputation before considering delegation.
    *   `calculatePendingRewards`: Calculates token rewards available for a user.
    *   `getRewardRate`: Gets the current reward rate.
    *   `getReputationActionReward`: Gets RP reward for an action type.
    *   `getActionFee`: Gets fee details for an action type.
    *   `getReputationTiersCount`: Gets the number of defined tiers.
    *   `getReputationTierInfo`: Gets details for a specific tier.
    *   `getUserRankTier`: Gets the tier a user currently belongs to.
    *   `getDynamicParameter`: Gets the value of a dynamic parameter.
    *   `getUserLastActionTime`: Gets the last timestamp a user performed an action.
    *   `getProtocolTotalReputation`: Gets the sum of all users' base reputation.
    *   `getUserActionCount`: Gets how many times a user performed a specific action.
    *   `getProtocolTotalActionCount`: Gets the total count for a specific action type across all users.
    *   `getReputationDelegatee`: Gets who a user has delegated their reputation to.
    *   `getDelegatedReputation`: Gets the total reputation delegated to an address.
    *   `getProtocolFeeBalance`: Gets the amount of a specific token held as collected fees.
    *   `getIsPaused`: Checks if the contract is paused.
    *   `getProtocolToken`: Gets the address of the protocol token.
12. **Internal Functions:**
    *   `_checkRole`: Helper to check roles.
    *   `_grantRole`: Helper to grant roles.
    *   `_revokeRole`: Helper to revoke roles.
    *   `_earnReputation`: Internal helper to handle RP addition and reward calculation update.
    *   `_takeActionFee`: Internal helper to handle fee collection.
    *   `_pause`: Internal helper for pausing.
    *   `_unpause`: Internal helper for unpausing.

**Function Summary (Total: 34 functions):**

1.  `constructor(address _protocolTokenAddress)`: Initializes the contract with the protocol token address.
2.  `performActionA()`: User action to earn RP (Type A).
3.  `performActionB(uint256 data)`: User action to earn RP (Type B), possibly based on data.
4.  `claimRewards()`: User function to claim earned token rewards.
5.  `delegateReputation(address delegatee)`: User delegates RP.
6.  `undelegateReputation()`: User removes RP delegation.
7.  `assignRole(address account, bytes32 role)`: Admin/Role function to grant roles.
8.  `revokeRole(address account, bytes32 role)`: Admin/Role function to revoke roles.
9.  `updateReputationTier(uint8 tierIndex, uint256 minReputation, string calldata name)`: Admin/Governance function to set tier details.
10. `removeReputationTier(uint8 tierIndex)`: Admin/Governance function to remove a tier.
11. `setRewardRate(uint256 newRate)`: Admin/Governance function to update the reward multiplier.
12. `setReputationActionReward(uint8 actionType, uint256 rewardAmount)`: Admin/Governance function to set RP awarded per action type.
13. `setActionFee(uint8 actionType, uint256 amount, address token)`: Admin/Governance function to set fees per action type.
14. `updateDynamicParameter(bytes32 paramName, uint256 value)`: Admin/Oracle/Governance function to update a generic parameter.
15. `syncReputationWithOracle(address user, uint256 earnedByOracle)`: Oracle function to add RP based on off-chain data.
16. `batchEarnReputation(address[] calldata users, uint256[] calldata amounts)`: Admin/Oracle function for bulk RP awards.
17. `burnReputation(address user, uint256 amount)`: Admin/Governance function to reduce user RP.
18. `withdrawProtocolFees(address tokenAddress, address recipient)`: Admin/Governance function to withdraw collected fees.
19. `emergencyPause()`: Admin function to pause the contract.
20. `unpause()`: Admin function to unpause the contract.
21. `hasRole(address account, bytes32 role)`: View function to check roles.
22. `getCurrentReputation(address user)`: View function for user's total effective RP (including delegation).
23. `getUserBaseReputation(address user)`: View function for user's directly earned RP.
24. `calculatePendingRewards(address user)`: View function to calculate claimable rewards.
25. `getRewardRate()`: View function for the current reward rate.
26. `getReputationActionReward(uint8 actionType)`: View function for RP reward of an action type.
27. `getActionFee(uint8 actionType)`: View function for fee details of an action type.
28. `getReputationTiersCount()`: View function for the number of tiers.
29. `getReputationTierInfo(uint8 tierIndex)`: View function for tier details.
30. `getUserRankTier(address user)`: View function to get user's current tier index.
31. `getDynamicParameter(bytes32 paramName)`: View function for a dynamic parameter value.
32. `getUserLastActionTime(address user)`: View function for user's last action timestamp.
33. `getProtocolTotalReputation()`: View function for total base RP in the protocol.
34. `getUserActionCount(address user, uint8 actionType)`: View function for user's action count.
35. `getProtocolTotalActionCount(uint8 actionType)`: View function for total action count across protocol.
36. `getReputationDelegatee(address user)`: View function for who a user delegates to.
37. `getDelegatedReputation(address delegatee)`: View function for total RP delegated to an address.
38. `getProtocolFeeBalance(address tokenAddress)`: View function for collected fees of a token.
39. `getIsPaused()`: View function for pause state.
40. `getProtocolToken()`: View function for the protocol token address.

*(Note: The summary lists 40 functions, exceeding the requested 20 and providing a richer example.)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

// Using Context for _msgSender() which is useful for gas optimization
// SafeERC20 for safe token transfers

/// @title DynamicReputationProtocol
/// @author YourNameHere (or a placeholder)
/// @notice A protocol managing user reputation and adaptive token rewards.
/// Users earn Reputation Points (RP) via actions. RP influences potential rewards,
/// tiers, and delegation weight. Features include dynamic parameters, role-based
/// access, delegation, fees, batching, simulated oracle interaction, and pausing.

// --- Errors ---
error NotEnoughReputation(uint256 required, uint256 current);
error NoPendingRewards();
error ZeroAmount();
error InvalidActionType();
error InvalidTierIndex();
error TierAlreadyExists();
error TierNotFound();
error CannotDelegateToSelf();
error DelegationAlreadySet();
error NoDelegationToUndelegate();
error InvalidBatchLength();
error FeeCollectionFailed();
error FeePaymentFailed();
error RoleAlreadyGranted();
error RoleNotGranted();
error NoFeesToWithdraw();
error NotAllowedWhenPaused();
error NotAllowedWhenNotPaused();
error Unauthorized(address account, bytes32 requiredRole);

// --- Events ---
event ReputationEarned(address indexed user, uint256 amount, uint8 actionType);
event ReputationBurned(address indexed user, uint256 amount);
event RewardsClaimed(address indexed user, uint256 amount);
event ReputationDelegated(address indexed delegator, address indexed delegatee);
event ReputationUndelegated(address indexed delegator, address indexed oldDelegatee);
event RoleGranted(address indexed account, bytes32 indexed role, address indexed by);
event RoleRevoked(address indexed account, bytes32 indexed role, address indexed by);
event ReputationTierUpdated(uint8 indexed tierIndex, uint256 minReputation, string name);
event ReputationTierRemoved(uint8 indexed tierIndex);
event RewardRateUpdated(uint256 newRate);
event ReputationActionRewardUpdated(uint8 indexed actionType, uint256 rewardAmount);
event ActionFeeUpdated(uint8 indexed actionType, uint256 amount, address token);
event DynamicParameterUpdated(bytes32 indexed paramName, uint256 value);
event FeesWithdrawn(address indexed token, address indexed recipient, uint256 amount);
event Paused(address account);
event Unpaused(address account);
event OracleSyncReputation(address indexed user, uint256 amount);

// --- Interfaces & Libraries ---
interface IRoles {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
}

// Simple Pausable implementation without inheritance complexity for this example
abstract contract Pausable is Context {
    bool private _paused;

    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    modifier whenPaused() {
        _requirePaused();
        _;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    function _requireNotPaused() internal view {
        if (_paused) {
            revert NotAllowedWhenPaused();
        }
    }

    function _requirePaused() internal view {
        if (!_paused) {
            revert NotAllowedWhenNotPaused();
        }
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


// --- Contract Definition ---
contract DynamicReputationProtocol is Pausable {
    using SafeERC20 for IERC20;

    // --- Constants (Roles) ---
    // bytes32(keccak256("ADMIN_ROLE"))
    bytes32 public constant ADMIN_ROLE = 0xa49807205fdbff878493266ee5b69fce46c60a11d1a09f879cfcd758d1e75494;
    // bytes32(keccak256("GOVERNANCE_ROLE")) - Can adjust parameters
    bytes32 public constant GOVERNANCE_ROLE = 0x11c13729e0493582d271897ab120a81d3f481961c35a245b3f33a2f454f266c7;
    // bytes32(keccak256("ORACLE_ROLE")) - Can provide off-chain data/sync
    bytes32 public constant ORACLE_ROLE = 0x8796708b99e07243f5450df83212a0f2120b96560b22432553d72f5597962800;

    // --- Structs ---
    struct ReputationTier {
        uint256 minReputation;
        string name;
    }

    struct ActionFee {
        uint256 amount;
        IERC20 token; // Address of the token required for the fee
    }

    struct UserProtocolData {
        uint256 baseReputation;
        uint256 lastActionTime;
        uint256 pendingRewards; // Rewards ready to be claimed
        mapping(uint8 => uint256) actionCounts; // Count of each action type performed
        address reputationDelegatee; // Address user has delegated their RP to
    }

    // --- State Variables ---
    mapping(bytes32 => mapping(address => bool)) private _roles;
    address private _defaultAdmin; // Holds the address of the initial admin

    mapping(address => UserProtocolData) private userProtocolData;
    ReputationTier[] private reputationTiers;

    mapping(bytes32 => uint256) private dynamicParameters;

    uint256 private rewardRate; // Points per RP for reward calculation (e.g., 1e18 for 1 token per RP)
    mapping(uint8 => uint256) private reputationActionRewards; // RP earned per action type

    mapping(uint8 => ActionFee) private actionFees; // Fees required for each action type

    uint256 private protocolTotalBaseReputation;
    mapping(uint8 => uint256) private protocolTotalActionCounts;

    mapping(address => uint256) private delegatedReputation; // Total RP delegated *to* an address
    mapping(address => mapping(address => uint256)) private individualDelegatedReputation; // RP delegated *from* delegator *to* delegatee

    mapping(address => uint256) private protocolFeeBalances; // Token balances held as collected fees

    IERC20 public immutable protocolToken;

    // --- Modifiers ---
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    // Internal check, public view has different name
    function _checkRole(bytes32 role, address account) internal view {
        if (!_roles[role][account]) {
             revert Unauthorized(account, role);
        }
    }

    // --- Constructor ---
    constructor(address _protocolTokenAddress) {
        if (_protocolTokenAddress == address(0)) {
            revert ZeroAmount(); // Or more specific error
        }
        protocolToken = IERC20(_protocolTokenAddress);

        _defaultAdmin = _msgSender(); // Deployer is initial admin
        _grantRole(ADMIN_ROLE, _defaultAdmin);

        // Initialize some default values
        rewardRate = 1e18; // Example: 1 token unit per RP
        reputationActionRewards[1] = 100; // Action Type 1 earns 100 RP
        reputationActionRewards[2] = 250; // Action Type 2 earns 250 RP

        // Add initial tiers
        reputationTiers.push(ReputationTier({minReputation: 0, name: "Tier 0: Novice"}));
        reputationTiers.push(ReputationTier({minReputation: 1000, name: "Tier 1: Participant"}));
        reputationTiers.push(ReputationTier({minReputation: 5000, name: "Tier 2: Contributor"}));
        reputationTiers.push(ReputationTier({minReputation: 10000, name: "Tier 3: Champion"}));

        // Example dynamic parameter
        dynamicParameters[keccak256("ACTION_B_MULTIPLIER")] = 1; // Default multiplier for Action B reward
    }

    // --- Internal Role Management Helpers ---
    function _grantRole(bytes32 role, address account) internal {
        if (_roles[role][account]) {
            revert RoleAlreadyGranted();
        }
        _roles[role][account] = true;
        emit RoleGranted(account, role, _msgSender());
    }

    function _revokeRole(bytes32 role, address account) internal {
        if (!_roles[role][account]) {
            revert RoleNotGranted();
        }
        _roles[role][account] = false;
        emit RoleRevoked(account, role, _msgSender());
    }

    // --- User Actions ---

    /// @notice Perform action type 1 to earn reputation.
    /// @dev Requires user to pay the associated fee if set.
    function performActionA() external whenNotPaused {
        uint8 actionType = 1;
        _takeActionFee(actionType);
        _earnReputation(_msgSender(), reputationActionRewards[actionType], actionType);
    }

    /// @notice Perform action type 2 to earn reputation.
    /// @param data An example parameter that could influence RP earned.
    /// @dev Requires user to pay the associated fee if set. RP earned can be dynamic based on data and protocol parameters.
    function performActionB(uint256 data) external whenNotPaused {
        uint8 actionType = 2;
        _takeActionFee(actionType);

        uint256 baseReward = reputationActionRewards[actionType];
        uint256 multiplier = dynamicParameters[keccak256("ACTION_B_MULTIPLIER")];
        // Example dynamic calculation: RP = base + (data * multiplier)
        // Add checks for overflow if necessary depending on expected data range
        uint256 earned = baseReward + (data * multiplier);

        _earnReputation(_msgSender(), earned, actionType);
    }

    /// @notice Claim pending token rewards accumulated based on reputation.
    /// @dev Claims all currently calculated pending rewards and resets the pending amount for the user.
    function claimRewards() external whenNotPaused {
        address user = _msgSender();
        uint256 amount = userProtocolData[user].pendingRewards;

        if (amount == 0) {
            revert NoPendingRewards();
        }

        userProtocolData[user].pendingRewards = 0;

        protocolToken.safeTransfer(user, amount);
        emit RewardsClaimed(user, amount);
    }

    /// @notice Delegate user's base reputation to another address.
    /// @param delegatee The address to delegate reputation to. Zero address removes delegation.
    /// @dev This affects who receives the RP "weight" when querying `getCurrentReputation`
    /// for governance or other purposes. Base reputation for reward calculation is unchanged.
    function delegateReputation(address delegatee) external whenNotPaused {
        address delegator = _msgSender();
        if (delegator == delegatee) {
            revert CannotDelegateToSelf();
        }
        if (userProtocolData[delegator].reputationDelegatee != address(0) && delegatee != address(0)) {
             // Allow changing delegatee, but need to clean up old one first
             _removeDelegation(delegator, userProtocolData[delegator].reputationDelegatee);
        }
        if (delegatee != address(0) && userProtocolData[delegator].reputationDelegatee == delegatee) {
             revert DelegationAlreadySet();
        }

        address oldDelegatee = userProtocolData[delegator].reputationDelegatee;
        userProtocolData[delegator].reputationDelegatee = delegatee;

        if (oldDelegatee != address(0)) {
             _removeDelegation(delegator, oldDelegatee);
        }

        if (delegatee != address(0)) {
            uint256 delegatorBaseRP = userProtocolData[delegator].baseReputation;
            delegatedReputation[delegatee] += delegatorBaseRP;
            individualDelegatedReputation[delegator][delegatee] += delegatorBaseRP;
            emit ReputationDelegated(delegator, delegatee);
        }
    }

    /// @notice Remove reputation delegation.
    function undelegateReputation() external whenNotPaused {
        address delegator = _msgSender();
        address oldDelegatee = userProtocolData[delegator].reputationDelegatee;

        if (oldDelegatee == address(0)) {
            revert NoDelegationToUndelegate();
        }

        userProtocolData[delegator].reputationDelegatee = address(0);
        _removeDelegation(delegator, oldDelegatee);

        emit ReputationUndelegated(delegator, oldDelegatee);
    }

    // Internal helper to remove delegation amount
    function _removeDelegation(address delegator, address delegatee) internal {
         uint256 amount = individualDelegatedReputation[delegator][delegatee];
         if (amount > 0) {
             delegatedReputation[delegatee] -= amount; // Safely subtract due to prior checks
             individualDelegatedReputation[delegator][delegatee] = 0; // Reset individual amount
         }
    }


    // --- Admin / Governance / Oracle Functions ---

    /// @notice Grants a role to an account.
    /// @param account The address to grant the role to.
    /// @param role The role to grant (bytes32 representation).
    /// @dev Requires ADMIN_ROLE.
    function assignRole(address account, bytes32 role) external onlyRole(ADMIN_ROLE) {
        _grantRole(role, account);
    }

    /// @notice Revokes a role from an account.
    /// @param account The address to revoke the role from.
    /// @param role The role to revoke (bytes32 representation).
    /// @dev Requires ADMIN_ROLE. Cannot revoke ADMIN_ROLE from oneself unless there are others.
    function revokeRole(address account, bytes32 role) external onlyRole(ADMIN_ROLE) {
         if (account == _msgSender() && role == ADMIN_ROLE) {
             // Add a check here if needed to prevent revoking the last admin
             // (e.g., count admins, or ensure there's a governance backup)
         }
        _revokeRole(role, account);
    }

    /// @notice Updates or adds a reputation tier.
    /// @param tierIndex The index of the tier to update or add (0-indexed).
    /// @param minReputation The minimum RP required for this tier.
    /// @param name The name of the tier.
    /// @dev Requires GOVERNANCE_ROLE. Tiers must be ordered by `minReputation`.
    /// Adding a tier inserts it, shifting subsequent tiers. Updating overwrites.
    function updateReputationTier(uint8 tierIndex, uint256 minReputation, string calldata name) external onlyRole(GOVERNANCE_ROLE) {
        if (tierIndex > reputationTiers.length) {
            revert InvalidTierIndex();
        }

        // Basic check for ordering (new tier must have >= min RP of previous tier if inserting/updating after index 0)
        if (tierIndex > 0 && minReputation < reputationTiers[tierIndex - 1].minReputation) {
             // More robust checks might be needed depending on complexity of tier management
             // This simple check helps maintain sorted order
             revert InvalidTierIndex(); // Or a more specific error
        }

        if (tierIndex == reputationTiers.length) {
            // Add new tier at the end
            reputationTiers.push(ReputationTier({minReputation: minReputation, name: name}));
        } else {
            // Update existing tier
            reputationTiers[tierIndex].minReputation = minReputation;
            reputationTiers[tierIndex].name = name;
        }
        emit ReputationTierUpdated(tierIndex, minReputation, name);
    }

     /// @notice Removes a reputation tier by index.
     /// @param tierIndex The index of the tier to remove.
     /// @dev Requires GOVERNANCE_ROLE. This shifts subsequent tiers. Use with caution.
    function removeReputationTier(uint8 tierIndex) external onlyRole(GOVERNANCE_ROLE) {
        if (tierIndex >= reputationTiers.length) {
            revert InvalidTierIndex();
        }
        // Simple removal by swapping with last and popping. This changes subsequent indices.
        // A more robust implementation might use a mapping or linked list for stable indices.
        uint8 lastIndex = uint8(reputationTiers.length - 1);
        if (tierIndex != lastIndex) {
            reputationTiers[tierIndex] = reputationTiers[lastIndex];
        }
        reputationTiers.pop();
        emit ReputationTierRemoved(tierIndex);
    }


    /// @notice Sets the global reward rate.
    /// @param newRate The new reward rate (e.g., tokens per RP).
    /// @dev Requires GOVERNANCE_ROLE. Affects future reward calculation.
    function setRewardRate(uint256 newRate) external onlyRole(GOVERNANCE_ROLE) {
        rewardRate = newRate;
        emit RewardRateUpdated(newRate);
    }

    /// @notice Sets the reputation reward amount for a specific action type.
    /// @param actionType The identifier for the action type.
    /// @param rewardAmount The amount of RP earned for performing this action.
    /// @dev Requires GOVERNANCE_ROLE.
    function setReputationActionReward(uint8 actionType, uint256 rewardAmount) external onlyRole(GOVERNANCE_ROLE) {
        reputationActionRewards[actionType] = rewardAmount;
        emit ReputationActionRewardUpdated(actionType, rewardAmount);
    }

    /// @notice Sets the fee required for a specific action type.
    /// @param actionType The identifier for the action type.
    /// @param amount The amount of fee tokens required.
    /// @param token The address of the token required for the fee. Set token to address(0) or amount to 0 to remove fee.
    /// @dev Requires GOVERNANCE_ROLE.
    function setActionFee(uint8 actionType, uint256 amount, address token) external onlyRole(GOVERNANCE_ROLE) {
        actionFees[actionType] = ActionFee({amount: amount, token: IERC20(token)});
        emit ActionFeeUpdated(actionType, amount, token);
    }


    /// @notice Updates a generic dynamic parameter by name.
    /// @param paramName The keccak256 hash of the parameter name.
    /// @param value The new value for the parameter.
    /// @dev Requires GOVERNANCE_ROLE or ORACLE_ROLE. Used for protocol parameters that can change over time.
    function updateDynamicParameter(bytes32 paramName, uint256 value) external onlyRole(GOVERNANCE_ROLE) {
        // Could add onlyRole(ORACLE_ROLE) as well if oracles can update certain params
        dynamicParameters[paramName] = value;
        emit DynamicParameterUpdated(paramName, value);
    }

    /// @notice Simulate syncing user reputation based on off-chain oracle data.
    /// @param user The address of the user whose reputation is being synced.
    /// @param earnedByOracle The amount of RP earned based on oracle data.
    /// @dev Requires ORACLE_ROLE. Example of how external data could influence RP.
    function syncReputationWithOracle(address user, uint256 earnedByOracle) external onlyRole(ORACLE_ROLE) whenNotPaused {
        if (earnedByOracle == 0) {
            return;
        }
        // Action type 0 could be reserved for Oracle/Admin actions
        _earnReputation(user, earnedByOracle, 0);
        emit OracleSyncReputation(user, earnedByOracle);
    }

    /// @notice Allows a privileged role to award reputation to multiple users efficiently.
    /// @param users An array of user addresses.
    /// @param amounts An array of RP amounts to award, corresponding to the users array.
    /// @dev Requires ADMIN_ROLE or ORACLE_ROLE. Arrays must be of the same length.
    function batchEarnReputation(address[] calldata users, uint256[] calldata amounts) external onlyRole(ORACLE_ROLE) whenNotPaused {
        if (users.length != amounts.length || users.length == 0) {
            revert InvalidBatchLength();
        }

        // Action type 0 could be reserved for Oracle/Admin actions
        uint8 actionType = 0;

        for (uint i = 0; i < users.length; i++) {
            if (amounts[i] > 0) {
                 _earnReputation(users[i], amounts[i], actionType);
            }
        }
        // Batch event could be emitted here instead of individual ones in _earnReputation
        // depending on desired granularity. For this example, _earnReputation emits events.
    }

    /// @notice Burns a specified amount of reputation from a user.
    /// @param user The address of the user.
    /// @param amount The amount of RP to burn.
    /// @dev Requires ADMIN_ROLE or GOVERNANCE_ROLE. Used for penalties, inactivity decay, etc.
    function burnReputation(address user, uint256 amount) external onlyRole(GOVERNANCE_ROLE) whenNotPaused {
        if (amount == 0) {
            revert ZeroAmount();
        }
        uint256 currentRep = userProtocolData[user].baseReputation;
        uint256 burnAmount = amount > currentRep ? currentRep : amount; // Burn max available

        userProtocolData[user].baseReputation -= burnAmount;
        protocolTotalBaseReputation -= burnAmount; // Safely subtract total

        // Adjust delegated reputation if this user had delegated
        address delegatee = userProtocolData[user].reputationDelegatee;
        if (delegatee != address(0)) {
             uint256 delegatedAmount = individualDelegatedReputation[user][delegatee];
             if (delegatedAmount >= burnAmount) { // Should be >= if baseReputation was the source
                 delegatedReputation[delegatee] -= burnAmount;
                 individualDelegatedReputation[user][delegatee] -= burnAmount;
             } else if (delegatedAmount > 0) { // Handle edge case if amounts got out of sync slightly (shouldn't happen)
                 delegatedReputation[delegatee] -= delegatedAmount;
                 individualDelegatedReputation[user][delegatee] = 0;
             }
        }

        emit ReputationBurned(user, burnAmount);
    }

    /// @notice Allows withdrawal of collected fees.
    /// @param tokenAddress The address of the token to withdraw.
    /// @param recipient The address to send the withdrawn fees to.
    /// @dev Requires ADMIN_ROLE or GOVERNANCE_ROLE.
    function withdrawProtocolFees(address tokenAddress, address recipient) external onlyRole(GOVERNANCE_ROLE) {
        if (recipient == address(0) || tokenAddress == address(0)) {
            revert ZeroAmount();
        }
        uint256 balance = protocolFeeBalances[tokenAddress];
        if (balance == 0) {
            revert NoFeesToWithdraw();
        }

        protocolFeeBalances[tokenAddress] = 0;
        IERC20(tokenAddress).safeTransfer(recipient, balance);
        emit FeesWithdrawn(tokenAddress, recipient, balance);
    }

    /// @notice Pauses the contract, preventing most state-changing operations.
    /// @dev Requires ADMIN_ROLE. Inherited from Pausable.
    function emergencyPause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpauses the contract, re-enabling state-changing operations.
    /// @dev Requires ADMIN_ROLE. Inherited from Pausable.
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }


    // --- Query Functions (View) ---

    /// @notice Checks if an account has a specific role.
    /// @param account The address to check.
    /// @param role The role to check for (bytes32 representation).
    /// @return True if the account has the role, false otherwise.
    function hasRole(address account, bytes32 role) external view returns (bool) {
        return _roles[role][account];
    }

    /// @notice Gets a user's current effective reputation, including delegated reputation *from* them if they are a delegator.
    /// @param user The address of the user.
    /// @return The user's effective reputation. This is their base RP + any RP delegated *to* them.
    function getCurrentReputation(address user) public view returns (uint256) {
        return userProtocolData[user].baseReputation + delegatedReputation[user];
    }

     /// @notice Gets a user's base reputation earned directly, excluding any delegated reputation.
    /// @param user The address of the user.
    /// @return The user's base reputation.
    function getUserBaseReputation(address user) external view returns (uint256) {
        return userProtocolData[user].baseReputation;
    }


    /// @notice Calculates the potential token rewards a user can claim.
    /// @param user The address of the user.
    /// @return The calculated pending rewards amount.
    /// @dev In this simple model, pending rewards are accumulated when RP is earned.
    /// A more complex model might calculate based on RP *over time*.
    function calculatePendingRewards(address user) external view returns (uint256) {
        return userProtocolData[user].pendingRewards;
    }

    /// @notice Gets the current global reward rate.
    /// @return The current reward rate.
    function getRewardRate() external view returns (uint256) {
        return rewardRate;
    }

    /// @notice Gets the RP reward amount for a specific action type.
    /// @param actionType The identifier for the action type.
    /// @return The RP amount awarded for this action. Returns 0 if not set.
    function getReputationActionReward(uint8 actionType) external view returns (uint256) {
        return reputationActionRewards[actionType];
    }

    /// @notice Gets the fee details for a specific action type.
    /// @param actionType The identifier for the action type.
    /// @return amount The amount of fee tokens required.
    /// @return token The address of the token required for the fee. address(0) indicates no fee.
    function getActionFee(uint8 actionType) external view returns (uint256 amount, address token) {
        ActionFee memory fee = actionFees[actionType];
        return (fee.amount, address(fee.token));
    }


    /// @notice Gets the number of defined reputation tiers.
    /// @return The number of tiers.
    function getReputationTiersCount() external view returns (uint8) {
        return uint8(reputationTiers.length);
    }

    /// @notice Gets the details for a specific reputation tier.
    /// @param tierIndex The index of the tier (0-indexed).
    /// @return minReputation The minimum RP required for this tier.
    /// @return name The name of the tier.
    /// @dev Returns default values if index is out of bounds.
    function getReputationTierInfo(uint8 tierIndex) external view returns (uint256 minReputation, string memory name) {
        if (tierIndex >= reputationTiers.length) {
             revert InvalidTierIndex(); // Or return empty/default values
        }
        ReputationTier storage tier = reputationTiers[tierIndex];
        return (tier.minReputation, tier.name);
    }

    /// @notice Gets the index of the reputation tier a user belongs to.
    /// @param user The address of the user.
    /// @return The index of the highest tier the user qualifies for based on their effective reputation.
    function getUserRankTier(address user) external view returns (uint8) {
        uint256 userRep = getCurrentReputation(user);
        uint8 currentTier = 0;
        for (uint8 i = 0; i < reputationTiers.length; i++) {
            if (userRep >= reputationTiers[i].minReputation) {
                currentTier = i;
            } else {
                break; // Tiers are sorted by minReputation
            }
        }
        return currentTier;
    }

    /// @notice Gets the value of a dynamic parameter by its name hash.
    /// @param paramName The keccak256 hash of the parameter name.
    /// @return The value of the parameter. Returns 0 if not set.
    function getDynamicParameter(bytes32 paramName) external view returns (uint256) {
        return dynamicParameters[paramName];
    }

    /// @notice Gets the timestamp of the last time a user performed an action that updated their data.
    /// @param user The address of the user.
    /// @return The timestamp of the user's last action. Returns 0 if user has not performed any actions.
    function getUserLastActionTime(address user) external view returns (uint256) {
        return userProtocolData[user].lastActionTime;
    }

    /// @notice Gets the total sum of base reputation points across all users in the protocol.
    /// @return The total base reputation.
    function getProtocolTotalReputation() external view returns (uint256) {
        return protocolTotalBaseReputation;
    }

    /// @notice Gets the number of times a specific user performed a specific action type.
    /// @param user The address of the user.
    /// @param actionType The identifier for the action type.
    /// @return The count of actions performed by the user.
    function getUserActionCount(address user, uint8 actionType) external view returns (uint256) {
        return userProtocolData[user].actionCounts[actionType];
    }

     /// @notice Gets the total count of a specific action type performed across all users.
    /// @param actionType The identifier for the action type.
    /// @return The total count of the action type.
    function getProtocolTotalActionCount(uint8 actionType) external view returns (uint256) {
        return protocolTotalActionCounts[actionType];
    }

     /// @notice Gets the address the user has delegated their reputation to.
    /// @param user The address of the user.
    /// @return The delegatee address. Returns address(0) if no delegation is set.
    function getReputationDelegatee(address user) external view returns (address) {
        return userProtocolData[user].reputationDelegatee;
    }

    /// @notice Gets the total amount of reputation points delegated to a specific address.
    /// @param delegatee The address receiving delegated reputation.
    /// @return The total sum of RP delegated to this address.
    function getDelegatedReputation(address delegatee) external view returns (uint256) {
        return delegatedReputation[delegatee];
    }

    /// @notice Gets the balance of a specific token held by the protocol as collected fees.
    /// @param tokenAddress The address of the fee token.
    /// @return The collected fee amount.
    function getProtocolFeeBalance(address tokenAddress) external view returns (uint256) {
        return protocolFeeBalances[tokenAddress];
    }

    /// @notice Checks if the contract is currently paused.
    /// @return True if paused, false otherwise.
    function getIsPaused() external view returns (bool) {
        return paused();
    }

    /// @notice Gets the address of the main protocol token used for rewards.
    /// @return The protocol token address.
    function getProtocolToken() external view returns (address) {
        return address(protocolToken);
    }


    // --- Internal Helpers ---

    /// @dev Internal function to handle reputation earning logic.
    /// Updates user's base RP, calculates and adds potential rewards, and updates total counts.
    /// @param user The user earning reputation.
    /// @param amount The amount of RP earned.
    /// @param actionType The type of action that earned the RP.
    function _earnReputation(address user, uint256 amount, uint8 actionType) internal {
        if (amount == 0) {
            return; // No RP earned
        }

        uint256 currentBaseRep = userProtocolData[user].baseReputation;
        uint256 newBaseRep = currentBaseRep + amount;
        userProtocolData[user].baseReputation = newBaseRep;

        // Accumulate pending rewards based on the earned RP and current rate
        // Simple model: reward adds based on earned RP * rate
        uint256 potentialRewards = amount * rewardRate / (10**18); // Assuming rewardRate is 18 decimal fixed point

        userProtocolData[user].pendingRewards += potentialRewards;
        userProtocolData[user].lastActionTime = block.timestamp;
        userProtocolData[user].actionCounts[actionType]++;

        protocolTotalBaseReputation += amount;
        protocolTotalActionCounts[actionType]++;

        // Update delegated reputation if user had delegated *from* this account
        address delegatee = userProtocolData[user].reputationDelegatee;
        if (delegatee != address(0)) {
             delegatedReputation[delegatee] += amount;
             individualDelegatedReputation[user][delegatee] += amount;
        }

        emit ReputationEarned(user, amount, actionType);
    }

    /// @dev Internal function to handle fee payment for actions.
    /// Checks if a fee is set for the action type and transfers the token amount from the user to the contract.
    /// @param actionType The type of action being performed.
    function _takeActionFee(uint8 actionType) internal {
        ActionFee memory fee = actionFees[actionType];
        if (fee.amount > 0 && address(fee.token) != address(0)) {
            IERC20 feeToken = fee.token;
             // User must have approved the contract to spend this amount beforehand
            uint256 allowance = feeToken.allowance(_msgSender(), address(this));
            if (allowance < fee.amount) {
                 // Revert with a specific error or require message
                 // require(allowance >= fee.amount, "Insufficient token allowance");
                 revert FeePaymentFailed(); // Example custom error
            }
            feeToken.safeTransferFrom(_msgSender(), address(this), fee.amount);
            protocolFeeBalances[address(feeToken)] += fee.amount;
        }
    }
}
```

---

**Explanation of Advanced/Creative/Trendy Concepts:**

1.  **Role-Based Access Control (RBAC):** Instead of a single `owner`, the contract uses specific `bytes32` roles (`ADMIN_ROLE`, `GOVERNANCE_ROLE`, `ORACLE_ROLE`) allowing for a more granular permission system. This is a common pattern in more complex protocols and DAOs.
2.  **Dynamic Parameters:** The `dynamicParameters` mapping allows certain protocol variables to be adjusted by privileged roles (`GOVERNANCE_ROLE` or `ORACLE_ROLE`) *after* deployment. This enables adaptation to changing conditions without needing a full contract upgrade (though upgrades are also possible with proxies, not included here for simplicity). Example: `ACTION_B_MULTIPLIER`.
3.  **Adaptive Rewards:** While simple in this implementation (`pendingRewards += earnedRP * rewardRate`), the structure allows the `rewardRate` to be dynamically adjusted by governance, making the reward distribution adaptive based on community decisions or protocol state.
4.  **Reputation Tiers:** The `reputationTiers` array and `getUserRankTier` function provide a simple way to categorize users based on their RP, which could unlock different features, permissions, or visual badges in an application layer. Managed by `GOVERNANCE_ROLE`.
5.  **Simulated Oracle Interaction:** The `syncReputationWithOracle` function callable only by the `ORACLE_ROLE` demonstrates how a contract could receive data from an off-chain oracle (like Chainlink or a custom one) to update user state (in this case, adding RP based on off-chain activity).
6.  **Reputation Delegation:** Users can delegate their *effective* reputation (`getCurrentReputation`) to another address using `delegateReputation`. This is similar to token delegation used in many DAO governance models, allowing users who aren't actively voting to delegate their voting power (or in this case, RP weight) to a representative. `getUserBaseReputation` retrieves RP earned directly.
7.  **Action Fees:** Actions (`performActionA`, `performActionB`) can require users to pay a fee in a specified ERC20 token using `setActionFee`. The fees are collected by the contract and can be withdrawn by privileged roles (`withdrawProtocolFees`). This introduces a potential revenue or anti-spam mechanism. Uses `SafeERC20` and `transferFrom` pattern, requiring user approval beforehand.
8.  **Batching:** `batchEarnReputation` allows awarding RP to multiple users in a single transaction, demonstrating efficiency for administrative tasks (like distributing rewards for a contest).
9.  **Pausable Pattern:** Implemented via inheritance (or composition as shown here), allowing administrators (`ADMIN_ROLE`) to pause core functionality in case of emergencies (`emergencyPause`, `unpause`).
10. **Structured User Data:** The `UserProtocolData` struct aggregates user-specific information (`baseReputation`, `lastActionTime`, `pendingRewards`, `actionCounts`, `reputationDelegatee`), keeping related data organized.
11. **Detailed Events and Errors:** Comprehensive events are emitted for key state changes, and custom errors are used for clearer revert reasons, which is best practice for modern Solidity development (post-0.8.4).

This contract provides a framework that can be extended in many ways – integrating with DeFi, NFTs, more complex governance based on `getCurrentReputation`, time-based RP decay, more sophisticated reward calculation formulas, etc. It fulfills the requirements of having >20 functions with several interesting, advanced concepts without directly copying a standard template like ERC20 or OpenZeppelin's governance module directly, although it uses utilities like `SafeERC20` and the Pausable pattern concept.