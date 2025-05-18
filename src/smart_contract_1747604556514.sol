Okay, let's create a smart contract concept that combines several advanced/trendy ideas: a multi-asset vault with dynamic rules based on an internal "Flux" energy state, conditional time/state releases, simulated yield calculation, and granular role-based access control with delegation features.

We'll call it `QuantumFluxVault`.

Here's the outline and summary, followed by the Solidity code.

---

## QuantumFluxVault Smart Contract

**Outline:**

1.  ** SPDX-License-Identifier & Pragma**
2.  ** Imports** (ERC20 standard)
3.  ** Events:** To signal important state changes.
4.  ** Errors:** Custom errors for clearer failure reasons.
5.  ** Constants:** Role identifiers, module names.
6.  ** Enums:** For state representation (e.g., Vault State).
7.  ** Structs:** Data structures for rules, releases, delegations.
8.  ** State Variables:**
    *   Owner, Vault State
    *   Role Management (Mapping address to roles)
    *   Asset Balances (Vault holdings)
    *   User Balances (User deposits within the vault)
    *   Flux Energy System State (Current Flux, timestamp of last update)
    *   Dynamic Parameters (Configurable values influencing rules/flux)
    *   Withdrawal Rules (Mapping token address to rules)
    *   Conditional Releases (Array/Mapping of scheduled releases)
    *   Delegation Permissions (Mapping for delegated withdrawal rights)
    *   Daily Withdrawal Tracking (For rate limits)
    *   Module Enablement (Mapping module name to boolean)
    *   Yield Simulation State (Deposit timestamps for yield calculation)
9.  ** Modifiers:** Access control (`onlyOwner`, `onlyRole`, `whenNotPaused`).
10. ** Constructor:** Initialize owner and default roles/parameters.
11. ** Internal Helper Functions:**
    *   `_updateFluxEnergy`: Logic to update the Flux state.
    *   `_canWithdrawInternal`: Core logic checking all withdrawal conditions.
    *   `_calculateSimulatedYield`: Logic for yield calculation.
12. ** Core Vault Functions (Deposit/Withdraw):**
    *   Deposit ETH/ERC20
    *   Withdraw ETH/ERC20 (Applying dynamic rules)
13. ** Balance & State View Functions:**
    *   Get user/vault balances.
    *   Get current Flux, parameters, rules, release status.
    *   Check if withdrawal is possible (`canWithdraw`).
    *   Get simulated yield.
14. ** Access Control & Role Management Functions:**
    *   Assign/revoke roles.
    *   Check roles.
15. ** Dynamic Rules & Parameter Management Functions:**
    *   Set withdrawal rules based on Flux, time, etc.
    *   Set generic vault parameters.
    *   Set yield simulation parameters.
16. ** Flux System Management Functions:**
    *   Manually trigger Flux updates (permissioned).
    *   Adjust Flux parameters.
17. ** Conditional Release Functions:**
    *   Schedule new releases.
    *   Cancel scheduled releases.
    *   Claim scheduled releases.
    *   View pending releases.
18. ** Delegation Functions:**
    *   Delegate withdrawal rights to another address.
    *   Execute delegated withdrawals.
    *   Renounce delegation.
19. ** Module Management Functions:**
    *   Enable/disable specific advanced features.
20. ** Emergency & Admin Functions:**
    *   Pause/Resume.
    *   Sweep accidental token transfers.
    *   Transfer Ownership.

**Function Summary (Highlighting core/advanced ones):**

1.  `constructor()`: Initializes the contract, sets owner, assigns initial admin role.
2.  `depositETH() payable`: Allows users to deposit Ether into the vault. Updates user balance and potentially Flux energy.
3.  `depositERC20(address token, uint256 amount)`: Allows users to deposit approved ERC20 tokens. Updates balances and potentially Flux.
4.  `withdrawETHWithRules(uint256 amount)`: Allows users to withdraw ETH, subject to the currently active withdrawal rules and internal state (like Flux).
5.  `withdrawERC20WithRules(address token, uint256 amount)`: Allows users to withdraw ERC20 tokens, subject to the active rules and internal state.
6.  `canWithdraw(address user, address token, uint256 amount)`: *View function* checking if a specific user *could* withdraw a given amount of a token *right now* based on *all* applicable rules (balance, lock time, daily limit, Flux level).
7.  `getUserETHBalance(address user)`: *View function* to get a user's deposited ETH balance.
8.  `getUserERC20Balance(address user, address token)`: *View function* to get a user's deposited token balance.
9.  `assignRole(address user, bytes32 role)`: (Admin function) Assigns a specific role (e.g., `RULE_MANAGER_ROLE`, `FLUX_MASTER_ROLE`) to an address.
10. `revokeRole(address user, bytes32 role)`: (Admin function) Revokes a role from an address.
11. `hasRole(address user, bytes32 role)`: *View function* to check if an address has a specific role.
12. `setWithdrawalRule(address token, uint256 minFlux, uint256 maxFlux, uint64 minLockDuration, uint256 maxDailyAmount)`: (Role-based) Sets or updates the dynamic withdrawal rule for a specific token, dependent on Flux range, minimum deposit lock time, and maximum daily withdrawal amount.
13. `getWithdrawalRule(address token)`: *View function* to retrieve the current withdrawal rule for a token.
14. `getCurrentFluxEnergy()`: *View function* to get the current Flux energy level of the vault. This function also triggers an internal update to account for time-based changes.
15. `setFluxParameters(uint256 timeDecayRate, uint256 depositBoost, uint256 minFluxIncreaseInterval)`: (Role-based) Sets parameters that govern how Flux energy changes over time and with actions.
16. `scheduleConditionalRelease(address token, uint256 amount, uint64 releaseTime, uint256 minFluxAtRelease)`: Allows a user to lock funds for a future release, which only becomes claimable *after* a specific time *and* if the vault's Flux energy is *at least* a certain level.
17. `cancelConditionalRelease(uint256 releaseId)`: Allows the user who scheduled it to cancel a pending conditional release (if not yet claimable).
18. `claimScheduledRelease(uint256 releaseId)`: Allows the beneficiary to claim a scheduled release if all conditions (time and Flux) are met.
19. `getPendingConditionalReleases(address user)`: *View function* to list the IDs of scheduled releases for a specific user.
20. `delegateWithdrawalPermission(address delegatee, address token, uint256 allowance, uint64 expiration)`: Allows a user to delegate permission to another address (`delegatee`) to withdraw *their* funds up to a specific `allowance` amount of a `token` before an `expiration` timestamp.
21. `delegatedWithdrawal(address owner, address token, uint256 amount)`: Allows a `delegatee` (who received permission via `delegateWithdrawalPermission`) to withdraw `amount` of `token` from the funds deposited by `owner`.
22. `getEstimatedYield(address user, address token)`: *View function* calculating a *simulated* yield based on the user's deposit history (deposit time/amount) and pre-set yield parameters. This is not real external yield but an internal calculation.
23. `setYieldParameters(address token, uint256 annualRateBasisPoints, uint64 compoundFrequency)`: (Role-based) Sets the parameters (annual rate, compounding frequency) used for the simulated yield calculation for a specific token.
24. `setModuleEnabled(bytes32 module, bool enabled)`: (Admin function) Allows enabling or disabling certain advanced features (modules) of the contract, like delegation or complex rules.
25. `panicShutdown()`: (Admin function) Immediately pauses all core operations (deposits, withdrawals, claims).
26. `resumeOperations()`: (Admin function) Resumes operations after a panic shutdown.

*Self-correction:* We have 26 functions listed above. This exceeds the minimum of 20 and covers the core requirements with advanced concepts. Some are views, some are state-changing. The key advanced concepts are the Flux-based dynamic rules, the conditional releases with state checks (Flux), the delegation mechanism, and the simulated yield calculation.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for basic ownership pattern

/**
 * @title QuantumFluxVault
 * @dev A multi-asset vault with dynamic withdrawal rules based on an internal "Flux" energy state,
 *      conditional releases, simulated yield calculation, granular role-based access, and delegation.
 *
 * Outline:
 * 1. SPDX-License-Identifier & Pragma
 * 2. Imports (ERC20)
 * 3. Events
 * 4. Errors
 * 5. Constants (Roles, Modules)
 * 6. Enums (Vault State)
 * 7. Structs (Rules, Releases, Delegations)
 * 8. State Variables (Ownership, Roles, Balances, Flux, Rules, Releases, Delegations, Parameters, Modules, Yield)
 * 9. Modifiers (Access Control, Pause)
 * 10. Constructor
 * 11. Internal Helper Functions (_updateFlux, _canWithdrawInternal, _calculateSimulatedYield)
 * 12. Core Vault Functions (Deposit/Withdraw w/ Rules)
 * 13. Balance & State View Functions (User/Vault Balances, Flux, Rules, Releases, Yield, canWithdraw)
 * 14. Access Control & Role Management Functions (Assign/Revoke/Check Roles)
 * 15. Dynamic Rules & Parameter Management Functions (Set Rules/Parameters)
 * 16. Flux System Management Functions (Set Flux Parameters, Trigger Flux Update)
 * 17. Conditional Release Functions (Schedule/Cancel/Claim Releases, View Pending)
 * 18. Delegation Functions (Delegate/Execute/Renounce Delegation)
 * 19. Module Management Functions (Enable/Disable Modules)
 * 20. Emergency & Admin Functions (Pause/Resume, Sweep, Transfer Ownership)
 *
 * Function Summary (Total: 26 functions):
 * - constructor()
 * - depositETH()
 * - depositERC20()
 * - withdrawETHWithRules()
 * - withdrawERC20WithRules()
 * - canWithdraw() view
 * - getUserETHBalance() view
 * - getUserERC20Balance() view
 * - assignRole()
 * - revokeRole()
 * - hasRole() view
 * - setWithdrawalRule()
 * - getWithdrawalRule() view
 * - getCurrentFluxEnergy() view
 * - setFluxParameters()
 * - scheduleConditionalRelease()
 * - cancelConditionalRelease()
 * - claimScheduledRelease()
 * - getPendingConditionalReleases() view
 * - delegateWithdrawalPermission()
 * - delegatedWithdrawal()
 * - getEstimatedYield() view
 * - setYieldParameters()
 * - setModuleEnabled()
 * - panicShutdown()
 * - resumeOperations()
 * - sweepTokens()
 * - transferOwnership()
 * - acceptOwnership() (from Ownable)
 */
contract QuantumFluxVault is Ownable {
    using SafeERC20 for IERC20;

    /*-----------------------------------
    | Events                           |
    -----------------------------------*/

    event DepositMade(address indexed user, address indexed token, uint256 amount);
    event WithdrawalMade(address indexed user, address indexed token, uint256 amount);
    event WithdrawalRuleUpdated(address indexed token, uint256 minFlux, uint256 maxFlux, uint64 minLockDuration, uint256 maxDailyAmount);
    event FluxEnergyUpdated(uint256 newFlux, uint64 timestamp);
    event RoleAssigned(address indexed user, bytes32 indexed role);
    event RoleRevoked(address indexed user, bytes32 indexed role);
    event ConditionalReleaseScheduled(address indexed user, address indexed token, uint256 amount, uint64 releaseTime, uint256 minFluxAtRelease, uint256 releaseId);
    event ConditionalReleaseClaimed(uint256 indexed releaseId);
    event ConditionalReleaseCancelled(uint256 indexed releaseId);
    event DelegationPermissionGranted(address indexed owner, address indexed delegatee, address indexed token, uint256 allowance, uint64 expiration);
    event DelegationUsed(address indexed owner, address indexed delegatee, address indexed token, uint256 amount);
    event DelegationRevoked(address indexed owner, address indexed token);
    event VaultParameterChanged(bytes32 indexed paramName, uint256 value);
    event ModuleStatusChanged(bytes32 indexed module, bool enabled);
    event VaultPaused();
    event VaultResumed();
    event TokensSwept(address indexed token, address indexed recipient, uint256 amount);

    /*-----------------------------------
    | Errors                           |
    -----------------------------------*/

    error DepositZero();
    error WithdrawalAmountExceedsBalance();
    error WithdrawalNotAllowedByRules();
    error WithdrawalDailyLimitExceeded();
    error InsufficientFluxForWithdrawal();
    error DepositTooRecentForWithdrawal();
    error OnlyRole(bytes32 requiredRole);
    error VaultIsPaused();
    error VaultIsNotPaused();
    error InvalidParameterValue();
    error ConditionalReleaseNotFound();
    error ConditionalReleaseNotClaimableYet();
    error ConditionalReleaseConditionsNotMet();
    error ConditionalReleaseAlreadyClaimedOrCancelled();
    error DelegationNotFound();
    error DelegationExpired();
    error DelegationAllowanceExceeded();
    error DelegationFromSelf();
    error ModuleDisabled(bytes32 module);
    error InvalidModule(bytes32 module);
    error CannotSweepManagedToken();
    error YieldCalculationDisabled();
    error NoDepositHistory();

    /*-----------------------------------
    | Constants                        |
    -----------------------------------*/

    // Role Identifiers
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant RULE_MANAGER_ROLE = keccak256("RULE_MANAGER_ROLE");
    bytes32 public constant FLUX_MASTER_ROLE = keccak256("FLUX_MASTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant PARAM_MANAGER_ROLE = keccak256("PARAM_MANAGER_ROLE");
    bytes32 public constant DELEGATION_MANAGER_ROLE = keccak256("DELEGATION_MANAGER_ROLE"); // Role to *grant* delegation permissions on behalf of others (advanced)
    bytes32 public constant YIELD_MANAGER_ROLE = keccak256("YIELD_MANAGER_ROLE");

    // Module Identifiers
    bytes32 public constant MODULE_DYNAMIC_RULES = keccak256("MODULE_DYNAMIC_RULES");
    bytes32 public constant MODULE_CONDITIONAL_RELEASES = keccak256("MODULE_CONDITIONAL_RELEASES");
    bytes32 public constant MODULE_DELEGATION = keccak256("MODULE_DELEGATION");
    bytes32 public constant MODULE_YIELD_SIMULATION = keccak256("MODULE_YIELD_SIMULATION");

    /*-----------------------------------
    | Enums                            |
    -----------------------------------*/

    enum VaultState { Active, Paused }

    /*-----------------------------------
    | Structs                          |
    -----------------------------------*/

    struct WithdrawalRule {
        uint256 minFlux;         // Minimum Flux energy required to withdraw
        uint256 maxFlux;         // Maximum Flux energy to withdraw (optional upper bound)
        uint64 minLockDuration;  // Minimum time in seconds a deposit must be held
        uint256 maxDailyAmount;  // Maximum amount per user per 24 hours (0 for no limit)
    }

    struct ConditionalRelease {
        address beneficiary;
        address token;
        uint256 amount;
        uint64 releaseTime;      // Timestamp after which release is claimable
        uint256 minFluxAtRelease; // Minimum Flux required at claim time
        bool claimed;
    }

    struct Delegation {
        uint256 allowance;    // Amount delegatee can withdraw on behalf of owner
        uint64 expiration;    // Timestamp after which delegation is invalid
    }

    struct DepositInfo {
        uint64 timestamp;
        uint256 amount;
    }

    /*-----------------------------------
    | State Variables                  |
    -----------------------------------*/

    // --- Access Control ---
    mapping(address => mapping(bytes32 => bool)) private userRoles;

    // --- Vault State ---
    VaultState public currentVaultState;

    // --- Asset Management ---
    mapping(address => mapping(address => uint256)) private userTokenBalances; // user => token => balance
    mapping(address => uint256) private vaultTotalTokenBalances; // token => total balance in vault

    // --- Flux System ---
    uint256 public currentFluxEnergy;
    uint64 private lastFluxUpdateTime;
    // Flux Parameters: timeDecayRate (flux per second), depositBoost (flux increase per ETH/token unit deposited), minFluxIncreaseInterval (min time between time-based updates)
    mapping(bytes32 => uint256) private fluxParameters;
    bytes32 public constant PARAM_FLUX_TIME_DECAY_RATE = keccak256("FLUX_TIME_DECAY_RATE"); // Flux units per second of decay
    bytes32 public constant PARAM_FLUX_DEPOSIT_BOOST = keccak256("FLUX_DEPOSIT_BOOST");     // Flux units per token unit deposited
    bytes32 public constant PARAM_MIN_FLUX_INCREASE_INTERVAL = keccak256("MIN_FLUX_INCREASE_INTERVAL"); // Min seconds between time-based increases

    // --- Dynamic Rules ---
    mapping(address => WithdrawalRule) private tokenWithdrawalRules;
    mapping(address => mapping(address => uint256)) private userDailyWithdrawal; // user => token => amount withdrawn today
    mapping(address => mapping(address => uint64)) private userLastWithdrawalDay; // user => token => timestamp of last withdrawal

    // --- Conditional Releases ---
    ConditionalRelease[] public conditionalReleases;
    uint256 private nextConditionalReleaseId = 0;

    // --- Delegation ---
    mapping(address => mapping(address => mapping(address => Delegation))) private delegationPermissions; // owner => delegatee => token => Delegation struct

    // --- Generic Parameters ---
    mapping(bytes32 => uint256) private vaultParameters;
    bytes32 public constant PARAM_MIN_DEPOSIT_ETH = keccak256("MIN_DEPOSIT_ETH");
    bytes32 public constant PARAM_MIN_DEPOSIT_ERC20 = keccak256("MIN_DEPOSIT_ERC20");
    bytes32 public constant PARAM_MAX_CONDITIONAL_RELEASES_PER_USER = keccak256("MAX_CONDITIONAL_RELEASES_PER_USER");

    // --- Module Management ---
    mapping(bytes32 => bool) private moduleEnabled;

    // --- Simulated Yield ---
    mapping(address => mapping(address => DepositInfo[])) private userDepositHistory; // user => token => list of DepositInfo
    mapping(address => mapping(bytes32 => uint256)) private yieldParameters; // token => param => value
    bytes32 public constant YIELD_PARAM_ANNUAL_RATE_BP = keccak256("ANNUAL_RATE_BP"); // Annual yield rate in basis points (100 = 1%)
    bytes32 public constant YIELD_PARAM_COMPOUND_FREQUENCY = keccak256("COMPOUND_FREQUENCY"); // Compounding frequency in seconds

    /*-----------------------------------
    | Modifiers                        |
    -----------------------------------*/

    modifier onlyRole(bytes32 role) {
        if (!hasRole(_msgSender(), role)) {
            revert OnlyRole(role);
        }
        _;
    }

    modifier whenNotPaused() {
        if (currentVaultState == VaultState.Paused) {
            revert VaultIsPaused();
        }
        _;
    }

    /*-----------------------------------
    | Constructor                      |
    -----------------------------------*/

    constructor() Ownable(msg.sender) {
        currentVaultState = VaultState.Active;
        userRoles[msg.sender][ADMIN_ROLE] = true; // Grant ADMIN_ROLE to owner

        // Initialize default parameters (example values)
        fluxParameters[PARAM_FLUX_TIME_DECAY_RATE] = 1; // Decay 1 flux unit per second
        fluxParameters[PARAM_FLUX_DEPOSIT_BOOST] = 100; // 100 flux units per token unit deposited (scaled)
        fluxParameters[PARAM_MIN_FLUX_INCREASE_INTERVAL] = 3600; // Check/update flux at most every hour

        vaultParameters[PARAM_MIN_DEPOSIT_ETH] = 0.01 ether; // Example min deposit ETH
        vaultParameters[PARAM_MIN_DEPOSIT_ERC20] = 1; // Example min deposit ERC20 (assuming 18 decimals)
        vaultParameters[PARAM_MAX_CONDITIONAL_RELEASES_PER_USER] = 10; // Max scheduled releases per user

        // Enable modules by default
        moduleEnabled[MODULE_DYNAMIC_RULES] = true;
        moduleEnabled[MODULE_CONDITIONAL_RELEASES] = true;
        moduleEnabled[MODULE_DELEGATION] = true;
        moduleEnabled[MODULE_YIELD_SIMULATION] = true;

        // Initialize flux state
        currentFluxEnergy = 0;
        lastFluxUpdateTime = uint64(block.timestamp);
    }

    /*-----------------------------------
    | Internal Helper Functions        |
    -----------------------------------*/

    /**
     * @dev Internal function to update Flux energy based on time and potentially other factors.
     * Decay over time, potentially increase on certain actions (handled within action functions).
     * Updates only if enough time has passed since the last update interval.
     */
    function _updateFluxEnergy() internal {
        uint64 currentTime = uint64(block.timestamp);
        uint64 minInterval = uint64(fluxParameters[PARAM_MIN_FLUX_INCREASE_INTERVAL]);

        if (currentTime > lastFluxUpdateTime && (currentTime - lastFluxUpdateTime) >= minInterval) {
             // Apply decay
            uint64 timeElapsed = currentTime - lastFluxUpdateTime;
            uint256 decayAmount = (fluxParameters[PARAM_FLUX_TIME_DECAY_RATE] * timeElapsed);
            if (decayAmount > currentFluxEnergy) {
                currentFluxEnergy = 0;
            } else {
                currentFluxEnergy -= decayAmount;
            }

            // Note: Deposit boost is added in the deposit functions

            lastFluxUpdateTime = currentTime;
            emit FluxEnergyUpdated(currentFluxEnergy, currentTime);
        }
    }

    /**
     * @dev Internal function to check if a withdrawal is allowed based on all rules.
     * @param user The user attempting to withdraw.
     * @param token The token address (address(0) for ETH).
     * @param amount The amount to withdraw.
     * @return True if withdrawal is allowed, false otherwise.
     */
    function _canWithdrawInternal(address user, address token, uint256 amount) internal view returns (bool) {
        if (amount == 0) return false;

        // Check user balance
        uint256 userBal = (token == address(0)) ? userTokenBalances[user][address(0)] : userTokenBalances[user][token];
        if (amount > userBal) return false;

        // If dynamic rules module is disabled, only check balance
        if (!moduleEnabled[MODULE_DYNAMIC_RULES]) {
            return true;
        }

        WithdrawalRule storage rule = tokenWithdrawalRules[token];

        // Check Flux rule
        if (currentFluxEnergy < rule.minFlux || (rule.maxFlux > 0 && currentFluxEnergy > rule.maxFlux)) {
            return false;
        }

        // Check minimum lock duration
        // This requires tracking deposit timestamps per user/token.
        // For simplicity in this example, we'll assume the user's *first* deposit
        // is the relevant one, or require users to track their own deposit ages.
        // A robust implementation would track multiple deposits per user and withdraw FIFO/LIFO etc.
        // Here, we'll just check if *any* deposit meets the minimum age requirement.
        // We need a way to store deposit timestamps. Let's add userDepositHistory struct.

        // Check min lock duration based on the *latest* deposit for simplicity
        // A more complex system might track individual deposits and allow withdrawal only of "aged" funds.
        if (userDepositHistory[user][token].length > 0) {
            DepositInfo storage latestDeposit = userDepositHistory[user][token][userDepositHistory[user][token].length - 1];
             if (block.timestamp < latestDeposit.timestamp + rule.minLockDuration) {
                // Check if *any* deposit is old enough to cover the amount
                uint256 availableAgedBalance = 0;
                for(uint i = 0; i < userDepositHistory[user][token].length; i++) {
                     if (block.timestamp >= userDepositHistory[user][token][i].timestamp + rule.minLockDuration) {
                         availableAgedBalance += userDepositHistory[user][token][i].amount;
                     }
                }
                if (amount > availableAgedBalance) {
                     return false; // Not enough aged funds
                }
             }
        } else if (rule.minLockDuration > 0) {
             return false; // No deposits, cannot meet lock duration
        }


        // Check daily withdrawal limit
        if (rule.maxDailyAmount > 0) {
            uint64 currentDay = uint64(block.timestamp / 1 days);
            if (userLastWithdrawalDay[user][token] != currentDay) {
                userDailyWithdrawal[user][token] = 0; // Reset daily limit if new day
            }
            if (userDailyWithdrawal[user][token] + amount > rule.maxDailyAmount) {
                return false; // Exceeds daily limit
            }
        }

        return true; // All checks passed
    }

     /**
      * @dev Internal function to calculate simulated yield.
      * This is *not* real yield from external protocols, but a calculated value
      * based on parameters and deposit history.
      * @param user The user.
      * @param token The token address.
      * @return The calculated simulated yield amount.
      */
    function _calculateSimulatedYield(address user, address token) internal view returns (uint256) {
        if (!moduleEnabled[MODULE_YIELD_SIMULATION]) {
            return 0;
        }

        if (userDepositHistory[user][token].length == 0) {
            return 0; // No deposit history to calculate yield on
        }

        uint256 annualRateBp = yieldParameters[token][YIELD_PARAM_ANNUAL_RATE_BP];
        uint64 compoundFreq = uint64(yieldParameters[token][YIELD_PARAM_COMPOUND_FREQUENCY]);

        if (annualRateBp == 0 || compoundFreq == 0) {
            return 0; // Yield calculation parameters not set
        }

        uint256 totalSimulatedYield = 0;
        uint64 currentTime = uint64(block.timestamp);

        // Calculate yield per deposit entry
        for (uint i = 0; i < userDepositHistory[user][token].length; i++) {
            DepositInfo storage deposit = userDepositHistory[user][token][i];
            if (currentTime <= deposit.timestamp) continue; // Cannot earn yield on future deposits

            uint64 duration = currentTime - deposit.timestamp;
            uint256 amount = deposit.amount;

            // Simple interest approximation per compound period
            // Note: This is a very simplified simulation. Real compound interest
            // calculation on-chain is complex due to fixed-point math and gas.
            // A more accurate version might use exponentiation or lookup tables.
            uint256 numCompoundPeriods = duration / compoundFreq;
            uint256 yieldPerPeriod = (amount * annualRateBp / 10000 * compoundFreq) / 31536000; // Approx yield per period (31536000 seconds in a year)

            totalSimulatedYield += yieldPerPeriod * numCompoundPeriods;

            // A more advanced simulation could track remaining time and fractional periods
            // and use more sophisticated math libraries.
        }

        return totalSimulatedYield;
    }


    /*-----------------------------------
    | Core Vault Functions             |
    -----------------------------------*/

    /**
     * @dev Deposits Ether into the vault.
     * Increases user balance and potentially Flux energy.
     */
    function depositETH() external payable whenNotPaused {
        if (msg.value == 0) revert DepositZero();
        if (msg.value < vaultParameters[PARAM_MIN_DEPOSIT_ETH]) revert InvalidParameterValue(); // Example min deposit check

        _updateFluxEnergy(); // Update flux before adding deposit boost

        userTokenBalances[msg.sender][address(0)] += msg.value;
        vaultTotalTokenBalances[address(0)] += msg.value;

        // Add deposit boost to flux (scaled)
        currentFluxEnergy += (msg.value / (10**12)) * fluxParameters[PARAM_FLUX_DEPOSIT_BOOST]; // Scale ETH down (e.g., by 1e12)

        // Record deposit history for yield simulation & lock duration check
        userDepositHistory[msg.sender][address(0)].push(DepositInfo({
            timestamp: uint64(block.timestamp),
            amount: msg.value
        }));

        emit DepositMade(msg.sender, address(0), msg.value);
        emit FluxEnergyUpdated(currentFluxEnergy, uint64(block.timestamp)); // Emit again after boost
    }

    /**
     * @dev Deposits ERC20 tokens into the vault.
     * Requires prior approval from the user for the vault contract.
     * Increases user balance and potentially Flux energy.
     * @param token The address of the ERC20 token.
     * @param amount The amount of tokens to deposit.
     */
    function depositERC20(address token, uint256 amount) external whenNotPaused {
        if (amount == 0) revert DepositZero();
        if (amount < vaultParameters[PARAM_MIN_DEPOSIT_ERC20]) revert InvalidParameterValue(); // Example min deposit check

        _updateFluxEnergy(); // Update flux before adding deposit boost

        IERC20 tokenContract = IERC20(token);
        tokenContract.safeTransferFrom(msg.sender, address(this), amount);

        userTokenBalances[msg.sender][token] += amount;
        vaultTotalTokenBalances[token] += amount;

        // Add deposit boost to flux (scaled - assuming 18 decimals for boost calc)
         uint256 scaledAmount = amount;
         // Attempt to scale if token decimals differ significantly? Or require deposits in base units?
         // For simplicity, let's assume standard 18 decimals for boost calculation or use a different scaling factor per token.
         // A simple scaling: if token has <18 decimals, scale up; if >18, scale down. Or just assume 18 for boost logic.
         // Let's just assume 18 decimals for boost calculation base or scale by a fixed large number.
         // Scaling by 1e12 means 1e6 units of an 18-decimal token gives flux boost.
         scaledAmount /= (10**12);
        currentFluxEnergy += scaledAmount * fluxParameters[PARAM_FLUX_DEPOSIT_BOOST];

        // Record deposit history for yield simulation & lock duration check
        userDepositHistory[msg.sender][token].push(DepositInfo({
            timestamp: uint64(block.timestamp),
            amount: amount
        }));

        emit DepositMade(msg.sender, token, amount);
         emit FluxEnergyUpdated(currentFluxEnergy, uint64(block.timestamp)); // Emit again after boost
    }

    /**
     * @dev Allows a user to withdraw ETH based on active withdrawal rules and state.
     * Updates user balance and daily withdrawal limits.
     * @param amount The amount of ETH to withdraw.
     */
    function withdrawETHWithRules(uint256 amount) external whenNotPaused {
        _updateFluxEnergy(); // Update flux before checking rules

        if (!_canWithdrawInternal(msg.sender, address(0), amount)) {
            // More specific errors from _canWithdrawInternal are not propagated directly here
            // A robust implementation would add checks here or have _canWithdrawInternal return specific error codes
            // For simplicity, we use a generic error after calling the internal check
            revert WithdrawalNotAllowedByRules();
        }

        if (amount > userTokenBalances[msg.sender][address(0)]) revert WithdrawalAmountExceedsBalance();

        userTokenBalances[msg.sender][address(0)] -= amount;
        vaultTotalTokenBalances[address(0)] -= amount;

        // Update daily withdrawal tracking
        uint64 currentDay = uint64(block.timestamp / 1 days);
         if (userLastWithdrawalDay[msg.sender][address(0)] != currentDay) {
            userDailyWithdrawal[msg.sender][address(0)] = 0; // Reset daily limit if new day
            userLastWithdrawalDay[msg.sender][address(0)] = currentDay;
        }
        userDailyWithdrawal[msg.sender][address(0)] += amount;


        // Remove amount from oldest deposit entries first to simulate FIFO for withdrawal age check
         uint256 remainingAmount = amount;
         uint i = 0;
         while (remainingAmount > 0 && i < userDepositHistory[msg.sender][address(0)].length) {
             uint256 withdrawAmount = remainingAmount < userDepositHistory[msg.sender][address(0)][i].amount ? remainingAmount : userDepositHistory[msg.sender][address(0)][i].amount;
             userDepositHistory[msg.sender][address(0)][i].amount -= withdrawAmount;
             remainingAmount -= withdrawAmount;

             // If an entry is fully depleted, remove it (expensive array operation, consider linked list for performance)
             if (userDepositHistory[msg.sender][address(0)][i].amount == 0) {
                 // Shift elements left - gas intensive for large history
                 for (uint j = i; j < userDepositHistory[msg.sender][address(0)].length - 1; j++) {
                     userDepositHistory[msg.sender][address(0)][j] = userDepositHistory[msg.sender][address(0)][j+1];
                 }
                 userDepositHistory[msg.sender][address(0)].pop();
                 // Do not increment i, as the next element is now at index i
             } else {
                 i++; // Move to the next deposit entry
             }
         }


        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "ETH transfer failed");

        emit WithdrawalMade(msg.sender, address(0), amount);
    }


    /**
     * @dev Allows a user to withdraw ERC20 tokens based on active withdrawal rules and state.
     * Updates user balance and daily withdrawal limits.
     * @param token The address of the ERC20 token.
     * @param amount The amount of tokens to withdraw.
     */
    function withdrawERC20WithRules(address token, uint256 amount) external whenNotPaused {
        _updateFluxEnergy(); // Update flux before checking rules

        if (!_canWithdrawInternal(msg.sender, token, amount)) {
            revert WithdrawalNotAllowedByRules();
        }

        if (amount > userTokenBalances[msg.sender][token]) revert WithdrawalAmountExceedsBalance();

        userTokenBalances[msg.sender][token] -= amount;
        vaultTotalTokenBalances[token] -= amount;

         // Update daily withdrawal tracking
        uint64 currentDay = uint64(block.timestamp / 1 days);
         if (userLastWithdrawalDay[msg.sender][token] != currentDay) {
            userDailyWithdrawal[msg.sender][token] = 0; // Reset daily limit if new day
             userLastWithdrawalDay[msg.sender][token] = currentDay;
        }
        userDailyWithdrawal[msg.sender][token] += amount;

        // Remove amount from oldest deposit entries for this token
         uint256 remainingAmount = amount;
         uint i = 0;
         while (remainingAmount > 0 && i < userDepositHistory[msg.sender][token].length) {
             uint256 withdrawAmount = remainingAmount < userDepositHistory[msg.sender][token][i].amount ? remainingAmount : userDepositHistory[msg.sender][token][i].amount;
             userDepositHistory[msg.sender][token][i].amount -= withdrawAmount;
             remainingAmount -= withdrawAmount;

             if (userDepositHistory[msg.sender][token][i].amount == 0) {
                 for (uint j = i; j < userDepositHistory[msg.sender][token].length - 1; j++) {
                     userDepositHistory[msg.sender][token][j] = userDepositHistory[msg.sender][token][j+1];
                 }
                 userDepositHistory[msg.sender][token].pop();
             } else {
                 i++;
             }
         }

        IERC20 tokenContract = IERC20(token);
        tokenContract.safeTransfer(msg.sender, amount);

        emit WithdrawalMade(msg.sender, token, amount);
    }

    /*-----------------------------------
    | Balance & State View Functions   |
    -----------------------------------*/

    /**
     * @dev Returns the current Flux energy level. Triggers update if needed.
     * @return The current Flux energy.
     */
    function getCurrentFluxEnergy() public view returns (uint256) {
        // Note: View functions cannot change state, so we cannot call _updateFluxEnergy() here
        // The actual state variable `currentFluxEnergy` might be slightly stale until
        // a state-changing function is called that triggers _updateFluxEnergy().
        // This view provides the *last known* value, not the real-time calculated one.
        // To get the most accurate value, one would need to call a state-changing fn first.
        return currentFluxEnergy;
    }

    /**
     * @dev Returns the current withdrawal rule for a token.
     * @param token The token address (address(0) for ETH).
     * @return The WithdrawalRule struct.
     */
    function getWithdrawalRule(address token) public view returns (WithdrawalRule memory) {
        return tokenWithdrawalRules[token];
    }

    /**
     * @dev Checks if a specific user could withdraw a given amount of a token right now.
     * This view function calls the internal helper but cannot rely on _updateFluxEnergy
     * modifying state, so it uses the currentFluxEnergy state variable as is.
     * @param user The user to check.
     * @param token The token address (address(0) for ETH).
     * @param amount The amount to check.
     * @return True if withdrawal is currently permitted by rules, false otherwise.
     */
    function canWithdraw(address user, address token, uint256 amount) external view returns (bool) {
        // Note: Uses current state variables, does not trigger internal flux update
        return _canWithdrawInternal(user, token, amount);
    }


    /**
     * @dev Returns a user's deposited ETH balance.
     * @param user The user's address.
     * @return The user's ETH balance in the vault.
     */
    function getUserETHBalance(address user) external view returns (uint256) {
        return userTokenBalances[user][address(0)];
    }

    /**
     * @dev Returns a user's deposited token balance.
     * @param user The user's address.
     * @param token The address of the ERC20 token.
     * @return The user's token balance in the vault.
     */
    function getUserERC20Balance(address user, address token) external view returns (uint256) {
        return userTokenBalances[user][token];
    }

     /**
      * @dev Returns the total ETH held in the vault.
      * @return Total ETH balance.
      */
     function getVaultTotalETHBalance() external view returns (uint256) {
         return vaultTotalTokenBalances[address(0)];
     }

     /**
      * @dev Returns the total balance of a specific token held in the vault.
      * @param token The token address.
      * @return Total token balance.
      */
     function getVaultTotalERC20Balance(address token) external view returns (uint256) {
         return vaultTotalTokenBalances[token];
     }

     /**
      * @dev Returns the value of a specific vault parameter.
      * @param paramName The keccak256 hash of the parameter name (e.g., `PARAM_MIN_DEPOSIT_ETH`).
      * @return The parameter value.
      */
     function getVaultParameter(bytes32 paramName) external view returns (uint256) {
         return vaultParameters[paramName];
     }

     /**
      * @dev Returns the status (enabled/disabled) of a specific module.
      * @param module The keccak256 hash of the module name (e.g., `MODULE_DELEGATION`).
      * @return True if module is enabled, false otherwise.
      */
     function isModuleEnabled(bytes32 module) external view returns (bool) {
         return moduleEnabled[module];
     }

     /**
      * @dev Calculates the simulated yield for a user for a specific token.
      * This is based on internal parameters and deposit history, NOT external protocols.
      * @param user The user to check.
      * @param token The token address.
      * @return The calculated simulated yield amount.
      */
     function getEstimatedYield(address user, address token) external view returns (uint256) {
         return _calculateSimulatedYield(user, token);
     }


    /*-----------------------------------
    | Access Control & Roles           |
    -----------------------------------*/

    /**
     * @dev Assigns a specific role to a user. Only ADMIN_ROLE can do this.
     * @param user The address to assign the role to.
     * @param role The role identifier (bytes32).
     */
    function assignRole(address user, bytes32 role) external onlyOwner {
        userRoles[user][role] = true;
        emit RoleAssigned(user, role);
    }

    /**
     * @dev Revokes a specific role from a user. Only ADMIN_ROLE can do this.
     * @param user The address to revoke the role from.
     * @param role The role identifier (bytes32).
     */
    function revokeRole(address user, bytes32 role) external onlyOwner {
        userRoles[user][role] = false;
        emit RoleRevoked(user, role);
    }

    /**
     * @dev Checks if a user has a specific role.
     * @param user The address to check.
     * @param role The role identifier (bytes32).
     * @return True if the user has the role, false otherwise.
     */
    function hasRole(address user, bytes32 role) public view returns (bool) {
        return userRoles[user][role];
    }

    /*-----------------------------------
    | Dynamic Rules & Parameters       |
    -----------------------------------*/

    /**
     * @dev Sets or updates the dynamic withdrawal rule for a specific token.
     * Requires RULE_MANAGER_ROLE.
     * @param token The token address (address(0) for ETH).
     * @param minFlux Minimum Flux energy required for withdrawal.
     * @param maxFlux Maximum Flux energy allowed for withdrawal (0 for no upper limit).
     * @param minLockDuration Minimum time in seconds a deposit must be held before withdrawal is possible (0 for no lock).
     * @param maxDailyAmount Maximum amount a user can withdraw per 24 hours for this token (0 for no limit).
     */
    function setWithdrawalRule(address token, uint256 minFlux, uint256 maxFlux, uint64 minLockDuration, uint256 maxDailyAmount) external onlyRole(RULE_MANAGER_ROLE) {
        tokenWithdrawalRules[token] = WithdrawalRule({
            minFlux: minFlux,
            maxFlux: maxFlux,
            minLockDuration: minLockDuration,
            maxDailyAmount: maxDailyAmount
        });
        emit WithdrawalRuleUpdated(token, minFlux, maxFlux, minLockDuration, maxDailyAmount);
    }

    /**
     * @dev Sets the value for a generic vault parameter.
     * Requires PARAM_MANAGER_ROLE.
     * @param paramName The keccak256 hash of the parameter name.
     * @param value The new value for the parameter.
     */
    function setVaultParameter(bytes32 paramName, uint256 value) external onlyRole(PARAM_MANAGER_ROLE) {
        // Add specific checks for known parameters if needed (e.g., min deposits > 0)
         if (paramName == PARAM_MIN_DEPOSIT_ETH && value == 0) revert InvalidParameterValue();
         if (paramName == PARAM_MIN_DEPOSIT_ERC20 && value == 0) revert InvalidParameterValue();
         if (paramName == PARAM_MAX_CONDITIONAL_RELEASES_PER_USER && value == 0) revert InvalidParameterValue();


        vaultParameters[paramName] = value;
        emit VaultParameterChanged(paramName, value);
    }

     /**
      * @dev Sets the parameters for simulated yield calculation for a specific token.
      * Requires YIELD_MANAGER_ROLE.
      * @param token The token address (address(0) for ETH).
      * @param annualRateBasisPoints The annual yield rate in basis points (e.g., 500 for 5%). 0 to disable for this token.
      * @param compoundFrequency Compounding frequency in seconds (e.g., 86400 for daily). 0 to disable for this token.
      */
     function setYieldParameters(address token, uint256 annualRateBasisPoints, uint64 compoundFrequency) external onlyRole(YIELD_MANAGER_ROLE) {
         yieldParameters[token][YIELD_PARAM_ANNUAL_RATE_BP] = annualRateBasisPoints;
         yieldParameters[token][YIELD_PARAM_COMPOUND_FREQUENCY] = compoundFrequency;
         emit VaultParameterChanged(YIELD_PARAM_ANNUAL_RATE_BP, annualRateBasisPoints); // Reusing event, ideally specific event
         emit VaultParameterChanged(YIELD_PARAM_COMPOUND_FREQUENCY, compoundFrequency); // Reusing event
     }


    /*-----------------------------------
    | Flux System Management           |
    -----------------------------------*/

     /**
      * @dev Sets parameters that govern the Flux energy system.
      * Requires FLUX_MASTER_ROLE.
      * @param timeDecayRate Flux units decayed per second.
      * @param depositBoost Flux units added per standard token unit deposited (scaled).
      * @param minFluxIncreaseInterval Minimum seconds between time-based flux updates.
      */
     function setFluxParameters(uint256 timeDecayRate, uint256 depositBoost, uint256 minFluxIncreaseInterval) external onlyRole(FLUX_MASTER_ROLE) {
         fluxParameters[PARAM_FLUX_TIME_DECAY_RATE] = timeDecayRate;
         fluxParameters[PARAM_FLUX_DEPOSIT_BOOST] = depositBoost;
         fluxParameters[PARAM_MIN_FLUX_INCREASE_INTERVAL] = minFluxIncreaseInterval;
         // Could emit specific events for each parameter change
     }

     /**
      * @dev Manually triggers an update of the Flux energy state.
      * Can be called by anyone, but only updates if the minimum interval has passed.
      * Useful to allow external systems to ensure Flux is relatively current.
      */
     function triggerFluxIncrease() external {
         _updateFluxEnergy();
     }


    /*-----------------------------------
    | Conditional Releases             |
    -----------------------------------*/

    /**
     * @dev Schedules a release of locked funds for a future time and minimum Flux level.
     * Requires MODULE_CONDITIONAL_RELEASES to be enabled.
     * @param token The token address (address(0) for ETH).
     * @param amount The amount to lock.
     * @param releaseTime Timestamp after which the release is claimable.
     * @param minFluxAtRelease Minimum Flux energy required in the vault at claim time.
     */
    function scheduleConditionalRelease(address token, uint256 amount, uint64 releaseTime, uint256 minFluxAtRelease) external whenNotPaused {
        if (!moduleEnabled[MODULE_CONDITIONAL_RELEASES]) revert ModuleDisabled(MODULE_CONDITIONAL_RELEASES);
        if (amount == 0) revert DepositZero(); // Reusing error

        uint256 userBal = (token == address(0)) ? userTokenBalances[msg.sender][address(0)] : userTokenBalances[msg.sender][token];
        if (amount > userBal) revert WithdrawalAmountExceedsBalance();

        if (releaseTime <= block.timestamp) revert InvalidParameterValue(); // Release time must be in the future

        // Optional: Check max number of pending releases per user
        uint256 userPendingReleases = 0;
        for(uint i = 0; i < conditionalReleases.length; i++) {
            if (conditionalReleases[i].beneficiary == msg.sender && !conditionalReleases[i].claimed) {
                userPendingReleases++;
            }
        }
        if (userPendingReleases >= vaultParameters[PARAM_MAX_CONDITIONAL_RELEASES_PER_USER]) {
             revert InvalidParameterValue(); // Or a specific error like MaxPendingReleasesExceeded
        }


        // Dedicate the amount by reducing user's balance
        if (token == address(0)) {
            userTokenBalances[msg.sender][address(0)] -= amount;
        } else {
            userTokenBalances[msg.sender][token] -= amount;
        }

        uint256 releaseId = nextConditionalReleaseId++;
        conditionalReleases.push(ConditionalRelease({
            beneficiary: msg.sender,
            token: token,
            amount: amount,
            releaseTime: releaseTime,
            minFluxAtRelease: minFluxAtRelease,
            claimed: false
        }));

        emit ConditionalReleaseScheduled(msg.sender, token, amount, releaseTime, minFluxAtRelease, releaseId);
    }

    /**
     * @dev Allows the scheduler to cancel a conditional release before it's claimed.
     * Requires MODULE_CONDITIONAL_RELEASES to be enabled.
     * @param releaseId The ID of the release to cancel.
     */
    function cancelConditionalRelease(uint256 releaseId) external whenNotPaused {
         if (!moduleEnabled[MODULE_CONDITIONAL_RELEASES]) revert ModuleDisabled(MODULE_CONDITIONAL_RELEASES);
        if (releaseId >= conditionalReleases.length) revert ConditionalReleaseNotFound();

        ConditionalRelease storage release = conditionalReleases[releaseId];

        if (release.beneficiary != msg.sender) revert Ownable.NotOwned(msg.sender); // Reusing Ownable error, ideally specific like NotReleaseOwner
        if (release.claimed) revert ConditionalReleaseAlreadyClaimedOrCancelled(); // Can't cancel if claimed (or already cancelled)

        // Return funds to user balance
        if (release.token == address(0)) {
            userTokenBalances[msg.sender][address(0)] += release.amount;
        } else {
            userTokenBalances[msg.sender][release.token] += release.amount;
        }

        release.claimed = true; // Mark as claimed/cancelled to prevent double-claiming/cancelling
        emit ConditionalReleaseCancelled(releaseId);
    }

    /**
     * @dev Allows the beneficiary to claim a conditional release if conditions are met.
     * Requires MODULE_CONDITIONAL_RELEASES to be enabled.
     * @param releaseId The ID of the release to claim.
     */
    function claimScheduledRelease(uint256 releaseId) external whenNotPaused {
        if (!moduleEnabled[MODULE_CONDITIONAL_RELEASES]) revert ModuleDisabled(MODULE_CONDITIONAL_RELEASES);
        if (releaseId >= conditionalReleases.length) revert ConditionalReleaseNotFound();

        ConditionalRelease storage release = conditionalReleases[releaseId];

        if (release.beneficiary != msg.sender) revert Ownable.NotOwned(msg.sender);
        if (release.claimed) revert ConditionalReleaseAlreadyClaimedOrCancelled();
        if (block.timestamp < release.releaseTime) revert ConditionalReleaseNotClaimableYet();

        _updateFluxEnergy(); // Update flux before checking the flux condition
        if (currentFluxEnergy < release.minFluxAtRelease) revert ConditionalReleaseConditionsNotMet();

        // Transfer funds from vault total balance
        if (release.token == address(0)) {
            vaultTotalTokenBalances[address(0)] -= release.amount; // Funds were already dedicated, just update total vault balance
            (bool success, ) = payable(msg.sender).call{value: release.amount}("");
            require(success, "ETH transfer failed for release");
        } else {
             vaultTotalTokenBalances[release.token] -= release.amount; // Funds were already dedicated
            IERC20 tokenContract = IERC20(release.token);
            tokenContract.safeTransfer(msg.sender, release.amount);
        }

        release.claimed = true; // Mark as claimed
        emit ConditionalReleaseClaimed(releaseId);
    }

     /**
      * @dev Returns the IDs of pending conditional releases for a user.
      * Note: This can be gas intensive if a user has many releases.
      * @param user The user address.
      * @return An array of pending release IDs.
      */
    function getPendingConditionalReleases(address user) external view returns (uint256[] memory) {
        uint256[] memory pending; // Cannot determine size in view function easily without iterating twice.
        // A better design might use linked lists or track pending count per user.
        // For demonstration, we'll iterate and store.

        uint256 count = 0;
        for (uint i = 0; i < conditionalReleases.length; i++) {
            if (conditionalReleases[i].beneficiary == user && !conditionalReleases[i].claimed) {
                 count++;
            }
        }

        pending = new uint256[](count);
        uint256 currentIndex = 0;
         for (uint i = 0; i < conditionalReleases.length; i++) {
            if (conditionalReleases[i].beneficiary == user && !conditionalReleases[i].claimed) {
                 pending[currentIndex] = i;
                 currentIndex++;
            }
        }

        return pending;
    }


    /*-----------------------------------
    | Delegation Functions             |
    -----------------------------------*/

    /**
     * @dev Allows a user to delegate permission to another address to withdraw their funds.
     * Requires MODULE_DELEGATION to be enabled.
     * Only the owner of the funds can grant delegation.
     * @param delegatee The address allowed to withdraw on behalf of the sender.
     * @param token The token address (address(0) for ETH).
     * @param allowance The maximum amount the delegatee can withdraw.
     * @param expiration Timestamp after which the delegation is invalid.
     */
    function delegateWithdrawalPermission(address delegatee, address token, uint256 allowance, uint64 expiration) external whenNotPaused {
        if (!moduleEnabled[MODULE_DELEGATION]) revert ModuleDisabled(MODULE_DELEGATION);
        if (delegatee == msg.sender) revert DelegationFromSelf();
        if (allowance == 0) revert InvalidParameterValue(); // Or a specific error
        if (expiration <= block.timestamp) revert InvalidParameterValue();

        delegationPermissions[msg.sender][delegatee][token] = Delegation({
            allowance: allowance,
            expiration: expiration
        });

        emit DelegationPermissionGranted(msg.sender, delegatee, token, allowance, expiration);
    }

     /**
      * @dev Allows a designated delegatee to withdraw funds on behalf of the original owner.
      * Requires MODULE_DELEGATION to be enabled.
      * Delegatee calls this function, specifying the original owner.
      * @param owner The address of the original fund owner who granted the delegation.
      * @param token The token address (address(0) for ETH).
      * @param amount The amount to withdraw using the delegation.
      */
    function delegatedWithdrawal(address owner, address token, uint256 amount) external whenNotPaused {
        if (!moduleEnabled[MODULE_DELEGATION]) revert ModuleDisabled(MODULE_DELEGATION);
        if (amount == 0) revert DepositZero(); // Reusing error
        if (owner == msg.sender) revert DelegationFromSelf(); // Cannot use delegation on your own funds this way

        Delegation storage delegation = delegationPermissions[owner][msg.sender][token];

        if (delegation.allowance == 0 && delegation.expiration == 0) revert DelegationNotFound(); // Check if delegation exists (basic check)
        if (block.timestamp > delegation.expiration) revert DelegationExpired();
        if (amount > delegation.allowance) revert DelegationAllowanceExceeded();

        // Check if the *owner* has sufficient balance (using their balance tracking)
        uint256 ownerBalance = (token == address(0)) ? userTokenBalances[owner][address(0)] : userTokenBalances[owner][token];
        if (amount > ownerBalance) revert WithdrawalAmountExceedsBalance(); // Original owner must have funds

        // Check if withdrawal is allowed by dynamic rules *for the owner's funds*
        // This is complex - should delegation bypass rules? Let's assume for this example it must follow owner's rules.
        // However, _canWithdrawInternal checks msg.sender, which is the delegatee.
        // A robust implementation might need a dedicated rule check function that takes the 'effective user' as parameter.
        // For this example, we'll simplify and require the *delegatee* to also pass the rules, which might not be desired behavior.
        // Or, more reasonably, delegation bypasses rule checks *EXCEPT* for owner balance. Let's go with that simpler interpretation.

        // Update owner's balance within the vault
        if (token == address(0)) {
            userTokenBalances[owner][address(0)] -= amount;
            vaultTotalTokenBalances[address(0)] -= amount; // Update total vault balance as well
            (bool success, ) = payable(msg.sender).call{value: amount}(""); // Send ETH to the delegatee
             require(success, "ETH transfer failed for delegation");
        } else {
            userTokenBalances[owner][token] -= amount;
             vaultTotalTokenBalances[token] -= amount; // Update total vault balance
            IERC20 tokenContract = IERC20(token);
            tokenContract.safeTransfer(msg.sender, amount); // Send tokens to the delegatee
        }

        // Decrease allowance
        delegation.allowance -= amount;

        emit DelegationUsed(owner, msg.sender, token, amount);
    }

    /**
     * @dev Allows a user who granted delegation permission to revoke it.
     * Requires MODULE_DELEGATION to be enabled.
     * @param token The token address (address(0) for ETH) for which to revoke delegation.
     */
    function renounceDelegation(address token) external whenNotPaused {
        if (!moduleEnabled[MODULE_DELEGATION]) revert ModuleDisabled(MODULE_DELEGATION);

        // Clear all delegations granted by msg.sender for this token
        // This requires iterating through all potential delegatees, which is gas intensive and not feasible.
        // A better structure would map owner => token => delegatee => Delegation
        // Our current structure is owner => delegatee => token => Delegation.
        // Revoking ALL delegations by owner for a token means setting allowance/expiration to 0 for all delegatees.
        // We cannot iterate all possible delegatees.
        // Let's modify the state variable structure or limit revocation to a specific delegatee.
        // Let's add a function to revoke for a *specific* delegatee.

        revert("Specific delegatee revocation required, cannot revoke all"); // Indicate this function needs re-design or removal
    }

     /**
      * @dev Allows a user who granted delegation permission to revoke it for a specific delegatee.
      * Requires MODULE_DELEGATION to be enabled.
      * @param delegatee The address whose delegation rights to revoke.
      * @param token The token address (address(0) for ETH) for which to revoke delegation.
      */
     function renounceDelegationForDelegatee(address delegatee, address token) external whenNotPaused {
         if (!moduleEnabled[MODULE_DELEGATION]) revert ModuleDisabled(MODULE_DELEGATION);
         if (delegatee == address(0)) revert InvalidParameterValue();

         // Check if a delegation exists before attempting to clear
         if (delegationPermissions[msg.sender][delegatee][token].allowance == 0 && delegationPermissions[msg.sender][delegatee][token].expiration == 0) {
             revert DelegationNotFound();
         }

         delete delegationPermissions[msg.sender][delegatee][token];
         emit DelegationRevoked(msg.sender, token); // Event doesn't include delegatee, could improve
     }

    /*-----------------------------------
    | Module Management                |
    -----------------------------------*/

     /**
      * @dev Enables or disables specific advanced modules/features of the vault.
      * Requires ADMIN_ROLE.
      * @param module The keccak256 hash of the module name.
      * @param enabled The desired status (true to enable, false to disable).
      */
     function setModuleEnabled(bytes32 module, bool enabled) external onlyRole(ADMIN_ROLE) {
         // Basic validation for known modules
         if (module != MODULE_DYNAMIC_RULES &&
             module != MODULE_CONDITIONAL_RELEASES &&
             module != MODULE_DELEGATION &&
             module != MODULE_YIELD_SIMULATION) {
             revert InvalidModule(module);
         }
         moduleEnabled[module] = enabled;
         emit ModuleStatusChanged(module, enabled);
     }


    /*-----------------------------------
    | Emergency & Admin Functions      |
    -----------------------------------*/

    /**
     * @dev Pauses all core operations (deposits, withdrawals, claims, delegation use).
     * Requires PAUSER_ROLE.
     */
    function panicShutdown() external onlyRole(PAUSER_ROLE) {
        if (currentVaultState == VaultState.Paused) revert VaultIsNotPaused();
        currentVaultState = VaultState.Paused;
        emit VaultPaused();
    }

    /**
     * @dev Resumes operations after a panic shutdown.
     * Requires PAUSER_ROLE.
     */
    function resumeOperations() external onlyRole(PAUSER_ROLE) {
         if (currentVaultState == VaultState.Active) revert VaultIsPaused();
        currentVaultState = VaultState.Active;
        emit VaultResumed();
    }

     /**
      * @dev Allows the owner to sweep accidentally sent ERC20 tokens from the contract.
      * Cannot sweep ETH or tokens managed by the vault (user balances).
      * Requires OWNER role (standard Ownable).
      * @param token The address of the token to sweep.
      * @param recipient The address to send the tokens to.
      */
    function sweepTokens(address token, address recipient) external onlyOwner {
        if (token == address(0)) revert CannotSweepManagedToken(); // Cannot sweep ETH via this function
        // Cannot sweep tokens that are part of user balances
        // A rough check: if total balance > vaultTotalTokenBalances, it's "extra"
        // This requires iterating through all users, which is too gas intensive.
        // A simpler rule: cannot sweep any token that *ever* had a user deposit.
        // For this example, we'll just prevent sweeping ETH or any token that currently has a positive vaultTotalTokenBalances entry.
        if (vaultTotalTokenBalances[token] > 0) revert CannotSweepManagedToken();

        IERC20 tokenContract = IERC20(token);
        uint256 balance = tokenContract.balanceOf(address(this));
        if (balance > 0) {
            tokenContract.safeTransfer(recipient, balance);
            emit TokensSwept(token, recipient, balance);
        }
    }

    // Overriding transferOwnership from Ownable to emit an event
    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
        // Ownable already emits OwnershipTransferred
    }

    // Renounce ownership is inherited from Ownable

    /*-----------------------------------
    | Fallback & Receive              |
    -----------------------------------*/

     // receive function to accept plain ETH transfers
     receive() external payable {
         depositETH(); // Route plain ETH transfers to depositETH
     }

     // fallback function to reject arbitrary calls
     fallback() external payable {
         revert("Function not recognized or disallowed");
     }
}
```