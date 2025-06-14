Okay, here is a Solidity smart contract concept called "QuantumLeapExchange". It's an advanced decentralized exchange (AMM) that goes beyond simple token swaps by introducing "Prediction Vaults" and "Time-Locked Pools", where liquidity providers can deposit funds under specific conditions or time locks, potentially influencing swap mechanics and earning variable fees. All LP positions are represented by unique NFTs, allowing for advanced position management like splitting and merging. It requires an external oracle for price condition checks.

This contract combines elements of AMMs, conditional logic, time-locking, variable fees, and NFT position management in a non-standard way to fulfill the request for advanced, creative, and non-duplicated concepts.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- QuantumLeapExchange Smart Contract Outline ---
// This contract implements a decentralized exchange with standard AMM features
// plus novel "Prediction Vaults" and "Time-Locked Pools".
// All liquidity positions (Standard, Prediction, Time-Locked) are represented by ERC721 NFTs.

// 1. Core Components:
//    - ERC721 Implementation (Embedded) for position NFTs.
//    - Pool Management (Pairs of ERC20 tokens).
//    - Liquidity Provision (Standard, Prediction, Time-Locked).
//    - Swap Execution (Standard, Prediction-assisted, Time-Locked-assisted).
//    - Oracle Integration for Prediction Vault conditions.
//    - Protocol Fee Management.
//    - Position NFT Management (Split, Merge).

// 2. Key Concepts:
//    - Standard Liquidity: Basic XY=K AMM liquidity.
//    - Prediction Vaults: Liquidity locked until an external price condition is met within a time window. Can be used for swaps once condition is met.
//    - Time-Locked Pools: Liquidity locked for a set duration. Swaps utilizing this liquidity can have different fee structures.
//    - Position NFTs: ERC721 tokens representing ownership of specific Standard, Prediction, or Time-Locked liquidity positions. Tradable and composable.
//    - Variable Fees: Fees can differ based on the type of swap (standard vs. assisted).

// --- Function Summary ---
// Owner/Admin Functions:
// - constructor: Deploys the contract, sets owner, initializes NFT.
// - addSupportedToken: Whitelists an ERC20 token.
// - setOracleAddress: Sets the address of the external price oracle.
// - updateStandardFee: Updates the fee rate for standard swaps.
// - updateLeapSwapFeeMultiplier: Updates the multiplier for Time-Locked (Leap) swap fees.
// - updatePredictionSwapDiscount: Updates the discount applied to Prediction Swaps.
// - withdrawProtocolFees: Allows owner to withdraw accumulated protocol fees.
// - pause: Pauses sensitive operations (swaps, LP changes).
// - unpause: Unpauses the contract.

// Pool Management:
// - createPool: Creates a new trading pair pool for two supported tokens.

// Standard Liquidity Provision (using Position NFTs):
// - addLiquidity: Adds liquidity to a standard pool and mints a Position NFT.
// - removeLiquidity: Burns a Position NFT and removes corresponding liquidity.

// Prediction Vaults (using Position NFTs):
// - createPredictionVault: Creates a prediction vault position with conditional release, mints a Prediction Position NFT. Requires oracle condition.
// - checkPredictionVaultCondition: View function to check if a prediction vault's condition is currently met via oracle.
// - executePredictionSwap: Executes a swap using liquidity from Prediction Vaults whose conditions are met. May offer a discount. (Complex: Simplified - uses any met PV liquidity in the pool).
// - claimFromPredictionVault: Claims tokens from a Prediction Vault after its time window expires (condition not met) or after its liquidity was used in a swap.
// - cancelPredictionVault: Allows early withdrawal from a Prediction Vault with a penalty.

// Time-Locked Pools (using Position NFTs):
// - createTimeLockedPool: Adds liquidity with a time lock, mints a Time-Locked Position NFT.
// - executeLeapSwap: Executes a swap specifically using liquidity from Time-Locked Pools. May have a different fee structure. (Simplified - uses any available TL liquidity in the pool).
// - claimFromTimeLockedPool: Claims tokens from a Time-Locked Pool after its lock duration expires.
// - extendTimeLockedPool: Extends the lock duration of an existing Time-Locked Pool position.

// Swap Functions:
// - swap: Executes a standard XY=K token swap.
// - executePredictionSwap (See Prediction Vaults)
// - executeLeapSwap (See Time-Locked Pools)

// Position NFT Management:
// - splitPositionNFT: Splits a single Position NFT into two new NFTs.
// - mergePositionNFTs: Merges multiple Position NFTs of the same type and pool into a single NFT.
// - tokenOfOwnerByIndex (ERC721): Returns token ID owned by an owner at a given index.
// - ownerOf (ERC721): Returns the owner of a specific NFT.
// - balanceOf (ERC721): Returns the number of NFTs owned by an address.
// - transferFrom (ERC721): Transfers an NFT.
// - safeTransferFrom (ERC721): Safely transfers an NFT.
// - approve (ERC721): Approves another address to manage an NFT.
// - getApproved (ERC721): Gets the approved address for an NFT.
// - setApprovalForAll (ERC721): Sets approval for all NFTs.
// - isApprovedForAll (ERC721): Checks if an address is approved for all NFTs.
// - supportsInterface (ERC721): Checks if the contract supports an interface (ERC721).

// View Functions:
// - getPoolState: Returns the current state of a pool (reserves, fees).
// - getPositionDetails: Returns details of a specific Position NFT (generic).
// - getPredictionVaultDetails: Returns specific details for a Prediction Vault NFT.
// - getTimeLockedPoolDetails: Returns specific details for a Time-Locked Pool NFT.
// - isSupportedToken: Checks if a token is supported.
// - getProtocolFees: Returns current accumulated protocol fees per token.
// - getPools: Returns the list of created pool IDs.
// - calculateSwapOutput: Calculates the output amount for a standard swap.
// - calculatePredictionSwapOutput: Calculates the output amount for a Prediction Swap (considering discount).
// - calculateLeapSwapOutput: Calculates the output amount for a Leap Swap (considering multiplier).

// Events:
// - PoolCreated
// - LiquidityAdded (Standard, Prediction, TimeLocked)
// - LiquidityRemoved (Standard, Prediction, TimeLocked)
// - SwapExecuted (Standard, Prediction, Leap)
// - VaultConditionMet
// - ProtocolFeesCollected
// - PositionSplit
// - PositionMerged
// - Paused
// - Unpaused
// - Transfer (ERC721)
// - Approval (ERC721)
// - ApprovalForAll (ERC721)

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Using SafeMath explicitly for clarity, though 0.8+ handles overflow/underflow
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // Include interface for clarity, embedding implementation

// Mock Oracle Interface (replace with actual Oracle like Chainlink AggregatorV3Interface)
interface IPriceOracle {
    function getLatestPrice(address tokenA, address tokenB) external view returns (int256 price, uint256 timestamp);
}

contract QuantumLeapExchange is IERC721 {
    using SafeMath for uint256;

    // --- ERC721 Embedded Implementation ---
    string public constant name = "QuantumLeapPosition";
    string public constant symbol = "QLP";
    uint256 private _nextTokenId;
    mapping(uint256 => address) private _tokenOwners;
    mapping(address => uint256) private _balanceOf;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // --- State Variables ---
    address public owner;
    IPriceOracle public oracle;
    bool public paused;

    // Supported Tokens
    mapping(address => bool) public isSupportedToken;
    address[] public supportedTokens;

    // Pool Management
    struct Pool {
        address tokenA;
        address tokenB;
        uint256 reserveA;
        uint256 reserveB;
        uint256 kLast; // for fee calculation
        uint256 standardFee; // e.g., 997 -> 0.3% fee (1000 - 997)
        uint256 leapFeeMultiplier; // Multiplier on standard fee for Leap Swaps (e.g., 1100 -> 1.1x fee)
        uint256 predictionSwapDiscount; // Discount percentage for Prediction Swaps (e.g., 50 -> 5% discount)
    }
    mapping(bytes32 => Pool) public pools; // pair hash => Pool struct
    bytes32[] public poolIds; // List of active pool hashes

    // Position Management (Linked to Position NFT)
    enum PositionType { StandardLP, PredictionVault, TimeLocked }
    enum ComparisonType { GreaterThan, LessThan }

    struct Position {
        PositionType positionType;
        bytes32 poolId;
        address owner;
        uint256 amountA; // Amount locked/represented
        uint256 amountB; // Amount locked/represented
        uint256 mintTimestamp;
        uint256 lastInteractionTimestamp; // e.g., last claim time
    }
    mapping(uint256 => Position) public positions; // tokenId => Position struct

    // Prediction Vault Specific Data
    struct PredictionVaultData {
        int256 priceTarget; // Price target for the condition
        address conditionToken; // Which token's price is being tracked (relative to the other token in the pair)
        ComparisonType comparison; // > or < target price
        uint256 startTime; // Condition active from this timestamp
        uint256 endTime; // Condition must be met by this timestamp
        bool conditionMet; // Flag indicating if condition was met within the window
        bool claimed; // Flag indicating if tokens have been claimed
    }
    mapping(uint255 => PredictionVaultData) public predictionVaults; // tokenId => Data

    // Time-Locked Specific Data
    struct TimeLockedData {
        uint256 lockDuration; // Duration in seconds
        uint256 endTime; // calculated as mintTimestamp + lockDuration
        bool claimed; // Flag indicating if tokens have been claimed
    }
    mapping(uint255 => TimeLockedData) public timeLockedPools; // tokenId => Data

    // Protocol Fees
    mapping(address => uint256) public protocolFees;

    // --- Events ---
    event PoolCreated(bytes32 indexed poolId, address indexed tokenA, address indexed tokenB);
    event LiquidityAdded(uint256 indexed tokenId, bytes32 indexed poolId, address indexed provider, PositionType positionType, uint256 amountA, uint256 amountB);
    event LiquidityRemoved(uint256 indexed tokenId, bytes32 indexed poolId, address indexed provider, PositionType positionType, uint256 amountA, uint256 amountB);
    event SwapExecuted(bytes32 indexed poolId, address indexed swapper, address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOut, PositionType swapType);
    event VaultConditionMet(uint256 indexed tokenId, bytes32 indexed poolId, int256 price, uint256 timestamp);
    event ProtocolFeesCollected(address indexed token, uint256 amount);
    event PositionSplit(uint256 indexed originalTokenId, uint256 indexed newTokenId1, uint256 indexed newTokenId2);
    event PositionMerged(uint256[] indexed originalTokenIds, uint256 indexed newTokenId);
    event Paused(address account);
    event Unpaused(address account);

    // ERC721 Events (Standard)
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "QLX: Not owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "QLX: Paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "QLX: Not paused");
        _;
    }

    // --- Constructor ---
    constructor(address _oracleAddress) {
        owner = msg.sender;
        oracle = IPriceOracle(_oracleAddress);
        _nextTokenId = 0; // Start token IDs from 0
    }

    // --- Owner/Admin Functions ---
    function addSupportedToken(address token) external onlyOwner {
        require(token != address(0), "QLX: Zero address");
        require(!isSupportedToken[token], "QLX: Token already supported");
        isSupportedToken[token] = true;
        supportedTokens.push(token);
    }

    function setOracleAddress(address _oracleAddress) external onlyOwner {
        require(_oracleAddress != address(0), "QLX: Zero address");
        oracle = IPriceOracle(_oracleAddress);
    }

    function updateStandardFee(bytes32 poolId, uint256 newFee) external onlyOwner {
        require(pools[poolId].tokenA != address(0), "QLX: Pool does not exist");
        require(newFee < 1000, "QLX: Fee must be less than 100%");
        pools[poolId].standardFee = 1000 - newFee; // Store as (1000 - fee_basis_points)
    }

    function updateLeapSwapFeeMultiplier(bytes32 poolId, uint256 multiplier) external onlyOwner {
        require(pools[poolId].tokenA != address(0), "QLX: Pool does not exist");
        require(multiplier > 0, "QLX: Multiplier must be positive");
        pools[poolId].leapFeeMultiplier = multiplier; // Store as basis points (e.g., 1100 for 1.1x)
    }

    function updatePredictionSwapDiscount(bytes32 poolId, uint256 discountPercentage) external onlyOwner {
        require(pools[poolId].tokenA != address(0), "QLX: Pool does not exist");
        require(discountPercentage <= 100, "QLX: Discount cannot exceed 100%");
        pools[poolId].predictionSwapDiscount = discountPercentage; // Store as percentage (e.g., 5 for 5%)
    }

    function withdrawProtocolFees(address token) external onlyOwner {
        uint256 amount = protocolFees[token];
        require(amount > 0, "QLX: No fees to withdraw");
        protocolFees[token] = 0;
        IERC20(token).transfer(owner, amount);
        emit ProtocolFeesCollected(token, amount);
    }

    function pause() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    // --- Pool Management ---
    function createPool(address tokenA, address tokenB) external onlyOwner {
        require(tokenA != address(0) && tokenB != address(0), "QLX: Zero address");
        require(tokenA != tokenB, "QLX: Tokens must be different");
        require(isSupportedToken[tokenA] && isSupportedToken[tokenB], "QLX: Tokens not supported");

        bytes32 poolId = keccak256(abi.encodePacked(tokenA < tokenB ? tokenA : tokenB, tokenA < tokenB ? tokenB : tokenA));
        require(pools[poolId].tokenA == address(0), "QLX: Pool already exists");

        pools[poolId] = Pool({
            tokenA: tokenA < tokenB ? tokenA : tokenB,
            tokenB: tokenA < tokenB ? tokenB : tokenA,
            reserveA: 0,
            reserveB: 0,
            kLast: 0,
            standardFee: 997, // Default 0.3% fee
            leapFeeMultiplier: 1000, // Default 1x multiplier (same as standard)
            predictionSwapDiscount: 0 // Default 0% discount
        });
        poolIds.push(poolId);

        emit PoolCreated(poolId, pools[poolId].tokenA, pools[poolId].tokenB);
    }

    // --- Liquidity Provision (Standard, Prediction, Time-Locked) ---

    function addLiquidity(bytes32 poolId, uint256 amountA, uint256 amountB) external whenNotPaused returns (uint256 tokenId) {
        Pool storage pool = pools[poolId];
        require(pool.tokenA != address(0), "QLX: Pool does not exist");
        require(amountA > 0 && amountB > 0, "QLX: Amounts must be > 0");

        // Transfer tokens to the pool
        IERC20(pool.tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(pool.tokenB).transferFrom(msg.sender, address(this), amountB);

        uint256 initialReserveA = pool.reserveA;
        uint256 initialReserveB = pool.reserveB;

        // Update reserves before minting
        pool.reserveA = initialReserveA.add(amountA);
        pool.reserveB = initialReserveB.add(amountB);

        // Mint Position NFT
        tokenId = _mintPosition(msg.sender, poolId, PositionType.StandardLP, amountA, amountB);

        // Update kLast for fee calculation tracking (Uniswap v2 logic)
        uint256 currentK = pool.reserveA.mul(pool.reserveB);
        if (pool.kLast > 0) {
             uint256 feeProtocol = currentK.sub(pool.kLast).div(pool.kLast).div(10); // Simplified protocol fee (0.1% of change in K)
             if (feeProtocol > 0) {
                 // This fee calculation is simplified. A real AMM would calculate fees based on swap volume.
                 // For this example, we track K like Uniswap V2 but don't implement the complex fee logic based on K.
                 // Protocol fees are accumulated directly during swaps. kLast is primarily for this (simplified) tracking.
             }
        }
        pool.kLast = currentK;


        emit LiquidityAdded(tokenId, poolId, msg.sender, PositionType.StandardLP, amountA, amountB);
    }

     function removeLiquidity(uint256 tokenId) external whenNotPaused returns (uint256 amountA, uint256 amountB) {
        Position storage pos = positions[tokenId];
        require(_exists(tokenId), "QLX: Invalid token ID");
        require(_isApprovedOrOwner(msg.sender, tokenId), "QLX: Not approved or owner");
        require(pos.positionType == PositionType.StandardLP, "QLX: Not a standard LP position");

        Pool storage pool = pools[pos.poolId];
        require(pool.tokenA != address(0), "QLX: Pool does not exist");

        // Calculate share of reserves based on initial deposit relative to total reserves when deposited.
        // This is an oversimplification. A real AMM calculates share based on LP token burned relative to total supply.
        // Since we use NFTs, we need to track the *proportion* each NFT represents. Let's simplify:
        // Assume the NFT represents the exact 'amountA' and 'amountB' initially deposited *plus* accumulated fees proportional to the initial share.
        // A proper implementation would track shares relative to total pool 'shares' or 'liquidity tokens' represented by the NFT.
        // For this complex example, we'll approximate by returning initial deposit plus a simplified share of current reserves based on initial ratio.
        // THIS IS NOT how production AMMs calculate withdrawal and is a simplification for concept demonstration.

        // Get current reserves
        uint256 currentReserveA = pool.reserveA;
        uint256 currentReserveB = pool.reserveB;

        // Avoid division by zero if pool is empty (shouldn't happen if NFT exists)
        if (currentReserveA == 0 || currentReserveB == 0) {
             amountA = pos.amountA; // Return initial deposit if pool is empty
             amountB = pos.amountB;
        } else {
             // Calculate share based on initial deposit ratio relative to current total reserves
             // This calculation is incorrect for fee accrual but works for demonstrating concept.
             // Correct would be: (pos.amountA * currentReserveA) / initialTotalPoolLiquidityAtDeposit
             // Let's use the initial deposit proportion relative to total pool size *at withdrawal* (simplified):
             // This logic is flawed for fee distribution across LPs, but demonstrates removing *some* amount.
             // A real implementation would need to track LP shares properly, maybe via an internal token mechanism.
             // Given the complexity constraint and desire for unique concepts, this simplification is necessary.
             // The *idea* is you get back your share, not necessarily just the initial deposit.
             // To make it slightly more realistic, let's pretend `pos.amountA` and `pos.amountB`
             // already include accumulated fees proportional to their share (which is hard to track per NFT).
             // So, we'll just return the amounts stored in the position struct as if they were updated.
             // A production system would need a much more robust share calculation.
             amountA = pos.amountA; // Simplified: Assume pos.amountA/B includes accrued value
             amountB = pos.amountB;
        }

        // Deduct from reserves
        pool.reserveA = pool.reserveA.sub(amountA);
        pool.reserveB = pool.reserveB.sub(amountB);

        // Burn Position NFT
        _burnPosition(tokenId);

        emit LiquidityRemoved(tokenId, pos.poolId, msg.sender, PositionType.StandardLP, amountA, amountB);

        // Transfer tokens back to user
        IERC20(pool.tokenA).transfer(msg.sender, amountA);
        IERC20(pool.tokenB).transfer(msg.sender, amountB);

        return (amountA, amountB);
    }


    function createPredictionVault(
        bytes32 poolId,
        address depositToken, // Token being deposited into the vault (e.g., depositing USDC to predict ETH price)
        uint256 depositAmount,
        int256 priceTarget,
        address conditionToken, // Which token in the pair the target price is relative to
        ComparisonType comparison, // > or < target
        uint256 duration // Duration the vault is active
    ) external whenNotPaused returns (uint256 tokenId) {
        Pool storage pool = pools[poolId];
        require(pool.tokenA != address(0), "QLX: Pool does not exist");
        require(depositAmount > 0, "QLX: Deposit amount must be > 0");
        require(duration > 0, "QLX: Duration must be > 0");
        require(depositToken == pool.tokenA || depositToken == pool.tokenB, "QLX: Deposit token not in pool");
        require(conditionToken == pool.tokenA || conditionToken == pool.tokenB, "QLX: Condition token not in pool");
        require(depositToken != conditionToken, "QLX: Condition token cannot be the deposit token");

        // Transfer tokens to the contract
        IERC20(depositToken).transferFrom(msg.sender, address(this), depositAmount);

        // Mint Prediction Vault NFT
        tokenId = _nextTokenId++;
        _tokenOwners[tokenId] = msg.sender;
        _balanceOf[msg.sender]++;

        // Store Position data
        positions[tokenId] = Position({
            positionType: PositionType.PredictionVault,
            poolId: poolId,
            owner: msg.sender,
            amountA: depositToken == pool.tokenA ? depositAmount : 0,
            amountB: depositToken == pool.tokenB ? depositAmount : 0,
            mintTimestamp: block.timestamp,
            lastInteractionTimestamp: block.timestamp
        });

        // Store Prediction Vault specific data
        predictionVaults[tokenId] = PredictionVaultData({
            priceTarget: priceTarget,
            conditionToken: conditionToken,
            comparison: comparison,
            startTime: block.timestamp,
            endTime: block.timestamp.add(duration),
            conditionMet: false, // Initialize as false
            claimed: false
        });

        emit LiquidityAdded(tokenId, poolId, msg.sender, PositionType.PredictionVault, depositToken == pool.tokenA ? depositAmount : 0, depositToken == pool.tokenB ? depositAmount : 0);
        emit Transfer(address(0), msg.sender, tokenId);

        return tokenId;
    }

    function checkPredictionVaultCondition(uint256 tokenId) public view returns (bool met, int256 currentPrice) {
        PredictionVaultData storage vault = predictionVaults[tokenId];
        require(positions[tokenId].positionType == PositionType.PredictionVault, "QLX: Not a prediction vault");
        require(!vault.claimed, "QLX: Vault claimed");

        // Check if within the active window
        if (block.timestamp < vault.startTime || block.timestamp > vault.endTime) {
            return (false, 0); // Condition cannot be met outside the window
        }

        // Get price from oracle (price of conditionToken relative to the other token in the pair)
        Pool storage pool = pools[positions[tokenId].poolId];
        address tokenA = pool.tokenA;
        address tokenB = pool.tokenB;
        address baseToken = vault.conditionToken;
        address quoteToken = baseToken == tokenA ? tokenB : tokenA; // The token price is quoted in

        // Oracle returns price of baseToken in terms of quoteToken
        (currentPrice, ) = oracle.getLatestPrice(baseToken, quoteToken);

        // Check condition
        met = false;
        if (vault.comparison == ComparisonType.GreaterThan) {
            met = currentPrice > vault.priceTarget;
        } else if (vault.comparison == ComparisonType.LessThan) {
            met = currentPrice < vault.priceTarget;
        }

        return (met, currentPrice);
    }

    // Simplified execution: This function allows *any* swapper to utilize Prediction Vault liquidity
    // *if* the condition for that vault is met. The discount is applied to the swapper.
    // This is a simplified interaction model for demonstration. A more complex model could
    // involve the swapper needing to reference the vault NFT, or the vault owner
    // manually enabling the liquidity or claiming a bonus.
    // For this version, if the condition is met, the vault's deposited token amounts
    // are considered "available" to be swapped against via this function, receiving a swap discount.
    function executePredictionSwap(
        bytes32 poolId,
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin // Slippage control
    ) external whenNotPaused returns (uint256 amountOut) {
        Pool storage pool = pools[poolId];
        require(pool.tokenA != address(0), "QLX: Pool does not exist");
        require(tokenIn == pool.tokenA || tokenIn == pool.tokenB, "QLX: Token not in pool");
        require(amountIn > 0, "QLX: Amount in must be > 0");

        address tokenOut = tokenIn == pool.tokenA ? pool.tokenB : pool.tokenA;

        // Identify Prediction Vaults in this pool whose conditions are met and not claimed
        // (This requires iterating or using a more complex indexing system in production)
        // For simplicity here, we assume we can find *some* eligible PV liquidity.
        // A real implementation would need to manage this pool of 'available' PV liquidity.

        // Check if *any* prediction vault in this pool has its condition met
        // This is a placeholder check. A real system would need to track *which* vaults are met.
        bool conditionMetForPool = false; // Placeholder logic
        // In a real contract, you'd likely have a mapping or list of active PV NFTs per pool
        // and iterate through them or query a state variable updated by an off-chain relayer
        // or keeper network that calls `checkPredictionVaultCondition` and flags vaults.
        // For this example, we'll simulate that the oracle check makes liquidity "available"
        // conceptually, and the swap logic just needs to know *if* enough met liquidity exists.

        // Let's simplify: Assume `checkAnyPredictionVaultMet(poolId)` function exists (not implemented for brevity/gas)
        // require(checkAnyPredictionVaultMet(poolId), "QLX: No prediction vault condition met");
        // Since we can't easily check *all* vaults efficiently on-chain, let's change the mechanic:
        // `executePredictionSwap` *requires* the caller to specify a VALID Prediction Vault NFT ID
        // whose condition is met AND which holds the token *being swapped OUT*.
        // This is still complex. Let's revert to the simplest model: Prediction Swaps just
        // use the *general* pool liquidity, but IF there is *any* PV liquidity whose condition
        // *is currently met* (checked via oracle), the swap receives a discount. This incentivizes PVs indirectly.

        bool anyPVMet = false; // Assume we have a way to know this, perhaps updated by a keeper calling checkPredictionVaultCondition.
        // In a real contract, managing the state of Prediction Vaults being 'met' requires a robust system.
        // For this demonstration, we'll simulate the potential for a discount if ANY vault *could* be met.
        // This isn't fully functional but shows the *intent* of variable rates.

        uint256 effectiveFee = pool.standardFee;
        if (anyPVMet) { // Simplified check: assume a mechanism exists to know if any PV is met
            // Apply discount
            uint256 feeAmount = amountIn.mul(1000 - pool.standardFee).div(pool.standardFee); // Calculate base fee
            uint256 discount = feeAmount.mul(pool.predictionSwapDiscount).div(100); // Calculate discount amount
            uint256 discountedFee = feeAmount.sub(discount); // Apply discount
            effectiveFee = 1000 - discountedFee.mul(pool.standardFee).div(amountIn); // Re-calculate effective fee basis points (approximation)
        }

        // Perform swap using standard XY=K logic with the effective fee
        uint256 amountInWithFee = amountIn.mul(effectiveFee).div(1000);
        uint256 inputReserve = (tokenIn == pool.tokenA) ? pool.reserveA : pool.reserveB;
        uint256 outputReserve = (tokenIn == pool.tokenA) ? pool.reserveB : pool.reserveA;

        // Calculate output amount (simplified XY=K)
        // (inputReserve + amountInWithFee) * (outputReserve - amountOut) = inputReserve * outputReserve
        // outputReserve - amountOut = (inputReserve * outputReserve) / (inputReserve + amountInWithFee)
        // amountOut = outputReserve - (inputReserve * outputReserve) / (inputReserve + amountInWithFee)
        amountOut = outputReserve.sub(inputReserve.mul(outputReserve).div(inputReserve.add(amountInWithFee)));

        require(amountOut >= amountOutMin, "QLX: Insufficient output amount (slippage)");

        // Transfer tokens into the pool
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        // Update reserves
        if (tokenIn == pool.tokenA) {
            pool.reserveA = pool.reserveA.add(amountIn);
            pool.reserveB = pool.reserveB.sub(amountOut);
        } else {
            pool.reserveB = pool.reserveB.add(amountIn);
            pool.reserveA = pool.reserveA.sub(amountOut);
        }

        // Update kLast (simplified, doesn't capture exact fee calculation per swap)
        pool.kLast = pool.reserveA.mul(pool.reserveB);

        // Accumulate protocol fees (simplified - a portion of the fee)
        uint256 totalFeePaid = amountIn.sub(amountInWithFee); // This is the fee amount in tokenIn
        protocolFees[tokenIn] = protocolFees[tokenIn].add(totalFeePaid.div(10)); // 10% protocol fee (example)

        // Transfer output tokens to the swapper
        IERC20(tokenOut).transfer(msg.sender, amountOut);

        emit SwapExecuted(poolId, msg.sender, tokenIn, amountIn, tokenOut, amountOut, PositionType.PredictionVault);

        return amountOut;
    }


    function claimFromPredictionVault(uint256 tokenId) external whenNotPaused {
        Position storage pos = positions[tokenId];
        PredictionVaultData storage vault = predictionVaults[tokenId];
        require(_isApprovedOrOwner(msg.sender, tokenId), "QLX: Not approved or owner");
        require(pos.positionType == PositionType.PredictionVault, "QLX: Not a prediction vault");
        require(!vault.claimed, "QLX: Vault already claimed");
        require(block.timestamp > vault.endTime, "QLX: Vault time window not expired");

        // Condition not met -> reclaim deposited tokens
        // If condition WAS met and liquidity used, logic would be different (e.g., claim proportional swap fees/output tokens)
        // For this simplified model, if the window expired and condition wasn't met, claim original deposit.
        // If condition WAS met *and* liquidity was utilized by a swap (which is hard to track per vault here),
        // the vault would conceptually hold the swapped-for tokens + share of fees.
        // Let's assume for this basic demo, if the window expires AND condition was NOT met, they get deposit back.
        // If window expires AND condition WAS met (detected earlier), they'd get something else (requires complex state tracking).
        // For simplicity: after end time, if condition not met, claim original deposit. If condition WAS met, user needs a different claim function or gets tokens credited differently.

        bool conditionMetDuringWindow = vault.conditionMet; // Check the flag set earlier (conceptually)

        uint256 amountA = pos.amountA;
        uint256 amountB = pos.amountB;

        if (conditionMetDuringWindow) {
            // This state should ideally mean the vault liquidity was used in a swap.
            // The vault NFT should then represent a claim on the tokens received from the swap + fees.
            // Implementing this state transition and claim logic is complex.
            // For this demo, let's prevent claiming this way if condition was met.
            // A 'claimAfterSwap' function would be needed.
            revert("QLX: Condition was met. Use specific claim function (not implemented)");
        } else {
             // Condition was NOT met by end time. Claim original deposit.
             require(block.timestamp > vault.endTime, "QLX: Vault time window not expired");

             // Transfer tokens back to owner
             if (amountA > 0) IERC20(pools[pos.poolId].tokenA).transfer(msg.sender, amountA);
             if (amountB > 0) IERC20(pools[pos.poolId].tokenB).transfer(msg.sender, amountB);
        }

        vault.claimed = true;
        pos.lastInteractionTimestamp = block.timestamp;

        emit LiquidityRemoved(tokenId, pos.poolId, msg.sender, PositionType.PredictionVault, amountA, amountB);
        // We don't burn the NFT immediately, allowing it to remain as proof/history, but it's marked as claimed.
        // _burnPosition(tokenId); // Could burn here if preferred
    }

    function cancelPredictionVault(uint256 tokenId) external whenNotPaused {
        Position storage pos = positions[tokenId];
        PredictionVaultData storage vault = predictionVaults[tokenId];
        require(_isApprovedOrOwner(msg.sender, tokenId), "QLX: Not approved or owner");
        require(pos.positionType == PositionType.PredictionVault, "QLX: Not a prediction vault");
        require(!vault.claimed, "QLX: Vault already claimed");
        require(block.timestamp < vault.endTime, "QLX: Vault time window expired"); // Must cancel before end

        // Optional: Apply a penalty for early withdrawal
        uint256 penaltyPercentage = 5; // Example: 5% penalty
        uint256 amountA = pos.amountA;
        uint256 amountB = pos.amountB;

        uint256 penaltyA = amountA.mul(penaltyPercentage).div(100);
        uint256 penaltyB = amountB.mul(penaltyPercentage).div(100);

        uint256 returnA = amountA.sub(penaltyA);
        uint256 returnB = amountB.sub(penaltyB);

        // Accumulate penalty as protocol fees
        if (penaltyA > 0) protocolFees[pools[pos.poolId].tokenA] = protocolFees[pools[pos.poolId].tokenA].add(penaltyA);
        if (penaltyB > 0) protocolFees[pools[pos.poolId].tokenB] = protocolFees[pools[pos.poolId].tokenB].add(penaltyB);


        // Transfer tokens back to owner (minus penalty)
        if (returnA > 0) IERC20(pools[pos.poolId].tokenA).transfer(msg.sender, returnA);
        if (returnB > 0) IERC20(pools[pos.poolId].tokenB).transfer(msg.sender, returnB);

        vault.claimed = true; // Mark as claimed/cancelled
        pos.lastInteractionTimestamp = block.timestamp;

        emit LiquidityRemoved(tokenId, pos.poolId, msg.sender, PositionType.PredictionVault, returnA, returnB); // Event shows returned amount
        // _burnPosition(tokenId); // Could burn here
    }


    function createTimeLockedPool(
        bytes32 poolId,
        uint256 amountA,
        uint256 amountB,
        uint256 lockDuration
    ) external whenNotPaused returns (uint256 tokenId) {
        Pool storage pool = pools[poolId];
        require(pool.tokenA != address(0), "QLX: Pool does not exist");
        require(amountA > 0 && amountB > 0, "QLX: Amounts must be > 0");
        require(lockDuration > 0, "QLX: Lock duration must be > 0");

        // Transfer tokens to the pool
        IERC20(pool.tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(pool.tokenB).transferFrom(msg.sender, address(this), amountB);

         // Note: Time-Locked pools don't add to the *standard* reserve for standard swaps.
         // Their liquidity is only available for Leap Swaps.
         // This requires separate tracking of Time-Locked reserves per pool.
         // To simplify and stick to the Pool struct, we'll conceptually say these amounts are held
         // by the contract but not part of `pool.reserveA/B` used by `swap()`.
         // A production system would need `timeLockedReserveA`, `timeLockedReserveB` etc. per pool.
         // For this demo, we store the amounts in the Position struct and use that.

        // Mint Position NFT
        tokenId = _nextTokenId++;
        _tokenOwners[tokenId] = msg.sender;
        _balanceOf[msg.sender]++;


        // Store Position data
        positions[tokenId] = Position({
            positionType: PositionType.TimeLocked,
            poolId: poolId,
            owner: msg.sender,
            amountA: amountA,
            amountB: amountB,
            mintTimestamp: block.timestamp,
            lastInteractionTimestamp: block.timestamp
        });

        // Store Time-Locked specific data
        timeLockedPools[tokenId] = TimeLockedData({
            lockDuration: lockDuration,
            endTime: block.timestamp.add(lockDuration),
            claimed: false
        });


        emit LiquidityAdded(tokenId, poolId, msg.sender, PositionType.TimeLocked, amountA, amountB);
        emit Transfer(address(0), msg.sender, tokenId);

        return tokenId;
    }


    // Simplified execution: This function uses liquidity from *any* available Time-Locked Pool
    // in the pool. It might apply a different fee based on the pool's leapFeeMultiplier.
    // A more complex model could require specifying the TL NFT ID.
     function executeLeapSwap(
        bytes32 poolId,
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin // Slippage control
    ) external whenNotPaused returns (uint256 amountOut) {
         Pool storage pool = pools[poolId];
        require(pool.tokenA != address(0), "QLX: Pool does not exist");
        require(tokenIn == pool.tokenA || tokenIn == pool.tokenB, "QLX: Token not in pool");
        require(amountIn > 0, "QLX: Amount in must be > 0");

        // This swap uses liquidity from Time-Locked positions *only*.
        // This requires tracking TL reserves separately from standard reserves.
        // Since we don't have separate TL reserves per pool in the struct (for simplicity),
        // this function is conceptual. In a real implementation, it would use
        // the sum of unlocked amounts from all active TL vaults in the pool.

        // For demonstration: Simulate using *some* TL liquidity. The rate calculation
        // will use the standard pool reserves but apply the Leap multiplier fee.
        // This is NOT how it would work if TL liquidity was truly separate.
        // Correct implementation would need separate pool state for TL reserves.

        address tokenOut = tokenIn == pool.tokenA ? pool.tokenB : pool.tokenA;

        // Calculate fee using leapFeeMultiplier
        uint256 standardFeeAmount = amountIn.mul(1000 - pool.standardFee).div(pool.standardFee); // Fee based on standard rate
        uint256 leapFeeAmount = standardFeeAmount.mul(pool.leapFeeMultiplier).div(1000); // Apply multiplier
        uint256 effectiveFee = 1000 - leapFeeAmount.mul(pool.standardFee).div(amountIn); // Re-calculate effective fee basis points (approximation)


        // Perform swap using standard XY=K logic but with the effective Leap fee
        uint256 amountInWithFee = amountIn.mul(effectiveFee).div(1000);
        uint256 inputReserve = (tokenIn == pool.tokenA) ? pool.reserveA : pool.reserveB; // Using standard reserves for calculation, but liquidity comes from TL conceptually
        uint256 outputReserve = (tokenIn == pool.tokenA) ? pool.reserveB : pool.reserveA;

        // Calculate output amount (simplified XY=K)
        amountOut = outputReserve.sub(inputReserve.mul(outputReserve).div(inputReserve.add(amountInWithFee)));

        require(amountOut >= amountOutMin, "QLX: Insufficient output amount (slippage)");

        // Transfer tokens into the contract (represent the swap using TL liquidity)
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        // In a real system, this amountIn would be added to TL reserve, amountOut subtracted.
        // Here, we don't touch standard reserves. This is purely conceptual swap logic using a different fee.
        // The actual tokens involved would come/go from the contract's overall balance,
        // and need to be reconciled against individual TL positions later.

        // Accumulate protocol fees (simplified - a portion of the fee)
        uint256 totalFeePaid = amountIn.sub(amountInWithFee); // This is the fee amount in tokenIn
        protocolFees[tokenIn] = protocolFees[tokenIn].add(totalFeePaid.div(10)); // 10% protocol fee (example)

        // Transfer output tokens to the swapper
        IERC20(tokenOut).transfer(msg.sender, amountOut);

        emit SwapExecuted(poolId, msg.sender, tokenIn, amountIn, tokenOut, amountOut, PositionType.TimeLocked);

        return amountOut;
    }

    function claimFromTimeLockedPool(uint256 tokenId) external whenNotPaused {
        Position storage pos = positions[tokenId];
        TimeLockedData storage locked = timeLockedPools[tokenId];
        require(_isApprovedOrOwner(msg.sender, tokenId), "QLX: Not approved or owner");
        require(pos.positionType == PositionType.TimeLocked, "QLX: Not a time-locked position");
        require(!locked.claimed, "QLX: Position already claimed");
        require(block.timestamp >= locked.endTime, "QLX: Lock duration not expired");

        uint256 amountA = pos.amountA;
        uint256 amountB = pos.amountB;

        // In a real system, this would include accumulated fees proportional to the TL position's contribution.
        // For this demo, we return the initial deposited amount + simplified assumed fees.
        // A real system would track the pool share represented by this TL NFT and calculate
        // the current value based on pool reserves and accumulated fees.

        // For demonstration, let's return the initial amount plus a hypothetical fixed fee percentage.
        // This is a simplified model.
        uint256 hypotheticalFeesA = amountA.div(100); // Example: 1% hypothetical fee earned
        uint256 hypotheticalFeesB = amountB.div(100); // Example: 1% hypothetical fee earned

        uint256 returnA = amountA.add(hypotheticalFeesA);
        uint256 returnB = amountB.add(hypotheticalFeesB);


        // Transfer tokens back to owner
        if (returnA > 0) IERC20(pools[pos.poolId].tokenA).transfer(msg.sender, returnA);
        if (returnB > 0) IERC20(pools[pos.poolId].tokenB).transfer(msg.sender, returnB);

        locked.claimed = true;
        pos.lastInteractionTimestamp = block.timestamp;

        emit LiquidityRemoved(tokenId, pos.poolId, msg.sender, PositionType.TimeLocked, returnA, returnB); // Event shows returned amount
        // _burnPosition(tokenId); // Could burn here
    }

    function extendTimeLockedPool(uint256 tokenId, uint256 additionalDuration) external whenNotPaused {
         Position storage pos = positions[tokenId];
        TimeLockedData storage locked = timeLockedPools[tokenId];
        require(_isApprovedOrOwner(msg.sender, tokenId), "QLX: Not approved or owner");
        require(pos.positionType == PositionType.TimeLocked, "QLX: Not a time-locked position");
        require(!locked.claimed, "QLX: Position already claimed");
        require(additionalDuration > 0, "QLX: Additional duration must be > 0");

        // Extend the end time from the current end time, or from now if already expired but not claimed
        uint256 newEndTime = locked.endTime > block.timestamp ? locked.endTime.add(additionalDuration) : block.timestamp.add(additionalDuration);
        locked.endTime = newEndTime;

        // Optional: Incentivize extending lock (e.g., small bonus, not implemented here)

        pos.lastInteractionTimestamp = block.timestamp; // Mark interaction

        // No specific event for extend, consider using LiquidityAdded with 0 amounts or custom event
    }


    // --- Swap Function (Standard XY=K) ---

    function swap(
        bytes32 poolId,
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin // Slippage control
    ) external whenNotPaused returns (uint256 amountOut) {
        Pool storage pool = pools[poolId];
        require(pool.tokenA != address(0), "QLX: Pool does not exist");
        require(tokenIn == pool.tokenA || tokenIn == pool.tokenB, "QLX: Token not in pool");
        require(amountIn > 0, "QLX: Amount in must be > 0");

        address tokenOut = tokenIn == pool.tokenA ? pool.tokenB : pool.tokenA;

        // Calculate output amount with fee
        uint256 amountInWithFee = amountIn.mul(pool.standardFee).div(1000);
        uint256 inputReserve = (tokenIn == pool.tokenA) ? pool.reserveA : pool.reserveB;
        uint256 outputReserve = (tokenIn == pool.tokenA) ? pool.reserveB : pool.reserveA;

        // amountOut = (amountInWithFee * outputReserve) / (inputReserve + amountInWithFee)
        amountOut = amountInWithFee.mul(outputReserve).div(inputReserve.add(amountInWithFee));

        require(amountOut >= amountOutMin, "QLX: Insufficient output amount (slippage)");

        // Transfer tokens into the pool
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        // Update reserves
        if (tokenIn == pool.tokenA) {
            pool.reserveA = pool.reserveA.add(amountIn);
            pool.reserveB = pool.reserveB.sub(amountOut);
        } else {
            pool.reserveB = pool.reserveB.add(amountIn);
            pool.reserveA = pool.reserveA.sub(amountOut);
        }

        // Update kLast (simplified, doesn't capture exact fee calculation per swap)
        pool.kLast = pool.reserveA.mul(pool.reserveB);

        // Accumulate protocol fees (simplified - a portion of the fee)
        uint256 totalFeePaid = amountIn.sub(amountInWithFee); // This is the fee amount in tokenIn
        protocolFees[tokenIn] = protocolFees[tokenIn].add(totalFeePaid.div(10)); // Example: 10% of fee goes to protocol


        // Transfer output tokens to the swapper
        IERC20(tokenOut).transfer(msg.sender, amountOut);

        emit SwapExecuted(poolId, msg.sender, tokenIn, amountIn, tokenOut, amountOut, PositionType.StandardLP);

        return amountOut;
    }

    // --- Position NFT Management ---

    function splitPositionNFT(uint256 tokenId, uint256 percentage) external whenNotPaused returns (uint256 newTokenId1, uint256 newTokenId2) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "QLX: Not approved or owner");
        require(percentage > 0 && percentage < 100, "QLX: Percentage must be between 1 and 99");

        Position storage pos = positions[tokenId];
        bytes32 poolId = pos.poolId;
        PositionType posType = pos.positionType;
        address originalOwner = pos.owner; // Store owner before burning

        // Calculate amounts for the split
        uint256 amountA1 = pos.amountA.mul(percentage).div(100);
        uint256 amountB1 = pos.amountB.mul(percentage).div(100);

        uint256 amountA2 = pos.amountA.sub(amountA1);
        uint256 amountB2 = pos.amountB.sub(amountB1);

        require(amountA1 > 0 || amountB1 > 0, "QLX: Split amounts must be > 0");
        require(amountA2 > 0 || amountB2 > 0, "QLX: Remaining amounts must be > 0");

        // Burn the original NFT
        _burnPosition(tokenId);

        // Mint two new NFTs representing the split shares
        newTokenId1 = _mintPosition(originalOwner, poolId, posType, amountA1, amountB1);
        newTokenId2 = _mintPosition(originalOwner, poolId, posType, amountA2, amountB2);

        // Copy specific data for Prediction Vaults or Time-Locked Pools
        if (posType == PositionType.PredictionVault) {
             PredictionVaultData storage originalVault = predictionVaults[tokenId];
             predictionVaults[newTokenId1] = PredictionVaultData(
                 originalVault.priceTarget,
                 originalVault.conditionToken,
                 originalVault.comparison,
                 originalVault.startTime,
                 originalVault.endTime,
                 originalVault.conditionMet,
                 originalVault.claimed // Note: Claimed status applies to the 'original' state
             );
             predictionVaults[newTokenId2] = PredictionVaultData(
                 originalVault.priceTarget,
                 originalVault.conditionToken,
                 originalVault.comparison,
                 originalVault.startTime,
                 originalVault.endTime,
                 originalVault.conditionMet,
                 originalVault.claimed
             );
             // WARNING: Splitting claimed or condition-met PVs is complex. This simplified logic
             // copies the flags. Real logic needs to handle what the new NFTs represent (e.g., claim on proportion of output).
             // For this demo, assume splitting only happens on active, unclaimed vaults.
        } else if (posType == PositionType.TimeLocked) {
             TimeLockedData storage originalLocked = timeLockedPools[tokenId];
             timeLockedPools[newTokenId1] = TimeLockedData(
                 originalLocked.lockDuration,
                 originalLocked.endTime,
                 originalLocked.claimed // Note: Claimed status applies to the 'original' state
             );
              timeLockedPools[newTokenId2] = TimeLockedData(
                 originalLocked.lockDuration,
                 originalLocked.endTime,
                 originalLocked.claimed
             );
             // WARNING: Splitting claimed TLs is complex. Assume splitting only on active, unclaimed.
        }


        emit PositionSplit(tokenId, newTokenId1, newTokenId2);
        return (newTokenId1, newTokenId2);
    }

    function mergePositionNFTs(uint256[] calldata tokenIds) external whenNotPaused returns (uint256 newTokenId) {
        require(tokenIds.length > 1, "QLX: Need at least two tokens to merge");

        bytes32 poolId;
        PositionType posType = PositionType.StandardLP; // Default

        uint256 totalAmountA = 0;
        uint256 totalAmountB = 0;

        // Validate tokens and sum amounts
        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(_exists(tokenId), "QLX: Invalid token ID in list");
            require(_isApprovedOrOwner(msg.sender, tokenId), "QLX: Not approved or owner for token");

            Position storage pos = positions[tokenId];

            if (i == 0) {
                poolId = pos.poolId;
                posType = pos.positionType;
                // Add additional checks for PV/TL data consistency if merging those types (complex!)
                // For this demo, merging PV/TL NFTs with different parameters (target, duration) is disallowed conceptually.
            } else {
                require(pos.poolId == poolId, "QLX: Tokens must be from the same pool");
                require(pos.positionType == posType, "QLX: Tokens must be of the same position type");
                // Add additional checks here for PV/TL data consistency (e.g., same price target, same lock end time or merge strategy)
                // For demo simplicity, we assume merge only applies to tokens with compatible PV/TL data or only StandardLPs.
            }

            totalAmountA = totalAmountA.add(pos.amountA);
            totalAmountB = totalAmountB.add(pos.amountB);
        }

         // Burn the original NFTs
        for (uint i = 0; i < tokenIds.length; i++) {
             _burnPosition(tokenIds[i]);
        }

        // Mint a new NFT representing the merged amounts
        newTokenId = _mintPosition(msg.sender, poolId, posType, totalAmountA, totalAmountB);

        // Handle specific data for PV/TL (complex merging rules, simplified copying first valid token's data)
        // A real implementation needs careful consideration of merging PV/TL data (e.g., average target? shortest lock? longest lock?)
        if (posType == PositionType.PredictionVault && tokenIds.length > 0) {
             PredictionVaultData storage firstVault = predictionVaults[tokenIds[0]]; // Use data from the first token (simplification)
             predictionVaults[newTokenId] = PredictionVaultData(
                 firstVault.priceTarget,
                 firstVault.conditionToken,
                 firstVault.comparison,
                 firstVault.startTime, // Keep start time of first vault? Or merge strategy?
                 firstVault.endTime, // Keep end time of first vault? Or merge strategy?
                 firstVault.conditionMet, // Check if *any* merged vault was met?
                 firstVault.claimed // Check if *all* merged vaults were claimed?
             );
             // WARNING: Merging PVs with different parameters is complex and simplified here.
        } else if (posType == PositionType.TimeLocked && tokenIds.length > 0) {
            TimeLockedData storage firstLocked = timeLockedPools[tokenIds[0]]; // Use data from the first token (simplification)
            // Merging TLs: The lock should respect the *latest* end time among the merged positions.
            uint256 latestEndTime = 0;
             for (uint i = 0; i < tokenIds.length; i++) {
                 if(timeLockedPools[tokenIds[i]].endTime > latestEndTime) {
                     latestEndTime = timeLockedPools[tokenIds[i]].endTime;
                 }
             }
             timeLockedPools[newTokenId] = TimeLockedData(
                 latestEndTime.sub(block.timestamp), // Calculate remaining duration from NOW to latest end time
                 latestEndTime,
                 false // New merged position is not claimed (unless all originals were claimed)
             );
            // WARNING: Merging claimed TLs is complex and simplified here. Assume merging only active, unclaimed.
        }


        emit PositionMerged(tokenIds, newTokenId);
        return newTokenId;
    }


    // --- View Functions ---

    function getPoolState(bytes32 poolId) public view returns (address tokenA, address tokenB, uint256 reserveA, uint256 reserveB, uint256 standardFee, uint256 leapFeeMultiplier, uint256 predictionSwapDiscount) {
         Pool storage pool = pools[poolId];
         require(pool.tokenA != address(0), "QLX: Pool does not exist");
         return (pool.tokenA, pool.tokenB, pool.reserveA, pool.reserveB, 1000 - pool.standardFee, pool.leapFeeMultiplier, pool.predictionSwapDiscount); // Return fee as basis points (e.g., 3 for 0.3%)
    }

    function getPositionDetails(uint256 tokenId) public view returns (Position memory) {
        require(_exists(tokenId), "QLX: Invalid token ID");
        return positions[tokenId];
    }

    function getPredictionVaultDetails(uint256 tokenId) public view returns (PredictionVaultData memory) {
        require(positions[tokenId].positionType == PositionType.PredictionVault, "QLX: Not a prediction vault");
        return predictionVaults[tokenId];
    }

    function getTimeLockedPoolDetails(uint256 tokenId) public view returns (TimeLockedData memory) {
        require(positions[tokenId].positionType == PositionType.TimeLocked, "QLX: Not a time-locked position");
        return timeLockedPools[tokenId];
    }

     function isSupportedToken(address token) public view returns (bool) {
         return isSupportedToken[token];
     }

    function getProtocolFees(address token) public view returns (uint256) {
        return protocolFees[token];
    }

    function getPools() public view returns (bytes32[] memory) {
        return poolIds;
    }

     function calculateSwapOutput(bytes32 poolId, address tokenIn, uint256 amountIn) public view returns (uint256 amountOut) {
        Pool storage pool = pools[poolId];
        require(pool.tokenA != address(0), "QLX: Pool does not exist");
        require(tokenIn == pool.tokenA || tokenIn == pool.tokenB, "QLX: Token not in pool");
        require(amountIn > 0, "QLX: Amount in must be > 0");

        uint256 amountInWithFee = amountIn.mul(pool.standardFee).div(1000);
        uint256 inputReserve = (tokenIn == pool.tokenA) ? pool.reserveA : pool.reserveB;
        uint256 outputReserve = (tokenIn == pool.tokenA) ? pool.reserveB : pool.reserveA;

        amountOut = amountInWithFee.mul(outputReserve).div(inputReserve.add(amountInWithFee));
        return amountOut;
    }

     function calculatePredictionSwapOutput(bytes32 poolId, address tokenIn, uint256 amountIn) public view returns (uint256 amountOut) {
         Pool storage pool = pools[poolId];
        require(pool.tokenA != address(0), "QLX: Pool does not exist");
        require(tokenIn == pool.tokenA || tokenIn == pool.tokenB, "QLX: Token not in pool");
        require(amountIn > 0, "QLX: Amount in must be > 0");

        // This calculation is conceptual, assuming there *is* PV liquidity available.
        // A real system would need to check this availability.
        bool anyPVMet = true; // Simulate that a PV is met for calculation purpose

        uint256 effectiveFee = pool.standardFee;
        if (anyPVMet) {
            uint256 feeAmount = amountIn.mul(1000 - pool.standardFee).div(pool.standardFee);
            uint256 discount = feeAmount.mul(pool.predictionSwapDiscount).div(100);
            uint256 discountedFee = feeAmount.sub(discount);
            effectiveFee = 1000 - discountedFee.mul(pool.standardFee).div(amountIn);
        }

        uint256 amountInWithFee = amountIn.mul(effectiveFee).div(1000);
        uint256 inputReserve = (tokenIn == pool.tokenA) ? pool.reserveA : pool.reserveB;
        uint256 outputReserve = (tokenIn == pool.tokenA) ? pool.reserveB : pool.reserveA;

        amountOut = amountInWithFee.mul(outputReserve).div(inputReserve.add(amountInWithFee));
        return amountOut;
     }

     function calculateLeapSwapOutput(bytes32 poolId, address tokenIn, uint256 amountIn) public view returns (uint256 amountOut) {
         Pool storage pool = pools[poolId];
        require(pool.tokenA != address(0), "QLX: Pool does not exist");
        require(tokenIn == pool.tokenA || tokenIn == pool.tokenB, "QLX: Token not in pool");
        require(amountIn > 0, "QLX: Amount in must be > 0");

         // Calculate fee using leapFeeMultiplier
        uint256 standardFeeAmount = amountIn.mul(1000 - pool.standardFee).div(pool.standardFee);
        uint256 leapFeeAmount = standardFeeAmount.mul(pool.leapFeeMultiplier).div(1000);
        uint256 effectiveFee = 1000 - leapFeeAmount.mul(pool.standardFee).div(amountIn);

        uint256 amountInWithFee = amountIn.mul(effectiveFee).div(1000);
        uint256 inputReserve = (tokenIn == pool.tokenA) ? pool.reserveA : pool.reserveB;
        uint256 outputReserve = (tokenIn == pool.tokenA) ? pool.reserveB : pool.reserveA;

        amountOut = amountInWithFee.mul(outputReserve).div(inputReserve.add(amountInWithFee));
        return amountOut;
     }


    // --- Internal/Helper Functions (for embedded ERC721 and Position Logic) ---

    function _mintPosition(address to, bytes32 poolId, PositionType posType, uint256 amountA, uint256 amountB) internal returns (uint255 tokenId) {
        tokenId = _nextTokenId++;
        require(to != address(0), "ERC721: mint to the zero address");

        _tokenOwners[tokenId] = to;
        _balanceOf[to]++;

        // Store Position data
         positions[tokenId] = Position({
            positionType: posType,
            poolId: poolId,
            owner: to, // Owner is the minter initially
            amountA: amountA,
            amountB: amountB,
            mintTimestamp: block.timestamp,
            lastInteractionTimestamp: block.timestamp
        });

        emit Transfer(address(0), to, tokenId);
        return tokenId;
    }

    function _burnPosition(uint256 tokenId) internal {
        require(_exists(tokenId), "ERC721: owner query for nonexistent token");
        address owner = _tokenOwners[tokenId];

        // Clear approvals
        _approve(address(0), tokenId);

        // Update balances and ownership
        _balanceOf[owner]--;
        delete _tokenOwners[tokenId];

        // Clear position data (optional, could keep for history but costs gas)
        delete positions[tokenId];
        // Delete specific data too
         if (positions[tokenId].positionType == PositionType.PredictionVault) {
             delete predictionVaults[tokenId];
         } else if (positions[tokenId].positionType == PositionType.TimeLocked) {
             delete timeLockedPools[tokenId];
         }


        emit Transfer(owner, address(0), tokenId);
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: owner query for nonexistent token");
        address owner = _tokenOwners[tokenId];
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }


    // --- ERC721 Required Functions (Embedded Implementation) ---

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC721).interfaceId || super.supportsInterface(interfaceId);
         // Simplified: Just return true for ERC721 interface, without full ERC165 check inheritance.
         // For demo purposes, assume this is sufficient.
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balanceOf[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _tokenOwners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "ERC721: approve caller is not owner nor approved for all");

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _approve(address(0), tokenId);

        _balanceOf[from]--;
        _balanceOf[to]++;
        _tokenOwners[tokenId] = to;

        // Update the owner field in the Position struct as well
        positions[tokenId].owner = to;


        emit Transfer(from, to, tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (to.code.length == 0) {
            return true;
        }
        try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
            return retval == IERC721Receiver.onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    // --- Optional ERC721 Metadata (if implementing ERC721Metadata) ---
    // string public tokenURI(uint256 tokenId) override pure { revert("ERC721Metadata: URI query for nonexistent token"); }
    // function _setTokenURI(uint256 tokenId, string memory uri) internal {}

    // --- Optional ERC721Enumerable (if implementing ERC721Enumerable) ---
    // uint256[] private _allTokens;
    // mapping(address => uint256[]) private _ownedTokens;
    // etc. (Requires tracking token lists which adds complexity/gas)


    // --- Additional Helper Functions ---

    // Helper to get sorted token pair for pool ID
    function getPoolId(address tokenA, address tokenB) public pure returns (bytes32) {
        require(tokenA != address(0) && tokenB != address(0) && tokenA != tokenB, "QLX: Invalid token addresses for pool ID");
        return keccak256(abi.encodePacked(tokenA < tokenB ? tokenA : tokenB, tokenA < tokenB ? tokenB : tokenA));
    }
}

// Mock IERC721Receiver interface
interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}
```

**Explanation of Advanced/Creative Concepts and Functions:**

1.  **NFT-Represented Positions (ERC721 Embedding):** Instead of using fungible LP tokens (like Uniswap V2) or complex internal state tracking, *every* liquidity position (Standard, Prediction, Time-Locked) is represented by a unique ERC721 NFT (`QuantumLeapPosition`). This is a trendy pattern (e.g., Uniswap V3 non-fungible positions) but extended here to multiple liquidity types. The ERC721 logic is embedded directly in the contract to avoid simply importing OpenZeppelin.
    *   `_mintPosition`, `_burnPosition`, `_transfer`, etc., are internal functions handling the NFT lifecycle.
    *   `Position` struct stores core position data linked to the NFT ID.
    *   Functions like `addLiquidity`, `createPredictionVault`, `createTimeLockedPool` mint NFTs.
    *   Functions like `removeLiquidity`, `claimFromVault`, `claimFromTimeLockedPool` burn NFTs (or mark as claimed).

2.  **Prediction Vaults:** A novel liquidity type allowing users to deposit tokens and commit them to the exchange *if* a specific external price condition is met within a time window.
    *   `createPredictionVault`: Takes deposit token, amount, price target, condition token, comparison type (`>`, `<`), and duration. Mints a Prediction Vault NFT.
    *   `PredictionVaultData` struct stores the condition details and state (`conditionMet`, `claimed`).
    *   `checkPredictionVaultCondition`: Queries an external `IPriceOracle` to see if the condition is currently met. This is a view function, but in a real system, a keeper or relayer would call this and update the `conditionMet` flag for the vault. *Note:* The contract doesn't have a keeper mechanism; `checkPredictionVaultCondition` is just a view.
    *   `executePredictionSwap`: This is the swap function that *conceptually* uses Prediction Vault liquidity. The implementation is simplified; it performs a standard XY=K swap but applies a potential `predictionSwapDiscount` if any PV condition in that pool is met (this check `bool anyPVMet` is a simplification; a real system needs state tracking of met vaults).
    *   `claimFromPredictionVault`: Allows the PV owner to reclaim tokens *after* the window expires. Simplified: returns initial deposit if condition was NOT met. Complex logic would be needed if the condition *was* met and liquidity was used in swaps (e.g., claiming swapped tokens + fees).
    *   `cancelPredictionVault`: Allows early withdrawal before the window ends, potentially with a penalty that goes to protocol fees.

3.  **Time-Locked Pools (Leap Swaps):** Another novel liquidity type where funds are locked for a set duration. Swaps designated as "Leap Swaps" can preferentially use this liquidity and have a different fee structure.
    *   `createTimeLockedPool`: Takes liquidity amounts and a lock duration. Mints a Time-Locked Position NFT. *Note:* This liquidity isn't added to standard `reserveA`/`reserveB` in the pool struct in this simplified version; it's conceptually separate.
    *   `TimeLockedData` struct stores the lock duration and end time.
    *   `executeLeapSwap`: The swap function *conceptually* using Time-Locked liquidity. Similar to `executePredictionSwap`, the implementation is simplified; it uses the standard pool reserves for the XY=K calculation but applies a `leapFeeMultiplier` to the fee. *Note:* In a real system, this would require separate reserves for TL liquidity or a mechanism to direct swaps specifically to TL positions.
    *   `claimFromTimeLockedPool`: Allows claiming deposited tokens *after* the lock expires. Simplified: returns initial deposit + a hypothetical fee share. Real implementation would track actual fee accrual for that position.
    *   `extendTimeLockedPool`: Allows extending the lock duration of an existing TL position.

4.  **Variable Fees:** The contract introduces configurable fees (`standardFee`, `leapFeeMultiplier`, `predictionSwapDiscount`) that can be updated by the owner, allowing for dynamic fee strategies based on liquidity type or external conditions (though the external condition influence on PV fee is simplified).

5.  **Position NFT Management:** The fact that all positions are NFTs enables advanced operations.
    *   `splitPositionNFT`: Allows the owner of a position NFT to split it into two new NFTs representing a percentage split of the underlying position value (based on deposited amounts). Useful for partial transfers or claims.
    *   `mergePositionNFTs`: Allows the owner to combine multiple position NFTs of the same type and pool into a single NFT, summing the underlying amounts. Useful for consolidating positions. *Note:* Merging PV/TL positions with potentially different parameters (targets, durations, claimed status) is complex and simplified here.

6.  **Oracle Integration:** The contract has a placeholder `IPriceOracle` interface and requires an oracle address in the constructor, demonstrating the concept of using external data for on-chain logic (specifically for Prediction Vault conditions).

7.  **Pausable:** Simple pausing mechanism for security or upgrades.

**Limitations and Simplifications (Due to complexity/gas limits for a single contract demo):**

*   **Liquidity Tracking:** The simplified implementation uses the standard `pool.reserveA/B` for all swap calculations (`swap`, `executePredictionSwap`, `executeLeapSwap`). A real system with separate Prediction Vault or Time-Locked liquidity pools would need distinct reserve variables and logic for how swaps interact with each type of liquidity.
*   **Fee Accrual & Claiming:** Calculating and claiming accrued fees per individual NFT position is complex in a production AMM. This contract uses simplified claims (initial deposit + hypothetical fees) and a basic protocol fee accumulation.
*   **Prediction Vault Condition Met State:** The contract doesn't implement a robust system for checking and updating the `conditionMet` flag for Prediction Vaults (e.g., via a keeper network or user-initiated check that updates state). `checkPredictionVaultCondition` is a view function. `executePredictionSwap` uses a simplified `anyPVMet` concept.
*   **Splitting/Merging PV/TL:** Handling the merging of Prediction Vaults or Time-Locked Pools with conflicting parameters (different price targets, end times, or claimed states) is highly complex. The current merge logic is a simplification.
*   **ERC721 Implementation:** The embedded ERC721 is minimal. A full implementation would include ERC165 interface checks, token enumeration (ERC721Enumerable), and metadata (ERC721Metadata). Using OpenZeppelin libraries would be standard practice but was avoided here per the "don't duplicate open source" constraint on the *concept* itself.
*   **Error Handling/Edge Cases:** Production code requires extensive error handling, especially around division/multiplication with large numbers and precision (fixed-point math is often used in AMMs). SafeMath is used, but full precision considerations are omitted for clarity.

This contract serves as a creative and complex concept demonstration, showcasing the potential for building highly customized and advanced DeFi protocols beyond standard AMMs, leveraging NFTs for flexible position management and incorporating conditional/time-based liquidity mechanics.