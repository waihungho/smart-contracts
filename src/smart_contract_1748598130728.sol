Okay, let's create a smart contract with a unique concept: a system of "Quantum States" that the contract can transition between based on external data (via oracle) and internal factors (like user predictions). Users can predict the next state and stake funds, potentially minting NFTs representing their prediction. The transition (the "Leap") is triggered when specific conditions are met.

This combines elements of prediction markets, dynamic state changes, oracles, and NFTs in a non-standard way. It's complex and requires careful state management.

**Contract Name:** `QuantumLeapContract`

**Concept:** The contract exists in one of several defined "Quantum States", each potentially having different parameters or effects. A "Leap Phase" can be initiated, during which users predict which state the contract will transition to based on a future external data point. When the external data is provided (by an oracle), the contract executes a "Quantum Leap" to the next state based on predefined conditions linked to the oracle data. Users who predicted correctly share the prediction pool. Users can also mint NFTs tied to their specific prediction for a given leap.

---

**Outline & Function Summary**

1.  **State Management:**
    *   Define and store potential `QuantumStateParameters`.
    *   Track the `currentStateId`.

2.  **Oracle Integration:**
    *   Set an `oracleAddress` responsible for providing external data.
    *   Receive oracle data to trigger leap conditions.

3.  **Leap Mechanism:**
    *   Initiate a `LeapPhase` (a period for predictions).
    *   Define `LeapCondition`s that map oracle data to potential next states.
    *   Execute the `QuantumLeap` based on the met condition and oracle data.

4.  **Prediction Market:**
    *   Users `predictNextState` by staking Ether.
    *   Track user predictions and staked amounts per state.
    *   `claimPredictionRewards` for correct predictors after a leap.
    *   Set fees and minimum stakes for predictions.

5.  **Prediction NFTs (Basic Implementation):**
    *   Allow users to `mintStateNFT` representing their prediction for a specific leap.
    *   Basic ERC721-like tracking (`balanceOf`, `ownerOf`, `tokenURI`, `transferFrom`).
    *   Link NFT metadata to the prediction details.
    *   Allow `burnStateNFT`.

6.  **Dynamic Features:**
    *   Potentially implement `configureDynamicFee` where fees change based on `currentStateId`.

7.  **Admin/Utility:**
    *   Owner functions for setup and configuration (`setOracleAddress`, `addQuantumState`, `setLeapConditionParameters`, `setPredictionFee`, `setMinStakeForPrediction`, `withdrawFunds`).
    *   `pauseContract`/`unpauseContract`.
    *   View functions to check state, predictions, balances, etc.

---

**Function Summary (>= 20 Functions):**

1.  `constructor()`: Initializes the contract and sets the owner.
2.  `setOracleAddress(address _oracle)`: Sets the address authorized to submit oracle data. (Owner only)
3.  `addQuantumState(uint256 _stateId, QuantumStateParameters calldata _params)`: Defines a new potential quantum state. (Owner only)
4.  `removeQuantumState(uint256 _stateId)`: Removes a previously defined quantum state. (Owner only)
5.  `setCurrentState(uint256 _stateId)`: Manually sets the contract's current state (e.g., for initial setup). (Owner only, restricted after first leap)
6.  `defineQuantumParameters(uint256 _stateId, QuantumStateParameters calldata _params)`: Updates parameters for an existing state. (Owner only)
7.  `setLeapConditionParameters(LeapCondition[] calldata _conditions)`: Defines the rules for transitioning between states based on oracle data. (Owner only)
8.  `setPredictionFee(uint256 _fee)`: Sets the fee required to make a prediction. (Owner only)
9.  `setMinStakeForPrediction(uint256 _minStake)`: Sets the minimum ETH amount required for a prediction stake. (Owner only)
10. `predictNextState(uint256 _predictedStateId) payable`: Allows a user to predict the outcome state for the current leap phase, staking ETH. Requires fee and minimum stake.
11. `initiateLeapPhase()`: Starts a new phase where users can predict the next state. (Owner only, or maybe time-based trigger?) Let's make it owner-triggered for simplicity.
12. `submitOracleData(int256 _oracleValue)`: Called by the designated oracle to provide the external data needed for the leap condition check.
13. `executeQuantumLeap()`: Triggers the state transition based on the submitted oracle data and defined conditions. Calculates and prepares prediction rewards. Callable only after oracle data is submitted and by a designated address (oracle/keeper). Let's restrict it to the oracle address.
14. `claimPredictionRewards()`: Allows users who predicted correctly for the *last* leap to claim their share of the prediction pool.
15. `mintStateNFT(uint256 _predictedStateId)`: Mints an NFT representing the user's prediction for the current leap phase. Requires a prediction stake already made for that state.
16. `burnStateNFT(uint256 _tokenId)`: Allows the owner of a prediction NFT to burn it.
17. `configureDynamicFee(uint256 _baseFee, mapping(uint256 => uint256) calldata _stateFeeMultiplier)`: Sets up a system where certain contract fees could dynamically change based on the current state (placeholder function).
18. `withdrawFunds(address payable _to, uint256 _amount)`: Allows the owner to withdraw accumulated fees or unclaimed funds. (Owner only)
19. `pauseContract()`: Pauses contract functionality. (Owner only)
20. `unpauseContract()`: Unpauses contract functionality. (Owner only)
21. `getCurrentStateId() view returns (uint256)`: Gets the ID of the current quantum state.
22. `getCurrentStateParameters() view returns (QuantumStateParameters memory)`: Gets parameters for the current state.
23. `getQuantumStateDetails(uint256 _stateId) view returns (QuantumStateParameters memory)`: Gets parameters for any defined state.
24. `getPredictionDetails(uint256 _leapId, uint256 _stateId) view returns (uint256 totalStake, uint256 predictorCount)`: Gets aggregated prediction data for a specific state in a given leap.
25. `getUserPrediction(uint256 _leapId, address _user) view returns (uint256 predictedStateId, uint256 stakeAmount)`: Gets a user's prediction details for a specific leap.
26. `getLeapPhaseStatus() view returns (bool isActive, uint256 currentLeapId)`: Checks if a leap phase is active and gets the current leap ID.
27. `isOracleAddress(address _addr) view returns (bool)`: Checks if an address is the designated oracle.
28. `ownerOf(uint256 tokenId) view returns (address)`: ERC721: Gets the owner of an NFT.
29. `balanceOf(address owner) view returns (uint256)`: ERC721: Gets the NFT count for an address.
30. `tokenURI(uint256 tokenId) view returns (string memory)`: ERC721: Gets the metadata URI for an NFT.
31. `transferFrom(address from, address to, uint256 tokenId)`: ERC721: Transfers an NFT. (Basic implementation)
32. `getPredictedStateForNFT(uint256 _tokenId) view returns (uint256 leapId, uint256 predictedStateId)`: Gets the leap and predicted state associated with an NFT.

*(Note: Some standard ERC721 functions like `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, events, and full safety checks for transfers are omitted for brevity and focus on the core concept and custom functions, but a production contract would need them.)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Basic ERC721 interfaces needed internally
interface IERC721Metadata {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}


/**
 * @title QuantumLeapContract
 * @dev A contract that manages dynamic "Quantum States", allowing transitions (Leaps)
 * based on oracle data and user predictions. Includes a prediction market and
 * prediction-linked NFTs.
 *
 * Outline:
 * 1. State Management: Define and store potential Quantum States, track current state.
 * 2. Oracle Integration: Set oracle address, receive external data.
 * 3. Leap Mechanism: Initiate leap phase, define conditions, execute leap based on oracle data.
 * 4. Prediction Market: Users predict next state with stake, claim rewards.
 * 5. Prediction NFTs: Mint/burn NFTs linked to user predictions.
 * 6. Dynamic Features: Placeholder for state-dependent fees.
 * 7. Admin/Utility: Owner controls, pausing, views.
 */
contract QuantumLeapContract is Ownable, Pausable, ReentrancyGuard {

    // --- State Variables ---

    // --- Core State & Leap ---
    struct QuantumStateParameters {
        string name;
        // Add other state-specific parameters here
        uint256 emissionRatePlaceholder; // Example: represents a different rate in this state
        bytes data; // Generic data field for complex state configs
    }

    struct LeapCondition {
        int256 minOracleValue; // Inclusive minimum
        int256 maxOracleValue; // Inclusive maximum
        uint256 targetStateId; // State to transition to if condition met
        string description;
    }

    mapping(uint256 => QuantumStateParameters) public quantumStates;
    uint256[] public availableStateIds; // To iterate over available states

    uint256 public currentStateId;
    uint256 private _nextStateId = 1; // Counter for assigning unique state IDs

    LeapCondition[] public leapConditions;
    uint256 public constant NO_LEAP_STATE_ID = 0; // Special ID indicating no transition

    uint256 public oracleDataSubmissionTime;
    int256 public lastSubmittedOracleValue;
    address public oracleAddress;

    bool public leapPhaseActive;
    uint256 public currentLeapId = 0; // Incremented with each new leap phase

    // --- Prediction Market ---
    uint256 public predictionFee = 0.01 ether; // Fee to make a prediction (burned or goes to treasury)
    uint256 public minStakeForPrediction = 0.05 ether; // Minimum ETH stake per prediction

    // Mapping: leapId => userAddress => predictedStateId
    mapping(uint256 => mapping(address => uint256)) public userPredictions;
    // Mapping: leapId => userAddress => stakeAmount
    mapping(uint256 => mapping(address => uint256)) public predictionStakes;
    // Mapping: leapId => predictedStateId => totalStake
    mapping(uint256 => mapping(uint256 => uint256)) public statePredictionTotals;
    // Mapping: leapId => predictedStateId => list of users who predicted this state
    mapping(uint256 => mapping(uint256 => address[])) private statePredictorList;

    // Store winning state and total pool for past leaps for reward calculation
    mapping(uint256 => uint256) public winningStateForLeap;
    mapping(uint256 => uint256) public totalPoolForLeap;

    // --- Prediction NFTs (Basic ERC721-like) ---
    uint256 private _nextTokenId = 1; // Counter for NFT token IDs
    // Mapping: tokenId => ownerAddress
    mapping(uint256 => address) private _owners;
    // Mapping: ownerAddress => balance
    mapping(address => uint256) private _balances;
    // Mapping: tokenId => leapId & predictedStateId
    mapping(uint256 => bytes) private _tokenMetadata; // Storing encoded leap/state info

    // ERC721Metadata placeholders
    string private _name = "QuantumPredictionNFT";
    string private _symbol = "QPN";

    // --- Dynamic Features Placeholder ---
    mapping(uint256 => uint256) public stateFeeMultiplierPlaceholder; // Example: Fee multiplier per state

    // --- Events ---
    event OracleAddressSet(address indexed oracle);
    event QuantumStateAdded(uint256 indexed stateId, string name);
    event QuantumStateRemoved(uint256 indexed stateId);
    event CurrentStateChanged(uint256 indexed oldStateId, uint256 indexed newStateId, uint256 indexed leapId);
    event LeapPhaseInitiated(uint256 indexed leapId);
    event OracleDataSubmitted(int256 value, uint256 timestamp);
    event QuantumLeapExecuted(uint256 indexed leapId, uint256 indexed winningStateId);
    event PredictionMade(uint256 indexed leapId, address indexed user, uint256 indexed predictedStateId, uint256 stakeAmount);
    event PredictionRewardsClaimed(uint256 indexed leapId, address indexed user, uint256 amount);
    event PredictionNFTMinted(uint256 indexed tokenId, uint256 indexed leapId, uint256 indexed predictedStateId, address indexed owner);
    event PredictionNFTBurned(uint256 indexed tokenId, address indexed owner);
    event PredictionFeeSet(uint256 newFee);
    event MinStakeSet(uint256 newMinStake);
    event FundsWithdrawn(address indexed to, uint256 amount);
    event Paused(address account);
    event Unpaused(address account);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId); // For NFT basic compatibility

    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Not the designated oracle");
        _;
    }

    modifier onlyDuringLeapPhase() {
        require(leapPhaseActive, "Leap phase is not active");
        _;
    }

    modifier onlyAfterLeapPhase() {
        require(!leapPhaseActive, "Leap phase is active");
        _;
    }

    modifier onlyBeforeOracleSubmission() {
         require(oracleDataSubmissionTime == 0, "Oracle data already submitted for this leap");
         _;
    }

    modifier onlyAfterOracleSubmission() {
         require(oracleDataSubmissionTime > 0, "Oracle data not yet submitted for this leap");
         _;
    }

    // --- Constructor ---
    constructor() Ownable(msg.sender) Pausable(false) {
        // Initialize with a default state (ID 0 is reserved for 'no leap')
        _nextStateId = 1; // Start state IDs from 1
        currentStateId = _nextStateId++; // Set initial state and increment counter
        quantumStates[currentStateId] = QuantumStateParameters({
            name: "Initial State",
            emissionRatePlaceholder: 100,
            data: ""
        });
        availableStateIds.push(currentStateId);
    }

    receive() external payable {} // Allows receiving Ether for predictions

    // --- Admin Functions ---

    /**
     * @dev Sets the address authorized to submit oracle data.
     * @param _oracle The address of the oracle.
     */
    function setOracleAddress(address _oracle) external onlyOwner {
        require(_oracle != address(0), "Zero address");
        oracleAddress = _oracle;
        emit OracleAddressSet(_oracle);
    }

    /**
     * @dev Defines a new potential quantum state.
     * State IDs are auto-incremented starting from 1.
     * @param _params Parameters for the new state.
     * @return The newly assigned state ID.
     */
    function addQuantumState(QuantumStateParameters calldata _params) external onlyOwner returns (uint256) {
        uint256 newStateId = _nextStateId++;
        quantumStates[newStateId] = _params;
        availableStateIds.push(newStateId);
        emit QuantumStateAdded(newStateId, _params.name);
        return newStateId;
    }

    /**
     * @dev Removes a previously defined quantum state. Cannot remove the current state.
     * @param _stateId The ID of the state to remove.
     */
    function removeQuantumState(uint256 _stateId) external onlyOwner {
        require(_stateId != 0 && _stateId != currentStateId, "Cannot remove current or invalid state");
        require(quantumStates[_stateId].name.length > 0, "State does not exist"); // Check if exists

        // Remove from availableStateIds array (simple way, less gas efficient for large arrays)
        bool found = false;
        for (uint i = 0; i < availableStateIds.length; i++) {
            if (availableStateIds[i] == _stateId) {
                availableStateIds[i] = availableStateIds[availableStateIds.length - 1];
                availableStateIds.pop();
                found = true;
                break;
            }
        }
        require(found, "State not found in list"); // Should not happen if state exists

        delete quantumStates[_stateId];
        emit QuantumStateRemoved(_stateId);
    }

    /**
     * @dev Updates parameters for an existing state.
     * @param _stateId The ID of the state to update.
     * @param _params New parameters for the state.
     */
    function defineQuantumParameters(uint256 _stateId, QuantumStateParameters calldata _params) external onlyOwner {
        require(quantumStates[_stateId].name.length > 0, "State does not exist");
        quantumStates[_stateId] = _params;
        // Emit a generic event or specific ones if needed
    }

    /**
     * @dev Manually sets the contract's current state.
     * Can only be called before the first leap (initial setup) or under specific conditions if added.
     * @param _stateId The ID of the state to transition to.
     */
    function setCurrentState(uint256 _stateId) external onlyOwner onlyBeforeOracleSubmission {
         // Simple restriction: only before first leap for initial setup, or before oracle data for current leap
        require(quantumStates[_stateId].name.length > 0, "State does not exist");
        // If currentLeapId > 0, this would allow owner to change state mid-leap setup which might be undesirable.
        // For this version, allow it only before the first leap initiation.
        require(currentLeapId == 0 && !leapPhaseActive, "Cannot manually set state after first leap or during phase");
        uint256 oldState = currentStateId;
        currentStateId = _stateId;
         emit CurrentStateChanged(oldState, currentStateId, currentLeapId); // leapId will be 0 here
    }


    /**
     * @dev Defines the rules for transitioning between states based on oracle data.
     * Each condition defines a range and a target state. The first matching range wins.
     * @param _conditions Array of leap conditions.
     */
    function setLeapConditionParameters(LeapCondition[] calldata _conditions) external onlyOwner {
        // Basic validation: check if target states exist
        for(uint i = 0; i < _conditions.length; i++) {
             if (_conditions[i].targetStateId != NO_LEAP_STATE_ID) {
                 require(quantumStates[_conditions[i].targetStateId].name.length > 0, "Target state in condition does not exist");
             }
        }
        leapConditions = _conditions;
    }

    /**
     * @dev Sets the fee required to make a prediction.
     * This fee is separate from the stake and is collected by the contract (treasury).
     * @param _fee The new prediction fee.
     */
    function setPredictionFee(uint256 _fee) external onlyOwner {
        predictionFee = _fee;
        emit PredictionFeeSet(_fee);
    }

    /**
     * @dev Sets the minimum ETH amount required for a prediction stake.
     * @param _minStake The new minimum stake.
     */
    function setMinStakeForPrediction(uint256 _minStake) external onlyOwner {
        minStakeForPrediction = _minStake;
        emit MinStakeSet(_minStake);
    }

    /**
     * @dev Allows the owner to withdraw accumulated funds (fees, unclaimed stakes).
     * @param _to The address to send the funds to.
     * @param _amount The amount to withdraw.
     */
    function withdrawFunds(address payable _to, uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be > 0");
        require(address(this).balance >= _amount, "Insufficient contract balance");
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Withdrawal failed");
        emit FundsWithdrawn(_to, _amount);
    }

    /**
     * @dev Pauses the contract. Prevents core actions like predictions and leaps.
     */
    function pauseContract() external onlyOwner {
        _pause();
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses the contract.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
        emit Unpaused(msg.sender);
    }

    // --- Leap and Prediction Functions ---

    /**
     * @dev Initiates a new leap phase, allowing users to make predictions.
     * Resets prediction data for the new phase.
     */
    function initiateLeapPhase() external onlyOwner whenNotPaused onlyAfterLeapPhase {
        currentLeapId++; // Start a new leap instance
        leapPhaseActive = true;
        oracleDataSubmissionTime = 0; // Reset oracle data status for the new phase

        // Clear previous leap's prediction data (important for gas, but doing fully on-chain is hard)
        // A more scalable approach would involve off-chain indexing or limiting data storage.
        // For this example, we just increment leapId, effectively isolating old data.
        // Direct deletion of large mappings/arrays is not feasible in one transaction.

        emit LeapPhaseInitiated(currentLeapId);
    }

    /**
     * @dev Allows a user to predict the next state during the leap phase.
     * Requires a fee and a minimum stake in Ether.
     * A user can only predict once per leap phase.
     * @param _predictedStateId The ID of the state the user predicts.
     */
    function predictNextState(uint256 _predictedStateId) external payable whenNotPaused nonReentrant onlyDuringLeapPhase onlyBeforeOracleSubmission {
        require(msg.value >= predictionFee + minStakeForPrediction, "Insufficient funds (fee + min stake)");
        require(quantumStates[_predictedStateId].name.length > 0 || _predictedStateId == NO_LEAP_STATE_ID, "Predicted state does not exist or invalid ID");
        require(userPredictions[currentLeapId][msg.sender] == 0, "Already made a prediction for this leap"); // User can only predict once

        uint256 stakeAmount = msg.value - predictionFee;

        userPredictions[currentLeapId][msg.sender] = _predictedStateId;
        predictionStakes[currentLeapId][msg.sender] = stakeAmount;
        statePredictionTotals[currentLeapId][_predictedStateId] += stakeAmount;

        // Add user to the list for this state (needed for reward distribution later)
        // This can be gas expensive for many predictors. A more efficient way might be needed.
        statePredictorList[currentLeapId][_predictedStateId].push(msg.sender);


        emit PredictionMade(currentLeapId, msg.sender, _predictedStateId, stakeAmount);
    }

     /**
     * @dev Allows a user to cancel their prediction *before* oracle data is submitted.
     * Refunds the stake and fee.
     */
    function cancelPrediction() external whenNotPaused onlyDuringLeapPhase onlyBeforeOracleSubmission nonReentrant {
        uint256 predictedStateId = userPredictions[currentLeapId][msg.sender];
        uint256 stakeAmount = predictionStakes[currentLeapId][msg.sender];

        require(predictedStateId != 0, "No active prediction to cancel for this leap"); // 0 means no prediction or NO_LEAP_STATE_ID prediction which is valid

        // Refund
        uint256 totalRefund = stakeAmount + predictionFee;
        require(address(this).balance >= totalRefund, "Contract balance too low for refund");

        // Update state totals
        statePredictionTotals[currentLeapId][predictedStateId] -= stakeAmount;

        // Remove user's prediction data
        delete userPredictions[currentLeapId][msg.sender];
        delete predictionStakes[currentLeapId][msg.sender];

         // Removing from statePredictorList is expensive. Let's skip deleting from the list
         // and just check userPredictions when distributing rewards.

        (bool success, ) = payable(msg.sender).call{value: totalRefund}("");
        require(success, "Refund failed");

        // No specific event for cancel, PredictionMade status indicates it's not finalized.
        // Or add PredictionCancelled event if needed.
    }


    /**
     * @dev Called by the designated oracle to submit the external data value.
     * This must happen during the leap phase and only once per phase.
     * @param _oracleValue The value received from the oracle.
     */
    function submitOracleData(int256 _oracleValue) external onlyOracle whenNotPaused onlyDuringLeapPhase onlyBeforeOracleSubmission {
        lastSubmittedOracleValue = _oracleValue;
        oracleDataSubmissionTime = block.timestamp;
        emit OracleDataSubmitted(_oracleValue, block.timestamp);
    }

    /**
     * @dev Executes the quantum leap based on the submitted oracle data and conditions.
     * Can only be called after oracle data is submitted during a leap phase.
     * Determines the winning state, sets the new current state, and prepares rewards.
     */
    function executeQuantumLeap() external onlyOracle whenNotPaused onlyDuringLeapPhase onlyAfterOracleSubmission nonReentrant {
        // Determine the next state based on oracle data and conditions
        uint256 nextStateId = NO_LEAP_STATE_ID; // Default is no state change
        for(uint i = 0; i < leapConditions.length; i++) {
            if (lastSubmittedOracleValue >= leapConditions[i].minOracleValue &&
                lastSubmittedOracleValue <= leapConditions[i].maxOracleValue)
            {
                nextStateId = leapConditions[i].targetStateId;
                break; // Use the first matching condition
            }
        }

        // Check if the determined next state exists (if not NO_LEAP_STATE_ID)
        if (nextStateId != NO_LEAP_STATE_ID) {
            require(quantumStates[nextStateId].name.length > 0, "Leap condition targets non-existent state");
        }

        // --- Calculate & Prepare Rewards ---
        uint256 totalPredictionPool = address(this).balance - (address(this).balance % 1 ether); // Example: keep a minimum balance or separate fees
        uint256 totalWinningStake = statePredictionTotals[currentLeapId][nextStateId];

        winningStateForLeap[currentLeapId] = nextStateId;
        totalPoolForLeap[currentLeapId] = totalPredictionPool; // This is the pool *before* distributing

        // Update contract state
        uint256 oldState = currentStateId;
        currentStateId = nextStateId; // Will be NO_LEAP_STATE_ID if no condition met

        // End leap phase
        leapPhaseActive = false;
        // Do NOT reset oracleDataSubmissionTime yet, keep it for reward claiming validation

        emit QuantumLeapExecuted(currentLeapId, nextStateId);
        emit CurrentStateChanged(oldState, currentStateId, currentLeapId);

        // Note: Rewards are NOT distributed here directly due to gas limits with many predictors.
        // Users must call claimPredictionRewards().
    }

    /**
     * @dev Allows users who predicted correctly for the *last completed* leap phase
     * to claim their proportional share of the prediction pool.
     */
    function claimPredictionRewards() external whenNotPaused nonReentrant onlyAfterLeapPhase {
         // Can only claim for the immediately preceding leap (currentLeapId - 1)
         // Or could store data for multiple past leaps if needed, but gas increases.
         // Let's allow claiming for the *last* completed leap phase (currentLeapId - 1).
         // Check if currentLeapId is > 0, otherwise no leap has completed.
         require(currentLeapId > 0, "No leap has completed yet");

         uint256 leapToClaim = currentLeapId - 1; // The most recently completed leap

         // Check if the user actually predicted in that leap
         uint256 predictedState = userPredictions[leapToClaim][msg.sender];
         require(predictedState != 0 || (predictedState == NO_LEAP_STATE_ID && userPredictions[leapToClaim][msg.sender] == NO_LEAP_STATE_ID), "No prediction found for this user in the last leap"); // Handle NO_LEAP_STATE_ID prediction explicitly

         // Check if this prediction was the winning state
         uint256 winningState = winningStateForLeap[leapToClaim];
         require(predictedState == winningState, "Your prediction was incorrect for this leap");

         // Check if rewards have already been claimed for this prediction
         uint256 stake = predictionStakes[leapToClaim][msg.sender];
         require(stake > 0, "Rewards already claimed or no stake"); // Stake is set to 0 after claiming

         // Calculate reward amount
         uint256 totalPool = totalPoolForLeap[leapToClaim]; // Total pool for the winning state
         uint256 totalWinningStake = statePredictionTotals[leapToClaim][winningState];

         uint256 rewardAmount = (stake * totalPool) / totalWinningStake;

         // Set stake to 0 to prevent double claiming
         predictionStakes[leapToClaim][msg.sender] = 0;

         // Send reward
         (bool success, ) = payable(msg.sender).call{value: rewardAmount}("");
         require(success, "Reward transfer failed");

         emit PredictionRewardsClaimed(leapToClaim, msg.sender, rewardAmount);
    }

    // --- Prediction NFT Functions (Basic ERC721-like) ---

    /**
     * @dev Mints an NFT representing the user's prediction for the current leap phase.
     * Requires the user to have already made a prediction for the current phase.
     * @param _predictedStateId The state ID the user predicted (must match their prediction).
     * @return The ID of the newly minted NFT.
     */
    function mintStateNFT(uint256 _predictedStateId) external whenNotPaused onlyDuringLeapPhase onlyBeforeOracleSubmission returns (uint256) {
        require(userPredictions[currentLeapId][msg.sender] == _predictedStateId, "User must have predicted this state for the current leap");
        require(_predictedStateId != 0 || (userPredictions[currentLeapId][msg.sender] == NO_LEAP_STATE_ID), "Cannot mint NFT for invalid state ID"); // Handle NO_LEAP_STATE_ID case

        uint256 newTokenId = _nextTokenId++;
        _mint(msg.sender, newTokenId);

        // Store the prediction details with the token
        // Simple encoding: leapId | predictedStateId
        // assuming leapId and predictedStateId fit within 16 bytes each (uint128) for simplicity
        bytes memory metadata = abi.encodePacked(uint128(currentLeapId), uint128(_predictedStateId));
        _tokenMetadata[newTokenId] = metadata;

        emit PredictionNFTMinted(newTokenId, currentLeapId, _predictedStateId, msg.sender);
        return newTokenId;
    }

    /**
     * @dev Burns a prediction NFT.
     * @param _tokenId The ID of the NFT to burn.
     */
    function burnStateNFT(uint256 _tokenId) external whenNotPaused nonReentrant {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not authorized to burn this token");
        _burn(_tokenId);
        emit PredictionNFTBurned(_tokenId, msg.sender);
    }

    /**
     * @dev Internal mint function.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(_owners[tokenId] == address(0), "ERC721: token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Internal burn function.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: token not minted");

        delete _owners[tokenId];
        _balances[owner] -= 1;

        delete _tokenMetadata[tokenId]; // Clear metadata on burn

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Gets the owner of an NFT.
     * @param tokenId The ID of the NFT.
     * @return The owner's address.
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

     /**
     * @dev Checks if an address is the owner or an approved operator for a token.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ownerOf(tokenId); // Will revert if token doesn't exist
        return (spender == owner); // Simplified: only owner can operate for this example
        // Full ERC721 would check approvals/operators here
    }

    /**
     * @dev Gets the balance of NFTs for an address.
     * @param owner The owner's address.
     * @return The number of NFTs owned.
     */
    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev Gets the metadata URI for an NFT.
     * Generates a simple URI containing the leap ID and predicted state ID.
     * @param tokenId The ID of the NFT.
     * @return The metadata URI.
     */
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        require(_owners[tokenId] != address(0), "ERC721Metadata: URI query for nonexistent token");
        bytes memory metadata = _tokenMetadata[tokenId];
        (uint128 leapId, uint128 predictedStateId) = abi.decode(metadata, (uint128, uint128));
        // Simple structure: data:application/json;base64,...
        // In a real app, this would point to IPFS or a backend API
        string memory uri = string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(abi.encodePacked(
                '{"name": "Quantum Prediction #', uint256(tokenId),
                '", "description": "Predicted state ', uint256(predictedStateId),
                ' for Quantum Leap #', uint256(leapId),
                '", "attributes": [',
                '{"trait_type": "Leap ID", "value": ', uint256(leapId), '},',
                '{"trait_type": "Predicted State ID", "value": ', uint256(predictedStateId), '}',
                // Add actual state name/details if accessible easily
                ']}'
            )))
        ));
        return uri;
    }

    /**
     * @dev Transfers an NFT. Simplified without full ERC721 checks (e.g., approvals).
     * @param from The current owner's address.
     * @param to The recipient's address.
     * @param tokenId The ID of the NFT to transfer.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual whenNotPaused nonReentrant {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not owner nor approved"); // Only owner can transfer in this simplified version
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Internal transfer logic
        _balances[from] -= 1;
        _owners[tokenId] = to;
        _balances[to] += 1;

        emit Transfer(from, to, tokenId);
    }

    // --- Dynamic Features Placeholder ---

    /**
     * @dev Placeholder function to configure dynamic fees based on the current state.
     * Not fully implemented, just shows the concept.
     * @param _baseFee Base fee amount.
     * @param _stateFeeMultiplier Mapping of state IDs to fee multipliers.
     */
    function configureDynamicFee(uint256 _baseFee, mapping(uint256 => uint256) calldata _stateFeeMultiplier) external onlyOwner {
        // This is a conceptual function. Implementation requires integrating it into
        // other functions that charge fees (e.g., predictNextState if fee was dynamic).
        // Base fee example: predictionFee = _baseFee;
        // Store multipliers: stateFeeMultiplierPlaceholder = _stateFeeMultiplier;
        // Inside predictNextState: uint256 fee = predictionFee * stateFeeMultiplierPlaceholder[currentStateId] / 100; // Example multiplier logic
    }


    // --- View Functions ---

    /**
     * @dev Gets the ID of the current quantum state.
     * @return The current state ID.
     */
    function getCurrentStateId() public view returns (uint256) {
        return currentStateId;
    }

    /**
     * @dev Gets the parameters for the current quantum state.
     * @return The parameters struct for the current state.
     */
    function getCurrentStateParameters() public view returns (QuantumStateParameters memory) {
        return quantumStates[currentStateId];
    }

    /**
     * @dev Gets the parameters for any defined quantum state.
     * @param _stateId The ID of the state to query.
     * @return The parameters struct for the queried state.
     */
    function getQuantumStateDetails(uint256 _stateId) public view returns (QuantumStateParameters memory) {
        require(quantumStates[_stateId].name.length > 0, "State does not exist");
        return quantumStates[_stateId];
    }

     /**
     * @dev Gets the list of available state IDs (excluding ID 0).
     * @return An array of defined state IDs.
     */
    function getAvailableStateIds() external view returns (uint256[] memory) {
        return availableStateIds;
    }


    /**
     * @dev Gets the total stake amount and predictor count for a specific state in a given leap.
     * @param _leapId The ID of the leap phase.
     * @param _stateId The ID of the state.
     * @return totalStake Total Ether staked on this state.
     * @return predictorCount Number of users who predicted this state.
     */
    function getPredictionDetails(uint256 _leapId, uint256 _stateId) public view returns (uint256 totalStake, uint256 predictorCount) {
        totalStake = statePredictionTotals[_leapId][_stateId];
        // Count users who predicted this state by iterating or maintaining a separate counter.
        // Iterating the list is gas-heavy for writing, ok for reading views.
        predictorCount = statePredictorList[_leapId][_stateId].length;
        // A more gas-efficient write approach would use a separate counter map:
        // mapping(uint256 => mapping(uint256 => uint256)) public statePredictorCounts;
        // incremented in predictNextState.
    }

    /**
     * @dev Gets a user's prediction details for a specific leap.
     * @param _leapId The ID of the leap phase.
     * @param _user The address of the user.
     * @return predictedStateId The ID of the state the user predicted (0 if none).
     * @return stakeAmount The amount the user staked.
     */
    function getUserPrediction(uint256 _leapId, address _user) public view returns (uint256 predictedStateId, uint256 stakeAmount) {
        return (userPredictions[_leapId][_user], predictionStakes[_leapId][_user]);
    }

    /**
     * @dev Checks if a leap phase is currently active and gets the current leap ID.
     * @return isActive True if a leap phase is active.
     * @return currentLeapId The ID of the current leap phase.
     */
    function getLeapPhaseStatus() public view returns (bool isActive, uint256 currentLeapId_) {
        return (leapPhaseActive, currentLeapId);
    }

     /**
     * @dev Gets the oracle address.
     * @return The oracle address.
     */
    function getOracleAddress() public view returns (address) {
        return oracleAddress;
    }

    /**
     * @dev Gets the submitted oracle data value and timestamp for the current leap phase.
     * Returns 0/0 if not yet submitted.
     * @return value The submitted oracle value.
     * @return timestamp The timestamp of submission.
     */
    function getOracleData() public view returns (int256 value, uint256 timestamp) {
        return (lastSubmittedOracleValue, oracleDataSubmissionTime);
    }

    /**
     * @dev Gets the leap condition parameters.
     * @return An array of the defined leap conditions.
     */
    function getLeapConditions() external view returns (LeapCondition[] memory) {
        return leapConditions;
    }

     /**
     * @dev Checks if an address is the currently set designated oracle.
     * @param _addr The address to check.
     * @return True if the address is the oracle.
     */
    function isOracleAddress(address _addr) public view returns (bool) {
        return _addr == oracleAddress;
    }

    /**
     * @dev Gets the leap ID and predicted state ID associated with a prediction NFT.
     * @param _tokenId The ID of the NFT.
     * @return leapId The leap phase ID the NFT is linked to.
     * @return predictedStateId The state ID predicted for that leap.
     */
    function getPredictedStateForNFT(uint256 _tokenId) public view returns (uint256 leapId, uint256 predictedStateId) {
        bytes memory metadata = _tokenMetadata[_tokenId];
        require(metadata.length > 0, "NFT metadata not found");
        (uint128 lId, uint128 psId) = abi.decode(metadata, (uint128, uint128));
        return (uint256(lId), uint256(psId));
    }

    /**
     * @dev Gets the prediction fee.
     * @return The current prediction fee.
     */
    function getPredictionFee() public view returns (uint256) {
        return predictionFee;
    }

    /**
     * @dev Gets the minimum stake required for a prediction.
     * @return The current minimum stake.
     */
    function getMinStakeForPrediction() public view returns (uint256) {
        return minStakeForPrediction;
    }

     /**
     * @dev Gets the contract's current Ether balance (treasury).
     * @return The balance in Wei.
     */
    function treasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // --- Internal/Helper Functions ---

    // ERC721 Name/Symbol getters (optional, for compliance)
     function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    // Simplified ERC721 approval functions (not fully implemented)
    function approve(address, uint256) public virtual override {
        revert("Approvals not implemented");
    }

    function getApproved(uint256) public view virtual override returns (address) {
        revert("Approvals not implemented");
    }

    function setApprovalForAll(address, bool) public virtual override {
         revert("Operator approvals not implemented");
    }

    function isApprovedForAll(address, address) public view virtual override returns (bool) {
         revert("Operator approvals not implemented");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public virtual override {
        transferFrom(from, to, tokenId);
        // Basic safety check (not full ERC721 receiver check)
        if (to.code.length > 0) {
            (bool success,) = to.call(abi.encodeWithSelector(0x150b7a02, msg.sender, from, tokenId, data));
            require(success, "ERC721: transfer to non ERC721Receiver implementer");
        }
    }

     function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
         safeTransferFrom(from, to, tokenId, "");
     }

}

// Helper library for Base64 encoding (required for tokenURI)
library Base64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // allocate the resulting string with the correct length
        uint256 len = (data.length * 4 + 2) / 3;
        string memory xs = new string(len);
        bytes memory bs = bytes(xs);

        uint255 i = 0;
        uint255 j = 0;

        while (i < data.length) {
            uint256 temp;
            uint255 lookahead = i + 3;
            temp = data[i++] << 16;
            if (i < lookahead) {
                temp |= data[i++] << 8;
            }
            if (i < lookahead) {
                temp |= data[i++];
            }

            bs[j++] = bytes1(table[(temp >> 18) & 0x3F]);
            bs[j++] = bytes1(table[(temp >> 12) & 0x3F]);
            if (i < lookahead || lookahead == data.length) {
                bs[j++] = bytes1(table[(temp >> 6) & 0x3F]);
            } else {
                bs[j++] = bytes1(0x3D); // pad character '='
            }
            if (i < lookahead || lookahead == data.length) {
                bs[j++] = bytes1(table[temp & 0x3F]);
            } else {
                bs[j++] = bytes1(0x3D); // pad character '='
            }
        }

        return string(bs);
    }
}
```