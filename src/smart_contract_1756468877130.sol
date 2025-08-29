```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title AethermindCompanionLab
 * @author [Your Pseudonym/Organization Name]
 * @notice A contract for managing Adaptive AI-Augmented Digital Companions (AADCs) as dynamic NFTs.
 *         AADCs are digital entities that evolve through skill acquisition, experience points, and decentralized attestations.
 *         This system enables on-chain verifiable progression, a reputation framework, and interactive elements for digital entities.
 *         The "AI-Augmented" aspect refers to the thematic categorization of skills (e.g., "Generative AI", "Data Analysis AI")
 *         and the conceptual use of these companions in AI-driven decentralized applications, while actual AI computation remains off-chain.
 *
 * @dev This contract demonstrates advanced concepts like dynamic NFTs, a decentralized attestation registry,
 *      and an on-chain reputation system, all integrated into a unique digital companion framework.
 *      It aims to provide a robust platform for verifiable skill progression and interactive digital assets.
 */

// OUTLINE:
// 1.  Core AADC (NFT) Management: Functions for minting, burning, transferring, and retrieving basic AADC details.
// 2.  Skill System: Management of definable skills, their acquisition by AADCs, experience points (XP) gain, and leveling up.
// 3.  Attestation Registry: A decentralized system allowing trusted entities (Attesters) to verify and attest to an AADC's skills.
// 4.  AADC Dynamic Attributes & Interaction: Functions for managing mutable AADC attributes like name, energy, and temperament, and simulating interaction.
// 5.  Reputation & Analytics: Functions to calculate an AADC's overall reputation based on its skills and attestations.
// 6.  Configuration & Admin: Administrative functions for contract owner to manage skills, attesters, and global settings.

// FUNCTION SUMMARY:
// (Custom functions + relevant ERC721/Ownable/Pausable functions for clarity)

// I. Core AADC (NFT) Management
// 1.  constructor(string memory _name, string memory _symbol): Initializes the ERC721 contract with a name and symbol.
// 2.  mintAADC(string memory _name, uint256 _initialTemperament): Mints a new AADC NFT with an initial name and temperament for the caller.
// 3.  burnAADC(uint256 _tokenId): Allows the AADC owner to burn their companion, permanently removing it.
// 4.  getAADCDetails(uint256 _tokenId): Retrieves comprehensive details of a specific AADC by its ID.
// 5.  getOwnerAADCs(address _owner): Returns an array of token IDs owned by a specific address.
// 6.  transferFrom(address _from, address _to, uint256 _tokenId): (Inherited from ERC721) Transfers ownership of an AADC.

// II. Skill System
// 7.  registerSkill(string memory _name, string memory _category, string memory _description): Allows the owner to define a new skill type that AADCs can learn.
// 8.  learnSkill(uint256 _tokenId, bytes32 _skillId): Allows an AADC owner to make their companion "learn" a registered skill.
// 9.  gainSkillXP(uint256 _tokenId, bytes32 _skillId, uint256 _xpAmount): Grants experience points to an AADC for a specific skill.
// 10. levelUpSkill(uint256 _tokenId, bytes32 _skillId): Allows an AADC owner to level up a skill if the companion has sufficient XP.
// 11. getAADCSkill(uint256 _tokenId, bytes32 _skillId): Retrieves the current level and XP of a specific skill for an AADC.
// 12. getAADCSkills(uint256 _tokenId): Returns a list of all skills learned by a specific AADC, including their levels and XP.
// 13. removeSkill(uint256 _tokenId, bytes32 _skillId): Allows the owner to remove a skill from an AADC (e.g., for re-specialization).

// III. Attestation Registry
// 14. addAttester(address _attesterAddress, string memory _name): Grants the `ATTESTER_ROLE` to an address, allowing them to issue attestations.
// 15. removeAttester(address _attesterAddress): Revokes the `ATTESTER_ROLE` from an address.
// 16. attestSkillMastery(uint256 _tokenId, bytes32 _skillId, uint256 _attestedLevel, string memory _proofURI): An authorized attester issues a verifiable claim about an AADC's skill mastery.
// 17. revokeAttestation(bytes32 _attestationId): Allows the original attester to revoke a previously issued attestation.
// 18. getAADCAttestations(uint256 _tokenId): Retrieves all attestations made for a specific AADC.
// 19. getAttestationDetails(bytes32 _attestationId): Fetches the full details of a specific attestation by its ID.

// IV. AADC Dynamic Attributes & Interaction
// 20. updateAADCName(uint256 _tokenId, string memory _newName): Allows the AADC owner to update their companion's name.
// 21. rechargeEnergy(uint256 _tokenId): Recharges an AADC's energy, potentially allowing for more actions.
// 22. interactWithAADC(uint256 _tokenId, uint256 _energyCost, bytes32 _potentialSkillId): Simulates an interaction, consuming energy and possibly granting XP.
// 23. updateTemperament(uint256 _tokenId, uint256 _newTemperament): Allows an authorized role (e.g., owner or governance) to adjust an AADC's temperament.

// V. Reputation & Analytics
// 24. getAADCRating(uint256 _tokenId): Calculates a dynamic reputation score for an AADC based on its skills, levels, and attestations.

// VI. Configuration & Admin
// 25. setSkillXPThreshold(bytes32 _skillId, uint256 _level, uint256 _xpRequired): Allows the owner to configure the XP required for each level of a skill.
// 26. pause(): (Inherited from Pausable) Pauses core contract functionalities in case of emergency.
// 27. unpause(): (Inherited from Pausable) Unpauses core contract functionalities.
// 28. setBaseURI(string memory _newBaseURI): (Inherited from ERC721) Sets the base URI for NFT metadata, enabling dynamic metadata.
// 29. withdrawBalance(address _to): Allows the owner to withdraw any ETH accumulated in the contract.

contract AethermindCompanionLab is ERC721, Ownable, Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // --- State Variables ---

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _attestationIdCounter;

    // AADC Core Data
    struct AADC {
        string name;
        address ownerAddress; // Redundant with ERC721, but useful for quick struct access
        uint256 temperament; // e.g., 0-100, can influence behavior/efficiency
        uint256 energy;      // e.g., 0-100, consumed by actions, recharges over time
        uint256 lastEnergyRechargeTimestamp; // Timestamp of last energy update
        uint256 creationTimestamp;
        // No direct skills mapping here, use separate mapping for AADC->skills
    }
    mapping(uint256 => AADC) private _aadcs;

    // Skill Definitions (Global)
    struct Skill {
        bytes32 skillId; // keccak256(name)
        string name;
        string category; // e.g., "Generative AI", "Data Analysis", "Security"
        string description;
        bool exists; // To check if skillId maps to a valid skill
    }
    mapping(bytes32 => Skill) private _registeredSkills;
    bytes32[] private _registeredSkillIds; // To iterate over all registered skills

    // AADC Specific Skills (Learned by an AADC)
    struct AADCSkill {
        uint256 level;
        uint256 currentXP;
        uint256 lastXPUpdateTimestamp; // To prevent XP spamming
        bool learned; // To check if AADC has learned this skill
    }
    mapping(uint256 => mapping(bytes32 => AADCSkill)) private _aadcSkills;
    mapping(uint256 => bytes32[]) private _aadcLearnedSkillIds; // To get all skills for an AADC

    // Skill Level XP Requirements
    // skillId -> level -> XP required for that level
    mapping(bytes32 => mapping(uint256 => uint256)) private _skillLevelXPThresholds;

    // Attestation System
    struct Attestation {
        bytes32 attestationId; // Unique ID for this attestation
        uint256 tokenId;
        address attester;
        bytes32 skillId; // The skill being attested
        uint256 attestedLevel; // The level attested to by the attester
        string proofURI; // URI to off-chain proof (e.g., ZKP, signature, audit report)
        uint256 timestamp;
        bool revoked;
    }
    mapping(bytes32 => Attestation) private _attestations;
    mapping(uint256 => bytes32[]) private _aadcAttestationIds; // All attestations for an AADC
    mapping(address => bool) private _isAttester; // Role for trusted attesters

    // --- Events ---

    event AADCMinted(uint256 indexed tokenId, address indexed owner, string name, uint256 temperament);
    event AADCNameUpdated(uint256 indexed tokenId, string oldName, string newName);
    event AADCBurned(uint256 indexed tokenId, address indexed owner);
    event AADCEnergyRecharged(uint256 indexed tokenId, uint256 newEnergy);
    event AADCInteraction(uint256 indexed tokenId, uint256 energyCost, bytes32 indexed skillId, uint256 xpGained);
    event AADCTemperamentUpdated(uint256 indexed tokenId, uint256 oldTemperament, uint256 newTemperament);

    event SkillRegistered(bytes32 indexed skillId, string name, string category);
    event SkillLearned(uint256 indexed tokenId, bytes32 indexed skillId, uint256 initialLevel);
    event SkillXPIncreased(uint256 indexed tokenId, bytes32 indexed skillId, uint256 oldXP, uint256 newXP);
    event SkillLeveledUp(uint256 indexed tokenId, bytes32 indexed skillId, uint256 oldLevel, uint256 newLevel);
    event SkillRemoved(uint256 indexed tokenId, bytes32 indexed skillId);
    event SkillXPThresholdSet(bytes32 indexed skillId, uint256 indexed level, uint256 xpRequired);

    event AttesterAdded(address indexed attester, string name);
    event AttesterRemoved(address indexed attester);
    event SkillAttested(
        bytes32 indexed attestationId,
        uint256 indexed tokenId,
        address indexed attester,
        bytes32 skillId,
        uint256 attestedLevel,
        string proofURI
    );
    event AttestationRevoked(bytes32 indexed attestationId, uint256 indexed tokenId, address indexed attester);

    // --- Constants ---

    uint256 public constant MAX_ENERGY = 100;
    uint256 public constant ENERGY_RECHARGE_RATE_PER_SECOND = 1; // Example: 1 energy per second
    uint256 public constant MAX_AADC_NAME_LENGTH = 32;

    // --- Modifiers ---

    modifier onlyAttester() {
        require(_isAttester[msg.sender], "AethermindCompanionLab: Caller is not an attester");
        _;
    }

    modifier onlyAADCowner(uint256 _tokenId) {
        require(_exists(_tokenId), "AethermindCompanionLab: AADC does not exist");
        require(ownerOf(_tokenId) == msg.sender, "AethermindCompanionLab: Not owner of AADC");
        _;
    }

    // --- Constructor ---

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) Ownable(msg.sender) {
        // Initial setup for the contract.
        // No specific initial roles or data defined here, but could be added.
    }

    // --- Core AADC (NFT) Management ---

    /**
     * @notice Mints a new AADC NFT with an initial name and temperament for the caller.
     * @param _name The desired name for the new AADC.
     * @param _initialTemperament The initial temperament score for the AADC (e.g., 0-100).
     * @return The ID of the newly minted AADC.
     */
    function mintAADC(string memory _name, uint256 _initialTemperament) public whenNotPaused returns (uint256) {
        require(bytes(_name).length > 0 && bytes(_name).length <= MAX_AADC_NAME_LENGTH, "AethermindCompanionLab: Invalid AADC name length");
        require(_initialTemperament <= 100, "AethermindCompanionLab: Temperament must be between 0 and 100");

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _safeMint(msg.sender, newItemId);

        _aadcs[newItemId] = AADC({
            name: _name,
            ownerAddress: msg.sender,
            temperament: _initialTemperament,
            energy: MAX_ENERGY, // Starts with full energy
            lastEnergyRechargeTimestamp: block.timestamp,
            creationTimestamp: block.timestamp
        });

        emit AADCMinted(newItemId, msg.sender, _name, _initialTemperament);
        return newItemId;
    }

    /**
     * @notice Allows the AADC owner to burn their companion, permanently removing it.
     * @param _tokenId The ID of the AADC to burn.
     */
    function burnAADC(uint256 _tokenId) public onlyAADCowner(_tokenId) whenNotPaused {
        _burn(_tokenId);
        delete _aadcs[_tokenId];
        delete _aadcSkills[_tokenId]; // Remove all associated skills
        delete _aadcLearnedSkillIds[_tokenId]; // Remove skill index
        delete _aadcAttestationIds[_tokenId]; // Remove attestation index
        // Note: Attestations themselves (in _attestations mapping) will persist but refer to a non-existent AADC.
        // This is a design choice to maintain attestation history, even for burned assets.

        emit AADCBurned(_tokenId, msg.sender);
    }

    /**
     * @notice Retrieves comprehensive details of a specific AADC by its ID.
     * @param _tokenId The ID of the AADC.
     * @return name The AADC's name.
     * @return owner The current owner's address.
     * @return temperament The AADC's current temperament.
     * @return currentEnergy The AADC's current energy level.
     * @return creationTimestamp The timestamp when the AADC was minted.
     */
    function getAADCDetails(uint256 _tokenId)
        public
        view
        returns (
            string memory name,
            address owner,
            uint256 temperament,
            uint256 currentEnergy,
            uint256 creationTimestamp
        )
    {
        require(_exists(_tokenId), "AethermindCompanionLab: AADC does not exist");
        AADC storage aadc = _aadcs[_tokenId];
        return (
            aadc.name,
            ownerOf(_tokenId), // Use ERC721's ownerOf for authoritative owner
            aadc.temperament,
            _calculateCurrentEnergy(_tokenId, aadc),
            aadc.creationTimestamp
        );
    }

    /**
     * @notice Returns an array of token IDs owned by a specific address.
     * @param _owner The address whose AADCs are to be retrieved.
     * @return An array of token IDs.
     */
    function getOwnerAADCs(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenIndex = 0;
        for (uint256 i = 0; i < _tokenIdCounter.current(); i++) {
            if (_exists(i + 1) && ownerOf(i + 1) == _owner) {
                tokenIds[currentTokenIndex] = i + 1;
                currentTokenIndex++;
            }
        }
        return tokenIds;
    }

    /**
     * @notice Overrides ERC721's _beforeTokenTransfer to update ownerAddress in AADC struct.
     * @dev This ensures the `ownerAddress` in the `AADC` struct always reflects the current ERC721 owner.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        if (from == address(0)) {
            // Token minted, ownerAddress set in mintAADC, no need to update
        } else if (to == address(0)) {
            // Token burned, ownerAddress will become irrelevant, handled in burnAADC
        } else {
            // Token transferred
            _aadcs[tokenId].ownerAddress = to;
        }
    }

    // --- Skill System ---

    /**
     * @notice Allows the owner to define a new skill type that AADCs can learn.
     * @dev Generates a unique `skillId` using keccak256 hash of the skill name.
     * @param _name The name of the skill (e.g., "Solidity Coding", "Generative Art").
     * @param _category The category of the skill (e.g., "Development", "Creative", "Analytics").
     * @param _description A brief description of the skill.
     * @return The unique `bytes32` ID of the registered skill.
     */
    function registerSkill(
        string memory _name,
        string memory _category,
        string memory _description
    ) public onlyOwner whenNotPaused returns (bytes32) {
        bytes32 skillId = keccak256(abi.encodePacked(_name));
        require(!_registeredSkills[skillId].exists, "AethermindCompanionLab: Skill with this name already registered");
        require(bytes(_name).length > 0, "AethermindCompanionLab: Skill name cannot be empty");

        _registeredSkills[skillId] = Skill({
            skillId: skillId,
            name: _name,
            category: _category,
            description: _description,
            exists: true
        });
        _registeredSkillIds.push(skillId);

        // Set default XP threshold for level 1
        _skillLevelXPThresholds[skillId][1] = 100; // Default: 100 XP for Level 1

        emit SkillRegistered(skillId, _name, _category);
        return skillId;
    }

    /**
     * @notice Allows an AADC owner to make their companion "learn" a registered skill.
     * @dev An AADC can only learn a skill once. It starts at level 0 with 0 XP.
     * @param _tokenId The ID of the AADC.
     * @param _skillId The ID of the skill to learn.
     */
    function learnSkill(uint256 _tokenId, bytes32 _skillId) public onlyAADCowner(_tokenId) whenNotPaused {
        require(_registeredSkills[_skillId].exists, "AethermindCompanionLab: Skill not registered");
        require(!_aadcSkills[_tokenId][_skillId].learned, "AethermindCompanionLab: AADC already learned this skill");

        _aadcSkills[_tokenId][_skillId] = AADCSkill({
            level: 0,
            currentXP: 0,
            lastXPUpdateTimestamp: block.timestamp,
            learned: true
        });
        _aadcLearnedSkillIds[_tokenId].push(_skillId);

        emit SkillLearned(_tokenId, _skillId, 0);
    }

    /**
     * @notice Grants experience points to an AADC for a specific skill.
     * @dev This function can be called by anyone (e.g., an external game or interaction) or restricted.
     *      For this example, it's public.
     * @param _tokenId The ID of the AADC.
     * @param _skillId The ID of the skill to grant XP to.
     * @param _xpAmount The amount of XP to grant.
     */
    function gainSkillXP(uint256 _tokenId, bytes32 _skillId, uint256 _xpAmount) public whenNotPaused {
        require(_exists(_tokenId), "AethermindCompanionLab: AADC does not exist");
        require(_aadcSkills[_tokenId][_skillId].learned, "AethermindCompanionLab: AADC has not learned this skill");
        require(_xpAmount > 0, "AethermindCompanionLab: XP amount must be greater than 0");

        AADCSkill storage aadcSkill = _aadcSkills[_tokenId][_skillId];
        uint256 oldXP = aadcSkill.currentXP;
        aadcSkill.currentXP = aadcSkill.currentXP.add(_xpAmount);
        aadcSkill.lastXPUpdateTimestamp = block.timestamp;

        emit SkillXPIncreased(_tokenId, _skillId, oldXP, aadcSkill.currentXP);
    }

    /**
     * @notice Allows an AADC owner to level up a skill if the companion has sufficient XP.
     * @param _tokenId The ID of the AADC.
     * @param _skillId The ID of the skill to level up.
     */
    function levelUpSkill(uint256 _tokenId, bytes32 _skillId) public onlyAADCowner(_tokenId) whenNotPaused {
        require(_aadcSkills[_tokenId][_skillId].learned, "AethermindCompanionLab: AADC has not learned this skill");

        AADCSkill storage aadcSkill = _aadcSkills[_tokenId][_skillId];
        uint256 nextLevel = aadcSkill.level.add(1);
        uint256 xpRequired = _skillLevelXPThresholds[_skillId][nextLevel];

        require(xpRequired > 0, "AethermindCompanionLab: No XP threshold set for next level or max level reached");
        require(aadcSkill.currentXP >= xpRequired, "AethermindCompanionLab: Insufficient XP to level up");

        aadcSkill.level = nextLevel;
        aadcSkill.currentXP = aadcSkill.currentXP.sub(xpRequired); // Consume XP

        emit SkillLeveledUp(_tokenId, _skillId, nextLevel.sub(1), nextLevel);
    }

    /**
     * @notice Retrieves the current level and XP of a specific skill for an AADC.
     * @param _tokenId The ID of the AADC.
     * @param _skillId The ID of the skill.
     * @return level The current level of the skill.
     * @return currentXP The current XP for the skill.
     */
    function getAADCSkill(uint256 _tokenId, bytes32 _skillId)
        public
        view
        returns (
            uint256 level,
            uint256 currentXP,
            bool learned
        )
    {
        require(_exists(_tokenId), "AethermindCompanionLab: AADC does not exist");
        AADCSkill storage aadcSkill = _aadcSkills[_tokenId][_skillId];
        return (aadcSkill.level, aadcSkill.currentXP, aadcSkill.learned);
    }

    /**
     * @notice Returns a list of all skills learned by a specific AADC, including their levels and XP.
     * @param _tokenId The ID of the AADC.
     * @return An array of tuples containing skill name, level, and current XP.
     */
    function getAADCSkills(uint256 _tokenId)
        public
        view
        returns (
            bytes32[] memory skillIds,
            string[] memory skillNames,
            uint256[] memory levels,
            uint256[] memory xps
        )
    {
        require(_exists(_tokenId), "AethermindCompanionLab: AADC does not exist");

        bytes32[] storage learnedIds = _aadcLearnedSkillIds[_tokenId];
        uint256 count = learnedIds.length;

        skillIds = new bytes32[count];
        skillNames = new string[](count);
        levels = new uint256[count];
        xps = new uint256[count];

        for (uint256 i = 0; i < count; i++) {
            bytes32 skillId = learnedIds[i];
            AADCSkill storage aadcSkill = _aadcSkills[_tokenId][skillId];
            Skill storage registeredSkill = _registeredSkills[skillId];

            skillIds[i] = skillId;
            skillNames[i] = registeredSkill.name;
            levels[i] = aadcSkill.level;
            xps[i] = aadcSkill.currentXP;
        }
        return (skillIds, skillNames, levels, xps);
    }

    /**
     * @notice Allows the owner to remove a skill from an AADC (e.g., for re-specialization or error correction).
     * @param _tokenId The ID of the AADC.
     * @param _skillId The ID of the skill to remove.
     */
    function removeSkill(uint256 _tokenId, bytes32 _skillId) public onlyAADCowner(_tokenId) whenNotPaused {
        require(_aadcSkills[_tokenId][_skillId].learned, "AethermindCompanionLab: AADC has not learned this skill");

        delete _aadcSkills[_tokenId][_skillId]; // Deletes the skill data

        // Remove from the dynamic array of learned skill IDs
        bytes32[] storage learnedIds = _aadcLearnedSkillIds[_tokenId];
        for (uint256 i = 0; i < learnedIds.length; i++) {
            if (learnedIds[i] == _skillId) {
                learnedIds[i] = learnedIds[learnedIds.length - 1]; // Replace with last element
                learnedIds.pop(); // Remove last element
                break;
            }
        }

        emit SkillRemoved(_tokenId, _skillId);
    }

    // --- Attestation Registry ---

    /**
     * @notice Grants the `ATTESTER_ROLE` to an address, allowing them to issue attestations.
     * @param _attesterAddress The address to grant the role to.
     * @param _name A descriptive name for the attester.
     */
    function addAttester(address _attesterAddress, string memory _name) public onlyOwner whenNotPaused {
        require(_attesterAddress != address(0), "AethermindCompanionLab: Invalid attester address");
        require(!_isAttester[_attesterAddress], "AethermindCompanionLab: Address is already an attester");
        _isAttester[_attesterAddress] = true;
        emit AttesterAdded(_attesterAddress, _name);
    }

    /**
     * @notice Revokes the `ATTESTER_ROLE` from an address.
     * @param _attesterAddress The address to revoke the role from.
     */
    function removeAttester(address _attesterAddress) public onlyOwner whenNotPaused {
        require(_isAttester[_attesterAddress], "AethermindCompanionLab: Address is not an attester");
        _isAttester[_attesterAddress] = false;
        emit AttesterRemoved(_attesterAddress);
    }

    /**
     * @notice An authorized attester issues a verifiable claim about an AADC's skill mastery.
     * @param _tokenId The ID of the AADC being attested.
     * @param _skillId The ID of the skill being attested.
     * @param _attestedLevel The level of mastery being attested to.
     * @param _proofURI A URI pointing to off-chain evidence/proof for this attestation (e.g., ZKP, signature, audit report).
     * @return The unique ID of the created attestation.
     */
    function attestSkillMastery(
        uint256 _tokenId,
        bytes32 _skillId,
        uint256 _attestedLevel,
        string memory _proofURI
    ) public onlyAttester whenNotPaused returns (bytes32) {
        require(_exists(_tokenId), "AethermindCompanionLab: AADC does not exist");
        require(_registeredSkills[_skillId].exists, "AethermindCompanionLab: Skill not registered");
        require(_attestedLevel > 0, "AethermindCompanionLab: Attested level must be greater than 0");

        _attestationIdCounter.increment();
        bytes32 attestationId = keccak256(abi.encodePacked(_tokenId, _skillId, msg.sender, block.timestamp, _attestationIdCounter.current()));

        _attestations[attestationId] = Attestation({
            attestationId: attestationId,
            tokenId: _tokenId,
            attester: msg.sender,
            skillId: _skillId,
            attestedLevel: _attestedLevel,
            proofURI: _proofURI,
            timestamp: block.timestamp,
            revoked: false
        });
        _aadcAttestationIds[_tokenId].push(attestationId);

        emit SkillAttested(attestationId, _tokenId, msg.sender, _skillId, _attestedLevel, _proofURI);
        return attestationId;
    }

    /**
     * @notice Allows the original attester to revoke a previously issued attestation.
     * @param _attestationId The ID of the attestation to revoke.
     */
    function revokeAttestation(bytes32 _attestationId) public onlyAttester whenNotPaused {
        Attestation storage attestation = _attestations[_attestationId];
        require(attestation.attester == msg.sender, "AethermindCompanionLab: Only original attester can revoke");
        require(!attestation.revoked, "AethermindCompanionLab: Attestation already revoked");

        attestation.revoked = true;
        emit AttestationRevoked(_attestationId, attestation.tokenId, msg.sender);
    }

    /**
     * @notice Retrieves all attestations made for a specific AADC.
     * @param _tokenId The ID of the AADC.
     * @return An array of attestation IDs.
     */
    function getAADCAttestations(uint256 _tokenId) public view returns (bytes32[] memory) {
        require(_exists(_tokenId), "AethermindCompanionLab: AADC does not exist");
        return _aadcAttestationIds[_tokenId];
    }

    /**
     * @notice Fetches the full details of a specific attestation by its ID.
     * @param _attestationId The ID of the attestation.
     * @return attestation The full Attestation struct.
     */
    function getAttestationDetails(bytes32 _attestationId) public view returns (Attestation memory) {
        return _attestations[_attestationId];
    }

    // --- AADC Dynamic Attributes & Interaction ---

    /**
     * @notice Allows the AADC owner to update their companion's name.
     * @param _tokenId The ID of the AADC.
     * @param _newName The new name for the AADC.
     */
    function updateAADCName(uint256 _tokenId, string memory _newName) public onlyAADCowner(_tokenId) whenNotPaused {
        require(bytes(_newName).length > 0 && bytes(_newName).length <= MAX_AADC_NAME_LENGTH, "AethermindCompanionLab: Invalid AADC name length");
        string memory oldName = _aadcs[_tokenId].name;
        _aadcs[_tokenId].name = _newName;
        emit AADCNameUpdated(_tokenId, oldName, _newName);
    }

    /**
     * @notice Recharges an AADC's energy. Callable by owner.
     * @dev This can be made to cost tokens or ETH in a more advanced implementation.
     *      For simplicity, it's a free, manual recharge to MAX_ENERGY for now.
     * @param _tokenId The ID of the AADC.
     */
    function rechargeEnergy(uint256 _tokenId) public onlyAADCowner(_tokenId) whenNotPaused {
        AADC storage aadc = _aadcs[_tokenId];
        aadc.energy = MAX_ENERGY;
        aadc.lastEnergyRechargeTimestamp = block.timestamp;
        emit AADCEnergyRecharged(_tokenId, aadc.energy);
    }

    /**
     * @notice Simulates an interaction with an AADC, consuming energy and potentially granting XP for a skill.
     * @dev This function could be called by any dApp integrating with AADCs to reflect usage.
     * @param _tokenId The ID of the AADC.
     * @param _energyCost The amount of energy consumed by this interaction.
     * @param _potentialSkillId The ID of a skill that might gain XP from this interaction (0x0 if none).
     */
    function interactWithAADC(uint256 _tokenId, uint256 _energyCost, bytes32 _potentialSkillId) public whenNotPaused {
        require(_exists(_tokenId), "AethermindCompanionLab: AADC does not exist");
        require(_energyCost > 0, "AethermindCompanionLab: Energy cost must be positive");

        AADC storage aadc = _aadcs[_tokenId];
        _calculateAndSetCurrentEnergy(_tokenId, aadc); // Update energy before consuming

        require(aadc.energy >= _energyCost, "AethermindCompanionLab: Insufficient energy for interaction");

        aadc.energy = aadc.energy.sub(_energyCost);
        uint256 xpGained = 0;

        if (_potentialSkillId != bytes32(0) && _aadcSkills[_tokenId][_potentialSkillId].learned) {
            uint256 xpAmount = _energyCost.mul(aadc.temperament).div(100); // XP gain scales with energy cost and temperament
            if (xpAmount == 0) xpAmount = 1; // Ensure at least 1 XP if interaction occurs
            gainSkillXP(_tokenId, _potentialSkillId, xpAmount);
            xpGained = xpAmount;
        }

        emit AADCInteraction(_tokenId, _energyCost, _potentialSkillId, xpGained);
    }

    /**
     * @notice Allows an authorized role (e.g., owner or governance) to adjust an AADC's temperament.
     * @dev Temperament can be used to influence various AADC behaviors, like XP gain rate or success chance.
     * @param _tokenId The ID of the AADC.
     * @param _newTemperament The new temperament score (0-100).
     */
    function updateTemperament(uint256 _tokenId, uint256 _newTemperament) public onlyOwner whenNotPaused {
        require(_exists(_tokenId), "AethermindCompanionLab: AADC does not exist");
        require(_newTemperament <= 100, "AethermindCompanionLab: Temperament must be between 0 and 100");

        uint256 oldTemperament = _aadcs[_tokenId].temperament;
        _aadcs[_tokenId].temperament = _newTemperament;
        emit AADCTemperamentUpdated(_tokenId, oldTemperament, _newTemperament);
    }

    // --- Reputation & Analytics ---

    /**
     * @notice Calculates a dynamic reputation score for an AADC based on its skills, levels, and attestations.
     * @dev This is a simplified reputation model. More complex models could involve weighted skills,
     *      attester reputation, or time decay.
     * @param _tokenId The ID of the AADC.
     * @return The calculated reputation score (e.g., 0-1000).
     */
    function getAADCRating(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "AethermindCompanionLab: AADC does not exist");

        uint256 totalSkillLevelScore = 0;
        uint256 totalAttestationScore = 0;

        // Score from learned skills
        bytes32[] storage learnedSkills = _aadcLearnedSkillIds[_tokenId];
        for (uint256 i = 0; i < learnedSkills.length; i++) {
            bytes32 skillId = learnedSkills[i];
            AADCSkill storage aadcSkill = _aadcSkills[_tokenId][skillId];
            totalSkillLevelScore = totalSkillLevelScore.add(aadcSkill.level.mul(10)); // Each level adds 10 points
        }

        // Score from attestations
        bytes32[] storage aadcAttestations = _aadcAttestationIds[_tokenId];
        for (uint256 i = 0; i < aadcAttestations.length; i++) {
            bytes32 attestationId = aadcAttestations[i];
            Attestation storage attestation = _attestations[attestationId];
            if (!attestation.revoked && _isAttester[attestation.attester]) {
                // Attested level adds 50 points per level if attestation is valid and by a current attester
                totalAttestationScore = totalAttestationScore.add(attestation.attestedLevel.mul(50));
            }
        }

        // Combine scores with temperament as a multiplier
        uint256 combinedScore = totalSkillLevelScore.add(totalAttestationScore);
        uint256 finalRating = combinedScore.mul(_aadcs[_tokenId].temperament).div(100);

        // Ensure a minimum rating if skills exist, or a base minimum
        if (combinedScore > 0 && finalRating == 0) {
            finalRating = 1; // Prevent zero rating if there's actual progression
        }

        return finalRating;
    }

    // --- Configuration & Admin ---

    /**
     * @notice Allows the owner to configure the XP required for each level of a specific skill.
     * @param _skillId The ID of the skill.
     * @param _level The skill level for which to set the XP threshold.
     * @param _xpRequired The amount of XP required to reach this level.
     */
    function setSkillXPThreshold(bytes32 _skillId, uint256 _level, uint256 _xpRequired) public onlyOwner whenNotPaused {
        require(_registeredSkills[_skillId].exists, "AethermindCompanionLab: Skill not registered");
        require(_level > 0, "AethermindCompanionLab: Level must be greater than 0");

        _skillLevelXPThresholds[_skillId][_level] = _xpRequired;
        emit SkillXPThresholdSet(_skillId, _level, _xpRequired);
    }

    /**
     * @notice Allows the owner to pause certain functionalities of the contract.
     * @dev Inherited from Pausable. Pauses functions decorated with `whenNotPaused`.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @notice Allows the owner to unpause the contract.
     * @dev Inherited from Pausable.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @notice Allows the owner to withdraw any ETH accumulated in the contract.
     * @param _to The address to send the ETH to.
     */
    function withdrawBalance(address _to) public onlyOwner {
        require(_to != address(0), "AethermindCompanionLab: Invalid recipient address");
        (bool success, ) = _to.call{value: address(this).balance}("");
        require(success, "AethermindCompanionLab: ETH withdrawal failed");
    }

    // --- Internal Helpers ---

    /**
     * @dev Calculates and updates the current energy level of an AADC based on elapsed time since last update.
     * @param _tokenId The ID of the AADC.
     * @param _aadc The AADC struct for the given ID.
     * @return The updated current energy level.
     */
    function _calculateAndSetCurrentEnergy(uint256 _tokenId, AADC storage _aadc) internal returns (uint256) {
        uint256 timeElapsed = block.timestamp.sub(_aadc.lastEnergyRechargeTimestamp);
        uint256 energyGained = timeElapsed.mul(ENERGY_RECHARGE_RATE_PER_SECOND);
        _aadc.energy = SafeMath.min(_aadc.energy.add(energyGained), MAX_ENERGY);
        _aadc.lastEnergyRechargeTimestamp = block.timestamp; // Update timestamp
        return _aadc.energy;
    }

    /**
     * @dev Calculates the current energy level of an AADC without modifying its state.
     * @param _tokenId The ID of the AADC.
     * @param _aadc The AADC struct for the given ID.
     * @return The calculated current energy level.
     */
    function _calculateCurrentEnergy(uint256 _tokenId, AADC storage _aadc) internal view returns (uint256) {
        uint256 timeElapsed = block.timestamp.sub(_aadc.lastEnergyRechargeTimestamp);
        uint256 energyGained = timeElapsed.mul(ENERGY_RECHARGE_RATE_PER_SECOND);
        return SafeMath.min(_aadc.energy.add(energyGained), MAX_ENERGY);
    }

    // --- ERC721 Overrides (for Custom Metadata URI) ---

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        AADC storage aadc = _aadcs[tokenId];
        uint256 currentEnergy = _calculateCurrentEnergy(tokenId, aadc);

        // This is a simplified example. In a real-world scenario, you'd construct a more complex JSON or link to an API.
        // For dynamic metadata, you would typically serve a JSON file from an API that pulls this on-chain data.
        // Example: "ipfs://<CID>/metadata/<tokenId>.json" where the JSON content is generated dynamically.
        // For this example, we'll just return a placeholder string demonstrating dynamic elements.

        return string(abi.encodePacked(
            baseURI,
            Strings.toString(tokenId),
            ".json",
            "?name=", aadc.name,
            "&temperament=", Strings.toString(aadc.temperament),
            "&energy=", Strings.toString(currentEnergy),
            "&rating=", Strings.toString(getAADCRating(tokenId))
            // More attributes could be added here
        ));
    }
}
```