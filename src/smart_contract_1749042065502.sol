Okay, here is a Solidity smart contract implementing a complex "Quantum Vault" concept. The core idea is a treasury where funds are locked, and their release (or other actions) depends on a dynamic, multi-factor set of conditions ("quantum superposition" of potential outcomes). A dedicated governance system manages these outcomes and other critical parameters.

This contract incorporates:
1.  **Conditional State Resolution:** Multiple potential release outcomes, each with complex, configurable conditions. A single `triggerRelease` function evaluates these conditions dynamically to determine which (if any) outcome is executed.
2.  **Layered Governance:** A proposal system requiring voting and a time lock for critical changes (adding/updating/removing outcomes, setting parameters).
3.  **Diverse Condition Types:** Conditions can be based on time, internal contract flags, external data (simulated via oracle placeholder), and governance vote counts.
4.  **Prioritized Outcomes:** Outcomes can have priority, influencing the order of evaluation during triggering.

This avoids direct duplication of standard ERC-20/721, simple timelocks, or basic multisigs by integrating complex, dynamic condition evaluation and a specific governance flow for state modification.

---

**Outline & Function Summary**

**Contract:** `QuantumVault`

A secure vault for Ether and potentially other tokens (extendable) where the release of assets is governed by a complex system of predefined, prioritized outcomes. Each outcome has a set of conditions that must be met for it to be triggered. The configuration of outcomes and other critical parameters is managed via a built-in, time-locked governance system.

**State Variables:**
*   `owner`: The contract owner (can be a multisig or another governance contract).
*   `nextOutcomeId`: Counter for unique outcome IDs.
*   `nextProposalId`: Counter for unique proposal IDs.
*   `outcomes`: Mapping from ID to `ReleaseOutcome` struct.
*   `activeOutcomeIds`: Array of IDs of currently active outcomes, ordered by priority (lower index = higher priority).
*   `proposals`: Mapping from ID to `Proposal` struct.
*   `hasVoted`: Mapping to track voter status for each proposal.
*   `internalFlags`: Mapping for boolean flags usable in conditions.
*   `externalOracleValues`: Mapping to simulate external data feed values.
*   `proposalTimelock`: Minimum time required between proposal queueing and execution.
*   `executionBuffer`: Time buffer after vote ends before execution is allowed (to allow queuing).

**Enums:**
*   `ConditionType`: Defines the type of condition (TimeThreshold, ExternalValueThreshold, InternalFlag, MinGovernanceVotes).
*   `ComparisonType`: Defines how a value is compared (GreaterThan, LessThan, EqualTo).
*   `ProposalType`: Defines the action a proposal enacts (AddOutcome, UpdateOutcome, RemoveOutcome, SetOracleValue, SetInternalFlag, SetTimelock, SetExecutionBuffer).
*   `ProposalState`: Defines the lifecycle of a proposal (Pending, Active, Passed, Failed, Queued, Executed, Cancelled).

**Structs:**
*   `Condition`: Represents a single condition within an outcome.
*   `ReleaseOutcome`: Represents a potential action (like sending Ether) with its ID, recipient, value, conditions, active status, and priority.
*   `Proposal`: Represents a governance proposal with its type, state, parameters, voting details, and execution times.

**Events:**
*   `Deposit`: Logs received Ether deposits.
*   `ReleaseTriggered`: Logs when the `triggerRelease` function is called.
*   `OutcomeTriggered`: Logs when a specific outcome's conditions are met and it's executed.
*   `OutcomeAdded`: Logs when a new outcome is successfully added via governance.
*   `OutcomeUpdated`: Logs when an outcome is updated via governance.
*   `OutcomeRemoved`: Logs when an outcome is removed via governance.
*   `ProposalCreated`: Logs the creation of a new proposal.
*   `VoteCast`: Logs a vote on a proposal.
*   `ProposalStateChanged`: Logs state transitions for proposals (e.g., Passed, Failed, Queued, Executed, Cancelled).
*   `ExternalOracleValueSet`: Logs when a simulated oracle value is set.
*   `InternalFlagSet`: Logs when an internal flag is set.
*   `TimelockUpdated`: Logs when the proposal timelock is changed.
*   `ExecutionBufferUpdated`: Logs when the execution buffer is changed.

**Functions (27 Total):**

1.  `constructor()`: Initializes the contract with the owner and default timelock/buffer.
2.  `receive()`: Allows receiving Ether deposits.
3.  `deposit()`: Explicit function for receiving Ether deposits (alternative to `receive`).
4.  `getContractBalance()`: View function to check the contract's Ether balance.
5.  `createProposal(ProposalType _proposalType, uint256 _targetOutcomeId, ReleaseOutcome calldata _newOutcomeConfig, bytes32 _oracleKey, uint256 _oracleValue, bytes32 _flagKey, bool _flagValue, uint256 _uintValue, uint256 _votePeriod, uint256 _quorum)`: Creates a new governance proposal.
6.  `vote(uint256 _proposalId, bool _support)`: Casts a vote (yay/nay) on an active proposal.
7.  `checkProposalState(uint256 _proposalId)`: Internal helper to determine the current state of a proposal.
8.  `queueProposal(uint256 _proposalId)`: Moves a successfully passed proposal into the execution queue after its voting period ends.
9.  `executeProposal(uint256 _proposalId)`: Executes a queued proposal after the timelock has expired.
10. `cancelProposal(uint256 _proposalId)`: Allows the proposer or owner to cancel a pending or active proposal.
11. `triggerRelease()`: The core function. Evaluates all active outcomes in priority order and executes the first one whose conditions are met.
12. `executeOutcome(uint256 _outcomeId)`: Internal helper to perform the action defined by an outcome (e.g., send Ether).
13. `checkOutcomeConditions(uint256 _outcomeId)`: Internal/Public view function to check if all conditions for a given outcome are currently met.
14. `checkCondition(Condition calldata _condition)`: Internal helper to evaluate a single condition.
15. `addOutcome(ReleaseOutcome calldata _outcome)`: Internal function called by successful proposals to add a new outcome.
16. `updateOutcome(uint256 _outcomeId, ReleaseOutcome calldata _newOutcomeConfig)`: Internal function called by successful proposals to update an existing outcome.
17. `removeOutcome(uint256 _outcomeId)`: Internal function called by successful proposals to remove an outcome.
18. `setExternalOracleValue(bytes32 _key, uint256 _value)`: Internal function called by successful proposals to set a simulated external oracle value.
19. `setInternalFlag(bytes32 _key, bool _value)`: Internal function called by successful proposals to set an internal boolean flag.
20. `setProposalTimelock(uint256 _timelock)`: Internal function called by successful proposals to set the timelock duration.
21. `setExecutionBuffer(uint256 _buffer)`: Internal function called by successful proposals to set the execution buffer duration.
22. `getOutcomeDetails(uint256 _outcomeId)`: View function to retrieve details of a specific outcome.
23. `getProposalDetails(uint256 _proposalId)`: View function to retrieve details of a specific proposal.
24. `getActiveOutcomeIds()`: View function to get the list of active outcome IDs in priority order.
25. `getInternalFlag(bytes32 _key)`: View function to get the state of an internal flag.
26. `getExternalOracleValue(bytes32 _key)`: View function to get the value of a simulated external oracle feed.
27. `getProposalState(uint256 _proposalId)`: View function to get the current state of a proposal.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title QuantumVault
/// @notice A secure vault with dynamic, conditional release mechanisms governed by a complex proposal system.
/// @dev Funds release is determined by evaluating a prioritized list of outcomes, each with multiple configurable conditions.
/// @dev Configuration changes and parameter updates require a time-locked governance proposal process.
contract QuantumVault {

    /// @dev Enum representing different types of conditions that can be evaluated.
    enum ConditionType {
        TimeThreshold,        // Condition based on block.timestamp
        ExternalValueThreshold, // Condition based on an external data feed value (simulated)
        InternalFlag,         // Condition based on an internal contract boolean flag
        MinGovernanceVotes    // Condition based on the number of 'yay' votes on a specific proposal
    }

    /// @dev Enum representing types of comparisons for value-based conditions.
    enum ComparisonType {
        GreaterThan,
        LessThan,
        EqualTo
    }

    /// @dev Struct defining a single condition.
    struct Condition {
        ConditionType conditionType;
        ComparisonType comparisonType; // Only relevant for TimeThreshold, ExternalValueThreshold, MinGovernanceVotes
        uint256 value;              // Threshold value for comparisons (time, external data, votes)
        bytes32 key;                // Key for ExternalValueThreshold (oracle data key) or InternalFlag (flag name)
        uint256 proposalId;         // Relevant only for MinGovernanceVotes (the proposal to check votes against)
    }

    /// @dev Struct defining a potential release outcome.
    struct ReleaseOutcome {
        uint256 id;             // Unique identifier for the outcome
        address recipient;      // Address to send funds to or interact with
        uint256 value;          // Amount of Ether to send (or other value depending on action)
        Condition[] conditions; // Array of conditions, ALL must be true for the outcome to be triggered
        bool isActive;          // Whether this outcome is currently active and considered
        uint256 priority;       // Lower number means higher priority (evaluated first)
        // Future extensions: Add bytes data for contract calls, token addresses, etc.
    }

    /// @dev Enum representing the types of governance proposals.
    enum ProposalType {
        AddOutcome,           // Adds a new ReleaseOutcome
        UpdateOutcome,        // Modifies an existing ReleaseOutcome
        RemoveOutcome,        // Deactivates/Removes an existing ReleaseOutcome
        SetExternalOracleValue, // Sets a value in the simulated externalOracleValues mapping
        SetInternalFlag,      // Sets a value in the internalFlags mapping
        SetTimelock,          // Sets the proposalTimelock duration
        SetExecutionBuffer    // Sets the executionBuffer duration
    }

    /// @dev Enum representing the state of a governance proposal.
    enum ProposalState {
        Pending,  // Created but not yet active (voting hasn't started)
        Active,   // Voting is currently open
        Passed,   // Voting period ended, votes met quorum and majority
        Failed,   // Voting period ended, votes did not meet quorum or majority
        Queued,   // Passed proposal waiting for timelock to expire
        Executed, // Proposal successfully executed
        Cancelled // Proposal cancelled by proposer or owner
    }

    /// @dev Struct defining a governance proposal.
    struct Proposal {
        uint256 id;             // Unique identifier for the proposal
        ProposalType proposalType;
        address proposer;
        uint256 voteStart;      // Timestamp when voting starts
        uint256 voteEnd;        // Timestamp when voting ends
        uint256 quorum;         // Minimum total votes required for proposal to pass (relative to total possible voters, simplified here as absolute count)
        uint256 yayVotes;       // Count of 'yay' votes
        uint256 nayVotes;       // Count of 'nay' votes
        ProposalState state;
        uint256 queuedForExecution; // Timestamp when a passed proposal is queued (execution not before this time)

        // Proposal specific data payloads (use appropriate fields based on proposalType)
        uint256 targetOutcomeId;         // For UpdateOutcome, RemoveOutcome
        ReleaseOutcome newOutcomeConfig; // For AddOutcome, UpdateOutcome (contains conditions, recipient, value, priority, but ID is ignored/validated)
        bytes32 oracleKey;               // For SetExternalOracleValue
        uint256 oracleValue;             // For SetExternalOracleValue, SetTimelock, SetExecutionBuffer
        bytes32 flagKey;                 // For SetInternalFlag
        bool flagValue;                  // For SetInternalFlag
    }

    // State Variables
    address public owner; // Owner can cancel proposals and is the only one who can initially set up governance parameters

    uint256 private nextOutcomeId = 0;
    uint256 private nextProposalId = 0;

    // Mapping from Outcome ID to ReleaseOutcome struct
    mapping(uint256 => ReleaseOutcome) public outcomes;
    // Ordered list of active Outcome IDs by priority (lower index = higher priority)
    uint256[] private activeOutcomeIds;

    // Mapping from Proposal ID to Proposal struct
    mapping(uint256 => Proposal) public proposals;
    // Mapping to track if an address has voted on a specific proposal
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // Mapping for internal boolean flags used in conditions
    mapping(bytes32 => bool) public internalFlags;
    // Mapping to simulate external data feeds (e.g., price, temperature)
    mapping(bytes32 => uint256) public externalOracleValues;

    uint256 public proposalTimelock; // Minimum seconds between proposal queueing and execution
    uint256 public executionBuffer;  // Seconds buffer after voteEnd to allow queuing

    // Events
    event Deposit(address indexed sender, uint256 amount);
    event ReleaseTriggered(address indexed caller, uint256 outcomesConsidered, uint256 outcomesExecuted);
    event OutcomeTriggered(uint256 indexed outcomeId, address indexed recipient, uint256 value);
    event OutcomeAdded(uint256 indexed outcomeId, address indexed proposer);
    event OutcomeUpdated(uint256 indexed outcomeId, address indexed proposer);
    event OutcomeRemoved(uint256 indexed outcomeId, address indexed proposer);
    event ProposalCreated(uint256 indexed proposalId, ProposalType proposalType, address indexed proposer, uint256 voteEnd);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event ExternalOracleValueSet(bytes32 indexed key, uint256 value);
    event InternalFlagSet(bytes32 indexed key, bool value);
    event TimelockUpdated(uint256 oldTimelock, uint256 newTimelock);
    event ExecutionBufferUpdated(uint256 oldBuffer, uint256 newBuffer);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        proposalTimelock = 7 days; // Default timelock
        executionBuffer = 1 days;   // Default buffer after voting ends
    }

    /// @notice Allows sending Ether to the contract.
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Explicit function to deposit Ether into the vault.
    function deposit() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Gets the current Ether balance of the contract.
    /// @return The contract's Ether balance.
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Creates a new governance proposal.
    /// @dev Proposer must fill in the relevant fields in the data payloads based on proposalType. Unused fields are ignored.
    /// @param _proposalType The type of action the proposal proposes.
    /// @param _targetOutcomeId For UpdateOutcome, RemoveOutcome. Ignored otherwise.
    /// @param _newOutcomeConfig For AddOutcome, UpdateOutcome. Ignored otherwise.
    /// @param _oracleKey For SetExternalOracleValue. Ignored otherwise.
    /// @param _oracleValue For SetExternalOracleValue, SetTimelock, SetExecutionBuffer. Ignored otherwise.
    /// @param _flagKey For SetInternalFlag. Ignored otherwise.
    /// @param _flagValue For SetInternalFlag. Ignored otherwise.
    /// @param _uintValue Generic uint value for Timelock/Buffer updates. Ignored otherwise.
    /// @param _votePeriod Duration of the voting period in seconds.
    /// @param _quorum Minimum total votes required.
    /// @return The ID of the newly created proposal.
    function createProposal(
        ProposalType _proposalType,
        uint256 _targetOutcomeId,
        ReleaseOutcome calldata _newOutcomeConfig,
        bytes32 _oracleKey,
        uint256 _oracleValue,
        bytes32 _flagKey,
        bool _flagValue,
        uint256 _uintValue, // Use for Timelock/Buffer
        uint256 _votePeriod,
        uint256 _quorum
    ) external returns (uint256) {
        require(_votePeriod > 0, "Vote period must be positive");

        uint256 proposalId = nextProposalId++;
        uint256 voteStart = block.timestamp;
        uint256 voteEnd = voteStart + _votePeriod;

        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposalType = _proposalType;
        newProposal.proposer = msg.sender;
        newProposal.voteStart = voteStart;
        newProposal.voteEnd = voteEnd;
        newProposal.quorum = _quorum;
        newProposal.state = ProposalState.Active;

        // Set proposal-specific data
        newProposal.targetOutcomeId = _targetOutcomeId;
        if (_proposalType == ProposalType.AddOutcome || _proposalType == ProposalType.UpdateOutcome) {
            // Copy the outcome config data
            newProposal.newOutcomeConfig.id = _newOutcomeConfig.id; // ID will be assigned/validated later
            newProposal.newOutcomeConfig.recipient = _newOutcomeConfig.recipient;
            newProposal.newOutcomeConfig.value = _newOutcomeConfig.value;
            newProposal.newOutcomeConfig.isActive = _newOutcomeConfig.isActive;
            newProposal.newOutcomeConfig.priority = _newOutcomeConfig.priority;
            // Deep copy conditions array
            newProposal.newOutcomeConfig.conditions = new Condition[](_newOutcomeConfig.conditions.length);
            for (uint i = 0; i < _newOutcomeConfig.conditions.length; i++) {
                newProposal.newOutcomeConfig.conditions[i] = _newOutcomeConfig.conditions[i];
            }
        }
        newProposal.oracleKey = _oracleKey;
        newProposal.oracleValue = _oracleValue; // Used for SetOracle, SetTimelock, SetExecutionBuffer
        newProposal.flagKey = _flagKey;         // Used for SetInternalFlag
        newProposal.flagValue = _flagValue;       // Used for SetInternalFlag
        newProposal.oracleValue = _uintValue; // Overrides if Timelock/Buffer type

        emit ProposalCreated(proposalId, _proposalType, msg.sender, voteEnd);
        emit ProposalStateChanged(proposalId, ProposalState.Active);

        return proposalId;
    }

    /// @notice Casts a vote on an active proposal.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for a 'yay' vote, false for a 'nay' vote.
    function vote(uint256 _proposalId, bool _support) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Active, "Proposal not active");
        require(block.timestamp >= proposal.voteStart && block.timestamp <= proposal.voteEnd, "Voting not open");
        require(!hasVoted[_proposalId][msg.sender], "Already voted");

        hasVoted[_proposalId][msg.sender] = true;
        if (_support) {
            proposal.yayVotes++;
        } else {
            proposal.nayVotes++;
        }

        emit VoteCast(_proposalId, msg.sender, _support);

        // Automatically check state if voting period ends with this vote
        if (block.timestamp == proposal.voteEnd) {
            // Re-evaluate state which might transition it
            checkProposalState(_proposalId); // State change might be emitted here
        }
    }

    /// @notice Gets the current state of a proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return The current state of the proposal.
    function getProposalState(uint256 _proposalId) public view returns (ProposalState) {
        return checkProposalState(_proposalId);
    }

    /// @dev Internal helper to determine the current state of a proposal based on time and votes.
    /// @param _proposalId The ID of the proposal.
    /// @return The calculated state of the proposal.
    function checkProposalState(uint256 _proposalId) internal view returns (ProposalState) {
        Proposal storage proposal = proposals[_proposalId];

        if (proposal.state == ProposalState.Executed || proposal.state == ProposalState.Cancelled) {
            return proposal.state;
        }
        if (proposal.state == ProposalState.Queued) {
             // Stay in Queued until executed
             return ProposalState.Queued;
        }

        if (block.timestamp < proposal.voteStart) {
            return ProposalState.Pending;
        }

        if (block.timestamp >= proposal.voteStart && block.timestamp <= proposal.voteEnd) {
            return ProposalState.Active;
        }

        // Voting period has ended (block.timestamp > proposal.voteEnd)
        uint256 totalVotes = proposal.yayVotes + proposal.nayVotes;
        if (totalVotes >= proposal.quorum && proposal.yayVotes > proposal.nayVotes) {
            return ProposalState.Passed;
        } else {
            return ProposalState.Failed;
        }
    }

    /// @notice Moves a successfully passed proposal into the execution queue.
    /// @dev Can only be called after the voting period ends and the proposal has passed.
    /// @param _proposalId The ID of the proposal to queue.
    function queueProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        require(checkProposalState(_proposalId) == ProposalState.Passed, "Proposal must be Passed");
        require(block.timestamp > proposal.voteEnd, "Voting period not ended"); // Ensure buffer period is over? Or handled by next step. Let's add buffer requirement
        require(block.timestamp >= proposal.voteEnd + executionBuffer, "Execution buffer not passed");
        require(proposal.state != ProposalState.Queued && proposal.state != ProposalState.Executed && proposal.state != ProposalState.Cancelled, "Proposal already queued, executed or cancelled");

        proposal.state = ProposalState.Queued;
        proposal.queuedForExecution = block.timestamp + proposalTimelock;
        emit ProposalStateChanged(_proposalId, ProposalState.Queued);
    }

    /// @notice Executes a queued proposal after the timelock has expired.
    /// @dev Only executable once the timelock duration has passed since queueing.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Queued, "Proposal not in Queued state");
        require(block.timestamp >= proposal.queuedForExecution, "Timelock not expired");

        proposal.state = ProposalState.Executed;
        emit ProposalStateChanged(_proposalId, ProposalState.Executed);

        // Execute the proposal action based on its type
        if (proposal.proposalType == ProposalType.AddOutcome) {
            addOutcome(proposal.newOutcomeConfig);
        } else if (proposal.proposalType == ProposalType.UpdateOutcome) {
            updateOutcome(proposal.targetOutcomeId, proposal.newOutcomeConfig);
        } else if (proposal.proposalType == ProposalType.RemoveOutcome) {
            removeOutcome(proposal.targetOutcomeId);
        } else if (proposal.proposalType == ProposalType.SetExternalOracleValue) {
            setExternalOracleValue(proposal.oracleKey, proposal.oracleValue);
        } else if (proposal.proposalType == ProposalType.SetInternalFlag) {
             setInternalFlag(proposal.flagKey, proposal.flagValue);
        } else if (proposal.proposalType == ProposalType.SetTimelock) {
            setProposalTimelock(proposal.oracleValue); // Value stored in oracleValue field
        } else if (proposal.proposalType == ProposalType.SetExecutionBuffer) {
            setExecutionBuffer(proposal.oracleValue); // Value stored in oracleValue field
        }
        // Extend with more proposal types here
    }

    /// @notice Allows the proposer or owner to cancel a proposal before it's executed.
    /// @dev Can cancel if state is Pending, Active, or Passed (before queuing).
    /// @param _proposalId The ID of the proposal to cancel.
    function cancelProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        require(msg.sender == owner || msg.sender == proposal.proposer, "Not authorized to cancel");
        require(
            proposal.state == ProposalState.Pending ||
            proposal.state == ProposalState.Active ||
            (proposal.state == ProposalState.Passed && block.timestamp < proposal.voteEnd + executionBuffer), // Allow cancelling Passed before queuing window passes
            "Cannot cancel proposal in its current state" // Cannot cancel Queued, Executed, Cancelled
        );

        proposal.state = ProposalState.Cancelled;
        emit ProposalStateChanged(_proposalId, ProposalState.Cancelled);
    }


    /// @notice Triggers the evaluation of all active outcomes.
    /// @dev Iterates through active outcomes in priority order and executes the first one whose conditions are met.
    /// @return The ID of the outcome that was triggered and executed, or 0 if none were triggered.
    function triggerRelease() external returns (uint256 triggeredOutcomeId) {
        uint256 outcomesConsidered = 0;
        uint256 outcomesExecutedCount = 0;
        triggeredOutcomeId = 0;

        // Iterate through active outcomes by priority
        for (uint i = 0; i < activeOutcomeIds.length; i++) {
            uint256 outcomeId = activeOutcomeIds[i];
            ReleaseOutcome storage outcome = outcomes[outcomeId];

            // Skip if not active (shouldn't happen if logic correct, but safety check)
            if (!outcome.isActive) {
                 continue;
            }

            outcomesConsidered++;

            // Check if ALL conditions for this outcome are met
            if (checkOutcomeConditions(outcomeId)) {
                executeOutcome(outcomeId);
                triggeredOutcomeId = outcomeId;
                outcomesExecutedCount++;
                // Stop after the first triggered outcome (based on priority)
                break;
            }
        }

        emit ReleaseTriggered(msg.sender, outcomesConsidered, outcomesExecutedCount);
        return triggeredOutcomeId;
    }

    /// @dev Internal function to execute the action of a specific outcome.
    /// @param _outcomeId The ID of the outcome to execute.
    function executeOutcome(uint256 _outcomeId) internal {
        ReleaseOutcome storage outcome = outcomes[_outcomeId];
        // Additional checks before execution (should be covered by triggerRelease checks, but safe):
        require(outcome.isActive, "Outcome is not active");
        require(checkOutcomeConditions(_outcomeId), "Outcome conditions not met for execution"); // Re-check right before execution

        // --- Perform the outcome action ---
        // Example: Sending Ether
        if (outcome.value > 0) {
            require(address(this).balance >= outcome.value, "Insufficient balance for outcome");
            (bool success, ) = payable(outcome.recipient).call{value: outcome.value}("");
            require(success, "Ether transfer failed"); // Revert if transfer fails
        }

        // Future extensions: Add logic for token transfers, contract calls, etc.
        // if (outcome.actionType == ActionType.TransferToken) { ... }
        // if (outcome.actionType == ActionType.CallContract) { ... }

        emit OutcomeTriggered(_outcomeId, outcome.recipient, outcome.value);

        // Optional: Deactivate outcome after execution if it's a one-time release
        // outcome.isActive = false; // Depends on desired contract logic
        // If deactivated, need to remove from activeOutcomeIds array
    }


    /// @notice Checks if all conditions for a specific outcome are met.
    /// @dev Used by triggerRelease and can be called publicly for inspection.
    /// @param _outcomeId The ID of the outcome to check.
    /// @return True if all conditions are met, false otherwise.
    function checkOutcomeConditions(uint256 _outcomeId) public view returns (bool) {
        ReleaseOutcome storage outcome = outcomes[_outcomeId];
        require(outcome.id != 0 || nextOutcomeId == 0, "Outcome does not exist"); // Check existence

        // An outcome with no conditions is always true (if active)
        if (outcome.conditions.length == 0 && outcome.isActive) {
            return true;
        }

        // Check ALL conditions
        for (uint i = 0; i < outcome.conditions.length; i++) {
            if (!checkCondition(outcome.conditions[i])) {
                return false; // If any condition is false, the outcome is not met
            }
        }
        return true; // All conditions were true
    }

    /// @dev Internal helper to evaluate a single condition struct.
    /// @param _condition The condition to evaluate.
    /// @return True if the condition is met, false otherwise.
    function checkCondition(Condition calldata _condition) internal view returns (bool) {
        if (_condition.conditionType == ConditionType.TimeThreshold) {
            if (_condition.comparisonType == ComparisonType.GreaterThan) {
                return block.timestamp > _condition.value;
            } else if (_condition.comparisonType == ComparisonType.LessThan) {
                return block.timestamp < _condition.value;
            } else if (_condition.comparisonType == ComparisonType.EqualTo) {
                return block.timestamp == _condition.value;
            }
        } else if (_condition.conditionType == ConditionType.ExternalValueThreshold) {
            uint256 currentValue = externalOracleValues[_condition.key];
            if (_condition.comparisonType == ComparisonType.GreaterThan) {
                return currentValue > _condition.value;
            } else if (_condition.comparisonType == ComparisonType.LessThan) {
                return currentValue < _condition.value;
            } else if (_condition.comparisonType == ComparisonType.EqualTo) {
                return currentValue == _condition.value;
            }
        } else if (_condition.conditionType == ConditionType.InternalFlag) {
             // For InternalFlag, value is ignored, we check the boolean flag
            return internalFlags[_condition.key] == (_condition.value != 0); // Assuming value=1 means true, value=0 means false
        } else if (_condition.conditionType == ConditionType.MinGovernanceVotes) {
            // Check yay votes on a specific proposal
            Proposal storage targetProposal = proposals[_condition.proposalId];
             if (_condition.comparisonType == ComparisonType.GreaterThan) {
                 return targetProposal.yayVotes > _condition.value;
             } else if (_condition.comparisonType == ComparisonType.LessThan) {
                 return targetProposal.yayVotes < _condition.value;
             } else if (_condition.comparisonType == ComparisonType.EqualTo) {
                 return targetProposal.yayVotes == _condition.value;
             }
        }
        // Default to false if condition type or comparison type is unrecognized/invalid
        return false;
    }

    /// @dev Internal function to add a new outcome. Called by executeProposal.
    /// @param _outcome The new outcome configuration.
    function addOutcome(ReleaseOutcome calldata _outcome) internal {
        uint256 outcomeId = nextOutcomeId++;
        outcomes[outcomeId] = _outcome; // Copy data including conditions
        outcomes[outcomeId].id = outcomeId; // Set the correct ID

        // Insert into activeOutcomeIds array based on priority (maintaining sorted order)
        bool inserted = false;
        for (uint i = 0; i < activeOutcomeIds.length; i++) {
            if (outcomes[activeOutcomeIds[i]].priority > _outcome.priority) {
                // Insert before this element
                activeOutcomeIds.push(0); // Expand array
                for (uint j = activeOutcomeIds.length - 1; j > i; j--) {
                    activeOutcomeIds[j] = activeOutcomeIds[j - 1];
                }
                activeOutcomeIds[i] = outcomeId;
                inserted = true;
                break;
            }
        }
        if (!inserted) {
            // Add to the end if it has the lowest priority or array is empty
            activeOutcomeIds.push(outcomeId);
        }

        emit OutcomeAdded(outcomeId, msg.sender); // msg.sender here is the contract itself, effectively triggered by governance
    }

    /// @dev Internal function to update an existing outcome. Called by executeProposal.
    /// @param _outcomeId The ID of the outcome to update.
    /// @param _newOutcomeConfig The new configuration for the outcome.
    function updateOutcome(uint256 _outcomeId, ReleaseOutcome calldata _newOutcomeConfig) internal {
        require(outcomes[_outcomeId].id != 0, "Outcome does not exist");
        ReleaseOutcome storage oldOutcome = outcomes[_outcomeId];

        bool priorityChanged = (oldOutcome.priority != _newOutcomeConfig.priority);
        bool isActiveChanged = (oldOutcome.isActive != _newOutcomeConfig.isActive);

        // Update fields (copy data)
        oldOutcome.recipient = _newOutcomeConfig.recipient;
        oldOutcome.value = _newOutcomeConfig.value;
        oldOutcome.isActive = _newOutcomeConfig.isActive;
        oldOutcome.priority = _newOutcomeConfig.priority;
         // Replace conditions array (deep copy)
        oldOutcome.conditions = new Condition[](_newOutcomeConfig.conditions.length);
        for (uint i = 0; i < _newOutcomeConfig.conditions.length; i++) {
            oldOutcome.conditions[i] = _newOutcomeConfig.conditions[i];
        }

        // If priority or active status changed, rebuild or re-sort activeOutcomeIds
        if (priorityChanged || isActiveChanged) {
             // Simplest way is to rebuild the array, could optimize later
             uint256[] memory tempActiveIds = new uint256[](activeOutcomeIds.length);
             uint k = 0;
             for(uint i = 0; i < activeOutcomeIds.length; i++) {
                 if(activeOutcomeIds[i] != _outcomeId) {
                     tempActiveIds[k++] = activeOutcomeIds[i];
                 }
             }
             // Resize if outcome was active and is now removed, or vice-versa
             if (oldOutcome.isActive && !isActiveChanged) { // Was active, remains active (just copy)
                 activeOutcomeIds = new uint256[](k);
                 for(uint i = 0; i < k; i++) activeOutcomeIds[i] = tempActiveIds[i];
             } else if (!oldOutcome.isActive && isActiveChanged) { // Was inactive, is now active
                  // tempActiveIds has old active ones + the updated one implicitly, needs re-insert
                  activeOutcomeIds = new uint256[](k);
                  for(uint i = 0; i < k; i++) activeOutcomeIds[i] = tempActiveIds[i]; // Copy old active ones
                  addOutcome(oldOutcome); // Re-insert the updated one into the sorted list
             } else if (oldOutcome.isActive && !isActiveChanged) { // Priority changed but still active
                 activeOutcomeIds = new uint256[](k);
                 for(uint i = 0; i < k; i++) activeOutcomeIds[i] = tempActiveIds[i]; // Copy old active ones
                 addOutcome(oldOutcome); // Re-insert with new priority
             }
             // If was inactive and remains inactive, no change to active list needed
        }

        emit OutcomeUpdated(_outcomeId, msg.sender); // msg.sender is contract
    }

    /// @dev Internal function to remove (deactivate) an outcome. Called by executeProposal.
    /// @param _outcomeId The ID of the outcome to remove.
    function removeOutcome(uint256 _outcomeId) internal {
        require(outcomes[_outcomeId].id != 0, "Outcome does not exist");
        require(outcomes[_outcomeId].isActive, "Outcome is already inactive");

        outcomes[_outcomeId].isActive = false;

        // Remove from activeOutcomeIds array
        uint256[] memory tempActiveIds = new uint256[](activeOutcomeIds.length - 1);
        uint k = 0;
        for (uint i = 0; i < activeOutcomeIds.length; i++) {
            if (activeOutcomeIds[i] != _outcomeId) {
                tempActiveIds[k++] = activeOutcomeIds[i];
            }
        }
        activeOutcomeIds = tempActiveIds; // Replace array with the new one

        emit OutcomeRemoved(_outcomeId, msg.sender); // msg.sender is contract
    }

    /// @dev Internal function to set a simulated external oracle value. Called by executeProposal.
    /// @param _key The key for the oracle value.
    /// @param _value The value to set.
    function setExternalOracleValue(bytes32 _key, uint256 _value) internal {
        externalOracleValues[_key] = _value;
        emit ExternalOracleValueSet(_key, _value);
    }

    /// @dev Internal function to set an internal boolean flag. Called by executeProposal.
    /// @param _key The key for the flag.
    /// @param _value The value (true/false) to set.
    function setInternalFlag(bytes32 _key, bool _value) internal {
        internalFlags[_key] = _value;
        emit InternalFlagSet(_key, _value);
    }

    /// @dev Internal function to set the proposal timelock. Called by executeProposal.
    /// @param _timelock The new timelock duration in seconds.
    function setProposalTimelock(uint256 _timelock) internal {
        uint256 oldTimelock = proposalTimelock;
        proposalTimelock = _timelock;
        emit TimelockUpdated(oldTimelock, _timelock);
    }

    /// @dev Internal function to set the execution buffer. Called by executeProposal.
    /// @param _buffer The new execution buffer duration in seconds.
    function setExecutionBuffer(uint256 _buffer) internal {
        uint256 oldBuffer = executionBuffer;
        executionBuffer = _buffer;
        emit ExecutionBufferUpdated(oldBuffer, _buffer);
    }


    // --- View Functions ---

    /// @notice Retrieves details of a specific outcome.
    /// @param _outcomeId The ID of the outcome.
    /// @return The ReleaseOutcome struct details.
    function getOutcomeDetails(uint256 _outcomeId) public view returns (ReleaseOutcome memory) {
        require(outcomes[_outcomeId].id != 0 || nextOutcomeId == 0, "Outcome does not exist");
        return outcomes[_outcomeId];
    }

    /// @notice Retrieves details of a specific proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return The Proposal struct details.
    function getProposalDetails(uint256 _proposalId) public view returns (Proposal memory) {
        require(_proposalId < nextProposalId, "Proposal does not exist");
        Proposal storage p = proposals[_proposalId];
        ProposalState currentState = checkProposalState(_proposalId); // Get latest state
        // Return a memory copy with the updated state
        return Proposal({
            id: p.id,
            proposalType: p.proposalType,
            proposer: p.proposer,
            voteStart: p.voteStart,
            voteEnd: p.voteEnd,
            quorum: p.quorum,
            yayVotes: p.yayVotes,
            nayVotes: p.nayVotes,
            state: currentState, // Return the dynamic state
            queuedForExecution: p.queuedForExecution,
            targetOutcomeId: p.targetOutcomeId,
            newOutcomeConfig: p.newOutcomeConfig, // This copies the struct content
            oracleKey: p.oracleKey,
            oracleValue: p.oracleValue,
            flagKey: p.flagKey,
            flagValue: p.flagValue
        });
    }


    /// @notice Gets the list of active outcome IDs, ordered by priority.
    /// @return An array of active outcome IDs.
    function getActiveOutcomeIds() public view returns (uint256[] memory) {
        return activeOutcomeIds;
    }

    /// @notice Gets the value of a specific internal boolean flag.
    /// @param _key The key of the flag.
    /// @return The boolean value of the flag.
    function getInternalFlag(bytes32 _key) public view returns (bool) {
        return internalFlags[_key];
    }

    /// @notice Gets the value of a simulated external oracle feed.
    /// @param _key The key of the oracle feed.
    /// @return The uint256 value of the feed.
    function getExternalOracleValue(bytes32 _key) public view returns (uint256) {
        return externalOracleValues[_key];
    }
}
```