Okay, let's design a smart contract that combines elements of on-chain gaming, dynamic state based on external randomness (Chainlink VRF), and NFT ownership, creating a unique, interactive experience – a "Quantum Maze Explorer".

This contract will represent a multi-dimensional maze where players navigate using NFT avatars. The maze's structure and events will dynamically change based on "Quantum Shifts" triggered by on-chain randomness. Players will have stats, find items, face challenges, and attempt to reach a special "Phase Transition" state.

**Concept:** Quantum Maze Explorer
**Core Mechanics:**
1.  **NFT Avatars:** Players mint an ERC721 NFT representing their explorer.
2.  **Dynamic Maze:** The maze is a set of locations. The available paths between locations and the events within them are influenced by a global "Quantum Shift State".
3.  **Quantum Shifts:** Periodically, or triggered by game events, the maze undergoes a quantum shift. This relies on Verifiable Random Functions (VRF) to ensure unpredictable changes.
4.  **Player State:** Avatars track player location, health, energy, inventory, and potentially stats like "Quantum Resonance".
5.  **Exploration:** Players move between locations. Movement costs energy.
6.  **Location Events:** Entering a new location might trigger events like finding items, encountering challenges, or discovering secrets, influenced by the current Quantum Shift State.
7.  **Challenges:** Simple on-chain challenges (e.g., stat check, item consumption).
8.  **Progression:** Players can find/use items, restore energy/health, and potentially upgrade stats.
9.  **Goal:** The ultimate goal is to find a specific location and attempt a "Phase Transition" under the right conditions, which might require specific items, stats, and the correct Quantum Shift State.

---

**Outline:**

1.  **Imports:** ERC721, Ownable, Chainlink VRF interfaces.
2.  **Errors:** Custom error definitions.
3.  **Events:** Signify important actions (Mint, Move, Shift, Event, Item, Challenge, Transition).
4.  **Enums & Structs:**
    *   `MazeShiftState`: Enum for different global quantum states.
    *   `LocationType`: Enum for different types of locations (Start, Standard, Rest, Challenge, Exit).
    *   `ItemType`: Enum for different types of items.
    *   `ChallengeType`: Enum for different types of challenges.
    *   `Location`: Struct for maze locations (type, potential exits, event configuration, current state).
    *   `PlayerState`: Struct for player data (location, health, energy, resonance, inventory mapping).
5.  **State Variables:**
    *   ERC721 related state.
    *   VRF related state (coordinator, key hash, subscription ID, request IDs, randomness).
    *   Owner address (via Ownable).
    *   `mazeLocations`: Array of `Location` structs.
    *   `playerStates`: Mapping from tokenId to `PlayerState`.
    *   `currentMazeShiftState`: The active `MazeShiftState`.
    *   Configuration parameters (energy costs, health recovery amounts, max stats, etc.).
    *   Mapping to track VRF request IDs to purposes (e.g., pending quantum shift).
6.  **Owner/Setup Functions:**
    *   `constructor`: Initializes ERC721, Ownable, and VRF.
    *   `initializeMazeLayout`: Sets up the initial `mazeLocations` array.
    *   `setLocationConfig`: Configures event probabilities and properties for locations.
    *   `defineItemType`: Defines properties for `ItemType`s (e.g., recovery amount).
    *   `setGameConfig`: Sets global parameters (costs, recovery, max stats).
    *   `requestNewQuantumShift` (Also triggered by game logic, but owner can force).
7.  **Player Functions:**
    *   `mintAvatar`: Mints a new NFT and initializes `PlayerState`.
    *   `moveToLocation`: Player attempts to move. Checks validity, costs energy, triggers event logic.
    *   `useInventoryItem`: Player uses an item from their inventory.
    *   `restAndRecover`: Player rests at a suitable location.
    *   `attuneToQuantumField`: Player attempts to gain a temporary buff based on the current shift state (costs energy, chance-based).
    *   `attemptPhaseTransition`: Player attempts the game's goal at a specific location/state.
8.  **VRF Callback Function:**
    *   `rawFulfillRandomWords`: Handles the randomness returned by VRF, updates `currentMazeShiftState`.
9.  **View Functions:**
    *   `getPlayerState`: Returns a player's current state.
    *   `getLocationDetails`: Returns details about a specific location.
    *   `getCurrentMazeShiftState`: Returns the active global state.
    *   `getValidExits`: Calculates and returns valid moves from a location based on the current shift state.
    *   `viewInventory`: Returns a player's inventory.
    *   Standard ERC721 view functions (`balanceOf`, `ownerOf`, `getApproved`, `isApprovedForAll`, `tokenOfOwnerByIndex`, `tokenByIndex`, `supportsInterface`). (7 functions)
10. **Internal Helper Functions:**
    *   `_isValidMove`: Checks if a move is valid given current location, destination, and shift state.
    *   `_triggerLocationEvent`: Handles the logic when a player enters a location.
    *   `_resolveChallenge`: Handles specific challenge types.
    *   `_modifyPlayerState`: Internal helper to update player stats/inventory safely.
    *   `_generatePseudoRandom`: Simple PRNG for internal game events if not using VRF for every micro-event (VRF is for the *shift*, not every step/event resolution).

---

**Function Summary (21+ unique functions + ERC721 Standard):**

1.  `constructor(address vrfCoordinatorV2, uint64 subscriptionId, bytes32 keyHash)`: Initializes the contract, setting up ERC721, Ownable, and linking to Chainlink VRF.
2.  `initializeMazeLayout(uint256 numLocations, uint256[][] potentialExits)`: (Owner) Sets the total number of locations and their *potential* connections. Does *not* define which exits are valid in a specific state.
3.  `setLocationConfig(uint256 locationId, LocationType locType, uint256[] eventConfig)`: (Owner) Configures properties and event parameters for a specific location. `eventConfig` could be probabilities or challenge types.
4.  `defineItemType(ItemType itemType, uint256 recoveryAmount, uint256 statBoost)`: (Owner) Defines the effects of different item types.
5.  `setGameConfig(uint256 moveEnergyCost, uint256 restHealthRecovery, uint256 maxHealth, uint256 maxEnergy, uint256 maxResonance)`: (Owner) Sets global game constants.
6.  `requestNewQuantumShift()`: (Owner or triggered by specific game logic) Requests a new random word from VRF to update the `currentMazeShiftState`. Costs LINK.
7.  `rawFulfillRandomWords(uint256 requestId, uint256[] randomWords)`: (Chainlink VRF Callback) Receives randomness and updates `currentMazeShiftState` based on the random number.
8.  `mintAvatar()`: Mints a new ERC721 token for the caller and initializes their `PlayerState` at the starting location with base stats.
9.  `moveToLocation(uint256 tokenId, uint256 destinationLocationId)`: Allows the owner of `tokenId` to attempt to move to `destinationLocationId`. Checks if the move is valid in the *current* `currentMazeShiftState`, if the player has enough energy, and then updates location and triggers event logic.
10. `useInventoryItem(uint256 tokenId, ItemType itemType)`: Allows the owner of `tokenId` to consume an item from their inventory to gain its effects.
11. `restAndRecover(uint256 tokenId)`: Allows the owner of `tokenId` to use the rest mechanic at their current location to recover health and energy.
12. `attuneToQuantumField(uint256 tokenId)`: Allows the owner of `tokenId` to spend energy to attempt to gain temporary buffs based on the `currentMazeShiftState`. Chance of success is involved.
13. `attemptPhaseTransition(uint256 tokenId)`: Allows the owner of `tokenId` to attempt to win or complete a phase of the game if they are at the designated exit location and meet specific conditions (e.g., required items, minimum stats, correct `currentMazeShiftState`).
14. `getPlayerState(uint256 tokenId)`: (View) Returns the detailed `PlayerState` struct for a given token ID.
15. `getLocationDetails(uint256 locationId)`: (View) Returns the configured details for a specific maze location.
16. `getCurrentMazeShiftState()`: (View) Returns the current global `MazeShiftState`.
17. `getValidExits(uint256 locationId)`: (View) Calculates and returns an array of location IDs that are valid destinations from `locationId` under the current `currentMazeShiftState`.
18. `viewInventory(uint256 tokenId)`: (View) Returns the items and counts in the player's inventory.
19. `burnAvatar(uint256 tokenId)`: Allows the owner to burn their avatar, potentially receiving some small reward or acknowledging they've left the maze permanently.
20. `resolveLocationEvent(uint256 tokenId, uint256 eventOutcomeSeed)`: (Internal/Helper, potentially callable by owner/trusted oracle in more complex scenarios) Handles the specific event triggered upon entering a location, based on the location config and current shift state. Uses `eventOutcomeSeed` (derived from VRF or block data) for pseudo-randomness within the event.
21. `_resolveChallenge(uint256 tokenId, ChallengeType challenge, uint256 challengeSeed)`: (Internal/Helper) Contains the logic for different challenge types, modifying player state based on stats, items, and randomness from `challengeSeed`.

**Plus Standard ERC721 Functions (adding at least 7 more public functions):**
22. `balanceOf(address owner)`
23. `ownerOf(uint256 tokenId)`
24. `getApproved(uint256 tokenId)`
25. `isApprovedForAll(address owner, address operator)`
26. `approve(address to, uint256 tokenId)`
27. `setApprovalForAll(address operator, bool approved)`
28. `transferFrom(address from, address to, uint256 tokenId)`
29. `safeTransferFrom(address from, address to, uint256 tokenId)`
30. `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`
31. `supportsInterface(bytes4 interfaceId)`

This list provides well over 20 functions, including core game logic, owner setup, VRF integration, and the standard ERC721 interface. The "Quantum Shift" mechanic driven by VRF and influencing dynamic maze structure and events provides the creative and advanced concept element.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

// Outline:
// 1. Imports: Standard libraries and Chainlink VRF.
// 2. Errors: Custom errors for game specific conditions.
// 3. Events: Announce key state changes and actions.
// 4. Enums & Structs: Define game elements and player state.
// 5. State Variables: Contract configuration, game state, player data, VRF setup.
// 6. Owner/Setup Functions: Initialize the game, configure maze and items.
// 7. Player Functions: Actions players can take (mint, move, use item, rest, attune, attempt goal).
// 8. VRF Callback: Handle random words from Chainlink.
// 9. View Functions: Retrieve game state and player information.
// 10. Internal Helpers: Core game logic (movement validation, event triggering, challenge resolution).
// 11. ERC721 Standard Functions: Included via inheritance and required overrides.

// Function Summary:
// - constructor(address vrfCoordinatorV2, uint64 subscriptionId, bytes32 keyHash): Initializes contract, VRF, ERC721.
// - initializeMazeLayout(uint256 numLocations, uint256[][] potentialExits): Owner sets maze size and potential connections.
// - setLocationConfig(uint256 locationId, LocationType locType, uint256[] eventConfig): Owner sets location properties and event triggers.
// - defineItemType(ItemType itemType, uint256 recoveryAmount, uint256 statBoost): Owner defines item effects.
// - setGameConfig(uint256 moveEnergyCost, uint256 restHealthRecovery, uint256 maxHealth, uint256 maxEnergy, uint256 maxResonance): Owner sets global game constants.
// - requestNewQuantumShift(): Owner or game logic requests VRF randomness for maze shift.
// - rawFulfillRandomWords(uint256 requestId, uint256[] randomWords): VRF callback - processes randomness, updates maze shift state.
// - mintAvatar(): Mints player NFT, initializes player state.
// - moveToLocation(uint256 tokenId, uint256 destinationLocationId): Player action - attempts to move.
// - useInventoryItem(uint256 tokenId, ItemType itemType): Player action - uses item.
// - restAndRecover(uint256 tokenId): Player action - recovers stats at rest location.
// - attuneToQuantumField(uint256 tokenId): Player action - attempts temporary buff based on shift state.
// - attemptPhaseTransition(uint256 tokenId): Player action - attempts game goal at exit.
// - burnAvatar(uint256 tokenId): Player action - burns NFT to exit the maze permanently.
// - getPlayerState(uint256 tokenId): View - retrieve player's state.
// - getLocationDetails(uint256 locationId): View - retrieve location configuration.
// - getCurrentMazeShiftState(): View - retrieve current global maze shift state.
// - getValidExits(uint256 locationId): View - calculate possible moves from location in current shift state.
// - viewInventory(uint256 tokenId): View - retrieve player's inventory.
// - resolveLocationEvent(uint256 tokenId, uint256 eventOutcomeSeed): Internal - handles event logic on location entry.
// - _resolveChallenge(uint256 tokenId, ChallengeType challenge, uint256 challengeSeed): Internal - handles specific challenge outcomes.
// - Plus 10+ standard ERC721 functions (balanceOf, ownerOf, transferFrom, approve, etc.) via inheritance.

contract QuantumMazeExplorer is ERC721Burnable, Ownable, VRFConsumerBaseV2 {

    // --- Errors ---
    error PlayerDoesNotExist();
    error LocationDoesNotExist();
    error InvalidMove();
    error NotEnoughEnergy();
    error LocationNotSuitableForRest();
    error ItemNotAvailableOrUsable();
    error NotAtExitLocation();
    error PhaseTransitionConditionsNotMet();
    error MazeNotInitialized();
    error NoActiveEvent();
    error VRFRequestFailed();

    // --- Events ---
    event AvatarMinted(uint256 indexed tokenId, address indexed playerAddress, uint256 initialLocation);
    event PlayerMoved(uint256 indexed tokenId, uint256 fromLocationId, uint256 toLocationId);
    event QuantumShiftRequested(uint256 indexed requestId, uint256 subscriptionId, bytes32 keyHash);
    event QuantumShiftOccurred(MazeShiftState newShiftState, uint256 randomness);
    event LocationEventTriggered(uint256 indexed tokenId, uint256 indexed locationId, uint256 eventSeed);
    event ItemAcquired(uint256 indexed tokenId, ItemType itemType, uint256 amount);
    event ItemUsed(uint256 indexed tokenId, ItemType itemType);
    event ChallengeResolved(uint256 indexed tokenId, ChallengeType challengeType, bool success);
    event StatsRecovered(uint256 indexed tokenId, uint256 healthRecovered, uint256 energyRecovered);
    event AttunementAttempt(uint256 indexed tokenId, MazeShiftState shiftState, bool success, uint256 resonanceBoost);
    event PhaseTransitionAttempt(uint256 indexed tokenId, bool success);

    // --- Enums ---
    enum MazeShiftState {
        Entangled,    // Paths might be unpredictable, events chaotic
        Decoherent,   // More stable paths, events rarer
        Resonant,     // Specific paths open, certain events more likely, attunement is strong
        Fluctuating   // Rapidly changing path availability, unique transient events
    }

    enum LocationType {
        Uninitialized,
        Start,
        Standard,
        RestNode,       // Allows resting
        ChallengeGate,  // Often triggers a challenge
        NexusPoint,     // Potentially links multiple sections, might trigger shift
        PhaseExit       // Location for attempting phase transition
    }

    enum ItemType {
        None,
        HealthCrystal, // Recovers health
        EnergyCell,    // Recovers energy
        ResonanceAmplifier, // Boosts resonance temporarily
        PhaseKey       // Required for phase transition
    }

    enum ChallengeType {
        None,
        CombatEncounter, // Requires health/resonance check
        EnergyDrainPuzzle, // Requires energy consumption/check
        ResonanceAlignment // Requires resonance check
    }

    // --- Structs ---
    struct Location {
        LocationType locType;
        uint256[] potentialExits; // List of location IDs this location *could* connect to
        // Event config: Could be probabilities, specific challenge IDs, required resonance, etc.
        // Using a simple array for demonstration, real game needs more structured config
        uint256[] eventConfig;
        // Dynamic state if needed per location (e.g., boss alive, door locked)
        // bool locked;
    }

    struct PlayerState {
        uint256 locationId;
        uint256 health;
        uint256 energy;
        uint256 resonance; // Stat relevant to quantum mechanics / challenges
        mapping(ItemType => uint256) inventory;
        bool exists; // Flag to check if player data is initialized
    }

    // --- State Variables ---

    // VRF
    VRFCoordinatorV2Interface COORDINATOR;
    bytes32 private immutable i_keyHash;
    uint64 private immutable i_subscriptionId;
    mapping(uint256 => uint256) public s_requestIdToTokenId; // Track which request belongs to which action/player if needed per action

    // Game State
    Location[] public mazeLocations;
    mapping(uint256 => PlayerState) private playerStates; // TokenId => PlayerState
    MazeShiftState public currentMazeShiftState = MazeShiftState.Entangled; // Initial state

    // Configuration (Owner settable)
    uint256 public moveEnergyCost = 5;
    uint256 public restHealthRecovery = 20;
    uint256 public restEnergyRecovery = 20;
    uint256 public maxHealth = 100;
    uint256 public maxEnergy = 100;
    uint256 public maxResonance = 50;
    uint256 public initialHealth = 100;
    uint256 public initialEnergy = 100;
    uint256 public initialResonance = 10;
    uint256 public startLocationId = 0; // Assuming location 0 is the start

    // Item Definitions (Owner settable)
    struct ItemProperties {
        uint256 recoveryAmount; // For Health/Energy
        uint256 statBoost;      // For Resonance/temp buffs
        bool consumable;        // Can it be consumed?
        bool requiredForPhaseTransition; // Is this the PhaseKey?
    }
    mapping(ItemType => ItemProperties) public itemDefinitions;

    // --- Constructor ---
    constructor(
        address vrfCoordinatorV2,
        uint64 subscriptionId,
        bytes32 keyHash
    ) ERC721("QuantumMazeExplorer", "QME") Ownable(msg.sender) VRFConsumerBaseV2(vrfCoordinatorV2) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_keyHash = keyHash;
        i_subscriptionId = subscriptionId;
    }

    // --- Owner/Setup Functions ---

    /// @notice Initializes the basic layout of the maze. Can only be called once.
    /// @param numLocations The total number of locations in the maze.
    /// @param potentialExits An array where each element is an array of location IDs reachable from the corresponding index location.
    function initializeMazeLayout(uint256 numLocations, uint256[][] calldata potentialExits) external onlyOwner {
        require(mazeLocations.length == 0, "Maze already initialized");
        require(numLocations > 0, "Must have at least one location");
        require(potentialExits.length == numLocations, "Potential exits must match num locations");

        mazeLocations.length = numLocations;
        for (uint256 i = 0; i < numLocations; i++) {
            mazeLocations[i].locType = LocationType.Standard; // Default type
            mazeLocations[i].potentialExits = potentialExits[i];
            // Default empty event config
            // mazeLocations[i].eventConfig = new uint256[](0);
        }
        mazeLocations[startLocationId].locType = LocationType.Start;
        // Set a default PhaseExit location if numLocations allows, requires separate config
    }

    /// @notice Sets the type and event configuration for a specific location.
    /// @param locationId The ID of the location to configure.
    /// @param locType The type of the location.
    /// @param eventConfig Specific parameters for events at this location (interpretation depends on locType/challengeType).
    function setLocationConfig(uint256 locationId, LocationType locType, uint256[] calldata eventConfig) external onlyOwner {
        if (locationId >= mazeLocations.length || mazeLocations.length == 0) revert LocationDoesNotExist();
        mazeLocations[locationId].locType = locType;
        mazeLocations[locationId].eventConfig = eventConfig; // Store event parameters
    }

    /// @notice Defines the properties of an item type.
    /// @param itemType The enum value for the item.
    /// @param recoveryAmount The health/energy recovery provided (0 if not applicable).
    /// @param statBoost The temporary or permanent stat boost provided (0 if not applicable).
    /// @param consumable If the item is consumed on use.
    /// @param requiredForPhaseTransition If this item is needed for the game goal.
    function defineItemType(ItemType itemType, uint256 recoveryAmount, uint256 statBoost, bool consumable, bool requiredForPhaseTransition) external onlyOwner {
         // Basic validation for itemType != None
        itemDefinitions[itemType] = ItemProperties(recoveryAmount, statBoost, consumable, requiredForPhaseTransition);
    }

    /// @notice Sets global game configuration parameters.
    function setGameConfig(uint256 _moveEnergyCost, uint256 _restHealthRecovery, uint256 _restEnergyRecovery, uint256 _maxHealth, uint256 _maxEnergy, uint256 _maxResonance) external onlyOwner {
        moveEnergyCost = _moveEnergyCost;
        restHealthRecovery = _restHealthRecovery;
        restEnergyRecovery = _restEnergyRecovery;
        maxHealth = _maxHealth;
        maxEnergy = _maxEnergy;
        maxResonance = _maxResonance;
    }

    /// @notice Requests a new Quantum Shift via Chainlink VRF. Can be triggered by owner or game logic.
    /// @dev Requires funding the VRF subscription with LINK.
    function requestNewQuantumShift() public onlyOwner returns (uint256 requestId) {
         // In a real game, this might be triggered by a timer or specific player actions.
         // For simplicity, make it onlyOwner or add specific game-triggering logic.
        uint32 numWords = 1;
        requestId = COORDINATOR.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            getRequestConfirmations(), // Standard confirmations
            getCallbackGasLimit(),   // Standard gas limit
            numWords
        );
        // s_requestIdToTokenId[requestId] = 0; // Or some indicator it's a global shift
        emit QuantumShiftRequested(requestId, i_subscriptionId, i_keyHash);
        return requestId;
    }

    // --- VRF Callback ---

    /// @notice Chainlink VRF callback function. Processes the random word to update the maze shift state.
    /// @param requestId The ID of the VRF request.
    /// @param randomWords The array of random words returned by VRF.
    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        // require(s_requestIdToTokenId[requestId] != 0, "Request ID not recognized"); // Check if this was our request
        // delete s_requestIdToTokenId[requestId]; // Clean up request ID

        uint256 randomness = randomWords[0];
        uint256 numShiftStates = uint256(type(MazeShiftState).max) + 1;
        MazeShiftState newShiftState = MazeShiftState(randomness % numShiftStates);
        currentMazeShiftState = newShiftState;

        emit QuantumShiftOccurred(newShiftState, randomness);
    }

    // --- Player Functions ---

    /// @notice Mints a new Explorer NFT and initializes the player's state.
    function mintAvatar() external {
        uint256 newItemId = totalSupply() + 1; // Simple sequential token ID
        _mint(msg.sender, newItemId);

        PlayerState storage newPlayer = playerStates[newItemId];
        require(!newPlayer.exists, "Player already exists"); // Should not happen with sequential IDs, but good check
        newPlayer.exists = true;
        newPlayer.locationId = startLocationId;
        newPlayer.health = initialHealth;
        newPlayer.energy = initialEnergy;
        newPlayer.resonance = initialResonance;
        // Inventory starts empty

        emit AvatarMinted(newItemId, msg.sender, startLocationId);
    }

    /// @notice Allows a player to move their avatar to an adjacent location if valid.
    /// @param tokenId The ID of the player's avatar NFT.
    /// @param destinationLocationId The ID of the location the player wants to move to.
    function moveToLocation(uint256 tokenId, uint256 destinationLocationId) external {
        require(ownerOf(tokenId) == msg.sender, "Not owner of token");
        PlayerState storage player = playerStates[tokenId];
        if (!player.exists) revert PlayerDoesNotExist();
        if (destinationLocationId >= mazeLocations.length || mazeLocations.length == 0) revert LocationDoesNotExist();
        if (player.energy < moveEnergyCost) revert NotEnoughEnergy();
        if (!_isValidMove(player.locationId, destinationLocationId, currentMazeShiftState)) revert InvalidMove();

        uint256 fromLocationId = player.locationId;
        player.locationId = destinationLocationId;
        player.energy -= moveEnergyCost;

        emit PlayerMoved(tokenId, fromLocationId, destinationLocationId);

        // --- Trigger Location Event Logic ---
        // Use a simple pseudo-random seed for event outcome for demonstration
        // In a real game, more robust randomness might be needed for critical events.
        // Example: use block.timestamp, block.number, tx.origin, etc. - BEWARE OF PREDICTABILITY
        // For better event randomness, one could request VRF per critical event,
        // but that adds latency and gas cost. A common pattern is using VRF for MAJOR
        // shifts/events and pseudo-randomness for minor, frequent ones.
        uint256 eventOutcomeSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, msg.sender, tokenId, player.locationId)));
        _triggerLocationEvent(tokenId, eventOutcomeSeed);
    }

     /// @notice Allows a player to use an item from their inventory.
     /// @param tokenId The ID of the player's avatar NFT.
     /// @param itemType The type of item to use.
    function useInventoryItem(uint256 tokenId, ItemType itemType) external {
        require(ownerOf(tokenId) == msg.sender, "Not owner of token");
        PlayerState storage player = playerStates[tokenId];
        if (!player.exists) revert PlayerDoesNotExist();
        if (itemType == ItemType.None) revert ItemNotAvailableOrUsable();

        if (player.inventory[itemType] == 0) revert ItemNotAvailableOrUsable();

        ItemProperties memory itemProps = itemDefinitions[itemType];
        require(itemProps.consumable, "Item is not consumable"); // Only consumable items can be 'used' this way

        player.inventory[itemType]--;

        // Apply effects
        player.health = min(player.health + itemProps.recoveryAmount, maxHealth);
        player.energy = min(player.energy + itemProps.recoveryAmount, maxEnergy); // Assuming recoveryAmount applies to both for simplicity
        player.resonance = min(player.resonance + itemProps.statBoost, maxResonance); // Assuming statBoost applies to resonance

        emit ItemUsed(tokenId, itemType);
    }

    /// @notice Allows a player to rest at a suitable location to recover stats.
    /// @param tokenId The ID of the player's avatar NFT.
    function restAndRecover(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Not owner of token");
        PlayerState storage player = playerStates[tokenId];
        if (!player.exists) revert PlayerDoesNotExist();

        if (player.locationId >= mazeLocations.length) revert LocationDoesNotExist();
        Location storage currentLocation = mazeLocations[player.locationId];
        if (currentLocation.locType != LocationType.RestNode) revert LocationNotSuitableForRest();

        uint256 healthRecovered = min(restHealthRecovery, maxHealth - player.health);
        uint256 energyRecovered = min(restEnergyRecovery, maxEnergy - player.energy);

        player.health += healthRecovered;
        player.energy += energyRecovered;

        emit StatsRecovered(tokenId, healthRecovered, energyRecovered);
    }

    /// @notice Allows a player to attempt to gain a temporary resonance boost based on the current quantum field state.
    /// @param tokenId The ID of the player's avatar NFT.
    function attuneToQuantumField(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Not owner of token");
        PlayerState storage player = playerStates[tokenId];
        if (!player.exists) revert PlayerDoesNotExist();
        if (player.energy < moveEnergyCost) revert NotEnoughEnergy(); // Costs energy to attune

        player.energy -= moveEnergyCost; // Cost

        uint256 attunementSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, msg.sender, tokenId, player.locationId, currentMazeShiftState)));
        uint256 successChance = 0;
        uint256 resonanceBoost = 0;

        // Attunement success and boost depends on the current shift state
        if (currentMazeShiftState == MazeShiftState.Resonant) {
            successChance = 80; // Higher chance in Resonant state
            resonanceBoost = 15;
        } else if (currentMazeShiftState == MazeShiftState.Fluctuating) {
            successChance = 50; // Medium chance
            resonanceBoost = 10;
        } else if (currentMazeShiftState == MazeShiftState.Entangled) {
            successChance = 30; // Lower chance, might be unpredictable
            resonanceBoost = 5;
        } else { // Decoherent
            successChance = 10; // Very low chance
            resonanceBoost = 2;
        }

        bool success = (attunementSeed % 100) < successChance;

        if (success) {
            player.resonance = min(player.resonance + resonanceBoost, maxResonance); // Simple boost
            emit AttunementAttempt(tokenId, currentMazeShiftState, true, resonanceBoost);
        } else {
            emit AttunementAttempt(tokenId, currentMazeShiftState, false, 0);
        }
    }

    /// @notice Allows a player to attempt to complete the game's goal (Phase Transition) at a specific location.
    /// @param tokenId The ID of the player's avatar NFT.
    function attemptPhaseTransition(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Not owner of token");
        PlayerState storage player = playerStates[tokenId];
        if (!player.exists) revert PlayerDoesNotExist();

        if (player.locationId >= mazeLocations.length) revert LocationDoesNotExist();
        Location storage currentLocation = mazeLocations[player.locationId];

        if (currentLocation.locType != LocationType.PhaseExit) revert NotAtExitLocation();

        // Define conditions for phase transition - example: Requires PhaseKey item, minimum resonance, and specific shift state
        ItemProperties memory phaseKeyProps = itemDefinitions[ItemType.PhaseKey];
        bool hasKey = player.inventory[ItemType.PhaseKey] > 0 && phaseKeyProps.requiredForPhaseTransition;
        bool highResonance = player.resonance >= maxResonance / 2; // Example threshold
        bool correctShiftState = currentMazeShiftState == MazeShiftState.Resonant; // Example required state

        if (hasKey && highResonance && correctShiftState) {
            // Success!
            // Consume the key
            player.inventory[ItemType.PhaseKey]--;
            // Player could be moved to a 'finished' state, burned, or transferred to a special contract
            // For simplicity, let's just mark them somehow or emit success.
            // In a real game, this is where win conditions are handled.
            // Example: Burn the NFT or transfer it to a 'Winner' contract.
            // _burn(tokenId); // Option 1: Burn
            // Option 2: Move to a 'won' location ID (needs mapping for this)
            // Option 3: Set a 'hasWon' flag in PlayerState (if keeping player state)
            // Let's just emit success for this example and let off-chain handle rewards/next steps.

            emit PhaseTransitionAttempt(tokenId, true);

            // Optional: Trigger another global event or reset maze
            // requestNewQuantumShift(); // Maybe attempting transition causes a shift
        } else {
            // Failed attempt
            // Penalize player?
            player.energy = player.energy > moveEnergyCost * 2 ? player.energy - moveEnergyCost * 2 : 0; // Lose energy on failure
            emit PhaseTransitionAttempt(tokenId, false);
        }
    }

     /// @notice Allows the owner to burn their avatar NFT.
     /// @param tokenId The ID of the player's avatar NFT.
    function burnAvatar(uint256 tokenId) public override {
        // Ensure owner is calling
        require(ownerOf(tokenId) == msg.sender, "Not owner of token");
        // Optionally, add conditions (e.g., cannot burn in a challenge)
        _burn(tokenId);
        // Optional: Delete player state data to save gas if state is no longer needed.
        // delete playerStates[tokenId]; // Note: This deletes the struct values, but the mapping key might still exist minimally.
                                       // Better to rely on the `exists` flag or check ownership.
        // Event for burn is already emitted by ERC721Burnable
    }


    // --- View Functions ---

    /// @notice Gets the current state of a player avatar.
    /// @param tokenId The ID of the player's avatar NFT.
    /// @return PlayerState struct.
    function getPlayerState(uint256 tokenId) external view returns (PlayerState memory) {
        if (ownerOf(tokenId) == address(0)) revert PlayerDoesNotExist(); // Check if NFT exists
        PlayerState storage player = playerStates[tokenId];
        if (!player.exists) revert PlayerDoesNotExist(); // Check if game state exists
        return player;
    }

    /// @notice Gets the details configured for a specific location.
    /// @param locationId The ID of the location.
    /// @return Location struct.
    function getLocationDetails(uint256 locationId) external view returns (Location memory) {
        if (locationId >= mazeLocations.length || mazeLocations.length == 0) revert LocationDoesNotExist();
        return mazeLocations[locationId];
    }

    /// @notice Gets the current global Quantum Shift State affecting the maze.
    /// @return The current MazeShiftState enum value.
    function getCurrentMazeShiftState() external view returns (MazeShiftState) {
        return currentMazeShiftState;
    }

    /// @notice Calculates the valid locations a player can move to from a given location based on the current maze shift state.
    /// @param locationId The starting location ID.
    /// @return An array of valid destination location IDs.
    function getValidExits(uint256 locationId) public view returns (uint256[] memory) {
        if (locationId >= mazeLocations.length || mazeLocations.length == 0) revert LocationDoesNotExist();
        Location storage currentLocation = mazeLocations[locationId];
        uint256[] memory potential = currentLocation.potentialExits;
        uint256[] memory valid = new uint256[](potential.length);
        uint256 validCount = 0;

        // Logic to determine valid exits based on currentMazeShiftState
        // This is a core "Quantum" mechanic - different states enable/disable paths
        for (uint256 i = 0; i < potential.length; i++) {
             // Example logic:
             // - Entangled: All potential exits are valid, but maybe chance of wrong destination (not implemented here)
             // - Decoherent: Only specific, stable exits are valid (e.g., even indices)
             // - Resonant: Specific "resonant" paths are open (e.g., require resonance >= threshold to see/use)
             // - Fluctuating: Paths change rapidly, maybe only one random path is open per location (hard to implement with just view)

            bool isValid = false;
            if (potential[i] >= mazeLocations.length) continue; // Ensure potential exit is a valid location ID

            if (currentMazeShiftState == MazeShiftState.Entangled) {
                isValid = true; // All potential paths are valid (in this simplified model)
            } else if (currentMazeShiftState == MazeShiftState.Decoherent) {
                 // Example: Only allow exits to locations with even IDs from locations with even IDs, or odd to odd.
                if ((locationId % 2 == potential[i] % 2)) {
                    isValid = true;
                }
            } else if (currentMazeShiftState == MazeShiftState.Resonant) {
                 // Example: Allow exits if the destination location ID matches a pattern or is in a specific list
                 // based on the source location AND the current state. Or requires player resonance.
                 // For simplicity, let's say certain predefined pairs are only valid in Resonant state.
                 // This would require pre-defining these pairs or more complex location data.
                 // Alternative simple example: Exit is valid if source + dest ID sum is even.
                 if ((locationId + potential[i]) % 2 == 0) {
                      isValid = true;
                 }
            } else if (currentMazeShiftState == MazeShiftState.Fluctuating) {
                 // Example: Very chaotic. Maybe only one specific exit is valid per location, determined by state + location ID
                 // This is complex to do deterministically and viewable. Simplification: random % potential.length is valid exit INDEX.
                 // Cannot easily implement true "fluctuating" paths predictably in a pure view function.
                 // Let's just use a simple rule: If the destination ID is prime (example), it's valid. (Requires isPrime helper)
                 // Or simpler: allow if (potential[i] % 3) == uint256(currentMazeShiftState) % 3;
                 if ((potential[i] % 3) == uint256(currentMazeShiftState) % 3) {
                     isValid = true;
                 }
            }

            if (isValid) {
                valid[validCount] = potential[i];
                validCount++;
            }
        }

        // Resize the array to fit actual valid exits
        uint256[] memory finalValid = new uint256[](validCount);
        for (uint256 i = 0; i < validCount; i++) {
            finalValid[i] = valid[i];
        }
        return finalValid;
    }

    /// @notice Gets the inventory of a player avatar.
    /// @param tokenId The ID of the player's avatar NFT.
    /// @return An array of ItemType and an array of corresponding counts.
    function viewInventory(uint256 tokenId) external view returns (ItemType[] memory, uint256[] memory) {
         if (ownerOf(tokenId) == address(0)) revert PlayerDoesNotExist();
         PlayerState storage player = playerStates[tokenId];
         if (!player.exists) revert PlayerDoesNotExist();

         // Get all possible ItemTypes (excluding None)
         uint256 numItemTypes = uint256(type(ItemType).max);
         ItemType[] memory ownedItemTypes = new ItemType[](numItemTypes);
         uint256[] memory ownedItemCounts = new uint256[](numItemTypes);
         uint256 ownedCount = 0;

         // Iterate through possible ItemTypes (requires knowing all enum values)
         // A practical way is to have an array of all valid ItemTypes managed by owner.
         // For this example, let's just check a few known types.
         // Better approach: Iterate through all enum values if possible, or require owner to list all valid types.
         // Solidity doesn't easily allow iterating enums. Let's assume a list of valid types is available or check known ones.

         // Example checking specific types:
         ItemType[] memory allKnownItemTypes = new ItemType[](4); // Hardcoded example size
         allKnownItemTypes[0] = ItemType.HealthCrystal;
         allKnownItemTypes[1] = ItemType.EnergyCell;
         allKnownItemTypes[2] = ItemType.ResonanceAmplifier;
         allKnownItemTypes[3] = ItemType.PhaseKey;


         for(uint256 i = 0; i < allKnownItemTypes.length; i++) {
             ItemType currentType = allKnownItemTypes[i];
             uint256 count = player.inventory[currentType];
             if (count > 0) {
                 ownedItemTypes[ownedCount] = currentType;
                 ownedItemCounts[ownedCount] = count;
                 ownedCount++;
             }
         }

         // Resize result arrays
         ItemType[] memory finalItemTypes = new ItemType[](ownedCount);
         uint256[] memory finalItemCounts = new uint256[](ownedCount);
         for(uint256 i = 0; i < ownedCount; i++) {
             finalItemTypes[i] = ownedItemTypes[i];
             finalItemCounts[i] = ownedItemCounts[i];
         }

         return (finalItemTypes, finalItemCounts);
    }


    // --- Internal Helper Functions ---

    /// @dev Checks if a move from current to destination is valid based on the current shift state.
    function _isValidMove(uint256 fromId, uint256 toId, MazeShiftState shiftState) internal view returns (bool) {
        if (fromId >= mazeLocations.length || toId >= mazeLocations.length || mazeLocations.length == 0) return false;

        uint256[] memory potential = mazeLocations[fromId].potentialExits;
        bool isPotentialExit = false;
        for (uint256 i = 0; i < potential.length; i++) {
            if (potential[i] == toId) {
                isPotentialExit = true;
                break;
            }
        }
        if (!isPotentialExit) return false;

        // Apply shift state logic - must match the getValidExits logic
         if (shiftState == MazeShiftState.Entangled) {
            return true; // All potential paths are valid
        } else if (shiftState == MazeShiftState.Decoherent) {
             return (fromId % 2 == toId % 2);
        } else if (shiftState == MazeShiftState.Resonant) {
             return (fromId + toId) % 2 == 0;
        } else if (shiftState == MazeShiftState.Fluctuating) {
            // Need to be careful about matching view function logic exactly
            // Using the same simple rule as in getValidExits for consistency
             return (toId % 3) == uint256(shiftState) % 3;
        }

        return false; // Should not reach here
    }


    /// @dev Triggers and handles the event that occurs upon entering a location.
    /// Uses eventOutcomeSeed for internal (pseudo-)randomness.
    function _triggerLocationEvent(uint256 tokenId, uint256 eventOutcomeSeed) internal {
        PlayerState storage player = playerStates[tokenId];
        Location storage currentLocation = mazeLocations[player.locationId];

        emit LocationEventTriggered(tokenId, player.locationId, eventOutcomeSeed);

        // Example Event Logic (simplified):
        // eventConfig could encode: [chance_of_event, type_of_event, param1, param2...]
        // eventConfig[0]: 0-100 chance threshold for *any* configured event
        // eventConfig[1]: ChallengeType or ItemType or SpecialEventCode

        if (currentLocation.eventConfig.length == 0) {
            // No events configured for this location
            return;
        }

        uint256 eventRoll = eventOutcomeSeed % 100; // Simple dice roll 0-99
        uint256 eventChanceThreshold = currentLocation.eventConfig[0]; // Assuming first element is chance threshold

        if (eventRoll < eventChanceThreshold) {
            // An event is triggered
            uint256 eventTypeOrId = currentLocation.eventConfig[1]; // Assuming second element is event type/ID

            if (eventTypeOrId == uint256(ChallengeType.CombatEncounter)) {
                _resolveChallenge(tokenId, ChallengeType.CombatEncounter, eventOutcomeSeed);
            } else if (eventTypeOrId == uint256(ItemType.HealthCrystal)) {
                 // Example: Find an item (assuming eventConfig[1] directly corresponds to an item type)
                 player.inventory[ItemType(eventTypeOrId)]++;
                 emit ItemAcquired(tokenId, ItemType(eventTypeOrId), 1);
            }
            // Add more event types here (e.g., Puzzle, Trap, FindSecretPassage, TriggerShift)
        }
    }


    /// @dev Resolves the outcome of a challenge for a player.
    /// Uses challengeSeed for internal (pseudo-)randomness within the challenge.
    function _resolveChallenge(uint256 tokenId, ChallengeType challenge, uint256 challengeSeed) internal {
         PlayerState storage player = playerStates[tokenId];
         bool success = false;
         uint256 randomFactor = challengeSeed % 10; // Simple factor 0-9

         if (challenge == ChallengeType.CombatEncounter) {
             // Example Combat: Player resonance + random vs a fixed difficulty + random
             uint256 playerScore = player.resonance + randomFactor;
             uint256 difficulty = 20; // Fixed difficulty example
             uint256 enemyScore = difficulty + (challengeSeed / 10 % 10); // Different random factor

             if (playerScore >= enemyScore) {
                 success = true;
                 // Reward: small health/energy gain, maybe item
                 player.health = min(player.health + 5, maxHealth);
                 player.energy = min(player.energy + 5, maxEnergy);
             } else {
                 // Penalty: health/energy loss
                 uint256 healthLoss = 10 + (challengeSeed % 5);
                 uint256 energyLoss = 10 + (challengeSeed % 5);
                 player.health = player.health > healthLoss ? player.health - healthLoss : 0;
                 player.energy = player.energy > energyLoss ? player.energy - energyLoss : 0;
             }
         } else if (challenge == ChallengeType.EnergyDrainPuzzle) {
             // Example Puzzle: Requires consuming energy, success based on resonance
             uint256 energyCost = 15; // Fixed cost
             if (player.energy >= energyCost) {
                 player.energy -= energyCost;
                 if (player.resonance + randomFactor >= 25) { // Resonance helps success
                     success = true;
                     // Reward: Maybe an item or access to a secret
                     player.inventory[ItemType.EnergyCell]++; // Find an energy cell
                     emit ItemAcquired(tokenId, ItemType.EnergyCell, 1);
                 } else {
                     // Failed puzzle: No reward
                 }
             } else {
                 // Not enough energy to attempt the puzzle
                 // This case might be handled before calling _resolveChallenge, or result in failure and penalty.
                 // Let's say failure and lose remaining energy
                 player.energy = 0;
             }
         }
         // Add more challenge types...

         emit ChallengeResolved(tokenId, challenge, success);

         // Check for player death
         if (player.health == 0) {
            // Handle player death: Burn NFT, move to start, etc.
            // For simplicity, let's just reset stats and move to start.
            player.locationId = startLocationId;
            player.health = initialHealth;
            player.energy = initialEnergy;
            player.resonance = initialResonance;
            // Clear inventory? Maybe not, penalty enough.
            emit PlayerMoved(tokenId, currentLocation.potentialExits[0], startLocationId); // Emit move to start
         }
    }


    /// @dev Simple helper for min function
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /// @dev Simple helper for max function
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }


    // --- Chainlink VRF V2 Configuration Overrides ---
    // Required overrides for VRFConsumerBaseV2

    // Minimum gas offered to the callback request.
    // Must be sufficient to execute the rawFulfillRandomWords function.
    function getCallbackGasLimit() internal pure returns (uint32) {
        return 250000; // Example value, adjust based on complexity of rawFulfillRandomWords
    }

    // Number of block confirmations to wait for the VRF request.
    function getRequestConfirmations() internal pure returns (uint16) {
        return 3; // Standard recommendation
    }

    // Max number of words in the randomness request.
    function getMaxRequestConfirmations() internal pure returns (uint32) {
        return 1; // We only need 1 word for the shift state
    }
}
```