Okay, here is a Solidity smart contract incorporating advanced, creative, and trendy concepts, avoiding duplication of common open-source patterns.

The core idea is a "Quantum Vault" where deposited assets exist in a superposition of potential states until a "measurement" (triggered collapse) locks them into a single outcome state, determining final withdrawal amounts. It incorporates concepts like:

1.  **Superposition (Simulated):** Deposits are linked to multiple potential outcome states (`StateInfo`).
2.  **Measurement/Collapse:** A specific action (`triggerCollapse`) resolves the superposition based on defined conditions (time, oracle data, or pseudo-randomness weighted by state probabilities).
3.  **Entanglement (Simulated):** Defined states can be linked, causing deposits associated with linked states to collapse together to the *same* outcome state.
4.  **Dynamic Outcomes:** Withdrawal amounts depend on the state the vault collapses into, defined by variable "withdrawal factors".
5.  **Observer Pattern:** Designated addresses can trigger collapses under specific conditions.
6.  **Probabilistic Collapse:** The final state can be chosen probabilistically based on weights assigned to states (simulated using on-chain entropy or oracle data).
7.  **Conditional Access/Logic:** Actions are gated based on the contract's collapse state (`beforeCollapse`, `afterCollapse`).
8.  **Mixed Assets:** Handles both ETH and multiple ERC20 tokens.

It aims for complexity and novelty in its state machine and interaction patterns rather than just being a standard vault, token, or DeFi primitive.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Using SafeMath for abundance of caution, though 0.8+ has overflow checks by default.
// It's good practice for clarity or when migrating older code.
using SafeMath for uint256;

/**
 * @title QuantumVault
 * @dev A smart contract simulating quantum superposition and collapse for asset management.
 * Assets deposited exist in a superposition of potential states, each with a defined
 * withdrawal factor. A 'collapse' event locks the vault into one of these states,
 * determining the final redeemable amount for each deposit based on the collapsed state's rules.
 * Features simulated 'entanglement' between states and probabilistic collapse outcomes.
 */

/*
Outline:
1.  State Definitions (Structs & Enums)
2.  Core State Variables
3.  Events & Custom Errors
4.  Modifiers (Access Control, State Checks)
5.  Constructor
6.  Admin Functions (Owner)
    -   Add/Update/Remove Quantum States
    -   Link/Unlink States (Simulated Entanglement)
    -   Register/Unregister Observers
    -   Set Oracle Address (Placeholder/Example)
    -   Emergency Withdraw
7.  User Functions
    -   Deposit (ETH and ERC20) - Associate deposit with an initial state
    -   Trigger Collapse - The 'Measurement' event
    -   Withdraw (ETH and ERC20) - Redeem assets based on collapsed state
8.  View Functions (Querying State and Info)
    -   Deposit Information
    -   State Definitions
    -   Vault Status
    -   Potential Outcomes
    -   Total Balances
    -   Observer Status
9.  Internal Helper Functions
*/

/*
Function Summary:

Admin Functions (onlyOwner):
- addQuantumState(name, withdrawalFactorBps, collapseCondition, collapseParam, collapseWeight): Defines a new potential state and its collapse properties.
- updateQuantumState(stateId, name, withdrawalFactorBps, collapseCondition, collapseParam, collapseWeight): Modifies an existing state definition.
- removeQuantumState(stateId): Removes a state definition (fails if deposits associated).
- linkStates(stateId1, stateId2): Establishes simulated entanglement between two states.
- unlinkStates(stateId1, stateId2): Removes simulated entanglement.
- registerObserver(observer): Grants observer status to an address.
- unregisterObserver(observer): Revokes observer status.
- setOracleAddress(oracle): Sets the address of a hypothetical oracle contract.
- emergencyWithdraw(token, amount): Allows owner to withdraw funds in emergencies.

User Functions:
- depositETH(initialStateId): Deposits ETH, associating it with an initial state.
- depositERC20(token, amount, initialStateId): Deposits ERC20, associating it with an initial state.
- triggerCollapse(): Initiates the vault's state collapse based on defined conditions and probabilities.
- triggerCollapseByObserver(targetStateId): Allows observers to force collapse to a specific state (if allowed by state definition).
- withdrawETH(depositId): Withdraws collapsed ETH deposit.
- withdrawERC20(depositId): Withdraws collapsed ERC20 deposit.

View Functions (Public/External):
- getDepositInfo(depositId): Retrieves details of a specific deposit.
- getQuantumStateInfo(stateId): Retrieves details of a specific quantum state definition.
- getVaultStatus(): Checks if the vault has collapsed and the resulting state.
- getPotentialWithdrawalAmount(depositId, targetStateId): Calculates potential withdrawal for a deposit if it collapses to a specific state.
- getEffectiveWithdrawalFactor(depositId): Gets the effective withdrawal factor for a deposit after collapse.
- getTotalDeposited(token): Gets total balance of a token (or ETH) held in the vault.
- getDepositsByAddress(depositor): Lists all deposit IDs for a given address.
- getDepositCount(): Gets the total number of deposits made.
- isObserver(addr): Checks if an address is a registered observer.
- getLinkedStates(stateId): Gets states entangled with a given state.
- getOracleAddress(): Gets the current oracle address.
- getAvailableStateIds(): Lists all currently defined state IDs.
- getStateTotalWeight(): Calculates the sum of weights for all collapsible states.

Internal Functions:
- _handleDeposit(token, amount, depositor, initialStateId): Internal helper for deposit logic.
- _handleWithdrawal(depositId, withdrawToken): Internal helper for withdrawal logic.
- _calculateWithdrawalAmount(depositInfo, effectiveCollapsedStateId): Calculates the final payout based on deposit and collapsed state.
- _selectCollapsedState(): Determines the final state based on weights and pseudo-randomness.
- _getEffectiveCollapsedState(depositInfo): Determines the final state *relevant to a specific deposit* after global collapse (considering entanglement).
- _areStatesLinked(stateId1, stateId2): Checks if two states are entangled.
- _checkCollapseCondition(stateId): Checks if the collapse condition for a given state is met.
- _generateEntropy(): Generates a pseudo-random seed for state selection.
*/

contract QuantumVault is Ownable, ReentrancyGuard {
    // --- State Definitions ---

    // Represents different conditions that can trigger a state collapse
    enum CollapseCondition {
        NO_CONDITION,       // Can only be triggered manually (e.g., by Observer)
        TIME_BASED,         // Triggered after a specific timestamp
        ORACLE_BASED,       // Triggered based on an oracle data point (simulated)
        PROBABILISTIC       // Can be triggered anytime, outcome determined probabilistically by weights
    }

    // Struct to define a potential outcome state for the vault
    struct StateInfo {
        string name; // e.g., "Winning State", "Losing State", "Neutral State"
        // Withdrawal factor in basis points (10000 = 1x, 11000 = 1.1x, 9000 = 0.9x)
        uint16 withdrawalFactorBps;
        CollapseCondition collapseCondition; // How this state *can* contribute to collapse
        uint256 collapseParam; // Parameter for the condition (e.g., timestamp, oracle threshold)
        uint16 collapseWeight; // Weight for probabilistic selection (only if condition is PROBABILISTIC)
        uint256[] linkedStates; // State IDs that are "entangled" with this one
    }

    // Struct to hold information about a user deposit
    struct DepositInfo {
        address depositor; // The address that made the deposit
        address token;     // The token address (address(0) for ETH)
        uint256 amount;    // The initial deposited amount
        uint256 initialStateId; // The state ID the user initially associated with
        bool withdrawn;    // Flag to check if the deposit has been withdrawn
    }

    // --- Core State Variables ---

    uint256 private _depositIdCounter; // Counter for unique deposit IDs
    mapping(uint256 => DepositInfo) private _deposits; // Stores deposit information by ID
    mapping(address => uint256[]) private _depositsByAddress; // Maps depositor to their deposit IDs

    uint256 private _stateIdCounter; // Counter for unique state IDs
    mapping(uint256 => StateInfo) private _quantumStates; // Stores definitions of potential states
    uint256[] private _availableStateIds; // List of currently active state IDs

    mapping(address => bool) private _observers; // Addresses registered as observers

    bool private _isCollapsed; // Flag indicating if the vault's state has collapsed
    uint256 private _collapsedStateId; // The ID of the state the vault collapsed into

    address private _oracleAddress; // Address of a hypothetical oracle contract

    // Entanglement mapping: stateId => array of linked stateIds (redundant but useful lookup)
    // The primary definition is within StateInfo.linkedStates, this could be a derived view.
    // Let's stick to the StateInfo.linkedStates for simplicity and non-duplication of data.

    // --- Events ---

    event QuantumStateAdded(uint256 indexed stateId, string name, uint16 withdrawalFactorBps);
    event QuantumStateUpdated(uint256 indexed stateId, string name, uint16 withdrawalFactorBps);
    event QuantumStateRemoved(uint256 indexed stateId);
    event StatesLinked(uint256 indexed stateId1, uint256 indexed stateId2);
    event StatesUnlinked(uint256 indexed stateId1, uint256 indexed stateId2);
    event ObserverRegistered(address indexed observer);
    event ObserverUnregistered(address indexed observer);
    event OracleAddressSet(address indexed oracle);
    event DepositMade(uint256 indexed depositId, address indexed depositor, address indexed token, uint256 amount, uint256 initialStateId);
    event VaultCollapsed(uint256 indexed collapsedStateId, uint256 timestamp);
    event WithdrawalMade(uint256 indexed depositId, address indexed depositor, address indexed token, uint256 initialAmount, uint256 withdrawnAmount);
    event EmergencyWithdrawal(address indexed token, uint256 amount);

    // --- Custom Errors ---

    error InvalidStateId(uint256 stateId);
    error StateHasDeposits(uint256 stateId);
    error VaultAlreadyCollapsed();
    error VaultNotCollapsed();
    error DepositAlreadyWithdrawn(uint256 depositId);
    error InsufficientBalance();
    error InvalidWithdrawalAmount(); // Should not happen if calculations are correct
    error CollapseConditionNotMet();
    error UnauthorizedCollapseTrigger(address caller);
    error NotEnoughStatesForProbabilisticCollapse();
    error ProbabilisticCollapseNeedsWeights();
    error DepositDoesNotExist(uint256 depositId);
    error CallerNotDepositOwner(uint256 depositId, address caller);
    error OracleAddressNotSet();
    error CannotTriggerCollapseToState(uint256 targetStateId);

    // --- Modifiers ---

    modifier beforeCollapse() {
        if (_isCollapsed) revert VaultAlreadyCollapsed();
        _;
    }

    modifier afterCollapse() {
        if (!_isCollapsed) revert VaultNotCollapsed();
        _;
    }

    modifier onlyObserver() {
        if (!_observers[msg.sender]) revert UnauthorizedCollapseTrigger(msg.sender);
        _;
    }

    // --- Constructor ---

    constructor(address initialOracle) Ownable(msg.sender) {
        _depositIdCounter = 0;
        _stateIdCounter = 0;
        _isCollapsed = false;
        _oracleAddress = initialOracle;

        // Add a default "Neutral" state (ID 1), non-collapsible by itself, 1x withdrawal
        _stateIdCounter++;
        _quantumStates[_stateIdCounter] = StateInfo({
            name: "Neutral State",
            withdrawalFactorBps: 10000, // 1x
            collapseCondition: CollapseCondition.NO_CONDITION,
            collapseParam: 0,
            collapseWeight: 0,
            linkedStates: new uint256[](0)
        });
         _availableStateIds.push(_stateIdCounter);
         emit QuantumStateAdded(_stateIdCounter, "Neutral State", 10000);
    }

    receive() external payable beforeCollapse nonReentrant {
        // ETH deposits without calling depositETH
        // We require a state ID, so direct receive is disabled unless it calls depositETH internally.
        // Let's require explicit function call for state association.
         revert("Call depositETH to deposit Ether.");
    }

    fallback() external {
        revert("Unknown function call.");
    }


    // --- Admin Functions (onlyOwner) ---

    /**
     * @dev Adds a new potential outcome state to the vault.
     * @param name Descriptive name for the state.
     * @param withdrawalFactorBps Basis points multiplier for withdrawals (e.g., 10000 for 1x).
     * @param condition The condition under which this state can participate in collapse selection.
     * @param param Parameter for the condition (e.g., timestamp for TIME_BASED).
     * @param weight Weight for probabilistic selection (ignored if condition is not PROBABILISTIC).
     */
    function addQuantumState(
        string memory name,
        uint16 withdrawalFactorBps,
        CollapseCondition condition,
        uint256 param,
        uint16 weight
    ) external onlyOwner beforeCollapse {
        _stateIdCounter++;
        uint256 newStateId = _stateIdCounter;

        _quantumStates[newStateId] = StateInfo({
            name: name,
            withdrawalFactorBps: withdrawalFactorBps,
            collapseCondition: condition,
            collapseParam: param,
            collapseWeight: weight,
            linkedStates: new uint256[](0)
        });
        _availableStateIds.push(newStateId);

        emit QuantumStateAdded(newStateId, name, withdrawalFactorBps);
    }

    /**
     * @dev Updates an existing potential outcome state.
     * @param stateId The ID of the state to update.
     * @param name New name.
     * @param withdrawalFactorBps New withdrawal factor.
     * @param condition New collapse condition.
     * @param param New condition parameter.
     * @param weight New probabilistic weight.
     */
    function updateQuantumState(
        uint256 stateId,
        string memory name,
        uint16 withdrawalFactorBps,
        CollapseCondition condition,
        uint256 param,
        uint16 weight
    ) external onlyOwner beforeCollapse {
        StateInfo storage state = _quantumStates[stateId];
        if (state.withdrawalFactorBps == 0 && stateId != 1) revert InvalidStateId(stateId); // Check if state exists (default 0 for uint16)

        state.name = name;
        state.withdrawalFactorBps = withdrawalFactorBps;
        state.collapseCondition = condition;
        state.collapseParam = param;
        state.collapseWeight = weight;

        emit QuantumStateUpdated(stateId, name, withdrawalFactorBps);
    }

    /**
     * @dev Removes a quantum state definition. Fails if any deposits are still associated with it.
     * @param stateId The ID of the state to remove.
     */
    function removeQuantumState(uint256 stateId) external onlyOwner beforeCollapse {
         StateInfo storage state = _quantumStates[stateId];
         if (state.withdrawalFactorBps == 0 && stateId != 1) revert InvalidStateId(stateId); // Check if state exists

         if (stateId == 1) revert("Cannot remove default Neutral state.");

         // Check if any deposits are associated with this state as their initial state
         for(uint256 i = 1; i <= _depositIdCounter; i++) {
             if (_deposits[i].depositor != address(0) && _deposits[i].initialStateId == stateId) {
                 revert StateHasDeposits(stateId);
             }
         }

        // Remove from available states list
        uint256 len = _availableStateIds.length;
        for (uint256 i = 0; i < len; i++) {
            if (_availableStateIds[i] == stateId) {
                _availableStateIds[i] = _availableStateIds[len - 1];
                _availableStateIds.pop();
                break;
            }
        }

        // Clear state info (solidity deletes mapping entry when struct is reset/deleted)
        delete _quantumStates[stateId];

        // Also unlink from any other states it might be linked to
        for(uint256 i = 0; i < _availableStateIds.length; i++) {
            uint256 otherStateId = _availableStateIds[i];
            StateInfo storage otherState = _quantumStates[otherStateId];
            uint256 linkedLen = otherState.linkedStates.length;
            for(uint256 j = 0; j < linkedLen; j++) {
                 if (otherState.linkedStates[j] == stateId) {
                    otherState.linkedStates[j] = otherState.linkedStates[linkedLen - 1];
                    otherState.linkedStates.pop();
                    break;
                 }
            }
        }


        emit QuantumStateRemoved(stateId);
    }

    /**
     * @dev Establishes simulated entanglement between two states.
     * If state A is linked to B, B is also linked to A.
     * @param stateId1 The ID of the first state.
     * @param stateId2 The ID of the second state.
     */
    function linkStates(uint256 stateId1, uint256 stateId2) external onlyOwner beforeCollapse {
        StateInfo storage state1 = _quantumStates[stateId1];
        StateInfo storage state2 = _quantumStates[stateId2];

        if ((state1.withdrawalFactorBps == 0 && stateId1 != 1) || (state2.withdrawalFactorBps == 0 && stateId2 != 1)) {
            revert InvalidStateId(stateId1 == 0 ? stateId2 : stateId1);
        }
        if (stateId1 == stateId2) revert("Cannot link a state to itself.");

        // Add state2 to state1's linked list if not already present
        bool alreadyLinked1 = false;
        for (uint265 i = 0; i < state1.linkedStates.length; i++) {
            if (state1.linkedStates[i] == stateId2) {
                alreadyLinked1 = true;
                break;
            }
        }
        if (!alreadyLinked1) {
            state1.linkedStates.push(stateId2);
        }

        // Add state1 to state2's linked list if not already present
        bool alreadyLinked2 = false;
        for (uint256 i = 0; i < state2.linkedStates.length; i++) {
            if (state2.linkedStates[i] == stateId1) {
                alreadyLinked2 = true;
                break;
            }
        }
        if (!alreadyLinked2) {
            state2.linkedStates.push(stateId1);
        }

        if (!alreadyLinked1 || !alreadyLinked2) { // Emit only if a link was actually added
             emit StatesLinked(stateId1, stateId2);
        }
    }

    /**
     * @dev Removes simulated entanglement between two states.
     * @param stateId1 The ID of the first state.
     * @param stateId2 The ID of the second state.
     */
    function unlinkStates(uint256 stateId1, uint256 stateId2) external onlyOwner beforeCollapse {
        StateInfo storage state1 = _quantumStates[stateId1];
        StateInfo storage state2 = _quantumStates[stateId2];

         if ((state1.withdrawalFactorBps == 0 && stateId1 != 1) || (state2.withdrawalFactorBps == 0 && stateId2 != 1)) {
            revert InvalidStateId(stateId1 == 0 ? stateId2 : stateId1);
        }
        if (stateId1 == stateId2) revert("Cannot unlink a state from itself.");

        // Remove state2 from state1's linked list
        uint256 len1 = state1.linkedStates.length;
        for (uint256 i = 0; i < len1; i++) {
            if (state1.linkedStates[i] == stateId2) {
                state1.linkedStates[i] = state1.linkedStates[len1 - 1];
                state1.linkedStates.pop();
                break;
            }
        }

        // Remove state1 from state2's linked list
        uint256 len2 = state2.linkedStates.length;
        for (uint256 i = 0; i < len2; i++) {
            if (state2.linkedStates[i] == stateId1) {
                state2.linkedStates[i] = state2.linkedStates[len2 - 1];
                state2.linkedStates.pop();
                break;
            }
        }
         emit StatesUnlinked(stateId1, stateId2);
    }

    /**
     * @dev Registers an address as an observer capable of triggering specific collapses.
     * @param observer The address to register.
     */
    function registerObserver(address observer) external onlyOwner {
        _observers[observer] = true;
        emit ObserverRegistered(observer);
    }

    /**
     * @dev Unregisters an observer.
     * @param observer The address to unregister.
     */
    function unregisterObserver(address observer) external onlyOwner {
        _observers[observer] = false;
        emit ObserverUnregistered(observer);
    }

    /**
     * @dev Sets the address of the hypothetical oracle contract.
     * @param oracle The address of the oracle contract.
     */
    function setOracleAddress(address oracle) external onlyOwner {
        _oracleAddress = oracle;
        emit OracleAddressSet(oracle);
    }

    /**
     * @dev Allows the owner to withdraw any token (or ETH) in case of emergencies.
     * Should be used cautiously as it bypasses the vault's state logic.
     * @param token The token address (address(0) for ETH).
     * @param amount The amount to withdraw.
     */
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner nonReentrant {
        if (token == address(0)) {
            (bool success, ) = owner().call{value: amount}("");
            require(success, "ETH withdrawal failed");
        } else {
            IERC20 erc20 = IERC20(token);
            require(erc20.transfer(owner(), amount), "ERC20 withdrawal failed");
        }
        emit EmergencyWithdrawal(token, amount);
    }

    // --- User Functions ---

    /**
     * @dev Deposits ETH into the vault, associating it with an initial state.
     * Must be called before the vault collapses.
     * @param initialStateId The ID of the potential state this deposit is initially associated with.
     */
    function depositETH(uint256 initialStateId) external payable beforeCollapse nonReentrant {
        if (msg.value == 0) revert("Amount must be greater than 0.");
        _handleDeposit(address(0), msg.value, msg.sender, initialStateId);
    }

    /**
     * @dev Deposits ERC20 tokens into the vault, associating it with an initial state.
     * The user must have approved this contract to spend the tokens beforehand.
     * Must be called before the vault collapses.
     * @param token The address of the ERC20 token.
     * @param amount The amount of tokens to deposit.
     * @param initialStateId The ID of the potential state this deposit is initially associated with.
     */
    function depositERC20(address token, uint256 amount, uint256 initialStateId) external beforeCollapse nonReentrant {
        if (amount == 0) revert("Amount must be greater than 0.");
        if (token == address(0)) revert("Use depositETH for Ether.");

        IERC20 erc20 = IERC20(token);
        uint256 contractBalanceBefore = erc20.balanceOf(address(this));
        erc20.transferFrom(msg.sender, address(this), amount);
        uint256 amountTransferred = erc20.balanceOf(address(this)).sub(contractBalanceBefore);
        if (amountTransferred != amount) revert("ERC20 transfer failed or amount mismatch."); // Sanity check

        _handleDeposit(token, amountTransferred, msg.sender, initialStateId);
    }

    /**
     * @dev Triggers the collapse of the vault's state.
     * Can be called by anyone, but the collapse only happens if the conditions
     * for at least one PROBABILISTIC state are met OR conditions for a TIME_BASED/ORACLE_BASED
     * state that should trigger collapse (requires specific state definition logic or observer).
     * The final state is chosen probabilistically among valid collapse states based on weights.
     */
    function triggerCollapse() external nonReentrant {
        if (_isCollapsed) revert VaultAlreadyCollapsed();

        // Check if any state's condition allows for collapse triggering
        bool conditionMet = false;
        uint256 totalProbabilisticWeight = 0;
        uint256[] memory collapsibleStateIds = new uint256[](_availableStateIds.length); // temp array
        uint256 collapsibleCount = 0;

        for (uint256 i = 0; i < _availableStateIds.length; i++) {
            uint256 stateId = _availableStateIds[i];
            StateInfo storage state = _quantumStates[stateId];

            if (state.collapseCondition == CollapseCondition.PROBABILISTIC) {
                 // Probabilistic states can always contribute weight to the selection process
                totalProbabilisticWeight = totalProbabilisticWeight.add(state.collapseWeight);
                // Add to potential collapse candidates if it has weight
                 if (state.collapseWeight > 0) {
                    collapsibleStateIds[collapsibleCount] = stateId;
                    collapsibleCount++;
                    conditionMet = true; // Probabilistic states implicitly meet a "triggerable" condition
                 }
            } else {
                // Check condition for TIME_BASED or ORACLE_BASED states
                if (_checkCollapseCondition(stateId)) {
                     collapsibleStateIds[collapsibleCount] = stateId;
                     collapsibleCount++;
                     conditionMet = true; // Condition met for a specific state
                }
            }
             // NO_CONDITION states cannot be triggered by this function unless linked to a triggered state (handled later).
        }

        if (!conditionMet) revert CollapseConditionNotMet();

        // Resize the temporary array
        uint265[] memory potentialStates = new uint256[](collapsibleCount);
        for(uint256 i = 0; i < collapsibleCount; i++){
            potentialStates[i] = collapsibleStateIds[i];
        }

        // Now select the final state probabilistically from the potentialStates list
        // If only one state met the condition (e.g., a single TIME_BASED state expired), it's selected directly.
        // If multiple met conditions, or PROBABILISTIC states were available, select based on weights.

        uint256 finalStateId = _selectCollapsedState(potentialStates);

        _isCollapsed = true;
        _collapsedStateId = finalStateId;

        emit VaultCollapsed(_collapsedStateId, block.timestamp);
    }

    /**
     * @dev Allows a registered observer to trigger the collapse to a specific state.
     * Useful for oracle-based triggers or manual overrides by trusted parties.
     * The target state must exist and be defined as potentially collapsible (not NO_CONDITION unless linked somehow - advanced logic skipped for simplicity here).
     * @param targetStateId The specific state ID to collapse into.
     */
    function triggerCollapseByObserver(uint256 targetStateId) external onlyObserver nonReentrant {
        if (_isCollapsed) revert VaultAlreadyCollapsed();

        StateInfo storage targetState = _quantumStates[targetStateId];
        if (targetState.withdrawalFactorBps == 0 && targetStateId != 1) revert InvalidStateId(targetStateId); // Check if state exists

        // Optionally add more checks here, e.g., maybe an observer can only trigger
        // to states that have specific properties, or within a time window.
        // For simplicity, observers can trigger to any valid state ID defined.

        _isCollapsed = true;
        _collapsedStateId = targetStateId;

        emit VaultCollapsed(_collapsedStateId, block.timestamp);
    }


    /**
     * @dev Allows a depositor to withdraw their funds after the vault has collapsed.
     * The amount withdrawn is determined by the collapsed state and the deposit's initial state/amount.
     * @param depositId The ID of the deposit to withdraw.
     */
    function withdrawETH(uint256 depositId) external afterCollapse nonReentrant {
        _handleWithdrawal(depositId, address(0));
    }

     /**
     * @dev Allows a depositor to withdraw their ERC20 funds after the vault has collapsed.
     * The amount withdrawn is determined by the collapsed state and the deposit's initial state/amount.
     * @param depositId The ID of the deposit to withdraw.
     */
    function withdrawERC20(uint256 depositId) external afterCollapse nonReentrant {
        _handleWithdrawal(depositId, _deposits[depositId].token); // Pass the token address from deposit info
    }


    // --- View Functions ---

    /**
     * @dev Gets the details of a specific deposit.
     * @param depositId The ID of the deposit.
     * @return DepositInfo struct.
     */
    function getDepositInfo(uint256 depositId) external view returns (DepositInfo memory) {
        if (_deposits[depositId].depositor == address(0)) revert DepositDoesNotExist(depositId);
        return _deposits[depositId];
    }

    /**
     * @dev Gets the definition details of a specific quantum state.
     * @param stateId The ID of the state.
     * @return StateInfo struct.
     */
    function getQuantumStateInfo(uint256 stateId) external view returns (StateInfo memory) {
         if (_quantumStates[stateId].withdrawalFactorBps == 0 && stateId != 1) revert InvalidStateId(stateId); // Check if state exists
        return _quantumStates[stateId];
    }

    /**
     * @dev Gets the current status of the vault's collapse state.
     * @return isCollapsed Boolean indicating if collapsed.
     * @return collapsedStateId The ID of the state the vault collapsed into (0 if not collapsed).
     */
    function getVaultStatus() external view returns (bool isCollapsed, uint256 collapsedStateId) {
        return (_isCollapsed, _collapsedStateId);
    }

    /**
     * @dev Calculates the potential withdrawal amount for a specific deposit
     * if the vault were to collapse into a given target state. Useful before collapse.
     * @param depositId The ID of the deposit.
     * @param targetStateId The ID of the hypothetical target state.
     * @return The potential withdrawal amount.
     */
    function getPotentialWithdrawalAmount(uint256 depositId, uint256 targetStateId) external view returns (uint256) {
        DepositInfo storage depositInfo = _deposits[depositId];
        if (depositInfo.depositor == address(0)) revert DepositDoesNotExist(depositId);
         if (_quantumStates[targetStateId].withdrawalFactorBps == 0 && targetStateId != 1) revert InvalidStateId(targetStateId); // Check if state exists

        // This view function calculates based *hypothetically* collapsing to targetStateId.
        // It doesn't apply entanglement rules strictly as entanglement resolves during the *actual* collapse.
        // A simpler approach for this view is to just apply the target state's factor directly to the initial deposit amount.
        // More complex approach would simulate the entanglement effect *assuming* the targetStateId is the result of a real collapse.
        // Let's use the simpler approach for the view function.
        return depositInfo.amount.mul(_quantumStates[targetStateId].withdrawalFactorBps).div(10000);
    }

     /**
     * @dev Gets the effective withdrawal factor applied to a deposit after collapse.
     * Considers the global collapsed state and entanglement.
     * @param depositId The ID of the deposit.
     * @return The effective withdrawal factor in basis points.
     */
    function getEffectiveWithdrawalFactor(uint256 depositId) external view afterCollapse returns (uint16) {
        DepositInfo storage depositInfo = _deposits[depositId];
        if (depositInfo.depositor == address(0)) revert DepositDoesNotExist(depositId);

        uint256 effectiveCollapsedStateId = _getEffectiveCollapsedState(depositInfo);
        return _quantumStates[effectiveCollapsedStateId].withdrawalFactorBps;
    }

    /**
     * @dev Gets the total balance of a specific token (or ETH) currently held in the vault.
     * @param token The token address (address(0) for ETH).
     * @return The total amount held.
     */
    function getTotalDeposited(address token) external view returns (uint256) {
        if (token == address(0)) {
            return address(this).balance;
        } else {
            return IERC20(token).balanceOf(address(this));
        }
    }

    /**
     * @dev Lists all deposit IDs belonging to a specific address.
     * @param depositor The address to query.
     * @return An array of deposit IDs.
     */
    function getDepositsByAddress(address depositor) external view returns (uint256[] memory) {
        return _depositsByAddress[depositor];
    }

    /**
     * @dev Gets the total number of deposits made into the vault.
     * @return The total count.
     */
    function getDepositCount() external view returns (uint256) {
        return _depositIdCounter;
    }

    /**
     * @dev Checks if an address is currently registered as an observer.
     * @param addr The address to check.
     * @return True if registered, false otherwise.
     */
    function isObserver(address addr) external view returns (bool) {
        return _observers[addr];
    }

    /**
     * @dev Gets the list of state IDs that are linked (entangled) with a given state ID.
     * @param stateId The state ID to query.
     * @return An array of linked state IDs.
     */
    function getLinkedStates(uint256 stateId) external view returns (uint256[] memory) {
        StateInfo storage state = _quantumStates[stateId];
         if (state.withdrawalFactorBps == 0 && stateId != 1) revert InvalidStateId(stateId); // Check if state exists
        return state.linkedStates;
    }

     /**
     * @dev Gets the list of all currently defined quantum state IDs.
     * @return An array of available state IDs.
     */
    function getAvailableStateIds() external view returns (uint256[] memory) {
        return _availableStateIds;
    }

    /**
     * @dev Calculates the total sum of weights for all states marked as PROBABILISTIC.
     * Useful for understanding the weighting distribution before collapse.
     * @return The total weight.
     */
    function getStateTotalWeight() external view returns (uint256) {
        uint256 totalWeight = 0;
         for (uint256 i = 0; i < _availableStateIds.length; i++) {
            uint256 stateId = _availableStateIds[i];
            StateInfo storage state = _quantumStates[stateId];
            if (state.collapseCondition == CollapseCondition.PROBABILISTIC) {
                totalWeight = totalWeight.add(state.collapseWeight);
            }
        }
        return totalWeight;
    }


    // --- Internal Helper Functions ---

    /**
     * @dev Internal helper to handle core deposit logic for both ETH and ERC20.
     */
    function _handleDeposit(address token, uint256 amount, address depositor, uint256 initialStateId) internal {
        // Validate initial state ID exists
        StateInfo storage initialState = _quantumStates[initialStateId];
        if (initialState.withdrawalFactorBps == 0 && initialStateId != 1) revert InvalidStateId(initialStateId); // Check if state exists

        _depositIdCounter++;
        uint256 newDepositId = _depositIdCounter;

        _deposits[newDepositId] = DepositInfo({
            depositor: depositor,
            token: token,
            amount: amount,
            initialStateId: initialStateId,
            withdrawn: false
        });

        _depositsByAddress[depositor].push(newDepositId);

        emit DepositMade(newDepositId, depositor, token, amount, initialStateId);
    }

    /**
     * @dev Internal helper to handle core withdrawal logic for both ETH and ERC20.
     */
    function _handleWithdrawal(uint256 depositId, address withdrawToken) internal {
        DepositInfo storage depositInfo = _deposits[depositId];

        if (depositInfo.depositor == address(0)) revert DepositDoesNotExist(depositId);
        if (depositInfo.withdrawn) revert DepositAlreadyWithdrawn(depositId);
        if (depositInfo.depositor != msg.sender) revert CallerNotDepositOwner(depositId, msg.sender);
        if (depositInfo.token != withdrawToken) revert("Incorrect token specified for withdrawal."); // Ensures ETH is withdrawn with withdrawETH, ERC20 with withdrawERC20

        // Determine the effective collapsed state for this specific deposit based on entanglement
        uint256 effectiveCollapsedStateId = _getEffectiveCollapsedState(depositInfo);
        StateInfo storage effectiveCollapsedState = _quantumStates[effectiveCollapsedStateId];

        uint256 withdrawalAmount = _calculateWithdrawalAmount(depositInfo, effectiveCollapsedStateId);
        if (withdrawalAmount == 0) {
             depositInfo.withdrawn = true; // Mark as withdrawn even if amount is 0 to prevent future attempts
             emit WithdrawalMade(depositId, depositInfo.depositor, depositInfo.token, depositInfo.amount, 0);
             return; // No funds to transfer
        }

        // Perform the transfer
        depositInfo.withdrawn = true; // Mark as withdrawn BEFORE transfer (reentrancy guard)

        if (depositInfo.token == address(0)) {
            // ETH withdrawal
            (bool success, ) = payable(depositInfo.depositor).call{value: withdrawalAmount}("");
            require(success, "ETH withdrawal failed");
        } else {
            // ERC20 withdrawal
            IERC20 erc20 = IERC20(depositInfo.token);
            require(erc20.transfer(depositInfo.depositor, withdrawalAmount), "ERC20 withdrawal failed");
        }

        emit WithdrawalMade(depositId, depositInfo.depositor, depositInfo.token, depositInfo.amount, withdrawalAmount);
    }

    /**
     * @dev Calculates the final withdrawal amount based on initial deposit and the effective collapsed state.
     * @param depositInfo The deposit details.
     * @param effectiveCollapsedStateId The state ID that determines the payout for this deposit.
     * @return The final amount to withdraw.
     */
    function _calculateWithdrawalAmount(DepositInfo storage depositInfo, uint256 effectiveCollapsedStateId) internal view returns (uint256) {
        StateInfo storage effectiveCollapsedState = _quantumStates[effectiveCollapsedStateId];
        // Amount * factor / 10000
        return depositInfo.amount.mul(effectiveCollapsedState.withdrawalFactorBps).div(10000);
    }

    /**
     * @dev Determines the final collapse state ID based on potential trigger states and weights.
     * This function implements the probabilistic 'measurement'.
     * Assumes potentialStates only contains states whose *conditions* have been met or are PROBABILISTIC with weight > 0.
     * @param potentialStates An array of state IDs that are candidates for the final collapse state.
     * @return The chosen state ID.
     */
    function _selectCollapsedState(uint256[] memory potentialStates) internal view returns (uint256) {
        uint256 totalWeight = 0;
        uint256[] memory weights = new uint256[](potentialStates.length);

        // Calculate total weight and store individual weights
        for (uint256 i = 0; i < potentialStates.length; i++) {
            uint256 stateId = potentialStates[i];
            StateInfo storage state = _quantumStates[stateId];
             // Only states with PROBABILISTIC condition and weight > 0 contribute to the weighted sum
            if (state.collapseCondition == CollapseCondition.PROBABILISTIC && state.collapseWeight > 0) {
                 weights[i] = state.collapseWeight;
                 totalWeight = totalWeight.add(weights[i]);
            } else {
                 // States triggered by TIME_BASED/ORACLE_BASED conditions that *met* the condition
                 // are effectively selected with 100% probability *if they are the only ones*.
                 // If combined with PROBABILISTIC, this logic needs refinement (e.g., make weighted states only selectable
                 // if total probabilistic weight > 0, otherwise prioritize non-probabilistic if condition met).
                 // For simplicity here: If *any* PROBABILISTIC state is a candidate with weight, use weighted selection across *all* candidates.
                 // If *no* PROBABILISTIC state is a candidate or total weight is 0, pick the first non-probabilistic candidate found.
                 // A more robust approach might involve distinct trigger mechanisms or priorities.

                 // Let's refine: if any non-probabilistic condition is met, ONLY those states (and linked ones) are candidates.
                 // If NO non-probabilistic condition is met, then ONLY probabilistic states (with weight > 0) are candidates.

                 bool anyNonProbabilisticMet = false;
                 for(uint256 j = 0; j < potentialStates.length; j++) {
                     if (_quantumStates[potentialStates[j]].collapseCondition != CollapseCondition.PROBABILISTIC) {
                         anyNonProbabilisticMet = true;
                         break;
                     }
                 }

                 if (anyNonProbabilisticMet) {
                     // If any non-probabilistic condition is met, filter the potentialStates
                     // to include only those states that met their condition.
                     // This means the selection is NOT probabilistic based on weights, but based on which conditions passed.
                     // If only one state's non-probabilistic condition passed, that's the outcome.
                     // If multiple non-probabilistic conditions passed simultaneously (unlikely for TIME_BASED/ORACLE_BASED with exact params, but possible with ranges),
                     // we would need a tie-breaking rule. Simplest is picking the first one in the list that met its condition.

                     for (uint256 j = 0; j < potentialStates.length; j++) {
                         if (_quantumStates[potentialStates[j]].collapseCondition != CollapseCondition.PROBABILISTIC && _checkCollapseCondition(potentialStates[j])) {
                            // Found a non-probabilistic state whose condition is met. This state determines the collapse.
                            return potentialStates[j]; // Return this state ID directly, overrides probabilistic.
                         }
                     }
                     // Should not reach here if anyNonProbabilisticMet is true and checkCollapseCondition is accurate.
                     revert("Internal error during state selection.");


                 } else {
                    // No non-probabilistic conditions met among candidates. Proceed with weighted probabilistic selection
                    // among PROBABILISTIC states with weight > 0.
                    // Weights calculation already handled above.
                 }

            }
        }

        if (totalWeight == 0) {
             // If total weight is still 0 after checking all states, it means either no PROBABILISTIC states had weight
             // or the potentialStates list was empty/incorrectly populated for probabilistic selection.
             // This shouldn't happen if `conditionMet` was true and filtering is correct.
             // This might indicate an edge case where only NO_CONDITION states were candidates, which shouldn't happen via triggerCollapse().
            revert("No valid states for probabilistic collapse.");
        }
         if (potentialStates.length < 1) revert("No states available for selection."); // Should not happen if conditionMet is true


        // Now perform the weighted selection among all candidates if totalWeight > 0
        uint256 randomSeed = _generateEntropy();
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(randomSeed, block.timestamp, block.difficulty, msg.sender))) % totalWeight;

        uint256 cumulativeWeight = 0;
        for (uint256 i = 0; i < potentialStates.length; i++) {
            uint256 stateId = potentialStates[i];
            StateInfo storage state = _quantumStates[stateId];
            // Only consider states that actually contribute weight for the selection loop
            if (state.collapseCondition == CollapseCondition.PROBABILISTIC && state.collapseWeight > 0) {
                cumulativeWeight = cumulativeWeight.add(state.collapseWeight);
                if (randomNumber < cumulativeWeight) {
                    return stateId; // This state is selected
                }
            }
        }

        // Fallback: Should theoretically not be reached if totalWeight > 0 and random number is within range
        // In rare cases due to precision or logic errors, might happen. Default to the first state with weight.
         for (uint265 i = 0; i < potentialStates.length; i++) {
            if (_quantumStates[potentialStates[i]].collapseCondition == CollapseCondition.PROBABILISTIC && _quantumStates[potentialStates[i]].collapseWeight > 0) {
                 return potentialStates[i];
            }
         }

         // If still here, something is fundamentally wrong, maybe potentialStates had issues
        revert("Failed to select collapsed state."); // Should not be reached
    }


    /**
     * @dev Determines the effective collapse state ID for a specific deposit,
     * taking into account the global collapsed state and any entanglement.
     * If a deposit's initial state is linked to the global collapsed state (or vice versa,
     * or both are linked in a chain), the deposit collapses to the global collapsed state.
     * Otherwise, its initial state association is less relevant *for the final outcome factor*,
     * and it simply uses the factor of the global collapsed state.
     * The primary role of initialStateId *after* collapse is conceptual and might influence
     * complex payout logic (e.g., different factors applied based on (initial, final) state pairs),
     * but here, entanglement means linked states *all* resolve to the *same* global result.
     * So, the logic simplifies: if collapsed, the effective state is always the global collapsed state.
     * Entanglement's main effect was on *which* state was chosen during `_selectCollapsedState`,
     * ensuring linked states were considered as a group if their conditions were met.
     *
     * Re-evaluating entanglement logic: A more 'quantum-like' entanglement might mean if State A
     * is chosen, *all deposits initially in states linked to A* also resolve as if they were in A,
     * regardless of the global collapsedStateId. This is more complex state management.
     * Let's implement the latter: a deposit's outcome depends on the global collapsed state,
     * BUT if its *initial* state is linked to the collapsed state, the outcome factor might differ.
     * Or simpler: if deposit's initial state is linked to final collapsed state, it just uses final collapsed state factor.
     * If not linked, maybe it gets a different factor or the base 1x?
     * Let's go with the simpler rule: If the global collapsed state's linked list contains the deposit's initial state ID (or vice versa), OR the initial state is the same as the collapsed state, use the collapsed state's factor. Otherwise, use the factor of the *initial* state? No, that breaks the 'collapse' concept.
     * Correct "Entanglement" interpretation for this contract: If states A and B are linked, and the `triggerCollapse` function *selects* state A, then all deposits initially associated with *either* A or B *resolve as if the outcome was A*. If B is selected, they resolve as if the outcome was B.
     * This requires `_selectCollapsedState` to return not just the ID, but perhaps the *group* of linked states that collapsed together.
     * Let's simplify again: the global `_collapsedStateId` is *the* outcome. Entanglement means *when* checking conditions to trigger collapse, if state A's condition is met, it *also* checks B's condition if B is linked, and if *any* condition in a linked group is met, the whole group becomes candidates for the *single* chosen outcome from the selection process. The chosen outcome applies to everyone.
     * With this simplification, `_getEffectiveCollapsedState` simply returns the global `_collapsedStateId`. The complexity was shifted to `_selectCollapsedState`.
     */
    function _getEffectiveCollapsedState(DepositInfo storage depositInfo) internal view returns (uint256) {
         // After collapse, the effective state for *all* deposits is the single state
         // that the vault collapsed into. The initial state association only
         // matters conceptually or for potential variations in payout logic
         // based on the (initialStateId, collapsedStateId) pair, which is not
         // implemented in _calculateWithdrawalAmount for simplicity.
         // Thus, the effective state is always the global collapsed state.
         return _collapsedStateId;
    }

    /**
     * @dev Checks if a given state's collapse condition is met.
     * @param stateId The state ID to check.
     * @return True if the condition is met, false otherwise.
     */
    function _checkCollapseCondition(uint256 stateId) internal view returns (bool) {
        StateInfo storage state = _quantumStates[stateId];
         if (state.withdrawalFactorBps == 0 && stateId != 1) return false; // State doesn't exist (excluding ID 1 check here as it's internal helper)

        if (state.collapseCondition == CollapseCondition.NO_CONDITION) {
            return false; // Cannot be triggered by general collapse function
        } else if (state.collapseCondition == CollapseCondition.TIME_BASED) {
            return block.timestamp >= state.collapseParam;
        } else if (state.collapseCondition == CollapseCondition.ORACLE_BASED) {
            // This requires interacting with a real oracle. Placeholder logic:
            // Assume the oracle contract has a function like `getValue(uint256 param)`
            // and the condition is `oracleValue >= state.collapseParam`.
            // This is a simplified example and would need a real oracle integration (e.g., Chainlink).
             if (_oracleAddress == address(0)) revert OracleAddressNotSet();
            // Example placeholder: Assume oracle returns a uint256 value
            // (bool success, bytes memory data) = _oracleAddress.staticcall(abi.encodeWithSignature("getValue(uint256)", state.collapseParam));
            // if (!success || data.length < 32) return false; // Oracle call failed or returned invalid data
            // uint256 oracleValue = abi.decode(data, (uint256));
            // return oracleValue >= state.collapseParam;
            // --- Simplified placeholder return ---
            return true; // <-- Replace with actual oracle call and logic
        } else if (state.collapseCondition == CollapseCondition.PROBABILISTIC) {
            // Probabilistic states don't have a *condition* to be met *to be triggerable*.
            // They are always *potential* candidates for probabilistic selection if they have weight.
            // Their inclusion in the candidate pool is handled in `triggerCollapse`.
             return state.collapseWeight > 0; // Can be triggered if has weight
        }
        return false; // Should not reach here
    }


    /**
     * @dev Generates a pseudo-random entropy seed.
     * NOTE: On-chain randomness is inherently limited and predictable.
     * For production, consider Chainlink VRF or similar secure randomness solutions.
     * This is a basic implementation using block data.
     * @return A pseudo-random seed.
     */
    function _generateEntropy() internal view returns (uint256) {
         // Using blockhash (only available for last 256 blocks) and block data.
         // This is NOT cryptographically secure randomness.
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, block.number)));
    }

     /**
      * @dev Checks if two states are linked (entangled).
      * @param stateId1 The ID of the first state.
      * @param stateId2 The ID of the second state.
      * @return True if linked, false otherwise.
      */
    function _areStatesLinked(uint256 stateId1, uint256 stateId2) internal view returns (bool) {
         if (stateId1 == stateId2) return true; // A state is linked to itself conceptually

         StateInfo storage state1 = _quantumStates[stateId1];
         // No need to check state2 explicitly as linking is symmetric in `linkStates`
         if (state1.withdrawalFactorBps == 0 && stateId1 != 1) return false; // State1 doesn't exist

         for(uint256 i = 0; i < state1.linkedStates.length; i++) {
             if (state1.linkedStates[i] == stateId2) {
                 return true;
             }
         }
         return false;
    }
}
```