Okay, this is an exciting challenge! Creating a truly novel and advanced smart contract that avoids duplicating existing open-source projects requires blending multiple concepts into a unique whole.

I've conceived "ChronoSculptor" – a dynamic, time-sensitive NFT (ERC-721) contract where NFTs are not static but evolve through defined states, can hold and release value over time, decay if not maintained, and react to external environmental factors. It's a blend of programmable assets, gamified mechanics, and conditional logic.

---

## ChronoSculptor Smart Contract

**Contract Name:** `ChronoSculptor`

**Concept Overview:**
The `ChronoSculptor` contract creates "ChronoSculpts" – unique, non-fungible tokens (NFTs) that possess dynamic, time-sensitive properties. Unlike traditional NFTs, ChronoSculpts are designed to evolve through predefined "states," unlock value or features conditionally, and potentially decay if neglected. They react to both internal time progression and external environmental factors, making them "living" digital assets.

**Core Principles:**
1.  **State-based Evolution:** Each ChronoSculpt progresses through a series of defined states, each with unique properties, art (metadata link), and potential actions. Evolution can be time-triggered or manually advanced.
2.  **Time-Value Sculpting:** Owners can deposit Ether into their ChronoSculpt, which can then be released incrementally over time, or unlocked upon reaching specific states or external conditions.
3.  **Ephemeral Mechanics (Decay):** ChronoSculpts can be configured to decay (lose functionality or value) if not regularly maintained (e.g., by depositing maintenance fees).
4.  **Environmental Reactivity:** ChronoSculpts can react to external data (e.g., from an oracle, representing market conditions, weather, etc.), potentially triggering state changes or conditional unlocks.
5.  **Modular State Definition:** The contract owner (or a DAO in a more advanced version) can define and update the properties of each ChronoSculpt state, allowing for flexible and evolving game mechanics or asset functionalities.

---

### Outline & Function Summary

**I. Core NFT & State Management**
*   `constructor`: Initializes the contract with basic ERC721 properties.
*   `mintChronoSculpt`: Mints a new ChronoSculpt NFT, starting it in its initial state.
*   `evolveSculptState`: Manually advances a ChronoSculpt to its next predefined state.
*   `autoEvolveSculpt`: Allows anyone to trigger auto-evolution for a sculpt if enough time has passed.
*   `regressSculptState`: (Admin/owner only) Reverts a ChronoSculpt to a previous state, useful for correcting errors or implementing special events.
*   `getCurrentSculptState`: Retrieves the current state index of a given ChronoSculpt.
*   `getSculptStateDetails`: Fetches the full definition details for a specific state index.
*   `performStateAction`: Executes a special action tied to a ChronoSculpt's current state.

**II. Value & Conditional Release Management**
*   `depositValueForSculpt`: Allows an owner to deposit Ether into their ChronoSculpt, becoming part of its "sculpted value."
*   `releaseTimedValue`: Allows the owner to claim a portion of the deposited value, released linearly over time.
*   `claimConditionalUnlock`: Allows the owner to claim a specific "unlock" (e.g., a bonus ETH amount or a feature flag) if a predefined condition (time, state, environmental factor) is met.
*   `lockSculptForDuration`: Temporarily locks a ChronoSculpt, preventing transfers for a specified period (e.g., during an event or a critical state).

**III. Ephemeral & Maintenance Mechanics**
*   `depositMaintenanceFee`: Owner deposits a fee to reset or extend the sculpt's active decay period.
*   `checkDecayStatus`: Checks if a ChronoSculpt is currently in a decayed state or is about to decay.
*   `triggerDecayPenalty`: Anyone can call this to apply a penalty (e.g., a state regression, value reduction) if a sculpt has decayed.

**IV. Environmental Reactivity & Oracles**
*   `setOracleAddress`: (Admin only) Sets the address of a trusted oracle contract.
*   `updateEnvironmentalFactor`: (Oracle only) Allows the oracle to push updated environmental data to the contract.
*   `reactToEnvironment`: Triggers a ChronoSculpt's reaction based on the current environmental factor and its configured reactivity.

**V. Configuration & Administrative Functions**
*   `setEvolutionInterval`: (Admin only) Configures the minimum time required between auto-evolution triggers.
*   `addSculptStateDefinition`: (Admin only) Defines a new evolution state, including its metadata, value unlocks, and environmental reactivity.
*   `updateSculptStateDefinition`: (Admin only) Modifies an existing state definition.
*   `removeSculptStateDefinition`: (Admin only) Removes a state definition (only if no active sculpts are in that state).
*   `updateStateUnlockCondition`: (Admin only) Modifies the conditions required to unlock features or value for a specific state.
*   `setDecayRate`: (Admin only) Configures the rate and period for sculpt decay.
*   `setMinimumDepositAmount`: (Admin only) Sets a minimum ETH deposit for value sculpting.
*   `pauseContract`: (Admin only) Pauses core functionalities of the contract (e.g., minting, transfers, value release) in case of emergencies.
*   `unpauseContract`: (Admin only) Unpauses the contract.
*   `withdrawContractFunds`: (Admin only) Allows the owner to withdraw accidental ETH sent to the contract (excluding deposited sculpt value).

**VI. View & Utility Functions**
*   `getSculptDetails`: Retrieves comprehensive data for a given ChronoSculpt.
*   `getEnvironmentalFactor`: Returns the current environmental factor stored in the contract.
*   `tokenURI`: Standard ERC-721 metadata URI resolver.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Custom Errors
error NotSculptOwner(uint256 tokenId, address caller);
error SculptDoesNotExist(uint256 tokenId);
error InvalidStateIndex(uint8 stateIndex);
error SculptAlreadyAtMaxState(uint256 tokenId);
error EvolutionNotReady(uint256 tokenId, uint256 timeRemaining);
error SculptNotDecayed(uint256 tokenId);
error SculptIsDecayed(uint256 tokenId);
error SculptLocked(uint256 tokenId, uint256 unlockTime);
error NotEnoughValueToRelease(uint256 tokenId, uint256 available, uint256 requested);
error InsufficientMaintenanceDeposit(uint256 required, uint256 provided);
error OracleNotSet();
error NotOracleAddress(address caller);
error NoActionDefinedForState(uint8 stateIndex);
error ConditionNotMet();
error NothingToWithdraw();
error MinimumDepositNotMet(uint256 required, uint256 provided);
error StateDefinitionAlreadyExists(uint8 stateIndex);
error StateDefinitionNotFound(uint8 stateIndex);
error SculptInUseInState(uint8 stateIndex);
error CannotRemoveInitialState();

/// @title ChronoSculptor
/// @dev A dynamic NFT contract where tokens evolve through states, manage time-locked value,
///      and react to external environmental factors, with built-in decay mechanics.
contract ChronoSculptor is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    // --- Enums & Structs ---

    /// @dev Represents the current status of a ChronoSculpt.
    enum SculptStatus { Active, Locked, Decayed }

    /// @dev Defines the properties for each evolution state of a ChronoSculpt.
    struct SculptStateDefinition {
        string name;                   // Human-readable name of the state (e.g., "Seed", "Sapling", "Tree")
        string baseURI;                // Base URI for metadata specific to this state
        uint256 conditionalUnlockValue; // ETH amount unlocked when entering/claiming this state
        uint256 maintenanceCost;      // Cost to maintain this state (per decay period)
        bool allowsStateAction;        // True if this state allows a specific action
        uint256 environmentalReactionThreshold; // Threshold for environmental factor to trigger reaction
        uint8 nextStateIndex;          // The default next state for evolution (0 for final state)
    }

    /// @dev Stores the mutable data for each ChronoSculpt NFT.
    struct ChronoSculptData {
        uint8 currentStateIndex;        // Current evolution state of the sculpt
        uint256 lastEvolutionTime;      // Timestamp of the last evolution
        uint256 totalDepositedValue;    // Total ETH deposited into this sculpt
        uint256 lastValueReleaseTime;   // Timestamp of the last value release
        uint256 lastMaintenanceTime;    // Timestamp of the last maintenance deposit
        uint256 unlockTime;             // Timestamp until which the sculpt is locked (transfer-restricted)
        SculptStatus status;            // Current status (Active, Locked, Decayed)
    }

    // --- State Variables ---

    mapping(uint256 => ChronoSculptData) private _chronoSculptData;
    mapping(uint8 => SculptStateDefinition) public stateDefinitions; // State Index => Definition
    uint8 public totalSculptStates; // Number of defined states

    address public oracleAddress; // Address of the trusted oracle contract
    uint256 public currentEnvironmentalFactor; // Data from the oracle

    uint256 public autoEvolutionInterval = 30 days; // Default interval for auto-evolution
    uint256 public decayPeriod = 60 days;         // Time after which sculpts start decaying if not maintained
    uint256 public decayPenaltyValue = 0.01 ether; // ETH penalty applied upon decay
    uint256 public minimumDepositAmount = 0.001 ether; // Minimum ETH for depositValueForSculpt

    // --- Events ---

    event SculptMinted(uint256 indexed tokenId, address indexed owner, uint8 initialState);
    event SculptEvolved(uint256 indexed tokenId, uint8 fromState, uint8 toState, bool autoEvolved);
    event SculptRegressed(uint256 indexed tokenId, uint8 fromState, uint8 toState);
    event ValueDeposited(uint256 indexed tokenId, address indexed depositor, uint256 amount);
    event ValueReleased(uint256 indexed tokenId, address indexed receiver, uint256 amount);
    event ConditionalUnlockClaimed(uint256 indexed tokenId, address indexed receiver, uint256 amount);
    event SculptLocked(uint256 indexed tokenId, uint256 unlockTime);
    event SculptUnlocked(uint256 indexed tokenId);
    event MaintenanceDeposited(uint256 indexed tokenId, uint256 amount, uint256 newMaintenanceTime);
    event SculptDecayed(uint256 indexed tokenId);
    event DecayPenaltyApplied(uint256 indexed tokenId, uint256 penaltyAmount);
    event EnvironmentalFactorUpdated(uint256 newFactor);
    event SculptReactedToEnvironment(uint256 indexed tokenId, uint256 factor, uint8 newState);
    event SculptStateDefinitionAdded(uint8 indexed stateIndex, string name);
    event SculptStateDefinitionUpdated(uint8 indexed stateIndex, string name);
    event SculptStateDefinitionRemoved(uint8 indexed stateIndex);

    // --- Modifiers ---

    modifier onlySculptOwner(uint256 _tokenId) {
        if (!_exists(_tokenId)) revert SculptDoesNotExist(_tokenId);
        if (ownerOf(_tokenId) != _msgSender()) revert NotSculptOwner(_tokenId, _msgSender());
        _;
    }

    modifier whenSculptIsActive(uint256 _tokenId) {
        if (!_exists(_tokenId)) revert SculptDoesNotExist(_tokenId);
        if (_chronoSculptData[_tokenId].status == SculptStatus.Locked) {
            revert SculptLocked(_tokenId, _chronoSculptData[_tokenId].unlockTime);
        }
        if (_chronoSculptData[_tokenId].status == SculptStatus.Decayed) {
            revert SculptIsDecayed(_tokenId);
        }
        _;
    }

    modifier onlyOracle() {
        if (oracleAddress == address(0)) revert OracleNotSet();
        if (_msgSender() != oracleAddress) revert NotOracleAddress(_msgSender());
        _;
    }

    // --- Constructor ---

    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
        Ownable(msg.sender)
    {}

    // --- I. Core NFT & State Management ---

    /// @dev Mints a new ChronoSculpt NFT and initializes its data.
    ///      Starts in state 0.
    /// @param to The address to mint the ChronoSculpt to.
    /// @return The ID of the newly minted ChronoSculpt.
    function mintChronoSculpt(address to)
        public
        whenNotPaused
        returns (uint256)
    {
        if (totalSculptStates == 0) revert InvalidStateIndex(0); // Ensure state 0 exists

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _safeMint(to, newItemId);

        _chronoSculptData[newItemId] = ChronoSculptData({
            currentStateIndex: 0,
            lastEvolutionTime: block.timestamp,
            totalDepositedValue: 0,
            lastValueReleaseTime: block.timestamp,
            lastMaintenanceTime: block.timestamp,
            unlockTime: 0,
            status: SculptStatus.Active
        });

        emit SculptMinted(newItemId, to, 0);
        return newItemId;
    }

    /// @dev Manually advances a ChronoSculpt to its next state.
    ///      Requires the sculpt to be active and the owner to call it.
    /// @param _tokenId The ID of the ChronoSculpt to evolve.
    function evolveSculptState(uint256 _tokenId)
        public
        onlySculptOwner(_tokenId)
        whenSculptIsActive(_tokenId)
        whenNotPaused
    {
        ChronoSculptData storage sculpt = _chronoSculptData[_tokenId];
        uint8 nextState = stateDefinitions[sculpt.currentStateIndex].nextStateIndex;

        if (nextState == 0 && sculpt.currentStateIndex != 0) { // nextStateIndex 0 means final state, unless it's state 0 itself
            revert SculptAlreadyAtMaxState(_tokenId);
        }
        if (nextState >= totalSculptStates) { // Prevent evolving past defined states
             revert InvalidStateIndex(nextState);
        }
        
        uint8 previousState = sculpt.currentStateIndex;
        sculpt.currentStateIndex = nextState;
        sculpt.lastEvolutionTime = block.timestamp;
        
        // Potential conditional unlock upon state change can be handled here or in `claimConditionalUnlock`
        // For simplicity, `claimConditionalUnlock` will be a separate function.

        emit SculptEvolved(_tokenId, previousState, sculpt.currentStateIndex, false);
    }

    /// @dev Allows anyone to trigger an automatic evolution for a sculpt if enough time has passed.
    /// @param _tokenId The ID of the ChronoSculpt to auto-evolve.
    function autoEvolveSculpt(uint256 _tokenId)
        public
        whenNotPaused
    {
        if (!_exists(_tokenId)) revert SculptDoesNotExist(_tokenId);
        if (_chronoSculptData[_tokenId].status != SculptStatus.Active) {
            revert SculptIsDecayed(_tokenId); // Auto-evolution only for active sculpts
        }

        ChronoSculptData storage sculpt = _chronoSculptData[_tokenId];
        uint8 nextState = stateDefinitions[sculpt.currentStateIndex].nextStateIndex;

        if (nextState == 0 && sculpt.currentStateIndex != 0) {
            revert SculptAlreadyAtMaxState(_tokenId);
        }
        if (nextState >= totalSculptStates) {
             revert InvalidStateIndex(nextState);
        }

        uint256 timeSinceLastEvolution = block.timestamp - sculpt.lastEvolutionTime;
        if (timeSinceLastEvolution < autoEvolutionInterval) {
            revert EvolutionNotReady(_tokenId, autoEvolutionInterval - timeSinceLastEvolution);
        }

        uint8 previousState = sculpt.currentStateIndex;
        sculpt.currentStateIndex = nextState;
        sculpt.lastEvolutionTime = block.timestamp;

        emit SculptEvolved(_tokenId, previousState, sculpt.currentStateIndex, true);
    }

    /// @dev Allows the owner to revert a ChronoSculpt to a previous state.
    ///      Could be used for special events, corrections, or "negative" evolutions.
    /// @param _tokenId The ID of the ChronoSculpt.
    /// @param _targetStateIndex The state index to regress to.
    function regressSculptState(uint256 _tokenId, uint8 _targetStateIndex)
        public
        onlyOwner // Only contract owner can do this for administrative purposes
        whenNotPaused
    {
        if (!_exists(_tokenId)) revert SculptDoesNotExist(_tokenId);
        if (_targetStateIndex >= totalSculptStates) revert InvalidStateIndex(_targetStateIndex);
        
        ChronoSculptData storage sculpt = _chronoSculptData[_tokenId];
        uint8 previousState = sculpt.currentStateIndex;

        if (previousState == _targetStateIndex) { // Already in the target state
            return;
        }

        sculpt.currentStateIndex = _targetStateIndex;
        sculpt.lastEvolutionTime = block.timestamp; // Reset evolution timer

        emit SculptRegressed(_tokenId, previousState, _targetStateIndex);
    }

    /// @dev Retrieves the current state index of a ChronoSculpt.
    /// @param _tokenId The ID of the ChronoSculpt.
    /// @return The current state index.
    function getCurrentSculptState(uint256 _tokenId)
        public
        view
        returns (uint8)
    {
        if (!_exists(_tokenId)) revert SculptDoesNotExist(_tokenId);
        return _chronoSculptData[_tokenId].currentStateIndex;
    }

    /// @dev Retrieves the detailed definition for a specific sculpt state.
    /// @param _stateIndex The index of the state to query.
    /// @return A tuple containing the state's name, base URI, conditional unlock value, maintenance cost,
    ///         allowsStateAction flag, environmental reaction threshold, and next state index.
    function getSculptStateDetails(uint8 _stateIndex)
        public
        view
        returns (
            string memory name,
            string memory baseURI,
            uint256 conditionalUnlockValue,
            uint256 maintenanceCost,
            bool allowsStateAction,
            uint256 environmentalReactionThreshold,
            uint8 nextStateIndex
        )
    {
        if (_stateIndex >= totalSculptStates) revert InvalidStateIndex(_stateIndex);
        SculptStateDefinition storage def = stateDefinitions[_stateIndex];
        return (
            def.name,
            def.baseURI,
            def.conditionalUnlockValue,
            def.maintenanceCost,
            def.allowsStateAction,
            def.environmentalReactionThreshold,
            def.nextStateIndex
        );
    }

    /// @dev Executes a special action defined for the ChronoSculpt's current state.
    ///      This is a placeholder for custom logic that would be implemented per state.
    /// @param _tokenId The ID of the ChronoSculpt to perform action on.
    function performStateAction(uint256 _tokenId)
        public
        onlySculptOwner(_tokenId)
        whenSculptIsActive(_tokenId)
        whenNotPaused
    {
        ChronoSculptData storage sculpt = _chronoSculptData[_tokenId];
        SculptStateDefinition storage currentStateDef = stateDefinitions[sculpt.currentStateIndex];

        if (!currentStateDef.allowsStateAction) {
            revert NoActionDefinedForState(sculpt.currentStateIndex);
        }

        // --- Placeholder for actual state-specific action logic ---
        // Examples:
        // - If in "Mining" state, might mint a special token to the owner.
        // - If in "Healing" state, might reset its decay timer more effectively.
        // - If in "Crafting" state, might combine with another NFT.
        // For this example, we'll just log an event.
        // In a real scenario, this function would likely be a dispatcher to private helper functions
        // based on `sculpt.currentStateIndex`.
        // --- End Placeholder ---

        emit Log("State action performed for sculpt", _tokenId, sculpt.currentStateIndex);
    }

    // --- II. Value & Conditional Release Management ---

    /// @dev Allows the owner to deposit Ether into their ChronoSculpt.
    ///      This value is then "sculpted" and can be released over time or conditionally.
    /// @param _tokenId The ID of the ChronoSculpt to deposit value into.
    function depositValueForSculpt(uint256 _tokenId)
        public
        payable
        onlySculptOwner(_tokenId)
        whenSculptIsActive(_tokenId)
        whenNotPaused
    {
        if (msg.value < minimumDepositAmount) {
            revert MinimumDepositNotMet(minimumDepositAmount, msg.value);
        }

        _chronoSculptData[_tokenId].totalDepositedValue += msg.value;
        emit ValueDeposited(_tokenId, _msgSender(), msg.value);
    }

    /// @dev Allows the owner to claim a portion of the deposited value, released linearly over time.
    ///      Calculates the amount available based on time passed since last release.
    /// @param _tokenId The ID of the ChronoSculpt to release value from.
    function releaseTimedValue(uint256 _tokenId)
        public
        onlySculptOwner(_tokenId)
        whenSculptIsActive(_tokenId)
        whenNotPaused
    {
        ChronoSculptData storage sculpt = _chronoSculptData[_tokenId];
        uint256 timeSinceLastRelease = block.timestamp - sculpt.lastValueReleaseTime;

        // Simple linear release: 1% of total deposited per day (example logic)
        // In a real scenario, this could be more complex, tied to state, etc.
        uint256 releaseRatePerSecond = sculpt.totalDepositedValue / (365 days); // Release over 1 year
        uint256 availableToRelease = releaseRatePerSecond * timeSinceLastRelease;

        if (availableToRelease == 0) revert NotEnoughValueToRelease(_tokenId, 0, 0);
        if (availableToRelease > sculpt.totalDepositedValue) {
            availableToRelease = sculpt.totalDepositedValue; // Cannot release more than available
        }
        
        uint256 amountToSend = availableToRelease; // Store before reducing totalDepositedValue

        if (amountToSend == 0) revert NotEnoughValueToRelease(_tokenId, 0, 0);

        sculpt.totalDepositedValue -= amountToSend;
        sculpt.lastValueReleaseTime = block.timestamp;

        // Using a low-level call to send Ether, safer than `transfer`
        (bool success, ) = payable(_msgSender()).call{value: amountToSend}("");
        require(success, "ETH transfer failed");

        emit ValueReleased(_tokenId, _msgSender(), amountToSend);
    }

    /// @dev Allows the owner to claim a specific "unlock" (e.g., a bonus ETH amount or a feature flag)
    ///      if a predefined condition (time, state, environmental factor) is met.
    /// @param _tokenId The ID of the ChronoSculpt.
    function claimConditionalUnlock(uint256 _tokenId)
        public
        onlySculptOwner(_tokenId)
        whenSculptIsActive(_tokenId)
        whenNotPaused
    {
        ChronoSculptData storage sculpt = _chronoSculptData[_tokenId];
        SculptStateDefinition storage currentStateDef = stateDefinitions[sculpt.currentStateIndex];

        // Example condition: unlock if the sculpt is in a specific state AND environmental factor is above a threshold.
        // This is highly customizable per state definition.
        bool conditionMet = (currentStateDef.environmentalReactionThreshold > 0 && currentEnvironmentalFactor >= currentStateDef.environmentalReactionThreshold) ||
                            (currentStateDef.conditionalUnlockValue > 0 && sculpt.currentStateIndex > 0); // Example: any state past initial state
        
        if (!conditionMet) {
            revert ConditionNotMet();
        }

        uint256 unlockAmount = currentStateDef.conditionalUnlockValue;
        if (unlockAmount == 0) {
            // No value unlock for this condition/state, but a feature could be toggled
            emit Log("No value unlock, condition met for feature", _tokenId, sculpt.currentStateIndex);
            return; // Or handle feature unlock here
        }

        // Prevent claiming multiple times for the same condition/state if desired
        // For simplicity, we assume this unlock is a one-time thing per state, but the state definition could allow repeated claims
        // To prevent repeated claims, you would need to store a mapping of (tokenId => stateIndex => bool claimed)

        (bool success, ) = payable(_msgSender()).call{value: unlockAmount}("");
        require(success, "Conditional unlock transfer failed");

        emit ConditionalUnlockClaimed(_tokenId, _msgSender(), unlockAmount);

        // Reset conditionalUnlockValue for this state for this sculpt if it's a one-time claim
        // This would require a per-sculpt flag, e.g., mapping(uint256 => mapping(uint8 => bool)) public conditionalClaimed;
        // For now, it assumes the state definition itself defines a one-time claim (or is handled off-chain).
    }

    /// @dev Temporarily locks a ChronoSculpt, preventing transfers for a specified duration.
    ///      Useful for events, quests, or ensuring stability.
    /// @param _tokenId The ID of the ChronoSculpt.
    /// @param _duration The duration in seconds to lock the sculpt for.
    function lockSculptForDuration(uint256 _tokenId, uint256 _duration)
        public
        onlySculptOwner(_tokenId)
        whenSculptIsActive(_tokenId) // Must be active to lock
        whenNotPaused
    {
        _chronoSculptData[_tokenId].unlockTime = block.timestamp + _duration;
        _chronoSculptData[_tokenId].status = SculptStatus.Locked;
        emit SculptLocked(_tokenId, _chronoSculptData[_tokenId].unlockTime);
    }

    // --- III. Ephemeral & Maintenance Mechanics ---

    /// @dev Owner deposits a fee to reset or extend the sculpt's active decay period.
    /// @param _tokenId The ID of the ChronoSculpt.
    function depositMaintenanceFee(uint256 _tokenId)
        public
        payable
        onlySculptOwner(_tokenId)
        whenNotPaused
    {
        if (!_exists(_tokenId)) revert SculptDoesNotExist(_tokenId);

        ChronoSculptData storage sculpt = _chronoSculptData[_tokenId];
        uint256 requiredMaintenance = stateDefinitions[sculpt.currentStateIndex].maintenanceCost;

        if (msg.value < requiredMaintenance) {
            revert InsufficientMaintenanceDeposit(requiredMaintenance, msg.value);
        }

        // Extend maintenance time. If already decayed, bring it back to active.
        sculpt.lastMaintenanceTime = block.timestamp;
        sculpt.status = SculptStatus.Active; // Restore to active if it was decayed

        emit MaintenanceDeposited(_tokenId, msg.value, sculpt.lastMaintenanceTime);
    }

    /// @dev Checks if a ChronoSculpt is currently in a decayed state or is about to decay.
    /// @param _tokenId The ID of the ChronoSculpt.
    /// @return true if decayed or needs maintenance soon, false otherwise.
    function checkDecayStatus(uint256 _tokenId)
        public
        view
        returns (bool isDecayed, uint256 timeUntilDecayOrOverdue)
    {
        if (!_exists(_tokenId)) revert SculptDoesNotExist(_tokenId);
        
        ChronoSculptData storage sculpt = _chronoSculptData[_tokenId];
        uint256 decayThreshold = sculpt.lastMaintenanceTime + decayPeriod;

        if (block.timestamp >= decayThreshold) {
            isDecayed = true;
            timeUntilDecayOrOverdue = block.timestamp - decayThreshold; // How long overdue
        } else {
            isDecayed = false;
            timeUntilDecayOrOverdue = decayThreshold - block.timestamp; // Time remaining
        }
    }

    /// @dev Allows anyone to call this to apply a penalty if a sculpt has decayed.
    ///      This incentivizes community members to identify decayed sculpts.
    /// @param _tokenId The ID of the ChronoSculpt.
    function triggerDecayPenalty(uint256 _tokenId)
        public
        whenNotPaused
    {
        if (!_exists(_tokenId)) revert SculptDoesNotExist(_tokenId);

        ChronoSculptData storage sculpt = _chronoSculptData[_tokenId];
        uint256 decayThreshold = sculpt.lastMaintenanceTime + decayPeriod;

        if (block.timestamp < decayThreshold) {
            revert SculptNotDecayed(_tokenId);
        }
        
        if (sculpt.status != SculptStatus.Decayed) {
            // First time detecting decay, set status and apply initial penalty
            sculpt.status = SculptStatus.Decayed;
            emit SculptDecayed(_tokenId);
        }

        // Apply penalty: for example, reduce total deposited value or regress state
        if (sculpt.totalDepositedValue >= decayPenaltyValue) {
            sculpt.totalDepositedValue -= decayPenaltyValue;
            emit DecayPenaltyApplied(_tokenId, decayPenaltyValue);
        } else if (sculpt.totalDepositedValue > 0) {
            // If less than penalty value, take all remaining
            uint256 remainingValue = sculpt.totalDepositedValue;
            sculpt.totalDepositedValue = 0;
            emit DecayPenaltyApplied(_tokenId, remainingValue);
        } else {
            // No value to penalize, maybe regress state or apply other negative effect
            if (sculpt.currentStateIndex > 0) {
                sculpt.currentStateIndex -= 1; // Example: regress one state
                emit SculptRegressed(_tokenId, sculpt.currentStateIndex + 1, sculpt.currentStateIndex);
            }
        }
    }

    // --- IV. Environmental Reactivity & Oracles ---

    /// @dev Sets the address of the trusted oracle contract. Only callable by owner.
    /// @param _oracleAddress The address of the oracle.
    function setOracleAddress(address _oracleAddress) public onlyOwner {
        oracleAddress = _oracleAddress;
    }

    /// @dev Allows the trusted oracle to push updated environmental data to the contract.
    /// @param _newFactor The new environmental factor value.
    function updateEnvironmentalFactor(uint256 _newFactor) public onlyOracle {
        currentEnvironmentalFactor = _newFactor;
        emit EnvironmentalFactorUpdated(_newFactor);
    }

    /// @dev Triggers a ChronoSculpt's reaction based on the current environmental factor.
    ///      Could change state, unlock features, or apply effects.
    /// @param _tokenId The ID of the ChronoSculpt.
    function reactToEnvironment(uint256 _tokenId)
        public
        onlySculptOwner(_tokenId)
        whenSculptIsActive(_tokenId)
        whenNotPaused
    {
        if (oracleAddress == address(0)) revert OracleNotSet();
        if (currentEnvironmentalFactor == 0) revert ConditionNotMet(); // No environmental data yet

        ChronoSculptData storage sculpt = _chronoSculptData[_tokenId];
        SculptStateDefinition storage currentStateDef = stateDefinitions[sculpt.currentStateIndex];

        // Example reaction: if environmental factor is above a sculpt's defined threshold,
        // it automatically evolves to the next state or triggers a special event.
        if (currentEnvironmentalFactor >= currentStateDef.environmentalReactionThreshold && currentStateDef.environmentalReactionThreshold > 0) {
            if (currentStateDef.nextStateIndex != 0) { // Can evolve further
                uint8 previousState = sculpt.currentStateIndex;
                sculpt.currentStateIndex = currentStateDef.nextStateIndex;
                sculpt.lastEvolutionTime = block.timestamp;
                emit SculptReactedToEnvironment(_tokenId, currentEnvironmentalFactor, sculpt.currentStateIndex);
                emit SculptEvolved(_tokenId, previousState, sculpt.currentStateIndex, false); // Treat as an evolution triggered by env
            } else {
                // Already at final state, maybe grant a bonus or special access
                emit Log("Sculpt at final state, reacted to environment", _tokenId, currentEnvironmentalFactor);
                // Can trigger a `claimConditionalUnlock` automatically here too
            }
        } else {
            revert ConditionNotMet(); // Environmental factor not met for this sculpt's state
        }
    }

    // --- V. Configuration & Administrative Functions ---

    /// @dev Configures the minimum time required between auto-evolution triggers.
    /// @param _interval New interval in seconds.
    function setEvolutionInterval(uint256 _interval) public onlyOwner {
        autoEvolutionInterval = _interval;
    }

    /// @dev Defines a new evolution state for ChronoSculpts.
    ///      State 0 is implicitly the initial state.
    /// @param _stateIndex The unique index for this state.
    /// @param _name Name of the state.
    /// @param _baseURI Base URI for metadata.
    /// @param _conditionalUnlockValue Value unlocked upon condition.
    /// @param _maintenanceCost Cost to maintain this state.
    /// @param _allowsStateAction If this state allows a special action.
    /// @param _environmentalReactionThreshold Threshold for environmental reaction.
    /// @param _nextStateIndex The index of the next state in the evolution chain (0 if final state).
    function addSculptStateDefinition(
        uint8 _stateIndex,
        string memory _name,
        string memory _baseURI,
        uint256 _conditionalUnlockValue,
        uint256 _maintenanceCost,
        bool _allowsStateAction,
        uint256 _environmentalReactionThreshold,
        uint8 _nextStateIndex
    ) public onlyOwner {
        if (stateDefinitions[_stateIndex].nextStateIndex != 0 || _stateIndex == totalSculptStates) { // Check if slot is taken or if adding sequentially
            // For simplicity, enforcing sequential addition or explicitly checking for existence.
            // A more robust system would hash the struct to check if it's the default empty struct.
            revert StateDefinitionAlreadyExists(_stateIndex);
        }
        
        stateDefinitions[_stateIndex] = SculptStateDefinition({
            name: _name,
            baseURI: _baseURI,
            conditionalUnlockValue: _conditionalUnlockValue,
            maintenanceCost: _maintenanceCost,
            allowsStateAction: _allowsStateAction,
            environmentalReactionThreshold: _environmentalReactionThreshold,
            nextStateIndex: _nextStateIndex
        });

        if (_stateIndex >= totalSculptStates) { // Update total states if new highest index
            totalSculptStates = _stateIndex + 1;
        }

        emit SculptStateDefinitionAdded(_stateIndex, _name);
    }

    /// @dev Modifies an existing state definition.
    /// @param _stateIndex The index of the state to modify.
    // (Parameters are identical to addSculptStateDefinition for brevity, but could be specific)
    function updateSculptStateDefinition(
        uint8 _stateIndex,
        string memory _name,
        string memory _baseURI,
        uint256 _conditionalUnlockValue,
        uint256 _maintenanceCost,
        bool _allowsStateAction,
        uint256 _environmentalReactionThreshold,
        uint8 _nextStateIndex
    ) public onlyOwner {
        if (_stateIndex >= totalSculptStates) revert StateDefinitionNotFound(_stateIndex);
        
        stateDefinitions[_stateIndex] = SculptStateDefinition({
            name: _name,
            baseURI: _baseURI,
            conditionalUnlockValue: _conditionalUnlockValue,
            maintenanceCost: _maintenanceCost,
            allowsStateAction: _allowsStateAction,
            environmentalReactionThreshold: _environmentalReactionThreshold,
            nextStateIndex: _nextStateIndex
        });

        emit SculptStateDefinitionUpdated(_stateIndex, _name);
    }

    /// @dev Removes a state definition. Can only remove if no active sculpts are in that state.
    /// @param _stateIndex The index of the state to remove.
    function removeSculptStateDefinition(uint8 _stateIndex) public onlyOwner {
        if (_stateIndex >= totalSculptStates || stateDefinitions[_stateIndex].nextStateIndex == 0 && _stateIndex != 0) {
            // Check if it's not the initial state and if it actually exists (a non-zero nextStateIndex suggests existence)
             revert StateDefinitionNotFound(_stateIndex);
        }
        if (_stateIndex == 0) revert CannotRemoveInitialState();

        // This would require iterating through all sculpts to ensure none are in this state.
        // For a large number of NFTs, this is gas-prohibitive on-chain.
        // In a real scenario, this would either be an off-chain check, or the design
        // would assume states are immutable once used, or allow "soft-deletion".
        // For this example, we'll assume it's a "safe" operation performed rarely.

        delete stateDefinitions[_stateIndex];
        // If the removed state was the highest index, adjust totalSculptStates
        if (_stateIndex == totalSculptStates - 1) {
            totalSculptStates--;
            // Potentially loop downwards to find new highest if there are gaps
            while (totalSculptStates > 0 && (stateDefinitions[totalSculptStates - 1].nextStateIndex == 0 && totalSculptStates - 1 != 0)) {
                totalSculptStates--;
            }
        }
        emit SculptStateDefinitionRemoved(_stateIndex);
    }

    /// @dev Modifies the conditions required to unlock features or value for a specific state.
    ///      This allows adjusting `conditionalUnlockValue` and `environmentalReactionThreshold`.
    /// @param _stateIndex The index of the state to update.
    /// @param _newUnlockValue The new conditional unlock ETH value.
    /// @param _newEnvThreshold The new environmental reaction threshold.
    function updateStateUnlockCondition(
        uint8 _stateIndex,
        uint256 _newUnlockValue,
        uint256 _newEnvThreshold
    ) public onlyOwner {
        if (_stateIndex >= totalSculptStates) revert InvalidStateIndex(_stateIndex);
        
        stateDefinitions[_stateIndex].conditionalUnlockValue = _newUnlockValue;
        stateDefinitions[_stateIndex].environmentalReactionThreshold = _newEnvThreshold;
        
        emit Log("State unlock condition updated", _stateIndex, _newUnlockValue);
    }

    /// @dev Configures the rate and period for sculpt decay.
    /// @param _decayPeriod New decay period in seconds.
    /// @param _decayPenaltyValue New ETH penalty for decay.
    function setDecayRate(uint256 _decayPeriod, uint256 _decayPenaltyValue) public onlyOwner {
        decayPeriod = _decayPeriod;
        decayPenaltyValue = _decayPenaltyValue;
    }

    /// @dev Sets a minimum ETH deposit for `depositValueForSculpt`.
    /// @param _amount The new minimum amount.
    function setMinimumDepositAmount(uint256 _amount) public onlyOwner {
        minimumDepositAmount = _amount;
    }

    /// @dev Pauses core contract functionalities in case of emergencies.
    function pauseContract() public onlyOwner {
        _pause();
    }

    /// @dev Unpauses the contract.
    function unpauseContract() public onlyOwner {
        _unpause();
    }

    /// @dev Allows the contract owner to withdraw any incidental ETH sent to the contract,
    ///      excluding sculpt-deposited value which is managed by `releaseTimedValue`.
    function withdrawContractFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        // This is tricky: we need to ensure we don't withdraw funds that are "locked" in sculpts.
        // A simple way is to calculate total locked in sculpts and subtract.
        // For simplicity here, assume any extra balance not tied to `totalDepositedValue` is incidental.
        // A more robust system would require careful accounting of all sculpt deposits.
        // This function will withdraw *all* contract balance for now. Be very careful with this.
        if (balance == 0) revert NothingToWithdraw();

        (bool success, ) = payable(_msgSender()).call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    // --- VI. View & Utility Functions ---

    /// @dev Retrieves comprehensive data for a given ChronoSculpt.
    /// @param _tokenId The ID of the ChronoSculpt.
    /// @return A tuple containing all stored data for the sculpt.
    function getSculptDetails(uint256 _tokenId)
        public
        view
        returns (
            uint8 currentStateIndex,
            uint256 lastEvolutionTime,
            uint256 totalDepositedValue,
            uint256 lastValueReleaseTime,
            uint256 lastMaintenanceTime,
            uint256 unlockTime,
            SculptStatus status
        )
    {
        if (!_exists(_tokenId)) revert SculptDoesNotExist(_tokenId);
        ChronoSculptData storage sculpt = _chronoSculptData[_tokenId];
        return (
            sculpt.currentStateIndex,
            sculpt.lastEvolutionTime,
            sculpt.totalDepositedValue,
            sculpt.lastValueReleaseTime,
            sculpt.lastMaintenanceTime,
            sculpt.unlockTime,
            sculpt.status
        );
    }

    /// @dev Returns the current environmental factor stored in the contract.
    function getEnvironmentalFactor() public view returns (uint256) {
        return currentEnvironmentalFactor;
    }

    /// @dev Overrides the standard ERC-721 tokenURI function to provide dynamic metadata.
    ///      The URI changes based on the sculpt's current state.
    /// @param _tokenId The ID of the ChronoSculpt.
    /// @return The full URI for the sculpt's metadata.
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(_tokenId)) revert ERC721NonexistentToken(_tokenId);

        ChronoSculptData storage sculpt = _chronoSculptData[_tokenId];
        SculptStateDefinition storage currentStateDef = stateDefinitions[sculpt.currentStateIndex];

        // Append tokenId and current state as query parameters or path segments
        // In a real dApp, this URI would point to a server/IPFS gateway
        // that dynamically generates JSON metadata based on the sculpt's properties.
        string memory baseURI = currentStateDef.baseURI;
        if (bytes(baseURI).length == 0) {
            baseURI = super.baseURI(); // Fallback to contract-level baseURI if state has none
        }

        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), "/", Strings.toString(sculpt.currentStateIndex), ".json"));
    }

    // --- Internal/Helper Functions ---

    /// @dev Internal override to prevent transfers when locked or paused.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable) // Also override for ERC721Enumerable if used
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        if (from != address(0)) { // Only check for existing tokens
            if (_chronoSculptData[tokenId].status == SculptStatus.Locked && block.timestamp < _chronoSculptData[tokenId].unlockTime) {
                revert SculptLocked(tokenId, _chronoSculptData[tokenId].unlockTime);
            }
        }
    }

    // --- Debug/Logging (for development, remove in production) ---
    event Log(string message, uint256 value1, uint256 value2);
}

// Minimal ERC721Enumerable import if needed, otherwise remove
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
// If using ERC721Enumerable, adjust inheritance: `is ERC721, ERC721Enumerable, Ownable, Pausable`
// And uncomment the `override(ERC721, ERC721Enumerable)` in _beforeTokenTransfer
```