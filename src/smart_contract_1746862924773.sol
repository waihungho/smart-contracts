Okay, here is a Solidity smart contract incorporating several advanced, creative, and perhaps slightly abstract concepts around state management, conditional access, and time-based mechanics, presented as a "Quantum Vault". It aims to demonstrate a complex interaction of internal state, time, and configurable parameters affecting how funds can be deposited and withdrawn.

It is designed to be illustrative of potential complex logic rather than production-ready for securing large amounts of value without extensive audits and potentially external systems (like actual oracles, VRF, etc., which are simulated here).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumVault
 * @author [Your Name/Alias] (Illustrative Example)
 * @notice A complex vault contract using state-dependent logic, temporal locks, and probabilistic access.
 * It manages Ether deposits and withdrawals based on internal 'Quantum State', configured time windows,
 * and simulated external inputs. Not a simple timelock or multisig.
 *
 * Outline:
 * 1. State Variables & Events
 * 2. Modifiers
 * 3. State Management Functions
 * 4. Fund Management Functions (Deposit & Conditional Withdrawal)
 * 5. Lock & Time-Based Functions
 * 6. Probabilistic Access Functions
 * 7. Access Control & Delegation Functions
 * 8. Configuration Functions
 * 9. Information & Utility Functions
 */

/**
 * @summary Function Summary:
 *
 * State Management:
 * - initializeVault: Sets up the vault with an initial state (intended for deploy or initializer).
 * - enterState: Changes the internal 'Quantum State' based on current state and input, emitting StateChanged event.
 * - resetState: Resets the state to a default Stable state under specific conditions.
 * - getState: Returns the current internal 'Quantum State'.
 *
 * Fund Management:
 * - depositETH: Allows users to deposit Ether into the vault.
 * - withdrawETH: Allows the owner to withdraw Ether, subject to state, locks, and temporal windows.
 * - attemptProbabilisticWithdraw: Allows an authorized user to *attempt* a withdrawal based on a probability influenced by state.
 * - emergencyWithdraw: Allows the owner or emergency delegate to withdraw bypassing some checks (may incur penalties/state change).
 * - sweepDust: Allows sweeping small amounts of arbitrary ERC20 tokens sent by mistake (subject to state/config).
 *
 * Lock & Time-Based:
 * - lockFundsFor: Locks a specific amount of the owner's withdrawable funds until a future timestamp.
 * - releaseLockedFunds: Allows owner to release funds after their lock has expired.
 * - setTemporalLock: Sets a specific block timestamp *before* which certain sensitive actions are restricted.
 * - clearTemporalLock: Clears the active temporal lock.
 * - getLockedFundsInfo: Returns information about currently locked funds for the owner.
 * - getTemporalLockEndTime: Returns the block timestamp when the temporal lock expires (0 if inactive).
 *
 * Probabilistic Access:
 * - calculateProbabilisticChance: Internal helper to determine success chance based on state and config.
 * - getProbabilisticWithdrawChance: Returns the current success chance for a probabilistic withdrawal attempt.
 * - setProbabilisticWithdrawParams: Configures the base chance and state influence for probabilistic withdrawals.
 *
 * Access Control & Delegation:
 * - delegateRole: Assigns a specific role (Configurator, EmergencyHandler) to another address.
 * - revokeRole: Removes a previously assigned role from an address.
 * - hasRole: Checks if an address has a specific delegated role.
 * - transferOwnership: Standard OpenZeppelin style ownership transfer.
 * - renounceOwnership: Standard OpenZeppelin style ownership renouncement (caution advised).
 *
 * Configuration:
 * - setAllowedStates: Configures which state transitions are permissible.
 * - setStateWithdrawalMultiplier: Configures how the state affects withdrawal amounts or conditions.
 * - setEmergencyWithdrawPenalty: Configures parameters for the emergency withdrawal penalty/state change.
 * - setTrustedExternalSource: Sets the address that can call functions simulating external data input.
 * - updateStateFromExternalSource: Simulates an update triggered by external data, affecting state.
 *
 * Information & Utility:
 * - getContractBalance: Returns the current ETH balance of the contract.
 * - getTokenBalance: Returns the balance of a specific ERC20 token held by the contract.
 * - getVaultConfiguration: Returns a summary of key configuration parameters.
 * - isPaused: Checks if the contract is currently paused.
 * - pauseVault: Pauses the contract (owner only).
 * - unpauseVault: Unpauses the contract (owner only).
 */

contract QuantumVault {
    // 1. State Variables & Events

    address private _owner;

    enum QuantumState {
        Uninitialized,
        Stable,
        Fluctuating,
        Entangled,
        Critical
    }

    enum DelegateRole {
        None,
        Configurator,
        EmergencyHandler
    }

    QuantumState public currentState;
    bool public isVaultPaused;

    // ETH balance is tracked implicitly by the contract's address

    // State-dependent configurations
    mapping(uint8 => mapping(uint8 => bool)) public allowedStateTransitions; // currentState => newState => allowed?
    mapping(uint8 => uint256) public stateWithdrawalMultipliers; // state => multiplier (e.g., percentage basis points)

    // Probabilistic withdrawal configuration
    uint256 public probabilisticBaseChance = 500; // Base chance in basis points (e.g., 500 = 5%)
    mapping(uint8 => int256) public probabilisticStateModifiers; // state => modifier (in basis points)

    // Temporal Lock
    uint256 public temporalLockEndTime; // block.timestamp when temporal lock expires (0 if inactive)

    // Locked Funds (for owner's specific deposit portions)
    struct LockedFunds {
        uint256 amount;
        uint256 unlockTime;
    }
    mapping(address => LockedFunds) private userLockedFunds; // User => LockedFunds info (currently only owner uses this pattern)

    // Access Control & Delegation
    mapping(address => DelegateRole) private delegatedRoles;

    // Simulated External Source
    address public trustedExternalSource;
    uint256 public lastExternalDataValue;

    // Emergency Withdrawal Penalty/State Change config
    uint26 public emergencyWithdrawalPenaltyBasisPoints = 1000; // 10% penalty
    QuantumState public stateAfterEmergencyWithdrawal = QuantumState.Critical;

    // Events
    event VaultInitialized(address indexed owner, uint8 initialState);
    event StateChanged(uint8 oldState, uint8 indexed newState, string reason);
    event DepositMade(address indexed depositor, uint256 amount);
    event WithdrawalMade(address indexed recipient, uint256 amount, string reason);
    event ProbabilisticWithdrawalAttempt(address indexed attempter, uint256 requestedAmount, uint256 actualAmount, bool success, uint256 chance);
    event FundsLocked(address indexed user, uint256 amount, uint256 unlockTime);
    event FundsUnlocked(address indexed user, uint256 amount);
    event TemporalLockSet(uint256 endTime);
    event TemporalLockCleared();
    event RoleDelegated(address indexed delegatee, uint8 role);
    event RoleRevoked(address indexed delegatee);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event VaultPaused(address indexed by);
    event VaultUnpaused(address indexed by);
    event DustSwept(address indexed token, uint256 amount, address indexed recipient);
    event ConfigurationUpdated(string configName, bytes data); // Generic config update event

    // 2. Modifiers

    modifier onlyOwner() {
        require(msg.sender == _owner, "QV: Caller is not the owner");
        _;
    }

    modifier onlyDelegate(DelegateRole role) {
        require(delegatedRoles[msg.sender] == role, "QV: Caller does not have required role");
        _;
    }

    modifier whenNotPaused() {
        require(!isVaultPaused, "QV: Vault is paused");
        _;
    }

    modifier requireState(QuantumState requiredState) {
        require(currentState == requiredState, "QV: Incorrect state");
        _;
    }

    modifier requireMinState(QuantumState minState) {
        require(currentState >= minState, "QV: State too low"); // Requires state enum values to be ordered
        _;
    }

    modifier requireMaxState(QuantumState maxState) {
        require(currentState <= maxState, "QV: State too high"); // Requires state enum values to be ordered
        _;
    }

    // Constructor (Simple initialization)
    constructor(uint8 initialState) {
        _owner = msg.sender;
        // Ensure initial state is valid (not Uninitialized)
        require(initialState > uint8(QuantumState.Uninitialized) && initialState <= uint8(QuantumState.Critical), "QV: Invalid initial state");
        currentState = QuantumState(initialState);
        isVaultPaused = false;

        // Default allowed transitions (example: Stable -> Fluctuating, Fluctuating <-> Entangled, Critical -> Stable)
        allowedStateTransitions[uint8(QuantumState.Stable)][uint8(QuantumState.Fluctuating)] = true;
        allowedStateTransitions[uint8(QuantumState.Fluctuating)][uint8(QuantumState.Stable)] = true;
        allowedStateTransitions[uint8(QuantumState.Fluctuating)][uint8(QuantumState.Entangled)] = true;
        allowedStateTransitions[uint8(QuantumState.Entangled)][uint8(QuantumState.Fluctuating)] = true;
        allowedStateTransitions[uint8(QuantumState.Critical)][uint8(QuantumState.Stable)] = true;

        // Default state multipliers (example: Stable = 1x, Fluctuating = 0.8x, Entangled = 1.2x, Critical = 0x for withdrawals)
        stateWithdrawalMultipliers[uint8(QuantumState.Stable)] = 10000; // 100%
        stateWithdrawalMultipliers[uint8(QuantumState.Fluctuating)] = 8000; // 80%
        stateWithdrawalMultipliers[uint8(QuantumState.Entangled)] = 12000; // 120% (e.g. bonus?) - note: withdrawETH needs logic for >100%
        stateWithdrawalMultipliers[uint8(QuantumState.Critical)] = 0; // 0%

        // Default probabilistic modifiers (example: Stable = -100 bp, Fluctuating = 0 bp, Entangled = +200 bp, Critical = +500 bp)
        probabilisticStateModifiers[uint8(QuantumState.Stable)] = -100;
        probabilisticStateModifiers[uint8(QuantumState.Fluctuating)] = 0;
        probabilisticStateModifiers[uint8(QuantumState.Entangled)] = 200;
        probabilisticStateModifiers[uint8(QuantumState.Critical)] = 500;

        emit VaultInitialized(_owner, initialState);
    }

    // 3. State Management Functions

    /**
     * @notice Allows owner or trusted source to attempt to change the vault's state.
     * Transition must be allowed by `allowedStateTransitions` map.
     * @param newState The target QuantumState.
     * @param reason Description for the state change.
     */
    function enterState(uint8 newState, string calldata reason)
        external
        whenNotPaused
    {
        require(msg.sender == _owner || msg.sender == trustedExternalSource, "QV: Unauthorized state transition");
        require(newState > uint8(QuantumState.Uninitialized) && newState <= uint8(QuantumState.Critical), "QV: Invalid target state");
        require(allowedStateTransitions[uint8(currentState)][newState], "QV: State transition not allowed from current state");

        uint8 oldState = uint8(currentState);
        currentState = QuantumState(newState);

        emit StateChanged(oldState, newState, reason);
    }

    /**
     * @notice Resets the vault state to Stable under specific conditions.
     * Can be called by owner or EmergencyHandler delegate.
     * Requires a minimum time since the last state change or specific critical state.
     */
    function resetState()
        external
        whenNotPaused
    {
        require(msg.sender == _owner || delegatedRoles[msg.sender] == DelegateRole.EmergencyHandler, "QV: Unauthorized state reset");
        // Example condition: Only allowed if in Critical state or after a long time in another state (simplified check here)
        require(currentState == QuantumState.Critical, "QV: State reset only allowed from Critical state");

        uint8 oldState = uint8(currentState);
        currentState = QuantumState.Stable;

        emit StateChanged(oldState, uint8(currentState), "State reset by authorized user");
    }

    /**
     * @notice Returns the current internal 'Quantum State'.
     */
    function getState() external view returns (QuantumState) {
        return currentState;
    }

    // 4. Fund Management Functions

    /**
     * @notice Allows users to deposit Ether into the vault.
     * Vault state might influence deposit behavior in future versions (e.g., rejecting in Critical state), but simple deposit for now.
     */
    receive() external payable whenNotPaused {
        require(msg.value > 0, "QV: Deposit amount must be greater than zero");
        // Add state checks if needed, e.g., require(currentState != QuantumState.Critical, "QV: Deposits paused in Critical state");
        emit DepositMade(msg.sender, msg.value);
    }

    /**
     * @notice Allows the owner to withdraw Ether.
     * Subject to current state's withdrawal multiplier, temporal lock, and personal fund locks.
     * Cannot withdraw locked funds before unlock time.
     * Cannot withdraw if temporal lock is active and state is above Fluctuating (example logic).
     * @param amount The amount of Ether to withdraw.
     */
    function withdrawETH(uint256 amount) external onlyOwner whenNotPaused {
        uint256 contractBalance = address(this).balance;
        require(amount > 0 && amount <= contractBalance, "QV: Invalid withdrawal amount");

        // Apply state-dependent withdrawal multiplier (cannot exceed 100% of available balance except maybe in special states with explicit logic)
        // Note: Multiplier > 100% logic would require complex accounting/rewards, simplifying to max 100% for standard withdrawal.
        uint256 multiplier = stateWithdrawalMultipliers[uint8(currentState)];
        uint256 maxWithdrawableByState = (amount * multiplier) / 10000; // Scaled by 10000 basis points
        amount = amount > maxWithdrawableByState ? maxWithdrawableByState : amount;
        require(amount > 0 || multiplier > 0, "QV: Withdrawal not allowed in current state"); // Ensure some amount is allowed or multiplier is positive

        // Check personal locked funds
        require(amount <= (contractBalance - userLockedFunds[msg.sender].amount), "QV: Cannot withdraw locked funds");

        // Check temporal lock - example: restricts withdrawal if state is Entangled or Critical and temporal lock is active
        if (temporalLockEndTime > block.timestamp && (currentState == QuantumState.Entangled || currentState == QuantumState.Critical)) {
             require(false, "QV: Withdrawal restricted during temporal lock in this state");
        }

        // Final checks and transfer
        require(amount <= address(this).balance, "QV: Insufficient contract balance"); // Double check balance

        // Perform the transfer securely
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "QV: ETH transfer failed");

        emit WithdrawalMade(msg.sender, amount, "Standard withdrawal");
    }

    /**
     * @notice Allows a user with EmergencyHandler role or the owner to withdraw bypassing some checks.
     * This action incurs a configurable penalty (reduces amount, changes state, etc.).
     * @param amount The amount of Ether to attempt emergency withdrawal.
     */
    function emergencyWithdraw(uint256 amount)
        external
        whenNotPaused
    {
        require(msg.sender == _owner || delegatedRoles[msg.sender] == DelegateRole.EmergencyHandler, "QV: Unauthorized emergency withdrawal");
        uint256 contractBalance = address(this).balance;
        require(amount > 0 && amount <= contractBalance, "QV: Invalid emergency withdrawal amount");

        // Apply penalty
        uint256 penaltyAmount = (amount * emergencyWithdrawalPenaltyBasisPoints) / 10000;
        uint256 actualAmount = amount - penaltyAmount;

        require(actualAmount > 0, "QV: Amount too small after penalty");

        // Transfer (may bypass temporal lock and user locks, but requires state change)
        (bool success, ) = payable(msg.sender).call{value: actualAmount}("");
        require(success, "QV: Emergency ETH transfer failed");

        // Apply state change penalty
        uint8 oldState = uint8(currentState);
        currentState = stateAfterEmergencyWithdrawal; // Move to Critical or configured state

        emit WithdrawalMade(msg.sender, actualAmount, "Emergency withdrawal (penalized)");
        emit StateChanged(oldState, uint8(currentState), "State changed due to emergency withdrawal");
    }

     /**
     * @notice Allows the owner to sweep small amounts of specified ERC20 tokens sent by mistake.
     * Subject to state restrictions (e.g., only in Stable state).
     * @param tokenAddress The address of the ERC20 token.
     * @param recipient The address to send the tokens to.
     */
    function sweepDust(address tokenAddress, address recipient)
        external
        onlyOwner
        whenNotPaused
        requireState(QuantumState.Stable) // Example restriction: only sweep in Stable state
    {
        require(tokenAddress != address(0), "QV: Invalid token address");
        require(recipient != address(0), "QV: Invalid recipient address");

        // Use low-level call for token transfer robustness
        bytes memory data = abi.encodeWithSelector(bytes4(keccak256("transfer(address,uint256)")), recipient, 0); // Check balance first for 0 check

        // Get token balance
        uint256 tokenBalance;
        (bool successBalance, bytes memory returnDataBalance) = tokenAddress.staticcall(abi.encodeWithSelector(bytes4(keccak256("balanceOf(address)")), address(this)));
        require(successBalance && returnDataBalance.length >= 32, "QV: Failed to get token balance");
        assembly {
            tokenBalance := mload(add(returnDataBalance, 32))
        }

        require(tokenBalance > 0, "QV: No tokens to sweep");

        // Update data with actual balance
        data = abi.encodeWithSelector(bytes4(keccak256("transfer(address,uint256)")), recipient, tokenBalance);

        (bool success, ) = tokenAddress.call(data);
        require(success, "QV: Token sweep failed");

        emit DustSwept(tokenAddress, tokenBalance, recipient);
    }


    // 5. Lock & Time-Based Functions

    /**
     * @notice Allows the owner to lock a specific amount of their *withdrawable* funds
     * within the vault for a specified duration.
     * Adds a personal lock, separate from contract-wide temporal lock.
     * Cannot lock more than the current withdrawable balance (total balance - existing locks).
     * @param amount The amount of Ether to lock.
     * @param duration The duration in seconds from now for the lock.
     */
    function lockFundsFor(uint256 amount, uint256 duration) external onlyOwner whenNotPaused {
        uint256 currentBalance = address(this).balance;
        uint256 currentlyLocked = userLockedFunds[msg.sender].amount;

        require(amount > 0, "QV: Amount to lock must be positive");
        require(duration > 0, "QV: Lock duration must be positive");
        require(amount <= (currentBalance - currentlyLocked), "QV: Cannot lock more than available balance");

        userLockedFunds[msg.sender].amount = currentlyLocked + amount;
        userLockedFunds[msg.sender].unlockTime = block.timestamp + duration;

        emit FundsLocked(msg.sender, amount, userLockedFunds[msg.sender].unlockTime);
    }

    /**
     * @notice Allows the owner to release their locked funds after the lock duration has passed.
     */
    function releaseLockedFunds() external onlyOwner whenNotPaused {
        require(userLockedFunds[msg.sender].amount > 0, "QV: No funds are locked");
        require(block.timestamp >= userLockedFunds[msg.sender].unlockTime, "QV: Lock period has not ended");

        uint256 releasedAmount = userLockedFunds[msg.sender].amount;
        userLockedFunds[msg.sender].amount = 0;
        userLockedFunds[msg.sender].unlockTime = 0;

        emit FundsUnlocked(msg.sender, releasedAmount);
    }

    /**
     * @notice Sets a contract-wide temporal lock, restricting certain actions (defined in function logic)
     * until the specified end timestamp. Only owner or Configurator can set.
     * @param endTime The block timestamp when the temporal lock expires. Must be in the future.
     */
    function setTemporalLock(uint256 endTime)
        external
        whenNotPaused
    {
        require(msg.sender == _owner || delegatedRoles[msg.sender] == DelegateRole.Configurator, "QV: Unauthorized to set temporal lock");
        require(endTime > block.timestamp, "QV: End time must be in the future");
        temporalLockEndTime = endTime;
        emit TemporalLockSet(endTime);
    }

    /**
     * @notice Clears the active contract-wide temporal lock. Only owner or Configurator can clear.
     */
    function clearTemporalLock()
        external
        whenNotPaused
    {
        require(msg.sender == _owner || delegatedRoles[msg.sender] == DelegateRole.Configurator, "QV: Unauthorized to clear temporal lock");
        require(temporalLockEndTime > block.timestamp, "QV: No active temporal lock to clear");
        temporalLockEndTime = 0;
        emit TemporalLockCleared();
    }

     /**
     * @notice Returns information about the owner's currently locked funds within the vault.
     * @return amount The amount of funds currently locked.
     * @return unlockTime The block timestamp when the funds become unlocked (0 if no funds locked).
     */
    function getLockedFundsInfo() external view onlyOwner returns (uint256 amount, uint256 unlockTime) {
        return (userLockedFunds[msg.sender].amount, userLockedFunds[msg.sender].unlockTime);
    }

    /**
     * @notice Returns the block timestamp when the contract's temporal lock expires.
     * Returns 0 if no temporal lock is currently active.
     */
    function getTemporalLockEndTime() external view returns (uint256) {
        return temporalLockEndTime;
    }

    // 6. Probabilistic Access Functions

    /**
     * @notice Allows any user to attempt a withdrawal based on a probability.
     * The success chance is influenced by the current state and configured modifiers.
     * Simulates a feature where access isn't guaranteed but depends on internal contract state.
     * Uses a simple pseudo-randomness based on block data (NOT secure for high value, use Chainlink VRF or similar in production).
     * @param amount The amount of Ether the user wishes to attempt to withdraw.
     */
    function attemptProbabilisticWithdraw(uint256 amount)
        external
        whenNotPaused
        // Example: Only allow probabilistic withdrawals in specific states
        requireMinState(QuantumState.Fluctuating)
    {
        uint256 contractBalance = address(this).balance;
        require(amount > 0 && amount <= contractBalance, "QV: Invalid attempt amount or insufficient balance");

        uint256 successChance = calculateProbabilisticChance();

        // Simple pseudo-randomness - DO NOT use for high value in production
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, amount, successChance, block.gaslimit)));
        uint256 randomValue = randomSeed % 10000; // Value between 0 and 9999

        bool success = randomValue < successChance;
        uint256 actualAmount = 0;

        if (success) {
            actualAmount = amount;
             (bool sent, ) = payable(msg.sender).call{value: actualAmount}("");
             require(sent, "QV: Probabilistic ETH transfer failed");
        }

        emit ProbabilisticWithdrawalAttempt(msg.sender, amount, actualAmount, success, successChance);
    }

     /**
     * @notice Internal helper to calculate the probabilistic success chance based on current state and configuration.
     * @return The success chance in basis points (0-10000).
     */
    function calculateProbabilisticChance() internal view returns (uint256) {
        int256 modifier = probabilisticStateModifiers[uint8(currentState)];
        int256 chance = int256(probabilisticBaseChance) + modifier;

        // Ensure chance is within 0-10000 range (0-100%)
        if (chance < 0) chance = 0;
        if (chance > 10000) chance = 10000;

        return uint256(chance);
    }

    /**
     * @notice Returns the current success chance for a probabilistic withdrawal attempt in basis points (0-10000).
     */
    function getProbabilisticWithdrawChance() external view returns (uint256) {
        return calculateProbabilisticChance();
    }

    /**
     * @notice Configures the base chance and state influence for probabilistic withdrawals.
     * Only owner or Configurator delegate can set.
     * @param baseChance_ Base chance in basis points (0-10000).
     * @param stateModifiers_ Array of modifiers (in basis points) for each state (Stable, Fluctuating, Entangled, Critical).
     */
    function setProbabilisticWithdrawParams(uint256 baseChance_, int256[4] calldata stateModifiers_)
        external
        whenNotPaused
    {
        require(msg.sender == _owner || delegatedRoles[msg.sender] == DelegateRole.Configurator, "QV: Unauthorized to set probabilistic params");
        require(baseChance_ <= 10000, "QV: Base chance cannot exceed 10000");

        probabilisticBaseChance = baseChance_;
        probabilisticStateModifiers[uint8(QuantumState.Stable)] = stateModifiers_[0];
        probabilisticStateModifiers[uint8(QuantumState.Fluctuating)] = stateModifiers_[1];
        probabilisticStateModifiers[uint8(QuantumState.Entangled)] = stateModifiers_[2];
        probabilisticStateModifiers[uint8(QuantumState.Critical)] = stateModifiers_[3];

        emit ConfigurationUpdated("ProbabilisticWithdraw", abi.encode(baseChance_, stateModifiers_));
    }


    // 7. Access Control & Delegation Functions

    /**
     * @notice Assigns a specific role to another address.
     * Roles grant permission to call certain functions. Only owner can delegate.
     * Role 0 is None, 1 is Configurator, 2 is EmergencyHandler.
     * @param delegatee The address to grant the role to.
     * @param role The role to assign (uint8 corresponding to DelegateRole enum).
     */
    function delegateRole(address delegatee, uint8 role) external onlyOwner {
        require(delegatee != address(0), "QV: Cannot delegate to zero address");
        require(delegatee != msg.sender, "QV: Cannot delegate role to self");
        require(role > uint8(DelegateRole.None) && role <= uint8(DelegateRole.EmergencyHandler), "QV: Invalid role");

        delegatedRoles[delegatee] = DelegateRole(role);
        emit RoleDelegated(delegatee, role);
    }

    /**
     * @notice Removes a previously assigned role from an address. Only owner can revoke.
     * @param delegatee The address to revoke the role from.
     */
    function revokeRole(address delegatee) external onlyOwner {
         require(delegatee != address(0), "QV: Invalid delegatee address");
         require(delegatedRoles[delegatee] != DelegateRole.None, "QV: Address has no role to revoke");

         delegatedRoles[delegatee] = DelegateRole.None;
         emit RoleRevoked(delegatee);
    }

     /**
     * @notice Checks if an address has a specific delegated role.
     * @param account The address to check.
     * @return true if the account has the role, false otherwise.
     */
    function hasRole(address account, DelegateRole role) external view returns (bool) {
        return delegatedRoles[account] == role;
    }


    /**
     * @notice Transfers ownership of the contract to a new address.
     * Can only be called by the current owner.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "QV: New owner cannot be the zero address");
        _owner = newOwner;
        emit OwnershipTransferred(msg.sender, newOwner);
    }

    /**
     * @notice Relinquishes ownership of the contract.
     * The contract will no longer have an owner, making some functions inaccessible.
     * Use with extreme caution.
     */
    function renounceOwnership() external onlyOwner {
        _owner = address(0);
        emit OwnershipTransferred(msg.sender, address(0));
    }

    // 8. Configuration Functions

    /**
     * @notice Configures which state transitions are allowed. Only owner or Configurator can set.
     * @param fromState The starting state (uint8).
     * @param toState The target state (uint8).
     * @param allowed True to allow the transition, false to disallow.
     */
    function setAllowedStates(uint8 fromState, uint8 toState, bool allowed)
        external
        whenNotPaused
    {
        require(msg.sender == _owner || delegatedRoles[msg.sender] == DelegateRole.Configurator, "QV: Unauthorized to set state transitions");
        require(fromState > uint8(QuantumState.Uninitialized) && fromState <= uint8(QuantumState.Critical), "QV: Invalid fromState");
        require(toState > uint8(QuantumState.Uninitialized) && toState <= uint8(QuantumState.Critical), "QV: Invalid toState");
        allowedStateTransitions[fromState][toState] = allowed;

         emit ConfigurationUpdated("AllowedStateTransition", abi.encode(fromState, toState, allowed));
    }

    /**
     * @notice Configures how the state affects withdrawal multipliers (in basis points).
     * Only owner or Configurator can set.
     * @param state The state to configure (uint8).
     * @param multiplierBasisPoints The multiplier value in basis points (e.g., 10000 for 100%).
     */
    function setStateWithdrawalMultiplier(uint8 state, uint256 multiplierBasisPoints)
        external
        whenNotPaused
    {
        require(msg.sender == _owner || delegatedRoles[msg.sender] == DelegateRole.Configurator, "QV: Unauthorized to set withdrawal multiplier");
        require(state > uint8(QuantumState.Uninitialized) && state <= uint8(QuantumState.Critical), "QV: Invalid state");
        stateWithdrawalMultipliers[state] = multiplierBasisPoints;

         emit ConfigurationUpdated("StateWithdrawalMultiplier", abi.encode(state, multiplierBasisPoints));
    }

    /**
     * @notice Configures parameters for the emergency withdrawal. Only owner or Configurator can set.
     * @param penaltyBasisPoints The percentage penalty applied to emergency withdrawals (0-10000).
     * @param stateAfterState The state the vault transitions to after an emergency withdrawal (uint8).
     */
    function setEmergencyWithdrawPenalty(uint26 penaltyBasisPoints, uint8 stateAfterState)
        external
        whenNotPaused
    {
         require(msg.sender == _owner || delegatedRoles[msg.sender] == DelegateRole.Configurator, "QV: Unauthorized to set emergency params");
         require(penaltyBasisPoints <= 10000, "QV: Penalty cannot exceed 10000");
         require(stateAfterState > uint8(QuantumState.Uninitialized) && stateAfterState <= uint8(QuantumState.Critical), "QV: Invalid stateAfterState");

         emergencyWithdrawalPenaltyBasisPoints = penaltyBasisPoints;
         stateAfterEmergencyWithdrawal = QuantumState(stateAfterState);

         emit ConfigurationUpdated("EmergencyWithdrawParams", abi.encode(penaltyBasisPoints, stateAfterState));
    }

    /**
     * @notice Sets the address that is authorized to trigger state updates simulating external data.
     * Only owner can set.
     * @param sourceAddress The address of the trusted external source.
     */
    function setTrustedExternalSource(address sourceAddress) external onlyOwner {
        trustedExternalSource = sourceAddress;
        emit ConfigurationUpdated("TrustedExternalSource", abi.encode(sourceAddress));
    }

     /**
     * @notice Simulates an update triggered by external data (e.g., an oracle reading).
     * This function can only be called by the `trustedExternalSource`.
     * The logic here is simplified: the input `externalData` directly influences a state transition attempt.
     * More complex logic could involve threshold checks, historical data, etc.
     * @param externalData A value simulating data from an external source.
     */
    function updateStateFromExternalSource(uint256 externalData)
        external
        whenNotPaused
    {
        require(msg.sender == trustedExternalSource, "QV: Unauthorized external source");
        lastExternalDataValue = externalData;

        // Example logic: If external data is high, attempt to move to Entangled state. If low, try Stable.
        uint8 nextState = uint8(currentState);
        string memory reason = "External data update";

        if (externalData > 5000 && allowedStateTransitions[uint8(currentState)][uint8(QuantumState.Entangled)]) {
             nextState = uint8(QuantumState.Entangled);
             reason = "External data high, attempting Entangled state";
        } else if (externalData < 1000 && allowedStateTransitions[uint8(currentState)][uint8(QuantumState.Stable)]) {
            nextState = uint8(QuantumState.Stable);
            reason = "External data low, attempting Stable state";
        }
        // More complex logic could involve other states and thresholds

        if (nextState != uint8(currentState)) {
            uint8 oldState = uint8(currentState);
            currentState = QuantumState(nextState);
            emit StateChanged(oldState, nextState, reason);
        }
         emit ConfigurationUpdated("LastExternalData", abi.encode(externalData)); // Log the data received
    }


    // 9. Information & Utility Functions

    /**
     * @notice Returns the current ETH balance held by the contract.
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

     /**
     * @notice Returns the balance of a specific ERC20 token held by the contract.
     * Requires token contract to implement standard ERC20 balanceOf.
     * @param tokenAddress The address of the ERC20 token.
     */
    function getTokenBalance(address tokenAddress) external view returns (uint256) {
         require(tokenAddress != address(0), "QV: Invalid token address");
         // Use staticcall for view function
         (bool success, bytes memory returnData) = tokenAddress.staticcall(abi.encodeWithSelector(bytes4(keccak256("balanceOf(address)")), address(this)));
         require(success && returnData.length >= 32, "QV: Failed to get token balance");

         uint256 balance;
         assembly {
             balance := mload(add(returnData, 32))
         }
         return balance;
    }


    /**
     * @notice Returns a summary of key vault configuration parameters.
     * Useful for off-chain monitoring.
     * @return configData A struct containing configuration details.
     */
    function getVaultConfiguration() external view returns (
        struct VaultConfig {
            uint8 currentState;
            bool isPaused;
            uint256 temporalLockEndTime;
            uint256 probabilisticBaseChance;
            int256[4] probabilisticStateModifiers;
            uint256 emergencyWithdrawalPenaltyBasisPoints;
            uint8 stateAfterEmergencyWithdrawal;
            address trustedExternalSource;
            uint256 lastExternalDataValue;
        }
    ) {
        int256[4] memory modifiersArray;
        modifiersArray[0] = probabilisticStateModifiers[uint8(QuantumState.Stable)];
        modifiersArray[1] = probabilisticStateModifiers[uint8(QuantumState.Fluctuating)];
        modifiersArray[2] = probabilisticStateModifiers[uint8(QuantumState.Entangled)];
        modifiersArray[3] = probabilisticStateModifiers[uint8(QuantumState.Critical)];


        return VaultConfig({
            currentState: uint8(currentState),
            isPaused: isVaultPaused,
            temporalLockEndTime: temporalLockEndTime,
            probabilisticBaseChance: probabilisticBaseChance,
            probabilisticStateModifiers: modifiersArray,
            emergencyWithdrawalPenaltyBasisPoints: emergencyWithdrawalPenaltyBasisPoints,
            stateAfterEmergencyWithdrawal: uint8(stateAfterEmergencyWithdrawal),
            trustedExternalSource: trustedExternalSource,
            lastExternalDataValue: lastExternalDataValue
        });
    }

    /**
     * @notice Checks if the contract is currently paused.
     */
    function isPaused() external view returns (bool) {
        return isVaultPaused;
    }

    /**
     * @notice Pauses the contract, preventing most state-changing operations.
     * Only owner can pause.
     */
    function pauseVault() external onlyOwner {
        require(!isVaultPaused, "QV: Vault is already paused");
        isVaultPaused = true;
        emit VaultPaused(msg.sender);
    }

    /**
     * @notice Unpauses the contract, allowing operations again.
     * Only owner can unpause.
     */
    function unpauseVault() external onlyOwner {
        require(isVaultPaused, "QV: Vault is not paused");
        isVaultPaused = false;
        emit VaultUnpaused(msg.sender);
    }
}
```