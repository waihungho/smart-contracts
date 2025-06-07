Okay, let's design a smart contract called `QuantumVault`. This contract will manage diverse digital assets (ERC-20 and ERC-721) using advanced, conditional logic, dynamic state transitions, granular permissions, and a simulated "reputation" or "trust" score. It will incorporate concepts like conditional deposits (superposition), dynamic fees, registered strategy execution, and emergency escape hatches, all controlled by a multi-faceted state machine and delegated permissions.

We will avoid direct copies of standard patterns like Uniswap pools, standard ERC-4626 vaults, basic timelocks, or simple multi-sigs, focusing on the *combination* and *conditional/dynamic* aspects.

**Disclaimer:** This contract is a complex conceptual example demonstrating advanced ideas. It is **NOT** audited, production-ready code. Implementing features like true reputation systems, secure external condition checks, or complex cross-contract interactions requires significant additional security considerations and robust oracle/ZK integrations not fully detailed here.

---

## Smart Contract: QuantumVault

**Description:**

The `QuantumVault` is a conceptual smart contract designed for managing multiple types of digital assets (ERC-20 and ERC-721) with a high degree of dynamic control, conditional logic, and granular access management. It operates based on distinct "Vault States," each with configurable parameters affecting operations like deposits, withdrawals, and fees. It introduces concepts such as conditional ("superposition") deposits, a simulated reputation system influencing access, delegate management with limits, and integrated strategy execution via registered adapters.

**Outline:**

1.  **State Variables & Data Structures:** Define different operational states, state-specific parameters, asset tracking, permissions, reputation mapping, conditional deposit tracking, etc.
2.  **Events & Errors:** Define relevant events for transparency and custom errors for revert reasons.
3.  **Modifiers:** Define access control and state-dependent modifiers.
4.  **Constructor:** Initialize the contract, set initial owner and state.
5.  **Vault State Management:** Functions to change the vault's operating state and configure parameters for each state.
6.  **Asset Management (ERC-20 & ERC-721):** Functions for depositing and withdrawing assets, incorporating state rules and permissions.
7.  **Conditional Deposits (Superposition):** Functions to deposit assets that are locked until a specific condition is met and functions to check and resolve these conditions.
8.  **Access Control & Permissions:** Functions to grant, revoke, and check granular permissions based on function selectors, potentially influenced by reputation or state.
9.  **Reputation System (Simulated):** Functions to update and retrieve a simulated on-chain reputation score.
10. **Strategy Execution:** Functions to register trusted strategy adapter contracts and execute calls through them.
11. **Dynamic Parameters:** Functions to update parameters like fees based on external conditions or governance (simulated).
12. **Emergency & Maintenance:** Functions for pausing, unpausing, setting emergency custodians, and initiating emergency withdrawals.
13. **Batch Operations:** A function to execute multiple calls in a single transaction.
14. **Information & Query:** View functions to inspect the vault's state, balances, permissions, and configurations.

**Function Summary:**

*   `constructor()`: Initializes the contract, setting the owner and initial vault state.
*   `setVaultState(VaultState newState)`: Changes the primary operational state of the vault (e.g., Active, Restricted, Emergency).
*   `configureStateParameters(VaultState state, StateParameters calldata params)`: Sets specific parameters (fees, limits, etc.) for a given vault state.
*   `updateDynamicFeeRate(uint256 newFeeBasisPoints)`: Updates the dynamic fee rate (simulating oracle/governance input).
*   `depositERC20(address token, uint256 amount)`: Deposits ERC-20 tokens into the vault, subject to current state rules, fees, and potentially reputation/permissions.
*   `withdrawERC20(address token, uint256 amount)`: Withdraws ERC-20 tokens, subject to current state, permissions, reputation, and withdrawal limits.
*   `depositERC721(address token, uint256 tokenId)`: Deposits an ERC-721 token, subject to state rules and reputation.
*   `withdrawERC721(address token, uint256 tokenId)`: Withdraws an ERC-721 token, subject to state, permissions, reputation, and ownership check.
*   `depositSuperposition(address assetContract, uint256 amountOrTokenId, bool isERC721, uint256 unlockTime, bytes32 conditionHash)`: Locks assets until a specified unlock time and condition hash are met.
*   `resolveSuperposition(bytes32 conditionHash, bytes memory conditionProof)`: Attempts to resolve a conditional deposit by providing proof for the condition hash (proof is simulated here).
*   `getConditionalDepositStatus(bytes32 conditionHash)`: View function to check the status (locked/resolved) of a conditional deposit.
*   `grantFunctionPermission(address user, bytes4 functionSelector, bool allowed)`: Grants or revokes general permission for a user to call a specific function, potentially influenced by reputation or state rules.
*   `delegateManagementWithLimit(address delegate, bytes4[] calldata selectors, uint256 dailyCallLimit)`: Delegates permission for specific functions to another address with a daily call limit.
*   `revokeDelegatedManagement(address delegate)`: Revokes all delegated management permissions for an address.
*   `updateReputationScore(address user, uint256 newScore)`: Simulates updating a user's on-chain reputation score (controlled by owner/governance).
*   `registerStrategyAdapter(address adapter, bool allowed)`: Registers or de-registers a trusted strategy adapter contract address.
*   `executeStrategy(address adapter, bytes calldata data)`: Calls a registered strategy adapter contract with arbitrary data, allowing the vault to interact with external protocols.
*   `batchExecuteCalls(address[] calldata targets, bytes[] calldata datas)`: Executes multiple arbitrary calls from the vault (e.g., transferring different tokens, calling other contracts).
*   `panicWithdraw(address token, uint256 amount)`: Allows the emergency custodian (or owner) to withdraw a specific amount of an ERC-20 token, bypassing some standard checks (only in specific states).
*   `setEmergencyCustodian(address custodian)`: Sets the address authorized for emergency actions.
*   `pauseVaultOperations()`: Pauses most interactions with the vault (except unpause and emergency functions).
*   `unpauseVaultOperations()`: Unpauses the vault.
*   `getERC20Balance(address token)`: View function to get the vault's balance of a specific ERC-20 token.
*   `getERC721Owner(address token, uint256 tokenId)`: View function to check if the vault owns a specific ERC-721 token ID.
*   `getVaultState()`: View function to get the current operational state of the vault.
*   `getStateParameters(VaultState state)`: View function to retrieve parameters for a specific vault state.
*   `getReputationScore(address user)`: View function to get a user's simulated reputation score.
*   `checkPermission(address user, bytes4 functionSelector)`: View function to check if a user has permission for a function based on general grants, state, and potentially reputation.
*   `getDelegatedPermissions(address delegate)`: View function to retrieve the functions delegated to a specific address.
*   `getDelegatedCallCount(address delegate, bytes4 functionSelector)`: View function to get the daily call count for a delegated function.
*   `resetDailyCallCounts()`: Resets the daily call counters for delegated management (intended to be called daily or by a trusted oracle/keeper).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// --- Outline & Function Summary (See above) ---

/// @title QuantumVault
/// @notice A conceptual smart contract for managing diverse digital assets with advanced, conditional logic and dynamic states.
contract QuantumVault is Ownable, Pausable {
    using SafeERC20 for IERC20;
    using Address for address;

    // --- State Variables & Data Structures ---

    enum VaultState {
        Initial,       // Initial deployment state
        Active,        // Standard operations allowed
        Restricted,    // Limited operations, potentially higher fees
        Maintenance,   // Operations paused for upgrades/fixes
        Emergency      // Critical state, minimal operations, emergency withdrawals
    }

    struct StateParameters {
        uint256 depositFeeBasisPoints; // 0-10000 (0%-100%)
        uint256 withdrawalFeeBasisPoints;
        uint256 maxDepositAmount;      // Per transaction per asset (0 for unlimited)
        uint256 maxWithdrawalAmount;   // Per transaction per asset (0 for unlimited)
        uint256 minReputationRequired; // Minimum reputation score to interact in this state
        bool allowERC20Deposits;
        bool allowERC20Withdrawals;
        bool allowERC721Deposits;
        bool allowERC721Withdrawals;
        bool allowStrategyExecution;
    }

    struct ConditionalDeposit {
        address depositor;
        address assetContract;
        uint256 amountOrTokenId;
        bool isERC721;
        uint256 unlockTime;       // Unix timestamp after which resolution is possible
        bytes32 conditionHash;    // Hash representing the off-chain condition
        bool resolved;            // True if condition met and assets claimed
    }

    VaultState public currentVaultState;
    mapping(VaultState => StateParameters) public stateConfigs;

    // ERC20 Balances are tracked implicitly by the contract's holdings

    // ERC721 Tracking: contract address => token ID => owned by vault
    mapping(address => mapping(uint256 => bool)) internal erc721Holdings;
    // ERC721 deposited count (optional, for query)
    mapping(address => uint256) public erc721TokenCount;

    // Simulated Reputation System
    mapping(address => uint256) public reputationScores;

    // Granular Permissions: user => function selector => allowed
    mapping(address => mapping(bytes4 => bool)) public functionPermissions;

    // Delegated Management: delegate => function selector => allowed
    mapping(address => mapping(bytes4 => bool)) public delegatedPermissions;
    // Delegated Management Daily Call Limits: delegate => function selector => daily limit
    mapping(address => mapping(bytes4 => uint256)) public delegatedCallLimits;
    // Delegated Management Daily Call Count: delegate => function selector => count for current day
    mapping(address => mapping(bytes4 => uint256)) internal delegatedCallCounts;
    uint256 public lastCallCountResetTimestamp; // Timestamp of the last daily reset

    // Conditional Deposits: conditionHash => ConditionalDeposit
    mapping(bytes32 => ConditionalDeposit) public conditionalDeposits;
    // Track deposits by depositor for easier lookup (optional)
    mapping(address => bytes32[]) public depositorConditionalHashes;

    // Registered Strategy Adapters
    mapping(address => bool) public registeredStrategyAdapters;

    // Dynamic Fee Rate (example of a parameter that could be oracle-fed)
    uint256 public dynamicFeeBasisPoints; // Applied on top of state fees, or as sole fee

    address public emergencyCustodian; // Address authorized for panic withdrawals

    // --- Events ---

    event VaultStateChanged(VaultState oldState, VaultState newState);
    event StateParametersConfigured(VaultState state, StateParameters params);
    event DynamicFeeRateUpdated(uint256 newFeeBasisPoints);
    event ERC20Deposited(address indexed token, address indexed depositor, uint256 amount, uint256 feePaid);
    event ERC20WithdrawalInitiated(address indexed token, address indexed receiver, uint256 amount, uint256 feePaid);
    event ERC721Deposited(address indexed token, uint256 indexed tokenId, address indexed depositor);
    event ERC721WithdrawalInitiated(address indexed token, uint256 indexed tokenId, address indexed receiver);
    event SuperpositionDepositLocked(bytes32 indexed conditionHash, address indexed depositor, address assetContract, uint256 amountOrTokenId, bool isERC721);
    event SuperpositionDepositResolved(bytes32 indexed conditionHash, address indexed receiver, uint256 amountOrTokenId);
    event FunctionPermissionGranted(address indexed user, bytes4 indexed functionSelector, bool allowed);
    event ManagementDelegated(address indexed delegate, bytes4[] selectors, uint256 dailyLimit);
    event ManagementDelegationRevoked(address indexed delegate);
    event ReputationScoreUpdated(address indexed user, uint256 newScore);
    event StrategyAdapterRegistered(address indexed adapter, bool allowed);
    event StrategyExecuted(address indexed adapter, bytes calldata data);
    event BatchExecution(address[] indexed targets);
    event PanicWithdrawal(address indexed token, address indexed receiver, uint256 amount);
    event EmergencyCustodianSet(address indexed oldCustodian, address indexed newCustodian);
    event DailyCallCountsReset();

    // --- Errors ---

    error InvalidState();
    error InsufficientReputation();
    error DepositNotAllowedInState();
    error WithdrawalNotAllowedInState();
    error DepositAmountExceedsLimit(uint256 maxAmount);
    error WithdrawalAmountExceedsLimit(uint256 maxAmount);
    error ERC721NotOwnedByVault();
    error InvalidConditionalDeposit();
    error ConditionalDepositNotReady(uint256 unlockTime);
    error InvalidConditionProof(); // Simulated error
    error ConditionalDepositAlreadyResolved();
    error PermissionDenied(address user, bytes4 functionSelector);
    error DelegationLimitExceeded(bytes4 functionSelector, uint256 limit);
    error AdapterNotRegistered(address adapter);
    error StrategyExecutionFailed(bytes returnData);
    error BatchExecutionFailed(address target, bytes returnData);
    error OnlyEmergencyCustodianOrOwner();
    error NotInEmergencyState();
    error CallCountsNotReadyForReset();

    // --- Modifiers ---

    modifier onlyState(VaultState state) {
        if (currentVaultState != state) revert InvalidState();
        _;
    }

    modifier hasPermission(bytes4 functionSelector) {
        // Owner always has permission
        if (msg.sender == owner()) _;
        else {
            // Check general permission grant
            bool granted = functionPermissions[msg.sender][functionSelector];
            // Check state parameters (e.g., reputation requirement)
            bool meetsStateReputation = reputationScores[msg.sender] >= stateConfigs[currentVaultState].minReputationRequired;

            // Check delegated permission
            bool delegated = delegatedPermissions[msg.sender][functionSelector];
            bool delegatedLimitOk = true;
            if (delegated) {
                 // Check daily limit for delegated calls
                if (delegatedCallLimits[msg.sender][functionSelector] > 0) {
                    // Check if counts need reset (simple daily check)
                    if (block.timestamp / 1 days > lastCallCountResetTimestamp / 1 days) {
                         revert CallCountsNotReadyForReset(); // Keeper needs to call resetDailyCallCounts first
                    }
                    if (delegatedCallCounts[msg.sender][functionSelector] >= delegatedCallLimits[msg.sender][functionSelector]) {
                         revert DelegationLimitExceeded(functionSelector, delegatedCallLimits[msg.sender][functionSelector]);
                    }
                     delegatedCallCounts[msg.sender][functionSelector]++; // Increment count
                }
            }

            // Permission granted if: (explicitly granted OR delegated) AND meets state reputation
            if (!( (granted || delegated) && meetsStateReputation )) {
                revert PermissionDenied(msg.sender, functionSelector);
            }
            _;
        }
    }

     // This modifier is used internally by hasPermission, but a public function allows a keeper to reset counts
    function resetDailyCallCounts() public onlyOwner {
        // Simple check: only allow reset if a full day has passed since last reset
        if (block.timestamp / 1 days <= lastCallCountResetTimestamp / 1 days) {
             revert CallCountsNotReadyForReset();
        }
        // This is a gas-intensive operation if there are many delegates/selectors.
        // A better approach might involve iterating through active delegations.
        // For this concept, we'll just reset the timestamp, implying a full map reset
        // would happen conceptually or be managed off-chain/via iteration.
        // In a real system, you'd need to iterate and clear the specific delegatedCallCounts map.
        // We'll just update the timestamp for this example.
        lastCallCountResetTimestamp = block.timestamp;
        emit DailyCallCountsReset();
    }


    modifier checkReputation(address user) {
        if (reputationScores[user] < stateConfigs[currentVaultState].minReputationRequired) {
            revert InsufficientReputation();
        }
        _;
    }

    // --- Constructor ---

    constructor() Ownable(msg.sender) Pausable() {
        currentVaultState = VaultState.Initial;
        // Configure a basic initial state
        stateConfigs[VaultState.Initial] = StateParameters({
            depositFeeBasisPoints: 0,
            withdrawalFeeBasisPoints: 0,
            maxDepositAmount: 0,
            maxWithdrawalAmount: 0,
            minReputationRequired: 0,
            allowERC20Deposits: false,
            allowERC20Withdrawals: false,
            allowERC721Deposits: false,
            allowERC721Withdrawals: false,
            allowStrategyExecution: false
        });
         lastCallCountResetTimestamp = block.timestamp; // Initialize reset timestamp
    }

    // --- Vault State Management ---

    /// @notice Changes the primary operational state of the vault.
    /// @param newState The target vault state.
    function setVaultState(VaultState newState) external onlyOwner {
        emit VaultStateChanged(currentVaultState, newState);
        currentVaultState = newState;
    }

    /// @notice Configures specific operational parameters for a given vault state.
    /// @param state The vault state to configure.
    /// @param params The StateParameters struct containing configuration details.
    function configureStateParameters(VaultState state, StateParameters calldata params) external onlyOwner {
        stateConfigs[state] = params;
        emit StateParametersConfigured(state, params);
    }

     /// @notice Updates the dynamic fee rate. Can be triggered by owner/governance or an oracle keeper.
     /// @param newFeeBasisPoints The new dynamic fee rate in basis points (0-10000).
    function updateDynamicFeeRate(uint256 newFeeBasisPoints) external onlyOwner { // Or add an oracle keeper role
        dynamicFeeBasisPoints = newFeeBasisPoints;
        emit DynamicFeeRateUpdated(newFeeBasisPoints);
    }


    // --- Asset Management (ERC-20 & ERC-721) ---

    /// @notice Deposits ERC-20 tokens into the vault.
    /// @param token The address of the ERC-20 token.
    /// @param amount The amount of tokens to deposit.
    function depositERC20(address token, uint256 amount) external payable whenNotPaused checkReputation(msg.sender) {
        StateParameters memory currentParams = stateConfigs[currentVaultState];
        if (!currentParams.allowERC20Deposits) revert DepositNotAllowedInState();
        if (currentParams.maxDepositAmount > 0 && amount > currentParams.maxDepositAmount) revert DepositAmountExceedsLimit(currentParams.maxDepositAmount);

        // Calculate fee
        uint256 totalFeeBasisPoints = currentParams.depositFeeBasisPoints + dynamicFeeBasisPoints;
        uint256 feeAmount = (amount * totalFeeBasisPoints) / 10000;
        uint256 amountAfterFee = amount - feeAmount;

        // Transfer tokens
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // Note: The fee is implicitly kept by the contract by transferring the full amount
        // and only conceptually applying the fee to the depositor's *intent*.
        // If fees were to be transferred elsewhere or burned, that logic would go here.

        emit ERC20Deposited(token, msg.sender, amount, feeAmount);
        // Actual usable balance in the vault is `amountAfterFee` for the depositor's virtual balance/share,
        // but the contract holds the full `amount`. Vault logic must track this.
        // For this conceptual contract, we track the gross deposit.
    }

    /// @notice Withdraws ERC-20 tokens from the vault.
    /// @param token The address of the ERC-20 token.
    /// @param amount The amount of tokens to withdraw.
    function withdrawERC20(address token, uint256 amount) external payable whenNotPaused checkReputation(msg.sender) hasPermission(this.withdrawERC20.selector) {
        StateParameters memory currentParams = stateConfigs[currentVaultState];
        if (!currentParams.allowERC20Withdrawals) revert WithdrawalNotAllowedInState();
        if (currentParams.maxWithdrawalAmount > 0 && amount > currentParams.maxWithdrawalAmount) revert WithdrawalAmountExceedsLimit(currentParams.maxWithdrawalAmount);
        // Add checks here against user's virtual balance if using a share/balance model

        // Calculate fee
        uint256 totalFeeBasisPoints = currentParams.withdrawalFeeBasisPoints + dynamicFeeBasisPoints;
        uint256 feeAmount = (amount * totalFeeBasisPoints) / 10000;
        uint256 amountAfterFee = amount - feeAmount;

        // Transfer tokens
        IERC20(token).safeTransfer(msg.sender, amountAfterFee); // Transfer amount AFTER fee

        // Note: The fee amount remains in the vault.

        emit ERC20WithdrawalInitiated(token, msg.sender, amount, feeAmount);
    }

    /// @notice Deposits an ERC-721 token into the vault.
    /// @param token The address of the ERC-721 token.
    /// @param tokenId The ID of the token to deposit.
    function depositERC721(address token, uint256 tokenId) external payable whenNotPaused checkReputation(msg.sender) {
        StateParameters memory currentParams = stateConfigs[currentVaultState];
        if (!currentParams.allowERC721Deposits) revert DepositNotAllowedInState();

        IERC721(token).safeTransferFrom(msg.sender, address(this), tokenId);
        erc721Holdings[token][tokenId] = true;
        erc721TokenCount[token]++;

        emit ERC721Deposited(token, tokenId, msg.sender);
    }

    /// @notice Withdraws an ERC-721 token from the vault.
    /// @param token The address of the ERC-721 token.
    /// @param tokenId The ID of the token to withdraw.
    function withdrawERC721(address token, uint256 tokenId) external payable whenNotPaused checkReputation(msg.sender) hasPermission(this.withdrawERC721.selector) {
        StateParameters memory currentParams = stateConfigs[currentVaultState];
        if (!currentParams.allowERC721Withdrawals) revert WithdrawalNotAllowedInState();
        if (!erc721Holdings[token][tokenId]) revert ERC721NotOwnedByVault();

        erc721Holdings[token][tokenId] = false;
        erc721TokenCount[token]--;
        IERC721(token).safeTransferFrom(address(this), msg.sender, tokenId);

        // Note: Fees on NFTs are complex. Could require payment in ERC20/ETH separately.
        // This example omits NFT fees for simplicity.

        emit ERC721WithdrawalInitiated(token, tokenId, msg.sender);
    }


    // --- Conditional Deposits (Superposition) ---

    /// @notice Deposits assets that are locked until a specific time and condition hash are met.
    /// @param assetContract The address of the asset contract (ERC20 or ERC721).
    /// @param amountOrTokenId The amount for ERC20, or token ID for ERC721.
    /// @param isERC721 True if depositing an ERC721, false for ERC20.
    /// @param unlockTime Unix timestamp after which resolution is possible.
    /// @param conditionHash A bytes32 hash representing the off-chain condition to be met.
    function depositSuperposition(
        address assetContract,
        uint256 amountOrTokenId,
        bool isERC721,
        uint256 unlockTime,
        bytes32 conditionHash
    ) external payable whenNotPaused checkReputation(msg.sender) {
        // Basic checks
        if (conditionHash == bytes32(0)) revert InvalidConditionalDeposit();
         // Ensure the condition hash isn't already used for an unresolved deposit
        if (conditionalDeposits[conditionHash].depositor != address(0)) revert InvalidConditionalDeposit();

        // Transfer assets into the vault
        if (isERC721) {
             IERC721(assetContract).safeTransferFrom(msg.sender, address(this), amountOrTokenId);
             // Note: ERC721s are tracked by vault ownership, but the conditional deposit records *who* can claim it.
             // Need to prevent standard withdrawal of this token ID while in superposition.
             // (This requires additional tracking beyond erc721Holdings, omitted for brevity in this example).
        } else {
            IERC20(assetContract).safeTransferFrom(msg.sender, address(this), amountOrTokenId);
             // Note: ERC20s are fungible. The vault holds the total balance,
             // but the conditional deposit records the *amount* claimable for this condition.
             // Need to ensure vault has enough balance when resolving.
        }

        // Store conditional deposit details
        conditionalDeposits[conditionHash] = ConditionalDeposit({
            depositor: msg.sender,
            assetContract: assetContract,
            amountOrTokenId: amountOrTokenId,
            isERC721: isERC721,
            unlockTime: unlockTime,
            conditionHash: conditionHash,
            resolved: false
        });

        depositorConditionalHashes[msg.sender].push(conditionHash);

        emit SuperpositionDepositLocked(conditionHash, msg.sender, assetContract, amountOrTokenId, isERC721);
    }

    /// @notice Attempts to resolve a conditional deposit and release assets.
    /// @param conditionHash The hash identifying the conditional deposit.
    /// @param conditionProof Placeholder for off-chain proof (verification logic is simulated).
    function resolveSuperposition(bytes32 conditionHash, bytes memory conditionProof) external payable whenNotPaused checkReputation(msg.sender) {
        ConditionalDeposit storage dep = conditionalDeposits[conditionHash];

        if (dep.depositor == address(0) || dep.resolved) revert InvalidConditionalDeposit();
        if (block.timestamp < dep.unlockTime) revert ConditionalDepositNotReady(dep.unlockTime);

        // --- Simulated Condition Verification ---
        // In a real contract, this would involve:
        // 1. Hashing the conditionProof + known parameters to verify it matches `conditionHash`.
        // 2. Potentially interacting with an oracle or verifying a ZK-SNARK proof.
        // For this example, we just check if conditionProof is non-empty (minimal simulation).
        if (conditionProof.length == 0) revert InvalidConditionProof();
        // A real implementation would perform complex checks here!

        // --- End Simulated Condition Verification ---

        // Mark as resolved
        dep.resolved = true;

        // Transfer assets back to the original depositor (or another specified receiver?)
        // For simplicity, we transfer back to the original depositor.
        address receiver = dep.depositor;

        if (dep.isERC721) {
             // Ensure vault still holds the NFT
            if (!erc721Holdings[dep.assetContract][dep.amountOrTokenId]) revert ERC721NotOwnedByVault(); // Should not happen if tracking is correct
            erc721Holdings[dep.assetContract][dep.amountOrTokenId] = false; // Update vault tracking
            erc721TokenCount[dep.assetContract]--;
            IERC721(dep.assetContract).safeTransferFrom(address(this), receiver, dep.amountOrTokenId);
        } else {
            // Ensure vault has sufficient balance ( ERC20s are fungible)
            if (IERC20(dep.assetContract).balanceOf(address(this)) < dep.amountOrTokenId) {
                // This indicates a potential issue - vault balance fell below locked amount.
                // A real system needs mechanisms to prevent this (e.g., reserve pool).
                 revert InsufficientReputation(); // Re-using error as a placeholder for "vault has issues"
            }
             IERC20(dep.assetContract).safeTransfer(receiver, dep.amountOrTokenId);
        }

        emit SuperpositionDepositResolved(conditionHash, receiver, dep.amountOrTokenId);
    }

    /// @notice View function to check the status of a conditional deposit.
    /// @param conditionHash The hash identifying the conditional deposit.
    /// @return A tuple containing deposit details and resolved status.
    function getConditionalDepositStatus(bytes32 conditionHash) public view returns (ConditionalDeposit memory) {
        return conditionalDeposits[conditionHash];
    }


    // --- Access Control & Permissions ---

    /// @notice Grants or revokes general permission for a user to call a specific function by selector.
    /// @param user The address to grant/revoke permission for.
    /// @param functionSelector The function selector (e.g., `this.withdrawERC20.selector`).
    /// @param allowed True to grant, false to revoke.
    function grantFunctionPermission(address user, bytes4 functionSelector, bool allowed) external onlyOwner {
        functionPermissions[user][functionSelector] = allowed;
        emit FunctionPermissionGranted(user, functionSelector, allowed);
    }

     /// @notice Delegates permission for specific functions to another address with a daily call limit.
     /// @param delegate The address receiving delegated permission.
     /// @param selectors An array of function selectors the delegate is allowed to call.
     /// @param dailyCallLimit The maximum number of calls per selector per day (0 for unlimited within the daily reset).
     function delegateManagementWithLimit(address delegate, bytes4[] calldata selectors, uint256 dailyCallLimit) external onlyOwner {
        for (uint i = 0; i < selectors.length; i++) {
            delegatedPermissions[delegate][selectors[i]] = true;
            delegatedCallLimits[delegate][selectors[i]] = dailyCallLimit;
            // Reset count for this delegate/selector when granting/updating
             delegatedCallCounts[delegate][selectors[i]] = 0; // Initialize count for the *current* day segment
        }
        emit ManagementDelegated(delegate, selectors, dailyCallLimit);
     }

    /// @notice Revokes all delegated management permissions for an address.
    /// @param delegate The address whose delegation is revoked.
    function revokeDelegatedManagement(address delegate) external onlyOwner {
        // Note: Revoking requires iterating through all granted selectors for this delegate.
        // This can be gas-intensive if many functions were delegated.
        // For simplicity in this example, we'll just mark the delegate as revoked conceptually,
        // but a real implementation needs to clear the specific delegatedPermissions map entries.
        // A mapping from delegate to an array of selectors would be needed, or external tracking.
         // We'll emit the event assuming the permissions are cleared.
         // A real implementation would need to clear delegatedPermissions[delegate][selector] for each selector.
        // Example (requires storing the selectors granted to each delegate):
        /*
        bytes4[] memory grantedSelectors = delegatedSelectorList[delegate];
        for(uint i=0; i<grantedSelectors.length; i++) {
            delegatedPermissions[delegate][grantedSelectors[i]] = false;
            delegatedCallLimits[delegate][grantedSelectors[i]] = 0;
            delegatedCallCounts[delegate][grantedSelectors[i]] = 0;
        }
        delete delegatedSelectorList[delegate];
        */
         emit ManagementDelegationRevoked(delegate);
    }

    // --- Reputation System (Simulated) ---

    /// @notice Updates a user's simulated on-chain reputation score.
    /// @param user The address whose score is updated.
    /// @param newScore The new reputation score.
    function updateReputationScore(address user, uint256 newScore) external onlyOwner { // In a real system, this would be driven by complex logic or an oracle
        reputationScores[user] = newScore;
        emit ReputationScoreUpdated(user, newScore);
    }


    // --- Strategy Execution ---

    /// @notice Registers or de-registers a trusted strategy adapter contract address.
    /// @param adapter The address of the strategy adapter contract.
    /// @param allowed True to register, false to de-register.
    function registerStrategyAdapter(address adapter, bool allowed) external onlyOwner {
        registeredStrategyAdapters[adapter] = allowed;
        emit StrategyAdapterRegistered(adapter, allowed);
    }

    /// @notice Calls a registered strategy adapter contract with arbitrary data.
    /// @param adapter The address of the registered strategy adapter.
    /// @param data The calldata to forward to the adapter.
    function executeStrategy(address adapter, bytes calldata data) external payable whenNotPaused checkReputation(msg.sender) hasPermission(this.executeStrategy.selector) {
        if (!registeredStrategyAdapters[adapter]) revert AdapterNotRegistered(adapter);
        if (!stateConfigs[currentVaultState].allowStrategyExecution) revert InvalidState();

        (bool success, bytes memory returnData) = adapter.call(data);
        if (!success) {
            // Attempt to extract revert reason
            if (returnData.length > 0) {
                // This attempts to decode a standard Solidity revert reason string
                // which is encoded as Error(string) -> 0x08c379a0 + bytes4(keccak256("Error(string)")) + ABI-encoded string
                if (returnData.length >= 68 && returnData[0] == 0x08 && returnData[1] == 0xc3 && returnData[2] == 0x79 && returnData[3] == 0xa0) {
                     assembly {
                        let returnDataOffset := add(returnData, 0x20)
                        let returnDataSize := sub(mload(returnData), 0x4)
                        revert(returnDataOffset, returnDataSize)
                     }
                }
            }
             revert StrategyExecutionFailed(returnData);
        }
         emit StrategyExecuted(adapter, data);
    }


    // --- Emergency & Maintenance ---

    /// @notice Allows the emergency custodian or owner to withdraw a specific amount during emergency state.
    /// @param token The address of the ERC-20 token.
    /// @param amount The amount to withdraw.
    function panicWithdraw(address token, uint256 amount) external payable {
        if (msg.sender != emergencyCustodian && msg.sender != owner()) revert OnlyEmergencyCustodianOrOwner();
        if (currentVaultState != VaultState.Emergency) revert NotInEmergencyState();

        // Minimal checks - allows withdrawal even if paused or reputation is low
        // Does not respect withdrawal limits or fees

        IERC20(token).safeTransfer(msg.sender, amount);
        emit PanicWithdrawal(token, msg.sender, amount);
    }

    /// @notice Sets the address authorized for emergency actions.
    /// @param custodian The address to set as emergency custodian.
    function setEmergencyCustodian(address custodian) external onlyOwner {
        emit EmergencyCustodianSet(emergencyCustodian, custodian);
        emergencyCustodian = custodian;
    }

    /// @notice Pauses most interactions with the vault. Only owner/emergency can unpause or panicWithdraw.
    function pauseVaultOperations() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses the vault.
    function unpauseVaultOperations() external onlyOwner {
        _unpause();
    }


    // --- Batch Operations ---

    /// @notice Executes multiple arbitrary calls from the vault's context.
    /// @dev Use with caution. Targets must be trusted.
    /// @param targets An array of target contract addresses.
    /// @param datas An array of calldata bytes for each target.
    function batchExecuteCalls(address[] calldata targets, bytes[] calldata datas) external payable whenNotPaused checkReputation(msg.sender) hasPermission(this.batchExecuteCalls.selector) {
        if (targets.length != datas.length) revert InvalidConditionalDeposit(); // Using existing error, ideally define new one
        if (targets.length == 0) return;

        emit BatchExecution(targets);

        for (uint i = 0; i < targets.length; i++) {
            (bool success, bytes memory returnData) = targets[i].call(datas[i]);
            if (!success) {
                // Log which call failed
                emit StrategyExecutionFailed(returnData); // Re-using event
                revert BatchExecutionFailed(targets[i], returnData); // Revert the whole batch
            }
        }
    }

    // --- Information & Query ---

    /// @notice View function to get the vault's balance of a specific ERC-20 token.
    /// @param token The address of the ERC-20 token.
    /// @return The balance held by the vault.
    function getERC20Balance(address token) public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    /// @notice View function to check if the vault owns a specific ERC-721 token ID.
    /// @param token The address of the ERC-721 token.
    /// @param tokenId The ID of the token.
    /// @return True if the vault owns the token, false otherwise.
    function getERC721Owner(address token, uint256 tokenId) public view returns (bool) {
         // Check internal tracking first for performance
        if (erc721Holdings[token][tokenId]) {
             // Optional: double check actual ownership if internal state might be stale
             // require(IERC721(token).ownerOf(tokenId) == address(this), "Vault tracking out of sync");
             return true;
        }
         return false;
    }

    /// @notice View function to get the current operational state of the vault.
    /// @return The current VaultState enum value.
    function getVaultState() public view returns (VaultState) {
        return currentVaultState;
    }

    /// @notice View function to retrieve parameters configured for a specific vault state.
    /// @param state The vault state to query.
    /// @return The StateParameters struct for the requested state.
    function getStateParameters(VaultState state) public view returns (StateParameters memory) {
        return stateConfigs[state];
    }

    /// @notice View function to get a user's simulated reputation score.
    /// @param user The address to query.
    /// @return The user's current reputation score.
    function getReputationScore(address user) public view returns (uint256) {
        return reputationScores[user];
    }

    /// @notice View function to check if a user has effective permission for a function, considering state and reputation.
    /// @param user The address to check.
    /// @param functionSelector The function selector to check.
    /// @return True if the user has permission, false otherwise.
    function checkPermission(address user, bytes4 functionSelector) public view returns (bool) {
        if (user == owner()) return true;
        bool granted = functionPermissions[user][functionSelector];
        bool delegated = delegatedPermissions[user][functionSelector];
        bool meetsStateReputation = reputationScores[user] >= stateConfigs[currentVaultState].minReputationRequired;

        // Note: This view function cannot check daily delegated call limits precisely
        // as it doesn't modify state (incrementing count). The `hasPermission` modifier does.
        // This view only reflects *if* they are generally allowed or delegated,
        // but not if they've hit their daily cap.
        return (granted || delegated) && meetsStateReputation;
    }

    /// @notice View function to retrieve the functions delegated to a specific address.
    /// @dev This function is conceptual. Storing and retrieving the *list* of delegated
    /// selectors requires a different data structure (e.g., mapping address to bytes4[]),
    /// which adds complexity for updates/revokes. This implementation implies
    /// checking per-selector. A more practical implementation might store the list.
    /// This stub returns an empty array.
    /// @param delegate The address to query.
    /// @return An array of function selectors delegated to the address.
    function getDelegatedPermissions(address delegate) public view returns (bytes4[] memory) {
        // Conceptual function: Retrieving the *list* of delegated selectors efficiently
        // requires additional data structures (e.g., mapping address => bytes4[]).
        // Checking individual delegatedPermissions[delegate][selector] is possible,
        // but returning *all* delegated selectors isn't trivial with the current structure.
        // This is a common trade-off in Solidity design.
        // For this example, we return an empty array.
        return new bytes4[](0);
    }

     /// @notice View function to get the current daily call count for a delegated function.
     /// @param delegate The address of the delegate.
     /// @param functionSelector The function selector.
     /// @return The number of times the delegate has called the function since the last reset.
     function getDelegatedCallCount(address delegate, bytes4 functionSelector) public view returns (uint256) {
         // This returns the count relative to the *last* reset timestamp.
         // The `hasPermission` modifier checks if a reset is *needed* based on the *current* block timestamp.
         // The interpretation of this count depends on whether the keeper has called resetDailyCallCounts recently.
        return delegatedCallCounts[delegate][functionSelector];
     }


    // Fallback/Receive functions (optional but good practice)
    receive() external payable {}
    fallback() external payable {}
}
```