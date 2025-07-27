This smart contract, `AetherForge`, explores a unique blend of dynamic NFTs, resource management, gamified mechanics, and advanced on-chain interactions. It's designed to be a central hub where users can combine various "Elemental Shards" (ERC-1155) and a mystical "Aether" (ERC-20 token managed internally) to forge unique, evolving "Artifacts" (ERC-721). These Artifacts possess dynamic attributes that can change based on user interaction (empowering, attuning) and time (decay). The concept aims to push beyond static NFTs into a realm of interactive, composable, and resource-driven digital assets.

---

## AetherForge Contract Outline and Function Summary

**Contract Name:** `AetherForge`

**Core Concept:** A decentralized forge where users combine ERC-1155 Elemental Shards and Aether (ERC-20) to create dynamic, evolving ERC-721 Artifacts. Artifacts can be empowered, attuned, and decay over time, creating a rich interactive ecosystem.

**Key Features:**
*   **Dynamic NFTs (Artifacts):** ERC-721 tokens with mutable properties based on on-chain actions and time.
*   **Resource Management:** Utilizes a custom ERC-20 (Aether) and ERC-1155 (Elemental Shards) as crafting components.
*   **Gamified Mechanics:** Forging, empowerment, attunement, refinement, extraction, decay, repair.
*   **Parameterization & Governance Hooks:** Adjustable crafting recipes, costs, and ratios by an owner/DAO (via `Ownable`).
*   **Composability:** Designed to interact with standard token interfaces.

---

### Function Categories & Summaries:

**I. Core Asset Management & Creation (Aether & Shards)**

1.  **`constructor()`:** Initializes the contract, setting up the owner, Aether token details, and initial shard types.
2.  **`mintAether(address recipient, uint256 amount)`:** Mints new Aether tokens and assigns them to a recipient. (Owner-only for initial distribution/treasury management).
3.  **`batchMintShards(address recipient, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data)`:** Mints multiple types of Elemental Shards for a recipient. (Owner-only for distribution/initial supply).
4.  **`setAetherBurnRate(uint256 _rate)`:** Sets the percentage of Aether that is burned during certain operations (e.g., forging, repair). (Owner-only).

**II. Artifact Lifecycle & Dynamics**

5.  **`forgeArtifact(uint256[] calldata shardIds, uint256[] calldata shardAmounts)`:** The primary function. Consumes Aether and specified Elemental Shards to mint a new ERC-721 Artifact with dynamic properties determined by the shard combination.
6.  **`empowerArtifact(uint256 artifactId, uint256 aetherAmount)`:** Allows an Artifact owner to stake Aether with their Artifact, temporarily boosting its attributes and potentially earning rewards.
7.  **`disempowerArtifact(uint256 artifactId)`:** Allows an Artifact owner to unstake previously empowered Aether, removing the attribute boost.
8.  **`attuneArtifact(uint256 artifactId, uint8 newElementalAlignment)`:** Changes an Artifact's primary elemental alignment, potentially altering its properties or future interactions, at a cost of Aether and specific Shards.
9.  **`refineShards(uint256 sourceShardId, uint256 sourceAmount, uint256 targetShardId)`:** Allows users to combine lower-tier Elemental Shards into higher-tier ones, or convert between elements, based on predefined ratios.
10. **`extractEssence(uint256 artifactId)`:** A "disenchant" function. Allows an Artifact owner to burn their Artifact, recovering a portion of the Aether and Elemental Shards used in its creation.
11. **`decayArtifact(uint256 artifactId)`:** Simulates time-based degradation of an Artifact's properties. This function can be called by anyone (gas incentive via Aether) or triggered internally.
12. **`repairArtifact(uint256 artifactId)`:** Allows an Artifact owner to spend Aether to restore decayed attributes of their Artifact.

**III. Query & Information**

13. **`getArtifactProperties(uint256 artifactId)`:** Retrieves all current dynamic properties (power, resilience, fortune, alignment, decay status, etc.) of a given Artifact.
14. **`calculateForgingCost(uint256[] calldata shardIds, uint256[] calldata shardAmounts)`:** Estimates the Aether cost for a given shard combination for forging.
15. **`getArtifactPower(uint256 artifactId)`:** Returns the current effective 'power' of an Artifact, considering base attributes and empowerment.
16. **`getRefinementRatio(uint256 sourceShardId, uint256 targetShardId)`:** Returns the conversion ratio for refining shards.
17. **`supportsInterface(bytes4 interfaceId)`:** Standard ERC-165 function to check if the contract supports a given interface (ERC-721, ERC-1155, ERC-20, etc.).

**IV. Administrative & Governance Hooks**

18. **`setForgingRecipe(uint8 elementIndex, uint256 baseCost, uint256[] calldata requiredShards, uint256[] calldata requiredAmounts)`:** Allows the owner to define or update recipes for forging different types of Artifacts based on elemental combinations.
19. **`setElementalAttributeWeights(uint8 element, uint256 powerWeight, uint256 resilienceWeight, uint256 fortuneWeight)`:** Allows the owner to define how different Elemental Shards contribute to an Artifact's attributes.
20. **`setDecayRate(uint256 _newDecayRate)`:** Adjusts the rate at which Artifacts decay over time. (Owner-only).
21. **`setEmpowermentYieldRate(uint256 _newRate)`:** Adjusts the yield rate for Aether staked with Artifacts. (Owner-only).
22. **`setRefinementRatio(uint256 sourceShardId, uint256 targetShardId, uint256 ratio)`:** Sets conversion ratios for shard refinement. (Owner-only).
23. **`toggleForgingEnabled(bool _enabled)`:** Pauses or unpauses the forging functionality. (Owner-only).
24. **`withdrawERC20(address tokenAddress, address recipient)`:** Allows the owner to withdraw any accidentally sent ERC-20 tokens from the contract (excluding Aether, which is managed internally).
25. **`proposeDynamicRuleChange(bytes32 ruleKey, bytes calldata newData)`:** A more advanced function: allows the owner/governance to propose a change to a dynamic rule (e.g., a complex interaction coefficient, a new hidden forging modifier). Requires an off-chain vote/approval mechanism.
26. **`applyDynamicRuleChange(bytes32 ruleKey)`:** Applies a previously proposed rule change after a timelock or vote. (Owner-only for this example, in a full DAO it would be a result of a vote).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; // For internal Aether token
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// --- AetherForge Contract Outline and Function Summary ---
//
// Contract Name: AetherForge
// Core Concept: A decentralized forge where users combine ERC-1155 Elemental Shards and Aether (ERC-20)
//               to create dynamic, evolving ERC-721 Artifacts. Artifacts can be empowered, attuned,
//               and decay over time, creating a rich interactive ecosystem.
//
// Key Features:
// *   Dynamic NFTs (Artifacts): ERC-721 tokens with mutable properties based on on-chain actions and time.
// *   Resource Management: Utilizes a custom ERC-20 (Aether) and ERC-1155 (Elemental Shards) as crafting components.
// *   Gamified Mechanics: Forging, empowerment, attunement, refinement, extraction, decay, repair.
// *   Parameterization & Governance Hooks: Adjustable crafting recipes, costs, and ratios by an owner/DAO (via `Ownable`).
// *   Composability: Designed to interact with standard token interfaces.
//
// --- Function Categories & Summaries: ---
//
// I. Core Asset Management & Creation (Aether & Shards)
// 1.  constructor(): Initializes the contract, setting up the owner, Aether token details, and initial shard types.
// 2.  mintAether(address recipient, uint256 amount): Mints new Aether tokens and assigns them to a recipient. (Owner-only).
// 3.  batchMintShards(address recipient, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data): Mints multiple types of Elemental Shards for a recipient. (Owner-only).
// 4.  setAetherBurnRate(uint256 _rate): Sets the percentage of Aether that is burned during certain operations. (Owner-only).
//
// II. Artifact Lifecycle & Dynamics
// 5.  forgeArtifact(uint256[] calldata shardIds, uint256[] calldata shardAmounts): The primary function. Consumes Aether and specified Elemental Shards to mint a new ERC-721 Artifact with dynamic properties.
// 6.  empowerArtifact(uint256 artifactId, uint256 aetherAmount): Allows an Artifact owner to stake Aether with their Artifact, temporarily boosting its attributes.
// 7.  disempowerArtifact(uint256 artifactId): Allows an Artifact owner to unstake previously empowered Aether.
// 8.  attuneArtifact(uint256 artifactId, uint8 newElementalAlignment): Changes an Artifact's primary elemental alignment, at a cost.
// 9.  refineShards(uint256 sourceShardId, uint256 sourceAmount, uint256 targetShardId): Allows users to combine lower-tier Shards into higher-tier ones.
// 10. extractEssence(uint256 artifactId): A "disenchant" function. Burns an Artifact, recovering a portion of materials.
// 11. decayArtifact(uint256 artifactId): Simulates time-based degradation of an Artifact's properties.
// 12. repairArtifact(uint256 artifactId): Allows an Artifact owner to spend Aether to restore decayed attributes.
//
// III. Query & Information
// 13. getArtifactProperties(uint256 artifactId): Retrieves all current dynamic properties of a given Artifact.
// 14. calculateForgingCost(uint256[] calldata shardIds, uint256[] calldata shardAmounts): Estimates the Aether cost for a given shard combination.
// 15. getArtifactPower(uint256 artifactId): Returns the current effective 'power' of an Artifact.
// 16. getRefinementRatio(uint256 sourceShardId, uint256 targetShardId): Returns the conversion ratio for refining shards.
// 17. supportsInterface(bytes4 interfaceId): Standard ERC-165 function.
//
// IV. Administrative & Governance Hooks
// 18. setForgingRecipe(uint8 elementIndex, uint256 baseCost, uint256[] calldata requiredShards, uint256[] calldata requiredAmounts): Allows the owner to define or update recipes for forging.
// 19. setElementalAttributeWeights(uint8 element, uint256 powerWeight, uint256 resilienceWeight, uint256 fortuneWeight): Allows the owner to define how different elements contribute to attributes.
// 20. setDecayRate(uint256 _newDecayRate): Adjusts the rate at which Artifacts decay over time. (Owner-only).
// 21. setEmpowermentYieldRate(uint256 _newRate): Adjusts the yield rate for Aether staked with Artifacts. (Owner-only).
// 22. setRefinementRatio(uint256 sourceShardId, uint256 targetShardId, uint256 ratio): Sets conversion ratios for shard refinement. (Owner-only).
// 23. toggleForgingEnabled(bool _enabled): Pauses or unpauses the forging functionality. (Owner-only).
// 24. withdrawERC20(address tokenAddress, address recipient): Allows the owner to withdraw any accidentally sent ERC-20 tokens.
// 25. proposeDynamicRuleChange(bytes32 ruleKey, bytes calldata newData): Proposes a change to a dynamic rule (for DAO integration).
// 26. applyDynamicRuleChange(bytes32 ruleKey): Applies a previously proposed rule change.
// --- End of Outline ---

// Define Elemental Alignments
enum ElementalAlignment { NONE, FIRE, WATER, EARTH, AIR, SPIRIT, VOID }

// Internal ERC-20 Token for Aether
contract AetherToken is ERC20, Ownable {
    constructor() ERC20("Aether", "AETH") {
        // No initial supply, minting handled by AetherForge
    }

    // Owner can mint Aether, AetherForge will be the owner
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}


contract AetherForge is ERC721, ERC1155, ERC721Burnable, Ownable, ReentrancyGuard, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---

    // Aether Token instance (ERC-20, internal to this contract)
    AetherToken public aether;

    // Artifact ID Counter
    Counters.Counter private _artifactIds;

    // Artifact Properties
    struct ArtifactProperties {
        uint256 power;         // Base power attribute
        uint256 resilience;    // Base resilience attribute
        uint256 fortune;       // Base fortune attribute (for future mechanics)
        uint8 elementalAlignment; // Corresponds to ElementalAlignment enum
        uint256 creationTime;  // Timestamp of creation
        uint256 lastEmpowerTime; // Timestamp of last empowerment for yield calculation
        uint256 lastDecayTime; // Timestamp of last decay calculation
        uint256 decayLevel;    // How much the artifact has decayed
    }

    mapping(uint256 => ArtifactProperties) public artifactData;
    mapping(uint256 => uint256) public artifactStakedAether; // Artifact ID => Aether amount staked

    // Forging Recipes: elementalAlignment => {baseCost, requiredShardIds, requiredShardAmounts}
    struct ForgingRecipe {
        uint256 baseAetherCost;
        uint256[] requiredShardIds;
        uint256[] requiredShardAmounts;
        // Future: could add more complex outcome parameters
    }
    mapping(uint8 => ForgingRecipe) public forgingRecipes; // Maps ElementalAlignment enum index to its recipe

    // Shard ID Definitions (example - extend as needed)
    uint256 public constant SHARD_FIRE = 1;
    uint256 public constant SHARD_WATER = 2;
    uint256 public constant SHARD_EARTH = 3;
    uint256 public constant SHARD_AIR = 4;
    uint256 public constant SHARD_SPIRIT = 5;
    uint256 public constant SHARD_VOID = 6;
    // Add more complex shards if desired, e.g., SHARD_MYSTIC_FIRE = 101;

    // Elemental Attribute Weights: elementalAlignment => {power, resilience, fortune}
    // Used to determine how elemental composition influences base artifact attributes
    struct AttributeWeights {
        uint256 powerWeight;
        uint256 resilienceWeight;
        uint256 fortuneWeight;
    }
    mapping(uint8 => AttributeWeights) public elementalAttributeWeights;

    // Refinement Ratios: sourceShardId => targetShardId => ratio (e.g., 3 source for 1 target)
    mapping(uint256 => mapping(uint256 => uint256)) public refinementRatios;

    // Global Parameters
    uint256 public decayRatePerDay = 10; // Percentage points per day
    uint256 public empowermentYieldRate = 50; // Aether yield per 1000 staked Aether per day (scaled by time)
    uint256 public aetherBurnRate = 10; // Percentage of Aether burned during certain operations (e.g., forging cost)

    // Dynamic Rule Changes (for advanced governance / future features)
    struct ProposedRuleChange {
        bytes data;
        uint256 proposalTime;
        bool applied;
    }
    mapping(bytes32 => ProposedRuleChange) public proposedRuleChanges;
    uint256 public constant RULE_CHANGE_TIMELOCK = 7 days; // Example timelock

    // --- Events ---
    event ArtifactForged(address indexed owner, uint256 indexed artifactId, uint8 elementalAlignment, uint256 power, uint256 resilience);
    event ArtifactEmpowered(uint256 indexed artifactId, address indexed staker, uint256 amountStaked);
    event ArtifactDisempowered(uint256 indexed artifactId, address indexed staker, uint256 amountUnstaked, uint256 yieldEarned);
    event ArtifactAttuned(uint256 indexed artifactId, uint8 oldAlignment, uint8 newAlignment);
    event ShardsRefined(address indexed refiner, uint256 sourceShardId, uint256 sourceAmount, uint256 targetShardId, uint256 targetAmount);
    event EssenceExtracted(uint256 indexed artifactId, address indexed recipient, uint256 aetherRecovered, uint256[] shardIdsRecovered, uint256[] shardAmountsRecovered);
    event ArtifactDecayed(uint256 indexed artifactId, uint256 newDecayLevel);
    event ArtifactRepaired(uint256 indexed artifactId, uint256 aetherCost, uint256 newDecayLevel);
    event ForgingRecipeUpdated(uint8 indexed alignment, uint256 baseCost);
    event ElementalAttributeWeightsUpdated(uint8 indexed element, uint256 powerWeight, uint256 resilienceWeight);
    event RefinementRatioUpdated(uint256 indexed sourceShard, uint256 indexed targetShard, uint256 ratio);
    event DynamicRuleChangeProposed(bytes32 indexed ruleKey, bytes data);
    event DynamicRuleChangeApplied(bytes32 indexed ruleKey, bytes data);

    // --- Constructor ---
    constructor()
        ERC721("AetherForge Artifact", "AFA")
        ERC1155("https://aetherforge.xyz/artifacts/{id}.json") // Base URI for Artifacts
        Ownable(msg.sender)
        Pausable()
    {
        aether = new AetherToken();
        aether.transferOwnership(address(this)); // AetherForge contract becomes owner of AetherToken

        // Initial default forging recipe (e.g., for 'NONE' alignment)
        forgingRecipes[uint8(ElementalAlignment.NONE)] = ForgingRecipe({
            baseAetherCost: 1000 * 10**18, // 1000 Aether
            requiredShardIds: new uint256[](0),
            requiredShardAmounts: new uint256[](0)
        });

        // Initial default attribute weights
        elementalAttributeWeights[uint8(ElementalAlignment.NONE)] = AttributeWeights(10, 10, 10);
        elementalAttributeWeights[uint8(ElementalAlignment.FIRE)] = AttributeWeights(15, 8, 7);
        elementalAttributeWeights[uint8(ElementalAlignment.WATER)] = AttributeWeights(8, 15, 7);
        elementalAttributeWeights[uint8(ElementalAlignment.EARTH)] = AttributeWeights(10, 12, 8);
        elementalAttributeWeights[uint8(ElementalAlignment.AIR)] = AttributeWeights(12, 10, 8);
        elementalAttributeWeights[uint8(ElementalAlignment.SPIRIT)] = AttributeWeights(10, 10, 15);
        elementalAttributeWeights[uint8(ElementalAlignment.VOID)] = AttributeWeights(20, 20, 20); // Potentially rare/powerful

        // Example refinement ratio: 3 Fire Shards -> 1 Spirit Shard
        refinementRatios[SHARD_FIRE][SHARD_SPIRIT] = 3;
    }

    // --- I. Core Asset Management & Creation (Aether & Shards) ---

    /// @notice Mints new Aether tokens for a recipient. Owner-only.
    /// @param recipient The address to receive the Aether.
    /// @param amount The amount of Aether to mint.
    function mintAether(address recipient, uint256 amount) external onlyOwner {
        aether.mint(recipient, amount);
    }

    /// @notice Mints multiple types of Elemental Shards for a recipient. Owner-only.
    /// @param recipient The address to receive the shards.
    /// @param ids An array of shard IDs to mint.
    /// @param amounts An array of corresponding amounts for each shard ID.
    /// @param data Additional data (can be empty).
    function batchMintShards(address recipient, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external onlyOwner {
        _mintBatch(recipient, ids, amounts, data);
    }

    /// @notice Sets the percentage of Aether that is burned during operations. Owner-only.
    /// @param _rate The new burn rate (e.g., 10 for 10%).
    function setAetherBurnRate(uint256 _rate) external onlyOwner {
        require(_rate <= 100, "Burn rate cannot exceed 100%");
        aetherBurnRate = _rate;
        emit ForgingRecipeUpdated(0, _rate); // Re-use event for parameter update
    }

    // --- II. Artifact Lifecycle & Dynamics ---

    /// @notice The primary function to forge a new ERC-721 Artifact.
    /// @param shardIds An array of Elemental Shard IDs to use in forging.
    /// @param shardAmounts An array of corresponding amounts for each shard ID.
    /// @dev Consumes Aether and specified Elemental Shards.
    /// @return The ID of the newly forged Artifact.
    function forgeArtifact(uint256[] calldata shardIds, uint256[] calldata shardAmounts) external nonReentrant whenNotPaused returns (uint256) {
        require(shardIds.length == shardAmounts.length, "Mismatched shard arrays");
        require(shardIds.length > 0, "Must use at least one shard for forging");

        // Determine the primary elemental alignment based on highest shard count/value
        uint8 primaryAlignment = uint8(ElementalAlignment.NONE);
        uint256 maxShardInfluence = 0;
        uint256 totalElementalValue = 0;

        for (uint256 i = 0; i < shardIds.length; i++) {
            uint256 currentShardId = shardIds[i];
            uint256 currentShardAmount = shardAmounts[i];

            // Basic mapping of shard ID to elemental alignment for simplicity
            // In a real scenario, this would be more complex, e.g., mapping to tiers/elements.
            uint8 currentElement;
            if (currentShardId == SHARD_FIRE) currentElement = uint8(ElementalAlignment.FIRE);
            else if (currentShardId == SHARD_WATER) currentElement = uint8(ElementalAlignment.WATER);
            else if (currentShardId == SHARD_EARTH) currentElement = uint8(ElementalAlignment.EARTH);
            else if (currentShardId == SHARD_AIR) currentElement = uint8(ElementalAlignment.AIR);
            else if (currentShardId == SHARD_SPIRIT) currentElement = uint8(ElementalAlignment.SPIRIT);
            else if (currentShardId == SHARD_VOID) currentElement = uint8(ElementalAlignment.VOID);
            else revert("Invalid Shard ID provided"); // Or handle unknown shards gracefully

            uint256 influence = currentShardAmount.mul(currentShardId); // Simple influence calculation

            if (influence > maxShardInfluence) {
                maxShardInfluence = influence;
                primaryAlignment = currentElement;
            }
            totalElementalValue = totalElementalValue.add(influence);
        }

        ForgingRecipe storage recipe = forgingRecipes[primaryAlignment];
        require(recipe.baseAetherCost > 0, "No valid forging recipe for this alignment");

        uint256 totalAetherCost = calculateForgingCost(shardIds, shardAmounts);

        // Deduct Aether
        require(aether.balanceOf(msg.sender) >= totalAetherCost, "Insufficient Aether balance");
        aether.transferFrom(msg.sender, address(this), totalAetherCost);

        // Burn a portion of Aether
        uint256 aetherToBurn = totalAetherCost.mul(aetherBurnRate).div(100);
        if (aetherToBurn > 0) {
            aether.burn(address(this), aetherToBurn);
        }

        // Consume Shards
        _burnBatch(msg.sender, shardIds, shardAmounts);

        // Mint new Artifact
        _artifactIds.increment();
        uint256 newArtifactId = _artifactIds.current();
        _safeMint(msg.sender, newArtifactId);

        // Determine Artifact Properties
        AttributeWeights storage weights = elementalAttributeWeights[primaryAlignment];
        uint256 basePower = weights.powerWeight.mul(totalElementalValue).div(100);
        uint256 baseResilience = weights.resilienceWeight.mul(totalElementalValue).div(100);
        uint256 baseFortune = weights.fortuneWeight.mul(totalElementalValue).div(100);

        artifactData[newArtifactId] = ArtifactProperties({
            power: basePower,
            resilience: baseResilience,
            fortune: baseFortune,
            elementalAlignment: primaryAlignment,
            creationTime: block.timestamp,
            lastEmpowerTime: 0,
            lastDecayTime: block.timestamp,
            decayLevel: 0
        });

        emit ArtifactForged(msg.sender, newArtifactId, primaryAlignment, basePower, baseResilience);
        return newArtifactId;
    }

    /// @notice Allows an Artifact owner to stake Aether with their Artifact, temporarily boosting its attributes.
    /// @param artifactId The ID of the Artifact to empower.
    /// @param aetherAmount The amount of Aether to stake.
    function empowerArtifact(uint256 artifactId, uint256 aetherAmount) external nonReentrant whenNotPaused {
        require(_exists(artifactId), "Artifact does not exist");
        require(ownerOf(artifactId) == msg.sender, "Not artifact owner");
        require(aetherAmount > 0, "Amount must be greater than zero");

        // Calculate accrued yield from previous empowerment if any
        uint256 currentStaked = artifactStakedAether[artifactId];
        if (currentStaked > 0) {
            _distributeEmpowermentYield(artifactId, msg.sender);
        }

        aether.transferFrom(msg.sender, address(this), aetherAmount);
        artifactStakedAether[artifactId] = artifactStakedAether[artifactId].add(aetherAmount);
        artifactData[artifactId].lastEmpowerTime = block.timestamp; // Update last empower time for new calculation cycle

        emit ArtifactEmpowered(artifactId, msg.sender, aetherAmount);
    }

    /// @notice Allows an Artifact owner to unstake previously empowered Aether.
    /// @param artifactId The ID of the Artifact to disempower.
    function disempowerArtifact(uint256 artifactId) external nonReentrant whenNotPaused {
        require(_exists(artifactId), "Artifact does not exist");
        require(ownerOf(artifactId) == msg.sender, "Not artifact owner");
        require(artifactStakedAether[artifactId] > 0, "No Aether staked with this artifact");

        uint256 stakedAmount = artifactStakedAether[artifactId];
        uint256 yieldEarned = _distributeEmpowermentYield(artifactId, msg.sender);

        artifactStakedAether[artifactId] = 0; // Reset staked amount
        artifactData[artifactId].lastEmpowerTime = 0; // Reset last empower time

        // Transfer back the staked Aether
        aether.transfer(msg.sender, stakedAmount);

        emit ArtifactDisempowered(artifactId, msg.sender, stakedAmount, yieldEarned);
    }

    /// @dev Internal function to calculate and distribute empowerment yield.
    /// @param artifactId The ID of the Artifact.
    /// @param recipient The address to receive the yield.
    /// @return The amount of Aether yield distributed.
    function _distributeEmpowermentYield(uint256 artifactId, address recipient) internal returns (uint256) {
        uint256 currentStaked = artifactStakedAether[artifactId];
        if (currentStaked == 0 || artifactData[artifactId].lastEmpowerTime == 0) {
            return 0;
        }

        uint256 duration = block.timestamp.sub(artifactData[artifactId].lastEmpowerTime);
        uint256 yieldAmount = currentStaked.mul(empowermentYieldRate).mul(duration).div(1 days).div(1000); // 1000 scale for percentage

        if (yieldAmount > 0) {
            aether.mint(recipient, yieldAmount); // Mint new Aether as yield
            artifactData[artifactId].lastEmpowerTime = block.timestamp;
            return yieldAmount;
        }
        return 0;
    }

    /// @notice Changes an Artifact's primary elemental alignment.
    /// @param artifactId The ID of the Artifact to attune.
    /// @param newElementalAlignment The new elemental alignment (from ElementalAlignment enum).
    /// @dev Costs Aether and specific Shards (implementation for cost simplified here).
    function attuneArtifact(uint256 artifactId, uint8 newElementalAlignment) external nonReentrant whenNotPaused {
        require(_exists(artifactId), "Artifact does not exist");
        require(ownerOf(artifactId) == msg.sender, "Not artifact owner");
        require(newElementalAlignment != uint8(ElementalAlignment.NONE), "Cannot attune to NONE");
        require(newElementalAlignment != artifactData[artifactId].elementalAlignment, "Artifact already has this alignment");
        require(newElementalAlignment <= uint8(ElementalAlignment.VOID), "Invalid elemental alignment");

        // Example cost: 100 Aether + 1 of the new element's shard
        uint256 attunementCost = 500 * 10**18;
        uint256 requiredShardId;
        if (newElementalAlignment == uint8(ElementalAlignment.FIRE)) requiredShardId = SHARD_FIRE;
        else if (newElementalAlignment == uint8(ElementalAlignment.WATER)) requiredShardId = SHARD_WATER;
        else if (newElementalAlignment == uint8(ElementalAlignment.EARTH)) requiredShardId = SHARD_EARTH;
        else if (newElementalAlignment == uint8(ElementalAlignment.AIR)) requiredShardId = SHARD_AIR;
        else if (newElementalAlignment == uint8(ElementalAlignment.SPIRIT)) requiredShardId = SHARD_SPIRIT;
        else if (newElementalAlignment == uint8(ElementalAlignment.VOID)) requiredShardId = SHARD_VOID;
        else revert("Invalid attunement target element");

        require(aether.balanceOf(msg.sender) >= attunementCost, "Insufficient Aether for attunement");
        require(balanceOf(msg.sender, requiredShardId) >= 1, "Insufficient specific shard for attunement");

        aether.transferFrom(msg.sender, address(this), attunementCost);
        _burn(msg.sender, requiredShardId, 1);

        uint8 oldAlignment = artifactData[artifactId].elementalAlignment;
        artifactData[artifactId].elementalAlignment = newElementalAlignment;

        // Optionally, modify artifact stats based on new alignment
        AttributeWeights storage newWeights = elementalAttributeWeights[newElementalAlignment];
        // This is a simplistic recalculation. A real system might involve complex blending or a reset.
        artifactData[artifactId].power = artifactData[artifactId].power.add(newWeights.powerWeight).div(2);
        artifactData[artifactId].resilience = artifactData[artifactId].resilience.add(newWeights.resilienceWeight).div(2);
        artifactData[artifactId].fortune = artifactData[artifactId].fortune.add(newWeights.fortuneWeight).div(2);

        emit ArtifactAttuned(artifactId, oldAlignment, newElementalAlignment);
    }

    /// @notice Allows users to combine lower-tier Elemental Shards into higher-tier ones, or convert between elements.
    /// @param sourceShardId The ID of the shard to consume.
    /// @param sourceAmount The amount of source shards to consume.
    /// @param targetShardId The ID of the shard to produce.
    function refineShards(uint256 sourceShardId, uint256 sourceAmount, uint256 targetShardId) external nonReentrant whenNotPaused {
        require(sourceAmount > 0, "Source amount must be greater than zero");
        require(sourceShardId != targetShardId, "Source and target shards cannot be the same");
        uint256 ratio = refinementRatios[sourceShardId][targetShardId];
        require(ratio > 0, "No defined refinement ratio for these shards");
        require(balanceOf(msg.sender, sourceShardId) >= sourceAmount, "Insufficient source shards");
        require(sourceAmount % ratio == 0, "Source amount must be a multiple of the refinement ratio");

        uint256 targetAmount = sourceAmount.div(ratio);

        _burn(msg.sender, sourceShardId, sourceAmount);
        _mint(msg.sender, targetShardId, targetAmount, "");

        emit ShardsRefined(msg.sender, sourceShardId, sourceAmount, targetShardId, targetAmount);
    }

    /// @notice Burns an Artifact and recovers a portion of the Aether and Elemental Shards used in its creation.
    /// @param artifactId The ID of the Artifact to extract essence from.
    function extractEssence(uint256 artifactId) external nonReentrant whenNotPaused {
        require(_exists(artifactId), "Artifact does not exist");
        require(ownerOf(artifactId) == msg.sender, "Not artifact owner");

        // Simulate recovery logic (e.g., 50% Aether, 25% of each original shard type)
        uint256 recoveredAether = calculateForgingCost(new uint256[](0), new uint256[](0)).div(2); // Simplified, ideally based on artifact's forging cost
        uint256[] memory recoveredShardIds; // Placeholder: in a real system, track original components
        uint256[] memory recoveredShardAmounts; // Placeholder

        if (artifactStakedAether[artifactId] > 0) {
            _distributeEmpowermentYield(artifactId, msg.sender); // Distribute any pending yield before burning staked Aether
            recoveredAether = recoveredAether.add(artifactStakedAether[artifactId]); // Add back staked Aether
            artifactStakedAether[artifactId] = 0;
        }

        // Transfer Aether
        aether.transfer(msg.sender, recoveredAether);

        // Burn the Artifact
        _burn(artifactId);

        // Clear artifact data
        delete artifactData[artifactId];

        emit EssenceExtracted(msg.sender, msg.sender, recoveredAether, recoveredShardIds, recoveredShardAmounts);
    }

    /// @notice Simulates time-based degradation of an Artifact's properties.
    /// @dev Can be called by anyone (incentivize with small reward?) or integrate with a keeper network.
    ///      For simplicity, it's public and gas cost is on caller.
    /// @param artifactId The ID of the Artifact to decay.
    function decayArtifact(uint256 artifactId) external nonReentrant {
        require(_exists(artifactId), "Artifact does not exist");
        ArtifactProperties storage props = artifactData[artifactId];

        uint256 timePassed = block.timestamp.sub(props.lastDecayTime);
        if (timePassed < 1 days) return; // Only decay once per day

        uint256 daysPassed = timePassed.div(1 days);
        uint256 decayAmount = decayRatePerDay.mul(daysPassed);

        // Prevent decay past 100%
        if (props.decayLevel.add(decayAmount) >= 100) {
            props.decayLevel = 100;
        } else {
            props.decayLevel = props.decayLevel.add(decayAmount);
        }

        props.lastDecayTime = block.timestamp;
        emit ArtifactDecayed(artifactId, props.decayLevel);
    }

    /// @notice Allows an Artifact owner to spend Aether to restore decayed attributes.
    /// @param artifactId The ID of the Artifact to repair.
    function repairArtifact(uint256 artifactId) external nonReentrant whenNotPaused {
        require(_exists(artifactId), "Artifact does not exist");
        require(ownerOf(artifactId) == msg.sender, "Not artifact owner");
        ArtifactProperties storage props = artifactData[artifactId];

        require(props.decayLevel > 0, "Artifact is not decayed");

        // Example repair cost: proportional to decay level
        uint256 repairCost = props.decayLevel.mul(10 * 10**18); // 10 Aether per decay point
        require(aether.balanceOf(msg.sender) >= repairCost, "Insufficient Aether for repair");

        aether.transferFrom(msg.sender, address(this), repairCost);

        // Burn a portion of repair cost
        uint256 aetherToBurn = repairCost.mul(aetherBurnRate).div(100);
        if (aetherToBurn > 0) {
            aether.burn(address(this), aetherToBurn);
        }

        props.decayLevel = 0; // Full repair for simplicity, could be partial
        props.lastDecayTime = block.timestamp; // Reset decay timer

        emit ArtifactRepaired(artifactId, repairCost, props.decayLevel);
    }

    // --- III. Query & Information ---

    /// @notice Retrieves all current dynamic properties of a given Artifact.
    /// @param artifactId The ID of the Artifact.
    /// @return power Current effective power.
    /// @return resilience Current effective resilience.
    /// @return fortune Current effective fortune.
    /// @return elementalAlignment The artifact's primary elemental alignment.
    /// @return creationTime Timestamp of creation.
    /// @return lastEmpowerTime Timestamp of last empowerment.
    /// @return lastDecayTime Timestamp of last decay calculation.
    /// @return decayLevel Current decay level (0-100).
    /// @return stakedAether Amount of Aether currently staked.
    function getArtifactProperties(uint256 artifactId) public view returns (
        uint256 power,
        uint256 resilience,
        uint256 fortune,
        uint8 elementalAlignment,
        uint256 creationTime,
        uint256 lastEmpowerTime,
        uint256 lastDecayTime,
        uint256 decayLevel,
        uint256 stakedAether
    ) {
        require(_exists(artifactId), "Artifact does not exist");
        ArtifactProperties storage props = artifactData[artifactId];
        uint256 currentPower = props.power;
        uint256 currentResilience = props.resilience;
        uint256 currentFortune = props.fortune;

        // Apply decay penalty
        if (props.decayLevel > 0) {
            currentPower = currentPower.mul(100 - props.decayLevel).div(100);
            currentResilience = currentResilience.mul(100 - props.decayLevel).div(100);
            currentFortune = currentFortune.mul(100 - props.decayLevel).div(100);
        }

        // Apply empowerment bonus
        uint256 currentStaked = artifactStakedAether[artifactId];
        if (currentStaked > 0) {
            // Example: 1 Aether staked adds 1 power/resilience per 1000 Aether (scaled)
            uint256 bonus = currentStaked.div(10**18).div(100); // 100 Aether staked adds 1 power
            currentPower = currentPower.add(bonus);
            currentResilience = currentResilience.add(bonus);
        }

        return (
            currentPower,
            currentResilience,
            currentFortune,
            props.elementalAlignment,
            props.creationTime,
            props.lastEmpowerTime,
            props.lastDecayTime,
            props.decayLevel,
            currentStaked
        );
    }

    /// @notice Estimates the Aether cost for a given shard combination for forging.
    /// @param shardIds An array of Elemental Shard IDs.
    /// @param shardAmounts An array of corresponding amounts.
    /// @return The estimated total Aether cost.
    function calculateForgingCost(uint256[] calldata shardIds, uint256[] calldata shardAmounts) public view returns (uint256) {
        require(shardIds.length == shardAmounts.length, "Mismatched shard arrays");
        require(shardIds.length > 0, "Must use at least one shard for calculation");

        // Determine primary alignment for recipe lookup (simplistic, same logic as forgeArtifact)
        uint8 primaryAlignment = uint8(ElementalAlignment.NONE);
        uint256 maxShardInfluence = 0;
        for (uint256 i = 0; i < shardIds.length; i++) {
            uint256 currentShardId = shardIds[i];
            uint256 currentShardAmount = shardAmounts[i];
            uint8 currentElement;
            if (currentShardId == SHARD_FIRE) currentElement = uint8(ElementalAlignment.FIRE);
            else if (currentShardId == SHARD_WATER) currentElement = uint8(ElementalAlignment.WATER);
            else if (currentShardId == SHARD_EARTH) currentElement = uint8(ElementalAlignment.EARTH);
            else if (currentShardId == SHARD_AIR) currentElement = uint8(ElementalAlignment.AIR);
            else if (currentShardId == SHARD_SPIRIT) currentElement = uint8(ElementalAlignment.SPIRIT);
            else if (currentShardId == SHARD_VOID) currentElement = uint8(ElementalAlignment.VOID);
            else continue; // Ignore invalid shards for cost calculation, but require them for actual forging

            uint256 influence = currentShardAmount.mul(currentShardId);
            if (influence > maxShardInfluence) {
                maxShardInfluence = influence;
                primaryAlignment = currentElement;
            }
        }
        
        ForgingRecipe storage recipe = forgingRecipes[primaryAlignment];
        require(recipe.baseAetherCost > 0, "No valid forging recipe for this combination");

        uint256 dynamicCost = 0;
        for (uint256 i = 0; i < shardIds.length; i++) {
            // Each shard contributes a small amount to the cost
            dynamicCost = dynamicCost.add(shardAmounts[i].mul(10 * 10**18)); // 10 Aether per shard unit
        }

        return recipe.baseAetherCost.add(dynamicCost);
    }

    /// @notice Returns the current effective 'power' of an Artifact, considering base attributes, empowerment, and decay.
    /// @param artifactId The ID of the Artifact.
    /// @return The current effective power.
    function getArtifactPower(uint256 artifactId) public view returns (uint256) {
        (uint256 power,,,,,,,,) = getArtifactProperties(artifactId);
        return power;
    }

    /// @notice Returns the conversion ratio for refining shards.
    /// @param sourceShardId The ID of the source shard.
    /// @param targetShardId The ID of the target shard.
    /// @return The ratio (e.g., 3 means 3 source shards for 1 target shard). Returns 0 if no ratio is set.
    function getRefinementRatio(uint256 sourceShardId, uint256 targetShardId) public view returns (uint256) {
        return refinementRatios[sourceShardId][targetShardId];
    }

    /// @notice Standard ERC-165 function to check if the contract supports a given interface.
    /// @param interfaceId The interface ID to check.
    /// @return True if the interface is supported, false otherwise.
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // --- IV. Administrative & Governance Hooks (Owner-only for this implementation) ---

    /// @notice Allows the owner to define or update recipes for forging different types of Artifacts.
    /// @param elementIndex The elemental alignment index (from ElementalAlignment enum).
    /// @param baseCost The base Aether cost for this recipe.
    /// @param requiredShards An array of shard IDs required.
    /// @param requiredAmounts An array of corresponding amounts required.
    function setForgingRecipe(
        uint8 elementIndex,
        uint256 baseCost,
        uint256[] calldata requiredShards,
        uint256[] calldata requiredAmounts
    ) external onlyOwner {
        require(elementIndex <= uint8(ElementalAlignment.VOID), "Invalid element index");
        require(requiredShards.length == requiredAmounts.length, "Mismatched shard arrays");
        
        forgingRecipes[elementIndex] = ForgingRecipe({
            baseAetherCost: baseCost,
            requiredShardIds: requiredShards,
            requiredShardAmounts: requiredAmounts
        });
        emit ForgingRecipeUpdated(elementIndex, baseCost);
    }

    /// @notice Allows the owner to define how different Elemental Shards contribute to an Artifact's attributes.
    /// @param element The elemental alignment index.
    /// @param powerWeight Weight for power attribute.
    /// @param resilienceWeight Weight for resilience attribute.
    /// @param fortuneWeight Weight for fortune attribute.
    function setElementalAttributeWeights(
        uint8 element,
        uint256 powerWeight,
        uint256 resilienceWeight,
        uint256 fortuneWeight
    ) external onlyOwner {
        require(element <= uint8(ElementalAlignment.VOID), "Invalid element index");
        elementalAttributeWeights[element] = AttributeWeights(powerWeight, resilienceWeight, fortuneWeight);
        emit ElementalAttributeWeightsUpdated(element, powerWeight, resilienceWeight);
    }

    /// @notice Adjusts the rate at which Artifacts decay over time. Owner-only.
    /// @param _newDecayRate The new decay rate (percentage points per day, e.g., 5 for 5%).
    function setDecayRate(uint256 _newDecayRate) external onlyOwner {
        require(_newDecayRate <= 100, "Decay rate cannot exceed 100%");
        decayRatePerDay = _newDecayRate;
        // Consider emitting a specific event for this
    }

    /// @notice Adjusts the yield rate for Aether staked with Artifacts. Owner-only.
    /// @param _newRate The new yield rate (per 1000 staked Aether per day, e.g., 50 for 5%).
    function setEmpowermentYieldRate(uint256 _newRate) external onlyOwner {
        empowermentYieldRate = _newRate;
        // Consider emitting a specific event for this
    }

    /// @notice Sets conversion ratios for shard refinement. Owner-only.
    /// @param sourceShardId The ID of the shard to consume.
    /// @param targetShardId The ID of the shard to produce.
    /// @param ratio The ratio (e.g., 3 means 3 source for 1 target). Set to 0 to remove.
    function setRefinementRatio(uint256 sourceShardId, uint256 targetShardId, uint256 ratio) external onlyOwner {
        refinementRatios[sourceShardId][targetShardId] = ratio;
        emit RefinementRatioUpdated(sourceShardId, targetShardId, ratio);
    }

    /// @notice Pauses or unpauses the forging functionality. Owner-only.
    /// @param _enabled True to enable, false to disable.
    function toggleForgingEnabled(bool _enabled) external onlyOwner {
        if (_enabled) {
            _unpause();
        } else {
            _pause();
        }
    }

    /// @notice Allows the owner to withdraw any accidentally sent ERC-20 tokens from the contract.
    /// @dev This function prevents locking up other ERC-20s in the contract, but does NOT allow withdrawing Aether
    ///      which is managed internally by this contract.
    /// @param tokenAddress The address of the ERC-20 token to withdraw.
    /// @param recipient The address to send the tokens to.
    function withdrawERC20(address tokenAddress, address recipient) external onlyOwner nonReentrant {
        require(tokenAddress != address(aether), "Cannot withdraw internal Aether token via this function");
        IERC20 token = IERC20(tokenAddress);
        token.transfer(recipient, token.balanceOf(address(this)));
    }

    /// @notice Allows the owner/governance to propose a change to a dynamic rule.
    /// @dev This serves as a hook for a more complex DAO governance model,
    ///      where changes are proposed, then voted on/timelocked before being applied.
    /// @param ruleKey A unique identifier for the rule being changed (e.g., hash of rule name).
    /// @param newData The new data for the rule, encoded.
    function proposeDynamicRuleChange(bytes32 ruleKey, bytes calldata newData) external onlyOwner {
        require(proposedRuleChanges[ruleKey].proposalTime == 0 || proposedRuleChanges[ruleKey].applied == true, "Rule change already proposed or pending");
        proposedRuleChanges[ruleKey] = ProposedRuleChange({
            data: newData,
            proposalTime: block.timestamp,
            applied: false
        });
        emit DynamicRuleChangeProposed(ruleKey, newData);
    }

    /// @notice Applies a previously proposed dynamic rule change after a timelock period.
    /// @dev In a full DAO, this would be callable by anyone after successful vote/timelock.
    /// @param ruleKey The unique identifier for the rule being applied.
    function applyDynamicRuleChange(bytes32 ruleKey) external onlyOwner { // Change to specific roles in a DAO scenario
        ProposedRuleChange storage proposal = proposedRuleChanges[ruleKey];
        require(proposal.proposalTime > 0, "No such rule change proposed");
        require(proposal.applied == false, "Rule change already applied");
        require(block.timestamp >= proposal.proposalTime.add(RULE_CHANGE_TIMELOCK), "Timelock not expired");

        // Example: How to apply a dynamic rule change. This is highly abstract.
        // In a real scenario, 'newData' would be decoded and specific state variables updated.
        // For instance, `newData` could encode `setDecayRate(newRate)` or similar.
        // Here, it's just a placeholder to demonstrate the concept.

        // Example: If ruleKey == keccak256("NEW_DECAY_RATE") and newData is a uint256
        // uint256 newRate = abi.decode(proposal.data, (uint256));
        // decayRatePerDay = newRate;
        // Similarly for other rules.

        proposal.applied = true;
        emit DynamicRuleChangeApplied(ruleKey, proposal.data);
    }

    // --- ERC1155 required overrides ---
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override {}
    function _afterTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override {}

    // The following functions are necessary for ERC1155 and ERC721 compliance
    // and ensuring the contract can receive tokens if needed, though for this
    // design, tokens are primarily sent *from* the user via approve/transferFrom.

    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    // This contract will *mint* ERC721s, so it doesn't need to *receive* them itself generally.
    // If it were to receive ERC721s (e.g., for staking *other* NFTs), then IERC721Receiver would be implemented.
}
```