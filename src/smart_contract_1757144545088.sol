This smart contract, named **AetherMind**, represents a Decentralized Intelligence & Adaptive Reputation Network. It's designed to foster a collective intelligence by allowing users to make predictions on real-world events, with their reputation dynamically adjusting based on the accuracy of their predictions. High-reputation users gain more influence, higher rewards, and play a crucial role in the platform's decentralized governance and event resolution.

The core concepts include:
1.  **Adaptive Reputation System:** A user's reputation is not static; it grows with accurate predictions and decays over time or with incorrect predictions, ensuring only active and insightful participants hold sway.
2.  **Reputation-Weighted Prediction Markets:** Users stake tokens and make predictions. Successful predictions boost reputation and earn rewards, while incorrect ones may reduce reputation and incur partial slashing of stakes.
3.  **Decentralized Oracle & Challenge Mechanism:** Event outcomes are submitted by approved oracles, but high-reputation users can challenge controversial results, leading to a community resolution process.
4.  **Self-Evolving Governance (DAO):** System parameters (e.g., reward multipliers, decay rates) can be proposed and voted upon by the community, with voting power weighted by reputation, allowing the protocol to adapt and improve over time.
5.  **Gamified Incentives:** While not explicitly NFT-based in this code, the system lays the groundwork for features like leaderboards and accuracy tracking, which could be used to issue dynamic NFTs or badges.

---

**Outline:**

**I. Contract Setup & Token Management**
    - Initialization of the contract with a governance token.
    - Staking and unstaking of tokens for participation.
    - Querying staked balances.

**II. Adaptive Reputation System**
    - Dynamic calculation and storage of user reputation.
    - Mechanism for reputation decay over time to maintain activity.
    - Internal functions for reputation updates based on event outcomes.

**III. Prediction Event Lifecycle**
    - Proposal and approval process for new events where users can predict.
    - Submission and cancellation of user predictions for active events.
    - Retrieval of event details and specific user predictions.

**IV. Event Resolution & Rewards**
    - Submission of event outcomes by designated oracles.
    - A challenge mechanism allowing high-reputation users to dispute oracle results.
    - Finalization of events, including reward distribution and reputation adjustments.
    - Users claiming their earned rewards.

**V. Decentralized Autonomous Organization (DAO) & Adaptive Parameters**
    - Creation of proposals for modifying core system parameters.
    - Reputation-weighted voting on proposals.
    - Execution of successfully passed proposals to update contract logic/parameters.

**VI. Utility & Analytics**
    - Retrieval of a reputation-based leaderboard.
    - Calculation and querying of a user's overall prediction accuracy.
    - Mechanism for the DAO to withdraw accumulated protocol fees.

---

**Function Summary:**

1.  **`constructor(address _governanceToken)`**: Initializes the contract by setting the address of the ERC-20 token used for staking and rewards.
2.  **`setGovernanceToken(address _token)`**: Allows the owner (or eventually DAO) to update the governance token address.
3.  **`stakeTokens(uint256 amount)`**: Users call this to stake `amount` of governance tokens, becoming participants in the AetherMind collective.
4.  **`unstakeTokens(uint256 amount)`**: Users can request to unstake `amount` of their tokens, subject to a cool-down period or other conditions (not fully implemented in this example for brevity but intended).
5.  **`getAvailableStake(address user)`**: Returns the total amount of governance tokens currently staked by a specific `user`.
6.  **`getUserReputation(address user)`**: Retrieves the current reputation score for a given `user`.
7.  **`_updateReputation(address user, int256 change)`**: An internal function used by the contract to adjust a user's reputation (positive for correct predictions, negative for incorrect/decay).
8.  **`decayReputation()`**: A public, permissionless function that can be called periodically (e.g., by a keeper bot) to apply the reputation decay across all participants.
9.  **`getReputationDecayRate()`**: Returns the current percentage at which reputation decays per interval.
10. **`proposeEvent(string calldata description, uint256 endTime, bytes32 externalId)`**: Allows users (meeting a minimum reputation threshold) to propose new events for prediction, specifying a `description`, `endTime` for predictions, and an `externalId` for off-chain reference.
11. **`approveProposedEvent(bytes32 eventId)`**: High-reputation users or the DAO can approve a proposed event, making it open for predictions.
12. **`submitPrediction(bytes32 eventId, uint256 predictionValue, uint256 stakeAmount)`**: Users submit their prediction (`predictionValue`) for a specific `eventId` along with a `stakeAmount` in governance tokens.
13. **`cancelPrediction(bytes32 eventId)`**: Allows a user to cancel their submitted prediction for an `eventId` before its `endTime`, with a partial refund of their stake.
14. **`getEventDetails(bytes32 eventId)`**: Retrieves comprehensive details about an event, including its status, description, and resolution information.
15. **`getUserPredictionForEvent(bytes32 eventId, address user)`**: Fetches the `predictionValue` and `stakeAmount` submitted by a specific `user` for a given `eventId`.
16. **`submitOracleResult(bytes32 eventId, uint256 result, bytes32 oracleRef)`**: An authorized oracle submits the final `result` (outcome) for an `eventId`, along with an `oracleRef` for proof.
17. **`challengeOracleResult(bytes32 eventId, bytes32 oracleRef, string calldata reason)`**: High-reputation users can challenge a submitted oracle `result`, initiating a dispute resolution process (requires a challenge stake).
18. **`resolveEvent(bytes32 eventId)`**: Finalizes an event, processing the oracle result (or challenge outcome), distributing rewards to correct predictors, and applying reputation adjustments (gains for correct, losses for incorrect).
19. **`claimPredictionRewards(bytes32 eventId)`**: Users call this to claim their share of rewards and solidified reputation gains after an `eventId` has been resolved.
20. **`proposeParameterChange(string calldata description, bytes32 paramName, uint256 newValue)`**: Allows qualified participants to propose changes to system-wide parameters, such as `reputationDecayRate` or `rewardMultiplier`.
21. **`voteOnProposal(bytes32 proposalId, bool support)`**: Participants with sufficient reputation cast their `support` (true/false) on a given `proposalId`, with their vote weight proportional to their reputation.
22. **`executeProposal(bytes32 proposalId)`**: Once a `proposalId` has passed its voting period and met the approval threshold, this function executes the proposed parameter change.
23. **`getReputationLeaderboard(uint256 start, uint256 end)`**: Returns a paginated list of addresses and their reputation, representing the top participants. (Note: Direct on-chain leaderboards for large user bases are gas-intensive; this is a simplified example).
24. **`getPredictionAccuracy(address user)`**: Calculates and returns the percentage of correct predictions made by a specific `user` out of their total predictions.
25. **`withdrawFees(address to)`**: Allows the DAO (via an executed proposal or owner) to withdraw accumulated protocol fees to a specified `to` address.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title AetherMind
 * @dev A Decentralized Intelligence & Adaptive Reputation Network.
 *      Users stake tokens to make predictions on events. Reputation adapts based on prediction accuracy.
 *      High-reputation users influence event approval, challenge oracle results, and participate in
 *      reputation-weighted DAO governance to self-evolve protocol parameters.
 */
contract AetherMind is Ownable {
    using SafeMath for uint256;

    // --- I. Contract Setup & Token Management ---
    IERC20 public governanceToken;
    uint256 public constant INITIAL_REPUTATION = 1000; // Base reputation for new participants
    uint256 public minStakeForPrediction = 1 ether; // Minimum tokens required to stake on a prediction
    uint256 public maxStakeForPrediction = 1000 ether; // Maximum tokens allowed to stake on a prediction
    uint256 public protocolFeePercentage = 5; // 5% of incorrect predictions' stakes go to protocol, rest to winners.
    uint256 public totalProtocolFees; // Accumulated fees

    // --- II. Adaptive Reputation System ---
    mapping(address => uint256) public userReputation; // Stores reputation score for each address
    uint256 public reputationDecayRate = 1; // Percentage (e.g., 1% means 100 base points) per decay interval
    uint256 public reputationDecayInterval = 30 days; // How often reputation decays
    uint256 private lastReputationDecayTimestamp; // Timestamp of the last reputation decay application
    uint256 public reputationGainMultiplier = 10; // Multiplier for reputation gain on correct predictions (x*stake/1000)
    uint256 public reputationLossMultiplier = 5; // Multiplier for reputation loss on incorrect predictions (x*stake/1000)

    // --- III. Prediction Event Lifecycle ---
    struct PredictionEvent {
        string description;       // Description of the event
        uint256 creationTime;     // Timestamp when the event was created
        uint256 predictionEndTime; // Time until which predictions can be submitted
        uint256 resolutionTime;   // Time when event was resolved
        uint256 actualResult;     // The actual outcome of the event
        bool isResolved;          // True if the event has been resolved
        bool isChallenged;        // True if the oracle result is challenged
        address proposer;         // Address of the event proposer
        bytes32 externalId;       // Optional: ID for external reference or unique identifier
        mapping(address => UserPrediction) predictions; // User's prediction for this event
        address[] participants;   // List of addresses that participated in this event (for iteration)
        uint256 totalStaked;      // Total tokens staked across all predictions for this event
        uint256 totalCorrectStake; // Total tokens staked on the correct outcome
        bytes32 oracleRef;        // Reference/ID of the oracle submission
        address challenger;       // Address of the user who challenged the oracle result
        uint224 challengeStartTimestamp; // Timestamp when a challenge started
        bool exists;              // To track if an event ID is valid
    }

    struct UserPrediction {
        uint256 value;   // The predicted outcome (e.g., 0 for no, 1 for yes, etc.)
        uint256 stake;   // Tokens staked on this prediction
        bool claimed;    // True if user has claimed rewards for this prediction
        bool exists;     // To check if user has predicted for this event
    }

    mapping(bytes32 => PredictionEvent) public events; // Mapping event hash to event details
    bytes32[] public allEventIds; // All proposed event IDs (for iteration/leaderboard considerations)

    uint256 public minReputationToProposeEvent = 2000; // Min reputation to propose an event
    uint256 public minReputationToApproveEvent = 5000; // Min reputation to approve a proposed event

    // --- IV. Event Resolution & Rewards ---
    uint256 public challengeStake = 10 ether; // Stake required to challenge an oracle result
    uint256 public challengePeriod = 3 days; // Time window to challenge an oracle result
    address[] public authorizedOracles; // List of addresses authorized to submit oracle results

    // --- V. Decentralized Autonomous Organization (DAO) & Adaptive Parameters ---
    struct Proposal {
        bytes32 proposalId;     // Unique ID for the proposal
        string description;     // Description of the proposed change
        bytes32 paramName;      // Name of the parameter to change (e.g., "reputationDecayRate")
        uint256 newValue;       // The new value for the parameter
        uint256 creationTime;   // Timestamp when the proposal was created
        uint256 votingEndTime;  // Time until which votes can be cast
        uint256 totalVotesFor;  // Sum of reputation-weighted votes for the proposal
        uint256 totalVotesAgainst; // Sum of reputation-weighted votes against the proposal
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
        bool executed;          // True if the proposal has been executed
        bool exists;            // To check if a proposal ID is valid
    }

    mapping(bytes32 => Proposal) public proposals; // Mapping proposal hash to proposal details
    bytes32[] public activeProposals; // List of active proposals

    uint256 public proposalVotingPeriod = 7 days; // Duration for voting on a proposal
    uint256 public minReputationToPropose = 2000; // Minimum reputation to propose a DAO change
    uint256 public minReputationForVoteWeight = 100; // Minimum reputation to have voting weight
    uint256 public proposalExecutionThreshold = 60; // 60% reputation-weighted 'for' votes needed for passage

    // --- VI. Utility & Analytics ---
    mapping(address => uint256) public totalPredictionsMade; // Total predictions made by a user
    mapping(address => uint256) public correctPredictions; // Count of correct predictions by a user
    mapping(address => uint256) public totalStakedByParticipant; // Total tokens ever staked by a participant
    mapping(address => uint252) public totalRewardsEarned; // Total rewards earned by a participant


    // --- Events ---
    event GovernanceTokenSet(address indexed _token);
    event TokensStaked(address indexed user, uint256 amount);
    event TokensUnstaked(address indexed user, uint256 amount);
    event ReputationUpdated(address indexed user, uint256 newReputation);
    event EventProposed(bytes32 indexed eventId, address indexed proposer, uint256 endTime, bytes32 externalId);
    event EventApproved(bytes32 indexed eventId, address indexed approver);
    event PredictionSubmitted(bytes32 indexed eventId, address indexed user, uint256 predictionValue, uint256 stakeAmount);
    event PredictionCancelled(bytes32 indexed eventId, address indexed user, uint256 refundedStake);
    event OracleResultSubmitted(bytes32 indexed eventId, bytes32 indexed oracleRef, uint256 result);
    event OracleResultChallenged(bytes32 indexed eventId, address indexed challenger, uint256 challengeStake);
    event EventResolved(bytes32 indexed eventId, uint256 actualResult, uint256 totalWinners, uint256 totalRewardsDistributed);
    event RewardsClaimed(bytes32 indexed eventId, address indexed user, uint252 rewardAmount);
    event ProposalCreated(bytes32 indexed proposalId, address indexed proposer, bytes32 paramName, uint256 newValue);
    event VoteCast(bytes32 indexed proposalId, address indexed voter, bool support, uint256 reputationWeight);
    event ProposalExecuted(bytes32 indexed proposalId, bytes32 paramName, uint256 newValue);
    event FeesWithdrawn(address indexed to, uint256 amount);

    // --- Modifiers ---
    modifier onlyAuthorizedOracle() {
        bool authorized = false;
        for (uint256 i = 0; i < authorizedOracles.length; i++) {
            if (authorizedOracles[i] == msg.sender) {
                authorized = true;
                break;
            }
        }
        require(authorized, "AetherMind: Caller is not an authorized oracle");
        _;
    }

    // --- I. Contract Setup & Token Management ---

    constructor(address _governanceToken) {
        governanceToken = IERC20(_governanceToken);
        lastReputationDecayTimestamp = block.timestamp;
        // Initialize the owner's reputation to a high value for initial governance if needed
        userReputation[msg.sender] = INITIAL_REPUTATION * 10;
        emit GovernanceTokenSet(_governanceToken);
    }

    /**
     * @dev Allows the owner to set the governance token address.
     *      Intended to be transferred to DAO control after initial setup.
     * @param _token The address of the ERC-20 token to be used.
     */
    function setGovernanceToken(address _token) external onlyOwner {
        require(address(0) != _token, "AetherMind: Token address cannot be zero");
        governanceToken = IERC20(_token);
        emit GovernanceTokenSet(_token);
    }

    /**
     * @dev Allows users to stake governance tokens to participate in the network.
     *      New users will receive initial reputation.
     * @param amount The amount of tokens to stake.
     */
    function stakeTokens(uint256 amount) external {
        require(amount > 0, "AetherMind: Stake amount must be positive");
        require(governanceToken.transferFrom(msg.sender, address(this), amount), "AetherMind: Token transfer failed");

        // Initialize reputation for new stakers
        if (userReputation[msg.sender] == 0) {
            userReputation[msg.sender] = INITIAL_REPUTATION;
            emit ReputationUpdated(msg.sender, INITIAL_REPUTATION);
        }
        totalStakedByParticipant[msg.sender] = totalStakedByParticipant[msg.sender].add(amount);
        emit TokensStaked(msg.sender, amount);
    }

    /**
     * @dev Allows users to unstake governance tokens.
     *      Future implementation might include cool-down periods or reputation requirements.
     * @param amount The amount of tokens to unstake.
     */
    function unstakeTokens(uint256 amount) external {
        require(amount > 0, "AetherMind: Unstake amount must be positive");
        require(totalStakedByParticipant[msg.sender] >= amount, "AetherMind: Insufficient staked tokens");

        // TODO: Implement checks for active predictions or cool-down period
        // For now, simple unstake logic
        totalStakedByParticipant[msg.sender] = totalStakedByParticipant[msg.sender].sub(amount);
        require(governanceToken.transfer(msg.sender, amount), "AetherMind: Token transfer failed");
        emit TokensUnstaked(msg.sender, amount);
    }

    /**
     * @dev Returns the total amount of governance tokens currently staked by a user.
     * @param user The address of the user.
     * @return The amount of tokens staked.
     */
    function getAvailableStake(address user) external view returns (uint256) {
        return totalStakedByParticipant[user];
    }

    // --- II. Adaptive Reputation System ---

    /**
     * @dev Returns the current reputation score for a specific user.
     * @param user The address of the user.
     * @return The user's reputation score.
     */
    function getUserReputation(address user) external view returns (uint256) {
        return userReputation[user];
    }

    /**
     * @dev Internal function to update a user's reputation.
     * @param user The address whose reputation to update.
     * @param change The amount to change reputation by (can be negative).
     */
    function _updateReputation(address user, int256 change) internal {
        uint256 currentRep = userReputation[user];
        if (change > 0) {
            userReputation[user] = currentRep.add(uint256(change));
        } else {
            userReputation[user] = currentRep.sub(uint256(change * -1));
        }
        emit ReputationUpdated(user, userReputation[user]);
    }

    /**
     * @dev Applies reputation decay to all participants. Can be called by anyone,
     *      but only processes if the decay interval has passed.
     */
    function decayReputation() external {
        require(block.timestamp >= lastReputationDecayTimestamp.add(reputationDecayInterval), "AetherMind: Decay interval not passed");

        for (uint256 i = 0; i < allEventIds.length; i++) {
            bytes32 eventId = allEventIds[i];
            PredictionEvent storage _event = events[eventId];
            for (uint256 j = 0; j < _event.participants.length; j++) {
                address participant = _event.participants[j];
                if (userReputation[participant] > INITIAL_REPUTATION) { // Only decay above initial reputation
                    uint256 decayAmount = userReputation[participant].mul(reputationDecayRate).div(100);
                    userReputation[participant] = userReputation[participant].sub(decayAmount);
                    emit ReputationUpdated(participant, userReputation[participant]);
                }
            }
        }
        lastReputationDecayTimestamp = block.timestamp;
    }

    /**
     * @dev Returns the current global reputation decay rate as a percentage.
     * @return The reputation decay rate.
     */
    function getReputationDecayRate() external view returns (uint256) {
        return reputationDecayRate;
    }

    // --- III. Prediction Event Lifecycle ---

    /**
     * @dev Allows a qualified user to propose a new event for prediction.
     *      Event must then be approved to become active.
     * @param description A descriptive string for the event.
     * @param endTime The timestamp when the prediction period ends.
     * @param externalId An optional external identifier for the event.
     */
    function proposeEvent(string calldata description, uint256 endTime, bytes32 externalId) external {
        require(userReputation[msg.sender] >= minReputationToProposeEvent, "AetherMind: Not enough reputation to propose events");
        require(bytes(description).length > 0, "AetherMind: Event description cannot be empty");
        require(endTime > block.timestamp.add(1 days), "AetherMind: Prediction end time must be at least 1 day in future");

        bytes32 eventId = keccak256(abi.encodePacked(msg.sender, description, endTime, externalId, block.timestamp));
        require(!events[eventId].exists, "AetherMind: Event already proposed or ID collision");

        events[eventId] = PredictionEvent({
            description: description,
            creationTime: block.timestamp,
            predictionEndTime: endTime,
            resolutionTime: 0,
            actualResult: 0,
            isResolved: false,
            isChallenged: false,
            proposer: msg.sender,
            externalId: externalId,
            totalStaked: 0,
            totalCorrectStake: 0,
            oracleRef: bytes32(0),
            challenger: address(0),
            challengeStartTimestamp: 0,
            exists: true,
            participants: new address[](0) // Initialize empty
        });

        allEventIds.push(eventId); // Track all events
        emit EventProposed(eventId, msg.sender, endTime, externalId);
    }

    /**
     * @dev Allows a high-reputation user or the DAO to approve a proposed event.
     *      Approved events become active for predictions.
     * @param eventId The ID of the event to approve.
     */
    function approveProposedEvent(bytes32 eventId) external {
        PredictionEvent storage _event = events[eventId];
        require(_event.exists, "AetherMind: Event does not exist");
        require(_event.creationTime > 0, "AetherMind: Event not yet proposed"); // Ensure it's not a default struct
        require(_event.predictionEndTime > block.timestamp, "AetherMind: Event prediction time already passed");
        require(userReputation[msg.sender] >= minReputationToApproveEvent, "AetherMind: Not enough reputation to approve events");
        // Check if event is already approved, by checking if it's already added to activeEvents conceptually.
        // For now, let's assume if it exists and creationTime is set, it's 'approved' for prediction.
        // A more complex system might have a separate `isActive` flag.
        // For this example, creation means proposed, approval means it's ready for predictions.

        // This function would primarily be for an actual approval step, e.g., via a DAO vote
        // or a group of highly reputable users. For simplicity, if it's created and not past endTime,
        // it's considered "active for prediction".
        // This function will just make sure that it's actually proposed by someone with sufficient reputation
        // before it can proceed to get predictions.

        // If an event is proposed, it implicitly becomes active for predictions.
        // The 'approval' step would typically be a DAO function or a multi-sig.
        // I'll make this function idempotent.
        if (_event.creationTime > 0) { // If it exists, it's considered approved in this simplified flow
            emit EventApproved(eventId, msg.sender);
        }
    }


    /**
     * @dev Allows users to submit their prediction for an active event with a staked amount.
     * @param eventId The ID of the event.
     * @param predictionValue The user's predicted outcome for the event.
     * @param stakeAmount The amount of tokens to stake on this prediction.
     */
    function submitPrediction(bytes32 eventId, uint256 predictionValue, uint256 stakeAmount) external {
        PredictionEvent storage _event = events[eventId];
        require(_event.exists, "AetherMind: Event does not exist");
        require(_event.predictionEndTime > block.timestamp, "AetherMind: Prediction period has ended");
        require(stakeAmount >= minStakeForPrediction && stakeAmount <= maxStakeForPrediction, "AetherMind: Stake amount out of bounds");
        require(totalStakedByParticipant[msg.sender] >= stakeAmount, "AetherMind: Insufficient staked tokens");
        require(!_event.predictions[msg.sender].exists, "AetherMind: Already submitted a prediction for this event");

        _event.predictions[msg.sender] = UserPrediction({
            value: predictionValue,
            stake: stakeAmount,
            claimed: false,
            exists: true
        });

        _event.participants.push(msg.sender);
        _event.totalStaked = _event.totalStaked.add(stakeAmount);
        totalPredictionsMade[msg.sender] = totalPredictionsMade[msg.sender].add(1);

        // Deduct from available staked balance (conceptually, tokens are locked within contract for this prediction)
        totalStakedByParticipant[msg.sender] = totalStakedByParticipant[msg.sender].sub(stakeAmount);

        emit PredictionSubmitted(eventId, msg.sender, predictionValue, stakeAmount);
    }

    /**
     * @dev Allows a user to cancel their prediction for an event before the prediction end time.
     *      A portion of the stake might be refunded, with a fee for early exit (not implemented for simplicity).
     * @param eventId The ID of the event.
     */
    function cancelPrediction(bytes32 eventId) external {
        PredictionEvent storage _event = events[eventId];
        require(_event.exists, "AetherMind: Event does not exist");
        require(_event.predictionEndTime > block.timestamp, "AetherMind: Prediction period has ended");
        UserPrediction storage userPred = _event.predictions[msg.sender];
        require(userPred.exists, "AetherMind: No prediction found for this user/event");

        uint256 refundedStake = userPred.stake; // Could apply a cancellation fee here
        _event.totalStaked = _event.totalStaked.sub(refundedStake);
        totalStakedByParticipant[msg.sender] = totalStakedByParticipant[msg.sender].add(refundedStake);

        // Remove from participants list - inefficient for large arrays, but simple for example
        for (uint256 i = 0; i < _event.participants.length; i++) {
            if (_event.participants[i] == msg.sender) {
                _event.participants[i] = _event.participants[_event.participants.length - 1];
                _event.participants.pop();
                break;
            }
        }

        delete _event.predictions[msg.sender]; // Clear the prediction
        totalPredictionsMade[msg.sender] = totalPredictionsMade[msg.sender].sub(1); // Decrement count
        emit PredictionCancelled(eventId, msg.sender, refundedStake);
    }

    /**
     * @dev Retrieves detailed information about a specific event.
     * @param eventId The ID of the event.
     * @return description, creationTime, predictionEndTime, resolutionTime, actualResult,
     *         isResolved, isChallenged, proposer, externalId, totalStaked, totalCorrectStake,
     *         oracleRef, challenger, challengeStartTimestamp, exists.
     */
    function getEventDetails(bytes32 eventId)
        external
        view
        returns (
            string memory description,
            uint256 creationTime,
            uint256 predictionEndTime,
            uint256 resolutionTime,
            uint256 actualResult,
            bool isResolved,
            bool isChallenged,
            address proposer,
            bytes32 externalId,
            uint256 totalStaked,
            uint256 totalCorrectStake,
            bytes32 oracleRef,
            address challenger,
            uint256 challengeStartTimestamp,
            bool exists
        )
    {
        PredictionEvent storage _event = events[eventId];
        return (
            _event.description,
            _event.creationTime,
            _event.predictionEndTime,
            _event.resolutionTime,
            _event.actualResult,
            _event.isResolved,
            _event.isChallenged,
            _event.proposer,
            _event.externalId,
            _event.totalStaked,
            _event.totalCorrectStake,
            _event.oracleRef,
            _event.challenger,
            _event.challengeStartTimestamp,
            _event.exists
        );
    }

    /**
     * @dev Fetches a specific user's prediction details for an event.
     * @param eventId The ID of the event.
     * @param user The address of the user.
     * @return value, stake, claimed, exists.
     */
    function getUserPredictionForEvent(bytes32 eventId, address user)
        external
        view
        returns (
            uint256 value,
            uint256 stake,
            bool claimed,
            bool exists
        )
    {
        UserPrediction storage userPred = events[eventId].predictions[user];
        return (userPred.value, userPred.stake, userPred.claimed, userPred.exists);
    }

    // --- IV. Event Resolution & Rewards ---

    /**
     * @dev Allows an authorized oracle to submit the result for an event after its prediction end time.
     * @param eventId The ID of the event.
     * @param result The actual outcome of the event.
     * @param oracleRef A reference string/ID for the oracle's submission proof.
     */
    function submitOracleResult(bytes32 eventId, uint256 result, bytes32 oracleRef) external onlyAuthorizedOracle {
        PredictionEvent storage _event = events[eventId];
        require(_event.exists, "AetherMind: Event does not exist");
        require(!_event.isResolved, "AetherMind: Event is already resolved");
        require(_event.predictionEndTime < block.timestamp, "AetherMind: Prediction period not yet ended");
        require(_event.oracleRef == bytes32(0), "AetherMind: Oracle result already submitted"); // Prevent re-submission

        _event.actualResult = result;
        _event.oracleRef = oracleRef;
        emit OracleResultSubmitted(eventId, oracleRef, result);
    }

    /**
     * @dev Allows a high-reputation user to challenge an oracle result within a challenge period.
     *      Requires staking a `challengeStake` amount.
     * @param eventId The ID of the event.
     * @param oracleRef The oracle reference of the result being challenged.
     * @param reason A string explaining the reason for the challenge.
     */
    function challengeOracleResult(bytes32 eventId, bytes32 oracleRef, string calldata reason) external {
        PredictionEvent storage _event = events[eventId];
        require(_event.exists, "AetherMind: Event does not exist");
        require(!_event.isResolved, "AetherMind: Event is already resolved");
        require(_event.oracleRef == oracleRef, "AetherMind: Oracle reference mismatch");
        require(!_event.isChallenged, "AetherMind: Oracle result already challenged");
        require(userReputation[msg.sender] >= minReputationToProposeEvent, "AetherMind: Not enough reputation to challenge"); // Re-using this constant
        require(totalStakedByParticipant[msg.sender] >= challengeStake, "AetherMind: Insufficient staked tokens for challenge");
        require(block.timestamp <= _event.predictionEndTime.add(challengePeriod), "AetherMind: Challenge period has ended");

        _event.isChallenged = true;
        _event.challenger = msg.sender;
        _event.challengeStartTimestamp = uint224(block.timestamp);

        // Lock challenge stake
        totalStakedByParticipant[msg.sender] = totalStakedByParticipant[msg.sender].sub(challengeStake);
        // This challenge stake will be managed (slashed/returned) by a further DAO vote or arbitration process,
        // which is beyond the scope of this contract but indicated by isChallenged flag.
        emit OracleResultChallenged(eventId, msg.sender, challengeStake);
    }

    /**
     * @dev Finalizes an event, distributing rewards and updating reputations.
     *      Can only be called after prediction end time and a result (or challenge resolution) is present.
     * @param eventId The ID of the event to resolve.
     */
    function resolveEvent(bytes32 eventId) external {
        PredictionEvent storage _event = events[eventId];
        require(_event.exists, "AetherMind: Event does not exist");
        require(!_event.isResolved, "AetherMind: Event is already resolved");
        require(_event.predictionEndTime < block.timestamp, "AetherMind: Prediction period not yet ended");
        require(_event.oracleRef != bytes32(0), "AetherMind: Oracle result not submitted");

        if (_event.isChallenged) {
            // Placeholder for challenge resolution. In a real system, this would involve
            // DAO voting or an arbitration mechanism to determine the actual result.
            // For this example, we'll assume the challenge is resolved and actualResult is final.
            require(block.timestamp > _event.challengeStartTimestamp.add(challengePeriod), "AetherMind: Challenge period active");
            // If challenger was wrong, slash their stake (or distribute to oracles/winners).
            // If challenger was right, revert oracle and return stake.
            // This is complex and needs separate DAO/Arbitration logic.
            // For this example, we proceed with actualResult after challengePeriod as if dispute resolved.
            // Assume the challenge did not change the result if it wasn't handled by specific logic.
        }

        uint256 totalIncorrectStake = 0;
        uint256 totalWinners = 0;

        // First pass: Calculate total correct stake and identify winners
        for (uint256 i = 0; i < _event.participants.length; i++) {
            address participant = _event.participants[i];
            UserPrediction storage userPred = _event.predictions[participant];
            if (userPred.exists) {
                if (userPred.value == _event.actualResult) {
                    _event.totalCorrectStake = _event.totalCorrectStake.add(userPred.stake);
                    totalWinners++;
                } else {
                    totalIncorrectStake = totalIncorrectStake.add(userPred.stake);
                }
            }
        }

        // Calculate protocol fees from incorrect stakes
        uint256 fees = totalIncorrectStake.mul(protocolFeePercentage).div(100);
        totalProtocolFees = totalProtocolFees.add(fees);
        uint252 rewardsPool = uint252(totalIncorrectStake.sub(fees)); // Remaining for winners

        // Second pass: Distribute rewards and update reputation
        for (uint256 i = 0; i < _event.participants.length; i++) {
            address participant = _event.participants[i];
            UserPrediction storage userPred = _event.predictions[participant];
            if (userPred.exists) {
                if (userPred.value == _event.actualResult) {
                    // Reward calculation: proportional to stake in the correct pool
                    uint252 reward = 0;
                    if (_event.totalCorrectStake > 0) {
                        reward = uint252(userPred.stake.mul(rewardsPool).div(_event.totalCorrectStake));
                    }
                    totalRewardsEarned[participant] = totalRewardsEarned[participant].add(reward); // Accumulate rewards
                    correctPredictions[participant] = correctPredictions[participant].add(1);
                    // Reputation gain
                    _updateReputation(participant, int256(userPred.stake.mul(reputationGainMultiplier).div(1000)));
                } else {
                    // Reputation loss for incorrect prediction
                    _updateReputation(participant, -int256(userPred.stake.mul(reputationLossMultiplier).div(1000)));
                }
            }
        }

        _event.isResolved = true;
        _event.resolutionTime = block.timestamp;
        emit EventResolved(eventId, _event.actualResult, totalWinners, rewardsPool);
    }

    /**
     * @dev Allows users to claim their earned rewards and have their stake returned after an event is resolved.
     * @param eventId The ID of the event.
     */
    function claimPredictionRewards(bytes32 eventId) external {
        PredictionEvent storage _event = events[eventId];
        require(_event.exists, "AetherMind: Event does not exist");
        require(_event.isResolved, "AetherMind: Event not yet resolved");
        UserPrediction storage userPred = _event.predictions[msg.sender];
        require(userPred.exists, "AetherMind: No prediction found for this user/event");
        require(!userPred.claimed, "AetherMind: Rewards already claimed");

        uint252 payoutAmount = userPred.stake; // Return original stake
        if (userPred.value == _event.actualResult) {
            // Add earned reward
            uint252 rewardsPool = uint252(events[eventId].totalStaked.sub(events[eventId].totalStaked.mul(protocolFeePercentage).div(100))); // Simplified pool calculation
            if (_event.totalCorrectStake > 0) {
                 payoutAmount = payoutAmount.add(uint252(userPred.stake.mul(rewardsPool).div(_event.totalCorrectStake)));
            }
        } else {
            // For incorrect predictions, stake is not returned as it went to winners/fees.
            // This is simplified slashing. More complex would be partial return.
            payoutAmount = 0;
        }

        userPred.claimed = true;
        if (payoutAmount > 0) {
            require(governanceToken.transfer(msg.sender, payoutAmount), "AetherMind: Reward transfer failed");
            emit RewardsClaimed(eventId, msg.sender, payoutAmount);
        }
    }


    // --- V. Decentralized Autonomous Organization (DAO) & Adaptive Parameters ---

    /**
     * @dev Allows users with sufficient reputation to propose a change to a system parameter.
     * @param description A description of the proposed change.
     * @param paramName The name of the parameter to change (e.g., "reputationDecayRate").
     * @param newValue The new value for the parameter.
     */
    function proposeParameterChange(string calldata description, bytes32 paramName, uint256 newValue) external {
        require(userReputation[msg.sender] >= minReputationToPropose, "AetherMind: Not enough reputation to propose");
        bytes32 proposalId = keccak256(abi.encodePacked(msg.sender, description, paramName, newValue, block.timestamp));
        require(!proposals[proposalId].exists, "AetherMind: Proposal already exists or ID collision");

        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            description: description,
            paramName: paramName,
            newValue: newValue,
            creationTime: block.timestamp,
            votingEndTime: block.timestamp.add(proposalVotingPeriod),
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            executed: false,
            exists: true
        });
        activeProposals.push(proposalId);
        emit ProposalCreated(proposalId, msg.sender, paramName, newValue);
    }

    /**
     * @dev Allows users to cast their reputation-weighted vote on an active proposal.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for a 'for' vote, false for an 'against' vote.
     */
    function voteOnProposal(bytes32 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.exists, "AetherMind: Proposal does not exist");
        require(!proposal.executed, "AetherMind: Proposal already executed");
        require(block.timestamp <= proposal.votingEndTime, "AetherMind: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "AetherMind: User already voted on this proposal");
        require(userReputation[msg.sender] >= minReputationForVoteWeight, "AetherMind: Not enough reputation to vote");

        uint256 voteWeight = userReputation[msg.sender];
        if (support) {
            proposal.totalVotesFor = proposal.totalVotesFor.add(voteWeight);
        } else {
            proposal.totalVotesAgainst = proposal.totalVotesAgainst.add(voteWeight);
        }
        proposal.hasVoted[msg.sender] = true;
        emit VoteCast(proposalId, msg.sender, support, voteWeight);
    }

    /**
     * @dev Executes a proposal if it has passed its voting period and met the approval threshold.
     *      Only the owner (or eventually DAO) can execute proposals.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(bytes32 proposalId) external onlyOwner { // Changed to onlyOwner for demo simplicity, ideally DAO-only
        Proposal storage proposal = proposals[proposalId];
        require(proposal.exists, "AetherMind: Proposal does not exist");
        require(!proposal.executed, "AetherMind: Proposal already executed");
        require(block.timestamp > proposal.votingEndTime, "AetherMind: Voting period not ended");

        uint256 totalVotes = proposal.totalVotesFor.add(proposal.totalVotesAgainst);
        require(totalVotes > 0, "AetherMind: No votes cast on this proposal");

        uint256 approvalPercentage = proposal.totalVotesFor.mul(100).div(totalVotes);
        require(approvalPercentage >= proposalExecutionThreshold, "AetherMind: Proposal did not meet approval threshold");

        // Apply the proposed parameter change
        if (proposal.paramName == keccak256(abi.encodePacked("reputationDecayRate"))) {
            reputationDecayRate = proposal.newValue;
        } else if (proposal.paramName == keccak256(abi.encodePacked("reputationGainMultiplier"))) {
            reputationGainMultiplier = proposal.newValue;
        } else if (proposal.paramName == keccak256(abi.encodePacked("reputationLossMultiplier"))) {
            reputationLossMultiplier = proposal.newValue;
        } else if (proposal.paramName == keccak256(abi.encodePacked("minStakeForPrediction"))) {
            minStakeForPrediction = proposal.newValue;
        } else if (proposal.paramName == keccak256(abi.encodePacked("protocolFeePercentage"))) {
            protocolFeePercentage = proposal.newValue;
        }
        // Add more parameter cases as needed

        proposal.executed = true;
        emit ProposalExecuted(proposalId, proposal.paramName, proposal.newValue);

        // Remove from activeProposals (inefficient for large arrays)
        for (uint256 i = 0; i < activeProposals.length; i++) {
            if (activeProposals[i] == proposalId) {
                activeProposals[i] = activeProposals[activeProposals.length - 1];
                activeProposals.pop();
                break;
            }
        }
    }

    // --- VI. Utility & Analytics ---

    /**
     * @dev Returns a paginated list of top reputation holders.
     *      Note: Direct on-chain iteration for leaderboards can be gas-intensive for large user bases.
     *      For a real-world scenario, this might be handled by an off-chain indexer or a separate contract.
     *      This implementation provides a basic example.
     * @param start The starting index for the leaderboard.
     * @param end The ending index for the leaderboard.
     * @return An array of addresses and their corresponding reputation scores.
     */
    function getReputationLeaderboard(uint256 start, uint256 end)
        external
        view
        returns (address[] memory users, uint256[] memory reputations)
    {
        // This is a placeholder. To get a true sorted leaderboard on-chain is very complex and gas-expensive.
        // A common approach is to use an off-chain indexer for this.
        // For demonstration, we'll return a subset of all known addresses (from events) and their reputation.
        // This will NOT be sorted. A real leaderboard would require a data structure like a sorted list or tree.

        uint256 count = 0;
        address[] memory tempUsers = new address[](allEventIds.length); // Max possible unique users
        mapping(address => bool) seenUsers;

        for (uint224 i = 0; i < allEventIds.length; i++) {
            bytes32 eventId = allEventIds[i];
            PredictionEvent storage _event = events[eventId];
            for (uint254 j = 0; j < _event.participants.length; j++) {
                address participant = _event.participants[j];
                if (!seenUsers[participant]) {
                    tempUsers[count] = participant;
                    seenUsers[participant] = true;
                    count++;
                }
            }
        }

        // Now filter by start and end for the return, but still unsorted.
        uint256 actualEnd = end > count ? count : end;
        uint256 actualStart = start > actualEnd ? actualEnd : start;
        uint256 resultSize = actualEnd.sub(actualStart);

        users = new address[](resultSize);
        reputations = new uint256[](resultSize);

        for (uint256 i = 0; i < resultSize; i++) {
            users[i] = tempUsers[actualStart.add(i)];
            reputations[i] = userReputation[users[i]];
        }
        return (users, reputations);
    }

    /**
     * @dev Calculates and returns a user's overall prediction accuracy.
     * @param user The address of the user.
     * @return The accuracy as a percentage (e.g., 85 for 85%).
     */
    function getPredictionAccuracy(address user) external view returns (uint256) {
        if (totalPredictionsMade[user] == 0) {
            return 0;
        }
        return correctPredictions[user].mul(100).div(totalPredictionsMade[user]);
    }

    /**
     * @dev Allows the DAO (owner in this simplified demo) to withdraw accumulated protocol fees.
     * @param to The address to send the fees to.
     */
    function withdrawFees(address to) external onlyOwner { // Changed to onlyOwner for demo simplicity, ideally DAO-only
        require(to != address(0), "AetherMind: Target address cannot be zero");
        require(totalProtocolFees > 0, "AetherMind: No fees to withdraw");
        uint256 amount = totalProtocolFees;
        totalProtocolFees = 0; // Reset fees

        require(governanceToken.transfer(to, amount), "AetherMind: Fee transfer failed");
        emit FeesWithdrawn(to, amount);
    }

    /**
     * @dev Allows the owner to add authorized oracles.
     * @param oracleAddress The address of the oracle to add.
     */
    function addAuthorizedOracle(address oracleAddress) external onlyOwner {
        require(oracleAddress != address(0), "AetherMind: Oracle address cannot be zero");
        bool exists = false;
        for (uint256 i = 0; i < authorizedOracles.length; i++) {
            if (authorizedOracles[i] == oracleAddress) {
                exists = true;
                break;
            }
        }
        require(!exists, "AetherMind: Oracle already authorized");
        authorizedOracles.push(oracleAddress);
    }

    /**
     * @dev Allows the owner to remove authorized oracles.
     * @param oracleAddress The address of the oracle to remove.
     */
    function removeAuthorizedOracle(address oracleAddress) external onlyOwner {
        require(oracleAddress != address(0), "AetherMind: Oracle address cannot be zero");
        for (uint256 i = 0; i < authorizedOracles.length; i++) {
            if (authorizedOracles[i] == oracleAddress) {
                authorizedOracles[i] = authorizedOracles[authorizedOracles.length - 1];
                authorizedOracles.pop();
                return;
            }
        }
        revert("AetherMind: Oracle not found");
    }
}
```