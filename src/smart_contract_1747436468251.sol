Okay, this is a fun challenge! Let's design a contract based on a concept that introduces state-dependent interaction between proposals, drawing inspiration from complex systems or perhaps even a metaphorical interpretation of "entanglement".

We'll create a system where proposals can be "entangled" in pairs. When a voter casts a vote on one proposal in an entangled pair, it affects their potential voting power on the *other* proposal in that same pair. This forces voters to strategically allocate their voting influence across linked issues.

Let's call this contract `QuantumEntanglementVoting`.

---

**Smart Contract: QuantumEntanglementVoting**

**Outline & Function Summary:**

This contract implements an advanced voting system where proposals can be linked in "entangled" pairs. Casting a vote (using a certain amount of effective voting power) on one proposal in an entangled pair reduces the maximum effective voting power a voter can use on the other proposal in that pair. This creates a strategic allocation challenge for voters.

**Key Concepts:**

1.  **Base Voting Power:** Admin-assigned power to addresses. This is the total potential influence a voter has across all *entangled pairs*.
2.  **Entangled Proposals:** Proposals explicitly linked by the admin.
3.  **Effective Voting Power:** The amount of a voter's base power they choose to allocate and use on a *specific* vote for a *specific* proposal.
4.  **Power Allocation Constraint:** For an entangled pair (A, B), a voter's total effective power used across both A and B cannot exceed their base voting power. Casting `X` power on A means the maximum they can use on B is `basePower - X`.
5.  **Strategic Voting:** Voters must decide how to split their influence between linked proposals.

**State Variables:**

*   `owner`: The address with administrative privileges.
*   `proposalCounter`: Counter for unique proposal IDs.
*   `proposals`: Mapping from proposal ID to `Proposal` struct.
*   `entangledProposals`: Mapping linking a proposal ID to its entangled partner ID (bidirectional).
*   `baseVotingPower`: Mapping from voter address to their total base voting power.
*   `voterStates`: Nested mapping: `proposalId -> voterAddress -> VoterState`. Stores how a voter voted on a specific proposal and the effective power they used *on that proposal*.

**Enums:**

*   `ProposalState`: `Pending`, `Active`, `Closed`, `Executed`, `Cancelled`.
*   `VoteType`: `None`, `For`, `Against`, `Abstain`.

**Structs:**

*   `Proposal`: Stores proposal details, timing, state, and total effective power for each vote type.
*   `VoterState`: Stores a voter's vote type and the effective power they committed for a specific proposal.

**Function Summary (>= 20 functions):**

**Admin Functions (onlyOwner):**

1.  `constructor()`: Sets the contract owner.
2.  `transferOwnership(address newOwner)`: Transfers ownership.
3.  `renounceOwnership()`: Renounces ownership.
4.  `setBaseVotingPower(address voter, uint256 amount)`: Assigns or updates base voting power for an address.
5.  `removeBaseVotingPower(address voter)`: Removes base voting power.
6.  `createProposal(string memory title, string memory description, uint256 durationSeconds)`: Creates a new proposal in `Pending` state.
7.  `cancelProposal(uint256 proposalId)`: Cancels a `Pending` proposal.
8.  `entangleProposals(uint256 proposalId1, uint256 proposalId2)`: Links two `Pending` proposals into an entangled pair. Requires both to be Pending and not already entangled.
9.  `disentangleProposals(uint256 proposalId)`: Removes the entanglement link for a given proposal (and its partner), but only if both are still `Pending`.
10. `activateProposal(uint256 proposalId)`: Starts the voting period for a `Pending` proposal. If entangled, activates its partner too. Sets state to `Active` and records start/end times.
11. `emergencyCancelActiveProposal(uint256 proposalId)`: Allows owner to cancel an `Active` proposal in an emergency.
12. `extendVotingPeriod(uint256 proposalId, uint256 additionalDurationSeconds)`: Extends the voting end time for an `Active` proposal and its entangled partner.

**Voter Functions:**

13. `castVote(uint256 proposalId, VoteType voteType, uint256 powerToUse)`: Casts or changes a vote for a proposal, allocating a specific amount of effective power. Requires the proposal to be `Active`, the voter to have sufficient base power, and the allocated power to respect the entanglement constraint (total used on paired proposals <= base power). Updates proposal totals and voter state.
14. `changeVote(uint256 proposalId, VoteType newVoteType, uint256 newPowerToUse)`: Allows changing vote type and re-allocating power *before* the voting period ends. Essentially a wrapper around `castVote` with checks for existing vote.

**Outcome & State Transition Functions:**

15. `closeVotingPeriod(uint256 proposalId)`: Can be called by anyone after the proposal's end time. Sets the state from `Active` to `Closed`.
16. `calculateOutcome(uint256 proposalId)`: (Internal) Calculates the winning vote type based on total effective power used `For` vs `Against` for a `Closed` proposal.
17. `executeProposal(uint256 proposalId)`: Placeholder function. Marks a `Closed` proposal as `Executed` if it passed (determined by `calculateOutcome`). In a real dApp, this would trigger associated logic (e.g., transferring tokens, calling another contract).

**View Functions:**

18. `getProposalCount()`: Returns the total number of proposals created.
19. `getProposal(uint256 proposalId)`: Returns details of a specific proposal.
20. `getEntangledPartner(uint256 proposalId)`: Returns the ID of the entangled partner proposal, or 0 if not entangled.
21. `getBaseVotingPower(address voter)`: Returns the base voting power of an address.
22. `getVoterStateForProposal(uint256 proposalId, address voter)`: Returns the voting state (vote type, effective power used) of a specific voter on a specific proposal.
23. `getAvailablePowerForVote(uint256 proposalId, address voter)`: Calculates the maximum effective power a voter can currently use on a specific proposal, considering their base power and the power already used on its entangled partner.
24. `getProposalOutcome(uint256 proposalId)`: Returns the winning `VoteType` for a `Closed` or `Executed` proposal.
25. `getProposalState(uint256 proposalId)`: Returns the current state of a proposal.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumEntanglementVoting
 * @dev An advanced voting contract where proposals can be entangled,
 *      affecting voter power allocation between them.
 *
 * Outline & Function Summary:
 *
 * This contract implements an advanced voting system where proposals can be linked in "entangled" pairs.
 * Casting a vote (using a certain amount of effective voting power) on one proposal in an entangled pair
 * reduces the maximum effective voting power a voter can use on the other proposal in that same pair.
 * This creates a strategic allocation challenge for voters.
 *
 * Key Concepts:
 * 1.  Base Voting Power: Admin-assigned power to addresses. Total potential influence.
 * 2.  Entangled Proposals: Proposals explicitly linked by the admin.
 * 3.  Effective Voting Power: The amount of a voter's base power they choose to allocate and use on a specific vote for a specific proposal.
 * 4.  Power Allocation Constraint: For an entangled pair (A, B), a voter's total effective power used across both A and B cannot exceed their base voting power. Casting X power on A means the maximum they can use on B is basePower - X.
 * 5.  Strategic Voting: Voters must decide how to split their influence between linked proposals.
 *
 * State Variables:
 * - owner: The address with administrative privileges.
 * - proposalCounter: Counter for unique proposal IDs.
 * - proposals: Mapping from proposal ID to Proposal struct.
 * - entangledProposals: Mapping linking a proposal ID to its entangled partner ID (bidirectional).
 * - baseVotingPower: Mapping from voter address to their total base voting power.
 * - voterStates: Nested mapping: proposalId -> voterAddress -> VoterState.
 *
 * Enums:
 * - ProposalState: Pending, Active, Closed, Executed, Cancelled.
 * - VoteType: None, For, Against, Abstain.
 *
 * Structs:
 * - Proposal: Stores proposal details, timing, state, and total effective power for each vote type.
 * - VoterState: Stores a voter's vote type and the effective power they committed for a specific proposal.
 *
 * Function Summary (>= 20 functions):
 * Admin Functions (onlyOwner):
 * 1.  constructor()
 * 2.  transferOwnership(address newOwner)
 * 3.  renounceOwnership()
 * 4.  setBaseVotingPower(address voter, uint256 amount)
 * 5.  removeBaseVotingPower(address voter)
 * 6.  createProposal(string memory title, string memory description, uint256 durationSeconds)
 * 7.  cancelProposal(uint256 proposalId)
 * 8.  entangleProposals(uint256 proposalId1, uint256 proposalId2)
 * 9.  disentangleProposals(uint256 proposalId)
 * 10. activateProposal(uint256 proposalId)
 * 11. emergencyCancelActiveProposal(uint256 proposalId)
 * 12. extendVotingPeriod(uint256 proposalId, uint256 additionalDurationSeconds)
 * Voter Functions:
 * 13. castVote(uint256 proposalId, VoteType voteType, uint256 powerToUse)
 * 14. changeVote(uint256 proposalId, VoteType newVoteType, uint256 newPowerToUse)
 * Outcome & State Transition Functions:
 * 15. closeVotingPeriod(uint256 proposalId)
 * 16. calculateOutcome(uint256 proposalId) (Internal)
 * 17. executeProposal(uint256 proposalId)
 * View Functions:
 * 18. getProposalCount()
 * 19. getProposal(uint256 proposalId)
 * 20. getEntangledPartner(uint256 proposalId)
 * 21. getBaseVotingPower(address voter)
 * 22. getVoterStateForProposal(uint256 proposalId, address voter)
 * 23. getAvailablePowerForVote(uint256 proposalId, address voter)
 * 24. getProposalOutcome(uint256 proposalId)
 * 25. getProposalState(uint256 proposalId)
 */
contract QuantumEntanglementVoting {

    address public owner;

    enum ProposalState {
        Pending,    // Created, not yet active, can be entangled/cancelled
        Active,     // Voting is open
        Closed,     // Voting ended, outcome not yet processed/executed
        Executed,   // Outcome processed/executed
        Cancelled   // Cancelled before activation/closing
    }

    enum VoteType {
        None,       // No vote cast
        For,
        Against,
        Abstain
    }

    struct Proposal {
        uint256 id;
        string title;
        string description;
        uint256 startTime;
        uint256 endTime;
        ProposalState state;
        uint256 totalEffectivePowerFor;
        uint256 totalEffectivePowerAgainst;
        uint256 totalEffectivePowerAbstain;
        // Note: totalEffectivePowerUsed is implicitly sum of For + Against + Abstain
    }

    struct VoterState {
        bool hasVoted; // True if they have cast *any* vote (including changing)
        VoteType voteType; // The current vote type
        uint256 effectivePowerUsedOnThis; // Power committed to this specific proposal
    }

    uint256 public proposalCounter;

    // Mapping from proposal ID to Proposal struct
    mapping(uint256 => Proposal) public proposals;

    // Mapping linking entangled proposal IDs. proposalId => entangledPartnerId
    mapping(uint256 => uint256) public entangledProposals;

    // Mapping from voter address to their total base voting power
    mapping(address => uint256) public baseVotingPower;

    // Nested mapping: proposalId => voterAddress => VoterState
    mapping(uint256 => mapping(address => VoterState)) public voterStates;

    // --- Events ---
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event BaseVotingPowerSet(address indexed voter, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, string title, uint256 duration);
    event ProposalCancelled(uint256 indexed proposalId);
    event ProposalsEntangled(uint256 indexed proposalId1, uint256 indexed proposalId2);
    event ProposalsDisentangled(uint256 indexed proposalId1, uint256 indexed proposalId2);
    event ProposalActivated(uint256 indexed proposalId, uint256 startTime, uint256 endTime);
    event ProposalVotingPeriodExtended(uint256 indexed proposalId, uint256 newEndTime);
    event VoteCast(uint256 indexed proposalId, address indexed voter, VoteType voteType, uint256 effectivePower);
    event ProposalClosed(uint256 indexed proposalId, VoteType outcome);
    event ProposalExecuted(uint256 indexed proposalId);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier proposalMustExist(uint256 proposalId) {
        require(proposalId > 0 && proposalId <= proposalCounter, "Proposal does not exist");
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
    }

    // --- Admin Functions ---

    /**
     * @dev Transfers ownership of the contract to a new account.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        address previousOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
    }

    /**
     * @dev Renounces ownership of the contract.
     * The contract will be left without an owner, leaving administration to be done by no one.
     */
    function renounceOwnership() external onlyOwner {
        address previousOwner = owner;
        owner = address(0);
        emit OwnershipTransferred(previousOwner, address(0));
    }

    /**
     * @dev Assigns or updates the base voting power for a given address.
     * Can only be called by the owner.
     * @param voter The address to set power for.
     * @param amount The amount of base voting power.
     */
    function setBaseVotingPower(address voter, uint256 amount) external onlyOwner {
        baseVotingPower[voter] = amount;
        emit BaseVotingPowerSet(voter, amount);
    }

    /**
     * @dev Removes the base voting power for a given address.
     * Can only be called by the owner. Note: This does *not* invalidate existing votes cast with that power on active proposals.
     * @param voter The address to remove power from.
     */
    function removeBaseVotingPower(address voter) external onlyOwner {
         // Setting to 0 is equivalent to removing for practical purposes here.
         // Doesn't affect power already allocated on active proposals.
        baseVotingPower[voter] = 0;
        emit BaseVotingPowerSet(voter, 0);
    }

    /**
     * @dev Creates a new proposal in the Pending state.
     * Can only be called by the owner.
     * @param title The title of the proposal.
     * @param description A description of the proposal.
     * @param durationSeconds The intended duration of the voting period once activated.
     */
    function createProposal(string memory title, string memory description, uint256 durationSeconds) external onlyOwner returns (uint256 proposalId) {
        proposalCounter++;
        proposalId = proposalCounter;
        proposals[proposalId] = Proposal({
            id: proposalId,
            title: title,
            description: description,
            startTime: 0, // Set on activation
            endTime: 0,   // Set on activation + duration
            state: ProposalState.Pending,
            totalEffectivePowerFor: 0,
            totalEffectivePowerAgainst: 0,
            totalEffectivePowerAbstain: 0
        });
        emit ProposalCreated(proposalId, title, durationSeconds);
        return proposalId;
    }

    /**
     * @dev Cancels a proposal that is still in the Pending state.
     * Can only be called by the owner.
     * @param proposalId The ID of the proposal to cancel.
     */
    function cancelProposal(uint256 proposalId) external onlyOwner proposalMustExist(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Pending, "Proposal must be Pending to be cancelled");

        // If entangled, disentangle it first
        uint256 partnerId = entangledProposals[proposalId];
        if (partnerId != 0) {
             // This check is actually redundant due to disentangleProposals's own checks,
             // but good defensively.
             require(proposals[partnerId].state == ProposalState.Pending, "Entangled partner must also be Pending to cancel entanglement");
             _disentangle(proposalId, partnerId);
        }

        proposal.state = ProposalState.Cancelled;
        emit ProposalCancelled(proposalId);
    }

    /**
     * @dev Entangles two proposals, linking their voting power allocation.
     * Both proposals must exist, be in the Pending state, and not already entangled.
     * Can only be called by the owner.
     * @param proposalId1 The ID of the first proposal.
     * @param proposalId2 The ID of the second proposal.
     */
    function entangleProposals(uint256 proposalId1, uint256 proposalId2) external onlyOwner proposalMustExist(proposalId1) proposalMustExist(proposalId2) {
        require(proposalId1 != proposalId2, "Cannot entangle a proposal with itself");

        Proposal storage prop1 = proposals[proposalId1];
        Proposal storage prop2 = proposals[proposalId2];

        require(prop1.state == ProposalState.Pending, "Proposal 1 must be Pending");
        require(prop2.state == ProposalState.Pending, "Proposal 2 must be Pending");
        require(entangledProposals[proposalId1] == 0, "Proposal 1 is already entangled");
        require(entangledProposals[proposalId2] == 0, "Proposal 2 is already entangled");

        entangledProposals[proposalId1] = proposalId2;
        entangledProposals[proposalId2] = proposalId1;

        emit ProposalsEntangled(proposalId1, proposalId2);
    }

    /**
     * @dev Removes the entanglement link between two proposals.
     * Both proposals must exist and be in the Pending state.
     * Can only be called by the owner.
     * @param proposalId The ID of one of the entangled proposals.
     */
    function disentangleProposals(uint256 proposalId) external onlyOwner proposalMustExist(proposalId) {
        uint256 partnerId = entangledProposals[proposalId];
        require(partnerId != 0, "Proposal is not entangled");

        Proposal storage prop1 = proposals[proposalId];
        Proposal storage prop2 = proposals[partnerId];

        require(prop1.state == ProposalState.Pending, "Proposal must be Pending to disentangle");
        require(prop2.state == ProposalState.Pending, "Entangled partner must also be Pending to disentangle");

        _disentangle(proposalId, partnerId);
    }

    /**
     * @dev Internal helper to remove entanglement.
     */
    function _disentangle(uint256 proposalId1, uint256 proposalId2) internal {
         entangledProposals[proposalId1] = 0;
         entangledProposals[proposalId2] = 0;
         emit ProposalsDisentangled(proposalId1, proposalId2);
    }

    /**
     * @dev Activates a pending proposal, starting its voting period.
     * If the proposal is entangled, its partner is activated simultaneously with the same timeline.
     * Can only be called by the owner.
     * @param proposalId The ID of the proposal to activate.
     */
    function activateProposal(uint256 proposalId) external onlyOwner proposalMustExist(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Pending, "Proposal must be Pending to activate");
        require(proposal.endTime == 0, "Proposal duration must be set (via createProposal)"); // Ensure duration was implicitly captured

        uint256 partnerId = entangledProposals[proposalId];

        uint256 startTime = block.timestamp;
        // Using a default duration if somehow not set during creation (shouldn't happen with current createProposal)
        uint256 duration = proposal.endTime > 0 ? proposal.endTime : 7 days; // Default duration, seconds

        // Re-calculate endTime based on current activation time + original duration logic
        // Storing duration separately might be clearer, but this uses original endTime field
        // Let's assume original endTime field *was* duration in seconds for Pending proposals.
        duration = proposals[proposalId].endTime; // Retrieve stored duration
        require(duration > 0, "Proposal duration must be greater than 0");
        uint256 endTime = startTime + duration;


        proposal.state = ProposalState.Active;
        proposal.startTime = startTime;
        proposal.endTime = endTime;
        emit ProposalActivated(proposalId, startTime, endTime);

        if (partnerId != 0) {
            Proposal storage partnerProposal = proposals[partnerId];
            // Partner must also be pending if entanglement was valid
            require(partnerProposal.state == ProposalState.Pending, "Entangled partner must be Pending to activate together");

            partnerProposal.state = ProposalState.Active;
            partnerProposal.startTime = startTime;
            partnerProposal.endTime = endTime; // Same timeline for entangled pairs
            emit ProposalActivated(partnerId, startTime, endTime);
        }
    }


    /**
     * @dev Allows owner to cancel an active proposal in case of emergency.
     * Voting immediately stops. The proposal moves to Cancelled state.
     * @param proposalId The ID of the proposal to emergency cancel.
     */
     function emergencyCancelActiveProposal(uint256 proposalId) external onlyOwner proposalMustExist(proposalId) {
         Proposal storage proposal = proposals[proposalId];
         require(proposal.state == ProposalState.Active, "Proposal must be Active to emergency cancel");

         proposal.state = ProposalState.Cancelled;
         // Optionally set endTime to block.timestamp to reflect immediate stop, though state is primary indicator
         proposal.endTime = block.timestamp;

         // If entangled, emergency cancel the partner too
         uint256 partnerId = entangledProposals[proposalId];
         if (partnerId != 0) {
             Proposal storage partnerProposal = proposals[partnerId];
             if(partnerProposal.state == ProposalState.Active) { // Only cancel if partner is also active
                 partnerProposal.state = ProposalState.Cancelled;
                 partnerProposal.endTime = block.timestamp;
                 emit ProposalCancelled(partnerId);
             }
         }

         emit ProposalCancelled(proposalId);
     }

    /**
     * @dev Extends the voting period for an active proposal.
     * If the proposal is entangled, its partner's voting period is extended by the same amount.
     * Can only be called by the owner.
     * @param proposalId The ID of the proposal to extend.
     * @param additionalDurationSeconds The number of seconds to add to the current end time.
     */
     function extendVotingPeriod(uint256 proposalId, uint256 additionalDurationSeconds) external onlyOwner proposalMustExist(proposalId) {
         Proposal storage proposal = proposals[proposalId];
         require(proposal.state == ProposalState.Active, "Proposal must be Active to extend voting");
         require(additionalDurationSeconds > 0, "Additional duration must be positive");

         uint256 oldEndTime = proposal.endTime;
         uint256 newEndTime = oldEndTime + additionalDurationSeconds;
         require(newEndTime > oldEndTime, "New end time must be greater than old end time"); // Prevent overflow issues

         proposal.endTime = newEndTime;
         emit ProposalVotingPeriodExtended(proposalId, newEndTime);

         uint256 partnerId = entangledProposals[proposalId];
         if (partnerId != 0) {
             Proposal storage partnerProposal = proposals[partnerId];
             // Extend only if partner is also active and potentially entangled
             if(partnerProposal.state == ProposalState.Active && entangledProposals[partnerId] == proposalId) {
                partnerProposal.endTime = newEndTime; // Set to the same absolute end time
                emit ProposalVotingPeriodExtended(partnerId, newEndTime);
             }
         }
     }


    // --- Voter Functions ---

    /**
     * @dev Casts or updates a voter's vote for a specific proposal, allocating a specific amount of power.
     * The amount of power usable is constrained by the voter's base power and power already allocated
     * to an entangled partner proposal.
     * @param proposalId The ID of the proposal to vote on.
     * @param voteType The type of vote (For, Against, Abstain). Cannot be None.
     * @param powerToUse The amount of effective voting power to commit to this vote.
     */
    function castVote(uint256 proposalId, VoteType voteType, uint256 powerToUse) external proposalMustExist(proposalId) {
        require(voteType != VoteType.None, "Vote type cannot be None");

        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Active, "Voting is not active for this proposal");
        require(block.timestamp >= proposal.startTime && block.timestamp < proposal.endTime, "Voting is not currently open");
        require(baseVotingPower[msg.sender] > 0, "Voter has no base voting power");

        uint256 voterBasePower = baseVotingPower[msg.sender];
        uint256 powerUsedOnPartner = 0;
        uint256 partnerId = entangledProposals[proposalId];

        if (partnerId != 0) {
            // Check how much power the voter has already used on the entangled partner
            powerUsedOnPartner = voterStates[partnerId][msg.sender].effectivePowerUsedOnThis;
        }

        uint256 maxAvailablePower = voterBasePower - powerUsedOnPartner;
        require(powerToUse <= maxAvailablePower, "Power to use exceeds available power (base power minus power used on entangled partner)");
        require(powerToUse > 0, "Power to use must be greater than 0"); // Require casting > 0 power

        VoterState storage voterState = voterStates[proposalId][msg.sender];

        // Remove previously allocated power from total counts if voter is changing vote/power
        if (voterState.hasVoted) {
            if (voterState.voteType == VoteType.For) {
                proposal.totalEffectivePowerFor -= voterState.effectivePowerUsedOnThis;
            } else if (voterState.voteType == VoteType.Against) {
                proposal.totalEffectivePowerAgainst -= voterState.effectivePowerUsedOnThis;
            } else if (voterState.voteType == VoteType.Abstain) {
                proposal.totalEffectivePowerAbstain -= voterState.effectivePowerUsedOnThis;
            }
        }

        // Update voter state
        voterState.hasVoted = true;
        voterState.voteType = voteType;
        voterState.effectivePowerUsedOnThis = powerToUse;

        // Add newly allocated power to total counts
        if (voteType == VoteType.For) {
            proposal.totalEffectivePowerFor += powerToUse;
        } else if (voteType == VoteType.Against) {
            proposal.totalEffectivePowerAgainst += powerToUse;
        } else if (voteType == VoteType.Abstain) {
            proposal.totalEffectivePowerAbstain += powerToUse;
        }

        emit VoteCast(proposalId, msg.sender, voteType, powerToUse);
    }

    /**
     * @dev Allows a voter to change their vote and/or power allocation for an active proposal.
     * This is effectively just calling castVote again with potentially different parameters.
     * Included for clarity and function count.
     * @param proposalId The ID of the proposal.
     * @param newVoteType The new type of vote.
     * @param newPowerToUse The new amount of effective power to commit.
     */
     function changeVote(uint256 proposalId, VoteType newVoteType, uint256 newPowerToUse) external proposalMustExist(proposalId) {
         VoterState storage voterState = voterStates[proposalId][msg.sender];
         require(voterState.hasVoted, "Cannot change vote, no vote cast yet"); // Ensure they voted at least once
         // The core logic for validity and update is handled by castVote
         castVote(proposalId, newVoteType, newPowerToUse);
         // Note: VoteCast event is emitted by castVote
     }


    // --- Outcome & State Transition Functions ---

    /**
     * @dev Closes the voting period for a proposal if the end time has passed.
     * Can be called by anyone.
     * @param proposalId The ID of the proposal to close.
     */
    function closeVotingPeriod(uint256 proposalId) external proposalMustExist(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Active, "Proposal is not Active");
        require(block.timestamp >= proposal.endTime, "Voting period has not ended yet");

        proposal.state = ProposalState.Closed;

        // Entangled partner is also closed if active
        uint256 partnerId = entangledProposals[proposalId];
         if (partnerId != 0) {
             Proposal storage partnerProposal = proposals[partnerId];
             if(partnerProposal.state == ProposalState.Active) {
                 partnerProposal.state = ProposalState.Closed;
                 emit ProposalClosed(partnerId, calculateOutcome(partnerId)); // Emit for partner too
             }
         }

        emit ProposalClosed(proposalId, calculateOutcome(proposalId));
    }

    /**
     * @dev Internal function to calculate the winning vote type for a closed proposal.
     * Determined by a simple majority of total effective power between For and Against.
     * Abstain power is counted but does not directly influence the For/Against outcome.
     * @param proposalId The ID of the proposal.
     * @return The winning VoteType (For, Against, or None if tied or not Closed/Executed).
     */
    function calculateOutcome(uint256 proposalId) internal view proposalMustExist(proposalId) returns (VoteType) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Closed || proposal.state == ProposalState.Executed, "Outcome can only be calculated for Closed or Executed proposals");

        if (proposal.totalEffectivePowerFor > proposal.totalEffectivePowerAgainst) {
            return VoteType.For;
        } else if (proposal.totalEffectivePowerAgainst > proposal.totalEffectivePowerFor) {
            return VoteType.Against;
        } else {
            // Tie or zero votes For/Against
            return VoteType.None; // Representing no clear majority outcome
        }
    }

    /**
     * @dev Placeholder function to simulate executing a proposal.
     * Marks a Closed proposal as Executed if it passed (outcome is For).
     * In a real system, this would trigger governance actions.
     * Can be called by anyone after closing.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) external proposalMustExist(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Closed, "Proposal must be Closed to be Executed");

        // Determine outcome
        VoteType outcome = calculateOutcome(proposalId);

        // Only 'For' votes lead to execution in this simplified model
        if (outcome == VoteType.For) {
             proposal.state = ProposalState.Executed;
             // In a real scenario, add logic here to perform the governance action
             // e.g., call another contract, transfer tokens, etc.
             // require(external_governance_contract.execute(proposal.id), "Execution failed");
             emit ProposalExecuted(proposalId);
        } else {
            // If outcome is Against or None (tie), it's not executed but still stays Closed
            // We could transition to another state like 'Rejected', but Closed is sufficient here.
        }
    }


    // --- View Functions ---

    /**
     * @dev Returns the total number of proposals created.
     */
    function getProposalCount() external view returns (uint256) {
        return proposalCounter;
    }

    /**
     * @dev Returns details of a specific proposal.
     * @param proposalId The ID of the proposal.
     * @return Proposal struct containing all details.
     */
    function getProposal(uint256 proposalId) external view proposalMustExist(proposalId) returns (Proposal memory) {
        return proposals[proposalId];
    }

    /**
     * @dev Returns the ID of the proposal entangled with the given proposal.
     * Returns 0 if the proposal is not entangled.
     * @param proposalId The ID of the proposal.
     * @return The ID of the entangled partner, or 0.
     */
    function getEntangledPartner(uint256 proposalId) external view returns (uint256) {
        // No need for proposalMustExist here, returns 0 for non-existent or non-entangled
        return entangledProposals[proposalId];
    }

    /**
     * @dev Returns the base voting power assigned to an address.
     * @param voter The address of the voter.
     * @return The base voting power amount.
     */
    function getBaseVotingPower(address voter) external view returns (uint256) {
        return baseVotingPower[voter];
    }

    /**
     * @dev Returns the voting state of a specific voter on a specific proposal.
     * @param proposalId The ID of the proposal.
     * @param voter The address of the voter.
     * @return VoterState struct.
     */
    function getVoterStateForProposal(uint256 proposalId, address voter) external view proposalMustExist(proposalId) returns (VoterState memory) {
        return voterStates[proposalId][voter];
    }

    /**
     * @dev Calculates the maximum effective power a voter can currently use on a specific proposal.
     * This is their base power minus the effective power they have already committed to
     * its entangled partner (if any).
     * @param proposalId The ID of the proposal.
     * @param voter The address of the voter.
     * @return The maximum effective power available for this specific vote.
     */
    function getAvailablePowerForVote(uint256 proposalId, address voter) external view proposalMustExist(proposalId) returns (uint256) {
        uint256 voterBasePower = baseVotingPower[voter];
        if (voterBasePower == 0) {
            return 0;
        }

        uint256 powerUsedOnPartner = 0;
        uint256 partnerId = entangledProposals[proposalId];

        if (partnerId != 0) {
             // Check if the partner proposal exists before accessing voterStates
             if (partnerId > 0 && partnerId <= proposalCounter) {
                 powerUsedOnPartner = voterStates[partnerId][voter].effectivePowerUsedOnThis;
             }
        }

        // Ensure no underflow if somehow powerUsedOnPartner > voterBasePower (shouldn't happen with castVote logic)
        return voterBasePower >= powerUsedOnPartner ? voterBasePower - powerUsedOnPartner : 0;
    }

    /**
     * @dev Returns the calculated outcome of a proposal.
     * Can only be called for Closed or Executed proposals.
     * @param proposalId The ID of the proposal.
     * @return The winning VoteType (For, Against, or None).
     */
    function getProposalOutcome(uint256 proposalId) external view proposalMustExist(proposalId) returns (VoteType) {
        return calculateOutcome(proposalId);
    }

     /**
     * @dev Returns the current state of a proposal.
     * @param proposalId The ID of the proposal.
     * @return The ProposalState enum value.
     */
    function getProposalState(uint256 proposalId) external view proposalMustExist(proposalId) returns (ProposalState) {
        return proposals[proposalId].state;
    }
}
```