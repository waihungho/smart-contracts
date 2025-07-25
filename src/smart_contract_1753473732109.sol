This Solidity smart contract, `ImpactDAO`, introduces an advanced and creative decentralized autonomous organization (DAO) model focusing on **Adaptive Governance** and **Reputation-Weighted Decision Making** for funding community projects. It integrates a unique combination of concepts like a non-transferable (Soul-Bound Token-like) reputation system, quadratic voting adjusted by reputation, milestone-based project funding with an integrated dispute resolution mechanism, and on-chain meta-governance.

The contract aims to create a dynamic and meritocratic ecosystem where contributions and past performance directly influence an individual's influence and ability to participate in the DAO's governance and funding processes.

---

## Contract Outline:

*   **I. Core State Variables, Enums, Structs & Events**: Defines all essential data structures, states, and logs for on-chain activities.
*   **II. Initial Setup & Configuration**: Constructor and functions for initial setup and configuring core parameters (like oracle address).
*   **III. Reputation Management (Non-transferable, SBT-like)**: Implements a non-transferable reputation score for each user, which serves as a basis for voting power, eligibility, and incentives. Includes delegation for reputation.
*   **IV. Governance & Proposal System (Adaptive, Reputation-Weighted Quadratic Voting)**: A comprehensive system for submitting, voting on, and tracking project proposals. Voting power is dynamically adjusted by a user's reputation using a quadratic weighting mechanism.
*   **V. Funding, Milestones & Escrow Management**: Manages the allocation of treasury funds to approved projects based on a milestone-driven escrow model, ensuring funds are released only upon verified progress.
*   **VI. Dispute Resolution Mechanism**: Provides an on-chain framework for challenging milestone completions, reputation scores, or other proposal outcomes, resolved by reputation-gated arbiters.
*   **VII. DAO Treasury & Meta-Governance**: Functions for managing the DAO's treasury (deposits, withdrawals) and allowing the DAO itself to update its core governance parameters.
*   **VIII. Oracle & External Integrations**: Defines the role of a trusted oracle for external data verification, specifically for milestone completion.
*   **IX. Utility & View Functions**: Helper functions for querying the state of proposals, disputes, and user reputation.
*   **X. Emergency & Ownership Controls**: Basic pausability and a mechanism to transfer contract ownership to a DAO-controlled address (e.g., multisig or governance module) after initial deployment.

---

## Function Summary:

1.  **`constructor(address _impactTokenAddress, address _initialOracleAddress)`**: Initializes the DAO, linking it to a specific ERC20 `IMPACT_TOKEN` for treasury and setting an initial trusted oracle address.
2.  **`setOracleAddress(address _newOracleAddress)`**: Allows the current owner (or DAO governance) to update the designated oracle address.
3.  **`propose(string calldata title, string calldata description, bytes32 metadataHash, uint256 requestedAmount, uint256[] calldata milestoneAmounts, bytes32[] calldata milestoneHashes)`**: Enables users with sufficient reputation to submit new project proposals for funding, including detailed milestones.
4.  **`voteOnProposal(uint256 proposalId, uint256 supportReputation)`**: Allows participants to cast their vote on a proposal. The voting power is derived from the square root of the reputation points they commit to supporting the proposal, introducing a reputation-weighted quadratic voting mechanism.
5.  **`endVotingPeriod(uint256 proposalId)`**: Concludes the voting phase for a proposal, calculates the final outcome based on reputation-weighted quadratic support, and updates the proposal's state.
6.  **`fundProposal(uint256 proposalId)`**: Moves the approved funds for a passed proposal from the DAO treasury into an internal escrow (earmarked) for milestone-based release.
7.  **`submitMilestoneCompletion(uint256 proposalId, uint256 milestoneIndex, bytes32 evidenceHash)`**: Project proposers submit evidence of a completed milestone, initiating a review period.
8.  **`challengeMilestoneCompletion(uint256 proposalId, uint256 milestoneIndex)`**: Allows eligible users (e.g., high-reputation holders) to challenge a submitted milestone completion, requiring a dispute bond and initiating a formal dispute.
9.  **`submitOracleMilestoneVerification(uint256 proposalId, uint256 milestoneIndex, bool verified)`**: The designated oracle uses this function to submit its verification status (true/false) for a specific milestone.
10. **`releaseMilestonePayment(uint256 proposalId, uint256 milestoneIndex)`**: Releases the allocated funds for a milestone to the project proposer once it has been verified (by oracle or dispute resolution) and is not challenged.
11. **`initiateDispute(uint256 subjectId, DisputeType dType, bytes32 evidenceHash)`**: Initiates a formal dispute (e.g., over a milestone, reputation, or proposal outcome), requiring a dispute bond from the initiator.
12. **`voteOnDispute(uint256 disputeId, bool decision)`**: Allows eligible arbiters (based on minimum reputation) to cast their vote (yes/no) on an ongoing dispute.
13. **`resolveDispute(uint256 disputeId)`**: Finalizes a dispute after its voting period ends, applying consequences (e.g., reputation changes, fund movements) based on the arbiter's decision.
14. **`updateGovernanceParameter(bytes32 paramName, uint256 newValue)`**: Enables the DAO, through its governance mechanism, to modify core contract parameters (meta-governance), such as voting periods, thresholds, or minimum reputation requirements.
15. **`depositFunds(uint256 amount)`**: Allows any user or external entity to deposit `IMPACT_TOKEN`s into the DAO's treasury.
16. **`withdrawTreasuryFunds(address recipient, uint256 amount)`**: Allows the DAO's governance (owner) to withdraw funds from the treasury, typically after a successful governance proposal.
17. **`delegateReputation(address delegatee)`**: Enables users to delegate their reputation-based voting power to another address, fostering expert delegation and participation.
18. **`undelegateReputation()`**: Allows users to revoke their active reputation delegation.
19. **`getReputation(address user)`**: A view function to retrieve the current reputation score of any given user.
20. **`getDelegatedReputationPower(address user)`**: A view function that returns the effective address that holds the voting power for a given user, considering delegations.
21. **`getProposalDetails(uint256 proposalId)`**: Provides comprehensive details about a specific proposal, including its state, requested funds, and voting statistics.
22. **`getMilestoneDetails(uint256 proposalId, uint256 milestoneIndex)`**: Returns detailed information about a specific milestone within a proposal, including its status and evidence.
23. **`getDisputeDetails(uint256 disputeId)`**: A view function to retrieve all details pertaining to a specific dispute.
24. **`getQuadraticVotingScore(uint256 reputationCommitted)`**: A pure helper function illustrating the square root calculation used for reputation-weighted voting.
25. **`grantReputation(address user, uint256 amount)`**: An administrative function (callable by owner/governance) to manually award reputation to a user (e.g., for off-chain contributions).
26. **`slashReputation(address user, uint256 amount)`**: An administrative function (callable by owner/governance) to reduce a user's reputation, typically as a consequence of malicious behavior or dispute resolution.
27. **`transferOwnershipToDAO(address daoGovernanceAddress)`**: A critical function to transfer the contract's `Ownable` ownership from the deployer to a DAO-controlled address (e.g., a multisig or a dedicated governance contract) for decentralization.
28. **`renounceOwnership()`**: (Inherited from Ownable) Allows the current owner to permanently renounce ownership of the contract. Use with extreme caution.
29. **`emergencyPause()`**: A security function callable by the owner to temporarily halt critical contract operations (like proposals, funding, disputes) in case of an emergency or vulnerability.
30. **`emergencyUnpause()`**: Callable by the owner to resume contract operations after an emergency pause.
31. **`getVotingPower(address _voter)`**: Calculates the effective reputation-based voting power for a given address, considering any active delegations.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // For initial setup and emergency controls
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For older versions or specific operations, useful for clarity
import "@openzeppelin/contracts/utils/math/Math.sol";     // For Math.sqrt in 0.8.x

// Outline:
// I.  Core State Variables, Enums, Structs & Events
// II. Initial Setup & Configuration
// III. Reputation Management (Non-transferable, SBT-like)
// IV. Governance & Proposal System (Adaptive, Reputation-Weighted Quadratic Voting)
// V.  Funding, Milestones & Escrow Management
// VI. Dispute Resolution Mechanism
// VII. DAO Treasury & Meta-Governance
// VIII. Oracle & External Integrations
// IX. Utility & View Functions
// X.  Emergency & Ownership Controls

// Function Summary:
// - constructor(address _impactTokenAddress, address _initialOracleAddress): Initializes the DAO with the ERC20 impact token and a trusted oracle address.
// - setOracleAddress(address _newOracleAddress): Allows the current owner (or DAO) to update the oracle address.
// - propose(string calldata title, string calldata description, bytes32 metadataHash, uint256 requestedAmount, uint256[] calldata milestoneAmounts, bytes32[] calldata milestoneHashes): Submits a new project proposal for funding. Requires a minimum reputation to propose.
// - voteOnProposal(uint256 proposalId, uint256 supportReputation): Participants cast reputation-weighted quadratic votes on proposals. Commits a portion of their reputation.
// - endVotingPeriod(uint256 proposalId): Finalizes voting, determines proposal outcome. Callable by anyone after voting ends.
// - fundProposal(uint256 proposalId): Transfers approved funds from the DAO treasury to the proposal's escrow if the proposal has passed.
// - submitMilestoneCompletion(uint256 proposalId, uint256 milestoneIndex, bytes32 evidenceHash): Proposers submit evidence for a completed milestone, initiating a review period.
// - challengeMilestoneCompletion(uint256 proposalId, uint256 milestoneIndex): Allows eligible users (e.g., high reputation) to challenge a submitted milestone completion. Initiates a dispute.
// - submitOracleMilestoneVerification(uint256 proposalId, uint256 milestoneIndex, bool verified): Allows the designated oracle to submit its verification status for a milestone.
// - releaseMilestonePayment(uint256 proposalId, uint256 milestoneIndex): Releases funds for an approved and verified milestone to the project proposer.
// - initiateDispute(uint256 subjectId, DisputeType dType, bytes32 evidenceHash): Initiates a formal dispute (e.g., reputation challenge, milestone dispute). Requires a dispute bond.
// - voteOnDispute(uint256 disputeId, bool decision): Arbiters cast votes on active disputes. Eligibility for arbiters is reputation-based.
// - resolveDispute(uint256 disputeId): Finalizes a dispute based on arbiter votes, applies consequences (e.g., reputation changes, fund movements). Callable by anyone after dispute voting ends.
// - updateGovernanceParameter(bytes32 paramName, uint256 newValue): Allows the DAO to change core governance parameters (meta-governance) via a special proposal type or highly privileged vote.
// - depositFunds(uint256 amount): Allows anyone to deposit IMPACT_TOKENs into the DAO treasury.
// - withdrawTreasuryFunds(address recipient, uint256 amount): Allows withdrawing treasury funds (requires governance approval).
// - delegateReputation(address delegatee): Users can delegate their reputation-based voting power.
// - undelegateReputation(): Users can revoke their reputation.
// - getReputation(address user): Returns a user's current non-transferable reputation score.
// - getDelegatedReputationPower(address user): Returns the effective voting power of a user (or their delegate).
// - getProposalDetails(uint256 proposalId): Returns comprehensive details for a specific proposal.
// - getMilestoneDetails(uint256 proposalId, uint256 milestoneIndex): Returns details for a specific milestone.
// - getDisputeDetails(uint256 disputeId): Returns details for a specific dispute.
// - getQuadraticVotingScore(uint256 reputationCommitted): Helper to calculate the effective QV score.
// - getVotingPower(address _voter): Calculates the effective reputation-based voting power for a given address.
// - grantReputation(address user, uint256 amount): Grants reputation based on positive contributions (internal/admin triggered).
// - slashReputation(address user, uint256 amount): Reduces reputation for negative actions (internal/dispute triggered).
// - transferOwnershipToDAO(address daoGovernanceAddress): Transfers contract ownership from the deployer to a DAO-controlled address (e.g., a multisig or specific governance module address).
// - renounceOwnership(): Disables Ownable after transfer.
// - emergencyPause(): A last-resort function to pause critical operations (e.g., during an exploit).
// - emergencyUnpause(): Unpauses the contract after an emergency.

contract ImpactDAO is Ownable, ReentrancyGuard {
    using SafeMath for uint256; // Provides protection against overflow/underflow for older Solidity versions, or for explicit clarity.
    using Math for uint256;     // Provides access to `sqrt()` function from OpenZeppelin.

    // I. Core State Variables, Enums, Structs & Events

    IERC20 public immutable IMPACT_TOKEN; // The governance and funding token for the DAO.
    address public oracleAddress;         // The address of the trusted oracle for milestone verification.

    // Reputation: Non-transferable, SBT-like score mapping address to reputation points.
    mapping(address => uint256) private _reputations;
    // Delegation mapping: stores the delegatee for each delegator.
    mapping(address => address) public delegatedReputation; // delegator => delegatee

    // Proposal Management
    uint256 public nextProposalId; // Counter for unique proposal IDs.
    mapping(uint256 => Proposal) public proposals; // Stores all proposals by their ID.

    // Enum for different states a proposal can be in.
    enum ProposalState {
        Pending,          // Just submitted, awaiting initial review/action.
        Voting,           // Active voting period.
        QueuedForFunding, // Passed vote, awaiting treasury allocation.
        Active,           // Funded, project work ongoing, milestones can be submitted.
        Completed,        // All milestones completed and paid.
        Failed,           // Did not pass the vote or was otherwise rejected.
        Rejected,         // Explicitly rejected by dispute or review.
        Canceled          // Canceled by proposer or dispute resolution.
    }

    // Structure defining a project proposal.
    struct Proposal {
        address proposer;            // The address that submitted the proposal.
        string title;                // Title of the proposal.
        string description;          // Detailed description of the proposal.
        bytes32 metadataHash;        // IPFS hash or similar for off-chain extended details.
        uint256 requestedAmount;     // Total IMPACT_TOKENs requested for the project.
        uint256 fundedAmount;        // Amount of IMPACT_TOKENs earmarked in the treasury for this proposal.
        uint256 proposalId;          // Unique ID of the proposal.
        uint256 submissionTime;      // Timestamp of proposal submission.
        uint256 votingEndTime;       // Timestamp when the voting period ends.
        ProposalState state;         // Current state of the proposal.
        uint256 totalReputationSupport; // Sum of square roots of reputation committed by voters (for QV).
        mapping(address => uint256) votes; // Maps voter addresses to the reputation they committed.
        Milestone[] milestones;      // Array of milestones for the project.
        bool fundsClaimedOnFail;     // Flag to prevent double claims if proposal fails voting.
    }

    // Structure defining a single milestone within a project proposal.
    struct Milestone {
        uint256 amount;              // Amount of IMPACT_TOKENs allocated for this milestone.
        bytes32 milestoneHash;       // IPFS hash for milestone details/proof structure.
        bool completedByProposer;    // True if proposer claims completion.
        bool verifiedByOracle;       // True if oracle has verified completion.
        bool challenged;             // True if this milestone's completion is under dispute.
        bool fundsReleased;          // True if payment for this milestone has been released.
    }

    // Dispute Management
    uint256 public nextDisputeId; // Counter for unique dispute IDs.
    mapping(uint256 => Dispute) public disputes; // Stores all disputes by their ID.

    // Enum for different types of disputes.
    enum DisputeType {
        MilestoneCompletion,      // Dispute related to a project milestone.
        ReputationChallenge,      // Dispute challenging a user's reputation score.
        ProposalOutcomeChallenge, // Dispute challenging the outcome of a proposal vote.
        Other                     // Generic dispute type for unforeseen issues.
    }

    // Enum for different states a dispute can be in.
    enum DisputeState {
        Pending,    // Just initiated.
        Voting,     // Arbiter voting is active.
        Resolved    // Finalized.
    }

    // Structure defining a dispute.
    struct Dispute {
        uint256 subjectId;        // ID of the subject being disputed (e.g., Proposal ID, or packed user address).
        DisputeType dType;        // Type of the dispute.
        bytes32 evidenceHash;     // IPFS hash for dispute evidence.
        address initiator;        // Address that initiated the dispute.
        uint256 initiationTime;   // Timestamp of dispute initiation.
        uint256 votingEndTime;    // Timestamp when arbiter voting ends.
        DisputeState state;       // Current state of the dispute.
        uint256 yesVotes;         // Total reputation-weighted "Yes" votes.
        uint256 noVotes;          // Total reputation-weighted "No" votes.
        mapping(address => bool) votedArbiters; // Maps arbiter addresses to true if they have voted.
    }

    // Governance Parameters (Configurable via Meta-Governance)
    uint256 public minReputationToPropose;            // Minimum reputation required to submit a proposal.
    uint256 public proposalVotingPeriod;              // Duration of the proposal voting period in seconds.
    uint256 public milestoneReviewPeriod;             // Duration for oracle verification/challenge period for milestones in seconds.
    uint256 public disputeVotingPeriod;               // Duration of the dispute arbiter voting period in seconds.
    uint256 public arbiterMinReputation;              // Minimum reputation required to act as an arbiter in disputes.
    uint256 public proposalPassThresholdNumerator;    // Numerator for the percentage threshold for a proposal to pass (e.g., 60 for 60%).
    uint256 public proposalPassThresholdDenominator;  // Denominator for the percentage threshold (e.g., 100).
    uint256 public disputeResolutionThresholdNumerator; // Numerator for the percentage threshold for a dispute to resolve (e.g., 51 for 51%).
    uint256 public disputeResolutionThresholdDenominator; // Denominator for the percentage threshold (e.g., 100).
    uint256 public disputeBondAmount;                 // Amount of IMPACT_TOKEN required as a bond to initiate a dispute.

    // Pausability state variable.
    bool public paused;

    // Events emitted by the contract to signal state changes.
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, uint256 requestedAmount, uint256 submissionTime);
    event VoteCast(uint256 indexed proposalId, address indexed voter, uint256 supportReputation);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event ProposalFunded(uint256 indexed proposalId, uint256 amount);
    event MilestoneSubmitted(uint256 indexed proposalId, uint256 indexed milestoneIndex, bytes32 evidenceHash);
    event MilestoneChallenged(uint256 indexed proposalId, uint256 indexed milestoneIndex, address indexed challenger);
    event OracleMilestoneVerified(uint256 indexed proposalId, uint256 indexed milestoneIndex, bool verified);
    event MilestonePaymentReleased(uint256 indexed proposalId, uint256 indexed milestoneIndex, uint256 amount);
    event DisputeInitiated(uint256 indexed disputeId, uint256 indexed subjectId, DisputeType dType, address indexed initiator);
    event DisputeVoteCast(uint256 indexed disputeId, address indexed voter, bool decision);
    event DisputeResolved(uint256 indexed disputeId, DisputeState newState, bool outcome);
    event ReputationGranted(address indexed user, uint256 amount);
    event ReputationSlashed(address indexed user, uint256 amount);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event GovernanceParameterUpdated(bytes32 indexed paramName, uint256 newValue);
    event ReputationDelegated(address indexed delegator, address indexed delegatee);
    event ReputationUndelegated(address indexed delegator);
    event Paused(address account);
    event Unpaused(address account);

    // II. Initial Setup & Configuration

    /// @dev Constructor to initialize the DAO contract.
    /// @param _impactTokenAddress The address of the ERC20 token used for funding and governance.
    /// @param _initialOracleAddress The initial trusted address for oracle operations.
    constructor(address _impactTokenAddress, address _initialOracleAddress) Ownable(msg.sender) {
        require(_impactTokenAddress != address(0), "ImpactDAO: Invalid token address");
        require(_initialOracleAddress != address(0), "ImpactDAO: Invalid oracle address");
        IMPACT_TOKEN = IERC20(_impactTokenAddress);
        oracleAddress = _initialOracleAddress;

        // Set initial configurable governance parameters.
        minReputationToPropose = 100; // Example: 100 reputation points required.
        proposalVotingPeriod = 5 days; // Proposals open for 5 days of voting.
        milestoneReviewPeriod = 3 days; // Time for oracle/challenges after milestone submission.
        disputeVotingPeriod = 5 days; // Disputes open for 5 days of arbiter voting.
        arbiterMinReputation = 500; // Example: 500 reputation points to act as an arbiter.
        proposalPassThresholdNumerator = 60; // 60% approval threshold for proposals (relative to total support).
        proposalPassThresholdDenominator = 100;
        disputeResolutionThresholdNumerator = 51; // 51% majority for dispute resolution.
        disputeResolutionThresholdDenominator = 100;
        disputeBondAmount = 100 * (10 ** 18); // Example: 100 tokens as bond for dispute initiation.
        nextProposalId = 1; // Initialize proposal ID counter.
        nextDisputeId = 1; // Initialize dispute ID counter.

        paused = false; // Contract is initially not paused.
    }

    // Modifiers to control access and contract state.
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "ImpactDAO: Only oracle can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "ImpactDAO: Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "ImpactDAO: Contract is not paused");
        _;
    }

    // X. Emergency & Ownership Controls

    /// @dev Transfers the contract's Ownable ownership to a DAO-controlled address.
    /// @param daoGovernanceAddress The address of the DAO's governance module (e.g., multisig or voting contract).
    function transferOwnershipToDAO(address daoGovernanceAddress) public onlyOwner {
        require(daoGovernanceAddress != address(0), "ImpactDAO: Invalid DAO governance address");
        transferOwnership(daoGovernanceAddress); // Call OpenZeppelin's transferOwnership.
        // After this, the contract is no longer controlled by the initial deployer, but by the DAO.
    }

    // renounceOwnership() is inherited from Ownable and can be called by the current owner.
    // It's used to permanently remove ownership, making the contract immutable in terms of owner-specific functions.

    /// @dev Pauses critical contract operations in case of an emergency.
    function emergencyPause() public onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /// @dev Unpauses critical contract operations, resuming normal functionality.
    function emergencyUnpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    // II. Initial Setup & Configuration (continued)

    /// @dev Allows the current owner (or DAO governance) to update the oracle address.
    /// @param _newOracleAddress The new address for the trusted oracle.
    function setOracleAddress(address _newOracleAddress) public onlyOwner whenNotPaused {
        require(_newOracleAddress != address(0), "ImpactDAO: Invalid new oracle address");
        oracleAddress = _newOracleAddress;
    }

    // III. Reputation Management (Non-transferable, SBT-like)

    /// @dev Internal function to grant reputation points to a user.
    /// @param user The address to grant reputation to.
    /// @param amount The amount of reputation points to grant.
    function _grantReputation(address user, uint256 amount) internal {
        _reputations[user] = _reputations[user].add(amount);
        emit ReputationGranted(user, amount);
    }

    /// @dev Internal function to slash (reduce) reputation points from a user.
    /// @param user The address to slash reputation from.
    /// @param amount The amount of reputation points to slash.
    function _slashReputation(address user, uint256 amount) internal {
        uint256 currentReputation = _reputations[user];
        if (currentReputation > amount) {
            _reputations[user] = currentReputation.sub(amount);
        } else {
            _reputations[user] = 0; // Reputation cannot go below zero.
        }
        emit ReputationSlashed(user, amount);
    }

    /// @dev Returns a user's current non-transferable reputation score.
    /// @param user The address to query reputation for.
    /// @return The reputation score of the user.
    function getReputation(address user) public view returns (uint256) {
        return _reputations[user];
    }

    /// @dev Allows a user to delegate their reputation-based voting power to another address.
    /// @param delegatee The address to which reputation power is delegated.
    function delegateReputation(address delegatee) public whenNotPaused {
        require(msg.sender != delegatee, "ImpactDAO: Cannot delegate to self");
        require(delegatee != address(0), "ImpactDAO: Cannot delegate to zero address");
        delegatedReputation[msg.sender] = delegatee;
        emit ReputationDelegated(msg.sender, delegatee);
    }

    /// @dev Allows a user to revoke their active reputation delegation.
    function undelegateReputation() public whenNotPaused {
        require(delegatedReputation[msg.sender] != address(0), "ImpactDAO: No active delegation to undelegate");
        delete delegatedReputation[msg.sender];
        emit ReputationUndelegated(msg.sender);
    }

    /// @dev Returns the effective address that holds the voting power for a given user, considering delegations.
    /// @param user The original user's address.
    /// @return The address that effectively controls the user's reputation voting power.
    function getDelegatedReputationPower(address user) public view returns (address) {
        address delegatee = delegatedReputation[user];
        return (delegatee != address(0) ? delegatee : user);
    }

    /// @dev Calculates the effective reputation-based voting power for a given address, considering delegation.
    /// @param _voter The address for which to calculate voting power.
    /// @return The effective reputation score used for voting.
    function getVotingPower(address _voter) public view returns (uint256) {
        address effectiveVoter = getDelegatedReputationPower(_voter);
        return _reputations[effectiveVoter];
    }

    // IV. Governance & Proposal System (Adaptive, Reputation-Weighted Quadratic Voting)

    /// @dev Submits a new project proposal for funding and sets up its milestones.
    /// @param title Title of the proposal.
    /// @param description Detailed description of the proposal.
    /// @param metadataHash IPFS hash for additional off-chain details.
    /// @param requestedAmount Total IMPACT_TOKENs requested.
    /// @param milestoneAmounts Array of amounts for each milestone.
    /// @param milestoneHashes Array of IPFS hashes for each milestone's details/proof structure.
    /// @return The ID of the newly created proposal.
    function propose(
        string calldata title,
        string calldata description,
        bytes32 metadataHash,
        uint256 requestedAmount,
        uint256[] calldata milestoneAmounts,
        bytes32[] calldata milestoneHashes
    ) public whenNotPaused returns (uint256) {
        require(getReputation(msg.sender) >= minReputationToPropose, "ImpactDAO: Not enough reputation to propose");
        require(requestedAmount > 0, "ImpactDAO: Requested amount must be greater than zero");
        require(milestoneAmounts.length == milestoneHashes.length && milestoneAmounts.length > 0, "ImpactDAO: Mismatched or empty milestones");

        uint256 totalMilestoneAmount = 0;
        for (uint256 i = 0; i < milestoneAmounts.length; i++) {
            totalMilestoneAmount = totalMilestoneAmount.add(milestoneAmounts[i]);
        }
        require(totalMilestoneAmount == requestedAmount, "ImpactDAO: Sum of milestone amounts must equal requested amount");

        uint256 proposalId = nextProposalId++;
        Proposal storage newProposal = proposals[proposalId];

        newProposal.proposer = msg.sender;
        newProposal.title = title;
        newProposal.description = description;
        newProposal.metadataHash = metadataHash;
        newProposal.requestedAmount = requestedAmount;
        newProposal.submissionTime = block.timestamp;
        newProposal.votingEndTime = block.timestamp.add(proposalVotingPeriod);
        newProposal.state = ProposalState.Voting;
        newProposal.proposalId = proposalId;

        // Initialize milestones for the proposal.
        newProposal.milestones.length = milestoneAmounts.length;
        for (uint256 i = 0; i < milestoneAmounts.length; i++) {
            newProposal.milestones[i] = Milestone({
                amount: milestoneAmounts[i],
                milestoneHash: milestoneHashes[i],
                completedByProposer: false,
                verifiedByOracle: false,
                challenged: false,
                fundsReleased: false
            });
        }

        emit ProposalSubmitted(proposalId, msg.sender, requestedAmount, block.timestamp);
        return proposalId;
    }

    /// @dev Allows participants to cast reputation-weighted quadratic votes on proposals.
    /// Each voter commits a portion of their reputation, and their effective vote power is sqrt(committed_reputation).
    /// @param proposalId The ID of the proposal to vote on.
    /// @param supportReputation The amount of reputation points the voter commits to support the proposal.
    function voteOnProposal(uint256 proposalId, uint256 supportReputation) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "ImpactDAO: Proposal does not exist");
        require(proposal.state == ProposalState.Voting, "ImpactDAO: Proposal not in voting state");
        require(block.timestamp <= proposal.votingEndTime, "ImpactDAO: Voting period has ended");

        address voter = getDelegatedReputationPower(msg.sender); // Use effective voter (self or delegatee)
        require(proposal.votes[voter] == 0, "ImpactDAO: Already voted on this proposal");
        require(supportReputation > 0, "ImpactDAO: Support reputation must be positive");
        require(_reputations[voter] >= supportReputation, "ImpactDAO: Not enough reputation to commit");

        // Calculate effective vote power using square root.
        uint256 effectiveSupport = Math.sqrt(supportReputation);
        proposal.totalReputationSupport = proposal.totalReputationSupport.add(effectiveSupport);
        proposal.votes[voter] = supportReputation; // Record the actual reputation committed.

        emit VoteCast(proposalId, msg.sender, supportReputation);
    }

    /// @dev Finalizes voting for a proposal, calculates its outcome, and updates its state.
    /// @param proposalId The ID of the proposal to finalize.
    function endVotingPeriod(uint256 proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "ImpactDAO: Proposal does not exist");
        require(proposal.state == ProposalState.Voting, "ImpactDAO: Proposal not in voting state");
        require(block.timestamp > proposal.votingEndTime, "ImpactDAO: Voting period has not ended yet");

        // A simple passing condition: total reputation support must exceed a certain threshold.
        // In a more complex system, this could involve quorum of participating reputation, etc.
        uint256 requiredEffectiveSupport = 1000; // Example fixed threshold for effective (sqrt-weighted) support.
        
        if (proposal.totalReputationSupport >= requiredEffectiveSupport) {
            // Further criteria can be added, e.g., (support/total_voters_reputation) > threshold
            proposal.state = ProposalState.QueuedForFunding;
        } else {
            proposal.state = ProposalState.Failed;
            proposal.fundsClaimedOnFail = false; // Allow proposer to claim back any initial contribution (not implemented in this version).
        }

        emit ProposalStateChanged(proposalId, proposal.state);
    }

    /// @dev Transfers approved funds from the DAO treasury to an internal escrow for a passed proposal.
    /// @param proposalId The ID of the proposal to fund.
    function fundProposal(uint256 proposalId) public nonReentrant whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "ImpactDAO: Proposal does not exist");
        require(proposal.state == ProposalState.QueuedForFunding, "ImpactDAO: Proposal not queued for funding");
        require(IMPACT_TOKEN.balanceOf(address(this)) >= proposal.requestedAmount, "ImpactDAO: Insufficient treasury funds");
        require(proposal.fundedAmount == 0, "ImpactDAO: Proposal already funded");

        // Funds are now earmarked for this proposal. `fundedAmount` tracks the remaining earmarked funds.
        proposal.fundedAmount = proposal.requestedAmount;
        proposal.state = ProposalState.Active; // Proposal is now active and ready for milestone progression.

        emit ProposalFunded(proposalId, proposal.requestedAmount);
    }

    // V. Funding, Milestones & Escrow Management

    /// @dev Proposers submit evidence for a completed milestone, initiating a review period.
    /// @param proposalId The ID of the proposal.
    /// @param milestoneIndex The index of the milestone within the proposal.
    /// @param evidenceHash IPFS hash or similar for the evidence of completion.
    function submitMilestoneCompletion(uint256 proposalId, uint256 milestoneIndex, bytes32 evidenceHash) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "ImpactDAO: Proposal does not exist");
        require(msg.sender == proposal.proposer, "ImpactDAO: Only proposer can submit milestone completion");
        require(proposal.state == ProposalState.Active, "ImpactDAO: Proposal not active");
        require(milestoneIndex < proposal.milestones.length, "ImpactDAO: Invalid milestone index");
        require(!proposal.milestones[milestoneIndex].completedByProposer, "ImpactDAO: Milestone already submitted");
        require(!proposal.milestones[milestoneIndex].challenged, "ImpactDAO: Milestone is currently under dispute");

        Milestone storage milestone = proposal.milestones[milestoneIndex];
        milestone.completedByProposer = true;
        milestone.milestoneHash = evidenceHash; // Store or update the evidence hash.

        emit MilestoneSubmitted(proposalId, milestoneIndex, evidenceHash);
    }

    /// @dev Allows eligible users (e.g., high reputation) to challenge a submitted milestone completion.
    /// Requires a dispute bond and initiates a formal dispute.
    /// @param proposalId The ID of the proposal.
    /// @param milestoneIndex The index of the milestone being challenged.
    function challengeMilestoneCompletion(uint256 proposalId, uint256 milestoneIndex) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "ImpactDAO: Proposal does not exist");
        require(getReputation(msg.sender) >= arbiterMinReputation, "ImpactDAO: Not enough reputation to challenge");
        require(proposal.state == ProposalState.Active, "ImpactDAO: Proposal not active");
        require(milestoneIndex < proposal.milestones.length, "ImpactDAO: Invalid milestone index");
        require(proposal.milestones[milestoneIndex].completedByProposer, "ImpactDAO: Milestone not submitted for completion yet");
        require(!proposal.milestones[milestoneIndex].challenged, "ImpactDAO: Milestone already challenged");

        // Transfer dispute bond from challenger to the DAO treasury.
        require(IMPACT_TOKEN.transferFrom(msg.sender, address(this), disputeBondAmount), "ImpactDAO: Insufficient dispute bond or allowance");

        proposal.milestones[milestoneIndex].challenged = true;
        // Initiate a dispute for this specific milestone.
        // Note: For a real system, `initiateDispute` would need explicit `proposalId` and `milestoneIndex` parameters.
        // For simplicity here, `subjectId` will be the proposalId and evidenceHash implicitly points to the specific milestone.
        initiateDispute(proposalId, DisputeType.MilestoneCompletion, proposal.milestones[milestoneIndex].milestoneHash);

        emit MilestoneChallenged(proposalId, milestoneIndex, msg.sender);
    }

    /// @dev Allows the designated oracle to submit its verification status for a milestone.
    /// @param proposalId The ID of the proposal.
    /// @param milestoneIndex The index of the milestone.
    /// @param verified True if the oracle verifies the milestone, false otherwise.
    function submitOracleMilestoneVerification(uint256 proposalId, uint256 milestoneIndex, bool verified) public onlyOracle whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "ImpactDAO: Proposal does not exist");
        require(proposal.state == ProposalState.Active, "ImpactDAO: Proposal not active");
        require(milestoneIndex < proposal.milestones.length, "ImpactDAO: Invalid milestone index");
        require(proposal.milestones[milestoneIndex].completedByProposer, "ImpactDAO: Milestone not submitted for completion by proposer");
        require(!proposal.milestones[milestoneIndex].challenged, "ImpactDAO: Milestone is challenged, awaiting dispute resolution");
        require(!proposal.milestones[milestoneIndex].verifiedByOracle, "ImpactDAO: Milestone already verified by oracle");

        proposal.milestones[milestoneIndex].verifiedByOracle = verified;
        emit OracleMilestoneVerified(proposalId, milestoneIndex, verified);

        // If not verified, proposer might be subject to reputation slash or proposal cancellation (advanced logic).
    }

    /// @dev Releases funds for an approved and verified milestone to the project proposer.
    /// @param proposalId The ID of the proposal.
    /// @param milestoneIndex The index of the milestone to release funds for.
    function releaseMilestonePayment(uint256 proposalId, uint256 milestoneIndex) public nonReentrant whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "ImpactDAO: Proposal does not exist");
        require(proposal.state == ProposalState.Active, "ImpactDAO: Proposal not active");
        require(milestoneIndex < proposal.milestones.length, "ImpactDAO: Invalid milestone index");
        require(proposal.milestones[milestoneIndex].completedByProposer, "ImpactDAO: Milestone not submitted by proposer");
        require(proposal.milestones[milestoneIndex].verifiedByOracle, "ImpactDAO: Milestone not verified by oracle");
        require(!proposal.milestones[milestoneIndex].challenged, "ImpactDAO: Milestone challenged, awaiting dispute resolution");
        require(!proposal.milestones[milestoneIndex].fundsReleased, "ImpactDAO: Milestone payment already released");
        // Check if there are enough earmarked funds for this milestone.
        require(proposal.fundedAmount >= proposal.milestones[milestoneIndex].amount, "ImpactDAO: Insufficient earmarked funds for milestone");

        Milestone storage milestone = proposal.milestones[milestoneIndex];
        uint256 paymentAmount = milestone.amount;

        milestone.fundsReleased = true;
        IMPACT_TOKEN.transfer(proposal.proposer, paymentAmount); // Transfer funds from DAO treasury to proposer.

        // Decrement the remaining earmarked funds for the proposal.
        proposal.fundedAmount = proposal.fundedAmount.sub(paymentAmount); 

        emit MilestonePaymentReleased(proposalId, milestoneIndex, paymentAmount);

        // Check if all milestones are completed to update proposal state.
        bool allMilestonesCompleted = true;
        for (uint256 i = 0; i < proposal.milestones.length; i++) {
            if (!proposal.milestones[i].fundsReleased) {
                allMilestonesCompleted = false;
                break;
            }
        }

        if (allMilestonesCompleted) {
            proposal.state = ProposalState.Completed;
            emit ProposalStateChanged(proposalId, ProposalState.Completed);
            _grantReputation(proposal.proposer, 100); // Example: Grant reputation for successful project completion.
        }
    }

    // VI. Dispute Resolution Mechanism

    /// @dev Initiates a formal dispute (e.g., reputation challenge, milestone dispute, proposal outcome).
    /// @param subjectId The ID of the subject being disputed (e.g., proposal ID, or a packed user ID).
    /// @param dType The type of dispute.
    /// @param evidenceHash IPFS hash for evidence related to the dispute.
    /// @return The ID of the newly created dispute.
    function initiateDispute(uint256 subjectId, DisputeType dType, bytes32 evidenceHash) public whenNotPaused returns (uint256) {
        require(getReputation(msg.sender) >= arbiterMinReputation, "ImpactDAO: Not enough reputation to initiate dispute");
        // Transfer dispute bond from initiator to DAO treasury.
        require(IMPACT_TOKEN.transferFrom(msg.sender, address(this), disputeBondAmount), "ImpactDAO: Insufficient dispute bond or allowance");

        uint256 disputeId = nextDisputeId++;
        Dispute storage newDispute = disputes[disputeId];

        newDispute.subjectId = subjectId;
        newDispute.dType = dType;
        newDispute.evidenceHash = evidenceHash;
        newDispute.initiator = msg.sender;
        newDispute.initiationTime = block.timestamp;
        newDispute.votingEndTime = block.timestamp.add(disputeVotingPeriod);
        newDispute.state = DisputeState.Voting;

        emit DisputeInitiated(disputeId, subjectId, dType, msg.sender);
        return disputeId;
    }

    /// @dev Arbiters cast votes on active disputes.
    /// @param disputeId The ID of the dispute to vote on.
    /// @param decision The arbiter's decision (true for 'Yes', false for 'No').
    function voteOnDispute(uint256 disputeId, bool decision) public whenNotPaused {
        Dispute storage dispute = disputes[disputeId];
        require(dispute.initiator != address(0), "ImpactDAO: Dispute does not exist");
        require(dispute.state == DisputeState.Voting, "ImpactDAO: Dispute not in voting state");
        require(block.timestamp <= dispute.votingEndTime, "ImpactDAO: Dispute voting period has ended");

        address voter = getDelegatedReputationPower(msg.sender); // Use effective voter (self or delegatee).
        require(getReputation(voter) >= arbiterMinReputation, "ImpactDAO: Not enough reputation to be an arbiter");
        require(!dispute.votedArbiters[voter], "ImpactDAO: Already voted on this dispute");

        uint256 voterReputation = getReputation(voter);
        if (decision) {
            dispute.yesVotes = dispute.yesVotes.add(voterReputation);
        } else {
            dispute.noVotes = dispute.noVotes.add(voterReputation);
        }
        dispute.votedArbiters[voter] = true;

        emit DisputeVoteCast(disputeId, msg.sender, decision);
    }

    /// @dev Finalizes a dispute based on arbiter votes and applies consequences.
    /// @param disputeId The ID of the dispute to resolve.
    function resolveDispute(uint256 disputeId) public nonReentrant whenNotPaused {
        Dispute storage dispute = disputes[disputeId];
        require(dispute.initiator != address(0), "ImpactDAO: Dispute does not exist");
        require(dispute.state == DisputeState.Voting, "ImpactDAO: Dispute not in voting state");
        require(block.timestamp > dispute.votingEndTime, "ImpactDAO: Dispute voting period has not ended yet");

        dispute.state = DisputeState.Resolved;
        bool outcome = false; // Default outcome (e.g., 'No' wins or insufficient votes).

        uint256 totalVotes = dispute.yesVotes.add(dispute.noVotes);
        if (totalVotes == 0) {
            // No votes cast, default outcome (e.g., original state stands).
            outcome = false; 
        } else {
            // Check if 'Yes' votes meet the resolution threshold.
            if (dispute.yesVotes.mul(disputeResolutionThresholdDenominator) > totalVotes.mul(disputeResolutionThresholdNumerator)) {
                outcome = true; // 'Yes' side wins.
            } else {
                outcome = false; // 'No' side wins or tie/insufficient 'Yes' votes.
            }
        }

        // Apply consequences based on dispute type and outcome.
        if (dispute.dType == DisputeType.MilestoneCompletion) {
            // Assuming `dispute.subjectId` is `proposalId` and `dispute.evidenceHash` points to `milestoneIndex`.
            // Realistically, this would require unpacking subjectId or direct parameters for proposalId and milestoneIndex.
            Proposal storage p = proposals[dispute.subjectId];
            if (p.proposer != address(0)) { // Ensure proposal exists.
                // Simple placeholder logic: if dispute says milestone is NOT verified (outcome=false)
                if (!outcome) { // Proposer's milestone claim was rejected.
                    _slashReputation(p.proposer, 50); // Example slash for proposer.
                    // Option: Challenger gets a reward/bond back.
                } else { // Proposer's milestone claim was validated (outcome=true).
                    // Option: Challenger loses bond.
                }
            }
        } else if (dispute.dType == DisputeType.ReputationChallenge) {
            // For a reputation challenge, subjectId would typically encode the user address.
            // If outcome is TRUE, means reputation is valid (challenger loses bond).
            // If outcome is FALSE, means reputation is invalid (user is slashed, challenger gets reward).
            // This would require more complex mapping for `subjectId` to an address.
            // Simplified: if (!outcome) _slashReputation(targetAddress, slashAmount);
        }
        // Dispute bond management: In a real system, the bond would be returned to winner or distributed.
        // For simplicity here, bond is consumed by the DAO for dispute system maintenance.

        emit DisputeResolved(disputeId, dispute.state, outcome);
    }

    // VII. DAO Treasury & Meta-Governance

    /// @dev Allows anyone to deposit IMPACT_TOKENs into the DAO treasury.
    /// Requires prior approval for the DAO contract to transfer tokens from sender's account.
    /// @param amount The amount of IMPACT_TOKENs to deposit.
    function depositFunds(uint256 amount) public whenNotPaused {
        require(IMPACT_TOKEN.transferFrom(msg.sender, address(this), amount), "ImpactDAO: Token transfer failed");
        emit FundsDeposited(msg.sender, amount);
    }

    /// @dev Allows the DAO's governance (owner) to withdraw funds from the treasury.
    /// In a fully decentralized DAO, this function would be callable only by a successful governance proposal execution.
    /// @param recipient The address to send funds to.
    /// @param amount The amount of IMPACT_TOKENs to withdraw.
    function withdrawTreasuryFunds(address recipient, uint256 amount) public nonReentrant whenNotPaused {
        // This 'owner' check is a placeholder. In a full DAO, this would be an `executeProposal` type call.
        require(msg.sender == owner(), "ImpactDAO: Only DAO owner/governance can withdraw treasury funds"); 
        require(IMPACT_TOKEN.balanceOf(address(this)) >= amount, "ImpactDAO: Insufficient treasury balance");
        require(recipient != address(0), "ImpactDAO: Invalid recipient address");

        IMPACT_TOKEN.transfer(recipient, amount);
        emit FundsWithdrawn(recipient, amount);
    }

    /// @dev Allows the DAO to change core governance parameters (meta-governance).
    /// This function should ideally be triggered by a successful meta-governance proposal.
    /// @param paramName The name of the parameter to update (e.g., "proposalVotingPeriod").
    /// @param newValue The new value for the parameter.
    function updateGovernanceParameter(bytes32 paramName, uint256 newValue) public nonReentrant whenNotPaused {
        // This 'owner' check is a placeholder for DAO governance control.
        require(msg.sender == owner(), "ImpactDAO: Only DAO governance can update parameters"); 

        if (paramName == "minReputationToPropose") {
            minReputationToPropose = newValue;
        } else if (paramName == "proposalVotingPeriod") {
            proposalVotingPeriod = newValue;
        } else if (paramName == "milestoneReviewPeriod") {
            milestoneReviewPeriod = newValue;
        } else if (paramName == "disputeVotingPeriod") {
            disputeVotingPeriod = newValue;
        } else if (paramName == "arbiterMinReputation") {
            arbiterMinReputation = newValue;
        } else if (paramName == "proposalPassThresholdNumerator") {
            proposalPassThresholdNumerator = newValue;
        } else if (paramName == "proposalPassThresholdDenominator") {
            require(newValue > 0, "Denominator cannot be zero");
            proposalPassThresholdDenominator = newValue;
        } else if (paramName == "disputeResolutionThresholdNumerator") {
            disputeResolutionThresholdNumerator = newValue;
        } else if (paramName == "disputeResolutionThresholdDenominator") {
            require(newValue > 0, "Denominator cannot be zero");
            disputeResolutionThresholdDenominator = newValue;
        } else if (paramName == "disputeBondAmount") {
            disputeBondAmount = newValue;
        } else {
            revert("ImpactDAO: Unknown governance parameter");
        }
        emit GovernanceParameterUpdated(paramName, newValue);
    }

    // IX. Utility & View Functions

    /// @dev Returns comprehensive details for a specific proposal.
    /// @param proposalId The ID of the proposal.
    /// @return A tuple containing all relevant proposal details.
    function getProposalDetails(uint256 proposalId) public view returns (
        address proposer,
        string memory title,
        string memory description,
        bytes32 metadataHash,
        uint256 requestedAmount,
        uint256 fundedAmount,
        uint256 submissionTime,
        uint256 votingEndTime,
        ProposalState state,
        uint256 totalReputationSupport,
        uint256 milestoneCount
    ) {
        Proposal storage p = proposals[proposalId];
        require(p.proposer != address(0), "ImpactDAO: Proposal does not exist"); // Check if proposal is initialized.
        return (
            p.proposer,
            p.title,
            p.description,
            p.metadataHash,
            p.requestedAmount,
            p.fundedAmount,
            p.submissionTime,
            p.votingEndTime,
            p.state,
            p.totalReputationSupport,
            p.milestones.length
        );
    }

    /// @dev Returns details for a specific milestone within a proposal.
    /// @param proposalId The ID of the proposal.
    /// @param milestoneIndex The index of the milestone.
    /// @return A tuple containing all relevant milestone details.
    function getMilestoneDetails(uint256 proposalId, uint256 milestoneIndex) public view returns (
        uint256 amount,
        bytes32 milestoneHash,
        bool completedByProposer,
        bool verifiedByOracle,
        bool challenged,
        bool fundsReleased
    ) {
        Proposal storage p = proposals[proposalId];
        require(p.proposer != address(0), "ImpactDAO: Proposal does not exist");
        require(milestoneIndex < p.milestones.length, "ImpactDAO: Invalid milestone index");
        Milestone storage m = p.milestones[milestoneIndex];
        return (
            m.amount,
            m.milestoneHash,
            m.completedByProposer,
            m.verifiedByOracle,
            m.challenged,
            m.fundsReleased
        );
    }

    /// @dev Returns details for a specific dispute.
    /// @param disputeId The ID of the dispute.
    /// @return A tuple containing all relevant dispute details.
    function getDisputeDetails(uint256 disputeId) public view returns (
        uint256 subjectId,
        DisputeType dType,
        bytes32 evidenceHash,
        address initiator,
        uint256 initiationTime,
        uint256 votingEndTime,
        DisputeState state,
        uint256 yesVotes,
        uint256 noVotes
    ) {
        Dispute storage d = disputes[disputeId];
        require(d.initiator != address(0), "ImpactDAO: Dispute does not exist");
        return (
            d.subjectId,
            d.dType,
            d.evidenceHash,
            d.initiator,
            d.initiationTime,
            d.votingEndTime,
            d.state,
            d.yesVotes,
            d.noVotes
        );
    }

    /// @dev Helper function to demonstrate the square root calculation used for quadratic voting.
    /// @param reputationCommitted The raw reputation committed by a voter.
    /// @return The effective (square root) voting score.
    function getQuadraticVotingScore(uint256 reputationCommitted) public pure returns (uint256) {
        return Math.sqrt(reputationCommitted);
    }

    /// @dev Allows an authorized entity (e.g., owner, or DAO governance) to grant reputation to a user.
    /// @param user The address to grant reputation to.
    /// @param amount The amount of reputation to grant.
    function grantReputation(address user, uint256 amount) public onlyOwner {
        _grantReputation(user, amount);
    }

    /// @dev Allows an authorized entity (e.g., owner, or DAO governance) to slash reputation from a user.
    /// @param user The address to slash reputation from.
    /// @param amount The amount of reputation to slash.
    function slashReputation(address user, uint256 amount) public onlyOwner {
        _slashReputation(user, amount);
    }
}
```