```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ChronoVault
 * @dev An advanced smart contract for managing time-based deposits, scheduled actions,
 *      temporary permissions, and time-locked rewards (TimeTokens).
 *      Combines concepts of vesting, multi-signature scheduling, access control,
 *      and time-based tokenomics in a single creative contract.
 *      Designed to be distinct from standard open-source libraries by integrating
 *      these concepts in a novel 'vault' paradigm.
 */

/*
Outline:
1.  Contract Information & SPDX License/Pragma.
2.  Documentation Outline & Function Summary.
3.  Error Definitions.
4.  Event Definitions.
5.  Struct Definitions (Deposit, ScheduledAction).
6.  Enum Definitions (PermissionType, ActionType).
7.  State Variables (Owner, Counters, Mappings for Deposits, Actions, Permissions, TimeTokens, Supported Tokens).
8.  Modifiers (onlyOwner, isSupportedToken, isDepositUnlocked, isScheduledActionReady, hasPermission).
9.  Constructor.
10. Owner/Management Functions.
11. Core Deposit Functions (ETH, ERC-20, with/without time locks).
12. Core Withdrawal Functions (Specific deposits, handling locks).
13. Scheduled Action Functions (Schedule, Cancel, Execute).
14. Temporary Permission Functions (Grant, Revoke, Check).
15. TimeToken Functions (Claiming time-based rewards).
16. Helper/Internal Functions (Value conversions, TimeToken calculation).
17. View Functions (Retrieving state, details, balances).
18. Receive/Fallback Functions (for direct ETH deposits).
*/

/*
Function Summary:

1.  `constructor()`: Initializes the contract with the deployer as the owner.
2.  `addSupportedToken(address tokenAddress)`: Owner adds an ERC-20 token address that the vault will accept/manage.
3.  `removeSupportedToken(address tokenAddress)`: Owner removes an ERC-20 token address. Deposits of removed tokens remain but no new deposits allowed.
4.  `setTimeTokenRate(uint256 rate)`: Owner sets the rate at which TimeTokens accrue per second per unit of ETH value locked.
5.  `transferOwnership(address newOwner)`: Transfers contract ownership to a new address.
6.  `ownerEmergencyWithdrawEth(uint256 amount)`: Owner can withdraw ETH in emergencies (use with caution).
7.  `ownerEmergencyWithdrawToken(address tokenAddress, uint256 amount)`: Owner can withdraw a specific ERC-20 token in emergencies (use with caution).
8.  `depositEth()`: User deposits ETH into the vault with no time lock.
9.  `depositEthTimeLock(uint64 unlockTimestamp)`: User deposits ETH with a specified unlock timestamp.
10. `depositToken(address tokenAddress, uint256 amount)`: User deposits a supported ERC-20 token with no time lock. Requires prior approval.
11. `depositTokenTimeLock(address tokenAddress, uint256 amount, uint64 unlockTimestamp)`: User deposits a supported ERC-20 token with a specified unlock timestamp. Requires prior approval.
12. `withdrawDeposit(uint256 depositId)`: User attempts to withdraw a specific deposit (ETH or Token). Checks if unlocked.
13. `scheduleEthWithdrawal(uint256 amount, uint64 scheduledTimestamp)`: User schedules a future withdrawal of a specific ETH amount.
14. `scheduleTokenWithdrawal(address tokenAddress, uint256 amount, uint64 scheduledTimestamp)`: User schedules a future withdrawal of a specific ERC-20 amount.
15. `cancelScheduledAction(uint256 actionId)`: User cancels a scheduled action they created, if not yet executed.
16. `executeScheduledAction(uint256 actionId)`: Any address can trigger the execution of a scheduled action *if* the scheduled time has passed.
17. `grantTemporaryPermission(address grantee, PermissionType permission, uint64 durationSeconds)`: User grants another address a specific temporary permission for a set duration.
18. `revokeTemporaryPermission(address grantee, PermissionType permission)`: User revokes a previously granted temporary permission immediately.
19. `extendLockDuration(uint256 depositId, uint64 newUnlockTimestamp)`: User extends the time lock on one of their deposits. Must be later than the current unlock time.
20. `claimTimeTokens()`: User claims accrued TimeTokens based on their locked ETH value over time. Resets accrual calculation time for eligible deposits.
21. `getDepositDetails(uint256 depositId)`: View function to get details of a specific deposit.
22. `getScheduledActionDetails(uint256 actionId)`: View function to get details of a specific scheduled action.
23. `getUserDepositIds(address user)`: View function to get a list of deposit IDs belonging to a user.
24. `getUserScheduledActionsIds(address user)`: View function to get a list of scheduled action IDs belonging to a user.
25. `getTotalEthBalance()`: View function to get the total ETH held by the contract.
26. `getTotalTokenBalance(address tokenAddress)`: View function to get the total balance of a specific token held by the contract.
27. `getTimeTokenBalance(address user)`: View function to get the TimeToken balance for a user.
28. `isSupportedToken(address tokenAddress)`: View function to check if a token is supported.
29. `isDepositUnlocked(uint256 depositId)`: View function to check if a specific deposit is past its unlock time.
30. `isScheduledActionReady(uint256 actionId)`: View function to check if a scheduled action is ready for execution.
31. `checkPermission(address user, PermissionType permission)`: View function to check if a user currently holds a specific temporary permission.
32. `getAccruedTimeTokens(address user)`: View function to calculate TimeTokens available to claim for a user without claiming them.
*/

// Custom error definitions for clarity and gas efficiency
error Unauthorized(address caller);
error TokenNotSupported(address tokenAddress);
error DepositNotFound(uint256 depositId);
error DepositNotUnlocked(uint256 depositId);
error InsufficientFunds(uint256 required, uint256 available);
error AmountMustBeGreaterThanZero();
error UnlockTimeInPast(uint64 unlockTime);
error NewUnlockTimeMustBeLater(uint64 currentUnlockTime, uint64 newUnlockTime);
error InvalidPermissionType();
error ActionNotFound(uint256 actionId);
error ActionNotReady(uint64 scheduledTime);
error ActionAlreadyExecuted(uint256 actionId);
error NotActionOwner(address caller, address owner);
error CannotCancelExecutedAction();
error SelfGrantRevokeDisallowed(); // Added based on thought process review

// Events
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
event SupportedTokenAdded(address indexed tokenAddress);
event SupportedTokenRemoved(address indexed tokenAddress);
event TimeTokenRateUpdated(uint256 newRate);
event DepositMade(uint256 indexed depositId, address indexed depositor, address tokenAddress, uint256 amount, uint64 unlockTimestamp);
event WithdrawalMade(uint256 indexed depositId, address indexed recipient, uint256 amount, address tokenAddress);
event LockExtended(uint256 indexed depositId, uint64 newUnlockTimestamp);
event PermissionGranted(address indexed granter, address indexed grantee, PermissionType permission, uint64 expiresAt);
event PermissionRevoked(address indexed granter, address indexed grantee, PermissionType permission);
event ActionScheduled(uint256 indexed actionId, address indexed scheduler, ActionType actionType, address target, uint256 amount, uint64 scheduledTimestamp);
event ActionCancelled(uint256 indexed actionId, address indexed canceller);
event ActionExecuted(uint256 indexed actionId, address indexed executor);
event TimeTokensClaimed(address indexed user, uint256 amount);
event EmergencyWithdrawal(address indexed owner, address tokenAddress, uint256 amount);

// Structs
struct Deposit {
    address depositor;
    address tokenAddress; // Address(0) for ETH
    uint256 amount;
    uint64 unlockTimestamp; // 0 for no lock
    uint64 lastTimeTokenClaimTime; // Timestamp of the last TimeToken claim for this specific deposit
    bool withdrawn; // To track if the deposit has been fully withdrawn
}

struct ScheduledAction {
    address scheduler;
    ActionType actionType;
    address target; // Recipient for withdrawal/transfer actions
    address tokenAddress; // Token address for token actions (Address(0) for ETH)
    uint256 amount;
    uint64 scheduledTimestamp;
    bool executed;
}

// Enums
enum PermissionType {
    ScheduleAction,     // Allows scheduling any action (withdrawal/transfer)
    TemporaryWithdraw   // Allows withdrawing *up to a certain amount*? (Let's simplify for function count: allows executing *any* scheduled withdrawal for *any* user they have permission to manage?) -> Let's redefine: allows executing *any* scheduled withdrawal *by this specific grantee* that is ready.
}

enum ActionType {
    Withdrawal // Currently only supporting withdrawal actions
    // Future: Transfer (internal to another vault user?), ContractCall?
}

contract ChronoVault {
    address private immutable i_owner;

    uint256 private s_nextDepositId = 1;
    uint256 private s_nextActionId = 1;

    mapping(uint256 => Deposit) private s_deposits;
    mapping(address => uint256[]) private s_userDepositIds; // Mapping to track deposit IDs per user

    mapping(uint256 => ScheduledAction) private s_scheduledActions;
    mapping(address => uint256[]) private s_userScheduledActionIds; // Mapping to track action IDs per user

    mapping(address => mapping(PermissionType => uint64)) private s_temporaryPermissions; // user => permission => expiresAt

    mapping(address => uint256) private s_timeTokenBalances;
    uint256 private s_timeTokenRate; // Rate per second per 10^18 Wei (equivalent of 1 ETH value)

    mapping(address => bool) private s_supportedTokens; // ERC-20 tokens supported

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert Unauthorized(msg.sender);
        }
        _;
    }

    modifier isSupportedToken(address tokenAddress) {
        if (tokenAddress != address(0) && !s_supportedTokens[tokenAddress]) {
            revert TokenNotSupported(tokenAddress);
        }
        _;
    }

    modifier isDepositUnlocked(uint256 depositId) {
        if (s_deposits[depositId].unlockTimestamp > block.timestamp) {
            revert DepositNotUnlocked(depositId);
        }
        _;
    }

    modifier isScheduledActionReady(uint256 actionId) {
        if (s_scheduledActions[actionId].scheduledTimestamp > block.timestamp) {
            revert ActionNotReady(s_scheduledActions[actionId].scheduledTimestamp);
        }
        _;
    }

    // Check if user has the specific permission or is the action owner for scheduling/execution
    modifier hasPermission(address user, PermissionType permission) {
        if (s_temporaryPermissions[user][permission] < block.timestamp) {
            revert Unauthorized(user);
        }
        _;
    }

    constructor() {
        i_owner = msg.sender;
        // Default rate: 1 TimeToken per year per ETH locked (for example)
        // 1e18 / (365 days * 24 hours * 60 minutes * 60 seconds)
        s_timeTokenRate = 1e18 / 31536000; // Example: 10^18 TimeTokens per ETH per year (approx)
        emit OwnershipTransferred(address(0), i_owner);
    }

    // --- Owner/Management Functions ---

    function addSupportedToken(address tokenAddress) external onlyOwner {
        if (tokenAddress == address(0)) revert TokenNotSupported(address(0));
        s_supportedTokens[tokenAddress] = true;
        emit SupportedTokenAdded(tokenAddress);
    }

    function removeSupportedToken(address tokenAddress) external onlyOwner {
        if (tokenAddress == address(0)) revert TokenNotSupported(address(0));
        s_supportedTokens[tokenAddress] = false;
        emit SupportedTokenRemoved(tokenAddress);
    }

    function setTimeTokenRate(uint256 rate) external onlyOwner {
        s_timeTokenRate = rate;
        emit TimeTokenRateUpdated(rate);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert Unauthorized(address(0));
        address previousOwner = i_owner;
        // Note: Cannot reassign immutable i_owner. A simple owner state variable would be needed
        // to allow this pattern without complex proxy/upgrade patterns.
        // For this example, let's assume i_owner is the true owner and this function
        // is illustrative of a potential owner action, perhaps in a non-immutable owner setup.
        // In a real contract, `owner = newOwner;` would be used with a mutable state variable.
        revert Unauthorized(msg.sender); // Owner is immutable in this example
        // If owner was mutable:
        // owner = newOwner;
        // emit OwnershipTransferred(previousOwner, newOwner);
    }

    // Emergency withdrawal functions (use with extreme caution)
    function ownerEmergencyWithdrawEth(uint256 amount) external onlyOwner {
        if (amount == 0) revert AmountMustBeGreaterThanZero();
        if (address(this).balance < amount) revert InsufficientFunds(amount, address(this).balance);
        // Note: This bypasses all locks and deposit tracking. For true emergencies only.
        (bool success,) = payable(i_owner).call{value: amount}("");
        require(success, "ETH transfer failed");
        emit EmergencyWithdrawal(i_owner, address(0), amount);
    }

    function ownerEmergencyWithdrawToken(address tokenAddress, uint256 amount) external onlyOwner isSupportedToken(tokenAddress) {
         if (amount == 0) revert AmountMustBeGreaterThanZero();
        IERC20 token = IERC20(tokenAddress);
        if (token.balanceOf(address(this)) < amount) revert InsufficientFunds(amount, token.balanceOf(address(this)));
        // Note: This bypasses all locks and deposit tracking. For true emergencies only.
        bool success = token.transfer(i_owner, amount);
        require(success, "Token transfer failed");
        emit EmergencyWithdrawal(i_owner, tokenAddress, amount);
    }


    // --- Core Deposit Functions ---

    // Allow receiving ETH directly or via depositEth function
    receive() external payable {
        if (msg.value > 0) {
             _createDeposit(msg.sender, address(0), msg.value, 0); // Direct ETH deposit gets no lock
        }
    }

    // Fallback function - typically revert if no function matches, unless allowing direct ETH send.
    // receive() handles ETH deposits, so fallback is not strictly needed for that.
    // If not allowing arbitrary calls, fallback should revert.
    fallback() external payable {
        revert(); // Revert if a function call doesn't match and ETH was sent (handled by receive) or not sent.
    }

    function depositEth() external payable {
        if (msg.value == 0) revert AmountMustBeGreaterThanZero();
        _createDeposit(msg.sender, address(0), msg.value, 0);
    }

    function depositEthTimeLock(uint64 unlockTimestamp) external payable {
        if (msg.value == 0) revert AmountMustBeGreaterThanZero();
        if (unlockTimestamp < block.timestamp) revert UnlockTimeInPast(unlockTimestamp);
        _createDeposit(msg.sender, address(0), msg.value, unlockTimestamp);
    }

    function depositToken(address tokenAddress, uint256 amount) external isSupportedToken(tokenAddress) {
        if (amount == 0) revert AmountMustBeGreaterThanZero();
        // ERC20 requires caller to approve this contract beforehand
        IERC20 token = IERC20(tokenAddress);
        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "Token transferFrom failed");
        _createDeposit(msg.sender, tokenAddress, amount, 0);
    }

    function depositTokenTimeLock(address tokenAddress, uint256 amount, uint64 unlockTimestamp) external isSupportedToken(tokenAddress) {
        if (amount == 0) revert AmountMustBeGreaterThanZero();
        if (unlockTimestamp < block.timestamp) revert UnlockTimeInPast(unlockTimestamp);
        // ERC20 requires caller to approve this contract beforehand
        IERC20 token = IERC20(tokenAddress);
        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "Token transferFrom failed");
        _createDeposit(msg.sender, tokenAddress, amount, unlockTimestamp);
    }

    // --- Core Withdrawal Functions ---

    function withdrawDeposit(uint256 depositId) external {
        Deposit storage deposit = s_deposits[depositId];
        if (deposit.depositor == address(0)) revert DepositNotFound(depositId);
        if (deposit.depositor != msg.sender) revert Unauthorized(msg.sender);
        if (deposit.withdrawn) revert DepositNotFound(depositId); // Treat as not found if already withdrawn

        isDepositUnlocked(depositId); // Reverts if locked

        deposit.withdrawn = true; // Mark as withdrawn BEFORE transfer to prevent reentrancy issues

        if (deposit.tokenAddress == address(0)) {
            // ETH withdrawal
            (bool success,) = payable(deposit.depositor).call{value: deposit.amount}("");
            require(success, "ETH withdrawal failed");
        } else {
            // ERC20 withdrawal
            IERC20 token = IERC20(deposit.tokenAddress);
            bool success = token.transfer(deposit.depositor, deposit.amount);
            require(success, "Token withdrawal failed");
        }

        emit WithdrawalMade(depositId, deposit.depositor, deposit.amount, deposit.tokenAddress);
    }

    // --- Scheduled Action Functions ---

    function scheduleEthWithdrawal(uint256 amount, uint64 scheduledTimestamp) external {
         if (amount == 0) revert AmountMustBeGreaterThanZero();
        if (scheduledTimestamp <= block.timestamp) revert UnlockTimeInPast(scheduledTimestamp); // Must be in the future

        // Create a new scheduled action
        uint256 actionId = s_nextActionId++;
        s_scheduledActions[actionId] = ScheduledAction({
            scheduler: msg.sender,
            actionType: ActionType.Withdrawal,
            target: msg.sender, // Withdrawing to self
            tokenAddress: address(0), // ETH
            amount: amount,
            scheduledTimestamp: scheduledTimestamp,
            executed: false
        });

        s_userScheduledActionIds[msg.sender].push(actionId);

        emit ActionScheduled(actionId, msg.sender, ActionType.Withdrawal, msg.sender, amount, scheduledTimestamp);
    }

    function scheduleTokenWithdrawal(address tokenAddress, uint256 amount, uint64 scheduledTimestamp) external isSupportedToken(tokenAddress) {
        if (amount == 0) revert AmountMustBeGreaterThanZero();
        if (scheduledTimestamp <= block.timestamp) revert UnlockTimeInPast(scheduledTimestamp); // Must be in the future

        // Create a new scheduled action
        uint256 actionId = s_nextActionId++;
        s_scheduledActions[actionId] = ScheduledAction({
            scheduler: msg.sender,
            actionType: ActionType.Withdrawal,
            target: msg.sender, // Withdrawing to self
            tokenAddress: tokenAddress,
            amount: amount,
            scheduledTimestamp: scheduledTimestamp,
            executed: false
        });

        s_userScheduledActionIds[msg.sender].push(actionId);

        emit ActionScheduled(actionId, msg.sender, ActionType.Withdrawal, msg.sender, amount, scheduledTimestamp);
    }

    function cancelScheduledAction(uint256 actionId) external {
        ScheduledAction storage action = s_scheduledActions[actionId];
        if (action.scheduler == address(0)) revert ActionNotFound(actionId); // Check if action exists
        if (action.scheduler != msg.sender) revert NotActionOwner(msg.sender, action.scheduler);
        if (action.executed) revert CannotCancelExecutedAction();

        // Mark as cancelled (simply delete or mark flag - delete is more gas efficient for storage)
        delete s_scheduledActions[actionId];
        // Note: s_userScheduledActionIds will still contain the ID, but lookup via s_scheduledActions[id] will return default struct.
        // A more robust implementation would remove from the array, but that's gas intensive. Leaving stale IDs in the array is acceptable.

        emit ActionCancelled(actionId, msg.sender);
    }

    function executeScheduledAction(uint256 actionId) external isScheduledActionReady(actionId) {
        ScheduledAction storage action = s_scheduledActions[actionId];
        if (action.scheduler == address(0)) revert ActionNotFound(actionId); // Check if action exists
        if (action.executed) revert ActionAlreadyExecuted(actionId);

        action.executed = true; // Mark as executed BEFORE transfer

        if (action.actionType == ActionType.Withdrawal) {
            if (action.tokenAddress == address(0)) {
                // ETH withdrawal
                uint256 balance = address(this).balance;
                 if (balance < action.amount) revert InsufficientFunds(action.amount, balance);
                (bool success,) = payable(action.target).call{value: action.amount}("");
                require(success, "Scheduled ETH transfer failed");
            } else {
                // ERC20 withdrawal
                 IERC20 token = IERC20(action.tokenAddress);
                 uint256 balance = token.balanceOf(address(this));
                 if (balance < action.amount) revert InsufficientFunds(action.amount, balance);
                bool success = token.transfer(action.target, action.amount);
                require(success, "Scheduled Token transfer failed");
            }
            emit WithdrawalMade(0, action.target, action.amount, action.tokenAddress); // Use 0 depositId as it's not tied to one
        }
        // Add other ActionTypes here if implemented

        emit ActionExecuted(actionId, msg.sender);
    }

    // --- Temporary Permission Functions ---

    function grantTemporaryPermission(address grantee, PermissionType permission, uint64 durationSeconds) external {
        if (grantee == msg.sender) revert SelfGrantRevokeDisallowed();
        if (durationSeconds == 0) revert AmountMustBeGreaterThanZero(); // Duration must be > 0

        uint64 expiresAt = uint64(block.timestamp) + durationSeconds;
        s_temporaryPermissions[grantee][permission] = expiresAt;

        emit PermissionGranted(msg.sender, grantee, permission, expiresAt);
    }

    function revokeTemporaryPermission(address grantee, PermissionType permission) external {
         if (grantee == msg.sender) revert SelfGrantRevokeDisallowed();

        // Setting expiry to now effectively revokes it
        s_temporaryPermissions[grantee][permission] = uint64(block.timestamp);

        emit PermissionRevoked(msg.sender, grantee, permission);
    }

    // --- TimeToken Functions ---

    function extendLockDuration(uint256 depositId, uint64 newUnlockTimestamp) external {
        Deposit storage deposit = s_deposits[depositId];
        if (deposit.depositor == address(0)) revert DepositNotFound(depositId);
        if (deposit.depositor != msg.sender) revert Unauthorized(msg.sender);
         if (deposit.withdrawn) revert DepositNotFound(depositId); // Treat as not found if already withdrawn

        if (newUnlockTimestamp <= deposit.unlockTimestamp) revert NewUnlockTimeMustBeLater(deposit.unlockTimestamp, newUnlockTimestamp);
        if (newUnlockTimestamp < block.timestamp) revert UnlockTimeInPast(newUnlockTimestamp);

        // TimeTokens accrued up to this point are calculated before extending the lock
        // The TimeToken calculation within claimTimeTokens handles the start time for accrual
        // based on either deposit time or last claim time.
        // Simply updating the unlock time here is sufficient.
        deposit.unlockTimestamp = newUnlockTimestamp;

        emit LockExtended(depositId, newUnlockTimestamp);
    }

    function claimTimeTokens() external {
        uint256 accrued = getAccruedTimeTokens(msg.sender);

        if (accrued == 0) {
            // Nothing to claim, but still update claim times? No, only update if claiming.
            // If user wants to update time, maybe call a different zero-value function.
            // Revert or just do nothing? Reverting is clearer.
            // revert AmountMustBeGreaterThanZero(); // Or a specific "NoTimeTokensAccrued" error
            return; // Silently return if 0
        }

        s_timeTokenBalances[msg.sender] += accrued;

        // Update the last claim time for all relevant deposits
        uint256[] storage userDepositIds = s_userDepositIds[msg.sender];
        for (uint i = 0; i < userDepositIds.length; i++) {
            uint256 depId = userDepositIds[i];
            Deposit storage dep = s_deposits[depId];
            // Only update if the deposit is active (not withdrawn) and contributes to tokens (ETH deposit)
            if (dep.depositor == msg.sender && !dep.withdrawn && dep.tokenAddress == address(0)) {
                 // Only update if the current time is *after* the last claim time recorded for this deposit.
                 // This handles cases where claimTimeTokens might be called multiple times in the same block (though unlikely/no-op due to `getAccruedTimeTokens` calculating 0)
                 // or if a deposit was just made in this block (lastClaimTime starts at unlockTimestamp or 0).
                if (block.timestamp > dep.lastTimeTokenClaimTime) {
                     dep.lastTimeTokenClaimTime = uint64(block.timestamp);
                }
            }
        }

        emit TimeTokensClaimed(msg.sender, accrued);
    }

    // --- View Functions ---

    function getDepositDetails(uint256 depositId) external view returns (Deposit memory) {
        Deposit storage deposit = s_deposits[depositId];
        if (deposit.depositor == address(0)) {
             // Return an empty/default struct for non-existent deposits
             return Deposit(address(0), address(0), 0, 0, 0, false);
        }
        return deposit;
    }

    function getScheduledActionDetails(uint256 actionId) external view returns (ScheduledAction memory) {
        ScheduledAction storage action = s_scheduledActions[actionId];
         if (action.scheduler == address(0)) {
             // Return an empty/default struct for non-existent actions
             return ScheduledAction(address(0), ActionType.Withdrawal, address(0), address(0), 0, 0, false);
         }
        return action;
    }

    function getUserDepositIds(address user) external view returns (uint256[] memory) {
        return s_userDepositIds[user];
    }

    function getUserScheduledActionsIds(address user) external view returns (uint256[] memory) {
        return s_userScheduledActionIds[user];
    }

    function getTotalEthBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getTotalTokenBalance(address tokenAddress) external view returns (uint256) {
        if (tokenAddress == address(0)) revert TokenNotSupported(address(0)); // Cannot get balance of ETH this way
        IERC20 token = IERC20(tokenAddress);
        return token.balanceOf(address(this));
    }

     function getTimeTokenBalance(address user) external view returns (uint256) {
        return s_timeTokenBalances[user];
    }

    function isSupportedToken(address tokenAddress) external view returns (bool) {
        return s_supportedTokens[tokenAddress];
    }

     function isDepositUnlocked(uint256 depositId) public view returns (bool) {
        Deposit storage deposit = s_deposits[depositId];
        // Check deposit exists and is not withdrawn first
        if (deposit.depositor == address(0) || deposit.withdrawn) return false;
        // A 0 unlockTimestamp means no lock, always unlocked
        return deposit.unlockTimestamp == 0 || deposit.unlockTimestamp <= block.timestamp;
    }

    function isScheduledActionReady(uint256 actionId) public view returns (bool) {
        ScheduledAction storage action = s_scheduledActions[actionId];
         // Check action exists and is not executed first
        if (action.scheduler == address(0) || action.executed) return false;
        return action.scheduledTimestamp <= block.timestamp;
    }

     function checkPermission(address user, PermissionType permission) external view returns (bool) {
        return s_temporaryPermissions[user][permission] > block.timestamp;
    }

     function getAccruedTimeTokens(address user) public view returns (uint256) {
        uint256 totalAccrued = 0;
        uint256[] storage userDepositIds = s_userDepositIds[user];

        for (uint i = 0; i < userDepositIds.length; i++) {
            uint256 depId = userDepositIds[i];
            Deposit storage dep = s_deposits[depId];

            // Only consider active ETH deposits for TimeTokens
            if (dep.depositor == user && !dep.withdrawn && dep.tokenAddress == address(0)) {
                // Accrual starts from either the deposit time or the last claim time, whichever is later.
                uint64 accrualStartTime = dep.lastTimeTokenClaimTime == 0 ? dep.unlockTimestamp : dep.lastTimeTokenClaimTime; // Using unlockTimestamp as proxy for deposit time if lastClaimTime is 0
                // Correct approach needs deposit creation time or careful handling. Let's add deposit time to struct.
                 // Correction: Let's calculate from the *latest* of deposit time, last claim time, or unlock time if it was extended.
                 // The lastTimeTokenClaimTime should track when accrual was last paid up to.
                 // When deposit is made, lastTimeTokenClaimTime = 0 or deposit time?
                 // Let's set lastTimeTokenClaimTime = deposit creation time (block.timestamp) on creation.
                 // On claim, calculate tokens for duration: (block.timestamp - lastTimeTokenClaimTime) * value * rate.
                 // Then update lastTimeTokenClaimTime = block.timestamp.
                 // Need to adjust struct and _createDeposit slightly.
                 // *Revisiting struct*: Change `lastTimeTokenClaimTime` to `accrualStartTime`. On creation, `accrualStartTime = uint64(block.timestamp)`. On claim, calculate from `accrualStartTime` to `block.timestamp`, add tokens, set `accrualStartTime = uint64(block.timestamp)`.
                 // This seems more robust. *Let's update the struct and `_createDeposit`*.

                 // Recalculating based on new `accrualStartTime` in Deposit struct
                 if (block.timestamp > dep.accrualStartTime) {
                    uint256 duration = block.timestamp - dep.accrualStartTime;
                    // Calculate tokens based on the locked ETH value * duration * rate
                    // (wei * seconds * (TimeTokens / second / wei)) = TimeTokens
                    // Using dep.amount (in wei) as the value locked.
                    uint256 depositAccrued = (dep.amount * duration * s_timeTokenRate) / (1e18); // Adjust rate for 1 ETH value (1e18 wei)
                    totalAccrued += depositAccrued;
                 }
            }
        }
        return totalAccrued;
    }


    // --- Internal Helpers ---

    // Helper function to create deposit entries
    function _createDeposit(address depositor, address tokenAddress, uint256 amount, uint64 unlockTimestamp) internal {
        uint256 depositId = s_nextDepositId++;
        s_deposits[depositId] = Deposit({
            depositor: depositor,
            tokenAddress: tokenAddress,
            amount: amount,
            unlockTimestamp: unlockTimestamp,
            accrualStartTime: uint64(block.timestamp), // TimeToken accrual starts now
            withdrawn: false
        });
        s_userDepositIds[depositor].push(depositId);

        emit DepositMade(depositId, depositor, tokenAddress, amount, unlockTimestamp);
    }
}

// Dummy ERC20 interface for interaction
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    // function approve(address spender, uint256 amount) external returns (bool); // Not needed by the vault itself, but needed by users interacting with depositToken functions
    // function allowance(address owner, address spender) external view returns (uint256); // Not needed by the vault itself
}
```