Okay, let's create a smart contract concept that involves stateful, dynamic NFTs (Non-Fungible Tokens) that generate a fungible resource based on their properties and interactions, influenced by a global contract state ("Cosmic Events"). We'll call it "Dimensional Nexus".

This concept combines elements of:
1.  **Dynamic NFTs:** The properties (like "Phase") of a Dimension NFT change over time and through user interaction.
2.  **Yield Farming/Resource Generation:** Dimensions passively generate a fungible token ($NEX) based on their state.
3.  **State Management:** Complex logic dictates how Dimension states change and how resources are generated.
4.  **Crafting/Synthesis:** Users can combine assets (Dimensions, $NEX) to create new assets or upgrade existing ones.
5.  **Global State Influence:** A contract-wide variable affects the behavior of all individual assets.
6.  **Time-Based Mechanics:** Generation and state changes are influenced by time elapsed.

We will *not* use standard ERC-721 or ERC-20 interfaces directly to avoid duplication, but will implement similar core functionalities (minting/transferring unique IDs, tracking balances).

---

**Smart Contract: Dimensional Nexus**

**Outline:**

1.  **State Variables:**
    *   Contract ownership and pause state.
    *   Counters for unique Dimension IDs.
    *   Mapping for Dimension data (struct `Dimension`).
    *   Mapping for user balances of Nexus Energy ($NEX).
    *   Mapping for Dimension ownership.
    *   Global "Cosmic Event" state.
    *   Configuration parameters (energy rates, transition thresholds, costs).
    *   Accumulated contract fees.

2.  **Structs and Enums:**
    *   `DimensionPhase`: Enum representing the state of a Dimension.
    *   `Dimension`: Struct holding all data for a single Dimension (ID, owner, creation time, state, parameters, traits, pending energy, etc.).
    *   `CosmicEvent`: Struct holding global event data (type, intensity, start time).

3.  **Events:**
    *   Minting, transferring, burning Dimensions.
    *   Claiming Nexus Energy.
    *   Attuning/Unattuning Dimensions.
    *   Exploring Dimensions.
    *   Synthesizing Dimensions.
    *   Cosmic Event triggered.
    *   Parameter updates.

4.  **Modifiers:**
    *   `onlyOwner`: Restricts access to the contract owner.
    *   `whenNotPaused`: Prevents execution when paused.
    *   `dimensionExists`: Checks if a dimension ID is valid.
    *   `isDimensionOwner`: Checks if caller owns a dimension.

5.  **Internal Helper Functions:**
    *   `_updateDimensionState`: Core logic to calculate time elapsed, accrue energy, and potentially trigger phase changes.
    *   `_calculateEnergyGenerated`: Calculates energy earned since last update based on state.
    *   `_determineNewPhase`: Logic to decide the next phase based on current state, parameters, attunement, cosmic event, and time.
    *   `_transferEnergy`: Internal function for moving $NEX between users or contract.
    *   `_mintDimension`: Internal function to create and assign a new Dimension.
    *   `_burnDimension`: Internal function to destroy a Dimension and clean up state.
    *   `_transferDimension`: Internal function to change Dimension ownership.

6.  **Public/External Functions (>= 20):**
    *   **Admin (onlyOwner):**
        *   `setPause`
        *   `withdrawFees`
        *   `triggerCosmicEvent`
        *   `setEnergyGenerationRates`
        *   `setPhaseTransitionThresholds`
        *   `setAttunementEffectiveness`
        *   `setExplorationConfig`
        *   `setSynthesisConfig`
    *   **Dimension Lifecycle:**
        *   `mintDimension`
        *   `transferDimension`
        *   `burnDimension`
        *   `getDimensionOwner` (view)
        *   `getTotalDimensionsMinted` (view)
    *   **Nexus Energy (NEX):**
        *   `claimEnergy`
        *   `getUserEnergy` (view)
        *   `transferEnergy` (internal system transfer, exposed for user P2P within system?) - Let's expose for user P2P within the contract.
        *   `burnEnergy`
    *   **Dimension Interaction:**
        *   `attuneDimension`
        *   `unattuneDimension`
        *   `exploreDimension`
        *   `synthesizeDimension`
        *   `updateDimensionState` (Allows anyone to trigger state update, but only applies if needed)
    *   **View Functions (public/external):**
        *   `getDimensionDetails` (view)
        *   `getDimensionParameters` (view)
        *   `getDimensionTraits` (view)
        *   `getPendingEnergy` (view, uses `_calculateEnergyGenerated`)
        *   `getPredictedPhase` (view, uses `_determineNewPhase`)
        *   `getCurrentCosmicEvent` (view)
        *   `getAttunementStaked` (view)

**Function Summary:**

*   `constructor()`: Initializes the contract owner and initial global state/parameters.
*   `setPause(bool _paused)`: Allows the owner to pause/unpause key interactions (minting, transfers, interactions).
*   `withdrawFees(address _to)`: Allows the owner to withdraw accumulated contract fees (e.g., from exploration costs).
*   `triggerCosmicEvent(uint8 _eventType, uint256 _intensity)`: Owner sets a new global event affecting all dimensions' behavior.
*   `setEnergyGenerationRates(uint8[] calldata _phases, uint256[] calldata _rates)`: Owner sets the base $NEX generation rate per phase (rate is per second/block).
*   `setPhaseTransitionThresholds(...)`: Owner sets parameters determining how phases change (e.g., time in state, attunement level required, parameter values).
*   `setAttunementEffectiveness(uint256 _effectiveness)`: Owner sets a multiplier determining how staked attunement energy boosts generation.
*   `setExplorationConfig(uint256 _energyCost, uint256 _parameterBoostAmount)`: Owner sets the cost and effect of exploring a dimension.
*   `setSynthesisConfig(uint256 _energyCost, uint256 _baseParamBoost, uint256 _materialParamContribution)`: Owner sets the costs and rules for synthesizing dimensions.
*   `mintDimension()`: Mints a new Dimension NFT to the caller, assigning random-ish initial traits and placing it in a default phase (e.g., Dormant).
*   `transferDimension(address _to, uint256 _dimensionId)`: Transfers ownership of a Dimension NFT. Handles associated data like pending energy (might need to be claimed first or transfers with it).
*   `burnDimension(uint256 _dimensionId)`: Destroys a Dimension NFT, removing it from existence. Any pending energy might be lost or sent to owner.
*   `getDimensionOwner(uint256 _dimensionId)`: View function to get the current owner of a Dimension.
*   `getTotalDimensionsMinted()`: View function for the total number of dimensions ever minted.
*   `claimEnergy(uint256[] calldata _dimensionIds)`: Allows the caller to claim pending Nexus Energy from multiple owned dimensions. Triggers state updates for specified dimensions.
*   `getUserEnergy(address _user)`: View function to get a user's current Nexus Energy balance.
*   `transferEnergy(address _to, uint256 _amount)`: Allows a user to transfer their Nexus Energy balance to another user *within the contract's internal balance system*.
*   `burnEnergy(uint256 _amount)`: Allows a user to burn their Nexus Energy (removes from their balance).
*   `attuneDimension(uint256 _dimensionId, uint256 _energyToStake)`: Allows the owner of a dimension to stake their Nexus Energy balance to that specific dimension, increasing its attunement level and boosting generation.
*   `unattuneDimension(uint256 _dimensionId, uint256 _energyToUnstake)`: Allows the owner to unstake previously staked Nexus Energy from a dimension.
*   `exploreDimension(uint256 _dimensionId)`: Allows the owner to spend Nexus Energy to perform an "exploration" action on a dimension, potentially modifying its parameters and triggering a state update.
*   `synthesizeDimension(uint256 _baseDimensionId, uint256 _materialDimensionId)`: Allows the owner to combine two dimensions (burning the material dimension) and spend Nexus Energy to upgrade the base dimension, potentially enhancing its parameters or traits based on the material dimension.
*   `updateDimensionState(uint256 _dimensionId)`: Public function allowing anyone to trigger a state update for a specific dimension. This is useful for ensuring the `pendingEnergy` and `phase` are up-to-date before interacting, without relying solely on interactions. The internal logic only processes the update if sufficient time has passed since the last update.
*   `getDimensionDetails(uint256 _dimensionId)`: View function returning all key details of a dimension struct.
*   `getDimensionParameters(uint256 _dimensionId)`: View function to get just the mutable parameters of a dimension.
*   `getDimensionTraits(uint256 _dimensionId)`: View function to get just the immutable/semi-mutable traits of a dimension.
*   `getPendingEnergy(uint256 _dimensionId)`: View function to calculate the potential Nexus Energy accrued *without* updating the dimension's state.
*   `getPredictedPhase(uint256 _dimensionId)`: View function to determine the likely next phase of a dimension based on current state and global factors, *without* triggering the actual state change.
*   `getCurrentCosmicEvent()`: View function to get the current global cosmic event details.
*   `getAttunementStaked(uint256 _dimensionId)`: View function to see how much energy is currently staked (attuned) to a specific dimension.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Dimensional Nexus
/// @notice A smart contract managing stateful, dynamic "Dimension" NFTs that generate a fungible "Nexus Energy" token.
/// @dev Dimensions have dynamic properties (Phase, Parameters) affected by time, user interaction, and global events.
/// @dev This contract implements custom ID management and internal token balances instead of standard ERCs.

// --- Outline ---
// 1. State Variables
// 2. Structs and Enums
// 3. Events
// 4. Modifiers
// 5. Internal Helper Functions
// 6. Public/External Functions (>= 20)
//    - Admin (onlyOwner)
//    - Dimension Lifecycle
//    - Nexus Energy (NEX)
//    - Dimension Interaction
//    - View Functions

// --- Function Summary ---
// constructor() - Initializes owner, base configs.
// setPause(bool) - Owner pause/unpause interactions.
// withdrawFees(address) - Owner withdraws accumulated fees.
// triggerCosmicEvent(uint8, uint256) - Owner sets global event.
// setEnergyGenerationRates(uint8[], uint256[]) - Owner sets rates per phase.
// setPhaseTransitionThresholds(...) - Owner configures phase changes.
// setAttunementEffectiveness(uint256) - Owner sets attunement boost multiplier.
// setExplorationConfig(uint256, uint256) - Owner sets explore cost/effect.
// setSynthesisConfig(uint256, uint256, uint256) - Owner sets synthesis costs/rules.
// mintDimension() - Mints a new Dimension NFT to caller.
// transferDimension(address, uint256) - Transfers Dimension ownership.
// burnDimension(uint256) - Destroys a Dimension NFT.
// getDimensionOwner(uint256) - View owner of Dimension.
// getTotalDimensionsMinted() - View total minted count.
// claimEnergy(uint256[]) - Claims pending NEX from Dimensions.
// getUserEnergy(address) - View user's NEX balance.
// transferEnergy(address, uint256) - Transfers user's internal NEX.
// burnEnergy(uint256) - Burns user's internal NEX.
// attuneDimension(uint256, uint256) - Stakes user NEX to a Dimension.
// unattuneDimension(uint256, uint256) - Unstakes NEX from a Dimension.
// exploreDimension(uint256) - Spends NEX for a Dimension interaction.
// synthesizeDimension(uint256, uint256) - Combines two Dimensions, burning one.
// updateDimensionState(uint256) - Public trigger for state update.
// getDimensionDetails(uint256) - View all Dimension data.
// getDimensionParameters(uint256) - View Dimension mutable parameters.
// getDimensionTraits(uint256) - View Dimension traits.
// getPendingEnergy(uint256) - View calculated pending NEX without update.
// getPredictedPhase(uint256) - View predicted next phase.
// getCurrentCosmicEvent() - View global event state.
// getAttunementStaked(uint256) - View NEX staked to Dimension.

contract DimensionalNexus {

    // --- State Variables ---
    address private immutable i_owner;
    bool public paused = false;

    uint256 private _dimensionIdCounter;
    mapping(uint256 => Dimension) public dimensions;
    mapping(uint256 => address) private _dimensionOwners; // Custom ownership tracking
    mapping(address => uint256) private _ownerDimensionCount; // Custom count tracking
    mapping(address => uint256) private _userNexusEnergy; // Internal NEX balances

    struct CosmicEvent {
        uint8 eventType; // e.g., 0=None, 1=Boost, 2=Turbulence, etc.
        uint256 intensity; // Magnitude of the event
        uint256 startTime;
        uint256 duration; // 0 for indefinite
    }
    CosmicEvent public cosmicEvent;

    // Configuration Parameters (Owner Settable)
    // Base energy rate per phase (per second or block, depending on interpretation/keeper frequency)
    mapping(uint8 => uint256) public energyGenerationRates; // Phase => Rate
    uint256 public attunementEffectiveness = 1 ether / 100; // 1% boost per staked energy unit (adjust decimals)
    uint256 public explorationEnergyCost = 1 ether;
    uint256 public explorationParameterBoost = 10; // Amount to increase a parameter
    uint256 public synthesisEnergyCost = 5 ether;
    uint256 public synthesisBaseParameterBoost = 50;
    uint256 public synthesisMaterialParameterContribution = 50; // Percentage contribution from material dim params

    // Phase transition thresholds (simplified)
    // Example: how long a phase lasts before a check, required attunement, parameter thresholds
    uint256 public constant MIN_TIME_IN_PHASE = 1 days; // Minimum time before phase can change naturally

    // Accumulated contract fees (e.g., from exploration)
    uint256 public accumulatedFees = 0;

    // --- Structs and Enums ---
    enum DimensionPhase {
        Dormant,     // Low generation
        Active,      // Standard generation
        Harmonious,  // Boosted generation, stable
        Turbulent,   // Boosted generation, unstable, potential for decay
        Null         // Should not happen, default zero value
    }

    struct Dimension {
        uint256 id;
        uint256 creationTime;
        uint256 lastStateUpdateTime;
        DimensionPhase phase;
        uint256 attunementStaked; // NEX staked to this specific dimension
        uint256 resonance; // Parameter: affects generation boost, phase stability
        uint256 stability; // Parameter: affects resistance to decay, phase transitions
        uint256 complexity; // Parameter: affects interaction outcomes (explore, synthesis)
        uint256 originTrait; // Immutable trait (example)
        uint256 affinityTrait; // Immutable trait (example)
        uint256 pendingEnergy; // NEX accrued but not yet claimed
    }

    // --- Events ---
    event DimensionMinted(uint256 indexed dimensionId, address indexed owner, uint256 creationTime, uint8 initialPhase);
    event DimensionTransferred(uint256 indexed dimensionId, address indexed from, address indexed to);
    event DimensionBurned(uint256 indexed dimensionId, address indexed owner);
    event EnergyClaimed(address indexed owner, uint256 indexed dimensionId, uint256 claimedAmount, uint256 finalPendingEnergy);
    event UserEnergyTransfer(address indexed from, address indexed to, uint256 amount);
    event UserEnergyBurn(address indexed owner, uint256 amount);
    event DimensionAttuned(uint256 indexed dimensionId, address indexed owner, uint256 stakedAmount, uint256 totalAttunement);
    event DimensionUnattuned(uint256 indexed dimensionId, address indexed owner, uint256 unstakedAmount, uint256 totalAttunement);
    event DimensionExplored(uint256 indexed dimensionId, address indexed owner, uint256 energyCost, uint256 parameterBoostApplied);
    event DimensionSynthesized(uint256 indexed baseDimensionId, uint256 indexed materialDimensionId, address indexed owner, uint256 energyCost);
    event DimensionStateUpdated(uint256 indexed dimensionId, uint256 newPendingEnergy, uint8 newPhase, uint265 lastUpdateTime);
    event CosmicEventTriggered(uint8 eventType, uint256 intensity, uint256 startTime, uint256 duration);
    event ParametersUpdated(bytes32 paramHash); // Generic event for any config update

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == i_owner, "Only owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier dimensionExists(uint256 _dimensionId) {
        require(_dimensionOwners[_dimensionId] != address(0), "Dimension does not exist");
        _;
    }

    modifier isDimensionOwner(uint256 _dimensionId) {
        require(_dimensionOwners[_dimensionId] == msg.sender, "Not dimension owner");
        _;
    }

    // --- Constructor ---
    constructor() {
        i_owner = msg.sender;
        _dimensionIdCounter = 0;

        // Set some initial default rates (Phase enum corresponds to array index)
        energyGenerationRates[uint8(DimensionPhase.Dormant)] = 10; // Example rates (per block/second)
        energyGenerationRates[uint8(DimensionPhase.Active)] = 50;
        energyGenerationRates[uint8(DimensionPhase.Harmonious)] = 100;
        energyGenerationRates[uint8(DimensionPhase.Turbulent)] = 75; // High but risky

        // Initial Cosmic Event (None)
        cosmicEvent = CosmicEvent({
            eventType: 0, // None
            intensity: 0,
            startTime: block.timestamp,
            duration: 0 // Indefinite
        });
    }

    // --- Internal Helper Functions ---

    /// @dev Updates a dimension's state including pending energy and potential phase changes.
    function _updateDimensionState(uint256 _dimensionId) internal dimensionExists(_dimensionId) {
        Dimension storage dim = dimensions[_dimensionId];
        uint256 currentTime = block.timestamp;

        // Calculate accrued energy
        uint256 timeElapsed = currentTime - dim.lastStateUpdateTime;
        if (timeElapsed > 0) {
            dim.pendingEnergy += _calculateEnergyGenerated(dim, timeElapsed);
            dim.lastStateUpdateTime = currentTime;
        }

        // Determine and apply phase change if conditions met and sufficient time passed
        if (currentTime - dim.creationTime > MIN_TIME_IN_PHASE && timeElapsed > 0) {
             DimensionPhase newPhase = _determineNewPhase(dim);
             if (newPhase != dim.phase) {
                 dim.phase = newPhase;
                 // Emit phase change event? Add to DimensionStateUpdated
             }
        }

        emit DimensionStateUpdated(_dimensionId, dim.pendingEnergy, uint8(dim.phase), dim.lastStateUpdateTime);
    }

    /// @dev Calculates energy generated since last update. Pure function.
    function _calculateEnergyGenerated(Dimension storage dim, uint256 timeElapsed) internal view returns (uint256) {
        uint256 baseRate = energyGenerationRates[uint8(dim.phase)];
        if (baseRate == 0) return 0;

        // Attunement boost: baseRate * (1 + attunementStaked * attunementEffectiveness)
        uint256 attunementMultiplier = 1 ether + (dim.attunementStaked * attunementEffectiveness / (1 ether)); // Scale effectiveness
        if (attunementMultiplier == 0) attunementMultiplier = 1 ether; // Prevent division by zero or zero multiplier

        uint256 generated = (baseRate * timeElapsed * attunementMultiplier) / (1 ether);

        // Apply Cosmic Event influence (example: boost or dampen generation)
        if (cosmicEvent.eventType == 1) { // Boost event
            generated = generated + (generated * cosmicEvent.intensity / 1000); // +intensity/1000 % boost
        } else if (cosmicEvent.eventType == 2) { // Turbulence event (might reduce or add variance, simplifying to potential reduction)
             generated = generated - (generated * cosmicEvent.intensity / 2000); // -intensity/2000 % reduction
        }
        // Add more complex event logic here...

        return generated;
    }

     /// @dev Determines the potential new phase based on state and rules. Pure/View logic.
     /// @notice Simplified phase transition logic. Realistically, this would be more complex.
    function _determineNewPhase(Dimension storage dim) internal view returns (DimensionPhase) {
        DimensionPhase currentPhase = dim.phase;
        // uint256 currentTime = block.timestamp;
        // uint256 timeInCurrentPhase = currentTime - dim.lastStateUpdateTime; // Or time since phase last changed

        // Example Rules (simplified):
        // Dormant -> Active: High resonance, some attunement, or specific cosmic event
        if (currentPhase == DimensionPhase.Dormant) {
            if (dim.resonance > 150 && dim.attunementStaked > 0) return DimensionPhase.Active;
            if (cosmicEvent.eventType == 1 && cosmicEvent.intensity > 500) return DimensionPhase.Active; // Boost event can wake it
        }
        // Active -> Harmonious: High resonance AND stability, significant attunement
        else if (currentPhase == DimensionPhase.Active) {
            if (dim.resonance > 200 && dim.stability > 180 && dim.attunementStaked > 10 ether) return DimensionPhase.Harmonious;
        }
        // Active -> Turbulent: Low stability, high complexity, or specific cosmic event
        else if (currentPhase == DimensionPhase.Active) {
             if (dim.stability < 50 || dim.complexity > 250) return DimensionPhase.Turbulent;
             if (cosmicEvent.eventType == 2 && cosmicEvent.intensity > 300) return DimensionPhase.Turbulent; // Turbulence event
        }
        // Harmonious -> Active: Low attunement or significant time passes without activity/attunement
        else if (currentPhase == DimensionPhase.Harmonious) {
             if (dim.attunementStaked < 5 ether) return DimensionPhase.Active;
             // Add time-based decay: e.g., if (timeInCurrentPhase > 7 days && dim.attunementStaked < 20 ether) return DimensionPhase.Active;
        }
         // Turbulent -> Active: High stability input (e.g. from synthesis/exploration), or time passes
        else if (currentPhase == DimensionPhase.Turbulent) {
            if (dim.stability > 150) return DimensionPhase.Active;
            // Add time-based decay: e.g., if (timeInCurrentPhase > 3 days) return DimensionPhase.Active; // Turbulent phases might be shorter
        }
        // Null -> Dormant: Should always start Dormant

        // Default: no phase change
        return currentPhase;
    }

    /// @dev Internal transfer of Nexus Energy between users.
    function _transferEnergy(address _from, address _to, uint256 _amount) internal {
        require(_userNexusEnergy[_from] >= _amount, "Insufficient energy");
        _userNexusEnergy[_from] -= _amount;
        _userNexusEnergy[_to] += _amount;
        emit UserEnergyTransfer(_from, _to, _amount);
    }

    /// @dev Internal minting of a new Dimension.
    function _mintDimension(address _to) internal returns (uint256) {
        _dimensionIdCounter++;
        uint256 newDimId = _dimensionIdCounter;

        // Assign initial random-ish traits and parameters
        // Using blockhash and timestamp for *basic* on-chain pseudo-randomness.
        // WARNING: This is NOT secure for high-value, unpredictable outcomes. Use Chainlink VRF or similar for true randomness.
        bytes32 randomnessSeed = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, newDimId));
        uint256 randomValue1 = uint256(keccak256(abi.encodePacked(randomnessSeed, "trait1"))) % 1000;
        uint256 randomValue2 = uint256(keccak256(abi.encodePacked(randomnessSeed, "trait2"))) % 1000;
        uint256 randomValue3 = uint256(keccak256(abi.encodePacked(randomnessSeed, "param1"))) % 100 + 50; // Base resonance 50-150
        uint256 randomValue4 = uint256(keccak256(abi.encodePacked(randomnessSeed, "param2"))) % 100 + 50; // Base stability 50-150
        uint256 randomValue5 = uint256(keccak256(abi.encodePacked(randomnessSeed, "param3"))) % 100 + 50; // Base complexity 50-150


        dimensions[newDimId] = Dimension({
            id: newDimId,
            creationTime: block.timestamp,
            lastStateUpdateTime: block.timestamp,
            phase: DimensionPhase.Dormant, // Start in Dormant
            attunementStaked: 0,
            resonance: randomValue3,
            stability: randomValue4,
            complexity: randomValue5,
            originTrait: randomValue1, // Example traits (could map to strings off-chain)
            affinityTrait: randomValue2,
            pendingEnergy: 0
        });

        _dimensionOwners[newDimId] = _to;
        _ownerDimensionCount[_to]++;

        emit DimensionMinted(newDimId, _to, block.timestamp, uint8(DimensionPhase.Dormant));
        return newDimId;
    }

    /// @dev Internal burning of a Dimension.
    function _burnDimension(uint256 _dimensionId) internal dimensionExists(_dimensionId) {
        address owner = _dimensionOwners[_dimensionId];
        Dimension storage dim = dimensions[_dimensionId];

        // Payout any pending energy and unstake attunement before burning
        if (dim.pendingEnergy > 0) {
             _userNexusEnergy[owner] += dim.pendingEnergy;
             dim.pendingEnergy = 0;
        }
        if (dim.attunementStaked > 0) {
             _userNexusEnergy[owner] += dim.attunementStaked;
             dim.attunementStaked = 0;
        }

        delete dimensions[_dimensionId];
        delete _dimensionOwners[_dimensionId];
        _ownerDimensionCount[owner]--;

        emit DimensionBurned(_dimensionId, owner);
    }

    /// @dev Internal transfer of a Dimension.
    function _transferDimension(address _from, address _to, uint256 _dimensionId) internal dimensionExists(_dimensionId) isDimensionOwner(_dimensionId) {
         require(_to != address(0), "Transfer to zero address");
         require(_from == _dimensionOwners[_dimensionId], "Transfer from wrong owner");

         // Claim pending energy for the *current* owner before transfer
         claimEnergy({_dimensionIds: [_dimensionId]}); // This also updates state

         // Staked attunement transfers WITH the dimension
         // If not desired, unstake here:
         // Dimension storage dim = dimensions[_dimensionId];
         // if (dim.attunementStaked > 0) {
         //      _userNexusEnergy[_from] += dim.attunementStaked;
         //      dim.attunementStaked = 0;
         //      emit DimensionUnattuned(_dimensionId, _from, dim.attunementStaked, 0); // Or specific unstaked amount
         // }


        _ownerDimensionCount[_from]--;
        _dimensionOwners[_dimensionId] = _to;
        _ownerDimensionCount[_to]++;

        emit DimensionTransferred(_dimensionId, _from, _to);
    }

    // --- Public/External Functions ---

    // Admin Functions
    function setPause(bool _paused) external onlyOwner {
        paused = _paused;
    }

    function withdrawFees(address _to) external onlyOwner {
        require(_to != address(0), "Withdraw to zero address");
        uint256 amount = accumulatedFees;
        accumulatedFees = 0;
        // Transfer ETH/native token balance of contract
        (bool success,) = payable(_to).call{value: amount}("");
        require(success, "Withdrawal failed");
        // Note: If fees were collected in NEX, need different logic
    }

    function triggerCosmicEvent(uint8 _eventType, uint256 _intensity) external onlyOwner whenNotPaused {
         cosmicEvent = CosmicEvent({
            eventType: _eventType,
            intensity: _intensity,
            startTime: block.timestamp,
            duration: 0 // For simplicity, indefinite until next event. Could add duration logic.
        });
        emit CosmicEventTriggered(_eventType, _intensity, block.timestamp, 0);
        // Consider adding logic to immediately update all dimensions? Too gas intensive.
        // Updates will happen lazily when dimensions are interacted with or updateDimensionState is called.
    }

    function setEnergyGenerationRates(uint8[] calldata _phases, uint256[] calldata _rates) external onlyOwner {
        require(_phases.length == _rates.length, "Array length mismatch");
        for(uint i = 0; i < _phases.length; i++) {
            require(uint8(_phases[i]) < uint8(DimensionPhase.Null), "Invalid phase");
            energyGenerationRates[_phases[i]] = _rates[i];
        }
        emit ParametersUpdated(keccak256("EnergyGenerationRates"));
    }

    function setPhaseTransitionThresholds(uint265 _minTimeInPhase) external onlyOwner {
        // In a real contract, setters for all thresholds would be here.
        // We'll just expose one example.
        // MIN_TIME_IN_PHASE = _minTimeInPhase; // Cannot set constant. Use a state variable instead if needed.
        // For this example, imagine setters for logic used in _determineNewPhase
         emit ParametersUpdated(keccak256("PhaseTransitionThresholds"));
    }

     function setAttunementEffectiveness(uint256 _effectiveness) external onlyOwner {
         attunementEffectiveness = _effectiveness;
         emit ParametersUpdated(keccak256("AttunementEffectiveness"));
     }

     function setExplorationConfig(uint256 _energyCost, uint256 _parameterBoostAmount) external onlyOwner {
         explorationEnergyCost = _energyCost;
         explorationParameterBoost = _parameterBoostAmount;
         emit ParametersUpdated(keccak256("ExplorationConfig"));
     }

     function setSynthesisConfig(uint256 _energyCost, uint256 _baseParamBoost, uint256 _materialParamContribution) external onlyOwner {
         synthesisEnergyCost = _energyCost;
         synthesisBaseParameterBoost = _baseParamBoost;
         synthesisMaterialParameterContribution = _materialParamContribution;
         emit ParametersUpdated(keccak256("SynthesisConfig"));
     }

    // Dimension Lifecycle
    function mintDimension() external whenNotPaused returns (uint256) {
        return _mintDimension(msg.sender);
    }

    function transferDimension(address _to, uint256 _dimensionId) external whenNotPaused {
        _transferDimension(msg.sender, _to, _dimensionId);
    }

    function burnDimension(uint256 _dimensionId) external whenNotPaused isDimensionOwner(_dimensionId) {
        _burnDimension(_dimensionId);
    }

    function getDimensionOwner(uint256 _dimensionId) external view dimensionExists(_dimensionId) returns (address) {
        return _dimensionOwners[_dimensionId];
    }

     function getTotalDimensionsMinted() external view returns (uint256) {
         return _dimensionIdCounter;
     }

    // Nexus Energy (NEX)
    function claimEnergy(uint256[] calldata _dimensionIds) external whenNotPaused {
        require(_dimensionIds.length > 0, "No dimensions specified");
        uint256 totalClaimed = 0;

        for (uint i = 0; i < _dimensionIds.length; i++) {
            uint256 dimId = _dimensionIds[i];
            require(_dimensionOwners[dimId] == msg.sender, "Not owner of dimension"); // Must own dimension to claim from it

            // Update state before claiming
            _updateDimensionState(dimId);

            Dimension storage dim = dimensions[dimId];
            uint256 amountToClaim = dim.pendingEnergy;
            if (amountToClaim > 0) {
                _userNexusEnergy[msg.sender] += amountToClaim;
                dim.pendingEnergy = 0;
                totalClaimed += amountToClaim;
                emit EnergyClaimed(msg.sender, dimId, amountToClaim, 0);
            }
        }
        // Optional: Add a total claimed event
    }

    function getUserEnergy(address _user) external view returns (uint256) {
        return _userNexusEnergy[_user];
    }

    /// @notice Allows transferring internal NEX balance to another user within this contract.
    function transferEnergy(address _to, uint256 _amount) external whenNotPaused {
         require(_to != address(0), "Transfer to zero address");
         require(msg.sender != _to, "Cannot transfer to self via this function");
         _transferEnergy(msg.sender, _to, _amount);
    }

    function burnEnergy(uint256 _amount) external whenNotPaused {
        require(_userNexusEnergy[msg.sender] >= _amount, "Insufficient energy to burn");
        _userNexusEnergy[msg.sender] -= _amount;
        emit UserEnergyBurn(msg.sender, _amount);
        // Could add to a global sink or trigger other effects here
    }

    // Dimension Interaction
    function attuneDimension(uint256 _dimensionId, uint256 _energyToStake) external whenNotPaused isDimensionOwner(_dimensionId) dimensionExists(_dimensionId) {
        require(_energyToStake > 0, "Must stake positive amount");
        require(_userNexusEnergy[msg.sender] >= _energyToStake, "Insufficient energy balance");

        // Update state before staking
        _updateDimensionState(_dimensionId);

        _transferEnergy(msg.sender, address(this), _energyToStake); // Transfer energy to contract's custody
        dimensions[_dimensionId].attunementStaked += _energyToStake;

        // Re-update state immediately after staking to reflect boost
        _updateDimensionState(_dimensionId);

        emit DimensionAttuned(_dimensionId, msg.sender, _energyToStake, dimensions[_dimensionId].attunementStaked);
    }

    function unattuneDimension(uint256 _dimensionId, uint256 _energyToUnstake) external whenNotPaused isDimensionOwner(_dimensionId) dimensionExists(_dimensionId) {
        require(_energyToUnstake > 0, "Must unstake positive amount");
        Dimension storage dim = dimensions[_dimensionId];
        require(dim.attunementStaked >= _energyToUnstake, "Insufficient staked energy");

        // Update state before unstaking (claim energy accrued with boost)
        _updateDimensionState(_dimensionId);

        dim.attunementStaked -= _energyToUnstake;
        _transferEnergy(address(this), msg.sender, _energyToUnstake); // Return energy from contract custody

        // Re-update state immediately after unstaking (boost reduced)
        _updateDimensionState(_dimensionId);

        emit DimensionUnattuned(_dimensionId, msg.sender, _energyToUnstake, dim.attunementStaked);
    }

     function exploreDimension(uint256 _dimensionId) external whenNotPaused isDimensionOwner(_dimensionId) dimensionExists(_dimensionId) {
         require(_userNexusEnergy[msg.sender] >= explorationEnergyCost, "Insufficient energy to explore");
         require(explorationEnergyCost > 0, "Exploration is disabled (cost is 0)");

         // Update state before exploring
         _updateDimensionState(_dimensionId);

         _transferEnergy(msg.sender, address(this), explorationEnergyCost); // Spend energy
         // accumulatedFees += explorationEnergyCost; // Optionally add to fees instead of burning/sink

         Dimension storage dim = dimensions[_dimensionId];
         // Apply effect: Boost parameters (simplified - could be random, conditional, etc.)
         dim.resonance += explorationParameterBoost;
         dim.stability += explorationParameterBoost / 2; // Less stability gain from exploration
         dim.complexity += explorationParameterBoost / 4; // Less complexity gain

         // Re-update state immediately after interaction
         _updateDimensionState(_dimensionId);

         emit DimensionExplored(_dimensionId, msg.sender, explorationEnergyCost, explorationParameterBoost);
     }

    /// @notice Synthesizes two dimensions. Burns material, applies effects to base.
     function synthesizeDimension(uint256 _baseDimensionId, uint256 _materialDimensionId) external whenNotPaused {
         require(_baseDimensionId != _materialDimensionId, "Cannot synthesize a dimension with itself");
         require(_dimensionOwners[_baseDimensionId] == msg.sender, "Not owner of base dimension");
         require(_dimensionOwners[_materialDimensionId] == msg.sender, "Not owner of material dimension");
         require(_userNexusEnergy[msg.sender] >= synthesisEnergyCost, "Insufficient energy to synthesize");
         require(synthesisEnergyCost > 0, "Synthesis is disabled (cost is 0)");

         // Update states before synthesis
         _updateDimensionState(_baseDimensionId);
         _updateDimensionState(_materialDimensionId); // State of material might affect outcome

         _transferEnergy(msg.sender, address(this), synthesisEnergyCost); // Spend energy

         Dimension storage baseDim = dimensions[_baseDimensionId];
         Dimension storage materialDim = dimensions[_materialDimensionId];

         // Apply synthesis effects (simplified)
         baseDim.resonance += synthesisBaseParameterBoost + (materialDim.resonance * synthesisMaterialParameterContribution / 100);
         baseDim.stability += synthesisBaseParameterBoost / 2 + (materialDim.stability * synthesisMaterialParameterContribution / 100);
         baseDim.complexity += synthesisBaseParameterBoost / 4 + (materialDim.complexity * synthesisMaterialParameterContribution / 100);
         // Could add logic to potentially inherit/modify traits, change phase, etc.

         // Burn the material dimension
         _burnDimension(_materialDimensionId); // Handles claiming/unstaking for material dim owner (which is msg.sender)

         // Re-update base dimension state after modification
         _updateDimensionState(_baseDimensionId);

         emit DimensionSynthesized(_baseDimensionId, _materialDimensionId, msg.sender, synthesisEnergyCost);
     }

    /// @notice Allows anyone to trigger a state update for a dimension to ensure data is fresh.
    /// @dev The internal _updateDimensionState logic prevents spam by only calculating if time has passed.
    function updateDimensionState(uint256 _dimensionId) external dimensionExists(_dimensionId) {
        _updateDimensionState(_dimensionId);
    }


    // View Functions
    // Note: View functions should not call non-view/pure functions that modify state.
    // Internal helpers used here (_calculateEnergyGenerated, _determineNewPhase) must be pure/view if called from public view functions.
    // In this implementation, _updateDimensionState is not called by these views.

    function getDimensionDetails(uint256 _dimensionId) external view dimensionExists(_dimensionId) returns (
        uint256 id,
        address owner,
        uint256 creationTime,
        uint256 lastStateUpdateTime,
        DimensionPhase phase,
        uint256 attunementStaked,
        uint256 resonance,
        uint256 stability,
        uint256 complexity,
        uint256 originTrait,
        uint256 affinityTrait,
        uint256 pendingEnergy
    ) {
        Dimension storage dim = dimensions[_dimensionId];
        return (
            dim.id,
            _dimensionOwners[_dimensionId],
            dim.creationTime,
            dim.lastStateUpdateTime,
            dim.phase,
            dim.attunementStaked,
            dim.resonance,
            dim.stability,
            dim.complexity,
            dim.originTrait,
            dim.affinityTrait,
            dim.pendingEnergy
        );
    }

    function getDimensionParameters(uint256 _dimensionId) external view dimensionExists(_dimensionId) returns (uint256 resonance, uint256 stability, uint256 complexity) {
         Dimension storage dim = dimensions[_dimensionId];
         return (dim.resonance, dim.stability, dim.complexity);
    }

    function getDimensionTraits(uint256 _dimensionId) external view dimensionExists(_dimensionId) returns (uint256 originTrait, uint256 affinityTrait) {
         Dimension storage dim = dimensions[_dimensionId];
         return (dim.originTrait, dim.affinityTrait);
    }

    /// @notice Calculates pending energy without updating the dimension's state.
    function getPendingEnergy(uint256 _dimensionId) external view dimensionExists(_dimensionId) returns (uint256) {
        Dimension storage dim = dimensions[_dimensionId];
        uint256 timeElapsed = block.timestamp - dim.lastStateUpdateTime;
        if (timeElapsed == 0) return dim.pendingEnergy; // No time passed, return current pending

        uint256 accrued = _calculateEnergyGenerated(dim, timeElapsed);
        return dim.pendingEnergy + accrued;
    }

    /// @notice Predicts the next phase based on current state and logic, without triggering change.
    function getPredictedPhase(uint256 _dimensionId) external view dimensionExists(_dimensionId) returns (DimensionPhase) {
        // Note: This calls _determineNewPhase which accesses storage, so needs to be view.
        // It needs to simulate the update process somewhat to get accurate parameters,
        // but *without* actually changing state or accruing energy.
        // For simplicity in this example, _determineNewPhase is made view and relies only on current storage values.
        // A more complex simulation might copy the struct and apply time/parameter changes speculatively.
         Dimension storage dim = dimensions[_dimensionId];
         // To be truly predictive of the *next* state update, it would need to consider time elapsed.
         // This simplified version just tells you what phase it *would* transition to *if* an update happened now and conditions were met.
         return _determineNewPhase(dim);
    }

    function getCurrentCosmicEvent() external view returns (uint8 eventType, uint256 intensity, uint256 startTime, uint256 duration) {
        return (cosmicEvent.eventType, cosmicEvent.intensity, cosmicEvent.startTime, cosmicEvent.duration);
    }

    function getAttunementStaked(uint256 _dimensionId) external view dimensionExists(_dimensionId) returns (uint256) {
        return dimensions[_dimensionId].attunementStaked;
    }

    // --- Fallback/Receive ---
    // Optional: Add receive() or fallback() if contract needs to receive native token for fees or other purposes.
    // receive() external payable {
    //     accumulatedFees += msg.value;
    // }
}
```