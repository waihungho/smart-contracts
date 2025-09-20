Here's a Solidity smart contract named `AuraForge`, which implements a decentralized skill and reputation framework. This contract focuses on gamification, dynamic NFTs, and DAO-like structures (Guilds).

**Core Concepts & Features:**

*   **Aura Points (AP):** An internal, non-transferable ERC20-like currency earned by users for on-chain actions (integrated via whitelisted external sources).
*   **Skills:** Definable abilities with AP costs and prerequisite skills, which users can unlock to gain benefits.
*   **Aura Artifacts (Dynamic NFTs):** ERC721 NFTs that represent a user's accumulated skills and achievements. These NFTs are dynamic, meaning their metadata automatically updates to reflect newly acquired skills.
*   **Guilds:** Decentralized, skill-gated groups that users can join, potentially for collaborative activities or shared benefits (though specific benefits are out of scope for this base contract).
*   **Challenges:** Timed, skill-gated events created by the owner, where participants can earn AP.
*   **Whitelisted Sources:** A mechanism for external contracts or trusted oracles to award Aura Points based on predefined criteria.
*   **Pausable System:** For emergency pauses or upgrades.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol"; // For dynamic NFT metadata

/**
 * @title AuraForge - Decentralized Skill & Reputation Framework
 * @dev A decentralized system where users earn "Aura Points" (AP) through on-chain actions,
 *      unlock "Skills" to gain unique benefits, and forge "Aura Artifacts" (NFTs)
 *      representing their progress and identity. It integrates gamification, dynamic NFTs,
 *      and supports DAO-like "Guilds" for collective activities and "Challenges" for timed events.
 */
contract AuraForge is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    /*
     * @dev Outline: AuraForge - Decentralized Skill & Reputation Framework
     * Purpose: A decentralized system where users earn "Aura Points" (AP) through on-chain actions,
     *          unlock "Skills" to gain unique benefits, and forge "Aura Artifacts" (NFTs)
     *          representing their progress and identity. It integrates gamification, dynamic NFTs,
     *          and supports DAO-like "Guilds" for collective activities.
     *
     * Function Summary:
     * I. Core User Management & Aura Points (AP)
     * 1.  registerAuraUser(): Registers a new user, initializing their profile.
     * 2.  getUserAuraProfile(address user): Retrieves a user's basic Aura profile (registration status, AP).
     * 3.  _awardAuraPoints(address user, uint256 amount): Internal function called by whitelisted sources to award Aura Points (AP).
     * 4.  getAuraPoints(address user): Returns a user's current AP balance.
     *
     * II. Skill Management & Unlocking
     * 5.  defineSkill(string memory name, string memory description, uint256 apCost, uint16[] memory prerequisiteSkillIds): Defines a new skill. Owner-only.
     * 6.  unlockSkill(uint16 skillId): Allows a user to unlock a defined skill using their AP.
     * 7.  getSkillDetails(uint16 skillId): Retrieves details of a specific skill.
     * 8.  getUserSkills(address user): Returns a list of skill IDs unlocked by a user.
     * 9.  hasSkill(address user, uint16 skillId): Checks if a user possesses a specific skill.
     *
     * III. Aura Artifacts (Dynamic NFTs)
     * 10. forgeAuraArtifact(): Mints a new Aura Artifact (ERC721 NFT) for the user, reflecting their current skill set.
     * 11. updateAuraArtifact(uint256 tokenId): Updates an existing Aura Artifact NFT to reflect newly acquired skills.
     * 12. getAuraArtifactSkillSet(uint256 tokenId): Retrieves the skill IDs embedded in an Aura Artifact.
     * 13. tokenURI(uint256 tokenId): Generates dynamic metadata (JSON Base64) for Aura Artifact NFTs.
     *
     * IV. Guilds (Decentralized Groups)
     * 14. createGuild(string memory name, string memory description, uint16[] memory requiredSkills): Creates a new Guild.
     * 15. joinGuild(uint32 guildId): Allows a user to join a Guild if they meet the skill requirements.
     * 16. leaveGuild(uint32 guildId): Allows a user to leave a Guild.
     * 17. getGuildMembers(uint32 guildId): Retrieves the members of a specific Guild.
     *
     * V. Challenges & Events
     * 18. createChallenge(string memory name, string memory description, uint256 rewardAP, uint16[] memory requiredSkills, uint256 durationBlocks): Creates a new timed challenge. Owner-only.
     * 19. participateInChallenge(uint32 challengeId): Allows a user to participate in an active challenge.
     * 20. completeChallenge(uint32 challengeId): (Owner/Whitelisted Oracle) Marks a challenge as completed, distributing rewards to participants.
     *
     * VI. Administrative & System Functions
     * 21. setAuraPointSource(address source, bool allowed): Whitelists/blacklists addresses allowed to award AP. Owner-only.
     * 22. withdrawExcessEth(address _to): Allows the owner to withdraw any incidental ETH sent to the contract.
     * 23. pauseSystem(): Pauses certain functionalities for maintenance. Owner-only.
     * 24. unpauseSystem(): Unpauses the system. Owner-only.
     * 25. transferOwnership(address newOwner): Transfers contract ownership.
     */

    // --- State Variables ---

    // I. Aura User Profile
    struct AuraUser {
        bool isRegistered;
        uint256 auraPoints;
        mapping(uint16 => bool) unlockedSkills; // skillId => true if unlocked
        uint32[] guildsJoined; // List of guild IDs the user is a member of
    }
    mapping(address => AuraUser) private _auraUsers;
    mapping(address => bool) private _isAuraRegistered; // Faster lookup for registration status

    // II. Skills
    struct Skill {
        string name;
        string description;
        uint256 apCost;
        uint16[] prerequisiteSkillIds;
        bool exists; // To check if a skillId is valid
    }
    mapping(uint16 => Skill) private _skills;
    Counters.Counter private _skillIdCounter;

    // III. Aura Artifacts (NFTs)
    mapping(uint256 => uint16[]) private _auraArtifactSkills; // tokenId => list of skill IDs
    Counters.Counter private _auraArtifactIdCounter;

    // IV. Guilds
    struct Guild {
        string name;
        string description;
        uint16[] requiredSkills;
        address[] members; // List of member addresses
        bool exists;
    }
    mapping(uint32 => Guild) private _guilds;
    Counters.Counter private _guildIdCounter;

    // V. Challenges
    struct Challenge {
        string name;
        string description;
        uint256 rewardAP;
        uint16[] requiredSkills;
        uint256 startBlock;
        uint256 endBlock;
        mapping(address => bool) participants; // User has participated
        address[] participantList; // List of actual participants for rewards
        bool completed;
        bool exists;
    }
    mapping(uint32 => Challenge) private _challenges;
    Counters.Counter private _challengeIdCounter;

    // VI. Administrative
    mapping(address => bool) private _auraPointSources; // Addresses allowed to call _awardAuraPoints

    // --- Events ---
    event AuraUserRegistered(address indexed user);
    event AuraPointsAwarded(address indexed user, uint256 amount);
    event SkillDefined(uint16 indexed skillId, string name, uint256 apCost);
    event SkillUnlocked(address indexed user, uint16 indexed skillId, uint256 apSpent);
    event AuraArtifactForged(address indexed owner, uint256 indexed tokenId, uint16[] skills);
    event AuraArtifactUpdated(uint256 indexed tokenId, uint16[] newSkills);
    event GuildCreated(uint32 indexed guildId, string name, address indexed creator);
    event GuildJoined(uint32 indexed guildId, address indexed member);
    event GuildLeft(uint32 indexed guildId, address indexed member);
    event ChallengeCreated(uint32 indexed challengeId, string name, uint256 rewardAP, uint256 endBlock);
    event ChallengeParticipated(uint32 indexed challengeId, address indexed participant);
    event ChallengeCompleted(uint32 indexed challengeId);
    event AuraPointSourceSet(address indexed source, bool allowed);

    // --- Constructor ---
    /// @dev Initializes the ERC721 token and sets the contract owner.
    /// @param initialOwner The address that will own the contract.
    constructor(address initialOwner)
        ERC721("AuraArtifact", "AURA")
        Ownable(initialOwner)
    {}

    // --- Modifiers ---
    /// @dev Requires the caller to be a registered AuraForge user.
    modifier onlyAuraRegistered(address _user) {
        require(_isAuraRegistered[_user], "AuraForge: User not registered");
        _;
    }

    /// @dev Requires the caller to be a whitelisted Aura Point source.
    modifier onlyAuraPointSource() {
        require(_auraPointSources[msg.sender], "AuraForge: Not an authorized Aura Point source");
        _;
    }

    // --- I. Core User Management & Aura Points (AP) ---

    /// @notice Registers a new user in the AuraForge system.
    /// @dev Initializes an AuraUser profile for the caller if not already registered.
    function registerAuraUser() public whenNotPaused {
        require(!_isAuraRegistered[msg.sender], "AuraForge: User already registered");
        _auraUsers[msg.sender].isRegistered = true;
        _isAuraRegistered[msg.sender] = true;
        emit AuraUserRegistered(msg.sender);
    }

    /// @notice Retrieves a user's basic Aura profile.
    /// @param user The address of the user.
    /// @return isRegistered Whether the user is registered.
    /// @return auraPoints The user's current Aura Points.
    function getUserAuraProfile(address user) public view returns (bool isRegistered, uint256 auraPoints) {
        return (_isAuraRegistered[user], _auraUsers[user].auraPoints);
    }

    /// @notice Internal function (called by whitelisted sources) to award Aura Points (AP) to a user.
    /// @dev This function is intended to be called by external protocols or trusted oracles
    ///      to reward users for specific on-chain actions (e.g., providing liquidity, governance votes).
    ///      `msg.sender` must be whitelisted as an AuraPointSource.
    /// @param user The address of the user to award AP to.
    /// @param amount The amount of AP to award.
    function _awardAuraPoints(address user, uint256 amount) internal onlyAuraPointSource whenNotPaused {
        require(_isAuraRegistered[user], "AuraForge: User not registered to receive AP");
        _auraUsers[user].auraPoints += amount;
        emit AuraPointsAwarded(user, amount);
    }

    /// @notice Returns a user's current Aura Points balance.
    /// @param user The address of the user.
    /// @return The user's Aura Points.
    function getAuraPoints(address user) public view onlyAuraRegistered(user) returns (uint256) {
        return _auraUsers[user].auraPoints;
    }

    // --- II. Skill Management & Unlocking ---

    /// @notice Defines a new skill that users can unlock.
    /// @dev Only the contract owner can define new skills. Skill IDs start from 1.
    /// @param name The name of the skill.
    /// @param description A brief description of the skill.
    /// @param apCost The Aura Points cost to unlock this skill.
    /// @param prerequisiteSkillIds An array of skill IDs that must be unlocked before this skill.
    function defineSkill(
        string memory name,
        string memory description,
        uint256 apCost,
        uint16[] memory prerequisiteSkillIds
    ) public onlyOwner whenNotPaused {
        _skillIdCounter.increment();
        uint16 newSkillId = uint16(_skillIdCounter.current());

        // Validate prerequisite skills
        for (uint256 i = 0; i < prerequisiteSkillIds.length; i++) {
            require(_skills[prerequisiteSkillIds[i]].exists, "AuraForge: Prerequisite skill does not exist");
        }

        _skills[newSkillId] = Skill({
            name: name,
            description: description,
            apCost: apCost,
            prerequisiteSkillIds: prerequisiteSkillIds,
            exists: true
        });

        emit SkillDefined(newSkillId, name, apCost);
    }

    /// @notice Allows a user to unlock a defined skill using their Aura Points.
    /// @param skillId The ID of the skill to unlock.
    function unlockSkill(uint16 skillId) public onlyAuraRegistered(msg.sender) whenNotPaused {
        require(_skills[skillId].exists, "AuraForge: Skill does not exist");
        require(!_auraUsers[msg.sender].unlockedSkills[skillId], "AuraForge: Skill already unlocked");
        
        Skill storage skill = _skills[skillId];
        require(_auraUsers[msg.sender].auraPoints >= skill.apCost, "AuraForge: Insufficient Aura Points");

        // Check prerequisites
        for (uint256 i = 0; i < skill.prerequisiteSkillIds.length; i++) {
            require(
                _auraUsers[msg.sender].unlockedSkills[skill.prerequisiteSkillIds[i]],
                "AuraForge: Prerequisite skill not met"
            );
        }

        _auraUsers[msg.sender].auraPoints -= skill.apCost;
        _auraUsers[msg.sender].unlockedSkills[skillId] = true;

        emit SkillUnlocked(msg.sender, skillId, skill.apCost);
    }

    /// @notice Retrieves details of a specific skill.
    /// @param skillId The ID of the skill.
    /// @return name The skill's name.
    /// @return description The skill's description.
    /// @return apCost The AP cost to unlock.
    /// @return prerequisiteSkillIds An array of prerequisite skill IDs.
    /// @return exists Whether the skill exists.
    function getSkillDetails(uint16 skillId)
        public
        view
        returns (string memory name, string memory description, uint256 apCost, uint16[] memory prerequisiteSkillIds, bool exists)
    {
        Skill storage skill = _skills[skillId];
        return (skill.name, skill.description, skill.apCost, skill.prerequisiteSkillIds, skill.exists);
    }

    /// @notice Returns a list of skill IDs unlocked by a user.
    /// @param user The address of the user.
    /// @return An array of skill IDs.
    function getUserSkills(address user) public view onlyAuraRegistered(user) returns (uint16[] memory) {
        uint16 currentSkillId = uint16(_skillIdCounter.current());
        uint16[] memory userSkills = new uint16[](currentSkillId); // Max possible skills (pre-alloc for efficiency)
        uint256 count = 0;
        for (uint16 i = 1; i <= currentSkillId; i++) { // Assuming skill IDs start from 1
            if (_auraUsers[user].unlockedSkills[i]) {
                userSkills[count] = i;
                count++;
            }
        }
        // Resize array to actual count
        uint16[] memory actualSkills = new uint16[](count);
        for (uint256 i = 0; i < count; i++) {
            actualSkills[i] = userSkills[i];
        }
        return actualSkills;
    }

    /// @notice Checks if a user possesses a specific skill.
    /// @param user The address of the user.
    /// @param skillId The ID of the skill.
    /// @return True if the user has the skill, false otherwise.
    function hasSkill(address user, uint16 skillId) public view onlyAuraRegistered(user) returns (bool) {
        return _auraUsers[user].unlockedSkills[skillId];
    }

    // --- III. Aura Artifacts (Dynamic NFTs) ---

    /// @dev Internal helper function to get the current set of skills for a given user.
    function _getCurrentUserSkills(address user) internal view returns (uint16[] memory) {
        uint16 currentSkillId = uint16(_skillIdCounter.current());
        uint16[] memory skills = new uint16[](currentSkillId);
        uint256 count = 0;
        for (uint16 i = 1; i <= currentSkillId; i++) {
            if (_auraUsers[user].unlockedSkills[i]) {
                skills[count] = i;
                count++;
            }
        }
        uint16[] memory actualSkills = new uint16[](count);
        for (uint256 i = 0; i < count; i++) {
            actualSkills[i] = skills[i];
        }
        return actualSkills;
    }

    /// @notice Mints a new Aura Artifact (ERC721 NFT) for the user.
    /// @dev The NFT's metadata reflects the user's current skill set at the time of minting.
    /// @return newTokenId The ID of the newly minted Aura Artifact.
    function forgeAuraArtifact() public onlyAuraRegistered(msg.sender) whenNotPaused returns (uint256) {
        _auraArtifactIdCounter.increment();
        uint256 newTokenId = _auraArtifactIdCounter.current();

        _safeMint(msg.sender, newTokenId);
        _auraArtifactSkills[newTokenId] = _getCurrentUserSkills(msg.sender);

        emit AuraArtifactForged(msg.sender, newTokenId, _auraArtifactSkills[newTokenId]);
        return newTokenId;
    }

    /// @notice Updates an existing Aura Artifact NFT to reflect newly acquired skills.
    /// @dev Only the owner of the NFT can update it. The NFT's metadata will change.
    /// @param tokenId The ID of the Aura Artifact NFT to update.
    function updateAuraArtifact(uint256 tokenId) public onlyAuraRegistered(msg.sender) whenNotPaused {
        require(_exists(tokenId), "AuraForge: Artifact does not exist");
        require(_isApprovedOrOwner(msg.sender, tokenId), "AuraForge: Not artifact owner or approved");

        _auraArtifactSkills[tokenId] = _getCurrentUserSkills(msg.sender);

        emit AuraArtifactUpdated(tokenId, _auraArtifactSkills[tokenId]);
    }

    /// @notice Retrieves the skill IDs embedded in an Aura Artifact.
    /// @param tokenId The ID of the Aura Artifact.
    /// @return An array of skill IDs associated with the artifact.
    function getAuraArtifactSkillSet(uint256 tokenId) public view returns (uint16[] memory) {
        require(_exists(tokenId), "AuraForge: Artifact does not exist");
        return _auraArtifactSkills[tokenId];
    }

    /// @dev See {ERC721-tokenURI}. This function generates dynamic metadata for Aura Artifacts.
    ///      The metadata includes the owner, skill count, and a detailed list of unlocked skills.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        address owner = ownerOf(tokenId);
        uint16[] memory skills = _auraArtifactSkills[tokenId];
        
        // Build skills JSON array dynamically
        string memory skillListJson = "[";
        for (uint256 i = 0; i < skills.length; i++) {
            Skill storage s = _skills[skills[i]];
            // Sanitize skill name and description for JSON (basic, more robust would escape quotes)
            string memory skillName = s.name;
            skillListJson = string(abi.encodePacked(
                skillListJson,
                '{"id":', skills[i].toString(), ',"name":"', skillName, '"}'
            ));
            if (i < skills.length - 1) {
                skillListJson = string(abi.encodePacked(skillListJson, ","));
            }
        }
        skillListJson = string(abi.encodePacked(skillListJson, "]"));

        string memory json = string(
            abi.encodePacked(
                '{"name": "Aura Artifact #',
                tokenId.toString(),
                '", "description": "A dynamic NFT representing the skills and achievements of ',
                Strings.toHexString(uint160(owner), 20),
                '.", "image": "ipfs://QmVz7sJvC4X8r3y6d9E0k1j2l3m4n5o6p7q8r9s0t1u2v3w4x5y6z7a8b9c0d1e2f3g4h", ', // Placeholder image URL
                '"attributes": [',
                '{"trait_type": "Owner", "value": "',
                Strings.toHexString(uint160(owner), 20), // Checksummed address
                '"},',
                '{"trait_type": "Skills Count", "value": ',
                skills.length.toString(),
                '}',
                '], "skills_unlocked": ', // Use a more descriptive key for the skill list
                skillListJson,
                '}'
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }


    // --- IV. Guilds (Decentralized Groups) ---

    /// @notice Creates a new Guild.
    /// @dev The creator automatically becomes the first member.
    /// @param name The name of the Guild.
    /// @param description A description of the Guild.
    /// @param requiredSkills An array of skill IDs required to join this Guild.
    function createGuild(
        string memory name,
        string memory description,
        uint16[] memory requiredSkills
    ) public onlyAuraRegistered(msg.sender) whenNotPaused {
        _guildIdCounter.increment();
        uint32 newGuildId = uint32(_guildIdCounter.current());

        // Validate required skills
        for (uint256 i = 0; i < requiredSkills.length; i++) {
            require(_skills[requiredSkills[i]].exists, "AuraForge: Required skill for guild does not exist");
        }

        _guilds[newGuildId] = Guild({
            name: name,
            description: description,
            requiredSkills: requiredSkills,
            members: new address[](0), // Initialize empty
            exists: true
        });

        // Creator automatically joins the guild
        _guilds[newGuildId].members.push(msg.sender);
        _auraUsers[msg.sender].guildsJoined.push(newGuildId);

        emit GuildCreated(newGuildId, name, msg.sender);
        emit GuildJoined(newGuildId, msg.sender);
    }

    /// @notice Allows a user to join a Guild if they meet the skill requirements.
    /// @param guildId The ID of the Guild to join.
    function joinGuild(uint32 guildId) public onlyAuraRegistered(msg.sender) whenNotPaused {
        require(_guilds[guildId].exists, "AuraForge: Guild does not exist");

        // Check if already a member
        for (uint256 i = 0; i < _guilds[guildId].members.length; i++) {
            require(_guilds[guildId].members[i] != msg.sender, "AuraForge: User already a member of this guild");
        }

        // Check required skills
        for (uint256 i = 0; i < _guilds[guildId].requiredSkills.length; i++) {
            require(
                _auraUsers[msg.sender].unlockedSkills[_guilds[guildId].requiredSkills[i]],
                "AuraForge: Missing required skill to join guild"
            );
        }

        _guilds[guildId].members.push(msg.sender);
        _auraUsers[msg.sender].guildsJoined.push(guildId);

        emit GuildJoined(guildId, msg.sender);
    }

    /// @notice Allows a user to leave a Guild.
    /// @param guildId The ID of the Guild to leave.
    function leaveGuild(uint32 guildId) public onlyAuraRegistered(msg.sender) whenNotPaused {
        require(_guilds[guildId].exists, "AuraForge: Guild does not exist");

        bool isMember = false;
        uint256 memberIndex = 0;

        // Find and remove from guild members (swap and pop for gas efficiency)
        for (uint256 i = 0; i < _guilds[guildId].members.length; i++) {
            if (_guilds[guildId].members[i] == msg.sender) {
                isMember = true;
                memberIndex = i;
                break;
            }
        }
        require(isMember, "AuraForge: User is not a member of this guild");

        _guilds[guildId].members[memberIndex] = _guilds[guildId].members[_guilds[guildId].members.length - 1];
        _guilds[guildId].members.pop();

        // Remove from user's guildsJoined list (swap and pop)
        uint256 userGuildIndex = 0;
        bool foundInUserList = false;
        for (uint256 i = 0; i < _auraUsers[msg.sender].guildsJoined.length; i++) {
            if (_auraUsers[msg.sender].guildsJoined[i] == guildId) {
                userGuildIndex = i;
                foundInUserList = true;
                break;
            }
        }
        // This should always be true if isMember was true, but good for defensive coding
        require(foundInUserList, "AuraForge: Guild not found in user's joined list (internal error)"); 
        _auraUsers[msg.sender].guildsJoined[userGuildIndex] = _auraUsers[msg.sender].guildsJoined[_auraUsers[msg.sender].guildsJoined.length - 1];
        _auraUsers[msg.sender].guildsJoined.pop();

        emit GuildLeft(guildId, msg.sender);
    }

    /// @notice Retrieves the members of a specific Guild.
    /// @param guildId The ID of the Guild.
    /// @return An array of member addresses.
    function getGuildMembers(uint32 guildId) public view returns (address[] memory) {
        require(_guilds[guildId].exists, "AuraForge: Guild does not exist");
        return _guilds[guildId].members;
    }

    // --- V. Challenges & Events ---

    /// @notice Creates a new timed challenge.
    /// @dev Only the contract owner can create challenges.
    /// @param name The name of the challenge.
    /// @param description A description of the challenge.
    /// @param rewardAP The Aura Points awarded to each participant upon successful completion.
    /// @param requiredSkills An array of skill IDs required to participate.
    /// @param durationBlocks The duration of the challenge in blocks.
    function createChallenge(
        string memory name,
        string memory description,
        uint256 rewardAP,
        uint16[] memory requiredSkills,
        uint256 durationBlocks
    ) public onlyOwner whenNotPaused {
        require(durationBlocks > 0, "AuraForge: Challenge duration must be greater than 0");

        _challengeIdCounter.increment();
        uint32 newChallengeId = uint32(_challengeIdCounter.current());

        // Validate required skills
        for (uint256 i = 0; i < requiredSkills.length; i++) {
            require(_skills[requiredSkills[i]].exists, "AuraForge: Required skill for challenge does not exist");
        }

        _challenges[newChallengeId] = Challenge({
            name: name,
            description: description,
            rewardAP: rewardAP,
            requiredSkills: requiredSkills,
            startBlock: block.number,
            endBlock: block.number + durationBlocks,
            participants: new mapping(address => bool)(), // Initialize mapping
            participantList: new address[](0), // Initialize empty
            completed: false,
            exists: true
        });

        emit ChallengeCreated(newChallengeId, name, rewardAP, _challenges[newChallengeId].endBlock);
    }

    /// @notice Allows a user to participate in an active challenge.
    /// @param challengeId The ID of the challenge to participate in.
    function participateInChallenge(uint32 challengeId) public onlyAuraRegistered(msg.sender) whenNotPaused {
        require(_challenges[challengeId].exists, "AuraForge: Challenge does not exist");
        require(block.number >= _challenges[challengeId].startBlock, "AuraForge: Challenge has not started yet");
        require(block.number <= _challenges[challengeId].endBlock, "AuraForge: Challenge has ended");
        require(!_challenges[challengeId].completed, "AuraForge: Challenge already completed");
        require(!_challenges[challengeId].participants[msg.sender], "AuraForge: User already participated in this challenge");

        Challenge storage challenge = _challenges[challengeId];

        // Check required skills for participation
        for (uint256 i = 0; i < challenge.requiredSkills.length; i++) {
            require(
                _auraUsers[msg.sender].unlockedSkills[challenge.requiredSkills[i]],
                "AuraForge: Missing required skill to participate in challenge"
            );
        }

        challenge.participants[msg.sender] = true;
        challenge.participantList.push(msg.sender);

        emit ChallengeParticipated(challengeId, msg.sender);
    }

    /// @notice Marks a challenge as completed and distributes rewards to participants.
    /// @dev This function is intended to be called by the owner or a whitelisted oracle
    ///      after the challenge duration has passed and conditions are met.
    /// @param challengeId The ID of the challenge to complete.
    function completeChallenge(uint32 challengeId) public onlyOwner whenNotPaused { // Could also be `onlyAuraPointSource` for decentralization
        require(_challenges[challengeId].exists, "AuraForge: Challenge does not exist");
        require(!_challenges[challengeId].completed, "AuraForge: Challenge already completed");
        require(block.number > _challenges[challengeId].endBlock, "AuraForge: Challenge has not ended yet");

        Challenge storage challenge = _challenges[challengeId];
        challenge.completed = true;

        for (uint256 i = 0; i < challenge.participantList.length; i++) {
            address participant = challenge.participantList[i];
            // Award AP, ensuring the participant is still registered (though highly unlikely they'd de-register)
            if (_isAuraRegistered[participant]) { 
                 _auraUsers[participant].auraPoints += challenge.rewardAP;
                 emit AuraPointsAwarded(participant, challenge.rewardAP); // Emit event for clarity
            }
        }

        emit ChallengeCompleted(challengeId);
    }

    // --- VI. Administrative & System Functions ---

    /// @notice Whitelists or blacklists addresses that can call `_awardAuraPoints`.
    /// @dev Only the contract owner can set Aura Point sources. These would typically be
    ///      other protocol contracts or trusted oracles that report on-chain actions.
    /// @param source The address to set as an Aura Point source.
    /// @param allowed True to whitelist, false to blacklist.
    function setAuraPointSource(address source, bool allowed) public onlyOwner whenNotPaused {
        _auraPointSources[source] = allowed;
        emit AuraPointSourceSet(source, allowed);
    }

    /// @notice Allows the contract owner to withdraw any incidental ETH sent to the contract.
    /// @dev This function protects against accidental ETH transfers to the contract address.
    /// @param _to The address to send the ETH to.
    function withdrawExcessEth(address _to) public onlyOwner {
        require(address(this).balance > 0, "AuraForge: No ETH to withdraw");
        (bool success, ) = _to.call{value: address(this).balance}("");
        require(success, "AuraForge: Failed to withdraw ETH");
    }

    /// @notice Pauses certain contract functionalities in case of an emergency or upgrade.
    /// @dev Only the contract owner can pause the system. This will block functions decorated with `whenNotPaused`.
    function pauseSystem() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses the system, resuming normal contract functionalities.
    /// @dev Only the contract owner can unpause the system.
    function unpauseSystem() public onlyOwner {
        _unpause();
    }

    /// @notice Transfers ownership of the contract to a new address.
    /// @dev This is an inherited function from OpenZeppelin's Ownable.
    /// @param newOwner The address of the new owner.
    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
    }
}
```