Okay, here is a Solidity smart contract featuring a concept called "Ephemeral & Conditional Access Pass (ECAP)". This contract manages unique, non-fungible digital passes that grant specific, time-sensitive rights or access. The passes have dynamic states, adjustable permissions, karma scores, and can be delegated or redeemed, making them more advanced than typical NFTs or simple access tokens.

It's designed to be distinct from standard open-source contracts like ERC-721 or ERC-1155, although it shares the concept of unique IDs. The features like dynamic states, adjustable per-pass permissions, karma, delegation of rights, and data redemption are combined in a novel way.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

// --- Outline ---
// 1. Contract Overview: Manages Ephemeral & Conditional Access Passes (ECAP)
// 2. Roles: Owner, Minters, State Managers
// 3. Data Structures: Enum PassState, Struct Pass
// 4. Core State Variables: Passes mapping, Counters, Role mappings, Active supply counter
// 5. Events: For key actions (Minting, State changes, Role changes, etc.)
// 6. Custom Errors: For specific failure conditions
// 7. Access Control & Pausability
// 8. Pass Management:
//    - Minting & Batch Minting
//    - Querying Pass Details & Status
//    - Updating Pass Properties (State, Expiry, Tier, Karma, Data, Permissions)
//    - Conditional Transfer (Manager initiated or Self-redeem)
//    - Burning
//    - Delegation of Pass Rights (Advanced)
//    - Redemption of Pass Data (Advanced)
//    - Bulk Operations
// 9. Utility Functions: Checking Permissions, Active status, Supply queries
// 10. ERC165 support (Basic interface detection)

// --- Function Summary ---
// Constructor: Initializes contract, sets owner and initial roles.
//
// Role Management:
// - setMinter(address minter, bool enabled): Grant or revoke MINTER role.
// - isMinter(address account): Check if an address has the MINTER role.
// - setStateManager(address manager, bool enabled): Grant or revoke STATE_MANAGER role.
// - isStateManager(address account): Check if an address has the STATE_MANAGER role.
//
// Pausability (Inherited from Pausable):
// - pause(): Pause contract operations (only owner).
// - unpause(): Unpause contract operations (only owner).
//
// Pass Creation:
// - mintPass(address recipient, uint256 expiryTime, PassState initialState, uint8 tier, bytes32 associatedData, uint32 permissionsBitmap): Creates and issues a new pass. (Only MINTER)
// - mintBatch(address[] recipients, uint256[] expiryTimes, PassState[] initialStates, uint8[] tiers, bytes32[] associatedDatas, uint32[] permissionsBitmaps): Creates multiple passes in a batch. (Only MINTER)
//
// Pass Querying:
// - getPassDetails(uint256 passId): Retrieve all details of a specific pass.
// - getPassState(uint256 passId): Get the current state of a pass.
// - getOwnerOfPass(uint256 passId): Get the owner of a pass.
// - getPassExpiryTime(uint256 passId): Get the expiry timestamp.
// - getPassAssociatedData(uint256 passId): Get the associated bytes32 data.
// - getPassKarma(uint256 passId): Get the karma score.
// - getPassPermissions(uint256 passId): Get the permission flags bitmap.
// - isPassActive(uint256 passId): Check if a pass is currently active (considering state and expiry).
// - checkPermission(uint256 passId, uint32 permissionFlag): Check if a specific permission flag is set for a pass.
// - getTotalSupply(): Get the total number of passes minted.
// - getActiveSupply(): Get the current number of active passes.
// - queryPassIdsByTier(uint8 tier): Returns an array of pass IDs belonging to a specific tier. (Potentially gas-intensive for large number of passes)
//
// Pass Updates (Only STATE_MANAGER unless specified otherwise):
// - updatePassState(uint256 passId, PassState newState): Change the state of a pass.
// - extendPassExpiry(uint256 passId, uint256 newExpiryTime): Update the expiry timestamp.
// - grantPermission(uint256 passId, uint32 permissionFlag): Add a specific permission flag to the pass's bitmap.
// - revokePermission(uint256 passId, uint32 permissionFlag): Remove a specific permission flag from the pass's bitmap.
// - updateAssociatedData(uint256 passId, bytes32 newData): Update the associated data hash.
// - updatePassTier(uint256 passId, uint8 newTier): Change the tier of a pass.
// - adjustPassKarma(uint256 passId, int256 karmaChange): Adjust the karma score (positive or negative).
// - bulkUpdatePassesState(uint256[] passIds, PassState newState): Change the state for multiple passes. (Only STATE_MANAGER)
//
// Pass Lifecycle & Actions:
// - managerTransferPass(uint256 passId, address newOwner): Transfer a pass to a new owner. (Only STATE_MANAGER - allows recovery/migration)
// - burnPass(uint256 passId): Destroy a pass (Can be called by owner of pass or STATE_MANAGER).
// - delegatePassRights(uint256 passId, address delegatee, uint32 delegatedPermissionsBitmap, uint256 duration): Allow the pass holder to temporarily delegate a subset of their pass's permissions to another address. (Callable by Pass Owner)
// - getDelegatedPermissions(uint256 passId, address delegatee): Retrieve the permissions currently delegated to a specific address for a pass.
// - revokeDelegation(uint256 passId, address delegatee): Revoke specific delegation. (Callable by Pass Owner or STATE_MANAGER)
// - redeemPassForData(uint256 passId): A one-time action that reveals the associatedData (if hidden externally) and changes the pass state to REDEEMED, potentially burning it or reducing karma. (Callable by Pass Owner, subject to conditions)
//
// ERC165 Support:
// - supportsInterface(bytes4 interfaceId): Standard ERC165 function.

contract EphemeralConditionalAccessPass is Ownable, Pausable, IERC1665 {

    using Counters for Counters.Counter;

    // --- State Enum ---
    enum PassState {
        ACTIVE,         // Pass is functional and confers rights
        PAUSED,         // Pass is temporarily suspended
        EXPIRED,        // Pass has passed its expiry time (state update might be delayed, but isPassActive checks this)
        REVOKED,        // Pass permanently cancelled by manager
        REDEEMED,       // Pass has been used for a one-time action
        UPGRADED        // Pass replaced by a newer version (linked via associatedData?)
    }

    // --- Pass Struct ---
    struct Pass {
        address owner;              // The address holding the rights
        uint256 issueTime;          // Block timestamp when minted
        uint256 expiryTime;         // Block timestamp when the pass expires (0 for indefinite)
        PassState state;            // Current state of the pass
        uint8 tier;                 // Tier or level of the pass
        int256 karma;               // Reputation score associated with this pass/holder
        bytes32 associatedData;     // A hash or reference to associated off-chain/on-chain data
        uint32 permissionsBitmap;   // Bitmask representing granular permissions
    }

    // --- State Variables ---
    mapping(uint256 => Pass) private _passes;
    Counters.Counter private _passIdCounter;
    uint256 private _activePassCount = 0; // Counter for passes in ACTIVE state AND not expired

    mapping(address => bool) private _minters;
    mapping(address => bool) private _stateManagers;

    // Delegation: passId => delegatee => {permissionsBitmap, expiryTime}
    mapping(uint256 => mapping(address => DelegatedRights)) private _delegatedRights;
    struct DelegatedRights {
        uint32 permissionsBitmap;
        uint256 expiryTime;
    }

    // --- Events ---
    event PassMinted(uint256 indexed passId, address indexed owner, uint256 expiryTime, PassState initialState, uint8 tier, bytes32 associatedData, uint32 permissionsBitmap);
    event PassStateUpdated(uint256 indexed passId, PassState oldState, PassState newState);
    event PassExpiryExtended(uint256 indexed passId, uint256 oldExpiryTime, uint256 newExpiryTime);
    event PassPermissionsModified(uint256 indexed passId, uint32 oldPermissions, uint32 newPermissions);
    event PassAssociatedDataUpdated(uint256 indexed passId, bytes32 oldData, bytes32 newData);
    event PassTierUpdated(uint256 indexed passId, uint8 oldTier, uint8 newTier);
    event PassKarmaAdjusted(uint256 indexed passId, int256 oldKarma, int256 newKarma, int256 change);
    event PassTransferred(uint256 indexed passId, address indexed oldOwner, address indexed newOwner); // For managerTransfer
    event PassBurned(uint256 indexed passId, address indexed owner);
    event RightsDelegated(uint256 indexed passId, address indexed delegator, address indexed delegatee, uint32 permissionsBitmap, uint256 duration);
    event RightsDelegationRevoked(uint256 indexed passId, address indexed delegator, address indexed delegatee);
    event PassRedeemed(uint256 indexed passId, address indexed redeemer, PassState newState, bytes32 redeemedData);

    event MinterRoleSet(address indexed account, bool enabled);
    event StateManagerRoleSet(address indexed account, bool enabled);

    // --- Custom Errors ---
    error UnauthorizedMinter();
    error UnauthorizedStateManager();
    error UnauthorizedPassOperation(uint256 passId);
    error InvalidPassId(uint256 passId);
    error PassAlreadyExists(uint256 passId); // Should not happen with counter
    error PassNotActive(uint256 passId);
    error InvalidStateTransition(uint256 passId, PassState currentState, PassState newState);
    error ExpiryTimeInPast();
    error DelegationAlreadyExpired(uint256 passId, address delegatee);
    error NoActiveDelegation(uint256 passId, address delegatee);
    error DelegationExpiryInPast();
    error CannotRedeemPass(uint256 passId, PassState currentState);


    // --- Constructor ---
    constructor(address ownerAddress, address[] memory initialMinters, address[] memory initialStateManagers) Ownable(ownerAddress) Pausable(false) {
        for (uint i = 0; i < initialMinters.length; i++) {
            _minters[initialMinters[i]] = true;
            emit MinterRoleSet(initialMinters[i], true);
        }
        for (uint i = 0; i < initialStateManagers.length; i++) {
            _stateManagers[initialStateManagers[i]] = true;
            emit StateManagerRoleSet(initialStateManagers[i], true);
        }
    }

    // --- Access Control Modifiers (OpenZeppelin Ownable and Pausable used directly) ---
    modifier onlyMinter() {
        if (!_minters[msg.sender]) revert UnauthorizedMinter();
        _;
    }

    modifier onlyStateManager() {
        if (!_stateManagers[msg.sender]) revert UnauthorizedStateManager();
        _;
    }

    modifier passExists(uint256 passId) {
        if (_passes[passId].issueTime == 0 && passId != 0) revert InvalidPassId(passId); // Check issueTime > 0 to avoid conflict with default struct init
        _;
    }

    // --- Role Management Functions ---
    /// @notice Grant or revoke the MINTER role.
    /// @param minter The address to set the role for.
    /// @param enabled True to grant, false to revoke.
    function setMinter(address minter, bool enabled) external onlyOwner {
        _minters[minter] = enabled;
        emit MinterRoleSet(minter, enabled);
    }

    /// @notice Check if an address has the MINTER role.
    /// @param account The address to check.
    /// @return True if the account has the MINTER role, false otherwise.
    function isMinter(address account) public view returns (bool) {
        return _minters[account];
    }

    /// @notice Grant or revoke the STATE_MANAGER role.
    /// @param manager The address to set the role for.
    /// @param enabled True to grant, false to revoke.
    function setStateManager(address manager, bool enabled) external onlyOwner {
        _stateManagers[manager] = enabled;
        emit StateManagerRoleSet(manager, enabled);
    }

    /// @notice Check if an address has the STATE_MANAGER role.
    /// @param account The address to check.
    /// @return True if the account has the STATE_MANAGER role, false otherwise.
    function isStateManager(address account) public view returns (bool) {
        return _stateManagers[account];
    }

    // --- Pass Creation ---

    /// @notice Creates and issues a new Ephemeral Conditional Access Pass.
    /// @param recipient The address to receive the pass.
    /// @param expiryTime The timestamp when the pass expires (0 for indefinite).
    /// @param initialState The initial state of the pass.
    /// @param tier The initial tier of the pass.
    /// @param associatedData A hash or reference for associated data.
    /// @param permissionsBitmap Bitmask for initial permissions.
    /// @return The ID of the newly minted pass.
    function mintPass(
        address recipient,
        uint256 expiryTime,
        PassState initialState,
        uint8 tier,
        bytes32 associatedData,
        uint32 permissionsBitmap
    ) external onlyMinter whenNotPaused returns (uint256) {
        uint256 newPassId = _passIdCounter.current();
        _passIdCounter.increment();

        _passes[newPassId] = Pass({
            owner: recipient,
            issueTime: block.timestamp,
            expiryTime: expiryTime,
            state: initialState,
            tier: tier,
            karma: 0, // Start with 0 karma
            associatedData: associatedData,
            permissionsBitmap: permissionsBitmap
        });

        if (_passes[newPassId].state == PassState.ACTIVE && (expiryTime == 0 || expiryTime > block.timestamp)) {
             _activePassCount++;
        }

        emit PassMinted(newPassId, recipient, expiryTime, initialState, tier, associatedData, permissionsBitmap);

        return newPassId;
    }

    /// @notice Creates and issues multiple passes in a single transaction.
    /// @param recipients Array of recipient addresses.
    /// @param expiryTimes Array of expiry timestamps.
    /// @param initialStates Array of initial states.
    /// @param tiers Array of initial tiers.
    /// @param associatedDatas Array of associated data hashes.
    /// @param permissionsBitmaps Array of initial permissions bitmaps.
    function mintBatch(
        address[] memory recipients,
        uint256[] memory expiryTimes,
        PassState[] memory initialStates,
        uint8[] memory tiers,
        bytes32[] memory associatedDatas,
        uint32[] memory permissionsBitmaps
    ) external onlyMinter whenNotPaused {
        require(recipients.length == expiryTimes.length &&
                recipients.length == initialStates.length &&
                recipients.length == tiers.length &&
                recipients.length == associatedDatas.length &&
                recipients.length == permissionsBitmaps.length, "Array lengths must match");

        for (uint i = 0; i < recipients.length; i++) {
            uint256 newPassId = _passIdCounter.current();
            _passIdCounter.increment();

            _passes[newPassId] = Pass({
                owner: recipients[i],
                issueTime: block.timestamp,
                expiryTime: expiryTimes[i],
                state: initialStates[i],
                tier: tiers[i],
                karma: 0,
                associatedData: associatedDatas[i],
                permissionsBitmap: permissionsBitmaps[i]
            });

             if (_passes[newPassId].state == PassState.ACTIVE && (expiryTimes[i] == 0 || expiryTimes[i] > block.timestamp)) {
                 _activePassCount++;
             }

            emit PassMinted(newPassId, recipients[i], expiryTimes[i], initialStates[i], tiers[i], associatedDatas[i], permissionsBitmaps[i]);
        }
    }

    // --- Pass Querying ---

    /// @notice Retrieve all details for a given pass ID.
    /// @param passId The ID of the pass.
    /// @return A struct containing all pass details.
    function getPassDetails(uint256 passId) external view passExists(passId) returns (Pass memory) {
        return _passes[passId];
    }

    /// @notice Get the current state of a pass.
    /// @param passId The ID of the pass.
    /// @return The current PassState.
    function getPassState(uint256 passId) external view passExists(passId) returns (PassState) {
        return _passes[passId].state;
    }

    /// @notice Get the owner of a pass.
    /// @param passId The ID of the pass.
    /// @return The owner address.
    function getOwnerOfPass(uint256 passId) external view passExists(passId) returns (address) {
        return _passes[passId].owner;
    }

     /// @notice Get the expiry time of a pass.
    /// @param passId The ID of the pass.
    /// @return The expiry timestamp (0 for indefinite).
    function getPassExpiryTime(uint256 passId) external view passExists(passId) returns (uint256) {
        return _passes[passId].expiryTime;
    }

     /// @notice Get the associated data hash for a pass.
    /// @param passId The ID of the pass.
    /// @return The associated data hash.
    function getPassAssociatedData(uint256 passId) external view passExists(passId) returns (bytes32) {
        return _passes[passId].associatedData;
    }

    /// @notice Get the karma score of a pass.
    /// @param passId The ID of the pass.
    /// @return The karma score (can be negative).
    function getPassKarma(uint256 passId) external view passExists(passId) returns (int256) {
        return _passes[passId].karma;
    }

    /// @notice Get the permission bitmap for a pass.
    /// @param passId The ID of the pass.
    /// @return The permissions bitmap.
    function getPassPermissions(uint256 passId) external view passExists(passId) returns (uint32) {
        return _passes[passId].permissionsBitmap;
    }


    /// @notice Check if a pass is currently considered active.
    /// An active pass is in the ACTIVE state and has not passed its expiry time (if one is set).
    /// @param passId The ID of the pass.
    /// @return True if the pass is active, false otherwise.
    function isPassActive(uint256 passId) public view passExists(passId) returns (bool) {
        Pass storage pass = _passes[passId];
        return pass.state == PassState.ACTIVE && (pass.expiryTime == 0 || pass.expiryTime > block.timestamp);
    }

    /// @notice Check if a specific permission flag is set for a pass.
    /// @param passId The ID of the pass.
    /// @param permissionFlag The specific bit representing the permission (e.g., 1, 2, 4, 8...).
    /// @return True if the permission is set, false otherwise.
    function checkPermission(uint256 passId, uint32 permissionFlag) public view passExists(passId) returns (bool) {
        return (_passes[passId].permissionsBitmap & permissionFlag) == permissionFlag;
    }

    /// @notice Get the total number of passes that have been minted.
    /// @return The total supply.
    function getTotalSupply() external view returns (uint256) {
        return _passIdCounter.current();
    }

     /// @notice Get the number of passes that are currently active.
     /// This counter is updated during mint, burn, transfer, state updates, and expiry extensions.
     /// Note: A pass might appear active based on state/expiry but this count reflects the
     /// *last known* state. The `isPassActive` function provides the real-time check.
    /// @return The current active supply count.
    function getActiveSupply() external view returns (uint256) {
        return _activePassCount;
    }

     /// @notice Get the IDs of passes that belong to a specific tier.
     /// WARNING: This function iterates through all passes and can be gas-intensive
     /// if the total number of passes is very large. Use with caution.
     /// @param tier The tier to filter by.
     /// @return An array of pass IDs in the specified tier.
    function queryPassIdsByTier(uint8 tier) external view returns (uint256[] memory) {
        uint256 total = _passIdCounter.current();
        uint256[] memory tierPasses = new uint256[](total); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i <= total; i++) {
            if (_passes[i].issueTime > 0 && _passes[i].tier == tier) { // Check issueTime > 0 to ensure it's a valid pass
                tierPasses[count] = i;
                count++;
            }
        }
        // Resize array to actual count
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = tierPasses[i];
        }
        return result;
    }

    // --- Pass Updates ---

    /// @notice Change the state of a pass.
    /// @param passId The ID of the pass.
    /// @param newState The new state to set.
    function updatePassState(uint256 passId, PassState newState) external onlyStateManager whenNotPaused passExists(passId) {
        Pass storage pass = _passes[passId];
        PassState oldState = pass.state;

        // Optional: Add checks for valid state transitions if needed (e.g., cannot go from REVOKED to ACTIVE)
        // require(isValidStateTransition(oldState, newState), "Invalid state transition");

        pass.state = newState;

        // Update active pass count
        bool wasActive = (oldState == PassState.ACTIVE && (pass.expiryTime == 0 || pass.expiryTime > block.timestamp));
        bool isActive = (newState == PassState.ACTIVE && (pass.expiryTime == 0 || pass.expiryTime > block.timestamp));

        if (wasActive && !isActive) {
            _activePassCount--;
        } else if (!wasActive && isActive) {
            _activePassCount++;
        }


        emit PassStateUpdated(passId, oldState, newState);
    }

    /// @notice Extend or change the expiry time of a pass.
    /// Can be set to 0 for indefinite.
    /// @param passId The ID of the pass.
    /// @param newExpiryTime The new expiry timestamp.
    function extendPassExpiry(uint256 passId, uint256 newExpiryTime) external onlyStateManager whenNotPaused passExists(passId) {
         Pass storage pass = _passes[passId];
         uint256 oldExpiryTime = pass.expiryTime;

        // Update active pass count BEFORE changing expiry
        bool wasActive = (pass.state == PassState.ACTIVE && (oldExpiryTime == 0 || oldExpiryTime > block.timestamp));

         pass.expiryTime = newExpiryTime;

        // Update active pass count AFTER changing expiry
        bool isActive = (pass.state == PassState.ACTIVE && (newExpiryTime == 0 || newExpiryTime > block.timestamp));

        if (wasActive && !isActive) {
            _activePassCount--;
        } else if (!wasActive && isActive) {
            _activePassCount++;
        }

         emit PassExpiryExtended(passId, oldExpiryTime, newExpiryTime);
    }

    /// @notice Add a specific permission flag to a pass's bitmap.
    /// Does not remove existing flags.
    /// @param passId The ID of the pass.
    /// @param permissionFlag The permission bit to add.
    function grantPermission(uint256 passId, uint32 permissionFlag) external onlyStateManager whenNotPaused passExists(passId) {
        Pass storage pass = _passes[passId];
        uint32 oldPermissions = pass.permissionsBitmap;
        uint32 newPermissions = oldPermissions | permissionFlag; // Use bitwise OR to add flag
        if (oldPermissions != newPermissions) {
            pass.permissionsBitmap = newPermissions;
            emit PassPermissionsModified(passId, oldPermissions, newPermissions);
        }
    }

    /// @notice Remove a specific permission flag from a pass's bitmap.
    /// Does not affect other flags.
    /// @param passId The ID of the pass.
    /// @param permissionFlag The permission bit to remove.
    function revokePermission(uint256 passId, uint32 permissionFlag) external onlyStateManager whenNotPaused passExists(passId) {
         Pass storage pass = _passes[passId];
        uint32 oldPermissions = pass.permissionsBitmap;
        uint32 newPermissions = oldPermissions & (~permissionFlag); // Use bitwise AND with inverted flag to remove
        if (oldPermissions != newPermissions) {
            pass.permissionsBitmap = newPermissions;
            emit PassPermissionsModified(passId, oldPermissions, newPermissions);
        }
    }

    /// @notice Update the associated data hash for a pass.
    /// @param passId The ID of the pass.
    /// @param newData The new associated data hash.
    function updateAssociatedData(uint256 passId, bytes32 newData) external onlyStateManager whenNotPaused passExists(passId) {
        Pass storage pass = _passes[passId];
        bytes32 oldData = pass.associatedData;
        pass.associatedData = newData;
        emit PassAssociatedDataUpdated(passId, oldData, newData);
    }

    /// @notice Change the tier of a pass.
    /// @param passId The ID of the pass.
    /// @param newTier The new tier value.
    function updatePassTier(uint256 passId, uint8 newTier) external onlyStateManager whenNotPaused passExists(passId) {
        Pass storage pass = _passes[passId];
        uint8 oldTier = pass.tier;
        pass.tier = newTier;
        emit PassTierUpdated(passId, oldTier, newTier);
    }

    /// @notice Adjust the karma score of a pass.
    /// Can be used to increase (positive change) or decrease (negative change) karma.
    /// @param passId The ID of the pass.
    /// @param karmaChange The amount to add to the karma score (can be negative).
    function adjustPassKarma(uint256 passId, int256 karmaChange) external onlyStateManager whenNotPaused passExists(passId) {
        Pass storage pass = _passes[passId];
        int256 oldKarma = pass.karma;
        int256 newKarma = oldKarma + karmaChange;
        pass.karma = newKarma;
        emit PassKarmaAdjusted(passId, oldKarma, newKarma, karmaChange);
    }

     /// @notice Bulk update the state for multiple passes.
     /// Useful for batch pausing, revoking, etc.
     /// @param passIds Array of pass IDs to update.
     /// @param newState The new state to set for all specified passes.
    function bulkUpdatePassesState(uint256[] memory passIds, PassState newState) external onlyStateManager whenNotPaused {
        for (uint i = 0; i < passIds.length; i++) {
            uint256 passId = passIds[i];
            if (_passes[passId].issueTime == 0 && passId != 0) continue; // Skip invalid IDs silently or revert

            Pass storage pass = _passes[passId];
            PassState oldState = pass.state;
             if (oldState == newState) continue; // Skip if state is already the desired state

            pass.state = newState;

            // Update active pass count
            bool wasActive = (oldState == PassState.ACTIVE && (pass.expiryTime == 0 || pass.expiryTime > block.timestamp));
            bool isActive = (newState == PassState.ACTIVE && (pass.expiryTime == 0 || pass.expiryTime > block.timestamp));

            if (wasActive && !isActive) {
                 if (_activePassCount > 0) _activePassCount--; // Prevent underflow, though unlikely with checks
            } else if (!wasActive && isActive) {
                _activePassCount++;
            }

            emit PassStateUpdated(passId, oldState, newState);
        }
    }


    // --- Pass Lifecycle & Actions ---

    /// @notice Transfer a pass from its current owner to a new owner.
    /// This function is restricted to STATE_MANAGER to maintain the "soulbound" nature,
    /// allowing for transfers only in managed scenarios (e.g., recovery, migration).
    /// @param passId The ID of the pass to transfer.
    /// @param newOwner The address of the new owner.
    function managerTransferPass(uint256 passId, address newOwner) external onlyStateManager whenNotPaused passExists(passId) {
        Pass storage pass = _passes[passId];
        address oldOwner = pass.owner;

        require(oldOwner != newOwner, "Cannot transfer to self");
        require(newOwner != address(0), "Cannot transfer to zero address");

        pass.owner = newOwner;
        emit PassTransferred(passId, oldOwner, newOwner);
    }

    /// @notice Burn (destroy) a pass.
    /// Can be called by the current owner of the pass or a STATE_MANAGER.
    /// @param passId The ID of the pass to burn.
    function burnPass(uint256 passId) external whenNotPaused passExists(passId) {
        Pass storage pass = _passes[passId];

        // Check authorization: owner or state manager
        if (msg.sender != pass.owner && !_stateManagers[msg.sender]) {
            revert UnauthorizedPassOperation(passId);
        }

        address ownerToBurn = pass.owner; // Store owner before deletion

        // Update active pass count BEFORE deletion
        bool wasActive = (pass.state == PassState.ACTIVE && (pass.expiryTime == 0 || pass.expiryTime > block.timestamp));
        if (wasActive) {
             if (_activePassCount > 0) _activePassCount--;
        }

        // Delete the pass data
        delete _passes[passId];
        // Note: _passIdCounter is not decremented as IDs are unique and sequential.

        // Clean up any active delegations for this pass
        delete _delegatedRights[passId];

        emit PassBurned(passId, ownerToBurn);
    }

    /// @notice Allow the pass holder to temporarily delegate a subset of their pass's permissions.
    /// Useful for granting temporary access/rights without transferring the pass itself.
    /// @param passId The ID of the pass.
    /// @param delegatee The address to delegate permissions to.
    /// @param delegatedPermissionsBitmap Bitmask of permissions being delegated. Only permissions the delegator *currently* has can be delegated.
    /// @param duration The duration in seconds for which the delegation is valid.
    function delegatePassRights(
        uint256 passId,
        address delegatee,
        uint32 delegatedPermissionsBitmap,
        uint256 duration
    ) external whenNotPaused passExists(passId) {
        Pass storage pass = _passes[passId];
        require(msg.sender == pass.owner, "Only pass owner can delegate rights");
        require(delegatee != address(0), "Cannot delegate to zero address");
        require(duration > 0, "Delegation duration must be greater than zero");

        // Ensure only permissions the owner *currently* holds can be delegated
        require((pass.permissionsBitmap & delegatedPermissionsBitmap) == delegatedPermissionsBitmap, "Cannot delegate permissions you do not have");

        uint256 expiryTime = block.timestamp + duration;
        require(expiryTime > block.timestamp, DelegationExpiryInPast()); // Prevent overflow and past expiry

        _delegatedRights[passId][delegatee] = DelegatedRights({
            permissionsBitmap: delegatedPermissionsBitmap,
            expiryTime: expiryTime
        });

        emit RightsDelegated(passId, msg.sender, delegatee, delegatedPermissionsBitmap, duration);
    }

    /// @notice Get the permissions currently delegated to a specific address for a pass.
    /// Returns expired delegations as well, calling code should check expiry.
    /// @param passId The ID of the pass.
    /// @param delegatee The delegatee address.
    /// @return permissionsBitmap The delegated permissions bitmap.
    /// @return expiryTime The expiry timestamp of the delegation.
    function getDelegatedPermissions(uint256 passId, address delegatee) external view passExists(passId) returns (uint32 permissionsBitmap, uint256 expiryTime) {
        DelegatedRights storage delegated = _delegatedRights[passId][delegatee];
        return (delegated.permissionsBitmap, delegated.expiryTime);
    }

     /// @notice Revoke an active or expired delegation.
     /// Can be called by the pass owner or a STATE_MANAGER.
     /// @param passId The ID of the pass.
     /// @param delegatee The delegatee address whose rights are being revoked.
    function revokeDelegation(uint256 passId, address delegatee) external whenNotPaused passExists(passId) {
         Pass storage pass = _passes[passId];
        require(msg.sender == pass.owner || _stateManagers[msg.sender], "Unauthorized to revoke delegation");
        require(_delegatedRights[passId][delegatee].expiryTime > 0, NoActiveDelegation(passId, delegatee)); // Check if delegation existed

        delete _delegatedRights[passId][delegatee];

        emit RightsDelegationRevoked(passId, pass.owner, delegatee);
    }


    /// @notice A one-time action to "redeem" the pass for its associated data or utility.
    /// This changes the pass state to REDEEMED and performs custom logic.
    /// Example: Could unlock off-chain data, grant in-game item, etc.
    /// The specific logic here is illustrative (changes state, reduces karma).
    /// @param passId The ID of the pass to redeem.
    function redeemPassForData(uint256 passId) external whenNotPaused passExists(passId) {
        Pass storage pass = _passes[passId];
        require(msg.sender == pass.owner, "Only pass owner can redeem");
        require(isPassActive(passId), PassNotActive(passId));
        require(pass.state != PassState.REDEEMED, CannotRedeemPass(passId, pass.state)); // Cannot redeem twice

        // --- Custom Redemption Logic ---
        // This section is customizable based on what redemption means.
        // Example:
        // - Reveal/Use the associatedData (which is public on-chain, but this function acts as the 'key')
        // - Trigger an external system via an event with the associatedData
        // - Grant a different token/NFT
        // - Apply a permanent status effect

        // Example Action: Change state and reduce karma
        PassState oldState = pass.state;
        pass.state = PassState.REDEEMED; // Mark as redeemed

        int256 karmaChange = -100; // Example: penalize karma upon redemption
        int256 oldKarma = pass.karma;
        pass.karma += karmaChange;
        int256 newKarma = pass.karma;


        // --- End Custom Redemption Logic ---

        // Update active pass count if it was active and now isn't
        if (oldState == PassState.ACTIVE) {
            _activePassCount--; // Redeemed is not Active
        }

        emit PassStateUpdated(passId, oldState, PassState.REDEEMED);
        emit PassKarmaAdjusted(passId, oldKarma, newKarma, karmaChange);
        emit PassRedeemed(passId, msg.sender, PassState.REDEEMED, pass.associatedData); // Emit data or proof of redemption
    }

    /// @notice Allow setting an external metadata URI for a pass, similar to ERC721.
    /// Can be used to link to a JSON file describing the pass's attributes.
    /// Requires a custom mapping or storage within the Pass struct for the URI.
    /// This requires adding a `string metadataURI;` field to the Pass struct
    /// or a separate mapping `mapping(uint256 => string) private _tokenURIs;`.
    /// For simplicity and gas cost, let's add a mapping rather than struct field.
    // Add state variable: mapping(uint256 => string) private _passMetadataURIs;
    // Add function:
    // function setPassMetadataURI(uint256 passId, string memory uri) external onlyStateManager whenNotPaused passExists(passId) {
    //     _passMetadataURIs[passId] = uri;
    //     // Emit event? No standard event for this.
    // }
    // function getPassMetadataURI(uint256 passId) external view passExists(passId) returns (string memory) {
    //    return _passMetadataURIs[passId];
    // }
    // --- Skipping actual implementation here to keep struct smaller, but this is a common advanced feature ---


    // --- ERC165 Support ---
    /// @notice Standard ERC165 function to check if the contract supports a given interface.
    /// @param interfaceId The interface ID to check.
    /// @return True if the interface is supported, false otherwise.
    function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
        // Supports ERC165 (0x01ffc9a7) and Ownable (0x73637532) and Pausable (0x8e1a535c)
        // No custom interfaces defined here, but could add one for ECAP if needed.
        return interfaceId == type(IERC165).interfaceId
            || interfaceId == type(Ownable).interfaceId
            || interfaceId == type(Pausable).interfaceId;
    }

    // --- Internal Helpers ---
    // No complex internal helpers needed beyond the logic within functions.

}
```

---

**Explanation of Advanced/Creative/Trendy Concepts Used:**

1.  **Dynamic State (`PassState` Enum):** Passes aren't just "owned" or "not owned". They can be Active, Paused, Expired, Revoked, Redeemed, Upgraded. This allows for rich lifecycle management beyond simple token transfer/burn.
2.  **Per-Pass Dynamic Permissions (`permissionsBitmap`):** Each pass instance has its own set of granular permissions stored as bits in a uint32. These can be added or removed by a manager (`grantPermission`, `revokePermission`). This allows for fine-grained access control associated directly with the specific pass, not just the contract or owner role.
3.  **Karma Score (`int256 karma`):** A mutable integer associated with the pass. Can be used to track reputation, activity points, or any other score tied to the pass's usage or owner's behavior (updated via `adjustPassKarma`). Can influence other logic (not explicitly implemented, but `checkPermission` or `redeemPassForData` could check karma).
4.  **Associated Data (`bytes32 associatedData`):** A flexible field to link the on-chain pass to external data, proofs, content hashes, or other unique identifiers. Used in the `redeemPassForData` example.
5.  **Conditional "Soulbound" Nature:** Passes are not freely transferable by the holder. `managerTransferPass` allows controlled transfer only by a `STATE_MANAGER`, facilitating necessary operations like account recovery or upgrades while preserving a degree of binding to the original recipient. (Could be extended with specific permission flags allowing holder transfer *only if* that flag is set).
6.  **Delegation of Rights (`delegatePassRights`, `getDelegatedPermissions`, `revokeDelegation`):** A key advanced feature. The *owner* of a pass can grant *specific subsets* of their pass's *current* permissions to another address for a *limited time*. This is powerful for scenarios like granting temporary access, allowing someone to act on your behalf with specific rights, etc., without giving up ownership or all permissions.
7.  **Redemption Mechanism (`redeemPassForData`):** A specific function for a one-time action tied to the pass's purpose. It consumes the "utility" of the pass, changes its state (e.g., to `REDEEMED`), and potentially affects other properties like karma. This is more complex than a simple burn or transfer.
8.  **Role-Based Access Control (RBAC) Beyond Owner:** Uses `MINTER` and `STATE_MANAGER` roles managed by the owner, providing separation of concerns (minting new passes vs. managing existing ones). (Uses OpenZeppelin's Ownable but implements custom roles).
9.  **Pausability (Circuit Breaker):** Standard but important for managing potential issues. (Uses OpenZeppelin's Pausable).
10. **Bulk Operations (`mintBatch`, `bulkUpdatePassesState`):** Includes functions for efficiency when dealing with multiple passes.
11. **Active Pass Tracking:** Explicitly tracks the count of passes in the `ACTIVE` state that are *not* expired, providing a useful real-time metric (`_activePassCount`).
12. **Querying by Property (`queryPassIdsByTier`):** Allows filtering passes based on properties like tier (with necessary gas caution for large datasets).
13. **Custom Errors:** Uses `revert with custom error` for gas efficiency and clarity.
14. **Timestamp-Based Expiry:** Utilizes `block.timestamp` for time-sensitive pass validity.
15. **Bitwise Permissions:** Efficiently stores multiple boolean permissions in a single integer (`uint32`), allowing for granular control and easy checking/modification using bitwise operations.

This contract goes beyond standard token patterns by introducing dynamic state, granular per-instance permissions, reputation tracking, rights delegation, and a specific redemption lifecycle, making it suitable for use cases like complex membership systems, in-game assets with evolving properties, event access with conditional rights, or decentralized identity components where attributes and permissions are dynamic and tied to the holder but not freely traded.