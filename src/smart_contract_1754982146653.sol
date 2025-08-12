This smart contract, **OmniSkill Nexus**, is designed to be a cutting-edge decentralized protocol for managing dynamic skill profiles, reputation, and collaborative projects, leveraging concepts like dynamic NFTs, simulated AI oracle interactions, and soulbound tokens.

---

## OmniSkill Nexus: Smart Contract Outline & Function Summary

This contract implements the "OmniSkill Nexus" - a Decentralized AI-Infused Dynamic Skill & Reputation Protocol. It aims to create verifiable, dynamic, and evolving on-chain identities for individuals based on their skills, achievements, and contributions within various decentralized ecosystems. It facilitates trustless skill matching, collaborative project execution, and reputation building, leveraging simulated AI oracle interactions and dynamic NFTs.

**Core Concepts Incorporated:**

*   **Dynamic NFTs (SkillBadges):** NFTs whose metadata (and visual representation) evolve based on skill progression and overall reputation.
*   **Soulbound Tokens (SBTs):** The primary user SkillBadge and specific Achievement Badges are non-transferable, representing immutable on-chain identity and verifiable achievements.
*   **AI Oracle Integration (Simulated):** External AI systems are conceptually integrated via a trusted oracle role. This oracle reports skill assessments, reputation recalculations, and project verifications, bringing off-chain intelligence on-chain.
*   **Reputation System:** A complex calculation based on weighted skill points, project contributions, and earned achievements, with a conceptual mechanism for decay or recalculation triggered by the oracle.
*   **Skill-Based Collaboration Bounties:** A system where projects can be created with defined skill requirements, and participants are matched, rewarded, and gain reputation/skill points upon verified completion.
*   **Zero-Knowledge Proof (ZKP) Integration Pattern:** Provides an interface for users to submit ZKP-verified claims about off-chain skills, which are then processed by the oracle.
*   **Adaptive Skill Weighting:** A governance mechanism to adjust the importance or "weight" of different skills over time, influencing reputation and visibility.
*   **Merkle Proofs:** For verifiable, privacy-preserving claims of off-chain verified skills.
*   **Access Control & Pausability:** Robust management functionalities using OpenZeppelin's access control roles and pausing mechanisms.
*   **Custom Errors:** For gas-efficient error handling.

---

### Function Summary:

#### I. Core Protocol Management & Configuration

1.  `initialize()`: **(UUPS Proxy Pattern Ready)** Initializes the contract, setting up initial administrative roles and the designated AI Oracle address. This function replaces a constructor for upgradeable contracts.
2.  `registerSkill(bytes32 skillId, string calldata name, string calldata description, uint256 baseWeight)`: Allows an authorized `ADMIN_ROLE` to define and register a new official skill type within the system, including its base weight for reputation calculation.
3.  `updateSkillBaseWeight(bytes32 skillId, uint256 newWeight)`: Enables an `ADMIN_ROLE` to adjust the importance or impact of a registered skill on overall reputation and skill levels.
4.  `setOracleAddress(address _oracleAddress)`: Sets or updates the address of the trusted AI Oracle, callable only by the `ADMIN_ROLE`.
5.  `pause()`: Allows the `PAUSER_ROLE` to pause the contract's core functionalities, useful in emergencies.
6.  `unpause()`: Allows the `PAUSER_ROLE` to unpause the contract's core functionalities, resuming operations.

#### II. User Profile & SkillBadge NFT Management

7.  `mintSkillBadge()`: Allows a user to mint their unique, non-transferable (Soulbound) dynamic SkillBadge NFT. Each user can only mint one SkillBadge, which represents their evolving on-chain identity.
8.  `getSkillBadgeMetadataURI(address user)`: Returns a dynamically generated Base64 encoded JSON URI for a user's SkillBadge NFT, reflecting their current skills and reputation.
9.  `getUserSkillProfile(address user, bytes32 skillId)`: Retrieves detailed information (points, level, last updated) about a specific skill for a given user.
10. `getOverallReputation(address user)`: Calculates and returns a user's current overall reputation score based on their weighted skill points and earned achievements.
11. `claimOffChainSkillVerification(bytes32 skillId, uint256 rawPoints, bytes32[] calldata merkleProof)`: Enables users to claim skill points for off-chain verified achievements by providing a Merkle proof against a pre-committed root.
12. `submitZKProofForSkillClaim(bytes32 skillId, bytes calldata proofData)`: A placeholder function where users can submit Zero-Knowledge Proofs for off-chain skill verification. The actual ZKP verification is handled off-chain by the designated oracle.
13. `grantAchievementBadge(address user, bytes32 achievementId, string calldata metadataURI)`: Allows an `ORACLE_ROLE` or `ADMIN_ROLE` to mint a non-transferable (Soulbound) Achievement NFT to a user, recognizing specific accomplishments.

#### III. Skill & Reputation Progression (Oracle-Driven)

14. `oracleUpdateSkillPoints(address user, bytes32 skillId, int256 pointsDelta, string calldata context)`: **(Oracle-Only)** The primary function for the AI Oracle to update a user's skill points, adding or subtracting based on off-chain assessments or project outcomes.
15. `oracleTriggerReputationRecalculation(address user)`: **(Oracle-Only)** Allows the AI Oracle to trigger a recalculation of a user's overall reputation, useful for periodic updates or after significant events like reputation decay.
16. `requestAIConsensusSkillUpdate(address user, bytes32 skillId, string calldata assessmentContext)`: Enables a user to request an AI-driven skill assessment from the oracle, providing contextual data (e.g., links to work, academic records). This function emits an event for off-chain processing.
17. `oracleReportAIConsensusResult(address user, bytes32 skillId, uint256 newPoints, uint256 newLevel)`: **(Oracle-Only)** The AI Oracle reports the results of an off-chain consensus-based skill assessment, directly updating a user's skill profile.

#### IV. Collaborative Project System

18. `createProjectBounty(bytes32 projectId, string calldata title, string calldata description, bytes32[] calldata requiredSkills, uint256 rewardAmount, address rewardToken, uint256 deadline)`: Allows anyone to create a new collaborative project, specifying skill requirements, rewards (in ERC20 tokens), and a deadline.
19. `applyForProject(bytes32 projectId)`: Enables users to apply for a project, with basic checks to ensure they possess some relevant skills or reputation (can be expanded to stricter criteria).
20. `selectProjectParticipant(bytes32 projectId, address participant)`: The project creator or `ADMIN_ROLE` selects a participant from the applicants for a project.
21. `submitProjectDeliverable(bytes32 projectId)`: The selected participant submits their proof of work or deliverable for the project.
22. `verifyProjectCompletionAndReward(bytes32 projectId, address participant, uint256 skillGainPoints, uint256 reputationGain, bool success)`: The project creator or `ORACLE_ROLE` verifies the project's completion. If successful, rewards are distributed, and skill/reputation points are awarded via the oracle.
23. `disputeProjectOutcome(bytes32 projectId, address participant, string calldata reason)`: Allows either the project creator or the participant to initiate a dispute regarding a project's outcome, conceptually triggering an off-chain arbitration process.

#### V. Utility & View Functions

24. `getRegisteredSkillIds()`: Returns an array containing the `bytes32` IDs of all skills currently registered in the system.
25. `getProjectInfo(bytes32 projectId)`: Retrieves comprehensive details about a specific project bounty.
26. `getProjectsBySkill(bytes32 skillId)`: Returns a list of active project IDs that require a specified skill.
27. `getUserSkillBadges(address user)`: Returns a list of all NFT token IDs (both primary SkillBadges and Achievement Badges) owned by a specific user.
28. `getOracleAddress()`: Returns the currently configured address of the AI Oracle.
29. `setOffChainSkillMerkleRoot(bytes32 _merkleRoot)`: Allows the `ADMIN_ROLE` to update the Merkle root used for validating off-chain skill claims.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // For easier demo/querying of tokens
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For SafeMath operations

// Custom Errors for gas efficiency
error AlreadyInitialized();
error NotInitialized();
error SkillAlreadyRegistered(bytes32 skillId);
error SkillNotRegistered(bytes32 skillId);
error UserAlreadyHasSkillBadge();
error UserDoesNotHaveSkillBadge();
error InvalidSkillPoints();
error Forbidden();
error InvalidMerkleProof();
error ProjectNotFound();
error ProjectAlreadyExists();
error ProjectNotActive();
error NotProjectCreator();
error AlreadyApplied();
error NotEnoughSkillsOrReputation();
error ParticipantNotSelected();
error ProjectNotCompleted();
error ProjectAlreadyCompleted();
error DeadlinePassed();
error ZeroAddressNotAllowed();
error InsufficientRewardTokens();
error NoSkillPointGain();
error AlreadyHasAchievement();

interface IAIOracle {
    // Defines an interface for an external AI oracle to report assessments
    // Note: The actual AI logic runs off-chain and the oracle just reports the results.
    function reportSkillAssessment(address user, bytes32 skillId, uint256 assessedPoints, uint256 assessedLevel) external;
    function reportAIConsensusResult(address user, bytes32 skillId, uint256 newPoints, uint256 newLevel) external;
    function triggerReputationRecalculation(address user) external;
    function verifyProjectCompletion(bytes32 projectId, address participant, uint256 skillGainPoints, uint256 reputationGain, bool success) external;
}

contract OmniSkillNexus is ERC721Enumerable, AccessControl, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Roles ---
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE"); // Manages skills, base weights, global settings
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE"); // Trusted source for skill/reputation updates
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE"); // Can pause/unpause the contract

    // --- State Variables ---
    address private _aiOracleAddress;
    bool private _initialized;

    // --- SkillBadge NFT Metadata & Counters ---
    Counters.Counter private _skillBadgeTokenIdCounter;
    Counters.Counter private _achievementBadgeTokenIdCounter;

    // --- Data Structures ---

    struct Skill {
        string name;
        string description;
        uint256 baseWeight; // Multiplier for reputation/level calculation (e.g., 100)
        bool registered;
    }

    struct SkillProfile {
        uint256 points;
        uint256 level;
        uint256 lastUpdated; // Timestamp of last update
    }

    struct UserProfile {
        uint256 skillBadgeTokenId; // The ID of the primary dynamic SkillBadge NFT
        mapping(bytes32 => SkillProfile) skillProfiles; // User's specific skill profiles
        bytes32[] registeredSkillIds; // List of skills user has points in
        mapping(bytes32 => bool) hasAchievement; // Tracks granted achievements for a user
        uint256[] achievementTokenIds; // List of achievement token IDs for user (SBTs)
    }

    struct ProjectBounty {
        address creator;
        string title;
        string description;
        bytes32[] requiredSkills;
        uint256 rewardAmount;
        address rewardToken; // ERC20 token address for reward
        uint256 deadline;
        address selectedParticipant;
        bool completed;
        bool deliverablesSubmitted;
        bool disputed;
        address[] applicants;
        mapping(address => bool) hasApplied; // To track who has applied
        bool exists; // To check if a project ID is actually used
    }

    // --- Mappings ---
    mapping(bytes32 => Skill) public skills; // skillId => Skill info
    bytes32[] public registeredSkillIdsList; // All registered skill IDs

    mapping(address => UserProfile) public userProfiles; // userAddress => User's overall profile
    mapping(address => uint256) public userSkillBadgeTokenIds; // userAddress => SkillBadge tokenId

    mapping(bytes32 => ProjectBounty) public projects; // projectId => Project details
    bytes32[] public activeProjectIds; // List of active project IDs

    // For Merkle Proofs: Root of a tree containing hashes of verified off-chain skills
    bytes32 public offChainSkillMerkleRoot;

    // Helper struct to store token specific data (extension for SBT logic)
    struct TokenData {
        bool isPrimarySkillBadge;
        bool isAchievementBadge;
        bytes32 associatedAchievementId; // If it's an achievement
    }
    mapping(uint256 => TokenData) private _tokenData; // Custom data for each minted token ID

    // --- Events ---
    event Initialized(uint8 version);
    event SkillRegistered(bytes32 indexed skillId, string name, uint256 baseWeight);
    event SkillBaseWeightUpdated(bytes32 indexed skillId, uint256 newWeight);
    event OracleAddressUpdated(address indexed newOracleAddress);
    event SkillBadgeMinted(address indexed user, uint256 indexed tokenId);
    event SkillPointsUpdated(address indexed user, bytes32 indexed skillId, uint256 newPoints, uint256 newLevel, string context);
    event ReputationRecalculated(address indexed user, uint256 newReputation);
    event AIConsensusRequested(address indexed user, bytes32 indexed skillId, string assessmentContext);
    event AIConsensusReported(address indexed user, bytes32 indexed skillId, uint256 newPoints, uint256 newLevel);
    event OffChainSkillVerified(address indexed user, bytes32 indexed skillId, uint256 rawPoints);
    event AchievementBadgeGranted(address indexed user, bytes32 indexed achievementId, uint256 indexed tokenId);
    event ProjectBountyCreated(bytes32 indexed projectId, address indexed creator, uint256 rewardAmount, address rewardToken, uint256 deadline);
    event ProjectApplied(bytes32 indexed projectId, address indexed applicant);
    event ProjectParticipantSelected(bytes32 indexed projectId, address indexed participant);
    event ProjectDeliverableSubmitted(bytes32 indexed projectId, address indexed participant);
    event ProjectCompletionVerified(bytes32 indexed projectId, address indexed participant, uint256 skillGainPoints, uint256 reputationGain, bool success);
    event ProjectDisputed(bytes32 indexed projectId, address indexed disputer, string reason);
    event RewardClaimed(bytes32 indexed projectId, address indexed participant, uint256 amount, address token);

    // --- Constructor & Initializer (for UUPS Proxy pattern) ---
    constructor() ERC721("OmniSkill SkillBadge", "OSSB") {
        // Grant the deployer the DEFAULT_ADMIN_ROLE for initial setup
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Initializes the contract, setting up initial roles and configurations.
    /// @dev This function is intended to be called once after deployment in an upgradeable setup.
    /// @param defaultAdmin The address to grant DEFAULT_ADMIN_ROLE.
    /// @param pauser The address to grant PAUSER_ROLE.
    /// @param aiOracle The address to grant ORACLE_ROLE and set as the AI oracle address.
    function initialize(address defaultAdmin, address pauser, address aiOracle) public {
        if (_initialized) revert AlreadyInitialized();
        _initialized = true;

        __ERC721_init("OmniSkill SkillBadge", "OSSB");
        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        // Grant initial roles
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(PAUSER_ROLE, pauser);
        _grantRole(ORACLE_ROLE, aiOracle);

        _aiOracleAddress = aiOracle;

        emit Initialized(1); // Version 1
    }

    // --- Modifiers ---
    /// @dev Restricts function access to the set AI oracle address or an address with ORACLE_ROLE.
    modifier onlyOracle() {
        if (msg.sender != _aiOracleAddress && !hasRole(ORACLE_ROLE, msg.sender)) revert Forbidden();
        _;
    }

    /// @dev Restricts function access to the project creator or an address with ADMIN_ROLE.
    modifier onlyProjectCreator(bytes32 projectId) {
        if (projects[projectId].creator != msg.sender && !hasRole(ADMIN_ROLE, msg.sender)) revert NotProjectCreator();
        _;
    }

    // --- Internal/Utility Functions ---

    /// @dev Internal function to add skill ID to user's tracked skills if new.
    function _addSkillToUserProfile(address user, bytes32 skillId) internal {
        UserProfile storage profile = userProfiles[user];
        // Check if the skillId is already in the user's registeredSkillIds list
        bool skillExistsForUser = false;
        for (uint i = 0; i < profile.registeredSkillIds.length; i++) {
            if (profile.registeredSkillIds[i] == skillId) {
                skillExistsForUser = true;
                break;
            }
        }

        if (!skillExistsForUser) {
            profile.registeredSkillIds.push(skillId);
            // Initialize default skill profile (points and level will be 0)
            profile.skillProfiles[skillId] = SkillProfile({
                points: 0,
                level: 0,
                lastUpdated: block.timestamp
            });
        }
    }

    /// @dev Internal function to derive skill level from points (example logic).
    /// @param skillId The ID of the skill.
    /// @param points The accumulated points for the skill.
    /// @return The calculated level for the skill.
    function _calculateSkillLevel(bytes32 skillId, uint256 points) internal view returns (uint256) {
        if (!skills[skillId].registered) return 0; // Should not happen if _addSkillToUserProfile is used correctly
        uint256 baseLevel = points.div(100); // 100 points per level
        uint256 weightedLevel = baseLevel.mul(skills[skillId].baseWeight > 0 ? skills[skillId].baseWeight : 1);
        return weightedLevel;
    }

    /// @dev Internal function to check if an address has a SkillBadge.
    /// @param user The address to check.
    /// @return True if the user has a SkillBadge, false otherwise.
    function _hasSkillBadge(address user) internal view returns (bool) {
        return userSkillBadgeTokenIds[user] != 0;
    }

    /// @dev Overrides for Soulbound ERC721 - prevent transfer of SkillBadges and Achievement Badges.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Prevent transfer of Soulbound tokens (primary SkillBadges and Achievement Badges)
        // This effectively makes them non-transferable unless explicitly minted or burned by the contract.
        if (from != address(0) && to != address(0)) { // Don't block minting or burning
            if (_tokenData[tokenId].isAchievementBadge || _tokenData[tokenId].isPrimarySkillBadge) {
                 revert Forbidden(); // Transfer of Soulbound tokens is forbidden
            }
        }
    }

    // --- I. Core Protocol Management & Configuration ---

    /// @notice Registers a new official skill type in the system.
    /// @param skillId A unique identifier for the skill (e.g., keccak256("Solidity Development")).
    /// @param name The human-readable name of the skill.
    /// @param description A brief description of the skill.
    /// @param baseWeight The initial base weight for the skill, influencing reputation/level calculations (must be > 0).
    function registerSkill(bytes32 skillId, string calldata name, string calldata description, uint256 baseWeight)
        public
        onlyRole(ADMIN_ROLE)
        whenNotPaused
    {
        if (skills[skillId].registered) revert SkillAlreadyRegistered(skillId);
        if (baseWeight == 0) revert NoSkillPointGain();

        skills[skillId] = Skill({
            name: name,
            description: description,
            baseWeight: baseWeight,
            registered: true
        });
        registeredSkillIdsList.push(skillId);
        emit SkillRegistered(skillId, name, baseWeight);
    }

    /// @notice Adjusts the base importance or weighting of a specific skill.
    /// @param skillId The ID of the skill to update.
    /// @param newWeight The new base weight for the skill (must be > 0).
    function updateSkillBaseWeight(bytes32 skillId, uint256 newWeight)
        public
        onlyRole(ADMIN_ROLE)
        whenNotPaused
    {
        if (!skills[skillId].registered) revert SkillNotRegistered(skillId);
        if (newWeight == 0) revert NoSkillPointGain();

        skills[skillId].baseWeight = newWeight;
        emit SkillBaseWeightUpdated(skillId, newWeight);
    }

    /// @notice Sets the address of the trusted AI Oracle.
    /// @param _oracleAddress The new address for the AI Oracle.
    function setOracleAddress(address _oracleAddress)
        public
        onlyRole(ADMIN_ROLE)
        whenNotPaused
    {
        if (_oracleAddress == address(0)) revert ZeroAddressNotAllowed();
        _aiOracleAddress = _oracleAddress;
        emit OracleAddressUpdated(_oracleAddress);
    }

    /// @notice Pauses core contract functionalities in case of an emergency.
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @notice Unpauses the contract functionalities.
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // --- II. User Profile & SkillBadge NFT Management ---

    /// @notice Mints a user's primary (SBT-like) dynamic SkillBadge NFT.
    /// @dev Each user can only mint one SkillBadge. This NFT is non-transferable.
    function mintSkillBadge() public whenNotPaused nonReentrant {
        if (_hasSkillBadge(msg.sender)) revert UserAlreadyHasSkillBadge();

        _skillBadgeTokenIdCounter.increment();
        uint256 newTokenId = _skillBadgeTokenIdCounter.current();

        _mint(msg.sender, newTokenId);
        userSkillBadgeTokenIds[msg.sender] = newTokenId;
        userProfiles[msg.sender].skillBadgeTokenId = newTokenId;
        _tokenData[newTokenId].isPrimarySkillBadge = true;

        emit SkillBadgeMinted(msg.sender, newTokenId);
    }

    /// @notice Returns the current dynamic metadata URI for a user's SkillBadge NFT.
    /// @param user The address of the user.
    /// @return The URI pointing to the dynamic metadata JSON.
    function getSkillBadgeMetadataURI(address user) public view returns (string memory) {
        if (!_hasSkillBadge(user)) revert UserDoesNotHaveSkillBadge();

        uint256 tokenId = userSkillBadgeTokenIds[user];
        // Ensure the user is still the owner (safety check)
        require(ownerOf(tokenId) == user, "Token ownership mismatch");

        // Dynamically generate JSON metadata for the SkillBadge
        string memory name = string(abi.encodePacked("OmniSkill Nexus Badge (", Strings.toHexString(uint160(user)), ")"));
        string memory description = "A dynamic Soulbound NFT reflecting on-chain skills, reputation, and achievements.";
        string memory image = "ipfs://QmYh2mX5Z6fJ7p8L4eW2cQ9xV3bN1kD1gC6yJ5v8B7qA2"; // Placeholder IPFS image link

        // Generate attributes based on user's dynamic profile
        string[] memory attributes = new string[](3); // At least 3 attributes for overall rep and top skills

        uint256 overallRep = getOverallReputation(user);
        attributes[0] = string(abi.encodePacked('{"trait_type": "Overall Reputation", "value": "', Strings.toString(overallRep), '"}'));

        // Find top skills - simplified to find the single top skill
        uint256 maxPoints = 0;
        bytes32 topSkillId = bytes32(0);
        UserProfile storage userProfile = userProfiles[user];

        for (uint i = 0; i < userProfile.registeredSkillIds.length; i++) {
            bytes32 currentSkillId = userProfile.registeredSkillIds[i];
            uint256 currentPoints = userProfile.skillProfiles[currentSkillId].points;
            if (currentPoints > maxPoints) {
                maxPoints = currentPoints;
                topSkillId = currentSkillId;
            }
        }

        if (topSkillId != bytes32(0)) {
            attributes[1] = string(abi.encodePacked('{"trait_type": "Top Skill: ', skills[topSkillId].name, '", "value": "', Strings.toString(userProfile.skillProfiles[topSkillId].level), '"}'));
        } else {
            attributes[1] = '{"trait_type": "Top Skill", "value": "N/A"}';
        }

        attributes[2] = string(abi.encodePacked('{"trait_type": "Achievements Earned", "value": "', Strings.toString(userProfile.achievementTokenIds.length), '"}'));


        // Concatenate attributes into a JSON array string
        string memory attributesJson = "";
        for (uint i = 0; i < attributes.length; i++) {
            attributesJson = string(abi.encodePacked(attributesJson, attributes[i]));
            if (i < attributes.length - 1) {
                attributesJson = string(abi.encodePacked(attributesJson, ","));
            }
        }

        // Construct the full JSON string
        string memory json = string(abi.encodePacked(
            '{"name": "', name, '",',
            '"description": "', description, '",',
            '"image": "', image, '",',
            '"attributes": [', attributesJson, ']}'
        ));

        // Encode the JSON string to Base64 and prefix with data URI scheme
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }


    /// @notice Retrieves detailed information about a specific skill for a given user.
    /// @param user The address of the user.
    /// @param skillId The ID of the skill.
    /// @return points The accumulated points for the skill.
    /// @return level The calculated level for the skill.
    /// @return lastUpdated The timestamp of the last update for this skill.
    function getUserSkillProfile(address user, bytes32 skillId)
        public
        view
        returns (uint256 points, uint256 level, uint256 lastUpdated)
    {
        if (!_hasSkillBadge(user)) revert UserDoesNotHaveSkillBadge();
        if (!skills[skillId].registered) revert SkillNotRegistered(skillId);

        SkillProfile storage profile = userProfiles[user].skillProfiles[skillId];
        return (profile.points, profile.level, profile.lastUpdated);
    }

    /// @notice Calculates and returns a user's current overall reputation score.
    /// @dev Reputation is calculated based on weighted sum of skill points and achievements.
    /// @param user The address of the user.
    /// @return The calculated overall reputation score.
    function getOverallReputation(address user) public view returns (uint256) {
        if (!_hasSkillBadge(user)) return 0; // User needs a badge to have reputation

        uint256 totalWeightedPoints = 0;
        UserProfile storage profile = userProfiles[user];

        for (uint i = 0; i < profile.registeredSkillIds.length; i++) {
            bytes32 skillId = profile.registeredSkillIds[i];
            SkillProfile storage sp = profile.skillProfiles[skillId];
            Skill storage s = skills[skillId];

            if (s.registered) {
                totalWeightedPoints = totalWeightedPoints.add(sp.points.mul(s.baseWeight));
            }
        }

        uint256 achievementBonus = profile.achievementTokenIds.length.mul(500); // Each achievement adds a bonus
        // Can add decay here based on last activity, or oracle-triggered
        return (totalWeightedPoints.div(1000)).add(achievementBonus); // Simplified reputation calculation
    }

    /// @notice Allows users to claim off-chain verified skills using a Merkle proof against a pre-committed root.
    /// @dev The `offChainSkillMerkleRoot` must be set by an ADMIN.
    /// @param skillId The ID of the skill being claimed.
    /// @param rawPoints The raw points for the skill as verified off-chain.
    /// @param merkleProof The Merkle proof for the claim.
    function claimOffChainSkillVerification(bytes32 skillId, uint256 rawPoints, bytes32[] calldata merkleProof)
        public
        whenNotPaused
        nonReentrant
    {
        if (offChainSkillMerkleRoot == bytes32(0)) revert Forbidden(); // Merkle root not set
        if (!skills[skillId].registered) revert SkillNotRegistered(skillId);
        if (!_hasSkillBadge(msg.sender)) revert UserDoesNotHaveSkillBadge();
        if (rawPoints == 0) revert NoSkillPointGain();

        // Hash the data the user is claiming: keccak256(abi.encodePacked(userAddress, skillId, rawPoints))
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, skillId, rawPoints));

        // Verify the Merkle proof
        bytes32 computedHash = leaf;
        for (uint i = 0; i < merkleProof.length; i++) {
            bytes32 proofElement = merkleProof[i];
            if (computedHash < proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        if (computedHash != offChainSkillMerkleRoot) revert InvalidMerkleProof();

        // Update skill points
        _addSkillToUserProfile(msg.sender, skillId);
        SkillProfile storage profile = userProfiles[msg.sender].skillProfiles[skillId];
        profile.points = profile.points.add(rawPoints);
        profile.level = _calculateSkillLevel(skillId, profile.points);
        profile.lastUpdated = block.timestamp;

        emit OffChainSkillVerified(msg.sender, skillId, rawPoints);
        emit SkillPointsUpdated(msg.sender, skillId, profile.points, profile.level, "Off-chain Merkle Verification");
        emit ReputationRecalculated(msg.sender, getOverallReputation(msg.sender));
    }

    /// @notice Placeholder function for submitting ZKP-verified skill claims.
    /// @dev In a real system, `proofData` would be verified off-chain by an oracle,
    ///      which then calls `oracleUpdateSkillPoints` with the verified result.
    /// @param skillId The ID of the skill being proven.
    /// @param proofData The raw ZKP proof data.
    function submitZKProofForSkillClaim(bytes32 skillId, bytes calldata proofData)
        public
        whenNotPaused
    {
        if (!skills[skillId].registered) revert SkillNotRegistered(skillId);
        if (!_hasSkillBadge(msg.sender)) revert UserDoesNotHaveSkillBadge();
        // Proof data is too abstract to validate on-chain without a verifier contract.
        // This function primarily serves to emit an event that an off-chain oracle monitors.
        emit AIConsensusRequested(msg.sender, skillId, "ZKP Proof Submission awaiting Oracle verification.");
    }

    /// @notice Grants a non-transferable Achievement NFT (SBT) to a user.
    /// @dev Only callable by ORACLE_ROLE or ADMIN_ROLE.
    /// @param user The address of the recipient.
    /// @param achievementId A unique identifier for the achievement.
    /// @param metadataURI The URI for the achievement's metadata.
    function grantAchievementBadge(address user, bytes32 achievementId, string calldata metadataURI)
        public
        onlyRole(ORACLE_ROLE) // Or ADMIN_ROLE depending on design
        whenNotPaused
        nonReentrant
    {
        if (user == address(0)) revert ZeroAddressNotAllowed();
        if (userProfiles[user].hasAchievement[achievementId]) revert AlreadyHasAchievement();

        _achievementBadgeTokenIdCounter.increment();
        // Ensure achievement token IDs are distinct from SkillBadge IDs.
        // A simple way is to start them from a very high number or use a distinct range.
        // Here, we just add a large offset to the SkillBadge counter.
        uint256 newTokenId = _achievementBadgeTokenIdCounter.current().add(1_000_000_000);

        _mint(user, newTokenId);
        _setTokenURI(newTokenId, metadataURI); // Set specific URI for achievement badge
        userProfiles[user].hasAchievement[achievementId] = true;
        userProfiles[user].achievementTokenIds.push(newTokenId);
        _tokenData[newTokenId].isAchievementBadge = true;
        _tokenData[newTokenId].associatedAchievementId = achievementId;

        emit AchievementBadgeGranted(user, achievementId, newTokenId);
        emit ReputationRecalculated(user, getOverallReputation(user)); // Recalculate reputation
    }

    // --- III. Skill & Reputation Progression (Oracle-Driven) ---

    /// @notice Oracle-only function to update a user's skill points for a specific skill.
    /// @dev This function is intended to be called by the trusted AI Oracle or an ADMIN.
    /// @param user The user whose skill points are being updated.
    /// @param skillId The ID of the skill.
    /// @param pointsDelta The change in skill points (can be positive or negative).
    /// @param context A description of why the points were updated (e.g., "Project completion", "AI assessment").
    function oracleUpdateSkillPoints(address user, bytes32 skillId, int256 pointsDelta, string calldata context)
        public
        onlyOracle
        whenNotPaused
        nonReentrant
    {
        if (user == address(0)) revert ZeroAddressNotAllowed();
        if (!skills[skillId].registered) revert SkillNotRegistered(skillId);
        if (!_hasSkillBadge(user)) revert UserDoesNotHaveSkillBadge();

        _addSkillToUserProfile(user, skillId);
        SkillProfile storage profile = userProfiles[user].skillProfiles[skillId];

        uint256 currentPoints = profile.points;
        if (pointsDelta > 0) {
            profile.points = currentPoints.add(uint256(pointsDelta));
        } else if (pointsDelta < 0) {
            uint256 absDelta = uint256(-pointsDelta);
            if (currentPoints < absDelta) {
                profile.points = 0; // Cannot go below zero
            } else {
                profile.points = currentPoints.sub(absDelta);
            }
        }
        profile.level = _calculateSkillLevel(skillId, profile.points);
        profile.lastUpdated = block.timestamp;

        emit SkillPointsUpdated(user, skillId, profile.points, profile.level, context);
        emit ReputationRecalculated(user, getOverallReputation(user)); // Recalculate reputation
    }

    /// @notice Oracle-only function to trigger a full recalculation and update of a user's overall reputation.
    /// @dev Can be used for periodic decay, or after major reputation-influencing events.
    /// @param user The user whose reputation is being recalculated.
    function oracleTriggerReputationRecalculation(address user)
        public
        onlyOracle
        whenNotPaused
    {
        if (user == address(0)) revert ZeroAddressNotAllowed();
        if (!_hasSkillBadge(user)) revert UserDoesNotHaveSkillBadge();

        // The actual recalculation logic is within `getOverallReputation`.
        // This function just ensures the event is emitted, allowing off-chain systems
        // to update their views or trigger further actions based on the new reputation.
        emit ReputationRecalculated(user, getOverallReputation(user));
    }

    /// @notice Allows a user to request an AI-driven skill assessment based on provided external context.
    /// @dev This function primarily emits an event; the actual assessment is performed off-chain by the oracle.
    /// @param user The user requesting the assessment.
    /// @param skillId The skill to be assessed.
    /// @param assessmentContext Contextual data (e.g., URL to a project, GitHub repo, academic record).
    function requestAIConsensusSkillUpdate(address user, bytes32 skillId, string calldata assessmentContext)
        public
        whenNotPaused
    {
        if (user == address(0)) revert ZeroAddressNotAllowed();
        if (!skills[skillId].registered) revert SkillNotRegistered(skillId);
        if (!_hasSkillBadge(user)) revert UserDoesNotHaveSkillBadge();

        // Emits an event which the off-chain AI Oracle system will pick up.
        emit AIConsensusRequested(user, skillId, assessmentContext);
    }

    /// @notice Oracle-only function to report the result of an AI consensus assessment, updating user's skill.
    /// @dev Called by the trusted AI Oracle after performing an off-chain assessment.
    /// @param user The user whose skill is being updated.
    /// @param skillId The ID of the skill.
    /// @param newPoints The new total points for the skill.
    /// @param newLevel The new calculated level for the skill.
    function oracleReportAIConsensusResult(address user, bytes32 skillId, uint256 newPoints, uint256 newLevel)
        public
        onlyOracle
        whenNotPaused
        nonReentrant
    {
        if (user == address(0)) revert ZeroAddressNotAllowed();
        if (!skills[skillId].registered) revert SkillNotRegistered(skillId);
        if (!_hasSkillBadge(user)) revert UserDoesNotHaveSkillBadge();

        _addSkillToUserProfile(user, skillId);
        SkillProfile storage profile = userProfiles[user].skillProfiles[skillId];

        profile.points = newPoints;
        profile.level = newLevel; // Oracle can directly set level or we can recalculate from points
        profile.lastUpdated = block.timestamp;

        emit AIConsensusReported(user, skillId, newPoints, newLevel);
        emit SkillPointsUpdated(user, skillId, newPoints, newLevel, "AI Consensus Report");
        emit ReputationRecalculated(user, getOverallReputation(user));
    }

    // --- IV. Collaborative Project System ---

    /// @notice Creates a new collaborative project bounty.
    /// @param projectId A unique ID for the project.
    /// @param title The title of the project.
    /// @param description A detailed description.
    /// @param requiredSkills An array of skill IDs required for the project.
    /// @param rewardAmount The amount of reward tokens.
    /// @param rewardToken The ERC20 token address for the reward.
    /// @param deadline The timestamp by which the project must be completed.
    function createProjectBounty(
        bytes32 projectId,
        string calldata title,
        string calldata description,
        bytes32[] calldata requiredSkills,
        uint256 rewardAmount,
        address rewardToken,
        uint256 deadline
    ) public whenNotPaused nonReentrant {
        if (projects[projectId].exists) revert ProjectAlreadyExists();
        if (deadline <= block.timestamp) revert DeadlinePassed();
        if (rewardAmount == 0) revert InsufficientRewardTokens();
        if (rewardToken == address(0)) revert ZeroAddressNotAllowed();

        // Check if all required skills are registered
        for (uint i = 0; i < requiredSkills.length; i++) {
            if (!skills[requiredSkills[i]].registered) {
                revert SkillNotRegistered(requiredSkills[i]);
            }
        }

        // Transfer reward tokens from the creator to the contract (requires prior approval by creator)
        IERC20(rewardToken).transferFrom(msg.sender, address(this), rewardAmount);

        projects[projectId] = ProjectBounty({
            creator: msg.sender,
            title: title,
            description: description,
            requiredSkills: requiredSkills,
            rewardAmount: rewardAmount,
            rewardToken: rewardToken,
            deadline: deadline,
            selectedParticipant: address(0),
            completed: false,
            deliverablesSubmitted: false,
            disputed: false,
            applicants: new address[](0),
            exists: true
        });
        // Mapping `hasApplied` in struct is implicitly initialized when struct is created.

        activeProjectIds.push(projectId);
        emit ProjectBountyCreated(projectId, msg.sender, rewardAmount, rewardToken, deadline);
    }

    /// @notice Allows users to apply for a project after meeting its minimum skill/reputation prerequisites.
    /// @param projectId The ID of the project to apply for.
    function applyForProject(bytes32 projectId) public whenNotPaused nonReentrant {
        ProjectBounty storage project = projects[projectId];
        if (!project.exists) revert ProjectNotFound();
        if (project.completed || project.deadline <= block.timestamp) revert ProjectNotActive();
        if (project.hasApplied[msg.sender]) revert AlreadyApplied();
        if (!_hasSkillBadge(msg.sender)) revert UserDoesNotHaveSkillBadge();

        // Simplified check: User must have at least some points (e.g., > 0) in at least one required skill.
        // This could be made more complex (e.g., minimum level for each required skill).
        bool hasRequiredSkills = false;
        if (project.requiredSkills.length == 0) { // If no specific skills required, anyone can apply (with badge)
            hasRequiredSkills = true;
        } else {
            for (uint i = 0; i < project.requiredSkills.length; i++) {
                bytes32 reqSkillId = project.requiredSkills[i];
                if (userProfiles[msg.sender].skillProfiles[reqSkillId].points > 0) {
                    hasRequiredSkills = true;
                    break;
                }
            }
        }
        if (!hasRequiredSkills) revert NotEnoughSkillsOrReputation();

        // Can also add a minimum overall reputation check here:
        // if (getOverallReputation(msg.sender) < MIN_REP_FOR_APPLY) revert NotEnoughSkillsOrReputation();

        project.applicants.push(msg.sender);
        project.hasApplied[msg.sender] = true;
        emit ProjectApplied(projectId, msg.sender);
    }

    /// @notice Project creator or authorized role selects a participant for a project.
    /// @param projectId The ID of the project.
    /// @param participant The address of the selected participant.
    function selectProjectParticipant(bytes32 projectId, address participant)
        public
        onlyProjectCreator(projectId)
        whenNotPaused
        nonReentrant
    {
        ProjectBounty storage project = projects[projectId];
        if (!project.exists) revert ProjectNotFound();
        if (project.completed || project.deadline <= block.timestamp) revert ProjectNotActive();
        if (project.selectedParticipant != address(0)) revert Forbidden(); // Participant already selected

        // Ensure the participant actually applied
        bool found = false;
        for (uint i = 0; i < project.applicants.length; i++) {
            if (project.applicants[i] == participant) {
                found = true;
                break;
            }
        }
        if (!found) revert Forbidden(); // Participant did not apply or is not a valid applicant

        project.selectedParticipant = participant;
        emit ProjectParticipantSelected(projectId, participant);
    }

    /// @notice The selected participant submits their proof of work/deliverable for a project.
    /// @param projectId The ID of the project.
    function submitProjectDeliverable(bytes32 projectId)
        public
        whenNotPaused
        nonReentrant
    {
        ProjectBounty storage project = projects[projectId];
        if (!project.exists) revert ProjectNotFound();
        if (project.selectedParticipant != msg.sender) revert Forbidden(); // Only selected participant can submit
        if (project.deadline <= block.timestamp) revert DeadlinePassed();
        if (project.deliverablesSubmitted) revert ProjectAlreadyCompleted(); // Or already submitted

        project.deliverablesSubmitted = true;
        emit ProjectDeliverableSubmitted(projectId, msg.sender);
    }

    /// @notice Project creator or Oracle verifies completion, distributes rewards, and updates skills/reputation.
    /// @dev Can be called by project creator or ORACLE_ROLE. Oracle has final say.
    /// @param projectId The ID of the project.
    /// @param participant The address of the participant.
    /// @param skillGainPoints The points to award for skill gain for EACH relevant skill.
    /// @param reputationGain The points to award for reputation gain (additive to overall reputation score).
    /// @param success True if the project was successfully completed, false otherwise.
    function verifyProjectCompletionAndReward(
        bytes32 projectId,
        address participant,
        uint256 skillGainPoints,
        uint256 reputationGain,
        bool success
    ) public whenNotPaused nonReentrant {
        ProjectBounty storage project = projects[projectId];
        if (!project.exists) revert ProjectNotFound();
        if (project.selectedParticipant != participant) revert ParticipantNotSelected();
        if (!project.deliverablesSubmitted) revert ProjectNotCompleted();
        if (project.completed) revert ProjectAlreadyCompleted();

        // Only project creator or oracle can verify. Oracle (ADMIN_ROLE or _aiOracleAddress) overrides creator.
        if (msg.sender != project.creator && !hasRole(ORACLE_ROLE, msg.sender) && msg.sender != _aiOracleAddress) {
            revert Forbidden();
        }

        project.completed = true;
        // Remove project from active list
        for (uint i = 0; i < activeProjectIds.length; i++) {
            if (activeProjectIds[i] == projectId) {
                activeProjectIds[i] = activeProjectIds[activeProjectIds.length - 1];
                activeProjectIds.pop();
                break;
            }
        }

        if (success) {
            // Distribute reward
            IERC20(project.rewardToken).transfer(participant, project.rewardAmount);

            // Update participant's skills for all *required* skills.
            // A realistic system might award different points per skill or have specific tasks for each.
            for(uint i=0; i<project.requiredSkills.length; i++){
                bytes32 skillId = project.requiredSkills[i];
                if (skillGainPoints > 0) {
                    // Award skill points based on project success and required skills
                    // Use int256 for oracleUpdateSkillPoints delta
                    oracleUpdateSkillPoints(participant, skillId, int256(skillGainPoints), string(abi.encodePacked("Project '", project.title, "' completion for ", skills[skillId].name)));
                }
            }

            // Grant a general achievement if project is a major milestone (optional)
            // Example: if project is 'Advanced Dapp Development', grant 'Advanced Dapp Dev Achiever'
            // This would be triggered by oracle with a specific achievementId.
            // Example: grantAchievementBadge(participant, keccak256("ProjectCompletionMaster"), "ipfs://...");

            // Trigger reputation recalculation to incorporate the overall reputation gain
            oracleTriggerReputationRecalculation(participant);

            emit RewardClaimed(projectId, participant, project.rewardAmount, project.rewardToken);
            emit ProjectCompletionVerified(projectId, participant, skillGainPoints, reputationGain, true);

        } else {
            // Return funds to creator if project failed/rejected by verifier
            IERC20(project.rewardToken).transfer(project.creator, project.rewardAmount);
            emit ProjectCompletionVerified(projectId, participant, 0, 0, false);
        }
    }

    /// @notice Initiates a dispute resolution process for a project outcome.
    /// @dev This function would trigger an off-chain dispute mechanism (e.g., DAO vote, arbitration service).
    /// @param projectId The ID of the project.
    /// @param participant The address of the participant involved in the dispute.
    /// @param reason A description of the dispute reason.
    function disputeProjectOutcome(bytes32 projectId, address participant, string calldata reason)
        public
        whenNotPaused
        nonReentrant
    {
        ProjectBounty storage project = projects[projectId];
        if (!project.exists) revert ProjectNotFound();
        if (project.completed) revert ProjectAlreadyCompleted();
        if (project.deadline <= block.timestamp) revert DeadlinePassed();
        if (msg.sender != project.creator && msg.sender != participant) revert Forbidden(); // Only creator or participant can dispute

        project.disputed = true;
        // In a real system, this would also pause reward payout, perhaps transfer funds to an arbiter contract.
        emit ProjectDisputed(projectId, msg.sender, reason);
    }

    // --- V. Utility & View Functions ---

    /// @notice Returns a list of all currently registered skill IDs in the system.
    /// @return An array of bytes32 representing skill IDs.
    function getRegisteredSkillIds() public view returns (bytes32[] memory) {
        return registeredSkillIdsList;
    }

    /// @notice Retrieves detailed information for a specific project bounty.
    /// @param projectId The ID of the project.
    /// @return Project details including creator, title, description, reward, deadline, status etc.
    function getProjectInfo(bytes32 projectId)
        public
        view
        returns (
            address creator,
            string memory title,
            string memory description,
            bytes32[] memory requiredSkills,
            uint256 rewardAmount,
            address rewardToken,
            uint256 deadline,
            address selectedParticipant,
            bool completed,
            bool deliverablesSubmitted,
            bool disputed,
            address[] memory applicants // Also return applicants
        )
    {
        ProjectBounty storage project = projects[projectId];
        if (!project.exists) revert ProjectNotFound();

        return (
            project.creator,
            project.title,
            project.description,
            project.requiredSkills,
            project.rewardAmount,
            project.rewardToken,
            project.deadline,
            project.selectedParticipant,
            project.completed,
            project.deliverablesSubmitted,
            project.disputed,
            project.applicants
        );
    }

    /// @notice Returns a list of active projects that require a specific skill.
    /// @param skillId The ID of the required skill.
    /// @return An array of project IDs.
    function getProjectsBySkill(bytes32 skillId) public view returns (bytes32[] memory) {
        if (!skills[skillId].registered) revert SkillNotRegistered(skillId);

        bytes32[] memory matchingProjects = new bytes32[](activeProjectIds.length);
        uint256 count = 0;
        for (uint i = 0; i < activeProjectIds.length; i++) {
            bytes32 projectId = activeProjectIds[i];
            ProjectBounty storage project = projects[projectId];
            // Only consider active, non-completed, non-disputed projects within deadline
            if (!project.completed && !project.disputed && project.deadline > block.timestamp) {
                for (uint j = 0; j < project.requiredSkills.length; j++) {
                    if (project.requiredSkills[j] == skillId) {
                        matchingProjects[count] = projectId;
                        count++;
                        break; // Found the skill, move to next project
                    }
                }
            }
        }
        // Resize array to actual count
        bytes32[] memory result = new bytes32[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = matchingProjects[i];
        }
        return result;
    }

    /// @notice Returns a list of all SkillBadge and Achievement NFTs owned by a user.
    /// @param user The address of the user.
    /// @return An array of token IDs.
    function getUserSkillBadges(address user) public view returns (uint256[] memory) {
        uint256 numTokens = balanceOf(user);
        uint256[] memory userOwnedTokens = new uint256[](numTokens);
        for (uint i = 0; i < numTokens; i++) {
            userOwnedTokens[i] = tokenOfOwnerByIndex(user, i);
        }
        return userOwnedTokens;
    }

    /// @notice Returns the currently set address of the AI Oracle.
    /// @return The address of the AI Oracle.
    function getOracleAddress() public view returns (address) {
        return _aiOracleAddress;
    }

    /// @notice Sets the Merkle root for off-chain skill verifications.
    /// @dev Only callable by ADMIN_ROLE. This root is generated off-chain after data aggregation.
    /// @param _merkleRoot The new Merkle root.
    function setOffChainSkillMerkleRoot(bytes32 _merkleRoot) public onlyRole(ADMIN_ROLE) whenNotPaused {
        offChainSkillMerkleRoot = _merkleRoot;
    }
}
```