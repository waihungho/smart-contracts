Okay, here is a Solidity smart contract called `QuantumLeapCoin`. This contract is *not* a standard ERC-20 token. Instead, it's a platform for managing "Quantum States" representing potential future outcomes or conditional events. Users can commit value (Ether in this example) to these states. When a state is "observed" (meaning its outcome becomes known), the committed value is distributed among participants based on predefined outcome rules. It incorporates concepts like state entanglement, dynamic fees, role-based observation/creation, and programmable outcome rules to make it non-standard and advanced.

It will have more than 20 functions covering state management, user interaction, observation, rule management, access control, and querying.

---

## QuantumLeapCoin Smart Contract: Outline and Function Summary

**Concept:** `QuantumLeapCoin` is a decentralized platform facilitating conditional commitments based on future events or "Quantum States". Participants commit value (Ether) to specific states. An authorized "Observer" reveals the state's outcome (the "Quantum Leap"), triggering the distribution of committed value according to predefined rules. The contract introduces concepts like state entanglement and programmable outcome rules.

**Core Components:**
1.  **QuantumState:** Represents a potential future outcome or event. Has a status (Active, Resolved, Expired), committed value, participants, an observation deadline, and references an OutcomeRule.
2.  **OutcomeRule:** Defines how committed value is distributed among participants based on the observed outcome data. Rules are managed by administrators.
3.  **Participants:** Addresses that have committed value to a QuantumState.
4.  **Observers:** Accounts authorized to trigger the "observation" (resolution) of a QuantumState.
5.  **State Creators:** Accounts authorized to create new QuantumStates.
6.  **Entanglement:** A conceptual link between two states, potentially influencing their observation or outcome processing (in this simplified implementation, primarily a data link).

**Function Summary:**

**Administration & Configuration (Owner/Admin):**
*   `constructor()`: Initializes the contract owner and sets initial fees.
*   `addObserverRole(address observer)`: Grants observer permissions to an address.
*   `removeObserverRole(address observer)`: Revokes observer permissions from an address.
*   `addStateCreatorRole(address creator)`: Grants state creation permissions to an address.
*   `removeStateCreatorRole(address creator)`: Revokes state creation permissions from an address.
*   `addOutcomeRule(string calldata description, bytes calldata ruleParameters)`: Adds a new type of outcome rule. `ruleParameters` stores data interpreted by the contract during observation.
*   `updateOutcomeRule(uint256 ruleId, string calldata description, bytes calldata ruleParameters)`: Modifies an existing outcome rule.
*   `setCommitmentFee(uint256 fee)`: Sets the fee percentage applied to each commitment.
*   `setObservationFee(uint256 fee)`: Sets the fee percentage applied during state observation (paid by observer).
*   `withdrawContractBalance(uint256 amount)`: Allows the owner to withdraw accumulated fees.

**Quantum State Management:**
*   `createQuantumState(string calldata description, uint256 outcomeRuleId, uint256 observationDeadline)`: Creates a new QuantumState instance. Requires State Creator role.
*   `entangleStates(uint256 stateId1, uint256 stateId2, EntanglementType entanglementType)`: Links two states, marking them as entangled. Requires State Creator role.
*   `observeQuantumState(uint256 stateId, bytes calldata observationData)`: Triggers the resolution of a state. Requires Observer role. `observationData` contains the specific data point for resolving this state using its OutcomeRule.
*   `refundExpiredState(uint256 stateId)`: Allows participants or anyone to trigger a refund for an expired state.
*   `getEntangledStates(uint256 stateId)`: Gets a list of states entangled with a given state.

**User Interaction:**
*   `commitToState(uint256 stateId) payable`: Commits Ether to a specific QuantumState.
*   `claimOutcome(uint256 stateId)`: Allows a participant to claim their share of the committed value after a state has been resolved.

**Query Functions:**
*   `getQuantumStateDetails(uint256 stateId)`: Retrieves details about a specific state.
*   `getParticipantCommitment(uint256 stateId, address participant)`: Gets the amount committed by a specific participant to a state.
*   `getParticipantsInState(uint256 stateId)`: Gets a list of all participants in a state.
*   `getAllQuantumStates()`: Lists all created state IDs.
*   `getActiveQuantumStates()`: Lists IDs of states that are currently active (not resolved or expired).
*   `getResolvedQuantumStates()`: Lists IDs of states that have been resolved.
*   `getOutcomeRuleDetails(uint256 ruleId)`: Retrieves details about a specific outcome rule.
*   `getCommitmentFee()`: Gets the current commitment fee percentage.
*   `getObservationFee()`: Gets the current observation fee percentage.
*   `hasObserverRole(address account)`: Checks if an account has the observer role.
*   `hasStateCreatorRole(address account)`: Checks if an account has the state creator role.
*   `isStateExpired(uint256 stateId)`: Checks if a state has passed its observation deadline.
*   `getTotalCommittedValue()`: Gets the total amount of Ether ever committed to the contract.
*   `getTotalValueInState(uint256 stateId)`: Gets the current total amount of Ether committed to a specific state.
*   `getStateStatus(uint256 stateId)`: Gets the current status of a state.
*   `getContractSummary()`: Provides a summary of contract stats (total states, total value, fees).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Although 0.8+ has overflow checks, good practice for complex math

/// @title QuantumLeapCoin
/// @author Your Name/Alias
/// @notice A contract for managing conditional commitments based on future states.

contract QuantumLeapCoin is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // --- Enums ---

    enum StateStatus {
        Active,
        Resolved,
        Expired
    }

    enum EntanglementType {
        None,
        MutualInfluence, // Resolving state A influences B's outcome/observationData requirements
        RequiresSimultaneousObservation, // A and B must be observed together
        OutcomeLinks // Outcome of A directly dictates outcome of B
    }

    // --- Structs ---

    struct QuantumState {
        uint256 id;
        string description;
        uint256 outcomeRuleId; // Reference to the rule that defines outcome distribution
        uint256 observationDeadline; // Timestamp by which state must be observed
        StateStatus status;
        uint256 totalCommittedValue;
        mapping(address => uint256) commitments; // Participant address => amount committed
        address[] participants; // List of participants for easier iteration
        bytes observationData; // Data provided by the observer at resolution
        mapping(address => bool) claimed; // Participant address => whether they have claimed
        mapping(address => uint256) claimableAmounts; // Participant address => amount claimable after resolution
    }

    struct OutcomeRule {
        uint256 id;
        string description;
        bytes ruleParameters; // Data used by the contract to interpret observationData and calculate payouts
    }

    // --- State Variables ---

    uint256 private _stateCounter;
    mapping(uint256 => QuantumState) private _quantumStates;
    uint256[] private _allStateIds; // To list all states easily

    uint256 private _outcomeRuleCounter;
    mapping(uint256 => OutcomeRule) private _outcomeRules;
    uint256[] private _allOutcomeRuleIds;

    mapping(address => bool) private _observers;
    mapping(address => bool) private _stateCreators;

    mapping(uint256 => mapping(uint256 => EntanglementType)) private _entangledStates; // stateId1 => stateId2 => type
    mapping(uint256 => uint256[]) private _stateEntanglements; // stateId => list of stateIds it's entangled with

    uint256 private _commitmentFeeBasisPoints; // e.g., 100 = 1%
    uint256 private _observationFeeBasisPoints; // e.g., 50 = 0.5%
    uint256 private _totalFeesCollected; // Total Ether collected as fees

    uint256 private _totalValueCommitted; // Total Ether ever committed to the contract

    // --- Events ---

    event StateCreated(uint256 stateId, string description, uint256 observationDeadline, address indexed creator);
    event CommitmentMade(uint256 indexed stateId, address indexed participant, uint256 amount, uint256 feePaid);
    event StateObserved(uint256 indexed stateId, StateStatus newStatus, bytes observationData, address indexed observer);
    event OutcomeClaimed(uint256 indexed stateId, address indexed participant, uint256 amount);
    event StateExpired(uint256 indexed stateId);
    event RefundIssued(uint256 indexed stateId, address indexed participant, uint256 amount);

    event ObserverRoleGranted(address indexed account);
    event ObserverRoleRevoked(address indexed account);
    event StateCreatorRoleGranted(address indexed account);
    event StateCreatorRoleRevoked(address indexed account);

    event OutcomeRuleAdded(uint256 ruleId, string description);
    event OutcomeRuleUpdated(uint256 ruleId);

    event FeesSet(uint256 commitmentFeeBasisPoints, uint256 observationFeeBasisPoints);
    event ContractBalanceWithdrawn(address indexed receiver, uint256 amount);
    event StatesEntangled(uint256 indexed stateId1, uint256 indexed stateId2, EntanglementType entanglementType);

    // --- Modifiers ---

    modifier onlyObserver() {
        require(_observers[msg.sender], "Qกล่าวC: Caller is not an observer");
        _;
    }

    modifier onlyStateCreator() {
        require(_stateCreators[msg.sender], "QLC: Caller is not a state creator");
        _;
    }

    modifier stateExists(uint256 stateId) {
        require(_quantumStates[stateId].id != 0 || stateId == 0, "QLC: State does not exist"); // ID 0 is reserved/invalid state
        require(stateId != 0, "QLC: Invalid State ID");
        _;
    }

    // --- Constructor ---

    constructor() Ownable(msg.sender) {
        _stateCounter = 0; // State IDs will start from 1
        _outcomeRuleCounter = 0; // Rule IDs will start from 1
        _commitmentFeeBasisPoints = 0; // Default 0%
        _observationFeeBasisPoints = 0; // Default 0%
        _totalFeesCollected = 0;
        _totalValueCommitted = 0;
    }

    // --- Administration & Configuration ---

    /**
     * @notice Grants observer role to an address.
     * @param observer The address to grant the role to.
     */
    function addObserverRole(address observer) external onlyOwner {
        require(observer != address(0), "QLC: Zero address");
        _observers[observer] = true;
        emit ObserverRoleGranted(observer);
    }

    /**
     * @notice Revokes observer role from an address.
     * @param observer The address to revoke the role from.
     */
    function removeObserverRole(address observer) external onlyOwner {
        require(observer != address(0), "QLC: Zero address");
        _observers[observer] = false;
        emit ObserverRoleRevoked(observer);
    }

    /**
     * @notice Grants state creator role to an address.
     * @param creator The address to grant the role to.
     */
    function addStateCreatorRole(address creator) external onlyOwner {
        require(creator != address(0), "QLC: Zero address");
        _stateCreators[creator] = true;
        emit StateCreatorRoleGranted(creator);
    }

    /**
     * @notice Revokes state creator role from an address.
     * @param creator The address to revoke the role from.
     */
    function removeStateCreatorRole(address creator) external onlyOwner {
        require(creator != address(0), "QLC: Zero address");
        _stateCreators[creator] = false;
        emit StateCreatorRoleRevoked(creator);
    }

    /**
     * @notice Adds a new outcome rule that defines how observation data affects payout.
     * @param description A description of the rule.
     * @param ruleParameters Specific parameters for this rule type (interpreted by contract logic).
     * @return ruleId The ID of the newly created rule.
     */
    function addOutcomeRule(string calldata description, bytes calldata ruleParameters) external onlyOwner returns (uint256) {
        _outcomeRuleCounter++;
        uint256 newRuleId = _outcomeRuleCounter;
        _outcomeRules[newRuleId] = OutcomeRule(newRuleId, description, ruleParameters);
        _allOutcomeRuleIds.push(newRuleId);
        emit OutcomeRuleAdded(newRuleId, description);
        return newRuleId;
    }

     /**
     * @notice Updates an existing outcome rule.
     * @param ruleId The ID of the rule to update.
     * @param description A new description for the rule.
     * @param ruleParameters New specific parameters for this rule type.
     */
    function updateOutcomeRule(uint256 ruleId, string calldata description, bytes calldata ruleParameters) external onlyOwner stateExists(ruleId) {
        require(_outcomeRules[ruleId].id != 0, "QLC: Outcome rule does not exist");
        _outcomeRules[ruleId].description = description;
        _outcomeRules[ruleId].ruleParameters = ruleParameters;
        emit OutcomeRuleUpdated(ruleId);
    }


    /**
     * @notice Sets the fee percentage for commitments (in basis points).
     * @param fee The fee in basis points (e.g., 100 for 1%). Max 10000 (100%).
     */
    function setCommitmentFee(uint256 fee) external onlyOwner {
        require(fee <= 10000, "QLC: Fee cannot exceed 100%");
        _commitmentFeeBasisPoints = fee;
        emit FeesSet(_commitmentFeeBasisPoints, _observationFeeBasisPoints);
    }

    /**
     * @notice Sets the fee percentage for observation (in basis points).
     * @param fee The fee in basis points (e.g., 50 for 0.5%). Max 10000 (100%).
     */
    function setObservationFee(uint256 fee) external onlyOwner {
        require(fee <= 10000, "QLC: Fee cannot exceed 100%");
        _observationFeeBasisPoints = fee;
        emit FeesSet(_commitmentFeeBasisPoints, _observationFeeBasisPoints);
    }

    /**
     * @notice Allows the contract owner to withdraw accumulated fees.
     * @param amount The amount of Ether to withdraw.
     */
    function withdrawContractBalance(uint256 amount) external onlyOwner {
        require(amount > 0, "QLC: Amount must be positive");
        require(address(this).balance >= amount, "QLC: Insufficient contract balance");
        require(_totalFeesCollected >= amount, "QLC: Withdrawn amount exceeds collected fees"); // Only allow withdrawing fees, not committed value

        _totalFeesCollected = _totalFeesCollected.sub(amount);
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "QLC: Transfer failed");
        emit ContractBalanceWithdrawn(msg.sender, amount);
    }

    // --- Quantum State Management ---

    /**
     * @notice Creates a new Quantum State for participants to commit to.
     * @param description A description of the state/event.
     * @param outcomeRuleId The ID of the OutcomeRule governing this state.
     * @param observationDeadline The timestamp by which the state must be observed.
     * @return stateId The ID of the newly created state.
     */
    function createQuantumState(string calldata description, uint256 outcomeRuleId, uint256 observationDeadline) external onlyStateCreator returns (uint256) {
        require(bytes(description).length > 0, "QLC: Description cannot be empty");
        require(observationDeadline > block.timestamp, "QLC: Deadline must be in the future");
        require(_outcomeRules[outcomeRuleId].id != 0, "QLC: Invalid outcome rule ID");

        _stateCounter++;
        uint256 newStateId = _stateCounter;

        QuantumState storage newState = _quantumStates[newStateId];
        newState.id = newStateId;
        newState.description = description;
        newState.outcomeRuleId = outcomeRuleId;
        newState.observationDeadline = observationDeadline;
        newState.status = StateStatus.Active;
        newState.totalCommittedValue = 0;
        // mappings and array (participants) are initialized empty by default

        _allStateIds.push(newStateId);

        emit StateCreated(newStateId, description, observationDeadline, msg.sender);
        return newStateId;
    }

    /**
     * @notice Links two states, marking them as entangled. Conceptual in this version.
     * @dev This function primarily records the entanglement. The actual logic for how entanglement affects observation or outcome distribution needs external interpretation or further contract logic development.
     * @param stateId1 The ID of the first state.
     * @param stateId2 The ID of the second state.
     * @param entanglementType The type of entanglement.
     */
    function entangleStates(uint256 stateId1, uint256 stateId2, EntanglementType entanglementType) external onlyStateCreator stateExists(stateId1) stateExists(stateId2) {
        require(stateId1 != stateId2, "QLC: Cannot entangle state with itself");
        require(entanglementType != EntanglementType.None, "QLC: Entanglement type cannot be None");
        // Prevent duplicate entanglement entries (check both directions as mapping is stateId1 => stateId2)
        require(_entangledStates[stateId1][stateId2] == EntanglementType.None && _entangledStates[stateId2][stateId1] == EntanglementType.None, "QLC: States already entangled");

        _entangledStates[stateId1][stateId2] = entanglementType;
        _entangledStates[stateId2][stateId1] = entanglementType; // Entanglement is symmetric

        // Store in array for easier retrieval
        _stateEntanglements[stateId1].push(stateId2);
        _stateEntanglements[stateId2].push(stateId1);

        emit StatesEntangled(stateId1, stateId2, entanglementType);
    }

     /**
     * @notice Sets a new observation deadline for an active state.
     * @param stateId The ID of the state to update.
     * @param newDeadline The new observation deadline timestamp.
     */
    function setObservationDeadline(uint256 stateId, uint256 newDeadline) external stateExists(stateId) {
        QuantumState storage state = _quantumStates[stateId];
        require(state.status == StateStatus.Active, "QLC: State is not active");
        require(msg.sender == owner() || _stateCreators[msg.sender], "QLC: Caller must be owner or state creator"); // Only owner or creator can change deadline
        require(newDeadline > block.timestamp, "QLC: Deadline must be in the future");

        state.observationDeadline = newDeadline;
        // Event could be added here if needed
    }

    /**
     * @notice Triggers the observation and resolution of a Quantum State. This is the "Quantum Leap".
     * @dev This function calculates and stores the claimable amounts for each participant based on the outcome rule and observation data.
     * @param stateId The ID of the state to observe.
     * @param observationData The data representing the observed outcome. This data's structure and meaning depend on the state's OutcomeRule.
     */
    function observeQuantumState(uint256 stateId, bytes calldata observationData) external onlyObserver stateExists(stateId) nonReentrant {
        QuantumState storage state = _quantumStates[stateId];
        require(state.status == StateStatus.Active, "QLC: State is not active");
        require(block.timestamp <= state.observationDeadline, "QLC: State has expired");
        require(state.totalCommittedValue > 0, "QLC: No value committed to this state"); // No point resolving empty state

        // Pay observation fee
        if (_observationFeeBasisPoints > 0) {
            uint256 fee = state.totalCommittedValue.mul(_observationFeeBasisPoints).div(10000);
            // Ensure contract has enough balance (committed value + fees)
             require(address(this).balance >= fee, "QLC: Insufficient contract balance for observation fee");

            _totalFeesCollected = _totalFeesCollected.add(fee);
            state.totalCommittedValue = state.totalCommittedValue.sub(fee); // Deduct fee from the pool
        }

        state.observationData = observationData; // Store the observed data

        // --- Quantum Leap Logic: Calculate Payouts Based on Rule and Observation Data ---
        // This is a placeholder for complex logic. A real contract might:
        // 1. Look up the OutcomeRule (_outcomeRules[state.outcomeRuleId])
        // 2. Interpret ruleParameters and observationData
        // 3. Calculate each participant's share of the remaining `state.totalCommittedValue`
        //    Example simple rule: If observationData is "0x01" (true), distribute 80% proportionally to commitments. If "0x00" (false), distribute 20% proportionally.
        //    More complex: observationData is a price. Participants who committed expecting price > X get proportional share of pool A, others get share of pool B.
        //    For this example, let's implement a basic binary outcome (true/false represented by bytes "0x01" or "0x00") proportional distribution rule.
        //    RuleParameters for this rule could be `bytes` representing two uint256 values: `percentageIfTrue` and `percentageIfFalse`.

        require(observationData.length == 1, "QLC: Invalid observation data format"); // Expecting 0x00 or 0x01
        uint256 payoutPercentage;
        uint256 remainingPool = state.totalCommittedValue;

        if (observationData[0] == 0x01) { // Outcome True
             // Example rule parameter: bytes(abi.encodePacked(uint256(8000), uint256(2000))) -> 80% if true, 20% if false (in basis points)
             require(_outcomeRules[state.outcomeRuleId].ruleParameters.length == 64, "QLC: Rule parameters incorrect length for binary rule");
             (uint256 truePct, ) = abi.decode(_outcomeRules[state.outcomeRuleId].ruleParameters, (uint256, uint256));
             payoutPercentage = truePct;

        } else if (observationData[0] == 0x00) { // Outcome False
             require(_outcomeRules[state.outcomeRuleId].ruleParameters.length == 64, "QLC: Rule parameters incorrect length for binary rule");
             (, uint256 falsePct) = abi.decode(_outcomeRules[state.outcomeRuleId].ruleParameters, (uint256, uint256));
             payoutPercentage = falsePct;

        } else {
            revert("QLC: Unsupported observation data value");
        }

        uint256 totalPayoutAmount = remainingPool.mul(payoutPercentage).div(10000);
        uint256 totalBasisForPayout = 0; // Sum of commitments from participants eligible for payout (in this simple rule, all participants)

        // In this simple proportional rule, all participants are potentially eligible, their share is based on their commitment relative to the *total* commitment before fees.
        // This needs careful consideration: Should payout be based on commitment *before* or *after* fee deduction? Let's use commitment *before* fee deduction for simplicity in calculation basis.
        // The actual payout amount comes from the pool *after* fee deduction.

        // Recalculate the basis from the stored commitments if needed, or rely on state.totalCommittedValue logic above
        // For simplicity with the proportional rule, totalBasisForPayout is the initial totalCommittedValue before fees, IF the rule distributes based on original share.
        // If rule distributes from the remaining pool, totalBasisForPayout is just the sum of eligible participants' *current* (after fee deduction) commitment - but we didn't track participant commitment reduction by fee.
        // Let's refine: The rule defines how the *remaining pool* is split based on *original commitments*.
        // Example: Total Committed = 100 ETH. Fee = 1 ETH. Remaining pool = 99 ETH. Payout rule = 80% for outcome A. Payout pool = 99 * 0.8 = 79.2 ETH.
        // Participant P1 committed 60 ETH, P2 committed 40 ETH. P1's share of payout = (60/100) * 79.2 = 47.52 ETH. P2's share = (40/100) * 79.2 = 31.68 ETH.
        // The calculation basis is the total committed value *before* fees.

        uint256 basisForCalculation = _quantumStates[stateId].totalCommittedValue.add(fee); // Use value before fee deduction as basis

        for (uint i = 0; i < state.participants.length; i++) {
            address participant = state.participants[i];
            uint256 commitment = state.commitments[participant]; // Original commitment
            if (commitment > 0) {
                 // Apply the rule's logic here. For binary proportional:
                 // If ruleParameters specified different pools for different outcomes, you'd check observationData
                 // and participant's 'side' of the bet (which isn't captured in this simple struct yet).
                 // Since our simple rule is just a percentage of the *whole pool* distributed proportionally:
                uint256 participantShare = commitment.mul(totalPayoutAmount).div(basisForCalculation); // Their commitment's proportion of the payout pool
                state.claimableAmounts[participant] = participantShare;
            }
        }

        // Any remaining value in the pool after distributing the defined payout percentage could be handled
        // (e.g., returned to observer, sent to owner, burned). For now, it stays in the contract balance.
        // The difference `remainingPool.sub(totalPayoutAmount)` represents value not distributed by the rule.

        state.status = StateStatus.Resolved;
        emit StateObserved(stateId, state.status, observationData, msg.sender);
    }

    /**
     * @notice Allows a participant to claim their calculated share after a state is resolved.
     * @param stateId The ID of the state to claim from.
     */
    function claimOutcome(uint256 stateId) external nonReentrant stateExists(stateId) {
        QuantumState storage state = _quantumStates[stateId];
        require(state.status == StateStatus.Resolved, "QLC: State is not resolved");
        require(!state.claimed[msg.sender], "QLC: Outcome already claimed");

        uint256 claimAmount = state.claimableAmounts[msg.sender];
        require(claimAmount > 0, "QLC: No claimable amount for this participant");

        state.claimed[msg.sender] = true;
        // Clear claimable amount after setting claimed to prevent double claim attempts hitting amount == 0
        state.claimableAmounts[msg.sender] = 0; // Important: Set to zero BEFORE transfer

        (bool success, ) = msg.sender.call{value: claimAmount}("");
        require(success, "QLC: Transfer failed");

        emit OutcomeClaimed(stateId, msg.sender, claimAmount);
    }

    /**
     * @notice Allows a participant to refund their commitment if the state expired without observation.
     * @param stateId The ID of the state to refund from.
     */
    function refundExpiredState(uint256 stateId) external nonReentrant stateExists(stateId) {
        QuantumState storage state = _quantumStates[stateId];
        require(state.status == StateStatus.Active, "QLC: State is not active");
        require(block.timestamp > state.observationDeadline, "QLC: State has not expired yet");

        uint256 commitment = state.commitments[msg.sender];
        require(commitment > 0, "QLC: No commitment from this participant");
        require(!state.claimed[msg.sender], "QLC: Already claimed (should not happen for expired state)"); // Check just in case

        state.commitments[msg.sender] = 0; // Clear commitment
        state.totalCommittedValue = state.totalCommittedValue.sub(commitment); // Reduce total state value

        // Remove participant from array? Could be gas-intensive if array is large.
        // For simplicity, we'll leave them in the array but their commitment mapping is zeroed.
        // If the list needs to be accurate for future use, a more complex removal or a separate set of active participants is needed.

        // Mark state as expired if this is the first refund or if all participants are refunded
        if (state.status != StateStatus.Expired) {
             state.status = StateStatus.Expired;
             emit StateExpired(stateId);
        }


        (bool success, ) = msg.sender.call{value: commitment}("");
        require(success, "QLC: Refund transfer failed");

        emit RefundIssued(stateId, msg.sender, commitment);
    }


    // --- User Interaction ---

    /**
     * @notice Commits Ether to a specific Quantum State.
     * @param stateId The ID of the state to commit to.
     */
    function commitToState(uint256 stateId) external payable nonReentrant stateExists(stateId) {
        QuantumState storage state = _quantumStates[stateId];
        require(state.status == StateStatus.Active, "QLC: State is not active");
        require(block.timestamp <= state.observationDeadline, "QLC: State has expired");
        require(msg.value > 0, "QLC: Commitment amount must be greater than zero");

        uint256 fee = msg.value.mul(_commitmentFeeBasisPoints).div(10000);
        uint256 amountAfterFee = msg.value.sub(fee);

        _totalFeesCollected = _totalFeesCollected.add(fee);
        _totalValueCommitted = _totalValueCommitted.add(msg.value);

        bool isNewParticipant = state.commitments[msg.sender] == 0;
        state.commitments[msg.sender] = state.commitments[msg.sender].add(amountAfterFee);
        state.totalCommittedValue = state.totalCommittedValue.add(amountAfterFee);

        if (isNewParticipant) {
            state.participants.push(msg.sender);
        }

        emit CommitmentMade(stateId, msg.sender, amountAfterFee, fee);
    }


    // --- Query Functions ---

    /**
     * @notice Retrieves details about a specific state.
     * @param stateId The ID of the state.
     * @return A tuple containing state details.
     */
    function getQuantumStateDetails(uint256 stateId) external view stateExists(stateId) returns (
        uint256 id,
        string memory description,
        uint256 outcomeRuleId,
        uint256 observationDeadline,
        StateStatus status,
        uint256 totalCommittedValue,
        bytes memory observationData // Will be empty until observed
    ) {
        QuantumState storage state = _quantumStates[stateId];
        return (
            state.id,
            state.description,
            state.outcomeRuleId,
            state.observationDeadline,
            state.status,
            state.totalCommittedValue,
            state.observationData
        );
    }

    /**
     * @notice Gets the amount committed by a specific participant to a state (after fees).
     * @param stateId The ID of the state.
     * @param participant The address of the participant.
     * @return The committed amount.
     */
    function getParticipantCommitment(uint256 stateId, address participant) external view stateExists(stateId) returns (uint256) {
        return _quantumStates[stateId].commitments[participant];
    }

    /**
     * @notice Gets a list of all participants in a state.
     * @dev Note: This list includes addresses that may have withdrawn or been refunded. Check `getParticipantCommitment` for current committed amount.
     * @param stateId The ID of the state.
     * @return An array of participant addresses.
     */
    function getParticipantsInState(uint256 stateId) external view stateExists(stateId) returns (address[] memory) {
        return _quantumStates[stateId].participants;
    }

    /**
     * @notice Lists all created state IDs.
     * @return An array of state IDs.
     */
    function getAllQuantumStates() external view returns (uint256[] memory) {
        return _allStateIds;
    }

    /**
     * @notice Lists IDs of states that are currently active.
     * @return An array of active state IDs.
     */
    function getActiveQuantumStates() external view returns (uint256[] memory) {
        uint256[] memory activeIds = new uint256[](_allStateIds.length); // Max possible size
        uint256 activeCount = 0;
        for (uint i = 0; i < _allStateIds.length; i++) {
            uint256 stateId = _allStateIds[i];
            if (_quantumStates[stateId].status == StateStatus.Active) {
                activeIds[activeCount] = stateId;
                activeCount++;
            }
        }
        // Trim array to actual size
        uint256[] memory result = new uint256[](activeCount);
        for (uint i = 0; i < activeCount; i++) {
            result[i] = activeIds[i];
        }
        return result;
    }

     /**
     * @notice Lists IDs of states that have been resolved.
     * @return An array of resolved state IDs.
     */
    function getResolvedQuantumStates() external view returns (uint256[] memory) {
        uint256[] memory resolvedIds = new uint256[](_allStateIds.length); // Max possible size
        uint256 resolvedCount = 0;
        for (uint i = 0; i < _allStateIds.length; i++) {
            uint256 stateId = _allStateIds[i];
            if (_quantumStates[stateId].status == StateStatus.Resolved) {
                resolvedIds[resolvedCount] = stateId;
                resolvedCount++;
            }
        }
        // Trim array
        uint256[] memory result = new uint256[](resolvedCount);
        for (uint i = 0; i < resolvedCount; i++) {
            result[i] = resolvedIds[i];
        }
        return result;
    }

    /**
     * @notice Gets details about a specific outcome rule.
     * @param ruleId The ID of the outcome rule.
     * @return A tuple containing rule details.
     */
    function getOutcomeRuleDetails(uint256 ruleId) external view returns (uint256 id, string memory description, bytes memory ruleParameters) {
         require(_outcomeRules[ruleId].id != 0, "QLC: Outcome rule does not exist");
         OutcomeRule storage rule = _outcomeRules[ruleId];
         return (rule.id, rule.description, rule.ruleParameters);
    }

    /**
     * @notice Gets the current commitment fee percentage in basis points.
     */
    function getCommitmentFee() external view returns (uint256) {
        return _commitmentFeeBasisPoints;
    }

    /**
     * @notice Gets the current observation fee percentage in basis points.
     */
    function getObservationFee() external view returns (uint256) {
        return _observationFeeBasisPoints;
    }

    /**
     * @notice Checks if an account has the observer role.
     * @param account The address to check.
     * @return True if the account has the role, false otherwise.
     */
    function hasObserverRole(address account) external view returns (bool) {
        return _observers[account];
    }

    /**
     * @notice Checks if an account has the state creator role.
     * @param account The address to check.
     * @return True if the account has the role, false otherwise.
     */
    function hasStateCreatorRole(address account) external view returns (bool) {
        return _stateCreators[account];
    }

    /**
     * @notice Gets a list of states entangled with a given state.
     * @param stateId The ID of the state.
     * @return An array of entangled state IDs.
     */
    function getEntangledStates(uint256 stateId) external view stateExists(stateId) returns (uint256[] memory) {
        return _stateEntanglements[stateId];
    }

     /**
     * @notice Checks if two states are entangled.
     * @param stateId1 The ID of the first state.
     * @param stateId2 The ID of the second state.
     * @return The entanglement type (None if not entangled).
     */
    function isEntangled(uint256 stateId1, uint256 stateId2) external view stateExists(stateId1) stateExists(stateId2) returns (EntanglementType) {
        return _entangledStates[stateId1][stateId2];
    }


    /**
     * @notice Checks if a state has passed its observation deadline.
     * @param stateId The ID of the state.
     * @return True if expired, false otherwise.
     */
    function isStateExpired(uint256 stateId) external view stateExists(stateId) returns (bool) {
        QuantumState storage state = _quantumStates[stateId];
        return state.status == StateStatus.Active && block.timestamp > state.observationDeadline;
    }

    /**
     * @notice Gets the total amount of Ether ever committed across all states (including fees).
     */
    function getTotalCommittedValue() external view returns (uint256) {
        return _totalValueCommitted;
    }

    /**
     * @notice Gets the current total amount of Ether committed to a specific state (remaining after fees).
     * @param stateId The ID of the state.
     */
    function getTotalValueInState(uint256 stateId) external view stateExists(stateId) returns (uint256) {
        return _quantumStates[stateId].totalCommittedValue;
    }

    /**
     * @notice Gets the current status of a state.
     * @param stateId The ID of the state.
     */
    function getStateStatus(uint256 stateId) external view stateExists(stateId) returns (StateStatus) {
        return _quantumStates[stateId].status;
    }

    /**
     * @notice Provides a summary of key contract statistics.
     * @return A tuple with total states, total committed value, and total fees collected.
     */
    function getContractSummary() external view returns (uint256 totalStates, uint256 totalValueCommitted, uint256 totalFeesCollectedInEth) {
        return (_stateCounter, _totalValueCommitted, _totalFeesCollected);
    }

    // Required to receive Ether
    receive() external payable {
        // Ether received here without calling commitToState will increase contract balance but not be associated with any state.
        // This could be for direct fee payments or initial funding if needed, but the primary way Ether enters is via commitToState.
    }
}
```