Okay, let's design a smart contract that goes beyond typical patterns like simple ERC20/721, basic staking, or standard timelock DAOs. We'll create a complex governance contract that incorporates concepts like:

1.  **Dynamic Voting Power:** Not just based on token balance, but potentially including a time-weighted factor or a reputation score derived from participation.
2.  **Conditional Delegation:** Users can delegate their voting power with specific constraints (e.g., only for certain proposal types, or within a certain timeframe).
3.  **Protocol State Machine:** The contract governs a hypothetical protocol that exists in different "states," and transitions between these states require specific governance proposals. Different states might unlock/lock certain functionalities or change parameters.
4.  **Conditional Execution Proposals:** Proposals whose execution is contingent on an external condition being met (e.g., an oracle value, a specific block number, another on-chain event).
5.  **Reputation System:** A basic on-chain reputation score based on successful vote participation and potentially delegation history.

Let's call this contract `QuantumMeshGovernor`, assuming it governs a hypothetical "QuantumMesh" protocol.

---

### **Contract Outline: QuantumMeshGovernor**

*   **Purpose:** A sophisticated governance contract for the hypothetical QuantumMesh protocol. It manages protocol parameters, facilitates state transitions, enables complex delegation, and incorporates dynamic voting power based on stake and reputation.
*   **Core Concepts:**
    *   Token-based voting with dynamic power calculation.
    *   Flexible delegation (standard and conditional).
    *   On-chain reputation system linked to voting/delegation.
    *   Protocol State Machine governed by proposals.
    *   Proposals for parameter changes, function calls, state transitions, and conditional execution.
    *   Standard governance lifecycle (propose, vote, queue, execute, cancel).
    *   Gasless voting and delegation using signatures.

---

### **Function Summary:**

**Governance Actions (Proposal Lifecycle):**

1.  `proposeParameterChange`: Create a proposal to modify a governed parameter.
2.  `proposeFunctionCall`: Create a proposal to call a specific function on a target contract.
3.  `proposeStateTransition`: Create a proposal to transition the protocol to a new state.
4.  `proposeConditionalExecution`: Create a proposal that only executes if a specified condition is met.
5.  `castVote`: Cast a vote (Yay/Nay/Abstain) on an active proposal.
6.  `castVoteWithReason`: Cast a vote with an accompanying string reason.
7.  `castVoteBySignature`: Cast a vote using an EIP-712 signature (gasless voting).
8.  `queueProposal`: Move a successful proposal to the timelock queue.
9.  `executeProposal`: Execute a proposal from the timelock queue.
10. `cancelProposal`: Cancel an active or queued proposal (under certain conditions).
11. `renounceProposal`: Proposer cancels their own proposal.
12. `triggerConditionalExecution`: Attempt to execute a conditional proposal if its condition is met.

**Delegation Management:**

13. `delegate`: Delegate voting power to another address.
14. `delegateBySignature`: Delegate voting power using an EIP-712 signature (gasless delegation).
15. `undelegate`: Remove current delegation.
16. `delegateWithConditions`: Delegate voting power with specific constraints (e.g., proposal type, minimum quorum).

**Query Functions:**

17. `getVotingPower`: Get the current calculated voting power for an address.
18. `getVotingPowerAtBlock`: Get the calculated voting power for an address at a specific block number (for proposal snapshots).
19. `getReputation`: Get the current reputation score for an address.
20. `getDelegatee`: Get the address an account has delegated to.
21. `getDelegators`: Get the list of addresses that have delegated *to* a specific address. (Note: May be inefficient or limited).
22. `getProposalState`: Get the current state of a proposal.
23. `getProposalDetails`: Get all details for a specific proposal.
24. `getCurrentProtocolState`: Get the current global state of the QuantumMesh protocol.
25. `getGovernanceParameter`: Get the value of a specific governed parameter.
26. `checkConditionalExecutionStatus`: Check if the condition for a conditional proposal is currently met.

**Internal/Helper Functions (Not direct external calls, but essential):**

*   `_calculateVotingPowerAtBlock`: Calculates dynamic voting power incorporating stake, delegation, and potentially time/reputation factors at a specific block.
*   `_updateReputation`: Internal logic to adjust reputation scores based on governance participation outcomes.
*   `_executeProposal`: Internal function handling the execution logic for different proposal types.
*   `_stateTransitionAllowed`: Internal check if a requested state transition is valid from the current state.

*(Self-correction: While internal functions count towards complexity, the request asks for "functions" generally. Listing callable ones is more user-friendly for understanding the interface. We have 26 callable functions, comfortably over 20.)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControl.sol"; // Using roles for core governor actions

// --- Contract Outline: QuantumMeshGovernor ---
// Purpose: A sophisticated governance contract for the hypothetical QuantumMesh protocol.
// It manages protocol parameters, facilitates state transitions, enables complex delegation,
// and incorporates dynamic voting power based on stake and reputation.
// Core Concepts:
// - Token-based voting with dynamic power calculation.
// - Flexible delegation (standard and conditional).
// - On-chain reputation system linked to voting/delegation.
// - Protocol State Machine governed by proposals.
// - Proposals for parameter changes, function calls, state transitions, and conditional execution.
// - Standard governance lifecycle (propose, vote, queue, execute, cancel).
// - Gasless voting and delegation using signatures.

// --- Function Summary ---
// Governance Actions (Proposal Lifecycle):
// 1. proposeParameterChange: Create a proposal to modify a governed parameter.
// 2. proposeFunctionCall: Create a proposal to call a specific function on a target contract.
// 3. proposeStateTransition: Create a proposal to transition the protocol to a new state.
// 4. proposeConditionalExecution: Create a proposal that only executes if a specified condition is met.
// 5. castVote: Cast a vote (Yay/Nay/Abstain) on an active proposal.
// 6. castVoteWithReason: Cast a vote with an accompanying string reason.
// 7. castVoteBySignature: Cast a vote using an EIP-712 signature (gasless voting).
// 8. queueProposal: Move a successful proposal to the timelock queue.
// 9. executeProposal: Execute a proposal from the timelock queue.
// 10. cancelProposal: Cancel an active or queued proposal (under certain conditions).
// 11. renounceProposal: Proposer cancels their own proposal.
// 12. triggerConditionalExecution: Attempt to execute a conditional proposal if its condition is met.

// Delegation Management:
// 13. delegate: Delegate voting power to another address.
// 14. delegateBySignature: Delegate voting power using an EIP-712 signature (gasless delegation).
// 15. undelegate: Remove current delegation.
// 16. delegateWithConditions: Delegate voting power with specific constraints (e.g., proposal type, minimum quorum).

// Query Functions:
// 17. getVotingPower: Get the current calculated voting power for an address.
// 18. getVotingPowerAtBlock: Get the calculated voting power for an address at a specific block number (for proposal snapshots).
// 19. getReputation: Get the current reputation score for an address.
// 20. getDelegatee: Get the address an account has delegated to.
// 21. getDelegators: Get the list of addresses that have delegated *to* a specific address. (Note: May be inefficient or limited).
// 22. getProposalState: Get the current state of a proposal.
// 23. getProposalDetails: Get all details for a specific proposal.
// 24. getCurrentProtocolState: Get the current global state of the QuantumMesh protocol.
// 25. getGovernanceParameter: Get the value of a specific governed parameter.
// 26. checkConditionalExecutionStatus: Check if the condition for a conditional proposal is currently met.

// Internal/Helper functions are also present but not listed in the external summary.

contract QuantumMeshGovernor is AccessControl {
    using SafeMath for uint256;
    using Address for address;
    using ECDSA for bytes32;
    using SignatureChecker for address;

    // --- Constants & Roles ---
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR"); // Can execute proposals from queue
    bytes32 public constant PARAM_EDITOR_ROLE = keccak256("PARAM_EDITOR"); // Could bypass proposal for urgent params (optional)

    // --- State Variables ---
    IERC20 public immutable quantumToken; // The token used for voting power
    uint256 public constant REPUTATION_UNIT = 1e18; // Unit for reputation score (like WEI for Ether)

    // Governable Parameters (can be changed via proposals)
    mapping(bytes32 => uint256) private governedParameters;
    bytes32 public constant KEY_PROPOSAL_THRESHOLD = keccak256("proposalThreshold"); // Min voting power to create proposal
    bytes32 public constant KEY_VOTING_PERIOD = keccak256("votingPeriod"); // Blocks duration for voting
    bytes32 public constant KEY_TIMELOCK_DELAY = keccak256("timelockDelay"); // Blocks/Time delay before execution
    bytes32 public constant KEY_QUORUM_THRESHOLD_BPS = keccak256("quorumThresholdBps"); // Quorum as basis points (e.g., 400 = 4%)
    bytes32 public constant KEY_REPUTATION_FACTOR_BPS = keccak256("reputationFactorBps"); // How much reputation affects voting power (basis points)
    bytes32 public constant KEY_MIN_STAKE_REPUTATION = keccak256("minStakeReputation"); // Min stake required for reputation consideration

    // Protocol State Machine
    enum ProtocolState { Initial, Activated, Paused, UpgradePending, Shutdown }
    ProtocolState public currentProtocolState = ProtocolState.Initial;

    // Proposal Management
    enum ProposalState { Pending, Active, Canceled, Defeated, Succeeded, Queued, Expired, Executed, Vetoed, ConditionPending, ConditionMet } // Added Condition states
    enum VoteType { Abstain, Nay, Yay }
    enum ProposalType { ParameterChange, FunctionCall, StateTransition, ConditionalExecution }
    enum DelegationType { Standard, Conditional }

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        ProposalType proposalType;
        address[] targets;
        uint256[] values;
        bytes[] calldatas;
        bytes32[] parameterKeys; // For ParameterChange type
        uint256[] parameterValues; // For ParameterChange type
        ProtocolState newState; // For StateTransition type

        // Conditional Execution specific
        address conditionContract;
        bytes conditionCalldata;
        bool conditionMet; // Track if condition was met

        uint256 creationBlock; // Block when proposal was created (snapshot for voting power)
        uint256 expirationBlock; // Block when voting ends
        uint256 eta; // Earliest timestamp or block number for execution (depends on timelock)

        uint256 yayVotes;
        uint256 nayVotes;
        uint256 abstainVotes;
        uint256 totalVotesCast; // Sum of yay, nay, abstain at snapshot block

        ProposalState state;
        bool executed;
        bool cancelled;
        bool vetoed; // Placeholder for potential veto mechanism
    }

    struct Voter {
        uint256 stakedAmount; // Token balance staked
        address delegatee; // Address this user has delegated to (address(0) if self-delegating)
        DelegationType delegationType; // Standard or Conditional
        // Mapping of proposal type => bool/params for conditional delegation (simplified for example)
        mapping(ProposalType => bool) conditionalDelegationAllowed;
        uint256 reputation; // Reputation score (scaled by REPUTATION_UNIT)
        uint256 lastReputationUpdateBlock; // Block of last reputation calculation/update
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId = 1;

    mapping(address => Voter) public voters;
    mapping(uint256 => mapping(address => bool)) public hasVoted; // proposalId => voter => bool

    // Simple delegation map for easy lookup (delegatee). Voter struct has delegatee too.
    // This map provides a direct lookup from delegator to delegatee.
    mapping(address => address) public delegateeLookup;
    // Mapping to track who is delegating to a specific address (less efficient to query all delegators)
    mapping(address => address[]) private delegatorsLookup; // delegatee => list of delegators
    // Note: delegatorsLookup can become very large. For real dApps, tracing events is often preferred.

    // --- Events ---
    event ProposalCreated(uint256 indexed id, address indexed proposer, address[] targets, uint256[] values, bytes[] calldatas, bytes32[] parameterKeys, uint256[] parameterValues, ProtocolState newState, address indexed conditionContract, bytes conditionCalldata, string description, ProposalType proposalType, uint256 creationBlock, uint256 expirationBlock);
    event VoteCast(address indexed voter, uint256 indexed proposalId, VoteType voteType, uint256 votingPower, string reason);
    event ProposalQueued(uint256 indexed id, uint256 eta);
    event ProposalExecuted(uint256 indexed id);
    event ProposalCanceled(uint256 indexed id);
    event ProposalRenounced(uint256 indexed id);
    event ProposalStateTransitioned(uint256 indexed id, ProtocolState indexed oldState, ProtocolState indexed newState);
    event ConditionalExecutionTriggered(uint256 indexed id, bool conditionMet);

    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance); // Tracks delegate's total voting power
    event ReputationUpdated(address indexed voter, uint256 oldReputation, uint256 newReputation);

    event GovernedParameterChanged(bytes32 indexed key, uint256 oldValue, uint256 newValue);
    event ProtocolStateChanged(ProtocolState indexed oldState, ProtocolState indexed newState);

    // --- Modifiers ---
    modifier whenState(ProposalState _state) {
        require(proposals[msg.sender].state == _state, "Governor: Invalid proposal state"); // Should check proposal state by ID, not msg.sender
        _;
    }
     modifier whenProposalState(uint256 proposalId, ProposalState _state) {
        require(proposals[proposalId].state == _state, "Governor: Invalid proposal state for action");
        _;
    }

    modifier unlessProposalState(uint256 proposalId, ProposalState _state) {
        require(proposals[proposalId].state != _state, "Governor: Cannot perform action in this proposal state");
        _;
    }

    modifier onlyProposer(uint256 proposalId) {
        require(proposals[proposalId].proposer == msg.sender, "Governor: Only proposer can perform this action");
        _;
    }

     modifier onlyGovernorRole() {
        require(hasRole(GOVERNOR_ROLE, msg.sender), "Governor: Must have Governor role");
        _;
    }

    // --- Constructor ---
    constructor(IERC20 _quantumToken, uint256 initialProposalThreshold, uint256 initialVotingPeriod, uint256 initialTimelockDelay, uint256 initialQuorumThresholdBps, uint256 initialReputationFactorBps, uint256 initialMinStakeReputation) {
        quantumToken = _quantumToken;

        // Set initial governed parameters
        governedParameters[KEY_PROPOSAL_THRESHOLD] = initialProposalThreshold;
        governedParameters[KEY_VOTING_PERIOD] = initialVotingPeriod;
        governedParameters[KEY_TIMELOCK_DELAY] = initialTimelockDelay; // Use blocks or time? Let's use blocks for simplicity aligned with votingPeriod
        governedParameters[KEY_QUORUM_THRESHOLD_BPS] = initialQuorumThresholdBps; // e.g., 400 for 4%
        governedParameters[KEY_REPUTATION_FACTOR_BPS] = initialReputationFactorBps; // e.g., 100 for 1% reputation impact
        governedParameters[KEY_MIN_STAKE_REPUTATION] = initialMinStakeReputation; // Min staked amount to consider reputation

        // Grant the deployer the Governor role initially
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(GOVERNOR_ROLE, msg.sender); // The contract itself might have this role for execution, or a separate Timelock contract.
                                              // For this example, let's assume a trusted entity (like a multi-sig) holds this role to trigger execution.
                                              // A more robust system would use a separate Timelock contract controlled by the Governor.
    }

    // --- Staking (Basic - prerequisite for voting power) ---
    // Note: In a real system, staking might be more complex with reward mechanics.
    // Here, it's just about holding tokens *known* to the governor for power calculation.
    // We assume tokens are approved *before* calling stake.
    function stake(uint256 amount) external {
        require(amount > 0, "Governor: Must stake positive amount");
        quantumToken.transferFrom(msg.sender, address(this), amount);
        voters[msg.sender].stakedAmount = voters[msg.sender].stakedAmount.add(amount);

        // If self-delegating (or not delegated), update delegatee's vote count
        address delegatee = delegateeLookup[msg.sender] == address(0) ? msg.sender : delegateeLookup[msg.sender];
        uint256 currentPower = _calculateVotingPowerAtBlock(delegatee, block.number); // Approximate
        // We need to track total delegated power *to* an address.
        // This requires updating delegatee's total power when stake/unstake/delegate occurs.
        // Let's add totalDelegatedVotes mapping.
        _moveDelegatedVotes(address(0), delegatee, amount); // Add stake to self or delegatee's power
    }

    function unstake(uint256 amount) external {
        require(amount > 0, "Governor: Must unstake positive amount");
        Voter storage voter = voters[msg.sender];
        require(voter.stakedAmount >= amount, "Governor: Insufficient staked amount");

        // Timelock for unstaking (example: based on a parameter or fixed value)
        // For simplicity in this example, we omit a specific unstake timelock.
        // In a real system, you'd likely require a delay similar to proposal timelocks.

        voter.stakedAmount = voter.stakedAmount.sub(amount);
        quantumToken.transfer(msg.sender, amount);

        // If self-delegating (or not delegated), update delegatee's vote count
        address delegatee = delegateeLookup[msg.sender] == address(0) ? msg.sender : delegateeLookup[msg.sender];
        _moveDelegatedVotes(delegatee, address(0), amount); // Remove stake from self or delegatee's power
    }

    // --- Delegation ---
    mapping(address => uint256) public totalDelegatedVotes; // delegatee => total voting power delegated to them

    function _moveDelegatedVotes(address from, address to, uint256 amount) internal {
        if (from != address(0)) {
            totalDelegatedVotes[from] = totalDelegatedVotes[from].sub(amount);
             emit DelegateVotesChanged(from, totalDelegatedVotes[from].add(amount), totalDelegatedVotes[from]);
        }
        if (to != address(0)) {
            totalDelegatedVotes[to] = totalDelegatedVotes[to].add(amount);
            emit DelegateVotesChanged(to, totalDelegatedVotes[to].sub(amount), totalDelegatedVotes[to]);
        }
    }

    function delegate(address delegatee) external {
        address currentDelegatee = delegateeLookup[msg.sender];
        if (currentDelegatee != delegatee) {
            Voter storage voter = voters[msg.sender];
            uint256 votingPower = _calculateVotingPowerAtBlock(msg.sender, block.number); // Use current power for simplicity, snapshotting is complex on delegation changes

            delegateeLookup[msg.sender] = delegatee;
            voter.delegatee = delegatee;
            voter.delegationType = DelegationType.Standard;
            // Reset conditional delegation constraints on standard delegation
             delete voter.conditionalDelegationAllowed; // Clear all entries

            _moveDelegatedVotes(currentDelegatee == address(0) ? msg.sender : currentDelegatee, delegatee == address(0) ? msg.sender : delegatee, votingPower);
            emit DelegateChanged(msg.sender, currentDelegatee, delegatee);
        }
    }

    // Gasless delegation (EIP-712)
    // Note: Needs domain separator and signing logic off-chain.
    // domainSeparator is keccak256(abi.encode(EIP712_DOMAIN_TYPEHASH, name, version, chainId, address));
    // EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    // DELEGATION_TYPEHASH = keccak256("Delegate(address delegatee,uint256 nonce,uint256 expiry)");
    function delegateBySignature(address delegatee, uint256 nonce, uint256 expiry, bytes memory signature) external {
        bytes32 structHash = keccak256(abi.encode(
            keccak256("Delegate(address delegatee,uint256 nonce,uint256 expiry)"),
            delegatee,
            nonce,
            expiry
        ));

        bytes32 domainSeparator = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256("QuantumMeshGovernor"), // Contract Name
            keccak256("1"), // Version
            block.chainid,
            address(this)
        ));

        bytes32 digest = domainSeparator.hashWithPrefix(structHash);
        address signer = digest.recover(signature);
        require(signer != address(0), "Governor: Invalid signature");
        require(nonce == voters[signer].lastReputationUpdateBlock, "Governor: Invalid nonce"); // Using lastReputationUpdateBlock as nonce (simple example)
        require(expiry >= block.timestamp, "Governor: Signature expired");

        delegate(signer, delegatee); // Call internal delegate function with signer as delegator
    }

     // Internal delegate function used by both standard and signature methods
    function delegate(address delegator, address delegatee) internal {
        address currentDelegatee = delegateeLookup[delegator];
        if (currentDelegatee != delegatee) {
            Voter storage voter = voters[delegator];
            uint256 votingPower = _calculateVotingPowerAtBlock(delegator, block.number);

            delegateeLookup[delegator] = delegatee;
            voter.delegatee = delegatee;
            voter.delegationType = DelegationType.Standard;
            delete voter.conditionalDelegationAllowed;

            _moveDelegatedVotes(currentDelegatee == address(0) ? delegator : currentDelegatee, delegatee == address(0) ? delegator : delegatee, votingPower);

            // Manage delegatorsLookup (add delegator to the new delegatee's list)
            if (currentDelegatee != address(0)) {
                 // Remove from old delegatee's list (expensive, simplified here)
                 address[] storage oldDelegators = delegatorsLookup[currentDelegatee];
                 for (uint i = 0; i < oldDelegators.length; i++) {
                     if (oldDelegators[i] == delegator) {
                         oldDelegators[i] = oldDelegators[oldDelegators.length - 1];
                         oldDelegators.pop();
                         break;
                     }
                 }
            }
            if (delegatee != address(0)) {
                delegatorsLookup[delegatee].push(delegator);
            }

            emit DelegateChanged(delegator, currentDelegatee, delegatee);
        }
    }


    function undelegate() external {
        delegate(msg.sender, address(0)); // Delegate to self (address(0) convention for self-delegation)
    }

    // Conditional Delegation
    function delegateWithConditions(address delegatee, ProposalType[] memory allowedTypes) external {
         address currentDelegatee = delegateeLookup[msg.sender];
        if (currentDelegatee != delegatee || voters[msg.sender].delegationType != DelegationType.Conditional) {
            Voter storage voter = voters[msg.sender];
            uint256 votingPower = _calculateVotingPowerAtBlock(msg.sender, block.number);

            delegateeLookup[msg.sender] = delegatee;
            voter.delegatee = delegatee;
            voter.delegationType = DelegationType.Conditional;

            // Set specific allowed proposal types
            delete voter.conditionalDelegationAllowed; // Clear previous conditions
            for(uint i = 0; i < allowedTypes.length; i++) {
                voter.conditionalDelegationAllowed[allowedTypes[i]] = true;
            }

            _moveDelegatedVotes(currentDelegatee == address(0) ? msg.sender : currentDelegatee, delegatee == address(0) ? msg.sender : delegatee, votingPower);

            // Manage delegatorsLookup (similar to standard delegate)
             if (currentDelegatee != address(0)) {
                 address[] storage oldDelegators = delegatorsLookup[currentDelegatee];
                 for (uint i = 0; i < oldDelegators.length; i++) {
                     if (oldDelegators[i] == msg.sender) {
                         oldDelegators[i] = oldDelegators[oldDelegators.length - 1];
                         oldDelegators.pop();
                         break;
                     }
                 }
            }
            if (delegatee != address(0)) {
                delegatorsLookup[delegatee].push(msg.sender);
            }

            emit DelegateChanged(msg.sender, currentDelegatee, delegatee); // Could add event params for conditions
        }
    }


    // --- Voting Power & Reputation ---

    // Calculates voting power considering stake, delegation, and reputation at a specific block
    function _calculateVotingPowerAtBlock(address account, uint256 blockNumber) internal view returns (uint256) {
        // Note: Snapshotting token balances at past blocks requires integration with the ERC20 token itself
        // if it supports checkpoints (like OpenZeppelin ERC20Votes). For simplicity, we'll use
        // the *current* staked balance from our `voters` struct, but this is NOT truly snapshotting
        // balance changes correctly. A real system needs to handle balance snapshots.
        uint256 stakePower = voters[account].stakedAmount;

        // For a delegatee, sum up all delegated votes (this needs proper snapshotting of delegations too)
        // For simplicity, totalDelegatedVotes is updated on delegate/unstake/stake, which is a form of snapshotting at change time.
        uint256 delegatedPower = totalDelegatedVotes[account];

        uint256 totalPower = stakePower.add(delegatedPower);

        // Apply reputation bonus (simplified: percentage bonus based on reputation score)
        uint256 reputation = voters[account].reputation;
        uint256 minStakeForReputation = governedParameters[KEY_MIN_STAKE_REPUTATION];

        // Only apply reputation bonus if stake is above minimum and reputation is positive
        if (stakePower >= minStakeForReputation && reputation > 0) {
             uint256 reputationFactorBps = governedParameters[KEY_REPUTATION_FACTOR_BPS];
             // Bonus = (totalPower * reputation * reputationFactorBps) / (REPUTATION_UNIT * 10000)
             uint256 reputationBonus = totalPower.mul(reputation).div(REPUTATION_UNIT).mul(reputationFactorBps).div(10000);
             totalPower = totalPower.add(reputationBonus);
        }

        // A more robust system would use block numbers for stake and delegation state.
        // This function as implemented is a simplified demonstration.
        return totalPower;
    }

    function getVotingPower(address account) public view returns (uint256) {
        // Returns power at the current block for live checks
        return _calculateVotingPowerAtBlock(account, block.number);
    }

    function getVotingPowerAtBlock(address account, uint256 blockNumber) public view returns (uint256) {
         // Returns power at a specific block (relies on the limitations mentioned in _calculateVotingPowerAtBlock)
         return _calculateVotingPowerAtBlock(account, blockNumber);
    }


    function getReputation(address account) public view returns (uint256) {
        return voters[account].reputation;
    }

    // Internal function to update reputation (example: triggered by vote cast or execution)
    function _updateReputation(address voterAddress, bool successfulParticipation, uint256 participationWeight) internal {
        Voter storage voter = voters[voterAddress];
        uint256 oldRep = voter.reputation;
        uint256 newRep = oldRep;

        // Simple linear update logic: +1 for successful participation, -0.5 for unsuccessful
        // (Scaled by REPUTATION_UNIT and participation weight, e.g., voting power)
        if (successfulParticipation) {
            // Increase reputation based on weight (e.g., power * factor)
            uint256 increase = participationWeight.mul(1e18).div(quantumToken.totalSupply()).div(100); // Example scaling
             newRep = newRep.add(increase);
        } else {
             uint256 decrease = participationWeight.mul(1e18).div(quantumToken.totalSupply()).div(200); // Example scaling
             newRep = newRep >= decrease ? newRep.sub(decrease) : 0;
        }

        voter.reputation = newRep;
        voter.lastReputationUpdateBlock = block.number; // Use this as nonce for signatures
        if (oldRep != newRep) {
            emit ReputationUpdated(voterAddress, oldRep, newRep);
        }
    }

    // --- Delegation Queries ---

    function getDelegatee(address delegator) public view returns (address) {
        // address(0) indicates no delegation or self-delegation in this lookup
        return delegateeLookup[delegator];
    }

     // This function can be expensive for large delegatees.
     // In practice, iterating through `delegatorsLookup` might hit gas limits.
     // A more scalable approach is to rely on event logs to reconstruct the list off-chain.
    function getDelegators(address delegatee) public view returns (address[] memory) {
        return delegatorsLookup[delegatee];
    }


    // --- Proposal Creation ---

    function proposeParameterChange(
        bytes32[] memory parameterKeys,
        uint256[] memory parameterValues,
        string memory description
    ) external returns (uint256) {
        require(parameterKeys.length == parameterValues.length, "Governor: Mismatched parameter key/value counts");
        require(parameterKeys.length > 0, "Governor: No parameters specified");

        uint256 proposalThreshold = governedParameters[KEY_PROPOSAL_THRESHOLD];
        require(getVotingPower(msg.sender) >= proposalThreshold, "Governor: Insufficient voting power to propose");
        require(bytes(description).length > 0, "Governor: Description cannot be empty");

        uint256 proposalId = nextProposalId++;
        uint256 creationBlock = block.number;
        uint256 votingPeriod = governedParameters[KEY_VOTING_PERIOD];
        uint256 expirationBlock = creationBlock.add(votingPeriod);

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: description,
            proposalType: ProposalType.ParameterChange,
            targets: new address[](0), // Not applicable
            values: new uint256[](0), // Not applicable
            calldatas: new bytes[](0), // Not applicable
            parameterKeys: parameterKeys,
            parameterValues: parameterValues,
            newState: currentProtocolState, // Not applicable
            conditionContract: address(0), // Not applicable
            conditionCalldata: "", // Not applicable
            conditionMet: false, // Not applicable
            creationBlock: creationBlock,
            expirationBlock: expirationBlock,
            eta: 0, // Not set yet
            yayVotes: 0,
            nayVotes: 0,
            abstainVotes: 0,
            totalVotesCast: 0, // Will be set during first vote or on expiration for quorum calculation
            state: ProposalState.Pending,
            executed: false,
            cancelled: false,
            vetoed: false
        });

        emit ProposalCreated(proposalId, msg.sender, new address[](0), new uint256[](0), new bytes[](0), parameterKeys, parameterValues, currentProtocolState, address(0), "", description, ProposalType.ParameterChange, creationBlock, expirationBlock);

        // Transition to Active state immediately upon creation if voting period starts now
        // Or keep in Pending until someone calls `activateProposal` or first vote?
        // Let's make voting start immediately.
        proposals[proposalId].state = ProposalState.Active;
        // Snapshot total possible voting power here for quorum calculation
        // Requires iterating through all voters/delegates which is expensive.
        // A better way is to use a token that checkpoints total supply or delegated power.
        // For simplicity, we'll calculate total power for quorum *when queuing* based on block.number.
        // A real system needs a snapshot mechanism.
        return proposalId;
    }


    function proposeFunctionCall(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) external returns (uint256) {
        require(targets.length == values.length && targets.length == calldatas.length, "Governor: Mismatched call data counts");
        require(targets.length > 0, "Governor: No calls specified");

        uint256 proposalThreshold = governedParameters[KEY_PROPOSAL_THRESHOLD];
        require(getVotingPower(msg.sender) >= proposalThreshold, "Governor: Insufficient voting power to propose");
         require(bytes(description).length > 0, "Governor: Description cannot be empty");

        uint256 proposalId = nextProposalId++;
        uint256 creationBlock = block.number;
        uint256 votingPeriod = governedParameters[KEY_VOTING_PERIOD];
        uint256 expirationBlock = creationBlock.add(votingPeriod);

         proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: description,
            proposalType: ProposalType.FunctionCall,
            targets: targets,
            values: values,
            calldatas: calldatas,
            parameterKeys: new bytes32[](0),
            parameterValues: new uint256[](0),
            newState: currentProtocolState,
            conditionContract: address(0),
            conditionCalldata: "",
            conditionMet: false,
            creationBlock: creationBlock,
            expirationBlock: expirationBlock,
            eta: 0,
            yayVotes: 0,
            nayVotes: 0,
            abstainVotes: 0,
            totalVotesCast: 0,
            state: ProposalState.Pending,
            executed: false,
            cancelled: false,
            vetoed: false
        });

        emit ProposalCreated(proposalId, msg.sender, targets, values, calldatas, new bytes32[](0), new uint256[](0), currentProtocolState, address(0), "", description, ProposalType.FunctionCall, creationBlock, expirationBlock);

        proposals[proposalId].state = ProposalState.Active;
        return proposalId;
    }

     function proposeStateTransition(
        ProtocolState newState,
        string memory description
    ) external returns (uint256) {
        require(newState != currentProtocolState, "Governor: New state must be different from current state");
        require(_stateTransitionAllowed(currentProtocolState, newState), "Governor: State transition not allowed from current state");

        uint256 proposalThreshold = governedParameters[KEY_PROPOSAL_THRESHOLD];
        require(getVotingPower(msg.sender) >= proposalThreshold, "Governor: Insufficient voting power to propose");
        require(bytes(description).length > 0, "Governor: Description cannot be empty");

        uint256 proposalId = nextProposalId++;
        uint256 creationBlock = block.number;
        uint256 votingPeriod = governedParameters[KEY_VOTING_PERIOD];
        uint256 expirationBlock = creationBlock.add(votingPeriod);

         proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: description,
            proposalType: ProposalType.StateTransition,
            targets: new address[](0),
            values: new uint256[](0),
            calldatas: new bytes[](0),
            parameterKeys: new bytes32[](0),
            parameterValues: new uint256[](0),
            newState: newState, // New target state
            conditionContract: address(0),
            conditionCalldata: "",
            conditionMet: false,
            creationBlock: creationBlock,
            expirationBlock: expirationBlock,
            eta: 0,
            yayVotes: 0,
            nayVotes: 0,
            abstainVotes: 0,
            totalVotesCast: 0,
            state: ProposalState.Pending,
            executed: false,
            cancelled: false,
            vetoed: false
        });

        emit ProposalCreated(proposalId, msg.sender, new address[](0), new uint256[](0), new bytes[](0), new bytes32[](0), new uint256[](0), newState, address(0), "", description, ProposalType.StateTransition, creationBlock, expirationBlock);

        proposals[proposalId].state = ProposalState.Active;
        return proposalId;
    }

     // Conditional Execution Proposal
     // Allows proposing actions that only become executable if an external on-chain condition is met
    function proposeConditionalExecution(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        address conditionContract, // Contract to check condition on
        bytes memory conditionCalldata, // Calldata to call conditionContract (must return bool)
        string memory description
    ) external returns (uint256) {
        require(targets.length == values.length && targets.length == calldatas.length, "Governor: Mismatched call data counts");
        require(targets.length > 0, "Governor: No calls specified");
        require(conditionContract != address(0), "Governor: Condition contract cannot be zero address");
        require(bytes(conditionCalldata).length > 0, "Governor: Condition calldata cannot be empty");

        uint256 proposalThreshold = governedParameters[KEY_PROPOSAL_THRESHOLD];
        require(getVotingPower(msg.sender) >= proposalThreshold, "Governor: Insufficient voting power to propose");
        require(bytes(description).length > 0, "Governor: Description cannot be empty");

        uint256 proposalId = nextProposalId++;
        uint256 creationBlock = block.number;
        uint256 votingPeriod = governedParameters[KEY_VOTING_PERIOD);
        uint256 expirationBlock = creationBlock.add(votingPeriod);

         proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: description,
            proposalType: ProposalType.ConditionalExecution,
            targets: targets,
            values: values,
            calldatas: calldatas,
            parameterKeys: new bytes32[](0),
            parameterValues: new uint256[](0),
            newState: currentProtocolState,
            conditionContract: conditionContract,
            conditionCalldata: conditionCalldata,
            conditionMet: false, // Initially false
            creationBlock: creationBlock,
            expirationBlock: expirationBlock,
            eta: 0, // Not set yet
            yayVotes: 0,
            nayVotes: 0,
            abstainVotes: 0,
            totalVotesCast: 0,
            state: ProposalState.Pending,
            executed: false,
            cancelled: false,
            vetoed: false
        });

         emit ProposalCreated(proposalId, msg.sender, targets, values, calldatas, new bytes32[](0), new uint256[](0), currentProtocolState, conditionContract, conditionCalldata, description, ProposalType.ConditionalExecution, creationBlock, expirationBlock);

        proposals[proposalId].state = ProposalState.Active;
        return proposalId;
    }


    // --- Voting ---

    function castVote(uint256 proposalId, VoteType voteType) external {
        _castVote(msg.sender, proposalId, voteType, "");
    }

     function castVoteWithReason(uint256 proposalId, VoteType voteType, string memory reason) external {
        _castVote(msg.sender, proposalId, voteType, reason);
     }

     // Gasless voting (EIP-712)
     // DELEGATE_VOTE_TYPEHASH = keccak256("CastVote(uint256 proposalId,uint8 voteType)");
     function castVoteBySignature(uint256 proposalId, VoteType voteType, uint256 nonce, uint256 expiry, bytes memory signature) external {
        bytes32 structHash = keccak256(abi.encode(
            keccak256("CastVote(uint256 proposalId,uint8 voteType,uint256 nonce,uint256 expiry)"),
            proposalId,
            uint8(voteType),
            nonce,
            expiry
        ));

        bytes32 domainSeparator = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256("QuantumMeshGovernor"), // Contract Name
            keccak256("1"), // Version
            block.chainid,
            address(this)
        ));

        bytes32 digest = domainSeparator.hashWithPrefix(structHash);
        address signer = digest.recover(signature);
        require(signer != address(0), "Governor: Invalid signature");
        require(nonce == voters[signer].lastReputationUpdateBlock, "Governor: Invalid nonce"); // Using lastReputationUpdateBlock as nonce
        require(expiry >= block.timestamp, "Governor: Signature expired");

        _castVote(signer, proposalId, voteType, "Signed Vote");
     }


    function _castVote(address voterAddress, uint256 proposalId, VoteType voteType, string memory reason) internal unlessProposalState(proposalId, ProposalState.Canceled) unlessProposalState(proposalId, ProposalState.Executed) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Active, "Governor: Voting is not active");
        require(block.number <= proposal.expirationBlock, "Governor: Voting period has ended");
        require(!hasVoted[proposalId][voterAddress], "Governor: Already voted");

        address votingAddress = delegateeLookup[voterAddress] == address(0) ? voterAddress : delegateeLookup[voterAddress];
        Voter storage voterInfo = voters[voterAddress]; // Use voterAddress for conditional delegation check

        // Check conditional delegation constraints
        if (voterInfo.delegationType == DelegationType.Conditional && voterAddress != votingAddress) { // If delegated and conditional
            require(voterInfo.conditionalDelegationAllowed[proposal.proposalType], "Governor: Delegation does not allow voting on this proposal type");
            // Could add more complex checks here based on proposal content if needed
        }

        // Get voting power at the snapshot block
        uint256 votingPower = _calculateVotingPowerAtBlock(voterAddress, proposal.creationBlock); // Use the delegator's power at snapshot

        require(votingPower > 0, "Governor: Voter has no voting power");

        hasVoted[proposalId][voterAddress] = true;

        if (voteType == VoteType.Yay) {
            proposal.yayVotes = proposal.yayVotes.add(votingPower);
        } else if (voteType == VoteType.Nay) {
            proposal.nayVotes = proposal.nayVotes.add(votingPower);
        } else if (voteType == VoteType.Abstain) {
            proposal.abstainVotes = proposal.abstainVotes.add(votingPower);
        } else {
            revert("Governor: Invalid vote type");
        }

        proposal.totalVotesCast = proposal.totalVotesCast.add(votingPower); // This total is per-voter power at snapshot

        // Update reputation based on participation (simplified: positive update for any cast vote)
        _updateReputation(voterAddress, true, votingPower); // Success = true for casting a valid vote

        emit VoteCast(voterAddress, proposalId, voteType, votingPower, reason);
    }

    // --- Proposal State Transitions ---

    function queueProposal(uint256 proposalId) external whenProposalState(proposalId, ProposalState.Succeeded) {
        Proposal storage proposal = proposals[proposalId];
        require(block.number > proposal.expirationBlock, "Governor: Voting period not ended"); // Ensure voting is over

        // Check if proposal succeeded (quorum and threshold)
        // Quorum check: Total votes cast vs Total possible voting power at snapshot block
        // Getting Total possible voting power at snapshot is hard without token/governor checkpoints.
        // Alternative: Use total supply of token at snapshot, or a predefined supply.
        // Let's assume we can get a reasonable approximation of total votable power at the snapshot block.
        // Placeholder: Using totalDelegatedVotes of address(0) + total supply approximation
        // This is a *major simplification* and needs a proper voting power snapshot system (like OpenZeppelin's ERC20Votes).
        uint256 totalVotablePower = totalDelegatedVotes[address(0)].add(quantumToken.totalSupply()); // VERY simplistic snapshot approx.
        uint256 quorumThresholdBps = governedParameters[KEY_QUORUM_THRESHOLD_BPS];
        uint256 requiredQuorum = totalVotablePower.mul(quorumThresholdBps).div(10000);
        require(proposal.totalVotesCast >= requiredQuorum, "Governor: Quorum not reached");

        // Threshold check: Yay votes vs total votes cast (excluding abstain)
        uint256 votesExcludingAbstain = proposal.yayVotes.add(proposal.nayVotes);
        require(votesExcludingAbstain > 0, "Governor: No non-abstain votes cast"); // Avoid division by zero
        require(proposal.yayVotes > votesExcludingAbstain.div(2), "Governor: Majority threshold not reached (Need > 50% Yay of non-abstain votes)");

        // Calculate execution time / block
        uint256 timelockDelay = governedParameters[KEY_TIMELOCK_DELAY];
        // Using block number for timelock delay
        proposal.eta = block.number.add(timelockDelay);

        proposal.state = ProposalState.Queued;
        emit ProposalQueued(proposalId, proposal.eta);
    }

     function executeProposal(uint256 proposalId) external onlyGovernorRole whenProposalState(proposalId, ProposalState.Queued) {
        Proposal storage proposal = proposals[proposalId];
        // Check if timelock has passed
        require(block.number >= proposal.eta, "Governor: Timelock has not expired");

        // Re-check condition for ConditionalExecution types before executing
        if (proposal.proposalType == ProposalType.ConditionalExecution) {
             // Ensure condition was checked and met
            require(proposal.conditionMet, "Governor: Condition for execution not met");
             // Should we allow checking condition again here? Or rely on triggerConditionalExecution?
             // Let's rely on triggerConditionalExecution setting `conditionMet` and state.
        }

        _executeProposal(proposalId);

        proposal.executed = true;
        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(proposalId);

        // Update reputation for participants in the successful vote? (Optional, could be complex)
        // Could iterate through hasVoted and reward Yays, penalize Nays/Abstains.
        // Skipped for simplicity in this example.
    }

     function cancelProposal(uint256 proposalId) external unlessProposalState(proposalId, ProposalState.Executed) unlessProposalState(proposalId, ProposalState.Canceled) unlessProposalState(proposalId, ProposalState.Vetoed) {
        Proposal storage proposal = proposals[proposalId];

        // Allow cancellation if in Pending or Active state and:
        // 1. Proposer cancels (covered by renounceProposal below)
        // 2. A large portion vote against it early (e.g., > 50% Nay + Abstain of total possible power) - This is complex to implement without power snapshots.
        // 3. Minimum required voting power drops below threshold for proposer or proposal.

        // Simple cancellation: Allow cancel if still Pending or Active and threshold criteria is lost OR proposer cancels (renounceProposal).
        require(proposal.state == ProposalState.Pending || proposal.state == ProposalState.Active, "Governor: Cannot cancel proposal in this state");

        // Example cancellation condition: If proposer's voting power drops below proposal threshold AFTER proposing
        uint256 proposalThreshold = governedParameters[KEY_PROPOSAL_THRESHOLD];
        require(getVotingPower(proposal.proposer) < proposalThreshold || msg.sender == proposal.proposer, "Governor: Cancellation conditions not met");

        proposal.state = ProposalState.Canceled;
        proposal.cancelled = true;
        emit ProposalCanceled(proposalId);
    }

    // Proposer can renounce their own proposal if not yet Executed/Canceled/Vetoed
    function renounceProposal(uint256 proposalId) external onlyProposer(proposalId) unlessProposalState(proposalId, ProposalState.Executed) unlessProposalState(proposalId, ProposalState.Canceled) unlessProposalState(proposalId, ProposalState.Vetoed) {
         Proposal storage proposal = proposals[proposalId];
         require(proposal.state == ProposalState.Pending || proposal.state == ProposalState.Active, "Governor: Cannot renounce proposal in this state");

         proposal.state = ProposalState.Canceled; // Treat renounce as a type of cancellation
         proposal.cancelled = true;
         emit ProposalRenounced(proposalId);
    }


    // --- Conditional Execution Handling ---

     // Checks if the condition for a conditional proposal is met by calling the specified contract
    function checkConditionalExecutionStatus(uint256 proposalId) public returns (bool) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposalType == ProposalType.ConditionalExecution, "Governor: Not a conditional execution proposal");
        require(proposal.state == ProposalState.Succeeded || proposal.state == ProposalState.ConditionPending, "Governor: Proposal not in a state to check condition");

        (bool success, bytes memory returnData) = proposal.conditionContract.staticcall(proposal.conditionCalldata);
        require(success, "Governor: Condition contract call failed");
        require(returnData.length == 32, "Governor: Condition contract must return bytes32 (interpreted as bool)"); // Expect bytes32 for bool

        bool conditionMet = abi.decode(returnData, (bool));
        proposal.conditionMet = conditionMet;

        if (conditionMet) {
            // If condition is met, transition state if currently Pending
            if (proposal.state == ProposalState.ConditionPending) {
                // Calculate ETA and queue it now that condition is met
                 uint256 timelockDelay = governedParameters[KEY_TIMELOCK_DELAY];
                 proposal.eta = block.number.add(timelockDelay);
                 proposal.state = ProposalState.Queued; // Move directly to queued once condition is met
                 emit ProposalQueued(proposalId, proposal.eta); // Emit queue event now
            } else if (proposal.state == ProposalState.Succeeded) {
                 // If succeeded but not yet queued (condition wasn't met previously), set state to ConditionMet
                proposal.state = ProposalState.ConditionMet; // Signal condition met, waiting for queue/execution
            }
        } else {
             // If condition not met, transition state if currently Succeeded
            if (proposal.state == ProposalState.Succeeded) {
                 proposal.state = ProposalState.ConditionPending; // Wait for condition
            }
        }

        emit ConditionalExecutionTriggered(proposalId, conditionMet);
        return conditionMet;
    }


    // Allows triggering execution if a ConditionalExecution proposal is in Queued state and condition was met.
    // This is separate from the standard `executeProposal` to highlight the conditional nature.
    function triggerConditionalExecution(uint256 proposalId) external onlyGovernorRole whenProposalState(proposalId, ProposalState.Queued) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposalType == ProposalType.ConditionalExecution, "Governor: Not a conditional execution proposal");

        // Condition must have been checked and met previously.
        // A check inside `executeProposal` also verifies this.
        // This function primarily serves as a specific entry point for conditional execution.
        // We can simply call the main execute function.
         executeProposal(proposalId);
    }


    // --- Internal Execution Logic ---

    function _executeProposal(uint256 proposalId) internal {
        Proposal storage proposal = proposals[proposalId];

        // Execute based on proposal type
        if (proposal.proposalType == ProposalType.ParameterChange) {
            for (uint i = 0; i < proposal.parameterKeys.length; i++) {
                 bytes32 key = proposal.parameterKeys[i];
                 uint256 oldValue = governedParameters[key];
                 uint256 newValue = proposal.parameterValues[i];
                 governedParameters[key] = newValue;
                 emit GovernedParameterChanged(key, oldValue, newValue);
            }
        } else if (proposal.proposalType == ProposalType.FunctionCall || proposal.proposalType == ProposalType.ConditionalExecution) {
             // Conditional execution follows FunctionCall execution path
            for (uint i = 0; i < proposal.targets.length; i++) {
                 address target = proposal.targets[i];
                 uint256 value = proposal.values[i];
                 bytes memory calldataPayload = proposal.calldatas[i];

                 (bool success, ) = target.call{value: value}(calldataPayload);
                 require(success, "Governor: Execution failed");
            }
        } else if (proposal.proposalType == ProposalType.StateTransition) {
             ProtocolState oldState = currentProtocolState;
             ProtocolState newState = proposal.newState;
             require(_stateTransitionAllowed(oldState, newState), "Governor: Invalid state transition"); // Should be checked at proposal creation, but double-check
             currentProtocolState = newState;
             emit ProtocolStateChanged(oldState, newState);
             emit ProposalStateTransitioned(proposalId, oldState, newState);

             // Specific actions on state change could be added here (e.g., pausing interactions)
        }
    }

    // Define allowed protocol state transitions
    function _stateTransitionAllowed(ProtocolState from, ProtocolState to) internal pure returns (bool) {
        // Define your state machine transitions here
        if (from == ProtocolState.Initial) {
            return to == ProtocolState.Activated;
        } else if (from == ProtocolState.Activated) {
            return to == ProtocolState.Paused || to == ProtocolState.UpgradePending || to == ProtocolState.Shutdown;
        } else if (from == ProtocolState.Paused) {
            return to == ProtocolState.Activated || to == ProtocolState.Shutdown;
        } else if (from == ProtocolState.UpgradePending) {
            return to == ProtocolState.Activated || to == ProtocolState.Shutdown;
        } else if (from == ProtocolState.Shutdown) {
            return false; // Cannot transition from Shutdown
        }
        return false; // Should not reach here
    }


    // --- Query Functions ---

    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        require(proposalId > 0 && proposalId < nextProposalId, "Governor: Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];

        // Recalculate state if voting period has ended
        if (proposal.state == ProposalState.Active && block.number > proposal.expirationBlock) {
            // Check if quorum and threshold met
            // Requires snapshot of total votable power at creationBlock - see limitations above.
            // For a true check here, you need a power snapshotting mechanism.
            // As a fallback, we can make a rough check or rely on queueProposal to do the definitive check.
            // Let's rely on queueProposal to transition from Active to Succeeded/Defeated/Expired.
             return ProposalState.Expired; // If voting ended and not yet Succeeded/Defeated
        }

        // For ConditionalExecution proposals, if Succeeded, check condition status
         if (proposal.proposalType == ProposalType.ConditionalExecution && proposal.state == ProposalState.Succeeded) {
             // Need to be able to call checkConditionalExecutionStatus publicly (but not changing state)
             // This would require checkConditionalExecutionStatus to be view or pure
             // Let's add a separate view helper for checking the *current* condition status without state change.
             // Or, more simply, if Succeeded, show Succeeded until condition is checked/met or it expires.
             return proposal.state;
         }


        return proposal.state;
    }

     // View helper to check condition status without state changes
     function checkConditionalConditionStatusView(uint256 proposalId) public view returns (bool) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposalType == ProposalType.ConditionalExecution, "Governor: Not a conditional execution proposal");
         (bool success, bytes memory returnData) = proposal.conditionContract.staticcall(proposal.conditionCalldata);
         require(success && returnData.length == 32, "Governor: Condition check failed or invalid return");
         return abi.decode(returnData, (bool));
     }


    function getProposalVotes(uint256 proposalId) public view returns (uint256 yayVotes, uint256 nayVotes, uint256 abstainVotes) {
        require(proposalId > 0 && proposalId < nextProposalId, "Governor: Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];
        return (proposal.yayVotes, proposal.nayVotes, proposal.abstainVotes);
    }

    function getProposalDetails(uint256 proposalId) public view returns (Proposal memory) {
        require(proposalId > 0 && proposalId < nextProposalId, "Governor: Invalid proposal ID");
        return proposals[proposalId];
    }

    function getCurrentProtocolState() public view returns (ProtocolState) {
        return currentProtocolState;
    }

     function getGovernanceParameter(bytes32 key) public view returns (uint256) {
         return governedParameters[key];
     }

     // Helper function to check if quorum is met (useful for frontends)
     function calculateQuorumReached(uint256 proposalId) public view returns (bool) {
         require(proposalId > 0 && proposalId < nextProposalId, "Governor: Invalid proposal ID");
         Proposal storage proposal = proposals[proposalId];
         // Need snapshot of total votable power - see limitations.
         // Using current total supply + current total delegated votes (approximation)
         uint256 totalVotablePower = totalDelegatedVotes[address(0)].add(quantumToken.totalSupply()); // Approximation
         uint256 quorumThresholdBps = governedParameters[KEY_QUORUM_THRESHOLD_BPS];
         uint256 requiredQuorum = totalVotablePower.mul(quorumThresholdBps).div(10000);
         return proposal.totalVotesCast >= requiredQuorum;
     }

     // Helper function to check if threshold is met (useful for frontends)
     function calculateThresholdReached(uint256 proposalId) public view returns (bool) {
         require(proposalId > 0 && proposalId < nextProposalId, "Governor: Invalid proposal ID");
         Proposal storage proposal = proposals[proposalId];
         uint256 votesExcludingAbstain = proposal.yayVotes.add(proposal.nayVotes);
         if (votesExcludingAbstain == 0) return false; // Cannot reach threshold with 0 non-abstain votes
         return proposal.yayVotes > votesExcludingAbstain.div(2); // Need > 50% Yay of non-abstain
     }


     // --- Governor Role Functions ---
     // Note: In a typical Governor setup, these actions (like queuing/executing)
     // are triggered by calls to the governor itself, not necessarily by a GOVERNOR_ROLE holder directly.
     // A separate Timelock contract holds the GOVERNOR_ROLE to execute calls.
     // For this example, we've simplified by giving a GOVERNOR_ROLE to an EOA/multi-sig
     // that calls queueProposal and executeProposal.

     // Example: Add a new governor via proposal
     // This requires a proposeFunctionCall that calls `grantRole(GOVERNOR_ROLE, newGovernorAddress)` on THIS contract.


     // --- Emergency Pause (Governed) ---
     // ProtocolState.Paused serves as a governed pause.
     // Functions that should be pausable would need to check `currentProtocolState`.
     // Example check: `require(currentProtocolState != ProtocolState.Paused, "Protocol is paused");`
     // Adding functions to directly pause/unpause by role is less decentralized.
     // A governed system would use `proposeStateTransition` to move to/from Paused state.
     // No direct pause/unpause functions exposed here, relies on state transitions.

}
```