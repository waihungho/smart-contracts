Okay, let's design a sophisticated vault contract that dynamically manages assets based on external signals, incorporates complex access control with time locks, and includes built-in risk management features like circuit breakers.

We'll call it `QuantumVault`. It's not a simple ERC20 or NFT, nor a standard staking/lending contract. It combines elements of algorithmic allocation, oracle interaction, granular permissions, and time-based constraints.

**Core Concept:** A vault holding multiple ERC20 tokens that can transfer these tokens to registered "strategy" addresses. The allocation weights for these strategies are dynamically calculated based on data from various oracles (e.g., price, volatility, sentiment). Access to critical functions is governed by a role-based system with optional time locks on changes. A circuit breaker can pause withdrawals under risky conditions.

---

**QuantumVault Smart Contract**

**Outline:**

1.  **Contract Setup:** License, Pragma, Imports, Interfaces.
2.  **State Variables:** Core mappings, arrays, structs, enums for tokens, strategies, oracles, risk, permissions, time locks, shares.
3.  **Events:** Signalling key state changes.
4.  **Modifiers:** Access control (`onlyOwner`, `hasPermission`), time locks (`notTimeLocked`), state checks (`whenNotCircuitBroken`).
5.  **Initialization:** Constructor.
6.  **Token Management:** Add/remove accepted tokens.
7.  **Oracle Management:** Register/unregister various oracle types.
8.  **Strategy Management:** Register/unregister strategy addresses, set dynamic parameters, trigger rebalancing calculation.
9.  **Risk Management:** Set risk parameters, activate/deactivate circuit breaker.
10. **Fund Management:** Deposit, withdraw, execute strategy allocation (transfer funds out).
11. **Access Control & Time Locks:** Set/revoke permission roles, set time locks for addresses/actions.
12. **View Functions:** Get various state parameters, calculate vault value, check status.

**Function Summary:**

*   `constructor()`: Initializes the owner.
*   `addAcceptedToken(address token)`: Adds an ERC20 token to the list of tokens the vault can hold.
*   `removeAcceptedToken(address token)`: Removes an ERC20 token from the list. Requires vault to not hold the token.
*   `registerOracle(bytes32 oracleType, address oracleAddress)`: Registers an oracle contract address for a specific type (e.g., "VOLATILITY", "SENTIMENT", "PRICE").
*   `unregisterOracle(bytes32 oracleType)`: Removes a registered oracle.
*   `setRiskParameters(RiskParameters calldata params)`: Sets global risk thresholds and cooldowns.
*   `registerStrategy(bytes32 strategyId, address strategyAddress, StrategyParams calldata params)`: Registers an external strategy address with associated dynamic parameters and an ID.
*   `unregisterStrategy(bytes32 strategyId)`: Removes a registered strategy. Requires no funds allocated.
*   `setStrategyParametersWithDelay(bytes32 strategyId, StrategyParams calldata params, uint256 delay)`: Sets new parameters for a strategy, but they only take effect after a specified time delay.
*   `triggerStrategyRebalancing()`: Callable by a specific role. Fetches data from registered oracles and recalculates the `currentStrategyWeights` for all strategies based on their `StrategyParams`. **Does not move funds.**
*   `manuallySetStrategyWeights(bytes32[] calldata strategyIds, uint256[] calldata weights)`: Callable by a specific role. Allows manual override of strategy allocation weights. Weights must sum to 10000 (basis points).
*   `executeStrategyAllocation(address tokenAddress)`: Callable by a specific role. Transfers the specified `tokenAddress` held in the vault to the registered strategy addresses according to the `currentStrategyWeights`. Requires tokens to be in the vault.
*   `deposit(address token, uint256 amount)`: Allows a user to deposit an `acceptedToken` into the vault. Mints shares proportionally to the vault's current total value.
*   `withdraw(uint256 shares)`: Allows a user to withdraw tokens by burning shares. Calculates the proportional amount of each token based on current vault value and transfers from the vault's balance. Subject to circuit breaker and user-specific time locks.
*   `sweepUnhandledTokens(address token)`: Allows admin to sweep tokens accidentally sent to the contract that are *not* `acceptedTokens`.
*   `setPermissionRole(address account, PermissionRole role, uint256 timeLockUntil)`: Assigns a specific permission role to an address. An optional `timeLockUntil` can delay when this change takes effect.
*   `revokePermissionRole(address account, uint256 timeLockUntil)`: Revokes all permissions from an address. An optional `timeLockUntil` can delay when this change takes effect.
*   `setTimeLock(bytes32 lockId, uint256 timeLockUntil)`: Sets a generic time lock for a specific identifier (used internally for parameter changes, etc.).
*   `activateCircuitBreaker()`: Callable by a specific role or potentially triggered automatically. Stops all withdrawals and certain state changes.
*   `deactivateCircuitBreaker()`: Callable by a specific role (higher permission than activation). Re-enables withdrawals and state changes.

**View Functions:**

*   `getUserShares(address account)`: Returns the shares held by an account.
*   `getTotalShares()`: Returns the total shares issued.
*   `getVaultValue()`: Calculates the total value of all `acceptedTokens` currently held *directly* by the vault, using registered price oracles. (Note: This does *not* track funds sent *to* strategies; those funds' value must be managed/returned by the strategies themselves).
*   `getAcceptedTokens()`: Returns the list of accepted token addresses.
*   `getStrategyIds()`: Returns the list of registered strategy IDs.
*   `getStrategyParams(bytes32 strategyId)`: Returns the dynamic parameters for a strategy.
*   `getCurrentStrategyWeights(bytes32 strategyId)`: Returns the currently set allocation weight for a strategy.
*   `getOracleAddress(bytes32 oracleType)`: Returns the address of the registered oracle for a type.
*   `getRiskParameters()`: Returns the currently set risk parameters.
*   `getPermissions(address account)`: Returns the permission role of an account.
*   `getTimeLock(bytes32 lockId)`: Returns the unlock timestamp for a specific time lock ID.
*   `isCircuitBreakerActive()`: Returns true if the circuit breaker is active.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Define necessary interfaces for oracles
interface IPriceOracle {
    function getPrice(address token) external view returns (uint256 price); // Price in USD or a common base unit, scaled
    function getVolatility(address token) external view returns (uint256 volatility); // Volatility score, scaled
}

interface ISignalOracle {
    function getSignal(bytes32 signalType) external view returns (uint256 signalValue); // Generic signal value, scaled
}

// --- QuantumVault Smart Contract ---

// Outline:
// 1. Contract Setup: License, Pragma, Imports, Interfaces.
// 2. State Variables: Core mappings, arrays, structs, enums for tokens, strategies, oracles, risk, permissions, time locks, shares.
// 3. Events: Signalling key state changes.
// 4. Modifiers: Access control (onlyOwner, hasPermission), time locks (notTimeLocked), state checks (whenNotCircuitBroken).
// 5. Initialization: Constructor.
// 6. Token Management: Add/remove accepted tokens.
// 7. Oracle Management: Register/unregister various oracle types.
// 8. Strategy Management: Register/unregister strategy addresses, set dynamic parameters, trigger rebalancing calculation.
// 9. Risk Management: Set risk parameters, activate/deactivate circuit breaker.
// 10. Fund Management: Deposit, withdraw, execute strategy allocation (transfer funds out).
// 11. Access Control & Time Locks: Set/revoke permission roles, set time locks for addresses/actions.
// 12. View Functions: Get various state parameters, calculate vault value, check status.

// Function Summary:
// constructor()
// addAcceptedToken(address token)
// removeAcceptedToken(address token)
// registerOracle(bytes32 oracleType, address oracleAddress)
// unregisterOracle(bytes32 oracleType)
// setRiskParameters(RiskParameters calldata params)
// registerStrategy(bytes32 strategyId, address strategyAddress, StrategyParams calldata params)
// unregisterStrategy(bytes32 strategyId)
// setStrategyParametersWithDelay(bytes32 strategyId, StrategyParams calldata params, uint256 delay)
// triggerStrategyRebalancing()
// manuallySetStrategyWeights(bytes32[] calldata strategyIds, uint256[] calldata weights)
// executeStrategyAllocation(address tokenAddress)
// deposit(address token, uint256 amount)
// withdraw(uint256 shares)
// sweepUnhandledTokens(address token)
// setPermissionRole(address account, PermissionRole role, uint256 timeLockUntil)
// revokePermissionRole(address account, uint256 timeLockUntil)
// setTimeLock(bytes32 lockId, uint256 timeLockUntil)
// activateCircuitBreaker()
// deactivateCircuitBreaker()
// getUserShares(address account) (View)
// getTotalShares() (View)
// getVaultValue() (View)
// getAcceptedTokens() (View)
// getStrategyIds() (View)
// getStrategyParams(bytes32 strategyId) (View)
// getCurrentStrategyWeights(bytes32 strategyId) (View)
// getOracleAddress(bytes32 oracleType) (View)
// getRiskParameters() (View)
// getPermissions(address account) (View)
// getTimeLock(bytes32 lockId) (View)
// isCircuitBreakerActive() (View)

contract QuantumVault is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // --- State Variables ---

    // Tokens accepted by the vault
    mapping(address => bool) private _isAcceptedToken;
    address[] private _acceptedTokens;

    // Oracles
    mapping(bytes32 => address) private _oracles; // oracleType => address

    // Strategies
    struct StrategyParams {
        address strategyAddress;
        // Parameters influencing dynamic weight calculation
        uint256 oracleSignalWeight; // How much a specific oracle signal influences weight (e.g., correlation)
        uint256 riskScoreWeight;    // How much a strategy's risk score influences weight (lower risk = higher weight)
        bytes32 primaryOracleType;  // The main oracle type this strategy reacts to
        // Add more parameters for complexity, e.g., performance history weight, fixed base weight
    }
    mapping(bytes32 => StrategyParams) private _strategyParams; // strategyId => parameters
    mapping(bytes32 => uint256) private _currentStrategyWeights; // strategyId => current allocation weight (in basis points, 10000 = 100%)
    bytes32[] private _strategyIds; // List of registered strategy IDs

    // Risk Management
    struct RiskParameters {
        uint256 volatilityThreshold; // If total vault value volatility exceeds this, trigger potential circuit breaker
        uint256 concentrationThreshold; // Max percentage of total value in a single strategy (currently unused in executeStrategyAllocation, but for future logic)
        uint256 circuitBreakerCooldown; // Time before circuit breaker can be deactivated after activation
    }
    RiskParameters public riskParameters;
    bool private _circuitBreakerActive = false;
    uint256 private _circuitBreakerActivatedTime;

    // Shares
    mapping(address => uint256) private _userShares;
    uint256 private _totalShares;

    // Access Control & Time Locks
    enum PermissionRole {
        NONE,
        DEPOSITOR,
        WITHDRAWER,
        STRATEGY_MANAGER, // Can trigger rebalancing, set manual weights, execute allocation
        RISK_MANAGER,     // Can set risk parameters, activate/deactivate circuit breaker
        ORACLE_MANAGER,   // Can register/unregister oracles
        ADMIN             // Can manage accepted tokens, register/unregister strategies, manage roles, bypass most time locks
    }
    mapping(address => PermissionRole) private _permissions;
    mapping(bytes32 => uint256) private _timeLocks; // lockId => unlockTimestamp

    // --- Events ---

    event TokenAccepted(address indexed token);
    event TokenRemoved(address indexed token);
    event OracleRegistered(bytes32 indexed oracleType, address indexed oracleAddress);
    event OracleUnregistered(bytes32 indexed oracleType);
    event RiskParametersSet(RiskParameters params);
    event StrategyRegistered(bytes32 indexed strategyId, address indexed strategyAddress);
    event StrategyUnregistered(bytes32 indexed strategyId);
    event StrategyParametersSet(bytes32 indexed strategyId, StrategyParams params, uint256 effectiveTimestamp);
    event StrategyRebalancingTriggered(address indexed caller);
    event StrategyWeightsUpdated(bytes32 indexed strategyId, uint256 weight);
    event StrategyAllocationExecuted(address indexed token, bytes32 indexed strategyId, uint256 amountTransferred);
    event Deposited(address indexed user, address indexed token, uint256 amount, uint256 sharesMinted);
    event Withdrew(address indexed user, address indexed token, uint256 amount, uint256 sharesBurned);
    event UnhandledTokensSwept(address indexed token, uint256 amount);
    event PermissionRoleSet(address indexed account, PermissionRole role, uint256 effectiveTimestamp);
    event PermissionRoleRevoked(address indexed account, uint256 effectiveTimestamp);
    event TimeLockSet(bytes32 indexed lockId, uint256 unlockTimestamp);
    event CircuitBreakerActivated(uint256 timestamp);
    event CircuitBreakerDeactivated(uint256 timestamp);

    // --- Modifiers ---

    modifier hasPermission(PermissionRole requiredRole) {
        require(_permissions[msg.sender] >= requiredRole, "QV: Insufficient permissions");
        _;
    }

    modifier notTimeLocked(bytes32 lockId) {
        require(block.timestamp >= _timeLocks[lockId], "QV: Action is time locked");
        _;
    }

    modifier whenNotCircuitBroken() {
        require(!_circuitBreakerActive, "QV: Circuit breaker active");
        _;
    }

    modifier whenCircuitBroken() {
        require(_circuitBreakerActive, "QV: Circuit breaker not active");
        _;
    }

    // --- Initialization ---

    constructor() Ownable(msg.sender) {
        // Set initial admin role
        _permissions[msg.sender] = PermissionRole.ADMIN;
        emit PermissionRoleSet(msg.sender, PermissionRole.ADMIN, block.timestamp);

        // Initialize default risk parameters (can be updated later)
        riskParameters = RiskParameters(0, 0, 0);
    }

    // --- Token Management ---

    /// @notice Adds a new token to the list of accepted tokens for deposit/withdrawal.
    /// @param token The address of the ERC20 token to accept.
    function addAcceptedToken(address token) external onlyOwner {
        require(token != address(0), "QV: Zero address");
        require(!_isAcceptedToken[token], "QV: Token already accepted");
        _isAcceptedToken[token] = true;
        _acceptedTokens.push(token);
        emit TokenAccepted(token);
    }

    /// @notice Removes a token from the list of accepted tokens.
    /// @param token The address of the ERC20 token to remove.
    /// @dev Requires the vault balance of this token to be zero.
    function removeAcceptedToken(address token) external onlyOwner {
        require(_isAcceptedToken[token], "QV: Token not accepted");
        require(IERC20(token).balanceOf(address(this)) == 0, "QV: Token balance must be zero");

        _isAcceptedToken[token] = false;
        // Simple removal from dynamic array (inefficient for large arrays)
        for (uint i = 0; i < _acceptedTokens.length; i++) {
            if (_acceptedTokens[i] == token) {
                _acceptedTokens[i] = _acceptedTokens[_acceptedTokens.length - 1];
                _acceptedTokens.pop();
                break;
            }
        }
        emit TokenRemoved(token);
    }

    // --- Oracle Management ---

    /// @notice Registers an oracle contract address for a specific type.
    /// @param oracleType A bytes32 identifier for the oracle type (e.g., keccak256("VOLATILITY_ORACLE")).
    /// @param oracleAddress The address of the oracle contract.
    function registerOracle(bytes32 oracleType, address oracleAddress) external hasPermission(PermissionRole.ORACLE_MANAGER) {
        require(oracleAddress != address(0), "QV: Zero address");
        _oracles[oracleType] = oracleAddress;
        emit OracleRegistered(oracleType, oracleAddress);
    }

    /// @notice Unregisters an oracle contract for a specific type.
    /// @param oracleType The bytes32 identifier for the oracle type.
    function unregisterOracle(bytes32 oracleType) external hasPermission(PermissionRole.ORACLE_MANAGER) {
        require(_oracles[oracleType] != address(0), "QV: Oracle not registered");
        delete _oracles[oracleType];
        emit OracleUnregistered(oracleType);
    }

    // --- Risk Management ---

    /// @notice Sets the global risk parameters for the vault.
    /// @param params The struct containing the new risk parameters.
    function setRiskParameters(RiskParameters calldata params) external hasPermission(PermissionRole.RISK_MANAGER) {
        riskParameters = params;
        emit RiskParametersSet(params);
    }

    /// @notice Activates the circuit breaker, pausing withdrawals and certain state changes.
    /// @dev Can be called manually by RISK_MANAGER or potentially triggered internally.
    function activateCircuitBreaker() external hasPermission(PermissionRole.RISK_MANAGER) whenNotCircuitBroken {
        _circuitBreakerActive = true;
        _circuitBreakerActivatedTime = block.timestamp;
        emit CircuitBreakerActivated(block.timestamp);
    }

    /// @notice Deactivates the circuit breaker.
    /// @dev Requires a cooldown period after activation and higher permission than activation.
    function deactivateCircuitBreaker() external hasPermission(PermissionRole.ADMIN) whenCircuitBroken {
        require(block.timestamp >= _circuitBreakerActivatedTime + riskParameters.circuitBreakerCooldown, "QV: Circuit breaker cooldown active");
        _circuitBreakerActive = false;
        emit CircuitBreakerDeactivated(block.timestamp);
    }

    /// @notice Checks if the current market conditions trigger the circuit breaker based on risk parameters and oracles.
    /// @dev This function does not change state, it's a check. Needs to be called by state-changing functions or an external monitor.
    /// @return bool True if conditions warrant activating the circuit breaker.
    function checkCircuitBreaker() public view returns (bool) {
        // Example check: Check overall vault value volatility
        address volatilityOracleAddress = _oracles[keccak256("VOLATILITY_ORACLE")];
        if (volatilityOracleAddress == address(0)) {
            // Cannot check volatility without the oracle
            return false;
        }
        IPriceOracle volatilityOracle = IPriceOracle(volatilityOracleAddress);
        // This part is hypothetical - getting vault-wide volatility from a single oracle
        // A real implementation might aggregate volatility from underlying assets/strategies
        uint256 currentVaultVolatility = volatilityOracle.getVolatility(address(this)); // Assuming oracle can provide this
        return currentVaultVolatility > riskParameters.volatilityThreshold;

        // Add more complex checks here (e.g., concentration, extreme price drops via price oracles)
    }


    // --- Strategy Management ---

    /// @notice Registers an external strategy address with its ID and parameters.
    /// @param strategyId A unique bytes32 identifier for the strategy.
    /// @param strategyAddress The address of the external contract/address representing the strategy.
    /// @param params The dynamic parameters for this strategy.
    function registerStrategy(bytes32 strategyId, address strategyAddress, StrategyParams calldata params) external onlyOwner {
        require(strategyAddress != address(0), "QV: Zero address");
        require(_strategyParams[strategyId].strategyAddress == address(0), "QV: Strategy ID already registered");

        _strategyParams[strategyId] = params;
        _strategyIds.push(strategyId);
        // Initialize weight to 0
        _currentStrategyWeights[strategyId] = 0;

        emit StrategyRegistered(strategyId, strategyAddress);
    }

    /// @notice Unregisters a strategy.
    /// @param strategyId The ID of the strategy to unregister.
    /// @dev Requires the current allocation weight for this strategy to be zero.
    function unregisterStrategy(bytes32 strategyId) external onlyOwner {
        require(_strategyParams[strategyId].strategyAddress != address(0), "QV: Strategy ID not registered");
        require(_currentStrategyWeights[strategyId] == 0, "QV: Strategy must have zero allocation weight");

        delete _strategyParams[strategyId];
        delete _currentStrategyWeights[strategyId];

        // Simple removal from dynamic array
        for (uint i = 0; i < _strategyIds.length; i++) {
            if (_strategyIds[i] == strategyId) {
                _strategyIds[i] = _strategyIds[_strategyIds.length - 1];
                _strategyIds.pop();
                break;
            }
        }
        emit StrategyUnregistered(strategyId);
    }

    /// @notice Sets new dynamic parameters for a strategy with an optional time delay.
    /// @param strategyId The ID of the strategy.
    /// @param params The new parameters.
    /// @param delay The time in seconds before the new parameters become active.
    function setStrategyParametersWithDelay(bytes32 strategyId, StrategyParams calldata params, uint256 delay) external hasPermission(PermissionRole.STRATEGY_MANAGER) {
        require(_strategyParams[strategyId].strategyAddress != address(0), "QV: Strategy ID not registered");

        bytes32 lockId = keccak256(abi.encodePacked("StrategyParams", strategyId));
        uint256 unlockTime = block.timestamp + delay;
        _timeLocks[lockId] = unlockTime;

        // Store the pending parameters keyed by the lockId
        // This requires a separate mapping to store pending changes, which adds complexity.
        // For simplicity in this example, we'll assume the parameters are set *immediately*
        // but the `triggerStrategyRebalancing` function checks the time lock before *using* them.
        // A better approach would be to store pending changes and apply them after the lock.
        // Let's adjust the modifier and logic slightly. The modifier checks the _timeLocks entry directly.
        // The params are updated immediately, but their *effect* is delayed by the modifier on functions that use them.

        // Set parameters immediately, their usage is gated by notTimeLocked
        _strategyParams[strategyId] = params;

        emit StrategyParametersSet(strategyId, params, unlockTime);
        emit TimeLockSet(lockId, unlockTime);
    }

    /// @notice Triggers the recalculation of strategy allocation weights based on oracles and strategy parameters.
    /// @dev Callable by STRATEGY_MANAGER. Does NOT move funds.
    function triggerStrategyRebalancing() external hasPermission(PermissionRole.STRATEGY_MANAGER) {
        // This is a simplified example. Real-world rebalancing involves complex calculations.
        uint totalWeightingScore = 0;
        mapping(bytes32 => uint256) memory newWeightsBP; // Basis Points (10000 = 100%)

        for (uint i = 0; i < _strategyIds.length; i++) {
            bytes32 strategyId = _strategyIds[i];
            StrategyParams storage params = _strategyParams[strategyId];

            // Check if parameters are time-locked
            bytes32 paramsLockId = keccak256(abi.encodePacked("StrategyParams", strategyId));
            if (block.timestamp < _timeLocks[paramsLockId]) {
                 // Skip this strategy's parameters if they are time-locked, maybe use previous active parameters or a default?
                 // For simplicity, let's just calculate score based on *current* params, but note this might use delayed params.
                 // A robust system needs pending parameters and activation logic.
            }

            // Fetch data from primary oracle for this strategy
            address primaryOracleAddress = _oracles[params.primaryOracleType];
            uint256 oracleSignal = 0;
            if (primaryOracleAddress != address(0)) {
                 // Assuming ISignalOracle or IPriceOracle can give a relevant signal based on type
                 // This is a placeholder - real logic needs to know *what* signal to get
                 // Example: If primaryOracleType is "SENTIMENT", call ISignalOracle.getSignal("SENTIMENT_FOR_STRATEGY_X")
                 // If primaryOracleType is "VOLATILITY", call IPriceOracle.getVolatility for relevant asset
                 // This requires a more complex oracle interaction interface/mapping.
                 // Let's assume for simplicity, oracles have a generic `getWeightedSignal(bytes32 strategyId)` function
                 // Oracles must be trusted to implement this correctly.
                 // This is an advanced concept placeholder - actual implementation is complex.
                 // For this example, let's fetch a generic signal and apply weights.
                 if (primaryOracleAddress != address(0)) {
                      ISignalOracle signalOracle = ISignalOracle(primaryOracleAddress);
                      // Hypothetical call: get signal relevant to this strategy and its type
                      // Need a more specific way to query oracles based on strategy/token.
                      // Simplest: oracles provide a score 0-10000.
                      // Let's assume primaryOracleType maps to a generic signal type the oracle understands.
                      try signalOracle.getSignal(params.primaryOracleType) returns (uint256 signalVal) {
                          oracleSignal = signalVal; // Assume scaled, e.g., 0-10000
                      } catch {
                          // Handle oracle call failure - maybe skip strategy or use default?
                          oracleSignal = 0; // Default to 0 if oracle call fails
                      }
                 }
            }


            // Calculate a weighting score for the strategy
            // This is a simplified formula: Score = (Oracle Signal * Oracle Weight) + (Inverse Risk Score * Risk Weight)
            // Assume Risk Score is also fetched from an oracle or internal calculation, scaled 0-10000 (0 = low risk)
            uint256 strategyRiskScore = 5000; // Placeholder: Assume a default or fetched from Risk Oracle
            address riskOracleAddress = _oracles[keccak256("RISK_ORACLE")];
            if (riskOracleAddress != address(0)) {
                 // Hypothetical call: get risk score for this specific strategy (complex)
                 // Let's assume ISignalOracle provides generic risk scores keyed by strategy ID
                 try ISignalOracle(riskOracleAddress).getSignal(strategyId) returns (uint256 riskVal) {
                     strategyRiskScore = riskVal; // Assume scaled 0-10000
                 } catch {
                     // Handle failure
                 }
            }

            uint256 inverseRiskScore = 10000 > strategyRiskScore ? 10000 - strategyRiskScore : 0; // Higher inverse score for lower risk

            uint256 rawScore = (oracleSignal.mul(params.oracleSignalWeight)).add(inverseRiskScore.mul(params.riskScoreWeight)).div(10000); // Divide by 10000 for scaling weights
            newWeightsBP[strategyId] = rawScore;
            totalWeightingScore = totalWeightingScore.add(rawScore);
        }

        // Normalize weights to sum to 10000 basis points
        if (totalWeightingScore > 0) {
            for (uint i = 0; i < _strategyIds.length; i++) {
                bytes32 strategyId = _strategyIds[i];
                _currentStrategyWeights[strategyId] = newWeightsBP[strategyId].mul(10000).div(totalWeightingScore);
                emit StrategyWeightsUpdated(strategyId, _currentStrategyWeights[strategyId]);
            }
        } else {
             // If total score is 0, maybe reset all weights or keep current? Resetting is safer.
             for (uint i = 0; i < _strategyIds.length; i++) {
                bytes32 strategyId = _strategyIds[i];
                _currentStrategyWeights[strategyId] = 0;
                emit StrategyWeightsUpdated(strategyId, 0);
             }
        }

        // Note: This requires rounding/precision handling. Using SafeMath and basis points helps.
        // Total weight might not be *exactly* 10000 due to rounding. Distribute remainder? Simple approach: ignore small remainder.

        emit StrategyRebalancingTriggered(msg.sender);
    }


    /// @notice Allows manual setting of strategy allocation weights.
    /// @dev Callable by STRATEGY_MANAGER. Weights must be in basis points and sum to 10000. Does NOT move funds.
    function manuallySetStrategyWeights(bytes32[] calldata strategyIds, uint256[] calldata weights) external hasPermission(PermissionRole.STRATEGY_MANAGER) {
        require(strategyIds.length == weights.length, "QV: Mismatch array lengths");
        uint256 totalWeight = 0;
        for (uint i = 0; i < strategyIds.length; i++) {
            require(_strategyParams[strategyIds[i]].strategyAddress != address(0), "QV: Unknown strategy ID");
            _currentStrategyWeights[strategyIds[i]] = weights[i];
            totalWeight = totalWeight.add(weights[i]);
        }
        require(totalWeight == 10000, "QV: Weights must sum to 10000"); // Must sum to 100% (basis points)

        for (uint i = 0; i < strategyIds.length; i++) {
             emit StrategyWeightsUpdated(strategyIds[i], weights[i]);
        }
    }

    /// @notice Executes the allocation of a specific token from the vault to strategies based on current weights.
    /// @dev This function transfers tokens OUT of the vault to the strategy addresses. Getting them back is external.
    /// @param tokenAddress The address of the token to allocate.
    function executeStrategyAllocation(address tokenAddress) external hasPermission(PermissionRole.STRATEGY_MANAGER) {
        require(_isAcceptedToken[tokenAddress], "QV: Not an accepted token");

        uint256 totalTokenBalance = IERC20(tokenAddress).balanceOf(address(this));
        uint256 allocatedAmount = 0;

        for (uint i = 0; i < _strategyIds.length; i++) {
            bytes32 strategyId = _strategyIds[i];
            StrategyParams storage params = _strategyParams[strategyId];
            uint256 targetWeight = _currentStrategyWeights[strategyId];

            if (targetWeight > 0) {
                uint256 amountToTransfer = totalTokenBalance.mul(targetWeight).div(10000);
                if (amountToTransfer > 0) {
                     // Transfer funds to the strategy address
                    IERC20(tokenAddress).safeTransfer(params.strategyAddress, amountToTransfer);
                    allocatedAmount = allocatedAmount.add(amountToTransfer);
                    emit StrategyAllocationExecuted(tokenAddress, strategyId, amountToTransfer);
                }
            }
        }
        // Note: Any unallocated amount (due to rounding or total weight < 10000) remains in the vault.
    }

    // --- Fund Management ---

    /// @notice Allows users to deposit accepted tokens into the vault and receive shares.
    /// @param token The address of the token to deposit.
    /// @param amount The amount of tokens to deposit.
    function deposit(address token, uint256 amount) external whenNotCircuitBroken {
        require(_isAcceptedToken[token], "QV: Not an accepted token");
        require(amount > 0, "QV: Deposit amount must be > 0");

        // Calculate shares to mint
        uint256 currentVaultValue = getVaultValue();
        uint256 sharesMinted;

        if (_totalShares == 0 || currentVaultValue == 0) {
            // First deposit or vault value is zero (shouldn't happen if tokens are accepted)
            // Assuming initial price is based on the first token deposited
            // For simplicity, assume first depositor gets shares == amount (scaled)
            // A real vault uses price oracles for first deposit share calculation
            // Let's simplify: If total shares are 0, 1 share = 1 unit of vault value (requires 1 token price)
            // A better way: Use a reference token or assume initial value per share is fixed (e.g., 1 unit)
            // Let's use a simple 1:1 ratio for the very first deposit of *any* token (requires trust or a base unit)
             if (_totalShares == 0) {
                // Simplified initial share issuance: 1 share = 1 unit of deposit token value at Oracle price
                address priceOracleAddress = _oracles[keccak256("PRICE_ORACLE")];
                require(priceOracleAddress != address(0), "QV: Price oracle not set for initial deposit value");
                IPriceOracle priceOracle = IPriceOracle(priceOracleAddress);
                uint256 tokenPrice = priceOracle.getPrice(token); // Price scaled, e.g., 1e18 USD per token
                require(tokenPrice > 0, "QV: Invalid token price from oracle");
                // Value of deposit = amount * tokenPrice
                // Shares = Value of deposit / (InitialValuePerShare or current ValuePerShare)
                // Let's assume initial ValuePerShare is 1e18.
                uint256 depositValue = amount.mul(tokenPrice).div(1e18); // Value in base unit
                require(depositValue > 0, "QV: Deposit value too low");
                sharesMinted = depositValue; // 1 share represents 1 base unit value
            } else {
                // Shares = (amount * tokenPrice * totalShares) / totalVaultValue
                address priceOracleAddress = _oracles[keccak256("PRICE_ORACLE")];
                require(priceOracleAddress != address(0), "QV: Price oracle not set");
                IPriceOracle priceOracle = IPriceOracle(priceOracleAddress);
                uint256 tokenPrice = priceOracle.getPrice(token);
                require(tokenPrice > 0, "QV: Invalid token price from oracle");
                uint256 depositValue = amount.mul(tokenPrice).div(1e18);
                 sharesMinted = depositValue.mul(_totalShares).div(currentVaultValue);
            }
        }

        require(sharesMinted > 0, "QV: Deposit amount too low for shares");

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        _userShares[msg.sender] = _userShares[msg.sender].add(sharesMinted);
        _totalShares = _totalShares.add(sharesMinted);

        emit Deposited(msg.sender, token, amount, sharesMinted);
    }


    /// @notice Allows users to withdraw tokens by burning shares.
    /// @param shares The number of shares to burn.
    /// @dev Withdrawals are subject to the circuit breaker and user-specific time locks set via setTimeLock.
    function withdraw(uint256 shares) external hasPermission(PermissionRole.WITHDRAWER) whenNotCircuitBroken {
        require(shares > 0, "QV: Withdraw shares must be > 0");
        require(_userShares[msg.sender] >= shares, "QV: Insufficient shares");

        // Check user-specific time lock for withdrawal
        bytes32 withdrawalLockId = keccak256(abi.encodePacked("WithdrawalLock", msg.sender));
        require(block.timestamp >= _timeLocks[withdrawalLockId], "QV: Withdrawal is time locked for this user");

        uint256 currentVaultValue = getVaultValue();
        require(currentVaultValue > 0, "QV: Vault value is zero");
        require(_totalShares > 0, "QV: Total shares are zero");

        // Calculate proportional amount of each token to withdraw
        // This assumes withdrawals happen from the vault's direct holdings.
        // If funds are in strategies, they must be pulled back first (external step).
        // The amount of each token to return is (user_token_value / total_vault_value) * total_user_value
        // Or simply: User's share of total vault value = (shares / totalShares) * currentVaultValue
        // This total value is distributed proportionally across *all* tokens the vault *currently holds*.

        uint256 userValue = shares.mul(currentVaultValue).div(_totalShares);
        require(userValue > 0, "QV: Calculated withdrawal value too low");

        // This is the complex part: how to give back specific tokens?
        // Simplest: Vault holds ETH/USDC as a reserve and pays out from that? No, doesn't fit concept.
        // Assume user gets a proportional amount of *all* tokens the vault holds *at this moment*.
        // This requires iterating through tokens, calculating their value contribution, and transferring.

        uint256 totalTokensWithdrawnValue = 0;

        address priceOracleAddress = _oracles[keccak256("PRICE_ORACLE")];
        require(priceOracleAddress != address(0), "QV: Price oracle not set for withdrawal calculation");
        IPriceOracle priceOracle = IPriceOracle(priceOracleAddress);


        for (uint i = 0; i < _acceptedTokens.length; i++) {
            address token = _acceptedTokens[i];
            uint256 vaultTokenBalance = IERC20(token).balanceOf(address(this));

            if (vaultTokenBalance > 0) {
                uint256 tokenPrice = priceOracle.getPrice(token);
                require(tokenPrice > 0, "QV: Invalid token price for withdrawal");
                uint256 tokenValueInVault = vaultTokenBalance.mul(tokenPrice).div(1e18); // Value scaled

                // Calculate the amount of THIS token the user gets
                // amount = (userValue * vaultTokenBalance) / currentVaultValue
                uint256 amountToTransfer = userValue.mul(vaultTokenBalance).div(currentVaultValue);

                if (amountToTransfer > 0) {
                    // Ensure vault has enough balance after calculation (should be true if logic is correct)
                     if (IERC20(token).balanceOf(address(this)) < amountToTransfer) {
                         // This indicates a logic error or re-entrancy risk if not careful.
                         // For safety, cap at available balance.
                         amountToTransfer = IERC20(token).balanceOf(address(this));
                         if (amountToTransfer == 0) continue; // Skip if no balance left
                     }

                    IERC20(token).safeTransfer(msg.sender, amountToTransfer);
                    totalTokensWithdrawnValue = totalTokensWithdrawnValue.add(amountToTransfer.mul(tokenPrice).div(1e18));
                    emit Withdrew(msg.sender, token, amountToTransfer, 0); // Emit 0 shares here, total shares burned is emitted once
                }
            }
        }
        // Note: The total value of tokens transferred might not be exactly `userValue` due to rounding and limited vault balances.
        // A more robust system might handle dust or prioritize token distribution.

        _userShares[msg.sender] = _userShares[msg.sender].sub(shares);
        _totalShares = _totalShares.sub(shares);

        emit Withdrew(msg.sender, address(0), totalTokensWithdrawnValue, shares); // Emit total shares burned event
    }

    /// @notice Allows the admin to sweep tokens sent to the contract that are not accepted tokens.
    /// @param token The address of the token to sweep.
    function sweepUnhandledTokens(address token) external onlyOwner {
        require(!_isAcceptedToken[token], "QV: This is an accepted token");
        require(token != address(0), "QV: Cannot sweep zero address");
        require(token != address(this), "QV: Cannot sweep contract's own balance");

        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(token).safeTransfer(owner(), balance);
            emit UnhandledTokensSwept(token, balance);
        }
    }

    // --- Access Control & Time Locks ---

    /// @notice Sets or changes the permission role for an account.
    /// @param account The address whose permissions are being set.
    /// @param role The new role to assign.
    /// @param timeLockUntil The timestamp until which this role change is locked (effective *after* this time). 0 for immediate.
    function setPermissionRole(address account, PermissionRole role, uint256 timeLockUntil) external hasPermission(PermissionRole.ADMIN) {
        require(account != address(0), "QV: Zero address");
        // Prevent revoking owner's ADMIN role unless it's a self-transfer to another ADMIN
        if (account == owner() && role != PermissionRole.ADMIN && msg.sender == owner()) {
             uint256 adminCount = 0;
             // This would require iterating all addresses or tracking admins separately - complex.
             // Simplification: Owner can *always* change their own role without time lock, but cannot set it to NONE if they are the sole admin.
             // Let's enforce: owner can't set their role to NONE.
             require(!(account == owner() && role == PermissionRole.NONE), "QV: Owner cannot revoke own admin role");
        }


        bytes32 lockId = keccak256(abi.encodePacked("RoleChange", account));
        _timeLocks[lockId] = timeLockUntil; // Set the unlock time for this specific role change lock

        // Store the *pending* role change. This needs a separate state variable.
        // struct PendingRoleChange { PermissionRole role; uint256 unlockTime; }
        // mapping(address => PendingRoleChange) private _pendingRoleChanges;
        // This adds significant complexity. Let's simplify: set the role immediately, but gate *usage* with time locks.
        // No, that's not how role changes usually work. A role change takes effect *after* the lock.
        // Let's implement the pending change logic.

        // *** Reverting to simpler logic for function count: set role immediately, use generic time lock mechanism for *certain actions* by that role ***
        // The 'setTimeLock' function becomes the general mechanism.
        // The setPermissionRole *itself* takes effect immediately (or gated by a separate admin approval process).
        // This simplifies state but shifts complexity to how actions check locks.

        // Simplification: `setPermissionRole` changes the role instantly. Time locking specific *actions* for that role is handled by `setTimeLock` and specific function checks.

        _permissions[account] = role;
        emit PermissionRoleSet(account, role, block.timestamp);
        // timeLockUntil parameter is unused in this simplified version of setPermissionRole, but kept for interface consistency/future upgrade hint.
    }


    /// @notice Revokes all permissions from an account.
    /// @param account The address whose permissions are being revoked.
    /// @param timeLockUntil The timestamp until which this revocation is locked (effective *after* this time). 0 for immediate.
    function revokePermissionRole(address account, uint256 timeLockUntil) external hasPermission(PermissionRole.ADMIN) {
         require(account != address(0), "QV: Zero address");
         require(account != owner(), "QV: Cannot revoke owner's role via this function");

         // Simplification: Revocation is instant. TimeLockUntil hints at delayed logic but is not implemented here.
         _permissions[account] = PermissionRole.NONE;
         emit PermissionRoleRevoked(account, block.timestamp);
          // timeLockUntil parameter is unused here.
    }


    /// @notice Sets a generic time lock for a specific identifier.
    /// @dev Used internally to lock parameters, withdrawals for users, etc.
    /// @param lockId A unique bytes32 identifier for the lock (e.g., keccak256(abi.encodePacked("WithdrawalLock", userAddress))).
    /// @param timeLockUntil The timestamp until which the lock is active. 0 removes the lock.
    function setTimeLock(bytes32 lockId, uint256 timeLockUntil) external hasPermission(PermissionRole.ADMIN) {
        _timeLocks[lockId] = timeLockUntil;
        emit TimeLockSet(lockId, timeLockUntil);
    }

    // --- View Functions ---

    /// @notice Returns the number of shares held by an account.
    function getUserShares(address account) external view returns (uint256) {
        return _userShares[account];
    }

    /// @notice Returns the total number of shares issued.
    function getTotalShares() external view returns (uint256) {
        return _totalShares;
    }

    /// @notice Calculates the total value of all accepted tokens held directly by the vault.
    /// @dev Does NOT include value held by strategies. Relies on the PRICE_ORACLE.
    /// @return uint256 The total value in the base unit used by the price oracle (e.g., USD scaled by 1e18).
    function getVaultValue() public view returns (uint256) {
        address priceOracleAddress = _oracles[keccak256("PRICE_ORACLE")];
        require(priceOracleAddress != address(0), "QV: Price oracle not set");
        IPriceOracle priceOracle = IPriceOracle(priceOracleAddress);

        uint256 totalValue = 0;
        for (uint i = 0; i < _acceptedTokens.length; i++) {
            address token = _acceptedTokens[i];
            uint256 balance = IERC20(token).balanceOf(address(this));
            if (balance > 0) {
                uint256 price = priceOracle.getPrice(token);
                if (price > 0) { // Only include tokens with valid price data
                    // Value = balance * price / price_scale (assuming price is scaled like 1e18)
                    totalValue = totalValue.add(balance.mul(price).div(1e18)); // Example scaling
                }
            }
        }
        return totalValue;
    }

    /// @notice Returns the list of accepted token addresses.
    function getAcceptedTokens() external view returns (address[] memory) {
        return _acceptedTokens;
    }

    /// @notice Returns the list of registered strategy IDs.
    function getStrategyIds() external view returns (bytes32[] memory) {
        return _strategyIds;
    }

    /// @notice Returns the dynamic parameters for a specific strategy.
    /// @param strategyId The ID of the strategy.
    function getStrategyParams(bytes32 strategyId) external view returns (StrategyParams memory) {
        require(_strategyParams[strategyId].strategyAddress != address(0), "QV: Unknown strategy ID");
        // Check if parameters are time-locked from recent change (optional, depends on setStrategyParametersWithDelay impl)
        // bytes32 paramsLockId = keccak256(abi.encodePacked("StrategyParams", strategyId));
        // if (block.timestamp < _timeLocks[paramsLockId]) { ... return old params or pending params ... }
        return _strategyParams[strategyId];
    }

    /// @notice Returns the currently set allocation weight for a specific strategy.
    /// @param strategyId The ID of the strategy.
    function getCurrentStrategyWeights(bytes32 strategyId) external view returns (uint256) {
        require(_strategyParams[strategyId].strategyAddress != address(0), "QV: Unknown strategy ID");
        return _currentStrategyWeights[strategyId];
    }

    /// @notice Returns the address of the registered oracle for a specific type.
    /// @param oracleType The bytes32 identifier for the oracle type.
    function getOracleAddress(bytes32 oracleType) external view returns (address) {
        return _oracles[oracleType];
    }

    /// @notice Returns the currently set risk parameters.
    function getRiskParameters() external view returns (RiskParameters memory) {
        return riskParameters;
    }

    /// @notice Returns the permission role of an account.
    function getPermissions(address account) external view returns (PermissionRole) {
        return _permissions[account];
    }

    /// @notice Returns the unlock timestamp for a specific time lock ID.
    /// @param lockId The bytes32 identifier for the lock.
    function getTimeLock(bytes32 lockId) external view returns (uint256) {
        return _timeLocks[lockId];
    }

    /// @notice Returns true if the circuit breaker is currently active.
    function isCircuitBreakerActive() external view returns (bool) {
        return _circuitBreakerActive;
    }

    // Fallback/Receive to reject direct ETH transfers unless intended
    receive() external payable {
        revert("QV: Receive not supported");
    }

    fallback() external payable {
        revert("QV: Fallback not supported");
    }
}
```