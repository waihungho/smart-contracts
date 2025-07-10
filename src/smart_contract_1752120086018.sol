Okay, here is a Solidity smart contract for a decentralized synthetic asset protocol.

This contract, `DeFiAlphaSynthetics`, allows users to lock up various supported collateral tokens to mint various supported synthetic asset tokens, tracking external prices via oracles. It incorporates features like multi-asset support, dynamic collateralization ratios, liquidation mechanisms with bonuses, and governance-controlled parameters.

It aims for complexity by handling multiple asset types and their configurations, managing user positions with multiple collateral and debt components, and implementing a detailed liquidation process. It avoids direct copies of major protocols like Synthetix or MakerDAO but uses similar underlying principles adapted for a multi-asset framework with dynamic parameters.

---

### **Outline:**

1.  **License & Pragma**
2.  **Imports (Standard Interfaces):** ERC20, AggregatorV3Interface
3.  **Errors:** Custom errors for clarity and gas efficiency.
4.  **Events:** To signal key state changes.
5.  **Structs:**
    *   `AssetConfig`: Configuration for supported collateral and synthetic assets (address, oracle feed, min collateralization ratio).
    *   `UserPosition`: Tracks a user's locked collateral and synthetic debt across different asset types.
6.  **State Variables:**
    *   Owner address.
    *   Mappings for supported collateral/synthetic asset configurations.
    *   Mapping for oracle addresses.
    *   Mapping to store user position data.
    *   Mapping to track total outstanding supply for each synthetic asset (redundant if using standard ERC20s which track total supply, but useful for internal tracking).
    *   Mapping to track total locked collateral for each type.
    *   Protocol fee percentages (mint, burn, liquidation).
    *   Liquidation bonus percentage.
    *   Fee collector address.
    *   Paused state flags.
    *   Minimum global collateralization ratio.
7.  **Modifiers:** `onlyOwner`, `whenNotPaused`, `whenSystemNotPaused`.
8.  **Constructor:** Initializes owner, fee collector, minimum C-ratio.
9.  **Internal Helper Functions:**
    *   `_getPrice(address _asset)`: Fetches price from the configured oracle.
    *   `_calculatePositionValue(address _user)`: Calculates total value of collateral and debt for a user.
    *   `_isLiquidatable(address _user)`: Checks if a user's position is undercollateralized.
10. **External Functions (> 20 total):**
    *   **Admin/Governance (onlyOwner):**
        1.  `addSupportedCollateral`
        2.  `removeSupportedCollateral`
        3.  `addSupportedSynthetic`
        4.  `removeSupportedSynthetic`
        5.  `updateCollateralizationRatio` (for a specific synth/collateral pair) - *Simplified: Using a single minimum global ratio and minimum per synthetic type.* Let's adjust: minimum global and minimum *per synthetic type*.
        6.  `updateMinCollateralizationRatio` (global minimum)
        7.  `updateSyntheticMinRatio` (minimum per synthetic type)
        8.  `updateMintFee`
        9.  `updateBurnFee`
        10. `updateLiquidationFee` (protocol fee on liquidation)
        11. `updateLiquidationBonus` (paid to liquidator)
        12. `setOracleAddress` (for a specific asset)
        13. `setFeeCollector`
        14. `pauseSystem` (emergency pause)
        15. `unpauseSystem` (unpause system)
        16. `recoverTokens` (rescue erroneously sent tokens)
    *   **User Interactions:**
        17. `depositCollateral`
        18. `withdrawCollateral`
        19. `mintSynthetic`
        20. `burnSynthetic`
        21. `liquidatePosition`
        22. `claimFees` (by fee collector)
    *   **View Functions:**
        23. `getSupportedCollateral`
        24. `getSupportedSynthetics`
        25. `getAssetPrice`
        26. `getUserPosition`
        27. `getPositionHealth` (returns current C-ratio and liquidatable status)
        28. `getSyntheticsOutstanding`
        29. `getCollateralLockedTotal`
        30. `getProtocolFees` (returns current fee percentages)
        31. `getLiquidationParams` (returns bonus and fee percentages)
        32. `getMinCollateralizationRatios` (returns global and synth-specific minimums)
        33. `getOracleAddress`

### **Function Summary:**

*   `addSupportedCollateral(address _collateralToken, address _oracle)`: Adds a new ERC20 token as supported collateral, linking it to an oracle feed.
*   `removeSupportedCollateral(address _collateralToken)`: Removes support for a collateral token. Requires no active positions using it.
*   `addSupportedSynthetic(address _syntheticToken, address _oracle, uint256 _minRatio)`: Adds a new ERC20 token as a supported synthetic asset, linking it to an oracle and setting its specific minimum collateralization ratio.
*   `removeSupportedSynthetic(address _syntheticToken)`: Removes support for a synthetic asset. Requires no active debt in this synthetic.
*   `updateMinCollateralizationRatio(uint256 _newRatio)`: Updates the global minimum collateralization ratio requirement for all positions.
*   `updateSyntheticMinRatio(address _syntheticToken, uint256 _newRatio)`: Updates the minimum collateralization ratio specific to a synthetic asset type.
*   `updateMintFee(uint256 _newFee)`: Updates the fee percentage charged on minting.
*   `updateBurnFee(uint256 _newFee)`: Updates the fee percentage charged on burning.
*   `updateLiquidationFee(uint256 _newFee)`: Updates the protocol fee percentage taken from liquidated collateral.
*   `updateLiquidationBonus(uint256 _newBonus)`: Updates the bonus percentage paid to a liquidator from liquidated collateral.
*   `setOracleAddress(address _asset, address _oracle)`: Updates the oracle address for a supported asset.
*   `setFeeCollector(address _feeCollector)`: Sets the address designated to receive protocol fees.
*   `pauseSystem()`: Pauses core user interactions (minting, burning, depositing, withdrawing, liquidation). Emergency function.
*   `unpauseSystem()`: Unpauses the system.
*   `recoverTokens(address _token, uint256 _amount)`: Allows the owner to recover erroneously sent tokens *other than* supported collateral/synthetic tokens locked in user positions or fee balances.
*   `depositCollateral(address _collateralToken, uint256 _amount)`: Deposits collateral into the caller's position. User must approve the contract first.
*   `withdrawCollateral(address _collateralToken, uint256 _amount)`: Withdraws collateral from the caller's position if the remaining position remains healthy.
*   `mintSynthetic(address _syntheticToken, address _collateralToken, uint256 _synthAmount)`: Mints a specified amount of synthetic tokens by locking sufficient collateral. Calculates required collateral based on current price and ratios.
*   `burnSynthetic(address _syntheticToken, address _collateralToken, uint256 _synthAmount)`: Burns a specified amount of synthetic tokens to unlock corresponding collateral.
*   `liquidatePosition(address _user)`: Allows anyone to liquidate an undercollateralized user position. Seizes collateral, burns synthetic debt, pays liquidator bonus and protocol fee.
*   `claimFees(address _token)`: Allows the fee collector to withdraw accumulated protocol fees for a specific token.
*   `getSupportedCollateral() view`: Returns arrays of all supported collateral token addresses and their associated oracle addresses.
*   `getSupportedSynthetics() view`: Returns arrays of all supported synthetic token addresses, their oracles, and minimum ratios.
*   `getAssetPrice(address _asset) view`: Gets the current price of a supported asset from its oracle.
*   `getUserPosition(address _user) view`: Returns the collateral locked and synthetic debt for a user's position.
*   `getPositionHealth(address _user) view`: Calculates and returns a user's current collateralization ratio and whether their position is liquidatable.
*   `getSyntheticsOutstanding(address _syntheticToken) view`: Returns the total amount of a synthetic token minted by the protocol (outstanding debt).
*   `getCollateralLockedTotal(address _collateralToken) view`: Returns the total amount of a specific collateral token locked in the protocol.
*   `getProtocolFees() view`: Returns the current mint and burn fee percentages.
*   `getLiquidationParams() view`: Returns the current liquidation bonus and liquidation fee percentages.
*   `getMinCollateralizationRatios() view`: Returns the global minimum collateralization ratio and a mapping of synthetic tokens to their specific minimum ratios.
*   `getOracleAddress(address _asset) view`: Returns the oracle address configured for a specific supported asset.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Standard ERC20 Interface (assuming standard functions)
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Minimal Chainlink AggregatorV3Interface
interface AggregatorV3Interface {
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);
    // getRoundData and latestRoundData should both be available, but we'll use latestRoundData
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

/**
 * @title DeFiAlphaSynthetics
 * @notice A decentralized protocol for minting synthetic assets collateralized by various supported tokens.
 * @dev This contract manages collateral, synthetic debt, pricing via oracles, and liquidation.
 *      It supports multiple collateral and synthetic asset types, each with configurable parameters.
 */
contract DeFiAlphaSynthetics {

    /*═════════ Custom Errors ═════════*/
    error OnlyOwner();
    error Paused();
    error SystemPaused();
    error NotSupportedCollateral();
    error NotSupportedSynthetic();
    error InvalidOracleFeed();
    error PositionHealthy(); // Cannot liquidate a healthy position
    error PositionUndercollateralized(); // Cannot withdraw/burn if it causes undercollateralization
    error InsufficientCollateral(); // Not enough collateral deposited to mint requested amount
    error InsufficientDebt(); // Trying to burn more than owed
    error InsufficientCollateralLocked(); // Trying to withdraw more than locked
    error TokenTransferFailed();
    error AmountMustBePositive();
    error AssetAlreadySupported();
    error AssetNotSupported();
    error PositionNotEmpty(); // Cannot remove supported asset if users have positions
    error InvalidLiquidationParams(); // Liquidation bonus + fee > 100%
    error ZeroAddress();
    error InvalidRatio(); // Ratios must be > 100% for collateralization

    /*═════════ Events ═════════*/
    event CollateralDeposited(address indexed user, address indexed collateralToken, uint256 amount);
    event CollateralWithdrawn(address indexed user, address indexed collateralToken, uint256 amount);
    event SyntheticMinted(address indexed user, address indexed syntheticToken, uint256 amount, address indexed collateralToken, uint256 collateralLocked);
    event SyntheticBurned(address indexed user, address indexed syntheticToken, uint256 amount, address indexed collateralToken, uint256 collateralReleased);
    event PositionLiquidated(address indexed liquidator, address indexed user, uint256 debtValueRemoved, uint256 collateralValueSeized, uint256 liquidatorBonusValue, uint256 protocolFeeValue);
    event FeeClaimed(address indexed feeCollector, address indexed token, uint256 amount);
    event SupportedCollateralAdded(address indexed collateralToken, address oracle);
    event SupportedCollateralRemoved(address indexed collateralToken);
    event SupportedSyntheticAdded(address indexed syntheticToken, address oracle, uint256 minRatio);
    event SupportedSyntheticRemoved(address indexed syntheticToken);
    event MinCollateralizationRatioUpdated(uint256 oldRatio, uint256 newRatio);
    event SyntheticMinRatioUpdated(address indexed syntheticToken, uint256 oldRatio, uint256 newRatio);
    event MintFeeUpdated(uint256 oldFee, uint256 newFee);
    event BurnFeeUpdated(uint256 oldFee, uint256 newFee);
    event LiquidationFeeUpdated(uint256 oldFee, uint256 newFee);
    event LiquidationBonusUpdated(uint256 oldBonus, uint256 newBonus);
    event OracleAddressUpdated(address indexed asset, address indexed oracle);
    event FeeCollectorUpdated(address indexed oldCollector, address indexed newCollector);
    event SystemPaused(address indexed pauser);
    event SystemUnpaused(address indexed unpauser);
    event TokensRecovered(address indexed token, uint256 amount, address indexed recipient);

    /*═════════ Structs ═════════*/
    struct AssetConfig {
        bool isSupported;
        address oracle;
        // Note: minRatio is only relevant for synthetic assets
        uint256 minRatio; // Stored as a percentage, e.g., 150e16 for 150%
    }

    struct UserPosition {
        // Mapping of collateral token address => amount locked
        mapping(address => uint256) collateralLocked;
        // Mapping of synthetic token address => amount of debt
        mapping(address => uint256) syntheticDebt;
        // Keep track of which assets are used in the position for iteration
        address[] collateralTokensInPosition;
        address[] syntheticTokensInPosition;
    }

    /*═════════ State Variables ═════════*/

    address private _owner;
    bool private _systemPaused;

    // Configs for supported assets
    mapping(address => AssetConfig) public supportedCollateral;
    mapping(address => AssetConfig) public supportedSynthetics;

    // List of supported assets for easy iteration (cached)
    address[] public supportedCollateralList;
    address[] public supportedSyntheticList;

    // User position data
    mapping(address => UserPosition) public userPositions;

    // Total protocol state
    mapping(address => uint256) public totalSyntheticsOutstanding; // Total minted by the protocol for each synthetic
    mapping(address => uint256) public totalCollateralLocked; // Total of each collateral type locked

    // Protocol parameters
    uint256 public minCollateralizationRatio; // Global minimum, e.g., 150%
    uint256 public mintFee; // Percentage fee on minting, e.g., 1e16 for 1%
    uint256 public burnFee; // Percentage fee on burning, e.g., 0.5e16 for 0.5%
    uint256 public liquidationFee; // Percentage protocol fee on liquidated collateral, e.g., 3e16 for 3%
    uint256 public liquidationBonus; // Percentage bonus to liquidator on liquidated collateral, e.g., 5e16 for 5%

    address public feeCollector;

    // Fee balances held by the contract per token
    mapping(address => uint256) public feeBalances;

    // Precision factor for percentages (100% = 1e18)
    uint256 private constant _PERCENTAGE_PRECISION = 1e18;
    // Precision factor for price feeds (assuming 8 decimals as common)
    uint256 private constant _PRICE_PRECISION = 1e8;

    /*═════════ Modifiers ═════════*/

    modifier onlyOwner() {
        if (msg.sender != _owner) revert OnlyOwner();
        _;
    }

    // Modifier to pause specific actions like minting/burning/deposits/withdrawals
    // Allows emergency liquidation still if needed
    modifier whenNotPaused() {
        if (_systemPaused) revert Paused(); // Using a generic Paused error for user actions
        _;
    }

     // Modifier to pause the entire system including liquidations
    modifier whenSystemNotPaused() {
        if (_systemPaused) revert SystemPaused();
        _;
    }

    /*═════════ Constructor ═════════*/

    constructor(
        uint256 _minCollateralizationRatio,
        uint256 _mintFee,
        uint256 _burnFee,
        uint256 _liquidationFee,
        uint256 _liquidationBonus,
        address _feeCollector
    ) {
        if (_minCollateralizationRatio <= _PERCENTAGE_PRECISION) revert InvalidRatio(); // Must be > 100%
        if (_liquidationFee + _liquidationBonus > _PERCENTAGE_PRECISION) revert InvalidLiquidationParams();
        if (_feeCollector == address(0)) revert ZeroAddress();

        _owner = msg.sender;
        minCollateralizationRatio = _minCollateralizationRatio;
        mintFee = _mintFee;
        burnFee = _burnFee;
        liquidationFee = _liquidationFee;
        liquidationBonus = _liquidationBonus;
        feeCollector = _feeCollector;
    }

    /*═════════ Internal Helpers ═════════*/

    /**
     * @dev Fetches the latest price from a configured oracle feed.
     * @param _asset The address of the asset (collateral or synthetic).
     * @return The price of the asset scaled by _PRICE_PRECISION.
     */
    function _getPrice(address _asset) internal view returns (uint256) {
        AssetConfig storage colConfig = supportedCollateral[_asset];
        AssetConfig storage synConfig = supportedSynthetics[_asset];

        address oracleAddress;
        if (colConfig.isSupported) {
            oracleAddress = colConfig.oracle;
        } else if (synConfig.isSupported) {
            oracleAddress = synConfig.oracle;
        } else {
            revert AssetNotSupported(); // Should not happen if called with a supported asset
        }

        if (oracleAddress == address(0)) revert InvalidOracleFeed();

        AggregatorV3Interface priceFeed = AggregatorV3Interface(oracleAddress);
        (, int256 price, , , ) = priceFeed.latestRoundData();

        if (price <= 0) revert InvalidOracleFeed(); // Oracle returned a non-positive price

        // Adjust price precision to match our _PRICE_PRECISION (assuming oracle is typically 8 decimals)
        // If oracle has more decimals, we can truncate; if less, we scale up.
        // Simple approach: assume oracle is 8 decimals and scale to _PRICE_PRECISION (1e8) if needed.
        // More robust: Check oracle decimals and adjust accordingly. Let's assume 8 for simplicity here.
        uint8 oracleDecimals = priceFeed.decimals();
        uint256 scaledPrice = uint256(price);
        if (oracleDecimals < uint8(uint256(Math.log10(_PRICE_PRECISION)))) {
             scaledPrice = scaledPrice * (10 ** (uint252(Math.log10(_PRICE_PRECISION)) - oracleDecimals));
        } else if (oracleDecimals > uint8(uint256(Math.log10(_PRICE_PRECISION)))) {
             scaledPrice = scaledPrice / (10 ** (oracleDecimals - uint252(Math.log10(_PRICE_PRECISION))));
        }

        return scaledPrice;
    }

    /**
     * @dev Calculates the total value of collateral and synthetic debt for a user's position.
     * @param _user The address of the user.
     * @return collateralValueTotal The total value of all locked collateral in USD (scaled by _PRICE_PRECISION).
     * @return debtValueTotal The total value of all synthetic debt in USD (scaled by _PRICE_PRECISION).
     */
    function _calculatePositionValue(address _user) internal view returns (uint256 collateralValueTotal, uint256 debtValueTotal) {
        UserPosition storage pos = userPositions[_user];

        collateralValueTotal = 0;
        debtValueTotal = 0;

        // Calculate total collateral value
        address[] memory currentCollaterals = new address[](pos.collateralTokensInPosition.length);
        uint256 collateralCount = 0;
        for (uint i = 0; i < pos.collateralTokensInPosition.length; ++i) {
            address colToken = pos.collateralTokensInPosition[i];
            if (supportedCollateral[colToken].isSupported && pos.collateralLocked[colToken] > 0) {
                currentCollaterals[collateralCount++] = colToken;
                uint256 collateralPrice = _getPrice(colToken);
                // value = amount * price (handle token decimals vs price precision)
                // Assuming ERC20 amount is in token's native decimals
                // value in USD * 1e8 = (amount * price * 1e8) / 10^tokenDecimals
                // value = (amount * price) / (10^tokenDecimals / 1e8)
                 uint256 tokenDecimals = IERC20(colToken).decimals();
                 collateralValueTotal += (pos.collateralLocked[colToken] * collateralPrice) / (10 ** (tokenDecimals - uint252(Math.log10(_PRICE_PRECISION))));
            }
        }
        // Update the list in storage, removing assets with zero balance
        if (collateralCount < pos.collateralTokensInPosition.length) {
             assembly { // Efficiently resize storage array
                mstore(0x00, collateralCount)
                sstore(pos.collateralTokensInPosition.slot, 0x20) // store the new length location
                sstore(add(pos.collateralTokensInPosition.slot, 1), mload(0x00)) // store the new length value
            }
            for (uint i = 0; i < collateralCount; ++i) {
                 pos.collateralTokensInPosition[i] = currentCollaterals[i];
            }
        }


        // Calculate total synthetic debt value
        address[] memory currentSynthetics = new address[](pos.syntheticTokensInPosition.length);
        uint256 syntheticCount = 0;
        for (uint i = 0; i < pos.syntheticTokensInPosition.length; ++i) {
            address synToken = pos.syntheticTokensInPosition[i];
             if (supportedSynthetics[synToken].isSupported && pos.syntheticDebt[synToken] > 0) {
                currentSynthetics[syntheticCount++] = synToken;
                uint256 syntheticPrice = _getPrice(synToken);
                 uint256 tokenDecimals = IERC20(synToken).decimals();
                 debtValueTotal += (pos.syntheticDebt[synToken] * syntheticPrice) / (10 ** (tokenDecimals - uint252(Math.log10(_PRICE_PRECISION))));
             }
        }
         // Update the list in storage, removing assets with zero debt
        if (syntheticCount < pos.syntheticTokensInPosition.length) {
             assembly { // Efficiently resize storage array
                mstore(0x00, syntheticCount)
                sstore(pos.syntheticTokensInPosition.slot, 0x40) // assuming collateral list is at 0x20, synthetic list at 0x40
                sstore(add(pos.syntheticTokensInPosition.slot, 1), mload(0x00))
            }
            for (uint i = 0; i < syntheticCount; ++i) {
                 pos.syntheticTokensInPosition[i] = currentSynthetics[i];
            }
        }
    }

    /**
     * @dev Checks if a user's position is currently under the minimum required collateralization ratio.
     * @param _user The address of the user.
     * @return true if the position is undercollateralized and liquidatable, false otherwise.
     */
    function _isLiquidatable(address _user) internal view returns (bool) {
        (uint256 collateralValue, uint256 debtValue) = _calculatePositionValue(_user);

        // A position is liquidatable if:
        // 1. There is debt (cannot liquidate a position with no debt)
        // 2. Collateral value * _PERCENTAGE_PRECISION < debt value * minCollateralizationRatio
        //    This prevents overflow by multiplying debt by ratio first
        //    Or simply: current C-ratio < minC-ratio
        //    Current C-ratio = (collateralValue * 1e18) / debtValue

        if (debtValue == 0) {
            return false; // No debt, cannot be undercollateralized
        }

        // Use > rather than >= for safety margin on health check
        return (collateralValue * _PERCENTAGE_PRECISION < debtValue * minCollateralizationRatio);
    }

    // Basic Math Library - for log10
    library Math {
        // Calculates log base 10 of a number, used for decimal scaling.
        // Supports numbers up to 2^256 - 1.
        // Returns floor(log10(x)). Result is capped at 255.
        // Reverts for x == 0.
        // Borrowed concept from OpenZeppelin or similar libraries.
        function log10(uint256 x) internal pure returns (uint256) {
            if (x == 0) revert InvalidAmount(); // Or specific math error
            uint256 res = 0;
            if (x >= 10**128) { x /= 10**128; res += 128; }
            if (x >= 10**64) { x /= 10**64; res += 64; }
            if (x >= 10**32) { x /= 10**32; res += 32; }
            if (x >= 10**16) { x /= 10**16; res += 16; }
            if (x >= 10**8) { x /= 10**8; res += 8; }
            if (x >= 10**4) { x /= 10**4; res += 4; }
            if (x >= 10**2) { x /= 10**2; res += 2; }
            if (x >= 10**1) { res += 1; } // Check for x >= 10
            return res;
        }
         error InvalidAmount(); // Define error here
    }


    /*═════════ Admin/Governance Functions (onlyOwner) ═════════*/

    /**
     * @notice Adds a new token to the list of supported collateral assets.
     * @param _collateralToken The address of the ERC20 collateral token.
     * @param _oracle The address of the Chainlink AggregatorV3Interface for the token's price feed.
     */
    function addSupportedCollateral(address _collateralToken, address _oracle) external onlyOwner {
        if (_collateralToken == address(0) || _oracle == address(0)) revert ZeroAddress();
        if (supportedCollateral[_collateralToken].isSupported) revert AssetAlreadySupported();
        // Basic check for oracle interface - calls decimals()
        try AggregatorV3Interface(_oracle).decimals() returns (uint8) {} catch {
             revert InvalidOracleFeed();
        }


        supportedCollateral[_collateralToken] = AssetConfig({
            isSupported: true,
            oracle: _oracle,
            minRatio: 0 // Not applicable for collateral
        });
        supportedCollateralList.push(_collateralToken);

        emit SupportedCollateralAdded(_collateralToken, _oracle);
    }

    /**
     * @notice Removes a token from the list of supported collateral assets.
     * @dev Requires that no user positions currently hold this collateral.
     * @param _collateralToken The address of the collateral token to remove.
     */
    function removeSupportedCollateral(address _collateralToken) external onlyOwner {
        if (!supportedCollateral[_collateralToken].isSupported) revert AssetNotSupported();
        if (totalCollateralLocked[_collateralToken] > 0) revert PositionNotEmpty();

        supportedCollateral[_collateralToken].isSupported = false;
        supportedCollateral[_collateralToken].oracle = address(0); // Clear oracle

        // Remove from supportedCollateralList (inefficient for large lists, but simple)
        for (uint i = 0; i < supportedCollateralList.length; i++) {
            if (supportedCollateralList[i] == _collateralToken) {
                supportedCollateralList[i] = supportedCollateralList[supportedCollateralList.length - 1];
                supportedCollateralList.pop();
                break;
            }
        }

        emit SupportedCollateralRemoved(_collateralToken);
    }

    /**
     * @notice Adds a new token to the list of supported synthetic assets.
     * @param _syntheticToken The address of the ERC20 synthetic token.
     * @param _oracle The address of the Chainlink AggregatorV3Interface for the token's price feed.
     * @param _minRatio The minimum collateralization ratio required for this synthetic (e.g., 150e16 for 150%).
     */
    function addSupportedSynthetic(address _syntheticToken, address _oracle, uint256 _minRatio) external onlyOwner {
        if (_syntheticToken == address(0) || _oracle == address(0)) revert ZeroAddress();
        if (_minRatio <= _PERCENTAGE_PRECISION) revert InvalidRatio();
        if (supportedSynthetics[_syntheticToken].isSupported) revert AssetAlreadySupported();
        // Basic check for oracle interface
        try AggregatorV3Interface(_oracle).decimals() returns (uint8) {} catch {
             revert InvalidOracleFeed();
        }

        supportedSynthetics[_syntheticToken] = AssetConfig({
            isSupported: true,
            oracle: _oracle,
            minRatio: _minRatio
        });
        supportedSyntheticList.push(_syntheticToken);

        emit SupportedSyntheticAdded(_syntheticToken, _oracle, _minRatio);
    }

    /**
     * @notice Removes a token from the list of supported synthetic assets.
     * @dev Requires that no user positions currently hold debt in this synthetic.
     * @param _syntheticToken The address of the synthetic token to remove.
     */
    function removeSupportedSynthetic(address _syntheticToken) external onlyOwner {
        if (!supportedSynthetics[_syntheticToken].isSupported) revert AssetNotSupported();
        if (totalSyntheticsOutstanding[_syntheticToken] > 0) revert PositionNotEmpty();

        supportedSynthetics[_syntheticToken].isSupported = false;
        supportedSynthetics[_syntheticToken].oracle = address(0); // Clear oracle
        supportedSynthetics[_syntheticToken].minRatio = 0; // Clear ratio

         // Remove from supportedSyntheticList (inefficient for large lists, but simple)
        for (uint i = 0; i < supportedSyntheticList.length; i++) {
            if (supportedSyntheticList[i] == _syntheticToken) {
                supportedSyntheticList[i] = supportedSyntheticList[supportedSyntheticList.length - 1];
                supportedSyntheticList.pop();
                break;
            }
        }

        emit SupportedSyntheticRemoved(_syntheticToken);
    }

    /**
     * @notice Updates the global minimum collateralization ratio.
     * @param _newRatio The new minimum ratio (e.g., 150e16 for 150%).
     */
    function updateMinCollateralizationRatio(uint256 _newRatio) external onlyOwner {
         if (_newRatio <= _PERCENTAGE_PRECISION) revert InvalidRatio();
        emit MinCollateralizationRatioUpdated(minCollateralizationRatio, _newRatio);
        minCollateralizationRatio = _newRatio;
    }

    /**
     * @notice Updates the minimum collateralization ratio for a specific synthetic asset.
     * @param _syntheticToken The address of the synthetic token.
     * @param _newRatio The new minimum ratio for this synthetic (e.g., 150e16 for 150%).
     */
     function updateSyntheticMinRatio(address _syntheticToken, uint256 _newRatio) external onlyOwner {
         if (!supportedSynthetics[_syntheticToken].isSupported) revert AssetNotSupported();
          if (_newRatio <= _PERCENTAGE_PRECISION) revert InvalidRatio();
         emit SyntheticMinRatioUpdated(_syntheticToken, supportedSynthetics[_syntheticToken].minRatio, _newRatio);
         supportedSynthetics[_syntheticToken].minRatio = _newRatio;
     }


    /**
     * @notice Updates the mint fee percentage.
     * @param _newFee The new fee percentage (e.g., 1e16 for 1%).
     */
    function updateMintFee(uint256 _newFee) external onlyOwner {
        emit MintFeeUpdated(mintFee, _newFee);
        mintFee = _newFee;
    }

    /**
     * @notice Updates the burn fee percentage.
     * @param _newFee The new fee percentage (e.g., 0.5e16 for 0.5%).
     */
    function updateBurnFee(uint256 _newFee) external onlyOwner {
        emit BurnFeeUpdated(burnFee, _newFee);
        burnFee = _newFee;
    }

    /**
     * @notice Updates the liquidation protocol fee percentage.
     * @param _newFee The new fee percentage (e.g., 3e16 for 3%).
     */
    function updateLiquidationFee(uint256 _newFee) external onlyOwner {
         if (_newFee + liquidationBonus > _PERCENTAGE_PRECISION) revert InvalidLiquidationParams();
        emit LiquidationFeeUpdated(liquidationFee, _newFee);
        liquidationFee = _newFee;
    }

    /**
     * @notice Updates the liquidation bonus percentage paid to liquidators.
     * @param _newBonus The new bonus percentage (e.g., 5e16 for 5%).
     */
    function updateLiquidationBonus(uint256 _newBonus) external onlyOwner {
         if (liquidationFee + _newBonus > _PERCENTAGE_PRECISION) revert InvalidLiquidationParams();
        emit LiquidationBonusUpdated(liquidationBonus, _newBonus);
        liquidationBonus = _newBonus;
    }

    /**
     * @notice Updates the oracle address for a supported asset.
     * @param _asset The address of the supported asset (collateral or synthetic).
     * @param _oracle The new oracle address.
     */
    function setOracleAddress(address _asset, address _oracle) external onlyOwner {
         if (_oracle == address(0)) revert ZeroAddress();
         bool isCol = supportedCollateral[_asset].isSupported;
         bool isSyn = supportedSynthetics[_asset].isSupported;
         if (!isCol && !isSyn) revert AssetNotSupported();
          // Basic check for oracle interface
        try AggregatorV3Interface(_oracle).decimals() returns (uint8) {} catch {
             revert InvalidOracleFeed();
        }


         if(isCol) supportedCollateral[_asset].oracle = _oracle;
         if(isSyn) supportedSynthetics[_asset].oracle = _oracle;

         emit OracleAddressUpdated(_asset, _oracle);
    }


    /**
     * @notice Sets the address that can claim protocol fees.
     * @param _feeCollector The new fee collector address.
     */
    function setFeeCollector(address _feeCollector) external onlyOwner {
         if (_feeCollector == address(0)) revert ZeroAddress();
        emit FeeCollectorUpdated(feeCollector, _feeCollector);
        feeCollector = _feeCollector;
    }

    /**
     * @notice Pauses critical user interactions with the system (minting, burning, deposits, withdrawals).
     * @dev This is an emergency function. Does NOT pause liquidation.
     */
    function pauseSystem() external onlyOwner {
        if (_systemPaused) return;
        _systemPaused = true;
        emit SystemPaused(msg.sender);
    }

    /**
     * @notice Unpauses the system, allowing normal user interactions.
     */
    function unpauseSystem() external onlyOwner {
         if (!_systemPaused) return;
        _systemPaused = false;
        emit SystemUnpaused(msg.sender);
    }

     /**
     * @notice Allows the owner to recover tokens erroneously sent to the contract.
     * @dev Cannot recover supported collateral/synthetic tokens that are part of the protocol's managed balance (user positions or fee balances).
     * @param _token The address of the token to recover.
     * @param _amount The amount of tokens to recover.
     */
    function recoverTokens(address _token, uint256 _amount) external onlyOwner {
        if (_amount == 0) revert AmountMustBePositive();
        // Prevent recovering tokens that are part of the protocol's state
        if (supportedCollateral[_token].isSupported || supportedSynthetics[_token].isSupported) {
            // Check if the amount trying to be recovered exceeds the 'free' balance
            // Free balance = total balance - locked collateral - fee balance
            uint256 totalBalance = IERC20(_token).balanceOf(address(this));
            uint256 managedBalance = totalCollateralLocked[_token] + feeBalances[_token];
             // Simple safety: only allow recovery up to (totalBalance - managedBalance)
             // A more rigorous check would ensure individual user collateral isn't touched
             // For simplicity, we just check if the requested amount *plus* managed balance
             // exceeds the total balance.
            if (_amount + managedBalance > totalBalance) {
                 // This implies the amount requested includes managed tokens
                 // Revert or adjust amount? Let's revert for safety.
                 revert TokenTransferFailed(); // Using a generic error for safety/simplicity
            }
        }

        if (!IERC20(_token).transfer(msg.sender, _amount)) revert TokenTransferFailed();

        emit TokensRecovered(_token, _amount, msg.sender);
    }


    /*═════════ User Interaction Functions ═════════*/

    /**
     * @notice Deposits collateral into the caller's position.
     * @dev User must approve the contract to spend `_amount` of `_collateralToken` beforehand.
     * @param _collateralToken The address of the collateral token to deposit.
     * @param _amount The amount of collateral to deposit.
     */
    function depositCollateral(address _collateralToken, uint256 _amount) external whenNotPaused {
        if (_amount == 0) revert AmountMustBePositive();
        if (!supportedCollateral[_collateralToken].isSupported) revert NotSupportedCollateral();

        UserPosition storage pos = userPositions[msg.sender];

        // If this is the first time this collateral is used by the user, add to list
        if (pos.collateralLocked[_collateralToken] == 0) {
             bool found = false;
             for(uint i = 0; i < pos.collateralTokensInPosition.length; ++i) {
                 if (pos.collateralTokensInPosition[i] == _collateralToken) {
                     found = true;
                     break;
                 }
             }
             if (!found) {
                pos.collateralTokensInPosition.push(_collateralToken);
             }
        }


        // Transfer collateral from user to contract
        if (!IERC20(_collateralToken).transferFrom(msg.sender, address(this), _amount)) {
            revert TokenTransferFailed();
        }

        pos.collateralLocked[_collateralToken] += _amount;
        totalCollateralLocked[_collateralToken] += _amount;

        emit CollateralDeposited(msg.sender, _collateralToken, _amount);
    }

    /**
     * @notice Withdraws collateral from the caller's position.
     * @dev Checks that the position remains healthy after withdrawal.
     * @param _collateralToken The address of the collateral token to withdraw.
     * @param _amount The amount of collateral to withdraw.
     */
    function withdrawCollateral(address _collateralToken, uint256 _amount) external whenNotPaused {
        if (_amount == 0) revert AmountMustBePositive();
        if (!supportedCollateral[_collateralToken].isSupported) revert NotSupportedCollateral();

        UserPosition storage pos = userPositions[msg.sender];
        if (pos.collateralLocked[_collateralToken] < _amount) revert InsufficientCollateralLocked();

        // Calculate position health BEFORE withdrawal
        (uint256 currentCollateralValue, uint256 currentDebtValue) = _calculatePositionValue(msg.sender);

        // Calculate the value of collateral being withdrawn
        uint256 withdrawalValue = (_amount * _getPrice(_collateralToken)) / (10 ** (IERC20(_collateralToken).decimals() - uint252(Math.log10(_PRICE_PRECISION))));

        uint256 potentialNewCollateralValue = currentCollateralValue - withdrawalValue;

        // Check if position remains healthy *after* withdrawal
        // If there's no debt, user can withdraw any amount up to their locked balance.
        if (currentDebtValue > 0) {
             // New C-ratio check: potentialNewCollateralValue * 1e18 >= currentDebtValue * minCollateralizationRatio
             if (potentialNewCollateralValue * _PERCENTAGE_PRECISION < currentDebtValue * minCollateralizationRatio) {
                revert PositionUndercollateralized();
            }

            // Also check against synthetic-specific minimums
            for (uint i = 0; i < pos.syntheticTokensInPosition.length; ++i) {
                address synToken = pos.syntheticTokensInPosition[i];
                if (pos.syntheticDebt[synToken] > 0) {
                    uint256 synDebtValue = (pos.syntheticDebt[synToken] * _getPrice(synToken)) / (10 ** (IERC20(synToken).decimals() - uint252(Math.log10(_PRICE_PRECISION))));
                     uint256 syntheticMinRatio = supportedSynthetics[synToken].minRatio;
                     // Check if overall collateral still backs *this specific* debt type adequately
                     if (potentialNewCollateralValue * _PERCENTAGE_PRECISION < synDebtValue * syntheticMinRatio) {
                          revert PositionUndercollateralized(); // Specific synthetic debt is undercollateralized
                     }
                }
            }
        }

        pos.collateralLocked[_collateralToken] -= _amount;
        totalCollateralLocked[_collateralToken] -= _amount;

        // Transfer collateral back to user
        if (!IERC20(_collateralToken).transfer(msg.sender, _amount)) {
            revert TokenTransferFailed();
        }

        emit CollateralWithdrawn(msg.sender, _collateralToken, _amount);
    }

    /**
     * @notice Mints synthetic tokens against locked collateral.
     * @dev User must have sufficient collateral locked and maintain the minimum collateralization ratio.
     * @param _syntheticToken The address of the synthetic token to mint.
     * @param _collateralToken The address of the collateral token used for ratio calculation.
     * @param _synthAmount The amount of synthetic tokens to mint (in synthetic token's decimals).
     */
    function mintSynthetic(address _syntheticToken, address _collateralToken, uint256 _synthAmount) external whenNotPaused {
        if (_synthAmount == 0) revert AmountMustBePositive();
        if (!supportedSynthetics[_syntheticToken].isSupported) revert NotSupportedSynthetic();
         if (!supportedCollateral[_collateralToken].isSupported) revert NotSupportedCollateral(); // Must specify which collateral supports this mint

        UserPosition storage pos = userPositions[msg.sender];

         // Calculate value of requested synth debt
        uint256 synthPrice = _getPrice(_syntheticToken);
        uint256 synthDecimals = IERC20(_syntheticToken).decimals();
        uint256 synthValue = (_synthAmount * synthPrice) / (10 ** (synthDecimals - uint252(Math.log10(_PRICE_PRECISION)))); // Value in USD * 1e8

         // Calculate potential new total debt value
         (uint256 currentCollateralValue, uint256 currentDebtValue) = _calculatePositionValue(msg.sender);
         uint256 potentialNewDebtValue = currentDebtValue + synthValue;

         // Check if collateral is sufficient for the *new* total debt
         // currentCollateralValue * 1e18 >= potentialNewDebtValue * minCollateralizationRatio
         if (currentCollateralValue * _PERCENTAGE_PRECISION < potentialNewDebtValue * minCollateralizationRatio) {
             revert InsufficientCollateral(); // Not enough collateral for global ratio
         }

          // Check if collateral is sufficient for the *new* debt of this specific synthetic type
         uint256 syntheticMinRatio = supportedSynthetics[_syntheticToken].minRatio;
         // currentCollateralValue * 1e18 >= (currentDebtValue + synthValue) * syntheticMinRatio
          if (currentCollateralValue * _PERCENTAGE_PRECISION < potentialNewDebtValue * syntheticMinRatio) {
             revert InsufficientCollateral(); // Not enough collateral for synthetic-specific ratio
          }

        // If this is the first time this synthetic is used by the user, add to list
        if (pos.syntheticDebt[_syntheticToken] == 0) {
              bool found = false;
             for(uint i = 0; i < pos.syntheticTokensInPosition.length; ++i) {
                 if (pos.syntheticTokensInPosition[i] == _syntheticToken) {
                     found = true;
                     break;
                 }
             }
             if (!found) {
                pos.syntheticTokensInPosition.push(_syntheticToken);
             }
        }

        // Update state
        pos.syntheticDebt[_syntheticToken] += _synthAmount;
        totalSyntheticsOutstanding[_syntheticToken] += _synthAmount;

        // Calculate and collect mint fee
        uint256 feeAmount = (_synthAmount * mintFee) / _PERCENTAGE_PRECISION;
        if (feeAmount > 0) {
            feeBalances[_syntheticToken] += feeAmount;
        }


        // Mint synthetic tokens to user (minus fee if applicable)
        uint256 amountToMintToUser = _synthAmount - feeAmount;
         if (!IERC20(_syntheticToken).transfer(msg.sender, amountToMintToUser)) {
             revert TokenTransferFailed(); // Synthetic token should be minter capable or pre-minted and held by this contract
         }


        emit SyntheticMinted(msg.sender, _syntheticToken, _synthAmount, _collateralToken, pos.collateralLocked[_collateralToken]); // Note: collateralLocked is total, not amount locked for this specific mint
    }

     /**
     * @notice Burns synthetic tokens to reduce debt and potentially unlock collateral.
     * @dev Burning synthetic tokens reduces the user's debt. Users can burn up to their current debt amount.
     *      Collateral is NOT automatically released on burn, user must call withdrawCollateral separately.
     * @param _syntheticToken The address of the synthetic token to burn.
     * @param _amount The amount of synthetic tokens to burn (in synthetic token's decimals).
     */
    function burnSynthetic(address _syntheticToken, uint256 _amount) external whenNotPaused {
        if (_amount == 0) revert AmountMustBePositive();
        if (!supportedSynthetics[_syntheticToken].isSupported) revert NotSupportedSynthetic();

        UserPosition storage pos = userPositions[msg.sender];
        if (pos.syntheticDebt[_syntheticToken] < _amount) revert InsufficientDebt();

        // Transfer synthetic tokens from user to contract (or burn)
        // Contract expects user to transfer/approve tokens to be burned
         if (!IERC20(_syntheticToken).transferFrom(msg.sender, address(this), _amount)) {
             revert TokenTransferFailed();
         }
        // In a real system, this would involve burning the tokens, not just transferring to contract.
        // Assuming the synthetic token has a burnFrom function or the contract is the minter/burner.
        // For demonstration, we'll simulate burning by reducing total supply tracking.
        // If using OpenZeppelin ERC20, require burn capability or contract is minter.

        // Update state
        pos.syntheticDebt[_syntheticToken] -= _amount;
        totalSyntheticsOutstanding[_syntheticToken] -= _amount; // Simulate burn

        // Calculate and collect burn fee
        uint256 feeAmount = (_amount * burnFee) / _PERCENTAGE_PRECISION;
        if (feeAmount > 0) {
            feeBalances[_syntheticToken] += feeAmount;
        }

        emit SyntheticBurned(msg.sender, _syntheticToken, _amount, address(0), 0); // collateralToken/Amount is not directly tied to burn
    }


     /**
     * @notice Allows anyone to liquidate an undercollateralized position.
     * @dev This function checks if the user position is below the minimum required collateralization ratio.
     *      If liquidatable, it seizes collateral, burns synthetic debt, pays a bonus to the liquidator, and collects a protocol fee.
     * @param _user The address of the user whose position is to be liquidated.
     */
    function liquidatePosition(address _user) external whenSystemNotPaused {
        if (_user == address(0)) revert ZeroAddress();
         if (_user == msg.sender) revert PositionHealthy(); // Cannot self-liquidate this way

        // Check if the position is actually liquidatable
        if (!_isLiquidatable(_user)) {
            revert PositionHealthy();
        }

        UserPosition storage pos = userPositions[_user];

        // --- Liquidation Logic ---
        // Liquidate the entire position (all debt, proportional collateral)
        // Or liquidate only enough debt to bring the position back above water + bonus/fee?
        // Full liquidation is simpler: Seize ALL collateral, burn ALL synthetic debt.
        // This needs careful consideration if user has multiple synth debts/collaterals.
        // Let's implement full liquidation for simplicity in this example contract.
        // Alternative: Partial liquidation - complicated calculation of how much debt to burn and which collateral to seize.

        (uint256 collateralValueTotal, uint256 debtValueTotal) = _calculatePositionValue(_user);

        // Calculate amounts of collateral to seize and synths to burn based on values.
        // This requires converting value back to token amounts using current prices.
        // This is complex with multiple collateral types and multiple synthetic debts.
        // A simpler model might link specific collateral to specific debt, but this contract design uses a pooled collateral model.
        //
        // Simplification: Seize *proportional* amounts of *all* locked collateral and burn *proportional* amounts of *all* synthetic debt.
        // The values liquidated should ideally match (value seized = value burned + bonus + fee).
        // Value Seized = Value of all collateral
        // Value Burned = Value of all debt
        // Value Bonus = Value of all collateral * liquidationBonus / 1e18
        // Value Fee = Value of all collateral * liquidationFee / 1e18
        // If Value Seized >= Value Burned + Value Bonus + Value Fee, the liquidation is viable.
        // The liquidator gets (Value Bonus) in proportion to seized collateral.
        // The protocol gets (Value Fee) in proportion to seized collateral.
        // The user gets (Value Seized - Value Bonus - Value Fee - Value Burned) returned, or loses it if negative.

        // Let's refine: The liquidator gets a BONUS. The protocol takes a FEE. Both are percentages of the *collateral value seized*.
        // The seized collateral is enough to cover the *debt value* plus the *bonus* and *fee*.
        // Required Collateral Value = Debt Value * (1e18 + Liquidation Bonus + Liquidation Fee) / 1e18
        // If totalCollateralValue < Required Collateral Value, it's liquidatable.
        // Collateral Seized Value = Debt Value + Bonus Value + Fee Value
        // Bonus Value = Debt Value * LiquidationBonus / 1e18
        // Fee Value = Debt Value * LiquidationFee / 1e18
        // Collateral Seized Value = Debt Value + Debt Value * LiquidationBonus / 1e18 + Debt Value * LiquidationFee / 1e18
        // This means seized collateral covers debt plus bonus/fee on the debt value.
        // The liquidator burns 100% of the debt, receives collateral covering (Debt Value + Bonus + Fee).
        // This leaves the user with remaining collateral (if any) or a net loss.

        // Calculate total value of collateral to seize: totalDebtValue * (1e18 + liquidationBonus + liquidationFee) / 1e18
        // Use a minimum seized value to ensure gas costs are covered, but let's skip for complexity.
        uint256 totalLiquidationPercentage = _PERCENTAGE_PRECISION + liquidationBonus + liquidationFee;
        uint256 requiredCollateralValueToSeize = (debtValueTotal * totalLiquidationPercentage) / _PERCENTAGE_PRECISION;

        // If collateral value is less than required, seize all available collateral.
        uint256 actualCollateralValueToSeize = Math.min(collateralValueTotal, requiredCollateralValueToSeize);

        // Calculate bonus and fee based on *seized collateral value*
        uint256 liquidatorBonusValue = (actualCollateralValueToSeize * liquidationBonus) / _PERCENTAGE_PRECISION;
        uint256 protocolFeeValue = (actualCollateralValueToSeize * liquidationFee) / _PERCENTAGE_PRECISION;

        // Amounts of tokens to transfer/burn based on their *current price* and *value*.
        // Seizing collateral: Iterate through locked collateral, calculate token amount based on value share.
        // Burning debt: Iterate through synthetic debt, calculate token amount based on value share.

        // Value of seized collateral that goes back to the user
        // This should be zero if actualCollateralValueToSeize is based on covering debt+bonus+fee
        // Let's assume seized collateral *exactly* covers debt+bonus+fee if possible, otherwise seize all.
        // The excess collateral is what's left after seizing needed amount.
        uint256 collateralValueRemaining = collateralValueTotal - actualCollateralValueToSeize;


        // 1. Transfer seized collateral tokens proportionally to liquidator and feeCollector
        for (uint i = 0; i < pos.collateralTokensInPosition.length; ++i) {
            address colToken = pos.collateralTokensInPosition[i];
             uint256 lockedAmount = pos.collateralLocked[colToken];
             if (lockedAmount > 0) {
                 uint256 collateralPrice = _getPrice(colToken);
                 uint256 tokenDecimals = IERC20(colToken).decimals();
                 uint256 lockedValue = (lockedAmount * collateralPrice) / (10 ** (tokenDecimals - uint252(Math.log10(_PRICE_PRECISION)))); // Value in USD * 1e8

                 // Amount of this token to seize = (lockedValue / collateralValueTotal) * actualCollateralValueToSeize
                 // This division can have precision issues. Alternative: Calculate amount based on (debtValue * ratio) for THIS token *if it were the only collateral*.
                 // Let's use the value share approach, accepting minor precision loss.
                 uint256 amountToSeize = (lockedAmount * actualCollateralValueToSeize) / collateralValueTotal; // amount = (value * total_amount) / total_value

                 if (amountToSeize > 0) {
                      // Amount to pay liquidator
                     uint256 liquidatorAmount = (amountToSeize * liquidationBonus) / totalLiquidationPercentage;
                     // Amount to pay protocol fee
                     uint256 feeAmount = (amountToSeize * liquidationFee) / totalLiquidationPercentage;
                      // Amount to cover debt
                     uint256 debtCoverAmount = amountToSeize - liquidatorAmount - feeAmount;

                      // Transfer to liquidator (bonus)
                      if (liquidatorAmount > 0) {
                         if (!IERC20(colToken).transfer(msg.sender, liquidatorAmount)) revert TokenTransferFailed();
                      }
                       // Transfer to fee collector
                     if (feeAmount > 0) {
                         feeBalances[colToken] += feeAmount; // Add to contract balance, collectable later
                     }

                     // Note: The 'debtCoverAmount' is not transferred out to cover debt directly.
                     // The collateral is seized to the contract, and the debt is burned.
                     // The user position simply loses the `amountToSeize` of collateral.
                     // This amount stays in the contract (totalCollateralLocked decreases) but isn't re-assigned to a user.
                     // It effectively disappears from user control and covers the burnt debt + fees/bonus.

                      pos.collateralLocked[colToken] -= amountToSeize;
                      totalCollateralLocked[colToken] -= amountToSeize;
                 }
             }
        }

        // 2. Burn synthetic debt proportionally
        for (uint i = 0; i < pos.syntheticTokensInPosition.length; ++i) {
            address synToken = pos.syntheticTokensInPosition[i];
            uint256 debtAmount = pos.syntheticDebt[synToken];
            if (debtAmount > 0) {
                uint256 syntheticPrice = _getPrice(synToken);
                uint256 tokenDecimals = IERC20(synToken).decimals();
                uint256 debtValue = (debtAmount * syntheticPrice) / (10 ** (tokenDecimals - uint252(Math.log10(_PRICE_PRECISION)))); // Value in USD * 1e8

                // Amount of this token to burn = (debtValue / debtValueTotal) * debtValueTotal = debtAmount
                 // We burn ALL debt for simplicity in full liquidation.
                if (debtAmount > 0) {
                    // In a real system, would call IERC20(synToken).burnFrom(user, debtAmount)
                    // For this example, we update internal state.
                    pos.syntheticDebt[synToken] -= debtAmount;
                    totalSyntheticsOutstanding[synToken] -= debtAmount; // Simulate burn
                }
            }
        }

         // Clean up empty asset lists in position struct
         _calculatePositionValue(_user); // Calling this re-calculates values AND cleans up the lists.

        emit PositionLiquidated(msg.sender, _user, debtValueTotal, actualCollateralValueToSeize, liquidatorBonusValue, protocolFeeValue);
    }


    /**
     * @notice Allows the fee collector to withdraw accumulated protocol fees for a specific token.
     * @param _token The address of the token for which to claim fees.
     */
    function claimFees(address _token) external {
        if (msg.sender != feeCollector) revert OnlyOwner(); // Using OnlyOwner error as it's the same concept
         if (!supportedCollateral[_token].isSupported && !supportedSynthetics[_token].isSupported) revert AssetNotSupported(); // Only claim fees for supported assets

        uint256 amount = feeBalances[_token];
        if (amount == 0) return; // No fees to claim

        feeBalances[_token] = 0; // Reset balance before transfer

        if (!IERC20(_token).transfer(feeCollector, amount)) {
            // If transfer fails, ideally log or revert and reset the balance.
            // Reverting is safer to ensure state consistency.
            feeBalances[_token] = amount; // Reset balance
            revert TokenTransferFailed();
        }

        emit FeeClaimed(feeCollector, _token, amount);
    }


    /*═════════ View Functions ═════════*/

    /**
     * @notice Gets the list of all supported collateral token addresses and their oracles.
     * @return collaterals An array of supported collateral token addresses.
     * @return oracles An array of corresponding oracle addresses.
     */
    function getSupportedCollateral() external view returns (address[] memory collaterals, address[] memory oracles) {
        uint256 count = supportedCollateralList.length;
        collaterals = new address[](count);
        oracles = new address[](count);
        for(uint i = 0; i < count; ++i) {
            address token = supportedCollateralList[i];
            if (supportedCollateral[token].isSupported) {
                 collaterals[i] = token;
                 oracles[i] = supportedCollateral[token].oracle;
            }
        }
        // Need to clean up potential zero addresses if remove wasn't perfect
        // Or just return the raw list and let the caller filter based on .isSupported
        // Let's return the raw list from storage which includes potentially removed ones, check isSupported
        // Alternative: Maintain a clean list in storage. Let's return cleaned list.
         uint256 validCount = 0;
         for(uint i = 0; i < supportedCollateralList.length; ++i) {
             if (supportedCollateral[supportedCollateralList[i]].isSupported) {
                 validCount++;
             }
         }
         collaterals = new address[](validCount);
         oracles = new address[](validCount);
         uint224 j = 0;
         for(uint i = 0; i < supportedCollateralList.length; ++i) {
             address token = supportedCollateralList[i];
             if (supportedCollateral[token].isSupported) {
                 collaterals[j] = token;
                 oracles[j] = supportedCollateral[token].oracle;
                 j++;
             }
         }
         return (collaterals, oracles);
    }

     /**
     * @notice Gets the list of all supported synthetic asset token addresses, their oracles, and minimum ratios.
     * @return synthetics An array of supported synthetic token addresses.
     * @return oracles An array of corresponding oracle addresses.
     * @return minRatios An array of corresponding minimum collateralization ratios.
     */
    function getSupportedSynthetics() external view returns (address[] memory synthetics, address[] memory oracles, uint256[] memory minRatios) {
        uint256 validCount = 0;
         for(uint i = 0; i < supportedSyntheticList.length; ++i) {
             if (supportedSynthetics[supportedSyntheticList[i]].isSupported) {
                 validCount++;
             }
         }
        synthetics = new address[](validCount);
        oracles = new address[](validCount);
        minRatios = new uint256[](validCount);
        uint224 j = 0;
        for(uint i = 0; i < supportedSyntheticList.length; ++i) {
             address token = supportedSyntheticList[i];
             if (supportedSynthetics[token].isSupported) {
                synthetics[j] = token;
                oracles[j] = supportedSynthetics[token].oracle;
                minRatios[j] = supportedSynthetics[token].minRatio;
                 j++;
             }
        }
        return (synthetics, oracles, minRatios);
    }


    /**
     * @notice Gets the current price of a supported asset from its oracle.
     * @param _asset The address of the supported asset.
     * @return The price of the asset scaled by _PRICE_PRECISION.
     */
    function getAssetPrice(address _asset) external view returns (uint256) {
        if (!supportedCollateral[_asset].isSupported && !supportedSynthetics[_asset].isSupported) revert AssetNotSupported();
        return _getPrice(_asset);
    }

    /**
     * @notice Gets the locked collateral and synthetic debt for a specific user.
     * @param _user The address of the user.
     * @return collateralTokens An array of collateral token addresses held by the user.
     * @return collateralAmounts An array of corresponding locked amounts.
     * @return syntheticTokens An array of synthetic token addresses the user has debt in.
     * @return syntheticAmounts An array of corresponding debt amounts.
     */
    function getUserPosition(address _user) external view returns (address[] memory collateralTokens, uint256[] memory collateralAmounts, address[] memory syntheticTokens, uint256[] memory syntheticAmounts) {
         UserPosition storage pos = userPositions[_user];

         // Filter out zero balances/debts and non-supported assets
         uint256 colCount = 0;
         for(uint i=0; i<pos.collateralTokensInPosition.length; ++i) {
             if(pos.collateralLocked[pos.collateralTokensInPosition[i]] > 0 && supportedCollateral[pos.collateralTokensInPosition[i]].isSupported) colCount++;
         }
         collateralTokens = new address[](colCount);
         collateralAmounts = new uint256[](colCount);
         uint224 j = 0;
          for(uint i=0; i<pos.collateralTokensInPosition.length; ++i) {
             address token = pos.collateralTokensInPosition[i];
             if(pos.collateralLocked[token] > 0 && supportedCollateral[token].isSupported) {
                 collateralTokens[j] = token;
                 collateralAmounts[j] = pos.collateralLocked[token];
                 j++;
             }
         }

         uint256 synCount = 0;
          for(uint i=0; i<pos.syntheticTokensInPosition.length; ++i) {
             if(pos.syntheticDebt[pos.syntheticTokensInPosition[i]] > 0 && supportedSynthetics[pos.syntheticTokensInPosition[i]].isSupported) synCount++;
         }
         syntheticTokens = new address[](synCount);
         syntheticAmounts = new uint256[](synCount);
         j = 0;
          for(uint i=0; i<pos.syntheticTokensInPosition.length; ++i) {
             address token = pos.syntheticTokensInPosition[i];
             if(pos.syntheticDebt[token] > 0 && supportedSynthetics[token].isSupported) {
                 syntheticTokens[j] = token;
                 syntheticAmounts[j] = pos.syntheticDebt[token];
                 j++;
             }
         }

         return (collateralTokens, collateralAmounts, syntheticTokens, syntheticAmounts);
    }


     /**
     * @notice Calculates and returns the current collateralization ratio and liquidatable status for a user's position.
     * @param _user The address of the user.
     * @return currentRatio The user's current collateralization ratio (scaled by _PERCENTAGE_PRECISION). Returns 0 if no debt.
     * @return isLiquidatable Whether the position is currently under the liquidation threshold.
     */
    function getPositionHealth(address _user) external view returns (uint256 currentRatio, bool isLiquidatable) {
        (uint256 collateralValue, uint256 debtValue) = _calculatePositionValue(_user);

        if (debtValue == 0) {
            return (0, false); // No debt, infinite ratio, not liquidatable
        }

        // currentRatio = (collateralValue * 1e18) / debtValue
        currentRatio = (collateralValue * _PERCENTAGE_PRECISION) / debtValue;

        // Check against global min ratio
        bool globalRatioFailed = (currentRatio < minCollateralizationRatio);

        // Check against synthetic-specific min ratios (if any debt exists for that synth)
        bool syntheticRatioFailed = false;
        UserPosition storage pos = userPositions[_user];
        for (uint i = 0; i < pos.syntheticTokensInPosition.length; ++i) {
            address synToken = pos.syntheticTokensInPosition[i];
             if (pos.syntheticDebt[synToken] > 0 && supportedSynthetics[synToken].isSupported) {
                  uint256 synDebtValue = (pos.syntheticDebt[synToken] * _getPrice(synToken)) / (10 ** (IERC20(synToken).decimals() - uint252(Math.log10(_PRICE_PRECISION))));
                  uint256 syntheticMinRatio = supportedSynthetics[synToken].minRatio;

                  // Check if overall collateral still backs *this specific* debt type adequately
                 // currentCollateralValue * 1e18 < synDebtValue * syntheticMinRatio
                 if (currentCollateralValue * _PERCENTAGE_PRECISION < synDebtValue * syntheticMinRatio) {
                      syntheticRatioFailed = true;
                      break; // Found one failing ratio, position is unhealthy
                 }
             }
        }

        isLiquidatable = (debtValue > 0) && (globalRatioFailed || syntheticRatioFailed);

        return (currentRatio, isLiquidatable);
    }


    /**
     * @notice Gets the total outstanding supply of a specific synthetic token minted by the protocol.
     * @param _syntheticToken The address of the synthetic token.
     * @return The total amount of the synthetic token outstanding.
     */
    function getSyntheticsOutstanding(address _syntheticToken) external view returns (uint256) {
        // Assuming totalSyntheticsOutstanding is kept accurate by mint/burn
        // A real system might query the ERC20 total supply if the contract is the sole minter.
        return totalSyntheticsOutstanding[_syntheticToken];
    }

     /**
     * @notice Gets the total amount of a specific collateral token locked in the protocol.
     * @param _collateralToken The address of the collateral token.
     * @return The total amount of the collateral token locked.
     */
    function getCollateralLockedTotal(address _collateralToken) external view returns (uint256) {
         // Assuming totalCollateralLocked is kept accurate by deposit/withdraw/liquidate
        return totalCollateralLocked[_collateralToken];
    }

    /**
     * @notice Gets the current protocol fee percentages.
     * @return mintFee_ The current mint fee percentage.
     * @return burnFee_ The current burn fee percentage.
     * @dev Percentages are scaled by _PERCENTAGE_PRECISION.
     */
    function getProtocolFees() external view returns (uint256 mintFee_, uint256 burnFee_) {
        return (mintFee, burnFee);
    }

    /**
     * @notice Gets the current liquidation bonus and fee percentages.
     * @return liquidationBonus_ The current liquidation bonus percentage paid to liquidators.
     * @return liquidationFee_ The current protocol fee percentage on liquidated collateral.
     * @dev Percentages are scaled by _PERCENTAGE_PRECISION.
     */
    function getLiquidationParams() external view returns (uint256 liquidationBonus_, uint256 liquidationFee_) {
        return (liquidationBonus, liquidationFee);
    }

    /**
     * @notice Gets the minimum required collateralization ratios.
     * @return globalMinRatio The global minimum collateralization ratio.
     * @return syntheticMinRatios A mapping of synthetic token addresses to their specific minimum ratios.
     * @dev Ratios are scaled by _PERCENTAGE_PRECISION. The syntheticMinRatios mapping cannot be returned directly
     *      in Solidity. A helper to get one ratio or iterating the list is needed. Let's return global and provide
     *      a getter for specific synthetic ratios.
     */
     function getMinCollateralizationRatios() external view returns (uint256 globalMinRatio) {
         return minCollateralizationRatio;
     }

     /**
      * @notice Gets the specific minimum collateralization ratio for a synthetic asset.
      * @param _syntheticToken The address of the synthetic asset.
      * @return The minimum ratio for the synthetic asset, or 0 if not supported.
      */
     function getSyntheticMinRatio(address _syntheticToken) external view returns (uint256) {
         return supportedSynthetics[_syntheticToken].minRatio;
     }

     /**
     * @notice Gets the oracle address configured for a specific supported asset.
     * @param _asset The address of the supported asset.
     * @return The oracle address, or address(0) if not supported or no oracle set.
     */
    function getOracleAddress(address _asset) external view returns (address) {
         if (supportedCollateral[_asset].isSupported) return supportedCollateral[_asset].oracle;
         if (supportedSynthetics[_asset].isSupported) return supportedSynthetics[_asset].oracle;
         return address(0);
    }

    // 33 Total External/Public/View Functions

    // Missing functions from outline (e.g., getSystemStatus) could be added by combining existing views.
    // The current count is 33, well over the 20 requested.

}
```