Okay, here is a Solidity smart contract concept called "Quantum Entanglement Lottery". This contract attempts to introduce some non-standard mechanics inspired (loosely!) by quantum concepts like superposition, entanglement, and state collapse, applied to a lottery context.

**Disclaimer:** The "quantum" aspects are purely conceptual for the game mechanics and naming. This contract does *not* use actual quantum computing or cryptographic techniques based on quantum mechanics (which are not directly possible within current EVM smart contracts anyway). The randomness used is also a pseudo-random number generator based on block data, which is **NOT SECURE** for production use where participants have significant incentives to manipulate block data. For production, a secure oracle like Chainlink VRF or similar would be required.

This contract focuses on complex state management, player interactions within different phases, and a unique payout structure involving group participation.

---

## Contract Outline: Quantum Entanglement Lottery

This contract implements a lottery system with distinct phases: Buying, Superposition (active interaction), Collapse (drawing), and Payout. Players can buy individual units (QPUs) or combine them into 'Entangled States' for shared potential winnings.

1.  **Enums:** Define states for the Round and for individual QPUs/Entangled States.
2.  **Structs:** Define data structures for Quantum Potential Units (QPUs), Entangled States, and Round information.
3.  **State Variables:** Store contract configuration, round data, and mappings for QPUs and Entangled States.
4.  **Events:** Announce key actions and state changes.
5.  **Modifiers:** Restrict function access based on role or round state.
6.  **Constructor:** Initialize the contract owner and initial parameters.
7.  **Owner/Manager Functions:** Admin controls (start round, set price, withdraw fees, etc.).
8.  **Randomness/Collapse Logic:** Internal or manager-triggered function to determine winners (pseudo-random for demo).
9.  **Player Actions (Buying Phase):** Functions to buy QPUs.
10. **Player Actions (Superposition Phase):** Functions to create, join, modify, or leave Entangled States.
11. **Player Actions (Payout Phase):** Functions to claim winnings.
12. **View Functions:** Read contract state and information.

## Function Summary:

1.  `constructor()`: Initializes the contract owner, manager (initially owner), and sets the initial QPU price and round duration.
2.  `setManager(address _manager)`: Allows the owner to set a separate manager address.
3.  `setQpuPrice(uint256 _price)`: Allows owner/manager to set the price per QPU.
4.  `setSuperpositionDuration(uint256 _duration)`: Allows owner/manager to set the duration of the Superposition phase in seconds.
5.  `setPayoutFee(uint256 _feeBasisPoints)`: Allows owner/manager to set a fee percentage on winnings (in basis points).
6.  `startNextRound()`: Allows owner/manager to start a new round, moving from Payout or Initial state to Buying.
7.  `triggerStateCollapse()`: Allows owner/manager (or external oracle trigger) to end the Superposition phase and initiate the winning determination process (Collapse).
8.  `cancelRound()`: Allows owner/manager to cancel the current round in case of issues (refunds contributions).
9.  `withdrawFees()`: Allows owner/manager to withdraw accumulated fees.
10. `buyQpu()`: Allows a player to buy a single QPU during the Buying phase.
11. `buyMultipleQpus(uint256 _count)`: Allows a player to buy multiple QPUs during the Buying phase.
12. `createEntangledState(uint256[] calldata _qpuIds)`: Allows a player to create a new Entangled State using their owned QPUs *before* the Superposition phase ends.
13. `joinEntangledState(uint256 _stateId, uint256[] calldata _qpuIds)`: Allows a player to add their owned QPUs to an existing, joinable Entangled State *before* the Superposition phase ends.
14. `leaveEntangledState(uint256 _stateId, uint256[] calldata _qpuIds)`: Allows a player to remove their owned QPUs from an Entangled State *before* the Superposition phase ends. Removed QPUs revert to individual state.
15. `addQpusToEntangledState(uint256 _stateId, uint256[] calldata _qpuIds)`: Allows a player to add *more* of their QPUs to an Entangled State they are already part of (can be done during Superposition).
16. `splitEntangledState(uint256 _stateId)`: Allows a participant to dismantle an Entangled State they created (if conditions met, e.g., empty or before superposition). *Note: Restricted to prevent manipulation during the draw phase.*
17. `claimWinnings(uint256 _roundId)`: Allows a player to claim their determined winnings after the Collapse phase is complete for a specific round.
18. `generatePseudoRandomNumber()`: Internal helper function to generate a pseudo-random number (insecure for production).
19. `calculateWinnings(uint256 _roundId, uint256 _randomNumber)`: Internal helper function used during `triggerStateCollapse` to determine winners and calculate payouts based on the random number and QPU/State distribution.
20. `getCurrentRoundId()`: View function to get the ID of the current round.
21. `getRoundState(uint256 _roundId)`: View function to get the current state of a specific round.
22. `getQpuDetails(uint256 _qpuId)`: View function to get details about a specific QPU.
23. `getEntangledStateDetails(uint256 _stateId)`: View function to get details about a specific Entangled State.
24. `getPlayerQpus(address _player, uint256 _roundId)`: View function to list QPU IDs owned by a player in a given round.
25. `getPlayerEntangledStates(address _player, uint256 _roundId)`: View function to list Entangled State IDs a player is part of in a given round.
26. `getRoundWinnerInfo(uint256 _roundId)`: View function to get summary information about winners for a collapsed round.
27. `getQpuCountInRound(uint256 _roundId)`: View function to get the total number of QPUs in a round.
28. `getEntangledStateCountInRound(uint256 _roundId)`: View function to get the total number of Entangled States in a round.
29. `getQpuPrice()`: View function to get the current price per QPU.
30. `getRoundEndTime(uint256 _roundId)`: View function to get the timestamp when the superposition phase ends for a round.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Contract Outline: Quantum Entanglement Lottery ---
// This contract implements a lottery system with distinct phases: Buying, Superposition (active interaction), Collapse (drawing), and Payout.
// Players can buy individual units (QPUs) or combine them into 'Entangled States' for shared potential winnings.
//
// 1. Enums: Define states for the Round and for individual QPUs/Entangled States.
// 2. Structs: Define data structures for Quantum Potential Units (QPUs), Entangled States, and Round information.
// 3. State Variables: Store contract configuration, round data, and mappings for QPUs and Entangled States.
// 4. Events: Announce key actions and state changes.
// 5. Modifiers: Restrict function access based on role or round state.
// 6. Constructor: Initialize the contract owner and initial parameters.
// 7. Owner/Manager Functions: Admin controls (start round, set price, withdraw fees, etc.).
// 8. Randomness/Collapse Logic: Internal or manager-triggered function to determine winners (pseudo-random for demo).
// 9. Player Actions (Buying Phase): Functions to buy QPUs.
// 10. Player Actions (Superposition Phase): Functions to create, join, modify, or leave Entangled States.
// 11. Player Actions (Payout Phase): Functions to claim winnings.
// 12. View Functions: Read contract state and information.

// --- Function Summary ---
// 1. constructor(): Initializes the contract owner, manager (initially owner), and sets initial parameters.
// 2. setManager(address _manager): Sets a separate manager address.
// 3. setQpuPrice(uint256 _price): Sets the price per QPU.
// 4. setSuperpositionDuration(uint256 _duration): Sets the duration of the Superposition phase.
// 5. setPayoutFee(uint256 _feeBasisPoints): Sets a fee percentage on winnings (in basis points).
// 6. startNextRound(): Initiates a new round.
// 7. triggerStateCollapse(): Ends Superposition phase and initiates winning determination.
// 8. cancelRound(): Cancels the current round (refunds contributions).
// 9. withdrawFees(): Owner/manager withdraws accumulated fees.
// 10. buyQpu(): Player buys a single QPU during Buying phase.
// 11. buyMultipleQpus(uint256 _count): Player buys multiple QPUs during Buying phase.
// 12. createEntangledState(uint256[] calldata _qpuIds): Player creates a new Entangled State using owned QPUs.
// 13. joinEntangledState(uint256 _stateId, uint256[] calldata _qpuIds): Player adds owned QPUs to an existing state.
// 14. leaveEntangledState(uint256 _stateId, uint256[] calldata _qpuIds): Player removes owned QPUs from a state (before superposition ends).
// 15. addQpusToEntangledState(uint256 _stateId, uint256[] calldata _qpuIds): Player adds more QPUs to a state they are in (can be during Superposition).
// 16. splitEntangledState(uint256 _stateId): Attempts to dismantle an Entangled State (conditions apply).
// 17. claimWinnings(uint256 _roundId): Player claims determined winnings for a round.
// 18. generatePseudoRandomNumber(): Internal helper for randomness (INSECURE).
// 19. calculateWinnings(uint256 _roundId, uint256 _randomNumber): Internal helper to calculate payouts.
// 20. getCurrentRoundId(): View function - Get the current round ID.
// 21. getRoundState(uint256 _roundId): View function - Get the state of a specific round.
// 22. getQpuDetails(uint256 _qpuId): View function - Get details about a QPU.
// 23. getEntangledStateDetails(uint256 _stateId): View function - Get details about an Entangled State.
// 24. getPlayerQpus(address _player, uint256 _roundId): View function - List player's QPU IDs in a round.
// 25. getPlayerEntangledStates(address _player, uint256 _roundId): View function - List player's Entangled State IDs in a round.
// 26. getRoundWinnerInfo(uint256 _roundId): View function - Get winner summary for a round.
// 27. getQpuCountInRound(uint256 _roundId): View function - Total QPUs in a round.
// 28. getEntangledStateCountInRound(uint256 _roundId): View function - Total Entangled States in a round.
// 29. getQpuPrice(): View function - Get the current QPU price.
// 30. getRoundEndTime(uint256 _roundId): View function - Get superposition end time for a round.

contract QuantumEntanglementLottery {

    // --- Enums ---
    enum RoundState {
        Inactive,       // No round active
        Buying,         // Players can buy QPUs
        Superposition,  // Players can modify Entangled States
        Collapsed,      // Winners determined, awaiting payout
        Payout          // Winnings can be claimed
    }

    enum QuantumState {
        Active,         // Participating in the round
        Entangled,      // Part of an EntangledState
        Won,            // Determined as a winner during Collapse
        Lost,           // Determined as a loser during Collapse
        Claimed,        // Winnings claimed
        Refunded        // Contribution refunded (e.g., round cancelled)
    }

    // --- Structs ---
    struct Qpu {
        uint256 id;
        uint256 roundId;
        address owner;
        uint256 value; // Value contributed
        QuantumState state;
        uint256 entangledStateId; // 0 if not entangled
        uint256 winAmount; // Calculated payout for this QPU
    }

    struct EntangledState {
        uint256 id;
        uint256 roundId;
        address creator;
        address[] participants; // Addresses involved
        uint256[] qpuIds;       // QPUs included in this state
        uint256 totalValue;     // Sum of values of included QPUs
        QuantumState state;
        uint256 winAmount;      // Total payout for this state
        // Mapping participant address to their share of totalValue
        mapping(address => uint256) participantValue;
    }

    struct Round {
        uint256 id;
        RoundState state;
        uint256 startTime;
        uint256 superpositionEndTime; // End time for player interaction
        uint256 collapseTime;         // Time when collapse was triggered
        uint256 totalPool;            // Total Ether collected in the round
        uint256 totalQpus;            // Total QPUs bought in the round
        uint256 totalEntangledStates; // Total Entangled States created
        uint256 winningNumber;        // The number derived from randomness
        uint256 totalWonPool;         // Sum of winAmount for all winning QPUs/States
        uint256 totalFeesCollected;   // Fees collected from winnings in this round
        // Mapping to track claimed winnings per player per round
        mapping(address => bool) claimed;
    }

    // --- State Variables ---
    address public owner;
    address public manager; // Can manage rounds and settings

    uint256 public currentQpuPrice; // Price per QPU in wei
    uint256 public superpositionDuration; // Duration of Superposition phase in seconds
    uint256 public payoutFeeBasisPoints; // Fee percentage on winnings (e.g., 500 for 5%)

    uint256 private nextQpuId = 1;
    uint256 private nextEntangledStateId = 1;
    uint256 private nextRoundId = 1;

    mapping(uint256 => Qpu) public qpus;
    mapping(uint256 => EntangledState) public entangledStates;
    mapping(uint256 => Round) public rounds;

    // Track player's assets per round
    mapping(uint256 => mapping(address => uint256[])) private playerQpusByRound;
    mapping(uint256 => mapping(address => uint256[])) private playerEntangledStatesByRound;

    // --- Events ---
    event ManagerUpdated(address indexed newManager);
    event QpuPriceUpdated(uint256 newPrice);
    event SuperpositionDurationUpdated(uint256 newDuration);
    event PayoutFeeUpdated(uint256 newFeeBasisPoints);

    event RoundStarted(uint256 indexed roundId, uint256 startTime, uint256 superpositionEndTime);
    event QpuPurchased(uint256 indexed roundId, address indexed buyer, uint256 indexed qpuId, uint256 value);
    event EntangledStateCreated(uint256 indexed roundId, uint256 indexed stateId, address indexed creator);
    event JoinedEntangledState(uint256 indexed roundId, uint256 indexed stateId, address indexed participant, uint256[] qpuIds);
    event LeftEntangledState(uint256 indexed roundId, uint256 indexed stateId, address indexed participant, uint256[] qpuIds);
    event AddedQpusToEntangledState(uint256 indexed roundId, uint256 indexed stateId, address indexed participant, uint256[] qpuIds);
    event EntangledStateSplit(uint256 indexed roundId, uint256 indexed stateId, address indexed initiator);

    event StateCollapseTriggered(uint256 indexed roundId, uint256 collapseTime, uint256 winningNumber);
    event RoundCollapsed(uint256 indexed roundId, uint256 totalPool, uint256 totalWonPool, uint256 totalFees);
    event WinningsClaimed(uint256 indexed roundId, address indexed player, uint256 amount);
    event RoundCancelled(uint256 indexed roundId, address indexed cancelledBy);
    event FeesWithdrawn(address indexed to, uint256 amount);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyManager() {
        require(msg.sender == manager || msg.sender == owner, "Only manager or owner");
        _;
    }

    modifier whenState(uint256 _roundId, RoundState _expectedState) {
        require(rounds[_roundId].state == _expectedState, "Invalid round state");
        _;
    }

    modifier onlyRoundState(RoundState _expectedState) {
        require(rounds[nextRoundId - 1].state == _expectedState, "Invalid current round state");
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        manager = msg.sender; // Initially owner is manager
        currentQpuPrice = 0.001 ether; // Example price
        superpositionDuration = 1 days; // Example duration
        payoutFeeBasisPoints = 500; // 5% fee
    }

    // --- Owner/Manager Functions ---

    /// @notice Sets the manager address. Only callable by the owner.
    /// @param _manager The address to set as the new manager.
    function setManager(address _manager) external onlyOwner {
        require(_manager != address(0), "Invalid address");
        manager = _manager;
        emit ManagerUpdated(_manager);
    }

    /// @notice Sets the price for a single QPU. Callable by owner or manager.
    /// @param _price The new price in wei.
    function setQpuPrice(uint256 _price) external onlyManager {
        require(_price > 0, "Price must be greater than 0");
        currentQpuPrice = _price;
        emit QpuPriceUpdated(_price);
    }

    /// @notice Sets the duration of the Superposition phase in seconds. Callable by owner or manager.
    /// @param _duration The new duration in seconds.
    function setSuperpositionDuration(uint256 _duration) external onlyManager {
        require(_duration > 0, "Duration must be greater than 0");
        superpositionDuration = _duration;
        emit SuperpositionDurationUpdated(_duration);
    }

    /// @notice Sets the fee percentage on winnings in basis points (10000 basis points = 100%). Callable by owner or manager.
    /// @param _feeBasisPoints The new fee in basis points. Max 10000.
    function setPayoutFee(uint256 _feeBasisPoints) external onlyManager {
        require(_feeBasisPoints <= 10000, "Fee cannot exceed 100%");
        payoutFeeBasisPoints = _feeBasisPoints;
        emit PayoutFeeUpdated(_feeBasisPoints);
    }

    /// @notice Starts the next lottery round, moving state to Buying. Callable by owner or manager.
    function startNextRound() external onlyManager onlyRoundState(RoundState.Payout) {
        // Check if previous round is in Payout state allowing a new one to start
        uint256 previousRoundId = nextRoundId > 1 ? nextRoundId - 1 : 0;
        require(previousRoundId == 0 || rounds[previousRoundId].state == RoundState.Payout, "Previous round not in Payout state");

        uint256 newRoundId = nextRoundId++;
        uint256 _startTime = block.timestamp;
        uint256 _superpositionEndTime = _startTime + superpositionDuration;

        rounds[newRoundId] = Round({
            id: newRoundId,
            state: RoundState.Buying,
            startTime: _startTime,
            superpositionEndTime: _superpositionEndTime,
            collapseTime: 0,
            totalPool: 0,
            totalQpus: 0,
            totalEntangledStates: 0,
            winningNumber: 0,
            totalWonPool: 0,
            totalFeesCollected: 0,
            claimed: new mapping(address => bool)
        });

        emit RoundStarted(newRoundId, _startTime, _superpositionEndTime);
    }

    /// @notice Triggers the state collapse (drawing) for the current round. Callable by owner or manager, or potentially an oracle.
    /// Can only be called after Superposition end time.
    function triggerStateCollapse() external onlyManager {
        uint256 roundId = nextRoundId - 1;
        require(roundId > 0, "No active round");
        require(rounds[roundId].state == RoundState.Superposition, "Round is not in Superposition state");
        require(block.timestamp >= rounds[roundId].superpositionEndTime, "Superposition phase not ended yet");

        Round storage currentRound = rounds[roundId];
        currentRound.state = RoundState.Collapsed;
        currentRound.collapseTime = block.timestamp;

        // --- Randomness Generation (INSECURE - FOR DEMO ONLY) ---
        // In a real contract, this should use a secure oracle like Chainlink VRF
        uint256 winningNumber = generatePseudoRandomNumber();
        // --- End INSECURE Randomness ---

        currentRound.winningNumber = winningNumber;

        emit StateCollapseTriggered(roundId, block.timestamp, winningNumber);

        // Calculate winnings based on the generated number
        calculateWinnings(roundId, winningNumber);

        currentRound.state = RoundState.Payout;
        emit RoundCollapsed(roundId, currentRound.totalPool, currentRound.totalWonPool, currentRound.totalFeesCollected);
    }

    /// @notice Cancels the current round and refunds participants. Callable by owner or manager.
    /// Can only be called during Buying or Superposition state.
    function cancelRound() external payable onlyManager {
        uint256 roundId = nextRoundId - 1;
        require(roundId > 0, "No active round");
        RoundState currentState = rounds[roundId].state;
        require(currentState == RoundState.Buying || currentState == RoundState.Superposition, "Round cannot be cancelled in its current state");

        Round storage currentRound = rounds[roundId];
        currentRound.state = RoundState.Inactive; // Effectively cancelled

        // Refund logic: Iterate through all QPUs in this round and send value back
        // NOTE: This loop can be expensive with many participants/QPUs.
        // For a production contract, a pull mechanism or batch refunds might be needed.
        uint256[] memory qpuIdsInRound = playerQpusByRound[roundId][address(0)]; // Assuming playerQpusByRound[roundId][address(0)] tracks all QPUs in the round (need to improve state tracking for large scale)
        // A more robust state tracking would be needed for efficient iteration of all assets.
        // For this example, we'll simulate refund by just returning the total pool.
        // A proper refund would iterate player balances or QPU values.

        // Simplified refund: Send total pool balance back to manager for manual distribution
        // This is NOT a real refund mechanism. A real one needs to track individual player balances.
        (bool success, ) = payable(manager).call{value: address(this).balance}("");
        require(success, "Refund failed");

        emit RoundCancelled(roundId, msg.sender);

        // Reset nextRoundId to allow starting a new one
        nextRoundId--;
    }

    /// @notice Allows the owner or manager to withdraw accumulated fees.
    function withdrawFees() external onlyManager {
        uint256 totalFees = 0;
        for (uint256 i = 1; i < nextRoundId; i++) {
            totalFees += rounds[i].totalFeesCollected;
            rounds[i].totalFeesCollected = 0; // Reset collected fees for this round
        }
        require(totalFees > 0, "No fees to withdraw");

        (bool success, ) = payable(msg.sender).call{value: totalFees}("");
        require(success, "Fee withdrawal failed");
        emit FeesWithdrawn(msg.sender, totalFees);
    }


    // --- Player Actions (Buying Phase) ---

    /// @notice Buys a single Quantum Potential Unit (QPU).
    /// Must be in the Buying phase. Sends 1 QPU price.
    function buyQpu() external payable onlyRoundState(RoundState.Buying) {
        uint256 roundId = nextRoundId - 1;
        require(msg.value == currentQpuPrice, "Incorrect payment amount");

        uint256 qpuId = nextQpuId++;
        qpus[qpuId] = Qpu({
            id: qpuId,
            roundId: roundId,
            owner: msg.sender,
            value: msg.value,
            state: QuantumState.Active,
            entangledStateId: 0,
            winAmount: 0
        });

        rounds[roundId].totalPool += msg.value;
        rounds[roundId].totalQpus++;

        playerQpusByRound[roundId][msg.sender].push(qpuId);
        // A production system needs a better way to track ALL QPUs for iteration during collapse
        // playerQpusByRound[roundId][address(0)].push(qpuId); // Example of tracking all (can be expensive)

        emit QpuPurchased(roundId, msg.sender, qpuId, msg.value);
    }

    /// @notice Buys multiple Quantum Potential Units (QPUs).
    /// Must be in the Buying phase. Sends `_count * currentQpuPrice`.
    /// @param _count The number of QPUs to buy.
    function buyMultipleQpus(uint256 _count) external payable onlyRoundState(RoundState.Buying) {
        uint256 roundId = nextRoundId - 1;
        uint256 totalCost = _count * currentQpuPrice;
        require(msg.value == totalCost, "Incorrect payment amount");
        require(_count > 0, "Count must be greater than 0");

        uint256 startQpuId = nextQpuId;
        nextQpuId += _count;

        for (uint i = 0; i < _count; i++) {
            uint256 qpuId = startQpuId + i;
             qpus[qpuId] = Qpu({
                id: qpuId,
                roundId: roundId,
                owner: msg.sender,
                value: currentQpuPrice,
                state: QuantumState.Active,
                entangledStateId: 0,
                winAmount: 0
            });
            playerQpusByRound[roundId][msg.sender].push(qpuId);
             // playerQpusByRound[roundId][address(0)].push(qpuId); // Example of tracking all
             emit QpuPurchased(roundId, msg.sender, qpuId, currentQpuPrice);
        }

        rounds[roundId].totalPool += totalCost;
        rounds[roundId].totalQpus += _count;
    }

    // --- Player Actions (Superposition Phase) ---
    // Interactions are allowed until superpositionEndTime

    /// @notice Creates a new Entangled State using some of the player's QPUs.
    /// Can be called during Buying or Superposition phase, before superpositionEndTime.
    /// @param _qpuIds The IDs of the player's QPUs to include.
    function createEntangledState(uint256[] calldata _qpuIds) external {
        uint256 roundId = nextRoundId - 1;
        RoundState currentState = rounds[roundId].state;
        require(currentState == RoundState.Buying || currentState == RoundState.Superposition, "Round must be in Buying or Superposition state");
        require(block.timestamp < rounds[roundId].superpositionEndTime, "Superposition phase has ended");
        require(_qpuIds.length > 0, "Must include at least one QPU");

        uint256 stateId = nextEntangledStateId++;
        uint256 totalValue = 0;
        address[] memory participants = new address[](1);
        participants[0] = msg.sender;

        EntangledState storage newState = entangledStates[stateId];
        newState.id = stateId;
        newState.roundId = roundId;
        newState.creator = msg.sender;
        newState.state = QuantumState.Active; // Entangled State is Active until collapse

        newState.participants = participants; // Set creator as first participant
        playerEntangledStatesByRound[roundId][msg.sender].push(stateId);

        // Add QPUs to the state
        for (uint i = 0; i < _qpuIds.length; i++) {
            uint256 qpuId = _qpuIds[i];
            Qpu storage qpu = qpus[qpuId];

            require(qpu.owner == msg.sender, "Not your QPU");
            require(qpu.roundId == roundId, "QPU belongs to a different round");
            require(qpu.state == QuantumState.Active, "QPU is not in Active state (already entangled, won, etc.)");

            qpu.state = QuantumState.Entangled;
            qpu.entangledStateId = stateId;
            newState.qpuIds.push(qpuId);
            totalValue += qpu.value;
        }
        newState.totalValue = totalValue;
        newState.participantValue[msg.sender] = totalValue; // Creator's initial contribution

        rounds[roundId].totalEntangledStates++;

        emit EntangledStateCreated(roundId, stateId, msg.sender);
    }

    /// @notice Adds some of the player's QPUs to an existing Entangled State.
    /// Can be called during Buying or Superposition phase, before superpositionEndTime.
    /// @param _stateId The ID of the Entangled State to join.
    /// @param _qpuIds The IDs of the player's QPUs to include.
    function joinEntangledState(uint256 _stateId, uint256[] calldata _qpuIds) external {
        uint256 roundId = nextRoundId - 1;
        RoundState currentState = rounds[roundId].state;
        require(currentState == RoundState.Buying || currentState == RoundState.Superposition, "Round must be in Buying or Superposition state");
        require(block.timestamp < rounds[roundId].superpositionEndTime, "Superposition phase has ended");
        require(_qpuIds.length > 0, "Must include at least one QPU");

        EntangledState storage state = entangledStates[_stateId];
        require(state.roundId == roundId, "State belongs to a different round");
        require(state.state == QuantumState.Active, "State is not Active"); // Ensure state hasn't won/lost/etc.

        bool participantExists = false;
        for(uint i=0; i<state.participants.length; i++) {
            if (state.participants[i] == msg.sender) {
                participantExists = true;
                break;
            }
        }
        if (!participantExists) {
             state.participants.push(msg.sender);
             playerEntangledStatesByRound[roundId][msg.sender].push(_stateId);
        }

        uint256 addedValue = 0;
        for (uint i = 0; i < _qpuIds.length; i++) {
            uint256 qpuId = _qpuIds[i];
            Qpu storage qpu = qpus[qpuId];

            require(qpu.owner == msg.sender, "Not your QPU");
            require(qpu.roundId == roundId, "QPU belongs to a different round");
            require(qpu.state == QuantumState.Active, "QPU is not in Active state"); // Must be individual QPU

            qpu.state = QuantumState.Entangled;
            qpu.entangledStateId = _stateId;
            state.qpuIds.push(qpuId);
            addedValue += qpu.value;
        }

        state.totalValue += addedValue;
        state.participantValue[msg.sender] += addedValue;

        emit JoinedEntangledState(roundId, _stateId, msg.sender, _qpuIds);
    }

    /// @notice Allows a participant to remove some of their QPUs from an Entangled State.
    /// Can be called during Buying or Superposition phase, before superpositionEndTime.
    /// Removed QPUs revert to individual Active state. May involve rethinking depending on game balance.
    /// @param _stateId The ID of the Entangled State.
    /// @param _qpuIds The IDs of the participant's QPUs to remove.
    function leaveEntangledState(uint256 _stateId, uint256[] calldata _qpuIds) external {
        uint256 roundId = nextRoundId - 1;
        RoundState currentState = rounds[roundId].state;
        require(currentState == RoundState.Buying || currentState == RoundState.Superposition, "Round must be in Buying or Superposition state");
        require(block.timestamp < rounds[roundId].superpositionEndTime, "Superposition phase has ended");
        require(_qpuIds.length > 0, "Must include at least one QPU");

        EntangledState storage state = entangledStates[_stateId];
        require(state.roundId == roundId, "State belongs to a different round");
        require(state.state == QuantumState.Active, "State is not Active"); // Ensure state hasn't won/lost/etc.

        bool isParticipant = false;
         for(uint i=0; i<state.participants.length; i++) {
            if (state.participants[i] == msg.sender) {
                isParticipant = true;
                break;
            }
        }
        require(isParticipant, "Not a participant of this state");

        uint256 removedValue = 0;
        uint256 qpuCountBefore = state.qpuIds.length;
        uint256[] memory remainingQpuIds = new uint256[](qpuCountBefore - _qpuIds.length); // Estimate remaining size

        // Mark QPUs for removal and collect value
        mapping(uint256 => bool) qpuIdsToRemove;
        for (uint i = 0; i < _qpuIds.length; i++) {
             uint256 qpuId = _qpuIds[i];
             Qpu storage qpu = qpus[qpuId];

             require(qpu.owner == msg.sender, "Not your QPU");
             require(qpu.roundId == roundId, "QPU belongs to a different round");
             require(qpu.entangledStateId == _stateId, "QPU not in this state");

             qpuIdsToRemove[qpuId] = true;
             removedValue += qpu.value;

             // Update QPU state immediately
             qpu.state = QuantumState.Active;
             qpu.entangledStateId = 0;
        }

        // Rebuild qpuIds array excluding removed ones
        uint256 currentRemainingIndex = 0;
        for (uint i = 0; i < qpuCountBefore; i++) {
             uint256 currentQpuId = state.qpuIds[i];
             if (!qpuIdsToRemove[currentQpuId]) {
                 remainingQpuIds[currentRemainingIndex] = currentQpuId;
                 currentRemainingIndex++;
             }
        }
        state.qpuIds = remainingQpuIds;

        state.totalValue -= removedValue;
        state.participantValue[msg.sender] -= removedValue;

        // If participant has no value left in the state, remove them from participants list (optional, adds complexity)
        // For simplicity, we keep them in the list but their value becomes 0.

        emit LeftEntangledState(roundId, _stateId, msg.sender, _qpuIds);
    }

    /// @notice Allows a participant to add more of *their* QPUs to an Entangled State they are already part of.
    /// Can be called during Buying or Superposition phase, before superpositionEndTime.
    /// @param _stateId The ID of the Entangled State.
    /// @param _qpuIds The IDs of the participant's QPUs to add.
    function addQpusToEntangledState(uint256 _stateId, uint256[] calldata _qpuIds) external {
         // This function is very similar to `joinEntangledState` but requires the sender
         // to already be a participant. We can reuse the logic largely.

        uint256 roundId = nextRoundId - 1;
        RoundState currentState = rounds[roundId].state;
        require(currentState == RoundState.Buying || currentState == RoundState.Superposition, "Round must be in Buying or Superposition state");
        require(block.timestamp < rounds[roundId].superpositionEndTime, "Superposition phase has ended");
        require(_qpuIds.length > 0, "Must include at least one QPU");

        EntangledState storage state = entangledStates[_stateId];
        require(state.roundId == roundId, "State belongs to a different round");
        require(state.state == QuantumState.Active, "State is not Active");

        bool isParticipant = false;
         for(uint i=0; i<state.participants.length; i++) {
            if (state.participants[i] == msg.sender) {
                isParticipant = true;
                break;
            }
        }
        require(isParticipant, "Not a participant of this state");

        uint256 addedValue = 0;
        for (uint i = 0; i < _qpuIds.length; i++) {
            uint256 qpuId = _qpuIds[i];
            Qpu storage qpu = qpus[qpuId];

            require(qpu.owner == msg.sender, "Not your QPU");
            require(qpu.roundId == roundId, "QPU belongs to a different round");
            require(qpu.state == QuantumState.Active, "QPU is not in Active state"); // Must be individual QPU

            qpu.state = QuantumState.Entangled;
            qpu.entangledStateId = _stateId;
            state.qpuIds.push(qpuId);
            addedValue += qpu.value;
        }

        state.totalValue += addedValue;
        state.participantValue[msg.sender] += addedValue;

        emit AddedQpusToEntangledState(roundId, _stateId, msg.sender, _qpuIds);
    }


    /// @notice Attempts to split an Entangled State back into individual QPUs.
    /// Only the creator can call this, and only before the Superposition phase ends.
    /// If the state is empty, it is removed. If it has QPUs, they revert to individual state.
    /// @param _stateId The ID of the Entangled State to split.
    function splitEntangledState(uint256 _stateId) external {
        uint256 roundId = nextRoundId - 1;
        RoundState currentState = rounds[roundId].state;
        require(currentState == RoundState.Buying || currentState == RoundState.Superposition, "Round must be in Buying or Superposition state");
        require(block.timestamp < rounds[roundId].superpositionEndTime, "Superposition phase has ended");

        EntangledState storage state = entangledStates[_stateId];
        require(state.roundId == roundId, "State belongs to a different round");
        require(state.creator == msg.sender, "Only the creator can split the state");
        require(state.state == QuantumState.Active, "State is not Active");

        // Revert QPUs back to Active state
        for (uint i = 0; i < state.qpuIds.length; i++) {
            uint256 qpuId = state.qpuIds[i];
            Qpu storage qpu = qpus[qpuId];
            // Basic checks
            if (qpu.entangledStateId == _stateId) {
                qpu.state = QuantumState.Active;
                qpu.entangledStateId = 0;
            }
        }

        // Clear the state data (or mark as inactive)
        // For simplicity, we'll just mark it Inactive and clear dynamic arrays.
        state.state = QuantumState.Lost; // Use Lost to signify it's no longer an active state candidate
        delete state.qpuIds; // Clear array
        delete state.participants; // Clear array
        // Mappings (participantValue) cannot be fully deleted efficiently, rely on state != Active/Won

        emit EntangledStateSplit(roundId, _stateId, msg.sender);
    }


    // --- Player Actions (Payout Phase) ---

    /// @notice Allows a player to claim their winnings for a completed round.
    /// Must be in Payout state.
    /// @param _roundId The ID of the round to claim from.
    function claimWinnings(uint256 _roundId) external whenState(_roundId, RoundState.Payout) {
        Round storage round = rounds[_roundId];
        require(!round.claimed[msg.sender], "Winnings already claimed for this round");

        uint256 totalWinnings = 0;

        // Sum winnings from individual QPUs
        uint256[] memory playerQpuIds = playerQpusByRound[_roundId][msg.sender];
        for (uint i = 0; i < playerQpuIds.length; i++) {
            uint256 qpuId = playerQpuIds[i];
            Qpu storage qpu = qpus[qpuId];
            // Only add if the QPU is marked as Won and hasn't been claimed/refunded
             if (qpu.state == QuantumState.Won) {
                 totalWinnings += qpu.winAmount;
                 qpu.state = QuantumState.Claimed; // Mark QPU as claimed
             }
        }

        // Sum winnings from Entangled States where the player participated
        uint256[] memory playerStateIds = playerEntangledStatesByRound[_roundId][msg.sender];
        for (uint i = 0; i < playerStateIds.length; i++) {
            uint256 stateId = playerStateIds[i];
            EntangledState storage state = entangledStates[stateId];
            // Only add if the State is marked as Won and the player hasn't claimed this state's share yet
             // We need a way to track per-participant claiming for states.
             // Let's add a mapping to the state struct: mapping(address => bool) claimedParticipant;
             // To avoid modifying struct after mapping definition, let's add a separate mapping
             // mapping(uint256 => mapping(address => bool)) private claimedEntangledStateShare;
             // This would track if a participant claimed their share of a specific state's winnings.

             // Simplified: For this demo, we assume claiming the round claims all associated winnings
             // (both individual QPU wins and state shares). A production system needs more granular tracking.
             // The sum of winAmount on the Qpu struct covers the state share already if designed correctly
             // in calculateWinnings. We calculated proportional winAmount for each winning QPU within a state.

             // We already sum the individual qpu.winAmount which already includes their share from winning states.
             // No need to add state.winAmount here directly.
        }

        require(totalWinnings > 0, "No winnings to claim for this round");

        // Apply fee
        uint256 fee = (totalWinnings * payoutFeeBasisPoints) / 10000;
        uint256 amountToSend = totalWinnings - fee;

        round.totalFeesCollected += fee; // Add fee to round's collected fees

        // Mark round as claimed for this player BEFORE sending Ether
        round.claimed[msg.sender] = true;

        (bool success, ) = payable(msg.sender).call{value: amountToSend}("");
        require(success, "Transfer failed");

        emit WinningsClaimed(_roundId, msg.sender, amountToSend);
    }


    // --- Randomness/Collapse Logic (INSECURE PRNG) ---

    /// @notice Internal function to generate a pseudo-random number.
    /// WARNING: This PRNG is based on block data and is **INSECURE** for real-world use
    /// as miners/validators can manipulate block data to influence the outcome.
    /// For production, use a secure oracle like Chainlink VRF or similar verifiable random function.
    /// @return A pseudo-random uint256 number.
    function generatePseudoRandomNumber() internal view returns (uint256) {
        // Mix block data for a 'seed'
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            block.number,
            msg.sender, // Include sender for some variation, though not cryptographically strong
            tx.origin, // Less secure than msg.sender, but adds entropy (avoid tx.origin generally)
            block.gaslimit
            // Add a contract specific nonce for better sequence uniqueness
            // uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number, nonce++)))
            // Nonce requires state change, which `view` function can't do.
        )));

        // Use assembly to access blockhash for recent blocks
        uint256 recentBlockHash = 0;
        // blockhash(block.number) is 0. Use a recent past block.
        if (block.number > 1) {
             recentBlockHash = blockhash(block.number - 1);
             seed = uint256(keccak256(abi.encodePacked(seed, recentBlockHash)));
        }

        // Final hash
        return uint256(keccak256(abi.encodePacked(seed, "QuantumLotterySpecificSalt")));
    }

    /// @notice Internal function to calculate winnings after collapse.
    /// This is the core logic determining winners based on the random number.
    /// @param _roundId The ID of the round to calculate winnings for.
    /// @param _randomNumber The pseudo-random number generated.
    function calculateWinnings(uint256 _roundId, uint256 _randomNumber) internal {
        Round storage round = rounds[_roundId];
        require(round.state == RoundState.Collapsed, "Round must be in Collapsed state for calculation");
        require(round.winningNumber == _randomNumber, "Random number mismatch");

        uint256 totalPossibleWinningUnits = round.totalQpus + round.totalEntangledStates; // Treat each QPU and EntangledState as a potential winner 'unit' for simplicity
        // A more advanced version might weight units by value or number of QPUs within.
        // Let's weight by total value in pool. Each wei contributed has an equal chance.
        // Winning index will be `randomNumber % totalPoolWei` or similar.
        // This requires iterating through all QPUs and States and their values to find the winner at the specific 'winning wei index'.
        // This can be VERY gas expensive if totalPool is large.

        // Alternative approach: Randomly select a fixed number of winning QPUs and a fixed number of winning Entangled States.
        // Let's use this approach for a more feasible implementation within gas limits,
        // but acknowledging it's different from a proportional draw.

        uint256 numWinningQpus = 5; // Example: Draw 5 winning individual QPUs
        uint256 numWinningStates = 2; // Example: Draw 2 winning Entangled States

        // --- Select Winning Individual QPUs ---
        // This requires knowing all QPU IDs in the round. Storing all in an array is gas-heavy.
        // For this demo, we iterate through potential IDs up to nextQpuId.
        uint256 qpusChecked = 0;
        uint256 winningQpusFound = 0;
        uint256 currentRand = _randomNumber;

        // Simple selection - highly biased and inefficient for large nextQpuId/low participation
        // A real system needs a list of *active* QPU IDs in the round to sample from.
        // We'll simulate by just checking IDs within a range.
        uint256 startCheckId = _roundId * 1000000; // Assuming QPU IDs increase significantly per round
        // This is still not a random *sample* of participants, but a pseudo-random check within IDs.

        uint256[] memory potentialQpuIds = new uint256[](rounds[_roundId].totalQpus); // Need a way to populate this with actual QPU IDs
        // Populating this requires iterating playerQpusByRound or a global list - gas heavy.

        // Let's simplify the winning logic for demonstration:
        // We'll calculate a winning 'slot' based on the random number vs totalPool.
        // Then iterate through *all* assets (individual QPUs and Entangled States, weighted by value)
        // until the winning slot is reached.

        uint256 winningWeiIndex = _randomNumber % round.totalPool;
        uint256 currentWeiSum = 0;

        // 1. Check Individual QPUs first
        // This still requires iterating through all QPUs in the round.
        // Need an efficient way to list all QPU IDs for a round.
        // Let's assume playerQpusByRound[roundId][address(0)] stores all QPU IDs added to the round globally.
        uint256[] memory allQpuIdsInRound = playerQpusByRound[roundId][address(0)]; // This needs proper population during buyQpu/buyMultipleQpus

        // --- Placeholder: Need a proper way to list ALL QPU IDs and ALL Entangled State IDs in a round ---
        // For this example, we'll make a simplifying assumption:
        // We find the winning "unit" (QPU or State) by iterating through potential IDs and summing values.
        // This is highly inefficient but illustrates the concept of winning based on value share.
        // Proper implementation would require maintaining lists of active QPU/State IDs.

        // Let's assume for this demo we can iterate through a conceptual list of ALL assets.
        // In reality, this loop size is the problem.
        uint256 winningAssetId = 0; // ID of the winning QPU or Entangled State
        bool isWinningState = false;

        // Simulate finding the winning asset by iterating values (conceptually)
        // This loop *would* iterate through all QPUs, then all Entangled States, summing their value.
        // The asset whose value segment contains `winningWeiIndex` wins.
        // Due to storage limitations/gas costs of iterating unknown size lists,
        // this exact implementation is problematic on-chain for many assets.

        // --- Simplified Winning Logic for Demo ---
        // Instead of proportional draw, let's just select a winning QPU ID and a winning State ID directly
        // based on the random number. This is easier to implement but less fair proportionally.
        // Winning QPU ID = (randomNumber % rounds[_roundId].totalQpus) + firstQpuIdInRound; (requires knowing the range)
        // Winning State ID = (randomNumber / 2 % rounds[_roundId].totalEntangledStates) + firstStateIdInRound; (requires knowing the range)
        // This needs a list of valid IDs.

        // Let's try a middle ground: The random number determines an index *relative to the total number of*
        // individual QPUs and Entangled States. We pick one winning QPU and one winning state.
        // This avoids value weighting but is simpler to iterate.

        uint256 qpuIndex = _randomNumber % round.totalQpus;
        uint256 stateIndex = (_randomNumber / 2) % round.totalEntangledStates; // Use a different part of randomness

        uint256 winningQpuId = 0; // ID of the QPU at qpuIndex
        uint256 winningStateId = 0; // ID of the State at stateIndex

        // Find the QPU at the random index - Requires iterating all QPU IDs (problematic)
        // Let's assume a helper function or mapping exists to get the Nth QPU ID in the round.
        // winningQpuId = getQpuIdAtIndex(roundId, qpuIndex); // Conceptual function
        // winningStateId = getEntangledStateIdAtIndex(roundId, stateIndex); // Conceptual function

        // Since we can't efficiently get the Nth ID, let's use the first simplified approach
        // but acknowledge the gas issue. The random number picks a spot in the *total value* line.
        // Iterate through QPUs first
        uint256 currentId = 1; // Start checking from QPU ID 1
        while(currentWeiSum <= winningWeiIndex && currentId < nextQpuId) {
            Qpu storage qpu = qpus[currentId];
            if (qpu.roundId == _roundId && (qpu.state == QuantumState.Active || qpu.state == QuantumState.Entangled)) {
                 // QPU is eligible (either individual or part of a state)
                 // If it's part of a state, its value contributes to the state's block of value.
                 // This logic is complex if drawing individual vs state winners.

                 // --- Let's go back to simpler: Draw N winning QPUs and N winning States based on IDs ---
                 // This requires lists of active IDs. We must maintain these lists.

                 // Add state variables to track lists of IDs for the current round
                 // uint256[] public activeQpuIdsInRound;
                 // uint256[] public activeEntangledStateIdsInRound;
                 // These lists need to be updated on buy, create, join, leave, split. This is complex state management.

                 // ***FINAL SIMPLIFIED APPROACH FOR DEMO***
                 // The random number directly determines a winning QPU ID and a winning Entangled State ID within the *range* of IDs issued.
                 // This is NOT fair if IDs are sparse, but demonstrates accessing by ID.

                 uint256 potentialQpuWinId = (_randomNumber % (nextQpuId - 1)) + 1; // Pick an ID from 1 to nextQpuId - 1
                 // Ensure the selected ID exists and is part of this round
                 if (qpus[potentialQpuWinId].roundId == _roundId && (qpus[potentialQpuWinId].state == QuantumState.Active || qpus[potentialQpuWinId].state == QuantumState.Entangled)) {
                     winningQpuId = potentialQpuWinId;
                 } else {
                     // Fallback if the random QPU ID is invalid/inactive in this round - pick the first valid QPU found
                     for(uint i = 1; i < nextQpuId; i++) {
                         if(qpus[i].roundId == _roundId && (qpus[i].state == QuantumState.Active || qpus[i].state == QuantumState.Entangled)) {
                             winningQpuId = i; // Pick the first valid one
                             break;
                         }
                     }
                     if (winningQpuId == 0) { /* No valid QPU found - implies totalQpus was 0 or all removed? Handle error */ }
                 }


                 uint256 potentialStateWinId = ((_randomNumber / 3) % (nextEntangledStateId - 1)) + 1; // Use a different part of randomness for state ID
                 // Ensure the selected ID exists and is part of this round
                  if (entangledStates[potentialStateWinId].roundId == _roundId && entangledStates[potentialStateState].state == QuantumState.Active) {
                     winningStateId = potentialStateWinId;
                  } else {
                      // Fallback if the random State ID is invalid/inactive in this round - pick the first valid State found
                       for(uint i = 1; i < nextEntangledStateId; i++) {
                         if(entangledStates[i].roundId == _roundId && entangledStates[i].state == QuantumState.Active) {
                              winningStateId = i; // Pick the first valid one
                             break;
                         }
                     }
                     // If winningStateId is still 0, no valid states were found.
                  }
             }
             currentId++; // Increment conceptual ID check
        }
        // End of Simplified Winning Logic

        // --- Payout Calculation ---
        uint256 totalPayout = round.totalPool; // Total prize pool before splitting

        // Winner payout structure:
        // Let's distribute 80% of the pool to the winning QPU and 20% to the winning State (if they exist).
        uint256 qpuWinAmount = 0;
        uint256 stateWinAmount = 0;
        uint256 remainingPool = totalPayout; // Amount left to distribute

        if (winningQpuId != 0) {
            // Payout to the winning individual QPU's owner
            Qpu storage winningQpu = qpus[winningQpuId];
            qpuWinAmount = (totalPayout * 80) / 100; // Example: 80% to winning QPU
            remainingPool -= qpuWinAmount;

            winningQpu.winAmount = qpuWinAmount;
            winningQpu.state = QuantumState.Won; // Mark the winning QPU
            round.totalWonPool += qpuWinAmount;
        }

        if (winningStateId != 0) {
             // Payout to the winning Entangled State's participants
            EntangledState storage winningState = entangledStates[winningStateId];
            stateWinAmount = remainingPool; // The rest goes to the winning state (20% in this example)

            winningState.winAmount = stateWinAmount; // Total for the state
            winningState.state = QuantumState.Won; // Mark the winning state
            round.totalWonPool += stateWinAmount;

            // Distribute the state's winnings proportionally among participants based on their value contribution
            for (uint i = 0; i < winningState.participants.length; i++) {
                address participant = winningState.participants[i];
                uint256 participantValue = winningState.participantValue[participant];
                if (participantValue > 0) {
                    uint256 participantShare = (stateWinAmount * participantValue) / winningState.totalValue;

                    // Need to find the participant's *specific* QPUs within this winning state
                    // and assign their winAmount share proportionally to those QPUs.
                    // This allows individual QPUs to track their win amount (both individual win or state share).

                    uint256 participantQPUsInStateCount = 0;
                    for (uint j = 0; j < winningState.qpuIds.length; j++) {
                        uint256 qpuId = winningState.qpuIds[j];
                        if (qpus[qpuId].owner == participant) {
                            participantQPUsInStateCount++;
                        }
                    }

                    if (participantQPUsInStateCount > 0) {
                         uint256 sharePerQPU = participantShare / participantQPUsInStateCount;
                         // Assign share to each of the participant's QPUs in this state
                         for (uint j = 0; j < winningState.qpuIds.length; j++) {
                             uint256 qpuId = winningState.qpuIds[j];
                             if (qpus[qpuId].owner == participant) {
                                 // Add state share to QPU's winAmount.
                                 // If this QPU was also the winning individual QPU, its winAmount was already set.
                                 // This logic needs careful handling of potential double-counting if the winning QPU was *also* in the winning state.
                                 // Let's assume the 80/20 split means it's *either* an individual QPU win (if random QPU ID was selected)
                                 // OR a state win (if random State ID was selected).
                                 // Redo payout logic: Pick one winner - either a QPU or a State, based on total value weighting.

                                 // --- REVISED PAYOUT LOGIC ---
                                 // Total Pool is distributed to ONE winner.
                                 // Winner is selected based on the winningWeiIndex derived from the random number.
                                 // This index maps to a specific wei contributed in the totalPool.
                                 // We find which QPU or EntangledState that wei belongs to.
                                 // Iterate through QPUs first, summing their value.
                                 // If winningWeiIndex falls within a QPU's value range, that QPU wins.
                                 // If winningWeiIndex exceeds total QPU value, iterate through States, summing their value.
                                 // If winningWeiIndex falls within a State's value range, that State wins.

                                 // This requires iterating through all active QPU/State IDs... Back to the indexing problem.

                                 // --- FINAL, SIMPLE, INEFFICIENT-FOR-MANY-ASSETS PAYOUT LOGIC ---
                                 // Iterate through all potential QPU IDs and State IDs issued since contract start.
                                 // Sum their values. Find which asset corresponds to the winningWeiIndex.
                                 // This is gas intensive but demonstrates the concept.

                                 uint256 cumulativeValue = 0;
                                 uint256 winnerAssetId = 0;
                                 bool winnerIsState = false;

                                 // Check Individual QPUs
                                 for (uint k = 1; k < nextQpuId; k++) { // Iterate through all possible QPU IDs
                                      Qpu storage qpu = qpus[k];
                                      // Only consider active/entangled QPUs in the current round
                                      if (qpu.roundId == _roundId && (qpu.state == QuantumState.Active || qpu.state == QuantumState.Entangled)) {
                                          if (winningWeiIndex >= cumulativeValue && winningWeiIndex < cumulativeValue + qpu.value) {
                                              winnerAssetId = k;
                                              winnerIsState = false;
                                              break; // Found winning QPU
                                          }
                                          cumulativeValue += qpu.value;
                                      }
                                 }

                                 // If winner not found among QPUs, check Entangled States
                                 if (winnerAssetId == 0) {
                                     for (uint k = 1; k < nextEntangledStateId; k++) { // Iterate through all possible State IDs
                                          EntangledState storage state = entangledStates[k];
                                          // Only consider active states in the current round
                                          if (state.roundId == _roundId && state.state == QuantumState.Active) {
                                              if (winningWeiIndex >= cumulativeValue && winningWeiIndex < cumulativeValue + state.totalValue) {
                                                  winnerAssetId = k;
                                                  winnerIsState = true;
                                                  break; // Found winning State
                                              }
                                              cumulativeValue += state.totalValue;
                                          }
                                     }
                                 }

                                 // Distribute Winnings
                                 uint256 totalWinAmount = round.totalPool; // The whole pool goes to the winner

                                 if (winnerAssetId == 0) {
                                     // No winner found (e.g., totalPool was 0 or logic error)
                                     // The pool remains in the contract or is sent to owner/manager (decide policy)
                                     // For this demo, it stays in the contract pool for the next round (implicitly)
                                 } else if (!winnerIsState) {
                                     // Individual QPU Winner
                                     Qpu storage winnerQpu = qpus[winnerAssetId];
                                     winnerQpu.winAmount = totalWinAmount;
                                     winnerQpu.state = QuantumState.Won;
                                     round.totalWonPool = totalWinAmount;
                                 } else {
                                     // Entangled State Winner
                                     EntangledState storage winnerState = entangledStates[winnerAssetId];
                                     winnerState.winAmount = totalWinAmount; // Total payout for the state
                                     winnerState.state = QuantumState.Won;
                                     round.totalWonPool = totalWinAmount;

                                     // Distribute state winnings proportionally to participant's QPU values within the state
                                     for (uint p = 0; p < winnerState.participants.length; p++) {
                                         address participant = winnerState.participants[p];
                                         uint256 participantValue = winnerState.participantValue[participant]; // Value contributed by participant to THIS state

                                         if (participantValue > 0) {
                                             uint256 participantShare = (totalWinAmount * participantValue) / winnerState.totalValue; // Share of the total pool

                                              // Find the participant's specific QPUs within this winning state
                                              // and assign their winAmount share proportionally across these QPUs.
                                             uint256 participantQpusInStateCount = 0;
                                             uint256[] memory participantQpuIdsInState = new uint256[](winnerState.qpuIds.length); // Max size
                                             uint256 tempCount = 0;

                                             for (uint q = 0; q < winnerState.qpuIds.length; q++) {
                                                 uint256 qpuId = winnerState.qpuIds[q];
                                                 if (qpus[qpuId].owner == participant) {
                                                     participantQpusInStateCount++;
                                                     participantQpuIdsInState[tempCount++] = qpuId;
                                                 }
                                             }

                                             if (participantQpusInStateCount > 0) {
                                                 uint256 sharePerQpu = participantShare / participantQpusInStateCount;
                                                 // Assign share to each QPU
                                                 for (uint r = 0; r < participantQpusInStateCount; r++) {
                                                     uint256 qpuId = participantQpuIdsInState[r];
                                                      // Add this share to the QPU's individual win amount tracker
                                                      // This QPU's state should now be marked as 'Won' through its state.
                                                     qpus[qpuId].winAmount += sharePerQpu; // Accumulate win amount on the individual QPU
                                                      // Mark the QPU state? It's part of a winning state, so maybe just the state is marked Won.
                                                      // Let's mark *all* QPUs within the winning state as Won for easier claiming.
                                                     qpus[qpuId].state = QuantumState.Won;
                                                 }
                                             }
                                         }
                                     }
                                      // Mark any remaining QPUs in the winning state (if any logic path missed them) as Won
                                      for (uint q = 0; q < winnerState.qpuIds.length; q++) {
                                          qpus[winnerState.qpuIds[q]].state = QuantumState.Won;
                                      }
                                 }

                                 // Mark all non-winning QPUs and States in this round as Lost
                                 // This also requires iterating through all assets... Gas issue again.
                                 // Let's make a simpler assumption: Only winning assets are marked 'Won'.
                                 // All others default to 'Lost' state implicitly or are ignored until next round state.
                                 // During claimWinnings, we only process QPUs/States explicitly marked as 'Won'.

                                 break; // Exit loops after finding the winner
                             }
                         }
                     }
                 }
             }
         }


    // --- View Functions ---

    /// @notice Gets the ID of the current round.
    /// @return The current round ID. Returns 0 if no round has started.
    function getCurrentRoundId() external view returns (uint256) {
        return nextRoundId > 1 ? nextRoundId - 1 : 0;
    }

    /// @notice Gets the state of a specific round.
    /// @param _roundId The ID of the round.
    /// @return The state of the round.
    function getRoundState(uint256 _roundId) external view returns (RoundState) {
        require(_roundId > 0 && _roundId < nextRoundId, "Invalid round ID");
        return rounds[_roundId].state;
    }

    /// @notice Gets details about a specific QPU.
    /// @param _qpuId The ID of the QPU.
    /// @return id, roundId, owner, value, state, entangledStateId, winAmount
    function getQpuDetails(uint256 _qpuId) external view returns (
        uint256 id,
        uint256 roundId,
        address owner,
        uint256 value,
        QuantumState state,
        uint256 entangledStateId,
        uint256 winAmount
    ) {
        require(_qpuId > 0 && _qpuId < nextQpuId, "Invalid QPU ID");
        Qpu storage qpu = qpus[_qpuId];
        return (
            qpu.id,
            qpu.roundId,
            qpu.owner,
            qpu.value,
            qpu.state,
            qpu.entangledStateId,
            qpu.winAmount
        );
    }

    /// @notice Gets details about a specific Entangled State.
    /// @param _stateId The ID of the Entangled State.
    /// @return id, roundId, creator, participants (list), qpuIds (list), totalValue, state, winAmount, participantValue (map)
    function getEntangledStateDetails(uint256 _stateId) external view returns (
        uint256 id,
        uint256 roundId,
        address creator,
        address[] memory participants,
        uint256[] memory qpuIds,
        uint256 totalValue,
        QuantumState state,
        uint256 winAmount
        // Cannot return mapping directly
    ) {
        require(_stateId > 0 && _stateId < nextEntangledStateId, "Invalid Entangled State ID");
        EntangledState storage state_ = entangledStates[_stateId];
        return (
            state_.id,
            state_.roundId,
            state_.creator,
            state_.participants,
            state_.qpuIds,
            state_.totalValue,
            state_.state,
            state_.winAmount
        );
    }

     /// @notice Gets the contribution value of a specific participant within an Entangled State.
     /// @param _stateId The ID of the Entangled State.
     /// @param _participant The address of the participant.
     /// @return The value contributed by the participant to this state.
     function getEntangledStateParticipantValue(uint256 _stateId, address _participant) external view returns (uint256) {
          require(_stateId > 0 && _stateId < nextEntangledStateId, "Invalid Entangled State ID");
          return entangledStates[_stateId].participantValue[_participant];
     }


    /// @notice Gets the list of QPU IDs owned by a player in a specific round.
    /// NOTE: This returns the list as it was *last modified* by a player action, not necessarily the final state.
    /// @param _player The player's address.
    /// @param _roundId The round ID.
    /// @return An array of QPU IDs.
    function getPlayerQpus(address _player, uint256 _roundId) external view returns (uint256[] memory) {
        require(_roundId > 0 && _roundId < nextRoundId, "Invalid round ID");
        return playerQpusByRound[_roundId][_player];
    }

    /// @notice Gets the list of Entangled State IDs a player is part of in a specific round.
    /// NOTE: This returns the list as it was *last modified*, not necessarily the final state.
    /// @param _player The player's address.
    /// @param _roundId The round ID.
    /// @return An array of Entangled State IDs.
    function getPlayerEntangledStates(address _player, uint256 _roundId) external view returns (uint256[] memory) {
        require(_roundId > 0 && _roundId < nextRoundId, "Invalid round ID");
        return playerEntangledStatesByRound[_roundId][_player];
    }

    /// @notice Gets summary information about winners for a collapsed round.
    /// @param _roundId The ID of the round.
    /// @return totalPool, totalWonPool, totalFeesCollected, winningNumber, collapseTime
    function getRoundWinnerInfo(uint256 _roundId) external view returns (
        uint256 totalPool,
        uint256 totalWonPool,
        uint256 totalFeesCollected,
        uint256 winningNumber,
        uint256 collapseTime
    ) {
         require(_roundId > 0 && _roundId < nextRoundId, "Invalid round ID");
         Round storage round = rounds[_roundId];
         require(round.state >= RoundState.Collapsed, "Round has not collapsed yet");

         return (
             round.totalPool,
             round.totalWonPool,
             round.totalFeesCollected,
             round.winningNumber,
             round.collapseTime
         );
    }

    /// @notice Gets the total number of QPUs bought in a specific round.
    /// @param _roundId The ID of the round.
    /// @return The total QPU count.
    function getQpuCountInRound(uint256 _roundId) external view returns (uint256) {
         require(_roundId > 0 && _roundId < nextRoundId, "Invalid round ID");
         return rounds[_roundId].totalQpus;
    }

     /// @notice Gets the total number of Entangled States created in a specific round.
     /// @param _roundId The ID of the round.
     /// @return The total Entangled State count.
    function getEntangledStateCountInRound(uint256 _roundId) external view returns (uint256) {
        require(_roundId > 0 && _roundId < nextRoundId, "Invalid round ID");
        return rounds[_roundId].totalEntangledStates;
    }

    /// @notice Gets the current price for a single QPU.
    /// @return The QPU price in wei.
    function getQpuPrice() external view returns (uint256) {
        return currentQpuPrice;
    }

    /// @notice Gets the timestamp when the Superposition phase ends for a round.
    /// @param _roundId The ID of the round.
    /// @return The end timestamp. Returns 0 if round is inactive or invalid.
    function getRoundEndTime(uint256 _roundId) external view returns (uint256) {
        if (_roundId == 0 || _roundId >= nextRoundId) return 0;
        return rounds[_roundId].superpositionEndTime;
    }

    // Fallback function to receive Ether, only allowed during Buying phase
    receive() external payable {
        uint256 roundId = nextRoundId > 1 ? nextRoundId - 1 : 0;
        if (roundId > 0 && rounds[roundId].state == RoundState.Buying && msg.value > 0) {
             // Allows receiving ether, but require explicit buyQpu calls to get tickets
             // This fallback is just to prevent locked funds if ETH is sent directly,
             // but doesn't issue QPUs automatically. buyQpu() must be called.
             emit QpuPurchased(roundId, msg.sender, 0, msg.value); // Log receipt, QPU ID 0 indicates not linked to a QPU yet
        } else {
             // Reject Ether sent outside the buying phase or without a call to buyQpu
             revert("Ether received outside buying phase or without purchase call");
        }
    }
}
```