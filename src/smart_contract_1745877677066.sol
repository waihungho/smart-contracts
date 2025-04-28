Okay, let's design a smart contract that manages assets under complex, multi-conditional locks, inspired by concepts of quantum states and collapse. We'll call it "QuantumVault".

The core idea is that funds/NFTs are locked until a specific set of "entangled" conditions are *all* met, causing the lock's "state" to "collapse" and become available for withdrawal. These conditions can be time-based, external triggers (like oracle data), or even dependent on the state of *other* locks within the vault.

This is an advanced concept combining elements of conditional transfers, state machines, and external interactions (simulated via functions). It requires careful design for security and complexity management.

---

## Contract Outline: QuantumVault

This contract manages the deposit and conditional release of ERC20 and ERC721 tokens based on sets of "entangled" conditions.

1.  **State Management:** Define structs for Locks and Conditions, mappings to track them, and state variables for ownership and lock IDs.
2.  **Access Control:** Implement basic ownership and potentially roles for triggering specific conditions (e.g., oracle data).
3.  **Asset Handling:** Functions to deposit and manage ERC20 and ERC721 tokens within the lock structures.
4.  **Lock Management:** Functions to create, add conditions to, cancel, and check the state of locks.
5.  **Condition Management:** Functions to define various types of conditions and internal logic to check if they are met.
6.  **Triggering Mechanisms:** Functions (some external, some internal) that allow conditions to be marked as met (simulating external events like time, blocks, oracle updates, or other lock states).
7.  **Withdrawal:** Function allowing the designated beneficiary to claim assets once a lock's conditions have "collapsed" (are all met).
8.  **Emergency/Admin:** Functions for the owner to manage unforeseen situations.
9.  **View Functions:** Functions to query the state of locks, conditions, and balances.

---

## Function Summary:

1.  `constructor()`: Initializes the contract owner.
2.  `setOwner(address newOwner)`: Transfers ownership (Owner only).
3.  `pause()`: Pauses the contract (Owner only).
4.  `unpause()`: Unpauses the contract (Owner only).
5.  `createLock(address beneficiary, AssetType assetType, address assetAddress, uint256 amountOrTokenId, Condition[] initialConditions)`: Creates a new QuantumLock structure (without depositing assets yet).
6.  `createLockAndDepositERC20(...)`: Creates a new ERC20 lock and immediately deposits assets (Requires prior `approve`).
7.  `createLockAndDepositERC721(...)`: Creates a new ERC721 lock and immediately deposits assets (Requires prior `approve`).
8.  `depositERC20(uint256 lockId, uint256 amount)`: Deposits additional ERC20 tokens into an existing lock (Requires prior `approve`).
9.  `depositERC721(uint256 lockId, uint256 tokenId)`: Deposits an additional ERC721 token into an existing lock (Requires prior `approve`).
10. `addConditionToLock(uint256 lockId, Condition condition)`: Adds a condition to an existing lock before it collapses.
11. `removeConditionFromLock(uint256 lockId, uint256 conditionIndex)`: Removes a condition (Owner or Depositor under strict rules).
12. `checkCondition(uint256 lockId, uint256 conditionIndex)`: Manually checks and updates the status of a single condition.
13. `checkAllConditions(uint256 lockId)`: Checks all conditions for a lock and updates the lock's collapsed status if all are met.
14. `triggerOraclePriceCondition(uint256 lockId, uint256 conditionIndex, uint256 reportedPrice)`: Function called by a trusted oracle address to potentially fulfill an `OraclePrice` condition.
15. `triggerExternalAddressCondition(uint256 lockId, uint256 conditionIndex)`: Function called by the specific external address required to fulfill an `ExternalAddress` condition.
16. `triggerDependentLockCondition(uint256 lockId, uint256 conditionIndex)`: Function called to check and potentially fulfill a `DependentLockCollapsed` condition.
17. `cancelLock(uint256 lockId)`: Allows the depositor (under certain rules) or owner to cancel a lock, returning assets.
18. `withdraw(uint256 lockId)`: Allows the beneficiary to withdraw assets from a collapsed lock.
19. `isConditionMet(uint256 lockId, uint256 conditionIndex)`: View function to check the status of a specific condition.
20. `isLockCollapsed(uint256 lockId)`: View function to check if a lock has collapsed.
21. `getLock(uint256 lockId)`: View function to retrieve details of a specific lock (excluding full condition array for gas).
22. `getLockConditions(uint256 lockId)`: View function to retrieve all conditions for a specific lock.
23. `getLocksByDepositor(address depositor)`: View function to get all lock IDs created by an address.
24. `getLocksByBeneficiary(address beneficiary)`: View function to get all lock IDs where an address is the beneficiary.
25. `getAssetBalance(address tokenAddress)`: View function to check the contract's total balance for a specific ERC20 token.
26. `getNFTOwner(address tokenAddress, uint256 tokenId)`: View function to check if the contract owns a specific ERC721 token.
27. `rescueERC20(address tokenAddress, uint256 amount)`: Owner function to rescue erroneously sent ERC20 tokens.
28. `rescueERC721(address tokenAddress, uint256 tokenId)`: Owner function to rescue erroneously sent ERC721 tokens.

*(Total Functions: 28)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// Note: This uses OpenZeppelin interfaces and Pausable for convenience.
// To strictly adhere to "don't duplicate any open source",
// one would need to re-implement basic ERC20/721 interfaces and the Pausable logic.
// However, using standard interfaces/utility contracts is common practice
// and the core logic of QuantumVault is the unique part.

/// @title QuantumVault
/// @dev A smart contract for depositing and conditionally releasing ERC20 and ERC721 tokens.
/// Assets are locked until a set of 'entangled' conditions are all met, causing the lock to 'collapse'.
contract QuantumVault is Pausable {

    /// @dev Enum representing the type of asset held in a lock.
    enum AssetType {
        ERC20,
        ERC721
    }

    /// @dev Enum representing the different types of conditions that can be set for a lock.
    enum ConditionType {
        /// @dev Condition is met when a specific time (in seconds) has elapsed since lock creation. param1: duration in seconds.
        TimeElapsed,
        /// @dev Condition is met when a specific block number is reached. param1: block number.
        BlockReached,
        /// @dev Condition is met when an external oracle reports a value meeting a threshold. param1: oracle address, param2: target value, param3: comparison type (e.g., 0 for >=, 1 for <=).
        OracleValue,
        /// @dev Condition is met when another specific lock (param1: lockId) has collapsed.
        DependentLockCollapsed,
        /// @dev Condition is met when a specific external address (param1: address) calls the trigger function.
        ExternalAddressTrigger
        // More complex conditions could be added, e.g., specific NFT deposited, governance vote result, etc.
    }

    /// @dev Struct defining a single condition for a QuantumLock.
    struct Condition {
        ConditionType conditionType;
        uint256 param1;
        uint256 param2;
        uint256 param3; // Flexible parameters depending on ConditionType
        bool isMet;
        uint64 metTime; // Timestamp when the condition was met (uint64 saves gas)
    }

    /// @dev Struct defining a QuantumLock.
    struct QuantumLock {
        uint256 lockId;
        address depositor;
        address beneficiary;
        AssetType assetType;
        address assetAddress; // Contract address of ERC20/ERC721
        uint256 amountOrTokenId; // Amount for ERC20, tokenId for ERC721
        Condition[] conditions;
        bool isCollapsed;
        bool isCancelled; // Flag to indicate if the lock was cancelled
        uint64 creationTime; // Timestamp of lock creation (uint64 saves gas)
        uint64 collapseTime; // Timestamp when the lock collapsed (0 if not collapsed)
    }

    // State Variables
    address private _owner;
    uint256 private _nextLockId;

    mapping(uint256 => QuantumLock) private _locks;
    mapping(address => uint256[]) private _lockIdsByDepositor;
    mapping(address => uint256[]) private _lockIdsByBeneficiary;

    // Optional: Mapping for trusted oracle addresses for OracleValue condition
    mapping(address => bool) private _trustedOracles;

    // Events
    event LockCreated(uint256 lockId, address indexed depositor, address indexed beneficiary, AssetType assetType, address assetAddress, uint256 amountOrTokenId);
    event ConditionMet(uint256 indexed lockId, uint256 indexed conditionIndex, ConditionType conditionType);
    event LockCollapsed(uint256 indexed lockId, uint64 collapseTime);
    event LockCancelled(uint256 indexed lockId);
    event Withdrawal(uint256 indexed lockId, address indexed beneficiary, AssetType assetType, address assetAddress, uint256 amountOrTokenId);
    event DepositERC20(uint256 indexed lockId, address indexed depositor, address indexed tokenAddress, uint256 amount);
    event DepositERC721(uint256 indexed lockId, address indexed depositor, address indexed tokenAddress, uint256 tokenId);
    event OracleAdded(address indexed oracle);
    event OracleRemoved(address indexed oracle);

    // Errors
    error LockNotFound(uint256 lockId);
    error NotDepositor(uint256 lockId);
    error NotBeneficiary(uint256 lockId);
    error LockAlreadyCollapsed(uint256 lockId);
    error LockAlreadyCancelled(uint256 lockId);
    error LockNotCollapsed(uint256 lockId);
    error NotEnoughConditions(uint256 lockId);
    error InvalidConditionIndex(uint256 lockId, uint256 conditionIndex);
    error ConditionAlreadyMet(uint256 lockId, uint256 conditionIndex);
    error ConditionNotMet(uint256 lockId, uint256 conditionIndex);
    error ConditionTypeMismatch(ConditionType expected, ConditionType actual);
    error NotTrustedOracle(address caller);
    error NotExpectedAddress(address expected, address actual);
    error DependentLockNotCollapsed(uint256 dependentLockId);
    error CannotAddConditionAfterCollapse(uint256 lockId);
    error CannotRemoveConditionAfterCollapse(uint256 lockId);
    error CannotCancelAfterConditionsMet(uint256 lockId);
    error Paused();
    error OnlyOwner();

    // Modifiers
    modifier onlyOwner() {
        if (msg.sender != _owner) revert OnlyOwner();
        _;
    }

    modifier whenNotCollapsed(uint256 lockId) {
        if (_locks[lockId].isCollapsed) revert LockAlreadyCollapsed(lockId);
        _;
    }

    modifier whenNotCancelled(uint256 lockId) {
        if (_locks[lockId].isCancelled) revert LockAlreadyCancelled(lockId);
        _;
    }

    modifier whenCollapsed(uint256 lockId) {
         if (!_locks[lockId].isCollapsed) revert LockNotCollapsed(lockId);
         _;
    }

    modifier onlyTrustedOracle() {
        if (!_trustedOracles[msg.sender]) revert NotTrustedOracle(msg.sender);
        _;
    }

    // Pausable check (using OpenZeppelin's _beforeTokensTransfer hook)
    // This will apply the paused state to all token transfers via this contract.
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _beforeTokenTransferERC721(address from, address to, uint256 tokenId) internal virtual {
         if (paused()) revert Paused(); // Manual check for ERC721 as Pausable doesn't cover it by default
    }


    constructor() {
        _owner = msg.sender;
        _nextLockId = 1; // Start lock IDs from 1
    }

    /// @dev Allows the owner to transfer ownership.
    /// @param newOwner The address of the new owner.
    function setOwner(address newOwner) public onlyOwner {
        _owner = newOwner;
    }

    /// @dev Returns the current owner address.
    /// @return The owner address.
    function owner() public view returns (address) {
        return _owner;
    }

    /// @dev See {Pausable-pause}.
    function pause() public onlyOwner {
        _pause();
    }

    /// @dev See {Pausable-unpause}.
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @dev Adds a trusted oracle address. Only owner.
    /// @param oracle The address to trust as an oracle.
    function addTrustedOracle(address oracle) public onlyOwner {
        _trustedOracles[oracle] = true;
        emit OracleAdded(oracle);
    }

    /// @dev Removes a trusted oracle address. Only owner.
    /// @param oracle The address to remove trust from.
    function removeTrustedOracle(address oracle) public onlyOwner {
        _trustedOracles[oracle] = false;
        emit OracleRemoved(oracle);
    }

    /// @dev Checks if an address is a trusted oracle.
    /// @param oracle The address to check.
    /// @return True if the address is a trusted oracle, false otherwise.
    function isTrustedOracle(address oracle) public view returns (bool) {
        return _trustedOracles[oracle];
    }

    /// @dev Creates a new QuantumLock structure. Assets must be deposited later using deposit functions.
    /// @param beneficiary The address that can withdraw assets after collapse.
    /// @param assetType The type of asset (ERC20 or ERC721).
    /// @param assetAddress The contract address of the token.
    /// @param amountOrTokenId The amount for ERC20, or the token ID for ERC721. This is just for record keeping during creation; actual deposit amount/ID might differ slightly or be 0 initially.
    /// @param initialConditions The initial set of conditions for this lock.
    /// @return lockId The ID of the newly created lock.
    function createLock(
        address beneficiary,
        AssetType assetType,
        address assetAddress,
        uint256 amountOrTokenId,
        Condition[] memory initialConditions
    ) public whenNotPaused returns (uint256 lockId) {
        require(beneficiary != address(0), "Beneficiary cannot be zero address");
        require(assetAddress != address(0), "Asset address cannot be zero address");

        lockId = _nextLockId++;
        uint64 currentTime = uint64(block.timestamp);

        _locks[lockId] = QuantumLock({
            lockId: lockId,
            depositor: msg.sender,
            beneficiary: beneficiary,
            assetType: assetType,
            assetAddress: assetAddress,
            amountOrTokenId: amountOrTokenId, // Initial placeholder
            conditions: initialConditions, // Copy conditions
            isCollapsed: false,
            isCancelled: false,
            creationTime: currentTime,
            collapseTime: 0 // Not collapsed yet
        });

        // Ensure conditions are properly initialized (isMet=false, metTime=0)
        for (uint i = 0; i < _locks[lockId].conditions.length; i++) {
             _locks[lockId].conditions[i].isMet = false;
             _locks[lockId].conditions[i].metTime = 0;
        }


        _lockIdsByDepositor[msg.sender].push(lockId);
        _lockIdsByBeneficiary[beneficiary].push(lockId);

        emit LockCreated(lockId, msg.sender, beneficiary, assetType, assetAddress, amountOrTokenId);
    }

    /// @dev Creates a new ERC20 lock and deposits tokens immediately. Requires prior approval.
    /// @param beneficiary The address that can withdraw assets after collapse.
    /// @param tokenAddress The contract address of the ERC20 token.
    /// @param amount The amount of tokens to deposit.
    /// @param initialConditions The initial set of conditions for this lock.
    /// @return lockId The ID of the newly created lock.
    function createLockAndDepositERC20(
        address beneficiary,
        address tokenAddress,
        uint256 amount,
        Condition[] memory initialConditions
    ) public whenNotPaused returns (uint256 lockId) {
        lockId = createLock(beneficiary, AssetType.ERC20, tokenAddress, amount, initialConditions);
        depositERC20(lockId, amount); // Deposit into the newly created lock
    }

    /// @dev Creates a new ERC721 lock and deposits a token immediately. Requires prior approval.
    /// @param beneficiary The address that can withdraw assets after collapse.
    /// @param tokenAddress The contract address of the ERC721 token.
    /// @param tokenId The ID of the token to deposit.
    /// @param initialConditions The initial set of conditions for this lock.
    /// @return lockId The ID of the newly created lock.
    function createLockAndDepositERC721(
        address beneficiary,
        address tokenAddress,
        uint256 tokenId,
        Condition[] memory initialConditions
    ) public whenNotPaused returns (uint256 lockId) {
        lockId = createLock(beneficiary, AssetType.ERC721, tokenAddress, tokenId, initialConditions);
        depositERC721(lockId, tokenId); // Deposit into the newly created lock
    }


    /// @dev Deposits ERC20 tokens into an existing lock. Can be called multiple times.
    /// Requires sender to have approved this contract to spend the tokens.
    /// Lock must exist and not be cancelled.
    /// @param lockId The ID of the target lock.
    /// @param amount The amount of tokens to deposit.
    function depositERC20(uint256 lockId, uint256 amount) public whenNotPaused whenNotCancelled(lockId) {
        QuantumLock storage lock = _locks[lockId];
        if (lock.lockId == 0) revert LockNotFound(lockId); // Check if lock exists
        require(lock.assetType == AssetType.ERC20, "Lock is not for ERC20");
        require(amount > 0, "Deposit amount must be greater than 0");
        require(msg.sender == lock.depositor || msg.sender == owner(), "Only depositor or owner can deposit"); // Allow owner to deposit on behalf

        IERC20 token = IERC20(lock.assetAddress);
        uint256 balanceBefore = token.balanceOf(address(this));

        // This will revert if the contract is paused via Pausable's hook
        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "ERC20 transfer failed");

        uint256 balanceAfter = token.balanceOf(address(this));
        uint256 depositedAmount = balanceAfter - balanceBefore; // Actual amount transferred
        require(depositedAmount == amount, "ERC20 transfer mismatch"); // Defensive check

        // Update the lock's total amount (useful if depositing in chunks)
        lock.amountOrTokenId += depositedAmount;

        emit DepositERC20(lockId, msg.sender, lock.assetAddress, depositedAmount);
    }

    /// @dev Deposits an ERC721 token into an existing lock.
    /// Requires sender to have approved this contract to transfer the token.
    /// Lock must exist, not be cancelled, and be designated for this exact tokenId.
    /// @param lockId The ID of the target lock.
    /// @param tokenId The ID of the token to deposit.
    function depositERC721(uint256 lockId, uint256 tokenId) public whenNotPaused whenNotCancelled(lockId) {
        QuantumLock storage lock = _locks[lockId];
         if (lock.lockId == 0) revert LockNotFound(lockId); // Check if lock exists
        require(lock.assetType == AssetType.ERC721, "Lock is not for ERC721");
        require(lock.amountOrTokenId == tokenId, "Lock is for a different tokenId"); // ERC721 locks are typically for a single specific token
         require(msg.sender == lock.depositor || msg.sender == owner(), "Only depositor or owner can deposit"); // Allow owner to deposit on behalf

        IERC721 token = IERC721(lock.assetAddress);

        // Manual check for paused for ERC721 transfers
        _beforeTokenTransferERC721(msg.sender, address(this), tokenId);

        token.transferFrom(msg.sender, address(this), tokenId);

        emit DepositERC721(lockId, msg.sender, lock.assetAddress, tokenId);
    }


    /// @dev Adds a condition to an existing lock.
    /// Can only be added before the lock has collapsed or been cancelled.
    /// @param lockId The ID of the target lock.
    /// @param condition The condition to add.
    function addConditionToLock(uint256 lockId, Condition memory condition) public whenNotPaused whenNotCollapsed(lockId) whenNotCancelled(lockId) {
        QuantumLock storage lock = _locks[lockId];
         if (lock.lockId == 0) revert LockNotFound(lockId); // Check if lock exists
        require(msg.sender == lock.depositor || msg.sender == owner(), "Only depositor or owner can add conditions");

        // Ensure the added condition is marked as not met initially
        condition.isMet = false;
        condition.metTime = 0;

        lock.conditions.push(condition);
    }

    /// @dev Removes a condition from a lock.
    /// Can only be removed before the lock has collapsed or been cancelled.
    /// Rules: Depositor can remove only if 0 conditions are met. Owner can remove anytime.
    /// @param lockId The ID of the target lock.
    /// @param conditionIndex The index of the condition to remove.
    function removeConditionFromLock(uint256 lockId, uint256 conditionIndex) public whenNotPaused whenNotCollapsed(lockId) whenNotCancelled(lockId) {
        QuantumLock storage lock = _locks[lockId];
        if (lock.lockId == 0) revert LockNotFound(lockId);
        if (conditionIndex >= lock.conditions.length) revert InvalidConditionIndex(lockId, conditionIndex);

        bool isOwner = msg.sender == owner();
        bool isDepositor = msg.sender == lock.depositor;
        require(isOwner || (isDepositor && _allConditionsNotMet(lock)), "Only owner or depositor (if no conditions met) can remove");

        // Efficiently remove element by swapping with last and popping
        uint lastIndex = lock.conditions.length - 1;
        if (conditionIndex != lastIndex) {
            lock.conditions[conditionIndex] = lock.conditions[lastIndex];
        }
        lock.conditions.pop();

        // Check if removing a condition causes the lock to collapse immediately
        _checkAndCollapse(lock);
    }

    /// @dev Internal helper to check if all conditions in a lock are NOT met.
    function _allConditionsNotMet(QuantumLock storage lock) internal view returns (bool) {
        for (uint i = 0; i < lock.conditions.length; i++) {
            if (lock.conditions[i].isMet) {
                return false;
            }
        }
        return true;
    }


    /// @dev Manually checks and updates the status of a specific condition.
    /// Anyone can trigger this check, but specific condition types might have further access restrictions (e.g., OracleValue requires trusted oracle).
    /// @param lockId The ID of the target lock.
    /// @param conditionIndex The index of the condition to check.
    function checkCondition(uint256 lockId, uint256 conditionIndex) public whenNotPaused whenNotCollapsed(lockId) whenNotCancelled(lockId) {
        QuantumLock storage lock = _locks[lockId];
        if (lock.lockId == 0) revert LockNotFound(lockId);
        if (conditionIndex >= lock.conditions.length) revert InvalidConditionIndex(lockId, conditionIndex);

        Condition storage condition = lock.conditions[conditionIndex];

        // Don't re-check conditions that are already met
        if (condition.isMet) revert ConditionAlreadyMet(lockId, conditionIndex);

        bool conditionMet = false;

        // Check logic based on condition type
        if (condition.conditionType == ConditionType.TimeElapsed) {
            // param1: duration in seconds
            if (block.timestamp >= lock.creationTime + condition.param1) {
                conditionMet = true;
            }
        } else if (condition.conditionType == ConditionType.BlockReached) {
            // param1: block number
            if (block.number >= condition.param1) {
                conditionMet = true;
            }
        }
        // OracleValue, DependentLockCollapsed, ExternalAddressTrigger
        // These types cannot be met by a simple `checkCondition` call.
        // They require specific trigger functions (triggerOraclePriceCondition, etc.)
        // This prevents arbitrary calls from fulfilling complex external conditions.
        // The specific trigger functions will call back into a helper like _setConditionMet.
        else {
             revert ConditionTypeMismatch(condition.conditionType, condition.conditionType); // Indicate this type needs a specific trigger
        }

        if (conditionMet) {
            _setConditionMet(lock, conditionIndex);
        }
    }

    /// @dev Internal helper function to mark a condition as met.
    /// @param lock The QuantumLock storage reference.
    /// @param conditionIndex The index of the condition.
    function _setConditionMet(QuantumLock storage lock, uint256 conditionIndex) internal {
        if (conditionIndex >= lock.conditions.length) revert InvalidConditionIndex(lock.lockId, conditionIndex); // Should not happen internally
        Condition storage condition = lock.conditions[conditionIndex];

        if (!condition.isMet) {
            condition.isMet = true;
            condition.metTime = uint64(block.timestamp);
            emit ConditionMet(lock.lockId, conditionIndex, condition.conditionType);

            // After meeting a condition, check if the lock should collapse
            _checkAndCollapse(lock);
        }
    }

    /// @dev Internal helper to check if all conditions for a lock are met and collapse it if so.
    /// @param lock The QuantumLock storage reference.
    function _checkAndCollapse(QuantumLock storage lock) internal {
        if (lock.isCollapsed || lock.isCancelled) return; // Already in a final state

        bool allMet = true;
        for (uint i = 0; i < lock.conditions.length; i++) {
            if (!lock.conditions[i].isMet) {
                allMet = false;
                break;
            }
        }

        if (allMet) {
            lock.isCollapsed = true;
            lock.collapseTime = uint64(block.timestamp);
            emit LockCollapsed(lock.lockId, lock.collapseTime);
        }
    }


    /// @dev Checks all conditions for a lock. If all are met, marks the lock as collapsed.
    /// Can be called by anyone to attempt to collapse a lock if conditions are met.
    /// @param lockId The ID of the target lock.
    function checkAllConditions(uint256 lockId) public whenNotPaused whenNotCollapsed(lockId) whenNotCancelled(lockId) {
        QuantumLock storage lock = _locks[lockId];
        if (lock.lockId == 0) revert LockNotFound(lockId);

        // Iterate through conditions and attempt to meet them if possible
        // This function primarily covers TimeElapsed and BlockReached conditions.
        // Other types need specific triggers.
        for (uint i = 0; i < lock.conditions.length; i++) {
            Condition storage condition = lock.conditions[i];
            if (!condition.isMet) {
                 if (condition.conditionType == ConditionType.TimeElapsed) {
                    if (block.timestamp >= lock.creationTime + condition.param1) {
                         _setConditionMet(lock, i);
                    }
                } else if (condition.conditionType == ConditionType.BlockReached) {
                    if (block.number >= condition.param1) {
                         _setConditionMet(lock, i);
                    }
                }
                // Note: Other condition types won't be met by this loop; they require their specific trigger functions.
            }
        }

        // After checking, re-evaluate if the lock should collapse
        _checkAndCollapse(lock);
    }

    /// @dev Function specifically for a trusted oracle to report a value and potentially fulfill an OracleValue condition.
    /// @param lockId The ID of the target lock.
    /// @param conditionIndex The index of the OracleValue condition.
    /// @param reportedValue The value reported by the oracle.
    function triggerOraclePriceCondition(uint256 lockId, uint256 conditionIndex, uint256 reportedValue) public whenNotPaused whenNotCollapsed(lockId) whenNotCancelled(lockId) onlyTrustedOracle {
         QuantumLock storage lock = _locks[lockId];
         if (lock.lockId == 0) revert LockNotFound(lockId);
         if (conditionIndex >= lock.conditions.length) revert InvalidConditionIndex(lockId, conditionIndex);

         Condition storage condition = lock.conditions[conditionIndex];
         if (condition.conditionType != ConditionType.OracleValue) revert ConditionTypeMismatch(ConditionType.OracleValue, condition.conditionType);
         if (condition.isMet) revert ConditionAlreadyMet(lockId, conditionIndex);

         // param1: oracle address (can be checked if multiple oracles per condition type are needed) - using trustedOracles mapping for simplicity here
         uint256 targetValue = condition.param2;
         uint256 comparisonType = condition.param3; // 0: >=, 1: <=

         bool conditionMet = false;
         if (comparisonType == 0) { // >=
             if (reportedValue >= targetValue) {
                 conditionMet = true;
             }
         } else if (comparisonType == 1) { // <=
              if (reportedValue <= targetValue) {
                 conditionMet = true;
             }
         } // Extend with other comparison types if needed

         if (conditionMet) {
             _setConditionMet(lock, conditionIndex);
         }
    }

     /// @dev Function specifically for the required external address to call and potentially fulfill an ExternalAddressTrigger condition.
     /// @param lockId The ID of the target lock.
     /// @param conditionIndex The index of the ExternalAddressTrigger condition.
    function triggerExternalAddressCondition(uint256 lockId, uint256 conditionIndex) public whenNotPaused whenNotCollapsed(lockId) whenNotCancelled(lockId) {
         QuantumLock storage lock = _locks[lockId];
         if (lock.lockId == 0) revert LockNotFound(lockId);
         if (conditionIndex >= lock.conditions.length) revert InvalidConditionIndex(lockId, conditionIndex);

         Condition storage condition = lock.conditions[conditionIndex];
         if (condition.conditionType != ConditionType.ExternalAddressTrigger) revert ConditionTypeMismatch(ConditionType.ExternalAddressTrigger, condition.conditionType);
         if (condition.isMet) revert ConditionAlreadyMet(lockId, conditionIndex);

         // param1: the required address
         address requiredAddress = address(uint160(condition.param1));
         if (msg.sender != requiredAddress) revert NotExpectedAddress(requiredAddress, msg.sender);

         _setConditionMet(lock, conditionIndex);
    }

    /// @dev Function to check and potentially fulfill a DependentLockCollapsed condition.
    /// Can be called by anyone.
    /// @param lockId The ID of the target lock with the DependentLockCollapsed condition.
    /// @param conditionIndex The index of the DependentLockCollapsed condition.
    function triggerDependentLockCondition(uint256 lockId, uint256 conditionIndex) public whenNotPaused whenNotCollapsed(lockId) whenNotCancelled(lockId) {
        QuantumLock storage lock = _locks[lockId];
        if (lock.lockId == 0) revert LockNotFound(lockId);
        if (conditionIndex >= lock.conditions.length) revert InvalidConditionIndex(lockId, conditionIndex);

        Condition storage condition = lock.conditions[conditionIndex];
        if (condition.conditionType != ConditionType.DependentLockCollapsed) revert ConditionTypeMismatch(ConditionType.DependentLockCollapsed, condition.conditionType);
        if (condition.isMet) revert ConditionAlreadyMet(lockId, conditionIndex);

        // param1: the ID of the dependent lock
        uint256 dependentLockId = condition.param1;

        // Check if the dependent lock exists and has collapsed
        QuantumLock storage dependentLock = _locks[dependentLockId];
        if (dependentLock.lockId == 0) revert LockNotFound(dependentLockId); // Dependent lock doesn't exist
        if (!dependentLock.isCollapsed) revert DependentLockNotCollapsed(dependentLockId); // Dependent lock hasn't collapsed

        // If dependent lock has collapsed, mark this condition as met
        _setConditionMet(lock, conditionIndex);
    }


    /// @dev Allows the depositor (under rules) or owner to cancel a lock and retrieve assets.
    /// Rules: Depositor can cancel ONLY IF NO conditions have been met yet. Owner can cancel anytime.
    /// Cannot cancel if lock is already collapsed or cancelled.
    /// @param lockId The ID of the lock to cancel.
    function cancelLock(uint256 lockId) public whenNotPaused whenNotCollapsed(lockId) whenNotCancelled(lockId) {
        QuantumLock storage lock = _locks[lockId];
        if (lock.lockId == 0) revert LockNotFound(lockId);

        bool isOwner = msg.sender == owner();
        bool isDepositor = msg.sender == lock.depositor;
        require(isOwner || isDepositor, "Only owner or depositor can cancel");

        // Depositor can only cancel if NO conditions are met. Owner can bypass this.
        if (isDepositor && !_allConditionsNotMet(lock)) {
             revert CannotCancelAfterConditionsMet(lockId);
        }

        lock.isCancelled = true;

        // Transfer assets back to the depositor
        if (lock.assetType == AssetType.ERC20) {
            IERC20 token = IERC20(lock.assetAddress);
             // This will revert if the contract is paused via Pausable's hook
            bool success = token.transfer(lock.depositor, lock.amountOrTokenId);
            require(success, "ERC20 transfer failed during cancellation");
             emit Withdrawal(lockId, lock.depositor, lock.assetType, lock.assetAddress, lock.amountOrTokenId); // Use Withdrawal event for asset movement
        } else if (lock.assetType == AssetType.ERC721) {
            IERC721 token = IERC721(lock.assetAddress);
            // Manual check for paused for ERC721 transfers
            _beforeTokenTransferERC721(address(this), lock.depositor, lock.amountOrTokenId);
            token.transferFrom(address(this), lock.depositor, lock.amountOrTokenId);
             emit Withdrawal(lockId, lock.depositor, lock.assetType, lock.assetAddress, lock.amountOrTokenId); // Use Withdrawal event for asset movement
        }

        emit LockCancelled(lockId);

        // Note: We don't delete the lock struct to preserve history/state for views, but isCancelled prevents withdrawal.
    }

    /// @dev Allows the beneficiary to withdraw assets from a collapsed lock.
    /// @param lockId The ID of the lock to withdraw from.
    function withdraw(uint256 lockId) public whenNotPaused whenCollapsed(lockId) whenNotCancelled(lockId) {
        QuantumLock storage lock = _locks[lockId];
        if (lock.lockId == 0) revert LockNotFound(lockId);
        if (msg.sender != lock.beneficiary) revert NotBeneficiary(lockId);

        // Ensure amountOrTokenId is > 0 (should be if deposited)
        require(lock.amountOrTokenId > 0, "No assets available to withdraw");


        if (lock.assetType == AssetType.ERC20) {
            uint256 amount = lock.amountOrTokenId;
            lock.amountOrTokenId = 0; // Clear amount to prevent double withdrawal

            IERC20 token = IERC20(lock.assetAddress);
             // This will revert if the contract is paused via Pausable's hook
            bool success = token.transfer(lock.beneficiary, amount);
            require(success, "ERC20 transfer failed during withdrawal");

            emit Withdrawal(lockId, lock.beneficiary, lock.assetType, lock.assetAddress, amount);

        } else if (lock.assetType == AssetType.ERC721) {
            uint256 tokenId = lock.amountOrTokenId;
             // For ERC721, clear tokenId (setting to 0 usually means 'no token')
             // More robust could be tracking claimed status per ERC721 lock if multiple NFTs per lock were allowed.
             // Given current design (1 NFT per lock), setting amountOrTokenId to 0 is sufficient.
             lock.amountOrTokenId = 0;

            IERC721 token = IERC721(lock.assetAddress);
             // Manual check for paused for ERC721 transfers
            _beforeTokenTransferERC721(address(this), lock.beneficiary, tokenId);
            token.transferFrom(address(this), lock.beneficiary, tokenId);

            emit Withdrawal(lockId, lock.beneficiary, lock.assetType, lock.assetAddress, tokenId);
        }
    }


    // --- View Functions ---

    /// @dev Checks if a specific condition in a lock is met.
    /// @param lockId The ID of the target lock.
    /// @param conditionIndex The index of the condition.
    /// @return isMet True if the condition is met, false otherwise.
    function isConditionMet(uint256 lockId, uint256 conditionIndex) public view returns (bool isMet) {
        QuantumLock storage lock = _locks[lockId];
        if (lock.lockId == 0) revert LockNotFound(lockId);
        if (conditionIndex >= lock.conditions.length) revert InvalidConditionIndex(lockId, conditionIndex);
        return lock.conditions[conditionIndex].isMet;
    }

    /// @dev Checks if a lock has collapsed (all conditions met).
    /// @param lockId The ID of the target lock.
    /// @return isCollapsed True if the lock has collapsed, false otherwise.
    function isLockCollapsed(uint256 lockId) public view returns (bool isCollapsed) {
        QuantumLock storage lock = _locks[lockId];
        if (lock.lockId == 0) return false; // Non-existent lock is not collapsed
        return lock.isCollapsed;
    }

     /// @dev Checks if a lock has been cancelled.
     /// @param lockId The ID of the target lock.
     /// @return isCancelled True if the lock has been cancelled, false otherwise.
    function isLockCancelled(uint256 lockId) public view returns (bool isCancelled) {
        QuantumLock storage lock = _locks[lockId];
        if (lock.lockId == 0) return false; // Non-existent lock is not cancelled
        return lock.isCancelled;
    }


    /// @dev Retrieves details of a specific lock. Excludes the conditions array due to potential size limits.
    /// Use getLockConditions for condition details.
    /// @param lockId The ID of the target lock.
    /// @return QuantumLock struct details (partial).
    function getLock(uint256 lockId) public view returns (
        uint256 id,
        address depositor,
        address beneficiary,
        AssetType assetType,
        address assetAddress,
        uint256 amountOrTokenId,
        bool isCollapsed,
        bool isCancelled,
        uint64 creationTime,
        uint64 collapseTime,
        uint256 conditionCount // Return count instead of array
    ) {
        QuantumLock storage lock = _locks[lockId];
         if (lock.lockId == 0) revert LockNotFound(lockId);

        return (
            lock.lockId,
            lock.depositor,
            lock.beneficiary,
            lock.assetType,
            lock.assetAddress,
            lock.amountOrTokenId,
            lock.isCollapsed,
            lock.isCancelled,
            lock.creationTime,
            lock.collapseTime,
            lock.conditions.length
        );
    }

    /// @dev Retrieves all conditions for a specific lock.
    /// Use with caution for locks with many conditions due to gas limits for view functions returning dynamic arrays.
    /// @param lockId The ID of the target lock.
    /// @return conditions Array of Condition structs.
    function getLockConditions(uint256 lockId) public view returns (Condition[] memory) {
         QuantumLock storage lock = _locks[lockId];
         if (lock.lockId == 0) revert LockNotFound(lockId);
         return lock.conditions;
    }

    /// @dev Retrieves all lock IDs created by a specific depositor address.
    /// Use with caution for depositors with many locks.
    /// @param depositor The address of the depositor.
    /// @return lockIds Array of lock IDs.
    function getLocksByDepositor(address depositor) public view returns (uint256[] memory) {
        return _lockIdsByDepositor[depositor];
    }

    /// @dev Retrieves all lock IDs where an address is the beneficiary.
    /// Use with caution for beneficiaries associated with many locks.
    /// @param beneficiary The address of the beneficiary.
    /// @return lockIds Array of lock IDs.
    function getLocksByBeneficiary(address beneficiary) public view returns (uint256[] memory) {
        return _lockIdsByBeneficiary[beneficiary];
    }

    /// @dev Checks the contract's current balance for a specific ERC20 token.
    /// Note: This shows the *total* held balance, not balance per lock.
    /// @param tokenAddress The address of the ERC20 token.
    /// @return balance The contract's balance of the token.
    function getAssetBalance(address tokenAddress) public view returns (uint256) {
        require(tokenAddress != address(0), "Invalid token address");
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    /// @dev Checks the owner of a specific ERC721 token.
    /// Useful to confirm the contract holds a particular NFT.
    /// @param tokenAddress The address of the ERC721 token.
    /// @param tokenId The ID of the token.
    /// @return owner Address of the token owner.
    function getNFTOwner(address tokenAddress, uint256 tokenId) public view returns (address) {
        require(tokenAddress != address(0), "Invalid token address");
        return IERC721(tokenAddress).ownerOf(tokenId);
    }


    // --- Emergency/Admin Functions ---

    /// @dev Allows the owner to rescue ERC20 tokens that were sent directly to the contract
    /// without being associated with a specific lock. Use with caution.
    /// @param tokenAddress The address of the ERC20 token to rescue.
    /// @param amount The amount of tokens to rescue.
    function rescueERC20(address tokenAddress, uint256 amount) public onlyOwner whenNotPaused {
        require(tokenAddress != address(0), "Invalid token address");
        require(amount > 0, "Amount must be greater than 0");

        IERC20 token = IERC20(tokenAddress);
         // This will revert if the contract is paused via Pausable's hook
        bool success = token.transfer(owner(), amount);
        require(success, "ERC20 rescue failed");
    }

    /// @dev Allows the owner to rescue ERC721 tokens that were sent directly to the contract
    /// without being associated with a specific lock. Use with caution.
    /// @param tokenAddress The address of the ERC721 token to rescue.
    /// @param tokenId The ID of the token to rescue.
    function rescueERC721(address tokenAddress, uint256 tokenId) public onlyOwner whenNotPaused {
         require(tokenAddress != address(0), "Invalid token address");
         IERC721 token = IERC721(tokenAddress);
         require(token.ownerOf(tokenId) == address(this), "Contract does not own this NFT");

         // Manual check for paused for ERC721 transfers
        _beforeTokenTransferERC721(address(this), owner(), tokenId);
         token.transferFrom(address(this), owner(), tokenId);
    }

    // Fallback function to prevent accidental ETH sends
    receive() external payable {
        revert("ETH not accepted");
    }

    fallback() external payable {
        revert("Call not accepted");
    }
}
```

---

**Explanation of Concepts & Complexity:**

1.  **Entangled Conditions:** Instead of a single time or event, release requires *all* conditions in a `Condition[]` array to be met. This mimics the idea of multiple factors being "entangled" and influencing the final state.
2.  **Collapse:** The lock's state `isCollapsed` becoming true when `_checkAndCollapse` determines all conditions are met. This is the "quantum collapse" – the system finalizes its state based on external observations/triggers.
3.  **Multiple Condition Types:** The `ConditionType` enum allows for extensible logic:
    *   `TimeElapsed`, `BlockReached`: Standard blockchain events.
    *   `OracleValue`: Requires interaction with a trusted oracle (simulated by `triggerOraclePriceCondition` and the `_trustedOracles` mapping). This brings off-chain data dependency.
    *   `DependentLockCollapsed`: Creates interdependencies between locks within the vault itself – a lock cannot be released until another one has collapsed. This is a form of on-chain condition entanglement.
    *   `ExternalAddressTrigger`: Allows a specific, predefined external address to manually trigger a condition as met. Useful for manual confirmation steps or off-chain processes.
4.  **Explicit Triggering:** Most complex conditions (`OracleValue`, `ExternalAddressTrigger`, `DependentLockCollapsed`) *must* be triggered by specific functions (`triggerOraclePriceCondition`, etc.), not just checked by `checkCondition` or `checkAllConditions`. This ensures access control and proper data handling for external dependencies. `checkCondition` and `checkAllConditions` primarily serve for automated conditions like time/block.
5.  **State Machine:** Each lock is a small state machine:
    *   `Created` -> `Deposited` (optional, can deposit later)
    *   `Deposited` -> `ConditionsBeingMet`
    *   `ConditionsBeingMet` -> `Collapsed` (if all met) -> `Withdrawn`
    *   `ConditionsBeingMet` -> `Cancelled` (if rules met) -> `CancelledAndReturned`
    *   States are managed via `isCollapsed` and `isCancelled` flags. Modifiers (`whenNotCollapsed`, `whenCollapsed`, `whenNotCancelled`) enforce valid state transitions for functions.
6.  **Asset Handling:** Supports both ERC20 (transferrable amounts) and ERC721 (unique tokens) within the same vault structure, requiring slightly different logic for deposit and withdrawal (`amountOrTokenId` storing either amount or token ID). Requires user approval (`approve`) before depositing.
7.  **Gas Considerations:** Using `uint64` for timestamps saves gas compared to `uint256`. Returning full dynamic arrays (`conditions`, `_lockIdsByDepositor`, `_lockIdsByBeneficiary`) in view functions can hit gas limits on some networks if the arrays are very large; this is a known limitation requiring external subgraph or off-chain indexing for large datasets in production. `getLock` returns a condition count instead of the full array as a gas-saving measure for basic lock info lookup.

This contract provides a framework for conditional asset release based on a flexible, multi-factor system that goes beyond simple time locks or single events. It's a relatively complex design requiring careful testing and consideration of how the external trigger functions would be integrated into a broader dApp or oracle network.