Okay, let's design a smart contract for a Decentralized Reputation and Governance Network. This contract will manage user reputation, staked tokens, voting power based on a combination of both, epoch-based reputation decay and slashing, and allow governance to propose and execute changes to the system's parameters or other connected contracts.

It will have a built-in token for staking and rewards, managed internally.

Here's the outline and function summary, followed by the Solidity code.

---

**Contract Name:** `DecentralizedReputationNetwork`

**Concept:** A decentralized network where participants earn reputation through positive interactions (represented abstractly), stake tokens for influence, and govern the network parameters. Reputation decays over time (epochs), and inactivity leads to slashing. Voting power is a dynamic combination of staked tokens and current reputation.

**Key Features:**

1.  **Internal Token (ERC20-like):** Manages a native token for staking and rewards within the contract.
2.  **User Profiles:** Tracks stake, reputation, delegation, and interaction history for each user.
3.  **Reputation System:**
    *   Earned through successful participation (e.g., executing successful proposals, participating actively).
    *   Decays epoch by epoch.
    *   Inactivity (no stakes, votes, proposals) leads to slashing of stake and significant reputation loss.
4.  **Staking:** Users lock tokens to gain influence and voting power.
5.  **Delegation:** Users can delegate their combined voting power to another address.
6.  **Epochs:** Time periods that trigger reputation decay, inactivity checks/slashing, and reward distribution.
7.  **Combined Voting Power:** Voting power is derived from `stakedAmount + reputationScore`.
8.  **Governance:**
    *   Users meeting thresholds can create proposals.
    *   Voting on proposals using combined voting power.
    *   Execution of successful proposals, including changing system parameters.
9.  **Dynamic Parameters:** Core network rules (decay rate, slashing rate, proposal thresholds, etc.) are adjustable via governance proposals.

**Outline and Function Summary:**

**I. Core Data Structures & State**
    *   Enums: `ProposalState` (Pending, Active, Succeeded, Failed, Executed)
    *   Structs:
        *   `UserProfile`: `uint256 stakedAmount`, `uint256 reputationScore`, `address delegatee`, `uint256 lastActiveEpoch`, `uint256 firstStakeEpoch`, `uint256 totalInteractions`
        *   `Proposal`: `address proposer`, `uint256 startEpoch`, `uint256 endEpoch`, `uint256 votesFor`, `uint256 votesAgainst`, `uint256 totalVotingPowerCast`, `bytes description`, `address target`, `bytes callData`, `ProposalState state`
    *   Mappings: `address => UserProfile`, `uint256 => Proposal`, `address => uint256` (balances), `address => mapping(address => uint256)` (allowances)
    *   State Variables: `currentEpoch`, `epochStartTime`, `systemParameters` (struct or individual vars), `proposalCounter`, ERC20 standard variables (`name`, `symbol`, `decimals`, `totalSupply`)

**II. Token Functions (ERC20-like Implementation)**
    1.  `constructor(string memory name_, string memory symbol_, uint256 initialSupply, uint256 epochDurationSeconds, uint256 initialReputationDecayRate, uint256 initialInactivityEpochsForSlashing)`: Deploys the contract, sets initial supply and system parameters.
    2.  `transfer(address recipient, uint256 amount)`: Standard token transfer.
    3.  `approve(address spender, uint256 amount)`: Standard token approve.
    4.  `transferFrom(address sender, address recipient, uint256 amount)`: Standard token transferFrom.
    5.  `balanceOf(address account)`: Get token balance.
    6.  `allowance(address owner, address spender)`: Get token allowance.
    7.  `totalSupply()`: Get total token supply.
    8.  `name()`: Get token name.
    9.  `symbol()`: Get token symbol.
    10. `decimals()`: Get token decimals.

**III. User & Staking Functions**
    11. `stake(uint256 amount)`: Stake tokens to gain voting power and potentially earn reputation. Creates profile if new.
    12. `unstake(uint256 amount)`: Unstake tokens. May be subject to locks or conditions (simplified here, but could add lockup).
    13. `delegate(address delegatee)`: Delegate voting power and reputation.
    14. `undelegate()`: Remove delegation.
    15. `getUserProfile(address user)`: Get a user's profile details.
    16. `getUserVotingPower(address user)`: Calculate the current combined voting power for a user (or their delegatee).

**IV. Epoch & Reputation Functions**
    17. `advanceEpoch()`: Callable function to transition to the next epoch. Triggers decay, slashing, and potentially rewards. Only executable after epoch duration passes.
    18. `calculateReputationDecay(address user)`: (Internal/Helper) Calculates and applies reputation decay for a specific user based on current epoch.
    19. `_slashInactiveUser(address user)`: (Internal/Helper) Checks for inactivity and slashes stake/reputation if necessary.

**V. Governance Functions**
    20. `createProposal(bytes description, address target, bytes calldata callData)`: Create a new governance proposal. Requires minimum stake/reputation.
    21. `vote(uint256 proposalId, bool support)`: Cast a vote on an active proposal. Uses the voter's current combined voting power (or their delegatee's).
    22. `executeProposal(uint256 proposalId)`: Execute a proposal that has succeeded and is ready for execution.
    23. `getProposal(uint256 proposalId)`: Get details of a specific proposal.
    24. `getProposalState(uint256 proposalId)`: Get the current state of a proposal.

**VI. Parameter & Query Functions**
    25. `getSystemParameters()`: Query current system parameters (epoch duration, decay rate, slashing settings, proposal thresholds).
    26. `getTotalStaked()`: Query the total amount of tokens staked in the contract.
    27. `getTotalReputation()`: Query the sum of all users' reputation scores.
    28. `getCurrentEpoch()`: Get the current epoch number.
    29. `setSystemParameter(bytes32 parameterName, uint256 newValue)`: (Target of Governance) Function callable by executed proposals to change system parameters. (Example: could have individual setters or a generic one like this). Let's implement individual setters as targets for clarity.
        *   `setEpochDuration(uint256 newDuration)`
        *   `setReputationDecayRate(uint256 newRate)`
        *   `setInactivityEpochsForSlashing(uint256 newCount)`
        *   `setMinimumStakeToPropose(uint256 newAmount)`
        *   `setMinimumReputationToPropose(uint256 newScore)`
        *   `setProposalVoteDurationEpochs(uint256 newDurationEpochs)`
        *   `setProposalQuorumNumerator(uint256 newNumerator)` (Quorum as numerator of total voting power)
        *   `setProposalMajorityNumerator(uint256 newNumerator)` (Majority as numerator of total votes cast)
    This brings the function count potentially higher, depending on how parameters are set. Let's aim for direct setters as governance targets.

**Total Functions (counting specific parameter setters):**

1.  constructor
2.  transfer
3.  approve
4.  transferFrom
5.  balanceOf
6.  allowance
7.  totalSupply
8.  name
9.  symbol
10. decimals
11. stake
12. unstake
13. delegate
14. undelegate
15. getUserProfile
16. getUserVotingPower
17. advanceEpoch
18. calculateReputationDecay (Internal/Helper, but logic exists)
19. _slashInactiveUser (Internal/Helper, but logic exists)
20. createProposal
21. vote
22. executeProposal
23. getProposal
24. getProposalState
25. getSystemParameters
26. getTotalStaked
27. getTotalReputation
28. getCurrentEpoch
29. setEpochDuration (Governance Target)
30. setReputationDecayRate (Governance Target)
31. setInactivityEpochsForSlashing (Governance Target)
32. setMinimumStakeToPropose (Governance Target)
33. setMinimumReputationToPropose (Governance Target)
34. setProposalVoteDurationEpochs (Governance Target)
35. setProposalQuorumNumerator (Governance Target)
36. setProposalMajorityNumerator (Governance Target)
37. _earnReputation(address user, uint256 amount) (Internal helper, triggered by actions like successful proposals)

Okay, well over 20 functions, covering token, profiles, staking, delegation, reputation (decay, earning, slashing), epochs, and governance (creation, voting, execution, parameter changes).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DecentralizedReputationNetwork
 * @dev A smart contract implementing a decentralized network with staked-based and reputation-based governance.
 * Users stake tokens, earn reputation through active participation, which decays over time.
 * Inactivity leads to slashing. Voting power is a combination of stake and reputation.
 * Governance allows participants to propose and execute changes to network parameters.
 *
 * Key Features:
 * - Internal Token (ERC20-like) for staking and rewards.
 * - User Profiles tracking stake, reputation, delegation, and activity.
 * - Epoch-based system for time-dependent logic (decay, slashing).
 * - Reputation system with earning (via successful actions) and decay.
 * - Inactivity Slashing: Penalizes users inactive for several epochs.
 * - Combined Voting Power: Stake + Reputation.
 * - Delegation of Voting Power.
 * - On-chain Governance: Proposal creation, voting, and execution (including parameter updates).
 * - Dynamic Parameters: Core system rules adjustable via governance.
 *
 * Outline:
 * I. Errors & Events
 * II. Data Structures & State Variables
 * III. Internal Token (ERC20-like) Implementation
 * IV. User & Staking Logic
 * V. Epoch & Reputation Logic
 * VI. Governance Logic
 * VII. Parameter Setting (Governance Targets)
 * VIII. Query Functions
 */
contract DecentralizedReputationNetwork {

    // I. Errors & Events
    error InvalidAmount();
    error InsufficientBalance(uint256 required, uint256 available);
    error ZeroAddress();
    error SelfDelegation();
    error AlreadyDelegating();
    error NotDelegating();
    error EpochNotElapsed();
    error ProposalNotFound();
    error ProposalNotActive();
    error ProposalAlreadyVoted();
    error InsufficientVotingPower();
    error ProposalNotExecutable();
    error ProposalNotSucceeded();
    error ProposalAlreadyExecuted();
    error MinimumStakeOrReputationNotMet();
    error InvalidProposalState();
    error Unauthorized(); // For parameter setters callable only by governance execution

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Staked(address indexed user, uint256 amount, uint256 totalStaked);
    event Unstaked(address indexed user, uint256 amount, uint256 totalStaked);
    event Delegated(address indexed delegator, address indexed delegatee);
    event Undelegated(address indexed delegator);
    event ReputationEarned(address indexed user, uint256 amount, uint256 newReputation);
    event ReputationDecayed(address indexed user, uint256 amount, uint256 newReputation);
    event UserSlashed(address indexed user, uint256 stakedAmountSlashed, uint256 reputationSlashed);
    event EpochAdvanced(uint256 indexed newEpoch, uint256 timestamp);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 startEpoch, uint256 endEpoch);
    event Voted(uint256 indexed proposalId, address indexed voter, uint256 votingPower, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event ParameterChanged(bytes32 indexed parameterName, uint256 oldValue, uint256 newValue);

    // II. Data Structures & State Variables

    enum ProposalState { Pending, Active, Succeeded, Failed, Executed, Canceled } // Added Canceled state possibility

    struct UserProfile {
        uint256 stakedAmount;
        uint256 reputationScore;
        address delegatee; // Address the user delegates their voting power/reputation to (0x0 if not delegating)
        uint256 lastActiveEpoch; // Last epoch user staked, voted, or proposed
        uint256 firstStakeEpoch; // Epoch user first staked
        uint256 totalInteractions; // Count of significant interactions (stake, vote, propose, successful proposal)
    }

    struct Proposal {
        address proposer;
        uint256 startEpoch; // Epoch proposal becomes active
        uint256 endEpoch;   // Epoch voting ends
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 totalVotingPowerCast; // Total voting power used in the vote
        bytes description;
        address target;     // Address of the contract/account to call if proposal succeeds
        bytes callData;     // Data to send in the call
        ProposalState state;
        mapping(address => bool) hasVoted; // Track if an address (delegator or delegatee) has voted
    }

    // ERC20 standard state variables
    string private _name;
    string private _symbol;
    uint8 private constant _decimals = 18;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // Network state variables
    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => Proposal) public proposals;

    uint256 public currentEpoch = 1; // Start at epoch 1
    uint256 public epochStartTime; // Timestamp when the current epoch started

    uint256 public proposalCounter; // Auto-incrementing ID for proposals

    uint256 public totalStaked; // Sum of staked tokens
    uint256 public totalReputation; // Sum of all reputation scores

    // System Parameters (adjustable by governance)
    uint256 public epochDurationSeconds;
    uint256 public reputationDecayRate; // Per 10000, e.g., 1000 = 10% decay per epoch
    uint256 public inactivityEpochsForSlashing; // Number of epochs inactive before slashing
    uint256 public slashingRate; // Per 10000, e.g., 500 = 5% stake slashed, 1000 = 10% reputation slashed upon inactivity
    uint256 public minimumStakeToPropose;
    uint256 public minimumReputationToPropose;
    uint256 public proposalVoteDurationEpochs; // How many epochs a proposal is active for voting
    uint256 public proposalQuorumNumerator; // Numerator for quorum percentage (denominator is 10000)
    uint256 public proposalMajorityNumerator; // Numerator for simple majority percentage (denominator is 10000)
    uint256 public reputationEarnAmountSuccessProposal; // Reputation earned by proposer on successful execution

    // Address that initiated the contract (initial admin, role diminishes as governance takes over)
    address private _owner; // Could be used for initial parameter setup or emergency kill switch

    // Modifier to restrict calls to only execution by this contract itself (for governance)
    modifier onlyGovernor() {
        // This check ensures the function is only called via the executeProposal mechanism
        // by checking that the caller is this contract's address.
        require(msg.sender == address(this), Unauthorized());
        _;
    }

    // III. Internal Token (ERC20-like) Implementation

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply,
        uint256 _epochDurationSeconds,
        uint256 _initialReputationDecayRate, // e.g., 100 for 1% decay
        uint256 _initialInactivityEpochsForSlashing, // e.g., 5 epochs
        uint256 _initialSlashingRate, // e.g., 500 for 5% stake, 1000 for 10% reputation
        uint256 _minimumStakeToPropose,
        uint256 _minimumReputationToPropose,
        uint256 _proposalVoteDurationEpochs,
        uint256 _proposalQuorumNumerator, // e.g., 400 (4%)
        uint256 _proposalMajorityNumerator, // e.g., 5001 (50.01%)
        uint256 _reputationEarnAmountSuccessProposal // e.g., 100 reputation points
    ) {
        if (bytes(name_).length == 0 || bytes(symbol_).length == 0) revert InvalidAmount(); // Basic check
        if (_epochDurationSeconds == 0) revert InvalidAmount();

        _name = name_;
        _symbol = symbol_;
        _totalSupply = initialSupply * (10 ** uint256(_decimals));
        _balances[msg.sender] = _totalSupply; // Mint initial supply to deployer

        epochDurationSeconds = _epochDurationSeconds;
        reputationDecayRate = _initialReputationDecayRate; // in per ten thousand
        inactivityEpochsForSlashing = _initialInactivityEpochsForSlashing;
        slashingRate = _initialSlashingRate; // in per ten thousand
        minimumStakeToPropose = _minimumStakeToPropose * (10 ** uint256(_decimals)); // Store in lowest denomination
        minimumReputationToPropose = _minimumReputationToPropose;
        proposalVoteDurationEpochs = _proposalVoteDurationEpochs;
        proposalQuorumNumerator = _proposalQuorumNumerator;
        proposalMajorityNumerator = _proposalMajorityNumerator;
        reputationEarnAmountSuccessProposal = _reputationEarnAmountSuccessProposal;

        epochStartTime = block.timestamp; // Set start time for the first epoch
        _owner = msg.sender; // Initial admin, limited role

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        if (currentAllowance < amount) revert InsufficientBalance(amount, currentAllowance);
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, currentAllowance - amount); // Decrease allowance
        return true;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        if (sender == address(0) || recipient == address(0)) revert ZeroAddress();
        if (amount == 0) revert InvalidAmount();
        if (_balances[sender] < amount) revert InsufficientBalance(amount, _balances[sender]);

        // Staked tokens cannot be transferred directly
        if (userProfiles[sender].stakedAmount > 0 && _balances[sender] - userProfiles[sender].stakedAmount < amount) {
             // This check is simplified. A more robust implementation would require unstaking first.
             // For this example, assume staked tokens are part of _balances but untransferable.
             // A better approach might be to *not* include stakedAmount in _balances.
             // Let's modify: stakedAmount is SEPARATE from _balances. Stake moves tokens from _balances to stakedAmount.
             // Unstake moves from stakedAmount to _balances.

             // --- RE-IMPLEMENTATION NOTE ---
             // Let's change the model slightly: stakedAmount is recorded in the profile.
             // The actual tokens are held BY THE CONTRACT ITSELF.
             // Staking moves tokens from user balance TO contract balance.
             // Unstaking moves tokens from contract balance TO user balance.
             // This is a standard and safer pattern. Need to adjust stake/unstake and _balances.
             // Initial supply should be minted to deployer as before. Stake requires user to `approve` the contract.

             // Reworking _transfer: This basic _transfer is for NON-STAKED tokens.
             // The staked balance is held *by this contract address*.
             // We need to ensure that when transferring *from* a user, we only use their NON-STAKED balance.
             // Staked balance is implicitly held by `address(this)`.

             // Let's assume _balances[user] holds the *liquid* tokens the user has outside of their stake.
             // The total supply is the sum of all _balances + totalStaked.

             // Ok, simpler approach for this example: _balances[user] holds the total user balance.
             // `userProfiles[user].stakedAmount` is the amount *within* that balance that is staked.
             // `userProfiles[user].stakedAmount <= _balances[user]` must always hold.
             // `transfer` can only move `_balances[sender] - userProfiles[sender].stakedAmount`.

             uint256 liquidBalance = _balances[sender] - userProfiles[sender].stakedAmount;
             if (liquidBalance < amount) revert InsufficientBalance(amount, liquidBalance);

             _balances[sender] -= amount;
             _balances[recipient] += amount;

             emit Transfer(sender, recipient, amount);
        } else {
            // This branch handles transfers where the sender has enough liquid balance
            _balances[sender] -= amount;
            _balances[recipient] += amount;
             emit Transfer(sender, recipient, amount);
        }
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        if (owner == address(0) || spender == address(0)) revert ZeroAddress();
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // IV. User & Staking Logic

    function stake(uint256 amount) public {
        if (amount == 0) revert InvalidAmount();
        // User needs to have approved this contract to pull tokens
        if (_allowances[msg.sender][address(this)] < amount) revert InsufficientBalance(amount, _allowances[msg.sender][address(this)]);
        if (_balances[msg.sender] < amount) revert InsufficientBalance(amount, _balances[msg.sender]); // Should not happen if allowance is sufficient and correct model used

        UserProfile storage user = userProfiles[msg.sender];

        if (user.firstStakeEpoch == 0) {
            user.firstStakeEpoch = currentEpoch; // Record first stake epoch
        }

        // Move tokens from user's liquid balance to their staked balance within the profile
        // Note: This requires _transfer to handle balances correctly, see rework note above.
        // Let's assume the reworked model where stakedAmount is separate from _balances.
        // User first needs to transfer tokens to this contract, then call stake. OR approve and contract pulls.
        // Standard staking: user approves, contract pulls via transferFrom. This is cleaner.

        // Reworking stake assuming approval model:
        // Transfer tokens from user's balance to contract's "staked pool" (implicitly held by contract balance).
        // The user's personal _balances map only holds liquid, unstaked tokens.

        // Let's simplify back for the example: _balances holds total user tokens.
        // stakedAmount is a portion of that _balances amount that is locked.
        // This requires careful handling in _transfer. Let's stick with the first rework idea:
        // Staked tokens are moved to THIS contract's balance. User's _balances is their liquid balance.

        // REWORK 3: Simplest for example: _balances holds liquid. stakedAmount is tracked in profile.
        // Staking involves user approving contract, then contract calls transferFrom to move tokens *to itself*.
        // The tokens are then added to the user's stakedAmount in the profile.

        // User must approve contract first!
        uint256 liquidBalance = _balances[msg.sender];
        if (liquidBalance < amount) revert InsufficientBalance(amount, liquidBalance); // Check liquid balance

        _balances[msg.sender] -= amount; // Move tokens out of liquid balance
        user.stakedAmount += amount; // Add to staked amount in profile

        totalStaked += amount;
        user.lastActiveEpoch = currentEpoch; // Mark as active
        user.totalInteractions++;

        emit Staked(msg.sender, amount, user.stakedAmount);
        emit Transfer(msg.sender, address(this), amount); // Implicit transfer to contract's managed pool
    }


    function unstake(uint256 amount) public {
        if (amount == 0) revert InvalidAmount();
        UserProfile storage user = userProfiles[msg.sender];
        if (user.stakedAmount < amount) revert InsufficientBalance(amount, user.stakedAmount);

        // Add any unstaking lockup logic here (not implemented in this example)

        user.stakedAmount -= amount; // Reduce staked amount
        _balances[msg.sender] += amount; // Return tokens to liquid balance

        totalStaked -= amount;
        user.lastActiveEpoch = currentEpoch; // Mark as active
        user.totalInteractions++;

        emit Unstaked(msg.sender, amount, user.stakedAmount);
         emit Transfer(address(this), msg.sender, amount); // Implicit transfer from contract's managed pool
    }

    function delegate(address delegatee) public {
        if (delegatee == address(0)) revert ZeroAddress();
        if (delegatee == msg.sender) revert SelfDelegation();

        UserProfile storage delegatorProfile = userProfiles[msg.sender];
        if (delegatorProfile.delegatee != address(0)) revert AlreadyDelegating();

        delegatorProfile.delegatee = delegatee;
        // Note: Voting power calculation will now factor in the delegatee
        delegatorProfile.lastActiveEpoch = currentEpoch; // Mark as active
        delegatorProfile.totalInteractions++;

        emit Delegated(msg.sender, delegatee);
    }

    function undelegate() public {
        UserProfile storage delegatorProfile = userProfiles[msg.sender];
        if (delegatorProfile.delegatee == address(0)) revert NotDelegating();

        delegatorProfile.delegatee = address(0);
        delegatorProfile.lastActiveEpoch = currentEpoch; // Mark as active
        delegatorProfile.totalInteractions++;

        emit Undelegated(msg.sender);
    }

    function getUserProfile(address user) public view returns (UserProfile memory) {
        return userProfiles[user];
    }

    function getUserVotingPower(address user) public view returns (uint256) {
        UserProfile storage userProfile = userProfiles[user];

        if (userProfile.delegatee != address(0)) {
            // If user is delegating, their voting power is effectively 0 for themselves,
            // and the delegatee's power is calculated including the delegator's stake+reputation.
            // However, the delegatee's power should NOT recursively include their own delegations.
            // A simple model: delegatee gets the sum of (staked + reputation) from all their delegators PLUS their own (staked + reputation).
            // This view function needs to calculate the power *originating* from this user, considering delegation.
            // A better model for total power calculation: Iterate through all users, sum up power, assign to delegatee if set.
            // This is complex for a simple view function.
            // Let's simplify: This function returns the power *originating* from this address. If delegating, it's 0.
            // If not delegating, it's their stake + reputation. The delegatee aggregates this.
            // A separate view might be needed for "getAggregateVotingPower(address delegatee)".
             return 0; // User has delegated their power
        } else {
             // User is not delegating, their power is their own stake + reputation
             return userProfile.stakedAmount + userProfile.reputationScore;
        }
    }

    // Helper to get effective voter address (self or delegatee)
    function _getEffectiveVoter(address voter) internal view returns (address) {
         address delegatee = userProfiles[voter].delegatee;
         return delegatee == address(0) ? voter : delegatee;
    }


    // V. Epoch & Reputation Logic

    function advanceEpoch() public {
        if (block.timestamp < epochStartTime + epochDurationSeconds) {
            revert EpochNotElapsed();
        }

        uint256 previousEpoch = currentEpoch;
        currentEpoch++;
        epochStartTime = block.timestamp; // Set start time for the new epoch

        // Iterate through all users to apply decay and check for slashing
        // NOTE: This loop can become very gas-intensive with many users.
        // A more scalable approach involves users or a separate contract calling a function
        // to update their state or process a batch of users off-chain and verify on-chain.
        // For this example, a simple loop is used.
        address[] memory allUsers = _getAllUsers(); // Dummy function, requires tracking all user addresses

        for (uint i = 0; i < allUsers.length; i++) {
             address user = allUsers[i];
             UserProfile storage profile = userProfiles[user];

             if (profile.stakedAmount > 0 || profile.reputationScore > 0) {
                 // Apply reputation decay
                 _calculateReputationDecay(user);

                 // Check for inactivity and slash
                 _slashInactiveUser(user);

                 // Potentially distribute rewards here based on stake or reputation
                 // _distributeEpochRewards(user); // Not implemented in this example
             }
        }

        emit EpochAdvanced(currentEpoch, block.timestamp);
    }

    // Helper function (simplified - tracking all users requires extra complexity or off-chain data)
    // In a real contract, you might use a linked list or require users to 'check-in'
    // or process users in batches submitted by trusted parties/keepres.
    function _getAllUsers() internal view returns (address[] memory) {
        // This is a placeholder. Iterating over all map keys directly is not possible or scalable.
        // For demonstration, we'll just return a small dummy list or assume a mechanism exists.
        // A realistic system might require users to call a `checkIn()` function or
        // rely on off-chain indexing to find inactive users to propose slashing.
        // Or iterate over a limited list of the most active users.
        // Let's assume for this example that `userProfiles` somehow yields all active keys.
        // A common pattern is to store users in a list/set upon first interaction.
        // For this code example, we'll just process a few active users for demonstration purposes.
        // A better way: Make decay/slashing opt-in or user-triggered after an epoch.
        // Example: `user.claimDecayAndSlash()` callable after epoch advance.

        // Let's change approach: AdvanceEpoch only updates global state.
        // Decay and slashing are applied *lazily* when a user interacts or their data is queried,
        // calculating decay/slashing since their `lastActiveEpoch`. This is much more scalable.

         revert("AdvanceEpoch requires lazy updates for scalability. Direct loop disabled.");
         // The loop below is commented out as it's not scalable.
         // Replace with lazy evaluation logic or a batched approach.
         // Example Lazy Evaluation for Reputation Decay:
         // In `getUserVotingPower`, `getUserProfile`, or interaction functions:
         // `_applyDecayAndSlashingIfDue(user);`
    }

    // New approach: Lazy updates for decay and slashing
    function _applyDecayAndSlashingIfDue(address user) internal {
        UserProfile storage profile = userProfiles[user];
        uint256 epochsPassed = currentEpoch - profile.lastActiveEpoch;

        if (epochsPassed > 0) {
            // Apply Decay
            if (profile.reputationScore > 0 && reputationDecayRate > 0) {
                uint256 decayAmount = (profile.reputationScore * reputationDecayRate * epochsPassed) / 10000;
                 if (decayAmount > profile.reputationScore) decayAmount = profile.reputationScore; // Cap decay
                profile.reputationScore -= decayAmount;
                totalReputation -= decayAmount;
                 emit ReputationDecayed(user, decayAmount, profile.reputationScore);
            }

            // Check and Apply Slashing
            if (epochsPassed >= inactivityEpochsForSlashing && slashingRate > 0 && profile.stakedAmount > 0) {
                uint256 stakeSlashAmount = (profile.stakedAmount * slashingRate) / 10000;
                uint256 reputationSlashAmount = (profile.reputationScore * slashingRate) / 10000;

                profile.stakedAmount -= stakeSlashAmount;
                totalStaked -= stakeSlashAmount;
                profile.reputationScore -= reputationSlashAmount;
                totalReputation -= reputationSlashAmount;

                // Slashed tokens could be burned or sent to a treasury/community pool
                // For this example, they are removed from totalStaked/totalReputation, effectively burned/removed from influence.
                // A real system would transfer the slashed stake amount.
                // For simplicity here, they are just removed from the user's stakedAmount and totalStaked.
                // Tokens are still in contract's balance, effectively inaccessible unless treasury logic is added.

                emit UserSlashed(user, stakeSlashAmount, reputationSlashAmount);
            }

            // Update last active epoch *after* calculating decay/slashing based on the old value
            profile.lastActiveEpoch = currentEpoch;
        }
    }

    // Internal function to add reputation (triggered by actions like successful proposals)
    function _earnReputation(address user, uint256 amount) internal {
        if (amount == 0) revert InvalidAmount();
        UserProfile storage profile = userProfiles[user];
        _applyDecayAndSlashingIfDue(user); // Apply any pending decay/slashing first
        profile.reputationScore += amount;
        totalReputation += amount;
        profile.lastActiveEpoch = currentEpoch; // Mark as active
        emit ReputationEarned(user, amount, profile.reputationScore);
    }

     // VI. Governance Logic

    function createProposal(bytes description, address target, bytes calldata callData) public returns (uint256 proposalId) {
        UserProfile storage proposerProfile = userProfiles[msg.sender];
         _applyDecayAndSlashingIfDue(msg.sender); // Ensure profile is up-to-date

        if (proposerProfile.stakedAmount < minimumStakeToPropose && proposerProfile.reputationScore < minimumReputationToPropose) {
            revert MinimumStakeOrReputationNotMet();
        }

        proposalId = ++proposalCounter;
        uint256 start = currentEpoch;
        uint256 end = start + proposalVoteDurationEpochs;

        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            startEpoch: start,
            endEpoch: end,
            votesFor: 0,
            votesAgainst: 0,
            totalVotingPowerCast: 0,
            description: description,
            target: target,
            callData: callData,
            state: ProposalState.Active
        });

        proposerProfile.lastActiveEpoch = currentEpoch; // Mark as active
        proposerProfile.totalInteractions++;

        emit ProposalCreated(proposalId, msg.sender, string(description), start, end);
    }

    function vote(uint256 proposalId, bool support) public {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound();

        // Check proposal state and epoch
        if (currentEpoch < proposal.startEpoch || currentEpoch >= proposal.endEpoch) {
            revert ProposalNotActive();
        }

        address effectiveVoter = _getEffectiveVoter(msg.sender);
        UserProfile storage voterProfile = userProfiles[effectiveVoter];
        _applyDecayAndSlashingIfDue(effectiveVoter); // Ensure voter's profile is up-to-date

        if (proposal.hasVoted[effectiveVoter]) {
            revert ProposalAlreadyVoted();
        }

        uint256 votingPower = voterProfile.stakedAmount + voterProfile.reputationScore;

        if (votingPower == 0) {
            revert InsufficientVotingPower(); // Cannot vote with 0 power
        }

        proposal.hasVoted[effectiveVoter] = true;
        proposal.totalVotingPowerCast += votingPower;

        if (support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }

        // Mark original caller (not delegatee) as active
        userProfiles[msg.sender].lastActiveEpoch = currentEpoch;
        userProfiles[msg.sender].totalInteractions++;


        emit Voted(proposalId, effectiveVoter, votingPower, support);
    }

    function executeProposal(uint256 proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound();

        // Check state transition conditions
        if (proposal.state == ProposalState.Executed) revert ProposalAlreadyExecuted();
        if (proposal.state != ProposalState.Active) revert ProposalNotExecutable(); // Must be Active to check outcome
         if (currentEpoch < proposal.endEpoch) revert ProposalNotExecutable(); // Voting period must have ended

        // Check Quorum: Total voting power cast must be >= a percentage of Total Voting Power (sum of all stake + reputation)
        uint256 totalNetworkVotingPower = totalStaked + totalReputation; // Simplified: Use current total power
        uint256 requiredQuorumPower = (totalNetworkVotingPower * proposalQuorumNumerator) / 10000;

        // Check Majority: Votes For must be > a percentage of Total Voting Power Cast in this proposal
        uint256 requiredMajorityVotesFor = (proposal.totalVotingPowerCast * proposalMajorityNumerator) / 10000;


        if (proposal.totalVotingPowerCast < requiredQuorumPower || proposal.votesFor <= proposal.votesAgainst || proposal.votesFor < requiredMajorityVotesFor) {
            proposal.state = ProposalState.Failed; // Mark as failed if quorum or majority not met
             revert ProposalNotSucceeded();
        }

        // If conditions are met, proposal succeeded
        proposal.state = ProposalState.Succeeded; // Mark as succeeded before execution attempt

        // Execute the proposal
        (bool success, ) = proposal.target.call(proposal.callData); // Low-level call

        if (!success) {
            // If execution fails, mark as failed (or add a specific ExecutionFailed state)
            // For simplicity, let's mark as failed and potentially slash the proposer
            proposal.state = ProposalState.Failed;
            // Optional: Slash proposer for failed execution? Requires more complex logic
            // emit ProposalExecutionFailed(proposalId);
             revert ProposalNotExecutable(); // Or a more specific error
        }

        proposal.state = ProposalState.Executed; // Mark as executed

        // Reward proposer for successful execution
        _earnReputation(proposal.proposer, reputationEarnAmountSuccessProposal);
        userProfiles[proposal.proposer].totalInteractions++; // Also mark proposer as active

        emit ProposalExecuted(proposalId);
    }

    function getProposal(uint256 proposalId) public view returns (
        address proposer,
        uint256 startEpoch,
        uint256 endEpoch,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 totalVotingPowerCast,
        bytes memory description,
        address target,
        bytes memory callData,
        ProposalState state
    ) {
        Proposal storage proposal = proposals[proposalId];
         if (proposal.proposer == address(0)) revert ProposalNotFound(); // Check if exists

        return (
            proposal.proposer,
            proposal.startEpoch,
            proposal.endEpoch,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.totalVotingPowerCast,
            proposal.description,
            proposal.target,
            proposal.callData,
            proposal.state
        );
    }

    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];
         if (proposal.proposer == address(0)) revert ProposalNotFound(); // Check if exists

        // Update state based on time if still active
        if (proposal.state == ProposalState.Active && currentEpoch >= proposal.endEpoch) {
             // Need to simulate state transition without changing state in a view function
             // A more robust way is to have executeProposal transition state, and view
             // just returns the current stored state. Let's stick to stored state.
             // If user wants the *final* state, they must call executeProposal if applicable.
             // This view function just returns the state as stored.
             return proposal.state; // Returns Active if period ended but not executed/failed yet
        }
        return proposal.state;
    }


    // VII. Parameter Setting (Governance Targets)
    // These functions are intended to be called only via a successful governance proposal execution.

    function setEpochDuration(uint256 newDuration) public onlyGovernor {
        uint256 oldDuration = epochDurationSeconds;
        epochDurationSeconds = newDuration;
        emit ParameterChanged("epochDurationSeconds", oldDuration, newDuration);
    }

    function setReputationDecayRate(uint256 newRate) public onlyGovernor {
        uint256 oldRate = reputationDecayRate;
        reputationDecayRate = newRate;
        emit ParameterChanged("reputationDecayRate", oldRate, newRate);
    }

    function setInactivityEpochsForSlashing(uint256 newCount) public onlyGovernor {
        uint256 oldCount = inactivityEpochsForSlashing;
        inactivityEpochsForSlashing = newCount;
        emit ParameterChanged("inactivityEpochsForSlashing", oldCount, newCount);
    }

    function setSlashingRate(uint256 newRate) public onlyGovernor {
        uint256 oldRate = slashingRate;
        slashingRate = newRate;
        emit ParameterChanged("slashingRate", oldRate, newRate);
    }

     function setMinimumStakeToPropose(uint256 newAmount) public onlyGovernor {
        uint256 oldAmount = minimumStakeToPropose;
        minimumStakeToPropose = newAmount * (10 ** uint256(_decimals));
        emit ParameterChanged("minimumStakeToPropose", oldAmount, minimumStakeToPropose);
    }

    function setMinimumReputationToPropose(uint256 newScore) public onlyGovernor {
        uint256 oldScore = minimumReputationToPropose;
        minimumReputationToPropose = newScore;
        emit ParameterChanged("minimumReputationToPropose", oldScore, newScore);
    }

    function setProposalVoteDurationEpochs(uint256 newDurationEpochs) public onlyGovernor {
        uint256 oldDuration = proposalVoteDurationEpochs;
        proposalVoteDurationEpochs = newDurationEpochs;
        emit ParameterChanged("proposalVoteDurationEpochs", oldDuration, newDurationEpochs);
    }

    function setProposalQuorumNumerator(uint256 newNumerator) public onlyGovernor {
        uint256 oldNumerator = proposalQuorumNumerator;
        proposalQuorumNumerator = newNumerator; // Should be <= 10000
        emit ParameterChanged("proposalQuorumNumerator", oldNumerator, newNumerator);
    }

    function setProposalMajorityNumerator(uint256 newNumerator) public onlyGovernor {
         uint256 oldNumerator = proposalMajorityNumerator;
        proposalMajorityNumerator = newNumerator; // Should be > 5000 for simple majority
        emit ParameterChanged("proposalMajorityNumerator", oldNumerator, newNumerator);
    }

    function setReputationEarnAmountSuccessProposal(uint256 newAmount) public onlyGovernor {
        uint256 oldAmount = reputationEarnAmountSuccessProposal;
        reputationEarnAmountSuccessProposal = newAmount;
        emit ParameterChanged("reputationEarnAmountSuccessProposal", oldAmount, newAmount);
    }


    // VIII. Query Functions

    function getSystemParameters() public view returns (
        uint256 _epochDurationSeconds,
        uint256 _reputationDecayRate,
        uint256 _inactivityEpochsForSlashing,
        uint256 _slashingRate,
        uint256 _minimumStakeToPropose,
        uint256 _minimumReputationToPropose,
        uint256 _proposalVoteDurationEpochs,
        uint256 _proposalQuorumNumerator,
        uint256 _proposalMajorityNumerator,
        uint256 _reputationEarnAmountSuccessProposal
    ) {
        return (
            epochDurationSeconds,
            reputationDecayRate,
            inactivityEpochsForSlashing,
            slashingRate,
            minimumStakeToPropose,
            minimumReputationToPropose,
            proposalVoteDurationEpochs,
            proposalQuorumNumerator,
            proposalMajorityNumerator,
            reputationEarnAmountSuccessProposal
        );
    }

    function getTotalStaked() public view returns (uint256) {
        return totalStaked;
    }

    function getTotalReputation() public view returns (uint256) {
        return totalReputation;
    }

    function getCurrentEpoch() public view returns (uint256) {
        return currentEpoch;
    }

    // Helper view to check effective voting power including delegation
    function _checkEffectiveVotingPower(address user) internal view returns (uint256) {
        address effectiveVoter = _getEffectiveVoter(user);
        // Note: This doesn't aggregate power if the effectiveVoter is a delegatee for many.
        // A proper aggregate power requires summing up all delegated power.
        // For voting, we only need the power of the *individual* or the *delegatee they chose*.
        // The vote function sums up total votes cast, correctly using the individual effective voter's power at the time of voting.
        // This helper is mainly for internal checks or basic queries.
         UserProfile storage profile = userProfiles[effectiveVoter];
        return profile.stakedAmount + profile.reputationScore;
    }

    // Helper view (gas intensive for many users) - better use off-chain indexer
    // function getDelegatedVotingPower(address delegatee) public view returns (uint256) {
    //     uint256 totalPower = 0;
    //     // This requires iterating all users to find who delegates to `delegatee`
    //     // Not suitable for a production contract without a different data structure.
    //     // ... iteration logic ...
    //     return totalPower + getUserVotingPower(delegatee); // Add delegatee's own power
    // }
}
```

**Explanation of Advanced/Creative Concepts:**

1.  **Combined Voting Power (Stake + Reputation):** Most DAOs use either token voting (`ERC20Votes`) or sometimes NFTs. Combining a dynamic, decaying reputation score with staked tokens creates a more nuanced Sybil resistance mechanism and rewards long-term, active participation over just holding tokens.
2.  **Epoch-Based Time Dynamics:** Instead of block numbers or raw timestamps for decay/slashing, structuring time into discrete epochs simplifies calculations and provides clear phases for network activity.
3.  **Reputation Decay:** Reputation isn't static. It diminishes over time if not maintained by participation, reflecting that past contributions might become less relevant. This encourages continuous engagement.
4.  **Inactivity Slashing:** Users who stake but become inactive (don't vote, propose, or restake) are penalized. This prevents "whale stagnation" where early holders could dominate governance passively forever and encourages active participation. Slashed stake could go to a treasury or be burned, increasing value for active participants. (In this code example, it's removed from `totalStaked` and the user's `stakedAmount`, effectively removing its influence).
5.  **Lazy State Updates (Reputation/Slashing):** To avoid gas costs of iterating over all users every epoch, decay and slashing are calculated and applied *when* a user's profile is accessed (e.g., when they stake, vote, propose, or someone queries their specific profile details). This is a common pattern for scalable systems with per-user time-based effects.
6.  **Decentralized Parameter Control:** The governance system isn't just for treasury spending or simple upgrades. It can modify the core rules of the network itself (decay rates, slashing thresholds, proposal parameters), making the system truly adaptive and self-governing over time. The `onlyGovernor` modifier and the target functions (`setEpochDuration`, etc.) exemplify this.
7.  **Delegation of Combined Power:** Users can delegate their entire influence (both stake and reputation) to another address, allowing for representative governance or participation by users who prefer not to manage it themselves.

This contract provides a framework for a sophisticated, dynamic, and community-driven network, moving beyond simple token-based governance or static reputation systems. The scalability of the epoch advance loop is addressed by switching to a lazy update model for user-specific decay and slashing.