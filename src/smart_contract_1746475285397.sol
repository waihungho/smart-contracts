```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // Useful for min/max/average in potential calculations

// --- Outline and Function Summary ---
/*
Contract: ChronoMorphs

Concept: Dynamic, evolving NFTs ("ChronoMorphs") whose traits and behavior change over time
based on on-chain parameters, user interactions, and internal pseudo-randomness derived from block data.
Each ChronoMorph has a immutable "Genetic Code" and mutable "Temporal Traits". Evolution
consumes "ChronoEnergy" (an ERC20 token) and is influenced by a global "Temporal Flow Rate".
Morphs can interact, breed, and enter stasis.

Core Mechanics:
1.  ERC721 Standard: Represents unique ChronoMorphs.
2.  Time-Based Evolution: Traits evolve based on elapsed time since last evolution/creation.
3.  Interaction Effects: User actions (generic interaction, feeding energy, challenging) influence evolution path and potential.
4.  Procedural Trait Mutation: Traits are modified based on a simple on-chain algorithm incorporating genetic code, temporal traits, time, and block data.
5.  ChronoEnergy (ERC20): A separate token required for evolution and certain interactions.
6.  Temporal Flow Rate: A global parameter set by the owner affecting the speed and nature of evolution.
7.  Stasis Mechanism: Owners can pause a ChronoMorph's evolution (potentially at a cost).
8.  Breeding: Combining two ChronoMorphs to create a new one with traits inherited/mixed from parents.
9.  Dynamic Metadata: tokenURI reflects the ChronoMorph's current temporal state.

Inherits: ERC721, ERC721Enumerable, Ownable

State Variables:
-   _tokenIdCounter: Counter for total minted ChronoMorphs.
-   _morphs: Mapping from tokenId to ChronoMorph struct.
-   _baseTokenURI: Base URI for metadata.
-   _chronoEnergyToken: Address of the required ERC20 token.
-   _temporalFlowRate: Global parameter affecting evolution speed/intensity.
-   _mutationBaseChance: Base probability denominator for trait mutations.
-   _evolutionCost: Base cost in ChronoEnergy for triggering evolution.

Structs:
-   ChronoMorph: Contains geneticCode (bytes32), creationTime (uint), lastEvolutionTime (uint), temporalAge (uint), interactionCount (uint), energyLevel (uint), inStasis (bool), parent1 (uint), parent2 (uint), currentTemporalTraits (uint[] - simple representation).

Events:
-   MorphMinted(uint256 tokenId, address owner, uint256 parent1, uint256 parent2)
-   MorphEvolved(uint256 tokenId, uint[] newTraits, uint256 temporalAge)
-   MorphInteracted(uint256 tokenId, address user)
-   MorphStasisToggled(uint256 tokenId, bool inStasis)
-   MorphBurned(uint256 tokenId)
-   TemporalFlowRateUpdated(uint256 newRate)
-   MutationParametersUpdated(uint256 mutationBaseChance, uint256 evolutionCost)
-   StimulusApplied(uint256 stimulusId, bytes data)

Function Summary (>= 20 functions):

Standard ERC721/Enumerable (Inherited/Overridden):
1.  constructor(string name, string symbol, address chronoEnergyAddress): Initializes the contract, sets name/symbol, and the ChronoEnergy token address.
2.  balanceOf(address owner): Returns the number of tokens owned by an address.
3.  ownerOf(uint256 tokenId): Returns the owner of a specific token.
4.  safeTransferFrom(address from, address to, uint256 tokenId): Transfers token safely.
5.  safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data): Transfers token safely with data.
6.  transferFrom(address from, address to, uint256 tokenId): Transfers token.
7.  approve(address to, uint256 tokenId): Approves an address to manage a token.
8.  getApproved(uint256 tokenId): Gets the approved address for a token.
9.  setApprovalForAll(address operator, bool approved): Sets approval for an operator for all tokens.
10. isApprovedForAll(address owner, address operator): Checks if an operator is approved for all tokens.
11. supportsInterface(bytes4 interfaceId): Indicates if the contract supports a given interface (ERC721, ERC721Enumerable, Ownable).
12. tokenURI(uint256 tokenId): Returns the metadata URI for a token (dynamic).
13. totalSupply(): Returns the total number of tokens in existence.
14. tokenByIndex(uint256 index): Returns a token ID by its index in the global list.
15. tokenOfOwnerByIndex(address owner, uint256 index): Returns a token ID by its index in the owner's list.

ChronoMorph Specific Logic:
16. mintInitialMorph(address owner, bytes32 geneticCode): Mints a new ChronoMorph (initial generation, admin/privileged).
17. mintFromBreeding(address owner, uint256 parent1Id, uint256 parent2Id): Mints a new ChronoMorph from two existing parents (unique breeding logic).
18. triggerEvolution(uint256 tokenId): Triggers the evolution process for a specific ChronoMorph (requires ChronoEnergy).
19. interactWithMorph(uint256 tokenId): Generic interaction, increases interaction count, potentially affects energy/evolution.
20. challengeMorph(uint256 tokenId1, uint256 tokenId2): Simulates a challenge between two morphs (outcome could be based on temporal traits).
21. feedChronoEnergy(uint256 tokenId, uint256 amount): Allows feeding ChronoEnergy to a morph, increasing its internal energy level.
22. toggleStasis(uint256 tokenId): Toggles the stasis status of a ChronoMorph (pauses/resumes evolution).
23. burnMorph(uint256 tokenId): Allows the owner to burn (destroy) their ChronoMorph.

Query Functions:
24. getMorphDetails(uint256 tokenId): Retrieves the full ChronoMorph struct data.
25. getTemporalTraits(uint256 tokenId): Retrieves only the current mutable temporal traits.
26. getGeneticCode(uint256 tokenId): Retrieves the immutable genetic code.
27. calculateCurrentAge(uint256 tokenId): Calculates the effective temporal age of the morph (considers stasis).
28. calculateEvolutionPotential(uint256 tokenId): Calculates a score indicating readiness/likelihood of significant evolution.
29. canEvolve(uint256 tokenId): Checks if a morph is eligible for evolution based on time, energy, and stasis status.
30. getMorphsOwnedBy(address owner): Returns an array of token IDs owned by an address (uses Enumerable).

Admin Functions (Ownable):
31. setTemporalFlowRate(uint256 newRate): Updates the global temporal flow rate.
32. setMutationParameters(uint256 mutationBaseChance, uint256 evolutionCost): Updates parameters for the mutation process and cost.
33. applyStimulus(uint256 tokenId, uint256 stimulusId, bytes data): Allows admin to apply a specific external stimulus that might affect a morph's state/evolution.
34. setBaseURI(string newBaseURI): Sets the base URI for token metadata.
35. withdrawERC20(address tokenAddress, uint256 amount): Allows the owner to withdraw accidental ERC20 transfers to the contract.

Internal/Helper Functions:
-   _mutateTraits(uint256 tokenId, uint256 evolutionSeed): Internal logic for applying trait mutations.
-   _generateGeneticCode(uint256 parent1Id, uint256 parent2Id): Internal logic for breeding genetic code.
-   _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize): Hook to potentially add logic on transfer (e.g., reset temporal state).

Note: Trait representation (uint[]) and mutation logic are simplified for on-chain feasibility. Complex traits or graphics would likely rely on off-chain metadata resolved by the dynamic tokenURI.
*/

contract ChronoMorphs is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    struct ChronoMorph {
        bytes32 geneticCode;       // Immutable base traits
        uint256 creationTime;      // Timestamp of creation
        uint256 lastEvolutionTime; // Timestamp of last evolution
        uint256 temporalAge;       // Accumulated non-stasis time in seconds
        uint256 interactionCount;  // Number of times interactWithMorph has been called
        uint256 energyLevel;       // Internal energy pool, potentially from feeding ChronoEnergy
        bool inStasis;             // If true, temporalAge doesn't increase
        uint256 stasisStartTime;   // Timestamp when stasis was entered
        uint256 parent1;           // Token ID of parent 1 (0 for initial generation)
        uint256 parent2;           // Token ID of parent 2 (0 for initial generation)
        uint[] currentTemporalTraits; // Mutable traits represented as a simple array of numbers
    }

    mapping(uint256 => ChronoMorph) private _morphs;
    string private _baseTokenURI;
    IERC20 private immutable _chronoEnergyToken;

    // Evolution and Mutation Parameters (Owner settable)
    uint256 public temporalFlowRate = 1; // Multiplier for temporal age accumulation / evolution potential
    uint256 public mutationBaseChance = 1000; // 1 / mutationBaseChance is base chance per trait evolution attempt (e.g., 1 in 1000)
    uint256 public evolutionCost = 1e18; // Base cost in ChronoEnergy (assuming 18 decimals)
    uint256 public constant MIN_EVOLUTION_INTERVAL = 1 days; // Minimum time required between manual evolutions

    // --- Events ---
    event MorphMinted(uint256 indexed tokenId, address indexed owner, uint256 parent1, uint256 parent2);
    event MorphEvolved(uint256 indexed tokenId, uint[] newTraits, uint256 temporalAge);
    event MorphInteracted(uint256 indexed tokenId, address indexed user);
    event MorphStasisToggled(uint256 indexed tokenId, bool inStasis);
    event MorphBurned(uint256 indexed tokenId);
    event TemporalFlowRateUpdated(uint256 newRate);
    event MutationParametersUpdated(uint256 mutationBaseChance, uint256 evolutionCost);
    event StimulusApplied(uint256 indexed tokenId, uint256 indexed stimulusId, bytes data);
    event ChronoEnergyFed(uint256 indexed tokenId, uint256 amount);

    // --- Constructor ---
    constructor(string memory name, string memory symbol, address chronoEnergyAddress)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        require(chronoEnergyAddress != address(0), "ChronoEnergy token address cannot be zero");
        _chronoEnergyToken = IERC20(chronoEnergyAddress);
    }

    // --- Modifiers ---
    modifier onlyMorphOwner(uint256 tokenId) {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not token owner");
        _;
    }

    modifier onlyMorphExists(uint256 tokenId) {
         require(_exists(tokenId), "Token does not exist");
         _;
    }

    // --- Core ChronoMorph Logic ---

    /**
     * @dev Mints an initial generation ChronoMorph. Only callable by owner.
     * @param owner Address to mint the morph to.
     * @param geneticCode Initial genetic code (bytes32).
     * @return The new token ID.
     */
    function mintInitialMorph(address owner, bytes32 geneticCode) external onlyOwner returns (uint256) {
        uint256 newTokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        uint[] memory initialTraits = new uint[](3); // Example: [strength, agility, resilience]
        initialTraits[0] = uint(uint160(geneticCode)) % 100;
        initialTraits[1] = uint(uint160(bytes32(uint256(geneticCode) >> 160))) % 100;
        initialTraits[2] = uint(uint160(bytes32(uint256(geneticCode) >> 32))) % 100;


        _morphs[newTokenId] = ChronoMorph({
            geneticCode: geneticCode,
            creationTime: block.timestamp,
            lastEvolutionTime: block.timestamp,
            temporalAge: 0,
            interactionCount: 0,
            energyLevel: 0,
            inStasis: false,
            stasisStartTime: 0,
            parent1: 0, // Indicates initial generation
            parent2: 0, // Indicates initial generation
            currentTemporalTraits: initialTraits
        });

        _safeMint(owner, newTokenId);
        emit MorphMinted(newTokenId, owner, 0, 0);

        return newTokenId;
    }

    /**
     * @dev Mints a new ChronoMorph by breeding two existing parent morphs.
     * Parent owners must approve the contract or be the caller.
     * @param owner Address to mint the new morph to.
     * @param parent1Id Token ID of the first parent.
     * @param parent2Id Token ID of the second parent.
     * @return The new token ID.
     */
    function mintFromBreeding(address owner, uint256 parent1Id, uint256 parent2Id) external returns (uint256) {
        require(_exists(parent1Id), "Parent 1 does not exist");
        require(_exists(parent2Id), "Parent 2 does not exist");
        require(parent1Id != parent2Id, "Cannot breed a morph with itself");

        // Check ownership or approval for both parents
        address p1Owner = ownerOf(parent1Id);
        address p2Owner = ownerOf(parent2Id);
        require(p1Owner == msg.sender || getApproved(parent1Id) == msg.sender || isApprovedForAll(p1Owner, msg.sender), "Caller not authorized for parent 1");
        require(p2Owner == msg.sender || getApproved(parent2Id) == msg.sender || isApprovedForAll(p2Owner, msg.sender), "Caller not authorized for parent 2");

        // --- Simplified Breeding Logic ---
        // Generate a new genetic code by combining/mixing parent codes
        bytes32 geneticCode = _generateGeneticCode(parent1Id, parent2Id);

        // Initialize temporal traits based on parents (simplified average/mix)
        ChronoMorph storage p1 = _morphs[parent1Id];
        ChronoMorph storage p2 = _morphs[parent2Id];
        uint[] memory childTraits = new uint[](Math.min(p1.currentTemporalTraits.length, p2.currentTemporalTraits.length));

        // Simple mixing: average traits, with some influence from genetic code
        uint traitLength = childTraits.length;
        bytes32 mixSeed = keccak256(abi.encodePacked(parent1Id, parent2Id, block.timestamp, block.difficulty, msg.sender));

        for (uint i = 0; i < traitLength; i++) {
             uint avgTrait = (p1.currentTemporalTraits[i] + p2.currentTemporalTraits[i]) / 2;
             // Add a small random variation based on mixSeed and genetic code
             uint variation = uint(uint16(bytes2(keccak256(abi.encodePacked(mixSeed, i))))) % 21 - 10; // +- 10
             childTraits[i] = Math.max(0, avgTrait + variation); // Ensure non-negative
        }
        // --- End Simplified Breeding Logic ---


        uint256 newTokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

         _morphs[newTokenId] = ChronoMorph({
            geneticCode: geneticCode,
            creationTime: block.timestamp,
            lastEvolutionTime: block.timestamp,
            temporalAge: 0, // Child starts at age 0
            interactionCount: 0,
            energyLevel: 0,
            inStasis: false,
            stasisStartTime: 0,
            parent1: parent1Id,
            parent2: parent2Id,
            currentTemporalTraits: childTraits
        });

        _safeMint(owner, newTokenId);
        emit MorphMinted(newTokenId, owner, parent1Id, parent2Id);

        return newTokenId;
    }

    /**
     * @dev Triggers the evolution process for a ChronoMorph.
     * Requires ChronoEnergy and sufficient temporal age/potential.
     * @param tokenId The ID of the ChronoMorph to evolve.
     */
    function triggerEvolution(uint256 tokenId) external onlyMorphOwner(tokenId) onlyMorphExists(tokenId) {
        ChronoMorph storage morph = _morphs[tokenId];

        require(!morph.inStasis, "Morph is in stasis");
        require(block.timestamp >= morph.lastEvolutionTime + MIN_EVOLUTION_INTERVAL, "Not enough time passed since last evolution");

        // Calculate energy cost (could scale with temporal age or traits)
        uint256 requiredEnergy = evolutionCost; // Simplified cost
        require(_chronoEnergyToken.balanceOf(msg.sender) >= requiredEnergy, "Insufficient ChronoEnergy balance");
        require(_chronoEnergyToken.allowance(msg.sender, address(this)) >= requiredEnergy, "ChronoEnergy allowance too low");

        // Calculate evolution potential based on age, interactions, energy, and flow rate
        uint256 potential = calculateEvolutionPotential(tokenId);
        require(potential > 0, "Evolution potential is zero"); // Must have some potential to evolve

        // Pay ChronoEnergy
        bool success = _chronoEnergyToken.transferFrom(msg.sender, address(this), requiredEnergy);
        require(success, "ChronoEnergy transfer failed");

        // Update temporal age
        uint256 timeElapsed = block.timestamp - morph.lastEvolutionTime;
        morph.temporalAge += timeElapsed * temporalFlowRate;
        morph.lastEvolutionTime = block.timestamp;

        // Perform mutation based on potential, genetic code, time, block data
        uint256 evolutionSeed = uint256(keccak256(abi.encodePacked(
            morph.geneticCode,
            morph.temporalAge,
            morph.interactionCount,
            morph.energyLevel,
            block.timestamp,
            block.number,
            block.difficulty // Or block.prevrandao for newer versions
        )));
        _mutateTraits(tokenId, evolutionSeed);

        // Reset interaction count and energy level (optional, depends on game mechanics)
        morph.interactionCount = 0;
        morph.energyLevel = 0; // Or reduce by a percentage

        emit MorphEvolved(tokenId, morph.currentTemporalTraits, morph.temporalAge);
    }

     /**
     * @dev Simulates a generic interaction with a ChronoMorph. Increases interaction count.
     * @param tokenId The ID of the ChronoMorph to interact with.
     */
    function interactWithMorph(uint256 tokenId) external onlyMorphExists(tokenId) {
        // Can add a cost here, or make it free
        _morphs[tokenId].interactionCount++;

        // Simple logic: chance for a minor spontaneous mutation or energy gain based on interaction
        uint256 interactionSeed = uint256(keccak256(abi.encodePacked(
            tokenId,
            msg.sender,
            _morphs[tokenId].interactionCount,
            block.timestamp,
            block.number
        )));
        if (interactionSeed % (mutationBaseChance * 10) == 0) { // Small chance for a spontaneous event
             _mutateTraits(tokenId, interactionSeed); // Minor mutation
             _morphs[tokenId].energyLevel += 10; // Small energy gain
        } else if (interactionSeed % 5 == 0) { // More frequent small energy gain
             _morphs[tokenId].energyLevel += 1;
        }


        emit MorphInteracted(tokenId, msg.sender);
    }

    /**
     * @dev Simulates a challenge between two ChronoMorphs. Outcome depends on traits.
     * Requires caller to own or be approved for both morphs.
     * @param tokenId1 ID of the first challenging morph.
     * @param tokenId2 ID of the second challenged morph.
     * Note: This is a simplified example. Real game logic would be more complex.
     */
    function challengeMorph(uint256 tokenId1, uint256 tokenId2) external {
        require(_exists(tokenId1), "Challenger does not exist");
        require(_exists(tokenId2), "Challenged does not exist");
        require(tokenId1 != tokenId2, "Cannot challenge self");

        // Ensure caller is authorized for both (either owner or approved operator)
        address owner1 = ownerOf(tokenId1);
        address owner2 = ownerOf(tokenId2);
        require(owner1 == msg.sender || getApproved(tokenId1) == msg.sender || isApprovedForAll(owner1, msg.sender), "Caller not authorized for morph 1");
        require(owner2 == msg.sender || getApproved(tokenId2) == msg.sender || isApprovedForAll(owner2, msg.sender), "Caller not authorized for morph 2");

        ChronoMorph storage morph1 = _morphs[tokenId1];
        ChronoMorph storage morph2 = _morphs[tokenId2];

        require(!morph1.inStasis && !morph2.inStasis, "Both morphs must not be in stasis to challenge");
        // Add other conditions like energy cost or cooldowns

        // --- Simplified Challenge Logic ---
        // Sum up trait values (example)
        uint256 score1 = 0;
        for(uint i=0; i < morph1.currentTemporalTraits.length; i++) {
            score1 += morph1.currentTemporalTraits[i];
        }

        uint256 score2 = 0;
        for(uint i=0; i < morph2.currentTemporalTraits.length; i++) {
            score2 += morph2.currentTemporalTraits[i];
        }

        uint256 challengeSeed = uint256(keccak256(abi.encodePacked(
            tokenId1, tokenId2, block.timestamp, block.difficulty // or block.prevrandao
        )));

        // Add some randomness influencing the outcome
        uint256 randomFactor = challengeSeed % 101; // 0-100

        bool morph1Wins = false;
        if (score1 + randomFactor > score2 + (100 - randomFactor)) {
            morph1Wins = true;
        } else if (score1 + randomFactor < score2 + (100 - randomFactor)) {
            morph1Wins = false;
        } else {
            // Draw or based on token ID for tie-breaker
            morph1Wins = tokenId1 < tokenId2;
        }

        // --- Apply Challenge Outcome ---
        if (morph1Wins) {
            // Example: Winner gains small trait boost, loser loses some energy
            if (morph1.currentTemporalTraits.length > 0) morph1.currentTemporalTraits[0] = morph1.currentTemporalTraits[0] + 1;
            if (morph2.energyLevel >= 5) morph2.energyLevel -= 5; else morph2.energyLevel = 0;
             emit MorphEvolved(tokenId1, morph1.currentTemporalTraits, morph1.temporalAge); // Indicate state change
        } else {
            // Example: Loser gains experience (interaction count), winner loses some energy
            morph2.interactionCount++;
            if (morph1.energyLevel >= 5) morph1.energyLevel -= 5; else morph1.energyLevel = 0;
             emit MorphInteracted(tokenId2, owner2); // Indicate state change
        }

        // Emit a specific event for challenge outcome if needed
        // event MorphChallengeOutcome(uint256 indexed winnerTokenId, uint256 indexed loserTokenId, bool isDraw);
        // emit MorphChallengeOutcome(morph1Wins ? tokenId1 : tokenId2, morph1Wins ? tokenId2 : tokenId1, score1 + randomFactor == score2 + (100 - randomFactor));
    }

    /**
     * @dev Feeds ChronoEnergy to a ChronoMorph to increase its internal energy level.
     * @param tokenId The ID of the ChronoMorph to feed.
     * @param amount The amount of ChronoEnergy to feed.
     */
    function feedChronoEnergy(uint256 tokenId, uint256 amount) external onlyMorphOwner(tokenId) onlyMorphExists(tokenId) {
         require(amount > 0, "Amount must be greater than zero");

         require(_chronoEnergyToken.balanceOf(msg.sender) >= amount, "Insufficient ChronoEnergy balance");
         require(_chronoEnergyToken.allowance(msg.sender, address(this)) >= amount, "ChronoEnergy allowance too low");

        bool success = _chronoEnergyToken.transferFrom(msg.sender, address(this), amount);
        require(success, "ChronoEnergy transfer failed");

        _morphs[tokenId].energyLevel += amount; // Increase internal energy pool

        emit ChronoEnergyFed(tokenId, amount);
    }

    /**
     * @dev Toggles the stasis status of a ChronoMorph.
     * When in stasis, temporal age accumulation is paused.
     * @param tokenId The ID of the ChronoMorph.
     */
    function toggleStasis(uint256 tokenId) external onlyMorphOwner(tokenId) onlyMorphExists(tokenId) {
        ChronoMorph storage morph = _morphs[tokenId];
        if (morph.inStasis) {
            morph.inStasis = false;
            morph.stasisStartTime = 0; // Reset stasis start time
            // When coming out of stasis, calculate and add the time elapsed *before* stasis was entered
            // This is already implicitly handled by calculateCurrentAge and triggerEvolution logic
        } else {
             // When entering stasis, first update the temporal age for time passed *before* stasis
             uint256 timeElapsedBeforeStasis = block.timestamp - morph.lastEvolutionTime;
             morph.temporalAge += timeElapsedBeforeStasis * temporalFlowRate;
             morph.lastEvolutionTime = block.timestamp; // Update last evolution time to 'now' before stasis

             morph.inStasis = true;
             morph.stasisStartTime = block.timestamp;
        }
        emit MorphStasisToggled(tokenId, morph.inStasis);
    }

    /**
     * @dev Allows the owner to burn (destroy) their ChronoMorph.
     * @param tokenId The ID of the ChronoMorph to burn.
     */
    function burnMorph(uint256 tokenId) external onlyMorphOwner(tokenId) onlyMorphExists(tokenId) {
        _burn(tokenId);
        delete _morphs[tokenId]; // Clean up morph data
        emit MorphBurned(tokenId);
    }

    // --- Query Functions ---

    /**
     * @dev Retrieves the full ChronoMorph struct data for a token ID.
     * @param tokenId The ID of the ChronoMorph.
     * @return The ChronoMorph struct.
     */
    function getMorphDetails(uint256 tokenId) external view onlyMorphExists(tokenId) returns (ChronoMorph memory) {
        return _morphs[tokenId];
    }

     /**
     * @dev Retrieves the current mutable temporal traits for a token ID.
     * @param tokenId The ID of the ChronoMorph.
     * @return An array of uint representing the temporal traits.
     */
    function getTemporalTraits(uint256 tokenId) external view onlyMorphExists(tokenId) returns (uint[] memory) {
        return _morphs[tokenId].currentTemporalTraits;
    }

    /**
     * @dev Retrieves the immutable genetic code for a token ID.
     * @param tokenId The ID of the ChronoMorph.
     * @return The bytes32 genetic code.
     */
    function getGeneticCode(uint256 tokenId) external view onlyMorphExists(tokenId) returns (bytes32) {
        return _morphs[tokenId].geneticCode;
    }

    /**
     * @dev Calculates the current effective temporal age of the morph.
     * Considers time elapsed since creation or last evolution, excluding stasis periods.
     * @param tokenId The ID of the ChronoMorph.
     * @return The calculated temporal age in seconds, scaled by temporalFlowRate.
     */
    function calculateCurrentAge(uint256 tokenId) public view onlyMorphExists(tokenId) returns (uint256) {
        ChronoMorph storage morph = _morphs[tokenId];
        uint256 currentTemporalAge = morph.temporalAge; // Base accumulated age

        if (!morph.inStasis) {
            // Add age accumulated since last evolution or creation (if never evolved)
             currentTemporalAge += (block.timestamp - morph.lastEvolutionTime) * temporalFlowRate;
        } else {
            // Age accumulation paused. morph.temporalAge was updated when entering stasis.
        }
        return currentTemporalAge;
    }

    /**
     * @dev Calculates a score indicating the ChronoMorph's potential for evolution.
     * Based on age, interaction count, energy level, and global flow rate.
     * @param tokenId The ID of the ChronoMorph.
     * @return A uint256 representing the evolution potential (higher is better).
     */
    function calculateEvolutionPotential(uint256 tokenId) public view onlyMorphExists(tokenId) returns (uint256) {
        ChronoMorph storage morph = _morphs[tokenId];
        if (morph.inStasis) {
            return 0; // No potential while in stasis
        }

        uint256 effectiveAge = calculateCurrentAge(tokenId);
        uint256 potential = 0;

        // Simple potential calculation: Age + Interaction Count + Energy Level, all scaled by flow rate
        potential = (effectiveAge / 1000 + morph.interactionCount + (morph.energyLevel / 1e18)) * temporalFlowRate; // Example scaling

        // Add a bonus if significant time has passed since last evolution
        if (block.timestamp >= morph.lastEvolutionTime + MIN_EVOLUTION_INTERVAL) {
             potential += 50 * temporalFlowRate; // Arbitrary bonus
        }


        // Ensure minimum threshold? Or just return calculated value.
        return potential;
    }

     /**
     * @dev Checks if a ChronoMorph is currently eligible to trigger evolution.
     * @param tokenId The ID of the ChronoMorph.
     * @return True if eligible, false otherwise.
     */
    function canEvolve(uint256 tokenId) public view onlyMorphExists(tokenId) returns (bool) {
        ChronoMorph storage morph = _morphs[tokenId];
        if (morph.inStasis) return false;

        // Check sufficient time since last evolution
        if (block.timestamp < morph.lastEvolutionTime + MIN_EVOLUTION_INTERVAL) return false;

        // Check if potential is non-zero (implies minimum age/interaction/energy)
        if (calculateEvolutionPotential(tokenId) == 0) return false;

         // Check if owner has enough ChronoEnergy and allowance
         uint256 requiredEnergy = evolutionCost; // Simplified cost
         address morphOwner = ownerOf(tokenId);
         if (_chronoEnergyToken.balanceOf(morphOwner) < requiredEnergy) return false;
         if (_chronoEnergyToken.allowance(morphOwner, address(this)) < requiredEnergy) return false;


        return true;
    }

    /**
     * @dev Returns all token IDs owned by a specific address. Uses ERC721Enumerable.
     * @param owner The address to query.
     * @return An array of token IDs.
     */
    function getMorphsOwnedBy(address owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokens = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokens[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokens;
    }


    // --- Admin Functions (Ownable) ---

    /**
     * @dev Sets the global temporal flow rate. Affects age accumulation and potential.
     * Only callable by owner.
     * @param newRate The new temporal flow rate (e.g., 1 = normal, 2 = double speed).
     */
    function setTemporalFlowRate(uint256 newRate) external onlyOwner {
        require(newRate > 0, "Flow rate must be positive");
        temporalFlowRate = newRate;
        emit TemporalFlowRateUpdated(newRate);
    }

    /**
     * @dev Sets parameters for mutation chance and evolution cost.
     * Only callable by owner.
     * @param _mutationBaseChance New base chance denominator.
     * @param _evolutionCost New cost in ChronoEnergy.
     */
    function setMutationParameters(uint256 _mutationBaseChance, uint256 _evolutionCost) external onlyOwner {
        require(_mutationBaseChance > 0, "Base chance must be positive");
        mutationBaseChance = _mutationBaseChance;
        evolutionCost = _evolutionCost;
        emit MutationParametersUpdated(mutationBaseChance, evolutionCost);
    }

     /**
     * @dev Allows owner to apply a specific external stimulus to a morph.
     * Could represent an event in a larger game world or an admin adjustment.
     * @param tokenId The ID of the ChronoMorph.
     * @param stimulusId An ID representing the type of stimulus.
     * @param data Optional extra data related to the stimulus.
     * Note: Specific effects of stimulus would be implemented here or in a separate logic layer.
     */
    function applyStimulus(uint256 tokenId, uint256 stimulusId, bytes calldata data) external onlyOwner onlyMorphExists(tokenId) {
        // Example: Stimulus 1 could add energy, Stimulus 2 could trigger a special mutation roll
        ChronoMorph storage morph = _morphs[tokenId];
        if (stimulusId == 1) {
            uint256 energyBoost = data.length > 0 ? abi.decode(data, (uint256)) : 100e18; // Default boost
            morph.energyLevel += energyBoost;
        } else if (stimulusId == 2) {
             // Trigger a special mutation roll with a different seed
             uint256 stimulusSeed = uint256(keccak256(abi.encodePacked(tokenId, stimulusId, data, block.timestamp)));
             _mutateTraits(tokenId, stimulusSeed);
        }
        // Add more stimulus types as needed...

        emit StimulusApplied(tokenId, stimulusId, data);
    }


    /**
     * @dev Sets the base URI for token metadata.
     * Only callable by owner.
     * @param newBaseURI The new base URI string.
     */
    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }

     /**
     * @dev Allows owner to withdraw any accidental ERC20 tokens sent to the contract.
     * Excludes the designated ChronoEnergy token if it's being used for contract mechanics.
     * @param tokenAddress Address of the ERC20 token to withdraw.
     * @param amount Amount of tokens to withdraw.
     */
    function withdrawERC20(address tokenAddress, uint256 amount) external onlyOwner {
         // Optional: Prevent withdrawing the contract's designated ChronoEnergy if needed for mechanics
         // require(tokenAddress != address(_chronoEnergyToken), "Cannot withdraw designated ChronoEnergy");
         IERC20 token = IERC20(tokenAddress);
         token.transfer(msg.sender, amount);
     }


    // --- ERC721/Enumerable Overrides ---

    /**
     * @dev Returns the metadata URI for `tokenId`.
     * Appends the token ID and potentially query parameters based on temporal traits.
     */
    function tokenURI(uint256 tokenId) public view override onlyMorphExists(tokenId) returns (string memory) {
        // Example: baseURI/tokenId?[trait1]=[value1]&[trait2]=[value2]...
        ChronoMorph storage morph = _morphs[tokenId];
        string memory base = _baseTokenURI;
        string memory id = Strings.toString(tokenId);

        // Simple example: append traits as query parameters.
        // Real implementation would require more complex string concatenation or use an API.
        string memory traitParams = "";
        if (morph.currentTemporalTraits.length > 0) {
            traitParams = string.concat("?t=");
            for (uint i = 0; i < morph.currentTemporalTraits.length; i++) {
                traitParams = string.concat(traitParams, Strings.toString(morph.currentTemporalTraits[i]));
                if (i < morph.currentTemporalTraits.length - 1) {
                    traitParams = string.concat(traitParams, ",");
                }
            }
             // Add age, energy etc. as well?
             traitParams = string.concat(traitParams, "&age=", Strings.toString(calculateCurrentAge(tokenId)));
             traitParams = string.concat(traitParams, "&energy=", Strings.toString(morph.energyLevel)); // Note: Large energy values might exceed practical URI limits
        }


        return string(abi.encodePacked(base, id, traitParams));
    }

     /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // The following functions are overrides required by Solidity.
    // They are inherited from ERC721Enumerable and ERC721 and handle token ownership tracking.
    // No need to add complex ChronoMorph logic here unless state changes are required on transfer.
    // For this contract, we assume temporal state persists across transfers, but temporalAge stops accumulating if not owned/interacted with.

    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint256 value) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }


    // --- Internal Helper Functions ---

    /**
     * @dev Internal function to apply trait mutations based on a seed.
     * Simplified on-chain procedural logic.
     * @param tokenId The ID of the ChronoMorph to mutate.
     * @param evolutionSeed A seed value influencing the mutation outcome.
     */
    function _mutateTraits(uint256 tokenId, uint256 evolutionSeed) internal {
        ChronoMorph storage morph = _morphs[tokenId];
        uint traitCount = morph.currentTemporalTraits.length;

        // Use the seed and trait index to determine mutation likelihood and magnitude
        bytes32 mutationBase = keccak256(abi.encodePacked(evolutionSeed, morph.geneticCode));

        for (uint i = 0; i < traitCount; i++) {
            bytes32 traitSpecificSeed = keccak256(abi.encodePacked(mutationBase, i));
            uint256 mutationRoll = uint256(traitSpecificSeed) % mutationBaseChance;

            // Simple probabilistic mutation
            if (mutationRoll < (temporalFlowRate + morph.interactionCount/10 + morph.energyLevel/1e18)) { // Chance increases with flow, interactions, energy
                int256 mutationMagnitude = int256(uint256(keccak256(abi.encodePacked(traitSpecificSeed, block.timestamp))) % 21) - 10; // Random magnitude between -10 and +10

                // Apply mutation, ensure non-negative traits
                int256 currentTrait = int256(morph.currentTemporalTraits[i]);
                morph.currentTemporalTraits[i] = uint(Math.max(0, currentTrait + mutationMagnitude));
            }
        }
    }

     /**
     * @dev Internal function to generate a new genetic code from two parents.
     * Simplified logic (e.g., XOR, blend, or pick bits).
     * @param parent1Id Token ID of parent 1.
     * @param parent2Id Token ID of parent 2.
     * @return The new bytes32 genetic code.
     */
    function _generateGeneticCode(uint256 parent1Id, uint256 parent2Id) internal view returns (bytes32) {
        bytes32 genetic1 = _morphs[parent1Id].geneticCode;
        bytes32 genetic2 = _morphs[parent2Id].geneticCode;

        // Simple mixing example: XOR the two codes with a random element
        bytes32 mixSeed = keccak256(abi.encodePacked(parent1Id, parent2Id, block.timestamp, block.difficulty)); // or block.prevrandao
        return genetic1 ^ genetic2 ^ mixSeed;

        // More complex logic could involve bitwise operations, averaging byte values, etc.
    }

    // Optional: Add _beforeTokenTransfer hook if transfer should reset temporal stats
    // function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
    //     super._beforeTokenTransfer(from, to, tokenId);
    //     // Example: Reset interaction count on transfer?
    //     // if (from != address(0)) { // Not a mint
    //     //     _morphs[tokenId].interactionCount = 0;
    //     //     _morphs[tokenId].energyLevel = 0;
    //     //      // Potentially update temporalAge accumulation state if needed
    //     // }
    // }


}
```