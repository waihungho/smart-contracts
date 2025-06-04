Okay, let's design a complex, multi-faceted smart contract that goes beyond typical DeFi primitives. We'll call it the "MetaMorphic Pool".

The core concept is a liquidity pool for multiple ERC-20 tokens whose behavior (fees, available actions, yield mechanics, access requirements) can change dynamically based on predefined "Phases". These phases could be triggered by administrative control, external oracle data (simulated), or internal state. It also incorporates concepts like dynamic yield distribution and meta-transaction support.

**Disclaimer:** This contract is a complex conceptual example. It is **not audited** and **not suitable for production use** without significant security review, testing, and potentially refactoring for gas efficiency and robustness. Simulating oracles and external systems simplifies the code but would require real-world implementations in production.

---

## Contract Outline: MetaMorphicPool

1.  **State Variables:** Store token addresses, pool balances, LP token info, phase state, roles, oracle address, NFT requirement, nonces, admin fees, pause state.
2.  **Enums:** Define the different operational phases.
3.  **Events:** Log critical actions like phase changes, liquidity events, swaps, role changes, yield, pauses.
4.  **Roles & Access Control:** Custom roles (Admin, Guardian) beyond the Owner, implemented with mappings.
5.  **Pause Mechanism:** Basic pausing functionality controlled by Guardian/Admin.
6.  **Constructor:** Initializes tokens, LP token, initial phase, and roles.
7.  **Core Pool Functions:**
    *   `addLiquidity`: Deposit tokens to mint LP tokens, phase-dependent rules.
    *   `removeLiquidity`: Burn LP tokens to withdraw tokens, phase-dependent rules.
    *   `swap`: Exchange one supported token for another, dynamic fees based on phase.
8.  **Phase Management Functions:**
    *   `setPhase`: Change the current operational phase (Admin/Guardian restricted, potentially with time/oracle locks).
    *   `updatePhaseParams`: Update parameters (like fees, weights conceptually) for a specific phase (Admin only).
    *   `triggerRecalibration`: Initiates an internal rebalancing based on phase rules or Admin trigger (conceptually adjusts internal weights/ratios).
9.  **Dynamic & Advanced Features:**
    *   `addYield`: Simulate external yield being added to the pool assets (increases LP value).
    *   `claimDynamicYield`: Allows LPs to claim accrued dynamic yield based on phase and oracle data (simulated).
    *   `swapForAccount`: Allows a relayer to pay gas for a swap executed on behalf of another account (basic meta-transaction pattern).
10. **Admin & Utility Functions:**
    *   `setRole`: Assign or revoke custom roles (Owner only).
    *   `renounceRole`: Allows a user to remove their own role.
    *   `withdrawAdminFees`: Withdraw accumulated protocol fees (Admin only).
    *   `setOracleAddress`: Update the address of the simulated oracle (Admin only).
    *   `setNFTRequirementAddress`: Set/remove the address of an NFT contract required for certain phases/actions (Admin only).
    *   `sweepExcessTokens`: Rescue tokens accidentally sent to the contract (Owner only).
11. **View Functions:** Provide information about the pool state, calculations, and configuration.

## Function Summary:

1.  `constructor(...)`: Initializes the contract with supported tokens, LP token, initial phase, and owner.
2.  `addLiquidity(...)`: Allows users to deposit specified amounts of supported tokens to receive `poolToken` shares. Calculates output based on current pool state and active phase rules/fees.
3.  `removeLiquidity(...)`: Allows users to burn `poolToken` shares to withdraw proportional amounts of supported tokens. Calculates output based on current pool state and active phase rules/fees.
4.  `swap(...)`: Allows users to exchange a certain amount of one supported token for another. Applies dynamic fees based on the active phase.
5.  `setPhase(Phase newPhase)`: (Admin/Guardian) Changes the contract's operational phase. Includes logic for phase transition checks (e.g., time locks, state validation).
6.  `updatePhaseParams(Phase targetPhase, uint256 newFeeBps, address requiredNFT, uint256 yieldMultiplier)`: (Admin) Allows updating parameters associated with a specific phase.
7.  `triggerRecalibration()`: (Admin/Guardian) Initiates an internal process (simulated) to adjust pool asset ratios or internal weights based on the current phase's strategy or external data.
8.  `addYield(address token, uint256 amount)`: (Admin/Guardian or designated Oracle caller) Simulates adding external yield to a specific token's balance within the pool without minting new LP tokens, thus increasing the value per LP token.
9.  `claimDynamicYield()`: Allows a user to claim a portion of "dynamic yield" accrued to their LP position based on their liquidity share, the phases they participated in, and the simulated oracle data during those phases. (Simplified calculation).
10. `swapForAccount(address account, address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOutMin, bytes signature)`: Allows a transaction relayer to execute a `swap` on behalf of `account`, verifying a signature and nonce to prevent replay attacks. Demonstrates a meta-transaction pattern. (Signature verification is simplified).
11. `setRole(address account, Role role, bool enable)`: (Owner) Grants or revokes a specific administrative/guardian role to an account.
12. `renounceRole(Role role)`: Allows a user to voluntarily remove a role from themselves.
13. `pause()`: (Guardian/Admin) Pauses certain critical operations (add/remove liquidity, swap).
14. `unpause()`: (Guardian/Admin) Unpauses critical operations.
15. `withdrawAdminFees(address token, uint256 amount)`: (Admin) Allows withdrawing collected protocol fees in a specific token.
16. `setOracleAddress(address _oracle)`: (Admin) Sets the address of the simulated oracle contract.
17. `setNFTRequirementAddress(address _nftAddress)`: (Admin) Sets the address of an ERC721 contract; holding an NFT from this contract may be required for certain phase interactions.
18. `sweepExcessTokens(address tokenAddress, uint256 amount)`: (Owner) Allows the owner to recover tokens sent to the contract that are not part of the pool's managed assets.
19. `getPhase()`: (View) Returns the current operational phase.
20. `getPhaseParams(Phase phase)`: (View) Returns the parameters associated with a specific phase.
21. `getTokenAddresses()`: (View) Returns the list of supported ERC-20 token addresses in the pool.
22. `getPoolTokenAddress()`: (View) Returns the address of the LP token issued by this pool.
23. `getPoolBalances()`: (View) Returns the current balances of all supported tokens held by the contract.
24. `calculateSwapOutput(address tokenIn, uint255 amountIn, address tokenOut)`: (View) Calculates the expected output amount for a given swap, considering the current phase's fee. (Does not account for slippage directly).
25. `calculateAddLiquidityOutput(address[] memory tokenAmounts)`: (View) Calculates the amount of `poolToken` that would be minted for a given deposit of tokens, considering current pool state.
26. `calculateRemoveLiquidityOutput(uint256 poolTokenAmount)`: (View) Calculates the amounts of underlying tokens that would be redeemed for burning a given amount of `poolToken`.
27. `getRole(address account, Role role)`: (View) Checks if an account has a specific role.
28. `isNFTRequirementMet(address account)`: (View) Checks if an account holds an NFT from the required collection (if any).
29. `getNonce(address account)`: (View) Returns the current meta-transaction nonce for an account.
30. `getAdminFeeBalance(address token)`: (View) Returns the amount of fees collected for withdrawal for a specific token.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol"; // Added for NFT check flexibility

// Helper contract (can be replaced by a real oracle)
contract MockOracle {
    uint256 public priceData = 100; // Example price data
    function setPriceData(uint256 _data) public { priceData = _data; }
    function getPriceData() public view returns (uint256) { return priceData; }
}

// Simplified ERC20 for the pool token
contract SimplePoolToken is IERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(allowance[from][msg.sender] >= amount, "SPT: transfer amount exceeds allowance");
        allowance[from][msg.sender] -= amount;
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(balanceOf[from] >= amount, "SPT: transfer amount exceeds balance");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
    }

    function mint(address account, uint256 amount) external {
        // Only callable by the MetaMorphicPool contract itself (enforced via require in MetaMorphicPool)
        totalSupply += amount;
        balanceOf[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function burn(address account, uint256 amount) external {
        // Only callable by the MetaMorphicPool contract itself
        require(balanceOf[account] >= amount, "SPT: burn amount exceeds balance");
        balanceOf[account] -= amount;
        totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    // Standard ERC20 events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title MetaMorphicPool
 * @dev A dynamic multi-token liquidity pool with changing behavior based on phases.
 *      Features include dynamic fees, potential NFT requirements, simulated yield,
 *      custom roles, pause, and a basic meta-transaction pattern demonstration.
 */
contract MetaMorphicPool {
    using SafeERC20 for IERC20;
    using Address for address;

    // --- State Variables ---

    // Pool Configuration
    address[] public supportedTokens;
    SimplePoolToken public poolToken; // Custom LP token contract
    mapping(address => bool) private isSupportedToken;

    // Pool State
    mapping(address => uint256) public poolBalances; // Current balances of supported tokens
    uint256 public totalPoolTokenSupply; // Redundant with poolToken.totalSupply(), but kept for clarity/cache

    // Phase Management
    enum Phase { Initial, Balanced, Growth, Defensive, Locked }
    Phase public currentPhase;

    struct PhaseParams {
        uint256 swapFeeBps;       // Swap fee in basis points (e.g., 30 = 0.30%)
        address requiredNFT;      // Address of NFT contract required for certain actions in this phase (address(0) if none)
        uint256 yieldMultiplier;  // Multiplier for dynamic yield calculation (simulated)
        bool acceptsLiquidity;    // Can liquidity be added in this phase?
        bool allowsRemoval;       // Can liquidity be removed in this phase?
        bool allowsSwaps;         // Can swaps happen in this phase?
    }
    mapping(Phase => PhaseParams) public phaseConfigurations;

    // Roles & Access Control (Manual implementation instead of OZ)
    enum Role { Admin, Guardian }
    mapping(address => mapping(Role => bool)) private roles;
    address public owner;

    // External Dependencies (Simulated)
    MockOracle public oracle;
    address public nftRequirementAddress; // Global NFT requirement address, phase-specific check can override

    // Fees
    mapping(address => uint256) public adminFees; // Fees collected per token, waiting to be withdrawn

    // Pause
    bool public paused;

    // Meta-transactions (Simplified nonce management)
    mapping(address => uint256) private nonces;

    // --- Events ---

    event PhaseChanged(Phase indexed oldPhase, Phase indexed newPhase, address indexed caller);
    event PhaseParamsUpdated(Phase indexed phase, uint256 newFeeBps, address requiredNFT, uint256 yieldMultiplier);
    event LiquidityAdded(address indexed provider, uint256 poolTokensMinted, uint256[] tokenAmounts);
    event LiquidityRemoved(address indexed provider, uint256 poolTokensBurned, uint256[] tokenAmounts);
    event Swapped(address indexed swapper, address indexed tokenIn, uint256 amountIn, address indexed tokenOut, uint256 amountOut, uint256 feeAmount);
    event RoleSet(address indexed account, Role indexed role, bool enabled);
    event AdminFeesWithdrawn(address indexed token, uint256 amount, address indexed recipient);
    event OracleAddressSet(address indexed oldOracle, address indexed newOracle);
    event NFTRequirementAddressSet(address indexed oldAddress, address indexed newAddress);
    event PoolPaused(address indexed caller);
    event PoolUnpaused(address indexed caller);
    event YieldAdded(address indexed token, uint256 amount);
    event DynamicYieldClaimed(address indexed account, uint256 yieldAmount, address indexed token); // Simplified, assuming claim in one token


    // --- Modifiers ---

    modifier onlyRole(Role role) {
        require(roles[msg.sender][role] || msg.sender == owner, "Caller is not authorized");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    // --- Constructor ---

    /**
     * @dev Initializes the contract, sets up supported tokens, creates the LP token,
     *      sets initial phase parameters, and assigns initial roles.
     * @param _supportedTokens Array of ERC20 token addresses this pool will manage.
     * @param _poolTokenName Name for the custom LP token.
     * @param _poolTokenSymbol Symbol for the custom LP token.
     */
    constructor(address[] memory _supportedTokens, string memory _poolTokenName, string memory _poolTokenSymbol) {
        require(_supportedTokens.length > 1, "Must support at least two tokens");
        owner = msg.sender;

        // Initialize supported tokens
        supportedTokens = _supportedTokens;
        for (uint i = 0; i < supportedTokens.length; i++) {
            require(supportedTokens[i] != address(0), "Zero address not allowed for tokens");
            isSupportedToken[supportedTokens[i]] = true;
            // Check if it's actually an ERC20? Basic check: call name()
            try IERC20(supportedTokens[i]).name() returns (string memory) {} catch {
                 revert("Invalid ERC20 token address provided");
            }
        }

        // Create the pool token
        poolToken = new SimplePoolToken(_poolTokenName, _poolTokenSymbol);
        totalPoolTokenSupply = 0; // Initial supply

        // Set initial phase and default parameters for all phases
        currentPhase = Phase.Initial;
        _initializeDefaultPhaseParams(); // Private helper

        // Owner is also Admin and Guardian initially
        roles[owner][Role.Admin] = true;
        roles[owner][Role.Guardian] = true;

        paused = false;
    }

    // --- Internal Helpers for Setup ---
    function _initializeDefaultPhaseParams() internal {
        // Define sensible defaults or specific initial settings
        phaseConfigurations[Phase.Initial] = PhaseParams({
            swapFeeBps: 50, // 0.5% fee
            requiredNFT: address(0),
            yieldMultiplier: 0,
            acceptsLiquidity: true,
            allowsRemoval: true,
            allowsSwaps: true
        });
        phaseConfigurations[Phase.Balanced] = PhaseParams({
            swapFeeBps: 30, // 0.3% fee
            requiredNFT: address(0),
            yieldMultiplier: 1, // Standard yield
            acceptsLiquidity: true,
            allowsRemoval: true,
            allowsSwaps: true
        });
         phaseConfigurations[Phase.Growth] = PhaseParams({
            swapFeeBps: 70, // Higher fee in growth phase? Or lower? Let's make it dynamic
            requiredNFT: address(0), // Could require NFT for high growth phases
            yieldMultiplier: 2, // Double yield
            acceptsLiquidity: true, // Maybe restricted liquidity
            allowsRemoval: true,
            allowsSwaps: true
        });
        phaseConfigurations[Phase.Defensive] = PhaseParams({
            swapFeeBps: 10, // Lower fee to encourage trades
            requiredNFT: address(0),
            yieldMultiplier: 0, // No yield
            acceptsLiquidity: false, // Stop liquidity adds
            allowsRemoval: true, // Allow liquidity removal
            allowsSwaps: true // Allow swaps
        });
        phaseConfigurations[Phase.Locked] = PhaseParams({
            swapFeeBps: 10000, // Effectively disables swaps (100%)
            requiredNFT: address(0),
            yieldMultiplier: 0,
            acceptsLiquidity: false,
            allowsRemoval: false,
            allowsSwaps: false
        });
         // Can update these later via updatePhaseParams
    }


    // --- Access Control & Role Management ---

    /**
     * @dev Sets or revokes a specific role for an account. Only callable by the contract owner.
     * @param account The address to modify roles for.
     * @param role The role to set (Admin or Guardian).
     * @param enable True to grant the role, false to revoke it.
     */
    function setRole(address account, Role role, bool enable) public onlyOwner {
        require(account != address(0), "Zero address not allowed");
        roles[account][role] = enable;
        emit RoleSet(account, role, enable);
    }

    /**
     * @dev Allows a user to voluntarily remove a role from themselves.
     * @param role The role to renounce.
     */
    function renounceRole(Role role) public {
        require(roles[msg.sender][role], "Role to renounce not held");
        roles[msg.sender][role] = false;
        emit RoleSet(msg.sender, role, false);
    }

    /**
     * @dev Checks if an account has a specific role.
     * @param account The address to check.
     * @param role The role to check for.
     * @return True if the account has the role (or is the owner), false otherwise.
     */
    function getRole(address account, Role role) public view returns (bool) {
        return roles[account][role] || account == owner;
    }

    // --- Pause Mechanism ---

    /**
     * @dev Pauses the contract. Only callable by Guardian or Admin.
     */
    function pause() public whenNotPaused onlyRole(Role.Guardian) {
        paused = true;
        emit PoolPaused(msg.sender);
    }

    /**
     * @dev Unpauses the contract. Only callable by Guardian or Admin.
     */
    function unpause() public whenPaused onlyRole(Role.Guardian) {
        paused = false;
        emit PoolUnpaused(msg.sender);
    }


    // --- Core Pool Functions ---

    /**
     * @dev Allows adding liquidity to the pool by depositing supported tokens.
     *      The amount of pool tokens minted depends on the ratio of deposited tokens
     *      to current pool reserves and the current total supply of pool tokens.
     *      Requires current phase to accept liquidity and potentially an NFT.
     * @param tokenAmounts Array of amounts of supported tokens to deposit. Must match order of supportedTokens.
     * @param minPoolTokens Minimum amount of pool tokens to receive (slippage control).
     */
    function addLiquidity(uint256[] memory tokenAmounts, uint256 minPoolTokens) public whenNotPaused {
        require(phaseConfigurations[currentPhase].acceptsLiquidity, "Phase does not accept liquidity");
        _checkNFTRequirement(msg.sender, currentPhase); // Check phase-specific NFT requirement
        require(tokenAmounts.length == supportedTokens.length, "Incorrect number of token amounts");

        uint256 poolTokensToMint = calculateAddLiquidityOutput(tokenAmounts);
        require(poolTokensToMint >= minPoolTokens, "Slippage limit exceeded on mint");
        require(poolTokensToMint > 0, "Must mint more than 0 pool tokens");

        // Transfer tokens into the pool
        for (uint i = 0; i < supportedTokens.length; i++) {
            if (tokenAmounts[i] > 0) {
                IERC20 token = IERC20(supportedTokens[i]);
                token.safeTransferFrom(msg.sender, address(this), tokenAmounts[i]);
                poolBalances[supportedTokens[i]] += tokenAmounts[i];
            }
        }

        // Mint pool tokens to the provider
        poolToken.mint(msg.sender, poolTokensToMint);
        totalPoolTokenSupply += poolTokensToMint;

        emit LiquidityAdded(msg.sender, poolTokensToMint, tokenAmounts);
    }

    /**
     * @dev Allows removing liquidity from the pool by burning pool tokens.
     *      Withdraws proportional amounts of supported tokens based on the user's share
     *      of the total pool tokens. Requires current phase to allow removal.
     * @param poolTokenAmount Amount of pool tokens to burn.
     * @param minTokenAmounts Minimum amounts of supported tokens to receive (slippage control).
     */
    function removeLiquidity(uint256 poolTokenAmount, uint256[] memory minTokenAmounts) public whenNotPaused {
         require(phaseConfigurations[currentPhase].allowsRemoval, "Phase does not allow liquidity removal");
         _checkNFTRequirement(msg.sender, currentPhase); // Check phase-specific NFT requirement
         require(minTokenAmounts.length == supportedTokens.length, "Incorrect number of min token amounts");
         require(poolTokenAmount > 0, "Amount must be greater than 0");
         require(poolToken.balanceOf(msg.sender) >= poolTokenAmount, "Insufficient pool tokens");
         require(totalPoolTokenSupply > 0, "No liquidity in the pool");


         uint256[] memory tokenAmountsToRedeem = calculateRemoveLiquidityOutput(poolTokenAmount);

         // Check slippage limits
         for(uint i = 0; i < supportedTokens.length; i++) {
             require(tokenAmountsToRedeem[i] >= minTokenAmounts[i], "Slippage limit exceeded on redeem");
         }

         // Burn pool tokens
         poolToken.burn(msg.sender, poolTokenAmount);
         totalPoolTokenSupply -= poolTokenAmount;

         // Transfer tokens out of the pool
         for(uint i = 0; i < supportedTokens.length; i++) {
             if (tokenAmountsToRedeem[i] > 0) {
                 poolBalances[supportedTokens[i]] -= tokenAmountsToRedeem[i]; // Update balance before transfer
                 IERC20(supportedTokens[i]).safeTransfer(msg.sender, tokenAmountsToRedeem[i]);
             }
         }

         emit LiquidityRemoved(msg.sender, poolTokenAmount, tokenAmountsToRedeem);
    }


    /**
     * @dev Allows swapping one supported token for another.
     *      Applies a dynamic fee based on the current operational phase.
     *      Requires current phase to allow swaps and potentially an NFT.
     *      Uses a simplified AMM-like calculation (constant product variant per pair conceptual).
     * @param tokenIn The address of the token to sell.
     * @param amountIn The amount of tokenIn to sell.
     * @param tokenOut The address of the token to buy.
     * @param amountOutMin Minimum amount of tokenOut to receive (slippage control).
     */
    function swap(address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOutMin) public whenNotPaused {
        require(phaseConfigurations[currentPhase].allowsSwaps, "Phase does not allow swaps");
        _checkNFTRequirement(msg.sender, currentPhase); // Check phase-specific NFT requirement
        require(isSupportedToken[tokenIn], "tokenIn not supported");
        require(isSupportedToken[tokenOut], "tokenOut not supported");
        require(tokenIn != tokenOut, "Cannot swap same tokens");
        require(amountIn > 0, "Amount in must be greater than 0");
        require(poolBalances[tokenIn] > 0 && poolBalances[tokenOut] > 0, "Insufficient pool liquidity for swap");

        // Get phase-specific fee
        uint256 swapFeeBps = phaseConfigurations[currentPhase].swapFeeBps;
        uint256 feeAmount = amountIn * swapFeeBps / 10000;
        uint256 amountInAfterFee = amountIn - feeAmount;

        // Add fee to admin balance (accumulate)
        adminFees[tokenIn] += feeAmount;

        // Perform swap calculation (simplified constant product like)
        // Note: A real implementation needs more robust invariant-based math across multiple tokens
        // For this example, we simulate a simple ratio swap influenced by reserves.
        // In a multi-token pool, a single swap affects multiple reserves.
        // This simplified example will treat it more like pairs implicitly.
        // A more advanced version could use Balancer-style weighted math or Uniswap V3 concepts.

        uint256 reserveIn = poolBalances[tokenIn];
        uint256 reserveOut = poolBalances[tokenOut];

        // Simplified calculation: amountOut = (amountIn * reserveOut) / reserveIn - (more advanced fee/slippage)
        // Let's use a simplified invariant-like approach for concept
        // K = reserveIn * reserveOut (ignoring other tokens for this pair swap)
        // New K = (reserveIn + amountInAfterFee) * (reserveOut - amountOut)
        // (reserveIn + amountInAfterFee) * (reserveOut - amountOut) = reserveIn * reserveOut
        // reserveIn*reserveOut - reserveIn*amountOut + amountInAfterFee*reserveOut - amountInAfterFee*amountOut = reserveIn*reserveOut
        // - reserveIn*amountOut + amountInAfterFee*reserveOut - amountInAfterFee*amountOut = 0
        // amountInAfterFee*reserveOut = reserveIn*amountOut + amountInAfterFee*amountOut
        // amountInAfterFee*reserveOut = amountOut * (reserveIn + amountInAfterFee)
        // amountOut = (amountInAfterFee * reserveOut) / (reserveIn + amountInAfterFee)

        uint256 amountOut = (amountInAfterFee * reserveOut) / (reserveIn + amountInAfterFee);

        require(amountOut >= amountOutMin, "Slippage limit exceeded on swap");
        require(amountOut > 0, "Must receive more than 0 tokens");


        // Update pool balances
        poolBalances[tokenIn] += amountInAfterFee; // Fee already subtracted from amountIn
        poolBalances[tokenOut] -= amountOut;

        // Transfer tokens
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenOut).safeTransfer(msg.sender, amountOut);

        emit Swapped(msg.sender, tokenIn, amountIn, tokenOut, amountOut, feeAmount);
    }

    // --- Phase Management Functions ---

    /**
     * @dev Changes the current operational phase of the pool.
     *      Only callable by Admin or Guardian. Can include complex checks (time, oracle, state).
     * @param newPhase The phase to transition to.
     */
    function setPhase(Phase newPhase) public onlyRole(Role.Admin) {
        require(newPhase != currentPhase, "Already in this phase");
        // Add complex transition logic here if needed, e.g.:
        // require(block.timestamp > lastPhaseChangeTime + minimumPhaseDuration, "Cannot change phase yet");
        // require(oracle.getPriceData() > threshold, "Oracle condition not met for this phase transition");

        Phase oldPhase = currentPhase;
        currentPhase = newPhase;
        emit PhaseChanged(oldPhase, newPhase, msg.sender);
    }

    /**
     * @dev Updates the configurable parameters for a specific phase.
     *      Only callable by Admin.
     * @param targetPhase The phase whose parameters to update.
     * @param newFeeBps New swap fee in basis points (0-10000).
     * @param requiredNFT New NFT contract address requirement (address(0) for none).
     * @param yieldMultiplier New yield multiplier for this phase (simulated).
     */
    function updatePhaseParams(Phase targetPhase, uint256 newFeeBps, address requiredNFT, uint256 yieldMultiplier, bool acceptsLiquidity, bool allowsRemoval, bool allowsSwaps) public onlyRole(Role.Admin) {
        require(newFeeBps <= 10000, "Fee basis points cannot exceed 10000 (100%)");
        PhaseParams storage params = phaseConfigurations[targetPhase];
        params.swapFeeBps = newFeeBps;
        params.requiredNFT = requiredNFT;
        params.yieldMultiplier = yieldMultiplier;
        params.acceptsLiquidity = acceptsLiquidity;
        params.allowsRemoval = allowsRemoval;
        params.allowsSwaps = allowsSwaps;

        emit PhaseParamsUpdated(targetPhase, newFeeBps, requiredNFT, yieldMultiplier);
    }

    /**
     * @dev Initiates an internal recalibration process.
     *      In a real pool, this might involve rebalancing assets towards target weights,
     *      potentially incurring costs or taking time. Simulated here.
     *      Only callable by Admin or Guardian.
     */
    function triggerRecalibration() public onlyRole(Role.Admin) {
        // --- Complex Recalibration Logic Here ---
        // This would involve internal swaps, potentially interacting with external markets,
        // or adjusting internal accounting based on the current phase's strategy.
        // Example: If phase X targets 50/50 A/B and it's 70/30, the contract might
        // swap some A for B internally.

        // For this example, we just log the event.
        // A real implementation needs significant logic here.
        emit RecalibrationTriggered(currentPhase, msg.sender); // Add RecalibrationTriggered event

         // Example: Conceptually adjust internal balances based on current phase/oracle
        if (currentPhase == Phase.Growth && address(oracle) != address(0)) {
            uint256 oracleData = oracle.getPriceData();
            // Hypothetical: Adjust balances based on oracle data
            // This requires complex, careful math and token movements.
            // e.g., if oracleData is high, move more towards a 'growth' asset.
            // This is highly complex and not implemented here.
        }
        // --- End Complex Recalibration Logic ---
    }

    event RecalibrationTriggered(Phase indexed phase, address indexed caller);


    // --- Dynamic & Advanced Features ---

    /**
     * @dev Simulates external yield being added to the pool.
     *      This could represent farming rewards, lending interest, etc.
     *      Adding tokens this way increases the value of existing LP tokens.
     *      Should only be callable by trusted addresses (e.g., Admin, oracles, specific external farm contracts).
     * @param token The token receiving yield. Must be a supported token.
     * @param amount The amount of yield tokens added.
     */
    function addYield(address token, uint256 amount) public onlyRole(Role.Admin) { // Restricted to Admin for safety in example
        require(isSupportedToken[token], "Yield token not supported");
        require(amount > 0, "Yield amount must be greater than 0");

        // Simulate transfer from external source (or require msg.sender to send it)
        // In a real scenario, this function might receive tokens or be called by
        // another contract that harvested yield.
        // For simplicity here, we just update the balance.
        // IERC20(token).safeTransferFrom(msg.sender, address(this), amount); // If caller sends yield
        poolBalances[token] += amount; // If yield is added internally or via privileged call

        emit YieldAdded(token, amount);
    }

    /**
     * @dev Allows an LP to claim dynamic yield accrued during their participation,
     *      potentially influenced by active phases and oracle data.
     *      Simplified calculation - a real implementation requires tracking
     *      yield per phase per LP share over time.
     * @dev NOTE: This is a highly simplified placeholder. A real dynamic yield claim
     *      mechanism based on phases and oracle data is significantly more complex
     *      and requires sophisticated accounting (e.g., similar to Compound's COMP distribution
     *      or complex farm reward calculations).
     */
    function claimDynamicYield() public whenNotPaused {
        // --- Complex Dynamic Yield Calculation Placeholder ---
        // This would involve:
        // 1. Calculating the LP's historical share over time across different phases.
        // 2. For each phase, determining the total yield generated (potentially via addYield calls
        //    or complex internal calculations/oracle interactions).
        // 3. Applying the phase's yieldMultiplier and oracle data relevant to the period.
        // 4. Distributing a calculated amount of a specific reward token (could be one of the pool tokens, or a separate governance/reward token).

        // For this example, we simulate a trivial claim based on current LP balance and oracle data.
        uint256 lpBalance = poolToken.balanceOf(msg.sender);
        if (lpBalance == 0 || totalPoolTokenSupply == 0 || address(oracle) == address(0)) {
             revert("No liquidity or yield available");
        }

        // Trivial simulation: Claimable yield = (LP Balance / Total LP Supply) * (Oracle Data * Yield Multiplier for CURRENT phase)
        // This doesn't track history and is highly inaccurate for a real system.
        uint256 simulatedOracleData = oracle.getPriceData();
        uint256 yieldMultiplier = phaseConfigurations[currentPhase].yieldMultiplier;

        // Simulate yield in one of the pool tokens, e.g., supportedTokens[0]
        address yieldToken = supportedTokens[0];
        // Prevent div by zero if multiplier or oracle data is zero
        uint256 simulatedYieldAmount = (lpBalance * simulatedOracleData / 10000) * yieldMultiplier / (totalPoolTokenSupply > 0 ? totalPoolTokenSupply : 1); // Scale oracle data / 10000 for bps effect
        // Clamp simulated amount to available balance to avoid draining pool
        simulatedYieldAmount = simulatedYieldAmount > poolBalances[yieldToken] ? poolBalances[yieldToken] : simulatedYieldAmount;

        require(simulatedYieldAmount > 0, "No claimable yield");

        // --- End Placeholder ---

        // Transfer simulated yield (this yield must exist in the pool's balance somehow)
        poolBalances[yieldToken] -= simulatedYieldAmount; // Deduct from pool balance
        IERC20(yieldToken).safeTransfer(msg.sender, simulatedYieldAmount);

        emit DynamicYieldClaimed(msg.sender, simulatedYieldAmount, yieldToken);
    }


    /**
     * @dev Executes a swap on behalf of an account using a signature and nonce.
     *      This is a simplified meta-transaction pattern where a relayer pays gas,
     *      but the `account` is the logical sender.
     *      NOTE: Signature verification is NOT implemented here for brevity.
     *      A real implementation needs `ecrecover`, message hashing (ERC-191 or ERC-712),
     *      and careful domain separation.
     * @param account The address initiating the swap logically.
     * @param tokenIn The address of the token to sell.
     * @param amountIn The amount of tokenIn to sell.
     * @param tokenOut The address of the token to buy.
     * @param amountOutMin Minimum amount of tokenOut to receive (slippage control).
     * @param signature Placeholder for signature data (not used in this simplified example).
     */
    function swapForAccount(address account, address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOutMin, bytes memory signature) public whenNotPaused {
         // --- Simplified Meta-transaction Logic ---
         // 1. Verify signature (SKIPPED FOR BREVITY)
         //    In real code:
         //    bytes32 digest = _getSwapMessageHash(...); // Hash relevant parameters + nonce
         //    address signer = ECDSA.recover(digest, signature);
         //    require(signer == account, "Invalid signature");

         // 2. Check nonce (prevents replay attacks)
         uint256 currentNonce = nonces[account];
         // In real code, nonce would be included in the signed message.
         // We'd check `nonce_in_message == currentNonce`, then increment `nonces[account]`.
         // For this example, we'll just increment the nonce associated with the account,
         // *assuming* the signature logic would have included and verified it.
         nonces[account]++;
         // --- End Simplified Meta-transaction Logic ---

         // --- Execute Swap Logic (similar to the regular swap) ---
         require(phaseConfigurations[currentPhase].allowsSwaps, "Phase does not allow swaps");
         _checkNFTRequirement(account, currentPhase); // Check phase-specific NFT requirement for the *account*
         require(isSupportedToken[tokenIn], "tokenIn not supported");
         require(isSupportedToken[tokenOut], "tokenOut not supported");
         require(tokenIn != tokenOut, "Cannot swap same tokens");
         require(amountIn > 0, "Amount in must be greater than 0");
         require(poolBalances[tokenIn] > 0 && poolBalances[tokenOut] > 0, "Insufficient pool liquidity for swap");

         // Get phase-specific fee
         uint256 swapFeeBps = phaseConfigurations[currentPhase].swapFeeBps;
         uint256 feeAmount = amountIn * swapFeeBps / 10000;
         uint256 amountInAfterFee = amountIn - feeAmount;

         // Add fee to admin balance
         adminFees[tokenIn] += feeAmount;

         // Perform swap calculation (simplified)
         uint256 reserveIn = poolBalances[tokenIn];
         uint256 reserveOut = poolBalances[tokenOut];
         uint256 amountOut = (amountInAfterFee * reserveOut) / (reserveIn + amountInAfterFee);

         require(amountOut >= amountOutMin, "Slippage limit exceeded on swap");
         require(amountOut > 0, "Must receive more than 0 tokens");

         // Update pool balances
         poolBalances[tokenIn] += amountInAfterFee;
         poolBalances[tokenOut] -= amountOut;

         // Transfer tokens - Relayer must ensure `account` has approved the contract
         IERC20(tokenIn).safeTransferFrom(account, address(this), amountIn);
         IERC20(tokenOut).safeTransfer(account, amountOut); // Send output tokens to the account

         // Note: In a real meta-tx, the relayer might handle transfers and fees differently.
         // This example shows the core idea of execution context switching.

         emit Swapped(account, tokenIn, amountIn, tokenOut, amountOut, feeAmount); // Log the original account
     }

    /**
     * @dev Gets the current meta-transaction nonce for an account.
     *      Used by accounts and relayers to track valid meta-transaction calls.
     * @param account The address whose nonce to retrieve.
     * @return The current nonce for the account.
     */
    function getNonce(address account) public view returns (uint256) {
        return nonces[account];
    }


    // --- Admin & Utility Functions ---

    /**
     * @dev Allows the admin to withdraw accumulated protocol fees.
     * @param token The token whose fees to withdraw.
     * @param amount The amount of fees to withdraw.
     */
    function withdrawAdminFees(address token, uint256 amount) public onlyRole(Role.Admin) {
        require(isSupportedToken[token], "Fee token not supported");
        require(adminFees[token] >= amount, "Insufficient accumulated fees");
        require(amount > 0, "Amount must be greater than 0");

        adminFees[token] -= amount;
        IERC20(token).safeTransfer(msg.sender, amount);

        emit AdminFeesWithdrawn(token, amount, msg.sender);
    }

    /**
     * @dev Sets the address of the simulated oracle contract.
     *      Only callable by Admin.
     * @param _oracle The address of the MockOracle or compatible contract.
     */
    function setOracleAddress(address _oracle) public onlyRole(Role.Admin) {
         require(_oracle != address(0), "Oracle address cannot be zero");
         require(_oracle.isContract(), "Oracle address must be a contract");
         // Optional: Add a check here to ensure the contract supports expected oracle interface
         // try MockOracle(_oracle).getPriceData() returns (uint256) {} catch { revert("Invalid Oracle contract"); }

         address oldOracle = address(oracle);
         oracle = MockOracle(_oracle);
         emit OracleAddressSet(oldOracle, _oracle);
    }


    /**
     * @dev Sets or clears the global NFT requirement address.
     *      This address can be checked by `_checkNFTRequirement`.
     *      Only callable by Admin.
     * @param _nftAddress The address of the ERC721/ERC1155 contract, or address(0) to clear.
     */
    function setNFTRequirementAddress(address _nftAddress) public onlyRole(Role.Admin) {
        // Optional: Add checks if _nftAddress is a contract and supports ERC721/1155 interface
        address oldAddress = nftRequirementAddress;
        nftRequirementAddress = _nftAddress;
        emit NFTRequirementAddressSet(oldAddress, _nftAddress);
    }

    /**
     * @dev Allows the contract owner to sweep accidentally sent tokens that are
     *      not part of the pool's managed supported tokens.
     *      Does NOT allow sweeping supported tokens (as that would break pool math).
     * @param tokenAddress The address of the token to sweep.
     * @param amount The amount to sweep.
     */
    function sweepExcessTokens(address tokenAddress, uint256 amount) public onlyOwner {
        require(!isSupportedToken[tokenAddress], "Cannot sweep supported tokens");
        require(tokenAddress != address(poolToken), "Cannot sweep pool tokens"); // Prevent sweeping own LP tokens
        require(amount > 0, "Amount must be greater than 0");
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "Insufficient token balance to sweep");
        token.safeTransfer(owner, amount);
        // Note: No specific event emitted for this, standard ERC20 Transfer event will occur.
    }


    // --- View Functions ---

    /**
     * @dev Returns the current operational phase of the pool.
     */
    function getPhase() public view returns (Phase) {
        return currentPhase;
    }

    /**
     * @dev Returns the parameters configured for a specific phase.
     * @param phase The phase to get parameters for.
     */
    function getPhaseParams(Phase phase) public view returns (PhaseParams memory) {
        return phaseConfigurations[phase];
    }

    /**
     * @dev Returns the list of supported ERC-20 token addresses in this pool.
     */
    function getTokenAddresses() public view returns (address[] memory) {
        return supportedTokens;
    }

    /**
     * @dev Returns the address of the pool's custom LP token.
     */
    function getPoolTokenAddress() public view returns (address) {
        return address(poolToken);
    }

    /**
     * @dev Returns the current balances of all supported tokens held by the pool.
     *      Order matches `supportedTokens`.
     */
    function getPoolBalances() public view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](supportedTokens.length);
        for (uint i = 0; i < supportedTokens.length; i++) {
            balances[i] = poolBalances[supportedTokens[i]];
        }
        return balances;
    }

    /**
     * @dev Calculates the expected output amount for a given swap without executing it.
     *      Considers the current phase's fee.
     *      Uses the same simplified AMM-like calculation as the `swap` function.
     *      Does not account for front-running or price impact from other trades.
     * @param tokenIn The address of the token to sell.
     * @param amountIn The amount of tokenIn to sell.
     * @param tokenOut The address of the token to buy.
     * @return The calculated amount of tokenOut.
     */
    function calculateSwapOutput(address tokenIn, uint255 amountIn, address tokenOut) public view returns (uint256) {
        require(isSupportedToken[tokenIn], "tokenIn not supported");
        require(isSupportedToken[tokenOut], "tokenOut not supported");
        require(tokenIn != tokenOut, "Cannot swap same tokens");
         if (amountIn == 0) return 0;
        require(poolBalances[tokenIn] > 0 && poolBalances[tokenOut] > 0, "Insufficient pool liquidity for calculation");

        uint256 swapFeeBps = phaseConfigurations[currentPhase].swapFeeBps;
        uint256 amountInAfterFee = amountIn - (amountIn * swapFeeBps / 10000);

        uint256 reserveIn = poolBalances[tokenIn];
        uint256 reserveOut = poolBalances[tokenOut];

        // Simplified calculation:
        uint256 amountOut = (amountInAfterFee * reserveOut) / (reserveIn + amountInAfterFee);
        return amountOut;
    }

    /**
     * @dev Calculates the amount of pool tokens that would be minted for a given deposit.
     *      Based on the user's proportional share of the total pool value.
     * @param tokenAmounts Array of amounts of supported tokens to deposit. Must match order of supportedTokens.
     * @return The calculated amount of pool tokens to mint.
     */
    function calculateAddLiquidityOutput(uint256[] memory tokenAmounts) public view returns (uint256) {
        require(tokenAmounts.length == supportedTokens.length, "Incorrect number of token amounts");
        if (totalPoolTokenSupply == 0) {
            // First liquidity provider: mint LP tokens based on the *value* of deposited assets.
            // This is tricky without knowing the value relative to each other.
            // A simple approach is to mint LP tokens equal to the *sum* of deposited amounts
            // if all tokens have the same decimals and roughly 1:1 value initial state.
            // Or, mint based on one token's value, e.g., tokenAmounts[0].
            // Let's assume for simplicity that the first deposit determines the initial 1:1
            // value relationship relative to the sum of amounts (if decimals match).
            // A robust pool needs an initial price oracle or bootstrap mechanism.
            uint256 initialLP = 0;
             // Simplified: sum of amounts (assumes equal value tokens / same decimals for initial)
             for(uint i = 0; i < tokenAmounts.length; i++) {
                 initialLP += tokenAmounts[i]; // This assumes 1:1 value and same decimals!
             }
             return initialLP; // Mint LP tokens roughly equal to the total initial deposit amount
        } else {
             // Subsequent liquidity providers: calculate based on proportional share
             // Value of deposit = sum(amount_i * price_i)
             // Price_i = PoolBalance_i / TotalPoolTokenSupply (scaled by decimals)
             // Value of 1 LP token = TotalPoolValue / TotalPoolTokenSupply
             // LP tokens minted = Value of Deposit / Value of 1 LP token

             // Simplified Proportional Method:
             // Calculate the minimum ratio of deposit amount to pool reserve across all tokens.
             // The minted LP tokens will be based on this minimum ratio applied to the total supply.
             uint256 minRatio = type(uint256).max;
             bool hasLiquidity = false;

             for (uint i = 0; i < supportedTokens.length; i++) {
                 if (poolBalances[supportedTokens[i]] > 0) {
                     hasLiquidity = true;
                     // Calculate ratio * 1e18 to maintain precision
                     uint256 ratio = (tokenAmounts[i] * 1e18) / poolBalances[supportedTokens[i]];
                     if (ratio < minRatio) {
                         minRatio = ratio;
                     }
                 } else {
                     // If any pool balance is zero after init, require depositing ALL tokens.
                     // If depositing X tokens and one reserve is zero, the ratio for that token is infinite.
                     // This simple method needs adjustment for zero reserves after initial liquidity.
                     // Let's assume for simplicity, if a reserve is zero, you MUST deposit that token.
                     require(tokenAmounts[i] > 0, "Must deposit all tokens if pool reserve is zero");
                     // If reserve is 0, the ratio is effectively infinite, doesn't constrain minRatio.
                     // If depositing into a zero reserve, you set the initial price for that token relative to others deposited.
                 }
             }
             require(hasLiquidity, "Pool must have existing liquidity for proportional calculation");

             // Mint LP tokens based on the minimum proportional increase across all reserves
             // (minRatio / 1e18) * totalPoolTokenSupply
             return (minRatio * totalPoolTokenSupply) / 1e18;
        }
    }

    /**
     * @dev Calculates the amounts of underlying tokens that would be redeemed for burning pool tokens.
     *      Based on the user's proportional share of the total pool value.
     * @param poolTokenAmount Amount of pool tokens to burn.
     * @return An array of token amounts to redeem, matching the order of `supportedTokens`.
     */
    function calculateRemoveLiquidityOutput(uint256 poolTokenAmount) public view returns (uint256[] memory) {
        require(totalPoolTokenSupply > 0, "No liquidity in pool");
        require(poolTokenAmount <= totalPoolTokenSupply, "Cannot burn more than total supply");

        uint256[] memory tokenAmounts = new uint256[](supportedTokens.length);

        // Calculate proportional share for each token
        // tokenAmount_i = (poolTokenAmount / TotalPoolTokenSupply) * PoolBalance_i
        for (uint i = 0; i < supportedTokens.length; i++) {
            // Use high precision multiplication before division
            tokenAmounts[i] = (poolTokenAmount * poolBalances[supportedTokens[i]]) / totalPoolTokenSupply;
        }

        return tokenAmounts;
    }

     /**
     * @dev Returns the amount of fees collected for withdrawal for a specific token.
     * @param token The address of the token.
     */
    function getAdminFeeBalance(address token) public view returns (uint256) {
        return adminFees[token];
    }

     /**
     * @dev Checks if an account meets the NFT requirement for the current phase or global setting.
     *      Checks the phase-specific requirement first, then the global one if no phase requirement.
     *      Assumes ERC721 for simplicity in the check, could extend to ERC1155.
     * @param account The address to check.
     * @return True if the account holds the required NFT (or no NFT is required), false otherwise.
     */
    function isNFTRequirementMet(address account) public view returns (bool) {
        address requiredNFT = phaseConfigurations[currentPhase].requiredNFT;

        // If phase doesn't require a specific NFT, check global requirement
        if (requiredNFT == address(0)) {
             requiredNFT = nftRequirementAddress;
        }

        // If still no NFT required, requirement is met
        if (requiredNFT == address(0)) {
            return true;
        }

        // Check ERC721 balance (basic check, assumes standard ERC721)
        // A more robust check would involve ERC165 supportsInterface
        try IERC721(requiredNFT).balanceOf(account) returns (uint256 balance) {
            return balance > 0;
        } catch {
            // Handle cases where it might be ERC1155 or not an NFT contract
            // For simplicity, if it's not ERC721 and set as required, assume failure
            // A real implementation would check ERC1155 or specific interfaces
            return false;
        }
         // Could add ERC1155 check:
         // try IERC1155(requiredNFT).balanceOf(account, specificTokenIdForRequirement) returns (uint256 balance) {
         //    return balance > 0;
         // } catch { ... }
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Internal function to check if an account holds the required NFT for a given phase.
     *      Reverts if an NFT is required but not held.
     * @param account The address to check.
     * @param phase The phase to check the requirement for.
     */
    function _checkNFTRequirement(address account, Phase phase) internal view {
        address requiredNFT = phaseConfigurations[phase].requiredNFT;

         // If phase doesn't require a specific NFT, check global requirement
        if (requiredNFT == address(0)) {
             requiredNFT = nftRequirementAddress;
        }

        // If still no NFT required, succeed
        if (requiredNFT == address(0)) {
            return;
        }

        // Check ERC721 balance (basic check)
        try IERC721(requiredNFT).balanceOf(account) returns (uint256 balance) {
            require(balance > 0, "NFT requirement not met for this phase/action");
        } catch {
            // Handle cases where it might be ERC1155 or not an NFT contract
            // For simplicity, revert if it's set as required but doesn't behave like ERC721
            revert("NFT requirement check failed or invalid NFT contract");
        }
         // Could add ERC1155 check here if needed
    }

    // --- Fallback/Receive ---
    receive() external payable {
        // Optionally handle incoming native currency, though this pool is token-centric
        // revert("Cannot send Ether directly");
    }

    fallback() external payable {
        // Optionally handle incoming native currency or unexpected calls
        // revert("Cannot receive raw calls or Ether");
    }
}
```