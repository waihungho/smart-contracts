Okay, let's create a smart contract with some interesting, non-standard mechanics inspired by concepts like decay, resonance, and state changes, metaphorically drawing from physics. We'll call it `QuantumEcho`.

This contract will allow users to deposit ETH to create unique "Echoes". These Echoes have properties like Resonance (their inherent value/strength) and a Decay Rate. Resonance decays over time, but users can interact ("Resonate") with their Echoes to slow decay or gain temporary boosts. Echoes can also be "Entangled" in pairs, linking their fates. Finally, an Echo's state can be "Collapsed", stabilizing its Resonance but ending its dynamic properties. Users can harvest value based on Resonance or withdraw their initial collateral, actions which typically cause a state collapse.

---

**QuantumEcho Smart Contract**

**Outline:**

1.  **Contract Overview:** Manages unique "Echo" assets created by users depositing ETH. Echoes have dynamic properties (Resonance, Decay) and states (Quantum, Entangled, Collapsed).
2.  **Data Structures:**
    *   `EchoState` Enum: Defines the lifecycle state of an Echo (Quantum, Collangled, Collapsed).
    *   `Echo` Struct: Holds all properties for a single Echo (owner, state, resonance, decay rate, timestamps, linked echo ID, initial collateral).
3.  **State Variables:** Storage for Echo data, user-to-echo mapping, configuration parameters, fees, and owner.
4.  **Events:** To signal important actions and state changes.
5.  **Error Handling:** Custom errors for clarity and gas efficiency (Solidity 0.8+).
6.  **Access Control:** Standard `Ownable` pattern for administrative functions.
7.  **Core Mechanics:**
    *   Creation of Echoes (deposit ETH).
    *   Resonance Decay (calculated on access).
    *   Resonating (interaction, potentially slowing decay/boosting resonance).
    *   Entangling/Disentangling Echoes (linking state).
    *   State Collapse (stopping decay, fixing resonance).
    *   Harvesting Resonance (extracting value based on current resonance).
    *   Withdrawing Collateral (reclaiming initial deposit).
8.  **Internal Helpers:** Functions to manage state updates, decay calculation, user echo lists.
9.  **Public/External Functions:** User-facing interactions and administrative calls.
10. **View Functions:** Read-only functions to query contract state and Echo properties.

**Function Summary:**

*   `constructor()`: Initializes contract owner and default parameters.
*   `createEcho()`: User function to deposit ETH and mint a new Echo.
*   `resonate(uint256 echoId)`: User function to interact with an Echo, updating its state and potentially applying effects. Requires a fee.
*   `entangle(uint256 echoId1, uint256 echoId2)`: User function to link two of their Quantum Echoes.
*   `disentangle(uint256 echoId)`: User function to break the entanglement of an Echo.
*   `collapseState(uint256 echoId)`: User function to force an Echo into the Collapsed state.
*   `harvestResonance(uint256 echoId)`: User function to extract value based on an Echo's current Resonance and collapse its state.
*   `withdrawCollateral(uint256 echoId)`: User function to withdraw the initial ETH deposit, collapsing the Echo's state.
*   `setEchoDecayRate(uint256 echoId, uint256 newRateBps)`: User function (potentially conditional) to modify their Echo's individual decay rate.
*   `applyExternalImpulse(uint256 echoId, uint256 impulseValue)`: Owner/privileged function to externally influence an Echo's resonance (e.g., for governance rewards or events).
*   `calculateCurrentResonance(uint256 echoId)`: View function to calculate an Echo's resonance considering decay *without* changing state.
*   `getUserEchoes(address owner)`: View function to list all Echo IDs owned by an address.
*   `getEchoDetails(uint256 echoId)`: View function to retrieve all properties of an Echo.
*   `isEntangled(uint256 echoId)`: View function to check if an Echo is entangled.
*   `getEntangledLink(uint256 echoId)`: View function to get the linked Echo ID.
*   `getEchoStateEnum(uint256 echoId)`: View function to get the state enum of an Echo.
*   `getTotalEchoes()`: View function for the total number of Echoes created.
*   `getContractStateSummary()`: View function for global contract statistics (total collateral, fees, etc.).
*   `setBaseDecayRate(uint256 rateBps)`: Owner function to set the default decay rate for *new* Echoes.
*   `setResonationFee(uint256 fee)`: Owner function to set the fee required for `resonate`.
*   `setEntanglementBonusRate(uint256 bonusBps)`: Owner function to set how much entanglement reduces effective decay.
*   `setCollapsePenaltyRate(uint256 penaltyBps)`: Owner function to set the percentage penalty on resonance upon collapse.
*   `withdrawContractFees()`: Owner function to withdraw accumulated fees.
*   `transferOwnership(address newOwner)`: Standard Ownable function.
*   `renounceOwnership()`: Standard Ownable function.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/// @title QuantumEcho
/// @author YourNameHere (replace with your name/alias)
/// @notice A smart contract simulating quantum-inspired dynamics (Decay, Resonance, Entanglement, Collapse) on unique user-created "Echo" assets.
/// @dev Echoes are non-transferable NFTs within the contract until potentially wrapped or withdrawn. Value is tied to Resonance and initial collateral.

// --- Outline ---
// 1. Contract Overview: Manages unique "Echo" assets with dynamic properties.
// 2. Data Structures: EchoState Enum, Echo Struct.
// 3. State Variables: Echo data storage, user-to-echo mapping, configuration, fees, owner.
// 4. Events: Signalling key actions.
// 5. Error Handling: Custom errors.
// 6. Access Control: Ownable.
// 7. Core Mechanics: Creation, Decay, Resonating, Entanglement, Collapse, Harvesting, Withdrawal.
// 8. Internal Helpers: State update, list management.
// 9. Public/External Functions: User interactions, admin.
// 10. View Functions: Read-only queries.

// --- Function Summary ---
// constructor(): Initializes owner and default parameters.
// createEcho(): User function to deposit ETH and mint a new Echo.
// resonate(uint256 echoId): Interact with Echo, update state, apply effects. Requires fee.
// entangle(uint256 echoId1, uint256 echoId2): Link two user-owned Quantum Echoes.
// disentangle(uint256 echoId): Break entanglement of an Echo.
// collapseState(uint256 echoId): Force Echo into Collapsed state.
// harvestResonance(uint256 echoId): Extract value based on Resonance, collapse state.
// withdrawCollateral(uint256 echoId): Withdraw initial deposit, collapse state.
// setEchoDecayRate(uint256 echoId, uint256 newRateBps): Modify specific Echo's decay rate (conditional).
// applyExternalImpulse(uint256 echoId, uint256 impulseValue): Owner/privileged func to influence resonance externally.
// calculateCurrentResonance(uint256 echoId): View func to calculate resonance with decay (no state change).
// getUserEchoes(address owner): View func listing Echo IDs owned by an address.
// getEchoDetails(uint256 echoId): View func retrieving all Echo properties.
// isEntangled(uint256 echoId): View func check if Echo is entangled.
// getEntangledLink(uint256 echoId): View func get linked Echo ID.
// getEchoStateEnum(uint256 echoId): View func get state enum.
// getTotalEchoes(): View func for total Echo count.
// getContractStateSummary(): View func for global stats.
// setBaseDecayRate(uint256 rateBps): Owner func set default decay rate for new Echoes.
// setResonationFee(uint256 fee): Owner func set resonate fee.
// setEntanglementBonusRate(uint256 bonusBps): Owner func set entanglement bonus effect (decay reduction).
// setCollapsePenaltyRate(uint256 penaltyBps): Owner func set resonance penalty on collapse.
// withdrawContractFees(): Owner func withdraw accumulated fees.
// transferOwnership(address newOwner): Ownable func.
// renounceOwnership(): Ownable func.


contract QuantumEcho is Ownable {
    using Address for address payable;
    using Math for uint256; // Using safe math functions if needed, OpenZeppelin includes this

    // --- Errors ---
    error InvalidEchoId();
    error NotEchoOwner();
    error NotQuantumState();
    error NotEntangledState();
    error AlreadyEntangled();
    error CannotEntangleSameEcho();
    error EntanglementRequiresTwoEchoes();
    error AlreadyCollapsed();
    error InsufficientResonationFee();
    error DecayRateTooHigh();
    error ZeroResonance();
    error NotEnoughFees();
    error EchoAlreadyHasLinkedEcho();
    error EchoHasNoLinkedEcho();


    // --- Data Structures ---

    enum EchoState {
        Quantum,     // Active, decaying, can be entangled or resonated
        Entangled,   // Linked to another Echo, potentially different decay/resonance effects
        Collapsed    // State is fixed, no more decay or dynamic changes
    }

    struct Echo {
        address owner;
        uint256 creationTime;
        uint256 lastInteractionTime; // Timestamp used for decay calculation reference
        uint256 initialCollateral;   // Original ETH deposit
        uint256 currentResonance;    // Dynamic value, decays over time
        uint256 decayRateBps;        // Decay rate in Basis Points (e.g., 100 = 1% per second scaling unit)
        uint256 entangledLink;       // ID of the linked Echo if state is Entangled, 0 otherwise
        EchoState state;
    }

    // --- State Variables ---

    mapping(uint256 => Echo) private echoes;
    mapping(address => uint256[] ) private userEchoes; // List of Echo IDs per user (simple array for iteration, might have gas costs for many echoes per user)
    uint256 private nextEchoId = 1; // Start from 1, 0 indicates no link/invalid ID

    uint256 private baseDecayRateBps = 1; // Default decay rate for new echoes (0.01% per second scale unit)
    uint256 private resonationFee = 0.001 ether; // Fee to resonate with an echo
    uint256 private entanglementBonusRateBps = 200; // 20% effective decay reduction when entangled
    uint256 private collapsePenaltyRateBps = 500; // 50% penalty on resonance when state collapses

    uint256 private totalContractFees = 0; // Accumulated resonation fees

    uint256 private constant RESONANCE_SCALE = 1e18; // Scale for resonance calculation, same as ETH/Wei


    // --- Events ---

    event EchoCreated(uint256 indexed echoId, address indexed owner, uint256 initialCollateral, uint256 initialResonance, uint256 creationTime);
    event EchoResonated(uint256 indexed echoId, address indexed user, uint256 feePaid, uint256 currentResonanceAfter);
    event EchoEntangled(uint256 indexed echoId1, uint256 indexed echoId2, address indexed user);
    event EchoDisentangled(uint256 indexed echoId1, uint256 indexed echoId2, address indexed user);
    event EchoStateCollapsed(uint256 indexed echoId, address indexed user, uint256 resonanceBeforePenalty, uint256 resonanceAfterPenalty);
    event ResonanceHarvested(uint256 indexed echoId, address indexed user, uint256 amountHarvested, uint256 remainingResonance);
    event CollateralWithdrawn(uint256 indexed echoId, address indexed user, uint256 amountWithdrawn);
    event EchoDecayRateSet(uint256 indexed echoId, address indexed user, uint256 newRateBps);
    event ExternalImpulseApplied(uint256 indexed echoId, address indexed sender, uint256 impulseValue, uint256 newResonance);
    event BaseDecayRateSet(uint256 oldRateBps, uint256 newRateBps);
    event ResonationFeeSet(uint256 oldFee, uint256 newFee);
    event EntanglementBonusRateSet(uint256 oldBonusBps, uint256 newBonusBps);
    event CollapsePenaltyRateSet(uint256 oldPenaltyBps, uint256 newPenaltyBps);
    event FeesWithdrawn(address indexed owner, uint256 amount);


    // --- Constructor ---

    constructor() Ownable(msg.sender) {
        // Initial parameters set as state variables default values
    }


    // --- Internal Helpers ---

    /// @dev Calculates the effective decay rate considering state (e.g., Entangled)
    /// @param echo The Echo struct
    /// @return The effective decay rate in basis points
    function _calculateEffectiveDecayRateBps(Echo storage echo) internal view returns (uint256) {
        if (echo.state == EchoState.Entangled && echo.decayRateBps > 0) {
             // Reduce decay rate by entanglement bonus percentage
             // Ensure result is not negative or zero if bonus is >= 10000 Bps (100%)
             return echo.decayRateBps.mul(10000 - entanglementBonusRateBps) / 10000;
        }
        return echo.decayRateBps;
    }

    /// @dev Calculates and applies decay to an Echo's resonance based on time elapsed since last interaction.
    /// Updates lastInteractionTime and currentResonance.
    /// @param echoId The ID of the Echo to update.
    function _updateEchoState(uint256 echoId) internal {
        Echo storage echo = echoes[echoId];
        if (echo.state == EchoState.Collapsed) {
            // Collapsed echoes do not decay
            return;
        }

        uint256 timeElapsed = block.timestamp - echo.lastInteractionTime;
        if (timeElapsed == 0) {
            // No time has passed, no decay
            return;
        }

        uint256 effectiveDecayRate = _calculateEffectiveDecayRateBps(echo);

        // Decay amount = Resonance * DecayRate * Time / (Scale Unit for Decay * 10000 for Bps)
        // Let's assume DecayRateBps is per second scaled by RESONANCE_SCALE
        // Decay per second = resonance * rateBps / 10000
        // Total Decay = decay per second * timeElapsed
        uint256 decayAmount = echo.currentResonance.mul(effectiveDecayRate).mul(timeElapsed) / 10000; // Base Bps 10000 for percentage

        // Prevent resonance from going below zero
        echo.currentResonance = echo.currentResonance > decayAmount ? echo.currentResonance - decayAmount : 0;

        echo.lastInteractionTime = block.timestamp;
    }

    /// @dev Adds an Echo ID to a user's list of echoes.
    /// @param owner The owner's address.
    /// @param echoId The Echo ID to add.
    function _addEchoToUserList(address owner, uint256 echoId) internal {
         userEchoes[owner].push(echoId);
    }

    /// @dev Removes an Echo ID from a user's list. Note: This can be gas-intensive if list is large.
    /// For simplicity, we iterate and swap with last element.
    /// @param owner The owner's address.
    /// @param echoId The Echo ID to remove.
    function _removeEchoFromUserList(address owner, uint256 echoId) internal {
        uint256[] storage userEchoList = userEchoes[owner];
        for (uint i = 0; i < userEchoList.length; i++) {
            if (userEchoList[i] == echoId) {
                // Swap with the last element and pop
                userEchoList[i] = userEchoList[userEchoList.length - 1];
                userEchoList.pop();
                return; // Found and removed
            }
        }
        // Should not happen if logic is correct, but good practice
        revert InvalidEchoId();
    }

    /// @dev Breaks the entanglement link for a given Echo and its linked Echo.
    /// @param echoId The ID of the Echo.
    function _disentangleEcho(uint256 echoId) internal {
        Echo storage echo = echoes[echoId];
        if (echo.state != EchoState.Entangled) {
            // Not entangled, nothing to do
            return;
        }

        uint256 linkedEchoId = echo.entangledLink;
        if (linkedEchoId != 0 && echoes[linkedEchoId].entangledLink == echoId) {
             // Disentangle the linked echo as well
            Echo storage linkedEcho = echoes[linkedEchoId];

            // Update states - if one is collapsing, the other might revert to Quantum
            linkedEcho.state = EchoState.Quantum;
            linkedEcho.entangledLink = 0;

            emit EchoDisentangled(linkedEchoId, echoId, echo.owner); // Assuming same owner for entangled pair
        }

        echo.state = EchoState.Quantum; // Revert to Quantum state after disentanglement
        echo.entangledLink = 0;

        emit EchoDisentangled(echoId, linkedEchoId, echo.owner);
    }


    // --- Public/External Functions ---

    /// @notice Creates a new Echo for the sender, funded by deposited ETH.
    /// @dev The amount of ETH deposited directly translates to the initial Resonance.
    /// @return The ID of the newly created Echo.
    receive() external payable {
        if (msg.value == 0) {
            revert("Must send ETH to create an Echo");
        }
        // Allow creation via receive/fallback
        uint256 newEchoId = nextEchoId++;
        uint256 initialResonance = msg.value; // Initial Resonance = deposited ETH

        echoes[newEchoId] = Echo({
            owner: msg.sender,
            creationTime: block.timestamp,
            lastInteractionTime: block.timestamp,
            initialCollateral: msg.value,
            currentResonance: initialResonance,
            decayRateBps: baseDecayRateBps,
            entangledLink: 0,
            state: EchoState.Quantum
        });

        _addEchoToUserList(msg.sender, newEchoId);

        emit EchoCreated(newEchoId, msg.sender, msg.value, initialResonance, block.timestamp);
    }

    function createEcho() external payable {
         // Delegate to receive function
         this.receive{value: msg.value}();
    }


    /// @notice Interacts with an Echo, updating its state, applying decay, and providing a small boost or decay reduction.
    /// @dev Requires payment of the `resonationFee`.
    /// @param echoId The ID of the Echo to resonate with.
    function resonate(uint256 echoId) external payable {
        Echo storage echo = echoes[echoId];
        if (echo.owner == address(0)) revert InvalidEchoId();
        if (echo.owner != msg.sender) revert NotEchoOwner();
        if (echo.state == EchoState.Collapsed) revert AlreadyCollapsed();
        if (msg.value < resonationFee) revert InsufficientResonationFee();

        // Apply decay before interaction effects
        _updateEchoState(echoId);

        // Pay the resonation fee
        totalContractFees += msg.value; // Add fee to contract balance

        // Apply resonance boost/decay reduction effect
        // Example: Add a small percentage of current resonance back, or temporarily reduce decay rate
        // Let's add a small fixed amount + a percentage boost relative to fee paid
        uint256 boost = resonationFee / 10 + msg.value / 100; // Example calculation
        echo.currentResonance += boost; // Increase resonance

        // Optionally, could also temporarily set a lower decay rate for a period,
        // but state management becomes more complex. A simple boost is easier.

        emit EchoResonated(echoId, msg.sender, msg.value, echo.currentResonance);
    }

    /// @notice Entangles two of the sender's Quantum Echoes.
    /// @dev Both Echoes must be owned by the sender, in the Quantum state, and not already entangled.
    /// @param echoId1 The ID of the first Echo.
    /// @param echoId2 The ID of the second Echo.
    function entangle(uint256 echoId1, uint256 echoId2) external {
        if (echoId1 == 0 || echoId2 == 0) revert InvalidEchoId();
        if (echoId1 == echoId2) revert CannotEntangleSameEcho();

        Echo storage echo1 = echoes[echoId1];
        Echo storage echo2 = echoes[echoes[echoId2].entangledLink]; // This is wrong. Access echo2 directly.
        Echo storage echo2_direct = echoes[echoId2]; // Correct access

        if (echo1.owner == address(0) || echo2_direct.owner == address(0)) revert InvalidEchoId();
        if (echo1.owner != msg.sender || echo2_direct.owner != msg.sender) revert NotEchoOwner();

        if (echo1.state != EchoState.Quantum) revert NotQuantumState();
        if (echo2_direct.state != EchoState.Quantum) revert NotQuantumState();

        if (echo1.entangledLink != 0) revert AlreadyEntangled();
        if (echo2_direct.entangledLink != 0) revert AlreadyEntangled();

        // Apply decay before entanglement
        _updateEchoState(echoId1);
        _updateEchoState(echoId2);

        // Link them
        echo1.entangledLink = echoId2;
        echo2_direct.entangledLink = echoId1;

        // Update states
        echo1.state = EchoState.Entangled;
        echo2_direct.state = EchoState.Entangled;

        emit EchoEntangled(echoId1, echoId2, msg.sender);
    }


    /// @notice Breaks the entanglement link for an Entangled Echo.
    /// @param echoId The ID of the Entangled Echo.
    function disentangle(uint256 echoId) external {
         if (echoId == 0) revert InvalidEchoId();
         Echo storage echo = echoes[echoId];
         if (echo.owner == address(0)) revert InvalidEchoId();
         if (echo.owner != msg.sender) revert NotEchoOwner();
         if (echo.state != EchoState.Entangled) revert NotEntangledState();
         if (echo.entangledLink == 0) revert EchoHasNoLinkedEcho(); // Should not happen if state is Entangled

         // Apply decay before disentangling
         _updateEchoState(echoId);
         _updateEchoState(echo.entangledLink); // Update the linked echo as well

         _disentangleEcho(echoId); // This helper handles updating both sides and states
    }


    /// @notice Forces an Echo into the Collapsed state.
    /// @dev Collapsed Echoes stop decaying but incur a penalty to current Resonance.
    /// @param echoId The ID of the Echo to collapse.
    function collapseState(uint256 echoId) external {
        if (echoId == 0) revert InvalidEchoId();
        Echo storage echo = echoes[echoId];
        if (echo.owner == address(0)) revert InvalidEchoId();
        if (echo.owner != msg.sender) revert NotEchoOwner();
        if (echo.state == EchoState.Collapsed) revert AlreadyCollapsed();

        // Apply decay before collapsing
        _updateEchoState(echoId);

        uint256 resonanceBeforePenalty = echo.currentResonance;

        // Apply collapse penalty
        uint256 penaltyAmount = echo.currentResonance.mul(collapsePenaltyRateBps) / 10000;
        echo.currentResonance = echo.currentResonance > penaltyAmount ? echo.currentResonance - penaltyAmount : 0;

        // Disentangle if necessary
        if (echo.state == EchoState.Entangled) {
            _disentangleEcho(echoId); // Note: this changes echo.state to Quantum temporarily before setting it to Collapsed below
        }

        echo.state = EchoState.Collapsed;

        emit EchoStateCollapsed(echoId, msg.sender, resonanceBeforePenalty, echo.currentResonance);
    }

    /// @notice Harvests the current Resonance value of an Echo as ETH and collapses its state.
    /// @dev The amount of ETH transferred is equal to the Echo's current Resonance (scaled).
    /// @param echoId The ID of the Echo to harvest.
    function harvestResonance(uint256 echoId) external {
        if (echoId == 0) revert InvalidEchoId();
        Echo storage echo = echoes[echoId];
        if (echo.owner == address(0)) revert InvalidEchoId();
        if (echo.owner != msg.sender) revert NotEchoOwner();
        if (echo.state == EchoState.Collapsed) revert AlreadyCollapsed();

        // Apply decay before harvesting
        _updateEchoState(echoId);

        uint256 amountToHarvest = echo.currentResonance;
        if (amountToHarvest == 0) revert ZeroResonance();

        // Zero out resonance and collapse state BEFORE transfer
        echo.currentResonance = 0;

        // Disentangle if necessary
         if (echo.state == EchoState.Entangled) {
            _disentangleEcho(echoId);
        }
        echo.state = EchoState.Collapsed;


        // Send the ETH
        // Use call instead of transfer/send for reentrancy prevention and gas limit
        (bool success, ) = payable(msg.sender).call{value: amountToHarvest}("");
        require(success, "Harvest ETH transfer failed");

        emit ResonanceHarvested(echoId, msg.sender, amountToHarvest, echo.currentResonance);
    }

    /// @notice Withdraws the initial collateral deposited for an Echo and collapses its state.
    /// @dev Cannot be called if the state is already Collapsed (implying harvest or prior withdrawal).
    /// @param echoId The ID of the Echo whose collateral to withdraw.
    function withdrawCollateral(uint256 echoId) external {
        if (echoId == 0) revert InvalidEchoId();
        Echo storage echo = echoes[echoId];
        if (echo.owner == address(0)) revert InvalidEchoId();
        if (echo.owner != msg.sender) revert NotEchoOwner();
        if (echo.state == EchoState.Collapsed) revert AlreadyCollapsed(); // Can't withdraw after collapse/harvest

        uint256 amountToWithdraw = echo.initialCollateral;
        if (amountToWithdraw == 0) {
             // Should not happen for valid Echoes, but handle defensively
             revert("No initial collateral to withdraw");
        }

        // Apply decay before withdrawal (decay applies to resonance, not collateral, but updates timestamp)
        _updateEchoState(echoId);

        // Zero out collateral and resonance, and collapse state BEFORE transfer
        echo.initialCollateral = 0;
        echo.currentResonance = 0;

        // Disentangle if necessary
         if (echo.state == EchoState.Entangled) {
            _disentangleEcho(echoId);
        }
        echo.state = EchoState.Collapsed;

        // Send the ETH
        (bool success, ) = payable(msg.sender).call{value: amountToWithdraw}("");
        require(success, "Collateral ETH transfer failed");

        emit CollateralWithdrawn(echoId, msg.sender, amountToWithdraw);
    }


    /// @notice Allows the owner of a Quantum/Entangled Echo to set a custom decay rate for it.
    /// @dev Rate is in Basis Points. May have restrictions (e.g., cannot be zero unless collapsed, cannot be excessively high).
    /// @param echoId The ID of the Echo to modify.
    /// @param newRateBps The new decay rate in Basis Points.
    function setEchoDecayRate(uint256 echoId, uint256 newRateBps) external {
        if (echoId == 0) revert InvalidEchoId();
        Echo storage echo = echoes[echoId];
        if (echo.owner == address(0)) revert InvalidEchoId();
        if (echo.owner != msg.sender) revert NotEchoOwner();
        if (echo.state == EchoState.Collapsed) revert AlreadyCollapsed(); // Cannot change rate if collapsed

        // Add validation for rate (e.g., not excessively high)
        uint256 MAX_DECAY_RATE_BPS = 10000; // Example: Max 100% decay per second scale unit
        if (newRateBps > MAX_DECAY_RATE_BPS) revert DecayRateTooHigh();

        // Apply decay before changing rate
        _updateEchoState(echoId);

        echo.decayRateBps = newRateBps;
        emit EchoDecayRateSet(echoId, msg.sender, newRateBps);
    }

    /// @notice Allows the contract owner or other privileged address to apply an external impulse to an Echo's resonance.
    /// @dev This could simulate external events or governance actions affecting Echoes.
    /// Requires specific access control (here using Ownable).
    /// @param echoId The ID of the Echo to modify.
    /// @param impulseValue The amount of resonance to add or subtract (signed value concept, here just adding).
    function applyExternalImpulse(uint256 echoId, uint256 impulseValue) external onlyOwner {
        if (echoId == 0) revert InvalidEchoId();
        Echo storage echo = echoes[echoId];
        if (echo.owner == address(0)) revert InvalidEchoId();
        // Allow impulse even on Collapsed state? Or only dynamic? Let's allow on Quantum/Entangled.
        if (echo.state == EchoState.Collapsed) revert AlreadyCollapsed();

        // Apply decay before impulse
        _updateEchoState(echoId);

        // Apply the impulse
        echo.currentResonance += impulseValue; // Assuming impulseValue is positive for adding

        emit ExternalImpulseApplied(echoId, msg.sender, impulseValue, echo.currentResonance);
    }


    // --- View Functions ---

    /// @notice Calculates the current Resonance of an Echo including decay up to the current block timestamp.
    /// @dev This is a view function and does NOT change the Echo's state or update timestamps.
    /// @param echoId The ID of the Echo to query.
    /// @return The calculated current resonance value.
    function calculateCurrentResonance(uint256 echoId) public view returns (uint256) {
        Echo storage echo = echoes[echoId];
        if (echo.owner == address(0)) return 0; // Invalid ID

        if (echo.state == EchoState.Collapsed) {
            return echo.currentResonance; // Collapsed state is fixed
        }

        uint256 timeElapsed = block.timestamp - echo.lastInteractionTime;
        if (timeElapsed == 0) {
            return echo.currentResonance; // No time has passed
        }

        uint256 effectiveDecayRate = _calculateEffectiveDecayRateBps(echo);

        uint256 potentialDecayAmount = echo.currentResonance.mul(effectiveDecayRate).mul(timeElapsed) / 10000;

        // Return calculated resonance, capped at zero
        return echo.currentResonance > potentialDecayAmount ? echo.currentResonance - potentialDecayAmount : 0;
    }

    /// @notice Gets a list of Echo IDs owned by a specific address.
    /// @dev Note: This might be gas-intensive for callers if a user owns a very large number of Echoes.
    /// @param owner The address to query.
    /// @return An array of Echo IDs.
    function getUserEchoes(address owner) external view returns (uint256[] memory) {
        return userEchoes[owner];
    }

    /// @notice Retrieves all detailed properties for a given Echo ID.
    /// @param echoId The ID of the Echo to query.
    /// @return A tuple containing all Echo struct fields.
    function getEchoDetails(uint256 echoId) external view returns (
        address owner,
        EchoState state,
        uint256 creationTime,
        uint256 lastInteractionTime,
        uint256 initialCollateral,
        uint256 currentResonance, // Note: This is the *stored* resonance, use calculateCurrentResonance for decay adjusted value
        uint256 decayRateBps,
        uint256 entangledLink
    ) {
        Echo storage echo = echoes[echoId];
        if (echo.owner == address(0)) revert InvalidEchoId(); // Or return zeroed struct

        return (
            echo.owner,
            echo.state,
            echo.creationTime,
            echo.lastInteractionTime,
            echo.initialCollateral,
            echo.currentResonance,
            echo.decayRateBps,
            echo.entangledLink
        );
    }

    /// @notice Checks if a specific Echo is currently entangled.
    /// @param echoId The ID of the Echo to check.
    /// @return True if Entangled, false otherwise.
    function isEntangled(uint256 echoId) external view returns (bool) {
        if (echoId == 0) return false;
        return echoes[echoId].state == EchoState.Entangled;
    }

    /// @notice Gets the ID of the Echo linked by entanglement.
    /// @param echoId The ID of the Echo.
    /// @return The ID of the linked Echo, or 0 if not entangled or invalid ID.
    function getEntangledLink(uint256 echoId) external view returns (uint256) {
        if (echoId == 0) return 0;
        return echoes[echoId].entangledLink;
    }

    /// @notice Gets the current state enum of an Echo.
    /// @param echoId The ID of the Echo.
    /// @return The EchoState enum value.
    function getEchoStateEnum(uint256 echoId) external view returns (EchoState) {
        if (echoId == 0) revert InvalidEchoId();
        return echoes[echoId].state;
    }

    /// @notice Gets the total number of Echoes that have been created.
    /// @return The total count.
    function getTotalEchoes() external view returns (uint256) {
        return nextEchoId - 1; // nextEchoId is the ID for the *next* echo
    }

    /// @notice Gets a summary of the contract's overall state.
    /// @return totalCreatedEchoes, totalInitialCollateral (locked in un-withdrawn echoes), totalFeesCollected.
    function getContractStateSummary() external view returns (uint256 totalCreatedEchoes, uint256 totalContractCollateral, uint256 totalFeesCollected) {
         // Calculating total locked collateral requires iterating through all *non-collapsed* or *un-withdrawn* echoes.
         // This is computationally expensive. Let's return what's easily available.
         // Returning total ETH balance might be misleading as it includes fees.
         // Let's just return total fees and total echoes created, and leave collateral check per-echo.
         return (nextEchoId - 1, address(this).balance - totalContractFees, totalContractFees);
         // Note: address(this).balance - totalContractFees is a rough estimate of potential un-withdrawn collateral.
         // A precise calculation would require summing initialCollateral for all non-collapsed, non-withdrawn echoes,
         // which is not gas-efficient as a view function.
    }


    // --- Owner Functions ---

    /// @notice Sets the base decay rate for *newly created* Echoes.
    /// @dev Rate is in Basis Points (1/100th of a percent).
    /// @param rateBps The new base decay rate in Basis Points.
    function setBaseDecayRate(uint256 rateBps) external onlyOwner {
        uint256 oldRate = baseDecayRateBps;
        baseDecayRateBps = rateBps;
        emit BaseDecayRateSet(oldRate, baseDecayRateBps);
    }

    /// @notice Sets the fee required for the `resonate` function.
    /// @param fee The new fee amount in Wei.
    function setResonationFee(uint256 fee) external onlyOwner {
        uint256 oldFee = resonationFee;
        resonationFee = fee;
        emit ResonationFeeSet(oldFee, resonationFee);
    }

    /// @notice Sets the bonus rate applied to effective decay when Echoes are entangled.
    /// @dev Rate in Basis Points. Higher rate means more decay reduction for entangled Echoes. Max 10000 Bps (100%).
    /// @param bonusBps The new entanglement bonus rate in Basis Points.
    function setEntanglementBonusRate(uint256 bonusBps) external onlyOwner {
        if (bonusBps > 10000) revert("Entanglement bonus cannot exceed 100%");
        uint256 oldRate = entanglementBonusRateBps;
        entanglementBonusRateBps = bonusBps;
        emit EntanglementBonusRateSet(oldRate, entanglementBonusRateBps);
    }

    /// @notice Sets the percentage penalty applied to Resonance when an Echo's state collapses.
    /// @dev Rate in Basis Points. Max 10000 Bps (100%).
    /// @param penaltyBps The new collapse penalty rate in Basis Points.
    function setCollapsePenaltyRate(uint256 penaltyBps) external onlyOwner {
         if (penaltyBps > 10000) revert("Collapse penalty cannot exceed 100%");
        uint256 oldRate = collapsePenaltyRateBps;
        collapsePenaltyRateBps = penaltyBps;
        emit CollapsePenaltyRateSet(oldRate, collapsePenaltyRateBps);
    }


    /// @notice Allows the contract owner to withdraw accumulated resonation fees.
    function withdrawContractFees() external onlyOwner {
        uint256 fees = totalContractFees;
        if (fees == 0) revert NotEnoughFees();

        totalContractFees = 0; // Zero out BEFORE transfer

        (bool success, ) = payable(owner()).call{value: fees}("");
        require(success, "Fee withdrawal failed");

        emit FeesWithdrawn(owner(), fees);
    }

    // Override Ownable functions to use custom errors if desired, or just use inherited.
    // Using inherited for simplicity here.
    // function transferOwnership(address newOwner) public override onlyOwner { super.transferOwnership(newOwner); }
    // function renounceOwnership() public override onlyOwner { super.renounceOwnership(); }

}
```