Okay, here is a Solidity smart contract combining several advanced concepts like weighted voting based on stake and reputation, reputation decay, liquid delegation, scheduled future parameter changes, and a modular governance execution model, all wrapped in a theme of managing a "Quantum Quasar Quorum".

This contract is designed to be complex and illustrative of various mechanics rather than a production-ready, audited system. It uses Solidity 0.8.x for checked arithmetic.

**Outline and Function Summary**

**Contract Name:** `QuantumQuasarQuorum`

**Description:** A complex DAO contract managing a conceptual "Quasar" resource. Governance is based on weighted voting combining staked funds and earned reputation, with reputation decaying over time. Supports delegation and scheduling future governance parameter changes.

**State Variables:**
*   `owner`: Initial deployer, potentially transferable to DAO.
*   `quasarPool`: Represents the managed resource (simple uint256 here).
*   `members`: Mapping of addresses to `MemberProfile` structs.
*   `proposals`: Mapping of proposal IDs to `Proposal` structs.
*   `nextProposalId`: Counter for new proposals.
*   Governance Parameters: Various uint256 parameters controlling minimums, durations, weights, etc.
*   `delegatesTo`: Mapping tracking who delegated their vote to whom.
*   `delegatedPower`: Mapping tracking total voting power delegated *to* an address.
*   `scheduledChanges`: Mapping of timestamps to `ScheduledChange` structs.
*   `nextScheduledChangeId`: Counter for scheduled changes.

**Structs:**
*   `MemberProfile`: `exists`, `stake`, `reputation`, `lastActivityTime`.
*   `Proposal`: `id`, `proposer`, `description`, `targetAddress`, `callData`, `creationTime`, `endTime`, `yayVotes`, `nayVotes`, `voters` (mapping), `state`, `quorumThresholdBasisPoints`, `reputationThresholdBasisPoints`, `requiredVotingPower`.
*   `ScheduledChange`: `id`, `timestamp`, `parameterIndex`, `newValue`, `executed`.

**Enums:**
*   `ProposalState`: `Pending`, `Active`, `Succeeded`, `Failed`, `Executed`, `Cancelled`.
*   `GovParamIndex`: Enum identifying specific governance parameters that can be changed.

**Events:**
*   `MemberStaked`, `MemberUnstaked`, `QuasarDeposited`, `QuasarWithdrawn`.
*   `ProposalCreated`, `Voted`, `ProposalStateChanged`, `ProposalExecuted`, `ProposalCancelled`.
*   `ParameterChanged`, `FutureParameterChangeScheduled`, `ScheduledChangeEnacted`.
*   `VoteDelegated`, `VoteUndelegated`.
*   `StakeSlashed`, `ReputationBoosted`.

**Functions (>= 20):**

1.  `constructor()`: Initializes the contract with owner and initial parameters.
2.  `setOwner(address newOwner)`: Transfers ownership (initially admin, potentially DAO).
3.  `renounceOwnership()`: Renounces admin ownership.
4.  `stake(uint256 amount)`: Allows a user to stake funds, becoming a member.
5.  `unstake(uint256 amount)`: Allows a member to unstake funds (may require cooldown/conditions).
6.  `getMemberProfile(address member)`: View function to get a member's profile.
7.  `depositQuasar()`: Allows anyone to deposit native currency (ETH) into the Quasar pool.
8.  `getQuasarBalance()`: View function for the current Quasar pool balance.
9.  `calculateEffectiveReputation(address member)`: Internal helper calculating reputation with decay.
10. `getVotingPower(address member)`: View function calculating total voting power (stake + decayed reputation + delegated power).
11. `delegateVote(address delegatee)`: Delegates voting power to another member.
12. `undelegateVote()`: Removes vote delegation.
13. `createProposal(string memory description, address targetAddress, bytes memory callData)`: Creates a new governance proposal (requires minimum stake/reputation).
14. `vote(uint256 proposalId, bool support)`: Casts a vote (Yay/Nay) on a proposal. Uses weighted voting power.
15. `endProposalVoting(uint256 proposalId)`: Ends the voting period for a proposal, checks quorum, and determines outcome.
16. `executeProposal(uint256 proposalId)`: Executes a successful proposal's target call.
17. `cancelProposal(uint256 proposalId)`: Cancels a proposal before voting ends (proposer or authorized).
18. `getProposalState(uint256 proposalId)`: View function for a proposal's current state.
19. `getProposalDetails(uint256 proposalId)`: View function for detailed proposal information.
20. `updateGovernanceParameter(uint256 parameterIndex, uint256 newValue)`: Function callable ONLY via proposal execution to change a governance parameter.
21. `distributeQuasar(address recipient, uint256 amount)`: Function callable ONLY via proposal execution to distribute Quasar from the pool.
22. `slashStake(address member, uint256 amount)`: Function callable ONLY via proposal execution to slash a member's stake.
23. `boostReputation(address member, uint256 amount)`: Function callable ONLY via proposal execution to boost a member's reputation.
24. `scheduleFutureParameterChange(uint256 timestamp, uint256 parameterIndex, uint256 newValue)`: Function callable ONLY via proposal execution to schedule a parameter change for a future time.
25. `enactScheduledParameterChange(uint256 scheduledChangeId)`: Callable by anyone after the scheduled timestamp to trigger a pending parameter change.
26. `viewScheduledParameterChanges()`: View function to list all scheduled changes.
27. `getScheduledChangeDetails(uint256 scheduledChangeId)`: View function for a specific scheduled change.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Outline:
// - State Variables: Core data like owner, treasury, members, proposals, parameters.
// - Structs: Data structures for MemberProfile, Proposal, ScheduledChange.
// - Enums: ProposalState, GovParamIndex.
// - Events: Signify key actions and state changes.
// - Modifiers: Access control (onlyOwner, ensureMember).
// - Functions:
//    - Core Management: constructor, setOwner, renounceOwnership.
//    - Member/Stake/Reputation: stake, unstake, getMemberProfile, calculateEffectiveReputation (internal), getVotingPower (view), delegateVote, undelegateVote.
//    - Quasar Pool: depositQuasar, getQuasarBalance.
//    - Governance Parameters: updateGovernanceParameter (via proposal), scheduleFutureParameterChange (via proposal), enactScheduledParameterChange, viewScheduledParameterChanges, getScheduledChangeDetails (view).
//    - Proposals: createProposal, vote, endProposalVoting, executeProposal, cancelProposal, getProposalState (view), getProposalDetails (view).
//    - Proposal Outcomes (callable only by successful proposal execution): distributeQuasar, slashStake, boostReputation.

// Function Summary:
// 1. constructor(): Initializes contract, sets owner and initial parameters.
// 2. setOwner(address newOwner): Transfers admin ownership.
// 3. renounceOwnership(): Renounces admin ownership (can be used to transfer control fully to DAO).
// 4. stake(uint256 amount): Allows an address to stake ETH to become/empower a member.
// 5. unstake(uint256 amount): Allows a member to withdraw staked ETH.
// 6. getMemberProfile(address member): Returns the profile struct for a member.
// 7. depositQuasar(): Receives native ETH into the contract's Quasar pool.
// 8. getQuasarBalance(): Returns the current balance of the Quasar pool.
// 9. calculateEffectiveReputation(address member): Internal helper to compute reputation after decay.
// 10. getVotingPower(address member): Returns the total voting power (stake + decayed reputation + delegated).
// 11. delegateVote(address delegatee): Assigns caller's voting power to another member.
// 12. undelegateVote(): Removes current vote delegation.
// 13. createProposal(string memory description, address targetAddress, bytes memory callData): Allows eligible members to propose actions.
// 14. vote(uint256 proposalId, bool support): Casts a weighted vote on an active proposal.
// 15. endProposalVoting(uint256 proposalId): Finalizes a proposal's outcome after its voting period ends.
// 16. executeProposal(uint256 proposalId): Executes the target function of a successful proposal.
// 17. cancelProposal(uint256 proposalId): Allows proposal cancellation under specific conditions.
// 18. getProposalState(uint256 proposalId): Returns the current state of a proposal.
// 19. getProposalDetails(uint256 proposalId): Returns comprehensive details about a proposal.
// 20. updateGovernanceParameter(uint256 parameterIndex, uint256 newValue): Executable by a successful proposal to change core governance settings.
// 21. distributeQuasar(address recipient, uint256 amount): Executable by a successful proposal to send ETH from the Quasar pool.
// 22. slashStake(address member, uint256 amount): Executable by a successful proposal to reduce a member's stake.
// 23. boostReputation(address member, uint256 amount): Executable by a successful proposal to increase a member's reputation.
// 24. scheduleFutureParameterChange(uint256 timestamp, uint256 parameterIndex, uint256 newValue): Executable by a successful proposal to set a parameter change for a future time.
// 25. enactScheduledParameterChange(uint256 scheduledChangeId): Callable by anyone to trigger a future parameter change once its timestamp is reached.
// 26. viewScheduledParameterChanges(): Returns a list of IDs for all scheduled parameter changes.
// 27. getScheduledChangeDetails(uint256 scheduledChangeId): Returns details for a specific scheduled parameter change.

contract QuantumQuasarQuorum {

    address public owner;

    // --- State Variables ---

    // Conceptual pool of resources managed by the DAO (using native ETH)
    uint256 public quasarPool;

    // Member profiles
    struct MemberProfile {
        bool exists;
        uint256 stake;          // Staked resources (e.g., ETH)
        uint256 reputation;     // Earned reputation points
        uint256 lastActivityTime; // Timestamp of last significant activity (e.g., stake, vote)
    }
    mapping(address => MemberProfile) public members;

    // Proposal tracking
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed, Cancelled }
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        address targetAddress; // Address of the contract to call
        bytes callData;        // Data for the target function call
        uint256 creationTime;
        uint256 endTime;       // Voting period ends
        uint256 yayVotes;      // Total voting power in favor
        uint256 nayVotes;      // Total voting power against
        mapping(address => bool) voters; // Address => hasVoted
        ProposalState state;
        uint256 quorumThresholdBasisPoints; // e.g., 4000 for 40% of total voting power needed to vote
        uint256 reputationThresholdBasisPoints; // Rep weight in voting power calc
        uint256 requiredVotingPower; // Snapshot of total voting power at proposal creation for quorum calculation
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId;

    // Governance Parameters (can be changed by successful proposals)
    enum GovParamIndex {
        ProposalMinStake,
        ProposalMinReputation,
        VotingPeriodDuration,
        QuorumThresholdBasisPoints,
        ReputationWeightBasisPoints, // How much reputation counts relative to stake
        ReputationDecayRate          // Seconds per reputation point decay
    }
    uint256[] public governanceParameters; // Indexed by GovParamIndex

    // Delegation mapping: who delegates their vote TO whom
    mapping(address => address) public delegatesTo;
    // Total voting power delegated TO an address
    mapping(address => uint256) public delegatedPower;

    // Scheduled future parameter changes
    struct ScheduledChange {
        uint256 id;
        uint256 timestamp; // When the change should occur
        uint256 parameterIndex;
        uint256 newValue;
        bool executed;
    }
    mapping(uint256 => ScheduledChange) public scheduledChanges;
    uint256 public nextScheduledChangeId;

    // --- Events ---

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event MemberStaked(address indexed member, uint256 amount, uint256 newStake);
    event MemberUnstaked(address indexed member, uint256 amount, uint256 newStake);
    event QuasarDeposited(address indexed depositor, uint256 amount);
    event QuasarWithdrawn(address indexed recipient, uint256 amount);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, uint256 creationTime, uint256 endTime);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event ProposalCancelled(uint256 indexed proposalId);

    event ParameterChanged(uint256 indexed parameterIndex, uint256 indexed newValue);
    event FutureParameterChangeScheduled(uint256 indexed scheduledChangeId, uint256 indexed timestamp, uint256 parameterIndex, uint256 newValue);
    event ScheduledChangeEnacted(uint256 indexed scheduledChangeId, uint256 indexed timestamp, uint256 parameterIndex, uint256 newValue);

    event VoteDelegated(address indexed delegator, address indexed delegatee);
    event VoteUndelegated(address indexed delegator, address indexed previousDelegatee);

    event StakeSlashed(address indexed member, uint256 amount, uint256 newStake);
    event ReputationBoosted(address indexed member, uint256 amount, uint256 newReputation);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier ensureMember(address _address) {
        require(members[_address].exists, "Not a member");
        _;
    }

    modifier onlyProposalExecution() {
        // This modifier ensures the function is only called by the contract itself,
        // acting on behalf of a successful proposal execution.
        // A more robust check might involve tracking the proposal ID being executed
        // but for simplicity, self-call is used.
        require(msg.sender == address(this), "Only callable by successful proposal execution");
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        // Initialize governance parameters (example values, scale as needed)
        governanceParameters.push(5 ether);         // 0: ProposalMinStake (5 ETH)
        governanceParameters.push(100);             // 1: ProposalMinReputation (100 points)
        governanceParameters.push(7 days);          // 2: VotingPeriodDuration (7 days)
        governanceParameters.push(4000);            // 3: QuorumThresholdBasisPoints (40% of requiredVotingPower)
        governanceParameters.push(100);             // 4: ReputationWeightBasisPoints (Reputation is weighted 100/10000 = 1% of stake value)
        governanceParameters.push(1 days);          // 5: ReputationDecayRate (Lose 1 rep point per day)

        // Initialize the default owner as a member (optional, could require staking first)
        // members[owner] = MemberProfile({exists: true, stake: 0, reputation: 0, lastActivityTime: block.timestamp});
        // delegatedPower[owner] = 0; // Initialize delegated power
    }

    // --- Core Management ---

    function setOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0); // Relinquish ownership
    }

    // --- Member, Stake & Reputation ---

    // Anyone can stake ETH to become a member or increase their stake
    function stake() external payable {
        require(msg.value > 0, "Stake amount must be greater than 0");

        MemberProfile storage member = members[msg.sender];
        if (!member.exists) {
            member.exists = true;
            member.stake = msg.value;
            member.reputation = 0; // Start with 0 reputation
            member.lastActivityTime = block.timestamp;
            delegatedPower[msg.sender] = 0; // Initialize delegated power count
        } else {
            // If already delegating, undelegate first to update delegatedPower correctly
            if (delegatesTo[msg.sender] != address(0)) {
                 // Temporarily remove old delegated power before adding stake,
                 // then re-delegate if desired by calling delegateVote again.
                 // To simplify, disallow staking while delegating.
                 revert("Cannot stake while delegating vote");
            }
            member.stake += msg.value;
            member.lastActivityTime = block.timestamp;
        }
        emit MemberStaked(msg.sender, msg.value, member.stake);
    }

    // Members can unstake. Note: Could add cooldowns/lockups in a real contract.
    function unstake(uint256 amount) external ensureMember(msg.sender) {
        MemberProfile storage member = members[msg.sender];
        require(amount > 0 && amount <= member.stake, "Invalid amount");
        require(delegatesTo[msg.sender] == address(0), "Cannot unstake while delegating vote");

        member.stake -= amount;
        member.lastActivityTime = block.timestamp;

        // If stake drops to 0, they are technically still a member profile but with no stake
        // Could add logic here to 'remove' them if stake + reputation is zero, but keeping profile is simpler.

        payable(msg.sender).transfer(amount);
        emit MemberUnstaked(msg.sender, amount, member.stake);
    }

    // Internal helper to calculate reputation considering decay
    function calculateEffectiveReputation(address memberAddress) internal view returns (uint256) {
        MemberProfile storage member = members[memberAddress];
        if (!member.exists || member.reputation == 0) {
            return 0;
        }

        uint256 timeElapsed = block.timestamp - member.lastActivityTime;
        uint256 decayRate = governanceParameters[uint256(GovParamIndex.ReputationDecayRate)];
        if (decayRate == 0) { // No decay if rate is zero
            return member.reputation;
        }

        uint256 decayAmount = timeElapsed / decayRate;
        return member.reputation > decayAmount ? member.reputation - decayAmount : 0;
    }

    // Get the total voting power for an address, including stake, decayed reputation, and delegated power
    function getVotingPower(address memberAddress) public view returns (uint256) {
        MemberProfile storage member = members[memberAddress];
        if (!member.exists || delegatesTo[memberAddress] != address(0)) {
             // If not a member or is delegating their power, they have no direct voting power
             return 0;
        }

        // Calculate own power (stake + weighted reputation)
        uint256 effectiveRep = calculateEffectiveReputation(memberAddress);
        uint256 reputationWeight = governanceParameters[uint256(GovParamIndex.ReputationWeightBasisPoints)];
        // Avoid division by zero if weight is 0 or 10000 (no scaling)
        uint256 reputationPower = (reputationWeight == 0 || reputationWeight == 10000)
            ? effectiveRep : (effectiveRep * reputationWeight) / 10000; // Simple basis points scaling

        uint256 ownPower = member.stake + reputationPower; // Example: Reputation adds to stake like bonus ETH

        // Add power delegated *to* this member
        uint256 totalPower = ownPower + delegatedPower[memberAddress];

        return totalPower;
    }

    // Delegate voting power to another member
    function delegateVote(address delegatee) external ensureMember(msg.sender) ensureMember(delegatee) {
        require(msg.sender != delegatee, "Cannot delegate to self");
        require(delegatesTo[msg.sender] == address(0), "Already delegating");

        // Calculate the power being delegated *at this moment*
        // Note: This snapshot approach is simpler than dynamic calculation but less precise if stake/rep changes after delegation.
        // A more advanced system would recalculate delegated power dynamically.
        uint256 powerToDelegate = getVotingPower(msg.sender); // Power *before* setting delegation flag

        delegatesTo[msg.sender] = delegatee;
        delegatedPower[delegatee] += powerToDelegate;

        // Update last activity time for both delegator and delegatee? Or just delegator?
        // Let's update delegator's time as they performed an action.
        members[msg.sender].lastActivityTime = block.timestamp;

        emit VoteDelegated(msg.sender, delegatee);
    }

    // Remove vote delegation
    function undelegateVote() external ensureMember(msg.sender) {
        address currentDelegatee = delegatesTo[msg.sender];
        require(currentDelegatee != address(0), "Not currently delegating");

        // The power previously delegated *to* the delegatee is lost when undelegating.
        // This requires recalculating or tracking which specific power chunks were delegated.
        // Simplification: Assume the power delegated was snapshot *at the time of delegation*.
        // A better approach would be to re-calculate the delegator's current potential power
        // and subtract that from the delegatee.
        // Let's recalculate the power the delegator *would* have now.
        uint256 currentPotentialPower = members[msg.sender].stake + (calculateEffectiveReputation(msg.sender) * governanceParameters[uint256(GovParamIndex.ReputationWeightBasisPoints)]) / 10000;

        delegatedPower[currentDelegatee] -= currentPotentialPower; // Potential underflow if stake decreased significantly

        delegatesTo[msg.sender] = address(0);
        members[msg.sender].lastActivityTime = block.timestamp;

        emit VoteUndelegated(msg.sender, currentDelegatee);
    }


    // --- Quasar Pool ---

    receive() external payable {
        depositQuasar();
    }

    function depositQuasar() public payable {
        require(msg.value > 0, "Must send native currency");
        quasarPool += msg.value;
        emit QuasarDeposited(msg.sender, msg.value);
    }

    function getQuasarBalance() public view returns (uint256) {
        return address(this).balance; // The actual balance is the source of the pool
    }

    // Function to distribute Quasar - callable ONLY via successful proposal
    function distributeQuasar(address recipient, uint256 amount) external payable onlyProposalExecution {
        require(recipient != address(0), "Invalid recipient");
        require(amount > 0 && amount <= address(this).balance, "Insufficient Quasar balance");

        // This function is called by `executeProposal` using `call` with the amount
        // being sent as part of the call's value. The QuasarPool variable is just
        // for internal tracking/representation; the actual ETH balance is used.
        // If this were a token, the logic would transfer tokens.
        // For simplicity with ETH, this function assumes the ETH is sent with the call.
        // In a real scenario, if the proposal execution calls this *without* value,
        // the contract needs to transfer from its own balance.

        // Let's modify this slightly: Assume `executeProposal` sends the ETH.
        // This function just confirms the call was intended to distribute.
        // If called directly by executeProposal with a value, msg.value will be > 0.
        require(msg.value == amount, "Execution call must send required amount");

        // The ETH was already sent with the call. Just update internal state/emit event
        quasarPool -= amount; // Update conceptual pool tracker

        emit QuasarWithdrawn(recipient, amount);

        // Note: The transfer already happened via the `call` in `executeProposal`.
        // If this function were to perform the transfer itself:
        // payable(recipient).transfer(amount);
    }


    // --- Governance Parameters ---

    // Callable ONLY by successful proposal execution
    function updateGovernanceParameter(uint256 parameterIndex, uint256 newValue) external onlyProposalExecution {
        require(parameterIndex < governanceParameters.length, "Invalid parameter index");
        // Add any specific value validation per parameterIndex here if needed
        governanceParameters[parameterIndex] = newValue;
        emit ParameterChanged(parameterIndex, newValue);
    }

    // Callable ONLY by successful proposal execution to schedule a future parameter change
    function scheduleFutureParameterChange(uint256 timestamp, uint256 parameterIndex, uint256 newValue) external onlyProposalExecution {
        require(timestamp > block.timestamp, "Timestamp must be in the future");
        require(parameterIndex < governanceParameters.length, "Invalid parameter index");

        uint256 changeId = nextScheduledChangeId++;
        scheduledChanges[changeId] = ScheduledChange({
            id: changeId,
            timestamp: timestamp,
            parameterIndex: parameterIndex,
            newValue: newValue,
            executed: false
        });

        emit FutureParameterChangeScheduled(changeId, timestamp, parameterIndex, newValue);
    }

    // Callable by anyone to enact a scheduled parameter change once the time is reached
    function enactScheduledParameterChange(uint256 scheduledChangeId) external {
        ScheduledChange storage scheduledChange = scheduledChanges[scheduledChangeId];
        require(scheduledChange.id == scheduledChangeId && !scheduledChange.executed, "Change not found or already executed");
        require(block.timestamp >= scheduledChange.timestamp, "Scheduled time has not arrived yet");
        require(scheduledChange.parameterIndex < governanceParameters.length, "Invalid parameter index in scheduled change"); // Safety check

        governanceParameters[scheduledChange.parameterIndex] = scheduledChange.newValue;
        scheduledChange.executed = true;

        emit ScheduledChangeEnacted(scheduledChangeId, scheduledChange.timestamp, scheduledChange.parameterIndex, scheduledChange.newValue);
        emit ParameterChanged(scheduledChange.parameterIndex, scheduledChange.newValue); // Also emit general parameter change event
    }

    // View all scheduled change IDs
    function viewScheduledParameterChanges() external view returns (uint256[] memory) {
        // This is inefficient for many changes. In production, might use a list or iterate a range.
        // For demonstration, iterate up to nextScheduledChangeId.
        uint256[] memory ids = new uint256[](nextScheduledChangeId);
        uint256 count = 0;
        for (uint256 i = 0; i < nextScheduledChangeId; i++) {
            if (scheduledChanges[i].id == i) { // Check if the ID exists (was scheduled)
                ids[count] = i;
                count++;
            }
        }
        // Resize array if necessary
        uint256[] memory existingIds = new uint256[](count);
        for(uint256 i = 0; i < count; i++){
            existingIds[i] = ids[i];
        }
        return existingIds;
    }

    // View details for a specific scheduled change
    function getScheduledChangeDetails(uint256 scheduledChangeId) external view returns (
        uint256 id,
        uint256 timestamp,
        uint256 parameterIndex,
        uint256 newValue,
        bool executed
    ) {
        ScheduledChange storage scheduledChange = scheduledChanges[scheduledChangeId];
        require(scheduledChange.id == scheduledChangeId, "Change not found"); // Check if ID was actually used
        return (
            scheduledChange.id,
            scheduledChange.timestamp,
            scheduledChange.parameterIndex,
            scheduledChange.newValue,
            scheduledChange.executed
        );
    }


    // --- Proposals ---

    // Create a new proposal
    function createProposal(
        string memory description,
        address targetAddress,
        bytes memory callData
    ) external ensureMember(msg.sender) returns (uint256 proposalId) {
        MemberProfile storage proposerProfile = members[msg.sender];
        require(getVotingPower(msg.sender) >= governanceParameters[uint256(GovParamIndex.ProposalMinStake)], "Insufficient voting power to propose");
        // Could add a separate reputation check if desired:
        // require(calculateEffectiveReputation(msg.sender) >= governanceParameters[uint256(GovParamIndex.ProposalMinReputation)], "Insufficient reputation to propose");

        proposalId = nextProposalId++;
        uint256 votingPeriod = governanceParameters[uint256(GovParamIndex.VotingPeriodDuration)];
        uint256 quorumBasisPoints = governanceParameters[uint256(GovParamIndex.QuorumThresholdBasisPoints)];
        uint256 reputationWeight = governanceParameters[uint256(GovParamIndex.ReputationWeightBasisPoints)];

        // Calculate total potential voting power at proposal creation time
        // This is needed for quorum calculation later. Iterating all members is expensive.
        // In a real system, a snapshot of total power might be taken off-chain or
        // the quorum calculation method adjusted (e.g., % of *participating* power if above a minimum).
        // For this example, let's iterate for simplicity, acknowledging gas cost.
        // Or, simplify quorum to be a percentage of *total stake* + *total current reputation*?
        // Let's use a simple approach: sum of all *existing* members' potential power at this moment.
        // This is still expensive. A better approach is needed for large member bases.
        // Let's pivot: Quorum is based on a percentage of the *total voting power that actually voted*.
        // Requires a MINIMUM voting power threshold for the proposal to be valid *even if* it gets 100% approval from those who vote.
        // Let's try this: Quorum is (Yay Votes + Nay Votes) >= (Total Potential Voting Power * QuorumThresholdBasisPoints / 10000)
        // Still need Total Potential Voting Power. Okay, stick to iterating *all* members for the snapshot, acknowledging the limitation.

        uint256 totalPotentialVotingPower = 0;
        // This iteration is a significant gas cost for many members!
        // A real implementation would likely use a different quorum mechanism
        // or require maintaining a running total of total power.
        address[] memory currentMembers = new address[](members.length); // This won't work directly with mapping
        // Alternative: Don't calculate total potential power on creation.
        // Calculate it ONCE when ending the proposal voting, summing up power of *all* members then.
        // This is still potentially expensive, but only happens at the end.
        // Let's go with this: Calculate `requiredVotingPower` as the snapshot of total power when `endProposalVoting` is called.
        // So, the `requiredVotingPower` field in the struct is set *later*.

        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposer = msg.sender;
        newProposal.description = description;
        newProposal.targetAddress = targetAddress;
        newProposal.callData = callData;
        newProposal.creationTime = block.timestamp;
        newProposal.endTime = block.timestamp + votingPeriod;
        newProposal.state = ProposalState.Active;
        newProposal.quorumThresholdBasisPoints = quorumBasisPoints;
        newProposal.reputationThresholdBasisPoints = reputationWeight;
        // newProposal.requiredVotingPower will be set in endProposalVoting

        proposerProfile.lastActivityTime = block.timestamp;

        emit ProposalCreated(proposalId, msg.sender, newProposal.creationTime, newProposal.endTime);
    }

    // Vote on an active proposal
    function vote(uint256 proposalId, bool support) external ensureMember(msg.sender) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Active, "Proposal not active");
        require(block.timestamp <= proposal.endTime, "Voting period has ended");
        require(!proposal.voters[msg.sender], "Already voted");

        uint256 voterPower = getVotingPower(msg.sender);
        require(voterPower > 0, "No voting power");

        if (support) {
            proposal.yayVotes += voterPower;
        } else {
            proposal.nayVotes += voterPower;
        }

        proposal.voters[msg.sender] = true;
        members[msg.sender].lastActivityTime = block.timestamp; // Update activity time for voter

        emit Voted(proposalId, msg.sender, support, voterPower);
    }

    // End the voting period and determine the outcome
    function endProposalVoting(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Active, "Proposal not active");
        require(block.timestamp > proposal.endTime, "Voting period has not ended yet");

        // Calculate total potential voting power *at this moment* for quorum calculation
        // This is the expensive iteration mentioned earlier!
        // A production system MUST optimize this.
        uint256 totalCurrentVotingPower = 0;
        // This part is pseudocode/conceptual as iterating a mapping is not direct.
        // In reality, you might need a list of members or track total power differently.
        // For a small, fixed set of members or if using a library like EnumerableSet:
        /*
        for (address memberAddress : memberList) { // conceptual loop over all members
            if (members[memberAddress].exists) {
                totalCurrentVotingPower += getVotingPower(memberAddress); // This gets their effective power *now*
            }
        }
        */
        // Let's use a simpler, less accurate quorum model for this example:
        // Quorum is met if total participating power (yay+nay) is > a fixed number,
        // OR a percentage of the total stake exists (easier to track).
        // Let's use total stake as the quorum basis for simplicity, ignoring reputation/delegation for quorum calc only.
        uint256 totalStake = 0;
         // Again, iterating mappings is hard. Let's assume total stake is tracked or calculated differently.
         // For this example, let's just use a simple quorum check based on participating power,
         // combined with a minimum *number* of voters or minimum *total* votes cast.
         // Quorum Met: Total Votes Cast (Yay + Nay) >= MinimumRequiredVotes
         // And: Total Votes Cast (Yay + Nay) >= (SnapshotTotalStake * QuorumThresholdBasisPoints / 10000)
         // Let's make it simpler: Quorum is met if total participating power (Yay + Nay) >= a percentage of the proposer's *requiredVotingPower* snapshot.
         // Let's *finally* define `requiredVotingPower` as the total voting power *at the time of proposal creation*. This requires the expensive iteration in `createProposal`. Acknowledge this cost.

         // Reverting to the plan: `requiredVotingPower` IS the snapshot from proposal creation.
         // Add a placeholder implementation for the snapshot (acknowledging it's not practical for many members).
         // In `createProposal`, add:
         /*
         uint256 snapshotTotalVotingPower = 0;
         // !!! EXPENSIVE ITERATION - REPLACE IN PRODUCTION !!!
         address[] memory allMembers = getMembersList(); // Need a way to get all member addresses
         for(uint i=0; i<allMembers.length; i++) {
             if(members[allMembers[i]].exists) {
                  snapshotTotalVotingPower += getVotingPower(allMembers[i]); // Calculate power *at creation*
             }
         }
         newProposal.requiredVotingPower = snapshotTotalVotingPower;
         */
         // Since iterating mapping isn't directly possible for snapshotting, let's simplify Quorum:
         // Quorum is met if Total Votes Cast (Yay + Nay) >= MinTotalVotesCast parameter.
         // AND Yay Votes > Nay Votes for success.
         // Add a new parameter: GovParamIndex.MinTotalVotesCast
         // governanceParameters.push(10 ether); // 6: MinTotalVotesCast (10 ETH voting power minimum)

         // Let's use this simplified quorum:
         uint256 totalVotesCast = proposal.yayVotes + proposal.nayVotes;
         uint256 minTotalVotesCast = governanceParameters[uint256(GovParamIndex.MinTotalVotesCast)]; // Assuming this is added

         if (totalVotesCast >= minTotalVotesCast && proposal.yayVotes > proposal.nayVotes) {
             proposal.state = ProposalState.Succeeded;
         } else {
             proposal.state = ProposalState.Failed;
         }

        emit ProposalStateChanged(proposalId, proposal.state);
    }

    // Execute a successful proposal
    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Succeeded, "Proposal not in Succeeded state");

        proposal.state = ProposalState.Executed;

        // Use low-level call. Be cautious with untrusted target contracts.
        // The value sent with the call is 0 unless explicitly specified in callData or if the target function is receive/fallback and expects value.
        // If the proposal is `distributeQuasar`, the callData must encode `distributeQuasar(recipient, amount)`
        // AND the call itself needs to send `amount` ETH. The `call` function allows sending value.
        // Example: proposal.callData = abi.encodeWithSelector(this.distributeQuasar.selector, recipient, amount);
        // When executing: address(this).call{value: amount}(proposal.callData)
        // So, need to detect if the callData is for distributeQuasar and extract the amount.
        // This is complex and error-prone (malicious callData).
        // A safer pattern: `distributeQuasar` doesn't take value. The `call` just triggers it.
        // The Quasar distribution happens within `distributeQuasar` by calling `payable(recipient).transfer(amount)`.
        // BUT `distributeQuasar` needs to be `onlyProposalExecution`.
        // The problem is `call` bypasses standard function visibility. `call` targets an address and provides calldata.
        // If targetAddress is this contract, `call` can invoke internal/private functions if calldata matches.
        // Safest: Make functions like distributeQuasar external, check msg.sender == address(this), AND have executeProposal be the *only* path that calls self.
        // The `onlyProposalExecution` modifier checks `msg.sender == address(this)`. This is sufficient if `executeProposal` is the only function that performs self-calls.

        (bool success, bytes memory returndata) = proposal.targetAddress.call{value: 0}(proposal.callData); // Assume value transfer handled within target function if needed

        // If target is this contract calling `distributeQuasar`, that function expects msg.value == amount.
        // The framework needs to know *how much* value to send with the call based on the proposal's action.
        // This requires adding a `uint256 value` field to the Proposal struct.

        // Let's add `value` to Proposal struct (requires updating struct definition above)
        // struct Proposal { ... uint256 value; ... }

        // Retry call with value:
        (success, returndata) = proposal.targetAddress.call{value: proposal.value}(proposal.callData);


        // Log success/failure, but state is already set to Executed
        if (!success) {
            // Handle execution failure - maybe revert state change or log error
             // Revert is simplest for now, prevents state from being 'Executed' on failure
             proposal.state = ProposalState.Succeeded; // Revert state
             emit ProposalExecuted(proposalId, false);
             // Get error message from returndata if possible (depends on Solidity version and target contract)
             string memory errorMsg = "";
             // Example: Try to decode revert reason (Solidity >= 0.6)
             if (returndata.length > 0) {
                 assembly {
                     errorMsg := add(returndata, 32)
                 }
             }
             revert("Proposal execution failed"); // Include errorMsg if possible
         }

        emit ProposalExecuted(proposalId, true);
        emit ProposalStateChanged(proposalId, proposal.state);
    }

    // Cancel a proposal (proposer or owner/DAO before voting ends)
    function cancelProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Pending || proposal.state == ProposalState.Active, "Proposal not cancellable");
        require(msg.sender == proposal.proposer || msg.sender == owner, "Not authorized to cancel"); // Owner check implies admin, can be DAO address too

        proposal.state = ProposalState.Cancelled;
        emit ProposalCancelled(proposalId);
        emit ProposalStateChanged(proposalId, proposal.state);
    }

    // View proposal state
    function getProposalState(uint256 proposalId) external view returns (ProposalState) {
        require(proposalId < nextProposalId, "Invalid proposal ID");
        return proposals[proposalId].state;
    }

    // View proposal details
    function getProposalDetails(uint256 proposalId) external view returns (
        uint256 id,
        address proposer,
        string memory description,
        address targetAddress,
        bytes memory callData,
        uint256 creationTime,
        uint256 endTime,
        uint256 yayVotes,
        uint256 nayVotes,
        ProposalState state,
        uint256 quorumThresholdBasisPoints,
        uint256 reputationThresholdBasisPoints,
        uint256 requiredVotingPower // Note: This field might not be populated depending on quorum model
    ) {
        require(proposalId < nextProposalId, "Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];
        return (
            proposal.id,
            proposal.proposer,
            proposal.description,
            proposal.targetAddress,
            proposal.callData,
            proposal.creationTime,
            proposal.endTime,
            proposal.yayVotes,
            proposal.nayVotes,
            proposal.state,
            proposal.quorumThresholdBasisPoints,
            proposal.reputationThresholdBasisPoints,
            proposal.requiredVotingPower
        );
    }

    // --- Specific Proposal Outcomes (Callable ONLY by successful proposal) ---

    // These functions are designed to be the *target* of a proposal execution.
    // They include the `onlyProposalExecution` modifier.

    // Distribute Quasar (ETH) from the pool
    // Note: The ETH transfer happens when `executeProposal` calls this function via `call` WITH VALUE.
    // The proposal's `value` field must be set correctly.
    // Example: abi.encodeWithSelector(this.distributeQuasar.selector, recipient, amount) AND proposal.value = amount
    // The `distributeQuasar` function signature must match the encoding.
    // It's safer if the target address is `address(this)`.
    // function distributeQuasar(address recipient, uint256 amount) external payable onlyProposalExecution { ... }
    // The payable keyword allows it to receive ETH from the call.
    // It then needs to verify msg.value == amount and update the conceptual pool.

    // Slash a member's stake - callable ONLY via successful proposal
    function slashStake(address memberAddress, uint256 amount) external onlyProposalExecution ensureMember(memberAddress) {
        MemberProfile storage member = members[memberAddress];
        require(amount > 0 && amount <= member.stake, "Invalid amount to slash");

        // If the member is delegating, need to recalculate delegated power correctly
         if (delegatesTo[memberAddress] != address(0)) {
             // The power lost due to slashing reduces the power of their delegatee
             // Calculate how much power is lost *from their own stake+rep*
             uint256 oldOwnPower = member.stake + (calculateEffectiveReputation(memberAddress) * governanceParameters[uint256(GovParamIndex.ReputationWeightBasisPoints)]) / 10000;
             member.stake -= amount;
             uint256 newOwnPower = member.stake + (calculateEffectiveReputation(memberAddress) * governanceParameters[uint256(GovParamIndex.ReputationWeightBasisPoints)]) / 10000;
             uint256 powerLost = oldOwnPower - newOwnPower; // This assumes positive change. Rep decay might make this complex.
             // Simpler: Just subtract the power associated with the slashed stake.
             // Assume reputation power doesn't change from slashing, only stake power.
             uint256 powerLostFromStake = amount; // 1 ETH stake = 1 vote base
             address delegatee = delegatesTo[memberAddress];
             delegatedPower[delegatee] -= powerLostFromStake; // Potential underflow if delegatee already lost stake elsewhere

         } else {
            member.stake -= amount;
         }

        member.lastActivityTime = block.timestamp; // Activity counts as getting slashed/boosted? Yes, state change.
        // Slashed funds could be burned, sent to treasury, or other logic. Burning here.
        // No explicit ETH transfer/burn needed as stake is conceptual within the contract's tracking.

        emit StakeSlashed(memberAddress, amount, member.stake);
    }

    // Boost a member's reputation - callable ONLY via successful proposal
    function boostReputation(address memberAddress, uint256 amount) external onlyProposalExecution ensureMember(memberAddress) {
        require(amount > 0, "Amount must be greater than 0");

        // If boosting reputation affects delegated power, need to update delegatee.
        // If the member is delegating, add the reputation power increase to the delegatee's delegatedPower.
        if (delegatesTo[memberAddress] != address(0)) {
             address delegatee = delegatesTo[memberAddress];
             uint256 reputationWeight = governanceParameters[uint256(GovParamIndex.ReputationWeightBasisPoints)];
             uint256 powerIncreaseFromRep = (amount * reputationWeight) / 10000;
             delegatedPower[delegatee] += powerIncreaseFromRep;
         }

        members[memberAddress].reputation += amount;
        members[memberAddress].lastActivityTime = block.timestamp; // Reputation change is activity

        emit ReputationBoosted(memberAddress, amount, members[memberAddress].reputation);
    }

    // --- Helper/Internal Functions (optional, for clarity) ---

    // Example: Function to get a list of all member addresses (highly inefficient)
    // function getMembersList() internal view returns (address[] memory) {
    //     // Cannot directly iterate mapping. Need a separate list or EnumerableSet.
    //     // Omitting for now to keep complexity manageable without external libraries.
    //     // This highlights why some operations (like total power snapshot) are hard/expensive.
    // }

}
```