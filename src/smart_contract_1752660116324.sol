Here's a Solidity smart contract named `AuraRealm`, designed to be an advanced, creative, and trending "Soulbound Identity & Gamified Progression Protocol". It allows users to mint non-transferable (soulbound) NFTs that represent their on-chain identity, which then accumulate skills, reputation, and achievements through gamified quests. Other DApps can query these profiles to create personalized experiences, enforce access control, or offer adaptive incentives.

This contract aims to be unique by combining dynamic NFT attributes, a reputation system, a full-fledged skill tree, and quest mechanics into a single, cohesive soulbound identity. It avoids direct duplication of common open-source projects by integrating these features in a novel way for an evolving, on-chain identity.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

/*
    Outline: AuraRealm - Soulbound Identity & Gamified Progression Protocol

    AuraRealm is an innovative smart contract designed to create dynamic, evolving, and non-transferable (Soulbound) digital identities on the blockchain. It integrates RPG-like progression systems, including customizable skill trees, a reputation system, and on-chain achievements (feats) and quests. The primary goal is to provide DApps and protocols with a rich, queryable user profile that can be used for personalized experiences, access control, adaptive incentives, and community building, without relying solely on fungible token holdings.

    It leverages the ERC-721 standard but specifically makes tokens non-transferable to maintain their 'soulbound' nature, ensuring that reputation and skills are tied directly to a user's address. Trusted oracles, set by the contract owner, play a crucial role in granting skills, adjusting reputation, and marking quest completions, allowing for integration with off-chain activities or complex on-chain logic.

    Function Summary:

    I. Core Aura Profile (Soulbound NFT) Management:
    1.  mintAuraProfile(address user, string memory initialMetadataURI): Mints a new unique Soulbound Aura NFT for a specified user. Reverts if user already has a profile. Includes an optional minting fee.
    2.  getAuraProfileTokenId(address user): Returns the tokenId associated with a user's Aura Profile.
    3.  isAuraProfileMinted(address user): Checks if a given address already owns an Aura Profile.
    4.  updateAuraMetadataURI(uint256 tokenId, string memory newURI): Allows the owner of an Aura (or a designated Aura Manager) to update their profile's metadata URI. Essential for dynamic Aura rendering.
    5.  burnAuraProfile(uint256 tokenId): Allows the owner of an Aura Profile to irrevocably burn it. This is a permanent action, potentially for privacy or profile reset.

    II. Dynamic Skill Tree System:
    6.  defineSkill(uint256 skillId, string memory name, string memory description, uint256 maxLevel): Admin/governance function to define a new skill type available within the AuraRealm. Each skill has a unique ID, name, description, and maximum level.
    7.  getSkillDetails(uint256 skillId): Retrieves the defined details (name, description, max level) for a specific skillId.
    8.  grantSkillPoints(uint256 tokenId, uint256 skillId, uint256 points): Trusted oracle/admin function to award skill points to a user's Aura for a specific skill. Automatically levels up the skill if point thresholds are met.
    9.  getUserSkillLevel(uint256 tokenId, uint256 skillId): Returns the current level of a specific skill for a given Aura Profile.
    10. getSkillPoints(uint256 tokenId, uint256 skillId): Returns the total skill points accumulated for a specific skill by an Aura Profile.
    11. getSkillPointsToNextLevel(uint256 tokenId, uint256 skillId): Calculates and returns the number of additional points required for an Aura's skill to reach its next level. Returns 0 if already at max level.
    12. querySkillLevel(address user, uint256 skillId): Public view function allowing any external contract or user to query the level of a specific skill for a given user's Aura Profile.

    III. Reputation & Influence System:
    13. adjustReputation(uint256 tokenId, int256 deltaReputation): Trusted oracle/admin function to increase or decrease an Aura Profile's global reputation score. Can be positive or negative.
    14. getUserReputation(uint256 tokenId): Returns the current reputation score for a given Aura Profile.
    15. queryReputation(address user): Public view function for external entities to query a user's global reputation score.

    IV. Feats (Achievements) & Badges:
    16. defineFeat(uint256 featId, string memory name, string memory description, string memory metadataURI): Admin/governance function to define a new achievement or 'feat' with its associated metadata.
    17. getFeatDetails(uint256 featId): Retrieves the details (name, description, metadata URI) for a specific featId.
    18. grantFeat(uint256 tokenId, uint256 featId): Trusted oracle/admin function to officially award a defined feat to a user's Aura Profile. Prevents duplicate grants and adds to a list of granted feats.
    19. hasFeat(uint256 tokenId, uint256 featId): Checks if a specific Aura Profile has been granted a particular feat.
    20. getUserFeats(uint256 tokenId): Returns a list of all feat IDs that have been granted to a specific Aura Profile.

    V. Gamified Quests & Progression:
    21. createQuest(uint256 questId, string memory name, string memory description, uint256 requiredReputation, uint256[] memory requiredSkills, uint256[] memory requiredSkillLevels, uint256 rewardSkillId, uint256 rewardSkillPoints, int256 rewardReputation): Admin/governance function to define a new quest, including its prerequisites (reputation, skills) and rewards (skill points, reputation).
    22. getQuestDetails(uint256 questId): Retrieves the defined details for a specific quest.
    23. completeQuest(uint256 tokenId, uint256 questId): Trusted oracle/admin function to mark a quest as completed for an Aura Profile. It automatically verifies if the Aura meets the quest's prerequisites and applies the rewards.
    24. getQuestStatus(uint256 tokenId, uint256 questId): Checks the completion status of a quest for a given Aura Profile.
    25. getAvailableQuests(uint256 tokenId): Returns a list of quest IDs that a specific Aura Profile is currently eligible to complete based on its reputation and skill levels.

    VI. Aura Interactions & System Utilities:
    26. setTrustedOracle(address oracle, bool isTrusted): Owner function to designate or revoke addresses as trusted oracles. Oracles have permissions to grant skills, adjust reputation, and complete quests.
    27. addAuraManager(uint256 tokenId, address manager): Allows the owner of an Aura Profile to delegate specific management rights (e.g., updating metadata) to another address.
    28. removeAuraManager(uint256 tokenId, address manager): Allows the owner of an Aura Profile to revoke management rights from a delegated address.
    29. isAuraManager(uint256 tokenId, address manager): Checks if an address is a delegated manager for a specific Aura Profile.
    30. setBaseURI(string memory newURI): Owner function to set the base URI for the Aura NFT metadata.
    31. pauseSystem(): Owner function to pause critical functions of the contract (minting, grants, quest completion). Useful for upgrades or emergency stops.
    32. unpauseSystem(): Owner function to resume paused contract functionalities.
    33. setMintFee(uint256 fee): Owner function to set a fee (in native currency, e.g., ETH) for minting a new Aura Profile.
    34. withdrawFees(): Owner function to withdraw collected minting fees from the contract.
    35. renounceOwnership(): Transfers ownership of the contract to the zero address, making it unowned.
*/

contract AuraRealm is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeCast for uint252; // Used for converting uint256 to int256 if needed, though direct comparisons are safer for reputation.

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;

    uint256 public mintFee; // Fee to mint an Aura Profile (in native currency, e.g., wei for ETH)

    // Mapping from user address to their Aura profile tokenId
    mapping(address => uint256) private _userAuraTokenId;
    // Mapping from tokenId to user address (reverse lookup for convenience)
    mapping(uint256 => address) private _auraTokenIdToUser;

    // Core Aura Profile data (beyond ERC721)
    mapping(uint256 => mapping(uint256 => uint256)) private _auraSkillPoints; // tokenId => skillId => total points
    mapping(uint256 => int256) private _auraReputation; // tokenId => reputation score (can be negative)
    mapping(uint256 => mapping(uint256 => bool)) private _auraFeats; // tokenId => featId => hasFeat (for O(1) check)
    mapping(uint256 => uint256[]) private _auraGrantedFeatList; // tokenId => list of granted feat IDs (for iteration)
    mapping(uint256 => mapping(uint256 => bool)) private _auraQuestsCompleted; // tokenId => questId => completed

    // System Definitions (admin/governance defined)
    struct Skill {
        string name;
        string description;
        uint256 maxLevel; // Max level for this skill type
    }
    mapping(uint256 => Skill) public skills; // skillId => Skill struct
    mapping(uint256 => bool) public isSkillDefined; // Quick check if a skillId is defined
    uint256[] private _definedSkillIds; // Stores all defined skill IDs for iteration

    struct Feat {
        string name;
        string description;
        string metadataURI; // URI for feat's visual representation/details
    }
    mapping(uint256 => Feat) public feats; // featId => Feat struct
    mapping(uint256 => bool) public isFeatDefined; // Quick check if a featId is defined
    uint256[] private _definedFeatIds; // Stores all defined feat IDs for iteration

    struct Quest {
        string name;
        string description;
        uint256 requiredReputation; // Minimum reputation (absolute value) to complete quest, though reputation is int256
        uint256[] requiredSkills; // Array of skillIds
        uint256[] requiredSkillLevels; // Array of required levels for corresponding skillIds
        uint256 rewardSkillId; // Skill to reward points to (0 if no skill reward)
        uint256 rewardSkillPoints; // Points to reward for the skill
        int256 rewardReputation; // Reputation change for completing quest
    }
    mapping(uint256 => Quest) public quests; // questId => Quest struct
    mapping(uint256 => bool) public isQuestDefined; // Quick check if a questId is defined
    uint256[] private _definedQuestIds; // Stores all defined quest IDs for iteration

    // Trusted Oracles: addresses that can grant skills, adjust reputation, complete quests
    mapping(address => bool) public trustedOracles;

    // Aura Managers: delegated addresses for specific Aura tokenIds (e.g., updating metadata)
    mapping(uint256 => mapping(address => bool)) private _auraManagers;

    // --- Events ---
    event AuraProfileMinted(address indexed user, uint256 indexed tokenId, string initialMetadataURI);
    event AuraMetadataUpdated(uint256 indexed tokenId, string newURI);
    event AuraProfileBurned(address indexed user, uint256 indexed tokenId);

    event SkillDefined(uint256 indexed skillId, string name, uint256 maxLevel);
    event SkillPointsGranted(uint256 indexed tokenId, uint256 indexed skillId, uint256 pointsGranted, uint256 newTotalPoints, uint256 newLevel);
    event ReputationAdjusted(uint256 indexed tokenId, int256 deltaReputation, int256 newReputation);

    event FeatDefined(uint256 indexed featId, string name, string metadataURI);
    event FeatGranted(uint256 indexed tokenId, uint256 indexed featId);

    event QuestCreated(uint256 indexed questId, string name);
    event QuestCompleted(uint256 indexed tokenId, uint256 indexed questId);

    event TrustedOracleSet(address indexed oracle, bool isTrusted);
    event AuraManagerSet(uint256 indexed tokenId, address indexed manager, bool isManager);
    event FeesWithdrawn(address indexed to, uint256 amount);

    // --- Constructor ---
    constructor() ERC721("AuraRealmProfile", "AURAP") Ownable() Pausable() {
        // No initial setup needed beyond OpenZeppelin defaults.
        // `mintFee` can be set by owner post-deployment.
    }

    // --- Modifiers ---
    modifier onlyTrustedOracle() {
        require(trustedOracles[msg.sender], "AuraRealm: Not a trusted oracle");
        _;
    }

    modifier onlyAuraOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "AuraRealm: Not Aura owner");
        _;
    }

    modifier onlyAuraOwnerOrManager(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender || _auraManagers[tokenId][msg.sender], "AuraRealm: Not Aura owner or manager");
        _;
    }

    // --- I. Core Aura Profile (Soulbound NFT) Management ---
    /**
     * @notice Mints a new Soulbound Aura NFT for a specific user. Each user can only mint one.
     * @param user The address for whom to mint the Aura Profile.
     * @param initialMetadataURI The initial metadata URI for the Aura Profile.
     */
    function mintAuraProfile(address user, string memory initialMetadataURI) public payable whenNotPaused {
        require(_userAuraTokenId[user] == 0, "AuraRealm: User already has an Aura Profile");
        require(msg.value >= mintFee, "AuraRealm: Insufficient mint fee");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(user, newTokenId);
        _setTokenURI(newTokenId, initialMetadataURI);

        _userAuraTokenId[user] = newTokenId;
        _auraTokenIdToUser[newTokenId] = user;

        emit AuraProfileMinted(user, newTokenId, initialMetadataURI);
    }

    /**
     * @notice Returns the tokenId for a given user's Aura Profile.
     * @param user The address to query.
     * @return The tokenId of the user's Aura Profile, or 0 if none exists.
     */
    function getAuraProfileTokenId(address user) public view returns (uint256) {
        return _userAuraTokenId[user];
    }

    /**
     * @notice Checks if an address already has an Aura Profile.
     * @param user The address to check.
     * @return True if the address has an Aura Profile, false otherwise.
     */
    function isAuraProfileMinted(address user) public view returns (bool) {
        return _userAuraTokenId[user] != 0;
    }

    /**
     * @notice Allows the owner of an Aura Profile (or a delegated manager) to update its metadata URI.
     * @param tokenId The ID of the Aura Profile.
     * @param newURI The new metadata URI.
     */
    function updateAuraMetadataURI(uint256 tokenId, string memory newURI) public onlyAuraOwnerOrManager(tokenId) whenNotPaused {
        _setTokenURI(tokenId, newURI);
        emit AuraMetadataUpdated(tokenId, newURI);
    }

    /**
     * @notice Allows the owner of an Aura Profile to burn it permanently.
     * @param tokenId The ID of the Aura Profile to burn.
     */
    function burnAuraProfile(uint256 tokenId) public whenNotPaused {
        address user = ownerOf(tokenId); // ERC721 ownerOf check
        require(msg.sender == user, "AuraRealm: Only Aura owner can burn");

        _burn(tokenId);

        // Clear associated data mappings to enable a user to mint a new profile if desired
        delete _userAuraTokenId[user];
        delete _auraTokenIdToUser[tokenId];

        // Optionally, clear all associated skill points, reputation, feats, and quests.
        // For simplicity and gas efficiency, these are implicitly orphaned as the tokenId becomes invalid.
        // If a "full reset" is desired, more explicit clearing would be needed here, which can be gas-intensive.

        emit AuraProfileBurned(user, tokenId);
    }

    // --- II. Dynamic Skill Tree System ---
    /**
     * @notice Defines a new skill type within the AuraRealm. Only callable by owner.
     * @param skillId A unique ID for the new skill.
     * @param name The name of the skill.
     * @param description A brief description of the skill.
     * @param maxLevel The maximum achievable level for this skill.
     */
    function defineSkill(uint256 skillId, string memory name, string memory description, uint256 maxLevel) public onlyOwner {
        require(!isSkillDefined[skillId], "AuraRealm: Skill ID already defined");
        require(maxLevel > 0, "AuraRealm: Max level must be greater than 0");

        skills[skillId] = Skill(name, description, maxLevel);
        isSkillDefined[skillId] = true;
        _definedSkillIds.push(skillId); // Add to the list of all defined skill IDs
        emit SkillDefined(skillId, name, maxLevel);
    }

    /**
     * @notice Retrieves the details of a defined skill.
     * @param skillId The ID of the skill.
     * @return name, description, maxLevel of the skill.
     */
    function getSkillDetails(uint256 skillId) public view returns (string memory name, string memory description, uint256 maxLevel) {
        require(isSkillDefined[skillId], "AuraRealm: Skill not defined");
        Skill storage s = skills[skillId];
        return (s.name, s.description, s.maxLevel);
    }

    /**
     * @notice Grants skill points to a user's Aura for a specific skill. Only callable by trusted oracles.
     *         Automatically updates skill level.
     * @param tokenId The ID of the Aura Profile.
     * @param skillId The ID of the skill to grant points to.
     * @param points The number of points to grant.
     */
    function grantSkillPoints(uint256 tokenId, uint256 skillId, uint256 points) public onlyTrustedOracle whenNotPaused {
        require(_exists(tokenId), "AuraRealm: Aura Profile does not exist");
        require(isSkillDefined[skillId], "AuraRealm: Skill not defined");
        require(points > 0, "AuraRealm: Points must be positive");

        uint256 currentPoints = _auraSkillPoints[tokenId][skillId];
        uint256 newTotalPoints = currentPoints + points;

        uint256 currentLevel = calculateSkillLevel(currentPoints);
        uint256 newLevel = calculateSkillLevel(newTotalPoints);

        // Ensure new level does not exceed maxLevel
        uint256 maxLevel = skills[skillId].maxLevel;
        if (newLevel > maxLevel) {
            newLevel = maxLevel;
            newTotalPoints = maxLevel * 100; // Cap points at max level equivalent if using this simple formula
        }

        _auraSkillPoints[tokenId][skillId] = newTotalPoints;

        emit SkillPointsGranted(tokenId, skillId, points, newTotalPoints, newLevel);
    }

    /**
     * @notice Internal helper to calculate skill level based on total points.
     *         Example: 100 points per level. Level 1 at 100, Level 2 at 200 etc.
     *         Level 0 is returned for 0 points.
     * @param totalPoints The total skill points accumulated.
     * @return The calculated skill level.
     */
    function calculateSkillLevel(uint256 totalPoints) internal pure returns (uint256) {
        if (totalPoints == 0) return 0;
        // Simple linear progression: 100 points per level.
        return (totalPoints / 100) + 1;
    }

    /**
     * @notice Retrieves the current level of a specific skill for a given Aura Profile.
     * @param tokenId The ID of the Aura Profile.
     * @param skillId The ID of the skill.
     * @return The current level of the skill.
     */
    function getUserSkillLevel(uint256 tokenId, uint256 skillId) public view returns (uint256) {
        require(_exists(tokenId), "AuraRealm: Aura Profile does not exist");
        require(isSkillDefined[skillId], "AuraRealm: Skill not defined");
        return calculateSkillLevel(_auraSkillPoints[tokenId][skillId]);
    }

    /**
     * @notice Retrieves the total skill points accumulated for a specific skill by an Aura Profile.
     * @param tokenId The ID of the Aura Profile.
     * @param skillId The ID of the skill.
     * @return The total points for the skill.
     */
    function getSkillPoints(uint256 tokenId, uint256 skillId) public view returns (uint256) {
        require(_exists(tokenId), "AuraRealm: Aura Profile does not exist");
        require(isSkillDefined[skillId], "AuraRealm: Skill not defined");
        return _auraSkillPoints[tokenId][skillId];
    }

    /**
     * @notice Calculates the number of additional points required for an Aura's skill to reach its next level.
     * @param tokenId The ID of the Aura Profile.
     * @param skillId The ID of the skill.
     * @return The points needed for the next level. Returns 0 if max level is reached or skill not defined/exists.
     */
    function getSkillPointsToNextLevel(uint256 tokenId, uint256 skillId) public view returns (uint256) {
        if (!_exists(tokenId) || !isSkillDefined[skillId]) return 0;

        uint256 currentPoints = _auraSkillPoints[tokenId][skillId];
        uint256 currentLevel = calculateSkillLevel(currentPoints);
        uint256 maxLevel = skills[skillId].maxLevel;

        if (currentLevel >= maxLevel) {
            return 0; // Already at max level
        }

        uint256 pointsForNextLevel = (currentLevel + 1) * 100; // Based on 100 points/level

        // Edge case: if currentPoints is already at the threshold for currentLevel+1 due to capping at max level
        if (pointsForNextLevel <= currentPoints) {
            return 0;
        }
        return pointsForNextLevel - currentPoints;
    }

    /**
     * @notice Public view function for external DApps to query a user's skill level by address.
     * @param user The address of the user.
     * @param skillId The ID of the skill.
     * @return The current level of the skill for the user, or 0 if no profile or skill.
     */
    function querySkillLevel(address user, uint256 skillId) public view returns (uint256) {
        uint256 tokenId = _userAuraTokenId[user];
        if (tokenId == 0 || !isSkillDefined[skillId]) return 0;
        return getUserSkillLevel(tokenId, skillId);
    }

    // --- III. Reputation & Influence System ---
    /**
     * @notice Adjusts an Aura Profile's global reputation score. Only callable by trusted oracles.
     * @param tokenId The ID of the Aura Profile.
     * @param deltaReputation The amount to change reputation by (can be positive or negative).
     */
    function adjustReputation(uint256 tokenId, int256 deltaReputation) public onlyTrustedOracle whenNotPaused {
        require(_exists(tokenId), "AuraRealm: Aura Profile does not exist");

        int256 currentReputation = _auraReputation[tokenId];
        int256 newReputation = currentReputation + deltaReputation;

        _auraReputation[tokenId] = newReputation;
        emit ReputationAdjusted(tokenId, deltaReputation, newReputation);
    }

    /**
     * @notice Returns the current reputation score for a given Aura Profile.
     * @param tokenId The ID of the Aura Profile.
     * @return The current reputation score.
     */
    function getUserReputation(uint256 tokenId) public view returns (int256) {
        require(_exists(tokenId), "AuraRealm: Aura Profile does not exist");
        return _auraReputation[tokenId];
    }

    /**
     * @notice Public view function for external DApps to query a user's global reputation score by address.
     * @param user The address of the user.
     * @return The current reputation score for the user, or 0 if no profile.
     */
    function queryReputation(address user) public view returns (int256) {
        uint256 tokenId = _userAuraTokenId[user];
        if (tokenId == 0) return 0;
        return getUserReputation(tokenId);
    }

    // --- IV. Feats (Achievements) & Badges ---
    /**
     * @notice Defines a new achievement or 'feat' within the AuraRealm. Only callable by owner.
     * @param featId A unique ID for the new feat.
     * @param name The name of the feat.
     * @param description A brief description of the feat.
     * @param metadataURI The URI for the feat's visual representation or detailed information.
     */
    function defineFeat(uint256 featId, string memory name, string memory description, string memory metadataURI) public onlyOwner {
        require(!isFeatDefined[featId], "AuraRealm: Feat ID already defined");

        feats[featId] = Feat(name, description, metadataURI);
        isFeatDefined[featId] = true;
        _definedFeatIds.push(featId); // Add to the list of all defined feat IDs
        emit FeatDefined(featId, name, metadataURI);
    }

    /**
     * @notice Retrieves the details for a specific feat.
     * @param featId The ID of the feat.
     * @return name, description, metadataURI of the feat.
     */
    function getFeatDetails(uint256 featId) public view returns (string memory name, string memory description, string memory metadataURI) {
        require(isFeatDefined[featId], "AuraRealm: Feat not defined");
        Feat storage f = feats[featId];
        return (f.name, f.description, f.metadataURI);
    }

    /**
     * @notice Awards a defined feat to a user's Aura Profile. Only callable by trusted oracles.
     *         Prevents duplicate grants.
     * @param tokenId The ID of the Aura Profile.
     * @param featId The ID of the feat to grant.
     */
    function grantFeat(uint256 tokenId, uint256 featId) public onlyTrustedOracle whenNotPaused {
        require(_exists(tokenId), "AuraRealm: Aura Profile does not exist");
        require(isFeatDefined[featId], "AuraRealm: Feat not defined");
        require(!_auraFeats[tokenId][featId], "AuraRealm: Feat already granted to this Aura");

        _auraFeats[tokenId][featId] = true; // For quick O(1) lookup
        _auraGrantedFeatList[tokenId].push(featId); // For listing all feats
        emit FeatGranted(tokenId, featId);
    }

    /**
     * @notice Checks if a specific Aura Profile has been granted a particular feat.
     * @param tokenId The ID of the Aura Profile.
     * @param featId The ID of the feat.
     * @return True if the Aura has the feat, false otherwise.
     */
    function hasFeat(uint256 tokenId, uint256 featId) public view returns (bool) {
        require(_exists(tokenId), "AuraRealm: Aura Profile does not exist");
        require(isFeatDefined[featId], "AuraRealm: Feat not defined");
        return _auraFeats[tokenId][featId];
    }

    /**
     * @notice Returns a list of all feat IDs that have been granted to a specific Aura Profile.
     * @param tokenId The ID of the Aura Profile.
     * @return An array of feat IDs.
     */
    function getUserFeats(uint256 tokenId) public view returns (uint256[] memory) {
        require(_exists(tokenId), "AuraRealm: Aura Profile does not exist");
        return _auraGrantedFeatList[tokenId];
    }

    // --- V. Gamified Quests & Progression ---
    /**
     * @notice Defines a new quest, including its prerequisites and rewards. Only callable by owner.
     * @param questId A unique ID for the new quest.
     * @param name The name of the quest.
     * @param description A brief description of the quest.
     * @param requiredReputation Minimum reputation required to complete this quest (absolute value, 0 for no req).
     * @param requiredSkills Array of skill IDs that are prerequisites.
     * @param requiredSkillLevels Array of required levels for corresponding skills.
     * @param rewardSkillId The skill ID to award points to upon completion (0 if no skill reward).
     * @param rewardSkillPoints The number of skill points to reward.
     * @param rewardReputation The change in reputation upon completion (can be negative).
     */
    function createQuest(
        uint256 questId,
        string memory name,
        string memory description,
        uint256 requiredReputation,
        uint256[] memory requiredSkills,
        uint256[] memory requiredSkillLevels,
        uint256 rewardSkillId,
        uint256 rewardSkillPoints,
        int256 rewardReputation
    ) public onlyOwner {
        require(!isQuestDefined[questId], "AuraRealm: Quest ID already defined");
        require(requiredSkills.length == requiredSkillLevels.length, "AuraRealm: Skill and level arrays must match length");
        if (rewardSkillId != 0) { // If there's a skill reward, ensure the skill is defined
            require(isSkillDefined[rewardSkillId], "AuraRealm: Reward skill not defined");
        }

        for (uint256 i = 0; i < requiredSkills.length; i++) {
            require(isSkillDefined[requiredSkills[i]], "AuraRealm: Required skill not defined");
        }

        quests[questId] = Quest(
            name,
            description,
            requiredReputation,
            requiredSkills,
            requiredSkillLevels,
            rewardSkillId,
            rewardSkillPoints,
            rewardReputation
        );
        isQuestDefined[questId] = true;
        _definedQuestIds.push(questId); // Add to the list of all defined quest IDs
        emit QuestCreated(questId, name);
    }

    /**
     * @notice Retrieves the defined details for a specific quest.
     * @param questId The ID of the quest.
     * @return The Quest struct details.
     */
    function getQuestDetails(uint256 questId) public view returns (Quest memory) {
        require(isQuestDefined[questId], "AuraRealm: Quest not defined");
        return quests[questId];
    }

    /**
     * @notice Internal helper to check if an Aura Profile meets quest prerequisites.
     * @param tokenId The ID of the Aura Profile.
     * @param questId The ID of the quest.
     * @return True if prerequisites are met, false otherwise.
     */
    function _checkQuestPrerequisites(uint256 tokenId, uint256 questId) internal view returns (bool) {
        Quest storage q = quests[questId];

        // Check reputation requirement (absolute value for positive reputation check)
        if (getUserReputation(tokenId) < q.requiredReputation.toInt256()) { // Use toInt256 for comparison with signed reputation
            return false;
        }

        // Check skill requirements
        for (uint256 i = 0; i < q.requiredSkills.length; i++) {
            if (getUserSkillLevel(tokenId, q.requiredSkills[i]) < q.requiredSkillLevels[i]) {
                return false;
            }
        }
        return true;
    }

    /**
     * @notice Marks a quest as completed for a user's Aura Profile. Only callable by trusted oracles.
     *         Automatically verifies prerequisites and applies rewards.
     * @param tokenId The ID of the Aura Profile.
     * @param questId The ID of the quest to complete.
     */
    function completeQuest(uint256 tokenId, uint256 questId) public onlyTrustedOracle whenNotPaused {
        require(_exists(tokenId), "AuraRealm: Aura Profile does not exist");
        require(isQuestDefined[questId], "AuraRealm: Quest not defined");
        require(!_auraQuestsCompleted[tokenId][questId], "AuraRealm: Quest already completed for this Aura");
        require(_checkQuestPrerequisites(tokenId, questId), "AuraRealm: Aura does not meet quest prerequisites");

        _auraQuestsCompleted[tokenId][questId] = true;

        // Apply rewards
        Quest storage q = quests[questId];
        if (q.rewardSkillId != 0 && q.rewardSkillPoints > 0) {
            grantSkillPoints(tokenId, q.rewardSkillId, q.rewardSkillPoints);
        }
        if (q.rewardReputation != 0) {
            adjustReputation(tokenId, q.rewardReputation);
        }

        emit QuestCompleted(tokenId, questId);
    }

    /**
     * @notice Checks the completion status of a quest for a given Aura Profile.
     * @param tokenId The ID of the Aura Profile.
     * @param questId The ID of the quest.
     * @return True if the quest is completed, false otherwise.
     */
    function getQuestStatus(uint256 tokenId, uint256 questId) public view returns (bool) {
        require(_exists(tokenId), "AuraRealm: Aura Profile does not exist");
        require(isQuestDefined[questId], "AuraRealm: Quest not defined");
        return _auraQuestsCompleted[tokenId][questId];
    }

    /**
     * @notice Returns a list of quest IDs that a specific Aura Profile is currently eligible to complete.
     *         Iterates through all defined quests. Can be gas-intensive for a very large number of quests.
     * @param tokenId The ID of the Aura Profile.
     * @return An array of quest IDs.
     */
    function getAvailableQuests(uint256 tokenId) public view returns (uint256[] memory) {
        require(_exists(tokenId), "AuraRealm: Aura Profile does not exist");

        uint256[] memory allQuestIds = _definedQuestIds; // Get the list of all defined quest IDs
        uint256 eligibleCount = 0;

        // First pass: count eligible quests to size the result array
        for (uint256 i = 0; i < allQuestIds.length; i++) {
            uint256 questId = allQuestIds[i];
            if (isQuestDefined[questId] && !_auraQuestsCompleted[tokenId][questId] && _checkQuestPrerequisites(tokenId, questId)) {
                eligibleCount++;
            }
        }

        // Second pass: populate the result array
        uint256[] memory result = new uint256[](eligibleCount);
        uint256 currentIdx = 0;
        for (uint256 i = 0; i < allQuestIds.length; i++) {
            uint256 questId = allQuestIds[i];
            if (isQuestDefined[questId] && !_auraQuestsCompleted[tokenId][questId] && _checkQuestPrerequisites(tokenId, questId)) {
                result[currentIdx] = questId;
                currentIdx++;
            }
        }
        return result;
    }

    // --- VI. Aura Interactions & System Utilities ---
    /**
     * @notice Designates or revokes an address as a trusted oracle. Only callable by owner.
     *         Trusted oracles can grant skills, adjust reputation, and complete quests.
     * @param oracle The address to set/unset as an oracle.
     * @param isTrusted True to set as trusted, false to revoke.
     */
    function setTrustedOracle(address oracle, bool isTrusted) public onlyOwner {
        require(oracle != address(0), "AuraRealm: Invalid oracle address");
        trustedOracles[oracle] = isTrusted;
        emit TrustedOracleSet(oracle, isTrusted);
    }

    /**
     * @notice Allows the owner of an Aura Profile to delegate management rights to another address.
     *         A manager can update the Aura's metadata URI.
     * @param tokenId The ID of the Aura Profile.
     * @param manager The address to grant management rights to.
     */
    function addAuraManager(uint256 tokenId, address manager) public onlyAuraOwner(tokenId) whenNotPaused {
        require(manager != address(0), "AuraRealm: Invalid manager address");
        require(!_auraManagers[tokenId][manager], "AuraRealm: Address is already a manager");
        _auraManagers[tokenId][manager] = true;
        emit AuraManagerSet(tokenId, manager, true);
    }

    /**
     * @notice Allows the owner of an Aura Profile to revoke management rights from a delegated address.
     * @param tokenId The ID of the Aura Profile.
     * @param manager The address to revoke management rights from.
     */
    function removeAuraManager(uint256 tokenId, address manager) public onlyAuraOwner(tokenId) whenNotPaused {
        require(_auraManagers[tokenId][manager], "AuraRealm: Address is not a manager");
        _auraManagers[tokenId][manager] = false;
        emit AuraManagerSet(tokenId, manager, false);
    }

    /**
     * @notice Checks if an address is a delegated manager for a specific Aura Profile.
     * @param tokenId The ID of the Aura Profile.
     * @param manager The address to check.
     * @return True if the address is a manager, false otherwise.
     */
    function isAuraManager(uint256 tokenId, address manager) public view returns (bool) {
        return _auraManagers[tokenId][manager];
    }

    /**
     * @notice Sets the base URI for the Aura NFT metadata. This is prefixed to the tokenId-specific URI.
     * @param newURI The new base URI.
     */
    function setBaseURI(string memory newURI) public onlyOwner {
        _setBaseURI(newURI);
    }

    /**
     * @notice Pauses critical functions of the contract. Only callable by owner.
     */
    function pauseSystem() public onlyOwner {
        _pause();
    }

    /**
     * @notice Resumes paused contract functionalities. Only callable by owner.
     */
    function unpauseSystem() public onlyOwner {
        _unpause();
    }

    /**
     * @notice Sets the fee (in native currency, e.g., ETH) for minting a new Aura Profile.
     * @param fee The new minting fee.
     */
    function setMintFee(uint256 fee) public onlyOwner {
        mintFee = fee;
    }

    /**
     * @notice Allows the owner to withdraw collected minting fees from the contract.
     */
    function withdrawFees() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "AuraRealm: No fees to withdraw");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "AuraRealm: Fee withdrawal failed");
        emit FeesWithdrawn(owner(), balance);
    }

    /**
     * @notice Transfers ownership of the contract to the zero address, making it unowned.
     *         This is a permanent action and should be used with extreme caution.
     */
    function renounceOwnership() public override onlyOwner {
        super.renounceOwnership();
    }

    // --- ERC721 Overrides for Soulbound Behavior ---
    // These functions prevent transfer and approval, ensuring the token is soulbound.

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     * Reverts if `from` is not address(0) (meaning it's not a mint) and `to` is not address(0) (meaning it's not a burn).
     * This enforces the non-transferable nature of the token.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
        // Allow minting (from == address(0)) and burning (to == address(0))
        // Disallow transfers (from != address(0) && to != address(0))
        require(from == address(0) || to == address(0), "AuraRealm: Aura Profiles are soulbound and cannot be transferred.");
    }

    // Explicitly override transfer/approval functions to revert to reinforce soulbound nature.
    function transferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("AuraRealm: Aura Profiles are soulbound and cannot be transferred.");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("AuraRealm: Aura Profiles are soulbound and cannot be transferred.");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public pure override {
        revert("AuraRealm: Aura Profiles are soulbound and cannot be transferred.");
    }

    function approve(address to, uint256 tokenId) public pure override {
        revert("AuraRealm: Aura Profiles are soulbound and cannot be approved.");
    }

    function setApprovalForAll(address operator, bool approved) public pure override {
        revert("AuraRealm: Aura Profiles are soulbound and cannot be approved for all.");
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        // Return address(0) as no approvals are possible
        return address(0);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        // Always false as approvals are not possible
        return false;
    }
}
```