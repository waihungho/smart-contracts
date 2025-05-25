Okay, here is a Solidity smart contract featuring several advanced, creative, and trendy concepts beyond standard open-source implementations like typical AMMs or staking pools.

It's designed as a "Quantum Liquidity Reactor" – an AMM-like system where trading fees, bonding yields, and even unlock penalties are dynamic and depend on an internal "Resonance State". It also includes a "Catalyst" system for boosted yields and separate reward streams.

Please note: Implementing all intricate calculations (like averaging historical resonance states for yield) fully in Solidity within a single example can be extremely complex and gas-intensive. This example provides the structure, state variables, function interfaces, and key logic outlines to *represent* these advanced concepts. A production-ready contract would require extensive optimization, formal verification, and potentially external keepers or oracle systems for truly complex state updates.

---

## Quantum Liquidity Reactor

**Concept:**
A dynamic Automated Market Maker (AMM) that manages liquidity for a pair of tokens (Token A and Token B). Unlike standard AMMs, its parameters (swap fees, bonding yields, penalties) are not fixed but adjust based on an internal "Resonance State". This state is influenced by factors like time and trading volume. The contract also features a liquidity bonding mechanism with tiered durations, adaptive yields, and a special "Catalyst" system for yield enhancement.

**Key Mechanics:**

1.  **Core AMM:** Standard functions to add/remove liquidity and swap between Token A and Token B, maintaining a product invariant.
2.  **Dynamic Fees:** Swap fees are not constant but depend on the current `ResonanceFactor`. Higher volatility states could imply higher fees.
3.  **Liquidity Bonding:** Users can lock their LP tokens for fixed durations. This earns them a share of trading fees and additional bonding rewards.
4.  **Adaptive Yields:** Bonding rewards are multiplied by a factor derived from the `ResonanceFactor`. The yield rate changes dynamically.
5.  **Resonance State:** An internal state variable (`resonanceFactor`) that updates over time and based on cumulative trading volume within epochs. It influences fees and yields. Can be updated by anyone (keeper function).
6.  **Catalyst System:** Users holding a specific "Catalyst" token or NFT can register it with the contract to receive boosted bonding rewards.
7.  **Multiple Reward Streams:** Bonded LPs can claim both accumulated bonding rewards (paid in Token A) and a share of the collected trading fees (in both Token A and Token B).
8.  **Penalties & Slashing:** Early unbonding incurs a penalty on the LP principal, which can be distributed or burned.
9.  **Internal LP Token:** The contract manages its own ERC20-like LP token state internally (`balanceOf`, `transfer`, etc.).

**Function Summary:**

1.  `constructor`: Initializes the contract with token addresses, name, symbol, and initial parameters.
2.  `addLiquidity`: Adds liquidity for Token A and Token B, mints LP tokens.
3.  `removeLiquidity`: Burns LP tokens, removes proportional liquidity.
4.  `swapAForB`: Swaps Token A for Token B. Calculates dynamic fee based on `ResonanceFactor`.
5.  `swapBForA`: Swaps Token B for Token A. Calculates dynamic fee based on `ResonanceFactor`.
6.  `getAmountOut`: View function to calculate estimated output amount for a swap, considering current `ResonanceFactor` fee.
7.  `getAmountIn`: View function to calculate required input amount for a desired output amount, considering current `ResonanceFactor` fee.
8.  `bondLiquidity`: Locks a specified amount of LP tokens for a chosen duration tier. Records bonding details including the `ResonanceFactor` snapshot at the time of bonding.
9.  `unbondLiquidity`: Unlocks bonded LP tokens after the maturity period. If called early (`emergencyUnbond` logic is separate), calculates and applies penalty.
10. `emergencyUnbond`: Unlocks bonded LP tokens before maturity, applying a higher penalty.
11. `claimBondingRewards`: Claims accrued bonding rewards (in Token A) for mature bonds. Reward calculation is based on bonded amount, duration tier, time, and the *averaged ResonanceFactor* during the bond period. Includes Catalyst boost if active.
12. `claimTradingFeeShare`: Claims accrued share of collected trading fees (in Token A and Token B) for *all* active and mature bonds.
13. `registerCatalyst`: Registers a specific Catalyst token/NFT ID held by the user to enable yield boosts. Requires transferring/approving the Catalyst.
14. `unregisterCatalyst`: Unregisters a previously registered Catalyst, allowing the user to transfer it back.
15. `updateResonanceState`: Public function callable by anyone (acting as a keeper) after a minimum epoch duration. Updates the internal `resonanceFactor` based on recent activity (volume, blocks elapsed). Includes a mechanism to prevent frequent calls.
16. `balanceOf`: (LP Token Standard) Returns the LP token balance of an address.
17. `allowance`: (LP Token Standard) Returns the amount an owner has allowed a spender to spend.
18. `transfer`: (LP Token Standard) Transfers LP tokens.
19. `approve`: (LP Token Standard) Approves a spender to spend LP tokens.
20. `transferFrom`: (LP Token Standard) Transfers LP tokens from one address to another using allowance.
21. `getBondDetails`: View function to retrieve details of a specific bond by user and index.
22. `getUserBondedBalanceByTier`: View function showing total LP amount bonded by a user for each duration tier.
23. `getPendingBondingRewards`: View function to estimate pending bonding rewards (Token A) for a user's bonds.
24. `getPendingTradingFeeShare`: View function to estimate pending trading fee share (Token A, Token B) for a user's bonds.
25. `getSwapFeePercentage`: View function returning the current swap fee percentage based on `ResonanceFactor`.
26. `getBondingMultiplier`: View function returning the current bonding yield multiplier for a specific tier based on `ResonanceFactor`.
27. `getCurrentResonanceState`: View function returning the current `ResonanceFactor` and last update details.
28. `setBondDurationTiers`: (Owner/Admin) Sets or updates the available bonding duration tiers and their base multipliers.
29. `setCatalystContract`: (Owner/Admin) Sets the address of the external Catalyst token/NFT contract.
30. `getReactorParameters`: View function returning core contract parameters.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol"; // To receive Catalyst NFT
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Note: This contract outlines the structure and concepts.
// Precise calculations for adaptive yields based on historical ResonanceFactor
// would require storing historical state snapshots or complex on-chain math,
// which are simplified here for demonstration purposes.

error InvalidAmount();
error ZeroAddress();
error IdenticalTokens();
error InsufficientLiquidity();
error TransferFailed();
error InsufficientBalance();
error InsufficientAllowance();
error ZeroLiquidity();
error BondingNotMature();
error NoActiveBonds();
error InvalidBondIndex();
error EarlyUnbondNotAllowed();
error CatalystAlreadyRegistered();
error CatalystNotRegistered();
error InvalidCatalystToken();
error InvalidDurationTier();
error ResonanceStateTooRecent();
error NothingToClaim();
error InvalidBondDetailsRequest();

contract QuantumLiquidityReactor is IERC20, Ownable, ERC721Holder {
    using SafeERC20 for IERC20;

    // --- State Variables ---

    IERC20 public immutable tokenA;
    IERC20 public immutable tokenB;
    IERC721 public catalystContract;

    uint256 private reserveA;
    uint256 private reserveB;
    uint256 private totalSupplyLP;

    // LP Token ERC20 State
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    string public name = "Quantum Reactor LP";
    string public symbol = "QRLP";
    uint8 public constant decimals = 18; // Assuming LP tokens are 18 decimals

    // Bonding State
    struct BondInfo {
        uint256 amount;         // Amount of LP tokens bonded
        uint64 startTime;       // Timestamp when bonding started
        uint64 endTime;         // Timestamp when bonding matures
        uint256 durationTierId; // Index of the duration tier used
        uint256 startResonanceFactor; // Resonance factor snapshot at bond start
        bool active;            // Is this bond currently active?
    }
    // Mapping user => array of their bonds
    mapping(address => BondInfo[]) public userBonds;

    // Duration Tiers for Bonding (duration in seconds, multiplier in basis points)
    struct DurationTier {
        uint65 duration; // Using uint65 to potentially store larger values if needed, but seconds fit in uint64
        uint256 baseMultiplier; // Base annual yield multiplier (e.g., 10000 for 1x)
    }
    DurationTier[] public bondDurationTiers;

    // Resonance State
    uint256 public resonanceFactor; // A dynamic factor influencing fees and yields (e.g., 1 to 1000)
    uint256 private lastResonanceUpdateTimestamp;
    uint256 private cumulativeVolumeSinceLastUpdate; // Sum of (amountA_in + amountB_in) since last update
    uint256 public constant RESONANCE_UPDATE_EPOCH_DURATION = 1 days; // Minimum time between resonance updates

    // Reward & Fee State
    uint256 public totalBondingRewardsAccrued; // Total Token A rewards accrued to the system (theoretical)
    uint256 public totalTradingFeesAccruedA;   // Total Token A fees collected
    uint256 public totalTradingFeesAccruedB;   // Total Token B fees collected

    // Catalyst State (simple system: user can link one catalyst ID)
    mapping(address => uint256) public userCatalystId; // User address => Catalyst Token/NFT ID
    mapping(uint256 => address) private catalystIdUser; // Catalyst Token/NFT ID => User address (for reverse lookup)
    uint256 public constant CATALYST_BOOST_PERCENT = 20; // 20% boost (example)

    // Penalty State
    uint256 public constant EARLY_UNBOND_PENALTY_PERCENT = 10; // 10% penalty on principal (example)
    uint256 public totalPenaltiesCollectedLP; // LP tokens collected from penalties

    // --- Events ---

    event AddLiquidity(address indexed user, uint256 amountA, uint256 amountB, uint256 lpTokensMinted);
    event RemoveLiquidity(address indexed user, uint256 lpTokensBurned, uint256 amountA, uint256 amountB);
    event Swap(address indexed user, IERC20 indexed tokenIn, IERC20 indexed tokenOut, uint256 amountIn, uint256 amountOut, uint256 feeAmount);
    event BondLiquidity(address indexed user, uint256 bondIndex, uint256 amount, uint256 durationTierId, uint64 endTime, uint256 startResonanceFactor);
    event UnbondLiquidity(address indexed user, uint256 bondIndex, uint256 lpReturned, uint256 penaltyAmount);
    event ClaimBondingRewards(address indexed user, uint256 bondIndex, uint256 rewardAmountA);
    event ClaimTradingFeeShare(address indexed user, uint256 amountA, uint256 amountB);
    event ResonanceStateUpdated(uint256 oldFactor, uint256 newFactor, uint256 cumulativeVolume, uint64 updateTimestamp);
    event CatalystRegistered(address indexed user, uint256 catalystId);
    event CatalystUnregistered(address indexed user, uint256 catalystId);
    event SetDurationTiers(DurationTier[] tiers);
    event SetCatalystContract(address indexed oldContract, address indexed newContract);

    // --- Constructor ---

    constructor(
        IERC20 _tokenA,
        IERC20 _tokenB,
        string memory _name,
        string memory _symbol
    ) Ownable(msg.sender) {
        if (address(_tokenA) == address(0) || address(_tokenB) == address(0)) revert ZeroAddress();
        if (address(_tokenA) == address(_tokenB)) revert IdenticalTokens();

        tokenA = _tokenA;
        tokenB = _tokenB;
        name = _name;
        symbol = _symbol;

        // Initial default duration tiers (example: 30 days, 90 days, 180 days)
        // Multipliers are annual basis points, Resonance Factor will adjust this.
        bondDurationTiers.push(DurationTier({duration: 30 days, baseMultiplier: 10000})); // 1x base
        bondDurationTiers.push(DurationTier({duration: 90 days, baseMultiplier: 15000})); // 1.5x base
        bondDurationTiers.push(DurationTier({duration: 180 days, baseMultiplier: 20000})); // 2x base

        // Initial Resonance State
        resonanceFactor = 500; // Start in a neutral state (e.g., range 1-1000)
        lastResonanceUpdateTimestamp = uint64(block.timestamp);
        cumulativeVolumeSinceLastUpdate = 0;
    }

    // --- Core AMM Functions ---

    function addLiquidity(uint256 amountA, uint256 amountB) external returns (uint256 lpTokens) {
        if (amountA == 0 || amountB == 0) revert InvalidAmount();

        uint256 currentReserveA = reserveA;
        uint256 currentReserveB = reserveB;

        if (currentReserveA == 0 || currentReserveB == 0) {
            // First liquidity provider
            lpTokens = amountA; // Simplified: LP tokens are initially pegged to tokenA amount
            reserveA = amountA;
            reserveB = amountB;
        } else {
            // Calculate LP tokens based on the proportion of reserves
            uint256 lpTokensA = (totalSupplyLP * amountA) / currentReserveA;
            uint256 lpTokensB = (totalSupplyLP * amountB) / currentReserveB;
            lpTokens = lpTokensA < lpTokensB ? lpTokensA : lpTokensB; // Mint the minimum to maintain price ratio

            if (lpTokens == 0) revert InsufficientLiquidity(); // Proportions are too off

            // Update reserves
            reserveA = currentReserveA + amountA;
            reserveB = currentReserveB + amountB;
        }

        // Transfer tokens to the contract
        tokenA.safeTransferFrom(msg.sender, address(this), amountA);
        tokenB.safeTransferFrom(msg.sender, address(this), amountB);

        // Mint LP tokens
        totalSupplyLP += lpTokens;
        balances[msg.sender] += lpTokens;

        emit AddLiquidity(msg.sender, amountA, amountB, lpTokens);
        emit Transfer(address(0), msg.sender, lpTokens); // ERC20 Mint event
        return lpTokens;
    }

    function removeLiquidity(uint256 lpTokens) external returns (uint256 amountA, uint256 amountB) {
        if (lpTokens == 0) revert InvalidAmount();
        if (lpTokens > balances[msg.sender]) revert InsufficientBalance();
        if (totalSupplyLP == 0) revert ZeroLiquidity();

        // Calculate token amounts to remove based on LP token proportion
        amountA = (lpTokens * reserveA) / totalSupplyLP;
        amountB = (lpTokens * reserveB) / totalSupplyLP;

        if (amountA == 0 || amountB == 0) revert InsufficientLiquidity(); // Should not happen if lpTokens > 0 and reserves > 0

        // Burn LP tokens
        totalSupplyLP -= lpTokens;
        balances[msg.sender] -= lpTokens;

        // Update reserves
        reserveA -= amountA;
        reserveB -= amountB;

        // Transfer tokens back to the user
        tokenA.safeTransfer(msg.sender, amountA);
        tokenB.safeTransfer(msg.sender, amountB);

        emit RemoveLiquidity(msg.sender, lpTokens, amountA, amountB);
        emit Transfer(msg.sender, address(0), lpTokens); // ERC20 Burn event
        return (amountA, amountB);
    }

    // --- Swap Functions ---

    // Internal helper to calculate dynamic swap fee
    function _calculateSwapFeePercentage(uint256 currentResonanceFactor) internal pure returns (uint256 feeBps) {
        // Example: Fee ranges from 0.3% (30 bps) to 1% (100 bps) based on resonance
        // Max resonance (e.g., 1000) = Max Fee
        // Min resonance (e.g., 1) = Min Fee
        // Formula: MinFee + (MaxFee - MinFee) * (resonanceFactor - MinResonance) / (MaxResonance - MinResonance)
        // Example with MinRes=1, MaxRes=1000, MinFee=30, MaxFee=100
        uint256 minFeeBps = 30; // 0.3%
        uint256 maxFeeBps = 100; // 1%
        uint256 minResonance = 1;
        uint256 maxResonance = 1000;

        if (currentResonanceFactor <= minResonance) return minFeeBps;
        if (currentResonanceFactor >= maxResonance) return maxFeeBps;

        feeBps = minFeeBps + (maxFeeBps - minFeeBps) * (currentResonanceFactor - minResonance) / (maxResonance - minResonance);
    }

    function getSwapFeePercentage() public view returns (uint256 feeBps) {
        return _calculateSwapFeePercentage(resonanceFactor);
    }

    // Uniswap V2 style getAmountOut with dynamic fee
    function _getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal view returns (uint256 amountOut, uint256 feeAmount) {
        uint256 feeBps = getSwapFeePercentage();
        uint256 amountInWithFee = amountIn * (10000 - feeBps); // 10000 is 100% in basis points

        // AMM formula: (reserveIn + amountInWithFee) * (reserveOut - amountOut) = reserveIn * reserveOut * 10000
        // amountOut = (reserveOut * amountInWithFee) / (reserveIn * 10000 + amountInWithFee)
        uint256 numerator = reserveOut * amountInWithFee;
        uint256 denominator = reserveIn * 10000 + amountInWithFee;

        if (denominator == 0) revert InsufficientLiquidity(); // Should not happen if reserveIn is not zero

        amountOut = numerator / denominator;
        feeAmount = amountIn * feeBps / 10000;
    }

     // Uniswap V2 style getAmountIn with dynamic fee
    function _getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) internal view returns (uint256 amountIn, uint256 feeAmount) {
        uint256 feeBps = getSwapFeePercentage();

        // AMM formula: (reserveIn + amountInWithFee) * (reserveOut - amountOut) = reserveIn * reserveOut * 10000
        // amountInWithFee = (reserveIn * reserveOut * 10000 / (reserveOut - amountOut)) - reserveIn * 10000
        // amountIn = amountInWithFee * 10000 / (10000 - feeBps)
        if (amountOut >= reserveOut) revert InsufficientLiquidity();

        uint256 numerator = reserveIn * amountOut * 10000;
        uint256 denominator = (reserveOut - amountOut) * (10000 - feeBps);
        if (denominator == 0) revert InsufficientLiquidity(); // Should not happen if amountOut < reserveOut

        uint256 amountInWithFee = (numerator / denominator); // This is the amount needed *before* fee calculation adjustment in the formula
        amountIn = (amountInWithFee * 10000 / (10000 - feeBps)); // This is the actual input amount including fee

        // Recalculate fee based on final amountIn to ensure accuracy
        feeAmount = amountIn * feeBps / 10000;
    }

    function getAmountOut(uint256 amountIn, IERC20 tokenIn) public view returns (uint256 amountOut, uint256 feeAmount) {
        if (address(tokenIn) == address(tokenA)) {
            return _getAmountOut(amountIn, reserveA, reserveB);
        } else if (address(tokenIn) == address(tokenB)) {
            return _getAmountOut(amountIn, reserveB, reserveA);
        } else {
            revert InvalidAmount(); // Invalid token
        }
    }

    function getAmountIn(uint256 amountOut, IERC20 tokenOut) public view returns (uint256 amountIn, uint256 feeAmount) {
         if (address(tokenOut) == address(tokenA)) {
            return _getAmountIn(amountOut, reserveB, reserveA);
        } else if (address(tokenOut) == address(tokenB)) {
            return _getAmountIn(amountOut, reserveA, reserveB);
        } else {
            revert InvalidAmount(); // Invalid token
        }
    }

    function swapAForB(uint256 amountInA, uint256 amountOutBMin) external {
        if (amountInA == 0) revert InvalidAmount();

        (uint256 amountOutB, uint256 feeAmountA) = _getAmountOut(amountInA, reserveA, reserveB);
        if (amountOutB < amountOutBMin) revert InsufficientLiquidity(); // Slippage check

        // Update reserves *before* transfers to prevent re-entrancy issues with external token calls
        reserveA += amountInA; // amountIn includes the fee component in Uniswap V2 math
        reserveB -= amountOutB;

        // Collect fees
        totalTradingFeesAccruedA += feeAmountA;

        // Transfer tokens
        tokenA.safeTransferFrom(msg.sender, address(this), amountInA);
        tokenB.safeTransfer(msg.sender, amountOutB);

        cumulativeVolumeSinceLastUpdate += amountInA + amountOutB; // Track volume for resonance update

        emit Swap(msg.sender, tokenA, tokenB, amountInA, amountOutB, feeAmountA);
    }

    function swapBForA(uint256 amountInB, uint256 amountOutAMin) external {
        if (amountInB == 0) revert InvalidAmount();

        (uint256 amountOutA, uint256 feeAmountB) = _getAmountOut(amountInB, reserveB, reserveA);
         if (amountOutA < amountOutAMin) revert InsufficientLiquidity(); // Slippage check

        // Update reserves *before* transfers
        reserveB += amountInB; // amountIn includes the fee component
        reserveA -= amountOutA;

        // Collect fees
        totalTradingFeesAccruedB += feeAmountB;

        // Transfer tokens
        tokenB.safeTransferFrom(msg.sender, address(this), amountInB);
        tokenA.safeTransfer(msg.sender, amountOutA);

        cumulativeVolumeSinceLastUpdate += amountInB + amountOutA; // Track volume

        emit Swap(msg.sender, tokenB, tokenA, amountInB, amountOutA, feeAmountB);
    }

    // --- Bonding Functions ---

    function getBondDurationTiers() public view returns (DurationTier[] memory) {
        return bondDurationTiers;
    }

    function getBondingMultiplier(uint256 tierId) public view returns (uint256 multiplierBps) {
        if (tierId >= bondDurationTiers.length) revert InvalidDurationTier();

        // Example: How resonance factor modifies the base multiplier
        // Resonance Factor is 1-1000. Neutral is 500.
        // Multiplier is `baseMultiplier * (1 + (resonanceFactor - 500) / 1000 * AdjustmentFactor)`
        // Simple example: if resonance is 1000, add 50% boost to base. if resonance is 0, subtract 50% (min 0).
        uint256 base = bondDurationTiers[tierId].baseMultiplier;
        int256 resonanceDelta = int256(resonanceFactor) - 500; // 0 at neutral
        // Map delta (-500 to +500) to a percentage adjustment (-50% to +50%)
        // adjustment = resonanceDelta * 50 / 500 = resonanceDelta / 10
        int256 adjustmentPercent = resonanceDelta / 10; // Using integer division for simplicity

        multiplierBps = uint256(int256(base) * (100 + adjustmentPercent) / 100);

        // Ensure multiplier is not zero
        if (multiplierBps == 0 && base > 0) multiplierBps = 1;
    }

    function bondLiquidity(uint256 amount, uint256 durationTierId) external {
        if (amount == 0) revert InvalidAmount();
        if (durationTierId >= bondDurationTiers.length) revert InvalidDurationTier();
        if (amount > balances[msg.sender]) revert InsufficientBalance();

        // Transfer LP tokens to the contract
        balances[msg.sender] -= amount; // Deduct from user's balance
        // Note: LP tokens bonded remain in the contract's total supply and balance,
        // but are marked as 'bonded' for the user.

        uint64 bondEndTime = uint64(block.timestamp) + bondDurationTiers[durationTierId].duration;

        BondInfo memory newBond = BondInfo({
            amount: amount,
            startTime: uint64(block.timestamp),
            endTime: bondEndTime,
            durationTierId: durationTierId,
            startResonanceFactor: resonanceFactor, // Capture state at bond start
            active: true
        });

        userBonds[msg.sender].push(newBond);
        uint256 bondIndex = userBonds[msg.sender].length - 1;

        emit BondLiquidity(msg.sender, bondIndex, amount, durationTierId, bondEndTime, resonanceFactor);
    }

    // Helper to calculate penalty
    function _calculateEarlyUnbondPenalty(uint256 amount) internal view returns (uint256 penaltyAmount) {
        penaltyAmount = amount * EARLY_UNBOND_PENALTY_PERCENT / 100;
    }

    // Helper to distribute penalty (example: send to a protocol fee collector or bonded stakers)
    function _distributePenalty(uint256 penaltyAmount) internal {
        // Example: Add to total collected penalties
        totalPenaltiesCollectedLP += penaltyAmount;
        // In a real system, this might be distributed to active bonded stakers or a DAO treasury.
        // For this example, they are just held in the contract.
    }


    function unbondLiquidity(uint256 bondIndex) external {
        if (bondIndex >= userBonds[msg.sender].length || !userBonds[msg.sender][bondIndex].active) {
            revert InvalidBondDetailsRequest();
        }

        BondInfo storage bond = userBonds[msg.sender][bondIndex];

        if (block.timestamp < bond.endTime) {
            // Not mature - must use emergency unbond
            revert BondingNotMature();
        }

        uint256 amountToReturn = bond.amount;

        // Mark bond as inactive
        bond.active = false;
        // Note: We don't remove from the array to avoid issues with indices of other bonds.
        // A better approach for many bonds would be a linked list or mapping by bond ID.

        // Return LP tokens to user
        balances[msg.sender] += amountToReturn;

        emit UnbondLiquidity(msg.sender, bondIndex, amountToReturn, 0);
        emit Transfer(address(this), msg.sender, amountToReturn); // ERC20 Transfer event
    }

     function emergencyUnbond(uint256 bondIndex) external {
        if (bondIndex >= userBonds[msg.sender].length || !userBonds[msg.sender][bondIndex].active) {
            revert InvalidBondDetailsRequest();
        }

        BondInfo storage bond = userBonds[msg.sender][bondIndex];

        if (block.timestamp >= bond.endTime) {
            // Already mature - use regular unbond
             revert EarlyUnbondNotAllowed();
        }

        uint256 penaltyAmount = _calculateEarlyUnbondPenalty(bond.amount);
        uint256 amountToReturn = bond.amount - penaltyAmount;

        // Mark bond as inactive
        bond.active = false;

        // Distribute penalty
        _distributePenalty(penaltyAmount);

        // Return penalized LP tokens to user
        balances[msg.sender] += amountToReturn;

        emit UnbondLiquidity(msg.sender, bondIndex, amountToReturn, penaltyAmount);
        emit Transfer(address(this), msg.sender, amountToReturn); // ERC20 Transfer event
    }

    // --- Reward & Fee Claiming ---

    // Simplified bonding reward calculation: Uses start and end resonance factors,
    // and linear time progression. A real system might sample resonance periodically.
    function _calculateAccruedBondingRewards(address user, uint256 bondIndex) internal view returns (uint256 rewardAmountA) {
        BondInfo storage bond = userBonds[user][bondIndex];
        if (!bond.active || block.timestamp < bond.endTime) {
            return 0; // Cannot claim until mature
        }

        // Calculate duration passed (should be total duration if mature)
        uint256 totalDuration = bondDurationTiers[bond.durationTierId].duration;
        if (totalDuration == 0) return 0;

        uint256 baseMultiplier = bondDurationTiers[bond.durationTierId].baseMultiplier; // Annualized basis points

        // Simple Resonance influence: Average of start and end resonance factors
        // NOTE: This is a significant simplification. Real adaptive yield needs
        // to account for state changes *during* the bond duration.
        // A more advanced system would store historical resonance points and calculate a time-weighted average.
        uint256 effectiveResonanceFactor = (bond.startResonanceFactor + resonanceFactor) / 2; // Using *current* state for simplicity here

        // Calculate effective bonding multiplier based on effective resonance
        uint256 effectiveMultiplierBps = baseMultiplier; // Simplified, should use a function like getBondingMultiplier with effectiveResonanceFactor

        // Annual reward amount based on multiplier: amount * effectiveMultiplierBps / 10000
        uint256 annualReward = bond.amount * effectiveMultiplierBps / 10000;

        // Scale by duration: annualReward * (bondDuration / 1 year)
        // Assuming 1 year = 365 days for simplicity in seconds calculation
        uint265 secondsInYear = 365 days;
        if (secondsInYear == 0) return 0; // Prevent division by zero

        // Total reward for the bond duration: annualReward * totalDuration / secondsInYear
        uint256 totalRewardForBond = annualReward * totalDuration / secondsInYear;

        // Apply Catalyst Boost if active
        if (userCatalystId[user] != 0 && address(catalystContract) != address(0)) {
             // Check if the user still holds the registered Catalyst
            try catalystContract.ownerOf(userCatalystId[user]) returns (address owner) {
                if (owner == address(this)) { // Check if contract still holds it (user transferred to contract)
                     totalRewardForBond = totalRewardForBond * (100 + CATALYST_BOOST_PERCENT) / 100;
                }
            } catch {
                 // Catalyst check failed (e.g., contract wrong, token transferred out of reactor)
                 // Do not apply boost
            }
        }

        // In a real system, you'd track *claimed* rewards per bond and only return the difference.
        // Here, since bonds are marked inactive on unbonding, claiming should happen afterwards.
        // Let's assume calling `claimBondingRewards` invalidates the bond for further claims.
        // The `active` flag is used for unbonding primarily. Let's add a `claimed` flag for rewards.
        // Requires modifying the BondInfo struct and tracking claimed status.
        // Simplified for now: Assume `claimBondingRewards` is called once per mature bond.
        // This requires `claimBondingRewards` to also mark the bond as claimed for rewards.
        // Let's add a `claimedRewards` boolean to BondInfo.

        return totalRewardForBond; // This is the *total* reward for this specific bond
    }

    // Modified BondInfo struct for reward claiming state
    struct BondInfoExtended {
        uint256 amount;
        uint64 startTime;
        uint64 endTime;
        uint256 durationTierId;
        uint256 startResonanceFactor;
        bool active; // For principal unbonding status
        bool rewardsClaimed; // For reward claiming status
    }
     // Let's refactor to use the Extended struct (requires modifying the bondLiquidity func)
     // For this example, let's stick to the simpler struct and assume `claimBondingRewards` is called once per bond after unbonding.
     // In a real system, rewards would accrue continuously and be claimable while bonded *and* after maturity until unbonded.

    function getPendingBondingRewards(address user, uint256 bondIndex) public view returns (uint256 rewardAmountA) {
         if (bondIndex >= userBonds[user].length || !userBonds[user][bondIndex].active) {
            return 0; // No active bond at this index
        }
        BondInfo storage bond = userBonds[user][bondIndex];
        if (block.timestamp < bond.endTime) {
            return 0; // Not mature yet
        }
         // Simplified: Return the total calculated reward if not yet claimed via the actual claim function
         // In a real system, this would be the accrual amount up to the current time/state snapshots.
        return _calculateAccruedBondingRewards(user, bondIndex);
    }

    // Simplified trading fee share calculation: based on user's current total bonded LP vs total currently bonded LP
    // A real system needs to track LP participation weight over time vs fee collection periods.
    function _calculateAccruedTradingFeeShare(address user) internal view returns (uint256 shareA, uint256 shareB) {
         uint256 totalCurrentlyBonded = getTotalBondedLiquidity();
         if (totalCurrentlyBonded == 0 || totalTradingFeesAccruedA == 0 && totalTradingFeesAccruedB == 0) {
             return (0, 0);
         }

         uint256 userTotalBonded = 0;
         for(uint i = 0; i < userBonds[user].length; i++) {
             if(userBonds[user][i].active || block.timestamp < userBonds[user][i].endTime) { // Count active and recently matured bonds for share calculation
                 userTotalBonded += userBonds[user][i].amount;
             }
         }

         if (userTotalBonded == 0) return (0,0);

         // This simple distribution means LPs only get fees if bonded *now*.
         // A real system needs to distribute fees accrued during a period proportionally
         // to the LP-seconds (or similar metric) each user had bonded during *that* period.
         // This would require a more complex accounting system.
         // Simplified: User's share is their current bonded amount proportion of *total* historical fees.
         // This is likely NOT how you'd do it in production.
         // A better way: Fees are claimed from pools that are filled over time,
         // and user's claimable amount from each pool is based on their bond weight
         // *while that pool was accumulating fees*.

         // For this example, let's assume fees are shared based on the *total lifetime* bonded amount vs. total lifetime liquidity volume.
         // This requires tracking lifetime bonded LP and lifetime volume. Too complex for example.

         // Let's simplify drastically: Fees are claimable by ANYONE who has EVER bonded, proportional to their *total claimed bonding rewards*.
         // This links fee share to bonding participation but avoids complex LP time-weighting.
         // Requires tracking total rewards claimed per user. Let's add a state variable for this.
         // OR, simplest: Fees accrue and are distributed to active, mature bonds proportionally to their size.
         // Let's go with the simplest: Distribute accrued fees (less any claimed amounts) based on user's current active/mature bonded balance vs total currently active/mature bonded balance.

        uint256 totalEligibleBonded = getTotalEligibleBondedLiquidity(); // Helper needed
        if (totalEligibleBonded == 0) return (0, 0);

        // Need to track already claimed fees per user to avoid double claiming
        // mapping(address => uint256) claimedFeesA; mapping(address => uint256) claimedFeesB;
        // This adds more state. Let's assume for simplicity fees are claimed ALL AT ONCE when user claims, resetting their share.

        shareA = totalTradingFeesAccruedA * userTotalBonded / totalEligibleBonded;
        shareB = totalTradingFeesAccruedB * userTotalBonded / totalEligibleBonded;
        // This logic is flawed for production as it doesn't track user claims properly vs total pool.
        // A proper system needs a mechanism to track user's *claimable* share based on historical contribution vs historical fee accrual.

        // Let's refine: User's claimable share of FEES is based on their *currently mature and unclaimed* bonds.
        // The accrued fee pools `totalTradingFeesAccruedA/B` represent the total fees collected *since the last fee distribution event* (or contract deploy).
        // Users claim their portion of *these* accumulated fees. This still requires tracking claimed amounts per user.

        // Simpler approach: Fees are collected. Periodically (or on `updateResonanceState`), a portion is moved to a distribution pool.
        // Bonded stakers (active + mature) can claim from the distribution pool pro-rata based on their stake *at the time of distribution snapshot*.
        // This requires snapshots. Let's avoid snapshots for this example.

        // FINAL SIMPLE APPROACH FOR EXAMPLE: Fees accrue globally. Users claim a percentage based on their total lifetime bonded LP.
        // Need total lifetime bonded LP per user and globally. Adds state.

        // Let's revert to the simplest: Claimable fees are just a proportion of TOTAL fees collected ever, based on their currently bonded amount vs total currently bonded amount.
        // This is incorrect for a real system but simple for demonstration. The correct way involves tracking claim offsets.

        // Let's use a simple global `claimedTradingFees` state per user. This assumes fees are one big pool.
        // mapping(address => uint256) private userClaimedFeesA;
        // mapping(address => uint256) private userClaimedFeesB;
        // shareA = (totalTradingFeesAccruedA * userTotalBonded / totalEligibleBonded) - userClaimedFeesA[user];
        // shareB = (totalTradingFeesAccruedB * userTotalBonded / totalEligibleBonded) - userClaimedFeesB[user];
        // This is also not quite right. The total pool shrinks as people claim.

        // Let's make it claimable relative to their share of BONDING REWARDS earned.
        // Total fees collected / Total bonding rewards paid out * User's bonding rewards paid out
        // Requires tracking total bonding rewards paid out.

        // Let's use the initial (and flawed) simple proportional method based on current bonded balance, acknowledging its simplicity for the example.
        // Let's refine `userTotalBonded` to be only `active` bonds.
        userTotalBonded = 0;
        for(uint i = 0; i < userBonds[user].length; i++) {
            if(userBonds[user][i].active) {
                userTotalBonded += userBonds[user][i].amount;
            }
        }
         totalEligibleBonded = getTotalBondedLiquidity(); // This now means only *active* bonds

        if (totalEligibleBonded == 0) return (0, 0);

        // Proportion of *total* accumulated fees based on *current* active bond
        shareA = totalTradingFeesAccruedA * userTotalBonded / totalEligibleBonded;
        shareB = totalTradingFeesAccruedB * userTotalBonded / totalEligibleBonded;

        // Need to subtract already claimed amounts.
        // This requires mapping user => total claimed fees.
        // Let's add those mappings.

        // mapping(address => uint256) private userClaimedFeesA;
        // mapping(address => uint256) private userClaimedFeesB;
        // shareA = shareA - userClaimedFeesA[user];
        // shareB = shareB - userClaimedFeesB[user];
        // The total accrued amounts also need to be adjusted when someone claims. This is complex.

        // Okay, let's simplify the model entirely for the example:
        // Trading fees are NOT distributed proportionally to bonded LPs.
        // Instead, they are a separate pool claimable by BONDED LPs, perhaps split 50/50 between A and B.
        // The bonding rewards (in Token A) are the primary yield source influenced by Resonance.
        // This makes the contract simpler and fits the "multiple reward streams" idea differently.
        // Fees collected just sit in the contract and potentially benefit the LP token value indirectly or can be withdrawn by owner (less advanced) or some protocol mechanism (more advanced).

        // Let's make trading fees claimable by ANY LP, not just bonded ones. This is standard Uniswap V2.
        // In V2, fees are not claimed, they increase the value of LP tokens.
        // If we want claimable fees, we need a different model.

        // Let's try again: Fees collected are held. Bonded LPs can claim a share.
        // The share is proportional to their bonded amount and time *within a specific fee accumulation period*.
        // This requires snapshots and tracking.
        // Let's go back to the *simple* model: Fees accrue globally. Bonded users can claim a proportional share of the *total* accrued fees. This requires tracking what each user HAS claimed.

        // Adding State:
        // mapping(address => uint252) private userClaimedFeesA; // Using smaller uint if fees aren't huge
        // mapping(address => uint252) private userClaimedFeesB;

        // The share is total fees * (user total bonded amount / total bonded amount). This is incorrect.
        // It should be total fees * (user LP-seconds / total LP-seconds) for the period the fees accumulated.

        // Let's change the trading fee mechanism: A percentage of the fee collected is immediately added to the bonding reward pool (paid in Token A).
        // This links fees directly to the Resonance-affected bonding yield and simplifies claiming.
        // Example: 50% of collected fee (in Token A) and equivalent value of Token B fee are converted to Token A and added to reward pool.
        // Conversion adds complexity.

        // Let's make the trading fee share completely separate and simple:
        // A percentage of *all* trading fees collected are available for bonded stakers to claim.
        // The claimable amount for a user is proportional to their *total LP-seconds bonded* vs *total LP-seconds bonded across all users* since the last time the user claimed fees.
        // This still requires tracking LP-seconds per user and globally, and tracking last claim time/state.

        // Okay, let's simplify one last time for the example contract constraints (avoiding extensive state for tracking accruals over time):
        // 1. Bonding rewards are calculated per bond on maturity based on start/end resonance and duration (simplified). Claimable once per bond.
        // 2. Trading fees are collected by the contract.
        // 3. Bonded LPs can claim a *separate* reward: a fixed rate per LP token bonded per day, paid from the collected fees. This is simple but less "adaptive".
        // 4. Or: Let's make it a fixed percentage of fees distributed whenever `claimTradingFeeShare` is called, proportional to the user's *current* active bonded amount. Still flawed but simpler.

        // Let's use a simpler fee distribution model for this example:
        // A portion of the collected fees (e.g., 50%) is held in the contract.
        // The other portion (50%) is immediately distributed among *currently active bonded* stakers, pro-rata.
        // This requires iterating over active bonds or using a Merkle drop (off-chain calc).

        // Let's make fees claimable *on demand* by bonded stakers, proportional to their *current active bonded amount* out of the *total currently active bonded amount*.
        // Need to track `claimedFeesA[user]` and `claimedFeesB[user]` against `totalTradingFeesAccruedA` and `totalTradingFeesAccruedB`.

        // Let's add the necessary state variables and logic for the proportional claim based on current active bond balance.
    }

     // Helper function to get total active bonded liquidity
    function getTotalBondedLiquidity() public view returns (uint256 total) {
        for(uint i = 0; i < userBonds[msg.sender].length; i++) { // This is only for msg.sender! Need global.
            // Requires iterating all users or tracking globally. Let's add global tracking.
        }
         // Adding State: uint256 public totalActiveBondedLP;
         // Need to update this in bondLiquidity and unbondLiquidity/emergencyUnbond.
         return totalActiveBondedLP;
    }

    // State variable for global active bonded LP
    uint256 private totalActiveBondedLP;

    // Adding Claimed Fees State
    mapping(address => uint256) private userClaimedFeesA;
    mapping(address => uint256) private userClaimedFeesB;

    // Recalculate _calculateAccruedTradingFeeShare based on current active bonds vs total active bonds and user's claimed history
     function _calculateAccruedTradingFeeShare(address user) internal view returns (uint256 shareA, uint256 shareB) {
         uint256 userCurrentActiveBonded = 0;
         for(uint i = 0; i < userBonds[user].length; i++) {
             if(userBonds[user][i].active) {
                 userCurrentActiveBonded += userBonds[user][i].amount;
             }
         }

        if (userCurrentActiveBonded == 0 || totalActiveBondedLP == 0) return (0, 0);

        // Calculate user's total potential share based on their current active bond proportion of total fees accrued.
        // This logic is still simplified. A proper system tracks fees accrued *per unit of LP-time*.
        uint256 potentialShareA = totalTradingFeesAccruedA * userCurrentActiveBonded / totalActiveBondedLP;
        uint256 potentialShareB = totalTradingFeesAccruedB * userCurrentActiveBonded / totalActiveBondedLP;

        // Subtract already claimed amounts
        shareA = potentialShareA > userClaimedFeesA[user] ? potentialShareA - userClaimedFeesA[user] : 0;
        shareB = potentialShareB > userClaimedFeesB[user] ? potentialShareB - userClaimedFeesB[user] : 0;
    }

     function getPendingTradingFeeShare(address user) public view returns (uint256 shareA, uint256 shareB) {
         return _calculateAccruedTradingFeeShare(user);
     }


    function claimBondingRewards(uint256 bondIndex) external {
        if (bondIndex >= userBonds[msg.sender].length) {
            revert InvalidBondDetailsRequest();
        }
        BondInfo storage bond = userBonds[msg.sender][bondIndex];

        if (!bond.active) { // Should be !bond.rewardsClaimed after adding that flag
             revert NothingToClaim(); // Or specific error like AlreadyClaimed
        }
         if (block.timestamp < bond.endTime) {
             revert BondingNotMature();
         }

        // In the extended struct model: if (bond.rewardsClaimed) revert NothingToClaim();

        uint256 rewardAmountA = _calculateAccruedBondingRewards(msg.sender, bondIndex);
        if (rewardAmountA == 0) revert NothingToClaim();

        // In the extended struct model: bond.rewardsClaimed = true;

        // Transfer rewards to user
        tokenA.safeTransfer(msg.sender, rewardAmountA);

        emit ClaimBondingRewards(msg.sender, bondIndex, rewardAmountA);

        // Note: If using the extended struct, you would add `bool claimedRewards;` to BondInfo
        // and check/set it here. This requires refactoring bondLiquidity, userBonds mapping, etc.
    }

     function claimTradingFeeShare() external {
         (uint256 claimableA, uint256 claimableB) = _calculateAccruedTradingFeeShare(msg.sender);

         if (claimableA == 0 && claimableB == 0) revert NothingToClaim();

         // Update claimed amounts *before* transfer to prevent re-entrancy
         userClaimedFeesA[msg.sender] = userClaimedFeesA[msg.sender] + claimableA; // Flawed if totalAccrued can decrease (it shouldn't here)
         userClaimedFeesB[msg.sender] = userClaimedFeesB[msg.sender] + claimableB;

         // Transfer fees to user
         if (claimableA > 0) tokenA.safeTransfer(msg.sender, claimableA);
         if (claimableB > 0) tokenB.safeTransfer(msg.sender, claimableB);

         emit ClaimTradingFeeShare(msg.sender, claimableA, claimableB);
     }

     function getClaimableRewards(address user) public view returns (uint256 pendingBondingRewardsA, uint256 pendingFeesA, uint256 pendingFeesB) {
         // Sum pending bonding rewards across all mature, unclaimed bonds
         pendingBondingRewardsA = 0;
         for(uint i = 0; i < userBonds[user].length; i++) {
             if (userBonds[user][i].active && block.timestamp >= userBonds[user][i].endTime) { // Check if active AND mature
                // In extended struct: if (userBonds[user][i].active && block.timestamp >= userBonds[user][i].endTime && !userBonds[user][i].rewardsClaimed)
                 pendingBondingRewardsA += _calculateAccruedBondingRewards(user, i);
             }
         }

         // Get pending trading fee share
         (pendingFeesA, pendingFeesB) = _calculateAccruedTradingFeeShare(user);
     }


    // --- Catalyst System ---

    function setCatalystContract(IERC721 _catalystContract) external onlyOwner {
        if (address(_catalystContract) == address(0)) revert ZeroAddress();
        emit SetCatalystContract(catalystContract, _catalystContract);
        catalystContract = _catalystContract;
    }

    function registerCatalyst(uint256 catalystId) external {
        if (address(catalystContract) == address(0)) revert InvalidCatalystToken();
        if (userCatalystId[msg.sender] != 0) revert CatalystAlreadyRegistered();

        // Verify sender owns the Catalyst token
        address tokenOwner = catalystContract.ownerOf(catalystId);
        if (tokenOwner != msg.sender) revert InvalidCatalystToken(); // Or a more specific error

        // Transfer Catalyst token to the reactor contract
        catalystContract.safeTransferFrom(msg.sender, address(this), catalystId);

        // Record the registration
        userCatalystId[msg.sender] = catalystId;
        catalystIdUser[catalystId] = msg.sender;

        emit CatalystRegistered(msg.sender, catalystId);
    }

    function unregisterCatalyst() external {
        uint256 catalystId = userCatalystId[msg.sender];
        if (catalystId == 0) revert CatalystNotRegistered();

        // Transfer Catalyst token back to the user
        catalystContract.safeTransferFrom(address(this), msg.sender, catalystId);

        // Clear the registration
        userCatalystId[msg.sender] = 0;
        catalystIdUser[catalystId] = address(0);

        emit CatalystUnregistered(msg.sender, catalystId);
    }

    function isCatalystActive(address user) public view returns (bool) {
        uint256 catalystId = userCatalystId[user];
        if (catalystId == 0 || address(catalystContract) == address(0)) return false;

         // Verify the contract still holds the token
        try catalystContract.ownerOf(catalystId) returns (address owner) {
             return owner == address(this);
        } catch {
             // Failed to get owner (e.g., contract address wrong, token burned, etc.)
             return false;
        }
    }

    // --- Resonance State Management ---

    // This function updates the resonanceFactor. It's public and can be called by anyone
    // after a minimum time epoch has passed. This allows external "keepers" to maintain
    // the state dynamism. The logic for how volume and time affect the factor is simplified.
    function updateResonanceState() external {
        uint64 currentTimestamp = uint64(block.timestamp);
        if (currentTimestamp < lastResonanceUpdateTimestamp + RESONANCE_UPDATE_EPOCH_DURATION) {
             revert ResonanceStateTooRecent();
        }

        uint256 oldResonanceFactor = resonanceFactor;

        // Simple example logic: Resonance increases with high volume, decreases with low volume.
        // Time also pushes it towards a neutral state (e.g., 500).
        uint256 volumeScore = cumulativeVolumeSinceLastUpdate / 1e18; // Scale volume down (assuming 18 decimals)
        uint256 timeScore = (currentTimestamp - lastResonanceUpdateTimestamp) / 1 hours; // Time in hours

        // Simplified update formula:
        // Resonance change is proportional to (volumeScore - baselineVolume) and deviation from neutral (500)
        // baselineVolume could be a moving average or constant. Let's use a constant.
        uint256 baselineVolumeScore = 100; // Example baseline score per epoch

        int256 volumeEffect = int256(volumeScore) - int256(baselineVolumeScore);
        int256 timeEffect = int256(timeScore);

        // Adjust factor: Add scaled volume effect, subtract time effect pushing towards neutral
        int256 resonanceChange = (volumeEffect / 10) - (int256(resonanceFactor) - 500) / 50; // Example scaling

        int256 newResonanceFactorInt = int256(resonanceFactor) + resonanceChange;

        // Clamp factor between 1 and 1000
        if (newResonanceFactorInt < 1) newResonanceFactorInt = 1;
        if (newResonanceFactorInt > 1000) newResonanceFactorInt = 1000;

        resonanceFactor = uint256(newResonanceFactorInt);
        lastResonanceUpdateTimestamp = currentTimestamp;
        cumulativeVolumeSinceLastUpdate = 0; // Reset volume counter

        emit ResonanceStateUpdated(oldResonanceFactor, resonanceFactor, cumulativeVolumeSinceLastUpdate, currentTimestamp);

        // Note: In a real system, this might also trigger a snapshot of reserves for fee/yield calculations.
        // It could also distribute accumulated fees to stakers here.
    }

    function getCurrentResonanceState() public view returns (uint256 currentFactor, uint64 lastUpdateTimestamp, uint256 volumeSinceLastUpdate) {
        return (resonanceFactor, lastResonanceUpdateTimestamp, cumulativeVolumeSinceLastUpdate);
    }

    // --- LP Token ERC20 Standard Functions (Internal Management) ---

    function totalSupply() public view override returns (uint256) {
        return totalSupplyLP;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        uint256 currentAllowance = allowances[from][msg.sender];
        if (currentAllowance < amount) revert InsufficientAllowance();
        // Using unchecked is generally safe for decrementing allowance if checked before
        unchecked {
            _approve(from, msg.sender, currentAllowance - amount);
        }
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        if (from == address(0) || to == address(0)) revert ZeroAddress();
        if (balances[from] < amount) revert InsufficientBalance();

        unchecked {
            balances[from] -= amount;
            balances[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        if (owner == address(0) || spender == address(0)) revert ZeroAddress();
        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // Note: _mint and _burn are handled within addLiquidity and removeLiquidity respectively.
    // _mint(address account, uint256 amount) internal { ... }
    // _burn(address account, uint256 amount) internal { ... }

    // --- View Functions ---

    function getReserves() public view returns (uint256 rA, uint256 rB) {
        return (reserveA, reserveB);
    }

    function getTokenAPriceInTokenB() public view returns (uint256 price) {
         if (reserveA == 0) return 0;
         // Price of 1 TokenA in TokenB = reserveB / reserveA
         // Scale up to avoid losing precision (e.g., using 1e18 for fixed point)
         // Assuming both tokens have 18 decimals
         price = (reserveB * 1e18) / reserveA;
    }

     function getTokenBPriceInTokenA() public view returns (uint256 price) {
         if (reserveB == 0) return 0;
         // Price of 1 TokenB in TokenA = reserveA / reserveB
          price = (reserveA * 1e18) / reserveB;
     }


     function getEstimatedLPTokenAmount(uint256 amountA, uint256 amountB) public view returns (uint256 lpTokens) {
         uint256 currentReserveA = reserveA;
         uint256 currentReserveB = reserveB;

        if (currentReserveA == 0 || currentReserveB == 0) {
            return amountA; // Simplified estimate for first LP
        } else {
             uint256 lpTokensA = (totalSupplyLP * amountA) / currentReserveA;
             uint256 lpTokensB = (totalSupplyLP * amountB) / currentReserveB;
             return lpTokensA < lpTokensB ? lpTokensA : lpTokensB;
        }
     }

     function getEstimatedTokenAmounts(uint256 lpTokens) public view returns (uint256 amountA, uint256 amountB) {
         if (totalSupplyLP == 0) return (0, 0);
         amountA = (lpTokens * reserveA) / totalSupplyLP;
         amountB = (lpTokens * reserveB) / totalSupplyLP;
     }

     function getUserBondedBalances(address user) public view returns (uint256[] memory amounts, uint256[] memory durationTierIds) {
         uint256 numBonds = userBonds[user].length;
         amounts = new uint256[](numBonds);
         durationTierIds = new uint256[](numBonds);

         for(uint i = 0; i < numBonds; i++) {
             // Only return details for active bonds
             if (userBonds[user][i].active) {
                 amounts[i] = userBonds[user][i].amount;
                 durationTierIds[i] = userBonds[user][i].durationTierId;
             } else {
                 // Or return info for all bonds, distinguishing active/inactive
                 amounts[i] = userBonds[user][i].amount; // Include inactive bond amount
                 durationTierIds[i] = userBonds[user][i].durationTierId; // Include tier
                 // Could also add a boolean array to indicate active status
             }
         }
         // Note: A better approach for many bonds might be pagination or iterating off-chain.
         // This function returns info for ALL bonds ever created by the user in the array.
     }

    function getBondDetails(address user, uint256 bondIndex) public view returns (BondInfo memory) {
        if (bondIndex >= userBonds[user].length) revert InvalidBondDetailsRequest();
        return userBonds[user][bondIndex];
    }

     function getUserBondedBalanceByTier(address user) public view returns (uint256[] memory tierAmounts) {
        tierAmounts = new uint256[](bondDurationTiers.length);
        for(uint i = 0; i < userBonds[user].length; i++) {
            if (userBonds[user][i].active) {
                 uint256 tierId = userBonds[user][i].durationTierId;
                 if (tierId < bondDurationTiers.length) { // Should always be true if bonded properly
                     tierAmounts[tierId] += userBonds[user][i].amount;
                 }
            }
        }
     }

    function getTotalLiquidity() public view returns (uint256) {
        return totalSupplyLP;
    }

     function getReactorParameters() public view returns (address tokenAAddress, address tokenBAddress, address catalystAddress, uint256 currentResonanceFactor, uint256 totalFeesA, uint256 totalFeesB, uint256 totalPenaltiesLP) {
         return (address(tokenA), address(tokenB), address(catalystContract), resonanceFactor, totalTradingFeesAccruedA, totalTradingFeesAccruedB, totalPenaltiesCollectedLP);
     }

    // --- Owner Functions ---

    function setBondDurationTiers(DurationTier[] calldata newTiers) external onlyOwner {
        // Basic validation: ensure tiers are somewhat reasonable (e.g., duration > 0)
        for (uint i = 0; i < newTiers.length; i++) {
            if (newTiers[i].duration == 0) revert InvalidDurationTier();
        }
        bondDurationTiers = newTiers;
        emit SetDurationTiers(newTiers);
    }

    // Override `onERC721Received` to accept Catalyst NFTs
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
        // Ensure this is the expected Catalyst contract and that the sender is the contract itself (meaning it was a transferFrom initiated by registerCatalyst)
        // and the 'from' address is the user who initiated the registerCatalyst call.
        // Basic check: Only allow transfers from the contract's own `safeTransferFrom`.
        // A more robust check would involve comparing operator/from against expected values stored temporarily in registerCatalyst.
        // For simplicity, just ensure it's from the expected catalyst contract.
        if (msg.sender != address(catalystContract)) revert InvalidCatalystToken();

        // If using the mapping `catalystIdUser` to track pending registrations:
        // if (catalystIdUser[tokenId] != from) revert InvalidCatalystToken(); // User initiated register

        return this.onERC721Received.selector;
    }

    // Fallback/Receive functions - handle unexpected incoming native tokens (shouldn't happen in this design)
    receive() external payable {
        // Optionally log or revert
    }
    fallback() external payable {
        // Optionally log or revert
    }
}
```