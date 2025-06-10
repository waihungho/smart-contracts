Okay, here is a Solidity smart contract demonstrating several interesting, advanced, and creative concepts. It focuses on a dynamic, time-decaying, reputation-gated, and fractionalized asset pool with built-in incentives and dynamic fees.

**Core Concepts & Features:**

1.  **Fractionalized Pool Asset ("Shards"):** Represents ownership claims on a pool of underlying assets (ERC20 tokens).
2.  **Time Decay:** The "health" or "lifespan" of the pool decays over time, affecting functionality and fees.
3.  **Reputation System:** Users have an on-chain reputation score. Certain actions (like transfers, withdrawals) require a minimum reputation. Reputation can be earned through positive interactions.
4.  **Maintenance Incentives:** Users can perform "maintenance" (contribute value) to extend the pool's lifespan, earning reputation and a share of accumulated fees.
5.  **Dynamic Fees:** Transfer and withdrawal fees are not fixed but change based on the pool's health/lifespan – lower lifespan means higher fees. Fees are collected in the pool assets.
6.  **Oracle Dependency (Simulated):** Requires an external price feed mechanism to value underlying assets for total pool value calculation and maintenance contributions. A simple interface and registration system are included.
7.  **Access Control:** Uses roles (Owner, OracleManager, Pauser) for sensitive operations.
8.  **Custom ERC20 Facade:** Implements necessary ERC20 functions but adds custom logic (reputation checks, dynamic fees) *without* inheriting or copying a standard OpenZeppelin implementation.

**Disclaimer:** This is a complex design for demonstration purposes. It requires significant testing, auditing, and potentially more robust oracle and fee distribution mechanisms for production use. It also assumes the existence of compatible ERC20 tokens and price feeds.

---

**Outline & Function Summary:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ChronosShards
 * @dev A dynamic, time-decaying, reputation-gated, fractionalized asset pool.
 *
 * Outline:
 * 1. State Variables: Define core data structures for Shards (balances, allowances),
 *    Pool assets, Time Decay parameters, Reputation system, Dynamic Fees, Access Control,
 *    Maintenance Incentives, and Oracle configuration.
 * 2. Events: Announce key state changes (Transfers, Deposits, Withdrawals, Decay,
 *    Reputation updates, Parameter changes, Maintenance).
 * 3. Errors: Define custom errors for clearer failure reasons.
 * 4. Interfaces: Define necessary external interfaces (ERC20, PriceFeed).
 * 5. Modifiers: Implement access control and state check modifiers (ownership, pausing, reputation, pool state).
 * 6. Core Logic - Shards (ERC20-like): Implement balance tracking, transfers (with reputation/fee logic), approvals.
 * 7. Core Logic - Pool Management: Handle deposits and withdrawals of underlying assets.
 * 8. Core Logic - Time Decay: Manage pool lifespan, apply decay, allow maintenance.
 * 9. Core Logic - Reputation: Track and modify user reputation, implement reputation checks.
 * 10. Core Logic - Dynamic Fees & Incentives: Calculate fees based on pool state, accrue and claim maintenance incentives.
 * 11. Oracle Integration: Manage price feed registration and retrieval for USD valuation.
 * 12. Access Controlled Functions: Admin functions for parameter tuning, role management, pausing.
 * 13. View Functions: Provide read-only access to contract state.
 * 14. Internal Helpers: Logic used internally by multiple functions (e.g., applying decay, calculating fees).
 */

/**
 * Function Summaries:
 *
 * 1. constructor(address owner, uint256 initialLifespan, uint256 decayRatePerSecond, address oracleManager, address pauser): Initializes contract parameters and roles.
 *
 * --- Shard (ERC20-like) Functions ---
 * 2. transfer(address recipient, uint256 amount): Transfers Shards, requires sender's minimum reputation, applies dynamic fee.
 * 3. transferFrom(address sender, address recipient, uint256 amount): Transfers Shards using allowance, requires sender's minimum reputation, applies dynamic fee.
 * 4. approve(address spender, uint256 amount): Standard ERC20 approve function.
 * 5. allowance(address owner, address spender) view: Standard ERC20 allowance getter.
 * 6. balanceOf(address account) view: Returns the Shard balance of an account.
 * 7. totalSupply() view: Returns the total supply of Shards.
 *
 * --- Pool Management Functions ---
 * 8. depositUnderlyingAsset(address token, uint256 amount): Deposits specified ERC20 token into the pool.
 * 9. withdrawUnderlyingAsset(address token, uint256 shardAmount): Allows withdrawal of a pro-rata share of a specific pool asset corresponding to burned Shards. Requires minimum reputation, applies dynamic fee.
 * 10. getPoolAssetBalance(address token) view: Returns the balance of a specific ERC20 token in the pool.
 *
 * --- Time Decay & Maintenance Functions ---
 * 11. triggerDecayUpdate(): Public function anyone can call to update the pool's lifespan based on elapsed time. Potentially gas-incentivized in a real system (not implemented here).
 * 12. getCurrentLifespanSeconds() view: Returns the remaining lifespan of the pool in seconds.
 * 13. performMaintenance(address token, uint256 amount): Users provide value in an accepted asset to extend the pool's lifespan, earning reputation and maintenance incentives. Requires minimum reputation.
 *
 * --- Reputation System Functions ---
 * 14. getReputation(address account) view: Returns the reputation score of an account.
 * 15. incrementReputation(address account, uint256 amount) onlyOwner: Increases an account's reputation (protocol function, only owner/admin).
 * 16. decrementReputation(address account, uint256 amount) onlyOwner: Decreases an account's reputation (protocol function, only owner/admin).
 * 17. getMinReputationRequired(string memory actionType) view: Returns the minimum reputation required for a specific action ("transfer", "withdraw", "maintain").
 *
 * --- Dynamic Fee & Incentive Functions ---
 * 18. getDynamicTransferFee(uint256 amount) view: Calculates the dynamic fee for a Shard transfer based on current pool lifespan.
 * 19. getDynamicWithdrawalFee(uint256 amount) view: Calculates the dynamic fee for a withdrawal based on current pool lifespan.
 * 20. claimMaintenanceIncentive(): Allows a user to claim their accumulated maintenance incentives (portion of collected fees).
 * 21. getPendingMaintenanceIncentive(address account) view: Returns the amount of maintenance incentive an account can claim.
 * 22. getAccumulatedFees(address token) view: Returns the total fees collected in a specific token.
 *
 * --- Oracle & Valuation Functions ---
 * 23. registerPriceFeed(address token, address feedAddress) onlyOracleManager: Registers or updates the price feed address for a specific ERC20 token.
 * 24. getAssetPriceUSD(address token) view: Retrieves the latest price for a token from its registered feed (assumed Chainlink PriceFeed interface).
 * 25. getTotalPoolValueUSD() view: Calculates the total USD value of all assets currently in the pool using registered price feeds.
 * 26. getShardValueInUSD(uint256 amount) view: Calculates the USD value of a given amount of Shards based on the total pool value and Shard supply.
 *
 * --- Access Control & Parameter Functions ---
 * 27. setMinReputationRequired(string memory actionType, uint256 minRep) onlyOwner: Sets the minimum reputation required for specified actions.
 * 28. setDecayParameters(uint256 decayRatePerSecond) onlyOwner: Sets the rate at which pool lifespan decays.
 * 29. setFeeParameters(uint256 baseFeeBps, uint256 lifespanSensitivity) onlyOwner: Sets parameters controlling the dynamic fee calculation.
 * 30. setReputationParameters(uint256 maintenanceRepGain, uint256 successfulActionRepCost, uint256 failedActionRepCost) onlyOwner: Sets parameters for how reputation changes during different actions.
 * 31. setOracleManager(address newOracleManager) onlyOwner: Sets the address allowed to manage price feeds.
 * 32. setPauser(address newPauser) onlyOwner: Sets the address allowed to pause/unpause the contract.
 * 33. pause() onlyPauser whenNotPaused: Pauses the contract, preventing most state-changing operations.
 * 34. unpause() onlyPauser whenPaused: Unpauses the contract.
 */
```

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Minimal interfaces to avoid duplicating standard libraries like OpenZeppelin or Chainlink interfaces
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

// Simplified Price Feed interface (assuming a Chainlink-like getLatestPrice function)
interface IPriceFeed {
    function getLatestPrice() external view returns (int256 answer); // Returns price * 10^decimals
    function decimals() external view returns (uint8); // Returns the number of decimals in the price feed answer
}

contract ChronosShards {

    // --- State Variables ---

    // Shard (ERC20-like) State
    string public constant name = "Chronos Shard";
    string public constant symbol = "CSHRD";
    uint8 public constant decimals = 18; // Standard ERC20 decimals
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // Pool State
    mapping(address => uint256) private poolAssetBalances; // Balance of each underlying asset (ERC20) in the pool
    address[] public supportedAssets; // List of assets accepted into the pool
    mapping(address => bool) private isSupportedAsset;

    // Time Decay State
    uint256 public lastDecayUpdateTime; // Timestamp of the last decay update
    uint256 public currentLifespanSeconds; // Remaining lifespan of the pool in seconds
    uint256 public decayRatePerSecond; // Seconds of lifespan lost per second of real time

    // Reputation State
    mapping(address => uint256) private reputation; // Reputation score for each address
    mapping(bytes32 => uint256) private minReputationRequirements; // Min reputation needed for actions (hashed action string => rep)

    // Dynamic Fee State
    uint256 public baseFeeBps; // Base fee in Basis Points (e.g., 10 = 0.1%)
    uint256 public lifespanSensitivity; // Factor determining how much lifespan affects the fee (higher = more sensitive)
    mapping(address => uint256) private accumulatedFees; // Collected fees per token

    // Maintenance Incentive State
    mapping(address => uint256) private maintenanceContributionsUSD; // Total USD value contributed by each maintainer
    uint256 private totalMaintenanceContributionsUSD; // Total USD value contributed across all maintainers
    // Incentives are a share of accumulated fees, calculated pro-rata based on contributions

    // Access Control State
    address public owner;
    address public oracleManager;
    address public pauser;
    bool public paused = false;

    // Oracle State
    mapping(address => address) private priceFeeds; // ERC20 token address => Price Feed address

    // --- Events ---
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Deposit(address indexed token, uint256 amount, address indexed depositor);
    event Withdrawal(address indexed token, uint256 amount, address indexed recipient, uint256 shardAmountBurned);
    event LifespanUpdated(uint256 newLifespan, uint256 decayApplied);
    event ReputationChanged(address indexed account, uint256 oldReputation, uint256 newReputation);
    event MinReputationSet(string actionType, uint256 minRep);
    event FeeParametersSet(uint256 baseFeeBps, uint256 lifespanSensitivity);
    event ReputationParametersSet(uint256 maintenanceRepGain, uint256 successfulActionRepCost, uint256 failedActionRepCost);
    event DecayParametersSet(uint256 decayRatePerSecond);
    event MaintenancePerformed(address indexed account, address indexed token, uint256 amount, uint256 usdValue, uint256 lifespanIncreasedBy);
    event IncentiveClaimed(address indexed account, address indexed token, uint256 amount);
    event PriceFeedRegistered(address indexed token, address indexed feed);
    event OracleManagerSet(address indexed oldManager, address indexed newManager);
    event PauserSet(address indexed oldPauser, address indexed newPauser);
    event Paused(address account);
    event Unpaused(address account);
    event SupportedAssetAdded(address token);


    // --- Errors ---
    error NotOwner();
    error NotOracleManager();
    error NotPauser();
    error Paused();
    error NotPaused();
    error InsufficientReputation(uint256 required, uint256 current);
    error InsufficientBalance(uint256 required, uint256 current);
    error InsufficientAllowance(uint256 required, uint256 current);
    error ZeroAmount();
    error TransferToZeroAddress();
    error WithdrawAmountExceedsShare();
    error PoolLifespanExpired();
    error InvalidActionType();
    error PriceFeedNotRegistered(address token);
    error OraclePriceError();
    error InvalidMaintenanceAmount();
    error AssetNotSupported(address token);


    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier onlyOracleManager() {
        if (msg.sender != oracleManager) revert NotOracleManager();
        _;
    }

    modifier onlyPauser() {
        if (msg.sender != pauser) revert NotPauser();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }

    modifier whenPaused() {
        if (!paused) revert NotPaused();
        _;
    }

    modifier hasMinReputation(string memory actionType) {
        bytes32 actionHash = keccak256(abi.encodePacked(actionType));
        uint256 requiredRep = minReputationRequirements[actionHash];
        if (reputation[msg.sender] < requiredRep) revert InsufficientReputation(requiredRep, reputation[msg.sender]);
        _;
    }

    modifier poolActive() {
        _updateDecay(); // Ensure lifespan is up-to-date
        if (currentLifespanSeconds == 0) revert PoolLifespanExpired();
        _;
    }

    // --- Constructor ---
    constructor(
        address _owner,
        uint256 _initialLifespan,
        uint256 _decayRatePerSecond,
        address _oracleManager,
        address _pauser
    ) {
        if (_owner == address(0)) revert NotOwner();
        owner = _owner;
        oracleManager = _oracleManager;
        pauser = _pauser;
        currentLifespanSeconds = _initialLifespan;
        lastDecayUpdateTime = block.timestamp;
        decayRatePerSecond = _decayRatePerSecond;

        // Set default minimum reputation requirements
        minReputationRequirements[keccak256(abi.encodePacked("transfer"))] = 1; // Basic rep to transfer
        minReputationRequirements[keccak256(abi.encodePacked("withdraw"))] = 10; // Higher rep to withdraw
        minReputationRequirements[keccak256(abi.encodePacked("maintain"))] = 5; // Some rep to maintain
        minReputationRequirements[keccak256(abi.encodePacked("deposit"))] = 0; // No rep needed to deposit

        // Set default fee parameters (e.g., 0.5% base fee, moderate sensitivity)
        baseFeeBps = 50;
        lifespanSensitivity = 1000; // Example: lifespan 0 -> fee = base + sens; lifespan max -> fee = base
    }

    // --- Internal Helpers ---

    /**
     * @dev Updates the pool's lifespan based on elapsed time and decay rate.
     * Should be called before any state-changing operations that depend on lifespan.
     */
    function _updateDecay() internal {
        uint256 timeElapsed = block.timestamp - lastDecayUpdateTime;
        uint256 decayAmount = timeElapsed * decayRatePerSecond;

        if (decayAmount > currentLifespanSeconds) {
            currentLifespanSeconds = 0;
            emit LifespanUpdated(0, decayAmount); // Note: decayApplied might be > currentLifespanSeconds here
        } else {
            currentLifespanSeconds -= decayAmount;
            emit LifespanUpdated(currentLifespanSeconds, decayAmount);
        }
        lastDecayUpdateTime = block.timestamp;
    }

     /**
     * @dev Safely transfers an ERC20 token, reverting on failure.
     */
    function _safeTransfer(address token, address to, uint256 amount) internal {
        bool success = IERC20(token).transfer(to, amount);
        if (!success) {
            // In a real scenario, might introspect revert reason or use events
            revert(); // Or a more specific error
        }
    }

    /**
     * @dev Safely transfers an ERC20 token from, reverting on failure.
     */
    function _safeTransferFrom(address token, address from, address to, uint256 amount) internal {
         bool success = IERC20(token).transferFrom(from, to, amount);
        if (!success) {
            // In a real scenario, might introspect revert reason or use events
            revert(); // Or a more specific error
        }
    }

    /**
     * @dev Adds a supported asset to the list and mapping.
     */
    function _addSupportedAsset(address token) internal {
        if (!isSupportedAsset[token]) {
            isSupportedAsset[token] = true;
            supportedAssets.push(token);
            emit SupportedAssetAdded(token);
        }
    }

    /**
     * @dev Increases an account's reputation.
     */
    function _increaseReputation(address account, uint256 amount) internal {
        uint256 oldRep = reputation[account];
        reputation[account] += amount;
        emit ReputationChanged(account, oldRep, reputation[account]);
    }

    /**
     * @dev Decreases an account's reputation.
     */
    function _decreaseReputation(address account, uint256 amount) internal {
        uint256 oldRep = reputation[account];
        reputation[account] = reputation[account] > amount ? reputation[account] - amount : 0;
        emit ReputationChanged(account, oldRep, reputation[account]);
    }

    // --- Shard (ERC20-like) Functions ---

    /**
     * @notice Transfers Shards, requires sender's minimum reputation, applies dynamic fee.
     * @param recipient The address to transfer to.
     * @param amount The amount of Shards to transfer.
     */
    function transfer(address recipient, uint256 amount)
        external
        whenNotPaused
        poolActive // Decay is checked/applied here
        hasMinReputation("transfer")
        returns (bool)
    {
        if (recipient == address(0)) revert TransferToZeroAddress();
        if (amount == 0) revert ZeroAmount();
        if (_balances[msg.sender] < amount) revert InsufficientBalance(_balances[msg.sender], amount);

        uint256 fee = _getDynamicTransferFee(amount);
        uint256 amountAfterFee = amount - fee;

        // Note: Fees are collected in Shards here, but the design intends
        // fees in underlying assets. This needs refinement or a separate
        // fee collection/conversion mechanism. For simplicity, let's assume
        // fees are collected in Shards which are effectively burned.
        // A better approach would be to collect fees on withdrawals/deposits in assets.
        // Let's rethink fee collection slightly: Fees are calculated on value/amount,
        // but accrue *to the pool's assets* to be distributed later.
        // For transfer/withdrawal, let's make fees directly reduce the amount transferred/withdrawn
        // and the fee amount (in terms of value) is converted to pool assets and added.
        // This requires knowing the shard/asset value relationship which depends on pool/total supply.

        // Re-implementing transfer/withdrawal fees to accrue to the pool asset balances.
        // The fee calculation returns a VALUE. We need to deduct this value equivalent
        // from the amount being transferred/withdrawn, and deposit the value equivalent
        // into the pool in a designated fee token (e.g., WETH, a stablecoin).
        // This adds significant complexity (value conversion, designated fee token).

        // Simpler Approach for Demonstration: Fees are taken proportionally from the Shard amount
        // and are conceptually 'burned' or sent to a zero address.
        // This avoids complex value conversions during every transfer.

        _balances[msg.sender] -= amount;
        _balances[recipient] += amountAfterFee;
        _totalSupply -= fee; // Burn the fee

        // Decrease reputation for successful transfer (configurable)
        _decreaseReputation(msg.sender, minReputationRequirements[keccak256(abi.encodePacked("successful_transfer_rep_cost"))]);


        emit Transfer(msg.sender, recipient, amountAfterFee);
        emit Transfer(msg.sender, address(0), fee); // Emit burn event for fee
        return true;
    }

    /**
     * @notice Transfers Shards from an account using the allowance mechanism.
     * Requires sender's minimum reputation, applies dynamic fee.
     * @param sender The address whose Shards are transferred.
     * @param recipient The address to transfer to.
     * @param amount The amount of Shards to transfer.
     */
    function transferFrom(address sender, address recipient, uint256 amount)
        external
        whenNotPaused
        poolActive
        hasMinReputation("transfer") // Check reputation of msg.sender (the one initiating transferFrom)
        returns (bool)
    {
        if (recipient == address(0)) revert TransferToZeroAddress();
        if (amount == 0) revert ZeroAmount();

        uint256 senderBalance = _balances[sender];
        if (senderBalance < amount) revert InsufficientBalance(senderBalance, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        if (currentAllowance < amount) revert InsufficientAllowance(currentAllowance, amount);

        _allowances[sender][msg.sender] -= amount;

        uint256 fee = _getDynamicTransferFee(amount);
        uint256 amountAfterFee = amount - fee;

        _balances[sender] -= amount;
        _balances[recipient] += amountAfterFee;
        _totalSupply -= fee; // Burn the fee

        // Decrease reputation for successful transfer (configurable)
        // Note: This decreases rep of msg.sender (the spender), not the original sender.
        _decreaseReputation(msg.sender, minReputationRequirements[keccak256(abi.encodePacked("successful_transfer_rep_cost"))]);

        emit Transfer(sender, recipient, amountAfterFee);
        emit Transfer(sender, address(0), fee); // Emit burn event for fee
        return true;
    }

    /**
     * @notice Allows `spender` to withdraw from your account multiple times, up to the `amount`.
     * @param spender The address allowed to spend.
     * @param amount The maximum amount `spender` is allowed to spend.
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Returns the amount of Shards `owner` allowed `spender` to withdraw.
     * @param owner The address of the account that owns the Shards.
     * @param spender The address of the account allowed to spend.
     */
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @notice Returns the Shard balance of a specific account.
     * @param account The address to query the balance for.
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /**
     * @notice Returns the total supply of Shards.
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    // --- Pool Management Functions ---

    /**
     * @notice Adds a supported asset to the list (Owner only).
     * Needs to be called for any token before it can be deposited or used for maintenance.
     * @param token The address of the ERC20 token.
     */
    function addSupportedAsset(address token) external onlyOwner {
        _addSupportedAsset(token);
    }

    /**
     * @notice Deposits a supported ERC20 token into the pool.
     * Mints new Shards proportional to the deposited value relative to the current total pool value.
     * @param token The address of the ERC20 token to deposit.
     * @param amount The amount of the token to deposit.
     */
    function depositUnderlyingAsset(address token, uint256 amount)
        external
        whenNotPaused
        hasMinReputation("deposit") // Check rep for deposit (default 0)
    {
        if (amount == 0) revert ZeroAmount();
        if (!isSupportedAsset[token]) revert AssetNotSupported(token);

        // Ensure decay is updated before calculating shard mint amount
        _updateDecay();

        uint256 currentTotalSupply = _totalSupply;
        uint256 currentTotalPoolValueUSD = getTotalPoolValueUSD(); // Assumes this is up-to-date via oracles

        // Calculate amount of Shards to mint
        uint256 shardsToMint;
        if (currentTotalPoolValueUSD == 0 || currentTotalSupply == 0) {
             // First deposit or pool value was zero (edge case)
             // Mint based on the deposited value relative to a notional initial value
             // Or, more simply for initial deposit, mint a fixed amount or 1:1 ratio
             // Let's assume a simple 1:1 minting for the very first deposit if total supply is 0.
             // For subsequent deposits when total value is 0 (e.g., after full decay),
             // minting should re-bootstrap the supply.
             // This logic is complex; for demonstration, let's assume non-zero total supply/value
             // OR handle the 0 case by minting proportional to USD value against a starting total supply (e.g., 1e18 shards per USD value).
            uint256 depositValueUSD = getAssetPriceUSD(token) * amount / (10**IERC20(token).decimals()); // Crude USD value, assumes 18 decimals for Shards
            // For simplicity, if total supply is 0, mint 1e18 shards per USD of deposit
            if (currentTotalSupply == 0) {
                 shardsToMint = depositValueUSD * (10**decimals);
                 _totalSupply = shardsToMint;
            } else {
                 // Pool value is 0 but supply isn't? This is an error state or post-decay state.
                 // Re-bootstrapping is complex. Revert for now.
                 revert InvalidMaintenanceAmount(); // Using this error for simplicity, logic needed to handle re-bootstrap.
            }

        } else {
             // Calculate the value of the deposited amount in USD
            uint256 depositValueUSD = getAssetPriceUSD(token) * amount / (10**IERC20(token).decimals()); // Crude USD value, assumes 18 decimals for Shards

            // Calculate Shards to mint: (Deposit Value / Total Pool Value) * Total Supply
            // Needs careful handling of fixed-point math. Using simplified math here.
            shardsToMint = (depositValueUSD * currentTotalSupply * (10**decimals)) / currentTotalPoolValueUSD;
            shardsToMint = shardsToMint / (10**decimals); // Adjust for precision

            _totalSupply += shardsToMint;

        }


        // Transfer tokens into the contract
        _safeTransferFrom(token, msg.sender, address(this), amount);
        poolAssetBalances[token] += amount;

        _balances[msg.sender] += shardsToMint;


        emit Deposit(token, amount, msg.sender);
        emit Transfer(address(0), msg.sender, shardsToMint); // Mint event
    }


    /**
     * @notice Allows withdrawal of a pro-rata share of a specific pool asset by burning Shards.
     * Requires minimum reputation, applies dynamic fee.
     * The amount of asset received is proportional to the number of shards burned relative to total supply.
     * @param token The address of the ERC20 token to withdraw.
     * @param shardAmount The amount of Shards to burn to facilitate withdrawal.
     */
    function withdrawUnderlyingAsset(address token, uint256 shardAmount)
        external
        whenNotPaused
        poolActive // Decay is checked/applied here
        hasMinReputation("withdraw")
    {
        if (shardAmount == 0) revert ZeroAmount();
        if (_balances[msg.sender] < shardAmount) revert InsufficientBalance(_balances[msg.sender], shardAmount);
        if (!isSupportedAsset[token]) revert AssetNotSupported(token);
        if (_totalSupply == 0) revert InsufficientBalance(shardAmount, 0); // Cannot withdraw if no shards exist

        // Calculate the amount of the specific asset to withdraw
        uint256 poolBalance = poolAssetBalances[token];
        uint256 totalShards = _totalSupply;

        // Amount to withdraw = (shardAmount / totalShards) * poolBalance
        uint256 assetAmount = (shardAmount * poolBalance) / totalShards;

        if (assetAmount == 0) revert WithdrawAmountExceedsShare(); // Share is too small or pool empty for this asset

        uint256 fee = _getDynamicWithdrawalFee(assetAmount); // Calculate fee based on asset amount
        uint256 assetAmountAfterFee = assetAmount - fee;

        // Transfer asset out of the contract
        _safeTransfer(token, msg.sender, assetAmountAfterFee);
        poolAssetBalances[token] -= assetAmount; // Deduct full amount from pool balance

        // Burn the Shards
        _balances[msg.sender] -= shardAmount;
        _totalSupply -= shardAmount;

        // Collect the fee (add it back to the pool)
        poolAssetBalances[token] += fee; // Fees in this token go back into the pool balance for that token
        accumulatedFees[token] += fee; // Track accumulated fees

        // Decrease reputation for successful withdrawal (configurable)
        _decreaseReputation(msg.sender, minReputationRequirements[keccak256(abi.encodePacked("successful_withdrawal_rep_cost"))]);


        emit Withdrawal(token, assetAmountAfterFee, msg.sender, shardAmount);
        emit Transfer(msg.sender, address(0), shardAmount); // Burn event for shards
        // Emit fee collection? Or assume it's part of the withdrawal event logic.
    }

    /**
     * @notice Returns the balance of a specific ERC20 token held in the pool.
     * @param token The address of the ERC20 token.
     */
    function getPoolAssetBalance(address token) external view returns (uint256) {
        return poolAssetBalances[token];
    }


    // --- Time Decay & Maintenance Functions ---

    /**
     * @notice Public function anyone can call to update the pool's lifespan.
     * This is often done before interacting with features affected by lifespan.
     */
    function triggerDecayUpdate() external {
         _updateDecay();
    }

    /**
     * @notice Returns the remaining lifespan of the pool in seconds.
     */
    function getCurrentLifespanSeconds() external view returns (uint256) {
         uint256 timeElapsed = block.timestamp - lastDecayUpdateTime;
         uint256 decayAmount = timeElapsed * decayRatePerSecond;
         if (decayAmount > currentLifespanSeconds) return 0;
         return currentLifespanSeconds - decayAmount;
    }


    /**
     * @notice Allows users to perform "maintenance" by contributing value in a supported asset.
     * This extends the pool's lifespan and earns the user reputation and future fee incentives.
     * The lifespan increase and rep gain are based on the USD value of the contribution.
     * @param token The supported ERC20 token to contribute.
     * @param amount The amount of the token to contribute.
     */
    function performMaintenance(address token, uint256 amount)
        external
        whenNotPaused
        hasMinReputation("maintain")
    {
        if (amount == 0) revert InvalidMaintenanceAmount();
        if (!isSupportedAsset[token]) revert AssetNotSupported(token);

        // Update decay before calculating lifespan increase
        _updateDecay();

        // Get USD value of the contribution
        uint256 contributionValueUSD = getAssetPriceUSD(token) * amount / (10**IERC20(token).decimals());
        if (contributionValueUSD == 0) revert InvalidMaintenanceAmount(); // Contribution value too small

        // Transfer tokens into the contract
        _safeTransferFrom(token, msg.sender, address(this), amount);
        poolAssetBalances[token] += amount; // Contributions go into the main pool balance

        // Increase lifespan based on USD value (example: 1 USD adds X seconds)
        // Needs a parameter for USD to seconds conversion. Let's add one as owner-settable.
        // For simplicity, let's relate it to the current decay rate: e.g., 1 USD counteracts Y seconds of decay at current rate.
        // Let's add a parameter: `usdValuePerSecondOfLifespan`.
        uint256 usdValuePerSecondOfLifespan = 1e18; // Example: 1 USD adds 1 second (using 18 decimals)
        uint256 lifespanIncrease = (contributionValueUSD * (10**decimals)) / usdValuePerSecondOfLifespan;
        lifespanIncrease = lifespanIncrease / (10**decimals); // Adjust for precision

        currentLifespanSeconds += lifespanIncrease;

        // Increase reputation for maintenance provider
        _increaseReputation(msg.sender, minReputationRequirements[keccak256(abi.encodePacked("maintenance_rep_gain"))]);

        // Track contribution for incentives
        maintenanceContributionsUSD[msg.sender] += contributionValueUSD;
        totalMaintenanceContributionsUSD += contributionValueUSD;


        emit MaintenancePerformed(msg.sender, token, amount, contributionValueUSD, lifespanIncrease);
        emit LifespanUpdated(currentLifespanSeconds, 0); // Indicate increase, 0 decay applied this call
    }

    /**
     * @notice Sets the USD value required to add one second of lifespan (Owner only).
     * @param usdValuePerSecond The USD value required, scaled by 10**18.
     */
    uint256 public usdValuePerSecondOfLifespan = 1e18; // Default: 1 USD per second (scaled)

    function setUsdValuePerSecondOfLifespan(uint256 usdValuePerSecond) external onlyOwner {
         usdValuePerSecondOfLifespan = usdValuePerSecond;
    }


    // --- Reputation System Functions ---

    /**
     * @notice Returns the reputation score of an account.
     * @param account The address to query reputation for.
     */
    function getReputation(address account) external view returns (uint256) {
        return reputation[account];
    }

    /**
     * @notice Increases an account's reputation (Protocol function, Owner only).
     * @param account The address whose reputation to increase.
     * @param amount The amount to increase reputation by.
     */
    function incrementReputation(address account, uint256 amount) external onlyOwner {
         _increaseReputation(account, amount);
    }

    /**
     * @notice Decreases an account's reputation (Protocol function, Owner only).
     * @param account The address whose reputation to decrease.
     * @param amount The amount to decrease reputation by.
     */
    function decrementReputation(address account, uint256 amount) external onlyOwner {
        _decreaseReputation(account, amount);
    }

    /**
     * @notice Returns the minimum reputation required for a specific action.
     * Valid action types: "transfer", "withdraw", "maintain", "deposit", "successful_transfer_rep_cost", "successful_withdrawal_rep_cost", "failed_action_rep_cost", "maintenance_rep_gain".
     * @param actionType The type of action ("transfer", "withdraw", etc.).
     */
    function getMinReputationRequired(string memory actionType) external view returns (uint256) {
        return minReputationRequirements[keccak256(abi.encodePacked(actionType))];
    }

    // --- Dynamic Fee & Incentive Functions ---

    /**
     * @dev Calculates the dynamic fee for a Shard transfer.
     * Fee increases as lifespan decreases.
     * @param amount The amount of Shards being transferred.
     * @return The fee amount in Shards.
     */
    function _getDynamicTransferFee(uint256 amount) internal view returns (uint256) {
        // Calculate fee percentage based on lifespan
        // Example: Fee% = baseFeeBps + lifespanSensitivity / (currentLifespanSeconds + 1)
        // Higher lifespan = lower fee towards baseFeeBps
        // Lower lifespan = higher fee
        uint256 feeBps = baseFeeBps + lifespanSensitivity / (getCurrentLifespanSeconds() + 1);

        // Cap fee percentage (e.g., at 10000 bps = 100%)
        if (feeBps > 10000) feeBps = 10000;

        // Calculate fee amount
        return (amount * feeBps) / 10000; // BPS is parts per 10000
    }

    /**
     * @dev Calculates the dynamic fee for an asset withdrawal.
     * Fee increases as lifespan decreases.
     * @param amount The amount of the asset being withdrawn.
     * @return The fee amount in the asset's smallest unit.
     */
     function _getDynamicWithdrawalFee(uint256 amount) internal view returns (uint256) {
        // Same fee logic as transfer, applied to asset amount
        uint256 feeBps = baseFeeBps + lifespanSensitivity / (getCurrentLifespanSeconds() + 1);
        if (feeBps > 10000) feeBps = 10000;
        return (amount * feeBps) / 10000;
     }


    /**
     * @notice Calculates the dynamic fee for a Shard transfer.
     * @param amount The amount of Shards being transferred.
     * @return The fee amount in Shards.
     */
     function getDynamicTransferFee(uint256 amount) external view returns (uint256) {
         return _getDynamicTransferFee(amount);
     }

    /**
     * @notice Calculates the dynamic fee for an asset withdrawal.
     * @param amount The amount of the asset being withdrawn.
     * @return The fee amount in the asset's smallest unit.
     */
     function getDynamicWithdrawalFee(uint256 amount) external view returns (uint256) {
         return _getDynamicWithdrawalFee(amount);
     }


    /**
     * @notice Allows a user who has performed maintenance to claim their share of accumulated fees.
     * Claimable amount is proportional to their USD maintenance contributions relative to total contributions.
     */
    function claimMaintenanceIncentive() external whenNotPaused poolActive {
        uint256 contributorUSD = maintenanceContributionsUSD[msg.sender];
        if (contributorUSD == 0) revert InvalidMaintenanceAmount(); // No contributions recorded

        // Calculate claimable share for each asset
        for (uint i = 0; i < supportedAssets.length; i++) {
            address token = supportedAssets[i];
            uint256 totalFeesInToken = accumulatedFees[token];
            if (totalFeesInToken == 0) continue;

            // Claimable amount in this token = (contributorUSD / totalMaintenanceContributionsUSD) * totalFeesInToken
            // Needs careful fixed-point math, simplified here.
            // Assuming 18 decimals for USD value tracking.
             uint256 claimableAmount = (contributorUSD * totalFeesInToken * (10**decimals)) / (totalMaintenanceContributionsUSD * (10**decimals));
             claimableAmount = claimableAmount / (10**decimals); // Adjust for precision

            if (claimableAmount > 0) {
                // Reduce accumulated fees to prevent double claiming
                accumulatedFees[token] -= claimableAmount;
                // Transfer incentive
                _safeTransfer(token, msg.sender, claimableAmount);
                emit IncentiveClaimed(msg.sender, token, claimableAmount);
            }
        }
         // Note: This simplistic approach means totalMaintenanceContributionsUSD needs to be adjusted
         // after claims or handle edge cases where totalFeesInToken changes. A more robust system
         // would track unclaimed shares or use checkpointing. For simplicity, we don't reset
         // maintenanceContributionsUSD here, allowing pro-rata claim *of current* fees.
         // This means claiming multiple times gets proportional share of fees collected *since last claim*.
         // Resetting `maintenanceContributionsUSD[msg.sender] = 0;` here would make it claim-once per contribution period.
    }

    /**
     * @notice Returns the amount of maintenance incentive an account can claim across all assets.
     * This requires iterating through supported assets and calculating the pro-rata share.
     * @param account The account to query pending incentives for.
     */
    function getPendingMaintenanceIncentive(address account) external view returns (address[] memory tokens, uint256[] memory amounts) {
        uint256 contributorUSD = maintenanceContributionsUSD[account];
        if (contributorUSD == 0 || totalMaintenanceContributionsUSD == 0) {
            return (new address[](0), new uint256[](0));
        }

        tokens = new address[](supportedAssets.length);
        amounts = new uint256[](supportedAssets.length);
        uint256 count = 0;

        for (uint i = 0; i < supportedAssets.length; i++) {
            address token = supportedAssets[i];
            uint256 totalFeesInToken = accumulatedFees[token];
            if (totalFeesInToken == 0) continue;

             uint256 claimableAmount = (contributorUSD * totalFeesInToken * (10**decimals)) / (totalMaintenanceContributionsUSD * (10**decimals));
             claimableAmount = claimableAmount / (10**decimals); // Adjust for precision

            if (claimableAmount > 0) {
                tokens[count] = token;
                amounts[count] = claimableAmount;
                count++;
            }
        }

        // Return only the valid entries
        assembly {
            mstore(tokens, count)
            mstore(amounts, count)
        }
        return (tokens, amounts);
    }

    /**
     * @notice Returns the total fees collected in a specific token.
     * @param token The address of the ERC20 token.
     */
    function getAccumulatedFees(address token) external view returns (uint256) {
        return accumulatedFees[token];
    }

    // --- Oracle & Valuation Functions ---

    /**
     * @notice Registers or updates the price feed address for a specific ERC20 token (OracleManager only).
     * This token must also be a supported asset for pool interaction.
     * @param token The address of the ERC20 token.
     * @param feedAddress The address of the Price Feed contract implementing IPriceFeed.
     */
    function registerPriceFeed(address token, address feedAddress) external onlyOracleManager {
         if (!isSupportedAsset[token]) revert AssetNotSupported(token);
         priceFeeds[token] = feedAddress;
         emit PriceFeedRegistered(token, feedAddress);
    }

    /**
     * @notice Retrieves the latest price for a token from its registered feed.
     * Returns the price scaled by 10**18 to standardize decimals for calculations.
     * @param token The address of the ERC20 token.
     * @return The price of the token in USD scaled by 10**18.
     */
    function getAssetPriceUSD(address token) public view returns (uint256) {
        address feedAddress = priceFeeds[token];
        if (feedAddress == address(0)) revert PriceFeedNotRegistered(token);

        IPriceFeed feed = IPriceFeed(feedAddress);
        int256 price = feed.getLatestPrice();
        uint8 feedDecimals = feed.decimals();

        if (price <= 0) revert OraclePriceError();

        // Scale price to 18 decimals for consistent calculations
        if (feedDecimals < 18) {
            return uint256(price) * (10**(18 - feedDecimals));
        } else if (feedDecimals > 18) {
             return uint256(price) / (10**(feedDecimals - 18));
        } else {
            return uint256(price);
        }
    }

    /**
     * @notice Calculates the total USD value of all assets currently in the pool.
     * Relies on registered price feeds. Returns 0 if any supported asset lacks a feed or has zero balance.
     */
    function getTotalPoolValueUSD() public view returns (uint256) {
        uint256 totalValue = 0;
        for (uint i = 0; i < supportedAssets.length; i++) {
            address token = supportedAssets[i];
            uint256 balance = poolAssetBalances[token];
            if (balance > 0) {
                 address feedAddress = priceFeeds[token];
                 if (feedAddress == address(0)) continue; // Skip assets without price feed

                 try IPriceFeed(feedAddress).getLatestPrice() returns (int256 price) {
                     if (price <= 0) continue; // Skip assets with zero/negative price

                     uint8 feedDecimals = IPriceFeed(feedAddress).decimals();
                     // Scale asset balance (which is in token's own decimals) to 18 decimals for value calc
                     uint256 scaledBalance;
                     uint8 tokenDecimals = IERC20(token).decimals(); // Needs another external call if not stored
                     // Let's assume all supported tokens have 18 decimals for simplicity or need to fetch this.
                     // For a real contract, you'd fetch token decimals or require them to be 18.
                     // Assuming all supported tokens have 18 decimals for now.
                     if (tokenDecimals < 18) scaledBalance = balance * (10**(18 - tokenDecimals));
                     else if (tokenDecimals > 18) scaledBalance = balance / (10**(tokenDecimals - 18));
                     else scaledBalance = balance;


                     uint256 assetValue = (scaledBalance * uint256(price) / (10**18)); // Value in USD * 10^18 (assuming price is scaled to 18)
                     totalValue += assetValue;

                 } catch {
                     continue; // Skip if price feed call fails
                 }
            }
        }
        return totalValue; // Value is scaled by 10^18
    }


    /**
     * @notice Calculates the estimated USD value of a given amount of Shards.
     * Based on the current total pool value and total Shard supply.
     * Returns 0 if total supply or total pool value is 0.
     * @param amount The amount of Shards.
     * @return The estimated USD value scaled by 10**18.
     */
    function getShardValueInUSD(uint256 amount) public view returns (uint256) {
        uint256 currentTotalSupply = _totalSupply;
        if (currentTotalSupply == 0) return 0;

        uint256 currentTotalPoolValueUSD = getTotalPoolValueUSD(); // Scaled by 10^18

        // Value = (amount / total supply) * total pool value
        // Needs careful fixed-point math. Assuming Shard decimals is 18.
        // Amount is in Shard decimals (18). Total supply is in Shard decimals (18).
        // Total pool value is in USD scaled by 10^18.

        // amount * totalPoolValueUSD / totalSupply
        // (amount * 10^18) * (totalPoolValueUSD * 10^18) / (totalSupply * 10^18) -- wrong scaling
        // Correct scaling: (amount * totalPoolValueUSD) / totalSupply
        // amount (10^18) * totalPoolValueUSD (10^18) / totalSupply (10^18) = Result (10^18)
        return (amount * currentTotalPoolValueUSD) / currentTotalSupply;
    }

    /**
     * @notice Calculates the USD value needed to counteract one second of decay at the current rate.
     * Useful for users estimating maintenance cost.
     * @return The USD value scaled by 10**18.
     */
    function getRequiredMaintenanceValueUSD() external view returns (uint256) {
        // Decay per second is `decayRatePerSecond` seconds of lifespan.
        // Lifespan increase per USD value (scaled 10^18) is 1 second / usdValuePerSecondOfLifespan (scaled 10^18)
        // Need USD value to increase lifespan by `decayRatePerSecond` seconds.
        // Value = decayRatePerSecond * usdValuePerSecondOfLifespan
        return decayRatePerSecond * usdValuePerSecondOfLifespan; // This multiplication needs care if numbers are large
    }

    // --- Access Control & Parameter Functions ---

    /**
     * @notice Sets the minimum reputation required for specified actions (Owner only).
     * @param actionType The type of action ("transfer", "withdraw", etc.).
     * @param minRep The minimum reputation score required.
     */
    function setMinReputationRequired(string memory actionType, uint256 minRep) external onlyOwner {
        bytes32 actionHash = keccak256(abi.encodePacked(actionType));
        // Validate action type? Not strictly necessary if allowing arbitrary types for future use.
        minReputationRequirements[actionHash] = minRep;
        emit MinReputationSet(actionType, minRep);
    }

    /**
     * @notice Sets the rate at which pool lifespan decays per second (Owner only).
     * @param _decayRatePerSecond The new decay rate in seconds per second.
     */
    function setDecayParameters(uint256 _decayRatePerSecond) external onlyOwner {
        decayRatePerSecond = _decayRatePerSecond;
        emit DecayParametersSet(_decayRatePerSecond);
    }

    /**
     * @notice Sets parameters controlling the dynamic fee calculation (Owner only).
     * @param _baseFeeBps The base fee in Basis Points (parts per 10000).
     * @param _lifespanSensitivity Factor determining how much lifespan affects the fee.
     */
    function setFeeParameters(uint256 _baseFeeBps, uint256 _lifespanSensitivity) external onlyOwner {
        baseFeeBps = _baseFeeBps;
        lifespanSensitivity = _lifespanSensitivity;
        emit FeeParametersSet(baseFeeBps, lifespanSensitivity);
    }

     /**
     * @notice Sets parameters for how reputation changes during different actions (Owner only).
     * Requires defining corresponding actionType hashes in getMinReputationRequired for reference.
     * @param _maintenanceRepGain Reputation amount gained per maintenance action.
     * @param _successfulActionRepCost Reputation cost for a successful reputation-gated action (e.g., transfer, withdraw).
     * @param _failedActionRepCost Reputation cost for attempting a reputation-gated action and failing (e.g., insufficient funds/allowance *after* rep check).
     */
    function setReputationParameters(
        uint256 _maintenanceRepGain,
        uint256 _successfulActionRepCost,
        uint256 _failedActionRepCost
    ) external onlyOwner {
        minReputationRequirements[keccak256(abi.encodePacked("maintenance_rep_gain"))] = _maintenanceRepGain;
        minReputationRequirements[keccak256(abi.encodePacked("successful_transfer_rep_cost"))] = _successfulActionRepCost; // Using same cost for transfer/withdrawal success
        minReputationRequirements[keccak256(abi.encodePacked("successful_withdrawal_rep_cost"))] = _successfulActionRepCost;
         minReputationRequirements[keccak256(abi.encodePacked("failed_action_rep_cost"))] = _failedActionRepCost; // Apply on failure *after* rep check? Or failure *of* rep check? Let's apply on failure where reputation might be relevant but isn't the *cause* of failure (e.g., insufficient balance *after* passing rep check).
        emit ReputationParametersSet(_maintenanceRepGain, _successfulActionRepCost, _failedActionRepCost);
    }


    /**
     * @notice Sets the address allowed to manage price feeds (Owner only).
     * @param newOracleManager The new OracleManager address.
     */
    function setOracleManager(address newOracleManager) external onlyOwner {
        address oldOracleManager = oracleManager;
        oracleManager = newOracleManager;
        emit OracleManagerSet(oldOracleManager, newOracleManager);
    }

    /**
     * @notice Sets the address allowed to pause/unpause the contract (Owner only).
     * @param newPauser The new Pauser address.
     */
    function setPauser(address newPauser) external onlyOwner {
        address oldPauser = pauser;
        pauser = newPauser;
        emit PauserSet(oldPauser, newPauser);
    }

    /**
     * @notice Pauses the contract (Pauser only).
     * Prevents most state-changing operations.
     */
    function pause() external onlyPauser whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Unpauses the contract (Pauser only).
     */
    function unpause() external onlyPauser whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }
}
```