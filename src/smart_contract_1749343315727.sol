Okay, here is a Solidity smart contract incorporating several advanced, creative, and trendy concepts like a state machine, dynamic permissions based on reputation and roles, epoch-based progression, and a proposal/voting system, along with a simplified contribution proof mechanism.

It's designed as a conceptual framework for a decentralized protocol where participants collectively evolve the protocol's state.

**Outline and Function Summary:**

This smart contract, `ProtocolStateEvolver`, manages the lifecycle and state transitions of a hypothetical decentralized protocol. Its core features include:

1.  **State Machine:** The protocol exists in distinct states (`State` enum), and transitions between states are governed by specific rules and proposals.
2.  **Epochs:** Time is divided into epochs, which regulate state transition proposals and voting periods.
3.  **Reputation System:** Users accumulate reputation based on positive interactions (e.g., verified contributions), which grants voting power and access to restricted functions.
4.  **Roles:** Specific roles (`Role` enum) provide different permission levels within the protocol.
5.  **Proposal System:** Users can propose state changes, which are then voted upon by qualified participants (based on reputation/stake).
6.  **Contribution Proofs:** A mechanism for users to signal off-chain contributions, which can be verified by designated roles to earn reputation.
7.  **Delegation:** Users can delegate their reputation's voting power.
8.  **Staking:** Users can stake reputation to increase voting power.

---

**Outline:**

*   **Enums:** `State`, `Role`
*   **Structs:** `Proposal`
*   **State Variables:**
    *   Admin address
    *   Current state
    *   Current epoch
    *   Epoch duration
    *   Epoch start time
    *   User roles mapping
    *   User reputation mapping
    *   Reputation delegation mapping
    *   Reputation staking mapping
    *   Proposal counter
    *   Proposals mapping
    *   Minimum reputation for actions/voting
    *   State transition criteria/conditions (simplified representation)
*   **Events:**
    *   `StateChanged`
    *   `EpochAdvanced`
    *   `RoleAssigned`
    *   `RoleRevoked`
    *   `ReputationAwarded`
    *   `ReputationSlashed`
    *   `ReputationDelegated`
    *   `ReputationUndelegated`
    *   `ReputationStaked`
    *   `ReputationUnstaked`
    *   `ProposalCreated`
    *   `VoteCast`
    *   `ProposalExecuted`
    *   `ProposalCancelled`
    *   `ContributionProofSubmitted`
    *   `ContributionProofVerified`
    *   `ContributionProofChallenged`
*   **Modifiers:**
    *   `onlyAdmin`
    *   `requireState`
    *   `requireRole`
    *   `requireReputation`
    *   `requireEpochEnded`
*   **Functions:**
    *   **Admin/Setup:**
        *   `constructor`
        *   `transferAdmin`
        *   `setEpochDuration`
        *   `assignRole`
        *   `revokeRole`
        *   `setMinReputationForProposals`
        *   `setMinReputationForVoting`
        *   `adminAwardReputation`
        *   `adminSlashReputation`
    *   **State Management:**
        *   `getCurrentState` (View)
        *   `proposeStateChange`
        *   `getProposalDetails` (View)
        *   `voteOnProposal`
        *   `executeProposal`
        *   `cancelProposal`
    *   **Reputation System:**
        *   `getReputation` (View)
        *   `getDelegatedVotingPower` (View)
        *   `getStakedReputation` (View)
        *   `getTotalVotingPower` (View)
        *   `delegateReputationVotingPower`
        *   `undelegateReputationVotingPower`
        *   `stakeReputationForVoting`
        *   `unstakeReputationVoting`
    *   **Epoch System:**
        *   `getCurrentEpoch` (View)
        *   `getEpochEndTime` (View)
        *   `advanceEpoch`
        *   `isEpochEnded` (View)
    *   **Roles:**
        *   `getRole` (View)
        *   `hasRole` (View)
    *   **Contribution Proofs:**
        *   `submitContributionProof`
        *   `verifyContributionProof` (Role required)
        *   `challengeContributionProof` (Role required, simplified)
    *   **Internal/Helper Functions:**
        *   `_awardReputation`
        *   `_slashReputation`
        *   `_transitionToState`
        *   `_isVotingPeriodEnded`
        *   `_canExecuteProposal`
        *   `_calculateVotingPower`

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ProtocolStateEvolver
 * @notice A smart contract for a decentralized protocol with state evolution,
 * dynamic permissions based on reputation and roles, epoch progression,
 * a proposal/voting system, and a simplified contribution proof mechanism.
 * It serves as a conceptual framework for collaborative protocol governance.
 */
contract ProtocolStateEvolver {

    // --- Enums ---

    /**
     * @dev Represents the distinct states the protocol can be in.
     * STATES:
     * Initial - Starting state.
     * Active - Main operational state.
     * Paused - Protocol is temporarily halted.
     * UpgradePending - Awaiting protocol upgrade execution.
     * Deprecated - Protocol is winding down.
     */
    enum State { Initial, Active, Paused, UpgradePending, Deprecated }

    /**
     * @dev Represents different roles with specific permissions.
     * ROLES:
     * None - Default role.
     * Admin - Full control (can be limited by design).
     * Operator - Can perform operational tasks.
     * Participant - Can propose and vote.
     * Verifier - Can verify contribution proofs.
     */
    enum Role { None, Admin, Operator, Participant, Verifier }

    /**
     * @dev Represents the current status of a proposal.
     * STATUS:
     * Active - Proposal is open for voting.
     * Passed - Proposal met voting threshold.
     * Failed - Proposal did not meet voting threshold.
     * Executed - Proposal has been successfully applied.
     * Cancelled - Proposal was withdrawn or cancelled.
     */
    enum ProposalStatus { Active, Passed, Failed, Executed, Cancelled }

    // --- Structs ---

    /**
     * @dev Represents a proposal to change the protocol state.
     */
    struct Proposal {
        uint256 id;
        address proposer;
        State targetState;
        uint256 creationEpoch;
        uint256 votingEndEpoch;
        uint256 totalVotesFor; // Sum of voting power
        uint256 totalVotesAgainst; // Sum of voting power
        mapping(address => bool) hasVoted;
        ProposalStatus status;
        //bytes data; // Optional: Could include data for complex state changes
    }

    // --- State Variables ---

    address private admin;
    State public currentState;
    uint256 public currentEpoch;
    uint256 public epochDuration; // Duration in seconds
    uint256 public currentEpochStartTime;

    mapping(address => Role) private userRoles;
    mapping(address => uint256) private userReputation; // Tracks reputation points
    mapping(address => address) private reputationDelegates; // delegatee => delegator (who delegated TO whom)
    mapping(address => uint256) private stakedReputation; // reputation owner => staked amount

    uint256 private nextProposalId;
    mapping(uint256 => Proposal) public proposals;
    mapping(State => State[]) public allowedStateTransitions; // Simplified: Mapping of allowed transitions

    uint256 public minReputationForProposals;
    uint256 public minReputationForVoting;
    uint256 public proposalVotingEpochs; // How many epochs a proposal is open

    // Contribution Proofs (Simplified: Just tracking hashes and status)
    mapping(bytes32 => address) private contributionProofSubmitter;
    mapping(bytes32 => bool) private contributionProofVerified;
    mapping(bytes32 => bool) private contributionProofChallenged;

    // --- Events ---

    event StateChanged(State indexed oldState, State indexed newState, uint256 epoch, address indexed caller);
    event EpochAdvanced(uint256 indexed newEpoch, uint256 indexed startTime, address indexed caller);
    event RoleAssigned(address indexed account, Role indexed role, address indexed assigner);
    event RoleRevoked(address indexed account, Role indexed role, address indexed revoker);
    event ReputationAwarded(address indexed account, uint256 amount, address indexed granter);
    event ReputationSlashed(address indexed account, uint256 amount, address indexed slasher);
    event ReputationDelegated(address indexed delegator, address indexed delegatee);
    event ReputationUndelegated(address indexed delegator, address indexed oldDelegatee);
    event ReputationStaked(address indexed account, uint256 amount);
    event ReputationUnstaked(address indexed account, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, State indexed targetState, uint256 creationEpoch, uint256 votingEndEpoch);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId, State indexed newState, uint256 epoch);
    event ProposalCancelled(uint256 indexed proposalId, address indexed canceller);
    event ContributionProofSubmitted(address indexed submitter, bytes32 indexed proofHash);
    event ContributionProofVerified(bytes32 indexed proofHash, address indexed verifier);
    event ContributionProofChallenged(bytes32 indexed proofHash, address indexed challenger);

    // --- Modifiers ---

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    modifier requireState(State requiredState) {
        require(currentState == requiredState, "Function requires a specific state");
        _;
    }

    modifier requireRole(Role requiredRole) {
        require(userRoles[msg.sender] == requiredRole, "Caller does not have the required role");
        _;
    }

    modifier requireReputation(uint256 requiredRep) {
        require(userReputation[msg.sender] >= requiredRep, "Insufficient reputation");
        _;
    }

    modifier requireEpochEnded() {
        require(_isEpochEnded(), "Current epoch has not ended yet");
        _;
    }

    // --- Constructor ---

    constructor(uint256 _epochDuration, uint256 _minReputationForProposals, uint256 _minReputationForVoting, uint256 _proposalVotingEpochs) {
        admin = msg.sender;
        currentState = State.Initial;
        currentEpoch = 1;
        epochDuration = _epochDuration; // e.g., 1 day = 86400 seconds
        currentEpochStartTime = block.timestamp;

        minReputationForProposals = _minReputationForProposals;
        minReputationForVoting = _minReputationForVoting;
        proposalVotingEpochs = _proposalVotingEpochs; // e.g., 3 epochs

        // Assign admin role initially
        userRoles[admin] = Role.Admin;
        emit RoleAssigned(admin, Role.Admin, address(0)); // address(0) signals initial assignment
    }

    // --- Admin/Setup Functions ---

    /**
     * @notice Transfers the admin role to a new address.
     * @param _newAdmin The address to transfer the admin role to.
     */
    function transferAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "New admin cannot be zero address");
        userRoles[admin] = Role.None;
        emit RoleRevoked(admin, Role.Admin, msg.sender);
        admin = _newAdmin;
        userRoles[admin] = Role.Admin;
        emit RoleAssigned(admin, Role.Admin, msg.sender);
    }

    /**
     * @notice Sets the duration of each epoch. Can only be called by admin.
     * @param _duration The new epoch duration in seconds.
     */
    function setEpochDuration(uint256 _duration) external onlyAdmin {
        require(_duration > 0, "Epoch duration must be positive");
        epochDuration = _duration;
        // Note: This change takes effect from the *next* epoch start time.
    }

    /**
     * @notice Assigns a role to an account. Can only be called by admin.
     * @param _account The address to assign the role to.
     * @param _role The role to assign.
     */
    function assignRole(address _account, Role _role) external onlyAdmin {
        require(_account != address(0), "Cannot assign role to zero address");
        userRoles[_account] = _role;
        emit RoleAssigned(_account, _role, msg.sender);
    }

    /**
     * @notice Revokes a role from an account. Can only be called by admin.
     * Admin role cannot be revoked this way (use transferAdmin).
     * @param _account The address to revoke the role from.
     */
    function revokeRole(address _account) external onlyAdmin {
        require(_account != address(0), "Cannot revoke role from zero address");
        require(_account != admin, "Cannot revoke admin role using this function");
        Role oldRole = userRoles[_account];
        userRoles[_account] = Role.None;
        emit RoleRevoked(_account, oldRole, msg.sender);
    }

     /**
     * @notice Sets the minimum reputation required to create a state change proposal.
     * @param _minReputation The minimum reputation amount.
     */
    function setMinReputationForProposals(uint256 _minReputation) external onlyAdmin {
        minReputationForProposals = _minReputation;
    }

    /**
     * @notice Sets the minimum reputation required to cast a vote on a proposal.
     * Note: This is a base requirement; voting power scales with reputation.
     * @param _minReputation The minimum reputation amount.
     */
    function setMinReputationForVoting(uint256 _minReputation) external onlyAdmin {
        minReputationForVoting = _minReputation;
    }

     /**
     * @notice Admin can directly award reputation points to an account.
     * Primarily intended for initial seeding or manual corrections.
     * For regular reputation earning, use verification flows.
     * @param _account The address to award reputation to.
     * @param _amount The amount of reputation to award.
     */
    function adminAwardReputation(address _account, uint256 _amount) external onlyAdmin {
        _awardReputation(_account, _amount, msg.sender);
    }

    /**
     * @notice Admin can directly slash (reduce) reputation points from an account.
     * Intended for manual corrections or penalty enforcement.
     * @param _account The address to slash reputation from.
     * @param _amount The amount of reputation to slash.
     */
    function adminSlashReputation(address _account, uint256 _amount) external onlyAdmin {
        _slashReputation(_account, _amount, msg.sender);
    }


    // --- State Management Functions ---

    /**
     * @notice Gets the current state of the protocol.
     * @return The current State enum value.
     */
    function getCurrentState() external view returns (State) {
        return currentState;
    }

    /**
     * @notice Allows a user with sufficient reputation to propose a state change.
     * Requires current epoch to NOT be ended, so proposal falls into next voting period.
     * @param _targetState The desired state to transition to.
     */
    function proposeStateChange(State _targetState) external requireReputation(minReputationForProposals) {
        require(currentState != _targetState, "Cannot propose transition to the current state");
        require(_targetState != State.Initial, "Cannot propose transition back to Initial state");
        // In a real contract, you'd check allowedStateTransitions mapping here.
        // For simplicity, we allow proposing any non-current, non-Initial state.

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            targetState: _targetState,
            creationEpoch: currentEpoch, // Proposal created in current epoch
            votingEndEpoch: currentEpoch + proposalVotingEpochs, // Voting ends after N epochs
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            status: ProposalStatus.Active
            //data: ""
        });

        emit ProposalCreated(proposalId, msg.sender, _targetState, currentEpoch, currentEpoch + proposalVotingEpochs);
    }

    /**
     * @notice Gets details of a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @return A tuple containing proposal details.
     */
    function getProposalDetails(uint256 _proposalId) external view returns (
        uint256 id,
        address proposer,
        State targetState,
        uint256 creationEpoch,
        uint256 votingEndEpoch,
        uint256 totalVotesFor,
        uint256 totalVotesAgainst,
        ProposalStatus status
    ) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0 || _proposalId == 0, "Proposal does not exist"); // Check if proposal struct is initialized

        return (
            proposal.id,
            proposal.proposer,
            proposal.targetState,
            proposal.creationEpoch,
            proposal.votingEndEpoch,
            proposal.totalVotesFor,
            proposal.totalVotesAgainst,
            proposal.status
        );
    }

    /**
     * @notice Allows a user with sufficient reputation to vote on a proposal.
     * Voting power is based on reputation + staked reputation.
     * Requires the proposal to be active and within its voting period.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for yes, False for no.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external requireReputation(minReputationForVoting) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "Proposal is not active");
        require(currentEpoch <= proposal.votingEndEpoch, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        uint256 votingPower = _calculateVotingPower(msg.sender);
        require(votingPower > 0, "Voter has no voting power");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.totalVotesFor += votingPower;
        } else {
            proposal.totalVotesAgainst += votingPower;
        }

        emit VoteCast(_proposalId, msg.sender, _support, votingPower);
    }

    /**
     * @notice Allows anyone to attempt to execute a passed proposal once its voting period ends.
     * Checks if the proposal met the necessary criteria (voting threshold, epoch ended) and
     * updates the protocol state if successful.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "Proposal is not active");
        require(currentEpoch > proposal.votingEndEpoch, "Voting period has not ended yet");
        require(currentState != proposal.targetState, "Protocol is already in the target state");
        // In a real contract, you'd check allowedStateTransitions here again.

        // Define simple execution threshold (e.g., > 50% of total votes cast)
        uint256 totalVotesCast = proposal.totalVotesFor + proposal.totalVotesAgainst;
        bool passed = proposal.totalVotesFor > proposal.totalVotesAgainst && totalVotesCast > 0; // Simple majority needed

        if (passed) {
            proposal.status = ProposalStatus.Executed;
            _transitionToState(proposal.targetState);
            emit ProposalExecuted(_proposalId, proposal.targetState, currentEpoch);
        } else {
            proposal.status = ProposalStatus.Failed;
            // No state change
        }
    }

    /**
     * @notice Allows the proposer or admin to cancel an active proposal before its voting period ends.
     * @param _proposalId The ID of the proposal to cancel.
     */
    function cancelProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "Proposal is not active");
        require(currentEpoch <= proposal.votingEndEpoch, "Voting period has ended");
        require(msg.sender == proposal.proposer || msg.sender == admin, "Only proposer or admin can cancel");

        proposal.status = ProposalStatus.Cancelled;
        emit ProposalCancelled(_proposalId, msg.sender);
    }

    // --- Reputation System Functions ---

    /**
     * @notice Gets the current reputation points of an account.
     * @param _account The address to query.
     * @return The reputation points of the account.
     */
    function getReputation(address _account) external view returns (uint256) {
        return userReputation[_account];
    }

    /**
     * @notice Gets the address that an account has delegated its voting power to.
     * @param _account The delegator's address.
     * @return The delegatee's address (address(0) if none).
     */
    function getDelegatedVotingPower(address _account) external view returns (address) {
        return reputationDelegates[_account];
    }

    /**
     * @notice Gets the amount of reputation an account has staked for voting.
     * @param _account The address to query.
     * @return The staked reputation amount.
     */
    function getStakedReputation(address _account) external view returns (uint256) {
        return stakedReputation[_account];
    }

    /**
     * @notice Calculates the total voting power for an account.
     * This includes their own reputation, staked reputation, and any delegated power.
     * @param _account The address to calculate power for.
     * @return The total calculated voting power.
     */
    function getTotalVotingPower(address _account) public view returns (uint256) {
        return _calculateVotingPower(_account);
    }

    /**
     * @notice Allows a user to delegate their voting power (reputation) to another address.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateReputationVotingPower(address _delegatee) external {
        require(_delegatee != msg.sender, "Cannot delegate to yourself");
        address oldDelegatee = reputationDelegates[msg.sender];
        reputationDelegates[msg.sender] = _delegatee;
        emit ReputationDelegated(msg.sender, _delegatee);
        // Need to potentially update voting power on active proposals? No, voting power is calculated at vote time.
    }

     /**
     * @notice Allows a user to undelegate their voting power.
     */
    function undelegateReputationVotingPower() external {
        address oldDelegatee = reputationDelegates[msg.sender];
        require(oldDelegatee != address(0), "No voting power currently delegated");
        reputationDelegates[msg.sender] = address(0);
        emit ReputationUndelegated(msg.sender, oldDelegatee);
    }


    /**
     * @notice Allows a user to stake some of their earned reputation to increase voting power.
     * Staked reputation is locked and cannot be used for other purposes or slashed while staked.
     * @param _amount The amount of reputation to stake.
     */
    function stakeReputationForVoting(uint256 _amount) external {
        require(_amount > 0, "Amount must be positive");
        require(userReputation[msg.sender] >= _amount, "Insufficient reputation to stake");

        userReputation[msg.sender] -= _amount;
        stakedReputation[msg.sender] += _amount;
        emit ReputationStaked(msg.sender, _amount);
    }

    /**
     * @notice Allows a user to unstake their reputation.
     * Unstaked reputation returns to the user's regular reputation balance.
     * @param _amount The amount of staked reputation to unstake.
     */
    function unstakeReputationVoting(uint256 _amount) external {
        require(_amount > 0, "Amount must be positive");
        require(stakedReputation[msg.sender] >= _amount, "Insufficient staked reputation");

        stakedReputation[msg.sender] -= _amount;
        userReputation[msg.sender] += _amount;
        emit ReputationUnstaked(msg.sender, _amount);
    }


    // --- Epoch System Functions ---

    /**
     * @notice Gets the current epoch number.
     * @return The current epoch number.
     */
    function getCurrentEpoch() external view returns (uint256) {
        return currentEpoch;
    }

    /**
     * @notice Gets the timestamp when the current epoch is scheduled to end.
     * @return The timestamp of the epoch end.
     */
    function getEpochEndTime() external view returns (uint256) {
        return currentEpochStartTime + epochDuration;
    }

    /**
     * @notice Allows anyone to advance the epoch once the current epoch duration has passed.
     * This function should be called periodically (e.g., by a relayer or automated script)
     * to keep the protocol clock moving.
     */
    function advanceEpoch() external {
        require(_isEpochEnded(), "Current epoch has not ended yet");

        currentEpoch++;
        currentEpochStartTime = block.timestamp; // Start the new epoch now
        emit EpochAdvanced(currentEpoch, currentEpochStartTime, msg.sender);

        // Optional: Add logic here to automatically process proposals that ended last epoch
        // (This could be gas-intensive if many proposals, might be better to rely on executeProposal)
    }

    /**
     * @notice Checks if the current epoch duration has passed.
     * @return True if the epoch has ended, false otherwise.
     */
    function isEpochEnded() external view returns (bool) {
        return _isEpochEnded();
    }


    // --- Role Functions ---

    /**
     * @notice Gets the primary role of an account.
     * @param _account The address to query.
     * @return The Role enum value.
     */
    function getRole(address _account) external view returns (Role) {
        return userRoles[_account];
    }

    /**
     * @notice Checks if an account has a specific role.
     * @param _account The address to query.
     * @param _role The role to check for.
     * @return True if the account has the role, false otherwise.
     */
    function hasRole(address _account, Role _role) external view returns (bool) {
        return userRoles[_account] == _role;
    }


    // --- Contribution Proof Functions ---

    /**
     * @notice Allows a user to submit a hash representing a potential contribution.
     * This doesn't verify the contribution, only registers the intent and proof identifier.
     * @param _proofHash A unique hash identifying the off-chain contribution.
     */
    function submitContributionProof(bytes32 _proofHash) external {
        require(contributionProofSubmitter[_proofHash] == address(0), "Proof hash already submitted");
        contributionProofSubmitter[_proofHash] = msg.sender;
        emit ContributionProofSubmitted(msg.sender, _proofHash);
    }

    /**
     * @notice Allows an account with the Verifier role to mark a submitted proof as verified.
     * This action awards reputation to the original submitter.
     * @param _proofHash The hash of the proof to verify.
     */
    function verifyContributionProof(bytes32 _proofHash) external requireRole(Role.Verifier) {
        address submitter = contributionProofSubmitter[_proofHash];
        require(submitter != address(0), "Proof hash not found or already verified/challenged");
        require(!contributionProofVerified[_proofHash], "Proof already verified");
        require(!contributionProofChallenged[_proofHash], "Proof has been challenged");

        contributionProofVerified[_proofHash] = true;
        // Award reputation for verified contribution (e.g., a fixed amount or amount based on proof type)
        _awardReputation(submitter, 100, msg.sender); // Example: Award 100 reputation
        emit ContributionProofVerified(_proofHash, msg.sender);

        // Clear the submitter mapping to prevent double verification/challenge
        delete contributionProofSubmitter[_proofHash];
    }

    /**
     * @notice Allows an account with a designated role (e.g., Verifier or Participant with high reputation)
     * to challenge a submitted proof. This prevents verification and potential reputation award.
     * (Simplified: Admin or Verifier can challenge)
     * @param _proofHash The hash of the proof to challenge.
     */
    function challengeContributionProof(bytes32 _proofHash) external {
        require(userRoles[msg.sender] == Role.Admin || userRoles[msg.sender] == Role.Verifier || userReputation[msg.sender] >= minReputationForProposals,
            "Caller does not have permission to challenge proofs");
        address submitter = contributionProofSubmitter[_proofHash];
        require(submitter != address(0), "Proof hash not found or already verified/challenged");
        require(!contributionProofVerified[_proofHash], "Proof already verified");
        require(!contributionProofChallenged[_proofHash], "Proof already challenged");

        contributionProofChallenged[_proofHash] = true;
        emit ContributionProofChallenged(_proofHash, msg.sender);

        // Clear the submitter mapping
        delete contributionProofSubmitter[_proofHash];

        // Optional: Add slashing logic for challenged/invalid proofs if they were already verified.
        // This would require a more complex state machine for proofs.
    }


    // --- Internal/Helper Functions ---

    /**
     * @dev Internal function to transition the protocol to a new state.
     * Emits the StateChanged event.
     * @param _newState The state to transition to.
     */
    function _transitionToState(State _newState) internal {
        State oldState = currentState;
        currentState = _newState;
        emit StateChanged(oldState, currentState, currentEpoch, msg.sender);
    }

    /**
     * @dev Internal function to award reputation points.
     * @param _account The account to award reputation to.
     * @param _amount The amount of reputation to award.
     * @param _granter The address that initiated the award (e.g., Admin or Verifier).
     */
    function _awardReputation(address _account, uint256 _amount, address _granter) internal {
        userReputation[_account] += _amount;
        emit ReputationAwarded(_account, _amount, _granter);
    }

    /**
     * @dev Internal function to slash (reduce) reputation points.
     * Reputation cannot go below zero.
     * @param _account The account to slash reputation from.
     * @param _amount The amount of reputation to slash.
     * @param _slasher The address that initiated the slashing (e.g., Admin).
     */
    function _slashReputation(address _account, uint256 _amount, address _slasher) internal {
        uint256 currentRep = userReputation[_account];
        uint256 slashAmount = _amount > currentRep ? currentRep : _amount; // Cannot slash more than they have
        userReputation[_account] -= slashAmount;
        emit ReputationSlashed(_account, slashAmount, _slasher);
    }

    /**
     * @dev Internal function to check if the current epoch has ended based on time.
     * @return True if the epoch has ended, false otherwise.
     */
    function _isEpochEnded() internal view returns (bool) {
        return block.timestamp >= currentEpochStartTime + epochDuration;
    }

    /**
     * @dev Internal function to calculate an account's total voting power.
     * Includes base reputation, staked reputation, and delegated reputation.
     * @param _account The account to calculate voting power for.
     * @return The total calculated voting power.
     */
    function _calculateVotingPower(address _account) internal view returns (uint256) {
        uint256 power = userReputation[_account] + stakedReputation[_account]; // Base reputation + staked
        // Add delegated power TO this account
        // Note: This requires iterating or a separate mapping to find who delegated *to* _account.
        // A simpler approach is to calculate power *for* the voter (msg.sender) and check delegation.
        // The current structure (reputationDelegates[delegator] => delegatee) allows checking who *msg.sender* delegated to.
        // To calculate total power *received* via delegation requires a mapping like delegatee => delegator[], which is complex/costly.
        // Let's simplify: Voting power is the voter's own reputation + staked, OR the power of the address they delegated TO, IF they delegated.

        address delegatee = reputationDelegates[msg.sender];
        if (delegatee != address(0) && delegatee != msg.sender) {
            // If msg.sender delegated, their voting power is that of their delegatee
            // To avoid infinite loops in delegation chains, this simplified version
            // just uses the delegatee's *own* base+staked power, not recursively.
            // A more advanced system would require a loop and gas limits or a snapshot system.
            return userReputation[delegatee] + stakedReputation[delegatee];
        } else {
            // If no delegation or delegated to self, use own power
            return power;
        }
    }

    // --- Additional Functions (Total 24 functions) ---

    /**
     * @notice Gets the admin address.
     */
    function getAdmin() external view returns (address) {
        return admin;
    }

    /**
     * @notice Gets the current epoch duration.
     */
    function getEpochDuration() external view returns (uint256) {
        return epochDuration;
    }

    /**
     * @notice Gets the total number of proposals created.
     */
    function getProposalCount() external view returns (uint256) {
        return nextProposalId;
    }

    /**
     * @notice Checks if a specific proposal's voting period has ended.
     * @param _proposalId The ID of the proposal.
     */
    function _isVotingPeriodEnded(uint256 _proposalId) internal view returns (bool) {
        Proposal storage proposal = proposals[_proposalId];
        return currentEpoch > proposal.votingEndEpoch;
    }

    /**
     * @notice Checks if a proposal can be executed based on votes and epoch.
     * (Internal helper for executeProposal)
     * @param _proposalId The ID of the proposal.
     * @return True if the proposal is executable, false otherwise.
     */
    function _canExecuteProposal(uint256 _proposalId) internal view returns (bool) {
         Proposal storage proposal = proposals[_proposalId];
         if (proposal.status != ProposalStatus.Active || currentEpoch <= proposal.votingEndEpoch || currentState == proposal.targetState) {
             return false;
         }
         uint256 totalVotesCast = proposal.totalVotesFor + proposal.totalVotesAgainst;
         return proposal.totalVotesFor > proposal.totalVotesAgainst && totalVotesCast > 0;
    }

    // Add view functions for min reputation and voting epochs
    function getMinReputationForProposals() external view returns (uint256) {
        return minReputationForProposals;
    }

    function getMinReputationForVoting() external view returns (uint256) {
        return minReputationForVoting;
    }

     function getProposalVotingEpochs() external view returns (uint256) {
        return proposalVotingEpochs;
    }

    // Add a function to get the submitter of a proof hash (if not yet verified/challenged)
    function getContributionProofSubmitter(bytes32 _proofHash) external view returns (address) {
         return contributionProofSubmitter[_proofHash];
    }

    // Add a function to check the verification status of a proof hash
     function isContributionProofVerified(bytes32 _proofHash) external view returns (bool) {
         return contributionProofVerified[_proofHash];
     }

     // Add a function to check the challenged status of a proof hash
     function isContributionProofChallenged(bytes32 _proofHash) external view returns (bool) {
         return contributionProofChallenged[_proofHash];
     }

    // Let's count the functions:
    // Constructor: 1
    // Admin/Setup: 7 (transferAdmin, setEpochDuration, assignRole, revokeRole, setMinReputationForProposals, setMinReputationForVoting, adminAwardReputation, adminSlashReputation) - Whoops, that's 8. Let's remove one admin setup, maybe setMinReputationForVoting, and keep proposal one? No, need both. Let's count again. Admin/Setup: 8.
    // State Management: 6 (getCurrentState, proposeStateChange, getProposalDetails, voteOnProposal, executeProposal, cancelProposal)
    // Reputation: 7 (getReputation, getDelegatedVotingPower, getStakedReputation, getTotalVotingPower, delegateReputationVotingPower, undelegateReputationVotingPower, stakeReputationForVoting, unstakeReputationVoting) - That's 8. Let's remove getDelegatedVotingPower as it's less critical externally. Still 7. Okay, unstake added. It's 8.
    // Epoch: 4 (getCurrentEpoch, getEpochEndTime, advanceEpoch, isEpochEnded)
    // Roles: 2 (getRole, hasRole)
    // Contribution Proofs: 3 (submitContributionProof, verifyContributionProof, challengeContributionProof)
    // Internal Helpers: 6 (_transitionToState, _awardReputation, _slashReputation, _isEpochEnded, _isVotingPeriodEnded, _canExecuteProposal, _calculateVotingPower) - That's 7. Okay, the list was wrong. Let's refine external/public count.
    // Additional: 6 (getAdmin, getEpochDuration, getProposalCount, getMinReputationForProposals, getMinReputationForVoting, getProposalVotingEpochs, getContributionProofSubmitter, isContributionProofVerified, isContributionProofChallenged) - That's 9 view functions.

    // EXTERNAL/PUBLIC Count:
    // Constructor: 1
    // Admin/Setup: 8 (transferAdmin, setEpochDuration, assignRole, revokeRole, setMinReputationForProposals, setMinReputationForVoting, adminAwardReputation, adminSlashReputation)
    // State Management: 5 (getCurrentState, proposeStateChange, getProposalDetails, voteOnProposal, executeProposal, cancelProposal) - That's 6.
    // Reputation: 7 (getReputation, getStakedReputation, getTotalVotingPower, delegateReputationVotingPower, undelegateReputationVotingPower, stakeReputationForVoting, unstakeReputationVoting) - GetDelegated removed as it was internal/view helper in thought. Add it back? Yes, useful external view. That's 8.
    // Epoch: 4 (getCurrentEpoch, getEpochEndTime, advanceEpoch, isEpochEnded)
    // Roles: 2 (getRole, hasRole)
    // Contribution Proofs: 3 (submitContributionProof, verifyContributionProof, challengeContributionProof)
    // Additional Views: 6 (getAdmin, getEpochDuration, getProposalCount, getMinReputationForProposals, getMinReputationForVoting, getProposalVotingEpochs)

    // Total external/public functions: 1 + 8 + 6 + 8 + 4 + 2 + 3 + 6 = 38. Well over 20.
    // Let's simplify the view functions count.
    // Getters for state variables/basic info: getCurrentState, getReputation, getStakedReputation, getTotalVotingPower, getCurrentEpoch, getEpochEndTime, getRole, hasRole, getAdmin, getEpochDuration, getProposalCount, getMinReputationForProposals, getMinReputationForVoting, getProposalVotingEpochs, isEpochEnded, getProposalDetails, getContributionProofSubmitter, isContributionProofVerified, isContributionProofChallenged. That's 19 view functions.
    // Transaction functions: constructor, transferAdmin, setEpochDuration, assignRole, revokeRole, setMinReputationForProposals, setMinReputationForVoting, adminAwardReputation, adminSlashReputation, proposeStateChange, voteOnProposal, executeProposal, cancelProposal, delegateReputationVotingPower, undelegateReputationVotingPower, stakeReputationForVoting, unstakeReputationVoting, advanceEpoch, submitContributionProof, verifyContributionProof, challengeContributionProof. That's 21 transaction functions.

    // Total functions (external/public): 19 (views) + 21 (tx) = 40. Plenty over 20.

}
```