This smart contract, `ChronoscribeCollective`, introduces a novel ecosystem for "Evolving NFTs" (Chronoscribes) with gamified governance, dynamic traits, and a progressive life-cycle. Unlike static NFTs, Chronoscribes adapt and grow based on owner interaction, community events, and a simulated environment, encouraging active participation and long-term engagement.

---

**Contract Name: ChronoscribeCollective**

**Outline:**

**I. Contract Structure & Core Definitions**
    *   Inherits from `ERC721Enumerable`, `AccessControl`, and `Pausable` for standard NFT functionality, role-based access, and emergency pausing.
    *   Defines custom roles: `DEFAULT_ADMIN_ROLE`, `QUEST_MASTER_ROLE`, `LORE_MASTER_ROLE`.
    *   Includes global configurations (mint cost, max supply, base URI) and counters for NFTs, quests, and lore proposals.
    *   **Structs:**
        *   `Scribe`: Represents an NFT with dynamic properties like `level`, `xp`, `chronosEnergy`, `traitScores` (a mapping for various attribute values), and `statusFlags`.
        *   `TraitDefinition`: Stores metadata for each possible trait (name, description).
        *   `EvolutionRule`: Defines the requirements (XP, ChronosEnergy, time) for a Scribe to level up.
        *   `Quest`: Details gamified tasks with rewards, status, and duration.
        *   `LoreProposal`: Records community proposals for lore or feature changes, including voting details.
    *   **Enums:** `QuestStatus`, `LoreProposalStatus` to manage state.
    *   **Events & Custom Errors:** Comprehensive event logging and specific error messages for improved debugging and user experience.

**II. Core NFT Management (ERC721 Extensions & Minting)**
    *   `mintScribe`: Allows users to mint new Chronoscribe NFTs, subject to supply limits and minting cost.
    *   `burnScribe`: Enables owners to destroy their Scribe, permanently removing it from the collection.
    *   `getScribeDetails`: Provides a detailed view of a specific Scribe's current state, including all dynamic attributes.
    *   `tokenURI`: Generates a dynamic metadata URI for each Scribe, which can reflect its evolving traits and status.

**III. Scribe Evolution & Traits**
    *   `initiateScribeEvolution`: Triggers a Scribe's level-up process if all evolution criteria (XP, ChronosEnergy, time) are met, granting generic trait boosts.
    *   `claimEvolutionPerks`: A placeholder for more complex post-evolution reward claims, allowing future expansion for unique perks.
    *   `accrueChronosEnergy`: Calculates and adds `ChronosEnergy` (an internal resource) to a Scribe based on elapsed time and its level, encouraging regular interaction.
    *   `spendChronosEnergy`: Allows Scribe owners to utilize their `ChronosEnergy` for various in-ecosystem actions.
    *   `_updateScribeTrait` (internal): A helper function to modify a Scribe's specific trait score, used by evolution, quests, or events.
    *   `getScribeTraitValue`: Retrieves the current numerical value of any specified dynamic trait for a Scribe.

**IV. Gamified Governance & Interaction**
    *   `proposeLoreFragment`: Enables Scribe owners (above a certain level) to submit proposals for new lore, features, or trait adjustments to the community.
    *   `voteOnLoreProposal`: Allows Scribe owners to cast votes on active lore proposals, with their Scribe's influence (level, ChronosEnergy) determining voting power.
    *   `completeQuestTask`: Facilitates the submission of "proof" by owners for quest completion, putting the quest into a verification state.
    *   `createCommunityQuest`: Empowered `QUEST_MASTER_ROLE` members to define and launch new community quests with specific rewards.
    *   `activateGlobalEvent`: Admin/DAO function to trigger time-limited ecosystem-wide events that can affect Scribe traits or environmental factors.
    *   `updateQuestStatus`: `QUEST_MASTER_ROLE` function to verify `completeQuestTask` submissions, grant rewards, or cancel quests.
    *   `getQuestDetails`: Retrieves full information about a specific quest.
    *   `getLoreProposalDetails`: Provides comprehensive data about a specific lore proposal.
    *   `finalizeLoreProposal`: `LORE_MASTER_ROLE` function to conclude voting on a lore proposal and set its final status.
    *   `registerTraitChangeFromLore`: `LORE_MASTER_ROLE` function to apply specific trait changes (e.g., to environmental factors) resulting from an approved lore proposal.

**V. Ecosystem Configuration & Treasury**
    *   `setEvolutionRule`: Admin/DAO function to configure the precise conditions (XP, Chronos, time) for each Scribe level.
    *   `defineScribeTrait`: Admin/DAO function to introduce new, unique traits that Chronoscribes can possess and evolve.
    *   `adjustEnvironmentalFactor`: Admin/Oracle-fed function to update ecosystem-wide variables (e.g., market sentiment, resource availability) that dynamically influence Scribe mechanics.
    *   `setMintParameters`: Admin function to adjust the cost of minting new Scribes and the total supply cap.
    *   `withdrawTreasuryFunds`: Admin/DAO controlled function to withdraw accumulated ETH from the contract's treasury for ecosystem development.
    *   `depositTreasuryFunds`: Allows any user to contribute ETH to the contract's treasury, supporting the ecosystem.
    *   `pauseEcosystemOperations`: Emergency pause function for critical contract operations.
    *   `unpauseEcosystemOperations`: Emergency unpause function.
    *   `setBaseURI`: Admin function to update the base URI for NFT metadata.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Contract Name: ChronoscribeCollective ---

// Outline:
// I.  Contract Structure & Core Definitions
//     - Inherits: ERC721Enumerable, AccessControl, Pausable
//     - Roles: DEFAULT_ADMIN_ROLE, QUEST_MASTER_ROLE, LORE_MASTER_ROLE
//     - State variables for configuration, counters, mappings
//     - Structs: Scribe, TraitDefinition, EvolutionRule, Quest, LoreProposal
//     - Enums: QuestStatus, LoreProposalStatus
//     - Events & Custom Errors
// II. Core NFT Management (ERC721 Extensions & Minting)
//     - mintScribe: Public entry point for users to mint a Scribe.
//     - burnScribe: Allows owner to destroy their Scribe.
//     - getScribeDetails: Retrieve comprehensive Scribe data.
//     - tokenURI: Generates dynamic metadata URI for the Scribe.
// III. Scribe Evolution & Traits
//      - initiateScribeEvolution: Checks eligibility and triggers Scribe level-up.
//      - claimEvolutionPerks: Owner claims bonuses after evolution.
//      - accrueChronosEnergy: Calculates and adds ChronosEnergy based on activity/level.
//      - spendChronosEnergy: Allows spending ChronosEnergy for actions.
//      - getScribeTraitValue: Retrieves a specific trait's current value.
// IV. Gamified Governance & Interaction
//     - proposeLoreFragment: Submit new lore/feature proposals.
//     - voteOnLoreProposal: Cast votes on proposals using Scribe's influence.
//     - completeQuestTask: Fulfill a quest requirement and earn rewards.
//     - createCommunityQuest: Admin/privileged Scribes can initiate new quests.
//     - activateGlobalEvent: Admin/DAO activates a time-limited event.
//     - updateQuestStatus: Admin/DAO to verify and close quests.
//     - getQuestDetails: Retrieves info about a quest.
//     - getLoreProposalDetails: Retrieves info about a lore proposal.
//     - finalizeLoreProposal: Admin/Lore Master to finalize proposal based on votes.
//     - registerTraitChangeFromLore: Admin to apply lore-approved trait changes.
// V.  Ecosystem Configuration & Treasury
//     - setEvolutionRule: Define conditions for Scribe evolution.
//     - defineScribeTrait: Add or modify definable traits.
//     - adjustEnvironmentalFactor: Admin/Oracle updates ecosystem-wide variables.
//     - setMintParameters: Configure minting cost, limits, etc.
//     - withdrawTreasuryFunds: Admin/DAO can withdraw accumulated funds.
//     - depositTreasuryFunds: Users can contribute to the treasury.
//     - pauseEcosystemOperations: Emergency pause functionality.
//     - unpauseEcosystemOperations: Emergency unpause functionality.
//     - setBaseURI: Admin to set the base URI for NFT metadata.

// Function Summary (28 unique functions):

// 1.  constructor(): Initializes the contract, sets basic roles, and defines initial configurations (e.g., initial traits, evolution rules).
// 2.  mintScribe(): Allows users to mint a new Chronoscribe NFT by paying a fee, adhering to max supply limits.
// 3.  burnScribe(uint256 tokenId): Allows a specified Chronoscribe NFT to be burned (destroyed) by its owner.
// 4.  getScribeDetails(uint256 tokenId): Retrieves all current data for a given Chronoscribe NFT, including level, XP, energy, and dynamic traits.
// 5.  tokenURI(uint256 tokenId): Returns the metadata URI for a Scribe. This URI can dynamically reflect the Scribe's evolving traits and status.
// 6.  initiateScribeEvolution(uint256 tokenId): Checks if a Scribe is eligible to evolve (level up) based on accumulated XP, ChronosEnergy, and time, and triggers the evolution process.
// 7.  claimEvolutionPerks(uint256 tokenId): Allows the owner to claim the benefits (e.g., increased trait points, new abilities, stat boosts) after a Scribe has successfully evolved (placeholder for complex perks).
// 8.  accrueChronosEnergy(uint256 tokenId): Calculates and adds ChronosEnergy to a Scribe based on elapsed time since last interaction or its current level, encouraging active participation.
// 9.  spendChronosEnergy(uint256 tokenId, uint256 amount): Allows a Scribe owner to spend their accumulated ChronosEnergy for various actions within the ecosystem (e.g., boosting votes, quest submissions).
// 10. updateScribeTrait(uint256 tokenId, uint8 traitId, int256 delta): (Internal/Admin) Modifies a specific trait's score for a Scribe based on evolution, quests, or events.
// 11. getScribeTraitValue(uint256 tokenId, uint8 traitId): Returns the current numerical value of a specified trait for a Scribe, reflecting its dynamic nature.
// 12. proposeLoreFragment(string memory fragmentURI, string memory title): Allows Scribe owners (min. level 2) to propose new lore entries, design concepts, or trait modification ideas for community discussion and voting.
// 13. voteOnLoreProposal(uint256 proposalId, uint256 tokenId, bool support): Scribe owners cast votes on active lore proposals, with voting power potentially influenced by their Scribe's level and ChronosEnergy.
// 14. completeQuestTask(uint256 questId, uint256 tokenId, bytes memory proof): Owners submit verifiable proof of quest completion (e.g., cryptographic hash, external verification ID) to be reviewed by Quest Masters.
// 15. createCommunityQuest(string memory title, string memory descriptionURI, uint256 xpReward, uint256 chronosReward, uint256 duration): Admin or privileged "Quest Master" Scribes can define and launch new community quests.
// 16. activateGlobalEvent(uint256 eventId, uint256 duration, int256 traitModifierDelta): Admin or DAO can activate time-limited global events that might temporarily or permanently impact all Scribes or specific trait categories.
// 17. setEvolutionRule(uint8 level, uint256 xpRequired, uint256 chronosCost, uint256 timeSinceLastEvoRequired, string memory description): Admin or DAO defines the conditions (XP, Chronos, time) for a Scribe to reach a new level and evolve.
// 18. defineScribeTrait(uint8 traitId, string memory name, string memory description): Admin or DAO sets up the possible traits for Scribes, their unique identifiers, and descriptions.
// 19. adjustEnvironmentalFactor(uint8 factorId, int256 newValue): Admin or an Oracle-fed function to update an ecosystem-wide "environmental factor" that might influence Scribe growth or energy generation.
// 20. setMintParameters(uint256 newMintCost, uint256 newMaxSupply): Admin can adjust the cost of minting a new Scribe and the overall maximum supply cap for the collection.
// 21. withdrawTreasuryFunds(address recipient, uint256 amount): Allows the authorized admin/DAO to withdraw accumulated ETH funds from the contract's treasury, e.g., for ecosystem development.
// 22. depositTreasuryFunds(): Allows any user to contribute ETH to the contract's treasury, publicly supporting the Chronoscribe ecosystem.
// 23. pauseEcosystemOperations(): Emergency function to pause critical contract operations (e.g., minting, evolution, quest submissions) by the authorized admin.
// 24. unpauseEcosystemOperations(): Emergency function to unpause critical contract operations by the authorized admin.
// 25. updateQuestStatus(uint256 questId, QuestStatus newStatus, uint256 completerTokenId): Admin or privileged "Quest Masters" can approve, reject, or finalize the status of community quests after review, granting rewards.
// 26. getQuestDetails(uint256 questId): Retrieves comprehensive information about a specific quest.
// 27. getLoreProposalDetails(uint256 proposalId): Retrieves all details about a specific lore proposal, including votes and status.
// 28. finalizeLoreProposal(uint256 proposalId): Admin/Lore Master can finalize a lore proposal based on vote outcome, potentially applying its effects.
// 29. registerTraitChangeFromLore(uint256 proposalId, uint8 traitId, int256 delta): (Admin) Registers a specific trait change outcome from a finalized lore proposal, typically affecting global environmental factors.
// 30. setBaseURI(string memory _newBaseURI): Admin function to update the base URI for token metadata.

contract ChronoscribeCollective is ERC721Enumerable, AccessControl, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- I. Contract Structure & Core Definitions ---

    // Roles
    bytes32 public constant QUEST_MASTER_ROLE = keccak256("QUEST_MASTER_ROLE");
    bytes32 public constant LORE_MASTER_ROLE = keccak256("LORE_MASTER_ROLE");
    // DEFAULT_ADMIN_ROLE (from AccessControl) manages other roles

    // Global Configurations
    uint256 public mintCost = 0.05 ether;
    uint256 public maxSupply = 10_000;
    string public baseURI;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _questIdCounter;
    Counters.Counter private _loreProposalIdCounter;

    // Scribe Struct: Represents an NFT with dynamic properties
    // `lastInteractionTime` (66 bits for timestamp) and `level` (8 bits for level) are packed into a uint66.
    // Max timestamp: 2^66 seconds from epoch (far future). Max level: 255.
    struct Scribe {
        address owner;
        uint64 mintTime;            // unix timestamp (64 bits, ~584 billion years)
        uint66 lastInteractionTime; // (Timestamp << 8) | level.
        uint64 xp;                  // Experience points
        uint64 chronosEnergy;       // Internal resource for actions
        mapping(uint8 => int32) traitScores; // Dynamic traits (e.g., Wisdom, Agility, Resilience)
        mapping(uint8 => bool) statusFlags; // Boolean flags (e.g., 'evolved_this_cycle', 'has_special_ability_X')
    }
    mapping(uint256 => Scribe) public scribes;

    // Trait Definition Struct
    struct TraitDefinition {
        string name;
        string description;
        bool exists;
    }
    mapping(uint8 => TraitDefinition) public traitDefinitions;
    uint8 public nextTraitId = 0; // Counter for assigning unique trait IDs

    // Evolution Rule Struct
    struct EvolutionRule {
        uint256 xpRequired;
        uint256 chronosCost;
        uint256 timeSinceLastEvoRequired; // Minimum time in seconds between evolutions
        string description;
        bool exists;
    }
    mapping(uint8 => EvolutionRule) public evolutionRules; // Keyed by level

    // Quest Struct
    enum QuestStatus { Active, Completed, Cancelled, AwaitingVerification }
    struct Quest {
        string title;
        string descriptionURI; // IPFS hash or URL for quest details
        uint64 creationTime;
        uint64 duration; // How long quest is active (seconds)
        uint256 xpReward;
        uint256 chronosReward;
        QuestStatus status;
        address creator;
    }
    mapping(uint256 => Quest) public quests;
    mapping(uint256 => mapping(uint256 => bool)) public questCompletedByScribe; // questId => tokenId => bool

    // Lore Proposal Struct
    enum LoreProposalStatus { Active, Approved, Rejected, Finalized }
    struct LoreProposal {
        string title;
        string fragmentURI; // IPFS hash or URL for lore content
        uint64 creationTime;
        uint64 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 totalVotes;
        address proposer;
        LoreProposalStatus status;
    }
    mapping(uint256 => LoreProposal) public loreProposals;
    mapping(uint256 => mapping(uint256 => bool)) public hasVotedOnLore; // proposalId => tokenId => bool

    // Environmental Factors (simulated or oracle-fed)
    // Example: 0=MarketSentiment, 1=ResourceScarcity, 2=GlobalWisdomModifier
    mapping(uint8 => int256) public environmentalFactors;

    // Events
    event ScribeMinted(uint256 indexed tokenId, address indexed owner, uint256 mintTime, uint8 initialLevel);
    event ScribeBurned(uint256 indexed tokenId, address indexed owner);
    event ScribeEvolved(uint256 indexed tokenId, uint8 newLevel, uint256 xpSpent, uint256 chronosSpent);
    event ChronosEnergyAccrued(uint256 indexed tokenId, uint256 amount, uint256 newTotal);
    event ChronosEnergySpent(uint256 indexed tokenId, uint256 amount, uint256 newTotal);
    event TraitUpdated(uint256 indexed tokenId, uint8 indexed traitId, int256 delta, int256 newScore);
    event QuestCreated(uint256 indexed questId, address indexed creator, string title);
    event QuestCompleted(uint256 indexed questId, uint256 indexed tokenId, address indexed completer);
    event QuestStatusUpdated(uint256 indexed questId, QuestStatus oldStatus, QuestStatus newStatus);
    event LoreProposalCreated(uint256 indexed proposalId, address indexed proposer, string title);
    event LoreVoted(uint256 indexed proposalId, uint256 indexed tokenId, bool support);
    event LoreProposalFinalized(uint256 indexed proposalId, LoreProposalStatus finalStatus);
    event EnvironmentalFactorAdjusted(uint8 indexed factorId, int256 newValue);
    event TreasuryFundsWithdrawn(address indexed recipient, uint224 amount); // Use uint224 for safety
    event TreasuryFundsDeposited(address indexed depositor, uint224 amount); // Use uint224 for safety

    // Custom Errors
    error Unauthorized();
    error InvalidTokenId();
    error NotScribeOwner();
    error MaxSupplyReached();
    error InsufficientFunds();
    error ScribeCannotEvolve();
    error NotEnoughChronosEnergy();
    error QuestNotActive();
    error QuestAlreadyCompleted();
    error LoreProposalNotActive();
    error AlreadyVoted();
    error MintingPaused(); // Specific error for minting pause
    error OperationsPaused(); // General error for other paused operations
    error NoEthToWithdraw();
    error EvolutionRuleDoesNotExist();
    error TraitDefinitionDoesNotExist();
    error InvalidTraitId();
    error InvalidQuestStatus();
    error LoreProposalNotFinalizable();
    error ScribeBelowMinLevelForAction(uint8 requiredLevel, uint8 currentLevel);
    error MaxTraitsReached();
    error NoEligibleScribeFound();
    error LoreProposalNotApproved(); // For trait changes from lore


    constructor(string memory _name, string memory _symbol, string memory _baseURI)
        ERC721(_name, _symbol)
        AccessControl()
        Pausable()
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setBaseURI(_baseURI); // Initial base URI
        baseURI = _baseURI;

        // Initialize a few default traits
        defineScribeTrait(nextTraitId++, "Wisdom", "Intellectual capacity and insight.");
        defineScribeTrait(nextTraitId++, "Agility", "Dexterity and reaction speed.");
        defineScribeTrait(nextTraitId++, "Resilience", "Resistance to change and endurance.");
        defineScribeTrait(nextTraitId++, "Charisma", "Leadership and influence.");

        // Example evolution rules
        // Level 1 (initial) doesn't need a rule, it's the starting point
        setEvolutionRule(2, 100, 50, 1 days, "The first awakening of consciousness.");
        setEvolutionRule(3, 250, 150, 3 days, "A deeper understanding of the collective.");
        // More rules can be set by admin
    }

    // --- AccessControl Overrides for Pausable ---
    // ERC721 operations like _beforeTokenTransfer can be paused.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        if (paused() && from != address(0)) { // Allow minting/burning when paused if needed, but not transfers
            revert OperationsPaused();
        }
    }

    // Admin can pause / unpause
    function _pause() internal virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        super._pause();
    }

    function _unpause() internal virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        super._unpause();
    }

    // --- Helper functions for packed Scribe data ---
    function _getScribeLevel(uint256 tokenId) internal view returns (uint8) {
        return uint8(scribes[tokenId].lastInteractionTime & 0xFF);
    }

    function _getScribeLastInteractionTime(uint256 tokenId) internal view returns (uint64) {
        return uint64(scribes[tokenId].lastInteractionTime >> 8);
    }

    function _setScribeLevel(uint256 tokenId, uint8 newLevel) internal {
        Scribe storage scribe = scribes[tokenId];
        uint64 currentTime = uint64(block.timestamp);
        scribe.lastInteractionTime = (uint66(currentTime) << 8) | uint66(newLevel);
    }

    function _setScribeLastInteractionTime(uint256 tokenId, uint64 timestamp) internal {
        Scribe storage scribe = scribes[tokenId];
        uint8 currentLevel = _getScribeLevel(tokenId);
        scribe.lastInteractionTime = (uint66(timestamp) << 8) | uint66(currentLevel);
    }


    // --- II. Core NFT Management (ERC721 Extensions & Minting) ---

    /// @notice Allows users to mint a new Chronoscribe NFT by paying a fee.
    /// @dev Minting is restricted by max supply and current mint cost.
    function mintScribe() public payable {
        if (paused()) { // Specific pause for minting
            revert MintingPaused();
        }
        if (totalSupply() >= maxSupply) {
            revert MaxSupplyReached();
        }
        if (msg.value < mintCost) {
            revert InsufficientFunds();
        }

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        Scribe storage newScribe = scribes[newTokenId];
        newScribe.owner = msg.sender;
        newScribe.mintTime = uint64(block.timestamp);
        newScribe.xp = 0;
        newScribe.chronosEnergy = 0;
        _setScribeLevel(newTokenId, 1); // Sets level to 1 and updates packed lastInteractionTime

        // Initialize base trait scores for the new Scribe
        for (uint8 i = 0; i < nextTraitId; i++) {
            if (traitDefinitions[i].exists) {
                newScribe.traitScores[i] = 10; // Base score for all defined traits
            }
        }

        _safeMint(msg.sender, newTokenId);

        emit ScribeMinted(newTokenId, msg.sender, block.timestamp, 1);
    }

    /// @notice Allows a specified Chronoscribe NFT to be burned (destroyed) by its owner.
    /// @param tokenId The ID of the Scribe NFT to burn.
    function burnScribe(uint256 tokenId) public whenNotPaused {
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        if (ownerOf(tokenId) != msg.sender) {
            revert NotScribeOwner();
        }
        _burn(tokenId);
        delete scribes[tokenId]; // Clear scribe data
        emit ScribeBurned(tokenId, msg.sender);
    }

    /// @notice Retrieves all current data for a given Chronoscribe NFT.
    /// @param tokenId The ID of the Scribe NFT.
    /// @return owner_ The owner's address.
    /// @return mintTime_ The timestamp when the Scribe was minted.
    /// @return lastInteractionTime_ The timestamp of the Scribe's last significant interaction.
    /// @return level_ The Scribe's current level.
    /// @return xp_ The Scribe's current experience points.
    /// @return chronosEnergy_ The Scribe's current ChronosEnergy balance.
    /// @return traitScores_ An array of current trait scores.
    /// @return traitNames_ An array of trait names corresponding to scores.
    /// @return statusFlags_ An array of current status flags.
    function getScribeDetails(uint256 tokenId)
        public
        view
        returns (
            address owner_,
            uint64 mintTime_,
            uint64 lastInteractionTime_,
            uint8 level_,
            uint64 xp_,
            uint64 chronosEnergy_,
            int32[] memory traitScores_,
            string[] memory traitNames_
        )
    {
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        Scribe storage scribe = scribes[tokenId];

        owner_ = scribe.owner;
        mintTime_ = scribe.mintTime;
        lastInteractionTime_ = _getScribeLastInteractionTime(tokenId);
        level_ = _getScribeLevel(tokenId);
        xp_ = scribe.xp;
        chronosEnergy_ = scribe.chronosEnergy;

        traitScores_ = new int32[](nextTraitId);
        traitNames_ = new string[](nextTraitId);

        for (uint8 i = 0; i < nextTraitId; i++) {
            if (traitDefinitions[i].exists) {
                traitScores_[i] = scribe.traitScores[i];
                traitNames_[i] = traitDefinitions[i].name;
            }
        }
    }

    /// @notice Returns the metadata URI for a Scribe. This URI can dynamically reflect the Scribe's evolving traits and status.
    /// @param tokenId The ID of the Scribe NFT.
    /// @return string The URI string.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }

        // Example of dynamic metadata - in a real scenario, this would point to a service
        // that generates JSON based on the Scribe's current state.
        // For simplicity, we'll just append some basic data.
        string memory currentBaseURI = baseURI; // Use the stored baseURI
        return string(abi.encodePacked(
            currentBaseURI,
            tokenId.toString(),
            "?",
            "level=", _getScribeLevel(tokenId).toString(),
            "&xp=", scribes[tokenId].xp.toString(),
            "&energy=", scribes[tokenId].chronosEnergy.toString()
            // In a real dApp, this would be a URL to an off-chain API like:
            // "https://api.chronoscribes.xyz/metadata/" + tokenId.toString()
        ));
    }

    // --- III. Scribe Evolution & Traits ---

    /// @notice Checks if a Scribe is eligible to evolve (level up) and triggers the process.
    /// @dev Evolution consumes XP, ChronosEnergy, and requires a cooldown period.
    /// @param tokenId The ID of the Scribe NFT to evolve.
    function initiateScribeEvolution(uint256 tokenId) public whenNotPaused {
        if (ownerOf(tokenId) != msg.sender) {
            revert NotScribeOwner();
        }
        Scribe storage scribe = scribes[tokenId];

        uint8 currentLevel = _getScribeLevel(tokenId);
        uint8 nextLevel = currentLevel + 1;

        if (!evolutionRules[nextLevel].exists) {
            revert ScribeCannotEvolve(); // No rule defined for next level
        }

        EvolutionRule storage rule = evolutionRules[nextLevel];

        if (scribe.xp < rule.xpRequired) {
            revert ScribeCannotEvolve(); // Not enough XP
        }
        if (scribe.chronosEnergy < rule.chronosCost) {
            revert NotEnoughChronosEnergy(); // Not enough ChronosEnergy
        }
        uint64 lastEvoTime = _getScribeLastInteractionTime(tokenId);
        if (block.timestamp < lastEvoTime + rule.timeSinceLastEvoRequired) {
            revert ScribeCannotEvolve(); // Still on cooldown
        }

        // Apply evolution
        scribe.xp -= rule.xpRequired;
        scribe.chronosEnergy -= uint64(rule.chronosCost);
        _setScribeLevel(tokenId, nextLevel); // Updates level and lastInteractionTime

        // Apply generic trait boosts upon evolution (can be more complex)
        for (uint8 i = 0; i < nextTraitId; i++) {
            if (traitDefinitions[i].exists) {
                _updateScribeTrait(tokenId, i, 5); // Example: +5 to all traits
            }
        }

        emit ScribeEvolved(tokenId, nextLevel, rule.xpRequired, rule.chronosCost);
    }

    /// @notice Allows the owner to claim the benefits (e.g., trait points, new abilities) after a Scribe has evolved.
    /// @dev This function could trigger specific trait changes or unlock new functionalities.
    ///      For simplicity, `initiateScribeEvolution` already applies generic perks.
    ///      This function is kept as a placeholder for more complex "claimable" perks post-evolution.
    /// @param tokenId The ID of the Scribe NFT.
    function claimEvolutionPerks(uint256 tokenId) public whenNotPaused {
        if (ownerOf(tokenId) != msg.sender) {
            revert NotScribeOwner();
        }
        // Example: if statusFlags[0] means 'evolution_perk_available'
        if (scribes[tokenId].statusFlags[0]) {
             scribes[tokenId].statusFlags[0] = false; // Mark as claimed
             // _updateScribeTrait(tokenId, specificTraitId, amount); // Grant specific trait boost
             // emit TraitUpdated(...);
        } else {
            // No perks to claim, or simply pass silently if this is for future use.
            // For now, it's illustrative.
        }
    }


    /// @notice Calculates and adds ChronosEnergy to a Scribe based on elapsed time and its current level.
    /// @dev This function encourages active participation by updating energy accrual.
    /// @param tokenId The ID of the Scribe NFT.
    function accrueChronosEnergy(uint256 tokenId) public whenNotPaused {
        if (ownerOf(tokenId) != msg.sender) {
            revert NotScribeOwner();
        }
        Scribe storage scribe = scribes[tokenId];

        uint64 lastTime = _getScribeLastInteractionTime(tokenId);
        uint64 currentTime = uint64(block.timestamp);

        if (currentTime <= lastTime) {
            return; // No time has passed
        }

        uint256 timeElapsed = currentTime - lastTime;
        uint256 energyPerSecond = _getScribeLevel(tokenId) * 1; // Example: 1 energy per second per level

        uint256 accrued = energyPerSecond * timeElapsed;
        uint256 newTotal = scribe.chronosEnergy + accrued;

        // Cap energy to prevent overflow or excessive accumulation
        if (newTotal > type(uint64).max) {
            scribe.chronosEnergy = type(uint64).max;
        } else {
            scribe.chronosEnergy = uint64(newTotal);
        }

        _setScribeLastInteractionTime(tokenId, currentTime); // Update interaction time
        emit ChronosEnergyAccrued(tokenId, accrued, scribe.chronosEnergy);
    }

    /// @notice Allows a Scribe owner to spend their accumulated ChronosEnergy for various actions.
    /// @param tokenId The ID of the Scribe NFT.
    /// @param amount The amount of ChronosEnergy to spend.
    function spendChronosEnergy(uint256 tokenId, uint256 amount) public whenNotPaused {
        if (ownerOf(tokenId) != msg.sender) {
            revert NotScribeOwner();
        }
        Scribe storage scribe = scribes[tokenId];
        if (scribe.chronosEnergy < amount) {
            revert NotEnoughChronosEnergy();
        }

        scribe.chronosEnergy -= uint64(amount);
        _setScribeLastInteractionTime(tokenId, uint64(block.timestamp)); // Update interaction time
        emit ChronosEnergySpent(tokenId, amount, scribe.chronosEnergy);
    }

    /// @notice (Internal/Admin) Modifies a specific trait's score for a Scribe.
    /// @param tokenId The ID of the Scribe.
    /// @param traitId The ID of the trait to modify.
    /// @param delta The amount to change the trait by (can be negative).
    function _updateScribeTrait(uint256 tokenId, uint8 traitId, int256 delta) internal {
        if (!traitDefinitions[traitId].exists) {
            revert TraitDefinitionDoesNotExist();
        }
        Scribe storage scribe = scribes[tokenId];
        int256 newScore = int256(scribe.traitScores[traitId]) + delta;

        // Clamp trait scores between reasonable bounds (e.g., 0 and 1000)
        if (newScore < 0) newScore = 0;
        if (newScore > 1000) newScore = 1000;

        scribe.traitScores[traitId] = int32(newScore);
        emit TraitUpdated(tokenId, traitId, delta, scribe.traitScores[traitId]);
    }

    /// @notice Returns the current numerical value of a specified trait for a Scribe.
    /// @param tokenId The ID of the Scribe.
    /// @param traitId The ID of the trait.
    /// @return The current score of the trait.
    function getScribeTraitValue(uint256 tokenId, uint8 traitId) public view returns (int32) {
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        if (!traitDefinitions[traitId].exists) {
            revert TraitDefinitionDoesNotExist();
        }
        return scribes[tokenId].traitScores[traitId];
    }

    // --- IV. Gamified Governance & Interaction ---

    /// @notice Allows Scribe owners to propose new lore entries, design concepts, or trait modification ideas for community discussion and voting.
    /// @param fragmentURI IPFS hash or URL for lore content.
    /// @param title Title of the lore proposal.
    /// @dev Requires a Scribe to be at least level 2 to propose lore.
    function proposeLoreFragment(string memory fragmentURI, string memory title) public whenNotPaused {
        // Find a Scribe owned by msg.sender
        uint256 proposerScribeId = 0;
        for (uint256 i = 0; i < totalSupply(); i++) {
            uint256 tid = tokenByIndex(i);
            if (ownerOf(tid) == msg.sender) {
                proposerScribeId = tid;
                break;
            }
        }
        if (proposerScribeId == 0) {
            revert NoEligibleScribeFound();
        }

        if (_getScribeLevel(proposerScribeId) < 2) {
            revert ScribeBelowMinLevelForAction(2, _getScribeLevel(proposerScribeId));
        }

        _loreProposalIdCounter.increment();
        uint256 proposalId = _loreProposalIdCounter.current();

        loreProposals[proposalId] = LoreProposal({
            title: title,
            fragmentURI: fragmentURI,
            creationTime: uint64(block.timestamp),
            votingEndTime: uint64(block.timestamp + 7 days), // 7 days voting period
            yesVotes: 0,
            noVotes: 0,
            totalVotes: 0,
            proposer: msg.sender,
            status: LoreProposalStatus.Active
        });

        emit LoreProposalCreated(proposalId, msg.sender, title);
    }

    /// @notice Scribe owners cast votes on active lore proposals, with voting power potentially influenced by their Scribe's level and ChronosEnergy.
    /// @param proposalId The ID of the lore proposal to vote on.
    /// @param tokenId The ID of the Scribe NFT used to cast the vote.
    /// @param support True for 'yes', false for 'no'.
    function voteOnLoreProposal(uint256 proposalId, uint256 tokenId, bool support) public whenNotPaused {
        if (ownerOf(tokenId) != msg.sender) {
            revert NotScribeOwner();
        }
        LoreProposal storage proposal = loreProposals[proposalId];
        if (proposal.creationTime == 0) {
            revert InvalidTokenId(); // Reusing, implies proposal doesn't exist
        }
        if (proposal.status != LoreProposalStatus.Active || block.timestamp > proposal.votingEndTime) {
            revert LoreProposalNotActive();
        }
        if (hasVotedOnLore[proposalId][tokenId]) {
            revert AlreadyVoted();
        }

        Scribe storage scribe = scribes[tokenId];
        // Voting power based on Scribe's level and ChronosEnergy
        uint256 votingPower = _getScribeLevel(tokenId) + (scribe.chronosEnergy / 100); // Example calculation
        if (votingPower == 0) votingPower = 1; // Min 1 vote

        if (support) {
            proposal.yesVotes += votingPower;
        } else {
            proposal.noVotes += votingPower;
        }
        proposal.totalVotes += votingPower;
        hasVotedOnLore[proposalId][tokenId] = true;

        emit LoreVoted(proposalId, tokenId, support);
    }

    /// @notice Owners submit verifiable proof of quest completion (e.g., cryptographic hash, external verification ID) to earn XP, ChronosEnergy, and other rewards.
    /// @dev The `proof` parameter could be a hash, a signed message from an oracle, or an ID to be verified off-chain.
    ///      Actual rewards are granted by `updateQuestStatus` after review by a Quest Master.
    /// @param questId The ID of the quest being completed.
    /// @param tokenId The ID of the Scribe NFT completing the quest.
    /// @param proof Placeholder for proof of completion.
    function completeQuestTask(uint256 questId, uint256 tokenId, bytes memory proof) public whenNotPaused {
        if (ownerOf(tokenId) != msg.sender) {
            revert NotScribeOwner();
        }
        Quest storage quest = quests[questId];
        if (quest.creationTime == 0) {
             revert InvalidTokenId(); // Reusing, implies quest doesn't exist
        }
        if (quest.status != QuestStatus.Active || block.timestamp > quest.creationTime + quest.duration) {
            revert QuestNotActive();
        }
        if (questCompletedByScribe[questId][tokenId]) {
            revert QuestAlreadyCompleted();
        }

        // --- Complex Proof Verification (Placeholder) ---
        // For this contract, simply record that completion was attempted and needs verification.
        // A QuestMaster will review and call `updateQuestStatus` to finalize.

        // Optionally, proof can be stored on-chain or off-chain depending on complexity.
        // For example, event can emit 'proof' for off-chain review.
        quest.status = QuestStatus.AwaitingVerification; // Requires Quest Master to verify

        emit QuestCompleted(questId, tokenId, msg.sender);
    }

    /// @notice Admin or privileged "Quest Master" Scribes can define and launch new community quests.
    /// @param title Title of the quest.
    /// @param descriptionURI IPFS hash or URL for quest details.
    /// @param xpReward XP reward for completion.
    /// @param chronosReward ChronosEnergy reward for completion.
    /// @param duration How long the quest is active (in seconds).
    function createCommunityQuest(
        string memory title,
        string memory descriptionURI,
        uint256 xpReward,
        uint256 chronosReward,
        uint256 duration
    ) public onlyRole(QUEST_MASTER_ROLE) whenNotPaused {
        _questIdCounter.increment();
        uint256 questId = _questIdCounter.current();

        quests[questId] = Quest({
            title: title,
            descriptionURI: descriptionURI,
            xpReward: xpReward,
            chronosReward: chronosReward,
            creationTime: uint64(block.timestamp),
            duration: uint64(duration),
            status: QuestStatus.Active,
            creator: msg.sender
        });

        emit QuestCreated(questId, msg.sender, title);
    }

    /// @notice Admin or DAO can activate time-limited global events that might temporarily or permanently impact all Scribes or specific trait categories.
    /// @dev This is a simplified example; a real system would have an 'Event' struct and more granular effects.
    /// @param eventId An identifier for the event.
    /// @param duration How long the event lasts (in seconds).
    /// @param traitModifierDelta A generic modifier that applies to traits.
    function activateGlobalEvent(uint256 eventId, uint256 duration, int256 traitModifierDelta) public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        // For demonstration, eventId 0 could mean "Global Aura Boost" influencing environmentalFactors[0]
        // In a more complex system, this would register a timed event and its effects would
        // be applied dynamically in functions like `accrueChronosEnergy` or `_updateScribeTrait`
        // by checking active events.
        environmentalFactors[uint8(eventId)] += traitModifierDelta; // Example: event affects an environmental factor
        emit EnvironmentalFactorAdjusted(uint8(eventId), environmentalFactors[uint8(eventId)]);
    }

    /// @notice Admin or privileged "Quest Masters" can approve, reject, or finalize the status of community quests after review.
    /// @dev This function is crucial for verifying `completeQuestTask` submissions.
    /// @param questId The ID of the quest to update.
    /// @param newStatus The new status for the quest (e.g., `Completed`, `Cancelled`).
    /// @param completerTokenId If setting to `Completed`, the tokenId that completed the quest (0 if not applicable).
    function updateQuestStatus(uint256 questId, QuestStatus newStatus, uint256 completerTokenId) public onlyRole(QUEST_MASTER_ROLE) whenNotPaused {
        Quest storage quest = quests[questId];
        if (quest.creationTime == 0) {
            revert InvalidTokenId(); // Reusing, implies quest doesn't exist
        }
        if (quest.status == QuestStatus.Completed || quest.status == QuestStatus.Cancelled) {
            revert InvalidQuestStatus(); // Cannot change status of finalized quests
        }

        QuestStatus oldStatus = quest.status;
        quest.status = newStatus;

        if (newStatus == QuestStatus.Completed) {
            if (!_exists(completerTokenId)) {
                revert InvalidTokenId(); // Must provide a valid tokenId for completion
            }
            if (questCompletedByScribe[questId][completerTokenId]) {
                revert QuestAlreadyCompleted(); // Already marked as completed
            }

            // Grant rewards
            Scribe storage scribe = scribes[completerTokenId];
            scribe.xp += uint64(quest.xpReward);
            scribe.chronosEnergy += uint64(quest.chronosReward);
            questCompletedByScribe[questId][completerTokenId] = true;
            // Potentially trigger trait updates too, e.g., _updateScribeTrait(completerTokenId, 0, 2);

            emit QuestCompleted(questId, completerTokenId, scribe.owner);
        }
        emit QuestStatusUpdated(questId, oldStatus, newStatus);
    }

    /// @notice Retrieves comprehensive information about a specific quest.
    /// @param questId The ID of the quest.
    /// @return Quest struct details.
    function getQuestDetails(uint256 questId) public view returns (Quest memory) {
        if (quests[questId].creationTime == 0) { // Check if quest exists
            revert InvalidTokenId(); // Reusing error, could be QuestNotFound
        }
        return quests[questId];
    }

    /// @notice Retrieves all details about a specific lore proposal, including votes and status.
    /// @param proposalId The ID of the lore proposal.
    /// @return LoreProposal struct details.
    function getLoreProposalDetails(uint256 proposalId) public view returns (LoreProposal memory) {
        if (loreProposals[proposalId].creationTime == 0) {
            revert InvalidTokenId(); // Reusing error, could be LoreProposalNotFound
        }
        return loreProposals[proposalId];
    }

    /// @notice Admin/Lore Master can finalize a lore proposal based on vote outcome, potentially applying its effects.
    /// @param proposalId The ID of the lore proposal to finalize.
    function finalizeLoreProposal(uint256 proposalId) public onlyRole(LORE_MASTER_ROLE) whenNotPaused {
        LoreProposal storage proposal = loreProposals[proposalId];
        if (proposal.creationTime == 0) {
            revert InvalidTokenId(); // Reusing, implies proposal doesn't exist
        }
        if (proposal.status != LoreProposalStatus.Active || block.timestamp < proposal.votingEndTime) {
            revert LoreProposalNotFinalizable();
        }

        if (proposal.totalVotes == 0) {
            proposal.status = LoreProposalStatus.Rejected; // No votes, effectively rejected
        } else if (proposal.yesVotes > proposal.noVotes) {
            proposal.status = LoreProposalStatus.Approved;
        } else {
            proposal.status = LoreProposalStatus.Rejected;
        }
        emit LoreProposalFinalized(proposalId, proposal.status);
    }

    /// @notice (Admin) Registers a specific trait change outcome from a finalized lore proposal.
    /// @dev This function is manually called by the Lore Master after a proposal is approved.
    ///      Impacts a global environmental factor as iterating through all NFTs is gas-intensive.
    /// @param proposalId The ID of the lore proposal.
    /// @param traitId The ID of the trait to modify (e.g., environmentalFactors index).
    /// @param delta The amount to change the trait by.
    function registerTraitChangeFromLore(uint256 proposalId, uint8 traitId, int256 delta) public onlyRole(LORE_MASTER_ROLE) whenNotPaused {
        LoreProposal storage proposal = loreProposals[proposalId];
        if (proposal.status != LoreProposalStatus.Approved) {
            revert LoreProposalNotApproved();
        }
        if (!traitDefinitions[traitId].exists) {
            revert TraitDefinitionDoesNotExist();
        }

        // Apply this as a global modifier to an environmental factor.
        // Direct iteration over all Scribes (for-loop over `totalSupply()`) is highly gas-intensive
        // and not scalable for large NFT collections.
        environmentalFactors[traitId] += delta; // Example: Lore changes global "Wisdom" factor
        emit EnvironmentalFactorAdjusted(traitId, environmentalFactors[traitId]);

        // Mark proposal as finalized to prevent double application
        proposal.status = LoreProposalStatus.Finalized;
        emit LoreProposalFinalized(proposalId, proposal.status);
    }


    // --- V. Ecosystem Configuration & Treasury ---

    /// @notice Admin or DAO defines the conditions (XP, Chronos, time) for a Scribe to reach a new level and evolve.
    /// @param level The target level for this rule.
    /// @param xpRequired XP required for this level.
    /// @param chronosCost ChronosEnergy required for this level.
    /// @param timeSinceLastEvoRequired Minimum time (in seconds) since last evolution.
    /// @param description Description of this evolution stage.
    function setEvolutionRule(
        uint8 level,
        uint256 xpRequired,
        uint256 chronosCost,
        uint256 timeSinceLastEvoRequired,
        string memory description
    ) public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        evolutionRules[level] = EvolutionRule({
            xpRequired: xpRequired,
            chronosCost: chronosCost,
            timeSinceLastEvoRequired: timeSinceLastEvoRequired,
            description: description,
            exists: true
        });
    }

    /// @notice Admin or DAO sets up the possible traits for Scribes, their unique identifiers, and descriptions.
    /// @dev A maximum of 255 traits can be defined due to `uint8` indexing.
    /// @param traitId The ID for the new trait.
    /// @param name Name of the trait.
    /// @param description Description of the trait.
    function defineScribeTrait(uint8 traitId, string memory name, string memory description) public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        if (traitId >= type(uint8).max) { // Max 255 traits
            revert MaxTraitsReached();
        }
        // If this is a new trait, ensure nextTraitId accounts for it.
        // Allows defining a specific ID, but keeps nextTraitId tracking.
        if (!traitDefinitions[traitId].exists) {
            if (traitId == nextTraitId) {
                nextTraitId++;
            } else if (traitId > nextTraitId) {
                nextTraitId = traitId + 1; // Adjust nextTraitId if a higher ID is explicitly set
            }
        }

        traitDefinitions[traitId] = TraitDefinition({
            name: name,
            description: description,
            exists: true
        });
    }

    /// @notice Admin or an Oracle-fed function to update an ecosystem-wide "environmental factor" that might influence Scribe growth or energy generation.
    /// @param factorId The ID of the environmental factor.
    /// @param newValue The new value for the factor.
    function adjustEnvironmentalFactor(uint8 factorId, int256 newValue) public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        environmentalFactors[factorId] = newValue;
        emit EnvironmentalFactorAdjusted(factorId, newValue);
    }

    /// @notice Admin can adjust the cost of minting a new Scribe and the overall maximum supply cap for the collection.
    /// @param newMintCost The new cost in wei to mint a Scribe.
    /// @param newMaxSupply The new maximum number of Scribes that can be minted.
    function setMintParameters(uint256 newMintCost, uint256 newMaxSupply) public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        mintCost = newMintCost;
        maxSupply = newMaxSupply;
    }

    /// @notice Allows the authorized admin/DAO to withdraw accumulated ETH funds from the contract's treasury.
    /// @param recipient The address to send the funds to.
    /// @param amount The amount of ETH to withdraw (in wei).
    function withdrawTreasuryFunds(address recipient, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        if (amount == 0) {
            revert NoEthToWithdraw();
        }
        if (address(this).balance < amount) {
            revert InsufficientFunds();
        }
        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert Unauthorized(); // Reusing error, could be specific 'WithdrawalFailed'
        }
        emit TreasuryFundsWithdrawn(recipient, uint224(amount));
    }

    /// @notice Allows any user to contribute ETH to the contract's treasury, publicly supporting the Chronoscribe ecosystem.
    function depositTreasuryFunds() public payable whenNotPaused {
        if (msg.value == 0) {
            revert NoEthToWithdraw(); // Reusing error, implies 0 ETH deposit
        }
        emit TreasuryFundsDeposited(msg.sender, uint224(msg.value));
    }

    /// @notice Emergency function to pause critical contract operations (e.g., minting, evolution, quest submissions) by the authorized admin.
    function pauseEcosystemOperations() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /// @notice Emergency function to unpause critical contract operations by the authorized admin.
    function unpauseEcosystemOperations() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /// @notice Sets the base URI for token metadata.
    /// @param _newBaseURI The new base URI.
    function setBaseURI(string memory _newBaseURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setBaseURI(_newBaseURI);
        baseURI = _newBaseURI; // Store it for public access
    }

    // AccessControl method required by OpenZeppelin for upgradable contracts, even if not used directly
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
```