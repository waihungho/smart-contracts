Okay, here is a Solidity smart contract featuring several advanced concepts, incorporating elements of prediction markets, dynamic NFTs (conceptually represented), staking, reputation, and oracle integration. It aims to be creative and distinct from typical open-source examples.

**Concept: The Epochal Chronicle**

This contract represents a decentralized chronicle or ledger that progresses through "Epochs." Users create a unique, soul-bound "Chronicle Slot" (represented by an ID and associated data, functioning like a dynamic NFT). Within their slot, they stake tokens and make predictions about external events revealed by a trusted oracle in each epoch. Successful predictions earn "Wisdom" (reputation points) and potentially rewards from a pool, while also influencing the associated Chronicle Slot's state (conceptually, its metadata or "evolution").

**Advanced/Creative Concepts Used:**

1.  **Staking into a Dynamic Asset:** Users stake tokens *within* their personal Chronicle Slot, rather than a general pool. The slot itself is tied to user progress.
2.  **Epoch-Based Lifecycle:** The contract operates in discrete time periods triggered by an admin/oracle.
3.  **Oracle Integration:** Relies on an external entity (the Oracle) to provide unpredictable outcomes for predictions.
4.  **On-Chain Prediction Market (Simplified):** Users commit predictions to the chain before the outcome is known.
5.  **Reputation System (Wisdom):** A core metric tied to successful participation, influencing rewards and potentially the asset's properties.
6.  **Dynamic State/Conceptual NFT:** Although not a full ERC721 transferable token (designed to be soul-bound or non-transferable for identity), the Chronicle Slot ID represents a unique asset whose associated on-chain data (Wisdom, staked amount, participation history) *changes* based on interaction, enabling dynamic metadata.
7.  **Parametric Reward Distribution:** Rewards are calculated based on prediction accuracy and potentially Wisdom score.
8.  **Role-Based Access Control (Simplified):** Differentiates between Owner, Oracle, and standard Users.
9.  **Pausable:** Standard safety mechanism.
10. **Token Rescue:** Allows owner to recover accidentally sent tokens.

---

**Outline & Function Summary:**

**I. State Variables:**
*   General contract state (paused, owner, oracle, staked token)
*   Epoch details (current ID, start/end time, state, event ID, outcome, prediction count)
*   Chronicle Slot details (mapping ID to data: owner, staked balance, wisdom, claimed epochs)
*   Slot management (owner to ID mapping, next available ID)
*   Epoch-specific prediction mapping (Epoch ID -> Slot ID -> Prediction)
*   Admin fee details (percentage, accumulated fees)
*   NFT Metadata base URI

**II. Events:**
*   Lifecycle events (Pause, Unpause, OwnershipTransferred)
*   Epoch events (EpochStarted, OutcomeRevealed)
*   User events (SlotCreated, TokensStaked, TokensUnstaked, PredictionMade, RewardsClaimed, WisdomUpdated)
*   Admin events (OracleUpdated, FeeUpdated, FeeWithdrawn, RescueTokens)

**III. Structs & Enums:**
*   `ChronicleSlot`: Stores data for each user's slot.
*   `Epoch`: Stores data for each epoch.
*   `EpochState`: Enum for epoch lifecycle.

**IV. Modifiers:**
*   `onlyOracle`: Restricts access to the designated oracle address.
*   `hasSlot`: Ensures caller has created a chronicle slot.
*   `isEpochState`: Checks the current epoch's state.
*   `isEpochOutcomeRevealed`: Checks if a specific epoch's outcome is revealed.

**V. Functions (>= 20 unique logic/view functions):**

1.  `constructor`: Initializes contract with staked token and oracle address.
2.  `createChronicleSlot`: (User) Mints a new Chronicle Slot ID for the caller (one per user).
3.  `stakeTokensIntoSlot`: (User) Stakes ERC20 tokens into the caller's Chronicle Slot.
4.  `unstakeTokensFromSlot`: (User) Unstakes ERC20 tokens from the caller's Chronicle Slot.
5.  `startNewEpoch`: (Oracle) Initiates a new epoch, setting its duration and external event ID.
6.  `submitPrediction`: (User) Submits a prediction (bytes32) for the current epoch's event.
7.  `revealEpochOutcome`: (Oracle) Reveals the true outcome (bytes32) for a specified past epoch.
8.  `claimEpochRewardsAndWisdom`: (User) Claims rewards and earns Wisdom for a completed, revealed epoch based on their prediction.
9.  `updateOracleAddress`: (Owner) Sets the address of the trusted oracle.
10. `updateEpochDuration`: (Owner) Sets the duration of future epochs.
11. `pause`: (Owner) Pauses core contract functionality.
12. `unpause`: (Owner) Unpauses core contract functionality.
13. `rescueStuckTokens`: (Owner) Recovers ERC20 tokens accidentally sent directly to the contract address.
14. `setSlotBaseURI`: (Owner) Sets the base URI for generating Chronicle Slot (NFT) metadata.
15. `setAdminFeePercentage`: (Owner) Sets the percentage of claims taken as a fee.
16. `withdrawAdminFees`: (Owner) Withdraws accumulated admin fees.
17. `getEpochDetails`: (View) Returns details about a specific epoch.
18. `getCurrentEpochDetails`: (View) Returns details about the current epoch.
19. `getUserSlotDetails`: (View) Returns details about the caller's Chronicle Slot.
20. `getSlotDetailsById`: (View) Returns details about a Chronicle Slot by its ID.
21. `getUserPredictionForEpoch`: (View) Returns a user's prediction for a specific epoch.
22. `getEpochOutcome`: (View) Returns the revealed outcome for a specific epoch.
23. `getClaimableRewardsAndWisdom`: (View) Calculates potential rewards and wisdom for a user/slot for a specific epoch *before* claiming.
24. `getWisdomScore`: (View) Returns the Wisdom score for a user's slot.
25. `getSlotIdByOwner`: (View) Returns the Chronicle Slot ID for a given owner address.
26. `getTotalStakedTokensInContract`: (View) Returns the total amount of staked tokens held in the contract.
27. `getEpochPredictionCount`: (View) Returns the total number of predictions submitted in a specific epoch.
28. `getEpochCorrectPredictionCount`: (Internal/View Helper) Calculates the number of correct predictions for an epoch (can be exposed as view).
29. `tokenURI`: (View) ERC721 metadata function - Generates a dynamic URI based on the slot's state.
30. `supportsInterface`: (View) ERC165 support (basic for ERC721 views).
31. `getAdminFeePercentage`: (View) Returns the current admin fee percentage.
32. `getAccumulatedAdminFees`: (View) Returns the total fees collected.

*(Note: Functions like `transferFrom`, `approve`, etc., from ERC721 are intentionally omitted as the slots are designed to be non-transferable/soul-bound identity representations in this concept.)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol"; // For supportsInterface

// --- Outline & Function Summary ---
// I. State Variables:
//    - General contract state (paused, owner, oracle, staked token)
//    - Epoch details (current ID, start/end time, state, event ID, outcome, prediction count)
//    - Chronicle Slot details (mapping ID to data: owner, staked balance, wisdom, claimed epochs)
//    - Slot management (owner to ID mapping, next available ID)
//    - Epoch-specific prediction mapping (Epoch ID -> Slot ID -> Prediction)
//    - Admin fee details (percentage, accumulated fees)
//    - NFT Metadata base URI
//
// II. Events:
//    - Lifecycle events (Pause, Unpause, OwnershipTransferred)
//    - Epoch events (EpochStarted, OutcomeRevealed)
//    - User events (SlotCreated, TokensStaked, TokensUnstaked, PredictionMade, RewardsClaimed, WisdomUpdated)
//    - Admin events (OracleUpdated, FeeUpdated, FeeWithdrawn, RescueTokens)
//
// III. Structs & Enums:
//    - ChronicleSlot: Stores data for each user's slot.
//    - Epoch: Stores data for each epoch.
//    - EpochState: Enum for epoch lifecycle.
//
// IV. Modifiers:
//    - onlyOracle: Restricts access to the designated oracle address.
//    - hasSlot: Ensures caller has created a chronicle slot.
//    - isEpochState: Checks the current epoch's state.
//    - isEpochOutcomeRevealed: Checks if a specific epoch's outcome is revealed.
//
// V. Functions (>= 20 unique logic/view functions):
//  1. constructor: Initializes contract.
//  2. createChronicleSlot: (User) Mints a new Slot ID.
//  3. stakeTokensIntoSlot: (User) Stakes tokens into their slot.
//  4. unstakeTokensFromSlot: (User) Unstakes tokens from their slot.
//  5. startNewEpoch: (Oracle) Initiates a new epoch.
//  6. submitPrediction: (User) Submits prediction for current epoch.
//  7. revealEpochOutcome: (Oracle) Reveals outcome for past epoch.
//  8. claimEpochRewardsAndWisdom: (User) Claims rewards/wisdom for epoch.
//  9. updateOracleAddress: (Owner) Sets oracle address.
// 10. updateEpochDuration: (Owner) Sets future epoch duration.
// 11. pause: (Owner) Pauses contract.
// 12. unpause: (Owner) Unpauses contract.
// 13. rescueStuckTokens: (Owner) Recovers accidental tokens.
// 14. setSlotBaseURI: (Owner) Sets base URI for NFT metadata.
// 15. setAdminFeePercentage: (Owner) Sets claim fee %.
// 16. withdrawAdminFees: (Owner) Withdraws collected fees.
// 17. getEpochDetails: (View) Details for specific epoch.
// 18. getCurrentEpochDetails: (View) Details for current epoch.
// 19. getUserSlotDetails: (View) Details for caller's slot.
// 20. getSlotDetailsById: (View) Details for slot by ID.
// 21. getUserPredictionForEpoch: (View) User's prediction for epoch.
// 22. getEpochOutcome: (View) Revealed outcome for epoch.
// 23. getClaimableRewardsAndWisdom: (View) Calculates potential rewards/wisdom.
// 24. getWisdomScore: (View) Wisdom score for slot.
// 25. getSlotIdByOwner: (View) Slot ID for owner address.
// 26. getTotalStakedTokensInContract: (View) Total staked amount.
// 27. getEpochPredictionCount: (View) Total predictions in epoch.
// 28. getEpochCorrectPredictionCount: (View/Helper) Count correct predictions in epoch.
// 29. tokenURI: (View) ERC721 metadata URI generation.
// 30. supportsInterface: (View) ERC165 interface support.
// 31. getAdminFeePercentage: (View) Returns fee %.
// 32. getAccumulatedAdminFees: (View) Returns collected fees.
//
// (Note: ERC721 transfer/approve functions are omitted for soul-bound nature.)
// --------------------------------------------------------------------

contract EpochalChronicle is Ownable, Pausable, IERC165 {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---
    IERC20 public immutable stakedToken;
    address public oracleAddress;

    enum EpochState {
        NotStarted,
        PredictionPeriod,
        RevealPeriod,
        Completed
    }

    struct Epoch {
        uint256 epochId;
        uint256 startTime;
        uint256 endTime;
        uint256 eventId; // Identifier for the event the oracle tracks (e.g., hash of event details)
        bytes32 outcome; // The actual outcome revealed by the oracle
        EpochState state;
        uint256 totalPredictions;
        uint256 epochRewardPool; // Staked tokens allocated for this epoch's rewards
    }

    struct ChronicleSlot {
        uint256 slotId;
        address owner;
        uint256 stakedBalance;
        uint256 wisdom;
        // Mapping to track claimed epochs for this slot (epochId => bool claimed)
        mapping(uint256 => bool) claimedEpochs;
    }

    mapping(uint256 => Epoch) public epochs;
    mapping(uint256 => ChronicleSlot) public chronicleSlots;
    mapping(address => uint256) private _ownerToSlotId; // Enforce one slot per owner initially
    Counters.Counter private _slotIdCounter;
    Counters.Counter private _epochIdCounter;

    // Mapping: epochId -> slotId -> prediction
    mapping(uint256 => mapping(uint256 => bytes32)) private _epochPredictions;

    uint256 public epochDuration; // Duration in seconds
    uint256 public predictionRevealLag; // Time after epoch end before outcome can be revealed (e.g., for oracle processing)
    uint256 public constant WISDOM_PER_CORRECT_PREDICTION = 100;
    uint256 public constant WISDOM_PER_PARTICIPATION = 10; // Even incorrect get some wisdom

    uint256 public adminFeePercentage; // Percentage of claimed rewards taken as fee (0-10000 for 0-100%)
    uint256 public accumulatedAdminFees;

    string public slotBaseURI; // Base URI for dynamic metadata

    // --- Events ---
    event OracleUpdated(address indexed newOracle);
    event EpochStarted(uint256 indexed epochId, uint256 startTime, uint256 endTime, uint256 eventId);
    event OutcomeRevealed(uint256 indexed epochId, bytes32 outcome);
    event SlotCreated(address indexed owner, uint256 indexed slotId);
    event TokensStaked(uint256 indexed slotId, address indexed owner, uint256 amount);
    event TokensUnstaked(uint256 indexed slotId, address indexed owner, uint256 amount);
    event PredictionMade(uint256 indexed epochId, uint256 indexed slotId, bytes32 prediction);
    event RewardsClaimed(uint256 indexed epochId, uint256 indexed slotId, uint256 claimedAmount, uint256 wisdomEarned);
    event WisdomUpdated(uint256 indexed slotId, uint256 newWisdom);
    event AdminFeeUpdated(uint256 newFeePercentage);
    event AdminFeeWithdrawn(address indexed receiver, uint256 amount);
    event TokensRescued(address indexed token, address indexed receiver, uint256 amount);

    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Not the oracle");
        _;
    }

    modifier hasSlot() {
        require(_ownerToSlotId[msg.sender] != 0, "No chronicle slot created");
        _;
    }

    modifier isEpochState(uint256 _epochId, EpochState _state) {
        require(epochs[_epochId].state == _state, "Epoch is not in required state");
        _;
    }

    modifier isEpochOutcomeRevealed(uint256 _epochId) {
        require(epochs[_epochId].outcome != bytes32(0), "Epoch outcome not revealed");
        _;
    }

    // --- Constructor ---
    constructor(address _stakedTokenAddress, address _oracleAddress, uint256 _epochDuration, uint256 _predictionRevealLag)
        Ownable(msg.sender)
        Pausable()
    {
        stakedToken = IERC20(_stakedTokenAddress);
        oracleAddress = _oracleAddress;
        epochDuration = _epochDuration;
        predictionRevealLag = _predictionRevealLag;
        adminFeePercentage = 0; // Default no fee
    }

    // --- User Functions ---

    /**
     * @notice Creates a new Chronicle Slot for the caller. Each address can only create one slot.
     * @dev The created slot ID serves as a conceptual NFT ID. It is initially non-transferable.
     */
    function createChronicleSlot() external whenNotPaused {
        require(_ownerToSlotId[msg.sender] == 0, "Chronicle slot already exists for this address");

        _slotIdCounter.increment();
        uint256 newSlotId = _slotIdCounter.current();

        chronicleSlots[newSlotId].slotId = newSlotId;
        chronicleSlots[newSlotId].owner = msg.sender;
        chronicleSlots[newSlotId].stakedBalance = 0;
        chronicleSlots[newSlotId].wisdom = 0;

        _ownerToSlotId[msg.sender] = newSlotId;

        emit SlotCreated(msg.sender, newSlotId);
    }

    /**
     * @notice Stakes tokens into the caller's Chronicle Slot.
     * @param _amount The amount of tokens to stake.
     */
    function stakeTokensIntoSlot(uint256 _amount) external whenNotPaused hasSlot {
        require(_amount > 0, "Amount must be greater than zero");
        uint256 slotId = _ownerToSlotId[msg.sender];

        // Transfer tokens from the user to the contract
        bool success = stakedToken.transferFrom(msg.sender, address(this), _amount);
        require(success, "Token transfer failed");

        chronicleSlots[slotId].stakedBalance = chronicleSlots[slotId].stakedBalance.add(_amount);

        emit TokensStaked(slotId, msg.sender, _amount);
    }

    /**
     * @notice Unstakes tokens from the caller's Chronicle Slot.
     * @param _amount The amount of tokens to unstake.
     * @dev Unstaking might have restrictions based on epoch state in a more complex version.
     */
    function unstakeTokensFromSlot(uint256 _amount) external whenNotPaused hasSlot {
        require(_amount > 0, "Amount must be greater than zero");
        uint256 slotId = _ownerToSlotId[msg.sender];
        require(chronicleSlots[slotId].stakedBalance >= _amount, "Insufficient staked balance");

        chronicleSlots[slotId].stakedBalance = chronicleSlots[slotId].stakedBalance.sub(_amount);

        // Transfer tokens from the contract back to the user
        bool success = stakedToken.transfer(msg.sender, _amount);
        require(success, "Token transfer failed");

        emit TokensUnstaked(slotId, msg.sender, _amount);
    }

    /**
     * @notice Submits a prediction for the current active epoch.
     * @param _prediction The prediction bytes32 value.
     */
    function submitPrediction(bytes32 _prediction) external whenNotPaused hasSlot isEpochState(_epochIdCounter.current(), EpochState.PredictionPeriod) {
        uint256 currentEpochId = _epochIdCounter.current();
        uint256 slotId = _ownerToSlotId[msg.sender];

        // Ensure user hasn't already predicted for this epoch
        require(_epochPredictions[currentEpochId][slotId] == bytes32(0), "Prediction already submitted for this epoch");

        _epochPredictions[currentEpochId][slotId] = _prediction;
        epochs[currentEpochId].totalPredictions = epochs[currentEpochId].totalPredictions.add(1);

        emit PredictionMade(currentEpochId, slotId, _prediction);
    }

    /**
     * @notice Claims rewards and Wisdom for a user's correct prediction in a completed epoch.
     * @param _epochId The ID of the epoch to claim for.
     * @dev Rewards distribution logic: Correct predictors share a pool. Wisdom is granted based on participation/correctness.
     */
    function claimEpochRewardsAndWisdom(uint256 _epochId) external whenNotPaused hasSlot isEpochOutcomeRevealed(_epochId) {
        uint256 slotId = _ownerToSlotId[msg.sender];
        ChronicleSlot storage slot = chronicleSlots[slotId];
        Epoch storage epoch = epochs[_epochId];

        require(epoch.state == EpochState.Completed, "Epoch not in completed state");
        require(!slot.claimedEpochs[_epochId], "Rewards already claimed for this epoch");
        require(_epochPredictions[_epochId][slotId] != bytes32(0), "No prediction made for this epoch");

        bytes32 userPrediction = _epochPredictions[_epochId][slotId];
        bytes32 epochOutcome = epoch.outcome;

        uint256 rewardAmount = 0;
        uint256 wisdomEarned = 0;

        bool isCorrect = (userPrediction == epochOutcome);

        if (isCorrect) {
            // Simple reward model: Correct predictors share the epoch's reward pool.
            // This pool needs to be funded separately (e.g., by admin).
            // A more complex model could redistribute incorrect stakes, but this is simpler.
            uint256 correctPredictorCount = getEpochCorrectPredictionCount(_epochId);
            if (correctPredictorCount > 0) {
                // Prevent division by zero
                rewardAmount = epoch.epochRewardPool.div(correctPredictorCount);
            }
            wisdomEarned = WISDOM_PER_CORRECT_PREDICTION;
        } else {
            wisdomEarned = WISDOM_PER_PARTICIPATION;
        }

        // Apply admin fee to the reward amount
        uint256 feeAmount = rewardAmount.mul(adminFeePercentage).div(10000);
        uint256 netRewardAmount = rewardAmount.sub(feeAmount);

        // Add rewards to staked balance and update wisdom
        slot.stakedBalance = slot.stakedBalance.add(netRewardAmount);
        slot.wisdom = slot.wisdom.add(wisdomEarned);
        accumulatedAdminFees = accumulatedAdminFees.add(feeAmount);

        slot.claimedEpochs[_epochId] = true;

        emit RewardsClaimed(_epochId, slotId, netRewardAmount, wisdomEarned);
        emit WisdomUpdated(slotId, slot.wisdom);
        if(feeAmount > 0) {
            // Optionally emit a fee collected event here if desired, or just rely on AdminFeeWithdrawn
        }
    }

    // --- Oracle Functions ---

    /**
     * @notice Starts a new epoch. Only callable by the oracle address.
     * @param _eventId An identifier for the event associated with this epoch (e.g., hash).
     * @param _epochRewardPoolAmount The amount of staked tokens to allocate to the reward pool for this epoch.
     */
    function startNewEpoch(uint256 _eventId, uint256 _epochRewardPoolAmount) external whenNotPaused onlyOracle {
        uint256 currentEpochId = _epochIdCounter.current();

        // Ensure the previous epoch is not in prediction or reveal phase
        if (currentEpochId > 0) {
             require(epochs[currentEpochId].state == EpochState.Completed || epochs[currentEpochId].state == EpochState.NotStarted,
                    "Previous epoch is not completed");
        }

        _epochIdCounter.increment();
        uint256 nextEpochId = _epochIdCounter.current();
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime.add(epochDuration);

        epochs[nextEpochId] = Epoch({
            epochId: nextEpochId,
            startTime: startTime,
            endTime: endTime,
            eventId: _eventId,
            outcome: bytes32(0), // Outcome is unknown initially
            state: EpochState.PredictionPeriod,
            totalPredictions: 0,
            epochRewardPool: _epochRewardPoolAmount
        });

        // Transfer reward tokens from Oracle/Admin to contract
        if (_epochRewardPoolAmount > 0) {
             bool success = stakedToken.transferFrom(msg.sender, address(this), _epochRewardPoolAmount);
             require(success, "Failed to transfer reward tokens");
        }


        emit EpochStarted(nextEpochId, startTime, endTime, _eventId);
    }

    /**
     * @notice Reveals the outcome for a specific epoch. Only callable by the oracle.
     * @param _epochId The ID of the epoch to reveal the outcome for.
     * @param _outcome The true outcome (bytes32) of the epoch's event.
     */
    function revealEpochOutcome(uint256 _epochId, bytes32 _outcome) external whenNotPaused onlyOracle {
        Epoch storage epoch = epochs[_epochId];

        require(epoch.epochId != 0 && _epochId < _epochIdCounter.current(), "Invalid epoch ID");
        require(epoch.state == EpochState.PredictionPeriod || epoch.state == EpochState.RevealPeriod, "Epoch not in a state to reveal outcome");
        require(block.timestamp >= epoch.endTime, "Epoch prediction period not ended");
        require(epoch.outcome == bytes32(0), "Outcome already revealed for this epoch");

        epoch.outcome = _outcome;
        epoch.state = EpochState.RevealPeriod; // Now in reveal/claim period

        // Potentially transition to Completed automatically after a reveal period + lag
        // For simplicity here, claiming transitions it for the user, or a separate function could finalize the epoch.
        // Let's just mark it completed after reveal + lag for global state:
         if (block.timestamp >= epoch.endTime.add(predictionRevealLag)) {
             epoch.state = EpochState.Completed;
         } else {
             // Allow a reveal lag period before it's fully 'Completed' and ready for claims
             epoch.state = EpochState.RevealPeriod;
         }


        emit OutcomeRevealed(_epochId, _outcome);
    }

    // --- Admin Functions ---

    /**
     * @notice Updates the address of the trusted oracle.
     * @param _newOracle The new oracle address.
     */
    function updateOracleAddress(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "New oracle address cannot be zero");
        oracleAddress = _newOracle;
        emit OracleUpdated(_newOracle);
    }

    /**
     * @notice Sets the duration for future epochs.
     * @param _newDuration The new epoch duration in seconds.
     */
    function updateEpochDuration(uint256 _newDuration) external onlyOwner {
        require(_newDuration > 0, "Epoch duration must be greater than zero");
        epochDuration = _newDuration;
    }

    /**
     * @notice Allows the owner to pause the contract. Inherited from Pausable.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @notice Allows the owner to unpause the contract. Inherited from Pausable.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @notice Allows the owner to rescue ERC20 tokens sent directly to the contract address by mistake.
     * @param _tokenAddress The address of the stuck token.
     * @param _amount The amount to rescue.
     * @dev This should NOT be used to withdraw staked tokens or reward pools.
     */
    function rescueStuckTokens(address _tokenAddress, uint256 _amount) external onlyOwner {
        require(_tokenAddress != address(stakedToken), "Cannot rescue the staked token this way");
        IERC20 stuckToken = IERC20(_tokenAddress);
        uint256 balance = stuckToken.balanceOf(address(this));
        require(balance >= _amount, "Insufficient stuck token balance");

        bool success = stuckToken.transfer(owner(), _amount);
        require(success, "Rescue transfer failed");

        emit TokensRescued(_tokenAddress, owner(), _amount);
    }

    /**
     * @notice Sets the base URI for generating Chronicle Slot (NFT) metadata.
     * @param _baseURI The base URI string.
     */
    function setSlotBaseURI(string memory _baseURI) external onlyOwner {
        slotBaseURI = _baseURI;
    }

    /**
     * @notice Sets the percentage of claimed rewards taken as an admin fee.
     * @param _feePercentage The fee percentage (0-10000, representing 0% to 100%).
     */
    function setAdminFeePercentage(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 10000, "Fee percentage cannot exceed 100%");
        adminFeePercentage = _feePercentage;
        emit AdminFeeUpdated(_feePercentage);
    }

    /**
     * @notice Allows the owner to withdraw accumulated admin fees.
     */
    function withdrawAdminFees() external onlyOwner {
        uint256 amount = accumulatedAdminFees;
        require(amount > 0, "No fees to withdraw");

        accumulatedAdminFees = 0;

        bool success = stakedToken.transfer(owner(), amount);
        require(success, "Fee withdrawal failed");

        emit AdminFeeWithdrawn(owner(), amount);
    }


    // --- View Functions (Public) ---

    /**
     * @notice Returns details about a specific epoch.
     * @param _epochId The ID of the epoch.
     * @return epochId_ ID of the epoch.
     * @return startTime Start timestamp.
     * @return endTime End timestamp.
     * @return eventId Identifier for the event.
     * @return outcome Revealed outcome (bytes32(0) if not revealed).
     * @return state Current state of the epoch.
     * @return totalPredictions Total predictions made in this epoch.
     * @return epochRewardPool Staked tokens allocated as reward pool for this epoch.
     */
    function getEpochDetails(uint256 _epochId)
        external view
        returns (
            uint256 epochId_,
            uint256 startTime,
            uint256 endTime,
            uint256 eventId,
            bytes32 outcome,
            EpochState state,
            uint256 totalPredictions,
            uint256 epochRewardPool
        )
    {
        Epoch storage epoch = epochs[_epochId];
        require(epoch.epochId != 0, "Epoch does not exist"); // Check if struct is initialized

        return (
            epoch.epochId,
            epoch.startTime,
            epoch.endTime,
            epoch.eventId,
            epoch.outcome,
            epoch.state,
            epoch.totalPredictions,
            epoch.epochRewardPool
        );
    }

    /**
     * @notice Returns details about the current epoch.
     * @dev Returns zero values if no epoch has started yet.
     * @return epochId_ ID of the current epoch.
     * @return startTime Start timestamp.
     * @return endTime End timestamp.
     * @return eventId Identifier for the event.
     * @return outcome Revealed outcome (bytes32(0) if not revealed).
     * @return state Current state of the epoch.
     * @return totalPredictions Total predictions made in this epoch.
     * @return epochRewardPool Staked tokens allocated as reward pool for this epoch.
     */
    function getCurrentEpochDetails()
        external view
        returns (
            uint256 epochId_,
            uint256 startTime,
            uint256 endTime,
            uint256 eventId,
            bytes32 outcome,
            EpochState state,
            uint256 totalPredictions,
            uint256 epochRewardPool
        )
    {
        uint256 currentEpochId = _epochIdCounter.current();
        if (currentEpochId == 0) {
            return (0, 0, 0, 0, bytes32(0), EpochState.NotStarted, 0, 0);
        }
        return getEpochDetails(currentEpochId);
    }


    /**
     * @notice Returns details about the caller's Chronicle Slot.
     * @return slotId The ID of the slot.
     * @return owner The owner address.
     * @return stakedBalance The current staked token balance.
     * @return wisdom The current wisdom score.
     */
    function getUserSlotDetails()
        external view hasSlot
        returns (uint256 slotId, address owner, uint256 stakedBalance, uint256 wisdom)
    {
        uint256 slotId_ = _ownerToSlotId[msg.sender];
        ChronicleSlot storage slot = chronicleSlots[slotId_];
        return (slot.slotId, slot.owner, slot.stakedBalance, slot.wisdom);
    }

    /**
     * @notice Returns details about a Chronicle Slot by its ID.
     * @param _slotId The ID of the slot.
     * @return slotId The ID of the slot.
     * @return owner The owner address.
     * @return stakedBalance The current staked token balance.
     * @return wisdom The current wisdom score.
     */
    function getSlotDetailsById(uint256 _slotId)
        external view
        returns (uint256 slotId, address owner, uint256 stakedBalance, uint256 wisdom)
    {
         require(chronicleSlots[_slotId].slotId != 0, "Slot does not exist");
         ChronicleSlot storage slot = chronicleSlots[_slotId];
         return (slot.slotId, slot.owner, slot.stakedBalance, slot.wisdom);
    }


    /**
     * @notice Returns the prediction made by a user's slot for a specific epoch.
     * @param _epochId The ID of the epoch.
     * @param _slotId The ID of the slot.
     * @return The prediction bytes32 value (bytes32(0) if no prediction made).
     */
    function getUserPredictionForEpoch(uint256 _epochId, uint256 _slotId) external view returns (bytes32) {
         require(epochs[_epochId].epochId != 0, "Epoch does not exist");
         require(chronicleSlots[_slotId].slotId != 0, "Slot does not exist");
        return _epochPredictions[_epochId][_slotId];
    }

    /**
     * @notice Returns the revealed outcome for a specific epoch.
     * @param _epochId The ID of the epoch.
     * @return The outcome bytes32 value (bytes32(0) if not revealed).
     */
    function getEpochOutcome(uint256 _epochId) external view returns (bytes32) {
        require(epochs[_epochId].epochId != 0, "Epoch does not exist");
        return epochs[_epochId].outcome;
    }

    /**
     * @notice Calculates potential rewards and wisdom for a user's slot for a specific epoch.
     * @param _epochId The ID of the epoch.
     * @return potentialReward The amount of tokens potentially claimable (before fees).
     * @return potentialWisdom The amount of wisdom potentially earnable.
     * @dev This is a view function to show potential, actual claim depends on state checks.
     */
    function getClaimableRewardsAndWisdom(uint256 _epochId)
        external view hasSlot isEpochOutcomeRevealed(_epochId)
        returns (uint256 potentialReward, uint256 potentialWisdom)
    {
        uint256 slotId = _ownerToSlotId[msg.sender];
        ChronicleSlot storage slot = chronicleSlots[slotId];
        Epoch storage epoch = epochs[_epochId];

        // Check if prediction was made and not yet claimed for this epoch
        if (slot.claimedEpochs[_epochId] || _epochPredictions[_epochId][slotId] == bytes32(0)) {
            return (0, 0); // Already claimed or no prediction
        }

        bytes32 userPrediction = _epochPredictions[_epochId][slotId];
        bytes32 epochOutcome = epoch.outcome;

        if (userPrediction == epochOutcome) {
             uint256 correctPredictorCount = getEpochCorrectPredictionCount(_epochId);
             uint256 rewardAmount = 0;
             if (correctPredictorCount > 0) {
                 rewardAmount = epoch.epochRewardPool.div(correctPredictorCount);
             }
             // Potential reward is before fee calculation in claim function
             return (rewardAmount, WISDOM_PER_CORRECT_PREDICTION);
        } else {
            return (0, WISDOM_PER_PARTICIPATION);
        }
    }


    /**
     * @notice Returns the Wisdom score for a user's slot.
     * @param _owner The owner address.
     * @return The current Wisdom score.
     */
    function getWisdomScore(address _owner) external view returns (uint256) {
         uint256 slotId = _ownerToSlotId[_owner];
         require(slotId != 0, "User does not have a slot");
        return chronicleSlots[slotId].wisdom;
    }

     /**
     * @notice Returns the Chronicle Slot ID for a given owner address.
     * @param _owner The owner address.
     * @return The Chronicle Slot ID (0 if none exists).
     */
    function getSlotIdByOwner(address _owner) external view returns (uint256) {
        return _ownerToSlotId[_owner];
    }


    /**
     * @notice Returns the total amount of the staked token held by the contract (staked + reward pools + fees).
     * @return The total balance.
     */
    function getTotalStakedTokensInContract() external view returns (uint256) {
        return stakedToken.balanceOf(address(this));
    }

    /**
     * @notice Returns the total number of predictions submitted in a specific epoch.
     * @param _epochId The ID of the epoch.
     * @return The total count of predictions.
     */
    function getEpochPredictionCount(uint256 _epochId) external view returns (uint256) {
         require(epochs[_epochId].epochId != 0, "Epoch does not exist");
        return epochs[_epochId].totalPredictions;
    }

    /**
     * @notice Returns the current admin fee percentage.
     * @return The fee percentage (0-10000).
     */
    function getAdminFeePercentage() external view returns (uint256) {
        return adminFeePercentage;
    }

    /**
     * @notice Returns the total accumulated admin fees ready for withdrawal.
     * @return The amount of accumulated fees in staked tokens.
     */
    function getAccumulatedAdminFees() external view returns (uint256) {
        return accumulatedAdminFees;
    }


    // --- ERC721 View Functions (Conceptual NFT) ---

    /**
     * @notice Generates a dynamic metadata URI for a Chronicle Slot.
     * @param _slotId The ID of the slot.
     * @return The metadata URI.
     * @dev This function simulates dynamic NFT metadata based on on-chain state.
     *      The actual metadata JSON would be served from the base URI + query params.
     */
    function tokenURI(uint256 _slotId) external view returns (string memory) {
        require(chronicleSlots[_slotId].slotId != 0, "Slot does not exist");

        // Construct a simple URI with parameters
        // Example: base_uri/slot/1?owner=0xabc...&staked=1000&wisdom=500
        string memory uri = string(abi.encodePacked(slotBaseURI, "/slot/", _slotId.toString()));
        uri = string(abi.encodePacked(uri, "?owner=", Strings.toHexString(chronicleSlots[_slotId].owner)));
        uri = string(abi.encodePacked(uri, "&staked=", chronicleSlots[_slotId].stakedBalance.toString()));
        uri = string(abi.encodePacked(uri, "&wisdom=", chronicleSlots[_slotId].wisdom.toString()));

        // Add more parameters as needed to reflect slot state evolution

        return uri;
    }

    /**
     * @notice ERC165 support function.
     * @param interfaceId The interface ID to check.
     * @return True if the interface is supported, false otherwise.
     * @dev This contract minimally supports ERC721 views for conceptual compatibility.
     *      It does NOT support transfer/approval interfaces (0x80ac58cd, 0x228a0a13).
     */
    function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
        // ERC165 (0x01ffc9a7) interface support
        // ERC721 Metadata (0x5b5e139f) interface support (for tokenURI)
        return interfaceId == type(IERC165).interfaceId ||
               interfaceId == 0x5b5e139f; // ERC721Metadata interface ID
               // Add ERC721Enumerable (0x780e9d63) if implementing token supply views
    }


    // --- Internal/Helper Functions ---

    /**
     * @notice Calculates the number of correct predictions for a specific epoch.
     * @param _epochId The ID of the epoch.
     * @return The count of correct predictions.
     * @dev This can be gas intensive for large numbers of predictions.
     *      A more scalable approach might track this count during the prediction phase or use off-chain calculation for rewards.
     *      Exposed as a public view function as well (#28).
     */
    function getEpochCorrectPredictionCount(uint256 _epochId) public view returns (uint256) {
        require(epochs[_epochId].epochId != 0, "Epoch does not exist");
        if (epochs[_epochId].outcome == bytes32(0)) {
            return 0; // Cannot count correct predictions if outcome isn't revealed
        }

        uint256 correctCount = 0;
        bytes32 outcome = epochs[_epochId].outcome;

        // Iterate through all potential slot IDs up to the current max
        // NOTE: This iteration can be very gas-expensive if _slotIdCounter.current() is large.
        // In a real-world scenario, a more efficient method like storing a list of participants per epoch
        // or using an off-chain service for calculation would be necessary.
        uint256 maxSlotId = _slotIdCounter.current();
        for (uint256 i = 1; i <= maxSlotId; i++) {
            if (_epochPredictions[_epochId][i] != bytes32(0) && _epochPredictions[_epochId][i] == outcome) {
                 // Also check if the slot exists, though prediction implies existence
                 if(chronicleSlots[i].slotId != 0) {
                    correctCount++;
                 }
            }
        }

        return correctCount;
    }
}
```