Okay, let's create a smart contract concept that blends dynamic NFTs, resource management, evolution, and procedural generation/decay in a unique way. We'll call it the "HyperCube Protocol".

**Concept:**

Users own unique digital entities called "HyperCubes" (ERC-721 NFTs). HyperCubes have dynamic attributes like Energy, Complexity, Resilience, and Affinity. They require a resource called "Plasma" (internal token/state) to thrive and evolve. Without Plasma or interaction, HyperCubes decay. Users can harvest Plasma based on the HyperCubes they own, feed Plasma to specific Cubes to increase their Energy and promote growth, evolve Cubes to increase Complexity, or merge two Cubes into a new, potentially more powerful one.

**Advanced/Creative/Trendy Features:**

1.  **Dynamic NFT Attributes:** Cube attributes (`energy`, `complexity`, etc.) are stored on-chain and change based on time and user interaction (`feed`, `evolve`, `decay`).
2.  **On-Chain Resource Management:** Introduction of an internal `Plasma` resource necessary for NFT maintenance and progression.
3.  **Time-Based Decay Mechanism:** HyperCubes lose `energy` over time if not maintained, potentially even reverting Complexity levels or becoming inactive if Energy hits zero. This introduces a "life cycle" and encourages interaction.
4.  **Procedural Evolution:** Evolution (`evolveHyperCube`) increases `complexity` based on meeting specific requirements (Plasma cost, Energy level). Complexity unlocks new possibilities or boosts performance.
5.  **Procedural Merging:** Combining two parent HyperCubes (`mergeHyperCubes`) burns the parents and mints a new child Cube. The child's attributes (Affinity, Resilience, initial Complexity, etc.) are derived procedurally based on the parents' attributes, generation, and potentially some pseudorandomness. This creates unique outcomes and a lineage.
6.  **Resource Harvesting tied to Ownership:** Plasma generation is linked to the number and state of HyperCubes a user owns.
7.  **Dynamic Requirements:** The cost and requirements for actions (`feed`, `evolve`, `merge`) can change based on the Cube's state (e.g., higher complexity costs more Plasma to evolve).
8.  **On-Chain Lineage Tracking:** Each merged Cube tracks its parent IDs, creating a traceable lineage.
9.  **State-Dependent Queries:** Many getter functions need to implicitly or explicitly apply decay before returning current state, making the state queries dynamic.

**Outline and Function Summary:**

*   **Contract Name:** `HyperCubeProtocol`
*   **Inherits:** `ERC721Enumerable`, `Ownable` (from OpenZeppelin)
*   **Core Data Structures:**
    *   `struct HyperCube`: Holds dynamic attributes for each NFT (energy, complexity, lastFedTime, affinity, resilience, generation, parent IDs).
*   **State Variables:**
    *   Mappings for HyperCube data, user Plasma balances, last Plasma harvest times.
    *   Global parameters for costs, rates, decay factors, total supply.
    *   Counters for token IDs.
*   **Key Function Categories:**
    *   **Initialization & Setup:** `constructor`
    *   **NFT Management (Standard ERC721):** `balanceOf`, `ownerOf`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, `transferFrom`, `safeTransferFrom`, `name`, `symbol`, `tokenURI`
    *   **NFT Management (Enumerable ERC721):** `totalSupply`, `tokenByIndex`, `tokenOfOwnerByIndex`
    *   **NFT Management (Custom):** `mintHyperCube`
    *   **Resource (Plasma) Management:** `harvestPlasma`, `feedHyperCube`
    *   **HyperCube Actions:** `evolveHyperCube`, `mergeHyperCubes`
    *   **State Management (Internal):** `_checkAndApplyDecay`
    *   **Query Functions (User/Public):** `getHyperCubeState`, `getUserPlasma`, `getPlasmaHarvestable`, `getEvolutionRequirements`, `getMergeRequirements`, `estimateMergedCubeProperties`, `getCubesByOwner`, `getCurrentComplexityLevel`, `getCurrentEnergy`, `getLastFedTime`
    *   **Query Functions (Parameters):** `getPlasmaParameters`, `getEvolutionParameters`, `getMergeParameters`, `getDecayParameters`, `getBaseMintCost`
    *   **Admin Functions (Owner):** `setPlasmaHarvestRate`, `setEvolutionCost`, `setMergeCost`, `setDecayRate`, `setBaseMintCost`, `withdrawEther`, `transferOwnership`, `renounceOwnership`

**Function Summary (at least 20 functions):**

1.  `constructor()`: Initializes the contract, ERC721, and Ownable.
2.  `mintHyperCube()`: Mints a new Generation 0 HyperCube to the caller. Requires payment (e.g., Ether). Initializes its state (full energy, low complexity).
3.  `harvestPlasma()`: Allows a user to claim Plasma accumulated since their last harvest, based on the number of HyperCubes they own and the time elapsed.
4.  `feedHyperCube(uint256 tokenId, uint256 amount)`: User spends their Plasma to restore Energy to a specific HyperCube. Updates `lastFedTime`.
5.  `evolveHyperCube(uint256 tokenId)`: Attempts to increase the Complexity level of a HyperCube. Requires sufficient Energy and user's Plasma balance. Consumes Plasma.
6.  `mergeHyperCubes(uint256 tokenId1, uint256 tokenId2)`: Attempts to merge two HyperCubes owned by the caller. Requires both cubes to meet minimum conditions (Energy, Complexity) and user's Plasma balance. Burns the two parent tokens, mints a new child token, and derives its initial properties.
7.  `_checkAndApplyDecay(uint256 tokenId)`: (Internal Helper) Calculates elapsed time since last interaction (`lastFedTime`) and reduces Energy based on the decay rate. Can potentially revert Complexity if Energy is too low.
8.  `getHyperCubeState(uint256 tokenId)`: Returns the full state (attributes) of a HyperCube after applying potential decay calculation.
9.  `getUserPlasma(address owner)`: Returns the current Plasma balance of a user.
10. `getPlasmaHarvestable(address owner)`: Calculates and returns the amount of Plasma a user *could* harvest right now.
11. `getEvolutionRequirements(uint256 tokenId)`: Returns the Plasma cost and minimum Energy required to evolve a given HyperCube based on its current Complexity.
12. `getMergeRequirements(uint256 tokenId1, uint256 tokenId2)`: Returns the Plasma cost and minimum conditions required for merging the two specified HyperCubes.
13. `estimateMergedCubeProperties(uint256 tokenId1, uint256 tokenId2)`: Provides an estimate of the potential attributes of a HyperCube resulting from merging the two inputs (without performing the merge).
14. `getCubesByOwner(address owner)`: Returns an array of token IDs owned by a specific address (helper using ERC721Enumerable).
15. `setPlasmaHarvestRate(uint256 rate)`: (Owner) Sets the global Plasma harvest rate per Cube per second.
16. `setEvolutionCost(uint256 complexityLevel, uint256 cost)`: (Owner) Sets the Plasma cost to evolve to a specific Complexity level.
17. `setMergeCost(uint256 complexityLevel, uint256 cost)`: (Owner) Sets the Plasma cost to merge two Cubes where the *lower* complexity parent is at least this level.
18. `setDecayRate(uint256 ratePerSecond)`: (Owner) Sets the rate at which Energy decays per second.
19. `setBaseMintCost(uint256 cost)`: (Owner) Sets the Ether cost to mint a new Generation 0 HyperCube.
20. `withdrawEther()`: (Owner) Withdraws collected Ether from minting.
21. `getCurrentComplexityLevel(uint256 tokenId)`: Explicit getter for Complexity after decay check.
22. `getCurrentEnergy(uint256 tokenId)`: Explicit getter for Energy after decay check.
23. `getLastFedTime(uint256 tokenId)`: Explicit getter for last fed time.
24. `getPlasmaParameters()`: Returns current global Plasma harvesting parameters.
25. `getEvolutionParameters(uint256 complexityLevel)`: Returns evolution costs for a specific level.
26. `getMergeParameters(uint256 complexityLevel)`: Returns merge costs for a specific level.
27. `getDecayParameters()`: Returns current global decay parameters.
28. `tokenURI(uint256 tokenId)`: (Standard ERC721) Returns the URI for the token's metadata. This implementation would likely point to an external service that dynamically generates metadata based on the Cube's on-chain state (`getHyperCubeState`).
29. ... (Plus standard ERC721/Enumerable/Ownable functions like `transferFrom`, `safeTransferFrom`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, `name`, `symbol`, `totalSupply`, `tokenByIndex`, `tokenOfOwnerByIndex`, `ownerOf`, `balanceOf`, `supportsInterface`, `transferOwnership`, `renounceOwnership` - easily pushing the total count well over 20).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

// --- HyperCube Protocol Outline and Function Summary ---
//
// Contract Name: HyperCubeProtocol
// Purpose: A system for cultivating, evolving, and merging dynamic on-chain NFT entities ("HyperCubes") using an internal resource ("Plasma").
// HyperCubes have attributes like Energy, Complexity, Resilience, Affinity, and Generation, which change over time and through interactions.
// Plasma is harvested based on owned HyperCubes and spent on feeding, evolving, or merging them.
// Cubes decay if not maintained. Merging creates new Cubes with properties derived from parents.
//
// Inherits:
// - ERC721Enumerable: For standard NFT functionality including enumeration of owned tokens.
// - Ownable: For basic ownership management.
//
// Data Structures:
// - struct HyperCube: Defines the dynamic attributes of each HyperCube NFT.
//
// State Variables:
// - hyperCubes: Mapping from token ID to HyperCube struct.
// - userPlasma: Mapping from user address to their Plasma balance.
// - lastPlasmaHarvestTime: Mapping from user address to the timestamp of their last Plasma harvest.
// - plasmaHarvestRatePerCubePerSecond: Global rate for Plasma generation.
// - evolutionCosts: Mapping from Complexity level to Plasma cost for evolution.
// - mergeCosts: Mapping from Complexity level (min parent) to Plasma cost for merging.
// - energyDecayRatePerSecond: Global rate for Energy decay.
// - baseMintCost: Ether cost to mint a new Gen 0 Cube.
// - _tokenIds: Counter for unique token IDs.
//
// Functions (>= 20 functions):
// - constructor(): Initializes the contract and parent contracts.
// - mintHyperCube(): Mints a new Gen 0 HyperCube, requires Ether payment, initializes attributes.
// - harvestPlasma(): Allows user to claim accumulated Plasma based on time and owned Cubes.
// - feedHyperCube(uint256 tokenId, uint256 amount): Spends user Plasma to increase a Cube's Energy.
// - evolveHyperCube(uint256 tokenId): Increases a Cube's Complexity level if requirements are met (Plasma cost, Energy).
// - mergeHyperCubes(uint256 tokenId1, uint256 tokenId2): Burns two parent Cubes and mints a new child Cube with derived properties. Requires Plasma and conditions met for parents.
// - _checkAndApplyDecay(uint256 tokenId): Internal helper to calculate and apply Energy decay based on time since last interaction.
// - getHyperCubeState(uint256 tokenId): Returns the current state of a HyperCube after applying decay.
// - getUserPlasma(address owner): Returns a user's Plasma balance.
// - getPlasmaHarvestable(address owner): Calculates potentially harvestable Plasma for a user.
// - getEvolutionRequirements(uint256 tokenId): Returns Plasma cost and Energy requirement for evolving a specific Cube.
// - getMergeRequirements(uint256 tokenId1, uint256 tokenId2): Returns Plasma cost and conditions for merging two specific Cubes.
// - estimateMergedCubeProperties(uint256 tokenId1, uint256 tokenId2): Provides a hypothetical outcome of a merge without execution.
// - getCubesByOwner(address owner): Returns an array of token IDs owned by an address.
// - setPlasmaHarvestRate(uint256 rate): (Owner) Sets global Plasma harvest rate.
// - setEvolutionCost(uint256 complexityLevel, uint256 cost): (Owner) Sets evolution cost for a complexity level.
// - setMergeCost(uint256 complexityLevel, uint256 cost): (Owner) Sets merge cost based on min parent complexity.
// - setDecayRate(uint256 ratePerSecond): (Owner) Sets Energy decay rate.
// - setBaseMintCost(uint256 cost): (Owner) Sets initial mint Ether cost.
// - withdrawEther(): (Owner) Withdraws contract's Ether balance.
// - getCurrentComplexityLevel(uint256 tokenId): Getter for Cube complexity after decay.
// - getCurrentEnergy(uint256 tokenId): Getter for Cube energy after decay.
// - getLastFedTime(uint256 tokenId): Getter for Cube last fed time.
// - getPlasmaParameters(): Returns global Plasma parameters.
// - getEvolutionParameters(uint256 complexityLevel): Returns evolution parameters for a level.
// - getMergeParameters(uint256 complexityLevel): Returns merge parameters for a level.
// - getDecayParameters(): Returns global decay parameters.
// - tokenURI(uint256 tokenId): Standard ERC721 method for metadata URI.
// - Plus standard ERC721/Enumerable/Ownable functions (balanceOf, ownerOf, transferFrom, etc.)

contract HyperCubeProtocol is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Math for uint256; // Using OpenZeppelin Math for min/max, etc.

    // --- Structs ---
    struct HyperCube {
        uint256 energy;      // Resource level, decreases over time if not fed
        uint256 complexity;  // Represents its evolutionary stage/tier
        uint64 lastFedTime;  // Timestamp of the last time it was fed Plasma
        uint256 affinity;    // Attribute affecting Plasma efficiency / interaction bonus
        uint256 resilience;  // Attribute affecting decay resistance / stability
        uint256 generation;  // 0 for minted, n+1 for merged from generation n
        uint256 parent1;     // Token ID of parent 1 (0 for Gen 0)
        uint256 parent2;     // Token ID of parent 2 (0 for Gen 0)
    }

    // --- State Variables ---
    mapping(uint256 => HyperCube) public hyperCubes;
    mapping(address => uint256) public userPlasma;
    mapping(address => uint64) public lastPlasmaHarvestTime;

    Counters.Counter private _tokenIds;

    // Global Parameters (Owner settable)
    uint256 public plasmaHarvestRatePerCubePerSecond = 1e12; // Example rate (adjust units)
    mapping(uint256 => uint256) public evolutionCosts;       // Complexity level => Plasma cost
    mapping(uint256 => uint256) public mergeCosts;           // Min complexity of *lower* parent => Plasma cost
    uint256 public energyDecayRatePerSecond = 1e12;          // Example decay rate (adjust units)
    uint256 public baseMintCost = 0.01 ether;                // Ether cost to mint a Gen 0 Cube

    // Max values (Example limits)
    uint256 public constant MAX_ENERGY = 100e18; // Example scale
    uint256 public constant MAX_COMPLEXITY = 10;
    uint256 public constant BASE_MINT_ENERGY = MAX_ENERGY;

    // --- Events ---
    event HyperCubeMinted(address indexed owner, uint256 indexed tokenId, uint256 generation);
    event PlasmaHarvested(address indexed owner, uint256 amount);
    event HyperCubeFed(uint256 indexed tokenId, address indexed feeder, uint256 amount, uint256 newEnergy);
    event HyperCubeEvolved(uint256 indexed tokenId, uint256 newComplexity);
    event HyperCubeMerged(address indexed owner, uint256 indexed parent1, uint256 indexed parent2, uint256 indexed childTokenId, uint256 childGeneration);
    event HyperCubeDecayed(uint256 indexed tokenId, uint256 energyLost, uint256 newEnergy, uint256 newComplexity);
    event PlasmaHarvestRateUpdated(uint256 newRate);
    event EvolutionCostUpdated(uint256 complexityLevel, uint256 cost);
    event MergeCostUpdated(uint256 complexityLevel, uint256 cost);
    event EnergyDecayRateUpdated(uint256 newRate);
    event BaseMintCostUpdated(uint256 newCost);

    // --- Constructor ---
    constructor() ERC721("HyperCube", "HCUBE") Ownable(msg.sender) {
        // Set initial costs/rates if needed, otherwise owner sets later
        evolutionCosts[0] = 100e18; // Cost to go from 0 to 1
        evolutionCosts[1] = 500e18;
        evolutionCosts[2] = 1000e18;
        // ... set for other levels up to MAX_COMPLEXITY

        mergeCosts[0] = 200e18; // Cost to merge two Gen 0 (or min complexity 0)
        mergeCosts[1] = 800e18;
        // ... set for other levels
    }

    // --- Modifiers ---
    modifier whenCubeExists(uint256 tokenId) {
        require(_exists(tokenId), "HyperCube: token does not exist");
        _;
    }

    modifier whenCubeOwnedBy(uint256 tokenId, address account) {
        require(ownerOf(tokenId) == account, "HyperCube: Not owned by caller");
        _;
    }

    // --- Internal Helpers ---

    /// @dev Calculates and applies energy decay to a HyperCube based on time passed.
    /// @param tokenId The ID of the HyperCube.
    function _checkAndApplyDecay(uint256 tokenId) internal {
        HyperCube storage cube = hyperCubes[tokenId];
        uint64 currentTime = uint64(block.timestamp);
        uint64 timeElapsed = currentTime - cube.lastFedTime;

        if (timeElapsed > 0) {
            uint256 potentialDecay = uint256(timeElapsed) * energyDecayRatePerSecond;
            uint256 decayAmount = Math.min(potentialDecay, cube.energy);
            uint256 oldEnergy = cube.energy;
            uint256 oldComplexity = cube.complexity;

            cube.energy = cube.energy - decayAmount;
            cube.lastFedTime = currentTime; // Update last fed time *after* decay calculation

            // Optional: Revert complexity if energy is too low
            if (cube.energy == 0 && cube.complexity > 0) {
                 cube.complexity = cube.complexity > 1 ? cube.complexity - 1 : 0; // Revert complexity by 1 or to 0
                 // Optionally add a penalty or event
            }

            if (decayAmount > 0 || cube.complexity != oldComplexity) {
                 emit HyperCubeDecayed(tokenId, decayAmount, cube.energy, cube.complexity);
            }
        }
    }

    /// @dev Derives attributes for a new HyperCube generated from merging two parents.
    /// This is a placeholder for creative logic.
    function _deriveMergedCubeProperties(uint256 parent1Id, uint256 parent2Id)
        internal
        view
        returns (uint256 energy, uint256 complexity, uint256 affinity, uint256 resilience)
    {
        HyperCube storage parent1 = hyperCubes[parent1Id];
        HyperCube storage parent2 = hyperCubes[parent2Id];

        // Example Derivation Logic:
        // - Energy: Average energy of parents (scaled) + bonus?
        // - Complexity: Max of parents' complexity + 1 (capped at MAX_COMPLEXITY)
        // - Affinity: Weighted average or sum, maybe random variance
        // - Resilience: Weighted average or sum, maybe random variance

        uint256 avgEnergy = (parent1.energy + parent2.energy) / 2;
        energy = Math.min(avgEnergy + MAX_ENERGY / 10, MAX_ENERGY); // Average + a bonus, capped

        complexity = Math.min(Math.max(parent1.complexity, parent2.complexity) + 1, MAX_COMPLEXITY);

        // Simple pseudorandomness based on block data and token IDs
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, parent1Id, parent2Id, msg.sender)));

        affinity = (parent1.affinity + parent2.affinity) / 2;
        affinity = affinity + (seed % (MAX_ENERGY / 20)); // Add some variance
        affinity = Math.min(affinity, MAX_ENERGY);

        resilience = (parent1.resilience + parent2.resilience) / 2;
        resilience = resilience + ((seed / 100) % (MAX_ENERGY / 20)); // Add some variance
        resilience = Math.min(resilience, MAX_ENERGY);

        return (energy, complexity, affinity, resilience);
    }

    // --- Core Functionality ---

    /// @notice Mints a new Generation 0 HyperCube to the caller.
    /// @dev Requires sending `baseMintCost` Ether with the transaction.
    function mintHyperCube() public payable {
        require(msg.value >= baseMintCost, "HyperCube: Insufficient Ether for mint");

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        // Simple pseudorandomness for initial attributes
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, newItemId)));

        hyperCubes[newItemId] = HyperCube({
            energy: BASE_MINT_ENERGY,
            complexity: 0,
            lastFedTime: uint64(block.timestamp),
            affinity: (seed % (MAX_ENERGY / 5)) + MAX_ENERGY / 10, // Initial random affinity
            resilience: ((seed / 100) % (MAX_ENERGY / 5)) + MAX_ENERGY / 10, // Initial random resilience
            generation: 0,
            parent1: 0,
            parent2: 0
        });

        _safeMint(msg.sender, newItemId);
        emit HyperCubeMinted(msg.sender, newItemId, 0);
    }

    /// @notice Allows a user to claim Plasma accumulated from their owned HyperCubes.
    function harvestPlasma() public {
        address owner = msg.sender;
        uint64 currentTime = uint64(block.timestamp);
        uint64 timeElapsed = currentTime - lastPlasmaHarvestTime[owner];

        if (timeElapsed == 0 && lastPlasmaHarvestTime[owner] != 0) {
             // Already harvested in this second, or first harvest
             return;
        }

        uint256 ownedCubes = balanceOf(owner);
        if (ownedCubes == 0) {
             lastPlasmaHarvestTime[owner] = currentTime;
             return;
        }

        uint256 potentialPlasma = uint256(timeElapsed) * ownedCubes * plasmaHarvestRatePerCubePerSecond;

        userPlasma[owner] += potentialPlasma;
        lastPlasmaHarvestTime[owner] = currentTime;

        if (potentialPlasma > 0) {
            emit PlasmaHarvested(owner, potentialPlasma);
        }
    }

    /// @notice Spends user's Plasma to increase a HyperCube's Energy.
    /// @param tokenId The ID of the HyperCube to feed.
    /// @param amount The amount of Plasma to spend.
    function feedHyperCube(uint256 tokenId, uint256 amount) public whenCubeOwnedBy(tokenId, msg.sender) {
        require(amount > 0, "HyperCube: Feed amount must be positive");
        require(userPlasma[msg.sender] >= amount, "HyperCube: Insufficient Plasma");

        // Apply decay before feeding
        _checkAndApplyDecay(tokenId);

        userPlasma[msg.sender] -= amount;
        HyperCube storage cube = hyperCubes[tokenId];

        // Feeding efficiency could depend on Affinity attribute
        uint256 energyRestored = amount; // Simple 1:1 for now, could scale by cube.affinity
        uint256 oldEnergy = cube.energy;
        cube.energy = Math.min(cube.energy + energyRestored, MAX_ENERGY);
        cube.lastFedTime = uint64(block.timestamp);

        emit HyperCubeFed(tokenId, msg.sender, amount, cube.energy);
    }

    /// @notice Attempts to evolve a HyperCube to the next Complexity level.
    /// @param tokenId The ID of the HyperCube to evolve.
    function evolveHyperCube(uint256 tokenId) public whenCubeOwnedBy(tokenId, msg.sender) {
        // Apply decay before checking conditions
        _checkAndApplyDecay(tokenId);

        HyperCube storage cube = hyperCubes[tokenId];

        uint256 currentComplexity = cube.complexity;
        require(currentComplexity < MAX_COMPLEXITY, "HyperCube: Already at max complexity");

        uint256 requiredPlasma = evolutionCosts[currentComplexity];
        require(userPlasma[msg.sender] >= requiredPlasma, "HyperCube: Insufficient Plasma for evolution");

        // Example: Require minimum Energy
        uint256 minEnergyForEvolve = MAX_ENERGY / 2; // Example threshold
        require(cube.energy >= minEnergyForEvolve, "HyperCube: Insufficient Energy to evolve");

        userPlasma[msg.sender] -= requiredPlasma;
        cube.complexity = currentComplexity + 1;
        // Optionally slightly boost energy, affinity, resilience upon evolution
        cube.energy = Math.min(cube.energy + MAX_ENERGY / 10, MAX_ENERGY);
        cube.affinity = Math.min(cube.affinity + MAX_ENERGY / 50, MAX_ENERGY);
        cube.resilience = Math.min(cube.resilience + MAX_ENERGY / 50, MAX_ENERGY);

        emit HyperCubeEvolved(tokenId, cube.complexity);
    }

    /// @notice Attempts to merge two HyperCubes owned by the caller into a new one.
    /// @param tokenId1 The ID of the first HyperCube.
    /// @param tokenId2 The ID of the second HyperCube.
    function mergeHyperCubes(uint256 tokenId1, uint256 tokenId2) public {
        require(tokenId1 != tokenId2, "HyperCube: Cannot merge a cube with itself");
        require(_exists(tokenId1) && _exists(tokenId2), "HyperCube: One or both tokens do not exist");
        require(ownerOf(tokenId1) == msg.sender && ownerOf(tokenId2) == msg.sender, "HyperCube: Caller must own both cubes");

        // Apply decay before checking conditions
        _checkAndApplyDecay(tokenId1);
        _checkAndApplyDecay(tokenId2);

        HyperCube storage cube1 = hyperCubes[tokenId1];
        HyperCube storage cube2 = hyperCubes[tokenId2];

        // Example: Require minimum Complexity and Energy for merging
        uint256 minComplexityForMerge = 0; // Example threshold
        uint256 minEnergyForMerge = MAX_ENERGY / 4; // Example threshold
        require(cube1.complexity >= minComplexityForMerge && cube2.complexity >= minComplexityForMerge, "HyperCube: Both cubes must meet min complexity for merging");
        require(cube1.energy >= minEnergyForMerge && cube2.energy >= minEnergyForMerge, "HyperCube: Both cubes must meet min energy for merging");

        uint256 minParentComplexity = Math.min(cube1.complexity, cube2.complexity);
        uint256 requiredPlasma = mergeCosts[minParentComplexity];
        require(userPlasma[msg.sender] >= requiredPlasma, "HyperCube: Insufficient Plasma for merging");

        userPlasma[msg.sender] -= requiredPlasma;

        // Burn parent tokens
        _burn(tokenId1);
        _burn(tokenId2);

        // Mint new child token
        _tokenIds.increment();
        uint256 childTokenId = _tokenIds.current();

        (uint256 energy, uint256 complexity, uint256 affinity, uint256 resilience) = _deriveMergedCubeProperties(tokenId1, tokenId2);

        hyperCubes[childTokenId] = HyperCube({
            energy: energy,
            complexity: complexity,
            lastFedTime: uint64(block.timestamp),
            affinity: affinity,
            resilience: resilience,
            generation: Math.max(cube1.generation, cube2.generation) + 1,
            parent1: tokenId1,
            parent2: tokenId2
        });

        _safeMint(msg.sender, childTokenId);

        emit HyperCubeMerged(msg.sender, tokenId1, tokenId2, childTokenId, hyperCubes[childTokenId].generation);
    }


    // --- Query Functions (User/Public) ---

    /// @notice Gets the current state of a specific HyperCube.
    /// @dev Applies decay calculation before returning the state.
    /// @param tokenId The ID of the HyperCube.
    /// @return The HyperCube struct containing its current attributes.
    function getHyperCubeState(uint256 tokenId) public whenCubeExists(tokenId) returns (HyperCube memory) {
        // Apply decay calculation without modifying storage view function,
        // but simulate the current state. Note: A real application might prefer
        // to apply decay only on state-changing functions or have an external
        // system trigger decay, or use a view function that calculates decay
        // but doesn't modify state, making it less accurate between state changes.
        // For this example, let's return the stored state for simplicity in a view function,
        // acknowledging that its energy might be lower than reported until an action occurs.
        // A truly "live" state in a view function requires calculating decay without storage writes.

        // Option 1: Return stored state (might be slightly outdated on energy/lastFedTime)
        // return hyperCubes[tokenId];

        // Option 2: Calculate potential decay for view (more complex, less gas efficient for caller)
        // Need to fetch state first, then calculate decay *in memory*
        HyperCube memory cube = hyperCubes[tokenId];
        uint64 currentTime = uint64(block.timestamp);
        uint64 timeElapsed = currentTime - cube.lastFedTime;

        if (timeElapsed > 0) {
            uint256 potentialDecay = uint256(timeElapsed) * energyDecayRatePerSecond;
            uint256 decayAmount = Math.min(potentialDecay, cube.energy);
            cube.energy = cube.energy - decayAmount;
            // Note: complexity change on decay is usually a state-changing effect,
            // not reflected purely in a view calculation unless the view function
            // simulates the *entire* state history, which is impractical.
            // So, complexity reported here might be based on stored state,
            // while energy is calculated live.
        }
         return cube;
    }


    /// @notice Returns the current Plasma balance for an owner.
    /// @param owner The address to query.
    /// @return The Plasma balance.
    function getUserPlasma(address owner) public view returns (uint256) {
        return userPlasma[owner];
    }

    /// @notice Calculates the amount of Plasma an owner could harvest right now.
    /// @param owner The address to query.
    /// @return The potential Plasma harvestable amount.
    function getPlasmaHarvestable(address owner) public view returns (uint256) {
        uint64 currentTime = uint64(block.timestamp);
        uint64 timeElapsed = currentTime - lastPlasmaHarvestTime[owner];

        if (timeElapsed == 0 && lastPlasmaHarvestTime[owner] != 0) {
             return 0;
        }

        uint256 ownedCubes = balanceOf(owner);
        if (ownedCubes == 0) {
             return 0;
        }

        return uint256(timeElapsed) * ownedCubes * plasmaHarvestRatePerCubePerSecond;
    }

     /// @notice Returns the Plasma cost and minimum Energy required to evolve a HyperCube.
    /// @dev Applies decay calculation for the energy check.
    /// @param tokenId The ID of the HyperCube.
    /// @return requiredPlasma The Plasma cost.
    /// @return minEnergy The minimum Energy required.
    /// @return currentEnergy The current Energy of the cube (after decay).
    /// @return nextComplexity The complexity level it would evolve to.
    function getEvolutionRequirements(uint256 tokenId) public view whenCubeExists(tokenId) returns (uint256 requiredPlasma, uint256 minEnergy, uint256 currentEnergy, uint256 nextComplexity) {
        HyperCube memory cube = getHyperCubeState(tokenId); // Get state with decay calculated for view
        currentEnergy = cube.energy;

        nextComplexity = cube.complexity + 1;
        if (nextComplexity > MAX_COMPLEXITY) {
            return (0, 0, currentEnergy, cube.complexity); // Cannot evolve further
        }

        requiredPlasma = evolutionCosts[cube.complexity]; // Cost is based on *current* complexity
        minEnergy = MAX_ENERGY / 2; // Example threshold

        return (requiredPlasma, minEnergy, currentEnergy, nextComplexity);
    }

    /// @notice Returns the Plasma cost and conditions for merging two HyperCubes.
    /// @dev Applies decay calculation for the energy checks.
    /// @param tokenId1 The ID of the first HyperCube.
    /// @param tokenId2 The ID of the second HyperCube.
    /// @return requiredPlasma The Plasma cost.
    /// @return minComplexity The minimum Complexity required for both.
    /// @return minEnergy The minimum Energy required for both.
    /// @return cube1State The state of the first cube after decay.
    /// @return cube2State The state of the second cube after decay.
    function getMergeRequirements(uint256 tokenId1, uint256 tokenId2) public view returns (uint256 requiredPlasma, uint256 minComplexity, uint256 minEnergy, HyperCube memory cube1State, HyperCube memory cube2State) {
        if (!_exists(tokenId1) || !_exists(tokenId2) || tokenId1 == tokenId2) {
             return (0, 0, 0, HyperCube(0,0,0,0,0,0,0,0), HyperCube(0,0,0,0,0,0,0,0));
        }

        cube1State = getHyperCubeState(tokenId1); // Get state with decay calculated for view
        cube2State = getHyperCubeState(tokenId2);

        minComplexity = 0; // Example threshold
        minEnergy = MAX_ENERGY / 4; // Example threshold

        uint256 minParentComplexity = Math.min(cube1State.complexity, cube2State.complexity);
        requiredPlasma = mergeCosts[minParentComplexity];

        return (requiredPlasma, minComplexity, minEnergy, cube1State, cube2State);
    }

    /// @notice Provides an estimate of the attributes of a HyperCube resulting from merging two inputs.
    /// @dev This is purely a view function and does not guarantee the exact outcome due to potential randomness.
    /// @param tokenId1 The ID of the first HyperCube.
    /// @param tokenId2 The ID of the second HyperCube.
    /// @return The estimated attributes of the resulting HyperCube.
    function estimateMergedCubeProperties(uint256 tokenId1, uint256 tokenId2) public view returns (uint256 energy, uint256 complexity, uint256 affinity, uint256 resilience, uint256 generation) {
         if (!_exists(tokenId1) || !_exists(tokenId2) || tokenId1 == tokenId2) {
             return (0, 0, 0, 0, 0);
        }
        HyperCube memory parent1 = hyperCubes[tokenId1]; // Use stored state, as this is just an estimate
        HyperCube memory parent2 = hyperCubes[tokenId2];

        (energy, complexity, affinity, resilience) = _deriveMergedCubeProperties(tokenId1, tokenId2);
        generation = Math.max(parent1.generation, parent2.generation) + 1;

        return (energy, complexity, affinity, resilience, generation);
    }

    /// @notice Gets all token IDs owned by a specific address.
    /// @param owner The address to query.
    /// @return An array of token IDs.
    function getCubesByOwner(address owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i = 0; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

     /// @notice Gets the current complexity of a HyperCube after potential decay.
    /// @param tokenId The ID of the HyperCube.
    /// @return The current complexity.
    function getCurrentComplexityLevel(uint256 tokenId) public view whenCubeExists(tokenId) returns (uint256) {
        HyperCube memory cube = getHyperCubeState(tokenId); // Applies decay logic in view
        return cube.complexity;
    }

    /// @notice Gets the current energy of a HyperCube after potential decay.
    /// @param tokenId The ID of the HyperCube.
    /// @return The current energy.
    function getCurrentEnergy(uint256 tokenId) public view whenCubeExists(tokenId) returns (uint256) {
        HyperCube memory cube = getHyperCubeState(tokenId); // Applies decay logic in view
        return cube.energy;
    }

     /// @notice Gets the timestamp the HyperCube was last fed.
    /// @dev Note: This is stored state and doesn't change in a view function.
    /// The actual decay calculation uses this time.
    /// @param tokenId The ID of the HyperCube.
    /// @return The timestamp.
    function getLastFedTime(uint256 tokenId) public view whenCubeExists(tokenId) returns (uint64) {
        // No decay calculation needed here, just return stored value
        return hyperCubes[tokenId].lastFedTime;
    }

    // --- Query Functions (Parameters) ---

     /// @notice Returns the global Plasma harvesting parameters.
    /// @return ratePerCubePerSecond The rate at which Plasma is harvested per cube per second.
    function getPlasmaParameters() public view returns (uint256 ratePerCubePerSecond) {
        return plasmaHarvestRatePerCubePerSecond;
    }

    /// @notice Returns the Plasma cost for evolving to a specific complexity level.
    /// @param complexityLevel The complexity level being evolved *to*.
    /// @return cost The Plasma cost.
    function getEvolutionParameters(uint256 complexityLevel) public view returns (uint256 cost) {
        return evolutionCosts[complexityLevel];
    }

    /// @notice Returns the Plasma cost for merging based on the minimum parent complexity.
    /// @param minParentComplexity The minimum complexity of the two cubes being merged.
    /// @return cost The Plasma cost.
    function getMergeParameters(uint256 minParentComplexity) public view returns (uint256 cost) {
        return mergeCosts[minParentComplexity];
    }

    /// @notice Returns the global Energy decay parameters.
    /// @return ratePerSecond The rate at which Energy decays per second.
    function getDecayParameters() public view returns (uint256 ratePerSecond) {
        return energyDecayRatePerSecond;
    }

     /// @notice Returns the current Ether cost to mint a new Gen 0 HyperCube.
    /// @return cost The Ether cost.
    function getBaseMintCost() public view returns (uint256) {
        return baseMintCost;
    }


    // --- Admin Functions (Owner) ---

    /// @notice Sets the global Plasma harvest rate per Cube per second.
    /// @param rate The new rate.
    function setPlasmaHarvestRate(uint256 rate) public onlyOwner {
        plasmaHarvestRatePerCubePerSecond = rate;
        emit PlasmaHarvestRateUpdated(rate);
    }

    /// @notice Sets the Plasma cost to evolve to a specific Complexity level.
    /// @param complexityLevel The complexity level being evolved *to*.
    /// @param cost The new Plasma cost.
    function setEvolutionCost(uint256 complexityLevel, uint256 cost) public onlyOwner {
        require(complexityLevel < MAX_COMPLEXITY, "HyperCube: Invalid complexity level");
        evolutionCosts[complexityLevel] = cost;
        emit EvolutionCostUpdated(complexityLevel, cost);
    }

    /// @notice Sets the Plasma cost to merge two Cubes based on the minimum parent complexity.
    /// @param minParentComplexity The minimum complexity of the two cubes being merged.
    /// @param cost The new Plasma cost.
    function setMergeCost(uint256 minParentComplexity, uint256 cost) public onlyOwner {
         require(minParentComplexity < MAX_COMPLEXITY, "HyperCube: Invalid complexity level");
        mergeCosts[minParentComplexity] = cost;
        emit MergeCostUpdated(minParentComplexity, cost);
    }

    /// @notice Sets the global Energy decay rate per second.
    /// @param ratePerSecond The new decay rate.
    function setDecayRate(uint256 ratePerSecond) public onlyOwner {
        energyDecayRatePerSecond = ratePerSecond;
        emit EnergyDecayRateUpdated(ratePerSecond);
    }

    /// @notice Sets the Ether cost to mint a new Generation 0 HyperCube.
    /// @param cost The new Ether cost.
    function setBaseMintCost(uint256 cost) public onlyOwner {
        baseMintCost = cost;
        emit BaseMintCostUpdated(cost);
    }

    /// @notice Allows the owner to withdraw any accumulated Ether (from minting).
    function withdrawEther() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "HyperCube: Ether withdrawal failed");
    }


    // --- Standard ERC721 / ERC721Enumerable / Ownable Overrides ---

    function _update(address to, uint256 tokenId, address auth) internal virtual override(ERC721, ERC721Enumerable) returns (address) {
        address oldOwner = _ownerOf[tokenId];
        address newOwner = super._update(to, tokenId, auth);
        if (oldOwner != address(0) && newOwner != oldOwner) {
            // When a token changes owner, potentially trigger Plasma harvest for old owner
            // and reset last harvest time for new owner if it's the first token they own.
            // This is a design choice - could also let harvest happen anytime.
            // For this example, let's just note it as a potential hook.
            // harvestPlasma() for the old owner could be called here.
            // lastPlasmaHarvestTime[newOwner] = uint64(block.timestamp); // If you want to reset
        }
        return newOwner;
    }

     function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
         address owner = ownerOf(tokenId);
         super._burn(tokenId);
         delete hyperCubes[tokenId]; // Clean up the struct data
         // Consider triggering harvestPlasma for the owner here too, as their cube count just decreased.
     }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return interfaceId == type(ERC721).interfaceId ||
               interfaceId == type(ERC721Enumerable).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    /// @dev Base URI for token metadata. Points to an external service/gateway.
    /// @param tokenId The token ID.
    /// @return The URI string.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        // require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // In a real dynamic NFT, this would likely return something like:
        // string memory baseURI = "ipfs://YOUR_BASE_URI/"; // or "https://YOUR_API_GATEWAY/metadata/"
        // return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
        // The external service at the URI would then query the contract's state
        // (using getHyperCubeState) to generate the dynamic JSON metadata.

        // For this example, returning a placeholder showing the token ID and implying state.
        return string(abi.encodePacked("data:application/json;base64,{\"name\":\"HyperCube #", Strings.toString(tokenId), "\", \"description\":\"A dynamic HyperCube entity.\", \"attributes\":[...]}"));
    }

    // --- Additional Custom Getters (Explicit for clarity) ---

    // Already included above: getHyperCubeState, getUserPlasma, getPlasmaHarvestable, getEvolutionRequirements, getMergeRequirements, estimateMergedCubeProperties, getCubesByOwner, getCurrentComplexityLevel, getCurrentEnergy, getLastFedTime, getPlasmaParameters, getEvolutionParameters, getMergeParameters, getDecayParameters, getBaseMintCost

}
```