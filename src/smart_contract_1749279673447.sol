Okay, here is a Solidity smart contract featuring a `DynamicNFTVault`. This contract allows users to deposit ERC721 NFTs, lock them for periods to potentially earn yield (represented by a separate ERC20 token), bond deposited NFTs together, and manage dynamic metadata/access for their vaulted items.

It incorporates concepts like:
*   **Vaulting:** Securely holding external ERC721 tokens.
*   **Dynamic Properties:** Simulating dynamic aspects of the NFT *within the vault* (metadata URI, yield multiplier) based on vault state (e.g., lock duration).
*   **Time-Based Mechanics:** Locking periods, time-accruing yield.
*   **Bonding:** Linking multiple deposited NFTs within the vault.
*   **Permissioning:** Allowing other users controlled access/interaction with a vaulted position.
*   **Yield Distribution:** A basic mechanism for distributing an ERC20 token to position holders based on their accrued yield.

It aims to be creative by combining these elements in a specific vault context, going beyond simple staking or basic NFT ownership.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// --- Outline ---
// 1. Contract Definition: DynamicNFTVault
// 2. External Dependencies: IERC721, IERC20 (standard interfaces)
// 3. Errors: Custom errors for specific failure conditions
// 4. Events: Signaling key actions
// 5. Enums: Defining states for Vault Positions
// 6. Structs: Defining the structure of a Vault Position
// 7. State Variables: Storing contract data (owner, position data, etc.)
// 8. Modifiers: (Using require statements for simplicity in this example)
// 9. Constructor: Initializes the contract
// 10. Functions:
//    - Core Vault Operations (Deposit, Withdraw, Get Position Info)
//    - Locking & Time-Based Mechanics (Lock, Extend Lock, Unlock, Check Lock Status)
//    - Dynamic Properties & Metadata (Update Metadata, Get Metadata, Calculate Multiplier)
//    - Yield & Token Distribution (Distribute Yield Token, Claim Yield, Calculate Pending Yield, Set Yield Rates, Get Total Claimable)
//    - Advanced Features (Bond/Unbond Positions, Manage Permissions, Transfer Position)
//    - Owner/Admin Functions (Ownership management, Emergency withdrawal)
//    - Helper/View Functions (Many of the "Get" and "Check" functions)

// --- Function Summary ---
// 1. constructor(address initialOwner, address yieldTokenAddress): Initializes the contract, setting the owner and the ERC20 yield token.
// 2. depositNFT(address nftContract, uint256 tokenId): Allows a user to deposit an ERC721 NFT into the vault, creating a new vault position. Requires prior approval.
// 3. withdrawNFT(uint256 positionId): Allows the owner of an unlocked vault position to withdraw the underlying NFT.
// 4. cancelPendingWithdrawal(uint256 positionId): Allows the owner of a position in PENDING_WITHDRAWAL state to revert it to UNLOCKED.
// 5. lockNFT(uint256 positionId, uint256 lockDurationInSeconds): Locks an UNLOCKED or EMPTY position for a specified duration, starting yield calculation.
// 6. extendLockDuration(uint256 positionId, uint256 additionalDurationInSeconds): Extends the lock end time for a LOCKED position.
// 7. unlockNFT(uint256 positionId): Transitions a LOCKED position to UNLOCKED status once the lock duration has passed. Triggers yield calculation up to unlock time.
// 8. bondPositions(uint256 positionId1, uint256 positionId2): Links two vault positions owned by the caller, potentially affecting yield or metadata (depending on implementation logic in calculateYield).
// 9. unbondPositions(uint256 positionId1, uint256 positionId2): Breaks the bond between two linked positions.
// 10. addPermittedUser(uint256 positionId, address user): Allows the position owner to grant a user permission (e.g., to update metadata).
// 11. removePermittedUser(uint256 positionId, address user): Allows the position owner to revoke a user's permission.
// 12. updateDynamicMetadataUri(uint256 positionId, string memory newUri): Allows position owner or a permitted user to update the dynamic metadata URI for the position.
// 13. distributeYieldToken(uint256 amount): Allows the contract owner to deposit yield tokens into the vault for distribution.
// 14. claimYield(uint256 positionId): Allows the position owner to claim accumulated yield for a specific position.
// 15. claimAllYield(): Allows the caller to claim accumulated yield for all their positions.
// 16. setLockDurationYieldMultiplier(uint256 lockDurationInSeconds, uint256 multiplier): Allows the owner to configure yield multiplier rates for different lock durations.
// 17. transferPositionOwnership(uint256 positionId, address newOwner): Allows a position owner to transfer ownership of their vault position (and the underlying NFT within it) to another address.
// 18. forceWithdrawNFT(uint256 positionId, address recipient): Owner function for emergency withdrawal of an NFT to any address. Use with caution.
// 19. getVaultPosition(uint256 positionId): View function to retrieve details of a specific vault position.
// 20. getUserPositions(address user): View function to get all position IDs owned by a user.
// 21. isLocked(uint256 positionId): View function to check if a position is currently locked.
// 22. getDynamicMetadataUri(uint256 positionId): View function to get the current dynamic metadata URI for a position.
// 23. getCalculatedYieldMultiplier(uint256 positionId): View function to get the currently calculated yield multiplier for a position.
// 24. calculatePendingYield(uint256 positionId): View function to calculate the yield accrued for a position since the last claim or lock start.
// 25. getTotalClaimableYield(address user): View function to get the total claimable yield across all positions owned by a user.
// 26. getBondedPositions(uint256 positionId): View function to get the list of position IDs bonded to a given position.
// 27. isPermittedUser(uint256 positionId, address user): View function to check if a user has permission on a position.
// 28. owner(): View function to get the contract owner.
// 29. transferOwnership(address newOwner): Allows the owner to transfer contract ownership.
// 30. renounceOwnership(): Allows the owner to renounce contract ownership (sets owner to zero address).

// --- Smart Contract Implementation ---

contract DynamicNFTVault {
    // --- Errors ---
    error NotOwner();
    error NotPositionOwner(uint256 positionId, address caller);
    error PositionNotFound(uint256 positionId);
    error PositionNotEmpty(uint256 positionId);
    error PositionStatusMismatch(uint256 positionId, VaultStatus expectedStatus, VaultStatus currentStatus);
    error NotApprovedOrOwner(); // For deposit
    error AlreadyBonded(uint256 positionId1, uint256 positionId2);
    error NotBonded(uint256 positionId1, uint256 positionId2);
    error CannotBondToSelf();
    error NotPermitted(uint256 positionId, address caller);
    error InsufficientYieldTokens(uint256 requestedAmount, uint256 contractBalance);
    error InvalidLockDuration();
    error DepositRequiresApproval();
    error WithdrawalNotAllowedWhileLocked(uint256 positionId);
    error PositionAlreadyUnlocked(uint256 positionId);

    // --- Events ---
    event NFTDeposited(uint256 positionId, address indexed depositor, address indexed nftContract, uint256 tokenId, uint256 timestamp);
    event NFTWithdrawn(uint256 positionId, address indexed recipient, address indexed nftContract, uint256 tokenId, uint256 timestamp);
    event PositionLocked(uint256 positionId, uint256 lockDuration, uint256 lockEndTime, uint256 timestamp);
    event LockDurationExtended(uint256 positionId, uint256 newLockEndTime, uint256 timestamp);
    event PositionUnlocked(uint256 positionId, uint256 timestamp);
    event PositionsBonded(uint256 indexed positionId1, uint256 indexed positionId2, uint256 timestamp);
    event PositionsUnbonded(uint256 indexed positionId1, uint256 indexed positionId2, uint256 timestamp);
    event PermittedUserAdded(uint256 positionId, address indexed user, uint256 timestamp);
    event PermittedUserRemoved(uint256 positionId, address indexed user, uint256 timestamp);
    event DynamicMetadataUriUpdated(uint256 positionId, string newUri, uint256 timestamp);
    event YieldTokensDistributed(address indexed distributor, uint256 amount, uint256 timestamp);
    event YieldClaimed(uint256 positionId, address indexed claimant, uint256 amount, uint256 timestamp);
    event LockDurationYieldMultiplierSet(uint256 lockDuration, uint256 multiplier);
    event PositionOwnershipTransferred(uint256 positionId, address indexed oldOwner, address indexed newOwner, uint256 timestamp);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event EmergencyWithdrawal(uint256 positionId, address indexed recipient, address indexed nftContract, uint256 tokenId, uint256 timestamp);
    event PendingWithdrawalCancelled(uint256 positionId, uint256 timestamp);


    // --- Enums ---
    enum VaultStatus {
        Empty,             // Position slot is available or has been withdrawn from
        Locked,            // Position holds an NFT and is time-locked
        Unlocked,          // Position holds an NFT and is not time-locked
        PendingWithdrawal  // Position is marked for withdrawal but not yet processed
    }

    // --- Structs ---
    struct VaultPosition {
        VaultStatus status;
        address owner;
        address nftContract;
        uint256 tokenId;
        uint256 lockStartTime;
        uint256 lockEndTime;      // 0 if not locked
        uint256 lastYieldClaimTime; // Timestamp of the last yield claim for this position
        uint256 claimableYield;   // Accumulated but unclaimed yield (in yieldToken decimals)
        string dynamicMetadataUri;
        uint256[] bondedPositions; // List of position IDs this position is bonded to
        mapping(address => bool) permittedUsers; // Users granted permissions by the position owner
    }

    // --- State Variables ---
    address private _owner;
    IERC20 public immutable yieldToken; // The token used for yield distribution

    uint256 private _nextPositionId; // Counter for unique position IDs
    mapping(uint256 => VaultPosition) private _vaultPositions; // Position ID => Position details
    mapping(address => uint256[]) private _userPositions; // User address => List of position IDs they own

    // Configuration for yield multiplier based on lock duration
    // Lock Duration (seconds) => Multiplier (e.g., 1000 means 1x yield, 2000 means 2x yield)
    mapping(uint256 => uint256) public lockDurationToYieldMultiplier;

    // --- Constructor ---
    constructor(address initialOwner, address yieldTokenAddress) {
        if (initialOwner == address(0)) revert NotOwner();
        if (yieldTokenAddress == address(0)) revert InsufficientYieldTokens(0,0); // Use InsufficientYieldTokens error creatively

        _owner = initialOwner;
        yieldToken = IERC20(yieldTokenAddress);
        _nextPositionId = 1; // Start position IDs from 1
        emit OwnershipTransferred(address(0), initialOwner);
    }

    // --- Modifiers (using require/revert instead for simplicity) ---

    // --- Functions ---

    /**
     * @notice Allows a user to deposit an ERC721 NFT into the vault.
     * @param nftContract The address of the ERC721 contract.
     * @param tokenId The ID of the token to deposit.
     */
    function depositNFT(address nftContract, uint256 tokenId) external {
        if (nftContract == address(0)) revert PositionNotFound(0); // Using position not found for invalid address
        IERC721 nft = IERC721(nftContract);

        // Check if the vault is approved to transfer the token or if msg.sender is the owner
        // This relies on ERC721 standard requires
        if (nft.getApproved(tokenId) != address(this) && nft.ownerOf(tokenId) != msg.sender) {
             revert NotApprovedOrOwner(); // Custom error for clarity
        }
        if (nft.ownerOf(tokenId) == address(0)) {
            revert PositionNotFound(0); // Token doesn't exist or not owned
        }

        // Transfer the NFT to the vault
        nft.safeTransferFrom(msg.sender, address(this), tokenId);

        // Create a new vault position
        uint256 newPositionId = _nextPositionId++;
        VaultPosition storage newPosition = _vaultPositions[newPositionId];

        newPosition.status = VaultStatus.Unlocked; // Starts unlocked
        newPosition.owner = msg.sender;
        newPosition.nftContract = nftContract;
        newPosition.tokenId = tokenId;
        newPosition.lockStartTime = 0; // Not locked initially
        newPosition.lockEndTime = 0;   // Not locked initially
        newPosition.lastYieldClaimTime = block.timestamp; // Set claim time to now
        newPosition.claimableYield = 0;
        // dynamicMetadataUri and bondedPositions are default initialized

        _userPositions[msg.sender].push(newPositionId);

        emit NFTDeposited(newPositionId, msg.sender, nftContract, tokenId, block.timestamp);
    }

    /**
     * @notice Allows the owner of an unlocked vault position to withdraw the underlying NFT.
     * @param positionId The ID of the vault position to withdraw from.
     */
    function withdrawNFT(uint256 positionId) external {
        VaultPosition storage position = _getVaultPosition(positionId);

        if (position.owner != msg.sender) revert NotPositionOwner(positionId, msg.sender);
        if (position.status == VaultStatus.Empty) revert PositionStatusMismatch(positionId, VaultStatus.Unlocked, position.status); // Can only withdraw if not empty
        if (position.status == VaultStatus.Locked) revert WithdrawalNotAllowedWhileLocked(positionId);

        // Claim any pending yield before withdrawal
        _claimYield(positionId);

        // Transfer the NFT back to the position owner
        IERC721(position.nftContract).safeTransferFrom(address(this), position.owner, position.tokenId);

        // Mark the position as Empty and clear details
        position.status = VaultStatus.Empty;
        position.owner = address(0);
        // nftContract, tokenId, lock times, yield details are kept for historical reference until overwritten
        // Clear sensitive mappings if necessary, e.g., position.permittedUsers = new mapping(address => bool)(); - This is complex to clear entirely. Let's just rely on status.
        position.bondedPositions = new uint256[](0); // Clear bonds on withdrawal

        // Remove position ID from user's list (optional but good practice)
        _removePositionFromUserList(msg.sender, positionId);

        emit NFTWithdrawn(positionId, msg.sender, position.nftContract, position.tokenId, block.timestamp);
    }

    /**
     * @notice Allows the owner of a position in PENDING_WITHDRAWAL state to revert it to UNLOCKED.
     * This assumes PENDING_WITHDRAWAL is a valid state introduced later for complex flows,
     * but for now, this function acts as a placeholder or example for status transition cancellation.
     * In this version, it primarily allows cancelling a state that wasn't fully processed.
     * @param positionId The ID of the vault position.
     */
    function cancelPendingWithdrawal(uint256 positionId) external {
         VaultPosition storage position = _getVaultPosition(positionId);

        if (position.owner != msg.sender) revert NotPositionOwner(positionId, msg.sender);
        // Assuming PENDING_WITHDRAWAL exists as a status state...
        // if (position.status != VaultStatus.PendingWithdrawal) revert PositionStatusMismatch(positionId, VaultStatus.PendingWithdrawal, position.status);

        // In this simplified version, we just ensure it's not Empty and owned by caller
        // If it's PENDING_WITHDRAWAL, revert to UNLOCKED
        // If it's UNLOCKED, do nothing or confirm
        if (position.status != VaultStatus.Empty) {
            position.status = VaultStatus.Unlocked;
            emit PendingWithdrawalCancelled(positionId, block.timestamp);
        } else {
             revert PositionStatusMismatch(positionId, VaultStatus.Unlocked, position.status); // Or a more specific error
        }
    }


    /**
     * @notice Locks an UNLOCKED or EMPTY position for a specified duration, starting yield calculation.
     * @param positionId The ID of the vault position to lock.
     * @param lockDurationInSeconds The duration to lock the position for.
     */
    function lockNFT(uint256 positionId, uint256 lockDurationInSeconds) external {
        VaultPosition storage position = _getVaultPosition(positionId);

        if (position.owner != msg.sender) revert NotPositionOwner(positionId, msg.sender);
        if (position.status == VaultStatus.Locked) revert PositionStatusMismatch(positionId, VaultStatus.Unlocked, position.status);
        if (position.status == VaultStatus.Empty) revert PositionNotEmpty(positionId); // Cannot lock an empty slot

        if (lockDurationInSeconds == 0) revert InvalidLockDuration();

        // Claim any pending yield before starting a new lock
        _claimYield(positionId);

        position.status = VaultStatus.Locked;
        position.lockStartTime = block.timestamp;
        position.lockEndTime = block.timestamp + lockDurationInSeconds;
        position.lastYieldClaimTime = block.timestamp; // Reset claim time for new lock period

        emit PositionLocked(positionId, lockDurationInSeconds, position.lockEndTime, block.timestamp);
    }

     /**
      * @notice Extends the lock end time for a LOCKED position.
      * @param positionId The ID of the vault position.
      * @param additionalDurationInSeconds The duration to add to the existing lock.
      */
     function extendLockDuration(uint256 positionId, uint256 additionalDurationInSeconds) external {
         VaultPosition storage position = _getVaultPosition(positionId);

         if (position.owner != msg.sender) revert NotPositionOwner(positionId, msg.sender);
         if (position.status != VaultStatus.Locked) revert PositionStatusMismatch(positionId, VaultStatus.Locked, position.status);

         if (additionalDurationInSeconds == 0) revert InvalidLockDuration();

         // Claim any yield accrued up to the current time before extending
         _claimYield(positionId);

         position.lockEndTime += additionalDurationInSeconds;
         position.lastYieldClaimTime = block.timestamp; // Reset claim time for new extended period

         emit LockDurationExtended(positionId, position.lockEndTime, block.timestamp);
     }


    /**
     * @notice Transitions a LOCKED position to UNLOCKED status once the lock duration has passed.
     * @param positionId The ID of the vault position.
     */
    function unlockNFT(uint256 positionId) external {
        VaultPosition storage position = _getVaultPosition(positionId);

        if (position.owner != msg.sender) revert NotPositionOwner(positionId, msg.sender);
        if (position.status != VaultStatus.Locked) revert PositionStatusMismatch(positionId, VaultStatus.Locked, position.status);
        if (block.timestamp < position.lockEndTime) revert PositionStatusMismatch(positionId, VaultStatus.Unlocked, position.status); // Not yet unlocked

        // Claim any yield accrued up to the lock end time
        _claimYield(positionId); // This will calculate yield up to lockEndTime

        position.status = VaultStatus.Unlocked;
        // Keep lock times for history, clear yield details on claim
        // lastYieldClaimTime is set by _claimYield

        emit PositionUnlocked(positionId, block.timestamp);
    }

    /**
     * @notice Links two vault positions owned by the caller.
     * Bonding can influence dynamic properties or yield multiplier calculations.
     * @param positionId1 The ID of the first vault position.
     * @param positionId2 The ID of the second vault position.
     */
    function bondPositions(uint256 positionId1, uint256 positionId2) external {
        if (positionId1 == positionId2) revert CannotBondToSelf();

        VaultPosition storage pos1 = _getVaultPosition(positionId1);
        VaultPosition storage pos2 = _getVaultPosition(positionId2);

        if (pos1.owner != msg.sender) revert NotPositionOwner(positionId1, msg.sender);
        if (pos2.owner != msg.sender) revert NotPositionOwner(positionId2, msg.sender);

        // Prevent bonding if already bonded
        for (uint i = 0; i < pos1.bondedPositions.length; i++) {
            if (pos1.bondedPositions[i] == positionId2) {
                revert AlreadyBonded(positionId1, positionId2);
            }
        }

        pos1.bondedPositions.push(positionId2);
        pos2.bondedPositions.push(positionId1);

        emit PositionsBonded(positionId1, positionId2, block.timestamp);
    }

    /**
     * @notice Breaks the bond between two linked positions.
     * @param positionId1 The ID of the first vault position.
     * @param positionId2 The ID of the second vault position.
     */
    function unbondPositions(uint256 positionId1, uint256 positionId2) external {
         if (positionId1 == positionId2) revert CannotBondToSelf();

        VaultPosition storage pos1 = _getVaultPosition(positionId1);
        VaultPosition storage pos2 = _getVaultPosition(positionId2);

        if (pos1.owner != msg.sender) revert NotPositionOwner(positionId1, msg.sender);
        if (pos2.owner != msg.sender) revert NotPositionOwner(positionId2, msg.sender);

        // Find and remove bond reference in pos1
        bool found1 = false;
        for (uint i = 0; i < pos1.bondedPositions.length; i++) {
            if (pos1.bondedPositions[i] == positionId2) {
                pos1.bondedPositions[i] = pos1.bondedPositions[pos1.bondedPositions.length - 1];
                pos1.bondedPositions.pop();
                found1 = true;
                break;
            }
        }

        // Find and remove bond reference in pos2
        bool found2 = false;
        for (uint i = 0; i < pos2.bondedPositions.length; i++) {
            if (pos2.bondedPositions[i] == positionId1) {
                pos2.bondedPositions[i] = pos2.bondedPositions[pos2.bondedPositions.length - 1];
                pos2.bondedPositions.pop();
                found2 = true;
                break;
            }
        }

        if (!found1 || !found2) revert NotBonded(positionId1, positionId2); // Should be bonded on both sides if bonded

        emit PositionsUnbonded(positionId1, positionId2, block.timestamp);
    }

    /**
     * @notice Allows the position owner to grant a user permission to interact with their position (e.g., update metadata).
     * @param positionId The ID of the vault position.
     * @param user The address to grant permission to.
     */
    function addPermittedUser(uint256 positionId, address user) external {
        VaultPosition storage position = _getVaultPosition(positionId);

        if (position.owner != msg.sender) revert NotPositionOwner(positionId, msg.sender);
        if (user == address(0)) revert NotPermitted(positionId, address(0)); // Invalid user address

        position.permittedUsers[user] = true;

        emit PermittedUserAdded(positionId, user, block.timestamp);
    }

     /**
      * @notice Allows the position owner to revoke a user's permission on their position.
      * @param positionId The ID of the vault position.
      * @param user The address to revoke permission from.
      */
    function removePermittedUser(uint256 positionId, address user) external {
        VaultPosition storage position = _getVaultPosition(positionId);

        if (position.owner != msg.sender) revert NotPositionOwner(positionId, msg.sender);
         if (user == address(0)) revert NotPermitted(positionId, address(0)); // Invalid user address

        delete position.permittedUsers[user];

        emit PermittedUserRemoved(positionId, user, block.timestamp);
    }

    /**
     * @notice Allows position owner or a permitted user to update the dynamic metadata URI for the position.
     * This URL could point to a JSON file describing the state of the NFT within the vault (e.g., locked status, yield earned, bonds).
     * @param positionId The ID of the vault position.
     * @param newUri The new URI for the dynamic metadata.
     */
    function updateDynamicMetadataUri(uint256 positionId, string memory newUri) external {
        VaultPosition storage position = _getVaultPosition(positionId);

        // Only position owner or permitted user can update
        if (position.owner != msg.sender && !position.permittedUsers[msg.sender]) {
            revert NotPermitted(positionId, msg.sender);
        }

        position.dynamicMetadataUri = newUri;

        emit DynamicMetadataUriUpdated(positionId, newUri, block.timestamp);
    }

    /**
     * @notice Allows the contract owner to deposit yield tokens into the vault for distribution.
     * @param amount The amount of yield tokens to deposit.
     */
    function distributeYieldToken(uint256 amount) external {
        if (msg.sender != _owner) revert NotOwner();
        if (amount == 0) revert InsufficientYieldTokens(0, yieldToken.balanceOf(address(this))); // Use error for zero amount

        // Transfer tokens from the owner to the contract
        // Requires owner to approve the contract first
        bool success = yieldToken.transferFrom(msg.sender, address(this), amount);
        if (!success) revert InsufficientYieldTokens(amount, yieldToken.balanceOf(address(this)));

        emit YieldTokensDistributed(msg.sender, amount, block.timestamp);
    }

    /**
     * @notice Allows the position owner to claim accumulated yield for a specific position.
     * @param positionId The ID of the vault position.
     */
    function claimYield(uint256 positionId) external {
        VaultPosition storage position = _getVaultPosition(positionId);

        if (position.owner != msg.sender) revert NotPositionOwner(positionId, msg.sender);

        _claimYield(positionId);
    }

    /**
     * @notice Internal function to calculate and transfer yield for a position.
     * @param positionId The ID of the vault position.
     */
    function _claimYield(uint256 positionId) internal {
         VaultPosition storage position = _vaultPositions[positionId]; // Use direct access, assumes validation happened before

        // Calculate yield accrued since last claim
        uint256 pending = calculatePendingYield(positionId);

        // Add to claimable balance
        position.claimableYield += pending;

        // Update last claim time
        // Claim time should be updated based on how yield was calculated
        // If yield accrues only while locked, set last claim time to the end of the calculation period (min(block.timestamp, lockEndTime))
        // If yield accrues always, set last claim time to block.timestamp
        // Let's assume yield accrues only while LOCKED for this example.
        // calculatePendingYield already uses min(block.timestamp, position.lockEndTime) if locked
        // So we update last claim time to reflect up to when the yield was calculated.
         position.lastYieldClaimTime = block.timestamp < position.lockEndTime && position.lockEndTime > 0 ? block.timestamp : position.lockEndTime; // Update based on current time or lock end time if passed/unlocked


        uint256 amountToClaim = position.claimableYield;

        if (amountToClaim == 0) return; // Nothing to claim

        // Check contract balance
        uint256 contractBalance = yieldToken.balanceOf(address(this));
        if (amountToClaim > contractBalance) {
            // Cannot pay full amount, transfer what's available
            amountToClaim = contractBalance;
             emit YieldTokensDistributed(address(this), 0, block.timestamp); // Signal partial claim due to lack of funds
        }

        position.claimableYield -= amountToClaim; // Reduce claimable by amount transferred

        // Transfer tokens to the position owner
        bool success = yieldToken.transfer(position.owner, amountToClaim);
        if (!success) {
            // If transfer fails, add the amount back to claimable balance
            position.claimableYield += amountToClaim;
            // Consider reverting or logging failure
             revert InsufficientYieldTokens(amountToClaim, contractBalance); // Revert on transfer failure
        }

        emit YieldClaimed(positionId, position.owner, amountToClaim, block.timestamp);
    }


    /**
     * @notice Allows the caller to claim accumulated yield for all their positions.
     */
    function claimAllYield() external {
        uint256[] memory userPositions = _userPositions[msg.sender];
        for (uint i = 0; i < userPositions.length; i++) {
            // Call internal claim for each position
            // Handle potential failures per position gracefully if needed,
            // but _claimYield will revert on transfer failure.
            // A more robust version might track successful claims or use a pull pattern.
            _claimYield(userPositions[i]);
        }
    }

    /**
     * @notice Allows the owner to configure yield multiplier rates for different lock durations.
     * Multiplier is represented as a percentage / 1000 (e.g., 1000 = 1x, 1500 = 1.5x, 2000 = 2x).
     * @param lockDurationInSeconds The lock duration this multiplier applies to.
     * @param multiplier The yield multiplier (e.g., 1000 for 1x).
     */
    function setLockDurationYieldMultiplier(uint256 lockDurationInSeconds, uint256 multiplier) external {
        if (msg.sender != _owner) revert NotOwner();
        // Add validation for lockDurationInSeconds if needed (e.g., must be > 0)

        lockDurationToYieldMultiplier[lockDurationInSeconds] = multiplier;

        emit LockDurationYieldMultiplierSet(lockDurationInSeconds, multiplier);
    }

    /**
     * @notice Allows a position owner to transfer ownership of their vault position (and the underlying NFT within it) to another address.
     * The NFT itself remains in the vault contract until withdrawn by the new position owner.
     * @param positionId The ID of the vault position to transfer.
     * @param newOwner The address of the new owner.
     */
    function transferPositionOwnership(uint256 positionId, address newOwner) external {
        VaultPosition storage position = _getVaultPosition(positionId);

        if (position.owner != msg.sender) revert NotPositionOwner(positionId, msg.sender);
        if (newOwner == address(0)) revert NotOwner(); // Using NotOwner error for zero address

        // Claim any pending yield before transferring ownership
        _claimYield(positionId);

        address oldOwner = position.owner;
        position.owner = newOwner;

        // Update user position lists
        _removePositionFromUserList(oldOwner, positionId);
        _userPositions[newOwner].push(positionId);

        // Clear permissions as they are tied to the old owner's granting
        // Reinitialize the mapping (cannot directly clear) - conceptually permissions are reset.
        // To truly clear, you'd need to iterate or use a different structure.
        // For simplicity, assume permissions are reset conceptually on transfer.

        emit PositionOwnershipTransferred(positionId, oldOwner, newOwner, block.timestamp);
    }

    /**
     * @notice Owner function for emergency withdrawal of an NFT to any address. Use with extreme caution.
     * This bypasses normal withdrawal checks.
     * @param positionId The ID of the vault position.
     * @param recipient The address to send the NFT to.
     */
    function forceWithdrawNFT(uint256 positionId, address recipient) external {
        if (msg.sender != _owner) revert NotOwner();
        if (recipient == address(0)) revert NotOwner(); // Using NotOwner error for zero address

        VaultPosition storage position = _getVaultPosition(positionId);
        // Allow withdrawal even if locked or other status, but not if Empty
        if (position.status == VaultStatus.Empty) revert PositionStatusMismatch(positionId, VaultStatus.Locked, position.status); // Allow from Locked, Unlocked, PendingWithdrawal

        // Note: This does *not* claim pending yield or update position status cleanly.
        // It's purely for emergency recovery of the underlying asset.
        // The position status should be manually handled or considered invalid after this.

         address currentPositionOwner = position.owner; // Store before potentially clearing

        // Transfer the NFT
        IERC721(position.nftContract).safeTransferFrom(address(this), recipient, position.tokenId);

        // Mark the position as Empty and clear details post-emergency withdrawal
        position.status = VaultStatus.Empty;
        position.owner = address(0);
        position.bondedPositions = new uint256[](0); // Clear bonds

        // Attempt to remove from the *last known* owner's list
        _removePositionFromUserList(currentPositionOwner, positionId);


        emit EmergencyWithdrawal(positionId, recipient, position.nftContract, position.tokenId, block.timestamp);
    }


    // --- View Functions ---

    /**
     * @notice View function to retrieve details of a specific vault position.
     * @param positionId The ID of the vault position.
     * @return A tuple containing the position details.
     */
    function getVaultPosition(uint256 positionId)
        public view
        returns (
            VaultStatus status,
            address owner,
            address nftContract,
            uint256 tokenId,
            uint256 lockStartTime,
            uint256 lockEndTime,
            uint256 lastYieldClaimTime,
            uint256 claimableYield,
            string memory dynamicMetadataUri,
            uint256[] memory bondedPositions
        )
    {
        if (positionId == 0 || positionId >= _nextPositionId || _vaultPositions[positionId].status == VaultStatus.Empty) {
             // Return default/empty values or revert. Reverting is clearer for non-existent positions.
             revert PositionNotFound(positionId);
        }
         VaultPosition storage position = _vaultPositions[positionId]; // Use storage for efficiency inside view

        return (
            position.status,
            position.owner,
            position.nftContract,
            position.tokenId,
            position.lockStartTime,
            position.lockEndTime,
            position.lastYieldClaimTime,
            position.claimableYield,
            position.dynamicMetadataUri,
            position.bondedPositions // Return a copy of the array
        );
    }

    /**
     * @notice View function to get all non-empty position IDs owned by a user.
     * @param user The address of the user.
     * @return An array of position IDs.
     */
    function getUserPositions(address user) public view returns (uint256[] memory) {
        if (user == address(0)) return new uint256[](0); // Return empty for zero address
        return _userPositions[user];
    }

    /**
     * @notice View function to check if a position is currently locked.
     * @param positionId The ID of the vault position.
     * @return True if locked, false otherwise.
     */
    function isLocked(uint256 positionId) public view returns (bool) {
         VaultPosition storage position = _getVaultPosition(positionId);
        return position.status == VaultStatus.Locked;
    }

     /**
      * @notice View function to get the current dynamic metadata URI for a position.
      * @param positionId The ID of the vault position.
      * @return The dynamic metadata URI string.
      */
    function getDynamicMetadataUri(uint256 positionId) public view returns (string memory) {
        VaultPosition storage position = _getVaultPosition(positionId);
        return position.dynamicMetadataUri;
    }

     /**
      * @notice View function to get the currently calculated yield multiplier for a position.
      * This function demonstrates a potential dynamic calculation based on position state.
      * Example logic: multiplier based on lock duration or number of bonded NFTs.
      * @param positionId The ID of the vault position.
      * @return The calculated yield multiplier.
      */
    function getCalculatedYieldMultiplier(uint256 positionId) public view returns (uint256) {
        VaultPosition storage position = _getVaultPosition(positionId);

        if (position.status != VaultStatus.Locked && position.lockEndTime == 0) {
            return 0; // No yield multiplier if not locked
        }

        uint256 effectiveMultiplier = 1000; // Base multiplier (1x)

        // Example 1: Multiplier based on *original* lock duration
        uint256 originalLockDuration = position.lockEndTime - position.lockStartTime; // Note: This is simplified, doesn't track extensions history
        uint256 configMultiplier = lockDurationToYieldMultiplier[originalLockDuration];
        if (configMultiplier > 0) {
            effectiveMultiplier = configMultiplier;
        }

        // Example 2: Bonus multiplier based on number of bonded positions
        // Let's say each bonded position adds +100 to the multiplier (0.1x)
        effectiveMultiplier += position.bondedPositions.length * 100;

        // Ensure a minimum multiplier (e.g., 1x) unless explicitly configured lower for a duration
        // effectiveMultiplier = effectiveMultiplier > 1000 ? effectiveMultiplier : 1000; // Or allow configured value

        return effectiveMultiplier;
    }


    /**
     * @notice View function to calculate the yield accrued for a position since the last claim or lock start.
     * Yield accrues based on time spent LOCKED and the effective multiplier.
     * @param positionId The ID of the vault position.
     * @return The amount of yield tokens pending claim for this position.
     */
    function calculatePendingYield(uint256 positionId) public view returns (uint256) {
        VaultPosition storage position = _getVaultPosition(positionId);

        // Yield only accrues while in the LOCKED state and within the lock period
        if (position.status != VaultStatus.Locked && position.lockEndTime == 0) {
             return 0;
        }

        uint256 yieldCalculationEndTime;
        // If currently locked, calculate up to block.timestamp, but not past lockEndTime
        if (position.status == VaultStatus.Locked) {
             yieldCalculationEndTime = block.timestamp < position.lockEndTime ? block.timestamp : position.lockEndTime;
        } else {
            // If unlocked but had a lockEndTime, calculate up to lockEndTime (if not already claimed past that point)
            yieldCalculationEndTime = position.lockEndTime;
        }


        uint256 startTime = position.lastYieldClaimTime > position.lockStartTime ? position.lastYieldClaimTime : position.lockStartTime;

        // Prevent calculation backwards in time
        if (yieldCalculationEndTime <= startTime) {
             return 0;
        }

        uint256 duration = yieldCalculationEndTime - startTime;

        // Yield is calculated based on the *effective* multiplier over time
        // Simplified: Yield per second = BaseRate * EffectiveMultiplier / 1000
        // Let's assume a base rate, e.g., 10**yieldToken.decimals per second * 1 / 1000 (for 1x multiplier)
        // A real yield system would be more complex (e.g., yield per block, APY conversion).
        // For this example, let's use a hypothetical base rate relative to the multiplier.
        // Let's assume 1 unit of yield per second at 1x multiplier (multiplier 1000).
        // Base rate per second (scaled) = 1e18 / 1000; adjust for actual token decimals
        uint256 baseRateScaled = (1 ether / 1000); // Hypothetical base rate (1e18 / 1000 multiplier unit)

        // Adjust base rate for target token decimals
        // Get decimals (requires IERC20Metadata or manual tracking) - assume 18 for simplicity here, or require it.
        // If decimals are not 18, need adjustment: (1e18 / 1000) * (10**yieldToken.decimals / 1e18) = 10**(yieldToken.decimals) / 1000
        // Assuming yieldToken has 18 decimals for simplicity:
        baseRateScaled = 1e18 / 1000; // Base rate is 1 yield token per 1000 multiplier units per second

        uint256 effectiveMultiplier = getCalculatedYieldMultiplier(positionId); // Get the dynamic multiplier

        // Total yield = duration * baseRateScaled * effectiveMultiplier / 1e18 (to unscale base rate)
        // Simplified calculation assuming effectiveMultiplier is >= 1000 (1x)
        uint256 pending = (duration * baseRateScaled * effectiveMultiplier) / (1e18);


        // Add previously accumulated but un-claimed yield
        return pending + position.claimableYield; // Return total claimable (pending + previously unclaimed)
    }

    /**
     * @notice View function to get the total claimable yield across all positions owned by a user.
     * @param user The address of the user.
     * @return The total amount of yield tokens pending claim for the user.
     */
    function getTotalClaimableYield(address user) public view returns (uint256) {
        if (user == address(0)) return 0;

        uint256 totalClaimable = 0;
        uint256[] memory userPositions = _userPositions[user];
        for (uint i = 0; i < userPositions.length; i++) {
            totalClaimable += calculatePendingYield(userPositions[i]); // Sum up pending yield for each position
        }
        return totalClaimable;
    }

     /**
      * @notice View function to get the list of position IDs bonded to a given position.
      * @param positionId The ID of the vault position.
      * @return An array of position IDs bonded to the given position.
      */
    function getBondedPositions(uint256 positionId) public view returns (uint256[] memory) {
        VaultPosition storage position = _getVaultPosition(positionId);
        return position.bondedPositions; // Return a copy of the array
    }

     /**
      * @notice View function to check if a user has permission on a position.
      * @param positionId The ID of the vault position.
      * @param user The address to check permissions for.
      * @return True if the user has permission, false otherwise.
      */
    function isPermittedUser(uint256 positionId, address user) public view returns (bool) {
        VaultPosition storage position = _getVaultPosition(positionId);
        return position.permittedUsers[user];
    }

    /**
     * @notice View function to get the status of a specific vault position.
     * @param positionId The ID of the vault position.
     * @return The VaultStatus enum value.
     */
    function getPositionStatus(uint256 positionId) public view returns (VaultStatus) {
         if (positionId == 0 || positionId >= _nextPositionId) {
             revert PositionNotFound(positionId);
         }
        return _vaultPositions[positionId].status;
    }


    // --- Owner Functions ---

    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) external {
        if (msg.sender != _owner) revert NotOwner();
        if (newOwner == address(0)) revert NotOwner();
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function renounceOwnership() external {
        if (msg.sender != _owner) revert NotOwner();
        address oldOwner = _owner;
        _owner = address(0);
        emit OwnershipTransferred(oldOwner, address(0));
    }


    // --- Internal Helper Functions ---

    /**
     * @dev Internal function to retrieve a position, checking for validity.
     * @param positionId The ID of the vault position.
     * @return The storage reference to the VaultPosition struct.
     */
    function _getVaultPosition(uint256 positionId) internal view returns (VaultPosition storage) {
        if (positionId == 0 || positionId >= _nextPositionId || _vaultPositions[positionId].status == VaultStatus.Empty) {
             revert PositionNotFound(positionId);
        }
        return _vaultPositions[positionId];
    }

    /**
     * @dev Internal function to remove a positionId from a user's list.
     * Note: This is a simple implementation (loop and swap-and-pop) which is O(n).
     * For a contract expecting millions of positions per user, a different structure might be needed.
     * @param user The address of the user.
     * @param positionId The ID of the position to remove.
     */
    function _removePositionFromUserList(address user, uint256 positionId) internal {
        uint256[] storage userPositions = _userPositions[user];
        for (uint i = 0; i < userPositions.length; i++) {
            if (userPositions[i] == positionId) {
                userPositions[i] = userPositions[userPositions.length - 1];
                userPositions.pop();
                break; // Assume positionId is unique per user list
            }
        }
    }

    // Fallback and Receive functions to accept potential ether (optional, remove if not needed)
    // receive() external payable {}
    // fallback() external payable {}
}
```