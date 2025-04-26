Okay, this is a fun challenge! Let's design a smart contract around a concept that involves state transitions, time-based dynamics, access control beyond simple ownership, and interacts with hypothetical external data (like a simplified oracle).

We'll create a contract that manages "Digital Familiars" - unique, dynamic entities represented as NFTs. These familiars have stats (Energy, Mood, Health) that decay over time. Owners (or approved delegates) must interact with them to keep them healthy and happy, potentially triggering evolutions. External factors (simulated via an oracle) can also influence them.

This combines concepts like:
*   **Dynamic NFTs:** Metadata changes based on the Familiar's state.
*   **Time-Based Logic:** Stats decay, and growth/evolution depends on time and interaction frequency.
*   **State Machines:** Familiars transition between states (Healthy, Hungry, Sick, etc.) and stages (Egg, Child, Adult).
*   **Role-Based/Delegated Access:** Allowing specific addresses to perform care actions on behalf of the owner.
*   **Oracle Interaction (Simulated):** Incorporating external data's influence.

---

## Smart Contract: Digital Familiar Genesis

**Concept:** A dynamic NFT contract where unique "Familiars" have simulated stats and lifecycle stages influenced by owner interaction, time, and external conditions.

**Outline:**

1.  **Interfaces & Imports:** Necessary OpenZeppelin interfaces for ERC721 and ERC165, Ownable.
2.  **State Variables:** Mappings for NFT data, Familiar stats/state, configuration parameters, delegate approvals, total supply.
3.  **Enums:** Define possible Familiar Stages (Egg, Child, etc.) and States (Healthy, Hungry, Sick, etc.).
4.  **Structs:** Define the structure to hold all Familiar data. Define structures for configuration parameters (decay rates, evolution thresholds, costs).
5.  **Events:** Emit events for key actions (Mint, Transfer, Approval, State Change, Evolution, Interaction, Delegate Set, Config Update).
6.  **Modifiers:** Custom modifiers for access control (owner/approved, owner/delegate, owner/oracle).
7.  **Core ERC-721 Functions:** Standard functions required for ERC-721 compliance, plus a dynamic `tokenURI`.
8.  **Familiar Data Management:** Functions to mint, retrieve familiar data, and apply time-based decay.
9.  **Interaction Functions:** Functions for owners/delegates to interact (Feed, Play, Rest) affecting stats.
10. **Lifecycle Functions:** Functions to check and trigger state changes (Hungry, Sick) and stage evolution.
11. **Delegation Functions:** Functions to manage care delegates.
12. **Oracle Interaction (Simulated):** Functions to simulate external data influencing Familiars.
13. **Configuration Functions:** Owner-only functions to adjust contract parameters.
14. **Utility Functions:** Helper views.

**Function Summary (28 Functions):**

*   `constructor()`: Initializes the contract, setting owner and initial configs.
*   `supportsInterface(bytes4 interfaceId)`: ERC165 compliance.
*   `balanceOf(address owner)`: ERC721: Returns the number of familiars owned by an address.
*   `ownerOf(uint256 tokenId)`: ERC721: Returns the owner of a specific familiar.
*   `approve(address to, uint256 tokenId)`: ERC721: Approves an address to manage a specific familiar.
*   `getApproved(uint256 tokenId)`: ERC721: Gets the approved address for a specific familiar.
*   `setApprovalForAll(address operator, bool approved)`: ERC721: Sets approval for an operator for all familiars.
*   `isApprovedForAll(address owner, address operator)`: ERC721: Checks if an operator is approved for an owner.
*   `transferFrom(address from, address to, uint256 tokenId)`: ERC721: Transfers familiar ownership (checked).
*   `safeTransferFrom(address from, address to, uint256 tokenId)`: ERC721: Transfers familiar ownership, checking receiver is compatible (ERC721 standard overload).
*   `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: ERC721: Transfers familiar ownership with extra data (ERC721 standard overload).
*   `tokenURI(uint256 tokenId)`: ERC721: Returns a data URI containing dynamic JSON metadata reflecting the familiar's current state.
*   `mintFamiliar()`: Creates and issues a new familiar NFT to the caller. Initializes stats, trait, and stage (Egg).
*   `getFamiliarData(uint256 tokenId)`: View function to retrieve the full data struct for a familiar. Includes calculation of current stats factoring in decay.
*   `getFamiliarConfig()`: View function to retrieve current contract configuration parameters (decay rates, thresholds, costs).
*   `feedFamiliar(uint256 tokenId)`: Interacts with familiar: increases Hunger, potentially costs ETH. Requires owner or delegate. Applies decay first.
*   `playWithFamiliar(uint256 tokenId)`: Interacts with familiar: increases Mood/Energy, potentially costs ETH. Requires owner or delegate. Applies decay first.
*   `restFamiliar(uint256 tokenId)`: Interacts with familiar: increases Health/Energy, potentially costs ETH. Requires owner or delegate. Applies decay first.
*   `checkFamiliarState(uint256 tokenId)`: Function to update the familiar's `state` (Healthy, Hungry, Sick, etc.) based on its current stats and time decay since last interaction. Can be called by anyone to 'poke' the familiar.
*   `checkFamiliarEvolution(uint256 tokenId)`: Function to check if a familiar is ready to evolve based on Growth and time, and triggers evolution if so. Requires owner or delegate. Applies decay first.
*   `setCareDelegate(address delegate, bool approved)`: Allows owner to grant or revoke care delegate status for all their familiars.
*   `isCareDelegate(address owner, address delegate)`: View function to check if an address is a care delegate for an owner.
*   `feedFamiliarDelegated(address owner, uint256 tokenId)`: Allows a registered care delegate to feed a familiar owned by `owner`.
*   `updateGlobalMood(int256 newMoodValue)`: Simulated Oracle function - allows a designated address to update a global mood factor influencing familiars.
*   `getGlobalMood()`: View function for the current simulated global mood.
*   `setConfigDecayRates(uint256 energyDecayPerDay, uint256 moodDecayPerDay, uint256 hungerDecayPerDay, uint256 healthDecayPerDay)`: Owner-only: Sets the rate at which stats decay over time.
*   `setConfigEvolutionThresholds(uint252[] memory thresholds)`: Owner-only: Sets the growth points required for each evolution stage.
*   `setConfigInteractionCosts(uint256 feedCost, uint256 playCost, uint256 restCost)`: Owner-only: Sets the ETH cost required for interaction functions.
*   `withdrawContractBalance()`: Owner-only: Withdraws any ETH accumulated from interaction costs.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

// Outline:
// 1. Interfaces & Imports
// 2. State Variables
// 3. Enums
// 4. Structs
// 5. Events
// 6. Modifiers
// 7. Core ERC-721 Functions
// 8. Familiar Data Management
// 9. Interaction Functions
// 10. Lifecycle Functions
// 11. Delegation Functions
// 12. Oracle Interaction (Simulated)
// 13. Configuration Functions
// 14. Utility Functions

// Function Summary (28 Functions):
// constructor()
// supportsInterface(bytes4 interfaceId)
// balanceOf(address owner)
// ownerOf(uint256 tokenId)
// approve(address to, uint256 tokenId)
// getApproved(uint256 tokenId)
// setApprovalForAll(address operator, bool approved)
// isApprovedForAll(address owner, address operator)
// transferFrom(address from, address to, uint256 tokenId)
// safeTransferFrom(address from, address to, uint256 tokenId) (overload 1)
// safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) (overload 2)
// tokenURI(uint256 tokenId)
// mintFamiliar()
// getFamiliarData(uint256 tokenId)
// getFamiliarConfig()
// feedFamiliar(uint256 tokenId)
// playWithFamiliar(uint256 tokenId)
// restFamiliar(uint256 tokenId)
// checkFamiliarState(uint256 tokenId)
// checkFamiliarEvolution(uint256 tokenId)
// setCareDelegate(address delegate, bool approved)
// isCareDelegate(address owner, address delegate)
// feedFamiliarDelegated(address owner, uint256 tokenId)
// updateGlobalMood(int256 newMoodValue)
// getGlobalMood()
// setConfigDecayRates(...)
// setConfigEvolutionThresholds(...)
// setConfigInteractionCosts(...)
// withdrawContractBalance()

contract DigitalFamiliarGenesis is ERC165, IERC721, IERC721Metadata, Ownable {

    // --- State Variables ---

    // ERC721 core storage
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    uint256 private _tokenIdCounter;

    // Familiar specific data
    mapping(uint256 => FamiliarData) private _familiars;
    mapping(address => mapping(address => bool)) private _careDelegates; // owner => delegate => approved

    // Oracle simulation
    address public oracleAddress; // Address authorized to update global mood
    int256 private _globalMood; // Affects familiar mood decay/gain

    // Configuration parameters
    ConfigDecayRates public familiarDecayRates;
    uint255[] public familiarEvolutionThresholds; // Growth points needed for Stage 1, 2, 3...
    ConfigInteractionCosts public familiarInteractionCosts;

    // Constants (relative max stats for clarity)
    uint256 public constant MAX_STAT = 1000; // Max value for Energy, Mood, Hunger, Health
    uint256 public constant GROWTH_PER_DAY_BASE = 10; // Base growth per day regardless of interaction (passive)
    uint256 public constant TIME_UNIT = 1 days; // Use 1 day as the base unit for decay/growth calculations

    // --- Enums ---

    enum FamiliarStage {
        Egg,
        Child,
        Adult,
        Elder,
        Lost // Terminal stage if neglected
    }

    enum FamiliarState {
        Healthy,
        Hungry,
        Tired, // Low Energy
        Bored, // Low Mood
        Sick, // Low Health
        Depressed // Critically Low Mood/Energy
    }

    // --- Structs ---

    struct FamiliarData {
        uint16 energy;
        uint16 mood;
        uint16 hunger;
        uint16 health;
        uint252 growth; // Max growth fits in uint252 if thresholds allow
        FamiliarStage stage;
        FamiliarState state; // Determined dynamically or updated on interaction/checkState
        uint48 lastInteractionTime; // Store timestamp efficiently
        uint32 traitId; // Simple ID for a unique trait
    }

    struct ConfigDecayRates {
        uint256 energyDecayPerDay;
        uint256 moodDecayPerDay;
        uint256 hungerDecayPerDay;
        uint256 healthDecayPerDay;
    }

    struct ConfigInteractionCosts {
        uint256 feedCost;
        uint256 playCost;
        uint256 restCost;
    }

    // --- Events ---

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event FamiliarMinted(address indexed owner, uint256 indexed tokenId, uint32 traitId);
    event FamiliarStateChanged(uint256 indexed tokenId, FamiliarState newState, FamiliarState oldState);
    event FamiliarEvolution(uint256 indexed tokenId, FamiliarStage newStage, FamiliarStage oldStage);
    event FamiliarInteracted(uint256 indexed tokenId, string interactionType, uint256 cost);
    event CareDelegateSet(address indexed owner, address indexed delegate, bool approved);
    event GlobalMoodUpdated(int256 newMoodValue);
    event ConfigUpdated(string configName);

    // --- Modifiers ---

    modifier onlyFamiliarOwnerOrApproved(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner or approved");
        _;
    }

     modifier onlyFamiliarOwnerOrDelegate(uint256 tokenId) {
        address owner = _owners[tokenId];
        require(msg.sender == owner || _careDelegates[owner][msg.sender], "Not owner or delegate");
        _;
    }

     modifier onlyOracle() {
         require(msg.sender == oracleAddress, "Only authorized oracle");
         _;
     }

    // --- Constructor ---

    constructor(address _oracleAddress) Ownable(msg.sender) {
        _tokenIdCounter = 0;
        oracleAddress = _oracleAddress;
        _globalMood = 50; // Initial neutral global mood

        // Set initial default configurations
        familiarDecayRates = ConfigDecayRates(50, 40, 60, 30); // Decay per day
        familiarEvolutionThresholds = [100, 500, 2000, 5000]; // Growth for Child, Adult, Elder, etc.
        familiarInteractionCosts = ConfigInteractionCosts(0.001 ether, 0.0008 ether, 0.0005 ether); // Example costs
    }

    // --- Core ERC-721 Functions ---

    // ERC165 compliance
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Metadata).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "ERC721: approve caller is not owner nor approved for all");
        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        FamiliarData memory data = _getFamiliarDataWithDecay(tokenId); // Get data including current decayed stats

        // Generate dynamic metadata based on state
        string memory name = string(abi.encodePacked("Familiar #", _toString(tokenId)));
        string memory description = string(abi.encodePacked(
            "A digital familiar. Trait: ", _toString(data.traitId),
            ", Stage: ", _stageToString(data.stage),
            ", State: ", _stateToString(data.state)
            // Add more detailed stats here if desired, or keep description concise
        ));

        // Placeholder image - in a real app, this would map trait+stage+state to an actual image URL
        // For this example, we'll just indicate the stage and state
        string memory image = string(abi.encodePacked(
             "data:image/svg+xml;base64,",
             Base64.encode(bytes(string(abi.encodePacked(
                 "<svg xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMinyMin meet' viewBox='0 0 350 350'><style>.base { fill: white; font-family: serif; font-size: 24px; }</style><rect width='100%' height='100%' fill='#",
                 _stageColor(data.stage), // Dynamic color based on stage
                 "'/><text x='10' y='25' class='base'>Familiar #", _toString(tokenId), "</text>",
                 "<text x='10' y='55' class='base'>Stage: ", _stageToString(data.stage), "</text>",
                 "<text x='10' y='85' class='base'>State: ", _stateToString(data.state), "</text>",
                 // Could add stats visually here too
                 "</svg>"
             ))))
         ));


        // Construct JSON object
        string memory json = string(abi.encodePacked(
            '{"name": "', name, '",',
            '"description": "', description, '",',
            '"image": "', image, '",',
            '"attributes": [',
                '{"trait_type": "Trait ID", "value": ', _toString(data.traitId), '},',
                '{"trait_type": "Stage", "value": "', _stageToString(data.stage), '"},',
                '{"trait_type": "State", "value": "', _stateToString(data.state), '"},',
                '{"display_type": "number", "trait_type": "Energy", "value": ', _toString(data.energy), '},',
                '{"display_type": "number", "trait_type": "Mood", "value": ', _toString(data.mood), '},',
                '{"display_type": "number", "trait_type": "Hunger", "value": ', _toString(data.hunger), '},',
                '{"display_type": "number", "trait_type": "Health", "value": ', _toString(data.health), '},',
                '{"display_type": "number", "trait_type": "Growth", "value": ', _toString(data.growth), '}',
            ']}'
        ));

        // Return as data URI
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    // --- Familiar Data Management ---

    function mintFamiliar() public returns (uint256) {
        uint256 newTokenId = _tokenIdCounter;
        _tokenIdCounter++;

        // Basic random-ish trait based on block hash and minter address
        uint32 trait = uint32(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender, newTokenId))) % 1000); // Trait ID 0-999

        _familiars[newTokenId] = FamiliarData({
            energy: uint16(MAX_STAT),
            mood: uint16(MAX_STAT),
            hunger: uint16(MAX_STAT),
            health: uint16(MAX_STAT),
            growth: 0,
            stage: FamiliarStage.Egg,
            state: FamiliarState.Healthy,
            lastInteractionTime: uint48(block.timestamp), // Set initial interaction time
            traitId: trait
        });

        _transfer(address(0), msg.sender, newTokenId);
        emit FamiliarMinted(msg.sender, newTokenId, trait);
        return newTokenId;
    }

    // Internal helper to apply decay and calculate current stats
    function _applyDecay(uint256 tokenId, FamiliarData memory familiar) internal view returns (FamiliarData memory) {
        uint256 timeElapsed = block.timestamp - familiar.lastInteractionTime;
        uint256 daysElapsed = timeElapsed / TIME_UNIT; // Integer division for full days

        familiar.energy = familiar.energy > daysElapsed * familiarDecayRates.energyDecayPerDay ?
                          uint16(familiar.energy - daysElapsed * familiarDecayRates.energyDecayPerDay) : 0;
        familiar.mood = familiar.mood > daysElapsed * familiarDecayRates.moodDecayPerDay ?
                        uint16(familiar.mood - daysElapsed * familiarDecayRates.moodDecayPerDay) : 0;
         familiar.hunger = familiar.hunger < MAX_STAT - daysElapsed * familiarDecayRates.hungerDecayPerDay ?
                           uint16(familiar.hunger + daysElapsed * familiarDecayRates.hungerDecayPerDay) : uint16(MAX_STAT); // Hunger increases
         familiar.health = familiar.health > daysElapsed * familiarDecayRates.healthDecayPerDay ?
                           uint16(familiar.health - daysElapsed * familiarDecayRates.healthDecayPerDay) : 0;

        // Growth increases passively over time
        familiar.growth += uint252(daysElapsed * GROWTH_PER_DAY_BASE);

        return familiar;
    }

     // Internal helper to determine familiar state based on stats
    function _determineState(FamiliarData memory familiar) internal pure returns (FamiliarState) {
        if (familiar.health == 0 || familiar.energy == 0 || familiar.mood == 0) {
             return FamiliarState.Lost; // Game over state
        }
        if (familiar.health < MAX_STAT / 4) return FamiliarState.Sick;
        if (familiar.mood < MAX_STAT / 4 && familiar.energy < MAX_STAT / 4) return FamiliarState.Depressed;
        if (familiar.hunger > MAX_STAT * 3 / 4) return FamiliarState.Hungry;
        if (familiar.energy < MAX_STAT / 4) return FamiliarState.Tired;
        if (familiar.mood < MAX_STAT / 4) return FamiliarState.Bored;

        return FamiliarState.Healthy;
    }

    // Internal helper to update familiar state in storage
    function _updateFamiliarStateInStorage(uint256 tokenId, FamiliarData memory familiar) internal {
        FamiliarState oldState = _familiars[tokenId].state;
        FamiliarState newState = _determineState(familiar);

        // Apply calculated decay and state to storage
        _familiars[tokenId] = familiar;
        _familiars[tokenId].state = newState; // Update state

        // Only emit if state changed
        if (oldState != newState) {
             emit FamiliarStateChanged(tokenId, newState, oldState);
        }
    }

    // Get familiar data with decay applied (read-only view)
    function getFamiliarData(uint256 tokenId) public view returns (FamiliarData memory) {
        require(_exists(tokenId), "Familiar does not exist");
        FamiliarData memory familiar = _familiars[tokenId];
        familiar = _applyDecay(tokenId, familiar); // Apply decay for current view
        familiar.state = _determineState(familiar); // Determine current state based on decayed stats
        return familiar;
    }

    // Get current contract configuration
    function getFamiliarConfig() public view returns (ConfigDecayRates memory, uint255[] memory, ConfigInteractionCosts memory) {
        return (familiarDecayRates, familiarEvolutionThresholds, familiarInteractionCosts);
    }

    // --- Interaction Functions ---

    function feedFamiliar(uint256 tokenId)
        public
        payable
        onlyFamiliarOwnerOrDelegate(tokenId)
    {
        require(_exists(tokenId), "Familiar does not exist");
        require(msg.value >= familiarInteractionCosts.feedCost, "Insufficient ETH sent");

        FamiliarData memory familiar = _getFamiliarDataWithDecay(tokenId); // Get current stats after decay

        require(familiar.state != FamiliarState.Lost, "Familiar is Lost and cannot be interacted with");

        // Apply effect of feeding (boost hunger recovery, small mood/energy)
        familiar.hunger = familiar.hunger > 200 ? uint16(familiar.hunger - 200) : 0; // Decrease hunger significantly
        familiar.mood = familiar.mood < MAX_STAT - 50 ? uint16(familiar.mood + 50) : uint16(MAX_STAT);
        familiar.energy = familiar.energy < MAX_STAT - 30 ? uint16(familiar.energy + 30) : uint16(MAX_STAT);

        familiar.lastInteractionTime = uint48(block.timestamp); // Update interaction time
        _updateFamiliarStateInStorage(tokenId, familiar); // Save updated state and stats

        emit FamiliarInteracted(tokenId, "Feed", msg.value);
    }

    function playWithFamiliar(uint256 tokenId)
        public
        payable
        onlyFamiliarOwnerOrDelegate(tokenId)
    {
        require(_exists(tokenId), "Familiar does not exist");
         require(msg.value >= familiarInteractionCosts.playCost, "Insufficient ETH sent");

        FamiliarData memory familiar = _getFamiliarDataWithDecay(tokenId); // Get current stats after decay

        require(familiar.state != FamiliarState.Lost, "Familiar is Lost and cannot be interacted with");

        // Apply effect of playing (boost mood/energy, slight hunger increase)
        familiar.mood = familiar.mood < MAX_STAT - 250 ? uint16(familiar.mood + 250) : uint16(MAX_STAT);
        familiar.energy = familiar.energy < MAX_STAT - 150 ? uint16(familiar.energy + 150) : uint16(MAX_STAT);
        familiar.hunger = familiar.hunger < MAX_STAT - 50 ? uint16(familiar.hunger + 50) : uint16(MAX_STAT); // Playing makes them hungry

        familiar.lastInteractionTime = uint48(block.timestamp); // Update interaction time
        _updateFamiliarStateInStorage(tokenId, familiar); // Save updated state and stats

        emit FamiliarInteracted(tokenId, "Play", msg.value);
    }

    function restFamiliar(uint256 tokenId)
        public
        payable
        onlyFamiliarOwnerOrDelegate(tokenId)
    {
        require(_exists(tokenId), "Familiar does not exist");
         require(msg.value >= familiarInteractionCosts.restCost, "Insufficient ETH sent");

        FamiliarData memory familiar = _getFamiliarDataWithDecay(tokenId); // Get current stats after decay

        require(familiar.state != FamiliarState.Lost, "Familiar is Lost and cannot be interacted with");

        // Apply effect of resting (boost energy/health, slight mood decrease from inactivity)
        familiar.energy = familiar.energy < MAX_STAT - 300 ? uint16(familiar.energy + 300) : uint16(MAX_STAT);
        familiar.health = familiar.health < MAX_STAT - 200 ? uint16(familiar.health + 200) : uint16(MAX_STAT);
        familiar.mood = familiar.mood > 50 ? uint16(familiar.mood - 50) : 0; // Resting can be boring

        familiar.lastInteractionTime = uint48(block.timestamp); // Update interaction time
        _updateFamiliarStateInStorage(tokenId, familiar); // Save updated state and stats

        emit FamiliarInteracted(tokenId, "Rest", msg.value);
    }

    // --- Lifecycle Functions ---

    // This function can be called by anyone to 'poke' the familiar and update its state
    // based on time elapsed, without requiring ownership or interaction costs.
    function checkFamiliarState(uint256 tokenId) public {
        require(_exists(tokenId), "Familiar does not exist");
        FamiliarData memory familiar = _getFamiliarDataWithDecay(tokenId); // Get current stats after decay

        FamiliarState oldState = familiar.state; // Get state before potential update
        FamiliarState newState = _determineState(familiar); // Determine the state based on decayed stats

        // Update state in storage ONLY if it changed or if it's the first check after decay period
        // This prevents state changes from being missed if nobody interacts for a long time.
        // We re-fetch from storage here because _getFamiliarDataWithDecay returns a memory copy
         FamiliarData storage storageFamiliar = _familiars[tokenId];
         if (storageFamiliar.state != newState) {
             storageFamiliar.state = newState;
             emit FamiliarStateChanged(tokenId, newState, oldState);
         }

         // Also update the stats calculated with decay, but only apply full days worth of decay
         // The _applyDecay calculates decay based on block.timestamp - lastInteractionTime
         // We apply it here but don't update lastInteractionTime unless it was an *interaction*
         // This ensures the decay is visually reflected even without paying for interaction.
         // Note: This might make stats appear lower in `getFamiliarData` than what's saved,
         // but interactions will use the correctly decayed value before boosting.
         // Let's refine: `checkFamiliarState` only determines and updates the *state enum*, not the stats.
         // Stats and growth decay are only persisted when an interaction function is called,
         // or via a specific decay application function if needed.
         // Reworking: `_getFamiliarDataWithDecay` is view only. Interaction functions
         // fetch, apply decay, apply boost, and *save*. `checkFamiliarState` just calculates
         // the state based on the *last saved* stats and the time elapsed, then *updates the state enum only* if needed.

         // Let's revert to simpler logic: Interaction functions update stats and time.
         // `checkFamiliarState` *calculates* decay and state based on current time vs lastInteractionTime,
         // and updates the state enum in storage if it's different from the stored state enum.
         // This ensures the displayed state is reasonably up-to-date. Stats shown by getFamiliarData
         // will reflect decay but are not saved until an interaction occurs.

        // Re-read from storage to compare current stored state
        storageFamiliar = _familiars[tokenId]; // Use storage pointer
        newState = _determineState(_applyDecay(tokenId, storageFamiliar)); // Calculate state based on decayed stats

        if (storageFamiliar.state != newState) {
            storageFamiliar.state = newState;
             emit FamiliarStateChanged(tokenId, newState, oldState);
        }
         // Stats themselves are NOT updated in storage here, only the state enum.
         // This saves gas for read-only checks. Stats are only updated on interactions.
    }

    function checkFamiliarEvolution(uint256 tokenId)
        public
        onlyFamiliarOwnerOrDelegate(tokenId)
    {
        require(_exists(tokenId), "Familiar does not exist");
        FamiliarData memory familiar = _getFamiliarDataWithDecay(tokenId); // Get current stats after decay

        require(familiar.state != FamiliarState.Lost, "Familiar is Lost and cannot evolve");

        FamiliarStage oldStage = familiar.stage;
        FamiliarStage newStage = oldStage;
        uint252 currentGrowth = familiar.growth;

        // Check evolution thresholds based on current growth
        if (oldStage == FamiliarStage.Egg && currentGrowth >= familiarEvolutionThresholds[0]) {
            newStage = FamiliarStage.Child;
        } else if (oldStage == FamiliarStage.Child && familiarEvolutionThresholds.length > 1 && currentGrowth >= familiarEvolutionThresholds[1]) {
            newStage = FamiliarStage.Adult;
        } else if (oldStage == FamiliarStage.Adult && familiarEvolutionThresholds.length > 2 && currentGrowth >= familiarEvolutionThresholds[2]) {
            newStage = FamiliarStage.Elder;
        }
        // Add more stages here if needed

        if (newStage != oldStage) {
            // Apply decay, update state, and save the new stage
             FamiliarData storage storageFamiliar = _familiars[tokenId];
             storageFamiliar = _applyDecay(tokenId, storageFamiliar); // Apply decay before saving
             storageFamiliar.stage = newStage;
             storageFamiliar.state = _determineState(storageFamiliar); // Re-determine state after decay/stage change
             storageFamiliar.lastInteractionTime = uint48(block.timestamp); // Update interaction time

            emit FamiliarEvolution(tokenId, newStage, oldStage);
            emit FamiliarStateChanged(tokenId, storageFamiliar.state, storageFamiliar.state); // Emit state change if it occurred
        } else {
             // If no evolution, just update the state based on potential decay since last interaction
             // We explicitly update state here even if no evolution occurred, as this function also
             // implies a check/update cycle.
             checkFamiliarState(tokenId); // Call the state check logic
        }

        // Always update last interaction time when checking evolution, as it's a form of engagement.
         _familiars[tokenId].lastInteractionTime = uint48(block.timestamp);
         _familiars[tokenId].growth = familiar.growth; // Save the calculated growth
    }

    // --- Delegation Functions ---

    function setCareDelegate(address delegate, bool approved) public {
        _careDelegates[msg.sender][delegate] = approved;
        emit CareDelegateSet(msg.sender, delegate, approved);
    }

    function isCareDelegate(address owner, address delegate) public view returns (bool) {
        return _careDelegates[owner][delegate];
    }

    // Allows a delegate to feed a familiar owned by another address
    function feedFamiliarDelegated(address owner, uint256 tokenId) public payable {
        require(_owners[tokenId] == owner, "Token not owned by specified owner");
        require(_careDelegates[owner][msg.sender], "Caller is not a care delegate for the owner");
        // Now execute the core feeding logic (reusing feedFamiliar's internal steps)
        // Note: The msg.sender check inside feedFamiliar's modifier would fail here.
        // We need to call the internal logic directly or restructure.
        // Let's restructure feed/play/rest into internal functions.

        _internalFeedFamiliar(tokenId, msg.value);

         emit FamiliarInteracted(tokenId, "Feed (Delegated)", msg.value); // Use a different event type maybe
    }

    // Internal version of feed accessible by owner or delegate
    function _internalFeedFamiliar(uint256 tokenId, uint256 valueSent) internal {
        require(_exists(tokenId), "Familiar does not exist");
        require(valueSent >= familiarInteractionCosts.feedCost, "Insufficient ETH sent");

        FamiliarData memory familiar = _getFamiliarDataWithDecay(tokenId); // Get current stats after decay

        require(familiar.state != FamiliarState.Lost, "Familiar is Lost and cannot be interacted with");

        familiar.hunger = familiar.hunger > 200 ? uint16(familiar.hunger - 200) : 0;
        familiar.mood = familiar.mood < MAX_STAT - 50 ? uint16(familiar.mood + 50) : uint16(MAX_STAT);
        familiar.energy = familiar.energy < MAX_STAT - 30 ? uint16(familiar.energy + 30) : uint16(MAX_STAT);

        familiar.lastInteractionTime = uint48(block.timestamp);
        _updateFamiliarStateInStorage(tokenId, familiar); // Save updated state and stats
    }

     // Re-implement public feed to call internal function
     function feedFamiliar(uint256 tokenId)
        public
        payable
        onlyFamiliarOwnerOrDelegate(tokenId)
    {
        _internalFeedFamiliar(tokenId, msg.value);
        emit FamiliarInteracted(tokenId, "Feed", msg.value);
    }

    // Similarly restructure Play and Rest
     function _internalPlayWithFamiliar(uint256 tokenId, uint256 valueSent) internal {
        require(_exists(tokenId), "Familiar does not exist");
         require(valueSent >= familiarInteractionCosts.playCost, "Insufficient ETH sent");

        FamiliarData memory familiar = _getFamiliarDataWithDecay(tokenId);

        require(familiar.state != FamiliarState.Lost, "Familiar is Lost and cannot be interacted with");

        familiar.mood = familiar.mood < MAX_STAT - 250 ? uint16(familiar.mood + 250) : uint16(MAX_STAT);
        familiar.energy = familiar.energy < MAX_STAT - 150 ? uint16(familiar.energy + 150) : uint16(MAX_STAT);
        familiar.hunger = familiar.hunger < MAX_STAT - 50 ? uint16(familiar.hunger + 50) : uint16(MAX_STAT);

        familiar.lastInteractionTime = uint48(block.timestamp);
        _updateFamiliarStateInStorage(tokenId, familiar);
    }

    function playWithFamiliar(uint256 tokenId)
        public
        payable
        onlyFamiliarOwnerOrDelegate(tokenId)
    {
        _internalPlayWithFamiliar(tokenId, msg.value);
        emit FamiliarInteracted(tokenId, "Play", msg.value);
    }

     function _internalRestFamiliar(uint256 tokenId, uint256 valueSent) internal {
        require(_exists(tokenId), "Familiar does not exist");
         require(valueSent >= familiarInteractionCosts.restCost, "Insufficient ETH sent");

        FamiliarData memory familiar = _getFamiliarDataWithDecay(tokenId);

        require(familiar.state != FamiliarState.Lost, "Familiar is Lost and cannot be interacted with");

        familiar.energy = familiar.energy < MAX_STAT - 300 ? uint16(familiar.energy + 300) : uint16(MAX_STAT);
        familiar.health = familiar.health < MAX_STAT - 200 ? uint16(familiar.health + 200) : uint16(MAX_STAT);
        familiar.mood = familiar.mood > 50 ? uint16(familiar.mood - 50) : 0;

        familiar.lastInteractionTime = uint48(block.timestamp);
        _updateFamiliarStateInStorage(tokenId, familiar);
    }

    function restFamiliar(uint256 tokenId)
        public
        payable
        onlyFamiliarOwnerOrDelegate(tokenId)
    {
        _internalRestFamiliar(tokenId, msg.value);
        emit FamiliarInteracted(tokenId, "Rest", msg.value);
    }


    // --- Oracle Interaction (Simulated) ---

    function updateGlobalMood(int256 newMoodValue) public onlyOracle {
        // Simple range capping
        if (newMoodValue > 100) newMoodValue = 100;
        if (newMoodValue < 0) newMoodValue = 0;

        _globalMood = newMoodValue;
        emit GlobalMoodUpdated(newMoodValue);
    }

    function getGlobalMood() public view returns (int256) {
        return _globalMood;
    }

    // --- Configuration Functions ---

    function setConfigDecayRates(uint256 energyDecayPerDay, uint256 moodDecayPerDay, uint256 hungerDecayPerDay, uint256 healthDecayPerDay) public onlyOwner {
        familiarDecayRates = ConfigDecayRates(energyDecayPerDay, moodDecayPerDay, hungerDecayPerDay, healthDecayPerDay);
        emit ConfigUpdated("DecayRates");
    }

    function setConfigEvolutionThresholds(uint255[] memory thresholds) public onlyOwner {
         // Optional: Add validation for threshold values (e.g., increasing sequence)
         familiarEvolutionThresholds = thresholds;
         emit ConfigUpdated("EvolutionThresholds");
    }

    function setConfigInteractionCosts(uint256 feedCost, uint256 playCost, uint256 restCost) public onlyOwner {
         familiarInteractionCosts = ConfigInteractionCosts(feedCost, playCost, restCost);
         emit ConfigUpdated("InteractionCosts");
    }

    // --- Utility Functions ---

     function withdrawContractBalance() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
     }

    // Predict how much more growth is needed for the next evolution
    function predictNextEvolution(uint256 tokenId) public view returns (uint256 growthNeeded, FamiliarStage nextStage) {
        require(_exists(tokenId), "Familiar does not exist");
        FamiliarData memory familiar = _getFamiliarDataWithDecay(tokenId); // Get current data including growth

        uint252 currentGrowth = familiar.growth;
        uint256 currentStageIndex = uint256(familiar.stage);

        if (currentStageIndex >= familiarEvolutionThresholds.length) {
            // Already at or beyond the last defined stage
            return (0, familiar.stage);
        }

        uint256 thresholdForNextStage = familiarEvolutionThresholds[currentStageIndex];

        if (currentGrowth >= thresholdForNextStage) {
             // Already met or exceeded the threshold for the next *defined* stage.
             // This should ideally be handled by checkFamiliarEvolution.
             // If threshold met, the 'next' is the current stage, but indicates it's ready or past.
             return (0, familiar.stage); // Indicate already met/passed threshold
        } else {
             growthNeeded = thresholdForNextStage - currentGrowth;
             nextStage = FamiliarStage(currentStageIndex + 1); // Assuming enum stages are sequential
             return (growthNeeded, nextStage);
        }
    }


    // --- Internal Helpers (Minimal ERC721 Implementation) ---

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

     function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(_owners[tokenId] == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _approve(address(0), tokenId); // Clear approval

        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

     // Copied from OZ to avoid dependency on their full implementation
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (to.code.length == 0) {
            return true;
        }
        try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
            return retval == IERC721Receiver.onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            } else {
                /// @solidity only catched events with a reason string are handled in the catch block.
                /// Errors with no reason string are caught as low level calls.
                /// See https://github.com/ethereum/solidity/issues/10503
                revert(string(reason));
            }
        }
    }

    // Internal helper to get familiar data and apply decay
    function _getFamiliarDataWithDecay(uint256 tokenId) internal view returns (FamiliarData memory) {
         require(_exists(tokenId), "Familiar does not exist");
         FamiliarData memory familiar = _familiars[tokenId];
         // Apply decay calculation for the current moment in time
         familiar = _applyDecay(tokenId, familiar);
         return familiar;
    }

    // Internal helper for converting uint to string
    function _toString(uint256 value) internal pure returns (string memory) {
        // Copied from OZ to avoid dependency
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // Internal helpers for enums to string
    function _stageToString(FamiliarStage stage) internal pure returns (string memory) {
        if (stage == FamiliarStage.Egg) return "Egg";
        if (stage == FamiliarStage.Child) return "Child";
        if (stage == FamiliarStage.Adult) return "Adult";
        if (stage == FamiliarStage.Elder) return "Elder";
        if (stage == FamiliarStage.Lost) return "Lost";
        return "Unknown";
    }

    function _stateToString(FamiliarState state) internal pure returns (string memory) {
        if (state == FamiliarState.Healthy) return "Healthy";
        if (state == FamiliarState.Hungry) return "Hungry";
        if (state == FamiliarState.Tired) return "Tired";
        if (state == FamiliarState.Bored) return "Bored";
        if (state == FamiliarState.Sick) return "Sick";
        if (state == FamiliarState.Depressed) return "Depressed";
         if (state == FamiliarState.Lost) return "Lost";
        return "Unknown";
    }

     // Internal helper for stages to color (for dynamic SVG)
    function _stageColor(FamiliarStage stage) internal pure returns (string memory) {
        if (stage == FamiliarStage.Egg) return "FFFFCC"; // Light Yellow
        if (stage == FamiliarStage.Child) return "CCFFCC"; // Light Green
        if (stage == FamiliarStage.Adult) return "CCCCFF"; // Light Blue
        if (stage == FamiliarStage.Elder) return "FFCCCC"; // Light Red
         if (stage == FamiliarStage.Lost) return "CCCCCC"; // Grey
        return "FFFFFF"; // White default
    }
}
```