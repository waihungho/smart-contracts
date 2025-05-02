Okay, let's design a complex, interesting, and advanced smart contract that isn't a direct copy of common patterns.

We'll create a **Time-Locked Escrow for Non-Fungible Tokens (NFTs) with a Resolver Role**.

This contract allows an NFT owner (Depositor) to lock an NFT, specifying a Recipient who will receive it after a set time or upon certain conditions. A third party (Resolver) has specific powers to intervene, which adds a layer of complexity for dispute resolution or emergency scenarios. It supports different types of time locks (simple and with a cliff).

**Advanced Concepts Used:**

1.  **NFT Escrow/Custody:** Contract holding valuable NFTs.
2.  **Time-Based Vesting/Release:** Using timestamps (`block.timestamp`) for conditional logic (start, cliff, end times).
3.  **Multi-Party Interaction:** Involves Depositor, Recipient, and Resolver with distinct roles and permissions.
4.  **State Machine:** Tracking the lifecycle of each lock (Active, Vesting, Releasable, Claimed, Cancelled, ResolverReturned).
5.  **Unique Lock Identifiers:** Using `keccak256` to generate unique IDs for each lock configuration.
6.  **Role-Based Access Control:** Custom modifiers for Depositor, Recipient, Resolver, and Owner.
7.  **Safe ERC721 Handling:** Using `safeTransferFrom` for secure token transfers.
8.  **Metadata/Description:** Allowing a string description for each lock.

---

## Contract: `TimeLockEscrowNFT`

**Outline:**

1.  **Pragmas & Imports:** Solidity version, ERC721 interface.
2.  **Errors:** Custom errors for clarity (or use require strings).
3.  **State Variables:**
    *   Owner address.
    *   Resolver address.
    *   Enum for Lock State.
    *   Struct for Lock Data (Depositor, Recipient, NFT details, Timings, State, Description).
    *   Mapping from unique Lock ID (`bytes32`) to `LockData`.
    *   Mapping from NFT (`contract`, `tokenId`) to active `lockId` to prevent double-locking.
    *   Counters for active locks per depositor/recipient (basic tracking).
    *   Mapping to store generated lock IDs for a depositor (simple tracking, not exhaustive).
4.  **Events:** For tracking state changes and actions.
5.  **Modifiers:** `onlyOwner`, `onlyDepositor`, `onlyRecipient`, `onlyResolver`, `onlyActiveOrVestingLock`, etc.
6.  **Constructor:** Sets initial owner.
7.  **Admin Functions:** Set Resolver, Transfer Ownership, Renounce Ownership.
8.  **Lock Creation Functions:**
    *   `createSimpleTimeLock`: Lock with a start and end time.
    *   `createCliffTimeLock`: Lock with a start, cliff, and end time.
    *   Internal helper for ID generation.
9.  **View Functions (Get Info):**
    *   Get Lock Data, State, Timings.
    *   Check if NFT is locked, get lock ID for NFT.
    *   Check vesting status (started, cliff passed, complete, releasable).
    *   Get active lock counts.
    *   Preview potential lock ID.
    *   Check if a lock ID is valid.
    *   Get string representation of lock state.
10. **Action Functions (Modify Lock State):**
    *   `cancelLock`: Depositor cancels before start.
    *   `claimNFT`: Recipient claims after vesting/cliff.
    *   `earlyReleaseByDepositor`: Depositor releases early.
    *   `returnNFTByResolver`: Resolver returns NFT to depositor.
    *   `updateLockDescription`: Depositor updates description.

**Function Summary (Counting towards the 20+ requirement):**

1.  `constructor()`: Initializes contract owner.
2.  `setResolver(address _resolver)`: Sets the address of the Resolver. (`onlyOwner`)
3.  `getResolver()`: Returns the current Resolver address. (View)
4.  `transferOwnership(address newOwner)`: Transfers contract ownership. (`onlyOwner`)
5.  `renounceOwnership()`: Renounces contract ownership. (`onlyOwner`)
6.  `createSimpleTimeLock(address _recipient, address _nftContract, uint256 _tokenId, uint48 _duration, string calldata _description)`: Creates a new lock for an NFT with a simple vesting duration. Requires NFT approval beforehand.
7.  `createCliffTimeLock(address _recipient, address _nftContract, uint256 _tokenId, uint48 _duration, uint48 _cliffDuration, string calldata _description)`: Creates a new lock for an NFT with a cliff period before vesting starts/becomes claimable. Requires NFT approval beforehand.
8.  `_generateLockId(address _depositor, address _nftContract, uint256 _tokenId, uint256 _timestamp)`: Internal helper to generate a unique ID for a lock.
9.  `getLockData(bytes32 _lockId)`: Retrieves all stored data for a given lock ID. (View)
10. `getLockState(bytes32 _lockId)`: Returns the current state of a specific lock. (View)
11. `getLockIdForNFT(address _nftContract, uint256 _tokenId)`: Returns the active lock ID associated with a specific NFT, if any. (View)
12. `isNFTLocked(address _nftContract, uint256 _tokenId)`: Checks if a specific NFT is currently under an active lock in this contract. (View)
13. `isVestingStarted(bytes32 _lockId)`: Checks if the start time for the lock has passed. (View)
14. `isCliffPassed(bytes32 _lockId)`: Checks if the cliff time (if applicable) for the lock has passed. (View)
15. `isVestingComplete(bytes32 _lockId)`: Checks if the end time for the lock has passed. (View)
16. `isReleasable(bytes32 _lockId)`: Checks if the NFT is currently claimable by the Recipient based on state and time. (View)
17. `getActiveDepositorLockCount(address _depositor)`: Returns the count of active locks created by a specific depositor. (View)
18. `getActiveRecipientLockCount(address _recipient)`: Returns the count of active locks destined for a specific recipient. (View)
19. `cancelLock(bytes32 _lockId)`: Allows the Depositor to cancel the lock and retrieve the NFT, only if vesting hasn't started. (`onlyDepositor`, state checks)
20. `claimNFT(bytes32 _lockId)`: Allows the Recipient to claim the NFT once it is releasable (state and time checks). (`onlyRecipient`, state checks)
21. `earlyReleaseByDepositor(bytes32 _lockId)`: Allows the Depositor to transfer the NFT to the Recipient immediately, bypassing time locks. (`onlyDepositor`, state checks)
22. `returnNFTByResolver(bytes32 _lockId)`: Allows the Resolver to return the NFT to the Depositor, overriding the time lock. (`onlyResolver`, state checks)
23. `updateLockDescription(bytes32 _lockId, string calldata _newDescription)`: Allows the Depositor to update the description of an active or vesting lock. (`onlyDepositor`, state checks)
24. `getVersion()`: Returns the contract version (simple identifier). (View)
25. `isValidLock(bytes32 _lockId)`: Checks if a lock with the given ID exists. (View)
26. `getLockTimings(bytes32 _lockId)`: Returns the start, end, and cliff times for a lock. (View)
27. `getTimeRemaining(bytes32 _lockId)`: Calculates the time remaining until the end time for a lock. (View)
28. `getStateDescription(LockState _state)`: Returns a string description for a given LockState enum value. (Pure)

This provides 28 functions, meeting the requirement of at least 20 and incorporating the specified concepts.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol"; // Included for potential future use or demonstration, though not strictly used in time-locking logic below. Can be removed if not needed.
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Less crucial in 0.8+ but good practice for arithmetic

/**
 * @title TimeLockEscrowNFT
 * @dev An advanced smart contract for time-locking and escrowing ERC721 tokens
 *      with multi-party roles (Depositor, Recipient, Resolver).
 *      Allows locking an NFT such that it can only be claimed by a recipient
 *      after a specified time duration, potentially with a cliff period.
 *      A designated Resolver can intervene to return the NFT to the depositor.
 *      Includes various state tracking and access control functions.
 *
 * Outline:
 * 1. Pragmas & Imports (Solidity version, ERC721, Ownable, SafeMath)
 * 2. Errors (Custom errors or require strings)
 * 3. State Variables (Owner, Resolver, LockState enum, LockData struct, Mappings for locks and NFT tracking, Counters)
 * 4. Events (LockCreated, LockStateChanged, NFTClaimed, LockCancelled, NFTReturnedByResolver, DescriptionUpdated)
 * 5. Modifiers (onlyOwner, onlyDepositor, onlyRecipient, onlyResolver, onlyActiveOrVestingLock, etc.)
 * 6. Constructor (Sets initial owner)
 * 7. Admin Functions (setResolver, transferOwnership, renounceOwnership, getResolver, getVersion)
 * 8. Lock Creation Functions (createSimpleTimeLock, createCliffTimeLock, _generateLockId)
 * 9. View Functions (Get Info): getLockData, getLockState, getLockIdForNFT, isNFTLocked, isVestingStarted, isCliffPassed, isVestingComplete, isReleasable, getActiveDepositorLockCount, getActiveRecipientLockCount, isValidLock, getLockTimings, getTimeRemaining, getStateDescription
 * 10. Action Functions (Modify Lock State): cancelLock, claimNFT, earlyReleaseByDepositor, returnNFTByResolver, updateLockDescription
 *
 * Function Summary:
 * 1. constructor(): Initializes contract owner.
 * 2. setResolver(address _resolver): Sets the address of the Resolver (onlyOwner).
 * 3. getResolver(): Returns the current Resolver address (View).
 * 4. transferOwnership(address newOwner): Transfers contract ownership (onlyOwner).
 * 5. renounceOwnership(): Renounces contract ownership (onlyOwner).
 * 6. createSimpleTimeLock(address _recipient, address _nftContract, uint256 _tokenId, uint48 _duration, string calldata _description): Creates a new lock for an NFT with a simple vesting duration. Requires NFT approval beforehand.
 * 7. createCliffTimeLock(address _recipient, address _nftContract, uint256 _tokenId, uint48 _duration, uint48 _cliffDuration, string calldata _description): Creates a new lock for an NFT with a cliff period before vesting starts/becomes claimable. Requires NFT approval beforehand.
 * 8. _generateLockId(address _depositor, address _nftContract, uint256 _tokenId, uint256 _timestamp): Internal helper to generate a unique ID for a lock.
 * 9. getLockData(bytes32 _lockId): Retrieves all stored data for a given lock ID (View).
 * 10. getLockState(bytes32 _lockId): Returns the current state of a specific lock (View).
 * 11. getLockIdForNFT(address _nftContract, uint256 _tokenId): Returns the active lock ID associated with a specific NFT, if any (View).
 * 12. isNFTLocked(address _nftContract, uint256 _tokenId): Checks if a specific NFT is currently under an active lock in this contract (View).
 * 13. isVestingStarted(bytes32 _lockId): Checks if the start time for the lock has passed (View).
 * 14. isCliffPassed(bytes32 _lockId): Checks if the cliff time (if applicable) for the lock has passed (View).
 * 15. isVestingComplete(bytes32 _lockId): Checks if the end time for the lock has passed (View).
 * 16. isReleasable(bytes32 _lockId): Checks if the NFT is currently claimable by the Recipient based on state and time (View).
 * 17. getActiveDepositorLockCount(address _depositor): Returns the count of active locks created by a specific depositor (View).
 * 18. getActiveRecipientLockCount(address _recipient): Returns the count of active locks destined for a specific recipient (View).
 * 19. cancelLock(bytes32 _lockId): Allows the Depositor to cancel the lock and retrieve the NFT, only if vesting hasn't started (onlyDepositor, state checks).
 * 20. claimNFT(bytes32 _lockId): Allows the Recipient to claim the NFT once it is releasable (state and time checks) (onlyRecipient, state checks).
 * 21. earlyReleaseByDepositor(bytes32 _lockId): Allows the Depositor to transfer the NFT to the Recipient immediately, bypassing time locks (onlyDepositor, state checks).
 * 22. returnNFTByResolver(bytes32 _lockId): Allows the Resolver to return the NFT to the Depositor, overriding the time lock (onlyResolver, state checks).
 * 23. updateLockDescription(bytes32 _lockId, string calldata _newDescription): Allows the Depositor to update the description of an active or vesting lock (onlyDepositor, state checks).
 * 24. getVersion(): Returns the contract version (simple identifier) (View).
 * 25. isValidLock(bytes32 _lockId): Checks if a lock with the given ID exists (View).
 * 26. getLockTimings(bytes32 _lockId): Returns the start, end, and cliff times for a lock (View).
 * 27. getTimeRemaining(bytes32 _lockId): Calculates the time remaining until the end time for a lock (View).
 * 28. getStateDescription(LockState _state): Returns a string description for a given LockState enum value (Pure).
 *
 * Note: ERC721Holder is imported but not inherited to avoid unnecessary complexity.
 * The contract handles receiving and sending NFTs explicitly using transferFrom/safeTransferFrom.
 */
contract TimeLockEscrowNFT is Ownable {
    using SafeMath for uint256; // Use SafeMath explicitly though 0.8+ handles overflow mostly

    /// @dev Represents the different states a lock can be in.
    enum LockState {
        Active,          // Lock created, waiting for start time
        Vesting,         // Start time reached, lock duration running
        Releasable,      // End time (and cliff) reached, ready to be claimed
        Claimed,         // NFT has been claimed by the recipient
        Cancelled,       // Lock cancelled by depositor before vesting started
        ResolverReturned // NFT returned to depositor by the resolver
    }

    /// @dev Struct to hold data for each NFT lock.
    struct LockData {
        bytes32 lockId;       // Unique identifier for the lock
        address depositor;    // The original owner who deposited the NFT
        address recipient;    // The intended recipient of the NFT
        address nftContract;  // Address of the ERC721 token contract
        uint256 tokenId;      // ID of the NFT token
        uint48 startTime;     // Timestamp when vesting/lock officially starts
        uint48 endTime;       // Timestamp when vesting/lock completes (can be claimed)
        uint48 cliffTime;     // Timestamp for the end of the cliff period (0 if no cliff)
        bool isCliffUsed;     // Flag indicating if a cliff is used for this lock
        LockState state;      // Current state of the lock
        string description;   // Optional description or notes about the lock
    }

    // --- State Variables ---
    address private _resolver; // Address of the designated resolver

    // Mapping from unique lock ID to its data
    mapping(bytes32 => LockData) public locks;

    // Mapping from NFT (contract, tokenId) to the active lock ID.
    // Prevents locking the same NFT under multiple configurations concurrently.
    mapping(address => mapping(uint256 => bytes32)) private nftToLockId;

    // Basic counters for active locks (simplistic, relies on state changes)
    mapping(address => uint256) private activeDepositorLockCount;
    mapping(address => uint256) private activeRecipientLockCount;

    // Mapping to track existence of a lock ID. More robust than checking struct default values.
    mapping(bytes32 => bool) private lockIdExists;

    // --- Events ---
    event LockCreated(bytes32 indexed lockId, address indexed depositor, address indexed recipient, address nftContract, uint256 tokenId, uint48 startTime, uint48 endTime, uint48 cliffTime, bool isCliffUsed, string description);
    event LockStateChanged(bytes32 indexed lockId, LockState oldState, LockState newState, uint256 timestamp);
    event NFTClaimed(bytes32 indexed lockId, address indexed recipient, address nftContract, uint256 tokenId);
    event LockCancelled(bytes32 indexed lockId, address indexed depositor, address nftContract, uint256 tokenId);
    event NFTReturnedByResolver(bytes32 indexed lockId, address indexed depositor, address indexed resolver, address nftContract, uint256 tokenId);
    event DescriptionUpdated(bytes32 indexed lockId, string newDescription);
    event ResolverUpdated(address indexed oldResolver, address indexed newResolver);

    // --- Modifiers ---
    modifier onlyResolver() {
        require(msg.sender == _resolver, "Not the resolver");
        _;
    }

    modifier onlyDepositor(bytes32 _lockId) {
        require(locks[_lockId].depositor == msg.sender, "Not the depositor");
        _;
    }

    modifier onlyRecipient(bytes32 _lockId) {
        require(locks[_lockId].recipient == msg.sender, "Not the recipient");
        _;
    }

    modifier onlyLockExists(bytes32 _lockId) {
        require(lockIdExists[_lockId], "Lock does not exist");
        _;
    }

    modifier onlyActiveOrVestingLock(bytes32 _lockId) {
        require(
            locks[_lockId].state == LockState.Active || locks[_lockId].state == LockState.Vesting,
            "Lock is not active or vesting"
        );
        _;
    }

    modifier onlyReleasableLock(bytes32 _lockId) {
        require(locks[_lockId].state == LockState.Releasable, "Lock is not releasable");
        _;
    }

    modifier onlyBeforeVestingStart(bytes32 _lockId) {
         require(
             locks[_lockId].state == LockState.Active && block.timestamp < locks[_lockId].startTime,
             "Vesting has already started"
         );
         _;
    }

    modifier onlyNotFinalState(bytes32 _lockId) {
         require(
             locks[_lockId].state != LockState.Claimed &&
             locks[_lockId].state != LockState.Cancelled &&
             locks[_lockId].state != LockState.ResolverReturned,
             "Lock is in a final state"
         );
         _;
    }


    // --- Constructor ---
    constructor() Ownable(msg.sender) {}

    // --- Admin Functions ---

    /**
     * @dev Sets the address of the contract resolver.
     * The resolver has special permissions to intervene in locks.
     * Only the contract owner can set the resolver.
     * @param _resolver The address to set as the resolver.
     */
    function setResolver(address _resolver) external onlyOwner {
        require(_resolver != address(0), "Resolver cannot be zero address");
        emit ResolverUpdated(this._resolver, _resolver);
        this._resolver = _resolver;
    }

    /**
     * @dev Returns the current resolver address.
     */
    function getResolver() external view returns (address) {
        return _resolver;
    }

    // Note: Ownable provides transferOwnership and renounceOwnership

    /**
     * @dev Returns the current version of the contract.
     */
    function getVersion() external pure returns (string memory) {
        return "1.0.0";
    }

    // --- Lock Creation Functions ---

    /**
     * @dev Creates a new simple time lock for an NFT.
     * The NFT must be approved to this contract BEFORE calling this function.
     * The contract will pull the NFT using transferFrom.
     * @param _recipient The address that will receive the NFT after the lock duration.
     * @param _nftContract The address of the ERC721 NFT contract.
     * @param _tokenId The ID of the NFT to lock.
     * @param _duration The duration of the lock in seconds, starting immediately.
     * @param _description Optional description for the lock.
     */
    function createSimpleTimeLock(
        address _recipient,
        address _nftContract,
        uint256 _tokenId,
        uint48 _duration,
        string calldata _description
    ) external {
        require(_recipient != address(0), "Recipient cannot be zero address");
        require(_nftContract != address(0), "NFT contract cannot be zero address");
        require(_duration > 0, "Duration must be greater than 0");
        require(!isNFTLocked(_nftContract, _tokenId), "NFT is already locked");

        // Check if this contract is approved to transfer the NFT
        IERC721 nft = IERC721(_nftContract);
        require(nft.getApproved(_tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)), "Contract not approved to transfer NFT");
        require(nft.ownerOf(_tokenId) == msg.sender, "Sender must own the NFT");

        uint48 currentTimestamp = uint48(block.timestamp);
        bytes32 lockId = _generateLockId(msg.sender, _nftContract, _tokenId, currentTimestamp);

        // Ensure lockId is unique (highly probable with timestamp, but double check)
        require(!lockIdExists[lockId], "Lock ID collision");

        LockData storage newLock = locks[lockId];
        newLock.lockId = lockId;
        newLock.depositor = msg.sender;
        newLock.recipient = _recipient;
        newLock.nftContract = _nftContract;
        newLock.tokenId = _tokenId;
        newLock.startTime = currentTimestamp;
        newLock.endTime = currentTimestamp.add(_duration); // SafeMath add
        newLock.cliffTime = 0; // No cliff
        newLock.isCliffUsed = false;
        newLock.state = LockState.Active; // Start as Active, becomes Vesting immediately if time=0 or passes

        // Check state based on time
        if (currentTimestamp >= newLock.startTime) {
             newLock.state = LockState.Vesting;
             if (currentTimestamp >= newLock.endTime) {
                 newLock.state = LockState.Releasable;
             }
        }

        newLock.description = _description;

        nftToLockId[_nftContract][_tokenId] = lockId;
        lockIdExists[lockId] = true;

        activeDepositorLockCount[msg.sender]++;
        activeRecipientLockCount[_recipient]++;

        // Pull the NFT into the contract
        IERC721(newLock.nftContract).transferFrom(msg.sender, address(this), newLock.tokenId);

        emit LockCreated(
            lockId,
            msg.sender,
            _recipient,
            _nftContract,
            _tokenId,
            newLock.startTime,
            newLock.endTime,
            newLock.cliffTime,
            newLock.isCliffUsed,
            _description
        );
         // Emit state change if it moved past Active immediately
        if (newLock.state != LockState.Active) {
            emit LockStateChanged(lockId, LockState.Active, newLock.state, currentTimestamp);
        }
    }

    /**
     * @dev Creates a new time lock for an NFT with a cliff period.
     * The NFT must be approved to this contract BEFORE calling this function.
     * The contract will pull the NFT using transferFrom.
     * Recipient can only claim AFTER both cliffTime and endTime have passed.
     * @param _recipient The address that will receive the NFT.
     * @param _nftContract The address of the ERC721 NFT contract.
     * @param _tokenId The ID of the NFT to lock.
     * @param _duration The total duration of the lock in seconds, starting immediately.
     * @param _cliffDuration The duration of the cliff period in seconds, from the start time. Must be <= _duration.
     * @param _description Optional description for the lock.
     */
    function createCliffTimeLock(
        address _recipient,
        address _nftContract,
        uint256 _tokenId,
        uint48 _duration,
        uint48 _cliffDuration,
        string calldata _description
    ) external {
        require(_recipient != address(0), "Recipient cannot be zero address");
        require(_nftContract != address(0), "NFT contract cannot be zero address");
        require(_duration > 0, "Duration must be greater than 0");
        require(_cliffDuration <= _duration, "Cliff duration cannot exceed total duration");
        require(!isNFTLocked(_nftContract, _tokenId), "NFT is already locked");

        // Check if this contract is approved to transfer the NFT
        IERC721 nft = IERC721(_nftContract);
        require(nft.getApproved(_tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)), "Contract not approved to transfer NFT");
        require(nft.ownerOf(_tokenId) == msg.sender, "Sender must own the NFT");

        uint48 currentTimestamp = uint48(block.timestamp);
        bytes32 lockId = _generateLockId(msg.sender, _nftContract, _tokenId, currentTimestamp);

        // Ensure lockId is unique
        require(!lockIdExists[lockId], "Lock ID collision");


        LockData storage newLock = locks[lockId];
        newLock.lockId = lockId;
        newLock.depositor = msg.sender;
        newLock.recipient = _recipient;
        newLock.nftContract = _nftContract;
        newLock.tokenId = _tokenId;
        newLock.startTime = currentTimestamp;
        newLock.endTime = currentTimestamp.add(_duration); // SafeMath add
        newLock.cliffTime = currentTimestamp.add(_cliffDuration); // SafeMath add
        newLock.isCliffUsed = true;
        newLock.state = LockState.Active; // Start as Active, becomes Vesting immediately if time=0 or passes

         // Check state based on time
        if (currentTimestamp >= newLock.startTime) {
             newLock.state = LockState.Vesting;
             // Does not immediately become Releasable even if endTime/cliffTime passed at creation,
             // state transitions happen via check/claim functions.
        }

        newLock.description = _description;

        nftToLockId[_nftContract][_tokenId] = lockId;
        lockIdExists[lockId] = true;

        activeDepositorLockCount[msg.sender]++;
        activeRecipientLockCount[_recipient]++;

        // Pull the NFT into the contract
        IERC721(newLock.nftContract).transferFrom(msg.sender, address(this), newLock.tokenId);

        emit LockCreated(
            lockId,
            msg.sender,
            _recipient,
            _nftContract,
            _tokenId,
            newLock.startTime,
            newLock.endTime,
            newLock.cliffTime,
            newLock.isCliffUsed,
            _description
        );
        // Emit state change if it moved past Active immediately
        if (newLock.state != LockState.Active) {
            emit LockStateChanged(lockId, LockState.Active, newLock.state, currentTimestamp);
        }
    }

    /**
     * @dev Internal helper function to generate a unique lock ID.
     * Generated by hashing a combination of depositor, nft, tokenId, and timestamp.
     * This makes each ID highly unique.
     * @param _depositor The address of the depositor.
     * @param _nftContract The address of the NFT contract.
     * @param _tokenId The ID of the NFT.
     * @param _timestamp The timestamp of creation (or a unique nonce).
     * @return A unique bytes32 lock ID.
     */
    function _generateLockId(
        address _depositor,
        address _nftContract,
        uint256 _tokenId,
        uint256 _timestamp
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_depositor, _nftContract, _tokenId, _timestamp, block.number, block.difficulty)); // Added block.number/difficulty for extra entropy
    }

    // --- View Functions (Get Info) ---

    /**
     * @dev Retrieves all stored data for a given lock ID.
     * @param _lockId The unique identifier of the lock.
     * @return A tuple containing all LockData fields.
     */
    function getLockData(bytes32 _lockId) external view onlyLockExists(_lockId) returns (LockData memory) {
        return locks[_lockId];
    }

    /**
     * @dev Returns the current state of a specific lock.
     * Automatically updates the state based on current time if it's Active or Vesting.
     * @param _lockId The unique identifier of the lock.
     * @return The current LockState.
     */
    function getLockState(bytes32 _lockId) external view onlyLockExists(_lockId) returns (LockState) {
        LockData storage lock = locks[_lockId];
        // Update state based on time if it's still in a time-dependent state
        if (lock.state == LockState.Active && block.timestamp >= lock.startTime) {
             return LockState.Vesting;
        }
        if (lock.state == LockState.Vesting) {
            bool timePassed = block.timestamp >= lock.endTime;
            bool cliffPassed = lock.isCliffUsed ? block.timestamp >= lock.cliffTime : true;
            if (timePassed && cliffPassed) {
                return LockState.Releasable;
            }
        }
        return lock.state; // Return current state if not time-dependent or time hasn't passed yet
    }


    /**
     * @dev Returns the active lock ID associated with a specific NFT.
     * Returns bytes32(0) if the NFT is not currently locked in this contract.
     * @param _nftContract The address of the ERC721 NFT contract.
     * @param _tokenId The ID of the NFT.
     * @return The bytes32 lock ID or bytes32(0).
     */
    function getLockIdForNFT(address _nftContract, uint256 _tokenId) external view returns (bytes32) {
        return nftToLockId[_nftContract][_tokenId];
    }

    /**
     * @dev Checks if a specific NFT is currently under an active lock in this contract.
     * @param _nftContract The address of the ERC721 NFT contract.
     * @param _tokenId The ID of the NFT.
     * @return True if locked, false otherwise.
     */
    function isNFTLocked(address _nftContract, uint256 _tokenId) public view returns (bool) {
        bytes32 lockId = nftToLockId[_nftContract][_tokenId];
        // Check if lockId exists and is in a non-final state (Active, Vesting, Releasable)
        if (lockIdExists[lockId]) {
            LockState currentState = getLockState(lockId); // Use the state check function that accounts for time
            return currentState == LockState.Active || currentState == LockState.Vesting || currentState == LockState.Releasable;
        }
        return false;
    }

    /**
     * @dev Checks if the start time for a lock has passed.
     * @param _lockId The unique identifier of the lock.
     * @return True if the start time is in the past, false otherwise.
     */
    function isVestingStarted(bytes32 _lockId) external view onlyLockExists(_lockId) returns (bool) {
        return block.timestamp >= locks[_lockId].startTime;
    }

    /**
     * @dev Checks if the cliff time for a lock has passed.
     * Returns true if no cliff is used.
     * @param _lockId The unique identifier of the lock.
     * @return True if the cliff time is in the past or no cliff, false otherwise.
     */
    function isCliffPassed(bytes32 _lockId) external view onlyLockExists(_lockId) returns (bool) {
        LockData storage lock = locks[_lockId];
        return !lock.isCliffUsed || block.timestamp >= lock.cliffTime;
    }

    /**
     * @dev Checks if the end time for a lock has passed.
     * @param _lockId The unique identifier of the lock.
     * @return True if the end time is in the past, false otherwise.
     */
    function isVestingComplete(bytes32 _lockId) external view onlyLockExists(_lockId) returns (bool) {
        return block.timestamp >= locks[_lockId].endTime;
    }

     /**
     * @dev Checks if the NFT is currently claimable by the Recipient based on state and time.
     * Returns true if state is Releasable OR if state is Active/Vesting and time conditions are met.
     * @param _lockId The unique identifier of the lock.
     * @return True if claimable, false otherwise.
     */
    function isReleasable(bytes32 _lockId) public view onlyLockExists(_lockId) returns (bool) {
        LockState currentState = getLockState(_lockId);
        if (currentState == LockState.Releasable) {
            return true;
        }
        // Also allow checking if it *would* be releasable based on time, even if state hasn't been updated by a call yet
        if (currentState == LockState.Active || currentState == LockState.Vesting) {
            LockData storage lock = locks[_lockId];
            bool timePassed = block.timestamp >= lock.endTime;
            bool cliffPassed = lock.isCliffUsed ? block.timestamp >= lock.cliffTime : true;
            return timePassed && cliffPassed;
        }
        return false;
    }


    /**
     * @dev Returns the count of active locks created by a specific depositor.
     * Note: This count is updated on lock creation and transition to final states.
     * @param _depositor The address of the depositor.
     * @return The number of active locks.
     */
    function getActiveDepositorLockCount(address _depositor) external view returns (uint256) {
        return activeDepositorLockCount[_depositor];
    }

    /**
     * @dev Returns the count of active locks destined for a specific recipient.
     * Note: This count is updated on lock creation and transition to final states.
     * @param _recipient The address of the recipient.
     * @return The number of active locks.
     */
    function getActiveRecipientLockCount(address _recipient) external view returns (uint256) {
        return activeRecipientLockCount[_recipient];
    }

    /**
     * @dev Checks if a lock with the given ID exists in the storage.
     * @param _lockId The unique identifier of the lock.
     * @return True if the lock ID corresponds to an existing lock, false otherwise.
     */
    function isValidLock(bytes32 _lockId) external view returns (bool) {
        return lockIdExists[_lockId];
    }

    /**
     * @dev Returns the start, end, and cliff times for a specific lock.
     * @param _lockId The unique identifier of the lock.
     * @return startTime, endTime, cliffTime.
     */
    function getLockTimings(bytes32 _lockId) external view onlyLockExists(_lockId) returns (uint48 startTime, uint48 endTime, uint48 cliffTime) {
        LockData storage lock = locks[_lockId];
        return (lock.startTime, lock.endTime, lock.cliffTime);
    }

     /**
     * @dev Calculates the time remaining until the end time for a lock.
     * Returns 0 if the end time has already passed or lock is not in a time-dependent state.
     * @param _lockId The unique identifier of the lock.
     * @return Time remaining in seconds.
     */
    function getTimeRemaining(bytes32 _lockId) external view onlyLockExists(_lockId) returns (uint256) {
        LockData storage lock = locks[_lockId];
         // Only calculate for states where time is relevant and end time hasn't passed
        if (lock.state == LockState.Active || lock.state == LockState.Vesting) {
            uint256 currentTime = block.timestamp;
            if (currentTime < lock.endTime) {
                return lock.endTime - currentTime;
            }
        }
        return 0; // Time has passed or state is not time-dependent
    }

    /**
     * @dev Returns a human-readable string representation of a LockState enum value.
     * @param _state The LockState enum value.
     * @return A string describing the state.
     */
    function getStateDescription(LockState _state) external pure returns (string memory) {
        if (_state == LockState.Active) return "Active";
        if (_state == LockState.Vesting) return "Vesting";
        if (_state == LockState.Releasable) return "Releasable";
        if (_state == LockState.Claimed) return "Claimed";
        if (_state == LockState.Cancelled) return "Cancelled";
        if (_state == LockState.ResolverReturned) return "ResolverReturned";
        return "Unknown";
    }


    // --- Action Functions (Modify Lock State) ---

    /**
     * @dev Allows the depositor to cancel a lock and get the NFT back.
     * This is only possible if the lock is Active (i.e., before the start time).
     * Updates state to Cancelled and transfers NFT back to depositor.
     * @param _lockId The unique identifier of the lock to cancel.
     */
    function cancelLock(bytes32 _lockId)
        external
        onlyLockExists(_lockId)
        onlyDepositor(_lockId)
        onlyBeforeVestingStart(_lockId) // Must be Active state and before startTime
    {
        LockData storage lock = locks[_lockId];
        LockState oldState = lock.state;
        lock.state = LockState.Cancelled;

        // Decrement active counts
        activeDepositorLockCount[lock.depositor]--;
        activeRecipientLockCount[lock.recipient]--;
        // Remove NFT lock mapping
        delete nftToLockId[lock.nftContract][lock.tokenId];
        // Do NOT delete the lock data itself, just mark it as cancelled for history/auditing.

        // Return NFT to depositor
        IERC721(lock.nftContract).safeTransferFrom(address(this), lock.depositor, lock.tokenId);

        emit LockStateChanged(_lockId, oldState, lock.state, block.timestamp);
        emit LockCancelled(_lockId, lock.depositor, lock.nftContract, lock.tokenId);
    }

    /**
     * @dev Allows the recipient to claim the NFT once it is releasable.
     * This requires the lock state to be Releasable (which implies vesting/cliff passed).
     * Updates state to Claimed and transfers NFT to recipient.
     * @param _lockId The unique identifier of the lock to claim.
     */
    function claimNFT(bytes32 _lockId)
        external
        onlyLockExists(_lockId)
        onlyRecipient(_lockId)
    {
         // Re-check state and time conditions explicitly, even though isReleasable is checked
         LockState currentState = getLockState(_lockId);
         require(currentState == LockState.Releasable, "Lock is not yet releasable");

         LockData storage lock = locks[_lockId];
         LockState oldState = lock.state;
         lock.state = LockState.Claimed; // Set state to Claimed

         // Decrement active counts
        activeDepositorLockCount[lock.depositor]--;
        activeRecipientLockCount[lock.recipient]--;
        // Remove NFT lock mapping
        delete nftToLockId[lock.nftContract][lock.tokenId];
        // Do NOT delete the lock data itself, just mark it as claimed.

         // Transfer NFT to recipient
         IERC721(lock.nftContract).safeTransferFrom(address(this), lock.recipient, lock.tokenId);

         emit LockStateChanged(_lockId, oldState, lock.state, block.timestamp);
         emit NFTClaimed(_lockId, lock.recipient, lock.nftContract, lock.tokenId);
    }

    /**
     * @dev Allows the depositor to release the NFT to the recipient immediately.
     * This bypasses the time lock and cliff periods.
     * Possible only if the lock is Active or Vesting and not yet in a final state.
     * Updates state to Claimed and transfers NFT to recipient.
     * @param _lockId The unique identifier of the lock.
     */
    function earlyReleaseByDepositor(bytes32 _lockId)
        external
        onlyLockExists(_lockId)
        onlyDepositor(_lockId)
        onlyActiveOrVestingLock(_lockId) // Can release early during Active or Vesting
    {
         LockData storage lock = locks[_lockId];
         LockState oldState = lock.state;
         lock.state = LockState.Claimed; // Treat early release same as claiming

         // Decrement active counts
        activeDepositorLockCount[lock.depositor]--;
        activeRecipientLockCount[lock.recipient]--;
        // Remove NFT lock mapping
        delete nftToLockId[lock.nftContract][lock.tokenId];
        // Do NOT delete the lock data itself.

         // Transfer NFT to recipient
         IERC721(lock.nftContract).safeTransferFrom(address(this), lock.recipient, lock.tokenId);

         emit LockStateChanged(_lockId, oldState, lock.state, block.timestamp);
         // Use the Claimed event as the outcome is the same for the recipient
         emit NFTClaimed(_lockId, lock.recipient, lock.nftContract, lock.tokenId);
    }


    /**
     * @dev Allows the designated resolver to return the NFT to the depositor.
     * This can be used in case of disputes or emergencies.
     * Possible only if the lock is not yet in a final state (Claimed, Cancelled, ResolverReturned).
     * Updates state to ResolverReturned and transfers NFT back to depositor.
     * @param _lockId The unique identifier of the lock.
     */
    function returnNFTByResolver(bytes32 _lockId)
        external
        onlyLockExists(_lockId)
        onlyResolver()
        onlyNotFinalState(_lockId) // Can return from Active, Vesting, or Releasable states
    {
        LockData storage lock = locks[_lockId];
        LockState oldState = lock.state;
        lock.state = LockState.ResolverReturned; // Set state

        // Decrement active counts if not already in a final state count wouldn't have removed them
        // This might be tricky if counters only decrement on specific FINAL states.
        // Let's refine counter logic: decrement when state becomes Claimed, Cancelled, or ResolverReturned.
        // So, if it was Active/Vesting/Releasable, decrement now.
        if (oldState == LockState.Active || oldState == LockState.Vesting || oldState == LockState.Releasable) {
             activeDepositorLockCount[lock.depositor]--;
             activeRecipientLockCount[lock.recipient]--;
             // Remove NFT lock mapping only if it was locked
             delete nftToLockId[lock.nftContract][lock.tokenId];
        }
        // Do NOT delete the lock data itself.

        // Transfer NFT back to depositor
        IERC721(lock.nftContract).safeTransferFrom(address(this), lock.depositor, lock.tokenId);

        emit LockStateChanged(_lockId, oldState, lock.state, block.timestamp);
        emit NFTReturnedByResolver(_lockId, lock.depositor, msg.sender, lock.nftContract, lock.tokenId);
    }

    /**
     * @dev Allows the depositor to update the description of a lock.
     * Possible only if the lock is Active or Vesting.
     * @param _lockId The unique identifier of the lock.
     * @param _newDescription The new description string.
     */
    function updateLockDescription(bytes32 _lockId, string calldata _newDescription)
        external
        onlyLockExists(_lockId)
        onlyDepositor(_lockId)
        onlyActiveOrVestingLock(_lockId) // Can update description while active or vesting
    {
        LockData storage lock = locks[_lockId];
        lock.description = _newDescription;
        emit DescriptionUpdated(_lockId, _newDescription);
    }
}
```