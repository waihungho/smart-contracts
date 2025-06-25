Okay, let's create a concept around dynamic, interconnected, evolving digital entities – think of them as generative "Fractal Fragments" within a "Fractalverse". Each fragment has properties that can change over time based on interactions, energy levels, and algorithmic rules. They can be linked, merged, split, and harvested for abstract resources or value. This blends concepts of NFTs, dynamic state, on-chain simulation, and resource management.

We will avoid standard token interfaces directly (like inheriting ERC721) to ensure uniqueness, implementing ownership and transfer mechanisms custom to this concept.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Fractalverse
 * @dev A smart contract managing dynamic, evolving, and interconnected digital entities called Fractal Fragments.
 *      Fragments have dynamic properties, energy, complexity, and can be linked, merged, split, and harvested.
 *      This contract explores concepts of on-chain dynamic assets, algorithmic evolution, and resource management.
 */

/**
 * OUTLINE:
 * 1. Data Structures: Define the Fragment struct and mappings to manage fragments and ownership.
 * 2. Events: Declare events for key actions (creation, transfer, evolution, linking, etc.).
 * 3. State Variables: Counters for fragment IDs, system-wide parameters (e.g., decay rate, evolution thresholds).
 * 4. Core Fragment Management:
 *    - Creation: Creating new fragments.
 *    - Ownership: Getting owner, transferring ownership.
 *    - Linking: Creating and managing connections between fragments.
 *    - Queries: Getting fragment details, links, owned fragments.
 * 5. Dynamic State & Evolution:
 *    - Energy Management: Adding energy to fragments.
 *    - Property Calculation: Calculating complexity, resonance, other derived properties.
 *    - Evolution & Decay: Functions triggering state changes based on rules and time.
 *    - Discovery: Probabilistic function to reveal new properties.
 * 6. Structural Operations:
 *    - Merging: Combining fragments.
 *    - Splitting: Breaking down fragments.
 * 7. Value & Interaction:
 *    - Harvesting: Extracting value or resources (abstract) from fragments.
 *    - Licensing/Royalty: Setting and paying royalties on fragments.
 * 8. System Configuration (Limited): Basic getter for system info. Admin functions kept minimal or hypothetical for decentralization.
 */

/**
 * FUNCTION SUMMARY:
 * - createFragment(uint256 _seed): Creates a new Fractal Fragment with initial properties derived from seed and other factors. (Payable)
 * - energizeFragment(uint256 _fragmentId): Adds energy to a specific fragment. (Payable)
 * - evolveFragment(uint256 _fragmentId): Triggers the evolution process for a fragment based on its energy, complexity, and time.
 * - decayFragment(uint256 _fragmentId): Explicitly triggers the decay process for a fragment (decay also happens implicitly over time).
 * - harvestFragment(uint256 _fragmentId): Extracts abstract resources/value from a fragment, consuming energy and potentially reducing complexity.
 * - linkFragments(uint256 _fragmentId1, uint256 _fragmentId2): Creates a unidirectional link from _fragmentId1 to _fragmentId2.
 * - removeLink(uint256 _fragmentId1, uint256 _fragmentId2): Removes a link from _fragmentId1 to _fragmentId2.
 * - mergeFragments(uint256 _fragmentId1, uint256 _fragmentId2): Merges two fragments into a new, more complex fragment. Requires conditions.
 * - splitFragment(uint256 _fragmentId): Splits a complex fragment into simpler ones. Requires conditions.
 * - discoverFragmentProperty(uint256 _fragmentId): A probabilistic function to potentially discover or enhance a property on a fragment. Requires cost/energy.
 * - transferFragment(address _to, uint256 _fragmentId): Transfers ownership of a fragment.
 * - setFragmentRoyaltyPercentage(uint256 _fragmentId, uint16 _percentage): Sets the royalty percentage for a fragment (bps, max 10000).
 * - payFragmentRoyalty(uint256 _fragmentId): Allows paying the set royalty to the fragment owner. (Payable)
 * - getFragmentCount(): Returns the total number of fragments created.
 * - getFragmentDetails(uint256 _fragmentId): Returns all key properties of a fragment.
 * - getFragmentOwner(uint256 _fragmentId): Returns the owner's address for a fragment.
 * - getFragmentsOwnedByUser(address _user): Returns an array of fragment IDs owned by a specific user.
 * - getFragmentLinks(uint256 _fragmentId): Returns the IDs of fragments linked *from* the given fragment.
 * - getFragmentEnergy(uint256 _fragmentId): Returns the current energy level of a fragment.
 * - getFragmentComplexity(uint256 _fragmentId): Calculates and returns the current complexity score of a fragment.
 * - getFragmentResonance(uint256 _fragmentId): Calculates and returns the resonance score of a fragment based on its properties and links.
 * - getFragmentSeed(uint256 _fragmentId): Returns the creation seed of a fragment.
 * - getFragmentCreationTime(uint256 _fragmentId): Returns the creation timestamp.
 * - getFragmentLastEvolutionTime(uint256 _fragmentId): Returns the timestamp of the last evolution/decay.
 * - getFragmentRoyaltyPercentage(uint256 _fragmentId): Returns the set royalty percentage for a fragment.
 * - getFragmentProperty(uint256 _fragmentId, uint8 _propertyIndex): Returns a specific property value.
 */

contract Fractalverse {

    struct Fragment {
        uint256 id;
        address owner;
        uint64 creationTime;
        uint256 seed; // Initial seed influencing base properties

        // Core Dynamic Properties (represent abstract aspects, dimensions, etc.)
        uint256[4] coreProperties; // Example: [Aspect A, Aspect B, Aspect C, Aspect D] - range 0-1000

        uint256 energy; // Resource for evolution, harvesting, discovery
        uint256 complexity; // Derived metric, influences evolution/decay difficulty and potential
        uint16 royaltyPercentageBps; // Royalty in Basis Points (e.g., 100 = 1%)

        uint64 lastEvolutionTime; // Timestamp of last evolve or decay event

        // Store linked fragment IDs (uni-directional links for simplicity)
        uint256[] linkedFragments;

        // Optional: Store more specific traits/data unlocked via 'discovery' or evolution
        // bytes32[] discoveredTraits; // Simplified for this example
    }

    // --- State Variables ---
    uint256 private _fragmentCounter;
    mapping(uint256 => Fragment) private _fragments;

    // Mapping from owner address to array of fragment IDs
    mapping(address => uint256[] shallow_fragmentsOwned);
    // Mapping from fragment ID to index in owner's array (for efficient removal)
    mapping(uint256 => uint256 shallow_fragmentIndexInOwnerArray);

    // System parameters (can be adjusted by owner initially, or later via governance)
    uint256 public constant EVOLUTION_ENERGY_THRESHOLD = 500; // Minimum energy to attempt evolution
    uint256 public constant EVOLUTION_COMPLEXITY_COST = 10; // Complexity points required/consumed for evolution
    uint256 public constant DECAY_INTERVAL = 1 days; // Time after which decay can occur
    uint256 public constant HARVEST_ENERGY_COST = 100; // Energy consumed per harvest
    uint256 public constant DISCOVERY_ENERGY_COST = 200; // Energy consumed per discovery attempt
    uint256 public constant MERGE_ENERGY_COST_PER_FRAGMENT = 300; // Energy cost to merge two fragments
    uint256 public constant SPLIT_ENERGY_COST = 400; // Energy cost to split a fragment
    uint256 public constant FRAGMENT_CREATION_COST = 0.01 ether; // Cost to create a new fragment
    uint256 public constant ENERGIZE_COST_PER_UNIT = 0.0001 ether; // Cost per unit of energy

    // --- Events ---
    event FragmentCreated(uint256 indexed fragmentId, address indexed owner, uint256 seed, uint64 creationTime);
    event FragmentTransferred(uint256 indexed fragmentId, address indexed from, address indexed to);
    event FragmentEnergized(uint256 indexed fragmentId, address indexed by, uint256 amount);
    event FragmentEvolved(uint256 indexed fragmentId, uint64 newLastEvolutionTime);
    event FragmentDecayed(uint256 indexed fragmentId, uint64 newLastEvolutionTime);
    event FragmentHarvested(uint256 indexed fragmentId, address indexed by, uint256 energyConsumed);
    event FragmentsMerged(uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 indexed newFragmentId);
    event FragmentSplit(uint256 indexed parentId, uint256[] newFragmentIds);
    event FragmentLinked(uint256 indexed fromFragmentId, uint256 indexed toFragmentId);
    event FragmentLinkRemoved(uint256 indexed fromFragmentId, uint256 indexed toFragmentId);
    event PropertyDiscovered(uint256 indexed fragmentId, uint8 indexed propertyIndex, uint256 newValue);
    event RoyaltyPercentageUpdated(uint256 indexed fragmentId, uint16 indexed percentageBps);
    event RoyaltyPaid(uint256 indexed fragmentId, address indexed payer, uint256 amount);


    // --- Modifiers ---
    modifier onlyFragmentOwner(uint256 _fragmentId) {
        require(_fragments[_fragmentId].owner == msg.sender, "Not fragment owner");
        _;
    }

    modifier fragmentExists(uint256 _fragmentId) {
        require(_fragments[_fragmentId].owner != address(0), "Fragment does not exist");
        _;
    }

    // --- Constructor (Simple owner for initial parameter setting, could be a DAO later) ---
    address public owner;
    constructor() {
        owner = msg.sender;
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Adds a fragment ID to the owner's list.
     */
    function _addFragmentToOwner(address _owner, uint256 _fragmentId) internal {
        shallow_fragmentIndexInOwnerArray[_fragmentId] = shallow_fragmentsOwned[_owner].length;
        shallow_fragmentsOwned[_owner].push(_fragmentId);
    }

    /**
     * @dev Removes a fragment ID from the owner's list efficiently using swap-and-pop.
     */
    function _removeFragmentFromOwner(address _owner, uint256 _fragmentId) internal {
        uint256 fragmentIndex = shallow_fragmentIndexInOwnerArray[_fragmentId];
        uint256 lastIndex = shallow_fragmentsOwned[_owner].length - 1;
        uint256 lastFragmentId = shallow_fragmentsOwned[_owner][lastIndex];

        // Swap the fragment to remove with the last fragment
        shallow_fragmentsOwned[_owner][fragmentIndex] = lastFragmentId;
        shallow_fragmentIndexInOwnerArray[lastFragmentId] = fragmentIndex;

        // Remove the last fragment (which is now a duplicate)
        shallow_fragmentsOwned[_owner].pop();

        // Clear the index mapping for the removed fragment
        delete shallow_fragmentIndexInOwnerArray[_fragmentId];
    }

    /**
     * @dev Calculates a base complexity score based on current properties.
     *      A simple sum or weighted sum of properties.
     */
    function _calculateBaseComplexity(uint256[4] memory properties) internal pure returns (uint256) {
        uint256 total = 0;
        for (uint8 i = 0; i < properties.length; i++) {
            total += properties[i];
        }
        return total / 40; // Normalize, adjust scaling factor
    }

    /**
     * @dev Calculates resonance based on linked fragments and property similarity.
     *      Simplified: Sum of similarity scores with linked fragments.
     *      Similarity: Inverse of difference between properties.
     */
    function _calculateResonance(uint256 _fragmentId) internal view returns (uint256) {
        uint256 resonance = 0;
        Fragment storage fragment = _fragments[_fragmentId];

        for (uint i = 0; i < fragment.linkedFragments.length; i++) {
            uint256 linkedId = fragment.linkedFragments[i];
            if (_fragments[linkedId].owner != address(0)) { // Check if linked fragment still exists
                Fragment storage linkedFragment = _fragments[linkedId];
                uint256 similarity = 0;
                for (uint8 prop = 0; prop < 4; prop++) {
                    uint256 diff = 0;
                    if (fragment.coreProperties[prop] > linkedFragment.coreProperties[prop]) {
                        diff = fragment.coreProperties[prop] - linkedFragment.coreProperties[prop];
                    } else {
                        diff = linkedFragment.coreProperties[prop] - fragment.coreProperties[prop];
                    }
                    // Simple inverse similarity (larger difference = lower similarity)
                    // Add 1 to avoid division by zero, scale up
                    similarity += (1000 - diff); // Max similarity per prop is 1000
                }
                resonance += (similarity / 4); // Average similarity contribution from this link
            }
        }
        return resonance; // Total resonance from all links
    }

    /**
     * @dev Implements simple probabilistic logic for discovery.
     *      Not cryptographically secure randomness, depends on block data.
     */
    function _tryDiscoverProperty(uint256 _fragmentId, uint256 _seedModifier) internal view returns (bool success, uint8 discoveredIndex, uint256 newValue) {
         // Use a combination of seed, fragment ID, timestamp, blockhash (less reliable now) and the modifier
        bytes32 entropy = keccak256(abi.encodePacked(_fragmentId, _seedModifier, block.timestamp, blockhash(block.number - 1), _fragments[_fragmentId].seed));
        uint256 chance = uint256(entropy) % 1000; // Chance out of 1000

        // Higher complexity increases chance
        uint256 discoveryChance = 50 + (_fragments[_fragmentId].complexity / 20); // Base 5%, +1% per 20 complexity
        if (discoveryChance > 500) discoveryChance = 500; // Cap chance at 50%

        if (chance < discoveryChance) {
            // Discovery successful
            discoveredIndex = uint8(uint256(keccak256(abi.encodePacked(entropy, "propertyIndex"))) % 4); // Which property index?
            // New value is influenced by entropy and current value
            uint256 currentPropertyValue = _fragments[_fragmentId].coreProperties[discoveredIndex];
            uint224 valueModifier = uint224(uint256(keccak256(abi.encodePacked(entropy, "valueModifier"))));
            newValue = currentPropertyValue + (valueModifier % 50); // Add 0-49 to property

            // Ensure properties stay within bounds (0-1000)
            if (newValue > 1000) newValue = 1000;

            return (true, discoveredIndex, newValue);
        }
        return (false, 0, 0); // Discovery failed
    }


    // --- Core Fragment Management Functions ---

    /**
     * @dev Creates a new Fractal Fragment.
     * @param _seed A user-provided seed influencing initial properties.
     * @return The ID of the newly created fragment.
     */
    function createFragment(uint256 _seed) external payable returns (uint256) {
        require(msg.value >= FRAGMENT_CREATION_COST, "Insufficient ETH for creation");

        _fragmentCounter++;
        uint256 newFragmentId = _fragmentCounter;
        uint64 currentTime = uint64(block.timestamp);

        // Initial properties based on seed, creation time, block data (simplified)
        uint256[4] memory initialProperties;
        bytes32 entropy = keccak256(abi.encodePacked(_seed, msg.sender, currentTime, blockhash(block.number - 1))); // Using blockhash(block.number-1) for some entropy
        for(uint8 i=0; i<4; i++) {
             // Properties influenced by seed and entropy, range 0-100
             initialProperties[i] = (uint256(keccak256(abi.encodePacked(entropy, i))) % 101);
        }

        Fragment storage newFragment = _fragments[newFragmentId];
        newFragment.id = newFragmentId;
        newFragment.owner = msg.sender;
        newFragment.creationTime = currentTime;
        newFragment.seed = _seed;
        newFragment.coreProperties = initialProperties;
        newFragment.energy = 0; // Starts with no energy
        newFragment.complexity = _calculateBaseComplexity(initialProperties);
        newFragment.royaltyPercentageBps = 0; // No royalties by default
        newFragment.lastEvolutionTime = currentTime; // Treat creation as initial state

        _addFragmentToOwner(msg.sender, newFragmentId);

        emit FragmentCreated(newFragmentId, msg.sender, _seed, currentTime);
        return newFragmentId;
    }

    /**
     * @dev Transfers ownership of a fragment.
     * @param _to The recipient address.
     * @param _fragmentId The ID of the fragment to transfer.
     */
    function transferFragment(address _to, uint256 _fragmentId) external fragmentExists(_fragmentId) onlyFragmentOwner(_fragmentId) {
        require(_to != address(0), "Cannot transfer to zero address");
        require(_to != msg.sender, "Cannot transfer to self");

        address from = msg.sender;
        Fragment storage fragment = _fragments[_fragmentId];

        _removeFragmentFromOwner(from, _fragmentId);
        fragment.owner = _to;
        _addFragmentToOwner(_to, _fragmentId);

        emit FragmentTransferred(_fragmentId, from, _to);
    }

    /**
     * @dev Creates a unidirectional link from one fragment to another.
     * @param _fromFragmentId The ID of the fragment initiating the link.
     * @param _toFragmentId The ID of the fragment being linked to.
     */
    function linkFragments(uint256 _fromFragmentId, uint256 _toFragmentId) external fragmentExists(_fromFragmentId) fragmentExists(_toFragmentId) onlyFragmentOwner(_fromFragmentId) {
        require(_fromFragmentId != _toFragmentId, "Cannot link a fragment to itself");

        Fragment storage fromFragment = _fragments[_fromFragmentId];

        // Check if link already exists (simple iteration)
        for (uint i = 0; i < fromFragment.linkedFragments.length; i++) {
            require(fromFragment.linkedFragments[i] != _toFragmentId, "Link already exists");
        }

        fromFragment.linkedFragments.push(_toFragmentId);

        // Note: Linking increases complexity slightly or influences resonance, handled implicitly by calculation functions

        emit FragmentLinked(_fromFragmentId, _toFragmentId);
    }

     /**
     * @dev Removes a link from one fragment to another.
     * @param _fromFragmentId The ID of the fragment where the link originates.
     * @param _toFragmentId The ID of the fragment the link points to.
     */
    function removeLink(uint256 _fromFragmentId, uint256 _toFragmentId) external fragmentExists(_fromFragmentId) onlyFragmentOwner(_fromFragmentId) {
        Fragment storage fromFragment = _fragments[_fromFragmentId];
        bool found = false;
        uint256 indexToRemove = fromFragment.linkedFragments.length; // Invalid index initially

        // Find the index of the link to remove
        for (uint i = 0; i < fromFragment.linkedFragments.length; i++) {
            if (fromFragment.linkedFragments[i] == _toFragmentId) {
                indexToRemove = i;
                found = true;
                break;
            }
        }

        require(found, "Link does not exist");

        // Efficiently remove the link by swapping with the last element
        uint256 lastIndex = fromFragment.linkedFragments.length - 1;
        if (indexToRemove != lastIndex) {
            fromFragment.linkedFragments[indexToRemove] = fromFragment.linkedFragments[lastIndex];
        }
        fromFragment.linkedFragments.pop();

        emit FragmentLinkRemoved(_fromFragmentId, _toFragmentId);
    }


    // --- Dynamic State & Evolution Functions ---

    /**
     * @dev Adds energy to a fragment. Costs ETH.
     * @param _fragmentId The ID of the fragment to energize.
     */
    function energizeFragment(uint256 _fragmentId) external payable fragmentExists(_fragmentId) onlyFragmentOwner(_fragmentId) {
        require(msg.value > 0, "Must send ETH to energize");

        Fragment storage fragment = _fragments[_fragmentId];
        uint256 energyAdded = msg.value / ENERGIZE_COST_PER_UNIT;
        require(energyAdded > 0, "Sent amount too low for any energy");

        fragment.energy += energyAdded;

        emit FragmentEnergized(_fragmentId, msg.sender, energyAdded);
    }

    /**
     * @dev Attempts to evolve a fragment. Requires sufficient energy and time since last evolution/decay.
     *      Evolution can change properties and complexity.
     */
    function evolveFragment(uint256 _fragmentId) external fragmentExists(_fragmentId) onlyFragmentOwner(_fragmentId) {
        Fragment storage fragment = _fragments[_fragmentId];
        uint64 currentTime = uint64(block.timestamp);

        require(fragment.energy >= EVOLUTION_ENERGY_THRESHOLD, "Insufficient energy for evolution");
        require(currentTime >= fragment.lastEvolutionTime + DECAY_INTERVAL, "Fragment needs time before evolving again"); // Use decay interval as cooldown

        // Consume energy
        fragment.energy -= EVOLUTION_ENERGY_THRESHOLD;

        // Attempt evolution logic (simplified): properties shift based on complexity and resonance
        // Higher complexity/resonance might push properties towards higher values
        uint256 complexityEffect = fragment.complexity / 50; // Scale complexity effect
        uint224 resonanceEffect = uint224(_calculateResonance(_fragmentId) / 100); // Scale resonance effect

        for(uint8 i=0; i<4; i++) {
            // Influence property change based on complexity, resonance, and some entropy
             uint256 influence = complexityEffect + resonanceEffect + (uint256(keccak256(abi.encodePacked(_fragmentId, currentTime, i))) % 10); // Add random factor

            if (influence > 0) {
                 uint256 change = influence / 2; // Determine magnitude of change
                 if (change == 0) change = 1; // Minimum change is 1

                 // Direction of change (e.g., random or based on desired state)
                 // Simplified: Random chance to increase or decrease, biased by complexity/resonance
                 if (uint256(keccak256(abi.encodePacked(currentTime, i, "direction"))) % 100 < 60 + complexityEffect/5) { // Bias towards increase
                      fragment.coreProperties[i] += change;
                      if (fragment.coreProperties[i] > 1000) fragment.coreProperties[i] = 1000; // Cap property value
                 } else {
                      if (fragment.coreProperties[i] >= change) {
                           fragment.coreProperties[i] -= change;
                      } else {
                           fragment.coreProperties[i] = 0; // Floor property value
                      }
                 }
            }
        }

        // Evolution increases complexity (or shifts it based on new properties)
        fragment.complexity = _calculateBaseComplexity(fragment.coreProperties); // Recalculate based on new properties
        fragment.complexity += (complexityEffect / 5); // Add bonus complexity from the process itself


        fragment.lastEvolutionTime = currentTime;
        emit FragmentEvolved(_fragmentId, currentTime);
    }

    /**
     * @dev Explicitly triggers decay for a fragment. Decay happens if enough time has passed.
     *      Decay reduces energy and complexity.
     */
    function decayFragment(uint256 _fragmentId) external fragmentExists(_fragmentId) {
        // Can be called by anyone to help clean up/push the simulation forward,
        // as long as enough time has passed. Owner calling it is most likely.
        Fragment storage fragment = _fragments[_fragmentId];
        uint64 currentTime = uint64(block.timestamp);

        require(currentTime >= fragment.lastEvolutionTime + DECAY_INTERVAL, "Decay interval has not passed yet");

        // Decay logic (simplified): reduce energy and complexity
        uint256 timeElapsed = currentTime - fragment.lastEvolutionTime;
        uint256 decayAmount = (timeElapsed / DECAY_INTERVAL) * (fragment.complexity / 10); // Decay based on time and complexity

        if (fragment.energy >= decayAmount) {
            fragment.energy -= decayAmount;
        } else {
            fragment.energy = 0;
        }

        if (fragment.complexity >= decayAmount/2) { // Complexity decays slower
            fragment.complexity -= decayAmount/2;
        } else {
             fragment.complexity = 0;
        }

         // Properties might also decay slightly (e.g., if complexity drops significantly)
         // Simplified: No direct property decay here unless complexity hits zero.

        fragment.lastEvolutionTime = currentTime;
        emit FragmentDecayed(_fragmentId, currentTime);
    }

    /**
     * @dev Allows the owner to attempt to discover or enhance a property on a fragment.
     *      Probabilistic success, consumes energy.
     */
    function discoverFragmentProperty(uint256 _fragmentId) external fragmentExists(_fragmentId) onlyFragmentOwner(_fragmentId) {
        Fragment storage fragment = _fragments[_fragmentId];
        require(fragment.energy >= DISCOVERY_ENERGY_COST, "Insufficient energy for discovery attempt");

        fragment.energy -= DISCOVERY_ENERGY_COST;

        (bool success, uint8 discoveredIndex, uint256 newValue) = _tryDiscoverProperty(_fragmentId, fragment.energy); // Use energy as a modifier for entropy

        if (success) {
            fragment.coreProperties[discoveredIndex] = newValue;
            // Discovery also slightly increases complexity
            fragment.complexity = _calculateBaseComplexity(fragment.coreProperties) + 5; // Base recalculation + discovery bonus
            emit PropertyDiscovered(_fragmentId, discoveredIndex, newValue);
        }
        // No event on failure, just energy consumed
    }


    // --- Structural Operations ---

    /**
     * @dev Merges two fragments owned by the caller into a new, potentially more complex one.
     *      Consumes energy and potentially the original fragments.
     *      Simplified: Creates a new fragment, burns the parents, inherits combined traits.
     */
    function mergeFragments(uint256 _fragmentId1, uint256 _fragmentId2) external fragmentExists(_fragmentId1) fragmentExists(_fragmentId2) onlyFragmentOwner(_fragmentId1) {
         require(msg.sender == _fragments[_fragmentId2].owner, "Must own both fragments to merge");
         require(_fragmentId1 != _fragmentId2, "Cannot merge a fragment with itself");
         // Add complexity/energy requirement for merging
         uint256 mergeCost = MERGE_ENERGY_COST_PER_FRAGMENT * 2;
         require(_fragments[_fragmentId1].energy + _fragments[_fragmentId2].energy >= mergeCost, "Insufficient combined energy for merge");

         // Basic merge logic: Create a new fragment influenced by both parents
         _fragmentCounter++;
         uint256 newFragmentId = _fragmentCounter;
         uint64 currentTime = uint64(block.timestamp);

         uint256[4] memory mergedProperties;
         for(uint8 i=0; i<4; i++) {
              // Simple average + bonus based on combined complexity
              mergedProperties[i] = (_fragments[_fragmentId1].coreProperties[i] + _fragments[_fragmentId2].coreProperties[i]) / 2;
              uint256 complexityBonus = (_fragments[_fragmentId1].complexity + _fragments[_fragmentId2].complexity) / 100;
              mergedProperties[i] += complexityBonus;
              if (mergedProperties[i] > 1000) mergedProperties[i] = 1000; // Cap
         }

         // New fragment's energy is remainder after cost
         uint256 newEnergy = (_fragments[_fragmentId1].energy + _fragments[_fragmentsId2].energy) - mergeCost;

         Fragment storage newFragment = _fragments[newFragmentId];
         newFragment.id = newFragmentId;
         newFragment.owner = msg.sender;
         newFragment.creationTime = currentTime;
         // New seed derived from parents' seeds
         newFragment.seed = keccak256(abi.encodePacked(_fragments[_fragmentId1].seed, _fragments[_fragmentId2].seed));
         newFragment.coreProperties = mergedProperties;
         newFragment.energy = newEnergy;
         newFragment.complexity = _calculateBaseComplexity(mergedProperties) + (_fragments[_fragmentId1].complexity + _fragments[_fragmentId2].complexity) / 5; // Higher complexity after merge
         newFragment.royaltyPercentageBps = 0; // Reset royalty on new fragment
         newFragment.lastEvolutionTime = currentTime;

         _addFragmentToOwner(msg.sender, newFragmentId);

         // Burn the parent fragments (effectively remove from owner list and mark as inactive/deleted)
         // In a real system, you might just mark them inactive or transfer to a burn address
         _removeFragmentFromOwner(msg.sender, _fragmentId1);
         _removeFragmentFromOwner(msg.sender, _fragmentId2);
         delete _fragments[_fragmentId1]; // Clears storage slot
         delete _fragments[_fragmentId2];

         emit FragmentsMerged(_fragmentId1, _fragmentId2, newFragmentId);
    }

    /**
     * @dev Splits a complex fragment owned by the caller into multiple simpler ones.
     *      Requires sufficient complexity and energy.
     *      Simplified: Creates new fragments with lower properties, burns the parent.
     *      Returns the IDs of the new fragments.
     */
    function splitFragment(uint256 _fragmentId) external fragmentExists(_fragmentId) onlyFragmentOwner(_fragmentId) returns (uint256[] memory) {
        Fragment storage parentFragment = _fragments[_fragmentId];
        require(parentFragment.complexity >= 500, "Fragment not complex enough to split"); // Example complexity threshold
        require(parentFragment.energy >= SPLIT_ENERGY_COST, "Insufficient energy to split");

        parentFragment.energy -= SPLIT_ENERGY_COST;

        uint8 numNewFragments = uint8(parentFragment.complexity / 200); // Number of fragments based on complexity
        if (numNewFragments < 2) numNewFragments = 2; // Always split into at least 2
        if (numNewFragments > 4) numNewFragments = 4; // Cap the number of splits

        uint256[] memory newFragmentIds = new uint256[](numNewFragments);
        uint64 currentTime = uint64(block.timestamp);
        address owner = msg.sender;

        for(uint8 i = 0; i < numNewFragments; i++) {
             _fragmentCounter++;
             uint256 newFragmentId = _fragmentCounter;
             newFragmentIds[i] = newFragmentId;

             uint256[4] memory splitProperties;
             uint256 baseProperty = parentFragment.complexity / (numNewFragments * 50); // Base property value influenced by parent complexity
             if (baseProperty > 50) baseProperty = 50; // Cap base

             bytes32 entropy = keccak256(abi.encodePacked(parentFragment.id, currentTime, i));
             for(uint8 j=0; j<4; j++) {
                  // Properties are lower than parent, influenced by base and entropy
                  splitProperties[j] = baseProperty + (uint256(keccak256(abi.encodePacked(entropy, j))) % 51); // Add 0-50
                  if (splitProperties[j] > 100) splitProperties[j] = 100; // Cap split properties lower than parent caps
             }

             Fragment storage newFragment = _fragments[newFragmentId];
             newFragment.id = newFragmentId;
             newFragment.owner = owner;
             newFragment.creationTime = currentTime;
             // New seed derived from parent seed and split index
             newFragment.seed = keccak256(abi.encodePacked(parentFragment.seed, i));
             newFragment.coreProperties = splitProperties;
             newFragment.energy = parentFragment.energy / (numNewFragments + 1); // Distribute some energy
             newFragment.complexity = _calculateBaseComplexity(splitProperties); // Lower complexity
             newFragment.royaltyPercentageBps = 0;
             newFragment.lastEvolutionTime = currentTime;

             _addFragmentToOwner(owner, newFragmentId);
        }

        // Burn the parent fragment
        _removeFragmentFromOwner(owner, _fragmentId);
        delete _fragments[_fragmentId];

        emit FragmentSplit(parentFragment.id, newFragmentIds);
        return newFragmentIds;
    }


    // --- Value & Interaction Functions ---

    /**
     * @dev Allows harvesting abstract resources or value from a fragment.
     *      Consumes energy, potentially reduces complexity.
     *      Simplified: Burns energy, potentially allows withdrawal of accumulated contract ETH (from creation/energize costs).
     *      Returns the amount of ETH harvested.
     */
    function harvestFragment(uint256 _fragmentId) external fragmentExists(_fragmentId) onlyFragmentOwner(_fragmentId) returns (uint256) {
        Fragment storage fragment = _fragments[_fragmentId];
        require(fragment.energy >= HARVEST_ENERGY_COST, "Insufficient energy for harvest");

        fragment.energy -= HARVEST_ENERGY_COST;

        // Harvesting reduces complexity over time
        if (fragment.complexity >= 5) { // Minimum complexity reduction
             fragment.complexity -= 5;
        } else {
             fragment.complexity = 0;
        }

        // --- Value Extraction Logic ---
        // This is highly conceptual. It could trigger creation of other tokens, update state, etc.
        // Simplest form: Allow withdrawal of a tiny amount of ETH from contract balance
        // based on energy consumed. This makes the contract a sink for ETH that can be trickled out.
        uint256 ethHarvested = HARVEST_ENERGY_COST * ENERGIZE_COST_PER_UNIT / 2; // Earn back half the energize cost of the energy consumed
        if (address(this).balance < ethHarvested) {
            ethHarvested = address(this).balance; // Don't send more than the contract has
        }

        if (ethHarvested > 0) {
             (bool success, ) = payable(msg.sender).call{value: ethHarvested}("");
             require(success, "ETH transfer failed during harvest");
        } else {
             // If no ETH is harvested (e.g., contract balance too low), still emit event
        }

        emit FragmentHarvested(_fragmentId, msg.sender, HARVEST_ENERGY_COST);
        return ethHarvested;
    }

    /**
     * @dev Sets the royalty percentage for a fragment. Owner only.
     * @param _fragmentId The ID of the fragment.
     * @param _percentage The royalty percentage in basis points (1/100th of a percent). Max 10000 (100%).
     */
    function setFragmentRoyaltyPercentage(uint256 _fragmentId, uint16 _percentage) external fragmentExists(_fragmentId) onlyFragmentOwner(_fragmentId) {
        require(_percentage <= 10000, "Royalty percentage exceeds 100%");
        _fragments[_fragmentId].royaltyPercentageBps = _percentage;
        emit RoyaltyPercentageUpdated(_fragmentId, _percentage);
    }

    /**
     * @dev Allows anyone to pay the defined royalty to the fragment owner.
     * @param _fragmentId The ID of the fragment.
     */
    function payFragmentRoyalty(uint256 _fragmentId) external payable fragmentExists(_fragmentId) {
         require(msg.value > 0, "Must send ETH to pay royalty");
         Fragment storage fragment = _fragments[_fragmentId];
         uint16 royaltyBps = fragment.royaltyPercentageBps;

         if (royaltyBps > 0) {
              uint256 royaltyAmount = (msg.value * royaltyBps) / 10000;
              if (royaltyAmount > 0) {
                   (bool success, ) = payable(fragment.owner).call{value: royaltyAmount}("");
                   require(success, "Royalty payment failed");
                   emit RoyaltyPaid(_fragmentId, msg.sender, royaltyAmount);
              }
              // Send remaining ETH back to the payer (if any)
              uint256 remainder = msg.value - royaltyAmount;
              if (remainder > 0) {
                   (bool success, ) = payable(msg.sender).call{value: remainder}("");
                   require(success, "Remainder ETH refund failed"); // Should not fail after royalty paid
              }
         } else {
             // No royalty set, refund all ETH
             (bool success, ) = payable(msg.sender).call{value: msg.value}("");
             require(success, "ETH refund failed");
         }
    }


    // --- Query Functions ---

    /**
     * @dev Returns the total number of fragments created.
     */
    function getFragmentCount() external view returns (uint256) {
        return _fragmentCounter;
    }

    /**
     * @dev Returns the core details of a fragment.
     */
    function getFragmentDetails(uint256 _fragmentId) external view fragmentExists(_fragmentId) returns (
        uint256 id,
        address owner,
        uint64 creationTime,
        uint256 seed,
        uint256[4] memory coreProperties,
        uint256 energy,
        uint256 complexity,
        uint16 royaltyPercentageBps,
        uint64 lastEvolutionTime
    ) {
        Fragment storage fragment = _fragments[_fragmentId];
        return (
            fragment.id,
            fragment.owner,
            fragment.creationTime,
            fragment.seed,
            fragment.coreProperties,
            fragment.energy,
            fragment.complexity, // Note: Complexity is stored, not recalculated here
            fragment.royaltyPercentageBps,
            fragment.lastEvolutionTime
        );
    }

     /**
     * @dev Returns a specific property value of a fragment.
     * @param _fragmentId The ID of the fragment.
     * @param _propertyIndex The index of the property (0-3).
     */
    function getFragmentProperty(uint256 _fragmentId, uint8 _propertyIndex) external view fragmentExists(_fragmentId) returns (uint256) {
         require(_propertyIndex < 4, "Invalid property index");
         return _fragments[_fragmentId].coreProperties[_propertyIndex];
    }


    /**
     * @dev Returns the owner of a fragment.
     */
    function getFragmentOwner(uint256 _fragmentId) external view fragmentExists(_fragmentId) returns (address) {
        return _fragments[_fragmentId].owner;
    }

    /**
     * @dev Returns the list of fragment IDs owned by a specific address.
     */
    function getFragmentsOwnedByUser(address _user) external view returns (uint256[] memory) {
        return shallow_fragmentsOwned[_user];
    }

    /**
     * @dev Returns the list of fragment IDs linked from a specific fragment.
     */
    function getFragmentLinks(uint256 _fragmentId) external view fragmentExists(_fragmentId) returns (uint256[] memory) {
        return _fragments[_fragmentId].linkedFragments;
    }

     /**
     * @dev Returns the current energy level of a fragment.
     */
    function getFragmentEnergy(uint256 _fragmentId) external view fragmentExists(_fragmentId) returns (uint256) {
        return _fragments[_fragmentId].energy;
    }

    /**
     * @dev Calculates and returns the current complexity score of a fragment.
     *      Note: This recalculates based on current properties. The stored complexity might lag until evolution/decay.
     */
    function getFragmentComplexity(uint256 _fragmentId) external view fragmentExists(_fragmentId) returns (uint256) {
         return _fragments[_fragmentId].complexity; // Returning the stored value for gas efficiency
         // Alternative: Recalculate: return _calculateBaseComplexity(_fragments[_fragmentId].coreProperties);
    }

    /**
     * @dev Calculates and returns the resonance score of a fragment.
     *      This involves looking up linked fragments and their properties.
     *      Gas cost depends on the number of links.
     */
    function getFragmentResonance(uint256 _fragmentId) external view fragmentExists(_fragmentId) returns (uint256) {
        return _calculateResonance(_fragmentId);
    }

     /**
     * @dev Returns the initial creation seed of a fragment.
     */
    function getFragmentSeed(uint256 _fragmentId) external view fragmentExists(_fragmentId) returns (uint256) {
        return _fragments[_fragmentId].seed;
    }

    /**
     * @dev Returns the creation timestamp of a fragment.
     */
    function getFragmentCreationTime(uint256 _fragmentId) external view fragmentExists(_fragmentId) returns (uint64) {
        return _fragments[_fragmentId].creationTime;
    }

    /**
     * @dev Returns the timestamp of the last evolution or decay event.
     */
    function getFragmentLastEvolutionTime(uint256 _fragmentId) external view fragmentExists(_fragmentId) returns (uint64) {
        return _fragments[_fragmentId].lastEvolutionTime;
    }

     /**
     * @dev Returns the current royalty percentage for a fragment in basis points.
     */
    function getFragmentRoyaltyPercentage(uint256 _fragmentId) external view fragmentExists(_fragmentId) returns (uint16) {
        return _fragments[_fragmentId].royaltyPercentageBps;
    }

    // Total functions: 25
    // createFragment, energizeFragment, evolveFragment, decayFragment, harvestFragment,
    // linkFragments, removeLink, mergeFragments, splitFragment, discoverFragmentProperty,
    // transferFragment, setFragmentRoyaltyPercentage, payFragmentRoyalty, getFragmentCount,
    // getFragmentDetails, getFragmentOwner, getFragmentsOwnedByUser, getFragmentLinks,
    // getFragmentEnergy, getFragmentComplexity, getFragmentResonance, getFragmentSeed,
    // getFragmentCreationTime, getFragmentLastEvolutionTime, getFragmentRoyaltyPercentage, getFragmentProperty (26!) - okay, over 20.
}
```