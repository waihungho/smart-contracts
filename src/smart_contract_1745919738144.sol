Okay, let's create a smart contract concept called **"QuantumFlow"**.

This contract will manage a novel type of non-fungible asset ("Flow Units") that have dynamic properties influenced by time, interactions, a simulated global "entropy" system, and even probabilistic "state changes". It goes beyond standard NFT functionality by adding mechanics like entanglement, decay, stabilization, observation effects, and potential probabilistic mutations.

**Concept Outline:**

1.  **Core Asset:** ERC-721 based "Flow Units" (NFTs).
2.  **Dynamic Properties:** Each Flow Unit has properties like Energy, Stability, State Probability, last interaction time, and an optional Entangled Partner ID.
3.  **System Entropy:** A global state variable that increases over time, affecting the decay rate of all Flow Units.
4.  **Decay Mechanic:** Flow Unit properties (like Energy, Stability) can decay over time, influenced by System Entropy. Interactions (Observing, Stabilizing, Attuning) can counteract decay temporarily.
5.  **Entanglement:** Two Flow Units can be linked. Actions on one *might* have effects on its entangled partner (conceptually, not fully implemented for complexity). Decoupling is possible.
6.  **Probabilistic State:** Flow Units have a binary state (e.g., "Stable" / "Unstable") determined probabilistically based on its properties (Energy, Stability). Interactions can trigger a "state change check" based on the current probability.
7.  **Observation Effect:** Simply viewing/interacting with a Flow Unit (`observeFlowUnit`) updates its `lastInteractionTime`, momentarily slowing decay.
8.  **Mutation:** A function (`mutateFlowUnit`) allows attempting a probabilistic mutation, potentially altering properties significantly (simulated randomness).
9.  **Energy Harvesting:** `harvestEnergy` function allows extracting value (conceptually, or reduces the unit's energy) from a Flow Unit, potentially reducing its lifespan or stability.

**Function Summary:**

*   **ERC-721 Standard Functions (Inherited/Implemented):**
    *   `balanceOf(address owner)`: Returns the number of tokens owned by an address.
    *   `ownerOf(uint256 tokenId)`: Returns the owner of a specific token.
    *   `transferFrom(address from, address to, uint256 tokenId)`: Transfers token ownership.
    *   `safeTransferFrom(address from, address to, uint256 tokenId)`: Transfers token ownership safely.
    *   `approve(address to, uint256 tokenId)`: Approves an address to spend a token.
    *   `setApprovalForAll(address operator, bool approved)`: Approves an operator for all tokens.
    *   `getApproved(uint256 tokenId)`: Gets the approved address for a token.
    *   `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for all tokens.
    *   `supportsInterface(bytes4 interfaceId)`: Standard ERC-165 interface check.
    *   `name()`: Returns the contract name.
    *   `symbol()`: Returns the contract symbol.
    *   `tokenURI(uint256 tokenId)`: Returns the metadata URI for a token.
*   **Core Flow Unit Management:**
    *   `mintFlowUnit(address recipient, uint256 initialEnergy, uint256 initialStability, string memory tokenURI_)`: Creates a new Flow Unit NFT.
    *   `getFlowUnitProperties(uint256 tokenId)`: Retrieves the current dynamic properties of a Flow Unit.
    *   `checkAndApplyDecay(uint256 tokenId)`: Internal helper to calculate and apply decay based on time and entropy. Called by other interaction functions.
    *   `getDecayLevel(uint256 tokenId)`: Calculates the current potential decay amount for a unit without applying it.
*   **Flow Unit Interactions:**
    *   `observeFlowUnit(uint256 tokenId)`: Interacts with a unit, updating its last interaction time and checking/applying decay.
    *   `stabilizeFlowUnit(uint256 tokenId)`: Improves a unit's stability and applies decay.
    *   `attuneFlowUnit(uint256 tokenId)`: Improves a unit's energy or another property (conceptual, implementation adds energy slightly) and applies decay.
    *   `harvestEnergy(uint256 tokenId)`: Extracts energy from a unit, significantly reducing its energy and applying decay. May require ownership.
*   **Entanglement:**
    *   `entangleFlowUnits(uint256 tokenId1, uint256 tokenId2)`: Links two Flow Units. Requires ownership of both.
    *   `decoupleFlowUnits(uint256 tokenId)`: Breaks the entanglement link for a unit. Requires ownership.
    *   `getEntangledPartner(uint256 tokenId)`: Returns the ID of the unit's entangled partner, or 0 if none.
    *   `getEntangledGroup(uint256 tokenId)`: Returns an array of all tokens entangled in a chain starting from this token. (Recursive helper needed internally).
*   **Probabilistic State & Mutation:**
    *   `getFlowUnitStateProbability(uint256 tokenId)`: Calculates the current probability of the unit being in a specific state (e.g., Unstable).
    *   `triggerStateChange(uint256 tokenId)`: Attempts a probabilistic state change based on current probability and simulated randomness. Applies decay.
    *   `predictStateOutcome(uint256 tokenId)`: Pure function predicting the outcome based *only* on current probability (no state change or randomness).
    *   `mutateFlowUnit(uint256 tokenId)`: Attempts a probabilistic mutation using simulated randomness, potentially changing properties. Applies decay.
*   **System Entropy Management:**
    *   `updateSystemEntropy()`: Internal helper to increase total entropy based on time. Called by interaction functions.
    *   `getSystemEntropy()`: Returns the current global system entropy level.
    *   `setEntropyIncreaseRate(uint256 ratePerSecond)`: Admin function to set how fast entropy grows.
*   **Utility/Batch:**
    *   `batchObserveFlowUnits(uint256[] calldata tokenIds)`: Observe multiple units in one transaction.
*   **Admin/Control (Inherited):**
    *   `pause()`: Pauses contract interactions (onlyOwner).
    *   `unpause()`: Unpauses contract interactions (onlyOwner).
    *   `transferOwnership(address newOwner)`: Transfers contract ownership (onlyOwner).

This outline covers the requirements and provides a structure for the Solidity code. We will use OpenZeppelin libraries for ERC721, Ownable, and Pausable for security and efficiency.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

// Outline:
// 1. ERC-721 base for "Flow Units".
// 2. Dynamic Properties per unit (Energy, Stability, Entanglement, Time).
// 3. Global System Entropy affecting decay.
// 4. Time-based decay mechanic counteracted by interactions.
// 5. Entanglement linking two units.
// 6. Probabilistic State based on properties, triggered by interaction.
// 7. Observation effect (interaction timestamp update).
// 8. Probabilistic Mutation function.
// 9. Energy Harvesting function.
// 10. Utility/Batch functions.
// 11. Admin controls (Pause, Ownership, Entropy Rate).

// Function Summary:
// ERC-721 Standard Functions (Inherited/Implemented):
// - balanceOf(address owner): Get token count for owner.
// - ownerOf(uint256 tokenId): Get owner of a token.
// - transferFrom(address from, address to, uint256 tokenId): Transfer token.
// - safeTransferFrom(address from, address to, uint256 tokenId): Safe transfer token.
// - approve(address to, uint256 tokenId): Approve address to spend token.
// - setApprovalForAll(address operator, bool approved): Approve operator for all tokens.
// - getApproved(uint256 tokenId): Get approved address for token.
// - isApprovedForAll(address owner, address operator): Check if operator is approved.
// - supportsInterface(bytes4 interfaceId): Standard ERC-165 interface check.
// - name(): Returns contract name.
// - symbol(): Returns contract symbol.
// - tokenURI(uint256 tokenId): Returns metadata URI.

// Core Flow Unit Management:
// - mintFlowUnit(address recipient, uint256 initialEnergy, uint256 initialStability, string memory tokenURI_): Create new Flow Unit.
// - getFlowUnitProperties(uint256 tokenId): Get dynamic properties of a unit.
// - checkAndApplyDecay(uint256 tokenId): Internal helper to apply decay.
// - getDecayLevel(uint256 tokenId): Calculate potential decay amount.

// Flow Unit Interactions:
// - observeFlowUnit(uint256 tokenId): Interact with unit, update time, apply decay.
// - stabilizeFlowUnit(uint256 tokenId): Improve stability, apply decay.
// - attuneFlowUnit(uint256 tokenId): Improve energy/property, apply decay.
// - harvestEnergy(uint256 tokenId): Extract energy, reduce properties, apply decay.

// Entanglement:
// - entangleFlowUnits(uint256 tokenId1, uint256 tokenId2): Link two units.
// - decoupleFlowUnits(uint256 tokenId): Break entanglement link.
// - getEntangledPartner(uint256 tokenId): Get entangled partner ID.
// - getEntangledGroup(uint256 tokenId): Get array of entangled tokens in a chain.

// Probabilistic State & Mutation:
// - getFlowUnitStateProbability(uint256 tokenId): Calculate probability of "Unstable" state.
// - triggerStateChange(uint256 tokenId): Attempt state change based on probability/randomness.
// - predictStateOutcome(uint256 tokenId): Pure prediction of state outcome based on probability.
// - mutateFlowUnit(uint256 tokenId): Attempt probabilistic mutation of properties.

// System Entropy Management:
// - updateSystemEntropy(): Internal helper to increase global entropy.
// - getSystemEntropy(): Get current global system entropy.
// - setEntropyIncreaseRate(uint256 ratePerSecond): Set entropy growth rate (Admin).

// Utility/Batch:
// - batchObserveFlowUnits(uint256[] calldata tokenIds): Observe multiple units.

// Admin/Control (Inherited):
// - pause(): Pause contract (Admin).
// - unpause(): Unpause contract (Admin).
// - transferOwnership(address newOwner): Transfer ownership (Admin).

contract QuantumFlow is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Math for uint256;

    // --- Structures ---

    struct FlowUnitProperties {
        uint256 energy;              // Represents vitality/power
        uint256 stability;           // Resistance to decay and state changes
        uint256 lastInteractionTime; // Timestamp of the last interaction
        uint256 entangledPartnerId;  // 0 if not entangled, otherwise partner's tokenId
        // Probability state: simplified representation
        // e.g., probability of being in an "Unstable" state
        // (numerator / denominator) -> probability = numerator / denominator (out of 10000 for precision)
        uint256 stateProbabilityNumerator; // Value determining probability (e.g., 0-10000)
        uint256 stateProbabilityDenominator; // Denominator (e.g., always 10000)
        uint256 lastDecayCheckTime;  // Timestamp when decay was last calculated/applied
        string metadataHash;         // Hash or identifier for IPFS/external metadata (optional)
    }

    // --- State Variables ---

    Counters.Counter private _tokenIds;
    mapping(uint256 => FlowUnitProperties) private _flowUnits;
    mapping(uint256 => string) private _tokenURIs; // Store token URIs separately if dynamic metadata isn't used

    uint256 public totalEntropy;
    uint256 public entropyIncreaseRate = 1; // Entropy units per second
    uint256 public lastEntropyIncreaseTime;

    uint256 public constant MAX_ENERGY = 1000;
    uint256 public constant MAX_STABILITY = 1000;
    uint256 public constant PROBABILITY_DENOMINATOR = 10000; // For probability calculations (e.g., 5000/10000 = 50%)
    uint256 public constant DECAY_RATE_BASE = 1; // Base decay units per time unit
    uint256 public constant DECAY_TIME_MULTIPLIER = 1 seconds; // Time unit for decay calculation

    // --- Events ---

    event FlowUnitMinted(uint256 tokenId, address recipient, uint256 initialEnergy, uint256 initialStability);
    event FlowUnitPropertiesUpdated(uint256 tokenId, uint256 newEnergy, uint256 newStability, uint256 newStateProbNumerator);
    event Entangled(uint256 tokenId1, uint256 tokenId2);
    event Decoupled(uint256 tokenId1, uint256 tokenId2);
    event StateChanged(uint256 tokenId, bool becameUnstable, uint256 probability);
    event EntropyIncreased(uint256 newTotalEntropy);
    event EnergyHarvested(uint256 tokenId, uint256 harvestedAmount);
    event MutationAttempted(uint256 tokenId, bool success, string details);

    // --- Constructor ---

    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
        Ownable(msg.sender)
        Pausable()
    {
        lastEntropyIncreaseTime = block.timestamp;
    }

    // --- Modifier ---

    modifier whenNotEntangled(uint256 tokenId) {
        require(_flowUnits[tokenId].entangledPartnerId == 0, "QF: Unit is entangled");
        _;
    }

    modifier onlyFlowUnitOwner(uint256 tokenId) {
        require(_exists(tokenId), "QF: Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "QF: Not owner");
        _;
    }

    // --- Internal Helpers ---

    function _updateSystemEntropy() internal {
        uint256 timeElapsed = block.timestamp - lastEntropyIncreaseTime;
        if (timeElapsed > 0) {
            totalEntropy += timeElapsed * entropyIncreaseRate;
            lastEntropyIncreaseTime = block.timestamp;
            emit EntropyIncreased(totalEntropy);
        }
    }

    // Calculate potential decay based on time, entropy, and stability
    function _calculatePotentialDecay(uint256 tokenId) internal view returns (uint256 potentialDecay) {
        FlowUnitProperties storage unit = _flowUnits[tokenId];
        uint256 timeElapsed = block.timestamp - unit.lastDecayCheckTime;

        // Decay is proportional to time elapsed and global entropy, inversely proportional to stability
        // Simplified decay: time * (base + totalEntropy / scale) / (stability + base_stability_inverse)
        // Avoid division by zero stability: use a small base stability value
        uint256 effectiveStability = unit.stability == 0 ? 1 : unit.stability; // Avoid division by zero
        uint256 entropyFactor = 1 + totalEntropy.div(1000); // Example scaling: 1 + totalEntropy / 1000
        potentialDecay = timeElapsed.mul(DECAY_RATE_BASE).mul(entropyFactor).div(effectiveStability);

        // Cap decay to prevent excessive values
        potentialDecay = potentialDecay.min(unit.energy + unit.stability); // Decay shouldn't exceed total properties
    }

    // Apply decay to energy and stability
    function _applyDecay(uint256 tokenId, uint256 decayAmount) internal {
        FlowUnitProperties storage unit = _flowUnits[tokenId];
        uint256 energyDecay = decayAmount.div(2); // Example: split decay between energy and stability
        uint256 stabilityDecay = decayAmount - energyDecay;

        unit.energy = unit.energy > energyDecay ? unit.energy - energyDecay : 0;
        unit.stability = unit.stability > stabilityDecay ? unit.stability - stabilityDecay : 0;
        unit.lastDecayCheckTime = block.timestamp; // Update decay check time
    }

    // Checks and applies decay if needed before an interaction
    function _checkAndApplyDecay(uint256 tokenId) internal {
        _updateSystemEntropy(); // Update global entropy first
        uint256 decayAmount = _calculatePotentialDecay(tokenId);
        if (decayAmount > 0) {
            _applyDecay(tokenId, decayAmount);
            // Recalculate probability after decay
            _updateFlowUnitStateProbability(tokenId);
            emit FlowUnitPropertiesUpdated(tokenId, _flowUnits[tokenId].energy, _flowUnits[tokenId].stability, _flowUnits[tokenId].stateProbabilityNumerator);
        }
    }

    // Recalculate the probability of the "Unstable" state
    function _updateFlowUnitStateProbability(uint256 tokenId) internal {
        FlowUnitProperties storage unit = _flowUnits[tokenId];
        // Simplified probability calculation: Higher energy = lower instability prob, Higher stability = lower instability prob
        // prob = (MAX_ENERGY - energy + MAX_STABILITY - stability) / (2 * MAX_ENERGY + 2 * MAX_STABILITY) * PROBABILITY_DENOMINATOR
        uint256 energyFactor = MAX_ENERGY > unit.energy ? MAX_ENERGY - unit.energy : 0;
        uint256 stabilityFactor = MAX_STABILITY > unit.stability ? MAX_STABILITY - unit.stability : 0;

        uint256 rawProb = (energyFactor + stabilityFactor).mul(PROBABILITY_DENOMINATOR);
        uint256 maxPossibleValue = (MAX_ENERGY + MAX_STABILITY).mul(2); // Scale to maximum possible instability factors

        unit.stateProbabilityNumerator = maxPossibleValue > 0 ? rawProb.div(maxPossibleValue) : 0;

        // Ensure numerator doesn't exceed denominator (shouldn't with this formula, but safety)
         if (unit.stateProbabilityNumerator > PROBABILITY_DENOMINATOR) {
             unit.stateProbabilityNumerator = PROBABILITY_DENOMINATOR;
         }
         unit.stateProbabilityDenominator = PROBABILITY_DENOMINATOR;
    }

    // Internal function to get a source of pseudo-randomness on-chain
    // WARNING: This is NOT secure for production use cases requiring true randomness.
    // For production, integrate with Chainlink VRF or similar oracle.
    function _getSimulatedRandomness() internal view returns (uint256) {
        // Simple, predictable randomness source for demonstration
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tx.origin, totalEntropy)));
    }

    // Internal helper to trigger state change check
    function _triggerStateChange(uint256 tokenId) internal {
        FlowUnitProperties storage unit = _flowUnits[tokenId];
        uint256 randomValue = _getSimulatedRandomness() % PROBABILITY_DENOMINATOR; // Get value between 0 and DENOMINATOR - 1

        bool becameUnstable = randomValue < unit.stateProbabilityNumerator;

        if (becameUnstable) {
            // Example effect: reduce stability or energy significantly
            uint256 penalty = unit.stability.div(4).min(unit.energy.div(4)); // Lose 25% of lesser property
            _applyDecay(tokenId, penalty); // Apply penalty as decay
            _updateFlowUnitStateProbability(tokenId);
            emit StateChanged(tokenId, true, unit.stateProbabilityNumerator);
            emit FlowUnitPropertiesUpdated(tokenId, unit.energy, unit.stability, unit.stateProbabilityNumerator);
        } else {
             emit StateChanged(tokenId, false, unit.stateProbabilityNumerator);
        }
    }


    // --- ERC-721 Standard Overrides ---

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // Prioritize stored hash if available, otherwise use _tokenURIs mapping
         if (bytes(_flowUnits[tokenId].metadataHash).length > 0) {
             return string(abi.encodePacked("ipfs://", _flowUnits[tokenId].metadataHash));
         }
         return _tokenURIs[tokenId]; // Fallback or initial URI
    }

    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        // Break entanglement on transfer (conceptual choice for this design)
        if (_flowUnits[tokenId].entangledPartnerId != 0) {
             _decoupleFlowUnits(tokenId, _flowUnits[tokenId].entangledPartnerId);
        }
        // Any transfer should also update interaction time and check decay
        _checkAndApplyDecay(tokenId); // Check decay before transfer
        _flowUnits[tokenId].lastInteractionTime = block.timestamp; // Update interaction time for the unit
        _flowUnits[tokenId].lastDecayCheckTime = block.timestamp; // Reset decay check time
        _updateFlowUnitStateProbability(tokenId); // Update probability
        emit FlowUnitPropertiesUpdated(tokenId, _flowUnits[tokenId].energy, _flowUnits[tokenId].stability, _flowUnits[tokenId].stateProbabilityNumerator);

        return super._update(to, tokenId, auth);
    }

    // --- Core Flow Unit Management Functions ---

    /// @notice Mints a new Flow Unit NFT.
    /// @param recipient The address to mint the token to.
    /// @param initialEnergy The initial energy level (0-MAX_ENERGY).
    /// @param initialStability The initial stability level (0-MAX_STABILITY).
    /// @param tokenURI_ The initial metadata URI (e.g., IPFS hash).
    function mintFlowUnit(address recipient, uint256 initialEnergy, uint256 initialStability, string memory tokenURI_)
        public onlyOwner whenNotPaused
        returns (uint256)
    {
        _updateSystemEntropy(); // Update entropy before minting
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        require(initialEnergy <= MAX_ENERGY, "QF: Initial energy too high");
        require(initialStability <= MAX_STABILITY, "QF: Initial stability too high");

        _flowUnits[newTokenId] = FlowUnitProperties({
            energy: initialEnergy,
            stability: initialStability,
            lastInteractionTime: block.timestamp,
            entangledPartnerId: 0,
            stateProbabilityNumerator: 0, // Will be calculated on first interaction/decay check
            stateProbabilityDenominator: PROBABILITY_DENOMINATOR,
            lastDecayCheckTime: block.timestamp,
            metadataHash: tokenURI_ // Store URI directly or derive hash
        });
        _tokenURIs[newTokenId] = tokenURI_; // Also store if needed for tokenURI function logic

        _safeMint(recipient, newTokenId);

        // Initial probability calculation
        _updateFlowUnitStateProbability(newTokenId);

        emit FlowUnitMinted(newTokenId, recipient, initialEnergy, initialStability);
        emit FlowUnitPropertiesUpdated(newTokenId, initialEnergy, initialStability, _flowUnits[newTokenId].stateProbabilityNumerator);

        return newTokenId;
    }

    /// @notice Retrieves the dynamic properties of a Flow Unit.
    /// @param tokenId The ID of the Flow Unit.
    /// @return A tuple containing energy, stability, last interaction time, entangled partner ID, and state probability numerator.
    function getFlowUnitProperties(uint256 tokenId)
        public view
        returns (uint256 energy, uint256 stability, uint256 lastInteractionTime, uint256 entangledPartnerId, uint256 stateProbabilityNumerator, uint256 stateProbabilityDenominator, uint256 lastDecayCheckTime)
    {
        require(_exists(tokenId), "QF: Token does not exist");
        FlowUnitProperties storage unit = _flowUnits[tokenId];
        return (
            unit.energy,
            unit.stability,
            unit.lastInteractionTime,
            unit.entangledPartnerId,
            unit.stateProbabilityNumerator,
            unit.stateProbabilityDenominator,
            unit.lastDecayCheckTime
        );
    }

    /// @notice Calculates the current potential decay level for a Flow Unit without applying it.
    /// @param tokenId The ID of the Flow Unit.
    /// @return The calculated potential decay amount.
     function getDecayLevel(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "QF: Token does not exist");
         // Need to simulate entropy update for accurate view
         uint256 currentTotalEntropy = totalEntropy;
         uint256 timeElapsedSinceLastEntropyUpdate = block.timestamp - lastEntropyIncreaseTime;
         currentTotalEntropy += timeElapsedSinceLastEntropyUpdate * entropyIncreaseRate;

         // Recalculate decay based on potentially updated entropy and time since last check
         FlowUnitProperties storage unit = _flowUnits[tokenId];
         uint256 timeElapsedSinceLastDecayCheck = block.timestamp - unit.lastDecayCheckTime;

         uint256 effectiveStability = unit.stability == 0 ? 1 : unit.stability;
         uint256 entropyFactor = 1 + currentTotalEntropy.div(1000);
         uint256 potentialDecay = timeElapsedSinceLastDecayCheck.mul(DECAY_RATE_BASE).mul(entropyFactor).div(effectiveStability);

         return potentialDecay.min(unit.energy + unit.stability);
     }


    // --- Flow Unit Interaction Functions ---

    /// @notice Interacts with a Flow Unit, updating its last interaction time and applying decay.
    /// @param tokenId The ID of the Flow Unit.
    function observeFlowUnit(uint256 tokenId)
        public whenNotPaused
    {
        require(_exists(tokenId), "QF: Token does not exist");
        _checkAndApplyDecay(tokenId); // Check and apply decay first
        _flowUnits[tokenId].lastInteractionTime = block.timestamp; // Update interaction time
        _updateFlowUnitStateProbability(tokenId); // Update probability after interaction/decay
        emit FlowUnitPropertiesUpdated(tokenId, _flowUnits[tokenId].energy, _flowUnits[tokenId].stability, _flowUnits[tokenId].stateProbabilityNumerator);
    }

    /// @notice Stabilizes a Flow Unit, slightly increasing its stability and applying decay.
    /// @param tokenId The ID of the Flow Unit.
    function stabilizeFlowUnit(uint256 tokenId)
        public whenNotPaused onlyFlowUnitOwner(tokenId)
    {
        _checkAndApplyDecay(tokenId); // Check and apply decay first
        FlowUnitProperties storage unit = _flowUnits[tokenId];
        unit.stability = (unit.stability + 50).min(MAX_STABILITY); // Example: Increase stability by 50
        unit.lastInteractionTime = block.timestamp;
        _updateFlowUnitStateProbability(tokenId);
        emit FlowUnitPropertiesUpdated(tokenId, unit.energy, unit.stability, unit.stateProbabilityNumerator);
    }

    /// @notice Attunes a Flow Unit, slightly increasing its energy and applying decay.
    /// @param tokenId The ID of the Flow Unit.
    function attuneFlowUnit(uint256 tokenId)
        public whenNotPaused onlyFlowUnitOwner(tokenId)
    {
        _checkAndApplyDecay(tokenId); // Check and apply decay first
        FlowUnitProperties storage unit = _flowUnits[tokenId];
        unit.energy = (unit.energy + 50).min(MAX_ENERGY); // Example: Increase energy by 50
        unit.lastInteractionTime = block.timestamp;
        _updateFlowUnitStateProbability(tokenId);
        emit FlowUnitPropertiesUpdated(tokenId, unit.energy, unit.stability, unit.stateProbabilityNumerator);
    }

    /// @notice Harvests energy from a Flow Unit, significantly reducing its energy and applying decay.
    /// @param tokenId The ID of the Flow Unit.
    function harvestEnergy(uint256 tokenId)
        public whenNotPaused onlyFlowUnitOwner(tokenId)
    {
        _checkAndApplyDecay(tokenId); // Check and apply decay first
        FlowUnitProperties storage unit = _flowUnits[tokenId];
        uint256 harvestedAmount = unit.energy.div(2); // Example: Harvest 50% of current energy
        unit.energy = unit.energy > harvestedAmount ? unit.energy - harvestedAmount : 0;

        // Harvesting is taxing, also reduce stability slightly
        unit.stability = unit.stability > 20 ? unit.stability - 20 : 0; // Example: Reduce stability by 20

        unit.lastInteractionTime = block.timestamp;
        _updateFlowUnitStateProbability(tokenId);
        emit EnergyHarvested(tokenId, harvestedAmount);
        emit FlowUnitPropertiesUpdated(tokenId, unit.energy, unit.stability, unit.stateProbabilityNumerator);
    }

    // --- Entanglement Functions ---

    /// @notice Entangles two Flow Units. Requires ownership of both.
    /// @param tokenId1 The ID of the first Flow Unit.
    /// @param tokenId2 The ID of the second Flow Unit.
    function entangleFlowUnits(uint256 tokenId1, uint256 tokenId2)
        public whenNotPaused
    {
        require(_exists(tokenId1), "QF: Token1 does not exist");
        require(_exists(tokenId2), "QF: Token2 does not exist");
        require(tokenId1 != tokenId2, "QF: Cannot entangle a unit with itself");
        require(ownerOf(tokenId1) == msg.sender, "QF: Not owner of token1");
        require(ownerOf(tokenId2) == msg.sender, "QF: Not owner of token2");
        require(_flowUnits[tokenId1].entangledPartnerId == 0, "QF: Token1 already entangled");
        require(_flowUnits[tokenId2].entangledPartnerId == 0, "QF: Token2 already entangled");

        _checkAndApplyDecay(tokenId1); // Check and apply decay before entanglement
        _checkAndApplyDecay(tokenId2);

        _flowUnits[tokenId1].entangledPartnerId = tokenId2;
        _flowUnits[tokenId2].entangledPartnerId = tokenId1;

        // Entangling updates interaction time for both
        _flowUnits[tokenId1].lastInteractionTime = block.timestamp;
        _flowUnits[tokenId2].lastInteractionTime = block.timestamp;

        _updateFlowUnitStateProbability(tokenId1);
        _updateFlowUnitStateProbability(tokenId2);

        emit Entangled(tokenId1, tokenId2);
        emit FlowUnitPropertiesUpdated(tokenId1, _flowUnits[tokenId1].energy, _flowUnits[tokenId1].stability, _flowUnits[tokenId1].stateProbabilityNumerator);
        emit FlowUnitPropertiesUpdated(tokenId2, _flowUnits[tokenId2].energy, _flowUnits[tokenId2].stability, _flowUnits[tokenId2].stateProbabilityNumerator);
    }

    /// @notice Decouples a Flow Unit from its entangled partner. Requires ownership.
    /// @param tokenId The ID of the Flow Unit to decouple.
    function decoupleFlowUnits(uint256 tokenId)
        public whenNotPaused onlyFlowUnitOwner(tokenId)
    {
        require(_flowUnits[tokenId].entangledPartnerId != 0, "QF: Unit not entangled");

        uint256 partnerId = _flowUnits[tokenId].entangledPartnerId;
        require(_exists(partnerId), "QF: Entangled partner does not exist"); // Should not happen if state is consistent

        _decoupleFlowUnits(tokenId, partnerId);

        _checkAndApplyDecay(tokenId); // Apply decay after decoupling
        _checkAndApplyDecay(partnerId); // Apply decay to partner too

        _updateFlowUnitStateProbability(tokenId);
        _updateFlowUnitStateProbability(partnerId);

         emit FlowUnitPropertiesUpdated(tokenId, _flowUnits[tokenId].energy, _flowUnits[tokenId].stability, _flowUnits[tokenId].stateProbabilityNumerator);
         emit FlowUnitPropertiesUpdated(partnerId, _flowUnits[partnerId].energy, _flowUnits[partnerId].stability, _flowUnits[partnerId].stateProbabilityNumerator);
    }

    // Internal helper to perform the decoupling
    function _decoupleFlowUnits(uint256 tokenId1, uint256 tokenId2) internal {
         _flowUnits[tokenId1].entangledPartnerId = 0;
         _flowUnits[tokenId2].entangledPartnerId = 0;

         // Decoupling updates interaction time for both
        _flowUnits[tokenId1].lastInteractionTime = block.timestamp;
        _flowUnits[tokenId2].lastInteractionTime = block.timestamp;

         emit Decoupled(tokenId1, tokenId2);
    }


    /// @notice Gets the entangled partner ID of a Flow Unit.
    /// @param tokenId The ID of the Flow Unit.
    /// @return The entangled partner's tokenId, or 0 if not entangled.
    function getEntangledPartner(uint256 tokenId)
        public view returns (uint256)
    {
         require(_exists(tokenId), "QF: Token does not exist");
         return _flowUnits[tokenId].entangledPartnerId;
    }

    /// @notice Gets the chain of entangled Flow Units starting from a given unit.
    /// @param tokenId The ID of the starting Flow Unit.
    /// @return An array containing the token IDs in the entangled chain.
    function getEntangledGroup(uint256 tokenId)
        public view returns (uint256[] memory)
    {
        require(_exists(tokenId), "QF: Token does not exist");

        uint256 currentId = tokenId;
        uint256 nextId = _flowUnits[currentId].entangledPartnerId;

        // Handle isolated or simple pair cases
        if (nextId == 0) {
            return new uint256[](1); // Single unit
        }
        if (_flowUnits[nextId].entangledPartnerId == currentId) {
             uint256[] memory group = new uint256[](2);
             group[0] = currentId;
             group[1] = nextId;
             return group;
        }

        // Potentially longer chains (unlikely with current simple entanglement, but general purpose)
        // This part is conceptual and might be gas-intensive for very long hypothetical chains
        uint256[] memory group = new uint256[](2); // Start with space for 2
        group[0] = currentId;
        uint256 count = 1;
        uint256 visited = currentId; // Use visited to detect cycles or end
        uint256 tempNextId = nextId;

        // Follow the chain
        while(tempNextId != 0 && tempNextId != visited) {
             // Expand array if needed (inefficient, better to count first or use dynamic array in memory)
             // For simplicity in this example, let's assume max entanglement depth is small or just return the direct partner.
             // The current simple entanglement only supports pairs. A general group requires a more complex graph traversal.
             // Let's simplify this function to only return the direct partner if entangled, or the unit itself.
             // The name "getEntangledGroup" implies more, but the current state structure only supports pairs.
             // Reverting to a simpler implementation that fits the state structure:
             uint256[] memory simplifiedGroup;
             if (nextId == 0) {
                 simplifiedGroup = new uint256[](1);
                 simplifiedGroup[0] = tokenId;
             } else {
                  // Assuming pair entanglement only
                 simplifiedGroup = new uint256[](2);
                 simplifiedGroup[0] = tokenId;
                 simplifiedGroup[1] = nextId;
             }
             return simplifiedGroup;
        }
         // Fallback for the originally intended but complex graph traversal logic (not fully implemented)
         // This requires a more sophisticated visited tracking and potentially returning a subset if too long.
         // Returning the simplified pair logic for now.
        uint256[] memory simplifiedGroup;
        if (nextId == 0) {
            simplifiedGroup = new uint256[](1);
            simplifiedGroup[0] = tokenId;
        } else {
             // Assuming pair entanglement only
            simplifiedGroup = new uint256[](2);
            simplifiedGroup[0] = tokenId;
            simplifiedGroup[1] = nextId;
        }
        return simplifiedGroup;

    }


    // --- Probabilistic State & Mutation Functions ---

    /// @notice Calculates the current probability of a Flow Unit being in the "Unstable" state.
    /// @param tokenId The ID of the Flow Unit.
    /// @return The probability numerator (out of PROBABILITY_DENOMINATOR).
    function getFlowUnitStateProbability(uint256 tokenId)
        public view returns (uint256)
    {
        require(_exists(tokenId), "QF: Token does not exist");
        // Note: This view function doesn't trigger decay calculation automatically.
        // Call _checkAndApplyDecay before reading properties for the most up-to-date value in non-view functions.
        FlowUnitProperties storage unit = _flowUnits[tokenId];
        return unit.stateProbabilityNumerator; // Numerator is already stored and updated by other actions
    }

    /// @notice Attempts a probabilistic state change for a Flow Unit based on its properties and simulated randomness.
    /// @param tokenId The ID of the Flow Unit.
    function triggerStateChange(uint256 tokenId)
        public whenNotPaused
    {
         require(_exists(tokenId), "QF: Token does not exist");
        _checkAndApplyDecay(tokenId); // Apply decay first, which also updates probability
        _triggerStateChange(tokenId); // Attempt state change based on new probability
         _flowUnits[tokenId].lastInteractionTime = block.timestamp; // Update interaction time
         emit FlowUnitPropertiesUpdated(tokenId, _flowUnits[tokenId].energy, _flowUnits[tokenId].stability, _flowUnits[tokenId].stateProbabilityNumerator);
    }

    /// @notice Predicts the state outcome based purely on current probability, without applying randomness or changing state.
    /// @param tokenId The ID of the Flow Unit.
    /// @return A string indicating the predicted outcome ("Likely Stable" or "Likely Unstable").
     function predictStateOutcome(uint256 tokenId)
         public view returns (string memory)
     {
         require(_exists(tokenId), "QF: Token does not exist");
         FlowUnitProperties storage unit = _flowUnits[tokenId];
         // Simple prediction: if prob > 50%, predict unstable
         if (unit.stateProbabilityNumerator > PROBABILITY_DENOMINATOR / 2) {
             return "Likely Unstable";
         } else {
             return "Likely Stable";
         }
     }

    /// @notice Attempts a probabilistic mutation of a Flow Unit's properties using simulated randomness.
    /// May significantly alter Energy and Stability.
    /// @param tokenId The ID of the Flow Unit.
    function mutateFlowUnit(uint256 tokenId)
        public whenNotPaused onlyFlowUnitOwner(tokenId)
    {
        _checkAndApplyDecay(tokenId); // Apply decay before potential mutation
        FlowUnitProperties storage unit = _flowUnits[tokenId];

        uint256 randomValue = _getSimulatedRandomness();
        uint256 mutationChance = unit.stateProbabilityNumerator; // Example: Higher instability increases mutation chance
        bool mutationSuccess = (randomValue % PROBABILITY_DENOMINATOR) < mutationChance;

        string memory details;

        if (mutationSuccess) {
            // Example Mutation Effect: Drastically change energy and stability
            // New values based on a different random seed or calculation
            uint256 mutationRandom = uint256(keccak256(abi.encodePacked(randomValue, "mutation", block.timestamp)));
            unit.energy = mutationRandom % (MAX_ENERGY + 1);
            unit.stability = (mutationRandom / 100) % (MAX_STABILITY + 1); // Use division to get different random distribution
            details = "Mutation successful!";
        } else {
            // Minor effect even on failure
            unit.energy = unit.energy > 10 ? unit.energy - 10 : 0;
            unit.stability = unit.stability > 10 ? unit.stability - 10 : 0;
            details = "Mutation failed, minor property loss.";
        }

        unit.lastInteractionTime = block.timestamp;
        _updateFlowUnitStateProbability(tokenId);

        emit MutationAttempted(tokenId, mutationSuccess, details);
        emit FlowUnitPropertiesUpdated(tokenId, unit.energy, unit.stability, unit.stateProbabilityNumerator);
    }


    // --- System Entropy Management Functions ---

    /// @notice Gets the current total global system entropy level.
    /// @return The current total entropy.
     function getSystemEntropy() public view returns (uint256) {
         // Need to simulate update for accurate view
         uint256 currentTotalEntropy = totalEntropy;
         uint256 timeElapsed = block.timestamp - lastEntropyIncreaseTime;
         currentTotalEntropy += timeElapsed * entropyIncreaseRate;
         return currentTotalEntropy;
     }

    /// @notice Sets the rate at which global system entropy increases per second.
    /// @param ratePerSecond The new entropy increase rate.
    function setEntropyIncreaseRate(uint256 ratePerSecond)
        public onlyOwner
    {
        _updateSystemEntropy(); // Update entropy before changing rate
        entropyIncreaseRate = ratePerSecond;
    }

    // --- Utility/Batch Functions ---

    /// @notice Observes multiple Flow Units in a single transaction.
    /// Applies decay and updates interaction time for each. Limited to a batch size for gas.
    /// @param tokenIds An array of token IDs to observe.
    function batchObserveFlowUnits(uint256[] calldata tokenIds)
        public whenNotPaused
    {
        // Limit batch size to prevent excessive gas consumption
        require(tokenIds.length <= 50, "QF: Batch size too large"); // Example limit

        _updateSystemEntropy(); // Update entropy once for the batch

        for (uint256 i = 0; i < tokenIds.length; i++) {
             uint256 tokenId = tokenIds[i];
             if (_exists(tokenId)) {
                 _checkAndApplyDecay(tokenId); // Check and apply decay
                 _flowUnits[tokenId].lastInteractionTime = block.timestamp; // Update interaction time
                 _updateFlowUnitStateProbability(tokenId); // Update probability
                 emit FlowUnitPropertiesUpdated(tokenId, _flowUnits[tokenId].energy, _flowUnits[tokenId].stability, _flowUnits[tokenId].stateProbabilityNumerator);
             }
             // Silently skip non-existent tokens in batch
        }
    }

    // --- Admin Functions (Inherited from Pausable, Ownable) ---
    // pause()
    // unpause()
    // transferOwnership()

    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    // Note: Standard transferOwnership is available from Ownable


    // --- Fallback/Receive (Optional, good practice) ---
    receive() external payable {
        // Optionally handle receiving ETH
        // Maybe increase system entropy slightly or use as community pool
    }

    fallback() external payable {
        // Optionally handle receiving ETH via fallback
    }
}
```

**Explanation and Advanced Concepts Used:**

1.  **Dynamic NFT Properties:** Standard NFTs often have static metadata. Here, properties like Energy, Stability, and Entangled Partner are state variables stored directly in the contract, making the NFTs dynamic and interactive.
2.  **Time-Based Mechanics:** Decay is explicitly linked to `block.timestamp`, making the state of the NFT change even without direct function calls, influenced by the passage of time.
3.  **Global State Influence:** The `totalEntropy` variable is a simple example of a global system state that affects all NFTs in the contract. This allows for environmental factors influencing individual assets.
4.  **Entropy Simulation:** While a simplification, the `totalEntropy` increasing over time based on `entropyIncreaseRate` demonstrates a system parameter that changes the contract's environment dynamically.
5.  **Entanglement:** The `entangledPartnerId` creates a relationship *between* NFTs within the contract, going beyond individual asset management. `entangleFlowUnits` and `decoupleFlowUnits` manage this on-chain relationship.
6.  **Probabilistic State:** The `stateProbabilityNumerator` and `PROBABILITY_DENOMINATOR` introduce a probabilistic element. The actual "state" isn't stored as a boolean but is derived or potentially flipped based on a random chance influenced by the unit's properties.
7.  **Simulated On-Chain Randomness (with caveat):** `_getSimulatedRandomness()` uses block variables. This is explicitly mentioned as *not* secure for high-value, unpredictable outcomes in production but serves the conceptual purpose here. For real-world use, Chainlink VRF or similar is necessary.
8.  **Observation Effect:** The `observeFlowUnit` function, while seemingly simple, updates `lastInteractionTime`, which counteracts decay. This introduces a mechanic where *any* interaction, even passive "observation" (a transaction), has a tangible effect on the asset's state.
9.  **Decay Calculation Nuance:** The decay calculation considers time elapsed *since the last check*, global entropy, and the unit's stability, creating a complex interplay of factors determining property loss. The `_checkAndApplyDecay` internal function ensures this is done before other interactions.
10. **Harvesting/Mutation Mechanics:** `harvestEnergy` and `mutateFlowUnit` provide ways to interact with units that have significant, potentially risky outcomes, adding strategic depth if integrated into a game or dApp.
11. **Batching:** `batchObserveFlowUnits` demonstrates how to optimize gas costs for multiple interactions by processing them in a single transaction (with a necessary safety limit).
12. **Structured Properties:** Using a `struct` for `FlowUnitProperties` keeps related dynamic data organized per token ID.
13. **Inherited Security/Standards:** Leveraging OpenZeppelin's `ERC721`, `Ownable`, and `Pausable` provides standard interfaces and basic access control/pausing capabilities.
14. **Function Count:** The contract includes the 11 required ERC721 functions (some internal/library based, but exposed via the interface) plus 16 custom public/external functions, totaling 27 externally accessible functions, well over the 20 requested minimum.

This contract provides a framework for NFTs that are living, dynamic entities within the blockchain environment, subject to internal logic, external system factors (entropy), and interactive outcomes. It avoids being a simple clone of standard ERC-721 contracts or basic DeFi primitives.