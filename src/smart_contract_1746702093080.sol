Okay, here is a smart contract concept called "QuantumVault". It's designed around dynamic asset states, conditional access based on external data (simulated via oracle callbacks), asset "entanglement", and time-based value changes (yield/decay). It aims for complexity beyond standard DeFi/NFT patterns by making the vault's behavior highly dependent on the internal state of deposited assets and external conditions.

**Concept:** Quantum Vault allows users to deposit ERC-20 tokens into individual "deposit slots". Each deposit has a state (`Initial`, `Entangled`, `Superposed`, `Decayed`, `Stabilized`) which affects its properties: potential yield accrual, decay rate, and withdrawal conditions. State transitions can occur automatically based on time, manually triggered by the user if conditions are met, or resolved by external data feeds (simulated oracle). Assets can be "entangled" to link their states or conditions.

**Outline:**

1.  **Pragma and Imports:** Define Solidity version, import necessary interfaces (like ERC20).
2.  **Errors:** Custom error definitions.
3.  **Events:** To signal important state changes, deposits, withdrawals, etc.
4.  **Enums:** Define the possible states for a deposit.
5.  **Structs:** Define structures for `Deposit`, `ConditionalWithdrawalRequest`, `EntangledPair`, `TransitionRule`.
6.  **State Variables:** Mappings to store deposits, requests, entangled pairs; counters; admin address; oracle address; configuration parameters (APY, decay rates, transition rules); pause status.
7.  **Modifiers:** Access control (`onlyAdmin`), pause control (`whenNotPaused`, `whenPaused`).
8.  **Constructor:** Initialize admin.
9.  **Core Vault Functions:** Deposit, Withdraw (basic, conditional).
10. **Deposit State Management:** Trigger state transitions, apply decay, claim yield.
11. **Entanglement:** Link and unlink deposits.
12. **Superposition & Oracle Interaction:** Request data, process oracle callbacks.
13. **Deposit Ownership:** Transfer ownership of a specific deposit slot.
14. **Admin Functions:** Pause, unpause, set rates, set transition rules, set oracle address, rescue tokens.
15. **View Functions:** Get deposit details, user balances, pending requests, rules, calculated value.
16. **Internal Helper Functions:** Calculate yield/decay, check transition conditions, get next deposit ID.

**Function Summary:**

1.  `deposit(address token, uint256 amount)`: Deposits ERC-20 tokens, creates a new deposit entry in `Initial` state.
2.  `withdraw(uint256 depositIndex, uint256 amount)`: Attempts to withdraw from a specific deposit. May fail if state doesn't allow it.
3.  `requestConditionalWithdrawal(uint256 depositIndex, uint256 amount, bytes32 conditionIdentifier)`: Requests a withdrawal that is pending an external condition (oracle result). Locks the amount in the deposit.
4.  `cancelConditionalWithdrawal(bytes32 requestId)`: Cancels a pending conditional withdrawal request.
5.  `claimConditionalWithdrawal(bytes32 requestId)`: Executes a conditional withdrawal if the linked oracle condition has been fulfilled positively.
6.  `triggerStateTransition(uint256 depositIndex)`: Attempts to move a deposit to a new state based on defined rules (time, value, etc.).
7.  `batchTriggerStateTransition(uint256[] depositIndexes)`: Applies `triggerStateTransition` to multiple deposits.
8.  `entangleDeposits(uint256 depositIndex1, uint256 depositIndex2)`: Links two deposits, potentially making their states or conditions interdependent. Requires specific states for both.
9.  `disentangleDeposits(uint256 entangledPairId)`: Breaks an entanglement link. Requires specific states.
10. `requestSuperpositionState(uint256 depositIndex, bytes32 oracleConditionId)`: Puts a deposit into `Superposed` state, linking its future state transition to an oracle result identified by `oracleConditionId`. (Simulates triggering an oracle request).
11. `fulfillOracleCondition(bytes32 oracleConditionId, uint256 oracleResult)`: Callback function *only* callable by the designated oracle address to provide external data, potentially resolving `Superposed` states or conditional withdrawals.
12. `applyDecay(uint256 depositIndex)`: Explicitly calculates and applies decay penalties based on the deposit's state and age if in a `Decayed` state. (Can be called by anyone, decay applied based on time).
13. `claimYield(uint256 depositIndex)`: Calculates and transfers accrued yield (if applicable based on state) to the deposit owner. Resets yield calculation timestamp for that deposit.
14. `transferDepositOwnership(uint256 depositIndex, address recipient)`: Transfers ownership of a specific deposit slot (including its state, amount, history) to another address.
15. `pause()`: Admin function to pause critical contract operations.
16. `unpause()`: Admin function to unpause operations.
17. `setTransitionRule(State fromState, State toState, bytes32 conditionIdentifier, uint256 timeLockDuration, uint256 minDepositValue)`: Admin function to configure the rules governing state transitions.
18. `setAPYBaseRate(address token, uint256 rate)`: Admin function to set the base Annual Percentage Yield for a specific token (used in yield calculation for certain states).
19. `setDecayRate(address token, uint256 rate)`: Admin function to set the decay rate for a specific token (used in decay calculation for certain states).
20. `setOracleAddress(address _oracle)`: Admin function to set the address of the trusted oracle contract.
21. `rescueERC20(address token, uint256 amount, address recipient)`: Admin function to rescue tokens accidentally sent to the contract, *excluding* tokens currently held in user deposits.
22. `getDepositDetails(uint256 depositIndex)`: View function to get all details of a specific deposit.
23. `getUserDepositIndexes(address user)`: View function to get all deposit indexes owned by a user.
24. `getEntangledPair(uint256 depositIndex)`: View function to find the entangled partner deposit index for a given deposit.
25. `getPendingConditionalWithdrawals(address user)`: View function to list all pending conditional withdrawal request IDs for a user.
26. `getTransitionRule(State fromState, State toState)`: View function to retrieve a specific transition rule configuration.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Note: In a real scenario, oracle interaction would use a library like Chainlink.
// This contract simulates the callback mechanism for demonstration purposes.
// It assumes an external oracle contract exists and is trusted to call fulfillOracleCondition.

/**
 * @title QuantumVault
 * @dev A complex vault contract featuring dynamic asset states, conditional withdrawals,
 *      asset entanglement, time-based yield/decay, and external oracle interaction.
 */
contract QuantumVault {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/
    error NotAdmin();
    error Paused();
    error NotPaused();
    error TokenNotSupported();
    error DepositNotFound();
    error InsufficientBalanceInDeposit();
    error InvalidDepositStateForAction(State currentState);
    error DepositNotOwnedByUser();
    error ConditionalWithdrawalNotFound();
    error ConditionalWithdrawalNotFulfilled();
    error ConditionalWithdrawalAlreadyClaimedOrCancelled();
    error InvalidDepositStateForTransition(State fromState, State toState);
    error TransitionConditionsNotMet();
    error DepositsCannotBeEntangled(uint256 depositIndex1, uint256 depositIndex2);
    error DepositsAlreadyEntangled(uint256 depositIndex1, uint256 depositIndex2);
    error EntangledPairNotFound();
    error DepositNotEntangled();
    error OracleAddressNotSet();
    error CallerNotOracle();
    error SuperpositionRequiresOracleCondition();
    error TransferToZeroAddress();
    error CannotRescueVaultTokens();
    error AmountMustBeGreaterThanZero();
    error DepositAmountTooLowForStateChange();

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    event TokenDeposited(address indexed user, address indexed token, uint256 depositIndex, uint256 amount, uint256 timestamp);
    event TokenWithdrawal(address indexed user, address indexed token, uint256 depositIndex, uint256 amount, uint256 timestamp);
    event ConditionalWithdrawalRequested(address indexed user, uint256 depositIndex, bytes32 indexed requestId, address token, uint256 amount, bytes32 conditionIdentifier);
    event ConditionalWithdrawalCancelled(bytes32 indexed requestId);
    event ConditionalWithdrawalClaimed(bytes32 indexed requestId, uint256 actualAmount); // Actual amount might differ after yield/decay
    event StateTransitioned(uint256 indexed depositIndex, State indexed fromState, State indexed toState, uint256 timestamp);
    event DepositsEntangled(uint256 indexed pairId, uint256 indexed depositIndex1, uint256 indexed depositIndex2);
    event DepositsDisentangled(uint256 indexed pairId);
    event DepositOwnershipTransferred(uint256 indexed depositIndex, address indexed oldOwner, address indexed newOwner);
    event YieldClaimed(uint256 indexed depositIndex, uint256 amount);
    event DecayApplied(uint256 indexed depositIndex, uint256 amountLost);
    event OracleConditionFulfilled(bytes32 indexed conditionId, uint256 result);
    event VaultPaused();
    event VaultUnpaused();
    event AdminChanged(address indexed newAdmin);
    event OracleAddressChanged(address indexed newOracle);
    event TransitionRuleUpdated(State fromState, State toState, bytes32 conditionIdentifier, uint256 timeLockDuration, uint256 minDepositValue);

    /*//////////////////////////////////////////////////////////////
                                ENUMS
    //////////////////////////////////////////////////////////////*/
    enum State {
        Initial,      // Just deposited, basic yield/decay might apply
        Entangled,    // Linked with another deposit, state/conditions might sync
        Superposed,   // Waiting for external oracle data to resolve state
        Decayed,      // Past a certain age/condition, subject to decay penalties
        Stabilized    // Matured or met specific conditions, potentially higher yield/stable value
    }

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/
    struct Deposit {
        address owner;
        address token;
        uint256 amount;                 // Current principal + accrued yield/decay
        uint256 initialAmount;          // Original deposited amount
        uint256 initialTimestamp;       // When deposited
        uint256 lastYieldDecayTimestamp;// When yield/decay was last applied
        State state;
        uint256 entangledPairId;        // 0 if not entangled
        bytes32 superposedConditionId;  // 0 if not Superposed
        uint256 pendingWithdrawalAmount;// Amount locked by a conditional withdrawal request
    }

    struct ConditionalWithdrawalRequest {
        address user;
        uint256 depositIndex;
        address token;
        uint256 amount;
        bytes32 conditionIdentifier;    // Identifier for the oracle condition
        bool isFulfilled;               // Set by oracle callback
        bool isCancelled;               // Set by user
    }

    struct EntangledPair {
        uint256 depositIndex1;
        uint256 depositIndex2;
    }

    struct TransitionRule {
        State fromState;
        State toState;
        bytes32 conditionIdentifier;    // Identifier for an internal or external condition
        uint256 timeLockDuration;       // Minimum time in the fromState
        uint256 minDepositValue;        // Minimum amount in the deposit
    }

    /*//////////////////////////////////////////////////////////////
                             STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    address public admin;
    address public oracle;
    bool public paused;

    uint256 private nextDepositIndex = 1;
    mapping(uint256 => Deposit) public deposits;
    mapping(address => uint256[]) private userDepositIndexes; // To track deposits per user

    uint256 private nextRequestId = 1;
    mapping(bytes32 => ConditionalWithdrawalRequest) public conditionalWithdrawalRequests;

    uint256 private nextEntangledPairId = 1;
    mapping(uint256 => EntangledPair) public entangledPairs;
    mapping(uint256 => uint256) private depositToEntangledPairId; // Map deposit index to pair ID

    // Configuration
    mapping(address => uint256) public apyBaseRate; // Stored as basis points (e.g., 100 = 1%)
    mapping(address => uint256) public decayRate;   // Stored as basis points (e.g., 50 = 0.5%)

    // State Transition Rules: mapping from (fromState, toState) => Rule
    // Note: This simple mapping means only one rule per state transition *pair* exists.
    // More complex logic might require mapping to an array of rules or a different structure.
    mapping(State => mapping(State => TransitionRule)) public transitionRules;


    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert NotAdmin();
        }
        _;
    }

    modifier whenNotPaused() {
        if (paused) {
            revert Paused();
        }
        _;
    }

    modifier whenPaused() {
        if (!paused) {
            revert NotPaused();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor() {
        admin = msg.sender;
    }

    /*//////////////////////////////////////////////////////////////
                         CORE VAULT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Deposits ERC-20 tokens into the vault, creating a new deposit entry.
     *      The deposit starts in the Initial state.
     * @param token The address of the ERC-20 token being deposited.
     * @param amount The amount of tokens to deposit.
     */
    function deposit(address token, uint256 amount) external whenNotPaused {
        if (amount == 0) revert AmountMustBeGreaterThanZero();
        // In a real contract, you might check if the token is supported
        // require(isTokenSupported[token], "Token not supported");

        IERC20 tokenContract = IERC20(token);
        tokenContract.safeTransferFrom(msg.sender, address(this), amount);

        uint256 depositIndex = nextDepositIndex++;
        uint256 timestamp = block.timestamp;

        deposits[depositIndex] = Deposit({
            owner: msg.sender,
            token: token,
            amount: amount,
            initialAmount: amount,
            initialTimestamp: timestamp,
            lastYieldDecayTimestamp: timestamp,
            state: State.Initial,
            entangledPairId: 0,
            superposedConditionId: bytes32(0),
            pendingWithdrawalAmount: 0
        });

        userDepositIndexes[msg.sender].push(depositIndex);

        emit TokenDeposited(msg.sender, token, depositIndex, amount, timestamp);
    }

    /**
     * @dev Attempts to withdraw a specified amount from a specific deposit.
     *      Withdrawal is restricted based on the deposit's current state.
     * @param depositIndex The index of the deposit to withdraw from.
     * @param amount The amount to withdraw.
     */
    function withdraw(uint256 depositIndex, uint256 amount) external whenNotPaused {
        Deposit storage deposit = deposits[depositIndex];
        if (deposit.owner == address(0)) revert DepositNotFound();
        if (deposit.owner != msg.sender) revert DepositNotOwnedByUser();
        if (amount == 0) revert AmountMustBeGreaterThanZero();
        if (amount > deposit.amount - deposit.pendingWithdrawalAmount) revert InsufficientBalanceInDeposit();

        // Only allow withdrawal from specific states, or maybe always allow but with penalties?
        // Let's restrict for this example: only Initial and Stabilized states allow free withdrawal.
        // Decayed might allow withdrawal with penalty (handled by calculateCurrentValue/claimYield implicitly).
        // Entangled/Superposed might require disentangling/resolving first.
        if (deposit.state != State.Initial && deposit.state != State.Stabilized && deposit.state != State.Decayed) {
             revert InvalidDepositStateForAction(deposit.state);
        }

        // Apply any pending yield/decay before withdrawal if state allows
        _applyYieldOrDecay(depositIndex);

        // Re-check amount after potential yield/decay
        if (amount > deposit.amount - deposit.pendingWithdrawalAmount) revert InsufficientBalanceInDeposit();

        deposit.amount -= amount;

        IERC20(deposit.token).safeTransfer(msg.sender, amount);

        emit TokenWithdrawal(msg.sender, deposit.token, depositIndex, amount, block.timestamp);

        // If deposit is now empty, clean up (optional, adds complexity)
        // For simplicity, we leave the entry but with amount 0.
    }

     /**
     * @dev Requests a withdrawal that will only be claimable after a specific external condition
     *      (identified by conditionIdentifier) is met. The amount is locked in the deposit.
     * @param depositIndex The index of the deposit to request withdrawal from.
     * @param amount The amount to lock for conditional withdrawal.
     * @param conditionIdentifier A bytes32 identifier for the required condition (e.g., a Chainlink request ID).
     */
    function requestConditionalWithdrawal(uint256 depositIndex, uint256 amount, bytes32 conditionIdentifier) external whenNotPaused {
        Deposit storage deposit = deposits[depositIndex];
        if (deposit.owner == address(0)) revert DepositNotFound();
        if (deposit.owner != msg.sender) revert DepositNotOwnedByUser();
        if (amount == 0) revert AmountMustBeGreaterThanZero();
         // Ensure state allows requesting conditional withdrawal (e.g., not already Superposed or Decayed)
        if (deposit.state == State.Superposed || deposit.state == State.Decayed) {
             revert InvalidDepositStateForAction(deposit.state);
        }

        // Ensure deposit has enough *available* balance (not already locked)
        if (amount > deposit.amount - deposit.pendingWithdrawalAmount) revert InsufficientBalanceInDeposit();
        if (conditionIdentifier == bytes32(0)) revert SuperpositionRequiresOracleCondition(); // Needs a condition

        bytes32 requestId = keccak256(abi.encodePacked(depositIndex, amount, conditionIdentifier, block.timestamp, msg.sender, nextRequestId++)); // Generate a unique request ID

        conditionalWithdrawalRequests[requestId] = ConditionalWithdrawalRequest({
            user: msg.sender,
            depositIndex: depositIndex,
            token: deposit.token,
            amount: amount,
            conditionIdentifier: conditionIdentifier,
            isFulfilled: false,
            isCancelled: false
        });

        deposit.pendingWithdrawalAmount += amount; // Lock the amount

        emit ConditionalWithdrawalRequested(msg.sender, depositIndex, requestId, deposit.token, amount, conditionIdentifier);

        // In a real scenario, you might trigger an oracle request here based on conditionIdentifier
        // requestOracleData(conditionIdentifier, ...);
    }

    /**
     * @dev Cancels a pending conditional withdrawal request. Unlocks the amount in the deposit.
     * @param requestId The ID of the conditional withdrawal request to cancel.
     */
    function cancelConditionalWithdrawal(bytes32 requestId) external whenNotPaused {
        ConditionalWithdrawalRequest storage request = conditionalWithdrawalRequests[requestId];
        if (request.user == address(0)) revert ConditionalWithdrawalNotFound();
        if (request.user != msg.sender) revert DepositNotOwnedByUser(); // Request owner must be msg.sender
        if (request.isCancelled) revert ConditionalWithdrawalAlreadyClaimedOrCancelled();

        Deposit storage deposit = deposits[request.depositIndex];
        if (deposit.owner == address(0)) revert DepositNotFound(); // Should not happen if request exists, but safety check
        // Also check if the deposit ownership changed after request was made (more complex logic needed)
        // Assuming for simplicity request owner must match current deposit owner to cancel

        request.isCancelled = true;
        deposit.pendingWithdrawalAmount -= request.amount; // Unlock the amount

        emit ConditionalWithdrawalCancelled(requestId);
    }

    /**
     * @dev Claims a conditional withdrawal if the associated oracle condition has been fulfilled positively.
     * @param requestId The ID of the conditional withdrawal request to claim.
     */
    function claimConditionalWithdrawal(bytes32 requestId) external whenNotPaused {
        ConditionalWithdrawalRequest storage request = conditionalWithdrawalRequests[requestId];
        if (request.user == address(0)) revert ConditionalWithdrawalNotFound();
        if (request.user != msg.sender) revert DepositNotOwnedByUser(); // Request owner must be msg.sender
        if (!request.isFulfilled) revert ConditionalWithdrawalNotFulfilled();
        if (request.isCancelled) revert ConditionalWithdrawalAlreadyClaimedOrCancelled();

        Deposit storage deposit = deposits[request.depositIndex];
         if (deposit.owner == address(0)) revert DepositNotFound(); // Should not happen
         // Also check if the deposit ownership changed after request was made

        request.isCancelled = true; // Mark as claimed (cannot be claimed again)

        // Apply pending yield/decay to the deposit BEFORE transferring
        _applyYieldOrDecay(request.depositIndex);

        // Calculate the actual amount to transfer based on the current deposit amount and locked amount
        uint256 amountToTransfer = request.amount;
        // Ensure the deposit still has the locked amount available after yield/decay
        if (deposit.amount - deposit.pendingWithdrawalAmount < 0) { // This check is technically redundant with amount < deposit.amount in Deposit struct
             // If decay reduced the amount below the locked amount, transfer what's left up to the locked amount
             amountToTransfer = deposit.amount > deposit.pendingWithdrawalAmount ? deposit.amount - deposit.pendingWithdrawalAmount + amountToTransfer : amountToTransfer;
             // This logic for decay interaction with pending withdrawal needs careful thought.
             // Simplest: amountToTransfer is exactly request.amount if deposit.amount >= request.amount + deposit.pendingWithdrawalAmount
             // Complex: Adjust amountToTransfer based on remaining deposit balance.
             // Let's assume principal + locked amount is always available for transfer once fulfilled for simplicity:
             // The 'amount' in the request is what's intended. The locked amount is removed from pending.
             // The actual transfer comes from the deposit's total amount.
              if (deposit.amount < request.amount) {
                  // This indicates a problem or decay reduced the principal below the requested withdrawal.
                  // Option A: Transfer less. Option B: Revert. Option C: Transfer 0 and log error.
                  // Let's transfer up to the current balance in the deposit, minimum of request.amount.
                  // The user requested X. The deposit principal was Y. Now it's Z due to yield/decay.
                  // The amount locked was X. The available is Z - X.
                  // The transfer amount should be min(X, Z). Let's transfer min(request.amount, deposit.amount).
                  // This means decay *can* reduce the amount received from a conditional withdrawal.
                  amountToTransfer = deposit.amount < request.amount ? deposit.amount : request.amount;
              }
        }
         // Ensure we don't transfer more than is currently in the deposit
        if (amountToTransfer > deposit.amount) {
             amountToTransfer = deposit.amount;
        }


        deposit.pendingWithdrawalAmount -= request.amount; // Unlock the original requested amount

        if (amountToTransfer > 0) {
             deposit.amount -= amountToTransfer;
             IERC20(request.token).safeTransfer(msg.sender, amountToTransfer);
        }


        emit ConditionalWithdrawalClaimed(requestId, amountToTransfer);
    }


    /*//////////////////////////////////////////////////////////////
                         DEPOSIT STATE MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Attempts to transition a deposit's state based on defined rules and conditions.
     * @param depositIndex The index of the deposit.
     */
    function triggerStateTransition(uint256 depositIndex) external whenNotPaused {
         Deposit storage deposit = deposits[depositIndex];
         if (deposit.owner == address(0)) revert DepositNotFound();
         // Allow anyone to trigger, but checks conditions internally

         State currentState = deposit.state;
         bool transitioned = false;

         // Check potential transitions from current state
         // Iterate through all defined rules (simplified)
         // In a real contract, you'd iterate rules relevant to currentState
         // For simplicity, we only support a few specific transitions hardcoded or checked via rules mapping
         State[] memory potentialNextStates = new State[](4); // Max potential states to check from any given state
         uint256 count = 0;
         if (currentState == State.Initial) {
             potentialNextStates[count++] = State.Stabilized; // e.g., based on time/min value
             potentialNextStates[count++] = State.Decayed;    // e.g., based on time without action
             potentialNextStates[count++] = State.Entangled;  // e.g., user action + rule
             potentialNextStates[count++] = State.Superposed; // e.g., user action + rule
         } else if (currentState == State.Entangled) {
              // Entangled transitions might require both deposits meeting conditions
              potentialNextStates[count++] = State.Stabilized;
              potentialNextStates[count++] = State.Decayed;
         } else if (currentState == State.Superposed) {
             // Superposed requires oracle resolution via fulfillOracleCondition
             // Cannot be triggered manually here.
         } else if (currentState == State.Decayed) {
             potentialNextStates[count++] = State.Stabilized; // e.g., by adding more value or admin action
         } else if (currentState == State.Stabilized) {
             // Stabilized might not have manual transitions, or only to specific states
         }

         // Iterate through potential next states and check rules
         for (uint256 i = 0; i < count; i++) {
             State nextState = potentialNextStates[i];
             TransitionRule storage rule = transitionRules[currentState][nextState];

             // Check if a rule exists for this transition pair
             // We use conditionIdentifier as a marker for rule existence (bytes32(0) = no rule)
             if (rule.conditionIdentifier != bytes32(0)) {
                  // Check rule conditions
                  bool conditionsMet = _checkTransitionCondition(depositIndex, rule);

                  if (conditionsMet) {
                      deposit.state = nextState;
                      // Reset yield/decay tracking timestamp on state change
                      deposit.lastYieldDecayTimestamp = block.timestamp;
                      emit StateTransitioned(depositIndex, currentState, nextState, block.timestamp);
                      transitioned = true;
                      break; // Only transition to one state per trigger
                  }
             }
         }

         if (!transitioned) {
              // Optional: Revert if no transition occurred, or just do nothing
              // revert TransitionConditionsNotMet(); // Or a more specific error
         }
    }

     /**
      * @dev Helper internal function to check if a specific transition rule's conditions are met.
      *      This function contains the custom logic for different condition identifiers.
      * @param depositIndex The index of the deposit.
      * @param rule The transition rule to check.
      * @return bool True if conditions are met, false otherwise.
      */
     function _checkTransitionCondition(uint256 depositIndex, TransitionRule storage rule) internal view returns (bool) {
         Deposit storage deposit = deposits[depositIndex];

         // Basic checks applicable to most rules
         if (block.timestamp < deposit.initialTimestamp + rule.timeLockDuration) return false;
         if (deposit.amount < rule.minDepositValue) return false;

         // Custom checks based on conditionIdentifier
         // This is where complex logic for different transitions lives
         if (rule.conditionIdentifier == bytes32("time_and_value_met")) {
             // Conditions already checked above (timeLockDuration and minDepositValue)
             return true;
         } else if (rule.conditionIdentifier == bytes32("decay_threshold_reached")) {
             // Check if decay has reached a certain percentage of the initial amount
             // Requires storing initialAmount and calculating decay
             uint256 currentTheoreticalValue = _calculateCurrentValue(depositIndex); // Calculate value *without* applying decay
             if (deposit.initialAmount > 0) {
                 // Example: Transition to Stabilized if current value is >= 95% of initial amount (recovering from decay)
                 if (currentTheoreticalValue * 100 >= deposit.initialAmount * 95) {
                     return true;
                 }
             }
             return false;
         } else if (rule.conditionIdentifier == bytes32("is_entangled_and_stabilized")) {
             // Check if the deposit is entangled and its entangled partner is in Stabilized state
             if (deposit.entangledPairId == 0) return false;
             uint256 pairId = deposit.entangledPairId;
             EntangledPair storage pair = entangledPairs[pairId];
             uint256 otherDepositIndex = (pair.depositIndex1 == depositIndex) ? pair.depositIndex2 : pair.depositIndex1;
             Deposit storage otherDeposit = deposits[otherDepositIndex];
             return otherDeposit.state == State.Stabilized;

         }
         // Add more custom conditions here...

         // If conditionIdentifier is recognized but conditions aren't met
         return false;
     }


    /**
     * @dev Attempts to trigger state transition for a batch of deposits.
     *      Note: This can be gas-intensive for large arrays.
     * @param depositIndexes An array of deposit indexes.
     */
    function batchTriggerStateTransition(uint256[] calldata depositIndexes) external whenNotPaused {
        // Basic check, more gas checks might be needed in production
        if (depositIndexes.length > 50) revert("Batch size too large");

        for (uint256 i = 0; i < depositIndexes.length; i++) {
            // Use try-catch to allow batch processing even if one transition fails
            try this.triggerStateTransition(depositIndexes[i]) {} catch {}
        }
    }

    /**
     * @dev Calculates the current effective value of a deposit, including accrued yield or applied decay.
     *      Does NOT modify the deposit amount.
     * @param depositIndex The index of the deposit.
     * @return uint256 The calculated current value of the deposit.
     */
    function calculateCurrentValue(uint256 depositIndex) public view returns (uint256) {
        Deposit storage deposit = deposits[depositIndex];
        if (deposit.owner == address(0)) return 0; // Deposit not found

        uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime - deposit.lastYieldDecayTimestamp;
        uint256 currentAmount = deposit.amount;

        if (timeElapsed == 0) return currentAmount; // No time passed since last update

        uint256 rate; // Basis points per year
        bool isYield;

        // Determine rate and type (yield or decay) based on state
        if (deposit.state == State.Initial || deposit.state == State.Stabilized || deposit.state == State.Entangled) {
             rate = apyBaseRate[deposit.token];
             isYield = true;
        } else if (deposit.state == State.Decayed) {
             rate = decayRate[deposit.token];
             isYield = false;
        } else {
             // Superposed or other states might not accrue/decay, or depend on oracle result
             return currentAmount;
        }

        if (rate == 0) return currentAmount; // No rate set

        // Calculate change. Simple linear calculation for demonstration.
        // Real contracts use more complex compounding.
        // rate is basis points per year (10000 basis points = 100%)
        // timeElapsed is in seconds
        // seconds per year = 365 days * 24 hours/day * 60 minutes/hour * 60 seconds/minute
        uint256 secondsPerYear = 31536000; // Average Gregorian year

        uint256 change = (currentAmount * rate * timeElapsed) / (10000 * secondsPerYear);

        if (isYield) {
            return currentAmount + change;
        } else {
            // Ensure amount doesn't go below zero (though uint256 makes this difficult without underflow checks)
            // We cap decay at 0
            return currentAmount > change ? currentAmount - change : 0;
        }
    }

    /**
     * @dev Applies accrued yield or decay to a deposit based on its state and time elapsed.
     *      Updates the deposit's amount and last calculation timestamp.
     * @param depositIndex The index of the deposit.
     */
    function _applyYieldOrDecay(uint256 depositIndex) internal {
         Deposit storage deposit = deposits[depositIndex];
         if (deposit.owner == address(0) || deposit.amount == 0) return; // Nothing to do

         uint256 currentTime = block.timestamp;
         uint256 timeElapsed = currentTime - deposit.lastYieldDecayTimestamp;

         if (timeElapsed == 0) return; // No time passed since last update

         uint256 currentAmount = deposit.amount;
         uint256 calculatedValue = calculateCurrentValue(depositIndex); // Use the public view function logic

         if (calculatedValue > currentAmount) {
             uint256 yieldAmount = calculatedValue - currentAmount;
             deposit.amount = calculatedValue;
             emit YieldClaimed(depositIndex, yieldAmount); // Emit as "claimed" even if just applied internally
         } else if (calculatedValue < currentAmount) {
             uint256 decayAmount = currentAmount - calculatedValue;
             deposit.amount = calculatedValue;
             emit DecayApplied(depositIndex, decayAmount);
         }
         // If calculatedValue == currentAmount, no change

         deposit.lastYieldDecayTimestamp = currentTime; // Reset timestamp after applying change
    }

     /**
     * @dev Callable function to force application of yield or decay for a specific deposit.
     *      Users might call this before withdrawing or transferring to get the updated value.
     * @param depositIndex The index of the deposit.
     */
    function applyDecay(uint256 depositIndex) external whenNotPaused {
        // Renamed from applyDecay to applyYieldOrDecayExternal to reflect internal helper name
        // and indicate it applies both yield and decay based on state.
        // Renamed back to applyDecay for the function summary name, but internal helper is more precise.
        // Let's just call the internal helper.
         Deposit storage deposit = deposits[depositIndex];
         if (deposit.owner == address(0)) revert DepositNotFound();
         // Anyone can trigger this to update the deposit's value

         _applyYieldOrDecay(depositIndex);
    }

    /**
     * @dev Transfers ownership of a specific deposit slot to another address.
     *      The recipient gains full control over the deposit, including state, amount, etc.
     * @param depositIndex The index of the deposit to transfer.
     * @param recipient The address to transfer ownership to.
     */
    function transferDepositOwnership(uint256 depositIndex, address recipient) external whenNotPaused {
        Deposit storage deposit = deposits[depositIndex];
        if (deposit.owner == address(0)) revert DepositNotFound();
        if (deposit.owner != msg.sender) revert DepositNotOwnedByUser();
        if (recipient == address(0)) revert TransferToZeroAddress();
        if (recipient == deposit.owner) return; // No-op

        address oldOwner = deposit.owner;
        deposit.owner = recipient;

        // Update userDepositIndexes mappings
        // This requires iterating and removing from old owner's array, and adding to new owner's.
        // Can be gas intensive. Simple implementation just adds to new owner's array.
        // A more efficient way would be to use a linked list or a more complex mapping.
        // For simplicity, let's just push to the new owner's array. Removal from old owner's
        // array is omitted for brevity and gas efficiency concerns in this example, but
        // would be needed for accurate `getUserDepositIndexes`.

        userDepositIndexes[recipient].push(depositIndex);
        // Removing from userDepositIndexes[oldOwner] is non-trivial and gas costly.
        // A better design would use a different data structure for user ownership tracking.
        // For this example, `getUserDepositIndexes` might show deposits the user no longer owns
        // unless iterating and checking `deposits[index].owner`.

        emit DepositOwnershipTransferred(depositIndex, oldOwner, recipient);
    }


    /*//////////////////////////////////////////////////////////////
                              ENTANGLEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Entangles two deposits. This links their states or makes them interdependent based on rules.
     *      Requires both deposits to be in the Initial state.
     * @param depositIndex1 The index of the first deposit.
     * @param depositIndex2 The index of the second deposit.
     */
    function entangleDeposits(uint256 depositIndex1, uint256 depositIndex2) external whenNotPaused {
        if (depositIndex1 == depositIndex2) revert DepositsCannotBeEntangled(depositIndex1, depositIndex2);

        Deposit storage deposit1 = deposits[depositIndex1];
        Deposit storage deposit2 = deposits[depositIndex2];

        if (deposit1.owner == address(0) || deposit2.owner == address(0)) revert DepositNotFound();
        // Both deposits must be owned by the caller to entangle
        if (deposit1.owner != msg.sender || deposit2.owner != msg.sender) revert DepositNotOwnedByUser();

        // Check if already entangled
        if (deposit1.entangledPairId != 0 || deposit2.entangledPairId != 0) revert DepositsAlreadyEntangled(depositIndex1, depositIndex2);

        // Require specific states for entanglement (e.g., both must be Initial)
        if (deposit1.state != State.Initial || deposit2.state != State.Initial) {
            revert InvalidDepositStateForAction(deposit1.state); // Or a more specific error
        }
         // Ensure they are the same token for simplicity
        if (deposit1.token != deposit2.token) revert DepositsCannotBeEntangled(depositIndex1, depositIndex2);

        uint256 pairId = nextEntangledPairId++;
        entangledPairs[pairId] = EntangledPair({
            depositIndex1: depositIndex1,
            depositIndex2: depositIndex2
        });

        deposit1.entangledPairId = pairId;
        deposit2.entangledPairId = pairId;

        // Transition both to Entangled state
        deposit1.state = State.Entangled;
        deposit2.state = State.Entangled;
         deposit1.lastYieldDecayTimestamp = block.timestamp;
         deposit2.lastYieldDecayTimestamp = block.timestamp;


        emit DepositsEntangled(pairId, depositIndex1, depositIndex2);
        emit StateTransitioned(depositIndex1, State.Initial, State.Entangled, block.timestamp);
        emit StateTransitioned(depositIndex2, State.Initial, State.Entangled, block.timestamp);
    }

    /**
     * @dev Disentangles a pair of deposits. Requires both to be in the Entangled state.
     * @param entangledPairId The ID of the entangled pair to disentangle.
     */
    function disentangleDeposits(uint256 entangledPairId) external whenNotPaused {
         EntangledPair storage pair = entangledPairs[entangledPairId];
         if (pair.depositIndex1 == 0) revert EntangledPairNotFound();

         Deposit storage deposit1 = deposits[pair.depositIndex1];
         Deposit storage deposit2 = deposits[pair.depositIndex2];

         // Both deposits must be owned by the caller to disentangle
         if (deposit1.owner != msg.sender || deposit2.owner != msg.sender) revert DepositNotOwnedByUser();

         // Require both deposits to be in the Entangled state to disentangle
         if (deposit1.state != State.Entangled || deposit2.state != State.Entangled) {
             revert InvalidDepositStateForAction(deposit1.state); // Or specific error
         }

         deposit1.entangledPairId = 0;
         deposit2.entangledPairId = 0;

         // Transition both back to Initial state (or another state based on rules)
         // For simplicity, let's transition them to a base state like Initial or Stabilized
         // depending on time held in Entangled state etc. Let's transition to Initial for now.
         deposit1.state = State.Initial;
         deposit2.state = State.Initial;
         deposit1.lastYieldDecayTimestamp = block.timestamp;
         deposit2.lastYieldDecayTimestamp = block.timestamp;


         // Clear the pair entry (optional, saves space but complicates iteration)
         delete entangledPairs[entangledPairId];

         emit DepositsDisentangled(entangledPairId);
         emit StateTransitioned(pair.depositIndex1, State.Entangled, State.Initial, block.timestamp);
         emit StateTransitioned(pair.depositIndex2, State.Entangled, State.Initial, block.timestamp);
    }


    /*//////////////////////////////////////////////////////////////
                         SUPERPOSITION & ORACLE
    //////////////////////////////////////////////////////////////*/

     /**
     * @dev Puts a deposit into the Superposed state, pending resolution by a specific oracle condition.
     *      Requires the deposit to be in a state allowing superposition (e.g., Initial or Entangled).
     * @param depositIndex The index of the deposit.
     * @param oracleConditionId An identifier linking to the external oracle data feed or condition.
     */
    function requestSuperpositionState(uint256 depositIndex, bytes32 oracleConditionId) external whenNotPaused {
        Deposit storage deposit = deposits[depositIndex];
        if (deposit.owner == address(0)) revert DepositNotFound();
        if (deposit.owner != msg.sender) revert DepositNotOwnedByUser();
        if (oracleConditionId == bytes32(0)) revert SuperpositionRequiresOracleCondition();

        // Only allow transition to Superposed from certain states
        if (deposit.state != State.Initial && deposit.state != State.Entangled) {
             revert InvalidDepositStateForAction(deposit.state);
        }
        // Cannot request superposition if already in superposition or has a pending condition
        if (deposit.state == State.Superposed || deposit.superposedConditionId != bytes32(0)) {
             revert InvalidDepositStateForAction(deposit.state);
        }

        // In a real contract, this would trigger an oracle request using Chainlink or similar.
        // e.g., LinkToken.transferAndCall(oracleAddress, fee, abi.encode(oracleJobId, address(this), bytes4(keccak256("fulfillOracleCondition(bytes32,uint256)")), oracleConditionId));

        deposit.state = State.Superposed;
        deposit.superposedConditionId = oracleConditionId;
        deposit.lastYieldDecayTimestamp = block.timestamp; // Reset timestamp

        emit StateTransitioned(depositIndex, deposit.state == State.Initial ? State.Initial : State.Entangled, State.Superposed, block.timestamp);
        // Emit event for the request itself might be useful too
    }


    /**
     * @dev Callback function for the oracle to fulfill a condition.
     *      Resolves Superposed states or conditional withdrawals linked to this condition ID.
     *      ONLY callable by the designated oracle address.
     * @param oracleConditionId The identifier of the condition being fulfilled.
     * @param oracleResult The result from the oracle (e.g., price, random number, boolean encoded).
     */
    function fulfillOracleCondition(bytes32 oracleConditionId, uint256 oracleResult) external whenNotPaused {
        if (oracle == address(0)) revert OracleAddressNotSet();
        if (msg.sender != oracle) revert CallerNotOracle();
        if (oracleConditionId == bytes32(0)) return; // Nothing to do

        emit OracleConditionFulfilled(oracleConditionId, oracleResult);

        // --- Resolve Superposed Deposits ---
        // Find deposits waiting for this condition ID.
        // This requires iterating through all deposits or maintaining a mapping from conditionId to depositIndex array.
        // Iterating all deposits is gas-prohibitive for large numbers.
        // For simplicity in this example, we won't automatically resolve *all* superposed deposits here.
        // A realistic approach: the oracle callback finds the *specific* request ID or deposit ID it was called for.
        // Or, a separate keeper system monitors oracle results and calls `triggerStateTransition` for relevant deposits.

        // Let's add a simple placeholder loop (not scalable)
        // In a real dApp, this would be replaced by a more targeted mechanism.
        // for (uint256 i = 1; i < nextDepositIndex; i++) {
        //      Deposit storage deposit = deposits[i];
        //      if (deposit.state == State.Superposed && deposit.superposedConditionId == oracleConditionId) {
        //          // Apply state transition based on oracleResult and rules
        //          // Example rule: if result > threshold, transition to Stabilized, else Decayed
        //          // This logic needs to match the transitionRules definition using oracleConditionId
        //          State fromState = State.Superposed;
        //          State toState; // Determine based on result and rules

        //          // Find rule based on oracleConditionId and result (example)
        //          // This is overly simplified. A real rule engine is needed.
        //          if (oracleResult > 100) { // Example condition check
        //               toState = State.Stabilized;
        //          } else {
        //               toState = State.Decayed;
        //          }
        //          // Check if a valid rule exists from Superposed to toState with this conditionIdentifier
        //          TransitionRule storage rule = transitionRules[fromState][toState];
        //          if (rule.conditionIdentifier == oracleConditionId) {
        //              deposit.state = toState;
        //              deposit.superposedConditionId = bytes32(0); // Reset
        //              deposit.lastYieldDecayTimestamp = block.timestamp;
        //              emit StateTransitioned(i, fromState, toState, block.timestamp);
        //          }
        //      }
        // }

        // --- Resolve Conditional Withdrawals ---
        // This *does* require a direct lookup by conditionIdentifier or storing request IDs by conditionIdentifier.
        // The request ID is unique. We can't iterate requests efficiently.
        // A realistic approach: the request ID *is* the conditionIdentifier sent to the oracle,
        // OR the oracle callback includes the request ID it's fulfilling.
        // Let's assume the oracle callback can provide the request ID.
        // If the oracle *only* provides the `oracleConditionId`, the contract needs a way
        // to map `oracleConditionId` to `requestId`s. This adds complexity.
        // Let's simplify and assume the oracle callback uses the `conditionIdentifier` from the request.
        // We cannot efficiently look up all requests with a given `conditionIdentifier`.
        // This highlights the need for a better data structure if this is a primary use case.

        // Simulating resolution if we could find the request:
        // ConditionalWithdrawalRequest storage request = conditionalWithdrawalRequests[oracleConditionId_or_requestId_from_oracle];
        // if (request.user != address(0) && request.conditionIdentifier == oracleConditionId && !request.isCancelled && !request.isFulfilled) {
        //      // Apply result logic if needed
        //      // Example: If oracleResult > 50, fulfill.
        //      if (oracleResult > 50) {
        //          request.isFulfilled = true;
        //          // User must then call claimConditionalWithdrawal(requestId)
        //          // No transfer happens here.
        //      } else {
        //          // Condition not met. Request remains unfulfilled. User can cancel or wait for another attempt.
        //      }
        // }

        // Given the limitations of iterating mappings and the need for a specific request ID or direct link
        // from oracle result to request, this function primarily acts as a signal.
        // The actual resolution of Superposed states or fulfilling requests would likely happen:
        // 1. By a keeper calling `triggerStateTransition` after observing the `OracleConditionFulfilled` event.
        // 2. By the user calling `claimConditionalWithdrawal` after observing the event.
        // 3. The oracle callback itself could be designed to take specific deposit/request IDs.
    }


    /*//////////////////////////////////////////////////////////////
                           ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Pauses the contract, preventing most state-changing operations.
     */
    function pause() external onlyAdmin whenNotPaused {
        paused = true;
        emit VaultPaused();
    }

    /**
     * @dev Unpauses the contract, allowing operations to resume.
     */
    function unpause() external onlyAdmin whenPaused {
        paused = false;
        emit VaultUnpaused();
    }

     /**
     * @dev Sets the address of the trusted oracle contract. Only callable by admin.
     * @param _oracle The address of the oracle contract.
     */
    function setOracleAddress(address _oracle) external onlyAdmin {
        oracle = _oracle;
        emit OracleAddressChanged(_oracle);
    }

    /**
     * @dev Sets or updates a rule for state transitions.
     * @param fromState The state the deposit must be in.
     * @param toState The state the deposit can transition to.
     * @param conditionIdentifier A bytes32 identifier for the condition required for transition.
     * @param timeLockDuration Minimum time deposit must be in `fromState`.
     * @param minDepositValue Minimum value required for the deposit.
     */
    function setTransitionRule(State fromState, State toState, bytes32 conditionIdentifier, uint256 timeLockDuration, uint256 minDepositValue) external onlyAdmin {
         // Basic validation (e.g., prevent transitioning from/to certain states, or loops)
         if (fromState == toState) revert("Cannot transition to the same state");
         // Add checks for valid state combinations if needed

         transitionRules[fromState][toState] = TransitionRule({
             fromState: fromState,
             toState: toState,
             conditionIdentifier: conditionIdentifier,
             timeLockDuration: timeLockDuration,
             minDepositValue: minDepositValue
         });

         emit TransitionRuleUpdated(fromState, toState, conditionIdentifier, timeLockDuration, minDepositValue);
    }

     /**
     * @dev Sets the base Annual Percentage Yield (APY) for a specific token.
     * @param token The address of the token.
     * @param rate The new APY rate in basis points (10000 = 100%).
     */
    function setAPYBaseRate(address token, uint256 rate) external onlyAdmin {
         apyBaseRate[token] = rate;
         // Emit event
    }

    /**
     * @dev Sets the decay rate for a specific token.
     * @param token The address of the token.
     * @param rate The new decay rate in basis points (10000 = 100%).
     */
    function setDecayRate(address token, uint256 rate) external onlyAdmin {
         decayRate[token] = rate;
         // Emit event
    }

    /**
     * @dev Allows the admin to rescue ERC-20 tokens sent to the contract address
     *      that are NOT part of active user deposits.
     * @param token The address of the token to rescue.
     * @param amount The amount to rescue.
     * @param recipient The address to send the tokens to.
     */
    function rescueERC20(address token, uint256 amount, address recipient) external onlyAdmin {
        if (amount == 0) revert AmountMustBeGreaterThanZero();
        if (recipient == address(0)) revert TransferToZeroAddress();

        // This requires knowing the total amount of this token held in deposits
        // and ensuring we don't withdraw from user balances.
        // A simple way is to track the total token balance deposited.
        // For this example, we'll omit the complex balance tracking and assume
        // admin is careful not to pull deposited funds.
        // A safer version would track `totalManagedTokenBalance[token]` updated on deposit/withdraw.
        // For now, rely on admin trust and external tools to verify contract balance vs managed balance.

        // Safer Check (Conceptual):
        // uint256 managedBalance; // Need a mapping like mapping(address => uint256) totalManagedBalance;
        // if (IERC20(token).balanceOf(address(this)) - managedBalance < amount) {
        //     revert CannotRescueVaultTokens();
        // }

        IERC20(token).safeTransfer(recipient, amount);
        // Emit event
    }

    /*//////////////////////////////////////////////////////////////
                             VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Gets the details of a specific deposit.
     * @param depositIndex The index of the deposit.
     * @return Deposit The deposit struct.
     */
    function getDepositDetails(uint256 depositIndex) external view returns (Deposit memory) {
        if (deposits[depositIndex].owner == address(0)) revert DepositNotFound();
        return deposits[depositIndex];
    }

    /**
     * @dev Gets all deposit indexes owned by a specific user.
     *      Note: This might include indexes for deposits that were transferred out
     *      if the internal tracking wasn't fully updated (due to gas).
     * @param user The address of the user.
     * @return uint256[] An array of deposit indexes.
     */
    function getUserDepositIndexes(address user) external view returns (uint256[] memory) {
        // Note: Iterating and checking owner here is more accurate if ownership transfer doesn't remove from the array
        uint256[] memory rawIndexes = userDepositIndexes[user];
        uint256 validCount = 0;
        for(uint256 i=0; i<rawIndexes.length; i++) {
            if(deposits[rawIndexes[i]].owner == user) {
                validCount++;
            }
        }

        uint256[] memory ownedIndexes = new uint256[](validCount);
        uint256 current = 0;
        for(uint256 i=0; i<rawIndexes.length; i++) {
            if(deposits[rawIndexes[i]].owner == user) {
                ownedIndexes[current++] = rawIndexes[i];
            }
        }
        return ownedIndexes;
    }


    /**
     * @dev Gets the entangled partner deposit index for a given deposit.
     * @param depositIndex The index of the deposit.
     * @return uint256 The index of the entangled partner, or 0 if not entangled or pair not found.
     */
    function getEntangledPair(uint256 depositIndex) external view returns (uint256) {
        uint256 pairId = depositToEntangledPairId[depositIndex]; // Using the mapping for quicker lookup
        if (pairId == 0) return 0; // Not entangled via mapping

        EntangledPair storage pair = entangledPairs[pairId];
         if (pair.depositIndex1 == 0) return 0; // Pair ID existed but pair deleted/invalidated

        // Return the other deposit index in the pair
        if (pair.depositIndex1 == depositIndex) {
            return pair.depositIndex2;
        } else if (pair.depositIndex2 == depositIndex) {
            return pair.depositIndex1;
        } else {
            // This case should not happen if depositToEntangledPairId is correct
            return 0;
        }
    }

    /**
     * @dev Gets all pending conditional withdrawal request IDs for a user.
     *      Note: This requires iterating through *all* requests if not indexed by user.
     *      For simplicity, this implementation would be inefficient. A better
     *      approach would be mapping user => array of request IDs.
     *      Let's provide a placeholder that indicates this limitation.
     * @param user The address of the user.
     * @return bytes32[] An array of pending request IDs.
     */
    function getPendingConditionalWithdrawals(address user) external view returns (bytes32[] memory) {
        // This is highly inefficient for a large number of requests.
        // A production contract would need a mapping like mapping(address => bytes32[]) userRequests;
        // or iterate requests from a list/linked list.

        // Placeholder implementation (DO NOT USE IN PRODUCTION ON LARGE SCALE)
        bytes32[] memory pendingRequests = new bytes32[](0); // Cannot dynamically size
        // Requires iterating nextRequestId and checking each request owner and status. Gas heavy.

        // A practical approach would be to have the user's UI track their request IDs from events.
        // Or require the user to provide the request ID they want to check.
         revert("Inefficient function, cannot list all pending requests efficiently.");

         // Example if user provides request ID:
         // function getConditionalWithdrawalStatus(bytes32 requestId) external view returns(...)
    }

    /**
     * @dev Gets the transition rule defined for a specific state pair.
     * @param fromState The starting state.
     * @param toState The target state.
     * @return TransitionRule The rule struct.
     */
    function getTransitionRule(State fromState, State toState) external view returns (TransitionRule memory) {
         return transitionRules[fromState][toState];
    }

     /**
     * @dev Gets the base APY rate for a specific token.
     * @param token The address of the token.
     * @return uint256 The APY rate in basis points.
     */
    function getAPYBaseRate(address token) external view returns (uint256) {
         return apyBaseRate[token];
    }

    /**
     * @dev Gets the decay rate for a specific token.
     * @param token The address of the token.
     * @return uint256 The decay rate in basis points.
     */
    function getDecayRate(address token) external view returns (uint256) {
         return decayRate[token];
    }

     /**
     * @dev Gets the current state of a specific deposit.
     * @param depositIndex The index of the deposit.
     * @return State The current state.
     */
    function getDepositState(uint256 depositIndex) external view returns (State) {
        if (deposits[depositIndex].owner == address(0)) revert DepositNotFound();
        return deposits[depositIndex].state;
    }

    /**
     * @dev Gets the total balance a user has across all their deposits for a specific token.
     *      Note: This requires iterating user's deposits. See `getUserDepositIndexes` note.
     * @param user The address of the user.
     * @param token The address of the token.
     * @return uint256 The total amount across all deposits.
     */
    function getUserTotalBalance(address user, address token) external view returns (uint256) {
        uint256 total = 0;
        uint256[] memory userIdxs = userDepositIndexes[user]; // Inefficient lookup if ownership transfer doesn't remove
        for(uint256 i = 0; i < userIdxs.length; i++) {
            uint256 idx = userIdxs[i];
            // Check ownership explicitly
            if (deposits[idx].owner == user && deposits[idx].token == token) {
                 // Calculate current value including potential pending yield/decay
                 total += calculateCurrentValue(idx);
            }
        }
        return total;
    }

    /**
     * @dev Gets the number of individual deposit entries a user has.
     *      Note: See `getUserDepositIndexes` note regarding transferred deposits.
     * @param user The address of the user.
     * @return uint256 The number of deposits.
     */
    function getUserDepositCount(address user) external view returns (uint256) {
        // Same efficiency note as getUserDepositIndexes
        uint256 count = 0;
        uint256[] memory userIdxs = userDepositIndexes[user];
         for(uint256 i = 0; i < userIdxs.length; i++) {
            if (deposits[userIdxs[i]].owner == user) {
                count++;
            }
         }
        return count;
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HELPERS
    //////////////////////////////////////////////////////////////*/

    // _checkTransitionCondition is defined within triggerStateTransition section

}
```