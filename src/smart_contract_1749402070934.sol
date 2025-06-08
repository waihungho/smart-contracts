Okay, here is a Solidity smart contract for a simplified Decentralized Synthetic Asset Protocol.

This protocol allows users to deposit approved collateral tokens (like ETH or USDC) and mint approved synthetic tokens (like sAAPL or sGOLD) based on oracle price feeds, maintaining a minimum collateralization ratio. It includes features for minting, burning, withdrawing excess collateral, liquidating undercollateralized positions, and governance over supported assets and parameters.

It uses concepts like:
*   **Multiple Asset Support:** Configurable collateral and synthetic assets.
*   **Oracle Integration:** Relies on external price feeds (simulated/abstracted Chainlink Aggregators).
*   **Collateralization:** Enforces a minimum collateralization ratio per position.
*   **Liquidation:** Allows anyone to liquidate underwater positions for a bounty.
*   **Configurable Parameters:** Minimum CRs, liquidation penalties are set per asset pair.
*   **Position Management:** Tracks individual user positions based on collateral and synthetic type.
*   **Basic Governance/Admin Control:** Functions for adding/removing assets and setting parameters (simplistic owner-based for this example).

It avoids common contract structures like simple ERC20/NFT/Stake contracts, basic AMMs, or standard DAO templates.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// --- Outline and Function Summary ---
/*
Outline:
1.  Interfaces: Define necessary external interfaces (ERC20, Oracle).
2.  Errors: Custom error definitions for clarity and gas efficiency.
3.  Libraries: Potential future use (e.g., SafeMath - not needed in 0.8+ for basic ops).
4.  Access Control: Pausable, Ownable.
5.  Structs: Data structures for asset parameters, asset pair parameters, and user positions.
6.  State Variables: Store supported assets, parameters, user positions, treasury address.
7.  Events: Emit logs for significant actions.
8.  Modifiers: Custom checks (e.g., asset supported, sufficient collateral).
9.  Constructor: Initialize owner and treasury.
10. Governance/Admin Functions: Add/remove assets, update parameters, set oracles, set treasury, pause/unpause.
11. Oracle Interaction Functions: Get prices from registered oracles (internal/public helpers).
12. Core Protocol Logic (User Functions):
    - Deposit collateral.
    - Mint synthetic assets.
    - Burn synthetic assets.
    - Withdraw excess collateral.
    - Redeem all collateral by burning all synth.
13. Liquidation Logic:
    - Check position health (collateralization ratio).
    - Liquidate undercollateralized positions.
14. View/Helper Functions: Get position details, calculate CR, required collateral, mintable amount.

Function Summary (Public/External Functions):

-   `constructor()`: Initializes the contract with owner and treasury.
-   `addSupportedCollateral(address collateralToken, address oracleAddress, uint256 defaultMinCR, uint256 defaultLiquidationPenalty)`: Allows owner to add a new ERC20 token as supported collateral.
-   `removeSupportedCollateral(address collateralToken)`: Allows owner to remove a supported collateral type.
-   `addSupportedSyntheticAsset(address syntheticToken, address oracleAddress)`: Allows owner to add a new ERC20 token as a supported synthetic asset.
-   `removeSupportedSyntheticAsset(address syntheticToken)`: Allows owner to remove a supported synthetic asset type.
-   `updateAssetPairParams(address collateralToken, address syntheticToken, uint256 minCR, uint256 liquidationPenalty)`: Sets or updates parameters (min CR, liquidation penalty) for a specific collateral-synth pair.
-   `setOracleAddress(address assetToken, address oracleAddress)`: Updates the oracle address for a supported asset.
-   `setProtocolTreasury(address treasuryAddress)`: Sets the address where protocol fees go.
-   `pause()`: Pauses core protocol functions (mint, deposit, liquidate).
-   `unpause()`: Unpauses the protocol.
-   `depositCollateral(address collateralToken, address syntheticToken, uint256 amount)`: User deposits collateral into a specific position (identified by collateral & synthetic tokens).
-   `mintSynthetic(address collateralToken, address syntheticToken, uint256 amount)`: User mints synthetic tokens against their deposited collateral, ensuring minimum CR is met.
-   `burnSynthetic(address collateralToken, address syntheticToken, uint256 amount)`: User burns synthetic tokens to reduce their debt, potentially allowing collateral withdrawal later.
-   `withdrawCollateral(address collateralToken, address syntheticToken, uint256 amount)`: User withdraws *excess* collateral from a position while maintaining the minimum CR.
-   `redeemCollateral(address collateralToken, address syntheticToken)`: User burns *all* synthetic tokens for a position to reclaim *all* deposited collateral.
-   `liquidatePosition(address user, address collateralToken, address syntheticToken)`: Allows anyone to liquidate an undercollateralized position.
-   `getCollateralPrice(address collateralToken)`: Gets the price of a supported collateral asset from its oracle.
-   `getSyntheticPrice(address syntheticToken)`: Gets the price of a supported synthetic asset from its oracle.
-   `getCurrentCollateralRatio(address user, address collateralToken, address syntheticToken)`: Calculates the current collateralization ratio for a user's position. Returns 0 if position doesn't exist or values are zero.
-   `getRequiredCollateral(address collateralToken, address syntheticToken, uint256 synthAmountToMint)`: Calculates the minimum required collateral value (in wei) to mint a given amount of synthetic tokens.
-   `getMintableAmount(address user, address collateralToken, address syntheticToken)`: Calculates the maximum amount of synthetic tokens a user can currently mint based on their deposited collateral.
-   `getPosition(address user, address collateralToken, address syntheticToken)`: Returns the current state (`amountCollateral`, `amountSyntheticMinted`) of a user's specific position.
-   `isSupportedCollateral(address token)`: Checks if a token is a supported collateral asset.
-   `isSupportedSyntheticAsset(address token)`: Checks if a token is a supported synthetic asset.
*/

// --- Imports ---
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; // Using Chainlink interface as a standard

// --- Interfaces ---

// Standard Chainlink Oracle Interface
// interface AggregatorV3Interface {
//     function latestRoundData() external view returns (
//         uint80 roundId,
//         int256 answer,
//         uint256 startedAt,
//         uint256 updatedAt,
//         uint80 answeredInRound
//     );
// }

// --- Errors (Solidity 0.8.4+) ---
// Use require statements for broader compatibility or if custom errors are complex.
// require statements will be used in this example for simplicity.

// --- Structs ---

struct AssetParams {
    address oracle; // Address of the price feed oracle (e.g., Chainlink Aggregator)
    bool isSupported; // Whether the asset is currently supported
    uint80 oracleDecimals; // Decimals of the oracle's answer (e.g., 8 for Chainlink prices)
}

// Parameters specific to a collateral-synthetic asset pair
struct AssetPairParams {
    uint256 minCR; // Minimum Collateralization Ratio (e.g., 150000000000000000000 = 150%) represented as fixed-point 18 decimals
    uint256 liquidationPenalty; // Penalty applied to collateral during liquidation (e.g., 10% = 100000000000000000)
    bool paramsSet; // True if params have been explicitly set for this pair
}

// Represents a user's position for a specific collateral token backing a specific synthetic token
struct Position {
    uint256 amountCollateral; // Amount of collateral token deposited
    uint256 amountSyntheticMinted; // Amount of synthetic token minted
}

// --- State Variables ---

// Mapping of supported collateral tokens to their parameters
mapping(address => AssetParams) public supportedCollateral;

// Mapping of supported synthetic tokens to their parameters
mapping(address => AssetParams) public supportedSyntheticAssets;

// Mapping of (collateral => synthetic => params) for asset pair specific settings
mapping(address => mapping(address => AssetPairParams)) public assetPairParameters;

// User positions: user => collateral token => synthetic token => position details
mapping(address => mapping(address => mapping(address => Position))) public userPositions;

address public protocolTreasury; // Address receiving liquidation penalties and potential future fees

// --- Events ---

event CollateralAdded(address indexed collateralToken, address oracleAddress, uint256 defaultMinCR, uint256 defaultLiquidationPenalty);
event CollateralRemoved(address indexed collateralToken);
event SyntheticAssetAdded(address indexed syntheticToken, address oracleAddress);
event SyntheticAssetRemoved(address indexed syntheticToken);
event AssetPairParamsUpdated(address indexed collateralToken, address indexed syntheticToken, uint256 minCR, uint256 liquidationPenalty);
event OracleAddressUpdated(address indexed assetToken, address newOracleAddress);
event TreasuryAddressUpdated(address indexed newTreasuryAddress);

event CollateralDeposited(address indexed user, address indexed collateralToken, address indexed syntheticToken, uint256 amount);
event SyntheticMinted(address indexed user, address indexed collateralToken, address indexed syntheticToken, uint256 amount);
event SyntheticBurned(address indexed user, address indexed collateralToken, address indexed syntheticToken, uint256 amount);
event CollateralWithdrawn(address indexed user, address indexed collateralToken, address indexed syntheticToken, uint256 amount);
event CollateralRedeemed(address indexed user, address indexed collateralToken, address indexed syntheticToken, uint256 amountSyntheticBurned, uint256 amountCollateralReturned);

event PositionLiquidated(address indexed user, address indexed collateralToken, address indexed syntheticToken, address liquidator, uint256 debtRepaid, uint256 collateralLiquidated, uint256 penaltyAmount, uint256 liquidatorReward);

// --- Modifiers ---

modifier onlySupportedCollateral(address token) {
    require(supportedCollateral[token].isSupported, "SAP: Collateral not supported");
    _;
}

modifier onlySupportedSyntheticAsset(address token) {
    require(supportedSyntheticAssets[token].isSupported, "SAP: Synthetic asset not supported");
    _;
}

modifier onlySupportedAssetPair(address collateralToken, address syntheticToken) {
    require(
        supportedCollateral[collateralToken].isSupported &&
        supportedSyntheticAssets[syntheticToken].isSupported,
        "SAP: Collateral or Synthetic asset not supported"
    );
    _;
}

modifier requiresExistingPosition(address user, address collateralToken, address syntheticToken) {
     require(userPositions[user][collateralToken][syntheticToken].amountCollateral > 0 ||
             userPositions[user][collateralToken][syntheticToken].amountSyntheticMinted > 0,
             "SAP: No existing position for this user/pair");
    _;
}


// --- Contract Implementation ---

constructor(address _protocolTreasury) Ownable() Pausable() {
    require(_protocolTreasury != address(0), "SAP: Treasury cannot be zero address");
    protocolTreasury = _protocolTreasury;
    // Note: No assets are supported by default. Owner must add them.
}

// --- Governance/Admin Functions ---

// 1. Add supported collateral
function addSupportedCollateral(
    address collateralToken,
    address oracleAddress,
    uint256 defaultMinCR,
    uint256 defaultLiquidationPenalty
) external onlyOwner {
    require(collateralToken != address(0) && oracleAddress != address(0), "SAP: Zero address");
    require(!supportedCollateral[collateralToken].isSupported, "SAP: Collateral already supported");
    require(defaultMinCR >= 100000000000000000000, "SAP: Min CR must be >= 100%"); // Min 100% (1e18)
    require(defaultLiquidationPenalty < 1000000000000000000, "SAP: Penalty must be < 100%"); // Max 100% (1e18)

    uint80 oracleDecimals = uint80(AggregatorV3Interface(oracleAddress).latestRoundData().decimals);

    supportedCollateral[collateralToken] = AssetParams({
        oracle: oracleAddress,
        isSupported: true,
        oracleDecimals: oracleDecimals
    });

    // Initialize pair params with defaults for all *existing* supported synthetic assets
    // and set the default for future pairs.
    // This is a simplified approach. In a real system, you might need a more robust
    // initialization or governance proposal per pair.
    for (uint i = 0; i < 0; ++i) { // Placeholder loop logic - real implementation needs iterable supported assets
        // In a real system, iterating maps is hard. You'd likely use arrays
        // or explicit pair addition. Skipping complex iteration here.
        // Example: Add pair params for (new collateral, existing synth1), (new collateral, existing synth2), etc.
        // For simplicity, we'll just allow setting per pair later.
    }


    emit CollateralAdded(collateralToken, oracleAddress, defaultMinCR, defaultLiquidationPenalty);
}

// 2. Remove supported collateral
// WARNING: This function does not handle existing positions using this collateral.
// A real protocol needs a migration plan (e.g., force redemption, liquidation, or locking).
function removeSupportedCollateral(address collateralToken) external onlyOwner {
    require(supportedCollateral[collateralToken].isSupported, "SAP: Collateral not supported");

    supportedCollateral[collateralToken].isSupported = false;
    // Oracle address and decimals remain for historical data if needed, or could be zeroed out.
    // Note: Parameters for pairs involving this collateral are effectively inactive.

    emit CollateralRemoved(collateralToken);
}

// 3. Add supported synthetic asset
function addSupportedSyntheticAsset(address syntheticToken, address oracleAddress) external onlyOwner {
    require(syntheticToken != address(0) && oracleAddress != address(0), "SAP: Zero address");
    require(!supportedSyntheticAssets[syntheticToken].isSupported, "SAP: Synthetic asset already supported");

    uint80 oracleDecimals = uint80(AggregatorV3Interface(oracleAddress).latestRoundData().decimals);

    supportedSyntheticAssets[syntheticToken] = AssetParams({
        oracle: oracleAddress,
        isSupported: true,
        oracleDecimals: oracleDecimals
    });

    // Initialize pair params with defaults for all *existing* supported collateral assets.
    // Skipping complex iteration, rely on updateAssetPairParams.

    emit SyntheticAssetAdded(syntheticToken, oracleAddress);
}

// 4. Remove supported synthetic asset
// WARNING: This function does not handle existing positions holding this synthetic asset.
// A real protocol needs a migration plan.
function removeSupportedSyntheticAsset(address syntheticToken) external onlyOwner {
    require(supportedSyntheticAssets[syntheticToken].isSupported, "SAP: Synthetic asset not supported");

    supportedSyntheticAssets[syntheticToken].isSupported = false;
    // Oracle address and decimals remain for historical data.
    // Note: Parameters for pairs involving this synth are effectively inactive.

    emit SyntheticAssetRemoved(syntheticToken);
}

// 5. Update parameters for a specific collateral-synthetic pair
function updateAssetPairParams(
    address collateralToken,
    address syntheticToken,
    uint256 minCR,
    uint256 liquidationPenalty
) external onlyOwner onlySupportedAssetPair(collateralToken, syntheticToken) {
     require(minCR >= 100000000000000000000, "SAP: Min CR must be >= 100%");
     require(liquidationPenalty < 1000000000000000000, "SAP: Penalty must be < 100%");

    assetPairParameters[collateralToken][syntheticToken] = AssetPairParams({
        minCR: minCR,
        liquidationPenalty: liquidationPenalty,
        paramsSet: true
    });

    emit AssetPairParamsUpdated(collateralToken, syntheticToken, minCR, liquidationPenalty);
}

// Internal helper to get pair params, uses defaults if not explicitly set
function _getAssetPairParams(address collateralToken, address syntheticToken)
    internal view returns (uint256 minCR, uint256 liquidationPenalty)
{
    AssetPairParams storage pairParams = assetPairParameters[collateralToken][syntheticToken];
    if (pairParams.paramsSet) {
        return (pairParams.minCR, pairParams.liquidationPenalty);
    } else {
        // Return default parameters. This is a simplified design.
        // A robust system might require params to be explicitly set per pair.
        // We'll use placeholder defaults here. In addSupportedCollateral/Synthetic,
        // we *could* have passed defaultPairParams, but this is simpler for the example.
        return (200000000000000000000, 100000000000000000); // Default: 200% CR, 10% penalty
    }
}


// 6. Set Oracle Address for a supported asset
// Can update oracle for already supported assets.
function setOracleAddress(address assetToken, address oracleAddress) external onlyOwner {
    require(assetToken != address(0) && oracleAddress != address(0), "SAP: Zero address");

    bool isCollateral = supportedCollateral[assetToken].isSupported;
    bool isSynthetic = supportedSyntheticAssets[assetToken].isSupported;

    require(isCollateral || isSynthetic, "SAP: Asset not supported");

    uint80 oracleDecimals = uint80(AggregatorV3Interface(oracleAddress).latestRoundData().decimals);

    if (isCollateral) {
        supportedCollateral[assetToken].oracle = oracleAddress;
        supportedCollateral[assetToken].oracleDecimals = oracleDecimals;
    }
    if (isSynthetic) {
        supportedSyntheticAssets[assetToken].oracle = oracleAddress;
        supportedSyntheticAssets[assetToken].oracleDecimals = oracleDecimals;
    }

    emit OracleAddressUpdated(assetToken, oracleAddress);
}

// 7. Set Protocol Treasury Address
function setProtocolTreasury(address treasuryAddress) external onlyOwner {
    require(treasuryAddress != address(0), "SAP: Zero address");
    protocolTreasury = treasuryAddress;
    emit TreasuryAddressUpdated(treasuryAddress);
}

// 8. Pause Protocol
function pause() external onlyOwner whenNotPaused {
    _pause();
}

// 9. Unpause Protocol
function unpause() external onlyOwner whenPaused {
    _unpause();
}


// --- Oracle Interaction (Helper Functions) ---

// Helper to get price from oracle, handling decimals
function _getPrice(address oracleAddress, uint80 oracleDecimals) internal view returns (uint256 price) {
    AggregatorV3Interface oracle = AggregatorV3Interface(oracleAddress);
    (, int256 answer, , uint256 updatedAt, ) = oracle.latestRoundData();

    // Basic check for stale data (configurable timeout needed in production)
    require(updatedAt > 0 && block.timestamp - updatedAt < 3600, "SAP: Oracle price data is stale");
    require(answer > 0, "SAP: Oracle price is zero or negative"); // Ensure positive price

    // Convert oracle price to 18 decimals for consistent calculations
    uint256 oraclePrice = uint256(answer);
    if (oracleDecimals < 18) {
        price = oraclePrice * (10**(18 - oracleDecimals));
    } else if (oracleDecimals > 18) {
        price = oraclePrice / (10**(oracleDecimals - 18));
    } else {
        price = oraclePrice;
    }
}

// 10. Get Collateral Price
function getCollateralPrice(address collateralToken)
    public view onlySupportedCollateral(collateralToken) returns (uint256)
{
    AssetParams storage params = supportedCollateral[collateralToken];
    return _getPrice(params.oracle, params.oracleDecimals);
}

// 11. Get Synthetic Price
function getSyntheticPrice(address syntheticToken)
    public view onlySupportedSyntheticAsset(syntheticToken) returns (uint256)
{
    AssetParams storage params = supportedSyntheticAssets[syntheticToken];
    return _getPrice(params.oracle, params.oracleDecimals);
}

// --- Core Protocol Logic (User Functions) ---

// 12. Deposit Collateral
function depositCollateral(
    address collateralToken,
    address syntheticToken,
    uint256 amount
) external whenNotPaused onlySupportedAssetPair(collateralToken, syntheticToken) {
    require(amount > 0, "SAP: Deposit amount must be > 0");

    // Pull collateral token from user
    bool success = IERC20(collateralToken).transferFrom(msg.sender, address(this), amount);
    require(success, "SAP: Collateral transfer failed");

    // Update user's position
    Position storage pos = userPositions[msg.sender][collateralToken][syntheticToken];
    pos.amountCollateral += amount;

    // No CR check needed on deposit, only on mint/withdraw

    emit CollateralDeposited(msg.sender, collateralToken, syntheticToken, amount);
}

// 13. Mint Synthetic Assets
function mintSynthetic(
    address collateralToken,
    address syntheticToken,
    uint256 amount
) external whenNotPaused onlySupportedAssetPair(collateralToken, syntheticToken) {
    require(amount > 0, "SAP: Mint amount must be > 0");

    Position storage pos = userPositions[msg.sender][collateralToken][syntheticToken];
    require(pos.amountCollateral > 0, "SAP: No collateral deposited for this position");

    uint256 newSyntheticAmount = pos.amountSyntheticMinted + amount;

    // Check if the new position meets the minimum CR
    _checkCollateralRatio(msg.sender, collateralToken, syntheticToken, pos.amountCollateral, newSyntheticAmount);

    // Mint synthetic token to user
    success = IERC20(syntheticToken).transfer(msg.sender, amount);
    require(success, "SAP: Synthetic token transfer failed");

    // Update user's position
    pos.amountSyntheticMinted = newSyntheticAmount;

    emit SyntheticMinted(msg.sender, collateralToken, syntheticToken, amount);
}

// 14. Burn Synthetic Assets
function burnSynthetic(
    address collateralToken,
    address syntheticToken,
    uint256 amount
) external whenNotPaused onlySupportedAssetPair(collateralToken, syntheticToken) requiresExistingPosition(msg.sender, collateralToken, syntheticToken) {
    require(amount > 0, "SAP: Burn amount must be > 0");

    Position storage pos = userPositions[msg.sender][collateralToken][syntheticToken];
    require(amount <= pos.amountSyntheticMinted, "SAP: Burn amount exceeds minted amount");

    // Pull synthetic token from user
    bool success = IERC20(syntheticToken).transferFrom(msg.sender, address(this), amount);
    require(success, "SAP: Synthetic token transfer failed");

    // Update user's position
    pos.amountSyntheticMinted -= amount;

    // CR should improve, no check needed.

    emit SyntheticBurned(msg.sender, collateralToken, syntheticToken, amount);
}

// 15. Withdraw Excess Collateral
function withdrawCollateral(
    address collateralToken,
    address syntheticToken,
    uint256 amount
) external whenNotPaused onlySupportedAssetPair(collateralToken, syntheticToken) requiresExistingPosition(msg.sender, collateralToken, syntheticToken) {
    require(amount > 0, "SAP: Withdraw amount must be > 0");

    Position storage pos = userPositions[msg.sender][collateralToken][syntheticToken];
    require(amount <= pos.amountCollateral, "SAP: Withdraw amount exceeds deposited collateral");

    uint256 newCollateralAmount = pos.amountCollateral - amount;

    // Check if the remaining position meets the minimum CR
    _checkCollateralRatio(msg.sender, collateralToken, syntheticToken, newCollateralAmount, pos.amountSyntheticMinted);

    // Push collateral token to user
    bool success = IERC20(collateralToken).transfer(msg.sender, amount);
    require(success, "SAP: Collateral transfer failed");

    // Update user's position
    pos.amountCollateral = newCollateralAmount;

    emit CollateralWithdrawn(msg.sender, collateralToken, syntheticToken, amount);
}

// 16. Redeem Collateral (Burn all synthetic to get all collateral back)
function redeemCollateral(
    address collateralToken,
    address syntheticToken
) external whenNotPaused onlySupportedAssetPair(collateralToken, syntheticToken) requiresExistingPosition(msg.sender, collateralToken, syntheticToken) {
    Position storage pos = userPositions[msg.sender][collateralToken][syntheticToken];
    uint256 syntheticToBurn = pos.amountSyntheticMinted;
    uint256 collateralToReturn = pos.amountCollateral;

    require(syntheticToBurn > 0, "SAP: No synthetic tokens minted in this position");

    // Pull all synthetic token from user
    bool success = IERC20(syntheticToken).transferFrom(msg.sender, address(this), syntheticToBurn);
    require(success, "SAP: Synthetic token transfer failed");

    // Push all collateral token to user
    success = IERC20(collateralToken).transfer(msg.sender, collateralToReturn);
    require(success, "SAP: Collateral transfer failed");

    // Reset user's position
    pos.amountCollateral = 0;
    pos.amountSyntheticMinted = 0;

    emit CollateralRedeemed(msg.sender, collateralToken, syntheticToken, syntheticToBurn, collateralToReturn);
    // Note: Position entry remains in mapping but with zero amounts
}

// --- Liquidation Logic ---

// Internal helper to calculate the collateral value and synthetic debt value in a common unit (e.g., USD with 18 decimals)
function _calculatePositionValue(
    address user,
    address collateralToken,
    address syntheticToken,
    uint256 amountCollateral,
    uint256 amountSynthetic
) internal view returns (uint256 collateralValue, uint256 syntheticValue) {
    if (amountCollateral == 0 && amountSynthetic == 0) {
        return (0, 0);
    }

    uint256 collateralPrice = getCollateralPrice(collateralToken);
    uint256 syntheticPrice = getSyntheticPrice(syntheticToken);

    // Calculate values, scaling amounts to 18 decimals if needed, then multiplying by price (already 18 decimals)
    // Note: Assumes collateral/synth tokens have 18 decimals. If not, need to adjust.
    // For simplicity, assume 18 decimals or adjust appropriately.
    // ERC20 amounts are typically in token's smallest unit (wei). Assume 18 decimals for simplicity here.
    collateralValue = (amountCollateral * collateralPrice) / (10**18);
    syntheticValue = (amountSynthetic * syntheticPrice) / (10**18);

    // Safety check against division by zero for CR calculation later
    if (syntheticValue == 0 && amountSynthetic > 0) {
        // This case means synthetic price is effectively zero, which is problematic.
        // Treat as infinitely underwater? Or revert? Reverting is safer.
         revert("SAP: Cannot calculate synthetic value (price is zero)");
    }
}


// Internal helper to check if a position meets the minimum collateralization ratio
function _checkCollateralRatio(
    address user,
    address collateralToken,
    address syntheticToken,
    uint256 amountCollateral,
    uint256 amountSynthetic
) internal view {
     // Zero debt implies infinite CR, always valid
     if (amountSynthetic == 0) {
         return;
     }

    (uint256 collateralValue, uint256 syntheticValue) = _calculatePositionValue(
        user,
        collateralToken,
        syntheticToken,
        amountCollateral,
        amountSynthetic
    );

    // Avoid division by zero if synthetic value is 0 (and amountSynthetic > 0 already handled in _calculatePositionValue)
     if (syntheticValue == 0) {
          // This implies a synthetic token price issue. Revert.
          revert("SAP: Cannot calculate CR - synthetic value is zero");
     }

    uint256 currentCR = (collateralValue * 10**18) / syntheticValue; // CR in 18 decimals

    (uint256 minCR, ) = _getAssetPairParams(collateralToken, syntheticToken);

    require(currentCR >= minCR, "SAP: Position below minimum collateral ratio");
}


// 17. Get Current Collateral Ratio (Public View)
function getCurrentCollateralRatio(
    address user,
    address collateralToken,
    address syntheticToken
) public view onlySupportedAssetPair(collateralToken, syntheticToken) returns (uint256) {
    Position storage pos = userPositions[user][collateralToken][syntheticToken];

    if (pos.amountCollateral == 0 && pos.amountSyntheticMinted == 0) {
        return 0; // No position
    }

    (uint256 collateralValue, uint256 syntheticValue) = _calculatePositionValue(
        user,
        collateralToken,
        syntheticToken,
        pos.amountCollateral,
        pos.amountSyntheticMinted
    );

    if (syntheticValue == 0) {
         // If syntheticValue is zero but amountSyntheticMinted > 0, it's an oracle issue or debt is tiny.
         // Return a very large number to indicate high CR or max uint.
         // If both values are 0 (pos check above handles 0/0), this branch is skipped.
         if(pos.amountSyntheticMinted > 0) return type(uint256).max; // Effectively infinite CR
         return 0; // Should not happen if pos.amountSyntheticMinted > 0 check works
    }

    return (collateralValue * 10**18) / syntheticValue; // CR in 18 decimals
}


// 18. Liquidate Position
// Anyone can call this function if the position is undercollateralized.
function liquidatePosition(
    address user,
    address collateralToken,
    address syntheticToken
) external whenNotPaused onlySupportedAssetPair(collateralToken, syntheticToken) requiresExistingPosition(user, collateralToken, syntheticToken) {
    Position storage pos = userPositions[user][collateralToken][syntheticToken];

    // Get current CR and required min CR
    uint256 currentCR = getCurrentCollateralRatio(user, collateralToken, syntheticToken);
    (uint256 minCR, uint256 liquidationPenalty) = _getAssetPairParams(collateralToken, syntheticToken);

    require(currentCR < minCR, "SAP: Position is not undercollateralized");

    // --- Calculate Liquidation Amounts ---
    // Liquidate enough collateral to cover the synthetic debt plus the liquidation penalty.

    (uint256 collateralValue, uint256 syntheticValue) = _calculatePositionValue(
         user,
         collateralToken,
         syntheticToken,
         pos.amountCollateral,
         pos.amountSyntheticMinted
     );

    // Value needed to cover debt + penalty
    // Target value = syntheticValue * (1 + liquidationPenalty)
    // e.g., 100 USD debt, 10% penalty -> need 110 USD value from collateral.
    // Need to be careful with fixed point math here. syntheticValue is already 18 decimals.
    // penalty is e.g., 0.1 * 1e18.
    // syntheticValue * (1e18 + penalty) / 1e18
    uint256 requiredCollateralValueForLiquidation = (syntheticValue * (10**18 + liquidationPenalty)) / (10**18);


    // Amount of collateral to liquidate in token units
    uint256 collateralPrice = getCollateralPrice(collateralToken);
    require(collateralPrice > 0, "SAP: Collateral price is zero for liquidation calculation");

    // collateralAmountToLiquidate = requiredCollateralValueForLiquidation * (10**18) / collateralPrice
    // Cap this amount at the user's available collateral
    uint256 collateralAmountToLiquidate = (requiredCollateralValueForLiquidation * (10**18)) / collateralPrice;
    collateralAmountToLiquidate = Math.min(collateralAmountToLiquidate, pos.amountCollateral);

    // Calculate how much debt this liquidated collateral covers *after* penalty
    // Collateral value AFTER penalty = collateralAmountToLiquidate * collateralPrice * (1 - liquidationPenalty / 1e18)
    // This is the value available to burn synthetic debt.
    // (collateralAmountToLiquidate * collateralPrice * (1e18 - liquidationPenalty)) / (1e18 * 1e18)
    // Amount of synthetic debt value covered = (collateralValue of liquidated amount * (1e18 - liquidationPenalty)) / 1e18
     uint256 liquidatedCollateralValueBeforePenalty = (collateralAmountToLiquidate * collateralPrice) / (10**18);
     uint256 liquidatedCollateralValueAfterPenalty = (liquidatedCollateralValueBeforePenalty * (10**18 - liquidationPenalty)) / (10**18);


    // Amount of synthetic tokens to burn
    // synthAmountToBurn = liquidatedCollateralValueAfterPenalty * (10**18) / syntheticPrice
    uint256 syntheticPrice = getSyntheticPrice(syntheticToken);
    require(syntheticPrice > 0, "SAP: Synthetic price is zero for liquidation calculation");

    uint256 syntheticAmountToBurn = (liquidatedCollateralValueAfterPenalty * (10**18)) / syntheticPrice;

    // The liquidator gets rewarded with a portion of the penalty.
    // The remaining penalty goes to the treasury.
    // A common model: liquidator gets the debt repaid amount + a bonus from the liquidated collateral.
    // Let's simplify: liquidator burns `syntheticAmountToBurn` from their balance,
    // receives `collateralAmountToLiquidate`, user loses `collateralAmountToLiquidate` and debt is reduced by `syntheticAmountToBurn`.
    // The value difference due to the penalty is implicitly shared between the liquidator and the protocol treasury.
    // Liquidator gets collateralValueBeforePenalty - liquidatedCollateralValueAfterPenalty (the penalty value) as reward, plus the amount to cover debt.

    // The synthetic tokens to burn must come *from the liquidator*.
    // The liquidator buys the debt at a discount by providing the synthetic tokens.
    // Amount synthetic liquidator must provide = syntheticAmountToBurn (or the user's total debt if less)
    // The liquidator receives collateral in return.

    // Let's adjust the model: liquidator pays `amountSyntheticToBurn` synthetic tokens.
    // User's debt decreases by `amountSyntheticToBurn`.
    // User's collateral decreases by `collateralAmountToLiquidate`.
    // Liquidator receives `collateralAmountToLiquidate`.
    // The penalty value is the difference: liquidatedCollateralValueBeforePenalty - liquidatedCollateralValueAfterPenalty.
    // This penalty value is the liquidator's profit (before gas).

    uint256 debtToBurn = Math.min(syntheticAmountToBurn, pos.amountSyntheticMinted); // Don't burn more than user owes

    // Calculate the *actual* collateral to liquidate based on the debt being burned.
    // collateral needed to cover debtToBurn = debtToBurn * syntheticPrice * (10**18 + liquidationPenalty) / (10**18 * 10**18)
    // collateral amount = (debtToBurn * syntheticPrice * (10**18 + liquidationPenalty)) / (10**18 * collateralPrice)
    uint256 actualCollateralToLiquidate = ((debtToBurn * syntheticPrice) / (10**18)) * (10**18 + liquidationPenalty) / collateralPrice;
    actualCollateralToLiquidate = actualCollateralToLiquidate / (10**18); // Adjust for the extra 1e18 from syntheticPrice*debtToBurn
    actualCollateralToLiquidate = Math.min(actualCollateralToLiquidate, pos.amountCollateral);

    // Recalculate debt burned based on actual collateral liquidated (due to caps)
    uint256 actualLiquidatedCollateralValue = (actualCollateralToLiquidate * collateralPrice) / (10**18);
    uint256 valueAvailableToBurn = (actualLiquidatedCollateralValue * (10**18 - liquidationPenalty)) / (10**18);
    uint256 actualDebtBurned = (valueAvailableToBurn * (10**18)) / syntheticPrice;
    actualDebtBurned = Math.min(actualDebtBurned, pos.amountSyntheticMinted); // Final cap

    // Ensure we are liquidating something significant
    require(actualDebtBurned > 0, "SAP: Liquidation amount is too small or calculation error");


    // --- Execute Transfers ---

    // Liquidator pays synthetic tokens to the protocol (which are then burned from user's debt)
    bool success = IERC20(syntheticToken).transferFrom(msg.sender, address(this), actualDebtBurned);
    require(success, "SAP: Liquidator synthetic token transfer failed");

    // Protocol transfers liquidated collateral to the liquidator
    success = IERC20(collateralToken).transfer(msg.sender, actualCollateralToLiquidate);
    require(success, "SAP: Collateral transfer to liquidator failed");

    // --- Update Position ---
    pos.amountCollateral -= actualCollateralToLiquidate;
    pos.amountSyntheticMinted -= actualDebtBurned;

    // After liquidation, the position should ideally be above the liquidation threshold (but maybe not min CR).
    // A full liquidation (debt=0) clears the position.

    emit PositionLiquidated(
        user,
        collateralToken,
        syntheticToken,
        msg.sender, // liquidator
        actualDebtBurned, // amount of synthetic debt repaid
        actualCollateralToLiquidate, // amount of collateral seized
        // The penalty is implicit in the amount of collateral received vs debt burned value
        // For event clarity, could calculate penalty value: actualLiquidatedCollateralValue - (actualDebtBurned * syntheticPrice / 1e18)
        // Let's just log the amounts transferred/burned.
        0, // Penalty amount (simplified - penalty is implicit profit)
        0 // Liquidator reward (simplified - reward is collateral received)
    );

    // If the position is now fully closed, clear it more explicitly if desired, though zero amounts are fine.
    // if (pos.amountCollateral == 0 && pos.amountSyntheticMinted == 0) {
    //     // Consider deleting the mapping entry if gas is critical, but this can be complex.
    // }
}


// --- View/Helper Functions ---

// 19. Get Required Collateral Value (in the collateral token's value units, 18 decimals)
function getRequiredCollateral(
    address collateralToken,
    address syntheticToken,
    uint256 synthAmountToMint
) public view onlySupportedAssetPair(collateralToken, syntheticToken) returns (uint256) {
    if (synthAmountToMint == 0) {
        return 0;
    }

    (uint256 minCR, ) = _getAssetPairParams(collateralToken, syntheticToken);
    uint256 syntheticPrice = getSyntheticPrice(syntheticToken);
    // syntheticValue = synthAmountToMint * syntheticPrice / 1e18 (assuming 18 decimals for synth amount)

    // Required Collateral Value = syntheticValue * minCR / 1e18
    // = (synthAmountToMint * syntheticPrice / 1e18) * minCR / 1e18
    // = synthAmountToMint * syntheticPrice * minCR / (1e18 * 1e18)
    uint256 requiredCollateralValue = (synthAmountToMint * syntheticPrice * minCR) / (10**36);

    return requiredCollateralValue;
}

// 20. Get Maximum Mintable Amount (in synthetic token units)
function getMintableAmount(
    address user,
    address collateralToken,
    address syntheticToken
) public view onlySupportedAssetPair(collateralToken, syntheticToken) returns (uint256) {
     Position storage pos = userPositions[user][collateralToken][syntheticToken];
     uint256 currentCollateral = pos.amountCollateral;
     uint256 currentSynthetic = pos.amountSyntheticMinted;

     if (currentCollateral == 0) {
         return 0; // Cannot mint without collateral
     }

    (uint256 minCR, ) = _getAssetPairParams(collateralToken, syntheticToken);
    uint256 collateralPrice = getCollateralPrice(collateralToken);
    uint256 syntheticPrice = getSyntheticPrice(syntheticToken);

    if (syntheticPrice == 0) return 0; // Cannot determine mintable amount if synth price is 0

    // Current Collateral Value = currentCollateral * collateralPrice / 1e18 (assuming 18 decimals for collateral amount)

    // Max allowed Synthetic Value = Current Collateral Value * 1e18 / minCR
    // = (currentCollateral * collateralPrice / 1e18) * 1e18 / minCR
    // = currentCollateral * collateralPrice / minCR
    uint256 maxSyntheticValueAllowed = (currentCollateral * collateralPrice) / minCR;

    // Max allowed Synthetic Amount = maxSyntheticValueAllowed * 1e18 / syntheticPrice
    // = (currentCollateral * collateralPrice / minCR) * 1e18 / syntheticPrice
    // = currentCollateral * collateralPrice * 1e18 / (minCR * syntheticPrice)
    uint256 maxSyntheticAmountAllowed = (currentCollateral * collateralPrice * (10**18)) / (minCR * syntheticPrice);

    // Amount that can be minted is the difference between max allowed and currently minted
    if (maxSyntheticAmountAllowed <= currentSynthetic) {
        return 0; // Already at or below max allowed debt
    } else {
        return maxSyntheticAmountAllowed - currentSynthetic;
    }
}


// 21. Get Position Details
function getPosition(
    address user,
    address collateralToken,
    address syntheticToken
) public view onlySupportedAssetPair(collateralToken, syntheticToken) returns (uint256 amountCollateral, uint256 amountSyntheticMinted) {
    Position storage pos = userPositions[user][collateralToken][syntheticToken];
    return (pos.amountCollateral, pos.amountSyntheticMinted);
}

// 22. Get Total Collateral in Position
function getTotalCollateral(
    address user,
    address collateralToken,
    address syntheticToken
) public view onlySupportedAssetPair(collateralToken, syntheticToken) returns (uint256) {
    return userPositions[user][collateralToken][syntheticToken].amountCollateral;
}

// 23. Get Total Synthetic Minted in Position
function getTotalSyntheticMinted(
    address user,
    address collateralToken,
    address syntheticToken
) public view onlySupportedAssetPair(collateralToken, syntheticToken) returns (uint256) {
    return userPositions[user][collateralToken][syntheticToken].amountSyntheticMinted;
}

// 24. Check if collateral is supported
function isSupportedCollateral(address token) public view returns (bool) {
    return supportedCollateral[token].isSupported;
}

// 25. Check if synthetic asset is supported
function isSupportedSyntheticAsset(address token) public view returns (bool) {
    return supportedSyntheticAssets[token].isSupported;
}

// --- Standard Libraries (if needed, e.g., SafeMath before 0.8) ---
// Using Solidity 0.8+, so SafeMath is not strictly necessary for basic ops.
// For more complex math (like min/max used in liquidate), we can import or implement.
// Let's add a simple Math library for min
library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}


// --- Add more functions to reach 20+ external/public count if needed ---
// We currently have:
// constructor: 1
// Governance: addCollateral, removeCollateral, addSynth, removeSynth, updatePairParams, setOracleAddress, setTreasury, pause, unpause (9)
// Oracle Getters: getCollateralPrice, getSyntheticPrice (2)
// Core Logic: depositCollateral, mintSynthetic, burnSynthetic, withdrawCollateral, redeemCollateral (5)
// Liquidation: liquidatePosition (1)
// View/Helpers: getCurrentCollateralRatio, getRequiredCollateral, getMintableAmount, getPosition, getTotalCollateral, getTotalSyntheticMinted, isSupportedCollateral, isSupportedSyntheticAsset (8)
// Total: 1 + 9 + 2 + 5 + 1 + 8 = 26 Public/External functions. Requirement met.

// Potential additional functions (not strictly needed for the 20+ count, but could add complexity):
// - Function to claim liquidation rewards if separated
// - View function to get specific asset pair parameters
// - Function to sweep accidentally sent tokens (emergency)
// - Governance proposal/voting functions (instead of direct owner calls)
// - Functions for rebalancing positions
// - Functions related to protocol fees beyond liquidation penalty (e.g., minting fees)
// - Functions for staking LP tokens etc (would require more contracts)

// Let's add a couple more views for completeness that could be useful:

// 26. Get Asset Pair Parameters
function getAssetPairConfig(address collateralToken, address syntheticToken)
    public view returns (uint256 minCR, uint256 liquidationPenalty, bool paramsSet)
{
    AssetPairParams storage params = assetPairParameters[collateralToken][syntheticToken];
    return (params.minCR, params.liquidationPenalty, params.paramsSet);
}

// 27. Get Supported Collateral Asset Details
function getSupportedCollateralDetails(address collateralToken)
    public view returns (address oracleAddress, bool isSupported, uint80 oracleDecimals)
{
     AssetParams storage params = supportedCollateral[collateralToken];
     return (params.oracle, params.isSupported, params.oracleDecimals);
}

// 28. Get Supported Synthetic Asset Details
function getSupportedSyntheticDetails(address syntheticToken)
    public view returns (address oracleAddress, bool isSupported, uint80 oracleDecimals)
{
     AssetParams storage params = supportedSyntheticAssets[syntheticToken];
     return (params.oracle, params.isSupported, params.oracleDecimals);
}

// Total Public/External Functions: 1 + 9 + 2 + 5 + 1 + 8 + 3 = 29 functions. Well over 20.
```

---

**Explanation and Advanced Concepts Used:**

1.  **Multiple Asset & Pair Management:** The contract isn't hardcoded for specific tokens (like ETH/DAI). It uses mappings (`supportedCollateral`, `supportedSyntheticAssets`, `assetPairParameters`) to allow the owner/governance to add/remove assets and configure parameters *per pair* (`updateAssetPairParams`). This is more flexible than single-collateral or fixed-pair systems.
2.  **Oracle Abstraction:** It defines and uses an `AggregatorV3Interface` (like Chainlink's) to fetch prices. This external dependency for off-chain data is crucial for DeFi protocols. Error handling for stale/zero prices is included.
3.  **Collateralization Logic:** The core mechanism involves calculating the value of collateral vs. the value of minted synthetic debt using real-time oracle prices. It enforces a minimum collateralization ratio (`minCR`).
4.  **Individual Position Tracking:** Instead of a global debt pool, each user's collateral and minted synthetic amount is tracked *per specific collateral/synthetic pair*. This allows users to manage multiple, isolated positions.
5.  **Liquidation Mechanism:** This is a complex, but standard, part of synthetic asset protocols. Anyone can trigger liquidation if a position falls below the required CR. The calculation involves determining how much collateral to seize to cover the debt *plus* a penalty, and how much synthetic debt is burned. The liquidator is implicitly rewarded by receiving the seized collateral.
6.  **Dynamic Parameters:** `minCR` and `liquidationPenalty` can be different for each collateral-synthetic pair and can be updated via governance. This allows tuning risk parameters based on asset volatility or market conditions.
7.  **Pausability:** A standard safety feature (`Pausable` from OpenZeppelin) to halt critical operations in case of an emergency (e.g., oracle failure, critical bug).
8.  **Access Control (`Ownable`):** While a real advanced system might use a complex DAO for governance, this example uses `Ownable` for simplicity to demonstrate which functions are restricted.
9.  **Fixed-Point Arithmetic:** Calculations involving currency values and ratios (`minCR`, `liquidationPenalty`) are done using large integers (uint256) and scaling (multiplying/dividing by 10^18) to simulate fixed-point decimal precision, avoiding floating-point issues in Solidity.

**Limitations and Areas for Further Advancement (beyond 20+ functions):**

*   **Oracle Reliability:** Assumes the Chainlink oracle is always available, accurate, and not manipulated. Real systems might use multiple oracles or different oracle designs.
*   **Asset Decimal Handling:** Simplifies by often assuming 18 decimals for collateral/synthetic tokens. A robust contract needs to handle different decimal counts correctly in all calculations.
*   **Governance:** The current governance is a simple `Ownable`. A decentralized protocol would use a DAO with token voting, representative voting, or other mechanisms.
*   **Liquidation Efficiency:** Gas costs for liquidation can be high. More advanced systems might use flash loans, auctions, or Keeper networks more tightly integrated. The penalty mechanism here is basic.
*   **Solvency:** This simple model doesn't explicitly track system-wide solvency or have mechanisms for recapitalization if a cascading failure occurs (e.g., oracle manipulation + rapid price drop).
*   **Fees:** Only a liquidation penalty is included. Protocols often have minting, burning, or stability fees.
*   **Edge Cases:** Requires thorough testing for edge cases like tiny amounts, prices changing rapidly between calculations, etc.

This contract provides a solid foundation for a synthetic asset protocol and demonstrates a variety of concepts beyond basic token or simple DeFi contracts, while meeting the function count requirement.