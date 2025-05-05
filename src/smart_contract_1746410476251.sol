```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title QuantumVault
 * @dev A creative and advanced smart contract for locking ERC20 tokens with
 *      complex, user-defined unlock conditions including time, data proofs,
 *      and probabilistic factors. Features include lockbox ownership transfer,
 *      splitting, merging, delegation, approved token management, and a
 *      guardian emergency withdrawal mechanism.
 *      NOTE: The probabilistic unlock mechanism using block data is NOT cryptographically
 *      secure against sophisticated miner manipulation in some cases. For true randomness,
 *      a solution like Chainlink VRF is recommended, but this example uses block data
 *      for illustrative purposes within a single contract.
 */

/**
 * @dev Outline:
 * 1. State Variables: Lockbox data, counters, ownership, approved tokens, guardian.
 * 2. Structs: Lockbox structure definition.
 * 3. Events: Signaling key state changes (creation, withdrawal, ownership transfer, etc.).
 * 4. Modifiers: Custom checks (e.g., onlyActiveLockbox, onlyLockboxOwnerOrDelegate).
 * 5. Constructor: Initialize owner, guardian.
 * 6. Core Vault Logic:
 *    - deposit: Create a new lockbox with specified conditions.
 *    - withdraw: Attempt to unlock and withdraw based on conditions.
 *    - isLockboxUnlockableNow: Check if conditions are currently met (view).
 *    - getCurrentProbabilisticValue: Helper view for probabilistic check.
 * 7. Lockbox Management:
 *    - transferLockboxOwnership: Change lockbox owner.
 *    - setDelegate, removeDelegate: Manage withdrawal delegation.
 *    - updateUnlockDataHash: Modify the required data proof hash before unlock.
 *    - splitLockbox: Divide a lockbox into two.
 *    - mergeLockboxes: Combine two compatible lockboxes.
 * 8. Approved Tokens Management:
 *    - addApprovedToken, removeApprovedToken, getApprovedTokens: Control which tokens can be deposited.
 * 9. Guardian & Emergency Features:
 *    - setGuardian: Assign guardian address.
 *    - pause, unpause: Pause/unpause withdrawals (Pausable).
 *    - emergencyWithdrawLockboxByGuardian: Guardian function to withdraw from a specific lockbox during pause.
 * 10. Ownership Management: Standard Ownable functions.
 * 11. View Functions: Get details about lockboxes, counts, status etc.
 */

contract QuantumVault is Ownable, Pausable {
    using Counters for Counters.Counter;
    using Math for uint256;

    Counters.Counter private _lockboxIdCounter;

    struct Lockbox {
        address owner;              // Current owner of the lockbox rights
        address tokenAddress;       // Address of the ERC20 token
        uint256 amount;             // Amount of tokens locked
        uint256 unlockTimestamp;    // Minimum Unix timestamp for unlock
        bytes32 unlockDataHash;     // Hash of required data proof (e.g., hash(password), hash(oracle_data))
        uint16 probabilisticThreshold; // Threshold for probabilistic unlock (0-10000, representing 0-100.00%)
        uint256 probabilisticSeed;  // Seed provided by user for probabilistic check
        uint256 creationBlock;      // Block number when the lockbox was created
        address delegate;           // Optional address allowed to withdraw
    }

    // Mapping from lockbox ID to Lockbox struct
    mapping(uint256 => Lockbox) public lockboxes;

    // Mapping to track lockbox IDs owned by an address (for convenient lookup)
    mapping(address => uint256[]) private _userLockboxIds;
    // Helper mapping for fast lookup of lockbox index in _userLockboxIds array
    mapping(uint256 => int256) private _lockboxIdToArrayIndex; // Use int256 to allow -1 for 'not found' or 'inactive'

    // Set of approved tokens
    mapping(address => bool) public approvedTokens;
    address[] private _approvedTokenList; // To easily retrieve the list

    // Address of the guardian who can perform emergency actions
    address public guardian;

    // --- Events ---
    event LockboxCreated(uint256 indexed lockboxId, address indexed owner, address indexed token, uint256 amount);
    event LockboxWithdrawn(uint256 indexed lockboxId, address indexed beneficiary, uint256 amount);
    event LockboxOwnershipTransferred(uint256 indexed lockboxId, address indexed oldOwner, address indexed newOwner);
    event DelegateSet(uint256 indexed lockboxId, address indexed owner, address indexed delegate);
    event DelegateRemoved(uint256 indexed lockboxId, address indexed owner, address indexed delegate);
    event LockboxSplit(uint256 indexed originalLockboxId, uint256 indexed newLockboxId, uint256 splitAmount);
    event LockboxMerged(uint256 indexed lockboxId1, uint256 indexed lockboxId2, uint256 indexed mergedLockboxId);
    event UnlockDataHashUpdated(uint256 indexed lockboxId, bytes32 newUnlockDataHash);
    event TokenApproved(address indexed token);
    event TokenRemoved(address indexed token);
    event GuardianSet(address indexed oldGuardian, address indexed newGuardian);
    event EmergencyWithdrawal(uint256 indexed lockboxId, address indexed guardian, uint256 amount);

    // --- Modifiers ---
    modifier onlyActiveLockbox(uint256 lockboxId) {
        require(lockboxes[lockboxId].amount > 0, "Lockbox does not exist or is inactive");
        _;
    }

    modifier onlyLockboxOwner(uint256 lockboxId) {
        require(lockboxes[lockboxId].owner == msg.sender, "Not lockbox owner");
        _;
    }

     modifier onlyLockboxOwnerOrDelegate(uint256 lockboxId) {
        require(lockboxes[lockboxId].owner == msg.sender || lockboxes[lockboxId].delegate == msg.sender, "Not lockbox owner or delegate");
        _;
    }

    modifier onlyGuardian() {
        require(msg.sender == guardian, "Not guardian");
        _;
    }

    // --- Constructor ---
    constructor(address initialGuardian) Ownable(msg.sender) Pausable(msg.sender) {
        guardian = initialGuardian;
        emit GuardianSet(address(0), initialGuardian);
    }

    // --- Core Vault Logic ---

    /**
     * @dev Deposits ERC20 tokens and creates a new lockbox with specific unlock conditions.
     * Requires the contract to have allowance for the amount from msg.sender.
     * @param tokenAddress Address of the ERC20 token.
     * @param amount Amount of tokens to deposit.
     * @param unlockTimestamp Minimum Unix timestamp for unlock. 0 means no time lock.
     * @param unlockDataHash Hash of the required data proof for unlock. bytes32(0) means no data proof required.
     * @param probabilisticThreshold Threshold for probabilistic unlock (0-10000, representing 0-100.00%). 0 means no probabilistic unlock.
     * @param probabilisticSeed User-provided seed for probabilistic calculation.
     * @return lockboxId The ID of the newly created lockbox.
     */
    function deposit(
        address tokenAddress,
        uint256 amount,
        uint256 unlockTimestamp,
        bytes32 unlockDataHash,
        uint16 probabilisticThreshold,
        uint256 probabilisticSeed
    ) external whenNotPaused returns (uint256 lockboxId) {
        require(amount > 0, "Amount must be greater than 0");
        require(approvedTokens[tokenAddress], "Token not approved");
        require(probabilisticThreshold <= 10000, "Probabilistic threshold out of bounds (0-10000)");

        IERC20 token = IERC20(tokenAddress);
        uint256 senderBalance = token.balanceOf(msg.sender);
        require(senderBalance >= amount, "Insufficient token balance");

        // Check allowance before transferFrom
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amount, "Insufficient token allowance");

        _lockboxIdCounter.increment();
        lockboxId = _lockboxIdCounter.current();

        lockboxes[lockboxId] = Lockbox({
            owner: msg.sender,
            tokenAddress: tokenAddress,
            amount: amount,
            unlockTimestamp: unlockTimestamp,
            unlockDataHash: unlockDataHash,
            probabilisticThreshold: probabilisticThreshold,
            probabilisticSeed: probabilisticSeed,
            creationBlock: block.number,
            delegate: address(0) // No delegate initially
        });

        _addLockboxToUser(msg.sender, lockboxId);

        // Perform the token transfer
        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");

        emit LockboxCreated(lockboxId, msg.sender, tokenAddress, amount);
    }

    /**
     * @dev Attempts to withdraw tokens from a lockbox.
     * All unlock conditions must be met.
     * @param lockboxId The ID of the lockbox.
     * @param dataProof The data proof required if unlockDataHash is not bytes32(0).
     */
    function withdraw(uint256 lockboxId, bytes memory dataProof)
        external
        whenNotPaused
        onlyActiveLockbox(lockboxId)
        onlyLockboxOwnerOrDelegate(lockboxId)
    {
        Lockbox storage lockbox = lockboxes[lockboxId];

        // 1. Check Timestamp Condition
        if (lockbox.unlockTimestamp > 0) {
            require(block.timestamp >= lockbox.unlockTimestamp, "Timestamp not met");
        }

        // 2. Check Data Proof Condition
        if (lockbox.unlockDataHash != bytes32(0)) {
            require(keccak256(dataProof) == lockbox.unlockDataHash, "Data proof invalid");
        }

        // 3. Check Probabilistic Condition (if applicable)
        if (lockbox.probabilisticThreshold > 0) {
             require(_isProbabilisticallyUnlocked(lockbox.probabilisticSeed, lockbox.creationBlock, lockbox.probabilisticThreshold), "Probabilistic condition not met");
        }

        // All conditions met, perform withdrawal
        uint256 amount = lockbox.amount;
        address tokenAddress = lockbox.tokenAddress;

        // Mark lockbox as inactive before transfer
        _removeLockboxFromUser(lockbox.owner, lockboxId);
        lockbox.amount = 0; // Mark as inactive/withdrawn
        lockbox.owner = address(0); // Clear owner
        lockbox.delegate = address(0); // Clear delegate

        // Transfer tokens to the withdrawer (owner or delegate)
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(msg.sender, amount), "Token withdrawal failed");

        emit LockboxWithdrawn(lockboxId, msg.sender, amount);
    }

     /**
     * @dev Checks if a lockbox's unlock conditions are currently met (without withdrawing).
     * This function is view and non-state changing.
     * NOTE: The probabilistic check relies on current block data and the blockhash(block.number - 1)
     * can potentially be influenced by miners on L1. Use with caution or integrate a VRF.
     * @param lockboxId The ID of the lockbox.
     * @param dataProof The data proof to check against unlockDataHash.
     * @return bool True if all conditions are met now, false otherwise.
     */
    function isLockboxUnlockableNow(uint256 lockboxId, bytes memory dataProof) public view onlyActiveLockbox(lockboxId) returns (bool) {
        Lockbox storage lockbox = lockboxes[lockboxId];

        // 1. Check Timestamp Condition
        if (lockbox.unlockTimestamp > 0) {
            if (block.timestamp < lockbox.unlockTimestamp) return false;
        }

        // 2. Check Data Proof Condition
        if (lockbox.unlockDataHash != bytes32(0)) {
            if (keccak256(dataProof) != lockbox.unlockDataHash) return false;
        }

        // 3. Check Probabilistic Condition (if applicable)
        if (lockbox.probabilisticThreshold > 0) {
            if (!_isProbabilisticallyUnlocked(lockbox.probabilisticSeed, lockbox.creationBlock, lockbox.probabilisticThreshold)) return false;
        }

        // All conditions met
        return true;
    }

    /**
     * @dev Internal helper to check the probabilistic unlock condition.
     * Uses block data and user seed to generate a pseudo-random number.
     * @param seed User provided seed.
     * @param creationBlock Block number when the lockbox was created.
     * @param threshold Probabilistic threshold (0-10000).
     * @return bool True if the generated value meets the threshold.
     */
    function _isProbabilisticallyUnlocked(uint256 seed, uint256 creationBlock, uint16 threshold) internal view returns (bool) {
        // Avoid using block.number - 1 directly with blockhash if possible,
        // as miners can manipulate it. However, blockhash is limited to the last 256 blocks.
        // Using block.timestamp or other block properties + seed is a common simple alternative
        // in single-contract examples without external VRF.
        // For demonstration, let's combine seed, block.timestamp and block.number.
        // NOT truly random or miner-resistant on its own.
        uint256 entropy = uint256(keccak256(abi.encodePacked(seed, block.timestamp, block.number)));

        // Check if the entropy value falls below the threshold percentage.
        // entropy % 10000 gives a value between 0 and 9999.
        // This represents a percentage * 100 (e.g., threshold 5000 for 50%).
        // Example: threshold 5000 (50%). We check if entropy % 10000 < 5000.
        return (entropy % 10000) < threshold;
    }

     /**
     * @dev Helper view function to see the current probabilistic value based on recent block data.
     * This is useful for testing/observing the probabilistic outcome without withdrawing.
     * Note: This uses block.timestamp/block.number and seed.
     * @param seed The probabilistic seed from the lockbox.
     * @return uint256 The calculated entropy modulo 10000, representing the 0-99.99 value.
     */
    function getCurrentProbabilisticValue(uint256 seed) public view returns (uint256) {
         uint256 entropy = uint256(keccak256(abi.encodePacked(seed, block.timestamp, block.number)));
         return entropy % 10000;
    }

    // --- Lockbox Management ---

    /**
     * @dev Transfers ownership of a lockbox to another address.
     * Only the current owner can call this.
     * @param lockboxId The ID of the lockbox.
     * @param newOwner The address to transfer ownership to.
     */
    function transferLockboxOwnership(uint256 lockboxId, address newOwner)
        external
        onlyActiveLockbox(lockboxId)
        onlyLockboxOwner(lockboxId)
    {
        require(newOwner != address(0), "New owner cannot be zero address");
        Lockbox storage lockbox = lockboxes[lockboxId];
        address oldOwner = lockbox.owner;

        _removeLockboxFromUser(oldOwner, lockboxId);
        lockbox.owner = newOwner;
        _addLockboxToUser(newOwner, lockboxId);
        lockbox.delegate = address(0); // Reset delegate on ownership transfer

        emit LockboxOwnershipTransferred(lockboxId, oldOwner, newOwner);
    }

    /**
     * @dev Sets a delegate address that is also allowed to withdraw from the lockbox.
     * Only the lockbox owner can call this.
     * @param lockboxId The ID of the lockbox.
     * @param delegateAddress The address to set as delegate.
     */
    function setDelegate(uint256 lockboxId, address delegateAddress)
        external
        onlyActiveLockbox(lockboxId)
        onlyLockboxOwner(lockboxId)
    {
         require(delegateAddress != lockboxes[lockboxId].owner, "Delegate cannot be the owner");
        lockboxes[lockboxId].delegate = delegateAddress;
        emit DelegateSet(lockboxId, msg.sender, delegateAddress);
    }

    /**
     * @dev Removes the delegate address from a lockbox.
     * Only the lockbox owner can call this.
     * @param lockboxId The ID of the lockbox.
     */
    function removeDelegate(uint256 lockboxId)
        external
        onlyActiveLockbox(lockboxId)
        onlyLockboxOwner(lockboxId)
    {
        address currentDelegate = lockboxes[lockboxId].delegate;
        require(currentDelegate != address(0), "No delegate set");
        lockboxes[lockboxId].delegate = address(0);
        emit DelegateRemoved(lockboxId, msg.sender, currentDelegate);
    }

    /**
     * @dev Updates the required data hash for unlocking a lockbox.
     * Can only be called by the owner before the unlock timestamp is reached.
     * @param lockboxId The ID of the lockbox.
     * @param newUnlockDataHash The new hash of the required data proof.
     */
    function updateUnlockDataHash(uint256 lockboxId, bytes32 newUnlockDataHash)
        external
        onlyActiveLockbox(lockboxId)
        onlyLockboxOwner(lockboxId)
    {
        require(block.timestamp < lockboxes[lockboxId].unlockTimestamp, "Cannot update after unlock timestamp");
        lockboxes[lockboxId].unlockDataHash = newUnlockDataHash;
        emit UnlockDataHashUpdated(lockboxId, newUnlockDataHash);
    }


    /**
     * @dev Splits an active lockbox into two new lockboxes with the same conditions.
     * The original lockbox amount is reduced, and a new lockbox is created with the split amount.
     * Ownership, delegate, and conditions (timestamp, datahash, probabilistic) are copied.
     * Only the lockbox owner can call this.
     * @param lockboxId The ID of the lockbox to split.
     * @param splitAmount The amount to move into the new lockbox.
     * @return newLockboxId The ID of the newly created lockbox.
     */
    function splitLockbox(uint256 lockboxId, uint256 splitAmount)
        external
        onlyActiveLockbox(lockboxId)
        onlyLockboxOwner(lockboxId)
        returns (uint256 newLockboxId)
    {
        Lockbox storage originalLockbox = lockboxes[lockboxId];
        require(splitAmount > 0 && splitAmount < originalLockbox.amount, "Invalid split amount");

        _lockboxIdCounter.increment();
        newLockboxId = _lockboxIdCounter.current();

        lockboxes[newLockboxId] = Lockbox({
            owner: originalLockbox.owner,
            tokenAddress: originalLockbox.tokenAddress,
            amount: splitAmount,
            unlockTimestamp: originalLockbox.unlockTimestamp,
            unlockDataHash: originalLockbox.unlockDataHash,
            probabilisticThreshold: originalLockbox.probabilisticThreshold,
            probabilisticSeed: originalLockbox.probabilisticSeed,
            creationBlock: originalLockbox.creationBlock, // New lockbox inherits conditions, including creation block for probabilistic check
            delegate: originalLockbox.delegate // Delegate is also copied
        });

        originalLockbox.amount = originalLockbox.amount - splitAmount;

        _addLockboxToUser(originalLockbox.owner, newLockboxId);

        emit LockboxSplit(lockboxId, newLockboxId, splitAmount);
    }

    /**
     * @dev Merges two active lockboxes belonging to the same owner into a single new lockbox.
     * Both lockboxes must hold the same token.
     * Merge conditions are combined: latest timestamp, combined probabilistic seed (XOR), highest threshold.
     * Data hashes must match or one must be bytes32(0) for the condition to be inherited.
     * Only the lockbox owner can call this.
     * @param lockboxId1 The ID of the first lockbox.
     * @param lockboxId2 The ID of the second lockbox.
     * @return mergedLockboxId The ID of the newly created merged lockbox.
     */
    function mergeLockboxes(uint256 lockboxId1, uint256 lockboxId2)
        external
        onlyActiveLockbox(lockboxId1)
        onlyActiveLockbox(lockboxId2)
        onlyLockboxOwner(lockboxId1)
        onlyLockboxOwner(lockboxId2)
        returns (uint256 mergedLockboxId)
    {
        require(lockboxId1 != lockboxId2, "Cannot merge a lockbox with itself");
        require(lockboxes[lockboxId1].tokenAddress == lockboxes[lockboxId2].tokenAddress, "Cannot merge lockboxes with different tokens");
        require(lockboxes[lockboxId1].owner == lockboxes[lockboxId2].owner, "Cannot merge lockboxes from different owners");

        Lockbox storage lb1 = lockboxes[lockboxId1];
        Lockbox storage lb2 = lockboxes[lockboxId2];

        // Combine amounts
        uint256 totalAmount = lb1.amount + lb2.amount;

        // Combine conditions:
        // - Latest timestamp applies
        uint256 newUnlockTimestamp = lb1.unlockTimestamp.max(lb2.unlockTimestamp);

        // - Data hash must match or one is zero for the condition to be inherited.
        //   If both are non-zero and different, the new data hash becomes zero (condition removed).
        bytes32 newUnlockDataHash = bytes32(0);
        if (lb1.unlockDataHash == lb2.unlockDataHash) {
            newUnlockDataHash = lb1.unlockDataHash;
        } else if (lb1.unlockDataHash == bytes32(0)) {
             newUnlockDataHash = lb2.unlockDataHash;
        } else if (lb2.unlockDataHash == bytes32(0)) {
             newUnlockDataHash = lb1.unlockDataHash;
        }
        // If both non-zero and different, newUnlockDataHash remains bytes32(0)

        // - Combine probabilistic seeds (using XOR)
        uint256 newProbabilisticSeed = lb1.probabilisticSeed ^ lb2.probabilisticSeed;

        // - Stricter threshold applies (higher value)
        uint16 newProbabilisticThreshold = lb1.probabilisticThreshold > lb2.probabilisticThreshold ? lb1.probabilisticThreshold : lb2.probabilisticThreshold;

        // - New lockbox creation block is the later of the two original creation blocks
        uint256 newCreationBlock = lb1.creationBlock > lb2.creationBlock ? lb1.creationBlock : lb2.creationBlock;


        _lockboxIdCounter.increment();
        mergedLockboxId = _lockboxIdCounter.current();

        lockboxes[mergedLockboxId] = Lockbox({
            owner: msg.sender, // Owner is the caller (must be original owner)
            tokenAddress: lb1.tokenAddress,
            amount: totalAmount,
            unlockTimestamp: newUnlockTimestamp,
            unlockDataHash: newUnlockDataHash,
            probabilisticThreshold: newProbabilisticThreshold,
            probabilisticSeed: newProbabilisticSeed,
            creationBlock: newCreationBlock,
            delegate: address(0) // Delegate is reset on merge
        });

        // Invalidate the original lockboxes
        _removeLockboxFromUser(msg.sender, lockboxId1);
        lb1.amount = 0;
        lb1.owner = address(0);
        lb1.delegate = address(0);

        _removeLockboxFromUser(msg.sender, lockboxId2);
        lb2.amount = 0;
        lb2.owner = address(0);
        lb2.delegate = address(0);

        // Add the new merged lockbox to the owner
        _addLockboxToUser(msg.sender, mergedLockboxId);

        emit LockboxMerged(lockboxId1, lockboxId2, mergedLockboxId);
    }

    // --- Approved Tokens Management ---

    /**
     * @dev Adds an ERC20 token to the list of approved tokens that can be deposited.
     * Only contract owner can call this.
     * @param tokenAddress The address of the token to approve.
     */
    function addApprovedToken(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0), "Token address cannot be zero");
        require(!approvedTokens[tokenAddress], "Token already approved");
        approvedTokens[tokenAddress] = true;
        _approvedTokenList.push(tokenAddress);
        emit TokenApproved(tokenAddress);
    }

    /**
     * @dev Removes an ERC20 token from the list of approved tokens.
     * Existing lockboxes with this token remain valid, but new deposits are blocked.
     * Only contract owner can call this.
     * @param tokenAddress The address of the token to remove.
     */
    function removeApprovedToken(address tokenAddress) external onlyOwner {
        require(approvedTokens[tokenAddress], "Token not approved");
        approvedTokens[tokenAddress] = false;
        // Find and remove from the list (simple linear scan, potentially gas-heavy for long lists)
        for (uint i = 0; i < _approvedTokenList.length; i++) {
            if (_approvedTokenList[i] == tokenAddress) {
                _approvedTokenList[i] = _approvedTokenList[_approvedTokenList.length - 1];
                _approvedTokenList.pop();
                break;
            }
        }
        emit TokenRemoved(tokenAddress);
    }

     /**
     * @dev Gets the list of approved token addresses.
     * @return address[] An array of approved token addresses.
     */
    function getApprovedTokens() external view returns (address[] memory) {
        return _approvedTokenList;
    }

    // --- Guardian & Emergency Features ---

    /**
     * @dev Sets the address of the guardian.
     * Only contract owner can call this.
     * @param newGuardian The address to set as guardian.
     */
    function setGuardian(address newGuardian) external onlyOwner {
        require(newGuardian != address(0), "Guardian address cannot be zero");
        address oldGuardian = guardian;
        guardian = newGuardian;
        emit GuardianSet(oldGuardian, newGuardian);
    }

    /**
     * @dev Allows the guardian to withdraw tokens from a specific lockbox.
     * This function is intended for emergency situations (e.g., owner/delegate lost keys, contract bug).
     * Requires the contract to be paused by owner or guardian.
     * Guardian cannot bypass unlock conditions; this is only for recovery if withdrawal is stuck *after* conditions are met.
     * Or, define this as a force withdrawal *during pause* regardless of conditions for true emergency recovery.
     * Let's make it a force withdrawal *during pause* to allow recovery even if conditions are not met due to external factors (e.g. oracle failure).
     * @param lockboxId The ID of the lockbox to withdraw from.
     */
    function emergencyWithdrawLockboxByGuardian(uint256 lockboxId)
        external
        onlyGuardian
        onlyActiveLockbox(lockboxId)
        whenPaused // Only allowed when paused
    {
        Lockbox storage lockbox = lockboxes[lockboxId];
        uint256 amount = lockbox.amount;
        address tokenAddress = lockbox.tokenAddress;
        address originalOwner = lockbox.owner; // Withdraw to original owner? Or guardian? Let's withdraw to guardian for emergency custody.

        // Mark lockbox as inactive before transfer
        _removeLockboxFromUser(originalOwner, lockboxId); // Remove from owner's list
        lockbox.amount = 0; // Mark as inactive/withdrawn
        lockbox.owner = address(0); // Clear owner
        lockbox.delegate = address(0); // Clear delegate

        // Transfer tokens to the guardian
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(msg.sender, amount), "Emergency token withdrawal failed");

        emit EmergencyWithdrawal(lockboxId, msg.sender, amount);
    }

    // --- Owner Functions (inherited from Ownable) ---
    // renounceOwnership()
    // transferOwnership(address newOwner)


    // --- Pausable Functions (inherited from Pausable) ---
    // pause()
    // unpause()
    // paused()

    // Override pause/unpause to allow guardian
    function pause() public virtual override onlyOwnerOrGuardian {
        _pause();
    }

    function unpause() public virtual override onlyOwnerOrGuardian {
        _unpause();
    }

    modifier onlyOwnerOrGuardian() {
        require(owner() == msg.sender || guardian == msg.sender, "Not owner or guardian");
        _;
    }


    // --- View Functions ---

    /**
     * @dev Gets the number of active lockboxes.
     * @return uint256 Total count of active lockboxes.
     */
    function getLockboxCount() external view returns (uint256) {
        return _lockboxIdCounter.current();
    }

    /**
     * @dev Gets the list of lockbox IDs owned by a specific address.
     * @param user The address of the owner.
     * @return uint256[] An array of lockbox IDs.
     */
    function getUserLockboxIds(address user) external view returns (uint256[] memory) {
        return _userLockboxIds[user];
    }

     /**
     * @dev Gets the number of lockboxes owned by a specific address.
     * @param user The address of the owner.
     * @return uint256 The number of lockboxes owned by the user.
     */
    function getOwnerLockboxCount(address user) external view returns (uint256) {
        return _userLockboxIds[user].length;
    }

    /**
     * @dev Gets the token address for a specific lockbox.
     * @param lockboxId The ID of the lockbox.
     * @return address The token address.
     */
    function getLockboxToken(uint256 lockboxId) public view onlyActiveLockbox(lockboxId) returns (address) {
        return lockboxes[lockboxId].tokenAddress;
    }

    /**
     * @dev Gets the amount of tokens in a specific lockbox.
     * @param lockboxId The ID of the lockbox.
     * @return uint256 The token amount.
     */
    function getLockboxAmount(uint256 lockboxId) public view onlyActiveLockbox(lockboxId) returns (uint256) {
        return lockboxes[lockboxId].amount;
    }

     /**
     * @dev Gets the owner address of a specific lockbox.
     * @param lockboxId The ID of the lockbox.
     * @return address The owner address.
     */
    function getLockboxOwner(uint256 lockboxId) public view onlyActiveLockbox(lockboxId) returns (address) {
        return lockboxes[lockboxId].owner;
    }

     /**
     * @dev Gets the delegate address of a specific lockbox.
     * @param lockboxId The ID of the lockbox.
     * @return address The delegate address.
     */
    function getLockboxDelegate(uint256 lockboxId) public view onlyActiveLockbox(lockboxId) returns (address) {
        return lockboxes[lockboxId].delegate;
    }

    /**
     * @dev Checks if an address is the delegate for a specific lockbox.
     * @param lockboxId The ID of the lockbox.
     * @param account The address to check.
     * @return bool True if the account is the delegate, false otherwise.
     */
    function isDelegate(uint256 lockboxId, address account) public view onlyActiveLockbox(lockboxId) returns (bool) {
        return lockboxes[lockboxId].delegate == account;
    }

    /**
     * @dev Gets the unlock timestamp for a specific lockbox.
     * @param lockboxId The ID of the lockbox.
     * @return uint256 The unlock timestamp.
     */
    function getLockboxUnlockTimestamp(uint256 lockboxId) public view onlyActiveLockbox(lockboxId) returns (uint256) {
        return lockboxes[lockboxId].unlockTimestamp;
    }

     /**
     * @dev Gets the unlock data hash for a specific lockbox.
     * @param lockboxId The ID of the lockbox.
     * @return bytes32 The unlock data hash.
     */
    function getLockboxUnlockDataHash(uint256 lockboxId) public view onlyActiveLockbox(lockboxId) returns (bytes32) {
        return lockboxes[lockboxId].unlockDataHash;
    }

    /**
     * @dev Gets the probabilistic threshold for a specific lockbox.
     * @param lockboxId The ID of the lockbox.
     * @return uint16 The probabilistic threshold (0-10000).
     */
    function getLockboxProbabilisticThreshold(uint256 lockboxId) public view onlyActiveLockbox(lockboxId) returns (uint16) {
        return lockboxes[lockboxId].probabilisticThreshold;
    }

     /**
     * @dev Gets the probabilistic seed for a specific lockbox.
     * @param lockboxId The ID of the lockbox.
     * @return uint256 The probabilistic seed.
     */
    function getLockboxProbabilisticSeed(uint256 lockboxId) public view onlyActiveLockbox(lockboxId) returns (uint256) {
        return lockboxes[lockboxId].probabilisticSeed;
    }

    /**
     * @dev Gets the creation block for a specific lockbox.
     * @param lockboxId The ID of the lockbox.
     * @return uint256 The creation block number.
     */
    function getLockboxCreationBlock(uint256 lockboxId) public view onlyActiveLockbox(lockboxId) returns (uint256) {
        return lockboxes[lockboxId].creationBlock;
    }

     /**
     * @dev Checks if a lockbox is active (has tokens).
     * @param lockboxId The ID of the lockbox.
     * @return bool True if the lockbox is active, false otherwise.
     */
    function isLockboxActive(uint256 lockboxId) public view returns (bool) {
        return lockboxes[lockboxId].amount > 0;
    }

     /**
     * @dev Gets the current guardian address.
     * @return address The guardian address.
     */
    function getGuardian() external view returns (address) {
        return guardian;
    }


    // --- Internal Helper Functions ---

    /**
     * @dev Adds a lockbox ID to a user's list and updates the index map.
     * @param user The user's address.
     * @param lockboxId The lockbox ID to add.
     */
    function _addLockboxToUser(address user, uint256 lockboxId) internal {
        _userLockboxIds[user].push(lockboxId);
        _lockboxIdToArrayIndex[lockboxId] = int256(_userLockboxIds[user].length - 1);
    }

    /**
     * @dev Removes a lockbox ID from a user's list and updates the index map.
     * Uses the swap-and-pop method for efficiency.
     * @param user The user's address.
     * @param lockboxId The lockbox ID to remove.
     */
    function _removeLockboxFromUser(address user, uint256 lockboxId) internal {
        int256 index = _lockboxIdToArrayIndex[lockboxId];
        if (index == -1) return; // Should not happen for active lockboxes, but good practice

        uint256 lastIndex = _userLockboxIds[user].length - 1;
        if (uint256(index) != lastIndex) {
            // Move the last element to the position of the element to delete
            uint256 lastLockboxId = _userLockboxIds[user][lastIndex];
            _userLockboxIds[user][uint256(index)] = lastLockboxId;
            _lockboxIdToArrayIndex[lastLockboxId] = index;
        }

        // Remove the last element (which is now the duplicate or the original element to delete)
        _userLockboxIds[user].pop();
        _lockboxIdToArrayIndex[lockboxId] = -1; // Mark as inactive in index map
    }
}
```