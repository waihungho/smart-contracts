Okay, here is a smart contract in Solidity demonstrating some advanced concepts like dynamic NFT state, time-based resource management, interactions between NFTs, and basic evolution/mutation mechanics.

It aims for creativity by making the NFTs living, interactive entities rather than just static tokens. It avoids directly duplicating standard OpenZeppelin implementations beyond the basic ERC721 interface and ownership, implementing the core dynamic logic from scratch.

**Concept:**

This contract manages "Evolutionary NFTs". Each NFT represents a creature with dynamic traits (Level, Experience, Energy, Strength, Agility, Intelligence) that change based on owner actions (Feed, Train, Rest), interactions with other NFTs (Battle), and time (Energy Regeneration). NFTs can level up, mutate, and potentially evolve into new species.

**State:**

*   Standard ERC721 ownership and token metadata.
*   `NFTState` struct storing dynamic properties for each token ID (species, level, experience, energy, timestamps, traits).
*   Mappings for species-specific base stats and energy parameters (max energy, regen rate).
*   Array for experience thresholds required for leveling up.
*   Base URI for dynamic metadata (off-chain service needed to interpret state).

**Mechanics:**

*   **Time-Based Energy:** Energy regenerates over time based on the NFT's species and the time elapsed since the last energy update. Actions require energy.
*   **Experience & Leveling:** Gaining experience points (XP) from actions allows NFTs to level up, increasing their stats and unlocking potential abilities (like mutation/evolution).
*   **Actions:** Owner/approved users can trigger actions like Feeding (restores energy), Training (consumes energy, gains XP), and Resting (explicitly updates energy).
*   **Battle:** Two NFTs can battle, consuming energy. The outcome depends on stats, resulting in XP gain (more for winner) and a chance for mutation for both.
*   **Mutation:** Can be triggered explicitly (costs energy) or occur randomly after battles. Results in random stat boosts or, rarely, an attempt at species evolution.
*   **Species Evolution:** A higher-level, mutated NFT can attempt to evolve to a new species if configured, changing its base parameters and potentially gaining new abilities (conceptually, implemented as stat adjustments here).
*   **Dynamic Metadata:** The `tokenURI` reflects the *current* on-chain state, requiring a separate service to serve dynamic JSON metadata based on the token's traits.

**Function Summary (38 Functions):**

**ERC721 Standard Functions (11):**

1.  `name()`: Returns the collection name.
2.  `symbol()`: Returns the collection symbol.
3.  `balanceOf(address owner)`: Returns the number of tokens owned by an address.
4.  `ownerOf(uint256 tokenId)`: Returns the owner of a specific token.
5.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers token ownership (requires approval/ownership).
6.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Transfers token ownership safely (checks receiver).
7.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: Safe transfer with data.
8.  `approve(address to, uint256 tokenId)`: Approves an address to spend a specific token.
9.  `getApproved(uint256 tokenId)`: Returns the approved address for a token.
10. `setApprovalForAll(address operator, bool approved)`: Approves or revokes an operator for all tokens.
11. `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for all tokens.
12. `supportsInterface(bytes4 interfaceId)`: ERC165 interface support check. (Inherited)

**Custom State & Dynamics Functions (26):**

13. `tokenURI(uint256 tokenId)`: Returns the dynamic metadata URI based on the configured base URI and token ID.
14. `mint(address to, uint256 initialSpeciesId)`: (Owner Only) Mints a new NFT with initial species stats.
15. `getNFTState(uint256 tokenId)`: Views the full state struct of an NFT.
16. `getEnergy(uint256 tokenId)`: Calculates and returns the current energy of an NFT, based on regeneration (updates state).
17. `getLevel(uint256 tokenId)`: Returns the NFT's current level.
18. `getExperience(uint256 tokenId)`: Returns the NFT's current experience points.
19. `getSpeciesId(uint256 tokenId)`: Returns the NFT's current species identifier.
20. `getStrength(uint256 tokenId)`: Returns the NFT's current Strength trait value.
21. `getAgility(uint256 tokenId)`: Returns the NFT's current Agility trait value.
22. `getIntelligence(uint256 tokenId)`: Returns the NFT's current Intelligence trait value.
23. `getMutationCount(uint256 tokenId)`: Returns how many times the NFT has mutated.
24. `getTimeSinceLastAction(uint256 tokenId)`: Returns time elapsed since any state-changing action.
25. `getTimeUntilFullEnergy(uint256 tokenId)`: Estimates time needed to reach max energy.
26. `feed(uint256 tokenId)`: Increases NFT energy and grants minor experience (Owner or approved).
27. `train(uint256 tokenId)`: Consumes energy, grants significant experience, potentially levels up (Owner or approved).
28. `rest(uint256 tokenId)`: Explicitly updates energy state based on elapsed time (Owner or approved).
29. `battle(uint256 tokenId1, uint256 tokenId2)`: Simulates a battle, consumes energy, updates exp/traits/mutation (Owner or approved of one).
30. `mutate(uint256 tokenId)`: Consumes energy, triggers a random mutation attempt (Owner or approved).
31. `evolveSpecies(uint256 tokenId, uint256 newSpeciesId)`: Attempts to evolve species if conditions met (Owner or approved).
32. `checkCanBattle(uint256 tokenId1, uint256 tokenId2)`: View function checking battle prerequisites.
33. `checkCanMutate(uint256 tokenId)`: View function checking mutation prerequisites.
34. `setLevelUpExperienceThresholds(uint256[] calldata thresholds)`: (Owner Only) Sets global XP needed for each level.
35. `setSpeciesBaseStats(uint256 speciesId, uint256 maxEnergy, uint256 energyRegenRate, uint256 baseStrength, uint256 baseAgility, uint256 baseIntelligence)`: (Owner Only) Configures species base stats.
36. `setMetadataBaseURI(string calldata baseURI)`: (Owner Only) Sets the base URI for token metadata.
37. `getSpeciesBaseStats(uint256 speciesId)`: View function to get base stats for a species.
38. `getLevelUpThreshold(uint256 level)`: View function to get XP threshold for a specific level.

*(Note: Some internal helper functions like `_updateEnergy` and `_checkLevelUp` are crucial but not counted in the 20+ public/external functions requirement. The battle outcome calculation `calculateBattleOutcome` is exposed as a public view helper)*

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
// import "hardhat/console.sol"; // Uncomment for debugging

// --- Outline ---
// 1. Concept: Evolutionary NFTs with dynamic traits (Level, Exp, Energy, Stats), time-based energy regen, and interaction mechanics (Feed, Train, Rest, Battle, Mutate, Evolve).
// 2. State: ERC721 ownership, NFT specific state (struct), configuration parameters (species stats, level thresholds, URIs).
// 3. Mechanics: Time-based energy regen, experience/leveling, probabilistic mutation, battle outcome based on stats, species evolution based on conditions.
// 4. Functions: Standard ERC721 interface, custom state getters, action functions (modifying state), interaction functions (battle), configuration functions (owner only), helper views/checks.

// --- Function Summary (Counted Public/External) ---
// ERC721 Standard Functions (12 including supportsInterface): name, symbol, balanceOf, ownerOf, transferFrom, safeTransferFrom (x2), approve, getApproved, setApprovalForAll, isApprovedForAll, supportsInterface.
// Custom State & Dynamics Functions (26): tokenURI, mint, getNFTState, getEnergy, getLevel, getExperience, getSpeciesId, getStrength, getAgility, getIntelligence, getMutationCount, getTimeSinceLastAction, getTimeUntilFullEnergy, feed, train, rest, battle, mutate, evolveSpecies, checkCanBattle, checkCanMutate, setLevelUpExperienceThresholds, setSpeciesBaseStats, setMetadataBaseURI, getSpeciesBaseStats, getLevelUpThreshold.
// Total Public/External Functions: 12 + 26 = 38 functions.

contract EvolutionaryNFT is ERC721URIStorage, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    // --- State Variables ---

    struct NFTState {
        uint256 speciesId;
        uint256 level;
        uint256 experience;
        uint256 energy; // Current energy
        uint48 lastEnergyUpdateTime; // Timestamp of last energy calculation/update
        uint48 lastActionTime; // Timestamp of last state-changing action (for general cooldowns/checks)
        uint256 mutationCount; // How many times this NFT has mutated
        // Example Traits (can be extended)
        uint256 strength;
        uint256 agility;
        uint256 intelligence;
    }

    mapping(uint256 => NFTState) private _nftStates;

    // Species Configuration (Owner settable)
    mapping(uint256 => uint256) private _speciesMaxEnergy;
    mapping(uint256 => uint256) private _speciesEnergyRegenRate; // Energy gained per second
    mapping(uint256 => uint256) private _speciesBaseStrength;
    mapping(uint256 => uint256) private _speciesBaseAgility;
    mapping(uint256 => uint256) private _speciesBaseIntelligence;

    // Leveling Configuration (Owner settable)
    // thresholds[level-1] = exp needed to reach level
    // E.g., thresholds[0] is XP needed to reach level 1 (i.e., 0, or maybe base XP), thresholds[1] is XP needed to reach level 2
    // Let's define thresholds[level] as XP needed to reach level + 1
    // thresholds[0] -> XP for Level 2, thresholds[1] -> XP for Level 3, etc.
    uint256[] private _levelUpExperienceThresholds;

    // Metadata
    string private _metadataBaseURI;

    // --- Events ---

    event NFTMinted(uint256 indexed tokenId, address indexed owner, uint256 speciesId);
    event NFTStateUpdated(uint256 indexed tokenId, uint256 level, uint256 experience, uint256 energy, uint256 strength, uint256 agility, uint256 intelligence, uint256 mutationCount);
    event LeveledUp(uint256 indexed tokenId, uint256 oldLevel, uint256 newLevel);
    event EnergyChanged(uint256 indexed tokenId, uint256 oldEnergy, uint256 newEnergy);
    event Battled(uint256 indexed tokenId1, uint256 indexed tokenId2, int256 outcome); // outcome > 0: token1 favored, < 0: token2 favored, == 0: draw
    event Mutated(uint256 indexed tokenId, uint256 mutationType, string description); // mutationType: 0=StatBoost, 1=EvolveAttempt, 2=BattleMutation
    event SpeciesEvolved(uint256 indexed tokenId, uint256 oldSpeciesId, uint256 newSpeciesId);
    event TraitChanged(uint256 indexed tokenId, string traitName, uint256 oldValue, uint256 newValue);

    // --- Constructor ---

    constructor() ERC721("EvolutionaryNFT", "EVO") {}

    // --- Modifiers ---

    modifier validNFT(uint256 tokenId) {
        require(_exists(tokenId), "EVO: token does not exist");
        _;
    }

    modifier onlyOwnerOrApproved(uint256 tokenId) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "EVO: caller is not owner nor approved");
        _;
    }

     modifier enoughEnergy(uint256 tokenId, uint256 requiredEnergy) {
         // Use _updateEnergy to ensure state is current before checking
         _updateEnergy(tokenId);
         require(_nftStates[tokenId].energy >= requiredEnergy, "EVO: insufficient energy");
         _;
    }


    // --- Standard ERC721 Overrides ---

    /// @notice Returns the dynamic metadata URI for a token.
    /// The off-chain service at the base URI should interpret the on-chain state to generate metadata.
    /// @param tokenId The ID of the NFT.
    /// @return The URI string.
    function tokenURI(uint256 tokenId) override(ERC721URIStorage) public view validNFT(tokenId) returns (string memory) {
        // If _metadataBaseURI is set, append the token ID. Otherwise, use default ERC721URIStorage logic (unlikely to be set here).
        return bytes(_metadataBaseURI).length > 0 ? string(abi.encodePacked(_metadataBaseURI, tokenId.toString())) : super.tokenURI(tokenId);
    }

    /// @notice ERC165 support check. Adds ERC721URIStorage interface ID.
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return interfaceId == type(ERC721).interfaceId ||
               interfaceId == type(ERC721URIStorage).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    // --- Owner Configuration Functions (4) ---

    /// @notice Mints a new NFT with a specified initial species. Owner only.
    /// @param to The address to mint the token to.
    /// @param initialSpeciesId The identifier for the initial species.
    function mint(address to, uint256 initialSpeciesId) public onlyOwner {
        uint256 newItemId = totalSupply().add(1);

        require(_speciesMaxEnergy[initialSpeciesId] > 0, "EVO: invalid species ID or species not configured");

        _safeMint(to, newItemId);

        NFTState storage newState = _nftStates[newItemId];
        newState.speciesId = initialSpeciesId;
        newState.level = 1;
        newState.experience = 0;
        newState.energy = _speciesMaxEnergy[initialSpeciesId]; // Start with full energy
        newState.lastEnergyUpdateTime = uint48(block.timestamp);
        newState.lastActionTime = uint48(block.timestamp);
        newState.mutationCount = 0;
        newState.strength = _speciesBaseStrength[initialSpeciesId];
        newState.agility = _speciesBaseAgility[initialSpeciesId];
        newState.intelligence = _speciesBaseIntelligence[initialSpeciesId];

        emit NFTMinted(newItemId, to, initialSpeciesId);
        emit NFTStateUpdated(newItemId, newState.level, newState.experience, newState.energy, newState.strength, newState.agility, newState.intelligence, newState.mutationCount);
    }

    /// @notice Sets the experience thresholds required to reach each level. Owner only.
    /// thresholds[level-1] = XP needed to reach 'level'.
    /// E.g., thresholds[0] is XP for level 1, thresholds[1] for level 2, etc.
    /// Level 1 requires 0 XP, so thresholds[0] should be 0 or ignored for Lvl 1 check.
    /// Array index i corresponds to the threshold to reach level i+1.
    /// @param thresholds An array of XP thresholds.
    function setLevelUpExperienceThresholds(uint256[] calldata thresholds) public onlyOwner {
        _levelUpExperienceThresholds = thresholds;
    }

    /// @notice Sets or updates the base stats and energy parameters for a given species. Owner only.
    /// @param speciesId The identifier for the species.
    /// @param maxEnergy Max energy for this species.
    /// @param energyRegenRate Energy gained per second for this species.
    /// @param baseStrength Base Strength stat.
    /// @param baseAgility Base Agility stat.
    /// @param baseIntelligence Base Intelligence stat.
    function setSpeciesBaseStats(
        uint256 speciesId,
        uint256 maxEnergy,
        uint256 energyRegenRate,
        uint256 baseStrength,
        uint256 baseAgility,
        uint256 baseIntelligence
    ) public onlyOwner {
        _speciesMaxEnergy[speciesId] = maxEnergy;
        _speciesEnergyRegenRate[speciesId] = energyRegenRate;
        _speciesBaseStrength[speciesId] = baseStrength;
        _speciesBaseAgility[speciesId] = baseAgility;
        _speciesBaseIntelligence[speciesId] = baseIntelligence;
    }

     /// @notice Sets the base URI for fetching dynamic metadata. Owner only.
     /// The service at this URI should handle the dynamic state.
     /// @param baseURI The base URI string.
    function setMetadataBaseURI(string calldata baseURI) public onlyOwner {
        _metadataBaseURI = baseURI;
    }

    // --- View Functions (14) ---

    /// @notice Gets the full current stored state of an NFT.
    /// Note: The energy value returned here might be outdated; use getEnergy() for the real-time calculated value.
    /// @param tokenId The ID of the NFT.
    /// @return The NFTState struct.
    function getNFTState(uint256 tokenId) public view validNFT(tokenId) returns (NFTState memory) {
        return _nftStates[tokenId];
    }

    /// @notice Gets the current energy of an NFT, calculated with regen.
    /// This view function does not update the stored state.
    /// @param tokenId The ID of the NFT.
    /// @return The current energy level.
    function getEnergy(uint256 tokenId) public view validNFT(tokenId) returns (uint256) {
         NFTState storage nft = _nftStates[tokenId]; // Access storage for reference
         return _calculateCurrentEnergy(tokenId, nft.energy, nft.lastEnergyUpdateTime);
    }

    /// @notice Gets the current level of an NFT.
    /// @param tokenId The ID of the NFT.
    /// @return The current level.
    function getLevel(uint256 tokenId) public view validNFT(tokenId) returns (uint256) {
        return _nftStates[tokenId].level;
    }

    /// @notice Gets the current experience of an NFT.
    /// @param tokenId The ID of the NFT.
    /// @return The current experience.
    function getExperience(uint256 tokenId) public view validNFT(tokenId) returns (uint256) {
        return _nftStates[tokenId].experience;
    }

    /// @notice Gets the current species ID of an NFT.
    /// @param tokenId The ID of the NFT.
    /// @return The current species ID.
    function getSpeciesId(uint256 tokenId) public view validNFT(tokenId) returns (uint256) {
        return _nftStates[tokenId].speciesId;
    }

    /// @notice Gets the current Strength trait value.
    /// @param tokenId The ID of the NFT.
    /// @return The strength value.
    function getStrength(uint256 tokenId) public view validNFT(tokenId) returns (uint256) {
         return _nftStates[tokenId].strength;
    }

    /// @notice Gets the current Agility trait value.
    /// @param tokenId The ID of the NFT.
    /// @return The agility value.
    function getAgility(uint256 tokenId) public view validNFT(tokenId) returns (uint256) {
         return _nftStates[tokenId].agility;
    }

    /// @notice Gets the current Intelligence trait value.
    /// @param tokenId The ID of the NFT.
    /// @return The intelligence value.
    function getIntelligence(uint256 tokenId) public view validNFT(tokenId) returns (uint256) {
         return _nftStates[tokenId].intelligence;
    }

     /// @notice Gets the mutation count of an NFT.
     /// @param tokenId The ID of the NFT.
     /// @return The number of mutations.
    function getMutationCount(uint256 tokenId) public view validNFT(tokenId) returns (uint256) {
         return _nftStates[tokenId].mutationCount;
    }


    /// @notice Gets the time elapsed since the last action for an NFT.
    /// Actions include Feed, Train, Rest, Battle, Mutate, EvolveSpecies.
    /// @param tokenId The ID of the NFT.
    /// @return Time in seconds.
    function getTimeSinceLastAction(uint256 tokenId) public view validNFT(tokenId) returns (uint256) {
        return block.timestamp - _nftStates[tokenId].lastActionTime;
    }

    /// @notice Estimates time remaining until an NFT reaches max energy.
    /// @param tokenId The ID of the NFT.
    /// @return Time in seconds. Returns 0 if already at max energy, or a large number if regen is 0.
    function getTimeUntilFullEnergy(uint256 tokenId) public view validNFT(tokenId) returns (uint256) {
        uint256 currentEnergy = getEnergy(tokenId); // Calls view energy calculation
        uint256 speciesId = _nftStates[tokenId].speciesId;
        uint256 maxEnergy = _speciesMaxEnergy[speciesId];
        uint256 regenRate = _speciesEnergyRegenRate[speciesId];

        if (currentEnergy >= maxEnergy) {
            return 0;
        }
        if (regenRate == 0) {
             return type(uint256).max; // Effectively infinity if no regen
        }

        uint256 energyNeeded = maxEnergy.sub(currentEnergy);
        // Integer division rounds down, which is acceptable for an estimate
        return energyNeeded.div(regenRate);
    }

     /// @notice Checks if two NFTs meet the basic requirements to battle (e.g., energy).
     /// Does not check ownership/approval.
     /// @param tokenId1 ID of the first NFT.
     /// @param tokenId2 ID of the second NFT.
     /// @return True if battle is possible based on internal state prerequisites, false otherwise.
    function checkCanBattle(uint256 tokenId1, uint256 tokenId2) public view validNFT(tokenId1) validNFT(tokenId2) returns (bool) {
        if (tokenId1 == tokenId2) return false;
        // Example Battle cost is 10 energy for this example
        uint256 battleCost = 10;
        // Use getEnergy view function here
        return getEnergy(tokenId1) >= battleCost && getEnergy(tokenId2) >= battleCost;
        // Could add more checks: min level, specific traits, not on cooldown, etc.
    }

     /// @notice Checks if an NFT meets the basic requirements to attempt mutation (e.g., energy, level).
     /// Does not check ownership/approval.
     /// @param tokenId ID of the NFT.
     /// @return True if mutation attempt is possible based on internal state prerequisites, false otherwise.
    function checkCanMutate(uint256 tokenId) public view validNFT(tokenId) returns (bool) {
         // Example Mutation cost is 50 energy
        uint256 mutationCost = 50;
        // Use getEnergy view function here
        return getEnergy(tokenId) >= mutationCost && _nftStates[tokenId].level >= 5; // Example: min level 5 to mutate
        // Could add cooldowns, item requirements, etc.
    }

    /// @notice Gets the base stats configured for a specific species.
    /// @param speciesId The identifier for the species.
    /// @return maxEnergy, energyRegenRate, baseStrength, baseAgility, baseIntelligence
    function getSpeciesBaseStats(uint256 speciesId) public view returns (uint256 maxEnergy, uint256 energyRegenRate, uint256 baseStrength, uint256 baseAgility, uint256 baseIntelligence) {
         return (
             _speciesMaxEnergy[speciesId],
             _speciesEnergyRegenRate[speciesId],
             _speciesBaseStrength[speciesId],
             _speciesBaseAgility[speciesId],
             _speciesBaseIntelligence[speciesId]
         );
    }

    /// @notice Gets the experience threshold needed to reach a specific level.
    /// @param level The level for which to get the threshold (e.g., level 2 requires thresholds[1]).
    /// @return The XP needed to reach that level from the previous one. Returns 0 if level is 1 or out of bounds.
    function getLevelUpThreshold(uint256 level) public view returns (uint256) {
        // Level 1 requires 0 XP (or base XP). Thresholds array index i is for reaching level i+1.
        // So, level 2 needs thresholds[1], level 3 needs thresholds[2], etc.
        if (level == 0 || level >= _levelUpExperienceThresholds.length.add(2)) return 0; // Levels 0 and beyond defined thresholds
        if (level == 1) return 0; // Level 1 requires 0 XP (starting state)
        return _levelUpExperienceThresholds[level.sub(2)]; // For level N (N>1), look at index N-2
    }


    // --- Action Functions (8) ---

    /// @notice Feeds an NFT, restoring energy and granting a small amount of experience.
    /// Requires caller to be owner or approved for the token.
    /// @param tokenId The ID of the NFT.
    function feed(uint256 tokenId) public validNFT(tokenId) onlyOwnerOrApproved(tokenId) {
         _updateEnergy(tokenId); // Update energy before modifying it

         NFTState storage nft = _nftStates[tokenId];
         uint256 oldEnergy = nft.energy;
         uint256 energyGained = 30; // Example fixed amount
         uint256 expGained = 5; // Example fixed amount

         uint256 maxEnergy = _speciesMaxEnergy[nft.speciesId];
         nft.energy = (nft.energy + energyGained).min(maxEnergy);
         nft.experience = nft.experience.add(expGained);
         nft.lastActionTime = uint48(block.timestamp);

         _checkLevelUp(tokenId); // Check if feeding caused level up

         emit EnergyChanged(tokenId, oldEnergy, nft.energy);
         emit NFTStateUpdated(tokenId, nft.level, nft.experience, nft.energy, nft.strength, nft.agility, nft.intelligence, nft.mutationCount);
    }


    /// @notice Trains an NFT, consuming energy and granting significant experience.
    /// Requires caller to be owner or approved for the token. Requires enough energy.
    /// @param tokenId The ID of the NFT.
    function train(uint256 tokenId) public validNFT(tokenId) onlyOwnerOrApproved(tokenId) enoughEnergy(tokenId, 15) { // Example cost: 15 energy
         // _updateEnergy is called by enoughEnergy modifier
         NFTState storage nft = _nftStates[tokenId];
         uint256 oldEnergy = nft.energy;

         uint256 energyCost = 15;
         uint256 expGained = 25; // Example fixed amount

         nft.energy = nft.energy.sub(energyCost);
         nft.experience = nft.experience.add(expGained);
         nft.lastEnergyUpdateTime = uint48(block.timestamp); // Update energy timestamp after consumption
         nft.lastActionTime = uint48(block.timestamp);

         _checkLevelUp(tokenId);

         emit EnergyChanged(tokenId, oldEnergy, nft.energy);
         emit NFTStateUpdated(tokenId, nft.level, nft.experience, nft.energy, nft.strength, nft.agility, nft.intelligence, nft.mutationCount);
    }

    /// @notice Rests an NFT, explicitly updating energy state based on time.
    /// Requires caller to be owner or approved for the token.
    /// @param tokenId The ID of the NFT.
    function rest(uint256 tokenId) public validNFT(tokenId) onlyOwnerOrApproved(tokenId) {
         // This action simply updates the energy based on time elapsed.
         // It ensures the energy state variable itself is current.
         uint256 oldEnergy = _nftStates[tokenId].energy;
         _updateEnergy(tokenId);
         _nftStates[tokenId].lastActionTime = uint48(block.timestamp); // Consider rest as an action

         emit EnergyChanged(tokenId, oldEnergy, _nftStates[tokenId].energy);
         emit NFTStateUpdated(tokenId, _nftStates[tokenId].level, _nftStates[tokenId].experience, _nftStates[tokenId].energy, _nftStates[tokenId].strength, _nftStates[tokenId].agility, _nftStates[tokenId].intelligence, _nftStates[tokenId].mutationCount);
    }

    /// @notice Initiates a battle between two NFTs.
    /// Requires caller to be owner or approved for at least one token. Requires both NFTs have enough energy.
    /// @param tokenId1 ID of the first NFT.
    /// @param tokenId2 ID of the second NFT.
    function battle(uint256 tokenId1, uint256 tokenId2) public validNFT(tokenId1) validNFT(tokenId2) {
         require(_isApprovedOrOwner(_msgSender(), tokenId1) || _isApprovedOrOwner(_msgSender(), tokenId2), "EVO: caller not authorized for either token");
         require(tokenId1 != tokenId2, "EVO: cannot battle self");
         require(checkCanBattle(tokenId1, tokenId2), "EVO: battle prerequisites not met (e.g., energy)");

         uint256 battleCost = 10; // Example cost

         // Update and consume energy for both
         _updateEnergy(tokenId1);
         _updateEnergy(tokenId2);

         uint256 oldEnergy1 = _nftStates[tokenId1].energy;
         uint256 oldEnergy2 = _nftStates[tokenId2].energy;

         _nftStates[tokenId1].energy = _nftStates[tokenId1].energy.sub(battleCost);
         _nftStates[tokenId2].energy = _nftStates[tokenId2].energy.sub(battleCost);

         _nftStates[tokenId1].lastEnergyUpdateTime = uint48(block.timestamp); // Update timestamp after consumption
         _nftStates[tokenId2].lastEnergyUpdateTime = uint48(block.timestamp); // Update timestamp after consumption
         _nftStates[tokenId1].lastActionTime = uint48(block.timestamp);
         _nftStates[tokenId2].lastActionTime = uint48(block.timestamp);


         // Calculate outcome based on stats
         int256 outcome = calculateBattleOutcome(
             _nftStates[tokenId1].strength, _nftStates[tokenId1].agility, _nftStates[tokenId1].intelligence,
             _nftStates[tokenId2].strength, _nftStates[tokenId2].agility, _nftStates[tokenId2].intelligence
         );

         // Apply consequences (example logic)
         uint256 expGainedWinner = 30;
         uint256 expGainedLoser = 10;
         uint256 mutationChanceWinner = 10; // 10% chance
         uint256 mutationChanceLoser = 20; // 20% chance (stress/defeat can cause mutation)

         if (outcome > 0) { // Token 1 wins (or is favored)
             _nftStates[tokenId1].experience = _nftStates[tokenId1].experience.add(expGainedWinner);
             _nftStates[tokenId2].experience = _nftStates[tokenId2].experience.add(expGainedLoser);
             if (_rollDice(mutationChanceWinner)) _attemptMutate(tokenId1);
             if (_rollDice(mutationChanceLoser)) _attemptMutate(tokenId2);
         } else if (outcome < 0) { // Token 2 wins (or is favored)
             _nftStates[tokenId2].experience = _nftStates[tokenId2].experience.add(expGainedWinner);
             _nftStates[tokenId1].experience = _nftStates[tokenId1].experience.add(expGainedLoser);
             if (_rollDice(mutationChanceLoser)) _attemptMutate(tokenId1);
             if (_rollDice(mutationChanceWinner)) _attemptMutate(tokenId2);
         } else { // Draw or unclear outcome
             _nftStates[tokenId1].experience = _nftStates[tokenId1].experience.add(expGainedLoser); // Smaller XP for a draw
             _nftStates[tokenId2].experience = _nftStates[tokenId2].experience.add(expGainedLoser);
             if (_rollDice(5)) _attemptMutate(tokenId1); // Small chance for draw mutation
             if (_rollDice(5)) _attemptMutate(tokenId2); // Small chance for draw mutation
         }

         // Check level ups after gaining exp
         _checkLevelUp(tokenId1);
         _checkLevelUp(tokenId2);

         emit Battled(tokenId1, tokenId2, outcome);
         emit EnergyChanged(tokenId1, oldEnergy1, _nftStates[tokenId1].energy);
         emit EnergyChanged(tokenId2, oldEnergy2, _nftStates[tokenId2].energy);
         emit NFTStateUpdated(tokenId1, _nftStates[tokenId1].level, _nftStates[tokenId1].experience, _nftStates[tokenId1].energy, _nftStates[tokenId1].strength, _nftStates[tokenId1].agility, _nftStates[tokenId1].intelligence, _nftStates[tokenId1].mutationCount);
         emit NFTStateUpdated(tokenId2, _nftStates[tokenId2].level, _nftStates[tokenId2].experience, _nftStates[tokenId2].energy, _nftStates[tokenId2].strength, _nftStates[tokenId2].agility, _nftStates[tokenId2].intelligence, _nftStates[tokenId2].mutationCount);
    }

    /// @notice Attempts to trigger a mutation for an NFT.
    /// Mutation is probabilistic and depends on internal state and potentially external factors.
    /// Requires caller to be owner or approved. Requires enough energy and meets checks.
    /// @param tokenId The ID of the NFT.
    function mutate(uint256 tokenId) public validNFT(tokenId) onlyOwnerOrApproved(tokenId) enoughEnergy(tokenId, 50) { // Example cost: 50 energy
         // _updateEnergy called by modifier

         if (!checkCanMutate(tokenId)) { // Re-check complex conditions if any
             revert("EVO: mutation prerequisites not met (e.g., level)");
         }

         NFTState storage nft = _nftStates[tokenId];
         uint256 oldEnergy = nft.energy;
         uint256 energyCost = 50;
         nft.energy = nft.energy.sub(energyCost);
         nft.lastEnergyUpdateTime = uint48(block.timestamp); // Update timestamp after consumption
         nft.lastActionTime = uint48(block.timestamp);

         // --- Mutation Logic ---
         // Simple Example: Randomly boost one stat or attempt species evolution

         uint256 mutationRoll = _rollDiceResult(100); // Roll 0-99
         uint256 mutationType = 0; // 0: stat boost, 1: species evolution attempt

         if (mutationRoll < 70) { // 70% chance for stat boost
             mutationType = 0;
             uint256 statRoll = _rollDiceResult(3); // 0: str, 1: agi, 2: int
             uint256 boostAmount = nft.level.div(4).add(1); // Boost scales roughly with level

             if (statRoll == 0) {
                  uint256 oldValue = nft.strength;
                  nft.strength = nft.strength.add(boostAmount);
                  emit TraitChanged(tokenId, "strength", oldValue, nft.strength);
                  emit Mutated(tokenId, mutationType, string(abi.encodePacked("Strength boosted by ", boostAmount.toString())));
             } else if (statRoll == 1) {
                  uint256 oldValue = nft.agility;
                  nft.agility = nft.agility.add(boostAmount);
                   emit TraitChanged(tokenId, "agility", oldValue, nft.agility);
                  emit Mutated(tokenId, mutationType, string(abi.encodePacked("Agility boosted by ", boostAmount.toString())));
             } else {
                  uint256 oldValue = nft.intelligence;
                  nft.intelligence = nft.intelligence.add(boostAmount);
                   emit TraitChanged(tokenId, "intelligence", oldValue, nft.intelligence);
                  emit Mutated(tokenId, mutationType, string(abi.encodePacked("Intelligence boosted by ", boostAmount.toString())));
             }

         } else { // 30% chance for species evolution attempt
             mutationType = 1;
             // This just signals the *possibility* of evolution, actual evolution needs the separate evolveSpecies call with conditions
             emit Mutated(tokenId, mutationType, "Attempting species evolution...");
         }

         nft.mutationCount = nft.mutationCount.add(1);
         emit EnergyChanged(tokenId, oldEnergy, nft.energy);
         emit NFTStateUpdated(tokenId, nft.level, nft.experience, nft.energy, nft.strength, nft.agility, nft.intelligence, nft.mutationCount);
    }

    /// @notice Attempts to evolve an NFT to a new species.
    /// Requires specific conditions to be met (e.g., high level, successful mutations).
    /// Requires caller to be owner or approved. Requires enough energy.
    /// @param tokenId The ID of the NFT.
    /// @param newSpeciesId The target species ID.
    function evolveSpecies(uint256 tokenId, uint256 newSpeciesId) public validNFT(tokenId) onlyOwnerOrApproved(tokenId) enoughEnergy(tokenId, 100) { // Example cost: 100 energy
         // _updateEnergy called by modifier

         NFTState storage nft = _nftStates[tokenId];

         require(nft.speciesId != newSpeciesId, "EVO: already this species");
         require(_speciesMaxEnergy[newSpeciesId] > 0, "EVO: invalid new species ID or species not configured");

         // Example Evolution Conditions: Level 10+ and at least 3 mutations
         require(nft.level >= 10, "EVO: level too low for evolution (Need 10+)");
         require(nft.mutationCount >= 3, "EVO: not enough mutations for evolution (Need 3+)");
         // Could add: specific items, time elapsed since last evolution, etc.

         uint256 oldEnergy = nft.energy;
         uint256 energyCost = 100;
         nft.energy = nft.energy.sub(energyCost);
         nft.lastEnergyUpdateTime = uint48(block.timestamp); // Update timestamp after consumption
         nft.lastActionTime = uint48(block.timestamp);

         uint256 oldSpeciesId = nft.speciesId;
         nft.speciesId = newSpeciesId;

         // Adjust stats based on new species base stats + current stats
         // Example: Add a percentage of the *new* base stats
         uint256 newBaseStr = _speciesBaseStrength[newSpeciesId];
         uint256 newBaseAgi = _speciesBaseAgility[newSpeciesId];
         uint256 newBaseInt = _speciesBaseIntelligence[newSpeciesId];

         // Add 50% of new base stat to current stat
         uint256 oldStr = nft.strength; uint256 oldAgi = nft.agility; uint256 oldInt = nft.intelligence;
         nft.strength = nft.strength.add(newBaseStr.div(2));
         nft.agility = nft.agility.add(newBaseAgi.div(2));
         nft.intelligence = nft.intelligence.add(newBaseInt.div(2));

         // Update max energy and regen rate to the new species' values.
         // The next call to _updateEnergy will cap/regen based on new values.
         // No direct change needed here, as mappings are read dynamically.


         emit SpeciesEvolved(tokenId, oldSpeciesId, newSpeciesId);
         emit TraitChanged(tokenId, "strength", oldStr, nft.strength);
         emit TraitChanged(tokenId, "agility", oldAgi, nft.agility);
         emit TraitChanged(tokenId, "intelligence", oldInt, nft.intelligence);
         emit EnergyChanged(tokenId, oldEnergy, nft.energy);
         emit NFTStateUpdated(tokenId, nft.level, nft.experience, nft.energy, nft.strength, nft.agility, nft.intelligence, nft.mutationCount);
    }


    // --- Internal/Pure Helper Functions ---

    /// @notice Internal function to calculate current energy based on regen and cap.
    /// Does *not* update the state variable, only calculates the theoretical value.
    /// Use _updateEnergy to apply this calculation to state.
    /// @param currentEnergy The current stored energy value.
    /// @param lastUpdate The timestamp of the last energy update.
    /// @return The calculated current energy.
    function _calculateCurrentEnergy(uint256 tokenId, uint256 currentEnergy, uint48 lastUpdate) internal view returns (uint256) {
        uint256 speciesId = _nftStates[tokenId].speciesId; // Need species for max energy and regen rate
        uint256 maxEnergy = _speciesMaxEnergy[speciesId];
        uint256 regenRate = _speciesEnergyRegenRate[speciesId];

        if (currentEnergy >= maxEnergy) {
            return maxEnergy;
        }
        if (regenRate == 0) {
            return currentEnergy; // No regen
        }

        uint256 elapsedTime = block.timestamp - lastUpdate;
        uint256 energyGained = elapsedTime.mul(regenRate);

        return (currentEnergy.add(energyGained)).min(maxEnergy);
    }

    /// @notice Internal function to calculate and update the energy state variable.
    /// Should be called by any function that needs the current energy state before using/modifying it.
    /// @param tokenId The ID of the NFT.
    function _updateEnergy(uint256 tokenId) internal {
        NFTState storage nft = _nftStates[tokenId];
        uint256 oldEnergy = nft.energy;
        uint256 currentEnergy = _calculateCurrentEnergy(tokenId, nft.energy, nft.lastEnergyUpdateTime);
        nft.energy = currentEnergy;
        nft.lastEnergyUpdateTime = uint48(block.timestamp);
        // Note: This internal helper doesn't emit EnergyChanged event. Callers should emit if needed.
    }


    /// @notice Internal function to check if an NFT levels up and updates its state.
    /// Should be called after gaining experience.
    /// @param tokenId The ID of the NFT.
    function _checkLevelUp(uint256 tokenId) internal {
        NFTState storage nft = _nftStates[tokenId];
        uint256 currentLevel = nft.level;
        uint256 currentXP = nft.experience;

        uint256 newLevel = currentLevel;

        // Iterate through thresholds starting from the next level requirement
        // thresholds[0] is for level 2, thresholds[1] for level 3, etc.
        // The loop checks if current XP meets the threshold for level (i+2)
        for (uint256 i = currentLevel; i < _levelUpExperienceThresholds.length; ++i) {
            if (currentXP >= _levelUpExperienceThresholds[i]) {
                 newLevel = i.add(2); // If XP >= threshold[i], they reached level i+2
            } else {
                break; // XP is not enough for this level threshold, so stop checking higher levels
            }
        }

        if (newLevel > currentLevel) {
            nft.level = newLevel;
            // Optional: Boost stats on level up
            uint256 oldStr = nft.strength; uint256 oldAgi = nft.agility; uint256 oldInt = nft.intelligence;
            nft.strength = nft.strength.add(newLevel.sub(currentLevel)); // Boost by difference in levels
            nft.agility = nft.agility.add(newLevel.sub(currentLevel));
            nft.intelligence = nft.intelligence.add(newLevel.sub(currentLevel));

             emit LeveledUp(tokenId, currentLevel, newLevel);
             emit TraitChanged(tokenId, "strength", oldStr, nft.strength);
             emit TraitChanged(tokenId, "agility", oldAgi, nft.agility);
             emit TraitChanged(tokenId, "intelligence", oldInt, nft.intelligence);
             // StateUpdate event emitted by the calling action function
        }
    }

    /// @notice Pure function to calculate battle outcome based on stats.
    /// Example simplified logic. Can be called externally as a view.
    /// @param strength1, agility1, intelligence1 Stats for NFT 1.
    /// @param strength2, agility2, intelligence2 Stats for NFT 2.
    /// @return An integer representing the outcome delta. Positive favors NFT 1, negative favors NFT 2.
    function calculateBattleOutcome(
        uint256 strength1, uint256 agility1, uint256 intelligence1,
        uint256 strength2, uint256 agility2, uint256 intelligence2
    ) public pure returns (int256) {
        // Basic example formula: (Str1 + Agi1 + Int1) - (Str2 + Agi2 + Int2)
        // Could be much more complex: type advantages, crit chance based on agility, spell power from intelligence, etc.
        int256 score1 = int256(strength1) + int256(agility1) + int256(intelligence1);
        int256 score2 = int256(strength2) + int256(agility2) + int256(intelligence2);

        return score1 - score2;
    }

    /// @notice Internal function to attempt a mutation after battle or triggered action.
    /// Different from the public `mutate` which has energy cost and checks.
    /// This is called *after* energy/checks are handled in actions like `battle`.
    /// @param tokenId The ID of the NFT.
    function _attemptMutate(uint256 tokenId) internal {
         // Simplified logic for secondary mutation: 50/50 chance for a minor stat boost on *any* stat
         uint256 chance = 50; // 50% chance to mutate
         if (_rollDice(chance)) {
             NFTState storage nft = _nftStates[tokenId];
             uint256 statRoll = _rollDiceResult(3); // 0: str, 1: agi, 2: int
             uint256 boostAmount = 1; // Minor boost

             if (statRoll == 0) {
                  uint256 oldValue = nft.strength;
                  nft.strength = nft.strength.add(boostAmount);
                  emit TraitChanged(tokenId, "strength", oldValue, nft.strength);
                  emit Mutated(tokenId, 2, string(abi.encodePacked("Auto/Battle Mutation: Strength boosted by ", boostAmount.toString()))); // Type 2 for auto/battle mutations
             } else if (statRoll == 1) {
                  uint256 oldValue = nft.agility;
                  nft.agility = nft.agility.add(boostAmount);
                   emit TraitChanged(tokenId, "agility", oldValue, nft.agility);
                  emit Mutated(tokenId, 2, string(abi.encodePacked("Auto/Battle Mutation: Agility boosted by ", boostAmount.toString())));
             } else {
                  uint256 oldValue = nft.intelligence;
                  nft.intelligence = nft.intelligence.add(boostAmount);
                   emit TraitChanged(tokenId, "intelligence", oldValue, nft.intelligence);
                  emit Mutated(tokenId, 2, string(abi.encodePacked("Auto/Battle Mutation: Intelligence boosted by ", boostAmount.toString())));
             }
            nft.mutationCount = nft.mutationCount.add(1);
            // NFTStateUpdated event emitted by the calling action function
         }
    }

    /// @notice Internal simple PRNG roll. NOT cryptographically secure. Use only for low-value outcomes.
    /// Relies on block variables which can be influenced by miners/validators.
    /// @param chance The percentage chance (0-100) to succeed.
    /// @return True if the roll succeeds.
    function _rollDice(uint256 chance) internal view returns (bool) {
        require(chance <= 100, "Chance must be 0-100");
        if (chance == 0) return false;
        if (chance == 100) return true;
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, tx.gasprice, msg.sender, block.number)));
        return (randomSeed % 100) < chance;
    }

     /// @notice Internal simple PRNG roll returning a result within a range. NOT cryptographically secure.
     /// @param range The upper bound (exclusive). Result will be [0, range-1].
     /// @return A random number within the range.
    function _rollDiceResult(uint256 range) internal view returns (uint256) {
        require(range > 0, "Range must be positive");
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, tx.gasprice, msg.sender, block.number, gasleft())));
        return randomSeed % range;
    }
}
```