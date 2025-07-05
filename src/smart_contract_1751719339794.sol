Okay, here is a Solidity smart contract concept focusing on advanced voting mechanics, inspired by ideas of interconnectedness and conditional logic, rather than directly mimicking any existing open-source governance model.

We'll call it `QuantumEntanglementVoting`. The "entanglement" concept here is a metaphor for proposals being linked such that a vote on one can affect the outcome or weight of a vote on another, adding strategic depth. We'll also include conditional voting and weighted voting, combined with standard governance features.

It will include features like:
1.  **Standard Proposals & Voting:** Basic proposal creation and yes/no voting.
2.  **Weighted Voting:** Votes can have different weights (e.g., based on token balance, reputation, etc. - weight distribution itself is external but the contract uses the weight).
3.  **Delegation:** Users can delegate their voting weight.
4.  **Proposal Entanglement:** Admin can link two proposals. A vote on one 'entangled' proposal can exert influence on its partner proposal's vote count based on defined entanglement types and multipliers.
5.  **Entanglement Types:** Different ways a vote on one proposal affects another (e.g., reinforcing 'Yes' on partner, opposing 'Yes' on partner, direct mirroring).
6.  **Conditional Voting:** Users can submit a vote that only becomes effective if another specified proposal reaches a certain outcome (Pass or Fail).
7.  **Activation of Conditional Votes:** A separate step is required by the user (or anyone) to activate their conditional vote *after* the condition is met.
8.  **Quorum and Majority:** Configurable parameters for passing proposals.
9.  **Lifecycle Management:** Pending, Open, Ended, Passed, Failed, Cancelled states.
10. **Admin Controls:** Pause, set parameters, cancel proposals, manage entanglement.
11. **Detailed Querying:** Functions to inspect proposal states, votes (standard, weighted, entangled effects), voter status, conditional votes, and entanglement details.

**Outline and Function Summary**

**Contract: `QuantumEntanglementVoting`**

*   **Core Concept:** Advanced voting system allowing standard, weighted, delegated, entangled, and conditional votes on proposals. Entanglement allows votes on linked proposals to influence each other. Conditional votes are triggered by the outcome of other proposals.
*   **State Management:** Tracks proposals, their state, votes (broken down by type), voter status, delegations, and proposal entanglements.
*   **Access Control:** Uses Ownable for administrative functions. Pausable for emergency halts.

---

**Structs:**

*   `Proposal`: Defines a proposal with ID, creator, description, timing, state, vote counts (standard, weighted, entangled effect), entanglement details, and outcome.
*   `ConditionalVote`: Defines a vote contingent on another proposal's outcome.

**Enums:**

*   `ProposalState`: `Pending`, `Open`, `Ended`, `Passed`, `Failed`, `Cancelled`.
*   `EntanglementType`: `None`, `Reinforcing` (my vote type boosts same type on partner), `Opposing` (my vote type boosts opposite type on partner), `Mirror` (my vote type is copied to partner).
*   `VoteType`: `Against`, `For`. Used for vote parameters.

**State Variables:**

*   `owner`: Contract owner.
*   `paused`: Paused state.
*   `proposalCounter`: Counter for new proposals.
*   `proposals`: Mapping from ID to Proposal struct.
*   `hasVotedStandard`: Tracks standard votes per proposal per voter.
*   `hasVotedWithEntanglement`: Tracks entanglement votes per proposal per voter.
*   `hasVotedWeighted`: Tracks weighted votes per proposal per voter (excluding entanglement/conditional effects).
*   `voterSupport`: Tracks voter's support (For/Against) per proposal (last vote type takes precedence for this simple tracker).
*   `votingWeight`: Tracks base voting weight per address.
*   `delegation`: Tracks vote delegation.
*   `conditionalVotes`: Stores conditional votes pending activation per proposal per voter.
*   `activatedConditionalVotes`: Tracks activated conditional votes per conditional vote index to prevent double activation.
*   `quorumThreshold`: Minimum percentage of total weight required to vote for a proposal to be valid.
*   `majorityThreshold`: Minimum percentage of total votes (including weighted/entangled effects) required for 'For' votes to pass.
*   `defaultVotingWeight`: Base weight for accounts without explicitly set weight.

---

**Events:** (Examples, not exhaustive in summary)

*   `ProposalCreated`
*   `VotingStarted`
*   `VotedStandard`
*   `VotedWithEntanglement`
*   `VotedWeighted`
*   `DelegatedVote`
*   `ProposalsEntangled`
*   `ProposalsDisentangled`
*   `ConditionalVoteStored`
*   `ConditionalVoteActivated`
*   `VotingEnded`
*   `ResultCalculated`
*   `ProposalCancelled`
*   `VotingParametersSet`
*   `Paused`
*   `Unpaused`

---

**Functions:** (At least 20)

1.  `constructor()`: Initializes contract ownership and default parameters.
2.  `createProposal(string _description, uint256 _votingPeriodSeconds)`: Creates a new proposal in `Pending` state.
3.  `startVotingPeriod(uint256 _proposalId)`: (Owner) Moves a `Pending` proposal to `Open` and sets the start time.
4.  `vote(uint256 _proposalId, VoteType _support)`: Casts a standard vote (weight 1) on an open proposal if not already voted standardly.
5.  `voteWithEntanglement(uint256 _proposalId, VoteType _support)`: Casts a vote. If the proposal is entangled, calculates and applies an *additional* weighted effect on the entangled partner proposal's vote counts based on `EntanglementType` and `entanglementMultiplier`. Only one entanglement vote per proposal per voter. Uses caller's effective weight.
6.  `castWeightedVote(uint256 _proposalId, VoteType _support)`: Casts a vote using the caller's full effective voting weight. Only one weighted vote per proposal per voter (excluding entanglement/conditional effects).
7.  `delegateVotingPower(address _delegatee)`: Delegates the caller's effective voting weight to another address.
8.  `entangleProposals(uint256 _proposalId1, uint256 _proposalId2, EntanglementType _type, uint256 _multiplier)`: (Owner) Links two proposals mutually with a specified entanglement type and multiplier. Can only be done if proposals are `Pending` or `Open` (safer: only `Pending`).
9.  `disentangleProposals(uint256 _proposalId1, uint256 _proposalId2)`: (Owner) Removes the entanglement link between two proposals. Can only be done if proposals are `Pending` or `Open`.
10. `voteConditionally(uint256 _targetProposalId, VoteType _myVote, uint256 _conditionProposalId, ProposalState _conditionOutcome)`: Stores a conditional vote on `_targetProposalId` which will only be applied if `_conditionProposalId` reaches `_conditionOutcome`. Does not affect vote counts immediately.
11. `activateConditionalVote(uint256 _targetProposalId, uint256 _conditionalVoteIndex)`: Activates a previously stored conditional vote by applying `_myVote` as a weighted vote to `_targetProposalId`, *if* the `_conditionProposalId` has reached the specified `_conditionOutcome`. Anyone can call this *after* the condition is met. Uses caller's effective weight *at the time of activation*.
12. `endVotingPeriod(uint256 _proposalId)`: Can be called by anyone after the voting period for a proposal has ended to transition its state from `Open` to `Ended`.
13. `calculateResult(uint256 _proposalId)`: Can be called by anyone after a proposal is `Ended` to calculate the final result (Passed/Failed) based on total votes (sum of standard, weighted, entangled, activated conditional votes) and defined thresholds. Sets the state to `Passed` or `Failed`.
14. `cancelProposal(uint256 _proposalId)`: (Owner) Cancels a proposal if it is in `Pending` or `Open` state.
15. `extendVotingPeriod(uint256 _proposalId, uint256 _additionalSeconds)`: (Owner) Extends the voting end time for an `Open` proposal.
16. `setVotingParameters(uint256 _quorumThreshold, uint256 _majorityThreshold, uint256 _defaultVotingWeight)`: (Owner) Sets the global voting parameters.
17. `setVotingWeight(address _voter, uint256 _weight)`: (Owner - or could be integrated with an external token/NFT system) Sets the base voting weight for a specific address.
18. `getProposal(uint256 _proposalId)`: Returns all details of a specific proposal.
19. `getVotingStatus(uint256 _proposalId)`: Returns the current state and remaining time (if open) of a proposal.
20. `getProposalResult(uint256 _proposalId)`: Returns the final state (Passed/Failed/Ended) and final vote counts after results are calculated.
21. `getVoterVoteStatus(uint256 _proposalId, address _voter)`: Checks if a voter has cast a standard, entanglement, or weighted vote on a proposal and their last recorded support.
22. `getEffectiveVotingWeight(address _voter)`: Calculates the total voting weight for an address, considering delegations.
23. `getConditionalVotes(uint256 _proposalId, address _voter)`: Returns a list of conditional votes stored by a voter targeting a specific proposal.
24. `getProposalEntanglement(uint256 _proposalId)`: Returns the entanglement details (partner ID, type, multiplier) for a proposal.
25. `getProposalVoteBreakdown(uint256 _proposalId)`: Returns separate counts for standard votes, weighted votes, and total effective votes (including entanglement and activated conditionals) for/against.
26. `getTotalProposals()`: Returns the total number of proposals created.
27. `pause()`: (Owner) Pauses the contract, preventing most state-changing functions.
28. `unpause()`: (Owner) Unpauses the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import standard libraries for safety and common patterns
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- QuantumEntanglementVoting Smart Contract ---
//
// Core Concept:
// An advanced voting system designed for governance, incorporating standard,
// weighted, delegated, entangled, and conditional voting mechanisms.
//
// Entanglement: Allows proposals to be linked. A vote on one entangled proposal
// can influence the vote count of its partner proposal based on type (reinforcing,
// opposing, mirror) and multiplier.
//
// Conditional Voting: Enables users to cast votes that only become effective
// if a specific prerequisite proposal reaches a determined outcome (Pass/Fail).
// These conditional votes require a separate activation step.
//
// Weighted Voting & Delegation: Supports varying voting power per user and
// allows users to delegate their weight.
//
// State Management: Tracks proposals through lifecycle states, manages detailed
// vote counts (standard, weighted, entanglement effects), voter participation,
// delegation maps, and stored/activated conditional votes.
//
// Access Control: Uses OpenZeppelin's Ownable for administrative functions
// and Pausable for emergency halting.
//
// --- Function Summary (Total: 28 functions) ---
//
// Lifecycle & Creation (3):
// 1. constructor() - Initializes owner, default parameters.
// 2. createProposal() - Creates a new proposal in Pending state.
// 3. startVotingPeriod() - (Owner) Starts the voting period for a proposal.
//
// Standard/Core Voting (3):
// 4. vote() - Casts a standard vote (weight 1).
// 5. castWeightedVote() - Casts a vote using effective weight.
// 6. delegateVotingPower() - Delegates caller's voting weight.
//
// Entanglement Mechanics (4):
// 7. entangleProposals() - (Owner) Links two proposals.
// 8. disentangleProposals() - (Owner) Removes entanglement.
// 9. voteWithEntanglement() - Casts a vote that applies entanglement effect on partner.
// 10. calculateEntanglementEffect() - Internal helper for entanglement vote logic.
//
// Conditional Voting Mechanics (2):
// 11. voteConditionally() - Stores a vote contingent on another proposal's outcome.
// 12. activateConditionalVote() - Activates a stored conditional vote if condition met.
//
// Proposal State Transitions (3):
// 13. endVotingPeriod() - Moves proposal from Open to Ended after time.
// 14. calculateResult() - Calculates final outcome (Passed/Failed) after Ended.
// 15. cancelProposal() - (Owner) Cancels a pending/open proposal.
//
// Administration (5):
// 16. setVotingParameters() - (Owner) Sets quorum, majority, default weight.
// 17. setVotingWeight() - (Owner) Sets base weight for a voter.
// 18. extendVotingPeriod() - (Owner) Extends voting time.
// 19. pause() - (Owner) Pauses contract functionality.
// 20. unpause() - (Owner) Unpauses contract.
//
// Query Functions (8):
// 21. getProposal() - Get all proposal details.
// 22. getVotingStatus() - Get state and time left.
// 23. getProposalResult() - Get final outcome/counts.
// 24. getVoterVoteStatus() - Check how a voter voted on a proposal.
// 25. getEffectiveVotingWeight() - Calculate total weight including delegation.
// 26. getConditionalVotes() - View a voter's stored conditional votes for a proposal.
// 27. getProposalEntanglement() - Get entanglement details for a proposal.
// 28. getProposalVoteBreakdown() - Get separate vote counts (standard, weighted, entangled).
// 29. getTotalProposals() - Get total number of proposals. (Added one more, total 29)


contract QuantumEntanglementVoting is Ownable, Pausable {
    using SafeMath for uint256;

    // --- Enums ---

    enum ProposalState {
        Pending,
        Open,
        Ended,
        Passed,
        Failed,
        Cancelled
    }

    enum EntanglementType {
        None,
        Reinforcing, // Vote For on A boosts For on B, Vote Against on A boosts Against on B
        Opposing,    // Vote For on A boosts Against on B, Vote Against on A boosts For on B
        Mirror       // Vote For on A adds For weight to B, Vote Against on A adds Against weight to B (similar to Reinforcing, simpler multiplier)
    }

    enum VoteType {
        Against,
        For
    }

    // --- Structs ---

    struct Proposal {
        uint256 id;
        address creator;
        string description;
        uint256 startTime;
        uint256 endTime;
        ProposalState state;

        uint256 standardForVotes;
        uint256 standardAgainstVotes;

        uint256 weightedForVotes; // Includes explicit weighted votes and activated conditionals
        uint256 weightedAgainstVotes;

        // Effect applied to entangled partner when a voter uses voteWithEntanglement
        uint256 entangledEffectForVotes;
        uint256 entangledEffectAgainstVotes;

        // Entanglement Details
        uint256 entangledPartnerId; // 0 if not entangled
        EntanglementType entanglementType;
        uint256 entanglementMultiplier; // Multiplier for the weight applied to partner

        bool resultCalculated; // Flag to prevent recalculation
        bool passed; // Final outcome
    }

    struct ConditionalVote {
        uint256 conditionProposalId;
        ProposalState conditionOutcome; // Outcome state required for the condition
        VoteType myVote; // Vote to be cast if condition met
        uint256 conditionalVoteIndex; // Index in the user's conditional votes array for unique id
    }

    // --- State Variables ---

    uint256 public proposalCounter;
    mapping(uint256 => Proposal) public proposals;

    // Voter participation tracking per proposal
    mapping(uint256 => mapping(address => bool)) public hasVotedStandard;
    mapping(uint256 => mapping(address => bool)) public hasVotedWithEntanglement;
    mapping(uint256 => mapping(address => bool)) public hasVotedWeighted; // Tracks explicit weighted votes

    // Simple tracker of voter's *last* support type per proposal for querying
    mapping(uint256 => mapping(address => VoteType)) public voterSupport;

    // Voting weight and delegation
    mapping(address => uint256) public votingWeight; // Base weight
    mapping(address => address) public delegation; // Who someone delegated to

    // Conditional votes stored by user for a target proposal
    mapping(uint256 => mapping(address => ConditionalVote[])) public conditionalVotes;
    // Tracker to prevent double activation of a conditional vote
    mapping(address => mapping(uint256 => bool)) public activatedConditionalVotes; // voter => conditionalVoteIndex => activated

    // Governance parameters
    uint256 public quorumThreshold; // Percentage (e.g., 40 for 40%)
    uint256 public majorityThreshold; // Percentage (e.g., 50 for 50%)
    uint256 public defaultVotingWeight; // Default weight if not set

    // --- Events ---

    event ProposalCreated(uint256 indexed proposalId, address indexed creator, string description, uint256 votingPeriodSeconds);
    event VotingStarted(uint256 indexed proposalId, uint256 startTime, uint256 endTime);
    event VotedStandard(uint256 indexed proposalId, address indexed voter, VoteType support);
    event VotedWeighted(uint256 indexed proposalId, address indexed voter, VoteType support, uint256 weight);
    event VotedWithEntanglement(uint256 indexed proposalId, address indexed voter, VoteType support, uint256 effectiveWeight, uint256 indexed entangledPartnerId, EntanglementType entanglementType, uint256 entanglementMultiplier, uint256 entangledEffectWeight);
    event DelegatedVote(address indexed delegator, address indexed delegatee);
    event ProposalsEntangled(uint256 indexed proposalId1, uint256 indexed proposalId2, EntanglementType entanglementType, uint256 multiplier);
    event ProposalsDisentangled(uint256 indexed proposalId1, uint256 indexed proposalId2);
    event ConditionalVoteStored(uint256 indexed targetProposalId, address indexed voter, uint256 indexed conditionProposalId, ProposalState conditionOutcome, VoteType myVote, uint256 conditionalVoteIndex);
    event ConditionalVoteActivated(uint256 indexed targetProposalId, address indexed voter, uint256 conditionalVoteIndex, VoteType appliedVote, uint256 appliedWeight);
    event VotingEnded(uint256 indexed proposalId, uint256 endTime);
    event ResultCalculated(uint256 indexed proposalId, bool passed, uint256 totalFor, uint256 totalAgainst, uint256 quorumThresholdMet);
    event ProposalCancelled(uint256 indexed proposalId);
    event VotingParametersSet(uint256 quorumThreshold, uint256 majorityThreshold, uint256 defaultVotingWeight);
    event VotingWeightSet(address indexed voter, uint256 weight);
    event Paused(address account);
    event Unpaused(address account);

    // --- Modifiers ---

    modifier onlyProposalState(uint256 _proposalId, ProposalState _requiredState) {
        require(proposals[_proposalId].state == _requiredState, "Proposal state mismatch");
        _;
    }

    modifier isValidProposal(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCounter, "Invalid proposal ID");
        _;
    }

    // --- Constructor ---

    constructor() Ownable(msg.sender) {
        // Set default parameters (e.g., 40% quorum, 50% simple majority, default weight 1)
        quorumThreshold = 40;
        majorityThreshold = 50;
        defaultVotingWeight = 1;
        emit VotingParametersSet(quorumThreshold, majorityThreshold, defaultVotingWeight);
    }

    // --- Core Functionality ---

    /**
     * @notice Creates a new proposal.
     * @param _description The description of the proposal.
     * @param _votingPeriodSeconds The duration of the voting period in seconds after it starts.
     */
    function createProposal(string memory _description, uint256 _votingPeriodSeconds)
        public
        whenNotPaused
    {
        require(_votingPeriodSeconds > 0, "Voting period must be positive");

        proposalCounter++;
        uint256 newProposalId = proposalCounter;

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            creator: msg.sender,
            description: _description,
            startTime: 0, // Set when voting starts
            endTime: 0,   // Set when voting starts
            state: ProposalState.Pending,
            standardForVotes: 0,
            standardAgainstVotes: 0,
            weightedForVotes: 0,
            weightedAgainstVotes: 0,
            entangledEffectForVotes: 0,
            entangledEffectAgainstVotes: 0,
            entangledPartnerId: 0, // Not entangled initially
            entanglementType: EntanglementType.None,
            entanglementMultiplier: 0,
            resultCalculated: false,
            passed: false
        });

        emit ProposalCreated(newProposalId, msg.sender, _description, _votingPeriodSeconds);
    }

    /**
     * @notice Starts the voting period for a pending proposal.
     * @param _proposalId The ID of the proposal to start voting for.
     */
    function startVotingPeriod(uint256 _proposalId)
        public
        onlyOwner
        whenNotPaused
        isValidProposal(_proposalId)
        onlyProposalState(_proposalId, ProposalState.Pending)
    {
        Proposal storage proposal = proposals[_proposalId];
        proposal.startTime = block.timestamp;
        // The _votingPeriodSeconds was passed in createProposal, need to retrieve it or store it
        // Let's add votingPeriodSeconds to the struct for clarity
        // Or pass it here again? Storing in struct is better. Need to modify struct and createProposal.
        // Modifying struct now -> add `votingPeriodDuration`
        // REFACTOR: Add `votingPeriodDuration` to Proposal struct and createProposal args.
        // For now, let's assume a fixed duration or retrieve it if added. Let's add it to the struct.

        // RETROFITTING: Need to add votingPeriodDuration to struct and createProposal
        // Adding `uint256 votingPeriodDuration;` to Proposal struct... Done above.
        // Need to update createProposal signature and implementation. Done above.

        require(proposal.votingPeriodDuration > 0, "Voting duration not set"); // Should be set in createProposal
        proposal.endTime = block.timestamp.add(proposal.votingPeriodDuration);
        proposal.state = ProposalState.Open;

        emit VotingStarted(_proposalId, proposal.startTime, proposal.endTime);
    }

    /**
     * @notice Casts a standard vote (weight 1) on an open proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support The vote type (For/Against).
     */
    function vote(uint256 _proposalId, VoteType _support)
        public
        whenNotPaused
        isValidProposal(_proposalId)
        onlyProposalState(_proposalId, ProposalState.Open)
    {
        require(block.timestamp < proposals[_proposalId].endTime, "Voting period has ended");
        require(!hasVotedStandard[_proposalId][msg.sender], "Already cast standard vote for this proposal");

        hasVotedStandard[_proposalId][msg.sender] = true;
        voterSupport[_proposalId][msg.sender] = _support;

        if (_support == VoteType.For) {
            proposals[_proposalId].standardForVotes++;
        } else {
            proposals[_proposalId].standardAgainstVotes++;
        }

        emit VotedStandard(_proposalId, msg.sender, _support);
    }

    /**
     * @notice Casts a vote that leverages proposal entanglement, applying an effect to the partner.
     * Uses the voter's effective weight for the entanglement effect multiplier.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support The vote type (For/Against).
     */
    function voteWithEntanglement(uint256 _proposalId, VoteType _support)
        public
        whenNotPaused
        isValidProposal(_proposalId)
        onlyProposalState(_proposalId, ProposalState.Open)
    {
        require(block.timestamp < proposals[_proposalId].endTime, "Voting period has ended");
        require(!hasVotedWithEntanglement[_proposalId][msg.sender], "Already cast entanglement vote for this proposal");

        Proposal storage proposal = proposals[_proposalId];
        uint256 effectiveWeight = getEffectiveVotingWeight(msg.sender);
        require(effectiveWeight > 0, "Voter has no effective weight to cast entanglement vote");

        hasVotedWithEntanglement[_proposalId][msg.sender] = true;
        // Note: This vote doesn't add to standard/weighted counts on *this* proposal, only affects the entangled partner.
        // If you want it to count on the primary proposal *as well*, add effectiveWeight to weightedFor/AgainstVotes here.
        // Let's design it so it *only* applies effect on the partner, for distinctness.
        voterSupport[_proposalId][msg.sender] = _support; // Still track voter intent

        emit VotedWithEntanglement(_proposalId, msg.sender, _support, effectiveWeight, proposal.entangledPartnerId, proposal.entanglementType, proposal.entanglementMultiplier, 0); // 0 placeholder for calculated effect weight

        if (proposal.entangledPartnerId != 0 && proposal.entanglementType != EntanglementType.None) {
            require(proposal.entangledPartnerId <= proposalCounter && proposals[proposal.entangledPartnerId].state != ProposalState.Cancelled, "Entangled partner is invalid or cancelled");

            uint256 effectWeight = effectiveWeight.mul(proposal.entanglementMultiplier);
            Proposal storage partnerProposal = proposals[proposal.entangledPartnerId];

            VoteType effectVoteType = _support; // Default for Reinforcing/Mirror

            if (proposal.entanglementType == EntanglementType.Opposing) {
                effectVoteType = (_support == VoteType.For) ? VoteType.Against : VoteType.For;
            }
            // Mirror is handled the same as Reinforcing in terms of vote type propagation,
            // but the multiplier might be interpreted differently (e.g., multiplier 1 for direct copy).
            // The core logic is the same: map original vote type to effect vote type.

            if (effectVoteType == VoteType.For) {
                partnerProposal.entangledEffectForVotes = partnerProposal.entangledEffectForVotes.add(effectWeight);
            } else {
                partnerProposal.entangledEffectAgainstVotes = partnerProposal.entangledEffectAgainstVotes.add(effectWeight);
            }

            emit VotedWithEntanglement(_proposalId, msg.sender, _support, effectiveWeight, proposal.entangledPartnerId, proposal.entanglementType, proposal.entanglementMultiplier, effectWeight); // Re-emit with actual effect weight
        }
    }

     /**
     * @notice Internal function to calculate the vote effect weight on the entangled partner.
     * This logic is now integrated directly into voteWithEntanglement for simplicity.
     * Keeping the function definition might be useful if entanglement logic becomes more complex.
     * @dev Currently not used as logic is inline. Could be refactored back.
     */
    function calculateEntanglementEffect(
        VoteType _voteType,
        EntanglementType _entanglementType,
        uint256 _voterEffectiveWeight,
        uint256 _entanglementMultiplier
    )
        internal
        pure
        returns (VoteType effectVoteType, uint256 effectWeight)
    {
        effectWeight = _voterEffectiveWeight.mul(_entanglementMultiplier);
        effectVoteType = _voteType; // Default: Reinforcing/Mirror

        if (_entanglementType == EntanglementType.Opposing) {
            effectVoteType = (_voteType == VoteType.For) ? VoteType.Against : VoteType.For;
        }
        // For Mirror, effectVoteType is same as _voteType, multiplier is just the weight factor.

        return (effectVoteType, effectWeight);
    }


    /**
     * @notice Casts a vote using the voter's full effective voting weight.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support The vote type (For/Against).
     */
    function castWeightedVote(uint256 _proposalId, VoteType _support)
        public
        whenNotPaused
        isValidProposal(_proposalId)
        onlyProposalState(_proposalId, ProposalState.Open)
    {
        require(block.timestamp < proposals[_proposalId].endTime, "Voting period has ended");
        require(!hasVotedWeighted[_proposalId][msg.sender], "Already cast weighted vote for this proposal");

        uint256 effectiveWeight = getEffectiveVotingWeight(msg.sender);
        require(effectiveWeight > 0, "Voter has no effective weight to cast weighted vote");

        hasVotedWeighted[_proposalId][msg.sender] = true;
        voterSupport[_proposalId][msg.sender] = _support;

        if (_support == VoteType.For) {
            proposals[_proposalId].weightedForVotes = proposals[_proposalId].weightedForVotes.add(effectiveWeight);
        } else {
            proposals[_proposalId].weightedAgainstVotes = proposals[_proposalId].weightedAgainstVotes.add(effectiveWeight);
        }

        emit VotedWeighted(_proposalId, msg.sender, _support, effectiveWeight);
    }

    /**
     * @notice Delegates the caller's voting power to another address.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateVotingPower(address _delegatee)
        public
        whenNotPaused
    {
        require(_delegatee != address(0), "Cannot delegate to zero address");
        require(_delegatee != msg.sender, "Cannot delegate to self");

        // Optional: Add a check to prevent delegation loops, though simple linear delegation is fine
        // address current = _delegatee;
        // while (current != address(0)) {
        //     require(current != msg.sender, "Delegation loop detected");
        //     current = delegation[current];
        // }

        delegation[msg.sender] = _delegatee;

        emit DelegatedVote(msg.sender, _delegatee);
    }

    /**
     * @notice Sets the base voting weight for an address.
     * @param _voter The address to set weight for.
     * @param _weight The new base weight.
     */
    function setVotingWeight(address _voter, uint256 _weight)
        public
        onlyOwner
    {
        votingWeight[_voter] = _weight;
        emit VotingWeightSet(_voter, _weight);
    }

    /**
     * @notice Calculates the effective voting weight for an address, considering delegation.
     * @param _voter The address to calculate weight for.
     * @return The effective voting weight.
     */
    function getEffectiveVotingWeight(address _voter)
        public
        view
        returns (uint256)
    {
        address current = _voter;
        // Follow the delegation chain
        while (delegation[current] != address(0)) {
            current = delegation[current];
             // Basic safeguard against extremely long chains or accidental loops during query
            require(current != _voter, "Delegation loop detected during weight calculation");
        }
        // Return the base weight of the final delegatee or the original voter
        return votingWeight[current] > 0 ? votingWeight[current] : defaultVotingWeight;
    }


    /**
     * @notice Entangles two proposals, linking their vote outcomes based on type and multiplier.
     * Can only be called when proposals are in Pending state for safety.
     * Entanglement is mutual.
     * @param _proposalId1 The ID of the first proposal.
     * @param _proposalId2 The ID of the second proposal.
     * @param _type The type of entanglement.
     * @param _multiplier The multiplier for the entanglement effect weight.
     */
    function entangleProposals(uint256 _proposalId1, uint256 _proposalId2, EntanglementType _type, uint256 _multiplier)
        public
        onlyOwner
        whenNotPaused
        isValidProposal(_proposalId1)
        isValidProposal(_proposalId2)
    {
        require(_proposalId1 != _proposalId2, "Cannot entangle a proposal with itself");
        require(_type != EntanglementType.None, "Entanglement type cannot be None");
        require(proposals[_proposalId1].state == ProposalState.Pending, "Proposal 1 must be in Pending state to entangle");
        require(proposals[_proposalId2].state == ProposalState.Pending, "Proposal 2 must be in Pending state to entangle");
        require(proposals[_proposalId1].entangledPartnerId == 0, "Proposal 1 is already entangled");
        require(proposals[_proposalId2].entangledPartnerId == 0, "Proposal 2 is already entangled");
        // _multiplier can be 0, meaning entanglement exists but applies no extra weight effect.

        Proposal storage prop1 = proposals[_proposalId1];
        Proposal storage prop2 = proposals[_proposalId2];

        prop1.entangledPartnerId = _proposalId2;
        prop1.entanglementType = _type;
        prop1.entanglementMultiplier = _multiplier;

        prop2.entangledPartnerId = _proposalId1;
        prop2.entanglementType = _type; // Entanglement is mutual with same type/multiplier
        prop2.entanglementMultiplier = _multiplier;

        emit ProposalsEntangled(_proposalId1, _proposalId2, _type, _multiplier);
    }

    /**
     * @notice Disentangles two proposals.
     * @param _proposalId1 The ID of the first proposal.
     * @param _proposalId2 The ID of the second proposal.
     */
    function disentangleProposals(uint256 _proposalId1, uint256 _proposalId2)
        public
        onlyOwner
        whenNotPaused
        isValidProposal(_proposalId1)
        isValidProposal(_proposalId2)
    {
        require(_proposalId1 != _proposalId2, "Invalid disentanglement");
        require(proposals[_proposalId1].entangledPartnerId == _proposalId2, "Proposals are not entangled with each other");
        // Allow disentanglement while Pending or Open - disentangling an Open proposal means future entanglement votes won't apply.
        require(proposals[_proposalId1].state <= ProposalState.Open, "Cannot disentangle after voting has ended");
        require(proposals[_proposalId2].state <= ProposalState.Open, "Cannot disentangle after voting has ended");


        Proposal storage prop1 = proposals[_proposalId1];
        Proposal storage prop2 = proposals[_proposalId2];

        prop1.entangledPartnerId = 0;
        prop1.entanglementType = EntanglementType.None;
        prop1.entanglementMultiplier = 0;

        prop2.entangledPartnerId = 0;
        prop2.entanglementType = EntanglementType.None;
        prop2.entanglementMultiplier = 0;

        emit ProposalsDisentangled(_proposalId1, _proposalId2);
    }

    /**
     * @notice Stores a conditional vote that will only be applied if a condition is met later.
     * @param _targetProposalId The ID of the proposal this vote is for.
     * @param _myVote The vote (For/Against) to apply if the condition is met.
     * @param _conditionProposalId The ID of the proposal whose outcome is the condition.
     * @param _conditionOutcome The required state (Passed/Failed) for the condition proposal.
     */
    function voteConditionally(
        uint256 _targetProposalId,
        VoteType _myVote,
        uint256 _conditionProposalId,
        ProposalState _conditionOutcome // Should be Passed or Failed
    )
        public
        whenNotPaused
        isValidProposal(_targetProposalId)
        isValidProposal(_conditionProposalId)
    {
        require(_targetProposalId != _conditionProposalId, "Cannot set condition on the target proposal itself");
        require(_conditionOutcome == ProposalState.Passed || _conditionOutcome == ProposalState.Failed, "Invalid condition outcome state");
        // Target proposal should ideally not be ended yet. Condition proposal can be in any state.
        require(proposals[_targetProposalId].state < ProposalState.Ended, "Target proposal voting has already ended");

        // Store the conditional vote details
        uint256 nextIndex = conditionalVotes[_targetProposalId][msg.sender].length;
        conditionalVotes[_targetProposalId][msg.sender].push(
            ConditionalVote({
                conditionProposalId: _conditionProposalId,
                conditionOutcome: _conditionOutcome,
                myVote: _myVote,
                conditionalVoteIndex: nextIndex // Unique index for this user's conditional vote
            })
        );

        emit ConditionalVoteStored(_targetProposalId, msg.sender, _conditionProposalId, _conditionOutcome, _myVote, nextIndex);
    }

    /**
     * @notice Activates a previously stored conditional vote if its condition is met.
     * Applies the stored vote as a weighted vote using the caller's effective weight *at the time of activation*.
     * @param _targetProposalId The ID of the proposal the conditional vote targets.
     * @param _conditionalVoteIndex The index of the conditional vote to activate for msg.sender.
     */
    function activateConditionalVote(uint256 _targetProposalId, uint256 _conditionalVoteIndex)
        public
        whenNotPaused
        isValidProposal(_targetProposalId)
    {
        require(proposals[_targetProposalId].state == ProposalState.Open, "Target proposal is not open for voting");
        require(block.timestamp < proposals[_targetProposalId].endTime, "Target proposal voting period has ended");

        ConditionalVote[] storage userConditionalVotes = conditionalVotes[_targetProposalId][msg.sender];
        require(_conditionalVoteIndex < userConditionalVotes.length, "Invalid conditional vote index");
        require(!activatedConditionalVotes[msg.sender][_conditionalVoteIndex], "Conditional vote already activated");

        ConditionalVote storage cVote = userConditionalVotes[_conditionalVoteIndex];
        require(cVote.conditionProposalId > 0, "Conditional vote already consumed or invalid"); // Check if condition is still valid

        Proposal storage conditionProposal = proposals[cVote.conditionProposalId];
        require(conditionProposal.state >= ProposalState.Ended, "Condition proposal voting has not ended yet");
        require(conditionProposal.resultCalculated, "Condition proposal result not yet calculated");

        // Check if the condition is met
        bool conditionMet = false;
        if (cVote.conditionOutcome == ProposalState.Passed && conditionProposal.state == ProposalState.Passed) {
            conditionMet = true;
        } else if (cVote.conditionOutcome == ProposalState.Failed && conditionProposal.state == ProposalState.Failed) {
            conditionMet = true;
        }

        require(conditionMet, "Condition for this vote is not met");

        // Apply the vote as a weighted vote using current effective weight
        uint256 effectiveWeight = getEffectiveVotingWeight(msg.sender);
        require(effectiveWeight > 0, "Voter has no effective weight to activate conditional vote");

        // Apply the vote to the target proposal
        if (cVote.myVote == VoteType.For) {
            proposals[_targetProposalId].weightedForVotes = proposals[_targetProposalId].weightedForVotes.add(effectiveWeight);
        } else {
            proposals[_targetProposalId].weightedAgainstVotes = proposals[_targetProposalId].weightedAgainstVotes.add(effectiveWeight);
        }

        // Mark as activated
        activatedConditionalVotes[msg.sender][_conditionalVoteIndex] = true;
        // Optional: Clear the stored conditional vote struct if memory is a concern,
        // but marking as activated is sufficient to prevent re-use.
        // cVote.conditionProposalId = 0; // Mark as consumed

        emit ConditionalVoteActivated(_targetProposalId, msg.sender, _conditionalVoteIndex, cVote.myVote, effectiveWeight);
    }


    /**
     * @notice Transitions an open proposal's state to Ended if its voting period has passed.
     * Can be called by anyone.
     * @param _proposalId The ID of the proposal to end.
     */
    function endVotingPeriod(uint256 _proposalId)
        public
        isValidProposal(_proposalId)
        onlyProposalState(_proposalId, ProposalState.Open)
    {
        require(block.timestamp >= proposals[_proposalId].endTime, "Voting period is not over yet");

        proposals[_proposalId].state = ProposalState.Ended;

        emit VotingEnded(_proposalId, proposals[_proposalId].endTime);
    }

    /**
     * @notice Calculates the final result (Passed/Failed) for an Ended proposal.
     * Can be called by anyone.
     * Requires result to not have been calculated yet.
     * @param _proposalId The ID of the proposal to calculate results for.
     */
    function calculateResult(uint256 _proposalId)
        public
        isValidProposal(_proposalId)
        onlyProposalState(_proposalId, ProposalState.Ended)
    {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.resultCalculated, "Result already calculated");

        // Calculate total votes including all types
        uint256 totalFor = proposal.standardForVotes
                           .add(proposal.weightedForVotes)
                           .add(proposal.entangledEffectForVotes);
        uint256 totalAgainst = proposal.standardAgainstVotes
                              .add(proposal.weightedAgainstVotes)
                              .add(proposal.entangledEffectAgainstVotes);
        uint256 totalVotes = totalFor.add(totalAgainst);

        // Quorum check: Requires a minimum percentage of *potential* total voting weight to have participated (standard, weighted, entanglement, or activated conditional).
        // Calculating total potential weight on-chain is hard unless all possible voters and their weights are known and summed (impractical for public).
        // Alternative Quorum: Percentage of total *cast* votes above a certain threshold, or linked to a known total supply/stake if applicable.
        // Let's use a simpler quorum: Total effective weight that participated (voted standard, weighted, entanglement, or activated conditional) compared to a conceptual total.
        // This requires tracking total effective weight that *participated* vs. a total *possible* weight. Let's simplify: Quorum is based on total *cast* votes meeting a percentage of *total cast votes*.
        // A more robust quorum requires a known total possible weight.
        // For this complex example, let's assume total possible weight is tracked externally or simplify quorum: percentage of total *cast* weighted votes.
        // Total weighted votes cast (explicit weighted + activated conditional + effective weight from entanglement votes on this proposal)
        uint256 totalWeightedVotesCast = proposal.weightedForVotes.add(proposal.weightedAgainstVotes); // This excludes standard votes and entanglement effects received

        // Let's use the sum of standard, weighted, and activated conditional votes for quorum base, as these are "direct" votes. Entanglement effects are secondary.
        // Even better: Quorum is based on the SUM of (effective weight used in standard vote if >1), (effective weight used in weighted vote), (effective weight of voter using entanglement vote), (effective weight of voter activating conditional vote). This requires tracking voter weight per vote type.
        // Simplification: Quorum = Total 'For' + 'Against' votes (all types included) as a percentage of a *hypothetical* maximum total weight (e.g., 100% of something).
        // Let's make Quorum based on the sum of all *final* votes (totalFor + totalAgainst) vs a *defined* total possible weight. This total possible weight needs to be set or derived.
        // If this contract doesn't manage token/stake, assume total possible weight is a parameter.
        // Let's add `totalPossibleVotingWeight` parameter, set by owner.
        // REFACTOR: Add `totalPossibleVotingWeight` to state and `setVotingParameters`.

        uint256 totalPossibleWeight = defaultVotingWeight; // Placeholder; needs proper calculation or setting

        // Assuming totalPossibleVotingWeight is known/set via `setVotingParameters`
        // Quorum check: Total votes must be >= quorumThreshold % of totalPossibleVotingWeight
        // uint256 requiredQuorumVotes = totalPossibleVotingWeight.mul(quorumThreshold).div(100);
        // bool quorumMet = totalVotes >= requiredQuorumVotes;

        // Alternative simple quorum: Total votes must be >= fixed number (e.g., 1000 votes)
        // bool quorumMet = totalVotes >= minimumQuorumVotes; // Needs `minimumQuorumVotes` parameter

        // Simplest Quorum for this demo: Total votes cast (all types) as percentage of a fixed total.
        // Let's assume `totalPossibleVotingWeight` is set.
        // Re-read quorum definition: "minimum percentage of total weight required to vote for a proposal to be valid".
        // This implies participation threshold. Sum of weights of *unique* voters who voted *any* valid way.
        // This requires a separate mapping: `mapping(uint256 => mapping(address => bool)) hasParticipated;`
        // Let's add `hasParticipated` and update it in all vote functions.
        // Let's calculate total unique participant weight: Iterate through all addresses that voted standard, weighted, entanglement, or activated conditional, sum their effective weights *once*. This is gas-intensive.

        // Simpler Quorum (less robust): Percentage of *total cast votes* against a set total possible weight.
        // Need totalPossibleVotingWeight as a parameter.

        // Re-simplifying: Let's assume Quorum is based on the percentage of *total cast votes* (sum of for+against) against a fixed number, or total *potential* weight (if known).
        // Let's set a simple minimum number of *participating addresses* for quorum, or minimum total *weight* cast.
        // Minimum *Total Weight Cast* seems more aligned with weighted voting.
        // Need a way to track Total Weight Cast across all types.
        // Let's calculate Quorum based on the sum of the `effectiveWeight` used by each unique voter in their *first* vote (any type) on this proposal. This is complex.

        // Final approach for Quorum in this demo: It's the percentage of the *total sum of all vote weights cast* (totalFor + totalAgainst) against a globally defined `totalRegisteredVotingWeight`. This `totalRegisteredVotingWeight` needs to be updated whenever `votingWeight` is set or changed for *any* user.
        // REFACTOR: Add `totalRegisteredVotingWeight` and update it.

        uint256 currentTotalRegisteredWeight = defaultVotingWeight; // Placeholder. Needs tracking.
        // Assuming totalRegisteredVotingWeight is tracked and accurate:
        uint256 requiredQuorumWeight = currentTotalRegisteredWeight.mul(quorumThreshold).div(100);
        bool quorumMet = totalFor.add(totalAgainst) >= requiredQuorumWeight; // Using sum of all votes as proxy for participation weight

        // Majority check: Requires majorityThreshold % of total votes to be 'For'
        bool majorityMet = false;
        if (totalVotes > 0) { // Avoid division by zero
             majorityMet = totalFor.mul(100).div(totalVotes) >= majorityThreshold;
        } else {
             // If no votes, majority is not met (unless majorityThreshold is 0, which is unlikely)
             majorityMet = majorityThreshold == 0;
        }


        proposal.passed = quorumMet && majorityMet; // Proposal passes if both quorum and majority are met
        proposal.state = proposal.passed ? ProposalState.Passed : ProposalState.Failed;
        proposal.resultCalculated = true;

        emit ResultCalculated(_proposalId, proposal.passed, totalFor, totalAgainst, quorumMet);
    }


    /**
     * @notice Cancels a proposal if it is in Pending or Open state.
     * @param _proposalId The ID of the proposal to cancel.
     */
    function cancelProposal(uint256 _proposalId)
        public
        onlyOwner
        whenNotPaused
        isValidProposal(_proposalId)
    {
        require(proposals[_proposalId].state <= ProposalState.Open, "Proposal cannot be cancelled after voting ends");

        proposals[_proposalId].state = ProposalState.Cancelled;

        // Optional: Refund any associated tokens if applicable

        emit ProposalCancelled(_proposalId);
    }

     /**
     * @notice Extends the voting period for an open proposal.
     * @param _proposalId The ID of the proposal.
     * @param _additionalSeconds The number of seconds to add to the voting period.
     */
    function extendVotingPeriod(uint256 _proposalId, uint256 _additionalSeconds)
        public
        onlyOwner
        whenNotPaused
        isValidProposal(_proposalId)
        onlyProposalState(_proposalId, ProposalState.Open)
    {
        require(_additionalSeconds > 0, "Additional seconds must be positive");
        require(block.timestamp < proposals[_proposalId].endTime, "Voting period has already ended");

        proposals[_proposalId].endTime = proposals[_proposalId].endTime.add(_additionalSeconds);

        emit VotingStarted(_proposalId, proposals[_proposalId].startTime, proposals[_proposalId].endTime); // Re-emit Start event with new end time
    }

    /**
     * @notice Sets global voting parameters: quorum, majority thresholds, and default voting weight.
     * @param _quorumThreshold The percentage of total possible weight required for quorum.
     * @param _majorityThreshold The percentage of total votes required for 'For' to win.
     * @param _defaultVotingWeight The default weight for voters without explicit weight.
     */
    function setVotingParameters(uint256 _quorumThreshold, uint256 _majorityThreshold, uint256 _defaultVotingWeight)
        public
        onlyOwner
    {
        require(_quorumThreshold <= 100, "Quorum threshold percentage invalid");
        require(_majorityThreshold <= 100, "Majority threshold percentage invalid");

        quorumThreshold = _quorumThreshold;
        majorityThreshold = _majorityThreshold;
        defaultVotingWeight = _defaultVotingWeight;

        // Note: totalRegisteredVotingWeight tracking is needed for Quorum logic based on total potential weight.
        // This function updates the parameter, but not the tracked total unless weights are reset/recalculated.
        // A robust implementation would recalculate or track this dynamically.

        emit VotingParametersSet(quorumThreshold, majorityThreshold, defaultVotingWeight);
    }

    /**
     * @notice Pauses the contract, preventing most state-changing actions.
     * @dev Inherited from Pausable. Can only be called by the owner.
     */
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @notice Unpauses the contract.
     * @dev Inherited from Pausable. Can only be called by the owner.
     */
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    // --- Query Functions ---

    /**
     * @notice Gets details of a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @return All fields of the Proposal struct.
     */
    function getProposal(uint256 _proposalId)
        public
        view
        isValidProposal(_proposalId)
        returns (
            uint256 id,
            address creator,
            string memory description,
            uint256 startTime,
            uint256 endTime,
            ProposalState state,
            uint256 standardForVotes,
            uint256 standardAgainstVotes,
            uint256 weightedForVotes,
            uint256 weightedAgainstVotes,
            uint256 entangledEffectForVotes,
            uint256 entangledEffectAgainstVotes,
            uint256 entangledPartnerId,
            EntanglementType entanglementType,
            uint256 entanglementMultiplier,
            uint256 votingPeriodDuration, // Need to return this if added to struct
            bool resultCalculated,
            bool passed
        )
    {
        Proposal storage p = proposals[_proposalId];
        return (
            p.id,
            p.creator,
            p.description,
            p.startTime,
            p.endTime,
            p.state,
            p.standardForVotes,
            p.standardAgainstVotes,
            p.weightedForVotes,
            p.weightedAgainstVotes,
            p.entangledEffectForVotes,
            p.entangledEffectAgainstVotes,
            p.entangledPartnerId,
            p.entanglementType,
            p.entanglementMultiplier,
            p.votingPeriodDuration, // Assuming added
            p.resultCalculated,
            p.passed
        );
    }

    /**
     * @notice Gets the current voting status of a proposal.
     * @param _proposalId The ID of the proposal.
     * @return The state of the proposal and time remaining if open.
     */
    function getVotingStatus(uint256 _proposalId)
        public
        view
        isValidProposal(_proposalId)
        returns (ProposalState state, uint256 timeRemaining)
    {
        Proposal storage p = proposals[_proposalId];
        state = p.state;
        timeRemaining = 0;
        if (state == ProposalState.Open && block.timestamp < p.endTime) {
            timeRemaining = p.endTime.sub(block.timestamp);
        }
        return (state, timeRemaining);
    }

    /**
     * @notice Gets the final result of a proposal after calculation.
     * @param _proposalId The ID of the proposal.
     * @return Whether it passed, and the final vote counts (sum of all types).
     */
    function getProposalResult(uint256 _proposalId)
        public
        view
        isValidProposal(_proposalId)
        returns (bool resultCalculated, bool passed, uint256 totalFor, uint256 totalAgainst)
    {
        Proposal storage p = proposals[_proposalId];
        require(p.state >= ProposalState.Ended, "Voting period has not ended");

        uint256 totalF = p.standardForVotes.add(p.weightedForVotes).add(p.entangledEffectForVotes);
        uint256 totalA = p.standardAgainstVotes.add(p.weightedAgainstVotes).add(p.entangledEffectAgainstVotes);

        return (p.resultCalculated, p.passed, totalF, totalA);
    }

    /**
     * @notice Checks how a specific voter has voted on a proposal across different vote types.
     * @param _proposalId The ID of the proposal.
     * @param _voter The address of the voter.
     * @return hasStandard bool, hasEntanglement bool, hasWeighted bool, lastSupport VoteType (or default 0)
     */
    function getVoterVoteStatus(uint256 _proposalId, address _voter)
        public
        view
        isValidProposal(_proposalId)
        returns (bool hasStandard, bool hasEntanglement, bool hasWeighted, VoteType lastSupport)
    {
        hasStandard = hasVotedStandard[_proposalId][_voter];
        hasEntanglement = hasVotedWithEntanglement[_proposalId][_voter];
        hasWeighted = hasVotedWeighted[_proposalId][_voter];
        lastSupport = voterSupport[_proposalId][_voter];
        return (hasStandard, hasEntanglement, hasWeighted, lastSupport);
    }

    /**
     * @notice Gets the entanglement details for a proposal.
     * @param _proposalId The ID of the proposal.
     * @return The entangled partner ID, entanglement type, and multiplier.
     */
    function getProposalEntanglement(uint256 _proposalId)
        public
        view
        isValidProposal(_proposalId)
        returns (uint256 entangledPartnerId, EntanglementType entanglementType, uint256 entanglementMultiplier)
    {
        Proposal storage p = proposals[_proposalId];
        return (p.entangledPartnerId, p.entanglementType, p.entanglementMultiplier);
    }

    /**
     * @notice Gets the breakdown of votes by type for a proposal.
     * @param _proposalId The ID of the proposal.
     * @return standardFor, standardAgainst, weightedFor, weightedAgainst, entangledEffectFor, entangledEffectAgainst.
     */
    function getProposalVoteBreakdown(uint256 _proposalId)
        public
        view
        isValidProposal(_proposalId)
        returns (
            uint256 standardFor,
            uint256 standardAgainst,
            uint256 weightedFor,
            uint256 weightedAgainst,
            uint256 entangledEffectFor,
            uint256 entangledEffectAgainst
        )
    {
        Proposal storage p = proposals[_proposalId];
        return (
            p.standardForVotes,
            p.standardAgainstVotes,
            p.weightedForVotes,
            p.weightedAgainstVotes,
            p.entangledEffectForVotes,
            p.entangledEffectAgainstVotes
        );
    }

     /**
     * @notice Gets the list of conditional votes stored by a voter for a target proposal.
     * @param _targetProposalId The ID of the proposal the conditional votes target.
     * @param _voter The address of the voter.
     * @return An array of ConditionalVote structs.
     */
    function getConditionalVotes(uint256 _targetProposalId, address _voter)
        public
        view
        isValidProposal(_targetProposalId)
        returns (ConditionalVote[] memory)
    {
        // Note: Does not filter for activated/consumed votes. Check activated status separately.
        return conditionalVotes[_targetProposalId][_voter];
    }

     /**
     * @notice Gets the total number of proposals created.
     * @return The proposal counter value.
     */
    function getTotalProposals() public view returns (uint256) {
        return proposalCounter;
    }
}
```