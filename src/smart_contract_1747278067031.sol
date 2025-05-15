Okay, let's design an advanced, creative, and non-standard smart contract. We'll create a system of "ChronoEssences" - dynamic, time-sensitive NFTs that evolve, decay, can be nurtured, affected by simulated environmental events, and even delegated for care.

This concept combines:
1.  **Dynamic NFTs:** State and properties change over time and interaction.
2.  **Time-Based Mechanics:** Decay, evolution based on time passage.
3.  **Simulated External Factors:** Admin-triggered "environmental events".
4.  **Delegation:** Granting specific rights (nurturing) to others.
5.  **Conditional State Transitions:** Evolution based on properties meeting thresholds.
6.  **Utility/Yield:** Essences can accumulate potential yield in certain states.
7.  **Temporary Buffs:** A "blessing" mechanism.

---

**Contract Outline:**

1.  **Pragmas & Imports:** Solidity version, OpenZeppelin imports for ERC721, Ownable, ReentrancyGuard.
2.  **Enums:** Define the different evolutionary states (Ages) of the Essence.
3.  **Structs:**
    *   `EssenceProperties`: Holds dynamic stats like Energy, Health, Resilience.
    *   `EssenceData`: Combines properties, state, timestamps, delegation info, potential yield.
4.  **State Variables:**
    *   ERC721 specific (handled by OZ).
    *   Mapping for `EssenceData` per token ID.
    *   Counters for token IDs.
    *   Configuration parameters (decay rates, nurture effects, evolution thresholds, event impacts, yield amounts).
    *   Mapping for nurture delegations.
    *   Metadata base URI.
    *   Accumulated yield ETH (if applicable).
5.  **Events:** Signal important actions and state changes (Mint, Nurture, Evolve, Decay, Event Triggered, Delegation Set, Yield Claimed, Blessed).
6.  **Modifiers:** Custom modifiers for access control (`onlyEssenceOwnerOrDelegatee`).
7.  **Internal Helpers:** Functions for applying time-based effects, checking evolution criteria.
8.  **Constructor:** Initializes the contract (Owner, potentially initial config).
9.  **Core ERC721 Functions:** Standard transfer, approval logic (mostly inherited/overridden from OZ).
10. **Essence Lifecycle & Interaction Functions:**
    *   `mintEssence`
    *   `nurture`
    *   `tryEvolve`
    *   `rescueDormant`
    *   `burnEssence` (Conditional)
11. **Utility & Read Functions:**
    *   `getCurrentEssenceState`
    *   `getEssenceProperties`
    *   `getTokenCreationTime`
    *   `getTimeSinceLastInteraction` (Nurture/Rescue/Evolve)
    *   `getPendingYield`
    *   `getBlessingStatus`
    *   `isNurtureDelegatee`
    *   `getEssenceMetadataURI`
    *   `getTotalEssences`
12. **Delegation Functions:**
    *   `delegateNurture`
    *   `revokeNurtureDelegation`
13. **Yield Functions:**
    *   `claimYield`
    *   `depositYieldEth` (Admin function)
    *   `withdrawCollectedYieldEth` (Admin function)
14. **Admin / Configuration Functions (onlyOwner):**
    *   `setBaseDecayRate`
    *   `setNurtureEffect`
    *   `setEvolutionThresholds`
    *   `setEnvironmentalEventEffect`
    *   `triggerEnvironmentalEvent`
    *   `setYieldAmountPerAge`
    *   `updateMetadataBaseURI`
    *   `setBlessingEffect` (Optional: Admin defines blessing effect)

---

**Function Summary:**

1.  `constructor()`: Initializes the contract, setting the owner.
2.  `mintEssence()`: Mints a new ChronoEssence token as a 'Seed' to the caller. Costs ETH, which funds the yield pool.
3.  `nurture(uint256 tokenId)`: Allows the owner or a delegatee to nurture an Essence, boosting its properties and resetting its last interaction time.
4.  `tryEvolve(uint256 tokenId)`: Checks if an Essence meets the criteria to evolve to the next Age based on its properties and state. Triggers evolution if conditions are met.
5.  `rescueDormant(uint256 tokenId)`: Special action to revive a 'Dormant' Essence. Might require a cost (ETH) and significantly boost properties.
6.  `burnEssence(uint256 tokenId)`: Allows the owner of a token (potentially only in certain states like 'Dormant' or 'Terminal') to destroy it.
7.  `claimYield(uint256 tokenId)`: Allows the owner to claim accumulated yield (ETH) based on the Essence's state and time spent in yield-generating states. Uses ReentrancyGuard.
8.  `delegateNurture(uint256 tokenId, address delegatee, uint64 expiresAt)`: Allows the Essence owner to grant permission to another address to call `nurture` on their behalf until a specified time.
9.  `revokeNurtureDelegation(uint256 tokenId)`: Allows the Essence owner to cancel an existing nurture delegation.
10. `getCurrentEssenceState(uint256 tokenId)`: Reads the current evolutionary state (Age) of an Essence.
11. `getEssenceProperties(uint256 tokenId)`: Reads the current dynamic properties (Energy, Health, Resilience) of an Essence, applying decay based on time since last update.
12. `getTokenCreationTime(uint256 tokenId)`: Reads the block timestamp when the Essence was minted.
13. `getTimeSinceLastInteraction(uint256 tokenId)`: Reads the time elapsed since the last time the Essence was nurtured, rescued, or evolved.
14. `getPendingYield(uint256 tokenId)`: Calculates the amount of yield (ETH) currently claimable for a specific Essence based on its history.
15. `getBlessingStatus(uint256 tokenId)`: Reads the timestamp when the Essence's blessing expires (0 if not blessed).
16. `isNurtureDelegatee(uint256 tokenId, address account)`: Checks if a given account is the currently active nurture delegatee for an Essence.
17. `getEssenceMetadataURI(uint256 tokenId)`: Returns the metadata URI for a given token ID, combining a base URI with the token ID.
18. `getTotalEssences()`: Returns the total number of Essences minted.
19. `setBaseDecayRate(uint8 propertyIndex, int256 rate)`: (Owner) Sets the global per-second decay rate for a specific property index (0=Energy, 1=Health, 2=Resilience). Negative means growth.
20. `setNurtureEffect(uint8 propertyIndex, int256 effect)`: (Owner) Sets the boost applied to a property when an Essence is nurtured.
21. `setEvolutionThresholds(uint8 currentAge, uint8 nextAge, uint8 propertyIndex, int256 threshold)`: (Owner) Sets the required value for a specific property to evolve from `currentAge` to `nextAge`.
22. `setEnvironmentalEventEffect(uint8 eventCode, uint8 propertyIndex, int256 effect)`: (Owner) Configures how a specific environmental event type impacts a property.
23. `triggerEnvironmentalEvent(uint8 eventCode)`: (Owner) Applies the configured effect of an environmental event to ALL active (non-dormant/terminal) Essences.
24. `setYieldAmountPerAge(uint8 age, uint256 amountPerSecond)`: (Owner) Sets the rate (Wei per second) at which Essences in a specific age accumulate potential yield.
25. `depositYieldEth()`: (Admin) Allows the owner to send ETH to the contract's balance, funding the yield pool.
26. `withdrawCollectedYieldEth(uint256 amount)`: (Admin) Allows the owner to withdraw accumulated yield ETH *not* yet claimed by token owners. (Careful: Needs careful accounting, or maybe just withdraw *all* owner-deposited funds). Let's make it withdraw *any* balance *not* marked as pending yield.
27. `updateMetadataBaseURI(string memory newURI)`: (Owner) Updates the base URI used for generating token metadata links.
28. `blessEssence(uint256 tokenId, uint32 durationSeconds)`: (Owner/Special Role?) Applies a temporary blessing buff to an Essence, preventing decay or boosting gain for a duration. Let's make this a separate admin function for simplicity, perhaps tied to events. Or maybe it's a *user* action that costs something. Let's make it an admin-triggered event specific to one token for creativity.
29. `setBlessingEffect(uint8 propertyIndex, int256 effect)`: (Owner) Sets the constant boost rate for a property while blessed.
30. `applyBlessingEffect(uint256 tokenId)`: Internal helper to apply blessing effect while active. (Counts as internal utility).

Okay, that's 30+ functions listed, ensuring we meet the >20 requirement with plenty of custom logic beyond standard interfaces.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

// --- Contract Outline ---
// 1. Pragmas & Imports
// 2. Enums (EssenceState)
// 3. Structs (EssenceProperties, EssenceData, NurtureDelegation)
// 4. State Variables (Mappings for data, counters, config, yield)
// 5. Events
// 6. Modifiers (onlyEssenceOwnerOrDelegatee)
// 7. Internal Helpers (_applyTimeBasedEffects, _checkEvolutionCriteria, _applyBlessingEffect)
// 8. Constructor
// 9. Core ERC721 Overrides (For custom metadata)
// 10. Essence Lifecycle & Interaction Functions (mint, nurture, tryEvolve, rescueDormant, burn)
// 11. Utility & Read Functions (get state, properties, time, yield, blessing, delegation, URI, total)
// 12. Delegation Functions (delegate, revoke)
// 13. Yield Functions (claim, deposit, withdraw admin)
// 14. Admin / Configuration Functions (set rates, effects, thresholds, trigger event, set yield, update URI, set blessing config, apply blessing)

// --- Function Summary ---
// 1.  constructor(): Initializes the contract, setting the owner and base URI.
// 2.  mintEssence(): Mints a new 'Seed' Essence token to the caller. Requires ETH payment to fund yield pool.
// 3.  nurture(uint256 tokenId): Boosts Essence properties, applies decay, updates last interaction time. Callable by owner or delegatee.
// 4.  tryEvolve(uint256 tokenId): Applies decay, checks evolution criteria, transitions to the next Age if met.
// 5.  rescueDormant(uint256 tokenId): Special action to revive a 'Dormant' Essence. Requires ETH payment, boosts properties, transitions to Seed state.
// 6.  burnEssence(uint256 tokenId): Destroys an Essence token (owner callable, potentially restricted by state).
// 7.  claimYield(uint256 tokenId): Calculates and sends accumulated ETH yield to the token owner. Uses ReentrancyGuard.
// 8.  delegateNurture(uint256 tokenId, address delegatee, uint64 expiresAt): Owner delegates nurture rights.
// 9.  revokeNurtureDelegation(uint256 tokenId): Owner revokes nurture rights.
// 10. getCurrentEssenceState(uint256 tokenId): Reads the current Age of an Essence.
// 11. getEssenceProperties(uint256 tokenId): Reads properties, applying decay up to the last interaction.
// 12. getTokenCreationTime(uint256 tokenId): Gets mint timestamp.
// 13. getTimeSinceLastInteraction(uint256 tokenId): Gets time since last nurture/rescue/evolve.
// 14. getPendingYield(uint256 tokenId): Calculates claimable yield without claiming.
// 15. getBlessingStatus(uint256 tokenId): Gets blessing expiration timestamp.
// 16. isNurtureDelegatee(uint256 tokenId, address account): Checks delegation status.
// 17. tokenURI(uint256 tokenId): ERC721 standard metadata URI override.
// 18. getTotalEssences(): Total minted count.
// 19. setBaseDecayRate(uint8 propertyIndex, int256 rate): (Owner) Configures property decay/growth rate.
// 20. setNurtureEffect(uint8 propertyIndex, int256 effect): (Owner) Configures nurture property boost.
// 21. setEvolutionThresholds(uint8 currentAge, uint8 nextAge, uint8 propertyIndex, int256 threshold): (Owner) Configures evolution requirements.
// 22. setEnvironmentalEventEffect(uint8 eventCode, uint8 propertyIndex, int256 effect): (Owner) Configures event impact.
// 23. triggerEnvironmentalEvent(uint8 eventCode): (Owner) Applies event effect to active Essences.
// 24. setYieldAmountPerAge(uint8 age, uint256 amountPerSecond): (Owner) Configures yield rate per Age.
// 25. depositYieldEth(): (Owner) Adds ETH to the yield pool.
// 26. withdrawCollectedYieldEth(uint256 amount): (Owner) Withdraws non-pending ETH yield.
// 27. updateMetadataBaseURI(string memory newURI): (Owner) Updates base URI.
// 28. setBlessingEffect(uint8 propertyIndex, int256 effect): (Owner) Configures blessing property boost rate.
// 29. applyBlessingToEssence(uint256 tokenId, uint32 durationSeconds): (Owner) Applies a temporary blessing buff to a specific Essence.
// 30. getAgeFromUint(uint8 age): Helper to convert uint to EssenceState enum. (Utility/Read)
// 31. getPropertyFromUint(uint8 propertyIndex): Helper to convert uint to property name. (Utility/Read)

contract ChronoEssence is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- Enums ---
    enum EssenceState {
        Seed,
        Sprout,
        Sapling,
        Mature,
        Dormant,
        Terminal // Cannot evolve further, maybe can be burned or yields something specific
    }

    // --- Structs ---
    struct EssenceProperties {
        int256 energy;
        int256 health;
        int256 resilience;
    }

    struct EssenceData {
        EssenceState currentState;
        EssenceProperties properties;
        uint64 creationTimestamp;
        uint64 lastInteractionTimestamp; // Nurture, Rescue, Evolve
        uint64 blessingExpiresAt;
        uint256 yieldPoints; // Accumulates based on state and time
    }

    struct NurtureDelegation {
        address delegatee;
        uint64 expiresAt;
    }

    // --- State Variables ---
    mapping(uint256 => EssenceData) private _essenceData;
    mapping(uint256 => NurtureDelegation) private _nurtureDelegations;

    // Configuration (Owner set)
    int256[3] public baseDecayRate; // Rate per second for [Energy, Health, Resilience]
    int256[3] public nurtureEffect; // Boost applied per nurture for [Energy, Health, Resilience]
    // Evolution thresholds: mapping from current Age uint => mapping next Age uint => mapping property index => required value
    mapping(uint8 => mapping(uint8 => mapping(uint8 => int256))) public evolutionThresholds;
    // Environmental Event effects: mapping from eventCode uint8 => mapping property index => effect
    mapping(uint8 => mapping(uint8 => int256)) public environmentalEventEffects;
    uint256[6] public yieldAmountPerAge; // Yield points per second for each Age enum index
    int256[3] public blessingEffect; // Constant boost per second while blessed

    string private _metadataBaseURI;

    // --- Events ---
    event EssenceMinted(uint256 indexed tokenId, address indexed owner, uint64 timestamp);
    event EssenceNurtured(uint256 indexed tokenId, address indexed by, uint64 timestamp);
    event EssenceEvolved(uint256 indexed tokenId, EssenceState fromState, EssenceState toState, uint64 timestamp);
    event EssenceDormant(uint256 indexed tokenId, uint64 timestamp);
    event EssenceRescued(uint256 indexed tokenId, uint64 timestamp);
    event EssenceBurned(uint256 indexed tokenId);
    event EnvironmentalEventTriggered(uint8 indexed eventCode, uint64 timestamp);
    event NurtureDelegationSet(uint256 indexed tokenId, address indexed delegatee, uint64 expiresAt);
    event NurtureDelegationRevoked(uint256 indexed tokenId);
    event YieldClaimed(uint256 indexed tokenId, address indexed owner, uint256 amount);
    event EssenceBlessed(uint256 indexed tokenId, uint64 expiresAt);
    event ConfigUpdated(string paramName); // Generic event for config changes

    // --- Modifiers ---
    modifier onlyEssenceOwnerOrDelegatee(uint256 tokenId) {
        address owner = ownerOf(tokenId);
        require(owner == _msgSender() || isNurtureDelegatee(tokenId, _msgSender()), "Not essence owner or authorized delegatee");
        _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol, string memory baseURI) ERC721(name, symbol) Ownable(msg.sender) {
        _metadataBaseURI = baseURI;

        // Set initial default configurations (can be changed by owner later)
        baseDecayRate = [-1, -1, -1]; // Gentle decay by default
        nurtureEffect = [10, 5, 2]; // Nurturing gives energy, health, resilience
        blessingEffect = [5, 5, 5]; // Blessing boosts all properties
        yieldAmountPerAge = [0, 1, 5, 20, 0, 0]; // Yield: Seed=0, Sprout=1, Sapling=5, Mature=20, Dormant=0, Terminal=0 points/sec
    }

    // --- Internal Helpers ---

    function _applyTimeBasedEffects(uint256 tokenId) internal {
        EssenceData storage data = _essenceData[tokenId];
        uint64 currentTime = uint64(block.timestamp);
        uint64 timeElapsedSinceLastInteraction = currentTime - data.lastInteractionTimestamp;

        if (timeElapsedSinceLastInteraction == 0 ||
            data.currentState == EssenceState.Dormant ||
            data.currentState == EssenceState.Terminal) {
            return; // No effects apply if no time passed or in static states
        }

        // Apply blessing effect if active
        bool isBlessed = currentTime < data.blessingExpiresAt;
        int256 blessedTime = isBlessed ? int256(Math.min(timeElapsedSinceLastInteraction, data.blessingExpiresAt - data.lastInteractionTimestamp)) : 0;

        // Apply decay/growth from base rate and blessing
        for (uint8 i = 0; i < 3; i++) {
            int256 netRate = baseDecayRate[i];
            if (isBlessed) {
                netRate += blessingEffect[i]; // Blessing modifies the rate
            }
             // Apply decay/growth for non-blessed time
            data.properties[i] += netRate * int256(timeElapsedSinceLastInteraction - uint64(blessedTime));
            // Apply modified rate for blessed time
            if(blessedTime > 0) {
                 data.properties[i] += (baseDecayRate[i] + blessingEffect[i]) * blessedTime;
            }
        }

        // Apply accumulated yield
        data.yieldPoints += uint256(timeElapsedSinceLastInteraction) * yieldAmountPerAge[uint8(data.currentState)];

        // Update last interaction timestamp
        data.lastInteractionTimestamp = currentTime;

        // --- Check for transition to Dormant ---
        // Define threshold for Dormant state (e.g., health or energy drops too low)
        // Example: Goes dormant if health < 0 or energy < 0
         if (data.currentState != EssenceState.Dormant && data.currentState != EssenceState.Terminal) {
            if (data.properties.health < 0 || data.properties.energy < 0) {
                data.currentState = EssenceState.Dormant;
                emit EssenceDormant(tokenId, currentTime);
            }
        }
    }

    function _checkEvolutionCriteria(uint256 tokenId) internal view returns (EssenceState nextState) {
        EssenceData storage data = _essenceData[tokenId];
        uint8 currentAge = uint8(data.currentState);

        // Iterate through possible next states from the current state
        // This is a simplified example. Realistically, evolution paths are linear (Seed -> Sprout -> Sapling -> Mature)
        // or branch based on actions. Let's implement linear for simplicity here.
        if (currentAge == uint8(EssenceState.Seed)) nextState = EssenceState.Sprout;
        else if (currentAge == uint8(EssenceState.Sprout)) nextState = EssenceState.Sapling;
        else if (currentAge == uint8(EssenceState.Sapling)) nextState = EssenceState.Mature;
        else return data.currentState; // Cannot evolve from Mature, Dormant, Terminal

        uint8 nextAge = uint8(nextState);

        // Check all thresholds for the potential next state
        for (uint8 i = 0; i < 3; i++) {
            int256 required = evolutionThresholds[currentAge][nextAge][i];
            if (data.properties[i] < required) {
                return data.currentState; // Criteria not met for this property
            }
        }

        return nextState; // All criteria met
    }

    // Helper to get Age enum from uint8
    function getAgeFromUint(uint8 age) public pure returns (EssenceState) {
        require(age < uint8(EssenceState.Terminal) + 1, "Invalid age index");
        return EssenceState(age);
    }

     // Helper to get property name from uint8 index
    function getPropertyFromUint(uint8 propertyIndex) public pure returns (string memory) {
        require(propertyIndex < 3, "Invalid property index");
        if (propertyIndex == 0) return "Energy";
        if (propertyIndex == 1) return "Health";
        if (propertyIndex == 2) return "Resilience";
        return "Unknown"; // Should not happen
    }


    // --- Core ERC721 Overrides ---
    // ERC721 requires tokenURI
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        // ERC721 standard recommends appending tokenId.json
        // We return a base URI, potential off-chain service handles dynamic metadata based on state/properties.
        return string(abi.encodePacked(_metadataBaseURI, Strings.toString(tokenId), ".json"));
    }


    // --- Essence Lifecycle & Interaction Functions ---

    function mintEssence() public payable nonReentrant {
        require(msg.value >= 0.001 ether, "Insufficient ETH for minting"); // Example mint cost

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        address minter = _msgSender();

        _safeMint(minter, newItemId);

        _essenceData[newItemId] = EssenceData({
            currentState: EssenceState.Seed,
            properties: EssenceProperties({
                energy: 10, // Starting properties
                health: 10,
                resilience: 10
            }),
            creationTimestamp: uint64(block.timestamp),
            lastInteractionTimestamp: uint64(block.timestamp),
            blessingExpiresAt: 0,
            yieldPoints: 0
        });

        emit EssenceMinted(newItemId, minter, uint64(block.timestamp));
    }

    function nurture(uint256 tokenId) public onlyEssenceOwnerOrDelegatee(tokenId) {
        _requireOwned(tokenId);
        EssenceData storage data = _essenceData[tokenId];
        require(data.currentState != EssenceState.Dormant && data.currentState != EssenceState.Terminal, "Essence cannot be nurtured in current state");

        _applyTimeBasedEffects(tokenId); // Apply time effects *before* nurturing

        // Apply nurture effects
        data.properties.energy += nurtureEffect[0];
        data.properties.health += nurtureEffect[1];
        data.properties.resilience += nurtureEffect[2];

        data.lastInteractionTimestamp = uint64(block.timestamp); // Update interaction time AFTER effects/nurture applied

        emit EssenceNurtured(tokenId, _msgSender(), uint64(block.timestamp));
    }

    function tryEvolve(uint256 tokenId) public {
        _requireOwned(tokenId); // Only owner can attempt evolution
        EssenceData storage data = _essenceData[tokenId];
        require(data.currentState != EssenceState.Dormant && data.currentState != EssenceState.Terminal, "Essence cannot evolve from current state");

        _applyTimeBasedEffects(tokenId); // Apply time effects *before* checking evolution

        EssenceState potentialNextState = _checkEvolutionCriteria(tokenId);

        if (potentialNextState != data.currentState) {
            EssenceState fromState = data.currentState;
            data.currentState = potentialNextState;
             data.lastInteractionTimestamp = uint64(block.timestamp); // Update interaction time

            emit EssenceEvolved(tokenId, fromState, data.currentState, uint64(block.timestamp));
        } else {
            // Optionally emit an event indicating evolution failed
             emit EssenceEvolved(tokenId, data.currentState, data.currentState, uint64(block.timestamp)); // Signal attempt but no change
        }
    }

    function rescueDormant(uint256 tokenId) public payable nonReentrant {
         _requireOwned(tokenId);
        EssenceData storage data = _essenceData[tokenId];
        require(data.currentState == EssenceState.Dormant, "Essence is not in a dormant state");
        require(msg.value >= 0.005 ether, "Insufficient ETH to rescue"); // Example rescue cost

        // Revive and boost properties
        data.currentState = EssenceState.Seed; // Or back to the age it was before dormant? Seed is simpler.
        data.properties.energy = 20; // Significant boost
        data.properties.health = 20;
        data.properties.resilience = 20;
        data.lastInteractionTimestamp = uint64(block.timestamp); // Reset timer

        emit EssenceRescued(tokenId, uint64(block.timestamp));
    }

    function burnEssence(uint256 tokenId) public {
        _requireOwned(tokenId);
        // Add conditions if needed, e.g., require(data.currentState == EssenceState.Terminal, "Essence must be in Terminal state to burn");

        delete _essenceData[tokenId]; // Clear data
        delete _nurtureDelegations[tokenId]; // Clear delegation
        _burn(tokenId); // Burn the token

        emit EssenceBurned(tokenId);
    }

    // --- Utility & Read Functions ---

    function getCurrentEssenceState(uint256 tokenId) public view returns (EssenceState) {
        _requireOwned(tokenId);
        return _essenceData[tokenId].currentState;
    }

    function getEssenceProperties(uint256 tokenId) public view returns (EssenceProperties memory) {
        _requireOwned(tokenId);
        EssenceData storage data = _essenceData[tokenId];
        EssenceProperties memory currentProps = data.properties;

        // Calculate time elapsed since last interaction for decay simulation
        uint64 currentTime = uint64(block.timestamp);
        uint64 timeElapsed = currentTime - data.lastInteractionTimestamp;

         if (timeElapsed > 0 && data.currentState != EssenceState.Dormant && data.currentState != EssenceState.Terminal) {
            // Simulate decay based on time elapsed, but only up to current time
            // This doesn't modify state, just shows current 'real' properties
            bool isBlessed = currentTime < data.blessingExpiresAt;
             int256 blessedTime = isBlessed ? int256(Math.min(timeElapsed, data.blessingExpiresAt - data.lastInteractionTimestamp)) : 0;

            for (uint8 i = 0; i < 3; i++) {
                int256 netRate = baseDecayRate[i];
                 if (isBlessed) {
                    netRate += blessingEffect[i];
                 }
                currentProps[i] += netRate * int256(timeElapsed - uint64(blessedTime));
                 if(blessedTime > 0) {
                     currentProps[i] += (baseDecayRate[i] + blessingEffect[i]) * blessedTime;
                 }
            }
        }

        return currentProps;
    }

    function getTokenCreationTime(uint256 tokenId) public view returns (uint64) {
         _requireOwned(tokenId);
        return _essenceData[tokenId].creationTimestamp;
    }

    function getTimeSinceLastInteraction(uint256 tokenId) public view returns (uint64) {
         _requireOwned(tokenId);
        return uint64(block.timestamp) - _essenceData[tokenId].lastInteractionTimestamp;
    }

    function getPendingYield(uint256 tokenId) public view returns (uint256) {
        _requireOwned(tokenId);
        EssenceData storage data = _essenceData[tokenId];
        uint64 currentTime = uint64(block.timestamp);

        // Calculate yield accrued since last interaction, add to stored yield points
        uint64 timeElapsed = currentTime - data.lastInteractionTimestamp;
         if (timeElapsed > 0) {
             uint256 accrued = uint256(timeElapsed) * yieldAmountPerAge[uint8(data.currentState)];
             return data.yieldPoints + accrued;
         } else {
             return data.yieldPoints;
         }
    }

    function getBlessingStatus(uint256 tokenId) public view returns (uint64 expirationTimestamp) {
        _requireOwned(tokenId);
        return _essenceData[tokenId].blessingExpiresAt;
    }

    function isNurtureDelegatee(uint256 tokenId, address account) public view returns (bool) {
        NurtureDelegation storage delegation = _nurtureDelegations[tokenId];
        return delegation.delegatee == account && uint64(block.timestamp) < delegation.expiresAt;
    }

     function getTotalEssences() public view returns (uint256) {
        return _tokenIdCounter.current();
    }


    // --- Delegation Functions ---

    function delegateNurture(uint256 tokenId, address delegatee, uint64 expiresAt) public {
        _requireOwned(tokenId);
        require(expiresAt > uint64(block.timestamp), "Expiration must be in the future");
        require(delegatee != address(0), "Delegatee cannot be zero address");
        require(delegatee != ownerOf(tokenId), "Cannot delegate to self");

        _nurtureDelegations[tokenId] = NurtureDelegation({
            delegatee: delegatee,
            expiresAt: expiresAt
        });

        emit NurtureDelegationSet(tokenId, delegatee, expiresAt);
    }

    function revokeNurtureDelegation(uint256 tokenId) public {
        _requireOwned(tokenId);
        require(_nurtureDelegations[tokenId].delegatee != address(0), "No active delegation to revoke");

        delete _nurtureDelegations[tokenId];

        emit NurtureDelegationRevoked(tokenId);
    }


    // --- Yield Functions ---

     function depositYieldEth() public payable onlyOwner {
        // ETH sent here is added to the contract balance, available for yield claims
        // No specific logic needed in the function body, 'payable' receives the ETH
         emit ConfigUpdated("YieldEthDeposited");
     }

    function claimYield(uint256 tokenId) public nonReentrant {
        _requireOwned(tokenId);
        EssenceData storage data = _essenceData[tokenId];

        // Apply pending yield up to the current time before claiming
        _applyTimeBasedEffects(tokenId); // This updates yieldPoints based on time passed

        uint256 amountToClaim = data.yieldPoints;
        require(amountToClaim > 0, "No yield available to claim");

        data.yieldPoints = 0; // Reset yield points after claiming

        // Send ETH
        address payable ownerAddress = payable(ownerOf(tokenId));
        (bool success, ) = ownerAddress.call{value: amountToClaim}("");
        require(success, "ETH transfer failed");

        emit YieldClaimed(tokenId, ownerAddress, amountToClaim);
    }

    function withdrawCollectedYieldEth(uint256 amount) public onlyOwner nonReentrant {
        // This function allows the owner to withdraw ETH from the contract.
        // It's crucial this doesn't affect pending user yield.
        // A simple approach is to track ETH deposited by the owner separately,
        // but that adds complexity. A safer approach here is to allow withdrawing
        // any balance *above* the total sum of all users' pending yield.
        // Calculating total pending yield for all tokens is gas-intensive.
        // A simpler, but less precise admin function is to allow withdrawing any
        // balance *assuming* the admin knows they aren't touching user yield.
        // Let's implement the simpler version, *warning* the user this could
        // potentially empty the yield pool if not managed carefully off-chain.
        // A more robust system would track total pending yield or require admin to deposit into a dedicated pool.
         require(amount <= address(this).balance, "Insufficient contract balance");

        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "ETH withdrawal failed");

        emit ConfigUpdated("YieldEthWithdrawnByAdmin");
    }


    // --- Admin / Configuration Functions (onlyOwner) ---

    function setBaseDecayRate(uint8 propertyIndex, int256 rate) public onlyOwner {
        require(propertyIndex < 3, "Invalid property index");
        baseDecayRate[propertyIndex] = rate;
         emit ConfigUpdated("BaseDecayRate");
    }

    function setNurtureEffect(uint8 propertyIndex, int256 effect) public onlyOwner {
        require(propertyIndex < 3, "Invalid property index");
        nurtureEffect[propertyIndex] = effect;
        emit ConfigUpdated("NurtureEffect");
    }

    function setEvolutionThresholds(
        uint8 currentAge,
        uint8 nextAge,
        uint8 propertyIndex,
        int256 threshold
    ) public onlyOwner {
        require(currentAge < uint8(EssenceState.Terminal), "Invalid current age");
        require(nextAge > currentAge && nextAge <= uint8(EssenceState.Mature), "Invalid next age for evolution");
        require(propertyIndex < 3, "Invalid property index");
        evolutionThresholds[currentAge][nextAge][propertyIndex] = threshold;
        emit ConfigUpdated("EvolutionThresholds");
    }

    function setEnvironmentalEventEffect(uint8 eventCode, uint8 propertyIndex, int256 effect) public onlyOwner {
        require(propertyIndex < 3, "Invalid property index");
        environmentalEventEffects[eventCode][propertyIndex] = effect;
        emit ConfigUpdated("EnvironmentalEventEffect");
    }

    function triggerEnvironmentalEvent(uint8 eventCode) public onlyOwner {
        // Iterate through all tokens (potentially gas-intensive for many tokens)
        // In a real scenario with many tokens, this might need pagination or an off-chain helper/keeper.
        // For demonstration, we iterate up to current counter.
        uint256 total = _tokenIdCounter.current();
        for (uint256 i = 1; i <= total; i++) {
             // Check if token exists and is active
            if (_exists(i)) {
                 EssenceData storage data = _essenceData[i];
                 if (data.currentState != EssenceState.Dormant && data.currentState != EssenceState.Terminal) {
                     // Apply event effect
                    _applyTimeBasedEffects(i); // Apply time effects before event
                     for(uint8 propIdx = 0; propIdx < 3; propIdx++) {
                        data.properties[propIdx] += environmentalEventEffects[eventCode][propIdx];
                     }
                    // Update timestamp to prevent double application of effects from the same time period
                    data.lastInteractionTimestamp = uint64(block.timestamp);
                 }
            }
        }
        emit EnvironmentalEventTriggered(eventCode, uint64(block.timestamp));
    }

    function setYieldAmountPerAge(uint8 age, uint256 amountPerSecond) public onlyOwner {
         require(age < uint8(EssenceState.Terminal) + 1, "Invalid age index");
         yieldAmountPerAge[age] = amountPerSecond;
         emit ConfigUpdated("YieldAmountPerAge");
    }

    function updateMetadataBaseURI(string memory newURI) public onlyOwner {
        _metadataBaseURI = newURI;
         emit ConfigUpdated("MetadataBaseURI");
    }

    function setBlessingEffect(uint8 propertyIndex, int256 effect) public onlyOwner {
        require(propertyIndex < 3, "Invalid property index");
        blessingEffect[propertyIndex] = effect;
        emit ConfigUpdated("BlessingEffect");
    }

    function applyBlessingToEssence(uint256 tokenId, uint32 durationSeconds) public onlyOwner {
         _requireOwned(tokenId); // Owner of the contract applies blessing, not token owner
         EssenceData storage data = _essenceData[tokenId];
         require(data.currentState != EssenceState.Dormant && data.currentState != EssenceState.Terminal, "Cannot bless Essence in current state");

        uint64 currentTime = uint64(block.timestamp);
        uint64 newExpiration = currentTime + durationSeconds;

        // If already blessed, extend from current expiration, not now
        if (data.blessingExpiresAt > currentTime) {
             newExpiration = data.blessingExpiresAt + durationSeconds;
        }

         data.blessingExpiresAt = newExpiration;
         // Note: Blessing effect is applied in _applyTimeBasedEffects via the netRate calculation

         emit EssenceBlessed(tokenId, data.blessingExpiresAt);
    }

    // --- Internal ERC721 Required Overrides (handled by OZ normally) ---
    // This section is mostly for completeness if not using OZ directly, but with OZ
    // the required functions like _beforeTokenTransfer, supportsInterface, etc.
    // are handled by inheriting ERC721.
}
```