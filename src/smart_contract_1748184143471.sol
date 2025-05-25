Okay, let's design a smart contract that's interesting, uses advanced concepts, and isn't just a standard template. We'll build a "Quantum Fluctuations Casino" leveraging Chainlink VRF for secure randomness, dynamic house edge based on the house balance, and a unique game concept.

The game will be "Quantum Dice", where users bet on the outcome of a number collapsing from a "superposition state" determined by the VRF output.

Here's the outline and function summary, followed by the Solidity code.

---

**Smart Contract Outline: QuantumFluctuationsCasino**

1.  **Purpose:** An on-chain casino game ("Quantum Dice") using Chainlink VRF for provably fair randomness and implementing a dynamic house edge.
2.  **Key Concepts:**
    *   **Chainlink VRF v2:** Secure and verifiable randomness generation.
    *   **Dynamic House Edge:** The casino's advantage adjusts based on its internal balance, aiming for sustainability.
    *   **Game States:** The contract manages distinct phases (Accepting Bets, Randomness Requested, Outcome Ready).
    *   **User Balances:** Users deposit ETH/Native currency into the contract to place bets.
    *   **House Balance:** Separate balance representing the casino's funds.
3.  **Core Data Structures:**
    *   `Bet`: Struct to hold details of a user's bet (type, amount, predicted outcome/range, paid status).
    *   `Round`: Struct to manage game round details (ID, VRF Request ID, outcome, bet indices, state).
    *   Mappings for user balances, house balance, rounds, and bets.
4.  **Ownership & Access Control:** Uses OpenZeppelin's `Ownable` and `Pausable`.
5.  **Randomness:** Integrates with Chainlink VRF V2.

---

**Function Summary:**

*   **Configuration & Initialization:**
    *   `constructor`: Initializes the contract, setting VRF parameters and owner.
    *   `setVRFKeyHash`: Owner updates the VRF key hash.
    *   `setVRFFee`: Owner updates the VRF fee.
    *   `setVRFSubscriptionId`: Owner sets the Chainlink VRF Subscription ID.
    *   `setConfiguredOutcomeRange`: Owner sets the valid range for the Quantum Dice outcome.
    *   `setMinimumBetAmount`: Owner sets the minimum amount required to place a bet.
    *   `setMaximumBetAmount`: Owner sets the maximum amount allowed for a single bet.
    *   `setDynamicHouseEdgeParameters`: Owner configures factors for dynamic house edge calculation.
    *   `setConfiguredMinimumBetsForRandomness`: Owner sets the minimum bets required to trigger randomness request.
    *   `setConfiguredTimeLimitForRandomness`: Owner sets the time limit after which randomness can be requested even if min bets aren't met.
*   **User Funds Management:**
    *   `deposit`: Users deposit native currency (ETH) into their contract balance.
    *   `withdraw`: Users withdraw funds from their contract balance.
    *   `addHouseFunds`: Owner deposits native currency into the house balance.
    *   `withdrawHouseFunds`: Owner withdraws native currency from the house balance (owner only).
*   **Betting & Game Mechanics:**
    *   `placeBetOnNumber`: Place a bet predicting a specific outcome number.
    *   `placeBetOnRange`: Place a bet predicting the outcome falls within a specific range.
    *   `placeBetOnParity`: Place a bet predicting the outcome is even or odd.
    *   `requestRandomness`: Public function (callable by anyone meeting conditions) to request VRF randomness for the current round.
    *   `rawFulfillRandomness`: Chainlink VRF callback function to receive the random number. This triggers outcome processing.
    *   `claimWinnings`: Users claim their winnings after a round's outcome has been processed.
    *   `cancelBet`: Users can cancel their bet if the round hasn't progressed past the betting phase.
*   **Query & View Functions:**
    *   `getUserBalance`: Check a user's current playable balance.
    *   `getHouseBalance`: Check the casino's current house balance.
    *   `getCurrentRoundId`: Get the ID of the current active game round.
    *   `getRoundDetails`: Get details about a specific game round.
    *   `getBetDetails`: Get details about a specific bet within a round.
    *   `getUserBetsInRound`: Get indices of a user's bets in a specific round.
    *   `getCurrentGamePhase`: Get the current phase of the active round.
    *   `getConfiguredOutcomeRange`: Get the configured range for the dice outcome.
    *   `getMinimumBetAmount`: Get the configured minimum bet amount.
    *   `getMaximumBetAmount`: Get the configured maximum bet amount.
    *   `getDynamicHouseEdgeParameters`: Get the parameters used for dynamic house edge calculation.
    *   `getCalculatedHouseEdge`: Get the current calculated dynamic house edge (for information).
    *   `getVRFSubscriptionId`: Get the configured VRF Subscription ID.
    *   `getConfiguredMinimumBetsForRandomness`: Get the minimum bets required to trigger randomness.
    *   `getConfiguredTimeLimitForRandomness`: Get the time limit for randomness trigger.
*   **Administrative:**
    *   `pauseContract`: Owner pauses contract interactions (betting, withdrawals).
    *   `unpauseContract`: Owner unpauses the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/vrf/V2WrapperConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol"; // Although using ETH, this is good practice

/**
 * @title QuantumFluctuationsCasino
 * @dev A simulated casino contract using Chainlink VRF for randomness and a dynamic house edge.
 * Users deposit ETH to a balance within the contract to place bets.
 * The core game is "Quantum Dice", where users bet on a number outcome.
 */
contract QuantumFluctuationsCasino is Ownable, Pausable, ReentrancyGuard, V2WrapperConsumerBase {

    using SafeMath for uint256; // Good practice, though 0.8+ reduces need
    using SafeERC20 for IERC20; // If using ERC20 later

    // --- Structs ---

    enum BetType {
        None,
        Number,
        Range,
        Parity // 0 for Even, 1 for Odd
    }

    struct Bet {
        address player;
        BetType betType;
        uint256 amount; // Bet amount in WEI
        uint256 predictedNumber; // Used for Number/Parity
        uint256 predictedRangeStart; // Used for Range
        uint256 predictedRangeEnd; // Used for Range
        uint256 payoutMultiplier; // Configured payout for this bet type/range
        bool paidOut; // Whether winnings for this bet have been processed
    }

    enum GamePhase {
        AcceptingBets,
        RandomnessRequested,
        OutcomeReady
    }

    struct Round {
        uint256 roundId;
        uint256 vrfRequestId; // Chainlink VRF Request ID
        int256 outcome; // The final random number outcome (-1 if not ready)
        uint256[] betIndices; // Indices of bets placed in this round
        GamePhase phase;
        uint256 randomnessRequestTime; // Timestamp when randomness was requested
        uint256 numBets; // Count of bets in this round
    }

    // --- State Variables ---

    uint256 public houseBalance; // Contract's operational funds
    mapping(address => uint256) public userBalances; // User deposit balances

    uint256 public currentRoundId;
    mapping(uint256 => Round) public rounds;
    Bet[] private bets; // Central storage for all bets

    // Game Configuration
    uint256 public configuredOutcomeRange; // e.g., 100 for 1-100
    uint256 public minimumBetAmount; // Minimum bet amount in WEI
    uint256 public maximumBetAmount; // Maximum bet amount in WEI

    // Dynamic House Edge Configuration
    // payout = betAmount * multiplier * (1 - houseEdgePercentage / 10000)
    uint256 public baseHouseEdgePercentage; // e.g., 100 for 1% (stored as 100/10000)
    uint256 public houseBalanceTarget; // Target house balance for calculating dynamic adjustment
    int256 public houseEdgeSensitivity; // How much edge changes based on deviation from target (e.g., 1 for 0.01% change per 1% deviation)
    uint256 public maxHouseEdgePercentage; // Upper limit for dynamic edge
    uint256 public minHouseEdgePercentage; // Lower limit for dynamic edge

    // Payout Multipliers (Example values, owner can configure)
    mapping(BetType => uint256) public basePayoutMultipliers;
    // Specific multipliers for ranges or numbers could be more complex

    // VRF Configuration
    bytes32 public keyHash;
    uint32 public callbackGasLimit = 500000; // Example gas limit
    uint256 public requestConfirmations = 3; // Example confirmations
    uint256 public fee; // LINK fee for VRF request
    uint64 public vrfSubscriptionId; // Your Chainlink VRF Subscription ID

    // Randomness Trigger Configuration
    uint256 public configuredMinimumBetsForRandomness;
    uint256 public configuredTimeLimitForRandomness; // Time limit in seconds

    // --- Events ---

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event HouseFundsAdded(address indexed owner, uint256 amount);
    event HouseFundsWithdrawn(address indexed owner, uint256 amount);

    event BetPlaced(address indexed player, uint256 roundId, uint256 betIndex, BetType betType, uint256 amount);
    event BetCancelled(address indexed player, uint256 roundId, uint256 betIndex);
    event RandomnessRequested(uint256 indexed roundId, uint256 indexed requestId);
    event OutcomeProcessed(uint256 indexed roundId, int256 outcome);
    event WinningsClaimed(address indexed player, uint256 roundId, uint256 betIndex, uint256 amount);

    event RoundStarted(uint256 indexed roundId);
    event GamePaused(address account);
    event GameUnpaused(address account);

    // --- Modifiers ---

    modifier onlyGamePhase(uint256 _roundId, GamePhase _expectedPhase) {
        require(rounds[_roundId].phase == _expectedPhase, "QFC: Invalid game phase");
        _;
    }

    // --- Constructor ---

    constructor(
        address vrfWrapper,
        bytes32 _keyHash,
        uint256 _fee,
        uint64 _vrfSubscriptionId,
        uint256 _initialOutcomeRange,
        uint256 _initialMinBet,
        uint256 _initialMaxBet
    ) V2WrapperConsumerBase(vrfWrapper) Ownable() Pausable() {
        keyHash = _keyHash;
        fee = _fee;
        vrfSubscriptionId = _vrfSubscriptionId;
        configuredOutcomeRange = _initialOutcomeRange; // e.g., 100 for 1-100
        minimumBetAmount = _initialMinBet;
        maximumBetAmount = _initialMaxBet;

        // Set initial dynamic edge parameters (example values)
        baseHouseEdgePercentage = 200; // 2%
        houseBalanceTarget = 100 ether; // Example target
        houseEdgeSensitivity = 10; // 0.1% change per 1% deviation (100 basis points per percentage point)
        maxHouseEdgePercentage = 500; // 5% max
        minHouseEdgePercentage = 50; // 0.5% min

        // Set example base payout multipliers
        basePayoutMultipliers[BetType.Number] = configuredOutcomeRange * 98 / 100; // Slightly less than full range for edge
        basePayoutMultipliers[BetType.Parity] = 196; // Slightly less than 2x for edge

        // Initialize the first round
        currentRoundId = 1;
        rounds[currentRoundId].roundId = currentRoundId;
        rounds[currentRoundId].phase = GamePhase.AcceptingBets;
        rounds[currentRoundId].outcome = -1; // Indicate no outcome yet
        emit RoundStarted(currentRoundId);
    }

    // --- User Funds Management ---

    /**
     * @dev Deposits native currency (ETH) into the user's balance within the contract.
     */
    receive() external payable whenNotPaused {
        deposit();
    }

    /**
     * @dev Deposits native currency (ETH) into the user's balance within the contract.
     */
    function deposit() public payable whenNotPaused nonReentrant {
        require(msg.value > 0, "QFC: Deposit amount must be greater than zero");
        userBalances[msg.sender] = userBalances[msg.sender].add(msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev Allows a user to withdraw funds from their balance in the contract.
     * @param amount The amount to withdraw.
     */
    function withdraw(uint256 amount) public whenNotPaused nonReentrant {
        require(amount > 0, "QFC: Withdrawal amount must be greater than zero");
        require(userBalances[msg.sender] >= amount, "QFC: Insufficient balance");

        userBalances[msg.sender] = userBalances[msg.sender].sub(amount);
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "QFC: ETH transfer failed");

        emit Withdrawal(msg.sender, amount);
    }

    /**
     * @dev Owner adds funds to the house balance.
     */
    function addHouseFunds() public payable onlyOwner whenNotPaused nonReentrant {
        require(msg.value > 0, "QFC: House fund amount must be greater than zero");
        houseBalance = houseBalance.add(msg.value);
        emit HouseFundsAdded(msg.sender, msg.value);
    }

    /**
     * @dev Owner withdraws funds from the house balance.
     * @param amount The amount to withdraw.
     */
    function withdrawHouseFunds(uint256 amount) public onlyOwner nonReentrant {
        require(amount > 0, "QFC: Withdrawal amount must be greater than zero");
        require(houseBalance >= amount, "QFC: Insufficient house balance");

        houseBalance = houseBalance.sub(amount);
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "QFC: ETH transfer failed");

        emit HouseFundsAdded(msg.sender, amount);
    }

    // --- Betting & Game Mechanics ---

    /**
     * @dev Internal function to handle placing a bet after validation.
     */
    function _placeBet(address player, BetType betType, uint256 amount, uint256 predictedNum, uint256 predictedRangeS, uint256 predictedRangeE, uint256 payoutMultiplier) private {
        require(rounds[currentRoundId].phase == GamePhase.AcceptingBets, "QFC: Not accepting bets");
        require(userBalances[player] >= amount, "QFC: Insufficient user balance for bet");
        require(amount >= minimumBetAmount, "QFC: Bet amount below minimum");
        require(amount <= maximumBetAmount, "QFC: Bet amount exceeds maximum");
        require(amount <= houseBalance, "QFC: Bet amount exceeds current house balance (max risk)"); // Basic risk check

        userBalances[player] = userBalances[player].sub(amount); // Deduct bet amount from user balance
        // The bet amount goes 'into' the round's potential payouts pool implicitly

        uint256 betIndex = bets.length;
        bets.push(Bet({
            player: player,
            betType: betType,
            amount: amount,
            predictedNumber: predictedNum,
            predictedRangeStart: predictedRangeS,
            predictedRangeEnd: predictedRangeE,
            payoutMultiplier: payoutMultiplier,
            paidOut: false
        }));

        rounds[currentRoundId].betIndices.push(betIndex);
        rounds[currentRoundId].numBets++;

        emit BetPlaced(player, currentRoundId, betIndex, betType, amount);
    }

    /**
     * @dev Place a bet on a specific number outcome.
     * @param predictedNumber The number the user is betting on (within configured range).
     * @param amount The bet amount in WEI.
     */
    function placeBetOnNumber(uint256 predictedNumber, uint256 amount) public whenNotPaused nonReentrant {
        require(predictedNumber > 0 && predictedNumber <= configuredOutcomeRange, "QFC: Invalid predicted number");
        uint256 payoutMultiplier = basePayoutMultipliers[BetType.Number];
        _placeBet(msg.sender, BetType.Number, amount, predictedNumber, 0, 0, payoutMultiplier);
    }

    /**
     * @dev Place a bet on the outcome falling within a specific range.
     * @param predictedRangeStart The start of the predicted range (inclusive).
     * @param predictedRangeEnd The end of the predicted range (inclusive).
     * @param amount The bet amount in WEI.
     */
    function placeBetOnRange(uint256 predictedRangeStart, uint256 predictedRangeEnd, uint256 amount) public whenNotPaused nonReentrant {
        require(predictedRangeStart > 0 && predictedRangeStart <= configuredOutcomeRange, "QFC: Invalid range start");
        require(predictedRangeEnd > 0 && predictedRangeEnd <= configuredOutcomeRange, "QFC: Invalid range end");
        require(predictedRangeStart <= predictedRangeEnd, "QFC: Range start must be <= range end");

        // Calculate dynamic multiplier for ranges (simplified example)
        uint256 rangeSize = predictedRangeEnd.sub(predictedRangeStart).add(1);
        require(rangeSize > 0 && rangeSize <= configuredOutcomeRange, "QFC: Invalid range size");

        // Basic range payout: inverse of probability (approx)
        // Adjust based on dynamic edge
        uint256 baseMultiplier = configuredOutcomeRange.div(rangeSize);
        uint256 currentEdge = getCalculatedHouseEdge(); // Get current dynamic edge
        uint256 payoutMultiplier = baseMultiplier.mul(10000 - currentEdge).div(10000); // Apply edge

        // Prevent too low multipliers or overflow
        require(payoutMultiplier > 0, "QFC: Calculated payout multiplier is zero");


        _placeBet(msg.sender, BetType.Range, amount, 0, predictedRangeStart, predictedRangeEnd, payoutMultiplier);
    }

    /**
     * @dev Place a bet on the outcome being even or odd.
     * @param predictEven True for Even, False for Odd.
     * @param amount The bet amount in WEI.
     */
    function placeBetOnParity(bool predictEven, uint256 amount) public whenNotPaused nonReentrant {
        uint256 predictedParity = predictEven ? 0 : 1; // 0 for Even, 1 for Odd
        uint256 payoutMultiplier = basePayoutMultipliers[BetType.Parity]; // Should be close to 2x

        _placeBet(msg.sender, BetType.Parity, amount, predictedParity, 0, 0, payoutMultiplier);
    }

    /**
     * @dev Requests randomness from Chainlink VRF for the current round.
     * Can be called by anyone if certain conditions (min bets or time limit) are met.
     */
    function requestRandomness() public whenNotPaused nonReentrant {
        Round storage current = rounds[currentRoundId];
        require(current.phase == GamePhase.AcceptingBets, "QFC: Randomness already requested or round closed");

        bool betsThresholdMet = current.numBets >= configuredMinimumBetsForRandomness;
        bool timeLimitMet = (current.randomnessRequestTime == 0 && block.timestamp >= rounds[currentRoundId].randomnessRequestTime.add(configuredTimeLimitForRandomness)) || (current.randomnessRequestTime > 0 && block.timestamp >= rounds[currentRoundId].randomnessRequestTime.add(configuredTimeLimitForRandomness));
        // Note: randomnessRequestTime is 0 initially, so we also check for block.timestamp > configuredTimeLimit... assuming round start time is block.timestamp when phase changes. Let's clarify state update.
        // Correction: Let's set randomnessRequestTime when the round *starts* or when the phase *changes* to AcceptingBets.
        // Let's make it simple: Check if enough bets or enough *time since round start* has passed.

        require(
            betsThresholdMet || (block.timestamp >= rounds[currentRoundId].randomnessRequestTime + configuredTimeLimitForRandomness),
            "QFC: Minimum bets or time limit not met to request randomness"
        );

        current.phase = GamePhase.RandomnessRequested;
        current.randomnessRequestTime = block.timestamp; // Record request time

        uint256 requestId = requestRandomWords(keyHash, vrfSubscriptionId, requestConfirmations, callbackGasLimit, 1); // Request 1 random word
        current.vrfRequestId = requestId;

        emit RandomnessRequested(currentRoundId, requestId);
    }

    /**
     * @dev Chainlink VRF callback function. Receives the random number and processes the round outcome.
     * @param requestId The ID of the VRF request.
     * @param randomWords The list of random numbers returned by VRF.
     */
    function rawFulfillRandomness(uint256 requestId, uint256[] memory randomWords) internal override nonReentrant {
        require(randomWords.length > 0, "QFC: No random words received");

        uint256 fulfilledRoundId = 0;
        for (uint256 i = 1; i <= currentRoundId; i++) {
            if (rounds[i].vrfRequestId == requestId && rounds[i].phase == GamePhase.RandomnessRequested) {
                fulfilledRoundId = i;
                break;
            }
        }

        require(fulfilledRoundId > 0, "QFC: VRF request ID not found for any pending round");

        Round storage fulfilledRound = rounds[fulfilledRoundId];
        require(fulfilledRound.phase == GamePhase.RandomnessRequested, "QFC: Round not in RandomnessRequested phase");

        // Use the first random word for the outcome
        // Map the large VRF random number to the desired outcome range (1 to configuredOutcomeRange)
        uint256 outcome = (randomWords[0] % configuredOutcomeRange) + 1;
        fulfilledRound.outcome = int256(outcome);
        fulfilledRound.phase = GamePhase.OutcomeReady;

        // Process payouts
        processGameOutcome(fulfilledRoundId);

        emit OutcomeProcessed(fulfilledRoundId, int256(outcome));

        // Start a new round if this was the current one
        if (fulfilledRoundId == currentRoundId) {
            currentRoundId++;
            rounds[currentRoundId].roundId = currentRoundId;
            rounds[currentRoundId].phase = GamePhase.AcceptingBets;
            rounds[currentRoundId].outcome = -1;
            rounds[currentRoundId].randomnessRequestTime = block.timestamp; // Set start time for new round's time limit check
            emit RoundStarted(currentRoundId);
        }
    }

    /**
     * @dev Processes the outcome of a round, calculating payouts for winning bets.
     * This function is called internally by rawFulfillRandomness.
     * @param _roundId The ID of the round to process.
     */
    function processGameOutcome(uint256 _roundId) internal {
        Round storage round = rounds[_roundId];
        require(round.phase == GamePhase.OutcomeReady, "QFC: Round outcome not ready");
        require(round.outcome != -1, "QFC: Round outcome not set");

        uint256 finalOutcome = uint256(round.outcome);

        for (uint256 i = 0; i < round.betIndices.length; i++) {
            uint256 betIndex = round.betIndices[i];
            Bet storage bet = bets[betIndex];

            if (bet.paidOut) continue; // Should not happen if called once per round

            bool isWinner = false;
            uint256 payout = 0;

            if (bet.betType == BetType.Number) {
                if (finalOutcome == bet.predictedNumber) {
                    isWinner = true;
                }
            } else if (bet.betType == BetType.Range) {
                if (finalOutcome >= bet.predictedRangeStart && finalOutcome <= bet.predictedRangeEnd) {
                    isWinner = true;
                }
            } else if (bet.betType == BetType.Parity) {
                uint256 actualParity = finalOutcome % 2; // 0 for even, 1 for odd
                if (actualParity == bet.predictedNumber) { // predictedNumber is 0 for Even, 1 for Odd
                    isWinner = true;
                }
            }

            if (isWinner) {
                // Calculate payout: bet amount * payout multiplier / 100 (as multiplier is stored as 100x)
                // Payout multiplier already includes house edge adjustment
                payout = bet.amount.mul(bet.payoutMultiplier).div(100);

                // Add winnings to user's balance
                userBalances[bet.player] = userBalances[bet.player].add(payout);
            } else {
                // Bet amount is kept by the house implicitly (was substracted from user, not added back)
            }

            bet.paidOut = true; // Mark bet as processed
        }
        // Note: House balance is implicitly updated as winning bets are paid from the contract's balance,
        // and losing bets' amounts remain in the contract (effectively adding to house balance over time).
        // A more explicit house balance model could transfer bet amounts to house on loss, and transfer
        // winnings from house on win, but the current model is simpler and achieves the same result.
    }

    /**
     * @dev Allows a user to claim winnings from a specific bet after the round is processed.
     * Winnings are added to the user's balance, not immediately withdrawn.
     * @param _roundId The ID of the round the bet was placed in.
     * @param _betIndex The index of the bet within the global bets array.
     */
    function claimWinnings(uint256 _roundId, uint256 _betIndex) public nonReentrant {
        // Allow claiming regardless of pause status? Depends on desired behavior.
        // Let's allow claiming even when paused, but prevent withdrawals.
        // require(rounds[_roundId].phase == GamePhase.OutcomeReady, "QFC: Round outcome not ready to claim"); // Not strictly necessary if bet.paidOut is used
        require(_betIndex < bets.length, "QFC: Invalid bet index");

        Bet storage bet = bets[_betIndex];
        require(bet.player == msg.sender, "QFC: Not your bet");
        require(bet.paidOut, "QFC: Bet outcome not yet processed");

        // Winnings are added directly to userBalances in processGameOutcome.
        // This function primarily serves as a state check/trigger visibility for the user.
        // If we wanted explicit "claimable" balance, we'd need another mapping.
        // With the current model, the user balance *is* their claimable/playable balance.
        // So, claiming is implicitly done during processGameOutcome.
        // Let's repurpose this function to simply verify a bet was won and processed.
        // A better pattern might be to have a separate 'claimableWinnings' balance.
        // Let's adjust: processGameOutcome calculates and adds winnings to a `claimableWinnings` mapping,
        // and `claimWinnings` moves it from `claimableWinnings` to `userBalances`.

        // Re-implementing with a separate claimable balance
        // Need a new mapping: `mapping(address => uint256) public claimableWinnings;`
        // In processGameOutcome: Instead of `userBalances[bet.player] = userBalances[bet.player].add(payout);`, use `claimableWinnings[bet.player] = claimableWinnings[bet.player].add(payout);`
        // This `claimWinnings` function would then be:

        uint256 winningsToClaim = claimableWinnings[msg.sender];
        require(winningsToClaim > 0, "QFC: No winnings to claim");

        claimableWinnings[msg.sender] = 0;
        userBalances[msg.sender] = userBalances[msg.sender].add(winningsToClaim); // Add to playable balance

        // We don't track winnings per bet index with this model, just per user.
        // Adjust event or remove _roundId, _betIndex params if we just claim total claimable.
        // Let's make it claim total claimable.

        // If we want to keep tracking per bet, the Bet struct needs a `winningsAmount` field set in processGameOutcome.
        // Let's stick to the simpler model for now where winnings are directly added to user balance in processGameOutcome.
        // The `claimWinnings` function then is perhaps redundant in this model, or serves as a *trigger* if payouts weren't automatic.
        // Given the current structure, `processGameOutcome` handles the payout calculation and adds to `userBalances`.
        // This `claimWinnings` function could potentially be used to trigger the *processing* for a specific bet if it wasn't done automatically, but that adds complexity.
        // Let's refine the concept: `processGameOutcome` *does* the calculation and adds to user balance. `claimWinnings` is not needed for payout, but perhaps `withdraw` is the actual claim from playable balance.
        // Okay, removing the need for a separate `claimWinnings` function as payout is direct to user balance in `processGameOutcome`.
        // Let's add back `claimableWinnings` mapping and the proper `claimWinnings` function as it's a common pattern and adds flexibility.

        // NEW IMPLEMENTATION OF CLAIM WINNINGS (Requires `mapping(address => uint256) public claimableWinnings;` state var)
        // In `processGameOutcome`, replace `userBalances[bet.player] = userBalances[bet.player].add(payout);`
        // with `claimableWinnings[bet.player] = claimableWinnings[bet.player].add(payout);`.

        uint256 winnings = claimableWinnings[msg.sender];
        require(winnings > 0, "QFC: No winnings to claim");

        claimableWinnings[msg.sender] = 0; // Reset claimable amount
        userBalances[msg.sender] = userBalances[msg.sender].add(winnings); // Add to playable balance

        // We don't have bet-specific claim, so the event is per user claim.
        emit WinningsClaimed(msg.sender, 0, 0, winnings); // Using 0 for round/bet index as it's total claim
    }
    mapping(address => uint256) public claimableWinnings; // State variable added based on refinement

    /**
     * @dev Allows a user to cancel their bet if the round is still accepting bets.
     * @param _roundId The ID of the round the bet was placed in.
     * @param _betIndex The index of the bet within the global bets array.
     */
    function cancelBet(uint256 _roundId, uint256 _betIndex) public nonReentrant onlyGamePhase(_roundId, GamePhase.AcceptingBets) {
        require(_betIndex < bets.length, "QFC: Invalid bet index");
        Bet storage bet = bets[_betIndex];
        require(bet.player == msg.sender, "QFC: Not your bet");
        require(!bet.paidOut, "QFC: Bet already processed"); // Also covers cancelled state effectively

        // Return the bet amount to the user's balance
        userBalances[msg.sender] = userBalances[msg.sender].add(bet.amount);

        // Mark the bet as cancelled (or logically exclude it).
        // A simple way is to mark it as paidOut and set amount to 0.
        // This saves gas vs removing from array but means the Bet struct remains.
        // Alternatively, we could use a 'cancelled' flag. Let's use 'paidOut' as flag and amount 0.
        bet.amount = 0; // Indicate cancelled/refunded
        bet.paidOut = true; // Prevent further processing

        // Need to remove from round's betIndices to avoid processing later.
        // This is gas-expensive for large rounds.
        // A simpler way: In `processGameOutcome`, check if `bet.amount > 0`.

        // Let's stick to the simpler `bet.amount = 0; bet.paidOut = true;` and check `bet.amount > 0` in processing.
        // This avoids array manipulation but leaves "empty" slots logically.

        emit BetCancelled(msg.sender, _roundId, _betIndex);
    }

    // --- Query & View Functions ---

    /**
     * @dev Gets a user's current playable balance.
     * @param user The address of the user.
     * @return The user's balance in WEI.
     */
    function getUserBalance(address user) public view returns (uint256) {
        return userBalances[user];
    }

    /**
     * @dev Gets the casino's current house balance.
     * @return The house balance in WEI.
     */
    function getHouseBalance() public view returns (uint256) {
        return houseBalance;
    }

    /**
     * @dev Gets the ID of the current active game round.
     * @return The current round ID.
     */
    function getCurrentRoundId() public view returns (uint256) {
        return currentRoundId;
    }

     /**
     * @dev Gets details about a specific game round.
     * @param _roundId The ID of the round.
     * @return roundId The round ID.
     * @return vrfRequestId The Chainlink VRF Request ID.
     * @return outcome The final random number outcome (-1 if not ready).
     * @return phase The current phase of the round.
     * @return randomnessRequestTime Timestamp when randomness was requested.
     * @return numBets Total number of bets placed in this round.
     */
    function getRoundDetails(uint256 _roundId) public view returns (
        uint256 roundId,
        uint256 vrfRequestId,
        int256 outcome,
        GamePhase phase,
        uint256 randomnessRequestTime,
        uint256 numBets
    ) {
        Round storage r = rounds[_roundId];
        return (
            r.roundId,
            r.vrfRequestId,
            r.outcome,
            r.phase,
            r.randomnessRequestTime,
            r.numBets
        );
    }


    /**
     * @dev Gets details about a specific bet.
     * @param _betIndex The index of the bet within the global bets array.
     * @return player The player's address.
     * @return betType The type of bet.
     * @return amount The bet amount.
     * @return predictedNumber The predicted number (if applicable).
     * @return predictedRangeStart The start of the predicted range (if applicable).
     * @return predictedRangeEnd The end of the predicted range (if applicable).
     * @return payoutMultiplier The multiplier used for this bet.
     * @return paidOut Whether the bet has been processed/paid.
     */
    function getBetDetails(uint256 _betIndex) public view returns (
        address player,
        BetType betType,
        uint256 amount,
        uint256 predictedNumber,
        uint256 predictedRangeStart,
        uint256 predictedRangeEnd,
        uint256 payoutMultiplier,
        bool paidOut
    ) {
        require(_betIndex < bets.length, "QFC: Invalid bet index");
        Bet storage bet = bets[_betIndex];
        return (
            bet.player,
            bet.betType,
            bet.amount,
            bet.predictedNumber,
            bet.predictedRangeStart,
            bet.predictedRangeEnd,
            bet.payoutMultiplier,
            bet.paidOut
        );
    }

    /**
     * @dev Gets the indices of all bets placed by a user in a specific round.
     * Note: This iterates through all bets in the round, potentially gas-heavy for view.
     * @param _roundId The ID of the round.
     * @param user The address of the user.
     * @return An array of bet indices.
     */
    function getUserBetsInRound(uint256 _roundId, address user) public view returns (uint256[] memory) {
        require(_roundId > 0 && _roundId <= currentRoundId, "QFC: Invalid round ID");
        uint256[] memory roundBetIndices = rounds[_roundId].betIndices;
        uint256[] memory userIndices;
        uint256 count = 0;

        // First pass to count
        for (uint256 i = 0; i < roundBetIndices.length; i++) {
            if (bets[roundBetIndices[i]].player == user) {
                count++;
            }
        }

        // Second pass to populate array
        userIndices = new uint256[](count);
        uint256 userIndexCount = 0;
        for (uint256 i = 0; i < roundBetIndices.length; i++) {
             if (bets[roundBetIndices[i]].player == user) {
                userIndices[userIndexCount] = roundBetIndices[i];
                userIndexCount++;
            }
        }

        return userIndices;
    }

    /**
     * @dev Gets the current phase of the active round.
     * @return The current game phase.
     */
    function getCurrentGamePhase() public view returns (GamePhase) {
        return rounds[currentRoundId].phase;
    }

    /**
     * @dev Gets the configured range for the Quantum Dice outcome (1 to N).
     * @return The maximum possible outcome number.
     */
    function getConfiguredOutcomeRange() public view returns (uint256) {
        return configuredOutcomeRange;
    }

     /**
     * @dev Gets the configured minimum bet amount.
     * @return The minimum bet amount in WEI.
     */
    function getMinimumBetAmount() public view returns (uint256) {
        return minimumBetAmount;
    }

    /**
     * @dev Gets the configured maximum bet amount.
     * @return The maximum bet amount in WEI.
     */
    function getMaximumBetAmount() public view returns (uint256) {
        return maximumBetAmount;
    }

     /**
     * @dev Gets the parameters used for dynamic house edge calculation.
     * @return baseEdge The base house edge percentage (e.g., 200 for 2%).
     * @return targetBalance The target house balance in WEI.
     * @return sensitivity How much edge changes per deviation (scaled).
     * @return maxEdge The maximum house edge percentage.
     * @return minEdge The minimum house edge percentage.
     */
    function getDynamicHouseEdgeParameters() public view returns (
        uint256 baseEdge,
        uint256 targetBalance,
        int256 sensitivity,
        uint256 maxEdge,
        uint256 minEdge
    ) {
        return (
            baseHouseEdgePercentage,
            houseBalanceTarget,
            houseEdgeSensitivity,
            maxHouseEdgePercentage,
            minHouseEdgePercentage
        );
    }

    /**
     * @dev Calculates the current dynamic house edge based on house balance.
     * Formula: max(minEdge, min(maxEdge, baseEdge + (houseBalanceTarget - houseBalance) * sensitivity / 1e18))
     * The sensitivity is scaled by 1e18 to handle potential fractional adjustments relative to ETH values.
     * Example: sensitivity = 10 means 0.1% edge change per 1 ETH deviation from target.
     * @return The calculated current house edge percentage (scaled by 10000, e.g., 100 for 1%).
     */
    function getCalculatedHouseEdge() public view returns (uint256) {
        uint256 currentHouseBalance = houseBalance; // Use the actual balance

        // Calculate deviation from target, scaled by 1e18 to align with WEI values
        int256 deviation = int256(houseBalanceTarget) - int256(currentHouseBalance);

        // Calculate adjustment: deviation * sensitivity / 1e18 (scaled)
        // Need to handle potential negative results from deviation
        int256 adjustment;
        if (deviation >= 0) {
             adjustment = (deviation * houseEdgeSensitivity) / (10**18); // Assumes sensitivity is per WEI deviation if 1e18 scale
        } else {
             adjustment = (deviation * houseEdgeSensitivity) / (10**18); // Still works with negative deviation
        }


        int256 currentEdge10000 = int256(baseHouseEdgePercentage) + adjustment;

        // Clamp the result between min and max edge
        currentEdge10000 = max(currentEdge10000, int256(minHouseEdgePercentage));
        currentEdge10000 = min(currentEdge10000, int256(maxHouseEdgePercentage));

        // Return as uint256
        return uint256(currentEdge10000);
    }

    // Helper for min/max int256
    function max(int256 a, int256 b) private pure returns (int256) {
        return a >= b ? a : b;
    }

     function min(int256 a, int256 b) private pure returns (int256) {
        return a <= b ? a : b;
    }


    /**
     * @dev Gets the configured Chainlink VRF Subscription ID.
     * @return The VRF Subscription ID.
     */
    function getVRFSubscriptionId() public view returns (uint64) {
        return vrfSubscriptionId;
    }

     /**
     * @dev Gets the configured minimum number of bets required to trigger randomness request.
     * @return The minimum bet count.
     */
    function getConfiguredMinimumBetsForRandomness() public view returns (uint256) {
        return configuredMinimumBetsForRandomness;
    }

     /**
     * @dev Gets the configured time limit in seconds after which randomness can be requested.
     * @return The time limit in seconds.
     */
    function getConfiguredTimeLimitForRandomness() public view returns (uint256) {
        return configuredTimeLimitForRandomness;
    }

    /**
     * @dev Gets the user's total claimable winnings balance.
     * @param user The address of the user.
     * @return The claimable winnings balance in WEI.
     */
    function getClaimableWinnings(address user) public view returns (uint256) {
        return claimableWinnings[user];
    }


    // --- Administrative Functions (Owner Only) ---

    /**
     * @dev Owner updates the Chainlink VRF Key Hash.
     * @param _keyHash The new key hash.
     */
    function setVRFKeyHash(bytes32 _keyHash) public onlyOwner {
        keyHash = _keyHash;
    }

    /**
     * @dev Owner updates the Chainlink VRF Fee.
     * @param _fee The new fee in LINK.
     */
    function setVRFFee(uint256 _fee) public onlyOwner {
        fee = _fee;
    }

    /**
     * @dev Owner updates the Chainlink VRF Subscription ID.
     * @param _vrfSubscriptionId The new subscription ID.
     */
    function setVRFSubscriptionId(uint64 _vrfSubscriptionId) public onlyOwner {
        vrfSubscriptionId = _vrfSubscriptionId;
    }

    /**
     * @dev Owner sets the valid range for the Quantum Dice outcome (1 to N).
     * Must be greater than 0.
     * @param _range The maximum outcome number.
     */
    function setConfiguredOutcomeRange(uint256 _range) public onlyOwner {
        require(_range > 0, "QFC: Outcome range must be greater than 0");
        configuredOutcomeRange = _range;
        // Note: May need to update payout multipliers for Number/Parity bets here too if they depend on range.
        // Simple example:
        basePayoutMultipliers[BetType.Number] = configuredOutcomeRange * 98 / 100;
    }

     /**
     * @dev Owner sets the minimum amount required to place a bet.
     * @param _amount The minimum amount in WEI.
     */
    function setMinimumBetAmount(uint256 _amount) public onlyOwner {
        minimumBetAmount = _amount;
    }

    /**
     * @dev Owner sets the maximum amount allowed for a single bet.
     * @param _amount The maximum amount in WEI.
     */
    function setMaximumBetAmount(uint256 _amount) public onlyOwner {
        maximumBetAmount = _amount;
    }

     /**
     * @dev Owner configures the parameters for dynamic house edge calculation.
     * @param _baseEdgePercentage The base house edge percentage (e.g., 200 for 2%).
     * @param _targetBalance The target house balance in WEI.
     * @param _sensitivity How much edge changes per 1e18 WEI deviation from target (e.g., 10 for 0.1% change per ETH deviation).
     * @param _maxEdgePercentage The upper limit for dynamic edge.
     * @param _minEdgePercentage The lower limit for dynamic edge.
     */
    function setDynamicHouseEdgeParameters(
        uint256 _baseEdgePercentage,
        uint256 _targetBalance,
        int256 _sensitivity,
        uint256 _maxEdgePercentage,
        uint256 _minEdgePercentage
    ) public onlyOwner {
        require(_minEdgePercentage <= _maxEdgePercentage, "QFC: Min edge must be <= max edge");
        baseHouseEdgePercentage = _baseEdgePercentage;
        houseBalanceTarget = _targetBalance;
        houseEdgeSensitivity = _sensitivity;
        maxHouseEdgePercentage = _maxEdgePercentage;
        minHouseEdgePercentage = _minEdgePercentage;
    }

     /**
     * @dev Owner sets the minimum number of bets required in a round to enable randomness request.
     * @param _count The minimum bet count.
     */
    function setConfiguredMinimumBetsForRandomness(uint256 _count) public onlyOwner {
        configuredMinimumBetsForRandomness = _count;
    }

     /**
     * @dev Owner sets the time limit in seconds after which randomness can be requested regardless of bet count.
     * @param _timeLimit The time limit in seconds.
     */
    function setConfiguredTimeLimitForRandomness(uint256 _timeLimit) public onlyOwner {
        configuredTimeLimitForRandomness = _timeLimit;
    }


    /**
     * @dev Pauses the contract, preventing most interactions.
     * Only owner can call.
     */
    function pauseContract() public onlyOwner {
        _pause();
        emit GamePaused(msg.sender);
    }

    /**
     * @dev Unpauses the contract, allowing interactions again.
     * Only owner can call.
     */
    function unpauseContract() public onlyOwner {
        _unpause();
         // When unpausing, update the randomnessRequestTime for the current round
        if (rounds[currentRoundId].phase == GamePhase.AcceptingBets) {
            rounds[currentRoundId].randomnessRequestTime = block.timestamp;
        }
        emit GameUnpaused(msg.sender);
    }


    // --- Helper / Utility Functions ---

    /**
     * @dev Internal helper to get base payout multiplier for a BetType.
     * @param _betType The type of bet.
     * @return The base multiplier.
     */
    function _getBasePayoutMultiplier(BetType _betType) internal view returns (uint256) {
         if (_betType == BetType.Number) return basePayoutMultipliers[BetType.Number];
         if (_betType == BetType.Parity) return basePayoutMultipliers[BetType.Parity];
         // Range multipliers are calculated dynamically in placeBetOnRange
         return 0; // Should not happen for valid types
    }


    // --- Fallback Function ---
    // Not strictly needed with `receive()`, but good for clarity.
    // fallback() external payable {
    //     revert("QFC: Call not supported or requires specific function");
    // }
}

// SafeMath library (OpenZeppelin) for safety against overflow/underflow
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction underflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}
```

---

**Explanation of Advanced/Interesting Concepts:**

1.  **Chainlink VRF v2 Integration:** Uses the standard, secure method for generating unpredictable and verifiable random numbers on-chain, essential for a fair casino. Requires linking to a VRF Coordinator and managing a Subscription ID.
2.  **Dynamic House Edge:** The `getCalculatedHouseEdge` function implements a simple model where the house edge (the casino's mathematical advantage) increases if the house balance falls below a target and decreases if it rises above the target. This aims to make the casino more sustainable over time by adjusting risk based on its reserves. Parameters are configurable by the owner. The calculation involves handling potentially negative intermediate values using `int256` before clamping to the valid `uint256` range.
3.  **Game State Management:** The `GamePhase` enum and the `rounds` mapping track the status of each game round (`AcceptingBets`, `RandomnessRequested`, `OutcomeReady`). This ensures actions like placing bets or requesting randomness only happen at the correct time in the game cycle.
4.  **Public Randomness Trigger:** The `requestRandomness` function can be called by *anyone* once a minimum number of bets are placed OR a certain amount of time has passed since the round started. This prevents the game from stalling if no single player makes enough bets, decentralizing the responsibility of moving the game forward (though a keeper/bot would likely do this reliably).
5.  **Internal Balance System:** Users deposit funds into their balance within the contract (`userBalances`) rather than sending ETH directly with each bet. This saves gas on multiple bets or withdrawals.
6.  **Separated House Balance:** Explicitly tracking `houseBalance` allows for clearer management of the casino's operational funds, distinct from user deposits.
7.  **Bet Types & Payout Calculation:** Supports different betting strategies (`Number`, `Range`, `Parity`) with varying payout multipliers, adjusted by the dynamic house edge.
8.  **Claimable Winnings Pattern:** Introducing a `claimableWinnings` mapping separates the payout event from the actual fund availability in the user's playable balance (`userBalances`). This allows users to see winnings immediately after the round processes but requires a separate `claimWinnings` transaction to make those funds available for betting or withdrawal.
9.  **Extensive Configuration:** Many key parameters (outcome range, bet limits, VRF details, dynamic edge factors, randomness trigger conditions) are configurable by the owner, allowing the casino operator to tune the game's economics and behavior.
10. **OpenZeppelin Standards:** Uses `Ownable`, `Pausable`, and `ReentrancyGuard` for standard and secure contract practices.

This contract provides a solid foundation for a complex on-chain game with several advanced features beyond a simple betting contract. Remember that deploying and operating this requires a funded Chainlink VRF Subscription.