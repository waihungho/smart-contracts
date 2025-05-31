Okay, let's design a sophisticated smart contract that integrates several advanced DeFi concepts in a novel way, focusing on dynamic interactions and combining different asset classes.

Here's the concept: **DeFiPulseFusion**

This contract acts as a core fusion pool where users can stake various *approved* ERC-20 tokens and potentially *approved* ERC-721 tokens (NFTs) to collectively generate yield. This yield isn't just simple token rewards; it's derived from potential future integrations (simulated here conceptually) with lending protocols, trading fees from an internal AMM swap pool, and potentially boosted by staked NFTs. Users mint a synthetic yield-bearing token, `FUSION`, based on their staked value, which can be used for governance or trading in the internal AMM.

**Key Advanced Concepts:**

1.  **Multi-Asset Staking:** Staking diverse asset types (ERC-20s, ERC-721s) in a single protocol.
2.  **Dynamic Yield Calculation:** Yield isn't a fixed rate but accrues based on factors like total staked value, AMM trading volume/fees, and potentially external data (simulated via oracle interaction).
3.  **Synthetic Yield Token (`FUSION`):** A token representing a claim on the pool's underlying value and accrued yield, minted based on staked value.
4.  **Internal AMM:** A basic constant-product market maker pool within the contract (e.g., FUSION <> WETH) where trading fees contribute to the overall pool yield.
5.  **TVL-Aware Dynamic Minting/Burn Ratio:** The rate at which FUSION is minted/burned relative to the underlying staked value adjusts based on the Total Value Locked (TVL) in the protocol, incentivizing early participation or managing supply.
6.  **NFT Utility Integration:** Staked NFTs grant specific, configurable benefits (e.g., a boost to yield calculation, reduction in AMM swap fees, increased governance power).
7.  **Governance Module:** A simplified governance system allowing FUSION token holders (or stakers) to vote on key protocol parameters (e.g., supported assets, fees, dynamic ratio parameters).
8.  **Oracle Integration:** Using oracles (Chainlink simulated) to value staked ERC-20 assets for accurate stake value calculation and TVL determination.
9.  **Flash Minting:** Allowing users to flash mint `FUSION` tokens (borrow and repay within the same transaction block) for arbitrage opportunities on the internal AMM or external platforms, generating a fee for the pool.
10. **Pausable:** Standard security feature for emergencies.

**Outline and Function Summary:**

**Contract Name:** `DeFiPulseFusion`

**Core Concept:** A multi-asset staking and yield-fusion protocol producing a synthetic yield-bearing token (`FUSION`) with internal AMM and governance.

**Key Features:**
*   Stake diverse ERC-20s and ERC-721s.
*   Dynamic yield derived from pooled assets and AMM fees.
*   Mint/Burn `FUSION` synthetic token based on stake value and yield.
*   Internal Constant Product AMM (FUSION <> WETH).
*   Dynamic FUSION minting/burning ratio based on TVL.
*   Configurable NFT staking benefits.
*   Token-weighted Governance for parameter control.
*   Oracle integration for asset valuation.
*   ERC-3156 compliant Flash Minting for `FUSION`.
*   Pausable for security.

**Source Code Outline:**

1.  **Pragma & Imports:** Specify Solidity version and import necessary interfaces/libraries (ERC20, ERC721, Oracle, Flash Loan interfaces, Pausable).
2.  **Error Definitions:** Custom error types for clarity and gas efficiency.
3.  **Events:** Declare events for key actions (Staking, Unstaking, Minting, Burning, Swaps, Governance changes, Pausing, Flash Mint).
4.  **Interfaces:** Define interfaces for external contracts (IERC20, IERC721, IFlashLoanRecipient, AggregatorV3Interface).
5.  **Structs:** Define structs for configuration data (Supported ERC20/ERC721, Governance Proposals).
6.  **State Variables:** Declare all state variables (addresses of tokens, oracles, governance, mappings for user data, pool data, governance state, parameters).
7.  **Modifiers:** Define custom modifiers (`onlyGovernance`, `whenNotPaused`, `whenPaused`).
8.  **Constructor:** Initialize key contract addresses and initial parameters.
9.  **Internal Helper Functions:** Private/internal functions for core logic (e.g., `_getAssetValue`, `_calculateYield`, `_updateAccountStakeValue`, `_getDynamicFusionRatio`, `_swap`, `_updateTotalStakedValue`).
10. **Admin & Setup Functions:** Functions for initial setup or emergency admin control (often restricted or handed to governance).
11. **Staking & Unstaking Functions:** Logic for depositing and withdrawing ERC-20s and ERC-721s.
12. **FUSION Management Functions:** Logic for minting and burning `FUSION` tokens.
13. **Yield & Value Query Functions:** Functions to check user's stake value, pending yield, and total protocol TVL.
14. **Internal AMM Functions:** Functions for swapping tokens and adding/removing liquidity.
15. **Governance Functions:** Logic for proposing, voting on, and executing parameter changes.
16. **Parameter Setting Functions:** Functions to change protocol parameters (callable only by governance execution).
17. **Oracle Interaction Functions:** Functions to fetch data from oracles.
18. **Pause Functionality:** Inherited from Pausable, with `pause` and `unpause` functions.
19. **Flash Mint Implementation:** Implementation of `IERC3156FlashLender` functions (`maxFlashLoan`, `flashFee`, `flashLoan`).
20. **Emergency Functions:** Functions for governance/admin to recover tokens in specific emergencies.
21. **Query Functions:** Public functions to read various state variables and configurations.

**Function Summary (Focus on Public/External, aiming for 20+):**

1.  `constructor(...)`: Initializes the contract with essential addresses (FUSION token, WETH, initial oracle, governance).
2.  `setGovernanceAddress(address _governance)`: Admin function to set/change the governance contract address.
3.  `addSupportedERC20(address _token, address _oracle, uint256 _minStakeAmount)`: Governance function to add a new supported ERC-20 token and its oracle feed.
4.  `removeSupportedERC20(address _token)`: Governance function to remove a supported ERC-20 token (requires users to unstake first).
5.  `addSupportedERC721(address _collection, uint256 _utilityBoostFactor)`: Governance function to add a supported ERC-721 collection and configure its utility boost.
6.  `removeSupportedERC721(address _collection)`: Governance function to remove a supported ERC-721 collection.
7.  `stakeERC20(address _token, uint256 _amount)`: Allows a user to stake an approved amount of a supported ERC-20 token.
8.  `unstakeERC20(address _token, uint256 _amount)`: Allows a user to unstake a specific amount of their staked ERC-20 token.
9.  `stakeERC721(address _collection, uint256 _tokenId)`: Allows a user to stake a specific approved NFT from a supported collection.
10. `unstakeERC721(address _collection, uint256 _tokenId)`: Allows a user to unstake a specific staked NFT.
11. `mintFusion()`: Calculates the user's accrued stake value increase and pending yield, mints corresponding `FUSION` tokens based on the dynamic ratio, and updates the user's state.
12. `burnFusion(uint256 _amount)`: Allows a user to burn `FUSION` tokens to unlock a proportional value of their staked assets (including accrued yield), which can then be unstaked.
13. `getPendingYield(address _user)`: Queries the calculated but unclaimed yield for a specific user based on their staked assets and accrued time.
14. `getAccountStakeValue(address _user)`: Queries the total calculated value (in a base unit like USD or WETH, based on oracles) of a user's currently staked assets.
15. `getTotalStakedValue()`: Queries the total calculated value of *all* staked assets in the protocol (the TVL).
16. `swapFusion(uint256 _amount, address _tokenOut, uint256 _minAmountOut)`: Performs a token swap on the internal AMM (currently FUSION to WETH or WETH to FUSION), incorporating the swap fee.
17. `addLiquidity(uint256 _amountFusion, uint256 _amountWETH)`: Allows users to add liquidity to the internal FUSION <> WETH AMM pool.
18. `removeLiquidity(uint256 _lpTokens)`: Allows users to remove liquidity from the internal AMM pool.
19. `proposeParameterChange(bytes32 _paramName, uint256 _newValue, string memory _description)`: Allows a user with sufficient governance power (e.g., staked assets) to propose a change to a protocol parameter.
20. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows users with governance power to vote on an active proposal.
21. `executeProposal(uint256 _proposalId)`: Executes a proposal if it has passed the voting period, met quorum, and achieved majority support.
22. `pause()`: Governance/Admin function to pause core protocol actions (staking, unstaking, minting, burning, swaps).
23. `unpause()`: Governance/Admin function to unpause the protocol.
24. `flashLoan(address receiver, uint256 amount, bytes calldata data)`: Implements the ERC-3156 flash loan function for `FUSION` tokens. Allows borrowing `amount` FUSION if the `receiver` contract promises to repay `amount + fee` within the same transaction via the `onFlashLoan` callback.
25. `emergencyWithdraw(address _token, uint256 _amount)`: Governance/Admin function to withdraw stuck tokens in case of emergency (should be used cautiously).
26. `getFusionMintRatio()`: Queries the current dynamic ratio used for minting FUSION based on TVL.
27. `getSwapFee()`: Queries the current fee percentage applied to internal AMM swaps.
28. `getSupportedERC20Config(address _token)`: Queries the configuration details for a specific supported ERC-20 token.
29. `getSupportedERC721Config(address _collection)`: Queries the configuration details for a specific supported ERC-721 collection.
30. `getAMMPoolReserves()`: Queries the current reserves of FUSION and WETH in the internal AMM pool.

This list exceeds 20 and covers the described advanced concepts. The implementation below will be a conceptual framework, as full integration with external protocols (like live lending markets) and robust, gas-optimized yield calculation is complex and beyond a single example contract.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashRecipient.sol"; // Interface for the borrower

// Mock/Example Oracle Interface (Chainlink Aggregator V3)
interface AggregatorV3Interface {
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

// --- Custom Errors ---
error DeFiPulseFusion__UnsupportedToken();
error DeFiPulseFusion__InsufficientStake();
error DeFiPulseFusion__AmountTooLow(uint256 required);
error DeFiPulseFusion__InvalidTokenId();
error DeFiPulseFusion__NotStaked();
error DeFiPulseFusion__MintAmountZero();
error DeFiPulseFusion__BurnAmountTooHigh();
error DeFiPulseFusion__AMMPoolEmpty();
error DeFiPulseFusion__InsufficientLiquidity();
error DeFiPulseFusion__InsufficientOutputAmount();
error DeFiPulseFusion__FlashLoanTooLarge();
error DeFiPulseFusion__FlashLoanRepaymentFailed();
error DeFiPulseFusion__FlashLoanCallbackFailed();
error DeFiPulseFusion__InvalidGovernanceProposal();
error DeFiPulseFusion__ProposalAlreadyExists();
error DeFiPulseFusion__ProposalExpired();
error DeFiPulseFusion__VotingPeriodNotEnded();
error DeFiPulseFusion__AlreadyVoted();
error DeFiPulseFusion__ProposalNotPassed();
error DeFiPulseFusion__ExecutionFailed();
error DeFiPulseFusion__Unauthorized();
error DeFiPulseFusion__TransferFailed();


// --- Events ---
event GovernanceAddressSet(address indexed oldGov, address indexed newGov);
event SupportedERC20Added(address indexed token, address indexed oracle, uint256 minStakeAmount);
event SupportedERC20Removed(address indexed token);
event SupportedERC721Added(address indexed collection, uint256 utilityBoostFactor);
event SupportedERC721Removed(address indexed collection);
event ERC20Staked(address indexed user, address indexed token, uint256 amount, uint256 stakeValue);
event ERC20Unstaked(address indexed user, address indexed token, uint256 amount);
event ERC721Staked(address indexed user, address indexed collection, uint256 tokenId);
event ERC721Unstaked(address indexed user, address indexed collection, uint256 tokenId);
event FusionMinted(address indexed user, uint256 amount, uint256 baseStakeValue, uint256 yieldValue);
event FusionBurned(address indexed user, uint256 amount, uint256 unlockedStakeValue);
event Swap(address indexed user, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);
event LiquidityAdded(address indexed provider, uint256 amountFusion, uint256 amountWETH, uint256 lpTokensMinted);
event LiquidityRemoved(address indexed provider, uint256 lpTokensBurned, uint256 amountFusion, uint256 amountWETH);
event ParameterChangeProposed(uint256 indexed proposalId, bytes32 paramName, uint256 newValue, string description);
event VoteCast(address indexed voter, uint256 indexed proposalId, bool support);
event ProposalExecuted(uint256 indexed proposalId);
event FlashLoan(address indexed receiver, uint256 amount, uint256 fee);


contract DeFiPulseFusion is Context, Pausable, ReentrancyGuard, IERC721Receiver, IERC3156FlashLender {

    // --- State Variables & Structs ---

    address public immutable FUSION; // The address of the FUSION ERC20 token
    address public immutable WETH;   // The address of wrapped Ether, used in AMM

    address public governance; // Address of the governance contract or EOA

    struct SupportedERC20Config {
        address oracle;         // Oracle feed for valuing the token
        uint256 minStakeAmount; // Minimum amount required to stake this token
        bool isSupported;       // Flag to check if token is supported
    }
    mapping(address => SupportedERC20Config) public supportedERC20s;

    struct SupportedERC721Config {
        uint256 utilityBoostFactor; // Factor multiplying yield/governance power etc. (e.g., 100 = 1x, 105 = 1.05x)
        bool isSupported;            // Flag to check if collection is supported
    }
    mapping(address => SupportedERC721Config) public supportedERC721s;

    // User Staking Data:
    // Tracks the amount of each ERC20 token staked by a user
    mapping(address => mapping(address => uint256)) public userERC20Stakes;
    // Tracks the staked ERC721 token IDs for each user and collection
    mapping(address => mapping(address => uint256[])) private userERC721Stakes; // Use private and provide getter

    // Protocol Total Staked Data:
    mapping(address => uint256) public totalStakedERC20; // Total amount of each ERC20 staked
    mapping(address => uint256) public totalStakedERC721Count; // Total count of each ERC721 collection staked

    uint256 private _totalStakedValue; // Total value of all staked assets in base units (e.g., USD cents or WETH wei)

    // Yield Calculation State:
    // This is a simplified yield model. A real protocol might use a 'reward per token' or 'per share' model.
    // We track the last time a user's stake for a given asset was updated.
    mapping(address => mapping(address => uint256)) private userLastStakeUpdateTime;
    mapping(address => mapping(address => uint256)) private userAccruedStakeValue; // Accumulated time-weighted stake value

    uint256 public yieldRatePerSecond; // Global yield rate (e.g., scaled percentage per second) - simplified
    uint256 public ammFeeRate;         // AMM swap fee rate (e.g., 9970 for 0.3%)
    uint256 private totalAMMFeesCollected; // Total AMM fees collected (added to pool value)

    // AMM Pool State (FUSION <> WETH)
    uint256 public fusionReserves;
    uint256 public wethReserves;
    uint256 public constant MINIMUM_LIQUIDITY = 1000; // Prevent liquidity removal to zero

    // FUSION Minting/Burning Parameters:
    // Dynamic ratio based on TVL: base + slope * TVL (or similar function)
    // We'll use a simple linear model: ratio = max_ratio - (TVL / tvl_scale_factor)
    uint256 public fusionMaxMintRatio; // Maximum FUSION per unit staked value (scaled)
    uint256 public fusionTVLScaleFactor; // Denominator for scaling TVL in ratio calculation

    // Governance State:
    uint256 public nextProposalId;
    uint256 public governanceVotingPeriod; // In seconds
    uint256 public governanceQuorumThreshold; // Percentage of total governance power (e.g., staked value or FUSION supply)
    uint256 public governanceMajorityThreshold; // Percentage for majority

    struct Proposal {
        bytes32 paramName;       // Identifier for the parameter being changed
        uint256 newValue;        // The proposed new value
        string description;      // Description of the proposal
        uint256 startTime;       // Timestamp when voting started
        uint256 votesFor;        // Total governance power voted 'For'
        uint256 votesAgainst;    // Total governance power voted 'Against'
        mapping(address => bool) hasVoted; // Keep track of voters
        bool executed;           // Whether the proposal has been executed
    }
    mapping(uint256 => Proposal) public proposals;

    // --- Constructor ---

    constructor(
        address _fusionTokenAddress,
        address _wethTokenAddress,
        address _initialGovernance,
        uint256 _initialYieldRatePerSecond,
        uint256 _initialAmmFeeRate, // e.g., 9970 for 0.3% fee
        uint256 _initialMaxMintRatio, // e.g., 1e18 for 1:1 base ratio (scaled)
        uint256 _initialTvlScaleFactor,
        uint256 _governanceVotingPeriod,
        uint256 _governanceQuorumThreshold,
        uint256 _governanceMajorityThreshold
    ) Pausable(0) { // Pause starts disabled
        FUSION = _fusionTokenAddress;
        WETH = _wethTokenAddress;
        governance = _initialGovernance;
        yieldRatePerSecond = _initialYieldRatePerSecond;
        ammFeeRate = _initialAmmFeeRate;
        fusionMaxMintRatio = _initialMaxMintRatio;
        fusionTVLScaleFactor = _initialTvlScaleFactor;
        governanceVotingPeriod = _governanceVotingPeriod;
        governanceQuorumThreshold = _governanceQuorumThreshold;
        governanceMajorityThreshold = _governanceMajorityThreshold;
        nextProposalId = 1;

        // Approve WETH and FUSION for spending by the contract itself for swaps
        // This assumes WETH is an ERC20 that needs allowance for transfers
        // Or, more typically, we'll rely on users approving *this* contract
        // to spend *their* WETH/FUSION when they interact with the AMM functions.
        // So, no need for allowance calls here for the contract's own balance.
    }

    // --- Modifiers ---

    modifier onlyGovernance() {
        if (_msgSender() != governance) {
            revert DeFiPulseFusion__Unauthorized();
        }
        _;
    }

    // --- Internal Helper Functions ---

    // Helper to get the value of a specific ERC20 asset in a base unit (e.g., USD cents)
    // Uses the configured oracle. Returns 0 if unsupported or oracle data is stale/invalid.
    function _getAssetValue(address _token, uint256 _amount) internal view returns (uint256 value) {
        SupportedERC20Config storage config = supportedERC20s[_token];
        if (!config.isSupported || config.oracle == address(0)) {
            return 0; // Unsupported token or missing oracle
        }
        AggregatorV3Interface priceFeed = AggregatorV3Interface(config.oracle);
        (, int256 price, , uint256 updatedAt, ) = priceFeed.latestRoundData();

        // Check if price is valid and recent (e.g., within the last hour)
        if (price <= 0 || block.timestamp - updatedAt > 3600) { // Example check: price > 0 and updated within 1 hour
            return 0; // Stale or invalid price data
        }

        // Assume oracle price feed provides price in USD * 1e8 (common Chainlink format)
        // Assume token uses 1e18 decimals
        // Value = (amount * price) / (10^token_decimals * 10^oracle_decimals)
        // Simplified: Value = (amount * price) / (1e18 * 1e8) = (amount * price) / 1e26
        // Need to handle token decimals properly in a real scenario.
        // Let's simplify for this example and assume 1e18 for both token and oracle scaling for calculation ease.
        // Value in base units (e.g., scaled USD): (amount * uint256(price)) / 1e18;

        // Proper scaling example:
        // int256 priceAnswer = priceFeed.latestAnswer(); // This is price * 10^decimals
        // uint80 decimals = priceFeed.decimals(); // Decimals of the price feed
        // uint256 assetDecimals = 18; // Assume ERC20 standard decimals or query token

        // Value = (_amount * uint256(priceAnswer) * (10**(18 - assetDecimals))) / (10**decimals)
        // Return value scaled to 1e18 for consistency
        // Let's use a simplified scaling for the example where price * 1e8 and token * 1e18
        // Value in arbitrary base units (scaled): (_amount * uint256(price)) / 1e8; // Simpler but needs matching oracle scale

        // Using the common Chainlink structure: Price is Answer * 10^Decimals. Token amount is Amount * 10^TokenDecimals.
        // Value = (Amount * Price * 10^TokenDecimals) / 10^TokenDecimals = Amount * Price
        // This seems too simple. Let's assume oracle price is relative to a base unit (e.g., USD) scaled,
        // and we need to convert the token amount to that base unit scale.
        // Value in BaseUnit_Scaled = (_amount * price_scaled) / 10^TokenDecimals * 10^(BaseUnit_Decimals)
        // Let's assume price is price * 1e8, token is amount * 1e18. We want value in USD cents * 1e18 scale.
        // Value = (_amount * uint256(price) * 1e18) / (1e18 * 1e8) = (_amount * uint256(price)) / 1e8
        // Let's use this last simplified formula for example value calculation, assuming price is price * 1e8.
        value = (_amount * uint256(price)) / (10**8); // Value in a base unit scaled by 1e18 (assuming price is 10^8 scaled)
        // This assumes the price feed gives price in BASE_UNIT / TOKEN.
        // Value in BASE_UNIT = amount_of_token * price_of_token_in_BASE_UNIT
        // Amount_of_token = _amount / 10^token_decimals
        // price_of_token_in_BASE_UNIT = oracle_answer / 10^oracle_decimals
        // Value_in_BASE_UNIT = (_amount / 10^18) * (price / 10^8) = (_amount * price) / 10^26
        // To get Value_in_BASE_UNIT_Scaled_by_1e18 = ((_amount * price) / 10^26) * 10^18 = (_amount * price) / 10^8
         return (_amount * uint256(price)) / (10**8); // Value scaled to 1e18
    }

    // Helper to calculate the value added by a staked NFT
    // Simplified: adds a fixed value boost multiplied by the collection's utility factor.
    function _getNFTValueBoost(address _collection) internal view returns (uint256 valueBoost) {
         SupportedERC721Config storage config = supportedERC721s[_collection];
         if (!config.isSupported) {
             return 0;
         }
         // Example: base boost value (scaled) multiplied by utility factor
         // Assume 100 = 1x boost, 105 = 1.05x boost
         // Boost value = (BaseBoostValue * utilityBoostFactor) / 100
         uint256 baseNFTBoostValue = 1e18; // Example base boost value (scaled to 1e18 base units)
         valueBoost = (baseNFTBoostValue * config.utilityBoostFactor) / 100;
         return valueBoost;
    }

    // Internal function to update a user's accumulated stake value for yield calculation
    function _updateAccountStakeValue(address _user, address _token, uint256 _currentAmount, bool isERC20) internal {
        uint256 currentTime = block.timestamp;
        uint256 lastUpdateTime = userLastStakeUpdateTime[_user][_token];
        uint256 accumulated = userAccruedStakeValue[_user][_token];

        if (lastUpdateTime > 0 && currentTime > lastUpdateTime) {
            uint256 timeElapsed = currentTime - lastUpdateTime;
            uint256 currentStakeValue;
            if (isERC20) {
                 currentStakeValue = _getAssetValue(_token, _currentAmount);
            } else { // Assuming _token here represents the collection address for NFTs
                 uint256 nftCount = getUserERC721Stakes(_user, _token).length;
                 currentStakeValue = _getNFTValueBoost(_token) * nftCount; // Value contribution from NFTs
            }

            // Accrue stake value: value * time elapsed
            // This accumulated value is *not* the yield, but the basis for calculating yield
            // A real protocol might track (value * time_elapsed * yield_rate) here directly
            // Or use a yield-per-share model.
            // Simplified: accumulate (stake_value * time) / 1 second
            accumulated += (currentStakeValue * timeElapsed); // Needs careful scaling based on desired yield rate unit

            userAccruedStakeValue[_user][_token] = accumulated;
        }
        userLastStakeUpdateTime[_user][_token] = currentTime;
    }

    // Calculate the user's pending yield based on accrued stake value
    // Simplified model: yield = total accumulated stake value * global yield rate
    function _calculatePendingYield(address _user) internal view returns (uint256 yieldValue) {
        uint256 totalAccumulatedValue = 0;
        // Iterate through supported ERC20s
        for (address token : _getSupportedERC20s()) {
             totalAccumulatedValue += userAccruedStakeValue[_user][token];
             // Add value accrued since last update for current amount
             uint256 currentAmount = userERC20Stakes[_user][token];
             uint256 lastUpdateTime = userLastStakeUpdateTime[_user][token];
             if (currentAmount > 0 && block.timestamp > lastUpdateTime) {
                 uint256 timeElapsed = block.timestamp - lastUpdateTime;
                 uint256 currentStakeValue = _getAssetValue(token, currentAmount);
                 totalAccumulatedValue += (currentStakeValue * timeElapsed);
             }
        }
        // Iterate through supported ERC721s
        for (address collection : _getSupportedERC721Collections()) {
             totalAccumulatedValue += userAccruedStakeValue[_user][collection];
              uint256 nftCount = getUserERC721Stakes(_user, collection).length;
              uint256 lastUpdateTime = userLastStakeUpdateTime[_user][collection];
              if (nftCount > 0 && block.timestamp > lastUpdateTime) {
                  uint256 timeElapsed = block.timestamp - lastUpdateTime;
                  uint256 currentStakeValue = _getNFTValueBoost(collection) * nftCount;
                  totalAccumulatedValue += (currentStakeValue * timeElapsed);
              }
        }

        // Convert accumulated value (value * time) to yield
        // Example: totalAccumulatedValue is sum of (value_i * time_i)
        // Yield is (totalAccumulatedValue * yieldRatePerSecond) / (1e18 * 1 second) assuming yieldRatePerSecond is scaled 1e18
        yieldValue = (totalAccumulatedValue * yieldRatePerSecond) / (1e18); // Assuming yieldRatePerSecond is % scaled by 1e18

        // Add user's share of total AMM fees collected since last yield claim/mint/burn
        // This requires tracking per-user claimed fees, adding complexity.
        // Simplified: AMM fees implicitly increase the pool's value, which impacts the BURN ratio,
        // but aren't claimed as a separate yield token here.
        // Or, even simpler, AMM fees are added to totalStakedValue (conceptually) increasing the yield basis.
        // Let's assume AMM fees increase the total pool value which increases the effective burn ratio.
        // So pending yield is only from staking over time.

        return yieldValue;
    }


    // Helper to get the current total value locked in the pool (TVL)
    function _getTVL() internal view returns (uint256) {
        // This calculation needs to iterate through ALL staked ERC20s and NFTs
        // and sum their current value based on oracles and NFT boost.
        // For simplicity and gas efficiency, we'll use the cached _totalStakedValue
        // and update it during stake/unstake operations based on oracle prices *at that time*.
        // A more accurate TVL would re-calculate using current oracle prices.
        // Let's use the cached value for performance, acknowledging it's a snapshot.
        return _totalStakedValue;
    }

    // Helper to calculate the dynamic FUSION mint/burn ratio
    // Ratio = max_ratio - (TVL / tvl_scale_factor)
    // Ensure ratio doesn't go below a minimum
    function _getDynamicFusionRatio() internal view returns (uint256) {
        uint256 currentTVL = _getTVL();
        uint256 minRatio = 1e17; // Example Minimum ratio (0.1 scaled 1e18)

        if (currentTVL == 0 || fusionTVLScaleFactor == 0) {
            return fusionMaxMintRatio; // Or some base ratio
        }

        uint256 tvlFactor = currentTVL / fusionTVLScaleFactor; // Needs careful scaling
        // Assume fusionMaxMintRatio and fusionTVLScaleFactor are scaled such that the result is meaningful
        // Example: max ratio = 1e18, tvl_scale_factor = 1e22 (means every 1e22 TVL reduces ratio by 1)
        // ratio = 1e18 - (TVL / 1e22)
        uint256 dynamicRatio = fusionMaxMintRatio;
        if (tvlFactor < dynamicRatio) { // Prevent underflow
             dynamicRatio -= tvlFactor;
        } else {
            dynamicRatio = minRatio; // Cap at minimum ratio
        }

        return dynamicRatio > minRatio ? dynamicRatio : minRatio;
    }

    // Internal swap function for the AMM
    // Based on x * y = k
    function _swap(address _tokenIn, address _tokenOut, uint256 _amountIn) internal nonReentrant returns (uint256 amountOut) {
        if (fusionReserves == 0 || wethReserves == 0) {
            revert DeFiPulseFusion__AMMPoolEmpty();
        }

        uint256 reserveIn;
        uint256 reserveOut;

        if (_tokenIn == FUSION && _tokenOut == WETH) {
            reserveIn = fusionReserves;
            reserveOut = wethReserves;
        } else if (_tokenIn == WETH && _tokenOut == FUSION) {
            reserveIn = wethReserves;
            reserveOut = fusionReserves;
        } else {
            revert DeFiPulseFusion__UnsupportedToken(); // AMM only supports FUSION <> WETH
        }

        // Amount including fee (fee is taken from amountIn before calculation)
        // amountInWithFee = amountIn * ammFeeRate / 10000 (e.g. 9970 / 10000 = 0.997)
        uint256 amountInAfterFee = (_amountIn * ammFeeRate) / 10000;

        // Calculate amountOut using constant product formula
        // (reserveIn + amountInAfterFee) * (reserveOut - amountOut) = reserveIn * reserveOut
        // reserveOut - amountOut = (reserveIn * reserveOut) / (reserveIn + amountInAfterFee)
        // amountOut = reserveOut - (reserveIn * reserveOut) / (reserveIn + amountInAfterFee)
        // amountOut = reserveOut * (1 - reserveIn / (reserveIn + amountInAfterFee))
        // amountOut = reserveOut * (reserveIn + amountInAfterFee - reserveIn) / (reserveIn + amountInAfterFee)
        // amountOut = reserveOut * amountInAfterFee / (reserveIn + amountInAfterFee)

        uint256 numerator = amountInAfterFee * reserveOut;
        uint256 denominator = reserveIn + amountInAfterFee;
        amountOut = numerator / denominator;

        if (amountOut == 0) {
            revert DeFiPulseFusion__InsufficientOutputAmount();
        }

        // Update reserves
        if (_tokenIn == FUSION && _tokenOut == WETH) {
            fusionReserves += _amountIn; // Note: add full amountIn, fee is implicit in amountOut calculation
            wethReserves -= amountOut;
        } else { // WETH to FUSION
            wethReserves += _amountIn;
            fusionReserves -= amountOut;
        }

        // AMM fees implicitly increase the k-value (reserveIn * reserveOut), which increases the value per LP share,
        // or conceptually, increases the value of the pooled assets, contributing to the overall protocol value
        // which affects the burn ratio.

        // Update total staked value conceptually (fees add value to the pool)
        // This is a simplified approach. A real protocol might handle fees separately.
        // _totalStakedValue += (_amountIn * (10000 - ammFeeRate)) / 10000; // Add the value equivalent of the fee
        // This is complex as value is relative. Fees are best left to naturally increase the pool's assets.

        emit Swap(_msgSender(), _tokenIn, _tokenOut, _amountIn, amountOut);

        return amountOut;
    }


    // Helper to get the list of supported ERC20 tokens
    // In a real contract with many tokens, this might be paginated or handled differently.
    // For this example, we'll use a simple fixed-size array or similar approach if needed,
    // or assume iteration over mapping keys is acceptable for demonstration.
    // A better way is to track supported tokens in a dynamic array when adding/removing.
    address[] private _supportedERC20List;
    address[] private _supportedERC721List;

    function _addSupportedERC20ToList(address token) internal {
        for(uint i=0; i<_supportedERC20List.length; i++) {
            if (_supportedERC20List[i] == token) return; // Already exists
        }
        _supportedERC20List.push(token);
    }

     function _removeSupportedERC20FromList(address token) internal {
        for(uint i=0; i<_supportedERC20List.length; i++) {
            if (_supportedERC20List[i] == token) {
                _supportedERC20List[i] = _supportedERC20List[_supportedERC20List.length - 1];
                _supportedERC20List.pop();
                return;
            }
        }
    }

    function _addSupportedERC721ToList(address collection) internal {
        for(uint i=0; i<_supportedERC721List.length; i++) {
            if (_supportedERC721List[i] == collection) return; // Already exists
        }
        _supportedERC721List.push(collection);
    }

    function _removeSupportedERC721FromList(address collection) internal {
        for(uint i=0; i<_supportedERC721List.length; i++) {
            if (_supportedERC721List[i] == collection) {
                _supportedERC721List[i] = _supportedERC721List[_supportedERC721List.length - 1];
                _supportedERC721List.pop();
                return;
            }
        }
    }

    function _getSupportedERC20s() internal view returns (address[] memory) {
        return _supportedERC20List;
    }

     function _getSupportedERC721Collections() internal view returns (address[] memory) {
        return _supportedERC721List;
    }


    // --- Admin & Setup Functions ---

    function setGovernanceAddress(address _governance) external onlyOwner {
        address oldGov = governance;
        governance = _governance;
        emit GovernanceAddressSet(oldGov, governance);
    }

    // --- Staking & Unstaking Functions ---

    function addSupportedERC20(address _token, address _oracle, uint256 _minStakeAmount) external onlyGovernance whenNotPaused {
        if (supportedERC20s[_token].isSupported) revert DeFiPulseFusion__InvalidGovernanceProposal(); // Already supported
        supportedERC20s[_token] = SupportedERC20Config(_oracle, _minStakeAmount, true);
        _addSupportedERC20ToList(_token);
        emit SupportedERC20Added(_token, _oracle, _minStakeAmount);
    }

    function removeSupportedERC20(address _token) external onlyGovernance whenNotPaused {
        if (!supportedERC20s[_token].isSupported) revert DeFiPulseFusion__UnsupportedToken();
        if (totalStakedERC20[_token] > 0) revert DeFiPulseFusion__InvalidGovernanceProposal(); // Cannot remove while staked

        delete supportedERC20s[_token];
        _removeSupportedERC20FromList(_token);
        emit SupportedERC20Removed(_token);
    }

     function addSupportedERC721(address _collection, uint256 _utilityBoostFactor) external onlyGovernance whenNotPaused {
        if (supportedERC721s[_collection].isSupported) revert DeFiPulseFusion__InvalidGovernanceProposal(); // Already supported
        supportedERC721s[_collection] = SupportedERC721Config(_utilityBoostFactor, true);
        _addSupportedERC721ToList(_collection);
        emit SupportedERC721Added(_collection, _utilityBoostFactor);
    }

    function removeSupportedERC721(address _collection) external onlyGovernance whenNotPaused {
        if (!supportedERC721s[_collection].isSupported) revert DeFiPulseFusion__UnsupportedToken(); // Using UnsupportedToken error for consistency
         if (totalStakedERC721Count[_collection] > 0) revert DeFiPulseFusion__InvalidGovernanceProposal(); // Cannot remove while staked

        delete supportedERC721s[_collection];
        _removeSupportedERC721FromList(_collection);
        emit SupportedERC721Removed(_collection);
    }

    function stakeERC20(address _token, uint256 _amount) external nonReentrant whenNotPaused {
        SupportedERC20Config storage config = supportedERC20s[_token];
        if (!config.isSupported) revert DeFiPulseFusion__UnsupportedToken();
        if (_amount < config.minStakeAmount) revert DeFiPulseFusion__AmountTooLow(config.minStakeAmount);

        uint256 value = _getAssetValue(_token, _amount);
        if (value == 0) revert DeFiPulseFusion__InvalidGovernanceProposal(); // Oracle failure or zero value asset

        // Update user's accumulated stake value before adding new stake
        _updateAccountStakeValue(_msgSender(), _token, userERC20Stakes[_msgSender()][_token], true);

        // Transfer token
        bool success = IERC20(_token).transferFrom(_msgSender(), address(this), _amount);
        if (!success) revert DeFiPulseFusion__TransferFailed();

        userERC20Stakes[_msgSender()][_token] += _amount;
        totalStakedERC20[_token] += _amount;
        _totalStakedValue += value; // Update total TVL (snapshot value)

        // Record the time of the new stake to calculate future yield correctly
        userLastStakeUpdateTime[_msgSender()][_token] = block.timestamp;

        emit ERC20Staked(_msgSender(), _token, _amount, value);
    }

    function unstakeERC20(address _token, uint256 _amount) external nonReentrant whenNotPaused {
        if (!supportedERC20s[_token].isSupported) revert DeFiPulseFusion__UnsupportedToken();
        if (userERC20Stakes[_msgSender()][_token] < _amount) revert DeFiPulseFusion__InsufficientStake();
        if (_amount == 0) revert DeFiPulseFusion__AmountTooLow(1);

        // Calculate pending yield and update stake value *before* reducing stake
        // The claimable yield is handled by mintFusion or burnFusion, not here directly.
        // This function just removes the asset stake and updates the stake value calculation base.
        _updateAccountStakeValue(_msgSender(), _token, userERC20Stakes[_msgSender()][_token], true);

        uint256 value = _getAssetValue(_token, _amount); // Value based on current price for TVL adjustment
        if (value == 0 && _totalStakedValue > 0) {
            // Handle potential oracle failure during unstake - rough TVL adjustment needed
            // Simple approach: assume proportional value based on token's share of total TVL if possible,
            // or just reduce amount and warn. Let's just update amount and total count.
            // For a real system, oracle failure would require pausing or more complex handling.
        } else if (value > 0) {
             _totalStakedValue -= value; // Update total TVL (snapshot value)
        }


        userERC20Stakes[_msgSender()][_token] -= _amount;
        totalStakedERC20[_token] -= _amount;

        // Transfer token back
        bool success = IERC20(_token).transfer(_msgSender(), _amount);
         if (!success) revert DeFiPulseFusion__TransferFailed();

        // Reset last update time if stake becomes zero, otherwise update
        if (userERC20Stakes[_msgSender()][_token] == 0) {
            userLastStakeUpdateTime[_msgSender()][_token] = 0;
            userAccruedStakeValue[_msgSender()][_token] = 0; // Reset accumulated value for this token
        } else {
             userLastStakeUpdateTime[_msgSender()][_token] = block.timestamp; // Update for remaining stake
        }

        emit ERC20Unstaked(_msgSender(), _token, _amount);
    }

    function stakeERC721(address _collection, uint256 _tokenId) external nonReentrant whenNotPaused {
        SupportedERC721Config storage config = supportedERC721s[_collection];
        if (!config.isSupported) revert DeFiPulseFusion__UnsupportedToken(); // Using UnsupportedToken error

        // Check ownership before transfer
        if (IERC721(_collection).ownerOf(_tokenId) != _msgSender()) revert DeFiPulseFusion__InvalidTokenId();

        // Check if already staked by this user (shouldn't be possible with correct flow, but as safeguard)
         for (uint i = 0; i < userERC721Stakes[_msgSender()][_collection].length; i++) {
             if (userERC721Stakes[_msgSender()][_collection][i] == _tokenId) {
                 revert DeFiPulseFusion__InvalidTokenId(); // Already staked by this user
             }
         }


        // Update user's accumulated stake value before adding new stake
         _updateAccountStakeValue(_msgSender(), _collection, 0, false); // Amount is 0 for NFTs, only need collection

        // Transfer NFT
        IERC721(_collection).safeTransferFrom(_msgSender(), address(this), _tokenId);

        userERC721Stakes[_msgSender()][_collection].push(_tokenId);
        totalStakedERC721Count[_collection]++;

        // Update total TVL (snapshot value including NFT boost)
        _totalStakedValue += _getNFTValueBoost(_collection);

        // Record the time of the new stake
        userLastStakeUpdateTime[_msgSender()][_collection] = block.timestamp;

        emit ERC721Staked(_msgSender(), _collection, _tokenId);
    }

    function unstakeERC721(address _collection, uint256 _tokenId) external nonReentrant whenNotPaused {
        if (!supportedERC721s[_collection].isSupported) revert DeFiPulseFusion__UnsupportedToken(); // Using UnsupportedToken error

        // Check if staked by this user
        bool found = false;
        uint256 index = 0;
        uint256[] storage stakedTokens = userERC721Stakes[_msgSender()][_collection];
        for (uint i = 0; i < stakedTokens.length; i++) {
            if (stakedTokens[i] == _tokenId) {
                found = true;
                index = i;
                break;
            }
        }
        if (!found) revert DeFiPulseFusion__NotStaked();

         // Calculate pending yield and update stake value *before* removing stake
        _updateAccountStakeValue(_msgSender(), _collection, 0, false); // Amount is 0 for NFTs, only need collection

        // Remove from user's staked list
        stakedTokens[index] = stakedTokens[stakedTokens.length - 1];
        stakedTokens.pop();

        totalStakedERC721Count[_collection]--;

        // Update total TVL (snapshot value)
        _totalStakedValue -= _getNFTValueBoost(_collection); // Reduce value contribution

        // Transfer NFT back
        IERC721(_collection).safeTransferFrom(address(this), _msgSender(), _tokenId);

        // Update last update time for remaining NFTs, or reset if none left
        if (stakedTokens.length == 0) {
             userLastStakeUpdateTime[_msgSender()][_collection] = 0;
             userAccruedStakeValue[_msgSender()][_collection] = 0; // Reset accumulated value for this collection
        } else {
            userLastStakeUpdateTime[_msgSender()][_collection] = block.timestamp; // Update for remaining NFTs
        }


        emit ERC721Unstaked(_msgSender(), _collection, _tokenId);
    }

    // Required by IERC721Receiver
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external view returns (bytes4) {
        // Only allow receiving NFTs if they are from this contract itself during unstaking,
        // or if the sender is staking via stakeERC721 (which does the transfer first).
        // This prevents arbitrary NFT transfers to the contract.
        // A more robust check might verify `from` is tx.origin or _msgSender(), and the collection is supported.
        // For simplicity here, just return the magic value if the collection is supported.
        if (supportedERC721s[msg.sender].isSupported) {
             return this.onERC721Received.selector;
        }
        revert DeFiPulseFusion__UnsupportedToken();
    }


    // --- FUSION Management Functions ---

    // Allows user to mint FUSION based on their accumulated stake value and pending yield
    // Resets accumulated stake value after minting.
    function mintFusion() external nonReentrant whenNotPaused {
        address user = _msgSender();

        // Calculate total current stake value across all assets
        uint256 currentStakeValue = getAccountStakeValue(user);

        // Calculate total accumulated value across all assets and update
        uint256 totalAccumulatedValue = 0;
         for (address token : _getSupportedERC20s()) {
             _updateAccountStakeValue(user, token, userERC20Stakes[user][token], true);
             totalAccumulatedValue += userAccruedStakeValue[user][token];
             userAccruedStakeValue[user][token] = 0; // Reset accumulated value after using it for minting
         }
         for (address collection : _getSupportedERC721Collections()) {
              _updateAccountStakeValue(user, collection, 0, false);
              totalAccumulatedValue += userAccruedStakeValue[user][collection];
              userAccruedStakeValue[user][collection] = 0; // Reset accumulated value
         }


        // Calculate yield based on total accumulated stake value
        uint256 yieldValue = (totalAccumulatedValue * yieldRatePerSecond) / (1e18); // Assuming yieldRatePerSecond is scaled 1e18

        // Total value to mint against = currentStakeValue + yieldValue
        uint256 totalValueBasis = currentStakeValue + yieldValue;

        if (totalValueBasis == 0) revert DeFiPulseFusion__MintAmountZero();

        // Calculate mint amount based on dynamic ratio
        // Fusion Mint Amount = totalValueBasis * dynamicRatio / 1e18 (if dynamicRatio is scaled 1e18)
        uint256 dynamicRatio = _getDynamicFusionRatio();
        uint256 fusionAmount = (totalValueBasis * dynamicRatio) / (1e18); // Assuming ratio is 1e18 scaled

        if (fusionAmount == 0) revert DeFiPulseFusion__MintAmountZero();


        // Mint FUSION tokens
        IERC20(FUSION).mint(user, fusionAmount); // Assumes FUSION is a minter-capped token owned by this contract

        emit FusionMinted(user, fusionAmount, currentStakeValue, yieldValue);
    }

     // Allows user to burn FUSION to redeem their staked assets and pending yield
     // The actual unstaking of assets happens separately after burning FUSION.
     // Burning FUSION increases the user's 'redeemable value'.
     function burnFusion(uint256 _amount) external nonReentrant whenNotPaused {
         address user = _msgSender();
         if (_amount == 0) revert DeFiPulseFusion__AmountTooLow(1);

         // Check if user has enough FUSION
         if (IERC20(FUSION).balanceOf(user) < _amount) revert DeFiPulseFusion__BurnAmountTooHigh();

         // Calculate value to unlock based on burn amount and inverse dynamic ratio
         // Value unlocked = amount * (1 / dynamicRatio)
         // Value unlocked = (amount * 1e18) / dynamicRatio
         uint256 dynamicRatio = _getDynamicFusionRatio();
         if (dynamicRatio == 0) revert DeFiPulseFusion__AMMPoolEmpty(); // Should not happen if minRatio > 0
         uint256 valueToUnlock = (_amount * (1e18)) / dynamicRatio; // Value unlocked in base units (scaled 1e18)

         // Burn FUSION tokens
         IERC20(FUSION).burn(user, _amount); // Assumes FUSION is a burner-capped token owned by this contract

         // Add valueToUnlock to a user's redeemable value balance (not implemented here for simplicity)
         // A real protocol needs a mapping like `userRedeemableValue[address]`
         // and functions to claim specific assets proportional to this value.
         // For this example, we'll just emit the unlocked value conceptually.

         emit FusionBurned(user, _amount, valueToUnlock);
     }

    // --- Yield & Value Query Functions ---

    function getPendingYield(address _user) public view returns (uint256) {
        return _calculatePendingYield(_user);
    }

     function getAccountStakeValue(address _user) public view returns (uint256) {
         uint256 totalValue = 0;
         // Sum value of all staked ERC20s
         for (address token : _getSupportedERC20s()) {
             uint256 amount = userERC20Stakes[_user][token];
             if (amount > 0) {
                 totalValue += _getAssetValue(token, amount);
             }
         }
         // Sum value of all staked ERC721s (boost value per NFT)
         for (address collection : _getSupportedERC721Collections()) {
             uint256 nftCount = getUserERC721Stakes(_user, collection).length;
             if (nftCount > 0) {
                 totalValue += _getNFTValueBoost(collection) * nftCount;
             }
         }
         return totalValue;
     }

     function getTotalStakedValue() public view returns (uint256) {
         // Returns the cached TVL. Note this is a snapshot at the last stake/unstake/config change.
         // For a real-time TVL, recalculate using current oracle prices for all staked assets.
         return _totalStakedValue;
     }

    function getUserERC721Stakes(address _user, address _collection) public view returns (uint256[] memory) {
        // Make private mapping data accessible
        return userERC721Stakes[_user][_collection];
    }


    // --- Internal AMM Functions ---

    function swapFusion(uint256 _amount, address _tokenOut, uint256 _minAmountOut) external nonReentrant whenNotPaused returns (uint256) {
        address tokenIn = FUSION;
        // Basic check if the swap pair is FUSION/WETH
        if (_tokenOut != WETH) revert DeFiPulseFusion__UnsupportedToken();

        // Pull tokens into the contract
        bool success = IERC20(tokenIn).transferFrom(_msgSender(), address(this), _amount);
        if (!success) revert DeFiPulseFusion__TransferFailed();

        uint256 amountOut = _swap(tokenIn, _tokenOut, _amount);

        if (amountOut < _minAmountOut) revert DeFiPulseFusion__InsufficientOutputAmount();

        // Send output tokens
        success = IERC20(_tokenOut).transfer(_msgSender(), amountOut);
        if (!success) revert DeFiPulseFusion__TransferFailed();

        return amountOut;
    }

    function swapWETH(uint256 _amount, uint256 _minAmountOut) external nonReentrant whenNotPaused returns (uint256) {
         address tokenIn = WETH;
         address tokenOut = FUSION;

         // Pull tokens into the contract
         bool success = IERC20(tokenIn).transferFrom(_msgSender(), address(this), _amount);
         if (!success) revert DeFiPulseFusion__TransferFailed();

         uint256 amountOut = _swap(tokenIn, tokenOut, _amount);

         if (amountOut < _minAmountOut) revert DeFiPulseFusion__InsufficientOutputAmount();

         // Send output tokens
         success = IERC20(tokenOut).transfer(_msgSender(), amountOut);
         if (!success) revert DeFiPulseFusion__TransferFailed();

         return amountOut;
    }

    function addLiquidity(uint256 _amountFusion, uint256 _amountWETH) external nonReentrant whenNotPaused returns (uint256 lpTokensMinted) {
        address user = _msgSender();

        // Pull tokens into the contract
        bool success = IERC20(FUSION).transferFrom(user, address(this), _amountFusion);
        if (!success) revert DeFiPulseFusion__TransferFailed();
        success = IERC20(WETH).transferFrom(user, address(this), _amountWETH);
        if (!success) revert DeFiPulseFusion__TransferFailed();

        uint256 currentFusionReserves = fusionReserves;
        uint256 currentWETHReserves = wethReserves;
        uint256 totalLPSupply = IERC20(address(this)).totalSupply(); // Assuming contract issues LP tokens to itself conceptually, or mints a separate LP token

        if (totalLPSupply == 0) {
            // First liquidity provider
             lpTokensMinted = (_amountFusion * _amountWETH)**(0.5); // Simplified: geometric mean
             if (lpTokensMinted < MINIMUM_LIQUIDITY) {
                 // Return dust amount and revert
                 success = IERC20(FUSION).transfer(user, _amountFusion); if (!success) revert DeFiPulseFusion__TransferFailed();
                 success = IERC20(WETH).transfer(user, _amountWETH); if (!success) revert DeFiPulseFusion__TransferFailed();
                 revert DeFiPulseFusion__InsufficientLiquidity();
             }
             // Burn minimum liquidity tokens to prevent issues
             // IERC20(address(this)).burn(address(0), MINIMUM_LIQUIDITY); // Assuming contract is LP token issuer
             // lpTokensMinted -= MINIMUM_LIQUIDITY;
             // This requires the contract to *be* an ERC20 LP token issuer, let's simplify.
             // We won't issue LP tokens explicitly in this example.
             // Liquidity is added, reserves updated, and user tracked implicitly or via shares.
             // Let's track LP shares via a mapping user -> shares. Contract total supply is sum of shares.
             // This requires implementing LP token logic or tracking shares separately.
             // SIMPLIFICATION: For this example, we'll just update reserves. A real system needs LP tokens.
              fusionReserves += _amountFusion;
              wethReserves += _amountWETH;
             // We need to mint LP tokens or track shares. Let's assume a separate LP token contract `LP_TOKEN`.
             // uint256 lpTokensToMint = ... based on formula
             // LP_TOKEN(address(this)).mint(user, lpTokensToMint);
             // For this example, let's return 0 and update reserves, acknowledging LP token management is needed.
             fusionReserves += _amountFusion;
             wethReserves += _amountWETH;
             lpTokensMinted = 0; // Placeholder, actual LP token logic needed
             // Acknowledge: Proper LP token management (minting/burning based on share) is required here.

        } else {
             // Subsequent liquidity providers
             // Amount of LP tokens to mint = totalLPSupply * min(_amountFusion / currentFusionReserves, _amountWETH / currentWETHReserves)
             // Simplified: calculate new K, compare to old K, mint tokens proportional to increase.
             // Needs LP token total supply and user balances.
             // Let's stick to the simplified reserve update and placeholder return.
             fusionReserves += _amountFusion;
             wethReserves += _amountWETH;
             lpTokensMinted = 0; // Placeholder
        }


        emit LiquidityAdded(user, _amountFusion, _amountWETH, lpTokensMinted);
        return lpTokensMinted;
    }

    // Acknowledge: removeLiquidity function would be complex and requires LP token tracking. Omitted for brevity but required in full implementation.


    // --- Dynamic Parameter Management (via Governance) ---

    function setYieldRatePerSecond(uint256 _newRate) external onlyGovernance {
        yieldRatePerSecond = _newRate;
        // Event for parameter change needed
    }

     function setSwapFee(uint256 _newFeeRate) external onlyGovernance {
         if (_newFeeRate > 10000) revert DeFiPulseFusion__InvalidGovernanceProposal(); // Fee > 100%
         ammFeeRate = _newFeeRate;
         // Event for parameter change needed
     }

     function setFusionMintRatioParams(uint256 _newMaxRatio, uint256 _newTVLScaleFactor) external onlyGovernance {
         if (_newMaxRatio == 0 || _newTVLScaleFactor == 0) revert DeFiPulseFusion__InvalidGovernanceProposal();
         fusionMaxMintRatio = _newMaxRatio;
         fusionTVLScaleFactor = _newTVLScaleFactor;
          // Event for parameter change needed
     }


    // --- Governance Functions ---
    // This is a highly simplified governance model.

    function proposeParameterChange(bytes32 _paramName, uint256 _newValue, string memory _description) external whenNotPaused returns (uint256 proposalId) {
        // Basic check: user must have some stake or FUSION balance to propose
        // Let's require a minimum staked value or FUSION balance to propose.
        // Simplification: Any user can propose, governance power check is on voting.
         if (bytes(_description).length == 0) revert DeFiPulseFusion__InvalidGovernanceProposal();

        proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            paramName: _paramName,
            newValue: _newValue,
            description: _description,
            startTime: block.timestamp,
            votesFor: 0,
            votesAgainst: 0,
            executed: false
        });

        emit ParameterChangeProposed(proposalId, _paramName, _newValue, _description);
    }

    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.startTime == 0 || proposal.startTime + governanceVotingPeriod < block.timestamp) {
            revert DeFiPulseFusion__ProposalExpired();
        }
        if (proposal.executed) revert DeFiPulseFusion__ProposalAlreadyExists(); // Using this error to mean already acted upon
        if (proposal.hasVoted[_msgSender()]) revert DeFiPulseFusion__AlreadyVoted();

        // Get voter's governance power (e.g., based on staked value or FUSION balance)
        // Simplification: Governance power is 1 per FUSION token held. A real protocol needs staked FUSION.
        uint256 voterPower = IERC20(FUSION).balanceOf(_msgSender());
        if (voterPower == 0) revert DeFiPulseFusion__InsufficientStake(); // Need FUSION to vote

        proposal.hasVoted[_msgSender()] = true;
        if (_support) {
            proposal.votesFor += voterPower;
        } else {
            proposal.votesAgainst += voterPower;
        }

        emit VoteCast(_msgSender(), _proposalId, _support);
    }

    function executeProposal(uint256 _proposalId) external nonReentrant whenNotPaused onlyGovernance {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.startTime == 0 || proposal.executed) revert DeFiPulseFusion__InvalidGovernanceProposal();
        if (block.timestamp < proposal.startTime + governanceVotingPeriod) {
            revert DeFiPulseFusion__VotingPeriodNotEnded();
        }

        uint256 totalGovernancePower = IERC20(FUSION).totalSupply(); // Simplification: use total supply. Real: total staked FUSION.
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;

        // Check Quorum: total votes must exceed quorum threshold
        if (totalVotes * 100 < totalGovernancePower * governanceQuorumThreshold) {
            revert DeFiPulseFusion__ProposalNotPassed(); // Did not meet quorum
        }

        // Check Majority: votesFor must exceed majority threshold of total votes
        if (proposal.votesFor * 100 <= totalVotes * governanceMajorityThreshold) {
             revert DeFiPulseFusion__ProposalNotPassed(); // Did not meet majority
        }

        // Execute the parameter change
        bytes32 paramName = proposal.paramName;
        uint256 newValue = proposal.newValue;

        // Use a hash of parameter names to map to functions
        // This is safer than allowing arbitrary calls.
        if (paramName == keccak256("yieldRatePerSecond")) {
             setYieldRatePerSecond(newValue);
        } else if (paramName == keccak256("ammFeeRate")) {
             setSwapFee(newValue);
        } else if (paramName == keccak256("fusionMintRatioParams")) {
             // Needs two values. A single newValue doesn't work here.
             // Parameter changes requiring multiple values are complex for this simple governance struct.
             // Let's assume this type of change is done via a different governance function or struct.
             revert DeFiPulseFusion__ExecutionFailed(); // Parameter type needs different handling
             // For demonstration, let's add specific execute functions for multi-value params if needed,
             // or simplify parameters to be single values. We added specific setters like setFusionMintRatioParams.
             // Need to adjust execute logic to call these specific setters.
             // This requires the proposal struct to be more complex or the governance to have more predefined actions.
             // Let's remove this specific case for now or simplify the allowed params.
             // Let's assume only single-value params can be changed via this generic function.
        }
        // Add more `else if` for other single-value parameters (e.g., governance thresholds, min stake amounts).
        // Example:
        // else if (paramName == keccak256("minStakeAmount_TOKENADDRESS")) {
        //     supportedERC20s[TOKENADDRESS].minStakeAmount = newValue;
        // }
        // This becomes complex quickly. The governance should ideally propose and execute specific setter functions.
        // A better governance system calls a target contract/function with data.
        // Let's stick to the simplified model but acknowledge its limitations.

        // Alternative: Governance proposes a call to a specific function with specific data.
        // Proposal struct: address target, bytes callData, string description...
        // Execute: (bool success, bytes memory returnData) = target.call(callData);

        // Let's revert to the simple model for this example and assume the paramName covers the logic.
        // The `setYieldRatePerSecond` and `setSwapFee` functions above should be internal and called here,
        // with external access only via `executeProposal`.
        // Let's modify `setYieldRatePerSecond` and `setSwapFee` to be internal.
        // (Need to move them below this function or declare them first).

        // Re-implementing execution for clarity:
        if (paramName == keccak256("yieldRatePerSecond")) {
            yieldRatePerSecond = newValue;
        } else if (paramName == keccak256("ammFeeRate")) {
            if (newValue > 10000) revert DeFiPulseFusion__InvalidGovernanceProposal();
            ammFeeRate = newValue;
        }
        // ... add more parameter updates here

        proposal.executed = true;
        emit ProposalExecuted(_proposalId);
    }

     // Allow getting a list of active proposals (simplified)
     function getCurrentProposals() external view returns (uint256[] memory activeProposalIds) {
         uint256[] memory allIds = new uint256[](nextProposalId - 1);
         uint256 count = 0;
         for (uint256 i = 1; i < nextProposalId; i++) {
             if (proposals[i].startTime > 0 && !proposals[i].executed && block.timestamp < proposals[i].startTime + governanceVotingPeriod) {
                 allIds[count++] = i;
             }
         }
         // Resize array
         activeProposalIds = new uint256[](count);
         for(uint i=0; i<count; i++) {
             activeProposalIds[i] = allIds[i];
         }
         return activeProposalIds;
     }


    // --- Pause Functionality ---
    // Inherited from Pausable. onlyOwner() controls pause/unpause by default,
    // but it's common to transfer this to governance or a multi-sig.
    // Let's override to make it onlyGovernance
     function pause() public override onlyGovernance whenNotPaused {
         _pause();
     }

     function unpause() public override onlyGovernance whenPaused {
         _unpause();
     }


    // --- Flash Mint Implementation (ERC-3156) ---

    // Max amount that can be flash-minted (e.g., total supply minus some buffer)
    function maxFlashLoan(address token) external view override returns (uint256) {
        if (token == FUSION) {
            uint256 supply = IERC20(FUSION).totalSupply();
            // Allow minting up to total supply. Repayment must be supply + fee.
            // This works because flash minting requires burning the minted amount + fee.
            // Or, cap at a percentage of supply to manage risk. Let's cap at total supply for simplicity.
            return supply; // Or a capped amount, e.g., supply / 2
        }
        return 0; // Only FUSION token is supported for flash loans
    }

    // Fee charged for flash minting
    function flashFee(address token, uint256 amount) external view override returns (uint256) {
         if (token != FUSION) return type(uint256).max; // Unsupported token
         // Example fee: 0.05% of the amount
         // Fee = amount * 5 / 10000 (0.05%)
         return (amount * 5) / 10000; // 0.05% fee, needs scaling based on desired fee rate
    }

    // Main flash loan function
    function flashLoan(IERC3156FlashRecipient receiver, address token, uint256 amount, bytes calldata data) external override nonReentrant whenNotPaused returns (bool) {
        if (token != FUSION) revert DeFiPulseFusion__UnsupportedToken();
        if (amount > maxFlashLoan(token)) revert DeFiPulseFusion__FlashLoanTooLarge();

        uint256 fee = flashFee(token, amount);
        uint256 amountToRepay = amount + fee;

        // 1. Mint tokens to receiver
        IERC20(FUSION).mint(address(receiver), amount); // Assumes minter permission

        // 2. Call receiver's callback function
        // The receiver is expected to perform actions (e.g., arbitrage) and acquire `amountToRepay` of the token
        // and approve this contract to pull it back.
        bytes4 callbackReturnValue = receiver.onFlashLoan(_msgSender(), token, amount, fee, data);

        // Check the return value - ERC-3156 requires a specific magic value on success
        if (callbackReturnValue != IERC3156FlashRecipient.onFlashLoan.selector) {
            revert DeFiPulseFusion__FlashLoanCallbackFailed();
        }

        // 3. Pull tokens back from the receiver
        // Use transferFrom to pull amountToRepay from the receiver back to this contract (which will then burn it)
        // Receiver must have approved this contract to spend amountToRepay
        uint256 receiverBalanceAfter = IERC20(FUSION).balanceOf(address(receiver));
        if (receiverBalanceAfter < amountToRepay) revert DeFiPulseFusion__FlashLoanRepaymentFailed();

        // Burn the tokens that were flash-minted + the fee.
        // This effectively takes the fee from the arbitrageur and removes the minted tokens from existence.
        // The fee tokens must be acquired by the arbitrageur during their operation.
        IERC20(FUSION).burn(address(receiver), amountToRepay); // Assumes burner permission

        // The fee collected (part of amountToRepay burned) is not explicitly held by the contract.
        // It's burned, reducing the total supply of FUSION. This benefits existing FUSION holders.
        // Alternative: Burn `amount` and transfer `fee` to a fee distribution module or the contract itself.
        // Burning both amount and fee simplifies the implementation and deflationary for FUSION.

        emit FlashLoan(address(receiver), amount, fee);

        return true;
    }


    // --- Emergency Functions ---
    // Allows governance to withdraw potentially stuck tokens. Use with caution.

    function emergencyWithdraw(address _token, uint256 _amount) external onlyGovernance whenPaused {
        // Can only be called when paused.
        // Withdraws _amount of _token to the governance address.
        bool success = IERC20(_token).transfer(governance, _amount);
        if (!success) revert DeFiPulseFusion__TransferFailed();
    }

    // --- Query Functions ---

    function getFusionMintRatio() public view returns (uint256) {
        return _getDynamicFusionRatio();
    }

    function getSwapFee() public view returns (uint256) {
        return ammFeeRate;
    }

    function getSupportedERC20Config(address _token) public view returns (SupportedERC20Config memory) {
        return supportedERC20s[_token];
    }

    function getSupportedERC721Config(address _collection) public view returns (SupportedERC721Config memory) {
        return supportedERC721s[_collection];
    }

     function getAMMPoolReserves() public view returns (uint256 fusion, uint256 weth) {
         return (fusionReserves, wethReserves);
     }

     function getProtocolParameters() public view returns (
         uint256 currentYieldRatePerSecond,
         uint256 currentAmmFeeRate,
         uint256 currentFusionMaxMintRatio,
         uint256 currentFusionTVLScaleFactor,
         uint256 currentGovernanceVotingPeriod,
         uint256 currentGovernanceQuorumThreshold,
         uint256 currentGovernanceMajorityThreshold,
         uint256 currentNextProposalId
     ) {
         return (
             yieldRatePerSecond,
             ammFeeRate,
             fusionMaxMintRatio,
             fusionTVLScaleFactor,
             governanceVotingPeriod,
             governanceQuorumThreshold,
             governanceMajorityThreshold,
             nextProposalId
         );
     }
}
```