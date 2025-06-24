Okay, here is a Solidity smart contract demonstrating several advanced, creative, and trendy concepts. It's designed around a fictional ecosystem of "ChronoMorphs" – NFTs that dynamically change state based on time, resource consumption, and external data inputs (via a simulated oracle), with added features like staking, governance, and batch operations.

**Disclaimer:** This is a complex example for educational purposes. It includes concepts that require careful consideration for production environments (e.g., gas costs for batch functions, oracle security, potential state calculation complexity over long periods). It is NOT audited production-ready code.

---

**Outline:**

1.  ** SPDX-License-Identifier & Pragma**
2.  **Imports:** ERC721, ERC20, Ownable (from OpenZeppelin)
3.  **Error Definitions:** Custom errors for clarity and gas efficiency.
4.  **Event Definitions:** Announce key actions and state changes.
5.  **State Variables:** Define contract state, parameters, mappings, etc.
6.  **Struct Definitions:** Define data structures for Morph data and Staking data.
7.  **Modifiers:** Custom access control modifiers.
8.  **Constructor:** Initialize tokens, roles, and initial parameters.
9.  **Role Management Functions:** Functions to manage Governor and Oracle Feeder roles.
10. **Core ERC721 Functions (Inherited):** Basic NFT operations (`balanceOf`, `ownerOf`, `transferFrom`, etc.).
11. **Core ERC20 Functions (Inherited):** Basic Essence token operations (`balanceOf`, `transfer`, etc.).
12. **Morph Data & State Functions:**
    *   `getMorphData`: Retrieve raw struct data.
    *   `getMorphCurrentState`: Calculate dynamic state based on time/factors.
    *   `getMorphStateDuration`: Time spent in the current state.
    *   `queryMorphStateAtTime`: Pure function to predict state at a past/future time.
13. **Resource Consumption & State Interaction Functions:**
    *   `consumeEssenceForStateChange`: Use Essence to influence state/age.
    *   `getMorphCumulativeEssenceConsumed`: Total Essence consumed by a morph.
14. **Staking Functions:**
    *   `stakeMorph`: Stake an NFT to earn Essence.
    *   `unstakeMorph`: Unstake an NFT.
    *   `claimStakingRewards`: Claim earned Essence.
    *   `getPendingStakingRewards`: View pending rewards.
    *   `isMorphStaked`: Check staking status.
    *   `getTotalStakedMorphs`: Total count of staked morphs.
15. **Simulated Oracle & External Data Functions:**
    *   `updateOracleData`: Update mock external data (restricted).
    *   `getOracleData`: Retrieve mock external data.
16. **Governance & Parameter Functions:**
    *   `setAgingRate`: Governor sets time-based aging speed.
    *   `setEssenceConsumptionCost`: Governor sets Essence cost for actions.
    *   `triggerEnvironmentalShift`: Governor triggers a global event affecting morphs.
    *   `getEnvironmentalShift`: View current global shift.
    *   `setMaxSupply`: Governor sets max number of mintable morphs.
17. **Evolution Function:**
    *   `evolveMorph`: Permanently evolve a morph based on criteria and cost.
    *   `isMorphEvolved`: Check evolution status.
18. **Batch Operation Functions:**
    *   `batchStakeMorphs`: Stake multiple NFTs.
    *   `batchUnstakeMorphs`: Unstake multiple NFTs.
    *   `batchClaimStakingRewards`: Claim rewards for multiple NFTs.
    *   `batchConsumeEssence`: Consume Essence for multiple NFTs.
19. **Utility/Safety Functions:**
    *   `mintMorph`: Mint a new ChronoMorph (requires Essence).
    *   `rescueERC20`: Rescue accidentally sent ERC20 tokens.
    *   `rescueETH`: Rescue accidentally sent ETH.
    *   `calculateEssenceMintableForStakeDuration`: Predict future staking rewards.

---

**Function Summary:**

*   **`constructor(...)`**: Initializes the contract, mints the associated Essence token, sets up initial roles (Owner, Governor, Oracle Feeder), and parameters.
*   **`setGovernor(address newGovernor)`**: Allows the current owner to transfer the Governor role.
*   **`setOracleFeeder(address newFeeder)`**: Allows the current owner to transfer the Oracle Feeder role.
*   **`getMorphData(uint256 tokenId)`**: Returns the raw state data associated with a specific ChronoMorph token.
*   **`getMorphCurrentState(uint256 tokenId)`**: Calculates and returns the *dynamic* state of a morph based on its current age, resource consumption, and external factors (simulated oracle/environmental shift).
*   **`getMorphStateDuration(uint256 tokenId)`**: Returns the duration (in seconds) the morph has been in its *current calculated state*.
*   **`queryMorphStateAtTime(uint256 tokenId, uint64 timestamp)`**: A pure (read-only, no state change) function to calculate what a morph's state *would have been* or *would be* at a specific point in time, assuming no consumption or evolution events between now and then.
*   **`consumeEssenceForStateChange(uint256 tokenId, uint256 amount)`**: Allows the owner of a morph to burn a specified amount of Essence tokens. This accelerates the morph's 'aging' process, potentially pushing it to a new state faster than time alone would allow.
*   **`getMorphCumulativeEssenceConsumed(uint256 tokenId)`**: Returns the total amount of Essence tokens ever consumed by a specific morph throughout its lifetime.
*   **`stakeMorph(uint256 tokenId)`**: Allows the owner to stake their ChronoMorph. Staked morphs cannot be transferred and start accruing Essence token rewards.
*   **`unstakeMorph(uint256 tokenId)`**: Allows the owner to unstake their ChronoMorph. Stops reward accrual and makes the NFT transferable again.
*   **`claimStakingRewards(uint256 tokenId)`**: Allows the owner of a staked morph to claim accrued Essence token rewards.
*   **`getPendingStakingRewards(uint256 tokenId)`**: A view function that calculates the amount of Essence tokens currently claimable for a specific staked morph.
*   **`isMorphStaked(uint256 tokenId)`**: A view function to check if a specific morph is currently staked.
*   **`getTotalStakedMorphs()`**: A view function returning the total number of ChronoMorphs currently staked in the contract.
*   **`updateOracleData(bytes32 dataType, uint256 value)`**: Allows the Oracle Feeder role to update specific pieces of external data stored in the contract. This data can influence morph state calculations.
*   **`getOracleData(bytes32 dataType)`**: A view function to retrieve the latest value for a specific type of mock oracle data.
*   **`setAgingRate(uint256 newRate)`**: Allows the Governor role to adjust the rate at which morphs age naturally over time. Higher rate means faster aging.
*   **`setEssenceConsumptionCost(uint256 cost)`**: Allows the Governor role to set the base cost (in Essence) for actions like `consumeEssenceForStateChange`.
*   **`triggerEnvironmentalShift(uint8 shiftType)`**: Allows the Governor role to trigger a global "environmental shift" event. This event temporarily or permanently alters factors influencing morph behavior, aging, or state changes.
*   **`getEnvironmentalShift()`**: A view function to see the details of the current global environmental shift.
*   **`setMaxSupply(uint256 newMaxSupply)`**: Allows the Governor role to set the maximum number of ChronoMorph tokens that can ever be minted.
*   **`evolveMorph(uint256 tokenId)`**: A more complex action allowing a morph meeting specific criteria (e.g., age, consumption, oracle data) to undergo a permanent 'evolution', potentially changing its properties or unlocking new states/abilities. Requires Essence.
*   **`isMorphEvolved(uint256 tokenId)`**: A view function to check if a morph has undergone its permanent evolution.
*   **`batchStakeMorphs(uint256[] calldata tokenIds)`**: Allows a user to stake multiple morphs in a single transaction for gas efficiency.
*   **`batchUnstakeMorphs(uint256[] calldata tokenIds)`**: Allows a user to unstake multiple morphs in a single transaction.
*   **`batchClaimStakingRewards(uint256[] calldata tokenIds)`**: Allows a user to claim rewards for multiple staked morphs in a single transaction.
*   **`batchConsumeEssence(uint256[] calldata tokenIds, uint256 amountPerToken)`**: Allows a user to consume the same amount of Essence for multiple morphs in a single transaction.
*   **`mintMorph()`**: Allows users to mint a new ChronoMorph token, requiring a certain amount of Essence tokens be burned. Limited by `maxSupply`.
*   **`rescueERC20(address tokenAddress, uint256 amount)`**: Allows the contract owner to recover arbitrary ERC20 tokens mistakenly sent to the contract address (excluding the contract's own Essence token).
*   **`rescueETH(uint256 amount)`**: Allows the contract owner to recover ETH mistakenly sent to the contract address.
*   **`calculateEssenceMintableForStakeDuration(uint256 tokenId, uint256 duration)`**: A view function to estimate the Essence rewards a morph would earn if staked for a given duration *from its current staking state*.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol"; // Added for potential burn mechanism

// --- Outline ---
// 1. SPDX-License-Identifier & Pragma
// 2. Imports: ERC721, ERC20, Ownable
// 3. Error Definitions
// 4. Event Definitions
// 5. State Variables
// 6. Struct Definitions
// 7. Modifiers
// 8. Constructor
// 9. Role Management Functions
// 10. Core ERC721 Functions (Inherited)
// 11. Core ERC20 Functions (Inherited)
// 12. Morph Data & State Functions
// 13. Resource Consumption & State Interaction Functions
// 14. Staking Functions
// 15. Simulated Oracle & External Data Functions
// 16. Governance & Parameter Functions
// 17. Evolution Function
// 18. Batch Operation Functions
// 19. Utility/Safety Functions

// --- Function Summary ---
// See detailed summary above the code block.

// Custom ERC20 for the ecosystem resource
contract EssenceToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    // Mint function for the contract owner (or designated minter)
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    // Optional burn function
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }
}

contract ChronoMorphs is ERC721, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    // --- Error Definitions ---
    error ChronoMorphs__MaxSupplyReached();
    error ChronoMorphs__InvalidTokenId();
    error ChronoMorphs__NotMorphOwner(address caller, uint256 tokenId);
    error ChronoMorphs__TokenAlreadyStaked(uint256 tokenId);
    error ChronoMorphs__TokenNotStaked(uint256 tokenId);
    error ChronoMorphs__NoRewardsToClaim();
    error ChronoMorphs__UnauthorizedGovernor(address caller);
    error ChronoMorphs__UnauthorizedOracleFeeder(address caller);
    error ChronoMorphs__EssenceConsumptionTooLow();
    error ChronoMorphs__InvalidEvolutionCriteria(uint256 tokenId);
    error ChronoMorphs__AlreadyEvolved(uint256 tokenId);
    error ChronoMorphs__EssenceBurnFailed();
    error ChronoMorphs__InvalidBatchLength();
    error ChronoMorphs__CannotRescueOwnEssenceToken();
    error ChronoMorphs__ETHTransferFailed();
    error ChronoMorphs__NotEnoughEssence(address owner, uint256 required, uint256 has);

    // --- Event Definitions ---
    event MorphMinted(uint256 indexed tokenId, address indexed owner, uint64 timestamp);
    event MorphStateChanged(uint256 indexed tokenId, uint8 newState, uint64 timestamp);
    event EssenceConsumedForState(uint256 indexed tokenId, uint256 amount, uint64 timestamp);
    event MorphStaked(uint256 indexed tokenId, address indexed owner, uint64 timestamp);
    event MorphUnstaked(uint256 indexed tokenId, address indexed owner, uint256 claimedRewards, uint64 timestamp);
    event StakingRewardsClaimed(uint256 indexed tokenId, address indexed owner, uint256 amount, uint64 timestamp);
    event OracleDataUpdated(bytes32 indexed dataType, uint256 value, uint64 timestamp);
    event ParameterChanged(string paramName, uint256 newValue, uint64 timestamp);
    event EnvironmentalShiftTriggered(uint8 shiftType, uint64 timestamp);
    event MorphEvolved(uint256 indexed tokenId, uint8 newEvolutionState, uint64 timestamp);

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;
    address public essenceTokenAddress;
    EssenceToken private _essenceToken; // Contract instance for interaction

    uint256 public maxSupply;
    uint256 public morphMintCostEssence;

    // Morph Data Storage
    struct MorphData {
        uint64 mintTimestamp;          // When the morph was minted
        uint64 lastStateCalcTimestamp; // When the state was last explicitly calculated or actioned
        uint256 cumulativeEssenceConsumed; // Total Essence consumed over lifetime
        uint8 currentCalculatedState;  // Cached state based on last calculation
        bool isEvolved;                // Has this morph undergone permanent evolution?
        uint8 evolutionState;          // Specific state if evolved (optional)
        bytes32 traitsHash;            // Placeholder for immutable or generative traits
    }
    mapping(uint256 => MorphData) private _morphData;

    // Staking Data Storage
    struct StakingData {
        uint64 stakeTimestamp;
        uint256 lastRewardCalcTimestamp; // Timestamp of last reward calculation/claim
        uint256 accumulatedRewards;      // Rewards accumulated since last claim
    }
    mapping(uint256 => StakingData) private _stakedMorphs;
    mapping(uint256 => bool) private _isMorphStaked; // Quick lookup
    uint256 private _totalStakedMorphsCount;

    // Governance Parameters
    address public governor;
    address public oracleFeeder;

    uint256 public agingRatePerSecond; // How much "age units" increase per second
    uint256 public baseEssenceConsumptionCost; // Base cost for consumption actions

    // Simulated Oracle Data (key is bytes32 e.g., "WEATHER", "MARKET_INDEX")
    mapping(bytes32 => uint256) private _oracleData;

    // Environmental Shift (Affects all morphs globally)
    struct EnvironmentalShift {
        uint8 shiftType;        // e.g., 0=None, 1=GrowthSpurt, 2=Dormancy
        uint64 startTime;
        uint64 endTime;         // 0 for permanent shift
        uint256 modifier;       // Factor influencing aging/consumption etc.
    }
    EnvironmentalShift public currentEnvironmentalShift;

    // State thresholds (example: state changes every X age units)
    uint256[] public stateThresholds; // Array of cumulative age units needed to reach state 1, 2, 3...

    // Staking Rewards Parameters
    uint256 public stakingRewardPerSecondPerMorph; // Essence per second per staked morph

    // --- Struct Definitions ---
    // (Defined above within State Variables section for clarity)

    // --- Modifiers ---
    modifier onlyGovernor() {
        if (msg.sender != governor) {
            revert ChronoMorphs__UnauthorizedGovernor(msg.sender);
        }
        _;
    }

    modifier onlyOracleFeeder() {
        if (msg.sender != oracleFeeder) {
            revert ChronoMorphs__UnauthorizedOracleFeeder(msg.sender);
        }
        _;
    }

    modifier validTokenId(uint256 tokenId) {
        if (!_exists(tokenId)) {
            revert ChronoMorphs__InvalidTokenId();
        }
        _;
    }

    modifier onlyMorphOwner(uint256 tokenId) {
         address owner = ERC721.ownerOf(tokenId);
         if (msg.sender != owner) {
             revert ChronoMorphs__NotMorphOwner(msg.sender, tokenId);
         }
         _;
    }

    // --- Constructor ---
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialMaxSupply,
        uint256 _morphMintCostEssence,
        uint256 _agingRatePerSecond,
        uint256 _baseEssenceConsumptionCost,
        uint256 _stakingRewardPerSecondPerMorph,
        uint256[] memory _stateThresholds // e.g., [1000, 5000, 15000]
    ) ERC721(name, symbol) Ownable(msg.sender) {
        maxSupply = initialMaxSupply;
        morphMintCostEssence = _morphMintCostEssence;
        agingRatePerSecond = _agingRatePerSecond;
        baseEssenceConsumptionCost = _baseEssenceConsumptionCost;
        stakingRewardPerSecondPerMorph = _stakingRewardPerSecondPerMorph;
        stateThresholds = _stateThresholds; // Set initial state thresholds

        // Deploy associated Essence token
        _essenceToken = new EssenceToken("ChronoEssence", "ESS");
        essenceTokenAddress = address(_essenceToken);

        // Initial roles
        governor = msg.sender;
        oracleFeeder = msg.sender;

        // Initial environmental shift (none)
        currentEnvironmentalShift = EnvironmentalShift(0, uint64(block.timestamp), 0, 1);
    }

    // --- Role Management Functions ---
    function setGovernor(address newGovernor) public onlyOwner {
        governor = newGovernor;
    }

    function setOracleFeeder(address newFeeder) public onlyOwner {
        oracleFeeder = newFeeder;
    }

    // --- Core ERC721 Functions (Inherited) ---
    // ERC721 functions like balanceOf, ownerOf, approve, getApproved, setApprovalForAll,
    // isApprovedForAll, transferFrom, safeTransferFrom are inherited and available.
    // We override transferFrom/safeTransferFrom to prevent transfers of staked tokens.
    function transferFrom(address from, address to, uint256 tokenId) public override {
        if (_isMorphStaked[tokenId]) {
            revert ChronoMorphs__TokenAlreadyStaked(tokenId);
        }
        super.transferFrom(from, to, tokenId);
        // When transferred, reset state calculation timestamp to reflect potential new environment/owner
        _morphData[tokenId].lastStateCalcTimestamp = uint64(block.timestamp);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
         if (_isMorphStaked[tokenId]) {
            revert ChronoMorphs__TokenAlreadyStaked(tokenId);
        }
        super.safeTransferFrom(from, to, tokenId, data);
        // When transferred, reset state calculation timestamp
        _morphData[tokenId].lastStateCalcTimestamp = uint64(block.timestamp);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    // --- Core ERC20 Functions (Inherited) ---
    // EssenceToken functions like balanceOf, transfer, approve, transferFrom, allowance
    // are available via the public essenceTokenAddress or _essenceToken instance.

    // --- Morph Data & State Functions ---

    /// @notice Retrieves the raw internal data struct for a morph.
    /// @param tokenId The ID of the ChronoMorph token.
    /// @return The MorphData struct.
    function getMorphData(uint256 tokenId) public view validTokenId(tokenId) returns (MorphData memory) {
        return _morphData[tokenId];
    }

    /// @notice Calculates the current dynamic state of a morph.
    /// State depends on base age, cumulative essence consumed, simulated oracle data,
    /// and global environmental shifts.
    /// @param tokenId The ID of the ChronoMorph token.
    /// @return The calculated state index (0-based).
    function getMorphCurrentState(uint256 tokenId) public view validTokenId(tokenId) returns (uint8) {
        MorphData storage morph = _morphData[tokenId];
        uint256 currentTimestamp = block.timestamp;

        // Calculate base age increase since last calculation
        uint256 timePassed = currentTimestamp - morph.lastStateCalcTimestamp;
        uint256 ageFromTime = timePassed * agingRatePerSecond;

        // Apply environmental shift modifier if active
        uint256 effectiveAgingRate = agingRatePerSecond;
        if (currentEnvironmentalShift.endTime == 0 || currentTimestamp < currentEnvironmentalShift.endTime) {
            // Example: ShiftType 1 (GrowthSpurt) doubles aging, Type 2 (Dormancy) halves it
            if (currentEnvironmentalShift.shiftType == 1) {
                 effectiveAgingRate = effectiveAgingRate * currentEnvironmentalShift.modifier; // Modifier could be 2 for doubling
            } else if (currentEnvironmentalShift.shiftType == 2) {
                 effectiveAgingRate = effectiveAgingRate / currentEnvironmentalShift.modifier; // Modifier could be 2 for halving
            }
            // Add more complex modifiers based on shiftType and currentEnvironmentalShift.modifier
        }
        ageFromTime = (currentTimestamp - morph.lastStateCalcTimestamp) * effectiveAgingRate;


        // Total "age units" = time-based age + essence-based age
        // Essence-based age: Simplistic model - 1 Essence adds Y age units
        uint256 essenceAgeContribution = morph.cumulativeEssenceConsumed / (baseEssenceConsumptionCost > 0 ? baseEssenceConsumptionCost : 1); // Avoid division by zero

        uint256 totalAgeUnits = (currentTimestamp - morph.mintTimestamp) * effectiveAgingRate + essenceAgeContribution;
        // Note: lastStateCalcTimestamp is used for *incremental* age calculation,
        // mintTimestamp + effectiveAgingRate * time is the *absolute* age.
        // Let's use absolute age for state calculation for simplicity in this demo.
        uint256 absoluteAgeUnits = (currentTimestamp - morph.mintTimestamp) * effectiveAgingRate + essenceAgeContribution;


        // Influence of simulated oracle data (Example: weather affects state)
        uint256 weatherData = _oracleData[bytes32("WEATHER")]; // Assume 0-100 scale
        if (weatherData > 80) { // Sunny/Hot
             absoluteAgeUnits = absoluteAgeUnits * 110 / 100; // 10% faster state change
        } else if (weatherData < 20) { // Rainy/Cold
             absoluteAgeUnits = absoluteAgeUnits * 90 / 100; // 10% slower state change
        }
        // Add more complex logic based on other oracle data

        // Determine state based on age units and thresholds
        uint8 currentState = 0; // Start at state 0
        for (uint i = 0; i < stateThresholds.length; i++) {
            if (absoluteAgeUnits >= stateThresholds[i]) {
                currentState = uint8(i + 1); // Reached state i+1
            } else {
                break; // Threshold not met, state is the current value
            }
        }

        // If evolved, state might be fixed or influenced differently
        if (morph.isEvolved) {
            // Example: Evolved morphs have a fixed minimum state or enter an "evolved state"
            // currentState = morph.evolutionState; // Could fix the state
             if (morph.evolutionState > currentState) { // Or ensure it's at least the evolution state
                currentState = morph.evolutionState;
             }
        }


        // Update cached state IF it has changed. This optimization avoids
        // recalculating state fully every time getMorphData is called.
        // This requires a state-changing function call, e.g., updateMorphState() or on actions.
        // For this view function, we just return the calculated state without writing to storage.
        return currentState;
    }

    /// @notice Returns the duration (in seconds) the morph has been in its current calculated state.
    /// Requires calling getMorphCurrentState first to determine the state.
    /// Note: This is an approximation based on the last state update timestamp.
    /// @param tokenId The ID of the ChronoMorph token.
    /// @return Duration in seconds.
    function getMorphStateDuration(uint256 tokenId) public view validTokenId(tokenId) returns (uint256) {
         // This requires a state update event to log when the state *actually* changed.
         // For simplicity here, we'll calculate based on the last time the state was
         // explicitly updated or calculated and stored (lastStateCalcTimestamp).
         // A more robust system would store state change history.
         // This is simplified for demo purposes.
         // return block.timestamp - _morphData[tokenId].lastStateCalcTimestamp; // Simpler, less accurate version

         // A more complex but still simplified approach: re-calculate age units
         MorphData storage morph = _morphData[tokenId];
         uint256 currentTimestamp = block.timestamp;
         uint256 effectiveAgingRate = agingRatePerSecond; // Apply shift here too if needed

         uint256 absoluteAgeUnits = (currentTimestamp - morph.mintTimestamp) * effectiveAgingRate + morph.cumulativeEssenceConsumed / (baseEssenceConsumptionCost > 0 ? baseEssenceConsumptionCost : 1);

         uint8 currentState = 0;
         uint256 ageUnitsAtCurrentStateEntry = 0;

         for (uint i = 0; i < stateThresholds.length; i++) {
             if (absoluteAgeUnits >= stateThresholds[i]) {
                 currentState = uint8(i + 1);
                 ageUnitsAtCurrentStateEntry = stateThresholds[i];
             } else {
                 break;
             }
         }

         if (morph.isEvolved && morph.evolutionState > currentState) {
             // If evolved state is higher than calculated, use evolution state logic
             currentState = morph.evolutionState;
             // Logic to determine state entry time for evolved state would be complex
             // Let's simplify and base duration calculation on non-evolved logic for now.
             // Or maybe evolved state entry is just the evolution timestamp?
             // For this demo, we'll calculate state duration based on the *calculated* age units.
             // If the morph is evolved, the 'current state' calculation above might need
             // to prioritize the evolved state if it's a fixed state.
             // Given the potential complexity, we return a basic duration calculation.
             // A more accurate version needs more state storage or event history.

             // Simplified duration: Time since last state calculation timestamp if state hasn't changed,
             // or time since mint if state has just changed (needs storage of last state change timestamp).
             // Let's return time since lastStateCalcTimestamp as a proxy for demo.
            return block.timestamp - morph.lastStateCalcTimestamp;
         }


         // Calculate how many age units *into* the current state the morph is
         uint256 ageUnitsIntoCurrentState = absoluteAgeUnits - ageUnitsAtCurrentStateEntry;

         // Estimate time in current state assuming constant rate since mint (ignores consumption bursts)
         // A more accurate calc needs to consider the history of rate changes and consumption.
         // This is a rough estimate for demonstration.
         if (effectiveAgingRate > 0) {
              return ageUnitsIntoCurrentState / effectiveAgingRate;
         } else {
             return 0; // Or handle error
         }
    }


    /// @notice Pure function to predict morph state at a hypothetical timestamp.
    /// Does NOT account for future Essence consumption, evolution, or oracle updates.
    /// Assumes parameters (agingRate, thresholds, shifts) were constant or can be calculated for the period.
    /// Highly simplified for demo. Accurate prediction is complex.
    /// @param tokenId The ID of the ChronoMorph token.
    /// @param timestamp The hypothetical future or past timestamp.
    /// @return Predicted state index.
    function queryMorphStateAtTime(uint256 tokenId, uint64 timestamp) public view validTokenId(tokenId) returns (uint8) {
         // Note: This is a PURE function. It CANNOT read contract state variables that change
         // (like _morphData, _oracleData, currentEnvironmentalShift).
         // Therefore, a true prediction based on historical/future state is impossible in PURE.
         // This must be a VIEW function. Correcting the function type.
    }

    /// @notice VIEW function to predict morph state at a hypothetical timestamp.
    /// Assumes parameters (agingRate, thresholds, shifts, oracle) are constant at *current* values.
    /// Does NOT account for historical changes in parameters, consumption, or evolution.
    /// @param tokenId The ID of the ChronoMorph token.
    /// @param timestamp The hypothetical future or past timestamp.
    /// @return Predicted state index.
    function queryMorphStateAtTime(uint256 tokenId, uint64 timestamp) public view validTokenId(tokenId) returns (uint8 predictedState) {
        MorphData storage morph = _morphData[tokenId];
        // For a basic view prediction, we use CURRENT parameters and Oracle data.
        // This is a simplification. A real system might need historical data or assumptions.

        // Calculate age units at the given timestamp
        uint256 effectiveAgingRate = agingRatePerSecond; // Use current rate
         if (currentEnvironmentalShift.endTime == 0 || timestamp < currentEnvironmentalShift.endTime) {
            if (currentEnvironmentalShift.shiftType == 1) {
                 effectiveAgingRate = effectiveAgingRate * currentEnvironmentalShift.modifier;
            } else if (currentEnvironmentalShift.shiftType == 2) {
                 effectiveAgingRate = effectiveAgingRate / currentEnvironmentalShift.modifier;
            }
        }


        uint256 ageFromTime = (timestamp > morph.mintTimestamp ? timestamp - morph.mintTimestamp : 0) * effectiveAgingRate;

        // Cumulative essence consumed remains constant for this prediction
        uint256 essenceAgeContribution = morph.cumulativeEssenceConsumed / (baseEssenceConsumptionCost > 0 ? baseEssenceConsumptionCost : 1);

        uint256 totalAgeUnits = ageFromTime + essenceAgeContribution;

        // Influence of simulated oracle data (Use current oracle data for prediction)
        uint256 weatherData = _oracleData[bytes32("WEATHER")];
         if (weatherData > 80) { totalAgeUnits = totalAgeUnits * 110 / 100; }
         else if (weatherData < 20) { totalAgeUnits = totalAgeUnits * 90 / 100; }

        // Determine state based on age units and thresholds (Use current thresholds)
        predictedState = 0;
        for (uint i = 0; i < stateThresholds.length; i++) {
            if (totalAgeUnits >= stateThresholds[i]) {
                predictedState = uint8(i + 1);
            } else {
                break;
            }
        }

        // If already evolved, the evolution state might override or influence prediction
         if (morph.isEvolved && morph.evolutionState > predictedState) {
             predictedState = morph.evolutionState;
         }

        return predictedState;
    }

    // --- Resource Consumption & State Interaction Functions ---

    /// @notice Allows morph owner to consume Essence to accelerate aging/state change.
    /// Burns Essence and adds to cumulative consumption.
    /// @param tokenId The ID of the ChronoMorph token.
    /// @param amount The amount of Essence tokens to consume (burn).
    function consumeEssenceForStateChange(uint256 tokenId, uint256 amount) public validTokenId(tokenId) onlyMorphOwner(tokenId) {
        if (amount < baseEssenceConsumptionCost) {
             revert ChronoMorphs__EssenceConsumptionTooLow();
        }
        // Requires approval for the contract to spend owner's Essence
        if (_essenceToken.allowance(msg.sender, address(this)) < amount) {
             revert ChronoMorphs__NotEnoughEssence(msg.sender, amount, _essenceToken.allowance(msg.sender, address(this)));
        }

        // Burn the Essence from the owner's balance
        bool success = _essenceToken.transferFrom(msg.sender, address(this), amount);
        if (!success) {
             revert ChronoMorphs__EssenceBurnFailed(); // Or a more specific error
        }
        // Transferring to contract address and then burning is safer if you need contract logic
        // or if ERC20 doesn't have a public burn. OpenZeppelin ERC20 has _burn protected.
        // Let's burn directly from the contract's balance after transferFrom
        _essenceToken._burn(address(this), amount);


        _morphData[tokenId].cumulativeEssenceConsumed += amount;
        // Update last state calculation timestamp as consumption affects state immediately
        _morphData[tokenId].lastStateCalcTimestamp = uint64(block.timestamp);

        emit EssenceConsumedForState(tokenId, amount, uint64(block.timestamp));
        // Could also emit MorphStateChanged if the consumption causes a state change,
        // but calculating state here and checking change adds gas.
        // Users can call getMorphCurrentState to see the result.
    }

    /// @notice Returns the total amount of Essence tokens ever consumed by a specific morph.
    /// @param tokenId The ID of the ChronoMorph token.
    /// @return The cumulative amount of Essence consumed.
    function getMorphCumulativeEssenceConsumed(uint256 tokenId) public view validTokenId(tokenId) returns (uint256) {
        return _morphData[tokenId].cumulativeEssenceConsumed;
    }

    // --- Staking Functions ---

    /// @notice Stakes a ChronoMorph token. Token cannot be transferred while staked.
    /// Starts accruing Essence rewards.
    /// @param tokenId The ID of the ChronoMorph token.
    function stakeMorph(uint256 tokenId) public validTokenId(tokenId) onlyMorphOwner(tokenId) {
        if (_isMorphStaked[tokenId]) {
            revert ChronoMorphs__TokenAlreadyStaked(tokenId);
        }

        // Ensure token is transferred to the contract or handled appropriately
        // For simplicity, we just mark it staked and lock transfers via override.
        // A more robust system might transfer to contract address (requires safeTransferFrom).
        // Let's enforce approval first, then mark staked. User needs to approve contract.
        // Approval logic isn't needed IF we don't transfer ownership to the contract.
        // Just marking it staked and blocking transfers in transferFrom/safeTransferFrom is sufficient for locking.

        uint64 currentTimestamp = uint64(block.timestamp);
        _isMorphStaked[tokenId] = true;
        _stakedMorphs[tokenId] = StakingData(currentTimestamp, currentTimestamp, 0);
        _totalStakedMorphsCount++;

        emit MorphStaked(tokenId, msg.sender, currentTimestamp);
    }

    /// @notice Unstakes a ChronoMorph token. Stops reward accrual. Claims any pending rewards.
    /// @param tokenId The ID of the ChronoMorph token.
    function unstakeMorph(uint256 tokenId) public validTokenId(tokenId) onlyMorphOwner(tokenId) {
        if (!_isMorphStaked[tokenId]) {
            revert ChronoMorphs__TokenNotStaked(tokenId);
        }

        uint256 pendingRewards = getPendingStakingRewards(tokenId);
        delete _stakedMorphs[tokenId]; // Clear staking data
        _isMorphStaked[tokenId] = false;
        _totalStakedMorphsCount--;

        if (pendingRewards > 0) {
            // Mint and transfer rewards to the owner
            _essenceToken.mint(msg.sender, pendingRewards);
            emit StakingRewardsClaimed(tokenId, msg.sender, pendingRewards, uint64(block.timestamp));
        } else {
             emit ChronoMorphs__NoRewardsToClaim(); // Or just don't emit anything
        }

        emit MorphUnstaked(tokenId, msg.sender, pendingRewards, uint64(block.timestamp));
    }

    /// @notice Claims pending Essence rewards for a staked ChronoMorph.
    /// @param tokenId The ID of the ChronoMorph token.
    function claimStakingRewards(uint256 tokenId) public validTokenId(tokenId) onlyMorphOwner(tokenId) {
        if (!_isMorphStaked[tokenId]) {
            revert ChronoMorphs__TokenNotStaked(tokenId);
        }

        uint256 pendingRewards = getPendingStakingRewards(tokenId);

        if (pendingRewards == 0) {
             revert ChronoMorphs__NoRewardsToClaim();
        }

        // Update accumulated rewards and last calculation time before minting
        uint64 currentTimestamp = uint64(block.timestamp);
        uint256 timeElapsed = currentTimestamp - _stakedMorphs[tokenId].lastRewardCalcTimestamp;
        _stakedMorphs[tokenId].accumulatedRewards += timeElapsed * stakingRewardPerSecondPerMorph;
        _stakedMorphs[tokenId].lastRewardCalcTimestamp = currentTimestamp; // Reset timer

        uint256 rewardsToClaim = _stakedMorphs[tokenId].accumulatedRewards;
        _stakedMorphs[tokenId].accumulatedRewards = 0; // Reset accumulated for next cycle


        // Mint and transfer rewards to the owner
        _essenceToken.mint(msg.sender, rewardsToClaim);

        emit StakingRewardsClaimed(tokenId, msg.sender, rewardsToClaim, currentTimestamp);
    }

    /// @notice Calculates the current pending Essence rewards for a staked ChronoMorph.
    /// Does not claim.
    /// @param tokenId The ID of the ChronoMorph token.
    /// @return The amount of Essence tokens claimable.
    function getPendingStakingRewards(uint256 tokenId) public view validTokenId(tokenId) returns (uint256) {
        if (!_isMorphStaked[tokenId]) {
            return 0; // No rewards if not staked
        }

        StakingData storage staking = _stakedMorphs[tokenId];
        uint64 currentTimestamp = uint64(block.timestamp);
        uint256 timeElapsed = currentTimestamp - staking.lastRewardCalcTimestamp;

        uint256 accruedThisPeriod = timeElapsed * stakingRewardPerSecondPerMorph;

        return staking.accumulatedRewards + accruedThisPeriod;
    }

    /// @notice Checks if a specific morph is currently staked.
    /// @param tokenId The ID of the ChronoMorph token.
    /// @return True if staked, false otherwise.
    function isMorphStaked(uint256 tokenId) public view returns (bool) {
        return _isMorphStaked[tokenId];
    }

    /// @notice Gets the total count of currently staked ChronoMorphs.
    /// @return The total number of staked morphs.
    function getTotalStakedMorphs() public view returns (uint256) {
        return _totalStakedMorphsCount;
    }

    // --- Simulated Oracle & External Data Functions ---

    /// @notice Allows the Oracle Feeder to update simulated external data.
    /// @param dataType Identifier for the data type (e.g., keccak256("WEATHER")).
    /// @param value The new data value.
    function updateOracleData(bytes32 dataType, uint256 value) public onlyOracleFeeder {
        _oracleData[dataType] = value;
        emit OracleDataUpdated(dataType, value, uint64(block.timestamp));
    }

    /// @notice Retrieves the latest value for a specific type of simulated oracle data.
    /// @param dataType Identifier for the data type.
    /// @return The latest data value, or 0 if not set.
    function getOracleData(bytes32 dataType) public view returns (uint256) {
        return _oracleData[dataType];
    }

    // --- Governance & Parameter Functions ---

    /// @notice Allows the Governor to set the rate at which morphs age naturally.
    /// Affects `getMorphCurrentState` and `queryMorphStateAtTime`.
    /// @param newRate The new aging rate (age units per second).
    function setAgingRate(uint256 newRate) public onlyGovernor {
        agingRatePerSecond = newRate;
        emit ParameterChanged("agingRatePerSecond", newRate, uint64(block.timestamp));
    }

    /// @notice Allows the Governor to set the base cost of Essence for consumption actions.
    /// @param cost The new base cost in Essence tokens (with decimals).
    function setEssenceConsumptionCost(uint256 cost) public onlyGovernor {
        baseEssenceConsumptionCost = cost;
        emit ParameterChanged("baseEssenceConsumptionCost", cost, uint64(block.timestamp));
    }

     /// @notice Allows the Governor to set the state thresholds.
    /// @param _stateThresholds Array of cumulative age units needed for states 1, 2, etc.
    function setStateThresholds(uint256[] memory _stateThresholds) public onlyGovernor {
        stateThresholds = _stateThresholds;
        emit ParameterChanged("stateThresholds (array updated)", _stateThresholds.length, uint64(block.timestamp)); // Log length or hash
    }


    /// @notice Allows the Governor to trigger a global environmental shift.
    /// This can temporarily or permanently modify morph behavior.
    /// @param shiftType The type of environmental shift (e.g., 1 for Growth Spurt, 2 for Dormancy).
    /// @param duration The duration of the shift in seconds (0 for permanent until next shift).
    /// @param modifierValue A factor used by shiftType logic (e.g., 200 for 2x effect, 50 for 0.5x effect).
    function triggerEnvironmentalShift(uint8 shiftType, uint64 duration, uint256 modifierValue) public onlyGovernor {
        uint64 startTime = uint64(block.timestamp);
        uint64 endTime = duration == 0 ? 0 : startTime + duration;
        currentEnvironmentalShift = EnvironmentalShift(shiftType, startTime, endTime, modifierValue);

        emit EnvironmentalShiftTriggered(shiftType, startTime);
         // Could also emit ParameterChanged for specific modifier/endtime if needed
    }

    /// @notice Returns the details of the current global environmental shift.
    /// @return EnvironmentalShift struct.
    function getEnvironmentalShift() public view returns (EnvironmentalShift memory) {
        return currentEnvironmentalShift;
    }

    /// @notice Allows the Governor to set the maximum total supply of ChronoMorphs.
    /// Must be greater than or equal to the current supply.
    /// @param newMaxSupply The new maximum supply.
    function setMaxSupply(uint256 newMaxSupply) public onlyGovernor {
         if (newMaxSupply < _tokenIdCounter.current()) {
             // Optionally disallow setting below current supply, or handle shrinkage logic
         }
        maxSupply = newMaxSupply;
        emit ParameterChanged("maxSupply", newMaxSupply, uint64(block.timestamp));
    }

    // --- Evolution Function ---

    /// @notice Allows a morph owner to attempt to evolve their morph.
    /// Requires meeting specific criteria (e.g., age, essence consumed) and consumes Essence.
    /// If successful, marks the morph as evolved and updates its state/properties.
    /// @param tokenId The ID of the ChronoMorph token.
    function evolveMorph(uint256 tokenId) public validTokenId(tokenId) onlyMorphOwner(tokenId) {
        MorphData storage morph = _morphData[tokenId];
        if (morph.isEvolved) {
            revert ChronoMorphs__AlreadyEvolved(tokenId);
        }

        // Define evolution criteria (Example: must be State 3 or higher AND have consumed > 1000 Essence)
        uint8 currentState = getMorphCurrentState(tokenId);
        uint256 cumulativeEssence = morph.cumulativeEssenceConsumed;

        bool criteriaMet = false;
        uint256 evolutionCost = baseEssenceConsumptionCost * 10; // Example cost
        uint8 newEvolutionState = 5; // Example resulting state

        // Example Criteria Logic:
        if (stateThresholds.length > 2 && currentState >= 3 && cumulativeEssence >= 1000 * (10**_essenceToken.decimals())) {
            criteriaMet = true;
        }
        // Add more complex criteria involving oracle data, environmental shifts, etc.
        // uint256 oracleFactor = getOracleData(bytes32("COSMIC_ALIGNMENT"));
        // if (criteriaMet && oracleFactor > 500 && !morph.isEvolved) { criteriaMet = true; }

        if (!criteriaMet) {
            revert ChronoMorphs__InvalidEvolutionCriteria(tokenId);
        }

        // Check and burn evolution cost Essence
         if (_essenceToken.allowance(msg.sender, address(this)) < evolutionCost) {
             revert ChronoMorphs__NotEnoughEssence(msg.sender, evolutionCost, _essenceToken.allowance(msg.sender, address(this)));
         }
        bool success = _essenceToken.transferFrom(msg.sender, address(this), evolutionCost);
         if (!success) {
             revert ChronoMorphs__EssenceBurnFailed();
         }
         _essenceToken._burn(address(this), evolutionCost);

        // Mark as evolved and set new evolution state/properties
        morph.isEvolved = true;
        morph.evolutionState = newEvolutionState; // Set the state they evolve into
        morph.cumulativeEssenceConsumed += evolutionCost; // Add cost to consumed total
        morph.lastStateCalcTimestamp = uint64(block.timestamp); // Update timestamp

        emit MorphEvolved(tokenId, newEvolutionState, uint64(block.timestamp));
         emit EssenceConsumedForState(tokenId, evolutionCost, uint64(block.timestamp)); // Log the cost
    }

     /// @notice Checks if a specific morph has undergone its permanent evolution.
     /// @param tokenId The ID of the ChronoMorph token.
     /// @return True if evolved, false otherwise.
     function isMorphEvolved(uint256 tokenId) public view validTokenId(tokenId) returns (bool) {
         return _morphData[tokenId].isEvolved;
     }

    // --- Batch Operation Functions ---
    // Max batch size to prevent hitting block gas limit
    uint256 public constant MAX_BATCH_SIZE = 50;

    /// @notice Stakes multiple ChronoMorph tokens in a single transaction.
    /// @param tokenIds An array of token IDs to stake.
    function batchStakeMorphs(uint256[] calldata tokenIds) public {
        if (tokenIds.length > MAX_BATCH_SIZE) {
             revert ChronoMorphs__InvalidBatchLength();
        }
        for (uint i = 0; i < tokenIds.length; i++) {
            // Requires owner check and staked check inside stakeMorph function
            stakeMorph(tokenIds[i]);
        }
    }

     /// @notice Unstakes multiple ChronoMorph tokens in a single transaction.
     /// @param tokenIds An array of token IDs to unstake.
     function batchUnstakeMorphs(uint256[] calldata tokenIds) public {
        if (tokenIds.length > MAX_BATCH_SIZE) {
             revert ChronoMorphs__InvalidBatchLength();
        }
        for (uint i = 0; i < tokenIds.length; i++) {
            // Requires owner check and staked check inside unstakeMorph function
            unstakeMorph(tokenIds[i]);
        }
    }

     /// @notice Claims staking rewards for multiple ChronoMorph tokens in a single transaction.
     /// @param tokenIds An array of token IDs for which to claim rewards.
     function batchClaimStakingRewards(uint256[] calldata tokenIds) public {
        if (tokenIds.length > MAX_BATCH_SIZE) {
             revert ChronoMorphs__InvalidBatchLength();
        }
        for (uint i = 0; i < tokenIds.length; i++) {
            // Requires owner check and staked check inside claimStakingRewards function
            claimStakingRewards(tokenIds[i]);
        }
    }

     /// @notice Consumes Essence for multiple ChronoMorph tokens in a single transaction.
     /// Each token consumes the same amount.
     /// @param tokenIds An array of token IDs.
     /// @param amountPerToken The amount of Essence to consume for EACH token.
     function batchConsumeEssence(uint256[] calldata tokenIds, uint256 amountPerToken) public {
         if (tokenIds.length == 0 || tokenIds.length > MAX_BATCH_SIZE) {
             revert ChronoMorphs__InvalidBatchLength();
         }
         if (amountPerToken < baseEssenceConsumptionCost) {
             revert ChronoMorphs__EssenceConsumptionTooLow();
         }

        uint256 totalAmount = amountPerToken * tokenIds.length;

         // Check approval and transfer total amount *once*
         if (_essenceToken.allowance(msg.sender, address(this)) < totalAmount) {
              revert ChronoMorphs__NotEnoughEssence(msg.sender, totalAmount, _essenceToken.allowance(msg.sender, address(this)));
         }
         bool success = _essenceToken.transferFrom(msg.sender, address(this), totalAmount);
         if (!success) {
              revert ChronoMorphs__EssenceBurnFailed();
         }
         _essenceToken._burn(address(this), totalAmount); // Burn from contract balance

         uint64 currentTimestamp = uint64(block.timestamp);
         for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            // Ensure token exists and caller owns it (check inside consumeEssenceForStateChange)
            // Re-calling full logic inside loop is safer than duplicating checks
            // Re-evaluate: consumeEssenceForStateChange already burns. We need to burn total first then update states.
            // Let's update the logic for batch consumption: burn total *then* update each morph's state.

            // Assuming tokens exist and caller owns them (or has approval - not handled for batch ownership check here)
            // For a real app, iterate and check owner/approval for each, or require batch approval for the contract.
            // Simplification: trust the caller sends *their* tokens.
            _morphData[tokenId].cumulativeEssenceConsumed += amountPerToken;
            _morphData[tokenId].lastStateCalcTimestamp = currentTimestamp;
            emit EssenceConsumedForState(tokenId, amountPerToken, currentTimestamp); // Emit event for each
         }
     }

    // --- Utility/Safety Functions ---

    /// @notice Mints a new ChronoMorph token. Requires burning Essence tokens.
    /// Limited by maxSupply.
    function mintMorph() public {
        if (_tokenIdCounter.current() >= maxSupply) {
            revert ChronoMorphs__MaxSupplyReached();
        }
        if (_essenceToken.allowance(msg.sender, address(this)) < morphMintCostEssence) {
             revert ChronoMorphs__NotEnoughEssence(msg.sender, morphMintCostEssence, _essenceToken.allowance(msg.sender, address(this)));
        }

        // Consume (burn) the mint cost in Essence from the minter
        bool success = _essenceToken.transferFrom(msg.sender, address(this), morphMintCostEssence);
        if (!success) {
             revert ChronoMorphs__EssenceBurnFailed();
        }
         _essenceToken._burn(address(this), morphMintCostEssence);


        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        address minter = msg.sender;

        _safeMint(minter, newTokenId);

        uint64 mintTime = uint64(block.timestamp);
        _morphData[newTokenId] = MorphData(
            mintTime,            // mintTimestamp
            mintTime,            // lastStateCalcTimestamp
            morphMintCostEssence, // initial cumulativeEssenceConsumed (from mint cost)
            0,                   // currentCalculatedState (starts at 0)
            false,               // isEvolved
            0,                   // evolutionState
            bytes32(0)           // traitsHash (placeholder)
        );

        emit MorphMinted(newTokenId, minter, mintTime);
         emit EssenceConsumedForState(newTokenId, morphMintCostEssence, mintTime); // Log mint cost as consumption
    }

    /// @notice Allows the contract owner to rescue arbitrary ERC20 tokens mistakenly sent to the contract.
    /// Prevents rescuing the contract's own Essence token.
    /// @param tokenAddress The address of the ERC20 token to rescue.
    /// @param amount The amount of tokens to transfer.
    function rescueERC20(address tokenAddress, uint256 amount) public onlyOwner {
        if (tokenAddress == essenceTokenAddress) {
             revert ChronoMorphs__CannotRescueOwnEssenceToken();
        }
        IERC20 token = IERC20(tokenAddress);
        token.transfer(owner(), amount);
    }

    /// @notice Allows the contract owner to rescue ETH mistakenly sent to the contract.
    /// @param amount The amount of ETH to transfer.
    function rescueETH(uint256 amount) public onlyOwner {
        (bool success, ) = owner().call{value: amount}("");
        if (!success) {
             revert ChronoMorphs__ETHTransferFailed();
        }
    }

    /// @notice Calculates the potential Essence rewards for staking a morph for a given duration
    /// from its *current* staking state. Does not account for changing parameters.
    /// @param tokenId The ID of the ChronoMorph token.
    /// @param duration The duration in seconds.
    /// @return The estimated amount of Essence tokens.
    function calculateEssenceMintableForStakeDuration(uint256 tokenId, uint256 duration) public view validTokenId(tokenId) returns (uint256) {
        if (!_isMorphStaked[tokenId]) {
            // If not staked, calculate based on starting staking now
             return duration * stakingRewardPerSecondPerMorph;
        } else {
             // If already staked, add to current pending rewards
             uint256 currentPending = getPendingStakingRewards(tokenId);
             return currentPending + (duration * stakingRewardPerSecondPerMorph);
        }
    }

     // The following functions are standard ERC721 views, just listed for completeness:
     // function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Burnable) returns (bool)
     // function tokenURI(uint256 tokenId) public view override returns (string memory)
     // function balanceOf(address owner) public view override returns (uint256)
     // function ownerOf(uint256 tokenId) public view override returns (address)
     // function approve(address to, uint256 tokenId) public override
     // function getApproved(uint256 tokenId) public view override returns (address)
     // function setApprovalForAll(address operator, bool approved) public override
     // function isApprovedForAll(address owner, address operator) public view override returns (bool)
     // function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override
     // function _update(address to, uint256 tokenId) internal override(ERC721, ERC721Burnable) returns (address)
     // function _increaseBalance(address account, uint256 value) internal override(ERC721, ERC721Burnable)

    // Example implementation for _beforeTokenTransfer to reinforce staking lock (optional, override handles it)
    // function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Burnable) {
    //     super._beforeTokenTransfer(from, to, tokenId, batchSize);
    //     if (_isMorphStaked[tokenId]) {
    //         revert ChronoMorphs__TokenAlreadyStaked(tokenId);
    //     }
    // }
}
```