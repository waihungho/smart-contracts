Okay, this is an exciting challenge! Let's build a smart contract that goes beyond typical DeFi or NFT projects, focusing on on-chain identity, reputation, and verifiable history, with conceptual hooks for future AI and verifiable credential integration.

I'll call this contract **"Chronoscribe"**. It aims to be a decentralized, self-sovereign identity and reputation system where users curate their own "Chronicles" – an evolving, soulbound digital ledger of significant life events, achievements, and attestations. These "Chronoscribes" contribute to a dynamic "Wisdom Score" and "Chronicle Level," reflecting a user's on-chain journey and credibility.

---

## Chronoscribe: On-Chain Life Ledger & Dynamic Identity System

**Concept:** Chronoscribe introduces a novel system for on-chain identity and reputation management. Each user can mint a unique, **Soulbound Chronicle (SBC)** token representing their digital persona. This Chronicle acts as a personal ledger, accumulating "Chronoscribes" – immutable records of events, achievements, and attestations. These Chronoscribes are either self-attested, endorsed by others, or verified by trusted third-party "Reputation Sources." The aggregation of Chronoscribes dynamically updates a user's "Wisdom Score" and "Chronicle Level," which are reflected in the SBC's metadata, making it a living, evolving NFT.

**Key Advanced Concepts:**

1.  **Soulbound Tokens (SBTs) for Identity:** The core `Chronicle` token is non-transferable, ensuring a persistent, verifiable identity linked to an address.
2.  **Dynamic NFT Metadata:** The `Chronicle` token's URI updates automatically based on accumulated "Chronoscribes," reflecting the owner's progress and reputation.
3.  **Verifiable Credentials (Conceptual):** `Chronoscribes` act as mini on-chain verifiable credentials, with support for external data hashes and optional third-party attestations.
4.  **Reputation System:** A multi-faceted "Wisdom Score" influenced by Chronoscribe quantity, quality, endorsements, and the trustworthiness of attesting sources.
5.  **Privacy Control:** Users can set visibility levels for their Chronoscribes (public, connections-only, private).
6.  **Social Graph Integration:** Users can establish "connections" with other Chronoscribes, allowing for a decentralized social network aspect.
7.  **Modular Event Types:** Flexible `EventType` enumeration for diverse Chronoscribes.
8.  **Oracle/Trusted Source Integration:** A system for registering and leveraging trusted external entities to verify Chronoscribes.
9.  **AI Integration (Off-chain Interface):** The structured data of Chronoscribes is designed to be easily consumed and analyzed by off-chain AI systems for insights, recommendations, or even dynamic content generation related to the Chronicle. The contract facilitates the data, the AI acts upon it.

---

### Outline & Function Summary

**I. Core Chronicle Management (Soulbound NFT)**
1.  **`mintChronicle`**: Creates a new, unique Soulbound Chronicle (SBC) NFT for the caller.
2.  **`updateChronicleDetails`**: Allows the Chronicle owner to update basic metadata (name, description).
3.  **`getChronicleDetails`**: Retrieves all core details of a Chronicle.
4.  **`getChronicleURI`**: Returns the dynamically generated metadata URI for a Chronicle.
5.  **`_updateChronicleMetadata` (Internal)**: Helper function to regenerate and update a Chronicle's metadata URI.

**II. Chronoscribe Management (Events & Attestations)**
6.  **`addSelfAttestedChronoscribe`**: Allows a Chronicle owner to add a personal, self-attested event.
7.  **`addVerifiedChronoscribe`**: Allows a registered `ReputationSource` to add a verified event to a Chronicle.
8.  **`updateChronoscribeMetadata`**: Allows the signer of a Chronoscribe to update its associated metadata URI (e.g., pointing to an IPFS image of a certificate).
9.  **`getChronoscribeDetails`**: Retrieves the full details of a specific Chronoscribe.
10. **`getChronoscribesByChronicle`**: Returns an array of `scribeIds` associated with a given Chronicle.
11. **`endorseChronoscribe`**: Allows other Chronicle owners to endorse a Chronoscribe, boosting its impact on Wisdom Score.
12. **`revokeEndorsement`**: Allows an endorser to revoke their endorsement.
13. **`setChronoscribeVisibility`**: Allows the owner of a Chronoscribe to control its public visibility.
14. **`_calculateWisdomScoreAndLevel` (Internal)**: Helper function to re-calculate a Chronicle's dynamic scores based on new/updated Chronoscribes.

**III. Reputation & Scoring System**
15. **`getWisdomScore`**: Returns the current Wisdom Score of a Chronicle.
16. **`getChronicleLevel`**: Returns the current Level of a Chronicle.

**IV. Decentralized Social Graph (Connections)**
17. **`requestConnection`**: Sends a connection request to another Chronicle owner.
18. **`acceptConnection`**: Accepts a pending connection request.
19. **`declineConnection`**: Declines a pending connection request.
20. **`removeConnection`**: Breaks an existing connection.
21. **`getConnections`**: Retrieves a list of Chronicle IDs connected to a given Chronicle.

**V. Admin & Oracle Management**
22. **`registerReputationSource`**: Allows the contract owner to register a new trusted `ReputationSource`.
23. **`updateReputationSourceTrustScore`**: Allows the contract owner to update the trust level of a registered `ReputationSource`.
24. **`pause`**: Pauses the contract in emergencies (using OpenZeppelin's `Pausable`).
25. **`unpause`**: Unpauses the contract.
26. **`setBaseURI`**: Sets the base URI for the NFT metadata, used by `tokenURI`.
27. **`withdraw`**: Allows the owner to withdraw any Ether sent to the contract (e.g., from fees, though none are implemented in this version).

**VI. Future Concepts / AI Hook (Conceptual)**
28. **`requestAIInsight` (Conceptual)**: A placeholder function to signal an off-chain AI service that a Chronicle wants an AI-generated insight based on its Chronoscribes. No on-chain AI computation.
29. **`submitAIGeneratedScribe` (Conceptual)**: Allows a whitelisted AI service to submit a special `Chronoscribe` generated from its analysis (e.g., "AI Insight: Your learning journey shows strong growth in X area").

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

/**
 * @title Chronoscribe
 * @dev A decentralized, soulbound identity and reputation system based on on-chain 'Chronoscribes'.
 *      Users mint a unique, non-transferable Chronicle (SBT) which accumulates events (Chronoscribes).
 *      These events contribute to a dynamic 'Wisdom Score' and 'Chronicle Level',
 *      reflected in the SBT's metadata, making it a living, evolving NFT.
 *      Includes features for reputation, privacy, and conceptual AI integration.
 */
contract Chronoscribe is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    Counters.Counter private _chronicleIds;
    Counters.Counter private _chronoscribeIds;

    // Mapping from Chronicle ID to Chronicle struct
    mapping(uint256 => Chronicle) public chronicles;
    // Mapping from owner address to Chronicle ID
    mapping(address => uint256) public addressToChronicleId;
    // Mapping from Chronoscribe ID to Chronoscribe struct
    mapping(uint256 => Chronoscribe) public chronoscribes;
    // Mapping from Chronicle ID to an array of its Chronoscribe IDs
    mapping(uint256 => uint256[]) public chronicleChronoscribes;

    // Connection statuses: 0=None, 1=Requested, 2=Connected
    mapping(uint256 => mapping(uint256 => uint8)) public connections; // chronicleId1 => chronicleId2 => status

    // Mapping for reputation sources (e.g., oracles, verified institutions)
    mapping(address => ReputationSource) public reputationSources;

    // Base URI for NFT metadata (e.g., IPFS gateway)
    string private _baseTokenURI;

    // --- Enums ---

    enum EventType {
        Generic,
        Achievement,
        Education,
        WorkExperience,
        CommunityContribution,
        Certification,
        Attestation,
        AIInsight // For AI-generated insights
    }

    enum Visibility {
        Public,
        ConnectionsOnly,
        Private
    }

    // --- Structs ---

    struct Chronicle {
        uint256 id;
        address owner;
        string name;
        string description;
        uint256 wisdomScore;
        uint256 level;
        uint256 createdAt;
        uint256 lastUpdated;
        bool exists; // To check if a Chronicle ID is valid
    }

    struct Chronoscribe {
        uint256 id;
        uint256 chronicleId;
        EventType eventType;
        string title;
        string description;
        string dataHash; // Hash of off-chain data (e.g., IPFS CID for a document)
        string metadataURI; // URI to specific metadata for this Chronoscribe
        address signer; // Address that added/verified this Chronoscribe
        uint256 timestamp;
        uint256 endorsementCount;
        mapping(address => bool) endorsedBy; // Who endorsed this scribe
        Visibility visibility;
    }

    struct ReputationSource {
        string name;
        string description;
        uint256 trustworthinessScore; // 1-100, higher is more trusted
        bool isRegistered;
    }

    // --- Events ---

    event ChronicleMinted(uint256 indexed chronicleId, address indexed owner, string name);
    event ChronicleUpdated(uint256 indexed chronicleId, string newName, string newDescription);
    event ChronoscribeAdded(uint256 indexed scribeId, uint256 indexed chronicleId, EventType eventType, address indexed signer);
    event ChronoscribeEndorsed(uint256 indexed scribeId, uint256 indexed chronicleId, address indexed endorser);
    event ChronoscribeVisibilitySet(uint256 indexed scribeId, Visibility newVisibility);
    event WisdomScoreUpdated(uint256 indexed chronicleId, uint256 newWisdomScore, uint256 newLevel);
    event ConnectionRequested(uint256 indexed requesterChronicleId, uint256 indexed targetChronicleId);
    event ConnectionAccepted(uint256 indexed chronicleId1, uint256 indexed chronicleId2);
    event ConnectionRemoved(uint256 indexed chronicleId1, uint256 indexed chronicleId2);
    event ReputationSourceRegistered(address indexed sourceAddress, string name, uint256 trustworthinessScore);
    event ReputationSourceUpdated(address indexed sourceAddress, uint256 newTrustworthinessScore);

    // --- Modifiers ---

    modifier onlyChronicleOwner(uint256 _chronicleId) {
        require(chronicles[_chronicleId].owner == msg.sender, "Caller is not the Chronicle owner");
        _;
    }

    modifier onlyReputationSource() {
        require(reputationSources[msg.sender].isRegistered, "Caller is not a registered reputation source");
        _;
    }

    modifier onlyChronoscribeSigner(uint256 _scribeId) {
        require(chronoscribes[_scribeId].signer == msg.sender, "Caller is not the Chronoscribe signer");
        _;
    }

    // --- Constructor ---

    constructor() ERC721("Chronoscribe Chronicle", "CHRSC") Ownable(msg.sender) Pausable() {}

    // --- I. Core Chronicle Management (Soulbound NFT) ---

    /**
     * @dev Mints a new Soulbound Chronicle (SBC) NFT for the caller.
     *      A user can only mint one Chronicle.
     * @param _name The chosen name for the Chronicle.
     * @param _description A brief description for the Chronicle.
     */
    function mintChronicle(string calldata _name, string calldata _description) external whenNotPaused {
        require(addressToChronicleId[msg.sender] == 0, "You already own a Chronicle.");

        _chronicleIds.increment();
        uint256 newId = _chronicleIds.current();

        chronicles[newId] = Chronicle({
            id: newId,
            owner: msg.sender,
            name: _name,
            description: _description,
            wisdomScore: 0,
            level: 0,
            createdAt: block.timestamp,
            lastUpdated: block.timestamp,
            exists: true
        });
        addressToChronicleId[msg.sender] = newId;

        _mint(msg.sender, newId);
        _updateChronicleMetadata(newId); // Generate initial URI

        emit ChronicleMinted(newId, msg.sender, _name);
    }

    /**
     * @dev Allows the Chronicle owner to update its name and description.
     * @param _chronicleId The ID of the Chronicle to update.
     * @param _newName The new name for the Chronicle.
     * @param _newDescription The new description for the Chronicle.
     */
    function updateChronicleDetails(
        uint256 _chronicleId,
        string calldata _newName,
        string calldata _newDescription
    ) external onlyChronicleOwner(_chronicleId) whenNotPaused {
        chronicles[_chronicleId].name = _newName;
        chronicles[_chronicleId].description = _newDescription;
        chronicles[_chronicleId].lastUpdated = block.timestamp;

        _updateChronicleMetadata(_chronicleId); // Update URI with new details
        emit ChronicleUpdated(_chronicleId, _newName, _newDescription);
    }

    /**
     * @dev Retrieves the core details of a Chronicle.
     * @param _chronicleId The ID of the Chronicle.
     * @return A tuple containing the Chronicle's ID, owner, name, description,
     *         wisdom score, level, creation timestamp, and last updated timestamp.
     */
    function getChronicleDetails(
        uint256 _chronicleId
    )
        external
        view
        returns (
            uint256 id,
            address owner,
            string memory name,
            string memory description,
            uint256 wisdomScore,
            uint256 level,
            uint256 createdAt,
            uint256 lastUpdated
        )
    {
        require(chronicles[_chronicleId].exists, "Chronicle does not exist.");
        Chronicle storage c = chronicles[_chronicleId];
        return (c.id, c.owner, c.name, c.description, c.wisdomScore, c.level, c.createdAt, c.lastUpdated);
    }

    /**
     * @dev Returns the dynamically generated metadata URI for a Chronicle.
     *      Overrides ERC721's tokenURI.
     * @param _chronicleId The ID of the Chronicle.
     * @return The URI pointing to the JSON metadata.
     */
    function getChronicleURI(uint256 _chronicleId) external view returns (string memory) {
        return tokenURI(_chronicleId);
    }

    /**
     * @dev Internal function to update the metadata URI for a Chronicle.
     *      This generates an on-chain JSON for dynamic NFT properties.
     * @param _chronicleId The ID of the Chronicle to update.
     */
    function _updateChronicleMetadata(uint256 _chronicleId) internal {
        Chronicle storage c = chronicles[_chronicleId];

        // Prepare attributes array for JSON
        string memory attributes = string(abi.encodePacked(
            "[",
            "{\"trait_type\": \"Wisdom Score\", \"value\": \"", c.wisdomScore.toString(), "\"},",
            "{\"trait_type\": \"Level\", \"value\": \"", c.level.toString(), "\"},",
            "{\"trait_type\": \"Chronoscribes Count\", \"value\": \"", chronicleChronoscribes[_chronicleId].length.toString(), "\"},",
            "{\"trait_type\": \"Created At\", \"display_type\": \"date\", \"value\": ", c.createdAt.toString(), "},"
        ));

        // Add dynamically updated 'last_updated'
        attributes = string(abi.encodePacked(
            attributes,
            "{\"trait_type\": \"Last Updated\", \"display_type\": \"date\", \"value\": ", block.timestamp.toString(), "}"
        ));

        // Append 'Soulbound' trait
        attributes = string(abi.encodePacked(
            attributes,
            ",{\"trait_type\": \"Type\", \"value\": \"Soulbound\"}"
        ));

        // Close attributes array
        attributes = string(abi.encodePacked(attributes, "]"));

        string memory json = string(abi.encodePacked(
            '{"name": "', c.name, ' - Chronicle #', c.id.toString(), '",',
            '"description": "', c.description, '",',
            '"image": "ipfs://Qmb8k75g6K2c7d9G9z9X9z9Z9z9X9z9Z9z9X9z9Z9z",', // Placeholder image (you'd replace this)
            '"attributes": ', attributes,
            '}'
        ));

        string memory base64Json = Base64.encode(bytes(json));
        _setTokenURI(_chronicleId, string(abi.encodePacked("data:application/json;base64,", base64Json)));
    }

    // --- II. Chronoscribe Management (Events & Attestations) ---

    /**
     * @dev Allows a Chronicle owner to add a self-attested Chronoscribe.
     *      These carry less weight than verified ones but build a personal narrative.
     * @param _chronicleId The ID of the Chronicle to add the scribe to.
     * @param _eventType The type of event (e.g., Achievement, Education).
     * @param _title A concise title for the event.
     * @param _description A detailed description of the event.
     * @param _dataHash A hash of off-chain data relevant to the event (e.g., IPFS CID of a document/image).
     * @param _metadataURI URI for specific metadata related to this Chronoscribe (e.g., specific NFT).
     * @param _visibility How public this Chronoscribe should be.
     */
    function addSelfAttestedChronoscribe(
        uint256 _chronicleId,
        EventType _eventType,
        string calldata _title,
        string calldata _description,
        string calldata _dataHash,
        string calldata _metadataURI,
        Visibility _visibility
    ) external onlyChronicleOwner(_chronicleId) whenNotPaused {
        _chronoscribeIds.increment();
        uint256 newScribeId = _chronoscribeIds.current();

        chronoscribes[newScribeId] = Chronoscribe({
            id: newScribeId,
            chronicleId: _chronicleId,
            eventType: _eventType,
            title: _title,
            description: _description,
            dataHash: _dataHash,
            metadataURI: _metadataURI,
            signer: msg.sender,
            timestamp: block.timestamp,
            endorsementCount: 0,
            visibility: _visibility
        });
        // Add signer to endorsedBy for self-attested
        chronoscribes[newScribeId].endorsedBy[msg.sender] = true;

        chronicleChronoscribes[_chronicleId].push(newScribeId);
        _calculateWisdomScoreAndLevel(_chronicleId); // Recalculate scores
        emit ChronoscribeAdded(newScribeId, _chronicleId, _eventType, msg.sender);
    }

    /**
     * @dev Allows a registered ReputationSource to add a verified Chronoscribe to a Chronicle.
     *      These carry more weight in the Wisdom Score calculation.
     * @param _chronicleId The ID of the Chronicle to add the scribe to.
     * @param _eventType The type of event (e.g., Certification, WorkExperience).
     * @param _title A concise title for the event.
     * @param _description A detailed description of the event.
     * @param _dataHash A hash of off-chain data relevant to the event.
     * @param _metadataURI URI for specific metadata related to this Chronoscribe.
     */
    function addVerifiedChronoscribe(
        uint256 _chronicleId,
        EventType _eventType,
        string calldata _title,
        string calldata _description,
        string calldata _dataHash,
        string calldata _metadataURI
    ) external onlyReputationSource whenNotPaused {
        require(chronicles[_chronicleId].exists, "Target Chronicle does not exist.");

        _chronoscribeIds.increment();
        uint256 newScribeId = _chronoscribeIds.current();

        // Verified chronoscribes are always public by default
        chronoscribes[newScribeId] = Chronoscribe({
            id: newScribeId,
            chronicleId: _chronicleId,
            eventType: _eventType,
            title: _title,
            description: _description,
            dataHash: _dataHash,
            metadataURI: _metadataURI,
            signer: msg.sender,
            timestamp: block.timestamp,
            endorsementCount: 1, // Automatically endorsed by the verified source
            visibility: Visibility.Public // Verified scribes are public
        });
        chronoscribes[newScribeId].endorsedBy[msg.sender] = true;

        chronicleChronoscribes[_chronicleId].push(newScribeId);
        _calculateWisdomScoreAndLevel(_chronicleId);
        emit ChronoscribeAdded(newScribeId, _chronicleId, _eventType, msg.sender);
    }

    /**
     * @dev Allows the signer of a Chronoscribe to update its associated metadata URI.
     * @param _scribeId The ID of the Chronoscribe to update.
     * @param _newMetadataURI The new URI for the Chronoscribe's specific metadata.
     */
    function updateChronoscribeMetadata(
        uint256 _scribeId,
        string calldata _newMetadataURI
    ) external onlyChronoscribeSigner(_scribeId) whenNotPaused {
        require(chronoscribes[_scribeId].chronicleId != 0, "Chronoscribe does not exist.");
        chronoscribes[_scribeId].metadataURI = _newMetadataURI;
    }

    /**
     * @dev Retrieves the details of a specific Chronoscribe, respecting visibility.
     * @param _scribeId The ID of the Chronoscribe.
     * @return A tuple containing all Chronoscribe details.
     */
    function getChronoscribeDetails(
        uint256 _scribeId
    )
        external
        view
        returns (
            uint256 id,
            uint256 chronicleId,
            EventType eventType,
            string memory title,
            string memory description,
            string memory dataHash,
            string memory metadataURI,
            address signer,
            uint256 timestamp,
            uint256 endorsementCount,
            Visibility visibility
        )
    {
        require(chronoscribes[_scribeId].chronicleId != 0, "Chronoscribe does not exist.");
        Chronoscribe storage s = chronoscribes[_scribeId];

        // Enforce visibility rules
        if (s.visibility == Visibility.Private) {
            require(msg.sender == chronicles[s.chronicleId].owner || msg.sender == s.signer, "Private Chronoscribe.");
        } else if (s.visibility == Visibility.ConnectionsOnly) {
            uint256 callerChronicleId = addressToChronicleId[msg.sender];
            require(
                msg.sender == chronicles[s.chronicleId].owner ||
                msg.sender == s.signer ||
                (callerChronicleId != 0 && (connections[s.chronicleId][callerChronicleId] == 2 || connections[callerChronicleId][s.chronicleId] == 2)),
                "Chronoscribe visible to connections only."
            );
        }

        return (
            s.id,
            s.chronicleId,
            s.eventType,
            s.title,
            s.description,
            s.dataHash,
            s.metadataURI,
            s.signer,
            s.timestamp,
            s.endorsementCount,
            s.visibility
        );
    }

    /**
     * @dev Returns an array of Chronoscribe IDs associated with a given Chronicle.
     *      Does not enforce visibility rules for the list itself, but `getChronoscribeDetails` will.
     * @param _chronicleId The ID of the Chronicle.
     * @return An array of Chronoscribe IDs.
     */
    function getChronoscribesByChronicle(uint256 _chronicleId) external view returns (uint256[] memory) {
        require(chronicles[_chronicleId].exists, "Chronicle does not exist.");
        return chronicleChronoscribes[_chronicleId];
    }

    /**
     * @dev Allows other Chronicle owners to endorse a Chronoscribe.
     *      An endorsement boosts the Chronoscribe's impact on the Wisdom Score.
     * @param _scribeId The ID of the Chronoscribe to endorse.
     */
    function endorseChronoscribe(uint256 _scribeId) external whenNotPaused {
        require(chronoscribes[_scribeId].chronicleId != 0, "Chronoscribe does not exist.");
        require(addressToChronicleId[msg.sender] != 0, "Caller must own a Chronicle to endorse.");
        require(chronoscribes[_scribeId].signer != msg.sender, "Cannot endorse your own Chronoscribe.");
        require(!chronoscribes[_scribeId].endorsedBy[msg.sender], "You have already endorsed this Chronoscribe.");

        chronoscribes[_scribeId].endorsedBy[msg.sender] = true;
        chronoscribes[_scribeId].endorsementCount++;

        // Recalculate score of the Chronoscribe's owner
        _calculateWisdomScoreAndLevel(chronoscribes[_scribeId].chronicleId);
        emit ChronoscribeEndorsed(_scribeId, chronoscribes[_scribeId].chronicleId, msg.sender);
    }

    /**
     * @dev Allows an endorser to revoke their endorsement from a Chronoscribe.
     * @param _scribeId The ID of the Chronoscribe to revoke endorsement from.
     */
    function revokeEndorsement(uint256 _scribeId) external whenNotPaused {
        require(chronoscribes[_scribeId].chronicleId != 0, "Chronoscribe does not exist.");
        require(addressToChronicleId[msg.sender] != 0, "Caller must own a Chronicle.");
        require(chronoscribes[_scribeId].endorsedBy[msg.sender], "You have not endorsed this Chronoscribe.");

        chronoscribes[_scribeId].endorsedBy[msg.sender] = false;
        chronoscribes[_scribeId].endorsementCount--;

        _calculateWisdomScoreAndLevel(chronoscribes[_scribeId].chronicleId);
        emit ChronoscribeEndorsed(_scribeId, chronoscribes[_scribeId].chronicleId, msg.sender); // Re-using event for simplicity
    }

    /**
     * @dev Allows the owner of a Chronoscribe to set its visibility.
     * @param _scribeId The ID of the Chronoscribe.
     * @param _visibility The new visibility setting.
     */
    function setChronoscribeVisibility(
        uint256 _scribeId,
        Visibility _visibility
    ) external onlyChronoscribeSigner(_scribeId) whenNotPaused {
        require(chronoscribes[_scribeId].chronicleId != 0, "Chronoscribe does not exist.");
        chronoscribes[_scribeId].visibility = _visibility;
        emit ChronoscribeVisibilitySet(_scribeId, _visibility);
    }

    /**
     * @dev Internal function to recalculate a Chronicle's Wisdom Score and Level.
     *      Called whenever a Chronoscribe is added, endorsed, or removed.
     *      The scoring logic can be made more complex (e.g., decaying scores,
     *      weighted by event type, or by reputation source trustworthiness).
     * @param _chronicleId The ID of the Chronicle to recalculate.
     */
    function _calculateWisdomScoreAndLevel(uint256 _chronicleId) internal {
        uint256 totalScore = 0;
        uint256[] storage scribes = chronicleChronoscribes[_chronicleId];

        for (uint256 i = 0; i < scribes.length; i++) {
            Chronoscribe storage s = chronoscribes[scribes[i]];
            uint256 scribeScore = 10; // Base score for any scribe

            if (reputationSources[s.signer].isRegistered) {
                // Verified scribes get a bonus based on source trustworthiness
                scribeScore += (reputationSources[s.signer].trustworthinessScore / 100) * 20; // Max 20 bonus
            } else if (s.signer == chronicles[_chronicleId].owner) {
                // Self-attested scribes are a bit lower base, but still contribute
                scribeScore = 5;
            }

            // Endorsements also boost score
            scribeScore += s.endorsementCount * 2; // Each endorsement adds 2 points

            totalScore += scribeScore;
        }

        uint256 newLevel = totalScore / 100; // 100 points per level

        // Update Chronicle struct
        chronicles[_chronicleId].wisdomScore = totalScore;
        chronicles[_chronicleId].level = newLevel;
        chronicles[_chronicleId].lastUpdated = block.timestamp;

        _updateChronicleMetadata(_chronicleId); // Update NFT metadata with new score/level
        emit WisdomScoreUpdated(_chronicleId, totalScore, newLevel);
    }

    // --- III. Reputation & Scoring System (View Functions) ---

    /**
     * @dev Returns the current Wisdom Score of a Chronicle.
     * @param _chronicleId The ID of the Chronicle.
     */
    function getWisdomScore(uint256 _chronicleId) external view returns (uint256) {
        require(chronicles[_chronicleId].exists, "Chronicle does not exist.");
        return chronicles[_chronicleId].wisdomScore;
    }

    /**
     * @dev Returns the current Level of a Chronicle.
     * @param _chronicleId The ID of the Chronicle.
     */
    function getChronicleLevel(uint256 _chronicleId) external view returns (uint256) {
        require(chronicles[_chronicleId].exists, "Chronicle does not exist.");
        return chronicles[_chronicleId].level;
    }

    // --- IV. Decentralized Social Graph (Connections) ---

    /**
     * @dev Sends a connection request from the caller's Chronicle to a target Chronicle.
     * @param _targetChronicleId The ID of the Chronicle to connect to.
     */
    function requestConnection(uint256 _targetChronicleId) external whenNotPaused {
        uint256 requesterChronicleId = addressToChronicleId[msg.sender];
        require(requesterChronicleId != 0, "Caller must own a Chronicle.");
        require(chronicles[_targetChronicleId].exists, "Target Chronicle does not exist.");
        require(requesterChronicleId != _targetChronicleId, "Cannot connect to yourself.");
        require(connections[requesterChronicleId][_targetChronicleId] == 0, "Connection already requested or exists.");

        connections[requesterChronicleId][_targetChronicleId] = 1; // Requested
        emit ConnectionRequested(requesterChronicleId, _targetChronicleId);
    }

    /**
     * @dev Accepts a pending connection request.
     * @param _requesterChronicleId The ID of the Chronicle that sent the request.
     */
    function acceptConnection(uint256 _requesterChronicleId) external onlyChronicleOwner(addressToChronicleId[msg.sender]) whenNotPaused {
        uint256 receiverChronicleId = addressToChronicleId[msg.sender];
        require(connections[_requesterChronicleId][receiverChronicleId] == 1, "No pending request from this Chronicle.");

        connections[_requesterChronicleId][receiverChronicleId] = 2; // Connected
        connections[receiverChronicleId][_requesterChronicleId] = 2; // Symmetrical connection
        emit ConnectionAccepted(_requesterChronicleId, receiverChronicleId);
    }

    /**
     * @dev Declines a pending connection request.
     * @param _requesterChronicleId The ID of the Chronicle that sent the request.
     */
    function declineConnection(uint256 _requesterChronicleId) external onlyChronicleOwner(addressToChronicleId[msg.sender]) whenNotPaused {
        uint256 receiverChronicleId = addressToChronicleId[msg.sender];
        require(connections[_requesterChronicleId][receiverChronicleId] == 1, "No pending request from this Chronicle.");

        connections[_requesterChronicleId][receiverChronicleId] = 0; // Reset
    }

    /**
     * @dev Removes an existing connection.
     * @param _targetChronicleId The ID of the Chronicle to disconnect from.
     */
    function removeConnection(uint256 _targetChronicleId) external onlyChronicleOwner(addressToChronicleId[msg.sender]) whenNotPaused {
        uint256 callerChronicleId = addressToChronicleId[msg.sender];
        require(
            connections[callerChronicleId][_targetChronicleId] == 2 || connections[_targetChronicleId][callerChronicleId] == 2,
            "No active connection with this Chronicle."
        );

        connections[callerChronicleId][_targetChronicleId] = 0; // Reset
        connections[_targetChronicleId][callerChronicleId] = 0; // Symmetrical removal
        emit ConnectionRemoved(callerChronicleId, _targetChronicleId);
    }

    /**
     * @dev Retrieves a list of Chronicle IDs connected to a given Chronicle.
     *      Note: This iterates through all potential Chronicle IDs up to the current counter,
     *      which can be gas-intensive for very large numbers of chronicles.
     *      In a real dapp, this might be handled by off-chain indexing.
     * @param _chronicleId The ID of the Chronicle.
     * @return An array of connected Chronicle IDs.
     */
    function getConnections(uint256 _chronicleId) external view returns (uint256[] memory) {
        require(chronicles[_chronicleId].exists, "Chronicle does not exist.");
        uint256[] memory connectedIds = new uint256[](_chronicleIds.current()); // Max possible size
        uint256 count = 0;

        for (uint256 i = 1; i <= _chronicleIds.current(); i++) {
            if (i == _chronicleId) continue;
            if (connections[_chronicleId][i] == 2) {
                connectedIds[count] = i;
                count++;
            }
        }

        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = connectedIds[i];
        }
        return result;
    }

    // --- V. Admin & Oracle Management ---

    /**
     * @dev Allows the contract owner to register a new trusted Reputation Source.
     *      These sources can add verified Chronoscribes with boosted impact.
     * @param _sourceAddress The address of the new reputation source.
     * @param _name The name of the source (e.g., "MIT Blockchain Lab").
     * @param _description A description of the source.
     * @param _trustworthinessScore A score from 1-100 indicating trustworthiness.
     */
    function registerReputationSource(
        address _sourceAddress,
        string calldata _name,
        string calldata _description,
        uint256 _trustworthinessScore
    ) external onlyOwner whenNotPaused {
        require(_sourceAddress != address(0), "Source address cannot be zero.");
        require(!reputationSources[_sourceAddress].isRegistered, "Source already registered.");
        require(_trustworthinessScore >= 1 && _trustworthinessScore <= 100, "Trustworthiness score must be between 1 and 100.");

        reputationSources[_sourceAddress] = ReputationSource({
            name: _name,
            description: _description,
            trustworthinessScore: _trustworthinessScore,
            isRegistered: true
        });
        emit ReputationSourceRegistered(_sourceAddress, _name, _trustworthinessScore);
    }

    /**
     * @dev Allows the contract owner to update the trustworthiness score of a registered source.
     * @param _sourceAddress The address of the reputation source.
     * @param _newTrustworthinessScore The new score from 1-100.
     */
    function updateReputationSourceTrustScore(
        address _sourceAddress,
        uint256 _newTrustworthinessScore
    ) external onlyOwner whenNotPaused {
        require(reputationSources[_sourceAddress].isRegistered, "Source not registered.");
        require(_newTrustworthinessScore >= 1 && _newTrustworthinessScore <= 100, "Trustworthiness score must be between 1 and 100.");

        reputationSources[_sourceAddress].trustworthinessScore = _newTrustworthinessScore;
        emit ReputationSourceUpdated(_sourceAddress, _newTrustworthinessScore);
    }

    /**
     * @dev Pauses the contract for emergency situations. Only callable by the owner.
     *      Inherited from OpenZeppelin's Pausable.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Only callable by the owner.
     *      Inherited from OpenZeppelin's Pausable.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Sets the base URI for the NFT metadata.
     * @param _newBaseURI The new base URI (e.g., "ipfs://your-gateway/").
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        _baseTokenURI = _newBaseURI;
    }

    /**
     * @dev Allows the contract owner to withdraw any Ether from the contract.
     *      Useful for collecting potential fees (if implemented) or accidentally sent funds.
     */
    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Withdrawal failed.");
    }

    // --- VI. Future Concepts / AI Hook (Conceptual) ---

    /**
     * @dev Conceptual function: Signals an off-chain AI service that a Chronicle wants an AI-generated insight.
     *      No on-chain AI computation happens here. This is purely for triggering off-chain processes.
     * @param _chronicleId The ID of the Chronicle requesting the insight.
     */
    function requestAIInsight(uint256 _chronicleId) external onlyChronicleOwner(_chronicleId) whenNotPaused {
        // In a real system, this would emit an event for an off-chain AI service to pick up.
        // For simplicity here, we'll just log an internal message.
        // event AIInsightRequested(uint256 indexed chronicleId, address indexed requester);
        // emit AIInsightRequested(_chronicleId, msg.sender);
    }

    /**
     * @dev Conceptual function: Allows a whitelisted AI service to submit a special Chronoscribe generated from its analysis.
     *      The AI service would need to be registered as a reputation source or a specific AI_ROLE.
     *      For this example, it simply reuses `addVerifiedChronoscribe` with a specific EventType.
     * @param _chronicleId The ID of the Chronicle the insight is for.
     * @param _title A concise title for the AI-generated insight.
     * @param _description A detailed description of the AI-generated insight.
     * @param _dataHash A hash of off-chain data relevant to the insight.
     * @param _metadataURI URI for specific metadata related to this AI Chronoscribe.
     */
    function submitAIGeneratedScribe(
        uint256 _chronicleId,
        string calldata _title,
        string calldata _description,
        string calldata _dataHash,
        string calldata _metadataURI
    ) external onlyReputationSource whenNotPaused {
        // The AI service needs to be registered as a reputation source.
        // This function simply uses the existing verified scribe mechanism but enforces EventType.AIInsight.
        addVerifiedChronoscribe(
            _chronicleId,
            EventType.AIInsight,
            _title,
            _description,
            _dataHash,
            _metadataURI
        );
    }

    // --- ERC721 Overrides for Soulbound Behavior ---

    /**
     * @dev Returns the base URI for token metadata.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Overrides `_beforeTokenTransfer` to enforce soulbound nature.
     *      Prevents any transfer of the Chronicle token once minted.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (from != address(0) && to != address(0)) {
            // Only allow transfer if it's the initial mint (from address(0))
            // or if it's burning (to address(0)).
            // Otherwise, it's a regular transfer, which is disallowed for SBT.
            revert("Chronicle is soulbound and cannot be transferred.");
        }
    }
}
```