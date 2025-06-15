Okay, here is a smart contract concept focused on "Symbiotic Growth Protocol," combining elements of dynamic staking, reputation, gamified maintenance, and variable yield based on on-chain state and environmental factors. It's designed to be complex, avoid simple patterns, and integrate several dynamic concepts.

**Disclaimer:** This is a complex conceptual contract for educational and illustrative purposes. It is *not* audited or ready for production use. It may contain bugs or security vulnerabilities. Deploying complex contracts like this requires rigorous testing and professional security audits.

---

### Symbiotic Growth Protocol: Outline and Function Summary

This contract implements a system where users "cultivate" a stake of `SYM` tokens to earn yield. The yield is dynamic, depending on several factors including the staked amount, the health and state of the user's "Garden" (their staked position), internal "Growth Boosts", and a protocol-wide "Environmental Factor" controlled by governance. Users earn non-transferable "Growth Points" (GP) by performing protocol-aligned actions (simulated here) and can use these GP or `SYM` to perform "Gardening Actions" (like watering or fertilizing) to improve their Garden's state and potential yield.

**Core Concepts:**

1.  **SYM Token:** The primary ERC20 token used for staking and rewards.
2.  **Growth Points (GP):** A non-transferable, non-fungible (in the sense of being unique per user balance) reputation score earned through contribution. Used for specific actions.
3.  **Garden:** Represents a user's staked `SYM` and their associated dynamic state (Health, Boosts).
4.  **Dynamic Yield:** Calculated based on Staked Amount, Plant Health, Growth Boost, Environmental Factor, and Time Elapsed.
5.  **Plant Health:** A value that decays over time but can be improved by Gardening Actions. Affects yield multiplier.
6.  **Growth Boost:** A temporary multiplier applied to yield, activated by Gardening Actions.
7.  **Environmental Factor:** A global multiplier set by governance, affecting all Gardens.
8.  **Gardening Actions:** Functions users call to spend resources (GP or SYM) to improve their Garden's state.
9.  **Harvesting:** Claiming accumulated yield. A fee may apply.

**Contract Structure:**

*   Inherits `AccessControl` for role-based governance.
*   Defines a `GOVERNOR_ROLE` with permissions for protocol parameter adjustments.
*   Uses a `GardenState` struct to store per-user staking data.
*   Mappings for `GardenState` and user `gpBalances`.
*   Storage variables for configurable parameters.
*   Events for key state changes and actions.

**Function Summary:**

**A. Core Staking & Yield:**
1.  `stakeSYM(uint256 amount)`: Stakes a specified amount of SYM tokens for the caller, updating or creating their Garden state. Requires prior token approval.
2.  `unstakeSYM(uint256 amount)`: Unstakes a specified amount of SYM tokens from the caller's Garden. User cannot unstake more than their current stake minus any potential yield (simplified here: can unstake up to staked amount).
3.  `harvestYield()`: Calculates and transfers accumulated SYM yield to the caller based on their Garden's state since the last harvest or stake time. Applies harvest fee.

**B. Growth Points (GP) & Actions:**
4.  `performSimulatedAction(uint256 actionId)`: Placeholder function to simulate earning GP for contributing to the protocol. Awards a fixed amount of GP.
5.  `waterGarden(uint256 costChoice)`: Performs the "Water" action. Costs GP or SYM depending on `costChoice`. Increases `plantHealth`.
6.  `fertilizeGarden(uint256 costChoice)`: Performs the "Fertilize" action. Costs GP or SYM depending on `costChoice`. Activates/extends `growthBoostEndTime`.
7.  `pruneGarden()`: Performs the "Prune" action. A low-cost/free action that provides a small `plantHealth` boost.

**C. View Functions (User & State Info):**
8.  `getGardenState(address user)`: Returns the detailed state of a user's Garden (staked amount, health, boost end time, last harvest time, creation time).
9.  `getUserGP(address user)`: Returns the current Growth Point balance for a user.
10. `calculateCurrentHealth(address user)`: Calculates the user's current `plantHealth` considering decay since the last state change or check.
11. `calculateCurrentGrowthBoost(address user)`: Calculates the user's current `growthBoost` multiplier based on the boost end time. Returns 1.0 if boost is expired.
12. `calculatePotentialYield(address user)`: Calculates the potential SYM yield a user would receive if they `harvestYield()` now. Accounts for health, boost, environmental factor, and harvest fee.
13. `hasGarden(address user)`: Checks if a user currently has staked SYM and an active Garden state.

**D. Governance (GOVERNOR_ROLE):**
14. `setEnvironmentalFactor(uint256 factor)`: Sets the protocol-wide `environmentalFactor`. Represented scaled (e.g., 1e18 for 1.0).
15. `setHealthDecayRate(uint256 rate)`: Sets the per-second rate at which `plantHealth` decays. Scaled.
16. `setWaterCosts(uint256 symCost, uint256 gpCost)`: Sets the costs in SYM and GP for the `waterGarden` action.
17. `setWaterHealthBoost(uint256 boost)`: Sets the amount `plantHealth` increases when `waterGarden` is called.
18. `setFertilizeCosts(uint256 symCost, uint256 gpCost)`: Sets the costs in SYM and GP for the `fertilizeGarden` action.
19. `setFertilizeBoostParams(uint256 boostAmount, uint256 boostDuration)`: Sets the multiplier amount and duration (in seconds) for the `fertilizeGarden` action. Boost amount scaled (e.g., 1e18 for 1.0 extra, meaning 2x total yield multiplier).
20. `setPruneHealthBoost(uint256 boost)`: Sets the amount `plantHealth` increases when `pruneGarden` is called.
21. `setBaseYieldRate(uint256 ratePerSecond)`: Sets the base rate (scaled) at which staked SYM generates yield per second.
22. `setGpPerSimulatedAction(uint256 amount)`: Sets the amount of GP earned per call of `performSimulatedAction`.
23. `setHarvestFeeRate(uint256 rateScaled)`: Sets the percentage fee taken on harvested yield (e.g., 1e17 for 10%). Fee destination is the contract or governor address.
24. `grantGovernorRole(address user)`: Grants the `GOVERNOR_ROLE` to an address.
25. `renounceGovernorRole()`: Renounces the `GOVERNOR_ROLE` for the caller.
26. `getGovernorRole()`: Returns the keccak256 hash of the `GOVERNOR_ROLE`. (Inherited getters like `hasRole` also exist).

This design offers dynamic state, user interaction impacting their yield potential, a reputation system (GP), and central governance over key economic parameters, making it more complex than typical fixed-rate or simple time-based staking contracts.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; // Using MockERC20 for SYM in this example

// Mock ERC20 for demonstration purposes
contract MockSYM is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public {
        _burn(from, amount);
    }
}


/**
 * @title SymbioticGrowthProtocol
 * @dev A dynamic staking and yield farming contract with gamified elements and reputation.
 * Users stake SYM tokens into a "Garden", which has dynamic state (Health, Boosts)
 * influencing yield. Users can perform "Gardening Actions" using SYM or Growth Points (GP)
 * to improve their Garden state. Yield is affected by Garden state and a global
 * Environmental Factor set by governance.
 *
 * Core Concepts:
 * - SYM Token: Staked asset and reward token.
 * - Growth Points (GP): Non-transferable reputation for protocol participation.
 * - Garden: User's staked position with dynamic attributes (Health, Boost, Timestamps).
 * - Dynamic Yield: Based on staked amount, Health, Boost, Environmental Factor, time.
 * - Gardening Actions: Water, Fertilize, Prune (cost SYM/GP, improve Garden state).
 * - Harvesting: Claiming accumulated yield.
 * - Governance: Controls global parameters (Environmental Factor, costs, rates).
 */
contract SymbioticGrowthProtocol is AccessControl {
    using SafeMath for uint256;

    // --- Roles ---
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");

    // --- State Structures ---
    struct GardenState {
        uint256 stakedAmount;
        uint256 plantHealth; // Scaled, e.g., 0-1000 representing 0% to 100% effectively scaled yield multiplier
        uint256 growthBoostEndTime; // Timestamp when growth boost expires
        uint256 lastStateChangeTime; // Timestamp of last health/boost/stake change
        uint256 lastHarvestTime; // Timestamp of last harvest or stake
        uint256 creationTime; // Timestamp when garden was first created
    }

    // --- Storage ---
    IERC20 public immutable SYM;
    mapping(address => GardenState) public gardens;
    mapping(address => uint256) public gpBalances; // Growth Points are non-transferable

    // --- Configurable Parameters (Set by Governor) ---
    uint256 public environmentalFactor; // Global yield multiplier, scaled (e.g., 1e18 for 1.0)
    uint256 public healthDecayRate; // Health decay per second, scaled (e.g., 1e15 for 0.001 per sec)
    uint256 public waterCostSYM; // Cost in SYM for water action
    uint256 public waterCostGP; // Cost in GP for water action
    uint256 public waterHealthBoost; // Health increase from water action, scaled
    uint256 public fertilizeCostSYM; // Cost in SYM for fertilize action
    uint256 public fertilizeCostGP; // Cost in GP for fertilize action
    uint256 public fertilizeBoostAmount; // Yield multiplier amount from fertilize action, scaled (e.g., 1e18 for +1.0x)
    uint256 public fertilizeBoostDuration; // Duration of fertilize boost in seconds
    uint256 public pruneHealthBoost; // Health increase from prune action, scaled
    uint256 public baseYieldRatePerSecond; // Base yield rate per second per staked token, scaled (e.g., 1e10 for 0.000000001 SYM per sec per token)
    uint256 public gpPerSimulatedAction; // GP earned per simulated action
    uint256 public harvestFeeRateScaled; // Percentage fee on harvested yield (e.g., 1e17 for 10%)

    // --- Constants ---
    uint256 private constant HEALTH_SCALE = 1000; // Max health scaling denominator
    uint256 private constant FACTOR_SCALE = 1e18; // Standard 18 decimals scaling

    // --- Events ---
    event Staked(address indexed user, uint256 amount, uint256 totalStaked);
    event Unstaked(address indexed user, uint256 amount, uint256 totalStaked);
    event Harvested(address indexed user, uint256 yieldAmount, uint256 feeAmount);
    event GPSimulatedAction(address indexed user, uint256 actionId, uint256 gpEarned, uint256 totalGP);
    event GardenWatered(address indexed user, uint256 healthBoost, uint256 currentHealth);
    event GardenFertilized(address indexed user, uint256 boostAmount, uint256 boostDuration, uint256 boostEndTime);
    event GardenPruned(address indexed user, uint256 healthBoost, uint256 currentHealth);
    event EnvironmentalFactorSet(uint256 newFactor);
    event ConfigParameterSet(string parameterName, uint256 value);
    event ConfigParameterSetWithDuration(string parameterName, uint256 value1, uint256 value2);
    event ConfigParameterSetWithCosts(string parameterName, uint256 symCost, uint256 gpCost);

    // --- Modifiers ---
    modifier hasGarden(address user) {
        require(gardens[user].stakedAmount > 0, "SGP: User has no garden");
        _;
    }

    // --- Constructor ---
    constructor(address symTokenAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(GOVERNOR_ROLE, msg.sender);

        SYM = IERC20(symTokenAddress);

        // Set reasonable initial default parameters (Governors should ideally set these)
        environmentalFactor = FACTOR_SCALE; // 1.0x
        healthDecayRate = 1e15; // 0.001 health per second decay
        waterCostSYM = 1e16; // 0.01 SYM
        waterCostGP = 5; // 5 GP
        waterHealthBoost = 100; // +100 health
        fertilizeCostSYM = 1e17; // 0.1 SYM
        fertilizeCostGP = 20; // 20 GP
        fertilizeBoostAmount = 5e17; // +0.5x yield (1.5x total while active)
        fertilizeBoostDuration = 1 days; // 1 day boost
        pruneHealthBoost = 10; // +10 health
        baseYieldRatePerSecond = 1e10; // 0.00000001 SYM per sec per token
        gpPerSimulatedAction = 10; // 10 GP per simulated action
        harvestFeeRateScaled = 5e16; // 5% fee
    }

    // --- A. Core Staking & Yield ---

    /**
     * @dev Stakes SYM tokens into the protocol. Requires prior approval.
     * Creates a new garden for the user if they don't have one.
     * @param amount The amount of SYM tokens to stake.
     */
    function stakeSYM(uint256 amount) external {
        require(amount > 0, "SGP: Stake amount must be > 0");

        SYM.transferFrom(msg.sender, address(this), amount);

        GardenState storage garden = gardens[msg.sender];
        uint256 currentHealth = _calculateCurrentHealth(msg.sender); // Capture health before stake change

        if (garden.stakedAmount == 0) {
            // New garden
            garden.creationTime = block.timestamp;
            garden.lastHarvestTime = block.timestamp;
            garden.plantHealth = HEALTH_SCALE; // Start with full health
            garden.growthBoostEndTime = block.timestamp; // No boost initially
            garden.lastStateChangeTime = block.timestamp;
        } else {
             // Existing garden - Update health based on decay before adding stake
            garden.plantHealth = currentHealth; // Update health to current decayed value
            garden.lastStateChangeTime = block.timestamp; // Health was just updated
        }

        garden.stakedAmount = garden.stakedAmount.add(amount);

        emit Staked(msg.sender, amount, garden.stakedAmount);
    }

    /**
     * @dev Unstakes SYM tokens from the protocol.
     * @param amount The amount of SYM tokens to unstake.
     */
    function unstakeSYM(uint256 amount) external hasGarden(msg.sender) {
        require(amount > 0, "SGP: Unstake amount must be > 0");
        GardenState storage garden = gardens[msg.sender];
        require(garden.stakedAmount >= amount, "SGP: Not enough staked");

        // Calculate and add potential yield before unstaking (optional, decided against for simplicity: harvest is separate)
        // uint256 potentialYield = _calculatePotentialYield(msg.sender);
        // gardens[msg.sender].lastHarvestTime = block.timestamp; // Reset harvest timer if harvesting here
        // // Logic to handle potentialYield...

        uint256 currentHealth = _calculateCurrentHealth(msg.sender); // Capture health before unstake change
        garden.plantHealth = currentHealth; // Update health to current decayed value
        garden.lastStateChangeTime = block.timestamp; // Health was just updated

        garden.stakedAmount = garden.stakedAmount.sub(amount);

        SYM.transfer(msg.sender, amount);

        if (garden.stakedAmount == 0) {
            // Clean up garden state if fully unstaked
            delete gardens[msg.sender];
        }

        emit Unstaked(msg.sender, amount, garden.stakedAmount);
    }

    /**
     * @dev Calculates and transfers accumulated SYM yield to the user.
     * Applies health, boost, environmental multipliers, and harvest fee.
     */
    function harvestYield() external hasGarden(msg.sender) {
        GardenState storage garden = gardens[msg.sender];
        uint256 timeElapsed = block.timestamp.sub(garden.lastHarvestTime);

        if (timeElapsed == 0 || garden.stakedAmount == 0) {
            // Nothing to harvest yet or no stake
            emit Harvested(msg.sender, 0, 0);
            return;
        }

        uint256 yieldAmount = _calculateYieldSince(msg.sender, timeElapsed);
        require(yieldAmount > 0, "SGP: No yield accumulated");

        uint256 feeAmount = yieldAmount.mul(harvestFeeRateScaled).div(FACTOR_SCALE);
        uint256 netYield = yieldAmount.sub(feeAmount);

        // Update garden state *before* transferring
        // Calculate and update health based on decay during the harvest period
        uint256 currentHealth = _calculateCurrentHealth(msg.sender);
        garden.plantHealth = currentHealth;
        garden.lastStateChangeTime = block.timestamp; // Health was just updated

        garden.lastHarvestTime = block.timestamp; // Reset harvest timer

        // Mint and transfer rewards (assuming SYM is mintable by this contract, or pre-minted pool)
        // Example uses MockSYM with mint function. In real scenarios, use a reward pool or carefully manage token supply.
        MockSYM(address(SYM)).mint(msg.sender, netYield);
        if (feeAmount > 0) {
             // Send fee to governor or treasury, or burn
             // Sending to governor address for simplicity. Consider a dedicated treasury.
            address feeRecipient = hasRole(GOVERNOR_ROLE, msg.sender) ? msg.sender : address(this); // Example: send to self if governor harvests, otherwise self. Consider separate treasury role/address.
             MockSYM(address(SYM)).mint(feeRecipient, feeAmount);
        }


        emit Harvested(msg.sender, netYield, feeAmount);
    }

    // --- B. Growth Points (GP) & Actions ---

    /**
     * @dev Simulates a user performing a protocol-aligned action and awards GP.
     * The `actionId` is a placeholder for different types of actions.
     * @param actionId Identifier for the simulated action.
     */
    function performSimulatedAction(uint256 actionId) external {
        // In a real application, this would likely be triggered by:
        // - Oracles verifying off-chain work
        // - Calls from other protocol contracts (e.g., governance vote participation)
        // - Proofs of liquidity provision, etc.
        require(gpPerSimulatedAction > 0, "SGP: GP per action is zero");

        gpBalances[msg.sender] = gpBalances[msg.sender].add(gpPerSimulatedAction);

        emit GPSimulatedAction(msg.sender, actionId, gpPerSimulatedAction, gpBalances[msg.sender]);
    }

    /**
     * @dev Performs the "Water" gardening action. Costs SYM or GP to boost health.
     * @param costChoice 0 for SYM cost, 1 for GP cost.
     */
    function waterGarden(uint256 costChoice) external hasGarden(msg.sender) {
        require(costChoice <= 1, "SGP: Invalid cost choice");

        GardenState storage garden = gardens[msg.sender];
        uint256 currentHealth = _calculateCurrentHealth(msg.sender); // Apply decay before boosting

        if (costChoice == 0) {
            // Pay with SYM
            require(waterCostSYM > 0, "SGP: SYM cost for water not set");
            require(SYM.balanceOf(msg.sender) >= waterCostSYM, "SGP: Insufficient SYM balance");
            require(SYM.allowance(msg.sender, address(this)) >= waterCostSYM, "SGP: SYM allowance too low");
            SYM.transferFrom(msg.sender, address(this), waterCostSYM);
        } else {
            // Pay with GP
            require(waterCostGP > 0, "SGP: GP cost for water not set");
            require(gpBalances[msg.sender] >= waterCostGP, "SGP: Insufficient GP balance");
            gpBalances[msg.sender] = gpBalances[msg.sender].sub(waterCostGP);
        }

        // Apply health boost, capping at max scale
        garden.plantHealth = currentHealth.add(waterHealthBoost);
        if (garden.plantHealth > HEALTH_SCALE) {
             garden.plantHealth = HEALTH_SCALE;
        }
        garden.lastStateChangeTime = block.timestamp; // Health state changed

        emit GardenWatered(msg.sender, waterHealthBoost, garden.plantHealth);
    }

    /**
     * @dev Performs the "Fertilize" gardening action. Costs SYM or GP to activate/extend growth boost.
     * @param costChoice 0 for SYM cost, 1 for GP cost.
     */
    function fertilizeGarden(uint256 costChoice) external hasGarden(msg.sender) {
        require(costChoice <= 1, "SGP: Invalid cost choice");
        require(fertilizeBoostAmount > 0 && fertilizeBoostDuration > 0, "SGP: Fertilize boost params not set");

        GardenState storage garden = gardens[msg.sender];
        uint256 currentHealth = _calculateCurrentHealth(msg.sender); // Apply decay before action

        if (costChoice == 0) {
            // Pay with SYM
            require(fertilizeCostSYM > 0, "SGP: SYM cost for fertilize not set");
            require(SYM.balanceOf(msg.sender) >= fertilizeCostSYM, "SGP: Insufficient SYM balance");
            require(SYM.allowance(msg.sender, address(this)) >= fertilizeCostSYM, "SGP: SYM allowance too low");
            SYM.transferFrom(msg.sender, address(this), fertilizeCostSYM);
        } else {
            // Pay with GP
            require(fertilizeCostGP > 0, "SGP: GP cost for fertilize not set");
            require(gpBalances[msg.sender] >= fertilizeCostGP, "SGP: Insufficient GP balance");
            gpBalances[msg.sender] = gpBalances[msg.sender].sub(fertilizeCostGP);
        }

        // Apply health update due to elapsed time, before boosting
        garden.plantHealth = currentHealth;
        // Extend boost time from *current* block.timestamp or *existing* boost end time if later
        uint256 newBoostEndTime = (block.timestamp > garden.growthBoostEndTime ? block.timestamp : garden.growthBoostEndTime).add(fertilizeBoostDuration);
        garden.growthBoostEndTime = newBoostEndTime;
        garden.lastStateChangeTime = block.timestamp; // Boost state changed

        emit GardenFertilized(msg.sender, fertilizeBoostAmount, fertilizeBoostDuration, garden.growthBoostEndTime);
    }

    /**
     * @dev Performs the "Prune" gardening action. A low-cost action to boost health.
     */
    function pruneGarden() external hasGarden(msg.sender) {
        require(pruneHealthBoost > 0, "SGP: Prune health boost not set");

        GardenState storage garden = gardens[msg.sender];
        uint256 currentHealth = _calculateCurrentHealth(msg.sender); // Apply decay before boosting

        // Apply health boost, capping at max scale
        garden.plantHealth = currentHealth.add(pruneHealthBoost);
         if (garden.plantHealth > HEALTH_SCALE) {
             garden.plantHealth = HEALTH_SCALE;
        }
        garden.lastStateChangeTime = block.timestamp; // Health state changed

        emit GardenPruned(msg.sender, pruneHealthBoost, garden.plantHealth);
    }


    // --- C. View Functions ---

    /**
     * @dev Returns the current state of a user's garden.
     * Note: plantHealth and growthBoostEndTime in the returned struct are the *stored* values,
     * not the dynamically calculated current values. Use calculateCurrentHealth and calculateCurrentGrowthBoost for real-time values.
     * @param user The address of the user.
     * @return GardenState struct.
     */
    function getGardenState(address user) public view returns (GardenState memory) {
        return gardens[user];
    }

     /**
     * @dev Returns the current Growth Point balance for a user.
     * @param user The address of the user.
     * @return The GP balance.
     */
    function getUserGP(address user) public view returns (uint256) {
        return gpBalances[user];
    }

    /**
     * @dev Calculates the user's current plant health, accounting for decay since last update.
     * @param user The address of the user.
     * @return The current plant health (scaled).
     */
    function calculateCurrentHealth(address user) public view hasGarden(user) returns (uint256) {
        return _calculateCurrentHealth(user);
    }

    /**
     * @dev Calculates the user's current growth boost multiplier.
     * @param user The address of the user.
     * @return The current growth boost multiplier (scaled, 1e18 = 1.0). Returns FACTOR_SCALE if boost expired.
     */
    function calculateCurrentGrowthBoost(address user) public view hasGarden(user) returns (uint224) { // Using uint224 to indicate this is a scaled multiplier
        GardenState storage garden = gardens[user];
        if (block.timestamp < garden.growthBoostEndTime) {
            // Boost is active
            return uint224(FACTOR_SCALE.add(fertilizeBoostAmount));
        } else {
            // Boost expired
            return uint224(FACTOR_SCALE); // 1.0x multiplier
        }
    }

    /**
     * @dev Calculates the potential SYM yield a user would receive if they harvested now.
     * @param user The address of the user.
     * @return The potential yield amount before the harvest fee.
     */
    function calculatePotentialYield(address user) public view hasGarden(user) returns (uint256) {
        GardenState storage garden = gardens[user];
        uint256 timeElapsed = block.timestamp.sub(garden.lastHarvestTime);

        if (timeElapsed == 0 || garden.stakedAmount == 0) {
            return 0;
        }

        uint256 yieldAmount = _calculateYieldSince(user, timeElapsed);
        // Apply harvest fee for reporting
         return yieldAmount.sub(yieldAmount.mul(harvestFeeRateScaled).div(FACTOR_SCALE));
    }

    /**
     * @dev Checks if a user has an active garden (staked amount > 0).
     * @param user The address of the user.
     * @return True if user has a garden, false otherwise.
     */
    function hasGarden(address user) public view returns (bool) {
        return gardens[user].stakedAmount > 0;
    }

    // --- Internal Calculation Helpers ---

    /**
     * @dev Internal function to calculate dynamic health including decay.
     * @param user The address of the user.
     * @return The current calculated health (scaled).
     */
    function _calculateCurrentHealth(address user) internal view returns (uint256) {
        GardenState storage garden = gardens[user];
        uint256 timeElapsed = block.timestamp.sub(garden.lastStateChangeTime);
        uint256 decayAmount = timeElapsed.mul(healthDecayRate).div(FACTOR_SCALE); // Decay scaled calculation

        if (decayAmount >= garden.plantHealth) {
            return 0; // Health cannot go below zero
        }
        return garden.plantHealth.sub(decayAmount);
    }

    /**
     * @dev Internal function to calculate the yield accumulated over a specific time period.
     * @param user The address of the user.
     * @param timeElapsed The time duration in seconds.
     * @return The total yield amount (before fee) for that period.
     */
    function _calculateYieldSince(address user, uint256 timeElapsed) internal view returns (uint256) {
        GardenState storage garden = gardens[user];

        if (garden.stakedAmount == 0 || timeElapsed == 0 || baseYieldRatePerSecond == 0) {
            return 0;
        }

        // Calculate effective health multiplier (0 to 1)
        uint256 currentHealth = _calculateCurrentHealth(user);
        uint256 healthMultiplier = currentHealth.mul(FACTOR_SCALE).div(HEALTH_SCALE); // Scale 0-1000 health to 0-1e18

        // Calculate effective boost multiplier (1.0 or 1.0 + boostAmount)
        uint256 boostMultiplier = calculateCurrentGrowthBoost(user);

        // Base yield = stakedAmount * baseYieldRatePerSecond * timeElapsed
        // Total yield = Base yield * healthMultiplier * boostMultiplier * environmentalFactor
        // Perform calculations carefully to avoid overflow and maintain precision
        // Use intermediate multiplications/divisions with FACTOR_SCALE

        uint256 yieldRatePerToken = baseYieldRatePerSecond
                                    .mul(healthMultiplier).div(FACTOR_SCALE)
                                    .mul(boostMultiplier).div(FACTOR_SCALE)
                                    .mul(environmentalFactor).div(FACTOR_SCALE);

        uint256 totalYield = garden.stakedAmount.mul(yieldRatePerToken).mul(timeElapsed).div(FACTOR_SCALE); // Adjust for rate per second

        return totalYield;
    }


    // --- D. Governance (GOVERNOR_ROLE) ---

    /**
     * @dev Sets the global environmental yield factor.
     * Requires GOVERNOR_ROLE.
     * @param factor The new environmental factor, scaled (e.g., 1e18 for 1.0).
     */
    function setEnvironmentalFactor(uint256 factor) external onlyRole(GOVERNOR_ROLE) {
        environmentalFactor = factor;
        emit EnvironmentalFactorSet(factor);
    }

     /**
     * @dev Sets the rate at which plant health decays per second.
     * Requires GOVERNOR_ROLE.
     * @param rate The new decay rate, scaled (e.g., 1e15 for 0.001 per second).
     */
    function setHealthDecayRate(uint256 rate) external onlyRole(GOVERNOR_ROLE) {
        healthDecayRate = rate;
        emit ConfigParameterSet("healthDecayRate", rate);
    }

    /**
     * @dev Sets the costs for the water action.
     * Requires GOVERNOR_ROLE.
     * @param symCost The cost in SYM.
     * @param gpCost The cost in GP.
     */
    function setWaterCosts(uint256 symCost, uint256 gpCost) external onlyRole(GOVERNOR_ROLE) {
        waterCostSYM = symCost;
        waterCostGP = gpCost;
        emit ConfigParameterSetWithCosts("waterCosts", symCost, gpCost);
    }

    /**
     * @dev Sets the health boost amount for the water action.
     * Requires GOVERNOR_ROLE.
     * @param boost The health increase amount (scaled).
     */
    function setWaterHealthBoost(uint256 boost) external onlyRole(GOVERNOR_ROLE) {
        waterHealthBoost = boost;
        emit ConfigParameterSet("waterHealthBoost", boost);
    }

    /**
     * @dev Sets the costs for the fertilize action.
     * Requires GOVERNOR_ROLE.
     * @param symCost The cost in SYM.
     * @param gpCost The cost in GP.
     */
    function setFertilizeCosts(uint256 symCost, uint256 gpCost) external onlyRole(GOVERNOR_ROLE) {
        fertilizeCostSYM = symCost;
        fertilizeCostGP = gpCost;
        emit ConfigParameterSetWithCosts("fertilizeCosts", symCost, gpCost);
    }

    /**
     * @dev Sets the boost parameters (amount and duration) for the fertilize action.
     * Requires GOVERNOR_ROLE.
     * @param boostAmount The yield multiplier amount (e.g., 5e17 for +0.5x).
     * @param boostDuration The duration in seconds.
     */
    function setFertilizeBoostParams(uint256 boostAmount, uint256 boostDuration) external onlyRole(GOVERNOR_ROLE) {
        fertilizeBoostAmount = boostAmount;
        fertilizeBoostDuration = boostDuration;
        emit ConfigParameterSetWithDuration("fertilizeBoostParams", boostAmount, boostDuration);
    }

    /**
     * @dev Sets the health boost amount for the prune action.
     * Requires GOVERNOR_ROLE.
     * @param boost The health increase amount (scaled).
     */
    function setPruneHealthBoost(uint256 boost) external onlyRole(GOVERNOR_ROLE) {
        pruneHealthBoost = boost;
        emit ConfigParameterSet("pruneHealthBoost", boost);
    }

    /**
     * @dev Sets the base yield rate per second per staked SYM token.
     * Requires GOVERNOR_ROLE.
     * @param ratePerSecond The new base rate, scaled (e.g., 1e10 for 0.000000001 SYM per sec per token).
     */
    function setBaseYieldRate(uint256 ratePerSecond) external onlyRole(GOVERNOR_ROLE) {
        baseYieldRatePerSecond = ratePerSecond;
        emit ConfigParameterSet("baseYieldRatePerSecond", ratePerSecond);
    }

    /**
     * @dev Sets the amount of GP earned per simulated action.
     * Requires GOVERNOR_ROLE.
     * @param amount The GP amount.
     */
    function setGpPerSimulatedAction(uint256 amount) external onlyRole(GOVERNOR_ROLE) {
        gpPerSimulatedAction = amount;
        emit ConfigParameterSet("gpPerSimulatedAction", amount);
    }

    /**
     * @dev Sets the fee rate applied to harvested yield.
     * Requires GOVERNOR_ROLE.
     * @param rateScaled The fee rate, scaled (e.g., 1e17 for 10%).
     */
    function setHarvestFeeRate(uint256 rateScaled) external onlyRole(GOVERNOR_ROLE) {
        require(rateScaled <= FACTOR_SCALE, "SGP: Fee rate cannot exceed 100%");
        harvestFeeRateScaled = rateScaled;
        emit ConfigParameterSet("harvestFeeRateScaled", rateScaled);
    }

    /**
     * @dev Grants the GOVERNOR_ROLE to an address.
     * Requires DEFAULT_ADMIN_ROLE or GOVERNOR_ROLE (if configured in AccessControl).
     * @param user The address to grant the role to.
     */
    function grantGovernorRole(address user) external onlyRole(DEFAULT_ADMIN_ROLE) { // Or restrict to only GOVERNOR_ROLE itself
        grantRole(GOVERNOR_ROLE, user);
    }

     /**
     * @dev Renounces the GOVERNOR_ROLE for the caller.
     * Requires GOVERNOR_ROLE.
     */
    function renounceGovernorRole() external onlyRole(GOVERNOR_ROLE) {
        renounceRole(GOVERNOR_ROLE, msg.sender);
    }

    /**
     * @dev Returns the hash of the GOVERNOR_ROLE.
     */
    function getGovernorRole() external pure returns (bytes32) {
        return GOVERNOR_ROLE;
    }


    // --- Inherited AccessControl Functions (also count towards the 20+ functions) ---
    // bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00...; // Included from AccessControl
    // function hasRole(bytes32 role, address account) external view returns (bool);
    // function _setupRole(bytes32 role, address account) internal; // Used in constructor
    // function _grantRole(bytes32 role, address account) internal; // Used in grantGovernorRole (and constructor)
    // function _revokeRole(bytes32 role, address account) internal; // Used in renounceGovernorRole
    // function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal; // Default setup in AccessControl
    // function getRoleAdmin(bytes32 role) external view returns (bytes32);
    // event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender); // Included
    // event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender); // Included
}
```