Okay, let's design a smart contract that's interesting, advanced, creative, and trendy, without being a direct copy of a well-known open-source protocol.

We'll create a **"QuantumFund"** - a pooled investment fund that can hold various whitelisted ERC-20 tokens and even whitelisted ERC-721 NFTs. The "quantum" aspect comes from the idea of dynamic, potentially complex, and non-obvious interactions between different asset types and configurable algorithmic strategies chosen by a governance mechanism based on the fund's own shares.

This contract incorporates:
1.  **Multi-Asset Pooling:** Handling both ERC-20s and ERC-721s.
2.  **Dynamic Strategy Framework:** Not hardcoding investment logic, but allowing the selection and weighting of different strategy modules.
3.  **Fund Share Token:** Users deposit assets and get ERC-20 shares representing their stake (`QFToken`).
4.  **On-Chain Valuation:** Calculating the fund's total value requires summing up the value of diverse assets (using oracles for tokens, potentially simplified valuation for NFTs).
5.  **Governance:** Using the fund's own `QFToken` for basic governance over whitelisted assets, strategies, and parameters.
6.  **Fees:** Deposit, withdrawal, and potential performance fees.
7.  **Pause Mechanism:** For emergencies.

**Disclaimer:** This is a complex conceptual contract designed for demonstration purposes. A production-ready version would require extensive security audits, gas optimizations, robust oracle handling (especially for NFTs), detailed strategy module logic, and a more sophisticated governance implementation.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol"; // To receive NFTs
import "@openzeppelin/contracts/access/Ownable.sol"; // For initial ownership/setup
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Although 0.8+ has built-in overflow checks, SafeMath can add clarity in some contexts or be used for division/multiplication
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

// Assuming Chainlink oracles or similar price feeds are available
interface AggregatorV3Interface {
    function latestRoundData()
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

// Interface for potential external swap protocols (e.g., Uniswap V3 Router mock)
interface ISwapRouter {
    // Placeholder for a swap function - actual implementation varies greatly
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// Interface for strategy modules that the fund can execute
interface IStrategyModule {
    // Unique identifier for the strategy
    function strategyId() external view returns (uint256);

    // Description of the strategy
    function description() external view returns (string memory);

    // Function to execute the strategy logic
    // Can take bytes for arbitrary parameters for the specific strategy execution
    function execute(bytes calldata data) external returns (bool success);

    // Returns whether the strategy is currently active or requires specific conditions
    function isActive() external view returns (bool);

    // Returns a list of tokens/NFTs the strategy might require or produce
    function getRequiredAssets() external view returns (address[] memory tokenAddrs, address[] memory nftAddrs);
}


/**
 * @title QuantumFund
 * @dev A dynamic, multi-asset pooled fund with algorithmic strategies and self-governance.
 * Users deposit whitelisted ERC-20s and ERC-721s to receive QFToken shares.
 * Fund value is calculated based on held assets and oracle prices.
 * Governance (using QFToken) selects and weights strategies.
 */
contract QuantumFund is ERC20, ERC721Holder, Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    // --- Outline ---
    // 1. State Variables
    // 2. Events
    // 3. Constructor
    // 4. ERC-721 Receiver Hook (from ERC721Holder)
    // 5. Fund Core Operations (Deposit, Withdraw, Valuation)
    // 6. Asset Whitelisting & Management
    // 7. Strategy Management & Execution
    // 8. Fee Management
    // 9. Governance (Simplified Placeholder)
    // 10. Information / View Functions
    // 11. Emergency Controls (Pause)
    // 12. Owner/Manager Functions (initial setup, transfers etc.)

    // --- Function Summary ---
    // 1. constructor() - Initializes the contract, sets QFToken details, initial owner.
    // 2. onERC721Received() - Hook to receive NFTs, verifies whitelisting.
    // 3. depositERC20() - Allows users to deposit whitelisted ERC-20 tokens.
    // 4. depositERC721() - Allows users to deposit whitelisted ERC-721 tokens.
    // 5. withdraw() - Allows users to redeem QFTokens for a proportional share of fund assets.
    // 6. getTotalFundValue() - Calculates the total value of all assets held by the fund.
    // 7. getSharePrice() - Calculates the value of one QFToken share.
    // 8. addWhitelistedToken() - Adds an ERC-20 token to the whitelist.
    // 9. removeWhitelistedToken() - Removes an ERC-20 token from the whitelist.
    // 10. addWhitelistedNFT() - Adds an ERC-721 token to the whitelist.
    // 11. removeWhitelistedNFT() - Removes an ERC-721 token from the whitelist.
    // 12. isWhitelistedToken() - Checks if an ERC-20 token is whitelisted.
    // 13. isWhitelistedNFT() - Checks if an ERC-721 token is whitelisted.
    // 14. addStrategyModule() - Registers a new IStrategyModule contract.
    // 15. removeStrategyModule() - Deregisters an IStrategyModule contract.
    // 16. setActiveStrategies() - Sets which strategies are active and their weights (governance/manager).
    // 17. executeActiveStrategies() - Triggers execution of currently active strategies.
    // 18. setDepositFee() - Sets the deposit fee percentage (governance/manager).
    // 19. setWithdrawalFee() - Sets the withdrawal fee percentage (governance/manager).
    // 20. setPerformanceFeeRate() - Sets the performance fee rate (governance/manager).
    // 21. collectProtocolFees() - Allows the owner/manager to collect accumulated fees.
    // 22. getDepositFee() - Returns the current deposit fee.
    // 23. getWithdrawalFee() - Returns the current withdrawal fee.
    // 24. getPerformanceFeeRate() - Returns the current performance fee rate.
    // 25. getStrategyModule() - Returns information about a registered strategy module.
    // 26. getActiveStrategies() - Returns the list of currently active strategy module addresses.
    // 27. getActiveStrategyWeight() - Returns the weight for a specific active strategy.
    // 28. pause() - Pauses the contract (owner/manager).
    // 29. unpause() - Unpauses the contract (owner/manager).
    // 30. transferAnyERC20Tokens() - Allows owner/manager to rescue accidentally sent ERC20s (careful use).
    // 31. transferAnyERC721Tokens() - Allows owner/manager to rescue accidentally sent ERC721s (careful use).
    // 32. registerOracle() - Registers a price oracle for a specific ERC-20 token.
    // 33. getOracleAddress() - Returns the oracle address for a token.
    // 34. getTokenPriceUsd() - Gets the price of a token from its registered oracle.
    // 35. setNFTValuationFactor() - Sets a value factor for a whitelisted NFT collection (simplified valuation).
    // 36. getNFTValuationFactor() - Gets the value factor for an NFT collection.
    // (Potential Governance functions - simplified placeholder for now, focusing on state changes driven by owner/manager as a proxy for governance)
    // 37. proposeChange() - Placeholder for a function to initiate a governance proposal.
    // 38. voteOnProposal() - Placeholder for a function to cast a vote using QFTokens.
    // 39. executeProposal() - Placeholder for a function to execute a successful proposal.


    // --- State Variables ---

    // Mapping from whitelisted ERC-20 token addresses to boolean
    mapping(address => bool) private _whitelistedTokens;
    // Mapping from whitelisted ERC-721 token addresses to boolean
    mapping(address => bool) private _whitelistedNFTs;
    // Mapping from whitelisted ERC-20 token addresses to their price oracle addresses
    mapping(address => AggregatorV3Interface) private _tokenOracles;
    // Mapping from whitelisted ERC-721 token addresses to a simplified valuation factor (e.g., representing floor price / 1e18)
    mapping(address => uint256) private _nftValuationFactors; // Stored as token value / 1e18 for simplification

    // Mapping from strategy module address to the IStrategyModule interface
    mapping(address => IStrategyModule) private _strategyModules;
    // List of active strategy module addresses
    address[] private _activeStrategies;
    // Mapping from active strategy address to its weight (e.g., out of 10000)
    mapping(address => uint256) private _strategyWeights;
    // Total weight of active strategies (should sum up to a target, e.g., 10000, if weights are used for allocation)
    uint256 private _totalActiveWeight;

    // Fee percentages (stored with a multiplier, e.g., 100 = 1% assuming 10000 basis points)
    uint256 public depositFeeBasisPoints = 0; // e.g., 100 = 1%
    uint256 public withdrawalFeeBasisPoints = 0; // e.g., 100 = 1%
    uint256 public performanceFeeRate = 0; // Not implemented sophisticatedly here, placeholder for a future system

    // Accumulated fees (ERC-20 asset address => amount)
    mapping(address => uint256) private _protocolFees;

    // Thresholds
    uint256 public minDepositAmount = 1e16; // 0.01 ether-like units minimum

    // Governance - simplified placeholder using owner/manager access
    // In a real system, this would involve proposals, voting periods, token balance checks etc.

    // Reference to a swap router for strategy execution (placeholder)
    ISwapRouter public swapRouter;

    // --- Events ---

    event DepositMade(address indexed account, address indexed token, uint256 amount, uint256 sharesMinted, uint256 fundValue);
    event NFTDepositMade(address indexed account, address indexed nftContract, uint256 tokenId, uint256 sharesMinted, uint256 fundValue);
    event WithdrawalMade(address indexed account, uint256 sharesBurned, uint256 fundValue, uint256 assetsWithdrawnCount);
    event WhitelistedTokenAdded(address indexed token);
    event WhitelistedTokenRemoved(address indexed token);
    event WhitelistedNFTAdded(address indexed nftContract);
    event WhitelistedNFTRemoved(address indexed nftContract);
    event StrategyModuleAdded(address indexed strategyAddress, uint256 strategyId);
    event StrategyModuleRemoved(address indexed strategyAddress);
    event ActiveStrategiesUpdated(address[] activeStrategies, uint256[] weights);
    event StrategyExecuted(address indexed strategyAddress, bool success);
    event DepositFeeUpdated(uint256 newFee);
    event WithdrawalFeeUpdated(uint256 newFee);
    event ProtocolFeesCollected(address indexed token, uint256 amount);
    event OracleRegistered(address indexed token, address indexed oracle);
    event NFTValuationFactorUpdated(address indexed nftContract, uint256 factor);
    event MinDepositAmountUpdated(uint256 newMinAmount);


    // --- Constructor ---

    constructor(string memory name, string memory symbol)
    ERC20(name, symbol) // e.g., "QuantumFund Shares", "QFS"
    Ownable(msg.sender)
    {}

    // --- ERC-721 Receiver Hook ---

    // This function is called by an ERC-721 contract when an NFT is transferred to this contract.
    // We override the default ERC721Holder behavior to add our whitelisting check.
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
    override
    public
    whenNotPaused
    returns (bytes4)
    {
        require(_whitelistedNFTs[msg.sender], "QuantumFund: ERC721 contract not whitelisted");
        // Optional: add more checks based on `data` if specific deposit logic is needed per NFT.
        // For simplicity, we assume direct deposits handle the share minting.
        // This hook primarily ensures we can receive whitelisted NFTs directly.
        // The actual share minting happens in depositERC721.
        return this.onERC721Received.selector;
    }

    // --- Fund Core Operations ---

    /**
     * @dev Deposits a whitelisted ERC-20 token into the fund and mints QFToken shares.
     * @param token The address of the ERC-20 token.
     * @param amount The amount of tokens to deposit.
     */
    function depositERC20(address token, uint256 amount) external nonReentrant whenNotPaused {
        require(_whitelistedTokens[token], "QuantumFund: Token not whitelisted for deposit");
        require(amount >= minDepositAmount, "QuantumFund: Deposit amount below minimum");

        uint256 currentFundValue = getTotalFundValue();
        uint256 totalShares = totalSupply();

        // Calculate shares to mint
        uint256 sharesToMint;
        if (totalShares == 0) {
            // First deposit sets the initial share price (1 share = 1 token value equivalent)
            sharesToMint = amount; // Simplified: assume 1 token unit = 1 share initially
            // A more accurate way might be to value the *first* deposited asset in USD and mint shares based on that,
            // e.g., sharesToMint = amount * tokenPriceUSD / sharePriceUSD (where initial sharePriceUSD is arbitrary, like $1).
            // For simplicity, let's tie shares to the *amount* of the *first* asset deposited. This has limitations.
            // A better approach for multi-asset initial deposit is required in a real system.
            // Let's refine: initial share price is 1e18 Wei per $1 equivalent.
            // Shares = (deposit_amount * token_price_usd * 1e18) / initial_share_price
            // Initial share price (conceptual) = 1e18 (representing $1 USD equivalent per share)
            uint256 tokenPriceUsd = getTokenPriceUsd(token); // Price in USD with oracle decimals (e.g., 10^8 or 10^18)
            uint256 oracleDecimals = uint256(AggregatorV3Interface(_tokenOracles[token]).latestRoundData().answeredInRound);

            // Convert token amount to USD equivalent value (using 1e18 for calculations)
            // Adjusted for token decimals and oracle decimals
            // USD Value = (amount * tokenPriceUsd * 1e18) / (10**tokenDecimals * 10**oracleDecimals)
            // Let's normalize token price to 1e18 for calculation: normalizedPrice = tokenPriceUsd * (10**(18 - oracleDecimals))
            // USD Value = (amount * normalizedPrice) / (10**tokenDecimals)
            uint256 tokenDecimals = IERC20(token).decimals();
            uint256 normalizedPrice = tokenPriceUsd;
            if (oracleDecimals < 18) {
                 normalizedPrice = normalizedPrice.mul(10**(18 - oracleDecimals));
            } else if (oracleDecimals > 18) {
                 normalizedPrice = normalizedPrice.div(10**(oracleDecimals - 18));
            }

            uint256 depositValueUsd_1e18 = amount.mul(normalizedPrice).div(10**tokenDecimals);
            sharesToMint = depositValueUsd_1e18; // 1 share = 1 USD equivalent initially (in 1e18 units)

        } else {
            // Subsequent deposits: calculate shares based on current fund value and total supply
            // Shares = (deposit_value_usd * total_shares) / current_fund_value_usd
            uint256 tokenDecimals = IERC20(token).decimals();
            uint256 tokenPriceUsd = getTokenPriceUsd(token);
             uint256 oracleDecimals = uint256(AggregatorV3Interface(_tokenOracles[token]).latestRoundData().answeredInRound);

            uint256 normalizedPrice = tokenPriceUsd;
            if (oracleDecimals < 18) {
                 normalizedPrice = normalizedPrice.mul(10**(18 - oracleDecimals));
            } else if (oracleDecimals > 18) {
                 normalizedPrice = normalizedPrice.div(10**(oracleDecimals - 18));
            }

            uint256 depositValueUsd_1e18 = amount.mul(normalizedPrice).div(10**tokenDecimals);

            // Ensure currentFundValue > 0 to avoid division by zero
             require(currentFundValue > 0, "QuantumFund: Fund value must be greater than zero");

            sharesToMint = depositValueUsd_1e18.mul(totalShares).div(currentFundValue);
        }

        require(sharesToMint > 0, "QuantumFund: Shares to mint must be greater than zero");

        // Apply deposit fee
        uint256 feeAmount = sharesToMint.mul(depositFeeBasisPoints).div(10000);
        uint256 sharesAfterFee = sharesToMint.sub(feeAmount);

        // Transfer tokens to the contract
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        // Mint shares to the depositor
        _mint(msg.sender, sharesAfterFee);

        // Accumulate fees (in QFToken equivalent for simplicity, but could track per-asset)
        // For simplicity, let's track fees in QFToken value equivalent.
        // In a real system, fees might be collected in the deposited asset or a specified fee token.
        // Let's track fees as a claim on the total fund value, represented by QFToken amount.
        // The actual fee collection (`collectProtocolFees`) would involve swapping or transferring underlying assets.
        // For *this* example, we'll track fees as if they were collected in QF Tokens for simpler accounting in this contract.
        // Acknowledge this is a simplification: real fee collection is more complex.
        _protocolFees[address(this)] = _protocolFees[address(this)].add(feeAmount); // Track fee in QFToken value

        emit DepositMade(msg.sender, token, amount, sharesAfterFee, currentFundValue);
    }

    /**
     * @dev Deposits a whitelisted ERC-721 token into the fund and mints QFToken shares.
     * Note: Requires the user to approve the NFT transfer to the fund contract *before* calling this function.
     * @param nftContract The address of the ERC-721 contract.
     * @param tokenId The ID of the NFT to deposit.
     */
    function depositERC721(address nftContract, uint256 tokenId) external nonReentrant whenNotPaused {
        require(_whitelistedNFTs[nftContract], "QuantumFund: NFT contract not whitelisted for deposit");
        // Check if NFT is owned by the depositor
        require(IERC721(nftContract).ownerOf(tokenId) == msg.sender, "QuantumFund: Caller does not own the NFT");

        uint256 currentFundValue = getTotalFundValue();
        uint256 totalShares = totalSupply();

        // Get NFT value using the simplified factor
        uint256 nftValueUsd_1e18 = getNFTValueUsd(nftContract, tokenId); // Uses the factor

        require(nftValueUsd_1e18 > 0, "QuantumFund: NFT has no value or factor not set");

        uint256 sharesToMint;
        if (totalShares == 0) {
            // First deposit, initialize shares based on NFT value
             sharesToMint = nftValueUsd_1e18; // 1 share = 1 USD equivalent initially (in 1e18 units)
        } else {
            // Subsequent deposits: calculate shares based on current fund value and total supply
            // Shares = (nft_value_usd * total_shares) / current_fund_value_usd
            require(currentFundValue > 0, "QuantumFund: Fund value must be greater than zero");
            sharesToMint = nftValueUsd_1e18.mul(totalShares).div(currentFundValue);
        }

         require(sharesToMint > 0, "QuantumFund: Shares to mint must be greater than zero");

        // Apply deposit fee
        uint256 feeAmount = sharesToMint.mul(depositFeeBasisPoints).div(10000);
        uint256 sharesAfterFee = sharesToMint.sub(feeAmount);

        // Transfer NFT to the contract (requires prior approval)
        IERC721(nftContract).safeTransferFrom(msg.sender, address(this), tokenId, ""); // The "" data triggers onERC721Received if implemented

        // Mint shares to the depositor
        _mint(msg.sender, sharesAfterFee);

         // Accumulate fees (in QFToken value equivalent)
        _protocolFees[address(this)] = _protocolFees[address(this)].add(feeAmount);

        emit NFTDepositMade(msg.sender, nftContract, tokenId, sharesAfterFee, currentFundValue);
    }


    /**
     * @dev Allows users to redeem QFToken shares for a proportional share of the fund's assets.
     * The specific assets returned depend on the fund's current holdings and are distributed proportionally.
     * @param shares The number of QFToken shares to burn.
     */
    function withdraw(uint256 shares) external nonReentrant whenNotPaused {
        require(shares > 0, "QuantumFund: Amount of shares to withdraw must be greater than zero");
        require(balanceOf(msg.sender) >= shares, "QuantumFund: Not enough shares");

        uint256 currentFundValue = getTotalFundValue();
        uint256 totalShares = totalSupply();

        // Avoid division by zero if fund is empty (shouldn't happen if shares > 0, but good practice)
        require(totalShares > 0, "QuantumFund: No shares outstanding");
        require(currentFundValue > 0, "QuantumFund: Fund value must be greater than zero");


        // Calculate the proportion of the fund value the shares represent
        // proportionalValueUsd_1e18 = (shares * currentFundValue_usd) / total_shares
        uint256 proportionalValueUsd_1e18 = shares.mul(currentFundValue).div(totalShares);
        require(proportionalValueUsd_1e18 > 0, "QuantumFund: Calculated withdrawal value is zero");

        // Apply withdrawal fee (calculated on the value *before* distributing assets)
        uint256 feeAmountUsd_1e18 = proportionalValueUsd_1e18.mul(withdrawalFeeBasisPoints).div(10000);
        uint256 valueAfterFeeUsd_1e18 = proportionalValueUsd_1e18.sub(feeAmountUsd_1e18);
        require(valueAfterFeeUsd_1e18 > 0, "QuantumFund: Value after fee is zero");


        // Burn the user's shares BEFORE transferring assets (Checks-Effects-Interactions)
        _burn(msg.sender, shares);

         // Accumulate withdrawal fees (in QFToken value equivalent)
        _protocolFees[address(this)] = _protocolFees[address(this)].add(feeAmountUsd_1e18); // Track fee in QFToken value equivalent

        // --- Asset Distribution ---
        // This is the complex part in a multi-asset fund. How do you give users
        // a proportional mix of the underlying assets?
        // Simplest approach for this example: iterate through whitelisted assets
        // and transfer a proportional amount based on their value contribution
        // to the fund's total value *at the time of withdrawal calculation*.

        uint256 assetsWithdrawnCount = 0;

        // ERC-20 Distribution
        // NOTE: This requires iterating through all *held* whitelisted tokens, not just the whitelist.
        // Tracking actual holdings requires more state or iterating through balances of all whitelisted tokens.
        // For this example, we'll iterate whitelisted tokens and assume we hold some.
        // A production system might have a list of *currently held* assets.
        address[] memory currentHeldTokens = getHeldTokens(); // Helper view function (simplified)
        for (uint i = 0; i < currentHeldTokens.length; i++) {
            address token = currentHeldTokens[i];
            if (_whitelistedTokens[token]) { // Double-check whitelist status
                 uint256 tokenBalance = IERC20(token).balanceOf(address(this));
                 if (tokenBalance > 0) {
                    uint256 tokenPriceUsd = getTokenPriceUsd(token);
                    uint256 tokenDecimals = IERC20(token).decimals();
                    uint256 oracleDecimals = uint256(AggregatorV3Interface(_tokenOracles[token]).latestRoundData().answeredInRound);

                    uint256 normalizedPrice = tokenPriceUsd;
                    if (oracleDecimals < 18) {
                         normalizedPrice = normalizedPrice.mul(10**(18 - oracleDecimals));
                    } else if (oracleDecimals > 18) {
                         normalizedPrice = normalizedPrice.div(10**(oracleDecimals - 18));
                    }

                    // Calculate USD value of this token holding (1e18)
                    uint256 tokenHoldingValueUsd_1e18 = tokenBalance.mul(normalizedPrice).div(10**tokenDecimals);

                    // Calculate the amount of *this specific token* to withdraw
                    // amount_to_withdraw = (value_after_fee_usd * token_balance) / current_fund_value_usd
                    // Need to handle potential division by zero for currentFundValue
                     uint256 amountToWithdraw = valueAfterFeeUsd_1e18.mul(tokenBalance).div(currentFundValue);

                    if (amountToWithdraw > 0) {
                        // Transfer tokens
                        IERC20(token).transfer(msg.sender, amountToWithdraw);
                        assetsWithdrawnCount++;
                    }
                 }
            }
        }

        // ERC-721 Distribution
        // This is even harder. You can't fractionalize and send *part* of an NFT.
        // Possible approaches:
        // 1. User only withdraws ERC-20s. NFTs remain in the fund until a strategy sells them.
        // 2. A dedicated "NFT Withdrawal" function where a user can claim a *specific* NFT
        //    if their shares represent at least its value, and their shares are reduced accordingly.
        // 3. Auctioning/selling NFTs internally or externally and distributing proceeds as ERC-20.
        // For *this example*, we will NOT distribute NFTs in the standard withdraw.
        // They contribute to fund value, but withdrawal only yields ERC-20s (and maybe ETH if held).
        // A separate, complex mechanism would be needed for NFT specific withdrawals.
        // Add a comment acknowledging this limitation.

        emit WithdrawalMade(msg.sender, shares, currentFundValue, assetsWithdrawnCount);
    }


    /**
     * @dev Calculates the total value of all whitelisted assets held by the fund in USD equivalent (1e18 decimals).
     * Requires registered oracles for ERC-20 tokens and valuation factors for ERC-721 collections.
     * This is a view function, but calculating value for many assets can be gas-intensive.
     * @return The total value of the fund in USD equivalent (1e18 decimals).
     */
    function getTotalFundValue() public view returns (uint256) {
        uint256 totalValueUsd_1e18 = 0;

        // Value ERC-20 holdings
         address[] memory heldTokens = getHeldTokens(); // Helper view function (simplified)
         for (uint i = 0; i < heldTokens.length; i++) {
             address token = heldTokens[i];
             if (_whitelistedTokens[token]) { // Double-check whitelist
                 uint256 balance = IERC20(token).balanceOf(address(this));
                 if (balance > 0) {
                     uint256 priceUsd = getTokenPriceUsd(token); // Price with oracle decimals
                     uint256 tokenDecimals = IERC20(token).decimals();
                     uint256 oracleDecimals = uint256(AggregatorV3Interface(_tokenOracles[token]).latestRoundData().answeredInRound);

                    // Normalize price to 1e18 before calculation
                    uint256 normalizedPrice = priceUsd;
                    if (oracleDecimals < 18) {
                         normalizedPrice = normalizedPrice.mul(10**(18 - oracleDecimals));
                    } else if (oracleDecimals > 18) {
                         normalizedPrice = normalizedPrice.div(10**(oracleDecimals - 18));
                    }

                     // Value = (balance * normalizedPrice) / (10**tokenDecimals)
                     totalValueUsd_1e18 = totalValueUsd_1e18.add(balance.mul(normalizedPrice).div(10**tokenDecimals));
                 }
             }
         }

        // Value ERC-721 holdings (using simplified valuation factor)
        address[] memory heldNFTCollections = getHeldNFTCollections(); // Helper view function (simplified)
        for (uint i = 0; i < heldNFTCollections.length; i++) {
            address nftContract = heldNFTCollections[i];
            if (_whitelistedNFTs[nftContract]) { // Double-check whitelist
                 // NOTE: Getting total value of NFTs requires knowing *which* NFTs are held.
                 // ERC721 standard doesn't have a `tokensOfOwner` directly in the interface.
                 // This would require iterating through tokenIds or relying on external indexers.
                 // For this example, we will SIMPLIFY and assume a fixed value *per NFT* in the collection
                 // based on the `_nftValuationFactors` and the *count* of NFTs held.
                 // This is highly inaccurate for real-world NFTs but serves the example.
                 uint256 nftCount = IERC721(nftContract).balanceOf(address(this));
                 if (nftCount > 0) {
                     uint256 valuationFactor_1e18 = _nftValuationFactors[nftContract]; // Assumes factor is in 1e18 USD equivalent
                     totalValueUsd_1e18 = totalValueUsd_1e18.add(nftCount.mul(valuationFactor_1e18));
                 }
            }
        }

        // ETH balance (if contract holds ETH)
        // Need to add ETH price oracle if holding/valuing ETH directly
        // uint256 ethBalance = address(this).balance;
        // If using WETH or similar, it would be covered by ERC20 valuation.

        return totalValueUsd_1e18;
    }

     /**
     * @dev Calculates the value of a single QFToken share in USD equivalent (1e18 decimals).
     * Share price = Total Fund Value / Total Shares Supply.
     * @return The value of one share in USD equivalent (1e18 decimals).
     */
    function getSharePrice() public view returns (uint256) {
        uint256 totalShares = totalSupply();
        if (totalShares == 0) {
            // If no shares exist, the conceptual share price can be set to an initial value, e.g., 1 USD equivalent
            // This matches the initial deposit logic (1 share = 1 USD eq)
            return 1e18; // Represents $1.00 with 18 decimals
        }
        uint256 totalValue = getTotalFundValue();
        if (totalValue == 0) {
             return 0; // Fund has assets but they evaluate to zero (unlikely with valid oracles)
        }
        return totalValue.mul(1e18).div(totalShares); // Share Price = (Total Value * 1e18) / Total Shares
    }

     /**
     * @dev Gets the price of a whitelisted token using its registered oracle.
     * Returns price in USD with oracle decimals. Reverts if no oracle is registered or feed is stale.
     * @param token The address of the token.
     * @return The price of the token in USD.
     */
    function getTokenPriceUsd(address token) public view returns (uint256) {
        require(_tokenOracles[token] != AggregatorV3Interface(address(0)), "QuantumFund: No oracle registered for token");
        AggregatorV3Interface oracle = _tokenOracles[token];
        (, int256 price, , uint256 updatedAt, ) = oracle.latestRoundData();
        require(price > 0, "QuantumFund: Oracle price is zero or negative");
        require(block.timestamp.sub(updatedAt) < 3600, "QuantumFund: Oracle feed is stale"); // Price feed not updated in 1 hour
        return uint256(price); // Price is returned with the oracle's decimals
    }

     /**
     * @dev Gets the simplified USD equivalent value for a specific NFT based on its collection's valuation factor.
     * This is a simplification for the example.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The ID of the NFT. (tokenId is not actually used in this simplified valuation)
     * @return The value of the NFT in USD equivalent (1e18 decimals).
     */
    function getNFTValueUsd(address nftContract, uint256 tokenId) public view returns (uint256) {
        // In a real scenario, valuing a *specific* NFT is complex.
        // It could involve:
        // - Floor price oracle (e.g., Chainlink NFT Floor Price Feeds)
        // - Appraisal mechanism (human or algorithmic)
        // - Last sale price
        // - Listing price on marketplaces
        // - Trait-based rarity valuation
        // This function uses a simplified factor *per collection* as a placeholder.
        // The factor is expected to be in 1e18 USD equivalent per NFT.
        return _nftValuationFactors[nftContract];
    }


    // --- Asset Whitelisting & Management ---

    /**
     * @dev Adds an ERC-20 token to the whitelist and optionally registers its price oracle.
     * Accessible by owner/manager (or governance).
     * @param token The address of the ERC-20 token.
     * @param oracleAddress The address of the Chainlink AggregatorV3Interface oracle for this token (can be address(0) if not needed for valuation/strategies).
     */
    function addWhitelistedToken(address token, address oracleAddress) external onlyOwner {
        require(token != address(0), "QuantumFund: Zero address not allowed for token");
         // Basic check if it looks like an ERC20 (call decimals) - not foolproof
        try IERC20(token).decimals() returns (uint8) {
            // Success
        } catch {
             revert("QuantumFund: Address is not a valid ERC20 token");
        }

        _whitelistedTokens[token] = true;
        if (oracleAddress != address(0)) {
             _tokenOracles[token] = AggregatorV3Interface(oracleAddress);
             emit OracleRegistered(token, oracleAddress);
        }

        emit WhitelistedTokenAdded(token);
    }

     /**
     * @dev Removes an ERC-20 token from the whitelist.
     * Accessible by owner/manager (or governance). Does not remove holdings.
     * @param token The address of the ERC-20 token.
     */
    function removeWhitelistedToken(address token) external onlyOwner {
        require(_whitelistedTokens[token], "QuantumFund: Token is not whitelisted");
        _whitelistedTokens[token] = false;
        // Could also remove the oracle reference here if desired
        // delete _tokenOracles[token];
        emit WhitelistedTokenRemoved(token);
    }

    /**
     * @dev Adds an ERC-721 token contract to the whitelist.
     * Accessible by owner/manager (or governance).
     * @param nftContract The address of the ERC-721 contract.
     */
    function addWhitelistedNFT(address nftContract) external onlyOwner {
        require(nftContract != address(0), "QuantumFund: Zero address not allowed for NFT contract");
         // Basic check if it looks like an ERC721 (call supportsInterface with ERC721 identifier) - not foolproof
        try IERC721(nftContract).supportsInterface(0x80ac58cd) returns (bool isERC721) {
            require(isERC721, "QuantumFund: Address is not a valid ERC721 contract");
        } catch {
             revert("QuantumFund: Address is not a valid ERC721 contract");
        }
        _whitelistedNFTs[nftContract] = true;
        // NFT valuation factor needs to be set separately
        emit WhitelistedNFTAdded(nftContract);
    }

     /**
     * @dev Removes an ERC-721 token contract from the whitelist.
     * Accessible by owner/manager (or governance). Does not remove holdings.
     * @param nftContract The address of the ERC-721 contract.
     */
    function removeWhitelistedNFT(address nftContract) external onlyOwner {
         require(_whitelistedNFTs[nftContract], "QuantumFund: NFT contract is not whitelisted");
        _whitelistedNFTs[nftContract] = false;
        // Could also remove the valuation factor reference here if desired
        // delete _nftValuationFactors[nftContract];
        emit WhitelistedNFTRemoved(nftContract);
    }

     /**
     * @dev Sets or updates the simplified valuation factor for a whitelisted NFT collection.
     * Accessible by owner/manager (or governance).
     * @param nftContract The address of the whitelisted NFT contract.
     * @param factor The new valuation factor (in 1e18 USD equivalent per NFT).
     */
    function setNFTValuationFactor(address nftContract, uint256 factor) external onlyOwner {
        require(_whitelistedNFTs[nftContract], "QuantumFund: NFT contract must be whitelisted first");
        _nftValuationFactors[nftContract] = factor;
        emit NFTValuationFactorUpdated(nftContract, factor);
    }


    // --- Strategy Management & Execution ---

    /**
     * @dev Registers a new strategy module contract. The module must implement IStrategyModule.
     * Accessible by owner/manager (or governance).
     * @param strategyAddress The address of the strategy module contract.
     */
    function addStrategyModule(address strategyAddress) external onlyOwner {
        require(strategyAddress != address(0), "QuantumFund: Zero address not allowed for strategy");
        IStrategyModule strategy = IStrategyModule(strategyAddress);
        // Basic check: call a view function from the interface
         try strategy.strategyId() returns (uint256 id) {
            require(id > 0, "QuantumFund: Invalid strategy module (ID must be > 0)");
        } catch {
             revert("QuantumFund: Address is not a valid strategy module interface");
        }

        require(_strategyModules[strategyAddress] == IStrategyModule(address(0)), "QuantumFund: Strategy already registered");
        _strategyModules[strategyAddress] = strategy;
        emit StrategyModuleAdded(strategyAddress, strategy.strategyId());
    }

    /**
     * @dev Deregisters a strategy module. Does not stop currently running logic within the module.
     * Accessible by owner/manager (or governance).
     * @param strategyAddress The address of the strategy module contract.
     */
    function removeStrategyModule(address strategyAddress) external onlyOwner {
        require(_strategyModules[strategyAddress] != IStrategyModule(address(0)), "QuantumFund: Strategy not registered");
        // Ensure it's not currently in the active strategies list (optional but recommended)
        // For simplicity, we allow removing, but `executeActiveStrategies` will skip non-registered ones.
        delete _strategyModules[strategyAddress];
        emit StrategyModuleRemoved(strategyAddress);
    }

    /**
     * @dev Sets the list of active strategies and their weights. Weights are used for allocation or priority.
     * Total weight typically sums to a fixed value (e.g., 10000).
     * Accessible by owner/manager (or governance).
     * @param strategies Array of strategy module addresses.
     * @param weights Array of weights corresponding to strategies.
     */
    function setActiveStrategies(address[] calldata strategies, uint256[] calldata weights) external onlyOwner {
        require(strategies.length == weights.length, "QuantumFund: Strategy and weight arrays must match");
        uint256 newTotalWeight = 0;
        address[] memory newActiveStrategies = new address[](strategies.length); // Create a new list

        // Clear previous weights for active strategies
        for (uint i = 0; i < _activeStrategies.length; i++) {
            delete _strategyWeights[_activeStrategies[i]];
        }

        for (uint i = 0; i < strategies.length; i++) {
            address strategyAddr = strategies[i];
            uint256 weight = weights[i];
            require(_strategyModules[strategyAddr] != IStrategyModule(address(0)), "QuantumFund: Strategy must be registered to be active");
            require(weight > 0, "QuantumFund: Strategy weight must be positive"); // Assuming weights > 0 for active strategies

            newActiveStrategies[i] = strategyAddr; // Build new active list
            _strategyWeights[strategyAddr] = weight;
            newTotalWeight = newTotalWeight.add(weight);
        }

        _activeStrategies = newActiveStrategies; // Replace the active list
        _totalActiveWeight = newTotalWeight;

        // Optional: require _totalActiveWeight == targetWeight (e.g., 10000)
        // require(_totalActiveWeight == 10000, "QuantumFund: Total active strategy weights must sum to 10000");

        emit ActiveStrategiesUpdated(strategies, weights);
    }

    /**
     * @dev Executes the logic of all currently active strategies.
     * Can be called by owner/manager, or triggered by a keeper bot, or even publicly if gas is handled.
     * The actual strategy execution logic is within the IStrategyModule contracts.
     * This function passes control and potentially data.
     * @param data Per-strategy data payload. Should be `bytes[]` corresponding to _activeStrategies.
     */
    function executeActiveStrategies(bytes[] calldata data) external nonReentrant whenNotPaused {
        require(data.length == _activeStrategies.length, "QuantumFund: Data array must match active strategies count");

        for (uint i = 0; i < _activeStrategies.length; i++) {
            address strategyAddr = _activeStrategies[i];
            IStrategyModule strategy = _strategyModules[strategyAddr];

            // Ensure strategy is still registered and active within its own logic
            if (address(strategy) != address(0) && strategy.isActive()) {
                // Call the strategy module's execute function
                // A try/catch block here could prevent one failing strategy from stopping others
                bool success = strategy.execute(data[i]);
                emit StrategyExecuted(strategyAddr, success);
                 // Optional: Revert if strategy failed critical task?
                 // require(success, string(abi.encodePacked("QuantumFund: Strategy execution failed for ", addressToString(strategyAddr))));
            }
        }
    }

    // --- Fee Management ---

     /**
     * @dev Sets the deposit fee percentage.
     * Accessible by owner/manager (or governance).
     * @param feeBasisPoints The new deposit fee in basis points (e.g., 100 = 1%). Max 10000 (100%).
     */
    function setDepositFee(uint256 feeBasisPoints) external onlyOwner {
        require(feeBasisPoints <= 10000, "QuantumFund: Fee cannot exceed 100%");
        depositFeeBasisPoints = feeBasisPoints;
        emit DepositFeeUpdated(feeBasisPoints);
    }

    /**
     * @dev Sets the withdrawal fee percentage.
     * Accessible by owner/manager (or governance).
     * @param feeBasisPoints The new withdrawal fee in basis points (e.g., 100 = 1%). Max 10000 (100%).
     */
    function setWithdrawalFee(uint256 feeBasisPoints) external onlyOwner {
        require(feeBasisPoints <= 10000, "QuantumFund: Fee cannot exceed 100%");
        withdrawalFeeBasisPoints = feeBasisPoints;
        emit WithdrawalFeeUpdated(feeBasisPoints);
    }

    /**
     * @dev Sets the performance fee rate. Note: Performance fee calculation/collection is complex
     * and not fully implemented in this example, this is a placeholder for the rate setting.
     * Accessible by owner/manager (or governance).
     * @param rate The performance fee rate (interpretation depends on the performance fee logic).
     */
    function setPerformanceFeeRate(uint256 rate) external onlyOwner {
        // Placeholder for setting a performance fee rate parameter
        performanceFeeRate = rate;
        // No specific event as the calculation isn't here. Add one if implementation exists.
    }

     /**
     * @dev Allows the owner/manager to collect accumulated protocol fees.
     * In this simplified example, fees are tracked in QFToken value equivalent.
     * Collecting would involve calculating the equivalent value in underlying assets
     * and transferring them. This requires complex logic (which assets to collect, swapping etc.).
     * For simplicity, this function is a placeholder or could potentially mint QFToken value
     * to a fee receiver address (though that dilutes existing holders, less common).
     * A better approach is to claim a proportional amount of underlying assets or swap to a fee token.
     * For this example, we'll add a very simple mechanism: claim a proportional value of a *single* specified ERC20 asset.
     * @param tokenAddress The ERC-20 token to collect fees in. Must be held by the fund.
     */
    function collectProtocolFees(address tokenAddress) external onlyOwner {
        uint256 feeQFValue = _protocolFees[address(this)]; // Get accumulated fee value in QFToken equivalent

        if (feeQFValue == 0) {
            emit ProtocolFeesCollected(tokenAddress, 0);
            return;
        }

        // Calculate the value of the fee in the specified token
        // feeTokenAmount = (feeQFValue * tokenBalance) / totalFundValue (before fee collection)
        uint256 currentFundValue = getTotalFundValue();
        uint256 tokenBalance = IERC20(tokenAddress).balanceOf(address(this));

        if (currentFundValue == 0 || tokenBalance == 0) {
             // Cannot collect fees in this token if fund value or token balance is zero
             // Fee value remains accrued until it can be collected in a different asset or value recovers
             return;
        }

        uint256 amountToCollect = feeQFValue.mul(tokenBalance).div(currentFundValue);

        if (amountToCollect > 0) {
            // Transfer the collected tokens to the owner/fee recipient
            // Note: This reduces the fund's assets, effectively 'paying out' the fee.
            // The accrued fee amount (`_protocolFees[address(this)]`) should also be reduced.
            IERC20(tokenAddress).transfer(owner(), amountToCollect);

            // Reduce the accrued fee amount based on the value collected
            // valueCollectedUsd_1e18 = (amountToCollect * tokenPriceUsd_1e18) / 10**tokenDecimals
            uint256 tokenPriceUsd = getTokenPriceUsd(tokenAddress);
            uint256 tokenDecimals = IERC20(tokenAddress).decimals();
             uint256 oracleDecimals = uint256(AggregatorV3Interface(_tokenOracles[tokenAddress]).latestRoundData().answeredInRound);
             uint256 normalizedPrice = tokenPriceUsd;
            if (oracleDecimals < 18) {
                 normalizedPrice = normalizedPrice.mul(10**(18 - oracleDecimals));
            } else if (oracleDecimals > 18) {
                 normalizedPrice = normalizedPrice.div(10**(oracleDecimals - 18));
            }
            uint256 valueCollectedUsd_1e18 = amountToCollect.mul(normalizedPrice).div(10**tokenDecimals);

            // Reduce the accrued fee amount by the value collected
            // This is a simplified accounting where fee value is tracked in QFToken equivalent
            // and reduced by the USD value of collected tokens scaled back to QF equivalent.
            // Need to be careful about precision loss and edge cases.
            // A more robust fee system would track fees per asset type.
            uint256 totalShares = totalSupply(); // Shares *before* potential QFToken fee collection, using current supply for scaling
             if (totalShares > 0) {
                uint256 collectedFeeQFValue = valueCollectedUsd_1e18.mul(totalShares).div(currentFundValue); // How much QFValue was collected?
                 _protocolFees[address(this)] = _protocolFees[address(this)].sub(collectedFeeQFValue);
             } else {
                 // If totalShares was 0, this whole fee mechanism is likely in initialization phase.
                 // Assume feeQFValue can be reset if collected.
                 _protocolFees[address(this)] = 0;
             }


            emit ProtocolFeesCollected(tokenAddress, amountToCollect);
        }
    }

     /**
     * @dev Sets the minimum deposit amount for ERC-20 tokens.
     * Accessible by owner/manager (or governance).
     * @param amount The new minimum deposit amount (in the lowest denomination of the deposited token).
     */
    function setMinDepositAmount(uint256 amount) external onlyOwner {
        minDepositAmount = amount;
        emit MinDepositAmountUpdated(amount);
    }


    // --- Governance (Simplified Placeholder) ---
    // These functions represent the *idea* of governance using QFToken balance.
    // A real implementation would involve a separate governance contract, timelocks,
    // snapshot voting, proposal types, execution queues, etc.

     /**
     * @dev Placeholder for initiating a governance proposal.
     * In a real system, this would require QFToken balance and define proposal details.
     */
    function proposeChange(bytes memory proposalData) external {
        // require(balanceOf(msg.sender) > MIN_GOVERNANCE_TOKENS, "QuantumFund: Insufficient governance tokens");
        // ... logic to create and store a proposal ...
        // This is just a concept function for this example.
        revert("QuantumFund: Governance is a placeholder concept in this example");
    }

     /**
     * @dev Placeholder for voting on a governance proposal.
     * In a real system, users vote with locked QFToken balance.
     */
     function voteOnProposal(uint256 proposalId, bool support) external {
         // require(balanceOf(msg.sender) > 0, "QuantumFund: No tokens to vote with");
         // ... logic to record vote based on token balance at a snapshot ...
         // This is just a concept function for this example.
         revert("QuantumFund: Governance is a placeholder concept in this example");
     }

     /**
     * @dev Placeholder for executing a successful governance proposal.
     * In a real system, this would check proposal status and execute predefined actions.
     */
    function executeProposal(uint256 proposalId) external {
        // ... logic to check if proposal passed and execute it ...
         // This is just a concept function for this example.
         revert("QuantumFund: Governance is a placeholder concept in this example");
    }


    // --- Information / View Functions ---

    /**
     * @dev Checks if an ERC-20 token is whitelisted for deposits.
     * @param token The address of the ERC-20 token.
     * @return True if whitelisted, false otherwise.
     */
    function isWhitelistedToken(address token) external view returns (bool) {
        return _whitelistedTokens[token];
    }

    /**
     * @dev Checks if an ERC-721 token contract is whitelisted for deposits.
     * @param nftContract The address of the ERC-721 contract.
     * @return True if whitelisted, false otherwise.
     */
     function isWhitelistedNFT(address nftContract) external view returns (bool) {
         return _whitelistedNFTs[nftContract];
     }

     /**
     * @dev Returns the address of the price oracle registered for a token.
     * @param token The address of the ERC-20 token.
     * @return The oracle address (address(0) if none registered).
     */
    function getOracleAddress(address token) external view returns (address) {
        return address(_tokenOracles[token]);
    }

     /**
     * @dev Returns the simplified valuation factor for a whitelisted NFT collection.
     * @param nftContract The address of the NFT contract.
     * @return The valuation factor (in 1e18 USD equivalent per NFT), 0 if not set.
     */
    function getNFTValuationFactor(address nftContract) external view returns (uint256) {
        return _nftValuationFactors[nftContract];
    }

     /**
     * @dev Returns the current deposit fee percentage.
     */
    function getDepositFee() external view returns (uint256) {
        return depositFeeBasisPoints;
    }

     /**
     * @dev Returns the current withdrawal fee percentage.
     */
    function getWithdrawalFee() external view returns (uint256) {
        return withdrawalFeeBasisPoints;
    }

    /**
     * @dev Returns the current performance fee rate placeholder value.
     */
     function getPerformanceFeeRate() external view returns (uint256) {
         return performanceFeeRate;
     }

    /**
     * @dev Returns information about a registered strategy module.
     * @param strategyAddress The address of the strategy module.
     * @return Whether it's registered, its ID, and description.
     */
    function getStrategyModule(address strategyAddress) external view returns (bool isRegistered, uint256 strategyId, string memory description) {
        IStrategyModule strategy = _strategyModules[strategyAddress];
        if (address(strategy) == address(0)) {
            return (false, 0, "");
        }
        return (true, strategy.strategyId(), strategy.description());
    }

     /**
     * @dev Returns the list of currently active strategy module addresses.
     */
     function getActiveStrategies() external view returns (address[] memory) {
         return _activeStrategies;
     }

     /**
     * @dev Returns the weight for a specific strategy if it is active.
     * @param strategyAddress The address of the strategy.
     * @return The weight, or 0 if not active or registered.
     */
    function getActiveStrategyWeight(address strategyAddress) external view returns (uint256) {
        return _strategyWeights[strategyAddress];
    }

    /**
     * @dev Returns the minimum deposit amount required for ERC-20 tokens.
     */
    function getMinDepositAmount() external view returns (uint256) {
        return minDepositAmount;
    }

    /**
     * @dev Returns the total accrued protocol fees (in QFToken value equivalent).
     */
    function getAccruedProtocolFees() external view returns (uint256) {
        return _protocolFees[address(this)]; // Simplified: using address(this) as key for QFToken value fees
    }

    /**
     * @dev Helper function (simplified) to get a list of ERC-20 tokens held by the contract.
     * NOTE: This is inefficient and assumes we can iterate through *all* whitelisted tokens.
     * A real system would need a dynamic list of *currently held* tokens.
     */
    function getHeldTokens() internal view returns (address[] memory) {
        // This is a placeholder. A proper implementation would need
        // to track which whitelisted tokens have a non-zero balance.
        // For demonstration, let's just return the whitelisted tokens.
        // A more robust way is complex: maybe require deposit/withdraw events
        // to update a dynamic array of held tokens, or rely on off-chain data.
        // We will return a hardcoded small list or iterate a *known* limited set for demo.
        // Let's assume we have a small internal list of *potentially* held tokens for this example.
        // This is a major simplification.
        address[] memory potentiallyHeld = new address[](2); // Example placeholder
        // Replace with logic to get actual held tokens if possible, or manage a list.
        // This requires either iterating *all* potential tokens (gas bomb)
        // or maintaining an internal dynamic list which is complex to update accurately.
        // Let's just list the whitelisted tokens for the *concept* demonstration,
        // acknowledging that many will have zero balance.
        // A better way involves adding/removing from a list on actual transfer events.
        // For the demo, let's *simulate* knowing held tokens by checking balance of whitelisted ones (still potentially gas heavy).
         address[] memory whitelisted = getWhitelistedTokens(); // Get list of whitelisted tokens
         uint256 heldCount = 0;
         for(uint i=0; i < whitelisted.length; i++) {
             if (IERC20(whitelisted[i]).balanceOf(address(this)) > 0) {
                 heldCount++;
             }
         }
         address[] memory actuallyHeld = new address[](heldCount);
         uint256 currentIdx = 0;
          for(uint i=0; i < whitelisted.length; i++) {
             if (IERC20(whitelisted[i]).balanceOf(address(this)) > 0) {
                 actuallyHeld[currentIdx] = whitelisted[i];
                 currentIdx++;
             }
         }
         return actuallyHeld;
    }

     /**
     * @dev Helper function (simplified) to get a list of ERC-721 collections held by the contract.
     * Similar limitations as getHeldTokens apply.
     */
     function getHeldNFTCollections() internal view returns (address[] memory) {
        // Same issue as ERC20s. Cannot easily list held collections.
        // Returning whitelisted ones for demonstration, acknowledging zero balance issue.
         address[] memory whitelisted = getWhitelistedNFTs();
         uint256 heldCount = 0;
         for(uint i=0; i < whitelisted.length; i++) {
             if (IERC721(whitelisted[i]).balanceOf(address(this)) > 0) {
                 heldCount++;
             }
         }
         address[] memory actuallyHeld = new address[](heldCount);
         uint256 currentIdx = 0;
          for(uint i=0; i < whitelisted.length; i++) {
             if (IERC721(whitelisted[i]).balanceOf(address(this)) > 0) {
                 actuallyHeld[currentIdx] = whitelisted[i];
                 currentIdx++;
             }
         }
         return actuallyHeld;
     }

      /**
     * @dev Returns a list of all whitelisted ERC-20 token addresses.
     * Note: Iterating mappings is not standard; this requires maintaining a separate list, which adds complexity.
     * For simplicity, this function would require an internal array of whitelisted tokens to be maintained.
     * Adding this complexity now for the example.
     */
    address[] private _whitelistedTokenList;
    mapping(address => uint256) private _whitelistedTokenIndex; // To manage removal efficiently

     /**
     * @dev Returns a list of all whitelisted ERC-721 collection addresses.
     * Similar to ERC-20s, requires maintaining a separate list.
     */
    address[] private _whitelistedNFTList;
     mapping(address => uint256) private _whitelistedNFTIndex; // To manage removal efficiently


     // --- Update add/remove functions to manage these lists ---
     // (Adding/removing from middle of array is O(n), requires swapping last element)

     function _addWhitelistedTokenToList(address token) internal {
         if(!_whitelistedTokens[token]) {
              _whitelistedTokens[token] = true;
              _whitelistedTokenIndex[token] = _whitelistedTokenList.length;
              _whitelistedTokenList.push(token);
               emit WhitelistedTokenAdded(token);
         }
     }
     function _removeWhitelistedTokenFromList(address token) internal {
         if(_whitelistedTokens[token]) {
             _whitelistedTokens[token] = false;
             uint256 index = _whitelistedTokenIndex[token];
             uint256 lastIndex = _whitelistedTokenList.length - 1;
             if (index != lastIndex) {
                 address lastToken = _whitelistedTokenList[lastIndex];
                 _whitelistedTokenList[index] = lastToken;
                 _whitelistedTokenIndex[lastToken] = index;
             }
             _whitelistedTokenList.pop();
             delete _whitelistedTokenIndex[token]; // Clean up index
             emit WhitelistedTokenRemoved(token);
         }
     }

     // Overload add/remove for lists
     function addWhitelistedToken(address token, address oracleAddress) public onlyOwner {
         require(token != address(0), "QuantumFund: Zero address not allowed for token");
         try IERC20(token).decimals() returns (uint8) {} catch { revert("QuantumFund: Address is not a valid ERC20 token"); }
         _addWhitelistedTokenToList(token); // Use internal list management
         if (oracleAddress != address(0)) {
              _tokenOracles[token] = AggregatorV3Interface(oracleAddress);
              emit OracleRegistered(token, oracleAddress);
         }
     }

     function removeWhitelistedToken(address token) public onlyOwner {
          require(_whitelistedTokens[token], "QuantumFund: Token is not whitelisted");
          _removeWhitelistedTokenFromList(token); // Use internal list management
     }

      function _addWhitelistedNFTToList(address nftContract) internal {
          if(!_whitelistedNFTs[nftContract]) {
               _whitelistedNFTs[nftContract] = true;
               _whitelistedNFTIndex[nftContract] = _whitelistedNFTList.length;
               _whitelistedNFTList.push(nftContract);
               emit WhitelistedNFTAdded(nftContract);
          }
      }

      function _removeWhitelistedNFTFromList(address nftContract) internal {
          if(_whitelistedNFTs[nftContract]) {
              _whitelistedNFTs[nftContract] = false;
              uint256 index = _whitelistedNFTIndex[nftContract];
              uint256 lastIndex = _whitelistedNFTList.length - 1;
              if (index != lastIndex) {
                  address lastNFT = _whitelistedNFTList[lastIndex];
                  _whitelistedNFTList[index] = lastNFT;
                  _whitelistedNFTIndex[lastNFT] = index;
              }
              _whitelistedNFTList.pop();
              delete _whitelistedNFTIndex[nftContract]; // Clean up index
              emit WhitelistedNFTRemoved(nftContract);
          }
      }

     // Overload add/remove for lists
      function addWhitelistedNFT(address nftContract) public onlyOwner {
         require(nftContract != address(0), "QuantumFund: Zero address not allowed for NFT contract");
         try IERC721(nftContract).supportsInterface(0x80ac58cd) returns (bool isERC721) { require(isERC721, "QuantumFund: Address is not a valid ERC721 contract"); } catch { revert("QuantumFund: Address is not a valid ERC721 contract"); }
         _addWhitelistedNFTToList(nftContract); // Use internal list management
      }

      function removeWhitelistedNFT(address nftContract) public onlyOwner {
           require(_whitelistedNFTs[nftContract], "QuantumFund: NFT contract is not whitelisted");
           _removeWhitelistedNFTFromList(nftContract); // Use internal list management
      }


     /**
      * @dev Returns a list of all whitelisted ERC-20 token addresses.
      */
     function getWhitelistedTokens() public view returns (address[] memory) {
         return _whitelistedTokenList;
     }

      /**
      * @dev Returns a list of all whitelisted ERC-721 collection addresses.
      */
      function getWhitelistedNFTs() public view returns (address[] memory) {
          return _whitelistedNFTList;
      }


    // --- Emergency Controls ---

    /**
     * @dev Pauses the contract, preventing deposits, withdrawals, and strategy execution.
     * Accessible by owner/manager.
     */
    function pause() external onlyOwner {
        _pause();
    }

     /**
     * @dev Unpauses the contract.
     * Accessible by owner/manager.
     */
     function unpause() external onlyOwner {
         _unpause();
     }


    // --- Owner/Manager Functions (Initial Setup & Rescue) ---

    /**
     * @dev Allows the owner/manager to transfer any ERC-20 tokens out of the contract.
     * EMERGENCY USE ONLY. Can be used to rescue tokens sent accidentally or manage specific strategy outputs.
     * Should be governed in a real system.
     * @param tokenAddress The address of the token to transfer.
     * @param to The recipient address.
     * @param amount The amount to transfer.
     */
    function transferAnyERC20Tokens(address tokenAddress, address to, uint256 amount) external onlyOwner {
        require(tokenAddress != address(this), "QuantumFund: Cannot transfer fund shares this way");
        IERC20(tokenAddress).transfer(to, amount);
        // NOTE: This function bypasses fund logic and fee structures. Use with extreme caution.
    }

     /**
     * @dev Allows the owner/manager to transfer any ERC-721 tokens out of the contract.
     * EMERGENCY USE ONLY. Can be used to rescue NFTs or manage specific strategy outputs.
     * Should be governed in a real system.
     * @param nftContract The address of the NFT contract.
     * @param to The recipient address.
     * @param tokenId The ID of the NFT to transfer.
     */
     function transferAnyERC721Tokens(address nftContract, address to, uint256 tokenId) external onlyOwner {
        require(IERC721(nftContract).ownerOf(tokenId) == address(this), "QuantumFund: Contract does not own this NFT");
         IERC721(nftContract).transferFrom(address(this), to, tokenId);
        // NOTE: This function bypasses fund logic and fee structures. Use with extreme caution.
     }


     // Helper function for converting address to string (utility, adds gas cost)
     // Used for better error messages if needed.
    // function addressToString(address _address) internal pure returns(string memory) {
    //     bytes32 _bytes = bytes32(uint256(_address));
    //     bytes memory __bytes = new bytes(40);
    //     for (uint i = 0; i < 20; i++) {
    //         __bytes[i*2] = _byteToChar(uint8(_bytes[i] >> 4));
    //         __bytes[i*2+1] = _byteToChar(uint8(_bytes[i] & 0x0f));
    //     }
    //     return string(__bytes);
    // }
    // function _byteToChar(uint8 _byte) internal pure returns(bytes1) {
    //     if (_byte < 10) return bytes1(uint8(48 + _byte));
    //     else return bytes1(uint8(87 + _byte));
    // }

}
```