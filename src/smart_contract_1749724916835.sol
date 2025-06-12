Okay, let's design an interesting and advanced smart contract concept. How about a "Chronicle Ledger" that allows users to create, version, attest to, and link pieces of verifiable information (chronicles) on-chain? This involves data structuring, multi-party interaction, state transitions (versioning, freezing), and querying historical states.

It's not a simple token, NFT, or basic escrow. It focuses on on-chain data provenance and multi-party validation.

Here's the plan:

**Concept:** Chronicle Ledger - A decentralized system for creating, managing, and validating versioned historical records or data entries ("Chronicles") through on-chain attestation.

**Key Features:**
1.  **Chronicle Creation:** Users can create initial chronicle entries.
2.  **Versioning:** Authors can update their chronicles, creating new immutable versions.
3.  **Attestation:** Users can attest to the validity or accuracy of a *specific version* of a chronicle.
4.  **Attester Reputation:** Track the total number of attestations made by a user.
5.  **Linking:** Establish verifiable links between different chronicles.
6.  **Freezing:** Authors (or owner) can freeze a specific chronicle, preventing further updates.
7.  **Querying:** Retrieve specific versions, attestations, attester profiles, links, etc.
8.  **Metadata:** Attach arbitrary key-value metadata to chronicle versions.
9.  **Threshold Check:** Check if a chronicle version has met a minimum number of attestations.
10. **Pausable:** Standard contract pausing mechanism.
11. **Ownable:** Standard ownership pattern for administrative functions.

---

**ChronicleLedger Smart Contract Outline & Function Summary**

**Contract:** `ChronicleLedger`

**Inherits:** `Ownable`, `Pausable` (from OpenZeppelin)

**Purpose:** Manages versioned chronicles and multi-party attestations on the blockchain.

**Data Structures:**

*   `Attestation`: Represents a single attestation event. Stores the attester's address, timestamp, and an optional comment.
*   `ChronicleVersion`: Represents a specific version of a chronicle. Stores the data hash (e.g., IPFS hash), timestamp, author, a list of attestations for this version, a mapping to quickly check if an address has attested to this version, and arbitrary metadata.
*   `Chronicle`: Represents a complete chronicle history. Stores the current latest version number, a mapping of version numbers to `ChronicleVersion` structs, the creation timestamp, a flag indicating if the chronicle is frozen (no more updates allowed), and a list of IDs of other linked chronicles.
*   `AttesterProfile`: Stores information about an address acting as an attester, currently just the total number of attestations made across all chronicles and versions.

**State Variables:**

*   `nextChronicleId`: Counter for issuing new chronicle IDs.
*   `chronicles`: Mapping from chronicle ID (`uint256`) to `Chronicle` struct.
*   `attesterProfiles`: Mapping from attester address (`address`) to `AttesterProfile` struct.
*   `totalSystemAttestations`: Counter for the total number of attestations ever made across the entire system.

**Events:**

*   `ChronicleCreated`: Emitted when a new chronicle is created (ID, author, initial dataHash).
*   `ChronicleUpdated`: Emitted when a chronicle is updated (ID, new version number, new dataHash).
*   `ChronicleFrozen`: Emitted when a chronicle is frozen (ID).
*   `ChronicleLinked`: Emitted when chronicles are linked (ID1, ID2).
*   `ChronicleMetadataAdded`: Emitted when metadata is added to a chronicle version (ID, version, key).
*   `ChronicleAttested`: Emitted when an address attests to a specific chronicle version (ID, version, attester, comment).
*   `AttestationRevoked`: Emitted when an attestation is revoked (ID, version, attester).

**Functions (Total: 27)**

1.  `createChronicle(string memory dataHash)`: Creates a new chronicle with the initial data. Mints a new ID.
2.  `updateChronicle(uint256 chronicleId, string memory newDataHash)`: Creates a new version for an existing chronicle. Only the original author can update, provided it's not frozen.
3.  `attestChronicle(uint256 chronicleId, uint256 version, string memory comment)`: Records an attestation for a specific chronicle version by the calling address. An address can only attest once per version.
4.  `revokeAttestation(uint256 chronicleId, uint256 version)`: Allows an address to remove their previously recorded attestation for a specific version.
5.  `freezeChronicle(uint256 chronicleId)`: Marks a chronicle as frozen, preventing further updates. Can only be called by the original author or the contract owner.
6.  `linkChronicles(uint256 chronicleId1, uint256 chronicleId2)`: Establishes a bidirectional link between two existing chronicles.
7.  `addMetadataToChronicleVersion(uint256 chronicleId, uint256 version, string memory key, string memory value)`: Adds a key-value metadata entry to a specific version of a chronicle.
8.  `getChronicleLatestVersion(uint256 chronicleId)`: Retrieves the details of the most recent version of a chronicle.
9.  `getChronicleVersion(uint256 chronicleId, uint256 version)`: Retrieves the details of a specific historical version of a chronicle.
10. `getChronicleAttestations(uint256 chronicleId, uint256 version)`: Retrieves the list of all attestation structs for a specific chronicle version.
11. `getAttesterProfile(address attester)`: Retrieves the attester profile information for a given address.
12. `getLinkedChronicles(uint256 chronicleId)`: Retrieves the list of chronicle IDs linked to a given chronicle.
13. `isChronicleFrozen(uint256 chronicleId)`: Checks if a specific chronicle is currently frozen.
14. `hasAttested(uint256 chronicleId, uint256 version, address attester)`: Checks if a specific address has attested to a specific chronicle version.
15. `getChronicleCount()`: Returns the total number of unique chronicles created in the system.
16. `getVersionCount(uint256 chronicleId)`: Returns the total number of versions for a specific chronicle.
17. `getAttestationCount(uint256 chronicleId, uint256 version)`: Returns the number of attestations for a specific chronicle version.
18. `getTotalAttestationCount()`: Returns the total number of attestations ever made across all chronicles and versions in the system.
19. `getAttestationDetails(uint256 chronicleId, uint256 version, uint256 index)`: Retrieves the full struct details of a specific attestation for a version by its index in the attestation array.
20. `checkAttestationThreshold(uint256 chronicleId, uint256 version, uint256 threshold)`: Checks if a specific chronicle version has met or exceeded a minimum number of unique attestations.
21. `getLatestChronicleId()`: Returns the ID that will be assigned to the next created chronicle (effectively, the count + 1).
22. `getVersionHistory(uint256 chronicleId)`: Returns an array of all available version numbers for a chronicle. (Implementation note: maybe just return the latest version count, as mapping keys aren't easily iterable externally; client can query 1..latest). Let's return the latest version count, simpler and more efficient. Rename to `getLatestVersionNumber`.
23. `getChronicleMetadata(uint256 chronicleId, uint256 version, string memory key)`: Retrieves the value of a specific metadata key for a chronicle version.
24. `getOwner()`: (Inherited from Ownable) Returns the current contract owner.
25. `setOwner(address newOwner)`: (Inherited from Ownable) Transfers ownership of the contract.
26. `renounceOwnership()`: (Inherited from Ownable) Relinquishes ownership of the contract.
27. `pause()`: (Inherited from Pausable) Pauses contract interactions (except owner functions).
28. `unpause()`: (Inherited from Pausable) Unpauses contract interactions.
29. `paused()`: (Inherited from Pausable) Checks if the contract is paused.

*Self-correction:* Function 22 `getVersionHistory` is tricky to implement efficiently on-chain. Returning the `latestVersion` number from the `Chronicle` struct is a better approach, letting the client iterate from 1 up to that number to query each version. Let's rename function 22 to `getLatestVersionNumber`. This still provides a distinct function. We have 28 functions total, well exceeding the 20 requirement.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title ChronicleLedger
 * @dev A decentralized system for creating, managing, and validating versioned historical records ("Chronicles")
 *      through on-chain attestation by multiple parties.
 *
 * Outline:
 * 1. Data Structures: Defines the structure of Attestations, ChronicleVersions, Chronicles, and AttesterProfiles.
 * 2. State Variables: Stores global state like chronicle counter, mappings for chronicles and profiles.
 * 3. Events: Logs significant actions like creation, updates, attestations, freezing, linking, etc.
 * 4. Modifiers: Custom modifiers for access control and state checks.
 * 5. Core Chronicle Management Functions: Create, update, freeze chronicles.
 * 6. Core Attestation Functions: Attest to versions, revoke attestations.
 * 7. Linking & Metadata Functions: Link chronicles, add metadata to versions.
 * 8. Query Functions (View/Pure): Retrieve chronicle/version details, attestation info, attester profiles, links, counts, status checks.
 * 9. Utility Functions: Threshold checks, latest ID/version retrieval.
 * 10. Inherited Functions: Ownable and Pausable standard functions.
 *
 * Note: Storing large amounts of data or many attestations on-chain can be gas-intensive.
 *       Data hashes (like IPFS hashes) are used for content to keep on-chain costs lower.
 *       Retrieving large lists (like all attestations for a version) might hit gas limits
 *       depending on blockchain configuration and the number of attestations.
 */
contract ChronicleLedger is Ownable, Pausable, ReentrancyGuard {

    // --- Data Structures ---

    /**
     * @dev Represents a single attestation event.
     */
    struct Attestation {
        address attester;         // The address that made the attestation.
        uint256 timestamp;        // The block timestamp when the attestation was made.
        string comment;           // An optional comment associated with the attestation.
    }

    /**
     * @dev Represents a specific version of a chronicle.
     */
    struct ChronicleVersion {
        string dataHash;                         // Hash or URI pointing to the actual data (e.g., IPFS CID).
        uint256 timestamp;                       // Timestamp when this version was created/updated.
        address author;                          // The address that created/updated this version.
        Attestation[] attestations;              // Array of attestations for THIS specific version.
        mapping(address => bool) hasAttested;    // Helper to quickly check if an address has attested to THIS version.
        mapping(string => string) metadata;      // Arbitrary key-value metadata for this version.
    }

    /**
     * @dev Represents a complete chronicle with its version history.
     */
    struct Chronicle {
        uint256 latestVersion;                      // The number of the most recent version.
        mapping(uint256 => ChronicleVersion) versions; // Mapping from version number to ChronicleVersion struct.
        uint256 creationTimestamp;                  // Timestamp when the chronicle was first created (version 1).
        bool frozen;                                // If true, no more updates are allowed for this chronicle.
        uint256[] linkedChronicleIds;               // Array of IDs of other chronicles linked to this one.
    }

    /**
     * @dev Represents a profile for an address that makes attestations.
     */
    struct AttesterProfile {
        uint256 totalAttestationsMade; // Total number of attestations made by this address across all chronicles/versions.
    }

    // --- State Variables ---

    uint256 private nextChronicleId = 1; // Counter for assigning unique chronicle IDs, starts from 1.

    mapping(uint256 => Chronicle) private chronicles; // Stores all chronicles by their ID.
    mapping(address => AttesterProfile) private attesterProfiles; // Stores attester profiles by address.

    uint256 private totalSystemAttestations = 0; // Total number of attestations made across the entire contract's history.

    // --- Events ---

    event ChronicleCreated(uint256 indexed chronicleId, address indexed author, string dataHash, uint256 timestamp);
    event ChronicleUpdated(uint256 indexed chronicleId, uint256 newVersion, address indexed author, string newDataHash, uint256 timestamp);
    event ChronicleFrozen(uint256 indexed chronicleId, uint256 timestamp);
    event ChronicleLinked(uint256 indexed chronicleId1, uint256 indexed chronicleId2, uint256 timestamp);
    event ChronicleMetadataAdded(uint256 indexed chronicleId, uint256 indexed version, string key); // Log key only for privacy/gas? or log key/value? Log key.
    event ChronicleAttested(uint256 indexed chronicleId, uint256 indexed version, address indexed attester, string comment, uint256 timestamp);
    event AttestationRevoked(uint256 indexed chronicleId, uint256 indexed version, address indexed attester, uint256 timestamp);

    // --- Modifiers ---

    /**
     * @dev Checks if a chronicle with the given ID exists.
     */
    modifier existingChronicle(uint256 chronicleId) {
        require(chronicles[chronicleId].creationTimestamp > 0, "Chronicle does not exist");
        _;
    }

    /**
     * @dev Checks if a specific version of a chronicle exists.
     */
    modifier existingChronicleVersion(uint256 chronicleId, uint256 version) {
        require(chronicles[chronicleId].versions[version].timestamp > 0, "Chronicle version does not exist");
        _;
    }

    /**
     * @dev Checks if a chronicle is not frozen.
     */
    modifier notFrozen(uint256 chronicleId) {
        require(!chronicles[chronicleId].frozen, "Chronicle is frozen");
        _;
    }

    // --- Core Chronicle Management Functions ---

    /**
     * @dev Creates a new chronicle with an initial version.
     * @param dataHash The hash or URI pointing to the content of the first version.
     * @return The ID of the newly created chronicle.
     */
    function createChronicle(string memory dataHash)
        public
        whenNotPaused
        nonReentrant
        returns (uint256)
    {
        uint256 chronicleId = nextChronicleId++;
        uint256 timestamp = block.timestamp;

        Chronicle storage chronicle = chronicles[chronicleId];
        chronicle.creationTimestamp = timestamp;
        chronicle.latestVersion = 1;
        chronicle.frozen = false; // Not frozen by default

        ChronicleVersion storage version = chronicle.versions[1];
        version.dataHash = dataHash;
        version.timestamp = timestamp;
        version.author = msg.sender; // Original creator is author of version 1

        emit ChronicleCreated(chronicleId, msg.sender, dataHash, timestamp);

        return chronicleId;
    }

    /**
     * @dev Creates a new version for an existing chronicle.
     *      Can only be called by the author of the *initial* version (version 1) of the chronicle.
     * @param chronicleId The ID of the chronicle to update.
     * @param newDataHash The hash or URI for the new version's content.
     */
    function updateChronicle(uint256 chronicleId, string memory newDataHash)
        public
        existingChronicle(chronicleId)
        notFrozen(chronicleId)
        whenNotPaused
        nonReentrant
    {
        Chronicle storage chronicle = chronicles[chronicleId];
        require(chronicle.versions[1].author == msg.sender, "Only original author (v1) can update");

        uint256 newVersion = chronicle.latestVersion + 1;
        uint256 timestamp = block.timestamp;

        ChronicleVersion storage version = chronicle.versions[newVersion];
        version.dataHash = newDataHash;
        version.timestamp = timestamp;
        version.author = msg.sender; // Author of this specific version update

        chronicle.latestVersion = newVersion;

        emit ChronicleUpdated(chronicleId, newVersion, msg.sender, newDataHash, timestamp);
    }

    /**
     * @dev Freezes a chronicle, preventing any further updates.
     *      Can be called by the original author (of version 1) or the contract owner.
     * @param chronicleId The ID of the chronicle to freeze.
     */
    function freezeChronicle(uint256 chronicleId)
        public
        existingChronicle(chronicleId)
        whenNotPaused
        nonReentrant
    {
        Chronicle storage chronicle = chronicles[chronicleId];
        require(chronicle.versions[1].author == msg.sender || owner() == msg.sender, "Only original author or owner can freeze");
        require(!chronicle.frozen, "Chronicle is already frozen");

        chronicle.frozen = true;
        emit ChronicleFrozen(chronicleId, block.timestamp);
    }

    // --- Core Attestation Functions ---

    /**
     * @dev Allows a user to attest to a specific version of a chronicle.
     *      A user can only attest once per version.
     * @param chronicleId The ID of the chronicle.
     * @param version The specific version number to attest to.
     * @param comment An optional comment for the attestation.
     */
    function attestChronicle(uint256 chronicleId, uint256 version, string memory comment)
        public
        existingChronicleVersion(chronicleId, version)
        whenNotPaused
        nonReentrant
    {
        Chronicle storage chronicle = chronicles[chronicleId];
        ChronicleVersion storage chronicleVersion = chronicle.versions[version];

        // Prevent attesting to a frozen chronicle? Or just frozen versions?
        // Let's allow attesting to *any* existing version, even if the chronicle is frozen from *updates*.
        // require(!chronicle.frozen, "Chronicle is frozen (no new attestations allowed)"); // Alternative rule

        require(!chronicleVersion.hasAttested[msg.sender], "Already attested to this version");

        Attestation memory newAttestation = Attestation({
            attester: msg.sender,
            timestamp: block.timestamp,
            comment: comment
        });

        chronicleVersion.attestations.push(newAttestation);
        chronicleVersion.hasAttested[msg.sender] = true;

        attesterProfiles[msg.sender].totalAttestationsMade++;
        totalSystemAttestations++;

        emit ChronicleAttested(chronicleId, version, msg.sender, comment, block.timestamp);
    }

    /**
     * @dev Allows a user to revoke their attestation for a specific chronicle version.
     * @param chronicleId The ID of the chronicle.
     * @param version The specific version number.
     */
    function revokeAttestation(uint256 chronicleId, uint256 version)
        public
        existingChronicleVersion(chronicleId, version)
        whenNotPaused
        nonReentrant
    {
        Chronicle storage chronicle = chronicles[chronicleId];
        ChronicleVersion storage chronicleVersion = chronicle.versions[version];

        require(chronicleVersion.hasAttested[msg.sender], "No attestation found from this address for this version");

        // Find the attestation and remove it (swap and pop for efficiency)
        bool found = false;
        for (uint i = 0; i < chronicleVersion.attestations.length; i++) {
            if (chronicleVersion.attestations[i].attester == msg.sender) {
                // Swap with the last element and pop
                chronicleVersion.attestations[i] = chronicleVersion.attestations[chronicleVersion.attestations.length - 1];
                chronicleVersion.attestations.pop();
                found = true;
                break; // Assuming only one attestation per user per version (enforced by hasAttested)
            }
        }
        require(found, "Internal error: Attestation not found despite hasAttested flag"); // Should not happen

        chronicleVersion.hasAttested[msg.sender] = false;

        // Decrement counters
        attesterProfiles[msg.sender].totalAttestationsMade--;
        totalSystemAttestations--;

        emit AttestationRevoked(chronicleId, version, msg.sender, block.timestamp);
    }

    // --- Linking & Metadata Functions ---

    /**
     * @dev Links two existing chronicles bidirectionally.
     * @param chronicleId1 The ID of the first chronicle.
     * @param chronicleId2 The ID of the second chronicle.
     */
    function linkChronicles(uint256 chronicleId1, uint256 chronicleId2)
        public
        existingChronicle(chronicleId1)
        existingChronicle(chronicleId2)
        whenNotPaused
        nonReentrant
    {
        require(chronicleId1 != chronicleId2, "Cannot link a chronicle to itself");

        Chronicle storage c1 = chronicles[chronicleId1];
        Chronicle storage c2 = chronicles[chronicleId2];

        // Prevent duplicate links. Simple check by iterating (could be optimized with a mapping for large numbers of links)
        bool alreadyLinked1 = false;
        for (uint i = 0; i < c1.linkedChronicleIds.length; i++) {
            if (c1.linkedChronicleIds[i] == chronicleId2) {
                alreadyLinked1 = true;
                break;
            }
        }
        require(!alreadyLinked1, "Chronicles are already linked");

        c1.linkedChronicleIds.push(chronicleId2);
        c2.linkedChronicleIds.push(chronicleId1); // Bidirectional link

        emit ChronicleLinked(chronicleId1, chronicleId2, block.timestamp);
    }

    /**
     * @dev Adds or updates a metadata key-value pair for a specific chronicle version.
     *      Can be called by the author of that specific version or the contract owner.
     * @param chronicleId The ID of the chronicle.
     * @param version The specific version number.
     * @param key The metadata key.
     * @param value The metadata value.
     */
    function addMetadataToChronicleVersion(uint256 chronicleId, uint256 version, string memory key, string memory value)
        public
        existingChronicleVersion(chronicleId, version)
        whenNotPaused
        nonReentrant
    {
        Chronicle storage chronicle = chronicles[chronicleId];
        ChronicleVersion storage chronicleVersion = chronicle.versions[version];

        // Allow author of the specific version OR contract owner to add/update metadata
        require(chronicleVersion.author == msg.sender || owner() == msg.sender, "Only version author or owner can add metadata");

        chronicleVersion.metadata[key] = value;

        emit ChronicleMetadataAdded(chronicleId, version, key);
    }

    // --- Query Functions (View/Pure) ---

    /**
     * @dev Retrieves the details of the most recent version of a chronicle.
     * @param chronicleId The ID of the chronicle.
     * @return ChronicleVersion struct containing the latest version's data.
     */
    function getChronicleLatestVersion(uint256 chronicleId)
        public
        view
        existingChronicle(chronicleId)
        returns (ChronicleVersion storage)
    {
        return chronicles[chronicleId].versions[chronicles[chronicleId].latestVersion];
    }

    /**
     * @dev Retrieves the details of a specific historical version of a chronicle.
     * @param chronicleId The ID of the chronicle.
     * @param version The version number.
     * @return ChronicleVersion struct containing the specified version's data.
     */
    function getChronicleVersion(uint256 chronicleId, uint256 version)
        public
        view
        existingChronicleVersion(chronicleId, version)
        returns (ChronicleVersion storage)
    {
         // Also check if version is within valid range (1 to latestVersion) for consistency, although existingChronicleVersion modifier handles the timestamp check.
        require(version > 0 && version <= chronicles[chronicleId].latestVersion, "Invalid version number");
        return chronicles[chronicleId].versions[version];
    }

    /**
     * @dev Retrieves all attestation structs for a specific chronicle version.
     * @param chronicleId The ID of the chronicle.
     * @param version The version number.
     * @return An array of Attestation structs. Note: Returning large arrays can be gas-intensive for the caller.
     */
    function getChronicleAttestations(uint256 chronicleId, uint256 version)
        public
        view
        existingChronicleVersion(chronicleId, version)
        returns (Attestation[] memory)
    {
        return chronicles[chronicleId].versions[version].attestations;
    }

    /**
     * @dev Retrieves the attester profile for a given address.
     * @param attester The address to query.
     * @return AttesterProfile struct.
     */
    function getAttesterProfile(address attester)
        public
        view
        returns (AttesterProfile storage)
    {
        return attesterProfiles[attester];
    }

    /**
     * @dev Retrieves the list of chronicle IDs linked to a given chronicle.
     * @param chronicleId The ID of the chronicle.
     * @return An array of linked chronicle IDs.
     */
    function getLinkedChronicles(uint256 chronicleId)
        public
        view
        existingChronicle(chronicleId)
        returns (uint256[] memory)
    {
        return chronicles[chronicleId].linkedChronicleIds;
    }

    /**
     * @dev Checks if a specific chronicle is currently frozen.
     * @param chronicleId The ID of the chronicle.
     * @return bool True if frozen, false otherwise.
     */
    function isChronicleFrozen(uint256 chronicleId)
        public
        view
        existingChronicle(chronicleId)
        returns (bool)
    {
        return chronicles[chronicleId].frozen;
    }

     /**
     * @dev Checks if a specific address has attested to a specific chronicle version.
     * @param chronicleId The ID of the chronicle.
     * @param version The version number.
     * @param attester The address to check.
     * @return bool True if the address has attested to this version, false otherwise.
     */
    function hasAttested(uint256 chronicleId, uint256 version, address attester)
        public
        view
        existingChronicleVersion(chronicleId, version)
        returns (bool)
    {
        return chronicles[chronicleId].versions[version].hasAttested[attester];
    }

    /**
     * @dev Returns the total number of unique chronicles created in the system.
     * @return uint256 Total chronicle count.
     */
    function getChronicleCount()
        public
        view
        returns (uint256)
    {
        return nextChronicleId - 1; // nextChronicleId is the next available ID, so count is ID - 1.
    }

    /**
     * @dev Returns the total number of versions for a specific chronicle.
     * @param chronicleId The ID of the chronicle.
     * @return uint256 Total version count.
     */
    function getLatestVersionNumber(uint256 chronicleId)
        public
        view
        existingChronicle(chronicleId)
        returns (uint256)
    {
        return chronicles[chronicleId].latestVersion;
    }

    /**
     * @dev Returns the number of attestations for a specific chronicle version.
     * @param chronicleId The ID of the chronicle.
     * @param version The version number.
     * @return uint256 Number of attestations.
     */
    function getAttestationCount(uint256 chronicleId, uint256 version)
        public
        view
        existingChronicleVersion(chronicleId, version)
        returns (uint256)
    {
        return chronicles[chronicleId].versions[version].attestations.length;
    }

    /**
     * @dev Returns the total number of attestations ever made across all chronicles and versions in the system.
     * @return uint256 Total system-wide attestation count.
     */
    function getTotalAttestationCount()
        public
        view
        returns (uint256)
    {
        return totalSystemAttestations;
    }

    /**
     * @dev Retrieves the full struct details of a specific attestation for a version by its index.
     *      Useful for iterating through attestations returned by getAttestationCount.
     * @param chronicleId The ID of the chronicle.
     * @param version The version number.
     * @param index The index of the attestation in the array.
     * @return Attestation struct.
     */
    function getAttestationDetails(uint256 chronicleId, uint256 version, uint256 index)
        public
        view
        existingChronicleVersion(chronicleId, version)
        returns (Attestation memory)
    {
        ChronicleVersion storage chronicleVersion = chronicles[chronicleId].versions[version];
        require(index < chronicleVersion.attestations.length, "Invalid attestation index");
        return chronicleVersion.attestations[index];
    }


    /**
     * @dev Checks if a specific chronicle version has met or exceeded a minimum number of unique attestations.
     * @param chronicleId The ID of the chronicle.
     * @param version The version number.
     * @param threshold The minimum required number of attestations.
     * @return bool True if the attestation count is >= threshold, false otherwise.
     */
    function checkAttestationThreshold(uint256 chronicleId, uint256 version, uint256 threshold)
        public
        view
        existingChronicleVersion(chronicleId, version)
        returns (bool)
    {
        return chronicles[chronicleId].versions[version].attestations.length >= threshold;
    }

    /**
     * @dev Returns the ID that will be assigned to the next chronicle.
     * @return uint256 The next available chronicle ID.
     */
    function getLatestChronicleId()
        public
        view
        returns (uint256)
    {
        return nextChronicleId;
    }

     /**
     * @dev Retrieves the value of a specific metadata key for a chronicle version.
     * @param chronicleId The ID of the chronicle.
     * @param version The version number.
     * @param key The metadata key.
     * @return string The metadata value. Returns an empty string if key is not found.
     */
    function getChronicleMetadata(uint256 chronicleId, uint256 version, string memory key)
        public
        view
        existingChronicleVersion(chronicleId, version)
        returns (string memory)
    {
        return chronicles[chronicleId].versions[version].metadata[key];
    }

    // --- Inherited Ownable Functions (Total 3) ---
    // getOwner()
    // setOwner(address newOwner)
    // renounceOwnership()
    // These are automatically available from the Ownable import.

    // --- Inherited Pausable Functions (Total 3) ---
    // pause()
    // unpause()
    // paused()
    // These are automatically available from the Pausable import.
}
```