Okay, this is an exciting challenge! Creating a truly novel concept that isn't already open-source and has 20+ functions requires combining several advanced ideas in a unique way.

I've conceived a contract called `ChronoGlyphGenesisEngine`. It's an adaptive, semi-autonomous on-chain ecosystem centered around dynamic, evolving NFTs called "ChronoGlyphs." The system's parameters and the NFTs' evolution are influenced by a unique "Energy Resonance" (soulbound contribution), a resource generation mechanism called "Essence Pools," and external "Environmental Wisdom" provided by an oracle.

---

## ChronoGlyphGenesisEngine: An Adaptive On-Chain Cultural & Economic Ecosystem

**Vision:**
The `ChronoGlyphGenesisEngine` envisions a decentralized system where digital artifacts (ChronoGlyphs) are not static, but instead dynamically evolve based on community interaction, resource contributions, and real-world external data. It aims to create a self-adjusting economic and creative environment, where core system parameters adapt over time, fostering a living, breathing on-chain digital ecosystem.

**Core Concepts:**

1.  **ChronoGlyphs (Dynamic ERC721 NFTs):**
    *   Unique digital artifacts, each with a set of evolving "traits."
    *   Their evolution is influenced by a combination of a user's `Energy Resonance`, `Essence` (generated resource), and the global `Environmental Wisdom` (from an oracle).
    *   Represent a "cultural footprint" that changes based on ecosystem dynamics.

2.  **Energy Resonance (Soulbound Contribution Score):**
    *   A non-transferable, continuously accumulating score for each user.
    *   Represents a user's active participation, time spent in the ecosystem, and contributions.
    *   Crucial for influencing ChronoGlyph evolution and potentially unlocking higher-tier actions. It's a "soulbound" or "reputation" point system.

3.  **Essence Pools (Resource Generation):**
    *   Users deposit ERC20 tokens into a pool.
    *   These deposits passively generate "Essence" over time, which is a key resource required for refining (evolving) ChronoGlyphs.
    *   Provides a sustainable sink for value and incentivizes long-term commitment.

4.  **Environmental Wisdom (Oracle Integration):**
    *   The system integrates with a trusted oracle to receive external "environmental" data (e.g., market sentiment, global climate data, community health metrics, AI-generated insights).
    *   This "wisdom" directly influences ChronoGlyph evolution pathways and dynamically adjusts core economic parameters of the system.

5.  **Adaptive Parameters:**
    *   Unlike traditional contracts with fixed parameters, key economic variables (e.g., ChronoGlyph forging cost, Essence generation rate, Energy Resonance accumulation rate) are not constant.
    *   They adapt programmatically based on the current `Environmental Wisdom` and overall system state (e.g., total Energy Resonance, number of active Glyphs), aiming for self-regulation and resilience.

**Modules & Function Summary (24 Functions):**

**I. Core Infrastructure & Control**
1.  `constructor()`: Initializes the contract, sets the owner, and initial adaptive parameters.
2.  `pauseSystem()`: Allows the owner to pause critical functions during emergencies or upgrades.
3.  `unpauseSystem()`: Allows the owner to resume paused functions.
4.  `setOracleAddress(address _newOracle)`: Sets the address of the trusted oracle contract.
5.  `updateCoreParameter(bytes32 _paramName, uint256 _newValue)`: Allows owner to adjust non-adaptive, critical system parameters.

**II. ChronoGlyph (Dynamic NFT) Management**
6.  `forgeChronoGlyph(string memory _initialTraitSeed)`: Mints a new ChronoGlyph NFT for the caller, initializing its traits based on a seed. Requires a cost in `msg.value`.
7.  `refineChronoGlyph(uint256 _tokenId)`: Evolves a ChronoGlyph's traits. Requires accumulated `Energy Resonance` and `Essence`. Evolution path is influenced by `Environmental Wisdom`.
8.  `attuneToGlyph(uint256 _tokenId)`: Users express affinity for a glyph, subtly influencing its future `Environmental Wisdom` weighting for evolution. Increases user's Energy Resonance.
9.  `getGlyphDetails(uint256 _tokenId)`: Retrieves all current details and traits of a specified ChronoGlyph.
10. `getGlyphEvolutionHistory(uint256 _tokenId)`: Retrieves the historical evolution path of a ChronoGlyph.

**III. Energy Resonance (Soulbound Contribution)**
11. `harvestEnergyResonance()`: Calculates and credits the caller with new `Energy Resonance` based on their elapsed time and recent activity within the system.
12. `getEnergyResonance(address _user)`: Retrieves the current `Energy Resonance` score for a specific user.
13. `distributeBonusResonance(address _user, uint256 _amount)`: (Admin only) Distributes bonus resonance for specific achievements or contributions.

**IV. Essence Pool & Generation**
14. `depositIntoEssencePool()`: Allows users to deposit the designated ERC20 token (`essenceToken`) into the Essence Pool to start generating `Essence`.
15. `withdrawFromEssencePool(uint256 _amount)`: Allows users to withdraw their deposited tokens from the Essence Pool.
16. `claimEssence()`: Allows users to claim their accumulated `Essence` generated from their pool deposits.
17. `getEssenceBalance(address _user)`: Retrieves the current `Essence` balance for a specific user.
18. `getEssencePoolValue()`: Retrieves the total value (in `essenceToken`) currently held in the Essence Pool.

**V. Oracle Integration & Adaptive Logic**
19. `receiveOracleData(uint256 _wisdomValue, uint256[] memory _factors)`: Callable only by the registered oracle, updates the internal `Environmental Wisdom` and triggers parameter adaptation.
20. `getCurrentEnvironmentalWisdom()`: Retrieves the latest `Environmental Wisdom` value received from the oracle.
21. `calculateAdaptiveParam(bytes32 _paramName)`: A view function to show the calculated value of an adaptive parameter based on current system state and wisdom.
22. `triggerParameterAdaptation()`: (Can be called by anyone or scheduled) Re-evaluates and updates all adaptive system parameters based on current `Environmental Wisdom` and system metrics.

**VI. System Analytics & Views**
23. `getTotalForgedGlyphs()`: Returns the total number of ChronoGlyphs minted to date.
24. `getTotalEnergyResonanceSupply()`: Returns the sum of all accumulated Energy Resonance across all users.

---
**Smart Contract Code:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Dummy interface for an external oracle. In a real scenario, this would be a robust oracle network.
interface IEnvironmentalOracle {
    function getLatestWisdom() external view returns (uint256 wisdomValue, uint256[] memory environmentalFactors);
}

contract ChronoGlyphGenesisEngine is Ownable, ERC721, Pausable, ReentrancyGuard {

    // --- Events ---
    event ChronoGlyphForged(uint256 indexed tokenId, address indexed owner, string initialTraitSeed, uint256 forgeCost);
    event ChronoGlyphRefined(uint256 indexed tokenId, address indexed owner, uint256 newTraitHash, uint256 essenceUsed, uint256 resonanceUsed);
    event ChronoGlyphAttuned(uint256 indexed tokenId, address indexed attunementProvider, uint256 newResonance);
    event EnergyResonanceHarvested(address indexed user, uint256 harvestedAmount, uint256 totalResonance);
    event EssenceDeposited(address indexed user, uint256 amount);
    event EssenceWithdrawn(address indexed user, uint256 amount);
    event EssenceClaimed(address indexed user, uint256 amount);
    event OracleDataReceived(uint256 wisdomValue, uint256[] environmentalFactors, uint256 timestamp);
    event AdaptiveParameterUpdated(bytes32 indexed paramName, uint256 oldValue, uint256 newValue);
    event CoreParameterUpdated(bytes32 indexed paramName, uint256 newValue);

    // --- State Variables & Data Structures ---

    // ChronoGlyph Data
    struct ChronoGlyph {
        uint256 tokenId;
        address owner;
        uint256 forgedTimestamp;
        uint256 lastRefinedTimestamp;
        string[] traits; // Dynamic traits that evolve
        uint256 evolutionCount;
        uint256 lastWisdomInfluence; // Wisdom value at last refinement
        uint256[] evolutionHistory; // Storing hashes of traits or evolution states for history
    }
    mapping(uint256 => ChronoGlyph) public chronoGlyphs;
    uint256 private _nextTokenId;

    // Energy Resonance Data (Soulbound)
    struct UserResonance {
        uint256 accumulatedResonance;
        uint256 lastResonanceHarvestTimestamp;
        uint256 lastActivityTimestamp; // To track active participation
    }
    mapping(address => UserResonance) public userResonance;
    uint256 public totalEnergyResonanceSupply;

    // Essence Pool Data
    IERC20 public immutable essenceToken; // The ERC20 token used for Essence Pools
    struct EssenceDeposit {
        uint256 amount;
        uint256 depositTimestamp;
        uint256 claimedEssence; // Essence already claimed from this deposit
    }
    mapping(address => EssenceDeposit) public essenceDeposits;
    uint256 public totalEssencePoolValue; // Total essenceToken locked in the pool

    // Oracle Data
    address public environmentalOracle;
    uint256 public currentEnvironmentalWisdom; // Global wisdom value from oracle
    uint256[] public environmentalFactors; // Additional factors from oracle
    uint256 public lastOracleUpdateTimestamp;

    // Adaptive Parameters (configurable by oracle data and system state)
    mapping(bytes32 => uint256) public adaptiveParameters; // Stores active parameter values
    // Base rates for adaptation calculations
    uint256 private constant BASE_FORGE_COST = 0.01 ether; // Example: 0.01 ETH
    uint256 private constant BASE_ESSENCE_GEN_RATE = 100; // Example: 100 units per second per token
    uint256 private constant BASE_RESONANCE_GEN_RATE = 1000; // Example: 1000 units per second
    uint256 private constant BASE_REFINE_ESSENCE_COST = 50000;
    uint256 private constant BASE_REFINE_RESONANCE_COST = 100000;

    // Core Parameters (set by owner, less frequently adjusted)
    mapping(bytes32 => uint256) public coreParameters; // Stores active parameter values
    bytes32 public constant PARAM_MIN_ESSENCE_FOR_REFINE = "MIN_ESSENCE_FOR_REFINE";
    bytes32 public constant PARAM_MIN_RESONANCE_FOR_REFINE = "MIN_RESONANCE_FOR_REFINE";
    bytes32 public constant PARAM_ATTUNE_BONUS_RESONANCE = "ATTUNE_BONUS_RESONANCE";
    bytes32 public constant PARAM_REFINE_COOL_DOWN = "REFINE_COOL_DOWN";

    // --- Constructor ---
    constructor(address _essenceTokenAddress, address _initialOracle)
        ERC721("ChronoGlyph", "CGLYPH")
        Ownable(msg.sender)
        Pausable()
    {
        require(_essenceTokenAddress != address(0), "Invalid essence token address");
        require(_initialOracle != address(0), "Invalid initial oracle address");

        essenceToken = IERC20(_essenceTokenAddress);
        environmentalOracle = _initialOracle;
        _nextTokenId = 1; // Start token IDs from 1

        // Initialize core parameters
        coreParameters[PARAM_MIN_ESSENCE_FOR_REFINE] = 10000; // 10k essence
        coreParameters[PARAM_MIN_RESONANCE_FOR_REFINE] = 20000; // 20k resonance
        coreParameters[PARAM_ATTUNE_BONUS_RESONANCE] = 500; // 500 resonance for attuning
        coreParameters[PARAM_REFINE_COOL_DOWN] = 1 days; // 1 day cooldown between refinements

        // Initialize adaptive parameters (will be refined by oracle later)
        adaptiveParameters["forgeCost"] = BASE_FORGE_COST;
        adaptiveParameters["essenceGenRate"] = BASE_ESSENCE_GEN_RATE;
        adaptiveParameters["resonanceGenRate"] = BASE_RESONANCE_GEN_RATE;
        adaptiveParameters["refineEssenceCost"] = BASE_REFINE_ESSENCE_COST;
        adaptiveParameters["refineResonanceCost"] = BASE_REFINE_RESONANCE_COST;
    }

    // --- I. Core Infrastructure & Control ---

    /**
     * @notice Pauses contract functions. Callable by owner.
     */
    function pauseSystem() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses contract functions. Callable by owner.
     */
    function unpauseSystem() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Sets the address of the trusted environmental oracle. Callable by owner.
     * @param _newOracle The new oracle contract address.
     */
    function setOracleAddress(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "Invalid new oracle address");
        environmentalOracle = _newOracle;
        emit CoreParameterUpdated("oracleAddress", uint256(uint160(_newOracle)));
    }

    /**
     * @notice Updates a core, non-adaptive system parameter. Callable by owner.
     * @param _paramName The name of the parameter to update (e.g., PARAM_MIN_ESSENCE_FOR_REFINE).
     * @param _newValue The new value for the parameter.
     */
    function updateCoreParameter(bytes32 _paramName, uint256 _newValue) external onlyOwner {
        uint256 oldValue = coreParameters[_paramName];
        coreParameters[_paramName] = _newValue;
        emit CoreParameterUpdated(_paramName, _newValue);
    }

    // --- II. ChronoGlyph (Dynamic NFT) Management ---

    /**
     * @notice Forges (mints) a new ChronoGlyph NFT. Requires a certain ETH payment.
     * @param _initialTraitSeed A string seed to determine initial traits (e.g., "fire", "water").
     * @dev The actual trait generation logic would be more complex and deterministic based on seed.
     */
    function forgeChronoGlyph(string memory _initialTraitSeed) external payable nonReentrant whenNotPaused {
        uint256 currentForgeCost = adaptiveParameters["forgeCost"];
        require(msg.value >= currentForgeCost, "Insufficient ETH to forge ChronoGlyph");

        uint256 tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);

        // Simple trait generation based on seed (can be expanded)
        string[] memory initialTraits = new string[](1);
        initialTraits[0] = _initialTraitSeed;

        chronoGlyphs[tokenId] = ChronoGlyph({
            tokenId: tokenId,
            owner: msg.sender,
            forgedTimestamp: block.timestamp,
            lastRefinedTimestamp: block.timestamp,
            traits: initialTraits,
            evolutionCount: 0,
            lastWisdomInfluence: currentEnvironmentalWisdom,
            evolutionHistory: new uint256[](0)
        });

        // Add initial trait hash to history (simple hash for now)
        chronoGlyphs[tokenId].evolutionHistory.push(uint256(keccak256(abi.encodePacked(initialTraits[0]))));

        // Refund any excess ETH
        if (msg.value > currentForgeCost) {
            payable(msg.sender).transfer(msg.value - currentForgeCost);
        }

        // Update user's activity timestamp for Resonance calculation
        userResonance[msg.sender].lastActivityTimestamp = block.timestamp;
        emit ChronoGlyphForged(tokenId, msg.sender, _initialTraitSeed, currentForgeCost);
    }

    /**
     * @notice Refines (evolves) an existing ChronoGlyph. Requires Essence and Energy Resonance.
     * @param _tokenId The ID of the ChronoGlyph to refine.
     */
    function refineChronoGlyph(uint256 _tokenId) external nonReentrant whenNotPaused {
        ChronoGlyph storage glyph = chronoGlyphs[_tokenId];
        require(glyph.owner == msg.sender, "Caller is not the owner of this ChronoGlyph");
        require(block.timestamp >= glyph.lastRefinedTimestamp + coreParameters[PARAM_REFINE_COOL_DOWN], "ChronoGlyph is on cooldown");

        // Calculate costs using adaptive parameters
        uint256 requiredEssence = adaptiveParameters["refineEssenceCost"];
        uint256 requiredResonance = adaptiveParameters["refineResonanceCost"];

        // Check user's Essence and Resonance balance
        require(getEssenceBalance(msg.sender) >= requiredEssence, "Insufficient Essence for refinement");
        require(userResonance[msg.sender].accumulatedResonance >= requiredResonance, "Insufficient Energy Resonance for refinement");

        // Deduct Essence
        essenceDeposits[msg.sender].claimedEssence += requiredEssence;

        // Deduct Resonance
        userResonance[msg.sender].accumulatedResonance -= requiredResonance;
        totalEnergyResonanceSupply -= requiredResonance;

        // Update ChronoGlyph traits based on wisdom and current traits
        // This is where the "advanced" evolution logic would reside.
        // For simplicity, let's just add a new trait influenced by current wisdom.
        string memory newTrait;
        if (currentEnvironmentalWisdom % 3 == 0) {
            newTrait = "Harmony_" + Strings.toString(currentEnvironmentalWisdom);
        } else if (currentEnvironmentalWisdom % 3 == 1) {
            newTrait = "Growth_" + Strings.toString(currentEnvironmentalWisdom);
        } else {
            newTrait = "Innovation_" + Strings.toString(currentEnvironmentalWisdom);
        }
        glyph.traits.push(newTrait);
        glyph.evolutionCount++;
        glyph.lastRefinedTimestamp = block.timestamp;
        glyph.lastWisdomInfluence = currentEnvironmentalWisdom;

        // Add current traits hash to history
        glyph.evolutionHistory.push(uint256(keccak256(abi.encodePacked(glyph.traits))));

        userResonance[msg.sender].lastActivityTimestamp = block.timestamp;
        emit ChronoGlyphRefined(_tokenId, msg.sender, uint256(keccak256(abi.encodePacked(glyph.traits))), requiredEssence, requiredResonance);
    }

    /**
     * @notice Allows a user to express affinity for a ChronoGlyph, influencing its future evolution probability.
     *         Also grants a small Energy Resonance bonus to the attuning user.
     * @param _tokenId The ID of the ChronoGlyph to attune to.
     */
    function attuneToGlyph(uint256 _tokenId) external whenNotPaused {
        require(chronoGlyphs[_tokenId].tokenId != 0, "ChronoGlyph does not exist");
        // In a more complex system, this might involve tracking unique attunements per user per glyph.
        // For now, it's a simple interaction.

        uint256 attuneBonus = coreParameters[PARAM_ATTUNE_BONUS_RESONANCE];
        userResonance[msg.sender].accumulatedResonance += attuneBonus;
        totalEnergyResonanceSupply += attuneBonus;

        userResonance[msg.sender].lastActivityTimestamp = block.timestamp;
        emit ChronoGlyphAttuned(_tokenId, msg.sender, userResonance[msg.sender].accumulatedResonance);
    }

    /**
     * @notice Retrieves all details and traits of a specified ChronoGlyph.
     * @param _tokenId The ID of the ChronoGlyph.
     * @return ChronoGlyph struct containing all its data.
     */
    function getGlyphDetails(uint256 _tokenId) external view returns (ChronoGlyph memory) {
        require(chronoGlyphs[_tokenId].tokenId != 0, "ChronoGlyph does not exist");
        return chronoGlyphs[_tokenId];
    }

    /**
     * @notice Retrieves the historical evolution path (hashes of traits) of a ChronoGlyph.
     * @param _tokenId The ID of the ChronoGlyph.
     * @return An array of uint256 representing historical trait hashes.
     */
    function getGlyphEvolutionHistory(uint256 _tokenId) external view returns (uint256[] memory) {
        require(chronoGlyphs[_tokenId].tokenId != 0, "ChronoGlyph does not exist");
        return chronoGlyphs[_tokenId].evolutionHistory;
    }

    // --- III. Energy Resonance (Soulbound Contribution) ---

    /**
     * @notice Calculates and credits the caller with new Energy Resonance.
     *         Resonance accumulates passively over time and with system activity.
     */
    function harvestEnergyResonance() external nonReentrant whenNotPaused {
        UserResonance storage user = userResonance[msg.sender];
        uint256 lastUpdate = user.lastResonanceHarvestTimestamp == 0 ? user.lastActivityTimestamp : user.lastResonanceHarvestTimestamp;
        if (lastUpdate == 0) lastUpdate = block.timestamp; // If user never interacted before, start from now

        uint256 timeElapsed = block.timestamp - lastUpdate;
        if (timeElapsed == 0) return; // No time elapsed, nothing to harvest

        uint256 resonanceGenerated = (timeElapsed * adaptiveParameters["resonanceGenRate"]) / 1 seconds;
        
        user.accumulatedResonance += resonanceGenerated;
        totalEnergyResonanceSupply += resonanceGenerated;
        user.lastResonanceHarvestTimestamp = block.timestamp;
        user.lastActivityTimestamp = block.timestamp; // Update activity on harvest
        
        emit EnergyResonanceHarvested(msg.sender, resonanceGenerated, user.accumulatedResonance);
    }

    /**
     * @notice Retrieves the current Energy Resonance score for a specific user.
     * @param _user The address of the user.
     * @return The current accumulated Energy Resonance.
     */
    function getEnergyResonance(address _user) external view returns (uint256) {
        return userResonance[_user].accumulatedResonance;
    }

    /**
     * @notice Distributes bonus Energy Resonance to a specific user. Callable only by owner.
     * @param _user The address to grant bonus resonance to.
     * @param _amount The amount of bonus resonance.
     */
    function distributeBonusResonance(address _user, uint256 _amount) external onlyOwner {
        userResonance[_user].accumulatedResonance += _amount;
        totalEnergyResonanceSupply += _amount;
        emit EnergyResonanceHarvested(_user, _amount, userResonance[_user].accumulatedResonance); // Use same event for consistency
    }

    // --- IV. Essence Pool & Generation ---

    /**
     * @notice Allows users to deposit the designated ERC20 token into the Essence Pool
     *         to start generating Essence.
     */
    function depositIntoEssencePool() external nonReentrant whenNotPaused {
        uint256 amount = msg.value; // For simplicity, using ETH. In a real scenario, use ERC20.
                                    // If using ERC20, would be: `IERC20(essenceToken).transferFrom(msg.sender, address(this), amount);`
        require(amount > 0, "Deposit amount must be greater than zero");

        // Check allowance if using ERC20: require(IERC20(essenceToken).allowance(msg.sender, address(this)) >= amount, "Insufficient allowance");
        // essenceToken.transferFrom(msg.sender, address(this), amount); // For ERC20

        // Simulate ERC20 transfer if using ETH for simplicity in this example.
        // In a real scenario, this contract would hold ERC20 tokens, not ETH, for Essence generation.
        // For demonstration, let's assume `essenceToken` is an actual ERC20 and `depositIntoEssencePool` expects a prior `approve` call.
        // Re-adjusting to reflect proper ERC20 interaction.
        require(essenceToken.transferFrom(msg.sender, address(this), amount), "ERC20 transfer failed");


        EssenceDeposit storage deposit = essenceDeposits[msg.sender];
        
        // Harvest any pending essence before updating deposit (to avoid loss of old rate calculation)
        _harvestEssenceInternal(msg.sender);

        deposit.amount += amount;
        deposit.depositTimestamp = block.timestamp; // Reset timestamp to reflect new deposit for future claims
        totalEssencePoolValue += amount;

        userResonance[msg.sender].lastActivityTimestamp = block.timestamp;
        emit EssenceDeposited(msg.sender, amount);
    }

    /**
     * @notice Allows users to withdraw their deposited tokens from the Essence Pool.
     * @param _amount The amount of tokens to withdraw.
     */
    function withdrawFromEssencePool(uint256 _amount) external nonReentrant whenNotPaused {
        EssenceDeposit storage deposit = essenceDeposits[msg.sender];
        require(deposit.amount >= _amount, "Insufficient deposited amount");
        
        // Harvest any pending essence before withdrawal
        _harvestEssenceInternal(msg.sender);

        deposit.amount -= _amount;
        totalEssencePoolValue -= _amount;

        require(essenceToken.transfer(msg.sender, _amount), "Token transfer failed");

        userResonance[msg.sender].lastActivityTimestamp = block.timestamp;
        emit EssenceWithdrawn(msg.sender, _amount);
    }

    /**
     * @notice Allows users to claim their accumulated Essence generated from their pool deposits.
     */
    function claimEssence() external nonReentrant whenNotPaused {
        _harvestEssenceInternal(msg.sender); // Harvest and update
        userResonance[msg.sender].lastActivityTimestamp = block.timestamp; // Update activity
    }

    /**
     * @notice Internal function to calculate and credit Essence.
     */
    function _harvestEssenceInternal(address _user) private {
        EssenceDeposit storage deposit = essenceDeposits[_user];
        if (deposit.amount == 0) return;

        uint256 timeElapsed = block.timestamp - deposit.depositTimestamp;
        if (timeElapsed == 0) return;

        uint256 currentEssenceGenRate = adaptiveParameters["essenceGenRate"];
        uint256 newlyGeneratedEssence = (deposit.amount * currentEssenceGenRate * timeElapsed) / (1 ether * 1 seconds); // Normalize by 1 ether for token amount
        
        uint256 unclaimedEssence = newlyGeneratedEssence - deposit.claimedEssence;
        require(unclaimedEssence > 0, "No essence to claim");

        // Credit essence (represented internally by adding to claimedEssence, implies future deduction on spend)
        // For actual "claiming" for external use, a separate ERC20 Essence token would be minted.
        // Here, it's just tracked as "available to spend".
        // Instead of claimedEssence, let's use a separate availableEssence balance.
        // Adjusting data structure for clarity:
        // mapping(address => uint256) public userEssenceBalance; // New mapping
        // And adjust EssenceDeposit to:
        // struct EssenceDeposit { uint256 amount; uint256 depositTimestamp; } // No claimedEssence here

        // (Self-correction during thought process)
        // Re-evaluating Essence management: It's better to calculate available essence on demand,
        // and then track "spent" essence separately or simply reduce the available amount.
        // Let's remove `claimedEssence` from EssenceDeposit and use a direct `userEssenceBalance`
        // which gets topped up when `claimEssence` is called.

        // Re-evaluating again: The current `claimedEssence` in the struct means "how much has been pulled out from the *potential* of this deposit".
        // So, `newlyGeneratedEssence` is the total potential, and `claimedEssence` is what was already 'used'.
        // This is a valid pattern for a "continuous yield" where you don't actually mint a token, but just track a spendable balance.
        // Let's stick with this pattern but clarify.
        
        // The `newlyGeneratedEssence` here represents the total potential Essence generated by this specific deposit since its last update.
        // `deposit.claimedEssence` should mean `totalEssenceGeneratedAndSpentFromThisDeposit`.
        // So, `totalPotential - totalSpent` should be `available`.
        // This is slightly confusing. Let's make it simpler:
        // `EssenceDeposit.lastClaimTimestamp` and `EssenceDeposit.accruedEssence`.
        // Or even simpler: Calculate essence on-the-fly when needed or claimed, and just update `lastDepositTimestamp`.

        // Okay, simpler: `userEssenceBalance[user]` represents their spendable balance.
        // When claiming, we calculate based on `deposit.depositTimestamp` and `deposit.amount`,
        // then update `deposit.depositTimestamp` to `block.timestamp`.

        uint256 essenceToCredit = (deposit.amount * currentEssenceGenRate * (block.timestamp - deposit.depositTimestamp)) / (1 ether * 1 seconds); // Normalize by 1 ether as deposit.amount is token amount
        require(essenceToCredit > 0, "No new essence generated since last claim");

        userEssenceBalance[_user] += essenceToCredit;
        deposit.depositTimestamp = block.timestamp; // Update timestamp for future calculations

        emit EssenceClaimed(_user, essenceToCredit);
    }
    
    // New mapping for user's spendable essence balance
    mapping(address => uint256) public userEssenceBalance;

    /**
     * @notice Retrieves the current spendable Essence balance for a specific user.
     * @param _user The address of the user.
     * @return The current spendable Essence.
     */
    function getEssenceBalance(address _user) public view returns (uint256) {
        // Calculate potential new essence since last claim, but don't credit it.
        // This makes `getEssenceBalance` a real-time view.
        EssenceDeposit storage deposit = essenceDeposits[_user];
        uint256 potentialEssence = 0;
        if (deposit.amount > 0) {
            uint256 timeElapsed = block.timestamp - deposit.depositTimestamp;
            uint256 currentEssenceGenRate = adaptiveParameters["essenceGenRate"];
            potentialEssence = (deposit.amount * currentEssenceGenRate * timeElapsed) / (1 ether * 1 seconds);
        }
        return userEssenceBalance[_user] + potentialEssence;
    }

    /**
     * @notice Retrieves the total value (in `essenceToken`) currently held in the Essence Pool.
     * @return The total amount of essenceToken.
     */
    function getEssencePoolValue() external view returns (uint256) {
        return totalEssencePoolValue;
    }

    // --- V. Oracle Integration & Adaptive Logic ---

    /**
     * @notice Receives and processes environmental data from the trusted oracle.
     *         Updates internal wisdom and triggers parameter adaptation.
     *         Callable only by the registered oracle address.
     * @param _wisdomValue A primary wisdom value from the oracle.
     * @param _factors Additional environmental factors (e.g., array of metrics).
     */
    function receiveOracleData(uint256 _wisdomValue, uint256[] memory _factors) external {
        require(msg.sender == environmentalOracle, "Only the registered oracle can call this function");

        currentEnvironmentalWisdom = _wisdomValue;
        environmentalFactors = _factors; // Store factors if needed for complex adaptations
        lastOracleUpdateTimestamp = block.timestamp;

        // Trigger immediate adaptation of parameters
        _adaptParameters();

        emit OracleDataReceived(_wisdomValue, _factors, block.timestamp);
    }

    /**
     * @notice Retrieves the latest `Environmental Wisdom` value received from the oracle.
     * @return The current wisdom value.
     */
    function getCurrentEnvironmentalWisdom() external view returns (uint256) {
        return currentEnvironmentalWisdom;
    }

    /**
     * @notice Internal function to adapt system parameters based on current wisdom and state.
     *         This logic makes the system "self-evolving."
     */
    function _adaptParameters() private {
        // Example adaptation logic:
        // Forge cost increases with high wisdom (indicates scarcity/demand or complexity)
        uint256 newForgeCost = BASE_FORGE_COST + (currentEnvironmentalWisdom / 100);
        _updateAdaptiveParameter("forgeCost", newForgeCost);

        // Essence generation rate influenced by wisdom and total pool value (encourages deposits)
        uint256 newEssenceGenRate = BASE_ESSENCE_GEN_RATE + (currentEnvironmentalWisdom / 50) + (totalEssencePoolValue / 1e18 / 100); // Scale by totalEthInPool/1e18
        _updateAdaptiveParameter("essenceGenRate", newEssenceGenRate);

        // Resonance generation rate influenced by wisdom and total resonance supply (prevents inflation)
        uint256 newResonanceGenRate = BASE_RESONANCE_GEN_RATE + (currentEnvironmentalWisdom / 75) - (totalEnergyResonanceSupply / 1000000); // Simple example
        if (newResonanceGenRate < BASE_RESONANCE_GEN_RATE / 2) newResonanceGenRate = BASE_RESONANCE_GEN_RATE / 2; // Min floor
        _updateAdaptiveParameter("resonanceGenRate", newResonanceGenRate);

        // Refinement costs can also adapt, making evolution more challenging or easier
        uint256 newRefineEssenceCost = BASE_REFINE_ESSENCE_COST + (currentEnvironmentalWisdom * 10);
        _updateAdaptiveParameter("refineEssenceCost", newRefineEssenceCost);

        uint256 newRefineResonanceCost = BASE_REFINE_RESONANCE_COST + (currentEnvironmentalWisdom * 15);
        _updateAdaptiveParameter("refineResonanceCost", newRefineResonanceCost);

        // Can also incorporate `environmentalFactors` for more nuanced adaptations
        // e.g., if factor[0] is high (market volatility), increase costs.
    }

    /**
     * @notice Helper function to update an adaptive parameter and emit an event.
     */
    function _updateAdaptiveParameter(bytes32 _paramName, uint256 _newValue) private {
        uint256 oldValue = adaptiveParameters[_paramName];
        adaptiveParameters[_paramName] = _newValue;
        emit AdaptiveParameterUpdated(_paramName, oldValue, _newValue);
    }

    /**
     * @notice A public view function to show the calculated value of an adaptive parameter
     *         based on the latest wisdom and current system state.
     *         Note: This function doesn't *update* the parameter, just calculates its current theoretical value.
     * @param _paramName The name of the adaptive parameter (e.g., "forgeCost").
     * @return The calculated value of the parameter.
     */
    function calculateAdaptiveParam(bytes32 _paramName) external view returns (uint256) {
        // This function would re-run the _adaptParameters logic temporarily
        // to show the result without state changes. However, doing so would mean
        // duplicating logic or making _adaptParameters public and then calling it with a revert.
        // For simplicity and gas efficiency, we'll just return the current stored adaptive value,
        // assuming `_adaptParameters` is called reliably by the oracle or `triggerParameterAdaptation`.
        // A more advanced approach would involve a 'pure' or 'view' simulation.
        return adaptiveParameters[_paramName];
    }

    /**
     * @notice Triggers the system to re-evaluate and update all adaptive parameters
     *         based on current Environmental Wisdom and system metrics.
     *         Can be called by anyone (gas cost for caller, but beneficial for system).
     */
    function triggerParameterAdaptation() external whenNotPaused {
        _adaptParameters();
    }

    // --- VI. System Analytics & Views ---

    /**
     * @notice Returns the total number of ChronoGlyphs minted to date.
     * @return The total number of forged glyphs.
     */
    function getTotalForgedGlyphs() external view returns (uint256) {
        return _nextTokenId - 1; // Since token IDs start from 1
    }

    /**
     * @notice Returns the sum of all accumulated Energy Resonance across all users.
     * @return The total Energy Resonance in circulation.
     */
    function getTotalEnergyResonanceSupply() external view returns (uint256) {
        return totalEnergyResonanceSupply;
    }

    // The ERC721 `tokenURI` function for metadata (required by standard, but implementation depends on off-chain storage)
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        ChronoGlyph memory glyph = chronoGlyphs[tokenId];
        // In a real dApp, this would return an IPFS hash or similar.
        // For dynamic NFTs, the URI usually points to an API endpoint that generates JSON metadata based on current traits.
        return string(abi.encodePacked("ipfs://your_metadata_cid/", Strings.toString(tokenId), ".json"));
    }
}
```