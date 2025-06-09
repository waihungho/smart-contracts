Okay, here is a smart contract called `QuantumVault`. It incorporates concepts inspired by quantum mechanics (like superposition of states, observation collapsing states, and entanglement through shared random fate) combined with DeFi elements (vault, staking rewards) and a simple governance structure. It uses a simulated Verifiable Random Function (VRF) or Verifiable Delay Function (VDF) oracle interface for the "observation" mechanism.

It aims for creativity by having deposits exist in a "superposition" of multiple potential lock-up states until an unpredictable "observation" event collapses them into a single active state, affecting withdrawal timelines and reward rates (entanglement).

---

**QuantumVault Smart Contract Outline & Function Summary**

**Contract Name:** `QuantumVault`

**Concept:** A token vault where deposits are made into a set of potential lock-up states ("superposition"). A shared, unpredictable "observation" event (simulated by a random number from an oracle) resolves this superposition for all deposits made within an epoch, determining the *actual* active lock-up state and influencing staking rewards.

**Core Components:**

1.  **QuantumStates:** Predefined options for deposit conditions (primarily time-based locks, but extensible).
2.  **Deposits:** User deposits linked to an epoch and a *set* of potential QuantumStates.
3.  **Epochs:** Time periods during which deposits are grouped.
4.  **Observation:** An event at the end of an epoch, providing a random number that deterministically selects *one* active state from the potential set for every deposit in that epoch.
5.  **Rewards:** Accrue based on the *active* state of a deposit. Longer/more restrictive states earn more.
6.  **Withdrawal:** Only possible after the deposit's epoch is observed and the conditions of the *active* state are met.
7.  **Governance:** Basic control over parameters and state options.

**Function Summary:**

*   **Vault & Deposit Management:**
    *   `deposit`: Users deposit tokens, selecting multiple potential lock-up states.
    *   `requestWithdrawal`: Users initiate withdrawal for a deposit after observation.
    *   `finalizeWithdrawal`: Users complete withdrawal after active state conditions are met.
    *   `emergencyWithdraw`: Governance function for emergency token recovery.
*   **QuantumState Management:**
    *   `addQuantumStateOption`: Governance adds a new possible QuantumState definition.
    *   `removeQuantumStateOption`: Governance removes a QuantumState definition.
    *   `updateQuantumStateOption`: Governance modifies an existing QuantumState definition.
*   **Epoch & Observation (The Core Quantum Logic):**
    *   `requestObservation`: Anyone can trigger the request for a new random observation for the *previous* epoch (if due).
    *   `fulfillObservation`: Called by a designated oracle/VRF coordinator to provide the random number and trigger state resolution for the pending epoch.
    *   `resolveEpochDeposits`: Internal helper function called by `fulfillObservation` to iterate through deposits and determine their active state based on the random number.
*   **Rewards Management:**
    *   `updateRewardRate`: Governance sets the base reward rate per token.
    *   `claimRewards`: Users claim accumulated rewards.
    *   `updateStateRewardMultiplier`: Governance sets multipliers for each QuantumState influencing reward rates.
*   **Governance & Parameters:**
    *   `setGovernanceContract`: Sets the address authorized for governance actions.
    *   `updateObservationEpochDuration`: Sets the duration of each deposit epoch.
    *   `updateMinimumObservationDelay`: Sets min delay after epoch end before observation request is valid.
    *   `pause`: Pauses key contract operations.
    *   `unpause`: Unpauses the contract.
*   **Querying & View Functions:**
    *   `getQuantumStateOption`: Retrieve details of a specific QuantumState option.
    *   `listAvailableStateOptions`: List all available QuantumState option IDs.
    *   `getCurrentEpoch`: Get the current deposit epoch number.
    *   `getEpochObservation`: Get the random number observed for a past epoch.
    *   `getUserDepositIds`: Get list of deposit IDs for a user.
    *   `getUserDepositDetails`: Get full details of a user's specific deposit.
    *   `getActiveStateForDeposit`: Get the *resolved* active state ID for a deposit after observation.
    *   `canFinalizeWithdrawal`: Check if the conditions for a deposit's active state are met.
    *   `getUserClaimableRewards`: Calculate the currently claimable rewards for a user.
    *   `getVaultTotalTokenBalance`: Get the total balance of a specific token held by the vault.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- Outline & Function Summary ---
//
// Contract Name: QuantumVault
// Concept: A token vault where deposits are made into a set of potential lock-up states ("superposition").
// An unpredictable "observation" event (simulated VRF/VDF oracle) resolves this for all deposits in an epoch,
// determining the actual active lock-up state and influencing staking rewards ("entanglement").
//
// Core Components:
// 1. QuantumStates: Predefined deposit conditions (time-based locks).
// 2. Deposits: User deposits linked to an epoch and a *set* of potential states.
// 3. Epochs: Time periods grouping deposits for observation.
// 4. Observation: Random event at epoch end resolving deposit states.
// 5. Rewards: Accrue based on the *active* state multiplier.
// 6. Withdrawal: Only possible after observation and active state conditions met.
// 7. Governance: Basic control over parameters and state options.
//
// Function Summary:
// - Vault & Deposit Management:
//   - deposit: Deposit tokens with potential state choices.
//   - requestWithdrawal: Initiate withdrawal after observation.
//   - finalizeWithdrawal: Complete withdrawal when active state conditions met.
//   - emergencyWithdraw: Governance recovery.
// - QuantumState Management:
//   - addQuantumStateOption: Add a new state definition (Governance).
//   - removeQuantumStateOption: Remove a state definition (Governance).
//   - updateQuantumStateOption: Modify a state definition (Governance).
// - Epoch & Observation (Quantum Logic):
//   - requestObservation: Trigger observation request (Anyone).
//   - fulfillObservation: Provide random number & resolve epoch (Oracle/Trusted Caller).
//   - resolveEpochDeposits: Internal helper to determine active states.
// - Rewards Management:
//   - updateRewardRate: Set base reward rate per token (Governance).
//   - claimRewards: Users claim accumulated rewards.
//   - updateStateRewardMultiplier: Set multiplier for a state (Governance).
// - Governance & Parameters:
//   - setGovernanceContract: Set governance address (Owner).
//   - updateObservationEpochDuration: Set epoch length (Governance).
//   - updateMinimumObservationDelay: Set min delay after epoch end before observation (Governance).
//   - pause: Pause critical ops (Owner/Governance).
//   - unpause: Unpause ops (Owner/Governance).
// - Querying & View Functions:
//   - getQuantumStateOption: Get state details.
//   - listAvailableStateOptions: List state IDs.
//   - getCurrentEpoch: Get current epoch number.
//   - getEpochObservation: Get observation for an epoch.
//   - getUserDepositIds: Get user's deposit IDs.
//   - getUserDepositDetails: Get details for a deposit ID.
//   - getActiveStateForDeposit: Get resolved state ID for a deposit.
//   - canFinalizeWithdrawal: Check if withdrawal conditions met.
//   - getUserClaimableRewards: Calculate claimable rewards.
//   - getVaultTotalTokenBalance: Get vault balance of a token.
//
// --- End Outline & Summary ---

contract QuantumVault is Ownable, Pausable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // --- Events ---

    event DepositMade(
        address indexed user,
        uint256 indexed depositId,
        address indexed token,
        uint256 amount,
        uint32[] potentialStateIds,
        uint256 epoch
    );

    event ObservationRequested(uint256 indexed epoch, uint256 requestBlock);
    event ObservationFulfilled(uint256 indexed epoch, uint256 randomNumber);
    event StatesResolved(uint256 indexed epoch, uint256 resolvedDepositCount);

    event WithdrawalRequested(uint256 indexed depositId, address indexed user);
    event WithdrawalFinalized(uint256 indexed depositId, address indexed user, uint256 amount);
    event EmergencyWithdrawal(address indexed token, uint256 amount);

    event RewardsClaimed(address indexed user, address indexed token, uint256 amount);

    event QuantumStateAdded(uint32 indexed stateId, uint256 lockDuration);
    event QuantumStateRemoved(uint32 indexed stateId);
    event QuantumStateUpdated(uint32 indexed stateId, uint256 newLockDuration);

    event RewardRateUpdated(address indexed token, uint256 newRate);
    event StateRewardMultiplierUpdated(uint32 indexed stateId, uint256 newMultiplier);

    event GovernanceContractUpdated(address indexed newGovernance);
    event EpochDurationUpdated(uint256 newDuration);
    event MinimumObservationDelayUpdated(uint256 newDelay);

    // --- Structs ---

    struct QuantumState {
        uint32 id;
        uint256 lockDuration; // in seconds (e.g., 30 days, 90 days)
        uint256 rewardMultiplier; // e.g., 10000 for 1x, 15000 for 1.5x base reward
        bool isActive; // Can this state option be chosen for new deposits?
    }

    struct Deposit {
        address user;
        address token;
        uint256 amount;
        uint256 depositTime;
        uint256 epoch;
        uint32[] potentialStateIds; // State options chosen by user
        uint32 activeStateId; // State resolved after observation (0 if not resolved)
        uint256 resolvedTime; // Timestamp when state was resolved
        bool withdrawalRequested;
        bool withdrawn;
    }

    // --- State Variables ---

    Counters.Counter private _depositIds;
    Counters.Counter private _quantumStateIds;

    mapping(uint256 => Deposit) public deposits;
    mapping(address => uint256[]) private userDepositIds; // user => list of deposit ids

    mapping(uint32 => QuantumState) public quantumStates;
    uint32[] public availableQuantumStateIds; // List of IDs that are 'isActive'

    // Epoch management
    uint256 public currentEpoch;
    uint256 public epochStartTime;
    uint256 public epochDuration = 7 days; // Default epoch duration
    uint256 public minimumObservationDelay = 1 days; // Min time after epoch ends before observation is valid

    mapping(uint256 => uint256) public epochObservations; // epoch => random number (0 if not observed)
    mapping(uint256 => uint256) public epochObservationRequestTime; // epoch => timestamp observation was requested

    // Track deposits per epoch to resolve them efficiently
    mapping(uint256 => uint256[]) private epochDepositIds;

    // Rewards
    mapping(address => uint256) public tokenRewardRatePerSecond; // token => base reward per token per second
    mapping(address => mapping(uint256 => uint256)) public lastRewardClaimTime; // user => depositId => timestamp
    mapping(address => mapping(address => uint256)) public accumulatedRewards; // user => token => amount (unclaimed)

    address public governanceContract; // Separate address/contract for governance actions
    address public oracleAddress; // Address expected to call fulfillObservation (e.g., Chainlink VRF Coordinator)

    // --- Constructor ---

    constructor(address _oracleAddress) Ownable(msg.sender) {
        epochStartTime = block.timestamp;
        currentEpoch = 1;
        oracleAddress = _oracleAddress;
    }

    // --- Modifiers ---

    modifier onlyGovernance() {
        require(msg.sender == governanceContract || msg.sender == owner(), "Not authorized for governance actions");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Only oracle can fulfill observation");
        _;
    }

    modifier depositExists(uint256 _depositId) {
        require(deposits[_depositId].user != address(0), "Deposit does not exist");
        _;
    }

    modifier isEpochObserved(uint256 _epoch) {
        require(epochObservations[_epoch] != 0, "Epoch has not been observed yet");
        _;
    }

    // --- Core Vault & Deposit Functions ---

    /**
     * @notice Deposits tokens into the vault, associating the deposit with multiple potential QuantumStates.
     * @param _token The address of the ERC20 token to deposit.
     * @param _amount The amount of tokens to deposit.
     * @param _potentialStateIds The IDs of the QuantumStates that this deposit could potentially resolve into.
     * @dev The actual state is determined after the epoch's observation event.
     * @dev Requires _potentialStateIds to not be empty and all IDs to be valid and active options.
     */
    function deposit(address _token, uint256 _amount, uint32[] memory _potentialStateIds) public payable whenNotPaused {
        require(_amount > 0, "Deposit amount must be greater than 0");
        require(_token != address(0), "Invalid token address");
        require(_potentialStateIds.length > 0, "Must select at least one potential state");

        // Validate potential state IDs
        for (uint i = 0; i < _potentialStateIds.length; i++) {
            require(quantumStates[_potentialStateIds[i]].isActive, "Invalid or inactive potential state ID");
        }

        IERC20 token = IERC20(_token);
        token.safeTransferFrom(msg.sender, address(this), _amount);

        _depositIds.increment();
        uint256 newDepositId = _depositIds.current();

        deposits[newDepositId] = Deposit({
            user: msg.sender,
            token: _token,
            amount: _amount,
            depositTime: block.timestamp,
            epoch: currentEpoch,
            potentialStateIds: _potentialStateIds,
            activeStateId: 0, // Not resolved yet
            resolvedTime: 0,
            withdrawalRequested: false,
            withdrawn: false
        });

        userDepositIds[msg.sender].push(newDepositId);
        epochDepositIds[currentEpoch].push(newDepositId);

        emit DepositMade(msg.sender, newDepositId, _token, _amount, _potentialStateIds, currentEpoch);
    }

    /**
     * @notice Requests withdrawal for a specific deposit.
     * @param _depositId The ID of the deposit to withdraw.
     * @dev Can only be requested after the deposit's epoch has been observed and the active state determined.
     * @dev Does *not* finalize the withdrawal, just marks it for withdrawal. Finalization happens when conditions are met.
     */
    function requestWithdrawal(uint256 _depositId) public whenNotPaused depositExists(_depositId) isEpochObserved(deposits[_depositId].epoch) {
        Deposit storage depositInfo = deposits[_depositId];
        require(depositInfo.user == msg.sender, "Not your deposit");
        require(!depositInfo.withdrawalRequested, "Withdrawal already requested");
        require(!depositInfo.withdrawn, "Deposit already withdrawn");

        depositInfo.withdrawalRequested = true;

        // Calculate and accrue any pending rewards up to this point
        _accrueRewards(msg.sender, _depositId);

        emit WithdrawalRequested(_depositId, msg.sender);
    }

    /**
     * @notice Finalizes a withdrawal request for a specific deposit.
     * @param _depositId The ID of the deposit to finalize withdrawal for.
     * @dev Can only be called after `requestWithdrawal` and when the conditions
     *      of the deposit's active state (e.g., lock duration) are met.
     */
    function finalizeWithdrawal(uint256 _depositId) public whenNotPaused depositExists(_depositId) {
        Deposit storage depositInfo = deposits[_depositId];
        require(depositInfo.user == msg.sender, "Not your deposit");
        require(depositInfo.withdrawalRequested, "Withdrawal not requested");
        require(!depositInfo.withdrawn, "Deposit already withdrawn");
        require(canFinalizeWithdrawal(_depositId), "Withdrawal conditions not met yet");

        uint256 amountToWithdraw = depositInfo.amount;
        address tokenAddress = depositInfo.token;

        // Accrue final rewards up to finalization time before sending tokens
        _accrueRewards(msg.sender, _depositId);

        depositInfo.withdrawn = true;

        IERC20 token = IERC20(tokenAddress);
        token.safeTransfer(msg.sender, amountToWithdraw);

        emit WithdrawalFinalized(_depositId, msg.sender, amountToWithdraw);
    }

    /**
     * @notice Allows governance to withdraw any token in an emergency.
     * @param _token The address of the token to withdraw.
     * @dev Use with extreme caution. Should have a clear off-chain policy for using this.
     */
    function emergencyWithdraw(address _token) public onlyGovernance {
        require(_token != address(0), "Invalid token address");
        IERC20 token = IERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No balance to withdraw");

        token.safeTransfer(governanceContract == address(0) ? owner() : governanceContract, balance); // Send to governance or owner if not set
        emit EmergencyWithdrawal(_token, balance);
    }

    // --- QuantumState Management Functions ---

    /**
     * @notice Adds a new potential QuantumState option that users can choose for deposits.
     * @param _lockDuration The lock-up period in seconds for this state.
     * @param _rewardMultiplier The multiplier for the base reward rate (e.g., 10000 for 1x).
     * @dev Only callable by governance.
     * @dev rewardMultiplier should be >= 10000 (representing 1x or more).
     */
    function addQuantumStateOption(uint256 _lockDuration, uint256 _rewardMultiplier) public onlyGovernance {
        require(_rewardMultiplier >= 10000, "Reward multiplier must be >= 10000 (1x)");

        _quantumStateIds.increment();
        uint32 newStateId = uint32(_quantumStateIds.current()); // Assuming state IDs won't exceed uint32 max

        quantumStates[newStateId] = QuantumState({
            id: newStateId,
            lockDuration: _lockDuration,
            rewardMultiplier: _rewardMultiplier,
            isActive: true
        });

        availableQuantumStateIds.push(newStateId);

        emit QuantumStateAdded(newStateId, _lockDuration);
    }

    /**
     * @notice Removes a QuantumState option, preventing new deposits from choosing it.
     * @param _stateId The ID of the state to remove.
     * @dev Only callable by governance. Existing deposits with this state remain unaffected.
     */
    function removeQuantumStateOption(uint32 _stateId) public onlyGovernance {
        require(quantumStates[_stateId].id != 0, "State does not exist");
        require(quantumStates[_stateId].isActive, "State is already inactive");

        quantumStates[_stateId].isActive = false;

        // Remove from the available list
        uint256 indexToRemove = type(uint256).max;
        for(uint i = 0; i < availableQuantumStateIds.length; i++) {
            if (availableQuantumStateIds[i] == _stateId) {
                indexToRemove = i;
                break;
            }
        }

        // Simple remove by swapping with last and popping (order doesn't matter for available list)
        if (indexToRemove != type(uint256).max) {
            availableQuantumStateIds[indexToRemove] = availableQuantumStateIds[availableQuantumStateIds.length - 1];
            availableQuantumStateIds.pop();
        }

        emit QuantumStateRemoved(_stateId);
    }

     /**
     * @notice Updates parameters of an existing QuantumState option.
     * @param _stateId The ID of the state to update.
     * @param _newLockDuration The new lock-up period in seconds.
     * @param _newRewardMultiplier The new multiplier for the base reward rate.
     * @dev Only callable by governance. Updates apply to new deposits choosing this state
     *      and potentially influence reward calculations for existing deposits depending
     *      on the implementation logic (here, rewards use the multiplier at time of accrual).
     */
    function updateQuantumStateOption(uint32 _stateId, uint256 _newLockDuration, uint256 _newRewardMultiplier) public onlyGovernance {
        require(quantumStates[_stateId].id != 0, "State does not exist");
        require(quantumStates[_stateId].isActive, "State is not active");
        require(_newRewardMultiplier >= 10000, "New reward multiplier must be >= 10000 (1x)");

        quantumStates[_stateId].lockDuration = _newLockDuration;
        quantumStates[_stateId].rewardMultiplier = _newRewardMultiplier;

        emit QuantumStateUpdated(_stateId, _newLockDuration);
    }


    // --- Epoch & Observation Functions (Quantum Logic) ---

    /**
     * @notice Requests an observation for the current epoch if it has ended.
     * @dev Can be called by anyone. This initiates the process for the oracle to provide the random number.
     * @dev Moves the contract to the next epoch if the current one is ready for observation.
     */
    function requestObservation() public whenNotPaused {
        uint256 epochToObserve = currentEpoch;
        if (block.timestamp < epochStartTime + epochDuration + minimumObservationDelay) {
             // Check if the *previous* epoch needs observation
             epochToObserve = currentEpoch - 1;
             require(epochToObserve > 0, "Current epoch not ended, and no previous epoch to observe");
        }

        require(epochObservations[epochToObserve] == 0, "Epoch already observed");
        require(epochObservationRequestTime[epochToObserve] == 0, "Observation already requested for this epoch");

        // Ensure the epoch has actually ended + minimum delay passed
        uint256 epochActualEndTime = epochStartTime + epochDuration;
        if (epochToObserve == currentEpoch) { // If requesting for the current epoch (meaning we are moving to the next one)
             require(block.timestamp >= epochActualEndTime + minimumObservationDelay, "Epoch has not ended yet or minimum delay not passed");
             epochStartTime = block.timestamp; // Start the new epoch
             currentEpoch++;
        } else { // Requesting for a previous epoch that somehow wasn't observed yet
             // Need to find the start time of epochToObserve. Requires tracking epoch start times
             // For simplicity here, we assume epochs are processed sequentially and epochStartTime updates sequentially.
             // A robust implementation might need a mapping `epoch => startTime`.
             // Assuming sequential processing: epochToObserve's end time would be approx
             // epochStartTime_at_EpochToObserve_creation + epochDuration.
             // Let's simplify and just rely on the `epochObservations` check.
             // If epochObservations[epochToObserve] is 0, and it's not the current one we just advanced past, it's a past epoch.
             // We still require the *current* time to be past the *previous* epoch's end time + delay.
             // This part needs careful logic in a real system with non-sequential observation.
             // Let's stick to the simple sequential flow: you request for the *just finished* epoch.
             epochToObserve = currentEpoch -1; // Re-calculate assuming sequential check
             require(epochToObserve > 0, "Cannot request observation for epoch 0");
             require(block.timestamp >= epochStartTime + epochDuration + minimumObservationDelay, "Current epoch not ended or minimum delay not passed for previous epoch");
             // currentEpoch and epochStartTime already advanced in the check above if needed.
        }


        epochObservationRequestTime[epochToObserve] = block.timestamp;

        // In a real VRF/VDF integration, you would now call the oracle contract
        // with `_epoch` and perhaps `msg.sender` to get the random number
        // callback later via fulfillObservation.
        // For this example, we just emit an event.

        emit ObservationRequested(epochToObserve, block.timestamp);
    }

    /**
     * @notice Called by the designated oracle/VRF coordinator to provide the random number for an epoch.
     * @param _epoch The epoch number for which the observation was requested.
     * @param _randomNumber The random number provided by the oracle.
     * @dev Only callable by the configured oracle address.
     * @dev Resolves the states for all deposits in the given epoch using the random number.
     */
    function fulfillObservation(uint256 _epoch, uint256 _randomNumber) public onlyOracle {
        require(epochObservations[_epoch] == 0, "Epoch already observed");
        require(epochObservationRequestTime[_epoch] != 0, "Observation not requested for this epoch");
        // Optionally add a check that the fulfill happens within a reasonable time after request

        epochObservations[_epoch] = _randomNumber;
        emit ObservationFulfilled(_epoch, _randomNumber);

        // Resolve states for all deposits made in this epoch
        resolveEpochDeposits(_epoch, _randomNumber);
    }

    /**
     * @notice Resolves the active QuantumState for all deposits in a given epoch.
     * @param _epoch The epoch whose deposits need resolution.
     * @param _randomNumber The random number for this epoch's observation.
     * @dev Internal function called by `fulfillObservation`.
     * @dev Selects one state deterministically from the potential states using the random number.
     */
    function resolveEpochDeposits(uint256 _epoch, uint256 _randomNumber) internal {
        uint256[] storage depositIdsToResolve = epochDepositIds[_epoch];
        uint256 resolvedCount = 0;

        for (uint i = 0; i < depositIdsToResolve.length; i++) {
            uint256 depositId = depositIdsToResolve[i];
            Deposit storage depositInfo = deposits[depositId];

            // Should not happen if called correctly after deposit logic, but safety check
            if (depositInfo.epoch != _epoch) continue;
            if (depositInfo.activeStateId != 0) continue; // Already resolved

            uint32[] memory potentialIds = depositInfo.potentialStateIds;
            if (potentialIds.length == 0) {
                 // Should not happen due to deposit validation, but handle defensively
                 // Maybe resolve to a default state or mark as error
                 continue;
            }

            // Deterministically select one state ID based on the random number
            // Simple modulo selection. A more complex scheme could weight states etc.
            uint256 selectionIndex = _randomNumber % potentialIds.length;
            uint32 selectedStateId = potentialIds[selectionIndex];

            // Ensure the selected state still exists, fallback to a default if needed (optional)
            if (quantumStates[selectedStateId].id == 0 || !quantumStates[selectedStateId].isActive) {
                 // Handle case where selected state was removed/invalidated after deposit but before observation.
                 // Could pick a default, or the first valid one from the list.
                 // For simplicity, let's require all potential states to *remain* valid until observation.
                 // Or, find the first *active* state in the list. Let's implement finding first active.
                 bool foundActive = false;
                 for(uint j = 0; j < potentialIds.length; j++) {
                      if (quantumStates[potentialIds[j]].isActive) {
                          selectedStateId = potentialIds[j];
                          foundActive = true;
                          break;
                      }
                 }
                 require(foundActive, "No active potential state found for deposit after observation");
            }


            depositInfo.activeStateId = selectedStateId;
            depositInfo.resolvedTime = block.timestamp;
            resolvedCount++;

            // At resolution time, we could initialize reward tracking based on the resolved state
             lastRewardClaimTime[depositInfo.user][depositId] = block.timestamp;

            // Note: epochDepositIds[_epoch] can potentially be cleared here to save gas on reads later,
            // but keeping it allows iterating through deposits of an epoch.

        }

        emit StatesResolved(_epoch, resolvedCount);
    }

    // --- Rewards Functions ---

    /**
     * @notice Updates the base reward rate per second for a specific token.
     * @param _token The token address.
     * @param _newRate The new base reward rate (per token per second).
     * @dev Only callable by governance.
     */
    function updateRewardRate(address _token, uint256 _newRate) public onlyGovernance {
        require(_token != address(0), "Invalid token address");
        tokenRewardRatePerSecond[_token] = _newRate;
        emit RewardRateUpdated(_token, _newRate);
    }

    /**
     * @notice Updates the reward multiplier for a specific QuantumState.
     * @param _stateId The ID of the QuantumState.
     * @param _newMultiplier The new multiplier (e.g., 10000 for 1x).
     * @dev Only callable by governance. Affects rewards calculations for deposits in this state.
     */
    function updateStateRewardMultiplier(uint32 _stateId, uint256 _newMultiplier) public onlyGovernance {
         require(quantumStates[_stateId].id != 0, "State does not exist");
         require(_newMultiplier >= 10000, "New reward multiplier must be >= 10000 (1x)");
         quantumStates[_stateId].rewardMultiplier = _newMultiplier;
         emit StateRewardMultiplierUpdated(_stateId, _newMultiplier);
    }

    /**
     * @notice Calculates and accrues pending rewards for a specific deposit.
     * @param _user The address of the deposit owner.
     * @param _depositId The ID of the deposit.
     * @dev Internal helper function.
     */
    function _accrueRewards(address _user, uint256 _depositId) internal {
        Deposit storage depositInfo = deposits[_depositId];
        require(depositInfo.user == _user, "Deposit does not belong to user");
        require(depositInfo.activeStateId != 0, "Deposit state not resolved for rewards");
        require(!depositInfo.withdrawn, "Deposit already withdrawn");

        uint256 lastClaim = lastRewardClaimTime[_user][_depositId];
        uint256 accrualStartTime = (lastClaim == 0 || lastClaim < depositInfo.resolvedTime) ? depositInfo.resolvedTime : lastClaim;
        uint256 accrualEndTime = block.timestamp;

        // Ensure accrual only happens after state resolution and up to current time
        if (accrualStartTime >= accrualEndTime) {
             return; // No time passed to accrue rewards
        }

        uint256 duration = accrualEndTime - accrualStartTime;
        address tokenAddress = depositInfo.token;
        uint256 baseRate = tokenRewardRatePerSecond[tokenAddress];

        if (baseRate == 0) {
            lastRewardClaimTime[_user][_depositId] = accrualEndTime; // Update time even if rate is zero
            return; // No rewards configured for this token
        }

        uint32 activeStateId = depositInfo.activeStateId;
        QuantumState storage activeState = quantumStates[activeStateId];
        // Assuming 10000 multiplier = 1x
        uint256 multiplier = activeState.rewardMultiplier;
        if (multiplier == 0) multiplier = 10000; // Default to 1x if somehow not set

        // Formula: amount * baseRate * duration * multiplier / 10000
        uint256 depositAmount = depositInfo.amount;
        uint256 rewards = depositAmount.mul(baseRate).div(1e18); // Scale base rate (assuming baseRate is scaled, e.g., WAD) - simplified here, needs careful unit design
        rewards = rewards.mul(duration);
        rewards = rewards.mul(multiplier).div(10000);


        if (rewards > 0) {
            accumulatedRewards[_user][tokenAddress] = accumulatedRewards[_user][tokenAddress].add(rewards);
        }

        lastRewardClaimTime[_user][_depositId] = accrualEndTime;
    }


    /**
     * @notice Allows a user to claim their accumulated rewards for a specific token.
     * @param _token The address of the token for which to claim rewards.
     */
    function claimRewards(address _token) public whenNotPaused {
        require(_token != address(0), "Invalid token address");

        // Accrue rewards for all user's deposits in this token before claiming
        uint256[] storage dIds = userDepositIds[msg.sender];
        for(uint i = 0; i < dIds.length; i++) {
            Deposit storage dep = deposits[dIds[i]];
            if (dep.token == _token && dep.activeStateId != 0 && !dep.withdrawn) {
                 _accrueRewards(msg.sender, dIds[i]);
            }
        }


        uint256 claimable = accumulatedRewards[msg.sender][_token];
        require(claimable > 0, "No claimable rewards for this token");

        accumulatedRewards[msg.sender][_token] = 0;

        IERC20 token = IERC20(_token);
        token.safeTransfer(msg.sender, claimable);

        emit RewardsClaimed(msg.sender, _token, claimable);
    }


    // --- Governance & Parameter Functions ---

    /**
     * @notice Sets the address authorized for governance actions.
     * @param _governanceAddress The address of the governance contract or multisig.
     * @dev Only callable by the owner. After this is set, `onlyGovernance` modifier will check this address.
     */
    function setGovernanceContract(address _governanceAddress) public onlyOwner {
        require(_governanceAddress != address(0), "Invalid governance address");
        governanceContract = _governanceAddress;
        emit GovernanceContractUpdated(_governanceAddress);
    }

    /**
     * @notice Updates the duration of each epoch.
     * @param _duration The new epoch duration in seconds.
     * @dev Only callable by governance. The change takes effect for the *next* epoch.
     */
    function updateObservationEpochDuration(uint256 _duration) public onlyGovernance {
        require(_duration > 0, "Epoch duration must be greater than 0");
        epochDuration = _duration;
        emit EpochDurationUpdated(_duration);
    }

    /**
     * @notice Updates the minimum delay after an epoch ends before observation can be requested.
     * @param _delay The new minimum delay in seconds.
     * @dev Only callable by governance.
     */
    function updateMinimumObservationDelay(uint256 _delay) public onlyGovernance {
        minimumObservationDelay = _delay;
        emit MinimumObservationDelayUpdated(_delay);
    }

    // Note: A function like `updateStateSelectionLogic(address logicContract)` could be added
    // to allow governance to upgrade the algorithm used in `resolveEpochDeposits`. This
    // would require careful design using delegatecall or an upgradeable proxy pattern,
    // which adds significant complexity, so it's omitted here but listed in summary.

    // --- Pausable Functions inherited from OpenZeppelin ---
    // pause() and unpause() inherited. Can be called by owner (or governance if configured with Ownable(governanceContract)).
    // Adding proxy for governance to call pause/unpause if desired.
    function pause() public override onlyGovernance {
        _pause();
    }

    function unpause() public override onlyGovernance {
        _unpause();
    }

    // --- Querying & View Functions (at least 7, already listed above) ---

    /**
     * @notice Gets the details of a specific QuantumState option.
     * @param _stateId The ID of the state.
     * @return A tuple containing the state's ID, lock duration, reward multiplier, and active status.
     */
    function getQuantumStateOption(uint32 _stateId) public view returns (uint32, uint256, uint256, bool) {
        QuantumState storage state = quantumStates[_stateId];
        return (state.id, state.lockDuration, state.rewardMultiplier, state.isActive);
    }

    /**
     * @notice Lists the IDs of all currently available (active) QuantumState options.
     * @return An array of available state IDs.
     */
    function listAvailableStateOptions() public view returns (uint32[] memory) {
        // Return a copy of the available IDs array
        uint32[] memory activeIds = new uint32[](availableQuantumStateIds.length);
        for(uint i = 0; i < availableQuantumStateIds.length; i++) {
            activeIds[i] = availableQuantumStateIds[i];
        }
        return activeIds;
    }

    /**
     * @notice Gets the current deposit epoch number.
     * @return The current epoch number.
     */
    function getCurrentEpoch() public view returns (uint256) {
        return currentEpoch;
    }

    /**
     * @notice Gets the random number observed for a specific epoch.
     * @param _epoch The epoch number.
     * @return The random number, or 0 if not yet observed.
     */
    function getEpochObservation(uint256 _epoch) public view returns (uint256) {
        return epochObservations[_epoch];
    }

    /**
     * @notice Gets the list of deposit IDs for a specific user.
     * @param _user The user's address.
     * @return An array of deposit IDs owned by the user.
     */
    function getUserDepositIds(address _user) public view returns (uint256[] memory) {
         // Return a copy to prevent storage manipulation
         uint256[] storage dIds = userDepositIds[_user];
         uint256[] memory result = new uint256[](dIds.length);
         for(uint i = 0; i < dIds.length; i++) {
             result[i] = dIds[i];
         }
         return result;
    }

    /**
     * @notice Gets the full details of a specific deposit.
     * @param _depositId The ID of the deposit.
     * @return A tuple containing all deposit details.
     * @dev Returns zero values if the deposit ID is invalid.
     */
    function getUserDepositDetails(uint256 _depositId) public view returns (Deposit memory) {
        // Return a memory copy of the struct
        return deposits[_depositId];
    }

     /**
     * @notice Gets the active QuantumState ID for a deposit after observation.
     * @param _depositId The ID of the deposit.
     * @return The active state ID, or 0 if the epoch hasn't been observed yet.
     */
    function getActiveStateForDeposit(uint256 _depositId) public view depositExists(_depositId) returns (uint32) {
         return deposits[_depositId].activeStateId;
    }


    /**
     * @notice Checks if the conditions for finalizing a withdrawal for a deposit are met.
     * @param _depositId The ID of the deposit.
     * @return True if withdrawal can be finalized, false otherwise.
     */
    function canFinalizeWithdrawal(uint256 _depositId) public view depositExists(_depositId) returns (bool) {
        Deposit storage depositInfo = deposits[_depositId];
        // Must be requested, not withdrawn, and state must be resolved
        if (!depositInfo.withdrawalRequested || depositInfo.withdrawn || depositInfo.activeStateId == 0) {
            return false;
        }

        uint32 activeStateId = depositInfo.activeStateId;
        QuantumState storage activeState = quantumStates[activeStateId];

        // Check lock duration
        // Deposit time + lock duration must be in the past
        return depositInfo.depositTime.add(activeState.lockDuration) <= block.timestamp;

        // Future versions could add checks for other conditions linked to the state type
        // e.g., price feeds, external contract states etc.
    }

    /**
     * @notice Calculates the currently claimable rewards for a user for a specific token.
     * @param _user The user's address.
     * @param _token The token address.
     * @return The amount of unclaimed rewards for the user and token.
     */
    function getUserClaimableRewards(address _user, address _token) public view returns (uint256) {
        // Note: This view function does *not* accrue rewards. Call claimRewards to accrue and transfer.
        // A full calculation here would require iterating over all user's deposits
        // and calculating potential rewards up to now, which can be gas-intensive for a view.
        // We return the already accumulated (but not claimed) rewards stored in the mapping.
        // The `claimRewards` function *does* trigger the full accrual before sending.
        return accumulatedRewards[_user][_token];
    }

     /**
     * @notice Gets the total balance of a specific token held by the vault contract.
     * @param _token The token address.
     * @return The total token balance.
     */
    function getVaultTotalTokenBalance(address _token) public view returns (uint256) {
        require(_token != address(0), "Invalid token address");
        return IERC20(_token).balanceOf(address(this));
    }

    // --- Additional View Functions to reach 20+ / enhance query ---

    /**
     * @notice Gets the total number of deposits ever made.
     * @return The total deposit count.
     */
    function getTotalDepositsCount() public view returns (uint256) {
        return _depositIds.current();
    }

    /**
     * @notice Gets the total number of QuantumState options defined (active or inactive).
     * @return The total state option count.
     */
    function getTotalQuantumStatesCount() public view returns (uint256) {
        return _quantumStateIds.current();
    }

    /**
     * @notice Gets the number of deposits made within a specific epoch.
     * @param _epoch The epoch number.
     * @return The count of deposits in that epoch.
     */
    function getEpochDepositCount(uint256 _epoch) public view returns (uint256) {
        // Note: This is based on the `epochDepositIds` mapping which might be cleared
        // after resolution in a gas-optimized version.
         if (_epoch == 0 || _epoch > currentEpoch) return 0; // Invalid epoch
         return epochDepositIds[_epoch].length;
    }

    /**
     * @notice Gets the IDs of deposits made within a specific epoch.
     * @param _epoch The epoch number.
     * @return An array of deposit IDs in that epoch.
     * @dev Gas intensive for epochs with many deposits.
     */
     function getEpochDepositIds(uint256 _epoch) public view returns (uint256[] memory) {
          if (_epoch == 0 || _epoch > currentEpoch) return new uint256[](0); // Invalid epoch
          // Return a copy
          uint256[] storage dIds = epochDepositIds[_epoch];
          uint256[] memory result = new uint256[](dIds.length);
          for(uint i = 0; i < dIds.length; i++) {
              result[i] = dIds[i];
          }
          return result;
     }

    // Total view functions: 7 base + 4 additional = 11 view functions.
    // Total non-view functions: deposit, requestWithdrawal, finalizeWithdrawal, emergencyWithdraw,
    // addQuantumStateOption, removeQuantumStateOption, updateQuantumStateOption, requestObservation,
    // fulfillObservation, resolveEpochDeposits (internal), updateRewardRate, claimRewards,
    // updateStateRewardMultiplier, setGovernanceContract, updateObservationEpochDuration,
    // updateMinimumObservationDelay, pause, unpause, _accrueRewards (internal).
    // Public/External non-view: 17 functions.
    // Total public/external: 17 + 11 = 28 functions. Meets the >= 20 requirement with meaningful operations.

}
```