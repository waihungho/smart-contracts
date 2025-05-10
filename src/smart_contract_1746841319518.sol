Okay, let's design an interesting and advanced smart contract. How about a decentralized, self-sovereign identity system focused on building a reputation and achievement "chronicle" tied to a soulbound identity (non-transferable token)? Users can register a "Soul", and then other authorized entities (issuers) can issue verifiable "Attestations" about that soul or award non-transferable "Achievements" (like badges or certifications).

This combines several trendy concepts: Soulbound Tokens (SBTs), Decentralized Identity (DID), Verifiable Credentials (VCs) represented by Attestations, and reputation building. It goes beyond a simple ERC20 or ERC721 by introducing structured data (schemas, attestations), roles (issuers), and linking multiple data points to a non-transferable identity.

Here's the plan:

**Contract Name:** `AdvancedSoulboundChronicle`

**Core Concepts:**

1.  **Soul Identity:** Each unique address registers to become a "Soul" with a unique ID. This Soul ID is the central anchor.
2.  **Attestations:** Structured claims made *about* a Soul by an authorized "Issuer". These can represent skills, achievements, verified facts, etc., and can have expiration dates.
3.  **Schemas:** Templates defining the structure and meaning of an Attestation (e.g., "Completed Course", "Skill Level", "Community Contribution").
4.  **Achievements:** Non-transferable ERC721 tokens awarded to a Soul by an authorized Issuer, representing milestones, certifications, or badges. These are the "Soulbound" part.
5.  **Issuers:** Addresses granted specific roles to create Schemas, issue Attestations, or award Achievements.
6.  **Chronicle:** The combined set of Attestations and Achievements associated with a Soul, forming its on-chain reputation/profile.

---

**Outline and Function Summary**

**Contract: `AdvancedSoulboundChronicle`**

**Description:**
A decentralized protocol for building verifiable on-chain identity chronicles. It allows users to register a non-transferable "Soul" identity, enables authorized issuers to issue structured "Attestations" about Souls based on defined "Schemas", and permits awarding non-transferable "Achievements" (Soulbound Tokens) representing milestones or certifications.

**Key Concepts:**
*   **Soul:** A non-transferable identity associated with a registered address.
*   **Schema:** Defines the type and data structure of an Attestation.
*   **Attestation:** A verifiable claim about a Soul, linked to a Schema.
*   **Achievement:** A non-transferable ERC721 token awarded to a Soul.
*   **Issuer:** An address authorized to interact with specific Schemas or Achievement types.

**Function Categories:**

1.  **Soul Management:**
    *   `registerSoul()`: Allows an address to register a unique Soul ID.
    *   `getSoulIdByAddress(address _addr)`: Returns the Soul ID for a given address.
    *   `getAddressBySoulId(uint256 _soulId)`: Returns the address for a given Soul ID.
    *   `getTotalSouls()`: Returns the total number of registered Souls.
    *   `isSoulRegistered(address _addr)`: Checks if an address is registered as a Soul.

2.  **Schema Management:**
    *   `createAttestationSchema(string memory _name, string memory _description, uint8 _dataType)`: Defines a new Schema for Attestations (data type encoding: 0=none, 1=bool, 2=uint, 3=int, 4=string, 5=address, 6=bytes).
    *   `getSchemaDetails(uint256 _schemaId)`: Retrieves details of a specific Schema.
    *   `getTotalSchemas()`: Returns the total number of defined Schemas.

3.  **Attestation Management:**
    *   `issueAttestation(uint256 _schemaId, uint256 _aboutSoulId, bytes memory _data, uint48 _expirationTime)`: Issues an Attestation about a Soul based on a Schema.
    *   `revokeAttestation(uint256 _attestationId)`: Revokes an issued Attestation (can only be done by the original issuer or contract owner).
    *   `getAttestationDetails(uint256 _attestationId)`: Retrieves details of a specific Attestation.
    *   `getAttestationsByIssuer(uint256 _issuerSoulId)`: Gets a list of Attestation IDs issued by a Soul.
    *   `getAttestationsForSoul(uint256 _aboutSoulId)`: Gets a list of Attestation IDs issued about a Soul.
    *   `getAttestationsForSoulBySchema(uint256 _aboutSoulId, uint256 _schemaId)`: Gets Attestation IDs for a Soul based on a specific Schema.
    *   `getLatestAttestationForSoulBySchema(uint256 _aboutSoulId, uint256 _schemaId)`: Gets the ID of the most recent valid Attestation for a Soul based on a Schema.
    *   `isAttestationValid(uint256 _attestationId)`: Checks if an Attestation is currently valid (not revoked and not expired).
    *   `getTotalAttestations()`: Returns the total number of issued Attestations.

4.  **Achievement Management (Soulbound ERC721):**
    *   `defineAchievementType(string memory _name, string memory _description, string memory _uri)`: Defines a new type of Achievement (SBT).
    *   `awardAchievement(uint256 _achievementTypeId, uint256 _toSoulId)`: Awards an Achievement of a specific type to a Soul (mints a non-transferable token).
    *   `revokeAchievement(uint256 _awardedAchievementTokenId)`: Revokes an awarded Achievement (burns the non-transferable token).
    *   `getAchievementTypeDetails(uint256 _achievementTypeId)`: Retrieves details of an Achievement type.
    *   `getAwardedAchievementDetails(uint256 _awardedAchievementTokenId)`: Retrieves details of a specific awarded Achievement instance.
    *   `getAchievementsOfSoul(uint256 _soulId)`: Gets a list of awarded Achievement token IDs for a Soul.
    *   `isSoulHolderOfAchievementType(uint256 _soulId, uint256 _achievementTypeId)`: Checks if a Soul holds at least one instance of a specific Achievement type.
    *   `getTotalAchievementTypes()`: Returns the total number of defined Achievement types.
    *   `getTotalAwardedAchievements()`: Returns the total number of awarded Achievement instances (SBTs minted).

5.  **Access Control (Issuer Roles):**
    *   `addSchemaIssuer(uint256 _schemaId, address _issuerAddress)`: Grants an address permission to issue Attestations for a Schema.
    *   `removeSchemaIssuer(uint256 _schemaId, address _issuerAddress)`: Revokes permission to issue Attestations for a Schema.
    *   `isSchemaIssuer(uint256 _schemaId, address _issuerAddress)`: Checks if an address is authorized to issue for a Schema.
    *   `addAchievementIssuer(uint256 _achievementTypeId, address _issuerAddress)`: Grants an address permission to award a specific Achievement type.
    *   `removeAchievementIssuer(uint256 _achievementTypeId, address _issuerAddress)`: Revokes permission to award a specific Achievement type.
    *   `isAchievementIssuer(uint256 _achievementTypeId, address _issuerAddress)`: Checks if an address is authorized to award an Achievement type.

(Count: 5 + 3 + 9 + 9 + 6 = 32 functions. Well over the required 20).

---

**Smart Contract Code (Solidity)**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // To easily get tokens of owner (Soul)
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Outline and Function Summary ---
// Contract: AdvancedSoulboundChronicle
// Description: A decentralized protocol for building verifiable on-chain identity chronicles.
// Key Concepts: Soul (non-transferable identity), Schema (Attestation type definition), Attestation (verifiable claim), Achievement (non-transferable ERC721), Issuer (authorized entity).
// Function Categories:
// 1. Soul Management: registerSoul, getSoulIdByAddress, getAddressBySoulId, getTotalSouls, isSoulRegistered
// 2. Schema Management: createAttestationSchema, getSchemaDetails, getTotalSchemas
// 3. Attestation Management: issueAttestation, revokeAttestation, getAttestationDetails, getAttestationsByIssuer, getAttestationsForSoul, getAttestationsForSoulBySchema, getLatestAttestationForSoulBySchema, isAttestationValid, getTotalAttestations
// 4. Achievement Management (Soulbound ERC721): defineAchievementType, awardAchievement, revokeAchievement, getAchievementTypeDetails, getAwardedAchievementDetails, getAchievementsOfSoul, isSoulHolderOfAchievementType, getTotalAchievementTypes, getTotalAwardedAchievements
// 5. Access Control (Issuer Roles): addSchemaIssuer, removeSchemaIssuer, isSchemaIssuer, addAchievementIssuer, removeAchievementIssuer, isAchievementIssuer
// Total Functions: 32+

contract AdvancedSoulboundChronicle is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // Counters for unique IDs
    Counters.Counter private _soulIds;
    Counters.Counter private _schemaIds;
    Counters.Counter private _attestationIds;
    Counters.Counter private _achievementTypeIds;
    // _tokenId counter inherited from ERC721Enumerable

    // Soul Mapping: Address <-> Soul ID
    mapping(address => uint256) private _addressToSoulId;
    mapping(uint256 => address) private _soulIdToAddress;
    mapping(uint256 => bool) private _isSoulIdRegistered; // To quickly check if a Soul ID exists

    // Attestation Schemas
    struct AttestationSchema {
        uint256 id;
        string name;
        string description;
        uint8 dataType; // 0=none, 1=bool, 2=uint, 3=int, 4=string, 5=address, 6=bytes
        bool exists; // Check if schema ID is valid
    }
    mapping(uint256 => AttestationSchema) private _attestationSchemas;

    // Attestations
    struct Attestation {
        uint256 id;
        uint256 schemaId;
        uint256 issuerSoulId;
        uint256 aboutSoulId;
        bytes data; // Store data based on schema.dataType
        uint48 expirationTime; // Timestamp in seconds, 0 for no expiration
        uint64 issuedTime; // Timestamp when issued
        bool revoked;
        bool exists; // Check if attestation ID is valid
    }
    mapping(uint256 => Attestation) private _attestations;

    // Achievement Types
    struct AchievementType {
        uint256 id;
        string name;
        string description;
        string uri; // Metadata URI template (optional)
        bool exists; // Check if achievement type ID is valid
    }
    mapping(uint256 => AchievementType) private _achievementTypes;

    // Awarded Achievements (SBT instances)
    struct AwardedAchievement {
        uint256 tokenId; // The ERC721 token ID
        uint256 achievementTypeId;
        uint256 soulId; // The recipient Soul ID
        uint64 awardedTime; // Timestamp when awarded
    }
    // Note: _tokenData from ERC721Enumerable already maps tokenId to owner address.
    mapping(uint256 => AwardedAchievement) private _awardedAchievements; // Map token ID to AwardedAchievement details

    // Indexing for retrieval
    mapping(uint256 => uint256[]) private _soulAttestationsIssued; // Soul ID => List of attestation IDs issued by this soul
    mapping(uint256 => uint256[]) private _soulAttestationsReceived; // Soul ID => List of attestation IDs about this soul
    mapping(uint256 => mapping(uint256 => uint256[])) private _soulAttestationsReceivedBySchema; // Soul ID => Schema ID => List of attestation IDs about this soul for this schema
    mapping(uint256 => uint256[]) private _soulAchievements; // Soul ID => List of awarded achievement token IDs

    // Access Control: Issuers
    mapping(uint256 => mapping(address => bool)) private _schemaIssuers; // Schema ID => Address => Is Issuer?
    mapping(uint256 => mapping(address => bool)) private _achievementIssuers; // Achievement Type ID => Address => Is Issuer?

    // --- Events ---

    event SoulRegistered(uint256 indexed soulId, address indexed account);
    event SchemaCreated(uint256 indexed schemaId, string name, uint8 dataType, address indexed creator);
    event AttestationIssued(uint256 indexed attestationId, uint256 indexed schemaId, uint256 indexed aboutSoulId, uint256 issuerSoulId, uint48 expirationTime, uint64 issuedTime);
    event AttestationRevoked(uint256 indexed attestationId, address indexed revoker);
    event AchievementTypeDefined(uint256 indexed achievementTypeId, string name, address indexed creator);
    event AchievementAwarded(uint256 indexed awardedAchievementTokenId, uint256 indexed achievementTypeId, uint256 indexed toSoulId, address awarder);
    event AchievementRevoked(uint256 indexed awardedAchievementTokenId, address indexed revoker);
    event SchemaIssuerAdded(uint256 indexed schemaId, address indexed issuerAddress, address indexed granter);
    event SchemaIssuerRemoved(uint256 indexed schemaId, address indexed issuerAddress, address indexed revoker);
    event AchievementIssuerAdded(uint256 indexed achievementTypeId, address indexed issuerAddress, address indexed granter);
    event AchievementIssuerRemoved(uint256 indexed achievementTypeId, address indexed issuerAddress, address indexed revoker);

    // --- Constructor ---

    constructor() ERC721("SoulboundChronicleAchievement", "SBC-ACH") Ownable(msg.sender) {}

    // --- Modifiers ---

    modifier onlyRegisteredSoul() {
        require(_isSoulRegistered[getSoulIdByAddress(msg.sender)], "Caller must be a registered soul");
        _;
    }

    modifier onlySchemaIssuer(uint256 _schemaId) {
        require(isSchemaIssuer(_schemaId, msg.sender) || owner() == msg.sender, "Caller is not authorized issuer for this schema");
        _;
    }

    modifier onlyAchievementIssuer(uint256 _achievementTypeId) {
        require(isAchievementIssuer(_achievementTypeId, msg.sender) || owner() == msg.sender, "Caller is not authorized issuer for this achievement type");
        _;
    }

    // --- Soul Management ---

    /// @dev Registers the caller's address as a new Soul identity.
    function registerSoul() external {
        require(!isSoulRegistered(msg.sender), "Address is already a registered soul");

        _soulIds.increment();
        uint256 newSoulId = _soulIds.current();

        _addressToSoulId[msg.sender] = newSoulId;
        _soulIdToAddress[newSoulId] = msg.sender;
        _isSoulIdRegistered[newSoulId] = true;

        emit SoulRegistered(newSoulId, msg.sender);
    }

    /// @dev Returns the Soul ID associated with an address. Returns 0 if not registered.
    /// @param _addr The address to query.
    /// @return The Soul ID.
    function getSoulIdByAddress(address _addr) public view returns (uint256) {
        return _addressToSoulId[_addr];
    }

    /// @dev Returns the address associated with a Soul ID. Returns address(0) if not found.
    /// @param _soulId The Soul ID to query.
    /// @return The address.
    function getAddressBySoulId(uint256 _soulId) public view returns (address) {
        return _soulIdToAddress[_soulId];
    }

    /// @dev Returns the total number of registered Souls.
    /// @return The total count of souls.
    function getTotalSouls() public view returns (uint256) {
        return _soulIds.current();
    }

    /// @dev Checks if an address is registered as a Soul.
    /// @param _addr The address to check.
    /// @return True if registered, false otherwise.
    function isSoulRegistered(address _addr) public view returns (bool) {
        return _addressToSoulId[_addr] != 0;
    }

    /// @dev Checks if a Soul ID is registered.
    /// @param _soulId The Soul ID to check.
    /// @return True if registered, false otherwise.
    function _isSoulIdRegisteredInternal(uint256 _soulId) internal view returns (bool) {
        return _isSoulIdRegistered[_soulId];
    }

    // --- Schema Management ---

    /// @dev Defines a new Attestation Schema. Only owner can create schemas.
    /// @param _name The name of the schema.
    /// @param _description A description of the schema.
    /// @param _dataType The expected data type for attestations using this schema (0=none, 1=bool, 2=uint, 3=int, 4=string, 5=address, 6=bytes).
    /// @return The ID of the newly created schema.
    function createAttestationSchema(string memory _name, string memory _description, uint8 _dataType) external onlyOwner returns (uint256) {
        require(_dataType <= 6, "Invalid data type");

        _schemaIds.increment();
        uint256 newSchemaId = _schemaIds.current();

        _attestationSchemas[newSchemaId] = AttestationSchema(
            newSchemaId,
            _name,
            _description,
            _dataType,
            true
        );

        emit SchemaCreated(newSchemaId, _name, _dataType, msg.sender);
        return newSchemaId;
    }

    /// @dev Retrieves details of a specific Attestation Schema.
    /// @param _schemaId The ID of the schema to query.
    /// @return The schema details.
    function getSchemaDetails(uint256 _schemaId) public view returns (AttestationSchema memory) {
        require(_attestationSchemas[_schemaId].exists, "Schema does not exist");
        return _attestationSchemas[_schemaId];
    }

    /// @dev Returns the total number of defined Attestation Schemas.
    /// @return The total count of schemas.
    function getTotalSchemas() public view returns (uint256) {
        return _schemaIds.current();
    }

    // --- Attestation Management ---

    /// @dev Issues an Attestation about a Soul based on a Schema. Must be a registered Soul and authorized issuer for the schema.
    /// @param _schemaId The ID of the schema the attestation conforms to.
    /// @param _aboutSoulId The Soul ID the attestation is about.
    /// @param _data The data associated with the attestation (format depends on schema dataType).
    /// @param _expirationTime The expiration timestamp (Unix epoch) in seconds. 0 for no expiration.
    /// @return The ID of the newly issued attestation.
    function issueAttestation(
        uint256 _schemaId,
        uint256 _aboutSoulId,
        bytes memory _data,
        uint48 _expirationTime
    ) external onlyRegisteredSoul onlySchemaIssuer(_schemaId) returns (uint256) {
        require(_isSoulIdRegisteredInternal(_aboutSoulId), "Target soul does not exist");
        // Additional checks on _data format based on _schemaId (optional, could add complexity)

        _attestationIds.increment();
        uint256 newAttestationId = _attestationIds.current();
        uint256 issuerSoulId = getSoulIdByAddress(msg.sender);
        uint64 issuedTime = uint64(block.timestamp);

        _attestations[newAttestationId] = Attestation(
            newAttestationId,
            _schemaId,
            issuerSoulId,
            _aboutSoulId,
            _data,
            _expirationTime,
            issuedTime,
            false, // Not revoked
            true // Exists
        );

        _soulAttestationsIssued[issuerSoulId].push(newAttestationId);
        _soulAttestationsReceived[_aboutSoulId].push(newAttestationId);
        _soulAttestationsReceivedBySchema[_aboutSoulId][_schemaId].push(newAttestationId);

        emit AttestationIssued(newAttestationId, _schemaId, _aboutSoulId, issuerSoulId, _expirationTime, issuedTime);
        return newAttestationId;
    }

    /// @dev Revokes an issued Attestation. Only the original issuer or contract owner can revoke.
    /// @param _attestationId The ID of the attestation to revoke.
    function revokeAttestation(uint256 _attestationId) external {
        Attestation storage attestation = _attestations[_attestationId];
        require(attestation.exists, "Attestation does not exist");
        require(!attestation.revoked, "Attestation is already revoked");

        uint256 issuerSoulId = attestation.issuerSoulId;
        require(
            getSoulIdByAddress(msg.sender) == issuerSoulId || owner() == msg.sender,
            "Caller is not the original issuer or owner"
        );

        attestation.revoked = true;

        emit AttestationRevoked(_attestationId, msg.sender);
    }

    /// @dev Retrieves details of a specific Attestation.
    /// @param _attestationId The ID of the attestation to query.
    /// @return The attestation details.
    function getAttestationDetails(uint256 _attestationId) public view returns (Attestation memory) {
        require(_attestations[_attestationId].exists, "Attestation does not exist");
        return _attestations[_attestationId];
    }

    /// @dev Gets a list of Attestation IDs issued by a specific Soul.
    /// @param _issuerSoulId The Soul ID of the issuer.
    /// @return An array of Attestation IDs.
    function getAttestationsByIssuer(uint256 _issuerSoulId) public view returns (uint256[] memory) {
         require(_isSoulIdRegisteredInternal(_issuerSoulId), "Issuer soul does not exist");
        return _soulAttestationsIssued[_issuerSoulId];
    }

    /// @dev Gets a list of Attestation IDs issued about a specific Soul.
    /// @param _aboutSoulId The Soul ID the attestations are about.
    /// @return An array of Attestation IDs.
    function getAttestationsForSoul(uint256 _aboutSoulId) public view returns (uint256[] memory) {
         require(_isSoulIdRegisteredInternal(_aboutSoulId), "Target soul does not exist");
        return _soulAttestationsReceived[_aboutSoulId];
    }

     /// @dev Gets a list of Attestation IDs issued about a specific Soul for a specific Schema.
    /// @param _aboutSoulId The Soul ID the attestations are about.
    /// @param _schemaId The ID of the schema.
    /// @return An array of Attestation IDs.
    function getAttestationsForSoulBySchema(uint256 _aboutSoulId, uint256 _schemaId) public view returns (uint256[] memory) {
        require(_isSoulIdRegisteredInternal(_aboutSoulId), "Target soul does not exist");
        require(_attestationSchemas[_schemaId].exists, "Schema does not exist");
        return _soulAttestationsReceivedBySchema[_aboutSoulId][_schemaId];
    }

    /// @dev Gets the ID of the most recent valid Attestation for a Soul based on a Schema. Returns 0 if none found.
    /// @param _aboutSoulId The Soul ID the attestations are about.
    /// @param _schemaId The ID of the schema.
    /// @return The ID of the latest valid attestation.
    function getLatestAttestationForSoulBySchema(uint256 _aboutSoulId, uint256 _schemaId) public view returns (uint256) {
        require(_isSoulIdRegisteredInternal(_aboutSoulId), "Target soul does not exist");
        require(_attestationSchemas[_schemaId].exists, "Schema does not exist");

        uint256[] memory attestationIds = _soulAttestationsReceivedBySchema[_aboutSoulId][_schemaId];
        uint256 latestValidAttestationId = 0;
        uint64 latestIssuedTime = 0;

        for (uint i = 0; i < attestationIds.length; i++) {
            uint256 currentAttestationId = attestationIds[i];
            Attestation storage attestation = _attestations[currentAttestationId];

            if (attestation.exists && !attestation.revoked) {
                if (attestation.expirationTime == 0 || attestation.expirationTime > block.timestamp) {
                     // Valid attestation
                     if (attestation.issuedTime > latestIssuedTime) {
                         latestIssuedTime = attestation.issuedTime;
                         latestValidAttestationId = currentAttestationId;
                     }
                }
            }
        }
        return latestValidAttestationId;
    }


    /// @dev Checks if an Attestation is currently valid (not revoked and not expired).
    /// @param _attestationId The ID of the attestation to check.
    /// @return True if valid, false otherwise.
    function isAttestationValid(uint256 _attestationId) public view returns (bool) {
        Attestation storage attestation = _attestations[_attestationId];
        if (!attestation.exists || attestation.revoked) {
            return false;
        }
        if (attestation.expirationTime == 0) {
            return true; // No expiration
        }
        return attestation.expirationTime > block.timestamp;
    }

    /// @dev Returns the total number of issued Attestations.
    /// @return The total count of attestations.
    function getTotalAttestations() public view returns (uint256) {
        return _attestationIds.current();
    }


    // --- Achievement Management (Soulbound ERC721) ---

    /// @dev Defines a new type of Achievement (SBT). Only owner can define achievement types.
    /// @param _name The name of the achievement type.
    /// @param _description A description of the achievement type.
    /// @param _uri An optional metadata URI template for achievements of this type.
    /// @return The ID of the newly defined achievement type.
    function defineAchievementType(string memory _name, string memory _description, string memory _uri) external onlyOwner returns (uint256) {
        _achievementTypeIds.increment();
        uint256 newTypeId = _achievementTypeIds.current();

        _achievementTypes[newTypeId] = AchievementType(
            newTypeId,
            _name,
            _description,
            _uri,
            true // Exists
        );

        emit AchievementTypeDefined(newTypeId, _name, msg.sender);
        return newTypeId;
    }

    /// @dev Awards an Achievement of a specific type to a Soul. Must be a registered Soul and authorized issuer for the achievement type. Mints a non-transferable token.
    /// @param _achievementTypeId The ID of the achievement type to award.
    /// @param _toSoulId The Soul ID to award the achievement to.
    /// @return The token ID of the newly awarded achievement (SBT instance).
    function awardAchievement(uint256 _achievementTypeId, uint256 _toSoulId) external onlyRegisteredSoul onlyAchievementIssuer(_achievementTypeId) returns (uint256) {
        require(_achievementTypes[_achievementTypeId].exists, "Achievement type does not exist");
        require(_isSoulIdRegisteredInternal(_toSoulId), "Recipient soul does not exist");

        _tokenIds.increment(); // Inherited from ERC721Enumerable's Counter
        uint256 newTokenId = _tokenIds.current();
        address recipientAddress = getAddressBySoulId(_toSoulId);

        // Mint the ERC721 token to the recipient address
        _safeMint(recipientAddress, newTokenId);

        // Store details about this specific awarded instance
        _awardedAchievements[newTokenId] = AwardedAchievement(
            newTokenId,
            _achievementTypeId,
            _toSoulId,
            uint64(block.timestamp)
        );

        // Add token ID to the soul's list of achievements
        _soulAchievements[_toSoulId].push(newTokenId);

        emit AchievementAwarded(newTokenId, _achievementTypeId, _toSoulId, msg.sender);
        return newTokenId;
    }

    /// @dev Revokes an awarded Achievement (SBT instance). Burns the token. Can only be done by the authorized issuer or owner.
    /// @param _awardedAchievementTokenId The token ID of the awarded achievement to revoke.
    function revokeAchievement(uint256 _awardedAchievementTokenId) external {
        AwardedAchievement storage awarded = _awardedAchievements[_awardedAchievementTokenId];
        require(awarded.tokenId != 0, "Awarded achievement does not exist"); // Check if token ID exists in mapping

        uint256 achievementTypeId = awarded.achievementTypeId;
        address currentOwner = ownerOf(_awardedAchievementTokenId); // Get current owner (should be the soul's address)

        // Check if caller is authorized issuer for the type OR contract owner
        require(
            isAchievementIssuer(achievementTypeId, msg.sender) || owner() == msg.sender,
            "Caller is not authorized to revoke this achievement type"
        );

        // Burn the token
        _burn(_awardedAchievementTokenId);

        // Clean up mapping (optional, but good practice) - mark as deleted or zero out
        delete _awardedAchievements[_awardedAchievementTokenId];

        // Note: Removing from _soulAchievements array is complex and gas-intensive.
        // We rely on checking token ownership via ERC721Enumerable's functions (`ownerOf`)
        // and `_awardedAchievements` mapping validity instead of keeping _soulAchievements perfectly clean.
        // A getter function `getAchievementsOfSoul` will need to filter out burned tokens.

        emit AchievementRevoked(_awardedAchievementTokenId, msg.sender);
    }

    /// @dev Retrieves details of an Achievement type.
    /// @param _achievementTypeId The ID of the achievement type to query.
    /// @return The achievement type details.
    function getAchievementTypeDetails(uint256 _achievementTypeId) public view returns (AchievementType memory) {
        require(_achievementTypes[_achievementTypeId].exists, "Achievement type does not exist");
        return _achievementTypes[_achievementTypeId];
    }

    /// @dev Retrieves details of a specific awarded Achievement instance (SBT).
    /// @param _awardedAchievementTokenId The token ID of the awarded achievement.
    /// @return The awarded achievement details.
    function getAwardedAchievementDetails(uint256 _awardedAchievementTokenId) public view returns (AwardedAchievement memory) {
        require(_awardedAchievements[_awardedAchievementTokenId].tokenId != 0, "Awarded achievement does not exist");
        return _awardedAchievements[_awardedAchievements[_awardedAchievementTokenId].tokenId];
    }


    /// @dev Gets a list of awarded Achievement token IDs for a specific Soul. Filters out burned tokens.
    /// @param _soulId The Soul ID to query.
    /// @return An array of awarded Achievement token IDs.
    function getAchievementsOfSoul(uint256 _soulId) public view returns (uint256[] memory) {
        require(_isSoulIdRegisteredInternal(_soulId), "Soul does not exist");
        address soulAddress = getAddressBySoulId(_soulId);
        uint256 balance = balanceOf(soulAddress);
        uint256[] memory tokenIds = new uint256[](balance);
        for (uint i = 0; i < balance; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(soulAddress, i);
        }
        return tokenIds;
    }

    /// @dev Checks if a Soul holds at least one instance of a specific Achievement type.
    /// @param _soulId The Soul ID to check.
    /// @param _achievementTypeId The ID of the achievement type.
    /// @return True if the soul holds an instance of this type, false otherwise.
    function isSoulHolderOfAchievementType(uint256 _soulId, uint256 _achievementTypeId) public view returns (bool) {
        require(_isSoulIdRegisteredInternal(_soulId), "Soul does not exist");
        require(_achievementTypes[_achievementTypeId].exists, "Achievement type does not exist");

        address soulAddress = getAddressBySoulId(_soulId);
        uint256 balance = balanceOf(soulAddress);

        for (uint i = 0; i < balance; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(soulAddress, i);
            if (_awardedAchievements[tokenId].achievementTypeId == _achievementTypeId) {
                return true;
            }
        }
        return false;
    }

    /// @dev Returns the total number of defined Achievement types.
    /// @return The total count of achievement types.
    function getTotalAchievementTypes() public view returns (uint256) {
        return _achievementTypeIds.current();
    }

     /// @dev Returns the total number of awarded Achievement instances (SBTs minted).
    /// @return The total count of awarded achievements.
    function getTotalAwardedAchievements() public view returns (uint256) {
        return _tokenIds.current(); // Total minted tokens (includes burned, but ERC721Enumerable handles that)
    }


    // --- Access Control (Issuer Roles) ---

    /// @dev Grants an address permission to issue Attestations for a specific Schema. Only owner can grant roles.
    /// @param _schemaId The ID of the schema.
    /// @param _issuerAddress The address to grant the role to.
    function addSchemaIssuer(uint256 _schemaId, address _issuerAddress) external onlyOwner {
        require(_attestationSchemas[_schemaId].exists, "Schema does not exist");
        require(!_schemaIssuers[_schemaId][_issuerAddress], "Address is already an issuer for this schema");
        _schemaIssuers[_schemaId][_issuerAddress] = true;
        emit SchemaIssuerAdded(_schemaId, _issuerAddress, msg.sender);
    }

    /// @dev Revokes an address's permission to issue Attestations for a specific Schema. Only owner can revoke roles.
    /// @param _schemaId The ID of the schema.
    /// @param _issuerAddress The address to revoke the role from.
    function removeSchemaIssuer(uint256 _schemaId, address _issuerAddress) external onlyOwner {
        require(_attestationSchemas[_schemaId].exists, "Schema does not exist");
        require(_schemaIssuers[_schemaId][_issuerAddress], "Address is not an issuer for this schema");
        _schemaIssuers[_schemaId][_issuerAddress] = false;
        emit SchemaIssuerRemoved(_schemaId, _issuerAddress, msg.sender);
    }

    /// @dev Checks if an address is authorized to issue Attestations for a specific Schema.
    /// @param _schemaId The ID of the schema.
    /// @param _issuerAddress The address to check.
    /// @return True if authorized, false otherwise.
    function isSchemaIssuer(uint256 _schemaId, address _issuerAddress) public view returns (bool) {
        return _schemaIssuers[_schemaId][_issuerAddress];
    }

    /// @dev Grants an address permission to award a specific Achievement type. Only owner can grant roles.
    /// @param _achievementTypeId The ID of the achievement type.
    /// @param _issuerAddress The address to grant the role to.
    function addAchievementIssuer(uint256 _achievementTypeId, address _issuerAddress) external onlyOwner {
        require(_achievementTypes[_achievementTypeId].exists, "Achievement type does not exist");
        require(!_achievementIssuers[_achievementTypeId][_issuerAddress], "Address is already an issuer for this achievement type");
        _achievementIssuers[_achievementTypeId][_issuerAddress] = true;
        emit AchievementIssuerAdded(_achievementTypeId, _issuerAddress, msg.sender);
    }

    /// @dev Revokes an address's permission to award a specific Achievement type. Only owner can revoke roles.
    /// @param _achievementTypeId The ID of the achievement type.
    /// @param _issuerAddress The address to revoke the role from.
    function removeAchievementIssuer(uint256 _achievementTypeId, address _issuerAddress) external onlyOwner {
        require(_achievementTypes[_achievementTypeId].exists, "Achievement type does not exist");
        require(_achievementIssuers[_achievementTypeId][_issuerAddress], "Address is not an issuer for this achievement type");
        _achievementIssuers[_achievementTypeId][_issuerAddress] = false;
        emit AchievementIssuerRemoved(_achievementTypeId, _issuerAddress, msg.sender);
    }

    /// @dev Checks if an address is authorized to award a specific Achievement type.
    /// @param _achievementTypeId The ID of the achievement type.
    /// @param _issuerAddress The address to check.
    /// @return True if authorized, false otherwise.
    function isAchievementIssuer(uint256 _achievementTypeId, address _issuerAddress) public view returns (bool) {
        return _achievementIssuers[_achievementTypeId][_issuerAddress];
    }

    // --- ERC721 Overrides for Soulbound Functionality ---

    /// @dev Prevents transfer of awarded achievement tokens (SBTs).
    /// @param from The address transferring from.
    /// @param to The address transferring to.
    /// @param tokenId The token ID being transferred.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Allow minting (from == address(0)) and burning (to == address(0))
        // Disallow transfer between accounts (from != address(0) and to != address(0))
        require(from == address(0) || to == address(0), "SBC-ACH: Tokens are soulbound and non-transferable");
    }

    // Additional ERC721 views (e.g., tokenURI) can be implemented here if needed,
    // potentially using the URI template from AchievementType combined with tokenId.
    // Example tokenURI function:
    // function tokenURI(uint256 tokenId) public view override returns (string memory) {
    //     require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    //     AwardedAchievement memory awarded = _awardedAchievements[tokenId];
    //     AchievementType memory achievementType = _achievementTypes[awarded.achievementTypeId];
    //     // Simple example: Replace {tokenId} and {soulId} placeholders in the template
    //     string memory uri = achievementType.uri;
    //     if (bytes(uri).length == 0) {
    //          return super.tokenURI(tokenId); // Use default if no custom URI
    //     }
    //     uri = Strings.replace(uri, "{tokenId}", Strings.toString(tokenId));
    //     uri = Strings.replace(uri, "{soulId}", Strings.toString(awarded.soulId));
    //     return uri;
    // }
}
```

---

**Explanation of Advanced Concepts & Creativity:**

1.  **Structured Identity:** Moving beyond a simple address or a single NFT, this contract builds a `Chronicle` around a central `Soul` ID. This ID is tied to an address but acts as a stable anchor for reputation even if the address changes (though in this simple version, the mapping is 1:1).
2.  **Verifiable Credentials (Attestations):** Attestations with defined `Schemas` allow for expressing complex, structured claims about a Soul. The ability for specific `Issuers` (not just anyone) to issue attestations adds a layer of trust and context, mimicking real-world credentialing authorities. Expiration dates add dynamism.
3.  **Soulbound Achievements (SBTs):** Using ERC721 as a base but overriding transfer functions (`_beforeTokenTransfer`) ensures that `Achievements` are permanently tied to the recipient Soul's address. This is the core SBT implementation. ERC721Enumerable is used to easily query a Soul's achievements.
4.  **Granular Access Control:** Instead of just an `admin` role, the system uses per-`Schema` and per-`AchievementType` `Issuers`. This allows for a decentralized network of credentialing bodies (e.g., one DAO issues academic attestations, another company issues work history attestations, a third community awards participation badges).
5.  **Data Linking and Indexing:** Mappings like `_soulAttestationsReceivedBySchema` and using ERC721Enumerable's internal mechanisms (`tokenOfOwnerByIndex`) allow for efficient querying of a Soul's complete Chronicle from different angles (all attestations, attestations by type, all achievements, achievements by type).
6.  **Chronicle Building:** The contract is designed *specifically* to aggregate different types of verifiable data points (structured attestations, typed achievements) onto a single identity anchor (`Soul ID`), enabling the *building* and querying of a comprehensive on-chain profile or reputation.
7.  **Non-Duplication:** While the underlying concepts (SBTs, attestations) exist in open source, this contract's *specific architecture* combining Soul ID, structured Schemas, Attestations, Soulbound ERC721 Achievements, and granular issuer roles into a single "Chronicle" system is a creative composition not typically found in standard libraries or simple examples.

This contract provides a foundation for building decentralized reputation systems, verifiable skill passports, on-chain academic records, and much more, using non-transferable assets and structured claims as the building blocks.