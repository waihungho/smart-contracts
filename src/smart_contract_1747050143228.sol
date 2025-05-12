Okay, here is a Solidity smart contract named `QuantumVault` that incorporates several advanced, creative, and trendy concepts. It combines secure storage (vault), flexible conditional release mechanisms (time, oracle, on-chain puzzle, multi-factor), delegation, partial claims, and structural modifications (split/merge), aiming for uniqueness and complexity beyond typical open-source examples.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// --- Outline ---
// 1.  **Title:** QuantumVault
// 2.  **Description:** A multi-faceted vault contract allowing deposit and conditional release of ETH and ERC20 tokens based on various "quantum" conditions (time, external data via oracle, on-chain puzzle, or a combination). Features include delegation of claim rights, partial claims, lock splitting/merging, and emergency owner withdrawal.
// 3.  **Core Components:**
//     *   Ownership and Access Control
//     *   ETH and ERC20 Deposit/Withdrawal
//     *   Lock Structures (defining conditions, amounts, claimants)
//     *   Conditional Logic Evaluation
//     *   Claiming Mechanisms
//     *   Delegation of Rights
//     *   Lock Manipulation (Split/Merge)
//     *   Protocol Fees
// 4.  **Key Concepts:**
//     *   **Conditional Release:** Funds unlocked only when specified criteria are met.
//     *   **Multiple Condition Types:** Time-based, Oracle-based (requires external data), Puzzle-based (requires solving an on-chain challenge).
//     *   **Multi-Condition Locks:** Require multiple criteria to be simultaneously met.
//     *   **On-chain Puzzle:** A simple verifiable puzzle (e.g., hash pre-image) integrated as an unlock condition.
//     *   **Partial Claims:** Ability to withdraw portions of a lock amount over time or in multiple transactions once conditions are met.
//     *   **Claim Delegation:** Original claimant can delegate their right to another address.
//     *   **Lock Restructuring:** Splitting one lock into two, merging two locks into one.
//     *   **Oracle Integration (Simulated):** An interface for interacting with external data feeds.
//     *   **Protocol Fees:** Configurable fee taken upon successful claims.

// --- Function Summary ---
// 1.  `constructor(address initialOracle)`: Initializes the contract owner and default oracle address.
// 2.  `depositToken(address tokenAddress, uint256 amount)`: Allows users to deposit ERC20 tokens into the vault.
// 3.  `depositETH()`: Allows users to deposit Ether into the vault.
// 4.  `withdrawOwnerEmergency(address tokenAddress, uint256 amount)`: Owner can emergency withdraw a specific amount of an ERC20 token.
// 5.  `withdrawOwnerEmergencyETH(uint256 amount)`: Owner can emergency withdraw a specific amount of ETH.
// 6.  `getBalance(address tokenAddress)`: Returns the contract's balance of a specific ERC20 token.
// 7.  `getETHBalance()`: Returns the contract's balance of Ether.
// 8.  `createTimeLock(address tokenAddress, uint256 amount, address claimant, uint256 unlockTime)`: Creates a lock that unlocks after a specific timestamp.
// 9.  `createOracleLock(address tokenAddress, uint256 amount, address claimant, address oracleAddress, bytes dataFeedId, int256 threshold, uint8 comparisonType)`: Creates a lock based on an oracle data feed value meeting a threshold comparison.
// 10. `createPuzzleLock(address tokenAddress, uint256 amount, address claimant, bytes32 puzzleTargetHash)`: Creates a lock requiring the claimant to provide the pre-image of a target hash.
// 11. `createMultiConditionLock(address tokenAddress, uint256 amount, address claimant, Condition[] conditions)`: Creates a lock requiring multiple conditions to be met simultaneously.
// 12. `modifyLockClaimant(uint256 lockId, address newClaimant)`: Allows the original claimant (or owner) to change the authorized claimant for a lock.
// 13. `cancelLock(uint256 lockId)`: Allows the owner to cancel a lock, making funds available for owner withdrawal or redistribution.
// 14. `getLockDetails(uint256 lockId)`: Returns the details of a specific lock. (View function)
// 15. `checkLockConditionsMet(uint256 lockId)`: Checks and returns whether the conditions for a specific lock are currently met. (View function)
// 16. `attemptUnlock(uint256 lockId, bytes calldata puzzleSolution)`: Attempts to claim the *entire* remaining amount of a lock if conditions are met. Requires puzzle solution for puzzle locks.
// 17. `claimPartial(uint256 lockId, uint256 amountToClaim, bytes calldata puzzleSolution)`: Attempts to claim a *partial* amount from a lock if conditions are met and the amount hasn't been fully claimed. Requires puzzle solution for puzzle locks.
// 18. `delegateClaimRight(uint256 lockId, address newDelegate)`: Allows the current claimant to delegate their claim right to another address.
// 19. `revokeClaimRight(uint256 lockId)`: Allows the current claimant to revoke any active delegation, restoring claim rights to themselves.
// 20. `isEligibleToClaim(uint256 lockId, address potentialClaimant)`: Checks if an address is authorized to claim a specific lock (original claimant or delegate). (View function)
// 21. `updateDefaultOracle(address newOracle)`: Allows the owner to update the contract's default oracle address for *future* locks.
// 22. `setProtocolFeeRate(uint256 feeRatePermil)`: Allows the owner to set the protocol fee rate (in permil, e.g., 10 for 1%).
// 23. `withdrawProtocolFees(address tokenAddress)`: Allows the owner to withdraw accumulated protocol fees for a specific token.
// 24. `splitLock(uint256 lockId, uint256 amountForNewLock, Condition[] newLockConditions)`: Splits a lock into two: the original lock with reduced amount, and a new lock with the specified amount and (potentially different) conditions.
// 25. `mergeLocks(uint256 lockId1, uint256 lockId2)`: Merges the amounts and conditions of two locks into a single new lock.
// 26. `executeConditionalAction(uint256 lockId)`: Triggers a predefined internal action or state change if the conditions of a specific lock are met (without transferring funds).

// --- Interface for a simple Oracle (Simulated) ---
// In a real-world scenario, you would use Chainlink Price Feeds or another reliable oracle.
// This is a simplified interface for demonstration purposes.
interface ISimpleOracle {
    // Represents a data feed ID - could be bytes32 or other identifier
    // Function to get the latest price or data value
    // Assumes dataFeedId identifies the specific data stream (e.g., "ETH/USD")
    function latestAnswer(bytes calldata dataFeedId) external view returns (int256);
}

contract QuantumVault is ReentrancyGuard {
    address public owner;
    uint256 private nextLockId;
    ISimpleOracle public defaultOracle;

    // Define the types of conditions
    enum ConditionType {
        None,
        Time,
        Oracle,
        Puzzle
    }

    // Define comparison types for Oracle conditions
    enum ComparisonType {
        GreaterThan, // >
        LessThan,    // <
        EqualTo      // ==
    }

    // Structure for a single unlock condition
    struct Condition {
        ConditionType conditionType;
        uint256 uintParam;   // e.g., unlockTime
        address addressParam; // e.g., oracleAddress
        bytes bytesParam;    // e.g., dataFeedId
        int256 intParam;    // e.g., threshold
        bytes32 bytes32Param; // e.g., puzzleTargetHash
        ComparisonType comparisonType; // for Oracle condition
    }

    // Structure for a single lock entry
    struct Lock {
        uint256 id;
        address originalCreator; // Who deposited/created the lock
        address claimant;        // Who is authorized to claim (can be delegated)
        address tokenAddress;    // Address of the ERC20 token, or address(0) for ETH
        uint256 totalAmount;     // Total amount initially locked
        uint256 claimedAmount;   // Amount already claimed from this lock
        bool isCancelled;        // True if the lock was cancelled by owner
        bool isMerged;           // True if this lock was merged into another
        Condition[] conditions;  // Array of conditions (AND logic: all must be met)
        address currentDelegate; // Address delegated to claim (address(0) if no delegate)
    }

    mapping(uint256 => Lock) public locks;
    mapping(address => uint256) private tokenBalances; // Contract's balance per token
    uint256 private ethBalance;
    mapping(address => uint256) private protocolFeeBalances; // Accumulated fees per token

    uint256 public protocolFeeRatePermil = 0; // Fee rate in permil (1000 = 100%, 10 = 1%)
    address public feeRecipient;

    // --- Events ---
    event LockCreated(uint256 lockId, address originalCreator, address claimant, address tokenAddress, uint256 amount, Condition[] conditions);
    event LockCancelled(uint256 lockId, address indexed owner);
    event FundsUnlocked(uint256 lockId, address indexed claimant, address tokenAddress, uint256 amount);
    event PartialClaim(uint256 lockId, address indexed claimant, address tokenAddress, uint256 amountClaimed, uint256 remainingAmount);
    event ClaimRightDelegated(uint256 lockId, address indexed delegator, address indexed newDelegate);
    event ClaimRightRevoked(uint256 lockId, address indexed delegator, address indexed previousDelegate);
    event LockSplit(uint256 originalLockId, uint256 newLockId, uint256 amountMoved);
    event LockMerged(uint256 lockId1, uint256 lockId2, uint256 newLockId);
    event Deposit(address indexed depositor, address tokenAddress, uint256 amount);
    event ETHDeposit(address indexed depositor, uint256 amount);
    event OwnerEmergencyWithdraw(address indexed owner, address tokenAddress, uint256 amount);
    event OwnerEmergencyWithdrawETH(address indexed owner, uint256 amount);
    event ProtocolFeeRateUpdated(uint256 newRatePermil);
    event ProtocolFeesWithdrawn(address indexed recipient, address tokenAddress, uint256 amount);
    event ConditionalActionExecuted(uint256 lockId);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyClaimantOrDelegate(uint256 lockId) {
        require(
            msg.sender == locks[lockId].claimant ||
            msg.sender == locks[lockId].currentDelegate,
            "Not authorized claimant or delegate"
        );
        _;
    }

    modifier lockExistsAndActive(uint256 lockId) {
        require(lockId > 0 && lockId <= nextLockId && locks[lockId].id != 0, "Lock does not exist");
        require(!locks[lockId].isCancelled, "Lock is cancelled");
        require(!locks[lockId].isMerged, "Lock is merged");
        _;
    }

    // --- Constructor ---
    constructor(address initialOracle) {
        owner = msg.sender;
        nextLockId = 1; // Start lock IDs from 1
        // Initialize default oracle if provided, otherwise allow owner to set later
        if (initialOracle != address(0)) {
            defaultOracle = ISimpleOracle(initialOracle);
        }
        feeRecipient = msg.sender; // Owner is default fee recipient
    }

    // --- Fallback and Receive to accept ETH ---
    receive() external payable nonReentrant {
        ethBalance += msg.value;
        emit ETHDeposit(msg.sender, msg.value);
    }

    // Fallback function is not strictly needed if receive() is present and handles ETH,
    // but can be included for clarity or if receive() is removed.
    // fallback() external payable {
    //     // Optional: Add specific logic if needed for calls with data but no matching function
    //     ethBalance += msg.value;
    //     emit ETHDeposit(msg.sender, msg.value);
    // }

    // --- Deposit Functions ---
    function depositToken(address tokenAddress, uint256 amount) external nonReentrant {
        require(tokenAddress != address(0), "Invalid token address");
        require(amount > 0, "Amount must be greater than 0");

        // Transfer tokens from the sender to the contract
        IERC20 token = IERC20(tokenAddress);
        uint256 balanceBefore = token.balanceOf(address(this));
        token.transferFrom(msg.sender, address(this), amount);
        uint256 balanceAfter = token.balanceOf(address(this));
        uint256 actualAmount = balanceAfter - balanceBefore; // Account for potential transfer fees/precision issues

        require(actualAmount >= amount, "Token transfer failed or insufficient allowance");

        tokenBalances[tokenAddress] += actualAmount;
        emit Deposit(msg.sender, tokenAddress, actualAmount);
    }

    // DepositETH is handled by the receive() function

    // --- Owner Emergency Withdrawals ---
    function withdrawOwnerEmergency(address tokenAddress, uint256 amount) external onlyOwner nonReentrant {
        require(tokenAddress != address(0), "Invalid token address");
        require(amount > 0, "Amount must be greater than 0");
        require(tokenBalances[tokenAddress] >= amount, "Insufficient token balance in contract");

        IERC20 token = IERC20(tokenAddress);
        tokenBalances[tokenAddress] -= amount;
        token.transfer(owner, amount);

        emit OwnerEmergencyWithdraw(owner, tokenAddress, amount);
    }

    function withdrawOwnerEmergencyETH(uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(ethBalance >= amount, "Insufficient ETH balance in contract");

        ethBalance -= amount;
        (bool success, ) = owner.call{value: amount}("");
        require(success, "ETH transfer failed");

        emit OwnerEmergencyWithdrawETH(owner, amount);
    }

    // --- Balance Check Functions ---
    function getBalance(address tokenAddress) external view returns (uint256) {
        return tokenBalances[tokenAddress];
    }

    function getETHBalance() external view returns (uint256) {
        return address(this).balance; // Use address(this).balance for accuracy with receive()
    }

    // --- Lock Creation Functions ---

    function createTimeLock(
        address tokenAddress,
        uint256 amount,
        address claimant,
        uint256 unlockTime
    ) external onlyOwner nonReentrant returns (uint256 lockId) {
        require(amount > 0, "Amount must be greater than 0");
        require(claimant != address(0), "Invalid claimant address");
        // No specific require for unlockTime > block.timestamp, allows creating future locks
        // require(unlockTime > block.timestamp, "Unlock time must be in the future"); // Optional

        lockId = nextLockId++;
        Condition[] memory conditions = new Condition[](1);
        conditions[0] = Condition({
            conditionType: ConditionType.Time,
            uintParam: unlockTime,
            addressParam: address(0),
            bytesParam: "",
            intParam: 0,
            bytes32Param: bytes32(0),
            comparisonType: ComparisonType.GreaterThan // Not used for time
        });

        _createLock(lockId, tokenAddress, amount, claimant, conditions);
        return lockId;
    }

    function createOracleLock(
        address tokenAddress,
        uint256 amount,
        address claimant,
        address oracleAddress, // Specific oracle for this lock, or use defaultOracle
        bytes dataFeedId,
        int256 threshold,
        uint8 comparisonType // 0: >, 1: <, 2: ==
    ) external onlyOwner nonReentrant returns (uint256 lockId) {
        require(amount > 0, "Amount must be greater than 0");
        require(claimant != address(0), "Invalid claimant address");
        require(oracleAddress != address(0), "Invalid oracle address");
        require(bytes(dataFeedId).length > 0, "Invalid data feed ID");
        require(comparisonType <= uint8(ComparisonType.EqualTo), "Invalid comparison type");

        lockId = nextLockId++;
        Condition[] memory conditions = new Condition[](1);
        conditions[0] = Condition({
            conditionType: ConditionType.Oracle,
            uintParam: 0, // Not used for oracle
            addressParam: oracleAddress,
            bytesParam: dataFeedId,
            intParam: threshold,
            bytes32Param: bytes32(0),
            comparisonType: ComparisonType(comparisonType)
        });

        _createLock(lockId, tokenAddress, amount, claimant, conditions);
        return lockId;
    }

    function createPuzzleLock(
        address tokenAddress,
        uint256 amount,
        address claimant,
        bytes32 puzzleTargetHash // e.g., keccak256(abi.encodePacked(secret_solution))
    ) external onlyOwner nonReentrant returns (uint256 lockId) {
        require(amount > 0, "Amount must be greater than 0");
        require(claimant != address(0), "Invalid claimant address");
        require(puzzleTargetHash != bytes32(0), "Invalid puzzle target hash");

        lockId = nextLockId++;
        Condition[] memory conditions = new Condition[](1);
        conditions[0] = Condition({
            conditionType: ConditionType.Puzzle,
            uintParam: 0, // Not used for puzzle
            addressParam: address(0),
            bytesParam: "",
            intParam: 0,
            bytes32Param: puzzleTargetHash,
            comparisonType: ComparisonType.GreaterThan // Not used for puzzle
        });

        _createLock(lockId, tokenAddress, amount, claimant, conditions);
        return lockId;
    }

    function createMultiConditionLock(
        address tokenAddress,
        uint256 amount,
        address claimant,
        Condition[] calldata conditions // Use calldata for external calls
    ) external onlyOwner nonReentrant returns (uint256 lockId) {
        require(amount > 0, "Amount must be greater than 0");
        require(claimant != address(0), "Invalid claimant address");
        require(conditions.length > 0, "Must provide at least one condition");

        lockId = nextLockId++;
        _createLock(lockId, tokenAddress, amount, claimant, conditions); // _createLock copies calldata to memory

        return lockId;
    }

    function _createLock(
        uint256 lockId,
        address tokenAddress,
        uint256 amount,
        address claimant,
        Condition[] memory conditions // Use memory as it's called internally
    ) internal {
        // Verify sufficient balance is available
        if (tokenAddress == address(0)) {
            require(ethBalance >= amount, "Insufficient ETH balance in contract for lock");
            ethBalance -= amount;
        } else {
            require(tokenBalances[tokenAddress] >= amount, "Insufficient token balance in contract for lock");
            tokenBalances[tokenAddress] -= amount;
        }

        // Deep copy conditions array
        Condition[] memory conditionsCopy = new Condition[](conditions.length);
        for (uint i = 0; i < conditions.length; i++) {
            conditionsCopy[i] = conditions[i];
        }

        locks[lockId] = Lock({
            id: lockId,
            originalCreator: owner, // Owner creating the lock
            claimant: claimant,
            tokenAddress: tokenAddress,
            totalAmount: amount,
            claimedAmount: 0,
            isCancelled: false,
            isMerged: false,
            conditions: conditionsCopy,
            currentDelegate: address(0) // No delegation initially
        });

        emit LockCreated(lockId, owner, claimant, tokenAddress, amount, conditions);
    }

    // --- Lock Modification & Cancellation ---

    function modifyLockClaimant(uint256 lockId, address newClaimant) external lockExistsAndActive(lockId) nonReentrant {
        Lock storage lock = locks[lockId];
        // Only original claimant, delegate, or owner can modify claimant
        require(
            msg.sender == lock.claimant ||
            msg.sender == lock.currentDelegate ||
            msg.sender == owner,
            "Unauthorized to change claimant"
        );
        require(newClaimant != address(0), "Invalid new claimant address");

        // If there was a delegate, clear it first
        if (lock.currentDelegate != address(0)) {
             emit ClaimRightRevoked(lockId, msg.sender, lock.currentDelegate); // Log revocation
             lock.currentDelegate = address(0);
        }

        lock.claimant = newClaimant;
        // Note: No specific event for claimant change, but delegation events cover related actions.
        // Could add event LockClaimantUpdated(lockId, previousClaimant, newClaimant);
    }

    function cancelLock(uint256 lockId) external onlyOwner lockExistsAndActive(lockId) nonReentrant {
        Lock storage lock = locks[lockId];
        require(lock.claimedAmount == 0, "Cannot cancel a lock that has already been partially claimed");

        lock.isCancelled = true;

        // Return funds to owner's available balance (not part of any lock)
        uint256 remainingAmount = lock.totalAmount - lock.claimedAmount; // Should be totalAmount here
        if (lock.tokenAddress == address(0)) {
             ethBalance += remainingAmount;
        } else {
             tokenBalances[lock.tokenAddress] += remainingAmount;
        }

        emit LockCancelled(lockId, owner);
    }

    // --- Lock Information ---

    function getLockDetails(uint256 lockId)
        external
        view
        returns (
            uint256 id,
            address originalCreator,
            address claimant,
            address tokenAddress,
            uint256 totalAmount,
            uint256 claimedAmount,
            bool isCancelled,
            bool isMerged,
            Condition[] memory conditions,
            address currentDelegate
        )
    {
        require(lockId > 0 && lockId <= nextLockId && locks[lockId].id != 0, "Lock does not exist");
        Lock storage lock = locks[lockId];
        return (
            lock.id,
            lock.originalCreator,
            lock.claimant,
            lock.tokenAddress,
            lock.totalAmount,
            lock.claimedAmount,
            lock.isCancelled,
            lock.isMerged,
            lock.conditions,
            lock.currentDelegate
        );
    }

    function checkLockConditionsMet(uint256 lockId) public view lockExistsAndActive(lockId) returns (bool) {
        Lock storage lock = locks[lockId];
        return _checkConditionsMet(lock.conditions);
    }

    function _checkConditionsMet(Condition[] memory conditions) internal view returns (bool) {
        if (conditions.length == 0) {
            return true; // No conditions means always met
        }

        for (uint i = 0; i < conditions.length; i++) {
            Condition storage cond = conditions[i];
            bool met = false;
            if (cond.conditionType == ConditionType.Time) {
                met = block.timestamp >= cond.uintParam;
            } else if (cond.conditionType == ConditionType.Oracle) {
                ISimpleOracle oracle = cond.addressParam == address(0) ? defaultOracle : ISimpleOracle(cond.addressParam);
                require(address(oracle) != address(0), "Oracle not set for condition");
                try oracle.latestAnswer(cond.bytesParam) returns (int256 answer) {
                     if (cond.comparisonType == ComparisonType.GreaterThan) {
                         met = answer > cond.intParam;
                     } else if (cond.comparisonType == ComparisonType.LessThan) {
                         met = answer < cond.intParam;
                     } else if (cond.comparisonType == ComparisonType.EqualTo) {
                         met = answer == cond.intParam;
                     }
                } catch {
                    // Oracle call failed, condition is not met
                    met = false;
                }
            }
            // Puzzle condition cannot be checked in a view function as it requires external input (the solution)
            // It will be checked within attemptUnlock or claimPartial

            if (!met && cond.conditionType != ConditionType.Puzzle) {
                return false; // If any non-puzzle condition is not met, the lock is not unlocked
            }
            // If it's a puzzle condition, we assume it *can* be met if a solution is provided.
            // The actual check happens when the user attempts to unlock/claim with a solution.
        }
        return true; // All non-puzzle conditions are met (puzzle conditions need external input)
    }

     // Internal helper to check puzzle condition
    function _checkPuzzleCondition(Condition memory cond, bytes calldata puzzleSolution) internal pure returns (bool) {
        require(cond.conditionType == ConditionType.Puzzle, "Condition is not a puzzle type");
        return keccak256(puzzleSolution) == cond.bytes32Param;
    }

    // --- Claiming Functions ---

    function attemptUnlock(uint256 lockId, bytes calldata puzzleSolution) external lockExistsAndActive(lockId) nonReentrant {
        Lock storage lock = locks[lockId];
        require(isEligibleToClaim(lockId, msg.sender), "Caller is not authorized to claim this lock");
        require(lock.claimedAmount < lock.totalAmount, "Lock has already been fully claimed");

        // Check all conditions, including puzzle if present
        for (uint i = 0; i < lock.conditions.length; i++) {
            Condition storage cond = lock.conditions[i];
            if (cond.conditionType == ConditionType.Puzzle) {
                require(_checkPuzzleCondition(cond, puzzleSolution), "Puzzle solution is incorrect");
            } else {
                 // Non-puzzle conditions must be currently met (checked via _checkConditionsMet)
                 // This check should arguably be done *before* the loop for efficiency if possible,
                 // but the loop is needed to find puzzle conditions. Let's call the helper.
                 require(checkLockConditionsMet(lockId), "Other conditions are not met");
                 // The checkLockConditionsMet doesn't check puzzle, so we need both.
                 // A more robust check: iterate and check each condition type appropriately.
                 bool met = false;
                 if (cond.conditionType == ConditionType.Time) {
                    met = block.timestamp >= cond.uintParam;
                 } else if (cond.conditionType == ConditionType.Oracle) {
                    ISimpleOracle oracle = cond.addressParam == address(0) ? defaultOracle : ISimpleOracle(cond.addressParam);
                    require(address(oracle) != address(0), "Oracle not set for condition");
                    try oracle.latestAnswer(cond.bytesParam) returns (int256 answer) {
                         if (cond.comparisonType == ComparisonType.GreaterThan) { met = answer > cond.intParam; }
                         else if (cond.comparisonType == ComparisonType.LessThan) { met = answer < cond.intParam; }
                         else if (cond.comparisonType == ComparisonType.EqualTo) { met = answer == cond.intParam; }
                    } catch { met = false; }
                 }
                 require(met, "A non-puzzle condition is not met");
            }
        }

        // Conditions are met, transfer the remaining amount
        uint256 amountToTransfer = lock.totalAmount - lock.claimedAmount;
        require(amountToTransfer > 0, "No amount remaining to claim");

        lock.claimedAmount = lock.totalAmount; // Mark as fully claimed

        _performTransfer(lock.tokenAddress, msg.sender, amountToTransfer);

        emit FundsUnlocked(lockId, msg.sender, lock.tokenAddress, amountToTransfer);
    }

    function claimPartial(uint256 lockId, uint256 amountToClaim, bytes calldata puzzleSolution) external lockExistsAndActive(lockId) nonReentrant {
        Lock storage lock = locks[lockId];
        require(isEligibleToClaim(lockId, msg.sender), "Caller is not authorized to claim this lock");
        require(amountToClaim > 0, "Amount to claim must be greater than 0");
        uint256 remainingClaimable = lock.totalAmount - lock.claimedAmount;
        require(amountToClaim <= remainingClaimable, "Amount exceeds remaining claimable");

        // Check all conditions, including puzzle if present (same logic as attemptUnlock)
        for (uint i = 0; i < lock.conditions.length; i++) {
            Condition storage cond = lock.conditions[i];
            if (cond.conditionType == ConditionType.Puzzle) {
                require(_checkPuzzleCondition(cond, puzzleSolution), "Puzzle solution is incorrect");
            } else {
                 // Non-puzzle conditions must be currently met
                 bool met = false;
                 if (cond.conditionType == ConditionType.Time) {
                    met = block.timestamp >= cond.uintParam;
                 } else if (cond.conditionType == ConditionType.Oracle) {
                    ISimpleOracle oracle = cond.addressParam == address(0) ? defaultOracle : ISimpleOracle(cond.addressParam);
                    require(address(oracle) != address(0), "Oracle not set for condition");
                    try oracle.latestAnswer(cond.bytesParam) returns (int256 answer) {
                         if (cond.comparisonType == ComparisonType.GreaterThan) { met = answer > cond.intParam; }
                         else if (cond.comparisonType == ComparisonType.LessThan) { met = answer < cond.intParam; }
                         else if (cond.comparisonType == ComparisonType.EqualTo) { met = answer == cond.intParam; }
                    } catch { met = false; }
                 }
                 require(met, "A non-puzzle condition is not met");
            }
        }

        // Conditions are met, transfer the partial amount
        lock.claimedAmount += amountToClaim;

        _performTransfer(lock.tokenAddress, msg.sender, amountToClaim);

        emit PartialClaim(lockId, msg.sender, lock.tokenAddress, amountToClaim, lock.totalAmount - lock.claimedAmount);
    }

    // Internal helper for performing transfers with fee deduction
    function _performTransfer(address tokenAddress, address recipient, uint256 amount) internal nonReentrant {
        uint256 feeAmount = (amount * protocolFeeRatePermil) / 1000;
        uint256 netAmount = amount - feeAmount;

        if (tokenAddress == address(0)) { // ETH
             require(ethBalance >= amount, "Insufficient ETH balance for transfer"); // Check balance before reducing
             ethBalance -= amount;
             if (netAmount > 0) {
                 (bool success, ) = recipient.call{value: netAmount}("");
                 require(success, "ETH transfer failed");
             }
             if (feeAmount > 0 && feeRecipient != address(0)) {
                 // Transfer fee separately
                 (bool successFee, ) = feeRecipient.call{value: feeAmount}("");
                 // Consider logging failure or letting it revert - reverting is safer for fee collection
                 require(successFee, "ETH fee transfer failed");
             } else if (feeAmount > 0) {
                 // If feeRecipient is zero or not set, add fee back to general ETH balance
                 ethBalance += feeAmount;
             }

        } else { // ERC20 Token
             require(tokenBalances[tokenAddress] >= amount, "Insufficient token balance for transfer"); // Check balance before reducing
             tokenBalances[tokenAddress] -= amount;
             if (netAmount > 0) {
                 IERC20 token = IERC20(tokenAddress);
                 token.transfer(recipient, netAmount);
             }
             if (feeAmount > 0 && feeRecipient != address(0)) {
                 // Transfer fee separately
                 IERC20 token = IERC20(tokenAddress);
                 token.transfer(feeRecipient, feeAmount);
             } else if (feeAmount > 0) {
                // If feeRecipient is zero or not set, add fee back to general token balance
                tokenBalances[tokenAddress] += feeAmount;
             }
        }
         // Note: Fee balances tracking is done manually here for simplicity,
         // but withdrawing fees function `withdrawProtocolFees` uses this logic.
         // A more robust fee system might accumulate fees in a dedicated mapping first.
    }


    // --- Delegation Functions ---

    function delegateClaimRight(uint256 lockId, address newDelegate) external lockExistsAndActive(lockId) nonReentrant {
         Lock storage lock = locks[lockId];
         // Only the current claimant or owner can delegate
         require(msg.sender == lock.claimant || msg.sender == owner, "Unauthorized to delegate claim right");
         require(newDelegate != address(0), "Cannot delegate to zero address");
         require(newDelegate != lock.claimant, "Cannot delegate to self");

         address previousDelegate = lock.currentDelegate;
         lock.currentDelegate = newDelegate;

         emit ClaimRightDelegated(lockId, msg.sender, newDelegate);
    }

    function revokeClaimRight(uint256 lockId) external lockExistsAndActive(lockId) nonReentrant {
         Lock storage lock = locks[lockId];
         // Only the original claimant or owner can revoke delegation
         require(msg.sender == lock.claimant || msg.sender == owner, "Unauthorized to revoke claim right");
         require(lock.currentDelegate != address(0), "No active delegation to revoke");

         address previousDelegate = lock.currentDelegate;
         lock.currentDelegate = address(0);

         emit ClaimRightRevoked(lockId, msg.sender, previousDelegate);
    }

    function isEligibleToClaim(uint256 lockId, address potentialClaimant) public view returns (bool) {
         // Check if lock exists (simplified check for view function)
         if (lockId == 0 || lockId > nextLockId || locks[lockId].id == 0 || locks[lockId].isCancelled || locks[lockId].isMerged) {
             return false;
         }
         Lock storage lock = locks[lockId];
         return potentialClaimant == lock.claimant || potentialClaimant == lock.currentDelegate;
    }


    // --- Protocol Fee Functions ---

    function setProtocolFeeRate(uint256 feeRatePermil) external onlyOwner {
        require(feeRatePermil <= 1000, "Fee rate cannot exceed 100%"); // 1000 permil = 100%
        protocolFeeRatePermil = feeRatePermil;
        // Note: Need a way to set feeRecipient if it's not always the owner.
        // Let's add a function for that.
        emit ProtocolFeeRateUpdated(feeRatePermil);
    }

    function setFeeRecipient(address newRecipient) external onlyOwner {
        require(newRecipient != address(0), "Fee recipient cannot be zero address");
        feeRecipient = newRecipient;
        // Could add event FeeRecipientUpdated(oldRecipient, newRecipient);
    }


    // Fees are deducted *during* the `_performTransfer`.
    // This means fee collection relies on claimants successfully withdrawing.
    // A more active fee collection method would require tracking fees in a separate mapping
    // and having the owner `withdrawProtocolFees` from that mapping.
    // Let's implement `withdrawProtocolFees` based on the current feeRecipient and any
    // unclaimed fee amounts implicitly held in the contract balance.

    function withdrawProtocolFees(address tokenAddress) external onlyOwner nonReentrant {
         require(feeRecipient != address(0), "Fee recipient not set");

         uint256 totalBalance;
         if (tokenAddress == address(0)) {
             totalBalance = address(this).balance;
         } else {
             totalBalance = IERC20(tokenAddress).balanceOf(address(this));
         }

         // Calculate amount locked across all *active* locks for this token
         uint256 lockedAmount = 0;
         for (uint256 i = 1; i < nextLockId; i++) {
             if (locks[i].id != 0 && !locks[i].isCancelled && !locks[i].isMerged && locks[i].tokenAddress == tokenAddress) {
                 lockedAmount += (locks[i].totalAmount - locks[i].claimedAmount);
             }
         }

         // The withdrawable fee amount is the contract's total balance minus
         // the total amount currently locked in active locks.
         // This assumes all other transfers (deposits, unlocks) are accounted for.
         uint256 withdrawableAmount = totalBalance > lockedAmount ? totalBalance - lockedAmount : 0;

         require(withdrawableAmount > 0, "No withdrawable fees for this token");

         if (tokenAddress == address(0)) { // ETH
             // Update internal ETH balance before sending
             // This is a simplification; a dedicated fee balance tracking is better.
             // Let's update internal balance by subtracting the withdrawable amount.
             // This logic is tricky if internal balance isn't always the source of truth.
             // Relying on address(this).balance is better here, assuming it's the source of truth.
             // Ensure ReentrancyGuard protects the transfer.
             (bool success, ) = feeRecipient.call{value: withdrawableAmount}("");
             require(success, "ETH fee withdrawal failed");
         } else { // ERC20
             IERC20 token = IERC20(tokenAddress);
             token.transfer(feeRecipient, withdrawableAmount);
         }

         emit ProtocolFeesWithdrawn(feeRecipient, tokenAddress, withdrawableAmount);
         // Note: This fee withdrawal mechanism is simplistic and relies on contract balance >= locked amount.
         // A dedicated fee balance tracking mapping would be more precise.
    }


    // --- Lock Restructuring Functions ---

    function splitLock(uint256 lockId, uint256 amountForNewLock, Condition[] calldata newLockConditions) external onlyOwner lockExistsAndActive(lockId) nonReentrancy {
        Lock storage originalLock = locks[lockId];
        require(amountForNewLock > 0, "Amount for new lock must be greater than 0");
        uint256 remainingOriginalAmount = originalLock.totalAmount - originalLock.claimedAmount;
        require(amountForNewLock <= remainingOriginalAmount, "Amount for new lock exceeds remaining amount in original lock");
        require(newLockConditions.length > 0, "New lock must have at least one condition");

        uint256 newLockId = nextLockId++;

        // Adjust original lock
        originalLock.totalAmount -= amountForNewLock;
        // Note: claimedAmount remains the same, effectively representing amount claimed *from the original total*.
        // This might be confusing. A better approach is to adjust claimedAmount proportionally,
        // or enforce that split can only happen before any claims. Let's enforce no claims yet.
        require(originalLock.claimedAmount == 0, "Cannot split a lock after partial claims");


        // Create new lock (deep copy conditions from calldata)
         Condition[] memory conditionsCopy = new Condition[](newLockConditions.length);
        for (uint i = 0; i < newLockConditions.length; i++) {
            conditionsCopy[i] = newLockConditions[i];
        }

        locks[newLockId] = Lock({
            id: newLockId,
            originalCreator: originalLock.originalCreator, // Or msg.sender? Let's keep original creator
            claimant: originalLock.claimant, // New lock defaults to original claimant
            tokenAddress: originalLock.tokenAddress,
            totalAmount: amountForNewLock,
            claimedAmount: 0,
            isCancelled: false,
            isMerged: false,
            conditions: conditionsCopy,
            currentDelegate: address(0) // No delegation initially
        });

        emit LockSplit(lockId, newLockId, amountForNewLock);
        // Could also emit LockUpdated/LockCreated events for clarity
    }

    function mergeLocks(uint256 lockId1, uint256 lockId2) external onlyOwner lockExistsAndActive(lockId1) lockExistsAndActive(lockId2) nonReentrancy {
        Lock storage lock1 = locks[lockId1];
        Lock storage lock2 = locks[lockId2];

        require(lockId1 != lockId2, "Cannot merge a lock with itself");
        require(lock1.tokenAddress == lock2.tokenAddress, "Cannot merge locks of different tokens");
        require(lock1.claimant == lock2.claimant && lock1.currentDelegate == lock2.currentDelegate, "Cannot merge locks with different claimants or delegates");
        require(lock1.claimedAmount == 0 && lock2.claimedAmount == 0, "Cannot merge locks after partial claims");

        uint256 newLockId = nextLockId++;
        uint256 mergedAmount = (lock1.totalAmount - lock1.claimedAmount) + (lock2.totalAmount - lock2.claimedAmount); // Should be totalAmount as claimedAmount is 0
        uint256 totalMergedAmount = lock1.totalAmount + lock2.totalAmount;

        // New lock requires ALL conditions from both original locks to be met
        Condition[] memory mergedConditions = new Condition[](lock1.conditions.length + lock2.conditions.length);
        uint k = 0;
        for (uint i = 0; i < lock1.conditions.length; i++) {
            mergedConditions[k++] = lock1.conditions[i];
        }
        for (uint i = 0; i < lock2.conditions.length; i++) {
            mergedConditions[k++] = lock2.conditions[i];
        }

         locks[newLockId] = Lock({
            id: newLockId,
            originalCreator: lock1.originalCreator, // Or owner? Let's keep first lock's creator
            claimant: lock1.claimant,
            tokenAddress: lock1.tokenAddress,
            totalAmount: totalMergedAmount,
            claimedAmount: 0,
            isCancelled: false,
            isMerged: false, // This is the NEW merged lock
            conditions: mergedConditions,
            currentDelegate: lock1.currentDelegate // Carry over delegation from first lock
        });

        // Mark original locks as merged
        lock1.isMerged = true;
        lock2.isMerged = true;

        emit LockMerged(lockId1, lockId2, newLockId);
    }

    // --- Other Advanced Functions ---

    // Example of a conditional action *within* the contract state,
    // triggered by a lock's conditions being met, without transferring funds.
    // This could potentially enable/disable features, update status variables, etc.
    // For demonstration, let's toggle a simple boolean flag associated with the lock creator/claimant.
    mapping(address => bool) public featureEnabledStatus;

    function executeConditionalAction(uint256 lockId) external lockExistsAndActive(lockId) nonReentrancy {
        Lock storage lock = locks[lockId];
        // This action doesn't require caller to be the claimant,
        // but maybe only the original creator or anyone who pays gas?
        // Let's allow anyone to trigger, assuming the *result* of the action
        // is only meaningful to the intended parties.
        // Or require owner/creator to trigger? Let's require original creator.
         require(msg.sender == lock.originalCreator, "Only original creator can trigger this action");


        // Check ALL conditions, including puzzle (though the solution is not provided here)
        // This implies the puzzle condition must be solvable *externally* first,
        // or this function is not intended for locks with puzzle conditions.
        // Let's refine: this function *cannot* execute for locks with Puzzle conditions,
        // or it requires the puzzle solution like attemptUnlock. Let's require puzzle solution.
        // No, that makes it similar to attemptUnlock. Let's make this action separate:
        // It *can* be triggered if *non-puzzle* conditions are met. The action itself
        // doesn't depend on the puzzle solution, only on external state/time.

        // Check all conditions EXCEPT Puzzle
         for (uint i = 0; i < lock.conditions.length; i++) {
            Condition storage cond = lock.conditions[i];
            if (cond.conditionType == ConditionType.Puzzle) {
                // Skip puzzle check for this action
                continue;
            }
            bool met = false;
             if (cond.conditionType == ConditionType.Time) {
                met = block.timestamp >= cond.uintParam;
            } else if (cond.conditionType == ConditionType.Oracle) {
                ISimpleOracle oracle = cond.addressParam == address(0) ? defaultOracle : ISimpleOracle(cond.addressParam);
                require(address(oracle) != address(0), "Oracle not set for condition");
                try oracle.latestAnswer(cond.bytesParam) returns (int256 answer) {
                     if (cond.comparisonType == ComparisonType.GreaterThan) { met = answer > cond.intParam; }
                     else if (cond.comparisonType == ComparisonType.LessThan) { met = answer < cond.intParam; }
                     else if (cond.comparisonType == ComparisonType.EqualTo) { met = answer == cond.intParam; }
                } catch { met = false; }
            }
            require(met, "A required non-puzzle condition is not met for this action");
        }


        // Example action: Toggle a feature flag for the lock's claimant
        address actionRecipient = lock.claimant;
        featureEnabledStatus[actionRecipient] = !featureEnabledStatus[actionRecipient];

        emit ConditionalActionExecuted(lockId);
    }

    // --- Owner Functions (can be added or removed as needed to reach >20) ---

    function updateDefaultOracle(address newOracle) external onlyOwner {
        require(newOracle != address(0), "New oracle address cannot be zero");
        defaultOracle = ISimpleOracle(newOracle);
        // Could add event DefaultOracleUpdated(oldOracle, newOracle);
    }
}
```

**Explanation of Advanced/Creative Concepts:**

1.  **Multiple, Flexible Lock Conditions:** Instead of just time locks or simple puzzles, this contract allows defining multiple conditions (`Condition[]`) for a single lock. These conditions can be time-based, oracle-based (simulated using an interface), or puzzle-based. All conditions in the array must be met (`AND` logic) for the lock to be claimable.
2.  **Oracle Integration (Simulated):** Includes a pattern for integrating with external data sources (like Chainlink Price Feeds) via an `ISimpleOracle` interface. This allows locks to depend on real-world events or data (e.g., "unlock if ETH price is above $3000"). Requires a specific oracle address and data feed ID per condition.
3.  **On-Chain Puzzle:** The `Puzzle` condition type and corresponding `attemptUnlock`/`claimPartial` functions implement a simple verifiable puzzle. The creator sets a target hash (`puzzleTargetHash`). The claimant must provide the correct pre-image (`puzzleSolution`) which, when hashed, matches the target. This is a basic cryptographic puzzle solvable with brute force or if the secret is known/found off-chain.
4.  **Multi-Condition Locks:** Explicitly supports creating locks that require a combination of Time, Oracle, and Puzzle conditions to be met simultaneously.
5.  **Partial Claims:** Once the conditions of a lock are met, the claimant doesn't have to withdraw the entire amount at once. They can call `claimPartial` multiple times, specifying the amount they want to withdraw, until the `totalAmount` is reached.
6.  **Claim Delegation:** The original claimant of a lock can delegate their right to claim funds to another address using `delegateClaimRight`. They can also revoke this delegation. This is useful for scenarios where the original recipient wants someone else (e.g., a manager, a different wallet) to handle the withdrawal.
7.  **Lock Restructuring (Split/Merge):**
    *   `splitLock`: Allows the owner to take an existing lock and split a portion of its remaining funds into a *new* lock with potentially *different* conditions. This is powerful for adjusting vesting schedules or changing unlock criteria post-creation (though currently limited to locks with no partial claims).
    *   `mergeLocks`: Allows the owner to combine the amounts and conditions of two compatible locks (same token, same claimant, no partial claims) into a single new lock. The new lock requires *all* conditions from *both* original locks to be met.
8.  **Conditional Action Execution:** The `executeConditionalAction` function demonstrates triggering an internal state change or logic based *only* on a lock's conditions being met (excluding Puzzle conditions in this implementation, or requiring the solution). This decouples conditional *logic* from conditional *transfers*, allowing for more flexible use cases beyond just releasing funds (e.g., unlocking a feature in a related contract state, updating a status flag on-chain).
9.  **Protocol Fees:** Includes a mechanism to set a protocol fee rate (`protocolFeeRatePermil`) and a `feeRecipient`. The `_performTransfer` internal function automatically deducts this fee from the claimed amount and conceptually allocates it to the `feeRecipient`. The `withdrawProtocolFees` function allows the owner to collect these accumulated fees. (Note: The fee tracking and withdrawal logic is a simplification; a more robust system would use a dedicated mapping for fee balances).
10. **Reentrancy Guard:** Uses OpenZeppelin's `ReentrancyGuard` for protection on functions that interact with external contracts (`transfer`, `call`) to prevent re-entrancy attacks.

This contract goes significantly beyond standard token vaults or simple time locks by introducing dynamic conditional logic, interactive puzzle elements, and lock structure manipulation features not commonly found in basic open-source examples. It serves as a complex example showcasing various Solidity capabilities and design patterns.