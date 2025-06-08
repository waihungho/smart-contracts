Okay, let's design a smart contract concept that incorporates several advanced, non-standard ideas around token state, time, decay, and complex interactions, moving beyond typical ERC20/NFT/DAO patterns.

We'll call it `QuantumEcho`. The core idea is a token (`EQO`) where users can create "Echoes" of their balance at a point in time. These Echoes are non-fungible *representations* of past state that decay over time but can be interacted with (collapsed, merged, boosted) and potentially contribute to generating new EQO via an "Equilibrium" mechanism.

This contract will implement a custom token standard similar to ERC20 internally and manage Echoes using structs and mappings.

---

## QuantumEcho Smart Contract: Outline and Function Summary

This contract manages a custom token (`EQO`) and associated non-fungible "Echo" states created from EQO balances. Echoes decay over time but provide unique interactions and potential yield generation.

**Core Concepts:**

1.  **EQO Token:** A standard-like fungible token.
2.  **Echoes:** Non-fungible structs representing a user's EQO balance at creation time.
3.  **Decay:** Echoes' value/potential decays over time based on a contract-wide rate.
4.  **Equilibrium Generation:** A mechanism allowing users with active Echoes to generate new EQO based on their holdings and time.
5.  **Complex Interactions:** Functions to collapse decayed Echoes back to EQO, merge multiple Echoes, boost Echo stability, and conditionally transfer Echo ownership.

**Data Structures:**

*   `Echo`: Struct holding details of an Echo (owner, initial balance, creation timestamp, stability multiplier, status).
*   `echoes`: Mapping from unique ID to `Echo` struct.
*   `userEchoIds`: Mapping from user address to a dynamic array of their Echo IDs.
*   `userLastEquilibriumClaim`: Mapping from user address to the timestamp of their last yield claim.

**State Variables:**

*   ERC20-like state (`_balances`, `_allowances`, `_totalSupply`, `name`, `symbol`).
*   `_echoCounter`: Counter for unique Echo IDs.
*   `_decayRatePerSecondScaled`: Global rate at which Echoes decay (scaled for fixed-point math).
*   `_equilibriumYieldRatePerSecondScaled`: Global rate for EQO generation based on active Echoes (scaled).
*   `_creationFeeEQO`: Fee to create an Echo (in EQO).
*   `_collapseFeeEQO`: Fee to collapse an Echo (in EQO).
*   `_mergeFeeEQO`: Fee to merge Echoes (in EQO).
*   `owner`: Contract owner address.
*   `paused`: Paused state flag.

**Function Summary (>20 functions):**

1.  **ERC20-like Functions (Public/External):**
    *   `name()`: Get token name.
    *   `symbol()`: Get token symbol.
    *   `totalSupply()`: Get total EQO supply.
    *   `balanceOf(address account)`: Get EQO balance of an account.
    *   `transfer(address recipient, uint256 amount)`: Transfer EQO.
    *   `allowance(address owner, address spender)`: Get allowance.
    *   `approve(address spender, uint256 amount)`: Set allowance.
    *   `transferFrom(address sender, address recipient, uint256 amount)`: Transfer with allowance.
2.  **Echo Management Functions (Public/External):**
    *   `createEcho(uint256 amount)`: Create an Echo from a portion of sender's EQO balance. Burns creation fee.
    *   `getEchoCount(address account)`: Get the number of Echoes owned by an account.
    *   `getEchoDetails(uint265 echoId)`: Get details of a specific Echo (view function).
    *   `listUserEchoIds(address account)`: Get list of Echo IDs owned by an account (view function, potentially gas-intensive for many echoes).
3.  **Echo Interaction Functions (Public/External):**
    *   `collapseEcho(uint256 echoId)`: Collapse a decayed Echo back into EQO. Amount returned depends on decay level. Burns collapse fee.
    *   `mergeEchoes(uint256[] calldata echoIds)`: Merge multiple of sender's Echoes into a new, single Echo. Initial balance of new Echo based on decayed value of merged ones, potentially with bonus/penalty. Burns merge fee.
    *   `boostEchoStability(uint256 echoId, uint256 eqoAmount)`: Spend EQO to increase an Echo's stability multiplier, slowing its decay.
    *   `transferEchoOwnership(uint256 echoId, address newOwner)`: Transfer ownership of a specific Echo. Requires meeting certain conditions (e.g., high decay level, owner consent).
4.  **Equilibrium Generation (Public/External):**
    *   `generateEquilibriumEQO()`: Claim accumulated EQO yield based on holding active Echoes over time.
5.  **Query/View Functions (Public/View):**
    *   `getCurrentDecayRateScaled()`: Get the current global decay rate.
    *   `getCurrentEquilibriumYieldRateScaled()`: Get the current global yield rate.
    *   `getCalculatedDecayedBalance(uint265 echoId)`: Calculate the current decayed balance of an Echo *without* collapsing it.
    *   `getPotentialEquilibriumYield(address account)`: Calculate how much EQO yield an account could claim right now.
6.  **Owner Functions (Public/External, onlyOwner):**
    *   `setDecayRate(uint256 ratePerSecondScaled)`: Set the global decay rate.
    *   `setEquilibriumYieldRate(uint256 ratePerSecondScaled)`: Set the global yield rate.
    *   `setCreationFee(uint256 fee)`: Set the EQO creation fee.
    *   `setCollapseFee(uint256 fee)`: Set the EQO collapse fee.
    *   `setMergeFee(uint256 fee)`: Set the EQO merge fee.
    *   `pause()`: Pause contract interactions.
    *   `unpause()`: Unpause contract.
    *   `withdrawFees(address token, uint256 amount)`: Withdraw specific tokens (like collected EQO fees) from the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumEcho
 * @dev A smart contract managing a custom token (EQO) and state-dependent, decaying non-fungible assets (Echoes).
 *
 * Outline:
 * 1. Custom ERC20-like Token Implementation (EQO)
 * 2. Struct for Echoes representing decayed past state
 * 3. Mappings to track Echoes per user and globally
 * 4. Functions for ERC20-like operations (transfer, balance, etc.)
 * 5. Functions for Echo creation, management, and interaction (create, collapse, merge, boost stability, transfer ownership)
 * 6. Mechanism for generating EQO yield based on active Echoes (Equilibrium Generation)
 * 7. View functions for querying state, decay, and yield
 * 8. Owner-controlled configuration and management functions (rates, fees, pause, withdraw)
 * 9. Events for tracking key actions
 * 10. Error handling for invalid operations
 *
 * Function Summary:
 * - name(): Returns the token name. (View)
 * - symbol(): Returns the token symbol. (View)
 * - totalSupply(): Returns the total supply of EQO tokens. (View)
 * - balanceOf(address account): Returns the EQO balance of an address. (View)
 * - transfer(address recipient, uint256 amount): Transfers EQO tokens. (Public)
 * - allowance(address owner, address spender): Returns allowance amount. (View)
 * - approve(address spender, uint256 amount): Sets allowance for spender. (Public)
 * - transferFrom(address sender, address recipient, uint256 amount): Transfers EQO using allowance. (Public)
 * - createEcho(uint256 amount): Creates an Echo from sender's EQO balance, deducting a fee. (Public)
 * - getEchoCount(address account): Returns the number of Echoes owned by an account. (View)
 * - getEchoDetails(uint256 echoId): Returns details of a specific Echo. (View)
 * - listUserEchoIds(address account): Returns an array of Echo IDs owned by an account. (View, potentially gas-intensive)
 * - collapseEcho(uint256 echoId): Collapses an Echo, returning decayed value as EQO (minus fee). (Public)
 * - mergeEchoes(uint256[] calldata echoIds): Merges selected Echoes into a new one (minus fee). (Public)
 * - boostEchoStability(uint256 echoId, uint256 eqoAmount): Burns EQO to slow an Echo's decay. (Public)
 * - transferEchoOwnership(uint256 echoId, address newOwner): Transfers Echo ownership (under specific conditions). (Public)
 * - generateEquilibriumEQO(): Claims EQO yield generated by holding active Echoes. (Public)
 * - getCurrentDecayRateScaled(): Returns the current global decay rate. (View)
 * - getCurrentEquilibriumYieldRateScaled(): Returns the current global yield rate. (View)
 * - getCalculatedDecayedBalance(uint256 echoId): Calculates the current decayed balance of an Echo. (View)
 * - getPotentialEquilibriumYield(address account): Calculates the pending EQO yield for an account. (View)
 * - setDecayRate(uint256 ratePerSecondScaled): Sets the global decay rate (Owner only). (Public)
 * - setEquilibriumYieldRate(uint256 ratePerSecondScaled): Sets the global yield rate (Owner only). (Public)
 * - setCreationFee(uint256 fee): Sets the Echo creation fee (Owner only). (Public)
 * - setCollapseFee(uint256 fee): Sets the Echo collapse fee (Owner only). (Public)
 * - setMergeFee(uint256 fee): Sets the Echo merge fee (Owner only). (Public)
 * - pause(): Pauses key contract functions (Owner only). (Public)
 * - unpause(): Unpauses the contract (Owner only). (Public)
 * - withdrawFees(address token, uint256 amount): Withdraws collected fees or other tokens (Owner only). (Public)
 */
contract QuantumEcho {

    // --- Errors ---
    error NotOwner();
    error Paused();
    error NotPaused();
    error TransferAmountExceedsBalance();
    error TransferAmountExceedsAllowance();
    error ApproveZeroAllowance(); // Consider allowing 0 approval
    error CreateAmountTooSmall();
    error InsufficientEQOForFee(uint256 required, uint256 has);
    error EchoDoesNotExist(uint256 echoId);
    error NotEchoOwner(uint256 echoId);
    error EchoAlreadyCollapsedOrMerged(uint256 echoId);
    error CannotCollapseActiveEcho(uint256 echoId); // Example: Maybe require some decay
    error CannotMergeLessThanTwoEchoes();
    error AllEchoesMustBelongToSender();
    error EchoCannotBeMerged(uint256 echoId); // e.g., if it's already merged/collapsed
    error InvalidBoostAmount();
    error CannotTransferEchoYet(uint256 echoId); // Example condition
    error CannotWithdrawZero();
    error InvalidTokenAddress();

    // --- Events ---
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event EchoCreated(address indexed owner, uint256 indexed echoId, uint256 initialBalance, uint256 creationTimestamp);
    event EchoCollapsed(address indexed owner, uint256 indexed echoId, uint256 returnedEQO);
    event EchoMerged(address indexed owner, uint256[] indexed mergedEchoIds, uint256 indexed newEchoId);
    event EchoStabilityBoosted(uint256 indexed echoId, uint256 amountBurned, uint256 newStabilityMultiplier);
    event EchoOwnershipTransferred(uint256 indexed echoId, address indexed oldOwner, address indexed newOwner);
    event EquilibriumEQOGenerated(address indexed account, uint256 amount);
    event DecayRateChanged(uint256 newRatePerSecondScaled);
    event EquilibriumYieldRateChanged(uint256 newRatePerSecondScaled);
    event CreationFeeChanged(uint256 newFee);
    event CollapseFeeChanged(uint256 newFee);
    event MergeFeeChanged(uint256 newFee);
    event Paused(address account);
    event Unpaused(address account);
    event FeesWithdrawn(address indexed token, address indexed to, uint256 amount);

    // --- Structs ---
    enum EchoStatus { Active, Collapsed, Merged }

    struct Echo {
        address owner;
        uint256 initialBalance;         // Balance at creation time
        uint64 creationTimestamp;       // Timestamp of creation
        uint256 stabilityMultiplier;    // Factor affecting decay (1e18 = normal, >1e18 = slower decay)
        EchoStatus status;              // Current status of the Echo
    }

    // --- State Variables ---

    // ERC20-like State
    string private _name = "Quantum Echo Token";
    string private _symbol = "EQO";
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // Echo State
    uint256 private _echoCounter; // Starts from 1
    mapping(uint256 => Echo) private _echoes;
    mapping(address => uint256[] private) _userEchoIds; // Dynamic array of Echo IDs per user (Gas caution!)

    // Equilibrium State
    // Note: A simpler equilibrium mechanism based on user's active initial balance & time
    mapping(address => uint64) private _userLastEquilibriumClaim;
    // Need to track total active initial balance globally or per user effectively for yield calculation
    // Let's simplify: yield is based *only* on time holding *any* active echo, multiplied by number of echoes
    // A more complex model would factor in the initial balance of the echoes.
    // Let's use total initial balance across all active echoes per user for yield calculation.
    mapping(address => uint256) private _userTotalActiveInitialBalance;

    // Configuration State
    uint256 public _decayRatePerSecondScaled; // e.g., 1e18 / (30 days * 86400) for ~30 days decay
    uint256 public _equilibriumYieldRatePerSecondScaled; // e.g., 1e18 / (365 days * 86400) for annual yield
    uint256 public _creationFeeEQO;
    uint256 public _collapseFeeEQO;
    uint256 public _mergeFeeEQO;

    address public owner;
    bool public paused;

    // Constants for fixed-point math
    uint256 private constant SCALE = 1e18; // Represents 1.0

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    modifier whenNotPaused() {
        if (paused) {
            revert Paused();
        }
        _;
    }

    modifier whenPaused() {
        if (!paused) {
            revert NotPaused();
        }
        _;
    }

    // --- Constructor ---
    constructor(uint256 initialSupply) {
        owner = msg.sender;
        _totalSupply = initialSupply * SCALE; // Initial supply is in whole units
        _balances[msg.sender] = _totalSupply;

        // Set initial rates and fees (example values)
        _decayRatePerSecondScaled = SCALE / (30 * 86400); // Example: ~30 day half-life decay
        _equilibriumYieldRatePerSecondScaled = SCALE / (365 * 86400); // Example: ~100% APR (scaled)
        _creationFeeEQO = 1 * SCALE / 100; // Example: 0.01 EQO
        _collapseFeeEQO = 5 * SCALE / 100; // Example: 0.05 EQO
        _mergeFeeEQO = 10 * SCALE / 100; // Example: 0.1 EQO

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    // --- Internal Helper Functions ---

    // Helper to transfer EQO internally
    function _transfer(address sender, address recipient, uint256 amount) internal {
        if (sender == address(0)) revert TransferAmountExceedsBalance(); // Equivalent to mint from 0
        if (recipient == address(0)) revert TransferAmountExceedsBalance(); // Equivalent to burn to 0

        uint256 senderBalance = _balances[sender];
        if (senderBalance < amount) {
            revert TransferAmountExceedsBalance();
        }
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    // Helper to calculate the current decayed balance of an Echo
    function _calculateDecayedBalance(uint256 echoId) internal view returns (uint256 decayedBalance) {
        Echo storage echo = _echoes[echoId];
        if (echo.status != EchoStatus.Active) {
            return 0; // Collapsed or merged echoes have no value
        }

        uint256 timeElapsed = block.timestamp - echo.creationTimestamp;
        uint256 effectiveDecayRate = (_decayRatePerSecondScaled * SCALE) / echo.stabilityMultiplier; // Stability multiplier slows decay

        // Calculate decay factor: (1 - rate)^time ≈ 1 - rate * time for small rate*time
        // A more accurate fixed-point decay over time is complex.
        // Let's use a simplified linear decay based on time and rate, clamped at 0.
        // Decay = initialBalance * effectiveDecayRate * timeElapsed / SCALE
        uint256 maxPossibleDecay = echo.initialBalance; // Can't decay more than initial
        uint256 calculatedDecay = (echo.initialBalance * effectiveDecayRate / SCALE) * timeElapsed / SCALE;

        if (calculatedDecay >= maxPossibleDecay) {
            return 0; // Fully decayed
        } else {
            unchecked {
                 // Need to be careful with large numbers.
                 // Let's calculate the remaining factor instead of subtracting decay.
                 // Remaining factor ≈ (1 - effectiveDecayRate * timeElapsed / SCALE)
                 // Remaining factor = MAX(0, SCALE - (effectiveDecayRate * timeElapsed / SCALE))
                 uint256 remainingFactor;
                 uint256 decayTerm = (effectiveDecayRate * timeElapsed) / SCALE; // This needs careful scaling

                 // Simple approximation: Decay by rate per second
                 // Remaining balance = initialBalance * (1 - rate) ^ time
                 // Using scaled integers: balance = initial * (SCALE - rate)^time / SCALE^time
                 // This involves exponentiation, which is complex and expensive in Solidity.

                 // Let's use a simpler decay model based on total decay over time
                 // Total decay = initialBalance * decayRate * timeElapsed
                 // Clamp the timeElapsed to avoid overflow and ensure finite decay
                 uint256 maxTimeForFullDecay = (echo.initialBalance * SCALE) / effectiveDecayRate; // Time to fully decay
                 uint256 clampedTimeElapsed = timeElapsed > maxTimeForFullDecay ? maxTimeForFullDecay : timeElapsed;

                 uint256 totalDecayAmount = (echo.initialBalance * effectiveDecayRate / SCALE) * clampedTimeElapsed / SCALE;

                 return echo.initialBalance - totalDecayAmount;

                 // A potentially better approach involves tracking 'decay progress' or 'decay debt' but adds state complexity.
                 // Sticking with the simplified linear-over-time calculation for now.
            }
        }
    }

    // Helper to calculate potential equilibrium yield
    function _calculatePotentialEquilibriumYield(address account) internal view returns (uint256 yieldAmount) {
        uint64 lastClaim = _userLastEquilibriumClaim[account];
        uint256 totalActiveInitialBalance = _userTotalActiveInitialBalance[account];
        uint64 timeElapsed = block.timestamp - lastClaim;

        // Yield is proportional to user's total active initial balance * time elapsed * yield rate
        // yield = totalActiveInitialBalance * timeElapsed * equilibriumYieldRate / SCALE
        yieldAmount = (totalActiveInitialBalance * timeElapsed * _equilibriumYieldRatePerSecondScaled) / SCALE;
        return yieldAmount;
    }

    // --- ERC20-like Functions ---

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

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

    function allowance(address accountOwner, address spender) public view returns (uint256) {
        return _allowances[accountOwner][spender];
    }

    function approve(address spender, uint256 amount) public whenNotPaused returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public whenNotPaused returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        if (currentAllowance < amount) {
            revert TransferAmountExceedsAllowance();
        }
        _transfer(sender, recipient, amount);
        unchecked {
            _allowances[sender][msg.sender] = currentAllowance - amount;
        }
        return true;
    }

    // --- Echo Management Functions ---

    /**
     * @dev Creates a new Echo from a portion of the sender's balance.
     * The specified amount is locked in the Echo. A fee is burned.
     * @param amount The amount of EQO balance to capture in the Echo.
     */
    function createEcho(uint256 amount) public whenNotPaused {
        if (amount == 0) revert CreateAmountTooSmall();
        if (_balances[msg.sender] < amount + _creationFeeEQO) {
            revert InsufficientEQOForFee(_creationFeeEQO, _balances[msg.sender] - amount);
        }

        // Lock the amount + burn the fee
        _transfer(msg.sender, address(this), amount); // Transfer amount to contract (locked in echo)
        _transfer(msg.sender, address(0), _creationFeeEQO); // Burn fee

        _echoCounter++;
        uint256 newEchoId = _echoCounter;

        _echoes[newEchoId] = Echo({
            owner: msg.sender,
            initialBalance: amount,
            creationTimestamp: uint64(block.timestamp),
            stabilityMultiplier: SCALE, // Start with normal stability
            status: EchoStatus.Active
        });

        // Add echo ID to user's list (Gas caution!)
        _userEchoIds[msg.sender].push(newEchoId);

        // Update user's total active initial balance for yield calculation
        _userTotalActiveInitialBalance[msg.sender] += amount;

        emit EchoCreated(msg.sender, newEchoId, amount, block.timestamp);
    }

    /**
     * @dev Gets the number of Echoes owned by an account.
     * @param account The address to query.
     * @return The number of Echoes.
     */
    function getEchoCount(address account) public view returns (uint256) {
        return _userEchoIds[account].length;
    }

    /**
     * @dev Gets details of a specific Echo.
     * @param echoId The ID of the Echo.
     * @return Details of the Echo struct.
     */
    function getEchoDetails(uint256 echoId) public view returns (Echo memory) {
        if (_echoes[echoId].owner == address(0) && echoId != 0) { // Check if echoId exists (owner is non-zero unless ID is 0)
             revert EchoDoesNotExist(echoId);
        }
        return _echoes[echoId];
    }

    /**
     * @dev Lists all Echo IDs owned by an account.
     * WARNING: Can be very gas-intensive for users with many Echoes.
     * Consider fetching paginated lists off-chain using events or subgraphs instead for production.
     * @param account The address to query.
     * @return An array of Echo IDs.
     */
    function listUserEchoIds(address account) public view returns (uint256[] memory) {
        return _userEchoIds[account];
    }

    // --- Echo Interaction Functions ---

    /**
     * @dev Collapses an active Echo, returning its current decayed value to the owner.
     * A collapse fee is burned.
     * @param echoId The ID of the Echo to collapse.
     */
    function collapseEcho(uint256 echoId) public whenNotPaused {
        Echo storage echo = _echoes[echoId];

        if (echo.owner != msg.sender) revert NotEchoOwner(echoId);
        if (echo.status != EchoStatus.Active) revert EchoAlreadyCollapsedOrMerged(echoId);

        // Deduct collapse fee *before* returning value
        if (_balances[msg.sender] < _collapseFeeEQO) {
             revert InsufficientEQOForFee(_collapseFeeEQO, _balances[msg.sender]);
        }
        _transfer(msg.sender, address(0), _collapseFeeEQO); // Burn fee

        // Calculate return amount based on current decayed value
        uint256 returnedEQO = _calculateDecayedBalance(echoId);

        // Update Echo status and remove from user's active list (marking as collapsed)
        echo.status = EchoStatus.Collapsed;
        // Removing from dynamic array: find index, swap with last, pop. Gas intensive.
        // A better way is to just mark as inactive and filter off-chain or in view functions.
        // Let's update _userTotalActiveInitialBalance by subtracting this echo's initial balance
        _userTotalActiveInitialBalance[msg.sender] -= echo.initialBalance;

        // Transfer decayed value back to the owner
        if (returnedEQO > 0) {
            _transfer(address(this), msg.sender, returnedEQO);
        }

        emit EchoCollapsed(msg.sender, echoId, returnedEQO);
    }

    /**
     * @dev Merges multiple active Echoes belonging to the sender into a single new Echo.
     * The initial balance of the new Echo is the sum of the decayed values of the merged ones,
     * potentially with a bonus or penalty (not implemented here for simplicity, just sum).
     * A merge fee is burned. The merged Echoes are marked as Merged.
     * @param echoIds An array of Echo IDs to merge.
     */
    function mergeEchoes(uint256[] calldata echoIds) public whenNotPaused {
        if (echoIds.length < 2) revert CannotMergeLessThanTwoEchoes();

        uint256 totalDecayedValue = 0;
        uint256 totalInitialValueMerged = 0;

        // Validate and calculate total decayed value
        for (uint i = 0; i < echoIds.length; i++) {
            uint256 echoId = echoIds[i];
            Echo storage echo = _echoes[echoId];

            if (echo.owner != msg.sender) revert AllEchoesMustBelongToSender();
            if (echo.status != EchoStatus.Active) revert EchoCannotBeMerged(echoId);

            totalDecayedValue += _calculateDecayedBalance(echoId);
            totalInitialValueMerged += echo.initialBalance;
        }

        // Deduct merge fee
        if (_balances[msg.sender] < _mergeFeeEQO) {
            revert InsufficientEQOForFee(_mergeFeeEQO, _balances[msg.sender]);
        }
        _transfer(msg.sender, address(0), _mergeFeeEQO); // Burn fee

        // Create the new merged Echo
        _echoCounter++;
        uint265 newEchoId = _echoCounter;

        // New Echo's initial balance is the sum of the decayed values of merged ones
        _echoes[newEchoId] = Echo({
            owner: msg.sender,
            initialBalance: totalDecayedValue, // Initial balance is the 'value' at time of merge
            creationTimestamp: uint64(block.timestamp),
            stabilityMultiplier: SCALE, // Start with normal stability
            status: EchoStatus.Active
        });

        // Mark old Echoes as Merged and update total active initial balance
        for (uint i = 0; i < echoIds.length; i++) {
             _echoes[echoIds[i]].status = EchoStatus.Merged;
             // Since the merged Echoes are removed from 'active' state,
             // subtract their initial balance from the user's total active initial balance.
             _userTotalActiveInitialBalance[msg.sender] -= _echoes[echoIds[i]].initialBalance;
        }

        // Add the new merged echo's initial balance to the user's total active initial balance
        _userTotalActiveInitialBalance[msg.sender] += totalDecayedValue;


        // Add new echo ID to user's list (Gas caution!)
        _userEchoIds[msg.sender].push(newEchoId);


        emit EchoMerged(msg.sender, echoIds, newEchoId);
    }

    /**
     * @dev Burns EQO to boost the stability multiplier of a specific Echo, slowing its decay.
     * The amount burned determines the increase in stability.
     * @param echoId The ID of the Echo to boost.
     * @param eqoAmount The amount of EQO to burn for the boost.
     */
    function boostEchoStability(uint256 echoId, uint256 eqoAmount) public whenNotPaused {
        if (eqoAmount == 0) revert InvalidBoostAmount();

        Echo storage echo = _echoes[echoId];

        if (echo.owner != msg.sender) revert NotEchoOwner(echoId);
        if (echo.status != EchoStatus.Active) revert EchoAlreadyCollapsedOrMerged(echoId);

        // Burn the EQO
        _transfer(msg.sender, address(0), eqoAmount);

        // Increase stability multiplier. Example: 1 EQO burned adds 10% stability (1e17 scaled)
        // New multiplier = Current multiplier + (eqoAmount * BoostFactor / SCALE)
        uint256 stabilityIncrease = (eqoAmount * SCALE) / (10 * SCALE); // Example: Burning 1 EQO adds 10% stability (1e17 scaled)
        echo.stabilityMultiplier += stabilityIncrease;

        emit EchoStabilityBoosted(echoId, eqoAmount, echo.stabilityMultiplier);
    }

    /**
     * @dev Transfers ownership of a specific Echo to a new owner.
     * Requires the Echo to meet specific conditions (e.g., highly decayed) and potentially owner consent.
     * THIS IMPLEMENTATION ADDS A SIMPLE DECAY THRESHOLD CONDITION.
     * @param echoId The ID of the Echo to transfer.
     * @param newOwner The address of the new owner.
     */
    function transferEchoOwnership(uint265 echoId, address newOwner) public whenNotPaused {
        Echo storage echo = _echoes[echoId];

        if (echo.owner != msg.sender) revert NotEchoOwner(echoId);
        if (echo.status != EchoStatus.Active) revert EchoAlreadyCollapsedOrMerged(echoId);
        if (newOwner == address(0)) revert InvalidTokenAddress(); // Use InvalidTokenAddress for convenience

        // --- Custom Transfer Condition ---
        // Example: Only allow transfer if the Echo has decayed below 10% of its initial value
        uint256 currentDecayedBalance = _calculateDecayedBalance(echoId);
        if (currentDecayedBalance > echo.initialBalance / 10) { // If current > 10% of initial
             revert CannotTransferEchoYet(echoId); // Echo must decay more to be transferable
        }
        // --- End Custom Transfer Condition ---


        address oldOwner = echo.owner;
        echo.owner = newOwner;

        // Update user's total active initial balance for yield calculation
        _userTotalActiveInitialBalance[oldOwner] -= echo.initialBalance;
        _userTotalActiveInitialBalance[newOwner] += echo.initialBalance;

        // Update userEchoIds lists (Gas caution!)
        // This requires removing from old owner's array and adding to new owner's array.
        // Dynamic array manipulation is expensive. Consider using a mapping instead of array if this is used frequently.
        // For this example, we'll skip the explicit array manipulation here to save gas in the main function,
        // relying on off-chain filtering or a separate index if needed.
        // In a real DApp, you might maintain a secondary mapping like mapping(address => mapping(uint256 => bool)) public _userHasEchoId;
        // Or implement array removal carefully.

        emit EchoOwnershipTransferred(echoId, oldOwner, newOwner);
    }


    // --- Equilibrium Generation ---

    /**
     * @dev Allows a user to claim accrued EQO yield based on their active Echo holdings over time.
     * Yield is calculated based on their total active initial balance and the time since their last claim.
     */
    function generateEquilibriumEQO() public whenNotPaused {
        address account = msg.sender;
        uint256 yieldAmount = _calculatePotentialEquilibriumYield(account);

        if (yieldAmount == 0) {
            _userLastEquilibriumClaim[account] = uint64(block.timestamp); // Update timestamp even if 0 yield to prevent future large claims from old timestamp
             return; // No yield accrued
        }

        // Mint the yield amount and transfer it to the user
        // Note: This contract acts as a minting authority. Initial supply is fixed, but yield adds more.
        // This is a form of inflation tied to Echo holding.
        _totalSupply += yieldAmount;
        _balances[account] += yieldAmount;
        _userLastEquilibriumClaim[account] = uint64(block.timestamp); // Update last claim timestamp

        emit Transfer(address(0), account, yieldAmount); // Mint event using address(0)
        emit EquilibriumEQOGenerated(account, yieldAmount);
    }

    // --- Query/View Functions ---

    function getCurrentDecayRateScaled() public view returns (uint256) {
        return _decayRatePerSecondScaled;
    }

    function getCurrentEquilibriumYieldRateScaled() public view returns (uint256) {
        return _equilibriumYieldRatePerSecondScaled;
    }

    /**
     * @dev Calculates the current decayed balance of an Echo.
     * Does not modify the Echo's state.
     * @param echoId The ID of the Echo.
     * @return The calculated current decayed balance.
     */
    function getCalculatedDecayedBalance(uint256 echoId) public view returns (uint256) {
        if (_echoes[echoId].owner == address(0) && echoId != 0) {
             revert EchoDoesNotExist(echoId);
        }
        return _calculateDecayedBalance(echoId);
    }

    /**
     * @dev Calculates the potential EQO yield an account could claim right now.
     * Does not modify any state.
     * @param account The address to query.
     * @return The potential yield amount.
     */
    function getPotentialEquilibriumYield(address account) public view returns (uint256) {
        return _calculatePotentialEquilibriumYield(account);
    }


    // --- Owner Functions ---

    /**
     * @dev Sets the global decay rate for Echoes.
     * Rate is per second, scaled by 1e18. Higher rate means faster decay.
     * @param ratePerSecondScaled The new decay rate per second (scaled by 1e18).
     */
    function setDecayRate(uint256 ratePerSecondScaled) public onlyOwner {
        _decayRatePerSecondScaled = ratePerSecondScaled;
        emit DecayRateChanged(ratePerSecondScaled);
    }

    /**
     * @dev Sets the global yield rate for Equilibrium generation.
     * Rate is per second, scaled by 1e18. Higher rate means more yield.
     * @param ratePerSecondScaled The new yield rate per second (scaled by 1e18).
     */
    function setEquilibriumYieldRate(uint256 ratePerSecondScaled) public onlyOwner {
        _equilibriumYieldRatePerSecondScaled = ratePerSecondScaled;
        emit EquilibriumYieldRateChanged(ratePerSecondScaled);
    }

     /**
      * @dev Sets the EQO fee required to create an Echo.
      * @param fee The new creation fee in scaled EQO.
      */
    function setCreationFee(uint256 fee) public onlyOwner {
        _creationFeeEQO = fee;
        emit CreationFeeChanged(fee);
    }

     /**
      * @dev Sets the EQO fee required to collapse an Echo.
      * @param fee The new collapse fee in scaled EQO.
      */
    function setCollapseFee(uint256 fee) public onlyOwner {
        _collapseFeeEQO = fee;
        emit CollapseFeeChanged(fee);
    }

     /**
      * @dev Sets the EQO fee required to merge Echoes.
      * @param fee The new merge fee in scaled EQO.
      */
    function setMergeFee(uint256 fee) public onlyOwner {
        _mergeFeeEQO = fee;
        emit MergeFeeChanged(fee);
    }

    /**
     * @dev Pauses contract functions that involve state changes.
     * Prevents transfers, echo creation/interaction, and yield generation.
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses contract functions.
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Allows the owner to withdraw collected fees or other tokens sent to the contract.
     * @param token The address of the token to withdraw (use address(0) for native ETH, but this contract is not designed for ETH).
     * @param amount The amount to withdraw.
     */
    function withdrawFees(address token, uint256 amount) public onlyOwner {
        if (amount == 0) revert CannotWithdrawZero();
        if (token == address(0)) revert InvalidTokenAddress(); // This contract doesn't handle native ETH withdrawals
        if (token == address(this)) {
             // Withdrawing EQO (contract's own token)
            if (_balances[address(this)] < amount) {
                revert TransferAmountExceedsBalance();
            }
            _transfer(address(this), msg.sender, amount);
        } else {
             // Withdrawing other ERC20 tokens accidentally sent here
            // Need to use ERC20 standard interface for this
            // Assumes the token at 'token' implements a standard transfer function
            // This is a basic implementation. Consider adding checks for success.
            try IERC20(token).transfer(msg.sender, amount) returns (bool success) {
                if (!success) {
                    // Handle transfer failure (revert or log)
                    // Reverting is safer
                    revert TransferAmountExceedsBalance(); // Or a more specific error
                }
            } catch {
                // Handle potential call failure (e.g., not an ERC20 contract)
                revert InvalidTokenAddress(); // Or a more specific error
            }
        }
        emit FeesWithdrawn(token, msg.sender, amount);
    }

    // --- Fallback/Receive (Optional, add if you expect ETH) ---
    // receive() external payable {
    //     // React to receiving ETH
    // }
    // fallback() external payable {
    //     // React to receiving ETH or calls to non-existent functions
    // }
}

// Minimal interface for withdrawFees (if needed)
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    // function balanceOf(address account) external view returns (uint256);
    // function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    // function approve(address spender, uint256 amount) external returns (bool);
    // function allowance(address owner, address spender) external view returns (uint256);
}
```