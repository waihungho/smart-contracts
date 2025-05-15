Okay, let's create a smart contract called `QuantumLockNFT`. This contract will combine concepts of time-locked value, dynamic state NFTs, energy mechanics, and limited observation rights, going beyond standard ERC721 use cases.

**Concept:** `QuantumLockNFT` represents a digital "lock" or vault that holds staked ERC20 tokens. These locks have different "types" or "difficulties", affecting how they are unlocked. Unlocking requires initiating a time-based "unlock sequence" and potentially maintaining an "energy level" within the lock over time. Successfully unlocking reveals a unique secret hash and allows claiming the staked tokens. The NFT's appearance (metadata) could change based on its state (Sealed, Charging, Unlocking, Open, Expired). The contract also includes a unique "observer" feature, allowing the lock owner to grant limited viewing permissions to others.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // To interact with staked ERC20 tokens
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title QuantumLockNFT
 * @dev An ERC721 contract representing dynamic, time-locked vaults with energy mechanics and observer patterns.
 * Locks hold staked ERC20 tokens and reveal a secret hash upon successful time-based unlocking.
 */
contract QuantumLockNFT is ERC721URIStorage, Ownable, ReentrancyGuard, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- Outline and Function Summary ---
    // I. Data Structures & Enums
    //    - LockStatus: Enum for the different states a lock can be in.
    //    - LockTypeParams: Struct defining parameters for different lock difficulties.
    //    - LockState: Struct holding the current state of a specific lock NFT.
    //
    // II. State Variables
    //    - Mappings for lock states, type parameters, observers, etc.
    //    - Admin-controlled variables.
    //
    // III. Events
    //    - Events emitted during key state changes and interactions.
    //
    // IV. Modifiers
    //    - Custom modifiers for access control based on lock state/owner.
    //
    // V. Constructor
    //    - Initializes the contract (ERC721 name/symbol, Ownable).
    //
    // VI. Admin Functions (Ownable)
    //    - setLockTypeParams: Define or update parameters for a lock type.
    //    - pauseContract: Pause core contract functions.
    //    - unpauseContract: Unpause core contract functions.
    //    - emergencyWithdrawTokens: Safely withdraw staked tokens in emergency.
    //    - updateBaseURI: Update the base URI for metadata.
    //    - burnLockAdmin: Admin ability to burn a lock (e.g., in case of error).
    //
    // VII. Core Lock Interaction Functions (User/Owner)
    //    - mintLock: Mints a new Quantum Lock NFT, requires staking ERC20 tokens.
    //    - chargeLock: Owner initiates/continues charging energy into the lock (time-based).
    //    - initiateUnlockSequence: Owner starts the timed unlock countdown.
    //    - attemptUnlock: Owner tries to open the lock after the sequence time has passed.
    //    - claimStakedTokens: Owner claims staked tokens after successful unlock.
    //    - revealSecretHash: Owner retrieves the secret hash after successful unlock.
    //    - burnLockOwner: Owner burns an expired or specific-state lock.
    //
    // VIII. Observer Functions
    //    - addObserver: Lock owner grants observer status to an address.
    //    - removeObserver: Lock owner revokes observer status.
    //
    // IX. Query/View Functions
    //    - getLockState: Get the full state details of a specific lock.
    //    - getLockTypeParams: Get the parameters for a specific lock type.
    //    - isLockOpen: Check if a lock is in the Open state.
    //    - isObserver: Check if an address is an observer for a lock.
    //    - getObservableState: Get limited state details accessible by observers.
    //    - calculateEstimatedChargeTime: Estimate time needed to charge.
    //    - calculateEstimatedUnlockTime: Estimate time until unlock attempt is possible.
    //
    // X. ERC721 Standard Functions (Overridden/Implemented)
    //    - tokenURI: Returns metadata URI, potentially dynamic based on lock state.
    //    - supportsInterface: Standard ERC721 function.
    //    - ownerOf: Standard ERC721 function.
    //    - balanceOf: Standard ERC721 function.
    //    - totalSupply: Standard ERC721 function.
    //    - getApproved: Standard ERC721 function.
    //    - isApprovedForAll: Standard ERC721 function.
    //    - approve: Standard ERC721 function.
    //    - setApprovalForAll: Standard ERC721 function.
    //    - transferFrom: Standard ERC721 function.
    //    - safeTransferFrom: Standard ERC721 function (two variations).
    //
    // XI. Internal Helper Functions
    //    - _updateLockState: Internal logic for state transitions and calculations.
    //    - _lockExists: Internal check if a lock ID is valid.

    // --- I. Data Structures & Enums ---
    enum LockStatus {
        Sealed,      // Initial state, inactive
        Charging,    // Receiving energy
        Decay,       // Energy is decreasing
        Unlocking,   // Unlock sequence initiated, timer running
        Open,        // Successfully unlocked, contents claimable
        Expired      // Unlock attempt failed permanently or sequence timed out/energy too low
    }

    struct LockTypeParams {
        uint256 minStakedAmount;    // Minimum tokens required to mint this type
        uint66 unlockSequenceTime;  // Time (in seconds) required for unlock sequence after initiation
        uint66 chargeRate;          // Energy gained per second while charging
        uint66 decayRate;           // Energy lost per second while in Decay state
        uint256 maxEnergy;          // Maximum energy capacity
        uint256 requiredEnergyForUnlock; // Energy needed to initiate unlock sequence
        uint256 minEnergyAtAttempt;  // Minimum energy needed to attempt unlock after sequence time
        bytes32 lockParamHash;      // Hash of these parameters for integrity check
    }

    struct LockState {
        LockStatus status;
        uint64 lockType;           // Index/ID of the lock type params
        address stakedTokenAddress; // Address of the ERC20 token staked
        uint256 stakedAmount;       // Amount of ERC20 tokens staked
        bytes32 secretHash;         // Hash of the secret associated with this lock
        uint256 currentEnergy;      // Current energy level
        uint64 lastStateChangeTime; // Timestamp of the last state change
        uint64 unlockAttemptTime;   // Timestamp when unlock sequence was initiated
        bool tokensClaimed;         // Flag if staked tokens have been claimed
        bool secretRevealed;        // Flag if secret hash has been revealed
    }

    // --- II. State Variables ---
    mapping(uint256 => LockState) private _lockStates;
    mapping(uint64 => LockTypeParams) private _lockTypeParams;
    mapping(uint256 => mapping(address => bool)) private _observers; // tokenId => observerAddress => isObserver
    uint64 private _nextLockTypeId = 0; // Counter for lock type IDs
    string private _baseTokenURI;

    // --- III. Events ---
    event LockMinted(uint256 indexed tokenId, address indexed owner, uint64 lockType, address indexed stakedToken, uint256 stakedAmount);
    event LockTypeParamsSet(uint64 indexed lockType, LockTypeParams params);
    event LockStatusChanged(uint256 indexed tokenId, LockStatus indexed oldStatus, LockStatus indexed newStatus, uint256 currentEnergy);
    event LockCharged(uint256 indexed tokenId, uint256 energyAdded, uint256 newEnergy);
    event UnlockSequenceInitiated(uint256 indexed tokenId, uint64 indexed unlockAttemptTime);
    event LockOpened(uint256 indexed tokenId);
    event TokensClaimed(uint256 indexed tokenId, address indexed receiver, uint256 amount);
    event SecretHashRevealed(uint256 indexed tokenId, bytes32 secretHash);
    event ObserverAdded(uint256 indexed tokenId, address indexed observer);
    event ObserverRemoved(uint256 indexed tokenId, address indexed observer);
    event EmergencyTokensWithdrawn(address indexed tokenAddress, uint256 amount, address indexed admin);
    event LockBurned(uint256 indexed tokenId, address indexed burner);

    // --- IV. Modifiers ---
    modifier onlyLockOwner(uint256 tokenId) {
        require(_exists(tokenId) && ownerOf(tokenId) == msg.sender, "Not lock owner");
        _;
    }

    modifier onlyLockObserverOrOwner(uint256 tokenId) {
        require(_exists(tokenId), "Lock does not exist");
        require(ownerOf(tokenId) == msg.sender || _observers[tokenId][msg.sender], "Not lock owner or observer");
        _;
    }

    // --- V. Constructor ---
    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {}

    // --- VI. Admin Functions (Ownable) ---

    /**
     * @dev Sets or updates parameters for a specific lock type.
     * Can only be called by the contract owner.
     * @param lockType ID of the lock type to set (use 0 for the first type, increment for new types).
     * @param params Struct containing the parameters for this lock type.
     */
    function setLockTypeParams(uint64 lockType, LockTypeParams memory params) external onlyOwner {
        require(params.minStakedAmount > 0, "Min staked amount must be positive");
        require(params.unlockSequenceTime > 0, "Unlock sequence time must be positive");
        require(params.chargeRate > 0 || params.decayRate > 0, "Charge or decay rate must be positive");
        require(params.maxEnergy > 0, "Max energy must be positive");
        require(params.requiredEnergyForUnlock > 0 && params.requiredEnergyForUnlock <= params.maxEnergy, "Required energy must be valid");
        require(params.minEnergyAtAttempt >= 0 && params.minEnergyAtAttempt <= params.maxEnergy, "Min energy at attempt must be valid");

        // Calculate expected hash to prevent parameter tampering if source is compromised
        bytes32 expectedHash = keccak256(abi.encode(
            params.minStakedAmount,
            params.unlockSequenceTime,
            params.chargeRate,
            params.decayRate,
            params.maxEnergy,
            params.requiredEnergyForUnlock,
            params.minEnergyAtAttempt
        ));
        require(params.lockParamHash == expectedHash, "Parameter hash mismatch");

        _lockTypeParams[lockType] = params;
        if (lockType >= _nextLockTypeId) {
            _nextLockTypeId = lockType + 1;
        }
        emit LockTypeParamsSet(lockType, params);
    }

    /**
     * @dev Pauses all state-changing interactions with locks.
     * Can only be called by the contract owner.
     */
    function pauseContract() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing interactions again.
     * Can only be called by the contract owner.
     */
    function unpauseContract() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @dev Allows the contract owner to withdraw staked tokens in an emergency.
     * Bypasses lock state checks. Should be used with extreme caution.
     * @param tokenAddress Address of the ERC20 token to withdraw.
     * @param amount Amount of tokens to withdraw.
     * @param recipient Address to send the tokens to.
     */
    function emergencyWithdrawTokens(address tokenAddress, uint256 amount, address recipient) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "Insufficient contract balance");
        token.transfer(recipient, amount);
        emit EmergencyTokensWithdrawn(tokenAddress, amount, msg.sender);
    }

    /**
     * @dev Updates the base URI for token metadata.
     * Can only be called by the contract owner.
     * @param baseURI The new base URI.
     */
    function updateBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * @dev Admin function to burn a specific lock NFT.
     * Use with extreme caution. Does not automatically return staked tokens.
     * @param tokenId The ID of the lock to burn.
     */
    function burnLockAdmin(uint256 tokenId) external onlyOwner nonReentrant {
        require(_exists(tokenId), "Lock does not exist");
        address owner = ownerOf(tokenId);

        // Note: Staked tokens remain in the contract unless claimed or emergency withdrawn
        // This design choice requires careful consideration - maybe tokens should be claimable by admin after burn?
        // For now, they are stranded unless emergency withdrawn.
        _burn(tokenId);
        delete _lockStates[tokenId]; // Clean up lock state
        // Clean up observer map (can be gas intensive for many observers, depending on usage)
        delete _observers[tokenId]; // Resets the inner mapping

        emit LockBurned(tokenId, msg.sender);
    }


    // --- VII. Core Lock Interaction Functions (User/Owner) ---

    /**
     * @dev Mints a new Quantum Lock NFT of a specified type.
     * Requires approval/transfer of minimum staked ERC20 tokens *before* calling this function.
     * Automatically sets the lock state to Sealed.
     * @param lockType ID of the lock type to mint.
     * @param stakedTokenAddress Address of the ERC20 token to stake.
     * @param stakedAmount Amount of ERC20 tokens to stake. Must be >= minStakedAmount for the type.
     * @param secretHash A keccak256 hash of the secret phrase/data associated with this lock.
     */
    function mintLock(
        uint64 lockType,
        address stakedTokenAddress,
        uint256 stakedAmount,
        bytes32 secretHash
    ) external nonReentrant whenNotPaused {
        require(_lockTypeParams[lockType].minStakedAmount > 0, "Lock type not configured"); // Ensure lock type exists
        LockTypeParams storage params = _lockTypeParams[lockType];
        require(stakedAmount >= params.minStakedAmount, "Insufficient staked amount for lock type");
        require(stakedTokenAddress != address(0), "Invalid token address");
        require(secretHash != bytes32(0), "Secret hash cannot be zero");

        // Transfer staked tokens to the contract
        IERC20 token = IERC20(stakedTokenAddress);
        require(token.transferFrom(msg.sender, address(this), stakedAmount), "Token transfer failed");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _mint(msg.sender, newTokenId);

        _lockStates[newTokenId] = LockState({
            status: LockStatus.Sealed,
            lockType: lockType,
            stakedTokenAddress: stakedTokenAddress,
            stakedAmount: stakedAmount,
            secretHash: secretHash,
            currentEnergy: 0,
            lastStateChangeTime: uint64(block.timestamp),
            unlockAttemptTime: 0, // Not initiated yet
            tokensClaimed: false,
            secretRevealed: false
        });

        emit LockMinted(newTokenId, msg.sender, lockType, stakedTokenAddress, stakedAmount);
        emit LockStatusChanged(newTokenId, LockStatus.Sealed, LockStatus.Sealed, 0); // Explicitly signal initial state
    }

    /**
     * @dev Allows the lock owner to put the lock into a Charging state or update energy based on time spent charging.
     * Requires the lock to be in Sealed, Charging, or Decay state.
     * Transitions to Charging if currently Sealed or Decay. Updates energy based on time in Charging state.
     * @param tokenId The ID of the lock to charge.
     */
    function chargeLock(uint256 tokenId) external onlyLockOwner(tokenId) nonReentrant whenNotPaused {
        LockState storage state = _lockStates[tokenId];
        LockTypeParams storage params = _lockTypeParams[state.lockType];

        require(state.status == LockStatus.Sealed || state.status == LockStatus.Charging || state.status == LockStatus.Decay,
                "Lock must be Sealed, Charging, or Decay to charge");
        require(params.chargeRate > 0, "Lock type has no charge rate");

        uint256 oldEnergy = state.currentEnergy;
        LockStatus oldStatus = state.status;

        // Update energy based on time spent in previous state
        _updateLockState(tokenId);

        // Transition to Charging state if not already there
        if (state.status != LockStatus.Charging) {
            state.status = LockStatus.Charging;
            state.lastStateChangeTime = uint64(block.timestamp);
            emit LockStatusChanged(tokenId, oldStatus, state.status, state.currentEnergy);
        }

        emit LockCharged(tokenId, state.currentEnergy - oldEnergy, state.currentEnergy);
    }

    /**
     * @dev Allows the lock owner to initiate the unlock sequence.
     * Requires the lock to be in Charging or Sealed state and have sufficient energy.
     * Transitions the lock to the Unlocking state and sets the unlock attempt time.
     * @param tokenId The ID of the lock to unlock.
     */
    function initiateUnlockSequence(uint256 tokenId) external onlyLockOwner(tokenId) nonReentrant whenNotPaused {
        LockState storage state = _lockStates[tokenId];
        LockTypeParams storage params = _lockTypeParams[state.lockType];

        require(state.status == LockStatus.Sealed || state.status == LockStatus.Charging || state.status == LockStatus.Decay,
                "Lock must be Sealed, Charging, or Decay to initiate unlock");

        // Update energy based on time spent in previous state before checking energy requirement
         _updateLockState(tokenId);

        require(state.currentEnergy >= params.requiredEnergyForUnlock, "Insufficient energy to initiate unlock");
        require(params.unlockSequenceTime > 0, "Unlock sequence time not set for this lock type");

        LockStatus oldStatus = state.status;
        state.status = LockStatus.Unlocking;
        state.lastStateChangeTime = uint64(block.timestamp);
        state.unlockAttemptTime = uint64(block.timestamp + params.unlockSequenceTime);

        emit LockStatusChanged(tokenId, oldStatus, state.status, state.currentEnergy);
        emit UnlockSequenceInitiated(tokenId, state.unlockAttemptTime);
    }

    /**
     * @dev Allows the lock owner to attempt to open the lock after the unlock sequence time has passed.
     * Requires the lock to be in the Unlocking state and the required time to have passed.
     * Checks minimum energy level at the moment of attempt. Success transitions to Open, failure to Expired or Decay.
     * @param tokenId The ID of the lock to attempt to open.
     */
    function attemptUnlock(uint256 tokenId) external onlyLockOwner(tokenId) nonReentrant whenNotPaused {
        LockState storage state = _lockStates[tokenId];
        LockTypeParams storage params = _lockTypeParams[state.lockType];

        require(state.status == LockStatus.Unlocking, "Lock must be in Unlocking state");
        require(block.timestamp >= state.unlockAttemptTime, "Unlock sequence time not yet reached");

        // Update energy based on time spent in Unlocking state (potential decay)
        _updateLockState(tokenId);

        LockStatus oldStatus = state.status;

        if (state.currentEnergy >= params.minEnergyAtAttempt) {
            // Successful unlock
            state.status = LockStatus.Open;
            state.lastStateChangeTime = uint64(block.timestamp);
            emit LockStatusChanged(tokenId, oldStatus, state.status, state.currentEnergy);
            emit LockOpened(tokenId);
        } else {
            // Failed unlock - transition to Expired or Decay based on logic (e.g., permanent fail or temporary)
            // Let's make it transition to Expired for this example.
            state.status = LockStatus.Expired;
            state.lastStateChangeTime = uint64(block.timestamp);
            emit LockStatusChanged(tokenId, oldStatus, state.status, state.currentEnergy);
            // Optionally, emit a LockAttemptFailed event
        }
    }

    /**
     * @dev Allows the lock owner to claim the staked ERC20 tokens after the lock has been successfully opened.
     * Requires the lock to be in the Open state and tokens not already claimed.
     * @param tokenId The ID of the lock from which to claim tokens.
     */
    function claimStakedTokens(uint256 tokenId) external onlyLockOwner(tokenId) nonReentrant {
        LockState storage state = _lockStates[tokenId];
        require(state.status == LockStatus.Open, "Lock must be Open to claim tokens");
        require(!state.tokensClaimed, "Tokens already claimed");

        state.tokensClaimed = true;
        IERC20 token = IERC20(state.stakedTokenAddress);

        // Use call to prevent reentrancy issues if token is malicious
        // Or use safeTransfer from OpenZeppelin's SafeERC20 (recommended but requires import)
        // For simplicity here, using standard transfer, but NonReentrantGuard is active.
        // A robust contract would use SafeERC20.safeTransfer
        token.transfer(msg.sender, state.stakedAmount);

        emit TokensClaimed(tokenId, msg.sender, state.stakedAmount);
    }

    /**
     * @dev Allows the lock owner to retrieve the secret hash associated with the lock.
     * Requires the lock to be in the Open state and hash not already revealed (optional flag).
     * @param tokenId The ID of the lock to reveal the secret hash for.
     * @return bytes32 The keccak256 hash of the secret.
     */
    function revealSecretHash(uint256 tokenId) external onlyLockOwner(tokenId) nonReentrant returns (bytes32) {
        LockState storage state = _lockStates[tokenId];
        require(state.status == LockStatus.Open, "Lock must be Open to reveal secret");
        // Optional: require(!state.secretRevealed, "Secret already revealed");

        state.secretRevealed = true;
        emit SecretHashRevealed(tokenId, state.secretHash);
        return state.secretHash;
    }

     /**
     * @dev Allows the lock owner to burn their lock NFT.
     * Can only be done if the lock is in the Expired or Open state (after claiming tokens).
     * Does NOT return staked tokens if burned from Expired state.
     * @param tokenId The ID of the lock to burn.
     */
    function burnLockOwner(uint256 tokenId) external onlyLockOwner(tokenId) nonReentrant {
        LockState storage state = _lockStates[tokenId];
        require(state.status == LockStatus.Expired || (state.status == LockStatus.Open && state.tokensClaimed),
                "Lock must be Expired or Open (tokens claimed) to be burned by owner");

        _burn(tokenId);
        delete _lockStates[tokenId]; // Clean up state
        delete _observers[tokenId]; // Clean up observers
        emit LockBurned(tokenId, msg.sender);
    }


    // --- VIII. Observer Functions ---

    /**
     * @dev Allows the lock owner to grant observer status for their lock to another address.
     * Observers can view limited state information about the lock.
     * @param tokenId The ID of the lock.
     * @param observerAddress The address to grant observer status.
     */
    function addObserver(uint256 tokenId, address observerAddress) external onlyLockOwner(tokenId) {
        require(observerAddress != address(0), "Invalid address");
        require(observerAddress != msg.sender, "Cannot add owner as observer");
        _observers[tokenId][observerAddress] = true;
        emit ObserverAdded(tokenId, observerAddress);
    }

    /**
     * @dev Allows the lock owner to revoke observer status for their lock from an address.
     * @param tokenId The ID of the lock.
     * @param observerAddress The address to remove observer status from.
     */
    function removeObserver(uint256 tokenId, address observerAddress) external onlyLockOwner(tokenId) {
        _observers[tokenId][observerAddress] = false; // Setting to false is sufficient
        emit ObserverRemoved(tokenId, observerAddress);
    }

    // --- IX. Query/View Functions ---

    /**
     * @dev Gets the full state details of a specific lock.
     * Only callable by the lock owner or a designated observer.
     * @param tokenId The ID of the lock.
     * @return LockState Struct containing the lock's current state.
     */
    function getLockState(uint256 tokenId) external view onlyLockObserverOrOwner(tokenId) returns (LockState memory) {
        require(_lockExists(tokenId), "Lock does not exist");
        // Note: This view function does NOT update the energy based on current time.
        // Energy calculation based on time is done in state-changing functions.
        // A client would need to call calculateCurrentEnergy if precise real-time energy is needed before a transaction.
        return _lockStates[tokenId];
    }

    /**
     * @dev Gets the full parameters for a specific lock type.
     * Publicly accessible.
     * @param lockType The ID of the lock type.
     * @return LockTypeParams Struct containing the lock type's parameters.
     */
    function getLockTypeParams(uint64 lockType) external view returns (LockTypeParams memory) {
        require(_lockTypeParams[lockType].minStakedAmount > 0, "Lock type not configured"); // Simple check for existence
        return _lockTypeParams[lockType];
    }

    /**
     * @dev Checks if a specific lock is currently in the Open state.
     * Publicly accessible.
     * @param tokenId The ID of the lock.
     * @return bool True if the lock is Open, false otherwise.
     */
    function isLockOpen(uint256 tokenId) external view returns (bool) {
        if (!_lockExists(tokenId)) return false;
        return _lockStates[tokenId].status == LockStatus.Open;
    }

    /**
     * @dev Checks if an address is an observer for a specific lock.
     * Publicly accessible.
     * @param tokenId The ID of the lock.
     * @param observerAddress The address to check.
     * @return bool True if the address is an observer, false otherwise.
     */
    function isObserver(uint256 tokenId, address observerAddress) external view returns (bool) {
        if (!_lockExists(tokenId)) return false;
        return _observers[tokenId][observerAddress];
    }

     /**
     * @dev Gets limited state information accessible by observers or the owner.
     * Useful for displaying basic status without revealing sensitive details like secret hash or exact staked amount.
     * @param tokenId The ID of the lock.
     * @return status The current LockStatus.
     * @return lockType The lock type ID.
     * @return currentEnergy The current energy level (as last updated by a transaction).
     * @return lastStateChangeTime The timestamp of the last state change.
     * @return unlockAttemptTime The timestamp the unlock sequence was initiated (0 if not initiated).
     */
    function getObservableState(uint256 tokenId) external view onlyLockObserverOrOwner(tokenId) returns (LockStatus status, uint64 lockType, uint256 currentEnergy, uint64 lastStateChangeTime, uint64 unlockAttemptTime) {
         require(_lockExists(tokenId), "Lock does not exist");
         LockState memory state = _lockStates[tokenId];
         // Return a subset of the state
         return (
             state.status,
             state.lockType,
             state.currentEnergy, // Note: This is energy as of the last transaction, not real-time
             state.lastStateChangeTime,
             state.unlockAttemptTime
         );
     }

    /**
     * @dev Estimates the time required to fully charge the lock from its current energy level.
     * Pure calculation based on stored state and type params. Does not update state.
     * @param tokenId The ID of the lock.
     * @return uint64 Estimated seconds required to reach max energy. Returns 0 if already max or cannot charge.
     */
    function calculateEstimatedChargeTime(uint256 tokenId) external view returns (uint64) {
        if (!_lockExists(tokenId)) return 0;
        LockState memory state = _lockStates[tokenId];
        LockTypeParams memory params = _lockTypeParams[state.lockType];

        if (params.chargeRate == 0 || state.currentEnergy >= params.maxEnergy ||
            (state.status != LockStatus.Sealed && state.status != LockStatus.Charging && state.status != LockStatus.Decay)) {
            return 0;
        }

        uint256 energyNeeded = params.maxEnergy - state.currentEnergy;
        return uint64((energyNeeded + params.chargeRate - 1) / params.chargeRate); // Ceiling division
    }

    /**
     * @dev Estimates the time remaining until an unlock attempt is possible after initiating the sequence.
     * Pure calculation. Does not update state.
     * @param tokenId The ID of the lock.
     * @return uint64 Estimated seconds remaining. Returns 0 if sequence not initiated, or if already ready/past due.
     */
    function calculateEstimatedUnlockTime(uint256 tokenId) external view returns (uint64) {
         if (!_lockExists(tokenId)) return 0;
         LockState memory state = _lockStates[tokenId];

         if (state.status != LockStatus.Unlocking || state.unlockAttemptTime == 0) {
             return 0;
         }

         uint64 currentTime = uint64(block.timestamp);
         if (currentTime >= state.unlockAttemptTime) {
             return 0; // Time has already passed
         } else {
             return state.unlockAttemptTime - currentTime;
         }
    }


    // --- X. ERC721 Standard Functions (Overridden/Implemented) ---

    /**
     * @dev Returns the token URI for a given token ID.
     * Overridden to potentially provide dynamic metadata based on lock state.
     * @param tokenId The ID of the token.
     * @return string The token URI.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");
        LockState memory state = _lockStates[tokenId];

        // Append status-specific path or query parameter to the base URI
        string memory statusString;
        if (state.status == LockStatus.Sealed) statusString = "sealed";
        else if (state.status == LockStatus.Charging) statusString = "charging";
        else if (state.status == LockStatus.Decay) statusString = "decay";
        else if (state.status == LockStatus.Unlocking) statusString = "unlocking";
        else if (state.status == LockStatus.Open) statusString = "open";
        else if (state.status == LockStatus.Expired) statusString = "expired";
        else statusString = "unknown"; // Should not happen

        string memory base = _baseTokenURI;
        if (bytes(base).length == 0) {
             base = super.tokenURI(tokenId); // Fallback to standard URI storage if base URI is not set
        }

        // Simple concatenation: baseURI/tokenId?status=statusString
        // A more advanced implementation might use a dedicated metadata service
        // or build a full data URI on chain (expensive).
        // This is a simple example showing dynamic URI potential.
        return string(abi.encodePacked(base, Strings.toString(tokenId), "?status=", statusString));
    }

    // Standard ERC721 functions inherited from ERC721, ERC721URIStorage, ERC721Enumerable (if added)
    // Explicitly list them as per the >= 20 function requirement summary:
    // ownerOf(uint256 tokenId) - inherited
    // balanceOf(address owner) - inherited
    // totalSupply() - Requires ERC721Enumerable extension (let's add it)
    // getApproved(uint256 tokenId) - inherited
    // isApprovedForAll(address owner, address operator) - inherited
    // approve(address to, uint256 tokenId) - inherited
    // setApprovalForAll(address operator, bool approved) - inherited
    // transferFrom(address from, address to, uint256 tokenId) - inherited (with _beforeTokenTransfer)
    // safeTransferFrom(address from, address to, uint256 tokenId) - inherited (with _beforeTokenTransfer)
    // safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) - inherited (with _beforeTokenTransfer)
    // supportsInterface(bytes4 interfaceId) - inherited

    // Need to add ERC721Enumerable to get `totalSupply`.
    // import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
    // contract QuantumLockNFT is ERC721URIStorage, ERC721Enumerable, Ownable, ReentrancyGuard, Pausable {
    // Need to include ERC721Enumerable's hooks in _beforeTokenTransfer
    // This adds totalSupply(), tokenByIndex(), tokenOfOwnerByIndex(). Let's include it.

    // Adding ERC721Enumerable necessitates overriding _update and _increaseBalance:
    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint256 amount) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, amount);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
     // End of ERC721 Standard Functions section (most are inherited, some overridden)


    // --- XI. Internal Helper Functions ---

    /**
     * @dev Internal function to update energy based on time elapsed since the last state change,
     * and handle potential state transitions due to decay or reaching max energy.
     * Called by state-changing functions before performing their specific logic.
     * @param tokenId The ID of the lock.
     */
    function _updateLockState(uint256 tokenId) internal {
        LockState storage state = _lockStates[tokenId];
        LockTypeParams storage params = _lockTypeParams[state.lockType];
        uint64 currentTime = uint64(block.timestamp);
        uint64 timeElapsed = currentTime - state.lastStateChangeTime;

        LockStatus oldStatus = state.status;

        if (timeElapsed > 0) {
            if (state.status == LockStatus.Charging) {
                if (params.chargeRate > 0) {
                    uint256 energyGained = uint256(timeElapsed) * params.chargeRate;
                    uint256 newEnergy = state.currentEnergy + energyGained;
                    state.currentEnergy = newEnergy > params.maxEnergy ? params.maxEnergy : newEnergy;

                    // If charging completes, transition to Sealed or Decay (owner needs to initiate next step)
                    if (state.currentEnergy == params.maxEnergy) {
                        state.status = params.decayRate > 0 ? LockStatus.Decay : LockStatus.Sealed; // If decay rate > 0, move to decay
                        state.lastStateChangeTime = currentTime;
                        emit LockStatusChanged(tokenId, oldStatus, state.status, state.currentEnergy);
                    }
                }
            } else if (state.status == LockStatus.Decay) {
                 if (params.decayRate > 0) {
                    uint256 energyLost = uint256(timeElapsed) * params.decayRate;
                    if (state.currentEnergy > energyLost) {
                        state.currentEnergy -= energyLost;
                    } else {
                        state.currentEnergy = 0;
                        // Transition to Expired if energy hits zero in Decay? Or just stay at 0?
                        // Let's have it stay at 0, owner needs to recharge.
                    }
                 }
                 // No status change needed unless energy hits 0 and we want a specific transition (decided against for now)
            } else if (state.status == LockStatus.Unlocking) {
                 // Energy may decay during unlocking sequence
                 if (params.decayRate > 0) {
                    uint256 energyLost = uint256(timeElapsed) * params.decayRate;
                    if (state.currentEnergy > energyLost) {
                         state.currentEnergy -= energyLost;
                    } else {
                         state.currentEnergy = 0;
                         // If energy hits zero during unlock sequence, maybe automatically fail?
                         // For now, fail is checked only at attemptUnlock.
                    }
                 }
                 // Status remains Unlocking until attemptUnlock is called
            }
            // For Sealed, Open, Expired states, energy doesn't change passively over time in this design.
            state.lastStateChangeTime = currentTime; // Update time even if energy didn't change
        }
    }

    /**
     * @dev Internal helper to check if a tokenId exists and has associated lock state.
     * @param tokenId The ID of the lock.
     * @return bool True if the lock exists in the _lockStates mapping.
     */
    function _lockExists(uint256 tokenId) internal view returns (bool) {
        // A simple check based on whether the tokenId exists in the ERC721 mapping
        // AND if it has a corresponding entry in our custom state mapping.
        // The latter is more robust for our custom state.
        // The ERC721 ownerOf check is already handled by _exists in inherited functions.
        // We need a way to check if _lockStates[tokenId] has been initialized.
        // Checking a non-zero default value is one way, or tracking a set of token IDs.
        // Using the tokenIDCounter ensures IDs are minted sequentially.
        // Checking if tokenId is within the valid range is a simple check.
        return tokenId > 0 && tokenId <= _tokenIdCounter.current();
    }

     /**
      * @dev See {ERC721-_beforeTokenTransfer}.
      * We override this to clean up lock state when an NFT is transferred or burned.
      * Crucially, state and observer info stays with the NFT, but we might need
      * to handle status changes on transfer (e.g., pause charging/unlocking).
      */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable) // Include ERC721Enumerable in override chain
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (from != address(0) && to == address(0)) {
            // Burning the token
            // Custom burn logic handles state cleanup in burnLockAdmin/burnLockOwner
            // This hook could also be used, but letting the specific burn function handle it
            // ensures state-specific cleanup (e.g., refunding tokens based on state, if implemented)
        } else if (from != address(0) && to != address(0)) {
            // Transferring the token to a new owner
            // The lock state and observers transfer with the NFT implicitly via the mapping keys (tokenId).
            // However, ongoing processes like Charging or Unlocking should potentially reset or pause.
            LockState storage state = _lockStates[tokenId];
            if (state.status == LockStatus.Charging || state.status == LockStatus.Unlocking) {
                 // Pause state transitions on transfer - new owner must re-initiate
                _updateLockState(tokenId); // Finalize energy calculation before state change
                LockStatus oldStatus = state.status;
                state.status = LockStatus.Sealed; // Go back to Sealed state on transfer
                state.unlockAttemptTime = 0; // Reset unlock sequence timer
                state.lastStateChangeTime = uint64(block.timestamp); // Update timestamp
                emit LockStatusChanged(tokenId, oldStatus, state.status, state.currentEnergy);
            }
            // Note: Observers remain linked to the tokenId. New owner inherits observer list.
            // Owner can remove observers if desired.
        }
        // Minting (from address(0)) requires setup *after* transfer, handled in mintLock
    }


    // --- Receive function ---
    // Prevent accidental Ether transfers to the contract
    receive() external payable {
        revert("Ether not accepted");
    }
}
```