Okay, let's create an interesting and advanced smart contract concept. We'll build a system of "Autonomous Agents" represented as Dynamic NFTs. These agents exist on-chain, have evolving stats and states influenced by interactions, time, and simulated "Aetheric Events" delivered via an oracle. A separate keeper system can trigger maintenance functions. It incorporates elements of gaming, dynamic NFTs, oracle integration, basic resource management, and potential for complex state transitions, while aiming to be distinct from standard open-source examples by combining these features in a specific simulation context.

**Concept:** **Aetherium Automata - Dynamic On-Chain Agents**

*   **Core Idea:** An ERC-721 contract where each token represents a unique 'Automaton'. Automata have on-chain stats (Health, Energy, Strength, etc.) and states that change based on owner actions (`explore`, `rest`), interactions with other Automata (`duel`), time elapsed, and external data (`Aetheric Events` from an oracle). A decentralized keeper network is envisioned to trigger time-sensitive state changes or maintenance.
*   **Advanced/Interesting Concepts:**
    *   **Dynamic NFT State:** Token metadata/attributes evolve based *entirely* on on-chain logic and external data.
    *   **On-Chain Simulation:** Core agent mechanics (actions, state changes, simple interactions) are handled within the contract.
    *   **Oracle Influence:** Agent stats/performance can be dynamically affected by external, real-world or simulated data injected via a trusted oracle.
    *   **Keeper Integration:** Designed to work with external decentralized keepers to trigger time-based effects or maintenance.
    *   **Resource Management:** Agents find/use a basic on-chain resource for upgrades or actions.
    *   **Complex State Transitions:** Actions and events don't just transfer value; they change the agent's internal state which affects future possibilities.
    *   **Reputation System:** A simple on-chain reputation score tied to agent performance/interactions.

---

## Aetherium Automata Contract Outline & Function Summary

**Contract Name:** `AetheriumAutomata`

**Inherits:** ERC721 (basic NFT functionality), Ownable (admin control), Pausable (emergency pause).

**State Variables:**
*   `Automaton` struct: Defines agent properties (stats, state, cooldowns, owner, etc.).
*   Mappings: `tokenId -> Automaton`, `address -> resourceBalance`.
*   Counters: For total tokens minted.
*   Global state: Current Aetheric Event, Oracle address, Keeper address, game parameters.

**Events:**
*   Standard ERC721 events (Transfer, Approval, ApprovalForAll).
*   Custom events: AutomatonMinted, ActionPerformed, StateChanged, AethericEventReceived, AutomatonUpgraded, ResourcesDistributed, MaintenanceTriggered.

**Modifiers:**
*   `onlyOwner`: Standard Ownable.
*   `whenNotPaused`: Standard Pausable.
*   `onlyOracle`: Restrict calls to the designated oracle address.
*   `onlyKeeper`: Restrict calls to the designated keeper address.
*   `onlyAutomatonOwnerOrApproved`: Check if caller owns or is approved for a specific token.
*   `actionReady`: Check if an agent's cooldown for actions has passed.

**Functions:**

1.  **`constructor(address initialOwner, address oracleAddress, address keeperAddress)`**: Initializes the contract, sets owner, oracle, and keeper addresses.
2.  **`mintAutomaton(string calldata name)`**: Mints a new Automaton NFT, initializes its base stats and state, assigns it to the caller.
3.  **`explore(uint256 tokenId)`**: Automaton action. Consumes energy, adds XP, potentially finds resources, sets action cooldown. Requires `onlyAutomatonOwnerOrApproved` and `actionReady`.
4.  **`rest(uint256 tokenId)`**: Automaton action. Recovers energy over time, sets action cooldown. Requires `onlyAutomatonOwnerOrApproved` and `actionReady`.
5.  **`train(uint256 tokenId, string calldata statName)`**: Automaton action. Consumes energy, increases a specific stat based on Intelligence, adds XP, sets action cooldown. Requires `onlyAutomatonOwnerOrApproved` and `actionReady`. `statName` could be "strength", "agility", "intelligence".
6.  **`duel(uint256 tokenId1, uint256 tokenId2)`**: Automaton interaction. Simulates a simple duel based on effective stats, affects health and reputation of both agents, sets cooldowns. Requires ownership/approval for both, `actionReady` for both.
7.  **`upgradeStats(uint256 tokenId, string[] calldata statNames)`**: Uses XP to increase base stats. Requirements: sufficient XP.
8.  **`upgradeLevelCap(uint256 tokenId)`**: Uses resources to increase the agent's maximum level or stat caps. Requires: sufficient resources.
9.  **`receiveAethericEvent(bytes32 eventId, uint256 eventEffectMagnitude, uint256 duration)`**: Callable only by the oracle. Updates the global `currentAethericEvent` state, which dynamically influences agent effective stats via `getAutomatonStatsEffective`.
10. **`triggerMaintenance()`**: Callable only by the keeper. Processes any time-dependent logic for *all* active agents (e.g., apply passive energy regen, decay if inactive), updates a global `lastMaintenanceTime`. *Note: This might be gas-intensive depending on implementation; could be optimized to process batches or rely on dynamic calculation.*
11. **`distributeResources(uint256 amount)`**: Example function where the contract (e.g., from game activities) can award resources to the caller's resource balance.
12. **`transferResources(address recipient, uint256 amount)`**: Allows an owner to transfer their earned resources to another address.
13. **`getAutomatonState(uint256 tokenId)`**: View function. Returns the full struct data for an Automaton.
14. **`getAutomatonStatsEffective(uint256 tokenId)`**: View function. Calculates and returns the agent's effective stats (base stats + level bonus + Aetheric Event modifiers).
15. **`getAethericEvent()`**: View function. Returns details of the current Aetheric Event.
16. **`getAutomatonReputation(uint256 tokenId)`**: View function. Returns the agent's current reputation score.
17. **`getResourceBalance(address owner)`**: View function. Returns the resource balance for a given address.
18. **`getAutomatonCount()`**: View function. Returns the total number of Automata minted.
19. **`isActionReady(uint256 tokenId)`**: View function. Checks if an agent's action cooldown has expired.
20. **`tokenURI(uint256 tokenId)`**: ERC721 standard. Returns the URI for the token metadata JSON. This URI should point to a service that dynamically generates metadata based on the on-chain state returned by `getAutomatonState` and `getAutomatonStatsEffective`.
21. **`pause()`**: Callable by owner. Pauses actions affecting agent state.
22. **`unpause()`**: Callable by owner. Unpauses contract.
23. **`setBaseURI(string calldata baseURI)`**: Callable by owner. Sets the base URI for `tokenURI`.
24. **`setOracleAddress(address oracleAddress)`**: Callable by owner. Updates the trusted oracle address.
25. **`setKeeperAddress(address keeperAddress)`**: Callable by owner. Updates the trusted keeper address.
26. **`getRequiredXPForNextLevel(uint256 currentLevel)`**: Pure function. Calculates XP needed for the next level.
27. **`getResourcesRequiredForUpgrade(uint256 currentUpgradeCount)`**: Pure function. Calculates resources needed for the next level cap/stat upgrade.
28. **`getEnergyRecoveryRate(uint256 tokenId)`**: View function. Calculates current energy recovery rate based on stats or state.
29. **`getHealthRecoveryRate(uint256 tokenId)`**: View function. Calculates current health recovery rate based on stats or state.
30. **`calculateDamage(uint256 attackerTokenId, uint256 defenderTokenId)`**: Internal helper function used in `duel`. Calculates potential damage based on effective stats. (Could be made public view for testing/frontend).

*(Note: Functions 13-20 are part of the ERC721 standard or essential utilities. The remaining functions implement the custom logic, bringing the total well over 20 distinctive operations related to the contract's specific purpose.)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

// Aetherium Automata - Dynamic On-Chain Agent Network
//
// Concept: An ERC-721 contract where each token represents a unique 'Automaton'.
// Automata have on-chain stats (Health, Energy, Strength, etc.) and states that change
// based on owner actions (explore, rest), interactions with other Automata (duel),
// time elapsed, and external data (Aetheric Events from an oracle).
// A decentralized keeper network can trigger time-sensitive state changes or maintenance.
//
// Outline & Function Summary:
//
// State Variables:
// - Automaton struct: Defines agent properties (stats, state, cooldowns, owner, etc.).
// - Mappings: tokenId -> Automaton, address -> resourceBalance.
// - Counters: For total tokens minted.
// - Global state: Current Aetheric Event, Oracle address, Keeper address, game parameters.
//
// Events:
// - Standard ERC721 events (Transfer, Approval, ApprovalForAll).
// - Custom events: AutomatonMinted, ActionPerformed, StateChanged, AethericEventReceived,
//   AutomatonUpgraded, ResourcesDistributed, MaintenanceTriggered, ReputationChanged.
//
// Modifiers:
// - onlyOwner: Standard Ownable.
// - whenNotPaused: Standard Pausable.
// - onlyOracle: Restrict calls to the designated oracle address.
// - onlyKeeper: Restrict calls to the designated keeper address.
// - onlyAutomatonOwnerOrApproved: Check if caller owns or is approved for a specific token.
// - actionReady: Check if an agent's cooldown for actions has passed.
//
// Functions (>= 30):
// 01. constructor(address initialOwner, address oracleAddress, address keeperAddress)
// 02. mintAutomaton(string calldata name) - Creates a new Automaton NFT.
// 03. explore(uint256 tokenId) - Agent action: consume energy, gain XP, find resources.
// 04. rest(uint256 tokenId) - Agent action: recover energy.
// 05. train(uint256 tokenId, string calldata statName) - Agent action: consume energy, increase stat, gain XP.
// 06. duel(uint256 tokenId1, uint256 tokenId2) - Agent interaction: simulate combat, affects health & reputation.
// 07. upgradeStats(uint256 tokenId, string[] calldata statNames) - Uses XP to increase base stats.
// 08. upgradeLevelCap(uint256 tokenId) - Uses resources to increase max level/stat caps.
// 09. receiveAethericEvent(bytes32 eventId, uint256 eventEffectMagnitude, uint256 duration) - Callable by oracle, updates global event state.
// 10. triggerMaintenance() - Callable by keeper, applies time-based effects or processes queues.
// 11. distributeResources(uint256 amount) - Awards resources (e.g., from exploration).
// 12. transferResources(address recipient, uint256 amount) - Allows resource transfer.
// 13. getAutomatonState(uint256 tokenId) - View: Returns full struct data.
// 14. getAutomatonStatsEffective(uint256 tokenId) - View: Calculates stats including dynamic modifiers.
// 15. getAethericEvent() - View: Returns current Aetheric Event details.
// 16. getAutomatonReputation(uint256 tokenId) - View: Returns reputation score.
// 17. getResourceBalance(address owner) - View: Returns resource balance.
// 18. getAutomatonCount() - View: Returns total minted count.
// 19. isActionReady(uint256 tokenId) - View: Checks cooldown status.
// 20. tokenURI(uint256 tokenId) - ERC721: Returns metadata URI (dynamic).
// 21. pause() - Admin: Pauses contract.
// 22. unpause() - Admin: Unpauses contract.
// 23. setBaseURI(string calldata baseURI) - Admin: Sets metadata URI prefix.
// 24. setOracleAddress(address oracleAddress) - Admin: Sets trusted oracle address.
// 25. setKeeperAddress(address keeperAddress) - Admin: Sets trusted keeper address.
// 26. getRequiredXPForNextLevel(uint256 currentLevel) - Pure: Calculates XP for next level.
// 27. getResourcesRequiredForUpgrade(uint256 currentUpgradeCount) - Pure: Calculates resources for next upgrade.
// 28. getEnergyRecoveryRate(uint256 tokenId) - View: Calculates current energy recovery rate.
// 29. getHealthRecoveryRate(uint256 tokenId) - View: Calculates current health recovery rate.
// 30. calculateDamage(uint256 attackerTokenId, uint256 defenderTokenId) - Internal: Calculates damage (used in duel).
// --- Plus standard ERC721 functions inherited: ---
// 31. transferFrom(address from, address to, uint256 tokenId)
// 32. safeTransferFrom(address from, address to, uint256 tokenId)
// 33. safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
// 34. approve(address to, uint256 tokenId)
// 35. setApprovalForAll(address operator, bool approved)
// 36. getApproved(uint256 tokenId)
// 37. isApprovedForAll(address owner, address operator)
// 38. balanceOf(address owner)
// 39. ownerOf(uint256 tokenId)
// 40. supportsInterface(bytes4 interfaceId) - Standard ERC165

contract AetheriumAutomata is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- Structs ---

    struct Automaton {
        uint256 id;
        string name;
        uint256 level;
        uint256 xp;
        uint256 currentHealth;
        uint256 currentEnergy;
        // Base Stats
        uint256 baseStrength;
        uint256 baseAgility;
        uint256 baseIntelligence;
        // Dynamic/State
        uint256 reputation;
        uint256 lastActionTime;
        uint256 lastMaintenanceTime; // Timestamp of last time keeper touched this agent (or maintenance run)
        uint256 energyRecoveryStartTime; // Timestamp when energy recovery started (e.g., when resting)
        // Could add status effects, buffs/debuffs etc.
        bool isResting;
        uint256 upgradeCount; // How many times stats/level cap have been upgraded
    }

    struct AethericEvent {
        bytes32 eventId;
        uint256 effectMagnitude; // e.g., percentage boost/reduction
        uint256 duration;        // How long the event lasts (timestamp ending)
        // Could add specific stats affected, types of effects etc.
    }

    // --- State Variables ---

    mapping(uint256 => Automaton) private _automata;
    mapping(address => uint256) private _resourceBalances;

    address private _oracleAddress;
    address private _keeperAddress;

    AethericEvent private _currentAethericEvent;
    uint256 private _lastGlobalMaintenanceTime; // Timestamp of the last global maintenance run

    uint256 public constant ACTION_COOLDOWN = 1 hours; // Cooldown for most actions
    uint256 public constant BASE_XP_GAIN_EXPLORE = 10;
    uint256 public constant BASE_ENERGY_COST_EXPLORE = 20;
    uint256 public constant BASE_ENERGY_COST_TRAIN = 15;
    uint256 public constant BASE_ENERGY_COST_DUEL = 30;
    uint256 public constant REST_ENERGY_PER_HOUR = 30;
    uint256 public constant DUEL_REPUTATION_CHANGE_WIN = 5;
    uint256 public constant DUEL_REPUTATION_CHANGE_LOSS = 2;
    uint256 public constant STARTING_RESOURCES = 10; // Resources given on mint

    string private _baseTokenURI;

    // --- Events ---

    event AutomatonMinted(uint256 indexed tokenId, address indexed owner, string name, uint256 initialLevel);
    event ActionPerformed(uint256 indexed tokenId, string action, uint256 timestamp);
    event StateChanged(uint256 indexed tokenId, string stateKey, uint256 oldValue, uint256 newValue); // Generic for stat/value changes
    event AethericEventReceived(bytes32 eventId, uint256 effectMagnitude, uint256 duration, uint256 timestamp);
    event AutomatonUpgraded(uint256 indexed tokenId, uint256 newLevel, uint256 newUpgradeCount);
    event ResourcesDistributed(address indexed owner, uint256 amount);
    event MaintenanceTriggered(uint256 timestamp);
    event ReputationChanged(uint256 indexed tokenId, int256 change, uint256 newReputation);

    // --- Modifiers ---

    modifier onlyOracle() {
        require(msg.sender == _oracleAddress, "Caller is not the oracle");
        _;
    }

    modifier onlyKeeper() {
        require(msg.sender == _keeperAddress, "Caller is not the keeper");
        _;
    }

    modifier onlyAutomatonOwnerOrApproved(uint256 tokenId) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");
        _;
    }

    modifier actionReady(uint256 tokenId) {
        require(_automata[tokenId].lastActionTime + ACTION_COOLDOWN <= block.timestamp, "Action not ready yet");
        _;
    }

    // --- Constructor ---

    constructor(address initialOwner, address oracleAddress, address keeperAddress)
        ERC721("AetheriumAutomata", "AETHA")
        Ownable(initialOwner)
        Pausable()
    {
        _oracleAddress = oracleAddress;
        _keeperAddress = keeperAddress;
        _lastGlobalMaintenanceTime = block.timestamp; // Initialize last maintenance time
        _currentAethericEvent.duration = block.timestamp; // Start with expired event
    }

    // --- Standard ERC721 Functions (Inherited from OpenZeppelin) ---
    // _safeMint, transferFrom, safeTransferFrom, approve, setApprovalForAll, getApproved,
    // isApprovedForAll, balanceOf, ownerOf, supportsInterface are inherited.
    // tokenURI is overridden below.

    // --- Core Game Logic Functions ---

    /**
     * @dev Mints a new Automaton NFT for the caller.
     * @param name The name of the new Automaton.
     */
    function mintAutomaton(string calldata name) public whenNotPaused returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _safeMint(msg.sender, newItemId);

        // Initialize new Automaton state
        _automata[newItemId] = Automaton({
            id: newItemId,
            name: name,
            level: 1,
            xp: 0,
            currentHealth: 100, // Start with full health
            currentEnergy: 100, // Start with full energy
            baseStrength: 5,
            baseAgility: 5,
            baseIntelligence: 5,
            reputation: 50, // Start with neutral reputation
            lastActionTime: 0, // Ready immediately after mint
            lastMaintenanceTime: block.timestamp, // Set initial maintenance time
            energyRecoveryStartTime: block.timestamp, // Energy starts recovering immediately
            isResting: false,
            upgradeCount: 0
        });

        // Give starting resources
        _resourceBalances[msg.sender] += STARTING_RESOURCES;
        emit ResourcesDistributed(msg.sender, STARTING_RESOURCES);

        emit AutomatonMinted(newItemId, msg.sender, name, 1);
        return newItemId;
    }

    /**
     * @dev Allows an Automaton to explore, consuming energy and potentially finding resources.
     * @param tokenId The ID of the Automaton.
     */
    function explore(uint256 tokenId) public whenNotPaused onlyAutomatonOwnerOrApproved(tokenId) actionReady(tokenId) {
        Automaton storage auto = _automata[tokenId];
        require(auto.currentEnergy >= BASE_ENERGY_COST_EXPLORE, "Not enough energy to explore");

        uint256 oldEnergy = auto.currentEnergy;
        auto.currentEnergy = Math.max(0, auto.currentEnergy - BASE_ENERGY_COST_EXPLORE);
        auto.xp += BASE_XP_GAIN_EXPLORE;
        auto.lastActionTime = block.timestamp;
        auto.isResting = false; // Stop resting if exploring

        emit ActionPerformed(tokenId, "explore", block.timestamp);
        emit StateChanged(tokenId, "energy", oldEnergy, auto.currentEnergy);
        emit StateChanged(tokenId, "xp", auto.xp - BASE_XP_GAIN_EXPLORE, auto.xp);

        // Simple resource finding logic (can be more complex)
        uint256 resourcesFound = Math.max(0, auto.baseIntelligence / 2 + uint256(block.timestamp) % 5); // Example: based on Int + small randomness
        if (resourcesFound > 0) {
            address owner = ownerOf(tokenId);
            _resourceBalances[owner] += resourcesFound;
            emit ResourcesDistributed(owner, resourcesFound);
        }

        _checkLevelUp(tokenId);
    }

    /**
     * @dev Allows an Automaton to rest, recovering energy over time.
     * @param tokenId The ID of the Automaton.
     */
    function rest(uint256 tokenId) public whenNotPaused onlyAutomatonOwnerOrApproved(tokenId) actionReady(tokenId) {
         Automaton storage auto = _automata[tokenId];

        if (!auto.isResting) {
            auto.isResting = true;
            auto.energyRecoveryStartTime = block.timestamp; // Start tracking recovery time
        }
        // Apply accumulated recovery
        _applyEnergyRecovery(tokenId);

        auto.lastActionTime = block.timestamp; // Still counts as an action to set cooldown

        emit ActionPerformed(tokenId, "rest", block.timestamp);
    }

    /**
     * @dev Allows an Automaton to train, increasing a specific base stat.
     * @param tokenId The ID of the Automaton.
     * @param statName The name of the stat to train ("strength", "agility", "intelligence").
     */
    function train(uint256 tokenId, string calldata statName) public whenNotPaused onlyAutomatonOwnerOrApproved(tokenId) actionReady(tokenId) {
        Automaton storage auto = _automata[tokenId];
        require(auto.currentEnergy >= BASE_ENERGY_COST_TRAIN, "Not enough energy to train");

        uint256 oldEnergy = auto.currentEnergy;
        auto.currentEnergy = Math.max(0, auto.currentEnergy - BASE_ENERGY_COST_TRAIN);
        auto.xp += BASE_XP_GAIN_EXPLORE; // Training also gives XP
        auto.lastActionTime = block.timestamp;
        auto.isResting = false; // Stop resting if training

        bytes32 statHash = keccak256(abi.encodePacked(statName));
        uint256 statIncrease = Math.max(1, auto.baseIntelligence / 10); // Training effectiveness based on Intelligence

        if (statHash == keccak256(abi.encodePacked("strength"))) {
            auto.baseStrength += statIncrease;
            emit StateChanged(tokenId, "baseStrength", auto.baseStrength - statIncrease, auto.baseStrength);
        } else if (statHash == keccak256(abi.encodePacked("agility"))) {
            auto.baseAgility += statIncrease;
            emit StateChanged(tokenId, "baseAgility", auto.baseAgility - statIncrease, auto.baseAgility);
        } else if (statHash == keccak256(abi.encodePacked("intelligence"))) {
            auto.baseIntelligence += statIncrease;
            emit StateChanged(tokenId, "baseIntelligence", auto.baseIntelligence - statIncrease, auto.baseIntelligence);
        } else {
            revert("Invalid stat name");
        }

        emit ActionPerformed(tokenId, string(abi.encodePacked("train_", statName)), block.timestamp);
        emit StateChanged(tokenId, "energy", oldEnergy, auto.currentEnergy);
        emit StateChanged(tokenId, "xp", auto.xp - BASE_XP_GAIN_EXPLORE, auto.xp);

        _checkLevelUp(tokenId);
    }

    /**
     * @dev Simulates a duel between two Automata. Affects health and reputation.
     * @param tokenId1 The ID of the first Automaton.
     * @param tokenId2 The ID of the second Automaton.
     */
    function duel(uint256 tokenId1, uint256 tokenId2) public whenNotPaused {
        require(tokenId1 != tokenId2, "Cannot duel self");
        require(_exists(tokenId1), "Automaton 1 does not exist");
        require(_exists(tokenId2), "Automaton 2 does not exist");

        // Caller must be owner/approved for AT LEAST one of the participants
        // (allowing setting up duels between your own agents or accepting duels)
        require(_isApprovedOrOwner(_msgSender(), tokenId1) || _isApprovedOrOwner(_msgSender(), tokenId2), "Caller is not owner/approved for either Automaton");

        // Both agents must be ready for action (no cooldown)
        require(isActionReady(tokenId1), "Automaton 1 not ready for action");
        require(isActionReady(tokenId2), "Automaton 2 not ready for action");
        // Both agents must have enough energy
        require(_automata[tokenId1].currentEnergy >= BASE_ENERGY_COST_DUEL, "Automaton 1 not enough energy");
        require(_automata[tokenId2].currentEnergy >= BASE_ENERGY_COST_DUEL, "Automaton 2 not enough energy");

        // Get mutable references
        Automaton storage auto1 = _automata[tokenId1];
        Automaton storage auto2 = _automata[tokenId2];

        // Apply any pending energy recovery before duel
        _applyEnergyRecovery(tokenId1);
        _applyEnergyRecovery(tokenId2);

        // Consume energy
        uint256 oldEnergy1 = auto1.currentEnergy;
        uint256 oldEnergy2 = auto2.currentEnergy;
        auto1.currentEnergy = Math.max(0, auto1.currentEnergy - BASE_ENERGY_COST_DUEL);
        auto2.currentEnergy = Math.max(0, auto2.currentEnergy - BASE_ENERGY_COST_DUEL);
        emit StateChanged(tokenId1, "energy", oldEnergy1, auto1.currentEnergy);
        emit StateChanged(tokenId2, "energy", oldEnergy2, auto2.currentEnergy);

        // Simulate combat turn-based (simplified)
        uint256 effectiveStr1 = getAutomatonStatsEffective(tokenId1).strength;
        uint256 effectiveAgi1 = getAutomatonStatsEffective(tokenId1).agility;
        uint256 effectiveInt1 = getAutomatonStatsEffective(tokenId1).intelligence;

        uint256 effectiveStr2 = getAutomatonStatsEffective(tokenId2).strength;
        uint256 effectiveAgi2 = getAutomatonStatsEffective(tokenId2).agility;
        uint256 effectiveInt2 = getAutomatonStatsEffective(tokenId2).intelligence;

        // Simple win condition: Higher combined stats (Str + Agi) wins
        uint256 score1 = effectiveStr1 + effectiveAgi1;
        uint256 score2 = effectiveStr2 + effectiveAgi2;

        uint256 damage1_to_2 = calculateDamage(tokenId1, tokenId2);
        uint256 damage2_to_1 = calculateDamage(tokenId2, tokenId1);

        uint256 oldHealth1 = auto1.currentHealth;
        uint256 oldHealth2 = auto2.currentHealth;

        auto1.currentHealth = Math.max(0, auto1.currentHealth - damage2_to_1);
        auto2.currentHealth = Math.max(0, auto2.currentHealth - damage1_to_2);

        emit StateChanged(tokenId1, "health", oldHealth1, auto1.currentHealth);
        emit StateChanged(tokenId2, "health", oldHealth2, auto2.currentHealth);

        // Reputation Change & XP Gain
        if (score1 > score2) {
            // Automaton 1 wins
            auto1.reputation += DUEL_REPUTATION_CHANGE_WIN;
            auto2.reputation = Math.max(0, auto2.reputation - DUEL_REPUTATION_CHANGE_LOSS);
            auto1.xp += BASE_XP_GAIN_EXPLORE * 2; // Bonus XP for winning
            emit ReputationChanged(tokenId1, int256(DUEL_REPUTATION_CHANGE_WIN), auto1.reputation);
            emit ReputationChanged(tokenId2, int256(-int256(DUEL_REPUTATION_CHANGE_LOSS)), auto2.reputation);
            emit StateChanged(tokenId1, "xp", auto1.xp - BASE_XP_GAIN_EXPLORE * 2, auto1.xp);
            // Could also add XP to auto2 for participation, maybe less
        } else if (score2 > score1) {
            // Automaton 2 wins
            auto2.reputation += DUEL_REPUTATION_CHANGE_WIN;
            auto1.reputation = Math.max(0, auto1.reputation - DUEL_REPUTATION_CHANGE_LOSS);
            auto2.xp += BASE_XP_GAIN_EXPLORE * 2; // Bonus XP for winning
            emit ReputationChanged(tokenId2, int256(DUEL_REPUTATION_CHANGE_WIN), auto2.reputation);
            emit ReputationChanged(tokenId1, int256(-int256(DUEL_REPUTATION_CHANGE_LOSS)), auto1.reputation);
            emit StateChanged(tokenId2, "xp", auto2.xp - BASE_XP_GAIN_EXPLORE * 2, auto2.xp);
        } else {
            // Draw (less reputation change)
            auto1.reputation = Math.max(0, auto1.reputation - Math.max(0, DUEL_REPUTATION_CHANGE_LOSS / 2));
            auto2.reputation = Math.max(0, auto2.reputation - Math.max(0, DUEL_REPUTATION_CHANGE_LOSS / 2));
             emit ReputationChanged(tokenId1, int256(-int256(DUEL_REPUTATION_CHANGE_LOSS / 2)), auto1.reputation);
            emit ReputationChanged(tokenId2, int256(-int256(DUEL_REPUTATION_CHANGE_LOSS / 2)), auto2.reputation);
        }

        // Set cooldowns for both
        auto1.lastActionTime = block.timestamp;
        auto2.lastActionTime = block.timestamp;
        auto1.isResting = false; // Stop resting
        auto2.isResting = false;

        emit ActionPerformed(tokenId1, "duel", block.timestamp);
        emit ActionPerformed(tokenId2, "duel", block.timestamp);

        _checkLevelUp(tokenId1);
        _checkLevelUp(tokenId2);
    }

    /**
     * @dev Allows an Automaton owner to spend XP to increase base stats.
     * @param tokenId The ID of the Automaton.
     * @param statNames An array of stat names to increase ("strength", "agility", "intelligence").
     */
    function upgradeStats(uint256 tokenId, string[] calldata statNames) public whenNotPaused onlyAutomatonOwnerOrApproved(tokenId) {
        Automaton storage auto = _automata[tokenId];
        uint256 totalXPcost = 0;
        uint256 xpCostPerPoint = auto.level * 5; // Example: Cost increases with level

        // Calculate total cost and validate stats
        for (uint i = 0; i < statNames.length; i++) {
            bytes32 statHash = keccak256(abi.encodePacked(statNames[i]));
             if (statHash != keccak256(abi.encodePacked("strength")) &&
                statHash != keccak256(abi.encodePacked("agility")) &&
                statHash != keccak256(abi.encodePacked("intelligence")))
            {
                 revert("Invalid stat name in array");
            }
            totalXPcost += xpCostPerPoint; // Assume 1 point increase per stat listed
        }

        require(auto.xp >= totalXPcost, "Not enough XP to upgrade stats");

        auto.xp = Math.max(0, auto.xp - totalXPcost);
        emit StateChanged(tokenId, "xp", auto.xp + totalXPcost, auto.xp);

        // Apply upgrades
        for (uint i = 0; i < statNames.length; i++) {
            bytes32 statHash = keccak256(abi.encodePacked(statNames[i]));
            if (statHash == keccak256(abi.encodePacked("strength"))) {
                auto.baseStrength += 1; // Increase by 1 point
                 emit StateChanged(tokenId, "baseStrength", auto.baseStrength - 1, auto.baseStrength);
            } else if (statHash == keccak256(abi.encodePacked("agility"))) {
                auto.baseAgility += 1;
                emit StateChanged(tokenId, "baseAgility", auto.baseAgility - 1, auto.baseAgility);
            } else if (statHash == keccak256(abi.encodePacked("intelligence"))) {
                auto.baseIntelligence += 1;
                emit StateChanged(tokenId, "baseIntelligence", auto.baseIntelligence - 1, auto.baseIntelligence);
            }
        }
         emit AutomatonUpgraded(tokenId, auto.level, auto.upgradeCount); // Or a specific event for stat upgrade
    }

    /**
     * @dev Allows an Automaton owner to spend resources to increase the agent's level cap or other progression limits.
     * @param tokenId The ID of the Automaton.
     */
    function upgradeLevelCap(uint256 tokenId) public whenNotPaused onlyAutomatonOwnerOrApproved(tokenId) {
         Automaton storage auto = _automata[tokenId];
         address owner = ownerOf(tokenId);

        uint256 requiredResources = getResourcesRequiredForUpgrade(auto.upgradeCount);
        require(_resourceBalances[owner] >= requiredResources, "Not enough resources for upgrade");

        _resourceBalances[owner] = Math.max(0, _resourceBalances[owner] - requiredResources);
        auto.upgradeCount += 1;
        // Could also increase max level or cap on stats here
        auto.level += 1; // For simplicity, let this directly increase level too

        emit AutomatonUpgraded(tokenId, auto.level, auto.upgradeCount);
        emit StateChanged(tokenId, "level", auto.level - 1, auto.level); // Emit level change specifically
    }


    // --- External Influence Functions ---

    /**
     * @dev Callable by the trusted oracle to inject a new Aetheric Event.
     * This event influences agent stats dynamically via `getAutomatonStatsEffective`.
     * @param eventId A unique identifier for the event.
     * @param eventEffectMagnitude The magnitude of the event's effect (e.g., 110 for +10%, 90 for -10%).
     * @param duration How long the event lasts from the current block timestamp (in seconds).
     */
    function receiveAethericEvent(bytes32 eventId, uint256 eventEffectMagnitude, uint256 duration) public onlyOracle {
        _currentAethericEvent = AethericEvent({
            eventId: eventId,
            effectMagnitude: eventEffectMagnitude,
            duration: block.timestamp + duration
        });
        emit AethericEventReceived(eventId, eventEffectMagnitude, duration, block.timestamp);
    }

    /**
     * @dev Callable by the trusted keeper network to trigger maintenance checks.
     * This function handles time-dependent processes for all agents.
     * Note: In a real-world scenario with many agents, this might need pagination
     * or processing a queue to avoid hitting gas limits. This implementation
     * primarily updates the global last maintenance time and relies on dynamic
     * calculations in view/action functions.
     */
    function triggerMaintenance() public onlyKeeper {
        // This simple version primarily updates the last global maintenance time.
        // Dynamic state changes (energy recovery, health decay) are applied
        // on demand in relevant functions (`explore`, `rest`, `duel`, `getAutomatonState`, etc.)
        // by comparing current time to last action time, rest start time, or last maintenance time.

        _lastGlobalMaintenanceTime = block.timestamp;

        // More complex logic could iterate through a list of agents needing maintenance
        // (e.g., those that haven't acted in a long time, those with ongoing status effects)
        // but this must be carefully designed to be gas-efficient for a large number of tokens.
        // Example: process a small batch from a queue or a list of "dirty" agents.

        emit MaintenanceTriggered(block.timestamp);
    }


    // --- Resource Management Functions ---

    /**
     * @dev Awards resources to a specific owner. Intended for internal game logic or admin.
     * @param amount The amount of resources to distribute.
     * (Note: Public for simplicity in example, could be internal or restricted)
     */
    function distributeResources(uint256 amount) public whenNotPaused {
         address owner = msg.sender; // Distribute to the caller
        _resourceBalances[owner] += amount;
        emit ResourcesDistributed(owner, amount);
    }

    /**
     * @dev Allows an owner to transfer their resources to another address.
     * @param recipient The address to receive the resources.
     * @param amount The amount of resources to transfer.
     */
    function transferResources(address recipient, uint256 amount) public whenNotPaused {
        require(recipient != address(0), "Cannot transfer to zero address");
        require(_resourceBalances[msg.sender] >= amount, "Not enough resources");

        _resourceBalances[msg.sender] = Math.max(0, _resourceBalances[msg.sender] - amount);
        _resourceBalances[recipient] += amount;

        emit ResourcesDistributed(recipient, amount); // Reuse event, maybe add Transfer event specifically
    }

    // --- View & Query Functions ---

    /**
     * @dev Gets the full state struct for an Automaton.
     * Applies pending time-based state changes (energy recovery, health decay) before returning.
     * @param tokenId The ID of the Automaton.
     * @return The Automaton struct.
     */
    function getAutomatonState(uint256 tokenId) public view returns (Automaton memory) {
        require(_exists(tokenId), "Automaton does not exist");
        Automaton memory auto = _automata[tokenId];

        // Apply energy recovery dynamically on query/access if resting
        if (auto.isResting) {
             uint256 elapsedHours = (block.timestamp - auto.energyRecoveryStartTime) / 1 hours;
             uint256 recoveredEnergy = elapsedHours * REST_ENERGY_PER_HOUR;
             auto.currentEnergy = Math.min(100, auto.currentEnergy + recoveredEnergy); // Assume max 100 energy
             // Note: This view doesn't persist the change. The change is applied and persisted
             // when the agent performs a non-rest action, or when rest is called again.
             // A true simulation might need a queue or state update on access, which is complex.
        }
        // Could also apply health decay or other time-based effects here if implemented

        return auto;
    }

    /**
     * @dev Calculates and returns the effective stats of an Automaton, including
     * base stats, level bonus, and current Aetheric Event modifiers.
     * @param tokenId The ID of the Automaton.
     * @return Struct containing effective stats.
     */
    function getAutomatonStatsEffective(uint256 tokenId) public view returns (struct {uint256 strength; uint256 agility; uint256 intelligence;} effectiveStats) {
        require(_exists(tokenId), "Automaton does not exist");
        Automaton storage auto = _automata[tokenId];

        // Base stats + level bonus (example: +2 per stat per level)
        uint256 levelBonus = auto.level * 2;
        uint256 effectiveStr = auto.baseStrength + levelBonus;
        uint256 effectiveAgi = auto.baseAgility + levelBonus;
        uint256 effectiveInt = auto.baseIntelligence + levelBonus;

        // Apply Aetheric Event modifier if active
        if (block.timestamp < _currentAethericEvent.duration) {
            // Example: Event affects all stats proportionally to magnitude
            uint256 modifier = _currentAethericEvent.effectMagnitude; // e.g., 110 for +10%
            effectiveStr = (effectiveStr * modifier) / 100;
            effectiveAgi = (effectiveAgi * modifier) / 100;
            effectiveInt = (effectiveInt * modifier) / 100;

            // More complex logic could check eventId to apply specific effects
            // if (_currentAethericEvent.eventId == keccak256("cosmic_radiation")) {
            //     effectiveInt = (effectiveInt * 120) / 100; // +20% Int
            // }
        }

        effectiveStats.strength = effectiveStr;
        effectiveStats.agility = effectiveAgi;
        effectiveStats.intelligence = effectiveInt;

        return effectiveStats;
    }

     /**
     * @dev Gets the details of the current Aetheric Event.
     * @return AethericEvent struct.
     */
    function getAethericEvent() public view returns (AethericEvent memory) {
        return _currentAethericEvent;
    }

    /**
     * @dev Gets the current reputation score of an Automaton.
     * @param tokenId The ID of the Automaton.
     * @return The reputation score.
     */
    function getAutomatonReputation(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "Automaton does not exist");
        return _automata[tokenId].reputation;
    }

     /**
     * @dev Gets the resource balance for a given address.
     * @param owner The address to check.
     * @return The resource balance.
     */
    function getResourceBalance(address owner) public view returns (uint256) {
        return _resourceBalances[owner];
    }

    /**
     * @dev Gets the total number of Automata minted.
     * @return The total count.
     */
    function getAutomatonCount() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /**
     * @dev Checks if an Automaton is ready to perform another action based on its cooldown.
     * @param tokenId The ID of the Automaton.
     * @return True if ready, false otherwise.
     */
    function isActionReady(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "Automaton does not exist");
        return _automata[tokenId].lastActionTime + ACTION_COOLDOWN <= block.timestamp;
    }

    /**
     * @dev Returns the URI for the token metadata.
     * This should ideally point to a service that generates dynamic JSON based on on-chain state.
     * @param tokenId The ID of the Automaton.
     * @return The metadata URI.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // Construct the dynamic URI, passing the tokenId.
        // A separate service (e.g., Node.js server, IPFS gateway with dynamic content)
        // would listen for requests to this URI and fetch the on-chain state
        // using `getAutomatonState` and `getAutomatonStatsEffective` via a blockchain node,
        // then format it into an ERC721 metadata JSON.
        string memory base = _baseTokenURI;
        if (bytes(base).length == 0) {
            return "";
        }
        return string(abi.encodePacked(base, Strings.toString(tokenId)));
    }

    /**
     * @dev Calculates the XP required to reach the next level.
     * @param currentLevel The current level of the Automaton.
     * @return The required XP.
     */
    function getRequiredXPForNextLevel(uint256 currentLevel) public pure returns (uint256) {
        // Example simple scaling: Level^2 * 100
        return currentLevel * currentLevel * 100;
    }

     /**
     * @dev Calculates the resources required for the next level cap/stat upgrade.
     * @param currentUpgradeCount The number of times the agent has been upgraded this way.
     * @return The required resources.
     */
    function getResourcesRequiredForUpgrade(uint256 currentUpgradeCount) public pure returns (uint256) {
        // Example simple scaling: (UpgradeCount + 1) * 50 resources
        return (currentUpgradeCount + 1) * 50;
    }

     /**
     * @dev Calculates the current energy recovery rate per hour for an Automaton.
     * @param tokenId The ID of the Automaton.
     * @return The energy recovery rate per hour.
     */
    function getEnergyRecoveryRate(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "Automaton does not exist");
         Automaton storage auto = _automata[tokenId];
         if (auto.isResting) {
             // Example: Rest recovers a base amount per hour, potentially boosted by Intelligence
             return REST_ENERGY_PER_HOUR + (auto.baseIntelligence / 5);
         } else {
             return 0; // No passive recovery when not resting
         }
    }

    /**
     * @dev Calculates the current health recovery rate per hour for an Automaton.
     * @param tokenId The ID of the Automaton.
     * @return The health recovery rate per hour.
     */
     function getHealthRecoveryRate(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "Automaton does not exist");
         // Example: Health recovers passively very slowly, maybe boosted by a status effect or item
         return 5; // Example: 5 health per hour passively
         // Could add logic for specific items or states
     }


    // --- Admin Functions ---

    /**
     * @dev See {Pausable-pause}.
     * Restricts actions that change agent state or minting.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev See {Pausable-unpause}.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Sets the base URI for tokenURI.
     * @param baseURI The new base URI.
     */
    function setBaseURI(string calldata baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * @dev Sets the address of the trusted Oracle.
     * @param oracleAddress The new oracle address.
     */
    function setOracleAddress(address oracleAddress) public onlyOwner {
        require(oracleAddress != address(0), "Oracle address cannot be zero");
        _oracleAddress = oracleAddress;
    }

    /**
     * @dev Sets the address of the trusted Keeper network caller.
     * @param keeperAddress The new keeper address.
     */
    function setKeeperAddress(address keeperAddress) public onlyOwner {
        require(keeperAddress != address(0), "Keeper address cannot be zero");
        _keeperAddress = keeperAddress;
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Internal function to check if an Automaton can level up and apply the level increase.
     * @param tokenId The ID of the Automaton.
     */
    function _checkLevelUp(uint256 tokenId) internal {
         Automaton storage auto = _automata[tokenId];
         uint256 requiredXP = getRequiredXPForNextLevel(auto.level);

        while (auto.xp >= requiredXP) {
            auto.level += 1;
            // XP carries over
            auto.xp -= requiredXP;
             emit StateChanged(tokenId, "level", auto.level - 1, auto.level);
             emit StateChanged(tokenId, "xp", auto.xp + requiredXP, auto.xp);
            requiredXP = getRequiredXPForNextLevel(auto.level); // Calculate next level's requirement
             emit AutomatonUpgraded(tokenId, auto.level, auto.upgradeCount); // Use general upgrade event for level up
        }
    }

    /**
     * @dev Applies accumulated energy recovery to an Automaton if it was resting.
     * Updates recovery start time.
     * @param tokenId The ID of the Automaton.
     */
     function _applyEnergyRecovery(uint256 tokenId) internal {
        Automaton storage auto = _automata[tokenId];
        if (auto.isResting && auto.currentEnergy < 100) { // Only recover if resting and not full
             uint256 elapsedHours = (block.timestamp - auto.energyRecoveryStartTime) / 1 hours;
             if (elapsedHours > 0) {
                 uint256 recoveryRate = getEnergyRecoveryRate(tokenId); // Get dynamic rate
                 uint256 recoveredEnergy = elapsedHours * recoveryRate;
                 uint256 oldEnergy = auto.currentEnergy;
                 auto.currentEnergy = Math.min(100, auto.currentEnergy + recoveredEnergy); // Assume max 100 energy
                 auto.energyRecoveryStartTime = block.timestamp; // Reset recovery start time

                 if (oldEnergy != auto.currentEnergy) {
                     emit StateChanged(tokenId, "energy", oldEnergy, auto.currentEnergy);
                 }
             }
        }
     }

    /**
     * @dev Internal helper to calculate potential damage in a duel.
     * Uses effective stats.
     * @param attackerTokenId The ID of the attacking Automaton.
     * @param defenderTokenId The ID of the defending Automaton.
     * @return The calculated damage.
     */
    function calculateDamage(uint256 attackerTokenId, uint256 defenderTokenId) internal view returns (uint256) {
        struct {uint256 strength; uint256 agility; uint256 intelligence;} attackerStats = getAutomatonStatsEffective(attackerTokenId);
        struct {uint256 strength; uint256 agility; uint256 intelligence;} defenderStats = getAutomatonStatsEffective(defenderTokenId);

        // Simplified damage formula: Attacker Str + Attacker Agi/2 - Defender Agi/2
        uint256 attackPower = attackerStats.strength + (attackerStats.agility / 2);
        uint256 defensePower = defenderStats.agility / 2;

        return Math.max(0, attackPower - defensePower); // Damage cannot be negative
    }

     // --- Overrides ---

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
}
```