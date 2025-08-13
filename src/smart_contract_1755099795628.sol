This smart contract, **NexusLore**, introduces the concept of **Adaptive Digital Beings** as NFTs that dynamically evolve based on user interactions, external data, and inter-being dynamics. It combines elements of dynamic NFTs, on-chain reputation systems, gamified progression, and secure oracle integration for AI-driven lore generation, all designed to be distinct from commonly available open-source implementations.

---

## NexusLore - Adaptive Digital Beings Smart Contract

**Solidity Version:** `^0.8.20`

### Outline:
*   **I. Core ERC721-like NFT Management (Adaptive Digital Beings)**: Handles the creation and state retrieval of dynamic NFTs. Includes custom `tokenURI` logic to reflect evolving metadata.
*   **II. Dynamic State & Evolution System**: Manages internal "Affinity" as a resource, drives being evolution, and controls the LoreScore and Alignment attributes.
*   **III. Trait & Skill Tree Progression**: Allows owners to allocate skill points, initiate time-locked training, and activate special traits based on accumulated progress and conditions.
*   **IV. Oracle & External Data Integration**: Enables authorized oracles to inject environmental data and facilitates off-chain AI-generated lore insights based on on-chain events.
*   **V. Gamified Interaction & Challenges**: Implements mechanics for beings to participate in and resolve challenges, and to "consult" with other beings for mutual benefits.
*   **VI. Role-Based Access Control & System Governance**: A custom RBAC system to manage permissions for various administrative and operational functions.
*   **VII. Pausability & Emergency Functions**: Standard mechanism to pause the contract in case of emergencies.

### Function Summary:

**I. Core ERC721-like NFT Management (Adaptive Digital Beings)**
1.  `mintBeing(address _owner, string memory _initialMetadataURI)`: Mints a new unique digital being (NFT) to a specified owner with an initial metadata URI.
2.  `getBeingState(uint256 _tokenId)`: Retrieves the detailed current state of a specific being, including its core attributes, skills, and traits.
3.  `tokenURI(uint256 _tokenId)`: Overrides ERC721's `tokenURI` to provide a dynamically generated metadata URI that reflects the being's current evolving state, pointing to an off-chain metadata service.
4.  `getBeingLoreStatus(uint256 _tokenId)`: Returns the current operational status of a being (e.g., Active, Dormant, Bound).

**II. Dynamic State & Evolution System**
5.  `pledgeAffinity(uint256 _tokenId, uint256 _amount)`: Allows a being's owner to pledge "Affinity" (an internal resource, not an ERC-20) to their being, fueling its potential for growth.
6.  `evolveBeing(uint256 _tokenId, uint256 _essenceAmount)`: Triggers an evolution cycle for a being, consuming Essence (derived from pledged Affinity) and updating its LoreScore and Alignment based on accumulated evolution points.
7.  `adjustLoreScore(uint256 _tokenId, int256 _adjustment)`: A privileged function (callable by LoreKeepers) to directly adjust a being's LoreScore, typically used for external event outcomes.
8.  `setEvolutionRate(uint256 _newRate)`: Sets the global rate at which Essence contributes to evolution, influencing the pace of being progression.

**III. Trait & Skill Tree Progression**
9.  `allocateSkillPoint(uint256 _tokenId, SkillType _skillId)`: Allows a being's owner to allocate a skill point to a specific skill, enhancing its capabilities.
10. `trainSkill(uint256 _tokenId, SkillType _skillId, uint256 _durationBlocks)`: Initiates a time-locked training period for a specified skill, consuming a small amount of Affinity.
11. `completeSkillTraining(uint256 _tokenId)`: Finalizes an active skill training session, applying the learned benefits and updating the being's skill levels and alignments.
12. `activateTrait(uint256 _tokenId, TraitType _traitId)`: Activates a specific special trait for a being, provided the complex prerequisite conditions (e.g., LoreScore, skill levels, environmental factors) are met.
13. `queryTraitInfluence(uint256 _tokenId, TraitType _traitId)`: Calculates and returns the current dynamic influence or effectiveness of a specific active trait, based on the being's real-time state.

**IV. Oracle & External Data Integration**
14. `updateEnvironmentalFactor(EnvironmentalFactor _factor, uint256 _value)`: Callable by an authorized Oracle Manager to inject real-world or simulated environmental data, influencing global or being-specific conditions.
15. `requestLoreInsight(uint256 _tokenId, InsightType _type)`: Emits an event signaling an off-chain AI service to generate a contextual lore insight or prediction for a specific being.
16. `receiveLoreInsight(uint256 _tokenId, string memory _newLoreSnippet, uint256 _aiConfidenceScore)`: A secure callback from a trusted off-chain AI oracle to update a being's `latestLoreSnippet` and `loreSnippetConfidence` on-chain.

**V. Gamified Interaction & Challenges**
17. `participateInChallenge(uint256 _tokenId, ChallengeType _challengeId)`: Registers a being to participate in an active challenge, consuming a set amount of Affinity.
18. `resolveChallenge(uint256 _challengeId, uint256[] memory _participantTokens, uint256[] memory _challengeOutcomes)`: Callable by a LoreKeeper to officially resolve a challenge, applying various outcomes (e.g., LoreScore adjustments, Affinity rewards, trait unlocks, or even `Bound` status) to participants.
19. `initiateInterBeingConsultation(uint256 _tokenId1, uint256 _tokenId2)`: Allows two beings to "consult" each other, potentially leading to shared skill progression or unique trait influences based on their combined attributes.
20. `setChallengeParameters(ChallengeType _challengeId, uint256 _essenceCost, uint256 _rewardBasis, uint256 _minParticipants, uint256 _maxParticipants, uint256 _registrationDurationBlocks, uint256 _resolutionDurationBlocks)`: Configures the rules and parameters for a specific challenge type, making it active for participation.

**VI. Role-Based Access Control & System Governance**
21. `grantRole(address _account, Role _role)`: Grants a specific administrative or operational role to an address, managed by the default admin.
22. `revokeRole(address _account, Role _role)`: Revokes a specific role from an address.
23. `hasRole(address _account, Role _role)`: Checks if a given address possesses a specific role.

**VII. Pausability & Emergency Functions**
24. `pauseSystem()`: Halts all critical contract interactions, callable by the default admin in emergencies.
25. `unpauseSystem()`: Resumes normal contract operations after a pause.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // For initial deployment, will transition to custom roles for primary access control.

// NOTE: This contract is a conceptual design showcasing advanced, creative, and trendy functionalities.
// It is designed to be distinct from common open-source implementations by combining novel mechanics.
// For a production environment, it would require comprehensive security audits, gas optimization,
// and robust off-chain infrastructure (oracles, AI services) with secure communication channels.

// --- Contract Outline ---
// I.  Core ERC721-like NFT Management (Adaptive Digital Beings)
// II. Dynamic State & Evolution System (Essence, LoreScore, Alignment)
// III.Trait & Skill Tree Progression
// IV. Oracle & External Data Integration (Environmental Factors, AI Lore)
// V.  Gamified Interaction & Challenges (Inter-Being Dynamics)
// VI. Role-Based Access Control & System Governance (Custom Implementation)
// VII.Pausability & Emergency Functions

// --- Function Summary ---

// I. Core ERC721-like NFT Management (Adaptive Digital Beings)
// 1.  `mintBeing(address _owner, string memory _initialMetadataURI)`: Mints a new unique digital being (NFT).
// 2.  `getBeingState(uint256 _tokenId)`: Retrieves the detailed current state of a specific being.
// 3.  `tokenURI(uint256 _tokenId)`: Overrides ERC721's tokenURI to provide a dynamic metadata URI based on the being's evolving state.
// 4.  `getBeingLoreStatus(uint256 _tokenId)`: Returns the current operational status of a being (e.g., Active, Dormant).

// II. Dynamic State & Evolution System
// 5.  `pledgeAffinity(uint256 _tokenId, uint256 _amount)`: Allows a user to pledge "Affinity" to a being, fueling its growth.
// 6.  `evolveBeing(uint256 _tokenId, uint256 _essenceAmount)`: Triggers evolution for a being, consuming Essence (derived from Affinity) and updating traits/LoreScore.
// 7.  `adjustLoreScore(uint256 _tokenId, int256 _adjustment)`: Admin/Oracle function to directly adjust a being's LoreScore.
// 8.  `setEvolutionRate(uint256 _newRate)`: Sets the global rate at which Essence contributes to evolution (governable).

// III. Trait & Skill Tree Progression
// 9.  `allocateSkillPoint(uint256 _tokenId, SkillType _skillId)`: User allocates a skill point to a specific skill for their being.
// 10. `trainSkill(uint256 _tokenId, SkillType _skillId, uint256 _durationBlocks)`: Initiates a time-locked training period for a skill.
// 11. `completeSkillTraining(uint256 _tokenId)`: Finalizes an active skill training, applying benefits.
// 12. `activateTrait(uint256 _tokenId, TraitType _traitId)`: Activates a specific trait for a being, if conditions are met.
// 13. `queryTraitInfluence(uint256 _tokenId, TraitType _traitId)`: Returns the current calculated influence/value of a specific trait.

// IV. Oracle & External Data Integration
// 14. `updateEnvironmentalFactor(EnvironmentalFactor _factor, uint256 _value)`: Callable by an authorized Oracle to inject real-world or simulated environmental data.
// 15. `requestLoreInsight(uint256 _tokenId, InsightType _type)`: Emits an event requesting an off-chain AI service to generate a lore insight.
// 16. `receiveLoreInsight(uint256 _tokenId, string memory _newLoreSnippet, uint256 _aiConfidenceScore)`: Callback from a trusted off-chain AI oracle, updating a being's lore.

// V. Gamified Interaction & Challenges
// 17. `participateInChallenge(uint256 _tokenId, ChallengeType _challengeId)`: Registers a being for a specific challenge.
// 18. `resolveChallenge(uint256 _challengeId, uint256[] memory _participantTokens, uint256[] memory _challengeOutcomes)`: Callable by a LoreKeeper/Oracle to resolve a challenge and apply outcomes.
// 19. `initiateInterBeingConsultation(uint256 _tokenId1, uint256 _tokenId2)`: Two beings "consult" each other, potentially leading to shared skill/trait progression.
// 20. `setChallengeParameters(ChallengeType _challengeId, uint256 _essenceCost, uint256 _rewardBasis, uint256 _minParticipants, uint256 _maxParticipants, uint256 _registrationDurationBlocks, uint256 _resolutionDurationBlocks)`: Configures specific challenge parameters.

// VI. Role-Based Access Control & System Governance (Custom Implementation)
// 21. `grantRole(address _account, Role _role)`: Grants a specific administrative role to an address.
// 22. `revokeRole(address _account, Role _role)`: Revokes a specific administrative role from an address.
// 23. `hasRole(address _account, Role _role)`: Checks if an address holds a specific role.

// VII. Pausability & Emergency Functions
// 24. `pauseSystem()`: Pauses all core interactions of the contract.
// 25. `unpauseSystem()`: Unpauses the contract, allowing interactions again.


contract NexusLore is ERC721, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;

    // --- Enums ---
    enum Role {
        DEFAULT_ADMIN_ROLE,    // Controls system-level configurations and grants/revokes other roles.
        LOREKEEPER_ROLE,       // Manages LoreScores, resolves challenges, and might set special being statuses.
        ORACLE_MANAGER_ROLE,   // Responsible for updating environmental data and feeding AI insights.
        CHALLENGE_MASTER_ROLE  // Configures and activates challenges.
    }

    enum LoreStatus {
        Active,       // Normal operational status.
        Dormant,      // Temporarily inactive, might require activation.
        Bound,        // Soulbound; cannot be transferred (unique achievement/penalty).
        Deactivated   // Permanently inactive (e.g., for severe violations).
    }

    enum SkillType {
        MysticAffinities,    // Related to esoteric knowledge and energy manipulation.
        TechnicAdaptation,   // Related to technological understanding and integration.
        NatureHarmonization, // Related to ecological balance and natural forces.
        StrategicInsight,    // Related to planning, tactics, and foresight.
        EmpathicResonance    // Related to understanding and influencing emotional states.
    }

    enum TraitType {
        ResilientWill,     // Increases resistance to negative LoreScore shifts.
        ArcaneSurge,       // Boosts MysticAffinities under certain cosmic conditions.
        TechSavvy,         // Improves TechnicAdaptation skill gain.
        Biomimicry,        // Enhances NatureHarmonization based on environmental factors.
        InsightfulVision,  // Provides bonuses in specific challenges.
        UnseenPresence     // Allows stealthy participation in certain interactions.
    }

    enum EnvironmentalFactor {
        CosmicRadiation,    // External cosmic energy levels.
        PlanetaryAlignment, // Influence from celestial body positions.
        AethericDensity,    // Pervasive magical or spiritual energy density.
        EconomicStability,  // Abstract representation of economic health.
        CulturalVibration   // Abstract representation of societal mood/trends.
    }

    enum ChallengeType {
        TrialOfEssence,       // Tests a being's raw evolutionary potential.
        RiddleOfAether,       // Requires high MysticAffinities and StrategicInsight.
        ConvergenceProtocol,  // Collaborative challenge for multiple beings.
        TemporalDrift         // Time-sensitive challenge, testing speed and adaptation.
    }

    enum InsightType {
        LoreNarrative,      // Request for a story fragment about the being's past/future.
        FuturePrediction,   // Request for a speculative outlook on the being's destiny.
        HistoricalContext   // Request for background information relevant to the being's traits.
    }

    // --- Structs ---
    struct BeingState {
        uint256 tokenId;
        address owner;
        LoreStatus status;
        uint256 creationBlock;
        uint256 lastEvolutionBlock;
        uint256 totalEssenceConsumed; // Accumulation of essence used for evolution.
        uint256 currentAffinity;      // Pledged affinity, available to be converted to essence.

        int256 loreScore; // Reputation/alignment score, from MIN_LORE_SCORE to MAX_LORE_SCORE.
        uint256 alignmentMystic; // 0-100, influences trait effectiveness and skill gain.
        uint256 alignmentTechnic; // 0-100.
        uint256 alignmentNature;  // 0-100.

        mapping(SkillType => uint256) skills; // Skill points allocated per skill type.
        mapping(TraitType => bool) activeTraits; // Whether a trait is currently active.
        mapping(TraitType => uint256) traitActivationBlock; // Block number when a trait became active.

        uint256 currentTrainingSkill; // Stores the SkillType (as uint) currently being trained.
        uint256 trainingCompletionBlock; // Block number when current training finishes.
        bool isTraining; // True if a being is currently undergoing training.

        string latestLoreSnippet; // The most recent AI-generated lore fragment.
        uint256 loreSnippetConfidence; // AI confidence score for the latest lore snippet (0-100).
    }

    struct Challenge {
        ChallengeType challengeId;
        uint256 essenceCostPerParticipant; // Affinity cost to join.
        uint256 rewardBasis; // Base multiplier for rewards.
        uint256 minParticipants; // Minimum beings required to start/resolve.
        uint256 maxParticipants; // Maximum beings allowed.
        uint256 registrationDeadline; // Block number by which beings must register.
        uint256 resolutionDeadline;   // Block number by which challenge must be resolved.
        uint256[] participants;       // List of tokenIds registered for this challenge.
        bool isActive;   // True if the challenge is currently open for registration/resolution.
        bool isResolved; // True if the challenge has been resolved.
    }

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;

    // Core storage for beings
    mapping(uint256 => BeingState) private _beings;
    mapping(uint256 => string) private _beingBaseMetadataURIs; // Stores the base URI part for dynamic metadata.

    // System parameters
    uint256 public essenceToEvolutionRatio = 100; // Defines how much essence is needed for one evolution unit.
    uint256 public constant MAX_LORE_SCORE = 1000;
    uint256 public constant MIN_LORE_SCORE = -1000;
    uint256 public constant MAX_ALIGNMENT = 100;

    // Environmental factors updated by Oracles
    mapping(EnvironmentalFactor => uint256) public environmentalFactors;

    // Challenges configuration and state
    mapping(ChallengeType => Challenge) public challenges;
    uint256[] public activeChallengeIds; // Array to easily list currently active challenges.

    // Pausability state
    bool public paused = false;

    // Role-Based Access Control (Custom implementation to avoid direct OZ AccessControl duplication)
    mapping(Role => mapping(address => bool)) private _roles;
    // Helper mapping for role names for error messages
    mapping(Role => string) private _roleName;


    // --- Events ---
    event BeingMinted(uint256 indexed tokenId, address indexed owner, string initialURI);
    event AffinityPledged(uint256 indexed tokenId, address indexed pledger, uint256 amount);
    event BeingEvolved(uint256 indexed tokenId, uint256 essenceConsumed, int256 newLoreScore);
    event LoreScoreAdjusted(uint256 indexed tokenId, int256 adjustment, int256 newScore);
    event SkillPointAllocated(uint256 indexed tokenId, SkillType indexed skillId, uint256 newLevel);
    event SkillTrainingInitiated(uint256 indexed tokenId, SkillType indexed skillId, uint256 completionBlock);
    event SkillTrainingCompleted(uint256 indexed tokenId, SkillType indexed skillId, uint256 newLevel);
    event TraitActivated(uint256 indexed tokenId, TraitType indexed traitId);
    event EnvironmentalFactorUpdated(EnvironmentalFactor indexed factor, uint256 value);
    event LoreInsightRequested(uint256 indexed tokenId, InsightType indexed insightType);
    event LoreInsightReceived(uint256 indexed tokenId, string newLoreSnippet, uint256 confidenceScore);
    event ChallengeRegistered(ChallengeType indexed challengeId, uint256 indexed tokenId);
    event ChallengeResolved(ChallengeType indexed challengeId, uint256[] indexed participantTokens, uint256[] outcomes);
    event InterBeingConsultationInitiated(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event RoleGranted(Role indexed role, address indexed account);
    event RoleRevoked(Role indexed role, address indexed account);
    event Paused(address account);
    event Unpaused(address account);
    event BeingLoreStatusChanged(uint256 indexed tokenId, LoreStatus newStatus);

    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!paused, "System is paused");
        _;
    }

    modifier onlyRole(Role _role) {
        require(_roles[_role][msg.sender], string(abi.encodePacked("AccessControl: caller is not a ", _roleName[_role], " role")));
        _;
    }

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        // Grant deployer all initial roles
        _roles[Role.DEFAULT_ADMIN_ROLE][msg.sender] = true;
        _roleName[Role.DEFAULT_ADMIN_ROLE] = "DEFAULT_ADMIN_ROLE";
        _roleName[Role.LOREKEEPER_ROLE] = "LOREKEEPER_ROLE";
        _roleName[Role.ORACLE_MANAGER_ROLE] = "ORACLE_MANAGER_ROLE";
        _roleName[Role.CHALLENGE_MASTER_ROLE] = "CHALLENGE_MASTER_ROLE";

        // Initialize a default challenge setup for example purposes
        challenges[ChallengeType.TrialOfEssence] = Challenge({
            challengeId: ChallengeType.TrialOfEssence,
            essenceCostPerParticipant: 50,
            rewardBasis: 10,
            minParticipants: 2,
            maxParticipants: 10,
            registrationDeadline: 0, // Will be set when activated via setChallengeParameters
            resolutionDeadline: 0,
            participants: new uint256[](0),
            isActive: false, // Not active until parameters are set
            isResolved: false
        });
    }

    // --- I. Core ERC721-like NFT Management (Adaptive Digital Beings) ---

    // 1. Mints a new unique digital being (NFT).
    function mintBeing(address _owner, string memory _initialMetadataURI)
        public
        onlyRole(Role.DEFAULT_ADMIN_ROLE) // Only the admin can mint new beings.
        whenNotPaused
        returns (uint256)
    {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(_owner, newTokenId); // Standard ERC721 mint

        BeingState storage newBeing = _beings[newTokenId];
        newBeing.tokenId = newTokenId;
        newBeing.owner = _owner;
        newBeing.status = LoreStatus.Active;
        newBeing.creationBlock = block.number;
        newBeing.lastEvolutionBlock = block.number;
        newBeing.loreScore = 0; // Neutral starting LoreScore
        newBeing.alignmentMystic = 50; // Neutral starting alignments
        newBeing.alignmentTechnic = 50;
        newBeing.alignmentNature = 50;
        newBeing.currentAffinity = 0;
        newBeing.totalEssenceConsumed = 0;
        newBeing.isTraining = false;
        newBeing.latestLoreSnippet = "A new being awakens, its destiny unwritten."; // Initial lore snippet
        newBeing.loreSnippetConfidence = 100; // Initial confidence for the base lore.

        _beingBaseMetadataURIs[newTokenId] = _initialMetadataURI; // Stores the base URI for dynamic metadata.

        emit BeingMinted(newTokenId, _owner, _initialMetadataURI);
        return newTokenId;
    }

    // 2. Retrieves the detailed current state of a specific being.
    function getBeingState(uint256 _tokenId)
        public
        view
        returns (
            uint256 tokenId,
            address owner,
            LoreStatus status,
            uint256 creationBlock,
            uint256 lastEvolutionBlock,
            uint256 totalEssenceConsumed,
            uint256 currentAffinity,
            int256 loreScore,
            uint256 alignmentMystic,
            uint256 alignmentTechnic,
            uint256 alignmentNature,
            uint256 currentTrainingSkill,
            uint256 trainingCompletionBlock,
            bool isTraining,
            string memory latestLoreSnippet,
            uint256 loreSnippetConfidence
        )
    {
        require(_exists(_tokenId), "NexusLore: Being does not exist");
        BeingState storage being = _beings[_tokenId];

        tokenId = being.tokenId;
        owner = being.owner; // Note: This is the owner at the time of the BeingState snapshot. Use ownerOf(_tokenId) for current ERC721 owner.
        status = being.status;
        creationBlock = being.creationBlock;
        lastEvolutionBlock = being.lastEvolutionBlock;
        totalEssenceConsumed = being.totalEssenceConsumed;
        currentAffinity = being.currentAffinity;
        loreScore = being.loreScore;
        alignmentMystic = being.alignmentMystic;
        alignmentTechnic = being.alignmentTechnic;
        alignmentNature = being.alignmentNature;
        currentTrainingSkill = being.currentTrainingSkill;
        trainingCompletionBlock = being.trainingCompletionBlock;
        isTraining = being.isTraining;
        latestLoreSnippet = being.latestLoreSnippet;
        loreSnippetConfidence = being.loreSnippetConfidence;
    }

    // 3. Overrides ERC721's tokenURI to provide a dynamic metadata URI based on the being's evolving state.
    // This URI would point to an off-chain service that dynamically generates metadata JSON
    // by querying the contract's state parameters for the given token ID.
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        BeingState storage being = _beings[_tokenId];

        // Example: https://api.nexuslore.com/metadata/{tokenId}?ls={loreScore}&am={alignMystic}...
        // The query parameters are passed for convenience of the off-chain service.
        return string(abi.encodePacked(
            _beingBaseMetadataURIs[_tokenId],
            "?id=",
            _toString(_tokenId),
            "&ls=",
            _toString(being.loreScore),
            "&am=",
            _toString(being.alignmentMystic),
            "&at=",
            _toString(being.alignmentTechnic),
            "&an=",
            _toString(being.alignmentNature),
            "&skills=",
            _getSkillsAsQueryString(_tokenId),
            "&traits=",
            _getTraitsAsQueryString(_tokenId),
            "&loreStatus=",
            _toString(uint256(being.status)),
            "&loreSnippet=",
            being.latestLoreSnippet // URL-encoding would be handled by the off-chain service/client
        ));
    }

    // Internal helper to convert uint256 to string
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // Internal helper to convert int256 to string
    function _toString(int256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        bool negative = value < 0;
        if (negative) value = -value; // Convert to positive for digit calculation

        uint256 absValue = uint256(value);
        uint256 temp = absValue;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer;
        if (negative) {
            buffer = new bytes(digits + 1);
            buffer[0] = '-';
        } else {
            buffer = new bytes(digits);
        }

        uint256 i = buffer.length - 1;
        while (absValue != 0) {
            buffer[i] = bytes1(uint8(48 + uint256(absValue % 10)));
            absValue /= 10;
            i--;
        }
        return string(buffer);
    }

    // Helper to format skills for URI query string (e.g., "0:10,1:5")
    function _getSkillsAsQueryString(uint256 _tokenId) internal view returns (string memory) {
        BeingState storage being = _beings[_tokenId];
        string memory skillStr = "";
        // Assuming SkillType enum has 5 values from 0 to 4
        for (uint264 i = 0; i < 5; i++) {
            SkillType sType = SkillType(i);
            if (being.skills[sType] > 0) {
                skillStr = string(abi.encodePacked(skillStr, _toString(uint256(sType)), ":", _toString(being.skills[sType]), ","));
            }
        }
        if (bytes(skillStr).length > 0) {
            skillStr = skillStr[0:bytes(skillStr).length - 1]; // Remove trailing comma
        }
        return skillStr;
    }

    // Helper to format active traits for URI query string (e.g., "0,3,5")
    function _getTraitsAsQueryString(uint256 _tokenId) internal view returns (string memory) {
        BeingState storage being = _beings[_tokenId];
        string memory traitStr = "";
        // Assuming TraitType enum has 6 values from 0 to 5
        for (uint264 i = 0; i < 6; i++) {
            TraitType tType = TraitType(i);
            if (being.activeTraits[tType]) {
                traitStr = string(abi.encodePacked(traitStr, _toString(uint256(tType)), ","));
            }
        }
        if (bytes(traitStr).length > 0) {
            traitStr = traitStr[0:bytes(traitStr).length - 1]; // Remove trailing comma
        }
        return traitStr;
    }

    // 4. Returns the current operational status of a being.
    function getBeingLoreStatus(uint256 _tokenId) public view returns (LoreStatus) {
        require(_exists(_tokenId), "NexusLore: Being does not exist");
        return _beings[_tokenId].status;
    }

    // Override OpenZeppelin's _beforeTokenTransfer to enforce "Soulbound" status.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // If 'from' is not the zero address (i.e., it's an actual transfer, not minting/burning)
        if (from != address(0) && _beings[tokenId].status == LoreStatus.Bound) {
            revert("NexusLore: This being is Soulbound and cannot be transferred.");
        }
    }


    // --- II. Dynamic State & Evolution System ---

    // 5. Allows a user to pledge "Affinity" to a being, fueling its growth.
    // Affinity is an internal, non-transferable resource, representing a user's commitment.
    function pledgeAffinity(uint256 _tokenId, uint256 _amount) public payable whenNotPaused nonReentrant {
        require(_exists(_tokenId), "NexusLore: Being does not exist");
        require(msg.sender == ownerOf(_tokenId), "NexusLore: Only being owner can pledge affinity");
        require(_amount > 0, "NexusLore: Affinity amount must be positive");
        
        // Optional: A small ETH fee could be associated with pledging affinity to deter spam or fund the system.
        // require(msg.value >= _amount / 1000, "NexusLore: Insufficient ETH for Affinity pledge fee");

        _beings[_tokenId].currentAffinity += _amount;
        emit AffinityPledged(_tokenId, msg.sender, _amount);
    }

    // 6. Triggers evolution for a being, consuming Essence (derived from Affinity) and updating traits/LoreScore.
    // The `_essenceAmount` defines how much affinity is converted to essence for this specific evolution event.
    function evolveBeing(uint256 _tokenId, uint256 _essenceAmount) public whenNotPaused nonReentrant {
        require(_exists(_tokenId), "NexusLore: Being does not exist");
        require(msg.sender == ownerOf(_tokenId), "NexusLore: Only being owner can evolve");
        require(_essenceAmount > 0, "NexusLore: Must consume a positive essence amount");
        require(_beings[_tokenId].currentAffinity >= _essenceAmount, "NexusLore: Not enough pledged Affinity");
        require(block.number >= _beings[_tokenId].lastEvolutionBlock + 10, "NexusLore: Being needs time to recover from last evolution (10 block cooldown)"); // Cooldown

        BeingState storage being = _beings[_tokenId];
        being.currentAffinity -= _essenceAmount;
        being.totalEssenceConsumed += _essenceAmount;
        being.lastEvolutionBlock = block.number;

        // Evolution logic:
        // For every `essenceToEvolutionRatio` essence consumed, the being gains 1 evolution point.
        uint256 evolutionPoints = _essenceAmount / essenceToEvolutionRatio;
        if (evolutionPoints > 0) {
            // Apply positive LoreScore adjustment, capped by MAX_LORE_SCORE
            int256 newLoreScore = being.loreScore + int256(evolutionPoints);
            being.loreScore = Math.clamp(newLoreScore, MIN_LORE_SCORE, MAX_LORE_SCORE);

            // Simple alignment shift: each evolution point slightly pushes alignments.
            // More complex logic could involve skill allocations, environmental factors, etc.
            if (evolutionPoints % 3 == 0) being.alignmentMystic = Math.min(being.alignmentMystic + 1, MAX_ALIGNMENT);
            if (evolutionPoints % 3 == 1) being.alignmentTechnic = Math.min(being.alignmentTechnic + 1, MAX_ALIGNMENT);
            if (evolutionPoints % 3 == 2) being.alignmentNature = Math.min(being.alignmentNature + 1, MAX_ALIGNMENT);

            // Conditional trait activation example: ResilientWill activates if LoreScore and total essence consumed are high.
            if (!being.activeTraits[TraitType.ResilientWill] && being.loreScore >= 100 && being.totalEssenceConsumed >= 500) {
                being.activeTraits[TraitType.ResilientWill] = true;
                being.traitActivationBlock[TraitType.ResilientWill] = block.number;
                emit TraitActivated(_tokenId, TraitType.ResilientWill);
            }
        }

        emit BeingEvolved(_tokenId, _essenceAmount, being.loreScore);
    }

    // 7. Admin/Oracle function to directly adjust a being's LoreScore (e.g., from external events or corrections).
    function adjustLoreScore(uint256 _tokenId, int256 _adjustment) public onlyRole(Role.LOREKEEPER_ROLE) whenNotPaused {
        require(_exists(_tokenId), "NexusLore: Being does not exist");
        BeingState storage being = _beings[_tokenId];

        int256 newScore = being.loreScore + _adjustment;
        being.loreScore = Math.clamp(newScore, MIN_LORE_SCORE, MAX_LORE_SCORE);
        
        emit LoreScoreAdjusted(_tokenId, _adjustment, being.loreScore);
    }

    // 8. Sets the global rate at which Essence contributes to evolution (governable by admin).
    function setEvolutionRate(uint256 _newRate) public onlyRole(Role.DEFAULT_ADMIN_ROLE) whenNotPaused {
        require(_newRate > 0, "NexusLore: Evolution rate must be positive");
        essenceToEvolutionRatio = _newRate;
    }


    // --- III. Trait & Skill Tree Progression ---

    // 9. User allocates a skill point to a specific skill for their being.
    function allocateSkillPoint(uint256 _tokenId, SkillType _skillId) public whenNotPaused {
        require(_exists(_tokenId), "NexusLore: Being does not exist");
        require(msg.sender == ownerOf(_tokenId), "NexusLore: Only being owner can allocate skill points");
        
        // Example condition: Only allow allocation if a certain LoreScore threshold is met.
        require(_beings[_tokenId].loreScore >= 50, "NexusLore: LoreScore too low to allocate skill points (min 50)");
        
        _beings[_tokenId].skills[_skillId]++;
        emit SkillPointAllocated(_tokenId, _skillId, _beings[_tokenId].skills[_skillId]);
    }

    // 10. Initiates a time-locked training period for a skill.
    function trainSkill(uint256 _tokenId, SkillType _skillId, uint256 _durationBlocks) public whenNotPaused nonReentrant {
        require(_exists(_tokenId), "NexusLore: Being does not exist");
        require(msg.sender == ownerOf(_tokenId), "NexusLore: Only being owner can initiate training");
        require(!_beings[_tokenId].isTraining, "NexusLore: Being is already in training");
        require(_durationBlocks > 0, "NexusLore: Training duration must be positive");

        BeingState storage being = _beings[_tokenId];
        being.currentTrainingSkill = uint256(_skillId); // Store skill type as uint
        being.trainingCompletionBlock = block.number + _durationBlocks;
        being.isTraining = true;

        // A small essence cost for initiating intensive training.
        require(being.currentAffinity >= 10, "NexusLore: Not enough Affinity for training initiation (cost 10)");
        being.currentAffinity -= 10;

        emit SkillTrainingInitiated(_tokenId, _skillId, being.trainingCompletionBlock);
    }

    // 11. Finalizes an active skill training, applying benefits.
    function completeSkillTraining(uint256 _tokenId) public whenNotPaused nonReentrant {
        require(_exists(_tokenId), "NexusLore: Being does not exist");
        require(msg.sender == ownerOf(_tokenId), "NexusLore: Only being owner can complete training");
        
        BeingState storage being = _beings[_tokenId];
        require(being.isTraining, "NexusLore: Being is not currently training");
        require(block.number >= being.trainingCompletionBlock, "NexusLore: Training not yet complete");

        SkillType completedSkill = SkillType(being.currentTrainingSkill);
        being.skills[completedSkill] += 5; // Example: +5 skill points upon completion.
        
        // Potential alignment shift based on the trained skill.
        if (completedSkill == SkillType.MysticAffinities) being.alignmentMystic = Math.min(being.alignmentMystic + 5, MAX_ALIGNMENT);
        else if (completedSkill == SkillType.TechnicAdaptation) being.alignmentTechnic = Math.min(being.alignmentTechnic + 5, MAX_ALIGNMENT);
        else if (completedSkill == SkillType.NatureHarmonization) being.alignmentNature = Math.min(being.alignmentNature + 5, MAX_ALIGNMENT);

        being.isTraining = false;
        being.currentTrainingSkill = 0; // Reset
        being.trainingCompletionBlock = 0; // Reset

        emit SkillTrainingCompleted(_tokenId, completedSkill, being.skills[completedSkill]);
    }

    // 12. Activates a specific trait for a being, if complex conditions are met.
    function activateTrait(uint256 _tokenId, TraitType _traitId) public whenNotPaused {
        require(_exists(_tokenId), "NexusLore: Being does not exist");
        require(msg.sender == ownerOf(_tokenId), "NexusLore: Only being owner can activate traits");
        require(!_beings[_tokenId].activeTraits[_traitId], "NexusLore: Trait already active");

        BeingState storage being = _beings[_tokenId];
        bool canActivate = false;

        // Complex activation conditions based on various being attributes and environmental factors:
        if (_traitId == TraitType.ArcaneSurge &&
            being.skills[SkillType.MysticAffinities] >= 20 &&
            being.alignmentMystic >= 70 &&
            environmentalFactors[EnvironmentalFactor.AethericDensity] >= 75) {
            canActivate = true;
        } else if (_traitId == TraitType.TechSavvy &&
                   being.skills[SkillType.TechnicAdaptation] >= 25 &&
                   environmentalFactors[EnvironmentalFactor.EconomicStability] >= 80 &&
                   being.totalEssenceConsumed >= 700) {
            canActivate = true;
        } else if (_traitId == TraitType.UnseenPresence &&
                   being.loreScore <= -100 && // Might be a trait for "dark" aligned beings
                   being.totalEssenceConsumed >= 1000 &&
                   being.skills[SkillType.StrategicInsight] >= 15) {
            canActivate = true;
        }
        // Add more complex conditions for other traits as the system expands.

        require(canActivate, "NexusLore: Conditions not met to activate trait");

        being.activeTraits[_traitId] = true;
        being.traitActivationBlock[_traitId] = block.number;
        emit TraitActivated(_tokenId, _traitId);
    }

    // 13. Returns the current calculated influence/value of a specific trait.
    // This is a dynamic calculation based on current state, not a stored static value.
    function queryTraitInfluence(uint256 _tokenId, TraitType _traitId) public view returns (uint256 influence) {
        require(_exists(_tokenId), "NexusLore: Being does not exist");
        BeingState storage being = _beings[_tokenId];

        if (!being.activeTraits[_traitId]) {
            return 0; // Trait not active, so no influence.
        }

        // Example influence calculations, demonstrating how traits interact with skills, alignments, and environment:
        if (_traitId == TraitType.ResilientWill) {
            // Influence increases with positive LoreScore and creation age (blocks since creation).
            influence = uint256(being.loreScore > 0 ? being.loreScore / 10 : 0) + (block.number - being.creationBlock) / 1000;
        } else if (_traitId == TraitType.ArcaneSurge) {
            // Influence depends on Mystic Alignment, AethericDensity, and MysticAffinities skill.
            influence = (being.alignmentMystic * environmentalFactors[EnvironmentalFactor.AethericDensity]) / 100 + being.skills[SkillType.MysticAffinities];
        } else if (_traitId == TraitType.TechSavvy) {
            // Influence depends on Technic skill level and EconomicStability.
            influence = being.skills[SkillType.TechnicAdaptation] + environmentalFactors[EnvironmentalFactor.EconomicStability] / 10;
        } else if (_traitId == TraitType.Biomimicry) {
            // Influence based on NatureHarmonization and PlanetaryAlignment.
            influence = being.skills[SkillType.NatureHarmonization] + environmentalFactors[EnvironmentalFactor.PlanetaryAlignment] / 5;
        }
        // ... add more trait-specific logic

        return influence;
    }


    // --- IV. Oracle & External Data Integration ---

    // 14. Callable by an authorized Oracle Manager to inject real-world or simulated environmental data.
    // This function acts as a secure entry point for off-chain data feeds.
    function updateEnvironmentalFactor(EnvironmentalFactor _factor, uint256 _value) public onlyRole(Role.ORACLE_MANAGER_ROLE) whenNotPaused {
        require(_value <= 1000, "NexusLore: Environmental factor value too high (max 1000)"); // Example cap for values.
        environmentalFactors[_factor] = _value;
        emit EnvironmentalFactorUpdated(_factor, _value);
    }

    // 15. Emits an event requesting an off-chain AI service to generate a lore insight.
    // This function does not store the insight on-chain directly but signals an off-chain process.
    function requestLoreInsight(uint256 _tokenId, InsightType _type) public whenNotPaused {
        require(_exists(_tokenId), "NexusLore: Being does not exist");
        require(msg.sender == ownerOf(_tokenId), "NexusLore: Only being owner can request lore insight");
        
        // Optional: Implement a small ETH or Affinity cost for requesting AI insights.
        // require(msg.value >= 0.001 ether, "NexusLore: Insufficient ETH for insight request fee");
        // require(_beings[_tokenId].currentAffinity >= 5, "NexusLore: Not enough Affinity for insight request (cost 5)");
        // _beings[_tokenId].currentAffinity -= 5;
        
        emit LoreInsightRequested(_tokenId, _type);
    }

    // 16. Callback from a trusted off-chain AI oracle, updating a being's lore.
    // This function must be secured to only accept calls from a verified oracle via the ORACLE_MANAGER_ROLE.
    function receiveLoreInsight(uint256 _tokenId, string memory _newLoreSnippet, uint256 _aiConfidenceScore) public onlyRole(Role.ORACLE_MANAGER_ROLE) whenNotPaused nonReentrant {
        require(_exists(_tokenId), "NexusLore: Being does not exist");
        require(bytes(_newLoreSnippet).length > 0, "NexusLore: Lore snippet cannot be empty");
        require(_aiConfidenceScore <= 100, "NexusLore: Confidence score must be 0-100");

        BeingState storage being = _beings[_tokenId];
        being.latestLoreSnippet = _newLoreSnippet;
        being.loreSnippetConfidence = _aiConfidenceScore;

        // Optionally, LoreScore or Alignment could be influenced by the AI insight's confidence/content.
        if (_aiConfidenceScore > 80) {
            adjustLoreScore(_tokenId, 10); // Small positive adjustment for high confidence lore.
        } else if (_aiConfidenceScore < 20) {
            adjustLoreScore(_tokenId, -5); // Small negative adjustment for low confidence lore (reflects uncertainty).
        }

        emit LoreInsightReceived(_tokenId, _newLoreSnippet, _aiConfidenceScore);
    }


    // --- V. Gamified Interaction & Challenges ---

    // 17. Registers a being for a specific challenge.
    function participateInChallenge(uint256 _tokenId, ChallengeType _challengeId) public whenNotPaused nonReentrant {
        require(_exists(_tokenId), "NexusLore: Being does not exist");
        require(msg.sender == ownerOf(_tokenId), "NexusLore: Only being owner can participate in challenges");
        
        Challenge storage currentChallenge = challenges[_challengeId];
        require(currentChallenge.isActive, "NexusLore: Challenge is not active");
        require(block.number <= currentChallenge.registrationDeadline, "NexusLore: Registration deadline passed for this challenge");
        require(currentChallenge.participants.length < currentChallenge.maxParticipants, "NexusLore: Challenge registration full");
        
        // Ensure being is not already registered.
        for (uint264 i = 0; i < currentChallenge.participants.length; i++) {
            if (currentChallenge.participants[i] == _tokenId) {
                revert("NexusLore: Being already registered for this challenge");
            }
        }

        // Cost to participate.
        require(_beings[_tokenId].currentAffinity >= currentChallenge.essenceCostPerParticipant, "NexusLore: Not enough Affinity to participate");
        _beings[_tokenId].currentAffinity -= currentChallenge.essenceCostPerParticipant;

        currentChallenge.participants.push(_tokenId);
        emit ChallengeRegistered(_challengeId, _tokenId);
    }

    // 18. Callable by a LoreKeeper/Oracle to resolve a challenge and apply outcomes.
    // _challengeOutcomes: Array indicating outcome for each corresponding participant (e.g., 0=fail, 1=succeed, 2=exceptional success).
    function resolveChallenge(ChallengeType _challengeId, uint256[] memory _participantTokens, uint256[] memory _challengeOutcomes) public onlyRole(Role.LOREKEEPER_ROLE) whenNotPaused nonReentrant {
        Challenge storage currentChallenge = challenges[_challengeId];
        require(currentChallenge.isActive, "NexusLore: Challenge is not active");
        require(!currentChallenge.isResolved, "NexusLore: Challenge already resolved");
        require(block.number > currentChallenge.registrationDeadline, "NexusLore: Registration still open for this challenge");
        require(block.number <= currentChallenge.resolutionDeadline, "NexusLore: Resolution deadline passed");
        require(_participantTokens.length == _challengeOutcomes.length, "NexusLore: Mismatch in participants and outcomes count");
        require(_participantTokens.length >= currentChallenge.minParticipants, "NexusLore: Not enough participants to resolve challenge");

        // Basic check: Ensure all _participantTokens are actually registered for this challenge.
        // More robust solutions would map registrations. For this example, assuming _participantTokens is derived from currentChallenge.participants.
        
        currentChallenge.isResolved = true; // Mark as resolved.
        currentChallenge.isActive = false; // Deactivate after resolution.

        for (uint264 i = 0; i < _participantTokens.length; i++) {
            uint256 tokenId = _participantTokens[i];
            uint256 outcome = _challengeOutcomes[i];
            
            require(_exists(tokenId), "NexusLore: Participant being does not exist");
            BeingState storage participantBeing = _beings[tokenId];

            // Apply outcomes based on outcome type.
            if (outcome == 1) { // Standard Success
                adjustLoreScore(tokenId, 20); // Positive LoreScore adjustment.
                participantBeing.currentAffinity += (currentChallenge.rewardBasis * 5); // Small affinity reward.
                
                // Example: Unlock a trait for successful participants.
                if (!participantBeing.activeTraits[TraitType.InsightfulVision]) {
                    participantBeing.activeTraits[TraitType.InsightfulVision] = true;
                    participantBeing.traitActivationBlock[TraitType.InsightfulVision] = block.number;
                    emit TraitActivated(tokenId, TraitType.InsightfulVision);
                }
            } else if (outcome == 2) { // Exceptional Success
                adjustLoreScore(tokenId, 50); // Significant LoreScore boost.
                participantBeing.currentAffinity += (currentChallenge.rewardBasis * 15); // Larger affinity reward.
                participantBeing.alignmentMystic = Math.min(participantBeing.alignmentMystic + 10, MAX_ALIGNMENT);
                // As a rare achievement, a being might become Soulbound upon exceptional success.
                if (participantBeing.status != LoreStatus.Bound) {
                    participantBeing.status = LoreStatus.Bound;
                    emit BeingLoreStatusChanged(tokenId, LoreStatus.Bound);
                }
            } else { // Failure or Neutral outcome
                adjustLoreScore(tokenId, -10); // Small negative LoreScore adjustment.
            }
        }
        
        emit ChallengeResolved(_challengeId, _participantTokens, _challengeOutcomes);
    }

    // 19. Two beings "consult" each other, potentially leading to shared skill/trait progression.
    // This function represents a complex interaction, where combined LoreScores or specific traits affect the outcome.
    function initiateInterBeingConsultation(uint256 _tokenId1, uint256 _tokenId2) public whenNotPaused nonReentrant {
        require(_exists(_tokenId1), "NexusLore: Being 1 does not exist");
        require(_exists(_tokenId2), "NexusLore: Being 2 does not exist");
        require(_tokenId1 != _tokenId2, "NexusLore: Cannot consult with self");
        require(msg.sender == ownerOf(_tokenId1) || msg.sender == ownerOf(_tokenId2), "NexusLore: Only owners of participating beings can initiate consultation");

        BeingState storage being1 = _beings[_tokenId1];
        BeingState storage being2 = _beings[_tokenId2];

        // Example pre-conditions: Requires high LoreScore from both, and a small essence cost.
        require(being1.loreScore >= 50 && being2.loreScore >= 50, "NexusLore: Both beings need higher LoreScore for consultation (min 50)");
        require(being1.currentAffinity >= 20 && being2.currentAffinity >= 20, "NexusLore: Both beings need 20 Affinity for consultation");
        
        being1.currentAffinity -= 20;
        being2.currentAffinity -= 20;

        // Influence logic based on combined attributes:
        // If one being is highly Mystic and the other highly Technic, they might gain StrategicInsight.
        if (being1.alignmentMystic > 70 && being2.alignmentTechnic > 70) {
            being1.skills[SkillType.StrategicInsight] += 1;
            being2.skills[SkillType.StrategicInsight] += 1;
            emit SkillPointAllocated(_tokenId1, SkillType.StrategicInsight, being1.skills[SkillType.StrategicInsight]);
            emit SkillPointAllocated(_tokenId2, SkillType.StrategicInsight, being2.skills[SkillType.StrategicInsight]);
        }
        // If both have high EmpathicResonance, they might gain a LoreScore boost.
        if (being1.skills[SkillType.EmpathicResonance] >= 10 && being2.skills[SkillType.EmpathicResonance] >= 10) {
            adjustLoreScore(_tokenId1, 5);
            adjustLoreScore(_tokenId2, 5);
        }
        // More complex logic for consultation outcomes could go here, potentially unlocking new shared traits or specific lore.

        emit InterBeingConsultationInitiated(_tokenId1, _tokenId2);
    }

    // 20. Configures specific challenge parameters and makes it active for registration.
    function setChallengeParameters(
        ChallengeType _challengeId,
        uint256 _essenceCost,
        uint256 _rewardBasis,
        uint256 _minParticipants,
        uint256 _maxParticipants,
        uint256 _registrationDurationBlocks, // How long registration is open for this challenge.
        uint256 _resolutionDurationBlocks    // How long until resolution is expected after registration closes.
    ) public onlyRole(Role.CHALLENGE_MASTER_ROLE) whenNotPaused {
        require(_essenceCost > 0, "NexusLore: Essence cost must be positive");
        require(_rewardBasis > 0, "NexusLore: Reward basis must be positive");
        require(_minParticipants > 0, "NexusLore: Min participants must be positive");
        require(_maxParticipants >= _minParticipants, "NexusLore: Max participants must be >= min");
        require(_registrationDurationBlocks > 0, "NexusLore: Registration duration must be positive");
        require(_resolutionDurationBlocks > 0, "NexusLore: Resolution duration must be positive");

        challenges[_challengeId] = Challenge({
            challengeId: _challengeId,
            essenceCostPerParticipant: _essenceCost,
            rewardBasis: _rewardBasis,
            minParticipants: _minParticipants,
            maxParticipants: _maxParticipants,
            registrationDeadline: block.number + _registrationDurationBlocks,
            resolutionDeadline: block.number + _registrationDurationBlocks + _resolutionDurationBlocks,
            participants: new uint256[](0), // Reset participants for a new challenge instance.
            isActive: true, // Mark challenge as active upon setting parameters.
            isResolved: false
        });

        // Add to active challenges list if not already present.
        bool found = false;
        for (uint264 i = 0; i < activeChallengeIds.length; i++) {
            if (activeChallengeIds[i] == uint256(_challengeId)) {
                found = true;
                break;
            }
        }
        if (!found) {
            activeChallengeIds.push(uint256(_challengeId));
        }
    }

    // 4. Set a being's operational status (e.g., Active, Dormant, Bound, Deactivated).
    // Access control varies based on the target status.
    function setBeingLoreStatus(uint256 _tokenId, LoreStatus _status) public whenNotPaused {
        require(_exists(_tokenId), "NexusLore: Being does not exist");
        
        // Only LoreKeepers can set 'Bound' or 'Deactivated' status.
        if (_status == LoreStatus.Bound || _status == LoreStatus.Deactivated) {
            require(hasRole(msg.sender, Role.LOREKEEPER_ROLE), "NexusLore: Only LoreKeeper can set Bound or Deactivated status");
        } else {
            // For 'Active' or 'Dormant', either the owner or a LoreKeeper can change.
            require(msg.sender == ownerOf(_tokenId) || hasRole(msg.sender, Role.LOREKEEPER_ROLE), "NexusLore: Not authorized to change this status");
        }

        _beings[_tokenId].status = _status;
        emit BeingLoreStatusChanged(_tokenId, _status);
    }


    // --- VI. Role-Based Access Control & System Governance (Custom Implementation) ---

    // 21. Grants a specific administrative role to an address.
    function grantRole(address _account, Role _role) public onlyRole(Role.DEFAULT_ADMIN_ROLE) {
        require(_account != address(0), "AccessControl: account is the zero address");
        require(!_roles[_role][_account], "AccessControl: account already has role");
        _roles[_role][_account] = true;
        emit RoleGranted(_role, _account);
    }

    // 22. Revokes a specific administrative role from an address.
    function revokeRole(address _account, Role _role) public onlyRole(Role.DEFAULT_ADMIN_ROLE) {
        require(_account != address(0), "AccessControl: account is the zero address");
        require(_roles[_role][_account], "AccessControl: account does not have role");
        _roles[_role][_account] = false;
        emit RoleRevoked(_role, _account);
    }

    // 23. Checks if an address holds a specific role.
    function hasRole(address _account, Role _role) public view returns (bool) {
        return _roles[_role][_account];
    }


    // --- VII. Pausability & Emergency Functions ---

    // 24. Pauses all core interactions of the contract.
    function pauseSystem() public onlyRole(Role.DEFAULT_ADMIN_ROLE) whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    // 25. Unpauses the contract, allowing interactions again.
    function unpauseSystem() public onlyRole(Role.DEFAULT_ADMIN_ROLE) {
        require(paused, "System is not paused");
        paused = false;
        emit Unpaused(msg.sender);
    }

    // Helper library for basic math operations (Solidity 0.8.0+ has safe math built-in for uint).
    library Math {
        function min(uint256 a, uint256 b) internal pure returns (uint256) {
            return a < b ? a : b;
        }

        function clamp(int256 value, int256 lowerBound, int256 upperBound) internal pure returns (int256) {
            return value < lowerBound ? lowerBound : (value > upperBound ? upperBound : value);
        }
    }
}
```