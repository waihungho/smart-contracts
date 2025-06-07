Okay, let's create a smart contract that acts as a **Dynamic Decentralized Asset Fund (DDAF)**. This contract allows users to deposit various approved assets (ETH, ERC-20s, potentially tracking ERC-721s) and receive shares representing ownership of the fund's Net Asset Value (NAV). The key "advanced" and "dynamic" aspects will involve:

1.  **Handling Multiple Asset Types:** Managing balances of different ERC-20 tokens and tracking ERC-721 ownership within the fund.
2.  **Dynamic Strategy Execution:** Allowing the fund manager (or potentially governance) to execute arbitrary calls on *approved* external "Strategy" contracts (e.g., interacting with lending protocols, staking pools, DEXs) using the fund's assets. This requires low-level calls and careful access control.
3.  **NAV Calculation:** Calculating the total value of the fund's assets (including those held in strategies) requiring integration with price oracles.
4.  **Proportional Redemption:** Allowing users to redeem shares for a proportional value of the fund's liquid assets.
5.  **Dynamic Fees:** Implementing adjustable management and performance fees.
6.  **ERC721 Handling:** Implementing the `onERC721Received` hook to accept NFTs.

This is more complex than a simple token or vault and incorporates elements from DeFi asset management and strategic execution.

**Disclaimer:** This is a conceptual example. A production-ready contract like this would require extensive testing, security audits, and robust oracle infrastructure. NFT valuation within NAV is particularly complex and often handled off-chain or by specific valuation oracles. For this example, NFTs will be tracked but not included in the primary NAV calculation for simplification, highlighting this complexity.

---

**Outline & Function Summary**

**Contract Name:** `DynamicDecentralizedAssetFund`

**Core Concept:** A fund that holds multiple asset types (ETH, ERC-20, tracks ERC-721), calculates NAV, issues shares, and can dynamically interact with approved external DeFi strategy contracts under controlled execution.

**Interfaces & External Dependencies:**
*   `IERC20`: Standard ERC-20 token interface.
*   `IERC721`: Standard ERC-721 token interface.
*   `IERC721Receiver`: For receiving ERC-721 tokens.
*   `Ownable`: For access control (using OpenZeppelin).
*   `ReentrancyGuard`: To prevent reentrancy (using OpenZeppelin).
*   `SafeERC20`: For safer ERC-20 operations (using OpenZeppelin).
*   `IOracle`: An interface for a hypothetical price oracle to get asset values (placeholder).
*   `IStrategy`: An interface for hypothetical external strategy contracts (placeholder).

**State Variables:**
*   `owner`: Address with administrative privileges.
*   `sharesSupply`: Total supply of fund shares (ERC-20 like representation, but not a full ERC-20).
*   `shares`: Mapping of user addresses to their share balance.
*   `allowedAssets`: Mapping of asset contract addresses (ERC20/ERC721) to boolean indicating if they are allowed for deposit/holding.
*   `assetBalances`: Mapping of allowed ERC20 asset addresses to the fund's balance of that asset (excludes assets locked in strategies).
*   `nftHoldings`: Mapping of NFT collection addresses to mapping of token IDs to boolean indicating ownership by the fund.
*   `allowedStrategies`: Mapping of strategy contract addresses to boolean indicating if they are approved for interaction.
*   `activeStrategies`: Mapping of strategy contract addresses to boolean indicating if they are currently active and executable.
*   `oracle`: Address of the price oracle contract.
*   `managementFeeRate`: Basis points for the management fee (e.g., 50 = 0.5%).
*   `performanceFeeRate`: Basis points for the performance fee.
*   `highWatermark`: The highest NAV per share reached, used for performance fee calculation.
*   `totalManagementFeesAccrued`: Total accumulated management fees.
*   `totalPerformanceFeesAccrued`: Total accumulated performance fees.

**Events:**
*   `AssetAllowed`: Emitted when an asset is added to the allowed list.
*   `AssetDisallowed`: Emitted when an asset is removed from the allowed list.
*   `StrategyAllowed`: Emitted when a strategy is added to the allowed list.
*   `StrategyDisallowed`: Emitted when a strategy is removed from the allowed list.
*   `StrategyActivated`: Emitted when a strategy is activated.
*   `StrategyDeactivated`: Emitted when a strategy is deactivated.
*   `Deposit`: Emitted when a user deposits assets and receives shares.
*   `Redemption`: Emitted when a user redeems shares and receives assets.
*   `StrategyCallExecuted`: Emitted when a dynamic call to a strategy is made.
*   `FeesCollected`: Emitted when fees are collected by the owner.
*   `ManagementFeeRateUpdated`: Emitted when management fee rate is changed.
*   `PerformanceFeeRateUpdated`: Emitted when performance fee rate is changed.

**Functions (Total: 31)**

**Admin & Setup (onlyOwner):**
1.  `constructor(address _oracle)`: Initializes the contract, sets the owner and oracle address.
2.  `addAllowedAsset(address _asset, bool _isERC721)`: Adds an asset (ERC-20 or ERC-721) to the list of allowed assets for deposits/holdings.
3.  `removeAllowedAsset(address _asset)`: Removes an asset from the allowed list.
4.  `addAllowedStrategy(address _strategy)`: Adds a strategy contract address to the list of approved strategies.
5.  `removeAllowedStrategy(address _strategy)`: Removes a strategy from the approved list.
6.  `activateStrategy(address _strategy)`: Activates an approved strategy, allowing the fund to interact with it via `executeStrategyCall`.
7.  `deactivateStrategy(address _strategy)`: Deactivates an active strategy.
8.  `setManagementFeeRate(uint256 _rate)`: Sets the management fee rate in basis points.
9.  `setPerformanceFeeRate(uint256 _rate)`: Sets the performance fee rate in basis points.
10. `collectFees()`: Allows the owner to withdraw accrued management and performance fees.
11. `transferAssetOut(address _asset, address _recipient, uint256 _amount)`: Transfers an allowed ERC-20 asset held by the fund to a specified recipient (e.g., to fund a strategy).
12. `transferNFTOut(address _collection, address _recipient, uint256 _tokenId)`: Transfers an allowed ERC-721 asset held by the fund to a specified recipient.
13. `transferOwnership(address newOwner)`: Transfers contract ownership (inherited from Ownable).

**User Interaction (Public/External):**
14. `depositETH()`: Payable function to deposit ETH into the fund in exchange for shares.
15. `depositERC20(address _token, uint256 _amount)`: Deposits an allowed ERC-20 token into the fund in exchange for shares (requires prior approval).
16. `depositERC721(address _collection, uint256 _tokenId)`: Deposits an allowed ERC-721 token into the fund. Shares are *not* minted proportionally for NFTs in this model (see explanation below).
17. `onERC721Received(address operator, address from, uint256 tokenId, bytes data)`: ERC-721 standard receiver hook to allow the contract to accept NFTs transferred to it.
18. `redeemShares(uint256 _sharesToRedeem)`: Burns shares and redeems a proportional value of the *liquid* fund assets (ETH and ERC-20s held directly by the fund, *not* including NFTs or assets locked in strategies). Assets are distributed proportionally based on current liquid holdings.

**Fund Management & Strategy Execution (onlyOwner, protected):**
19. `executeStrategyCall(address _strategy, bytes memory _callData)`: Allows the owner to execute an arbitrary function call on an *active* and *allowed* strategy contract using low-level `.call()`.
20. `withdrawFromStrategy(address _strategy, bytes memory _callData)`: A specific wrapper or pattern for executing a call on a strategy that is expected to result in assets being returned to the fund. (Could be combined with #19, but separating makes intent clearer).
21. `updateHighWatermark()`: Owner can trigger updating the high watermark for performance fee calculation after significant gains are realized or NAV is recalculated.

**Internal Helpers:**
*   `_calculateNAV()`: Internal function to calculate the total Net Asset Value of the fund (summing values of all held ETH and ERC-20s, using oracle prices; *excludes* NFT value).
*   `_getAssetValue(address _asset, uint256 _amount)`: Internal function to get the value of a specific asset amount using the oracle.
*   `_mintShares(address _recipient, uint255 _amount)`: Internal function to mint shares.
*   `_burnShares(address _holder, uint255 _amount)`: Internal function to burn shares.
*   `_accrueFees()`: Internal function to calculate and accrue management fees (e.g., based on time or activity). Performance fees are calculated on redemption/withdrawal.

**View Functions (Public):**
22. `getTotalShares()`: Returns the total supply of fund shares.
23. `getSharePrice()`: Returns the current NAV per share.
24. `getNAV()`: Returns the total Net Asset Value of the fund.
25. `getFundETHBalance()`: Returns the current ETH balance of the fund.
26. `getFundERC20Balance(address _token)`: Returns the balance of a specific ERC-20 token held directly by the fund.
27. `getFundNFTCount(address _collection)`: Returns the count of NFTs of a specific collection held by the fund.
28. `isAssetAllowed(address _asset)`: Checks if an asset is on the allowed list.
29. `isStrategyAllowed(address _strategy)`: Checks if a strategy is on the approved list.
30. `isStrategyActive(address _strategy)`: Checks if a strategy is currently active.
31. `getAccruedFees()`: Returns the currently accrued management and performance fees.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// --- Outline & Function Summary ---
// Contract Name: DynamicDecentralizedAssetFund
// Core Concept: A fund that holds multiple asset types (ETH, ERC-20, tracks ERC-721), calculates NAV, issues shares, and can dynamically interact with approved external DeFi strategy contracts under controlled execution.
// This is a conceptual example and requires robust oracle infrastructure and audits for production use. NFT valuation is complex and not included in primary NAV for simplicity here.

// State Variables:
// owner: Address with administrative privileges (from Ownable)
// sharesSupply: Total supply of fund shares (uint256)
// shares: Mapping of user addresses to their share balance (address => uint256)
// allowedAssets: Mapping of asset contract addresses (ERC20/ERC721) to boolean indicating if allowed (address => bool)
// allowedAssetTypes: Mapping of allowed asset addresses to their type (0=Unknown, 1=ERC20, 2=ERC721) (address => uint8)
// assetBalances: Mapping of allowed ERC20 asset addresses to the fund's balance (address => uint256)
// nftHoldings: Mapping of NFT collection addresses to mapping of token IDs to boolean (address => mapping(uint256 => bool))
// allowedStrategies: Mapping of strategy contract addresses to boolean if approved (address => bool)
// activeStrategies: Mapping of strategy contract addresses to boolean if currently active (address => bool)
// oracle: Address of the price oracle contract (address)
// managementFeeRate: Basis points for management fee (uint256)
// performanceFeeRate: Basis points for performance fee (uint256)
// highWatermark: Highest NAV per share reached (uint256)
// totalManagementFeesAccrued: Total accumulated management fees (uint256)
// totalPerformanceFeesAccrued: Total accumulated performance fees (uint256)

// Events:
// AssetAllowed(address asset, bool isERC721)
// AssetDisallowed(address asset)
// StrategyAllowed(address strategy)
// StrategyDisallowed(address strategy)
// StrategyActivated(address strategy)
// StrategyDeactivated(address strategy)
// Deposit(address indexed user, address indexed asset, uint256 amount, uint256 sharesMinted)
// DepositETH(address indexed user, uint256 amount, uint256 sharesMinted)
// DepositNFT(address indexed user, address indexed collection, uint256 tokenId)
// Redemption(address indexed user, uint256 sharesBurned, uint256 valueRedeemed)
// StrategyCallExecuted(address indexed strategy, bytes4 selector, bytes callData, bool success, bytes returnData)
// FeesCollected(address indexed collector, uint256 managementFees, uint256 performanceFees)
// ManagementFeeRateUpdated(uint256 newRate)
// PerformanceFeeRateUpdated(uint256 newRate)

// Functions (Total: 31)
// Admin & Setup (onlyOwner):
// 1. constructor(address _oracle)
// 2. addAllowedAsset(address _asset, uint8 _type) // 1 for ERC20, 2 for ERC721
// 3. removeAllowedAsset(address _asset)
// 4. addAllowedStrategy(address _strategy)
// 5. removeAllowedStrategy(address _strategy)
// 6. activateStrategy(address _strategy)
// 7. deactivateStrategy(address _strategy)
// 8. setManagementFeeRate(uint256 _rate)
// 9. setPerformanceFeeRate(uint256 _rate)
// 10. collectFees()
// 11. transferAssetOut(address _asset, address _recipient, uint256 _amount)
// 12. transferNFTOut(address _collection, address _recipient, uint256 _tokenId)
// 13. transferOwnership(address newOwner) // Inherited from Ownable

// User Interaction (Public/External):
// 14. depositETH() payable
// 15. depositERC20(address _token, uint256 _amount)
// 16. depositERC721(address _collection, uint256 _tokenId)
// 17. onERC721Received(address operator, address from, uint256 tokenId, bytes data) // ERC721Receiver hook
// 18. redeemShares(uint256 _sharesToRedeem) // Redeems for proportional liquid assets

// Fund Management & Strategy Execution (onlyOwner, protected by ReentrancyGuard):
// 19. executeStrategyCall(address _strategy, bytes memory _callData)
// 20. withdrawFromStrategy(address _strategy, bytes memory _callData) // Wrapper for calls expected to return assets
// 21. updateHighWatermark()

// Internal Helpers:
// _calculateNAV() internal view returns (uint256 totalNAV)
// _getAssetValue(address _asset, uint256 _amount) internal view returns (uint256 valueInUSD) // Requires Oracle
// _mintShares(address _recipient, uint256 _amount) internal
// _burnShares(address _holder, uint256 _amount) internal
// _accrueManagementFees() internal // Accrues fees based on NAV over time - simplified here
// _calculatePerformanceFee(uint256 navIncrease) internal view returns (uint256 feeAmount)

// View Functions (Public):
// 22. getTotalShares() external view returns (uint256)
// 23. getSharePrice() external view returns (uint256) // NAV per share
// 24. getNAV() external view returns (uint256) // Total NAV
// 25. getFundETHBalance() external view returns (uint256)
// 26. getFundERC20Balance(address _token) external view returns (uint256)
// 27. getFundNFTCount(address _collection) external view returns (uint256)
// 28. isAssetAllowed(address _asset) external view returns (bool)
// 29. isStrategyAllowed(address _strategy) external view returns (bool)
// 30. isStrategyActive(address _strategy) external view returns (bool)
// 31. getAccruedFees() external view returns (uint256 management, uint256 performance)

// --- End of Outline & Summary ---


// --- Placeholder Interfaces ---

// Hypothetical Oracle Interface (e.g., for Chainlink, Band Protocol, etc.)
interface IOracle {
    // Function to get price of asset in USD (or a common base currency like ETH)
    // Returns price per unit (e.g., 1 token), scaled by decimals.
    // Assumes price feed returns price with a fixed decimal precision (e.g., 8 or 18).
    // Need to handle different token decimals and feed decimals.
    // For simplicity, let's assume price is in USD * 10^18 for 1e18 units of the asset.
    // A real oracle integration would need more complex scaling logic.
    function getAssetPrice(address _asset) external view returns (uint256 price); // Price of 1e18 of _asset in USD*1e18
    function getETHPrice() external view returns (uint256 price); // Price of 1e18 ETH in USD*1e18
}

// Hypothetical Strategy Interface (Example: A simple staking strategy)
// A real strategy would have functions like deposit, withdraw, claimRewards etc.
// This interface is just to show how the fund *could* interact.
interface IStrategy {
    // Example functions a strategy might have
    // function deposit(uint256 amount) external;
    // function withdraw(uint256 amount) external;
    // function claimRewards() external;
    // function getStrategyBalance(address asset) external view returns (uint256);
}

// --- Contract Implementation ---

contract DynamicDecentralizedAssetFund is Ownable, ReentrancyGuard, IERC721Receiver {
    using SafeERC20 for IERC20;
    using Address for address;

    // --- State Variables ---

    uint256 public sharesSupply;
    mapping(address => uint256) public shares; // User shares

    // Asset management
    mapping(address => bool) public allowedAssets;
    mapping(address => uint8) public allowedAssetTypes; // 1: ERC20, 2: ERC721
    mapping(address => uint256) public assetBalances; // ERC20 balances held directly by the fund
    mapping(address => mapping(uint256 => bool)) public nftHoldings; // ERC721 token IDs held by the fund

    // Strategy management
    mapping(address => bool) public allowedStrategies;
    mapping(address => bool) public activeStrategies;

    IOracle public oracle;

    // Fees
    uint256 public managementFeeRate; // in basis points (e.g., 50 = 0.5%)
    uint256 public performanceFeeRate; // in basis points
    uint256 public highWatermark; // NAV per share at the time highwatermark was last set or passed
    uint256 public totalManagementFeesAccrued;
    uint256 public totalPerformanceFeesAccrued;

    // Constants
    uint256 private constant BASIS_POINTS_DENOMINATOR = 10000;
    uint256 private constant ASSET_TYPE_ERC20 = 1;
    uint256 private constant ASSET_TYPE_ERC721 = 2;
    uint256 private constant ORACLE_PRICE_DECIMALS = 1e18; // Assuming oracle returns price * 1e18

    // --- Events ---

    event AssetAllowed(address indexed asset, uint8 assetType);
    event AssetDisallowed(address indexed asset);
    event StrategyAllowed(address indexed strategy);
    event StrategyDisallowed(address indexed strategy);
    event StrategyActivated(address indexed strategy);
    event StrategyDeactivated(address indexed strategy);
    event Deposit(address indexed user, address indexed asset, uint256 amount, uint256 sharesMinted);
    event DepositETH(address indexed user, uint256 amount, uint256 sharesMinted);
    event DepositNFT(address indexed user, address indexed collection, uint256 tokenId);
    event Redemption(address indexed user, uint256 sharesBurned, uint256 valueRedeemed);
    event StrategyCallExecuted(address indexed strategy, bytes4 selector, bytes callData, bool success, bytes returnData);
    event FeesCollected(address indexed collector, uint256 managementFees, uint256 performanceFees);
    event ManagementFeeRateUpdated(uint256 newRate);
    event PerformanceFeeRateUpdated(uint256 newRate);

    // --- Errors ---

    error AssetNotAllowed(address asset);
    error AssetAlreadyAllowed(address asset);
    error InvalidAssetType();
    error StrategyNotAllowed(address strategy);
    error StrategyAlreadyAllowed(address strategy);
    error StrategyNotActive(address strategy);
    error ZeroAddress();
    error AmountMustBeGreaterThanZero();
    error InvalidFeeRate();
    error NoFeesToCollect();
    error NotEnoughShares(uint256 required, uint256 available);
    error ERC721DepositNotSupportedForShares(); // Clarifies NFT deposit model
    error NFTNotOwnedByFund(address collection, uint256 tokenId);
    error LowLevelCallFailed(bytes returnData);
    error CallMustBeFromOwner(); // Redundant with onlyOwner, but explicit for clarity in some functions

    // --- Constructor ---

    constructor(address _oracle) Ownable(msg.sender) {
        if (_oracle == address(0)) revert ZeroAddress();
        oracle = IOracle(_oracle);
        // Initialize high watermark for the first deposit
        highWatermark = 1 ether; // Assuming initial share price is 1 USD (or base unit)
    }

    // --- Admin & Setup (onlyOwner) ---

    // 2. addAllowedAsset
    function addAllowedAsset(address _asset, uint8 _type) external onlyOwner {
        if (_asset == address(0)) revert ZeroAddress();
        if (allowedAssets[_asset]) revert AssetAlreadyAllowed(_asset);
        if (_type != ASSET_TYPE_ERC20 && _type != ASSET_TYPE_ERC721) revert InvalidAssetType();

        allowedAssets[_asset] = true;
        allowedAssetTypes[_asset] = _type;
        emit AssetAllowed(_asset, _type);
    }

    // 3. removeAllowedAsset
    function removeAllowedAsset(address _asset) external onlyOwner {
        if (_asset == address(0)) revert ZeroAddress();
        if (!allowedAssets[_asset]) revert AssetNotAllowed(_asset);
        // Consider checks if fund still holds this asset type before removal

        allowedAssets[_asset] = false;
        allowedAssetTypes[_asset] = 0; // Reset type
        emit AssetDisallowed(_asset);
    }

    // 4. addAllowedStrategy
    function addAllowedStrategy(address _strategy) external onlyOwner {
        if (_strategy == address(0)) revert ZeroAddress();
        if (allowedStrategies[_strategy]) revert StrategyAlreadyAllowed(_strategy);

        allowedStrategies[_strategy] = true;
        emit StrategyAllowed(_strategy);
    }

    // 5. removeAllowedStrategy
    function removeAllowedStrategy(address _strategy) external onlyOwner {
        if (_strategy == address(0)) revert ZeroAddress();
        if (!allowedStrategies[_strategy]) revert StrategyNotAllowed(_strategy);
        if (activeStrategies[_strategy]) revert StrategyActiveCannotRemove(_strategy); // Assuming you can't remove active strategies

        allowedStrategies[_strategy] = false;
        emit StrategyDisallowed(_strategy);
    }

    // 6. activateStrategy
    function activateStrategy(address _strategy) external onlyOwner {
        if (!allowedStrategies[_strategy]) revert StrategyNotAllowed(_strategy);
        if (activeStrategies[_strategy]) revert StrategyAlreadyActive(_strategy); // Assuming already active is an error

        activeStrategies[_strategy] = true;
        emit StrategyActivated(_strategy);
    }

    // 7. deactivateStrategy
    function deactivateStrategy(address _strategy) external onlyOwner {
        if (!allowedStrategies[_strategy]) revert StrategyNotAllowed(_strategy);
        if (!activeStrategies[_strategy]) revert StrategyNotActive(_strategy);

        activeStrategies[_strategy] = false;
        emit StrategyDeactivated(_strategy);
    }

    // 8. setManagementFeeRate
    function setManagementFeeRate(uint256 _rate) external onlyOwner {
        // Add rate validation if needed (e.g., max rate)
        managementFeeRate = _rate;
        emit ManagementFeeRateUpdated(_rate);
    }

    // 9. setPerformanceFeeRate
    function setPerformanceFeeRate(uint256 _rate) external onlyOwner {
         // Add rate validation if needed (e.g., max rate)
        performanceFeeRate = _rate;
        emit PerformanceFeeRateUpdated(_rate);
    }

    // 10. collectFees
    function collectFees() external onlyOwner nonReentrant {
        uint256 management = totalManagementFeesAccrued;
        uint256 performance = totalPerformanceFeesAccrued;

        if (management == 0 && performance == 0) revert NoFeesToCollect();

        totalManagementFeesAccrued = 0;
        totalPerformanceFeesAccrued = 0;

        // Fees are collected in ETH for simplicity in this example
        // In a real scenario, fees might be collected in a specific token, or a mix.
        // This requires selling assets or holding a fee token.
        // For this concept, we'll assume fees are ETH or equivalent value.
        // A robust fee collection would convert accrued value to a specific token or ETH.
        // Let's simplify: the owner can withdraw ANY asset balance up to the accrued fee VALUE.
        // This is complex. Let's simplify again: fees are accrued as a VALUE, owner can withdraw ETH equal to this value *if available*.

        // More practical approach: owner withdraws accrued fees as ETH or a designated fee token.
        // Let's assume fees are accrued as a 'claim' in USD value, and the owner can withdraw available ETH/USDC etc. up to that value.
        // The simplest model for this example: Fees are accrued *in kind* or as a value claim, and owner can withdraw *any* available asset balance corresponding to fee value.
        // Let's revert to the initial idea: total accrued fees are values. Owner can claim these values.
        // How are they claimed? Either from liquid assets, or new assets are generated (minting a fee token).
        // Safest: owner claims fees as a *value* and needs to withdraw available assets manually or via helper.
        // Let's assume fees are accrued as ETH value, and owner can withdraw ETH.

        // Re-simplifying: Let's say fees are accrued in ETH only for this example's state variables.
        // (Note: A real fund would accrue value proportionally across assets).

        uint256 ethAmount = management + performance; // Assuming fees are recorded in ETH value

        // Need to check if fund has enough liquid ETH
        if (address(this).balance < ethAmount) {
             // Cannot withdraw all fees if not enough ETH. Withdraw available ETH.
             ethAmount = address(this).balance;
             // Update remaining accrued fees (more complex) or just log partial withdrawal.
             // For simplicity, let's just withdraw available and reset. Real fee system needs tracking unpaid fees.
        }


        (bool success, ) = payable(owner()).call{value: ethAmount}("");
        if (!success) {
             // Handle failure - maybe revert, or log and keep fees accrued. Reverting is safer.
             // If we revert, reset the state change before the transfer attempt.
             // Need a mechanism to track pending fees if transfer fails.
             // Let's simplify again: fees are just values recorded, owner *uses* collectFees to see the value, then uses transferAssetOut / ETH withdrawal to claim.
             // The state variables `totalManagementFeesAccrued` etc. now just represent a claimable value.
             // Let's make collectFees() trigger the withdrawal.
             // We need to decide *in what asset* the fees are collected. ETH is simplest.

             // Ok, final attempt at collectFees logic for this example:
             // Fees are accrued as a USD value. When collecting, calculate how much ETH that value is worth now.
             // Try to send that ETH amount. If not enough ETH, send all available ETH.
             // This requires converting accrued USD value to ETH value using the oracle.

             uint256 accruedValueUSD = totalManagementFeesAccrued + totalPerformanceFeesAccrued;
             if (accruedValueUSD == 0) revert NoFeesToCollect();

             // Get current ETH price (USD per ETH)
             uint256 ethPrice = oracle.getETHPrice();
             if (ethPrice == 0) revert OracleError("ETH price unavailable"); // Need OracleError

             // Convert USD value to ETH amount: (accruedValueUSD * 1e18) / ethPrice
             // Assuming accruedValueUSD is also scaled somehow, or represents USD cents * 1e16 etc.
             // Let's assume accrued fees are stored in USD * 1e18 for consistency with oracle.
             uint256 ethAmountToWithdraw = (accruedValueUSD * ORACLE_PRICE_DECIMALS) / ethPrice;

             uint256 actualEthWithdrawal = Math.min(ethAmountToWithdraw, address(this).balance); // Using SafeMath or similar min

             totalManagementFeesAccrued = 0; // This is only correct if we assume all fees were collected
             totalPerformanceFeesAccrued = 0; // A real system needs to track remaining fees

             (bool success, ) = payable(owner()).call{value: actualEthWithdrawal}("");
             if (!success) {
                 // Revert or handle... Reverting is safer.
                 // Revert before modifying accrued fees if transfer might fail.
                 // Let's add accrued fees back if transfer fails. Or better, calculate *after* transfer.

                 // Recalculating after transfer:
                 // This is getting too complex for an example. Let's simplify fee collection:
                 // `collectFees` just zeros out the accrued fees and logs the amount.
                 // The owner uses `transferAssetOut` or ETH withdrawal manually to claim assets equivalent to the fee value.
                 // The accrued fee variables simply represent a claimable value.

                 uint256 mgmt = totalManagementFeesAccrued;
                 uint256 perf = totalPerformanceFeesAccrued;
                 totalManagementFeesAccrued = 0;
                 totalPerformanceFeesAccrued = 0;
                 emit FeesCollected(owner(), mgmt, perf);
             } else {
                 // If transfer succeeded, zero out fees and emit. This still isn't perfect if only partial ETH was sent.
                 // Let's emit the *attempted* withdrawal amount, or just the accrued value.
                 // Sticking to the previous simplified approach: accrue values, owner claims manually.
                 uint256 mgmt = totalManagementFeesAccrued;
                 uint256 perf = totalPerformanceFeesAccrued;
                 totalManagementFeesAccrued = 0;
                 totalPerformanceFeesAccrued = 0;
                 emit FeesCollected(owner(), mgmt, perf);
             }
        }


    }

    // 11. transferAssetOut
    function transferAssetOut(address _asset, address _recipient, uint256 _amount) external onlyOwner nonReentrant {
        if (_asset == address(0) || _recipient == address(0)) revert ZeroAddress();
        if (_amount == 0) revert AmountMustBeGreaterThanZero();
        if (!allowedAssets[_asset] || allowedAssetTypes[_asset] != ASSET_TYPE_ERC20) revert AssetNotAllowed(_asset);
        if (assetBalances[_asset] < _amount) revert NotEnoughAsset(_asset, assetBalances[_asset], _amount); // Need NotEnoughAsset error

        IERC20(_asset).safeTransfer(_recipient, _amount);
        assetBalances[_asset] -= _amount; // Update internal balance tracking
        // Note: This bypasses share calculations. Used for funding strategies or specific admin withdrawals.
        // Be careful: transferring assets out directly affects NAV without burning shares, impacting share price.
        // Use cases: Sending to a strategy, paying expenses, distributing specific assets.
    }

    // 12. transferNFTOut
    function transferNFTOut(address _collection, address _recipient, uint256 _tokenId) external onlyOwner nonReentrant {
        if (_collection == address(0) || _recipient == address(0)) revert ZeroAddress();
        if (!allowedAssets[_collection] || allowedAssetTypes[_collection] != ASSET_TYPE_ERC721) revert AssetNotAllowed(_collection);
        if (!nftHoldings[_collection][_tokenId]) revert NFTNotOwnedByFund(_collection, _tokenId);

        IERC721(_collection).safeTransferFrom(address(this), _recipient, _tokenId);
        nftHoldings[_collection][_tokenId] = false; // Mark as no longer held
        // Note: Similar to transferAssetOut, this affects the fund's holdings outside of share redemption logic.
    }

    // 13. transferOwnership - inherited from Ownable

    // --- User Interaction (Public/External) ---

    // Internal helper to calculate shares to mint
    function _calculateSharesToMint(uint256 _depositValueUSD) internal view returns (uint256 sharesToMint) {
        uint256 currentNAV = _calculateNAV();

        if (sharesSupply == 0 || currentNAV == 0) {
            // First deposit or fund is empty, 1 share = 1 unit of deposit value (e.g., 1 USD equivalent)
            // Assuming _depositValueUSD is already scaled (e.g., * 1e18)
             sharesToMint = _depositValueUSD;
        } else {
            // shares = (depositValue * totalShares) / totalNAV
            // Using 1e18 as a precision factor for shares, assuming NAV is also scaled.
            // Let's assume shares are also scaled by 1e18.
             sharesToMint = (_depositValueUSD * sharesSupply) / currentNAV;
        }
         if (sharesToMint == 0) revert DepositTooSmall(); // Need DepositTooSmall error
    }

    // Internal helper to mint shares
    function _mintShares(address _recipient, uint256 _amount) internal {
         shares[_recipient] += _amount;
         sharesSupply += _amount;
    }

    // Internal helper to burn shares
    function _burnShares(address _holder, uint256 _amount) internal {
        if (shares[_holder] < _amount) revert NotEnoughShares(shares[_holder], _amount);
         shares[_holder] -= _amount;
         sharesSupply -= _amount;
    }

    // 14. depositETH
    function depositETH() external payable nonReentrant {
        uint256 ethAmount = msg.value;
        if (ethAmount == 0) revert AmountMustBeGreaterThanZero();

        // Get current ETH value in USD
        uint256 ethPrice = oracle.getETHPrice();
        if (ethPrice == 0) revert OracleError("ETH price unavailable");

        // Value of deposit in USD (scaled)
        // (ethAmount * ethPrice) / 1e18 (assuming ethAmount is in wei, ethPrice is USD*1e18 per 1e18 ETH)
        // Need to scale ethAmount by 1e18 if ethPrice is price per 1e18 unit
        // If ethAmount is in wei (1e18), and ethPrice is USD*1e18 per 1e18 ETH, depositValue is (ethAmount * ethPrice) / 1e18
        uint256 depositValueUSD = (ethAmount * ethPrice) / ORACLE_PRICE_DECIMALS;
        if (depositValueUSD == 0) revert OracleError("Deposit value too low or oracle issue");


        uint256 sharesToMint = _calculateSharesToMint(depositValueUSD);
        _mintShares(msg.sender, sharesToMint);

        // No need to update assetBalances for ETH, it's the contract balance.
        emit DepositETH(msg.sender, ethAmount, sharesToMint);

        // Update high watermark if necessary
        uint256 currentSharePrice = getSharePrice(); // Recalculates NAV and share price
        if (currentSharePrice > highWatermark) {
            highWatermark = currentSharePrice;
        }
    }

    // 15. depositERC20
    function depositERC20(address _token, uint256 _amount) external nonReentrant {
        if (_amount == 0) revert AmountMustBeGreaterThanZero();
        if (!allowedAssets[_token] || allowedAssetTypes[_token] != ASSET_TYPE_ERC20) revert AssetNotAllowed(_token);

        // Need to get token decimals to calculate correct USD value
        uint8 tokenDecimals = IERC20(_token).decimals(); // Assumes ERC20 standard has decimals()
        uint256 tokenMultiplier = 10**tokenDecimals;

        // Get token price in USD
        uint256 tokenPrice = oracle.getAssetPrice(_token);
        if (tokenPrice == 0) revert OracleError("Token price unavailable");

        // Value of deposit in USD (scaled)
        // (amount * tokenPrice) / ORACLE_PRICE_DECIMALS (assuming amount is in token's native units, price is USD*1e18 per 1e18 unit)
        // Need to adjust for token decimals: (amount * tokenPrice * 1e18) / (tokenMultiplier * ORACLE_PRICE_DECIMALS)
        // Or, if oracle price is per 1 unit of the token (scaled by its decimals): (amount * tokenPrice) / 1e18
        // Let's assume oracle `getAssetPrice` returns price of 1 unit of the token, scaled by 1e18.
        // So value = (amount * price) / 1e18
        uint256 depositValueUSD = (_amount * tokenPrice) / ORACLE_PRICE_DECIMALS;
         if (depositValueUSD == 0) revert OracleError("Deposit value too low or oracle issue");


        uint256 sharesToMint = _calculateSharesToMint(depositValueUSD);
        _mintShares(msg.sender, sharesToMint);

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        assetBalances[_token] += _amount; // Update internal balance tracking

        emit Deposit(msg.sender, _token, _amount, sharesToMint);

        // Update high watermark
         uint256 currentSharePrice = getSharePrice();
         if (currentSharePrice > highWatermark) {
             highWatermark = currentSharePrice;
         }
    }

    // 16. depositERC721
    // Note: Depositing ERC721s does *not* directly mint shares in this model.
    // NFTs are tracked as assets held by the fund, but their value is excluded from NAV calculation
    // for share price determination due to valuation complexity. They represent a different class
    // of asset or a separate mechanism for value accrual/distribution.
    function depositERC721(address _collection, uint256 _tokenId) external nonReentrant {
        if (_collection == address(0)) revert ZeroAddress();
        if (!allowedAssets[_collection] || allowedAssetTypes[_collection] != ASSET_TYPE_ERC721) revert AssetNotAllowed(_collection);

        // Transfer the NFT to the contract. This relies on the sender calling transferFrom
        // *before* or the contract being approved. The `onERC721Received` hook below handles acceptance.
        // A simpler pattern is to require the user to have already transferred it,
        // and this function just registers it. Let's stick to the `transferFrom` approach for deposit.
        IERC721(_collection).transferFrom(msg.sender, address(this), _tokenId);

        // The actual tracking happens in onERC721Received
        // emit DepositNFT(msg.sender, _collection, _tokenId); // This event might be better in onERC721Received
    }

    // 17. onERC721Received
    // ERC721 standard receiver hook.
    // Called by ERC721 contracts when an NFT is transferred using safeTransferFrom.
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
        public override nonReentrant returns (bytes4)
    {
        address collection = msg.sender; // msg.sender is the NFT collection contract

        if (!allowedAssets[collection] || allowedAssetTypes[collection] != ASSET_TYPE_ERC721) {
            // Reject unallowed NFTs
            return bytes4(0); // Returning non-success magic value
        }

        // Track the NFT
        nftHoldings[collection][tokenId] = true;

        emit DepositNFT(from, collection, tokenId); // Emit deposit event here

        // Return the magic value to indicate successful reception
        return this.onERC721Received.selector;
    }

    // 18. redeemShares
    // User redeems shares for a proportional value of the fund's *liquid* ETH and ERC20 assets.
    // Assets held in strategies or NFTs are NOT included in the redeemable value here.
    // A more complex redemption would allow redeeming for assets in strategies (requiring withdrawals)
    // or handling NFT redemption (e.g., if user's share value is high enough to claim a full NFT).
    function redeemShares(uint256 _sharesToRedeem) external nonReentrant {
        if (_sharesToRedeem == 0) revert AmountMustBeGreaterThanZero();
        if (shares[msg.sender] < _sharesToRedeem) revert NotEnoughShares(shares[msg.sender], _sharesToRedeem);
        if (sharesSupply == 0) revert NoSharesMinted(); // Need NoSharesMinted error

        uint256 currentNAV = _calculateNAV();
        if (currentNAV == 0) revert FundIsEmpty(); // Need FundIsEmpty error

        // Calculate the proportional value the user is redeeming in USD (scaled)
        // redemptionValueUSD = (sharesToRedeem * totalNAV) / totalSharesSupply
        uint256 redemptionValueUSD = (_sharesToRedeem * currentNAV) / sharesSupply;
        if (redemptionValueUSD == 0) revert RedemptionValueTooSmall(); // Need RedemptionValueTooSmall error

        _burnShares(msg.sender, _sharesToRedeem);

        // Distribute liquid assets proportionally based on their current contribution to NAV
        uint256 totalLiquidValueUSD = getFundETHBalance() > 0 ? (getFundETHBalance() * oracle.getETHPrice()) / ORACLE_PRICE_DECIMALS : 0;

        address[] memory erc20Assets = new address[](allowedAssets.length); // This requires iterating or storing allowed assets in a list
        uint256 erc20Count = 0;
        // Need a way to iterate over allowedAssets map - Solidity doesn't support this directly.
        // A better approach is to store allowed assets in a dynamic array or linked list.
        // For this example, let's just iterate over known assets or require a list input.
        // Simpler: just redeem for ETH equivalent value or proportional ETH/a stablecoin.
        // Let's redeem for proportional liquid ETH + proportional value of liquid ERC20s.

        // We need the total *liquid* NAV (assets held directly by fund), not total NAV including strategies.
        uint256 liquidNAV = _calculateLiquidNAV(); // Need _calculateLiquidNAV helper

        if (liquidNAV == 0) revert NoLiquidAssetsToRedeem(); // Need NoLiquidAssetsToRedeem error

        // Calculate the user's share of liquid assets
        // liquidRedemptionValueUSD = (sharesToRedeem * liquidNAV) / totalSharesSupply
        uint256 liquidRedemptionValueUSD = (_sharesToRedeem * liquidNAV) / sharesSupply;

        // Accrue management fees before transferring assets
        // A percentage of the value being withdrawn
        uint256 managementFeeAmountUSD = (liquidRedemptionValueUSD * managementFeeRate) / BASIS_POINTS_DENOMINATOR;
        totalManagementFeesAccrued += managementFeeAmountUSD;
        liquidRedemptionValueUSD -= managementFeeAmountUSD; // User receives value minus management fee

        // Performance fee calculation is complex - needs high watermark check
        // Performance fee is typically on *profit* above high watermark.
        // Profit per share = currentSharePrice - highWatermark
        // Total profit for redeemed shares = (currentSharePrice - highWatermark) * sharesToRedeem
        // Performance fee = (profit * performanceFeeRate) / 10000
        // Only apply if currentSharePrice > highWatermark
        uint256 currentSharePrice = getSharePrice(); // Need to call this AFTER calculating liquidNAV? No, NAV is calculated first.

        uint256 performanceFeeAmountUSD = 0;
        if (currentSharePrice > highWatermark) {
             uint256 profitPerShareUSD = currentSharePrice - highWatermark; // Assuming share price is also in USD value scaled by 1e18
             uint256 totalProfitUSD = (profitPerShareUSD * _sharesToRedeem) / ORACLE_PRICE_DECIMALS; // Scale by shares decimal (1e18)
             performanceFeeAmountUSD = (totalProfitUSD * performanceFeeRate) / BASIS_POINTS_DENOMINATOR;
             totalPerformanceFeesAccrued += performanceFeeAmountUSD;
             liquidRedemptionValueUSD -= performanceFeeAmountUSD; // User receives value minus performance fee
             // Note: Fees reduce the USD value the user is entitled to receive in assets.
        }


        // Now distribute assets based on the remaining liquidRedemptionValueUSD
        // How to distribute? Proportional to current liquid holdings' value.

        uint256 ethToRedeemUSD = (getFundETHBalance() * oracle.getETHPrice()) / ORACLE_PRICE_DECIMALS;
        uint256 ethShareOfValue = (ethToRedeemUSD * liquidRedemptionValueUSD) / liquidNAV; // How much of the value should come from ETH?

        uint256 ethPrice = oracle.getETHPrice();
         if (ethPrice == 0) revert OracleError("ETH price unavailable");
        uint256 ethAmountToTransfer = (ethShareOfValue * ORACLE_PRICE_DECIMALS) / ethPrice;

        // Ensure we don't send more ETH than available
        uint256 actualEthAmount = Math.min(ethAmountToTransfer, address(this).balance); // Need SafeMath or similar

        (bool success, ) = payable(msg.sender).call{value: actualEthAmount}("");
        if (!success) {
            // Handle ETH transfer failure. Revert or log and proceed? Revert is safer.
            revert EthTransferFailed(); // Need EthTransferFailed error
        }

        // Distribute ERC20s proportionally
        // This still requires iterating allowed ERC20s.
        // Let's simplify again: Redeemers get proportional ETH *and* proportional amounts of all ERC20s.
        // Calculate total liquid ERC20 value.
        // Calculate user's share of each ERC20: (userShares / totalShares) * fundERC20Balance

        // Resetting the redemption logic to a simpler proportional withdrawal *of assets*, not value.
        // Users get (sharesToRedeem / totalSharesSupply) percentage of EACH liquid asset.

        uint256 sharesNumerator = _sharesToRedeem;
        uint256 sharesDenominator = sharesSupply;

        // ETH withdrawal
        uint256 ethBalance = address(this).balance;
        uint256 ethAmountToWithdraw = (ethBalance * sharesNumerator) / sharesDenominator;
        if (ethAmountToWithdraw > 0) {
             (bool successETH, ) = payable(msg.sender).call{value: ethAmountToWithdraw}("");
             if (!successETH) {
                 // This makes partial failure handling complex. It might be better
                 // to use a pull pattern or require users to claim assets separately.
                 // For example: redemption burns shares, updates internal "redeemable" balances.
                 // User then calls `claimRedeemedAssets()`.
                 // Let's use the direct transfer and accept the complexity or revert.
                 // Reverting if ETH transfer fails:
                 revert EthTransferFailed();
             }
        }

        // ERC20 withdrawals (requires iterating allowed ERC20s)
        // This needs a list of ERC20 assets, not a map. Let's assume a list is maintained elsewhere or iterate allowedAssets map (if possible or with helper).
        // Since direct map iteration isn't easy, let's assume a helper function or a pre-defined list.
        // For this example, we'll simulate iterating:
        // `for (address token : allowedERC20Assets)`
        // Or, let the user specify which assets they want to claim proportionally? No, that defeats 'proportional'.

        // A common pattern is to redeem for *value* in a single asset (e.g., ETH or stablecoin)
        // or proportional across a predefined list.

        // Let's revert to the proportional asset withdrawal based on shares.
        // This means user gets (shares/totalSupply) of ETH, (shares/totalSupply) of TokenA, etc.

        // Calculate total USD value redeemed (before fees)
        uint256 initialRedemptionValueUSD = (_sharesToRedeem * getNAV()) / sharesSupply; // Use total NAV for value calculation before fees? No, use liquid NAV for asset distribution.
         uint256 totalLiquidNAV = _calculateLiquidNAV();
         uint256 initialRedemptionValueUSD_Liquid = (_sharesToRedeem * totalLiquidNAV) / sharesSupply;

         // Management Fee (on total value redeemed)
         uint256 managementFeeUSD = (initialRedemptionValueUSD_Liquid * managementFeeRate) / BASIS_POINTS_DENOMINATOR;
         totalManagementFeesAccrued += managementFeeUSD;
         uint256 valueAfterManagementFee = initialRedemptionValueUSD_Liquid - managementFeeUSD;

         // Performance Fee (on profit above high watermark for these shares)
         uint256 currentSharePriceValue = getSharePrice(); // Recalculates NAV
         uint256 performanceFeeUSD = 0;
         if (currentSharePriceValue > highWatermark) {
             uint256 profitPerShare = currentSharePriceValue - highWatermark;
             uint256 totalProfitForShares = (_sharesToRedeem * profitPerShare) / sharesSupply; // Scale by shares decimal (1e18) - assuming shares are 1e18
              performanceFeeUSD = (totalProfitForShares * performanceFeeRate) / BASIS_POINTS_DENOMINATOR;
             totalPerformanceFeesAccrued += performanceFeeUSD;
         }
        uint256 finalRedemptionValueUSD = valueAfterManagementFee - performanceFeeUSD;


        _burnShares(msg.sender, _sharesToRedeem);

        // Distribute assets based on the finalRedemptionValueUSD value, proportional to the *current* liquid asset composition.
        // This requires getting the current USD value of *each* liquid asset, calculating its percentage of total liquid NAV,
        // and giving the user that percentage of their `finalRedemptionValueUSD` amount, converted back into the asset's native units.

        uint256 totalLiquidValueUSD = _calculateLiquidNAV(); // Re-calculate if needed or use value from earlier
        if (totalLiquidValueUSD == 0) {
            // This shouldn't happen if liquidNAV was checked earlier, but double check
             revert NoLiquidAssetsToRedeem();
        }

        // ETH distribution
        uint256 ethValueInFundUSD = (address(this).balance * oracle.getETHPrice()) / ORACLE_PRICE_DECIMALS;
        uint256 ethShare = (ethValueInFundUSD * 1e18) / totalLiquidValueUSD; // Percentage of liquid NAV represented by ETH (scaled)
        uint256 ethValueToUserUSD = (finalRedemptionValueUSD * ethShare) / 1e18;
        uint256 ethAmountToTransferFinal = (ethValueToUserUSD * ORACLE_PRICE_DECIMALS) / oracle.getETHPrice();

        uint256 actualEthAmountFinal = Math.min(ethAmountToTransferFinal, address(this).balance); // SafeMath
        if (actualEthAmountFinal > 0) {
             (bool successETHFinal, ) = payable(msg.sender).call{value: actualEthAmountFinal}("");
             if (!successETHFinal) revert EthTransferFailed();
        }

        // ERC20 distribution (needs iteration)
        // We need to store allowed ERC20s in a list or use a helper that iterates (complex/gas intensive).
        // Assuming we have `allowedERC20AssetsList` (not shown in state for brevity):
        /*
        for (uint i = 0; i < allowedERC20AssetsList.length; i++) {
            address token = allowedERC20AssetsList[i];
            if (allowedAssets[token] && allowedAssetTypes[token] == ASSET_TYPE_ERC20) {
                 uint256 tokenBalance = assetBalances[token];
                 if (tokenBalance > 0) {
                     uint256 tokenValueInFundUSD = (tokenBalance * oracle.getAssetPrice(token)) / ORACLE_PRICE_DECIMALS;
                     uint256 tokenShare = (tokenValueInFundUSD * 1e18) / totalLiquidValueUSD;
                     uint256 tokenValueToUserUSD = (finalRedemptionValueUSD * tokenShare) / 1e18;

                     uint256 tokenPrice = oracle.getAssetPrice(token);
                     if (tokenPrice > 0) { // Avoid division by zero
                          uint256 tokenAmountToTransferFinal = (tokenValueToUserUSD * ORACLE_PRICE_DECIMALS) / tokenPrice;
                          uint256 actualTokenAmount = Math.min(tokenAmountToTransferFinal, tokenBalance); // SafeMath
                          if (actualTokenAmount > 0) {
                              IERC20(token).safeTransfer(msg.sender, actualTokenAmount);
                              assetBalances[token] -= actualTokenAmount; // Update internal balance
                          }
                     }
                 }
            }
        }
        */
        // The ERC20 distribution requires iterating. Let's omit the loop for brevity in this example, but acknowledge its necessity.
        // A pragmatic approach is to redeem solely in ETH or a designated stablecoin. Let's refine the redemption function to do that.

        // ### REVISED REDEMPTION LOGIC ###
        // Redeem shares for equivalent value in ETH based on *liquid* NAV.
        // This is simpler and avoids proportional distribution issues.

        function redeemSharesForETH(uint256 _sharesToRedeem) external nonReentrant {
            if (_sharesToRedeem == 0) revert AmountMustBeGreaterThanZero();
            if (shares[msg.sender] < _sharesToRedeem) revert NotEnoughShares(shares[msg.sender], _sharesToRedeem);
            if (sharesSupply == 0) revert NoSharesMinted();

            uint256 totalLiquidNAV_USD = _calculateLiquidNAV();
            if (totalLiquidNAV_USD == 0) revert NoLiquidAssetsToRedeem();

            // Calculate value user is redeeming (proportional to liquid NAV)
            uint256 redemptionValueUSD = (_sharesToRedeem * totalLiquidNAV_USD) / sharesSupply;
            if (redemptionValueUSD == 0) revert RedemptionValueTooSmall();

            // Accrue fees
             uint256 managementFeeUSD = (redemptionValueUSD * managementFeeRate) / BASIS_POINTS_DENOMINATOR;
             totalManagementFeesAccrued += managementFeeUSD;
             uint256 valueAfterManagementFee = redemptionValueUSD - managementFeeUSD;

             uint256 currentSharePriceValue = getSharePrice(); // Uses total NAV
             uint256 performanceFeeUSD = 0;
             // Performance fee on profit of these shares over high watermark
             if (currentSharePriceValue > highWatermark) {
                 uint256 profitPerShare = currentSharePriceValue - highWatermark; // Assuming scaled value
                 uint256 totalProfitForShares = (_sharesToRedeem * profitPerShare) / sharesSupply; // Scale by shares decimal (1e18)
                 performanceFeeUSD = (totalProfitForShares * performanceFeeRate) / BASIS_POINTS_DENOMINATOR;
                 totalPerformanceFeesAccrued += performanceFeeUSD;
             }
            uint256 finalRedemptionValueUSD = valueAfterManagementFee - performanceFeeUSD;

            _burnShares(msg.sender, _sharesToRedeem);

            // Convert final USD value to ETH amount
            uint256 ethPrice = oracle.getETHPrice();
             if (ethPrice == 0) revert OracleError("ETH price unavailable");
            uint256 ethAmountToTransfer = (finalRedemptionValueUSD * ORACLE_PRICE_DECIMALS) / ethPrice;

            // Ensure we don't send more ETH than available liquid ETH
            uint256 actualEthAmount = Math.min(ethAmountToTransfer, address(this).balance); // SafeMath min

            // Update high watermark if share price dropped significantly after redemptions/fees
            uint256 newSharePrice = getSharePrice();
            if (newSharePrice < highWatermark) {
                // Reset high watermark if NAV per share falls below it
                highWatermark = newSharePrice; // Or reset to 0, or a previous value. Resetting is common.
            }


            (bool success, ) = payable(msg.sender).call{value: actualEthAmount}("");
            if (!success) {
                 // If ETH transfer fails, should shares be returned? Complex.
                 // Reverting is safest for atomic operation.
                 // BUT, if fees were already accrued, reverting means fees aren't accrued.
                 // A robust system would handle this carefully. For example:
                 // 1. Calculate fees and amount to send.
                 // 2. Burn shares.
                 // 3. Transfer ETH. If fails, revert state including shares and fees.
                 revert EthTransferFailed();
            }

            emit Redemption(msg.sender, _sharesToRedeem, actualEthAmount); // Emitting actual amount transferred or USD value? Let's emit ETH value.
        }
        // End of REVISED REDEMPTION LOGIC -> Replacing original redeemShares with redeemSharesForETH (Function 18)

    // --- Fund Management & Strategy Execution (onlyOwner, protected) ---

    // 19. executeStrategyCall
    // Allows owner to call arbitrary function on an active strategy.
    // CRITICAL SECURITY NOTE: The strategy contract must be trusted implicitly or
    // calls must be restricted to a safe allow-list of function selectors and parameters.
    // A malicious strategy or call can drain funds if not careful.
    function executeStrategyCall(address _strategy, bytes memory _callData) external onlyOwner nonReentrant returns (bool success, bytes memory returnData) {
        if (_strategy == address(0)) revert ZeroAddress();
        if (!activeStrategies[_strategy]) revert StrategyNotActive(_strategy);

        // Low-level call allows calling any function on the strategy
        (success, returnData) = _strategy.call(_callData);

        // Decide whether to revert on failure. Often, strategy calls might fail temporarily.
        // For critical operations (like withdrawals), you might want to revert.
        // For others (like claiming rewards), maybe not.
        // Simple approach: just emit the result. Owner needs to monitor events.
        // A more secure approach: Only allow specific, pre-approved function selectors and check return data.

        emit StrategyCallExecuted(_strategy, bytes4(_callData), _callData, success, returnData);

        if (!success) {
            // Optionally include return data in error
            // If returnData is an error string, decode it.
            // This is complex. Let's just indicate failure.
            // revert LowLevelCallFailed(returnData); // Option to revert on failure
        }

        // After executing a strategy call (especially withdrawals),
        // assetBalances might change. NAV needs implicit re-calculation for deposits/redemptions.
        // Explicitly updating high watermark might be needed if profit was realized.
    }

    // 20. withdrawFromStrategy
    // Specific function to execute a call on a strategy that is expected to result in
    // assets being transferred *from* the strategy *to* this fund contract.
    // This is a wrapper around executeStrategyCall, emphasizing the intent.
    // Could add checks specific to withdrawal calls.
    function withdrawFromStrategy(address _strategy, bytes memory _callData) external onlyOwner nonReentrant returns (bool success, bytes memory returnData) {
        // Pre-call balances could be checked here to verify assets were received, but this is complex.
        // The success of the call itself is the primary indicator.
        (success, returnData) = executeStrategyCall(_strategy, _callData); // Reuse the core execution logic

        if (!success) {
             revert StrategyWithdrawalFailed(_strategy); // Need StrategyWithdrawalFailed error
        }

        // After withdrawal, ERC20 balances and ETH balance might have increased.
        // assetBalances mapping needs to be updated if the strategy directly transfers tokens back.
        // If strategy has a `claimRewards` function, the received tokens will increase assetBalances.
        // If strategy withdraws principal, those tokens return and increase assetBalances.

        // Re-calculate NAV and potentially update high watermark if needed after a successful withdrawal
        // (especially if rewards/profits were withdrawn). This could be manual via `updateHighWatermark`.
    }

    // 21. updateHighWatermark
    // Owner can call this to update the high watermark based on the current share price.
    // This is typically done after significant performance or fee collection.
    function updateHighWatermark() external onlyOwner {
        highWatermark = getSharePrice();
    }


    // --- Internal Helpers ---

    // _calculateLiquidNAV - Calculates NAV based ONLY on assets held directly by the fund (ETH and assetBalances).
    function _calculateLiquidNAV() internal view returns (uint256 totalLiquidNAV) {
         totalLiquidNAV = 0;

         // Add ETH value
         uint256 ethBalance = address(this).balance;
         if (ethBalance > 0) {
             uint256 ethPrice = oracle.getETHPrice();
             if (ethPrice > 0) {
                 totalLiquidNAV += (ethBalance * ethPrice) / ORACLE_PRICE_DECIMALS; // Assuming ethBalance is in wei, price is USD*1e18 per 1e18 ETH
             }
         }

        // Add ERC20 value
        // This requires iterating over allowed ERC20 assets.
        // Assuming a list `allowedERC20AssetsList` exists (not explicitly in state for brevity)
        /*
         for (uint i = 0; i < allowedERC20AssetsList.length; i++) {
             address token = allowedERC20AssetsList[i];
             if (allowedAssets[token] && allowedAssetTypes[token] == ASSET_TYPE_ERC20) {
                 uint256 tokenBalance = assetBalances[token];
                 if (tokenBalance > 0) {
                     uint256 tokenPrice = oracle.getAssetPrice(token);
                     if (tokenPrice > 0) {
                         // Adjust for token decimals if oracle price is per 1e18 unit
                         uint8 tokenDecimals = IERC20(token).decimals(); // Assumes decimals() exists
                         uint256 tokenMultiplier = 10**tokenDecimals;
                         uint256 value = (tokenBalance * tokenPrice * ORACLE_PRICE_DECIMALS) / (tokenMultiplier * ORACLE_PRICE_DECIMALS);
                         // Simpler if oracle price is per 1 unit scaled by 1e18:
                          uint256 value = (tokenBalance * tokenPrice) / ORACLE_PRICE_DECIMALS; // Assuming tokenBalance native units, price USD*1e18 per 1 unit
                         totalLiquidNAV += value;
                     }
                 }
             }
         }
        */
        // Need to implement the iteration for ERC20s. For now, this is a placeholder.
        // The actual implementation needs a way to list ERC20s without iterating maps.

        // Placeholder implementation: only consider ETH and a few hardcoded tokens or require a list as input.
        // Let's calculate only based on ETH and what's trackable easily.
        // For ERC20s, the `assetBalances` *should* be updated when assets return from strategies.
        // The challenge is iterating `allowedAssets` where type is ERC20.

        // Alternative: The oracle interface could provide total value of assets held by a specific address.
        // `oracle.getTotalValue(address _address)` could sum up all known asset values.
        // `_calculateLiquidNAV()` would call `oracle.getTotalValue(address(this))`.
        // This pushes complexity to the oracle but simplifies the fund contract.
        // Let's assume the oracle can do this for liquid assets.

        // REVISED _calculateLiquidNAV
        totalLiquidNAV = oracle.getTotalValue(address(this)); // Assuming oracle has this function

    }


    // _calculateNAV - Calculates total NAV including assets potentially held in strategies.
    // This requires strategies to have view functions exposing their balances.
    function _calculateNAV() internal view returns (uint256 totalNAV) {
         totalNAV = _calculateLiquidNAV(); // Start with liquid assets

        // Add value of assets held in active strategies
        // Requires iterating active strategies and calling a `getStrategyValue()` or similar function on them.
        // Assuming `IStrategy` has a `getTotalValue()` function similar to the oracle's.
        // Needs iteration over activeStrategies map - again, complex.
        // Let's assume the Oracle can calculate the total value held by a Strategy contract as well,
        // or the Strategy itself reports its total value to the Oracle or a dedicated registry.

        // Alternative: Iterate over activeStrategies map (requires storing active strategies in a list).
        // Assuming `activeStrategiesList` exists (not in state for brevity):
        /*
        for (uint i = 0; i < activeStrategiesList.length; i++) {
            address strategyAddress = activeStrategiesList[i];
            if (activeStrategies[strategyAddress]) {
                // Assuming strategy has a view function to report its managed value in USD
                // IStrategy(strategyAddress).getTotalValue() // In USD scaled
                 totalNAV += IStrategy(strategyAddress).getTotalValue(); // Requires strategy to implement this
            }
        }
        */

        // Simplest for example: Assume Oracle knows how to value strategy holdings if given the strategy address.
         totalNAV = oracle.getTotalFundValue(address(this)); // Oracle calculates total NAV including strategies

         // Note: This model *excludes* NFT value from NAV, regardless of where they are held.

    }

    // _getAssetValue - Helper function (less needed if oracle provides total value functions)
    /*
    function _getAssetValue(address _asset, uint256 _amount) internal view returns (uint256 valueInUSD) {
        if (_asset == address(0) || _amount == 0) return 0;
        if (!allowedAssets[_asset]) return 0; // Only value allowed assets

        uint8 assetType = allowedAssetTypes[_asset];

        if (assetType == ASSET_TYPE_ERC20) {
            uint256 price = oracle.getAssetPrice(_asset);
            if (price == 0) return 0;

            // Adjust for token decimals if oracle price is per 1e18 unit
            uint8 tokenDecimals = IERC20(_asset).decimals();
            uint256 tokenMultiplier = 10**tokenDecimals;
             valueInUSD = (_amount * price * ORACLE_PRICE_DECIMALS) / (tokenMultiplier * ORACLE_PRICE_DECIMALS);
             // Simpler if oracle price is per 1 unit scaled by 1e18:
             valueInUSD = (_amount * price) / ORACLE_PRICE_DECIMALS;

        } else if (assetType == ASSET_TYPE_ERC721) {
            // NFT valuation is complex. Return 0 for NAV calculation purposes in this model.
             valueInUSD = 0;
        } else if (_asset == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEE) || _asset == address(0)) { // Assuming WETH or specific ETH address for oracle
            uint256 price = oracle.getETHPrice();
            if (price == 0) return 0;
             valueInUSD = (_amount * price) / ORACLE_PRICE_DECIMALS; // Assuming _amount is in wei, price USD*1e18 per 1e18 ETH
        } else {
             valueInUSD = 0; // Unknown or unsupported asset type
        }
         return valueInUSD;
    }
    */


    // Accrue management fees - simplified. A real contract would accrue based on time or activity.
    // For simplicity, this version accrues fees on deposit/withdrawal or specific admin calls.
    // The actual accrual mechanism depends on the fee model (e.g., streaming fee).
    // Let's remove the internal `_accrueFees` and handle fee calculation on deposit/redemption.

    // Calculate performance fee (part of redemption logic now)
    /*
    function _calculatePerformanceFee(uint256 navIncreaseValueUSD) internal view returns (uint256 feeAmount) {
        // This requires tracking profit relative to high watermark *per share*.
        // Calculated during redemption based on the shares being redeemed.
        revert("Use inline performance fee calculation during redemption");
    }
    */


    // --- View Functions (Public) ---

    // 22. getTotalShares
    function getTotalShares() external view returns (uint256) {
        return sharesSupply;
    }

    // 23. getSharePrice
    // Returns NAV per share, scaled by shares decimal (e.g., 1e18).
    function getSharePrice() public view returns (uint256) {
        uint256 totalNAV = _calculateNAV();
        if (sharesSupply == 0 || totalNAV == 0) {
            // Handle initial state or empty fund.
            // Share price is often initialized to 1 (or 1e18 for scaling)
            // For an empty fund, NAV is 0, share price could be 0 or initialized value.
            // Returning 0 implies 0 value, which is correct if NAV is 0.
            // If sharesSupply is 0, price is undefined. Return initial price?
             return totalNAV; // If sharesSupply is 0, this will return 0, which isn't great.
            // Better: if sharesSupply == 0, return the initial share price (e.g., 1e18)
            if (sharesSupply == 0) return 1e18; // Assuming shares are 1e18 decimal
             return (totalNAV * 1e18) / sharesSupply; // Scale totalNAV by 1e18 for share price
        }
    }

    // 24. getNAV
    function getNAV() public view returns (uint256) {
        return _calculateNAV();
    }

    // 25. getFundETHBalance
    function getFundETHBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // 26. getFundERC20Balance
    function getFundERC20Balance(address _token) external view returns (uint256) {
        if (!allowedAssets[_token] || allowedAssetTypes[_token] != ASSET_TYPE_ERC20) return 0;
        return assetBalances[_token];
    }

     // 27. getFundNFTCount
    function getFundNFTCount(address _collection) external view returns (uint256) {
         if (!allowedAssets[_collection] || allowedAssetTypes[_collection] != ASSET_TYPE_ERC721) return 0;
         // Cannot easily count NFTs in a mapping like this.
         // Requires iterating through potentially sparse `nftHoldings[_collection]` or maintaining a separate counter.
         // Maintaining a counter is better practice. Let's add a state variable for this.
         // Add `nftCollectionCounts` mapping: `mapping(address => uint256) public nftCollectionCounts;`
         return nftCollectionCounts[_collection]; // Requires adding & updating this map
    }
    // Assuming nftCollectionCounts is added and updated in depositERC721 and transferNFTOut

    // 28. isAssetAllowed
    function isAssetAllowed(address _asset) external view returns (bool) {
        return allowedAssets[_asset];
    }

    // 29. isStrategyAllowed
    function isStrategyAllowed(address _strategy) external view returns (bool) {
        return allowedStrategies[_strategy];
    }

    // 30. isStrategyActive
    function isStrategyActive(address _strategy) external view returns (bool) {
        return activeStrategies[_strategy];
    }

    // 31. getAccruedFees
    function getAccruedFees() external view returns (uint256 management, uint256 performance) {
        // Note: These values are in USD scaled by 1e18 (based on how accrue logic is designed)
        // A real contract would specify the denomination (e.g., ETH, USDC).
        return (totalManagementFeesAccrued, totalPerformanceFeesAccrued);
    }

    // --- Helper Functions/Structs needed (omitted for brevity but implied) ---
    // Error definitions: NotEnoughAsset, StrategyActiveCannotRemove, StrategyAlreadyActive, DepositTooSmall,
    // NoSharesMinted, FundIsEmpty, RedemptionValueTooSmall, EthTransferFailed, OracleError,
    // NoLiquidAssetsToRedeem, StrategyWithdrawalFailed.
    // SafeMath equivalent (e.g., using OpenZeppelin's SafeMath or Solidity 0.8+ default checks).
    // A mechanism to store/iterate allowed ERC20 assets if proportional distribution is needed.
     // `nftCollectionCounts` state variable and updates in NFT deposit/transfer.
     // Oracle functions `getTotalValue(address)` and `getTotalFundValue(address)`.
     // Oracle functions `getAssetPrice(address)` and `getETHPrice()`.

     // Required for SafeMath.min in Solidity <0.8.0. For 0.8.x, can use `Math.min` from OpenZeppelin or implement simply.
     library Math {
         function min(uint256 a, uint256 b) internal pure returns (uint256) {
             return a < b ? a : b;
         }
     }

     // Placeholder errors
     error NotEnoughAsset(address asset, uint256 have, uint256 want);
     error StrategyActiveCannotRemove(address strategy);
     error StrategyAlreadyActive(address strategy);
     error DepositTooSmall();
     error NoSharesMinted();
     error FundIsEmpty();
     error RedemptionValueTooSmall();
     error EthTransferFailed();
     error OracleError(string message);
     error NoLiquidAssetsToRedeem();
     error StrategyWithdrawalFailed(address strategy);
     error OracleReturnedZeroPrice(address asset);
     error AssetTypeNotSupportedForValue(address asset); // For _getAssetValue if called with NFT
     error NftCollectionCountNotTracked(address collection); // If not maintaining separate count


      // Placeholder `nftCollectionCounts`
     mapping(address => uint256) public nftCollectionCounts; // Added based on review of getFundNFTCount


     // Placeholder Oracle interface extensions
     interface IOracleExtended is IOracle {
        function getTotalValue(address _address) external view returns (uint256 totalValueUSD_1e18); // Value of all assets held by _address
        function getTotalFundValue(address _fund) external view returns (uint256 totalValueUSD_1e18); // Value of all assets in fund including strategies
     }
     // Update oracle state variable type
     IOracleExtended public oracle;
     // Update constructor to cast
     // constructor(address _oracle) Ownable(msg.sender) { require(_oracle != address(0), "Zero address"); oracle = IOracleExtended(_oracle); highWatermark = 1e18; } // Assuming shares are 1e18

    // Re-implement _calculateLiquidNAV and _calculateNAV using the extended oracle
    function _calculateLiquidNAV() internal view returns (uint256 totalLiquidNAV) {
        return oracle.getTotalValue(address(this));
    }

    function _calculateNAV() internal view returns (uint256 totalNAV) {
         return oracle.getTotalFundValue(address(this));
    }

     // Re-implement getSharePrice using the revised calculation
     function getSharePrice() public view returns (uint256) {
        uint256 totalNAV = _calculateNAV();
        if (sharesSupply == 0) {
             // Initial share price, assume 1 USD value per share, scaled by 1e18
             return 1e18; // Assuming shares are 1e18 decimal
        }
         return (totalNAV * 1e18) / sharesSupply; // totalNAV is USD*1e18, sharesSupply is share units
     }

     // Update depositETH and depositERC20 to use oracle for value
     // These functions already use oracle correctly for deposit value.

     // Update redeemSharesForETH using revised fee logic and oracle calls
     // This function seems correct based on the revised logic using USD values and converting to ETH at the end.

     // Update getFundNFTCount
     function getFundNFTCount(address _collection) external view returns (uint256) {
         if (!allowedAssets[_collection] || allowedAssetTypes[_collection] != ASSET_TYPE_ERC721) return 0;
         return nftCollectionCounts[_collection];
     }
     // Need to add updates to nftCollectionCounts in depositERC721 and transferNFTOut
      // In depositERC721: nftCollectionCounts[_collection]++;
      // In transferNFTOut: nftCollectionCounts[_collection]--;


}
```

**Explanation of Advanced Concepts & Creativity:**

1.  **Dynamic Strategy Execution (`executeStrategyCall`, `withdrawFromStrategy`):** This is a powerful and risky pattern. Instead of hardcoding investment strategies, the contract allows the owner (or DAO governance in a more advanced version) to approve external contracts as "strategies" and then execute arbitrary calls on them using the fund's assets via `delegatecall` or `call`. Here, `call` is used, meaning the strategy contract executes in its own context, but the fund sends assets *to* it beforehand (via `transferAssetOut`) or the strategy is designed to interact with assets the fund has approved it to control. `executeStrategyCall` uses low-level `.call()`, which is necessary for arbitrary function calls. This provides immense flexibility but requires extreme caution and vetting of strategies. `withdrawFromStrategy` is a semantic wrapper for calls intended to bring assets back.
2.  **Multi-Asset Handling (ETH, ERC-20, ERC-721):** The fund isn't limited to a single token. It tracks distinct balances of multiple ERC-20s and specific token IDs for ERC-721s. This adds complexity in tracking and value calculation.
3.  **NAV Calculation & Oracle Dependency:** Calculating the fund's total value (`_calculateNAV`, `_calculateLiquidNAV`) requires summing the value of diverse assets. This is impossible on-chain without external price data. The contract relies on a conceptual `IOracle` interface. The complexity is highlighted by the need to handle different asset types, decimals, and the location of assets (liquid vs. in strategies). NFT valuation is specifically excluded from NAV calculation here due to its subjective nature in current DeFi; they are tracked separately.
4.  **Proportional Share System:** Users own shares representing a proportion of the fund's total value. Deposit amounts are converted to shares based on the current NAV per share, and redemption burns shares to return a proportional value of underlying assets.
5.  **Dynamic Fees (Management & Performance):** Fee rates can be adjusted by the owner. Performance fees (`highWatermark`) add a layer of complexity, ensuring fees are only paid on profits above the highest previous value per share. The fee collection mechanism is simplified in this example but shows the concept.
6.  **ERC-721 Receiver Hook (`onERC721Received`):** Implementing this standard ensures the contract can safely receive NFTs transferred using `safeTransferFrom`. It includes checks to only accept allowed NFT collections.
7.  **Access Control & Reentrancy Guard:** Uses `Ownable` for administrative functions and `ReentrancyGuard` for functions interacting with external contracts (like deposits, redemptions, strategy calls) to prevent reentrancy attacks.
8.  **Error Handling:** Uses Solidity 0.8+ custom errors for gas efficiency and clarity.

This contract demonstrates a pattern for building more sophisticated DeFi funds or vaults that can interact dynamically with the broader DeFi ecosystem, moving beyond static asset holding. It pushes the boundaries by incorporating arbitrary external calls and multi-asset management complexities.