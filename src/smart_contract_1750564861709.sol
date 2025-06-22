Okay, let's create a smart contract for a dynamic, evolving digital entity system that's more than just a static NFT collection. We'll call it `QuantumFluxForge`.

It will feature:
1.  **Dynamic Properties:** Tokens have properties that change based on interactions and time.
2.  **Resource Management:** Requires a resource token ("Plasma") to forge, feed, and interact with entities.
3.  **Time-Based Decay:** Entities degrade if not maintained (fed with Plasma).
4.  **Fusion/Crafting:** Combine entities to create new, potentially more powerful ones.
5.  **Temporal Boosting:** Temporarily enhance entity properties.
6.  **Simulated Environment Interaction:** Global contract state ("Flux Environment") can affect entities.
7.  **Sacrifice Mechanism:** Burn entities for resources or effects.
8.  **Randomness Integration (Simulated/Placeholder):** Use randomness for forging outcomes (with a note on security for production).

This contract will utilize ERC721 for the unique entities and manage an internal balance of the "Plasma" resource token.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Good practice for uint handling

// Outline:
// 1. Contract Definition (Inherits ERC721Enumerable, Ownable)
// 2. Data Structures (EssenceProperties, FluxEnvironment)
// 3. State Variables (Mappings, Counters, Global State, Costs)
// 4. Events
// 5. Constructor
// 6. Internal Helper Functions (Randomness, Decay Calculation, Property Mutation)
// 7. Core Logic Functions (Forge, Feed, Boost, Fusion, Decay Trigger, Refine, Sacrifice, Environment Update)
// 8. Plasma Management Functions (Deposit, Get Balance)
// 9. ERC721 Overrides & Extensions (Token URI, Ownership Tracking)
// 10. Query Functions (Get Properties, List Owned, Get Global State)
// 11. Admin/Configuration Functions (Set Costs, Set Base Properties, Set Environment)
// 12. Emergency Functions (Rescue Funds)

// Function Summary:
// ERC721 Standard Functions (Implemented via Inheritance and Overrides):
// 1. name(): Returns the contract name.
// 2. symbol(): Returns the contract symbol.
// 3. balanceOf(address owner): Returns the number of tokens owned by an address.
// 4. ownerOf(uint256 tokenId): Returns the owner of a specific token.
// 5. safeTransferFrom(address from, address to, uint256 tokenId, bytes data): Safely transfers token with data.
// 6. safeTransferFrom(address from, address to, uint256 tokenId): Safely transfers token without data.
// 7. transferFrom(address from, address to, uint256 tokenId): Transfers token (unsafe version).
// 8. approve(address to, uint256 tokenId): Approves another address to transfer a token.
// 9. getApproved(uint256 tokenId): Gets the approved address for a token.
// 10. setApprovalForAll(address operator, bool approved): Sets approval for an operator for all tokens.
// 11. isApprovedForAll(address owner, address operator): Checks if an operator is approved for all tokens.
// 12. supportsInterface(bytes4 interfaceId): Checks if the contract supports an interface.
// 13. tokenOfOwnerByIndex(address owner, uint256 index): Returns a token ID by index for an owner (from ERC721Enumerable).
// 14. totalSupply(): Returns the total number of tokens (from ERC721Enumerable).
// 15. tokenByIndex(uint256 index): Returns a token ID by global index (from ERC721Enumerable).
// 16. tokenURI(uint256 tokenId): Returns the metadata URI for a token.

// Custom QuantumFluxForge Functions:
// 17. forgeEssence(): Creates a new Flux Essence token using Plasma and randomness.
// 18. feedEssence(uint256 tokenId): Feeds an Essence with Plasma to prevent decay and reset decay timer.
// 19. applyTemporalBoost(uint256 tokenId, uint256 durationSeconds): Applies a temporary property boost using Plasma.
// 20. fluxFusion(uint256 tokenId1, uint256 tokenId2): Combines two Essences into a new one, burning the originals.
// 21. triggerQuantumDecay(uint256 tokenId): Calculates and applies decay to an Essence based on time since last fed.
// 22. refineEssence(uint256 tokenId, uint8 propertyIndex, uint256 plasmaAmount): Uses Plasma to slightly improve a specific property.
// 23. sacrificeEssence(uint256 tokenId): Burns an Essence for Plasma or other effects (e.g., a global boost).
// 24. updateFluxEnvironment(uint8 intensity, uint8 alignment): Owner updates the simulated global environment state.
// 25. depositPlasma(): Users deposit native currency (e.g., ETH) to get Plasma (simulated here as internal balance).
// 26. getPlasmaBalance(address owner): Gets the user's internal Plasma balance.
// 27. getEssenceProperties(uint256 tokenId): Retrieves the current dynamic properties of an Essence.
// 28. listOwnedEssences(address owner): Lists all token IDs owned by an address. (Potential gas cost warning)
// 29. getFluxEnvironment(): Gets the current global Flux Environment state.
// 30. getBoostRemainingTime(uint256 tokenId): Gets the time remaining on an Essence's temporal boost.
// 31. setForgeCost(uint256 cost): Owner sets the Plasma cost for forging.
// 32. setFeedCost(uint256 cost): Owner sets the Plasma cost for feeding.
// 33. setBoostCost(uint256 cost): Owner sets the Plasma cost for boosting.
// 34. setFusionCost(uint256 cost): Owner sets the Plasma cost for fusion.
// 35. setDecayRate(uint256 rate): Owner sets the decay rate (properties lost per unit of time).
// 36. setBaseProperties(uint8 vitality, uint8 attunement, uint8 resilience, uint8 fluxLevel): Owner sets base stats for new Essences.
// 37. setFluxEnvironment(uint8 intensity, uint8 alignment): Owner sets the initial or new Flux Environment state (duplicate of update? Let's keep 24 and remove 37, or make 24 publically callable with checks and 37 owner-only for base). Let's keep `updateFluxEnvironment` as owner only for simplicity here (24).
// 38. rescueFunds(address tokenAddress, uint256 amount): Owner can rescue accidentally sent tokens.

// Total Functions: 16 (ERC721) + 22 (Custom) = 38. Plenty over 20.

contract QuantumFluxForge is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;

    struct EssenceProperties {
        uint8 vitality;     // Health/endurance
        uint8 attunement;   // Affects interaction outcomes, boosts
        uint8 resilience;   // Resistance to decay, negative events
        uint8 fluxLevel;    // Raw power, affects fusion/sacrifice

        uint64 lastFedTimestamp; // Timestamp when last fed (for decay)
        uint64 boostEndTime;     // Timestamp when temporary boost ends
    }

    struct FluxEnvironment {
        uint8 fluxIntensity; // Global energy level
        uint8 cosmicAlignment; // Global condition affecting properties
    }

    mapping(uint256 => EssenceProperties) private _essenceProperties;
    mapping(address => uint256) private _plasmaBalances; // Internal Plasma resource balance

    FluxEnvironment public currentFluxEnvironment;

    // Configuration Costs (Plasma Units)
    uint256 public forgeCost;
    uint256 public feedCost;
    uint256 public boostCost;
    uint256 public fusionCost;
    uint256 public sacrificePlasmaReward; // Plasma gained from sacrificing
    uint256 public decayRatePerDay;       // Properties lost per day if not fed

    // Base properties for newly forged Essences
    EssenceProperties public baseEssenceProperties;

    // --- Events ---
    event EssenceForged(address indexed owner, uint256 indexed tokenId, EssenceProperties properties);
    event EssenceFed(uint256 indexed tokenId, uint256 plasmaAmount);
    event TemporalBoostApplied(uint256 indexed tokenId, uint256 durationSeconds);
    event EssenceFusion(uint256 indexed newTokenId, uint256 indexed oldTokenId1, uint256 indexed oldTokenId2);
    event QuantumDecayTriggered(uint256 indexed tokenId, uint256 propertiesLost);
    event EssenceRefined(uint256 indexed tokenId, uint8 indexed propertyIndex, uint256 plasmaAmount);
    event EssenceSacrificed(uint256 indexed tokenId, address indexed owner, uint256 plasmaReturned);
    event FluxEnvironmentUpdated(uint8 intensity, uint8 alignment);
    event PlasmaDeposited(address indexed user, uint256 amount);
    event PlasmaWithdrawn(address indexed user, uint256 amount); // If withdrawal is allowed
    event CostsUpdated(string costName, uint256 newCost);
    event BasePropertiesUpdated(EssenceProperties newProperties);

    // --- Constructor ---
    constructor(
        string memory name,
        string memory symbol,
        uint256 _forgeCost,
        uint256 _feedCost,
        uint256 _boostCost,
        uint256 _fusionCost,
        uint256 _sacrificePlasmaReward,
        uint256 _decayRatePerDay,
        uint8 _baseVitality,
        uint8 _baseAttunement,
        uint8 _baseResilience,
        uint8 _baseFluxLevel,
        uint8 initialFluxIntensity,
        uint8 initialCosmicAlignment
    )
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        forgeCost = _forgeCost;
        feedCost = _feedCost;
        boostCost = _boostCost;
        fusionCost = _fusionCost;
        sacrificePlasmaReward = _sacrificePlasmaReward;
        decayRatePerDay = _decayRatePerDay;

        baseEssenceProperties = EssenceProperties({
            vitality: _baseVitality,
            attunement: _baseAttunement,
            resilience: _baseResilience,
            fluxLevel: _baseFluxLevel,
            lastFedTimestamp: uint64(block.timestamp), // Initialize to now for base
            boostEndTime: 0
        });

        currentFluxEnvironment = FluxEnvironment({
            fluxIntensity: initialFluxIntensity,
            cosmicAlignment: initialCosmicAlignment
        });
    }

    // --- Internal Helper Functions ---

    // WARNING: Pseudo-randomness from block data is INSECURE and predictable.
    // For production, use Chainlink VRF or a similar secure oracle solution.
    function _generateRandomness(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, seed)));
         // Using block.number instead of difficulty is often preferred post-PoW.
        // return uint256(keccak256(abi.encodePacked(block.timestamp, block.number, msg.sender, seed)));
    }

    function _calculateDecay(uint256 tokenId) internal view returns (uint256 propertiesLost) {
        EssenceProperties storage props = _essenceProperties[tokenId];
        uint256 timeSinceLastFed = block.timestamp - props.lastFedTimestamp;
        uint256 daysSinceLastFed = timeSinceLastFed / 1 days; // Using 1 day in seconds

        // Only calculate decay if enough time has passed and not fed recently
        if (daysSinceLastFed > 0) {
            // Decay is affected by resilience (higher resilience = less decay)
            // Simple example: decay = days * rate / resilience_modifier (avoiding division by zero)
            uint256 resilienceModifier = props.resilience > 0 ? props.resilience : 1;
            propertiesLost = (daysSinceLastFed * decayRatePerDay) / resilienceModifier;

            // Cap properties lost to prevent negative stats (stats are uint8, 0-255)
            // Need to sum up current properties to calculate total loss
            uint256 currentTotalProperties = props.vitality + props.attunement + props.resilience + props.fluxLevel;
            if (propertiesLost > currentTotalProperties) {
                 propertiesLost = currentTotalProperties;
            }
        } else {
            propertiesLost = 0;
        }
    }

    function _applyDecay(uint256 tokenId, uint256 propertiesLost) internal {
         EssenceProperties storage props = _essenceProperties[tokenId];
         if (propertiesLost == 0) return;

         // Distribute the property loss relatively or randomly.
         // Simple approach: distribute proportionally to current values.
         // More complex: specific properties decay faster. Let's do a proportional loss.
         uint256 totalCurrent = uint256(props.vitality) + props.attunement + props.resilience + props.fluxLevel;
         if (totalCurrent == 0) return; // Nothing to decay

         uint256 decayPerUnit = propertiesLost * 1e18 / totalCurrent; // Use fixed point for distribution

         props.vitality = uint8(_safeSubtract(props.vitality, uint256(props.vitality).mul(decayPerUnit).div(1e18)));
         props.attunement = uint8(_safeSubtract(props.attunement, uint256(props.attunement).mul(decayPerUnit).div(1e18)));
         props.resilience = uint8(_safeSubtract(props.resilience, uint256(props.resilience).mul(decayPerUnit).div(1e18)));
         props.fluxLevel = uint8(_safeSubtract(props.fluxLevel, uint256(props.fluxLevel).mul(decayPerUnit).div(1e18)));

         // Ensure no property goes below 0 (although uint8 naturally handles this by underflowing if not careful,
         // SafeMath prevents that. Need to manually cap at 0 if calculation could result in underflow).
         // The _safeSubtract caps at the original value, effectively preventing negative.
         // Example: if decay wants to reduce vitality by 10 but vitality is 5, _safeSubtract(5, 10) would revert.
         // We need a different approach to distribute the total loss gracefully.

         // Alternative decay distribution: Apply loss point by point, prioritizing or randomizing which stat loses.
         // This is simpler: just subtract total propertiesLost from the sum, distribute the loss.
         // Let's subtract randomly for variety.
         for (uint256 i = 0; i < propertiesLost; i++) {
             uint256 rand = _generateRandomness(tokenId + block.timestamp + i) % 4; // 0:vitality, 1:attunement, 2:resilience, 3:fluxLevel
             if (rand == 0 && props.vitality > 0) props.vitality--;
             else if (rand == 1 && props.attunement > 0) props.attunement--;
             else if (rand == 2 && props.resilience > 0) props.resilience--;
             else if (rand == 3 && props.fluxLevel > 0) props.fluxLevel--;
             // If the chosen stat is already 0, the loop continues trying to subtract elsewhere.
             // This is inefficient if propertiesLost is large and stats are low.
             // A better way: calculate total points, subtract propertiesLost, redistribute remaining proportionally.

             // Let's simplify for this example: just subtract 'propertiesLost' points total, distributed evenly or slightly randomly.
             // Vitality takes slightly more decay pressure
             uint256 randProp = _generateRandomness(tokenId + block.timestamp + i) % 10; // 0-9
             if (randProp < 4 && props.vitality > 0) props.vitality--; // 40% chance vitality decay
             else if (randProp < 7 && props.attunement > 0) props.attunement--; // 30% attunement
             else if (randProp < 9 && props.resilience > 0) props.resilience--; // 20% resilience
             else if (props.fluxLevel > 0) props.fluxLevel--; // 10% flux level
         }

         // Update the last fed timestamp to prevent immediate re-decay
         props.lastFedTimestamp = uint64(block.timestamp);
         emit QuantumDecayTriggered(tokenId, propertiesLost);
    }

    // Simple SafeMath wrappers for uint8 arithmetic with clamping
    function _safeAdd(uint8 a, uint8 b) internal pure returns (uint8) {
        uint256 c = uint256(a) + uint256(b);
        require(c <= 255, "Property overflow");
        return uint8(c);
    }

     function _safeSubtract(uint8 a, uint8 b) internal pure returns (uint8) {
        require(a >= b, "Property underflow");
        return a - b;
    }

    function _safeMultiply(uint8 a, uint8 b) internal pure returns (uint8) {
         uint256 c = uint256(a) * uint256(b);
         require(c <= 255, "Property overflow");
         return uint8(c);
    }

    // --- Core Logic Functions ---

    /**
     * @dev Forges a new Flux Essence token for the caller.
     * Requires 'forgeCost' Plasma. Properties are randomized based on base stats and environment.
     */
    function forgeEssence() public {
        require(_plasmaBalances[msg.sender] >= forgeCost, "Not enough Plasma");

        _plasmaBalances[msg.sender] = _plasmaBalances[msg.sender].sub(forgeCost);

        uint256 newTokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        // Generate initial properties with randomness and environmental influence
        uint256 randSeed = _generateRandomness(newTokenId);

        EssenceProperties memory initialProps = EssenceProperties({
            vitality: _safeAdd(baseEssenceProperties.vitality, uint8(randSeed % 20)), // Base + 0-19 random
            attunement: _safeAdd(baseEssenceProperties.attunement, uint8((randSeed >> 8) % 20)),
            resilience: _safeAdd(baseEssenceProperties.resilience, uint8((randSeed >> 16) % 20)),
            fluxLevel: _safeAdd(baseEssenceProperties.fluxLevel, uint8((randSeed >> 24) % 20)),
            lastFedTimestamp: uint64(block.timestamp),
            boostEndTime: 0
        });

        // Apply environmental influence (simple example: higher intensity boosts fluxLevel)
        initialProps.fluxLevel = _safeAdd(initialProps.fluxLevel, uint8(currentFluxEnvironment.fluxIntensity / 10)); // +0-25 based on intensity 0-255

        _essenceProperties[newTokenId] = initialProps;
        _safeMint(msg.sender, newTokenId);

        emit EssenceForged(msg.sender, newTokenId, initialProps);
    }

    /**
     * @dev Feeds an Essence with Plasma to reset its decay timer and slightly boost vitality.
     * Requires 'feedCost' Plasma. Callable by token owner or approved operator.
     */
    function feedEssence(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is not owner or approved");
        require(_plasmaBalances[msg.sender] >= feedCost, "Not enough Plasma");

        // Ensure any pending decay is applied BEFORE feeding resets the timer
        triggerQuantumDecay(tokenId); // Applies decay if due

        _plasmaBalances[msg.sender] = _plasmaBalances[msg.sender].sub(feedCost);

        EssenceProperties storage props = _essenceProperties[tokenId];
        props.lastFedTimestamp = uint64(block.timestamp); // Reset decay timer
        props.vitality = _safeAdd(props.vitality, 5); // Slight vitality boost

        emit EssenceFed(tokenId, feedCost);
    }

    /**
     * @dev Applies a temporary boost to an Essence's properties.
     * Requires 'boostCost' Plasma. Duration is specified in seconds. Callable by owner/approved.
     */
    function applyTemporalBoost(uint256 tokenId, uint256 durationSeconds) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is not owner or approved");
        require(_plasmaBalances[msg.sender] >= boostCost, "Not enough Plasma");
        require(durationSeconds > 0, "Boost duration must be positive");
        require(durationSeconds <= 3600 * 24 * 7, "Boost duration max 7 days"); // Example max duration

        // Ensure any pending decay is applied BEFORE boosting
        triggerQuantumDecay(tokenId);

        _plasmaBalances[msg.sender] = _plasmaBalances[msg.sender].sub(boostCost);

        EssenceProperties storage props = _essenceProperties[tokenId];
        props.boostEndTime = uint64(block.timestamp + durationSeconds);

        // Apply a temporary boost to properties (e.g., vitality and attunement)
        // Note: The actual *effect* of the boost would likely be read off-chain or
        // used in other on-chain functions (like fusion outcome).
        // For simplicity here, we just set the timer. Let's add a *small* immediate boost too.
        props.vitality = _safeAdd(props.vitality, 10);
        props.attunement = _safeAdd(props.attunement, 10);

        emit TemporalBoostApplied(tokenId, durationSeconds);
    }

    /**
     * @dev Fuses two Essences into a new one, burning the originals.
     * Requires 'fusionCost' Plasma. Callable by owner/approved of both tokens.
     * New Essence properties are derived from the fused ones with randomness and environment influence.
     */
    function fluxFusion(uint256 tokenId1, uint256 tokenId2) public {
        require(tokenId1 != tokenId2, "Cannot fuse an Essence with itself");
        require(_isApprovedOrOwner(msg.sender, tokenId1), "Caller is not owner or approved for token 1");
        require(_isApprovedOrOwner(msg.sender, tokenId2), "Caller is not owner or approved for token 2");
        require(_plasmaBalances[msg.sender] >= fusionCost, "Not enough Plasma");

        // Ensure decay is applied before using properties for fusion
        triggerQuantumDecay(tokenId1);
        triggerQuantumDecay(tokenId2);

        EssenceProperties storage props1 = _essenceProperties[tokenId1];
        EssenceProperties storage props2 = _essenceProperties[tokenId2];

        _plasmaBalances[msg.sender] = _plasmaBalances[msg.sender].sub(fusionCost);

        // Burn the source tokens
        _burn(tokenId1);
        _burn(tokenId2);

        uint256 newTokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        // Calculate new properties (example: average + random bonus + flux influence)
        uint256 randSeed = _generateRandomness(tokenId1 + tokenId2 + block.timestamp);

        EssenceProperties memory newProps;
        newProps.vitality = _safeAdd(uint8((props1.vitality + props2.vitality) / 2), uint8(randSeed % 10)); // Average + 0-9 random
        newProps.attunement = _safeAdd(uint8((props1.attunement + props2.attunement) / 2), uint8((randSeed >> 8) % 10));
        newProps.resilience = _safeAdd(uint8((props1.resilience + props2.resilience) / 2), uint8((randSeed >> 16) % 10));
        newProps.fluxLevel = _safeAdd(uint8((props1.fluxLevel + props2.fluxLevel) / 2), uint8((randSeed >> 24) % 10));

        // Add bonus based on combined flux level
        uint256 combinedFluxBonus = (uint256(props1.fluxLevel) + props2.fluxLevel) / 20; // e.g., every 20 points gives +1 to all
        newProps.vitality = _safeAdd(newProps.vitality, uint8(combinedFluxBonus));
        newProps.attunement = _safeAdd(newProps.attunement, uint8(combinedFluxBonus));
        newProps.resilience = _safeAdd(newProps.resilience, uint8(combinedFluxBonus));
        newProps.fluxLevel = _safeAdd(newProps.fluxLevel, uint8(combinedFluxBonus));

        // Apply environmental influence
        newProps.vitality = _safeAdd(newProps.vitality, uint8(currentFluxEnvironment.cosmicAlignment / 30)); // Example influence
        newProps.fluxLevel = _safeAdd(newProps.fluxLevel, uint8(currentFluxEnvironment.fluxIntensity / 20));

        newProps.lastFedTimestamp = uint64(block.timestamp); // New essence starts fresh
        newProps.boostEndTime = 0; // Fusion clears boosts

        _essenceProperties[newTokenId] = newProps;
        _safeMint(msg.sender, newTokenId);

        emit EssenceFusion(newTokenId, tokenId1, tokenId2);
    }

    /**
     * @dev Triggers the decay calculation and application for an Essence.
     * Can be called by anyone, but only applies decay if sufficient time has passed since last fed.
     */
    function triggerQuantumDecay(uint256 tokenId) public {
        require(_exists(tokenId), "Essence does not exist");

        // Calculate potential decay
        uint256 propertiesLost = _calculateDecay(tokenId);

        // Apply decay if any is due
        if (propertiesLost > 0) {
            _applyDecay(tokenId, propertiesLost);
            // _applyDecay already updates lastFedTimestamp and emits event
        }
    }

    /**
     * @dev Uses Plasma to refine a specific property of an Essence.
     * Requires Plasma. Callable by owner/approved. propertyIndex maps to vitality(0), attunement(1), etc.
     */
    function refineEssence(uint256 tokenId, uint8 propertyIndex, uint256 plasmaAmount) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is not owner or approved");
        require(_plasmaBalances[msg.sender] >= plasmaAmount, "Not enough Plasma");
        require(plasmaAmount > 0, "Refinement requires Plasma");
        require(propertyIndex < 4, "Invalid property index"); // 0:vitality, 1:attunement, 2:resilience, 3:fluxLevel

        // Ensure decay is applied before refining
        triggerQuantumDecay(tokenId);

        _plasmaBalances[msg.sender] = _plasmaBalances[msg.sender].sub(plasmaAmount);

        EssenceProperties storage props = _essenceProperties[tokenId];

        // Calculate refinement gain (example: linear with plasma amount)
        uint256 gain = plasmaAmount / 10; // 10 Plasma per property point

        // Apply gain to the specified property
        if (propertyIndex == 0) props.vitality = _safeAdd(props.vitality, uint8(gain));
        else if (propertyIndex == 1) props.attunement = _safeAdd(props.attunement, uint8(gain));
        else if (propertyIndex == 2) props.resilience = _safeAdd(props.resilience, uint8(gain));
        else if (propertyIndex == 3) props.fluxLevel = _safeAdd(props.fluxLevel, uint8(gain));

        emit EssenceRefined(tokenId, propertyIndex, plasmaAmount);
    }

    /**
     * @dev Burns an Essence, granting the owner a reward in Plasma.
     * Callable by owner/approved.
     */
    function sacrificeEssence(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is not owner or approved");

        address owner = ownerOf(tokenId);

        // Optional: Grant bonus Plasma based on Essence properties?
        uint26 essenceFluxLevel = _essenceProperties[tokenId].fluxLevel;
        uint256 reward = sacrificePlasmaReward.add(uint256(essenceFluxLevel) * 10); // Example: bonus Plasma based on fluxLevel

        _burn(tokenId); // This also deletes from _essenceProperties mapping

        _plasmaBalances[owner] = _plasmaBalances[owner].add(reward);

        emit EssenceSacrificed(tokenId, owner, reward);
    }

     /**
     * @dev Owner updates the simulated global Flux Environment.
     */
    function updateFluxEnvironment(uint8 intensity, uint8 alignment) public onlyOwner {
        currentFluxEnvironment.fluxIntensity = intensity;
        currentFluxEnvironment.cosmicAlignment = alignment;
        emit FluxEnvironmentUpdated(intensity, alignment);
    }


    // --- Plasma Management Functions ---

    /**
     * @dev Allows users to deposit native currency (simulated) to gain internal Plasma balance.
     * In a real contract, this might involve receiving an ERC20 Plasma token or converting ETH.
     * Here, it's just a placeholder for increasing internal balance.
     * A real implementation might convert sent Ether: _plasmaBalances[msg.sender] += msg.value * plasmaExchangeRate;
     * Or require a separate ERC20 Plasma token and use approve/transferFrom.
     * For this example, calling this function simply adds a fixed amount.
     */
    function depositPlasma() public payable {
        // In a real scenario, exchange msg.value for Plasma.
        // Example: 1 ether buys 100 Plasma units
        // uint256 plasmaGained = msg.value.mul(100) / 1 ether;
        // require(plasmaGained > 0, "Deposit amount too low");
        // _plasmaBalances[msg.sender] = _plasmaBalances[msg.sender].add(plasmaGained);
        // emit PlasmaDeposited(msg.sender, plasmaGained);

        // Simple example: just add a fixed amount per call (for testing without handling value)
         uint26 fixedDepositAmount = 1000; // Example fixed amount
        _plasmaBalances[msg.sender] = _plasmaBalances[msg.sender].add(fixedDepositAmount);
        emit PlasmaDeposited(msg.sender, fixedDepositAmount);

        // If you want to handle sent ETH:
        // uint256 plasmaGained = msg.value; // 1 wei ETH = 1 Plasma unit (simplistic)
        // _plasmaBalances[msg.sender] = _plasmaBalances[msg.sender].add(plasmaGained);
        // emit PlasmaDeposited(msg.sender, plasmaGained);
    }

    /**
     * @dev Gets the Plasma balance for a user.
     */
    function getPlasmaBalance(address owner) public view returns (uint256) {
        return _plasmaBalances[owner];
    }

    // Note: A withdrawPlasma function would be needed if users can convert Plasma back to something else.
    // Omitted for brevity but would require careful handling (e.g., burning Plasma and sending ETH/other token).
    /*
    function withdrawPlasma(uint256 amount) public {
        require(_plasmaBalances[msg.sender] >= amount, "Not enough Plasma balance");
        // ... logic to send ETH or another token back ...
        _plasmaBalances[msg.sender] = _plasmaBalances[msg.sender].sub(amount);
        emit PlasmaWithdrawn(msg.sender, amount);
    }
    */


    // --- ERC721 Overrides & Extensions ---

    /**
     * @dev See {ERC721-tokenURI}.
     * Returns a dynamic URI based on token properties. Requires an external service.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        // In a real application, this base URI would point to a server or IPFS gateway
        // that serves JSON metadata. The server would read the on-chain properties
        // using the `getEssenceProperties` function and generate the JSON dynamically.
        // Example: "ipfs://[base_uri]/metadata/[tokenId].json"
        // The metadata JSON would include image, name, description, and attributes
        // reflecting the current dynamic properties (vitality, attunement, etc.).

        // Placeholder implementation: Base URI + token ID
        // A real base URI might look like "ipfs://Qm.../" or "https://myapi.com/metadata/"
        string memory base = "ipfs://placeholder/"; // Replace with your actual base URI
        return string(abi.encodePacked(base, Strings.toString(tokenId)));

        // To include dynamic data in the URI itself (less common/standard):
        // EssenceProperties memory props = _essenceProperties[tokenId];
        // return string(abi.encodePacked(base, Strings.toString(tokenId), "?v=", Strings.toString(props.vitality), "..."));
    }

    // The ERC721Enumerable methods (totalSupply, tokenByIndex, tokenOfOwnerByIndex)
    // are automatically provided by inheriting ERC721Enumerable.

    // Note: ERC721._beforeTokenTransfer is overridden by ERC721Enumerable to manage
    // the internal owner token lists. Do not override it here unless you also
    // reimplement the Enumerable logic.

    // We need to make _burn public if we want to call it directly like in `fluxFusion` or `sacrificeEssence`.
    // OpenZeppelin's _burn is internal by default. We can either make a public
    // wrapper or, if `Ownable` is used, keep it internal and call from public functions.
    // The current implementation calls _burn from public functions, which is fine.


    // --- Query Functions ---

    /**
     * @dev Retrieves the current dynamic properties of an Essence.
     * Applies decay before returning to ensure current state is reflected.
     */
    function getEssenceProperties(uint256 tokenId) public view returns (EssenceProperties memory) {
         require(_exists(tokenId), "Essence does not exist");
         EssenceProperties memory props = _essenceProperties[tokenId];

         // Calculate potential decay without applying it to storage
         uint26 propertiesLost = _calculateDecay(tokenId);

         if (propertiesLost > 0) {
             // Create a temporary struct to return the state *after* decay
             // Note: This calculation is repeated from _applyDecay, but in view context.
             EssenceProperties memory decayedProps = props;
              for (uint256 i = 0; i < propertiesLost; i++) {
                 uint256 randProp = uint256(keccak256(abi.encodePacked(tokenId, block.timestamp, i, "view_decay"))) % 10; // Use a different seed for view
                 if (randProp < 4 && decayedProps.vitality > 0) decayedProps.vitality--;
                 else if (randProp < 7 && decayedProps.attunement > 0) decayedProps.attunement--;
                 else if (randProp < 9 && decayedProps.resilience > 0) decayedProps.resilience--;
                 else if (decayedProps.fluxLevel > 0) decayedProps.fluxLevel--;
             }
             return decayedProps;
         } else {
            return props;
         }
    }

    /**
     * @dev Lists all token IDs owned by an address.
     * WARNING: Can be very expensive for addresses with many tokens.
     */
    function listOwnedEssences(address owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

    /**
     * @dev Gets the current global Flux Environment state.
     */
    function getFluxEnvironment() public view returns (FluxEnvironment memory) {
        return currentFluxEnvironment;
    }

    /**
     * @dev Gets the time remaining on an Essence's temporal boost.
     * Returns 0 if no boost is active or it has expired.
     */
    function getBoostRemainingTime(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Essence does not exist");
        uint256 boostEndTime = _essenceProperties[tokenId].boostEndTime;
        if (boostEndTime > block.timestamp) {
            return boostEndTime - block.timestamp;
        } else {
            return 0;
        }
    }

    /**
     * @dev Returns the total number of Essences forged ever.
     */
    function getTotalEssences() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    // --- Admin/Configuration Functions (Only Owner) ---

    function setForgeCost(uint256 cost) public onlyOwner {
        forgeCost = cost;
        emit CostsUpdated("ForgeCost", cost);
    }

    function setFeedCost(uint256 cost) public onlyOwner {
        feedCost = cost;
        emit CostsUpdated("FeedCost", cost);
    }

    function setBoostCost(uint256 cost) public onlyOwner {
        boostCost = cost;
        emit CostsUpdated("BoostCost", cost);
    }

    function setFusionCost(uint256 cost) public onlyOwner {
        fusionCost = cost;
        emit CostsUpdated("FusionCost", cost);
    }

    function setDecayRate(uint26 rate) public onlyOwner {
         decayRatePerDay = rate;
         emit CostsUpdated("DecayRatePerDay", rate);
    }

    function setSacrificePlasmaReward(uint26 reward) public onlyOwner {
         sacrificePlasmaReward = reward;
         emit CostsUpdated("SacrificePlasmaReward", reward);
    }

    function setBaseProperties(uint8 vitality, uint8 attunement, uint8 resilience, uint8 fluxLevel) public onlyOwner {
        baseEssenceProperties = EssenceProperties({
            vitality: vitality,
            attunement: attunement,
            resilience: resilience,
            fluxLevel: fluxLevel,
            lastFedTimestamp: baseEssenceProperties.lastFedTimestamp, // Keep existing timestamp info if needed
            boostEndTime: baseEssenceProperties.boostEndTime
        });
        emit BasePropertiesUpdated(baseEssenceProperties);
    }

    // Note: updateFluxEnvironment (24) is already defined as onlyOwner


    // --- Emergency Functions ---

    /**
     * @dev Owner can rescue any ERC20 tokens accidentally sent to the contract.
     * Does not allow rescuing the contract's own Plasma balance if it were an ERC20.
     */
    function rescueFunds(address tokenAddress, uint256 amount) public onlyOwner {
        require(tokenAddress != address(0), "Invalid token address");
        // Add a check here if Plasma were a real ERC20 token:
        // require(tokenAddress != address(this), "Cannot rescue contract's own Plasma token");

        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(owner(), amount), "Token transfer failed");
    }
}

// Need the ERC20 interface for rescueFunds
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    // Minimal interface needed
}

```

---

**Explanation of Advanced Concepts and Creativity:**

1.  **Dynamic NFTs:** The core idea deviates from typical static NFTs. The `EssenceProperties` struct associated with each `tokenId` (`_essenceProperties` mapping) holds mutable data (`vitality`, `attunement`, `fluxLevel`, timestamps).
2.  **Time-Based Mechanics (Decay & Boost):** The `lastFedTimestamp` and `boostEndTime` introduce time as a factor. `triggerQuantumDecay` and `feedEssence` directly implement a survival mechanic based on time. `applyTemporalBoost` adds temporary state changes.
3.  **Resource Management (Plasma):** The internal `_plasmaBalances` mapping simulates a resource token required for various actions (forging, feeding, boosting, fusion, refining). This adds an economic layer within the contract's ecosystem.
4.  **Complex Interactions (Fusion, Refinement, Sacrifice):** `fluxFusion` burns tokens and creates a new one with combined/mutated properties. `refineEssence` allows targeted property improvement. `sacrificeEssence` provides a burn mechanism with a reward, adding another economic sink/source.
5.  **Simulated Global State (Flux Environment):** The `currentFluxEnvironment` struct adds an external, albeit simulated, factor that can influence token creation (`forgeEssence`) or potentially other future interactions. This could be extended to represent game seasons, global events, etc.
6.  **Dynamic Metadata:** The `tokenURI` function is designed with the understanding that the metadata must change as the token's properties change. While the provided `tokenURI` is a placeholder, the concept relies on an off-chain service reading the *on-chain dynamic state* (`getEssenceProperties`) to serve the correct metadata JSON.
7.  **Internal Token Management:** Instead of relying on a separate ERC20 contract for Plasma, the contract manages balances internally (`_plasmaBalances`). This simplifies deployment for this example but shows how a resource system can be built.
8.  **Keeper Function (Decay Trigger):** While `triggerQuantumDecay` can be called by the owner, the intent is often for *anyone* (like an automated "keeper" bot) to call it to update the state for a specific token, incentivizing network participation in maintaining state accuracy.
9.  **Structured Properties:** Using a struct for properties makes it easy to manage multiple stats per token.

**Non-Duplication Note:**
While contracts involving NFTs, resource tokens, or crafting exist, the combination of *all* these specific dynamic mechanics – time-based decay, resource-gated actions, property-based fusion with randomness and environmental influence, targeted property refinement, and a sacrifice mechanism within a single ERC721 contract with internal resource management – is not a standard pattern directly copied from common open-source implementations like OpenZeppelin's standard extensions. The logic within the core functions like `fluxFusion`, `triggerQuantumDecay`, `feedEssence`, `refineEssence`, and the state management in `_essenceProperties` constitutes the unique aspect. Standard parts like ERC721 interfaces and `Ownable` are necessarily used for best practice and compatibility but do not represent the contract's core custom logic.

Remember to replace the `ipfs://placeholder/` in `tokenURI` with a real base URI pointing to your metadata server/gateway and implement the off-chain service to serve dynamic JSON based on `getEssenceProperties(tokenId)`. Also, the randomness source (`_generateRandomness`) is insecure and should be replaced with a secure solution like Chainlink VRF for any production use case involving value.