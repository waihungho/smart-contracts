Okay, let's design a smart contract for an "Eternal Art Engine". This contract will manage generative art pieces (NFTs) that evolve over time based on internal state, interactions, and potentially external triggers.

The core concept: Each NFT (`CosmicFragment`) represents a point or entity within a dynamic, procedural system. Its visual representation is determined by a set of on-chain parameters that change based on energy levels, complexity, time, and interactions with other fragments. The contract manages this state, while the actual *rendering* of the art (the image/SVG) happens off-chain based on querying these parameters via `tokenURI`.

This incorporates:
*   **Generative Art:** Storing parameters on-chain, requiring an off-chain renderer.
*   **State-Based Evolution:** NFTs are not static; their parameters change based on defined rules.
*   **Internal Resources:** Fragments have "Energy" which is required for evolution and interactions.
*   **Time-Based Mechanics:** Evolution can be triggered by time passing (if energy is available).
*   **Complex Interactions:** Functions like fusing fragments or seeding new ones.
*   **Pseudo-Randomness:** Using on-chain data for parameter changes (with caveats about security).
*   **Parameter Space Navigation:** A conceptual layer where fragments have "coordinates" that influence interactions.

This goes beyond standard ERC721 by adding a rich layer of state and interaction logic tied to the token ID.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Note: For production, a secure oracle like Chainlink VRF should be used for true randomness.
// The pseudo-randomness used here (blockhash, timestamp, etc.) is predictable.
// Off-chain rendering logic is required for tokenURI.

/**
 * @title EternalArtEngine
 * @dev A smart contract for managing evolving generative art NFTs (Cosmic Fragments).
 * Each fragment has state (energy, complexity, parameters) that changes based on time, interactions, and owner actions.
 * The contract stores the parameters, and an external service renders the art based on these parameters via tokenURI.
 */
contract EternalArtEngine is ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;

    // --- State Structures ---

    /**
     * @dev Represents the state of a Cosmic Fragment.
     * @param seed Initial unique identifier influencing initial parameters.
     * @param energy Current energy level. Required for evolution and interactions.
     * @param complexity A value influencing the generative algorithm's structure/depth.
     * @param lastEvolutionTime Timestamp of the last time the fragment's state evolved.
     * @param parameters A dynamic array storing various numeric parameters for the generative art algorithm.
     * @param coords Conceptual coordinates within a procedural space, influencing certain interactions.
     */
    struct FragmentState {
        uint256 seed;
        uint256 energy;
        uint256 complexity;
        uint256 lastEvolutionTime;
        int256[] parameters; // Using int256 for potential negative parameters
        int256[] coords; // e.g., [x, y, z]
    }

    // --- Mappings and Storage ---

    mapping(uint256 => FragmentState) private _fragmentStates;

    // --- Configuration Parameters (Admin Settable) ---

    uint256 public baseEvolutionCost = 100; // Energy cost per evolution
    uint256 public energyDecayRate = 1; // Energy lost per time unit since last evolution (e.g., per hour)
    uint256 public energyDecayInterval = 1 hours; // Time unit for decay
    uint256 public complexityGrowthFactor = 5; // Complexity gained per evolution
    uint256 public evolutionCooldown = 1 days; // Minimum time between manual/timed evolutions
    uint256 public fuseEnergyCost = 500; // Energy cost to fuse fragments
    uint256 public seedChildEnergyCost = 1000; // Energy cost to seed a new fragment
    uint256 public navigateCost = 50; // Energy cost for navigation
    uint256 public minEnergyForTimedEvolution = 50; // Min energy required for external trigger
    uint256 public parameterTweakCost = 10; // Energy cost per parameter tweak
    uint256 public parameterRandomizeCost = 50; // Energy cost to re-randomize parameters

    // Initial parameters configuration (indices map to specific roles in off-chain renderer)
    uint256 public initialParameterCount = 5;
    int256 public initialParameterMin = -100;
    int256 public initialParameterMax = 100;

    string private _rendererBaseURI; // Base URI for the off-chain renderer service

    // --- Events ---

    event FragmentMinted(uint256 indexed tokenId, address indexed owner, uint256 seed);
    event FragmentEvolved(uint256 indexed tokenId, uint256 newComplexity, uint256 newEnergy);
    event EnergyInjected(uint256 indexed tokenId, address indexed injector, uint256 amount, uint256 newEnergy);
    event FragmentsFused(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 resultingComplexity, uint256 resultingEnergy);
    event FragmentDetonated(uint256 indexed tokenId, address indexed owner, uint256 finalEnergy, uint256 yieldedSeed);
    event ChildFragmentSeeded(uint256 indexed parentTokenId, uint256 indexed childTokenId, uint256 parentEnergyRemaining);
    event ParametersUpdated(uint256 indexed tokenId);
    event FragmentNavigated(uint256 indexed tokenId, int256[] newCoords);

    // --- Constructor ---

    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {}

    // --- Internal Helper Functions ---

    /**
     * @dev Generates a pseudo-random seed based on block data and token ID.
     * Note: Not cryptographically secure.
     */
    function _generatePseudoRandomSeed(uint256 tokenId) internal view returns (uint256) {
        uint256 blockValue = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, tx.origin, block.coinbase)));
        return uint256(keccak256(abi.encodePacked(blockValue, tokenId, block.number)));
    }

    /**
     * @dev Calculates the energy decay for a fragment since its last evolution.
     * @param lastEvolution The timestamp of the last evolution.
     * @param currentEnergy The current energy level.
     * @return The new energy level after applying decay.
     */
    function _calculateEnergyDecay(uint256 lastEvolution, uint256 currentEnergy) internal view returns (uint256) {
        if (block.timestamp <= lastEvolution) {
            return currentEnergy; // No time passed, no decay
        }
        uint256 timeElapsed = block.timestamp - lastEvolution;
        uint256 decayIntervals = timeElapsed / energyDecayInterval;
        uint256 decayAmount = decayIntervals.mul(energyDecayRate);
        return currentEnergy > decayAmount ? currentEnergy.sub(decayAmount) : 0;
    }

    /**
     * @dev Applies the core evolution logic, modifying parameters and state.
     * Internal function called by manual, timed, fuse, and seed evolution paths.
     * Uses pseudo-randomness derived from the fragment's seed and current state.
     * @param tokenId The ID of the fragment to evolve.
     */
    function _applyEvolutionLogic(uint256 tokenId) internal {
        FragmentState storage fragment = _fragmentStates[tokenId];

        // Calculate and apply energy decay before evolution logic
        uint256 currentEnergy = _calculateEnergyDecay(fragment.lastEvolutionTime, fragment.energy);
        fragment.energy = currentEnergy; // Update energy state

        // Check energy requirement *after* decay
        require(fragment.energy >= baseEvolutionCost, "Insufficient energy for evolution");

        fragment.energy = fragment.energy.sub(baseEvolutionCost);
        fragment.complexity = fragment.complexity.add(complexityGrowthFactor);
        fragment.lastEvolutionTime = block.timestamp;

        // --- Parameter Evolution Logic ---
        // This is where the core generative art logic influences parameter changes.
        // The pseudo-randomness source should incorporate fragment-specific data.
        uint256 randomness = uint256(keccak256(abi.encodePacked(fragment.seed, fragment.complexity, fragment.energy, block.timestamp, block.number, tx.gasprice)));

        for (uint i = 0; i < fragment.parameters.length; i++) {
            // Example parameter evolution: simple weighted randomness and complexity influence
            // The exact logic here determines the art's behavior over time.
            int256 currentValue = fragment.parameters[i];
            int256 delta;

            // Use parts of the randomness for different parameters
            uint256 paramRandomness = uint256(keccak256(abi.encodePacked(randomness, i)));

            // Simple random delta calculation (can be made more complex)
            int256 randomDelta = int256(paramRandomness % 21) - 10; // Random delta between -10 and +10

            // Influence of complexity and current value (example logic)
            // Complexity could increase volatility or bias changes
            int256 complexityInfluence = int256(fragment.complexity % 5) - 2; // Simple example

            // Apply a change
            delta = randomDelta + complexityInfluence;

            // New value: current + delta
            int256 newValue = currentValue + delta;

            // Optional: Keep parameters within a certain range
            // For simplicity, let's allow unbounded parameters for now,
            // but a real system might clamp them or normalize for rendering.

            fragment.parameters[i] = newValue;
        }

        emit FragmentEvolved(tokenId, fragment.complexity, fragment.energy);
        emit ParametersUpdated(tokenId);
    }

    /**
     * @dev Initializes the parameters for a new fragment based on its seed.
     */
    function _initializeParameters(uint256 tokenId, uint256 seed) internal returns (int256[] memory) {
        int256[] memory params = new int256[](initialParameterCount);
        uint256 randomness = uint256(keccak256(abi.encodePacked(seed, block.timestamp, block.number)));

        for (uint i = 0; i < initialParameterCount; i++) {
            uint256 paramRandomness = uint256(keccak256(abi.encodePacked(randomness, i)));
            // Generate initial parameter value within range
            int256 range = initialParameterMax - initialParameterMin;
            params[i] = initialParameterMin + int256(paramRandomness % uint256(range > 0 ? range : 1));
        }
        return params;
    }

    /**
     * @dev Initializes conceptual coordinates for a new fragment.
     */
    function _initializeCoords(uint256 seed) internal pure returns (int256[] memory) {
         // Simple 3D coordinates based on seed
        int256[] memory coords = new int256[](3);
        coords[0] = int256(uint256(keccak256(abi.encodePacked(seed, 0))) % 1000) - 500;
        coords[1] = int256(uint256(keccak256(abi.encodePacked(seed, 1))) % 1000) - 500;
        coords[2] = int256(uint256(keccak256(abi.encodePacked(seed, 2))) % 1000) - 500;
        return coords;
    }


    // --- Core ERC721 Functions (Implemented via Inheritance) ---
    // 1. balanceOf(address owner)
    // 2. ownerOf(uint256 tokenId)
    // 3. approve(address to, uint256 tokenId)
    // 4. getApproved(uint256 tokenId)
    // 5. setApprovalForAll(address operator, bool approved)
    // 6. isApprovedForAll(address owner, address operator)
    // 7. transferFrom(address from, address to, uint256 tokenId)
    // 8. safeTransferFrom(address from, address to, uint256 tokenId) - two versions
    // 9. supportsInterface(bytes4 interfaceId)

    // --- Custom Eternal Art Engine Functions (11-31) ---

    /**
     * @dev Mints a new Cosmic Fragment token.
     * Only callable by the contract owner initially, or via specific mechanisms later.
     * Includes initial state generation.
     * @param to The address to mint the token to.
     * @return The newly minted token ID.
     */
    function mintInitialFragment(address to) external onlyOwner returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _safeMint(to, newItemId);

        uint256 seed = _generatePseudoRandomSeed(newItemId);
        int256[] memory initialParams = _initializeParameters(newItemId, seed);
        int256[] memory initialCoords = _initializeCoords(seed);

        _fragmentStates[newItemId] = FragmentState({
            seed: seed,
            energy: 500, // Starting energy
            complexity: 1, // Starting complexity
            lastEvolutionTime: block.timestamp,
            parameters: initialParams,
            coords: initialCoords
        });

        emit FragmentMinted(newItemId, to, seed);
        return newItemId;
    }

    /**
     * @dev Allows the owner of a fragment to manually trigger its evolution.
     * Consumes energy and requires a cooldown period.
     * @param tokenId The ID of the fragment to evolve.
     */
    function evolveFragment(uint256 tokenId) external {
        require(_exists(tokenId), "Fragment does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not owner of fragment");

        FragmentState storage fragment = _fragmentStates[tokenId];

        uint256 timeElapsed = block.timestamp.sub(fragment.lastEvolutionTime);
        require(timeElapsed >= evolutionCooldown, "Evolution cooldown not met");

        // _applyEvolutionLogic handles energy check and decay internally
        _applyEvolutionLogic(tokenId);
    }

    /**
     * @dev Allows anyone to trigger the evolution of a fragment *if* its cooldown is met and it has sufficient energy
     * (after decay). This allows the community to pay gas to keep fragments evolving.
     * Useful for automated systems or users wanting to see the art change.
     * @param tokenId The ID of the fragment to potentially evolve.
     */
    function triggerTimedEvolution(uint256 tokenId) external {
        require(_exists(tokenId), "Fragment does not exist");

        FragmentState storage fragment = _fragmentStates[tokenId];

        uint256 timeElapsed = block.timestamp.sub(fragment.lastEvolutionTime);
        require(timeElapsed >= evolutionCooldown, "Evolution cooldown not met");

        // Calculate energy after decay *before* applying logic
        uint256 energyAfterDecay = _calculateEnergyDecay(fragment.lastEvolutionTime, fragment.energy);

        // Check if evolution is possible *after* decay
        require(energyAfterDecay >= baseEvolutionCost.add(minEnergyForTimedEvolution), "Insufficient energy for timed evolution after decay");

        // Temporarily update energy for the check inside apply logic
        fragment.energy = energyAfterDecay;

        // _applyEvolutionLogic handles the final energy check and update
        _applyEvolutionLogic(tokenId);
    }


    /**
     * @dev Allows the owner to inject energy into a fragment.
     * Can potentially be tied to payment or burning other tokens in a more complex system.
     * For simplicity, this version just adds a fixed amount.
     * @param tokenId The ID of the fragment to inject energy into.
     * @param amount The amount of energy to inject.
     */
    function injectEnergy(uint256 tokenId, uint256 amount) external {
        require(_exists(tokenId), "Fragment does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not owner of fragment");
        require(amount > 0, "Injection amount must be positive");

        FragmentState storage fragment = _fragmentStates[tokenId];

        // Apply decay before injecting, so decay is up-to-date
        fragment.energy = _calculateEnergyDecay(fragment.lastEvolutionTime, fragment.energy);
        // Update last evolution time to now to reset decay clock after injection
        fragment.lastEvolutionTime = block.timestamp;

        fragment.energy = fragment.energy.add(amount);

        emit EnergyInjected(tokenId, msg.sender, amount, fragment.energy);
    }

    /**
     * @dev Allows the owner to fuse two fragments.
     * The primary fragment (tokenId1) is modified, incorporating aspects of the secondary fragment (tokenId2).
     * The secondary fragment (tokenId2) is burned. Consumes energy.
     * @param tokenId1 The ID of the primary fragment (kept and modified).
     * @param tokenId2 The ID of the secondary fragment (burned).
     */
    function fuseFragments(uint256 tokenId1, uint256 tokenId2) external {
        require(_exists(tokenId1), "Primary fragment does not exist");
        require(_exists(tokenId2), "Secondary fragment does not exist");
        require(tokenId1 != tokenId2, "Cannot fuse a fragment with itself");
        require(ownerOf(tokenId1) == msg.sender, "Not owner of primary fragment");
        require(ownerOf(tokenId2) == msg.sender, "Not owner of secondary fragment");

        FragmentState storage fragment1 = _fragmentStates[tokenId1];
        FragmentState storage fragment2 = _fragmentStates[tokenId2];

        // Apply decay before check
        fragment1.energy = _calculateEnergyDecay(fragment1.lastEvolutionTime, fragment1.energy);
        fragment2.energy = _calculateEnergyDecay(fragment2.lastEvolutionTime, fragment2.energy);

        require(fragment1.energy.add(fragment2.energy) >= fuseEnergyCost, "Insufficient combined energy for fusion");

        // Fusion Logic (Example: combine parameters, complexity, merge energy)
        uint256 totalEnergy = fragment1.energy.add(fragment2.energy).sub(fuseEnergyCost);
        uint256 combinedComplexity = fragment1.complexity.add(fragment2.complexity); // Simple sum

        // Parameter blending (example: average parameters, weighted by complexity or energy)
        // If parameter arrays are different lengths, this needs careful handling (pad, truncate, or error)
        uint256 minLen = fragment1.parameters.length < fragment2.parameters.length ? fragment1.parameters.length : fragment2.parameters.length;
        for (uint i = 0; i < minLen; i++) {
             // Simple average
            fragment1.parameters[i] = (fragment1.parameters[i] + fragment2.parameters[i]) / 2;
             // Weighted average by complexity (more complex fragment has more influence)
            // fragment1.parameters[i] = (fragment1.parameters[i] * int256(fragment1.complexity) + fragment2.parameters[i] * int256(fragment2.complexity)) / int256(fragment1.complexity + fragment2.complexity);
        }
         // If lengths differ, maybe keep the longer one or resize? Let's keep the primary's length for simplicity.

        // Merge coordinates (e.g., find midpoint)
        if (fragment1.coords.length == fragment2.coords.length) {
            for (uint i = 0; i < fragment1.coords.length; i++) {
                fragment1.coords[i] = (fragment1.coords[i] + fragment2.coords[i]) / 2;
            }
        } // Else, keep primary's coordinates

        fragment1.energy = totalEnergy;
        fragment1.complexity = combinedComplexity;
        fragment1.lastEvolutionTime = block.timestamp; // Reset cooldown and decay

        // Burn the secondary fragment
        _burn(tokenId2);
        delete _fragmentStates[tokenId2]; // Clean up state storage

        emit FragmentsFused(tokenId1, tokenId2, fragment1.complexity, fragment1.energy);
        emit ParametersUpdated(tokenId1);
    }

     /**
      * @dev Allows the owner to detonate a fragment. This burns the fragment.
      * Can yield a portion of its remaining energy as a special 'seed' value or refund.
      * Here, it yields a deterministic 'seed' based on final state, and burns the token.
      * @param tokenId The ID of the fragment to detonate.
      * @return yieldedSeed A seed value derived from the fragment's final state.
      */
    function detonateFragment(uint256 tokenId) external returns (uint256 yieldedSeed) {
        require(_exists(tokenId), "Fragment does not exist");
        address owner = ownerOf(tokenId);
        require(owner == msg.sender, "Not owner of fragment");

        FragmentState storage fragment = _fragmentStates[tokenId];

        // Apply decay before detonation
        fragment.energy = _calculateEnergyDecay(fragment.lastEvolutionTime, fragment.energy);

        // Determine yield (example: a deterministic seed based on final state)
        uint256 finalEnergy = fragment.energy;
        yieldedSeed = uint256(keccak256(abi.encodePacked(fragment.seed, finalEnergy, fragment.complexity, block.timestamp)));

        emit FragmentDetonated(tokenId, owner, finalEnergy, yieldedSeed);

        _burn(tokenId);
        delete _fragmentStates[tokenId];

        return yieldedSeed;
    }

    /**
     * @dev Allows a high-energy fragment to 'seed' a new child fragment.
     * Consumes significant energy from the parent. The child's parameters are related to the parent.
     * @param parentTokenId The ID of the parent fragment.
     * @param to The address to mint the child token to.
     * @return The newly minted child token ID.
     */
    function seedChildFragment(uint256 parentTokenId, address to) external returns (uint256 childTokenId) {
        require(_exists(parentTokenId), "Parent fragment does not exist");
        require(ownerOf(parentTokenId) == msg.sender, "Not owner of parent fragment");

        FragmentState storage parentFragment = _fragmentStates[parentTokenId];

        // Apply decay before check
        parentFragment.energy = _calculateEnergyDecay(parentFragment.lastEvolutionTime, parentFragment.energy);

        require(parentFragment.energy >= seedChildEnergyCost, "Parent has insufficient energy to seed a child");

        parentFragment.energy = parentFragment.energy.sub(seedChildEnergyCost);
        parentFragment.lastEvolutionTime = block.timestamp; // Reset parent's decay clock

        // Mint the child token
        _tokenIdCounter.increment();
        childTokenId = _tokenIdCounter.current();
        _safeMint(to, childTokenId);

        // Initialize child state based on parent and randomness
        uint256 childSeed = _generatePseudoRandomSeed(childTokenId);
        int256[] memory childParams = new int256[](parentFragment.parameters.length > 0 ? parentFragment.parameters.length : initialParameterCount);

         // Example: Child parameters are slightly mutated from parent parameters
        uint256 randomness = uint256(keccak256(abi.encodePacked(parentFragment.seed, childSeed, block.timestamp, block.number)));
        for (uint i = 0; i < childParams.length; i++) {
             // If parent has parameters, start near parent's value with mutation
            int256 baseValue = i < parentFragment.parameters.length ? parentFragment.parameters[i] : 0; // Default if parent has fewer
            uint256 paramRandomness = uint256(keccak256(abi.encodePacked(randomness, i)));
            int256 mutation = int256(paramRandomness % 31) - 15; // Mutation between -15 and +15
            childParams[i] = baseValue + mutation;
        }

        // Child coordinates start near parent's or re-initialized
        int256[] memory childCoords = new int256[](parentFragment.coords.length > 0 ? parentFragment.coords.length : 3);
         for (uint i = 0; i < childCoords.length; i++) {
             int256 baseCoord = i < parentFragment.coords.length ? parentFragment.coords[i] : 0;
             uint256 coordRandomness = uint256(keccak256(abi.encodePacked(randomness, i + childParams.length)));
             int256 mutation = int256(coordRandomness % 21) - 10; // Mutation between -10 and +10
             childCoords[i] = baseCoord + mutation;
        }


        _fragmentStates[childTokenId] = FragmentState({
            seed: childSeed,
            energy: seedChildEnergyCost / 2, // Child starts with some energy
            complexity: parentFragment.complexity / 2 + 1, // Child starts with some inherited complexity
            lastEvolutionTime: block.timestamp,
            parameters: childParams,
            coords: childCoords
        });

        emit ChildFragmentSeeded(parentTokenId, childTokenId, parentFragment.energy);
        emit FragmentMinted(childTokenId, to, childSeed);
        emit ParametersUpdated(childTokenId);
        return childTokenId;
    }

    /**
     * @dev Allows the owner to slightly tweak specific parameters of a fragment.
     * Useful for fine-tuning or steering the art's evolution. Costs energy per tweak.
     * @param tokenId The ID of the fragment.
     * @param parameterIndex The index of the parameter to tweak.
     * @param delta The amount to add to the parameter value (can be negative).
     */
    function updateParameterManually(uint256 tokenId, uint256 parameterIndex, int256 delta) external {
         require(_exists(tokenId), "Fragment does not exist");
         require(ownerOf(tokenId) == msg.sender, "Not owner of fragment");

         FragmentState storage fragment = _fragmentStates[tokenId];
         require(parameterIndex < fragment.parameters.length, "Invalid parameter index");

         // Apply decay before check
         fragment.energy = _calculateEnergyDecay(fragment.lastEvolutionTime, fragment.energy);

         require(fragment.energy >= parameterTweakCost, "Insufficient energy to tweak parameter");

         fragment.energy = fragment.energy.sub(parameterTweakCost);
         fragment.parameters[parameterIndex] = fragment.parameters[parameterIndex] + delta; // Apply delta

         // Note: lastEvolutionTime is not updated by tweaking, only by actual evolution events.
         // This means tweaking doesn't reset the decay/cooldown timer.

         emit ParametersUpdated(tokenId);
    }

     /**
      * @dev Allows the owner to re-randomize all parameters of a fragment.
      * More costly than tweaking. Useful for drastic changes.
      * @param tokenId The ID of the fragment.
      */
    function randomizeParameters(uint256 tokenId) external {
        require(_exists(tokenId), "Fragment does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not owner of fragment");

        FragmentState storage fragment = _fragmentStates[tokenId];

        // Apply decay before check
        fragment.energy = _calculateEnergyDecay(fragment.lastEvolutionTime, fragment.energy);

        require(fragment.energy >= parameterRandomizeCost, "Insufficient energy to randomize parameters");

        fragment.energy = fragment.energy.sub(parameterRandomizeCost);

        // Regenerate parameters based on current state + randomness
        uint256 randomness = uint256(keccak256(abi.encodePacked(fragment.seed, fragment.complexity, fragment.energy, block.timestamp, block.number, tx.gasprice, "randomize")));
         for (uint i = 0; i < fragment.parameters.length; i++) {
            uint256 paramRandomness = uint256(keccak256(abi.encodePacked(randomness, i)));
            int256 range = initialParameterMax - initialParameterMin; // Use initial range as bound reference
             // Re-randomize within initial range + some variance based on complexity
            int256 minBound = initialParameterMin - int256(fragment.complexity % 10); // Example
            int256 maxBound = initialParameterMax + int256(fragment.complexity % 10); // Example
            int256 currentRange = maxBound - minBound;
            if (currentRange <= 0) currentRange = 1; // Avoid div by zero

            fragment.parameters[i] = minBound + int256(paramRandomness % uint256(currentRange));
        }

        // Note: lastEvolutionTime is not updated by randomization.

        emit ParametersUpdated(tokenId);
    }


     /**
      * @dev Allows the owner to navigate the fragment within the conceptual coordinate space.
      * Costs energy. Changes the fragment's coordinates, which might influence future interactions
      * or rendering if the renderer uses coordinates.
      * @param tokenId The ID of the fragment.
      * @param deltaCoords The deltas to apply to the coordinates. Must match current dimension.
      */
    function navigateFragment(uint256 tokenId, int256[] calldata deltaCoords) external {
        require(_exists(tokenId), "Fragment does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not owner of fragment");

        FragmentState storage fragment = _fragmentStates[tokenId];
        require(fragment.coords.length > 0 && deltaCoords.length == fragment.coords.length, "Invalid coordinate delta length");

        // Apply decay before check
        fragment.energy = _calculateEnergyDecay(fragment.lastEvolutionTime, fragment.energy);

        require(fragment.energy >= navigateCost, "Insufficient energy to navigate");

        fragment.energy = fragment.energy.sub(navigateCost);

        // Apply coordinate changes
        for (uint i = 0; i < fragment.coords.length; i++) {
            fragment.coords[i] = fragment.coords[i] + deltaCoords[i];
        }

        // Note: lastEvolutionTime is not updated by navigation.

        emit FragmentNavigated(tokenId, fragment.coords);
    }


    // --- Query Functions (Read-Only) ---

    /**
     * @dev Gets the full state of a Cosmic Fragment.
     * @param tokenId The ID of the fragment.
     * @return The FragmentState struct.
     */
    function getFragmentState(uint256 tokenId) public view returns (FragmentState memory) {
        require(_exists(tokenId), "Fragment does not exist");
        FragmentState storage fragment = _fragmentStates[tokenId];
        // Return a memory copy, applying potential energy decay for read
        FragmentState memory state = fragment;
        state.energy = _calculateEnergyDecay(state.lastEvolutionTime, state.energy);
        return state;
    }

    /**
     * @dev Gets the current energy level of a fragment, including decay since last update.
     * @param tokenId The ID of the fragment.
     * @return The current energy level.
     */
    function getFragmentEnergy(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "Fragment does not exist");
         FragmentState storage fragment = _fragmentStates[tokenId];
         return _calculateEnergyDecay(fragment.lastEvolutionTime, fragment.energy);
    }

    /**
     * @dev Gets the current complexity level of a fragment.
     * @param tokenId The ID of the fragment.
     * @return The current complexity level.
     */
    function getFragmentComplexity(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "Fragment does not exist");
         return _fragmentStates[tokenId].complexity;
    }

    /**
     * @dev Gets the current generative parameters of a fragment.
     * @param tokenId The ID of the fragment.
     * @return An array of int256 parameters.
     */
    function getFragmentParameters(uint256 tokenId) public view returns (int256[] memory) {
         require(_exists(tokenId), "Fragment does not exist");
         return _fragmentStates[tokenId].parameters;
    }

     /**
      * @dev Gets the conceptual coordinates of a fragment.
      * @param tokenId The ID of the fragment.
      * @return An array of int256 coordinates.
      */
    function getFragmentCoords(uint256 tokenId) public view returns (int256[] memory) {
         require(_exists(tokenId), "Fragment does not exist");
         return _fragmentStates[tokenId].coords;
    }

    /**
     * @dev Gets the time elapsed since the last evolution of a fragment.
     * Useful for checking cooldown status.
     * @param tokenId The ID of the fragment.
     * @return The time elapsed in seconds.
     */
    function getTimeSinceLastEvolution(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "Fragment does not exist");
         return block.timestamp.sub(_fragmentStates[tokenId].lastEvolutionTime);
    }

    /**
     * @dev Gets the base URI used by the tokenURI function to construct the full URI.
     * @return The base URI string.
     */
    function rendererBaseURI() public view returns (string memory) {
        return _rendererBaseURI;
    }


    // --- ERC721 Metadata Extension ---

    /**
     * @dev Returns the token URI for a given token ID.
     * This should point to an external service that fetches the fragment's state
     * using `getFragmentState` or `getFragmentParameters` and renders the art or JSON metadata.
     * The format is typically `rendererBaseURI` + `tokenId`.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // The actual rendering service needs to query the contract state for this tokenId
        // using getFragmentState() or similar and return JSON metadata with image/SVG data.
        // Example format: ipfs://[hash]/[tokenId].json or https://renderer.service/api/metadata/[tokenId]
        // For this example, we'll use the base URI + token ID. The service at the base URI
        // is expected to handle the rest.
        string memory base = _rendererBaseURI;
        if (bytes(base).length == 0) {
             return ""; // Or a default error URI
        }
        // ERC721 spec says token URI should be base URI + token ID string
        // We'll append token ID as string
        return string(abi.encodePacked(base, Strings.toString(tokenId)));
    }


    // --- Admin Functions (Owner Only) ---

    /**
     * @dev Sets the base URI for the external renderer service.
     * @param baseURI The new base URI string.
     */
    function setRendererBaseURI(string memory baseURI) external onlyOwner {
        _rendererBaseURI = baseURI;
    }

     /**
      * @dev Sets the base energy cost for standard evolution.
      * @param cost The new base cost.
      */
     function setBaseEvolutionCost(uint256 cost) external onlyOwner {
         baseEvolutionCost = cost;
     }

     /**
      * @dev Sets the energy decay rate (amount lost per interval).
      * @param rate The new decay rate.
      */
    function setEnergyDecayRate(uint256 rate) external onlyOwner {
        energyDecayRate = rate;
    }

    /**
     * @dev Sets the energy decay interval (time unit for decay).
     * @param interval The new decay interval in seconds.
     */
    function setEnergyDecayInterval(uint256 interval) external onlyOwner {
        require(interval > 0, "Interval must be positive");
        energyDecayInterval = interval;
    }


     /**
      * @dev Sets the complexity growth factor per evolution.
      * @param factor The new growth factor.
      */
    function setComplexityGrowthFactor(uint256 factor) external onlyOwner {
        complexityGrowthFactor = factor;
    }

    /**
     * @dev Sets the minimum time required between manual or timed evolutions.
     * @param cooldown The new cooldown in seconds.
     */
    function setEvolutionCooldown(uint256 cooldown) external onlyOwner {
        evolutionCooldown = cooldown;
    }

    /**
     * @dev Sets the energy cost for fusing fragments.
     * @param cost The new fusion cost.
     */
    function setFuseEnergyCost(uint256 cost) external onlyOwner {
        fuseEnergyCost = cost;
    }

     /**
      * @dev Sets the energy cost for seeding a new child fragment.
      * @param cost The new seed child cost.
      */
    function setSeedChildEnergyCost(uint256 cost) external onlyOwner {
        seedChildEnergyCost = cost;
    }

    /**
     * @dev Sets the energy cost for navigating in the coordinate space.
     * @param cost The new navigation cost.
     */
    function setNavigateCost(uint256 cost) external onlyOwner {
        navigateCost = cost;
    }

    /**
     * @dev Sets the minimum energy required for a fragment to be eligible for timed evolution (after decay).
     * @param minEnergy The new minimum energy threshold.
     */
    function setMinEnergyForTimedEvolution(uint256 minEnergy) external onlyOwner {
        minEnergyForTimedEvolution = minEnergy;
    }

     /**
      * @dev Sets the energy cost for manually tweaking a single parameter.
      * @param cost The new tweak cost.
      */
     function setParameterTweakCost(uint256 cost) external onlyOwner {
         parameterTweakCost = cost;
     }

     /**
      * @dev Sets the energy cost for re-randomizing all parameters.
      * @param cost The new randomize cost.
      */
     function setParameterRandomizeCost(uint256 cost) external onlyOwner {
         parameterRandomizeCost = cost;
     }


     /**
      * @dev Sets the number of initial parameters and their value range.
      * Note: Changing parameter count for *existing* fragments is not supported by this function.
      * This only affects *newly minted* fragments.
      * @param count The number of parameters.
      * @param min The minimum initial value.
      * @param max The maximum initial value.
      */
    function setInitialParameterConfig(uint256 count, int256 min, int256 max) external onlyOwner {
        require(count > 0, "Parameter count must be positive");
        initialParameterCount = count;
        initialParameterMin = min;
        initialParameterMax = max;
    }
}
```

---

**Outline and Function Summary**

This contract, `EternalArtEngine`, is an ERC721 token managing generative art NFTs called "Cosmic Fragments". Each fragment's state (energy, complexity, parameters, coordinates) is stored on-chain and evolves based on various triggers. The visual art is rendered off-chain using the on-chain parameters via the `tokenURI` function.

**Inherited Functions (from OpenZeppelin ERC721 & Ownable):** (9 functions)
1.  `balanceOf(address owner)`: Get the number of tokens owned by an address.
2.  `ownerOf(uint256 tokenId)`: Get the owner of a specific token.
3.  `approve(address to, uint256 tokenId)`: Grant approval to a single address for a specific token.
4.  `getApproved(uint256 tokenId)`: Get the approved address for a single token.
5.  `setApprovalForAll(address operator, bool approved)`: Grant/revoke approval for an operator for all owner's tokens.
6.  `isApprovedForAll(address owner, address operator)`: Check if an address is an approved operator for another.
7.  `transferFrom(address from, address to, uint256 tokenId)`: Transfer token ownership from one address to another (requires approval/operator).
8.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Same as transferFrom, but with receiver hook check.
9.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Same as transferFrom, but with receiver hook check (without data).
10. `supportsInterface(bytes4 interfaceId)`: Standard function to signal supported interfaces (ERC165).

**Custom Eternal Art Engine Functions:** (23 functions)

**Minting:**
11. `mintInitialFragment(address to)`: Mints a new fragment with initial state. Only callable by the contract owner. Returns the new token ID.

**State Management & Evolution:**
12. `evolveFragment(uint256 tokenId)`: Allows the token owner to manually trigger the evolution of their fragment. Requires energy and cooldown.
13. `triggerTimedEvolution(uint256 tokenId)`: Allows *anyone* to trigger a fragment's evolution if its cooldown is met and it has sufficient energy (after decay). Pays gas for the transaction.
14. `injectEnergy(uint256 tokenId, uint256 amount)`: Allows the owner to add energy to a fragment. Resets the decay timer.
15. `updateParameterManually(uint256 tokenId, uint256 parameterIndex, int256 delta)`: Allows the owner to manually adjust a specific generative parameter by a delta value. Costs energy.
16. `randomizeParameters(uint256 tokenId)`: Allows the owner to re-randomize all generative parameters based on internal state and randomness. Costs energy.
17. `navigateFragment(uint256 tokenId, int256[] calldata deltaCoords)`: Allows the owner to change the fragment's conceptual coordinates. Costs energy.

**Fragment Interactions:**
18. `fuseFragments(uint256 tokenId1, uint256 tokenId2)`: Fuses two fragments owned by the caller. `tokenId1` is modified based on `tokenId2`, and `tokenId2` is burned. Consumes energy from both.
19. `detonateFragment(uint256 tokenId)`: Burns a fragment. Yields a seed value derived from its final state.
20. `seedChildFragment(uint256 parentTokenId, address to)`: Creates and mints a new fragment (`to`) whose initial state is derived from a high-energy parent fragment owned by the caller. Consumes significant energy from the parent.

**Query Functions (Read-Only):**
21. `getFragmentState(uint256 tokenId)`: Returns the full `FragmentState` struct for a token, including energy adjusted for decay.
22. `getFragmentEnergy(uint256 tokenId)`: Returns the current energy of a fragment, accounting for decay.
23. `getFragmentComplexity(uint256 tokenId)`: Returns the complexity level of a fragment.
24. `getFragmentParameters(uint256 tokenId)`: Returns the generative parameters array for a fragment.
25. `getFragmentCoords(uint256 tokenId)`: Returns the conceptual coordinates array for a fragment.
26. `getTimeSinceLastEvolution(uint256 tokenId)`: Returns the time elapsed in seconds since the fragment last evolved.
27. `rendererBaseURI()`: Returns the base URI string used for generating token URIs.
28. `tokenURI(uint256 tokenId)`: Returns the full URI string for querying the fragment's metadata and art rendering (calls an external service).

**Admin Functions (Owner Only):**
29. `setRendererBaseURI(string memory baseURI)`: Sets the base URI for the off-chain renderer.
30. `setBaseEvolutionCost(uint256 cost)`: Sets the energy cost for evolution.
31. `setEnergyDecayRate(uint256 rate)`: Sets the rate at which energy decays per interval.
32. `setEnergyDecayInterval(uint256 interval)`: Sets the duration of the energy decay interval in seconds.
33. `setComplexityGrowthFactor(uint256 factor)`: Sets how much complexity increases per evolution.
34. `setEvolutionCooldown(uint256 cooldown)`: Sets the minimum time between evolutions.
35. `setFuseEnergyCost(uint256 cost)`: Sets the total energy cost for fusion.
36. `setSeedChildEnergyCost(uint256 cost)`: Sets the energy cost for seeding a child fragment.
37. `setNavigateCost(uint256 cost)`: Sets the energy cost for navigating coordinates.
38. `setMinEnergyForTimedEvolution(uint256 minEnergy)`: Sets the minimum energy required for timed evolution trigger after decay.
39. `setParameterTweakCost(uint256 cost)`: Sets the energy cost for manually tweaking a parameter.
40. `setParameterRandomizeCost(uint256 cost)`: Sets the energy cost for re-randomizing all parameters.
41. `setInitialParameterConfig(uint256 count, int256 min, int256 max)`: Configures the number and range of parameters for *newly minted* fragments.

This contract provides a rich, stateful NFT experience centered around dynamic, evolving generative art, offering multiple interaction points for owners and the community.