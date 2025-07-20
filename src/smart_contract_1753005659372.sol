Okay, this is a fantastic challenge! Let's build something truly unique, leveraging concepts from Soulbound Tokens (SBTs), decentralized identity, on-chain reputation, and dynamic asset evolution, without directly copying existing projects.

I present the "MetaPersona" contract: A non-transferable, evolving on-chain identity that accumulates attributes and affiliations based on on-chain activities, can attest to data, and delegate its influence. It's a "digital twin" that grows and specializes.

---

## MetaPersona: An Evolving On-Chain Identity Protocol

### Outline

1.  **Introduction & Core Concept:**
    *   What is a MetaPersona?
    *   Why is it Soulbound?
    *   How does it evolve?
    *   Key components: Attributes, Affiliations, Challenges, Attestations, Influence Delegation.

2.  **Key Features & Advanced Concepts:**
    *   **Soulbound Tokens (SBTs):** Non-transferable ERC-721 tokens representing unique on-chain identities.
    *   **Dynamic Attributes & Progression:** Personas gain and level up specific attributes (skills, traits) through completing on-chain "Challenges" or specific interactions, increasing their "XP" and "Level."
    *   **On-Chain Attestation Framework:** Personas can cryptographically sign arbitrary data hashes on-chain, proving their endorsement or participation, verifiable by anyone.
    *   **Affiliation System:** Personas can join and leave defined on-chain communities or groups, potentially unlocking specific capabilities or collective influence.
    *   **Influence Delegation:** A Persona's accumulated influence (derived from its level, attributes, and affiliations) can be explicitly delegated to another address or Persona for governance or collective action.
    *   **Curated Challenges:** System administrators (or future DAO) can define and manage "Challenges" that, upon completion, award specific attributes and XP.
    *   **Pausable & Ownable:** Standard security patterns.
    *   **Reentrancy Guard:** For any potential future value transfers (though none exist directly in this version, good practice).
    *   **Event-Driven:** Every significant state change emits an event for off-chain indexing.

3.  **Contract Structure & Modules:**
    *   **ERC721MetaPersona:** The core SBT implementation, preventing transfers.
    *   **Persona Data Management:** Structs and mappings for Persona details, attributes, affiliations, and progression.
    *   **Attribute & Affiliation Definitions:** System-level definitions of what attributes and affiliations exist.
    *   **Challenge Management:** Definition and tracking of challenges.
    *   **Attestation Logic:** Functions for signing and verifying data.
    *   **Delegation Logic:** Functions for managing influence delegation.
    *   **Access Control:** Owner-only functions for system configuration.

### Function Summary (25 Functions)

**I. Core Persona Management (ERC-721 & Identity)**

1.  `mintPersona(address _owner, string calldata _personaName)`: Mints a new soulbound Persona token for `_owner` with a given name.
2.  `updatePersonaName(uint256 _tokenId, string calldata _newName)`: Allows the Persona owner to update their Persona's display name.
3.  `getPersonaDetails(uint256 _tokenId)`: Retrieves comprehensive details about a specific Persona.
4.  `getPersonaAttributes(uint256 _tokenId)`: Returns all attributes and their levels for a given Persona.
5.  `getPersonaAffiliations(uint256 _tokenId)`: Returns all affiliations a Persona belongs to.
6.  `_beforeTokenTransfer(address from, address to, uint256 tokenId)`: Internal OpenZeppelin hook overridden to prevent any token transfers, enforcing soulbound nature. (Not directly callable externally but critical).

**II. Attribute & Affiliation Definitions (System-Level)**

7.  `defineAttribute(string calldata _name, string calldata _description, bool _isCumulative, uint256 _maxLevel)`: Owner-only. Defines a new type of Persona attribute, specifying its properties.
8.  `updateAttributeDefinition(uint256 _attributeId, string calldata _newName, string calldata _newDescription, bool _newIsCumulative, uint256 _newMaxLevel)`: Owner-only. Modifies an existing attribute definition.
9.  `defineAffiliation(string calldata _name, string calldata _description)`: Owner-only. Defines a new type of Persona affiliation/community.
10. `updateAffiliationDefinition(uint256 _affiliationId, string calldata _newName, string calldata _newDescription)`: Owner-only. Modifies an existing affiliation definition.

**III. Persona Progression & Interaction**

11. `completeChallenge(uint256 _tokenId, uint256 _challengeId)`: Allows a Persona owner to mark a challenge as completed, awarding XP and specific attribute points.
12. `levelUpPersona(uint256 _tokenId)`: Automatically levels up a Persona if it has accumulated enough XP. Callable by anyone, but only affects the Persona owner's identity.
13. `joinAffiliation(uint256 _tokenId, uint256 _affiliationId)`: Allows a Persona to join a defined affiliation.
14. `leaveAffiliation(uint256 _tokenId, uint256 _affiliationId)`: Allows a Persona to leave a defined affiliation.

**IV. On-Chain Attestation & Verification**

15. `attestToData(uint256 _tokenId, bytes32 _dataHash, string calldata _context)`: Allows a Persona to cryptographically sign a `bytes32` hash on-chain, creating a verifiable attestation.
16. `verifyAttestation(uint256 _tokenId, bytes32 _dataHash, uint256 _attestationIndex)`: Verifies if a specific Persona made a particular attestation at a given index.

**V. Influence & Delegation**

17. `delegateInfluence(uint256 _tokenId, address _delegatee)`: Allows a Persona owner to delegate their Persona's influence to another address (can be another Persona's owner or an EOA).
18. `revokeInfluenceDelegation(uint256 _tokenId)`: Allows a Persona owner to revoke any existing influence delegation.
19. `getDelegatedInfluenceOf(uint256 _tokenId)`: Returns the address to which a Persona has delegated its influence.
20. `getIncomingDelegationsFor(address _address)`: Returns an array of Persona IDs that have delegated their influence to the specified address.

**VI. System Configuration & Governance**

21. `defineChallenge(string calldata _name, string calldata _description, uint256 _xpReward, uint256[] calldata _attributeIds, uint256[] calldata _attributeAmounts, bool _isActive)`: Owner-only. Defines a new challenge that Personas can complete.
22. `updateChallengeStatus(uint256 _challengeId, bool _isActive)`: Owner-only. Activates or deactivates a challenge.
23. `setPersonaXPForLevel(uint256 _level, uint256 _requiredXP)`: Owner-only. Sets the XP required to reach a specific Persona level.
24. `pause()`: Owner-only. Pauses all core functionalities of the contract (minting, challenge completion, etc.).
25. `unpause()`: Owner-only. Unpauses the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title MetaPersona: An Evolving On-Chain Identity Protocol
 * @dev This contract implements a Soulbound Token (SBT) representing a dynamic, evolving on-chain identity.
 *      It cannot be transferred. Personas accumulate attributes and affiliations through on-chain
 *      actions (like completing challenges), can attest to data, and delegate their influence.
 *      It aims to be a foundational layer for reputation systems, decentralized identity,
 *      and dynamic on-chain "digital twins".
 */
contract MetaPersona is ERC721, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _attributeIdCounter;
    Counters.Counter private _affiliationIdCounter;
    Counters.Counter private _challengeIdCounter;

    // Mapping from token ID to Persona details
    mapping(uint256 => Persona) public personas;

    // Mapping from attribute ID to its definition
    mapping(uint256 => AttributeDefinition) public attributeDefinitions;

    // Mapping from affiliation ID to its definition
    mapping(uint256 => AffiliationDefinition) public affiliationDefinitions;

    // Mapping from challenge ID to its definition
    mapping(uint256 => ChallengeDefinition) public challengeDefinitions;

    // XP required to reach a specific level
    mapping(uint256 => uint256) public xpForLevel;

    // Persona ID => Challenge ID => Number of completions
    mapping(uint256 => mapping(uint256 => uint256)) public challengeCompletions;

    // Persona ID => index => Attestation details
    mapping(uint256 => Attestation[]) public personaAttestations;

    // Persona ID => Address delegated to
    mapping(uint256 => address) public personaDelegation;

    // Address => array of Persona IDs that delegate to it
    mapping(address => uint256[]) private incomingDelegations;

    // --- Structs ---

    struct Persona {
        address owner;
        uint256 creationTimestamp;
        string personaName;
        uint256 level;
        uint256 xp;
        uint256 lastActivityTimestamp;
        // Attribute ID => current level/value of the attribute
        mapping(uint256 => uint256) attributes;
        // Affiliation ID => true if part of affiliation
        mapping(uint256 => bool) affiliations;
        uint256 attestationCount; // Counter for unique attestation indices
    }

    struct AttributeDefinition {
        string name;
        string description;
        bool isCumulative; // True if attribute value stacks (e.g., strength), false if it's a binary trait (e.g., has_certified)
        uint256 maxLevel; // 0 for unlimited, or specific cap
        bool exists; // To check if an ID is actually defined
    }

    struct AffiliationDefinition {
        string name;
        string description;
        bool exists;
    }

    struct ChallengeDefinition {
        string name;
        string description;
        uint256 xpReward;
        // Attribute ID => amount rewarded for this challenge
        mapping(uint256 => uint256) attributeRewards;
        uint256[] rewardedAttributeIds; // To iterate through rewarded attributes
        bool isActive;
        bool exists;
    }

    struct Attestation {
        bytes32 dataHash;
        string context;
        uint256 timestamp;
        address signerAddress; // The address that initiated the attestation (persona owner)
    }

    // --- Events ---

    event PersonaMinted(uint256 indexed tokenId, address indexed owner, string personaName, uint256 timestamp);
    event PersonaNameUpdated(uint256 indexed tokenId, string newName);
    event PersonaLeveledUp(uint256 indexed tokenId, uint256 newLevel, uint256 currentXP);
    event ChallengeDefined(uint256 indexed challengeId, string name, uint256 xpReward, bool isActive);
    event ChallengeCompleted(uint256 indexed tokenId, uint256 indexed challengeId, uint256 xpGained);
    event AttributeDefined(uint256 indexed attributeId, string name, bool isCumulative, uint256 maxLevel);
    event AttributeGained(uint256 indexed tokenId, uint256 indexed attributeId, uint256 newLevel);
    event AffiliationDefined(uint256 indexed affiliationId, string name);
    event PersonaJoinedAffiliation(uint256 indexed tokenId, uint256 indexed affiliationId);
    event PersonaLeftAffiliation(uint256 indexed tokenId, uint256 indexed affiliationId);
    event DataAttested(uint256 indexed tokenId, bytes32 indexed dataHash, string context, uint256 attestationIndex);
    event InfluenceDelegated(uint256 indexed tokenId, address indexed delegatee);
    event InfluenceRevoked(uint256 indexed tokenId, address indexed previousDelegatee);
    event XPForLevelSet(uint256 indexed level, uint256 requiredXP);

    // --- Constructor ---

    constructor() ERC721("MetaPersona", "MPR") Ownable(msg.sender) {
        // Set initial XP requirements for leveling up
        xpForLevel[1] = 0; // Level 1 requires 0 XP (initial state)
        xpForLevel[2] = 100;
        xpForLevel[3] = 250;
        xpForLevel[4] = 500;
        xpForLevel[5] = 1000;
        // ... more levels can be added later via setPersonaXPForLevel
    }

    // --- Modifiers ---

    modifier onlyPersonaOwner(uint256 _tokenId) {
        require(_exists(_tokenId), "MP: Persona does not exist");
        require(personas[_tokenId].owner == msg.sender, "MP: Not persona owner");
        _;
    }

    modifier onlyDefinedAttribute(uint256 _attributeId) {
        require(attributeDefinitions[_attributeId].exists, "MP: Attribute not defined");
        _;
    }

    modifier onlyDefinedAffiliation(uint256 _affiliationId) {
        require(affiliationDefinitions[_affiliationId].exists, "MP: Affiliation not defined");
        _;
    }

    modifier onlyActiveChallenge(uint256 _challengeId) {
        require(challengeDefinitions[_challengeId].exists, "MP: Challenge not defined");
        require(challengeDefinitions[_challengeId].isActive, "MP: Challenge is not active");
        _;
    }

    // --- I. Core Persona Management (ERC-721 & Identity) ---

    /**
     * @dev Mints a new soulbound MetaPersona token for the specified owner.
     * @param _owner The address to mint the Persona to.
     * @param _personaName The desired name for the Persona.
     * @return The tokenId of the newly minted Persona.
     */
    function mintPersona(address _owner, string calldata _personaName)
        external
        whenNotPaused
        nonReentrant
        returns (uint256)
    {
        require(bytes(_personaName).length > 0, "MP: Persona name cannot be empty");
        _tokenIdCounter.increment();
        uint256 newPersonaId = _tokenIdCounter.current();

        _mint(_owner, newPersonaId);

        Persona storage newPersona = personas[newPersonaId];
        newPersona.owner = _owner;
        newPersona.creationTimestamp = block.timestamp;
        newPersona.personaName = _personaName;
        newPersona.level = 1;
        newPersona.xp = 0;
        newPersona.lastActivityTimestamp = block.timestamp;

        emit PersonaMinted(newPersonaId, _owner, _personaName, block.timestamp);
        return newPersonaId;
    }

    /**
     * @dev Prevents any ERC-721 transfers, making the token soulbound.
     * @param from The address transferring the token.
     * @param to The address receiving the token.
     * @param tokenId The ID of the token being transferred.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId);
        // Explicitly forbid any transfer, even to self or zero address, to ensure soulbound nature.
        // The only way to remove a Persona might be a future 'burn' function with strict conditions.
        require(from == address(0) || to == address(0), "MP: Persona is Soulbound and cannot be transferred");
    }

    /**
     * @dev Allows the owner of a Persona to update its display name.
     * @param _tokenId The ID of the Persona.
     * @param _newName The new name for the Persona.
     */
    function updatePersonaName(uint256 _tokenId, string calldata _newName)
        external
        onlyPersonaOwner(_tokenId)
        whenNotPaused
    {
        require(bytes(_newName).length > 0, "MP: New name cannot be empty");
        personas[_tokenId].personaName = _newName;
        personas[_tokenId].lastActivityTimestamp = block.timestamp;
        emit PersonaNameUpdated(_tokenId, _newName);
    }

    /**
     * @dev Retrieves comprehensive details about a specific Persona.
     * @param _tokenId The ID of the Persona.
     * @return Persona details (owner, creationTimestamp, personaName, level, xp, lastActivityTimestamp).
     */
    function getPersonaDetails(uint256 _tokenId)
        external
        view
        returns (address owner, uint256 creationTimestamp, string memory personaName, uint256 level, uint256 xp, uint256 lastActivityTimestamp)
    {
        require(_exists(_tokenId), "MP: Persona does not exist");
        Persona storage p = personas[_tokenId];
        return (p.owner, p.creationTimestamp, p.personaName, p.level, p.xp, p.lastActivityTimestamp);
    }

    /**
     * @dev Returns all attributes and their levels for a given Persona.
     * @param _tokenId The ID of the Persona.
     * @return An array of attribute IDs and an array of their corresponding levels.
     */
    function getPersonaAttributes(uint256 _tokenId)
        external
        view
        returns (uint256[] memory attributeIds, uint256[] memory levels)
    {
        require(_exists(_tokenId), "MP: Persona does not exist");
        uint256 count = 0;
        // This is inefficient for large number of attributes, but there's no direct way to iterate
        // over a mapping in Solidity. A more advanced design would track attributes in an array within Persona struct
        // when they are gained. For 20 functions, this approach is acceptable for demonstration.
        // Assuming `_attributeIdCounter.current()` is not excessively large.
        uint256 totalAttributes = _attributeIdCounter.current();
        for (uint256 i = 1; i <= totalAttributes; i++) {
            if (personas[_tokenId].attributes[i] > 0) {
                count++;
            }
        }

        attributeIds = new uint256[](count);
        levels = new uint256[](count);
        uint256 j = 0;
        for (uint256 i = 1; i <= totalAttributes; i++) {
            if (personas[_tokenId].attributes[i] > 0) {
                attributeIds[j] = i;
                levels[j] = personas[_tokenId].attributes[i];
                j++;
            }
        }
        return (attributeIds, levels);
    }

    /**
     * @dev Returns all affiliations a Persona belongs to.
     * @param _tokenId The ID of the Persona.
     * @return An array of affiliation IDs.
     */
    function getPersonaAffiliations(uint256 _tokenId) external view returns (uint256[] memory) {
        require(_exists(_tokenId), "MP: Persona does not exist");
        uint256 count = 0;
        uint256 totalAffiliations = _affiliationIdCounter.current();
        for (uint256 i = 1; i <= totalAffiliations; i++) {
            if (personas[_tokenId].affiliations[i]) {
                count++;
            }
        }

        uint256[] memory affiliationIds = new uint256[](count);
        uint256 j = 0;
        for (uint256 i = 1; i <= totalAffiliations; i++) {
            if (personas[_tokenId].affiliations[i]) {
                affiliationIds[j] = i;
                j++;
            }
        }
        return affiliationIds;
    }

    // --- II. Attribute & Affiliation Definitions (System-Level) ---

    /**
     * @dev Defines a new type of Persona attribute. Only callable by the contract owner.
     * @param _name The name of the attribute (e.g., "Developer", "Analyst", "Creator").
     * @param _description A description of the attribute.
     * @param _isCumulative True if the attribute value represents a level/amount, false if it's a binary trait (0 or 1).
     * @param _maxLevel The maximum level this attribute can reach (0 for unlimited).
     * @return The ID of the newly defined attribute.
     */
    function defineAttribute(string calldata _name, string calldata _description, bool _isCumulative, uint256 _maxLevel)
        external
        onlyOwner
        whenNotPaused
        returns (uint256)
    {
        _attributeIdCounter.increment();
        uint256 newAttributeId = _attributeIdCounter.current();
        attributeDefinitions[newAttributeId] = AttributeDefinition({
            name: _name,
            description: _description,
            isCumulative: _isCumulative,
            maxLevel: _maxLevel,
            exists: true
        });
        emit AttributeDefined(newAttributeId, _name, _isCumulative, _maxLevel);
        return newAttributeId;
    }

    /**
     * @dev Updates an existing attribute definition. Only callable by the contract owner.
     * @param _attributeId The ID of the attribute to update.
     * @param _newName The new name for the attribute.
     * @param _newDescription The new description for the attribute.
     * @param _newIsCumulative The new cumulative status for the attribute.
     * @param _newMaxLevel The new maximum level for the attribute.
     */
    function updateAttributeDefinition(uint256 _attributeId, string calldata _newName, string calldata _newDescription, bool _newIsCumulative, uint256 _newMaxLevel)
        external
        onlyOwner
        whenNotPaused
        onlyDefinedAttribute(_attributeId)
    {
        AttributeDefinition storage attr = attributeDefinitions[_attributeId];
        attr.name = _newName;
        attr.description = _newDescription;
        attr.isCumulative = _newIsCumulative;
        attr.maxLevel = _newMaxLevel;
        // Re-emit AttributeDefined for clarity on update
        emit AttributeDefined(_attributeId, _newName, _newIsCumulative, _newMaxLevel);
    }


    /**
     * @dev Defines a new type of Persona affiliation/community. Only callable by the contract owner.
     * @param _name The name of the affiliation (e.g., "Web3 Builders DAO", "Early Adopter Group").
     * @param _description A description of the affiliation.
     * @return The ID of the newly defined affiliation.
     */
    function defineAffiliation(string calldata _name, string calldata _description)
        external
        onlyOwner
        whenNotPaused
        returns (uint256)
    {
        _affiliationIdCounter.increment();
        uint256 newAffiliationId = _affiliationIdCounter.current();
        affiliationDefinitions[newAffiliationId] = AffiliationDefinition({
            name: _name,
            description: _description,
            exists: true
        });
        emit AffiliationDefined(newAffiliationId, _name);
        return newAffiliationId;
    }

    /**
     * @dev Updates an existing affiliation definition. Only callable by the contract owner.
     * @param _affiliationId The ID of the affiliation to update.
     * @param _newName The new name for the affiliation.
     * @param _newDescription The new description for the affiliation.
     */
    function updateAffiliationDefinition(uint256 _affiliationId, string calldata _newName, string calldata _newDescription)
        external
        onlyOwner
        whenNotPaused
        onlyDefinedAffiliation(_affiliationId)
    {
        AffiliationDefinition storage aff = affiliationDefinitions[_affiliationId];
        aff.name = _newName;
        aff.description = _newDescription;
        // Re-emit AffiliationDefined for clarity on update
        emit AffiliationDefined(_affiliationId, _newName);
    }

    // --- III. Persona Progression & Interaction ---

    /**
     * @dev Allows a Persona owner to mark a challenge as completed.
     *      Awards XP and specified attribute points to the Persona.
     * @param _tokenId The ID of the Persona completing the challenge.
     * @param _challengeId The ID of the challenge completed.
     */
    function completeChallenge(uint256 _tokenId, uint256 _challengeId)
        external
        onlyPersonaOwner(_tokenId)
        whenNotPaused
        nonReentrant
        onlyActiveChallenge(_challengeId)
    {
        Persona storage p = personas[_tokenId];
        ChallengeDefinition storage challenge = challengeDefinitions[_challengeId];

        // Increment XP
        p.xp += challenge.xpReward;

        // Apply attribute rewards
        for (uint256 i = 0; i < challenge.rewardedAttributeIds.length; i++) {
            uint256 attrId = challenge.rewardedAttributeIds[i];
            uint256 attrAmount = challenge.attributeRewards[attrId];

            AttributeDefinition storage attrDef = attributeDefinitions[attrId];
            require(attrDef.exists, "MP: Reward attribute not defined");

            if (attrDef.isCumulative) {
                // For cumulative attributes, add to current level, respect max level
                uint256 newLevel = p.attributes[attrId] + attrAmount;
                if (attrDef.maxLevel > 0 && newLevel > attrDef.maxLevel) {
                    newLevel = attrDef.maxLevel;
                }
                p.attributes[attrId] = newLevel;
            } else {
                // For binary attributes, set to 1 if not already, otherwise ignore
                if (p.attributes[attrId] == 0) {
                    p.attributes[attrId] = 1;
                }
            }
            emit AttributeGained(_tokenId, attrId, p.attributes[attrId]);
        }

        // Track challenge completion count
        challengeCompletions[_tokenId][_challengeId]++;
        p.lastActivityTimestamp = block.timestamp;

        // Attempt to level up the Persona after challenge completion
        _tryLevelUp(p, _tokenId);

        emit ChallengeCompleted(_tokenId, _challengeId, challenge.xpReward);
    }

    /**
     * @dev Internal function to check and apply Persona level ups.
     *      Can be called after XP gain or manually by owner.
     * @param _persona The Persona storage reference.
     * @param _tokenId The ID of the Persona.
     */
    function _tryLevelUp(Persona storage _persona, uint256 _tokenId) internal {
        uint256 nextLevel = _persona.level + 1;
        uint256 requiredXP = xpForLevel[nextLevel];

        // Loop in case multiple levels are gained at once
        while (requiredXP > 0 && _persona.xp >= requiredXP) {
            _persona.level = nextLevel;
            nextLevel++;
            requiredXP = xpForLevel[nextLevel]; // Get XP for the subsequent level
            emit PersonaLeveledUp(_tokenId, _persona.level, _persona.xp);
        }
    }

    /**
     * @dev Allows a Persona to join a defined affiliation.
     * @param _tokenId The ID of the Persona.
     * @param _affiliationId The ID of the affiliation to join.
     */
    function joinAffiliation(uint256 _tokenId, uint256 _affiliationId)
        external
        onlyPersonaOwner(_tokenId)
        whenNotPaused
        onlyDefinedAffiliation(_affiliationId)
    {
        Persona storage p = personas[_tokenId];
        require(!p.affiliations[_affiliationId], "MP: Persona already in this affiliation");

        p.affiliations[_affiliationId] = true;
        p.lastActivityTimestamp = block.timestamp;
        emit PersonaJoinedAffiliation(_tokenId, _affiliationId);
    }

    /**
     * @dev Allows a Persona to leave a defined affiliation.
     * @param _tokenId The ID of the Persona.
     * @param _affiliationId The ID of the affiliation to leave.
     */
    function leaveAffiliation(uint256 _tokenId, uint256 _affiliationId)
        external
        onlyPersonaOwner(_tokenId)
        whenNotPaused
        onlyDefinedAffiliation(_affiliationId)
    {
        Persona storage p = personas[_tokenId];
        require(p.affiliations[_affiliationId], "MP: Persona is not in this affiliation");

        p.affiliations[_affiliationId] = false;
        p.lastActivityTimestamp = block.timestamp;
        emit PersonaLeftAffiliation(_tokenId, _affiliationId);
    }

    /**
     * @dev Manually attempts to level up a Persona if it meets XP requirements.
     *      Useful if XP was gained through means other than challenges, or to force a check.
     * @param _tokenId The ID of the Persona.
     */
    function levelUpPersona(uint256 _tokenId) external onlyPersonaOwner(_tokenId) whenNotPaused {
        Persona storage p = personas[_tokenId];
        uint256 initialLevel = p.level;
        _tryLevelUp(p, _tokenId);
        require(p.level > initialLevel, "MP: Not enough XP to level up");
        p.lastActivityTimestamp = block.timestamp;
    }

    // --- IV. On-Chain Attestation & Verification ---

    /**
     * @dev Allows a Persona to cryptographically attest to a specific data hash on-chain.
     *      This functions as an on-chain "signature" or endorsement from the Persona.
     * @param _tokenId The ID of the Persona making the attestation.
     * @param _dataHash The keccak256 hash of the data being attested to.
     * @param _context A string describing the context or purpose of the attestation.
     */
    function attestToData(uint256 _tokenId, bytes32 _dataHash, string calldata _context)
        external
        onlyPersonaOwner(_tokenId)
        whenNotPaused
    {
        Persona storage p = personas[_tokenId];
        uint256 attestationIndex = p.attestationCount; // Use current count as index
        personaAttestations[_tokenId].push(Attestation({
            dataHash: _dataHash,
            context: _context,
            timestamp: block.timestamp,
            signerAddress: msg.sender // Store the actual signing address (persona owner)
        }));
        p.attestationCount++;
        p.lastActivityTimestamp = block.timestamp;
        emit DataAttested(_tokenId, _dataHash, _context, attestationIndex);
    }

    /**
     * @dev Retrieves a specific attestation made by a Persona.
     * @param _tokenId The ID of the Persona.
     * @param _attestationIndex The index of the attestation (0-based).
     * @return dataHash The hash of the data attested to.
     * @return context The context string of the attestation.
     * @return timestamp The timestamp of the attestation.
     * @return signerAddress The address that signed the attestation (persona owner).
     */
    function getAttestation(uint256 _tokenId, uint256 _attestationIndex)
        external
        view
        returns (bytes32 dataHash, string memory context, uint256 timestamp, address signerAddress)
    {
        require(_exists(_tokenId), "MP: Persona does not exist");
        require(_attestationIndex < personas[_tokenId].attestationCount, "MP: Attestation index out of bounds");
        Attestation storage att = personaAttestations[_tokenId][_attestationIndex];
        return (att.dataHash, att.context, att.timestamp, att.signerAddress);
    }

    /**
     * @dev Returns the total number of attestations made by a Persona.
     * @param _tokenId The ID of the Persona.
     * @return The total number of attestations.
     */
    function getAttestationCount(uint256 _tokenId) external view returns (uint256) {
        require(_exists(_tokenId), "MP: Persona does not exist");
        return personas[_tokenId].attestationCount;
    }

    // --- V. Influence & Delegation ---

    /**
     * @dev Allows a Persona owner to delegate their Persona's influence to another address.
     *      This enables sophisticated governance models where Personas can empower representatives.
     * @param _tokenId The ID of the Persona delegating.
     * @param _delegatee The address to delegate influence to.
     */
    function delegateInfluence(uint256 _tokenId, address _delegatee)
        external
        onlyPersonaOwner(_tokenId)
        whenNotPaused
    {
        require(_delegatee != address(0), "MP: Cannot delegate to zero address");
        require(personaDelegation[_tokenId] != _delegatee, "MP: Already delegated to this address");

        address currentDelegatee = personaDelegation[_tokenId];
        if (currentDelegatee != address(0)) {
            _removeIncomingDelegation(currentDelegatee, _tokenId);
        }

        personaDelegation[_tokenId] = _delegatee;
        _addIncomingDelegation(_delegatee, _tokenId);
        personas[_tokenId].lastActivityTimestamp = block.timestamp;
        emit InfluenceDelegated(_tokenId, _delegatee);
    }

    /**
     * @dev Allows a Persona owner to revoke any existing influence delegation.
     * @param _tokenId The ID of the Persona revoking delegation.
     */
    function revokeInfluenceDelegation(uint256 _tokenId)
        external
        onlyPersonaOwner(_tokenId)
        whenNotPaused
    {
        address currentDelegatee = personaDelegation[_tokenId];
        require(currentDelegatee != address(0), "MP: No active delegation to revoke");

        _removeIncomingDelegation(currentDelegatee, _tokenId);
        delete personaDelegation[_tokenId];
        personas[_tokenId].lastActivityTimestamp = block.timestamp;
        emit InfluenceRevoked(_tokenId, currentDelegatee);
    }

    /**
     * @dev Returns the address to which a specific Persona has delegated its influence.
     * @param _tokenId The ID of the Persona.
     * @return The address the Persona has delegated to, or address(0) if none.
     */
    function getDelegatedInfluenceOf(uint256 _tokenId) external view returns (address) {
        require(_exists(_tokenId), "MP: Persona does not exist");
        return personaDelegation[_tokenId];
    }

    /**
     * @dev Returns an array of Persona IDs that have delegated their influence to the specified address.
     * @param _address The address to check for incoming delegations.
     * @return An array of Persona IDs.
     */
    function getIncomingDelegationsFor(address _address) external view returns (uint256[] memory) {
        return incomingDelegations[_address];
    }

    /**
     * @dev Internal helper to add a Persona ID to the list of incoming delegations for an address.
     * @param _delegatee The address receiving the delegation.
     * @param _tokenId The Persona ID delegating.
     */
    function _addIncomingDelegation(address _delegatee, uint256 _tokenId) internal {
        incomingDelegations[_delegatee].push(_tokenId);
    }

    /**
     * @dev Internal helper to remove a Persona ID from the list of incoming delegations for an address.
     * @param _delegatee The address whose delegations list needs to be updated.
     * @param _tokenId The Persona ID to remove.
     */
    function _removeIncomingDelegation(address _delegatee, uint256 _tokenId) internal {
        uint256[] storage delegations = incomingDelegations[_delegatee];
        for (uint256 i = 0; i < delegations.length; i++) {
            if (delegations[i] == _tokenId) {
                // Swap with last element and pop to maintain O(1) removal, order doesn't matter
                delegations[i] = delegations[delegations.length - 1];
                delegations.pop();
                break;
            }
        }
    }

    // --- VI. System Configuration & Governance ---

    /**
     * @dev Defines a new challenge that Personas can complete to earn XP and attributes.
     *      Only callable by the contract owner.
     * @param _name The name of the challenge.
     * @param _description A description of the challenge.
     * @param _xpReward The XP rewarded upon completion.
     * @param _attributeIds An array of attribute IDs that are rewarded.
     * @param _attributeAmounts An array of corresponding amounts for each rewarded attribute.
     *                          Must be same length as _attributeIds.
     * @param _isActive True if the challenge is active immediately.
     * @return The ID of the newly defined challenge.
     */
    function defineChallenge(string calldata _name, string calldata _description, uint256 _xpReward, uint256[] calldata _attributeIds, uint256[] calldata _attributeAmounts, bool _isActive)
        external
        onlyOwner
        whenNotPaused
        returns (uint256)
    {
        require(_attributeIds.length == _attributeAmounts.length, "MP: Mismatched attribute arrays");

        _challengeIdCounter.increment();
        uint256 newChallengeId = _challengeIdCounter.current();

        ChallengeDefinition storage newChallenge = challengeDefinitions[newChallengeId];
        newChallenge.name = _name;
        newChallenge.description = _description;
        newChallenge.xpReward = _xpReward;
        newChallenge.isActive = _isActive;
        newChallenge.exists = true;

        for (uint256 i = 0; i < _attributeIds.length; i++) {
            uint256 attrId = _attributeIds[i];
            require(attributeDefinitions[attrId].exists, "MP: Reward attribute ID not defined");
            newChallenge.attributeRewards[attrId] = _attributeAmounts[i];
            newChallenge.rewardedAttributeIds.push(attrId); // Store IDs for iteration
        }

        emit ChallengeDefined(newChallengeId, _name, _xpReward, _isActive);
        return newChallengeId;
    }

    /**
     * @dev Activates or deactivates an existing challenge. Only callable by the contract owner.
     * @param _challengeId The ID of the challenge to update.
     * @param _isActive The new status (true for active, false for inactive).
     */
    function updateChallengeStatus(uint256 _challengeId, bool _isActive)
        external
        onlyOwner
        whenNotPaused
    {
        require(challengeDefinitions[_challengeId].exists, "MP: Challenge does not exist");
        challengeDefinitions[_challengeId].isActive = _isActive;
        emit ChallengeDefined(_challengeId, challengeDefinitions[_challengeId].name, challengeDefinitions[_challengeId].xpReward, _isActive); // Re-emit with updated status
    }

    /**
     * @dev Sets the XP required to reach a specific Persona level. Only callable by the contract owner.
     * @param _level The target level.
     * @param _requiredXP The XP required to reach this level.
     */
    function setPersonaXPForLevel(uint256 _level, uint256 _requiredXP) external onlyOwner whenNotPaused {
        require(_level > 0, "MP: Level must be greater than 0");
        xpForLevel[_level] = _requiredXP;
        emit XPForLevelSet(_level, _requiredXP);
    }

    /**
     * @dev Pauses the contract, preventing most state-changing operations.
     *      Emergency function, only callable by the contract owner.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing operations to resume.
     *      Only callable by the contract owner.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }
}
```