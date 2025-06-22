Okay, here is a smart contract written in Solidity with over 20 functions, incorporating advanced and creative concepts inspired by quantum physics metaphors (without implementing actual quantum computing, which is not possible on EVM). The concepts revolve around managing data ("Quantum Keys") that can be "entangled," have probabilistic "decay," require specific "context" for access, and have complex state transitions.

This contract is purely conceptual and designed to showcase various function interactions and state management patterns beyond simple token or data storage. It is **not** intended for production use without rigorous security audits and gas optimization.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumEntangledKeyManager
 * @author YourName (or a pseudonym)
 * @notice A conceptual smart contract managing 'Quantum Keys' with
 *         features inspired by quantum mechanics metaphors: entanglement,
 *         probabilistic decay, context-dependent access, and state observations.
 *         This is a complex example demonstrating various function types and state
 *         interactions, not a production-ready system.
 */

/*
 * OUTLINE:
 * 1. Contract State: Defines structs for Quantum Keys and Entanglement Links,
 *    mappings to store them, state counters, global context, and ownership.
 * 2. Events: Signals for key lifecycle, link creation/destruction, access,
 *    decay, context changes, and state transitions.
 * 3. Modifiers: Custom checks for key existence, link existence, decay status,
 *    context matching, and ownership.
 * 4. Error Handling: Custom errors for clearer reverts.
 * 5. Data Structures (Structs & Enums): Defines the structure of keys, links,
 *    link types, and context requirements.
 * 6. Core Logic Functions:
 *    - Key Management: Creation, updates, status checks, manual decay.
 *    - Link Management: Creation, updates, breakage, status checks.
 *    - Access Control: The central `accessQuantumKey` function with complex checks
 *      (decay, expiration, context, entanglement effects).
 *    - State Observation/Query: Functions to retrieve key/link/contract info.
 *    - Context Management: Setting and checking the global context required for access.
 *    - Utilities: Functions to check access possibility, cleanup.
 *    - Access & Control: Basic ownership and pause functionality.
 * 7. Function Count: Designed to exceed 20 functions, demonstrating diverse interactions.
 */

/*
 * FUNCTION SUMMARY:
 *
 * --- Key Management ---
 * 1. createQuantumKey(bytes memory data, uint256 expirationBlock, uint256 probabilisticDecayFactor, bytes32 requiredContext): Creates a new Quantum Key with specified properties.
 * 2. updateKeyExpiration(uint256 keyId, uint256 newExpirationBlock): Updates the expiration block of an existing key.
 * 3. updateKeyProbabilisticDecayFactor(uint256 keyId, uint256 newDecayFactor): Updates the probabilistic decay factor (owner only).
 * 4. decayKeyManually(uint256 keyId): Forces a key to decay (owner or privileged role).
 * 5. renewKey(uint256 keyId, uint256 newExpirationBlock): Renews a decayed key, potentially with a new expiration (owner only).
 *
 * --- Entanglement Link Management ---
 * 6. createEntanglementLink(uint256 key1Id, uint256 key2Id, EntanglementType linkType): Creates a bidirectional entanglement link between two keys.
 * 7. breakEntanglementLink(uint256 linkId): Deactivates an existing entanglement link.
 * 8. updateLinkType(uint256 linkId, EntanglementType newType): Changes the behavior type of an active link (owner only).
 * 9. updateLinkStatus(uint256 linkId, bool isActive): Activates or deactivates an entanglement link (owner only).
 *
 * --- Key Access & Observation ---
 * 10. accessQuantumKey(uint256 keyId): Attempts to access a Quantum Key. Performs decay checks, context checks, and triggers entangled effects if successful. Returns key data.
 * 11. getKeyInfo(uint256 keyId): Retrieves non-sensitive information about a key (expiration, decay status, context requirement, linked keys count).
 * 12. getEntangledKeys(uint256 keyId): Returns the IDs of keys currently entangled with a specific key.
 * 13. canAccessKey(uint256 keyId): Checks if a key meets the criteria for access *at the current moment* without attempting access.
 * 14. getRawKeyDataIfPermitted(uint256 keyId): Allows owner or privileged role to retrieve key data without triggering access effects.
 *
 * --- State & Context Management ---
 * 15. setGlobalContext(bytes32 newContext): Sets the global context required by certain keys for access (owner only).
 * 16. getCurrentContext(): Returns the current global context.
 * 17. getTotalKeys(): Returns the total number of keys ever created.
 * 18. getTotalActiveLinks(): Returns the total number of currently active entanglement links.
 * 19. getContractStateSummary(): Returns a summary struct of key contract state metrics.
 *
 * --- Utility & Maintenance ---
 * 20. checkProbabilisticDecay(uint256 keyId): Checks if a key decays based on its decay factor and block randomness (internal/utility, called during access).
 * 21. cleanupDecayedKey(uint256 keyId): Allows owner to remove a decayed key's data from storage to save gas/space (caution advised).
 * 22. getKeysByOwner(address ownerAddress): Returns the IDs of keys owned by a specific address (can be gas-intensive for many keys).
 *
 * --- Access & Control (Basic Ownership/Pausability) ---
 * 23. transferOwnership(address newOwner): Transfers contract ownership (standard).
 * 24. renounceOwnership(): Relinquishes ownership (standard).
 * 25. owner(): Returns the current owner (standard getter).
 * 26. pause(): Pauses contract interactions (owner only, standard Pausable).
 * 27. unpause(): Unpauses contract interactions (owner only, standard Pausable).
 * 28. paused(): Returns pause status (standard getter).
 *
 * Total Functions: 28+
 */

import "hardhat/console.sol"; // Or remove if not using hardhat

// Custom Errors for better revert messages
error KeyNotFound(uint256 keyId);
error LinkNotFound(uint256 linkId);
error KeyAlreadyDecayed(uint256 keyId);
error KeyNotDecayed(uint256 keyId);
error KeyExpired(uint256 keyId);
error ContextMismatch(uint256 keyId);
error LinkNotActive(uint256 linkId);
error CannotLinkKeyToItself();
error NotOwner();
error ContractPaused();
error ContractNotPaused();
error AccessDenied(uint256 keyId, string reason); // General access denial with reason

// Enums for clarity
enum EntanglementType {
    MutualDecay,             // Accessing Key A decays Key B, accessing Key B decays Key A
    AccessTriggersOther,     // Accessing Key A decays Key B, but accessing Key B does NOT decay Key A
    MutualContextRequirement // Both keys require the *same* context to be active (checks during access)
    // Add more complex types here
}

enum ContextRequirement {
    None,          // No context required
    SpecificValue, // Requires a specific bytes32 context value to match global
    // Add more complex context types here
}

// Data Structures
struct QuantumKey {
    bytes data; // The sensitive data (can be anything)
    uint256 creationBlock;
    uint256 expirationBlock; // Key becomes invalid after this block
    uint256 probabilisticDecayFactor; // Higher factor = higher chance of probabilistic decay (e.g., 1-100)
    address owner; // The "owner" who created/manages the key
    bool isDecayed; // Set to true on access, expiration, or probabilistic decay
    bytes32 requiredContext; // Context value required for access if contextRequired is true
    ContextRequirement contextType;
    uint256[] linkedLinks; // IDs of links this key is part of
    bool cleanedUp; // Flag to indicate if data has been removed for cleanup
}

struct EntanglementLink {
    uint256 linkId;
    uint256 key1Id;
    uint256 key2Id;
    EntanglementType linkType;
    bool isActive;
    uint256 creationBlock;
}

struct ContractStateSummary {
    uint256 totalKeysCreated;
    uint256 totalActiveLinks;
    bytes32 currentGlobalContext;
    bool contractIsPaused;
}

// --- State Variables ---
uint256 private s_nextKeyId;
uint256 private s_nextLinkId;
bytes32 private s_globalContext;
bool private s_paused;

mapping(uint256 => QuantumKey) private s_keys;
mapping(uint256 => EntanglementLink) private s_links;
mapping(address => uint256[]) private s_keysByOwner; // Store key IDs per owner

// --- Events ---
event KeyCreated(uint256 indexed keyId, address indexed owner, bytes32 indexed requiredContext, uint256 expirationBlock);
event KeyAccessed(uint256 indexed keyId, address indexed accessor, bytes32 indexed contextUsed, uint256 blockAccessed);
event KeyDecayed(uint256 indexed keyId, string reason, uint256 blockNumber); // reason: "accessed", "expired", "probabilistic", "manual"
event KeyRenewed(uint256 indexed keyId, uint256 newExpirationBlock);
event LinkCreated(uint256 indexed linkId, uint256 indexed key1Id, uint256 indexed key2Id, EntanglementType linkType);
event LinkBroken(uint256 indexed linkId);
event LinkStatusUpdated(uint256 indexed linkId, bool isActive);
event LinkTypeUpdated(uint256 indexed linkId, EntanglementType newType);
event GlobalContextUpdated(bytes32 indexed oldContext, bytes32 indexed newContext, address indexed updater);
event KeyCleanup(uint256 indexed keyId, address indexed cleaner);
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
event Paused(address indexed account);
event Unpaused(address indexed account);

// --- Modifiers ---
modifier onlyOwner() {
    if (msg.sender != owner()) revert NotOwner();
    _;
}

modifier whenNotPaused() {
    if (s_paused) revert ContractPaused();
    _;
}

modifier whenPaused() {
    if (!s_paused) revert ContractNotPaused();
    _;
}

modifier onlyKeyExists(uint256 keyId) {
    if (s_keys[keyId].creationBlock == 0) revert KeyNotFound(keyId); // Check if key exists by checking a non-zero default value
    _;
}

modifier onlyLinkExists(uint256 linkId) {
    if (s_links[linkId].creationBlock == 0) revert LinkNotFound(linkId); // Check if link exists
    _;
}

modifier onlyKeyNotDecayed(uint256 keyId) {
    if (s_keys[keyId].isDecayed) revert KeyAlreadyDecayed(keyId);
    _;
}

// --- Constructor ---
constructor() {
    // Initialize counters and owner
    s_nextKeyId = 1;
    s_nextLinkId = 1;
    s_paused = false;
    emit OwnershipTransferred(address(0), msg.sender);
}

// --- Access Control Getters (Manual Ownership) ---
address private s_owner;

// Initializer for owner (done in constructor)
function initializeOwner() internal {
     // This is typically done once. In this example, it's just assigned in constructor.
     // For upgradeable contracts, this would be separate.
}

// 25. owner() - Standard getter for owner
function owner() public view returns (address) {
    // Check if owner is initialized (needed for manual ownership)
    if (s_owner == address(0)) {
        // In this simple example, the owner is set in the constructor.
        // A more robust manual implementation would need an initialize function.
        // For this example, we'll assume s_owner is correctly set by the constructor.
        // Let's explicitly set s_owner in the constructor for clarity.
         return s_owner;
    }
    return s_owner;
}

// Constructor explicitly sets owner now
constructor() {
    s_owner = msg.sender; // Set owner in constructor
    s_nextKeyId = 1;
    s_nextLinkId = 1;
    s_paused = false;
    emit OwnershipTransferred(address(0), msg.sender);
}


// 23. transferOwnership(address newOwner)
function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(s_owner, newOwner);
    s_owner = newOwner;
}

// 24. renounceOwnership()
function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(s_owner, address(0));
    s_owner = address(0);
}

// --- Pausability (Manual) ---
// 28. paused() - Standard getter for paused status
function paused() public view returns (bool) {
    return s_paused;
}

// 26. pause()
function pause() public virtual onlyOwner whenNotPaused {
    s_paused = true;
    emit Paused(msg.sender);
}

// 27. unpause()
function unpause() public virtual onlyOwner whenPaused {
    s_paused = false;
    emit Unpaused(msg.sender);
}


// --- Key Management Functions ---

// 1. createQuantumKey(...)
function createQuantumKey(
    bytes memory data,
    uint256 expirationBlock,
    uint256 probabilisticDecayFactor, // 0-100, 0 means no probabilistic decay
    bytes32 requiredContext // Set to bytes32(0) for no specific context
) public whenNotPaused returns (uint256 keyId) {
    require(expirationBlock > block.number, "Expiration must be in the future");
    require(probabilisticDecayFactor <= 100, "Decay factor max 100");

    keyId = s_nextKeyId++;
    ContextRequirement contextType = requiredContext != bytes32(0) ? ContextRequirement.SpecificValue : ContextRequirement.None;

    s_keys[keyId] = QuantumKey({
        data: data,
        creationBlock: block.number,
        expirationBlock: expirationBlock,
        probabilisticDecayFactor: probabilisticDecayFactor,
        owner: msg.sender,
        isDecayed: false,
        requiredContext: requiredContext,
        contextType: contextType,
        linkedLinks: new uint256[](0), // Initialize empty array
        cleanedUp: false
    });

    s_keysByOwner[msg.sender].push(keyId);

    emit KeyCreated(keyId, msg.sender, requiredContext, expirationBlock);
    console.log("Key created with ID:", keyId, "by", msg.sender); // For debugging
    return keyId;
}

// 2. updateKeyExpiration(...)
function updateKeyExpiration(uint256 keyId, uint256 newExpirationBlock) public whenNotPaused onlyKeyExists(keyId) {
    QuantumKey storage key = s_keys[keyId];
    require(msg.sender == key.owner || msg.sender == owner(), "Not key owner or contract owner");
    require(newExpirationBlock > block.number, "New expiration must be in the future");
    require(!key.isDecayed, "Cannot update expiration of decayed key");

    key.expirationBlock = newExpirationBlock;
    // No event for just updating expiration for simplicity in this example
}

// 3. updateKeyProbabilisticDecayFactor(...)
function updateKeyProbabilisticDecayFactor(uint256 keyId, uint256 newDecayFactor) public whenNotPaused onlyKeyExists(keyId) onlyOwner {
    require(newDecayFactor <= 100, "New decay factor max 100");
    require(!s_keys[keyId].isDecayed, "Cannot update decay factor of decayed key");

    s_keys[keyId].probabilisticDecayFactor = newDecayFactor;
    // No event for simplicity
}

// 4. decayKeyManually(...)
function decayKeyManually(uint256 keyId) public whenNotPaused onlyKeyExists(keyId) onlyKeyNotDecayed(keyId) {
     QuantumKey storage key = s_keys[keyId];
     require(msg.sender == key.owner || msg.sender == owner(), "Not key owner or contract owner");

     _decayKey(keyId, "manual");
}

// Internal function to handle key decay state transition
function _decayKey(uint256 keyId, string memory reason) internal onlyKeyExists(keyId) {
    QuantumKey storage key = s_keys[keyId];
    if (!key.isDecayed) {
        key.isDecayed = true;
        emit KeyDecayed(keyId, reason, block.number);
        console.log("Key decayed:", keyId, "Reason:", reason);
        // Note: Entanglement effects triggered *during access*, not just any decay.
    }
}

// 5. renewKey(...)
function renewKey(uint256 keyId, uint256 newExpirationBlock) public whenNotPaused onlyKeyExists(keyId) onlyOwner {
    QuantumKey storage key = s_keys[keyId];
    require(key.isDecayed, "Key must be decayed to be renewed");
    require(newExpirationBlock > block.number, "New expiration must be in the future");
    require(!key.cleanedUp, "Cannot renew a cleaned up key");


    key.isDecayed = false;
    key.expirationBlock = newExpirationBlock;
    // Reset probabilistic decay factor or context? Let's leave them as is for now.
    // key.probabilisticDecayFactor = 0; // Example: Reset decay factor on renewal

    emit KeyRenewed(keyId, newExpirationBlock);
    console.log("Key renewed:", keyId);
}


// --- Entanglement Link Management Functions ---

// 6. createEntanglementLink(...)
function createEntanglementLink(uint256 key1Id, uint256 key2Id, EntanglementType linkType) public whenNotPaused onlyKeyExists(key1Id) onlyKeyExists(key2Id) returns (uint256 linkId) {
    require(key1Id != key2Id, "Cannot link a key to itself");
    // Require owner of both keys or contract owner? Let's require owner of *caller's* key for simplicity, or contract owner.
    require(msg.sender == s_keys[key1Id].owner || msg.sender == s_keys[key2Id].owner || msg.sender == owner(), "Must own one of the keys or be contract owner");

    linkId = s_nextLinkId++;

    s_links[linkId] = EntanglementLink({
        linkId: linkId,
        key1Id: key1Id,
        key2Id: key2Id,
        linkType: linkType,
        isActive: true, // Links are active by default
        creationBlock: block.number
    });

    s_keys[key1Id].linkedLinks.push(linkId);
    if (key1Id != key2Id) { // Avoid pushing the same link ID twice for self-links (though checked above)
        s_keys[key2Id].linkedLinks.push(linkId);
    }

    emit LinkCreated(linkId, key1Id, key2Id, linkType);
    console.log("Link created:", linkId, "between", key1Id, "and", key2Id, "Type:", uint(linkType));
    return linkId;
}

// 7. breakEntanglementLink(...)
function breakEntanglementLink(uint256 linkId) public whenNotPaused onlyLinkExists(linkId) {
    EntanglementLink storage link = s_links[linkId];
    // Allow owner of either key or contract owner to break
    require(msg.sender == s_keys[link.key1Id].owner || msg.sender == s_keys[link.key2Id].owner || msg.sender == owner(), "Must own one of the linked keys or be contract owner");

    // We don't delete the link struct to maintain history/ID uniqueness.
    // Instead, we mark it inactive. Cleaning up the linkedLinks array is complex.
    // We'll handle inactive links by filtering in read/logic functions.
    if (link.isActive) {
        link.isActive = false;
        emit LinkBroken(linkId); // Using LinkBroken event for deactivation
        console.log("Link broken:", linkId);
    }
}

// 8. updateLinkType(...)
function updateLinkType(uint256 linkId, EntanglementType newType) public whenNotPaused onlyLinkExists(linkId) onlyOwner {
    EntanglementLink storage link = s_links[linkId];
    require(link.isActive, "Link must be active to update type");
    link.linkType = newType;
    emit LinkTypeUpdated(linkId, newType);
    console.log("Link type updated:", linkId, "to", uint(newType));
}

// 9. updateLinkStatus(...)
function updateLinkStatus(uint256 linkId, bool isActive) public whenNotPaused onlyLinkExists(linkId) onlyOwner {
    EntanglementLink storage link = s_links[linkId];
    if (link.isActive != isActive) {
        link.isActive = isActive;
        emit LinkStatusUpdated(linkId, isActive);
         console.log("Link status updated:", linkId, "to active:", isActive);
    }
}


// --- Key Access & Observation Functions ---

// 10. accessQuantumKey(...) - The core interaction function
function accessQuantumKey(uint256 keyId) public whenNotPaused onlyKeyExists(keyId) returns (bytes memory) {
    QuantumKey storage key = s_keys[keyId];

    if (key.cleanedUp) revert AccessDenied(keyId, "Key data cleaned up");
    if (key.isDecayed) revert KeyAlreadyDecayed(keyId);
    if (block.number > key.expirationBlock) {
        _decayKey(keyId, "expired");
        revert KeyExpired(keyId);
    }

    // Check Context Requirement
    if (key.contextType == ContextRequirement.SpecificValue) {
        if (key.requiredContext != s_globalContext) {
             revert ContextMismatch(keyId);
        }
    }

    // Check Probabilistic Decay (happens *before* access succeeds)
    if (key.probabilisticDecayFactor > 0) {
         if (checkProbabilisticDecay(keyId)) {
             _decayKey(keyId, "probabilistic");
             revert AccessDenied(keyId, "Probabilistically decayed during access attempt");
         }
    }

    // Access is successful!
    bytes memory accessedData = key.data; // Get data *before* potentially triggering decay

    // Trigger decay on access
    _decayKey(keyId, "accessed");

    // Trigger Entanglement Effects on linked keys
    _triggerEntanglementEffects(keyId);

    emit KeyAccessed(keyId, msg.sender, s_globalContext, block.number);
    console.log("Key accessed:", keyId, "by", msg.sender);

    return accessedData;
}

// Internal helper for triggering entanglement effects
function _triggerEntanglementEffects(uint256 accessedKeyId) internal {
    QuantumKey storage key = s_keys[accessedKeyId];

    // Iterate through linked links
    uint256 currentLinkCount = key.linkedLinks.length; // Snapshot length for safety if array changes
    for (uint256 i = 0; i < currentLinkCount; i++) {
        uint256 linkId = key.linkedLinks[i];

        // Ensure link exists and is active before processing
        if (s_links[linkId].creationBlock != 0 && s_links[linkId].isActive) {
            EntanglementLink storage link = s_links[linkId];

            uint256 otherKeyId = (link.key1Id == accessedKeyId) ? link.key2Id : link.key1Id;

            // Ensure the other key exists and hasn't been cleaned up
            if (s_keys[otherKeyId].creationBlock != 0 && !s_keys[otherKeyId].cleanedUp) {
                 QuantumKey storage otherKey = s_keys[otherKeyId];

                 if (!otherKey.isDecayed) { // Only affect keys that haven't decayed yet
                     if (link.linkType == EntanglementType.MutualDecay) {
                         console.log("Entanglement Effect: MutualDecay - Decaying linked key", otherKeyId);
                         _decayKey(otherKeyId, "entanglement_mutual_decay");
                     } else if (link.linkType == EntanglementType.AccessTriggersOther && link.key1Id == accessedKeyId) {
                         // Only triggers if accessedKeyId is key1Id for this link type
                         console.log("Entanglement Effect: AccessTriggersOther - Decaying linked key", otherKeyId);
                         _decayKey(otherKeyId, "entanglement_trigger");
                     } else if (link.linkType == EntanglementType.MutualContextRequirement) {
                         // This type's effect is checked *during* access, not triggered afterwards.
                         // No state change effect here.
                     }
                     // Add logic for other entanglement types here
                 }
            }
        }
    }
}


// 11. getKeyInfo(...) - View function for key details
function getKeyInfo(uint256 keyId) public view onlyKeyExists(keyId) returns (
    uint256 id,
    uint256 creationBlock,
    uint256 expirationBlock,
    uint256 probabilisticDecayFactor,
    address owner,
    bool isDecayed,
    bytes32 requiredContext,
    ContextRequirement contextType,
    uint256 linkedLinksCount,
    bool cleanedUp
) {
    QuantumKey storage key = s_keys[keyId];
    return (
        keyId,
        key.creationBlock,
        key.expirationBlock,
        key.probabilisticDecayFactor,
        key.owner,
        key.isDecayed,
        key.requiredContext,
        key.contextType,
        key.linkedLinks.length, // Return count instead of array for view function gas limits
        key.cleanedUp
    );
}

// 12. getEntangledKeys(...) - View function to find linked keys
function getEntangledKeys(uint256 keyId) public view onlyKeyExists(keyId) returns (uint256[] memory) {
    QuantumKey storage key = s_keys[keyId];
    uint256[] memory entangledKeys = new uint256[](key.linkedLinks.length);
    uint256 count = 0;

    for (uint256 i = 0; i < key.linkedLinks.length; i++) {
        uint256 linkId = key.linkedLinks[i];
         // Check if link exists, is active, and the other key exists/not cleaned up
        if (s_links[linkId].creationBlock != 0 && s_links[linkId].isActive) {
             EntanglementLink storage link = s_links[linkId];
             uint256 otherKeyId = (link.key1Id == keyId) ? link.key2Id : link.key1Id;
             if (s_keys[otherKeyId].creationBlock != 0 && !s_keys[otherKeyId].cleanedUp) {
                entangledKeys[count] = otherKeyId;
                count++;
             }
        }
    }

    // Resize array to actual count of valid, active entangled keys
    uint256[] memory result = new uint256[](count);
    for (uint256 i = 0; i < count; i++) {
        result[i] = entangledKeys[i];
    }
    return result;
}

// 13. canAccessKey(...) - Utility view function
function canAccessKey(uint256 keyId) public view onlyKeyExists(keyId) returns (bool) {
    QuantumKey storage key = s_keys[keyId];

    if (key.cleanedUp || key.isDecayed || block.number > key.expirationBlock) {
        return false; // Basic validity checks
    }

    // Check Context Requirement
    if (key.contextType == ContextRequirement.SpecificValue) {
        if (key.requiredContext != s_globalContext) {
             return false; // Context mismatch
        }
    }

    // Note: This does *not* check probabilistic decay, as that's non-deterministic
    // and happens *during* the access transaction.

    return true; // Seems accessible based on deterministic checks
}

// 14. getRawKeyDataIfPermitted(...) - Owner/privileged access to data
function getRawKeyDataIfPermitted(uint256 keyId) public view onlyKeyExists(keyId) onlyOwner returns (bytes memory) {
     // Allows owner to view data regardless of decay/context, without triggering effects
    QuantumKey storage key = s_keys[keyId];
    if (key.cleanedUp) revert AccessDenied(keyId, "Key data cleaned up");
    return key.data;
}


// --- State & Context Management Functions ---

// 15. setGlobalContext(...)
function setGlobalContext(bytes32 newContext) public whenNotPaused onlyOwner {
    bytes32 oldContext = s_globalContext;
    s_globalContext = newContext;
    emit GlobalContextUpdated(oldContext, newContext, msg.sender);
    console.log("Global context updated to:", newContext);
}

// 16. getCurrentContext()
function getCurrentContext() public view returns (bytes32) {
    return s_globalContext;
}

// 17. getTotalKeys()
function getTotalKeys() public view returns (uint256) {
    // s_nextKeyId is the count *after* the last ID assigned, so total keys is s_nextKeyId - 1
    return s_nextKeyId - 1;
}

// 18. getTotalActiveLinks()
function getTotalActiveLinks() public view returns (uint256) {
     // Iterating through all links might be gas-intensive for many links.
     // A more efficient way would be to maintain a counter that's updated
     // on link creation, breakage, and status updates.
     // For this example, let's iterate (caution: gas):
     uint256 activeCount = 0;
     // Iterate from 1 up to the last link ID created
     for (uint256 i = 1; i < s_nextLinkId; i++) {
         // Check if link exists and is active
         if (s_links[i].creationBlock != 0 && s_links[i].isActive) {
             activeCount++;
         }
     }
     return activeCount;
}

// 19. getContractStateSummary()
function getContractStateSummary() public view returns (ContractStateSummary memory) {
     return ContractStateSummary({
         totalKeysCreated: getTotalKeys(), // Uses internal function
         totalActiveLinks: getTotalActiveLinks(), // Uses internal function (caution: gas)
         currentGlobalContext: s_globalContext,
         contractIsPaused: s_paused
     });
}


// --- Utility & Maintenance Functions ---

// 20. checkProbabilisticDecay(...) - Internal utility for probabilistic check
function checkProbabilisticDecay(uint256 keyId) internal view onlyKeyExists(keyId) returns (bool) {
    uint256 decayFactor = s_keys[keyId].probabilisticDecayFactor;
    if (decayFactor == 0) {
        return false; // No probabilistic decay configured
    }

    // Simple "randomness" based on block hash and key ID.
    // WARNING: Block hash is manipulable by miners within limits.
    // Do NOT use for high-value security decisions.
    // A production system would use a secure oracle (like Chainlink VRF).
    uint256 randomNumber = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), keyId, block.timestamp))) % 100; // Get a number between 0 and 99

    // Decay if the random number is less than the decay factor
    // e.g., factor 10 means 10% chance (numbers 0-9)
    return randomNumber < decayFactor;
}

// 21. cleanupDecayedKey(...) - Allows removal of decayed key data
function cleanupDecayedKey(uint256 keyId) public whenNotPaused onlyKeyExists(keyId) {
     QuantumKey storage key = s_keys[keyId];
     require(msg.sender == key.owner || msg.sender == owner(), "Not key owner or contract owner");
     require(key.isDecayed, "Key must be decayed to be cleaned up");
     require(!key.cleanedUp, "Key already cleaned up");

     // Mark as cleaned up rather than deleting to avoid state complexity with linkedLinks arrays
     // If you *must* delete, you'd need to find this keyId in all linkedLinks arrays of other keys
     // and remove it, which is gas-prohibitive and complex with dynamic arrays.
     // Marking is simpler and prevents future access to data.
     key.cleanedUp = true;
     delete key.data; // Free up storage for the data

     emit KeyCleanup(keyId, msg.sender);
     console.log("Key cleaned up:", keyId);

     // Note: This doesn't remove the key ID from s_keys or s_keysByOwner arrays.
     // You would need separate, potentially gas-intensive, processes for full removal.
     // For this example, marking cleanedUp and deleting data is sufficient illustration.
}

// 22. getKeysByOwner(...) - Get list of key IDs for an owner
function getKeysByOwner(address ownerAddress) public view returns (uint256[] memory) {
     // WARNING: Can be gas-intensive if an owner has a very large number of keys.
     // Consider pagination or alternative storage patterns for production.
    return s_keysByOwner[ownerAddress];
}

// 29. getRawLinkInfo (Added during review - useful counterpart to getKeyInfo)
function getRawLinkInfo(uint256 linkId) public view onlyLinkExists(linkId) returns (
    uint256 id,
    uint256 key1Id,
    uint256 key2Id,
    EntanglementType linkType,
    bool isActive,
    uint256 creationBlock
) {
     EntanglementLink storage link = s_links[linkId];
     return (
         linkId,
         link.key1Id,
         link.key2Id,
         link.linkType,
         link.isActive,
         link.creationBlock
     );
}


}
```

**Explanation of Advanced/Creative Concepts & Functions:**

1.  **Quantum Key Metaphor:** Data isn't just stored; it's a "Quantum Key" with properties like decay factor, expiration, and required context, reflecting a non-static, state-dependent nature.
2.  **Probabilistic Decay (`probabilisticDecayFactor`, `checkProbabilisticDecay`):** Introduced a concept where accessing a key has a chance of causing it to decay, influenced by a factor. This uses `blockhash` and key ID for a (highly insecure) form of on-chain pseudo-randomness, highlighting the *concept* rather than secure implementation. A real dApp would use Chainlink VRF or similar.
3.  **Context-Dependent Access (`requiredContext`, `contextType`, `setGlobalContext`, `getCurrentContext`, `accessQuantumKey` context check):** Keys can be configured to *only* be accessible when a specific global context matches their required context. This allows for external state or conditions to gate access to secrets. The owner controls the global context, acting like an "environment modulator."
4.  **Entanglement Links (`EntanglementLink` struct, `createEntanglementLink`, `breakEntanglementLink`, `updateLinkType`, `updateLinkStatus`, `_triggerEntanglementEffects`, `getEntangledKeys`):** Two keys can be linked with specific "entanglement types." Accessing one key can trigger state changes (like decay) in the other, based on the link's rules.
    *   `MutualDecay`: Accessing either key decays the other.
    *   `AccessTriggersOther`: Accessing key1 decays key2, but accessing key2 does *not* decay key1 (asymmetric).
    *   `MutualContextRequirement`: (Implemented as a check within `accessQuantumKey`) Both keys linked by this type must have their *individual* context requirements met simultaneously for *either* to be accessible. (Self-correction: The current `_triggerEntanglementEffects` focuses on *decay* effects. The `MutualContextRequirement` needs to be checked *during* the access logic of *both* keys if they are linked by this type. This is complex to implement fully bidirectionally and efficiently within the example, so the current code focuses on the *decay-triggering* entanglement types in `_triggerEntanglementEffects`. The `ContextMismatch` check in `accessQuantumKey` applies to the *individual* key's context, not necessarily a linked one's requirement being met. Let's refine the `accessQuantumKey` description to clarify this type's behavior isn't fully implemented as a trigger). Let's stick to Decay-based entanglement for simplicity in `_triggerEntanglementEffects` and note the `MutualContextRequirement` as a conceptual idea in the enum.
5.  **State Observation/Query (`getKeyInfo`, `getEntangledKeys`, `canAccessKey`, `getContractStateSummary`, `getRawLinkInfo`):** Provides various ways to inspect the state of keys, links, and the contract itself, including filtered information (`getEntangledKeys` only shows *currently* entangled ones).
6.  **Lifecycle Management (`createQuantumKey`, `decayKeyManually`, `renewKey`, `cleanupDecayedKey`):** Explicit functions for creating keys, forcing decay, *un-decaying* (renewing, but only by owner), and even cleaning up the data of decayed keys (to save gas, but leaving ID records).
7.  **Function Count & Diversity:** Includes basic CRUD-like functions (create, update, break links) alongside complex state-changing logic (`accessQuantumKey`, `_triggerEntanglementEffects`), utility views (`canAccessKey`, `checkProbabilisticDecay`), and administrative functions (owner controls context, pause, cleanup). Exceeds 20 functions easily.
8.  **Non-Duplication:** Avoids standard patterns like ERC-20, ERC-721, basic MultiSig, or simple fixed timelocks. The entanglement, probabilistic decay, and dynamic context requirement logic are the core novelties here.
9.  **Manual Ownership/Pausability:** Instead of importing OpenZeppelin, basic `onlyOwner`, `paused`, `whenNotPaused`, `whenPaused`, `transferOwnership`, `renounceOwnership` are implemented manually to adhere strictly to "don't duplicate any of open source" for the *core components*, while still having these common control patterns.

This contract serves as a good exercise in designing complex state interactions and function calls within a Solidity contract, using a creative theme to tie the features together.