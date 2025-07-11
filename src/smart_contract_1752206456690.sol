Okay, here is a Solidity smart contract for a `QuantumFluctuationFoundry`.

This contract concept is designed around creating unique digital artifacts (`Fluctuations`) whose properties are determined by a combination of user input, the contract's internal "entropy" state, and a simulated external random seed. The process is state-dependent and incorporates concepts like state observation, entanglement, decay, and phase transitions, framed within a "quantum" analogy.

It avoids direct replication of standard patterns like basic ERC-20/721 (though the `Fluctuation` struct could *represent* properties stored by an ERC-721, this contract *manages* them internally), simple yield farming, fixed-logic DAOs, or standard proxy upgrade patterns. It focuses on complex, state-dependent logic for artifact generation and interaction.

It uses standard OpenZeppelin libraries for `Ownable` and `Pausable` for robustness; the novelty is in the core state management and generation logic, not in these basic utilities.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title QuantumFluctuationFoundry
 * @dev A contract for synthesizing unique digital fluctuations based on entropy, input energy, and external flux.
 *
 * Outline:
 * 1. State Variables: Stores contract state, fluctuation data, parameters.
 * 2. Structs: Defines the structure of a Fluctuation.
 * 3. Events: Announces key state changes and actions.
 * 4. Modifiers: Restrict access based on ownership, phase, or pause status.
 * 5. Constructor: Initializes contract parameters.
 * 6. Core Synthesis: Functions to create new Fluctuations.
 * 7. Fluctuation Interaction: Functions allowing interaction between Fluctuations (Observation, Entanglement).
 * 8. Foundry State Management: Functions to influence the Foundry's internal state (Entropy, Phase).
 * 9. View Functions: Read-only functions to query contract state.
 * 10. Admin/Owner Functions: Management functions (set parameters, pause, withdraw, ownership).
 * 11. Internal Helper Functions: Logic abstracted for clarity and reusability.
 *
 * Function Summary (27 Functions):
 * - constructor(uint256 initialEntropy, uint256 initialStabilizationThreshold, uint256 initialEntropyFactor, uint256 initialSynthesisCostBase, uint256 initialEntanglementCost, uint256 initialDeEntanglementCost, uint256 initialObservationCost, uint8 initialPhase): Initializes the contract with starting parameters. (1)
 * - synthesizeFluctuation(uint256 _inputEnergy): Creates a new Fluctuation based on input energy, current entropy, and last external flux. (2)
 * - observeFluctuation(uint256 _id): Simulates observing a Fluctuation, potentially reducing its stability and slightly altering entropy. (3)
 * - entangleFluctuations(uint256 _id1, uint256 _id2): Attempts to entangle two Fluctuations, linking their states. (4)
 * - deEntangleFluctuations(uint256 _id1, uint256 _id2): Attempts to break the entanglement between two Fluctuations. (5)
 * - stabilizeFoundry(): Reduces the current foundry entropy, potentially requiring a cost. (6)
 * - introduceExternalFlux(uint256 _externalSeed): Owner function to update the external seed simulating an oracle or external event. (7)
 * - triggerDecayCheck(uint256 _id): Owner function to trigger a potential decay check on a specific Fluctuation. (8)
 * - advanceFoundryPhase(): Owner function to transition the Foundry to the next operational phase. (9)
 * - retreatFoundryPhase(): Owner function to transition the Foundry to the previous operational phase (if allowed). (10)
 * - recalibrateEntropyFactor(int256 _newFactor): Owner function to set the factor influencing how much entropy changes per operation. (11)
 * - setStabilizationThreshold(uint256 _newThreshold): Owner function to set the entropy threshold below which stabilization is cheap/free. (12)
 * - setSynthesisCostBase(uint256 _newCost): Owner function to set the base cost for synthesizing a Fluctuation. (13)
 * - setEntanglementCost(uint256 _newCost): Owner function to set the cost for entanglement. (14)
 * - setDeEntanglementCost(uint256 _newCost): Owner function to set the cost for de-entanglement. (15)
 * - setObservationCost(uint256 _newCost): Owner function to set the cost for observing a Fluctuation. (16)
 * - getCurrentFoundryEntropy(): Returns the current entropy level of the Foundry. (View) (17)
 * - getFoundryPhase(): Returns the current operational phase of the Foundry. (View) (18)
 * - getTotalFluctuations(): Returns the total number of Fluctuations created. (View) (19)
 * - getFluctuationDetails(uint256 _id): Returns details for a specific Fluctuation. (View) (20)
 * - getFluctuationEntropySignature(uint256 _id): Returns the entropy signature of a specific Fluctuation. (View) (21)
 * - isFluctuationEntangled(uint256 _id): Checks if a Fluctuation is entangled. (View) (22)
 * - getFluctuationEntangledWith(uint256 _id): Returns the ID a Fluctuation is entangled with (0 if none). (View) (23)
 * - pauseFoundry(): Pauses synthesis and state-changing operations. (Owner) (24)
 * - unpauseFoundry(): Unpauses the Foundry. (Owner) (25)
 * - withdrawFunds(): Withdraws accumulated Ether to the owner. (Owner) (26)
 * - rescueTokens(address _tokenAddress, address _to): Allows owner to rescue ERC20 tokens sent accidentally. (Owner) (27)
 * - transferOwnership(address newOwner): Standard Ownable function. (Inherited)
 * - acceptOwnership(): Standard Ownable function. (Inherited)
 */
contract QuantumFluctuationFoundry is Ownable, Pausable {

    using SafeERC20 for IERC20;

    // --- State Variables ---
    struct Fluctuation {
        uint256 id;                 // Unique identifier
        uint256 creationBlock;      // Block number created
        uint256 energyInput;        // Energy input used for synthesis
        uint16 perceivedColor;      // Property 1 (e.g., 0-255)
        uint16 frequency;           // Property 2 (e.g., 0-255)
        uint16 stability;           // Resistance to decay (e.g., 0-100)
        uint16 entropySignature;    // Snapshot of entropy during creation (e.g., 0-255)
        bool isEntangled;           // Is currently entangled?
        uint256 entangledWithId;    // ID of the entangled fluctuation (0 if none)
        bool isDecayed;             // Has stability reached zero?
    }

    mapping(uint256 => Fluctuation) private fluctuations;
    uint256 private fluctuationCounter; // Counter for unique Fluctuation IDs

    uint256 public currentFoundryEntropy; // Global entropy level of the Foundry
    uint256 public lastQuantumSeed;       // Simulates an external random seed or flux

    // Parameters influencing Foundry behavior
    uint256 public stabilizationThreshold; // Entropy below which stabilization is cheaper
    int256 public entropyChangeFactor;    // Multiplier for entropy changes

    // Operational Phases
    enum FoundryPhase { Genesis, Stable, Volatile, Chaotic }
    FoundryPhase public currentPhase;

    // Costs (payable in Ether)
    uint256 public synthesisCostBase;
    uint256 public entanglementCost;
    uint256 public deEntanglementCost;
    uint256 public observationCost;

    // --- Events ---
    event FluctuationSynthesized(uint256 indexed id, address indexed owner, uint256 inputEnergy, uint16 perceivedColor, uint16 frequency, uint16 stability, uint256 currentEntropy, uint8 phase);
    event FoundryStabilized(uint256 indexed oldEntropy, uint256 indexed newEntropy, uint256 costPaid);
    event FluctuationsEntangled(uint256 indexed id1, uint256 indexed id2, address indexed operator, uint256 currentEntropy);
    event FluctuationsDeEntangled(uint256 indexed id1, uint256 indexed id2, address indexed operator, uint256 currentEntropy);
    event FluctuationObserved(uint256 indexed id, address indexed observer, uint16 oldStability, uint16 newStability, uint256 currentEntropy);
    event FluctuationDecayed(uint256 indexed id, uint16 finalStability);
    event ExternalFluxIntroduced(uint256 indexed oldSeed, uint256 indexed newSeed, address indexed introducer);
    event FoundryPhaseAdvanced(FoundryPhase indexed oldPhase, FoundryPhase indexed newPhase);
    event FoundryPhaseRetreated(FoundryPhase indexed oldPhase, FoundryPhase indexed newPhase);
    event EntropyRecalibrated(int256 indexed oldFactor, int256 indexed newFactor);
    event ParametersUpdated(string paramName, uint256 oldValue, uint256 newValue); // Generic for cost/threshold updates

    // --- Modifiers ---
    modifier onlyPhase(FoundryPhase _phase) {
        require(currentPhase == _phase, "FF: Not in required phase");
        _;
    }

     modifier notPhase(FoundryPhase _phase) {
        require(currentPhase != _phase, "FF: Operation not allowed in this phase");
        _;
    }

    // --- Constructor ---
    constructor(
        uint256 initialEntropy,
        uint256 initialStabilizationThreshold,
        int256 initialEntropyFactor,
        uint256 initialSynthesisCostBase,
        uint256 initialEntanglementCost,
        uint256 initialDeEntanglementCost,
        uint256 initialObservationCost,
        uint8 initialPhase // 0=Genesis, 1=Stable, 2=Volatile, 3=Chaotic
    ) Ownable(msg.sender) {
        currentFoundryEntropy = initialEntropy;
        stabilizationThreshold = initialStabilizationThreshold;
        entropyChangeFactor = initialEntropyFactor;
        synthesisCostBase = initialSynthesisCostBase;
        entanglementCost = initialEntanglementCost;
        deEntanglementCost = initialDeEntanglementCost;
        observationCost = initialObservationCost;
        currentPhase = FoundryPhase(initialPhase); // Cast uint8 to enum
        fluctuationCounter = 0;
        lastQuantumSeed = block.timestamp; // Initial seed from deployment time
    }

    // --- Core Synthesis ---

    /**
     * @dev Synthesizes a new Quantum Fluctuation.
     * Properties are derived from input energy, current foundry state, and external flux.
     * Increases foundry entropy.
     * @param _inputEnergy User-provided energy input for the synthesis process.
     */
    function synthesizeFluctuation(uint256 _inputEnergy) external payable whenNotPaused returns (uint256 newFluctuationId) {
        uint256 requiredCost = synthesisCostBase + (_inputEnergy / 10); // Cost increases with input energy
        require(msg.value >= requiredCost, "FF: Insufficient payment for synthesis");

        // Pseudo-random property generation based on state and seed
        (uint16 color, uint16 frequency, uint16 stability, uint16 entropySig) = _generateFluctuationProperties(_inputEnergy, currentFoundryEntropy, lastQuantumSeed);

        newFluctuationId = ++fluctuationCounter;

        fluctuations[newFluctuationId] = Fluctuation({
            id: newFluctuationId,
            creationBlock: block.number,
            energyInput: _inputEnergy,
            perceivedColor: color,
            frequency: frequency,
            stability: stability,
            entropySignature: entropySig,
            isEntangled: false,
            entangledWithId: 0,
            isDecayed: false
        });

        // Update Foundry Entropy: Synthesis adds complexity/entropy
        uint256 oldEntropy = currentFoundryEntropy;
        currentFoundryEntropy = _calculateEntropyChange(oldEntropy, requiredCost, true); // Assume success

        emit FluctuationSynthesized(newFluctuationId, msg.sender, _inputEnergy, color, frequency, stability, currentFoundryEntropy, uint8(currentPhase));

        // Refund excess payment if any
        if (msg.value > requiredCost) {
            payable(msg.sender).transfer(msg.value - requiredCost);
        }
    }

    // --- Fluctuation Interaction ---

    /**
     * @dev Simulates observing a specific Fluctuation.
     * Observation can reduce the fluctuation's stability and slightly alter foundry entropy.
     * Requires payment.
     * @param _id The ID of the Fluctuation to observe.
     */
    function observeFluctuation(uint256 _id) external payable whenNotPaused {
        require(msg.value >= observationCost, "FF: Insufficient payment for observation");
        require(_id > 0 && _id <= fluctuationCounter, "FF: Fluctuation does not exist");
        Fluctuation storage fluctuation = fluctuations[_id];
        require(!fluctuation.isDecayed, "FF: Cannot observe a decayed fluctuation");

        uint16 oldStability = fluctuation.stability;
        uint16 newStability = oldStability > 0 ? (oldStability * 9 / 10) : 0; // Reduce stability by 10%

        fluctuation.stability = newStability;

        // Check for decay after observation
        if (fluctuation.stability == 0 && !fluctuation.isDecayed) {
            _decayFluctuationInternal(_id);
        }

        // Update Foundry Entropy: Observation adds minimal complexity/entropy
        uint256 oldEntropy = currentFoundryEntropy;
        currentFoundryEntropy = _calculateEntropyChange(oldEntropy, observationCost, true);

        emit FluctuationObserved(_id, msg.sender, oldStability, newStability, currentFoundryEntropy);

         if (msg.value > observationCost) {
            payable(msg.sender).transfer(msg.value - observationCost);
        }
    }

    /**
     * @dev Attempts to entangle two Fluctuations.
     * Requires payment. Fluctuations must exist and not be already entangled.
     * Increases foundry entropy significantly.
     * @param _id1 The ID of the first Fluctuation.
     * @param _id2 The ID of the second Fluctuation.
     */
    function entangleFluctuations(uint256 _id1, uint256 _id2) external payable whenNotPaused notPhase(FoundryPhase.Chaotic) {
        require(msg.value >= entanglementCost, "FF: Insufficient payment for entanglement");
        require(_id1 > 0 && _id1 <= fluctuationCounter && _id2 > 0 && _id2 <= fluctuationCounter, "FF: One or both fluctuations do not exist");
        require(_id1 != _id2, "FF: Cannot entangle a fluctuation with itself");

        Fluctuation storage f1 = fluctuations[_id1];
        Fluctuation storage f2 = fluctuations[_id2];

        require(!f1.isEntangled && !f2.isEntangled, "FF: One or both fluctuations are already entangled");
        require(!f1.isDecayed && !f2.isDecayed, "FF: Cannot entangle decayed fluctuations");

        // Perform entanglement
        f1.isEntangled = true;
        f1.entangledWithId = _id2;

        f2.isEntangled = true;
        f2.entangledWithId = _id1;

        // Update Foundry Entropy: Entanglement adds high complexity/entropy
        uint256 oldEntropy = currentFoundryEntropy;
        currentFoundryEntropy = _calculateEntropyChange(oldEntropy, entanglementCost, true);

        emit FluctuationsEntangled(_id1, _id2, msg.sender, currentFoundryEntropy);

         if (msg.value > entanglementCost) {
            payable(msg.sender).transfer(msg.value - entanglementCost);
        }
    }

    /**
     * @dev Attempts to break the entanglement between two Fluctuations.
     * Requires payment. Fluctuations must exist and be entangled with each other.
     * Also increases foundry entropy.
     * @param _id1 The ID of the first Fluctuation.
     * @param _id2 The ID of the second Fluctuation.
     */
    function deEntangleFluctuations(uint256 _id1, uint256 _id2) external payable whenNotPaused notPhase(FoundryPhase.Genesis) {
         require(msg.value >= deEntanglementCost, "FF: Insufficient payment for de-entanglement");
        require(_id1 > 0 && _id1 <= fluctuationCounter && _id2 > 0 && _id2 <= fluctuationCounter, "FF: One or both fluctuations do not exist");
        require(_id1 != _id2, "FF: Cannot de-entangle the same fluctuation");

        Fluctuation storage f1 = fluctuations[_id1];
        Fluctuation storage f2 = fluctuations[_id2];

        require(f1.isEntangled && f2.isEntangled && f1.entangledWithId == _id2 && f2.entangledWithId == _id1, "FF: Fluctuations are not entangled with each other");
        require(!f1.isDecayed && !f2.isDecayed, "FF: Cannot de-entangle decayed fluctuations");

        // Perform de-entanglement
        f1.isEntangled = false;
        f1.entangledWithId = 0;

        f2.isEntangled = false;
        f2.entangledWithId = 0;

        // Update Foundry Entropy: De-entanglement also adds complexity/entropy
        uint256 oldEntropy = currentFoundryEntropy;
        currentFoundryEntropy = _calculateEntropyChange(oldEntropy, deEntanglementCost, true); // De-entanglement is complex!

        emit FluctuationsDeEntangled(_id1, _id2, msg.sender, currentFoundryEntropy);

         if (msg.value > deEntanglementCost) {
            payable(msg.sender).transfer(msg.value - deEntanglementCost);
        }
    }

    // --- Foundry State Management ---

    /**
     * @dev Attempts to stabilize the Foundry by reducing current entropy.
     * Cost may depend on how far entropy is above the stabilization threshold.
     * Can only be called in specific phases.
     * Requires payment.
     */
    function stabilizeFoundry() external payable whenNotPaused onlyPhase(FoundryPhase.Stable) {
        uint256 reductionAmount = (currentFoundryEntropy > stabilizationThreshold) ? (currentFoundryEntropy - stabilizationThreshold) / 2 : 0; // Reduce entropy by 50% above threshold
        uint256 requiredCost = (currentFoundryEntropy > stabilizationThreshold * 2) ? msg.value : 0; // Higher entropy requires minimum payment to trigger full reduction

        require(reductionAmount > 0, "FF: Foundry is already sufficiently stable");
        if (currentFoundryEntropy > stabilizationThreshold * 2) {
             require(msg.value >= requiredCost, "FF: Insufficient payment for high-entropy stabilization");
        }

        uint256 oldEntropy = currentFoundryEntropy;
        currentFoundryEntropy = currentFoundryEntropy - reductionAmount; // Guaranteed decrease

        // Update Foundry Entropy: Stabilization reduces entropy
        // Note: _calculateEntropyChange is used here to potentially *reduce* entropy
        // based on the factor, but the primary reduction is the fixed 'reductionAmount'.
        // Let's simplify and just apply the reductionAmount here, and use _calculateEntropyChange
        // for operations that *add* entropy.
        // currentFoundryEntropy = _calculateEntropyChange(currentFoundryEntropy, msg.value, true); // Cost also slightly influences state?

        emit FoundryStabilized(oldEntropy, currentFoundryEntropy, msg.value);

         if (msg.value > requiredCost) {
            payable(msg.sender).transfer(msg.value - requiredCost);
        }
    }

    /**
     * @dev Owner function to introduce a new external flux seed.
     * Simulates oracle input or a significant external event affecting the Foundry.
     * Slightly alters entropy.
     * @param _externalSeed A new seed value from an external source (simulated).
     */
    function introduceExternalFlux(uint256 _externalSeed) external onlyOwner {
        uint256 oldSeed = lastQuantumSeed;
        lastQuantumSeed = _externalSeed;

        // Update Foundry Entropy: External flux adds slight unpredictability/entropy
        uint256 oldEntropy = currentFoundryEntropy;
        currentFoundryEntropy = _calculateEntropyChange(oldEntropy, 0, true); // Assume success, adds fixed minimal entropy

        emit ExternalFluxIntroduced(oldSeed, lastQuantumSeed, msg.sender);
    }

     /**
      * @dev Owner function to trigger a decay check on a specific Fluctuation.
      * This allows the owner to explicitly trigger the decay logic if stability reaches zero.
      * Normally triggered internally by observation, but provides a manual override.
      * @param _id The ID of the Fluctuation to check.
      */
    function triggerDecayCheck(uint256 _id) external onlyOwner {
        require(_id > 0 && _id <= fluctuationCounter, "FF: Fluctuation does not exist");
        Fluctuation storage fluctuation = fluctuations[_id];
        if (fluctuation.stability == 0 && !fluctuation.isDecayed) {
            _decayFluctuationInternal(_id);
        }
    }


    /**
     * @dev Owner function to advance the Foundry's operational phase.
     * Different phases may have different rules, costs, or allowed operations.
     */
    function advanceFoundryPhase() external onlyOwner {
        require(uint8(currentPhase) < uint8(FoundryPhase.Chaotic), "FF: Already in the final phase");
        FoundryPhase oldPhase = currentPhase;
        currentPhase = FoundryPhase(uint8(currentPhase) + 1);
        emit FoundryPhaseAdvanced(oldPhase, currentPhase);
    }

    /**
     * @dev Owner function to retreat the Foundry's operational phase.
     * Requires specific conditions or is only allowed from certain phases.
     * Currently only allowed from Chaotic to Volatile.
     */
    function retreatFoundryPhase() external onlyOwner {
         require(currentPhase == FoundryPhase.Chaotic, "FF: Retreat only allowed from Chaotic phase");
         FoundryPhase oldPhase = currentPhase;
         currentPhase = FoundryPhase(uint8(currentPhase) - 1);
         emit FoundryPhaseRetreated(oldPhase, currentPhase);
    }


    // --- View Functions ---

    /**
     * @dev Returns the current entropy level of the Foundry.
     */
    function getCurrentFoundryEntropy() external view returns (uint256) {
        return currentFoundryEntropy;
    }

    /**
     * @dev Returns the current operational phase of the Foundry.
     */
    function getFoundryPhase() external view returns (FoundryPhase) {
        return currentPhase;
    }

     /**
     * @dev Returns the total number of Fluctuations created.
     */
    function getTotalFluctuations() external view returns (uint256) {
        return fluctuationCounter;
    }

    /**
     * @dev Returns the details of a specific Fluctuation.
     * @param _id The ID of the Fluctuation.
     */
    function getFluctuationDetails(uint256 _id) external view returns (Fluctuation memory) {
        require(_id > 0 && _id <= fluctuationCounter, "FF: Fluctuation does not exist");
        return fluctuations[_id];
    }

    /**
     * @dev Returns the entropy signature of a specific Fluctuation.
     * @param _id The ID of the Fluctuation.
     */
    function getFluctuationEntropySignature(uint256 _id) external view returns (uint16) {
         require(_id > 0 && _id <= fluctuationCounter, "FF: Fluctuation does not exist");
         return fluctuations[_id].entropySignature;
    }

    /**
     * @dev Checks if a specific Fluctuation is entangled.
     * @param _id The ID of the Fluctuation.
     */
     function isFluctuationEntangled(uint256 _id) external view returns (bool) {
         require(_id > 0 && _id <= fluctuationCounter, "FF: Fluctuation does not exist");
         return fluctuations[_id].isEntangled;
     }

     /**
      * @dev Returns the ID of the Fluctuation that a given Fluctuation is entangled with.
      * Returns 0 if not entangled or Fluctuation doesn't exist.
      * @param _id The ID of the Fluctuation.
      */
     function getFluctuationEntangledWith(uint256 _id) external view returns (uint256) {
         if (_id == 0 || _id > fluctuationCounter) return 0;
         return fluctuations[_id].entangledWithId;
     }


    // --- Admin/Owner Functions ---

    /**
     * @dev Owner function to set the entropy change factor.
     * Influences how significantly entropy changes after operations.
     * @param _newFactor The new entropy change factor (can be negative).
     */
    function recalibrateEntropyFactor(int256 _newFactor) external onlyOwner {
        int256 oldFactor = entropyChangeFactor;
        entropyChangeFactor = _newFactor;
        emit EntropyRecalibrated(oldFactor, _newFactor);
    }

    /**
     * @dev Owner function to set the stabilization threshold.
     * @param _newThreshold The new stabilization threshold.
     */
    function setStabilizationThreshold(uint256 _newThreshold) external onlyOwner {
        uint256 oldValue = stabilizationThreshold;
        stabilizationThreshold = _newThreshold;
        emit ParametersUpdated("StabilizationThreshold", oldValue, _newThreshold);
    }

    /**
     * @dev Owner function to set the base cost for synthesizing Fluctuations.
     * @param _newCost The new base synthesis cost in Ether.
     */
    function setSynthesisCostBase(uint256 _newCost) external onlyOwner {
        uint256 oldValue = synthesisCostBase;
        synthesisCostBase = _newCost;
        emit ParametersUpdated("SynthesisCostBase", oldValue, _newCost);
    }

    /**
     * @dev Owner function to set the cost for entanglement.
     * @param _newCost The new entanglement cost in Ether.
     */
     function setEntanglementCost(uint256 _newCost) external onlyOwner {
        uint256 oldValue = entanglementCost;
        entanglementCost = _newCost;
        emit ParametersUpdated("EntanglementCost", oldValue, _newCost);
     }

     /**
      * @dev Owner function to set the cost for de-entanglement.
      * @param _newCost The new de-entanglement cost in Ether.
      */
     function setDeEntanglementCost(uint256 _newCost) external onlyOwner {
        uint256 oldValue = deEntanglementCost;
        deEntanglementCost = _newCost;
        emit ParametersUpdated("DeEntanglementCost", oldValue, _newCost);
     }

     /**
      * @dev Owner function to set the cost for observation.
      * @param _newCost The new observation cost in Ether.
      */
     function setObservationCost(uint256 _newCost) external onlyOwner {
        uint256 oldValue = observationCost;
        observationCost = _newCost;
        emit ParametersUpdated("ObservationCost", oldValue, _newCost);
     }

    /**
     * @dev Pauses the contract (prevents state-changing operations except owner functions).
     * Inherited from Pausable.
     */
    function pauseFoundry() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract.
     * Inherited from Pausable.
     */
    function unpauseFoundry() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows the owner to withdraw accumulated Ether.
     */
    function withdrawFunds() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "FF: Ether withdrawal failed");
    }

    /**
     * @dev Allows the owner to rescue ERC20 tokens sent to the contract address by mistake.
     * @param _tokenAddress The address of the ERC20 token.
     * @param _to The address to send the tokens to.
     */
    function rescueTokens(address _tokenAddress, address _to) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "FF: No tokens to rescue");
        token.safeTransfer(_to, balance);
    }


    // --- Internal Helper Functions ---

    /**
     * @dev Internal function to generate pseudo-random properties for a new Fluctuation.
     * Uses block data, sender, energy input, current state, and external seed.
     * NOTE: block.difficulty is unreliable on PoS, block.timestamp is guessable.
     * This is for concept illustration; a real dApp needing secure randomness would use Chainlink VRF or similar.
     * @param _inputEnergy User input energy.
     * @param _currentEntropy Current foundry entropy.
     * @param _seed External flux seed.
     * @return color, frequency, stability, entropySignature
     */
    function _generateFluctuationProperties(uint256 _inputEnergy, uint256 _currentEntropy, uint256 _seed) internal view returns (uint16, uint16, uint16, uint16) {
        uint256 combinedSeed = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao, // Use block.prevrandao for PoS
            msg.sender,
            _inputEnergy,
            _currentEntropy,
            _seed,
            fluctuationCounter + 1 // Include next counter for uniqueness
        )));

        // Derive properties using modulo and bit shifts
        uint16 color = uint16(combinedSeed % 256); // 0-255
        uint16 frequency = uint16((combinedSeed >> 8) % 256); // 0-255
        // Stability is influenced by input energy and current entropy - higher input/lower entropy -> potentially higher initial stability
        uint16 baseStability = 50 + uint16((_inputEnergy / 100) % 40); // Base stability 50-90 based on input energy
        uint16 entropyInfluence = uint16((_currentEntropy / 1000) % 30); // Higher entropy reduces stability up to 30
        uint16 stability = baseStability > entropyInfluence ? baseStability - entropyInfluence : 0; // Max 100 initial

        uint16 entropySig = uint16((combinedSeed >> 16) % 256); // Snapshot of entropy state influence

        return (color, frequency, stability, entropySig);
    }

    /**
     * @dev Internal function to calculate the change in foundry entropy.
     * Entropy changes based on operation cost, success, current state, and factor.
     * @param _currentEntropy The entropy level before the operation.
     * @param _operationCost The cost paid for the operation (simulates energy expenditure).
     * @param _success Was the operation successful? (Always true for now, but could be used for failure states)
     * @return The new entropy level.
     */
    function _calculateEntropyChange(uint256 _currentEntropy, uint256 _operationCost, bool _success) internal view returns (uint256) {
        // Example complex entropy change logic:
        // Entropy increases more with complex/costly operations (entanglement, synthesis)
        // Entropy changes are scaled by entropyChangeFactor
        // Different phases might have different base entropy changes

        int256 entropyDelta = 0;

        if (_success) {
            // Base increase varies by phase and operation type (simulated by cost)
            if (currentPhase == FoundryPhase.Genesis) entropyDelta += 10;
            else if (currentPhase == FoundryPhase.Stable) entropyDelta += 5;
            else if (currentPhase == FoundryPhase.Volatile) entropyDelta += 20;
            else if (currentPhase == FoundryPhase.Chaotic) entropyDelta += 50; // Chaotic phase adds entropy rapidly

            // Cost influence: higher cost operations add more entropy (simulating complexity/energy)
            entropyDelta += int256(_operationCost / 1e15); // Scale Gwei to something reasonable

            // Observation adds minimal entropy regardless of cost
            if (_operationCost == observationCost) entropyDelta += 1;

            // Entanglement/De-entanglement add significant base entropy
            if (_operationCost == entanglementCost || _operationCost == deEntanglementCost) entropyDelta += 50;

        } else { // Example for failed operations (not currently implemented to fail)
             entropyDelta -= 20; // Failure might reduce entropy by simplifying state? Or increase? Depends on design. Let's say it adds failure complexity.
             entropyDelta += 30;
        }

        // Apply the global entropy change factor
        entropyDelta = entropyDelta * entropyChangeFactor / 100; // Factor is a percentage multiplier (e.g., 100 = no change, 200 = double change, -50 = reverse 50%)

        // Calculate new entropy, preventing underflow if delta is negative
        unchecked { // Use unchecked for addition/subtraction where we handle potential underflow/overflow
            if (entropyDelta > 0) {
                 // Add entropy, cap at a maximum (e.g., type(uint256).max or a defined limit)
                uint256 maxEntropy = 1e24; // Arbitrary cap
                uint256 increasedEntropy = _currentEntropy + uint256(entropyDelta);
                return increasedEntropy > maxEntropy ? maxEntropy : increasedEntropy;
            } else if (entropyDelta < 0) {
                // Subtract entropy, prevent underflow below 0
                uint256 decreaseAmount = uint256(-entropyDelta);
                return _currentEntropy > decreaseAmount ? _currentEntropy - decreaseAmount : 0;
            } else {
                return _currentEntropy; // No change
            }
        }
    }

    /**
     * @dev Internal function to mark a fluctuation as decayed.
     * Called when stability reaches zero.
     * @param _id The ID of the Fluctuation to decay.
     */
    function _decayFluctuationInternal(uint256 _id) internal {
        Fluctuation storage fluctuation = fluctuations[_id];
        fluctuation.isDecayed = true;
        fluctuation.isEntangled = false; // Decayed fluctuations cannot remain entangled
        fluctuation.entangledWithId = 0;

        // Decay might slightly reduce entropy as the state simplifies
        uint256 oldEntropy = currentFoundryEntropy;
        currentFoundryEntropy = currentFoundryEntropy > 5 ? currentFoundryEntropy - 5 : 0; // Example reduction

        emit FluctuationDecayed(_id, 0);
    }

    // --- Fallback/Receive ---
     receive() external payable {
        // Optional: Handle raw Ether payments, maybe add slightly to entropy
        if (msg.value > 0) {
             uint256 oldEntropy = currentFoundryEntropy;
            // Add a tiny bit of entropy for unsolicited Ether (random noise)
            currentFoundryEntropy = _calculateEntropyChange(oldEntropy, msg.value, true);
        }
    }

    fallback() external payable {
        // Optional: Handle calls to undefined functions, maybe revert or log
        revert("FF: Call to undefined function");
    }
}
```