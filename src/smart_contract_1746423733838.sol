Okay, let's create a smart contract that simulates a dynamic on-chain ecosystem or 'Digital Garden'. This contract will combine elements of ERC-20 (resources), ERC-721 (dynamic assets), time-based state changes, and probabilistic events, aiming for a concept beyond typical token standards or simple DeFi/NFT mechanics.

The core idea is a garden where users can plant "AuraPods" (NFTs) using "Essence" (ERC-20), nurture them to grow, harvest Essence from mature pods, or attempt to mutate them into rare forms. AuraPods have dynamic on-chain stats that change over time and based on interactions.

---

**Outline and Function Summary**

**Contract Name:** `AuraWeaverGardens`

**Description:** A smart contract simulating a dynamic digital garden ecosystem. Users interact by planting, nurturing, harvesting, and attempting to mutate on-chain assets (AuraPods, ERC-721) using a native resource token (Essence, ERC-20). AuraPods have dynamic state (health, growth stage, potential) influenced by time and user actions.

**Core Concepts:**

1.  **Essence (ERC-20):** The primary resource for interacting with the garden (planting, nurturing, mutating). Can be harvested from mature AuraPods.
2.  **AuraPods (ERC-721):** The plantable, dynamic NFT assets. Their state (`health`, `growthStage`, `mutationPotential`, `affinity`, `lastInteractionTime`) is stored on-chain and changes based on time elapsed and user actions.
3.  **Time-Based Growth Simulation:** AuraPods grow passively over time based on their `health` and global 'Sunlight Intensity', but growth is calculated actively when a user interacts.
4.  **Probabilistic Mutation:** Users can attempt to mutate an AuraPod using Essence, with a chance of success influenced by global 'Mutation Success Rate' and the pod's `mutationPotential`.
5.  **Resource Management:** Users must manage their Essence to interact.
6.  **Dynamic State:** NFT traits aren't static; they evolve on-chain.

**Function Summary:**

*   **ERC-20 (Essence) Standard Functions (8):**
    *   `name()`: Returns the ERC-20 token name.
    *   `symbol()`: Returns the ERC-20 token symbol.
    *   `decimals()`: Returns the number of decimals for ERC-20.
    *   `totalSupply()`: Returns total supply of Essence.
    *   `balanceOf(address account)`: Returns Essence balance of an account.
    *   `transfer(address to, uint256 amount)`: Transfers Essence.
    *   `approve(address spender, uint256 amount)`: Approves spender for Essence.
    *   `allowance(address owner, address spender)`: Returns allowance.
*   **ERC-721 (AuraPod) Standard Functions (9):**
    *   `balanceOf(address owner)`: Returns AuraPod balance of an owner.
    *   `ownerOf(uint256 tokenId)`: Returns owner of an AuraPod.
    *   `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer of AuraPod.
    *   `transferFrom(address from, address to, uint256 tokenId)`: Transfer of AuraPod.
    *   `approve(address to, uint256 tokenId)`: Approves address for an AuraPod.
    *   `getApproved(uint256 tokenId)`: Returns approved address for an AuraPod.
    *   `setApprovalForAll(address operator, bool approved)`: Sets approval for all tokens.
    *   `isApprovedForAll(address owner, address operator)`: Checks approval for all tokens.
    *   `tokenURI(uint256 tokenId)`: Returns URI for AuraPod metadata (will point to dynamic data).
*   **Ecosystem Core Actions (6):**
    *   `plantAuraPod()`: Spends Essence to mint a new AuraPod NFT.
    *   `nurtureAuraPod(uint256 tokenId)`: Spends Essence to increase an AuraPod's health and update its state.
    *   `harvestEssence(uint256 tokenId)`: If mature, harvests Essence from an AuraPod (burns the NFT).
    *   `attemptMutation(uint256 tokenId)`: Spends Essence to attempt mutating an AuraPod's properties.
    *   `getAuraPodState(uint256 tokenId)`: Returns the current state struct of an AuraPod.
    *   `getAuraPodGrowthProgress(uint256 tokenId)`: Calculates approximate growth percentage based on current state.
*   **Ecosystem Read Functions (Internal/External) (3):**
    *   `getCurrentSunlightIntensity()`: Returns the current global sunlight parameter.
    *   `getCurrentMutationSuccessRate()`: Returns the current global mutation rate parameter.
    *   `getAuraPodCurrentStateOptimized(uint256 tokenId)`: Returns state struct *after* simulating growth based on current time (gas cost depends on time elapsed).
*   **Admin/Parameter Control Functions (5):**
    *   `setEssenceCosts(uint256 plantCost, uint256 nurtureCost, uint256 mutateCost)`: Sets costs for actions.
    *   `setHarvestYield(uint256 yieldAmount)`: Sets Essence harvested from a mature pod.
    *   `setGrowthThreshold(uint256 requiredHealth)`: Sets health required for maturity.
    *   `updateSunlightIntensity(uint256 newIntensityBasisPoints)`: Updates global sunlight factor (affects growth).
    *   `updateMutationRate(uint256 newRateBasisPoints)`: Updates global mutation success chance.
    *   `withdrawEssenceAdminFees()`: Allows owner to withdraw accumulated Essence from costs.

**Total Functions:** 8 (ERC20) + 9 (ERC721) + 6 (Ecosystem Actions) + 3 (Ecosystem Reads) + 5 (Admin) = **31 Functions** (Exceeds minimum of 20).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Outline and Function Summary is provided above the contract code.

contract AuraWeaverGardens is ERC20, ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _auraPodIds;

    // --- Structs ---

    struct AuraPodState {
        uint256 health;           // Current health (affects growth rate)
        uint256 growthStage;      // Current growth stage (accumulated growth points)
        uint256 mutationPotential;// Potential for successful mutation (basis points)
        uint256 affinity;         // An arbitrary trait (e.g., 0-100, affects mutation outcome)
        uint256 lastInteractionTime; // Timestamp of the last state-changing interaction
    }

    // --- State Variables ---

    // AuraPod State Mapping
    mapping(uint256 => AuraPodState) private _auraPodStates;

    // Global Ecosystem Parameters (Admin controlled)
    uint256 public currentSunlightIntensityBasisPoints; // Affects growth rate (e.g., 100 = 1x, 150 = 1.5x)
    uint256 public mutationSuccessRateBasisPoints;      // Base chance of mutation success (e.g., 500 = 5%)

    // Costs and Yields (Admin controlled)
    uint256 public essencePlantCost;
    uint256 public essenceNurtureCost;
    uint256 public essenceMutateCost;
    uint256 public essenceHarvestYieldMature;
    uint256 public requiredHealthForMaturity; // Health required to reach maturity

    // Essence accumulated from costs
    uint256 public essenceAdminFeesCollected;

    // --- Events ---

    event AuraPodPlanted(address indexed owner, uint256 indexed tokenId, uint256 initialHealth, uint256 initialMutationPotential, uint256 initialAffinity);
    event AuraPodNurtured(uint256 indexed tokenId, uint256 newHealth, uint256 newGrowthStage);
    event AuraPodHarvested(uint256 indexed tokenId, address indexed owner, uint256 essenceAmount);
    event AuraPodMutationAttempt(uint256 indexed tokenId, bool success, uint256 newMutationPotential, uint256 newAffinity);
    event SunlightIntensityUpdated(uint256 newIntensityBasisPoints);
    event MutationRateUpdated(uint256 newRateBasisPoints);
    event EssenceCostsUpdated(uint256 plantCost, uint256 nurtureCost, uint256 mutateCost);
    event HarvestYieldUpdated(uint256 yieldAmount);
    event GrowthThresholdUpdated(uint256 requiredHealth);
    event AdminFeesWithdrawn(address indexed owner, uint256 amount);

    // --- Constructor ---

    constructor(uint256 initialEssenceSupply, string memory essenceName, string memory essenceSymbol)
        ERC20(essenceName, essenceSymbol)
        ERC721("AuraPod", "APOD")
        Ownable(msg.sender) // Set deployer as owner
    {
        // Mint initial Essence supply (e.g., to the deployer or a treasury)
        _mint(msg.sender, initialEssenceSupply);

        // Set initial parameters (can be changed by owner later)
        essencePlantCost = 100 ether; // Example: 100 Essence
        essenceNurtureCost = 10 ether;
        essenceMutateCost = 50 ether;
        essenceHarvestYieldMature = 500 ether;
        requiredHealthForMaturity = 1000; // Example: requires 1000 total health for maturity

        currentSunlightIntensityBasisPoints = 100; // 100% intensity initially
        mutationSuccessRateBasisPoints = 500;      // 5% base chance

        essenceAdminFeesCollected = 0;
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Simulates growth of an AuraPod based on time elapsed and current state.
     * Growth accumulation rate depends on time * health * sunlight intensity.
     * Updates growthStage and lastInteractionTime.
     */
    function _simulateGrowth(uint256 tokenId) internal {
        AuraPodState storage pod = _auraPodStates[tokenId];
        uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime - pod.lastInteractionTime;

        if (timeElapsed > 0 && pod.growthStage < requiredHealthForMaturity) {
            // Growth = time * health * sunlight_factor / TIME_UNIT / HEALTH_UNIT / SUNLIGHT_UNIT
            // Example: 1 unit growth per hour per 10 health at 100% sunlight
            // Simplified formula: growth_per_sec = health * (sunlight/10000) / BASE_GROWTH_RATE_DIVISOR
            // Let's use a divisor to scale growth reasonably.
            // Example: 1 health contributes 1 point of growth per (10000 / sunlight_bp * health_divisor) seconds
            // Let health_divisor = 100
            // Let time_divisor = 3600 (seconds in an hour)
            // Growth rate = health * sunlight_bp / (100 * 10000) per second
            // Total growth = timeElapsed * pod.health * currentSunlightIntensityBasisPoints / 1000000; // Scale down
            // Simplified: growth_rate_factor = pod.health * currentSunlightIntensityBasisPoints / 10000;
            // Growth increase = timeElapsed * growth_rate_factor / SCALING_FACTOR;
            // Let's use a scaling factor where 1 health grows ~1 point per hour at 100% sunlight.
            // Time in hours = timeElapsed / 3600
            // Growth per hour = pod.health * (currentSunlightIntensityBasisPoints / 10000)
            // Total Growth = (timeElapsed / 3600) * pod.health * (currentSunlightIntensityBasisPoints / 10000)
            // Integer math: growth_increase = (timeElapsed * pod.health * currentSunlightIntensityBasisPoints) / (3600 * 10000);

            uint256 growthIncrease = (timeElapsed * pod.health * currentSunlightIntensityBasisPoints) / 36000000; // Scaled

            pod.growthStage = pod.growthStage + growthIncrease;
            if (pod.growthStage > requiredHealthForMaturity) {
                pod.growthStage = requiredHealthForMaturity;
            }
        }
        pod.lastInteractionTime = currentTime; // Update interaction time even if no growth occurred (e.g., already mature)
    }

    /**
     * @dev Internal function to get calculated growth progress based on current time.
     * Does not modify state.
     */
    function _getAuraPodCurrentGrowth(uint256 tokenId) internal view returns (uint256 calculatedGrowthStage) {
        AuraPodState storage pod = _auraPodStates[tokenId];
        uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime - pod.lastInteractionTime;

        calculatedGrowthStage = pod.growthStage;

        if (timeElapsed > 0 && pod.growthStage < requiredHealthForMaturity) {
            // Same calculation as _simulateGrowth, but using current time
            uint256 growthIncrease = (timeElapsed * pod.health * currentSunlightIntensityBasisPoints) / 36000000; // Scaled
            calculatedGrowthStage = pod.growthStage + growthIncrease;
            if (calculatedGrowthStage > requiredHealthForMaturity) {
                calculatedGrowthStage = requiredHealthForMaturity;
            }
        }
    }


    // --- ERC20 Standard Functions ---

    // name(), symbol(), decimals(), totalSupply(), balanceOf(), transfer(), approve(), allowance(), transferFrom()
    // These are provided by inheriting ERC20.sol

    // --- ERC721 Standard Functions ---

    // balanceOf(), ownerOf(), safeTransferFrom(), transferFrom(), approve(), getApproved(), setApprovalForAll(), isApprovedForAll()
    // These are provided by inheriting ERC721.sol

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * Returns a base URI + the token ID. Metadata for dynamic NFTs is typically served
     * by an external service that reads the on-chain state to generate the JSON.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // Ensure token exists
        require(_exists(tokenId), "ERC721: invalid token ID");

        // Base URI for metadata server (replace with your actual server URI)
        // This server would read the state returned by getAuraPodState/getAuraPodCurrentStateOptimized
        // and generate the dynamic metadata JSON and image URL.
        string memory baseURI = "https://your-dynamic-metadata-server.com/aurapod/";
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    // --- Ecosystem Core Actions ---

    /**
     * @dev Allows a user to spend Essence to plant a new AuraPod.
     */
    function plantAuraPod() external {
        uint256 cost = essencePlantCost;
        require(balanceOf(msg.sender) >= cost, "Not enough Essence to plant");

        // Burn Essence cost
        _burn(msg.sender, cost);
        essenceAdminFeesCollected += cost; // Accumulate fees

        // Mint new AuraPod NFT
        _auraPodIds.increment();
        uint256 newTokenId = _auraPodIds.current();
        _safeMint(msg.sender, newTokenId);

        // Initialize AuraPod state
        _auraPodStates[newTokenId] = AuraPodState({
            health: 100,              // Starting health
            growthStage: 0,           // Starts at 0 growth
            mutationPotential: 1000,  // Starting mutation potential (10%)
            affinity: uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, newTokenId))) % 100, // Pseudo-random initial affinity (0-99)
            lastInteractionTime: block.timestamp // Record creation time
        });

        emit AuraPodPlanted(msg.sender, newTokenId, 100, 1000, _auraPodStates[newTokenId].affinity);
    }

    /**
     * @dev Allows an AuraPod owner to spend Essence to increase its health and simulate growth.
     * Increases health up to a cap, contributes to accumulated growth via simulation.
     * @param tokenId The ID of the AuraPod to nurture.
     */
    function nurtureAuraPod(uint256 tokenId) external {
        require(_exists(tokenId), "AuraPod does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not your AuraPod to nurture");

        uint256 cost = essenceNurtureCost;
        require(balanceOf(msg.sender) >= cost, "Not enough Essence to nurture");

        // Burn Essence cost
        _burn(msg.sender, cost);
        essenceAdminFeesCollected += cost; // Accumulate fees

        // Simulate growth based on time elapsed *before* nurturing effects
        _simulateGrowth(tokenId);

        // Increase health ( capped )
        AuraPodState storage pod = _auraPodStates[tokenId];
        pod.health += 50; // Example: Increase health by 50
        // Add a health cap, e.g., max 500
        if (pod.health > 500) {
            pod.health = 500;
        }

        // lastInteractionTime was updated in _simulateGrowth
        // growthStage was updated in _simulateGrowth

        emit AuraPodNurtured(tokenId, pod.health, pod.growthStage);
    }

    /**
     * @dev Allows an AuraPod owner to harvest Essence if the pod is mature.
     * Burns the AuraPod NFT and mints Essence to the owner.
     * @param tokenId The ID of the AuraPod to harvest.
     */
    function harvestEssence(uint256 tokenId) external {
        require(_exists(tokenId), "AuraPod does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not your AuraPod to harvest");

        // Simulate growth to ensure maturity check is up-to-date
        _simulateGrowth(tokenId);

        AuraPodState storage pod = _auraPodStates[tokenId];
        require(pod.growthStage >= requiredHealthForMaturity, "AuraPod is not yet mature");

        uint256 yieldAmount = essenceHarvestYieldMature;

        // Mint Essence to owner
        _mint(msg.sender, yieldAmount);

        // Burn the AuraPod NFT
        _deleteAuraPodState(tokenId); // Delete state *before* burning the NFT
        _burn(tokenId);

        emit AuraPodHarvested(tokenId, msg.sender, yieldAmount);
    }

    /**
     * @dev Allows an AuraPod owner to attempt to mutate its properties (potential, affinity).
     * Spends Essence, success is probabilistic.
     * @param tokenId The ID of the AuraPod to attempt mutation on.
     */
    function attemptMutation(uint256 tokenId) external {
        require(_exists(tokenId), "AuraPod does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not your AuraPod to mutate");

        uint256 cost = essenceMutateCost;
        require(balanceOf(msg.sender) >= cost, "Not enough Essence to mutate");

        // Burn Essence cost
        _burn(msg.sender, cost);
        essenceAdminFeesCollected += cost; // Accumulate fees

        // Simulate growth based on time elapsed *before* mutation attempt
        _simulateGrowth(tokenId);

        AuraPodState storage pod = _auraPodStates[tokenId];

        // Calculate success chance: Base rate + Pod potential + Sunlight factor
        // Example: (Base Rate + Potential) * Sunlight Factor / 10000
        uint256 effectiveChance = (mutationSuccessRateBasisPoints + pod.mutationPotential);
        effectiveChance = (effectiveChance * currentSunlightIntensityBasisPoints) / 10000;
        // Cap chance at 100% (10000 basis points)
        if (effectiveChance > 10000) {
            effectiveChance = 10000;
        }


        // Pseudo-randomness: Highly discouraged for production due to predictability/exploitability,
        // but used here for a self-contained example without external oracle dependency.
        // For production, use Chainlink VRF or similar.
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, tx.origin, block.number, tokenId, pod.mutationPotential, currentSunlightIntensityBasisPoints)));
        uint256 randomValue = randomSeed % 10000; // Value between 0 and 9999

        bool success = randomValue < effectiveChance;

        uint256 oldMutationPotential = pod.mutationPotential;
        uint256 oldAffinity = pod.affinity;
        uint256 newMutationPotential = oldMutationPotential;
        uint256 newAffinity = oldAffinity;

        if (success) {
            // Mutation successful: Modify state
            // Example: Increase mutation potential, change affinity
            newMutationPotential = oldMutationPotential + (randomSeed % 500 + 100); // Increase potential by 1-6%
            // Cap potential, e.g., at 5000 (50%)
            if (newMutationPotential > 5000) {
                 newMutationPotential = 5000;
            }

            // Mutate affinity: shift by a random amount
            uint256 affinityShift = randomSeed % 20; // Shift by up to 20
            if (randomSeed % 2 == 0) {
                newAffinity = (oldAffinity + affinityShift) % 100; // Increase and wrap around
            } else {
                 // Handle potential underflow if shifting down
                 newAffinity = (oldAffinity + 100 - affinityShift) % 100; // Decrease and wrap around
            }

            pod.mutationPotential = newMutationPotential;
            pod.affinity = newAffinity;
        } else {
            // Mutation failed: Maybe slightly decrease potential or health as a penalty?
            // For simplicity, let's just log failure for this example.
            // pod.health = pod.health > 10 ? pod.health - 10 : 0; // Example penalty
        }

        // lastInteractionTime updated in _simulateGrowth

        emit AuraPodMutationAttempt(tokenId, success, newMutationPotential, newAffinity);
    }

    /**
     * @dev Gets the current state struct of an AuraPod.
     * Does NOT simulate growth beforehand - returns the state as it was after the last interaction.
     * Use getAuraPodCurrentStateOptimized for state including passive growth since last interaction.
     * @param tokenId The ID of the AuraPod.
     * @return The AuraPodState struct.
     */
    function getAuraPodState(uint256 tokenId) public view returns (AuraPodState memory) {
        require(_exists(tokenId), "AuraPod does not exist");
        return _auraPodStates[tokenId];
    }

    /**
     * @dev Calculates the current growth progress percentage of an AuraPod.
     * Includes passive growth since the last interaction.
     * @param tokenId The ID of the AuraPod.
     * @return Growth progress as a percentage (0-100).
     */
    function getAuraPodGrowthProgress(uint256 tokenId) public view returns (uint256 progressPercentage) {
         require(_exists(tokenId), "AuraPod does not exist");
         uint256 currentGrowth = _getAuraPodCurrentGrowth(tokenId);
         if (requiredHealthForMaturity == 0) return 0; // Avoid division by zero
         return (currentGrowth * 100) / requiredHealthForMaturity;
    }


    // --- Ecosystem Read Functions ---

    /**
     * @dev Returns the current global sunlight intensity factor.
     */
    function getCurrentSunlightIntensity() public view returns (uint256) {
        return currentSunlightIntensityBasisPoints;
    }

    /**
     * @dev Returns the current global mutation success rate.
     */
    function getCurrentMutationSuccessRate() public view returns (uint256) {
        return mutationSuccessRateBasisPoints;
    }

    /**
     * @dev Gets the current state struct of an AuraPod *after* simulating growth based on current time.
     * This is more gas-intensive than getAuraPodState but provides the most up-to-date state visualization.
     * Does NOT modify state.
     * @param tokenId The ID of the AuraPod.
     * @return The calculated AuraPodState including passive growth.
     */
    function getAuraPodCurrentStateOptimized(uint256 tokenId) public view returns (AuraPodState memory) {
        require(_exists(tokenId), "AuraPod does not exist");
        AuraPodState memory pod = _auraPodStates[tokenId];
        uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime - pod.lastInteractionTime;

        if (timeElapsed > 0 && pod.growthStage < requiredHealthForMaturity) {
             uint256 growthIncrease = (timeElapsed * pod.health * currentSunlightIntensityBasisPoints) / 36000000; // Scaled
             pod.growthStage += growthIncrease; // Apply calculated growth
             if (pod.growthStage > requiredHealthForMaturity) {
                pod.growthStage = requiredHealthForMaturity;
            }
        }
        pod.lastInteractionTime = currentTime; // Conceptually update time for this view

        return pod;
    }


    // --- Admin Functions (Only Owner) ---

    /**
     * @dev Allows the owner to set the Essence costs for actions.
     */
    function setEssenceCosts(uint256 plantCost, uint256 nurtureCost, uint256 mutateCost) external onlyOwner {
        essencePlantCost = plantCost;
        essenceNurtureCost = nurtureCost;
        essenceMutateCost = mutateCost;
        emit EssenceCostsUpdated(plantCost, nurtureCost, mutateCost);
    }

    /**
     * @dev Allows the owner to set the Essence harvested from a mature pod.
     */
    function setHarvestYield(uint256 yieldAmount) external onlyOwner {
        essenceHarvestYieldMature = yieldAmount;
        emit HarvestYieldUpdated(yieldAmount);
    }

    /**
     * @dev Allows the owner to set the health required for an AuraPod to be mature.
     */
    function setGrowthThreshold(uint256 requiredHealth) external onlyOwner {
        requiredHealthForMaturity = requiredHealth;
        emit GrowthThresholdUpdated(requiredHealth);
    }

    /**
     * @dev Allows the owner to update the global sunlight intensity factor.
     * Higher intensity leads to faster growth. Basis points (e.g., 10000 = 100%).
     */
    function updateSunlightIntensity(uint256 newIntensityBasisPoints) external onlyOwner {
        currentSunlightIntensityBasisPoints = newIntensityBasisPoints;
        emit SunlightIntensityUpdated(newIntensityBasisPoints);
    }

    /**
     * @dev Allows the owner to update the global mutation success rate.
     * Higher rate means higher chance of successful mutation attempts. Basis points (e.g., 10000 = 100%).
     */
    function updateMutationRate(uint256 newRateBasisPoints) external onlyOwner {
        mutationSuccessRateBasisPoints = newRateBasisPoints;
        emit MutationRateUpdated(newRateBasisPoints);
    }

    /**
     * @dev Allows the owner to withdraw accumulated Essence from action costs.
     */
    function withdrawEssenceAdminFees() external onlyOwner {
        uint256 amount = essenceAdminFeesCollected;
        require(amount > 0, "No admin fees collected");
        essenceAdminFeesCollected = 0;
        // Note: This transfers Essence token *held by the contract itself*,
        // not ETH. The contract must hold the Essence token.
        // This transfer uses the ERC20 transfer function inherited.
        require(transfer(owner(), amount), "Essence transfer failed");
        emit AdminFeesWithdrawn(owner(), amount);
    }

    // --- Overrides & Internal ERC721 Helpers ---

    // The following overrides are needed to manage the AuraPodState mapping
    // whenever a token is transferred or burned.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // When transferring away from address(0) (minting), initialize state was handled in plantAuraPod.
        // When transferring to address(0) (burning), delete state.
        if (to == address(0)) {
            _deleteAuraPodState(tokenId);
        }
    }

    /**
     * @dev Internal function to delete the state associated with a burned token.
     */
    function _deleteAuraPodState(uint256 tokenId) internal {
        // Solidity handles deletion by resetting to default values
        delete _auraPodStates[tokenId];
    }

    // We need to ensure standard ERC721 transfer functions work correctly.
    // The _beforeTokenTransfer override handles state deletion on burn.
    // State creation on mint is handled within plantAuraPod.
    // State should persist across non-burn transfers.

    // The rest of the standard ERC721 functions like _safeMint, _burn,
    // _transfer etc. are called internally by the public ERC721
    // functions or our custom logic, and our _beforeTokenTransfer
    // hook ensures _auraPodStates is managed.
}
```

**Explanation of Concepts & Code:**

1.  **Dynamic State (`AuraPodState` struct and `_auraPodStates` mapping):** Each AuraPod NFT (identified by its `tokenId`) has a corresponding entry in the `_auraPodStates` mapping. This struct holds numerical values (`health`, `growthStage`, `mutationPotential`, `affinity`) and a timestamp (`lastInteractionTime`) that represent the *on-chain* state of that specific NFT instance. This state is mutable, making the NFTs dynamic.
2.  **Essence ERC-20:** Standard ERC-20 implementation used as the internal currency/resource of the ecosystem. Costs for actions (`plant`, `nurture`, `mutate`) are paid in Essence, and `harvest` yields Essence. Fees accumulate in the contract's balance until withdrawn by the owner.
3.  **Time-Based Simulation (`_simulateGrowth`, `_getAuraPodCurrentGrowth`, `lastInteractionTime`):** Instead of running continuous simulation (impossible/impractical on L1), growth is calculated retrospectively based on the time elapsed since the `lastInteractionTime`. This calculation happens within `_simulateGrowth`, which is called by user-facing functions (`nurture`, `harvest`, `attemptMutation`) before applying the action's specific effects. This ensures the state is reasonably up-to-date when interacted with. `getAuraPodCurrentStateOptimized` is a view function that calculates this simulated growth without modifying the state, useful for frontends.
4.  **Probabilistic Mutation (`attemptMutation`):** This function introduces randomness. While true on-chain randomness is challenging (miners can influence results), this example uses a simple pseudo-randomness based on block data and timestamps. **Note:** For production systems requiring secure, unpredictable outcomes, integrating with Chainlink VRF or a similar decentralized oracle solution is crucial. The outcome (success/failure) and the resulting state changes (`mutationPotential`, `affinity`) are determined by this probabilistic check and calculation.
5.  **Resource Sink and Faucet:** Planting, nurturing, and mutating act as Essence sinks (burning user Essence and collecting it as admin fees). Harvesting acts as an Essence faucet (minting new Essence based on a burned NFT). This basic economic loop is common in game-like tokenomics.
6.  **Admin Control (`Ownable` and Admin Functions):** The contract owner can adjust key parameters like costs, harvest yield, growth requirements, sunlight intensity, and mutation rates. This allows tuning the game economy and dynamics.
7.  **Dynamic `tokenURI`:** The `tokenURI` function returns a URI that includes the token ID. A real-world implementation would have an off-chain server at this base URI that reads the *current on-chain state* of the specified token ID (using functions like `getAuraPodCurrentStateOptimized`) and dynamically generates the NFT metadata JSON, including trait values, growth stage, etc., and potentially links to a dynamically generated image reflecting the state.

This contract provides a foundation for a complex, evolving on-chain ecosystem, demonstrating dynamic NFT state, resource management, time-influenced mechanics, and probabilistic events, going beyond the standard token functionalities. Remember that deploying this to a public network requires careful consideration of gas costs, security (especially randomness), and the need for off-chain services for dynamic metadata and potentially web clients to interact.