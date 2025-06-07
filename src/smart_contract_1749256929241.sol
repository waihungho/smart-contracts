Okay, here is a smart contract concept based on "Quantum Entanglement Keys". This contract manages unique pairs of digital assets (Keys) that are conceptually linked or "entangled". Actions on one key can potentially affect its paired counterpart, reflecting a simplified, blockchain-based interpretation of quantum entanglement principles.

This concept goes beyond typical NFTs by focusing on the relationship and interaction *between* paired tokens, including states like "decoherence" and "observation". It's creative and uses slightly more complex state management and interaction logic than a standard token contract.

---

**Smart Contract: QuantumEntanglementKeys**

**Concept:** Manages unique pairs of digital assets ("Keys") linked by a simulated "quantum entanglement". Owners can interact with individual keys or their paired counterparts, with specific functions simulating entanglement effects, state observation, and potential decoherence.

**Outline:**

1.  **License & Pragma**
2.  **Imports** (Using OpenZeppelin for roles and utility)
3.  **Error Definitions**
4.  **Events** (Signaling key actions, transfers, entanglement changes)
5.  **State Variables** (Mapping key IDs to owners, pairs, states, roles, counters)
6.  **Roles** (Creator, Observer)
7.  **Modifiers** (Access control)
8.  **Constructor** (Initialize owner, setup roles)
9.  **Core Management Functions** (Getters for key/pair info)
10. **Creation Function** (Minting entangled pairs)
11. **Ownership & Transfer Functions** (Handling individual keys and pairs)
12. **Entanglement Interaction Functions** (Simulating entanglement effects, breaking/repairing links, observation)
13. **State & Data Management Functions** (Attaching data, updating states)
14. **Role Management Functions** (Granting/revoking Creator/Observer roles)
15. **Utility Functions** (Listing keys/pairs by owner)

**Function Summary:**

1.  `constructor()`: Initializes the contract owner and sets the deploying address as the initial creator.
2.  `createEntangledPair()`: Mints a new pair of entangled keys (Key A and Key B) and assigns ownership of both to the caller. Increments total supply and pair counter.
3.  `transferKey(address to, uint256 keyId)`: Transfers ownership of a single key (`keyId`) to the `to` address. Emits `Transfer` event. Checks ownership and approvals.
4.  `transferPair(address to, uint256 pairId)`: Transfers ownership of *both* keys belonging to `pairId` to the `to` address. Fails if keys are owned by different addresses.
5.  `safeTransferKey(address from, address to, uint256 keyId)`: Safer transfer function checking if `to` is a smart contract capable of receiving NFTs.
6.  `safeTransferPair(address from, address to, uint256 pairId)`: Safer transfer for pairs.
7.  `approve(address to, uint256 keyId)`: Grants approval for `to` to transfer a specific key.
8.  `setApprovalForAll(address operator, bool approved)`: Grants/revokes approval for `operator` to manage all caller's keys.
9.  `getApproved(uint256 keyId)`: Returns the address approved to transfer a specific key.
10. `isApprovedForAll(address owner, address operator)`: Checks if `operator` is approved for all of `owner`'s keys.
11. `balanceOf(address owner)`: Returns the total number of *individual* keys owned by an address.
12. `ownerOf(uint256 keyId)`: Returns the owner of a specific key.
13. `getKeyInfo(uint256 keyId)`: Returns detailed information about a single key, including its owner, pair ID, type (A/B), and current state.
14. `getPairInfo(uint256 pairId)`: Returns information about an entangled pair, including the IDs of Key A and Key B, their owners, and the pair's current entanglement state.
15. `getPairedKeyId(uint256 keyId)`: Returns the ID of the key entangled with `keyId`.
16. `getPairIdOfKey(uint256 keyId)`: Returns the pair ID to which `keyId` belongs.
17. `initiateEntanglementPulse(uint256 keyId)`: Simulates sending a "pulse" through a key. This can only be done by the key's owner and only if the pair is `Entangled`. It updates the state of *both* keys in the pair.
18. `decayEntanglementState(uint256 pairId)`: Allows the owner of *both* keys in a pair (or potentially a role) to transition the pair's state from `Entangled` towards `Decohered`. This might happen passively or actively. Requires both keys to be owned by the caller.
19. `observePairedState(uint256 pairId, uint256 keyIdTrigger)`: Simulates the act of "observing" one key (`keyIdTrigger`), potentially collapsing or revealing shared state in its paired key. This function might have preconditions related to key ownership or roles (e.g., requiring both owners to consent, or callable by an Observer role). Can only be called on an `Entangled` pair.
20. `breakEntanglement(uint256 pairId)`: Permanently breaks the link between Key A and Key B of a pair, setting the state to `Broken`. Requires the owner of both keys in the pair. Broken pairs cannot use entanglement functions.
21. `attemptRepairEntanglement(uint256 pairId)`: An attempt to restore entanglement for a `Decohered` or `Broken` pair. This could have complex conditions or require burning a resource (not implemented, but designed as a concept). Currently just transitions from `Decohered` to `Entangled` if both owned by caller.
22. `attachSecretHash(uint256 keyId, bytes32 secretHash)`: Allows the owner of a key to attach a cryptographic hash representing a private secret associated with that key.
23. `revealSecretHash(uint256 keyId)`: Allows the owner of a key to retrieve the previously attached secret hash. Note: This only reveals the hash, not the secret itself.
24. `verifyPairedSecretMatch(uint256 pairId, bytes32 hashA, bytes32 hashB)`: Allows the owner of *both* keys in a pair (or a role) to verify if supplied hashes (`hashA`, `hashB`) match the hashes attached to Key A and Key B of that pair, *without revealing the stored hashes*. Requires both keys to have attached hashes.
25. `updateKeyMetadata(uint256 keyId, string memory metadataURI)`: Allows the owner to update the metadata URI for a single key.
26. `updatePairMetadata(uint256 pairId, string memory metadataURI)`: Allows the owner of both keys in a pair to update metadata for the pair (can override individual key metadata).
27. `grantCreatorRole(address account)`: Grants the CREATOR_ROLE, allowing the account to mint new pairs. (Owner function)
28. `revokeCreatorRole(address account)`: Revokes the CREATOR_ROLE. (Owner function)
29. `grantObserverRole(address account)`: Grants the OBSERVER_ROLE, potentially allowing observation functions under specific conditions. (Owner function)
30. `revokeObserverRole(address account)`: Revokes the OBSERVER_ROLE. (Owner function)
31. `isCreator(address account)`: Checks if an account has the CREATOR_ROLE.
32. `isObserver(address account)`: Checks if an account has the OBSERVER_ROLE.
33. `getKeysOwnedBy(address owner)`: Returns an array of all individual key IDs owned by an address. (Might be gas-intensive for large collections).
34. `getPairsOwnedBy(address owner)`: Returns an array of pair IDs where *both* keys in the pair are owned by the same address.

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol"; // Using ERC721Holder for safe transfers example

// Error Definitions
error QuantumEntanglementKeys__NotOwnerOrApproved();
error QuantumEntanglementKeys__InvalidKeyId();
error QuantumEntanglementKeys__KeyAlreadyExists(); // Should not happen with counter, but good defensive check
error QuantumEntanglementKeys__PairNotFound();
error QuantumEntanglementKeys__NotEntangled();
error QuantumEntanglementKeys__KeysSeparatelyOwned();
error QuantumEntanglementKeys__PairAlreadyBroken();
error QuantumEntanglementKeys__PairNotDecoheredOrBroken();
error QuantumEntanglementKeys__SecretHashNotAttached();
error QuantumEntanglementKeys__MismatchedKeyInPair();
error QuantumEntanglementKeys__PairRequiresBothKeysOwnedByCaller();
error QuantumEntanglementKeys__CannotTransferPairToMultipleOwners();
error QuantumEntanglementKeys__KeyHasNoPairedKey(); // Should not happen if creation works
error QuantumEntanglementKeys__PairHasNoKeys(); // Should not happen if creation works
error QuantumEntanglementKeys__NotCreator();
error QuantumEntanglementKeys__MetadataUpdateNotAllowed(); // Example for future complexity


/**
 * @title QuantumEntanglementKeys
 * @dev A creative smart contract managing paired, 'entangled' digital assets (Keys).
 *      Simulates concepts of entanglement, decoherence, and observation via contract state and functions.
 *      Each pair consists of Key A and Key B.
 *      Ownership of keys can be separate, but certain 'entanglement' functions require
 *      specific ownership configurations or roles.
 *      Not a standard ERC721, but incorporates some similar ownership/transfer concepts.
 *      Focus is on the unique pair interactions rather than standard NFT marketplace compatibility.
 */
contract QuantumEntanglementKeys is Ownable, AccessControl, ERC721Holder { // Inherit ERC721Holder for safeTransfer checks compatibility

    // --- Access Control Roles ---
    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");
    bytes32 public constant OBSERVER_ROLE = keccak256("OBSERVER_ROLE");

    // --- State Enums ---
    enum KeyType { KeyA, KeyB }
    enum PairState { Entangled, Decohered, Broken } // Simulated quantum states

    // --- State Variables ---
    using Counters for Counters.Counter;
    Counters.Counter private _keyCounter;
    Counters.Counter private _pairCounter;

    // Key Data: keyId => info
    struct Key {
        uint256 pairId;
        KeyType keyType;
        uint256 pairedKeyId; // Direct link to the paired key ID
        bytes32 secretHash; // Optional attached hash
        string metadataURI; // Individual key metadata
        // Add more key-specific state here if needed
    }
    mapping(uint256 => Key) private _keys;
    mapping(uint256 => address) private _keyOwners; // keyId => owner address
    mapping(uint256 => address) private _keyApprovals; // keyId => approved address
    mapping(address => mapping(address => bool)) private _operatorApprovals; // owner => operator => approved

    // Pair Data: pairId => info
    struct Pair {
        uint256 keyAId;
        uint256 keyBId;
        PairState state;
        uint256 lastInteractionTime; // Timestamp for decay simulation (optional)
        string metadataURI; // Pair-level metadata
        // Add more pair-specific state here if needed
    }
    mapping(uint256 => Pair) private _pairs;

    // Helper mappings for querying collections (potentially gas-intensive for large numbers)
    mapping(address => uint256[]) private _ownedKeys; // owner => list of key IDs
    mapping(uint256 => uint256) private _ownedKeysIndex; // keyId => index in owner's _ownedKeys array

    // Note: Tracking pairs owned by a single address dynamically in getPairsOwnedBy to avoid separate mapping overhead


    // --- Events ---
    event PairCreated(uint256 indexed pairId, uint256 keyAId, uint256 keyBId, address indexed owner);
    event KeyTransfer(uint256 indexed keyId, address indexed from, address indexed to);
    event PairTransfer(uint256 indexed pairId, address indexed from, address indexed to); // Both keys moved together
    event Approval(uint256 indexed keyId, address indexed owner, address indexed approved);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event EntanglementPulseInitiated(uint256 indexed pairId, uint256 indexed keyIdTrigger, address indexed caller);
    event PairStateChanged(uint256 indexed pairId, PairState newState, address indexed caller);
    event PairedStateObserved(uint256 indexed pairId, uint256 indexed keyIdTrigger, address indexed caller);
    event EntanglementBroken(uint256 indexed pairId, address indexed caller);
    event SecretHashAttached(uint256 indexed keyId, bytes32 indexed secretHash, address indexed caller);
    event KeyMetadataUpdated(uint256 indexed keyId, string metadataURI, address indexed caller);
    event PairMetadataUpdated(uint256 indexed pairId, string metadataURI, address indexed caller);


    // --- Modifiers ---
    modifier onlyKeyOwnerOrApproved(uint256 keyId) {
        require(_keyOwners[keyId] == msg.sender || _keyApprovals[keyId] == msg.sender || _operatorApprovals[_keyOwners[keyId]][msg.sender],
                "QuantumEntanglementKeys: Not owner or approved");
        _;
    }

    modifier onlyPairOwner(uint256 pairId) {
        if (_pairs[pairId].keyAId == 0) revert PairNotFound(); // Basic pair existence check
        if (_keyOwners[_pairs[pairId].keyAId] != msg.sender || _keyOwners[_pairs[pairId].keyBId] != msg.sender)
            revert PairRequiresBothKeysOwnedByCaller();
        _;
    }

    modifier onlyCreator() {
        if (!hasRole(CREATOR_ROLE, msg.sender)) revert NotCreator();
        _;
    }

    // --- Constructor ---
    constructor() Ownable(msg.sender) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Owner is also the default admin
        _grantRole(CREATOR_ROLE, msg.sender); // Owner is initial creator
        // _grantRole(OBSERVER_ROLE, msg.sender); // Uncomment if owner is initial observer
    }

    // --- Role Management Functions ---

    /**
     * @dev Grants the CREATOR_ROLE to an account, allowing them to mint new pairs.
     * @param account The address to grant the role to.
     */
    function grantCreatorRole(address account) external onlyOwner {
        _grantRole(CREATOR_ROLE, account);
    }

    /**
     * @dev Revokes the CREATOR_ROLE from an account.
     * @param account The address to revoke the role from.
     */
    function revokeCreatorRole(address account) external onlyOwner {
        _revokeRole(CREATOR_ROLE, account);
    }

    /**
     * @dev Grants the OBSERVER_ROLE to an account, potentially allowing specific observation functions.
     * @param account The address to grant the role to.
     */
    function grantObserverRole(address account) external onlyOwner {
        _grantRole(OBSERVER_ROLE, account);
    }

    /**
     * @dev Revokes the OBSERVER_ROLE from an account.
     * @param account The address to revoke the role from.
     */
    function revokeObserverRole(address account) external onlyOwner {
        _revokeRole(OBSERVER_ROLE, account);
    }

    /**
     * @dev Checks if an account has the CREATOR_ROLE.
     * @param account The address to check.
     * @return True if the account has the role, false otherwise.
     */
    function isCreator(address account) external view returns (bool) {
        return hasRole(CREATOR_ROLE, account);
    }

    /**
     * @dev Checks if an account has the OBSERVER_ROLE.
     * @param account The address to check.
     * @return True if the account has the role, false otherwise.
     */
    function isObserver(address account) external view returns (bool) {
        return hasRole(OBSERVER_ROLE, account);
    }


    // --- Core Management Getters ---

    /**
     * @dev Returns the total number of *individual* keys minted.
     */
    function totalSupplyKeys() external view returns (uint256) {
        return _keyCounter.current();
    }

    /**
     * @dev Returns the total number of entangled pairs created.
     */
    function totalPairs() external view returns (uint256) {
        return _pairCounter.current();
    }

    /**
     * @dev Returns the owner of a specific key.
     * @param keyId The ID of the key.
     * @return The owner address.
     */
    function ownerOf(uint256 keyId) public view returns (address) {
         if (_keyOwners[keyId] == address(0)) revert InvalidKeyId(); // Check existence
         return _keyOwners[keyId];
    }

     /**
     * @dev Returns the total number of *individual* keys owned by an address.
     * @param owner The address to check.
     * @return The number of keys owned.
     */
    function balanceOf(address owner) external view returns (uint256) {
        return _ownedKeys[owner].length;
    }

    /**
     * @dev Gets detailed information about a single key.
     * @param keyId The ID of the key.
     * @return keyType The type of key (KeyA or KeyB).
     * @return pairId The ID of the pair it belongs to.
     * @return pairedKeyId The ID of its entangled partner.
     * @return owner The current owner of the key.
     * @return secretHash The attached secret hash (0x0 if none).
     * @return metadataURI The individual key metadata URI.
     */
    function getKeyInfo(uint256 keyId) external view returns (
        KeyType keyType,
        uint256 pairId,
        uint256 pairedKeyId,
        address owner,
        bytes32 secretHash,
        string memory metadataURI
    ) {
        if (_keys[keyId].pairId == 0) revert InvalidKeyId(); // Check existence

        return (
            _keys[keyId].keyType,
            _keys[keyId].pairId,
            _keys[keyId].pairedKeyId,
            _keyOwners[keyId],
            _keys[keyId].secretHash,
            _keys[keyId].metadataURI
        );
    }

    /**
     * @dev Gets detailed information about an entangled pair.
     * @param pairId The ID of the pair.
     * @return keyAId The ID of Key A in the pair.
     * @return keyBId The ID of Key B in the pair.
     * @return keyAOwner The owner of Key A.
     * @return keyBOwner The owner of Key B.
     * @return state The current state of the pair (Entangled, Decohered, Broken).
     * @return metadataURI The pair-level metadata URI.
     */
    function getPairInfo(uint256 pairId) external view returns (
        uint256 keyAId,
        uint256 keyBId,
        address keyAOwner,
        address keyBOwner,
        PairState state,
        string memory metadataURI
    ) {
         if (_pairs[pairId].keyAId == 0) revert PairNotFound(); // Check existence

        return (
            _pairs[pairId].keyAId,
            _pairs[pairId].keyBId,
            _keyOwners[_pairs[pairId].keyAId],
            _keyOwners[_pairs[pairId].keyBId],
            _pairs[pairId].state,
            _pairs[pairId].metadataURI
        );
    }

     /**
     * @dev Returns the ID of the key entangled with a given key ID.
     * @param keyId The ID of one key in a pair.
     * @return The ID of its paired key.
     */
    function getPairedKeyId(uint256 keyId) public view returns (uint256) {
        if (_keys[keyId].pairId == 0) revert InvalidKeyId(); // Check existence
        if (_keys[keyId].pairedKeyId == 0) revert KeyHasNoPairedKey(); // Should not happen if created correctly
        return _keys[keyId].pairedKeyId;
    }

     /**
     * @dev Returns the pair ID to which a specific key belongs.
     * @param keyId The ID of the key.
     * @return The pair ID.
     */
    function getPairIdOfKey(uint256 keyId) public view returns (uint256) {
         if (_keys[keyId].pairId == 0) revert InvalidKeyId(); // Check existence
        return _keys[keyId].pairId;
    }

     /**
     * @dev Returns the address approved for a single key.
     * @param keyId The ID of the key.
     * @return The approved address.
     */
    function getApproved(uint256 keyId) external view returns (address) {
         if (_keyOwners[keyId] == address(0)) revert InvalidKeyId(); // Check existence
        return _keyApprovals[keyId];
    }

    /**
     * @dev Checks if an operator is approved for all keys of an owner.
     * @param owner The owner address.
     * @param operator The potential operator address.
     * @return True if approved, false otherwise.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    // --- Creation Function ---

    /**
     * @dev Mints a new entangled pair of Key A and Key B.
     *      Requires the caller to have the CREATOR_ROLE.
     *      Assigns ownership of both keys to the caller.
     * @return The pair ID of the newly created pair.
     */
    function createEntangledPair() external onlyCreator returns (uint256) {
        _pairCounter.increment();
        uint256 pairId = _pairCounter.current();

        _keyCounter.increment();
        uint256 keyAId = _keyCounter.current();

        _keyCounter.increment();
        uint256 keyBId = _keyCounter.current();

        address owner = msg.sender;

        // Initialize Key A
        _keys[keyAId] = Key({
            pairId: pairId,
            keyType: KeyType.KeyA,
            pairedKeyId: keyBId,
            secretHash: bytes32(0),
            metadataURI: "" // Default empty URI
        });
        _safeMint(owner, keyAId); // Handles ownership and internal tracking

        // Initialize Key B
        _keys[keyBId] = Key({
            pairId: pairId,
            keyType: KeyType.KeyB,
            pairedKeyId: keyAId,
            secretHash: bytes32(0),
            metadataURI: "" // Default empty URI
        });
        _safeMint(owner, keyBId); // Handles ownership and internal tracking

        // Initialize Pair
        _pairs[pairId] = Pair({
            keyAId: keyAId,
            keyBId: keyBId,
            state: PairState.Entangled, // Start in Entangled state
            lastInteractionTime: block.timestamp,
            metadataURI: "" // Default empty URI
        });

        emit PairCreated(pairId, keyAId, keyBId, owner);

        return pairId;
    }

    // --- Ownership & Transfer Functions ---

    /**
     * @dev Transfers ownership of a single key.
     *      Can be called by the owner or an approved address/operator.
     * @param to The recipient address.
     * @param keyId The ID of the key to transfer.
     */
    function transferKey(address to, uint256 keyId) external onlyKeyOwnerOrApproved(keyId) {
        _transfer(ownerOf(keyId), to, keyId);
    }

     /**
     * @dev Transfers ownership of both keys in a pair to the same recipient.
     *      Requires the caller to own both keys.
     * @param to The recipient address.
     * @param pairId The ID of the pair to transfer.
     */
    function transferPair(address to, uint256 pairId) external onlyPairOwner(pairId) {
        uint256 keyAId = _pairs[pairId].keyAId;
        uint256 keyBId = _pairs[pairId].keyBId;
        address currentOwner = _keyOwners[keyAId]; // KeyA and KeyB must have the same owner here

        // Transfer both keys
        _transfer(currentOwner, to, keyAId);
        _transfer(currentOwner, to, keyBId);

        emit PairTransfer(pairId, currentOwner, to);
    }

    /**
     * @dev Safely transfers ownership of a single key, checking if recipient can receive.
     * @param from The current owner address.
     * @param to The recipient address.
     * @param keyId The ID of the key to transfer.
     */
     function safeTransferKey(address from, address to, uint256 keyId) external onlyKeyOwnerOrApproved(keyId) {
        _safeTransfer(from, to, keyId, "");
    }

     /**
     * @dev Safely transfers ownership of both keys in a pair, checking if recipient can receive.
     *      Requires the caller to own both keys.
     * @param from The current owner address.
     * @param to The recipient address.
     * @param pairId The ID of the pair to transfer.
     */
    function safeTransferPair(address from, address to, uint256 pairId) external onlyPairOwner(pairId) {
         if (ownerOf(_pairs[pairId].keyAId) != from) revert NotOwnerOrApproved(); // Double check sender owns both

        uint256 keyAId = _pairs[pairId].keyAId;
        uint256 keyBId = _pairs[pairId].keyBId;

        // Use internal _safeTransfer for each key
        _safeTransfer(from, to, keyAId, "");
        _safeTransfer(from, to, keyBId, "");

         emit PairTransfer(pairId, from, to);
    }


    /**
     * @dev Approves an address to manage a specific key.
     * @param to The address to approve.
     * @param keyId The ID of the key.
     */
    function approve(address to, uint256 keyId) external {
        address owner = ownerOf(keyId);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "QuantumEntanglementKeys: Approval requires owner or operator");
        _keyApprovals[keyId] = to;
        emit Approval(keyId, owner, to);
    }

    /**
     * @dev Approves or revokes an operator for all keys owned by the caller.
     * @param operator The operator address.
     * @param approved True to approve, false to revoke.
     */
    function setApprovalForAll(address operator, bool approved) external {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // --- Internal Transfer Logic (Simplified for this example) ---
    // Note: A full ERC721 implementation would be more complex, handling hooks, etc.
    // This is a simplified version for demonstrating the core concepts.
    function _transfer(address from, address to, uint256 keyId) internal {
        if (_keyOwners[keyId] != from) revert NotOwnerOrApproved(); // Ensure 'from' is the current owner

        // Clear approvals for the transferring key
        _keyApprovals[keyId] = address(0);

        // Update internal tracking
        _removeKeyFromOwnerListing(from, keyId);
        _addKeyToOwnerListing(to, keyId);

        _keyOwners[keyId] = to; // Update ownership mapping

        emit KeyTransfer(keyId, from, to);
    }

    function _safeTransfer(address from, address to, uint255 keyId, bytes memory data) internal {
         _transfer(from, to, keyId); // Perform the transfer first
        require(
            _checkOnERC721Received(from, to, keyId, data),
            "QuantumEntanglementKeys: Transfer to non ERC721Receiver implementer"
        );
    }

     // Helper function to check if a contract can receive tokens (based on ERC721 standard)
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 keyId,
        bytes memory data
    ) private returns (bool) {
        // If the recipient is not a contract account, no callback is required.
        if (!isContract(to)) {
            return true;
        }
        // If the recipient is a contract, check if it implements IERC721Receiver.
        // Use a low-level call to avoid issues with receiver implementation errors.
        (bool success, bytes memory returndata) = to.call(
            abi.encodeWithSelector(
                IERC721Receiver.onERC721Received.selector,
                msg.sender,
                from,
                keyId,
                data
            )
        );
        // Check success and the return value. The ERC721 standard requires the
        // `onERC721Received` function to return its own selector on success.
        return success && (returndata.length == 32) && abi.decode(returndata, (bytes4)) == IERC721Receiver.onERC721Received.selector;
    }

    // Helper function to check if an address is a contract (basic check)
    function isContract(address account) internal view returns (bool) {
        // This method relies on the `extcodesize` opcode, which returns 0 for accounts
        // without deployed code. It does not return 0 for accounts during construction,
        // so this method does not work in constructors.
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }


    // --- Internal Tracking for Owned Keys ---
    function _addKeyToOwnerListing(address to, uint256 keyId) internal {
        _ownedKeys[to].push(keyId);
        _ownedKeysIndex[keyId] = _ownedKeys[to].length - 1; // Store index
    }

    function _removeKeyFromOwnerListing(address from, uint256 keyId) internal {
         if (_ownedKeys[from].length == 0) return; // Nothing to remove

        uint256 keyIndex = _ownedKeysIndex[keyId];
        uint256 lastKeyIndex = _ownedKeys[from].length - 1;
        uint256 lastKeyId = _ownedKeys[from][lastKeyIndex];

        // Move the last element to the index of the element to delete
        if (keyIndex != lastKeyIndex) {
            _ownedKeys[from][keyIndex] = lastKeyId;
            _ownedKeysIndex[lastKeyId] = keyIndex;
        }

        // Shrink the array
        _ownedKeys[from].pop();
        delete _ownedKeysIndex[keyId]; // Clean up the index mapping
    }

     // Internal mint function for creation
    function _safeMint(address to, uint256 keyId) internal {
        // Basic checks
        require(to != address(0), "QuantumEntanglementKeys: mint to the zero address");
        if (_keyOwners[keyId] != address(0)) revert KeyAlreadyExists(); // Should not happen with counter

        _keyOwners[keyId] = to;
        _addKeyToOwnerListing(to, keyId); // Add to internal tracking list

        emit KeyTransfer(0x000000000000000000000000000000000000dEaD, to, keyId); // Use burn address as 'from' for mint
    }


    // --- Entanglement Interaction Functions ---

    /**
     * @dev Simulates sending a "pulse" through one key in an Entangled pair.
     *      Requires the caller to be the owner of the key.
     *      Updates the state of *both* keys in the pair. (Example: toggle a boolean state or update a counter)
     * @param keyIdTrigger The ID of the key initiating the pulse.
     */
    function initiateEntanglementPulse(uint256 keyIdTrigger) external {
        address owner = ownerOf(keyIdTrigger); // Checks if keyId exists
        require(owner == msg.sender, "QuantumEntanglementKeys: Only key owner can initiate pulse");

        uint256 pairId = _keys[keyIdTrigger].pairId;
        if (_pairs[pairId].state != PairState.Entangled) revert NotEntangled();

        // Example simulation: Toggle a conceptual state in both keys
        // We don't have a specific 'state' field per key yet, so let's just update last interaction
        _pairs[pairId].lastInteractionTime = block.timestamp;

        // In a more complex version, this would update state variables linked to the key structs.
        // e.g., _keys[keyIdTrigger].pulseCount++; _keys[_keys[keyIdTrigger].pairedKeyId].pulseCount++;

        emit EntanglementPulseInitiated(pairId, keyIdTrigger, msg.sender);
        // Optionally, emit events for individual key state changes if implemented
    }

    /**
     * @dev Simulates the decay of entanglement state over time or upon explicit action.
     *      Allows the owner of *both* keys in the pair to initiate decay towards Decohered.
     *      Can transition state from Entangled -> Decohered.
     *      Further decay (Decohered -> Broken) might be possible via another function or time decay.
     * @param pairId The ID of the pair to decay.
     */
    function decayEntanglementState(uint256 pairId) external onlyPairOwner(pairId) {
         if (_pairs[pairId].keyAId == 0) revert PairNotFound();

        PairState currentState = _pairs[pairId].state;

        if (currentState == PairState.Entangled) {
            _pairs[pairId].state = PairState.Decohered;
            emit PairStateChanged(pairId, PairState.Decohered, msg.sender);
        } else if (currentState == PairState.Decohered) {
            // Optional: Add logic to transition from Decohered to Broken here, maybe based on time
            // if (_pairs[pairId].lastInteractionTime + decayThreshold < block.timestamp) {
            //     _pairs[pairId].state = PairState.Broken;
            //     emit PairStateChanged(pairId, PairState.Broken, msg.sender);
            //     emit EntanglementBroken(pairId, msg.sender);
            // }
             // For now, if already Decohered, do nothing or require different function/conditions
             // Revert is also an option: revert("QuantumEntanglementKeys: Pair already Decohered");
        } else {
             revert PairAlreadyBroken();
        }
         _pairs[pairId].lastInteractionTime = block.timestamp; // Update interaction time
    }


    /**
     * @dev Simulates 'observing' the state of one key in an Entangled pair, potentially
     *      affecting the state of the other key.
     *      This function can have complex access control:
     *      - Could require ownership of *both* keys (like `onlyPairOwner`)
     *      - Could require one owner to call, and the other to have pre-approved (`approveObservation`)
     *      - Could be callable by an `OBSERVER_ROLE` under certain conditions (e.g., paying a fee)
     *      This example uses the `OBSERVER_ROLE` OR the owner of the triggering key.
     *      Only works on `Entangled` pairs. Might cause decoherence as a side effect.
     * @param pairId The ID of the pair being observed.
     * @param keyIdTrigger The ID of the key being directly 'observed'.
     */
    function observePairedState(uint256 pairId, uint256 keyIdTrigger) external {
        if (_pairs[pairId].keyAId == 0) revert PairNotFound();
        if (_keys[keyIdTrigger].pairId != pairId) revert MismatchedKeyInPair();

        // Access Control: Either the owner of the triggering key, OR an Observer role
        address keyOwner = ownerOf(keyIdTrigger);
        require(msg.sender == keyOwner || hasRole(OBSERVER_ROLE, msg.sender),
            "QuantumEntanglementKeys: Not owner of triggering key or Observer");

        if (_pairs[pairId].state != PairState.Entangled) revert NotEntangled();

        // --- Simulate Observation Effect ---
        // Example: Observation might slightly decay the entanglement state
        // Or reveal a specific shared bit of data IF certain conditions are met.
        // In a real implementation, this might trigger a state change or unlock data.

        // For this example, we'll just emit an event and update last interaction time.
        // Optionally, transition to Decohered:
        // _pairs[pairId].state = PairState.Decohered;
        // emit PairStateChanged(pairId, PairState.Decohered, msg.sender);

        _pairs[pairId].lastInteractionTime = block.timestamp; // Update interaction time

        emit PairedStateObserved(pairId, keyIdTrigger, msg.sender);
    }


    /**
     * @dev Allows the owners of a pair (even if owned separately) to synchronize some data or state,
     *      facilitated by the contract. This implies a coordinated action between two owners.
     *      Could require both owners to call in sequence or approve a third party (like a relayer).
     *      This example requires the caller to be the owner of *one* of the keys, and assumes
     *      some off-chain coordination or a prior approval mechanism (not fully implemented).
     *      For simplicity, let's say it updates a shared state bit *if* the pair is Entangled.
     * @param pairId The ID of the pair to synchronize.
     */
    function synchronizePairedKeys(uint256 pairId) external {
         if (_pairs[pairId].keyAId == 0) revert PairNotFound();

        uint256 keyAId = _pairs[pairId].keyAId;
        uint256 keyBId = _pairs[pairId].keyBId;
        address ownerA = ownerOf(keyAId);
        address ownerB = ownerOf(keyBId);

        // Require caller to be an owner of one of the keys
        require(msg.sender == ownerA || msg.sender == ownerB,
            "QuantumEntanglementKeys: Caller must own one of the keys in the pair");

        // --- Simulate Synchronization ---
        // This is where a more complex coordination mechanism would fit.
        // E.g., require a signed message from the other owner, or require both call within a time window.
        // For this example, let's just update interaction time if Entangled.

        if (_pairs[pairId].state == PairState.Entangled) {
             _pairs[pairId].lastInteractionTime = block.timestamp; // Update interaction time
             // In a real scenario, update shared state variables here
             // e.g., _pairs[pairId].sharedSyncCounter++;
             // emit PairSynchronized(pairId, msg.sender); // New event
        } else {
             revert NotEntangled(); // Synchronization only works when Entangled
        }
         // Add an event for synchronization
         emit PairStateChanged(pairId, _pairs[pairId].state, msg.sender); // Re-using event for state change indication
    }


    /**
     * @dev Permanently breaks the entanglement link between Key A and Key B.
     *      Requires the caller to own *both* keys in the pair.
     *      Sets the pair state to `Broken`. Broken pairs cannot use entanglement functions.
     * @param pairId The ID of the pair to break.
     */
    function breakEntanglement(uint256 pairId) external onlyPairOwner(pairId) {
         if (_pairs[pairId].keyAId == 0) revert PairNotFound();
         if (_pairs[pairId].state == PairState.Broken) revert PairAlreadyBroken();

        _pairs[pairId].state = PairState.Broken;
        emit EntanglementBroken(pairId, msg.sender);
        emit PairStateChanged(pairId, PairState.Broken, msg.sender);
    }

    /**
     * @dev Attempts to repair the entanglement for a Decohered or Broken pair.
     *      This could have complex conditions (e.g., burning a resource, a time lock,
     *      requiring both owners to collaborate, or a low probability of success).
     *      For simplicity, this version only works if the caller owns both keys
     *       and the state is Decohered or Broken, setting it back to Entangled.
     * @param pairId The ID of the pair to attempt repair on.
     */
    function attemptRepairEntanglement(uint256 pairId) external onlyPairOwner(pairId) {
         if (_pairs[pairId].keyAId == 0) revert PairNotFound();

        PairState currentState = _pairs[pairId].state;

        if (currentState == PairState.Entangled) {
            // Already entangled, nothing to do
            return;
        } else {
            // Simulate repair success (simple version)
            _pairs[pairId].state = PairState.Entangled;
            _pairs[pairId].lastInteractionTime = block.timestamp; // Reset timer
            emit PairStateChanged(pairId, PairState.Entangled, msg.sender);
            // In a real system, maybe add a success event or a cost/randomness factor
        }
    }


    // --- State & Data Management Functions ---

    /**
     * @dev Allows the owner of a key to attach a cryptographic hash representing an off-chain secret.
     *      Can be updated by the owner. Does not reveal the secret, only stores its hash.
     * @param keyId The ID of the key.
     * @param secretHash The hash of the secret (e.g., keccak256 of a string).
     */
    function attachSecretHash(uint256 keyId, bytes32 secretHash) external onlyKeyOwnerOrApproved(keyId) {
        _keys[keyId].secretHash = secretHash;
        emit SecretHashAttached(keyId, secretHash, msg.sender);
    }

    /**
     * @dev Allows the owner of a key to retrieve the attached secret hash.
     *      Note: This function is view/pure and reveals the hash, which is public data on-chain.
     *      The *actual* secret remains off-chain.
     * @param keyId The ID of the key.
     * @return The attached secret hash.
     */
    function revealSecretHash(uint256 keyId) external view returns (bytes32) {
        if (_keys[keyId].pairId == 0) revert InvalidKeyId(); // Check existence
        if (_keys[keyId].secretHash == bytes32(0)) revert SecretHashNotAttached(); // Check if hash was ever attached
        // require(ownerOf(keyId) == msg.sender, "QuantumEntanglementKeys: Only owner can reveal hash"); // Optional: Restrict visibility

        return _keys[keyId].secretHash;
    }

    /**
     * @dev Allows the owner of *both* keys in a pair to verify if two provided hashes
     *      match the secret hashes attached to Key A and Key B respectively, *without* revealing the stored hashes.
     *      Requires both keys to have secret hashes attached.
     *      Conceptually similar to proving knowledge without revealing.
     * @param pairId The ID of the pair.
     * @param hashA The hash claimed to be attached to Key A.
     * @param hashB The hash claimed to be attached to Key B.
     * @return True if both hashes match the stored hashes for Key A and Key B of the pair.
     */
    function verifyPairedSecretMatch(uint256 pairId, bytes32 hashA, bytes32 hashB) external view onlyPairOwner(pairId) returns (bool) {
        uint256 keyAId = _pairs[pairId].keyAId;
        uint256 keyBId = _pairs[pairId].keyBId;

        if (_keys[keyAId].secretHash == bytes32(0) || _keys[keyBId].secretHash == bytes32(0)) {
             revert SecretHashNotAttached(); // Both must have hashes attached
        }

        // Check if provided hashes match stored hashes
        return _keys[keyAId].secretHash == hashA && _keys[keyBId].secretHash == hashB;
    }

     /**
     * @dev Allows the owner to update the metadata URI for a single key.
     * @param keyId The ID of the key.
     * @param metadataURI The new metadata URI string.
     */
    function updateKeyMetadata(uint256 keyId, string memory metadataURI) external onlyKeyOwnerOrApproved(keyId) {
        _keys[keyId].metadataURI = metadataURI;
        emit KeyMetadataUpdated(keyId, metadataURI, msg.sender);
    }

    /**
     * @dev Allows the owner of both keys in a pair to update the metadata URI for the pair.
     *      This could conceptually override individual key metadata depending on how it's used off-chain.
     * @param pairId The ID of the pair.
     * @param metadataURI The new metadata URI string for the pair.
     */
    function updatePairMetadata(uint256 pairId, string memory metadataURI) external onlyPairOwner(pairId) {
        if (_pairs[pairId].keyAId == 0) revert PairNotFound();
        _pairs[pairId].metadataURI = metadataURI;
        emit PairMetadataUpdated(pairId, metadataURI, msg.sender);
    }


    // --- Utility Functions ---

    /**
     * @dev Returns an array of all individual key IDs owned by an address.
     *      NOTE: This function can be very gas-intensive and potentially exceed block gas limits
     *      if an address owns a large number of keys. Consider off-chain indexing for scalability.
     * @param owner The address to query.
     * @return An array of key IDs.
     */
    function getKeysOwnedBy(address owner) external view returns (uint256[] memory) {
        return _ownedKeys[owner];
    }

    /**
     * @dev Returns an array of pair IDs where *both* keys in the pair are owned by the same address.
     *      NOTE: This iterates through all created pairs. Can be gas-intensive for many pairs.
     * @param owner The address to query.
     * @return An array of pair IDs.
     */
    function getPairsOwnedBy(address owner) external view returns (uint256[] memory) {
        uint256[] memory ownedPairs;
        uint256 currentPairCount = _pairCounter.current();
        uint256 tempCount = 0;

        // First pass to count
        for (uint256 i = 1; i <= currentPairCount; i++) {
            uint256 keyAId = _pairs[i].keyAId;
             // Check if pair exists and both keys are owned by the address
            if (keyAId != 0 && _keyOwners[keyAId] == owner && _keyOwners[_pairs[i].keyBId] == owner) {
                tempCount++;
            }
        }

        ownedPairs = new uint256[](tempCount);
        uint256 currentIndex = 0;

        // Second pass to fill the array
         for (uint256 i = 1; i <= currentPairCount; i++) {
            uint256 keyAId = _pairs[i].keyAId;
             // Check if pair exists and both keys are owned by the address
            if (keyAId != 0 && _keyOwners[keyAId] == owner && _keyOwners[_pairs[i].keyBId] == owner) {
                ownedPairs[currentIndex] = i;
                currentIndex++;
            }
        }

        return ownedPairs;
    }

    // --- ERC165 Interface Support (Needed for ERC721Receiver check) ---
    // Adds basic support for `supportsInterface`
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId);
        // Add other interface IDs if needed, e.g., ERC721 interface
        // return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC721Metadata).interfaceId || super.supportsInterface(interfaceId);
    }

    // The onERC721Received function is required by IERC721Receiver and implemented by ERC721Holder
    // This allows the contract itself to receive other ERC721 tokens, which isn't the primary goal
    // but is required by `_safeTransfer` when transferring *to* this contract address.
    // You might want to disable this if the contract should *never* hold tokens.
    // function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
    //     // Decide what happens when this contract receives an ERC721. By default, ERC721Holder
    //     // returns the correct selector to signal acceptance. You could add checks here.
    //     return super.onERC721Received(operator, from, tokenId, data);
    // }

}
```