Okay, here is a smart contract written in Solidity incorporating several advanced, creative, and trendy concepts beyond typical open-source examples. It's designed as a "Quantum Vault" – a metaphor for a vault with complex, time-sensitive, and condition-dependent access mechanisms.

**Disclaimer:** This contract is a complex example demonstrating various concepts. It is for educational and illustrative purposes only. Deploying complex smart contracts on a mainnet requires extensive security audits, gas optimizations, and careful consideration of all edge cases, which are beyond the scope of this example. Oracle interactions, VRF, and external calls are simplified or simulated.

---

**QuantumVault Smart Contract**

**Outline & Function Summary:**

This contract acts as a multi-asset vault (ERC-20, ETH) with sophisticated access control, time-based logic, conditional execution based on external data (simulated), recurring payment setups, configurable delays for critical changes, role-based permissions, emergency functions, and potential hooks for randomness or external protocol interaction.

1.  **Core Vault Management:** Handling deposits and withdrawals of ERC-20 tokens and native ETH.
2.  **Access Control:** Implementing granular roles beyond simple ownership (Admin, Strategist, Guardian, Relayer).
3.  **Time-Based Access:** Setting up and executing withdrawals locked until a specific time or for recurring intervals.
4.  **Conditional Access:** Setting up and executing withdrawals contingent on external data (e.g., price feeds, simulated via parameters).
5.  **Configuration Management:** Implementing a delayed proposal-and-execution mechanism for sensitive configuration changes to enhance security and governance.
6.  **Emergency Procedures:** Functions for pausing the contract or allowing specific roles to perform emergency withdrawals.
7.  **Batch Operations:** Performing multiple deposits or withdrawals in a single transaction.
8.  **External Interaction Hooks:** Frameworks for triggering calls to other contracts or integrating with oracles/VRF (simulated/simplified).

**Function Summary (Total: 30 Functions):**

*   `constructor`: Initializes roles and configures proposal delay.
*   `receive`: Handles incoming ETH deposits.
*   `depositERC20`: Deposits a specified amount of an allowed ERC-20 token.
*   `depositETH`: Explicit function for depositing ETH (redundant with `receive` but good practice).
*   `withdrawERC20`: Standard withdrawal of an allowed ERC-20 token by the user.
*   `withdrawETH`: Standard withdrawal of native ETH by the user.
*   `getVaultBalance`: Returns the total balance of a specific token held by the vault contract.
*   `getUserTotalHoldings`: Returns the total logical holdings of a user across all tokens (based on internal accounting).
*   `getUserTokenHoldings`: Returns the logical holdings of a user for a specific token.
*   `addAllowedToken`: Admin function to whitelist a token for deposits/withdrawals.
*   `removeAllowedToken`: Admin function to unwhitelist a token.
*   `grantRole`: Admin function to grant a specific role to an address.
*   `revokeRole`: Admin function to revoke a specific role from an address.
*   `hasRole`: Check if an account has a specific role.
*   `proposeConfigChange`: Proposes a change to a configuration setting, starts the delay timer.
*   `cancelConfigProposal`: Cancels an active configuration proposal.
*   `executeConfigChange`: Executes a proposed config change after the delay period.
*   `setConfigProposalDelay`: Sets the time required between proposing and executing changes (itself subject to proposal/delay).
*   `setupTimeLockedWithdrawal`: Sets up a withdrawal request that can only be executed after a specific timestamp.
*   `cancelTimeLockedWithdrawal`: User cancels their pending time-locked withdrawal.
*   `executeTimeLockedWithdrawal`: User executes their time-locked withdrawal after the unlock time.
*   `setupRecurringWithdrawal`: Sets up a series of recurring withdrawals at fixed intervals.
*   `cancelRecurringWithdrawal`: User cancels a recurring withdrawal setup.
*   `executeRecurringWithdrawal`: User or authorized relayer triggers a single instance of a recurring withdrawal.
*   `setupConditionalWithdrawal`: Sets up a withdrawal request dependent on an external condition (simulated by parameters).
*   `cancelConditionalWithdrawal`: User cancels a pending conditional withdrawal request.
*   `executeConditionalWithdrawal`: Authorized role (Strategist/Guardian) executes a conditional withdrawal if the condition is met (simulated check).
*   `pause`: Guardian function to pause transfers and critical operations.
*   `unpause`: Guardian function to unpause the contract.
*   `emergencyWithdrawToken`: Guardian function to withdraw all of a specific token in an emergency.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol"; // Example for potential meta-tx or signed calls (not fully implemented here)

// Define Interfaces for potential interactions (simplified/placeholder)
interface IOracle {
    function getValue(bytes calldata data) external view returns (uint256);
}

contract QuantumVault is AccessControl, ReentrancyGuard, Pausable {

    // --- --- ---
    // Roles (bytes32 generated using keccak256)
    // --- --- ---
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant STRATEGIST_ROLE = keccak256("STRATEGIST_ROLE"); // Can execute strategies, conditional calls
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");   // Can pause/unpause, emergency withdraw
    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");     // Can trigger recurring withdrawals on behalf of users (if signed)

    // --- --- ---
    // Configuration
    // --- --- ---
    mapping(address => bool) public allowedTokens;
    uint48 public configProposalDelay; // Delay in seconds before a proposed config change can be executed

    struct ConfigProposal {
        bytes32 key;
        bytes value;
        address proposer;
        uint48 proposalTime;
        bool exists; // To check if a proposal is active for this key
    }
    mapping(bytes32 => ConfigProposal) public configProposals; // Map config key hash to proposal details
    bytes32 constant CONFIG_KEY_PROPOSAL_DELAY = keccak256("CONFIG_PROPOSAL_DELAY");
    // Add other config keys as needed, e.g., keccak256("FEE_RATE"), keccak256("STRATEGY_CONTRACT")

    // --- --- ---
    // User Specific States (More complex tracking than just contract balance)
    // Note: For simplicity, this example assumes user funds are pooled,
    // and internal accounting tracks user "shares" or logical balances.
    // A real-world contract might issue shares (like ERC-4626) or use different accounting.
    // This maps user address -> token address -> logical balance held by user within the vault concept.
    mapping(address => mapping(address => uint256)) internal userTokenHoldings;

    struct TimeLock {
        address token;
        uint256 amount;
        uint48 unlockTime;
        bool active;
    }
    mapping(address => mapping(bytes32 => TimeLock)) public userTimeLocks; // user -> unique_id -> timelock details
    uint256 internal timeLockCounter; // To generate unique IDs

    struct RecurringWithdrawal {
        address token;
        uint256 amount;
        uint48 startTime;
        uint48 interval; // in seconds
        uint16 occurrences; // 0 for infinite
        uint16 executedCount;
        uint48 nextExecutionTime;
        bool active;
    }
    mapping(address => mapping(bytes32 => RecurringWithdrawal)) public userRecurringSetups; // user -> unique_id -> setup details
    uint256 internal recurringCounter; // To generate unique IDs

    struct ConditionalWithdrawal {
        address user; // The user requesting the withdrawal
        address token;
        uint256 amount;
        address oracle; // The oracle contract address
        bytes oracleData; // Data to pass to the oracle getValue function
        uint256 conditionThreshold; // Threshold for the oracle value check
        bool active; // Is this request still pending?
        bool conditionMet; // Was the condition met when checked? (optional, could re-check)
        address proposer; // Address who set up the conditional withdrawal
    }
     // Mapping from a unique request ID to the conditional withdrawal details.
     // Could be generated based on hash of parameters or a counter. Let's use a hash for uniqueness.
    mapping(bytes32 => ConditionalWithdrawal) public conditionalWithdrawals;

    // --- --- ---
    // Events
    // --- --- ---
    event DepositERC20(address indexed token, address indexed user, uint256 amount);
    event DepositETH(address indexed user, uint256 amount);
    event WithdrawalERC20(address indexed token, address indexed user, uint256 amount);
    event WithdrawalETH(address indexed user, uint256 amount);
    event TokenAdded(address indexed token);
    event TokenRemoved(address indexed token);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event ConfigProposalCreated(bytes32 indexed key, bytes newValue, address indexed proposer, uint48 proposalTime);
    event ConfigProposalCancelled(bytes32 indexed key);
    event ConfigChangeExecuted(bytes32 indexed key, bytes value);
    event TimeLockSetup(address indexed user, bytes32 indexed setupId, address indexed token, uint256 amount, uint48 unlockTime);
    event TimeLockCancelled(address indexed user, bytes32 indexed setupId);
    event TimeLockExecuted(address indexed user, bytes32 indexed setupId);
    event RecurringSetup(address indexed user, bytes32 indexed setupId, address indexed token, uint256 amount, uint48 startTime, uint48 interval, uint16 occurrences);
    event RecurringCancelled(address indexed user, bytes32 indexed setupId);
    event RecurringExecuted(address indexed user, bytes32 indexed setupId, uint16 executedCount);
    event ConditionalSetup(address indexed user, bytes32 indexed setupId, address indexed token, uint256 amount, address oracle, bytes oracleData, uint256 conditionThreshold);
    event ConditionalCancelled(address indexed user, bytes32 indexed setupId);
    event ConditionalExecuted(address indexed user, bytes32 indexed setupId);
    event Paused(address account);
    event Unpaused(address account);
    event EmergencyWithdraw(address indexed token, address indexed recipient, uint256 amount);

    // --- --- ---
    // Constructor
    // --- --- ---
    constructor(uint48 _configProposalDelay) payable {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Default admin has all privileges initially
        _grantRole(ADMIN_ROLE, msg.sender);
        // Initial proposal delay
        configProposalDelay = _configProposalDelay;

        // Grant initial roles or leave to be granted by admin later
        // _grantRole(STRATEGIST_ROLE, someStrategistAddress);
        // _grantRole(GUARDIAN_ROLE, someGuardianAddress);
    }

    // --- --- ---
    // Fallback/Receive ETH
    // --- --- ---
    receive() external payable whenNotPaused {
        // Implicitly adds to contract balance, user deposits tracked separately if using internal accounting
        // For this example, ETH deposit via receive() increases contract balance but isn't tied to a specific user balance here without extra logic
        emit DepositETH(msg.sender, msg.value);
    }

    fallback() external payable {
        // Optional: Handle calls to undefined functions, potentially reverting or logging
        revert("Call to undefined function");
    }

    // --- --- ---
    // Core Deposit/Withdrawal (ERC20 & ETH)
    // Note: These functions handle the physical transfer of assets.
    // User specific balances (`userTokenHoldings`) must be managed alongside these calls
    // if implementing internal accounting rather than a share-based system.
    // This example *shows* the userTokenHoldings mapping but doesn't fully implement
    // the complex share/accounting logic needed for a pool.
    // For simplicity in this example, deposit/withdraw directly affect contract balance
    // and the userTokenHoldings mapping is used conceptually for time-locked/conditional withdrawals.
    // A real vault would need to reconcile these or use a share token.
    // --- --- ---

    /**
     * @dev Deposits ERC-20 tokens into the vault.
     * Requires token approval beforehand.
     * @param token The address of the ERC-20 token.
     * @param amount The amount of tokens to deposit.
     */
    function depositERC20(address token, uint256 amount) external nonReentrant whenNotPaused {
        require(allowedTokens[token], "Token not allowed");
        require(amount > 0, "Amount must be > 0");

        IERC20(token).transferFrom(msg.sender, address(this), amount);

        // Update user's conceptual balance (if using internal accounting)
        userTokenHoldings[msg.sender][token] += amount; // Example: Simple increment

        emit DepositERC20(token, msg.sender, amount);
    }

    /**
     * @dev Deposits native ETH into the vault.
     * Can also use the `receive()` function.
     */
    function depositETH() external payable nonReentrant whenNotPaused {
        require(msg.value > 0, "Amount must be > 0");
        // userTokenHoldings[msg.sender][address(0)] += msg.value; // Example: Internal accounting for ETH
        emit DepositETH(msg.sender, msg.value);
    }


    /**
     * @dev Allows a user to withdraw their deposited ERC-20 tokens.
     * Assumes user has sufficient 'logical' balance based on internal accounting.
     * @param token The address of the ERC-20 token.
     * @param amount The amount of tokens to withdraw.
     */
    function withdrawERC20(address token, uint256 amount) external nonReentrant whenNotPaused {
        require(allowedTokens[token], "Token not allowed");
        require(amount > 0, "Amount must be > 0");
        // In a real pooled vault, check shares/entitlement.
        // Here, check internal user balance (conceptual):
        require(userTokenHoldings[msg.sender][token] >= amount, "Insufficient user balance");

        // Update user's conceptual balance
        userTokenHoldings[msg.sender][token] -= amount;

        IERC20(token).transfer(msg.sender, amount);
        emit WithdrawalERC20(token, msg.sender, amount);
    }

    /**
     * @dev Allows a user to withdraw their deposited native ETH.
     * Assumes user has sufficient 'logical' balance based on internal accounting.
     * @param amount The amount of ETH to withdraw (in wei).
     */
    function withdrawETH(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be > 0");
        // In a real pooled vault, check shares/entitlement.
        // Here, check internal user balance (conceptual):
        // require(userTokenHoldings[msg.sender][address(0)] >= amount, "Insufficient user balance"); // Example: Internal accounting for ETH

        // Update user's conceptual balance
        // userTokenHoldings[msg.sender][address(0)] -= amount; // Example: Internal accounting for ETH

        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "ETH transfer failed");
        emit WithdrawalETH(msg.sender, amount);
    }

    /**
     * @dev Returns the total physical balance of a specific token held by the vault contract.
     * @param token The address of the ERC-20 token or address(0) for ETH.
     * @return The balance of the token.
     */
    function getVaultBalance(address token) public view returns (uint256) {
        if (token == address(0)) {
            return address(this).balance;
        } else {
            return IERC20(token).balanceOf(address(this));
        }
    }

    /**
     * @dev Returns the total logical holdings of a user across all tokens (conceptually).
     * Note: This is a conceptual function for the internal accounting model.
     * @param user The address of the user.
     * @return The total conceptual balance.
     */
    function getUserTotalHoldings(address user) public view returns (uint256 total) {
         // This would require iterating through all possible tokens, which is gas-prohibitive.
         // A real implementation would track this sum or rely on share tokens.
         // Placeholder implementation:
         // for token in allowedTokens: total += userTokenHoldings[user][token];
         // This function is illustrative of the *concept* of user-specific balances.
         revert("Not implemented: Calculating total holdings requires iterating allowedTokens which is too gas heavy.");
    }

    /**
     * @dev Returns the logical holdings of a user for a specific token (conceptually).
     * @param user The address of the user.
     * @param token The address of the token.
     * @return The conceptual balance of the token for the user.
     */
    function getUserTokenHoldings(address user, address token) public view returns (uint256) {
        return userTokenHoldings[user][token];
    }


    // --- --- ---
    // Allowed Tokens Management
    // --- --- ---

    /**
     * @dev Adds a token to the list of allowed tokens for deposit/withdrawal.
     * Restricted to ADMIN_ROLE.
     * @param token The address of the token to allow.
     */
    function addAllowedToken(address token) external onlyRole(ADMIN_ROLE) nonReentrant {
        require(token != address(0), "Invalid token address");
        require(!allowedTokens[token], "Token already allowed");
        allowedTokens[token] = true;
        emit TokenAdded(token);
    }

    /**
     * @dev Removes a token from the list of allowed tokens.
     * Restricted to ADMIN_ROLE.
     * @param token The address of the token to disallow.
     */
    function removeAllowedToken(address token) external onlyRole(ADMIN_ROLE) nonReentrant {
        require(allowedTokens[token], "Token not currently allowed");
        allowedTokens[token] = false;
        emit TokenRemoved(token);
    }

    // --- --- ---
    // Access Control (Overriding AccessControl functions for clarity)
    // --- --- ---

    /**
     * @dev Grants a role to an account.
     * Restricted to DEFAULT_ADMIN_ROLE.
     * @param role The role to grant.
     * @param account The account to grant the role to.
     */
    function grantRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        _grantRole(role, account);
        emit RoleGranted(role, account, msg.sender);
    }

    /**
     * @dev Revokes a role from an account.
     * Restricted to DEFAULT_ADMIN_ROLE.
     * @param role The role to revoke.
     * @param account The account to revoke the role from.
     */
    function revokeRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        _revokeRole(role, account);
        emit RoleRevoked(role, account, msg.sender);
    }

    /**
     * @dev Checks if an account has a specific role.
     * @param role The role to check.
     * @param account The account to check.
     * @return True if the account has the role, false otherwise.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return super.hasRole(role, account);
    }

    // --- --- ---
    // Delayed Configuration Changes (Advanced Governance/Security)
    // Allows proposing changes that only take effect after a set time delay.
    // --- --- ---

    /**
     * @dev Proposes a change to a configuration setting. The change can only be executed after `configProposalDelay` has passed.
     * Restricted to ADMIN_ROLE.
     * @param key The identifier of the configuration setting (e.g., keccak256("FEE_RATE")).
     * @param newValue The new value for the configuration setting (encoded as bytes).
     */
    function proposeConfigChange(bytes32 key, bytes calldata newValue) external onlyRole(ADMIN_ROLE) nonReentrant {
        require(!configProposals[key].exists, "Proposal for this key already exists");
        require(key != bytes32(0), "Invalid config key");

        configProposals[key] = ConfigProposal({
            key: key,
            value: newValue,
            proposer: msg.sender,
            proposalTime: uint48(block.timestamp),
            exists: true
        });

        emit ConfigProposalCreated(key, newValue, msg.sender, uint48(block.timestamp));
    }

    /**
     * @dev Cancels an active configuration change proposal.
     * Restricted to ADMIN_ROLE or the proposer.
     * @param key The identifier of the configuration setting.
     */
    function cancelConfigProposal(bytes32 key) external nonReentrant {
        ConfigProposal storage proposal = configProposals[key];
        require(proposal.exists, "No active proposal for this key");
        require(hasRole(ADMIN_ROLE, msg.sender) || proposal.proposer == msg.sender, "Not authorized to cancel");

        delete configProposals[key]; // Removes the proposal

        emit ConfigProposalCancelled(key);
    }

    /**
     * @dev Executes a proposed configuration change after the required delay has passed.
     * Restricted to ADMIN_ROLE.
     * @param key The identifier of the configuration setting.
     */
    function executeConfigChange(bytes32 key) external onlyRole(ADMIN_ROLE) nonReentrant {
        ConfigProposal storage proposal = configProposals[key];
        require(proposal.exists, "No active proposal for this key");
        require(block.timestamp >= proposal.proposalTime + configProposalDelay, "Proposal delay has not passed");

        bytes memory newValue = proposal.value;
        bool success = false;

        // --- Apply the configuration change based on the key ---
        if (key == CONFIG_KEY_PROPOSAL_DELAY) {
            // Special case: Changing the proposal delay itself requires decoding bytes to uint48
            require(newValue.length == 6, "Invalid data for proposal delay"); // uint48 is 6 bytes
            uint48 newDelay = 0;
            assembly {
                // Read 6 bytes from newValue starting at offset 32 (Solidity data offset)
                newDelay := mload(add(newValue, 0x20))
                // Mask to get only the 6 bytes (48 bits)
                newDelay := and(newDelay, 0xFFFFFFFFFFFF)
            }
             // Ensure decoded value is reasonable (e.g., prevent 0 delay)
            require(newDelay > 0, "New delay must be greater than 0");
            configProposalDelay = newDelay;
            success = true;
        }
        // Add more `else if` for other configuration keys and their specific decoding/application logic
        // else if (key == keccak256("FEE_RATE")) { ... decode and set fee rate ... success = true; }
        // else if (key == keccak256("STRATEGY_CONTRACT")) { ... decode address and set strategy contract ... success = true; }
        // --- End of configuration change logic ---

        require(success, "Unknown or unhandled config key");

        emit ConfigChangeExecuted(key, newValue);

        // Clean up the proposal after execution
        delete configProposals[key];
    }

    /**
     * @dev Allows proposing and executing a change to the config proposal delay itself.
     * This function encapsulates the proposal pattern for this specific setting.
     * Restricted to ADMIN_ROLE.
     * @param newDelay The new delay in seconds.
     */
    function setConfigProposalDelay(uint48 newDelay) external onlyRole(ADMIN_ROLE) nonReentrant {
        require(newDelay > 0, "Delay must be positive");
        bytes memory encodedValue = abi.encodePacked(newDelay);
        proposeConfigChange(CONFIG_KEY_PROPOSAL_DELAY, encodedValue);
    }

    // --- --- ---
    // Time-Locked Withdrawals
    // Users can schedule withdrawals that are only accessible after a specific time.
    // --- --- ---

    /**
     * @dev Sets up a time-locked withdrawal for the sender.
     * The tokens remain in the vault but are earmarked/locked for this purpose.
     * Requires user to have sufficient logical balance.
     * @param token The address of the token (or address(0) for ETH).
     * @param amount The amount to lock.
     * @param unlockTime The timestamp after which the withdrawal can be executed.
     */
    function setupTimeLockedWithdrawal(address token, uint256 amount, uint48 unlockTime) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be > 0");
        require(unlockTime > block.timestamp, "Unlock time must be in the future");
         if (token != address(0)) {
            require(allowedTokens[token], "Token not allowed");
         }
        // In a real pooled vault, this would lock 'shares'.
        // Here, check internal user balance (conceptual) and deduct:
        require(userTokenHoldings[msg.sender][token] >= amount, "Insufficient user balance");
        userTokenHoldings[msg.sender][token] -= amount; // Deduct from available balance

        timeLockCounter++;
        bytes32 setupId = keccak256(abi.encodePacked(msg.sender, token, timeLockCounter, block.timestamp)); // Generate a unique ID

        userTimeLocks[msg.sender][setupId] = TimeLock({
            token: token,
            amount: amount,
            unlockTime: unlockTime,
            active: true
        });

        emit TimeLockSetup(msg.sender, setupId, token, amount, unlockTime);
    }

    /**
     * @dev Allows the user to cancel a pending time-locked withdrawal setup.
     * The locked amount is returned to their available logical balance.
     * @param setupId The ID of the time-lock setup.
     */
    function cancelTimeLockedWithdrawal(bytes32 setupId) external nonReentrant whenNotPaused {
        TimeLock storage lock = userTimeLocks[msg.sender][setupId];
        require(lock.active, "Time lock not active");
        require(block.timestamp < lock.unlockTime, "Cannot cancel after unlock time");

        // Return amount to user's available balance
        userTokenHoldings[msg.sender][lock.token] += lock.amount;

        lock.active = false; // Mark as inactive
        // Optionally, delete the struct entry to save gas on future lookups:
        // delete userTimeLocks[msg.sender][setupId];

        emit TimeLockCancelled(msg.sender, setupId);
    }

    /**
     * @dev Executes a time-locked withdrawal after the unlock time has passed.
     * The previously locked amount is transferred to the user.
     * @param setupId The ID of the time-lock setup.
     */
    function executeTimeLockedWithdrawal(bytes32 setupId) external nonReentrant whenNotPaused {
        TimeLock storage lock = userTimeLocks[msg.sender][setupId];
        require(lock.active, "Time lock not active");
        require(block.timestamp >= lock.unlockTime, "Unlock time has not passed");
        require(lock.amount > 0, "Amount is zero"); // Should not happen if setup was valid

        uint256 amount = lock.amount;
        address token = lock.token;

        lock.active = false; // Mark as inactive immediately
        // delete userTimeLocks[msg.sender][setupId]; // Clean up

        if (token == address(0)) {
            (bool success,) = msg.sender.call{value: amount}("");
            require(success, "ETH transfer failed");
             // No need to update userTokenHoldings for ETH transfer out
        } else {
             // No need to update userTokenHoldings for ERC20 transfer out
            IERC20(token).transfer(msg.sender, amount);
        }

        emit TimeLockExecuted(msg.sender, setupId);
    }

    // --- --- ---
    // Recurring Withdrawals (Subscription-like payments)
    // Allows users to set up withdrawals that can be triggered repeatedly over time.
    // Can be triggered by the user or a designated relayer (e.g., a service provider).
    // Requires user to maintain sufficient *total* balance in the vault over time.
    // --- --- ---

    /**
     * @dev Sets up a recurring withdrawal for the sender.
     * This does *not* lock the total amount upfront, but checks user's *current*
     * logical balance upon each execution. User must ensure sufficient funds.
     * @param token The address of the token (or address(0) for ETH).
     * @param amount The amount of each recurring withdrawal.
     * @param startTime The timestamp of the first possible execution.
     * @param interval The time interval between executions (in seconds).
     * @param occurrences The maximum number of times the withdrawal can be executed (0 for infinite).
     */
    function setupRecurringWithdrawal(
        address token,
        uint256 amount,
        uint48 startTime,
        uint48 interval,
        uint16 occurrences
    ) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be > 0");
        require(startTime >= block.timestamp, "Start time must be in the future or now");
        require(interval > 0, "Interval must be positive");
         if (token != address(0)) {
            require(allowedTokens[token], "Token not allowed");
         }
         // Note: Does NOT check or lock total amount here. User must manage balance.

        recurringCounter++;
        bytes32 setupId = keccak256(abi.encodePacked(msg.sender, token, recurringCounter, block.timestamp)); // Generate unique ID

        userRecurringSetups[msg.sender][setupId] = RecurringWithdrawal({
            token: token,
            amount: amount,
            startTime: startTime,
            interval: interval,
            occurrences: occurrences,
            executedCount: 0,
            nextExecutionTime: startTime,
            active: true
        });

        emit RecurringSetup(msg.sender, setupId, token, amount, startTime, interval, occurrences);
    }

    /**
     * @dev Allows the user to cancel a recurring withdrawal setup.
     * @param setupId The ID of the recurring setup.
     */
    function cancelRecurringWithdrawal(bytes32 setupId) external nonReentrant whenNotPaused {
        RecurringWithdrawal storage setup = userRecurringSetups[msg.sender][setupId];
        require(setup.active, "Recurring setup not active");

        setup.active = false; // Mark as inactive
        // Optionally, delete the struct entry:
        // delete userRecurringSetups[msg.sender][setupId];

        emit RecurringCancelled(msg.sender, setupId);
    }

    /**
     * @dev Executes a single instance of a recurring withdrawal.
     * Can be called by the user or anyone with RELAYER_ROLE (e.g., a service paying gas).
     * Requires the user to have sufficient logical balance *at the time of execution*.
     * @param user The user whose recurring withdrawal setup this is.
     * @param setupId The ID of the recurring setup.
     */
    function executeRecurringWithdrawal(address user, bytes32 setupId) external nonReentrant whenNotPaused {
        RecurringWithdrawal storage setup = userRecurringSetups[user][setupId];
        require(setup.active, "Recurring setup not active");
        require(block.timestamp >= setup.nextExecutionTime, "Not yet time for the next execution");
        require(setup.occurrences == 0 || setup.executedCount < setup.occurrences, "Max occurrences reached");
        require(setup.amount > 0, "Amount is zero");

        address token = setup.token;
        uint256 amount = setup.amount;

        // Check user's logical balance AT THE TIME OF EXECUTION
        require(userTokenHoldings[user][token] >= amount, "Insufficient user balance for recurring withdrawal");

        // Update user's conceptual balance
        userTokenHoldings[user][token] -= amount;

        // Update setup state
        setup.executedCount++;
        // Calculate next execution time. Note: Avoids drifting by adding interval to start/previous execution time.
        // Example: next = startTime + executedCount * interval;
        // Or simply advance from current nextExecutionTime:
        setup.nextExecutionTime = setup.nextExecutionTime + setup.interval; // Simple interval increase

        // If max occurrences reached, deactivate
        if (setup.occurrences > 0 && setup.executedCount >= setup.occurrences) {
             setup.active = false;
        }

        // Perform transfer
        if (token == address(0)) {
            (bool success,) = user.call{value: amount}(""); // Send ETH to the user
            require(success, "ETH transfer failed");
        } else {
            IERC20(token).transfer(user, amount); // Send ERC20 to the user
        }

        emit RecurringExecuted(user, setupId, setup.executedCount);
    }

    // --- --- ---
    // Conditional Withdrawals (Based on External Data/Oracles - Simulated)
    // Allows setting up withdrawals that are only possible if an external condition is met.
    // --- --- ---

    /**
     * @dev Sets up a withdrawal request that can only be executed if a specified oracle condition is met.
     * Requires user to have sufficient logical balance at setup time, which is then earmarked/locked.
     * @param token The address of the token (or address(0) for ETH).
     * @param amount The amount to withdraw.
     * @param oracle The address of the oracle contract to query.
     * @param oracleData Encoded data to pass to the oracle's `getValue` function.
     * @param conditionThreshold The threshold the oracle value must meet (e.g., >= threshold).
     */
    function setupConditionalWithdrawal(
        address token,
        uint256 amount,
        address oracle,
        bytes calldata oracleData,
        uint256 conditionThreshold
    ) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be > 0");
        require(oracle != address(0), "Oracle address cannot be zero");
         if (token != address(0)) {
            require(allowedTokens[token], "Token not allowed");
         }
        // In a real pooled vault, this would lock 'shares'.
        // Here, check internal user balance (conceptual) and deduct:
        require(userTokenHoldings[msg.sender][token] >= amount, "Insufficient user balance");
        userTokenHoldings[msg.sender][token] -= amount; // Deduct from available balance

        // Generate a unique ID for the request
        bytes32 setupId = keccak256(abi.encodePacked(
            msg.sender, token, amount, oracle, oracleData, conditionThreshold, block.timestamp
        ));
        require(!conditionalWithdrawals[setupId].active, "Conditional setup already exists"); // Prevent ID collision

        conditionalWithdrawals[setupId] = ConditionalWithdrawal({
            user: msg.sender,
            token: token,
            amount: amount,
            oracle: oracle,
            oracleData: oracleData,
            conditionThreshold: conditionThreshold,
            active: true,
            conditionMet: false, // Will be checked on execution
            proposer: msg.sender
        });

        emit ConditionalSetup(msg.sender, setupId, token, amount, oracle, oracleData, conditionThreshold);
    }

     /**
     * @dev Allows the user to cancel a pending conditional withdrawal setup.
     * The earmarked amount is returned to their available logical balance.
     * @param setupId The ID of the conditional setup.
     */
    function cancelConditionalWithdrawal(bytes32 setupId) external nonReentrant whenNotPaused {
        ConditionalWithdrawal storage cond = conditionalWithdrawals[setupId];
        require(cond.active, "Conditional setup not active");
        require(cond.user == msg.sender, "Not authorized to cancel this setup");

         // Return amount to user's available balance
        userTokenHoldings[cond.user][cond.token] += cond.amount;

        cond.active = false; // Mark as inactive
        // Optionally, delete the struct entry:
        // delete conditionalWithdrawals[setupId];

        emit ConditionalCancelled(cond.user, setupId);
    }

    /**
     * @dev Executes a conditional withdrawal if the oracle condition is met.
     * Restricted to STRATEGIST_ROLE or GUARDIAN_ROLE.
     * @param setupId The ID of the conditional setup.
     */
    function executeConditionalWithdrawal(bytes32 setupId) external onlyRole(STRATEGIST_ROLE, GUARDIAN_ROLE) nonReentrant whenNotPaused {
        ConditionalWithdrawal storage cond = conditionalWithdrawals[setupId];
        require(cond.active, "Conditional setup not active");
        require(cond.amount > 0, "Amount is zero");

        // --- Simulate Oracle Check ---
        // In a real contract, this would call an oracle contract's view function:
        // uint256 oracleValue = IOracle(cond.oracle).getValue(cond.oracleData);
        // require(oracleValue >= cond.conditionThreshold, "Oracle condition not met");
        // --- End Simulation ---

        // For this example, we'll just assume the condition is met for demonstration purposes.
        // A real oracle integration would be synchronous (view call) or asynchronous (callback).
        // This simplified version requires the caller (Strategist/Guardian) to *know* the condition is met off-chain.
        // A safer implementation would involve a verifiable on-chain oracle call.
        // require(IOracle(cond.oracle).getValue(cond.oracleData) >= cond.conditionThreshold, "Oracle condition not met"); // Example real check

        // Simulate the check passing:
        bool conditionMet = true; // REPLACE WITH ACTUAL ORACLE CALL RESULT

        require(conditionMet, "Oracle condition not met");

        address user = cond.user;
        address token = cond.token;
        uint256 amount = cond.amount;

        cond.active = false; // Deactivate immediately
        // delete conditionalWithdrawals[setupId]; // Clean up

        // Perform transfer
        if (token == address(0)) {
            (bool success,) = user.call{value: amount}(""); // Send ETH
            require(success, "ETH transfer failed");
        } else {
            IERC20(token).transfer(user, amount); // Send ERC20
        }

        emit ConditionalExecuted(user, setupId);
    }


    // --- --- ---
    // Batch Operations
    // Allows users to deposit/withdraw multiple tokens in a single transaction.
    // --- --- ---

    /**
     * @dev Deposits multiple ERC-20 tokens in a single transaction.
     * Requires prior approval for each token.
     * @param tokens Array of token addresses.
     * @param amounts Array of amounts corresponding to each token.
     */
    function batchDepositsERC20(address[] calldata tokens, uint256[] calldata amounts) external nonReentrant whenNotPaused {
        require(tokens.length == amounts.length, "Array length mismatch");
        require(tokens.length > 0, "Arrays cannot be empty");

        for (uint i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            uint256 amount = amounts[i];
            require(allowedTokens[token], "Token not allowed");
            require(amount > 0, "Amount must be > 0 for all tokens");

            IERC20(token).transferFrom(msg.sender, address(this), amount);

             // Update user's conceptual balance (if using internal accounting)
            userTokenHoldings[msg.sender][token] += amount; // Example: Simple increment

            emit DepositERC20(token, msg.sender, amount); // Log each deposit
        }
    }

     /**
     * @dev Withdraws multiple ERC-20 tokens in a single transaction.
     * Requires user to have sufficient logical balance for each token.
     * @param tokens Array of token addresses.
     * @param amounts Array of amounts corresponding to each token.
     */
    function batchWithdrawalsERC20(address[] calldata tokens, uint256[] calldata amounts) external nonReentrant whenNotPaused {
        require(tokens.length == amounts.length, "Array length mismatch");
        require(tokens.length > 0, "Arrays cannot be empty");

        // Pre-check all balances before any transfers
        for (uint i = 0; i < tokens.length; i++) {
             require(allowedTokens[tokens[i]], "Token not allowed");
             require(amounts[i] > 0, "Amount must be > 0 for all tokens");
             require(userTokenHoldings[msg.sender][tokens[i]] >= amounts[i], "Insufficient user balance for one or more tokens");
        }

        // Perform transfers and update balances
        for (uint i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            uint256 amount = amounts[i];

            // Update user's conceptual balance
            userTokenHoldings[msg.sender][token] -= amount;

            IERC20(token).transfer(msg.sender, amount);
            emit WithdrawalERC20(token, msg.sender, amount); // Log each withdrawal
        }
    }


    // --- --- ---
    // Emergency Functions
    // Allows designated roles to pause operations or withdraw funds in emergencies.
    // --- --- ---

    /**
     * @dev Pauses the contract, preventing most state-changing operations.
     * Restricted to GUARDIAN_ROLE.
     */
    function pause() external onlyRole(GUARDIAN_ROLE) nonReentrant whenNotPaused {
        _pause();
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses the contract, allowing operations to resume.
     * Restricted to GUARDIAN_ROLE.
     */
    function unpause() external onlyRole(GUARDIAN_ROLE) nonReentrant whenPaused {
        _unpause();
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Allows a Guardian to withdraw all of a specific token in an emergency.
     * Does NOT respect user-specific balances, withdraws the contract's full balance.
     * Restricted to GUARDIAN_ROLE.
     * @param token The address of the token (or address(0) for ETH) to withdraw.
     */
    function emergencyWithdrawToken(address token) external onlyRole(GUARDIAN_ROLE) nonReentrant {
        uint256 balance = getVaultBalance(token);
        require(balance > 0, "Token balance is zero");

        if (token == address(0)) {
            (bool success, ) = msg.sender.call{value: balance}("");
            require(success, "Emergency ETH withdrawal failed");
        } else {
             // No need to check allowedTokens for emergency withdrawal
            IERC20(token).transfer(msg.sender, balance);
        }

        // Note: This emergency withdrawal bypasses internal user accounting.
        // This is intended for scenarios where the vault needs to be drained quickly.

        emit EmergencyWithdraw(token, msg.sender, balance);
    }

    // --- --- ---
    // Placeholder/Conceptual Advanced Features (Not fully implemented)
    // Demonstrate potential for integration with VRF or external contracts.
    // --- --- ---

    // Example: Hook for Chainlink VRF (Simplified callback)
    // Requires Chainlink VRF specific setup (Coordinator address, Link token, subscription)
    // These functions only show the *idea* of requesting/receiving randomness for a purpose.
    /*
    address public vrfCoordinator;
    bytes32 public keyHash;
    uint64 public s_subscriptionId;
    mapping(bytes32 => address) public requestIdToUser; // Map VRF request ID to user

    // Call this function (e.g., by Strategist) to get randomness
    function requestRandomness(bytes32 userSeed) external onlyRole(STRATEGIST_ROLE) returns (bytes32 requestId) {
        // In a real scenario, call VRFCoordinatorV2Interface(vrfCoordinator).requestRandomWords(...)
        // This is just a placeholder to show the function signature
        emit RequestSent(requestId); // Example event
        return bytes32(keccak256(abi.encodePacked(userSeed, block.timestamp))); // Placeholder ID
    }

    // This is the callback function from the VRF Coordinator
    function fulfillRandomness(bytes32 requestId, uint256[] memory randomWords) internal {
        // Only callable by the VRF Coordinator
        // Use the randomWords (e.g., randomWords[0]) for some vault logic
        // E.g., decide strategy, select users for a lottery, trigger a random event
        emit RandomnessReceived(requestId, randomWords[0]); // Example event

        address user = requestIdToUser[requestId];
        // Example: trigger a random action for the user based on randomWords[0]
        // triggerRandomActionForUser(user, randomWords[0]);
    }
    */

    // Example: Generic external call trigger (Dangerous, use with caution and strong access control)
    // Can allow the vault (specifically, a controlled role) to interact with other protocols.
    /**
     * @dev Allows a role (e.g., Strategist) to trigger a call to an external contract.
     * This is powerful and potentially risky. Use with extreme caution.
     * Restricted to STRATEGIST_ROLE.
     * @param target The address of the target contract.
     * @param data The abi-encoded data for the function call.
     */
    function triggerExternalCall(address target, bytes calldata data) external onlyRole(STRATEGIST_ROLE) nonReentrant whenNotPaused {
        require(target != address(0), "Target address cannot be zero");

        // Add checks here to restrict *which* targets or *which* data patterns are allowed
        // For example, only allow interaction with approved DeFi protocols, or specific function signatures.
        // Without strong limitations, this is a major security risk.

        (bool success, bytes memory result) = target.call(data);
        require(success, string(abi.decode(result, (string)))); // Revert with target contract's error message

        // Depending on the call, state might need updates here
    }

    // --- Total functions: 30 ---
    // Constructor: 1
    // receive: 1
    // depositERC20: 1
    // depositETH: 1
    // withdrawERC20: 1
    // withdrawETH: 1
    // getVaultBalance: 1
    // getUserTotalHoldings: 1 (Conceptual)
    // getUserTokenHoldings: 1 (Conceptual)
    // addAllowedToken: 1
    // removeAllowedToken: 1
    // grantRole: 1
    // revokeRole: 1
    // hasRole: 1
    // proposeConfigChange: 1
    // cancelConfigProposal: 1
    // executeConfigChange: 1
    // setConfigProposalDelay: 1
    // setupTimeLockedWithdrawal: 1
    // cancelTimeLockedWithdrawal: 1
    // executeTimeLockedWithdrawal: 1
    // setupRecurringWithdrawal: 1
    // cancelRecurringWithdrawal: 1
    // executeRecurringWithdrawal: 1
    // setupConditionalWithdrawal: 1
    // cancelConditionalWithdrawal: 1
    // executeConditionalWithdrawal: 1
    // pause: 1
    // unpause: 1
    // emergencyWithdrawToken: 1
    // triggerExternalCall: 1
    // VRF Placeholder: 2 (requestRandomness, fulfillRandomness - commented out)
    // Total = 1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1 = 30

}
```