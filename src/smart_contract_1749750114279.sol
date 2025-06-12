Okay, let's design an interesting, advanced-concept smart contract that isn't a standard copy. We'll call it `QuantumVault` and implement a system where access to funds depends on a combination of "quantum states" that can be manipulated, "collapsed", and influenced by external factors (simulated). This uses state management, conditional access, resource management, and simulated external inputs in a unique combination.

**Concept:** A vault where user and global "quantum states" determine withdrawal eligibility based on configurable "entanglement rules". Interactions with states require "observation energy". States can be "collapsed" or influenced by simulated external events.

**Outline:**

1.  **Contract Definition:** `QuantumVault` inheriting `Ownable` and `Pausable`.
2.  **Interfaces:** `IERC20` for token support.
3.  **State Variables:**
    *   Owner, Paused state
    *   Vault balances (ETH, ERC20)
    *   User-specific states (`userStates`)
    *   Global states (`globalStates`)
    *   Entanglement rule configuration
    *   Observation energy balance
    *   Required energy for collapse
    *   Authorized "observers"
    *   Simulation influence parameters
4.  **Events:** Log key actions (deposits, withdrawals, state changes, rule changes, energy changes, observer changes, collapse, influence).
5.  **Modifiers:** `onlyOwner`, `whenNotPaused`, `whenPaused`, `onlyAuthorizedObserver`, `hasEnoughObservationEnergy`.
6.  **Entanglement Rule Structure:** A struct to define the condition for withdrawal.
7.  **Functions (20+):**
    *   Basic Vault (deposit/withdraw ETH/ERC20) - Conditional withdrawal
    *   State Management (get/set user/global states)
    *   Rule Configuration (set/get entanglement rule)
    *   Conditional Access Check (`canWithdraw` functions)
    *   Observation Energy Management (add/get/consume)
    *   State Collapse (trigger fixed state based on energy)
    *   Simulated External Influence (affect states pseudo-randomly)
    *   Authorized Observer Management (add/remove/check)
    *   Configuration (set collapse cost, influence weights)
    *   Utility (contract info, balances)
    *   Owner/Admin (pause, ownership transfer)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// --- Outline and Function Summary ---
//
// 1. Contract Definition: `QuantumVault` inheriting `Ownable` and `Pausable`.
//    - Implements a vault for ETH and ERC20 tokens.
//    - Access is governed by metaphorical "quantum states".
//    - Includes pause functionality for emergencies.
//
// 2. Interfaces: `IERC20` standard interface for interacting with ERC-20 tokens.
//
// 3. State Variables:
//    - `owner`: The contract owner (from Ownable).
//    - `_paused`: Paused state (from Pausable).
//    - `userStates`: Mapping storing individual user state values.
//    - `globalStates`: Mapping storing global state values.
//    - `entanglementRule`: Struct defining the withdrawal condition based on states.
//    - `observationEnergy`: Global energy pool required for state manipulations.
//    - `requiredCollapseEnergy`: Energy cost for collapsing a state.
//    - `authorizedObservers`: Mapping of addresses allowed to perform state collapse/influence.
//    - `influenceWeightGlobal`: How much simulated influence affects global state.
//    - `influenceWeightUser`: How much simulated influence affects user state.
//    - `minWithdrawalAmountETH`: Minimum ETH that can be withdrawn.
//    - `minWithdrawalAmountERC20`: Minimum ERC20 that can be withdrawn.
//
// 4. Events: Log significant actions for transparency and off-chain monitoring.
//    - `ETHDeposited`: Records ETH deposits.
//    - `ETHWithdrawn`: Records conditional ETH withdrawals.
//    - `ERC20Deposited`: Records ERC20 deposits.
//    - `ERC20Withdrawn`: Records conditional ERC20 withdrawals.
//    - `UserStateChanged`: Records changes to a user's state.
//    - `GlobalStateChanged`: Records changes to a global state variable.
//    - `EntanglementRuleUpdated`: Records changes to the withdrawal rule.
//    - `ObservationEnergyAdded`: Records energy added to the pool.
//    - `StateCollapsed`: Records a state collapse event.
//    - `ExternalInfluenceApplied`: Records application of simulated external influence.
//    - `ObserverAdded`: Records addition of an authorized observer.
//    - `ObserverRemoved`: Records removal of an authorized observer.
//    - `CollapseEnergyCostUpdated`: Records update to collapse energy cost.
//    - `InfluenceWeightUpdated`: Records update to influence weights.
//    - `MinWithdrawalAmountUpdated`: Records updates to minimum withdrawal amounts.
//
// 5. Modifiers: Reusable access control and state checks.
//    - `onlyOwner`: Restricts function calls to the contract owner (from Ownable).
//    - `whenNotPaused`: Restricts function calls when the contract is not paused (from Pausable).
//    - `whenPaused`: Restricts function calls when the contract is paused (from Pausable).
//    - `onlyAuthorizedObserver`: Restricts function calls to owner or authorized observers.
//    - `hasEnoughObservationEnergy`: Checks if sufficient energy is available for an action.
//
// 6. Entanglement Rule Structure (`EntanglementRule`): Defines the parameters used in the `canWithdraw` condition calculation.
//    - `userStateDimension`: Which user state dimension to use.
//    - `globalStateDimension`: Which global state dimension to use.
//    - `modulo`: Modulo value for the combined state calculation.
//    - `targetValue`: The target value the combined state (modulo) must equal for withdrawal.
//    - `requireCollapsedStates`: Bool indicating if relevant states must be 'collapsed' (e.g., non-zero after collapse) to withdraw.
//
// 7. Functions (27 functions in total):
//    - `constructor()`: Initializes contract, owner, and default state/rules.
//    - `receive()`: Allows direct ETH deposits into the vault.
//    - `depositETH()`: Explicit ETH deposit function.
//    - `withdrawETH(uint256 amount)`: Conditional withdrawal of ETH. Requires `canWithdrawETH()`.
//    - `depositERC20(address tokenAddress, uint256 amount)`: Deposit ERC20 tokens. Requires allowance.
//    - `withdrawERC20(address tokenAddress, uint256 amount)`: Conditional withdrawal of ERC20. Requires `canWithdrawERC20()`.
//    - `canWithdrawETH()`: View function. Checks if the calling user can withdraw ETH based on current states and rule.
//    - `canWithdrawERC20(address tokenAddress)`: View function. Checks if the calling user can withdraw ERC20 based on current states and rule.
//    - `getUserState(address user, uint256 dimension)`: View function. Gets a specific user's state value for a dimension.
//    - `getGlobalState(uint256 dimension)`: View function. Gets a specific global state value for a dimension.
//    - `setUserState(address user, uint256 dimension, int256 value)`: Sets a user's state value (authorized observers/owner).
//    - `setGlobalState(uint256 dimension, int256 value)`: Sets a global state value (authorized observers/owner).
//    - `configureEntanglementRule(uint256 userDim, uint256 globalDim, uint256 mod, int256 target, bool requireCollapsed)`: Sets the entanglement rule (owner only).
//    - `getEntanglementRule()`: View function. Returns the current entanglement rule parameters.
//    - `collapseUserState(address user, uint256 dimension)`: Attempts to 'collapse' a user's state. Requires energy. Fixes state value.
//    - `collapseGlobalState(uint256 dimension)`: Attempts to 'collapse' a global state. Requires energy. Fixes state value.
//    - `getObservationEnergy()`: View function. Gets the current observation energy level.
//    - `addObservationEnergy(uint256 amount)`: Adds energy to the pool (owner only).
//    - `getRequiredCollapseEnergy()`: View function. Gets the energy cost for collapsing a state.
//    - `setCollapseEnergyCost(uint256 cost)`: Sets the energy cost for collapsing a state (owner only).
//    - `simulateExternalInfluence()`: Simulates external 'quantum noise' affecting states pseudo-randomly (authorized observers/owner). Requires energy? (Let's make it cost energy too).
//    - `setInfluenceWeights(uint256 globalWeight, uint256 userWeight)`: Sets the weights for external influence (owner only).
//    - `addAuthorizedObserver(address observer)`: Adds an address to the authorized observers list (owner only).
//    - `removeAuthorizedObserver(address observer)`: Removes an address from the authorized observers list (owner only).
//    - `isAuthorizedObserver(address observer)`: View function. Checks if an address is an authorized observer.
//    - `getTotalETHBalance()`: View function. Gets the total ETH held by the contract.
//    - `getUserHoldingsETH(address user)`: View function. Gets a user's recorded ETH deposit amount. (Note: This contract tracks user deposits, not the overall contract balance per user).
//    - `setMinimumWithdrawalAmounts(uint256 minETH, uint256 minERC20)`: Sets the minimum withdrawal amounts (owner only).
//
// --- End of Outline ---

contract QuantumVault is Ownable, Pausable {
    // --- State Variables ---

    // --- Balances (Simple tracking, actual balance is contract's holdings) ---
    // Note: This contract tracks how much *users intended* to deposit,
    // but the actual funds are held in the contract's balance.
    // User withdrawals check eligibility based on state, not individual deposit records.
    mapping(address => uint256) private userETHHoldings;
    mapping(address => mapping(address => uint256)) private userERC20Holdings;

    // --- Quantum States ---
    // Using int256 to allow for positive and negative 'state values'
    mapping(address => mapping(uint256 => int256)) private userStates;
    mapping(uint256 => int256) private globalStates;

    // --- State Collapse Tracking ---
    // A state is considered 'collapsed' if its value is set using collapseUserState/GlobalState
    // and its value is non-zero *after* collapsing.
    mapping(address => mapping(uint256 => bool)) private userStateCollapsed;
    mapping(uint256 => bool) private globalStateCollapsed;


    // --- Entanglement Rule ---
    struct EntanglementRule {
        uint256 userStateDimension; // Which user state dimension to check
        uint256 globalStateDimension; // Which global state dimension to check
        uint256 modulo; // Modulo for combined state calculation
        int256 targetValue; // Target value the combined state (modulo) must equal
        bool requireCollapsedStates; // If true, required states (user and global) must be non-zero *after* being collapsed
    }

    EntanglementRule public entanglementRule;

    // --- Observation Energy ---
    uint256 public observationEnergy;
    uint256 public requiredCollapseEnergy;
    uint256 public requiredInfluenceEnergy; // Energy cost for simulated influence

    // --- Authorized Observers ---
    // Addresses (besides owner) allowed to interact with states/influence
    mapping(address => bool) public authorizedObservers;

    // --- Simulated External Influence Parameters ---
    uint256 public influenceWeightGlobal; // Weight applied to pseudo-randomness for global state influence
    uint256 public influenceWeightUser;   // Weight applied to pseudo-randomness for user state influence

    // --- Minimum Withdrawal Amounts ---
    uint256 public minWithdrawalAmountETH = 0;
    mapping(address => uint256) public minWithdrawalAmountERC20; // Per token address

    // --- Events ---
    event ETHDeposited(address indexed user, uint256 amount);
    event ETHWithdrawn(address indexed user, uint256 amount);
    event ERC20Deposited(address indexed user, address indexed token, uint256 amount);
    event ERC20Withdrawn(address indexed user, address indexed token, uint256 amount);
    event UserStateChanged(address indexed user, uint256 indexed dimension, int256 newValue, bool indexed collapsed);
    event GlobalStateChanged(uint256 indexed dimension, int256 newValue, bool indexed collapsed);
    event EntanglementRuleUpdated(uint256 userDim, uint256 globalDim, uint256 mod, int256 target, bool requireCollapsed);
    event ObservationEnergyAdded(uint256 amount);
    event StateCollapsed(address indexed user, uint256 indexed dimension, bool isGlobal, int256 finalValue);
    event ExternalInfluenceApplied(address indexed by, uint256 entropySeed); // entropySeed is just for logging the input to pseudo-randomness
    event ObserverAdded(address indexed observer);
    event ObserverRemoved(address indexed observer);
    event CollapseEnergyCostUpdated(uint256 newCost);
    event InfluenceEnergyCostUpdated(uint256 newCost);
    event InfluenceWeightUpdated(uint256 globalWeight, uint256 userWeight);
    event MinWithdrawalAmountUpdated(uint256 minETH, address indexed token, uint256 minERC20);

    // --- Modifiers ---
    modifier onlyAuthorizedObserver() {
        require(msg.sender == owner() || authorizedObservers[msg.sender], "QuantumVault: Not authorized observer");
        _;
    }

    modifier hasEnoughObservationEnergy(uint256 required) {
        require(observationEnergy >= required, "QuantumVault: Not enough observation energy");
        _;
    }

    // --- Constructor ---
    constructor() Ownable(msg.sender) Pausable(false) {
        // Set a default entanglement rule (Example: userState[0] + globalState[0]) % 10 == 5
        entanglementRule = EntanglementRule(0, 0, 10, 5, false);

        // Set default costs and weights
        requiredCollapseEnergy = 100;
        requiredInfluenceEnergy = 500;
        influenceWeightGlobal = 1;
        influenceWeightUser = 1;
    }

    // --- Receive ETH ---
    receive() external payable whenNotPaused {
        userETHHoldings[msg.sender] += msg.value;
        emit ETHDeposited(msg.sender, msg.value);
    }

    // --- 1. Deposit ETH ---
    function depositETH() external payable whenNotPaused {
        userETHHoldings[msg.sender] += msg.value;
        emit ETHDeposited(msg.sender, msg.value);
    }

    // --- 2. Withdraw ETH (Conditional) ---
    function withdrawETH(uint256 amount) external whenNotPaused {
        require(amount > 0, "QuantumVault: Amount must be > 0");
        require(userETHHoldings[msg.sender] >= amount, "QuantumVault: Insufficient recorded holdings");
        require(amount >= minWithdrawalAmountETH, "QuantumVault: Below minimum withdrawal amount");

        // --- Core Quantum Condition Check ---
        require(canWithdrawETH(), "QuantumVault: Withdrawal condition not met");

        // Update user holdings record
        userETHHoldings[msg.sender] -= amount;

        // Transfer ETH (reentrancy guard provided by Check-Effects-Interact pattern implicitly)
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "QuantumVault: ETH transfer failed");

        emit ETHWithdrawn(msg.sender, amount);
    }

    // --- 3. Deposit ERC20 ---
    function depositERC20(address tokenAddress, uint256 amount) external whenNotPaused {
        require(amount > 0, "QuantumVault: Amount must be > 0");
        require(tokenAddress != address(0), "QuantumVault: Invalid token address");

        IERC20 token = IERC20(tokenAddress);
        // Using transferFrom requires the user to approve this contract first
        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "QuantumVault: ERC20 transfer failed");

        userERC20Holdings[msg.sender][tokenAddress] += amount;
        emit ERC20Deposited(msg.sender, tokenAddress, amount);
    }

    // --- 4. Withdraw ERC20 (Conditional) ---
    function withdrawERC20(address tokenAddress, uint256 amount) external whenNotPaused {
        require(amount > 0, "QuantumVault: Amount must be > 0");
        require(tokenAddress != address(0), "QuantumVault: Invalid token address");
        require(userERC20Holdings[msg.sender][tokenAddress] >= amount, "QuantumVault: Insufficient recorded holdings");
        require(amount >= minWithdrawalAmountERC20[tokenAddress], "QuantumVault: Below minimum withdrawal amount");

        // --- Core Quantum Condition Check ---
        require(canWithdrawERC20(tokenAddress), "QuantumVault: Withdrawal condition not met");

        // Update user holdings record
        userERC20Holdings[msg.sender][tokenAddress] -= amount;

        IERC20 token = IERC20(tokenAddress);
        bool success = token.transfer(msg.sender, amount);
        require(success, "QuantumVault: ERC20 transfer failed");

        emit ERC20Withdrawn(msg.sender, tokenAddress, amount);
    }

    // --- 5. Check ETH Withdrawal Eligibility ---
    function canWithdrawETH() public view returns (bool) {
        return _checkWithdrawalCondition(msg.sender);
    }

    // --- 6. Check ERC20 Withdrawal Eligibility ---
    function canWithdrawERC20(address tokenAddress) public view returns (bool) {
        // ERC20 eligibility uses the same core state logic
        return _checkWithdrawalCondition(msg.sender);
    }

    // Internal helper to check the core quantum condition
    function _checkWithdrawalCondition(address user) internal view returns (bool) {
        int256 userStateVal = userStates[user][entanglementRule.userStateDimension];
        int256 globalStateVal = globalStates[entanglementRule.globalStateDimension];

        // Check collapse requirement first
        if (entanglementRule.requireCollapsedStates) {
            bool userReqMet = userStateCollapsed[user][entanglementRule.userStateDimension];
            bool globalReqMet = globalStateCollapsed[entanglementRule.globalStateDimension];

            // If requiring collapse, both must be collapsed AND the collapsed value must be non-zero
            if (!(userReqMet && globalReqMet && userStateVal != 0 && globalStateVal != 0)) {
                 return false;
            }
        }

        // Calculate combined state (handling potential negative values with modulo)
        // (userStateVal + globalStateVal) could be negative.
        // Solidity's % operator for negative numbers is implementation-defined below 0.8.0.
        // For 0.8.x, a % n works as expected (e.g. -5 % 10 = -5). We need a positive modulo.
        int256 combinedState = userStateVal + globalStateVal;
        uint256 positiveModulo = entanglementRule.modulo;
        if (positiveModulo == 0) return false; // Avoid division by zero

        // Calculate positive modulo result
        uint256 result;
        if (combinedState >= 0) {
            result = uint256(combinedState) % positiveModulo;
        } else {
            // Add multiples of modulo until positive
            result = (uint256(combinedState) % positiveModulo + positiveModulo) % positiveModulo;
        }

        // Check against the target value
        // Target value can be negative, need to compare using int256
         return int256(result) == entanglementRule.targetValue;
    }


    // --- 7. Get User State ---
    function getUserState(address user, uint256 dimension) public view returns (int256) {
        return userStates[user][dimension];
    }

    // --- 8. Get Global State ---
    function getGlobalState(uint256 dimension) public view returns (int256) {
        return globalStates[dimension];
    }

    // --- 9. Set User State ---
    // Callable by owner or authorized observers
    function setUserState(address user, uint256 dimension, int256 value) external onlyAuthorizedObserver whenNotPaused {
        userStates[user][dimension] = value;
        // Setting state directly does NOT mark it as collapsed
        userStateCollapsed[user][dimension] = false;
        emit UserStateChanged(user, dimension, value, false);
    }

    // --- 10. Set Global State ---
    // Callable by owner or authorized observers
    function setGlobalState(uint256 dimension, int256 value) external onlyAuthorizedObserver whenNotPaused {
        globalStates[dimension] = value;
        // Setting state directly does NOT mark it as collapsed
        globalStateCollapsed[dimension] = false;
        emit GlobalStateChanged(dimension, value, false);
    }

    // --- 11. Configure Entanglement Rule ---
    // Callable by owner only
    function configureEntanglementRule(
        uint256 userDim,
        uint256 globalDim,
        uint256 mod,
        int256 target,
        bool requireCollapsed
    ) external onlyOwner whenNotPaused {
        require(mod > 0, "QuantumVault: Modulo must be > 0");
        // Although target can be negative, the result of modulo will be in [0, mod-1] or [-(mod-1), 0] in some languages.
        // With our _checkWithdrawalCondition's positive modulo logic, the result is [0, mod-1].
        // So, require target to be within the positive modulo range for clarity.
        require(target >= 0 && uint256(target) < mod, "QuantumVault: Target value must be within [0, modulo-1]");


        entanglementRule = EntanglementRule(userDim, globalDim, mod, target, requireCollapsed);
        emit EntanglementRuleUpdated(userDim, globalDim, mod, target, requireCollapsed);
    }

    // --- 12. Get Entanglement Rule ---
    function getEntanglementRule() external view returns (
        uint256 userStateDimension,
        uint256 globalStateDimension,
        uint256 modulo,
        int256 targetValue,
        bool requireCollapsedStates
    ) {
        return (
            entanglementRule.userStateDimension,
            entanglementRule.globalStateDimension,
            entanglementRule.modulo,
            entanglementRule.targetValue,
            entanglementRule.requireCollapsedStates
        );
    }

    // --- 13. Collapse User State ---
    // Attempt to fix a user's state. Requires observation energy.
    // Callable by owner or authorized observers.
    function collapseUserState(address user, uint256 dimension)
        external
        onlyAuthorizedObserver
        whenNotPaused
        hasEnoughObservationEnergy(requiredCollapseEnergy)
    {
        // In a real quantum system, measurement 'collapses' the state to a definite value.
        // Here, we simulate fixing the current value and marking it as collapsed.
        // The value doesn't change, but the 'collapsed' flag is set.
        // The int256 value itself could represent the outcome of the collapse.
        observationEnergy -= requiredCollapseEnergy;
        userStateCollapsed[user][dimension] = true;
        emit StateCollapsed(user, dimension, false, userStates[user][dimension]);
        // Note: UserStateChanged event is not emitted here as the value didn't change by collapse itself.
    }

    // --- 14. Collapse Global State ---
    // Attempt to fix a global state. Requires observation energy.
    // Callable by owner or authorized observers.
    function collapseGlobalState(uint256 dimension)
        external
        onlyAuthorizedObserver
        whenNotPaused
        hasEnoughObservationEnergy(requiredCollapseEnergy)
    {
        observationEnergy -= requiredCollapseEnergy;
        globalStateCollapsed[dimension] = true;
        emit StateCollapsed(address(0), dimension, true, globalStates[dimension]);
        // Note: GlobalStateChanged event is not emitted here as the value didn't change by collapse itself.
    }

    // --- 15. Get Observation Energy ---
    function getObservationEnergy() public view returns (uint256) {
        return observationEnergy;
    }

    // --- 16. Add Observation Energy ---
    // Callable by owner only (Simulates adding resources for observation/experimentation)
    function addObservationEnergy(uint256 amount) external onlyOwner {
        require(amount > 0, "QuantumVault: Amount must be > 0");
        observationEnergy += amount;
        emit ObservationEnergyAdded(amount);
    }

    // --- 17. Get Required Collapse Energy ---
    function getRequiredCollapseEnergy() public view returns (uint256) {
        return requiredCollapseEnergy;
    }

    // --- 18. Set Collapse Energy Cost ---
    // Callable by owner only
    function setCollapseEnergyCost(uint256 cost) external onlyOwner {
        requiredCollapseEnergy = cost;
        emit CollapseEnergyCostUpdated(cost);
    }

    // --- 19. Get Required Influence Energy ---
    function getRequiredInfluenceEnergy() public view returns (uint256) {
        return requiredInfluenceEnergy;
    }

    // --- 20. Set Influence Energy Cost ---
    // Callable by owner only
    function setInfluenceEnergyCost(uint256 cost) external onlyOwner {
        requiredInfluenceEnergy = cost;
        emit InfluenceEnergyCostUpdated(cost);
    }

    // --- 21. Simulate External Influence ---
    // Simulates external 'quantum noise' affecting states pseudo-randomly.
    // Uses block data for a simple, non-cryptographically secure source of entropy.
    // Callable by owner or authorized observers. Requires energy.
    function simulateExternalInfluence()
        external
        onlyAuthorizedObserver
        whenNotPaused
        hasEnoughObservationEnergy(requiredInfluenceEnergy)
    {
        observationEnergy -= requiredInfluenceEnergy;

        // Use recent block data for pseudo-randomness
        // NOTE: This is NOT cryptographically secure and should not be used for high-value random outcomes
        // if miners or observers can influence the block data or timing. It's for conceptual simulation here.
        uint256 entropySeed = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.number,
            tx.origin, // Using tx.origin is generally discouraged due to phishing risks, but here it adds entropy. Be cautious in real apps.
            block.prevrandao // Better source post-merge, replace block.difficulty
        )));

        uint256 numGlobalDimensions = 10; // Arbitrary number of global dimensions to influence
        uint256 numUserDimensions = 10;   // Arbitrary number of user dimensions to influence
        uint256 maxInfluence = 100;       // Max absolute value of influence

        // Influence Global States
        for (uint256 i = 0; i < numGlobalDimensions; i++) {
            uint256 dimension = (entropySeed + i) % 256; // Select a dimension to influence
            int256 influence = int256((entropySeed >> (i * 8)) % (2 * maxInfluence + 1)) - int256(maxInfluence); // Pseudo-random value in [-maxInfluence, maxInfluence]

            int256 oldState = globalStates[dimension];
            // Apply influence weighted
            int256 newState = oldState + (influence * int256(influenceWeightGlobal));

            globalStates[dimension] = newState;
             // Influence *resets* the collapsed state
            globalStateCollapsed[dimension] = false;
            emit GlobalStateChanged(dimension, newState, false);
        }

        // Influence Caller's User States
        for (uint256 i = 0; i < numUserDimensions; i++) {
            uint256 dimension = (entropySeed + 1000 + i) % 256; // Select a dimension
            int256 influence = int256((entropySeed >> (i * 8 + 64)) % (2 * maxInfluence + 1)) - int256(maxInfluence); // Another pseudo-random value

             int256 oldState = userStates[msg.sender][dimension];
            // Apply influence weighted
            int256 newState = oldState + (influence * int256(influenceWeightUser));

            userStates[msg.sender][dimension] = newState;
            // Influence *resets* the collapsed state
            userStateCollapsed[msg.sender][dimension] = false;
            emit UserStateChanged(msg.sender, dimension, newState, false);
        }

        emit ExternalInfluenceApplied(msg.sender, entropySeed);
    }

    // --- 22. Set Influence Weights ---
    // Callable by owner only
    function setInfluenceWeights(uint256 globalWeight, uint256 userWeight) external onlyOwner {
        influenceWeightGlobal = globalWeight;
        influenceWeightUser = userWeight;
        emit InfluenceWeightUpdated(globalWeight, userWeight);
    }

    // --- 23. Add Authorized Observer ---
    // Callable by owner only
    function addAuthorizedObserver(address observer) external onlyOwner {
        require(observer != address(0), "QuantumVault: Invalid address");
        authorizedObservers[observer] = true;
        emit ObserverAdded(observer);
    }

    // --- 24. Remove Authorized Observer ---
    // Callable by owner only
    function removeAuthorizedObserver(address observer) external onlyOwner {
         require(observer != address(0), "QuantumVault: Invalid address");
        authorizedObservers[observer] = false;
        emit ObserverRemoved(observer);
    }

    // --- 25. Check if Address is Authorized Observer ---
    function isAuthorizedObserver(address observer) public view returns (bool) {
        return authorizedObservers[observer];
    }

    // --- 26. Get Total ETH Balance ---
    function getTotalETHBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // --- 27. Get User's Recorded ETH Holdings ---
    function getUserHoldingsETH(address user) public view returns (uint256) {
        return userETHHoldings[user];
    }

    // --- 28. Get User's Recorded ERC20 Holdings ---
    function getUserHoldingsERC20(address user, address tokenAddress) public view returns (uint256) {
        return userERC20Holdings[user][tokenAddress];
    }

    // --- 29. Get Total ERC20 Balance (Actual) ---
     function getTotalERC20Balance(address tokenAddress) public view returns (uint256) {
        require(tokenAddress != address(0), "QuantumVault: Invalid token address");
        return IERC20(tokenAddress).balanceOf(address(this));
    }


    // --- 30. Set Minimum Withdrawal Amounts ---
    // Callable by owner only
    function setMinimumWithdrawalAmounts(uint256 minETH, address tokenAddress, uint256 minERC20) external onlyOwner {
        require(tokenAddress != address(0) || minETH > 0, "QuantumVault: Set ETH min or valid token"); // Basic sanity check
        if (minETH > 0) {
             minWithdrawalAmountETH = minETH;
             emit MinWithdrawalAmountUpdated(minETH, address(0), 0); // Use address(0) for ETH
        }
        if (tokenAddress != address(0)) {
             minWithdrawalAmountERC20[tokenAddress] = minERC20;
             emit MinWithdrawalAmountUpdated(0, tokenAddress, minERC20);
        }
    }


    // --- Pausable Functions (from OpenZeppelin) ---
    // `pause()`: Inherited from Pausable. Only owner can call.
    // `unpause()`: Inherited from Pausable. Only owner can call.
    // `paused()`: Inherited from Pausable. Public view function.

    // --- Ownable Functions (from OpenZeppelin) ---
    // `transferOwnership(address newOwner)`: Inherited from Ownable. Only owner can call.
    // `renounceOwnership()`: Inherited from Ownable. Only owner can call.
    // `owner()`: Inherited from Ownable. Public view function.

    // --- Contract Info ---
    function contractName() public pure returns (string memory) {
        return "QuantumVault";
    }

    function contractVersion() public pure returns (string memory) {
        return "1.0";
    }
}
```