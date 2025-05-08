Okay, let's create a smart contract called `QuantumLeapChronicles`. This contract will represent dynamic, evolving NFTs where each token is a "Chronicle" with a history of state changes ("Chronicle Entries"). The core concepts include:

1.  **Dynamic State:** Each Chronicle has a structured state that evolves.
2.  **Historical Tracking:** Every significant state change is recorded as a `ChronicleEntry`.
3.  **Quantum Leaps:** The primary action to advance a Chronicle's state, potentially gated by cooldowns.
4.  **Timeline Branching:** Creating a new Chronicle token that inherits the state of an existing one at a specific point.
5.  **Timeline Merging:** Combining aspects of two Chronicles into one, recording the event in both histories.
6.  **State Simulation:** A view function to predict the outcome of a state change without executing it on-chain.
7.  **Per-Token Cooldowns:** Configurable cooldowns for specific actions on individual tokens.
8.  **Activity Status:** Tokens can be marked as inactive (e.g., after being 'merged' into another).
9.  **Complex Access Control Simulation:** A function to check if a user *can* perform a certain action based on multiple factors (ownership, state, cooldowns).

This combines elements of dynamic NFTs, historical provenance, state-based interactions, and simulations, which are more advanced than typical ERC721 implementations.

---

## `QuantumLeapChronicles` Smart Contract Outline & Function Summary

**Outline:**

1.  **License & Pragma**
2.  **Interfaces:** Define necessary interfaces (ERC165, ERC721).
3.  **Errors:** Custom error definitions for clarity and gas efficiency.
4.  **Events:** Define events for state changes and actions.
5.  **Structs:**
    *   `ChronicleState`: Holds the current state of a Chronicle token.
    *   `ChronicleEntry`: Records a historical event or state change.
6.  **Enums:** Define types of history events.
7.  **State Variables:**
    *   ERC721 standard mappings (`_owners`, `_balances`, approvals).
    *   Total token supply counter.
    *   Mapping from token ID to `ChronicleState`.
    *   Mapping from token ID to array of `ChronicleEntry`.
    *   Mapping from interface ID to supported status (for ERC165).
8.  **Constructor:** Initializes ERC165 support.
9.  **ERC165 Functions:** `supportsInterface`.
10. **ERC721 Standard Functions:**
    *   `balanceOf`
    *   `ownerOf`
    *   `approve`
    *   `getApproved`
    *   `setApprovalForAll`
    *   `isApprovedForAll`
    *   `transferFrom`
    *   `safeTransferFrom` (two versions)
11. **Internal ERC721 Helpers:**
    *   `_exists`
    *   `_isApprovedOrOwner`
    *   `_transfer`
    *   `_mint`
12. **Internal Chronicle Helpers:**
    *   `_updateChronicleState`
    *   `_addChronicleEntry`
    *   `_isLeapPossible` (Checks cooldown)
13. **Custom Chronicle Functions (External/Public):**
    *   `mintChronicle`
    *   `getChronicleState` (View)
    *   `getChronicleEntryCount` (View)
    *   `getChronicleEntry` (View)
    *   `performQuantumLeap`
    *   `simulateLeapOutcome` (View)
    *   `branchTimeline`
    *   `mergeTimelines`
    *   `influenceChronicle`
    *   `setChronicleMetadata`
    *   `getCurrentEpoch` (View)
    *   `getLastLeapTimestamp` (View)
    *   `isTimelineActive` (View)
    *   `retireChronicle`
    *   `setLeapCooldown`
    *   `getTimeUntilNextLeap` (View)
    *   `getTotalChroniclesMinted` (View)
    *   `canPerformAction` (View - Simulates access check)

**Function Summary:**

*   `supportsInterface(bytes4 interfaceId)`: Standard ERC165 function.
*   `balanceOf(address owner)`: Returns the number of tokens owned by `owner`.
*   `ownerOf(uint256 tokenId)`: Returns the owner of the `tokenId`.
*   `approve(address to, uint256 tokenId)`: Approves `to` to manage `tokenId`.
*   `getApproved(uint256 tokenId)`: Returns the approved address for `tokenId`.
*   `setApprovalForAll(address operator, bool approved)`: Sets operator approval for all tokens of `msg.sender`.
*   `isApprovedForAll(address owner, address operator)`: Checks if `operator` is approved for all tokens of `owner`.
*   `transferFrom(address from, address to, uint256 tokenId)`: Transfers `tokenId` from `from` to `to`.
*   `safeTransferFrom(address from, address to, uint256 tokenId)`: Safer transfer calling `onERC721Received`.
*   `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: Safer transfer calling `onERC721Received` with data.
*   `mintChronicle(address recipient, bytes32 initialMetadata)`: Creates a new Chronicle token for `recipient` with initial data. Increments token count.
*   `getChronicleState(uint256 tokenId)`: Returns the current `ChronicleState` struct for `tokenId`.
*   `getChronicleEntryCount(uint256 tokenId)`: Returns the number of history entries for `tokenId`.
*   `getChronicleEntry(uint256 tokenId, uint256 index)`: Returns a specific `ChronicleEntry` from the history of `tokenId`.
*   `performQuantumLeap(uint256 tokenId, bytes32 leapData)`: Executes a state transition (leap) for `tokenId`. Updates state, increments epoch, records entry, applies cooldown. Requires ownership/approval and cooldown check.
*   `simulateLeapOutcome(uint256 tokenId, bytes32 potentialLeapData)`: A view function that calculates and returns the *potential* `ChronicleState` if a `performQuantumLeap` with `potentialLeapData` were executed, without changing storage.
*   `branchTimeline(uint256 tokenId, address newOwner, bytes32 branchMetadata)`: Creates a *new* Chronicle token based on the current state of `tokenId`. The new token is minted to `newOwner`, and both tokens record a branch entry.
*   `mergeTimelines(uint256 tokenId1, uint256 tokenId2, bytes32 mergeData)`: Updates the state of `tokenId1` based on combined factors from `tokenId1`, `tokenId2`, and `mergeData`. Records merge entries in both histories. `tokenId2` remains owned by its owner but can be marked inactive via `retireChronicle`. Requires ownership/approval for both tokens.
*   `influenceChronicle(uint256 tokenId, bytes32 influenceData)`: Applies an "external influence" to the state of `tokenId`. Updates state, records entry. Might have different rules than `performQuantumLeap` (e.g., no cooldown). Requires ownership/approval.
*   `setChronicleMetadata(uint256 tokenId, bytes32 newMetadata)`: Updates the generic metadata hash in the `ChronicleState`. Requires ownership/approval.
*   `getCurrentEpoch(uint256 tokenId)`: Returns the current epoch of the Chronicle.
*   `getLastLeapTimestamp(uint256 tokenId)`: Returns the timestamp of the last leap for the Chronicle.
*   `isTimelineActive(uint256 tokenId)`: Checks if the Chronicle is currently marked as active.
*   `retireChronicle(uint256 tokenId)`: Marks a Chronicle as inactive. Records a history entry. Requires ownership/approval. Inactive tokens cannot perform leaps, branches, influences.
*   `setLeapCooldown(uint256 tokenId, uint64 cooldownDuration)`: Sets the duration of the cooldown period required between `performQuantumLeap` calls for `tokenId`. Requires ownership/approval.
*   `getTimeUntilNextLeap(uint256 tokenId)`: Calculates the remaining time in seconds until `performQuantumLeap` is possible again for `tokenId`, considering the last leap timestamp and cooldown. Returns 0 if no cooldown is set or cooldown has passed.
*   `getTotalChroniclesMinted()`: Returns the total number of Chronicle tokens ever minted.
*   `canPerformAction(uint256 tokenId, address user, bytes4 actionSelector)`: A complex view function. Checks if `user` is permitted to perform the action represented by `actionSelector` (e.g., `performQuantumLeap`, `branchTimeline`) on `tokenId`, considering ownership, approval, active status, and specific action cooldowns (like the leap cooldown). This function simulates access logic without executing the action.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- INTERFACES ---

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    /// uses less than 30,000 gas and MUST return a boolean.
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    /// This event emits when NFTs are created (`from` and `to` are non-zero) and destroyed
    /// (`from` and `to` are zero). Exception: initializing an NFT contract is not considered a transfer.
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /// @dev This emits when the approved address for an NFT is changed or reaffirmed. The zero address indicates there is no approved address.
    /// When a Transfer event is emitted, this also indicates that the approved address for that NFT (if any) is reset to none.
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner. The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /// @notice Returns the number of NFTs owned by `owner` or 0 if the owner is the zero address.
    function balanceOf(address owner) external view returns (uint256 balance);

    /// @notice Returns the owner of the NFT specified by `tokenId`.
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /// @notice Transfers the ownership of an NFT from one address to another address.
    /// @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved address for this NFT.
    /// Throws if `from` is not the current owner.
    /// Throws if `to` is the zero address.
    /// Throws if `tokenId` is not a valid NFT.
    function transferFrom(address from, address to, uint256 tokenId) external;

    /// @notice Transfers the ownership of an NFT from one address to another address.
    /// @dev This implements the safe transfer mechanism (ERC721 standard, see https://eips.ethereum.org/EIPS/eip-721).
    /// Throws unless `msg.sender` is the current owner, an authorized operator, or the approved address for this NFT.
    /// Throws if `from` is not the current owner.
    /// Throws if `to` is the zero address.
    /// Throws if `tokenId` is not a valid NFT.
    /// If `to` is a smart contract, it calls `onERC721Received` on `to` and throws if the return value is not `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /// @notice Transfers the ownership of an NFT from one address to another address.
    /// @dev This implements the same safe transfer mechanism as `safeTransferFrom(address, address, uint256)` with additional data.
    /// Throws unless `msg.sender` is the current owner, an authorized operator, or the approved address for this NFT.
    /// Throws if `from` is not the current owner.
    /// Throws if `to` is the zero address.
    /// Throws if `tokenId` is not a valid NFT.
    /// If `to` is a smart contract, it calls `onERC721Received` on `to` and throws if the return value is not `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /// @notice Approves `to` to operate on `tokenId`
    /// @dev The zero address indicates there is no approved address.
    /// Throws unless `msg.sender` is the current NFT owner, or an authorized operator.
    /// Throws if `tokenId` is not a valid NFT.
    function approve(address to, uint256 tokenId) external;

    /// @notice Sets or unsets the approval for an operator to manage all of `msg.sender`'s NFTs.
    /// @param operator The address to give or revoke approval to.
    /// @param approved True to approve, false to revoke.
    /// Throws if `operator` is the `msg.sender`.
    function setApprovalForAll(address operator, bool approved) external;

    /// @notice Tells whether `operator` is an approved operator for `owner`.
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC721Receiver {
    /// @notice Handles the receipt of an NFT sent to this contract
    /// @dev The ERC721 smart contract calls this function on the recipient after a `safeTransferFrom`. This function MUST return the function selector,
    /// `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`, if the transfer is to be accepted. If the contract does not implement this function,
    /// or if the return value is different, the transfer is reverted. The selector can be obtained using `this.onERC721Received.selector`.
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// --- ERRORS ---

error TokenDoesNotExist(uint256 tokenId);
error NotApprovedOrOwner();
error TransferToZeroAddress();
error InvalidIndex(uint256 index, uint256 count);
error CooldownNotElapsed(uint64 timeRemaining);
error TimelineAlreadyInactive(uint256 tokenId);
error TimelineAlreadyActive(uint256 tokenId); // Maybe not needed, but good to have
error CannotMergeOwnTimeline();
error NotApprovedOrOwnerForBoth();
error ERC721ReceiveInvalid();


// --- EVENTS ---

event ChronicleMinted(uint256 indexed tokenId, address indexed owner, bytes32 initialMetadata);
event QuantumLeapPerformed(uint256 indexed tokenId, address indexed performer, uint64 newEpoch, bytes32 leapData);
event TimelineBranched(uint256 indexed sourceTokenId, uint256 indexed newTokenId, address indexed newOwner, bytes32 branchMetadata);
event TimelinesMerged(uint256 indexed primaryTokenId, uint256 indexed secondaryTokenId, address indexed performer, bytes32 mergeData);
event ChronicleInfluenced(uint256 indexed tokenId, address indexed influencer, bytes32 influenceData);
event ChronicleMetadataUpdated(uint256 indexed tokenId, bytes32 newMetadata);
event ChronicleRetired(uint256 indexed tokenId, address indexed retirer);
event LeapCooldownSet(uint256 indexed tokenId, uint64 duration);


// --- CONTRACT ---

contract QuantumLeapChronicles is IERC721, IERC165 {

    // --- STRUCTS ---

    enum ChronicleEventType {
        Mint,
        QuantumLeap,
        BranchSource, // This chronicle was the source of a branch
        BranchNew,    // This chronicle is a new branch from a source
        MergePrimary, // This chronicle was the primary in a merge
        MergeSecondary, // This chronicle was the secondary in a merge
        ExternalInfluence,
        MetadataUpdate,
        Retire
    }

    struct ChronicleState {
        uint64 currentEpoch; // Represents progress through dimensions/epochs
        bytes32 currentStateHash; // A hash representing the state configuration
        uint66 creationTimestamp; // When the chronicle was minted
        uint66 lastLeapTimestamp; // When the last quantum leap occurred
        bytes32 metadataHash; // Arbitrary metadata specific to this state/chronicle
        uint64 leapCooldownDuration; // Specific cooldown for this token's leaps
        bool isActive; // Can this chronicle still perform leaps/branches etc.
    }

    struct ChronicleEntry {
        uint64 epoch; // The epoch at the time of the event
        uint66 timestamp; // When the event occurred
        ChronicleEventType eventType;
        bytes32 dataHash; // Hash relevant to the event (e.g., state hash, merge data hash)
        uint256 relatedTokenId; // If event involves another token (branch, merge)
    }


    // --- STATE VARIABLES ---

    // ERC721 State
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    uint256 private _nextTokenId; // Counter for minting new tokens

    // Chronicle State & History
    mapping(uint256 => ChronicleState) private _chronicles;
    mapping(uint256 => ChronicleEntry[]) private _chronicleHistory;

    // ERC165 support
    mapping(bytes4 => bool) private _supportedInterfaces;


    // --- CONSTRUCTOR ---

    constructor() {
        // Register ERC165 interface
        _supportedInterfaces[type(IERC165).interfaceId] = true;
        // Register ERC721 interface
        _supportedInterfaces[type(IERC721).interfaceId] = true;
        // Note: We don't inherit from Ownable for this example to keep it focused on the custom logic,
        // access control relies on ERC721 ownership/approval.
    }

    // --- ERC165 ---

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    // --- ERC721 IMPLEMENTATION ---

    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) revert TransferToZeroAddress(); // Standard check for ERC721
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert TokenDoesNotExist(tokenId);
        return owner;
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ownerOf(tokenId); // Will revert if token doesn't exist
        return (spender == owner ||
                getApproved(tokenId) == spender ||
                isApprovedForAll(owner, spender));
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId); // Will revert if token doesn't exist
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) {
            revert NotApprovedOrOwner();
        }
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == msg.sender) revert NotApprovedOrOwner(); // Cannot approve self as operator
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        if (ownerOf(tokenId) != from) revert NotApprovedOrOwner(); // Check ownership
        if (to == address(0)) revert TransferToZeroAddress(); // Cannot transfer to zero address

        // Clear approvals from the previous owner
        _tokenApprovals[tokenId] = address(0);

        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert NotApprovedOrOwner();
        }
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public virtual override {
         if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert NotApprovedOrOwner();
        }
        _transfer(from, to, tokenId);

        // ERC721Receiver check
        if (to.code.length > 0) {
            bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data);
             if (retval != IERC721Receiver.onERC721Received.selector) {
                revert ERC721ReceiveInvalid();
            }
        }
    }

     function _mint(address to, uint256 tokenId) internal virtual {
        if (to == address(0)) revert TransferToZeroAddress();
        // Do not allow overwriting existing token (this check isn't strictly needed
        // with _nextTokenId logic but is good practice for a generic _mint)
        // if (_exists(tokenId)) revert TokenAlreadyExists(tokenId);

        _balances[to]++;
        _owners[tokenId] = to; // Note: Sets owner first, before emitting event per standard

        emit Transfer(address(0), to, tokenId);
    }


    // --- INTERNAL CHRONICLE HELPERS ---

    /// @dev Calculates a simple state hash. Could be more complex based on actual state variables.
    function _calculateStateHash(ChronicleState storage state) internal view returns (bytes32) {
        // Example: Hash of current epoch, last leap time, and metadata
        return keccak256(abi.encodePacked(state.currentEpoch, state.lastLeapTimestamp, state.metadataHash));
    }

    /// @dev Updates the ChronicleState struct in storage and calculates/sets the new state hash.
    function _updateChronicleState(uint256 tokenId, uint64 newEpoch, uint66 lastLeapTime, bytes32 newMetadata, bool isActive) internal {
        ChronicleState storage state = _chronicles[tokenId];
        state.currentEpoch = newEpoch;
        state.lastLeapTimestamp = lastLeapTime;
        state.metadataHash = newMetadata;
        state.isActive = isActive;
        state.currentStateHash = _calculateStateHash(state);
    }

    /// @dev Adds a new entry to the Chronicle's history.
    function _addChronicleEntry(
        uint256 tokenId,
        uint64 epoch,
        uint66 timestamp,
        ChronicleEventType eventType,
        bytes32 dataHash,
        uint256 relatedTokenId
    ) internal {
        _chronicleHistory[tokenId].push(ChronicleEntry({
            epoch: epoch,
            timestamp: timestamp,
            eventType: eventType,
            dataHash: dataHash,
            relatedTokenId: relatedTokenId
        }));
    }

     /// @dev Checks if a quantum leap is possible based on the token's specific cooldown.
    function _isLeapPossible(uint256 tokenId) internal view returns (bool) {
        ChronicleState storage state = _chronicles[tokenId];
        // If duration is 0, there's no cooldown
        if (state.leapCooldownDuration == 0) {
            return true;
        }
        // Cooldown starts *after* the last leap timestamp
        return uint66(block.timestamp) >= state.lastLeapTimestamp + state.leapCooldownDuration;
    }


    // --- CUSTOM CHRONICLE FUNCTIONS (EXTERNAL/PUBLIC) ---

    /// @notice Mints a new Quantum Leap Chronicle token.
    /// @param recipient The address to mint the token to.
    /// @param initialMetadata Initial metadata hash for the chronicle.
    /// @return The ID of the newly minted token.
    function mintChronicle(address recipient, bytes32 initialMetadata) external returns (uint256) {
        uint256 newTokenId = _nextTokenId++;
        _mint(recipient, newTokenId);

        ChronicleState storage state = _chronicles[newTokenId];
        state.currentEpoch = 0; // Start at epoch 0
        state.creationTimestamp = uint66(block.timestamp);
        state.lastLeapTimestamp = uint66(block.timestamp); // Initial leap timestamp is creation time
        state.metadataHash = initialMetadata;
        state.leapCooldownDuration = 0; // Default no cooldown
        state.isActive = true; // Start active

        // Calculate initial state hash
        state.currentStateHash = _calculateStateHash(state);

        // Add initial history entry
        _addChronicleEntry(
            newTokenId,
            state.currentEpoch,
            uint66(block.timestamp),
            ChronicleEventType.Mint,
            state.currentStateHash,
            0 // No related token
        );

        emit ChronicleMinted(newTokenId, recipient, initialMetadata);
        return newTokenId;
    }

    /// @notice Retrieves the current state of a Chronicle token.
    /// @param tokenId The ID of the token.
    /// @return The ChronicleState struct.
    function getChronicleState(uint256 tokenId) public view returns (ChronicleState memory) {
         if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
         return _chronicles[tokenId];
    }

    /// @notice Gets the number of history entries for a Chronicle.
    /// @param tokenId The ID of the token.
    /// @return The number of entries.
    function getChronicleEntryCount(uint256 tokenId) public view returns (uint256) {
         if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
         return _chronicleHistory[tokenId].length;
    }

    /// @notice Retrieves a specific history entry for a Chronicle.
    /// @param tokenId The ID of the token.
    /// @param index The index of the entry in the history array.
    /// @return The ChronicleEntry struct.
    function getChronicleEntry(uint256 tokenId, uint256 index) public view returns (ChronicleEntry memory) {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
        if (index >= _chronicleHistory[tokenId].length) revert InvalidIndex(index, _chronicleHistory[tokenId].length);
        return _chronicleHistory[tokenId][index];
    }

    /// @notice Performs a "Quantum Leap", advancing the state of a Chronicle.
    /// @dev This is the primary state transition function. Subject to cooldown.
    /// @param tokenId The ID of the token.
    /// @param leapData Data influencing the leap outcome (e.g., random seed, user input hash).
    function performQuantumLeap(uint256 tokenId, bytes32 leapData) public {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert NotApprovedOrOwner();
        ChronicleState storage state = _chronicles[tokenId];
        if (!state.isActive) revert TimelineAlreadyInactive(tokenId);
        if (!_isLeapPossible(tokenId)) revert CooldownNotElapsed(getTimeUntilNextLeap(tokenId));

        // --- State Transition Logic (Placeholder) ---
        // This is where the "magic" happens. How leapData affects the state
        // depends on the specific game/application rules.
        // Example: Increment epoch, mix leapData into new metadata, maybe change cooldown.
        uint64 newEpoch = state.currentEpoch + 1;
        bytes32 newMetadata = keccak256(abi.encodePacked(state.metadataHash, leapData, block.timestamp, newEpoch));
        // Maybe influence cooldown randomly or based on leapData?
        // uint64 newCooldown = state.leapCooldownDuration; // Or calculate a new one...
        // --- End State Transition Logic ---

        uint66 currentTimestamp = uint66(block.timestamp);
        _updateChronicleState(tokenId, newEpoch, currentTimestamp, newMetadata, state.isActive); // Keep active status
        _addChronicleEntry(
            tokenId,
            newEpoch,
            currentTimestamp,
            ChronicleEventType.QuantumLeap,
            keccak256(abi.encodePacked(leapData)), // Hash the input data for history
            0
        );

        emit QuantumLeapPerformed(tokenId, msg.sender, newEpoch, leapData);
    }

    /// @notice Simulates the outcome of a Quantum Leap without changing the state.
    /// @dev Allows users to see potential future states based on hypothetical leap data.
    /// @param tokenId The ID of the token.
    /// @param potentialLeapData Hypothetical data for the leap.
    /// @return The potential ChronicleState struct after the simulated leap.
    function simulateLeapOutcome(uint256 tokenId, bytes32 potentialLeapData) public view returns (ChronicleState memory) {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
        ChronicleState memory currentState = _chronicles[tokenId]; // Work on memory copy

        // --- Simulated State Transition Logic (Must match performQuantumLeap logic) ---
        // This logic needs to be a pure function or use only view-accessible state/inputs.
        // Example: Predict the next epoch and metadata hash.
        uint64 potentialNewEpoch = currentState.currentEpoch + 1;
        bytes32 potentialNewMetadata = keccak256(abi.encodePacked(currentState.metadataHash, potentialLeapData, block.timestamp, potentialNewEpoch)); // Use current block.timestamp for simulation context
        // Cooldown doesn't change *before* the leap, only *as a result* of it.
        // If cooldown can change *during* the leap, simulate that too.
        // For simplicity here, we won't simulate cooldown change in this view function.
        // --- End Simulated State Transition Logic ---

        ChronicleState memory simulatedState = currentState; // Copy current state
        simulatedState.currentEpoch = potentialNewEpoch;
        simulatedState.lastLeapTimestamp = uint66(block.timestamp); // Simulate as if it happened now
        simulatedState.metadataHash = potentialNewMetadata;
        // Recalculate state hash for the simulated state
        simulatedState.currentStateHash = keccak256(abi.encodePacked(simulatedState.currentEpoch, simulatedState.lastLeapTimestamp, simulatedState.metadataHash));

        return simulatedState;
    }

    /// @notice Creates a new Chronicle token (a "branch") from an existing one.
    /// @param sourceTokenId The ID of the token to branch from.
    /// @param newOwner The address to mint the new branch token to.
    /// @param branchMetadata Initial metadata specific to this branch.
    /// @return The ID of the newly created branch token.
    function branchTimeline(uint256 sourceTokenId, address newOwner, bytes32 branchMetadata) public returns (uint256) {
        if (!_isApprovedOrOwner(msg.sender, sourceTokenId)) revert NotApprovedOrOwner();
        ChronicleState storage sourceState = _chronicles[sourceTokenId];
        if (!sourceState.isActive) revert TimelineAlreadyInactive(sourceTokenId);
        if (newOwner == address(0)) revert TransferToZeroAddress();

        uint256 newChronicleId = _nextTokenId++;
        _mint(newOwner, newChronicleId);

        // Initialize new branch state based on source state at the time of branching
        ChronicleState storage newChronicleState = _chronicles[newChronicleId];
        newChronicleState.currentEpoch = sourceState.currentEpoch; // Branch starts at source's epoch
        newChronicleState.creationTimestamp = uint66(block.timestamp);
        newChronicleState.lastLeapTimestamp = uint66(block.timestamp); // New timeline starts fresh on leap cooldown
        newChronicleState.metadataHash = branchMetadata; // Use branch-specific metadata
        newChronicleState.leapCooldownDuration = sourceState.leapCooldownDuration; // Inherit source cooldown? Or set default/new? Let's inherit.
        newChronicleState.isActive = true; // New branch is active

        // Calculate initial state hash for the new branch
        newChronicleState.currentStateHash = _calculateStateHash(newChronicleState);

        uint66 currentTimestamp = uint66(block.timestamp);

        // Add history entry to the NEW branch
        _addChronicleEntry(
            newChronicleId,
            newChronicleState.currentEpoch,
            currentTimestamp,
            ChronicleEventType.BranchNew,
            newChronicleState.currentStateHash,
            sourceTokenId // Link back to the source
        );

        // Add history entry to the SOURCE chronicle
        _addChronicleEntry(
            sourceTokenId,
            sourceState.currentEpoch,
            currentTimestamp,
            ChronicleEventType.BranchSource,
            sourceState.currentStateHash,
            newChronicleId // Link to the new branch
        );

        emit TimelineBranched(sourceTokenId, newChronicleId, newOwner, branchMetadata);
        return newChronicleId;
    }

    /// @notice Merges two Chronicle timelines. The primary chronicle's state is updated, and both record the merge event.
    /// @dev Requires ownership/approval of *both* tokens by msg.sender.
    /// @param primaryTokenId The token ID whose state will be updated.
    /// @param secondaryTokenId The token ID contributing state factors to the merge.
    /// @param mergeData Data influencing the merge outcome.
    function mergeTimelines(uint256 primaryTokenId, uint256 secondaryTokenId, bytes32 mergeData) public {
        if (primaryTokenId == secondaryTokenId) revert CannotMergeOwnTimeline();
        if (!_isApprovedOrOwner(msg.sender, primaryTokenId)) revert NotApprovedOrOwnerForBoth(); // Simplified check, could check both individually
        if (!_isApprovedOrOwner(msg.sender, secondaryTokenId)) revert NotApprovedOrOwnerForBoth();

        ChronicleState storage primaryState = _chronicles[primaryTokenId];
        ChronicleState storage secondaryState = _chronicles[secondaryTokenId];

        if (!primaryState.isActive) revert TimelineAlreadyInactive(primaryTokenId);
        if (!secondaryState.isActive) revert TimelineAlreadyInactive(secondaryTokenId);

        // --- Merge State Transition Logic (Placeholder) ---
        // How do the states merge? This is highly application-specific.
        // Example: Primary epoch increases, metadata is a hash of both metadata and mergeData.
        uint64 newPrimaryEpoch = primaryState.currentEpoch + 1; // Merge advances primary epoch
        bytes32 newPrimaryMetadata = keccak256(abi.encodePacked(primaryState.metadataHash, secondaryState.metadataHash, mergeData, block.timestamp));
        // Cooldown might be reset or inherited based on some rule
        uint64 newPrimaryCooldown = primaryState.leapCooldownDuration; // Keep primary cooldown
        // --- End Merge State Transition Logic ---

        uint66 currentTimestamp = uint66(block.timestamp);

        // Update primary chronicle's state
        _updateChronicleState(
            primaryTokenId,
            newPrimaryEpoch,
            primaryState.lastLeapTimestamp, // Merge doesn't reset leap cooldown? Or does it? Depends on logic. Let's not reset it.
            newPrimaryMetadata,
            primaryState.isActive
        );

        // Add history entry to the PRIMARY chronicle
        _addChronicleEntry(
            primaryTokenId,
            newPrimaryEpoch, // Record epoch *after* merge
            currentTimestamp,
            ChronicleEventType.MergePrimary,
            keccak256(abi.encodePacked(mergeData)), // Hash the merge input data
            secondaryTokenId // Link to the secondary
        );

        // Add history entry to the SECONDARY chronicle
        _addChronicleEntry(
            secondaryTokenId,
            secondaryState.currentEpoch, // Record epoch *before* merge (or current)
            currentTimestamp,
            ChronicleEventType.MergeSecondary,
             keccak256(abi.encodePacked(mergeData)), // Hash the merge input data
            primaryTokenId // Link to the primary
        );

        emit TimelinesMerged(primaryTokenId, secondaryTokenId, msg.sender, mergeData);

        // Note: The secondary token is NOT burned or transferred here. It remains owned.
        // It could optionally be marked inactive using `retireChronicle`.
    }

    /// @notice Applies an "external influence" to a Chronicle's state.
    /// @dev This function might have different rules or effects than a Quantum Leap.
    /// @param tokenId The ID of the token.
    /// @param influenceData Data representing the external influence.
    function influenceChronicle(uint256 tokenId, bytes32 influenceData) public {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert NotApprovedOrOwner();
         ChronicleState storage state = _chronicles[tokenId];
        if (!state.isActive) revert TimelineAlreadyInactive(tokenId);

        // --- Influence State Transition Logic (Placeholder) ---
        // Example: Metadata changes, epoch doesn't necessarily increase, no cooldown check.
        bytes32 newMetadata = keccak256(abi.encodePacked(state.metadataHash, influenceData, block.timestamp));
        uint64 currentEpoch = state.currentEpoch; // Influence might not change epoch
        uint66 lastLeapTimestamp = state.lastLeapTimestamp; // Influence doesn't count as a leap

        // --- End Influence State Transition Logic ---

        uint66 currentTimestamp = uint66(block.timestamp);
         _updateChronicleState(tokenId, currentEpoch, lastLeapTimestamp, newMetadata, state.isActive); // Keep state data

        _addChronicleEntry(
            tokenId,
            currentEpoch,
            currentTimestamp,
            ChronicleEventType.ExternalInfluence,
            keccak256(abi.encodePacked(influenceData)), // Hash influence data
            0
        );

        emit ChronicleInfluenced(tokenId, msg.sender, influenceData);
    }

    /// @notice Updates the arbitrary metadata hash for a Chronicle.
    /// @param tokenId The ID of the token.
    /// @param newMetadata The new metadata hash.
    function setChronicleMetadata(uint256 tokenId, bytes32 newMetadata) public {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert NotApprovedOrOwner();
        ChronicleState storage state = _chronicles[tokenId];
        if (!state.isActive) revert TimelineAlreadyInactive(tokenId);

        bytes32 oldMetadata = state.metadataHash;
        state.metadataHash = newMetadata;
        // Recalculate state hash if metadata is part of it
        state.currentStateHash = _calculateStateHash(state);

        uint66 currentTimestamp = uint66(block.timestamp);
        _addChronicleEntry(
            tokenId,
            state.currentEpoch,
            currentTimestamp,
            ChronicleEventType.MetadataUpdate,
            newMetadata, // Store the new metadata hash
            0
        );

        emit ChronicleMetadataUpdated(tokenId, newMetadata);
    }

    /// @notice Gets the current epoch of a Chronicle.
    /// @param tokenId The ID of the token.
    /// @return The current epoch.
    function getCurrentEpoch(uint256 tokenId) public view returns (uint64) {
         if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
         return _chronicles[tokenId].currentEpoch;
    }

    /// @notice Gets the timestamp of the last quantum leap for a Chronicle.
    /// @param tokenId The ID of the token.
    /// @return The timestamp.
    function getLastLeapTimestamp(uint256 tokenId) public view returns (uint66) {
         if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
         return _chronicles[tokenId].lastLeapTimestamp;
    }

    /// @notice Checks if a Chronicle is currently active.
    /// @param tokenId The ID of the token.
    /// @return True if active, false otherwise.
    function isTimelineActive(uint256 tokenId) public view returns (bool) {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
        return _chronicles[tokenId].isActive;
    }

    /// @notice Marks a Chronicle as inactive. It can no longer perform main actions like Leap or Branch.
    /// @param tokenId The ID of the token to retire.
    function retireChronicle(uint256 tokenId) public {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert NotApprovedOrOwner();
        ChronicleState storage state = _chronicles[tokenId];
        if (!state.isActive) revert TimelineAlreadyInactive(tokenId); // Already inactive

        state.isActive = false; // Mark as inactive
        // Update state hash if active status is part of it? Let's say it's not.

        uint66 currentTimestamp = uint66(block.timestamp);
        _addChronicleEntry(
            tokenId,
            state.currentEpoch,
            currentTimestamp,
            ChronicleEventType.Retire,
            state.currentStateHash, // Record state hash at retirement
            0
        );

        emit ChronicleRetired(tokenId, msg.sender);
    }

    /// @notice Sets the cooldown duration for performing Quantum Leaps on a specific Chronicle.
    /// @param tokenId The ID of the token.
    /// @param cooldownDuration The duration in seconds (0 for no cooldown).
    function setLeapCooldown(uint256 tokenId, uint64 cooldownDuration) public {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert NotApprovedOrOwner();
        ChronicleState storage state = _chronicles[tokenId];
        state.leapCooldownDuration = cooldownDuration;

        emit LeapCooldownSet(tokenId, cooldownDuration);
    }

    /// @notice Calculates the remaining time in seconds until a Quantum Leap is possible.
    /// @param tokenId The ID of the token.
    /// @return The remaining time in seconds. Returns 0 if cooldown is 0 or has elapsed.
    function getTimeUntilNextLeap(uint256 tokenId) public view returns (uint64) {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
        ChronicleState storage state = _chronicles[tokenId];
        if (state.leapCooldownDuration == 0) {
            return 0; // No cooldown set
        }
        uint256 nextLeapTime = uint256(state.lastLeapTimestamp) + state.leapCooldownDuration;
        if (block.timestamp >= nextLeapTime) {
            return 0; // Cooldown has elapsed
        }
        return uint64(nextLeapTime - block.timestamp);
    }

     /// @notice Returns the total number of Chronicle tokens ever minted.
    /// @return The total count.
    function getTotalChroniclesMinted() public view returns (uint256) {
        return _nextTokenId;
    }

    /// @notice Simulates whether a user *can* perform a specific action on a Chronicle.
    /// @dev This is a complex view function checking ownership/approval, active status, and action-specific rules (like cooldown).
    /// @param tokenId The ID of the token.
    /// @param user The address attempting the action.
    /// @param actionSelector The function selector of the action being checked (e.g., `this.performQuantumLeap.selector`).
    /// @return True if the user can perform the action, false otherwise.
    function canPerformAction(uint256 tokenId, address user, bytes4 actionSelector) public view returns (bool) {
        if (!_exists(tokenId)) return false; // Token doesn't exist

        // Basic ownership/approval check
        if (!_isApprovedOrOwner(user, tokenId)) return false;

        ChronicleState storage state = _chronicles[tokenId];

        // Check if timeline is active for most actions
        if (!state.isActive) {
            // Special case: retireChronicle can be called on an inactive token by owner/approved
            if (actionSelector == this.retireChronicle.selector) {
                 return _isApprovedOrOwner(user, tokenId); // Only need ownership/approval for retire
            }
            return false; // Most actions require active timeline
        }

        // Check action-specific rules
        if (actionSelector == this.performQuantumLeap.selector) {
            // Requires active timeline AND cooldown elapsed
            return _isLeapPossible(tokenId);
        }

        if (actionSelector == this.branchTimeline.selector || actionSelector == this.influenceChronicle.selector || actionSelector == this.setChronicleMetadata.selector || actionSelector == this.setLeapCooldown.selector) {
             // These require active timeline and ownership/approval (already checked)
             return true;
        }

        // Handle actions involving multiple tokens separately if needed (e.g. mergeTimelines would need checks on *both* tokens)
        // For this generic function, we only check the primary token.
        // A full multi-token check would require passing all relevant token IDs.

        // If the action is not recognized or doesn't have specific checks here
        return false;
    }
}
```