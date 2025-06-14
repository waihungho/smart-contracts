Okay, let's design an interesting, advanced, and relatively unique smart contract concept. We'll build a "Dynamic Yielding Asset Forge".

**Concept:** Users can stake a base token to "forge" unique, non-fungible assets (NFTs). These NFTs have properties that dynamically change based on time and potentially external data (via an oracle). The NFTs themselves can then be staked *within the same protocol* to earn yield in the base token. There are mechanics to influence, decompose, or refine these dynamic NFTs.

This combines:
1.  **Staking** (fungible tokens).
2.  **NFT Minting** based on staking/cost.
3.  **Dynamic NFTs** (state changes over time/data).
4.  **NFT Staking** for yield (fungible tokens).
5.  **Oracle Interaction** (potential influence on NFT state).
6.  **Complex State Transitions** (refining, decomposing).
7.  **Protocol Fees/Treasury**.

We'll call the contract `TemporalEssenceForge`. The base token staked and yielded will be `ForgeFuel`. The minted NFT will be `TemporalEssence`.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Outline ---
// 1. Imports: Using OpenZeppelin for standard patterns (Ownable, ReentrancyGuard, Pausable, ERC20, ERC721 interfaces).
// 2. Interfaces: Define custom interface for the Oracle contract.
// 3. State Variables: Addresses for tokens and oracle, parameters for forging/staking/refining, mappings for user stakes, essence states, staking info.
// 4. Events: Announce key actions (Forged, Staked, Harvested, Refined, Decomposed, Parameter Updates, etc.).
// 5. Modifiers: Custom modifiers if needed (besides Ownable, Pausable, ReentrancyGuard).
// 6. Structs: Define structures for Essence state and Staking information for clarity.
// 7. Constructor: Initialize basic parameters and ownership.
// 8. Configuration Functions: Functions callable by owner to set addresses and parameters.
// 9. Core Interaction Functions: User-facing functions for staking fuel, forging essences, staking essences, harvesting yield, decomposing, refining.
// 10. View Functions: Read-only functions to get information (balances, costs, pending yield, essence states).
// 11. Admin/Rescue Functions: Functions for the owner to handle emergencies or protocol fees.
// 12. Internal Functions: Helper functions for calculations and state management.

// --- Function Summary ---
// Configuration (Owner Only):
// 1. setForgeFuelToken(address tokenAddress): Sets the address of the ForgeFuel ERC20 token.
// 2. setTemporalEssenceNFT(address nftAddress): Sets the address of the TemporalEssence ERC721 token.
// 3. setCosmicOracle(address oracleAddress): Sets the address of the Oracle contract.
// 4. updateForgingParameters(uint256 cost, uint256 duration): Updates cost and forging duration.
// 5. updateYieldParameters(uint256 baseRate, uint256 maxBoost): Updates yield rate parameters.
// 6. updateRefinementParameters(uint256 cost, uint256 potencyBoost): Updates refinement cost and effect.
// 7. setProtocolFeeRate(uint256 feeRatePermil): Sets the protocol fee rate (in permil, e.g., 10 for 1%).
// 8. updateAllowedOracleDataKeys(bytes32[] keys): Sets which oracle data keys are relevant for forging.
// 9. pause(): Pauses forging and staking.
// 10. unpause(): Unpauses forging and staking.

// User Interactions (Public):
// 11. stakeFuel(uint256 amount): Stakes ForgeFuel tokens.
// 12. unstakeFuel(uint256 amount): Unstakes ForgeFuel tokens.
// 13. forgeEssence(string memory metadataURI): Forges a new TemporalEssence NFT.
// 14. stakeEssence(uint256 essenceId): Stakes a TemporalEssence NFT.
// 15. unstakeEssence(uint256 essenceId): Unstakes a staked TemporalEssence NFT.
// 16. harvestEssenceYield(uint256[] calldata essenceIds): Claims accumulated yield from one or more staked NFTs.
// 17. decomposeEssence(uint256 essenceId): Burns an NFT to recover some ForgeFuel.
// 18. refineEssence(uint256 essenceId): Spends ForgeFuel to modify an Essence's properties.

// View Functions (Public - Pure/View):
// 19. getUserStakedFuel(address user): Gets the amount of ForgeFuel staked by a user.
// 20. getEssenceState(uint256 essenceId): Calculates and returns the current dynamic state of an Essence.
// 21. getPendingEssenceYield(uint256 essenceId): Calculates and returns pending yield for a staked Essence.
// 22. getForgingCost(): Gets the current ForgeFuel cost to forge an Essence.
// 23. getYieldRate(uint256 essenceId): Gets the current calculated yield rate for a specific Essence (dynamic).
// 24. getEssenceInfo(uint256 essenceId): Gets static creation info for an Essence (creation time, initial data).
// 25. isEssenceStaked(uint256 essenceId): Checks if an Essence is currently staked.
// 26. getAllowedOracleDataKeys(): Gets the list of oracle data keys the contract uses.

// Admin/Rescue (Owner Only):
// 27. withdrawProtocolFees(address token, uint256 amount): Withdraws collected protocol fees for a specific token.
// 28. rescueERC20(address token, address to, uint256 amount): Rescues inadvertently sent ERC20 tokens.
// 29. rescueERC721(address nft, address to, uint256 tokenId): Rescues inadvertently sent ERC721 tokens.

// Total Functions: 29 (Meeting the >= 20 requirement with room).

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract TemporalEssenceForge is Ownable, ReentrancyGuard, Pausable {
    using Math for uint256; // For safe math operations, though Solidity 0.8+ handles overflow

    // --- Interfaces ---

    // Assuming a simple Oracle interface
    interface ICosmicOracle {
        // Function to get latest data for a specific key
        // Returns (value, timestamp, dataHash) - check timestamp and hash for validity
        function getData(bytes32 key) external view returns (int256 value, uint256 timestamp, bytes32 dataHash);
    }

    // --- State Variables ---

    IERC20 public forgeFuelToken;
    IERC721 public temporalEssenceNFT;
    ICosmicOracle public cosmicOracle;

    // Configuration Parameters (Owner Settable)
    uint256 public forgingCost = 1 ether; // Cost in ForgeFuel
    uint256 public forgingDuration = 1 hours; // Time required after staking fuel before forging is possible
    uint256 public baseYieldRatePerSecond = 100; // Yield rate in wei per second per unit potency
    uint256 public essenceMaxYieldBoostFactor = 2; // Max multiplier for yield based on state (e.g., 2x)
    uint256 public refinementCost = 0.5 ether; // Cost in ForgeFuel to refine
    uint256 public refinementPotencyBoost = 50; // Amount to add to base potency upon refinement
    uint256 public essenceMaxPotency = 1000; // Max base potency achievable
    uint256 public essenceVolatilityInfluence = 10; // How much oracle volatility affects state (e.g., 10%)
    uint256 public decompositionRecoveryFactor = 5000; // Recovery factor in permil (e.g., 5000 = 50%) of forging cost
    uint256 public protocolFeeRatePermil = 50; // 5% protocol fee on forging cost

    // Mappings for state
    mapping(address => uint256) public userStakedFuel;
    mapping(address => uint256) public userFuelStakeTime; // Timestamp when fuel was staked (last time)

    // Essence-specific state and staking info
    struct EssenceInfo {
        uint256 creationTime;
        uint256 basePotency; // Initial or base potency influencing yield
        int256 initialCosmicFactor; // Oracle data point at creation time
        bytes32 initialOracleDataHash; // Hash of oracle data at creation
    }
    mapping(uint256 => EssenceInfo) public essenceCreationInfo; // tokenId => EssenceInfo

    struct StakingInfo {
        address staker;
        uint256 stakeTime;
        uint256 accumulatedYieldPerShare; // Internal accounting for yield calculation
    }
    mapping(uint256 => StakingInfo) public essenceStakingInfo; // tokenId => StakingInfo

    mapping(uint256 => uint256) public essenceLastHarvestTime; // tokenId => timestamp
    mapping(uint256 => uint256) public essenceStakedAmount; // Using tokenId as key, amount is always 1 for ERC721

    // Protocol Fee Treasury
    mapping(address => uint256) public protocolFeeTreasury; // tokenAddress => amount

    // Oracle Data Keys we care about
    bytes32[] public allowedOracleDataKeys;
    bytes32 public essenceCosmicFactorKey = keccak256("COSMIC_FACTOR"); // Key for the cosmic factor data

    // --- Events ---

    event ForgeFuelStaked(address indexed user, uint256 amount);
    event ForgeFuelUnstaked(address indexed user, uint256 amount);
    event EssenceForged(address indexed user, uint256 indexed tokenId, uint256 costPaid, int256 initialCosmicFactor);
    event EssenceStaked(address indexed user, uint256 indexed tokenId, uint256 stakeTime);
    event EssenceUnstaked(address indexed user, uint256 indexed tokenId, uint256 unstakeTime);
    event EssenceYieldHarvested(address indexed user, uint256 indexed tokenId, uint256 amount);
    event EssenceRefined(address indexed user, uint256 indexed tokenId, uint256 costPaid, uint256 newBasePotency);
    event EssenceDecomposed(address indexed user, uint256 indexed tokenId, uint256 fuelReturned);
    event ParameterUpdated(bytes32 name, uint256 oldValue, uint256 newValue);
    event AddressParameterUpdated(bytes32 name, address oldValue, address newValue);
    event ProtocolFeesWithdrawn(address indexed token, address indexed to, uint256 amount);
    event AllowedOracleKeysUpdated(bytes32[] keys);

    // --- Constructor ---

    constructor() Ownable(msg.sender) {}

    // --- Configuration Functions (Owner Only) ---

    /// @notice Sets the address of the ForgeFuel ERC20 token.
    /// @param tokenAddress The address of the ForgeFuel contract.
    function setForgeFuelToken(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0), "Invalid address");
        emit AddressParameterUpdated("forgeFuelToken", address(forgeFuelToken), tokenAddress);
        forgeFuelToken = IERC20(tokenAddress);
    }

    /// @notice Sets the address of the TemporalEssence ERC721 token.
    /// @param nftAddress The address of the TemporalEssence contract.
    function setTemporalEssenceNFT(address nftAddress) external onlyOwner {
        require(nftAddress != address(0), "Invalid address");
        emit AddressParameterUpdated("temporalEssenceNFT", address(temporalEssenceNFT), nftAddress);
        temporalEssenceNFT = IERC721(nftAddress);
    }

    /// @notice Sets the address of the Cosmic Oracle contract.
    /// @param oracleAddress The address of the Oracle contract.
    function setCosmicOracle(address oracleAddress) external onlyOwner {
        require(oracleAddress != address(0), "Invalid address");
        emit AddressParameterUpdated("cosmicOracle", address(cosmicOracle), oracleAddress);
        cosmicOracle = ICosmicOracle(oracleAddress);
    }

    /// @notice Updates parameters related to forging Essences.
    /// @param cost The new cost in ForgeFuel.
    /// @param duration The new required staking duration before forging.
    function updateForgingParameters(uint256 cost, uint256 duration) external onlyOwner {
        emit ParameterUpdated("forgingCost", forgingCost, cost);
        emit ParameterUpdated("forgingDuration", forgingDuration, duration);
        forgingCost = cost;
        forgingDuration = duration;
    }

    /// @notice Updates parameters related to Essence yield rates.
    /// @param baseRate The new base yield rate per second per unit potency.
    /// @param maxBoost The new maximum yield boost factor based on dynamic state.
    function updateYieldParameters(uint256 baseRate, uint256 maxBoost) external onlyOwner {
        emit ParameterUpdated("baseYieldRatePerSecond", baseYieldRatePerSecond, baseRate);
        emit ParameterUpdated("essenceMaxYieldBoostFactor", essenceMaxYieldBoostFactor, maxBoost);
        baseYieldRatePerSecond = baseRate;
        essenceMaxYieldBoostFactor = maxBoost;
    }

    /// @notice Updates parameters related to refining Essences.
    /// @param cost The new cost in ForgeFuel.
    /// @param potencyBoost The new potency boost amount from refinement.
    function updateRefinementParameters(uint256 cost, uint256 potencyBoost) external onlyOwner {
        emit ParameterUpdated("refinementCost", refinementCost, cost);
        emit ParameterUpdated("refinementPotencyBoost", refinementPotencyBoost, potencyBoost);
        refinementCost = cost;
        refinementPotencyBoost = potencyBoost;
    }

    /// @notice Sets the protocol fee rate on forging cost.
    /// @param feeRatePermil The fee rate in permil (e.g., 100 = 10%). Max 1000 (100%).
    function setProtocolFeeRate(uint256 feeRatePermil) external onlyOwner {
        require(feeRatePermil <= 1000, "Fee rate cannot exceed 100%");
        emit ParameterUpdated("protocolFeeRatePermil", protocolFeeRatePermil, feeRatePermil);
        protocolFeeRatePermil = feeRatePermil;
    }

    /// @notice Updates the list of oracle data keys the contract uses for forging/state.
    /// @param keys An array of desired oracle data keys.
    function updateAllowedOracleDataKeys(bytes32[] calldata keys) external onlyOwner {
        allowedOracleDataKeys = keys;
        emit AllowedOracleKeysUpdated(keys);
    }

    /// @notice Pauses forging and staking actions.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses forging and staking actions.
    function unpause() external onlyOwner {
        _unpause();
    }

    // --- Core Interaction Functions (Public) ---

    /// @notice Stakes ForgeFuel tokens into the forge.
    /// @param amount The amount of ForgeFuel to stake.
    function stakeFuel(uint256 amount) external nonReentrant whenNotPaused {
        require(address(forgeFuelToken) != address(0), "ForgeFuel token not set");
        require(amount > 0, "Amount must be greater than 0");

        userStakedFuel[msg.sender] = userStakedFuel[msg.sender].add(amount);
        userFuelStakeTime[msg.sender] = block.timestamp; // Update stake time

        bool success = forgeFuelToken.transferFrom(msg.sender, address(this), amount);
        require(success, "ForgeFuel transfer failed");

        emit ForgeFuelStaked(msg.sender, amount);
    }

    /// @notice Unstakes ForgeFuel tokens from the forge.
    /// @param amount The amount of ForgeFuel to unstake.
    function unstakeFuel(uint256 amount) external nonReentrant whenNotPaused {
        require(address(forgeFuelToken) != address(0), "ForgeFuel token not set");
        require(amount > 0, "Amount must be greater than 0");
        require(userStakedFuel[msg.sender] >= amount, "Insufficient staked fuel");

        userStakedFuel[msg.sender] = userStakedFuel[msg.sender].sub(amount);
        // Note: userFuelStakeTime is NOT reset here. It remains the time of the *last* stake action,
        // which is needed for the forging duration check.

        bool success = forgeFuelToken.transfer(msg.sender, amount);
        require(success, "ForgeFuel transfer failed");

        emit ForgeFuelUnstaked(msg.sender, amount);
    }

    /// @notice Forges a new TemporalEssence NFT by consuming staked ForgeFuel.
    /// Requires sufficient staked fuel and minimum staking duration met.
    /// Influenced by current oracle data.
    /// @param metadataURI The URI for the NFT's metadata.
    function forgeEssence(string memory metadataURI) external nonReentrant whenNotPaused {
        require(address(forgeFuelToken) != address(0), "ForgeFuel token not set");
        require(address(temporalEssenceNFT) != address(0), "TemporalEssence NFT not set");
        require(address(cosmicOracle) != address(0), "Cosmic Oracle not set");
        require(userStakedFuel[msg.sender] >= forgingCost, "Insufficient staked fuel for forging");
        require(userFuelStakeTime[msg.sender] + forgingDuration <= block.timestamp, "Fuel must be staked for minimum duration");

        // Get oracle data - requires at least one key configured
        require(allowedOracleDataKeys.length > 0, "No allowed oracle data keys configured");
        int256 initialCosmicFactor = 0;
        bytes32 oracleDataHash = bytes32(0);
        uint256 oracleTimestamp = 0;

        // Fetch data for the main cosmic factor key if configured
        bool foundCosmicFactorKey = false;
        for(uint i = 0; i < allowedOracleDataKeys.length; i++) {
            if (allowedOracleDataKeys[i] == essenceCosmicFactorKey) {
                 (initialCosmicFactor, oracleTimestamp, oracleDataHash) = cosmicOracle.getData(essenceCosmicFactorKey);
                 // Basic check: ensure data isn't too old (e.g., within the last hour or day, depending on desired dynamism)
                 // For simplicity here, we just check timestamp > 0. A real system would need more robust freshness checks.
                 require(oracleTimestamp > 0, "Oracle data is not fresh or available");
                 foundCosmicFactorKey = true;
                 break; // Found the key we care about for the core logic
            }
        }
        require(foundCosmicFactorKey, "Cosmic factor oracle key not configured");

        // Calculate fee and amount to burn/transfer
        uint256 feeAmount = forgingCost.mul(protocolFeeRatePermil).div(1000);
        uint256 burnAmount = forgingCost.sub(feeAmount);

        // Consume staked fuel (reduce user balance first)
        userStakedFuel[msg.sender] = userStakedFuel[msg.sender].sub(forgingCost);
        // User's stake time is NOT reset here.

        // Transfer fee to treasury
        if (feeAmount > 0) {
             bool successFee = forgeFuelToken.transfer(address(this), feeAmount);
             require(successFee, "Fee transfer failed");
             protocolFeeTreasury[address(forgeFuelToken)] = protocolFeeTreasury[address(forgeFuelToken)].add(feeAmount);
        }

        // Burn or Sink remaining cost (example: transfer to address(0))
        if (burnAmount > 0) {
             bool successBurn = forgeFuelToken.transfer(address(0), burnAmount);
             require(successBurn, "Burn transfer failed");
        }

        // Mint the NFT
        uint256 newTokenId = 0; // ERC721 standard doesn't have _mint returning token id, need custom implementation or tracking
        // Assuming TemporalEssenceNFT has a mint function like _mint(address to, uint256 tokenId) or mint(address to)
        // For this example, we'll assume a function 'mint(address to, string memory uri)' that handles ID assignment internally
        // and we'll need a way to get the new token ID. A common pattern is to track next ID or listen for Transfer events.
        // For demonstration, let's *simulate* getting the next ID, but note this isn't safe without a custom NFT contract.
        // A better way is for the NFT contract to have a mint function that *returns* the tokenId or for this contract
        // to call a mint function with a predetermined ID if the NFT contract supports it.
        // Let's assume the NFT contract has a public counter `nextTokenId` and a `mint(address to, string memory uri)` function.
        // Or even better, let's make the NFT contract `TemporalEssence` and call it directly.
        // **Correction:** We need to *define* the ERC721 contract `TemporalEssence` as part of this system or assume its interface includes
        // a way to mint with a specific ID or return the ID. Let's assume a simple `mint(address to, uint256 tokenId, string memory uri)`
        // function on `TemporalEssence`. We'll need an internal ID counter.

        uint256 newTokenId = temporalEssenceNFT.nextTokenId(); // Assuming NFT contract exposes this
        temporalEssenceNFT.mint(msg.sender, newTokenId, metadataURI); // Assuming NFT contract has this mint function

        // Store creation info
        essenceCreationInfo[newTokenId] = EssenceInfo({
            creationTime: block.timestamp,
            basePotency: 100, // Starting base potency
            initialCosmicFactor: initialCosmicFactor,
            initialOracleDataHash: oracleDataHash // Store hash for potential later validation/auditing
        });

        emit EssenceForged(msg.sender, newTokenId, forgingCost, initialCosmicFactor);
    }

    /// @notice Stakes a TemporalEssence NFT to earn yield.
    /// Requires the user to own the NFT and approve this contract.
    /// @param essenceId The ID of the TemporalEssence NFT to stake.
    function stakeEssence(uint256 essenceId) external nonReentrant whenNotPaused {
        require(address(temporalEssenceNFT) != address(0), "TemporalEssence NFT not set");
        require(temporalEssenceNFT.ownerOf(essenceId) == msg.sender, "Caller must own the NFT");
        require(essenceStakedAmount[essenceId] == 0, "Essence is already staked");

        // Transfer NFT to the contract
        temporalEssenceNFT.transferFrom(msg.sender, address(this), essenceId);

        // Record staking info
        essenceStakingInfo[essenceId] = StakingInfo({
            staker: msg.sender,
            stakeTime: block.timestamp,
            accumulatedYieldPerShare: 0 // Reset internal yield tracking for this NFT
        });
        essenceStakedAmount[essenceId] = 1; // Mark as staked
        essenceLastHarvestTime[essenceId] = block.timestamp; // Initialize last harvest time

        emit EssenceStaked(msg.sender, essenceId, block.timestamp);
    }

    /// @notice Unstakes a TemporalEssence NFT.
    /// Claims any pending yield upon unstaking.
    /// @param essenceId The ID of the TemporalEssence NFT to unstake.
    function unstakeEssence(uint256 essenceId) external nonReentrant whenNotPaused {
        require(address(temporalEssenceNFT) != address(0), "TemporalEssence NFT not set");
        require(essenceStakedAmount[essenceId] == 1, "Essence is not staked");
        require(essenceStakingInfo[essenceId].staker == msg.sender, "Caller is not the staker");

        // Harvest pending yield before unstaking
        _harvestEssenceYield(essenceId);

        // Transfer NFT back to the staker
        temporalEssenceNFT.transferFrom(address(this), msg.sender, essenceId);

        // Clear staking info
        delete essenceStakingInfo[essenceId];
        delete essenceStakedAmount[essenceId];
        delete essenceLastHarvestTime[essenceId];

        emit EssenceUnstaked(msg.sender, essenceId, block.timestamp);
    }

    /// @notice Claims accumulated yield from one or more staked Essences.
    /// @param essenceIds An array of Essence IDs to harvest from.
    function harvestEssenceYield(uint256[] calldata essenceIds) external nonReentrant whenNotPaused {
         require(address(forgeFuelToken) != address(0), "ForgeFuel token not set");
         uint256 totalYield = 0;

         for(uint i = 0; i < essenceIds.length; i++) {
             uint256 essenceId = essenceIds[i];
             require(essenceStakedAmount[essenceId] == 1, "Essence is not staked");
             require(essenceStakingInfo[essenceId].staker == msg.sender, "Caller is not the staker");

             totalYield = totalYield.add(_harvestEssenceYield(essenceId));
         }

         if (totalYield > 0) {
             bool success = forgeFuelToken.transfer(msg.sender, totalYield);
             require(success, "Yield transfer failed");
         }
    }

    /// @dev Internal function to calculate and record yield for a single essence.
    /// Does NOT transfer tokens. Returns calculated yield amount.
    function _harvestEssenceYield(uint256 essenceId) internal returns (uint256) {
        uint256 lastHarvestTime = essenceLastHarvestTime[essenceId];
        uint256 timeElapsed = block.timestamp - lastHarvestTime;

        if (timeElapsed == 0) {
            return 0; // No time has passed since last harvest/stake
        }

        // Get current dynamic state (potency, volatility)
        (uint256 currentPotency, int256 currentCosmicFactor) = getEssenceState(essenceId); // This calls the view function

        // Calculate dynamic yield rate
        // Example: yield rate = baseRate * (potency / maxPotency) * (1 + volatilityEffect)
        // VolatilityEffect could be based on |currentCosmicFactor - initialCosmicFactor| / max(abs(factors))
        // Let's simplify: yield rate is baseRate * (currentPotency / 100) * yieldBoost based on volatility
        // Yield boost based on volatility: 1 + (Min(abs(currentFactor), abs(initialFactor)) / Max(abs(currentFactor), abs(initialFactor))) * (MaxBoost - 1)
        // Or even simpler: yield rate = baseRate * (currentPotency / 100) * (1 + volatilityBoostFactor)
        // VolatilityBoostFactor could be proportional to the magnitude of change in cosmic factor since creation.
        // Example: Boost = (essenceMaxYieldBoostFactor - 1) * (abs(currentCosmicFactor - initialCosmicFactor) / MaxPossibleFactorChange)
        // Let's use a simpler model for this example: Yield rate is baseRate * (normalized potency) * (volatility-based multiplier).
        // normalized potency = currentPotency / essenceMaxPotency. Let's scale potency by 100 for simplicity (1-10 range based on 100-1000 potency).
        // Effective Potency Factor: currentPotency / 100 (Assuming baseRate is per unit of 100 potency)
        uint256 effectivePotencyFactor = currentPotency.mul(1e18).div(100).div(1e18); // Scale potency from 100-1000 to 1-10
        if (effectivePotencyFactor == 0) effectivePotencyFactor = 1; // Avoid division by zero or 0 yield if potency is low

        // Volatility Boost Factor: Simple example - boost is proportional to the absolute difference in cosmic factor.
        // Need a maximum possible difference for normalization. Let's assume Cosmic Factor is +/- 1000. Max diff = 2000.
        // Boost = (essenceMaxYieldBoostFactor - 1) * (abs(currentCosmicFactor - initialCosmicFactor) / 2000)
        // We need to handle potential large swings, maybe cap the boost contribution.
        // Let's use a simpler volatility boost: (1 + (abs(currentCosmicFactor - essenceCreationInfo[essenceId].initialCosmicFactor) / 1000)).min(essenceMaxYieldBoostFactor)
        // This assumes cosmic factor swings up to 1000 difference give full boost.
        uint256 volatilityBoost = 1e18; // Start with 1x boost (scaled by 1e18)
        int256 cosmicFactorDiff = currentCosmicFactor - essenceCreationInfo[essenceId].initialCosmicFactor;
        uint256 absCosmicFactorDiff = uint256(cosmicFactorDiff >= 0 ? cosmicFactorDiff : -cosmicFactorDiff);
        // Normalize diff by assuming a max possible diff (e.g., 2000 if factor is +/- 1000)
        uint256 normalizedDiff = absCosmicFactorDiff.mul(1e18).div(2000); // Scale to 0-1e18

        // Calculate boost multiplier: 1 + (MaxBoost - 1) * normalizedDiff
        // Let's cap normalizedDiff at 1e18 to avoid overflow and excessive boost
        normalizedDiff = normalizedDiff.min(1e18);
        uint256 maxBoostScaled = essenceMaxYieldBoostFactor.mul(1e18);
        uint256 boostMultiplier = 1e18.add((maxBoostScaled.sub(1e18)).mul(normalizedDiff).div(1e18)); // (MaxBoost - 1) * normalizedDiff

        // Final dynamic yield rate per second (scaled): baseYieldRatePerSecond * effectivePotencyFactor * boostMultiplier
        // Need to scale baseYieldRatePerSecond if it's not already in wei
        // Let's assume baseYieldRatePerSecond is in wei per second per 100 potency unit at 1x volatility.
        uint256 dynamicRate = baseYieldRatePerSecond.mul(effectivePotencyFactor).div(1e18).mul(boostMultiplier).div(1e18);

        uint256 yieldAmount = dynamicRate.mul(timeElapsed);

        essenceLastHarvestTime[essenceId] = block.timestamp;

        emit EssenceYieldHarvested(essenceStakingInfo[essenceId].staker, essenceId, yieldAmount);

        return yieldAmount;
    }


    /// @notice Burns a TemporalEssence NFT to recover some ForgeFuel.
    /// Recovery amount depends on original cost and a fixed factor.
    /// Can only be called by the owner of the unstaked NFT.
    /// @param essenceId The ID of the TemporalEssence NFT to decompose.
    function decomposeEssence(uint256 essenceId) external nonReentrant whenNotPaused {
        require(address(temporalEssenceNFT) != address(0), "TemporalEssence NFT not set");
        require(temporalEssenceNFT.ownerOf(essenceId) == msg.sender, "Caller must own the NFT");
        require(essenceStakedAmount[essenceId] == 0, "Essence must be unstaked to decompose");

        // Calculate recovery amount (fixed percentage of original forging cost)
        uint256 recoveryAmount = forgingCost.mul(decompositionRecoveryFactor).div(10000); // Factor is permil, need to divide by 10000 for percentage

        // Burn the NFT
        temporalEssenceNFT.burn(essenceId); // Assuming the NFT contract has a burn function

        // Transfer fuel back to the user
        if (recoveryAmount > 0) {
            bool success = forgeFuelToken.transfer(msg.sender, recoveryAmount);
            require(success, "Fuel recovery transfer failed");
        }

        // Clean up state
        delete essenceCreationInfo[essenceId];
        // Staking info/amount should already be clear if unstaked

        emit EssenceDecomposed(msg.sender, essenceId, recoveryAmount);
    }

    /// @notice Refines a TemporalEssence NFT by spending ForgeFuel to boost its base potency.
    /// Can only be called by the owner of the unstaked NFT.
    /// @param essenceId The ID of the TemporalEssence NFT to refine.
    function refineEssence(uint256 essenceId) external nonReentrant whenNotPaused {
        require(address(temporalEssenceNFT) != address(0), "TemporalEssence NFT not set");
        require(address(forgeFuelToken) != address(0), "ForgeFuel token not set");
        require(temporalEssenceNFT.ownerOf(essenceId) == msg.sender, "Caller must own the NFT");
        require(essenceStakedAmount[essenceId] == 0, "Essence must be unstaked to refine");
        require(essenceCreationInfo[essenceId].creationTime > 0, "Essence does not exist or info missing"); // Ensure it's a valid essence

        // Ensure current base potency is below max
        require(essenceCreationInfo[essenceId].basePotency < essenceMaxPotency, "Essence already at max potency");

        // Take ForgeFuel payment
        bool success = forgeFuelToken.transferFrom(msg.sender, address(this), refinementCost);
        require(success, "Refinement cost transfer failed");

        // Apply refinement effect (increase base potency)
        uint256 oldPotency = essenceCreationInfo[essenceId].basePotency;
        essenceCreationInfo[essenceId].basePotency = essenceCreationInfo[essenceId].basePotency.add(refinementPotencyBoost).min(essenceMaxPotency);
        uint256 newPotency = essenceCreationInfo[essenceId].basePotency;

        emit EssenceRefined(msg.sender, essenceId, refinementCost, newPotency);
    }

    // --- View Functions (Public) ---

    /// @notice Gets the amount of ForgeFuel staked by a specific user.
    /// @param user The address of the user.
    /// @return The staked amount.
    function getUserStakedFuel(address user) external view returns (uint256) {
        return userStakedFuel[user];
    }

    /// @notice Calculates the current dynamic state (potency, volatility) of an Essence.
    /// Potency grows over time towards maxPotency. Volatility is influenced by current vs initial cosmic factor.
    /// @param essenceId The ID of the TemporalEssence NFT.
    /// @return currentPotency The dynamically calculated potency.
    /// @return currentCosmicFactor The current value from the oracle for the cosmic factor key.
    function getEssenceState(uint256 essenceId) public view returns (uint256 currentPotency, int256 currentCosmicFactor) {
        EssenceInfo storage info = essenceCreationInfo[essenceId];
        require(info.creationTime > 0, "Essence does not exist or info missing");

        // Potency: Simple time decay/growth model. Starts at base, grows towards max over time.
        // Let's say potency grows linearly from basePotency to essenceMaxPotency over a fixed period (e.g., 30 days).
        // Or simpler: grows towards max at a fixed rate per second, capped at max.
        // currentPotency = min(basePotency + timeSinceCreation * growthRatePerSecond, essenceMaxPotency)
        // GrowthRatePerSecond = (essenceMaxPotency - InitialPotency) / GrowthDuration
        // Let's simplify: potency increases slightly over time, plus refinement adds directly.
        // The *displayed* potency could be the base + time factor, but the *yield calculation* uses base + refinement.
        // Or, let's make it simpler: basePotency *is* the value that changes with refinement.
        // The *displayed* potency can add a time-based bonus, or be calculated based on time/oracle.
        // Let's make getEssenceState calculate a TEMPORAL_POTENCY based on creation time and oracle data.
        // TEMPORAL_POTENCY = basePotency (from EssenceInfo) + (block.timestamp - creationTime) / 1 day (example growth) + oracle influence

        uint256 timeSinceCreation = block.timestamp - info.creationTime;
        uint256 timeBasedPotencyBonus = timeSinceCreation / 86400; // Add 1 potency per day (example)

        // Get current Cosmic Factor from oracle
        int256 oracleValue = 0;
        // Only attempt oracle call if set and key is allowed
        if (address(cosmicOracle) != address(0)) {
             for(uint i = 0; i < allowedOracleDataKeys.length; i++) {
                if (allowedOracleDataKeys[i] == essenceCosmicFactorKey) {
                     (oracleValue, , ) = cosmicOracle.getData(essenceCosmicFactorKey);
                     break;
                }
            }
        }
        currentCosmicFactor = oracleValue; // Current factor from oracle

        // Oracle Influence on Potency: Example - Potency gets a bonus/penalty based on how far current factor is from initial
        // Influence = (currentCosmicFactor - initialCosmicFactor) / SomeFactorToScaleInfluence
        // Example: Influence = (currentCosmicFactor - initialCosmicFactor) / 10 (Integer division)
        int256 potencyOracleInfluence = (currentCosmicFactor - info.initialCosmicFactor) / 10; // Example scaling

        // Final calculated potency: Base Potency + Time Bonus + Oracle Influence (handle potential negative influence)
        uint256 calculatedPotency = info.basePotency.add(timeBasedPotencyBonus);
        if (potencyOracleInfluence > 0) {
            calculatedPotency = calculatedPotency.add(uint256(potencyOracleInfluence));
        } else if (potencyOracleInfluence < 0) {
            uint256 penalty = uint256(-potencyOracleInfluence);
             calculatedPotency = calculatedPotency > penalty ? calculatedPotency.sub(penalty) : 0;
        }

        currentPotency = calculatedPotency.min(essenceMaxPotency.mul(2)); // Cap displayed/calculated potency higher than base max? Or at a fixed max? Let's cap it at 2x max base.

        return (currentPotency, currentCosmicFactor);
    }

    /// @notice Calculates the pending yield for a specific staked Essence.
    /// Does not affect the state (read-only).
    /// @param essenceId The ID of the staked TemporalEssence NFT.
    /// @return The amount of pending ForgeFuel yield.
    function getPendingEssenceYield(uint256 essenceId) public view returns (uint256) {
        require(essenceStakedAmount[essenceId] == 1, "Essence is not staked");

        uint256 lastHarvestTime = essenceLastHarvestTime[essenceId];
        uint256 timeElapsed = block.timestamp - lastHarvestTime;

        if (timeElapsed == 0) {
            return 0;
        }

        // Get current dynamic state (potency, volatility)
        (uint256 currentPotency, int256 currentCosmicFactor) = getEssenceState(essenceId);

         // Calculate dynamic yield rate (same logic as in _harvestEssenceYield)
        uint256 effectivePotencyFactor = currentPotency.mul(1e18).div(100).div(1e18);
         if (effectivePotencyFactor == 0) effectivePotencyFactor = 1;

        uint256 volatilityBoost = 1e18;
        int256 cosmicFactorDiff = currentCosmicFactor - essenceCreationInfo[essenceId].initialCosmicFactor;
        uint256 absCosmicFactorDiff = uint256(cosmicFactorDiff >= 0 ? cosmicFactorDiff : -cosmicFactorDiff);
        uint256 normalizedDiff = absCosmicFactorDiff.mul(1e18).div(2000);
        normalizedDiff = normalizedDiff.min(1e18);
        uint256 maxBoostScaled = essenceMaxYieldBoostFactor.mul(1e18);
        uint256 boostMultiplier = 1e18.add((maxBoostScaled.sub(1e18)).mul(normalizedDiff).div(1e18));

        uint256 dynamicRate = baseYieldRatePerSecond.mul(effectivePotencyFactor).div(1e18).mul(boostMultiplier).div(1e18);

        uint256 yieldAmount = dynamicRate.mul(timeElapsed);

        return yieldAmount;
    }

    /// @notice Gets the current ForgeFuel cost to forge a new Essence.
    /// @return The current forging cost.
    function getForgingCost() external view returns (uint256) {
        return forgingCost;
    }

    /// @notice Calculates the current potential yield rate per second for a specific Essence if it were staked.
    /// This uses the dynamic state calculation.
    /// @param essenceId The ID of the TemporalEssence NFT.
    /// @return The potential yield rate per second in ForgeFuel wei.
    function getYieldRate(uint256 essenceId) external view returns (uint256) {
         EssenceInfo storage info = essenceCreationInfo[essenceId];
         require(info.creationTime > 0, "Essence does not exist or info missing");

        // Get current dynamic state (potency, volatility)
        (uint256 currentPotency, int256 currentCosmicFactor) = getEssenceState(essenceId);

         // Calculate dynamic yield rate (same logic as in _harvestEssenceYield)
        uint256 effectivePotencyFactor = currentPotency.mul(1e18).div(100).div(1e18);
         if (effectivePotencyFactor == 0) effectivePotencyFactor = 1;

        uint256 volatilityBoost = 1e18;
        int256 cosmicFactorDiff = currentCosmicFactor - essenceCreationInfo[essenceId].initialCosmicFactor;
        uint256 absCosmicFactorDiff = uint256(cosmicFactorDiff >= 0 ? cosmicFactorDiff : -cosmicFactorDiff);
        uint256 normalizedDiff = absCosmicFactorDiff.mul(1e18).div(2000);
        normalizedDiff = normalizedDiff.min(1e18);
        uint256 maxBoostScaled = essenceMaxYieldBoostFactor.mul(1e18);
        uint256 boostMultiplier = 1e18.add((maxBoostScaled.sub(1e18)).mul(normalizedDiff).div(1e18));

        uint256 dynamicRate = baseYieldRatePerSecond.mul(effectivePotencyFactor).div(1e18).mul(boostMultiplier).div(1e18);

        return dynamicRate;
    }

    /// @notice Gets the static creation information for an Essence.
    /// @param essenceId The ID of the TemporalEssence NFT.
    /// @return creationTime The timestamp of creation.
    /// @return basePotency The initial/refined base potency.
    /// @return initialCosmicFactor The oracle value at creation.
    /// @return initialOracleDataHash The hash of oracle data at creation.
     function getEssenceInfo(uint256 essenceId) external view returns (uint256 creationTime, uint256 basePotency, int256 initialCosmicFactor, bytes32 initialOracleDataHash) {
         EssenceInfo storage info = essenceCreationInfo[essenceId];
         require(info.creationTime > 0, "Essence does not exist or info missing");
         return (info.creationTime, info.basePotency, info.initialCosmicFactor, info.initialOracleDataHash);
     }

    /// @notice Checks if a specific Essence is currently staked in the forge.
    /// @param essenceId The ID of the TemporalEssence NFT.
    /// @return True if staked, false otherwise.
     function isEssenceStaked(uint256 essenceId) external view returns (bool) {
         return essenceStakedAmount[essenceId] == 1;
     }

    /// @notice Gets the list of oracle data keys that this contract is configured to use.
    /// @return An array of allowed oracle data keys.
     function getAllowedOracleDataKeys() external view returns (bytes32[] memory) {
         return allowedOracleDataKeys;
     }


    // --- Admin/Rescue Functions (Owner Only) ---

    /// @notice Allows the owner to withdraw accumulated protocol fees for a specific token.
    /// @param token The address of the token to withdraw.
    /// @param amount The amount to withdraw.
    function withdrawProtocolFees(address token, uint256 amount) external onlyOwner {
        require(protocolFeeTreasury[token] >= amount, "Insufficient fees accumulated");
        protocolFeeTreasury[token] = protocolFeeTreasury[token].sub(amount);
        IERC20 feeToken = IERC20(token);
        bool success = feeToken.transfer(owner(), amount);
        require(success, "Fee withdrawal transfer failed");
        emit ProtocolFeesWithdrawn(token, owner(), amount);
    }

    /// @notice Allows the owner to rescue ERC20 tokens accidentally sent to the contract.
    /// Does not allow withdrawing the protocol's intended tokens (ForgeFuel or staked NFTs).
    /// @param token The address of the ERC20 token to rescue.
    /// @param to The address to send the tokens to.
    /// @param amount The amount of tokens to rescue.
    function rescueERC20(address token, address to, uint256 amount) external onlyOwner {
        require(token != address(forgeFuelToken), "Cannot rescue ForgeFuel via this function");
        // Add other token addresses if they shouldn't be rescued, e.g., governance token if added later.
        require(token != address(temporalEssenceNFT), "Cannot rescue TemporalEssence NFT via this function"); // ERC721 rescue below

        IERC20 rescueToken = IERC20(token);
        require(rescueToken.balanceOf(address(this)) >= amount, "Insufficient balance to rescue");
        bool success = rescueToken.transfer(to, amount);
        require(success, "ERC20 rescue transfer failed");
    }

    /// @notice Allows the owner to rescue ERC721 tokens accidentally sent to the contract.
    /// Does not allow rescuing the protocol's intended NFTs (TemporalEssence).
    /// @param nft The address of the ERC721 token to rescue.
    /// @param to The address to send the NFT to.
    /// @param tokenId The ID of the NFT to rescue.
    function rescueERC721(address nft, address to, uint256 tokenId) external onlyOwner {
        require(nft != address(temporalEssenceNFT), "Cannot rescue TemporalEssence NFT via this function");

        IERC721 rescueNFT = IERC721(nft);
        require(rescueNFT.ownerOf(tokenId) == address(this), "Contract does not own the NFT");
        rescueNFT.transferFrom(address(this), to, tokenId);
    }

    // --- Internal Functions (Helper) ---

    // Currently, _harvestEssenceYield is internal helper called by public harvestEssenceYield and unstakeEssence.
    // Other helper logic is directly within public functions or view functions.
    // If complexity grows, more internal helpers could be extracted (e.g., _calculateDynamicRate, _validateOracleData).


    // --- Fallback/Receive (Optional but good practice) ---
    receive() external payable {
        // Optionally handle received ETH, though this contract is token-based.
        // revert("ETH not accepted");
    }

    fallback() external payable {
        // Optionally handle calls to undefined functions
        // revert("Call not recognized");
    }

    // Note: A real-world implementation would need the ForgeFuel and TemporalEssence
    // contracts to be deployed separately and their addresses set in this contract.
    // The TemporalEssence contract would need `mint(address to, uint256 tokenId, string memory uri)`,
    // `burn(uint256 tokenId)`, and potentially `nextTokenId()` or similar mechanisms.
    // The Oracle contract would need to implement `ICosmicOracle`.
}
```

---

**Explanation of Advanced/Creative/Trendy Aspects:**

1.  **Multi-Asset Interaction:** The contract manages user balances of an ERC-20 (`ForgeFuel`) and custody/staking of an ERC-721 (`TemporalEssence`).
2.  **Dynamic NFTs:** The `getEssenceState` function calculates properties (`currentPotency`) that change dynamically based on time since creation and external oracle data, rather than being static metadata. This goes beyond simple metadata updates.
3.  **NFT Staking for Yield:** Users stake unique NFTs to earn a fungible token (`ForgeFuel`), a common pattern in GameFi and DeFi, but implemented here specifically for these dynamically changing assets.
4.  **Oracle Integration:** The forging process and the dynamic state of the NFT (`getEssenceState`, `getYieldRate`, `_harvestEssenceYield`) are directly influenced by an external oracle (`ICosmicOracle`). This connects the on-chain state to external reality.
5.  **Complex Yield Calculation:** The yield rate earned by staking an NFT is not fixed but depends on the NFT's *current* dynamic state (potency) and the volatility observed in the oracle feed since its creation.
6.  **Forging Mechanics with Prerequisites:** Forging requires staking the base token *and* waiting for a minimum duration (`forgingDuration`) before the staked fuel can be used, adding a time-lock/commitment element.
7.  **NFT Lifecycle Management:** Beyond minting and transfer, the contract includes `refineEssence` (burning fuel to alter properties) and `decomposeEssence` (burning the NFT for partial fuel recovery), providing multiple ways to interact with the asset based on its state and the user's goals.
8.  **Protocol Fees:** A fee is charged on the forging process, directed to a treasury within the contract, providing a mechanism for protocol value capture or funding.
9.  **Pausability and Upgradability Hooks:** While not a fully implemented proxy pattern, including `Pausable` and owner-only `set...` functions provides basic control, and the structure is compatible with future upgradability patterns like UUPS (by changing inheritance and adding a proxy contract).
10. **Reentrancy Protection:** Using `ReentrancyGuard` on critical state-changing functions is standard but essential for security in complex interactions.

This design moves beyond a basic token or simple NFT collection, creating a mini-protocol where assets are forged, evolve, and interact with external data to influence their utility and yield. The combination of dynamic state, oracle influence, and the specific forging/staking/refining/decomposing mechanics provides a creative and somewhat advanced use case for smart contracts.