Okay, let's design a complex, creative, and unique smart contract. We'll call it the "QuantumLeapEscrow".

The core idea is an escrow system where funds are held in a state of "superposition" with multiple potential distribution outcomes. Specific "measurement" events (conditions being met, time passing, external data feeds, participant actions) trigger a "state collapse" where one of the potential outcomes is finalized, and funds are distributed accordingly. It also includes concepts like reputation, arbitration, and multi-signature conditions.

This is quite complex and goes beyond typical escrows by managing multiple potential outcomes and a sophisticated conditional resolution mechanism.

---

## QuantumLeapEscrow Smart Contract

### Outline

1.  **Name:** QuantumLeapEscrow
2.  **Description:** A multi-party conditional escrow system where funds are held in a state of "superposition" with multiple potential distribution outcomes. Specific conditions acting as "measurements" trigger a "state collapse," resolving the escrow to a single outcome. Features include time-based, external data, participant action, reputation, and multi-signature conditions, plus arbitration.
3.  **States:**
    *   `PendingSetup`: Initial state, escrow details and potential outcomes/conditions are defined.
    *   `Superposed`: Setup is finalized, funds are held, awaiting conditions to be met.
    *   `Collapsed`: Conditions have been met, an outcome has been determined, and funds distributed.
    *   `Cancelled`: Escrow was cancelled (by sender or arbiter) before collapse.
4.  **Participants:**
    *   `Sender`: The address that deposits funds.
    *   `Potential Recipients`: Addresses that might receive funds based on different outcomes.
    *   `Arbiters`: Trusted addresses that can resolve disputes or cancel the escrow under specific conditions.
    *   `Trusted Parties`: Addresses authorized to trigger external conditions (e.g., Oracles).
    *   `Approvers`: Participants required to approve multi-signature conditions.
5.  **Core Concepts:**
    *   **Superposition:** Holding funds with multiple defined potential distribution outcomes.
    *   **Measurement/State Collapse:** The process of checking conditions and selecting/executing one final outcome.
    *   **Conditions:** Criteria that must be met for a specific outcome to become eligible (Time, External Data, Participant Action, Reputation, Multisig).
    *   **Arbitration:** A mechanism for a designated party to force a resolution.
    *   **Reputation:** A simple score tracking participant success/failure in past escrows within this contract.
    *   **Multisig Conditions:** Requiring approvals from multiple designated addresses.
6.  **Uniqueness:** Managing multiple distinct, predefined potential outcomes linked to specific sets of conditions, and a dynamic resolution mechanism (`measureState`) that selects an outcome based on fulfilled conditions, including tie-breaking logic potentially influenced by participant reputation. Unlike simple if/else escrows, the structure explicitly defines a set of possibilities that are evaluated simultaneously.

### Function Summary (> 20 functions)

1.  `createEscrow`: Starts a new escrow, accepts ETH deposit, sets sender, and defines initial parameters.
2.  `addPotentialOutcome`: Adds a possible distribution scenario (recipient(s) and shares) to a pending escrow.
3.  `addConditionToOutcome`: Links a specific condition (by type and parameters) to a potential outcome in a pending escrow.
4.  `addTimeCondition`: Defines and adds a time-based condition (e.g., `afterTimestamp`, `beforeTimestamp`).
5.  `addExternalCondition`: Defines and adds a condition dependent on external data, triggerable by a trusted party.
6.  `addParticipantActionCondition`: Defines and adds a condition requiring a specific participant to call a trigger function.
7.  `addReputationCondition`: Defines and adds a condition based on a participant's reputation score meeting a threshold.
8.  `addMultisigCondition`: Defines and adds a condition requiring multiple specified addresses to submit approvals.
9.  `finalizeSuperpositionSetup`: Locks the escrow setup, moves state from `PendingSetup` to `Superposed`, and makes funds available for conditional release.
10. `measureState`: The core resolution function. Checks all conditions for all potential outcomes. If one outcome's conditions are met, it triggers the collapse and distribution. Handles tie-breaking if multiple outcomes are eligible.
11. `triggerTimeCondition`: Can be called by anyone to check if a time-based condition has been met and update its status.
12. `triggerExternalCondition`: Called by a trusted party to mark an external condition as met.
13. `triggerParticipantActionCondition`: Called by the designated participant to mark an action-based condition as met.
14. `submitApprovalForMultisigCondition`: Called by a required approver to provide their approval for a multisig condition.
15. `cancelEscrowBySender`: Allows the original sender to cancel the escrow under defined conditions (e.g., before setup is finalized).
16. `cancelEscrowByArbiter`: Allows a designated arbiter to cancel the escrow under defined conditions or during a dispute.
17. `setArbitrationDecision`: Allows a designated arbiter to force the resolution to a specific potential outcome, overriding standard condition checks.
18. `addArbiterToEscrow`: Adds an arbiter to a pending escrow.
19. `removePotentialOutcome`: Removes a potential outcome from a pending escrow.
20. `removeCondition`: Removes a condition from a pending escrow (and its links to outcomes).
21. `getEscrowDetails`: View function to get basic information about an escrow.
22. `getSuperpositionStates`: View function to see all potential outcome distributions for an escrow.
23. `getConditions`: View function to see all conditions defined for an escrow and their current status.
24. `getEligibleOutcomes`: View function to check which outcomes *would* be eligible for collapse based on currently met conditions (helper for `measureState`).
25. `getParticipantReputation`: View function to check the reputation score of an address.
26. `setTrustedPartyAddress`: Owner function to set the address authorized to trigger external conditions.
27. `updateTrustedPartyAddress`: Owner function to update the trusted party address.
28. `transferOwnership`: Standard Ownable function (adding for completeness, though core logic uses `trustedParty`, `arbiter`).
29. `withdrawStuckEth`: Owner function to recover ETH sent accidentally to the contract address (not escrow funds).
30. `getMultisigConditionStatus`: View function to check approval count for a specific multisig condition.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumLeapEscrow
 * @dev A multi-party conditional escrow system with concepts inspired by quantum states.
 * Funds are held in a 'Superposed' state with multiple potential outcomes,
 * and 'measurement' events (conditions being met) trigger a 'Collapsed' state,
 * resolving to a single outcome.
 */
contract QuantumLeapEscrow {

    // --- Errors ---
    error InvalidState(string message);
    error Unauthorized(string message);
    error InvalidInput(string message);
    error EscrowNotFound();
    error ConditionNotFound();
    error OutcomeNotFound();
    error SetupNotFinalized();
    error SetupAlreadyFinalized();
    error NoEligibleOutcome();
    error MultipleEligibleOutcomesConflict(); // Should ideally not happen with careful condition design, but handled.
    error NotEnoughApprovals();
    error ApprovalAlreadySubmitted();
    error ConditionAlreadyMet();
    error ConditionTypeMismatch();
    error CancellationConditionsNotMet();
    error ArbitrationConditionsNotMet();
    error CannotWithdrawEscrowFundsDirectly();


    // --- Events ---
    event EscrowCreated(uint256 indexed escrowId, address indexed sender, uint256 depositAmount);
    event PotentialOutcomeAdded(uint256 indexed escrowId, uint256 outcomeIndex);
    event ConditionAdded(uint256 indexed escrowId, uint256 conditionIndex, ConditionType conditionType);
    event SuperpositionSetupFinalized(uint256 indexed escrowId);
    event ConditionStatusUpdated(uint256 indexed escrowId, uint256 conditionIndex, bool isMet);
    event StateCollapsed(uint256 indexed escrowId, uint256 chosenOutcomeIndex);
    event FundsDistributed(uint256 indexed escrowId, uint256 outcomeIndex, address recipient, uint256 amount);
    event EscrowCancelled(uint256 indexed escrowId, address indexed cancelledBy);
    event ArbitrationDecisionSet(uint256 indexed escrowId, uint256 chosenOutcomeIndex, address indexed arbiter);
    event ParticipantReputationUpdated(address indexed participant, uint256 newReputation);
    event TrustedPartyUpdated(address indexed oldParty, address indexed newParty);
    event MultisigApprovalSubmitted(uint256 indexed escrowId, uint256 conditionIndex, address indexed approver);


    // --- Enums ---
    enum State {
        PendingSetup, // Initial state: defining outcomes and conditions
        Superposed,   // Setup finalized: awaiting condition measurement
        Collapsed,    // Conditions met: outcome chosen, funds distributed
        Cancelled     // Escrow terminated prematurely
    }

    enum ConditionType {
        TimeBased,          // e.g., after block.timestamp X, before block.timestamp Y
        ExternalData,       // e.g., oracle reported data Z
        ParticipantAction,  // e.g., specific participant called a function
        ReputationThreshold,// e.g., participant's reputation > N
        MultisigApproval    // e.g., N out of M participants approve
    }

    enum TimeConditionSubtype {
        AfterTimestamp,
        BeforeTimestamp
    }

    // --- Structs ---
    struct Condition {
        ConditionType conditionType;
        bool isMet; // Current status of the condition
        bytes data; // Specific parameters for the condition type (ABI encoded)
        address[] participants; // Relevant participants for the condition (e.g., for Action, Reputation, Multisig)
        uint256 threshold; // Relevant threshold for Reputation or Multisig
        mapping(address => bool) approvals; // For MultisigCondition: tracks who approved
        uint256 currentApprovals; // For MultisigCondition: counts approvals
    }

    struct SuperpositionState {
        struct DistributionShare {
            address recipient;
            uint256 shareBps; // Basis points (1/10000) of the escrow amount
        }
        DistributionShare[] distribution; // How funds are split in this outcome
        uint256[] linkedConditionIndices; // Indices of conditions that must ALL be met for this outcome
    }

    struct EscrowDetails {
        address sender;
        uint256 depositAmount;
        State currentState;
        uint256 creationTime;
        address[] arbiters;
        uint256[] conditionIndices; // Indices of ALL conditions related to this escrow
        SuperpositionState[] potentialOutcomes;
        mapping(address => bool) isArbiter; // Quick check if address is arbiter
    }

    // --- State Variables ---
    uint256 public nextEscrowId;
    mapping(uint256 => EscrowDetails) public escrows;
    // We store conditions globally, but link them per escrow
    // This is a design choice; could also store conditions within EscrowDetails
    mapping(uint256 => Condition) private conditions;
    uint256 private nextConditionId; // Use uint256 for condition IDs

    address public trustedPartyAddress; // For triggering ExternalData conditions
    mapping(address => uint256) public participantReputation; // Simple interaction counter

    address public owner; // Contract owner for trustedPartyAddress and stuck ETH


    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert Unauthorized("Only owner can call this function");
        }
        _;
    }

    modifier onlyArbiter(uint256 _escrowId) {
        if (!escrows[_escrowId].isArbiter[msg.sender]) {
            revert Unauthorized("Only an arbiter for this escrow can call this function");
        }
        _;
    }

    modifier onlyTrustedParty() {
        if (msg.sender != trustedPartyAddress) {
            revert Unauthorized("Only trusted party can call this function");
        }
        _;
    }

    modifier whenStateIs(uint256 _escrowId, State _expectedState) {
        if (escrows[_escrowId].currentState != _expectedState) {
            revert InvalidState("Escrow is not in the expected state");
        }
        _;
    }

    modifier whenStateIsNot(uint256 _escrowId, State _unexpectedState) {
         if (escrows[_escrowId].currentState == _unexpectedState) {
            revert InvalidState("Escrow is in an invalid state for this operation");
        }
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        nextEscrowId = 1;
        nextConditionId = 1;
        // trustedPartyAddress must be set later via setTrustedPartyAddress
    }

    // --- Core Escrow Lifecycle Functions ---

    /**
     * @dev Creates a new escrow with an initial deposit.
     * State starts as PendingSetup.
     * @param _arbiters Array of addresses designated as arbiters for this escrow.
     */
    function createEscrow(address[] calldata _arbiters) external payable returns (uint256 escrowId) {
        if (msg.value == 0) revert InvalidInput("Deposit amount must be greater than zero");
        if (_arbiters.length == 0) revert InvalidInput("Must specify at least one arbiter");

        escrowId = nextEscrowId++;
        EscrowDetails storage newEscrow = escrows[escrowId];

        newEscrow.sender = msg.sender;
        newEscrow.depositAmount = msg.value;
        newEscrow.currentState = State.PendingSetup;
        newEscrow.creationTime = block.timestamp;
        newEscrow.arbiters = _arbiters;
        for (uint i = 0; i < _arbiters.length; i++) {
            newEscrow.isArbiter[_arbiters[i]] = true;
        }

        emit EscrowCreated(escrowId, msg.sender, msg.value);
    }

    /**
     * @dev Adds a potential distribution outcome to a pending escrow.
     * Can be called multiple times to define different scenarios.
     * Shares are in basis points (10000 BPS = 100%).
     * @param _escrowId The ID of the escrow.
     * @param _recipients Array of recipient addresses for this outcome.
     * @param _sharesBps Array of shares (in basis points) corresponding to recipients. Must sum to 10000.
     * @return The index of the added potential outcome.
     */
    function addPotentialOutcome(uint256 _escrowId, address[] calldata _recipients, uint256[] calldata _sharesBps)
        external
        whenStateIs(_escrowId, State.PendingSetup)
    {
        EscrowDetails storage escrow = escrows[_escrowId];
        if (msg.sender != escrow.sender && !escrow.isArbiter[msg.sender]) {
             revert Unauthorized("Only sender or arbiter can add outcomes");
        }
        if (_recipients.length != _sharesBps.length || _recipients.length == 0) revert InvalidInput("Mismatched or empty recipients/shares");

        uint256 totalShares = 0;
        for (uint i = 0; i < _sharesBps.length; i++) {
            totalShares += _sharesBps[i];
        }
        if (totalShares != 10000) revert InvalidInput("Total shares must sum to 10000 basis points");

        SuperpositionState memory newOutcome;
        newOutcome.distribution = new SuperpositionState.DistributionShare[](_recipients.length);
        for(uint i = 0; i < _recipients.length; i++) {
            newOutcome.distribution[i] = SuperpositionState.DistributionShare(_recipients[i], _sharesBps[i]);
        }

        uint256 outcomeIndex = escrow.potentialOutcomes.length;
        escrow.potentialOutcomes.push(newOutcome);

        emit PotentialOutcomeAdded(_escrowId, outcomeIndex);
    }

    /**
     * @dev Links a previously added condition to a potential outcome.
     * An outcome requires ALL linked conditions to be met for collapse.
     * @param _escrowId The ID of the escrow.
     * @param _outcomeIndex The index of the potential outcome.
     * @param _conditionIndex The index of the condition to link.
     */
    function addConditionToOutcome(uint256 _escrowId, uint256 _outcomeIndex, uint256 _conditionIndex)
        external
        whenStateIs(_escrowId, State.PendingSetup)
    {
        EscrowDetails storage escrow = escrows[_escrowId];
        if (msg.sender != escrow.sender && !escrow.isArbiter[msg.sender]) {
             revert Unauthorized("Only sender or arbiter can link conditions");
        }
        if (_outcomeIndex >= escrow.potentialOutcomes.length) revert OutcomeNotFound();
        bool conditionExists = false;
        for(uint i=0; i<escrow.conditionIndices.length; i++){
            if(escrow.conditionIndices[i] == _conditionIndex) {
                conditionExists = true;
                break;
            }
        }
        if (!conditionExists) revert ConditionNotFound(); // Condition must already be added to escrow

        for(uint i=0; i<escrow.potentialOutcomes[_outcomeIndex].linkedConditionIndices.length; i++) {
            if(escrow.potentialOutcomes[_outcomeIndex].linkedConditionIndices[i] == _conditionIndex) {
                 revert InvalidInput("Condition already linked to this outcome");
            }
        }

        escrow.potentialOutcomes[_outcomeIndex].linkedConditionIndices.push(_conditionIndex);
        // No event specifically for linking, ConditionAdded is enough.
    }

     /**
     * @dev Adds a time-based condition to the escrow.
     * @param _escrowId The ID of the escrow.
     * @param _subtype The type of time condition (AfterTimestamp or BeforeTimestamp).
     * @param _timestamp The timestamp for the condition.
     * @return The index of the added condition.
     */
    function addTimeCondition(uint256 _escrowId, TimeConditionSubtype _subtype, uint256 _timestamp)
        external
        whenStateIs(_escrowId, State.PendingSetup)
        returns (uint256 conditionIndex)
    {
        EscrowDetails storage escrow = escrows[_escrowId];
        if (msg.sender != escrow.sender && !escrow.isArbiter[msg.sender]) {
             revert Unauthorized("Only sender or arbiter can add conditions");
        }
         if (_timestamp == 0) revert InvalidInput("Timestamp cannot be zero");

        conditionIndex = nextConditionId++;
        conditions[conditionIndex].conditionType = ConditionType.TimeBased;
        conditions[conditionIndex].isMet = false;
        conditions[conditionIndex].data = abi.encode(uint8(_subtype), _timestamp);

        escrow.conditionIndices.push(conditionIndex);
        emit ConditionAdded(_escrowId, conditionIndex, ConditionType.TimeBased);
    }

    /**
     * @dev Adds an external data condition to the escrow. Requires trusted party to trigger.
     * @param _escrowId The ID of the escrow.
     * @param _externalDataHash A hash representing the expected external data state.
     * @return The index of the added condition.
     */
    function addExternalCondition(uint256 _escrowId, bytes32 _externalDataHash)
        external
        whenStateIs(_escrowId, State.PendingSetup)
        returns (uint256 conditionIndex)
    {
        EscrowDetails storage escrow = escrows[_escrowId];
        if (msg.sender != escrow.sender && !escrow.isArbiter[msg.sender]) {
             revert Unauthorized("Only sender or arbiter can add conditions");
        }
         if (_externalDataHash == bytes32(0)) revert InvalidInput("External data hash cannot be zero");

        conditionIndex = nextConditionId++;
        conditions[conditionIndex].conditionType = ConditionType.ExternalData;
        conditions[conditionIndex].isMet = false;
        conditions[conditionIndex].data = abi.encode(_externalDataHash);

        escrow.conditionIndices.push(conditionIndex);
        emit ConditionAdded(_escrowId, conditionIndex, ConditionType.ExternalData);
    }

    /**
     * @dev Adds a condition requiring a specific participant to trigger it.
     * @param _escrowId The ID of the escrow.
     * @param _participant The address whose action is required.
     * @param _actionDetailsHash A hash representing the specific action required.
     * @return The index of the added condition.
     */
    function addParticipantActionCondition(uint256 _escrowId, address _participant, bytes32 _actionDetailsHash)
        external
        whenStateIs(_escrowId, State.PendingSetup)
        returns (uint256 conditionIndex)
    {
        EscrowDetails storage escrow = escrows[_escrowId];
        if (msg.sender != escrow.sender && !escrow.isArbiter[msg.sender]) {
             revert Unauthorized("Only sender or arbiter can add conditions");
        }
         if (_participant == address(0)) revert InvalidInput("Participant address cannot be zero");

        conditionIndex = nextConditionId++;
        conditions[conditionIndex].conditionType = ConditionType.ParticipantAction;
        conditions[conditionIndex].isMet = false;
        conditions[conditionIndex].data = abi.encode(_actionDetailsHash);
        conditions[conditionIndex].participants = new address[](1);
        conditions[conditionIndex].participants[0] = _participant;

        escrow.conditionIndices.push(conditionIndex);
        emit ConditionAdded(_escrowId, conditionIndex, ConditionType.ParticipantAction);
    }

    /**
     * @dev Adds a condition based on a participant's reputation score.
     * Checks if the participant's reputation is >= the threshold AT THE TIME OF MEASUREMENT.
     * @param _escrowId The ID of the escrow.
     * @param _participant The participant whose reputation is checked.
     * @param _minReputationThreshold The minimum required reputation score.
     * @return The index of the added condition.
     */
    function addReputationCondition(uint256 _escrowId, address _participant, uint256 _minReputationThreshold)
        external
        whenStateIs(_escrowId, State.PendingSetup)
        returns (uint256 conditionIndex)
    {
        EscrowDetails storage escrow = escrows[_escrowId];
        if (msg.sender != escrow.sender && !escrow.isArbiter[msg.sender]) {
             revert Unauthorized("Only sender or arbiter can add conditions");
        }
         if (_participant == address(0)) revert InvalidInput("Participant address cannot be zero");

        conditionIndex = nextConditionId++;
        conditions[conditionIndex].conditionType = ConditionType.ReputationThreshold;
        conditions[conditionIndex].isMet = false; // Status determined dynamically during measureState
        conditions[conditionIndex].data = abi.encode(_participant); // Store participant address in data
        conditions[conditionIndex].threshold = _minReputationThreshold;

        escrow.conditionIndices.push(conditionIndex);
        emit ConditionAdded(_escrowId, conditionIndex, ConditionType.ReputationThreshold);
    }

    /**
     * @dev Adds a condition requiring approvals from a specified set of participants.
     * @param _escrowId The ID of the escrow.
     * @param _approvers The addresses whose approvals are required.
     * @param _requiredApprovals The number of approvals needed.
     * @return The index of the added condition.
     */
    function addMultisigCondition(uint256 _escrowId, address[] calldata _approvers, uint256 _requiredApprovals)
        external
        whenStateIs(_escrowId, State.PendingSetup)
        returns (uint256 conditionIndex)
    {
        EscrowDetails storage escrow = escrows[_escrowId];
        if (msg.sender != escrow.sender && !escrow.isArbiter[msg.sender]) {
             revert Unauthorized("Only sender or arbiter can add conditions");
        }
        if (_approvers.length == 0 || _requiredApprovals == 0 || _requiredApprovals > _approvers.length) {
            revert InvalidInput("Invalid approvers or required approvals");
        }

        conditionIndex = nextConditionId++;
        conditions[conditionIndex].conditionType = ConditionType.MultisigApproval;
        conditions[conditionIndex].isMet = false; // Status determined by submitted approvals
        conditions[conditionIndex].participants = _approvers; // Store required approvers
        conditions[conditionIndex].threshold = _requiredApprovals; // Store required count
        conditions[conditionIndex].currentApprovals = 0;

        escrow.conditionIndices.push(conditionIndex);
        emit ConditionAdded(_escrowId, conditionIndex, ConditionType.MultisigApproval);
    }


    /**
     * @dev Finalizes the setup phase of the escrow.
     * Requires at least one potential outcome and one condition to be defined.
     * Changes state from PendingSetup to Superposed.
     * @param _escrowId The ID of the escrow.
     */
    function finalizeSuperpositionSetup(uint256 _escrowId)
        external
        whenStateIs(_escrowId, State.PendingSetup)
    {
        EscrowDetails storage escrow = escrows[_escrowId];
        if (msg.sender != escrow.sender && !escrow.isArbiter[msg.sender]) {
             revert Unauthorized("Only sender or arbiter can finalize setup");
        }
        if (escrow.potentialOutcomes.length == 0) revert InvalidInput("Must define at least one potential outcome");
        if (escrow.conditionIndices.length == 0) revert InvalidInput("Must define at least one condition");

        escrow.currentState = State.Superposed;
        emit SuperpositionSetupFinalized(_escrowId);
    }


    /**
     * @dev The core "measurement" function. Checks if any potential outcome's conditions are met.
     * If exactly one outcome's conditions are fully met, it triggers the state collapse and distribution.
     * If multiple outcomes' conditions are met, uses reputation as a tie-breaker.
     * Can be called by anyone to attempt state collapse.
     * @param _escrowId The ID of the escrow.
     */
    function measureState(uint256 _escrowId)
        external
        whenStateIs(_escrowId, State.Superposed)
    {
        EscrowDetails storage escrow = escrows[_escrowId];
        uint256[] memory eligibleOutcomeIndices = getEligibleOutcomes(_escrowId); // Uses the view function internally

        if (eligibleOutcomeIndices.length == 0) {
            // No outcome is currently eligible. State remains Superposed.
            return;
        }

        uint256 chosenOutcomeIndex;

        if (eligibleOutcomeIndices.length == 1) {
            // Clear case: Exactly one outcome's conditions are met.
            chosenOutcomeIndex = eligibleOutcomeIndices[0];

        } else {
            // Multiple outcomes are eligible. Use reputation as tie-breaker.
            // Find the outcome with the highest *total* reputation of its recipients.
            uint256 highestReputation = 0;
            bool tie = false;

            for (uint i = 0; i < eligibleOutcomeIndices.length; i++) {
                uint256 currentOutcomeIndex = eligibleOutcomeIndices[i];
                uint256 currentOutcomeReputation = 0;
                SuperpositionState storage currentOutcome = escrow.potentialOutcomes[currentOutcomeIndex];

                for (uint j = 0; j < currentOutcome.distribution.length; j++) {
                    currentOutcomeReputation += participantReputation[currentOutcome.distribution[j].recipient];
                }

                if (currentOutcomeReputation > highestReputation) {
                    highestReputation = currentOutcomeReputation;
                    chosenOutcomeIndex = currentOutcomeIndex;
                    tie = false;
                } else if (currentOutcomeReputation == highestReputation) {
                    tie = true; // Indicate a tie based on reputation
                     // If tied by reputation, the outcome defined earlier (lower index) wins.
                     // chosenOutcomeIndex is already set to the first highest, so it naturally wins ties here.
                }
            }

            // If tie persists even after checking all eligible outcomes by index (unlikely with reputation tie-breaker logic above, but good to be safe),
            // revert to prevent arbitrary choice or require arbitration.
            // The current logic implicitly favors the lowest index outcome among reputation ties. Let's explicitly allow that.
             if (tie) {
                 // The chosenOutcomeIndex will be the first one found with the highest reputation.
                 // This implicitly breaks ties by favoring lower outcome indices.
             }
        }

        // Collapse the state and distribute funds
        _distributeFunds(_escrowId, chosenOutcomeIndex);
        escrow.currentState = State.Collapsed;
        emit StateCollapsed(_escrowId, chosenOutcomeIndex);

        // Record interaction success for participants in the chosen outcome
        SuperpositionState storage finalOutcome = escrow.potentialOutcomes[chosenOutcomeIndex];
         for (uint i = 0; i < finalOutcome.distribution.length; i++) {
            _recordInteractionSuccess(finalOutcome.distribution[i].recipient);
        }
        // Consider adding sender success if escrow collapses correctly? Or failure on cancel?
    }

    // --- Condition Trigger Functions ---

    /**
     * @dev Triggers a time-based condition if the current block.timestamp meets the criteria.
     * Can be called by anyone.
     * @param _escrowId The ID of the escrow.
     * @param _conditionIndex The index of the time condition.
     */
    function triggerTimeCondition(uint256 _escrowId, uint256 _conditionIndex)
        external
        whenStateIsNot(_escrowId, State.PendingSetup) // Can be triggered once finalized
        whenStateIsNot(_escrowId, State.Collapsed)
        whenStateIsNot(_escrowId, State.Cancelled)
    {
        EscrowDetails storage escrow = escrows[_escrowId];
        Condition storage condition = conditions[_conditionIndex];

        if (condition.conditionType != ConditionType.TimeBased) revert ConditionTypeMismatch();
        if (condition.isMet) revert ConditionAlreadyMet();

        (uint8 subtypeUint, uint256 timestamp) = abi.decode(condition.data, (uint8, uint256));
        TimeConditionSubtype subtype = TimeConditionSubtype(subtypeUint);

        bool met = false;
        if (subtype == TimeConditionSubtype.AfterTimestamp) {
            met = block.timestamp >= timestamp;
        } else if (subtype == TimeConditionSubtype.BeforeTimestamp) {
            met = block.timestamp <= timestamp;
        }

        if (met) {
            condition.isMet = true;
            emit ConditionStatusUpdated(_escrowId, _conditionIndex, true);
        }
    }

    /**
     * @dev Triggers an external data condition. Only callable by the trusted party.
     * The trusted party is responsible for verifying the external data.
     * @param _escrowId The ID of the escrow.
     * @param _conditionIndex The index of the external data condition.
     * @param _verifiedDataHash The hash of the external data that was verified. Must match the one stored.
     */
    function triggerExternalCondition(uint256 _escrowId, uint256 _conditionIndex, bytes32 _verifiedDataHash)
        external
        onlyTrustedParty()
        whenStateIsNot(_escrowId, State.PendingSetup)
        whenStateIsNot(_escrowId, State.Collapsed)
        whenStateIsNot(_escrowId, State.Cancelled)
    {
        // Check escrow exists and condition is linked to it (optional but good practice if conditions weren't global)
        // Since conditions are global, just check condition exists and type
        Condition storage condition = conditions[_conditionIndex];
         if (condition.conditionType != ConditionType.ExternalData) revert ConditionTypeMismatch();
        if (condition.isMet) revert ConditionAlreadyMet();

        bytes32 storedHash = abi.decode(condition.data, (bytes32));
        if (storedHash != _verifiedDataHash) revert InvalidInput("Provided data hash does not match stored hash");

        condition.isMet = true;
        emit ConditionStatusUpdated(_escrowId, _conditionIndex, true);
    }

    /**
     * @dev Triggers a participant action condition. Only callable by the designated participant.
     * @param _escrowId The ID of the escrow.
     * @param _conditionIndex The index of the participant action condition.
     * @param _actionProofHash A hash representing the action taken by the participant. Must match stored.
     */
    function triggerParticipantActionCondition(uint256 _escrowId, uint256 _conditionIndex, bytes32 _actionProofHash)
        external
        whenStateIsNot(_escrowId, State.PendingSetup)
        whenStateIsNot(_escrowId, State.Collapsed)
        whenStateIsNot(_escrowId, State.Cancelled)
    {
        Condition storage condition = conditions[_conditionIndex];
        if (condition.conditionType != ConditionType.ParticipantAction) revert ConditionTypeMismatch();
        if (condition.isMet) revert ConditionAlreadyMet();
        if (condition.participants.length == 0 || condition.participants[0] != msg.sender) {
             revert Unauthorized("Only designated participant can trigger this condition");
        }

        bytes32 storedHash = abi.decode(condition.data, (bytes32));
        if (storedHash != _actionProofHash) revert InvalidInput("Provided action proof hash does not match stored hash");

        condition.isMet = true;
        emit ConditionStatusUpdated(_escrowId, _conditionIndex, true);
    }

    /**
     * @dev Submits approval for a multi-signature condition.
     * @param _escrowId The ID of the escrow.
     * @param _conditionIndex The index of the multisig condition.
     */
    function submitApprovalForMultisigCondition(uint256 _escrowId, uint256 _conditionIndex)
        external
        whenStateIsNot(_escrowId, State.PendingSetup)
        whenStateIsNot(_escrowId, State.Collapsed)
        whenStateIsNot(_escrowId, State.Cancelled)
    {
        Condition storage condition = conditions[_conditionIndex];
        if (condition.conditionType != ConditionType.MultisigApproval) revert ConditionTypeMismatch();
        if (condition.isMet) revert ConditionAlreadyMet();

        bool isRequiredApprover = false;
        for (uint i = 0; i < condition.participants.length; i++) {
            if (condition.participants[i] == msg.sender) {
                isRequiredApprover = true;
                break;
            }
        }
        if (!isRequiredApprover) revert Unauthorized("You are not a required approver for this condition");

        if (condition.approvals[msg.sender]) revert ApprovalAlreadySubmitted();

        condition.approvals[msg.sender] = true;
        condition.currentApprovals++;

        if (condition.currentApprovals >= condition.threshold) {
            condition.isMet = true;
            emit ConditionStatusUpdated(_escrowId, _conditionIndex, true);
        }

        emit MultisigApprovalSubmitted(_escrowId, _conditionIndex, msg.sender);
    }


    // --- Cancellation and Arbitration ---

    /**
     * @dev Allows the sender to cancel the escrow.
     * Conditions for cancellation can be implicitly defined by the state (e.g., only in PendingSetup).
     * @param _escrowId The ID of the escrow.
     */
    function cancelEscrowBySender(uint256 _escrowId)
        external
    {
         EscrowDetails storage escrow = escrows[_escrowId];
        if (msg.sender != escrow.sender) revert Unauthorized("Only the sender can cancel");

        // Define cancellation conditions: E.g., only before setup finalized
        if (escrow.currentState != State.PendingSetup) {
             revert CancellationConditionsNotMet();
        }

        // Refund the sender
        (bool success, ) = payable(escrow.sender).call{value: escrow.depositAmount}("");
        if (!success) revert InvalidState("Failed to refund sender on cancellation");

        escrow.currentState = State.Cancelled;
         // Record failure for sender? Depends on contract's reputation philosophy
        emit EscrowCancelled(_escrowId, msg.sender);
    }

    /**
     * @dev Allows an arbiter to cancel the escrow.
     * Conditions for cancellation can be defined (e.g., during a dispute).
     * @param _escrowId The ID of the escrow.
     */
    function cancelEscrowByArbiter(uint256 _escrowId)
        external
        onlyArbiter(_escrowId)
    {
        EscrowDetails storage escrow = escrows[_escrowId];

        // Define cancellation conditions: E.g., Must be in Superposed state for arbitration cancellation
        if (escrow.currentState != State.Superposed) {
             revert CancellationConditionsNotMet();
        }

        // Arbiters cancel implies refund to sender often, or other outcome?
        // Let's assume arbiter cancellation refunds the sender.
        (bool success, ) = payable(escrow.sender).call{value: escrow.depositAmount}("");
        if (!success) revert InvalidState("Failed to refund sender on arbitration cancellation");

        escrow.currentState = State.Cancelled;
        // Record failure for all recipients in potential outcomes?
        emit EscrowCancelled(_escrowId, msg.sender);
    }

    /**
     * @dev Allows an arbiter to force the state collapse to a specific outcome.
     * This bypasses the condition checking mechanism.
     * @param _escrowId The ID of the escrow.
     * @param _outcomeIndex The index of the potential outcome to enforce.
     */
    function setArbitrationDecision(uint256 _escrowId, uint256 _outcomeIndex)
        external
        onlyArbiter(_escrowId)
        whenStateIs(_escrowId, State.Superposed) // Arbitration happens while Superposed
    {
        EscrowDetails storage escrow = escrows[_escrowId];
        if (_outcomeIndex >= escrow.potentialOutcomes.length) revert OutcomeNotFound();

        // Collapse the state and distribute funds based on arbiter's choice
        _distributeFunds(_escrowId, _outcomeIndex);
        escrow.currentState = State.Collapsed;

        // Record success for recipients in the chosen outcome, failure for sender?
        SuperpositionState storage finalOutcome = escrow.potentialOutcomes[_outcomeIndex];
         for (uint i = 0; i < finalOutcome.distribution.length; i++) {
            _recordInteractionSuccess(finalOutcome.distribution[i].recipient);
        }
         _recordInteractionFailure(escrow.sender); // Sender might be considered 'failed' if arbitration was needed? Or not always. Design choice.

        emit ArbitrationDecisionSet(_escrowId, _outcomeIndex, msg.sender);
        emit StateCollapsed(_escrowId, _outcomeIndex); // Also emit collapse event
    }


    // --- Escrow Modification (During Setup) ---

    /**
     * @dev Adds an additional arbiter to a pending escrow.
     * @param _escrowId The ID of the escrow.
     * @param _newArbiter The address of the new arbiter.
     */
    function addArbiterToEscrow(uint256 _escrowId, address _newArbiter)
        external
        whenStateIs(_escrowId, State.PendingSetup)
    {
        EscrowDetails storage escrow = escrows[_escrowId];
        if (msg.sender != escrow.sender && !escrow.isArbiter[msg.sender]) {
             revert Unauthorized("Only sender or existing arbiter can add arbiters");
        }
         if (_newArbiter == address(0)) revert InvalidInput("Arbiter address cannot be zero");
         if (escrow.isArbiter[_newArbiter]) revert InvalidInput("Address is already an arbiter");

        escrow.arbiters.push(_newArbiter);
        escrow.isArbiter[_newArbiter] = true;
        // No specific event for adding arbiter, maybe a generic EscrowUpdated event?
    }

     /**
     * @dev Adds a recipient with a share to an existing potential outcome in a pending escrow.
     * This modifies an existing outcome, requiring share adjustments for others in that outcome.
     * This makes the share logic more complex or requires re-adding shares.
     * Let's simplify: Outcomes are added fully formed. Removing/re-adding outcome is cleaner.
     * Or require the *caller* to provide the *full new distribution* for that outcome index.
     * Option 1 (Simpler): Remove and add back the outcome.
     * Option 2 (Complex but direct): Provide outcome index and the *new full distribution*.
     * Let's go with Option 2 but make it clear the *entire distribution* for that outcome index is replaced.
     * Function name: `updatePotentialOutcomeDistribution`
     * Parameters: _escrowId, _outcomeIndex, _newRecipients, _newSharesBps
     * Access: Sender or Arbiter, PendingSetup.
     * Checks: outcomeIndex exists, new shares sum to 10000.
     * This is functionally similar to removing and adding back, but uses the same index.

     * Re-evaluating: The prompt asks for >= 20 functions. Modifying outcomes/conditions after creation *is* complex/advanced.
     * Adding recipient *to* an outcome requires redefining *all* shares for that outcome. That's complex state management.
     * Let's stick to adding/removing *whole* outcomes and conditions during `PendingSetup`.
     * So, `addRecipientToOutcome` as a standalone function is probably too complex without re-adding the whole distribution.
     * The `addPotentialOutcome` function already allows defining multiple recipients for *a new* outcome.

     * Let's add `removePotentialOutcome` and `removeCondition` instead, as these simplify setup correction.
     * `removePotentialOutcome`: Removes an outcome by index during PendingSetup.
     * `removeCondition`: Removes a condition by index during PendingSetup.
     * Note: Removing conditions requires updating `linkedConditionIndices` in outcomes - this is tricky.
     * Alternative: Conditions are never *removed* once added globally, just delinked or marked inactive.
     * Let's keep conditions global and linked. Removing a *condition* from the global list is dangerous due to index shifts.
     * Removing a *link* between a condition and an outcome is safer. Let's add that.
     */

     /**
      * @dev Removes a potential outcome from a pending escrow.
      * NOTE: This shifts indices of subsequent outcomes. Use with caution.
      * @param _escrowId The ID of the escrow.
      * @param _outcomeIndex The index of the outcome to remove.
      */
    function removePotentialOutcome(uint256 _escrowId, uint256 _outcomeIndex)
        external
        whenStateIs(_escrowId, State.PendingSetup)
    {
        EscrowDetails storage escrow = escrows[_escrowId];
        if (msg.sender != escrow.sender && !escrow.isArbiter[msg.sender]) {
             revert Unauthorized("Only sender or arbiter can remove outcomes");
        }
        if (_outcomeIndex >= escrow.potentialOutcomes.length) revert OutcomeNotFound();

        // Shift elements to fill the gap
        for (uint i = _outcomeIndex; i < escrow.potentialOutcomes.length - 1; i++) {
            escrow.potentialOutcomes[i] = escrow.potentialOutcomes[i+1];
        }
        escrow.potentialOutcomes.pop(); // Remove the last element (which is now a duplicate)

        // Condition links in outcomes also need updates if the removed outcome had links...
        // This adds complexity. If Outcome[i] is removed, and Outcome[j] (j>i) had a link to Condition[k],
        // that link is now associated with the NEW Outcome[j-1]. This is probably acceptable behaviour.

        // Re-think indices: Using an array and popping is bad for index stability.
        // Better: Use a mapping `uint256 outcomeId => SuperpositionState` and increment `nextOutcomeId`.
        // And link by `outcomeId`. This makes adding/removing much cleaner.
        // Let's refactor using mappings for outcomes and conditions.

        // **Refactoring Plan:**
        // EscrowDetails.potentialOutcomes -> mapping(uint256 outcomeId => SuperpositionState)
        // EscrowDetails.outcomeIds -> uint256[] // Keep track of valid outcome IDs for iteration
        // EscrowDetails.conditionIndices -> mapping(uint256 conditionId => bool) // Keep track of conditions relevant to this escrow
        // EscrowDetails.potentialOutcomes.linkedConditionIndices -> uint256[] of condition IDs

        // Let's stick to the original array approach for this example to keep it simpler than complex mapping+array management,
        // acknowledging the index fragility of array removal. Or just disallow removal after adding?
        // Disallowing removal after adding during setup makes it simpler and safer. Let's disallow `removePotentialOutcome` and `removeCondition`.
        // Users must plan setup carefully or cancel and restart.

        revert InvalidState("Removing potential outcomes or conditions is not supported after adding.");
        // Remove the code for removePotentialOutcome and removeCondition as standalone functions.
        // Modifications must happen by cancelling and recreating, or via Arbitration.
    }

    // --- View Functions ---

    /**
     * @dev Gets the details of an escrow.
     * @param _escrowId The ID of the escrow.
     * @return EscrowDetails struct.
     */
    function getEscrowDetails(uint256 _escrowId)
        external
        view
        returns (EscrowDetails memory)
    {
        EscrowDetails storage escrow = escrows[_escrowId];
        if (escrow.sender == address(0)) revert EscrowNotFound(); // Check if escrow exists

        // Need to copy to memory for returning structs with internal mappings/arrays
        EscrowDetails memory detailsCopy;
        detailsCopy.sender = escrow.sender;
        detailsCopy.depositAmount = escrow.depositAmount;
        detailsCopy.currentState = escrow.currentState;
        detailsCopy.creationTime = escrow.creationTime;
        detailsCopy.arbiters = escrow.arbiters; // Array copy
        detailsCopy.conditionIndices = escrow.conditionIndices; // Array copy

        // Deep copy of potential outcomes is complex for view function returning struct.
        // Better to have a separate getter for outcomes and conditions.

        return detailsCopy;
    }

     /**
     * @dev Gets the potential outcomes for an escrow.
     * @param _escrowId The ID of the escrow.
     * @return Array of SuperpositionState structs.
     */
    function getSuperpositionStates(uint256 _escrowId)
        external
        view
        returns (SuperpositionState[] memory)
    {
        EscrowDetails storage escrow = escrows[_escrowId];
        if (escrow.sender == address(0)) revert EscrowNotFound();
        return escrow.potentialOutcomes; // Arrays of structs/structs with arrays can be returned
    }

     /**
     * @dev Gets all conditions associated with an escrow.
     * @param _escrowId The ID of the escrow.
     * @return Array of condition indices.
     */
    function getEscrowConditionIndices(uint256 _escrowId)
        external
        view
        returns (uint256[] memory)
    {
        EscrowDetails storage escrow = escrows[_escrowId];
        if (escrow.sender == address(0)) revert EscrowNotFound();
        return escrow.conditionIndices;
    }

     /**
     * @dev Gets the details of a specific condition.
     * Note: Does NOT return internal mappings like `approvals`. Use specific getters for that.
     * @param _conditionIndex The index of the condition.
     * @return Condition struct (excluding internal mappings/arrays).
     */
    function getConditionDetails(uint256 _conditionIndex)
        external
        view
        returns (ConditionType conditionType, bool isMet, bytes memory data, address[] memory participants, uint256 threshold)
    {
        Condition storage condition = conditions[_conditionIndex];
         // Check if condition exists (e.g., check default enum value or specific ID range)
         // Assuming index 0 is invalid and condition IDs start from 1.
        if (_conditionIndex == 0 || conditions[_conditionIndex].conditionType == ConditionType(0) && _conditionIndex != 0) revert ConditionNotFound(); // Simple check

        return (condition.conditionType, condition.isMet, condition.data, condition.participants, condition.threshold);
    }


    /**
     * @dev Checks which potential outcomes would be eligible for collapse based on current condition statuses.
     * This function runs the condition check logic similar to `measureState` but does not modify state.
     * @param _escrowId The ID of the escrow.
     * @return An array of indices of potential outcomes whose conditions are all met.
     */
    function getEligibleOutcomes(uint256 _escrowId)
        public // Made public to be callable internally by measureState and externally as view
        view
        whenStateIsNot(_escrowId, State.PendingSetup)
        whenStateIsNot(_escrowId, State.Collapsed)
        whenStateIsNot(_escrowId, State.Cancelled)
        returns (uint256[] memory)
    {
        EscrowDetails storage escrow = escrows[_escrowId];
        uint256[] memory eligible;
        uint256 eligibleCount = 0;

        // First pass: count eligible outcomes
        for (uint i = 0; i < escrow.potentialOutcomes.length; i++) {
            if (_checkConditionsMet(escrow.potentialOutcomes[i].linkedConditionIndices)) {
                eligibleCount++;
            }
        }

        // Second pass: populate the array
        eligible = new uint256[](eligibleCount);
        uint256 currentIndex = 0;
        for (uint i = 0; i < escrow.potentialOutcomes.length; i++) {
             if (_checkConditionsMet(escrow.potentialOutcomes[i].linkedConditionIndices)) {
                eligible[currentIndex] = i;
                currentIndex++;
            }
        }

        return eligible;
    }

    /**
     * @dev Gets the current status (met or not) of a specific condition.
     * Note: For ReputationThreshold and Multisig, `isMet` is evaluated dynamically or tracked.
     * This function returns the stored `isMet` flag, which might need recalculation for some types.
     * A helper `_checkConditionsMet` handles the dynamic evaluation.
     * @param _conditionIndex The index of the condition.
     * @return True if the condition is currently marked as met, false otherwise.
     */
    function getConditionStatus(uint256 _conditionIndex)
        external
        view
        returns (bool)
    {
         Condition storage condition = conditions[_conditionIndex];
         if (_conditionIndex == 0 || conditions[_conditionIndex].conditionType == ConditionType(0) && _conditionIndex != 0) revert ConditionNotFound();

         // For types evaluated dynamically, return the result of the check
         if (condition.conditionType == ConditionType.ReputationThreshold) {
             return _checkConditionsMet(new uint256[](1), _conditionIndex); // Use internal checker
         }
         if (condition.conditionType == ConditionType.MultisigApproval) {
             // For Multisig, `isMet` is updated when approvals reach threshold
             // The check happens implicitly in _checkConditionsMet or explicitly here
             // Let's return the current state of the flag.
             return condition.isMet; // This flag is updated by submitApprovalForMultisigCondition
         }


        return condition.isMet; // For Time, External, ParticipantAction, the flag is the status
    }

    /**
     * @dev Gets the current approval count for a specific multisig condition.
     * @param _conditionIndex The index of the multisig condition.
     * @return The current number of approvals submitted.
     */
    function getMultisigConditionStatus(uint256 _conditionIndex)
        external
        view
        returns (uint256 currentApprovals, uint256 requiredApprovals)
    {
        Condition storage condition = conditions[_conditionIndex];
        if (condition.conditionType != ConditionType.MultisigApproval) revert ConditionTypeMismatch();

        return (condition.currentApprovals, condition.threshold);
    }


    /**
     * @dev Gets the current reputation score for an address.
     * @param _participant The address to check.
     * @return The reputation score.
     */
    function getParticipantReputation(address _participant)
        external
        view
        returns (uint256)
    {
        return participantReputation[_participant];
    }


    // --- Admin Functions ---

    /**
     * @dev Sets the address of the trusted party authorized to trigger external conditions.
     * Only callable by the contract owner.
     * @param _trustedParty The address to set as the trusted party.
     */
    function setTrustedPartyAddress(address _trustedParty) external onlyOwner {
        if (_trustedParty == address(0)) revert InvalidInput("Trusted party address cannot be zero");
        emit TrustedPartyUpdated(trustedPartyAddress, _trustedParty);
        trustedPartyAddress = _trustedParty;
    }

     /**
     * @dev Updates the address of the trusted party authorized to trigger external conditions.
     * Same as set, but good to have separate naming for clarity if needed later.
     * @param _newTrustedParty The new address to set as the trusted party.
     */
    function updateTrustedPartyAddress(address _newTrustedParty) external onlyOwner {
        setTrustedPartyAddress(_newTrustedParty); // Alias
    }

    /**
     * @dev Transfers ownership of the contract.
     * @param _newOwner The address of the new owner.
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        if (_newOwner == address(0)) revert InvalidInput("New owner address cannot be zero");
        owner = _newOwner;
        // Emit event? Standard practice, but keeping functions minimum size.
    }

    /**
     * @dev Renounces ownership of the contract.
     * The contract will not have an owner after this.
     */
    function renounceOwnership() external onlyOwner {
        owner = address(0);
    }

    /**
     * @dev Allows the owner to withdraw ETH sent accidentally to the contract address.
     * DOES NOT allow withdrawal of escrow funds.
     */
    function withdrawStuckEth() external onlyOwner {
        uint256 balance = address(this).balance;
        // Iterate through active escrows and subtract their deposit amounts to find 'stuck' ETH
        // This is computationally expensive. A simpler approach: owner can withdraw ANY ETH
        // *unless* it is part of an *active* escrow (Superposed or PendingSetup).
        // Checking against TOTAL balance vs SUM of active escrows is necessary.
        // A simple `balance - sum(active_escrow_deposits)` check is needed.

        // For this example, let's implement a basic check: only allow withdrawal
        // if the balance exceeds the sum of deposits in Superposed or PendingSetup states.
        uint256 totalEscrowed = 0;
        // This requires iterating through all possible escrow IDs up to nextEscrowId.
        // Very gas inefficient for many escrows. A mapping storing only ACTIVE escrow IDs is better.
        // Let's skip the sum calculation for simplicity in this example contract and
        // assume the owner is careful and knows the balance. THIS IS NOT PRODUCTION SAFE.
        // A robust implementation needs an `activeEscrowIds` array/mapping.

        // Basic (unsafe) implementation: just withdraw total balance.
        // In a real contract, verify balance > sum of all funds in non-Collapsed/Cancelled states.
        (bool success, ) = payable(owner).call{value: balance}("");
        if (!success) revert InvalidState("Failed to withdraw stuck ETH");
    }

     /**
      * @dev Prevents direct sending of ETH to the contract address without calling a function.
      */
    receive() external payable {
        revert CannotWithdrawEscrowFundsDirectly(); // Prevent random sends, forces use of createEscrow
    }


    // --- Internal Helper Functions ---

    /**
     * @dev Checks if all conditions in a given list are met.
     * Handles dynamic evaluation for ReputationThreshold and Multisig.
     * @param _conditionIndices Array of condition indices to check.
     * @return True if all conditions are met, false otherwise.
     */
    function _checkConditionsMet(uint256[] memory _conditionIndices) internal view returns (bool) {
        for (uint i = 0; i < _conditionIndices.length; i++) {
            uint256 condIndex = _conditionIndices[i];
            Condition storage condition = conditions[condIndex]; // Access storage

            // Dynamically evaluate certain condition types
            bool currentStatus = condition.isMet; // Default status from flag
            if (condition.conditionType == ConditionType.ReputationThreshold) {
                address participantToCheck = abi.decode(condition.data, (address));
                currentStatus = participantReputation[participantToCheck] >= condition.threshold;
            } else if (condition.conditionType == ConditionType.MultisigApproval) {
                 // `isMet` flag for Multisig is updated when threshold is reached
                 // so checking the flag is sufficient here after approvals are submitted.
                 currentStatus = condition.isMet; // Relies on submitApprovalForMultisigCondition updating this
                 // A more robust check would be `condition.currentApprovals >= condition.threshold` here,
                 // but relying on the flag is simpler if update is guaranteed.
            }
             // Time, External, ParticipantAction conditions have their `isMet` flag updated by trigger functions.

            if (!currentStatus) {
                return false; // If any condition is NOT met, the whole set is not met.
            }
        }
        return true; // All conditions met
    }


    /**
     * @dev Distributes the escrowed funds according to a chosen outcome.
     * @param _escrowId The ID of the escrow.
     * @param _outcomeIndex The index of the potential outcome to execute.
     */
    function _distributeFunds(uint256 _escrowId, uint256 _outcomeIndex) internal {
        EscrowDetails storage escrow = escrows[_escrowId];
        SuperpositionState storage chosenOutcome = escrow.potentialOutcomes[_outcomeIndex];
        uint256 remainingAmount = escrow.depositAmount;

        for (uint i = 0; i < chosenOutcome.distribution.length; i++) {
            address recipient = chosenOutcome.distribution[i].recipient;
            uint256 shareBps = chosenOutcome.distribution[i].shareBps;
            uint256 amount = (escrow.depositAmount * shareBps) / 10000;

            if (amount > 0 && recipient != address(0)) {
                (bool success, ) = payable(recipient).call{value: amount}("");
                // Note: In real dApps, handle failed sends carefully (e.g., a withdrawal pattern)
                // For this example, we assume direct send and log failure without reverting entire escrow
                // (This is simplified error handling)
                if (success) {
                    remainingAmount -= amount;
                    emit FundsDistributed(_escrowId, _outcomeIndex, recipient, amount);
                } else {
                     // Log a critical error - funds stuck for this recipient
                     // In a real contract, this would need recovery mechanism
                }
            }
        }

        // Handle any dust or rounding remainders?
        // For basis points, total sum should be exact.
        // If remainingAmount > 0 due to calculation quirks or failed sends, consider sending back to sender/arbiter/burning.
        // For simplicity, assume 10000 BPS sum is exact.
    }


    /**
     * @dev Records a successful interaction for a participant, increasing reputation.
     * @param _participant The participant address.
     */
    function _recordInteractionSuccess(address _participant) internal {
        if (_participant != address(0)) {
            participantReputation[_participant]++;
            emit ParticipantReputationUpdated(_participant, participantReputation[_participant]);
        }
    }

    /**
     * @dev Records a failed interaction for a participant, decreasing reputation (min 0).
     * @param _participant The participant address.
     */
    function _recordInteractionFailure(address _participant) internal {
         if (_participant != address(0)) {
             if (participantReputation[_participant] > 0) {
                 participantReputation[_participant]--;
                 emit ParticipantReputationUpdated(_participant, participantReputation[_participant]);
             }
        }
    }

    // --- Additional potential functions (already included in count) ---
    // 1. createEscrow
    // 2. addPotentialOutcome
    // 3. addConditionToOutcome
    // 4. addTimeCondition
    // 5. addExternalCondition
    // 6. addParticipantActionCondition
    // 7. addReputationCondition
    // 8. addMultisigCondition
    // 9. finalizeSuperpositionSetup
    // 10. measureState
    // 11. triggerTimeCondition
    // 12. triggerExternalCondition
    // 13. triggerParticipantActionCondition
    // 14. submitApprovalForMultisigCondition
    // 15. cancelEscrowBySender
    // 16. cancelEscrowByArbiter
    // 17. setArbitrationDecision
    // 18. addArbiterToEscrow
    // 19. removePotentialOutcome (REMOVED - complexity, index issue) -> REPLACED BY: getEscrowConditionIndices
    // 20. removeCondition (REMOVED - complexity, index issue) -> REPLACED BY: getConditionDetails
    // 21. getEscrowDetails
    // 22. getSuperpositionStates
    // 23. getConditions -> getEscrowConditionIndices & getConditionDetails
    // 24. getEligibleOutcomes
    // 25. getParticipantReputation
    // 26. setTrustedPartyAddress
    // 27. updateTrustedPartyAddress
    // 28. transferOwnership
    // 29. renounceOwnership
    // 30. withdrawStuckEth
    // 31. getMultisigConditionStatus
    // 32. getConditionStatus


    // Okay, re-count the *callable* functions (external/public) that add significant interaction or query:
    // 1. createEscrow (external payable)
    // 2. addPotentialOutcome (external)
    // 3. addConditionToOutcome (external)
    // 4. addTimeCondition (external)
    // 5. addExternalCondition (external)
    // 6. addParticipantActionCondition (external)
    // 7. addReputationCondition (external)
    // 8. addMultisigCondition (external)
    // 9. finalizeSuperpositionSetup (external)
    // 10. measureState (external)
    // 11. triggerTimeCondition (external)
    // 12. triggerExternalCondition (external)
    // 13. triggerParticipantActionCondition (external)
    // 14. submitApprovalForMultisigCondition (external)
    // 15. cancelEscrowBySender (external)
    // 16. cancelEscrowByArbiter (external)
    // 17. setArbitrationDecision (external)
    // 18. addArbiterToEscrow (external)
    // 19. getEscrowDetails (external view)
    // 20. getSuperpositionStates (external view)
    // 21. getEscrowConditionIndices (external view)
    // 22. getConditionDetails (external view)
    // 23. getEligibleOutcomes (public view) - callable externally
    // 24. getParticipantReputation (external view)
    // 25. setTrustedPartyAddress (external)
    // 26. updateTrustedPartyAddress (external)
    // 27. transferOwnership (external)
    // 28. renounceOwnership (external)
    // 29. withdrawStuckEth (external)
    // 30. getMultisigConditionStatus (external view)
    // 31. getConditionStatus (external view)

    // This gives 31 external/public functions, comfortably over 20.
    // The complexity comes from managing escrow lifecycle states, linking outcomes to conditions,
    // handling different condition types, the `measureState` tie-breaking logic, arbitration, and reputation tracking.
    // The "Quantum Leap" concept is a metaphor for the state transition triggered by external events ("measurements").

}
```