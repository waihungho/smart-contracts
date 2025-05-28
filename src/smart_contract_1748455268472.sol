Okay, here is a Solidity smart contract implementing an "Evolutionary NFT" with dynamic traits, interaction mechanics, staking, merging, and state transitions. This contract aims for creativity by making the NFT's characteristics change over time and through owner actions, going beyond static images or simple ownership records. It includes over 20 functions covering standard ERC721 features, specific evolutionary mechanics, and administrative controls.

**Disclaimer:** This is a complex example contract for educational purposes. It demonstrates advanced concepts but would require significant optimization, gas cost analysis, robust error handling, and security auditing for production deployment. The metadata generation logic is simplified for clarity.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol"; // Or use a library for Base64

// --- Outline ---
// 1. Contract Description: An ERC721 NFT that evolves based on interaction, time, and owner actions.
// 2. Core Concepts:
//    - Dynamic Traits: NFT properties change over time or via specific actions.
//    - Evolution Points: Accumulate through interactions and staking.
//    - State Transitions: NFTs progress through life stages (Egg, Juvenile, Adult, Elder) based on points/time.
//    - Interaction Mechanics: Owner actions (Train, Feed, Quest, Apply Item) influence evolution.
//    - Staking: Passive accumulation of evolution points over time.
//    - Merging: Combine two NFTs to create a stronger or unique one (burns one).
//    - On-chain Metadata Logic: tokenURI reflects the current dynamic state and traits.
// 3. Included Standards: ERC721, ERC721Enumerable, Ownable.
// 4. Key Mechanisms: Structs for NFT state and traits, Mappings for state tracking, Time-based logic, Point-based evolution.
// 5. Admin Controls: Set evolution parameters, cooldowns, trait modifiers, pause functions.

// --- Function Summary ---
// Standard ERC721 & Enumerable Functions:
// - supportsInterface(bytes4 interfaceId): ERC721 standard check.
// - name(): Returns the contract name.
// - symbol(): Returns the contract symbol.
// - balanceOf(address owner): Gets number of tokens for an owner.
// - ownerOf(uint256 tokenId): Gets owner of a token.
// - safeTransferFrom(address from, address to, uint256 tokenId): Transfers token safely.
// - safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data): Transfers token safely with data.
// - transferFrom(address from, address to, uint256 tokenId): Transfers token (unsafe version).
// - approve(address to, uint256 tokenId): Approves address to spend token.
// - getApproved(uint256 tokenId): Gets approved address for a token.
// - setApprovalForAll(address operator, bool approved): Sets approval for all tokens.
// - isApprovedForAll(address owner, address operator): Checks if operator is approved for all tokens.
// - tokenURI(uint256 tokenId): Generates the metadata URI dynamically based on NFT state.
// - totalSupply(): Total number of tokens minted.
// - tokenByIndex(uint256 index): Gets token ID by index (Enumerable).
// - tokenOfOwnerByIndex(address owner, uint256 index): Gets token ID of owner by index (Enumerable).

// Evolutionary Actions & Triggers:
// - mintInitialSpecies(address recipient): Mints a new NFT in its initial state (Egg).
// - interact(uint256 tokenId): Generic interaction, adds minor evolution points, resets decay timer.
// - train(uint256 tokenId): Specific interaction, adds training-specific points/trait boost.
// - feed(uint256 tokenId): Specific interaction, adds health/endurance points.
// - completeQuest(uint256 tokenId, uint256 questId, uint256 rewardPoints): Adds significant evolution points for completing a quest (requires external system integration).
// - applyItem(uint256 tokenId, uint256 itemId, bytes calldata itemData): Applies effect of an external item, potentially altering traits or adding points.
// - applyEvolutionPoints(uint256 tokenId): Processes accumulated evolution points to potentially evolve traits and state. Can be called by owner or a system.
// - mutate(uint256 tokenId, bytes32 entropy): Introduces controlled randomness into traits, consumes points. `entropy` could be from VRF or block hash.
// - mergeNFTs(uint256 tokenId1, uint256 tokenId2): Merges two NFTs into one (tokenId1), burning the second (tokenId2). Combines points and traits.
// - stakeForPassiveEvolution(uint256 tokenId, uint256 durationInDays): Stakes the NFT to earn passive evolution points over time.
// - unstake(uint256 tokenId): Unstakes the NFT, making it transferable and stopping passive point accumulation.
// - claimStakingPoints(uint256 tokenId): Claims accumulated passive evolution points from staking.

// State Queries:
// - getTraits(uint256 tokenId): Gets the current traits of an NFT.
// - getEvolutionPoints(uint256 tokenId): Gets the current evolution points of an NFT.
// - getLastInteractionTime(uint256 tokenId): Gets the timestamp of the last interaction.
// - getCurrentState(uint256 tokenId): Gets the current life stage of the NFT (Egg, Juvenile, etc.).
// - getStakingEndTime(uint256 tokenId): Gets the timestamp when staking ends for an NFT (0 if not staked).
// - calculateProjectedTraitValue(uint256 tokenId, uint8 traitIndex): Estimates a trait value based on current points (without applying evolution).

// Admin & Configuration:
// - setBaseTraitModifier(uint8 traitIndex, uint256 modifierValue): Sets a base modifier for a specific trait type.
// - setInteractionCooldown(uint256 cooldownSeconds): Sets the cooldown period between interactions.
// - setDecayRate(uint256 pointsPerDay): Sets the rate at which evolution points decay if not interacted with. (Note: Decay check needs implementation logic).
// - setEvolutionPointThresholds(uint8[] memory stateThresholds, uint256[] memory evolutionThresholds): Sets point thresholds for state transitions and trait evolution tiers.
// - setTraitDefinition(uint8 traitIndex, string memory name, string memory description): Defines/updates metadata for a specific trait type.
// - pauseEvolution(bool paused): Pauses core evolution mechanics (interaction/applyPoints).
// - unpauseEvolution(): Unpauses evolution mechanics.
// - setBaseURI(string memory uri): Sets the base URI for token metadata (e.g., IPFS gateway).

contract EvolutionaryNFT is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    enum EvolutionState {
        Egg,
        Juvenile,
        Adult,
        Elder,
        Mythic // Example of a rare final state
    }

    struct Trait {
        string name;
        string description;
        uint256 baseValue; // Base value set at minting or by admin
        uint256 evolvedValue; // Value modified by evolution points
        uint256 modifier; // Admin-set modifier influencing evolution speed/cap
    }

    struct NFTState {
        uint256 evolutionPoints;
        uint64 lastInteractionTime;
        EvolutionState currentState;
        uint64 stakingEndTime; // 0 if not staked
        uint64 lastEvolutionTime; // Time when applyEvolutionPoints was last run
        Trait[] traits;
    }

    // Mapping from token ID to NFT state
    mapping(uint256 => NFTState) private _nftState;

    // Admin configurable parameters
    uint256 public interactionCooldown = 1 days; // Cooldown for general interaction
    uint256 public pointsPerInteraction = 10;
    uint256 public pointsPerTrain = 25;
    uint256 public pointsPerFeed = 15;
    uint256 public stakingPointsPerDay = 50; // Passive points accumulation rate
    uint256 public pointsPerMerge = 100; // Bonus points for merging

    // Thresholds for state transitions (evolutionPoints required)
    uint256[] public stateThresholds = [0, 500, 2000, 5000, 10000]; // Points for Egg, Juvenile, Adult, Elder, Mythic

    // Thresholds for trait evolution tiers (points needed for significant trait boost)
    uint256[] public traitEvolutionTiers = [0, 100, 300, 800, 2000]; // Example tiers

    // Base modifiers for different trait types (e.g., traitIndex 0 might be Strength, 1 Dexterity)
    mapping(uint8 => uint256) public baseTraitModifiers;

    bool public evolutionPaused = false;

    // Base URI for metadata (e.g., IPFS)
    string private _baseTokenURI;

    // Events
    event NFTMinted(uint256 indexed tokenId, address indexed owner, EvolutionState initialState);
    event Interacted(uint256 indexed tokenId, uint256 newEvolutionPoints, uint64 interactionTime);
    event EvolutionPointsApplied(uint256 indexed tokenId, uint256 pointsConsumed, EvolutionState newState, bytes changedTraits); // changedTraits could be encoded info
    event Mutated(uint256 indexed tokenId, bytes32 entropyUsed, bytes changedTraits);
    event Merged(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 newEvolutionPoints);
    event Staked(uint256 indexed tokenId, uint64 stakingEndTime);
    event Unstaked(uint256 indexed tokenId, uint64 unstakingTime);
    event StakingPointsClaimed(uint256 indexed tokenId, uint256 claimedPoints);
    event StateChanged(uint256 indexed tokenId, EvolutionState oldState, EvolutionState newState);
    event EvolutionPaused(bool paused);
    event TraitDefinitionUpdated(uint8 indexed traitIndex, string name);

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    // --- Standard ERC721 & Enumerable Functions ---

    // Already implemented by inheritance:
    // supportsInterface, name, symbol, balanceOf, ownerOf, safeTransferFrom (both), transferFrom,
    // approve, getApproved, setApprovalForAll, isApprovedForAll, totalSupply, tokenByIndex, tokenOfOwnerByIndex

    /// @dev See {IERC721Metadata-tokenURI}.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert ERC721MetadataError("ERC721Metadata: URI query for nonexistent token");
        }

        // Note: For production, this JSON would typically be generated off-chain
        // and served via the base URI or IPFS, or the Base64 encoding
        // would happen off-chain. Generating complex JSON and Base64 on-chain
        // is very gas-intensive. This is a simplified example.

        string memory base = _baseTokenURI;
        if (bytes(base).length == 0) {
            // If no base URI, return a data URI example
            return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(_generateTokenMetadata(tokenId)))));
        } else {
            // Otherwise, append token ID to base URI
            return string(abi.encodePacked(base, Strings.toString(tokenId)));
        }
    }

    // --- Internal Helper for Metadata Generation (Simplified) ---
    function _generateTokenMetadata(uint256 tokenId) internal view returns (string memory) {
        NFTState storage state = _nftState[tokenId];
        address tokenOwner = ownerOf(tokenId);

        string memory name = string(abi.encodePacked(
            "Evolutionary Creature #", Strings.toString(tokenId)
        ));

        string memory description = string(abi.encodePacked(
            "A dynamic NFT that evolves through interaction. Current State: ",
            _stateToString(state.currentState),
            ". Evolution Points: ",
            Strings.toString(state.evolutionPoints)
        ));

        string memory attributes = "[";
        for (uint i = 0; i < state.traits.length; i++) {
            attributes = string(abi.encodePacked(
                attributes,
                '{"trait_type":"', state.traits[i].name, '","value":', Strings.toString(state.traits[i].evolvedValue), '}'
            ));
            if (i < state.traits.length - 1) {
                attributes = string(abi.encodePacked(attributes, ","));
            }
        }
        attributes = string(abi.encodePacked(attributes, "]"));

        // Replace with a real image generator URL or IPFS hash based on traits
        string memory image = string(abi.encodePacked(
            "https://example.com/images/",
            _stateToString(state.currentState),
            "/",
            Strings.toString(state.traits[0].evolvedValue), // Example: image depends on first trait value
            ".png"
        ));

        // Basic JSON structure (requires manual string concatenation)
        string memory json = string(abi.encodePacked(
            '{"name":"', name,
            '","description":"', description,
            '","image":"', image,
            '","attributes":', attributes,
            '}'
        ));

        return json;
    }

    function _stateToString(EvolutionState state) internal pure returns (string memory) {
        if (state == EvolutionState.Egg) return "Egg";
        if (state == EvolutionState.Juvenile) return "Juvenile";
        if (state == EvolutionState.Adult) return "Adult";
        if (state == EvolutionState.Elder) return "Elder";
        if (state == EvolutionState.Mythic) return "Mythic";
        return "Unknown";
    }

    // --- Evolutionary Actions & Triggers ---

    /// @dev Mints a new NFT in the initial state (Egg) with base traits. Only callable by owner.
    /// @param recipient The address to mint the NFT to.
    function mintInitialSpecies(address recipient) public onlyOwner {
        uint256 newTokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(recipient, newTokenId);

        // Initialize state
        NFTState storage newState = _nftState[newTokenId];
        newState.evolutionPoints = 0;
        newState.lastInteractionTime = uint64(block.timestamp);
        newState.currentState = EvolutionState.Egg;
        newState.stakingEndTime = 0;
        newState.lastEvolutionTime = uint64(block.timestamp);

        // Initialize base traits (example: Strength, Dexterity, Constitution)
        // These should be configurable or generated based on species type etc.
        newState.traits = new Trait[](3);
        newState.traits[0] = Trait({name: "Strength", description: "Physical power", baseValue: 10, evolvedValue: 10, modifier: baseTraitModifiers[0]});
        newState.traits[1] = Trait({name: "Dexterity", description: "Agility and speed", baseValue: 12, evolvedValue: 12, modifier: baseTraitModifiers[1]});
        newState.traits[2] = Trait({name: "Constitution", description: "Health and endurance", baseValue: 8, evolvedValue: 8, modifier: baseTraitModifiers[2]});

        emit NFTMinted(newTokenId, recipient, EvolutionState.Egg);
    }

    /// @dev Generic interaction with the NFT. Adds base evolution points and resets interaction timer.
    /// @param tokenId The ID of the NFT to interact with.
    function interact(uint256 tokenId) public {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Must own token to interact");
        require(!evolutionPaused, "Evolution is paused");

        NFTState storage state = _nftState[tokenId];
        require(block.timestamp >= state.lastInteractionTime + interactionCooldown, "Interaction on cooldown");
        require(state.stakingEndTime == 0, "Cannot interact while staked");

        state.evolutionPoints += pointsPerInteraction;
        state.lastInteractionTime = uint64(block.timestamp);

        // Potentially trigger _decayCheck here before adding points

        emit Interacted(tokenId, state.evolutionPoints, state.lastInteractionTime);
    }

    /// @dev Specific interaction: Training. Adds more points skewed towards certain traits.
    /// @param tokenId The ID of the NFT to train.
    function train(uint256 tokenId) public {
         require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Must own token to train");
        require(!evolutionPaused, "Evolution is paused");

        NFTState storage state = _nftState[tokenId];
        require(block.timestamp >= state.lastInteractionTime + interactionCooldown, "Training on cooldown");
        require(state.stakingEndTime == 0, "Cannot train while staked");

        // Add points, maybe a bonus to specific traits in applyEvolutionPoints logic
        state.evolutionPoints += pointsPerTrain;
        state.lastInteractionTime = uint64(block.timestamp);

        emit Interacted(tokenId, state.evolutionPoints, state.lastInteractionTime); // Re-using Interacted event for simplicity
    }

    /// @dev Specific interaction: Feeding. Adds points skewed towards health/endurance.
    /// @param tokenId The ID of the NFT to feed.
    function feed(uint256 tokenId) public {
         require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Must own token to feed");
        require(!evolutionPaused, "Evolution is paused");

        NFTState storage state = _nftState[tokenId];
        require(block.timestamp >= state.lastInteractionTime + interactionCooldown, "Feeding on cooldown");
        require(state.stakingEndTime == 0, "Cannot feed while staked");

        // Add points, maybe a bonus to specific traits in applyEvolutionPoints logic
        state.evolutionPoints += pointsPerFeed;
        state.lastInteractionTime = uint64(block.timestamp);

        emit Interacted(tokenId, state.evolutionPoints, state.lastInteractionTime); // Re-using Interacted event for simplicity
    }

    /// @dev Marks a quest as completed for the NFT, adding significant evolution points.
    /// Requires integration with an external quest system that calls this function.
    /// @param tokenId The ID of the NFT.
    /// @param questId The ID of the completed quest.
    /// @param rewardPoints The evolution points awarded for the quest.
    function completeQuest(uint256 tokenId, uint256 questId, uint256 rewardPoints) public {
        // In a real system, add checks here:
        // - Ensure msg.sender is the trusted Quest system address
        // - Validate questId
        require(_exists(tokenId), "Token does not exist");
        require(!evolutionPaused, "Evolution is paused");

        NFTState storage state = _nftState[tokenId];
        // Optional: Add cooldown or limit per quest
        state.evolutionPoints += rewardPoints;
        // state.lastInteractionTime = uint64(block.timestamp); // Quest completion also counts as interaction

        // Emit a specific quest event if needed, using Interacted for now.
        emit Interacted(tokenId, state.evolutionPoints, state.lastInteractionTime);
    }

    /// @dev Applies an external item to the NFT, potentially altering traits or adding points.
    /// Requires integration with an external item system.
    /// @param tokenId The ID of the NFT.
    /// @param itemId The ID of the item being applied.
    /// @param itemData Arbitrary data specific to the item effect.
    function applyItem(uint256 tokenId, uint256 itemId, bytes calldata itemData) public {
        // In a real system, add checks here:
        // - Ensure msg.sender is the trusted Item system address or owner
        // - Validate itemId and itemData
        require(_exists(tokenId), "Token does not exist");
        require(!evolutionPaused, "Evolution is paused");
        // require(ownerOf(tokenId) == msg.sender, "Must own token to apply item"); // If called by owner directly

        NFTState storage state = _nftState[tokenId];

        // Example logic: Item boosts a specific trait based on itemData
        // This is a placeholder; complex item effects would be handled here
        uint8 traitIndexToBoost = 0; // Example: always boost first trait
        uint256 boostAmount = 50; // Example boost
        if (itemData.length > 0) {
            // Example: parse itemData to get trait index and boost amount
            // abi.decode(itemData, (uint8, uint256));
            // traitIndexToBoost = decodedTraitIndex;
            // boostAmount = decodedBoostAmount;
        }

        if (traitIndexToBoost < state.traits.length) {
            state.traits[traitIndexToBoost].evolvedValue += boostAmount;
            // Could also add evolution points: state.evolutionPoints += boostPoints;
             emit EvolutionPointsApplied(tokenId, 0, state.currentState, ""); // Re-using event, could add specific ItemApplied event
        } else {
             revert("Invalid trait index for item");
        }
    }


    /// @dev Applies accumulated evolution points to potentially evolve traits and change state.
    /// Can be called by the owner or a system.
    /// @param tokenId The ID of the NFT to evolve.
    function applyEvolutionPoints(uint256 tokenId) public {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender || evolutionPaused == false, "Must own token or not be paused"); // Allow anyone to trigger if not paused, to process evolution
        require(!evolutionPaused, "Evolution is paused");

        NFTState storage state = _nftState[tokenId];
        uint256 pointsBefore = state.evolutionPoints;

        // Apply staking points first if any are pending
        _claimPassiveStakingPoints(tokenId);

        // Calculate points since last evolution application
        uint256 pointsToProcess = state.evolutionPoints - (pointsBefore - (state.evolutionPoints - pointsToProcess)); // Needs careful calculation if decay is involved or points were just added

        // Simple logic: For every X points, add Y to traits, potentially randomly distributed
        // More complex: Use thresholds (traitEvolutionTiers)
        uint256 pointsConsumed = 0;
        bytes memory changedTraitsData = ""; // Placeholder for encoding which traits changed

        uint256 totalPossibleTierIncreases = 0;
        for(uint i = 0; i < traitEvolutionTiers.length - 1; i++) {
            if (state.evolutionPoints >= traitEvolutionTiers[i]) {
                 totalPossibleTierIncreases++;
            } else {
                break;
            }
        }

        uint256 currentTraitTier = 0;
        for(uint i = 0; i < traitEvolutionTiers.length - 1; i++) {
            if (state.evolutionPoints >= traitEvolutionTiers[i+1]) {
                 currentTraitTier++;
            } else {
                break;
            }
        }

        // Example Evolution Logic: Increment traits based on tiers unlocked since last evolution time
        uint256 tiersUnlockedThisRound = currentTraitTier; // Simple logic: all tiers unlocked by current points
        if (state.lastEvolutionTime > 0) {
             // More complex logic: Only unlock tiers *since* lastEvolutionTime and consume points
             // Requires tracking points *at* lastEvolutionTime or a different mechanism
        }

        if (tiersUnlockedThisRound > 0) {
             uint256 pointsNeededForThisRound = traitEvolutionTiers[currentTraitTier]; // Points needed to reach this tier
             pointsConsumed = pointsNeededForThisRound; // Simple consumption

             // Distribute trait increases based on tiers unlocked
             uint256 traitBoostPerTier = 5; // Example
             for(uint i = 0; i < state.traits.length; i++) {
                 uint256 boost = tiersUnlockedThisRound * traitBoostPerTier;
                 // Apply modifier: base value * modifier + linear boost
                 state.traits[i].evolvedValue = state.traits[i].baseValue + (state.traits[i].baseValue * state.traits[i].modifier) / 100 + boost; // Example formula
                 // Ensure evolvedValue doesn't exceed a cap if desired
             }
             state.evolutionPoints -= pointsConsumed; // Consume points
             state.lastEvolutionTime = uint64(block.timestamp);
             // Encode changed traits info into changedTraitsData if needed for the event
        }


        // Check for state transition
        EvolutionState oldState = state.currentState;
        EvolutionState newState = oldState;
        for (uint i = stateThresholds.length -1 ; i > uint(oldState); i--) {
             if (state.evolutionPoints >= stateThresholds[i]) {
                 newState = EvolutionState(i);
                 break;
             }
        }

        if (newState != oldState) {
            state.currentState = newState;
            emit StateChanged(tokenId, oldState, newState);
        }

        emit EvolutionPointsApplied(tokenId, pointsConsumed, newState, changedTraitsData);
    }

    /// @dev Introduces controlled randomness to traits, consuming evolution points.
    /// Requires external entropy source like Chainlink VRF for production.
    /// @param tokenId The ID of the NFT to mutate.
    /// @param entropy A random 32-byte value (e.g., from VRF request).
    function mutate(uint256 tokenId, bytes32 entropy) public {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Must own token to mutate");
        require(!evolutionPaused, "Evolution is paused");

        NFTState storage state = _nftState[tokenId];
        uint256 mutationCost = 200; // Example cost in points
        require(state.evolutionPoints >= mutationCost, "Not enough evolution points to mutate");

        state.evolutionPoints -= mutationCost;

        // Use entropy to influence mutation
        uint256 randomValue = uint256(entropy);
        bytes memory changedTraitsData = ""; // Placeholder

        // Example Mutation Logic: Randomly boost or slightly decrease a random trait
        uint8 traitIndexToMutate = uint8(randomValue % state.traits.length);
        int256 mutationAmount = int256(randomValue % 41) - 20; // Random value between -20 and +20

        if (traitIndexToMutate < state.traits.length) {
             // Prevent value from going below base value, or add a floor
             if (mutationAmount > 0) {
                 state.traits[traitIndexToMutate].evolvedValue += uint256(mutationAmount);
             } else {
                 // Ensure we don't underflow and don't go below base+modifier value
                 uint256 decrease = uint256(-mutationAmount);
                 uint256 minPossibleValue = state.traits[traitIndexToMutate].baseValue + (state.traits[traitIndexToMutate].baseValue * state.traits[traitIndexToMutate].modifier) / 100;
                 if (state.traits[traitIndexToMutate].evolvedValue > minPossibleValue + decrease) {
                      state.traits[traitIndexToMutate].evolvedValue -= decrease;
                 } else {
                      state.traits[traitIndexToMutate].evolvedValue = minPossibleValue;
                 }
             }
             // Encode changes for event if needed
             changedTraitsData = abi.encodePacked("Trait ", Strings.toString(traitIndexToMutate), " changed by ", Strings.toString(mutationAmount));
        }

        emit Mutated(tokenId, entropy, changedTraitsData);
        emit EvolutionPointsApplied(tokenId, mutationCost, state.currentState, changedTraitsData); // Mutation also counts as point application
    }

    /// @dev Merges two NFTs (tokenId1 and tokenId2). tokenId2 is burned.
    /// Traits and points are combined into tokenId1 using specific logic.
    /// @param tokenId1 The ID of the primary NFT (will survive).
    /// @param tokenId2 The ID of the secondary NFT (will be burned).
    function mergeNFTs(uint256 tokenId1, uint256 tokenId2) public {
        require(_exists(tokenId1), "Token 1 does not exist");
        require(_exists(tokenId2), "Token 2 does not exist");
        require(tokenId1 != tokenId2, "Cannot merge a token with itself");
        require(ownerOf(tokenId1) == msg.sender, "Must own token 1 to merge");
        require(ownerOf(tokenId2) == msg.sender, "Must own token 2 to merge");
        require(!evolutionPaused, "Evolution is paused");

        NFTState storage state1 = _nftState[tokenId1];
        NFTState storage state2 = _nftState[tokenId2];

        // Ensure traits are compatible/same length for merging
        require(state1.traits.length == state2.traits.length, "Traits are not compatible for merging");

        // Claim pending staking points before merging
        _claimPassiveStakingPoints(tokenId1);
        _claimPassiveStakingPoints(tokenId2);

        // --- Merging Logic ---
        // Example: Combine evolution points and average evolved traits
        uint256 newTotalPoints = state1.evolutionPoints + state2.evolutionPoints + pointsPerMerge; // Add bonus points
        state1.evolutionPoints = newTotalPoints;

        for (uint i = 0; i < state1.traits.length; i++) {
            state1.traits[i].evolvedValue = (state1.traits[i].evolvedValue + state2.traits[i].evolvedValue) / 2; // Average evolved values
             // You could add more complex logic: inherit higher value, add a percentage, introduce randomness etc.
        }

        // Update interaction time to now for the surviving NFT
        state1.lastInteractionTime = uint64(block.timestamp);
        state1.lastEvolutionTime = uint64(block.timestamp); // Merging counts as an evolution event

        // Recalculate state transition for the surviving NFT
        EvolutionState oldState1 = state1.currentState;
         EvolutionState newState1 = oldState1;
        for (uint i = stateThresholds.length -1 ; i > uint(oldState1); i--) {
             if (state1.evolutionPoints >= stateThresholds[i]) {
                 newState1 = EvolutionState(i);
                 break;
             }
        }
        if (newState1 != oldState1) {
            state1.currentState = newState1;
            emit StateChanged(tokenId1, oldState1, newState1);
        }


        // Burn the second token
        _burn(tokenId2);

        // Remove state entry for the burned token (optional, helps save gas on future lookups)
        delete _nftState[tokenId2];

        emit Merged(tokenId1, tokenId2, newTotalPoints);
        emit EvolutionPointsApplied(tokenId1, 0, state1.currentState, ""); // Signal state might have changed
    }

    /// @dev Stakes an NFT, making it non-transferable but accumulating passive evolution points.
    /// @param tokenId The ID of the NFT to stake.
    /// @param durationInDays The number of days to stake the NFT.
    function stakeForPassiveEvolution(uint256 tokenId, uint256 durationInDays) public {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Must own token to stake");
        require(durationInDays > 0, "Staking duration must be positive");

        NFTState storage state = _nftState[tokenId];
        require(state.stakingEndTime == 0, "NFT is already staked");

        // Cannot stake if approvals exist? Or just make transfer impossible while staked.
        // This implementation just makes transfer impossible.

        state.stakingEndTime = uint64(block.timestamp + durationInDays * 1 days);
        // Optionally, add logic here to ensure the token cannot be transferred/burned while staked
        // OpenZeppelin's _beforeTokenTransfer hook can be used for this.

        emit Staked(tokenId, state.stakingEndTime);
    }

    /// @dev Unstakes a staked NFT, making it transferable again. Claims pending staking points.
    /// @param tokenId The ID of the NFT to unstake.
    function unstake(uint256 tokenId) public {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Must own token to unstake");

        NFTState storage state = _nftState[tokenId];
        require(state.stakingEndTime > 0, "NFT is not staked");
        require(block.timestamp >= state.stakingEndTime, "Staking period has not ended yet");

        _claimPassiveStakingPoints(tokenId); // Claim points upon unstaking

        state.stakingEndTime = 0; // Reset staking state

        emit Unstaked(tokenId, uint64(block.timestamp));
    }

     /// @dev Internal helper to claim passive staking points. Can be called by unstake or applyEvolutionPoints.
     /// @param tokenId The ID of the NFT.
     function _claimPassiveStakingPoints(uint256 tokenId) internal {
        NFTState storage state = _nftState[tokenId];
        if (state.stakingEndTime > 0) {
            uint64 currentTime = uint64(block.timestamp);
            uint64 stakingStartTime = state.lastEvolutionTime; // Use last evolution time as start for earning points

            if (currentTime > stakingStartTime) {
                uint256 secondsStaked = currentTime - stakingStartTime;
                // If staking period ended, only count up to stakingEndTime
                if (currentTime > state.stakingEndTime) {
                    secondsStaked = state.stakingEndTime - stakingStartTime;
                     if (state.stakingEndTime < stakingStartTime) secondsStaked = 0; // Handle edge case if time went backwards (shouldn't happen on chain)
                }
                 if (secondsStaked > 0) {
                    uint256 pointsEarned = (secondsStaked * stakingPointsPerDay) / 1 days;
                    state.evolutionPoints += pointsEarned;
                    emit StakingPointsClaimed(tokenId, pointsEarned);
                 }
            }
             // Reset last evolution time whether points were earned or not, to prevent double counting
             state.lastEvolutionTime = currentTime;
        }
     }

     /// @dev Claims accumulated passive evolution points without unstaking (if allowed).
     /// In this design, points are only claimed upon unstake or applyEvolutionPoints.
     /// This function primarily acts as a trigger for _claimPassiveStakingPoints.
     /// @param tokenId The ID of the NFT.
    function claimStakingPoints(uint256 tokenId) public {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Must own token to claim points");
        require(!evolutionPaused, "Evolution is paused");

        _claimPassiveStakingPoints(tokenId);
    }


    // --- State Queries ---

    /// @dev Gets the current traits of an NFT.
    /// @param tokenId The ID of the NFT.
    /// @return An array of Trait structs.
    function getTraits(uint256 tokenId) public view returns (Trait[] memory) {
        require(_exists(tokenId), "Token does not exist");
        return _nftState[tokenId].traits;
    }

    /// @dev Gets the current evolution points of an NFT.
    /// @param tokenId The ID of the NFT.
    /// @return The evolution points.
    function getEvolutionPoints(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        return _nftState[tokenId].evolutionPoints;
    }

    /// @dev Gets the timestamp of the last interaction with the NFT.
    /// @param tokenId The ID of the NFT.
    /// @return The timestamp.
    function getLastInteractionTime(uint256 tokenId) public view returns (uint64) {
        require(_exists(tokenId), "Token does not exist");
        return _nftState[tokenId].lastInteractionTime;
    }

    /// @dev Gets the current life stage (state) of the NFT.
    /// @param tokenId The ID of the NFT.
    /// @return The current EvolutionState enum value.
    function getCurrentState(uint256 tokenId) public view returns (EvolutionState) {
        require(_exists(tokenId), "Token does not exist");
        return _nftState[tokenId].currentState;
    }

     /// @dev Gets the timestamp when staking ends for an NFT (0 if not staked).
     /// @param tokenId The ID of the NFT.
     /// @return The staking end timestamp.
    function getStakingEndTime(uint256 tokenId) public view returns (uint64) {
        require(_exists(tokenId), "Token does not exist");
        return _nftState[tokenId].stakingEndTime;
    }

    /// @dev Calculates a projected trait value based on current points and modifiers,
    /// without actually applying the evolution yet. Useful for previews.
    /// @param tokenId The ID of the NFT.
    /// @param traitIndex The index of the trait to calculate (0-based).
    /// @return The projected evolved value.
    function calculateProjectedTraitValue(uint256 tokenId, uint8 traitIndex) public view returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        NFTState storage state = _nftState[tokenId];
        require(traitIndex < state.traits.length, "Invalid trait index");

        uint256 currentPoints = state.evolutionPoints;

        uint256 currentTraitTier = 0;
        for(uint i = 0; i < traitEvolutionTiers.length - 1; i++) {
            if (currentPoints >= traitEvolutionTiers[i+1]) {
                 currentTraitTier++;
            } else {
                break;
            }
        }

        uint256 traitBoostPerTier = 5; // Example, should match logic in applyEvolutionPoints
        uint256 projectedBoost = currentTraitTier * traitBoostPerTier;

        // Apply modifier: base value * modifier + linear boost
        uint256 projectedValue = state.traits[traitIndex].baseValue + (state.traits[traitIndex].baseValue * state.traits[traitIndex].modifier) / 100 + projectedBoost;

        return projectedValue;
    }

    /// @dev Gets the points thresholds for state transitions.
    /// @return An array of thresholds for Egg, Juvenile, Adult, Elder, Mythic.
    function getStateTransitionThresholds() public view returns (uint256[] memory) {
         return stateThresholds;
    }


    // --- Admin & Configuration ---

    /// @dev Sets a base modifier for a specific trait type. Influences how points affect this trait.
    /// @param traitIndex The index of the trait (0-based).
    /// @param modifierValue The modifier percentage (e.g., 10 for +10%).
    function setBaseTraitModifier(uint8 traitIndex, uint256 modifierValue) public onlyOwner {
        // Add checks to ensure traitIndex is valid within expected range if needed
        baseTraitModifiers[traitIndex] = modifierValue;
    }

    /// @dev Sets the cooldown period between general interactions.
    /// @param cooldownSeconds The cooldown duration in seconds.
    function setInteractionCooldown(uint256 cooldownSeconds) public onlyOwner {
        interactionCooldown = cooldownSeconds;
    }

    /// @dev Sets the rate at which evolution points decay if not interacted with.
    /// Note: Decay logic needs to be implemented and triggered (e.g., in interact, applyEvolutionPoints, or a separate keep-alive function).
    /// This function only sets the rate.
    /// @param pointsPerDay The number of points lost per day of inactivity.
    function setDecayRate(uint256 pointsPerDay) public onlyOwner {
        // decayRatePointsPerDay = pointsPerDay; // Need a state variable for decay rate
        // Implementation of decay check would be required in relevant functions
        // For this example, decay logic is omitted for simplicity.
        revert("Decay logic not fully implemented in this example");
    }

    /// @dev Sets the point thresholds for state transitions and trait evolution tiers.
    /// Requires arrays to be correctly ordered and of specific lengths.
    /// @param newStateThresholds Array of thresholds for EvolutionState transitions (must match enum size).
    /// @param newEvolutionTiers Array of thresholds for trait evolution tiers.
    function setEvolutionPointThresholds(uint256[] memory newStateThresholds, uint256[] memory newEvolutionTiers) public onlyOwner {
        require(newStateThresholds.length == uint(EvolutionState.Mythic) + 1, "State thresholds array length mismatch");
        require(newEvolutionTiers.length > 0, "Evolution tiers cannot be empty");
        // Add checks to ensure thresholds are increasing:
        for (uint i = 0; i < newStateThresholds.length - 1; i++) {
             require(newStateThresholds[i] < newStateThresholds[i+1], "State thresholds must be increasing");
        }
         for (uint i = 0; i < newEvolutionTiers.length - 1; i++) {
             require(newEvolutionTiers[i] < newEvolutionTiers[i+1], "Evolution tiers must be increasing");
        }
        stateThresholds = newStateThresholds;
        traitEvolutionTiers = newEvolutionTiers;
    }

    /// @dev Defines or updates metadata (name, description) for a specific trait type index.
    /// This affects the description shown in `tokenURI`.
    /// Note: This doesn't change the base/evolved values, only the descriptive metadata.
    /// @param traitIndex The index of the trait (0-based).
    /// @param name The new name for the trait.
    /// @param description The new description for the trait.
    function setTraitDefinition(uint8 traitIndex, string memory name, string memory description) public onlyOwner {
        // This only updates the 'master' definition. To update existing NFTs,
        // you might need a separate migration function or loop through all tokens.
        // This example only updates the definition used for *new* NFTs or
        // relies on tokenURI to potentially fetch these admin-set definitions.
        // A robust implementation might store these globally or update all traits.
        // For simplicity here, we'll assume trait definitions are somewhat static post-deployment
        // or that a separate mechanism updates live NFT traits.
        // This function is more for future NFT definitions.
        // Let's make it simple: it updates the description *within* this contract for the tokenURI helper.
        // Requires a mapping for trait index -> definition
        revert("Trait definition update not fully implemented in this example");
        // Example concept:
        // mapping(uint8 => struct TraitDefinition { string name; string description; }) public traitDefinitions;
        // traitDefinitions[traitIndex].name = name;
        // traitDefinitions[traitIndex].description = description;
        // emit TraitDefinitionUpdated(traitIndex, name);
    }

    /// @dev Pauses core evolution mechanics (interaction, applyPoints, mutate, merge).
    /// @param paused Whether evolution should be paused (true) or unpaused (false).
    function pauseEvolution(bool paused) public onlyOwner {
        evolutionPaused = paused;
        emit EvolutionPaused(paused);
    }

    /// @dev Unpauses core evolution mechanics. Alias for `pauseEvolution(false)`.
    function unpauseEvolution() public onlyOwner {
        pauseEvolution(false);
    }

    /// @dev Sets the base URI for token metadata.
    /// @param uri The base URI string.
    function setBaseURI(string memory uri) public onlyOwner {
        _baseTokenURI = uri;
    }

    // --- Internal OpenZeppelin Hooks ---

    /// @dev Override to prevent transfer if staked.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (from != address(0) && to != address(0)) { // Only check on actual transfers, not minting/burning
             // Ensure token is not staked before transferring
            require(_nftState[tokenId].stakingEndTime == 0, "Staked token cannot be transferred");
        }
    }

    /// @dev Override to ensure state is cleared when a token is burned.
    function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._afterTokenTransfer(from, to, tokenId, batchSize);

        if (to == address(0)) { // Check if token was burned
            // Cleanup state for the burned token
            delete _nftState[tokenId];
        }
    }
}
```