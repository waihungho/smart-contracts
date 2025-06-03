Okay, let's create a smart contract concept that involves dynamic, state-changing NFTs influenced by global cycles and individual interactions. This goes beyond simple ownership and static metadata.

We'll call it "AethelgardAmulets". These are Soulbound NFTs (cannot be transferred once bound) representing a mystical amulet. Each amulet has traits that change over time, based on aging, processing cycles, rejuvenation, and global "Aetheric Cycles" managed by the contract owner.

**Advanced Concepts Involved:**

1.  **Soulbound Tokens:** NFTs that are permanently tied to an address after a certain action.
2.  **Dynamic Metadata:** The `tokenURI` reflects the amulet's current state, requiring off-chain logic to interpret on-chain data.
3.  **Aging & Decay:** Amlets age over time (measured in contract cycles), leading to potential decay in traits.
4.  **Rejuvenation:** A mechanism to reset an amulet's age and counteract decay (potentially costing resources).
5.  **Empowerment:** A mechanism to boost traits, possibly restricted to certain conditions (like specific cycles).
6.  **Global Cycles:** A contract-wide state variable (`_globalCycle`) that advances and influences all amulets dynamically.
7.  **Cycle-Based Effects:** The impact of the global cycle on an amulet's traits is configurable.
8.  **On-Chain State Processing:** A specific function (`processAmuletState`) is required to update an amulet's decay and age based on elapsed time/cycles.
9.  **Calculated/Effective Traits:** The visible "strength" of a trait is not just stored data, but a calculation based on base value, age/decay, empowerment, and current cycle effects.
10. **Permissioned Actions:** Some actions (like advancing cycles, setting decay rates) are restricted to the owner.

---

### **AethelgardAmulets Smart Contract**

**Outline:**

1.  **SPDX License and Pragma**
2.  **Imports:** ERC721 interfaces (for standard compliance).
3.  **Interfaces (Optional but good practice):** Define interfaces for key interactions if planning integration. Not strictly needed for this standalone example.
4.  **Error Definitions:** Custom errors for clarity and gas efficiency (Solidity 0.8+).
5.  **State Variables:**
    *   Contract Owner
    *   Paused State
    *   Token Counter
    *   Amulet Data Mapping (`tokenId => Amulet`)
    *   Owner Mapping (`tokenId => ownerAddress`)
    *   Balance Mapping (`ownerAddress => balance`)
    *   Approved/Operator Mappings (Standard ERC721 - simplified for this example)
    *   Base Token URI
    *   Global Aetheric Cycle Counter
    *   Decay Rate Configuration
    *   Rejuvenation Cost (in Ether)
    *   Cycle-Specific Effect Modifiers Configuration
    *   Cycle Phase required for Empowerment Configuration
    *   Trait Names Mapping (for metadata hints)
6.  **Structs:**
    *   `Amulet`: Data structure holding `mintCycle`, `lastProcessedCycle`, `isSoulbound`, `baseTraitValues`, `empoweredTraitValues`.
7.  **Events:**
    *   Minting, Binding, State Processing, Rejuvenation, Empowerment, Cycle Advance, Config Changes.
8.  **Modifiers:**
    *   `onlyOwner`: Restricts access to the contract owner.
    *   `whenNotPaused`: Prevents execution if the contract is paused.
    *   `amuletExists`: Checks if a token ID is valid.
    *   `isOwnerOrApproved`: ERC721 standard access check (simplified).
9.  **Constructor:** Initializes owner, cycle, etc.
10. **ERC721 Standard Functions (Minimal Implementation/Overrides):**
    *   `balanceOf`
    *   `ownerOf`
    *   `transferFrom` (Override to check soulbound)
    *   `safeTransferFrom` (Override to check soulbound)
    *   `approve`, `setApprovalForAll`, `getApproved`, `isApprovedForAll` (Minimal/dummy implementation as transfers are restricted)
    *   `supportsInterface` (Indicate ERC721 compliance)
    *   `tokenURI` (Dynamic)
11. **Core Amulet Lifecycle Functions:**
    *   `mint`: Creates a new amulet.
    *   `bindAmulet`: Makes an amulet Soulbound to its owner.
    *   `processAmuletState`: Updates an amulet's internal state based on elapsed cycles (applies aging/decay).
12. **Dynamic Behavior Functions:**
    *   `rejuvenateAmulet`: Resets amulet age, potentially costs Ether.
    *   `empowerAmulet`: Increases a trait value under specific cycle conditions.
13. **Cycle Management Functions:**
    *   `advanceGlobalCycle`: Owner function to increment the global cycle.
    *   `getGlobalCycle`: Reads the current global cycle.
    *   `setCycleEffectModifier`: Owner configures how cycles affect traits.
    *   `getCycleEffectModifier`: Queries cycle effect configuration.
    *   `setEmpowerCyclePhase`: Owner configures which cycle phase allows empowerment.
    *   `getEmpowerCyclePhase`: Queries empowerment phase configuration.
14. **Amulet State Querying & Calculation Functions:**
    *   `getAmuletData`: Gets raw stored amulet data.
    *   `getAmuletAgeCycles`: Calculates age in cycles since minting.
    *   `getAmuletDecayCycles`: Calculates cycles since last processing (decay potential).
    *   `calculateDecayPenalty`: Calculates the current decay penalty for a trait based on decay cycles and rate.
    *   `calculateCycleBonusOrPenalty`: Calculates the effect of the current global cycle on a trait.
    *   `calculateEffectiveTrait`: Combines base, empowered, decay, and cycle effects to get the *actual* trait value.
    *   `queryEffectiveState`: Returns all calculated effective traits and key state variables.
15. **Admin/Configuration Functions:**
    *   `setBaseTokenURI`: Sets the base URI for metadata.
    *   `setDecayRate`: Configures the global decay rate.
    *   `setRejuvenationCost`: Configures the Ether cost for rejuvenation.
    *   `setTraitName`: Configures names for trait indices (metadata helper).
    *   `pauseContract`: Pauses contract interactions (owner).
    *   `unpauseContract`: Unpauses contract interactions (owner).
    *   `withdrawFunds`: Withdraws collected Ether (from rejuvenation).

**Function Summary (25 Functions):**

1.  `constructor()`: Deploys the contract, sets owner and initial cycle.
2.  `balanceOf(address owner)`: ERC721: Returns the number of tokens owned by an address.
3.  `ownerOf(uint256 tokenId)`: ERC721: Returns the owner of a specific token.
4.  `transferFrom(address from, address to, uint256 tokenId)`: ERC721 Override: Transfers token, *checks if not soulbound*.
5.  `safeTransferFrom(address from, address to, uint256 tokenId)`: ERC721 Override: Transfers token safely, *checks if not soulbound*.
6.  `approve(address to, uint256 tokenId)`: ERC721 Override: Approves address for transfer (dummy/restricted by soulbound).
7.  `setApprovalForAll(address operator, bool approved)`: ERC721 Override: Sets operator for all tokens (dummy/restricted).
8.  `getApproved(uint256 tokenId)`: ERC721 Override: Gets approved address (dummy/restricted).
9.  `isApprovedForAll(address owner, address operator)`: ERC721 Override: Checks operator approval (dummy/restricted).
10. `supportsInterface(bytes4 interfaceId)`: ERC721: Indicates supported interfaces.
11. `tokenURI(uint256 tokenId)`: ERC721 Override: Returns the URI for token metadata (designed to be dynamic based on state).
12. `mint(address to)`: Creates and assigns a new Amulet NFT to an address.
13. `bindAmulet(uint256 tokenId)`: Makes the specified amulet Soulbound to its current owner.
14. `processAmuletState(uint256 tokenId)`: Calculates elapsed cycles since last processing and applies aging/decay penalties to the amulet's state.
15. `rejuvenateAmulet(uint256 tokenId)`: Resets the amulet's age back to zero cycles, paid with Ether.
16. `empowerAmulet(uint256 tokenId, uint8 traitIndex, uint8 value)`: Increases the empowered value of a specific trait, only callable during a configured global cycle phase.
17. `advanceGlobalCycle()`: Owner-only function to increment the global Aetheric Cycle counter.
18. `getGlobalCycle()`: Returns the current global Aetheric Cycle number.
19. `setCycleEffectModifier(uint8 cyclePhase, uint8 traitIndex, int8 modifierValue)`: Owner-only configures how a specific cycle phase modifies a specific trait.
20. `getCycleEffectModifier(uint8 cyclePhase, uint8 traitIndex)`: Returns the configured modifier value for a cycle phase and trait.
21. `calculateEffectiveTrait(uint256 tokenId, uint8 traitIndex)`: Calculates the effective value of a trait considering base, empowered, decay penalties, and current cycle effects.
22. `queryEffectiveState(uint256 tokenId)`: Returns a comprehensive view of the amulet's current calculated state, including effective traits.
23. `setDecayRate(uint8 decayRatePerCycle)`: Owner-only sets the global rate at which decay penalties accrue per unprocessed cycle.
24. `setRejuvenationCost(uint256 cost)`: Owner-only sets the amount of Ether required to rejuvenate an amulet.
25. `setEmpowerCyclePhase(uint8 phase)`: Owner-only sets the required global cycle phase during which `empowerAmulet` can be called.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC721, IERC721Enumerable, IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol"; // For supportsInterface

// Note: This contract implements the core logic of AethelgardAmulets
// and required ERC721 functions minimally to demonstrate the concept.
// For a production contract, consider using OpenZeppelin library for
// battle-tested ERC721 implementations, Ownable, Pausable etc.
// However, to adhere to the "don't duplicate open source" spirit conceptually,
// the core mechanics (soulbound, aging, cycles, dynamic traits) are custom.

error NotOwnerOrApproved();
error AmuletDoesNotExist();
error AmuletIsSoulbound();
error OnlyCallableWhenNotPaused();
error OnlyCallableWhenPaused();
error InvalidTraitIndex();
error InvalidValue();
error InsufficientPayment();
error WrongCyclePhaseForEmpowerment();
error NoFundsToWithdraw();

contract AethelgardAmulets is IERC721, IERC721Enumerable, IERC721Metadata, ERC165 {

    // --- State Variables ---
    address private immutable i_owner;
    bool private _paused;
    uint256 private _tokenIds; // Counter for unique token IDs
    uint256 private _globalCycle; // Global counter for the Aetheric Cycle

    // Amulet Data Storage
    struct Amulet {
        uint256 mintCycle; // The cycle the amulet was minted
        uint256 lastProcessedCycle; // The last global cycle when state was processed
        bool isSoulbound;
        uint8[5] baseTraitValues; // Example: Strength, Intellect, Resilience, etc. (0-255)
        uint8[5] empoweredTraitValues; // Values added through empowerment (additive)
    }

    mapping(uint256 => Amulet) private _amulets;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _owners;

    // ERC721 standard mappings (simplified)
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Configuration
    string private _baseTokenURI;
    uint8 private _decayRatePerCycle; // How much each trait decays per unprocessed cycle (e.g., 1 = -1 per trait per cycle)
    uint256 private _rejuvenationCost; // Cost in wei to rejuvenate an amulet
    uint8 private _empowerCyclePhase; // Required global cycle phase (0-99) to empower an amulet

    // Cycle Effects Configuration
    // Mapping: cyclePhase => traitIndex => modifier (signed integer)
    mapping(uint8 => mapping(uint8 => int8)) private _cycleEffectModifiers;

    // Metadata Helpers (Off-chain service would read these)
    string[5] private _traitNames; // Names for the 5 traits

    // --- Events ---
    event Minted(address indexed to, uint256 indexed tokenId, uint256 indexed mintCycle);
    event Bound(uint256 indexed tokenId);
    event StateProcessed(uint256 indexed tokenId, uint256 lastProcessedCycle, uint8[] decayPenaltiesApplied);
    event Rejuvenated(uint256 indexed tokenId, address indexed owner);
    event Empowered(uint256 indexed tokenId, uint8 indexed traitIndex, uint8 value);
    event CycleAdvanced(uint256 indexed newCycle);
    event DecayRateUpdated(uint8 indexed newRate);
    event RejuvenationCostUpdated(uint256 indexed newCost);
    event EmpowerPhaseUpdated(uint8 indexed newPhase);
    event TraitNameUpdated(uint8 indexed traitIndex, string name);
    event CycleEffectUpdated(uint8 indexed cyclePhase, uint8 indexed traitIndex, int8 modifierValue);
    event Paused(address account);
    event Unpaused(address account);
    event FundsWithdrawn(address indexed to, uint256 amount);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == i_owner, "Not contract owner");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused, OnlyCallableWhenNotPaused.selector);
        _;
    }

    modifier whenPaused() {
        require(_paused, OnlyCallableWhenPaused.selector);
        _;
    }

    modifier amuletExists(uint256 tokenId) {
        require(_owners[tokenId] != address(0), AmuletDoesNotExist.selector);
        _;
    }

    // --- Constructor ---
    constructor(uint8 initialDecayRate, uint256 initialRejuvCost, uint8 initialEmpowerPhase) {
        i_owner = msg.sender;
        _tokenIds = 0;
        _globalCycle = 1; // Start from Cycle 1
        _decayRatePerCycle = initialDecayRate;
        _rejuvenationCost = initialRejuvCost;
        _empowerCyclePhase = initialEmpowerPhase;

        // Set default trait names
        _traitNames = ["Strength", "Intellect", "Resilience", "Agility", "Luck"];

        _paused = false;
    }

    // --- ERC721 Standard Implementations (Simplified) ---

    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Enumerable).interfaceId ||
               interfaceId == type(IERC721Metadata).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "Owner query for non-existent owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), AmuletDoesNotExist.selector);
        return owner;
    }

    function _transfer(address from, address to, uint256 tokenId) internal amuletExists(tokenId) {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals
        delete _tokenApprovals[tokenId];

        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        // Standard ERC721 Transfer event - must be emitted
        emit Transfer(from, to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override whenNotPaused amuletExists(tokenId) {
        // Check soulbound status BEFORE standard checks
        require(!_amulets[tokenId].isSoulbound, AmuletIsSoulbound.selector);

        // Simplified approval check - assumes msg.sender is owner or approved
        require(ownerOf(tokenId) == msg.sender || _tokenApprovals[tokenId] == msg.sender || _operatorApprovals[ownerOf(tokenId)][msg.sender], NotOwnerOrApproved.selector);

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override whenNotPaused amuletExists(tokenId) {
         // Check soulbound status BEFORE standard checks
        require(!_amulets[tokenId].isSoulbound, AmuletIsSoulbound.selector);

        // Simplified approval check
        require(ownerOf(tokenId) == msg.sender || _tokenApprovals[tokenId] == msg.sender || _operatorApprovals[ownerOf(tokenId)][msg.sender], NotOwnerOrApproved.selector);

        _transfer(from, to, tokenId);
        // Note: safeTransfer requires check on receiver contract - omitted for simplicity here.
        // A full implementation would use a helper like Address.isContract and call onERC721Received.
    }

    // Approve/SetApprovalForAll - Functionality is largely negated by soulbound,
    // but interface requires them. Implement them minimally.
    function approve(address to, uint256 tokenId) public override whenNotPaused amuletExists(tokenId) {
         require(ownerOf(tokenId) == msg.sender || _operatorApprovals[ownerOf(tokenId)][msg.sender], NotOwnerOrApproved.selector);
         _tokenApprovals[tokenId] = to;
         emit Approval(msg.sender, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override whenNotPaused {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

     function getApproved(uint256 tokenId) public view override returns (address) {
        require(_owners[tokenId] != address(0), AmuletDoesNotExist.selector); // Standard check
        return _tokenApprovals[tokenId];
     }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }


    function tokenURI(uint256 tokenId) public view override amuletExists(tokenId) returns (string memory) {
        // This function typically returns a URL pointing to metadata JSON.
        // For dynamic NFTs, the JSON hosted at this URL should read the ON-CHAIN state
        // of the amulet (using a blockchain RPC call) and generate the metadata
        // (including traits, age, status) dynamically.
        // The base URI tells the off-chain service where to look.
        // Example: "ipfs://[hash]/[tokenId]" or "https://api.example.com/metadata/[tokenId]"
        string memory base = _baseTokenURI;
        if (bytes(base).length == 0) {
            return ""; // Or a default error URI
        }

        // Concatenate base URI with token ID
        // Using basic string concatenation for example; might need library for complex cases
        return string(abi.encodePacked(base, Strings.toString(tokenId)));
    }

     // IERC721Enumerable - Dummy implementations as we aren't tracking enumeration for simplicity
    function totalSupply() public view override returns (uint256) {
        return _tokenIds; // Total number of tokens minted
    }

    function tokenByIndex(uint256 index) public view override returns (uint256) {
        revert("Enumerable not fully implemented"); // Requires explicit token ID tracking array
    }

     function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
         revert("Enumerable not fully implemented"); // Requires explicit owner token tracking array
     }


    // --- Core Amulet Lifecycle ---

    function mint(address to) public onlyOwner whenNotPaused returns (uint256) {
        require(to != address(0), "Mint to zero address");

        _tokenIds++;
        uint256 newTokenId = _tokenIds; // Get the next token ID

        // Initialize amulet data
        Amulet storage newAmulet = _amulets[newTokenId];
        newAmulet.mintCycle = _globalCycle;
        newAmulet.lastProcessedCycle = _globalCycle; // Start with state processed at mint
        newAmulet.isSoulbound = false; // Not soulbound initially

        // Initialize base traits (e.g., random or fixed - fixed for simplicity)
        for (uint8 i = 0; i < 5; i++) {
             newAmulet.baseTraitValues[i] = 50; // Example initial value
             newAmulet.empoweredTraitValues[i] = 0;
        }


        // Assign ownership
        _balances[to]++;
        _owners[newTokenId] = to;

        // Emit standard ERC721 events
        emit Transfer(address(0), to, newTokenId);
        emit Minted(to, newTokenId, _globalCycle);

        return newTokenId;
    }

    function bindAmulet(uint256 tokenId) public whenNotPaused amuletExists(tokenId) {
        // Only owner can bind their amulet
        require(ownerOf(tokenId) == msg.sender, "Only owner can bind");
        require(!_amulets[tokenId].isSoulbound, "Amulet is already soulbound");

        _amulets[tokenId].isSoulbound = true;
        emit Bound(tokenId);
    }

    function processAmuletState(uint256 tokenId) public whenNotPaused amuletExists(tokenId) {
        Amulet storage amulet = _amulets[tokenId];

        // Calculate cycles passed since last processing
        uint256 cyclesElapsed = _globalCycle - amulet.lastProcessedCycle;

        if (cyclesElapsed == 0) {
             // State is already up-to-date for the current cycle
            return;
        }

        // Apply decay based on elapsed cycles
        uint8[] memory decayPenaltiesApplied = new uint8[](5);
        for (uint8 i = 0; i < 5; i++) {
            // Decay penalty is decayRate * cyclesElapsed
            // Ensure we don't underflow base trait values
            uint256 decayAmount = uint256(_decayRatePerCycle) * cyclesElapsed;
            uint8 currentBase = amulet.baseTraitValues[i];

            uint8 penalty = (currentBase > decayAmount) ? uint8(decayAmount) : currentBase; // Max penalty is current base value
            amulet.baseTraitValues[i] = currentBase - penalty;
            decayPenaltiesApplied[i] = penalty;
        }

        // Update last processed cycle
        amulet.lastProcessedCycle = _globalCycle;

        emit StateProcessed(tokenId, amulet.lastProcessedCycle, decayPenaltiesApplied);
    }


    // --- Dynamic Behavior ---

    function rejuvenateAmulet(uint256 tokenId) public payable whenNotPaused amuletExists(tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Only owner can rejuvenate");
        require(msg.value >= _rejuvenationCost, InsufficientPayment.selector);

        Amulet storage amulet = _amulets[tokenId];

        // Optional: Process state before rejuvenating to apply final decay
        // processAmuletState(tokenId);

        // Reset age related state
        amulet.mintCycle = _globalCycle; // Treat as if newly minted in terms of age
        amulet.lastProcessedCycle = _globalCycle; // State is current

        // Optional: Add a temporary buff or reset decay penalties fully
        // For simplicity, resetting age effectively removes future decay penalty accumulation based on *past* age.
        // Past applied decay remains unless we explicitly increase base traits here.
        // Let's add a small buff to base traits upon rejuvenation as well.
         for (uint8 i = 0; i < 5; i++) {
            // Add a fixed amount, up to max 255
            amulet.baseTraitValues[i] = amulet.baseTraitValues[i] + 10 <= 255 ? amulet.baseTraitValues[i] + 10 : 255;
        }


        emit Rejuvenated(tokenId, msg.sender);

        // Excess Ether is kept in the contract for owner withdrawal
    }

    function empowerAmulet(uint256 tokenId, uint8 traitIndex, uint8 value) public whenNotPaused amuletExists(tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Only owner can empower");
        require(traitIndex < 5, InvalidTraitIndex.selector);
        require(value > 0 && value <= 100, InvalidValue.selector); // Limit empowerment value per call

        // Check if the current global cycle phase allows empowerment
        // Cycle phase is _globalCycle % 100 (0 to 99)
        require(_globalCycle % 100 == _empowerCyclePhase, WrongCyclePhaseForEmpowerment.selector);

        Amulet storage amulet = _amulets[tokenId];

        // Add to empowered value, cap at 255
        uint256 newEmpoweredValue = uint256(amulet.empoweredTraitValues[traitIndex]) + value;
        amulet.empoweredTraitValues[traitIndex] = uint8(newEmpoweredValue > 255 ? 255 : newEmpoweredValue);


        emit Empowered(tokenId, traitIndex, value);
    }

    // --- Cycle Management ---

    function advanceGlobalCycle() public onlyOwner whenNotPaused {
        _globalCycle++;
        emit CycleAdvanced(_globalCycle);

        // Note: Amulet state processing based on this new cycle
        // happens when processAmuletState is called per-amulet.
    }

    function getGlobalCycle() public view returns (uint256) {
        return _globalCycle;
    }

    function setCycleEffectModifier(uint8 cyclePhase, uint8 traitIndex, int8 modifierValue) public onlyOwner {
        require(cyclePhase < 100, "Cycle phase must be < 100");
        require(traitIndex < 5, InvalidTraitIndex.selector);
        _cycleEffectModifiers[cyclePhase][traitIndex] = modifierValue;
        emit CycleEffectUpdated(cyclePhase, traitIndex, modifierValue);
    }

    function getCycleEffectModifier(uint8 cyclePhase, uint8 traitIndex) public view returns (int8) {
        require(cyclePhase < 100, "Cycle phase must be < 100");
        require(traitIndex < 5, InvalidTraitIndex.selector);
        return _cycleEffectModifiers[cyclePhase][traitIndex];
    }

     function setEmpowerCyclePhase(uint8 phase) public onlyOwner {
        require(phase < 100, "Phase must be < 100");
        _empowerCyclePhase = phase;
        emit EmpowerPhaseUpdated(phase);
     }

     function getEmpowerCyclePhase() public view returns (uint8) {
         return _empowerCyclePhase;
     }


    // --- State Querying & Calculation ---

    function getAmuletData(uint256 tokenId) public view amuletExists(tokenId) returns (Amulet memory) {
        return _amulets[tokenId];
    }

    function getAmuletAgeCycles(uint256 tokenId) public view amuletExists(tokenId) returns (uint256) {
        // Age is measured in cycles since minting
        return _globalCycle - _amulets[tokenId].mintCycle;
    }

    function getAmuletDecayCycles(uint256 tokenId) public view amuletExists(tokenId) returns (uint256) {
        // Cycles passed since state was last processed
        return _globalCycle - _amulets[tokenId].lastProcessedCycle;
    }

    function calculateDecayPenalty(uint256 tokenId, uint8 traitIndex) public view amuletExists(tokenId) returns (uint8) {
        require(traitIndex < 5, InvalidTraitIndex.selector);
        uint256 cyclesElapsed = getAmuletDecayCycles(tokenId);
        uint256 decayAmount = uint256(_decayRatePerCycle) * cyclesElapsed;

        uint8 currentBase = _amulets[tokenId].baseTraitValues[traitIndex];
        return (currentBase > decayAmount) ? uint8(decayAmount) : currentBase;
    }

     function calculateCycleBonusOrPenalty(uint256 tokenId, uint8 traitIndex) public view amuletExists(tokenId) returns (int8) {
         require(traitIndex < 5, InvalidTraitIndex.selector);
         uint8 currentCyclePhase = uint8(_globalCycle % 100);
         int8 modifier = _cycleEffectModifiers[currentCyclePhase][traitIndex];

         // Optional: Add logic where amulet's own traits influence how cycle affects it.
         // e.g., resilience trait reduces negative cycle effects.
         // uint8 resilience = _amulets[tokenId].baseTraitValues[2]; // Example uses trait at index 2
         // modifier = (modifier < 0 && resilience > 0) ? int8(uint8(-modifier) * (255 - resilience) / 255) : modifier; // Reduce penalty based on resilience

         return modifier;
     }


    function calculateEffectiveTrait(uint256 tokenId, uint8 traitIndex) public view amuletExists(tokenId) returns (int256) {
        require(traitIndex < 5, InvalidTraitIndex.selector);

        Amulet memory amulet = _amulets[tokenId];

        // Start with base + empowered
        int256 effectiveValue = int256(amulet.baseTraitValues[traitIndex]) + int256(amulet.empoweredTraitValues[traitIndex]);

        // Subtract decay penalty based on unprocessed cycles
        effectiveValue = effectiveValue - int256(calculateDecayPenalty(tokenId, traitIndex));

        // Add cycle bonus/penalty based on current global cycle
        effectiveValue = effectiveValue + int256(calculateCycleBonusOrPenalty(tokenId, traitIndex));

        // Ensure the value is not negative (traits shouldn't go below 0 effectively)
        return effectiveValue > 0 ? effectiveValue : 0;
    }

    // Returns a summary of the amulet's current state, including calculated effective traits
    function queryEffectiveState(uint256 tokenId) public view amuletExists(tokenId) returns (
        uint256 currentCycle,
        uint256 amuletAgeCycles,
        uint256 decayCycles,
        bool isSoulboundStatus,
        int256[5] memory effectiveTraits
    ) {
        Amulet memory amulet = _amulets[tokenId];

        currentCycle = _globalCycle;
        amuletAgeCycles = currentCycle - amulet.mintCycle;
        decayCycles = currentCycle - amulet.lastProcessedCycle;
        isSoulboundStatus = amulet.isSoulbound;

        for (uint8 i = 0; i < 5; i++) {
            effectiveTraits[i] = calculateEffectiveTrait(tokenId, i);
        }

        return (
            currentCycle,
            amuletAgeCycles,
            decayCycles,
            isSoulboundStatus,
            effectiveTraits
        );
    }


    // --- Admin/Configuration ---

    function setBaseTokenURI(string memory uri) public onlyOwner {
        _baseTokenURI = uri;
    }

    function getBaseTokenURI() public view onlyOwner returns (string memory) {
        return _baseTokenURI;
    }

    function setDecayRate(uint8 decayRatePerCycle) public onlyOwner {
        _decayRatePerCycle = decayRatePerCycle;
        emit DecayRateUpdated(decayRatePerCycle);
    }

    function getDecayRate() public view returns (uint8) {
        return _decayRatePerCycle;
    }

    function setRejuvenationCost(uint256 cost) public onlyOwner {
        _rejuvenationCost = cost;
        emit RejuvenationCostUpdated(cost);
    }

    function getRejuvenationCost() public view returns (uint256) {
        return _rejuvenationCost;
    }

    function setTraitName(uint8 traitIndex, string memory name) public onlyOwner {
        require(traitIndex < 5, InvalidTraitIndex.selector);
        _traitNames[traitIndex] = name;
        emit TraitNameUpdated(traitIndex, name);
    }

    function getTraitName(uint8 traitIndex) public view returns (string memory) {
         require(traitIndex < 5, InvalidTraitIndex.selector);
         return _traitNames[traitIndex];
    }

    function pauseContract() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpauseContract() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    function withdrawFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, NoFundsToWithdraw.selector);
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "Withdrawal failed");
        emit FundsWithdrawn(msg.sender, balance);
    }
}

// Helper library for toString (basic implementation)
library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
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
}
```