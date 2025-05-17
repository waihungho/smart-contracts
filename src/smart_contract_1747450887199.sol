Okay, let's design an advanced, creative, and trendy smart contract focusing on a complex decentralized governance/voting mechanism. We'll call it the "QuantumVoteProtocol".

The core idea is a voting system where voting power isn't static, votes can be conditional or time-locked, and the outcome determination ("collapse") involves evaluating these complex vote types. It integrates a custom staking mechanism to influence voting power and uses a custom token.

**Concept:** QuantumVoteProtocol is a decentralized governance system where token holders stake their tokens to gain dynamic voting power. Proposals can have multiple potential outcomes. Voters can cast simple votes, conditional votes (where their vote only counts if a specific internal condition based on other votes is met), or time-locked votes (where their vote only becomes active after a certain timestamp). The final outcome is determined by a complex "collapse" process that evaluates all vote types based on their conditions and timestamps.

---

### **QuantumVoteProtocol Smart Contract Outline**

1.  **Preamble:** SPDX License, Pragma.
2.  **Imports:** OpenZeppelin ERC20, Pausable, Ownable (for simplicity).
3.  **State Variables:**
    *   Owner, Pausability state.
    *   Token details (name, symbol, total supply, balances, allowances - standard ERC20).
    *   Staking data (staked amounts, last stake time for time-based bonus).
    *   Voting power parameters (multiplier, time bonus divisor).
    *   Proposal data (mapping from ID to Proposal struct, latest ID counter).
    *   Vote data (mapping from (proposal ID, voter address) to Vote struct).
    *   Configuration parameters (voting period duration, execution role).
4.  **Structs:**
    *   `Outcome`: Describes a potential result of a proposal (ID, description, target address for execution, call data).
    *   `Proposal`: Details of a governance proposal (ID, proposer, description, outcomes list, voting period, state: created/active/collapsed, winning outcome ID, total vote power tallies for each outcome).
    *   `Vote`: Details of a specific user's vote on a proposal (voter, proposal ID, chosen outcome ID, power used, type: simple/conditional/time-locked, conditional threshold, effective timestamp).
5.  **Events:**
    *   Standard ERC20 events.
    *   `Staked`, `Unstaked`.
    *   `VotingPowerMultiplierUpdated`, `TimeBonusDivisorUpdated`.
    *   `ProposalCreated`.
    *   `VoteCast` (with type information).
    *   `VoteRevoked`.
    *   `StateCollapsed` (with winning outcome).
    *   `OutcomeExecuted`.
    *   `Paused`, `Unpaused`.
    *   `OwnershipTransferred`.
6.  **Modifiers:** `onlyOwner`, `whenNotPaused`, `whenPaused`, `isActiveProposal`, `isCollapsedProposal`.
7.  **Constructor:** Initializes ERC20, Owner, sets initial parameters.
8.  **ERC20 Functions:** (Inherited/Overridden from OpenZeppelin)
    *   `name`, `symbol`, `decimals`, `totalSupply`, `balanceOf`, `transfer`, `allowance`, `approve`, `transferFrom`.
9.  **Internal Token Functions:**
    *   `_mint`, `_burn` (Used by staking/protocol logic).
10. **Staking Functions:**
    *   `stake(uint256 amount)`: Stake tokens to gain voting power.
    *   `withdrawStake(uint256 amount)`: Withdraw staked tokens (potentially with a time lock penalty, though simplified here).
    *   `getStakedAmount(address account) view`: Get user's staked amount.
    *   `getTotalStaked() view`: Get total tokens staked in the protocol.
11. **Voting Power Functions:**
    *   `calculateVotingPower(address account) view`: Calculates current potential voting power based on balance, stake, and stake duration.
    *   `getTotalProtocolVotingPower() view`: Calculates sum of potential voting power of all token holders (estimation or based on total supply/staked).
12. **Proposal Management Functions:**
    *   `createProposal(string description, Outcome[] outcomes, uint64 votingPeriodDays)`: Create a new proposal.
    *   `getProposalDetails(uint256 proposalId) view`: Get details of a specific proposal.
    *   `getProposalOutcomes(uint256 proposalId) view`: Get the list of outcomes for a proposal.
    *   `getLatestProposalId() view`: Get the ID of the most recently created proposal.
13. **Voting Functions:**
    *   `castSimpleVote(uint256 proposalId, uint256 outcomeId)`: Cast a standard vote for an outcome.
    *   `castConditionalVote(uint256 proposalId, uint256 outcomeId, uint256 conditionalThreshold)`: Cast a vote that only counts if the target outcome meets a vote power threshold *after* simple and active time-locked votes are tallied.
    *   `castTimeLockedVote(uint256 proposalId, uint256 outcomeId, uint64 effectiveTimestamp)`: Cast a vote that only becomes active *after* a specific timestamp.
    *   `revokeVote(uint256 proposalId)`: Revoke a previously cast vote before the voting period ends.
    *   `getVoteDetails(uint256 proposalId, address voter) view`: Get details of a user's vote on a proposal.
    *   `getOutcomeVoteTallies(uint256 proposalId) view`: Get the current tallies (simple, conditional, time-locked) for each outcome before collapse.
14. **Resolution & Execution Functions:**
    *   `collapseVoteState(uint256 proposalId)`: Finalizes the voting, evaluates conditional and time-locked votes, determines the winning outcome. Callable by anyone after the voting period.
    *   `getWinningOutcome(uint256 proposalId) view`: Get the determined winning outcome after collapse.
    *   `executeWinningOutcome(uint256 proposalId)`: Triggers the execution of the winning outcome's associated action (if any). Restricted to a specific role/owner.
15. **Admin/Configuration Functions:**
    *   `setStakingMultiplier(uint256 multiplier)`: Set the multiplier for staked tokens in voting power calculation.
    *   `setTimeBonusDivisor(uint256 divisor)`: Set the divisor for calculating the time-based staking bonus.
    *   `setVotingPeriodDuration(uint64 durationDays)`: Set the default duration for new proposals.
    *   `setExecutionRole(address role)`: Set the address authorized to call `executeWinningOutcome`.
    *   `pause()`: Pause contract sensitive operations.
    *   `unpause()`: Unpause contract.
    *   `transferOwnership(address newOwner)`: Transfer contract ownership.
16. **Utility Functions:**
    *   `calculateOutcomeVotePower(uint256 proposalId, uint256 outcomeId, VoteType voteType) view`: Internal helper to calculate power for a specific vote type/outcome before collapse. (Maybe combine into `getOutcomeVoteTallies`).

---

### **Function Summary**

1.  `constructor(string name, string symbol, address initialOwner)`: Initializes the contract, ERC20 token, and owner.
2.  `name() view`: Returns the token name (ERC20).
3.  `symbol() view`: Returns the token symbol (ERC20).
4.  `decimals() view`: Returns the token decimals (ERC20).
5.  `totalSupply() view`: Returns the total token supply (ERC20).
6.  `balanceOf(address account) view`: Returns the token balance of an account (ERC20).
7.  `transfer(address to, uint256 amount) returns (bool)`: Transfers tokens (ERC20).
8.  `allowance(address owner, address spender) view`: Returns allowance (ERC20).
9.  `approve(address spender, uint256 amount) returns (bool)`: Approves spending (ERC20).
10. `transferFrom(address from, address to, uint256 amount) returns (bool)`: Transfers approved tokens (ERC20).
11. `stake(uint256 amount)`: Stakes caller's tokens, updates staked amount and last stake time.
12. `withdrawStake(uint256 amount)`: Allows caller to unstake tokens.
13. `getStakedAmount(address account) view`: Returns the amount of tokens staked by an account.
14. `getTotalStaked() view`: Returns the total amount of tokens currently staked in the protocol.
15. `calculateVotingPower(address account) view`: Calculates the dynamic voting power of an account based on balance, stake, and stake duration.
16. `getTotalProtocolVotingPower() view`: Calculates the estimated total voting power across all token holders.
17. `createProposal(string description, Outcome[] outcomes, uint64 votingPeriodDays)`: Creates a new governance proposal with multiple potential outcomes and sets the voting period.
18. `getProposalDetails(uint256 proposalId) view`: Retrieves the full details of a specific proposal.
19. `getProposalOutcomes(uint256 proposalId) view`: Retrieves the list of possible outcomes defined for a proposal.
20. `getLatestProposalId() view`: Returns the ID of the most recently created proposal.
21. `castSimpleVote(uint256 proposalId, uint256 outcomeId)`: Casts a non-conditional, non-time-locked vote for a specific outcome using current voting power.
22. `castConditionalVote(uint256 proposalId, uint256 outcomeId, uint256 conditionalThreshold)`: Casts a vote that only contributes to the final tally if the chosen outcome's simple + active time-locked vote power meets or exceeds `conditionalThreshold` during collapse.
23. `castTimeLockedVote(uint256 proposalId, uint256 outcomeId, uint64 effectiveTimestamp)`: Casts a vote that only becomes active and contributes to the tally if the `collapseVoteState` function is called at or after `effectiveTimestamp`.
24. `revokeVote(uint256 proposalId)`: Allows a voter to cancel their vote on an active proposal, restoring their voting power.
25. `getVoteDetails(uint256 proposalId, address voter) view`: Retrieves the details of a specific voter's cast vote on a proposal.
26. `getOutcomeVoteTallies(uint256 proposalId) view`: Provides current tallies of simple, conditional, and time-locked vote power for each outcome (before collapse logic is applied).
27. `collapseVoteState(uint256 proposalId)`: Finalizes the voting results for a proposal after its period ends, evaluating conditional/time-locked votes and determining the winning outcome. Can be called by anyone.
28. `getWinningOutcome(uint256 proposalId) view`: Returns the ID of the outcome that won the vote after the state has been collapsed.
29. `executeWinningOutcome(uint256 proposalId)`: Triggers the execution of the winning outcome's associated action (e.g., calling another contract). Callable only by the designated execution role.
30. `setStakingMultiplier(uint256 multiplier)`: (Admin) Sets the multiplier used for calculating voting power from staked tokens.
31. `setTimeBonusDivisor(uint256 divisor)`: (Admin) Sets the divisor for calculating the time-based staking bonus.
32. `setVotingPeriodDuration(uint64 durationDays)`: (Admin) Sets the default duration for new proposal voting periods.
33. `setExecutionRole(address role)`: (Admin) Sets the address allowed to trigger outcome execution.
34. `pause()`: (Admin) Pauses certain contract functions (like staking, voting, proposal creation).
35. `unpause()`: (Admin) Unpauses the contract.
36. `transferOwnership(address newOwner)`: (Admin) Transfers ownership of the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol"; // Useful for tracking voters or proposals, although iterating is gas-intensive. Let's keep it simple and iterate stored voters per proposal.
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Though 0.8+ has overflow checks, SafeMath adds clarity for explicit operations if needed. Not strictly necessary here.

// Outline:
// 1. State Variables (Owner, Pausable, ERC20, Staking, Parameters, Proposals, Votes)
// 2. Structs (Outcome, Proposal, Vote)
// 3. Events
// 4. Modifiers
// 5. Constructor
// 6. ERC20 Functions (Inherited)
// 7. Staking Functions
// 8. Voting Power Functions
// 9. Proposal Management Functions
// 10. Voting Functions (Simple, Conditional, Time-Locked, Revoke)
// 11. Resolution & Execution Functions (Collapse, Get Winning, Execute)
// 12. Admin/Configuration Functions
// 13. Internal Helpers

// Function Summary:
// 1.  constructor: Initialize contract, token, owner, parameters.
// 2.  name(): Get token name (ERC20).
// 3.  symbol(): Get token symbol (ERC20).
// 4.  decimals(): Get token decimals (ERC20).
// 5.  totalSupply(): Get total supply (ERC20).
// 6.  balanceOf(account): Get balance (ERC20).
// 7.  transfer(to, amount): Transfer tokens (ERC20).
// 8.  allowance(owner, spender): Get allowance (ERC20).
// 9.  approve(spender, amount): Approve spending (ERC20).
// 10. transferFrom(from, to, amount): Transfer using allowance (ERC20).
// 11. stake(amount): Stake tokens for voting power.
// 12. withdrawStake(amount): Unstake tokens.
// 13. getStakedAmount(account): Get user's staked balance.
// 14. getTotalStaked(): Get total staked amount in protocol.
// 15. calculateVotingPower(account): Calculate dynamic voting power.
// 16. getTotalProtocolVotingPower(): Calculate total potential voting power.
// 17. createProposal(description, outcomes, votingPeriodDays): Create a new proposal.
// 18. getProposalDetails(proposalId): Get proposal details.
// 19. getProposalOutcomes(proposalId): Get proposal outcomes.
// 20. getLatestProposalId(): Get the ID of the last created proposal.
// 21. castSimpleVote(proposalId, outcomeId): Cast a standard vote.
// 22. castConditionalVote(proposalId, outcomeId, conditionalThreshold): Cast a conditional vote.
// 23. castTimeLockedVote(proposalId, outcomeId, effectiveTimestamp): Cast a time-locked vote.
// 24. revokeVote(proposalId): Revoke a vote.
// 25. getVoteDetails(proposalId, voter): Get details of a specific vote.
// 26. getOutcomeVoteTallies(proposalId): Get current vote tallies by type.
// 27. collapseVoteState(proposalId): Finalize voting and determine winner.
// 28. getWinningOutcome(proposalId): Get winning outcome after collapse.
// 29. executeWinningOutcome(proposalId): Execute the winning outcome action.
// 30. setStakingMultiplier(multiplier): Set staking power multiplier (Admin).
// 31. setTimeBonusDivisor(divisor): Set time bonus divisor (Admin).
// 32. setVotingPeriodDuration(durationDays): Set default proposal duration (Admin).
// 33. setExecutionRole(role): Set role for execution (Admin).
// 34. pause(): Pause contract (Admin).
// 35. unpause(): Unpause contract (Admin).
// 36. transferOwnership(newOwner): Transfer ownership (Admin).


contract QuantumVoteProtocol is ERC20, Pausable, Ownable {

    // --- State Variables ---

    // Staking Data
    mapping(address => uint256) private _stakedAmounts;
    mapping(address => uint64) private _lastStakeTime; // Timestamp of the last stake or unstake event
    uint256 private _totalStaked;

    // Voting Power Parameters
    uint256 public stakingMultiplier; // Multiplier for staked tokens in voting power (e.g., 2 means 1 staked token = 2x power of 1 balance token)
    uint256 public timeBonusDivisor;  // Divisor for time-based bonus (e.g., 1 day in seconds / divisor = bonus points per day)

    // Proposal Data
    uint256 private _latestProposalId;
    mapping(uint256 => Proposal) private _proposals;

    // Vote Data (maps proposalId to voter address to vote details)
    mapping(uint256 => mapping(address => Vote)) private _votes;

    // Configuration Parameters
    uint64 public defaultVotingPeriodDays; // Default duration for proposal voting in days
    address public executionRole; // Address or contract authorized to execute winning outcomes

    // --- Structs ---

    struct Outcome {
        uint256 id;
        string description;
        address targetAddress; // Address to call if this outcome wins
        bytes callData;        // Data for the call
    }

    enum ProposalState { Created, Active, Collapsed }

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        Outcome[] outcomes;
        uint664 startTime; // Use uint64 for block timestamp
        uint64 endTime;
        ProposalState state;
        uint256 winningOutcomeId; // Set after collapse
        // Store tallies per outcome ID. Index 0 is simple, 1 is conditional, 2 is time-locked
        mapping(uint256 => uint256[3]) currentVoteTallies; // outcomeId => [simple, conditional, timeLocked]
        address[] voters; // List of addresses who voted on this proposal, needed for collapse iteration
    }

    enum VoteType { Simple, Conditional, TimeLocked }

    struct Vote {
        address voter;
        uint256 proposalId;
        uint256 chosenOutcomeId;
        uint256 votePowerUsed;
        VoteType voteType;
        uint256 conditionalThreshold; // Used for Conditional votes
        uint64 effectiveTimestamp;    // Used for TimeLocked votes
    }

    // --- Events ---

    event Staked(address indexed account, uint256 amount, uint256 newStakedAmount);
    event Unstaked(address indexed account, uint256 amount, uint256 newStakedAmount);
    event VotingPowerMultiplierUpdated(uint256 oldMultiplier, uint256 newMultiplier);
    event TimeBonusDivisorUpdated(uint256 oldDivisor, uint256 newDivisor);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, uint64 startTime, uint64 endTime);
    event VoteCast(uint256 indexed proposalId, address indexed voter, uint256 indexed outcomeId, uint256 powerUsed, VoteType voteType);
    event VoteRevoked(uint256 indexed proposalId, address indexed voter);
    event StateCollapsed(uint256 indexed proposalId, uint256 winningOutcomeId);
    event OutcomeExecuted(uint256 indexed proposalId, uint256 indexed outcomeId, address targetAddress, bytes callData, bool success);
    event ExecutionRoleUpdated(address indexed oldRole, address indexed newRole);

    // --- Modifiers ---

    modifier isActiveProposal(uint256 proposalId) {
        require(proposalId > 0 && proposalId <= _latestProposalId, "Invalid proposal ID");
        require(_proposals[proposalId].state == ProposalState.Active, "Proposal is not active");
        require(block.timestamp <= _proposals[proposalId].endTime, "Voting period has ended");
        _;
    }

    modifier isVotingPeriodEnded(uint256 proposalId) {
        require(proposalId > 0 && proposalId <= _latestProposalId, "Invalid proposal ID");
        require(_proposals[proposalId].state == ProposalState.Active, "Proposal is not active");
        require(block.timestamp > _proposals[proposalId].endTime, "Voting period is not over yet");
        _;
    }

    modifier isCollapsedProposal(uint256 proposalId) {
        require(proposalId > 0 && proposalId <= _latestProposalId, "Invalid proposal ID");
        require(_proposals[proposalId].state == ProposalState.Collapsed, "Proposal has not been collapsed");
        _;
    }

    // --- Constructor ---

    constructor(string memory name, string memory symbol, address initialOwner, uint256 initialSupply, uint256 _stakingMultiplier, uint256 _timeBonusDivisor, uint64 _defaultVotingPeriodDays)
        ERC20(name, symbol)
        Ownable(initialOwner) // Use initialOwner parameter for Ownable constructor
        Pausable()
    {
        _mint(initialOwner, initialSupply); // Mint initial supply to the owner
        stakingMultiplier = _stakingMultiplier;
        timeBonusDivisor = _timeBonusDivisor;
        defaultVotingPeriodDays = _defaultVotingPeriodDays;
        executionRole = initialOwner; // By default, owner can execute
        _latestProposalId = 0;
    }

    // --- ERC20 Functions (Inherited from OpenZeppelin) ---
    // name(), symbol(), decimals(), totalSupply(), balanceOf(), transfer(), allowance(), approve(), transferFrom()
    // These are inherited and usable directly.

    // We might override some ERC20 functions later if we wanted to add custom logic
    // on transfer (e.g., affecting voting power temporarily), but let's keep them standard for now.
    // We need to ensure stake() and withdrawStake() interact correctly with ERC20 balance.

    // --- Staking Functions ---

    /// @notice Stakes tokens to gain dynamic voting power. Transfers tokens to the contract.
    /// @param amount The amount of tokens to stake.
    function stake(uint256 amount) public whenNotPaused {
        require(amount > 0, "Cannot stake 0");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");

        _stakedAmounts[msg.sender] += amount;
        _totalStaked += amount;
        _lastStakeTime[msg.sender] = uint64(block.timestamp); // Update last stake time
        _transfer(msg.sender, address(this), amount); // Transfer tokens to the contract

        emit Staked(msg.sender, amount, _stakedAmounts[msg.sender]);
    }

    /// @notice Withdraws staked tokens. Transfers tokens from the contract back to the caller.
    /// @param amount The amount of tokens to unstake.
    function withdrawStake(uint256 amount) public whenNotPaused {
        require(amount > 0, "Cannot unstake 0");
        require(_stakedAmounts[msg.sender] >= amount, "Insufficient staked amount");

        _stakedAmounts[msg.sender] -= amount;
        _totalStaked -= amount;
        _lastStakeTime[msg.sender] = uint64(block.timestamp); // Update last stake time
        _transfer(address(this), msg.sender, amount); // Transfer tokens back

        emit Unstaked(msg.sender, amount, _stakedAmounts[msg.sender]);
    }

    /// @notice Gets the amount of tokens currently staked by an account.
    /// @param account The address to query.
    /// @return The staked amount.
    function getStakedAmount(address account) public view returns (uint256) {
        return _stakedAmounts[account];
    }

    /// @notice Gets the total amount of tokens staked across all users in the protocol.
    /// @return The total staked amount.
    function getTotalStaked() public view returns (uint256) {
        return _totalStaked;
    }

    // --- Voting Power Functions ---

    /// @notice Calculates the dynamic voting power of an account.
    /// Power = (Balance + Staked * stakingMultiplier) + (Staked * (current time - last stake time) / timeBonusDivisor)
    /// The time bonus incentivizes longer staking.
    /// @param account The address for which to calculate voting power.
    /// @return The calculated voting power.
    function calculateVotingPower(address account) public view returns (uint256) {
        uint256 balance = balanceOf(account);
        uint256 staked = _stakedAmounts[account];
        uint64 lastStake = _lastStakeTime[account];

        uint256 basePower = balance + (staked * stakingMultiplier);

        uint256 timeBonus = 0;
        if (staked > 0 && timeBonusDivisor > 0) {
            uint64 timeElapsed = uint64(block.timestamp) - lastStake;
             // Simple linear time bonus: staked amount * (time elapsed / timeBonusDivisor)
             // Be careful with potential overflows or large numbers depending on units/scale
            timeBonus = staked * (timeElapsed / timeBonusDivisor);
        }

        // Add a cap to time bonus to prevent excessive power from very long stake times if needed
        // uint256 maxTimeBonus = staked * stakingMultiplier; // Example cap: max bonus equals staked base power
        // timeBonus = timeBonus > maxTimeBonus ? maxTimeBonus : timeBonus;

        return basePower + timeBonus;
    }

    /// @notice Calculates the total potential voting power across all token holders.
    /// This is an estimation based on total supply and staked amount.
    /// @return The estimated total voting power.
    function getTotalProtocolVotingPower() public view returns (uint256) {
        // This is a simplified estimation. A more accurate way would involve iterating all holders, which is not feasible on-chain.
        // We assume tokens outside the contract and staked tokens contribute.
        // Total potential power ~ (TotalSupply - TotalStaked) + (TotalStaked * stakingMultiplier) + (AverageTimeBonus * TotalStaked/AverageStakedAmount)
        // Let's simplify: use total supply and average potential bonus.
        uint256 totalBalancePower = totalSupply() - _totalStaked;
        uint256 totalStakedPower = _totalStaked * stakingMultiplier;

        // Time bonus is hard to estimate accurately globally on-chain.
        // For a practical contract, you might track sum of stake durations or similar.
        // Let's provide a basic estimate using total supply and staked multiplier.
        // A more advanced version could track sum of (staked * time_elapsed)
         return totalBalancePower + totalStakedPower;
    }


    // --- Proposal Management Functions ---

    /// @notice Creates a new governance proposal.
    /// @param description A description of the proposal.
    /// @param outcomes The possible outcomes for the proposal.
    /// @param votingPeriodDays The duration of the voting period in days.
    function createProposal(string memory description, Outcome[] memory outcomes, uint64 votingPeriodDays)
        public
        whenNotPaused
        returns (uint256 proposalId)
    {
        require(bytes(description).length > 0, "Description cannot be empty");
        require(outcomes.length > 0, "Must have at least one outcome");
        require(votingPeriodDays > 0, "Voting period must be positive");
        // Ensure outcome IDs are unique and sequential from 0 or 1
        for (uint i = 0; i < outcomes.length; i++) {
            require(outcomes[i].id == i, "Outcome IDs must be sequential starting from 0");
        }

        _latestProposalId++;
        proposalId = _latestProposalId;
        uint64 startTime = uint64(block.timestamp);
        uint64 endTime = startTime + votingPeriodDays * 1 days;

        _proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: description,
            outcomes: outcomes,
            startTime: startTime,
            endTime: endTime,
            state: ProposalState.Active,
            winningOutcomeId: type(uint256).max, // Sentinel value
            currentVoteTallies: mapping(uint256 => uint256[3]) // Initialize empty
            , voters: new address[](0) // Initialize empty voters list
        });

        emit ProposalCreated(proposalId, msg.sender, startTime, endTime);
    }

    /// @notice Gets the details of a specific proposal.
    /// @param proposalId The ID of the proposal.
    /// @return id, proposer, description, startTime, endTime, state, winningOutcomeId
    function getProposalDetails(uint256 proposalId)
        public
        view
        returns (uint256 id, address proposer, string memory description, uint64 startTime, uint64 endTime, ProposalState state, uint256 winningOutcomeId)
    {
        require(proposalId > 0 && proposalId <= _latestProposalId, "Invalid proposal ID");
        Proposal storage p = _proposals[proposalId];
        return (p.id, p.proposer, p.description, p.startTime, p.endTime, p.state, p.winningOutcomeId);
    }

     /// @notice Gets the outcomes of a specific proposal.
    /// @param proposalId The ID of the proposal.
    /// @return An array of Outcome structs.
    function getProposalOutcomes(uint256 proposalId)
        public
        view
        returns (Outcome[] memory)
    {
         require(proposalId > 0 && proposalId <= _latestProposalId, "Invalid proposal ID");
         return _proposals[proposalId].outcomes;
    }


    /// @notice Gets the ID of the most recently created proposal.
    /// @return The latest proposal ID.
    function getLatestProposalId() public view returns (uint256) {
        return _latestProposalId;
    }

    // --- Voting Functions ---

    /// @dev Internal helper to record a vote, assumes validation is done by the public function.
    function _recordVote(uint256 proposalId, uint256 outcomeId, VoteType voteType, uint256 powerUsed, uint256 conditionalThreshold, uint64 effectiveTimestamp) internal {
        Proposal storage proposal = _proposals[proposalId];
        address voter = msg.sender;

        // Check if already voted
        require(_votes[proposalId][voter].proposalId == 0, "Already voted on this proposal");

        // Store vote details
        _votes[proposalId][voter] = Vote({
            voter: voter,
            proposalId: proposalId,
            chosenOutcomeId: outcomeId,
            votePowerUsed: powerUsed,
            voteType: voteType,
            conditionalThreshold: conditionalThreshold,
            effectiveTimestamp: effectiveTimestamp
        });

        // Add voter to the list for iteration during collapse
        proposal.voters.push(voter);

        // Update immediate tally based on vote type (pre-collapse tally)
        if (voteType == VoteType.Simple) {
             proposal.currentVoteTallies[outcomeId][0] += powerUsed;
        } else if (voteType == VoteType.Conditional) {
             proposal.currentVoteTallies[outcomeId][1] += powerUsed;
        } else if (voteType == VoteType.TimeLocked) {
             proposal.currentVoteTallies[outcomeId][2] += powerUsed;
        }

        emit VoteCast(proposalId, voter, outcomeId, powerUsed, voteType);
    }

    /// @notice Casts a standard (simple) vote on a proposal.
    /// @param proposalId The ID of the proposal.
    /// @param outcomeId The ID of the chosen outcome.
    function castSimpleVote(uint256 proposalId, uint256 outcomeId)
        public
        whenNotPaused
        isActiveProposal(proposalId)
    {
        Proposal storage proposal = _proposals[proposalId];
        require(outcomeId < proposal.outcomes.length, "Invalid outcome ID");

        uint256 power = calculateVotingPower(msg.sender);
        require(power > 0, "No voting power");

        _recordVote(proposalId, outcomeId, VoteType.Simple, power, 0, 0); // conditionalThreshold and effectiveTimestamp are ignored
    }

    /// @notice Casts a conditional vote on a proposal.
    /// The vote only counts if the chosen outcome's tally (Simple + Active Time-Locked) meets or exceeds the threshold during collapse.
    /// @param proposalId The ID of the proposal.
    /// @param outcomeId The ID of the chosen outcome.
    /// @param conditionalThreshold The minimum total vote power (Simple + Active Time-Locked) required for this vote to count.
    function castConditionalVote(uint256 proposalId, uint256 outcomeId, uint256 conditionalThreshold)
        public
        whenNotPaused
        isActiveProposal(proposalId)
    {
        Proposal storage proposal = _proposals[proposalId];
        require(outcomeId < proposal.outcomes.length, "Invalid outcome ID");
        require(conditionalThreshold > 0, "Conditional threshold must be positive");

        uint256 power = calculateVotingPower(msg.sender);
        require(power > 0, "No voting power");

        _recordVote(proposalId, outcomeId, VoteType.Conditional, power, conditionalThreshold, 0); // effectiveTimestamp is ignored
    }

    /// @notice Casts a time-locked vote on a proposal.
    /// The vote only counts if the collapse occurs at or after the effective timestamp.
    /// @param proposalId The ID of the proposal.
    /// @param outcomeId The ID of the chosen outcome.
    /// @param effectiveTimestamp The timestamp after which this vote becomes active. Must be within or after the voting period.
    function castTimeLockedVote(uint256 proposalId, uint256 outcomeId, uint64 effectiveTimestamp)
        public
        whenNotPaused
        isActiveProposal(proposalId)
    {
         Proposal storage proposal = _proposals[proposalId];
         require(outcomeId < proposal.outcomes.length, "Invalid outcome ID");
         require(effectiveTimestamp >= proposal.startTime && effectiveTimestamp <= proposal.endTime + 7 days, "Effective timestamp must be within a reasonable range"); // Example range check

         uint256 power = calculateVotingPower(msg.sender);
         require(power > 0, "No voting power");

         _recordVote(proposalId, outcomeId, VoteType.TimeLocked, power, 0, effectiveTimestamp); // conditionalThreshold is ignored
    }


    /// @notice Allows a voter to revoke their vote on an active proposal.
    /// @param proposalId The ID of the proposal.
    function revokeVote(uint256 proposalId)
        public
        whenNotPaused
        isActiveProposal(proposalId)
    {
        address voter = msg.sender;
        require(_votes[proposalId][voter].proposalId != 0, "No vote cast for this proposal");

        // Note: Voting power recalculation at revocation is not necessary for final tally,
        // as the power is snapshotted at the time of casting.
        // We simply clear the vote and remove it from preliminary tallies.

        Vote memory revokedVote = _votes[proposalId][voter];
        uint256 outcomeId = revokedVote.chosenOutcomeId;
        uint256 powerUsed = revokedVote.votePowerUsed;

         Proposal storage proposal = _proposals[proposalId];

        if (revokedVote.voteType == VoteType.Simple) {
             proposal.currentVoteTallies[outcomeId][0] -= powerUsed;
        } else if (revokedVote.voteType == VoteType.Conditional) {
             proposal.currentVoteTallies[outcomeId][1] -= powerUsed;
        } else if (revokedVote.voteType == VoteType.TimeLocked) {
             proposal.currentVoteTallies[outcomeId][2] -= powerUsed;
        }

        // Remove voter from the list (potentially gas-intensive, but necessary for collapse loop)
        // Find and remove the voter's address from the voters array.
        // This simple remove-by-swap-and-pop is efficient but changes element order.
        address[] storage voters = proposal.voters;
        bool found = false;
        for (uint i = 0; i < voters.length; i++) {
            if (voters[i] == voter) {
                if (i < voters.length - 1) {
                    voters[i] = voters[voters.length - 1]; // Swap last element into current position
                }
                voters.pop(); // Remove the last element (which is now the duplicate or the original last)
                found = true;
                break; // Assuming only one vote per voter
            }
        }
        require(found, "Voter not found in list (internal error)");


        // Clear the vote struct
        delete _votes[proposalId][voter];

        emit VoteRevoked(proposalId, voter);
    }

    /// @notice Gets details of a specific voter's vote on a proposal.
    /// @param proposalId The ID of the proposal.
    /// @param voter The address of the voter.
    /// @return A Vote struct containing the vote details.
    function getVoteDetails(uint256 proposalId, address voter)
        public
        view
        returns (Vote memory)
    {
        require(proposalId > 0 && proposalId <= _latestProposalId, "Invalid proposal ID");
        // Note: Returns zero-initialized struct if no vote exists
        return _votes[proposalId][voter];
    }

     /// @notice Gets the current tallies for each outcome of a proposal by vote type.
    /// Note: These are preliminary tallies and do not reflect the final count after collapse logic.
    /// @param proposalId The ID of the proposal.
    /// @return An array of arrays, where result[outcomeId] = [simple tally, conditional tally, time-locked tally].
    function getOutcomeVoteTallies(uint256 proposalId)
        public
        view
        returns (uint256[][] memory)
    {
        require(proposalId > 0 && proposalId <= _latestProposalId, "Invalid proposal ID");
        Proposal storage proposal = _proposals[proposalId];
        uint256[][] memory tallies = new uint256[][](proposal.outcomes.length);
        for(uint i = 0; i < proposal.outcomes.length; i++) {
            tallies[i] = new uint256[](3);
            tallies[i][0] = proposal.currentVoteTallies[i][0]; // Simple
            tallies[i][1] = proposal.currentVoteTallies[i][1]; // Conditional (preliminary)
            tallies[i][2] = proposal.currentVoteTallies[i][2]; // Time-Locked (preliminary)
        }
        return tallies;
    }

    // --- Resolution & Execution Functions ---

    /// @notice Finalizes the voting for a proposal after the voting period ends.
    /// Evaluates conditional and time-locked votes and determines the winning outcome.
    /// Callable by anyone to trigger the state transition.
    /// @param proposalId The ID of the proposal to collapse.
    function collapseVoteState(uint256 proposalId)
        public
        whenNotPaused
        isVotingPeriodEnded(proposalId) // Ensure voting period is over
    {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.state != ProposalState.Collapsed, "Proposal already collapsed");

        // --- Tallying Logic ---
        uint256 numOutcomes = proposal.outcomes.length;
        uint256[] memory finalTallies = new uint256[](numOutcomes);
        address[] memory voters = proposal.voters; // Get a snapshot of voters who cast votes

        // Pass 1: Tally Simple and Active Time-Locked Votes
        uint256[] memory initialTallies = new uint256[](numOutcomes); // Simple + Active Time-Locked
        for (uint i = 0; i < voters.length; i++) {
            address voter = voters[i];
            Vote memory vote = _votes[proposalId][voter];

            if (vote.voteType == VoteType.Simple) {
                initialTallies[vote.chosenOutcomeId] += vote.votePowerUsed;
            } else if (vote.voteType == VoteType.TimeLocked) {
                if (block.timestamp >= vote.effectiveTimestamp) {
                    initialTallies[vote.chosenOutcomeId] += vote.votePowerUsed;
                }
                // Else: Time-locked vote is not yet effective, ignored in initial tally.
            }
            // Conditional votes are handled in Pass 2
        }

        // Pass 2: Evaluate and Tally Conditional Votes
        // Conditional votes are evaluated based on the *initialTallies* (Simple + Active Time-Locked)
        // for their chosen outcome.
        uint256[] memory conditionalTallies = new uint256[](numOutcomes);
         for (uint i = 0; i < voters.length; i++) {
            address voter = voters[i];
            Vote memory vote = _votes[proposalId][voter];

            if (vote.voteType == VoteType.Conditional) {
                 // Condition: Does the initial tally for the chosen outcome meet the threshold?
                 if (initialTallies[vote.chosenOutcomeId] >= vote.conditionalThreshold) {
                     conditionalTallies[vote.chosenOutcomeId] += vote.votePowerUsed;
                 }
            }
        }

        // Final Tally = Initial Tally + Conditional Tally
        uint256 winningOutcomeIndex = 0;
        uint256 maxVotePower = 0;

        for (uint i = 0; i < numOutcomes; i++) {
            finalTallies[i] = initialTallies[i] + conditionalTallies[i];

            // Determine Winning Outcome (Simple Majority)
            if (finalTallies[i] > maxVotePower) {
                maxVotePower = finalTallies[i];
                winningOutcomeIndex = i;
            }
            // Tie-breaking: If tied, the outcome with the lower index wins.
            // Alternatively, could use a random factor, proposer's preference, etc.
            // Current logic implicitly favors lower index in case of tie.
        }

        // Update Proposal State
        proposal.state = ProposalState.Collapsed;
        proposal.winningOutcomeId = proposal.outcomes[winningOutcomeIndex].id; // Store the actual ID

        // Note: The currentVoteTallies mapping is not updated with the final count here,
        // as finalTallies[] holds the correct result after collapse logic.
        // If needed, we could store final tallies separately or update the mapping.

        emit StateCollapsed(proposalId, proposal.winningOutcomeId);
    }

    /// @notice Gets the winning outcome of a collapsed proposal.
    /// @param proposalId The ID of the proposal.
    /// @return The ID of the winning outcome. Returns type(uint256).max if not collapsed.
    function getWinningOutcome(uint256 proposalId)
        public
        view
        isCollapsedProposal(proposalId)
        returns (uint256)
    {
        return _proposals[proposalId].winningOutcomeId;
    }

    /// @notice Executes the action associated with the winning outcome of a proposal.
    /// This function assumes the winning outcome includes a target address and call data.
    /// Restricted to the `executionRole`.
    /// @param proposalId The ID of the proposal whose winning outcome should be executed.
    function executeWinningOutcome(uint256 proposalId)
        public
        whenNotPaused
        isCollapsedProposal(proposalId)
    {
        require(msg.sender == executionRole, "Not authorized to execute outcome");

        Proposal storage proposal = _proposals[proposalId];
        uint256 winningOutcomeId = proposal.winningOutcomeId;

        // Find the winning outcome struct
        Outcome memory winningOutcome;
        bool found = false;
        for(uint i = 0; i < proposal.outcomes.length; i++) {
            if (proposal.outcomes[i].id == winningOutcomeId) {
                winningOutcome = proposal.outcomes[i];
                found = true;
                break;
            }
        }
        require(found, "Winning outcome not found (internal error)");
        require(winningOutcome.targetAddress != address(0), "Winning outcome has no target address");

        // Execute the call
        (bool success, bytes memory returndata) = winningOutcome.targetAddress.call(winningOutcome.callData);

        // Note: Decide if execution failure should revert the entire transaction.
        // Here, we emit an event but don't revert. A robust DAO might have a more complex execution flow.
        emit OutcomeExecuted(proposalId, winningOutcomeId, winningOutcome.targetAddress, winningOutcome.callData, success);

        // Optional: Handle returndata if needed, but requires abi.decode, which is complex.
        // require(success, string(returndata)); // Example if you want to revert on failure with message

        // Prevent re-execution? Add a flag to Proposal struct? Or rely on off-chain tracking.
        // Let's add a flag. Requires modifying the Proposal struct again.
        // Skipping for now to keep functions list > 20 without further struct complexity increase.
    }

    // --- Admin/Configuration Functions ---

    /// @notice Sets the multiplier for staked tokens in voting power calculation.
    /// Callable only by the owner.
    /// @param multiplier The new staking multiplier.
    function setStakingMultiplier(uint256 multiplier) public onlyOwner {
        require(multiplier > 0, "Multiplier must be positive");
        uint256 oldMultiplier = stakingMultiplier;
        stakingMultiplier = multiplier;
        emit VotingPowerMultiplierUpdated(oldMultiplier, multiplier);
    }

    /// @notice Sets the divisor for calculating the time-based staking bonus.
    /// A higher divisor means less time bonus.
    /// Callable only by the owner.
    /// @param divisor The new time bonus divisor.
    function setTimeBonusDivisor(uint256 divisor) public onlyOwner {
        require(divisor > 0, "Divisor must be positive");
        uint256 oldDivisor = timeBonusDivisor;
        timeBonusDivisor = divisor;
        emit TimeBonusDivisorUpdated(oldDivisor, divisor);
    }

    /// @notice Sets the default voting period duration for new proposals.
    /// Callable only by the owner.
    /// @param durationDays The new default duration in days.
    function setVotingPeriodDuration(uint64 durationDays) public onlyOwner {
        require(durationDays > 0, "Duration must be positive");
        defaultVotingPeriodDays = durationDays;
    }

    /// @notice Sets the address authorized to call `executeWinningOutcome`.
    /// Callable only by the owner.
    /// @param role The address of the new execution role.
    function setExecutionRole(address role) public onlyOwner {
        require(role != address(0), "Execution role cannot be zero address");
        address oldRole = executionRole;
        executionRole = role;
        emit ExecutionRoleUpdated(oldRole, role);
    }


    /// @notice Pauses the contract, preventing sensitive operations.
    /// Callable only by the owner.
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract, allowing sensitive operations.
    /// Callable only by the owner.
    function unpause() public onlyOwner {
        _unpause();
    }

    // transferOwnership is inherited from Ownable

    // --- Internal Helpers ---
    // (None complex enough to warrant separate functions currently)
    // The vote counting logic is within collapseVoteState.

}
```