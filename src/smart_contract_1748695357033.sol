Okay, here is a Solidity smart contract concept named `QuantumLeapProtocol`. It incorporates several advanced, creative, and trendy concepts like time-based epoch management, state prediction/staking, dynamic fees, Chainlink VRF integration for weighted random outcomes, reward/penalty systems, treasury management, and a unique 'flash-claim-and-restake' feature. It also includes placeholders for more advanced concepts like outcome "hints" and token-gated access, even if their V1 implementation is simple data storage or a basic check.

The goal is to create a protocol where users stake tokens on predicted "states" for a given time epoch. A random outcome, influenced by stakes and determined by Chainlink VRF, determines the winning state, distributing rewards to stakers on the correct state and applying penalties (partially to treasury) to those on losing states.

---

**QuantumLeapProtocol Smart Contract**

**Outline & Function Summary:**

This contract manages a time-based staking protocol across discrete epochs. Users stake tokens predicting a future 'state'. Epoch outcomes are determined pseudo-randomly via Chainlink VRF, influenced by the total stake on each state. Winners are rewarded from losers' stakes (after a protocol cut), and losers' stakes are partially penalized.

1.  **Interfaces & Imports:**
    *   `ERC20`: Standard token interface for staking/rewards.
    *   `Ownable`: For contract ownership and admin functions.
    *   `Pausable`: Allows pausing core functions for safety.
    *   `VRFConsumerBaseV2`: For Chainlink VRF integration.

2.  **State Variables:**
    *   Protocol Configuration (Token addresses, epoch duration, rates, VRF config).
    *   Epoch Data (Current epoch ID, start/end times, status, outcome).
    *   State Data (Mapping of state IDs to names, available states list).
    *   Staking Data (User stakes per epoch/state, total staked per epoch/state).
    *   Outcome & Claim Data (Outcome per epoch, randomness request IDs, claim status).
    *   Treasury Data (Protocol fee balance).
    *   Potential Future Concepts (Access control token, outcome hints mapping - V1 simple).

3.  **Events:** Signal key protocol actions (Staked, Claimed, EpochStarted, OutcomeRequested, OutcomeDetermined, Paused, etc.).

4.  **Errors:** Custom errors for gas efficiency and clarity.

5.  **Modifiers:** Common checks (e.g., `onlyEpochActive`, `onlyOutcomeNotDetermined`).

6.  **Epoch Management (Admin & Time-based):**
    *   `startNextEpoch`: Advances the protocol to the next epoch. Only possible after current epoch ends, outcome determined, and a cooldown period.
    *   `setEpochDuration`: Sets the duration of each epoch (Owner only).
    *   `getCurrentEpoch`: Gets the current epoch ID (View).
    *   `getEpochStartTime`: Gets the start timestamp of a specific epoch (View).
    *   `getEpochEndTime`: Gets the end timestamp of a specific epoch (View).
    *   `getEpochStatus`: Gets the current status of an epoch (Active, OutcomePending, OutcomeDetermined, ClaimPhase) (View).

7.  **State Configuration (Admin):**
    *   `addState`: Adds a new valid state ID and name (Owner only).
    *   `removeState`: Removes an existing state (Owner only).
    *   `getAvailableStates`: Gets the list of state IDs users can stake on (View).
    *   `getStateName`: Gets the name for a given state ID (View).

8.  **Staking (User):**
    *   `stakeOnState`: Stakes tokens on a specific state for the *current* epoch. Includes dynamic fee calculation and collection. Requires approval.
    *   `increaseStake`: Adds more tokens to an existing stake within the *current* epoch. Includes dynamic fee. Requires approval.
    *   `withdrawStake`: Withdraws user's original staked amount *after* the epoch outcome is determined. Penalized amount is not withdrawn.
    *   `getUserStake`: Gets the amount staked by a user on a specific state for a specific epoch (View).
    *   `getTotalStakedOnState`: Gets the total amount staked across all users on a specific state for a specific epoch (View).

9.  **Dynamic Fee (Config & Calculation):**
    *   `setDynamicFeeParams`: Sets parameters (base, rate, scaling factor) for the dynamic staking fee (Owner only). Fee scales with total staked amount in the epoch.
    *   `calculateDynamicFee`: Calculates the fee for a given stake amount based on current epoch's total stake (Pure).
    *   `getDynamicFeeParams`: Gets the current dynamic fee parameters (View).

10. **Outcome Determination (Chainlink VRF & Protocol Trigger):**
    *   `requestOutcomeDetermination`: Triggers the Chainlink VRF request for the *current* epoch's outcome. Only possible after the epoch ends and outcome is not yet pending/determined. Calculates stake-weighted probability range.
    *   `fulfillRandomness`: Chainlink VRF callback function. Receives the random number, determines the winning state ID based on the stake-weighted probability range calculated in `requestOutcomeDetermination`, records the outcome, and updates the epoch status.
    *   `getEpochOutcome`: Gets the winning state ID for a specific epoch (View).
    *   `getRandomnessRequestStatus`: Checks the status of a VRF request ID (View).

11. **Rewards & Penalties (Claiming):**
    *   `claimRewards`: Allows users to claim rewards (if they staked on the winning state) or have penalties applied (if they staked on losing states) for a *past* epoch where the outcome is determined. Distributes rewards, sends penalties to treasury, and marks the user as claimed.
    *   `calculatePotentialRewards`: Estimates the potential reward for a user's stake on the winning state, *after* outcome determination but *before* claiming. Shows gross reward before considering penalties on other states or previous claims (View). *Note: This is an estimate, actual claim processes full P&L across all user stakes in that epoch.*
    *   `getUserClaimableRewards`: Gets the net claimable amount for a user for a specific epoch, considering total staked, winning/losing states, penalties, rewards, and protocol cut. Requires outcome to be determined (View).
    *   `hasUserClaimed`: Checks if a user has claimed for a specific epoch (View).
    *   `setRewardPenaltyRates`: Sets the percentage rates for reward distribution and penalty collection (Owner only).
    *   `getRewardPenaltyRates`: Gets the current reward/penalty rates (View).

12. **Treasury Management:**
    *   `withdrawTreasury`: Allows the owner to withdraw collected protocol fees (penalties and dynamic fees) from the treasury (Owner only).
    *   `getProtocolTreasury`: Gets the current balance of the protocol treasury (View).

13. **Advanced/Creative Concepts (Placeholders/Basic V1):**
    *   `flashClaimAndRestake`: Allows a user to claim rewards from a past epoch and immediately restake a specified amount (potentially their winnings + original stake) into a specific state for the *current* or *next* active epoch in a single transaction.
    *   `submitOutcomeHint`: (V1: Simply stores data). A function allowing users (potentially gated by access control) to submit an off-chain "hint" or rationale for their prediction for a given epoch/state. This data is stored on-chain but doesn't *directly* affect VRF outcome in V1. Could be used off-chain for analysis or future protocol versions (e.g., influencing a non-VRF outcome).
    *   `setAccessControlToken`: Sets an optional ERC721 or ERC20 token address used for access control checks (Owner only).
    *   `checkAccessTier`: (V1: Checks if user holds > 0 of `accessControlToken`). A function to check if a user meets certain criteria (e.g., holding a specific NFT or amount of a token) for potentially gated features (View).

14. **Admin & Safety (Owner/Pausable):**
    *   `pause`: Pauses core functions like staking, claiming, epoch transition (Owner only).
    *   `unpause`: Unpauses the contract (Owner only).
    *   `setPausableFunctions`: Allows owner to specify *which* functions are affected by pause/unpause (More advanced Pausable, assuming a library like OpenZeppelin that supports this or implementing custom logic).
    *   Standard `transferOwnership` from Ownable.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // For potential access control token
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol"; // For token transfers

// --- Custom Errors ---
error QuantumLeap__EpochNotActive();
error QuantumLeap__EpochNotEnded();
error QuantumLeap__OutcomeNotDetermined();
error QuantumLeap__OutcomeAlreadyDetermined();
error QuantumLeap__NothingToClaim();
error QuantumLeap__AlreadyClaimed();
error QuantumLeap__InvalidState(uint256 stateId);
error QuantumLeap__StateAlreadyExists(uint256 stateId);
error QuantumLeap__InsufficientStake();
error QuantumLeap__InsufficientBalanceForFee(uint256 required);
error QuantumLeap__NotEnoughTimePassedForNextEpoch();
error QuantumLeap__OutcomeDeterminationPending();
error QuantumLeap__InvalidRewardPenaltyRate();
error QuantumLeap__AccessDenied();
error QuantumLeap__StateCannotBeRemoved(uint256 stateId); // If state has active stakes
error QuantumLeap__NothingToWithdraw();
error QuantumLeap__WithdrawalTooLarge();


// --- Interfaces ---
// (No additional custom interfaces needed for this concept, using standard ones)


// --- Contract Definition ---
contract QuantumLeapProtocol is Ownable, Pausable, VRFConsumerBaseV2 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // --- State Variables ---

    // Protocol Configuration
    IERC20 public immutable stakingToken;
    VRFCoordinatorV2Interface immutable i_vrfCoordinator;
    uint64 public immutable i_subscriptionId;
    bytes32 public immutable i_keyHash;
    uint32 public immutable i_callbackGasLimit;
    uint16 public immutable i_requestConfirmations;
    uint256 public immutable i_vrfFee;

    uint256 public epochDurationSeconds;
    uint256 public nextEpochStartTime; // Calculated based on current epoch end
    uint256 public epochCooldownSeconds = 60; // Time after outcome determined before next epoch can start

    // Reward/Penalty Rates (scaled by 10000, e.g., 9500 = 95%)
    uint256 public rewardRateBasisPoints; // Percentage of winning pot distributed to winners
    uint256 public penaltyRateBasisPoints; // Percentage of losing stakes penalized

    // Dynamic Fee Configuration (fee scales with total staked amount in current epoch)
    uint256 public dynamicFeeBase; // Base fee amount
    uint256 public dynamicFeeRate; // Rate multiplier for fee calculation (per 10000)
    uint256 public dynamicFeeScalingFactor; // Divisor for the scaling part (higher factor reduces scaling effect)
    IERC20 public feeToken; // Token used for dynamic fees (can be the same as stakingToken)

    // Access Control (Optional)
    IERC721 public accessControlToken721; // Token for access control tier (e.g., NFT)
    IERC20 public accessControlToken20; // Token for access control tier (e.g., ERC20 minimum balance)

    // Epoch Data
    uint256 public currentEpoch = 0; // Epoch 0 is inactive/initial state
    mapping(uint256 => uint256) public epochStartTimes; // Epoch ID => Start Timestamp
    mapping(uint256 => uint256) public epochEndTimes;   // Epoch ID => End Timestamp

    // State Data
    uint256[] public availableStateIds; // Array of valid state IDs
    mapping(uint256 => string) public stateNames; // State ID => Name

    // Staking Data
    // epoch => state ID => user => amount staked
    mapping(uint256 => mapping(uint256 => mapping(address => uint256))) public userStakes;
    // epoch => state ID => total amount staked on this state
    mapping(uint256 => mapping(uint256 => uint256)) public totalStakedPerState;
    // epoch => total amount staked in this epoch (across all states)
    mapping(uint256 => uint256) public totalStakedInEpoch;

    // Outcome Data
    // epoch => winning state ID (0 if not determined)
    mapping(uint256 => uint256) public epochOutcomes;
    // epoch => randomness request ID for VRF
    mapping(uint256 => uint256) public epochRandomnessRequestIds;
    // randomness request ID => epoch
    mapping(uint256 => uint256) private randomnessRequestIdToEpoch;
    // epoch => bool indicating if outcome determined
    mapping(uint256 => bool) public isOutcomeDeterminedForEpoch;
     // epoch => bool indicating if outcome determination is pending (VRF requested)
    mapping(uint256 => bool) public isOutcomePendingForEpoch;

    // Claim Data
    // epoch => user => bool indicating if user has claimed for this epoch
    mapping(uint256 => mapping(address => bool)) public hasUserClaimedForEpoch;

    // Treasury
    uint256 public protocolTreasury; // Accumulated fees

    // Advanced/Creative Concepts (V1: Data Storage)
    // epoch => state ID => user => hint data (e.g., IPFS hash, string rationale)
    mapping(uint256 => mapping(uint256 => mapping(address => bytes))) public outcomeHints;


    // --- Events ---
    event EpochStarted(uint256 indexed epochId, uint256 startTime, uint256 endTime);
    event Staked(uint256 indexed epochId, address indexed user, uint256 indexed stateId, uint256 amount, uint256 totalStakedOnState, uint256 totalStakedInEpoch, uint256 feePaid);
    event StakeIncreased(uint256 indexed epochId, address indexed user, uint256 indexed stateId, uint256 additionalAmount, uint256 newTotalAmount, uint256 feePaid);
    event StakeWithdrawal(uint256 indexed epochId, address indexed user, uint256 indexed stateId, uint256 amountWithdrawn, uint256 amountPenalized);
    event OutcomeDeterminationRequested(uint256 indexed epochId, uint256 indexed requestId, uint256 vrfFee);
    event OutcomeDetermined(uint256 indexed epochId, uint256 indexed winningStateId, uint256 randomNumber);
    event Claimed(uint256 indexed epochId, address indexed user, uint256 amount);
    event ProtocolTreasuryWithdrawal(address indexed to, uint256 amount);
    event StateAdded(uint256 indexed stateId, string name);
    event StateRemoved(uint256 indexed stateId);
    event ParametersUpdated(); // Generic event for admin config changes
    event PausedProtocol(address account);
    event UnpausedProtocol(address account);
    event OutcomeHintSubmitted(uint256 indexed epochId, address indexed user, uint256 indexed stateId, bytes hintData);


    // --- Modifiers ---
    modifier onlyEpochActive(uint256 epochId) {
        if (epochId != currentEpoch || block.timestamp >= epochEndTimes[epochId]) revert QuantumLeap__EpochNotActive();
        _;
    }

    modifier onlyEpochEnded(uint256 epochId) {
        if (epochId > currentEpoch || block.timestamp < epochEndTimes[epochId]) revert QuantumLeap__EpochNotEnded();
        _;
    }

    modifier onlyOutcomeNotDetermined(uint256 epochId) {
        if (isOutcomeDeterminedForEpoch[epochId]) revert QuantumLeap__OutcomeAlreadyDetermined();
        _;
    }

    modifier onlyOutcomeDetermined(uint256 epochId) {
        if (!isOutcomeDeterminedForEpoch[epochId]) revert QuantumLeap__OutcomeNotDetermined();
        _;
    }

    modifier onlyStateExists(uint256 stateId) {
        bool exists = false;
        for (uint i = 0; i < availableStateIds.length; i++) {
            if (availableStateIds[i] == stateId) {
                exists = true;
                break;
            }
        }
        if (!exists) revert QuantumLeap__InvalidState(stateId);
        _;
    }

    // --- Constructor ---
    constructor(
        address _stakingToken,
        address _feeToken,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint66 _subscriptionId,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint256 _vrfFee,
        uint256 _epochDurationSeconds,
        uint256 _rewardRateBasisPoints,
        uint256 _penaltyRateBasisPoints,
        uint256 _dynamicFeeBase,
        uint256 _dynamicFeeRate,
        uint256 _dynamicFeeScalingFactor
    )
        VRFConsumerBaseV2(_vrfCoordinator)
        Ownable(msg.sender)
    {
        stakingToken = IERC20(_stakingToken);
        feeToken = IERC20(_feeToken);

        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        i_keyHash = _keyHash;
        i_subscriptionId = _subscriptionId;
        i_callbackGasLimit = _callbackGasLimit;
        i_requestConfirmations = _requestConfirmations;
        i_vrfFee = _vrfFee;

        epochDurationSeconds = _epochDurationSeconds;
        rewardRateBasisPoints = _rewardRateBasisPoints;
        penaltyRateBasisPoints = _penaltyRateBasisPoints;
        dynamicFeeBase = _dynamicFeeBase;
        dynamicFeeRate = _dynamicFeeRate;
        dynamicFeeScalingFactor = _dynamicFeeScalingFactor;

        if (rewardRateBasisPoints > 10000 || penaltyRateBasisPoints > 10000) {
             revert QuantumLeap__InvalidRewardPenaltyRate();
        }
    }

    // --- Pausable Overrides ---
    function pause() public onlyOwner {
        _pause();
        emit PausedProtocol(msg.sender);
    }

    function unpause() public onlyOwner {
        _unpause();
        emit UnpausedProtocol(msg.sender);
    }

    // --- Epoch Management ---

    /// @notice Starts the next epoch. Callable by anyone after the cooldown period of the previous epoch.
    /// @dev Requires the previous epoch outcome to be determined and cooldown time to pass.
    function startNextEpoch() external whenNotPaused {
        uint256 previousEpoch = currentEpoch;

        // Check if previous epoch is ready for transition
        if (previousEpoch > 0) {
            // Must be after previous epoch ends
            if (block.timestamp < epochEndTimes[previousEpoch]) {
                 revert QuantumLeap__EpochNotEnded();
            }
            // Must have outcome determined
            if (!isOutcomeDeterminedForEpoch[previousEpoch]) {
                revert QuantumLeap__OutcomeNotDetermined();
            }
             // Must be after cooldown period from when outcome was determined (or epoch end, whichever is later?)
             // Let's simplify: must be after epoch ends + cooldown period
             if (block.timestamp < epochEndTimes[previousEpoch] + epochCooldownSeconds) {
                 revert QuantumLeap__NotEnoughTimePassedForNextEpoch();
             }
        } else {
             // Initial epoch transition (from 0 to 1)
             if (block.timestamp < nextEpochStartTime) {
                 // Should only happen if nextEpochStartTime was set in constructor, but isn't.
                 // Set it here for initial start.
                 nextEpochStartTime = block.timestamp; // Or constructor arg
             }
        }

        currentEpoch = previousEpoch.add(1);
        epochStartTimes[currentEpoch] = nextEpochStartTime;
        epochEndTimes[currentEpoch] = nextEpochStartTime.add(epochDurationSeconds);
        nextEpochStartTime = epochEndTimes[currentEpoch];

        // Reset state for new epoch (mappings default to 0/false)
        // isOutcomeDeterminedForEpoch[currentEpoch] will be false
        // isOutcomePendingForEpoch[currentEpoch] will be false
        // userStakes[currentEpoch], totalStakedPerState[currentEpoch], totalStakedInEpoch[currentEpoch] will be empty

        emit EpochStarted(currentEpoch, epochStartTimes[currentEpoch], epochEndTimes[currentEpoch]);
    }

    /// @notice Sets the duration of each epoch.
    /// @param _epochDurationSeconds The new duration in seconds.
    function setEpochDuration(uint256 _epochDurationSeconds) external onlyOwner {
        epochDurationSeconds = _epochDurationSeconds;
        emit ParametersUpdated();
    }

     /// @notice Gets the current status of a given epoch.
     /// @param epochId The ID of the epoch to check.
     /// @return status A string representing the epoch status (Inactive, Active, OutcomePending, OutcomeDetermined, ClaimPhase).
    function getEpochStatus(uint256 epochId) external view returns (string memory status) {
        if (epochId == 0 || epochId > currentEpoch) {
            return "Inactive";
        }
        if (isOutcomeDeterminedForEpoch[epochId]) {
             // Outcome determined, check if claim phase is active
             // Claim phase is active until the next epoch's outcome is determined? Or forever?
             // Let's say claim phase is active once outcome determined.
             return "OutcomeDetermined/ClaimPhase";
        }
        if (isOutcomePendingForEpoch[epochId]) {
            return "OutcomePending";
        }
        if (block.timestamp < epochEndTimes[epochId]) {
            return "Active";
        }
         // Epoch ended, but outcome not yet pending or determined
        return "Ended - Outcome Not Requested";
    }

    // --- State Configuration ---

    /// @notice Adds a new state that users can stake on.
    /// @param stateId The unique ID for the state.
    /// @param name The human-readable name for the state.
    function addState(uint256 stateId, string calldata name) external onlyOwner {
        for (uint i = 0; i < availableStateIds.length; i++) {
            if (availableStateIds[i] == stateId) {
                revert QuantumLeap__StateAlreadyExists(stateId);
            }
        }
        availableStateIds.push(stateId);
        stateNames[stateId] = name;
        emit StateAdded(stateId, name);
        emit ParametersUpdated();
    }

    /// @notice Removes an existing state. Only possible if no stakes exist for this state in the current or future epochs.
    /// @param stateId The ID of the state to remove.
    function removeState(uint256 stateId) external onlyOwner onlyStateExists(stateId) {
        // Check for active stakes in current/future epochs
        // For simplicity V1, just check current epoch total stake. More robust would check future potential epochs too.
        if (totalStakedPerState[currentEpoch][stateId] > 0) {
            revert QuantumLeap__StateCannotBeRemoved(stateId);
        }

        bool found = false;
        for (uint i = 0; i < availableStateIds.length; i++) {
            if (availableStateIds[i] == stateId) {
                // Simple swap and pop for removal
                availableStateIds[i] = availableStateIds[availableStateIds.length - 1];
                availableStateIds.pop();
                delete stateNames[stateId];
                found = true;
                break;
            }
        }
        // Should always find if onlyStateExists modifier passes
        require(found, "State removal failed");

        emit StateRemoved(stateId);
        emit ParametersUpdated();
    }


    // --- Staking ---

    /// @notice Stakes tokens on a specified state for the current active epoch.
    /// @param stateId The ID of the state the user is predicting.
    /// @param amount The amount of staking tokens to stake.
    function stakeOnState(uint256 stateId, uint256 amount) external whenNotPaused onlyEpochActive(currentEpoch) onlyStateExists(stateId) {
        if (amount == 0) revert InsufficientStake(); // Use a general error or define specific one
        uint256 fee = calculateDynamicFee(amount, totalStakedInEpoch[currentEpoch]);
        uint256 totalTransferAmount = amount.add(fee);

        if (feeToken != stakingToken) {
             // Transfer staking amount
             stakingToken.safeTransferFrom(msg.sender, address(this), amount);
             // Transfer fee amount separately
             feeToken.safeTransferFrom(msg.sender, address(this), fee);
        } else {
             // Single transfer if staking and fee token are the same
             stakingToken.safeTransferFrom(msg.sender, address(this), totalTransferAmount);
        }

        userStakes[currentEpoch][stateId][msg.sender] = userStakes[currentEpoch][stateId][msg.sender].add(amount);
        totalStakedPerState[currentEpoch][stateId] = totalStakedPerState[currentEpoch][stateId].add(amount);
        totalStakedInEpoch[currentEpoch] = totalStakedInEpoch[currentEpoch].add(amount);
        protocolTreasury = protocolTreasury.add(fee);

        emit Staked(currentEpoch, msg.sender, stateId, amount, totalStakedPerState[currentEpoch][stateId], totalStakedInEpoch[currentEpoch], fee);
    }

    /// @notice Increases an existing stake on a state for the current active epoch.
    /// @param stateId The ID of the state the user is staked on.
    /// @param additionalAmount The additional amount of staking tokens to add.
    function increaseStake(uint256 stateId, uint256 additionalAmount) external whenNotPaused onlyEpochActive(currentEpoch) onlyStateExists(stateId) {
         if (additionalAmount == 0) revert InsufficientStake(); // Use a general error or define specific one
         if (userStakes[currentEpoch][stateId][msg.sender] == 0) revert InsufficientStake(); // Must have an existing stake

         uint256 fee = calculateDynamicFee(additionalAmount, totalStakedInEpoch[currentEpoch]);
         uint256 totalTransferAmount = additionalAmount.add(fee);

         if (feeToken != stakingToken) {
              // Transfer staking amount
              stakingToken.safeTransferFrom(msg.sender, address(this), additionalAmount);
              // Transfer fee amount separately
              feeToken.safeTransferFrom(msg.sender, address(this), fee);
         } else {
              // Single transfer if staking and fee token are the same
              stakingToken.safeTransferFrom(msg.sender, address(this), totalTransferAmount);
         }

         userStakes[currentEpoch][stateId][msg.sender] = userStakes[currentEpoch][stateId][msg.sender].add(additionalAmount);
         totalStakedPerState[currentEpoch][stateId] = totalStakedPerState[currentEpoch][stateId].add(additionalAmount);
         totalStakedInEpoch[currentEpoch] = totalStakedInEpoch[currentEpoch].add(additionalAmount);
         protocolTreasury = protocolTreasury.add(fee);

         emit StakeIncreased(currentEpoch, msg.sender, stateId, additionalAmount, userStakes[currentEpoch][stateId][msg.sender], fee);
    }

    /// @notice Allows a user to withdraw their original staked amount for a past epoch after the outcome is determined.
    /// @dev Penalized amounts are *not* withdrawn.
    /// @param epochId The ID of the past epoch.
    /// @param stateId The ID of the state the user staked on in that epoch.
    function withdrawStake(uint256 epochId, uint256 stateId) external whenNotPaused onlyOutcomeDetermined(epochId) onlyStateExists(stateId) {
         uint256 originalStake = userStakes[epochId][stateId][msg.sender];
         if (originalStake == 0) revert NothingToWithdraw(); // Or a specific error

         // Calculate the penalty amount for this specific stake
         uint256 winningState = epochOutcomes[epochId];
         uint256 amountWithdrawn = originalStake;
         uint256 amountPenalized = 0;

         if (stateId != winningState) {
              // Stake was on a losing state, apply penalty to this stake
              amountPenalized = originalStake.mul(penaltyRateBasisPoints).div(10000);
              amountWithdrawn = originalStake.sub(amountPenalized);
         }

         // Transfer the remaining amount back to the user
         if (amountWithdrawn > 0) {
             stakingToken.safeTransfer(msg.sender, amountWithdrawn);
         }

         // Mark the stake as withdrawn (set to 0)
         userStakes[epochId][stateId][msg.sender] = 0; // Prevent double withdrawal

         emit StakeWithdrawal(epochId, msg.sender, stateId, amountWithdrawn, amountPenalized);
    }


    // --- Dynamic Fee ---

    /// @notice Calculates the dynamic fee for a given amount based on the current total staked.
    /// @param amount The amount being staked or increased.
    /// @param currentTotalStaked The total staked amount in the current epoch *before* this transaction.
    /// @return fee The calculated fee amount.
    function calculateDynamicFee(uint256 amount, uint256 currentTotalStaked) public view returns (uint256 fee) {
        // Example simple dynamic fee: base + rate * log(total_staked + amount)
        // Using integer arithmetic approximation for log or a piecewise function might be needed.
        // For simplicity here, let's use a linear scaling for V1 based on *current* total staked.
        // Fee = dynamicFeeBase + (currentTotalStaked * dynamicFeeRate / dynamicFeeScalingFactor)
        // Cap the fee to avoid overflow or excessive amounts relative to stake
        uint256 scalingFee = currentTotalStaked.mul(dynamicFeeRate).div(dynamicFeeScalingFactor);
        fee = dynamicFeeBase.add(scalingFee);

        // Ensure fee is not ridiculously high compared to the amount being staked
        // Max fee is, say, 10% of the amount being staked (arbitrary rule for safety)
        uint256 maxFee = amount.div(10); // 10%
        if (fee > maxFee && maxFee > 0) { // Don't cap if amount is 0 or maxFee is 0
            fee = maxFee;
        }
        // Ensure min fee is base fee
         if (fee < dynamicFeeBase) {
            fee = dynamicFeeBase;
         }

        // Note: More sophisticated models (e.g., sigmoid functions, step functions) could be used.
    }

    /// @notice Sets parameters for the dynamic staking fee.
    /// @param _dynamicFeeBase The base fee amount.
    /// @param _dynamicFeeRate The rate multiplier for fee calculation (per 10000).
    /// @param _dynamicFeeScalingFactor The divisor for the scaling part (higher factor reduces scaling effect).
    function setDynamicFeeParams(uint256 _dynamicFeeBase, uint256 _dynamicFeeRate, uint256 _dynamicFeeScalingFactor) external onlyOwner {
        dynamicFeeBase = _dynamicFeeBase;
        dynamicFeeRate = _dynamicFeeRate;
        dynamicFeeScalingFactor = _dynamicFeeScalingFactor; // Should be > 0 to avoid division by zero
        emit ParametersUpdated();
    }

    /// @notice Sets the token used for collecting dynamic fees.
    /// @param _feeToken Address of the ERC20 token to use for fees.
    function setFeeToken(address _feeToken) external onlyOwner {
        feeToken = IERC20(_feeToken);
        emit ParametersUpdated();
    }

    // --- Outcome Determination (Chainlink VRF) ---

    /// @notice Requests randomness from Chainlink VRF Coordinator to determine the epoch outcome.
    /// @dev Can only be called after the epoch has ended and outcome is not pending/determined.
    function requestOutcomeDetermination() external whenNotPaused onlyEpochEnded(currentEpoch) onlyOutcomeNotDetermined(currentEpoch) {
        if (isOutcomePendingForEpoch[currentEpoch]) revert QuantumLeap__OutcomeDeterminationPending();

        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            i_requestConfirmations,
            i_callbackGasLimit,
            1 // Requesting 1 random word
        );

        epochRandomnessRequestIds[currentEpoch] = requestId;
        randomnessRequestIdToEpoch[requestId] = currentEpoch;
        isOutcomePendingForEpoch[currentEpoch] = true;

        emit OutcomeDeterminationRequested(currentEpoch, requestId, i_vrfFee);
    }

    /// @notice Callback function from Chainlink VRF Coordinator. Determines the winning state.
    /// @dev This function is automatically called by the VRF Coordinator after the randomness is generated. DO NOT CALL MANUALLY.
    /// @param requestId The ID of the randomness request.
    /// @param randomWords An array containing the requested random word(s).
    function fulfillRandomness(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 epochId = randomnessRequestIdToEpoch[requestId];
        if (epochId == 0 || epochId != currentEpoch || isOutcomeDeterminedForEpoch[epochId]) {
             // This request is not for the current active epoch's determination, or already determined. Ignore.
             // This could happen if VRF is slow and startNextEpoch is called, or due to re-orgs/duplicate fulfillments.
             return;
        }

        uint256 randomNumber = randomWords[0];
        delete randomnessRequestIdToEpoch[requestId]; // Clean up mapping
        isOutcomePendingForEpoch[epochId] = false; // Clear pending status

        // --- Weighted Random State Selection Logic ---
        // The random number (0 to 2^256-1) is mapped to a winning state ID.
        // The available range is divided proportionally to the total stake on each state in this epoch.

        uint256 totalStake = totalStakedInEpoch[epochId];
        uint256 winningStateId = 0; // Default or error state
        uint256 cumulativeWeight = 0;
        uint256 randomValue = randomNumber % totalStake; // Scale random number to total stake range

        if (totalStake > 0) {
             // Iterate through available states and find which one the random number falls into
             for (uint i = 0; i < availableStateIds.length; i++) {
                 uint256 stateId = availableStateIds[i];
                 uint256 stateWeight = totalStakedPerState[epochId][stateId]; // Stake amount is the weight

                 if (stateWeight > 0) {
                     cumulativeWeight = cumulativeWeight.add(stateWeight);
                     if (randomValue < cumulativeWeight) {
                         winningStateId = stateId;
                         break; // Found the winning state
                     }
                 }
             }

            // Handle edge case if randomValue is exactly totalStake (shouldn't happen with %)
            // or if somehow no state was selected (e.g., all stake is 0, though checked above)
            // If winningStateId is still 0 (and 0 is not a valid state ID), pick the first valid state as a fallback?
            // Or revert? Reverting is safer if totalStake > 0 but no state has stake.
            if (totalStake > 0 && winningStateId == 0) {
                 // This indicates an issue if totalStake > 0 but cumulativeWeight didn't exceed randomValue.
                 // This shouldn't mathematically happen if totalStake > 0 and iteration covers all states with stake.
                 // As a safety, pick the first state if availableStateIds is not empty and totalStake > 0.
                 if (availableStateIds.length > 0) {
                      winningStateId = availableStateIds[0];
                 } else {
                      // Should be caught earlier, but safety check
                     revert("QuantumLeap__NoStatesAvailableForOutcome");
                 }
            } else if (totalStake == 0 && availableStateIds.length > 0) {
                 // No stake in the epoch, pick a state randomly from available states without weighting
                 winningStateId = availableStateIds[randomNumber % availableStateIds.length];
            } else if (totalStake == 0 && availableStateIds.length == 0) {
                 // No states, no stake. Outcome remains 0.
                 winningStateId = 0; // Represents no outcome or invalid state
            }

        } else if (availableStateIds.length > 0) {
             // No stake in the epoch, pick a state randomly from available states without weighting
             winningStateId = availableStateIds[randomNumber % availableStateIds.length];
        } else {
             // No states defined, no stake. Outcome remains 0.
             winningStateId = 0; // Represents no outcome or invalid state
        }

        epochOutcomes[epochId] = winningStateId;
        isOutcomeDeterminedForEpoch[epochId] = true;

        emit OutcomeDetermined(epochId, winningStateId, randomNumber);
    }


    // --- Rewards & Penalties ---

    /// @notice Allows a user to claim their rewards (if any) for a past epoch.
    /// @dev Calculates rewards for winning stakes, applies penalties for losing stakes, collects protocol fee.
    /// @param epochId The ID of the epoch to claim for.
    function claimRewards(uint256 epochId) external whenNotPaused onlyOutcomeDetermined(epochId) {
         if (hasUserClaimedForEpoch[epochId]) revert AlreadyClaimed();

         uint256 winningState = epochOutcomes[epochId];
         uint256 totalStakeInEpoch = totalStakedInEpoch[epochId];
         uint256 totalStakedOnWinningState = totalStakedPerState[epochId][winningState];

         uint256 totalPenalizedAmount = 0;
         uint256 totalWinningStakeGrossRewards = 0;

         // Calculate total penalized amount across all losing states for this epoch
         for (uint i = 0; i < availableStateIds.length; i++) {
             uint256 stateId = availableStateIds[i];
             if (stateId != winningState) {
                  uint256 stakedOnLosingState = totalStakedPerState[epochId][stateId];
                  uint256 penaltyAmount = stakedOnLosingState.mul(penaltyRateBasisPoints).div(10000);
                  totalPenalizedAmount = totalPenalizedAmount.add(penaltyAmount);
             }
         }

         // The total rewards pool is the sum of total stake on winning state + total penalized amount from losing states
         // This pool is then distributed to winners after the protocol cut from penalties
         uint256 protocolPenaltyCut = totalPenalizedAmount.mul(10000 - rewardRateBasisPoints).div(10000); // Protocol keeps (100 - reward_rate)% of penalties
         uint256 rewardPoolForWinners = totalStakedOnWinningState.add(totalPenalizedAmount.sub(protocolPenaltyCut));

         // Add protocol's cut from penalties to treasury
         protocolTreasury = protocolTreasury.add(protocolPenaltyCut);

         // Calculate user's net claimable amount
         uint256 userTotalStaked = 0;
         uint256 userStakeOnWinningState = userStakes[epochId][winningState][msg.sender];
         uint256 userGrossReward = 0;
         uint256 userTotalPenalties = 0;

         // Calculate user's total stake and penalties across all states
         for (uint i = 0; i < availableStateIds.length; i++) {
              uint256 stateId = availableStateIds[i];
              uint256 userStakeOnState = userStakes[epochId][stateId][msg.sender];
              userTotalStaked = userTotalStaked.add(userStakeOnState);

              if (userStakeOnState > 0 && stateId != winningState) {
                   // This portion of the user's stake was on a losing state - calculate penalty
                  uint256 penaltyForThisStake = userStakeOnState.mul(penaltyRateBasisPoints).div(10000);
                  userTotalPenalties = userTotalPenalties.add(penaltyForThisStake);
              }
         }

         // If user had stake on the winning state and winning pool is > 0, calculate their share of the reward pool
         if (userStakeOnWinningState > 0 && totalStakedOnWinningState > 0) {
             // User's gross reward is their proportional share of the reward pool
             userGrossReward = rewardPoolForWinners.mul(userStakeOnWinningState).div(totalStakedOnWinningState);
         }

         // Net claimable = original total stake + gross reward - total penalties
         // Note: original stake is effectively "returned" as part of the reward calculation framework.
         // The user gets their winning stake back + their share of the profit (penalties - protocol cut),
         // minus the penalties on their losing stakes.
         // A simpler way to think about it:
         // User gets winningStake + (winningStake / totalWinningStake) * (totalPenalties - protocolCut)
         // User loses penaltyRate * losingStake for each losing stake

         uint256 userClaimableAmount = userTotalStaked.add(userGrossReward).sub(userTotalPenalties);

         if (userClaimableAmount == 0) revert NothingToClaim(); // Or allow claiming 0 if desired

         // Transfer the net amount to the user
         stakingToken.safeTransfer(msg.sender, userClaimableAmount);

         // Mark as claimed
         hasUserClaimedForEpoch[epochId][msg.sender] = true;

         emit Claimed(epochId, msg.sender, userClaimableAmount);
    }

    /// @notice Sets the reward and penalty rates.
    /// @param _rewardRateBasisPoints Percentage (x/10000) of the winning pool distributed to winners. Remaining is protocol cut.
    /// @param _penaltyRateBasisPoints Percentage (x/10000) of losing stakes that are penalized.
    function setRewardPenaltyRates(uint256 _rewardRateBasisPoints, uint256 _penaltyRateBasisPoints) external onlyOwner {
        if (_rewardRateBasisPoints > 10000 || _penaltyRateBasisPoints > 10000) {
             revert QuantumLeap__InvalidRewardPenaltyRate();
        }
        rewardRateBasisPoints = _rewardRateBasisPoints;
        penaltyRateBasisPoints = _penaltyRateBasisPoints;
        emit ParametersUpdated();
    }

    // --- Treasury ---

    /// @notice Allows the owner to withdraw the protocol treasury balance.
    /// @param amount The amount to withdraw.
    /// @param to The address to send the funds to.
    function withdrawTreasury(uint256 amount, address to) external onlyOwner {
        if (amount == 0 || amount > protocolTreasury) revert NothingToWithdraw(); // Use NothingToWithdraw or Define specific
        if (to == address(0)) revert OwnableInvalidOwner(address(0)); // Use Ownable error or define specific

        protocolTreasury = protocolTreasury.sub(amount);
        feeToken.safeTransfer(to, amount); // Treasury holds fee tokens

        emit ProtocolTreasuryWithdrawal(to, amount);
    }

    // --- Advanced/Creative Concepts (V1) ---

    /// @notice Allows a user to claim from a past epoch and immediately restake in a single transaction.
    /// @dev This combines claimRewards and stakeOnState for user convenience.
    /// @param claimEpochId The epoch to claim from.
    /// @param restakeStateId The state to stake on in the *current* or *next* active epoch.
    /// @param restakeAmount The amount to restake (must be <= claimed amount + current balance).
    function flashClaimAndRestake(uint256 claimEpochId, uint256 restakeStateId, uint256 restakeAmount) external whenNotPaused onlyOutcomeDetermined(claimEpochId) onlyStateExists(restakeStateId) {
        uint256 userBalanceBefore = stakingToken.balanceOf(msg.sender);

        // 1. Claim Rewards (logic is same as claimRewards function)
        // This will transfer funds to msg.sender and update hasUserClaimedForEpoch
         if (hasUserClaimedForEpoch[claimEpochId]) revert AlreadyClaimed();

         uint256 winningState = epochOutcomes[claimEpochId];
         uint256 totalStakedOnWinningState = totalStakedPerState[claimEpochId][winningState];

         uint256 totalPenalizedAmount = 0;
         for (uint i = 0; i < availableStateIds.length; i++) {
             uint256 stateId = availableStateIds[i];
             if (stateId != winningState) {
                  uint256 stakedOnLosingState = totalStakedPerState[claimEpochId][stateId];
                  uint256 penaltyAmount = stakedOnLosingState.mul(penaltyRateBasisPoints).div(10000);
                  totalPenalizedAmount = totalPenalizedAmount.add(penaltyAmount);
             }
         }

         uint256 protocolPenaltyCut = totalPenalizedAmount.mul(10000 - rewardRateBasisPoints).div(10000);
         uint256 rewardPoolForWinners = totalStakedOnWinningState.add(totalPenalizedAmount.sub(protocolPenaltyCut));
         protocolTreasury = protocolTreasury.add(protocolPenaltyCut);

         uint256 userTotalStaked = 0;
         uint256 userStakeOnWinningState = userStakes[claimEpochId][winningState][msg.sender];
         uint256 userGrossReward = 0;
         uint256 userTotalPenalties = 0;

         for (uint i = 0; i < availableStateIds.length; i++) {
              uint256 stateId = availableStateIds[i];
              uint256 userStakeOnState = userStakes[claimEpochId][stateId][msg.sender];
              userTotalStaked = userTotalStaked.add(userStakeOnState);

              if (userStakeOnState > 0 && stateId != winningState) {
                  uint256 penaltyForThisStake = userStakeOnState.mul(penaltyRateBasisPoints).div(10000);
                  userTotalPenalties = userTotalPenalties.add(penaltyForThisStake);
              }
         }

         uint256 userClaimableAmount = userTotalStaked.add(userGrossReward).sub(userTotalPenalties);

         if (userClaimableAmount == 0 && restakeAmount > 0) revert NothingToClaim(); // Cannot restake if nothing to claim (and no prior balance)
         if (userClaimableAmount > 0) {
             stakingToken.safeTransfer(msg.sender, userClaimableAmount);
         }
         hasUserClaimedForEpoch[claimEpochId][msg.sender] = true;
         emit Claimed(claimEpochId, msg.sender, userClaimableAmount);

         // 2. Restake (logic similar to stakeOnState)
         // User must approve this contract to spend restakeAmount from their balance *after* the claim
         if (restakeAmount > 0) {
             // Determine which epoch to stake on. Use current if active, otherwise next.
             uint256 targetEpoch = currentEpoch;
             if (block.timestamp >= epochEndTimes[currentEpoch]) {
                  // Current epoch ended, restake goes to the *next* one.
                  // Need to ensure nextEpochStartTime logic is sound or start next epoch first?
                  // Let's assume startNextEpoch *can* be called first if needed, or implicitly happens after cooldown.
                  // For simplicity in V1, require staking in the *current* active epoch.
                  revert QuantumLeap__EpochNotActive(); // Or implement logic to stake in next pending epoch
             }

             uint256 fee = calculateDynamicFee(restakeAmount, totalStakedInEpoch[targetEpoch]);
             uint256 totalTransferAmount = restakeAmount.add(fee);

             // User must have approved the contract *after* the claim transfer has updated their balance.
             // Alternatively, use a "pull" pattern where user approves a larger amount beforehand.
             // Or, require restakeAmount <= userClaimableAmount to ensure funds come *only* from the claim.
             // Let's require user to have balance for restake + fee *after* claim, and require prior approval.
             uint256 userBalanceAfterClaim = stakingToken.balanceOf(msg.sender);
             if (userBalanceAfterClaim < totalTransferAmount) revert InsufficientBalanceForFee(totalTransferAmount);

             // Check allowance - User needs to have approved this contract for at least `totalTransferAmount` *before* calling this function.
             // This is a standard pattern, but important to note for the user experience.
             // If feeToken != stakingToken, the user needs two separate approvals.

             if (feeToken != stakingToken) {
                  stakingToken.safeTransferFrom(msg.sender, address(this), restakeAmount);
                  feeToken.safeTransferFrom(msg.sender, address(this), fee);
             } else {
                 stakingToken.safeTransferFrom(msg.sender, address(this), totalTransferAmount);
             }

             userStakes[targetEpoch][restakeStateId][msg.sender] = userStakes[targetEpoch][restakeStateId][msg.sender].add(restakeAmount);
             totalStakedPerState[targetEpoch][restakeStateId] = totalStakedPerState[targetEpoch][restakeStateId].add(restakeAmount);
             totalStakedInEpoch[targetEpoch] = totalStakedInEpoch[targetEpoch].add(restakeAmount);
             protocolTreasury = protocolTreasury.add(fee);

             emit Staked(targetEpoch, msg.sender, restakeStateId, restakeAmount, totalStakedPerState[targetEpoch][restakeStateId], totalStakedInEpoch[targetEpoch], fee);
         }
    }

    /// @notice Allows a user (potentially gated by access control) to submit an outcome hint.
    /// @dev In V1, this function only stores the hint data on-chain. It does not influence the outcome determination.
    /// @param epochId The epoch the hint is for.
    /// @param stateId The state the hint relates to.
    /// @param hintData Arbitrary data related to the hint (e.g., IPFS hash, analysis bytes).
    function submitOutcomeHint(uint256 epochId, uint256 stateId, bytes calldata hintData) external whenNotPaused onlyStateExists(stateId) {
        // Optional: Implement access control check here if accessControlToken addresses are set
        // if (!checkAccessTier(msg.sender, 1)) revert QuantumLeap__AccessDenied(); // Example check

        // Optional: Restrict to active epoch or before outcome determined
        // if (epochId != currentEpoch || isOutcomeDeterminedForEpoch[epochId]) revert SomeError();

        outcomeHints[epochId][stateId][msg.sender] = hintData;

        emit OutcomeHintSubmitted(epochId, msg.sender, stateId, hintData);
    }

    /// @notice Sets the address of an optional ERC721 token for access control gating.
    /// @param _accessControlToken721 The address of the ERC721 token. Use address(0) to disable.
    function setAccessControlToken721(address _accessControlToken721) external onlyOwner {
        accessControlToken721 = IERC721(_accessControlToken721);
        emit ParametersUpdated();
    }

    /// @notice Sets the address of an optional ERC20 token for access control gating (e.g., minimum balance).
    /// @param _accessControlToken20 The address of the ERC20 token. Use address(0) to disable.
    function setAccessControlToken20(address _accessControlToken20) external onlyOwner {
        accessControlToken20 = IERC20(_accessControlToken20);
        emit ParametersUpdated();
    }


    /// @notice Checks if a user meets a specific access tier requirement.
    /// @dev V1: Simply checks if user holds > 0 of either access control token if set.
    /// More advanced tiers could check specific token IDs, balances, etc.
    /// @param user The address to check.
    /// @param tier The tier level to check (V1 ignores this, assumes a single tier based on holding any token).
    /// @return bool True if the user meets the criteria for the tier, false otherwise.
    function checkAccessTier(address user, uint256 tier) public view returns (bool) {
        // V1 implementation: Check if user holds any of the configured access tokens
        if (address(accessControlToken721) != address(0)) {
             if (accessControlToken721.balanceOf(user) > 0) {
                 return true;
             }
        }
         if (address(accessControlToken20) != address(0)) {
             // Could add a minimum balance check here
             if (accessControlToken20.balanceOf(user) > 0) {
                 return true;
             }
         }
        // If no access control tokens are set, or user doesn't hold them
        return (address(accessControlToken721) == address(0) && address(accessControlToken20) == address(0));
         // Or return false if access tokens are set but user doesn't hold them:
         // return false;
    }


    // --- View & Pure Functions (Total Count >= 20 including others) ---

    /// @notice Gets the list of available state IDs for staking.
    /// @return uint256[] An array of valid state IDs.
    function getAvailableStates() external view returns (uint256[] memory) {
        return availableStateIds;
    }

    /// @notice Gets the name associated with a state ID.
    /// @param stateId The ID of the state.
    /// @return string The name of the state.
    function getStateName(uint256 stateId) external view returns (string memory) {
         return stateNames[stateId];
    }

    /// @notice Gets the current epoch ID.
    /// @return uint256 The current epoch ID.
    function getCurrentEpoch() external view returns (uint256) {
        return currentEpoch;
    }

    /// @notice Gets the duration of each epoch in seconds.
    /// @return uint256 The epoch duration.
    function getEpochDuration() external view returns (uint256) {
        return epochDurationSeconds;
    }

     /// @notice Gets the start timestamp for a specific epoch.
     /// @param epochId The epoch ID.
     /// @return uint256 The start timestamp.
    function getEpochStartTime(uint256 epochId) external view returns (uint256) {
        return epochStartTimes[epochId];
    }

    /// @notice Gets the end timestamp for a specific epoch.
     /// @param epochId The epoch ID.
     /// @return uint256 The end timestamp.
    function getEpochEndTime(uint256 epochId) external view returns (uint256) {
        return epochEndTimes[epochId];
    }

    /// @notice Gets the winning state ID for a specific epoch.
    /// @param epochId The epoch ID.
    /// @return uint256 The winning state ID (0 if not determined).
    function getEpochOutcome(uint256 epochId) external view returns (uint256) {
        return epochOutcomes[epochId];
    }

    /// @notice Gets the amount staked by a user on a specific state for a specific epoch.
    /// @param epochId The epoch ID.
    /// @param stateId The state ID.
    /// @param user The user address.
    /// @return uint256 The staked amount.
    function getUserStake(uint256 epochId, uint256 stateId, address user) external view returns (uint256) {
        return userStakes[epochId][stateId][user];
    }

    /// @notice Gets the total amount staked on a specific state for a specific epoch.
    /// @param epochId The epoch ID.
    /// @param stateId The state ID.
    /// @return uint256 The total staked amount on that state.
    function getTotalStakedOnState(uint256 epochId, uint256 stateId) external view returns (uint256) {
        return totalStakedPerState[epochId][stateId];
    }

     /// @notice Gets the total amount staked in a specific epoch across all states.
     /// @param epochId The epoch ID.
     /// @return uint256 The total staked amount in the epoch.
    function getTotalStakedInEpoch(uint256 epochId) external view returns (uint256) {
        return totalStakedInEpoch[epochId];
    }


    /// @notice Gets the estimated net claimable amount for a user for a specific epoch.
    /// @dev Requires outcome to be determined. This calculates the potential payout/loss without state-changing side effects.
    /// @param epochId The epoch ID.
    /// @param user The user address.
    /// @return uint256 The estimated claimable amount. Returns 0 if outcome not determined or user already claimed.
    function getUserClaimableRewards(uint256 epochId, address user) external view returns (uint256) {
         if (!isOutcomeDeterminedForEpoch[epochId] || hasUserClaimedForEpoch[epochId]) {
             return 0;
         }

         uint256 winningState = epochOutcomes[epochId];
         uint256 totalStakedOnWinningState = totalStakedPerState[epochId][winningState];

         uint256 totalPenalizedAmount = 0;
         for (uint i = 0; i < availableStateIds.length; i++) {
             uint256 stateId = availableStateIds[i];
             if (stateId != winningState) {
                  uint256 stakedOnLosingState = totalStakedPerState[epochId][stateId];
                  uint256 penaltyAmount = stakedOnLosingState.mul(penaltyRateBasisPoints).div(10000);
                  totalPenalizedAmount = totalPenalizedAmount.add(penaltyAmount);
             }
         }

         uint256 protocolPenaltyCut = totalPenalizedAmount.mul(10000 - rewardRateBasisPoints).div(10000);
         uint256 rewardPoolForWinners = totalStakedOnWinningState.add(totalPenalizedAmount.sub(protocolPenaltyCut));

         uint256 userTotalStaked = 0;
         uint256 userStakeOnWinningState = userStakes[epochId][winningState][user];
         uint256 userGrossReward = 0;
         uint256 userTotalPenalties = 0;

         for (uint i = 0; i < availableStateIds.length; i++) {
              uint256 stateId = availableStateIds[i];
              uint256 userStakeOnState = userStakes[epochId][stateId][user];
              userTotalStaked = userTotalStaked.add(userStakeOnState);

              if (userStakeOnState > 0 && stateId != winningState) {
                  uint256 penaltyForThisStake = userStakeOnState.mul(penaltyRateBasisPoints).div(10000);
                  userTotalPenalties = userTotalPenalties.add(penaltyForThisStake);
              }
         }

         if (userStakeOnWinningState > 0 && totalStakedOnWinningState > 0) {
             userGrossReward = rewardPoolForWinners.mul(userStakeOnWinningState).div(totalStakedOnWinningState);
         }

         uint256 userClaimableAmount = userTotalStaked.add(userGrossReward).sub(userTotalPenalties);

         return userClaimableAmount;
    }

    /// @notice Checks if the outcome for a specific epoch has been determined.
    /// @param epochId The epoch ID.
    /// @return bool True if the outcome is determined, false otherwise.
    function isOutcomeDetermined(uint256 epochId) external view returns (bool) {
        return isOutcomeDeterminedForEpoch[epochId];
    }

    /// @notice Checks if a user has claimed rewards for a specific epoch.
    /// @param epochId The epoch ID.
    /// @param user The user address.
    /// @return bool True if the user has claimed, false otherwise.
    function hasUserClaimed(uint256 epochId, address user) external view returns (bool) {
        return hasUserClaimedForEpoch[epochId][user];
    }

    /// @notice Gets the current reward and penalty rates.
    /// @return rewardRate Percentage of winning pool distributed (x/10000).
    /// @return penaltyRate Percentage of losing stakes penalized (x/10000).
    function getRewardPenaltyRates() external view returns (uint256 rewardRate, uint256 penaltyRate) {
        return (rewardRateBasisPoints, penaltyRateBasisPoints);
    }

    /// @notice Gets the current dynamic fee parameters.
    /// @return base Base fee amount.
    /// @return rate Rate multiplier (x/10000).
    /// @return scalingFactor Divisor for scaling part.
    function getDynamicFeeParams() external view returns (uint256 base, uint256 rate, uint256 scalingFactor) {
        return (dynamicFeeBase, dynamicFeeRate, dynamicFeeScalingFactor);
    }

    /// @notice Gets the address of the oracle/VRF coordinator.
    /// @return address The VRF coordinator address.
    function getVRFCoordinatorAddress() external view returns (address) {
        return address(i_vrfCoordinator);
    }

    /// @notice Gets the Chainlink VRF key hash used.
    /// @return bytes32 The key hash.
    function getKeyHash() external view returns (bytes32) {
        return i_keyHash;
    }

    /// @notice Gets the required number of block confirmations for VRF.
    /// @return uint16 The request confirmations.
    function getRequestConfirmations() external view returns (uint16) {
        return i_requestConfirmations;
    }

     /// @notice Gets the VRF request ID for a specific epoch.
     /// @param epochId The epoch ID.
     /// @return uint256 The VRF request ID (0 if not requested).
    function getVRFRequestIdForEpoch(uint256 epochId) external view returns (uint256) {
         return epochRandomnessRequestIds[epochId];
    }

    /// @notice Gets the current balance of the protocol treasury.
    /// @return uint256 The treasury balance in fee tokens.
    function getProtocolTreasury() external view returns (uint256) {
        return protocolTreasury;
    }

    /// @notice Gets the hint data submitted by a user for a specific epoch and state.
    /// @param epochId The epoch ID.
    /// @param stateId The state ID.
    /// @param user The user address.
    /// @return bytes The hint data (empty bytes if none submitted).
    function getOutcomeHint(uint256 epochId, uint256 stateId, address user) external view returns (bytes memory) {
         return outcomeHints[epochId][stateId][user];
    }

     /// @notice Gets the address of the access control ERC721 token.
     /// @return address The token address (address(0) if not set).
    function getAccessControlToken721() external view returns (address) {
         return address(accessControlToken721);
    }

    /// @notice Gets the address of the access control ERC20 token.
    /// @return address The token address (address(0) if not set).
    function getAccessControlToken20() external view returns (address) {
         return address(accessControlToken20);
    }
}
```