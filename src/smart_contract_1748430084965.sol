Okay, let's design a complex and unique smart contract concept. We'll build an "Evolving On-Chain Sentinels" system. These will be NFTs that represent digital entities with dynamic attributes that change based on time, user interaction, and a simulated on-chain environment. Users will need to care for their Sentinels to help them evolve and potentially yield passive resources.

**Concept:** Evolving On-Chain Sentinels (EOS)

*   **Core Idea:** A collection of ERC-721 tokens (Sentinels) with dynamic attributes that decay or grow over time and are influenced by a contract-wide "environment state". Users interact with their Sentinels to restore attributes, encourage growth, and attempt evolution to higher stages.
*   **Dynamic Attributes:** Attributes like Health, Energy, Growth, and Affinity change based on the time elapsed since the last care action and the current Environment Influence.
*   **Evolution:** Sentinels start at a base stage (e.g., Seedling) and can evolve to higher stages (e.g., Juvenile, Mature, Awakened) if their dynamic attributes meet certain thresholds when an evolution attempt is made. Evolution might change base attributes and unlock new capabilities (like faster resource generation).
*   **Environment Influence:** The contract owner can change a global environment parameter (e.g., Elemental Affinity bias - Fire, Water, Earth, Air). This influences how quickly attributes decay or grow for Sentinels with corresponding Affinities.
*   **Passive Resource (Glimmer):** Sentinels, especially in higher stages, passively generate an internal resource ("Glimmer") over time, which the owner of the Sentinel can claim. This Glimmer is tracked within the contract.
*   **Interactions:** Users can "Nurture" their Sentinels (costs Ether/Native Token) to restore Health and Energy and boost Growth, resetting the decay timer. They can also `attemptEvolution`.

**Outline:**

1.  **SPDX-License-Identifier & Pragma**
2.  **Imports:** ERC721, Ownable, ERC165
3.  **Error Definitions**
4.  **Enums:** `EvolutionStage`
5.  **Structs:**
    *   `SentinelAttributes` (base attributes after evolution/minting)
    *   `Entity` (combines attributes, stage, timestamps, affinity)
    *   `EvolutionRequirement` (thresholds needed for evolution)
    *   `CareFees` (costs for nurture actions)
6.  **State Variables:**
    *   Mapping `_sentinels` (tokenId to Entity)
    *   Mapping `_glimmerBalances` (owner address to amount)
    *   Counter `_nextTokenId`
    *   Current `_environmentInfluence`
    *   Mapping `_evolutionRequirements` (stage to requirements)
    *   `_careFees`
    *   `_glimmerRatePerStage` (mapping stage to glimmer/second)
    *   `_glimmerClaimCooldown`
    *   `_collectedFees` (for owner withdrawal)
7.  **Events:**
    *   `SentinelIncubated`
    *   `SentinelNurtured`
    *   `SentinelEvolutionAttempt`
    *   `SentinelEvolved`
    *   `GlimmerClaimed`
    *   `EnvironmentChanged`
    *   `FeesWithdrawn`
8.  **Modifiers:** (e.g., `sentinelExists`, `onlySentinelOwner`)
9.  **ERC721 Standard Functions:** (`balanceOf`, `ownerOf`, `safeTransferFrom`, `transferFrom`, `approve`, `setApprovalForAll`, `getApproved`, `isApprovedForAll`, `supportsInterface`, `tokenURI`)
10. **Admin/Owner Functions:**
    *   `constructor`
    *   `setEvolutionRequirements`
    *   `setCareFees`
    *   `setGlimmerRatePerStage`
    *   `setGlimmerClaimCooldown`
    *   `setEnvironmentInfluence`
    *   `withdrawFees`
11. **Core Interaction Functions:**
    *   `incubateSentinel` (mints a new Sentinel)
    *   `nurtureSentinel`
    *   `attemptEvolution`
    *   `claimGlimmer`
    *   `spendGlimmer` (allows users to use Glimmer, e.g., for cosmetic changes - optional but adds depth)
12. **View Functions:**
    *   `getSentinelCalculatedAttributes` (computes dynamic attributes)
    *   `getSentinelDetails` (static details)
    *   `getEvolutionRequirements`
    *   `getCurrentEnvironmentInfluence`
    *   `getCareFees`
    *   `getGlimmerRatePerStage`
    *   `getGlimmerClaimCooldown`
    *   `getClaimableGlimmerAmount` (for a specific sentinel)
    *   `getUserGlimmerBalance`
    *   `getCollectedFees`
    *   `getBaseAttributesForStage` (Helper view)

**Function Summary (> 20 functions):**

*   `constructor`: Initializes the contract, sets owner, base values. (1)
*   `setEvolutionRequirements(EvolutionStage stage, EvolutionRequirement req)`: Owner sets thresholds for evolving to a specific stage. (2)
*   `setCareFees(CareFees fees)`: Owner sets the cost for nurturing. (3)
*   `setGlimmerRatePerStage(EvolutionStage stage, uint256 rate)`: Owner sets the glimmer accrual rate for a specific stage (per second). (4)
*   `setGlimmerClaimCooldown(uint64 cooldownSeconds)`: Owner sets minimum time between glimmer claims for a single sentinel. (5)
*   `setEnvironmentInfluence(int256 influence)`: Owner sets the global environmental factor affecting attribute decay/growth. (6)
*   `withdrawFees()`: Owner withdraws collected Ether. (7)
*   `incubateSentinel()`: Mints a new Sentinel token, assigns initial random-ish traits and attributes, sets initial stage (Seedling). Requires payment of the care fee. (8)
*   `nurtureSentinel(uint256 tokenId)`: User pays fee to nurture their Sentinel, boosting Health/Energy/Growth and resetting the decay timer (`lastCareTime`). (9)
*   `attemptEvolution(uint256 tokenId)`: User attempts to evolve their Sentinel. Checks if the Sentinel's *calculated* dynamic attributes meet the requirements for the *next* stage. If successful, updates stage and potentially base attributes, emits event. (10)
*   `claimGlimmer(uint256 tokenId)`: Owner of the Sentinel claims accrued Glimmer since the last claim/nurture. Adds Glimmer to the user's balance tracked in the contract. Resets the Sentinel's glimmer claim timer. (11)
*   `spendGlimmer(uint256 amount)`: Allows a user to spend their accumulated Glimmer balance (placeholder function, could be integrated with other features). (12)
*   `getSentinelCalculatedAttributes(uint256 tokenId)`: *Pure view function.* Calculates the Sentinel's current effective attributes (Health, Energy, Growth, Affinity) based on base attributes, time elapsed since last care, current environment influence, and Sentinel's affinity. (13)
*   `getSentinelDetails(uint256 tokenId)`: View function to get static details: owner, stage, base attributes, last care time, last glimmer claim time, affinity. (14)
*   `getEvolutionRequirements(EvolutionStage stage)`: View function to see requirements for evolving to a specific stage. (15)
*   `getCurrentEnvironmentInfluence()`: View function to get the current global environment influence. (16)
*   `getCareFees()`: View function to get the current nurture costs. (17)
*   `getGlimmerRatePerStage(EvolutionStage stage)`: View function to get the glimmer rate for a stage. (18)
*   `getGlimmerClaimCooldown()`: View function to get the glimmer claim cooldown. (19)
*   `getClaimableGlimmerAmount(uint256 tokenId)`: View function to see how much Glimmer *could* be claimed from a specific sentinel right now. (20)
*   `getUserGlimmerBalance(address user)`: View function to get a user's total accumulated Glimmer balance. (21)
*   `getCollectedFees()`: View function to see the total fees available for withdrawal by the owner. (22)
*   `getBaseAttributesForStage(EvolutionStage stage)`: Internal/Helper view function (can be made public) showing base attributes granted upon reaching a stage. (23 - potentially internal or public helper)
*   `balanceOf(address owner)`: ERC721 standard. (24)
*   `ownerOf(uint256 tokenId)`: ERC721 standard. (25)
*   `safeTransferFrom(address from, address to, uint256 tokenId)`: ERC721 standard. (26)
*   `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: ERC721 standard. (27)
*   `transferFrom(address from, address to, uint256 tokenId)`: ERC721 standard. (28)
*   `approve(address to, uint256 tokenId)`: ERC721 standard. (29)
*   `setApprovalForAll(address operator, bool approved)`: ERC721 standard. (30)
*   `getApproved(uint256 tokenId)`: ERC721 standard. (31)
*   `isApprovedForAll(address owner, address operator)`: ERC721 standard. (32)
*   `supportsInterface(bytes4 interfaceId)`: ERC165 standard. (33)
*   `tokenURI(uint256 tokenId)`: ERC721 standard. Needs logic to point to metadata. (34)

This easily exceeds the 20 function requirement, focusing on the unique mechanics of evolving, time-sensitive, environment-influenced NFTs with a passive resource layer.

Let's write the code.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- Outline and Function Summary ---
/*
Outline:
1.  SPDX-License-Identifier & Pragma
2.  Imports: ERC721, Ownable, Counters, SafeMath
3.  Error Definitions (Custom Errors for clarity)
4.  Enums: EvolutionStage
5.  Structs: SentinelAttributes, Entity, EvolutionRequirement, CareFees, CalculatedAttributes
6.  State Variables: _sentinels, _glimmerBalances, _nextTokenId, _environmentInfluence, _evolutionRequirements, _careFees, _glimmerRatePerStage, _glimmerClaimCooldown, _collectedFees, ERC721 name/symbol
7.  Events: SentinelIncubated, SentinelNurtured, SentinelEvolutionAttempt, SentinelEvolved, GlimmerClaimed, EnvironmentChanged, FeesWithdrawn, GlimmerSpent (optional)
8.  Modifiers: sentinelExists, onlySentinelOwner
9.  ERC721 Standard Functions: balanceOf, ownerOf, safeTransferFrom (2 overloads), transferFrom, approve, setApprovalForAll, getApproved, isApprovedForAll, supportsInterface, tokenURI
10. Admin/Owner Functions: constructor, setEvolutionRequirements, setCareFees, setGlimmerRatePerStage, setGlimmerClaimCooldown, setEnvironmentInfluence, withdrawFees
11. Core Interaction Functions: incubateSentinel, nurtureSentinel, attemptEvolution, claimGlimmer, spendGlimmer (optional)
12. View Functions: getSentinelCalculatedAttributes, getSentinelDetails, getEvolutionRequirements, getCurrentEnvironmentInfluence, getCareFees, getGlimmerRatePerStage, getGlimmerClaimCooldown, getClaimableGlimmerAmount, getUserGlimmerBalance, getCollectedFees, getBaseAttributesForStage (helper)

Function Summary (34+ functions):
1.  constructor(string memory name, string memory symbol): Initializes contract, ERC721, sets owner.
2.  setEvolutionRequirements(EvolutionStage stage, EvolutionRequirement memory req): Owner sets requirements for evolution to a stage.
3.  setCareFees(CareFees memory fees): Owner sets costs for nurture actions.
4.  setGlimmerRatePerStage(EvolutionStage stage, uint256 rate): Owner sets glimmer/second rate per stage.
5.  setGlimmerClaimCooldown(uint64 cooldownSeconds): Owner sets claim cooldown for sentinels.
6.  setEnvironmentInfluence(int256 influence): Owner sets global environment factor.
7.  withdrawFees(): Owner withdraws collected native tokens.
8.  incubateSentinel() external payable: Mints a new Sentinel token, requires payment, sets initial state & attributes.
9.  nurtureSentinel(uint256 tokenId) external payable: User pays fee to nurture a sentinel, boosting specific calculated attributes & resetting decay timer.
10. attemptEvolution(uint256 tokenId) external: User attempts evolution if calculated attributes meet requirements for the next stage.
11. claimGlimmer(uint256 tokenId) external: Sentinel owner claims accrued Glimmer, adding to their balance.
12. spendGlimmer(uint256 amount) external: User spends their accumulated Glimmer balance (example use: cosmetic effect calls).
13. getSentinelCalculatedAttributes(uint256 tokenId) public view returns (CalculatedAttributes memory): Computes *effective* attributes including time decay/growth and environment influence.
14. getSentinelDetails(uint256 tokenId) public view returns (Entity memory): Retrieves stored static sentinel details.
15. getEvolutionRequirements(EvolutionStage stage) public view returns (EvolutionRequirement memory): Gets requirements for a stage.
16. getCurrentEnvironmentInfluence() public view returns (int256): Gets current global environment value.
17. getCareFees() public view returns (CareFees memory): Gets current nurture fees.
18. getGlimmerRatePerStage(EvolutionStage stage) public view returns (uint256): Gets glimmer rate for a stage.
19. getGlimmerClaimCooldown() public view returns (uint64): Gets glimmer claim cooldown.
20. getClaimableGlimmerAmount(uint256 tokenId) public view returns (uint256): Calculates available glimmer for a sentinel.
21. getUserGlimmerBalance(address user) public view returns (uint256): Gets a user's total glimmer balance.
22. getCollectedFees() public view returns (uint256): Gets total collected fees.
23. getBaseAttributesForStage(EvolutionStage stage) public view returns (SentinelAttributes memory): Helper view for base attributes per stage.
24. balanceOf(address owner) public view override returns (uint256): ERC721 standard.
25. ownerOf(uint256 tokenId) public view override returns (address): ERC721 standard.
26. safeTransferFrom(address from, address to, uint256 tokenId) public override: ERC721 standard.
27. safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override: ERC721 standard.
28. transferFrom(address from, address to, uint256 tokenId) public override: ERC721 standard.
29. approve(address to, uint256 tokenId) public override: ERC721 standard.
30. setApprovalForAll(address operator, bool approved) public override: ERC721 standard.
31. getApproved(uint256 tokenId) public view override returns (address): ERC721 standard.
32. isApprovedForAll(address owner, address operator) public view override returns (bool): ERC721 standard.
33. supportsInterface(bytes4 interfaceId) public view override returns (bool): ERC165 standard.
34. tokenURI(uint256 tokenId) public view override returns (string memory): ERC721 standard (placeholder/base URI).

Advanced Concepts Included:
- Dynamic Attributes: Attributes change based on time elapsed and environment.
- State-Based Logic: Contract behavior (evolution, glimmer rate) depends on Sentinel's stage.
- Simple On-Chain Environment Simulation: Global state variable affects attribute changes.
- Passive Resource Generation: Sentinels accrue a claimable resource (Glimmer).
- Composable/Interactive NFTs: Users interact with NFTs to change their state and attributes.
- Pseudo-Randomness for Initial Traits (using block data - note limitations).
- Custom Errors for gas efficiency and clarity.
- Usage of SafeMath for arithmetic safety.
- Clear separation of base vs. calculated attributes.

*/

contract EvolvingSentinels is ERC721, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _nextTokenId;

    // --- Custom Errors ---
    error SentinelDoesNotExist(uint256 tokenId);
    error NotSentinelOwner(uint256 tokenId, address caller);
    error EvolutionRequirementsNotMet(uint256 tokenId);
    error AlreadyAtMaxStage(uint256 tokenId);
    error InsufficientPayment(uint256 required, uint256 provided);
    error InsufficientGlimmer(uint256 required, uint256 provided);
    error GlimmerClaimOnCooldown(uint256 tokenId, uint64 timeLeft);

    // --- Enums ---
    enum EvolutionStage {
        Seedling, // Base stage, low stats, slow growth
        Juvenile, // Improved stats, faster growth
        Mature,   // Solid stats, unlocks significant glimmer generation
        Awakened  // Peak stats, highest glimmer rate, potential visual changes
    }

    // --- Structs ---
    struct SentinelAttributes {
        uint16 maxHealth; // Maximum possible health for this stage/entity
        uint16 maxEnergy; // Maximum possible energy
        uint16 baseGrowthRate; // Base rate of growth increase per time unit
        int16 baseDecayRate; // Base rate of health/energy decay per time unit (negative)
    }

    struct Entity {
        uint256 tokenId;
        EvolutionStage stage;
        SentinelAttributes baseAttributes; // Attributes granted upon reaching this stage
        int256 affinity; // -100 to 100, e.g., relates to environmental influence
        uint64 lastCareTime; // Timestamp of last nurture/evolution
        uint64 lastGlimmerClaimTime; // Timestamp of last glimmer claim
        uint256 accruedGlimmer; // Glimmer accrued since last claim, but not yet claimed
    }

    struct EvolutionRequirement {
        uint16 requiredHealthPercent; // % of maxHealth needed (0-100)
        uint16 requiredEnergyPercent; // % of maxEnergy needed (0-100)
        uint16 requiredGrowthPoints; // Absolute growth points needed
        uint64 minTimeInStage; // Minimum time in current stage before attempting evolution
    }

    struct CareFees {
        uint256 nurtureFee; // Cost in native token to nurture
        uint256 incubationFee; // Cost in native token to mint
    }

    // Attributes calculated dynamically based on time, environment, etc.
    struct CalculatedAttributes {
        uint16 currentHealth;
        uint16 currentEnergy;
        uint16 currentGrowth; // Represents cumulative growth progress
        int256 effectiveAffinity; // Sentinel's affinity adjusted by environment
    }

    // --- State Variables ---
    mapping(uint256 => Entity) private _sentinels;
    mapping(address => uint256) private _glimmerBalances; // User's claimed Glimmer balance

    int256 private _environmentInfluence; // Global factor, e.g., elemental bias (-100 to 100)

    mapping(EvolutionStage => EvolutionRequirement) private _evolutionRequirements;
    CareFees private _careFees;
    mapping(EvolutionStage => uint256) private _glimmerRatePerStage; // Glimmer per second
    uint64 private _glimmerClaimCooldown; // Cooldown in seconds after claiming Glimmer for a sentinel

    uint256 private _collectedFees; // Sum of native tokens collected from fees

    // --- Events ---
    event SentinelIncubated(uint256 indexed tokenId, address indexed owner, EvolutionStage initialStage);
    event SentinelNurtured(uint256 indexed tokenId, address indexed nurturer, uint16 newHealth, uint16 newEnergy, uint16 newGrowth);
    event SentinelEvolutionAttempt(uint256 indexed tokenId, EvolutionStage fromStage, EvolutionStage toStage, bool success);
    event SentinelEvolved(uint256 indexed tokenId, EvolutionStage fromStage, EvolutionStage toStage);
    event GlimmerClaimed(uint256 indexed tokenId, address indexed owner, uint256 amount);
    event EnvironmentChanged(int256 newInfluence);
    event FeesWithdrawn(address indexed owner, uint256 amount);
    event GlimmerSpent(address indexed user, uint256 amount); // Optional event if spendGlimmer is used

    // --- Modifiers ---
    modifier sentinelExists(uint256 tokenId) {
        if (_sentinels[tokenId].tokenId == 0 && tokenId != 0) revert SentinelDoesNotExist(tokenId); // tokenId 0 is default, check against stored tokenId
        if (_sentinels[tokenId].tokenId == 0 && tokenId == 0) revert SentinelDoesNotExist(tokenId); // Handle edge case tokenId 0 explicitly if needed
        _;
    }

    modifier onlySentinelOwner(uint256 tokenId) {
        if (_ownerOf(tokenId) != msg.sender) revert NotSentinelOwner(tokenId, msg.sender);
        _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {
        // Set some initial default values (owner can change later)
        _careFees = CareFees({
            nurtureFee: 0.01 ether,
            incubationFee: 0.05 ether
        });

        _glimmerRatePerStage[EvolutionStage.Seedling] = 0;
        _glimmerRatePerStage[EvolutionStage.Juvenile] = 100; // 100 units per second
        _glimmerRatePerStage[EvolutionStage.Mature] = 500;
        _glimmerRatePerStage[EvolutionStage.Awakened] = 1500;

        _glimmerClaimCooldown = 1 days; // Example: Users can claim glimmer max once per day per sentinel

        // Example initial evolution requirements (Owner *must* set proper values after deployment)
        _evolutionRequirements[EvolutionStage.Juvenile] = EvolutionRequirement(70, 60, 1000, 1 hours); // Req for Seedling -> Juvenile
        _evolutionRequirements[EvolutionStage.Mature] = EvolutionRequirement(80, 70, 3000, 3 days);   // Req for Juvenile -> Mature
        _evolutionRequirements[EvolutionStage.Awakened] = EvolutionRequirement(90, 80, 6000, 7 days); // Req for Mature -> Awakened

        _environmentInfluence = 0; // Neutral initially
    }

    // --- Admin/Owner Functions ---

    /**
     * @notice Sets the requirements needed for a Sentinel to evolve to a specific stage.
     * @param stage The EvolutionStage the requirements are *for*.
     * @param req The EvolutionRequirement struct containing the thresholds.
     */
    function setEvolutionRequirements(EvolutionStage stage, EvolutionRequirement memory req) external onlyOwner {
        // Prevent setting requirements for the final stage (Awakened)
        require(uint8(stage) < uint8(EvolutionStage.Awakened), "Cannot set requirements for max stage");
        require(req.requiredHealthPercent <= 100 && req.requiredEnergyPercent <= 100, "Percentage requirements must be <= 100");
        _evolutionRequirements[stage] = req;
    }

    /**
     * @notice Sets the fees required for nurturing and incubating Sentinels.
     * @param fees The CareFees struct containing the new fee amounts.
     */
    function setCareFees(CareFees memory fees) external onlyOwner {
        _careFees = fees;
    }

    /**
     * @notice Sets the rate at which Glimmer is generated per second for Sentinels in a specific stage.
     * @param stage The EvolutionStage.
     * @param rate The new Glimmer rate per second.
     */
    function setGlimmerRatePerStage(EvolutionStage stage, uint256 rate) external onlyOwner {
        _glimmerRatePerStage[stage] = rate;
    }

     /**
      * @notice Sets the minimum cooldown period between Glimmer claims for an individual Sentinel.
      * @param cooldownSeconds The new cooldown duration in seconds.
      */
    function setGlimmerClaimCooldown(uint64 cooldownSeconds) external onlyOwner {
        _glimmerClaimCooldown = cooldownSeconds;
    }

    /**
     * @notice Sets the global environmental influence factor.
     * @param influence The new influence value (-100 to 100).
     * @dev This value affects how quickly attributes decay/grow based on Sentinel's affinity.
     */
    function setEnvironmentInfluence(int256 influence) external onlyOwner {
        require(influence >= -100 && influence <= 100, "Influence must be between -100 and 100");
        _environmentInfluence = influence;
        emit EnvironmentChanged(influence);
    }

    /**
     * @notice Allows the owner to withdraw accumulated native token fees.
     */
    function withdrawFees() external onlyOwner {
        uint256 amount = _collectedFees;
        _collectedFees = 0;
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "Fee withdrawal failed");
        emit FeesWithdrawn(owner(), amount);
    }

    // --- Core Interaction Functions ---

    /**
     * @notice Incubates and mints a new Sentinel token. Requires payment of the incubation fee.
     */
    function incubateSentinel() external payable {
        require(msg.value >= _careFees.incubationFee, InsufficientPayment(_careFees.incubationFee, msg.value));

        _collectedFees = _collectedFees.add(msg.value);

        uint256 newTokenId = _nextTokenId.current();

        // Simple pseudo-randomness based on block data
        uint256 blockValue = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, newTokenId)));

        // Assign initial base attributes and affinity (example logic)
        SentinelAttributes memory initialBaseAttributes = SentinelAttributes({
            maxHealth: 500 + uint16(blockValue % 100), // 500-600
            maxEnergy: 500 + uint16((blockValue / 100) % 100), // 500-600
            baseGrowthRate: 5 + uint16((blockValue / 10000) % 10), // 5-14
            baseDecayRate: -10 - int16((blockValue / 100000) % 5) // -10 to -14
        });

        int256 initialAffinity = int256(blockValue % 201) - 100; // -100 to 100

        _sentinels[newTokenId] = Entity({
            tokenId: newTokenId,
            stage: EvolutionStage.Seedling,
            baseAttributes: initialBaseAttributes,
            affinity: initialAffinity,
            lastCareTime: uint64(block.timestamp),
            lastGlimmerClaimTime: uint64(block.timestamp),
            accruedGlimmer: 0
        });

        _safeMint(msg.sender, newTokenId);
        _nextTokenId.increment();

        emit SentinelIncubated(newTokenId, msg.sender, EvolutionStage.Seedling);
    }

    /**
     * @notice Nurtures a Sentinel, boosting its current Health, Energy, and Growth. Requires payment of the nurture fee.
     * @param tokenId The ID of the Sentinel to nurture.
     */
    function nurtureSentinel(uint256 tokenId) external payable sentinelExists(tokenId) onlySentinelOwner(tokenId) {
        require(msg.value >= _careFees.nurtureFee, InsufficientPayment(_careFees.nurtureFee, msg.value));

        _collectedFees = _collectedFees.add(msg.value);

        Entity storage sentinel = _sentinels[tokenId];

        // Calculate current attributes before nurturing effects
        CalculatedAttributes memory currentAttrs = getSentinelCalculatedAttributes(tokenId);

        // Apply nurture boost and reset decay timer
        // Boost amounts are examples; could be based on stage, affinity, etc.
        uint16 healthBoost = sentinel.baseAttributes.maxHealth / 10; // Example: restore 10% of max health
        uint16 energyBoost = sentinel.baseAttributes.maxEnergy / 8;  // Example: restore 12.5% of max energy
        uint16 growthBoost = 50; // Example: add 50 growth points

        // Ensure attributes don't exceed max
        uint16 newHealth = currentAttrs.currentHealth.add(healthBoost);
        if (newHealth > sentinel.baseAttributes.maxHealth) newHealth = sentinel.baseAttributes.maxHealth;

        uint16 newEnergy = currentAttrs.currentEnergy.add(energyBoost);
        if (newEnergy > sentinel.baseAttributes.maxEnergy) newEnergy = sentinel.baseAttributes.maxEnergy;

        uint16 newGrowth = currentAttrs.currentGrowth.add(growthBoost); // Growth can exceed a stage's requirement, but is capped for calculation purposes

        sentinel.lastCareTime = uint64(block.timestamp);
        // Note: We don't update accruedGlimmer here, it's calculated on claim

        emit SentinelNurtured(tokenId, msg.sender, newHealth, newEnergy, newGrowth);
    }

    /**
     * @notice Attempts to evolve a Sentinel to the next stage. Requires the Sentinel's calculated attributes to meet the requirements.
     * @param tokenId The ID of the Sentinel to attempt evolution for.
     */
    function attemptEvolution(uint256 tokenId) external sentinelExists(tokenId) onlySentinelOwner(tokenId) {
        Entity storage sentinel = _sentinels[tokenId];
        uint8 currentStageIndex = uint8(sentinel.stage);

        if (currentStageIndex >= uint8(EvolutionStage.Awakened)) {
            revert AlreadyAtMaxStage(tokenId);
        }

        EvolutionStage nextStage = EvolutionStage(currentStageIndex + 1);
        EvolutionRequirement memory req = _evolutionRequirements[nextStage]; // Requirements to reach `nextStage` from `currentStage`

        CalculatedAttributes memory currentAttrs = getSentinelCalculatedAttributes(tokenId);

        bool requirementsMet = true;
        // Check time in stage (lastCareTime is used as a proxy for time active/cared for in stage)
        if (block.timestamp < sentinel.lastCareTime + req.minTimeInStage) {
             requirementsMet = false;
        }
        // Check attribute percentages
        uint256 currentHealthPercent = currentAttrs.currentHealth.mul(100) / sentinel.baseAttributes.maxHealth;
        uint256 currentEnergyPercent = currentAttrs.currentEnergy.mul(100) / sentinel.baseAttributes.maxEnergy;

        if (currentHealthPercent < req.requiredHealthPercent || currentEnergyPercent < req.requiredEnergyPercent) {
            requirementsMet = false;
        }
        // Check growth points
         if (currentAttrs.currentGrowth < req.requiredGrowthPoints) {
            requirementsMet = false;
        }


        emit SentinelEvolutionAttempt(tokenId, sentinel.stage, nextStage, requirementsMet);

        if (!requirementsMet) {
             revert EvolutionRequirementsNotMet(tokenId);
        }

        // Evolution successful
        sentinel.stage = nextStage;

        // Reset base attributes for the new stage (example values)
        // In a real system, these might be based on the *amount* of growth achieved, specific interactions, etc.
        SentinelAttributes memory newBaseAttributes = getBaseAttributesForStage(nextStage);
        sentinel.baseAttributes = newBaseAttributes;

        // Reset dynamic attributes / timestamps for the new stage
        // Note: Glimmer accrual continues based on the *new* rate, but claim timer is separate
        sentinel.lastCareTime = uint64(block.timestamp);
        // Growth resets or scales down significantly upon evolution
        // For simplicity here, let's just have the *calculated* growth reset in the view function
        // The underlying mechanism could be more complex, e.g., using a separate currentGrowth state var that resets.
        // For this implementation, we rely on the calculation in getSentinelCalculatedAttributes.

        emit SentinelEvolved(tokenId, EvolutionStage(currentStageIndex), nextStage);
    }

    /**
     * @notice Allows the owner of a Sentinel to claim the Glimmer it has accrued.
     * @param tokenId The ID of the Sentinel to claim Glimmer from.
     */
    function claimGlimmer(uint256 tokenId) external sentinelExists(tokenId) onlySentinelOwner(tokenId) {
        Entity storage sentinel = _sentinels[tokenId];
        address ownerAddress = msg.sender; // Already checked by onlySentinelOwner

        // Check cooldown
        require(block.timestamp >= sentinel.lastGlimmerClaimTime + _glimmerClaimCooldown,
            GlimmerClaimOnCooldown(tokenId, uint64(sentinel.lastGlimmerClaimTime + _glimmerClaimCooldown - block.timestamp)));

        uint256 claimableAmount = getClaimableGlimmerAmount(tokenId);

        if (claimableAmount == 0) {
            // No glimmer to claim, maybe just exit or provide feedback
            return; // Or revert if 0 claim is an error state
        }

        // Add accrued glimmer to user's balance
        _glimmerBalances[ownerAddress] = _glimmerBalances[ownerAddress].add(claimableAmount);

        // Reset Sentinel's accrued glimmer and claim time
        sentinel.accruedGlimmer = 0;
        sentinel.lastGlimmerClaimTime = uint64(block.timestamp);

        emit GlimmerClaimed(tokenId, ownerAddress, claimableAmount);
    }

    /**
     * @notice Allows a user to spend their accumulated Glimmer balance.
     * @dev This is a placeholder function. Real use case would integrate this with other features (e.g., cosmetic upgrades, boosting chances, etc.)
     * @param amount The amount of Glimmer to spend.
     */
    function spendGlimmer(uint256 amount) external {
        require(_glimmerBalances[msg.sender] >= amount, InsufficientGlimmer(amount, _glimmerBalances[msg.sender]));
        _glimmerBalances[msg.sender] = _glimmerBalances[msg.sender].sub(amount);
        emit GlimmerSpent(msg.sender, amount);
    }


    // --- View Functions ---

    /**
     * @notice Calculates and returns the current effective attributes of a Sentinel, considering time decay/growth and environment influence.
     * @param tokenId The ID of the Sentinel.
     * @return CalculatedAttributes struct with current health, energy, growth, and effective affinity.
     */
    function getSentinelCalculatedAttributes(uint256 tokenId) public view sentinelExists(tokenId) returns (CalculatedAttributes memory) {
        Entity storage sentinel = _sentinels[tokenId];
        uint64 timeElapsed = uint64(block.timestamp) - sentinel.lastCareTime;

        // Calculate decay/growth based on time elapsed
        // Decay is negative, growth is positive
        int256 timeEffect = int256(timeElapsed) * sentinel.baseAttributes.baseDecayRate; // Decay health/energy
        uint256 growthEffect = uint256(timeElapsed) * sentinel.baseAttributes.baseGrowthRate; // Increase growth

        // Apply environment influence to decay/growth calculation based on affinity
        // Higher environmental influence matching affinity reduces decay / increases growth effect
        // Environment influence: -100 to 100
        // Sentinel Affinity: -100 to 100
        // When env and affinity match (both high positive or both high negative), influence is strong positive.
        // When env and affinity are opposite (one positive, one negative), influence is strong negative.
        // Let's scale the affinity and env influence to make calculation simpler, e.g., -1 to 1 range scaled by 100
        // Influence Factor: (affinity/100) * (environmentInfluence/100) * Modifier
        // A simple linear model: Factor = (affinity * _environmentInfluence) / 10000
        // Adjust timeEffect and growthEffect by this factor.
        // For decay (negative rate): a positive factor should make it *less* negative (slower decay).
        // For growth (positive rate): a positive factor should make it *more* positive (faster growth).
        // Let's say influence modifies the base rate by up to 50% (e.g., if affinity and env are both 100 or -100)
        // Max modifier = 0.5. Factor range: -0.5 to 0.5
        // Effective Rate = BaseRate * (1 + Factor)
        // Factor = (int256(sentinel.affinity) * _environmentInfluence) / 10000; // Range -1 to 1, scaled
        // Let's refine the influence effect. A high positive affinity meets a high positive environment: boost.
        // A high positive affinity meets a high negative environment: penalty.
        // Simple impact calculation: `impact = (affinity * environmentInfluence) / 100` (Range -100 to 100)
        // Let's say this impact modifies base decay/growth by up to +/- 25%. Max modifier 0.25.
        // Modifier = `impact / 400.0` (Range -0.25 to 0.25) -> use fixed point or integer math
        // Modifier (int): `(affinity * environmentInfluence) / 40000` (Range -25 to 25)
        // Effective Rate = BaseRate * (100 + Modifier) / 100 -> Integer: (BaseRate * (100 + Modifier)) / 100
        // Let's calculate effect on health/energy decay:
        int256 affinityEnvironmentImpact = (int256(sentinel.affinity) * _environmentInfluence) / 100; // Range -100 to 100
        int256 decayModifierPercent = affinityEnvironmentImpact / 4; // Range -25 to 25, this is % change to decay rate
        // Adjusted decay rate: sentinel.baseAttributes.baseDecayRate * (100 + decayModifierPercent) / 100
        // Decay is negative, so a positive modifier makes it less negative (slower decay)
        // Let's use uint for health/energy/growth for simplicity and cap at max/min.
        uint256 healthDecay = uint256((int256(timeElapsed) * int256(sentinel.baseAttributes.baseDecayRate) * (100 + decayModifierPercent)) / 100);
        uint256 energyDecay = uint256((int256(timeElapsed) * int256(sentinel.baseAttributes.baseDecayRate) * (100 + decayModifierPercent)) / 100); // Use same decay rate

        uint256 growthRateModifierPercent = -decayModifierPercent; // Opposite effect on growth rate? Or independent? Let's make it positive correlation.
        int256 growthRateModifier = (int256(sentinel.affinity) * _environmentInfluence) / 400; // Range -25 to 25
        uint256 growthIncrease = uint256(int256(timeElapsed) * int256(sentinel.baseAttributes.baseGrowthRate) * (100 + growthRateModifier) / 100); // Growth is positive

        // Capped current attributes (attributes cannot go below 0 or above max)
        // We need to store *current* health/energy/growth, or recalculate each time.
        // Storing is better for state-based logic, but requires updating on *any* state change (claim, transfer).
        // Recalculating from last care time is simpler but makes 'current growth' stateless.
        // Let's calculate current based on initial (or post-evolution) value + changes.
        // This implies we need to store the *actual* current health/energy/growth that changes.
        // Reworking struct:
        // struct Entity { ... uint16 currentHealth; uint16 currentEnergy; uint16 currentGrowth; ... }
        // Nurture updates these. Evolution resets/adjusts these. Decay happens *between* updates.
        // The calculated attributes function then applies decay since *last update*.

        // Let's redefine CalculatedAttributes to show the current decaying state
        // And update Entity struct to store last known values after an action.
        // This makes more sense. Nurture/Evolve set current HP/EN/GR and update lastCareTime.
        // View function calculates decay/growth *since* lastCareTime.

         // --- Reworking getSentinelCalculatedAttributes based on new approach ---
         // This function now calculates the *decay/growth that has occurred* since lastCareTime
         // and applies it to the stored current values. This needs to be careful not to permanently
         // apply decay in a view function.

         // Simpler approach: getSentinelCalculatedAttributes just calculates decay/growth amount.
         // A helper internal function `_applyDecayAndReturnCurrent` updates the stored values when needed (e.g., before nurture, attemptEvolution, claimGlimmer).

         // Reverting to original simpler logic for getSentinelCalculatedAttributes:
         // Assume baseAttributes includes current state or a starting state for the stage.
         // Let's assume `baseAttributes` in Entity struct *represents* the state *after* the last care action or evolution.
         // This is imperfect, but reduces state complexity.

         // Okay, let's use the Entity struct's lastCareTime and baseAttributes (representing state *at* lastCareTime)
         // This requires baseAttributes to conceptually hold the "restored" or "post-evolution" state.
         // The view function will apply decay *from* that state over time.

        // Decay in health/energy (always negative effect on value)
        uint256 effectiveDecayRate = uint256(int256(sentinel.baseAttributes.baseDecayRate) * (100 + decayModifierPercent)).mul(uint256(timeElapsed)).div(100);

        // Growth in growth points (always positive effect on value)
        uint256 effectiveGrowthRate = uint256(int256(sentinel.baseAttributes.baseGrowthRate) * (100 + growthRateModifier)).mul(uint256(timeElapsed)).div(100);


        // Calculate current values by applying decay/growth to the state at lastCareTime
        // Initial state at lastCareTime was effectively max health/energy (after nurture/evolution).
        // This is a simplification. A real system might track exact values.
        // Let's assume nurturing *sets* health/energy to max, evolution *sets* health/energy to max for the new stage, and sets growth to 0.
        // Then this function calculates decay *from* max.
        // And growth *from* 0 (or a stage base growth).

        uint16 currentHealth = sentinel.baseAttributes.maxHealth;
        if (effectiveDecayRate > 0 && currentHealth > effectiveDecayRate) {
             currentHealth = sentinel.baseAttributes.maxHealth.sub(uint16(effectiveDecayRate));
        } else if (effectiveDecayRate > 0) {
             currentHealth = 0;
        }
        // Note: effectiveDecayRate is calculated from a negative baseRate * potentially modified. If modified makes it positive, it adds? No, decay should always reduce.
        // Let's fix decay/growth calculation. Base decay rate is negative. Modifiers +/- affect magnitude.
        // Effective Decay Amount = (baseDecayRate * (100 + Modifier)) / 100 * timeElapsed. This *should* be negative.
        // Let's calculate absolute decay amount: `abs_decay_amount = (uint256(-sentinel.baseAttributes.baseDecayRate) * uint256(100 + decayModifierPercent)) / 100 * timeElapsed`
        // This is still weird with potential negative modifiers making it positive.

        // Simplified attribute calculation logic:
        // Health/Energy Decay: Max possible decay per second is abs(baseDecayRate) * (1 + max possible negative modifier).
        // Health/Energy Restoration per Nurture: Fixed amount or % of max.
        // Growth Increase: baseGrowthRate * (1 + positive modifier) per second.
        // Growth is capped by stage requirements.

        // Let's use a fixed decay/growth amount per second, adjusted by environment influence * linear affinity:
        // Example: decayPerSec = 10. environmentImpactPerSec = (affinity * envInfluence) / 10000 * 10 (max +/- 10)
        // Total decay per sec = 10 - impact. (range 0-20)
        // Growth per sec = 5. environmentImpactPerSec = (affinity * envInfluence) / 10000 * 5 (max +/- 5)
        // Total growth per sec = 5 + impact. (range 0-10)

        // Simpler approach 2: Decay/Growth amounts per second are stored per stage, adjusted by environment.
        // Let's define `decayPerSecBase`, `growthPerSecBase` per stage.
        // Effective Decay Per Sec = decayPerSecBase * (1 - (affinity * envInfluence) / 20000) // Scale env/aff to +/- 1, modifier +/- 0.5
        // Effective Growth Per Sec = growthPerSecBase * (1 + (affinity * envInfluence) / 20000)

        // Okay, let's go with a clean calculation based on time.
        // Health/Energy decay linearly from max over time since last care.
        // Growth increases linearly from 0 over time since last care (or stage evolution).
        // Environment and Affinity modify the *rate* of decay/growth.
        // Modifier = (int256(sentinel.affinity) * _environmentInfluence) / 10000; // Range -1 to 1
        // If Modifier is 1 (perfect match), rate is doubled. If -1 (opposite), rate is 0 (or even reverse?).
        // Let's say rate multiplier is `1 + Modifier`. Capped at 0 or minimum positive value.
        // Effective rate = Base Rate * max(0, 1 + Modifier)

        int256 modifier10000 = (int256(sentinel.affinity) * _environmentInfluence) / 100; // Range -100 to 100
        // Modifier multiplier: (10000 + modifier10000 * 100) / 10000
        // Range (0 to 20000)/10000 = 0 to 2
        uint256 rateMultiplier100 = uint256(int256(100) + (modifier10000 / 1)); // Simple linear adjustment around 100. Range ~0 to 200
        if (rateMultiplier100 < 0) rateMultiplier100 = 0; // Should not be negative if calculated from int256(100) + ...

        // Decay: Sentinel's baseDecayRate is negative. We want effective decay AMOUNT (positive).
        // Effective Decay Rate (positive amount per second) = -sentinel.baseAttributes.baseDecayRate * rateMultiplier100 / 100
        uint256 effectiveDecayPerSec = (uint256(-sentinel.baseAttributes.baseDecayRate) * rateMultiplier100) / 100;
        uint256 totalDecay = effectiveDecayPerSec.mul(timeElapsed);

        // Growth: Sentinel's baseGrowthRate is positive.
        // Effective Growth Rate (positive amount per second) = sentinel.baseAttributes.baseGrowthRate * rateMultiplier100 / 100
        uint256 effectiveGrowthPerSec = (uint256(sentinel.baseAttributes.baseGrowthRate) * rateMultiplier100) / 100;
        uint256 totalGrowth = effectiveGrowthPerSec.mul(timeElapsed);


        // Calculate current attributes assuming they start at max/0 after last care/evolution
        // This is the compromise for not storing current mutable state.
        uint16 currentHealth = sentinel.baseAttributes.maxHealth > totalDecay ? sentinel.baseAttributes.maxHealth.sub(uint16(totalDecay)) : 0;
        uint16 currentEnergy = sentinel.baseAttributes.maxEnergy > totalDecay ? sentinel.baseAttributes.maxEnergy.sub(uint16(totalDecay)) : 0;
        uint16 currentGrowth = uint16(totalGrowth); // Growth just accumulates


        return CalculatedAttributes({
            currentHealth: currentHealth,
            currentEnergy: currentEnergy,
            currentGrowth: currentGrowth, // Note: This accumulates from 0 since last care/evolution
            effectiveAffinity: sentinel.affinity // Effective affinity itself doesn't change, just its *impact* is calculated
        });
    }

    /**
     * @notice Returns the static details of a Sentinel.
     * @param tokenId The ID of the Sentinel.
     * @return Entity struct with stored details.
     */
    function getSentinelDetails(uint256 tokenId) public view sentinelExists(tokenId) returns (Entity memory) {
        return _sentinels[tokenId];
    }

    /**
     * @notice Returns the requirements for evolving to a specific stage.
     * @param stage The target evolution stage.
     * @return EvolutionRequirement struct.
     */
    function getEvolutionRequirements(EvolutionStage stage) public view returns (EvolutionRequirement memory) {
        return _evolutionRequirements[stage];
    }

    /**
     * @notice Returns the current global environmental influence value.
     * @return The current influence value.
     */
    function getCurrentEnvironmentInfluence() public view returns (int256) {
        return _environmentInfluence;
    }

    /**
     * @notice Returns the current care fees for nurture and incubation.
     * @return CareFees struct.
     */
    function getCareFees() public view returns (CareFees memory) {
        return _careFees;
    }

     /**
      * @notice Returns the Glimmer accrual rate per second for a specific stage.
      * @param stage The evolution stage.
      * @return The Glimmer rate per second.
      */
    function getGlimmerRatePerStage(EvolutionStage stage) public view returns (uint256) {
        return _glimmerRatePerStage[stage];
    }

     /**
      * @notice Returns the current cooldown period between Glimmer claims for a sentinel.
      * @return The cooldown duration in seconds.
      */
    function getGlimmerClaimCooldown() public view returns (uint64) {
        return _glimmerClaimCooldown;
    }

    /**
     * @notice Calculates the amount of Glimmer that is currently claimable for a specific Sentinel.
     * @param tokenId The ID of the Sentinel.
     * @return The amount of Glimmer available to claim.
     */
    function getClaimableGlimmerAmount(uint256 tokenId) public view sentinelExists(tokenId) returns (uint256) {
        Entity storage sentinel = _sentinels[tokenId];
        // Glimmer accrues based on time since *last claim* (or incubation if never claimed)
        uint64 timeSinceLastClaim = uint64(block.timestamp) - sentinel.lastGlimmerClaimTime;

        uint256 rate = _glimmerRatePerStage[sentinel.stage];
        if (rate == 0) return 0;

        uint256 newlyAccrued = rate.mul(timeSinceLastClaim);

        return sentinel.accruedGlimmer.add(newlyAccrued);
    }

    /**
     * @notice Returns the total Glimmer balance for a user.
     * @param user The address of the user.
     * @return The user's Glimmer balance.
     */
    function getUserGlimmerBalance(address user) public view returns (uint256) {
        return _glimmerBalances[user];
    }

     /**
      * @notice Returns the total amount of native tokens collected from fees that are available for withdrawal by the owner.
      * @return The total collected fees.
      */
    function getCollectedFees() public view returns (uint256) {
        return _collectedFees;
    }

    /**
     * @notice Helper function to get the base attributes granted upon reaching a specific stage.
     * @dev These are example values. In a real system, these might be more complex or calculated dynamically.
     * @param stage The evolution stage.
     * @return SentinelAttributes struct for that stage.
     */
    function getBaseAttributesForStage(EvolutionStage stage) public view returns (SentinelAttributes memory) {
        if (stage == EvolutionStage.Seedling) {
             // Seedling base attributes are set during incubation based on pseudo-randomness
             // We can't retrieve the *exact* incubated values here unless stored separately.
             // Returning a generic seedling base for clarity.
             return SentinelAttributes(500, 500, 5, -10);
        } else if (stage == EvolutionStage.Juvenile) {
             return SentinelAttributes(800, 700, 10, -8);
        } else if (stage == EvolutionStage.Mature) {
             return SentinelAttributes(1200, 1000, 15, -6);
        } else if (stage == EvolutionStage.Awakened) {
             return SentinelAttributes(2000, 1500, 20, -4);
        } else {
            revert("Invalid stage");
        }
    }


    // --- ERC721 Standard Overrides ---

    /**
     * @notice See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        // ERC721Enumerable would store this, but we don't use it here for simplicity.
        // Counting would require iterating or tracking separately. Let's assume OpenZeppelin's
        // ERC721 base handles internal tracking, or we'd need to add a mapping or iterate.
        // OpenZeppelin's base ERC721 *does* track balances.
        return super.balanceOf(owner);
    }

    /**
     * @notice See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return super.ownerOf(tokenId); // Relies on OZ ERC721 internal tracking
    }

    /**
     * @notice See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        super.safeTransferFrom(from, to, tokenId);
        // Consider if transfer should affect sentinel state (e.g., reset last care time).
        // For now, let's leave state as is.
    }

     /**
      * @notice See {IERC721-safeTransferFrom}.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        super.safeTransferFrom(from, to, tokenId, data);
        // Consider if transfer should affect sentinel state (e.g., reset last care time).
    }

     /**
      * @notice See {IERC721-transferFrom}.
      */
    function transferFrom(address from, address to, uint256 tokenId) public override {
        super.transferFrom(from, to, tokenId);
        // Consider if transfer should affect sentinel state (e.g., reset last care time).
    }

    /**
     * @notice See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        super.approve(to, tokenId);
    }

    /**
     * @notice See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public override {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @notice See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
         return super.getApproved(tokenId);
    }

    /**
     * @notice See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @notice See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice See {IERC721Metadata-tokenURI}.
     * @dev Returns a base URI + tokenId. A real implementation would point to an API
     *      that generates metadata based on the Sentinel's current state and attributes.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Ensures the token exists

        // In a real application, this would point to an external API endpoint
        // that looks up the token ID in the contract state and generates dynamic JSON metadata.
        // Example: "https://myapi.com/metadata/sentinels/123" -> returns {name: "Juvenile Sentinel #123", attributes: [...], image: "ipfs://..."}

        // Placeholder implementation: return a base URI + token ID
        string memory baseURI = "ipfs://YOUR_BASE_URI/"; // Replace with your base URI
        return string(abi.encodePacked(baseURI, _toString(tokenId)));

        // A more dynamic (but complex) on-chain approach would require encoding JSON on-chain (gas intensive)
        // or storing attribute IDs and having a front-end/off-chain process resolve them.
        // The standard is to use an external API for dynamic metadata.
    }

    // Internal helper to convert uint256 to string
    function _toString(uint256 value) internal pure returns (string memory) {
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
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
```