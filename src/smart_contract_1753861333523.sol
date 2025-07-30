Okay, this is an exciting challenge! Creating a smart contract that's unique, advanced, and trendy, while avoiding existing open-source patterns, requires combining several concepts in a novel way.

Let's design a "Decentralized Adaptive Predictive Intelligence Network" (DAPIN). This contract allows users to stake tokens on the outcomes of future events, but critically, it has a built-in *adaptive learning mechanism* that adjusts rewards, penalties, and even event proposal weights based on the collective accuracy of participants and registered "insight oracles." It aims to foster a more accurate, self-correcting predictive market.

---

## NexusOracle: Decentralized Adaptive Predictive Intelligence Network (DAPIN)

**Overview:**

NexusOracle is a sophisticated smart contract designed to operate as a self-improving decentralized prediction market. Unlike traditional prediction markets, NexusOracle incorporates adaptive mechanisms that adjust system parameters based on historical accuracy and the performance of "insight oracles" and participants. This creates a dynamic feedback loop intended to foster more accurate collective intelligence. Users stake tokens on event outcomes, earn rewards for correct predictions, and accrue "Foresight Points" (reputation). The contract "learns" by adjusting its internal reward multipliers, dispute thresholds, and oracle weighting based on overall prediction success rates.

**Core Concepts:**

1.  **Adaptive Parameters:** Reward multipliers, penalty rates, and dispute fees are not fixed but dynamically adjust based on the system's overall prediction accuracy and oracle reliability.
2.  **Foresight Points (Reputation):** A non-transferable, accumulative score for users, reflecting their historical prediction accuracy. Higher Foresight Points can unlock higher reward multipliers and proposal weights.
3.  **Insight Oracles:** Specialized participants who can register and provide early insights or definitive resolutions. Their own reputation and impact on the system are tied to their historical accuracy.
4.  **Community-Driven Events & Resolution:** Events can be proposed by any user, voted on by the community, and resolved either by trusted oracles or through community consensus/dispute resolution.
5.  **Synergistic Rewards:** Users who not only predict correctly but also align with the majority correct prediction receive enhanced rewards, incentivizing robust collective intelligence.

---

### Contract Outline & Function Summary

**I. Core Data Structures & Enums**
*   `EventStatus`: Defines the lifecycle of an event (Proposed, Active, Resolved, Disputed).
*   `Outcome`: Defines possible results of an event (Undetermined, OptionA, OptionB, etc.).
*   `Event`: Struct holding all event details (description, options, deadlines, state, winner, staked amounts).
*   `Prediction`: Struct detailing a user's stake on an event.
*   `Oracle`: Struct for registered insight providers (address, reputation, performance metrics).
*   `UserProfile`: Struct for users' overall reputation and statistics.

**II. State Variables**
*   `nexusToken`: Address of the ERC-20 token used for staking and rewards.
*   `owner`: Contract owner (for initial setup/emergency).
*   `nextEventId`, `nextOracleId`: Counters for unique IDs.
*   `events`: Mapping from event ID to `Event` struct.
*   `userPredictions`: Mapping from event ID to mapping from user address to `Prediction` struct.
*   `oracles`: Mapping from oracle ID to `Oracle` struct.
*   `oracleAddresses`: Mapping from oracle address to oracle ID.
*   `userProfiles`: Mapping from user address to `UserProfile` struct.
*   `eventProposals`: Mapping from event ID to mapping from proposer to number of votes.
*   `eventProposalVotes`: Mapping from event ID to mapping from voter to boolean.
*   `eventDisputeVotes`: Mapping from event ID to mapping from voter to boolean.

**III. System Parameters (Dynamically Adjusted)**
*   `baseRewardMultiplier`: Base percentage for correct prediction rewards.
*   `penaltyMultiplier`: Percentage of stake penalized for incorrect predictions.
*   `foresightPointMultiplier`: How many FP are awarded per successful prediction.
*   `oracleRegistrationFee`: Tokens required to become an oracle.
*   `minStakeAmount`: Minimum required stake for a prediction.
*   `eventProposalVoteThreshold`: Min votes needed for an event proposal to pass.
*   `overallSystemAccuracy`: Tracks the contract's historical prediction success rate.
*   `overallOracleAccuracy`: Tracks average accuracy of registered oracles.

**IV. Functions**

**A. Initialization & Core Management**
1.  `constructor(address _nexusTokenAddress)`: Initializes the contract with the ERC-20 token address and sets initial system parameters.
2.  `updateSystemParameters(uint256 _baseRewardMultiplier, uint256 _penaltyMultiplier, uint256 _fpMultiplier, uint256 _oracleRegFee, uint256 _minStake, uint256 _eventProposalThreshold)`: Allows the owner to adjust core system parameters.
3.  `pauseContract()`: Emergency function by owner to pause critical operations.
4.  `unpauseContract()`: Emergency function by owner to unpause critical operations.

**B. Event Lifecycle Management**
5.  `proposeEvent(string calldata _description, string[] calldata _options, uint256 _predictionDeadline, uint256 _resolutionDeadline)`: Allows any user to propose a new event for community consideration. Requires a small fee to prevent spam.
6.  `voteOnEventProposal(uint256 _eventId, bool _approve)`: Community members vote on proposed events. Weight of vote can be influenced by Foresight Points.
7.  `finalizeEventProposal(uint256 _eventId)`: Moves a proposed event to 'Active' if it meets the approval threshold.
8.  `submitPrediction(uint256 _eventId, uint8 _chosenOptionIndex, uint256 _amount)`: Users stake `_amount` of `NexusToken` on a specific outcome for an active event.
9.  `cancelPrediction(uint256 _eventId)`: Allows a user to cancel their prediction *before* the prediction deadline, incurring a small cancellation fee.
10. `resolveEventByOracle(uint256 _eventId, uint8 _winningOptionIndex, uint256 _oracleId)`: An *approved Insight Oracle* resolves an event, setting its winning outcome. This is a crucial function for data input.
11. `resolveEventByConsensus(uint256 _eventId, uint8 _winningOptionIndex)`: Allows the owner or a whitelisted multi-sig to resolve an event if no oracle does, or if an oracle is disputed.
12. `disputeResolution(uint256 _eventId)`: Users can dispute an event's resolution, initiating a community vote on the correct outcome. Requires a dispute fee.
13. `voteOnDispute(uint256 _eventId, bool _correct)`: Community members vote on the validity of a disputed resolution.
14. `finalizeDispute(uint256 _eventId)`: Admin or an automated process finalizes a dispute based on community vote, potentially reversing the resolution and penalizing the original resolver.

**C. Oracle Management**
15. `registerOracle(string calldata _name)`: Allows a user to register as an "Insight Oracle" by paying a fee and staking some tokens.
16. `deregisterOracle(uint256 _oracleId)`: Allows an oracle to deregister, potentially with a cooldown period or penalty on their staked tokens.
17. `updateOraclePerformance(uint256 _oracleId, bool _wasAccurate)`: Internal/called by `resolveEvent` to track an oracle's accuracy.

**D. Rewards & Reputation**
18. `claimRewards(uint256 _eventId)`: Allows users to claim their `NexusToken` rewards and Foresight Points for correctly predicting a resolved event.
19. `calculateSynergisticReward(uint256 _eventId, address _user)`: Internal function to calculate enhanced rewards for users who correctly predicted *and* were part of the majority correct prediction.
20. `recalibrateSystemParameters()`: **(Advanced & Trendy)** This is the "adaptive intelligence" function. It calculates new `baseRewardMultiplier`, `penaltyMultiplier`, and potentially `foresightPointMultiplier` based on `overallSystemAccuracy` and `overallOracleAccuracy`. This simulates the contract "learning" and adjusting its incentives.
21. `withdrawDisputeFees(address _to)`: Allows the owner or contract to withdraw accumulated dispute fees (e.g., for treasury or redistribution).

**E. View Functions (Read-Only)**
22. `getEventDetails(uint256 _eventId)`: Retrieves all details of a specific event.
23. `getUserPrediction(uint256 _eventId, address _user)`: Retrieves a user's prediction for a specific event.
24. `getUserProfile(address _user)`: Retrieves a user's Foresight Points and other profile data.
25. `getOracleInfo(uint256 _oracleId)`: Retrieves an oracle's details and performance.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Dummy ERC20 for demonstration. In a real scenario, this would be a separate, deployed token.
contract NexusToken is IERC20 {
    string public name = "Nexus Token";
    string public symbol = "NEX";
    uint8 public immutable decimals = 18;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor(uint256 initialSupply) {
        _totalSupply = initialSupply * (10 ** uint256(decimals));
        _balances[msg.sender] = _totalSupply;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        uint256 currentAllowance = _allowances[from][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(from, msg.sender, currentAllowance - amount);
        }
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");

        unchecked {
            _balances[from] -= amount;
            _balances[to] += amount;
        }
        emit Transfer(from, to, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}


contract NexusOracle is Ownable, Pausable, ReentrancyGuard {

    IERC20 public immutable nexusToken;

    // --- Enums ---
    enum EventStatus {
        Proposed,     // Event is proposed, waiting for community vote
        Active,       // Prediction period is open
        Resolved,     // Outcome determined, rewards can be claimed
        Disputed      // Resolution is being challenged
    }

    enum Outcome {
        Undetermined,
        Option1, // We'll use 1-based indexing for options for easier human readability
        Option2,
        Option3,
        // ... extend as needed
        MaxOptions // Sentinel value for bounds checking
    }

    // --- Structs ---

    struct Event {
        uint256 id;
        string description;
        string[] options;
        uint256 predictionDeadline; // Timestamp when predictions close
        uint256 resolutionDeadline; // Timestamp when event *should* be resolved
        EventStatus status;
        Outcome winningOption;
        address proposer;
        uint256 totalStaked;
        mapping(uint8 => uint256) stakedPerOption; // total staked for each option
        mapping(address => bool) hasClaimed; // User's claim status
        uint256 totalCorrectStaked; // Sum of staked amounts for the winning option
        uint256 totalIncorrectStaked; // Sum of staked amounts for losing options
        address resolverAddress; // The address that resolved the event
        uint256 proposalVotesFor; // Votes for event proposal
        uint256 proposalVotesAgainst; // Votes against event proposal
        uint256 disputeVotesFor; // Votes for the current resolution in dispute
        uint256 disputeVotesAgainst; // Votes against the current resolution in dispute
    }

    struct Prediction {
        uint256 eventId;
        address predictor;
        Outcome chosenOption;
        uint256 stakedAmount;
        uint256 timestamp;
        bool claimed;
        bool cancelled;
    }

    struct Oracle {
        uint256 id;
        address oracleAddress;
        string name;
        uint256 registrationTimestamp;
        uint256 stakedCollateral; // Collateral required for oracle registration
        uint256 totalResolutions;
        uint256 correctResolutions;
        uint256 foresightPoints; // Oracle's reputation score
        bool isActive;
        mapping(uint256 => Outcome) eventResolutions; // Event ID -> Oracle's submitted resolution
    }

    struct UserProfile {
        uint256 foresightPoints; // User's overall reputation score
        uint256 totalPredictions;
        uint256 correctPredictions;
        uint256 totalStaked;
        uint256 totalClaimedRewards;
    }

    // --- State Variables ---
    uint256 public nextEventId;
    uint256 public nextOracleId;

    mapping(uint256 => Event) public events;
    mapping(uint256 => mapping(address => Prediction)) public userPredictions; // eventId -> userAddress -> Prediction
    mapping(uint256 => mapping(address => bool)) public hasVotedOnEventProposal; // eventId -> voterAddress -> voted
    mapping(uint256 => mapping(address => bool)) public hasVotedOnDispute; // eventId -> voterAddress -> voted

    mapping(uint256 => Oracle) public oracles;
    mapping(address => uint256) public oracleAddresses; // oracleAddress -> oracleId

    mapping(address => UserProfile) public userProfiles;

    // --- System Parameters (Dynamically Adjusted) ---
    uint256 public baseRewardMultiplier;      // e.g., 105 for 1.05x reward (105%)
    uint256 public penaltyMultiplier;         // e.g., 5 for 5% penalty on incorrect prediction
    uint256 public foresightPointMultiplier;  // FP awarded per correct prediction amount, e.g., 1 FP per 100 NEX staked
    uint256 public oracleRegistrationFee;     // Fee to become an oracle
    uint256 public minStakeAmount;            // Minimum amount to stake on an event
    uint256 public eventProposalFee;          // Fee to propose an event
    uint256 public eventProposalVoteThreshold;// Minimum votes needed for an event proposal to pass (percentage, e.g., 5100 for 51%)
    uint256 public disputeFee;                // Fee to initiate a dispute
    uint256 public disputeVoteThreshold;      // Minimum votes needed for a dispute to pass (percentage)

    // Global accuracy metrics for adaptive recalibration
    uint256 public overallSystemAccuracy;  // In percentage, e.g., 7500 for 75%
    uint256 public overallOracleAccuracy;  // In percentage, e.g., 8000 for 80%

    // Accumulated fees from cancellations, penalties, disputes
    uint256 public accumulatedFees;

    // --- Events ---
    event EventProposed(uint256 indexed eventId, address indexed proposer, string description, uint256 predictionDeadline);
    event EventProposalVoted(uint256 indexed eventId, address indexed voter, bool approved);
    event EventProposalFinalized(uint256 indexed eventId, EventStatus newStatus);
    event PredictionSubmitted(uint256 indexed eventId, address indexed predictor, Outcome chosenOption, uint256 amount);
    event PredictionCancelled(uint256 indexed eventId, address indexed predictor, uint256 refundedAmount);
    event EventResolved(uint256 indexed eventId, Outcome winningOption, address indexed resolver);
    event DisputeInitiated(uint256 indexed eventId, address indexed disputer);
    event DisputeVoted(uint256 indexed eventId, address indexed voter, bool correct);
    event DisputeFinalized(uint256 indexed eventId, Outcome newWinningOption, bool resolutionChanged);
    event RewardsClaimed(uint256 indexed eventId, address indexed claimant, uint256 rewardAmount, uint256 foresightPointsEarned);
    event OracleRegistered(uint256 indexed oracleId, address indexed oracleAddress, string name);
    event OracleDeregistered(uint256 indexed oracleId, address indexed oracleAddress);
    event SystemParametersRecalibrated(uint256 newBaseRewardMultiplier, uint256 newPenaltyMultiplier, uint256 newForesightPointMultiplier);

    // --- Modifiers ---
    modifier onlyOracle(uint256 _oracleId) {
        require(oracles[_oracleId].isActive, "NexusOracle: Caller is not an active oracle.");
        require(oracles[_oracleId].oracleAddress == msg.sender, "NexusOracle: Oracle ID does not match caller.");
        _;
    }

    modifier eventExists(uint256 _eventId) {
        require(_eventId < nextEventId, "NexusOracle: Event does not exist.");
        _;
    }

    modifier notResolved(uint256 _eventId) {
        require(events[_eventId].status != EventStatus.Resolved && events[_eventId].status != EventStatus.Disputed, "NexusOracle: Event already resolved or in dispute.");
        _;
    }

    modifier predictionOpen(uint256 _eventId) {
        require(events[_eventId].status == EventStatus.Active, "NexusOracle: Event is not active for predictions.");
        require(block.timestamp < events[_eventId].predictionDeadline, "NexusOracle: Prediction deadline has passed.");
        _;
    }

    modifier resolutionOpen(uint256 _eventId) {
        require(events[_eventId].status == EventStatus.Active || events[_eventId].status == EventStatus.Disputed, "NexusOracle: Event not ready for resolution or dispute resolution.");
        require(block.timestamp >= events[_eventId].predictionDeadline, "NexusOracle: Prediction period not over yet.");
        require(block.timestamp < events[_eventId].resolutionDeadline, "NexusOracle: Resolution deadline has passed.");
        _;
    }

    // --- Constructor ---
    constructor(address _nexusTokenAddress) Ownable(msg.sender) {
        require(_nexusTokenAddress != address(0), "NexusOracle: NEX Token address cannot be zero.");
        nexusToken = IERC20(_nexusTokenAddress);

        // Initial system parameters
        baseRewardMultiplier = 10500; // 1.05x (105%)
        penaltyMultiplier = 500;      // 5%
        foresightPointMultiplier = 10; // 10 FP per NEX (example, adjust based on token decimals)
        oracleRegistrationFee = 10 ether; // 10 NEX (adjust units based on token decimals)
        minStakeAmount = 1 ether;     // 1 NEX
        eventProposalFee = 0.1 ether; // 0.1 NEX
        eventProposalVoteThreshold = 6000; // 60% approval needed
        disputeFee = 1 ether;
        disputeVoteThreshold = 6000; // 60% approval needed

        overallSystemAccuracy = 5000; // Start at 50%
        overallOracleAccuracy = 5000; // Start at 50%

        nextEventId = 0;
        nextOracleId = 0;
        accumulatedFees = 0;
    }

    // --- A. Initialization & Core Management ---

    // 2. Allows the owner to adjust core system parameters.
    function updateSystemParameters(
        uint256 _baseRewardMultiplier,
        uint256 _penaltyMultiplier,
        uint256 _fpMultiplier,
        uint256 _oracleRegFee,
        uint256 _minStake,
        uint256 _eventProposalThreshold,
        uint256 _disputeFee,
        uint256 _disputeVoteThreshold
    ) external onlyOwner {
        baseRewardMultiplier = _baseRewardMultiplier;
        penaltyMultiplier = _penaltyMultiplier;
        foresightPointMultiplier = _fpMultiplier;
        oracleRegistrationFee = _oracleRegFee;
        minStakeAmount = _minStake;
        eventProposalVoteThreshold = _eventProposalThreshold;
        disputeFee = _disputeFee;
        disputeVoteThreshold = _disputeVoteThreshold;
        emit SystemParametersRecalibrated(baseRewardMultiplier, penaltyMultiplier, foresightPointMultiplier); // Re-emit for clarity
    }

    // 3. Emergency function by owner to pause critical operations.
    function pauseContract() external onlyOwner {
        _pause();
    }

    // 4. Emergency function by owner to unpause critical operations.
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    // --- B. Event Lifecycle Management ---

    // 5. Allows any user to propose a new event.
    function proposeEvent(
        string calldata _description,
        string[] calldata _options,
        uint256 _predictionDeadline,
        uint256 _resolutionDeadline
    ) external payable whenNotPaused nonReentrant returns (uint256) {
        require(msg.value >= eventProposalFee, "NexusOracle: Insufficient event proposal fee.");
        require(_options.length >= 2 && _options.length <= 10, "NexusOracle: Event must have 2 to 10 options.");
        require(_predictionDeadline > block.timestamp, "NexusOracle: Prediction deadline must be in the future.");
        require(_resolutionDeadline > _predictionDeadline, "NexusOracle: Resolution deadline must be after prediction deadline.");

        uint256 currentEventId = nextEventId++;
        Event storage newEvent = events[currentEventId];
        newEvent.id = currentEventId;
        newEvent.description = _description;
        newEvent.options = _options;
        newEvent.predictionDeadline = _predictionDeadline;
        newEvent.resolutionDeadline = _resolutionDeadline;
        newEvent.status = EventStatus.Proposed;
        newEvent.winningOption = Outcome.Undetermined;
        newEvent.proposer = msg.sender;
        newEvent.totalStaked = 0;

        accumulatedFees += eventProposalFee; // Collect the fee

        emit EventProposed(currentEventId, msg.sender, _description, _predictionDeadline);
        return currentEventId;
    }

    // 6. Community members vote on proposed events.
    function voteOnEventProposal(uint256 _eventId, bool _approve)
        external
        whenNotPaused
        eventExists(_eventId)
        nonReentrant
    {
        Event storage event_ = events[_eventId];
        require(event_.status == EventStatus.Proposed, "NexusOracle: Event is not in proposed status.");
        require(!hasVotedOnEventProposal[_eventId][msg.sender], "NexusOracle: Already voted on this proposal.");

        hasVotedOnEventProposal[_eventId][msg.sender] = true;

        if (_approve) {
            event_.proposalVotesFor += getUserProfile(msg.sender).foresightPoints > 0 ? getUserProfile(msg.sender).foresightPoints : 1; // Foresight points give weight
        } else {
            event_.proposalVotesAgainst += getUserProfile(msg.sender).foresightPoints > 0 ? getUserProfile(msg.sender).foresightPoints : 1;
        }

        emit EventProposalVoted(_eventId, msg.sender, _approve);
    }

    // 7. Moves a proposed event to 'Active' if it meets the approval threshold.
    function finalizeEventProposal(uint256 _eventId)
        external
        whenNotPaused
        eventExists(_eventId)
        nonReentrant
    {
        Event storage event_ = events[_eventId];
        require(event_.status == EventStatus.Proposed, "NexusOracle: Event is not in proposed status.");

        uint256 totalVotes = event_.proposalVotesFor + event_.proposalVotesAgainst;
        require(totalVotes > 0, "NexusOracle: No votes cast yet.");

        // Check if approval threshold is met
        if ((event_.proposalVotesFor * 10000) / totalVotes >= eventProposalVoteThreshold) {
            event_.status = EventStatus.Active;
            emit EventProposalFinalized(_eventId, EventStatus.Active);
        } else {
            // If not approved, remove it or set a 'Rejected' status
            // For simplicity, we'll just leave it in 'Proposed' and it effectively expires.
            // A more complex system might have a 'Rejected' status and allow re-proposal.
        }
    }

    // 8. Users stake `_amount` of `NexusToken` on a specific outcome.
    function submitPrediction(uint256 _eventId, uint8 _chosenOptionIndex, uint256 _amount)
        external
        whenNotPaused
        predictionOpen(_eventId)
        nonReentrant
    {
        Event storage event_ = events[_eventId];
        require(_amount >= minStakeAmount, "NexusOracle: Stake amount too low.");
        require(_chosenOptionIndex > 0 && _chosenOptionIndex <= event_.options.length, "NexusOracle: Invalid option index.");
        require(userPredictions[_eventId][msg.sender].stakedAmount == 0, "NexusOracle: You already have an active prediction for this event.");

        // Transfer tokens from user to contract
        require(nexusToken.transferFrom(msg.sender, address(this), _amount), "NexusOracle: Token transfer failed.");

        Prediction storage newPrediction = userPredictions[_eventId][msg.sender];
        newPrediction.eventId = _eventId;
        newPrediction.predictor = msg.sender;
        newPrediction.chosenOption = Outcome(_chosenOptionIndex);
        newPrediction.stakedAmount = _amount;
        newPrediction.timestamp = block.timestamp;
        newPrediction.claimed = false;

        event_.totalStaked += _amount;
        event_.stakedPerOption[_chosenOptionIndex] += _amount;

        userProfiles[msg.sender].totalPredictions++;
        userProfiles[msg.sender].totalStaked += _amount;

        emit PredictionSubmitted(_eventId, msg.sender, Outcome(_chosenOptionIndex), _amount);
    }

    // 9. Allows a user to cancel their prediction *before* the prediction deadline.
    function cancelPrediction(uint256 _eventId)
        external
        whenNotPaused
        eventExists(_eventId)
        nonReentrant
    {
        Event storage event_ = events[_eventId];
        Prediction storage prediction_ = userPredictions[_eventId][msg.sender];

        require(prediction_.stakedAmount > 0 && !prediction_.claimed && !prediction_.cancelled, "NexusOracle: No active prediction to cancel for this event.");
        require(event_.status == EventStatus.Active, "NexusOracle: Event is not active.");
        require(block.timestamp < event_.predictionDeadline, "NexusOracle: Prediction deadline has passed, cannot cancel.");

        uint256 refundAmount = prediction_.stakedAmount; // No penalty for cancellation before deadline, or could add one
        
        event_.totalStaked -= refundAmount;
        event_.stakedPerOption[uint8(prediction_.chosenOption)] -= refundAmount;

        prediction_.stakedAmount = 0; // Effectively remove the prediction
        prediction_.cancelled = true;

        userProfiles[msg.sender].totalStaked -= refundAmount; // Adjust user profile total staked

        require(nexusToken.transfer(msg.sender, refundAmount), "NexusOracle: Refund transfer failed.");
        emit PredictionCancelled(_eventId, msg.sender, refundAmount);
    }

    // 10. An *approved Insight Oracle* resolves an event.
    function resolveEventByOracle(uint256 _eventId, uint8 _winningOptionIndex, uint256 _oracleId)
        external
        whenNotPaused
        onlyOracle(_oracleId)
        eventExists(_eventId)
        resolutionOpen(_eventId)
        nonReentrant
    {
        Event storage event_ = events[_eventId];
        Oracle storage oracle_ = oracles[_oracleId];

        require(event_.status == EventStatus.Active, "NexusOracle: Event is not active for oracle resolution.");
        require(_winningOptionIndex > 0 && _winningOptionIndex <= event_.options.length, "NexusOracle: Invalid winning option index.");
        require(oracle_.eventResolutions[_eventId] == Outcome.Undetermined, "NexusOracle: Oracle already resolved this event.");

        event_.winningOption = Outcome(_winningOptionIndex);
        event_.status = EventStatus.Resolved;
        event_.resolverAddress = msg.sender;

        oracle_.totalResolutions++;
        oracle_.eventResolutions[_eventId] = Outcome(_winningOptionIndex); // Record oracle's resolution

        // Calculate correct/incorrect staked amounts for the event
        event_.totalCorrectStaked = event_.stakedPerOption[_winningOptionIndex];
        event_.totalIncorrectStaked = event_.totalStaked - event_.totalCorrectStaked;

        // Recalibrate system parameters based on this resolution's impact
        recalibrateSystemParameters(); // Trigger adaptive learning

        emit EventResolved(_eventId, Outcome(_winningOptionIndex), msg.sender);
    }

    // 11. Allows the owner or a whitelisted multi-sig to resolve an event if no oracle does, or if an oracle is disputed.
    function resolveEventByConsensus(uint256 _eventId, uint8 _winningOptionIndex)
        external
        whenNotPaused
        onlyOwner // Can be extended to a multi-sig or DAO voting
        eventExists(_eventId)
        resolutionOpen(_eventId)
        nonReentrant
    {
        Event storage event_ = events[_eventId];
        require(event_.status == EventStatus.Active || event_.status == EventStatus.Disputed, "NexusOracle: Event not in a resolvable state by consensus.");
        require(_winningOptionIndex > 0 && _winningOptionIndex <= event_.options.length, "NexusOracle: Invalid winning option index.");

        event_.winningOption = Outcome(_winningOptionIndex);
        event_.status = EventStatus.Resolved;
        event_.resolverAddress = msg.sender;

        event_.totalCorrectStaked = event_.stakedPerOption[_winningOptionIndex];
        event_.totalIncorrectStaked = event_.totalStaked - event_.totalCorrectStaked;

        recalibrateSystemParameters(); // Trigger adaptive learning

        emit EventResolved(_eventId, Outcome(_winningOptionIndex), msg.sender);
    }

    // 12. Users can dispute an event's resolution, initiating a community vote.
    function disputeResolution(uint256 _eventId)
        external
        payable
        whenNotPaused
        eventExists(_eventId)
        nonReentrant
    {
        Event storage event_ = events[_eventId];
        require(event_.status == EventStatus.Resolved, "NexusOracle: Event is not in resolved status to dispute.");
        require(msg.value >= disputeFee, "NexusOracle: Insufficient dispute fee.");
        require(block.timestamp < event_.resolutionDeadline, "NexusOracle: Dispute deadline has passed.");

        event_.status = EventStatus.Disputed;
        accumulatedFees += disputeFee;
        emit DisputeInitiated(_eventId, msg.sender);
    }

    // 13. Community members vote on the validity of a disputed resolution.
    function voteOnDispute(uint256 _eventId, bool _correct)
        external
        whenNotPaused
        eventExists(_eventId)
        nonReentrant
    {
        Event storage event_ = events[_eventId];
        require(event_.status == EventStatus.Disputed, "NexusOracle: Event is not in dispute.");
        require(!hasVotedOnDispute[_eventId][msg.sender], "NexusOracle: Already voted on this dispute.");
        require(block.timestamp < event_.resolutionDeadline, "NexusOracle: Dispute voting deadline has passed.");

        hasVotedOnDispute[_eventId][msg.sender] = true;

        // Weight votes by foresight points
        uint256 voteWeight = userProfiles[msg.sender].foresightPoints > 0 ? userProfiles[msg.sender].foresightPoints : 1;

        if (_correct) {
            event_.disputeVotesFor += voteWeight;
        } else {
            event_.disputeVotesAgainst += voteWeight;
        }

        emit DisputeVoted(_eventId, msg.sender, _correct);
    }

    // 14. Admin or automated process finalizes a dispute.
    function finalizeDispute(uint256 _eventId)
        external
        whenNotPaused
        onlyOwner // Can be automated or extended to a multi-sig
        eventExists(_eventId)
        nonReentrant
    {
        Event storage event_ = events[_eventId];
        require(event_.status == EventStatus.Disputed, "NexusOracle: Event is not in dispute.");
        require(block.timestamp >= event_.resolutionDeadline, "NexusOracle: Dispute voting is still open."); // Ensure voting period ended

        uint256 totalDisputeVotes = event_.disputeVotesFor + event_.disputeVotesAgainst;
        require(totalDisputeVotes > 0, "NexusOracle: No votes cast for dispute.");

        bool resolutionChanged = false;
        if ((event_.disputeVotesAgainst * 10000) / totalDisputeVotes >= disputeVoteThreshold) {
            // Dispute successful: original resolution was incorrect.
            // A more complex system would allow the community to propose a new winning option.
            // For simplicity, owner now sets the new correct resolution.
            // Original resolver (if it was an oracle) might lose FP or collateral.
            
            // Revert original oracle's accuracy record if applicable
            if (event_.resolverAddress != address(0) && oracleAddresses[event_.resolverAddress] != 0) {
                Oracle storage resolverOracle = oracles[oracleAddresses[event_.resolverAddress]];
                if (resolverOracle.correctResolutions > 0) {
                    resolverOracle.correctResolutions--; // Reduce correct count
                }
                resolverOracle.foresightPoints = resolverOracle.foresightPoints > 100 ? resolverOracle.foresightPoints - 100 : 0; // Penalize FP
            }

            event_.status = EventStatus.Active; // Revert to active for re-resolution
            event_.winningOption = Outcome.Undetermined; // Clear incorrect winner
            resolutionChanged = true;
            emit DisputeFinalized(_eventId, Outcome.Undetermined, resolutionChanged);

        } else {
            // Dispute failed: original resolution stands.
            event_.status = EventStatus.Resolved; // Go back to resolved
            emit DisputeFinalized(_eventId, event_.winningOption, resolutionChanged);
        }
        recalibrateSystemParameters(); // Recalibrate after dispute resolution
    }

    // --- C. Oracle Management ---

    // 15. Allows a user to register as an "Insight Oracle".
    function registerOracle(string calldata _name)
        external
        whenNotPaused
        nonReentrant
    {
        require(oracleAddresses[msg.sender] == 0, "NexusOracle: Address already registered as an oracle.");
        require(nexusToken.transferFrom(msg.sender, address(this), oracleRegistrationFee), "NexusOracle: Oracle registration fee transfer failed.");

        uint256 currentOracleId = nextOracleId++;
        Oracle storage newOracle = oracles[currentOracleId];
        newOracle.id = currentOracleId;
        newOracle.oracleAddress = msg.sender;
        newOracle.name = _name;
        newOracle.registrationTimestamp = block.timestamp;
        newOracle.stakedCollateral = oracleRegistrationFee;
        newOracle.isActive = true;
        newOracle.foresightPoints = 100; // Start with some base FP

        oracleAddresses[msg.sender] = currentOracleId;
        accumulatedFees += oracleRegistrationFee;

        emit OracleRegistered(currentOracleId, msg.sender, _name);
    }

    // 16. Allows an oracle to deregister.
    function deregisterOracle(uint256 _oracleId)
        external
        whenNotPaused
        onlyOracle(_oracleId)
        nonReentrant
    {
        Oracle storage oracle_ = oracles[_oracleId];
        require(oracle_.isActive, "NexusOracle: Oracle is already inactive.");

        // Implement a cooldown period or penalty if necessary
        // For simplicity, direct deregister and return collateral
        oracle_.isActive = false;
        oracleAddresses[msg.sender] = 0; // Remove mapping

        require(nexusToken.transfer(msg.sender, oracle_.stakedCollateral), "NexusOracle: Collateral withdrawal failed.");
        emit OracleDeregistered(_oracleId, msg.sender);
    }

    // 17. Internal/called by `resolveEvent` to track an oracle's accuracy.
    function updateOraclePerformance(uint256 _oracleId, bool _wasAccurate) internal {
        Oracle storage oracle_ = oracles[_oracleId];
        require(oracle_.isActive, "NexusOracle: Cannot update inactive oracle's performance.");

        if (_wasAccurate) {
            oracle_.correctResolutions++;
            oracle_.foresightPoints += foresightPointMultiplier; // Reward FP
        } else {
            oracle_.foresightPoints = oracle_.foresightPoints > (foresightPointMultiplier * 2) ? oracle_.foresightPoints - (foresightPointMultiplier * 2) : 0; // Penalize FP
        }
    }

    // --- D. Rewards & Reputation ---

    // 18. Allows users to claim their `NexusToken` rewards and Foresight Points.
    function claimRewards(uint256 _eventId)
        external
        whenNotPaused
        eventExists(_eventId)
        nonReentrant
    {
        Event storage event_ = events[_eventId];
        Prediction storage prediction_ = userPredictions[_eventId][msg.sender];

        require(event_.status == EventStatus.Resolved, "NexusOracle: Event is not resolved.");
        require(prediction_.stakedAmount > 0, "NexusOracle: No prediction found for this user and event.");
        require(!prediction_.claimed, "NexusOracle: Rewards already claimed for this prediction.");
        require(event_.winningOption != Outcome.Undetermined, "NexusOracle: Event outcome not determined.");

        prediction_.claimed = true;
        userProfiles[msg.sender].totalClaimedRewards += prediction_.stakedAmount; // Initial stake considered part of 'rewards' for tracking

        uint256 rewardAmount = 0;
        uint256 foresightPointsEarned = 0;

        if (prediction_.chosenOption == event_.winningOption) {
            // Correct prediction: Calculate reward including base multiplier and synergistic bonus
            uint256 baseReward = (prediction_.stakedAmount * baseRewardMultiplier) / 10000;
            rewardAmount = baseReward + calculateSynergisticReward(_eventId, msg.sender);
            foresightPointsEarned = (prediction_.stakedAmount * foresightPointMultiplier) / 1 ether; // Adjust unit based on token decimals

            userProfiles[msg.sender].correctPredictions++;
            userProfiles[msg.sender].foresightPoints += foresightPointsEarned;
            userProfiles[msg.sender].totalClaimedRewards += (rewardAmount - prediction_.stakedAmount); // Only added profit for total claimed

        } else {
            // Incorrect prediction: Apply penalty
            uint256 penalty = (prediction_.stakedAmount * penaltyMultiplier) / 10000;
            rewardAmount = prediction_.stakedAmount - penalty;
            accumulatedFees += penalty; // Add penalty to accumulated fees

            userProfiles[msg.sender].foresightPoints = userProfiles[msg.sender].foresightPoints > (foresightPointMultiplier / 2) ? userProfiles[msg.sender].foresightPoints - (foresightPointMultiplier / 2) : 0; // Small FP penalty
        }

        require(nexusToken.transfer(msg.sender, rewardAmount), "NexusOracle: Reward transfer failed.");
        emit RewardsClaimed(_eventId, msg.sender, rewardAmount, foresightPointsEarned);
    }

    // 19. Internal function to calculate enhanced rewards for users who correctly predicted *and* were part of the majority correct prediction.
    function calculateSynergisticReward(uint256 _eventId, address _user) internal view returns (uint256) {
        Event storage event_ = events[_eventId];
        Prediction storage prediction_ = userPredictions[_eventId][_user];

        if (prediction_.chosenOption != event_.winningOption) {
            return 0; // Only for correct predictions
        }

        // Synergistic bonus for aligning with the majority correct prediction
        // E.g., if 80% of total stake on winning option, bonus is (80% / 100%) * X% of stake
        // This encourages collective intelligence
        if (event_.totalCorrectStaked == 0) return 0; // Avoid division by zero

        uint256 majorityPercentage = (event_.stakedPerOption[uint8(event_.winningOption)] * 10000) / event_.totalStaked;
        // For example, if majority is 80%, give 0.05% of stake as bonus
        // The more aligned the collective is, the higher the bonus (up to a cap)
        uint256 bonusMultiplier = (majorityPercentage * 5) / 100; // 0.05% bonus per 1% of majority (capped at 500 = 5%)
        return (prediction_.stakedAmount * bonusMultiplier) / 10000;
    }

    // 20. **(Advanced & Trendy)** Recalibrates system parameters based on overall system and oracle accuracy.
    function recalibrateSystemParameters() internal {
        // This function would ideally be called by a trusted off-chain process
        // or a DAO vote periodically, or after a certain number of events are resolved.
        // For demonstration, we'll call it internally upon event resolution.

        uint256 totalSystemCorrect = 0;
        uint256 totalSystemPredictions = 0;
        uint256 totalOracleCorrect = 0;
        uint256 totalOracleResolutions = 0;

        // Iterate through resolved events to get system accuracy
        for (uint256 i = 0; i < nextEventId; i++) {
            if (events[i].status == EventStatus.Resolved && events[i].totalStaked > 0) {
                totalSystemPredictions += events[i].totalStaked; // Sum of all stakes
                totalSystemCorrect += events[i].totalCorrectStaked; // Sum of correct stakes

                // If event was resolved by an oracle, contribute to oracle accuracy
                if (events[i].resolverAddress != address(0) && oracleAddresses[events[i].resolverAddress] != 0) {
                    Oracle storage resolverOracle = oracles[oracleAddresses[events[i].resolverAddress]];
                    totalOracleResolutions++;
                    if (events[i].winningOption == resolverOracle.eventResolutions[i]) {
                        totalOracleCorrect++;
                    }
                }
            }
        }

        // Calculate overall system accuracy (if there are predictions)
        if (totalSystemPredictions > 0) {
            overallSystemAccuracy = (totalSystemCorrect * 10000) / totalSystemPredictions; // In basis points (10000 = 100%)
        } else {
            overallSystemAccuracy = 5000; // Default if no data
        }

        // Calculate overall oracle accuracy (if there are oracle resolutions)
        if (totalOracleResolutions > 0) {
            overallOracleAccuracy = (totalOracleCorrect * 10000) / totalOracleResolutions;
        } else {
            overallOracleAccuracy = 5000; // Default if no data
        }

        // Adjust parameters based on accuracies (simplified "learning" algorithm)
        // If overall accuracy is high, increase rewards and decrease penalties
        // If low, decrease rewards and increase penalties
        if (overallSystemAccuracy >= 7500) { // >= 75%
            baseRewardMultiplier = _min(baseRewardMultiplier + 50, 11500); // Cap at 1.15x
            penaltyMultiplier = _max(penaltyMultiplier - 25, 200);   // Min 2%
        } else if (overallSystemAccuracy <= 4000) { // <= 40%
            baseRewardMultiplier = _max(baseRewardMultiplier - 50, 10050); // Min 1.005x
            penaltyMultiplier = _min(penaltyMultiplier + 25, 1000); // Max 10%
        }

        // Adjust FP multiplier based on overall oracle accuracy
        if (overallOracleAccuracy >= 8000) { // >= 80%
            foresightPointMultiplier = _min(foresightPointMultiplier + 1, 20); // Max FP per NEX
        } else if (overallOracleAccuracy <= 5000) { // <= 50%
            foresightPointMultiplier = _max(foresightPointMultiplier - 1, 5); // Min FP per NEX
        }

        emit SystemParametersRecalibrated(baseRewardMultiplier, penaltyMultiplier, foresightPointMultiplier);
    }

    // Helper for min (Solidity doesn't have built-in)
    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    // Helper for max (Solidity doesn't have built-in)
    function _max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    // 21. Allows the owner or contract to withdraw accumulated fees.
    function withdrawDisputeFees(address _to) external onlyOwner nonReentrant {
        require(_to != address(0), "NexusOracle: Target address cannot be zero.");
        uint256 amount = accumulatedFees;
        accumulatedFees = 0;
        require(nexusToken.transfer(_to, amount), "NexusOracle: Fee withdrawal failed.");
    }

    // --- E. View Functions (Read-Only) ---

    // 22. Retrieves all details of a specific event.
    function getEventDetails(uint256 _eventId)
        public
        view
        eventExists(_eventId)
        returns (
            uint256 id,
            string memory description,
            string[] memory options,
            uint256 predictionDeadline,
            uint256 resolutionDeadline,
            EventStatus status,
            Outcome winningOption,
            address proposer,
            uint256 totalStaked,
            uint256[] memory stakedPerOptionArray,
            address resolverAddress,
            uint256 proposalVotesFor,
            uint256 proposalVotesAgainst,
            uint256 disputeVotesFor,
            uint256 disputeVotesAgainst
        )
    {
        Event storage event_ = events[_eventId];

        // Convert mapping to array for external return
        stakedPerOptionArray = new uint256[](event_.options.length + 1); // +1 for 0-index placeholder or empty slot
        for (uint8 i = 1; i <= event_.options.length; i++) {
            stakedPerOptionArray[i] = event_.stakedPerOption[i];
        }

        return (
            event_.id,
            event_.description,
            event_.options,
            event_.predictionDeadline,
            event_.resolutionDeadline,
            event_.status,
            event_.winningOption,
            event_.proposer,
            event_.totalStaked,
            stakedPerOptionArray,
            event_.resolverAddress,
            event_.proposalVotesFor,
            event_.proposalVotesAgainst,
            event_.disputeVotesFor,
            event_.disputeVotesAgainst
        );
    }

    // 23. Retrieves a user's prediction for a specific event.
    function getUserPrediction(uint256 _eventId, address _user)
        public
        view
        eventExists(_eventId)
        returns (
            uint256 eventId,
            address predictor,
            Outcome chosenOption,
            uint256 stakedAmount,
            uint256 timestamp,
            bool claimed,
            bool cancelled
        )
    {
        Prediction storage prediction_ = userPredictions[_eventId][_user];
        return (
            prediction_.eventId,
            prediction_.predictor,
            prediction_.chosenOption,
            prediction_.stakedAmount,
            prediction_.timestamp,
            prediction_.claimed,
            prediction_.cancelled
        );
    }

    // 24. Retrieves a user's Foresight Points and other profile data.
    function getUserProfile(address _user)
        public
        view
        returns (
            uint256 foresightPoints,
            uint256 totalPredictions,
            uint256 correctPredictions,
            uint256 totalStaked,
            uint256 totalClaimedRewards
        )
    {
        UserProfile storage profile_ = userProfiles[_user];
        return (
            profile_.foresightPoints,
            profile_.totalPredictions,
            profile_.correctPredictions,
            profile_.totalStaked,
            profile_.totalClaimedRewards
        );
    }

    // 25. Retrieves an oracle's details and performance.
    function getOracleInfo(uint256 _oracleId)
        public
        view
        returns (
            uint256 id,
            address oracleAddress,
            string memory name,
            uint256 registrationTimestamp,
            uint256 stakedCollateral,
            uint256 totalResolutions,
            uint256 correctResolutions,
            uint256 foresightPoints,
            bool isActive
        )
    {
        Oracle storage oracle_ = oracles[_oracleId];
        return (
            oracle_.id,
            oracle_.oracleAddress,
            oracle_.name,
            oracle_.registrationTimestamp,
            oracle_.stakedCollateral,
            oracle_.totalResolutions,
            oracle_.correctResolutions,
            oracle_.foresightPoints,
            oracle_.isActive
        );
    }
}
```