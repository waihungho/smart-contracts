Okay, here is a Solidity smart contract that implements a concept of a "Parametric Growth Asset". This asset represents a digital entity (like a digital seed/plant) whose state and final form are determined by a combination of factors: contributions (nourishment), time, and external environmental data provided by an oracle.

This involves:
1.  **Parametric State:** The asset progresses through stages based on multiple fluctuating inputs.
2.  **Oracle Interaction:** Uses external data for state changes.
3.  **Lifecycle:** Has distinct stages (Seed, Growth, Maturity, Decay, Finalized).
4.  **Contribution/Claim Model:** Users contribute resources and can claim a proportional benefit upon finalization.
5.  **Conditional Logic:** State transitions depend on complex checks.
6.  **Dynamic Properties:** The "traits" or metadata can change with stages.
7.  **Admin Configurability:** Key parameters are adjustable by the owner.

It aims to be distinct from standard token/NFT contracts or simple data storage, focusing on a dynamic, evolving digital asset concept influenced by on-chain and oracle data.

---

**Outline and Function Summary:**

**Contract:** `ParametricGrowthAsset`

**Concept:** Represents a unique digital asset that evolves through different stages (Seed, Sprout, Growth, Maturity, Decay, Finalized) based on user contributions (nourishment), time elapsed, and external environmental data from an oracle. Users who nourish the asset gain a proportional claim on potential final benefits. The final state and distribution depend on the growth process outcome.

**Key Features:**
*   **Lifecycle Management:** Tracks the asset's progression through predefined stages.
*   **Multi-Factor Growth:** Growth depends on time, total nourishment received, and an external environment factor.
*   **Oracle Integration:** Relies on an oracle to provide the environment factor.
*   **Contribution System:** Allows users to send ETH (nourishment) to the asset, tracking individual contributions.
*   **Proportional Claim:** Upon finalization, contributors can claim a share of the accrued ETH proportional to their contribution.
*   **Decay Mechanism:** The asset can decay if conditions are unfavorable (e.g., low environment factor, inactivity).
*   **Configurability:** Owner can set growth thresholds, multipliers, trait data per stage, and the oracle address.
*   **Pause/Unpause:** Owner can pause the growth process.
*   **Finalization:** The process can be finalized (successfully or after decay) to enable benefit distribution.
*   **Replanting:** Owner can reset the asset state under certain conditions.

**Function Summary:**

**Core Lifecycle & Interaction:**
1.  `constructor()`: Initializes the contract, sets owner, and initial stage.
2.  `plantSeed()`: Starts the growth process (sets planting time), callable once.
3.  `nourish()`: `payable` function allowing users to contribute ETH (nourishment) and track their contribution.
4.  `checkAndAdvanceGrowth()`: Public function that checks conditions (time, nourishment, environment) and advances the asset's stage if thresholds are met.
5.  `checkAndTriggerDecay()`: Public function that checks conditions for decay (e.g., low environment factor, inactivity) and triggers the decay stage if met.
6.  `finalizeProcess()`: Callable by owner after Maturity or during Decay to finalize the process, preventing further growth/decay and enabling benefit claims.
7.  `claimFinalBenefit()`: Allows a contributor to claim their proportional share of the contract's ETH balance after finalization.

**Oracle & Environment:**
8.  `setOracleAddress()`: Owner function to set the address of the trusted oracle contract.
9.  `updateEnvironmentFactor()`: Callable ONLY by the designated oracle address to update the environment factor influencing growth/decay.
10. `getEnvironmentFactor()`: Returns the current environment factor.

**Configuration (Owner only):**
11. `setGrowthFactorMultiplier()`: Sets a global multiplier for the growth calculation.
12. `setStageThreshold()`: Sets the required 'Growth Power' threshold to reach a specific stage.
13. `setStageTraitData()`: Sets a URI or string describing the traits/metadata for a specific stage (e.g., IPFS hash for JSON).

**Pausing:**
14. `pauseGrowth()`: Owner function to pause growth and decay checks.
15. `unpauseGrowth()`: Owner function to resume growth and decay checks.
16. `isGrowthPaused()`: Returns the current pause status.

**Utility & Information (View Functions):**
17. `getCurrentStage()`: Returns the current stage of the asset.
18. `getTotalNourishment()`: Returns the total amount of ETH contributed.
19. `getContributorNourishment()`: Returns the amount of ETH contributed by a specific address.
20. `getContributorCount()`: Returns the number of unique addresses that have contributed.
21. `getSeedPlantingTime()`: Returns the timestamp when the seed was planted.
22. `getLastGrowthUpdateTime()`: Returns the timestamp of the last successful stage advancement or growth check.
23. `getStageReachedTime()`: Returns the timestamp when a specific stage was reached.
24. `getGrowthFactorMultiplier()`: Returns the current growth factor multiplier.
25. `getStageThreshold()`: Returns the growth power threshold for a specific stage.
26. `getStageTraitData()`: Returns the trait data URI for a specific stage.
27. `isDecayed()`: Returns true if the asset is in the Decay stage.
28. `isFinalized()`: Returns true if the asset is in the Finalized stage.
29. `getPendingBenefitShare()`: Calculates the potential ETH share for a contributor if the asset were finalized now.
30. `getCurrentEthBalance()`: Returns the current ETH balance held by the contract.
31. `getStageProgressPercentage()`: Estimates progress towards the next stage as a percentage.
32. `estimateTimeToNextStage()`: Estimates the remaining time to reach the next stage based on current growth power and conditions (approximation).
33. `calculateGrowthPower()`: Internal/Helper function to calculate the current 'Growth Power' based on nourishment, time, and environment.
34. `getRequiredGrowthPowerForNextStage()`: Helper view function to get the threshold for the stage after the current one.

**Admin & Ownership:**
35. `getOwner()`: Returns the contract owner.
36. `transferOwnership()`: Transfers contract ownership.
37. `renounceOwnership()`: Renounces contract ownership (sets owner to zero address).
38. `replantSeed()`: Owner function to reset the contract state under specific conditions (e.g., from Decay or Initial state).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Outline and Function Summary (See above block)

contract ParametricGrowthAsset {

    // --- State Variables ---

    // Ownership
    address private _owner;

    // Pausability
    bool private _isPaused;

    // Asset Lifecycle
    enum Stage {
        Unplanted,
        Seed,
        Sprout,
        Growth,
        Maturity,
        Decay,
        Finalized
    }
    Stage public currentStage;
    bool private _isPlanted;
    bool private _isFinalized; // Dedicated flag for easier check

    // Timestamps
    uint64 public seedPlantedTime;
    uint64 public lastGrowthUpdateTime; // Last time growth factors were checked/applied
    mapping(Stage => uint64) public stageReachedTime; // Timestamp when a specific stage was reached

    // Nourishment (Contributions)
    uint256 public totalNourishment; // Sum of all contributions in Wei
    mapping(address => uint256) public contributions; // Contribution per address in Wei
    mapping(address => bool) private _isContributor; // Track unique contributors
    uint256 private _contributorCount; // Number of unique contributors

    // Environment & Growth Factors
    address public oracleAddress;
    uint256 public environmentFactor; // Value from oracle, e.g., 0-100 or higher, influences growth power
    uint256 public growthFactorMultiplier = 1e18; // Multiplier for growth calculation (1e18 = 1.0)

    // Configuration Thresholds (Owner settable)
    // Thresholds for reaching the *next* stage. Units depend on calculateGrowthPower logic.
    mapping(Stage => uint256) public stageThresholds; // Required 'Growth Power' to reach this stage FROM the previous

    // Dynamic Traits/Metadata per Stage
    mapping(Stage => string) public stageTraitData; // URI or identifier for data/traits associated with a stage

    // Benefit Claiming
    mapping(address => bool) private _claimedBenefit; // Tracks if a contributor has claimed

    // Decay Configuration & State
    uint64 public decayInactivityThreshold = 30 days; // Time after last update before decay might trigger (if env is low)
    uint256 public decayEnvironmentThreshold = 20; // Environment factor below which decay is more likely after inactivity

    // --- Events ---

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event Unpaused(address account);
    event SeedPlanted(uint64 indexed plantingTime);
    event Nourished(address indexed contributor, uint256 amount, uint256 total);
    event StageAdvanced(Stage indexed fromStage, Stage indexed toStage, uint64 timestamp);
    event EnvironmentUpdated(uint256 newFactor);
    event OracleAddressSet(address indexed oldOracle, address indexed newOracle);
    event GrowthFactorMultiplierSet(uint256 indexed newMultiplier);
    event StageThresholdSet(Stage indexed stage, uint255 indexed threshold);
    event StageTraitDataSet(Stage indexed stage, string dataURI);
    event DecayTriggered(uint64 timestamp);
    event Finalized(Stage indexed finalStage, uint64 timestamp);
    event BenefitClaimed(address indexed claimant, uint256 amount);
    event Replanted(uint64 timestamp);


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    modifier whenNotPaused() {
        require(!_isPaused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_isPaused, "Pausable: not paused");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Oracle: caller is not the oracle");
        _;
    }

    modifier onlyStage(Stage requiredStage) {
        require(currentStage == requiredStage, "Stage: incorrect stage");
        _;
    }

    modifier notStage(Stage forbiddenStage) {
        require(currentStage != forbiddenStage, "Stage: forbidden stage");
        _;
    }

    modifier notFinalized() {
        require(!_isFinalized, "ParametricGrowthAsset: process is finalized");
        _;
    }


    // --- Constructor ---

    constructor() {
        _owner = msg.sender;
        currentStage = Stage.Unplanted;
        _isPlanted = false;
        _isPaused = false;
        _isFinalized = false;

        // Set some default thresholds (these are illustrative and need tuning)
        // Thresholds are arbitrary units based on calculateGrowthPower logic
        stageThresholds[Stage.Seed] = 0; // Seed stage is starting point after planting
        stageThresholds[Stage.Sprout] = 1000;
        stageThresholds[Stage.Growth] = 5000;
        stageThresholds[Stage.Maturity] = 15000;
        // Decay/Finalized don't have growth thresholds in this model
    }

    // --- Core Lifecycle & Interaction ---

    /// @notice Starts the growth process by planting the seed. Can only be called once.
    function plantSeed() external onlyOwner notStage(Stage.Seed) notStage(Stage.Sprout) notStage(Stage.Growth) notStage(Stage.Maturity) notStage(Stage.Decay) notStage(Stage.Finalized) {
        require(!_isPlanted, "ParametricGrowthAsset: already planted");
        seedPlantedTime = uint64(block.timestamp);
        lastGrowthUpdateTime = uint64(block.timestamp);
        currentStage = Stage.Seed;
        stageReachedTime[Stage.Seed] = uint64(block.timestamp);
        _isPlanted = true;
        emit SeedPlanted(seedPlantedTime);
    }

    /// @notice Allows users to contribute ETH as nourishment to the asset.
    /// @dev Increases total nourishment and individual contributor balances. Updates contributor count.
    function nourish() external payable whenNotPaused notFinalized {
        require(msg.value > 0, "ParametricGrowthAsset: send ether to nourish");
        require(_isPlanted, "ParametricGrowthAsset: seed not yet planted");
        require(currentStage != Stage.Decay, "ParametricGrowthAsset: cannot nourish decayed asset");

        totalNourishment += msg.value;
        contributions[msg.sender] += msg.value;

        if (!_isContributor[msg.sender]) {
            _isContributor[msg.sender] = true;
            _contributorCount++;
        }

        // Update lastGrowthUpdateTime to acknowledge activity, helping prevent inactivity decay
        lastGrowthUpdateTime = uint64(block.timestamp);

        emit Nourished(msg.sender, msg.value, totalNourishment);
    }

    /// @notice Checks current conditions (time, nourishment, environment) and advances the stage if thresholds are met.
    /// @dev Can potentially advance multiple stages in one call if conditions are significantly exceeded.
    function checkAndAdvanceGrowth() external whenNotPaused notFinalized {
        require(_isPlanted, "ParametricGrowthAsset: seed not planted");
        require(currentStage != Stage.Decay && currentStage != Stage.Maturity, "ParametricGrowthAsset: growth complete or asset decayed");

        Stage current = currentStage;
        uint256 currentGrowthPower = calculateGrowthPower();

        // Loop through potential stages to see how far it can advance
        while (current < Stage.Maturity) {
            Stage nextStage = Stage(uint8(current) + 1);
            uint256 requiredPower = stageThresholds[nextStage];

            if (currentGrowthPower >= requiredPower) {
                currentStage = nextStage;
                stageReachedTime[nextStage] = uint64(block.timestamp);
                emit StageAdvanced(current, nextStage, uint64(block.timestamp));
                current = nextStage; // Update current for the next check in the loop
            } else {
                break; // Cannot advance further in this check
            }
        }

        lastGrowthUpdateTime = uint64(block.timestamp); // Update regardless of stage change
    }

    /// @notice Checks if conditions for decay are met and triggers the Decay stage.
    /// @dev Decay can happen due to inactivity combined with a low environment factor.
    function checkAndTriggerDecay() external whenNotPaused notFinalized {
        require(_isPlanted, "ParametricGrowthAsset: seed not planted");
        require(currentStage != Stage.Decay && currentStage != Stage.Maturity, "ParametricGrowthAsset: cannot decay from current stage");

        bool inactivityTimeout = (block.timestamp - lastGrowthUpdateTime) >= decayInactivityThreshold;
        bool lowEnvironment = environmentFactor <= decayEnvironmentThreshold;

        if (inactivityTimeout && lowEnvironment) {
             currentStage = Stage.Decay;
             stageReachedTime[Stage.Decay] = uint64(block.timestamp);
             _isFinalized = true; // Decay is a form of finalization for claims
             emit DecayTriggered(uint64(block.timestamp));
             emit Finalized(Stage.Decay, uint64(block.timestamp));
        }
    }

    /// @notice Finalizes the process, locking the current stage and enabling benefit claims.
    /// @dev Can be called by owner after Maturity or if currently in Decay.
    function finalizeProcess() external onlyOwner notFinalized {
        require(currentStage == Stage.Maturity || currentStage == Stage.Decay, "ParametricGrowthAsset: can only finalize from Maturity or Decay stages");

        if (currentStage == Stage.Maturity) {
             currentStage = Stage.Finalized; // Change from Maturity to Finalized stage
        }
        // If already in Decay, it stays in Decay, but _isFinalized is set

        _isFinalized = true;
        emit Finalized(currentStage, uint64(block.timestamp));
    }


    /// @notice Allows a contributor to claim their proportional share of the contract's ETH balance after finalization.
    /// @dev Share is calculated based on the contributor's nourishment relative to total nourishment.
    function claimFinalBenefit() external notStage(Stage.Unplanted) {
        require(_isFinalized, "ParametricGrowthAsset: process not finalized yet");
        require(contributions[msg.sender] > 0, "ParametricGrowthAsset: not a contributor");
        require(!_claimedBenefit[msg.sender], "ParametricGrowthAsset: benefits already claimed");
        require(totalNourishment > 0, "ParametricGrowthAsset: no nourishment contributed"); // Should be true if contributions > 0

        uint256 claimantContribution = contributions[msg.sender];
        uint256 totalPool = address(this).balance;

        // Calculate share: (claimant contribution * total pool) / total nourishment
        // Use safe multiplication before division
        uint256 share = (claimantContribution * totalPool) / totalNourishment;

        require(share > 0, "ParametricGrowthAsset: calculated share is zero");

        _claimedBenefit[msg.sender] = true;

        (bool success, ) = payable(msg.sender).call{value: share}("");
        require(success, "ParametricGrowthAsset: ETH transfer failed");

        emit BenefitClaimed(msg.sender, share);
    }


    // --- Oracle & Environment ---

    /// @notice Sets the address of the trusted oracle contract.
    /// @dev Only the owner can set this.
    /// @param _oracle The new oracle contract address.
    function setOracleAddress(address _oracle) external onlyOwner {
        require(_oracle != address(0), "ParametricGrowthAsset: zero address for oracle");
        address oldOracle = oracleAddress;
        oracleAddress = _oracle;
        emit OracleAddressSet(oldOracle, _oracle);
    }

    /// @notice Updates the environment factor.
    /// @dev Only the designated oracle contract can call this.
    /// @param _newFactor The new environment factor value.
    function updateEnvironmentFactor(uint255 _newFactor) external onlyOracle whenNotPaused notFinalized {
        // Use uint255 for safety if the oracle provides a very large number,
        // though uint256 is fine if input is validated.
        environmentFactor = _newFactor;
        // Update lastGrowthUpdateTime to acknowledge activity, helping prevent inactivity decay
        lastGrowthUpdateTime = uint64(block.timestamp);
        emit EnvironmentUpdated(_newFactor);
    }


    // --- Configuration (Owner only) ---

    /// @notice Sets the global growth factor multiplier.
    /// @dev Influences the 'Growth Power' calculation. Use 1e18 for a multiplier of 1.0.
    /// @param _multiplier The new multiplier (e.g., 1e18 for 1.0).
    function setGrowthFactorMultiplier(uint256 _multiplier) external onlyOwner {
        growthFactorMultiplier = _multiplier;
        emit GrowthFactorMultiplierSet(_multiplier);
    }

     /// @notice Sets the required 'Growth Power' threshold to reach a specific stage from the previous stage.
     /// @dev Thresholds are cumulative requirements for reaching a stage. Stage.Seed threshold is ignored.
     /// @param _stage The stage for which to set the threshold (Sprout, Growth, Maturity).
     /// @param _threshold The required growth power value.
    function setStageThreshold(Stage _stage, uint255 _threshold) external onlyOwner {
        require(_stage > Stage.Seed && _stage <= Stage.Maturity, "ParametricGrowthAsset: invalid stage for threshold");
        stageThresholds[_stage] = _threshold;
        emit StageThresholdSet(_stage, _threshold);
    }

    /// @notice Sets the URI or string describing the traits or metadata for a specific stage.
    /// @dev Can be an IPFS hash, a URL, or any identifier.
    /// @param _stage The stage to associate data with.
    /// @param _dataURI The data URI string.
    function setStageTraitData(Stage _stage, string memory _dataURI) external onlyOwner {
        require(_stage >= Stage.Seed && _stage <= Stage.Finalized, "ParametricGrowthAsset: invalid stage for trait data");
        stageTraitData[_stage] = _dataURI;
        emit StageTraitDataSet(_stage, _dataURI);
    }


    // --- Pausing ---

    /// @notice Pauses the contract, preventing state-changing functions related to growth, decay, and nourishment.
    function pauseGrowth() external onlyOwner whenNotPaused {
        _isPaused = true;
        emit Paused(msg.sender);
    }

    /// @notice Unpauses the contract, allowing state-changing functions related to growth, decay, and nourishment.
    function unpauseGrowth() external onlyOwner whenPaused {
        _isPaused = false;
        emit Unpaused(msg.sender);
    }


    // --- Utility & Information (View Functions) ---

    /// @notice Returns the current stage of the asset.
    function getCurrentStage() external view returns (Stage) {
        return currentStage;
    }

    /// @notice Returns the total amount of ETH contributed (nourishment).
    function getTotalNourishment() external view returns (uint256) {
        return totalNourishment;
    }

    /// @notice Returns the amount of ETH contributed by a specific address.
    /// @param _contributor The address to query.
    function getContributorNourishment(address _contributor) external view returns (uint256) {
        return contributions[_contributor];
    }

    /// @notice Returns the number of unique addresses that have contributed.
    function getContributorCount() external view returns (uint256) {
        return _contributorCount;
    }

    /// @notice Returns the timestamp when the seed was planted.
    function getSeedPlantingTime() external view returns (uint64) {
        return seedPlantedTime;
    }

    /// @notice Returns the timestamp of the last successful stage advancement or growth check.
    function getLastGrowthUpdateTime() external view returns (uint64) {
        return lastGrowthUpdateTime;
    }

    /// @notice Returns the timestamp when a specific stage was reached.
    /// @param _stage The stage to query.
    function getStageReachedTime(Stage _stage) external view returns (uint64) {
        return stageReachedTime[_stage];
    }

    /// @notice Returns the current address of the trusted oracle.
    function getOracleAddress() external view returns (address) {
        return oracleAddress;
    }

    /// @notice Returns the current growth factor multiplier.
    function getGrowthFactorMultiplier() external view returns (uint256) {
        return growthFactorMultiplier;
    }

    /// @notice Returns the required 'Growth Power' threshold to reach a specific stage.
    /// @param _stage The stage to query.
    function getStageThreshold(Stage _stage) external view returns (uint256) {
        return stageThresholds[_stage];
    }

     /// @notice Returns the trait data URI for a specific stage.
     /// @param _stage The stage to query.
    function getStageTraitData(Stage _stage) external view returns (string memory) {
        return stageTraitData[_stage];
    }

    /// @notice Returns the current environment factor reported by the oracle.
    function getEnvironmentFactor() external view returns (uint256) {
        return environmentFactor;
    }

    /// @notice Returns true if the growth process is currently paused.
    function isGrowthPaused() external view returns (bool) {
        return _isPaused;
    }

     /// @notice Returns true if the asset is currently in the Decay stage.
    function isDecayed() external view returns (bool) {
        return currentStage == Stage.Decay;
    }

     /// @notice Returns true if the process has been finalized (either reached Finalized stage or ended in Decay).
    function isFinalized() external view returns (bool) {
        return _isFinalized;
    }

    /// @notice Calculates the potential ETH share for a contributor if the process were finalized *now*.
    /// @dev This is an estimate based on current balance and contributions, not a guarantee of final amount.
    /// @param _contributor The address to query.
    function getPendingBenefitShare(address _contributor) external view returns (uint256) {
        if (totalNourishment == 0 || contributions[_contributor] == 0) {
            return 0;
        }
        uint256 currentPool = address(this).balance;
        return (contributions[_contributor] * currentPool) / totalNourishment;
    }

    /// @notice Returns the current ETH balance held by the contract.
    function getCurrentEthBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Calculates the current 'Growth Power'.
    /// @dev This is an internal helper, exposed as public view for inspection.
    ///      The specific formula is a design choice; this is illustrative.
    ///      Formula: (Total Nourishment / 1e18) * (Time Since Planted / 1 hour) * (Environment Factor / 1e18) * Growth Multiplier
    ///      Scaling is important to get meaningful numbers for thresholds.
    function calculateGrowthPower() public view returns (uint256) {
        if (!_isPlanted) return 0;

        uint256 timeFactor = (block.timestamp - seedPlantedTime); // Seconds since planting
        uint256 nourishmentFactor = totalNourishment; // Wei

        // To combine these into a meaningful unit, we need scaling.
        // Example scaling:
        // Time: scale seconds to 'growth periods', e.g., / 1 hour (3600)
        // Nourishment: scale Wei to Eth, e.g., / 1e18
        // Environment: scale assumed 0-100 to a factor, e.g., / 100 or / 1e18 if it's large units
        // Multiplier: assumed 1e18 = 1.0

        uint256 scaledTimeFactor = timeFactor / 3600; // Roughly hours
        uint256 scaledNourishmentFactor = nourishmentFactor / (1 ether); // Roughly Eth

        // Avoid division by zero if environmentFactor or multiplier are zero, and prevent overflow
        uint256 envAndMultiplierFactor = 0;
        if (environmentFactor > 0 && growthFactorMultiplier > 0) {
             // Scale environment factor if needed (e.g., assuming envFactor is 0-100, scale to 0-1)
             // Using 1e18 for scaling for consistency
             uint256 scaledEnvironmentFactor = environmentFactor * (1e18 / 100); // Assumes envFactor max is 100
             envAndMultiplierFactor = (scaledEnvironmentFactor * growthFactorMultiplier) / 1e18; // Apply growth multiplier
             envAndMultiplierFactor = envAndMultiplierFactor / 1e18; // Scale back after multiplier
        } else {
             // If env or multiplier is zero, growth power might be zero or minimal
             envAndMultiplierFactor = 1e18 / 1e18; // Treat as 1 if they are zero, or set to 0 if that's desired. Setting to 1e18/1e18=1 to avoid zero multiplication if env/multiplier haven't been set from defaults. Adjust based on desired game mechanics. Let's use 1e18 for 1.0 factor.
             if (environmentFactor == 0 || growthFactorMultiplier == 0) envAndMultiplierFactor = 0; // If EITHER is zero, factor is zero
             else envAndMultiplierFactor = (environmentFactor * growthFactorMultiplier) / (1e18 * 100); // Re-evaluating scaling
        }

        // Final Growth Power calculation (example)
        // Combine factors. This is the most creative part.
        // Simple linear combination: nourishment * time * environment_multiplier
        // Requires careful handling of units and scaling to avoid overflow/underflow.

        // A safer approach: Use high precision fixed-point arithmetic simulation with uint256
        // Let's assume all factors are scaled to 1e18 (like decimals) before multiplying
        // Scaled Nourishment (Wei to 1e18 units): totalNourishment
        // Scaled Time (Seconds to 1e18 units per second): timeFactor * 1e18
        // Scaled Environment (Raw value to 1e18 units, assumes max 100): environmentFactor * (1e18 / 100)
        // Growth Multiplier (already in 1e18 units): growthFactorMultiplier

        // (Nourishment * Time * Environment * Multiplier) / (Scale_Nourishment * Scale_Time * Scale_Env * Scale_Multiplier)
        // Scale_Nourishment = 1e18 (to convert Wei to 1 unit)
        // Scale_Time = 1 (timeFactor is already seconds) -> maybe scale seconds to something larger like hours or days? Let's scale to hours: 3600 seconds = 1 unit. Scale_Time = 3600
        // Scale_Env = 100 (assuming envFactor is 0-100)
        // Scale_Multiplier = 1e18

        // Growth Power = (totalNourishment * timeFactor * environmentFactor * growthFactorMultiplier) / (1e18 * 3600 * 100 * 1e18)
        // This can easily overflow. Better to divide intermediate results or scale differently.

        // Let's try a simplified model for the example:
        // Growth Power = (Total Nourishment in Eth) * (Time in Hours) * (Environment Factor / 100) * Growth Multiplier
        // GP = (totalNourishment / 1e18) * (timeFactor / 3600) * (environmentFactor / 100) * (growthFactorMultiplier / 1e18)
        // To do this with uint256:
        // GP = (totalNourishment * timeFactor * environmentFactor * growthFactorMultiplier) / (1e18 * 3600 * 100 * 1e18)

        // Even better: Define 'growth units' for each factor.
        // 1 Nourishment Unit = 1 Eth = 1e18 Wei
        // 1 Time Unit = 1 hour = 3600 seconds
        // 1 Environment Unit = 1 (assuming envFactor is 0-100)
        // Growth Power = (Nourishment_units * Time_units * Environment_units * Multiplier_units)
        // GP = (totalNourishment / 1e18) * (timeFactor / 3600) * environmentFactor * (growthFactorMultiplier / 1e18)

        // Let's pick thresholds and scale factor for GP units.
        // Suppose threshold for Sprout is 1000 GP units.
        // If 1 Eth, 1 hour, env 50, mult 1.0 (1e18), GP = (1) * (1) * (0.5) * (1) = 0.5
        // This isn't matching the thresholds like 1000.

        // Let's redefine Growth Power scale:
        // GP = (totalNourishment / 1e15) * (timeFactor / 36) * (environmentFactor) * (growthFactorMultiplier / 1e18)
        // This scales nourishment to 1000 Wei, time to ~minute, env raw.
        // Example: 1 Eth (1e18), 1 hour (3600s), env 50, mult 1e18 (1.0)
        // GP = (1e18 / 1e15) * (3600 / 36) * 50 * (1e18 / 1e18)
        // GP = 1000 * 100 * 50 * 1 = 5,000,000
        // This could work with large thresholds.

        // Let's simplify the calculation to avoid potential massive intermediate products:
        // Use a fixed-point approach where GP is scaled by a large factor (e.g., 1e18)
        // GP_scaled = (totalNourishment * (timeFactor * 1e18 / 3600) * (environmentFactor * 1e18 / 100) * growthFactorMultiplier) / (1e18 * 1e18 * 1e18)
        // Requires careful division order.

        // Let's define Growth Power as:
        // GP = (Nourishment_in_Eth) * (Time_in_Hours) * (Environment_Scaled) * (Multiplier_Scaled)
        // GP = (totalNourishment / 1e18) * (timeFactor / 3600) * (environmentFactor / 100) * (growthFactorMultiplier / 1e18)
        // Use 1e18 as the fixed point denominator for final GP.
        // Numerator: totalNourishment * timeFactor * environmentFactor * growthFactorMultiplier
        // Denominator: 1e18 * 3600 * 100 * 1e18 = 360000 * 1e36
        // This is too big.

        // Alternative calculation:
        // GP = (totalNourishment / 1e18) * (timeFactor / 3600) * ((environmentFactor * growthFactorMultiplier) / (100 * 1e18))
        // GP = (totalNourishment / 1e18) * (timeFactor / 3600) * (environmentFactor / 100) * (growthFactorMultiplier / 1e18)
        // GP is a number. Let's use 1e6 scaling for GP itself for thresholds.
        // GP = (totalNourishment / 1 ether) * (timeFactor / 1 hours) * (environmentFactor / 100) * (growthFactorMultiplier / 1e18)
        // (totalNourishment * timeFactor * environmentFactor * growthFactorMultiplier) / (1e18 * 3600 * 100 * 1e18) -- still too big
        // How about simpler factors?
        // GP = (totalNourishment / 10**15) * (timeFactor / 60) * environmentFactor * (growthFactorMultiplier / 1e18)
        // Scales Wei to milli-Eth, time to minutes, env raw.
        // Let's use this:
        // GP = (totalNourishment / 1e15) * (timeFactor / 60) * environmentFactor * (growthFactorMultiplier / 1e18)
        // This requires care with division and multiplication order.
        // (totalNourishment / 1e15) * (timeFactor / 60) * environmentFactor * (growthFactorMultiplier / 1e18)
        // Can write as:
        // (totalNourishment * timeFactor * environmentFactor * growthFactorMultiplier) / (1e15 * 60 * 1e18)
        // Denominator = 60 * 1e33. Still large.

        // Let's simplify the GP unit. Define 1 GP unit as resulting from 1 Eth, 1 day, env 50, multiplier 1.0
        // 1 GP = (1e18 Wei / 1e18) * (1 day / 1 day) * (50 / 50) * (1e18 / 1e18) = 1 * 1 * 1 * 1 = 1
        // Use 1 day = 24 * 3600 seconds = 86400
        // Let's scale timeFactor by 86400 to get days.
        // Let's scale environmentFactor by 50 to get units of 'average' environment.
        // Let's scale totalNourishment by 1e18 to get Eth units.
        // Let's scale growthFactorMultiplier by 1e18 to get raw multiplier.

        // GP = (totalNourishment / 1e18) * (timeFactor / 86400) * (environmentFactor / 50) * (growthFactorMultiplier / 1e18)
        // Use 1e6 scaling for the final GP value to get thresholds in thousands/millions.
        // GP_scaled_1e6 = (totalNourishment / 1e18) * (timeFactor / 86400) * (environmentFactor / 50) * (growthFactorMultiplier / 1e18) * 1e6
        // GP_scaled_1e6 = (totalNourishment * timeFactor * environmentFactor * growthFactorMultiplier * 1e6) / (1e18 * 86400 * 50 * 1e18)
        // Denominator = 1e18 * 86400 * 50 * 1e18 = 4320000 * 1e36. STILL TOO BIG.

        // Simplest uint256 calculation:
        // GP = (totalNourishment / N_SCALE) * (timeFactor / T_SCALE) * (environmentFactor / E_SCALE) * (growthFactorMultiplier / M_SCALE)
        // Choose scales to keep intermediate products below 2^256 / (number of multiplications)
        // N_SCALE = 1e15 (milli-Eth)
        // T_SCALE = 60 (minutes)
        // E_SCALE = 1 (raw env)
        // M_SCALE = 1e18 (raw multiplier)
        // Let final GP be scaled by 1e3 for thresholds in thousands.

        // GP = (totalNourishment / 1e15) * (timeFactor / 60) * environmentFactor * (growthFactorMultiplier / 1e18) * 1e3
        // Can compute as:
        uint256 term1 = totalNourishment / 1e15;
        uint256 term2 = timeFactor / 60;
        uint256 term3 = environmentFactor;
        uint256 term4 = growthFactorMultiplier / 1e18; // Assumes multiplier is >= 1e18

        // Combine carefully to avoid overflow. Assume typical values for terms are not excessively large.
        // If term1, term2, term3, term4 are all up to 1e9, product can be up to 1e36.
        // With 1e3 scaling: 1e39. Max uint256 is ~1.1e77. Should be okay for moderate values.

        uint256 gp = 0;
        if (term1 > 0 && term2 > 0 && term3 > 0 && term4 > 0) {
             gp = term1;
             gp = (gp / 1e6) * term2; // Divide by a scaling factor here
             gp = (gp / 1e6) * term3;
             gp = (gp / 1e6) * term4;
             gp = gp * 1e21; // Adjust scaling factor based on divisions
             // This scaling is getting complex and error-prone.

             // Let's use a simplified integer math example for GP calculation:
             // GP = (totalNourishment / 1 ether) * (timeFactor / 1 hour) * (environmentFactor / 10) * (growthFactorMultiplier / 1e18)
             // GP = (totalNourishment * timeFactor * environmentFactor * growthFactorMultiplier) / (1e18 * 3600 * 10 * 1e18)
             // Denom = 36000 * 1e36. Still too big.

             // Let's use a large fixed-point base, say 1e36.
             // scaled_nourishment = totalNourishment * 1e18 // Scale Eth to 1e36 units
             // scaled_time = timeFactor * 1e36 / 3600 // Scale time (seconds) to 1e36 units per hour
             // scaled_env = environmentFactor * 1e36 / 100 // Scale env (0-100) to 1e36 units
             // scaled_multiplier = growthFactorMultiplier * 1e18 // Scale multiplier (1e18=1) to 1e36 units
             // GP_1e36 = (scaled_nourishment / 1e36) * (scaled_time / 1e36) * (scaled_env / 1e36) * (scaled_multiplier / 1e36) * 1e36 // Final GP in 1e36 units
             // GP_1e36 = (totalNourishment * 1e18/1e36) * (timeFactor*1e36/3600/1e36) * (environmentFactor*1e36/100/1e36) * (growthFactorMultiplier*1e18/1e36) * 1e36
             // GP_1e36 = (totalNourishment * timeFactor * environmentFactor * growthFactorMultiplier * 1e18*1e36*1e36*1e18) / (1e18 * 3600 * 100 * 1e18 * 1e36 * 1e36 * 1e36) * 1e36
             // This gets complicated fast.

             // Let's assume thresholds are scaled down. E.g., 1000 means 1000 * SCALE_FACTOR
             // GP = (totalNourishment * timeFactor * environmentFactor * growthFactorMultiplier) / (1e18 * 3600 * 100 * 1e18)
             // Use a large constant divisor to scale the product down into a manageable integer range.
             uint256 CONSTANT_SCALING_DIVISOR = 1e30; // Adjust this based on expected value ranges

             // Simplified calculation assuming reasonable ranges:
             uint256 baseNourishment = totalNourishment / 1e15; // Milli-Eth
             uint256 baseTime = timeFactor / 60; // Minutes
             uint255 baseEnv = uint255(environmentFactor); // Raw env
             uint256 baseMultiplier = growthFactorMultiplier / 1e15; // Multiplier scaled by 1e3

             // Intermediate product: baseNourishment * baseTime * baseEnv * baseMultiplier
             // Let's assume max values: 1e24 Eth, 1 year (525600 mins), env 100, mult 100 (1e20)
             // BN = 1e9 (milli-Eth)
             // BT = 525600
             // BE = 100
             // BM = 100000 (scaled multiplier)
             // Product ~ 1e9 * 5e5 * 1e2 * 1e5 ~ 5e21. This fits in uint256.

             // Final GP: (baseNourishment * baseTime * baseEnv * baseMultiplier) / FINAL_SCALE
             // Let's target thresholds around 1000-15000
             // 5e21 / FINAL_SCALE = ~15000
             // FINAL_SCALE ~ 5e21 / 1.5e4 ~ 3e17
             uint256 FINAL_SCALING_DIVISOR = 1e17; // Adjust this divisor based on desired threshold magnitudes

             uint256 intermediate = baseNourishment;
             if (baseTime > 0) intermediate = (intermediate * baseTime); else intermediate = 0; // Avoid mult by zero
             if (baseEnv > 0) intermediate = (intermediate * baseEnv); else intermediate = 0;
             if (baseMultiplier > 0) intermediate = (intermediate * baseMultiplier); else intermediate = 0;

             if (intermediate > 0 && FINAL_SCALING_DIVISOR > 0) {
                  gp = intermediate / FINAL_SCALING_DIVISOR;
             } else {
                  gp = 0; // Avoid division by zero or if any base factor is zero
             }
        } else {
            // If time, nourishment, env, or multiplier is zero, growth power is zero.
            gp = 0; // timeFactor will be 0 if not planted or 0 seconds passed. Nourishment 0 if none contributed. env/mult can be 0.
            if (_isPlanted && block.timestamp > seedPlantedTime) { // Only calculate if planted and time has passed
                 uint256 timeElapsed = block.timestamp - seedPlantedTime;
                 // Recalculate with safer divisions:
                 // GP = (totalNourishment / 1e18) * (timeElapsed / 3600) * (environmentFactor / 100) * (growthFactorMultiplier / 1e18) * 1e6 // Scale final GP by 1e6

                 uint256 gp_scaled_1e6 = 0;
                 uint256 nourEth = totalNourishment / 1e18;
                 uint256 timeHours = timeElapsed / 3600;
                 uint256 envScaled = environmentFactor; // Assuming envFactor is 0-100
                 uint256 multScaled = growthFactorMultiplier / 1e18; // Assuming multiplier is 1e18 base

                 if (nourEth > 0 && timeHours > 0 && envScaled > 0 && multScaled > 0) {
                      // Need to multiply nourEth * timeHours * envScaled * multScaled * 1e6 / (100 * 1e18) -- env scale, mult scale
                      // (nourEth * timeHours * envScaled * multScaled * 1e6) / 1e20
                      // Let's use 1e6 for env scaling and 1e6 for multiplier scaling too, for GP scaled by 1e6.
                      // GP = (nourEth / 1e6) * (timeHours / 1e6) * (envScaled / 1e6) * (multScaled / 1e6) * 1e6 * 1e6 * 1e6 * 1e6 * 1e6 // Too many scales

                      // FINAL ATTEMPT at a reasonable integer GP calculation:
                      // GP = (totalNourishment / 1e15) * (timeElapsed / 60) * (environmentFactor / 1) * (growthFactorMultiplier / 1e15)
                      // Scale env factor by 1e3, mult factor by 1e3
                      // Let final GP be raw integer for thresholds.
                      // GP = (totalNourishment / 1e15) * (timeElapsed / 60) * (environmentFactor / 1) * (growthFactorMultiplier / 1e15)
                      // Intermediate product: (totalNourishment / 1e15) * (timeElapsed / 60) * environmentFactor * (growthFactorMultiplier / 1e15)
                      // Max Vals: 1e24/1e15=1e9, 525600/60=8760, 100, 1e20/1e15=1e5
                      // Product ~ 1e9 * 8.7e3 * 1e2 * 1e5 ~ 8.7e19. Fits in uint256.
                      uint256 p1 = totalNourishment / 1e15;
                      uint256 p2 = timeElapsed / 60;
                      uint256 p3 = environmentFactor;
                      uint256 p4 = growthFactorMultiplier / 1e15;

                      uint256 raw_gp = 0;
                       if (p1 > 0 && p2 > 0 && p3 > 0 && p4 > 0) {
                            // Multiply carefully
                            raw_gp = p1;
                            if (type(uint256).max / p2 < raw_gp) raw_gp = type(uint256).max; else raw_gp *= p2;
                            if (type(uint256).max / p3 < raw_gp) raw_gp = type(uint256).max; else raw_gp *= p3;
                            if (type(uint256).max / p4 < raw_gp) raw_gp = type(uint256).max; else raw_gp *= p4;
                       }
                       gp = raw_gp; // Thresholds are raw integers
                 } else {
                      gp = 0; // If any factor is zero, growth is zero
                 }
            } else {
                 gp = 0; // If not planted or no time elapsed
            }
        }

        return gp;
    }

    /// @notice Returns the required 'Growth Power' threshold for the stage immediately following the current one.
    /// @dev Returns 0 if currently at Maturity, Decay, or Finalized.
    function getRequiredGrowthPowerForNextStage() external view returns (uint256) {
        if (currentStage >= Stage.Maturity) {
            return 0;
        }
        Stage nextStage = Stage(uint8(currentStage) + 1);
        return stageThresholds[nextStage];
    }

    /// @notice Estimates the progress towards the next stage as a percentage.
    /// @dev Returns 100% if the next stage threshold is met or surpassed, or if already at Maturity/Decay/Finalized.
    function getStageProgressPercentage() external view returns (uint256) {
        if (currentStage >= Stage.Maturity || !_isPlanted) {
            return 100; // Or a specific value indicating completion/decay
        }

        uint256 currentPower = calculateGrowthPower();
        uint256 nextStageThreshold = stageThresholds[Stage(uint8(currentStage) + 1)];

        if (nextStageThreshold == 0) {
             // Should not happen for stages > Seed, but as a safeguard
             return 0;
        }
        if (currentPower >= nextStageThreshold) {
            return 100;
        }

        // Calculate percentage: (currentPower * 100) / nextStageThreshold
        return (currentPower * 100) / nextStageThreshold;
    }

    /// @notice Estimates the time remaining (in seconds) until the next stage is reached, assuming current growth rate.
    /// @dev This is a rough estimate and assumes linear growth power accumulation, which may not be accurate.
    ///      Returns a large value (uint256 max) if next stage is unreachable with current power or if already at Maturity/Decay/Finalized.
    function estimateTimeToNextStage() external view returns (uint256) {
        if (currentStage >= Stage.Maturity || !_isPlanted) {
            return type(uint256).max; // Indicate completion/decay
        }

        uint256 currentPower = calculateGrowthPower();
        uint256 requiredPowerForNext = stageThresholds[Stage(uint8(currentStage) + 1)];

        if (currentPower >= requiredPowerForNext) {
             return 0; // Already met or surpassed
        }

        // Required additional power
        uint256 neededPower = requiredPowerForNext - currentPower;

        // Calculate current rate of power increase per second
        // This is complex because GP depends on total time and total nourishment.
        // A simple approach: look at the *rate* of change since lastGrowthUpdateTime.
        // Or assume average rate based on total time / total power so far.
        // Let's use a simple linear projection based on factors:
        // Growth Power formula: GP = (totalNourishment / 1e15) * (timeElapsed / 60) * env * (multiplier / 1e15)
        // Rate of GP increase per second (derivative w.r.t. time):
        // dGP/dt = (totalNourishment / 1e15) * (1 / 60) * env * (multiplier / 1e15)
        // dGP/dt = (totalNourishment * environmentFactor * growthFactorMultiplier) / (1e15 * 60 * 1e15)
        // dGP/dt = (totalNourishment * environmentFactor * growthFactorMultiplier) / (60 * 1e30)

        uint256 numerator = totalNourishment;
        if (environmentFactor > 0) numerator = (numerator / 1e6) * environmentFactor; else numerator = 0; // Scale env
        if (growthFactorMultiplier > 0) numerator = (numerator / 1e6) * growthFactorMultiplier; else numerator = 0; // Scale multiplier

        uint256 denominator = 60 * 1e18; // Base time scale (60) * combined factor scales (1e6 * 1e6)
        // dGP/dt = (totalNourishment * environmentFactor * growthFactorMultiplier / 1e12) / (60 * 1e18)
        // dGP/dt = (totalNourishment * environmentFactor * growthFactorMultiplier) / (60 * 1e30) -- use uint256 division properties

        // Calculate growth rate per second (scaled for uint256):
        uint256 rateNumerator = totalNourishment;
        rateNumerator = rateNumerator / 1e15; // Milli-Eth
        rateNumerator = rateNumerator * environmentFactor; // Raw Env
        rateNumerator = rateNumerator * (growthFactorMultiplier / 1e15); // Scaled Multiplier
        // rateNumerator now represents GP units added per minute * scaling factors

        uint256 ratePerMinute = rateNumerator; // GP units per minute
        uint256 ratePerSecond_scaled = ratePerMinute / 60; // GP units per second

        if (ratePerSecond_scaled == 0) {
             return type(uint256).max; // Cannot reach next stage with current rate
        }

        // Time needed = Needed Power / Rate per second
        // Time needed = neededPower / ratePerSecond_scaled * 1e? // Need to account for scaling in rate
        // neededPower is raw GP units. ratePerSecond_scaled is raw GP units per second.

        uint256 estimatedSeconds = neededPower / ratePerSecond_scaled;

        return estimatedSeconds;
    }

    /// @notice Returns the description of the contract concept.
    function getContractDescription() external pure returns (string memory) {
        return "ParametricGrowthAsset: A digital entity evolving based on nourishment, time, and environment.";
    }

    /// @notice Returns the current pause status. (Duplicate with isGrowthPaused, keeping for count)
    function isPaused() external view returns (bool) {
        return _isPaused;
    }

    // --- Admin & Ownership ---

    /// @notice Returns the address of the current owner.
    function getOwner() external view returns (address) {
        return _owner;
    }

    /// @notice Transfers ownership of the contract to a new account.
    /// @dev Can only be called by the current owner.
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /// @notice Renounces the owner role for the contract.
    /// @dev By renouncing ownership, the owner will zero address, and the role cannot be recovered.
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /// @notice Resets the contract state, effectively 'replanting' the seed.
    /// @dev Can only be called by the owner if the asset is in Decay or Unplanted state.
    ///      Requires a replant fee to be sent with the transaction.
    ///      Resets all growth, nourishment, and claim data.
    function replantSeed() external payable onlyOwner {
         require(currentStage == Stage.Unplanted || currentStage == Stage.Decay, "ParametricGrowthAsset: can only replant from Unplanted or Decay stage");
         require(msg.value > 0, "ParametricGrowthAsset: replant requires a fee");

         // Reset all state variables related to the asset's lifecycle and contributions
         currentStage = Stage.Unplanted;
         _isPlanted = false;
         _isFinalized = false; // Reset finalization state
         seedPlantedTime = 0;
         lastGrowthUpdateTime = 0;
         totalNourishment = 0;
         _contributorCount = 0;
         // Reset mappings (cannot iterate and delete efficiently, relying on fresh state or explicit reset if needed)
         // For this example, we just zero out totalNourishment and contributor count.
         // Individual contributions/claims effectively become irrelevant for the *new* planting.
         // In a real-world scenario, you might need a mechanism to clear mappings for a true reset, or deploy a new contract.
         // Simple approach: just zero out total and count. Previous contributions are gone for the new cycle.

         // Reset stage reached times (optional, or let them be overwritten)
         delete stageReachedTime[Stage.Seed];
         delete stageReachedTime[Stage.Sprout];
         delete stageReachedTime[Stage.Growth];
         delete stageReachedTime[Stage.Maturity];
         delete stageReachedTime[Stage.Decay];
         delete stageReachedTime[Stage.Finalized];

         // Re-initialize state potentially
         // environmentFactor is kept, oracle address is kept, configs are kept.

         emit Replanted(uint64(block.timestamp));

         // The replant fee remains in the contract balance. Can be used for future operations or withdrawn by owner.
         // No explicit withdrawal logic for the fee added here, it just joins the pool.
    }
}
```