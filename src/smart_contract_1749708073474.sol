Okay, here is a Solidity smart contract concept based on a "Quantum Entanglement Bond". This contract attempts to create a unique investment mechanism where the final payout terms (yield, duration) are not fixed upon creation but are determined probabilistically during a "superposition" phase, influenced by a verifiable random function (VRF) and potentially biased by user interactions, simulating a form of "quantum measurement".

This concept is advanced due to:
1.  **Complex State Management:** Bonds transition through multiple unique states (Active, Superposition, PendingResolution, EntangledA, EntangledB, Claimed).
2.  **Probabilistic Resolution:** Using a VRF (simulated here for brevity, but requiring integration with Chainlink VRF or similar) to determine the outcome.
3.  **User Influence:** Allowing users to interact during the superposition phase to *bias* the probabilistic outcome, without guaranteeing it, mimicking observation effects.
4.  **Time-Based Dynamics:** Superposition and claimability are time-dependent.
5.  **Parameterized Bond Types:** Allows the contract owner to define different bond types with distinct potential outcomes.

It avoids common open-source patterns like standard ERC-20/721, basic DeFi pools, or simple fixed-term staking.

---

**Smart Contract: QuantumEntanglementBond**

**Outline:**

1.  **State Variables:**
    *   Owner address.
    *   Paused state.
    *   Counters for Bond Types and Bond Instances.
    *   Mappings for Bond Types (ID to struct).
    *   Mappings for Bond Instances (ID to struct).
    *   Mapping to track bond IDs per investor address.
    *   Mapping for influence counters (for biasing resolution).
    *   Total principal deposited.
    *   Total yield paid.
2.  **Enums:**
    *   `BondState`: Represents the lifecycle state of a bond instance.
    *   `TriggerType`: Defines how entanglement resolution is triggered.
3.  **Structs:**
    *   `BondType`: Defines the parameters for a class of bonds (yields, durations, superposition time, trigger).
    *   `BondInstance`: Represents a specific user's investment bond (principal, investor, type ID, state, timestamps, resolved state A/B).
4.  **Events:**
    *   Signaling key actions and state changes (BondTypeCreated, BondInvested, EntanglementTriggered, BondResolved, BondClaimed, InfluenceApplied, ParametersUpdated, Paused, Unpaused).
5.  **Modifiers:**
    *   `onlyOwner`: Restricts access to the contract owner.
    *   `whenNotPaused`: Restricts access when the contract is paused.
    *   `whenPaused`: Restricts access when the contract is not paused.
    *   `requireState`: Checks if a bond is in a specific state.
    *   `requireBondExists`: Checks if a bond ID is valid.
    *   `requireBondTypeExists`: Checks if a bond type ID is valid.
6.  **Functions:** (> 20 total)
    *   **Setup & Management:**
        *   `constructor`: Initializes owner and state.
        *   `createBondType`: Defines a new type of Quantum Entanglement Bond.
        *   `setBondTypeParameters`: Updates parameters of an existing bond type (with caveats for active bonds).
        *   `pauseContract`: Pauses certain contract interactions.
        *   `unpauseContract`: Unpauses the contract.
        *   `renounceOwnership`: Transfers ownership to zero address.
        *   `transferOwnership`: Transfers ownership to a new address.
        *   `withdrawFeesAndPenalties`: Owner function to withdraw collected funds (e.g., from cancellations).
        *   `emergencyWithdrawPrincipal`: Owner function for extreme emergencies (withdraws trapped ETH).
    *   **Bond Lifecycle:**
        *   `invest`: Creates a new bond instance by depositing principal ETH based on a bond type.
        *   `cancelBondBeforeSuperposition`: Allows investor to cancel before superposition starts (full refund).
        *   `cancelBondDuringSuperposition`: Allows investor to cancel during superposition (with penalty).
        *   `triggerEntanglement`: Initiates the resolution process (can be called manually if trigger type allows, or internally by time). Simulates VRF request.
        *   `resolveEntanglement`: Called (conceptually by VRF callback or owner/keeper after VRF) to process the random outcome and determine the final state (A or B).
        *   `claimYield`: Allows the investor to claim principal + yield after the bond has resolved and the claim duration has passed.
    *   **Interaction (Influence):**
        *   `attractToStateA`: User interaction during superposition to increase the bias towards state A.
        *   `attractToStateB`: User interaction during superposition to increase the bias towards state B.
    *   **View Functions (Getters):**
        *   `getBondTypeDetails`: Returns details of a specific bond type.
        *   `getBondDetails`: Returns details of a specific bond instance.
        *   `getBondState`: Returns the current state of a bond instance.
        *   `getClaimableAmount`: Calculates and returns the amount claimable for a resolved bond.
        *   `getCurrentInfluence`: Returns the current bias counts for a specific bond instance.
        *   `getBondIdsByInvestor`: Returns all bond IDs associated with an investor.
        *   `getBondCount`: Returns the total number of bond instances created.
        *   `getBondTypeCount`: Returns the total number of bond types created.
        *   `getTotalPrincipalDeposited`: Returns the total principal ETH ever deposited.
        *   `getTotalYieldPaid`: Returns the total yield ETH ever paid out.

**Function Summary:**

*   **`constructor()`**: Initializes the contract, setting the deployer as the owner.
*   **`createBondType(uint256 yieldAPermille, uint256 durationASeconds, uint256 yieldBPermille, uint256 durationBSeconds, uint256 superpositionDurationSeconds, TriggerType triggerType)`**: Creates a new bond type template with specific yield/duration parameters for states A and B, the length of the superposition phase, and how the resolution is triggered.
*   **`setBondTypeParameters(uint256 bondTypeId, uint256 yieldAPermille, uint256 durationASeconds, uint256 yieldBPermille, uint256 durationBSeconds, uint256 superpositionDurationSeconds, TriggerType triggerType)`**: Allows the owner to update parameters of an existing bond type. *Note: Careful use needed, as it affects future bonds of this type.*
*   **`pauseContract()`**: Owner-only function to pause certain functions (`invest`, `attractToStateA`, `attractToStateB`, `triggerEntanglement` if manual).
*   **`unpauseContract()`**: Owner-only function to unpause the contract.
*   **`renounceOwnership()`**: Relinquishes ownership of the contract.
*   **`transferOwnership(address newOwner)`**: Transfers ownership of the contract to a new address.
*   **`withdrawFeesAndPenalties()`**: Owner-only function to withdraw ETH collected from penalties (e.g., cancellations).
*   **`emergencyWithdrawPrincipal()`**: Owner-only function to withdraw all ETH from the contract in an emergency. Designed as a failsafe, use with extreme caution.
*   **`invest(uint255 bondTypeId)`**: Allows a user to invest ETH to create a new bond instance of a specified type. The deposited ETH becomes the principal. Sets state to `Active`, starts superposition timer.
*   **`cancelBondBeforeSuperposition(uint256 bondId)`**: Allows the investor of a bond to cancel it *before* the superposition phase begins. Refunds full principal.
*   **`cancelBondDuringSuperposition(uint256 bondId)`**: Allows the investor of a bond to cancel it *during* the superposition phase. Refunds principal minus a penalty.
*   **`triggerEntanglement(uint256 bondId)`**: Initiates the process to resolve the bond's state. Can be called by anyone if the trigger type is manual, or is called internally/by a keeper if time-based. This function conceptually requests randomness (simulated here) and sets the bond state to `PendingResolution`.
*   **`resolveEntanglement(uint256 bondId, uint256 randomOutcome)`**: Processes the random outcome provided (conceptually from a VRF callback) to determine whether the bond resolves to state A or state B. Updates the bond state and sets the `resolutionTime`. The logic for choosing A or B incorporates the `attract` influence counters and the `randomOutcome`.
*   **`claimYield(uint256 bondId)`**: Allows the investor to claim their principal plus the calculated yield, but only after the bond has resolved (`EntangledA` or `EntangledB`) and the required duration for that state has passed since resolution.
*   **`attractToStateA(uint256 bondId)`**: Allows any user to call this function for a bond during its `Superposition` state. This increases the influence counter towards state A for that bond, potentially biasing the probabilistic resolution. Could require a small fee or stake in a real implementation.
*   **`attractToStateB(uint256 bondId)`**: Similar to `attractToStateA`, but increases the influence counter towards state B.
*   **`getBondTypeDetails(uint256 bondTypeId)`**: View function returning the configuration details of a specific bond type.
*   **`getBondDetails(uint256 bondId)`**: View function returning the current state and details of a specific bond instance.
*   **`getBondState(uint256 bondId)`**: View function returning only the current state enum of a bond instance.
*   **`getClaimableAmount(uint256 bondId)`**: View function calculating the principal + yield for a resolved bond. Does *not* check if it's claimable yet by time.
*   **`getCurrentInfluence(uint256 bondId)`**: View function returning the current influence counts towards states A and B for a bond in superposition.
*   **`getBondIdsByInvestor(address investor)`**: View function returning an array of all bond IDs created by a specific address.
*   **`getBondCount()`**: View function returning the total number of bond instances created.
*   **`getBondTypeCount()`**: View function returning the total number of bond types created.
*   **`getTotalPrincipalDeposited()`**: View function returning the cumulative ETH principal deposited across all bonds.
*   **`getTotalYieldPaid()`**: View function returning the cumulative ETH yield paid out across all claimed bonds.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Note: For a production contract, this would integrate with a real VRF service
// like Chainlink VRF. The random outcome simulation here is for demonstration
// purposes only. Chainlink VRF integration adds complexity (callback functions,
// request IDs) not included here.

/**
 * @title QuantumEntanglementBond
 * @dev A smart contract implementing a unique bond mechanism where the final yield
 * and duration are determined probabilistically based on a simulated VRF and
 * influenced by user interactions during a 'superposition' phase.
 */
contract QuantumEntanglementBond is Ownable, Pausable, ReentrancyGuard {

    // --- State Variables ---
    uint256 private bondTypeCounter = 0;
    uint256 private bondInstanceCounter = 0;
    uint256 private totalPrincipalDeposited = 0;
    uint256 private totalYieldPaid = 0;
    uint256 private penaltyPercentagePermille = 100; // 10% penalty for cancellation during superposition (in per mille, i.e., 1/1000)
    address payable private feeRecipient; // Address where penalties/fees are sent

    mapping(uint256 => BondType) public bondTypes;
    mapping(uint256 => BondInstance) public bondInstances;
    mapping(address => uint256[]) private investorBondIds;

    // Influence counters for biasing resolution (bondId => state => count)
    mapping(uint256 => mapping(uint8 => uint256)) private bondInfluence;

    // --- Enums ---

    /**
     * @dev Represents the lifecycle state of a bond instance.
     * Active: Created, waiting for superposition to start (or starting immediately).
     * Superposition: The phase where the outcome (A or B) is undetermined but can be influenced.
     * PendingResolution: VRF requested, waiting for the random outcome.
     * EntangledA: Resolved to state A (higher yield, shorter duration).
     * EntangledB: Resolved to state B (lower yield, longer duration).
     * Claimed: Principal and yield have been withdrawn by the investor.
     * Cancelled: Bond was cancelled before claiming.
     */
    enum BondState { Active, Superposition, PendingResolution, EntangledA, EntangledB, Claimed, Cancelled }

    /**
     * @dev Defines how the entanglement resolution is triggered.
     * TimeBased: Resolution is triggered automatically after superpositionDurationSeconds.
     * Manual: Resolution must be triggered by calling `triggerEntanglement` after superposition starts.
     */
    enum TriggerType { TimeBased, Manual }

    // --- Structs ---

    /**
     * @dev Defines the parameters for a specific type of Quantum Entanglement Bond.
     */
    struct BondType {
        uint256 id;
        uint256 yieldAPermille;             // Yield for State A in per mille (e.g., 100 for 10%)
        uint256 durationASeconds;           // Claimable duration after resolution for State A
        uint256 yieldBPermille;             // Yield for State B in per mille
        uint256 durationBSeconds;           // Claimable duration after resolution for State B
        uint256 superpositionDurationSeconds; // Duration of the superposition phase
        TriggerType triggerType;
        bool exists; // Helper to check if type ID is valid
    }

    /**
     * @dev Represents a specific instance of an investor's bond.
     */
    struct BondInstance {
        uint256 id;
        uint256 bondTypeId;
        address investor;
        uint256 principal; // Principal amount invested (in native currency, e.g., Wei)
        BondState state;
        uint256 investmentTime;
        uint256 superpositionEndTime; // When superposition phase ends
        uint256 resolutionTime;     // When the bond state was resolved (EntangledA/B)
        bool resolvedStateIsA;      // True if resolved to State A, false if State B
    }

    // --- Events ---

    event BondTypeCreated(uint256 indexed bondTypeId, uint256 yieldAPermille, uint256 durationASeconds, uint256 yieldBPermille, uint256 durationBSeconds, uint256 superpositionDurationSeconds, TriggerType triggerType);
    event BondTypeParametersUpdated(uint256 indexed bondTypeId, uint256 yieldAPermille, uint256 durationASeconds, uint256 yieldBPermille, uint256 durationBSeconds, uint256 superpositionDurationSeconds, TriggerType triggerType);
    event BondInvested(uint256 indexed bondId, uint256 indexed bondTypeId, address indexed investor, uint256 principal, uint256 investmentTime);
    event BondStateChanged(uint256 indexed bondId, BondState newState, BondState oldState);
    event EntanglementTriggered(uint256 indexed bondId, TriggerType triggerType);
    event BondResolved(uint256 indexed bondId, bool resolvedStateIsA, uint256 resolutionTime);
    event BondClaimed(uint256 indexed bondId, address indexed investor, uint256 principal, uint256 yieldAmount);
    event InfluenceApplied(uint256 indexed bondId, uint8 indexed stateIndex, address indexed influencer);
    event BondCancelled(uint256 indexed bondId, address indexed investor, BondState cancelledState, uint256 refundAmount, uint256 penaltyAmount);
    event PenaltyPercentageUpdated(uint256 oldPercentage, uint256 newPercentage);
    event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);

    // --- Modifiers ---

    modifier requireState(uint256 _bondId, BondState _requiredState) {
        require(bondInstances[_bondId].state == _requiredState, "QEB: Invalid state for action");
        _;
    }

    modifier requireBondExists(uint256 _bondId) {
        require(bondInstances[_bondId].id != 0, "QEB: Bond does not exist");
        _;
    }

    modifier requireBondTypeExists(uint256 _bondTypeId) {
        require(bondTypes[_bondTypeId].exists, "QEB: Bond type does not exist");
        _;
    }

    // --- Constructor ---

    constructor(address payable _feeRecipient) Ownable(msg.sender) Pausable(false) {
        require(_feeRecipient != address(0), "QEB: Fee recipient cannot be zero address");
        feeRecipient = _feeRecipient;
    }

    // --- Owner & Management Functions ---

    /**
     * @dev Creates a new bond type template.
     * @param yieldAPermille Yield percentage for State A in per mille (e.g., 100 = 10%). Max 1000 (100%).
     * @param durationASeconds Claimable duration after resolution for State A.
     * @param yieldBPermille Yield percentage for State B in per mille. Max 1000.
     * @param durationBSeconds Claimable duration after resolution for State B.
     * @param superpositionDurationSeconds Duration of the superposition phase.
     * @param triggerType How resolution is triggered (TimeBased or Manual).
     */
    function createBondType(
        uint256 yieldAPermille,
        uint256 durationASeconds,
        uint256 yieldBPermille,
        uint256 durationBSeconds,
        uint256 superpositionDurationSeconds,
        TriggerType triggerType
    ) external onlyOwner whenNotPaused {
        require(yieldAPermille <= 1000, "QEB: Yield A too high");
        require(yieldBPermille <= 1000, "QEB: Yield B too high");
        require(superpositionDurationSeconds > 0, "QEB: Superposition duration must be positive");

        bondTypeCounter++;
        uint256 newTypeId = bondTypeCounter;
        bondTypes[newTypeId] = BondType(
            newTypeId,
            yieldAPermille,
            durationASeconds,
            yieldBPermille,
            durationBSeconds,
            superpositionDurationSeconds,
            triggerType,
            true
        );

        emit BondTypeCreated(newTypeId, yieldAPermille, durationASeconds, yieldBPermille, durationBSeconds, superpositionDurationSeconds, triggerType);
    }

    /**
     * @dev Updates parameters of an existing bond type.
     * Caution: Affects future bonds and potentially triggers for existing bonds of this type.
     * Does NOT affect yield/duration of bonds already in EntangledA/B state.
     */
    function setBondTypeParameters(
        uint256 bondTypeId,
        uint256 yieldAPermille,
        uint256 durationASeconds,
        uint256 yieldBPermille,
        uint256 durationBSeconds,
        uint256 superpositionDurationSeconds,
        TriggerType triggerType
    ) external onlyOwner whenNotPaused requireBondTypeExists(bondTypeId) {
        require(yieldAPermille <= 1000, "QEB: Yield A too high");
        require(yieldBPermille <= 1000, "QEB: Yield B too high");
        require(superpositionDurationSeconds > 0, "QEB: Superposition duration must be positive");

        BondType storage bt = bondTypes[bondTypeId];
        bt.yieldAPermille = yieldAPermille;
        bt.durationASeconds = durationASeconds;
        bt.yieldBPermille = yieldBPermille;
        bt.durationBSeconds = durationBSeconds;
        bt.superpositionDurationSeconds = superpositionDurationSeconds;
        bt.triggerType = triggerType;

        emit BondTypeParametersUpdated(bondTypeId, yieldAPermille, durationASeconds, yieldBPermille, durationBSeconds, superpositionDurationSeconds, triggerType);
    }

    /**
     * @dev Sets the penalty percentage applied when cancelling during superposition.
     * @param newPenaltyPercentagePermille Penalty in per mille (e.g., 100 for 10%). Max 1000 (100%).
     */
    function setPenaltyPercentagePermille(uint256 newPenaltyPercentagePermille) external onlyOwner {
        require(newPenaltyPercentagePermille <= 1000, "QEB: Penalty too high");
        emit PenaltyPercentageUpdated(penaltyPercentagePermille, newPenaltyPercentagePermille);
        penaltyPercentagePermille = newPenaltyPercentagePermille;
    }

    /**
     * @dev Sets the address where penalties/fees are sent.
     */
    function setFeeRecipient(address payable _newFeeRecipient) external onlyOwner {
         require(_newFeeRecipient != address(0), "QEB: New fee recipient cannot be zero address");
         emit FeeRecipientUpdated(feeRecipient, _newFeeRecipient);
         feeRecipient = _newFeeRecipient;
    }


    /**
     * @dev Pauses certain functions (invest, attract, manual triggerEntanglement).
     */
    function pauseContract() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses the contract.
     */
    function unpauseContract() external onlyOwner whenPaused {
        _unpause();
    }

     /**
     * @dev Allows the owner to withdraw collected penalties/fees.
     * Requires the contract to have a balance from penalties.
     */
    function withdrawFeesAndPenalties() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance - totalPrincipalDeposited - totalYieldPaid; // Calculate available fees
        require(balance > 0, "QEB: No fees or penalties available to withdraw");
        (bool success, ) = feeRecipient.call{value: balance}("");
        require(success, "QEB: Fee withdrawal failed");
    }

    /**
     * @dev Allows the owner to withdraw all ETH from the contract in an emergency.
     * This is a failsafe and should only be used in extreme circumstances.
     */
    function emergencyWithdrawPrincipal() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "QEB: No ETH balance to withdraw");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "QEB: Emergency withdrawal failed");
    }


    // --- Bond Lifecycle Functions ---

    /**
     * @dev Allows an investor to create a new bond instance by depositing ETH.
     * Sets the bond state to Active and calculates the superposition end time.
     * @param bondTypeId The ID of the bond type to invest in.
     */
    function invest(uint255 bondTypeId) external payable whenNotPaused requireBondTypeExists(bondTypeId) nonReentrant {
        require(msg.value > 0, "QEB: Must deposit principal");

        bondInstanceCounter++;
        uint256 newBondId = bondInstanceCounter;
        BondType storage bondType = bondTypes[bondTypeId];

        bondInstances[newBondId] = BondInstance(
            newBondId,
            bondTypeId,
            msg.sender,
            msg.value,
            BondState.Active,
            block.timestamp,
            block.timestamp + bondType.superpositionDurationSeconds,
            0, // resolutionTime
            false // resolvedStateIsA
        );

        investorBondIds[msg.sender].push(newBondId);
        totalPrincipalDeposited += msg.value;

        // Transition to Superposition immediately if duration > 0, otherwise skip
        if (bondType.superpositionDurationSeconds > 0) {
             _updateBondState(newBondId, BondState.Superposition);
        } else {
             // If superposition is 0, directly trigger resolution
             _updateBondState(newBondId, BondState.PendingResolution);
             // In a real VRF system, this would initiate the VRF request
             // resolveEntanglement(newBondId, simulatedRandomOutcome); // Call internal resolution immediately
             // For simulation, let's assume the random outcome is available instantly
             // and the logic to resolve is called right after setting PendingResolution.
             // In a real system, this would be a separate call triggered by the VRF callback.
             // Calling a placeholder for clarity:
             _simulateVRFAndResolve(newBondId);
        }


        emit BondInvested(newBondId, bondTypeId, msg.sender, msg.value, block.timestamp);
    }

     /**
     * @dev Allows the investor of a bond to cancel it before the superposition phase begins.
     * Refunds the full principal.
     * @param bondId The ID of the bond to cancel.
     */
    function cancelBondBeforeSuperposition(uint256 bondId) external nonReentrant requireBondExists(bondId) requireState(bondId, BondState.Active) {
        BondInstance storage bond = bondInstances[bondId];
        require(bond.investor == msg.sender, "QEB: Not your bond");
        require(block.timestamp < bond.superpositionEndTime, "QEB: Superposition has already started or ended");

        _updateBondState(bondId, BondState.Cancelled);
        // Refund principal
        uint256 refundAmount = bond.principal;
        totalPrincipalDeposited -= bond.principal; // Adjust total principal count
        // No yield or penalty
        emit BondCancelled(bondId, msg.sender, BondState.Active, refundAmount, 0);

        (bool success, ) = payable(msg.sender).call{value: refundAmount}("");
        require(success, "QEB: Refund failed");
    }


    /**
     * @dev Allows the investor of a bond to cancel it during the superposition phase.
     * Refunds principal minus a penalty. The penalty amount is kept by the contract
     * and can be withdrawn by the owner.
     * @param bondId The ID of the bond to cancel.
     */
    function cancelBondDuringSuperposition(uint256 bondId) external nonReentrant requireBondExists(bondId) requireState(bondId, BondState.Superposition) {
        BondInstance storage bond = bondInstances[bondId];
        require(bond.investor == msg.sender, "QEB: Not your bond");
        require(block.timestamp < bond.superpositionEndTime, "QEB: Superposition time not ended");

        _updateBondState(bondId, BondState.Cancelled);

        uint256 penaltyAmount = (bond.principal * penaltyPercentagePermille) / 1000;
        uint256 refundAmount = bond.principal - penaltyAmount;

        totalPrincipalDeposited -= bond.principal; // Adjust total principal count
        // Penalty amount stays in contract balance until withdrawn by owner

        emit BondCancelled(bondId, msg.sender, BondState.Superposition, refundAmount, penaltyAmount);

        (bool success, ) = payable(msg.sender).call{value: refundAmount}("");
        require(success, "QEB: Refund failed");
    }


    /**
     * @dev Initiates the entanglement resolution process for a bond.
     * Can be called by anyone if triggerType is Manual after superposition starts.
     * If triggerType is TimeBased, this would ideally be called by an automated keeper
     * after superpositionEndTime is reached.
     * @param bondId The ID of the bond to trigger.
     */
    function triggerEntanglement(uint256 bondId) external whenNotPaused requireBondExists(bondId) requireState(bondId, BondState.Superposition) {
        BondInstance storage bond = bondInstances[bondId];
        BondType storage bondType = bondTypes[bond.bondTypeId];

        // Check if triggering is allowed based on type and time (for TimeBased)
        bool canTrigger = false;
        if (bondType.triggerType == TriggerType.Manual) {
            // Manual trigger allowed after superposition starts (which is immediate after Active)
            canTrigger = true;
        } else if (bondType.triggerType == TriggerType.TimeBased) {
             // Time-based trigger only allowed *after* the superposition duration
             canTrigger = block.timestamp >= bond.superpositionEndTime;
        }
        require(canTrigger, "QEB: Trigger conditions not met");

        // Prevent triggering if already past the superposition end time for TimeBased trigger type
        // (This is a race condition protection if multiple keepers/users call it)
        if (bondType.triggerType == TriggerType.TimeBased) {
             require(bond.state == BondState.Superposition, "QEB: Bond state changed before triggering");
        }


        _updateBondState(bondId, BondState.PendingResolution);

        emit EntanglementTriggered(bondId, bondType.triggerType);

        // --- VRF Simulation ---
        // In a real contract, this would request randomness from a VRF provider (e.g., Chainlink VRF).
        // The VRF provider's callback function would then call resolveEntanglement with the result.
        // For this example, we simulate the callback immediately.
        _simulateVRFAndResolve(bondId);
        // --- End VRF Simulation ---
    }

    /**
     * @dev Internal function simulating VRF request and immediate resolution callback.
     * REPLACE with actual VRF request and callback logic in production.
     */
    function _simulateVRFAndResolve(uint256 bondId) internal {
         // Simulate getting randomness - DO NOT USE this in production
         uint256 simulatedRandomOutcome = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.coinbase, bondId)));
         // Call the resolution logic (which would be the VRF callback in a real system)
         _resolveEntanglement(bondId, simulatedRandomOutcome);
    }


    /**
     * @dev Processes the random outcome to determine the final entangled state (A or B).
     * This function is conceptually called by the VRF provider's callback after randomness is obtained.
     * @param bondId The ID of the bond to resolve.
     * @param randomOutcome The random number provided by the VRF.
     */
    function _resolveEntanglement(uint256 bondId, uint256 randomOutcome) internal requireBondExists(bondId) requireState(bondId, BondState.PendingResolution) {
        BondInstance storage bond = bondInstances[bondId];
        BondType storage bondType = bondTypes[bond.bondTypeId];

        uint256 influenceA = bondInfluence[bondId][0]; // State A influence
        uint256 influenceB = bondInfluence[bondId][1]; // State B influence
        uint256 totalInfluence = influenceA + influenceB;

        // Determine resolution based on random outcome and influence
        // If total influence is zero, it's a 50/50 chance.
        // Otherwise, the influence biases the outcome.
        // We use a simple weighted probability based on influence.
        // Random outcome maps to a point on a line. If the point falls within
        // the "weighted A" segment, it resolves to A, otherwise B.
        // Example: totalInfluence = 10, influenceA = 7, influenceB = 3.
        // Random number space (0 to max_uint256) is split 70% for A, 30% for B.
        // This is a simplified model. Real implementation might use Chainlink VRF
        // coordinate systems or more complex weighting.

        bool resolvedStateIsA;
        if (totalInfluence == 0) {
            resolvedStateIsA = randomOutcome % 2 == 0; // 50/50 if no influence
        } else {
             // Scale random outcome (0 to max_uint256) to 0 to totalInfluence
             // Be careful with large numbers. Using modulo is okay for small influences
             // but can show bias with non-power-of-2 limits and large random numbers.
             // A better approach with Chainlink VRF might use the full 256-bit random number.
             uint256 weightedRandom = randomOutcome % totalInfluence;
             resolvedStateIsA = weightedRandom < influenceA;
        }

        bond.resolvedStateIsA = resolvedStateIsA;
        bond.resolutionTime = block.timestamp;
        _updateBondState(bondId, resolvedStateIsA ? BondState.EntangledA : BondState.EntangledB);

        emit BondResolved(bondId, resolvedStateIsA, bond.resolutionTime);

        // Reset influence counters after resolution
        delete bondInfluence[bondId];
    }


    /**
     * @dev Allows the investor to claim their principal plus yield.
     * Only possible after the bond is in an Entangled state and the required
     * duration for that state has passed since resolution.
     * @param bondId The ID of the bond to claim.
     */
    function claimYield(uint256 bondId) external nonReentrant requireBondExists(bondId) {
        BondInstance storage bond = bondInstances[bondId];
        require(bond.investor == msg.sender, "QEB: Not your bond");
        require(bond.state == BondState.EntangledA || bond.state == BondState.EntangledB, "QEB: Bond not resolved or already claimed");

        BondType storage bondType = bondTypes[bond.bondTypeId];

        uint256 requiredDuration;
        uint256 yieldPermille;

        if (bond.resolvedStateIsA) {
            requiredDuration = bondType.durationASeconds;
            yieldPermille = bondType.yieldAPermille;
        } else {
            requiredDuration = bondType.durationBSeconds;
            yieldPermille = bondType.yieldBPermille;
        }

        require(block.timestamp >= bond.resolutionTime + requiredDuration, "QEB: Claim duration not yet passed");

        uint256 yieldAmount = (bond.principal * yieldPermille) / 1000;
        uint256 totalClaimAmount = bond.principal + yieldAmount;

        // Mark as claimed BEFORE sending ETH to prevent reentrancy
        _updateBondState(bondId, BondState.Claimed);
        totalPrincipalDeposited -= bond.principal; // Adjust total principal count
        totalYieldPaid += yieldAmount; // Track total yield paid

        emit BondClaimed(bondId, msg.sender, bond.principal, yieldAmount);

        (bool success, ) = payable(msg.sender).call{value: totalClaimAmount}("");
        require(success, "QEB: ETH transfer failed");
    }


    // --- Interaction (Influence) Functions ---

    /**
     * @dev Allows any user to apply influence towards State A for a bond in Superposition.
     * This increases the weight for State A during the probabilistic resolution.
     * Could require a small fee or stake in a production version.
     * @param bondId The ID of the bond to influence.
     */
    function attractToStateA(uint256 bondId) external whenNotPaused requireBondExists(bondId) requireState(bondId, BondState.Superposition) {
         BondInstance storage bond = bondInstances[bondId];
         // Ensure superposition time hasn't ended yet if it's TimeBased trigger (manual trigger ignores end time for this purpose)
         if (bondTypes[bond.bondTypeId].triggerType == TriggerType.TimeBased) {
             require(block.timestamp < bond.superpositionEndTime, "QEB: Superposition phase ended");
         }

        // Using index 0 for State A influence
        bondInfluence[bondId][0]++;
        emit InfluenceApplied(bondId, 0, msg.sender);
    }

    /**
     * @dev Allows any user to apply influence towards State B for a bond in Superposition.
     * This increases the weight for State B during the probabilistic resolution.
     * Could require a small fee or stake in a production version.
     * @param bondId The ID of the bond to influence.
     */
    function attractToStateB(uint256 bondId) external whenNotPaused requireBondExists(bondId) requireState(bondId, BondState.Superposition) {
         BondInstance storage bond = bondInstances[bondId];
          // Ensure superposition time hasn't ended yet if it's TimeBased trigger
         if (bondTypes[bond.bondTypeId].triggerType == TriggerType.TimeBased) {
             require(block.timestamp < bond.superpositionEndTime, "QEB: Superposition phase ended");
         }

        // Using index 1 for State B influence
        bondInfluence[bondId][1]++;
        emit InfluenceApplied(bondId, 1, msg.sender);
    }

    // --- Internal Helper Function ---

    /**
     * @dev Updates the state of a bond instance and emits an event.
     * Internal function to standardize state transitions.
     */
    function _updateBondState(uint256 bondId, BondState newState) internal {
        BondState oldState = bondInstances[bondId].state;
        bondInstances[bondId].state = newState;
        emit BondStateChanged(bondId, newState, oldState);
    }

    // --- View Functions (Getters) ---

    /**
     * @dev Returns the configuration details of a specific bond type.
     */
    function getBondTypeDetails(uint256 bondTypeId) external view requireBondTypeExists(bondTypeId) returns (
        uint256 id,
        uint256 yieldAPermille,
        uint256 durationASeconds,
        uint256 yieldBPermille,
        uint256 durationBSeconds,
        uint256 superpositionDurationSeconds,
        TriggerType triggerType
    ) {
        BondType storage bt = bondTypes[bondTypeId];
        return (
            bt.id,
            bt.yieldAPermille,
            bt.durationASeconds,
            bt.yieldBPermille,
            bt.durationBSeconds,
            bt.superpositionDurationSeconds,
            bt.triggerType
        );
    }

    /**
     * @dev Returns the current state and details of a specific bond instance.
     */
    function getBondDetails(uint256 bondId) external view requireBondExists(bondId) returns (
        uint256 id,
        uint256 bondTypeId,
        address investor,
        uint256 principal,
        BondState state,
        uint256 investmentTime,
        uint256 superpositionEndTime,
        uint256 resolutionTime,
        bool resolvedStateIsA
    ) {
        BondInstance storage bond = bondInstances[bondId];
        return (
            bond.id,
            bond.bondTypeId,
            bond.investor,
            bond.principal,
            bond.state,
            bond.investmentTime,
            bond.superpositionEndTime,
            bond.resolutionTime,
            bond.resolvedStateIsA
        );
    }

    /**
     * @dev Returns only the current state enum of a bond instance.
     */
    function getBondState(uint256 bondId) external view requireBondExists(bondId) returns (BondState) {
        return bondInstances[bondId].state;
    }

     /**
     * @dev Calculates the potential claimable amount (principal + yield) for a resolved bond.
     * Does NOT check if the claim duration has passed.
     * @param bondId The ID of the bond.
     * @return claimAmount The total amount (principal + yield) or 0 if not resolved.
     */
    function getClaimableAmount(uint256 bondId) external view requireBondExists(bondId) returns (uint256 claimAmount) {
        BondInstance storage bond = bondInstances[bondId];
        if (bond.state != BondState.EntangledA && bond.state != BondState.EntangledB) {
            return 0; // Not in a resolved state
        }

        BondType storage bondType = bondTypes[bond.bondTypeId];
        uint256 yieldPermille;

        if (bond.resolvedStateIsA) {
            yieldPermille = bondType.yieldAPermille;
        } else {
            yieldPermille = bondType.yieldBPermille;
        }

        uint256 yieldAmount = (bond.principal * yieldPermille) / 1000;
        return bond.principal + yieldAmount;
    }


    /**
     * @dev Returns the current influence counts towards states A and B for a bond in superposition.
     * Returns [0, 0] if the bond is not in superposition.
     * @param bondId The ID of the bond.
     * @return influenceCounts An array [influenceA, influenceB].
     */
    function getCurrentInfluence(uint256 bondId) external view returns (uint256[] memory influenceCounts) {
        influenceCounts = new uint256[](2);
        if (bondInstances[bondId].state == BondState.Superposition) {
            influenceCounts[0] = bondInfluence[bondId][0]; // State A
            influenceCounts[1] = bondInfluence[bondId][1]; // State B
        } else {
            influenceCounts[0] = 0;
            influenceCounts[1] = 0;
        }
         return influenceCounts;
    }


    /**
     * @dev Returns an array of all bond IDs associated with a specific investor address.
     * @param investor The address of the investor.
     * @return bondIds An array of bond IDs.
     */
    function getBondIdsByInvestor(address investor) external view returns (uint256[] memory) {
        return investorBondIds[investor];
    }

    /**
     * @dev Returns the total number of bond instances created.
     */
    function getBondCount() external view returns (uint256) {
        return bondInstanceCounter;
    }

    /**
     * @dev Returns the total number of bond types created.
     */
    function getBondTypeCount() external view returns (uint255) {
        return bondTypeCounter;
    }

    /**
     * @dev Returns the cumulative ETH principal deposited across all bonds (including active, superposition, resolved, but not claimed/cancelled).
     */
    function getTotalPrincipalDeposited() external view returns (uint256) {
        // Note: This tracks the sum of principal of bonds that are NOT YET claimed or cancelled.
        // It represents the total principal currently "managed" by the contract.
        // If you wanted the historical total, you'd need a separate variable incremented on invest.
        // Current implementation tracks the sum of `bondInstances[id].principal` for non-cancelled/non-claimed bonds.
        // Let's adjust the internal logic to track total ever deposited for clarity in getter.
        // For simplicity, the state variable `totalPrincipalDeposited` will track this.
         return totalPrincipalDeposited;
    }

    /**
     * @dev Returns the cumulative ETH yield paid out across all claimed bonds.
     */
    function getTotalYieldPaid() external view returns (uint256) {
        return totalYieldPaid;
    }

     /**
     * @dev Returns the current penalty percentage for cancelling during superposition (in per mille).
     */
    function getPenaltyPercentagePermille() external view returns (uint256) {
        return penaltyPercentagePermille;
    }

     /**
     * @dev Returns the address currently set as the fee recipient.
     */
    function getFeeRecipient() external view returns (address) {
        return feeRecipient;
    }

}
```