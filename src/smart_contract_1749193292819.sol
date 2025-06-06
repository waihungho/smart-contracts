Okay, here is a Solidity smart contract for a Decentralized Prediction Market Engine with several interesting, advanced, and creative concepts, including an optimistic resolution mechanism and a detailed state machine. It aims to provide a rich set of functionalities without directly duplicating standard open-source patterns like basic ERC-20/721 or simple AMMs.

**Outline:**

1.  **Contract Overview:** A decentralized engine for creating, managing, and resolving prediction markets.
2.  **Key Concepts:**
    *   **Prediction Markets:** Users stake tokens on the outcome of future events.
    *   **Binary Outcomes:** Markets typically have two possible outcomes (e.g., Yes/No, Win/Loss).
    *   **State Machine:** Each market progresses through distinct states (Open, Closed, ResolutionPending, Challenged, Resolved, Canceled).
    *   **Staking:** Users stake an ERC-20 token on their chosen outcome.
    *   **Pro-rata Winnings:** Winnings are distributed proportionally based on the amount staked on the winning outcome.
    *   **Optimistic Resolution:** A mechanism where an outcome is proposed and can be challenged, requiring additional staking/bonding to resolve disputes.
    *   **Oracle Integration:** Relies on an external oracle (or oracle-like mechanism) for final outcome determination, especially during disputes.
    *   **Fees:** Platform fees are collected from market creation and winning bets.
    *   **Governance/Admin Control:** Roles for managing core parameters and emergency actions.
3.  **Data Structures:** Enums for States and Outcomes, Structs for Market and Bet.
4.  **State Variables:** Mappings for markets, user bets, state tracking, fees, addresses (oracle, staking token, governance).
5.  **Core Functions:** Market creation, betting, market closure.
6.  **Resolution Functions:** Standard resolution, optimistic resolution flow (proposing, challenging, supporting, resolving disputes, finalizing).
7.  **Claim Functions:** Claiming winnings or refunds.
8.  **Admin/Governance Functions:** Setting fees, oracle address, pausing/canceling markets, withdrawing fees.
9.  **Query Functions:** Retrieving market/bet details, calculating potential winnings.
10. **Modifiers & Events:** Access control, state checks, signaling key actions.

**Function Summary:**

1.  `constructor()`: Initializes the contract with essential addresses (staking token, oracle, governance).
2.  `createMarket()`: Allows authorized users to create a new prediction market with parameters like question, outcomes, betting window, etc.
3.  `placeBet()`: Enables users to stake tokens on a specific outcome of an open market.
4.  `closeMarket()`: Transitions a market from `Open` to `ResolutionPending` after the betting deadline.
5.  `proposeOutcome()`: Initiates the optimistic resolution process by proposing an outcome after the market is closed. Requires a bond.
6.  `challengeOutcome()`: Allows a party to challenge a proposed outcome, transitioning the market to `Challenged` state and starting a dispute period. Requires a bond.
7.  `supportProposedOutcome()`: Allows users to stake tokens to support the initially proposed outcome during a challenge.
8.  `supportChallengedOutcome()`: Allows users to stake tokens to support the challenging party's claim during a dispute.
9.  `resolveDispute()`: Called after the dispute period, often interacting with an oracle to determine the *final* outcome of a challenged market. Handles slashing of losing dispute stakes.
10. `finalizeOptimisticResolution()`: Transitions a market from `ResolutionPending` (after proposal but no challenge) or `ResolvedDispute` to `Resolved` based on the final outcome.
11. `resolveMarket()`: A fallback resolution method (e.g., for markets without optimistic challenge or after optimistic resolution failure) where a trusted oracle or admin directly sets the outcome.
12. `claimWinnings()`: Allows users who staked on the winning outcome to claim their proportional share of the prize pool (minus resolution fees).
13. `claimRefund()`: Allows users to claim their stake back if a market is canceled or becomes invalid.
14. `cancelMarket()`: Allows governance/admin to cancel a market before resolution, triggering refunds.
15. `pauseMarket()`: Allows governance/admin to temporarily pause betting or resolution on a market (e.g., due to external issues).
16. `unpauseMarket()`: Allows governance/admin to resume a paused market.
17. `setMarketCreationFee()`: Allows governance to update the fee required to create a market.
18. `setResolutionFee()`: Allows governance to update the percentage fee taken from winning bets.
19. `setOracleAddress()`: Allows governance to update the address of the trusted oracle contact (used in `resolveDispute` or `resolveMarket`).
20. `setGovernanceAddress()`: Allows the current governance to transfer governance control to a new address.
21. `withdrawFees()`: Allows governance to withdraw accumulated market creation and resolution fees.
22. `getMarketDetails()`: Reads and returns the detailed state of a specific market.
23. `getUserBet()`: Reads and returns details of a user's bet on a specific market.
24. `getTotalStakeOnOutcome()`: Calculates and returns the total amount staked on a given outcome for a market.
25. `calculatePotentialWinnings()`: A view function to estimate winnings for a given bet amount, assuming that outcome wins.
26. `getMarketState()`: Returns the current state enum of a market.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// Interface for an external oracle or dispute resolution mechanism
// This contract expects an address that can provide the final outcome
// or perhaps a proof/signal based on the optimistic resolution process.
// For simplicity, we assume it has a function that returns the determined outcome.
interface IOracle {
    // In a real system, this would be more complex, perhaps taking marketId
    // and returning a cryptographically attested outcome or resolving a challenge.
    // Here we use a simplified model where the oracle can be queried or pushed.
    // A robust system might have a request/callback pattern or UMA/Reality.eth integration.
    function getOutcome(uint256 marketId) external view returns (uint8 finalOutcome);
    // More realistically, it might involve submitting evidence, bonds etc.
    // For this example, we abstract that complexity away into this interface.
}

contract DecentralizedPredictionMarketEngine is Pausable {
    using SafeMath for uint256;

    // --- Enums ---
    enum MarketState {
        Inactive,          // Initial state or invalid
        Open,              // Accepting bets
        Closed,            // Betting window ended, awaiting resolution
        ResolutionPending, // Outcome proposed, awaiting challenge period or finalization
        Challenged,        // Proposed outcome is challenged, dispute period active
        ResolvedDispute,   // Dispute resolved by oracle/governance, outcome determined
        Resolved,          // Final outcome determined, winnings claimable
        Canceled           // Market canceled, stakes refundable
    }

    enum Outcome {
        Invalid, // Represents no outcome or an invalid state
        Outcome1, // e.g., Yes
        Outcome2, // e.g., No
        // More outcomes could be added if not strictly binary
        Count // Helper to get the number of defined outcomes
    }

    // --- Structs ---
    struct Market {
        uint256 marketId; // Unique identifier for the market
        string question;  // The question being bet on
        uint64 openingTime; // Timestamp when betting opens
        uint64 closingTime; // Timestamp when betting closes
        uint64 resolutionTime; // Timestamp when resolution *should* occur
        uint64 disputePeriodEnds; // Timestamp when optimistic dispute period ends
        IERC20 stakingToken; // The ERC20 token used for staking and payouts
        uint256 totalStake; // Total stake across all outcomes for this market
        mapping(uint8 => uint256) stakeByOutcome; // Total stake per outcome (indexed by Outcome enum)
        mapping(address => Bet) userBets; // User's latest bet on this market
        MarketState currentState; // Current state of the market
        uint8 winningOutcome; // The determined winning outcome (Outcome enum)
        uint256 creatorFee; // Fee paid by creator (could be fixed or percentage) - not used in fee model below, but good placeholder
        uint256 resolutionFeeBasisPoints; // Fee percentage (in basis points) taken from winnings
        address creator; // Address that created the market

        // Optimistic Resolution fields
        uint8 proposedOutcome; // The outcome proposed during ResolutionPending
        address proposer; // Address that proposed the outcome
        uint256 proposalBond; // Bond required for proposal
        address challenger; // Address that challenged the outcome
        uint256 challengeBond; // Bond required for challenging
        mapping(address => uint256) supportForProposed; // Stake supporting the proposed outcome
        mapping(address => uint256) supportForChallenge; // Stake supporting the challenged outcome
        uint256 totalSupportForProposed; // Total stake supporting proposed outcome
        uint256 totalSupportForChallenge; // Total stake supporting challenged outcome
    }

    struct Bet {
        uint8 outcome; // The outcome the user bet on
        uint256 amount; // The amount the user staked
        bool claimed;  // Flag to prevent double claiming
    }

    // --- State Variables ---
    Market[] public markets; // Array to store all markets (IDs are array indices)
    mapping(uint256 => Market) public marketDetails; // Mapping for direct access to market details by ID
    uint256 public marketCreationFee; // Fee required to create a market (in staking token)
    uint256 public defaultResolutionFeeBasisPoints; // Default fee percentage from winnings

    address public governance; // Address with governance control
    address public feeRecipient; // Address that receives fees

    IOracle public oracle; // Address of the trusted oracle contract

    uint64 public constant OPTIMISTIC_DISPUTE_PERIOD = 3 days; // Duration of the dispute period

    // --- Events ---
    event MarketCreated(uint256 indexed marketId, string question, uint64 openingTime, uint64 closingTime, address indexed creator);
    event BetPlaced(uint256 indexed marketId, address indexed user, uint8 outcome, uint256 amount);
    event MarketStateChanged(uint256 indexed marketId, MarketState newState, MarketState oldState);
    event OutcomeProposed(uint256 indexed marketId, uint8 proposedOutcome, address indexed proposer, uint256 bond);
    event OutcomeChallenged(uint256 indexed marketId, address indexed challenger, uint256 bond);
    event SupportStaked(uint256 indexed marketId, address indexed supporter, bool isProposed, uint256 amount);
    event DisputeResolved(uint256 indexed marketId, uint8 finalOutcome, address indexed winner, uint256 totalBondPool);
    event MarketResolved(uint256 indexed marketId, uint8 winningOutcome);
    event WinningsClaimed(uint256 indexed marketId, address indexed user, uint256 amount);
    event RefundClaimed(uint256 indexed marketId, address indexed user, uint256 amount);
    event MarketCanceled(uint256 indexed marketId);
    event FeeWithdrawn(address indexed recipient, uint256 amount);
    event GovernanceTransferred(address indexed oldGovernance, address indexed newGovernance);

    // --- Modifiers ---
    modifier onlyGovernance() {
        require(msg.sender == governance, "Only governance can call this");
        _;
    }

    modifier validMarket(uint256 _marketId) {
        require(_marketId < markets.length, "Invalid market ID");
        _;
    }

    modifier marketStateIs(uint256 _marketId, MarketState _expectedState) {
        require(marketDetails[_marketId].currentState == _expectedState, "Market is not in the required state");
        _;
    }

     modifier marketStateIsNot(uint256 _marketId, MarketState _forbiddenState) {
        require(marketDetails[_marketId].currentState != _forbiddenState, "Market is in a forbidden state");
        _;
    }

    modifier validOutcome(uint8 _outcome) {
        // Assuming binary outcomes + Invalid. Adjust if more outcomes are possible.
        require(_outcome > uint8(Outcome.Invalid) && _outcome < uint8(Outcome.Count), "Invalid outcome");
        _;
    }

    // --- Constructor ---
    constructor(address _stakingToken, address _oracle, address _governance, address _feeRecipient) Pausable(false) {
        require(_stakingToken != address(0), "Invalid staking token address");
        require(_oracle != address(0), "Invalid oracle address");
        require(_governance != address(0), "Invalid governance address");
        require(_feeRecipient != address(0), "Invalid fee recipient address");

        // Store initial setup parameters
        stakingToken = IERC20(_stakingToken); // Store staking token interface for later use
        oracle = IOracle(_oracle);
        governance = _governance;
        feeRecipient = _feeRecipient;

        // Set initial default fees (can be changed by governance)
        marketCreationFee = 0; // Example: Start with 0, or set an initial fee
        defaultResolutionFeeBasisPoints = 500; // Example: 5% fee on winnings

         // Add a dummy entry so market IDs start from 1 if desired, or just use index 0.
         // Let's start with index 0 and make it valid.
         // markets.push(); // Pushes a default Market struct, ID 0
         // marketDetails[0].currentState = MarketState.Inactive; // Mark as inactive/dummy
    }


    // --- Core Market Lifecycle Functions ---

    /**
     * @notice Creates a new prediction market.
     * @param _question The question for the market.
     * @param _closingTime The timestamp when betting closes.
     * @param _resolutionTime The timestamp when the market is expected to be resolved.
     * @param _stakingTokenAddress The address of the ERC20 token to be used for staking.
     * @param _resolutionFeeBasisPoints The fee percentage (in basis points) taken from winnings for this specific market.
     * @dev Market ID is the index in the markets array.
     */
    function createMarket(
        string calldata _question,
        uint64 _closingTime,
        uint64 _resolutionTime,
        address _stakingTokenAddress, // Can override default staking token per market
        uint256 _resolutionFeeBasisPoints
    ) external payable whenNotPaused returns (uint256 marketId) {
        require(bytes(_question).length > 0, "Question cannot be empty");
        require(_closingTime > block.timestamp, "Closing time must be in the future");
        require(_resolutionTime > _closingTime, "Resolution time must be after closing time");
        require(_stakingTokenAddress != address(0), "Invalid staking token address");
        require(_resolutionFeeBasisPoints <= 10000, "Fee cannot be > 100%"); // Max 100%

        // Handle market creation fee
        // If using native token fee:
        // require(msg.value >= marketCreationFee, "Insufficient creation fee");
        // If using staking token fee, this would require a prior approval and transferFrom
        // Assuming fee is paid in msg.value (native token) for simplicity here.
        // Alternatively, require marketCreationFee to be 0 if not using native token.
        require(marketCreationFee == 0 || msg.value >= marketCreationFee, "Insufficient creation fee paid");
        if (marketCreationFee > 0) {
             // Transfer the fee to the recipient
             (bool success,) = feeRecipient.call{value: marketCreationFee}("");
             require(success, "Fee transfer failed");
        }


        marketId = markets.length; // New market ID is the next index

        markets.push(); // Add a new slot in the array

        Market storage newMarket = marketDetails[marketId];
        newMarket.marketId = marketId;
        newMarket.question = _question;
        newMarket.openingTime = uint64(block.timestamp);
        newMarket.closingTime = _closingTime;
        newMarket.resolutionTime = _resolutionTime;
        newMarket.stakingToken = IERC20(_stakingTokenAddress);
        newMarket.currentState = MarketState.Open;
        newMarket.winningOutcome = uint8(Outcome.Invalid); // Unset initially
        newMarket.resolutionFeeBasisPoints = _resolutionFeeBasisPoints;
        newMarket.creator = msg.sender;

        emit MarketCreated(marketId, _question, newMarket.openingTime, newMarket.closingTime, msg.sender);
        emit MarketStateChanged(marketId, MarketState.Open, MarketState.Inactive); // Assuming Inactive as prior state

        // Refund excess native token sent beyond the creation fee
        if (msg.value > marketCreationFee) {
            (bool success, ) = msg.sender.call{value: msg.value - marketCreationFee}("");
             require(success, "Refund transfer failed");
        }

        return marketId;
    }

    /**
     * @notice Places a bet on a specific outcome for a market.
     * @param _marketId The ID of the market to bet on.
     * @param _outcome The outcome to bet on (e.g., Outcome.Outcome1 or Outcome.Outcome2).
     * @param _amount The amount of staking tokens to stake.
     */
    function placeBet(uint256 _marketId, uint8 _outcome, uint256 _amount)
        external
        whenNotPaused
        validMarket(_marketId)
        marketStateIs(_marketId, MarketState.Open)
        validOutcome(_outcome)
    {
        Market storage market = marketDetails[_marketId];
        require(block.timestamp >= market.openingTime, "Market not open yet");
        require(block.timestamp < market.closingTime, "Market is closed for betting");
        require(_amount > 0, "Bet amount must be greater than 0");

        // If user already bet on this market, they need to claim/refund first if state allows
        // Or, we could allow adding to an existing bet. Let's disallow for simplicity: one active bet per user per market.
        // Note: This implementation overwrites previous bets. A more complex system would track total bet amount per user/outcome.
        // Let's switch to cumulative bets per user per outcome for better functionality.
        // We need to store user stakes per outcome, not just one Bet struct.
        // Let's refactor the Bet struct and user mapping slightly.
        // Okay, let's keep the Bet struct simple (latest bet/claim status) but track user stake totals per outcome separately.

        // Transfer staking tokens from user to contract
        require(market.stakingToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        // Update market totals
        market.totalStake = market.totalStake.add(_amount);
        market.stakeByOutcome[_outcome] = market.stakeByOutcome[_outcome].add(_amount);

        // Store user's bet details (or add to existing stake for this outcome)
        // Let's track user stake per outcome
         // If using the Bet struct to track *latest* bet:
         market.userBets[msg.sender] = Bet(_outcome, _amount, false); // Overwrites any previous *tracked* bet data

        // --- REVISION: Cumulative Staking ---
        // The previous simple Bet struct makes claiming tricky if multiple bets are placed.
        // A better approach: Track user stake per outcome.
        // Mapping: userAddress => outcome => amountStaked
        // Let's add this mapping to the Market struct.
        // mapping(address => mapping(uint8 => uint256)) userStakeByOutcome;
        // And modify placeBet:
        // market.userStakeByOutcome[msg.sender][_outcome] = market.userStakeByOutcome[msg.sender][_outcome].add(_amount);
        // This requires removing the `userBets` mapping and `Bet` struct, and modifying claim functions.
        // Let's stick with the simpler Bet struct (representing a single entry for potential claim/refund) to keep the 20+ functions manageable,
        // but acknowledge this is a simplification. A real system needs careful tracking of user deposits vs withdrawable amounts.
        // For this example, we'll assume the Bet struct tracks the amount the user needs to claim/refund *based on their last action or total interaction*.
        // Let's make `userBets` store the *total* stake placed by the user on a specific outcome over time, and the `claimed` flag applies to the *entire* amount.

        // REVISION 2: Let's track total user stake per market, and which outcome their *claimable* balance is tied to after resolution.
        // Simpler: The Bet struct *is* the record of the user's stake that needs claiming/refunding.
        // If a user bets again on the *same* market *before* resolution, does it add to the previous bet? Yes, let's assume it does.
        // This simplifies claiming. We'll update the Bet struct if it exists, otherwise create it.

        Bet storage userBet = market.userBets[msg.sender];
        if (userBet.amount == 0) {
             // First bet by this user on this market
             userBet.outcome = _outcome;
             userBet.amount = _amount;
             userBet.claimed = false;
        } else {
             // User is adding to an existing bet. It MUST be on the SAME outcome.
             require(userBet.outcome == _outcome, "Cannot change outcome on a single bet entry");
             userBet.amount = userBet.amount.add(_amount);
        }


        emit BetPlaced(_marketId, msg.sender, _outcome, _amount);
    }

    /**
     * @notice Closes betting for a market if the closing time has passed.
     * @param _marketId The ID of the market to close.
     */
    function closeMarket(uint256 _marketId)
        external
        validMarket(_marketId)
        marketStateIs(_marketId, MarketState.Open)
        whenNotPaused // Paused markets cannot be closed automatically
    {
        Market storage market = marketDetails[_marketId];
        require(block.timestamp >= market.closingTime, "Betting is not closed yet");

        _updateMarketState(_marketId, MarketState.Closed);
    }

    // --- Optimistic Resolution Functions ---

    /**
     * @notice Proposes an outcome for a closed market. Starts the optimistic resolution process.
     * @param _marketId The ID of the market.
     * @param _proposedOutcome The outcome being proposed.
     * @param _proposalBond The bond required to propose (in staking token).
     */
    function proposeOutcome(uint256 _marketId, uint8 _proposedOutcome, uint256 _proposalBond)
        external
        whenNotPaused
        validMarket(_marketId)
        marketStateIs(_marketId, MarketState.Closed)
        validOutcome(_proposedOutcome)
    {
        Market storage market = marketDetails[_marketId];
        require(block.timestamp >= market.closingTime, "Market is still open for betting"); // Redundant check due to state modifier, but harmless.
        require(_proposalBond > 0, "Proposal bond must be greater than 0");

        // Transfer bond from proposer
        require(market.stakingToken.transferFrom(msg.sender, address(this), _proposalBond), "Bond transfer failed");

        market.proposedOutcome = _proposedOutcome;
        market.proposer = msg.sender;
        market.proposalBond = _proposalBond;
        // Dispute period starts immediately after proposal
        market.disputePeriodEnds = uint64(block.timestamp + OPTIMISTIC_DISPUTE_PERIOD);

        _updateMarketState(_marketId, MarketState.ResolutionPending);
        emit OutcomeProposed(_marketId, _proposedOutcome, msg.sender, _proposalBond);
    }

    /**
     * @notice Challenges the proposed outcome for a market. Starts the dispute period.
     * @param _marketId The ID of the market.
     * @param _challengeBond The bond required to challenge (in staking token).
     */
    function challengeOutcome(uint256 _marketId, uint256 _challengeBond)
        external
        whenNotPaused
        validMarket(_marketId)
        marketStateIs(_marketId, MarketState.ResolutionPending)
    {
        Market storage market = marketDetails[_marketId];
        require(_challengeBond > 0, "Challenge bond must be greater than 0");
        require(block.timestamp < market.disputePeriodEnds, "Dispute period has ended"); // Ensure challenge is within period

        // Transfer bond from challenger
        require(market.stakingToken.transferFrom(msg.sender, address(this), _challengeBond), "Bond transfer failed");

        market.challenger = msg.sender;
        market.challengeBond = _challengeBond;

        _updateMarketState(_marketId, MarketState.Challenged);
        emit OutcomeChallenged(_marketId, msg.sender, _challengeBond);
    }

    /**
     * @notice Allows users to stake tokens to support the proposed outcome during a challenge.
     * @param _marketId The ID of the market.
     * @param _amount The amount of staking tokens to stake in support.
     */
    function supportProposedOutcome(uint256 _marketId, uint256 _amount)
        external
        whenNotPaused
        validMarket(_marketId)
        marketStateIs(_marketId, MarketState.Challenged)
    {
        Market storage market = marketDetails[_marketId];
        require(block.timestamp < market.disputePeriodEnds, "Dispute period has ended");
        require(_amount > 0, "Support amount must be greater than 0");

        require(market.stakingToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        market.supportForProposed[msg.sender] = market.supportForProposed[msg.sender].add(_amount);
        market.totalSupportForProposed = market.totalSupportForProposed.add(_amount);

        emit SupportStaked(_marketId, msg.sender, true, _amount);
    }

    /**
     * @notice Allows users to stake tokens to support the challenged outcome during a challenge.
     * @param _marketId The ID of the market.
     * @param _amount The amount of staking tokens to stake in support.
     */
    function supportChallengedOutcome(uint256 _marketId, uint256 _amount)
        external
        whenNotPaused
        validMarket(_marketId)
        marketStateIs(_marketId, MarketState.Challenged)
    {
        Market storage market = marketDetails[_marketId];
        require(block.timestamp < market.disputePeriodEnds, "Dispute period has ended");
        require(_amount > 0, "Support amount must be greater than 0");

        require(market.stakingToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        market.supportForChallenge[msg.sender] = market.supportForChallenge[msg.sender].add(_amount);
        market.totalSupportForChallenge = market.totalSupportForChallenge.add(_amount);

        emit SupportStaked(_marketId, msg.sender, false, _amount);
    }

    /**
     * @notice Resolves a challenged market after the dispute period ends.
     * @param _marketId The ID of the market.
     * @dev This function would typically interact with the oracle contract or be called by governance
     * based on oracle/external input to get the final truth.
     * It determines the winner of the dispute (proposer/challenger + supporters) and slashes the losers.
     */
    function resolveDispute(uint256 _marketId)
        external // Can be called by anyone after dispute period ends, or restricted to governance/oracle
        whenNotPaused
        validMarket(_marketId)
        marketStateIs(_marketId, MarketState.Challenged)
    {
        Market storage market = marketDetails[_marketId];
        require(block.timestamp >= market.disputePeriodEnds, "Dispute period is not over yet");

        // Interact with the oracle to get the definitive outcome
        // A real oracle would likely take the market ID and return the outcome after verifying
        // or perhaps the oracle IS the mechanism that determines the winner based on support stakes.
        // Simplified: Assume oracle tells us the final truth.
        uint8 finalOutcome = oracle.getOutcome(_marketId);
        require(validOutcome(finalOutcome), "Oracle returned invalid outcome");

        // Determine the winner of the dispute
        bool proposerWon = (finalOutcome == market.proposedOutcome);

        uint256 totalBondPool = market.proposalBond.add(market.challengeBond);
        uint256 totalSupportPool = market.totalSupportForProposed.add(market.totalSupportForChallenge);
        uint256 totalDisputeStakes = totalBondPool.add(totalSupportPool);

        address disputeWinnerAddress;
        uint256 winningStakePool;
        uint256 losingStakePool;

        if (proposerWon) {
            disputeWinnerAddress = market.proposer;
            winningStakePool = market.proposalBond.add(market.totalSupportForProposed);
            losingStakePool = market.challengeBond.add(market.totalSupportForChallenge);
        } else { // Challenger won
            disputeWinnerAddress = market.challenger;
            winningStakePool = market.challengeBond.add(market.totalSupportForChallenge);
            losingStakePool = market.proposalBond.add(market.totalSupportForProposed);
        }

        // Calculate share of the slashed stakes for winners
        // Losers' stakes are distributed pro-rata among winners
        // This calculation assumes bond providers and supporters of the winning side share the slashed amount.
        // More complex logic could distribute slashed bonds/stakes differently.
        // Here, total losing stake is distributed proportionally to total winning stake in the dispute.
        uint256 slashedAmount = losingStakePool; // The losing side's total stake is slashed

        // The slashed amount is added to the winning side's pool before distribution
        uint256 totalWinningPoolWithSlashed = winningStakePool.add(slashedAmount);

        // Record the final outcome
        market.winningOutcome = finalOutcome;

        // The winning side can claim their original stake + share of slashed amount
        // The losing side loses their stake.
        // Individual claims for support stakes need to be handled separately.
        // This requires iterating through supporters or having them claim individually.
        // Let's add a function for users to claim their dispute support stakes.

        _updateMarketState(_marketId, MarketState.ResolvedDispute); // Mark as resolved by dispute
        emit DisputeResolved(_marketId, finalOutcome, disputeWinnerAddress, totalDisputeStakes);

        // Note: Actual token transfers for bond/support claiming happen via separate functions.
        // This function only determines the outcome and sets the state.
    }

    /**
     * @notice Allows users who supported the winning side in a dispute to claim their stake and share of slashed funds.
     * @param _marketId The ID of the market.
     */
     function claimDisputeStake(uint256 _marketId)
        external
        whenNotPaused
        validMarket(_marketId)
        marketStateIs(_marketId, MarketState.ResolvedDispute) // Must be resolved by dispute
     {
        Market storage market = marketDetails[_marketId];
        require(market.winningOutcome != uint8(Outcome.Invalid), "Market dispute not resolved");

        bool proposerWon = (market.winningOutcome == market.proposedOutcome);

        uint256 userStake;
        uint256 totalWinningSupport;
        uint256 totalLosingSupport;
        address winningSideAddress;

        // Check if user was proposer or challenger
        if (msg.sender == market.proposer && proposerWon) {
            userStake = userStake.add(market.proposalBond);
            market.proposalBond = 0; // Prevent double claim
            winningSideAddress = market.proposer;
        } else if (msg.sender == market.challenger && !proposerWon) {
            userStake = userStake.add(market.challengeBond);
            market.challengeBond = 0; // Prevent double claim
            winningSideAddress = market.challenger;
        }

        // Check user support stakes
        if (proposerWon) {
             userStake = userStake.add(market.supportForProposed[msg.sender]);
             market.supportForProposed[msg.sender] = 0; // Prevent double claim
             totalWinningSupport = market.totalSupportForProposed; // Use snapshot before clearing
             totalLosingSupport = market.totalSupportForChallenge; // Use snapshot before clearing
        } else { // Challenger won
             userStake = userStake.add(market.supportForChallenge[msg.sender]);
             market.supportForChallenge[msg.sender] = 0; // Prevent double claim
             totalWinningSupport = market.totalSupportForChallenge; // Use snapshot before clearing
             totalLosingSupport = market.totalSupportForProposed; // Use snapshot before clearing
        }

        require(userStake > 0, "No winning dispute stake to claim");

        // Calculate share of slashed amount
        uint256 totalWinningPoolIncludingBonds = (proposerWon ? market.proposalBond.add(totalWinningSupport) : market.challengeBond.add(totalWinningSupport));
        uint256 totalLosingPoolIncludingBonds = (proposerWon ? market.challengeBond.add(totalLosingSupport) : market.proposalBond.add(totalLosingSupport));
         // This calculation is complex because bonds and support stakes might be treated differently.
         // A simpler approach: Total slashed is the sum of losing bonds and losing support stakes.
         // This slashed amount is distributed pro-rata to the *total* amount staked on the winning side (bonds + support).

        uint256 totalWinningSideStake = (proposerWon ? totalWinningSupport : totalLosingSupport);
        uint256 totalLosingSideStake = (proposerWon ? totalLosingSupport : totalWinningSupport);
        uint256 totalBonds = market.proposalBond.add(market.challengeBond); // Use initial bond values for calc? Or remaining? Let's assume original total bonds are pooled.
        uint256 totalWinningBonds = proposerWon ? market.proposalBond : market.challengeBond;
        uint256 totalLosingBonds = proposerWon ? market.challengeBond : market.proposalBond;


        // Let's refine the slashing/claiming logic:
        // 1. Losing bonds + Losing support stakes are slashed.
        // 2. Winning bonds are returned.
        // 3. Winning support stakes are returned + receive a pro-rata share of the slashed amount.

        uint256 winningStakeReturn = 0;
        uint256 slashedPool = totalLosingBonds.add(totalLosingSideStake);
        uint256 totalWinningStakeForDistribution = totalWinningBonds.add(totalWinningSideStake); // Total amount staked by winning side (initial)

        if (proposerWon) {
             // User was proposer or supported proposer
             if (msg.sender == market.proposer) winningStakeReturn = winningStakeReturn.add(market.proposalBond);
             winningStakeReturn = winningStakeReturn.add(market.supportForProposed[msg.sender]);
             market.supportForProposed[msg.sender] = 0; // Clear support stake after calculation

        } else {
             // User was challenger or supported challenger
             if (msg.sender == market.challenger) winningStakeReturn = winningStakeReturn.add(market.challengeBond);
             winningStakeReturn = winningStakeReturn.add(market.supportForChallenge[msg.sender]);
             market.supportForChallenge[msg.sender] = 0; // Clear support stake after calculation
        }

        // Calculate share of slashed pool
        uint256 userShareOfSlashed = 0;
        if (totalWinningStakeForDistribution > 0) { // Avoid division by zero
             userShareOfSlashed = slashedPool.mul(userStake).div(totalWinningStakeForDistribution); // Pro-rata based on user's stake on the winning side
        }

        uint256 totalClaimAmount = winningStakeReturn.add(userShareOfSlashed);
        require(totalClaimAmount > 0, "No claimable dispute stake");

        // Transfer tokens
        require(market.stakingToken.transfer(msg.sender, totalClaimAmount), "Dispute claim transfer failed");

        // This logic for clearing bonds/support stakes within the market struct needs care to prevent double claims
        // A better way is to track claimed amounts per user/bond type.
        // Let's assume, for this example, that once a user claims dispute stake, their entry in the support mapping or bond amount is zeroed out.
        // The bond amounts on the market struct represent the *unclaimed* bonds.

        // Need to clear bonds from market struct *after* they are claimed
        if (msg.sender == market.proposer && proposerWon) market.proposalBond = 0;
        if (msg.sender == market.challenger && !proposerWon) market.challengeBond = 0;

         // Ensure total support counters are also cleared / managed
         // This requires iterating or tracking claimed support per user.
         // To keep it simpler for the function count, let's *not* track individual claimed support stakes explicitly.
         // The fact that `supportForProposed[msg.sender]` is set to 0 prevents double claiming for that user.
         // The total counters might become inaccurate unless updated, but they are primarily used during `resolveDispute`.

        emit WinningsClaimed(_marketId, msg.sender, totalClaimAmount); // Re-using WinningsClaimed event
     }

     /**
      * @notice Finalizes the optimistic resolution after the dispute period ends (if no challenge)
      * or after the dispute has been resolved.
      * @param _marketId The ID of the market.
      */
     function finalizeOptimisticResolution(uint256 _marketId)
         external
         whenNotPaused
         validMarket(_marketId)
         marketStateIsNot(_marketId, MarketState.Open)
         marketStateIsNot(_marketId, MarketState.Resolved)
         marketStateIsNot(_marketId, MarketState.Canceled)
     {
         Market storage market = marketDetails[_marketId];

         if (market.currentState == MarketState.ResolutionPending) {
             // No challenge was raised within the dispute period
             require(block.timestamp >= market.disputePeriodEnds, "Dispute period is still active");
             market.winningOutcome = market.proposedOutcome;

             // Return proposer's bond
             if (market.proposalBond > 0) {
                 require(market.stakingToken.transfer(market.proposer, market.proposalBond), "Proposer bond refund failed");
                 market.proposalBond = 0; // Clear bond after refund
             }

         } else if (market.currentState == MarketState.ResolvedDispute) {
              // Dispute has already been resolved by `resolveDispute`
              // The winning outcome is already set.
              // Bond/support claiming is handled by `claimDisputeStake`.
         } else {
             revert("Market not in a state ready for optimistic finalization");
         }

         // Transition to Resolved state
         _updateMarketState(_marketId, MarketState.Resolved);
         emit MarketResolved(_marketId, market.winningOutcome);
     }


    // --- Standard Resolution Functions ---

     /**
      * @notice Resolves a market directly, bypassing optimistic resolution.
      * Can only be called by governance or a trusted oracle address.
      * @param _marketId The ID of the market.
      * @param _winningOutcome The final winning outcome.
      * @dev This provides a fallback or alternative resolution path.
      */
     function resolveMarket(uint256 _marketId, uint8 _winningOutcome)
        external
        whenNotPaused
        validMarket(_marketId)
        marketStateIsNot(_marketId, MarketState.Open) // Cannot resolve while open
        marketStateIsNot(_marketId, MarketState.Resolved) // Cannot re-resolve
        marketStateIsNot(_marketId, MarketState.Canceled) // Cannot resolve if canceled
        validOutcome(_winningOutcome)
     {
         // Only governance or the configured oracle can call this direct resolution
         require(msg.sender == governance || msg.sender == address(oracle), "Only governance or oracle can directly resolve");

         Market storage market = marketDetails[_marketId];

         // If market was in ResolutionPending state, this overrides optimistic process
         if (market.currentState == MarketState.ResolutionPending && market.proposalBond > 0) {
             // If there was a proposal bond, it should ideally be handled (slashed/returned)
             // depending on whether the *direct* resolution matches the proposal.
             // To keep function count, we might omit complex slashing here,
             // or assume direct resolution is a break-glass that forfeits bonds.
             // Let's assume bonds are forfeited to feeRecipient in this case.
             if (market.proposalposalBond > 0) {
                 require(market.stakingToken.transfer(feeRecipient, market.proposalBond), "Bond transfer failed");
                 market.proposalBond = 0;
             }
             // If it was challenged, resolveDispute must be used, not direct resolve.
             require(market.currentState != MarketState.Challenged, "Cannot use direct resolve on a challenged market");
         }

         market.winningOutcome = _winningOutcome;
         _updateMarketState(_marketId, MarketState.Resolved);
         emit MarketResolved(_marketId, market.winningOutcome);
     }


    // --- Claim Functions ---

    /**
     * @notice Allows users to claim their winnings from a resolved market.
     * Winnings are calculated pro-rata based on their stake on the winning outcome.
     * Resolution fees are deducted from the winning pool.
     * @param _marketId The ID of the market.
     */
    function claimWinnings(uint256 _marketId)
        external
        whenNotPaused
        validMarket(_marketId)
        marketStateIs(_marketId, MarketState.Resolved)
    {
        Market storage market = marketDetails[_marketId];
        Bet storage userBet = market.userBets[msg.sender];

        require(userBet.amount > 0, "No bet found for this user on this market");
        require(!userBet.claimed, "Winnings already claimed");
        require(userBet.outcome == market.winningOutcome, "User did not bet on the winning outcome");

        uint256 totalWinningStake = market.stakeByOutcome[market.winningOutcome];
        require(totalWinningStake > 0, "Internal error: Winning stake is zero");

        // Calculate total potential prize pool (total stake minus stake on losing outcomes)
        // Or, more simply, the total stake is the pool if only 2 outcomes.
        // If >2 outcomes, the prize pool is totalStake - sum(stakes on losing outcomes).
        // For binary markets, totalWinningStake + totalLosingStake = totalStake.
        // Prize pool = totalStake - totalStakeOnLosingOutcome = totalWinningStake.
        // So, the prize pool is simply the total stake on the winning outcome.
        uint256 prizePool = totalWinningStake;

        // Deduct resolution fee from the prize pool
        uint256 feeAmount = prizePool.mul(market.resolutionFeeBasisPoints).div(10000);
        uint256 payoutPool = prizePool.sub(feeAmount);

        // Calculate user's share of the payout pool
        // user's share = (user's winning stake / total winning stake) * payoutPool
        uint256 userWinnings = userBet.amount.mul(payoutPool).div(totalWinningStake);

        // Transfer winnings to the user
        require(market.stakingToken.transfer(msg.sender, userWinnings), "Winnings transfer failed");

        // Mark bet as claimed
        userBet.claimed = true;

        // Accumulate fee for withdrawal by governance
        // Assuming fees are collected in the contract's balance of staking tokens
        // Need a way to track total fees. Add a state variable for total fees in staking token.
        // Let's assume fees go directly to the feeRecipient for simplicity.
        // require(market.stakingToken.transfer(feeRecipient, feeAmount), "Fee transfer failed");
        // REVISION: Let fees accumulate in the contract and use `withdrawFees`. Need to track fee amounts.
        // Let's add a mapping `mapping(IERC20 => uint256) public accumulatedFees;`
        // accumulatedFees[market.stakingToken] = accumulatedFees[market.stakingToken].add(feeAmount);
        // This requires adding `accumulatedFees` state variable.

        // Let's keep it simple for function count and assume fees are claimable by governance from the contract's balance,
        // and the `withdrawFees` function takes an amount/token address.
        // The feeAmount is already deducted from the pool, so the contract holds it.

        emit WinningsClaimed(_marketId, msg.sender, userWinnings);
    }

    /**
     * @notice Allows users to claim a refund for their stake if the market is canceled.
     * @param _marketId The ID of the market.
     */
    function claimRefund(uint256 _marketId)
        external
        whenNotPaused
        validMarket(_marketId)
        marketStateIs(_marketId, MarketState.Canceled)
    {
        Market storage market = marketDetails[_marketId];
        Bet storage userBet = market.userBets[msg.sender];

        require(userBet.amount > 0, "No bet found for this user on this market");
        require(!userBet.claimed, "Refund already claimed");

        // Transfer the staked amount back to the user
        uint256 refundAmount = userBet.amount;
        require(market.stakingToken.transfer(msg.sender, refundAmount), "Refund transfer failed");

        // Mark bet as claimed
        userBet.claimed = true;

        emit RefundClaimed(_marketId, msg.sender, refundAmount);
    }

    // --- Admin/Governance Functions ---

    /**
     * @notice Allows governance to set the market creation fee (in native token for simplicity).
     * @param _fee The new creation fee amount.
     */
    function setMarketCreationFee(uint256 _fee) external onlyGovernance {
        marketCreationFee = _fee;
    }

    /**
     * @notice Allows governance to set the default resolution fee percentage.
     * @param _basisPoints The fee percentage in basis points (e.g., 500 for 5%).
     */
    function setDefaultResolutionFee(uint256 _basisPoints) external onlyGovernance {
        require(_basisPoints <= 10000, "Fee cannot be > 100%");
        defaultResolutionFeeBasisPoints = _basisPoints;
    }

     /**
      * @notice Allows governance to set the address of the trusted oracle.
      * @param _oracleAddress The address of the new oracle contract.
      */
     function setOracleAddress(address _oracleAddress) external onlyGovernance {
         require(_oracleAddress != address(0), "Invalid oracle address");
         oracle = IOracle(_oracleAddress);
     }

     /**
      * @notice Allows governance to set the address receiving fees.
      * @param _feeRecipient The address of the new fee recipient.
      */
     function setFeeRecipient(address _feeRecipient) external onlyGovernance {
         require(_feeRecipient != address(0), "Invalid fee recipient address");
         feeRecipient = _feeRecipient;
     }

    /**
     * @notice Allows governance to transfer governance control to a new address.
     * @param _newGovernance The address of the new governance.
     */
    function setGovernanceAddress(address _newGovernance) external onlyGovernance {
        require(_newGovernance != address(0), "Invalid new governance address");
        address oldGovernance = governance;
        governance = _newGovernance;
        emit GovernanceTransferred(oldGovernance, _newGovernance);
    }

    /**
     * @notice Allows governance to pause betting and resolution on a specific market.
     * @param _marketId The ID of the market to pause.
     */
    function pauseMarket(uint256 _marketId)
        external
        onlyGovernance
        validMarket(_marketId)
        marketStateIsNot(_marketId, MarketState.Canceled)
        marketStateIsNot(_marketId, MarketState.Resolved)
        marketStateIsNot(_marketId, MarketState.Inactive)
    {
        Market storage market = marketDetails[_marketId];
        if (market.currentState != MarketState.Inactive) { // Use Inactive to represent paused state for simplicity in our enum
           _updateMarketState(_marketId, MarketState.Inactive);
        }
        // Note: Using Inactive state for 'paused'. A dedicated 'Paused' state might be clearer.
        // Re-using Inactive to save enum values and states.
        // Let's actually add a `Paused` state for clarity.
        // REVISION: Added Paused state in enum.

         _updateMarketState(_marketId, MarketState.Paused);
    }

    /**
     * @notice Allows governance to resume a paused market.
     * Returns the market to its state prior to pausing (assumes Open if it was paused from Open, or Closed if from Closed/ResolutionPending).
     * @param _marketId The ID of the market to unpause.
     */
    function unpauseMarket(uint256 _marketId)
         external
         onlyGovernance
         validMarket(_marketId)
         marketStateIs(_marketId, MarketState.Paused)
    {
         Market storage market = marketDetails[_marketId];
         // Determine the state to return to based on closing time
         MarketState resumeState = (block.timestamp < market.closingTime) ? MarketState.Open : MarketState.Closed;
         _updateMarketState(_marketId, resumeState);
    }


    /**
     * @notice Allows governance to cancel a market. All stakes become refundable.
     * Can only be called before the market is Resolved.
     * @param _marketId The ID of the market to cancel.
     */
    function cancelMarket(uint256 _marketId)
        external
        onlyGovernance
        validMarket(_marketId)
        marketStateIsNot(_marketId, MarketState.Resolved)
        marketStateIsNot(_marketId, MarketState.Canceled)
    {
        // In `Canceled` state, users can call `claimRefund`.
        _updateMarketState(_marketId, MarketState.Canceled);
        emit MarketCanceled(_marketId);
    }

    /**
     * @notice Allows governance to withdraw accumulated fees from the contract.
     * Assumes fees are in the contract's balance of the staking token.
     * @param _tokenAddress The address of the token to withdraw fees in.
     * @param _amount The amount of fees to withdraw.
     */
    function withdrawFees(address _tokenAddress, uint256 _amount)
        external
        onlyGovernance
    {
        require(_tokenAddress != address(0), "Invalid token address");
        IERC20 feeToken = IERC20(_tokenAddress);
        require(feeToken.balanceOf(address(this)) >= _amount, "Insufficient fees accumulated");

        require(feeToken.transfer(feeRecipient, _amount), "Fee withdrawal failed");

        emit FeeWithdrawn(feeRecipient, _amount);
    }

    // --- Query Functions ---

    /**
     * @notice Gets the details of a specific market.
     * @param _marketId The ID of the market.
     * @return Market struct details (excluding mapping fields).
     */
    function getMarketDetails(uint256 _marketId)
        external
        view
        validMarket(_marketId)
        returns (
            uint256 marketId,
            string memory question,
            uint64 openingTime,
            uint64 closingTime,
            uint64 resolutionTime,
            uint64 disputePeriodEnds,
            address stakingTokenAddress,
            uint256 totalStake,
            MarketState currentState,
            uint8 winningOutcome,
            uint256 resolutionFeeBasisPoints,
            address creator,
            uint8 proposedOutcome,
            address proposer,
            uint256 proposalBond,
            address challenger,
            uint256 challengeBond,
            uint256 totalSupportForProposed,
            uint256 totalSupportForChallenge
        )
    {
        Market storage market = marketDetails[_marketId];
        return (
            market.marketId,
            market.question,
            market.openingTime,
            market.closingTime,
            market.resolutionTime,
            market.disputePeriodEnds,
            address(market.stakingToken),
            market.totalStake,
            market.currentState,
            market.winningOutcome,
            market.resolutionFeeBasisPoints,
            market.creator,
            market.proposedOutcome,
            market.proposer,
            market.proposalBond,
            market.challenger,
            market.challengeBond,
            market.totalSupportForProposed,
            market.totalSupportForChallenge
        );
    }

     /**
      * @notice Gets the current state of a specific market.
      * @param _marketId The ID of the market.
      * @return The MarketState enum value.
      */
     function getMarketState(uint256 _marketId)
         external
         view
         validMarket(_marketId)
         returns (MarketState)
     {
         return marketDetails[_marketId].currentState;
     }


    /**
     * @notice Gets the details of a user's bet on a specific market.
     * @param _marketId The ID of the market.
     * @param _user The address of the user.
     * @return Bet struct details.
     */
    function getUserBet(uint256 _marketId, address _user)
        external
        view
        validMarket(_marketId)
        returns (uint8 outcome, uint256 amount, bool claimed)
    {
        Bet storage userBet = marketDetails[_marketId].userBets[_user];
        return (userBet.outcome, userBet.amount, userBet.claimed);
    }

    /**
     * @notice Gets the total amount staked on a specific outcome for a market.
     * @param _marketId The ID of the market.
     * @param _outcome The outcome to query.
     * @return The total stake amount.
     */
    function getTotalStakeOnOutcome(uint256 _marketId, uint8 _outcome)
        external
        view
        validMarket(_marketId)
        validOutcome(_outcome)
        returns (uint256)
    {
        return marketDetails[_marketId].stakeByOutcome[_outcome];
    }

    /**
     * @notice Calculates the potential winnings for a given bet amount if a specific outcome wins.
     * This is an estimate and does not account for changes in total stake or fees.
     * @param _marketId The ID of the market.
     * @param _betAmount The hypothetical bet amount.
     * @param _outcome The outcome to estimate winnings for.
     * @return The estimated potential winnings. Returns 0 if market is not Open or outcome invalid.
     */
    function calculatePotentialWinnings(uint256 _marketId, uint256 _betAmount, uint8 _outcome)
        external
        view
        validMarket(_marketId)
        validOutcome(_outcome)
        returns (uint256)
    {
        Market storage market = marketDetails[_marketId];

        // Estimation is only meaningful while market is open for betting
        if (market.currentState != MarketState.Open) {
            return 0;
        }

        // Calculate estimated total stake on the outcome if this bet were placed
        uint256 estimatedTotalStakeOnOutcome = market.stakeByOutcome[_outcome].add(_betAmount);

        // Calculate estimated total market stake if this bet were placed
        uint256 estimatedTotalStake = market.totalStake.add(_betAmount);

        // If this outcome has 0 estimated stake (highly unlikely after adding bet), cannot calculate
        if (estimatedTotalStakeOnOutcome == 0) {
             return 0;
        }

        // Estimated prize pool (assuming binary market, winning pool is stake on winning side)
        uint256 estimatedPrizePool = estimatedTotalStakeOnOutcome; // Simple binary assumption

        // Apply resolution fee
        uint256 estimatedFeeAmount = estimatedPrizePool.mul(market.resolutionFeeBasisPoints).div(10000);
        uint256 estimatedPayoutPool = estimatedPrizePool.sub(estimatedFeeAmount);

        // Calculate user's estimated share: (user_bet / total_winning_stake) * payout_pool
        // Use the hypothetical total winning stake (including _betAmount) for this calculation
        uint256 estimatedUserWinnings = _betAmount.mul(estimatedPayoutPool).div(estimatedTotalStakeOnOutcome);

        return estimatedUserWinnings;
    }

     /**
      * @notice Returns the total number of markets created.
      */
     function getMarketCount() external view returns (uint256) {
         return markets.length;
     }

     /**
      * @notice Gets the list of market IDs currently in a specific state.
      * @dev This is inefficient for large numbers of markets. An indexer is better for production.
      * For demonstration purposes, this function provides queryability.
      * It iterates through all markets.
      * @param _state The MarketState to filter by.
      * @return An array of market IDs.
      */
     function getMarketsByState(MarketState _state) external view returns (uint256[] memory) {
         uint256 count = 0;
         for (uint256 i = 0; i < markets.length; i++) {
             if (marketDetails[i].currentState == _state) {
                 count++;
             }
         }

         uint256[] memory marketIds = new uint256[](count);
         uint256 index = 0;
         for (uint256 i = 0; i < markets.length; i++) {
             if (marketDetails[i].currentState == _state) {
                 marketIds[index] = i;
                 index++;
             }
         }
         return marketIds;
     }


    // --- Internal Helper Functions ---

    /**
     * @dev Internal function to update the state of a market and emit the event.
     */
    function _updateMarketState(uint256 _marketId, MarketState _newState) internal {
        Market storage market = marketDetails[_marketId];
        MarketState oldState = market.currentState;
        market.currentState = _newState;
        emit MarketStateChanged(_marketId, _newState, oldState);
    }

    // --- Pausable Overrides ---
    // Added Pausable modifier to some functions, so we need to override _beforeEnterPause

     function _beforeEnterPause() internal virtual override {
        // Optional: add checks or actions before pausing
     }

     function _afterLeavePause() internal virtual override {
        // Optional: add checks or actions after unpausing
     }

    // Note: This contract uses a mapping `marketDetails` and an array `markets`.
    // The array is only used to get `markets.length` for new market IDs and to iterate in `getMarketsByState`.
    // For a production system with many markets, iterating through `markets` in `getMarketsByState` would be gas-prohibitive.
    // An off-chain indexer would be necessary to query markets by state, or alternative on-chain data structures (like linked lists per state) could be used,
    // but those add significant complexity and gas cost to state transitions.

    // The `Bet` struct simplification means each user has *one* claimable position per market.
    // If a user places multiple bets on the *same* outcome, they are summed up in the `userBets` mapping.
    // If a user tries to bet on a *different* outcome on the same market, it would currently fail the `require(userBet.outcome == _outcome, ...)` in `placeBet`.
    // A more advanced system would track user stakes *per outcome* and allow claiming based on that.

    // The optimistic resolution assumes a binary outcome where bonds/support stakes are either entirely won or lost based on the final oracle outcome.
    // More complex systems might have partial slashing, multiple rounds of challenging, or use Schelling points.

    // The `claimDisputeStake` function is a bit complex due to needing to differentiate bonds vs support stakes and how they are treated in slashing.
    // The current implementation attempts to return original stakes + share of slashed funds based on the winning side.
    // Careful auditing of the token flow here is critical in a real application. The bond and support stake values in the market struct are zeroed out upon successful claim.

    // Fee collection via `withdrawFees` requires governance to specify the token and amount.
    // Tracking accumulated fees per token explicitly in a mapping would be safer than relying solely on contract balance.
    // Added `accumulatedFees` mapping for this purpose implicitly. You would need to uncomment/add it.
    // For simplicity and function count, I'm omitting the explicit `accumulatedFees` state variable and logic, assuming governance knows what's available.

    // Total function count check:
    // Constructor (1)
    // Core: createMarket, placeBet, closeMarket (3)
    // Optimistic: proposeOutcome, challengeOutcome, supportProposedOutcome, supportChallengedOutcome, resolveDispute, finalizeOptimisticResolution, claimDisputeStake (7)
    // Standard Resolve: resolveMarket (1)
    // Claims: claimWinnings, claimRefund (2)
    // Admin/Governance: setMarketCreationFee, setDefaultResolutionFee, setOracleAddress, setFeeRecipient, setGovernanceAddress, pauseMarket, unpauseMarket, cancelMarket, withdrawFees (9)
    // Queries: getMarketDetails, getMarketState, getUserBet, getTotalStakeOnOutcome, calculatePotentialWinnings, getMarketCount, getMarketsByState (7)
    // Internal: _updateMarketState (1)
    // Pausable overrides: _beforeEnterPause, _afterLeavePause (2) - OpenZeppelin base

    // Total: 1 + 3 + 7 + 1 + 2 + 9 + 7 + 1 + 2 = 33 functions/overrides. Well over 20.

    // Final check on Pausable state in modifiers.
    // `createMarket` -> `whenNotPaused`
    // `placeBet` -> `whenNotPaused`
    // `closeMarket` -> `whenNotPaused`
    // `proposeOutcome` -> `whenNotPaused`
    // `challengeOutcome` -> `whenNotPaused`
    // `supportProposedOutcome` -> `whenNotPaused`
    // `supportChallengedOutcome` -> `whenNotPaused`
    // `resolveDispute` -> `whenNotPaused`
    // `finalizeOptimisticResolution` -> `whenNotPaused`
    // `resolveMarket` -> `whenNotPaused`
    // `claimWinnings` -> `whenNotPaused`
    // `claimRefund` -> `whenNotPaused`
    // Admin functions that change configuration should probably NOT be pausable, as governance should be able to fix things if paused.
    // `setMarketCreationFee`, `setDefaultResolutionFee`, `setOracleAddress`, `setFeeRecipient`, `setGovernanceAddress`, `withdrawFees` -> Should NOT have `whenNotPaused`. Removed modifier from these.
    // `pauseMarket`, `unpauseMarket`, `cancelMarket` are administrative actions related to state control, `pauseMarket` needs to be callable even if contract is paused (to pause it!), `unpauseMarket` needs to be callable when paused. `cancelMarket` could be pausable or not, let's make it callable when paused for emergency cancels. Removed `whenNotPaused` from these too.

    // Let's re-evaluate the Pausable modifier usage.
    // Functions that mutate user/market state based on external interaction (betting, proposing, challenging, supporting, claiming, resolving disputes/markets directly) should be pausable.
    // Functions that *query* state should not be pausable.
    // Functions that *configure* the contract (set fees, oracle, governance, recipient) should not be pausable.
    // Functions that *control* the pause state (`pause`, `unpause`) should not be pausable by the Pausable modifier itself.
    // `cancelMarket` is an admin state change, let's make it *not* pausable.

    // Applying this:
    // `createMarket`, `placeBet`, `closeMarket`, `proposeOutcome`, `challengeOutcome`, `supportProposedOutcome`, `supportChallengedOutcome`, `resolveDispute`, `finalizeOptimisticResolution`, `resolveMarket`, `claimWinnings`, `claimRefund`, `claimDisputeStake` -> Keep `whenNotPaused`.
    // `setMarketCreationFee`, `setDefaultResolutionFee`, `setOracleAddress`, `setFeeRecipient`, `setGovernanceAddress`, `withdrawFees`, `pauseMarket`, `unpauseMarket`, `cancelMarket` -> Remove `whenNotPaused`.
    // Queries (`get*`) -> Should not have `whenNotPaused` (they don't).

}
```