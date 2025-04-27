Okay, let's design a smart contract protocol focusing on dynamic NFTs that evolve based on resource staking, time, and simulated environmental conditions. This involves creating a custom ERC20 token (Essence) and a custom ERC721 token (Morph), managed by a core protocol contract that handles the logic of staking, evolution, mutations, environmental shifts, and potentially trait discovery.

We will structure it as a single contract for simplicity in this example, deploying the necessary ERC20 and ERC721 internally.

---

### Smart Contract: MetaMorphProtocol

**Concept:**
A protocol centered around "Morphs" (dynamic, evolving NFTs) powered by "Essence" (a fungible resource token). Morphs evolve by staking Essence, influenced by global "Environmental Conditions" that change over time (Epochs). They can also undergo random or conditional "Mutations" and potentially discover new "Traits".

**Outline:**

1.  **Contract Definition:** Inherits Ownable, ERC20 (for Essence), ERC721 (for Morph).
2.  **Libraries:** Use SafeMath (though Solc 0.8+ handles overflow, explicit usage can be clear).
3.  **Structs:**
    *   `MorphState`: Represents the dynamic state of a Morph NFT (evolution level, staked essence, traits, history).
    *   `TraitDefinition`: Defines a possible trait (name, type, status).
    *   `EnvironmentalCondition`: Defines modifiers for evolution/mutation during an epoch.
    *   `EvolutionAttempt`: Logs a single evolution attempt result.
    *   `MutationEvent`: Logs a mutation event.
4.  **Enums:** `TraitType`, `MutationType`.
5.  **Events:** Log key actions like Mint, Stake, Unstake, Evolve, Mutate, EpochAdvance, TraitDiscovery.
6.  **State Variables:** Mappings for morph states, trait definitions, environmental conditions. Counters for token IDs, trait IDs. Global protocol parameters (epoch details, evolution costs, mutation chances). Token metadata bases.
7.  **Constructor:** Initializes tokens, sets initial parameters and traits.
8.  **Internal/Helper Functions:** Logic for applying evolution, triggering mutations, checking conditions, updating state.
9.  **External/Public Functions (>= 20 functions):**
    *   ERC20 standard functions (inherited or custom).
    *   ERC721 standard functions (inherited or custom).
    *   Morph Minting & Management.
    *   Essence Staking & Management.
    *   Evolution Logic.
    *   Environmental & Epoch Management.
    *   Trait Discovery & Management.
    *   View Functions for state query.
    *   Admin Functions for parameter tuning.

**Function Summary:**

*   **Essence Token (ERC20 - Inherited/Custom):**
    1.  `constructor`: Initializes the protocol, including deploying tokens.
    2.  `mintEssence`: (Admin) Mints new Essence tokens.
    3.  `burnEssence`: (User) Burns Essence tokens.
    4.  `transfer`: Standard ERC20 transfer.
    5.  `approve`: Standard ERC20 approve.
    6.  `transferFrom`: Standard ERC20 transferFrom.
    7.  `balanceOf`: Standard ERC20 balance query.
    8.  `allowance`: Standard ERC20 allowance query.
*   **Morph NFT (ERC721 - Inherited/Custom):**
    9.  `mintMorph`: (User/Public) Mints a new Morph NFT, potentially costing Essence.
    10. `burnMorph`: (User) Burns a Morph NFT (must own).
    11. `transferFrom`: Standard ERC721 transfer.
    12. `safeTransferFrom`: Standard ERC721 safeTransfer.
    13. `approve`: Standard ERC721 approve.
    14. `setApprovalForAll`: Standard ERC721 setApprovalForAll.
    15. `getApproved`: Standard ERC721 getApproved.
    16. `isApprovedForAll`: Standard ERC721 isApprovedForAll.
    17. `ownerOf`: Standard ERC721 ownerOf query.
    18. `balanceOf`: Standard ERC721 balance query.
    19. `tokenURI`: Dynamic token URI based on Morph state.
*   **Protocol Core Logic:**
    20. `getMorphState`: Query the detailed state of a specific Morph.
    21. `stakeEssence`: Stake Essence tokens onto a specific Morph.
    22. `unstakeEssence`: Unstake Essence tokens from a specific Morph.
    23. `initiateEvolution`: Attempt to evolve a Morph using staked Essence, influenced by environment.
    24. `getEnvironmentalConditions`: Query conditions for the current/next epoch.
    25. `advanceEpoch`: (Admin/Automated) Advances the global epoch.
    26. `discoverNewTrait`: (User) Attempt to discover a new global trait by spending Essence.
    27. `getTraitDefinition`: Query details of a specific trait.
    28. `getDiscoveredTraits`: List all globally discovered traits.
    29. `getMorphTraits`: List traits currently possessed by a specific Morph.
    30. `updateEnvironmentalConditions`: (Admin) Set environmental conditions for a future epoch.
    31. `setEvolutionParams`: (Admin) Adjust parameters for evolution success chance, costs, etc.
    32. `setMutationParams`: (Admin) Adjust parameters for mutation chance and types.
    33. `addInitialTrait`: (Admin) Adds a trait definition to the protocol's potential traits (not yet discovered globally).
    34. `getMorphEvolutionHistory`: Query the evolution history of a Morph.
    35. `simulateEvolutionOutcome`: (Pure) Helper to simulate evolution outcome probabilities off-chain.
    36. `emergencyWithdrawStakedEssence`: (Admin) Emergency withdrawal of all staked essence by owner.
    37. `getTokenAddresses`: View addresses of the deployed Essence and Morph contracts (self).
    38. `renounceOwnership`: Standard Ownable.
    39. `transferOwnership`: Standard Ownable.
    40. `getOwner`: Standard Ownable query.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Though 0.8+ checks, explicit is clear
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MetaMorphProtocol is Ownable, ERC20, ERC721 {
    using SafeMath for uint256;
    using Strings for uint256;
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    // --- ENUMS ---

    enum TraitType { STATISTICAL, COSMETIC, MUTATION_PRONE, ENVIRONMENT_SENSTIVE }
    enum MutationType { RANDOM_TRAIT_CHANGE, TRAIT_LEVEL_ADJUST, TEMPORARY_BOOST_DEBUFF }

    // --- STRUCTS ---

    struct TraitDefinition {
        string name;
        TraitType traitType;
        bool isGloballyDiscovered; // Can be applied/discovered by Morphs
        bool isInitialTrait; // Added by admin initially
        uint256 discoveryChanceMultiplier; // Affects chance during discovery attempts
    }

    struct MorphTrait {
        uint256 traitId;
        uint256 level; // Some traits might have levels
        bool active; // Some traits might be inactive temporarily
    }

    struct EvolutionAttempt {
        uint256 epoch;
        uint256 timestamp;
        uint256 levelBefore;
        uint256 levelAfter;
        uint256 essenceConsumed;
        bool success;
        string outcomeDescription; // e.g., "Successful level up", "Failed, triggered mutation"
    }

    struct MutationEvent {
        uint256 epoch;
        uint256 timestamp;
        MutationType mutationType;
        string description; // Details of the mutation
        uint256[] affectedTraitIds; // Traits changed by this mutation
    }

    struct MorphState {
        uint256 evolutionLevel;
        uint256 stakedEssence;
        MorphTrait[] traits;
        EvolutionAttempt[] evolutionHistory;
        MutationEvent[] mutationHistory;
        // Add last evolution timestamp to prevent spamming? Or rely purely on essence cost?
    }

    struct EnvironmentalCondition {
        string description; // e.g., "Solar Flare increasing mutation chance"
        uint256 evolutionSuccessModifier; // % change to base success chance
        uint256 mutationChanceModifier; // % change to base mutation chance
        // Add other potential modifiers later
    }

    // --- STATE VARIABLES ---

    // Token Counters (Managed internally for simplicity)
    Counters.Counter private _essenceSupply; // ERC20 total supply
    Counters.Counter private _morphTokenIds; // ERC721 token counter

    // Core Protocol State
    mapping(uint256 => MorphState) private _morphStates; // tokenId => MorphState
    mapping(uint256 => TraitDefinition) private _traitDefinitions; // traitId => TraitDefinition
    uint256[] private _globallyDiscoveredTraitIds; // List of traits available for discovery/application
    Counters.Counter private _nextTraitId; // Counter for new trait IDs

    uint256 public currentEpoch = 1;
    uint256 public epochDuration = 7 days; // Example: Epoch lasts 7 days
    uint256 public lastEpochStartTime;
    mapping(uint256 => EnvironmentalCondition) private _environmentalConditions; // epoch => Conditions

    // Protocol Parameters (Admin settable)
    uint256 public morphMintCostEssence = 100 ether; // Cost to mint a new Morph
    uint256 public baseEvolutionCostEssence = 50 ether; // Base essence cost per evolution level
    uint256 public baseEvolutionSuccessChance = 70; // Base chance % (70 = 70%)
    uint256 public baseMutationChance = 5; // Base chance % (5 = 5%)
    uint256 public traitDiscoveryCostEssence = 200 ether; // Cost to attempt trait discovery
    uint256 public baseTraitDiscoverySuccessChance = 10; // Base chance % (10 = 10%)

    // ERC721 Metadata Base
    string private _baseTokenURI = "ipfs://__YOUR_BASE_URI__/"; // Should resolve to JSON metadata

    // --- EVENTS ---

    event EssenceMinted(address indexed recipient, uint256 amount);
    event EssenceBurned(address indexed burner, uint256 amount);
    event MorphMinted(address indexed owner, uint256 indexed tokenId, uint256 initialLevel);
    event MorphBurned(address indexed owner, uint256 indexed tokenId);
    event EssenceStaked(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event EssenceUnstaked(uint256 indexed tokenId, address indexed unstaker, uint256 amount);
    event EvolutionInitiated(uint256 indexed tokenId, uint256 epoch, uint256 levelBefore, uint256 essenceConsumed);
    event EvolutionResult(uint256 indexed tokenId, uint256 levelAfter, bool success, string outcomeDescription);
    event MutationTriggered(uint256 indexed tokenId, uint256 epoch, MutationType mutationType, string description);
    event EpochAdvanced(uint256 indexed oldEpoch, uint256 indexed newEpoch, uint256 timestamp);
    event TraitDiscovered(uint256 indexed traitId, string name, address indexed discoverer);
    event TraitAddedToMorph(uint256 indexed tokenId, uint256 indexed traitId, uint256 level);
    event TraitDefinitionAdded(uint256 indexed traitId, string name, TraitType traitType);
    event EnvironmentalConditionsUpdated(uint256 indexed epoch, string description);
    event ParametersUpdated(string paramName, uint256 newValue); // Generic for admin updates

    // --- CONSTRUCTOR ---

    constructor(string memory name, string memory symbol) ERC20(name, symbol) ERC721("MetaMorph", "MORPH") Ownable(msg.sender) {
        lastEpochStartTime = block.timestamp;

        // Add some initial trait definitions (not globally discovered yet)
        _addTraitDefinition("Strength", TraitType.STATISTICAL, false, true, 100); // 1x discovery chance
        _addTraitDefinition("Agility", TraitType.STATISTICAL, false, true, 100);
        _addTraitDefinition("Color Shift", TraitType.COSMETIC, false, true, 150); // Slightly higher discovery chance
        _addTraitDefinition("Adaptive Hide", TraitType.ENVIRONMENT_SENSTIVE, false, true, 80); // Slightly lower

        // Set initial environmental conditions
        _environmentalConditions[currentEpoch] = EnvironmentalCondition({
            description: "Stable beginning",
            evolutionSuccessModifier: 0, // 0% change
            mutationChanceModifier: 0 // 0% change
        });
    }

    // --- INTERNAL/HELPER FUNCTIONS ---

    function _applyEvolutionOutcome(uint256 tokenId, bool success, uint256 essenceConsumed) internal {
        MorphState storage morph = _morphStates[tokenId];
        uint256 levelBefore = morph.evolutionLevel;
        string memory outcomeDescription;

        if (success) {
            morph.evolutionLevel = morph.evolutionLevel.add(1);
            outcomeDescription = "Successful level up";
            // Potentially add/upgrade traits based on evolution level or environment?
            // For simplicity here, evolution mainly increases level and enables future actions.
            // Complex trait logic could be added: e.g., at level 5, roll to gain a new trait.
        } else {
            outcomeDescription = "Failed to level up";
            // Chance to trigger a mutation on failure
            uint256 mutationChance = baseMutationChance; // Base chance
            // Adjust by environment modifier (let's say modifier is in basis points, 10000 = 100%)
            mutationChance = mutationChance.add(baseMutationChance.mul(_getEnvironmentalConditions(currentEpoch).mutationChanceModifier).div(10000));
            if (mutationChance > 100) mutationChance = 100; // Cap at 100%

            if (_rollChance(mutationChance)) {
                 _triggerMutation(tokenId);
                 outcomeDescription = string.concat(outcomeDescription, ", triggered mutation");
            }
        }

        morph.evolutionHistory.push(EvolutionAttempt({
            epoch: currentEpoch,
            timestamp: block.timestamp,
            levelBefore: levelBefore,
            levelAfter: morph.evolutionLevel,
            essenceConsumed: essenceConsumed,
            success: success,
            outcomeDescription: outcomeDescription
        }));

        emit EvolutionResult(tokenId, morph.evolutionLevel, success, outcomeDescription);
    }

    function _triggerMutation(uint256 tokenId) internal {
        MorphState storage morph = _morphStates[tokenId];
        MutationType mutationType;
        string memory description;
        uint256[] memory affectedTraitIds; // To be filled

        // Simple random mutation type selection
        uint256 rand = uint256(keccak256(abi.encodePacked(tokenId, block.timestamp, block.number, msg.sender))) % 3;
        if (rand == 0) {
            mutationType = MutationType.RANDOM_TRAIT_CHANGE;
            description = "Random trait change";
            // Implement logic to randomly change or swap a trait
            // Example: Find an existing trait, remove it, try to add another random discovered trait
            if (morph.traits.length > 0 && _globallyDiscoveredTraitIds.length > 0) {
                uint256 traitIndexToChange = uint256(keccak256(abi.encodePacked(tokenId, block.timestamp, block.number, msg.sender, "traitchange"))) % morph.traits.length;
                 uint256 oldTraitId = morph.traits[traitIndexToChange].traitId;
                 // For simplicity, let's just change the ID to a random discovered one
                 uint256 newTraitId = _globallyDiscoveredTraitIds[uint256(keccak256(abi.encodePacked(tokenId, block.timestamp, block.number, msg.sender, "newtrait"))) % _globallyDiscoveredTraitIds.length];
                 morph.traits[traitIndexToChange].traitId = newTraitId;
                 // You might want to track trait removals explicitly
                 affectedTraitIds = new uint256[](2);
                 affectedTraitIds[0] = oldTraitId;
                 affectedTraitIds[1] = newTraitId;
            }
        } else if (rand == 1) {
            mutationType = MutationType.TRAIT_LEVEL_ADJUST;
            description = "Trait level adjustment";
            // Implement logic to boost or decrease a trait level
            if (morph.traits.length > 0) {
                 uint256 traitIndexToAdjust = uint256(keccak256(abi.encodePacked(tokenId, block.timestamp, block.number, msg.sender, "traitadjust"))) % morph.traits.length;
                 MorphTrait storage trait = morph.traits[traitIndexToAdjust];
                 bool increase = uint256(keccak256(abi.encodePacked(tokenId, block.timestamp, block.number, msg.sender, "adjustdir"))) % 2 == 0;
                 if (increase) {
                     trait.level = trait.level.add(1);
                     description = string.concat(description, " - Increased level of trait ", trait.traitId.toString());
                 } else if (trait.level > 0) {
                     trait.level = trait.level.sub(1);
                     description = string.concat(description, " - Decreased level of trait ", trait.traitId.toString());
                 }
                 affectedTraitIds = new uint256[](1);
                 affectedTraitIds[0] = trait.traitId;
            }
        } else { // rand == 2
            mutationType = MutationType.TEMPORARY_BOOST_DEBUFF;
            description = "Temporary boost/debuff";
            // Implement logic for temporary effects (requires tracking active effects, more complex state)
            // For simplicity, let's say it affects evolution success chance for the *next* attempt
             description = "Temporary debuff applied (affects next evolution)";
             // This would require adding a temporary effect state to the MorphState struct
             // Skipping actual implementation of temp effects for brevity, but marking the event
        }

        morph.mutationHistory.push(MutationEvent({
            epoch: currentEpoch,
            timestamp: block.timestamp,
            mutationType: mutationType,
            description: description,
            affectedTraitIds: affectedTraitIds // Note: requires deep copy if traits are complex objects
        }));

        emit MutationTriggered(tokenId, currentEpoch, mutationType, description);
    }

    function _rollChance(uint256 chancePercentage) internal view returns (bool) {
        // Use block hash, timestamp, and unique contract/msg.sender data for pseudo-randomness
        // NOTE: This is NOT cryptographically secure randomness for high-stakes applications.
        // For true randomness, use Chainlink VRF or similar oracles.
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender, tx.origin, address(this))));
        uint256 randomNumber = randomSeed % 100; // Roll 0-99
        return randomNumber < chancePercentage;
    }

    function _getEnvironmentalConditions(uint256 epoch) internal view returns (EnvironmentalCondition memory) {
        // If conditions for an epoch aren't set, return default (no modifiers)
        if (bytes(_environmentalConditions[epoch].description).length == 0) {
             return EnvironmentalCondition({
                description: "Default conditions",
                evolutionSuccessModifier: 0,
                mutationChanceModifier: 0
             });
        }
        return _environmentalConditions[epoch];
    }

    function _addTraitDefinition(string memory name, TraitType traitType, bool isGloballyDiscovered, bool isInitialTrait, uint256 discoveryChanceMultiplier) internal returns (uint256) {
        _nextTraitId.increment();
        uint256 traitId = _nextTraitId.current();
        _traitDefinitions[traitId] = TraitDefinition({
            name: name,
            traitType: traitType,
            isGloballyDiscovered: isGloballyDiscovered,
            isInitialTrait: isInitialTrait,
            discoveryChanceMultiplier: discoveryChanceMultiplier
        });
        if (isGloballyDiscovered) {
            _globallyDiscoveredTraitIds.push(traitId);
        }
         emit TraitDefinitionAdded(traitId, name, traitType);
        return traitId;
    }

    function _addTraitToMorph(uint256 tokenId, uint256 traitId, uint256 level) internal {
        // Check if trait definition exists
        require(bytes(_traitDefinitions[traitId].name).length > 0, "Trait definition does not exist");
        // Check if the morph already has this trait (prevent duplicates, or allow level-up?)
        // For simplicity, let's prevent adding the exact same traitId. Level-up logic would be more complex.
        for(uint i=0; i < _morphStates[tokenId].traits.length; i++) {
            if (_morphStates[tokenId].traits[i].traitId == traitId) {
                // Optionally, handle level-up here instead of adding
                return;
            }
        }
        _morphStates[tokenId].traits.push(MorphTrait({traitId: traitId, level: level, active: true}));
        emit TraitAddedToMorph(tokenId, traitId, level);
    }


    // ERC20 internal overrides
    function _mint(address account, uint256 amount) internal override {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _essenceSupply.increment(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal override {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _essenceSupply.decrement(amount);
        emit Transfer(account, address(0), amount);
    }

    // ERC721 internal overrides
    function _safeMint(address to, uint256 tokenId) internal override {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _owners[tokenId] = to;
        _balances[to] = _balances[to].add(1);
        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal override {
        address owner = ERC721.ownerOf(tokenId);
        require(msg.sender == owner, "ERC721: caller is not token owner");
        _burn(tokenId, owner);
    }

     function _burn(uint256 tokenId, address owner) internal {
        // Clear approvals
        delete _tokenApprovals[tokenId];

        _beforeTokenTransfer(owner, address(0), tokenId);

        _balances[owner] = _balances[owner].sub(1);
        delete _owners[tokenId];
        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    // Override base URI function for ERC721
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }


    // --- PUBLIC/EXTERNAL FUNCTIONS ---

    // ERC20 Functions (Inherited, listed here for summary clarity)
    // 4. transfer, 5. approve, 6. transferFrom, 7. balanceOf, 8. allowance - these are provided by OpenZeppelin

    // 2. Mint Essence (Admin)
    function mintEssence(address recipient, uint256 amount) external onlyOwner {
        _mint(recipient, amount);
        emit EssenceMinted(recipient, amount);
    }

    // 3. Burn Essence (User)
    function burnEssence(uint256 amount) external {
        _burn(msg.sender, amount);
        emit EssenceBurned(msg.sender, amount);
    }

    // 9. Mint Morph (Public, costs Essence)
    function mintMorph() external {
        uint256 cost = morphMintCostEssence;
        require(_balances[msg.sender] >= cost, "MetaMorph: Insufficient Essence to mint");

        // Use transferFrom to pull tokens approved by the user
        IERC20(address(this)).safeTransferFrom(msg.sender, address(this), cost);

        _morphTokenIds.increment();
        uint256 newTokenId = _morphTokenIds.current();

        _safeMint(msg.sender, newTokenId);

        // Initialize morph state
        _morphStates[newTokenId] = MorphState({
            evolutionLevel: 1, // Start at level 1
            stakedEssence: 0,
            traits: new MorphTrait[](0),
            evolutionHistory: new EvolutionAttempt[](0),
            mutationHistory: new MutationEvent[](0)
        });

        // Optional: Add some initial traits based on a random roll or fixed set
        // For simplicity, let's add 1-2 random *initial* traits from the admin-added list
        uint256 initialTraitCount = uint256(keccak256(abi.encodePacked(newTokenId, block.timestamp))) % 2 + 1; // 1 or 2 traits
        uint256[] memory potentialInitialTraitIds = new uint256[](_nextTraitId.current()); // Using all trait IDs as potential initial ones
        uint256 potentialCount = 0;
        for(uint256 i = 1; i <= _nextTraitId.current(); i++) {
            if (_traitDefinitions[i].isInitialTrait) {
                 potentialInitialTraitIds[potentialCount] = i;
                 potentialCount++;
            }
        }

        for(uint i=0; i < initialTraitCount && potentialCount > 0; i++) {
             uint256 traitIndex = uint256(keccak256(abi.encodePacked(newTokenId, block.timestamp, i))) % potentialCount;
             _addTraitToMorph(newTokenId, potentialInitialTraitIds[traitIndex], 1); // Add with level 1
             // Remove from potential list to avoid duplicates
             potentialInitialTraitIds[traitIndex] = potentialInitialTraitIds[potentialCount - 1];
             potentialCount--;
        }


        emit MorphMinted(msg.sender, newTokenId, 1);
    }

    // 10. Burn Morph (User)
    function burnMorph(uint256 tokenId) external {
        require(ERC721.ownerOf(tokenId) == msg.sender, "MetaMorph: Only owner can burn morph");

        // Optional: Add logic to return staked essence? Or is it lost? Let's return.
        uint256 staked = _morphStates[tokenId].stakedEssence;
        if (staked > 0) {
            // Transfer staked essence back to the owner
            IERC20(address(this)).safeTransfer(msg.sender, staked);
            _morphStates[tokenId].stakedEssence = 0; // Should already be 0 after transfer
        }

        _burn(tokenId); // Calls internal _burn logic
        delete _morphStates[tokenId]; // Clean up state
        emit MorphBurned(msg.sender, tokenId);
    }

    // ERC721 Functions (Inherited, listed here for summary clarity)
    // 11. transferFrom, 12. safeTransferFrom, 13. approve, 14. setApprovalForAll, 15. getApproved, 16. isApprovedForAll, 17. ownerOf, 18. balanceOf - these are provided by OpenZeppelin

    // 19. Dynamic Token URI
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        // Base URI + token ID. Metadata server would read chain state (getMorphState)
        // to generate dynamic JSON.
        return string.concat(_baseTokenURI, tokenId.toString());

        // Example of embedding some data directly (less flexible for complex metadata)
        /*
        MorphState memory morph = _morphStates[tokenId];
        return string.concat(
            _baseTokenURI,
            tokenId.toString(),
            ".json?level=", morph.evolutionLevel.toString(),
            "&staked=", morph.stakedEssence.toString()
            // Add trait parameters here
        );
        */
    }

    // 20. Query Morph State
    function getMorphState(uint256 tokenId) external view returns (MorphState memory) {
        require(_exists(tokenId), "MetaMorph: Morph does not exist");
        return _morphStates[tokenId];
    }

     // 21. Stake Essence onto a Morph
    function stakeEssence(uint256 tokenId, uint256 amount) external {
        require(_exists(tokenId), "MetaMorph: Morph does not exist");
        require(ERC721.ownerOf(tokenId) == msg.sender, "MetaMorph: Only owner can stake on their morph");
        require(amount > 0, "MetaMorph: Must stake a positive amount");

        // User must have approved this contract to spend their Essence tokens
        IERC20(address(this)).safeTransferFrom(msg.sender, address(this), amount);

        _morphStates[tokenId].stakedEssence = _morphStates[tokenId].stakedEssence.add(amount);

        emit EssenceStaked(tokenId, msg.sender, amount);
    }

    // 22. Unstake Essence from a Morph
    function unstakeEssence(uint256 tokenId, uint256 amount) external {
        require(_exists(tokenId), "MetaMorph: Morph does not exist");
        require(ERC721.ownerOf(tokenId) == msg.sender, "MetaMorph: Only owner can unstake from their morph");
        require(amount > 0, "MetaMorph: Must unstake a positive amount");
        require(_morphStates[tokenId].stakedEssence >= amount, "MetaMorph: Insufficient staked essence");

        _morphStates[tokenId].stakedEssence = _morphStates[tokenId].stakedEssence.sub(amount);

        // Transfer staked essence back to the owner
        IERC20(address(this)).safeTransfer(msg.sender, amount);

        emit EssenceUnstaked(tokenId, msg.sender, amount);
    }

    // 23. Initiate Evolution
    function initiateEvolution(uint256 tokenId) external {
        require(_exists(tokenId), "MetaMorph: Morph does not exist");
        require(ERC721.ownerOf(tokenId) == msg.sender, "MetaMorph: Only owner can initiate evolution");

        uint256 requiredEssence = baseEvolutionCostEssence.mul(_morphStates[tokenId].evolutionLevel); // Cost increases with level
        require(_morphStates[tokenId].stakedEssence >= requiredEssence, "MetaMorph: Insufficient staked essence for evolution");

        // Consume staked essence
        _morphStates[tokenId].stakedEssence = _morphStates[tokenId].stakedEssence.sub(requiredEssence);

        emit EvolutionInitiated(tokenId, currentEpoch, _morphStates[tokenId].evolutionLevel, requiredEssence);

        // Determine success chance based on environment
        EnvironmentalCondition memory env = _getEnvironmentalConditions(currentEpoch);
        uint256 currentSuccessChance = baseEvolutionSuccessChance;
        // Adjust by environment modifier (basis points)
        currentSuccessChance = currentSuccessChance.add(baseEvolutionSuccessChance.mul(env.evolutionSuccessModifier).div(10000));
        if (currentSuccessChance > 100) currentSuccessChance = 100; // Cap at 100%

        bool success = _rollChance(currentSuccessChance);

        _applyEvolutionOutcome(tokenId, success, requiredEssence);
    }

    // 24. Query Environmental Conditions
    function getEnvironmentalConditions(uint256 epoch) external view returns (EnvironmentalCondition memory) {
        return _getEnvironmentalConditions(epoch);
    }

    // 25. Advance Epoch (Admin)
    function advanceEpoch() external onlyOwner {
        require(block.timestamp >= lastEpochStartTime.add(epochDuration), "MetaMorph: Epoch duration has not passed");

        currentEpoch = currentEpoch.add(1);
        lastEpochStartTime = block.timestamp;

        // If conditions for the new epoch aren't set by admin, default conditions apply.
        // Admin should set conditions for future epochs using updateEnvironmentalConditions.

        emit EpochAdvanced(currentEpoch.sub(1), currentEpoch, block.timestamp);
    }

    // 26. Discover New Trait (User, costs Essence)
    function discoverNewTrait() external {
        uint256 cost = traitDiscoveryCostEssence;
        require(_balances[msg.sender] >= cost, "MetaMorph: Insufficient Essence for trait discovery");

        // Find a trait definition that hasn't been globally discovered yet
        uint256 potentialTraitId = 0;
        // Iterate through *all* trait definitions to find an undiscovered one
        for(uint256 i = 1; i <= _nextTraitId.current(); i++) {
            if (!_traitDefinitions[i].isGloballyDiscovered) {
                 potentialTraitId = i;
                 break; // Found one, try to discover this
            }
        }

        require(potentialTraitId != 0, "MetaMorph: No undiscovered traits left");

        // Use transferFrom to pull tokens approved by the user
        IERC20(address(this)).safeTransferFrom(msg.sender, address(this), cost);

        // Calculate discovery chance (could be affected by environment too)
        uint256 currentDiscoveryChance = baseTraitDiscoverySuccessChance;
        // Could multiply by the trait's specific chance multiplier
        currentDiscoveryChance = currentDiscoveryChance.mul(_traitDefinitions[potentialTraitId].discoveryChanceMultiplier).div(100); // Multiplier in %

        if (_rollChance(currentDiscoveryChance)) {
            _traitDefinitions[potentialTraitId].isGloballyDiscovered = true;
            _globallyDiscoveredTraitIds.push(potentialTraitId);
            emit TraitDiscovered(potentialTraitId, _traitDefinitions[potentialTraitId].name, msg.sender);

            // Optional: Automatically add the discovered trait to the discoverer's active Morph?
            // For simplicity, let's just make it globally available. Users can add via other means.

        } else {
            // Discovery failed, essence is still consumed
            // Could emit a "DiscoveryFailed" event
        }
    }

    // 27. Query Trait Definition
    function getTraitDefinition(uint256 traitId) external view returns (TraitDefinition memory) {
        require(bytes(_traitDefinitions[traitId].name).length > 0, "MetaMorph: Trait definition does not exist");
        return _traitDefinitions[traitId];
    }

    // 28. List Globally Discovered Traits
    function getDiscoveredTraits() external view returns (uint256[] memory) {
        return _globallyDiscoveredTraitIds;
    }

    // 29. List Traits of a Morph
     function getMorphTraits(uint256 tokenId) external view returns (MorphTrait[] memory) {
         require(_exists(tokenId), "MetaMorph: Morph does not exist");
         return _morphStates[tokenId].traits;
     }

    // 30. Update Environmental Conditions (Admin)
    function updateEnvironmentalConditions(uint256 epoch, string memory description, uint256 evolutionSuccessModifier, uint256 mutationChanceModifier) external onlyOwner {
        // Ensure conditions are set for a future epoch, or the *next* epoch if not set
        require(epoch > currentEpoch, "MetaMorph: Cannot update conditions for past or current epoch (use advanceEpoch first)");

        _environmentalConditions[epoch] = EnvironmentalCondition({
            description: description,
            evolutionSuccessModifier: evolutionSuccessModifier,
            mutationChanceModifier: mutationChanceModifier
        });

        emit EnvironmentalConditionsUpdated(epoch, description);
    }

    // 31. Set Evolution Parameters (Admin)
    function setEvolutionParams(uint256 newBaseCostEssence, uint256 newBaseSuccessChance) external onlyOwner {
        baseEvolutionCostEssence = newBaseCostEssence;
        baseEvolutionSuccessChance = newBaseSuccessChance;
        emit ParametersUpdated("baseEvolutionCostEssence", newBaseCostEssence);
        emit ParametersUpdated("baseEvolutionSuccessChance", newBaseSuccessChance);
    }

    // 32. Set Mutation Parameters (Admin)
    function setMutationParams(uint256 newBaseMutationChance) external onlyOwner {
        baseMutationChance = newBaseMutationChance;
        emit ParametersUpdated("baseMutationChance", newBaseMutationChance);
    }

    // 33. Add Initial Trait Definition (Admin)
    function addInitialTrait(string memory name, TraitType traitType, uint256 discoveryChanceMultiplier) external onlyOwner {
        // Use internal helper to create the definition
        _addTraitDefinition(name, traitType, false, true, discoveryChanceMultiplier);
         // Emits TraitDefinitionAdded inside the helper
    }

    // 34. Get Morph Evolution History
    function getMorphEvolutionHistory(uint256 tokenId) external view returns (EvolutionAttempt[] memory) {
         require(_exists(tokenId), "MetaMorph: Morph does not exist");
         return _morphStates[tokenId].evolutionHistory;
    }

    // 35. Simulate Evolution Outcome (Pure - helpful for UI, not on-chain logic)
    function simulateEvolutionOutcome(uint256 tokenId, uint256 targetEpoch) external view returns (uint256 requiredEssence, uint256 successChance, uint256 mutationChance) {
        require(_exists(tokenId), "MetaMorph: Morph does not exist");

        // Calculate required essence for next level
        MorphState memory morph = _morphStates[tokenId];
        requiredEssence = baseEvolutionCostEssence.mul(morph.evolutionLevel);

        // Get conditions for the target epoch (can be current or future planned)
        EnvironmentalCondition memory env = _getEnvironmentalConditions(targetEpoch);

        // Calculate success chance
        successChance = baseEvolutionSuccessChance;
        successChance = successChance.add(baseEvolutionSuccessChance.mul(env.evolutionSuccessModifier).div(10000));
        if (successChance > 100) successChance = 100;

        // Calculate mutation chance (applies on failure)
        mutationChance = baseMutationChance;
        mutationChance = mutationChance.add(baseMutationChance.mul(env.mutationChanceModifier).div(10000));
        if (mutationChance > 100) mutationChance = 100;

        return (requiredEssence, successChance, mutationChance);
    }

    // 36. Emergency Withdraw Staked Essence (Admin Only, potentially time-locked)
    // This is a safety valve in case the contract needs to be drained of staked essence
    // It's an admin function, so use with extreme caution. A timelock could be added.
    function emergencyWithdrawStakedEssence(uint256 tokenId) external onlyOwner {
        require(_exists(tokenId), "MetaMorph: Morph does not exist");
        uint256 staked = _morphStates[tokenId].stakedEssence;
        require(staked > 0, "MetaMorph: No essence staked on this morph");

        _morphStates[tokenId].stakedEssence = 0;
        // Transfer staked essence to the owner of the protocol, not the morph owner
        IERC20(address(this)).safeTransfer(owner(), staked);

        emit EssenceUnstaked(tokenId, address(0), staked); // Use address(0) or owner() as the unstaker
    }

    // 37. Get Token Addresses (Self-referential as tokens are deployed internally)
    function getTokenAddresses() external view returns (address essenceToken, address morphNFT) {
        return (address(this), address(this));
    }

    // 38, 39, 40: Ownable functions (renounceOwnership, transferOwnership, owner) inherited

    // --- ERC20 Standard Overrides (required for implementation) ---
    function supply() public view returns (uint256) {
        return _essenceSupply.current();
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    // Override total supply getter
    function totalSupply() public view override returns (uint256) {
        return _essenceSupply.current();
    }


    // --- ERC721 Standard Overrides (required for implementation) ---
     function supportsInterface(bytes4 interfaceId) public view override(ERC721, Ownable) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IOwnable).interfaceId || // OpenZeppelin Ownable interface
            super.supportsInterface(interfaceId);
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

     function getApproved(uint256 tokenId) public view override returns (address) {
         require(_exists(tokenId), "ERC721: approved query for nonexistent token");
         return _tokenApprovals[tokenId];
     }
}
```