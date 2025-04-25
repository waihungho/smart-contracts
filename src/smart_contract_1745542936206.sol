Okay, let's design a smart contract that simulates a "Decentralized Adaptive Chronicle". This contract manages a state that evolves over discrete epochs, influenced by participant actions, reputation (Influence), and internal parameters that can be adjusted through a complex voting-like process.

It avoids simple ERC-20/ERC-721 patterns and incorporates:
*   **State Machine:** Explicit states the contract can be in.
*   **Time-Based Epochs:** Progress is gated by time.
*   **Influence System:** A non-transferable score used for permissions and weight.
*   **Resource Management:** Participants manage an abstract "Epoch Yield" resource.
*   **Data Submission:** Participants can submit data/events affecting the system.
*   **Delegation:** Influence can be delegated.
*   **Adaptive Parameters:** Key system parameters can be proposed and changed.
*   **Proposal/Affirmation System:** A multi-step process for certain actions (like granting influence).
*   **On-Chain Generation:** Simple on-chain pseudo-randomness for outcomes (be cautious with this in production).

This is a complex, conceptual contract. It would require significant gas and careful optimization for production, and the pseudo-randomness is exploitable.

---

**Outline: Decentralized Adaptive Chronicle**

1.  **State Management:** Defines the current phase of the chronicle.
2.  **Participant Data:** Stores influence, yield, and delegation info for each participant.
3.  **System Parameters:** Configurable values governing epoch duration, costs, rewards, etc.
4.  **Epoch & Time:** Tracks current epoch and timing.
5.  **Pending Data Submissions:** Stores data points submitted by participants for processing.
6.  **Parameter Proposals:** Stores proposals for changing system parameters and associated votes.
7.  **Influence Grant Proposals:** Stores proposals for granting influence and associated affirmations.
8.  **Events:** Signalling key state changes and actions.
9.  **Modifiers:** Access control and state checks.
10. **Core Logic Functions:**
    *   Initialization & Registration.
    *   Epoch Advancement & Processing.
    *   Data Submission & Processing.
    *   Influence & Yield Management (claiming, delegating).
    *   Parameter Governance (proposing, voting, enacting).
    *   Influence Granting (proposing, affirming, executing).
11. **View Functions:** Querying contract state, participant data, proposals, etc.

---

**Function Summary:**

*   `initializeGenesis()`: Sets initial parameters and state.
*   `registerParticipant()`: Allows an address to join, gaining base influence and yield.
*   `advanceEpochAndProcess()`: Callable by anyone after the epoch duration passes. Transitions state, processes pending data, tallies votes/proposals, updates state/parameters.
*   `submitDataPoint(bytes32 _dataHash)`: Participants submit data (represented by a hash) during `EpochActive`, costs yield. Increases influence chance.
*   `claimEpochYield()`: Participants claim their accumulated yield at the start of a new `EpochActive` period.
*   `delegateInfluence(address _delegatee)`: Delegate influence to another participant.
*   `revokeInfluenceDelegation()`: Revoke influence delegation.
*   `getEffectiveInfluence(address _participant)`: View total influence (self + delegated in).
*   `submitParameterVote(bytes32 _parameterName, uint256 _newValue)`: Vote on changing a specific system parameter during `ParameterVoting`. Costs yield.
*   `proposeInfluenceGrant(address _recipient, uint256 _amount)`: Propose granting influence to an address. Requires influence.
*   `affirmInfluenceGrant(bytes32 _proposalId)`: Affirm an influence grant proposal. Requires influence.
*   `executeInfluenceGrantProposals()`: Callable by anyone after a period, executes grant proposals with sufficient affirmations.
*   `proposeEpochDurationChange(uint256 _newDuration)`: Propose changing the epoch duration. Requires influence.
*   `voteForEpochDurationChange(uint256 _newDuration)`: Vote on a proposed epoch duration change. Costs yield.
*   `enactEpochDurationChange()`: Callable by anyone after voting, enacts the epoch duration change if the vote passes.
*   `queryCurrentState()`: View the current state.
*   `queryCurrentEpoch()`: View the current epoch number.
*   `queryEpochEndTime()`: View the timestamp when the current epoch ends.
*   `querySystemParameters()`: View the current values of all system parameters.
*   `queryParticipantInfluence(address _participant)`: View base influence.
*   `queryParticipantYield(address _participant)`: View yield balance.
*   `queryDelegatee(address _participant)`: View who a participant has delegated their influence to.
*   `queryPendingSubmissionsCount()`: View the number of pending data submissions.
*   `queryParameterVoteDetails(bytes32 _parameterName)`: View current votes for a parameter change.
*   `queryInfluenceGrantProposalDetails(bytes32 _proposalId)`: View details and affirmations for an influence grant proposal.
*   `queryEpochDurationChangeProposalDetails()`: View details and votes for the epoch duration change proposal.
*   `isParticipant(address _participant)`: Check if an address is a registered participant.

*(Note: Some functions like internal processing will not be in this summary but are required in code)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Outline: Decentralized Adaptive Chronicle
// 1. State Management: Defines the current phase of the chronicle.
// 2. Participant Data: Stores influence, yield, and delegation info for each participant.
// 3. System Parameters: Configurable values governing epoch duration, costs, rewards, etc.
// 4. Epoch & Time: Tracks current epoch and timing.
// 5. Pending Data Submissions: Stores data points submitted by participants for processing.
// 6. Parameter Proposals: Stores proposals for changing system parameters and associated votes.
// 7. Influence Grant Proposals: Stores proposals for granting influence and associated affirmations.
// 8. Events: Signalling key state changes and actions.
// 9. Modifiers: Access control and state checks.
// 10. Core Logic Functions: Initialization & Registration, Epoch Advancement & Processing, Data Submission & Processing, Influence & Yield Management, Parameter Governance, Influence Granting.
// 11. View Functions: Querying contract state, participant data, proposals, etc.

// Function Summary:
// initializeGenesis(): Sets initial parameters and state.
// registerParticipant(): Allows an address to join, gaining base influence and yield.
// advanceEpochAndProcess(): Transitions state, processes data, tallies votes/proposals.
// submitDataPoint(bytes32 _dataHash): Participants submit data during EpochActive, costs yield, might increase influence.
// claimEpochYield(): Participants claim their accumulated yield.
// delegateInfluence(address _delegatee): Delegate influence.
// revokeInfluenceDelegation(): Revoke delegation.
// getEffectiveInfluence(address _participant): View total influence (self + delegated in).
// submitParameterVote(bytes32 _parameterName, uint256 _newValue): Vote on parameter changes during ParameterVoting. Costs yield.
// proposeInfluenceGrant(address _recipient, uint256 _amount): Propose granting influence. Requires influence.
// affirmInfluenceGrant(bytes32 _proposalId): Affirm an influence grant proposal. Requires influence.
// executeInfluenceGrantProposals(): Executes grant proposals with sufficient affirmations.
// proposeEpochDurationChange(uint256 _newDuration): Propose changing epoch duration. Requires influence.
// voteForEpochDurationChange(uint256 _newDuration): Vote on epoch duration change. Costs yield.
// enactEpochDurationChange(): Enacts epoch duration change if vote passes.
// queryCurrentState(): View current state.
// queryCurrentEpoch(): View current epoch number.
// queryEpochEndTime(): View when current epoch ends.
// querySystemParameters(): View parameter values.
// queryParticipantInfluence(address _participant): View base influence.
// queryParticipantYield(address _participant): View yield balance.
// queryDelegatee(address _participant): View who a participant delegated to.
// queryPendingSubmissionsCount(): View pending data submissions count.
// queryParameterVoteDetails(bytes32 _parameterName): View votes for a parameter.
// queryInfluenceGrantProposalDetails(bytes32 _proposalId): View grant proposal details.
// queryEpochDurationChangeProposalDetails(): View epoch duration proposal details.
// isParticipant(address _participant): Check if registered.


contract DecentralizedAdaptiveChronicle {

    // --- State Management ---
    enum SystemState { Initializing, Genesis, EpochActive, EpochProcessing, ParameterVoting, InfluenceGrantVoting, EpochCooldown }
    SystemState public currentState;

    // --- Participant Data ---
    struct Participant {
        bool isRegistered;
        uint256 baseInfluence; // Base influence score
        uint256 epochYield;    // Abstract resource for actions
        address delegatee;     // Address influence is delegated to (address(0) if none)
        // Could add delegators list, but iteration is expensive. Querying `delegatee` is sufficient.
    }
    mapping(address => Participant) private participants;
    address[] private participantList; // Simple array for tracking registered participants (careful with size)

    // --- System Parameters ---
    // Stored as bytes32 name => uint256 value
    mapping(bytes32 => uint256) public systemParameters;
    bytes32[] private parameterNames; // List of adjustable parameter names

    // Predefined Parameter Names (using keccak256 hash of string)
    bytes32 constant public PARAM_EPOCH_DURATION = keccak256("EPOCH_DURATION");
    bytes32 constant public PARAM_DATA_SUBMISSION_COST = keccak256("DATA_SUBMISSION_COST");
    bytes32 constant public PARAM_YIELD_PER_INFLUENCE = keccak256("YIELD_PER_INFLUENCE");
    bytes32 constant public PARAM_MIN_INFLUENCE_FOR_PROPOSAL = keccak256("MIN_INFLUENCE_FOR_PROPOSAL");
    bytes32 constant public PARAM_INFLUENCE_GRANT_AFFIRM_THRESHOLD = keccak256("INFLUENCE_GRANT_AFFIRM_THRESHOLD");
    bytes32 constant public PARAM_INFLUENCE_DECAY_RATE = keccak256("INFLUENCE_DECAY_RATE"); // e.g., percentage decay / 1000

    // --- Epoch & Time ---
    uint256 public currentEpoch;
    uint256 public epochEndTime;

    // --- Pending Data Submissions ---
    struct DataSubmission {
        address submitter;
        bytes32 dataHash;
        uint256 submissionTime;
    }
    DataSubmission[] private pendingDataSubmissions;

    // --- Parameter Proposals (Generic) ---
    struct ParameterVote {
        uint256 newValue;
        uint256 totalInfluenceVoted; // Sum of effective influence of voters
        mapping(address => bool) hasVoted;
    }
    mapping(bytes32 => ParameterVote) private parameterVotes; // Parameter Name => Vote details

    // --- Influence Grant Proposals ---
    struct InfluenceGrantProposal {
        address proposer;
        address recipient;
        uint256 amount;
        mapping(address => bool) hasAffirmed;
        uint256 affirmationInfluenceSum; // Sum of effective influence of affirmers
        bool executed;
    }
    mapping(bytes32 => InfluenceGrantProposal) private influenceGrantProposals; // Proposal ID (hash) => Proposal details
    bytes32[] private activeGrantProposals; // List of currently active proposals

    // --- Epoch Duration Change Proposal (Specific) ---
    struct EpochDurationVote {
        uint256 newDuration;
        uint256 totalInfluenceVoted;
        mapping(address => bool) hasVoted;
        bool isActive;
    }
    EpochDurationVote public epochDurationVote;

    // --- Events ---
    event GenesisInitialized(address indexed owner, uint256 initialEpochDuration);
    event ParticipantRegistered(address indexed participant);
    event EpochAdvanced(uint256 indexed epoch, uint256 endTime, SystemState newState);
    event StateTransitioned(SystemState indexed oldState, SystemState indexed newState, uint256 timestamp);
    event DataPointSubmitted(address indexed submitter, bytes32 dataHash, uint256 timestamp);
    event DataPointProcessed(address indexed submitter, bytes32 dataHash, uint256 epoch);
    event EpochYieldClaimed(address indexed participant, uint256 amount);
    event InfluenceDelegated(address indexed delegator, address indexed delegatee);
    event InfluenceRevoked(address indexed delegator);
    event ParameterVoteSubmitted(address indexed voter, bytes32 parameterName, uint256 newValue, uint256 influenceWeightedVote);
    event ParameterChanged(bytes32 parameterName, uint256 oldValue, uint256 newValue);
    event InfluenceGrantProposed(address indexed proposer, address indexed recipient, uint256 amount, bytes32 proposalId);
    event InfluenceGrantAffirmed(address indexed affirmer, bytes32 indexed proposalId, uint256 effectiveInfluence);
    event InfluenceGrantExecuted(bytes32 indexed proposalId, address indexed recipient, uint256 amount);
    event EpochDurationChangeProposed(address indexed proposer, uint256 newDuration);
    event EpochDurationVoteSubmitted(address indexed voter, uint256 newDuration, uint256 influenceWeightedVote);
    event EpochDurationChanged(uint256 oldDuration, uint256 newDuration);
    event InfluenceGrantedDirectly(address indexed recipient, uint256 amount); // For initial grants etc.
    event ParticipantInfluenceChanged(address indexed participant, uint256 oldInfluence, uint256 newInfluence);
    event ParticipantYieldChanged(address indexed participant, uint256 oldYield, uint256 newYield);

    // --- Modifiers ---
    modifier onlyState(SystemState _state) {
        require(currentState == _state, "DAC: Not in required state");
        _;
    }

    modifier notInState(SystemState _state) {
         require(currentState != _state, "DAC: Cannot perform action in current state");
         _;
    }

    modifier onlyRegisteredParticipant() {
        require(participants[msg.sender].isRegistered, "DAC: Caller not a registered participant");
        _;
    }

    modifier onlyGenesis() {
        require(currentState == SystemState.Genesis, "DAC: Only callable during Genesis");
        _;
    }

    // --- Constructor (Minimal, Init via Function) ---
    constructor() {
        currentState = SystemState.Initializing;
        // Pre-define parameter names for later lookup
        parameterNames.push(PARAM_EPOCH_DURATION);
        parameterNames.push(PARAM_DATA_SUBMISSION_COST);
        parameterNames.push(PARAM_YIELD_PER_INFLUENCE);
        parameterNames.push(PARAM_MIN_INFLUENCE_FOR_PROPOSAL);
        parameterNames.push(PARAM_INFLUENCE_GRANT_AFFIRM_THRESHOLD);
        parameterNames.push(PARAM_INFLUENCE_DECAY_RATE);
    }

    // --- Core Logic Functions ---

    /**
     * @notice Initializes the chronicle, setting initial parameters and moving to Genesis state.
     * @dev Can only be called once when in Initializing state.
     * @param _initialEpochDuration The duration of the first epoch in seconds.
     * @param _initialDataSubmissionCost The cost in yield to submit data.
     * @param _initialYieldPerInfluence The amount of yield granted per influence point each epoch.
     * @param _minInfluenceForProposal Minimum influence to propose actions.
     * @param _influenceGrantAffirmThreshold Sum of effective influence needed to pass a grant proposal.
     * @param _influenceDecayRate Rate of influence decay per epoch (e.g., 100 for 10% decay if scaled by 1000).
     */
    function initializeGenesis(
        uint256 _initialEpochDuration,
        uint256 _initialDataSubmissionCost,
        uint256 _initialYieldPerInfluence,
        uint256 _minInfluenceForProposal,
        uint256 _influenceGrantAffirmThreshold,
        uint256 _influenceDecayRate
    ) external onlyState(SystemState.Initializing) {
        systemParameters[PARAM_EPOCH_DURATION] = _initialEpochDuration;
        systemParameters[PARAM_DATA_SUBMISSION_COST] = _initialDataSubmissionCost;
        systemParameters[PARAM_YIELD_PER_INFLUENCE] = _initialYieldPerInfluence;
        systemParameters[PARAM_MIN_INFLUENCE_FOR_PROPOSAL] = _minInfluenceForProposal;
        systemParameters[PARAM_INFLUENCE_GRANT_AFFIRM_THRESHOLD] = _influenceGrantAffirmThreshold;
        systemParameters[PARAM_INFLUENCE_DECAY_RATE] = _influenceDecayRate;

        currentEpoch = 0;
        epochEndTime = block.timestamp + _initialEpochDuration;
        currentState = SystemState.Genesis;

        emit GenesisInitialized(msg.sender, _initialEpochDuration);
        emit StateTransitioned(SystemState.Initializing, SystemState.Genesis, block.timestamp);
    }

     /**
      * @notice Registers a new participant in the chronicle.
      * @dev Grants a base yield upon registration. Can be called in Genesis or EpochActive.
      */
    function registerParticipant() external notInState(SystemState.Initializing) {
        require(!participants[msg.sender].isRegistered, "DAC: Already a registered participant");

        participants[msg.sender].isRegistered = true;
        // Start with a minimal yield or influence, or grant via proposal system initially
        participants[msg.sender].epochYield = systemParameters[PARAM_YIELD_PER_INFLUENCE]; // Grant initial yield
        participantList.push(msg.sender); // Add to list (caution: potential scaling issues)

        emit ParticipantRegistered(msg.sender);
        emit ParticipantYieldChanged(msg.sender, 0, participants[msg.sender].epochYield);
    }

    /**
     * @notice Advances the chronicle to the next epoch and triggers processing.
     * @dev Can be called by any registered participant once the current epoch has ended.
     * Handles state transitions and internal processing steps.
     */
    function advanceEpochAndProcess() external notInState(SystemState.Initializing) {
        require(block.timestamp >= epochEndTime, "DAC: Epoch has not yet ended");
        require(currentState != SystemState.EpochProcessing && currentState != SystemState.InfluenceGrantVoting, "DAC: System busy processing");

        uint256 oldEpoch = currentEpoch;
        currentEpoch++;
        SystemState oldState = currentState;

        // Transition to processing state
        _transitionState(SystemState.EpochProcessing);

        // --- Internal Processing Steps ---
        _processPendingDataSubmissions();
        _tallyParameterVotesAndApply();
        _tallyEpochDurationVoteAndApply();
        _decayInfluence();
        _calculateAndDistributeEpochYield();

        // Clear old proposals/votes
        _cleanupEpochData();

        // Set up for the next epoch
        epochEndTime = block.timestamp + systemParameters[PARAM_EPOCH_DURATION];

        // Transition to the next active state (could be EpochActive or start voting periods)
        // Simple transition for now: straight back to EpochActive, grant proposals/votes can be submitted then
        _transitionState(SystemState.EpochActive);


        emit EpochAdvanced(currentEpoch, epochEndTime, currentState);
    }

    /**
     * @dev Internal function to handle state transitions and emit events.
     */
    function _transitionState(SystemState _newState) private {
        SystemState oldState = currentState;
        currentState = _newState;
        emit StateTransitioned(oldState, _newState, block.timestamp);
    }


    /**
     * @notice Submits a data point to be processed at the end of the current epoch.
     * @dev Requires being a registered participant and consumes epoch yield.
     * @param _dataHash A hash representing the submitted data.
     */
    function submitDataPoint(bytes32 _dataHash) external onlyRegisteredParticipant onlyState(SystemState.EpochActive) {
        uint256 cost = systemParameters[PARAM_DATA_SUBMISSION_COST];
        require(participants[msg.sender].epochYield >= cost, "DAC: Insufficient epoch yield to submit data");

        participants[msg.sender].epochYield -= cost;
        pendingDataSubmissions.push(DataSubmission({
            submitter: msg.sender,
            dataHash: _dataHash,
            submissionTime: block.timestamp
        }));

        emit DataPointSubmitted(msg.sender, _dataHash, block.timestamp);
        emit ParticipantYieldChanged(msg.sender, participants[msg.sender].epochYield + cost, participants[msg.sender].epochYield);
    }

    /**
     * @dev Internal function to process submitted data points.
     * Placeholder for complex simulation logic. Might award influence based on data.
     */
    function _processPendingDataSubmissions() private {
        uint256 submissionCount = pendingDataSubmissions.length;
        // Simple example: award minor influence based on a hash and block properties
        uint256 influenceReward = 0; // Calculate reward based on parameters/data
        uint256 seed = block.timestamp + block.number + uint256(blockhash(block.number - 1)); // Simple seed (exploitable)

        for (uint i = 0; i < submissionCount; i++) {
            DataSubmission storage submission = pendingDataSubmissions[i];
            bytes32 dataSeed = keccak256(abi.encodePacked(seed, submission.dataHash, submission.submitter, i));
            uint256 randValue = uint256(dataSeed);

            // Example: Award influence based on hash properties (placeholder logic)
            influenceReward = (randValue % 10) + 1; // Random reward 1-10

            uint256 oldInfluence = participants[submission.submitter].baseInfluence;
            participants[submission.submitter].baseInfluence += influenceReward;

            emit DataPointProcessed(submission.submitter, submission.dataHash, currentEpoch);
            emit ParticipantInfluenceChanged(submission.submitter, oldInfluence, participants[submission.submitter].baseInfluence);
        }
        delete pendingDataSubmissions; // Clear array
    }

    /**
     * @notice Claims the epoch yield accumulated for the current participant.
     * @dev Yield is calculated and distributed during epoch processing. Callable in EpochActive.
     */
    function claimEpochYield() external onlyRegisteredParticipant onlyState(SystemState.EpochActive) {
        uint256 yieldAmount = participants[msg.sender].epochYield;
        require(yieldAmount > 0, "DAC: No yield to claim");

        // Yield was already added during EpochProcessing. This function just confirms claim/makes it usable conceptually.
        // In this simple model, yield is immediately available. This function primarily serves as a user action point.
        // A more complex model might have a separate "claimable" balance vs "usable" balance.
        // For this example, the yield is already in the usable balance `participants[msg.sender].epochYield`
        // The 'claim' could represent acknowledging or using the yield.
        // Let's make it a check for now, or if yield was *only* added on claim, move the distribution logic here.
        // Re-reading: "Participants claim their accumulated yield *at the start* of a new EpochActive period."
        // This suggests yield is calculated, maybe stored in a 'claimable' var, and moved to 'epochYield' here.
        // Let's add a `claimableYield` variable.

        uint256 claimable = participants[msg.sender].claimableYield;
        require(claimable > 0, "DAC: No claimable yield");

        participants[msg.sender].epochYield += claimable;
        participants[msg.sender].claimableYield = 0;

        emit EpochYieldClaimed(msg.sender, claimable);
        emit ParticipantYieldChanged(msg.sender, participants[msg.sender].epochYield - claimable, participants[msg.sender].epochYield);

    }

     // Adding claimableYield to Participant struct - need to update struct definition above if possible, or acknowledge this change.
     // Okay, let's add it to the struct definition at the top.

    /**
     * @dev Internal function to calculate and add epoch yield based on influence.
     * Called during epoch processing. Adds to claimable yield.
     */
    function _calculateAndDistributeEpochYield() private {
        uint256 yieldPerInf = systemParameters[PARAM_YIELD_PER_INFLUENCE];
        for(uint i = 0; i < participantList.length; i++) {
            address participantAddress = participantList[i];
            if(participants[participantAddress].isRegistered) {
                 uint256 effectiveInf = _getEffectiveInfluence(participantAddress);
                 uint256 yieldAmount = effectiveInf * yieldPerInf;
                 participants[participantAddress].claimableYield += yieldAmount;
                 // No event here, event is on claimEpochYield
            }
        }
    }

    /**
     * @notice Delegates participant's influence to another participant.
     * @dev Influence calculation becomes `baseInfluence` + `delegatedInfluenceFromOthers`.
     * @param _delegatee The address to delegate influence to. address(0) to undelegate.
     */
    function delegateInfluence(address _delegatee) external onlyRegisteredParticipant {
        require(_delegatee != msg.sender, "DAC: Cannot delegate influence to yourself");
        if (_delegatee != address(0)) {
             require(participants[_delegatee].isRegistered, "DAC: Delegatee must be a registered participant");
        }

        address oldDelegatee = participants[msg.sender].delegatee;
        participants[msg.sender].delegatee = _delegatee;

        if (_delegatee == address(0)) {
            emit InfluenceRevoked(msg.sender);
        } else {
            emit InfluenceDelegated(msg.sender, _delegatee);
        }
    }

    /**
     * @notice Revokes any active influence delegation by the caller.
     * @dev Equivalent to calling `delegateInfluence(address(0))`.
     */
    function revokeInfluenceDelegation() external onlyRegisteredParticipant {
        delegateInfluence(address(0));
    }

    /**
     * @notice Submits a vote to change a system parameter.
     * @dev Callable during ParameterVoting state. Consumes yield. Requires being a participant.
     * @param _parameterName The keccak256 hash of the parameter name (e.g., PARAM_DATA_SUBMISSION_COST).
     * @param _newValue The proposed new value for the parameter.
     */
    function submitParameterVote(bytes32 _parameterName, uint256 _newValue) external onlyRegisteredParticipant onlyState(SystemState.ParameterVoting) {
        uint256 cost = 1; // Define parameter voting cost or use a param
        require(participants[msg.sender].epochYield >= cost, "DAC: Insufficient epoch yield to vote");
        require(!parameterVotes[_parameterName].hasVoted[msg.sender], "DAC: Already voted for this parameter change");

        // Check if parameter name is valid/known
        bool isValidParam = false;
        for(uint i = 0; i < parameterNames.length; i++) {
            if (parameterNames[i] == _parameterName) {
                isValidParam = true;
                break;
            }
        }
        require(isValidParam, "DAC: Invalid parameter name");


        uint256 effectiveInf = _getEffectiveInfluence(msg.sender);
        require(effectiveInf > 0, "DAC: Cannot vote with zero influence");

        participants[msg.sender].epochYield -= cost;

        parameterVotes[_parameterName].newValue = _newValue; // Note: This only tracks the LAST proposed value for the parameter
        parameterVotes[_parameterName].totalInfluenceVoted += effectiveInf;
        parameterVotes[_parameterName].hasVoted[msg.sender] = true;

        emit ParameterVoteSubmitted(msg.sender, _parameterName, _newValue, effectiveInf);
        emit ParticipantYieldChanged(msg.sender, participants[msg.sender].epochYield + cost, participants[msg.sender].epochYield);

        // Note: This current voting model only supports voting *for* a specific new value per parameter.
        // A more complex model would track votes for different proposed values.
    }

    /**
     * @dev Internal function to tally parameter votes and apply changes.
     * Called during epoch processing.
     */
    function _tallyParameterVotesAndApply() private {
        // Iterate through all known parameters
        uint256 minInfluence = systemParameters[PARAM_MIN_INFLUENCE_FOR_PROPOSAL]; // Using this param as a threshold

        for(uint i = 0; i < parameterNames.length; i++) {
            bytes32 paramName = parameterNames[i];
            ParameterVote storage vote = parameterVotes[paramName];

            // Simple logic: If total influence voted for this parameter change exceeds a threshold, apply it.
            // A real system would need more sophisticated logic (e.g., majority vote on a specific value).
            if (vote.totalInfluenceVoted >= minInfluence) { // Using MIN_INFLUENCE_FOR_PROPOSAL as a proxy threshold
                 uint256 oldValue = systemParameters[paramName];
                 systemParameters[paramName] = vote.newValue;
                 emit ParameterChanged(paramName, oldValue, vote.newValue);
            }
            // Clear votes for the next epoch
            delete parameterVotes[paramName]; // Resets struct, including the mapping `hasVoted`
        }
    }

     /**
      * @notice Proposes a change to the global epoch duration parameter.
      * @dev Requires a minimum influence score. Callable in EpochActive state.
      * @param _newDuration The proposed new epoch duration in seconds.
      */
     function proposeEpochDurationChange(uint256 _newDuration) external onlyRegisteredParticipant onlyState(SystemState.EpochActive) {
         require(!epochDurationVote.isActive, "DAC: Epoch duration change proposal already active");
         require(_getEffectiveInfluence(msg.sender) >= systemParameters[PARAM_MIN_INFLUENCE_FOR_PROPOSAL], "DAC: Insufficient influence to propose");
         require(_newDuration > 0, "DAC: New duration must be greater than zero");

         epochDurationVote.newDuration = _newDuration;
         epochDurationVote.totalInfluenceVoted = 0;
         // Clear previous voters map (manual iteration needed or use a new struct/mapping for each proposal)
         // For simplicity, reset the single struct and accept that only one proposal is active at a time.
         // Using a mapping for `hasVoted` within the struct handles clearing voters for the *current* active proposal.
         // To clear the map within the struct for the *next* proposal, we'd need to iterate or use a pattern where `epochDurationVote` itself is a mapping key (e.g., proposalId).
         // Let's keep it simple with one active proposal struct and accept voters map is cleared on next proposal activation.
         epochDurationVote.isActive = true; // Mark as active

         emit EpochDurationChangeProposed(msg.sender, _newDuration);
     }

     /**
      * @notice Submits a vote for the currently active epoch duration change proposal.
      * @dev Callable during ParameterVoting state (or could be EpochActive, depending on voting model).
      * Requires being a participant and consumes yield.
      * @param _newDuration The proposed duration value being voted on (must match the active proposal).
      */
     function voteForEpochDurationChange(uint256 _newDuration) external onlyRegisteredParticipant onlyState(SystemState.ParameterVoting) {
         require(epochDurationVote.isActive, "DAC: No active epoch duration change proposal");
         require(epochDurationVote.newDuration == _newDuration, "DAC: Voted duration does not match active proposal");

         uint256 cost = 1; // Define cost
         require(participants[msg.sender].epochYield >= cost, "DAC: Insufficient epoch yield to vote");
         require(!epochDurationVote.hasVoted[msg.sender], "DAC: Already voted on this proposal");

         uint256 effectiveInf = _getEffectiveInfluence(msg.sender);
         require(effectiveInf > 0, "DAC: Cannot vote with zero influence");

         participants[msg.sender].epochYield -= cost;

         epochDurationVote.totalInfluenceVoted += effectiveInf;
         epochDurationVote.hasVoted[msg.sender] = true;

         emit EpochDurationVoteSubmitted(msg.sender, _newDuration, effectiveInf);
         emit ParticipantYieldChanged(msg.sender, participants[msg.sender].epochYield + cost, participants[msg.sender].epochYield);
     }

     /**
      * @dev Internal function to tally the epoch duration vote and apply change if passed.
      * Called during epoch processing.
      */
     function _tallyEpochDurationVoteAndApply() private {
         if (epochDurationVote.isActive) {
             // Simple majority threshold based on total influence of all participants? Or MIN_INFLUENCE_FOR_PROPOSAL?
             // Let's use a simple percentage of total influence, or a high fixed threshold.
             // Using a high fixed threshold based on a parameter.
             uint256 threshold = systemParameters[PARAM_INFLUENCE_GRANT_AFFIRM_THRESHOLD]; // Re-using this parameter for simplicity

             if (epochDurationVote.totalInfluenceVoted >= threshold) {
                 uint256 oldDuration = systemParameters[PARAM_EPOCH_DURATION];
                 systemParameters[PARAM_EPOCH_DURATION] = epochDurationVote.newDuration;
                 emit EpochDurationChanged(oldDuration, epochDurationVote.newDuration);
             }
             // Deactivate the proposal regardless of outcome
             epochDurationVote.isActive = false;
             // Clear voters mapping - Solidity 0.8.x requires iteration or re-initialization if not mapping in struct.
             // For simplicity, let's accept it's cleared when `epochDurationVote` is overwritten or becomes inactive and its mapping is implicitly reset on next proposal setup.
         }
     }


    /**
     * @notice Proposes granting influence to a specific participant.
     * @dev Requires a minimum influence score. Creates a proposal that needs affirmation.
     * @param _recipient The address to grant influence to.
     * @param _amount The amount of influence to grant.
     * @return proposalId The unique ID of the created proposal.
     */
    function proposeInfluenceGrant(address _recipient, uint256 _amount) external onlyRegisteredParticipant onlyState(SystemState.EpochActive) returns (bytes32 proposalId) {
        require(_getEffectiveInfluence(msg.sender) >= systemParameters[PARAM_MIN_INFLUENCE_FOR_PROPOSAL], "DAC: Insufficient influence to propose");
        require(participants[_recipient].isRegistered, "DAC: Recipient must be a registered participant");
        require(_amount > 0, "DAC: Grant amount must be positive");

        proposalId = keccak256(abi.encodePacked(msg.sender, _recipient, _amount, block.timestamp, activeGrantProposals.length));

        require(influenceGrantProposals[proposalId].proposer == address(0), "DAC: Proposal ID collision"); // Basic collision check

        influenceGrantProposals[proposalId] = InfluenceGrantProposal({
            proposer: msg.sender,
            recipient: _recipient,
            amount: _amount,
            hasAffirmed: new mapping(address => bool), // Initialize mapping
            affirmationInfluenceSum: 0,
            executed: false
        });

        activeGrantProposals.push(proposalId);

        emit InfluenceGrantProposed(msg.sender, _recipient, _amount, proposalId);
    }

    /**
     * @notice Affirms an existing influence grant proposal.
     * @dev Requires a minimum influence score. Adds effective influence weight to the proposal.
     * @param _proposalId The ID of the proposal to affirm.
     */
    function affirmInfluenceGrant(bytes32 _proposalId) external onlyRegisteredParticipant onlyState(SystemState.EpochActive) {
        InfluenceGrantProposal storage proposal = influenceGrantProposals[_proposalId];
        require(proposal.proposer != address(0), "DAC: Proposal does not exist"); // Check if proposal exists
        require(!proposal.executed, "DAC: Proposal already executed");
        require(!proposal.hasAffirmed[msg.sender], "DAC: Already affirmed this proposal");

        uint256 effectiveInf = _getEffectiveInfluence(msg.sender);
        require(effectiveInf > 0, "DAC: Cannot affirm with zero influence");

        proposal.hasAffirmed[msg.sender] = true;
        proposal.affirmationInfluenceSum += effectiveInf;

        emit InfluenceGrantAffirmed(msg.sender, _proposalId, effectiveInf);
    }

    /**
     * @notice Executes influence grant proposals that have met the affirmation threshold.
     * @dev Callable by anyone. Processes proposals and grants influence.
     * This could be triggered during epoch processing or be a separate callable function.
     * Let's make it callable by anyone, but only process if state allows or after a delay from proposal.
     * For simplicity, make it callable during EpochProcessing or a dedicated phase.
     * Let's make it callable during EpochProcessing for simplicity with state machine.
     */
    function executeInfluenceGrantProposals() external onlyState(SystemState.EpochProcessing) {
        uint256 threshold = systemParameters[PARAM_INFLUENCE_GRANT_AFFIRM_THRESHOLD];
        bytes32[] memory proposalsToKeep; // New list for proposals not yet executed

        for(uint i = 0; i < activeGrantProposals.length; i++) {
            bytes32 proposalId = activeGrantProposals[i];
            InfluenceGrantProposal storage proposal = influenceGrantProposals[proposalId];

            if (!proposal.executed && proposal.affirmationInfluenceSum >= threshold) {
                // Execute the grant
                uint256 oldInfluence = participants[proposal.recipient].baseInfluence;
                participants[proposal.recipient].baseInfluence += proposal.amount;
                proposal.executed = true; // Mark as executed

                emit InfluenceGrantExecuted(proposalId, proposal.recipient, proposal.amount);
                emit ParticipantInfluenceChanged(proposal.recipient, oldInfluence, participants[proposal.recipient].baseInfluence);

            } else if (!proposal.executed) {
                // Keep proposals that haven't met the threshold yet
                proposalsToKeep.push(proposalId);
            }
            // Executed proposals are conceptually discarded from 'active' list, but remain stored by ID.
            // They will be truly cleaned up in _cleanupEpochData
        }
         // Update activeGrantProposals to only include those not executed this round
         activeGrantProposals = proposalsToKeep; // Caution: This could be gas-intensive if many proposals are kept
    }


    /**
     * @dev Internal function to decay influence scores based on a parameter.
     * Called during epoch processing.
     */
    function _decayInfluence() private {
        uint256 decayRate = systemParameters[PARAM_INFLUENCE_DECAY_RATE]; // Expect this to be a percentage scaled, e.g., 990 for 1% decay if scaled by 1000
        if (decayRate == 0) return; // No decay

        uint256 scale = 1000; // Example scale, parameter value is decayRate * scale

        for(uint i = 0; i < participantList.length; i++) {
            address participantAddress = participantList[i];
             uint256 oldInfluence = participants[participantAddress].baseInfluence;
            if (oldInfluence > 0) {
                // Apply decay: new = old * (1 - rate/scale)
                // Example: 100 inf, 10% decay (rate 100, scale 1000) -> 100 * (1 - 100/1000) = 100 * 0.9 = 90
                participants[participantAddress].baseInfluence = (oldInfluence * (scale - decayRate)) / scale;
                 if(participants[participantAddress].baseInfluence != oldInfluence) {
                     emit ParticipantInfluenceChanged(participantAddress, oldInfluence, participants[participantAddress].baseInfluence);
                 }
            }
        }
    }

     /**
      * @dev Internal function to clean up expired or processed epoch data.
      * Called during epoch processing.
      */
     function _cleanupEpochData() private {
        // Pending submissions are already cleared in _processPendingDataSubmissions
        // Parameter votes are cleared in _tallyParameterVotesAndApply
        // Epoch duration vote state is reset in _tallyEpochDurationVoteAndApply (isActive = false)

        // Clean up executed influence grant proposals from the active list
        // The `executeInfluenceGrantProposals` function already does this by recreating the `activeGrantProposals` list.

        // Note: The actual `InfluenceGrantProposal` structs themselves are NOT deleted from the mapping,
        // only removed from the `activeGrantProposals` list. This allows querying historical proposals by ID.
     }


    // --- View Functions ---

    /**
     * @notice Returns the current state of the chronicle.
     */
    function queryCurrentState() external view returns (SystemState) {
        return currentState;
    }

     /**
      * @notice Returns the current epoch number.
      */
    function queryCurrentEpoch() external view returns (uint256) {
        return currentEpoch;
    }

    /**
     * @notice Returns the timestamp when the current epoch is scheduled to end.
     */
    function queryEpochEndTime() external view returns (uint256) {
        return epochEndTime;
    }

     /**
      * @notice Returns the current values of all adjustable system parameters.
      * @dev Returns arrays of parameter names and their corresponding values.
      */
    function querySystemParameters() external view returns (bytes32[] memory names, uint256[] memory values) {
        names = new bytes32[](parameterNames.length);
        values = new uint256[](parameterNames.length);
        for(uint i = 0; i < parameterNames.length; i++) {
            names[i] = parameterNames[i];
            values[i] = systemParameters[parameterNames[i]];
        }
        return (names, values);
    }

    /**
     * @notice Returns the base influence score for a participant.
     * @param _participant The address of the participant.
     */
    function queryParticipantInfluence(address _participant) external view returns (uint256) {
        return participants[_participant].baseInfluence;
    }

    /**
     * @notice Returns the current usable epoch yield balance for a participant.
     * @param _participant The address of the participant.
     */
    function queryParticipantYield(address _participant) external view returns (uint256) {
        return participants[_participant].epochYield;
    }

    /**
     * @notice Returns the address that a participant has delegated their influence to.
     * @param _participant The address of the participant.
     */
    function queryDelegatee(address _participant) external view returns (address) {
        return participants[_participant].delegatee;
    }

    /**
     * @notice Calculates and returns the effective influence for a participant, considering delegations.
     * @dev This function might be computationally intensive in a complex delegation chain scenario.
     * For simplicity here, assumes a single level of delegation.
     * @param _participant The address of the participant.
     */
    function getEffectiveInfluence(address _participant) external view returns (uint256) {
       return _getEffectiveInfluence(_participant);
    }

     /**
      * @dev Internal helper to calculate effective influence recursively or iteratively.
      * Simple version: Base influence + sum of base influence from direct delegators.
      * A more accurate version would be: Base influence + sum of (base influence + delegated influence) from direct delegators.
      * This requires a reverse mapping or iteration over all participants. Iteration is bad for gas.
      * Let's stick to the simpler model: Base influence + direct delegators' *base* influence.
      * Even this requires iterating over all participants to find delegators.
      * Alternative simple model: Base influence + sum of influence *delegated to* this address. This requires iterating all users or a reverse mapping.
      * Okay, simplest effective influence: *Only* base influence if not delegating out, OR 0 if delegating out. The delegatee gets the delegator's base influence added to their own.
      * Let's revise `getEffectiveInfluence` to this simpler model:
      * If user X delegates to Y, Y's effective influence = Y's base + X's base + Z's base (if Z delegates to Y).
      * This *still* requires finding all delegators.

      * Let's redefine: Influence is only affected by *delegating out*. If you delegate, your effective influence is 0 for voting/proposing. The delegatee's *base* influence is what matters for their *own* effective influence, but they get permission to vote/propose on behalf of delegators.
      * This is also complex to track *how much* influence the delegatee effectively controls.

      * **New Plan:** `getEffectiveInfluence` is just `baseInfluence`. Delegation grants *permission* to act, not aggregate influence numerically. The *vote weight* or *proposal power* will be based on the *caller's* `baseInfluence` UNLESS they are a delegatee, in which case they can use *their* base influence + the sum of base influences of those delegating to them.

      * This requires tracking who is delegating *to* whom. Let's add a mapping: `mapping(address => address[]) private delegators;` - this is still bad due to array manipulation cost.

      * **Simplest Model for `getEffectiveInfluence`:**
      * `getEffectiveInfluence(addr)`:
      * If `addr` has delegated (`delegatee[addr] != address(0)`), their effective influence for their *own* actions is 0.
      * If `addr` has *not* delegated, their effective influence is `baseInfluence[addr]`.
      * The delegatee can use their *own* effective influence AND act for their delegators. This still requires iterating delegators.

      * **Alternative Simple Model:** `getEffectiveInfluence` IS `baseInfluence`. Delegation allows the delegatee to call certain functions (`submitParameterVote`, `proposeInfluenceGrant`, etc.) *on behalf of* the delegator, using the delegator's yield and influence *for that specific action*. This is complex state management.

      * **Back to the "Y gets X's influence" model, but calculate on demand:**
      * `getEffectiveInfluence(addr)`: Start with `participants[addr].baseInfluence`. Iterate through *all* participants. If `participants[other].delegatee == addr`, add `participants[other].baseInfluence` to the total.
      * THIS IS TOO EXPENSIVE FOR A VIEW FUNCTION CALLED FREQUENTLY.

      * **Final Simplification:** `getEffectiveInfluence` returns `participants[addr].baseInfluence`. Delegation allows calling functions *using* the delegator's address in a parameter, or requires the caller to be the delegatee and use the delegator's influence/yield. The latter is more common.
      * Let's implement delegation where the delegatee calls the function but *specifies* the delegator address, and the call uses the delegator's resources/influence.
      * This increases function complexity (e.g., `submitDataPointFor(address _delegator, bytes32 _dataHash)`). This adds too many functions.

      * **Okay, let's revert to the "delegatee gets influence added" model, but acknowledge the view function is expensive.**
      * `getEffectiveInfluence(addr)` will calculate the sum of base influences of those delegating to `addr`.
      * This view function will iterate through `participantList`. This IS expensive O(N), but it's a read-only function, less critical than O(N) in a state-changing function.

      * Implementing `_getEffectiveInfluence` which iterates:
      */
    function _getEffectiveInfluence(address _participant) internal view returns (uint256) {
        uint256 effectiveInf = participants[_participant].baseInfluence;
        // Iterate through all participants to find those delegating to _participant
        for(uint i = 0; i < participantList.length; i++) {
            address potentialDelegator = participantList[i];
            // Ensure not the participant themselves, they are registered, and they delegate to _participant
            if (potentialDelegator != _participant && participants[potentialDelegator].isRegistered && participants[potentialDelegator].delegatee == _participant) {
                effectiveInf += participants[potentialDelegator].baseInfluence;
            }
        }
        return effectiveInf;
    }


    /**
     * @notice Returns the number of pending data submissions for the current epoch.
     */
    function queryPendingSubmissionsCount() external view returns (uint256) {
        return pendingDataSubmissions.length;
    }

    /**
     * @notice Returns details about the current votes for a specific parameter change proposal.
     * @param _parameterName The keccak256 hash of the parameter name.
     */
    function queryParameterVoteDetails(bytes32 _parameterName) external view returns (uint256 newValue, uint256 totalInfluenceVoted) {
        ParameterVote storage vote = parameterVotes[_parameterName];
        // Note: Cannot return the `hasVoted` mapping directly.
        return (vote.newValue, vote.totalInfluenceVoted);
    }

    /**
     * @notice Returns details about an active influence grant proposal.
     * @param _proposalId The ID of the proposal.
     */
    function queryInfluenceGrantProposalDetails(bytes32 _proposalId) external view returns (
        address proposer,
        address recipient,
        uint256 amount,
        uint256 affirmationInfluenceSum,
        bool executed
    ) {
         InfluenceGrantProposal storage proposal = influenceGrantProposals[_proposalId];
         return (
             proposal.proposer,
             proposal.recipient,
             proposal.amount,
             proposal.affirmationInfluenceSum,
             proposal.executed
         );
         // Note: Cannot return the `hasAffirmed` mapping directly.
    }

     /**
      * @notice Returns details about the currently active epoch duration change proposal.
      */
     function queryEpochDurationChangeProposalDetails() external view returns (
         uint256 newDuration,
         uint256 totalInfluenceVoted,
         bool isActive
     ) {
         // Note: Cannot return the `hasVoted` mapping directly.
         return (
             epochDurationVote.newDuration,
             epochDurationVote.totalInfluenceVoted,
             epochDurationVote.isActive
         );
     }

     /**
      * @notice Checks if an address is a registered participant.
      * @param _participant The address to check.
      */
     function isParticipant(address _participant) external view returns (bool) {
         return participants[_participant].isRegistered;
     }

    // --- Additional functions to reach 20+ and add more features ---

     // Add `claimableYield` to Participant struct
     // Participant struct will be:
     // struct Participant {
     //    bool isRegistered;
     //    uint256 baseInfluence;
     //    uint256 epochYield; // Usable yield
     //    uint256 claimableYield; // Yield earned but not yet claimed/added to usable balance
     //    address delegatee;
     // }
     // (Need to manually update this at the top)

     /**
      * @notice Returns the claimable epoch yield for a participant.
      * @param _participant The address of the participant.
      */
     function queryParticipantClaimableYield(address _participant) external view returns (uint256) {
         return participants[_participant].claimableYield;
     }

     /**
      * @notice Allows a participant to burn some of their usable epoch yield.
      * @dev Useful if yield accumulates excessively or for future mechanics.
      * @param _amount The amount of yield to burn.
      */
     function burnEpochYield(uint256 _amount) external onlyRegisteredParticipant {
         require(participants[msg.sender].epochYield >= _amount, "DAC: Insufficient epoch yield to burn");
         uint256 oldYield = participants[msg.sender].epochYield;
         participants[msg.sender].epochYield -= _amount;
         emit ParticipantYieldChanged(msg.sender, oldYield, participants[msg.sender].epochYield);
         // Could add an event specifically for burning
     }

    /**
     * @notice Grants initial influence during the Genesis state.
     * @dev Can only be called during Genesis by the contract deployer (implicitly via `onlyGenesis`).
     * In a real system, this might be permissioned further.
     * @param _participant The address to grant influence to.
     * @param _amount The amount of influence to grant.
     */
    function grantGenesisInfluence(address _participant, uint256 _amount) external onlyGenesis {
         require(participants[_participant].isRegistered, "DAC: Participant must be registered");
         uint256 oldInfluence = participants[_participant].baseInfluence;
         participants[_participant].baseInfluence += _amount;
         emit InfluenceGrantedDirectly(_participant, _amount);
         emit ParticipantInfluenceChanged(_participant, oldInfluence, participants[_participant].baseInfluence);
    }

    // Function Count Check:
    // initializeGenesis() - 1
    // registerParticipant() - 2
    // advanceEpochAndProcess() - 3
    // submitDataPoint() - 4
    // claimEpochYield() - 5
    // delegateInfluence() - 6
    // revokeInfluenceDelegation() - 7
    // getEffectiveInfluence() - 8 (View)
    // submitParameterVote() - 9
    // proposeInfluenceGrant() - 10
    // affirmInfluenceGrant() - 11
    // executeInfluenceGrantProposals() - 12
    // proposeEpochDurationChange() - 13
    // voteForEpochDurationChange() - 14
    // enactEpochDurationChange() - Internal part of _tallyEpochDurationVoteAndApply, not external. Let's make the tally external and callable.
    // Let's rename the internal tally functions and expose them if the state is right.

    // Let's make processing steps callable *after* epoch has advanced past endTime, but *before* the state transitions out of Processing.
    // This allows anyone to trigger the processing phase.

     /**
      * @notice Triggers the processing of pending data submissions.
      * @dev Callable by anyone when the contract is in EpochProcessing state.
      */
     function processDataSubmissions() external onlyState(SystemState.EpochProcessing) {
         _processPendingDataSubmissions();
         // After this, might transition state, or allow other processing steps.
     }

     /**
      * @notice Triggers the tallying and application of parameter votes.
      * @dev Callable by anyone when the contract is in EpochProcessing state.
      */
     function tallyParameterVotes() external onlyState(SystemState.EpochProcessing) {
         _tallyParameterVotesAndApply();
     }

      /**
      * @notice Triggers the tallying and application of the epoch duration vote.
      * @dev Callable by anyone when the contract is in EpochProcessing state.
      */
     function tallyEpochDurationVote() external onlyState(SystemState.EpochProcessing) {
         _tallyEpochDurationVoteAndApply();
     }

     /**
      * @notice Triggers the influence decay process.
      * @dev Callable by anyone when the contract is in EpochProcessing state.
      */
     function applyInfluenceDecay() external onlyState(SystemState.EpochProcessing) {
         _decayInfluence();
     }

     /**
      * @notice Triggers the calculation and distribution of epoch yield.
      * @dev Callable by anyone when the contract is in EpochProcessing state.
      */
     function distributeEpochYield() external onlyState(SystemState.EpochProcessing) {
         _calculateAndDistributeEpochYield();
     }

     /**
      * @notice Triggers cleanup of epoch-specific data.
      * @dev Callable by anyone when the contract is in EpochProcessing state.
      */
     function cleanupEpochData() external onlyState(SystemState.EpochProcessing) {
         _cleanupEpochData();
     }

     // Let's adjust advanceEpochAndProcess to transition to EpochProcessing,
     // then require these individual processing steps to be called sequentially or in any order,
     // finally call a function to transition out of EpochProcessing.
     // This makes it more decentralized for triggering steps, but requires careful state management.

     // Let's revise the states slightly: Initializing, Genesis, EpochActive, EpochProcessing (composite state), EpochCooldown (voting/grants), EpochEndTransition.

     // New simplified state flow: Initializing -> Genesis -> EpochActive -> (Time passes) -> EpochProcessing (Anyone triggers) -> (Anyone triggers processing steps) -> EpochActive (Anyone triggers transition)

     // Let's revert to the combined `advanceEpochAndProcess` for simplicity in this example, but ensure we hit 20 functions.

     // Let's add more query functions and maybe a simple permission/role concept (though aiming away from standard patterns).

     // Re-count functions:
    // 1. initializeGenesis()
    // 2. registerParticipant()
    // 3. advanceEpochAndProcess() - Triggers internal states & processing
    // 4. submitDataPoint()
    // 5. claimEpochYield()
    // 6. delegateInfluence()
    // 7. revokeInfluenceDelegation()
    // 8. getEffectiveInfluence() (View)
    // 9. submitParameterVote()
    // 10. proposeInfluenceGrant()
    // 11. affirmInfluenceGrant()
    // 12. executeInfluenceGrantProposals()
    // 13. proposeEpochDurationChange()
    // 14. voteForEpochDurationChange()
    // 15. queryCurrentState() (View)
    // 16. queryCurrentEpoch() (View)
    // 17. queryEpochEndTime() (View)
    // 18. querySystemParameters() (View)
    // 19. queryParticipantInfluence() (View)
    // 20. queryParticipantYield() (View)
    // 21. queryDelegatee() (View)
    // 22. queryPendingSubmissionsCount() (View)
    // 23. queryParameterVoteDetails() (View)
    // 24. queryInfluenceGrantProposalDetails() (View)
    // 25. queryEpochDurationChangeProposalDetails() (View)
    // 26. isParticipant() (View)
    // 27. queryParticipantClaimableYield() (View)
    // 28. burnEpochYield()
    // 29. grantGenesisInfluence()

    // We have 29 functions listed, including views. Some internal helper functions are not counted. This meets the >= 20 requirement.

    // Let's add a few more non-standard concepts.

     /**
      * @notice A simple on-chain "discovery" function that generates a parameter.
      * @dev Callable once per epoch during EpochProcessing. Uses block data for pseudo-randomness.
      * This is conceptual and not truly random or secure.
      * @return A newly generated uint256 value.
      */
     function discoverNewValue() internal view returns (uint256) {
         // In a real Dapp, this would likely use an oracle (like Chainlink VRF)
         // This is a simplified, deterministic example based on block data.
         uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, block.difficulty, msg.sender, currentEpoch)));
         return uint256(keccak256(abi.encodePacked(seed, "discovery")));
     }

     // Let's add a function that utilizes this discovery concept, perhaps setting a temporary parameter.

     /**
      * @notice Sets a temporary epoch-specific bonus parameter based on on-chain discovery.
      * @dev Callable only during EpochProcessing. Sets a parameter that resets next epoch.
      * @param _bonusParameterName Hash of the temporary parameter name.
      */
     function setEpochBonusParameter(bytes32 _bonusParameterName) external onlyState(SystemState.EpochProcessing) {
        // Use the discovery mechanism to set the value
        uint256 discoveredValue = discoverNewValue();
        // Store in a separate mapping for epoch-specific parameters
        epochBonusParameters[_bonusParameterName] = discoveredValue;
        emit ParameterChanged(_bonusParameterName, 0, discoveredValue); // Use generic event
     }

     mapping(bytes32 => uint256) private epochBonusParameters; // Temporary params

     /**
      * @notice Queries the value of an epoch-specific bonus parameter.
      * @param _bonusParameterName Hash of the temporary parameter name.
      */
     function queryEpochBonusParameter(bytes32 _bonusParameterName) external view returns (uint256) {
         return epochBonusParameters[_bonusParameterName];
     }

     // Need to clear epochBonusParameters at the end of the epoch processing
     // Add this to `_cleanupEpochData`.

     // Total functions: 29 + 2 = 31. Well over 20.

     // Final Review: Check concepts. State machine, time, influence, yield, delegation, parameter voting, proposals (grants, duration), on-chain value generation/discovery. These are varied and more complex than basic tokens/NFTs. Avoided direct copying of standard OpenZeppelin contracts. Seems reasonable for the prompt.

     // Add participantList cleanup or safety if needed - growing arrays in state is risky. For a conceptual example, it's acceptable, but acknowledge in documentation.

     // Update Participant struct with claimableYield
      struct Participant {
         bool isRegistered;
         uint256 baseInfluence;      // Base influence score
         uint256 epochYield;         // Usable abstract resource for actions
         uint256 claimableYield;     // Yield earned but not yet claimed/added to usable balance
         address delegatee;          // Address influence is delegated to (address(0) if none)
     }
     // This needs to be defined at the top.

}
```
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Outline: Decentralized Adaptive Chronicle
// 1. State Management: Defines the current phase of the chronicle (Initializing, Genesis, EpochActive, EpochProcessing).
// 2. Participant Data: Stores influence, yield, delegation, and registration status for each participant.
// 3. System Parameters: Configurable values governing epoch duration, costs, rewards, influence decay, thresholds, stored generically.
// 4. Epoch & Time: Tracks current epoch number and the timestamp for the epoch end.
// 5. Pending Data Submissions: Stores data points submitted by participants during EpochActive for processing.
// 6. Parameter Proposals (Generic): Stores proposals for changing system parameters and associated votes weighted by influence.
// 7. Influence Grant Proposals: Stores proposals for granting influence, requiring affirmation weighted by influence.
// 8. Epoch Duration Change Proposal: Specific proposal and voting mechanism for the epoch duration parameter.
// 9. Epoch Bonus Parameters: Temporary parameters set by on-chain "discovery" during processing, valid for one epoch.
// 10. Events: Signalling key state changes, participant actions, and parameter updates.
// 11. Modifiers: Access control (registration, state checks).
// 12. Core Logic Functions: Initialization & Registration, Epoch Advancement & Full Processing Trigger, Data Submission & Internal Processing, Influence & Yield Management (claiming, delegating, burning, grants), Parameter Governance (proposing, voting, enacting), Influence Decay, On-Chain Discovery.
// 13. View Functions: Querying contract state, participant data, proposals, parameters, and counts.

// Function Summary:
// initializeGenesis(): Sets initial parameters, owner (implicit), and moves to Genesis state.
// registerParticipant(): Allows an address to join the chronicle.
// advanceEpochAndProcess(): Callable after epoch time ends. Transitions state to EpochProcessing, triggers all internal processing steps, and transitions back to EpochActive.
// submitDataPoint(bytes32 _dataHash): Participants submit data during EpochActive, costs yield.
// claimEpochYield(): Participants claim their claimable yield balance.
// delegateInfluence(address _delegatee): Delegate influence to another participant.
// revokeInfluenceDelegation(): Revoke influence delegation.
// getEffectiveInfluence(address _participant): Calculates and returns total influence (base + influence delegated IN). (Note: Iterative view function, potentially high gas).
// submitParameterVote(bytes32 _parameterName, uint256 _newValue): Vote on a generic parameter change during ParameterVoting (conceptual state handled within EpochProcessing). Costs yield.
// proposeInfluenceGrant(address _recipient, uint256 _amount): Propose granting influence. Requires min influence. Creates a proposal.
// affirmInfluenceGrant(bytes32 _proposalId): Affirm an influence grant proposal. Requires min influence.
// executeInfluenceGrantProposals(): Processes active influence grant proposals. Grants influence for those meeting affirmation threshold. Callable during EpochProcessing.
// proposeEpochDurationChange(uint256 _newDuration): Propose changing epoch duration. Requires min influence.
// voteForEpochDurationChange(uint256 _newDuration): Vote on the epoch duration change proposal. Costs yield.
// queryCurrentState(): View the current state.
// queryCurrentEpoch(): View the current epoch number.
// queryEpochEndTime(): View when current epoch ends.
// querySystemParameters(): View the current values of all adjustable system parameters.
// queryParticipantInfluence(address _participant): View base influence.
// queryParticipantYield(address _participant): View usable yield balance.
// queryDelegatee(address _participant): View who a participant delegated to.
// queryPendingSubmissionsCount(): View the number of pending data submissions.
// queryParameterVoteDetails(bytes32 _parameterName): View current votes for a generic parameter.
// queryInfluenceGrantProposalDetails(bytes32 _proposalId): View details and affirmation sum for a grant proposal.
// queryEpochDurationChangeProposalDetails(): View details and votes for the epoch duration proposal.
// isParticipant(address _participant): Check if an address is a registered participant.
// queryParticipantClaimableYield(): View the claimable yield balance.
// burnEpochYield(uint256 _amount): Burn usable epoch yield.
// grantGenesisInfluence(address _participant, uint256 _amount): Grant initial influence during Genesis state.
// setEpochBonusParameter(bytes32 _bonusParameterName): Sets a temporary bonus parameter using on-chain discovery during EpochProcessing.
// queryEpochBonusParameter(bytes32 _bonusParameterName): Queries a temporary bonus parameter.

contract DecentralizedAdaptiveChronicle {

    // --- State Management ---
    enum SystemState { Initializing, Genesis, EpochActive, EpochProcessing } // Simplified states
    SystemState public currentState;

    // --- Participant Data ---
    struct Participant {
        bool isRegistered;
        uint256 baseInfluence;      // Base influence score
        uint256 epochYield;         // Usable abstract resource for actions
        uint256 claimableYield;     // Yield earned but not yet claimed/added to usable balance
        address delegatee;          // Address influence is delegated to (address(0) if none)
    }
    mapping(address => Participant) private participants;
    address[] private participantList; // Simple array for tracking registered participants (caution with size)

    // --- System Parameters ---
    // Stored as bytes32 name => uint256 value
    mapping(bytes32 => uint256) public systemParameters;
    bytes32[] private parameterNames; // List of adjustable parameter names

    // Predefined Parameter Names (using keccak256 hash of string)
    bytes32 constant public PARAM_EPOCH_DURATION = keccak256("EPOCH_DURATION");
    bytes32 constant public PARAM_DATA_SUBMISSION_COST = keccak256("DATA_SUBMISSION_COST");
    bytes32 constant public PARAM_YIELD_PER_INFLUENCE = keccak256("YIELD_PER_INFLUENCE");
    bytes32 constant public PARAM_MIN_INFLUENCE_FOR_PROPOSAL = keccak256("MIN_INFLUENCE_FOR_PROPOSAL");
    bytes32 constant public PARAM_INFLUENCE_GRANT_AFFIRM_THRESHOLD = keccak256("INFLUENCE_GRANT_AFFIRM_THRESHOLD");
    bytes32 constant public PARAM_INFLUENCE_DECAY_RATE = keccak256("INFLUENCE_DECAY_RATE"); // e.g., percentage decay / 1000
    bytes32 constant public PARAM_DATA_PROCESSING_INFLUENCE_GAIN = keccak256("DATA_PROCESSING_INFLUENCE_GAIN"); // Avg influence gain from processing data point

    // --- Epoch & Time ---
    uint256 public currentEpoch;
    uint256 public epochEndTime;

    // --- Pending Data Submissions ---
    struct DataSubmission {
        address submitter;
        bytes32 dataHash;
        uint256 submissionTime;
    }
    DataSubmission[] private pendingDataSubmissions;

    // --- Parameter Proposals (Generic) ---
    // This simplified model just tracks the last proposed value and total influence supporting *a* change for the parameter.
    // It doesn't support multiple competing values.
    struct ParameterVote {
        uint256 newValue;
        uint256 totalInfluenceVoted; // Sum of effective influence of voters
        mapping(address => bool) hasVoted; // To track who voted in the current round
    }
    mapping(bytes32 => ParameterVote) private parameterVotes; // Parameter Name => Vote details for the current epoch's vote

    // --- Influence Grant Proposals ---
    struct InfluenceGrantProposal {
        address proposer;
        address recipient;
        uint256 amount;
        mapping(address => bool) hasAffirmed; // To track who affirmed
        uint256 affirmationInfluenceSum; // Sum of effective influence of affirmers
        bool executed;
    }
    mapping(bytes32 => InfluenceGrantProposal) private influenceGrantProposals; // Proposal ID (hash) => Proposal details
    bytes32[] private activeGrantProposals; // List of currently active proposals

    // --- Epoch Duration Change Proposal (Specific) ---
    struct EpochDurationVote {
        uint256 newDuration;
        uint256 totalInfluenceVoted; // Sum of effective influence of voters
        mapping(address => bool) hasVoted; // To track who voted
        bool isActive;
    }
    EpochDurationVote public epochDurationVote; // Only one active duration vote at a time

    // --- Epoch Bonus Parameters ---
    mapping(bytes32 => uint256) private epochBonusParameters; // Temporary params, cleared each epoch

    // --- Events ---
    event GenesisInitialized(address indexed deployer, uint256 initialEpochDuration);
    event ParticipantRegistered(address indexed participant);
    event EpochAdvanced(uint256 indexed epoch, uint256 endTime, SystemState newState);
    event StateTransitioned(SystemState indexed oldState, SystemState indexed newState, uint256 timestamp);
    event DataPointSubmitted(address indexed submitter, bytes32 dataHash, uint256 timestamp);
    event DataPointProcessed(address indexed submitter, bytes32 dataHash, uint256 epoch, uint256 influenceGained);
    event EpochYieldClaimed(address indexed participant, uint256 amount);
    event InfluenceDelegated(address indexed delegator, address indexed delegatee);
    event InfluenceRevoked(address indexed delegator);
    event ParameterVoteSubmitted(address indexed voter, bytes32 parameterName, uint256 newValue, uint256 influenceWeightedVote);
    event ParameterChanged(bytes32 parameterName, uint256 oldValue, uint256 newValue);
    event InfluenceGrantProposed(address indexed proposer, address indexed recipient, uint256 amount, bytes32 proposalId);
    event InfluenceGrantAffirmed(address indexed affirmer, bytes32 indexed proposalId, uint256 effectiveInfluence);
    event InfluenceGrantExecuted(bytes32 indexed proposalId, address indexed recipient, uint256 amount);
    event EpochDurationChangeProposed(address indexed proposer, uint256 newDuration);
    event EpochDurationVoteSubmitted(address indexed voter, uint256 newDuration, uint256 influenceWeightedVote);
    event EpochDurationChanged(uint256 oldDuration, uint256 newDuration);
    event InfluenceGrantedDirectly(address indexed recipient, uint256 amount); // For initial grants etc.
    event ParticipantInfluenceChanged(address indexed participant, uint256 oldInfluence, uint256 newInfluence);
    event ParticipantYieldChanged(address indexed participant, uint256 oldYield, uint256 newYield);
    event YieldBurned(address indexed participant, uint256 amount);


    // --- Modifiers ---
    modifier onlyState(SystemState _state) {
        require(currentState == _state, string(abi.encodePacked("DAC: Not in required state ", uint256(_state))));
        _;
    }

    modifier notInState(SystemState _state) {
         require(currentState != _state, string(abi.encodePacked("DAC: Cannot perform action in state ", uint256(_state))));
         _;
    }

    modifier onlyRegisteredParticipant() {
        require(participants[msg.sender].isRegistered, "DAC: Caller not a registered participant");
        _;
    }

    modifier onlyGenesis() {
        require(currentState == SystemState.Genesis, "DAC: Only callable during Genesis");
        _;
    }

    // --- Constructor (Minimal, Init via Function) ---
    constructor() {
        currentState = SystemState.Initializing;
        // Pre-define parameter names for later lookup
        parameterNames.push(PARAM_EPOCH_DURATION);
        parameterNames.push(PARAM_DATA_SUBMISSION_COST);
        parameterNames.push(PARAM_YIELD_PER_INFLUENCE);
        parameterNames.push(PARAM_MIN_INFLUENCE_FOR_PROPOSAL);
        parameterNames.push(PARAM_INFLUENCE_GRANT_AFFIRM_THRESHOLD);
        parameterNames.push(PARAM_INFLUENCE_DECAY_RATE);
        parameterNames.push(PARAM_DATA_PROCESSING_INFLUENCE_GAIN);
    }

    // --- Core Logic Functions ---

    /**
     * @notice Initializes the chronicle, setting initial parameters and moving to Genesis state.
     * @dev Can only be called once when in Initializing state.
     * @param _initialEpochDuration The duration of the first epoch in seconds.
     * @param _initialDataSubmissionCost The cost in yield to submit data.
     * @param _initialYieldPerInfluence The amount of yield granted per influence point each epoch.
     * @param _minInfluenceForProposal Minimum influence to propose actions.
     * @param _influenceGrantAffirmThreshold Sum of effective influence needed to pass a grant proposal.
     * @param _influenceDecayRate Rate of influence decay per epoch (e.g., 100 for 10% decay if scaled by 1000).
     * @param _dataProcessingInfluenceGain Base influence gained when a data point is processed.
     */
    function initializeGenesis(
        uint256 _initialEpochDuration,
        uint256 _initialDataSubmissionCost,
        uint256 _initialYieldPerInfluence,
        uint256 _minInfluenceForProposal,
        uint256 _influenceGrantAffirmThreshold,
        uint256 _influenceDecayRate,
        uint256 _dataProcessingInfluenceGain
    ) external onlyState(SystemState.Initializing) {
        systemParameters[PARAM_EPOCH_DURATION] = _initialEpochDuration;
        systemParameters[PARAM_DATA_SUBMISSION_COST] = _initialDataSubmissionCost;
        systemParameters[PARAM_YIELD_PER_INFLUENCE] = _initialYieldPerInfluence;
        systemParameters[PARAM_MIN_INFLUENCE_FOR_PROPOSAL] = _minInfluenceForProposal;
        systemParameters[PARAM_INFLUENCE_GRANT_AFFIRM_THRESHOLD] = _influenceGrantAffirmThreshold;
        systemParameters[PARAM_INFLUENCE_DECAY_RATE] = _influenceDecayRate;
        systemParameters[PARAM_DATA_PROCESSING_INFLUENCE_GAIN] = _dataProcessingInfluenceGain;

        currentEpoch = 0;
        epochEndTime = block.timestamp + _initialEpochDuration;
        _transitionState(SystemState.Genesis);

        emit GenesisInitialized(msg.sender, _initialEpochDuration);
    }

     /**
      * @notice Registers a new participant in the chronicle.
      * @dev Can be called in Genesis or EpochActive. Grants initial claimable yield.
      */
    function registerParticipant() external notInState(SystemState.Initializing) {
        require(!participants[msg.sender].isRegistered, "DAC: Already a registered participant");

        participants[msg.sender].isRegistered = true;
        // Grant initial claimable yield upon registration
        participants[msg.sender].claimableYield = systemParameters[PARAM_YIELD_PER_INFLUENCE];
        participantList.push(msg.sender); // Add to list (caution: potential scaling issues)

        emit ParticipantRegistered(msg.sender);
        // No yield changed event here, only on claim.
    }

    /**
     * @notice Advances the chronicle to the next epoch and triggers full processing.
     * @dev Can be called by any registered participant once the current epoch has ended.
     * Orchestrates the state transitions and internal processing steps for the end of an epoch.
     */
    function advanceEpochAndProcess() external notInState(SystemState.Initializing) onlyRegisteredParticipant {
        require(block.timestamp >= epochEndTime, "DAC: Epoch has not yet ended");
        require(currentState != SystemState.EpochProcessing, "DAC: System is already processing epoch");

        uint256 oldEpoch = currentEpoch;
        currentEpoch++;
        SystemState oldState = currentState;

        // Transition to processing state
        _transitionState(SystemState.EpochProcessing);

        // --- Internal Processing Steps ---
        _processPendingDataSubmissions();
        _tallyParameterVotesAndApply();
        _tallyEpochDurationVoteAndApply();
        executeInfluenceGrantProposals(); // Call the public function to execute grants
        _decayInfluence();
        _calculateAndDistributeEpochYield();
        _cleanupEpochData(); // Clean up temporary data

        // Set up for the next epoch
        epochEndTime = block.timestamp + systemParameters[PARAM_EPOCH_DURATION];

        // Transition back to EpochActive
        _transitionState(SystemState.EpochActive);

        emit EpochAdvanced(currentEpoch, epochEndTime, currentState);
    }

    /**
     * @dev Internal function to handle state transitions and emit events.
     */
    function _transitionState(SystemState _newState) private {
        SystemState oldState = currentState;
        currentState = _newState;
        emit StateTransitioned(oldState, _newState, block.timestamp);
    }


    /**
     * @notice Submits a data point to be processed at the end of the current epoch.
     * @dev Requires being a registered participant and consumes epoch yield.
     * @param _dataHash A hash representing the submitted data.
     */
    function submitDataPoint(bytes32 _dataHash) external onlyRegisteredParticipant onlyState(SystemState.EpochActive) {
        uint256 cost = systemParameters[PARAM_DATA_SUBMISSION_COST];
        require(participants[msg.sender].epochYield >= cost, "DAC: Insufficient epoch yield to submit data");

        uint256 oldYield = participants[msg.sender].epochYield;
        participants[msg.sender].epochYield -= cost;
        pendingDataSubmissions.push(DataSubmission({
            submitter: msg.sender,
            dataHash: _dataHash,
            submissionTime: block.timestamp
        }));

        emit DataPointSubmitted(msg.sender, _dataHash, block.timestamp);
        emit ParticipantYieldChanged(msg.sender, oldYield, participants[msg.sender].epochYield);
    }

    /**
     * @dev Internal function to process submitted data points.
     * Placeholder for complex simulation logic. Awards influence based on a pseudo-random outcome.
     */
    function _processPendingDataSubmissions() private {
        uint256 submissionCount = pendingDataSubmissions.length;
        uint256 baseInfluenceGain = systemParameters[PARAM_DATA_PROCESSING_INFLUENCE_GAIN];

        // Simple pseudo-random seed based on block data (exploitable!)
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, block.difficulty, currentEpoch)));

        for (uint i = 0; i < submissionCount; i++) {
            DataSubmission storage submission = pendingDataSubmissions[i];

            // Pseudo-random influence gain calculation based on seed and submission data
            uint256 dataSeed = uint256(keccak256(abi.encodePacked(seed, submission.dataHash, submission.submitter, i)));
            uint256 randomFactor = (dataSeed % 100); // Random factor 0-99

            // Influence gained is base + a factor derived from pseudo-randomness
            uint256 influenceGained = baseInfluenceGain + (randomFactor % (baseInfluenceGain / 2 + 1)); // Example: Base + up to Base/2

            uint256 oldInfluence = participants[submission.submitter].baseInfluence;
            participants[submission.submitter].baseInfluence += influenceGained;

            emit DataPointProcessed(submission.submitter, submission.dataHash, currentEpoch, influenceGained);
            emit ParticipantInfluenceChanged(submission.submitter, oldInfluence, participants[submission.submitter].baseInfluence);
        }
        delete pendingDataSubmissions; // Clear array
    }

    /**
     * @notice Claims the claimable epoch yield accumulated for the current participant.
     * @dev Yield is calculated and distributed to `claimableYield` during epoch processing. This function moves it to `epochYield`.
     */
    function claimEpochYield() external onlyRegisteredParticipant {
        uint256 claimable = participants[msg.sender].claimableYield;
        require(claimable > 0, "DAC: No claimable yield");

        uint256 oldYield = participants[msg.sender].epochYield;
        participants[msg.sender].epochYield += claimable;
        participants[msg.sender].claimableYield = 0;

        emit EpochYieldClaimed(msg.sender, claimable);
        emit ParticipantYieldChanged(msg.sender, oldYield, participants[msg.sender].epochYield);
    }

    /**
     * @dev Internal function to calculate and add epoch yield based on influence.
     * Called during epoch processing. Adds yield to `claimableYield`.
     */
    function _calculateAndDistributeEpochYield() private {
        uint256 yieldPerInf = systemParameters[PARAM_YIELD_PER_INFLUENCE];
        for(uint i = 0; i < participantList.length; i++) {
            address participantAddress = participantList[i];
            if(participants[participantAddress].isRegistered) {
                 // Yield is based on Base Influence, not Effective Influence, to avoid cycles/complexity
                 uint256 baseInf = participants[participantAddress].baseInfluence;
                 uint256 yieldAmount = baseInf * yieldPerInf;
                 participants[participantAddress].claimableYield += yieldAmount;
                 // No event here, event is on claimEpochYield
            }
        }
    }

    /**
     * @notice Delegates participant's influence to another participant.
     * @dev Allows a delegatee to act on behalf of the delegator for certain actions.
     * Does NOT numerically add influence to the delegatee's `baseInfluence` or `getEffectiveInfluence` calculation (in this simple model).
     * @param _delegatee The address to delegate influence to. address(0) to undelegate.
     */
    function delegateInfluence(address _delegatee) external onlyRegisteredParticipant {
        require(_delegatee != msg.sender, "DAC: Cannot delegate influence to yourself");
        if (_delegatee != address(0)) {
             require(participants[_delegatee].isRegistered, "DAC: Delegatee must be a registered participant");
        }

        address oldDelegatee = participants[msg.sender].delegatee;
        participants[msg.sender].delegatee = _delegatee;

        if (_delegatee == address(0)) {
            emit InfluenceRevoked(msg.sender);
        } else {
            emit InfluenceDelegated(msg.sender, _delegatee);
        }
    }

    /**
     * @notice Revokes any active influence delegation by the caller.
     * @dev Equivalent to calling `delegateInfluence(address(0))`.
     */
    function revokeInfluenceDelegation() external onlyRegisteredParticipant {
        delegateInfluence(address(0));
    }

    /**
     * @notice Submits a vote to change a system parameter.
     * @dev Callable during EpochActive (representing a continuous voting period). Consumes yield. Requires being a participant.
     * This vote contributes influence weight towards the *last proposed value* for the parameter in this epoch.
     * @param _parameterName The keccak256 hash of the parameter name.
     * @param _newValue The proposed new value for the parameter.
     */
    function submitParameterVote(bytes32 _parameterName, uint256 _newValue) external onlyRegisteredParticipant onlyState(SystemState.EpochActive) {
        uint256 cost = 1; // Define parameter voting cost or use a param
        require(participants[msg.sender].epochYield >= cost, "DAC: Insufficient epoch yield to vote");

        // Check if parameter name is valid/known
        bool isValidParam = false;
        for(uint i = 0; i < parameterNames.length; i++) {
            if (parameterNames[i] == _parameterName) {
                isValidParam = true;
                break;
            }
        }
        require(isValidParam, "DAC: Invalid parameter name");

        // Check if already voted in this epoch for this param
        require(!parameterVotes[_parameterName].hasVoted[msg.sender], "DAC: Already voted for this parameter change in this epoch");


        // Effective influence for voting includes base + influence from direct delegators
        uint256 effectiveInf = _getEffectiveInfluence(msg.sender);
        require(effectiveInf > 0, "DAC: Cannot vote with zero influence");

        uint256 oldYield = participants[msg.sender].epochYield;
        participants[msg.sender].epochYield -= cost;

        // In this simplified model, the vote adds influence weight for the *latest* proposed value.
        // A more complex system would track votes per proposed value.
        parameterVotes[_parameterName].newValue = _newValue; // Update the proposed value (last one wins the value part)
        parameterVotes[_parameterName].totalInfluenceVoted += effectiveInf; // Sum influence for *any* vote on this parameter
        parameterVotes[_parameterName].hasVoted[msg.sender] = true;

        emit ParameterVoteSubmitted(msg.sender, _parameterName, _newValue, effectiveInf);
        emit ParticipantYieldChanged(msg.sender, oldYield, participants[msg.sender].epochYield);

    }

    /**
     * @dev Internal function to tally parameter votes and apply changes.
     * Called during epoch processing. Applies the last proposed value if total influence voting reaches a threshold.
     */
    function _tallyParameterVotesAndApply() private {
        uint256 minInfluenceThreshold = systemParameters[PARAM_MIN_INFLUENCE_FOR_PROPOSAL]; // Using this param as a threshold

        for(uint i = 0; i < parameterNames.length; i++) {
            bytes32 paramName = parameterNames[i];
            ParameterVote storage vote = parameterVotes[paramName];

            // Simple logic: If total influence voted for this parameter change exceeds a threshold, apply the LAST proposed value.
            if (vote.totalInfluenceVoted >= minInfluenceThreshold) {
                 uint256 oldValue = systemParameters[paramName];
                 systemParameters[paramName] = vote.newValue;
                 emit ParameterChanged(paramName, oldValue, vote.newValue);
            }
            // Votes are cleared at the end of processing
        }
    }

     /**
      * @notice Proposes a change to the global epoch duration parameter.
      * @dev Requires a minimum influence score. Callable in EpochActive state. Only one proposal active at a time.
      * @param _newDuration The proposed new epoch duration in seconds.
      */
     function proposeEpochDurationChange(uint256 _newDuration) external onlyRegisteredParticipant onlyState(SystemState.EpochActive) {
         require(!epochDurationVote.isActive, "DAC: Epoch duration change proposal already active");
         require(_getEffectiveInfluence(msg.sender) >= systemParameters[PARAM_MIN_INFLUENCE_FOR_PROPOSAL], "DAC: Insufficient influence to propose");
         require(_newDuration > 0, "DAC: New duration must be greater than zero");

         // Initialize the new proposal struct. Mapping `hasVoted` is reset.
         epochDurationVote = EpochDurationVote({
             newDuration: _newDuration,
             totalInfluenceVoted: 0,
             hasVoted: new mapping(address => bool),
             isActive: true
         });

         emit EpochDurationChangeProposed(msg.sender, _newDuration);
     }

     /**
      * @notice Submits a vote for the currently active epoch duration change proposal.
      * @dev Callable during EpochActive (representing a continuous voting period).
      * Requires being a participant and consumes yield.
      * @param _newDuration The proposed duration value being voted on (must match the active proposal).
      */
     function voteForEpochDurationChange(uint256 _newDuration) external onlyRegisteredParticipant onlyState(SystemState.EpochActive) {
         require(epochDurationVote.isActive, "DAC: No active epoch duration change proposal");
         require(epochDurationVote.newDuration == _newDuration, "DAC: Voted duration does not match active proposal");

         uint256 cost = 1; // Define cost
         require(participants[msg.sender].epochYield >= cost, "DAC: Insufficient epoch yield to vote");
         require(!epochDurationVote.hasVoted[msg.sender], "DAC: Already voted on this proposal in this epoch");

         uint256 effectiveInf = _getEffectiveInfluence(msg.sender);
         require(effectiveInf > 0, "DAC: Cannot vote with zero influence");

         uint256 oldYield = participants[msg.sender].epochYield;
         participants[msg.sender].epochYield -= cost;

         epochDurationVote.totalInfluenceVoted += effectiveInf;
         epochDurationVote.hasVoted[msg.sender] = true;

         emit EpochDurationVoteSubmitted(msg.sender, _newDuration, effectiveInf);
         emit ParticipantYieldChanged(msg.sender, oldYield, participants[msg.sender].epochYield);
     }

     /**
      * @dev Internal function to tally the epoch duration vote and apply change if passed.
      * Called during epoch processing.
      */
     function _tallyEpochDurationVoteAndApply() private {
         if (epochDurationVote.isActive) {
             uint256 threshold = systemParameters[PARAM_INFLUENCE_GRANT_AFFIRM_THRESHOLD]; // Using this parameter as the threshold

             if (epochDurationVote.totalInfluenceVoted >= threshold) {
                 uint256 oldDuration = systemParameters[PARAM_EPOCH_DURATION];
                 systemParameters[PARAM_EPOCH_DURATION] = epochDurationVote.newDuration;
                 emit EpochDurationChanged(oldDuration, epochDurationVote.newDuration);
             }
             // Deactivate the proposal regardless of outcome
             epochDurationVote.isActive = false;
             // Mapping `hasVoted` will be reset upon the next proposal creation due to how structs/mappings work.
         }
     }


    /**
     * @notice Proposes granting influence to a specific participant.
     * @dev Requires a minimum effective influence score. Creates a proposal that needs affirmation. Callable in EpochActive.
     * @param _recipient The address to grant influence to.
     * @param _amount The amount of influence to grant.
     * @return proposalId The unique ID of the created proposal.
     */
    function proposeInfluenceGrant(address _recipient, uint256 _amount) external onlyRegisteredParticipant onlyState(SystemState.EpochActive) returns (bytes32 proposalId) {
        require(_getEffectiveInfluence(msg.sender) >= systemParameters[PARAM_MIN_INFLUENCE_FOR_PROPOSAL], "DAC: Insufficient influence to propose");
        require(participants[_recipient].isRegistered, "DAC: Recipient must be a registered participant");
        require(_amount > 0, "DAC: Grant amount must be positive");

        // Generate a proposal ID based on unique data
        proposalId = keccak256(abi.encodePacked(msg.sender, _recipient, _amount, block.timestamp, activeGrantProposals.length, currentEpoch));

        // Ensure proposal ID is unique (highly likely with timestamp/length/epoch)
        require(influenceGrantProposals[proposalId].proposer == address(0), "DAC: Proposal ID collision, retry");

        influenceGrantProposals[proposalId] = InfluenceGrantProposal({
            proposer: msg.sender,
            recipient: _recipient,
            amount: _amount,
            hasAffirmed: new mapping(address => bool), // Initialize mapping
            affirmationInfluenceSum: 0,
            executed: false
        });

        activeGrantProposals.push(proposalId);

        emit InfluenceGrantProposed(msg.sender, _recipient, _amount, proposalId);
    }

    /**
     * @notice Affirms an existing influence grant proposal.
     * @dev Requires a minimum effective influence score. Adds effective influence weight to the proposal's affirmation sum. Callable in EpochActive.
     * @param _proposalId The ID of the proposal to affirm.
     */
    function affirmInfluenceGrant(bytes32 _proposalId) external onlyRegisteredParticipant onlyState(SystemState.EpochActive) {
        InfluenceGrantProposal storage proposal = influenceGrantProposals[_proposalId];
        require(proposal.proposer != address(0), "DAC: Proposal does not exist"); // Check if proposal exists
        require(!proposal.executed, "DAC: Proposal already executed");
        require(!proposal.hasAffirmed[msg.sender], "DAC: Already affirmed this proposal");

        uint256 effectiveInf = _getEffectiveInfluence(msg.sender);
        require(effectiveInf > 0, "DAC: Cannot affirm with zero influence");

        proposal.hasAffirmed[msg.sender] = true;
        proposal.affirmationInfluenceSum += effectiveInf;

        emit InfluenceGrantAffirmed(msg.sender, _proposalId, effectiveInf);
    }

    /**
     * @notice Executes influence grant proposals that have met the affirmation threshold.
     * @dev Callable by anyone. Processes proposals and grants influence. Designed to be called during EpochProcessing.
     */
    function executeInfluenceGrantProposals() public onlyState(SystemState.EpochProcessing) { // Made public so advanceEpochAndProcess can call it
        uint256 threshold = systemParameters[PARAM_INFLUENCE_GRANT_AFFIRM_THRESHOLD];
        bytes32[] memory proposalsToKeep; // New list for proposals not yet executed in this epoch

        for(uint i = 0; i < activeGrantProposals.length; i++) {
            bytes32 proposalId = activeGrantProposals[i];
            InfluenceGrantProposal storage proposal = influenceGrantProposals[proposalId];

            // Only process if not already executed
            if (!proposal.executed) {
                if (proposal.affirmationInfluenceSum >= threshold) {
                    // Execute the grant
                    uint256 oldInfluence = participants[proposal.recipient].baseInfluence;
                    participants[proposal.recipient].baseInfluence += proposal.amount;
                    proposal.executed = true; // Mark as executed for this epoch

                    emit InfluenceGrantExecuted(proposalId, proposal.recipient, proposal.amount);
                    emit ParticipantInfluenceChanged(proposal.recipient, oldInfluence, participants[proposal.recipient].baseInfluence);

                } else {
                    // Keep proposals that haven't met the threshold yet for future epochs
                     proposalsToKeep.push(proposalId);
                }
            } else {
                // Keep proposals that were executed in a previous epoch but still in the list
                // This shouldn't happen if cleanup works, but defensive.
                // Better: executed proposals are simply NOT added to proposalsToKeep.
            }
        }
         // Update activeGrantProposals to only include those not executed *in this run*.
         // They will be fully cleared from the active list in _cleanupEpochData.
         // For now, this means proposals that failed or were already executed this epoch are excluded.
         activeGrantProposals = proposalsToKeep;
    }


    /**
     * @dev Internal function to decay influence scores based on a parameter.
     * Called during epoch processing.
     */
    function _decayInfluence() private {
        uint256 decayRate = systemParameters[PARAM_INFLUENCE_DECAY_RATE]; // Expect this to be a percentage scaled, e.g., 10 for 1% decay if scaled by 1000
        if (decayRate == 0) return; // No decay

        uint256 scale = 1000; // Example scale, parameter value is decayRate / scale

        for(uint i = 0; i < participantList.length; i++) {
            address participantAddress = participantList[i];
             uint256 oldInfluence = participants[participantAddress].baseInfluence;
            if (oldInfluence > 0) {
                // Apply decay: new = old * (1 - rate/scale)
                // Example: 100 inf, 1% decay (rate 10, scale 1000) -> 100 * (1 - 10/1000) = 100 * 0.99 = 99
                // Using checked subtraction is safe as scale > decayRate is expected.
                participants[participantAddress].baseInfluence = (oldInfluence * (scale - decayRate)) / scale;
                 if(participants[participantAddress].baseInfluence != oldInfluence) {
                     emit ParticipantInfluenceChanged(participantAddress, oldInfluence, participants[participantAddress].baseInfluence);
                 }
            }
        }
    }

     /**
      * @dev Internal function to clean up expired or processed epoch data.
      * Called during epoch processing.
      */
     function _cleanupEpochData() private {
        // Pending submissions are cleared in _processPendingDataSubmissions
        // Parameter votes state needs to be reset for the next epoch's voting
        for(uint i = 0; i < parameterNames.length; i++) {
             bytes32 paramName = parameterNames[i];
             // Resetting the struct clears the mapping `hasVoted` for this parameter for the next epoch
             delete parameterVotes[paramName];
        }

        // Epoch duration vote state needs to be reset for the next epoch
        // The `isActive` flag is set to false in _tallyEpochDurationVoteAndApply.
        // The `hasVoted` mapping will be reset upon the next call to proposeEpochDurationChange.

        // Influence Grant Proposals: Clear executed proposals from the active list
        // The `executeInfluenceGrantProposals` function already filtered the list to only include non-executed proposals.
        // To clear ALL active proposals (even non-executed) at epoch end:
        // delete activeGrantProposals; // Uncomment this line to clear all active proposals each epoch

        // Clear epoch-specific bonus parameters
        // Iterating and deleting from mapping is gas intensive. Best if there's a fixed small list or map key includes epoch.
        // For simplicity, let's assume a fixed small list of potential bonus params or accept the cost.
        // Or, design it so bonus params are queried by name and if name+epoch is not found, it's 0.
        // Let's use a simple mapping and clear it. This is O(N) where N is the number of distinct bonus params set.
        // In this example, we only set one type, but can be extended.
         // For a robust implementation, store bonus params keyed by `(bytes32 paramName, uint256 epoch)` and query by current epoch. No cleanup needed then, just storage growth.
         // Let's switch to that storage model for bonus params.

         // Old: mapping(bytes32 => uint256) private epochBonusParameters;
         // New: mapping(bytes32 => mapping(uint256 => uint256)) private epochBonusParametersByEpoch; // paramName => epoch => value

         // Update `setEpochBonusParameter` and `queryEpochBonusParameter` accordingly.
         // No cleanup needed for this new structure.
     }


    // --- View Functions ---

    /**
     * @notice Returns the current state of the chronicle.
     */
    function queryCurrentState() external view returns (SystemState) {
        return currentState;
    }

     /**
      * @notice Returns the current epoch number.
      */
    function queryCurrentEpoch() external view returns (uint256) {
        return currentEpoch;
    }

    /**
     * @notice Returns the timestamp when the current epoch is scheduled to end.
     */
    function queryEpochEndTime() external view returns (uint256) {
        return epochEndTime;
    }

     /**
      * @notice Returns the current values of all adjustable system parameters.
      * @dev Returns arrays of parameter names and their corresponding values.
      */
    function querySystemParameters() external view returns (bytes32[] memory names, uint256[] memory values) {
        names = new bytes32[](parameterNames.length);
        values = new uint256[](parameterNames.length);
        for(uint i = 0; i < parameterNames.length; i++) {
            names[i] = parameterNames[i];
            values[i] = systemParameters[parameterNames[i]];
        }
        return (names, values);
    }

    /**
     * @notice Returns the base influence score for a participant.
     * @param _participant The address of the participant.
     */
    function queryParticipantInfluence(address _participant) external view returns (uint256) {
        return participants[_participant].baseInfluence;
    }

    /**
     * @notice Returns the current usable epoch yield balance for a participant.
     * @param _participant The address of the participant.
     */
    function queryParticipantYield(address _participant) external view returns (uint256) {
        return participants[_participant].epochYield;
    }

     /**
      * @notice Returns the claimable epoch yield for a participant (yield earned but not yet moved to usable balance).
      * @param _participant The address of the participant.
      */
     function queryParticipantClaimableYield(address _participant) external view returns (uint256) {
         return participants[_participant].claimableYield;
     }


    /**
     * @notice Returns the address that a participant has delegated their influence to.
     * @param _participant The address of the participant.
     */
    function queryDelegatee(address _participant) external view returns (address) {
        return participants[_participant].delegatee;
    }

    /**
     * @notice Calculates and returns the effective influence for a participant, considering delegations.
     * @dev This function calculates effective influence as base influence + sum of base influence from direct delegators.
     * It requires iterating over all participants, which can be gas-intensive for a large participant list.
     * @param _participant The address of the participant.
     */
    function getEffectiveInfluence(address _participant) external view returns (uint256) {
       uint256 effectiveInf = participants[_participant].baseInfluence;
        // Iterate through all participants to find those delegating to _participant
        for(uint i = 0; i < participantList.length; i++) {
            address potentialDelegator = participantList[i];
            // Ensure not the participant themselves, they are registered, and they delegate to _participant
            // Also ensure the delegator has a non-zero base influence to contribute
            if (potentialDelegator != _participant && participants[potentialDelegator].isRegistered && participants[potentialDelegator].delegatee == _participant && participants[potentialDelegator].baseInfluence > 0) {
                effectiveInf += participants[potentialDelegator].baseInfluence;
            }
        }
        return effectiveInf;
    }


    /**
     * @notice Returns the number of pending data submissions for the current epoch.
     */
    function queryPendingSubmissionsCount() external view returns (uint256) {
        return pendingDataSubmissions.length;
    }

    /**
     * @notice Returns details about the current votes for a specific generic parameter change.
     * @param _parameterName The keccak256 hash of the parameter name.
     */
    function queryParameterVoteDetails(bytes32 _parameterName) external view returns (uint256 newValue, uint256 totalInfluenceVoted) {
        ParameterVote storage vote = parameterVotes[_parameterName];
        // Note: Cannot return the `hasVoted` mapping directly.
        return (vote.newValue, vote.totalInfluenceVoted);
    }

    /**
     * @notice Returns details about an active influence grant proposal.
     * @param _proposalId The ID of the proposal.
     */
    function queryInfluenceGrantProposalDetails(bytes32 _proposalId) external view returns (
        address proposer,
        address recipient,
        uint256 amount,
        uint256 affirmationInfluenceSum,
        bool executed
    ) {
         InfluenceGrantProposal storage proposal = influenceGrantProposals[_proposalId];
         // Check if proposal exists (proposer will be address(0) if not)
         require(proposal.proposer != address(0), "DAC: Proposal does not exist");
         return (
             proposal.proposer,
             proposal.recipient,
             proposal.amount,
             proposal.affirmationInfluenceSum,
             proposal.executed
         );
         // Note: Cannot return the `hasAffirmed` mapping directly.
    }

     /**
      * @notice Returns details about the currently active epoch duration change proposal.
      */
     function queryEpochDurationChangeProposalDetails() external view returns (
         uint256 newDuration,
         uint256 totalInfluenceVoted,
         bool isActive
     ) {
         // Note: Cannot return the `hasVoted` mapping directly.
         return (
             epochDurationVote.newDuration,
             epochDurationVote.totalInfluenceVoted,
             epochDurationVote.isActive
         );
     }

     /**
      * @notice Checks if an address is a registered participant.
      * @param _participant The address to check.
      */
     function isParticipant(address _participant) external view returns (bool) {
         return participants[_participant].isRegistered;
     }


     /**
      * @notice Allows a participant to burn some of their usable epoch yield.
      * @dev Useful if yield accumulates excessively or for future mechanics. Consumes yield.
      * @param _amount The amount of yield to burn.
      */
     function burnEpochYield(uint256 _amount) external onlyRegisteredParticipant {
         require(_amount > 0, "DAC: Burn amount must be positive");
         require(participants[msg.sender].epochYield >= _amount, "DAC: Insufficient epoch yield to burn");
         uint256 oldYield = participants[msg.sender].epochYield;
         participants[msg.sender].epochYield -= _amount;
         emit YieldBurned(msg.sender, _amount);
         emit ParticipantYieldChanged(msg.sender, oldYield, participants[msg.sender].epochYield);
     }

    /**
     * @notice Grants initial influence during the Genesis state.
     * @dev Can only be called during Genesis. Intended for initial distribution.
     * @param _participant The address to grant influence to.
     * @param _amount The amount of influence to grant.
     */
    function grantGenesisInfluence(address _participant, uint256 _amount) external onlyGenesis {
         require(participants[_participant].isRegistered, "DAC: Participant must be registered");
         require(_amount > 0, "DAC: Grant amount must be positive");
         uint256 oldInfluence = participants[_participant].baseInfluence;
         participants[_participant].baseInfluence += _amount;
         emit InfluenceGrantedDirectly(_participant, _amount);
         emit ParticipantInfluenceChanged(_participant, oldInfluence, participants[_participant].baseInfluence);
    }

     /**
      * @dev Internal function using block data for a pseudo-random value. Highly insecure for critical functions.
      * @return A newly generated uint256 value.
      */
     function _discoverValue() internal view returns (uint256) {
         // In a real Dapp, this would likely use an oracle (like Chainlink VRF)
         // This is a simplified, deterministic example based on block data.
         uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, block.difficulty, msg.sender, currentEpoch)));
         return uint256(keccak256(abi.encodePacked(seed, "discovery")));
     }

     // New storage for epoch bonus parameters keyed by name AND epoch
     mapping(bytes32 => mapping(uint256 => uint256)) private epochBonusParametersByEpoch; // paramName => epoch => value

     /**
      * @notice Sets a temporary epoch-specific bonus parameter based on on-chain discovery.
      * @dev Callable only during EpochProcessing. The parameter is only valid for the epoch it was set.
      * @param _bonusParameterName Hash of the temporary parameter name.
      */
     function setEpochBonusParameter(bytes32 _bonusParameterName) external onlyState(SystemState.EpochProcessing) {
        // Check if a bonus parameter with this name has already been set for this epoch
        require(epochBonusParametersByEpoch[_bonusParameterName][currentEpoch] == 0, "DAC: Bonus parameter already set for this epoch");

        // Use the discovery mechanism to set the value
        uint256 discoveredValue = _discoverValue();

        // Store keyed by name and current epoch
        epochBonusParametersByEpoch[_bonusParameterName][currentEpoch] = discoveredValue;

        // Emit event. We can't use ParameterChanged as it implies a system parameter change.
        // Let's create a new event.
        // event EpochBonusParameterSet(bytes32 indexed parameterName, uint256 indexed epoch, uint256 value);
        // (Need to add this event to the top)
        emit EpochBonusParameterSet(_bonusParameterName, currentEpoch, discoveredValue);
     }

     /**
      * @notice Queries the value of an epoch-specific bonus parameter for a given epoch.
      * @param _bonusParameterName Hash of the temporary parameter name.
      * @param _epoch The epoch number to query the bonus parameter for. Use 0 for current epoch if needed, but storage is by `currentEpoch`.
      * @return The value of the bonus parameter for that epoch, or 0 if not set.
      */
     function queryEpochBonusParameter(bytes32 _bonusParameterName, uint256 _epoch) external view returns (uint256) {
         return epochBonusParametersByEpoch[_bonusParameterName][_epoch];
     }

    // Add total participant count function
    /**
     * @notice Returns the total number of registered participants.
     */
    function queryTotalParticipants() external view returns (uint256) {
        return participantList.length;
    }

}
```