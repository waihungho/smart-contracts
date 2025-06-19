Okay, here is a Solidity smart contract concept called "CryptoEvolution".

This contract represents a collection of unique, evolving digital creatures (NFTs). Their attributes and visual appearance change over time and based on certain conditions, including staking and on-chain pseudo-randomness. It incorporates concepts like dynamic NFTs, time-based mechanics, staking utility, pseudo-randomness for outcomes, and administrative controls for managing the evolution process.

---

## CryptoEvolution Smart Contract Outline & Function Summary

**Contract Name:** `CryptoEvolution`

**Inherits From:** `ERC721URIStorage`, `Ownable`, `ReentrancyGuard`, `Pausable`

**Core Concept:** A collection of ERC721 NFTs representing creatures that evolve over time and based on interactions like staking and random events.

**State Variables:**
*   `CreatureData`: Struct holding creature attributes, stage, last evolution time, staking info, temporary buffs, etc.
*   `EvolutionParameters`: Struct holding thresholds, costs, and multipliers for evolution.
*   Mappings to store `CreatureData`, staking info, temporary boosts by token ID.
*   Admin-controlled parameters (evolution costs, base attributes, max supply).
*   Counters for token IDs and staged creature counts.
*   Base URI for dynamic metadata.
*   Last used random seed.

**Events:**
*   `CreatureMinted`: Log when a new creature is minted.
*   `EvolutionRequested`: Log when an evolution process is initiated for a creature.
*   `CreatureEvolved`: Log when a creature successfully evolves, showing attribute/stage changes.
*   `CreatureStaked`: Log when a creature is staked.
*   `CreatureUnstaked`: Log when a creature is unstaked.
*   `CreatureBurned`: Log when a creature is burned/sacrificed.
*   `AttributesChanged`: Log when a creature's attributes are updated.
*   `StageChanged`: Log when a creature changes evolution stage.
*   `TemporaryBoostGranted`: Log when a temporary boost is applied.
*   `ParametersUpdated`: Log when admin parameters are changed.

**Modifiers:**
*   `onlyOwner`: Restricts access to the contract owner.
*   `whenNotPaused`: Prevents execution when the contract is paused.
*   `whenPaused`: Allows execution only when the contract is paused.
*   `onlyCreatureOwner`: Restricts access to the owner of a specific creature.
*   `notStaked`: Prevents execution for staked creatures.

**Functions (>= 20 Functions):**

**ERC721 Standard Functions (Inherited/Overridden - ~11 functions):**
1.  `balanceOf(address owner)`: Get number of tokens owned by an address.
2.  `ownerOf(uint256 tokenId)`: Get owner of a specific token.
3.  `approve(address to, uint256 tokenId)`: Grant approval to transfer a token.
4.  `getApproved(uint256 tokenId)`: Get approved address for a token.
5.  `setApprovalForAll(address operator, bool approved)`: Set approval for an operator for all tokens.
6.  `isApprovedForAll(address owner, address operator)`: Check if an operator is approved for all tokens of an owner.
7.  `transferFrom(address from, address to, uint256 tokenId)`: Transfer token (standard).
8.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer token (standard).
9.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Safe transfer token (with data).
10. `tokenURI(uint256 tokenId)`: Get metadata URI for a token (points to dynamic service).
11. `supportsInterface(bytes4 interfaceId)`: Check if contract supports an interface.

**Custom Core Mechanics Functions:**
12. `constructor()`: Initializes the contract, sets owner, base parameters.
13. `mintCreature(address recipient)`: Mints a new creature NFT to a recipient, initializes its base attributes and stage. Requires Ether payment.
14. `requestEvolution(uint256 tokenId)`: Allows the owner to request evolution for their creature. Checks conditions (time elapsed, cost, not staked), consumes cost, triggers internal evolution process.
15. `canEvolve(uint256 tokenId)`: View function to check if a creature meets the basic requirements (time elapsed, not staked) to attempt evolution.
16. `stakeCreature(uint256 tokenId)`: Allows the owner to stake their creature. Updates internal state, prevents transfer.
17. `unstakeCreature(uint256 tokenId)`: Allows the owner to unstake their creature. Records staking duration.
18. `getStakingDuration(uint256 tokenId)`: View function to get the duration a creature has been staked (or was staked if unstaked).
19. `burnCreature(uint256 tokenId)`: Allows the owner to "sacrifice" their creature (burn the NFT) possibly for a small reward or benefit.

**View/Query Functions:**
20. `getCreatureData(uint256 tokenId)`: View function to retrieve all stored data for a specific creature.
21. `getEvolutionCost()`: View function to retrieve the current cost to request evolution.
22. `getStakingInfo(uint256 tokenId)`: View function returning staking status and start/end times for a creature.
23. `getCreatureCountByStage(uint8 stage)`: View function to get the number of creatures currently in a specific evolution stage.
24. `getLastRandomSeed()`: View function returning the last block hash used for randomness.

**Admin/Owner Functions:**
25. `setEvolutionParameters(uint256 minTimeBetweenEvolution, uint256 etherCost)`: Allows owner to set core evolution parameters.
26. `setBaseAttributes(uint8 strength, uint8 intelligence, uint8 dexterity, uint8 initialStage)`: Allows owner to set initial attributes and stage for *newly minted* creatures.
27. `adminSetCreatureAttributes(uint256 tokenId, uint8 strength, uint8 intelligence, uint8 dexterity, uint8 stage)`: Allows owner to *override* attributes and stage for a specific creature (use cautiously, e.g., for bug fixes).
28. `grantTemporaryBoost(uint256 tokenId, uint8 attributeIndex, uint8 boostAmount, uint256 expiryTimestamp)`: Allows owner to grant a temporary boost to a creature's attribute that expires.
29. `removeExpiredBoosts(uint256 tokenId)`: Allows anyone to trigger removal of expired temporary boosts for a creature.
30. `setBaseURI(string memory baseURI_)`: Allows owner to update the base URI for metadata.
31. `pause()`: Pauses sensitive contract functions.
32. `unpause()`: Unpauses the contract.
33. `withdraw()`: Allows owner to withdraw collected Ether (from mints/evolution costs).
34. `setMaxSupply(uint256 maxSupply_)`: Sets the maximum number of creatures that can be minted.

**Internal/Helper Functions:**
*   `_calculateEvolutionOutcome(uint256 tokenId, uint256 randomness)`: Determines the outcome of an evolution attempt based on creature state, staking duration, and randomness. Updates attributes and potentially stage.
*   `_applyEvolutionChanges(uint256 tokenId, uint8 attributeChanges, bool stageUp)`: Applies calculated changes to creature data and emits events.
*   `_generateRandomness(uint256 tokenId)`: Generates a pseudo-random number using block data and token ID.
*   `_beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)`: Override ERC721 hook to prevent transfer of staked tokens.
*   `_afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)`: Override ERC721 hook (potentially for future use like updating owner's token list).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- Outline & Function Summary Above ---

contract CryptoEvolution is ERC721URIStorage, Ownable, ReentrancyGuard, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;

    // --- Structs ---

    enum EvolutionStage { Hatchling, Juvenile, Adult, Elder, Mythic }

    struct CreatureData {
        uint8 strength;
        uint8 intelligence;
        uint8 dexterity;
        EvolutionStage stage;
        uint256 lastEvolutionTime;
        uint256 totalStakingDuration; // Accumulated duration staked
        bool isStaked;
        uint256 stakingStartTime;
        uint256 boostExpiryTime; // Expiry for temporary boost
        uint8 boostedAttribute; // Index: 0=Str, 1=Int, 2=Dex
        uint8 boostAmount;
    }

    struct EvolutionParameters {
        uint256 minTimeBetweenEvolution; // Minimum time (seconds) between evolution attempts
        uint256 etherCost; // Ether cost per evolution attempt
        uint8 baseAttributeIncreaseMin; // Minimum attribute points gained on evolution
        uint8 baseAttributeIncreaseMax; // Maximum attribute points gained on evolution
        uint256 stakingDurationBonusFactor; // Factor to influence attribute gain based on staking duration
        uint256 stageUpChanceBase; // Base chance (out of 1000) for stage up on evolution
        uint256 stakingStageUpBonus; // Bonus chance (out of 1000) for stage up if staked long enough
    }

    // --- State Variables ---

    mapping(uint256 => CreatureData) private _creatures;
    mapping(uint8 => uint256) private _creatureCountByStage; // Count of creatures per stage
    EvolutionParameters private _evolutionParameters;
    uint256 private _maxSupply;
    uint256 private _lastRandomSeed; // Stores a recent block hash for pseudo-randomness

    // --- Events ---

    event CreatureMinted(uint256 indexed tokenId, address indexed owner, uint8 initialStage);
    event EvolutionRequested(uint256 indexed tokenId);
    event CreatureEvolved(uint256 indexed tokenId, uint8 newStrength, uint8 newIntelligence, uint8 newDexterity, EvolutionStage newStage, uint256 randomnessUsed);
    event CreatureStaked(uint256 indexed tokenId, uint256 stakeStartTime);
    event CreatureUnstaked(uint256 indexed tokenId, uint256 unstakeTime, uint256 accumulatedDuration);
    event CreatureBurned(uint256 indexed tokenId, address indexed owner);
    event AttributesChanged(uint256 indexed tokenId, uint8 strength, uint8 intelligence, uint8 dexterity);
    event StageChanged(uint256 indexed tokenId, EvolutionStage oldStage, EvolutionStage newStage);
    event TemporaryBoostGranted(uint256 indexed tokenId, uint8 indexed boostedAttribute, uint8 boostAmount, uint256 expiryTimestamp);
    event TemporaryBoostRemoved(uint256 indexed tokenId, uint8 indexed removedAttribute);
    event ParametersUpdated();

    // --- Constructor ---

    constructor() ERC721("CryptoEvolutionCreature", "CEC") Ownable(msg.sender) {
        // Set initial evolution parameters (example values)
        _evolutionParameters = EvolutionParameters({
            minTimeBetweenEvolution: 1 days, // 1 day
            etherCost: 0.01 ether, // 0.01 ETH
            baseAttributeIncreaseMin: 1,
            baseAttributeIncreaseMax: 3,
            stakingDurationBonusFactor: 10000, // 1 unit staking duration adds 1/10000th of max possible attribute bonus
            stageUpChanceBase: 50, // 5% base chance
            stakingStageUpBonus: 100 // +10% chance if staked long enough (e.g., > 7 days)
        });

        // Set initial base attributes for new creatures (example values)
        _creatures[0] = CreatureData({ // Use token ID 0 as a template for new mints
            strength: 5,
            intelligence: 5,
            dexterity: 5,
            stage: EvolutionStage.Hatchling,
            lastEvolutionTime: 0, // Not applicable for template
            totalStakingDuration: 0,
            isStaked: false,
            stakingStartTime: 0,
            boostExpiryTime: 0,
            boostedAttribute: 255, // Sentinel value
            boostAmount: 0
        });

        _creatureCountByStage[uint8(EvolutionStage.Hatchling)] = 0; // Will be incremented on mint
        _maxSupply = 1000; // Example max supply
    }

    // --- Modifiers ---

    modifier onlyCreatureOwner(uint256 tokenId) {
        require(_exists(tokenId), "CEC: Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "CEC: Not creature owner");
        _;
    }

     modifier notStaked(uint256 tokenId) {
        require(_exists(tokenId), "CEC: Token does not exist");
        require(!_creatures[tokenId].isStaked, "CEC: Creature is staked");
        _;
    }

    // --- ERC721 Standard Functions (Inherited/Overridden) ---

    // Note: balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll,
    // transferFrom, safeTransferFrom (x2), supportsInterface are provided by OpenZeppelin base contracts.

    /// @inheritdoc ERC721URIStorage
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        // The base URI should point to a service that generates JSON metadata dynamically
        // based on the creature's current state retrieved via getCreatureData.
        string memory base = _baseURI();
        // You would append the tokenId and potentially query parameters to this base URI
        // Example: "https://yourapi.com/metadata/" + tokenId.toString()
        // A simple implementation just returns the base URI + tokenId
        return string(abi.encodePacked(base, _toString(tokenId)));
    }

    // --- Custom Core Mechanics Functions ---

    /// @dev Mints a new creature NFT to the recipient.
    /// Requires payment equal to the mint cost.
    /// @param recipient Address to mint the creature to.
    function mintCreature(address recipient) external payable whenNotPaused nonReentrant {
        require(_tokenIdCounter.current() < _maxSupply, "CEC: Max supply reached");
        require(msg.value >= _evolutionParameters.etherCost, "CEC: Insufficient ETH for mint"); // Using evolutionCost as mint cost for simplicity

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        // Initialize creature data based on the template
        _creatures[newTokenId] = CreatureData({
            strength: _creatures[0].strength,
            intelligence: _creatures[0].intelligence,
            dexterity: _creatures[0].dexterity,
            stage: _creatures[0].stage,
            lastEvolutionTime: block.timestamp, // Set initial evolution time to now
            totalStakingDuration: 0,
            isStaked: false,
            stakingStartTime: 0,
            boostExpiryTime: 0,
            boostedAttribute: 255,
            boostAmount: 0
        });

        // Increment stage count for the initial stage
        _creatureCountByStage[uint8(_creatures[newTokenId].stage)]++;

        _safeMint(recipient, newTokenId);

        emit CreatureMinted(newTokenId, recipient, uint8(_creatures[newTokenId].stage));
    }

    /// @dev Allows the creature owner to attempt an evolution.
    /// Requires the configured Ether cost and minimum time since last evolution.
    /// Applies changes based on internal logic and pseudo-randomness.
    /// @param tokenId The ID of the creature to evolve.
    function requestEvolution(uint256 tokenId) external payable onlyCreatureOwner(tokenId) notStaked(tokenId) whenNotPaused nonReentrant {
        CreatureData storage creature = _creatures[tokenId];

        // Check minimum time elapsed since last evolution
        require(block.timestamp >= creature.lastEvolutionTime + _evolutionParameters.minTimeBetweenEvolution, "CEC: Not enough time has passed since last evolution");

        // Check Ether cost
        require(msg.value >= _evolutionParameters.etherCost, "CEC: Insufficient ETH for evolution");

        // Update last evolution time
        creature.lastEvolutionTime = block.timestamp;

        // Generate pseudo-randomness
        uint256 randomness = _generateRandomness(tokenId);
        _lastRandomSeed = randomness; // Store for viewing

        // Calculate and apply evolution outcome
        _calculateEvolutionOutcome(tokenId, randomness);

        emit EvolutionRequested(tokenId);
    }

    /// @dev Checks if a creature is eligible for evolution based on time elapsed and staking status.
    /// Does not check for Ether cost.
    /// @param tokenId The ID of the creature to check.
    /// @return True if the creature can attempt evolution, false otherwise.
    function canEvolve(uint256 tokenId) public view returns (bool) {
        if (!_exists(tokenId)) {
            return false;
        }
        const CreatureData storage creature = _creatures[tokenId];
        // Basic checks: time elapsed and not staked
        return block.timestamp >= creature.lastEvolutionTime + _evolutionParameters.minTimeBetweenEvolution && !creature.isStaked;
    }

    /// @dev Stakes a creature, preventing transfers and starting staking duration tracking.
    /// Only the owner can stake.
    /// @param tokenId The ID of the creature to stake.
    function stakeCreature(uint256 tokenId) external onlyCreatureOwner(tokenId) notStaked(tokenId) whenNotPaused {
        CreatureData storage creature = _creatures[tokenId];
        creature.isStaked = true;
        creature.stakingStartTime = block.timestamp;
        emit CreatureStaked(tokenId, block.timestamp);
    }

    /// @dev Unstakes a creature, allowing transfers and adding staking duration to total.
    /// Only the owner can unstake.
    /// @param tokenId The ID of the creature to unstake.
    function unstakeCreature(uint256 tokenId) external onlyCreatureOwner(tokenId) whenNotPaused {
        CreatureData storage creature = _creatures[tokenId];
        require(creature.isStaked, "CEC: Creature is not staked");

        uint256 currentStakingDuration = block.timestamp.sub(creature.stakingStartTime);
        creature.totalStakingDuration = creature.totalStakingDuration.add(currentStakingDuration);
        creature.isStaked = false;
        creature.stakingStartTime = 0; // Reset staking start time

        emit CreatureUnstaked(tokenId, block.timestamp, creature.totalStakingDuration);
    }

    /// @dev Gets the current staking duration for a creature (if staked) or the last recorded duration.
    /// @param tokenId The ID of the creature.
    /// @return The current/last staking duration in seconds.
    function getStakingDuration(uint256 tokenId) public view returns (uint256) {
         if (!_exists(tokenId)) {
            return 0; // Or handle error appropriately
        }
        const CreatureData storage creature = _creatures[tokenId];
        if (creature.isStaked) {
            return block.timestamp.sub(creature.stakingStartTime);
        } else {
            return creature.totalStakingDuration; // Return last accumulated duration if not currently staked
        }
    }

    /// @dev Allows the owner to burn (sacrifice) their creature.
    /// The token is transferred to the zero address. Can include rewards/benefits.
    /// @param tokenId The ID of the creature to burn.
    function burnCreature(uint256 tokenId) external onlyCreatureOwner(tokenId) whenNotPaused nonReentrant {
         // Prevent burning if staked (requires unstaking first)
         require(!_creatures[tokenId].isStaked, "CEC: Cannot burn staked creature");

        address owner = ownerOf(tokenId);
        _burn(tokenId); // ERC721 burn function

        // Decrement stage count
        _creatureCountByStage[uint8(_creatures[tokenId].stage)]--;

        delete _creatures[tokenId]; // Remove creature data

        // Optional: Implement reward logic here (e.g., send a small amount of ETH or a different token)
        // This would require the contract to hold ETH or the token.
        // For this example, no reward is given.

        emit CreatureBurned(tokenId, owner);
    }

    // --- View/Query Functions ---

    /// @dev Gets the full data structure for a specific creature.
    /// @param tokenId The ID of the creature.
    /// @return CreatureData struct containing all attributes and state.
    function getCreatureData(uint256 tokenId) public view returns (CreatureData memory) {
        require(_exists(tokenId), "CEC: Token does not exist");
        CreatureData memory creature = _creatures[tokenId];

        // Adjust attributes based on active temporary boost
        if (creature.boostExpiryTime > block.timestamp) {
            if (creature.boostedAttribute == 0) creature.strength = creature.strength.add(creature.boostAmount);
            else if (creature.boostedAttribute == 1) creature.intelligence = creature.intelligence.add(creature.boostAmount);
            else if (creature.boostedAttribute == 2) creature.dexterity = creature.dexterity.add(creature.boostAmount);
        }
        // Note: totalStakingDuration is accumulated only on unstake. getStakingDuration gives *current* staked time.
        // For display purposes, you might combine totalStakingDuration + current staked time.

        return creature;
    }

    /// @dev Gets the current Ether cost required to request an evolution attempt.
    /// @return The evolution cost in wei.
    function getEvolutionCost() public view returns (uint256) {
        return _evolutionParameters.etherCost;
    }

    /// @dev Gets the staking status and relevant times for a creature.
    /// @param tokenId The ID of the creature.
    /// @return isStaked, stakingStartTime, totalStakingDuration (including current if staked).
    function getStakingInfo(uint256 tokenId) public view returns (bool isStaked, uint256 stakingStartTime, uint256 currentOrTotalStakingDuration) {
        if (!_exists(tokenId)) {
             return (false, 0, 0);
        }
        const CreatureData storage creature = _creatures[tokenId];
        isStaked = creature.isStaked;
        stakingStartTime = creature.stakingStartTime;
        if (isStaked) {
            currentOrTotalStakingDuration = creature.totalStakingDuration.add(block.timestamp.sub(creature.stakingStartTime));
        } else {
             currentOrTotalStakingDuration = creature.totalStakingDuration;
        }
        return (isStaked, stakingStartTime, currentOrTotalStakingDuration);
    }

     /// @dev Gets the number of creatures currently in a specific evolution stage.
     /// @param stage The evolution stage (0=Hatchling, 1=Juvenile, etc.).
     /// @return The count of creatures in that stage.
    function getCreatureCountByStage(uint8 stage) public view returns (uint256) {
        require(stage < uint8(EvolutionStage.Mythic) + 1, "CEC: Invalid stage");
        return _creatureCountByStage[stage];
    }

    /// @dev Gets the last block hash used for pseudo-randomness in evolution.
    /// This is useful for verification (though block hashes are somewhat predictable).
    /// @return The last random seed (block hash).
    function getLastRandomSeed() public view returns (uint256) {
        return _lastRandomSeed;
    }

    // --- Admin/Owner Functions ---

    /// @dev Allows the owner to update the parameters governing evolution.
    /// @param minTimeBetweenEvolution_ Minimum time (seconds).
    /// @param etherCost_ Ether cost per attempt.
    /// @param baseAttributeIncreaseMin_ Min attribute points gained.
    /// @param baseAttributeIncreaseMax_ Max attribute points gained.
    /// @param stakingDurationBonusFactor_ Factor for staking influence on attributes.
    /// @param stageUpChanceBase_ Base chance for stage up (out of 1000).
    /// @param stakingStageUpBonus_ Bonus chance for stage up from staking (out of 1000).
    function setEvolutionParameters(
        uint256 minTimeBetweenEvolution_,
        uint256 etherCost_,
        uint8 baseAttributeIncreaseMin_,
        uint8 baseAttributeIncreaseMax_,
        uint256 stakingDurationBonusFactor_,
        uint256 stageUpChanceBase_,
        uint256 stakingStageUpBonus_
    ) external onlyOwner {
        require(baseAttributeIncreaseMin_ <= baseAttributeIncreaseMax_, "CEC: Min increase cannot be greater than max");
        require(stageUpChanceBase_ <= 1000 && stakingStageUpBonus_ <= 1000, "CEC: Chance values out of 1000 range");

        _evolutionParameters = EvolutionParameters({
            minTimeBetweenEvolution: minTimeBetweenEvolution_,
            etherCost: etherCost_,
            baseAttributeIncreaseMin: baseAttributeIncreaseMin_,
            baseAttributeIncreaseMax: baseAttributeIncreaseMax_,
            stakingDurationBonusFactor: stakingDurationBonusFactor_,
            stageUpChanceBase: stageUpChanceBase_,
            stakingStageUpBonus: stakingStageUpBonus_
        });
        emit ParametersUpdated();
    }

    /// @dev Allows the owner to set the base attributes and initial stage for *newly minted* creatures.
    /// Does not affect existing creatures.
    /// @param strength_ Base strength.
    /// @param intelligence_ Base intelligence.
    /// @param dexterity_ Base dexterity.
    /// @param initialStage_ Initial evolution stage (e.g., 0 for Hatchling).
    function setBaseAttributes(uint8 strength_, uint8 intelligence_, uint8 dexterity_, uint8 initialStage_) external onlyOwner {
        require(initialStage_ <= uint8(EvolutionStage.Mythic), "CEC: Invalid initial stage");
         _creatures[0].strength = strength_; // Update template
         _creatures[0].intelligence = intelligence_;
         _creatures[0].dexterity = dexterity_;
         _creatures[0].stage = EvolutionStage(initialStage_);
         // Note: This only affects future mints.
         emit ParametersUpdated(); // Or a specific event like BaseAttributesUpdated
    }

    /// @dev Allows the owner to manually set attributes and stage for an existing creature.
    /// Use cautiously, mainly for correcting errors or special cases.
    /// @param tokenId The ID of the creature to modify.
    /// @param strength_ New strength value.
    /// @param intelligence_ New intelligence value.
    /// @param dexterity_ New dexterity value.
    /// @param stage_ New evolution stage (e.g., 0 for Hatchling).
    function adminSetCreatureAttributes(uint256 tokenId, uint8 strength_, uint8 intelligence_, uint8 dexterity_, uint8 stage_) external onlyOwner {
         require(_exists(tokenId), "CEC: Token does not exist");
         require(stage_ <= uint8(EvolutionStage.Mythic), "CEC: Invalid stage");

         CreatureData storage creature = _creatures[tokenId];
         EvolutionStage oldStage = creature.stage;

         creature.strength = strength_;
         creature.intelligence = intelligence_;
         creature.dexterity = dexterity_;

         if (creature.stage != EvolutionStage(stage_)) {
             _creatureCountByStage[uint8(oldStage)]--;
             creature.stage = EvolutionStage(stage_);
             _creatureCountByStage[uint8(creature.stage)]++;
             emit StageChanged(tokenId, oldStage, creature.stage);
         }

         emit AttributesChanged(tokenId, creature.strength, creature.intelligence, creature.dexterity);
    }

    /// @dev Allows the owner to grant a temporary boost to a creature's attribute.
    /// Useful for rewards or events. Boost expires after a timestamp.
    /// @param tokenId The ID of the creature to boost.
    /// @param attributeIndex Index of the attribute to boost (0=Str, 1=Int, 2=Dex).
    /// @param boostAmount The amount to add to the attribute while the boost is active.
    /// @param expiryTimestamp Timestamp when the boost expires.
    function grantTemporaryBoost(uint256 tokenId, uint8 attributeIndex, uint8 boostAmount, uint256 expiryTimestamp) external onlyOwner {
        require(_exists(tokenId), "CEC: Token does not exist");
        require(attributeIndex < 3, "CEC: Invalid attribute index");
        require(expiryTimestamp > block.timestamp, "CEC: Expiry must be in the future");

        CreatureData storage creature = _creatures[tokenId];
        creature.boostedAttribute = attributeIndex;
        creature.boostAmount = boostAmount;
        creature.boostExpiryTime = expiryTimestamp;

        emit TemporaryBoostGranted(tokenId, attributeIndex, boostAmount, expiryTimestamp);
    }

     /// @dev Allows anyone to call and remove expired temporary boosts for a creature.
     /// This is a maintenance function that can be called by anyone to update the state.
     /// @param tokenId The ID of the creature to check for boosts.
    function removeExpiredBoosts(uint256 tokenId) external {
         if (!_exists(tokenId)) {
            return; // Do nothing if token doesn't exist
        }

        CreatureData storage creature = _creatures[tokenId];
        if (creature.boostExpiryTime <= block.timestamp && creature.boostedAttribute != 255) {
            uint8 removedAttributeIndex = creature.boostedAttribute;
            creature.boostedAttribute = 255; // Reset to sentinel
            creature.boostAmount = 0;
            creature.boostExpiryTime = 0;
            emit TemporaryBoostRemoved(tokenId, removedAttributeIndex);
        }
    }


    /// @dev Allows the owner to update the base URI for the token metadata.
    /// @param baseURI_ The new base URI string.
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _setBaseURI(baseURI_);
        emit ParametersUpdated(); // Or a specific event
    }

    /// @dev Pauses contract operations that involve state changes (minting, evolution, staking, burning).
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @dev Unpauses contract operations.
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /// @dev Allows the owner to withdraw accumulated Ether from mints and evolution costs.
    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "CEC: No Ether to withdraw");
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "CEC: ETH withdrawal failed");
    }

     /// @dev Allows the owner to set the maximum number of creatures that can ever be minted.
     /// Cannot set below the current total supply.
     /// @param maxSupply_ The new maximum supply.
    function setMaxSupply(uint256 maxSupply_) external onlyOwner {
        require(maxSupply_ >= _tokenIdCounter.current(), "CEC: Max supply cannot be less than current supply");
        _maxSupply = maxSupply_;
        emit ParametersUpdated(); // Or a specific event
    }


    // --- Internal/Helper Functions ---

    /// @dev Internal function to determine and apply evolution outcome.
    /// Modifies creature attributes and stage based on pseudo-randomness and staking duration.
    /// @param tokenId The ID of the creature evolving.
    /// @param randomness Pseudo-random value generated.
    function _calculateEvolutionOutcome(uint256 tokenId, uint256 randomness) internal {
        CreatureData storage creature = _creatures[tokenId];

        // Simple pseudo-random attribute increase
        uint8 attributeIncrease = uint8(randomness % (_evolutionParameters.baseAttributeIncreaseMax - _evolutionParameters.baseAttributeIncreaseMin + 1)) + _evolutionParameters.baseAttributeIncreaseMin;

        // Influence attribute increase by total staking duration
        // Example: 1 day staked (86400s) * stakingDurationBonusFactor (10000) -> add 8 to randomness influencer
        uint256 stakingBonusInfluence = creature.totalStakingDuration.mul(_evolutionParameters.stakingDurationBonusFactor) / 1e18; // Scale factor

        uint8 totalIncrease = attributeIncrease.add(uint8(randomness.add(stakingBonusInfluence) % _evolutionParameters.baseAttributeIncreaseMax));
        if (totalIncrease < attributeIncrease) totalIncrease = attributeIncrease; // Ensure at least base increase

        // Distribute increase randomly among attributes (simplified)
        uint256 distributionRandom = randomness / 100; // Use a different part of the randomness
        uint8 strIncrease = uint8(distributionRandom % (totalIncrease + 1));
        uint8 intIncrease = uint8((distributionRandom / 100) % (totalIncrease - strIncrease + 1));
        uint8 dexIncrease = totalIncrease.sub(strIncrease).sub(intIncrease); // Remaining points


        creature.strength = creature.strength.add(strIncrease);
        creature.intelligence = creature.intelligence.add(intIncrease);
        creature.dexterity = creature.dexterity.add(dexIncrease);

        emit AttributesChanged(tokenId, creature.strength, creature.intelligence, creature.dexterity);

        // Stage Up Logic
        bool stageUpOccurred = false;
        if (uint8(creature.stage) < uint8(EvolutionStage.Mythic)) {
             uint256 stageUpRoll = randomness % 1000; // Roll a number out of 1000
             uint256 stageUpThreshold = _evolutionParameters.stageUpChanceBase;

             // Add bonus chance based on accumulated staking duration (example: 7 days = 604800 seconds for bonus)
             if (creature.totalStakingDuration >= 7 days) { // Example threshold
                 stageUpThreshold = stageUpThreshold.add(_evolutionParameters.stakingStageUpBonus);
             }

             if (stageUpRoll < stageUpThreshold) {
                 _creatureCountByStage[uint8(creature.stage)]--; // Decrement old stage count
                 creature.stage = EvolutionStage(uint8(creature.stage) + 1); // Increment stage
                 _creatureCountByStage[uint8(creature.stage)]++; // Increment new stage count
                 stageUpOccurred = true;
                 emit StageChanged(tokenId, EvolutionStage(uint8(creature.stage) - 1), creature.stage);
             }
        }

        emit CreatureEvolved(tokenId, creature.strength, creature.intelligence, creature.dexterity, creature.stage, randomness);

         // After evolution, reset total staking duration (or use it up?) - let's reset for this logic
        creature.totalStakingDuration = 0;
    }

    /// @dev Internal function to generate a pseudo-random number.
    /// NOTE: Block hashes are NOT cryptographically secure random sources on-chain
    /// as miners can influence them to some degree. Use Chainlink VRF or similar
    /// for production-grade randomness. This is for demonstration purposes.
    /// @param tokenId The ID of the creature (used as a salt).
    /// @return A pseudo-random uint256 value.
    function _generateRandomness(uint256 tokenId) internal view returns (uint256) {
        // Combine block data and token ID for a simple seed
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number, blockhash(block.number - 1), tokenId)));
    }

    /// @dev Overrides ERC721's hook to prevent transferring staked creatures.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Prevent transfer of staked tokens, unless transferring to/from address(0) (mint/burn)
        if (from != address(0) && to != address(0)) {
            require(!_creatures[tokenId].isStaked, "CEC: Staked creatures cannot be transferred");
        }
    }

    // --- ERC165 Support ---

    /// @inheritdoc ERC721
    function supportsInterface(bytes4 interfaceId) public view override(ERC721URIStorage, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // --- Helper to convert uint to string (for tokenURI if not dynamic) ---
    // (ERC721URIStorage already uses this internally, keeping for reference if needed elsewhere)
    function _toString(uint256 value) internal pure returns (string memory) {
        // Equivalent to OpenZeppelin's Strings.toString
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
        uint256 index = digits;
        temp = value;
        while (temp != 0) {
            index--;
            buffer[index] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}
```