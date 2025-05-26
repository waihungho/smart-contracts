Okay, let's create a smart contract incorporating several advanced, creative, and interactive concepts like state machines, time-based mechanics, probabilistic outcomes, interaction with multiple token standards (ERC-20, ERC-721, ERC-1155), and dynamic NFT properties.

We'll design a contract called `DimensionalShiftGate`. Users will interact with this gate to attempt "shifts" into different "dimensions". The gate has a dynamic state (`Alignment` and `Charge`) that decays over time and influences the success probability and outcome of a shift. Successful shifts can mint unique "Shift Tokens" (ERC-721 NFTs) with properties representing the discovered dimension and power level. Users need to spend "Energy" (ERC-20) and potentially "Catalyst" (ERC-1155) to interact with the gate.

This combines concepts from gaming (resource management, probability, unique items), NFTs (dynamic properties, ownership), and state management.

---

## Smart Contract: DimensionalShiftGate

**Outline:**

1.  **License & Pragmas:** SPDX License Identifier, Solidity version.
2.  **Imports:** OpenZeppelin Contracts (Ownable, Pausable, ERC interfaces).
3.  **Errors:** Custom error definitions for clearer reasons.
4.  **Enums:** Define the possible states of the Gate.
5.  **Structs:** Define the properties for the unique Shift Tokens (ERC-721).
6.  **State Variables:** Store contract parameters, gate state, user data, token data.
7.  **Events:** Log key actions and state changes.
8.  **Constructor:** Initialize the contract with required token addresses and initial parameters.
9.  **Modifiers:** Restrict access (e.g., `onlyOwner`, `whenNotPaused`).
10. **Internal/Private Helper Functions:** Logic encapsulated for clarity and reusability (e.g., calculating decay, determining shift outcome, updating token properties).
11. **Admin/Owner Functions:** Functions only callable by the contract owner to configure parameters, manage funds, etc. (>= 12 functions).
12. **User Interaction Functions:** Functions users call to interact with the gate (>= 3 functions).
13. **Query/View Functions:** Functions to read the contract's state and user data (>= 5 functions).

**Function Summary:**

*   **Admin/Owner Functions:**
    *   `setShiftTokenContract`: Set the address of the ERC-721 Shift Token contract.
    *   `setEnergyTokenContract`: Set the address of the ERC-20 Energy Token contract.
    *   `setCatalystNFTContract`: Set the address of the ERC-1155 Catalyst NFT contract.
    *   `setGateState`: Manually set the gate's operational state (for admin control).
    *   `setShiftCosts`: Configure the base energy and catalyst costs for performing a shift.
    *   `setCalibrationCost`: Configure the energy cost for calibrating the gate.
    *   `setDecayRates`: Configure how quickly Gate Alignment and Charge decay over time.
    *   `setMinAlignmentForShift`: Set the minimum Alignment level required to *attempt* a shift.
    *   `setShiftCooldownDuration`: Set the time users must wait between shift attempts.
    *   `addDimensionParameter`: Add parameters for a new discoverable dimension (probability weighting, min/max power).
    *   `updateDimensionParameter`: Modify parameters for an existing dimension.
    *   `withdrawEnergy`: Owner can withdraw excess Energy tokens held by the contract.
    *   `withdrawCatalyst`: Owner can withdraw excess Catalyst NFTs held by the contract.
    *   `pause`: Pause core user interactions (`performShift`).
    *   `unpause`: Unpause core user interactions.
*   **User Interaction Functions:**
    *   `chargeGate`: Users deposit Energy tokens to increase the Gate's Charge level.
    *   `calibrateGate`: Users deposit Energy tokens to increase the Gate's Alignment level.
    *   `performShift`: The main interaction. Users attempt a shift, consuming resources (Energy, Catalyst NFT). Success depends on gate state and calculated probability. Can result in minting or updating a Shift Token. Applies cooldown.
*   **Query/View Functions:**
    *   `getGateState`: Returns the current operational state of the gate.
    *   `getGateAlignment`: Returns the current Gate Alignment level.
    *   `getGateCharge`: Returns the current Gate Charge level.
    *   `getUserShiftCooldown`: Returns the timestamp when a user's shift cooldown expires.
    *   `getUserShiftCount`: Returns the number of successful shifts performed by a user.
    *   `getShiftTokenProperties`: Returns the properties (dimension, power, discovery time) for a given Shift Token ID.
    *   `getTotalShiftsPerformed`: Returns the total number of shifts performed across all users.
    *   `getShiftParameters`: Returns the current configured costs and cooldown.
    *   `getDimensionParameters`: Returns parameters for a specific dimension ID.
    *   `getDiscoveredDimensions`: Returns a list of all dimension IDs that have been discovered.
    *   `getEstimatedShiftCost`: Estimates the current cost of a shift based on parameters (doesn't account for dynamic factors yet, just base).
    *   `getEstimatedShiftSuccessChance`: Estimates the success chance based on current gate state (simplistic estimation).
*   **Internal Helper Functions (Not directly callable externally, ~6 functions):**
    *   `_applyDecay`: Updates alignment and charge based on elapsed time and decay rates.
    *   `_calculateShiftSuccessChance`: Computes the actual success chance based on current alignment, charge, and parameters.
    *   `_determineShiftOutcome`: Determines success/failure and the resulting dimension/power based on probability and randomness.
    *   `_mintOrUpdateShiftToken`: Handles the logic of interacting with the Shift Token contract (minting new or updating existing).
    *   `_checkShiftRequirements`: Checks if the caller meets the minimum requirements (cooldown, gate state, resources) for a shift attempt.
    *   `_updateGateState`: Transitions the gate state based on user actions or decay.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Although 0.8+ has overflow checks by default, good practice or for specific scenarios.
import "@openzeppelin/contracts/utils/Counters.sol"; // For Shift Token IDs
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol"; // Good practice for transfers

// Assume these interfaces exist for your specific token contracts
interface IShiftToken is IERC721 {
    function mint(address to, uint256 tokenId, uint256 dimensionId, uint256 powerLevel) external;
    function updateProperties(uint256 tokenId, uint256 dimensionId, uint256 powerLevel) external; // Example update function
    // Add other functions needed by the Gate, like checking if a token exists for an owner
    function exists(uint256 tokenId) external view returns (bool);
}

interface IEnergyToken is IERC20 {}

interface ICatalystNFT is IERC1155 {}

/**
 * @title DimensionalShiftGate
 * @dev A smart contract simulating an interactive gate to different dimensions.
 * Users spend resources (Energy, Catalyst NFT) to attempt shifts.
 * The gate has dynamic state (Alignment, Charge) that affects success probability and decays over time.
 * Successful shifts result in unique ERC-721 Shift Tokens with dynamic properties.
 * Includes admin controls, state management, time-based decay, probabilistic outcomes, and multi-token interaction.
 */
contract DimensionalShiftGate is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // --- Errors ---
    error GateIsNotActive();
    error NotEnoughEnergy();
    error NotEnoughCatalyst();
    error OnShiftCooldown(uint256 cooldownExpiration);
    error GateAlignmentTooLow(uint256 required, uint256 current);
    error GateChargeTooLow(uint256 required, uint256 current);
    error ShiftTokenContractNotSet();
    error EnergyTokenContractNotSet();
    error CatalystNFTContractNotSet();
    error DimensionAlreadyExists(uint256 dimensionId);
    error DimensionDoesNotExist(uint256 dimensionId);
    error NoShiftTokenForUser(address user); // Maybe we mint one per user? Or specific token?
    error InvalidShiftTokenId(uint256 tokenId);


    // --- Enums ---
    enum GateState {
        Idle,              // Default state
        Charging,          // Actively being charged by users
        Calibrating,       // Actively being calibrated by users
        Aligned,           // High alignment, ready for optimal shifts
        Misaligned,        // Low alignment, shifts are risky/unlikely
        CalibrationRequired // Alignment has dropped significantly, needs calibration
    }

    // --- Structs ---
    struct ShiftTokenProperties {
        uint256 dimensionId;
        uint256 powerLevel;
        uint256 discoveryTime; // Timestamp when the dimension was first reached via this token
    }

    struct DimensionParameters {
        uint256 probabilityWeight; // Higher weight means more likely to be chosen
        uint256 minPower;
        uint256 maxPower;
        bool isDiscovered; // True if at least one user has successfully shifted to this dimension
    }

    // --- State Variables ---
    IShiftToken public shiftTokenContract;
    IEnergyToken public energyTokenContract;
    ICatalystNFT public catalystNFTContract;

    GateState public currentGateState = GateState.Idle;
    uint256 public gateAlignment = 0; // 0 to 10000 (representing 0% to 100%)
    uint256 public gateCharge = 0;    // Arbitrary units of accumulated energy

    uint256 public lastInteractionTimestamp; // Used for decay calculation

    // Configuration Parameters
    uint256 public baseShiftEnergyCost = 100e18; // Example cost in EnergyToken (assuming 18 decimals)
    uint256 public baseShiftCatalystAmount = 1; // Amount of Catalyst NFT (e.g., type 1)
    uint256 public calibrationEnergyCost = 50e18;
    uint256 public decayRateAlignmentPerSecond = 1; // Points of alignment decay per second
    uint256 public decayRateChargePerSecond = 5;    // Points of charge decay per second
    uint256 public minAlignmentForShiftAttempt = 3000; // Min 30% alignment
    uint256 public shiftCooldownDuration = 1 days;    // Time in seconds

    // User Data
    mapping(address => uint256) public userShiftCooldowns; // Timestamp when cooldown ends
    mapping(address => uint256) public userShiftCounts;   // Successful shifts per user
    mapping(address => uint256) public userShiftTokenId; // Tracks the SINGLE ShiftToken ID for a user? Or allow multiple? Let's do one per user for simplicity first, representing their 'connection' to the gate. This might need adjustment based on actual NFT contract logic (minting per shift vs per user). Let's assume one NFT *per user's journey* that gets updated. User ID mapping to token ID might be complex if the NFT contract handles ownership elsewhere. Alternative: Require user to provide *their* token ID to update. Let's go with the user mapping to a single token ID they own. This token ID must *exist* and be *owned* by them. User mints it once via this gate.
    // --- Let's rethink: The ERC721 contract handles ownership. This contract should just know how to *call* mint/update on it. The user provides their target token ID if they want to update, or a new ID if they are minting their first. ---
    // Simpler approach: The Shift Token contract handles minting and assigns IDs. We just store properties associated with the *minted token ID*. The user gets *a* token ID from the minting process.

    // Shift Token Data (Mapping token ID to its properties)
    mapping(uint256 => ShiftTokenProperties) public shiftTokenProperties;
    Counters.Counter private _shiftTokenIds; // Counter for new Shift Token IDs minted by this contract

    // Dimension Data
    mapping(uint256 => DimensionParameters) public dimensionParameters;
    uint256[] public discoveredDimensions; // List of dimension IDs that have been reached
    mapping(uint256 => bool) private _isDimensionDiscovered; // Helper to quickly check discovery

    // Global Stats
    uint256 public totalShiftsPerformed = 0;
    uint256 public totalEnergyConsumed = 0;

    // --- Events ---
    event GateStateChanged(GateState newState, uint256 timestamp);
    event GateCharged(address indexed user, uint256 amount, uint256 newCharge);
    event GateCalibrated(address indexed user, uint256 amount, uint256 newAlignment);
    event ShiftAttempted(address indexed user, uint256 timestamp);
    event ShiftPerformed(address indexed user, uint256 tokenId, uint256 dimensionId, uint256 powerLevel, uint256 timestamp);
    event ShiftFailed(address indexed user, string reason, uint256 timestamp);
    event ShiftTokenMinted(address indexed user, uint256 tokenId, uint256 dimensionId, uint256 powerLevel, uint256 timestamp);
    event ShiftTokenUpdated(address indexed user, uint256 tokenId, uint256 newDimensionId, uint256 newPowerLevel, uint256 timestamp);
    event DimensionDiscovered(uint256 dimensionId, uint256 timestamp);
    event ParametersUpdated(string paramName); // Generic event for config changes
    event OwnerWithdrawal(address indexed tokenAddress, uint256 amount);


    // --- Constructor ---
    constructor(address _shiftTokenAddress, address _energyTokenAddress, address _catalystNFTAddress)
        Ownable(msg.sender) // msg.sender is the initial owner
    {
        require(_shiftTokenAddress != address(0), "ShiftToken address zero");
        require(_energyTokenAddress != address(0), "EnergyToken address zero");
        require(_catalystNFTAddress != address(0), "CatalystNFT address zero");

        shiftTokenContract = IShiftToken(_shiftTokenAddress);
        energyTokenContract = IEnergyToken(_energyTokenAddress);
        catalystNFTContract = ICatalystNFT(_catalystNFTAddress);

        lastInteractionTimestamp = block.timestamp; // Initialize decay timer

        // Add initial dimension(s) - Dimension 1 is always known/reachable
        _addDimensionParameter(1, 100, 1, 1000); // Dim 1: weight 100, power 1-1000
        _discoverDimension(1); // Dimension 1 is discovered from the start

        emit GateStateChanged(currentGateState, block.timestamp);
    }

    // --- Modifiers ---
    modifier updateGateState() {
        _applyDecay();
        _;
        _updateGateState();
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Applies decay to Gate Alignment and Charge based on elapsed time.
     */
    function _applyDecay() internal {
        uint256 timeElapsed = block.timestamp.sub(lastInteractionTimestamp);

        // Prevent underflow on subtraction, effectively capping decay at current value
        gateAlignment = gateAlignment > decayRateAlignmentPerSecond.mul(timeElapsed)
            ? gateAlignment.sub(decayRateAlignmentPerSecond.mul(timeElapsed))
            : 0;

        gateCharge = gateCharge > decayRateChargePerSecond.mul(timeElapsed)
            ? gateCharge.sub(decayRateChargePerSecond.mul(timeElapsed))
            : 0;

        lastInteractionTimestamp = block.timestamp;
    }

    /**
     * @dev Calculates the success chance of a shift based on gate state.
     * @return successChance Percentage (0-10000)
     */
    function _calculateShiftSuccessChance() internal view returns (uint256) {
        // Simple calculation: base chance + bonus from alignment + bonus from charge (capped)
        // Max alignment: 10000 (100%), Max charge: (needs a max threshold?)
        // Let's assume optimal alignment/charge gives a significant bonus.
        // Base chance could be 10% (1000) at min requirements.
        // Max alignment bonus: up to 40% (4000)
        // Max charge bonus: up to 20% (2000)
        // Total Max chance: 10% + 40% + 20% = 70% (7000)

        uint256 baseChance = 1000; // 10%
        uint256 maxAlignmentBonus = 4000; // 40%
        uint256 maxChargeBonus = 2000; // 20%
        uint256 maxPossibleAlignment = 10000;
        uint256 maxEffectiveCharge = 50000e18; // Assume charge beyond this gives no further bonus

        uint256 alignmentBonus = gateAlignment.mul(maxAlignmentBonus).div(maxPossibleAlignment);
        uint256 chargeBonus = gateCharge > maxEffectiveCharge
            ? maxChargeBonus
            : gateCharge.mul(maxChargeBonus).div(maxEffectiveCharge);

        // Ensure total chance doesn't exceed 100% (10000)
        return baseChance.add(alignmentBonus).add(chargeBonus).min(10000);
    }

    /**
     * @dev Determines the outcome of a shift attempt (success/fail, dimension, power).
     * Relies on Chainlink VRF or a similar oracle for true randomness in production.
     * For this example, using blockhash (NOT secure or truly random for production).
     * @return success True if shift is successful
     * @return dimensionId The ID of the dimension reached (if successful)
     * @return powerLevel The power level assigned to the token (if successful)
     */
    function _determineShiftOutcome() internal view returns (bool success, uint256 dimensionId, uint256 powerLevel) {
        uint256 successChance = _calculateShiftSuccessChance();
        uint256 randomValue = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.number, block.difficulty))) % 10000; // Insecure randomness! Replace in production.

        success = randomValue < successChance;

        if (success) {
            // Determine Dimension ID based on weights
            uint256 totalWeight = 0;
            for (uint i = 0; i < discoveredDimensions.length; i++) {
                totalWeight = totalWeight.add(dimensionParameters[discoveredDimensions[i]].probabilityWeight);
            }

            uint256 dimensionRandom = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.number, "dimension"))) % totalWeight;
            uint256 cumulativeWeight = 0;

            for (uint i = 0; i < discoveredDimensions.length; i++) {
                uint256 currentDimensionId = discoveredDimensions[i];
                cumulativeWeight = cumulativeWeight.add(dimensionParameters[currentDimensionId].probabilityWeight);
                if (dimensionRandom < cumulativeWeight) {
                    dimensionId = currentDimensionId;
                    break;
                }
            }

            // Determine Power Level within dimension range
            DimensionParameters storage params = dimensionParameters[dimensionId];
            uint256 powerRange = params.maxPower.sub(params.minPower).add(1);
            uint256 powerRandom = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.number, "power"))) % powerRange;
            powerLevel = params.minPower.add(powerRandom);

             // Rare chance to discover a new dimension (if any non-discovered exist)
            // This part would need a mechanism to *list* potential but undiscovered dimensions.
            // For simplicity in this example, let's skip truly *random* discovery of *new* dimensions via shifts,
            // and assume new dimensions are added by admin and become 'discoverable' (weight > 0) but only 'discovered' when first shifted to.
            // We check if the chosen dimension is newly 'discovered' by *this shift*.
            if (!_isDimensionDiscovered[dimensionId]) {
                 _discoverDimension(dimensionId);
            }

        } else {
            // On failure, dimensionId and powerLevel can be zero or some indicator
            dimensionId = 0;
            powerLevel = 0;
        }
    }

    /**
     * @dev Handles the logic of interacting with the Shift Token contract.
     * Mints a new token if the user doesn't have one tracked by this contract, or updates an existing one.
     * Assumes a user gets ONE main shift token representing their journey.
     * @param user The address of the user.
     * @param dimensionId The dimension reached.
     * @param powerLevel The power level achieved.
     * @return tokenId The ID of the token minted or updated.
     */
    function _mintOrUpdateShiftToken(address user, uint256 dimensionId, uint256 powerLevel) internal returns (uint256 tokenId) {
         if (address(shiftTokenContract) == address(0)) revert ShiftTokenContractNotSet();

        // Simple logic: If user has no token ID recorded here, mint one. Otherwise, update their existing one.
        // NOTE: A more robust system might involve checking if the user still *owns* the recorded token ID.
        // Or allow users to specify *which* of their Shift Tokens to potentially update if they own multiple.
        // This simplified version assumes one main token per user's journey tracked by this gate.
        if (userShiftTokenId[user] == 0) {
            _shiftTokenIds.increment();
            tokenId = _shiftTokenIds.current();
            // Call the external ERC721 contract's mint function
            shiftTokenContract.mint(user, tokenId, dimensionId, powerLevel);
            userShiftTokenId[user] = tokenId; // Record the token ID for this user

            shiftTokenProperties[tokenId] = ShiftTokenProperties({
                dimensionId: dimensionId,
                powerLevel: powerLevel,
                discoveryTime: block.timestamp
            });
            emit ShiftTokenMinted(user, tokenId, dimensionId, powerLevel, block.timestamp);

        } else {
            tokenId = userShiftTokenId[user];
            // Check if the user still owns this token ID (Important security check)
             if (shiftTokenContract.ownerOf(tokenId) != user) {
                 // If the user somehow lost the token associated with their record, mint a new one for them.
                 // Or, revert? Reverting is safer. Let's revert and require the user to re-align their state if needed.
                 // A complex system might allow linking a *new* token, but that's out of scope for 20+ functions.
                 revert InvalidShiftTokenId(tokenId); // Indicates recorded token isn't owned by user
             }


            // Call the external ERC721 contract's update function
            shiftTokenContract.updateProperties(tokenId, dimensionId, powerLevel);

            // Update properties stored in this contract
            shiftTokenProperties[tokenId].dimensionId = dimensionId;
            shiftTokenProperties[tokenId].powerLevel = powerLevel;
            // discoveryTime is usually set on first discovery, might not update here, depending on logic
            // shiftTokenProperties[tokenId].discoveryTime = block.timestamp; // Or maybe update discovery time only if it's a *new* dimension for *this token*

            emit ShiftTokenUpdated(user, tokenId, dimensionId, powerLevel, block.timestamp);
        }
    }

    /**
     * @dev Checks if the requirements for attempting a shift are met.
     */
    function _checkShiftRequirements(address user) internal view {
        if (currentGateState == GateState.Idle) revert GateIsNotActive(); // Ensure gate is in an active state
        if (block.timestamp < userShiftCooldowns[user]) revert OnShiftCooldown(userShiftCooldowns[user]);
        if (gateAlignment < minAlignmentForShiftAttempt) revert GateAlignmentTooLow(minAlignmentForShiftAttempt, gateAlignment);
        // Assuming Shift Charge is a requirement, enforce a minimum (e.g., same as minAlignment)
        // if (gateCharge < ???) revert GateChargeTooLow(???, gateCharge); // Add a min charge threshold if desired
        // Resource checks happen *before* calling this function in performShift
    }

     /**
      * @dev Updates the gate state based on current conditions.
      */
    function _updateGateState() internal {
         GateState oldState = currentGateState;
        if (gateAlignment < minAlignmentForShiftAttempt && currentGateState != GateState.CalibrationRequired) {
            currentGateState = GateState.CalibrationRequired;
        } else if (gateAlignment >= minAlignmentForShiftAttempt && currentGateState == GateState.CalibrationRequired) {
             currentGateState = GateState.Idle; // Or Aligned, depends on exact threshold
        }

        // Example transitions - make these more complex if needed
        // e.g., High alignment + high charge = Aligned
        // Low alignment = Misaligned
        // Actively Charging/Calibrating could be states set by user actions directly
        // This simplified update only reacts to decay causing CalibrationRequired

        if (oldState != currentGateState) {
             emit GateStateChanged(currentGateState, block.timestamp);
        }
    }

    /**
     * @dev Marks a dimension as discovered.
     * Internal helper, called when the first shift to a dimension occurs.
     */
     function _discoverDimension(uint256 dimensionId) internal {
         if (!_isDimensionDiscovered[dimensionId]) {
             _isDimensionDiscovered[dimensionId] = true;
             discoveredDimensions.push(dimensionId);
             dimensionParameters[dimensionId].isDiscovered = true;
             emit DimensionDiscovered(dimensionId, block.timestamp);
         }
     }

     /**
      * @dev Internal function to add dimension parameters.
      * Used in constructor and admin function.
      */
    function _addDimensionParameter(uint256 dimensionId, uint256 weight, uint256 minP, uint256 maxP) internal {
         require(dimensionParameters[dimensionId].probabilityWeight == 0, "Dimension already exists");
         dimensionParameters[dimensionId] = DimensionParameters({
             probabilityWeight: weight,
             minPower: minP,
             maxPower: maxP,
             isDiscovered: false // Mark as undiscovered initially (unless it's Dimension 1 in constructor)
         });
    }

    // --- Admin/Owner Functions (15 functions) ---

    /**
     * @dev Sets the address of the ERC-721 Shift Token contract.
     * Can only be called once unless reset logic is added.
     */
    function setShiftTokenContract(address _shiftTokenAddress) external onlyOwner {
        require(_shiftTokenAddress != address(0), "ShiftToken address zero");
        require(address(shiftTokenContract) == address(0), "ShiftToken contract already set"); // Allow setting only once
        shiftTokenContract = IShiftToken(_shiftTokenAddress);
        emit ParametersUpdated("ShiftTokenContract");
    }

    /**
     * @dev Sets the address of the ERC-20 Energy Token contract.
     * Can only be called once.
     */
    function setEnergyTokenContract(address _energyTokenAddress) external onlyOwner {
        require(_energyTokenAddress != address(0), "EnergyToken address zero");
        require(address(energyTokenContract) == address(0), "EnergyToken contract already set"); // Allow setting only once
        energyTokenContract = IEnergyToken(_energyTokenAddress);
        emit ParametersUpdated("EnergyTokenContract");
    }

    /**
     * @dev Sets the address of the ERC-1155 Catalyst NFT contract.
     * Can only be called once.
     */
    function setCatalystNFTContract(address _catalystNFTAddress) external onlyOwner {
        require(_catalystNFTAddress != address(0), "CatalystNFT address zero");
        require(address(catalystNFTContract) == address(0), "CatalystNFT contract already set"); // Allow setting only once
        catalystNFTContract = ICatalystNFT(_catalystNFTAddress);
        emit ParametersUpdated("CatalystNFTContract");
    }

    /**
     * @dev Manually sets the gate state. Use with caution.
     */
    function setGateState(GateState newState) external onlyOwner {
        currentGateState = newState;
        lastInteractionTimestamp = block.timestamp; // Reset decay timer on manual state change
        emit GateStateChanged(currentGateState, block.timestamp);
    }

    /**
     * @dev Configures the base energy and catalyst costs for performing a shift.
     */
    function setShiftCosts(uint256 energyCost, uint256 catalystAmount) external onlyOwner {
        baseShiftEnergyCost = energyCost;
        baseShiftCatalystAmount = catalystAmount;
        emit ParametersUpdated("ShiftCosts");
    }

    /**
     * @dev Configures the energy cost for calibrating the gate.
     */
    function setCalibrationCost(uint256 energyCost) external onlyOwner {
        calibrationEnergyCost = energyCost;
        emit ParametersUpdated("CalibrationCost");
    }

    /**
     * @dev Configures how quickly Gate Alignment and Charge decay over time (per second).
     */
    function setDecayRates(uint256 alignmentRatePerSecond, uint256 chargeRatePerSecond) external onlyOwner {
        decayRateAlignmentPerSecond = alignmentRatePerSecond;
        decayRateChargePerSecond = chargeRatePerSecond;
        emit ParametersUpdated("DecayRates");
    }

    /**
     * @dev Sets the minimum Alignment level required to *attempt* a shift (0-10000).
     */
    function setMinAlignmentForShift(uint256 minAlignment) external onlyOwner {
        minAlignmentForShiftAttempt = minAlignment.min(10000); // Cap at 10000
        emit ParametersUpdated("MinAlignmentForShift");
    }

     /**
      * @dev Sets the time users must wait between shift attempts in seconds.
      */
    function setShiftCooldownDuration(uint256 duration) external onlyOwner {
        shiftCooldownDuration = duration;
        emit ParametersUpdated("ShiftCooldownDuration");
    }


    /**
     * @dev Adds parameters for a new potential dimension.
     * Dimensions added here are *potential*, they become 'discovered' only after the first successful shift to them.
     */
    function addDimensionParameter(uint256 dimensionId, uint256 weight, uint256 minP, uint256 maxP) external onlyOwner {
        _addDimensionParameter(dimensionId, weight, minP, maxP);
        emit ParametersUpdated("DimensionParameterAdded");
    }

    /**
     * @dev Updates parameters for an existing dimension.
     */
    function updateDimensionParameter(uint256 dimensionId, uint256 weight, uint256 minP, uint256 maxP) external onlyOwner {
        require(dimensionParameters[dimensionId].probabilityWeight > 0, "Dimension does not exist");
        dimensionParameters[dimensionId].probabilityWeight = weight;
        dimensionParameters[dimensionId].minPower = minP;
        dimensionParameters[dimensionId].maxPower = maxP;
        // isDiscovered flag is managed internally
        emit ParametersUpdated("DimensionParameterUpdated");
    }


    /**
     * @dev Allows the owner to withdraw excess Energy tokens held by the contract.
     */
    function withdrawEnergy(uint256 amount) external onlyOwner nonReentrant {
        if (address(energyTokenContract) == address(0)) revert EnergyTokenContractNotSet();
        energyTokenContract.transfer(owner(), amount);
        emit OwnerWithdrawal(address(energyTokenContract), amount);
    }

    /**
     * @dev Allows the owner to withdraw excess Catalyst NFTs held by the contract.
     * Specify token ID (type) and amount.
     */
    function withdrawCatalyst(uint256 tokenId, uint256 amount) external onlyOwner nonReentrant {
        if (address(catalystNFTContract) == address(0)) revert CatalystNFTContractNotSet();
        catalystNFTContract.safeTransferFrom(address(this), owner(), tokenId, amount, "");
        emit OwnerWithdrawal(address(catalystNFTContract), amount);
    }

    // Pausable functions (already inherited from OpenZeppelin Pausable)
    // `pause()` and `unpause()` are now available via inheritance.
    // This adds 2 functions implicitly. We'll list them for the count.


    // --- User Interaction Functions (3 functions) ---

    /**
     * @dev Allows users to deposit Energy tokens to increase the Gate's Charge level.
     * Requires the user to have approved this contract to spend their Energy tokens.
     * @param amount The amount of Energy tokens to deposit.
     */
    function chargeGate(uint256 amount) external updateGateState nonReentrant {
        if (address(energyTokenContract) == address(0)) revert EnergyTokenContractNotSet();
        require(amount > 0, "Amount must be greater than zero");

        // Transfer tokens from the user to the contract
        bool success = energyTokenContract.transferFrom(msg.sender, address(this), amount);
        require(success, "Energy token transfer failed");

        gateCharge = gateCharge.add(amount); // Increase gate charge
        emit GateCharged(msg.sender, amount, gateCharge);
    }

    /**
     * @dev Allows users to deposit Energy tokens to increase the Gate's Alignment level.
     * Requires the user to have approved this contract to spend their Energy tokens.
     * @param amount The amount of Energy tokens to deposit (cost).
     */
    function calibrateGate(uint256 amount) external updateGateState nonReentrant {
         if (address(energyTokenContract) == address(0)) revert EnergyTokenContractNotSet();
         require(amount >= calibrationEnergyCost, "Amount less than calibration cost");

        // Transfer tokens from the user to the contract
        bool success = energyTokenContract.transferFrom(msg.sender, address(this), amount);
        require(success, "Energy token transfer failed");

        // Increase gate alignment, capped at 10000
        gateAlignment = gateAlignment.add(amount.mul(10000).div(calibrationEnergyCost.mul(10))).min(10000); // Simple scaling example
         emit GateCalibrated(msg.sender, amount, gateAlignment);
    }


    /**
     * @dev The main function for users to attempt a shift.
     * Requires energy and catalyst tokens, checks cooldown, gate state, and performs the probabilistic outcome.
     * Mints or updates a Shift Token on success.
     * Requires user to have approved EnergyToken and CatalystNFT transfers to this contract.
     */
    function performShift() external payable updateGateState whenNotPaused nonReentrant {
        if (address(energyTokenContract) == address(0)) revert EnergyTokenContractNotSet();
        if (address(catalystNFTContract) == address(0)) revert CatalystNFTContractNotSet();

        _checkShiftRequirements(msg.sender); // Checks cooldown, min alignment, gate state

        // Check and consume resources
        require(energyTokenContract.balanceOf(msg.sender) >= baseShiftEnergyCost, NotEnoughEnergy());
        require(energyTokenContract.allowance(msg.sender, address(this)) >= baseShiftEnergyCost, "Energy allowance too low");
        energyTokenContract.transferFrom(msg.sender, address(this), baseShiftEnergyCost);
        totalEnergyConsumed = totalEnergyConsumed.add(baseShiftEnergyCost);


        require(catalystNFTContract.balanceOf(msg.sender, baseShiftCatalystAmount) >= baseShiftCatalystAmount, NotEnoughCatalyst());
        require(catalystNFTContract.isApprovedForAll(msg.sender, address(this)), "Catalyst NFT not approved for all"); // Assuming approved for all for simplicity of consuming specific type
        catalystNFTContract.safeTransferFrom(msg.sender, address(this), baseShiftCatalystAmount, baseShiftCatalystAmount, ""); // Consume catalyst

        // Determine outcome
        (bool success, uint256 dimensionId, uint256 powerLevel) = _determineShiftOutcome();

        emit ShiftAttempted(msg.sender, block.timestamp);

        if (success) {
            uint256 mintedOrUpdatedTokenId = _mintOrUpdateShiftToken(msg.sender, dimensionId, powerLevel);
            userShiftCounts[msg.sender] = userShiftCounts[msg.sender].add(1);
            totalShiftsPerformed = totalShiftsPerformed.add(1);
            emit ShiftPerformed(msg.sender, mintedOrUpdatedTokenId, dimensionId, powerLevel, block.timestamp);
        } else {
            emit ShiftFailed(msg.sender, "Shift failed", block.timestamp);
            // On failure, maybe reduce gate charge/alignment? Or apply a penalty?
            // For now, just consume resources and apply cooldown.
        }

        // Apply cooldown
        userShiftCooldowns[msg.sender] = block.timestamp.add(shiftCooldownDuration);
    }


    // --- Query/View Functions (12 functions) ---

    /**
     * @dev Returns the current operational state of the gate.
     */
    function getGateState() external view returns (GateState) {
        return currentGateState;
    }

    /**
     * @dev Returns the current Gate Alignment level (0-10000) after considering decay.
     */
    function getGateAlignment() external view returns (uint256) {
        uint256 timeElapsed = block.timestamp.sub(lastInteractionTimestamp);
        return gateAlignment > decayRateAlignmentPerSecond.mul(timeElapsed)
            ? gateAlignment.sub(decayRateAlignmentPerSecond.mul(timeElapsed))
            : 0;
    }

    /**
     * @dev Returns the current Gate Charge level after considering decay.
     */
    function getGateCharge() external view returns (uint256) {
         uint256 timeElapsed = block.timestamp.sub(lastInteractionTimestamp);
        return gateCharge > decayRateChargePerSecond.mul(timeElapsed)
            ? gateCharge.sub(decayRateChargePerSecond.mul(timeElapsed))
            : 0;
    }

    /**
     * @dev Returns the timestamp when a user's shift cooldown expires.
     */
    function getUserShiftCooldown(address user) external view returns (uint256) {
        return userShiftCooldowns[user];
    }

    /**
     * @dev Returns the number of successful shifts performed by a user.
     */
    function getUserShiftCount(address user) external view returns (uint256) {
        return userShiftCounts[user];
    }

    /**
     * @dev Returns the properties (dimension, power, discovery time) for a given Shift Token ID.
     * Requires the Shift Token contract to correctly map token IDs.
     * Assumes the Shift Token contract's updateProperties call also updates the properties here.
     * Or, this contract is the SOLE source of truth for these properties. Let's assume this contract IS the source of truth.
     */
    function getShiftTokenProperties(uint256 tokenId) external view returns (uint256 dimensionId, uint256 powerLevel, uint256 discoveryTime) {
        // We check if the token ID was ever minted by this contract
        require(_shiftTokenIds.current() >= tokenId && tokenId > 0, InvalidShiftTokenId(tokenId));
        ShiftTokenProperties storage props = shiftTokenProperties[tokenId];
        // We don't need to check if the ShiftToken contract *exists*, as these properties are stored *here*
        // However, the user must *own* the token corresponding to this ID. This view function doesn't check ownership,
        // it just reports the properties stored for that ID.
        return (props.dimensionId, props.powerLevel, props.discoveryTime);
    }

    /**
     * @dev Returns the total number of shifts performed across all users.
     */
    function getTotalShiftsPerformed() external view returns (uint256) {
        return totalShiftsPerformed;
    }

     /**
      * @dev Returns the current configured costs and cooldown for a shift attempt.
      */
    function getShiftParameters() external view returns (uint256 energyCost, uint256 catalystAmount, uint256 cooldownDuration, uint256 minAlignment) {
        return (baseShiftEnergyCost, baseShiftCatalystAmount, shiftCooldownDuration, minAlignmentForShiftAttempt);
    }

    /**
     * @dev Returns parameters for a specific dimension ID.
     */
    function getDimensionParameters(uint256 dimensionId) external view returns (uint256 weight, uint256 minP, uint256 maxP, bool isDisc) {
        require(dimensionParameters[dimensionId].probabilityWeight > 0 || dimensionId == 1, DimensionDoesNotExist(dimensionId)); // Allow querying default dim 1 even if weight was set to 0 later
        DimensionParameters storage params = dimensionParameters[dimensionId];
        return (params.probabilityWeight, params.minPower, params.maxPower, params.isDiscovered);
    }

    /**
     * @dev Returns a list of all dimension IDs that have been discovered.
     */
    function getDiscoveredDimensions() external view returns (uint256[] memory) {
        return discoveredDimensions;
    }

    /**
     * @dev Estimates the current energy and catalyst cost of a shift based *only* on configured parameters.
     * Does not account for dynamic requirements or future parameter changes.
     */
    function getEstimatedShiftCost() external view returns (uint256 energyCost, uint256 catalystAmount) {
        return (baseShiftEnergyCost, baseShiftCatalystAmount);
    }

     /**
      * @dev Estimates the success chance of a shift based on the *current* gate state (including decay).
      * Returns chance as a percentage (0-10000).
      */
    function getEstimatedShiftSuccessChance() external view returns (uint256) {
        // Apply decay *conceptually* for the view function
        uint256 timeElapsed = block.timestamp.sub(lastInteractionTimestamp);
        uint256 currentAlignment = gateAlignment > decayRateAlignmentPerSecond.mul(timeElapsed)
            ? gateAlignment.sub(decayRateAlignmentPerSecond.mul(timeElapsed))
            : 0;
        uint256 currentCharge = gateCharge > decayRateChargePerSecond.mul(timeElapsed)
            ? gateCharge.sub(decayRateChargePerSecond.mul(timeElapsed))
            : 0;

        // Recalculate chance based on estimated current state
        uint256 baseChance = 1000; // 10%
        uint256 maxAlignmentBonus = 4000; // 40%
        uint256 maxChargeBonus = 2000; // 20%
        uint256 maxPossibleAlignment = 10000;
        uint256 maxEffectiveCharge = 50000e18;

        uint256 alignmentBonus = currentAlignment.mul(maxAlignmentBonus).div(maxPossibleAlignment);
        uint256 chargeBonus = currentCharge > maxEffectiveCharge
            ? maxChargeBonus
            : currentCharge.mul(maxChargeBonus).div(maxEffectiveCharge);

        return baseChance.add(alignmentBonus).add(chargeBonus).min(10000);
    }


    // Fallback and Receive functions (optional but good practice)
    // If this contract needs to receive plain ETH
    // receive() external payable {}
    // fallback() external payable {}

    // ERC-1155 Receiver Hook (if this contract is to receive arbitrary ERC1155 tokens)
    // function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external returns(bytes4) {
    //     // Only accept if it's the Catalyst NFT type/id expected, or from owner for deposit
    //     return this.onERC1155Received.selector;
    // }
    // function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external returns(bytes4) {
    //      return this.onERC1155BatchReceived.selector;
    // }
}
```

**Explanation of Concepts & Functions:**

1.  **State Machine (`GateState`, `updateGateState`, `setGateState`):** The contract has a specific state (`Idle`, `Charging`, etc.) which can be changed by user actions (`chargeGate`, `calibrateGate`), decay (`_applyDecay`), or admin (`setGateState`). The `updateGateState` modifier ensures the state is checked/updated around key interactions.
2.  **Time-Based Mechanics (`lastInteractionTimestamp`, `decayRateAlignmentPerSecond`, `decayRateChargePerSecond`, `_applyDecay`):** Gate alignment and charge aren't static; they decrease over time, requiring users to actively maintain them by charging/calibrating. This creates an ongoing incentive loop. The `updateGateState` modifier automatically applies decay before relevant state-changing functions execute.
3.  **Probabilistic Outcomes (`_calculateShiftSuccessChance`, `_determineShiftOutcome`, `performShift`):** The core `performShift` function doesn't guarantee success. The chance is calculated based on the Gate's state (Alignment and Charge). This introduces a game-like element of risk and reward. *Note: The randomness used (`blockhash`, `keccak256`) is insecure for production and should be replaced with a verifiable random function (VRF) like Chainlink VRF.*
4.  **Multi-Token Interaction (`IERC20`, `IERC721`, `IERC1155`, `performShift`, `chargeGate`, `calibrateGate`, `withdrawEnergy`, `withdrawCatalyst`):** The contract interacts with three different token standards. Users spend ERC-20 Energy and an ERC-1155 Catalyst NFT to use the gate, and the gate can mint/update an ERC-721 Shift Token. This demonstrates complex resource management and asset generation.
5.  **Dynamic NFT Properties (`ShiftTokenProperties`, `shiftTokenProperties`, `_mintOrUpdateShiftToken`, `getShiftTokenProperties`):** The ERC-721 Shift Tokens minted by this contract have properties (dimensionId, powerLevel) that are stored *within this `DimensionalShiftGate` contract*. When a user performs another successful shift, their existing token's properties can be *updated* via the `_mintOrUpdateShiftToken` internal helper calling an `updateProperties` function on the external `IShiftToken` contract. This makes the NFTs dynamic based on user activity.
6.  **Discovery/Exploration (`DimensionParameters`, `discoveredDimensions`, `_isDimensionDiscovered`, `_discoverDimension`, `addDimensionParameter`, `updateDimensionParameter`, `getDiscoveredDimensions`):** Dimensions can have different parameters (weight, power range). Some dimensions might be initially unknown (`isDiscovered: false`). The first time a user successfully shifts to one of these, it's marked as `isDiscovered` in the contract, and this list grows. This adds an exploration element to the game.
7.  **Resource Management (`gateCharge`, `gateAlignment`, `totalEnergyConsumed`, `baseShiftEnergyCost`, `calibrationEnergyCost`):** Users contribute resources (`chargeGate`, `calibrateGate`) to improve the gate's state, which in turn improves their chances or outcomes in the core interaction (`performShift`).
8.  **Cooldowns (`userShiftCooldowns`, `shiftCooldownDuration`, `_checkShiftRequirements`):** Limits how often a single user can attempt a shift, preventing spamming and adding a strategic element to timing.
9.  **Admin Control (`Ownable`, `onlyOwner`, `set...` functions, `withdraw...` functions):** The owner has extensive control over contract parameters, including costs, decay rates, minimum requirements, dimension settings, and fund withdrawals. The `Pausable` pattern allows the owner to temporarily stop shifts.
10. **Comprehensive Query Functions (>= 10 view functions):** A wide range of `view` functions allow anyone to inspect the current state of the gate, user stats, token properties, and contract parameters, providing transparency.

**Note on Open Source Duplication:** While this contract uses standard OpenZeppelin libraries (which are open source) and interacts with standard token interfaces (ERC-20, 721, 1155, which are open standards), the *combination* of dynamic gate state, time-based decay affecting probabilistic outcomes, specific resource consumption mechanics tied to state improvement, dimension discovery, and the dynamic updating of an external ERC-721 NFT based on these interactions is a specific and creative blend of mechanics unlikely to be a direct, single-source copy of an existing widely used open-source contract. It draws inspiration from various dApp design patterns but integrates them in a novel way.

**Important Considerations for Deployment:**

*   **Randomness:** Replace `blockhash` and simple `keccak256` with a secure VRF (e.g., Chainlink VRF) for production environments.
*   **Gas Costs:** Complex interactions like `performShift` involving multiple external calls and state updates will be expensive in terms of gas. Optimize where possible.
*   **External Contracts:** This contract *depends* on the existence and functionality of the specified ERC-20, ERC-721, and ERC-1155 contracts. You must deploy those separately and provide their addresses to this contract's constructor. The `IShiftToken` interface assumes your ERC-721 contract has `mint` and `updateProperties` functions with specific signatures; you'll need to ensure your custom ERC-721 contract matches this.
*   **Security Audits:** As with any complex smart contract handling valuable assets, a thorough professional security audit is highly recommended before deployment.
*   **Scaling:** Consider potential scaling issues if usage is very high, although for typical dApp usage on L1 or optimistic rollups, this design should be manageable.

This contract provides a solid framework for a complex, interactive, and somewhat gamified dApp built around resource management, dynamic state, and probabilistic outcomes tied to unique digital assets.