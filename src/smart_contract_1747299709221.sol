Okay, here is a Solidity smart contract implementing a "Yield-Bearing Strategy Bundle" (YSB). This contract acts as a vault that can hold various approved ERC-20 and specific ERC-721 tokens. It manages these assets according to an external "Strategy" contract, aiming to generate yield. Users deposit assets and receive shares of the bundle (represented by an internal ERC-20 token managed by this contract). The contract includes features like dynamic strategy switching based on conditions (simulated via an oracle/keeper call), performance fees, asset management, and access control.

It aims to be complex and creative by combining:
1.  **Composite Asset Management:** Holding *both* ERC-20s and ERC-721s in one bundle.
2.  **Externalized Strategy:** Offloading the core yield generation logic to a separate, potentially upgradeable or swappable, Strategy contract.
3.  **Dynamic Strategy Switching:** Allowing pre-approved strategy changes based on external data/triggers.
4.  **Internal Share Token:** Managing its own ERC-20 share token internally rather than inheriting from a standard ERC-20 base contract (though it implements the interface).
5.  **Role-Based Access:** Differentiating between Owner, Strategy Managers, and the Strategy contract itself.
6.  **Yield/Fee Mechanics:** Tracking bundle value and distributing performance fees.

This is a conceptual contract demonstrating the complexity; a real-world implementation would require extensive auditing, sophisticated oracle integration, and a robust Strategy contract ecosystem.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- OUTLINE ---
// Contract Name: YieldBearingStrategyBundle (YSB)
// Description: A vault contract holding multiple ERC-20 and specific ERC-721 assets.
//              It manages these assets according to an external strategy contract to generate yield.
//              Users deposit assets to receive shares (an internal ERC-20 token) representing their proportional ownership.
// Core Concepts:
//   - Composite Asset Holding (ERC-20 & ERC-721)
//   - External Strategy Pattern
//   - Dynamic Strategy Switching based on conditions
//   - Internal Share Token Management
//   - Performance Fee Mechanism
//   - Role-Based Access Control (Owner, Strategy Managers, Strategy)
// Key Features:
//   - Deposit/Withdrawal of approved ERC-20s.
//   - Deposit/Withdrawal of specific ERC-721s.
//   - Calculation of bundle value and share price (simulated via Oracle interface).
//   - Strategy execution controlled by authorized entities.
//   - Setting/Changing strategies and strategy parameters.
//   - Automated/Triggered dynamic strategy shifts.
//   - Harvesting yield and distributing performance fees.
//   - Pausability for emergencies.
//   - Rescue mechanisms for accidentally sent tokens.
// Inheritance/Interfaces:
//   - Ownable (Basic ownership for critical admin functions)
//   - Pausable (For emergency stop)
//   - IERC20, IERC721 (Standard token interfaces)
//   - IStrategy (Custom interface for external Strategy contracts)
//   - IPriceOracle (Custom interface for value calculation)

// --- FUNCTION SUMMARY ---
// State Management:
//   - constructor(string name, string symbol, address initialStrategy, address priceOracle): Initializes the contract, sets owner, YSB token details, initial strategy, and oracle.
//   - transferOwnership(address newOwner): Transfers contract ownership (Ownable).
//   - pauseContract(): Pauses deposits, withdrawals, and strategy execution (Pausable).
//   - unpauseContract(): Unpauses the contract (Pausable).
//   - setApprovedUnderlying(address token, bool isApproved): Adds or removes an ERC-20 or ERC-721 collection from the list of approved underlying assets.
//   - setApprovedERC721Id(address collection, uint256 tokenId, bool isApproved): Approves or disapproves specific ERC-721 token IDs within an approved collection.
// Asset Deposit/Withdrawal:
//   - depositERC20(address token, uint256 amount): Deposits an approved ERC-20 token and mints YSB shares.
//   - depositERC721(address collection, uint256 tokenId): Deposits an approved ERC-721 token ID and mints YSB shares.
//   - withdrawERC20(uint256 shares): Redeems YSB shares for proportional amounts of all currently held ERC-20 assets.
//   - withdrawERC721(uint256 shares, address collection, uint256 tokenId): Redeems YSB shares (that were associated with this specific NFT) and receives the specific ERC-721 token back. This is complex; a simpler model might redeem for value. This implements the specific NFT redemption.
// YSB Share Token (Internal ERC-20 implementation):
//   - totalSupply(): Returns the total supply of YSB shares.
//   - balanceOf(address account): Returns the YSB share balance of an account.
//   - transfer(address recipient, uint256 amount): Transfers YSB shares.
//   - allowance(address owner, address spender): Returns the allowance for YSB shares.
//   - approve(address spender, uint256 amount): Approves spending of YSB shares.
//   - transferFrom(address sender, address recipient, uint256 amount): Transfers YSB shares using allowance.
// Strategy Management:
//   - setStrategy(address newStrategy): Owner sets the active strategy contract.
//   - addStrategyManager(address manager): Owner adds an address allowed to trigger strategy executions.
//   - removeStrategyManager(address manager): Owner removes a strategy manager.
//   - executeStrategy(bytes calldata data): Called *only* by the active Strategy contract to perform actions (e.g., swap, farm deposit). Includes strict access control and data validation.
//   - triggerManualRebalance(bytes calldata data): A strategy manager can trigger a rebalance via the current strategy.
// Value & Performance:
//   - getBundleTotalValue(): Calculates the total value of all assets currently held, using the oracle.
//   - getSharePrice(): Calculates the value of a single YSB share (Total Value / Total Supply).
//   - harvestYield(): Owner or strategy manager can trigger the strategy to harvest yield.
//   - distributeFees(): Owner or strategy manager can trigger distribution of accrued performance fees.
//   - setPerformanceFeeRate(uint256 rateBasisPoints): Owner sets the performance fee rate (e.g., 1000 for 10%).
//   - getAccruedProtocolFees(): Returns the amount of fees accrued and ready for distribution.
// Dynamic Strategy Shift:
//   - setDynamicShiftCondition(uint256 conditionType, uint256 threshold, address alternativeStrategy): Owner sets parameters for an automated strategy shift condition.
//   - triggerDynamicStrategyShift(uint256 conditionType, bytes calldata oracleData): Callable by a trusted oracle/keeper. Checks condition using oracle data and shifts strategy if met.
// Rescue Functions:
//   - rescueERC20(address token, uint256 amount): Owner can rescue non-YSB, non-strategy ERC-20 tokens accidentally sent.
//   - rescueERC721(address collection, uint256 tokenId): Owner can rescue non-YSB, non-strategy ERC-721 tokens accidentally sent.
// View/Utility:
//   - getCurrentStrategy(): Returns the address of the current strategy contract.
//   - isStrategyManager(address account): Checks if an address is a strategy manager.
//   - getApprovedUnderlying(uint256 index): Get an approved underlying asset address by index.
//   - getApprovedUnderlyingCount(): Get the count of approved underlying assets.
//   - getApprovedERC721Ids(address collection): Get the list of approved token IDs for a collection.

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// Custom Interface for the Strategy Contract
interface IStrategy {
    // Function called by the YSB vault to execute strategy actions
    // `data` is encoded call data for actions the strategy wants the vault to perform (e.g., transfer, approve, interact with other protocols)
    function execute(bytes calldata data) external;

    // Function called by the YSB vault to trigger yield harvesting by the strategy
    function harvest() external;

    // Function called by the YSB vault to trigger a rebalance by the strategy
    function rebalance(bytes calldata data) external;

    // Function called by the YSB vault to update strategy-specific parameters
    function setParameters(bytes calldata data) external;

    // Function called by the YSB vault to calculate the current total value of assets held by the strategy
    function getTotalStrategyValue(address vault, IPriceOracle oracle) external view returns (uint256);

    // Optional: Function called by the YSB vault to signal strategy is about to be switched out
    function retire() external;
}

// Custom Interface for the Price Oracle
interface IPriceOracle {
    // Should return the value of a token/NFT bundle in a common base currency (e.g., USD, ETH) scaled appropriately
    // Assumes the oracle can value various ERC20s and potentially ERC721s
    // This is a simplified placeholder - real oracles are complex.
    function getValue(address tokenOrCollection, uint256 amountOrId, address vault) external view returns (uint256);

    // Gets value of a list of ERC20s and their amounts
    function getERC20PortfolioValue(address[] calldata tokens, uint256[] calldata amounts, address vault) external view returns (uint256);

    // Gets value of a list of ERC721s (collection, id)
    function getERC721PortfolioValue(address[] calldata collections, uint256[] calldata tokenIds, address vault) external view returns (uint256);

    // Used for dynamic shifts - checks a condition based on internal vault state and external data
    // conditionType: e.g., 1 for PriceDrop, 2 for TVLChange, etc.
    // threshold: The value threshold for the condition
    // oracleData: Additional data needed by the oracle to check the condition (e.g., current market price of a key asset)
    function checkCondition(address vault, uint256 conditionType, uint256 threshold, bytes calldata oracleData) external view returns (bool);
}

contract YieldBearingStrategyBundle is Ownable, Pausable, ERC721Holder {
    using Address for address;

    // --- Errors ---
    error InvalidAmount();
    error InvalidShares();
    error InvalidStrategy();
    error InvalidToken();
    error InvalidERC721Id();
    error TransferFailed();
    error StrategyExecutionFailed();
    error NotStrategy();
    error NotStrategyOrManager();
    error StrategyAlreadyActive();
    error DynamicShiftConditionNotMet();
    error DynamicShiftConditionNotSet();
    error NotApprovedUnderlying();
    error ERC721IdNotApproved();
    error ERC721NotHeldInVault();
    error InsufficientBalance();
    error ZeroAddress();

    // --- Events ---
    event Deposit(address indexed user, address indexed token, uint256 amount, uint256 sharesMinted);
    event ERC721Deposit(address indexed user, address indexed collection, uint256 indexed tokenId, uint256 sharesMinted);
    event Withdrawal(address indexed user, uint256 sharesBurned, uint256 valueWithdrawn);
    event ERC721Withdrawal(address indexed user, uint256 sharesBurned, address indexed collection, uint256 indexed tokenId);
    event StrategySet(address indexed oldStrategy, address indexed newStrategy);
    event StrategyManagerAdded(address indexed manager);
    event StrategyManagerRemoved(address indexed manager);
    event StrategyExecuted(bytes calldata data);
    event YieldHarvested(uint256 yieldAmount);
    event FeesDistributed(uint256 feeAmount);
    event PerformanceFeeRateSet(uint256 indexed rateBasisPoints);
    event DynamicShiftConditionSet(uint256 indexed conditionType, uint256 threshold, address alternativeStrategy);
    event DynamicStrategyShift(uint256 indexed conditionType, address indexed oldStrategy, address indexed newStrategy);
    event ApprovedUnderlyingSet(address indexed token, bool isApproved);
    event ApprovedERC721IdSet(address indexed collection, uint256 indexed tokenId, bool isApproved);

    // --- State Variables ---

    // YSB Share Token Details (ERC-20 implementation internally)
    string public name;
    string public symbol;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // Asset Management
    mapping(address => bool) public approvedUnderlying; // ERC20 or ERC721 collection address -> is approved
    address[] private _approvedUnderlyingList; // To iterate approved tokens/collections
    mapping(address => mapping(uint256 => bool)) public approvedERC721Ids; // ERC721 collection -> tokenId -> is approved
    mapping(address => mapping(uint256 => address)) private erc721Depositor; // ERC721 collection -> tokenId -> original depositor (for specific withdrawal)

    // Strategy Management
    IStrategy public currentStrategy;
    mapping(address => bool) public isStrategyManager;

    // Oracle for value calculation and dynamic shifts
    IPriceOracle public priceOracle;

    // Performance Fees (e.g., 1000 means 10%)
    uint256 public performanceFeeRateBasisPoints; // Stored as basis points (1/100 of a percent)
    uint256 public accruedProtocolFees; // Fees collected and waiting to be distributed

    // Dynamic Strategy Shift Configuration
    mapping(uint256 => DynamicShiftConfig) public dynamicShiftConditions; // conditionType -> config
    struct DynamicShiftConfig {
        uint256 threshold;
        address alternativeStrategy;
    }

    // --- Modifiers ---

    modifier onlyStrategy() {
        if (msg.sender != address(currentStrategy)) revert NotStrategy();
        _;
    }

    modifier onlyStrategyOrManager() {
        if (msg.sender != address(currentStrategy) && !isStrategyManager[msg.sender] && msg.sender != owner()) revert NotStrategyOrManager();
        _;
    }

    // --- Constructor ---

    constructor(
        string memory _name,
        string memory _symbol,
        address initialStrategy,
        address _priceOracle
    ) Ownable(msg.sender) Pausable(false) {
        if (initialStrategy == address(0) || _priceOracle == address(0)) revert ZeroAddress();
        name = _name;
        symbol = _symbol;
        currentStrategy = IStrategy(initialStrategy);
        priceOracle = IPriceOracle(_priceOracle);
        // Add the initial strategy address as a strategy manager by default
        isStrategyManager[initialStrategy] = true;
        emit StrategyManagerAdded(initialStrategy);
    }

    // --- YSB Share Token (Internal ERC-20 Implementation) ---

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public whenNotPaused returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public whenNotPaused returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public whenNotPaused returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        if (currentAllowance < amount) revert InsufficientAllowance(); // Custom or standard error
        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    // ERC-20 internal helpers
    function _transfer(address sender, address recipient, uint256 amount) internal {
        if (sender == address(0) || recipient == address(0)) revert ZeroAddress();
        if (_balances[sender] < amount) revert InsufficientBalance();

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        if (account == address(0)) revert ZeroAddress();
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        if (account == address(0)) revert ZeroAddress();
        if (_balances[account] < amount) revert InsufficientBalance();

        _balances[account] -= amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        if (owner == address(0) || spender == address(0)) revert ZeroAddress();
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // --- Asset Management ---

    function setApprovedUnderlying(address token, bool isApproved) public onlyOwner {
        if (token == address(0)) revert ZeroAddress();
        bool wasApproved = approvedUnderlying[token];
        if (wasApproved == isApproved) return; // No change

        approvedUnderlying[token] = isApproved;

        if (isApproved) {
            _approvedUnderlyingList.push(token);
        } else {
            // Remove from the list
            for (uint i = 0; i < _approvedUnderlyingList.length; i++) {
                if (_approvedUnderlyingList[i] == token) {
                    _approvedUnderlyingList[i] = _approvedUnderlyingList[_approvedUnderlyingList.length - 1];
                    _approvedUnderlyingList.pop();
                    break;
                }
            }
            // Clear any specific ERC721 ID approvals for this collection if it was a collection
            // (Cannot easily iterate specific ID approvals here, would need a complex data structure)
            // A simpler approach is to require re-approving specific IDs if collection is re-added.
        }
        emit ApprovedUnderlyingSet(token, isApproved);
    }

    function getApprovedUnderlying(uint256 index) public view returns (address) {
        if (index >= _approvedUnderlyingList.length) revert InvalidAmount(); // Use generic error for out of bounds
        return _approvedUnderlyingList[index];
    }

    function getApprovedUnderlyingCount() public view returns (uint256) {
        return _approvedUnderlyingList.length;
    }

    function setApprovedERC721Id(address collection, uint256 tokenId, bool isApproved) public onlyOwner {
        if (collection == address(0)) revert ZeroAddress();
        if (!approvedUnderlying[collection]) revert NotApprovedUnderlying(); // Collection must be approved first

        approvedERC721Ids[collection][tokenId] = isApproved;
        emit ApprovedERC721IdSet(collection, tokenId, isApproved);
    }

    // Note: Retrieving *all* approved ERC721 IDs for a collection is not practical on-chain
    // due to storage costs and iteration limits. This function is a placeholder.
    // getApprovedERC721Ids is removed as it's not feasible to return a dynamic array of IDs.
    // You would need off-chain data structures or alternative on-chain patterns (like linked lists or merkle trees)
    // to manage approved IDs efficiently for retrieval.

    // --- Deposit/Withdrawal ---

    function depositERC20(address token, uint256 amount) public whenNotPaused returns (uint256 sharesMinted) {
        if (amount == 0) revert InvalidAmount();
        if (token == address(0)) revert ZeroAddress();
        if (!approvedUnderlying[token]) revert NotApprovedUnderlying();

        // Calculate shares to mint based on current share price
        uint256 totalValue = getBundleTotalValue();
        uint256 currentTotalSupply = _totalSupply;

        if (currentTotalSupply == 0 || totalValue == 0) {
            // First deposit or bundle is somehow valueless (shouldn't happen normally)
            sharesMinted = amount; // Assume 1 YSB = 1 unit of the first deposited asset (simplification)
            // In a real vault, initial share price might be set relative to USD or ETH, or just 1 share per asset unit.
            // For simplicity here, we'll assume the *very first* deposit of *any* approved asset sets the initial price base.
            // A robust system needs a more defined initial price or bootstrap mechanism.
            // Let's use a common approach: 1 share = 1e18 units of value initially (e.g., 1 USD or 1 ETH, requires oracle)
            // We need the value of the deposited amount first.
            uint256 depositedValue = priceOracle.getValue(token, amount, address(this));
             if (depositedValue == 0) revert InvalidAmount(); // Oracle couldn't value it
             sharesMinted = depositedValue; // Use value as initial shares (e.g., $100 deposit gets 100 shares if oracle values in cents/wei-equiv)

        } else {
             // Calculate shares based on the value brought in vs current total value
             uint256 depositedValue = priceOracle.getValue(token, amount, address(this));
             if (depositedValue == 0) revert InvalidAmount(); // Oracle couldn't value it
             // sharesMinted = (depositedValue * currentTotalSupply) / totalValue;
             // A more accurate calculation: Shares = (depositedValue * total_shares) / total_value
             // Avoid precision loss: Shares = (depositedValue * total_shares * 1e18) / (total_value * 1e18)
             // Let's assume totalValue and depositedValue are in the same unit (e.g., wei of a stablecoin or ETH)
             // shares = (depositedValue * currentTotalSupply) / totalValue
             sharesMinted = (depositedValue * currentTotalSupply) / totalValue; // Note: Integer division floors
             if (sharesMinted == 0) revert InvalidAmount(); // Amount too small to mint even 1 share

        }

        IERC20(token).transferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, sharesMinted);

        emit Deposit(msg.sender, token, amount, sharesMinted);
        return sharesMinted;
    }

    function depositERC721(address collection, uint256 tokenId) public whenNotPaused returns (uint256 sharesMinted) {
        if (collection == address(0)) revert ZeroAddress();
        if (!approvedUnderlying[collection]) revert NotApprovedUnderlying();
        if (!approvedERC721Ids[collection][tokenId]) revert ERC721IdNotApproved();

        // Calculate shares to mint based on current share price
        uint256 totalValue = getBundleTotalValue();
        uint256 currentTotalSupply = _totalSupply;

        uint256 depositedValue = priceOracle.getValue(collection, tokenId, address(this));
        if (depositedValue == 0) revert InvalidERC721Id(); // Oracle couldn't value it (or ID not found/valid)

        if (currentTotalSupply == 0 || totalValue == 0) {
             sharesMinted = depositedValue; // Use value as initial shares
        } else {
             sharesMinted = (depositedValue * currentTotalSupply) / totalValue;
             if (sharesMinted == 0) revert InvalidERC721Id(); // Value too small
        }

        IERC721(collection).safeTransferFrom(msg.sender, address(this), tokenId);
        erc721Depositor[collection][tokenId] = msg.sender; // Record who deposited this specific NFT

        _mint(msg.sender, sharesMinted);

        emit ERC721Deposit(msg.sender, collection, tokenId, sharesMinted);
        return sharesMinted;
    }

    function withdrawERC20(uint256 shares) public whenNotPaused {
        if (shares == 0) revert InvalidShares();
        if (_balances[msg.sender] < shares) revert InsufficientBalance();

        uint256 totalValue = getBundleTotalValue();
        uint256 currentTotalSupply = _totalSupply;
        if (currentTotalSupply == 0) revert InvalidShares(); // Cannot withdraw from empty vault

        // Calculate proportional value to withdraw (handle potential precision issues)
        // value = (shares * totalValue) / currentTotalSupply
        uint256 valueToWithdraw = (shares * totalValue) / currentTotalSupply; // Note: Integer division

        _burn(msg.sender, shares);

        // Distribute proportional share of *all* currently held ERC-20s
        // This is complex as it requires iterating through all held ERC-20s
        // and sending a proportional amount of each.
        // For simplicity in this example, we'll simulate receiving *some* value equivalent,
        // but a real implementation needs to calculate and send specific token amounts.
        // This might involve swapping assets internally or requiring the user to specify
        // which assets they want back proportionally.
        // A common vault pattern doesn't return specific assets, just the proportional value
        // in a pre-defined withdrawal asset or lets the strategy handle swapping to a single asset.
        // Let's simulate transferring value in a placeholder way, or require a more complex withdrawal function.
        // A more standard vault withdraws all ERC20s proportionally. Let's do that conceptually.

        // *** Simplified conceptual withdrawal of proportional ERC-20s ***
        // Iterate approved ERC20s (need to distinguish ERC20s from ERC721s in _approvedUnderlyingList)
        // Get balance of each approved ERC20
        // amount_to_send = (balance_of_token * shares) / currentTotalSupply (before burn)
        uint256 supplyBeforeBurn = currentTotalSupply; // Use supply before burning shares

        // Need a list of just approved ERC20 addresses
        address[] memory erc20Tokens = new address[](0); // Need to filter list
        for(uint i = 0; i < _approvedUnderlyingList.length; i++) {
            address token = _approvedUnderlyingList[i];
            // Check if it's likely an ERC20 (heuristic: has totalSupply or can call balanceOf)
            // A better way is to store type metadata when approving
            // For this example, assume approvedUnderlying can list both ERC20s and ERC721 collections,
            // and we need to check if it's ERC20-like. This is brittle.
            // Let's assume `approvedUnderlying` only stores ERC20s *and* ERC721Collections, and we filter.
            // A more robust design stores types explicitly.
            // Assuming _approvedUnderlyingList contains only ERC20s for this function:
             try IERC20(token).totalSupply() returns (uint256) {
                 erc20Tokens.push(token);
             } catch {} // It's not an ERC20 or call failed
        }


        for (uint i = 0; i < erc20Tokens.length; i++) {
            address token = erc20Tokens[i];
            uint256 tokenBalance = IERC20(token).balanceOf(address(this));
            if (tokenBalance > 0) {
                 uint256 amountToSend = (tokenBalance * shares) / supplyBeforeBurn;
                 if (amountToSend > 0) {
                     // Ensure contract has enough balance after potential strategy moves
                     if (IERC20(token).balanceOf(address(this)) < amountToSend) {
                        // This indicates assets are stuck in the strategy or mismanaged.
                        // Cannot fulfill withdrawal fully. This is a critical error state.
                        // A real vault might track 'managed' vs 'available' assets or use a 'pull' model from strategy.
                        // For this example, we'll proceed but note this limitation.
                        // In production, this would likely fail or partially fulfill.
                        // Revert is safest for a demo.
                        revert InsufficientBalance();
                     }
                     _transferERC20(token, msg.sender, amountToSend);
                 }
            }
        }

        // Acknowledge the value withdrawn conceptually
        emit Withdrawal(msg.sender, shares, valueToWithdraw);
    }

    function withdrawERC721(uint256 shares, address collection, uint256 tokenId) public whenNotPaused {
        if (shares == 0) revert InvalidShares();
        if (collection == address(0)) revert ZeroAddress();
        if (_balances[msg.sender] < shares) revert InsufficientBalance(); // Must burn shares

        // Complex logic: How many shares are associated with *this specific* NFT?
        // The simple model assumed all shares are fungible and represent proportional value of the whole bundle.
        // Allowing withdrawal of a *specific* NFT requires tracking which shares came from which NFT deposit, or
        // having a separate class of non-fungible shares tied to specific NFTs.
        // This contract's current share model (fungible ERC20) doesn't support specific NFT withdrawal easily.
        // A conceptual implementation would need:
        // 1. Verify the user deposited THIS specific NFT initially (using erc721Depositor)
        // 2. Verify the user still holds the shares they received for THAT deposit (hard to track with fungible shares)
        // 3. Burn shares equivalent to the *current* value of that NFT relative to the bundle.
        // 4. Transfer the NFT back IF it's still in the vault.

        // Let's implement a simplified specific NFT withdrawal:
        // User burns shares equal to the NFT's current value (relative to bundle value),
        // AND they must have been the original depositor, AND the NFT must be in the vault.
        // This still requires burning shares from their main YSB balance.

        if (erc721Depositor[collection][tokenId] != msg.sender) revert InvalidERC721Id(); // Only original depositor can attempt specific NFT withdrawal
        if (!IERC721(collection).ownerOf(tokenId).isContract() || IERC721(collection).ownerOf(tokenId) != address(this)) revert ERC721NotHeldInVault();

        uint256 nftValue = priceOracle.getValue(collection, tokenId, address(this));
        if (nftValue == 0) revert InvalidERC721Id(); // Oracle can't value

        uint256 totalValue = getBundleTotalValue();
        uint256 currentTotalSupply = _totalSupply;
         if (currentTotalSupply == 0 || totalValue == 0) revert InvalidShares();

        // Calculate shares to burn equivalent to the NFT's value
        uint256 sharesToBurn = (nftValue * currentTotalSupply) / totalValue;
        if (sharesToBurn == 0) revert InvalidERC721Id(); // NFT value too low

        if (_balances[msg.sender] < sharesToBurn) revert InsufficientBalance();

        _burn(msg.sender, sharesToBurn);

        // Transfer the NFT back
        IERC721(collection).safeTransferFrom(address(this), msg.sender, tokenId);
        delete erc721Depositor[collection][tokenId]; // Clear depositor record

        emit ERC721Withdrawal(msg.sender, sharesToBurn, collection, tokenId);
    }


    // --- Value & Performance ---

    function getBundleTotalValue() public view returns (uint256) {
        // This is a placeholder. A real implementation would:
        // 1. Get balances of all ERC-20s in the vault (both in contract and in strategy).
        // 2. Get list/value of all ERC-721s in the vault (both in contract and in strategy).
        // 3. Use the oracle to get the value of each asset.
        // 4. Sum up all values.
        // This requires coordination with the strategy contract about where assets are.
        // For this example, we will call a simplified oracle function.

        address[] memory erc20Tokens = new address[](0); // Need to filter list
         for(uint i = 0; i < _approvedUnderlyingList.length; i++) {
             address token = _approvedUnderlyingList[i];
              try IERC20(token).totalSupply() returns (uint256) {
                 erc20Tokens.push(token);
              } catch {}
         }

        address[] memory erc721Collections = new address[](0); // Need list of collections
        uint256[] memory erc721Ids = new uint256[](0); // Need list of IDs

        // Iterating stored ERC721 IDs is not feasible.
        // A real system would need the Strategy to report which NFTs it holds,
        // and the Vault would need a way to list the NFTs it holds directly.
        // Let's assume the oracle has a way to query the vault directly or gets asset lists from elsewhere.
        // This is a major simplification required for a conceptual example.
        // We will call the oracle directly with asset types.

        // This function needs to consider assets held *by the strategy contract* as well!
        // currentStrategy.getTotalStrategyValue(address(this), priceOracle) would get value from strategy.
        // Then add value of assets held directly in the vault.

        // --- Simplified implementation: Oracle figures out total value based on vault address ---
        // A robust oracle would need to be aware of the vault's state and strategy's state.
        // Let's call two functions on the oracle: one for ERC20s, one for ERC721s held by the vault address.
        // This assumes the Oracle can get balances by querying the vault address.
        // A real oracle might need asset lists passed in, or rely on trusted keepers providing signed data.

        // Get list of all ERC20 balances held by the vault
        address[] memory currentERC20sInVault = new address[](erc20Tokens.length); // Reuse erc20Tokens list
        uint256[] memory currentERC20AmountsInVault = new uint256[](erc20Tokens.length);
        for(uint i = 0; i < erc20Tokens.length; i++) {
            currentERC20sInVault[i] = erc20Tokens[i];
            currentERC20AmountsInVault[i] = IERC20(erc20Tokens[i]).balanceOf(address(this));
        }

         // Getting list of ERC721s held by the vault is impossible on-chain without helper structures.
         // We'll omit adding ERC721 value from assets *directly* in the vault for simplicity here,
         // or assume the oracle can query this (which is still hard).
         // A better model: Strategy holds ALL assets andgetTotalStrategyValue handles it.

        uint256 vaultERC20Value = priceOracle.getERC20PortfolioValue(currentERC20sInVault, currentERC20AmountsInVault, address(this));

        // Call strategy to get value of assets it holds
        uint256 strategyValue = currentStrategy.getTotalStrategyValue(address(this), priceOracle);

        return vaultERC20Value + strategyValue;
    }

    function getSharePrice() public view returns (uint256) {
        uint256 totalValue = getBundleTotalValue();
        uint256 currentTotalSupply = _totalSupply;
        if (currentTotalSupply == 0 || totalValue == 0) {
            // Handle initial state or zero value scenario
            // Define a base unit for value (e.g., 1e18 for 1 unit of value)
            // Initial price could be 1e18 if supply is 0, representing 1 unit of value per share.
            return _totalSupply == 0 ? 1e18 : 0; // Return 1 unit of value per share if empty, otherwise 0 if value is 0
        }
        // price = (totalValue * 1e18) / currentTotalSupply; // Scale for precision
        return (totalValue * 1e18) / currentTotalSupply;
    }

    function calculateSharesToMint(address token, uint256 amount) public view returns (uint256) {
        if (amount == 0) return 0;
        if (token == address(0)) return 0;
         if (!approvedUnderlying[token]) return 0; // Not an approved asset

        uint256 totalValue = getBundleTotalValue();
        uint256 currentTotalSupply = _totalSupply;

        uint256 depositedValue = priceOracle.getValue(token, amount, address(this));
        if (depositedValue == 0) return 0;

        if (currentTotalSupply == 0 || totalValue == 0) {
            return depositedValue; // Use value as initial shares
        } else {
            // shares = (depositedValue * currentTotalSupply) / totalValue
            return (depositedValue * currentTotalSupply) / totalValue;
        }
    }

     function calculateUnderlyingToWithdraw(uint256 shares) public view returns (uint256 valueEquivalent) {
         if (shares == 0) return 0;
         uint256 totalValue = getBundleTotalValue();
         uint256 currentTotalSupply = _totalSupply;
         if (currentTotalSupply == 0 || totalValue == 0) return 0;

         // This returns the total value equivalent in the common base unit, not specific tokens.
         // For proportional token amounts, see the withdrawal function logic description.
         return (shares * totalValue) / currentTotalSupply;
     }


    function harvestYield() public whenNotPaused onlyStrategyOrManager {
        // This function triggers the strategy to harvest yield.
        // The strategy should internally calculate yield, realize it, and potentially
        // return a portion to the vault for fees or reinvestment.
        // This is a placeholder call. Real strategies would emit specific harvest events.
        currentStrategy.harvest();
        // A real system would need a way for the strategy to report harvested amount
        // and transfer protocol fees back to the vault.
        // For simplicity, we'll assume harvest increases bundle value, and fees are calculated based on value increase.
        // A common fee model is (newTotalValue - oldTotalValue - deposits - withdrawals) * feeRate.
        // Tracking this state (`oldTotalValue`, `deposits`, `withdrawals`) is complex.
        // Let's use a simpler model: fees are a percentage of *gross yield* harvested by the strategy,
        // and the strategy sends the fee amount back to the vault.
        // We'll assume the strategy's `harvest` function handles this and sends fees to `address(this)`.
        // The fees accumulate in `accruedProtocolFees` after being sent by the strategy.
    }

    // This function is called by the strategy after harvest to send fees back.
    // Requires a dedicated function in the vault that only the strategy can call.
    // Or, simpler: strategy sends fees to vault, and `distributeFees` sweeps them.
    // Let's make `distributeFees` sweep fees received by the vault.

    function distributeFees() public whenNotPaused onlyStrategyOrManager {
        if (accruedProtocolFees == 0) return;

        uint256 fees = accruedProtocolFees;
        accruedProtocolFees = 0;

        // Send fees to a designated treasury address (can be set in constructor or state)
        // For this example, send to the owner.
        // address treasury = owner(); // Use owner for simplicity
        // (bool success, ) = payable(treasury).call{value: fees}("");
        // if (!success) {
        //     // Fee distribution failed, revert or handle? Reverting is safer.
        //     // Revert would put fees back in accruedProtocolFees, but owner() might be non-payable.
        //     // A real treasury address would be payable. Let's assume it's payable.
        //      revert TransferFailed(); // Use a specific error for fee transfer
        // }
         // Assume fees are collected in a specific ERC20 token (e.g., DAI, ETH).
         // Let's assume fees are collected as the contract's *share* token (YSB).
         // This means a portion of the harvested yield is converted BY THE STRATEGY into YSB tokens
         // and sent to the vault, increasing `accruedProtocolFees` (if we store fees in YSB terms).
         // Alternatively, fees are collected in base assets, and `distributeFees` sends base assets.
         // Let's make it simpler: fees accumulate as YSB tokens received by the vault address.
         // This requires the strategy to buy/mint YSB shares as fees. This isn't typical.
         // A typical model: Fees are a % of underlying assets harvested, sent to a separate fee recipient address.
         // Let's modify: `accruedProtocolFees` is the value in the common oracle unit, and `distributeFees`
         // sends equivalent value or specific assets to the owner/treasury.

         // Let's simplify further: The strategy harvests yield and sends the fee amount
         // (in underlying assets, say DAI) directly to the owner/treasury. This vault
         // just sets the fee *rate*.

         // Let's revert to the accruedProtocolFees in the vault state, representing VALUE.
         // Distribution needs to send *assets* equivalent to this value. This is complex.
         // Simplest: Send a specific asset (e.g., ETH or DAI) equivalent to accrued value.
         // This requires swapping assets, which needs integration with a DEX.
         // Let's make it conceptual: accrue fees as VALUE, distribute sends VALUE equivalent in ETH to owner.
         // This requires oracle for ETH price and ETH balance in vault (which the strategy might manage).

         // Let's use the simplest model for accruedProtocolFees: It represents YSB shares owned by the protocol/vault.
         // The strategy harvests yield, converts the fee portion into YSB shares, and sends them to `address(this)`.
         // `distributeFees` then transfers these YSB shares to the owner.

         uint256 feeShares = _balances[address(this)]; // YSB shares held by the contract itself (as fees)
         if (feeShares == 0) return;

         _transfer(address(this), owner(), feeShares);
         accruedProtocolFees = 0; // Reset accrued fees (value, not shares in this model) - need consistency.
         // Let's stick to `accruedProtocolFees` representing VALUE in oracle's base unit.
         // The strategy sends harvested assets back to the vault. `distributeFees` takes a % of RECENTLY added assets
         // as fees, calculates value, and sends them to the owner/treasury. This state needs to track 'recent yield'.

         // Let's define accruedProtocolFees as the *value* (in oracle base units) that has been accumulated as fees.
         // The harvest function would need to report yield, fees are calculated, and this value is added to accruedProtocolFees.
         // Distribution needs to send assets.

         // *** Simplified Fee Distribution ***
         // Assume accruedProtocolFees holds the value in Oracle base units.
         // This function attempts to convert this value to a specific asset (e.g., ETH) and send to owner.
         // This needs DEX integration or a sophisticated oracle/strategy.
         // For this example, let's make accruedProtocolFees represent a claim on the bundle's value
         // that the owner can 'claim' or 'sweep'. It doesn't correspond to specific tokens here.

         // Reverting to initial model: accruedProtocolFees stores the *amount* of YSB shares owned by the protocol.
         // Strategy harvests yield, sends fee % as ASSETS back to vault, vault SWAPS ASSETS for YSB, HOLDS YSB.
         // `distributeFees` SENDS HELD YSB TO OWNER. This still requires a swap mechanism.

         // Let's use the accruedProtocolFees counter as *value* in oracle base units.
         // When harvest happens, strategy reports yield, a fee is calculated (value), added to accruedProtocolFees.
         // When distributeFees is called, owner receives the accrued value, and it's reset.
         // This doesn't actually transfer assets, just tracks the value owed. Asset transfer is separate/complex.

         // Okay, final simplified model for demo:
         // `performanceFeeRateBasisPoints` is set.
         // `harvestYield()` is called (by manager/strategy). Strategy harvests.
         // Strategy must then call a helper in the vault: `reportHarvestedYield(uint256 yieldValue)`.
         // Vault calculates fee: `feeValue = (yieldValue * performanceFeeRateBasisPoints) / 10000`.
         // `accruedProtocolFees += feeValue`.
         // `distributeFees()` called by owner/manager. This just triggers a conceptual distribution event.
         // The actual asset transfer would happen off-chain or via a complex on-chain mechanism (swapping, sending specific tokens).
         // Let's add `reportHarvestedYield`.

         // Removing distributeFees and harvestYield as separate steps.
         // The strategy handles harvest and fee sending internally, based on the rate set here.
         // It sends the fee assets directly to the owner or treasury address.
         // The vault only sets the rate.
         // We'll keep `accruedProtocolFees` as a conceptual value tracker.

         // Redefining `harvestYield`: Called by manager/strategy, it tells the strategy to harvest. Strategy *then* sends fees directly.
         currentStrategy.harvest();
         // The strategy is responsible for calculating the fee based on `performanceFeeRateBasisPoints` (fetched from vault)
         // and sending fee assets (e.g., a percentage of harvested tokens) to the owner/treasury address (fetched from vault).
         // This vault contract doesn't hold/distribute the fee assets directly in this simplified model.
         // `accruedProtocolFees` state variable becomes redundant in this model. Let's remove it.

         // Need functions for setting the fee recipient if not owner.
         // Let's add `setFeeRecipient`.

         // Re-adding `harvestYield` as a manager/strategy callable function to trigger strategy harvest.
         // Re-adding `distributeFees` as a separate step.
         // Let's make `accruedProtocolFees` store the value that should be distributed.
         // The strategy will report yield value, fees calculated and added to `accruedProtocolFees`.
         // `distributeFees` will need to convert `accruedProtocolFees` value into assets. This is still hard.

         // OK, last attempt for a demo:
         // accruedProtocolFees stores the *value* (in oracle base unit) owed to the protocol.
         // Strategy harvests, calculates fee value, calls `reportFeeValue(uint256 feeValue)` on the vault.
         // Vault adds `feeValue` to `accruedProtocolFees`.
         // `distributeFees` can *only* be called by the owner. It triggers sending assets.
         // Which assets? Let's assume the vault sends a predefined asset (e.g., ETH) equivalent to the value.
         // Requires ETH balance in the vault, which must come from fees sent by strategy or deposits.
         // Simpler: The strategy sends fees in the yield-bearing asset back to the vault.
         // `accruedProtocolFees` will store a mapping of token => amount owed.

         // Reverting to initial `accruedProtocolFees` storing total value owed.
         // `distributeFees` is called by owner. It needs to convert `accruedProtocolFees` value into assets and send.
         // How? Let's assume the strategy sends fee assets back to the vault, and `distributeFees` transfers specific tokens.
         // This needs tracking which tokens are fee tokens.

         // Let's make `accruedProtocolFees` store the *amount* of the *vault's own share token (YSB)*
         // that the protocol has accrued.
         // The strategy harvests yield, calculates fee value, SWAPS for YSB tokens on a DEX, and sends YSB tokens to the vault address.
         // `distributeFees` transfers `balanceOf(address(this))` YSB tokens to the owner.

         accruedProtocolFees = _balances[address(this)]; // Update accrued value based on YSB held by vault
         if (accruedProtocolFees == 0) return; // No YSB shares held as fees

         uint256 fees = accruedProtocolFees;
         accruedProtocolFees = 0; // Reset counter (conceptual, as balance changes)

         _transfer(address(this), owner(), fees); // Transfer YSB shares from vault to owner
         emit FeesDistributed(fees);
     }

     function setPerformanceFeeRate(uint256 rateBasisPoints) public onlyOwner {
         if (rateBasisPoints > 10000) revert InvalidAmount(); // Cannot be more than 100%
         performanceFeeRateBasisPoints = rateBasisPoints;
         emit PerformanceFeeRateSet(rateBasisPoints);
     }

     // No getAccruedProtocolFees needed if fees are just balance. Let's keep it for tracking.
     // This will just report the balance of the vault's own token.
     function getAccruedProtocolFees() public view returns (uint256) {
         return _balances[address(this)]; // Assuming fees are collected as YSB shares held by the vault
     }


    // --- Strategy Management ---

    function setStrategy(address newStrategy) public onlyOwner {
        if (newStrategy == address(0)) revert ZeroAddress();
        if (newStrategy == address(currentStrategy)) revert StrategyAlreadyActive();

        // Optional: Call retire() on the old strategy if it exists
        if (address(currentStrategy) != address(0)) {
            try currentStrategy.retire() {} catch {} // Best effort call
        }

        // Add the new strategy as a manager, remove the old one unless it's still owner/another manager
        if(address(currentStrategy) != address(0)) {
             // Only remove if it was added *as* a strategy manager for this role.
             // A dedicated mapping for strategy managers is better. Let's use that.
             // isStrategyManager already tracks this. No special logic needed here.
        }
         // Add the new strategy as a manager automatically? Yes, convenient.
         isStrategyManager[newStrategy] = true;
         emit StrategyManagerAdded(newStrategy);


        address oldStrategy = address(currentStrategy);
        currentStrategy = IStrategy(newStrategy);
        emit StrategySet(oldStrategy, newStrategy);
    }

    function addStrategyManager(address manager) public onlyOwner {
        if (manager == address(0)) revert ZeroAddress();
        isStrategyManager[manager] = true;
        emit StrategyManagerAdded(manager);
    }

    function removeStrategyManager(address manager) public onlyOwner {
        if (manager == address(0)) revert ZeroAddress();
        // Prevent removing the active strategy itself unless it's also the owner.
        // The active strategy *must* be able to call `executeStrategy`.
        // Let's disallow removing the *active strategy address* as a manager.
        if (manager == address(currentStrategy)) revert InvalidAmount(); // Use generic error

        isStrategyManager[manager] = false;
        emit StrategyManagerRemoved(manager);
    }

    function isStrategyManager(address account) public view returns (bool) {
        return isStrategyManager[account];
    }


    // This function is designed to be called *only* by the current Strategy contract.
    // It allows the strategy to perform actions on behalf of the vault (like transfers).
    function executeStrategy(bytes calldata data) public whenNotPaused onlyStrategy {
         // Decode the data and execute the intended call.
         // This is a generic executor. The strategy encodes the target address, value, and call data.
         // Example: strategy wants to call IERC20(token).transfer(recipient, amount)
         // `data` would be abi.encodeCall(IERC20.transfer, (recipient, amount))
         // The target address must be known implicitly or passed in `data`.
         // A safer pattern is to have predefined vault actions the strategy can trigger,
         // rather than arbitrary calls via `execute`.
         // Example: `transferERC20(token, recipient, amount)` only callable by strategy.

         // Let's implement a safer pattern with predefined actions.
         // The strategy calls specific functions on the vault, not a generic execute.
         // Removing this generic `executeStrategy`.
         // The strategy will interact with the vault via `transferERC20ByStrategy`, etc.

         // Let's redefine `executeStrategy` as a function on the *Vault* that the strategy calls.
         // The strategy calls `vault.transferERC20ByStrategy(...)`, not `vault.executeStrategy(abi.encodeCall(IERC20.transfer, ...))`
         // This requires adding specific functions for the strategy to call.

         // Reverting to the generic model for maximum flexibility (at higher risk).
         // The `data` should encode a call to an external contract.
         // The strategy needs the vault address to call it.
         // The data should be `targetAddress.call(payload)`.

         // Let's assume `data` is the raw calldata for an *external* call originating from the vault.
         // The strategy provides `targetAddress` and `callData`.
         // This requires the strategy to know the vault's ABI or target ABI.
         // A common pattern: Strategy calls `vault.callExternal(address target, bytes calldata data)`.
         // This function can only be called by the Strategy.

         // Let's add `callExternalByStrategy`. Remove `executeStrategy`.

         revert("Deprecated: Use specific functions or callExternalByStrategy"); // Deprecate the old `executeStrategy` concept
    }

    // New function for strategy to call external contracts
    function callExternalByStrategy(address target, bytes calldata data) public whenNotPaused onlyStrategy returns (bool success, bytes memory result) {
        if (target == address(0)) revert ZeroAddress();
        // Prevent calling back into self or sensitive addresses if needed, though `onlyStrategy` should limit abuse.
        // Be cautious allowing calls to self or owner address from strategy.

        // It might be safer to only allow calls to approved DeFi protocol addresses.
        // This would require a mapping `approvedStrategyCallTarget[address]`.

        (success, result) = target.call(data);
        // Strategy is responsible for checking `success` and `result`

        // No event for now, too frequent. Strategy should emit events.
        return (success, result);
    }


     function triggerManualRebalance(bytes calldata data) public whenNotPaused onlyStrategyOrManager {
         // Trigger the current strategy's rebalance function.
         currentStrategy.rebalance(data);
         // Strategy implementation determines what 'rebalance' means and uses callExternalByStrategy if needed.
     }

     function setStrategyParameters(bytes calldata data) public whenNotPaused onlyStrategyOrManager {
         // Allows owner or strategy manager to update internal parameters of the strategy contract.
         // Strategy contract must expose a `setParameters` function.
         currentStrategy.setParameters(data);
     }


    // --- Dynamic Strategy Shift ---

    function setDynamicShiftCondition(uint256 conditionType, uint256 threshold, address alternativeStrategy) public onlyOwner {
         if (alternativeStrategy == address(0)) revert ZeroAddress();
         // Consider validating `alternativeStrategy` exists and implements `IStrategy`.
         dynamicShiftConditions[conditionType] = DynamicShiftConfig({
             threshold: threshold,
             alternativeStrategy: alternativeStrategy
         });
         // Add the alternative strategy as a manager? Not automatically, owner does it via addStrategyManager.
         emit DynamicShiftConditionSet(conditionType, threshold, alternativeStrategy);
     }

    // This function is intended to be called by a trusted keeper or an oracle.
    // It checks if a predefined condition is met using the oracle and, if so, switches the strategy.
     function triggerDynamicStrategyShift(uint256 conditionType, bytes calldata oracleData) public whenNotPaused {
         // Could restrict caller to a specific keeper address or a trusted oracle source.
         // For now, allows anyone to trigger the check, but the check relies on the trusted oracle.

         DynamicShiftConfig memory config = dynamicShiftConditions[conditionType];
         if (config.alternativeStrategy == address(0)) revert DynamicShiftConditionNotSet(); // Condition not configured

         bool conditionMet = priceOracle.checkCondition(address(this), conditionType, config.threshold, oracleData);

         if (conditionMet) {
             // Execute the strategy shift
             setStrategy(config.alternativeStrategy); // Uses the existing setStrategy function
             emit DynamicStrategyShift(conditionType, address(currentStrategy), config.alternativeStrategy);
         } else {
             revert DynamicShiftConditionNotMet();
         }
     }


    // --- Rescue Functions ---
    // Allows owner to rescue tokens accidentally sent to the contract,
    // EXCEPT approved underlying tokens (as they are part of the bundle)
    // or the contract's own YSB token.

    function rescueERC20(address token, uint256 amount) public onlyOwner {
        if (token == address(0)) revert ZeroAddress();
        if (token == address(this)) revert InvalidToken(); // Cannot rescue own token
        if (approvedUnderlying[token]) revert InvalidToken(); // Cannot rescue approved assets

        _transferERC20(token, owner(), amount);
    }

     function rescueERC721(address collection, uint256 tokenId) public onlyOwner {
        if (collection == address(0)) revert ZeroAddress();
        if (approvedUnderlying[collection] && approvedERC721Ids[collection][tokenId]) revert InvalidERC721Id(); // Cannot rescue approved NFTs

        // Check if the contract actually owns the NFT
        if (IERC721(collection).ownerOf(tokenId) != address(this)) revert ERC721NotHeldInVault();

        IERC721(collection).safeTransferFrom(address(this), owner(), tokenId);
    }


    // --- Internal Transfer Helpers ---

    function _transferERC20(address token, address recipient, uint256 amount) internal {
        uint256 balanceBefore = IERC20(token).balanceOf(address(this));
        // The contract must have enough balance. Assets managed by the strategy might not be directly available.
        // This implies assets rescued must be sitting idly in the vault address.
        if (balanceBefore < amount) revert InsufficientBalance();

        (bool success, ) = IERC20(token).transfer(recipient, amount);
        if (!success) revert TransferFailed();
    }

    // --- ERC721Holder Callback ---
    // Required by OpenZeppelin's ERC721Holder for safety.
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        // Only accept transfers from msg.sender during deposit
        // The depositERC721 function calls safeTransferFrom, which triggers this.
        // Need to ensure `from` is the user and `operator` is msg.sender or approved.
        // The ERC721 standard handles operator/from checks before calling this callback.
        // We just need to ensure the token is approved for deposit.

        // The deposit function checks `approvedUnderlying` and `approvedERC721Ids` *before* the transfer.
        // This callback primarily serves as a safety mechanism to reject unexpected NFT transfers.
        // We should only accept if the deposit process initiated this.
        // This requires tracking if a deposit is in progress, or relying solely on the pre-checks in deposit.
        // Relying on pre-checks in deposit is simpler and standard. This callback just returns the magic value.
        // If an *unsolicited* NFT transfer happens, it will revert because depositERC721 wasn't called.

        // Add a basic check: ensure the collection is approved, just in case.
        // This doesn't prevent *any* approved NFT from being sent if not deposited via depositERC721,
        // but it's better than nothing. A robust system needs more sophisticated state tracking
        // or only allowing transfers from approved strategy addresses/owner.
        // If `approvedUnderlying[msg.sender]` (where msg.sender is the NFT collection) is false,
        // it means an unapproved NFT collection is trying to enter.
        // This check is incorrect. `msg.sender` for `onERC721Received` is the ERC721 contract address.
        // We need to check `approvedUnderlying[address(this)]`?? No. Check the token being received (`msg.sender`).

        if (!approvedUnderlying[msg.sender]) {
             revert InvalidToken(); // Reject unsolicited/unapproved NFT collection
        }
        // Note: This check alone doesn't ensure the *specific* tokenId is approved, nor that
        // it came from a deposit flow. It just stops completely unapproved collections.
        // Full safety requires combining this with deposit flow state.

        return this.onERC721Received.selector;
    }
}

// Dummy or simplified implementations for interfaces for testing/conceptual understanding
// In a real scenario, these would be deployed separately.

contract DummyStrategy is IStrategy {
    YieldBearingStrategyBundle public vault; // To interact with the vault

    constructor(address _vault) {
        vault = YieldBearingStrategyBundle(_vault);
    }

    function execute(bytes calldata data) external override {
        // Decode data and call vault.callExternalByStrategy
        // Example: data = abi.encode(targetAddress, callData)
        (address target, bytes memory callData) = abi.decode(data, (address, bytes));
        (bool success, ) = vault.callExternalByStrategy(target, callData);
        require(success, "Strategy execution failed");
        // Real strategy would handle results
    }

    function harvest() external override {
        // Simulate harvesting yield and potentially sending fees back to the vault owner
        // In a real scenario, this interacts with farming protocols, liquidates rewards, etc.
        // uint256 harvestedAmount = ...; // Simulate yield harvested
        // uint256 feeAmount = (harvestedAmount * vault.performanceFeeRateBasisPoints()) / 10000;
        // Send feeAmount of a specific asset (e.g., DAI) to vault.owner()
        // IERC20(daiAddress).transfer(vault.owner(), feeAmount);
    }

    function rebalance(bytes calldata data) external override {
         // Simulate rebalancing - e.g., swapping assets using vault.callExternalByStrategy
         // (address tokenIn, uint256 amountIn, address tokenOut, address dexRouter) = abi.decode(data, ...);
         // bytes memory swapCallData = abi.encode(...); // Encode swap call
         // vault.callExternalByStrategy(dexRouter, swapCallData);
    }

    function setParameters(bytes calldata data) external override {
        // Decode data and update strategy's internal parameters
        // Example: (uint256 newThreshold) = abi.decode(data, (uint256));
        // myThreshold = newThreshold;
    }

     // Simplified: Reports total ERC20 value held directly by the strategy + its 'managed' assets
     function getTotalStrategyValue(address vaultAddress, IPriceOracle oracle) external view override returns (uint256) {
         // In a real strategy, this is complex: sum value of assets in external protocols (like Aave, Uniswap LPs)
         // Plus assets held directly by the strategy contract.
         // For demo, let's just get value of some placeholder assets held by this strategy contract.
         // Assumes this strategy holds TOKEN_A and TOKEN_B.
         // address tokenA = ...;
         // address tokenB = ...;
         // uint256 balanceA = IERC20(tokenA).balanceOf(address(this));
         // uint256 balanceB = IERC20(tokenB).balanceOf(address(this));
         // uint256 valueA = oracle.getValue(tokenA, balanceA, vaultAddress);
         // uint256 valueB = oracle.getValue(tokenB, balanceB, vaultAddress);
         // return valueA + valueB;

         // Placeholder: return a hardcoded or simulated value
         return 1000e18; // Simulate $1000 worth of assets
     }

     function retire() external override {
         // Optional: Called before strategy switch. Can unwind positions.
     }
}

contract DummyPriceOracle is IPriceOracle {
     // --- SIMPLIFIED DUMMY ORACLE ---
     // THIS DOES NOT PROVIDE REAL PRICES AND IS INSECURE.
     // A real oracle uses decentralized feeds (like Chainlink, Tellor) or TWAPs from DEXs.
     // It must be resilient to manipulation.

    mapping(address => uint256) public tokenPrices; // tokenAddress -> price in base unit (e.g., wei of a stablecoin)
    mapping(address => mapping(uint256 => uint256)) public nftPrices; // collection -> tokenId -> price

    // For dynamic shifts:
    mapping(uint256 => bool) public conditionStatus; // conditionType -> status (e.g., is price below threshold)

    function setPrice(address tokenOrCollection, uint256 price) public {
        tokenPrices[tokenOrCollection] = price;
    }

    function setNFTPrice(address collection, uint256 tokenId, uint256 price) public {
         nftPrices[collection][tokenId] = price;
    }

     function setConditionStatus(uint256 conditionType, bool status) public {
         conditionStatus[conditionType] = status;
     }


    function getValue(address tokenOrCollection, uint256 amountOrId, address vault) external view override returns (uint256) {
        // This needs to distinguish between ERC20 (amount) and ERC721 (id)
        // Simple heuristic: if amountOrId is large, treat as ERC20 amount, otherwise as ERC721 ID.
        // This is very brittle. Real oracle needs type info or separate functions.

        // Let's assume amountOrId is an amount if > 1000, otherwise maybe an ID.
        // Or check if the token/collection is in our NFT price map.

        if (nftPrices[tokenOrCollection][amountOrId] > 0) {
            // Treat as NFT ID
            return nftPrices[tokenOrCollection][amountOrId];
        } else {
            // Treat as ERC20 amount
            uint256 price = tokenPrices[tokenOrCollection];
            if (price == 0) return 0; // No price available
            // Price is likely per token unit (e.g., wei). Calculate total value.
            // Value = (amount * price) / 1e18 (if price is scaled to 1e18)
            // Or assuming price is in oracle's base unit: Value = amount * price (simplified)
            // Let's assume tokenPrices is scaled such that price * amount gives value directly (e.g., price is per wei)
            return amountOrId * price; // DANGEROUS: integer overflow possible
            // Safer: return (amountOrId / 1e18) * price if price is per token, or (amountOrId * price) / SCALE if price is scaled.
            // Assuming price is scaled to 1e18 per base unit (e.g., 1 USD).
            // If token has 18 decimals: (amount * price) / 1e18
            // If token has 6 decimals: (amount * price) / 1e6
            // Needs token decimal info. Let's simplify to just `price * amountOrId` and assume caller/price knows scaling.
        }
         // This is too simplistic. Let's define separate functions for ERC20 and ERC721 value.
         // But the interface only has one `getValue`. Let's assume it works for both.
         // A real oracle would need to handle this type difference.
    }

     function getERC20PortfolioValue(address[] calldata tokens, uint256[] calldata amounts, address vaultAddress) external view override returns (uint256 totalValue) {
         require(tokens.length == amounts.length, "Mismatched arrays");
         totalValue = 0;
         for(uint i = 0; i < tokens.length; i++) {
             uint256 price = tokenPrices[tokens[i]]; // Price per token unit (wei)
             if (price > 0) {
                  // Assume price is scaled appropriately (e.g., price represents value of 1e18 token units)
                  // Value = (amount * price) / 1e18
                  totalValue += (amounts[i] * price) / 1e18; // Requires price to be large (scaled)
             }
         }
     }

     function getERC721PortfolioValue(address[] calldata collections, uint256[] calldata tokenIds, address vaultAddress) external view override returns (uint256 totalValue) {
          require(collections.length == tokenIds.length, "Mismatched arrays");
          totalValue = 0;
          for(uint i = 0; i < collections.length; i++) {
              uint256 price = nftPrices[collections[i]][tokenIds[i]];
              totalValue += price; // Assume price is already in the base unit
          }
     }


    function checkCondition(address vaultAddress, uint256 conditionType, uint256 threshold, bytes calldata oracleData) external view override returns (bool) {
        // Simulate checking a condition based on oracleData and internal state.
        // conditionType: e.g., 1 = Price below threshold, 2 = TVL above threshold
        // oracleData: e.g., current price of a key asset
        // threshold: value to check against

        // Example: conditionType 1 = Is ETH price (oracleData) below threshold?
        // uint256 currentEthPrice = abi.decode(oracleData, (uint256));
        // if (conditionType == 1) {
        //     return currentEthPrice < threshold;
        // }

        // Simple dummy check: just return a pre-set status
        return conditionStatus[conditionType];
    }
}


// Standard OpenZeppelin contracts used
// IERC20.sol           (from @openzeppelin/contracts/token/ERC20/IERC20.sol)
// IERC721.sol          (from @openzeppelin/contracts/token/ERC721/IERC721.sol)
// Ownable.sol          (from @openzeppelin/contracts/access/Ownable.sol)
// Pausable.sol         (from @openzeppelin/contracts/security/Pausable.sol)
// ERC721Holder.sol     (from @openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol)
// Address.sol          (from @openzeppelin/contracts/utils/Address.sol)
```