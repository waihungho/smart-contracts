Okay, let's create a smart contract that embodies some advanced concepts like dynamic state transitions influenced by external data (simulated via Oracle), state-dependent functionality, a custom ERC-20 token with conditional transfer restrictions, and a mechanism for state-dependent delegated actions using signature verification.

We'll call it `QuantumFluctuatingReserve`. Its core idea is a reserve of ETH and a custom token (`QFRToken`) whose operational parameters and even token behavior change based on a periodically "observed" external factor (like market volatility, represented by price feed changes) which shifts the contract between different "Quantum States".

**Outline & Function Summary:**

1.  **Outline:**
    *   Contract Definition (`QuantumFluctuatingReserve`) inheriting `Ownable`.
    *   Internal ERC-20 Token Definition (`QFRToken`).
    *   State Management (Enum for `QuantumState`, State Variables).
    *   Oracle Integration (Chainlink `AggregatorV3Interface`).
    *   State Transition Logic (Based on Oracle data, time, internal metrics).
    *   Reserve Functionality (Deposit/Withdraw ETH, Mint/Burn QFRToken - state-dependent).
    *   QFRToken Functionality (Transfer, Approve, etc. - potentially state-restricted via Reserve).
    *   Conditional Delegated Action (Executing signed actions based on contract state).
    *   Owner/Admin Functions (Configuration, emergency recovery).
    *   Events.
    *   Error Handling.

2.  **Function Summary (Minimum 20+ Functions):**
    *   **Core Reserve & Token Interaction:**
        *   `constructor`: Initializes contract, deploys QFRToken, sets owner, oracle.
        *   `depositEth`: Allows users to deposit ETH into the reserve.
        *   `withdrawEth`: Allows users to withdraw ETH (may have state-dependent fees/restrictions).
        *   `mintQFRTokens`: Allows users to mint QFRTokens by depositing ETH (state-dependent rate).
        *   `burnQFRTokens`: Allows users to burn QFRTokens to withdraw ETH (state-dependent rate).
        *   `transferQFRTokens`: Initiates a QFRToken transfer (routes through internal logic, can be state-restricted).
        *   `approveQFRTokens`: Standard ERC-20 approve for QFRToken.
        *   `transferFromQFRTokens`: Standard ERC-20 transferFrom for QFRToken (routes through internal logic, can be state-restricted).
        *   `balanceOfQFRTokens`: Get balance of QFRToken for an address.
        *   `allowanceQFRTokens`: Get allowance for QFRToken.
        *   `getTotalSupplyQFRTokens`: Get total supply of QFRToken.
        *   `getQFRTokenAddress`: Get address of the deployed QFRToken.
    *   **State Management & Observation:**
        *   `triggerObservation`: External function to trigger the state observation and potential transition (subject to cooldown/permissions).
        *   `getCurrentState`: Returns the current `QuantumState`.
        *   `getOraclePrice`: Fetches and returns the latest price data from the Oracle.
        *   `getLastObservationTimestamp`: Returns the timestamp of the last state observation.
        *   `peekNextState`: Calculates and returns the *potential* next state without actually transitioning.
    *   **Configuration & Information:**
        *   `setOracleFeed`: Owner-only to set the Oracle feed address.
        *   `setObservationCooldown`: Owner-only to set the cooldown for `triggerObservation`.
        *   `setStateTransitionThresholds`: Owner-only to configure parameters for state transitions.
        *   `getStateTransitionThresholds`: Get current state transition configuration.
        *   `getMintRate`: Returns the current ETH to QFRToken minting rate multiplier (state-dependent).
        *   `getBurnRate`: Returns the current QFRToken to ETH burning rate multiplier (state-dependent).
        *   `getStateBasedFee`: Returns the current fee percentage applied to withdrawals/transfers (state-dependent).
    *   **Advanced & Utility:**
        *   `executeConditionalAction`: Allows execution of a pre-signed action (like withdraw, transfer) *only if* the contract is in a specific `requiredState` at the time of execution. Uses signature verification and nonces.
        *   `getDomainSeparator`: Helper for EIP-712 signing (used internally or by clients).
        *   `getConditionalActionHash`: Helper to compute the hash of a `ConditionalAction` struct for signing.
        *   `getUserActionNonce`: Get the current nonce for a user's conditional actions.
        *   `emergencyWithdrawEth`: Owner-only to withdraw ETH in emergencies.
        *   `emergencyWithdrawTokens`: Owner-only to withdraw *any* specified ERC20 token from the contract.
    *   **Inherited (`Ownable`):**
        *   `owner`: Get the owner address.
        *   `transferOwnership`: Transfer ownership.
        *   `renounceOwnership`: Renounce ownership.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Required imports (using OpenZeppelin for common patterns and Chainlink for oracle)
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // While 0.8+ has built-in overflow checks, SafeMath is explicit and sometimes preferred for clarity or specific operations.
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title QuantumFluctuatingReserve
 * @dev A smart contract representing a reserve of ETH and a custom token (QFRToken)
 *      whose operational state and token behavior dynamically change based on
 *      external observations (simulated via Oracle price fluctuations).
 *      Features state-dependent fees, mint/burn rates, transfer restrictions,
 *      and state-conditional delegated execution.
 */
contract QuantumFluctuatingReserve is Ownable {
    using SafeMath for uint256;
    using ECDSA for bytes32;

    /**
     * @dev Represents the possible "Quantum States" of the reserve.
     *      Each state affects how certain functions behave.
     *      Stable: Normal operation, low fees, standard rates.
     *      Volatile: Higher fees, potentially restricted transfers, adjusted rates.
     *      Entangled: Transfers paused, specific interactions enabled/disabled.
     *      Superposition: Highly unpredictable, potentially locked states, unique rates.
     */
    enum QuantumState {
        Stable,       // Normal, low fees, standard rates
        Volatile,     // Higher fees, potential transfer costs/delays
        Entangled,    // Transfers potentially locked, specific functions disabled/enabled
        Superposition // Unpredictable rates, unique fees, high volatility
    }

    // --- State Variables ---
    QuantumState public currentState;
    uint48 public lastObservationTimestamp; // uint48 is enough for timestamps until ~2262

    IERC20 public immutable qfrToken;
    AggregatorV3Interface public priceFeed; // Chainlink ETH/USD or similar

    uint64 public observationCooldown = 1 days; // Min time between state observations

    // State transition thresholds (example parameters - can be extended)
    struct StateThresholds {
        int256 volatileThresholdPriceChange; // e.g., 500e8 (5% change in 18 decimals)
        int256 entangledThresholdPriceChange; // e.g., 1000e8 (10% change)
        uint256 superpositionDeterminantRange; // Range size for Superposition determinant
    }
    StateThresholds public stateTransitionThresholds;
    int256 private lastObservedPrice; // Price at the time of the last observation

    // Mapping to track nonces for state-conditional actions per user
    mapping(address => uint256) private userActionNonces;

    // --- Events ---
    event StateTransition(QuantumState indexed oldState, QuantumState indexed newState, int256 priceChangeObserved);
    event EthDeposited(address indexed user, uint256 amount);
    event EthWithdrawn(address indexed user, uint256 amount, uint256 fee);
    event TokensMinted(address indexed user, uint256 ethAmount, uint256 tokenAmount);
    event TokensBurned(address indexed user, uint256 tokenAmount, uint256 ethAmount);
    event QFRTransfer(address indexed from, address indexed to, uint256 amount, uint256 fee); // Custom event for transfers potentially with fees
    event ConditionalActionExecuted(address indexed user, bytes32 indexed actionHash, QuantumState requiredState);
    event OracleFeedUpdated(address indexed oldFeed, address indexed newFeed);
    event ObservationCooldownUpdated(uint256 oldCooldown, uint256 newCooldown);
    event StateTransitionThresholdsUpdated(StateThresholds thresholds);


    // --- Internal QFRToken Definition ---
    // Defining ERC20 internally to tie its behavior directly to the reserve state
    contract QFRToken is IERC20 {
        string private _name;
        string private _symbol;
        uint256 private _totalSupply;
        mapping(address => uint256) private _balances;
        mapping(address => mapping(address => uint256)) private _allowances;

        // Allow only the owner (QuantumFluctuatingReserve contract) to call mint/burn
        address public owner;

        constructor(string memory name_, string memory symbol_) {
            _name = name_;
            _symbol = symbol_;
            owner = msg.sender; // The deploying QuantumFluctuatingReserve contract
        }

        modifier onlyOwner() {
            require(msg.sender == owner, "QFRT: Caller is not owner");
            _;
        }

        // Basic ERC20 functions routed through the owner contract
        function name() public view override returns (string memory) { return _name; }
        function symbol() public view override returns (string memory) { return _symbol; }
        function decimals() public pure override returns (uint8) { return 18; } // Standard ERC20 decimals
        function totalSupply() public view override returns (uint256) { return _totalSupply; }
        function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
        function allowance(address holder, address spender) public view override returns (uint256) { return _allowances[holder][spender]; }

        // Transfer logic will be primarily handled by the owner contract's state logic
        function transfer(address to, uint256 amount) public override returns (bool) {
             // Transfers should ideally go through the main Reserve contract's functions
             // to enforce state-dependent logic. This function might be restricted or
             // simply route the call back, or apply a default state-agnostic transfer.
             // For this example, let's allow basic transfer but strongly recommend
             // using the Reserve's methods for state-aware transfers.
             _transfer(msg.sender, to, amount); // Basic transfer
             return true;
        }

        // Approval logic is standard ERC20
        function approve(address spender, uint256 amount) public override returns (bool) {
            _approve(msg.sender, spender, amount);
            return true;
        }

        // TransferFrom logic will be primarily handled by the owner contract's state logic
        function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
            // Similar to transfer, recommend using Reserve's methods.
            uint256 currentAllowance = _allowances[from][msg.sender];
            require(currentAllowance >= amount, "QFRT: Insufficient allowance");
            _transfer(from, to, amount);
            _approve(from, msg.sender, currentAllowance - amount); // Decrease allowance
            return true;
        }

        // Internal functions called by the owner contract
        function _transfer(address from, address to, uint256 amount) internal {
            require(from != address(0), "QFRT: Transfer from zero address");
            require(to != address(0), "QFRT: Transfer to zero address");
            require(_balances[from] >= amount, "QFRT: Insufficient balance");

            _balances[from] -= amount;
            _balances[to] += amount;

            emit Transfer(from, to, amount); // Standard ERC20 event
        }

        function _mint(address account, uint256 amount) internal onlyOwner {
            require(account != address(0), "QFRT: Mint to zero address");

            _totalSupply += amount;
            _balances[account] += amount;

            emit Transfer(address(0), account, amount); // Standard ERC20 event for minting
        }

        function _burn(address account, uint256 amount) internal onlyOwner {
            require(account != address(0), "QFRT: Burn from zero address");
            require(_balances[account] >= amount, "QFRT: Burn amount exceeds balance");

            _balances[account] -= amount;
            _totalSupply -= amount;

            emit Transfer(account, address(0), amount); // Standard ERC20 event for burning
        }

        function _approve(address holder, address spender, uint256 amount) internal {
            require(holder != address(0), "QFRT: Approve from zero address");
            require(spender != address(0), "QFRT: Approve to zero address");

            _allowances[holder][spender] = amount;

            emit Approval(holder, spender, amount); // Standard ERC20 event
        }
    }


    // --- Constructor ---
    constructor(string memory tokenName_, string memory tokenSymbol_, address priceFeedAddress) Ownable(msg.sender) {
        // Deploy the internal QFRToken contract
        qfrToken = new QFRToken(tokenName_, tokenSymbol_);
        // Set the owner of the QFRToken to THIS contract address
        QFRToken(address(qfrToken)).transferOwnership(address(this));

        // Set initial state and oracle feed
        currentState = QuantumState.Stable;
        priceFeed = AggregatorV3Interface(priceFeedAddress);

        // Get initial price observation
        (, lastObservedPrice, , , ) = priceFeed.latestRoundData();
        lastObservationTimestamp = uint48(block.timestamp);

        // Set initial default thresholds
        stateTransitionThresholds = StateThresholds({
            volatileThresholdPriceChange: 50000000, // e.g., 0.5% change in 8 decimals price feed
            entangledThresholdPriceChange: 100000000, // e.g., 1% change in 8 decimals
            superpositionDeterminantRange: 50 // Determinant 0-49 -> Superposition (out of 1000)
        });
    }

    // --- Receive ETH ---
    receive() external payable {
        emit EthDeposited(msg.sender, msg.value);
    }

    // --- Reserve & Token Interaction Functions ---

    /**
     * @dev Allows users to deposit ETH into the reserve.
     *      This is a basic deposit function. More complex versions could
     *      offer state-dependent bonuses or restrictions.
     */
    function depositEth() external payable {
        require(msg.value > 0, "QFR: Deposit amount must be > 0");
        emit EthDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Allows users to withdraw ETH from the reserve.
     *      Withdrawals may be subject to state-dependent fees or temporary restrictions.
     * @param amount The amount of ETH to withdraw.
     */
    function withdrawEth(uint256 amount) external {
        require(amount > 0, "QFR: Withdrawal amount must be > 0");
        require(address(this).balance >= amount, "QFR: Insufficient reserve balance");

        uint256 fee = amount.mul(getStateBasedFee()).div(10000); // Fee is in 1/100ths of a percent (e.g., 100 = 1%)
        uint256 amountToSend = amount.sub(fee);

        require(address(this).balance >= amountToSend, "QFR: Insufficient reserve balance after fee");

        (bool success, ) = msg.sender.call{value: amountToSend}("");
        require(success, "QFR: ETH withdrawal failed");

        emit EthWithdrawn(msg.sender, amount, fee);
    }

    /**
     * @dev Mints QFRTokens for the user based on deposited ETH and the current state's mint rate.
     * @param ethAmount The amount of ETH to deposit for minting.
     */
    function mintQFRTokens(uint256 ethAmount) external payable {
        require(msg.value == ethAmount, "QFR: Sent ETH must match ethAmount");
        require(ethAmount > 0, "QFR: ETH amount must be > 0");

        // Get the current state-dependent mint rate (tokens per ETH)
        uint256 mintRate = getMintRate();
        uint256 tokensToMint = ethAmount.mul(mintRate);

        require(tokensToMint > 0, "QFR: Minted tokens must be > 0");

        // Mint tokens using the internal QFRToken contract
        QFRToken(address(qfrToken))._mint(msg.sender, tokensToMint);

        emit TokensMinted(msg.sender, ethAmount, tokensToMint);
    }

    /**
     * @dev Burns QFRTokens from the user and sends back ETH based on the current state's burn rate.
     * @param tokenAmount The amount of QFRTokens to burn.
     */
    function burnQFRTokens(uint256 tokenAmount) external {
        require(tokenAmount > 0, "QFR: Token amount must be > 0");
        require(qfrToken.balanceOf(msg.sender) >= tokenAmount, "QFR: Insufficient QFRToken balance");

        // Get the current state-dependent burn rate (ETH per token, adjusted for decimals)
        uint256 burnRate = getBurnRate();
        uint256 ethToReturn = tokenAmount.mul(burnRate).div(1e18); // Adjust for QFRToken decimals

        require(address(this).balance >= ethToReturn, "QFR: Insufficient reserve ETH for burning");

        // Burn tokens using the internal QFRToken contract
        QFRToken(address(qfrToken))._burn(msg.sender, tokenAmount);

        // Send ETH back to the user
        (bool success, ) = msg.sender.call{value: ethToReturn}("");
        require(success, "QFR: ETH return failed during burn");

        emit TokensBurned(msg.sender, tokenAmount, ethToReturn);
    }

    /**
     * @dev Transfers QFRTokens, applying state-dependent rules (like fees or restrictions).
     *      This is the recommended way to transfer QFRTokens for state awareness.
     * @param to The recipient address.
     * @param amount The amount of tokens to transfer.
     */
    function transferQFRTokens(address to, uint256 amount) external returns (bool) {
         uint256 fee = amount.mul(getStateBasedFee()).div(10000); // State-dependent fee on transfer
         uint256 amountToSend = amount.sub(fee);

         // Check state-specific transfer restrictions
         _checkTransferRestrictions(msg.sender, to, amount);

         QFRToken(address(qfrToken))._transfer(msg.sender, to, amountToSend);

         // Transfer fee to contract or owner if needed (for simplicity, fee is burnt/removed from amount)
         // If you want to send the fee to the owner or contract, add transfer logic here.
         // e.g., if (fee > 0) QFRToken(address(qfrToken))._transfer(msg.sender, address(this), fee);

         emit QFRTransfer(msg.sender, to, amount, fee); // Custom event showing total amount and fee
         return true;
    }

     /**
     * @dev Transfers QFRTokens using allowance, applying state-dependent rules.
     *      Recommended for state-aware transferFrom functionality.
     * @param from The address to transfer tokens from.
     * @param to The recipient address.
     * @param amount The amount of tokens to transfer.
     */
    function transferFromQFRTokens(address from, address to, uint256 amount) external returns (bool) {
        uint256 fee = amount.mul(getStateBasedFee()).div(10000);
        uint256 amountToSend = amount.sub(fee);

        // Standard ERC20 allowance check and decrease
        uint256 currentAllowance = qfrToken.allowance(from, msg.sender);
        require(currentAllowance >= amount, "QFR: Insufficient allowance");

        // Check state-specific transfer restrictions
        _checkTransferRestrictions(from, to, amount);

        // Transfer requires interaction with the internal QFRToken contract's _transfer
        QFRToken(address(qfrToken))._approve(from, msg.sender, currentAllowance - amount); // Decrease allowance first
        QFRToken(address(qfrToken))._transfer(from, to, amountToSend);

        emit QFRTransfer(from, to, amount, fee);
        return true;
    }

    /**
     * @dev Standard ERC20 approve function for QFRToken.
     * @param spender The address to approve.
     * @param amount The allowance amount.
     */
    function approveQFRTokens(address spender, uint256 amount) external returns (bool) {
        QFRToken(address(qfrToken)).approve(spender, amount); // Routes to the standard ERC20 approve
        return true;
    }

    /**
     * @dev Gets the QFRToken balance of an address.
     * @param account The address to check.
     */
    function balanceOfQFRTokens(address account) external view returns (uint256) {
        return qfrToken.balanceOf(account);
    }

    /**
     * @dev Gets the QFRToken allowance granted by holder to spender.
     * @param holder The address holding the tokens.
     * @param spender The address allowed to spend.
     */
    function allowanceQFRTokens(address holder, address spender) external view returns (uint256) {
         return qfrToken.allowance(holder, spender);
    }

    /**
     * @dev Gets the total supply of QFRTokens.
     */
    function getTotalSupplyQFRTokens() external view returns (uint256) {
        return qfrToken.totalSupply();
    }

     /**
     * @dev Gets the address of the deployed QFRToken contract.
     */
    function getQFRTokenAddress() external view returns (address) {
        return address(qfrToken);
    }

    /**
     * @dev Gets the contract's current ETH balance.
     */
    function getEthBalance() external view returns (uint256) {
        return address(this).balance;
    }


    // --- State Management & Observation Functions ---

    /**
     * @dev Triggers an observation of external conditions (Oracle) and may transition state.
     *      Subject to a cooldown period. Can be called by anyone, but state only changes
     *      if cooldown elapsed and conditions met.
     */
    function triggerObservation() external {
        require(block.timestamp >= lastObservationTimestamp + observationCooldown, "QFR: Observation cooldown not elapsed");

        (int256 currentPrice, , , , ) = priceFeed.latestRoundData();
        require(currentPrice > 0, "QFR: Invalid oracle price"); // Ensure valid price

        int256 priceChange = currentPrice.sub(lastObservedPrice);

        // Determine next state based on price change, current state, and other factors
        QuantumState nextState = _determineNextState(priceChange);

        // Only transition if the state actually changes
        if (nextState != currentState) {
            QuantumState oldState = currentState;
            currentState = nextState;
            emit StateTransition(oldState, currentState, priceChange);
        }

        lastObservedPrice = currentPrice;
        lastObservationTimestamp = uint48(block.timestamp);
    }

    /**
     * @dev Returns the current QuantumState of the reserve.
     */
    function getCurrentState() external view returns (QuantumState) {
        return currentState;
    }

    /**
     * @dev Fetches the latest price from the Oracle feed.
     *      Returns price and timestamp.
     */
    function getOraclePrice() external view returns (int256 price, uint256 timestamp) {
         (, price, , timestamp, ) = priceFeed.latestRoundData();
    }


    /**
     * @dev Calculates the potential next state based on current conditions *without* changing the state.
     *      Useful for users to anticipate state changes.
     */
    function peekNextState() external view returns (QuantumState potentialNextState) {
         (int256 currentPrice, , , , ) = priceFeed.latestRoundData();
         require(currentPrice > 0, "QFR: Invalid oracle price");
         int256 priceChange = currentPrice.sub(lastObservedPrice);
         potentialNextState = _determineNextState(priceChange);
    }

    /**
     * @dev Internal function to determine the next state based on various factors.
     *      This is where the "quantum" like non-linearity and state-dependent logic resides.
     *      Uses price change as a primary driver, but could incorporate time, volume, etc.
     * @param priceChange The difference between current and last observed oracle price.
     * @return The determined next QuantumState.
     */
    function _determineNextState(int256 priceChange) internal view returns (QuantumState) {
        // Example logic:
        // Significant positive price change -> Volatile
        // Significant negative price change -> Entangled
        // Moderate change -> Stable
        // Deterministic pseudorandom element combined with state/price -> Superposition

        // Calculate a determinant based on various factors for pseudo-randomness
        // Use block hash, timestamp, price change, current state, and contract balance
        uint256 determinant = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.difficulty, // block.difficulty is deprecated, use block.prevrandao in PoS. Using it here for demonstration.
                    priceChange,
                    uint8(currentState),
                    address(this).balance,
                    qfrToken.totalSupply(),
                    lastObservedPrice // Include previous state variable
                )
            )
        ) % 1000; // Determinant range 0-999

        // State transition logic
        if (determinant < stateTransitionThresholds.superpositionDeterminantRange) { // e.g., 0-49 -> Superposition
            return QuantumState.Superposition;
        } else if (priceChange >= stateTransitionThresholds.entangledThresholdPriceChange) { // Significant positive price jump
            return QuantumState.Volatile; // Or Entangled, depending on desired logic
        } else if (priceChange <= -stateTransitionThresholds.entangledThresholdPriceChange) { // Significant negative price drop
             return QuantumState.Entangled; // Or Volatile
        } else if (priceChange >= stateTransitionThresholds.volatileThresholdPriceChange || priceChange <= -stateTransitionThresholds.volatileThresholdPriceChange) { // Moderate price change
            return QuantumState.Volatile; // Or Entangled based on sign
        } else {
             // Default or if price change is within stable range
            if (currentState == QuantumState.Stable) {
                return QuantumState.Stable; // Stay Stable if already stable and minimal change
            } else {
                // Gradual return to Stable from other states? Add logic here.
                // For simplicity, if not a major event, maybe transition back to Stable or stay.
                // Let's say stay in current state unless a condition explicitly moves it elsewhere.
                 return currentState; // Stay in current non-stable state if change is minimal
            }
        }
         // This is a simplified example. A real system might use more sophisticated
         // statistical analysis, volatility metrics, or multiple oracle feeds.
    }

     /**
     * @dev Internal function to check if transfers are allowed in the current state.
     *      Reverts if transfers are restricted.
     * @param from The sender address.
     * @param to The recipient address.
     * @param amount The transfer amount.
     */
    function _checkTransferRestrictions(address from, address to, uint256 amount) internal view {
        // Example restrictions:
        if (currentState == QuantumState.Entangled) {
            require(false, "QFR: Transfers restricted in Entangled state");
        }
        if (currentState == QuantumState.Superposition) {
             // Maybe allow only transfers to/from specific addresses, or small amounts
             require(amount <= 100 ether, "QFR: Large transfers restricted in Superposition"); // Example restriction
        }
        // Add more state-specific checks as needed
    }


    // --- State-Dependent Parameter Functions ---

    /**
     * @dev Returns the current mint rate of QFRToken per ETH, based on the QuantumState.
     *      e.g., 1 ETH = X QFRT. Rate is a multiplier.
     *      Return value * 1e18 tokens per ETH.
     */
    function getMintRate() public view returns (uint256) {
        // Example rates (can be fetched from a complex calculation or state variable)
        // Rates are relative to ETH value, assuming Oracle is ETH/USD.
        // Simplified: Assume a base rate and apply multipliers
        uint256 baseRate = 1000e18; // 1 ETH = 1000 QFRT in stable (example)

        if (currentState == QuantumState.Stable) {
            return baseRate;
        } else if (currentState == QuantumState.Volatile) {
            return baseRate.mul(8).div(10); // 80% of base rate (more expensive to mint)
        } else if (currentState == QuantumState.Entangled) {
             return baseRate.mul(12).div(10); // 120% of base rate (cheaper to mint)
        } else if (currentState == QuantumState.Superposition) {
             // Highly unpredictable rate - maybe depends on determinant or other factors
             // Using a simple pseudo-random factor for demonstration
             uint256 pseudoRandomFactor = uint256(keccak256(abi.encodePacked(block.timestamp, block.number))) % 50 + 75; // 75-124
             return baseRate.mul(pseudoRandomFactor).div(100); // 75% to 124% of base rate
        }
        return baseRate; // Fallback
    }

    /**
     * @dev Returns the current burn rate of ETH per QFRToken, based on the QuantumState.
     *      e.g., Y QFRT = 1 ETH. Rate is ETH per token.
     *      Return value is ETH amount (with 1e18 decimals) per 1 QFRT.
     */
    function getBurnRate() public view returns (uint256) {
        // Example rates (should be inverse of mint rate for economic stability, ideally)
        uint256 baseEthPerToken = 1e18.div(1000); // 1 QFRT = 0.001 ETH in stable

        if (currentState == QuantumState.Stable) {
            return baseEthPerToken;
        } else if (currentState == QuantumState.Volatile) {
            return baseEthPerToken.mul(12).div(10); // 120% of base rate (more ETH per burn)
        } else if (currentState == QuantumState.Entangled) {
             return baseEthPerToken.mul(8).div(10); // 80% of base rate (less ETH per burn)
        } else if (currentState == QuantumState.Superposition) {
             // Highly unpredictable rate, inverse of mint rate logic
             uint256 pseudoRandomFactor = uint256(keccak256(abi.encodePacked(block.timestamp, block.number))) % 50 + 75;
             // Simple inverse-like calculation: if mint rate multiplier is M, burn rate multiplier is ~1/M.
             // If pseudoRandomFactor for mint was X/100, for burn it's 100/X.
             // Example using a simple scaled inverse: 100 / (150 - pseudoRandomFactor) * baseRate
             uint256 scaledFactor = 150 - (uint256(keccak256(abi.encodePacked(block.timestamp, block.number, "burn"))) % 50 + 75); // 25-74 (inverse tendency)
             return baseEthPerToken.mul(scaledFactor).div(100); // 25% to 74% effect
        }
        return baseEthPerToken; // Fallback
    }

    /**
     * @dev Returns the current fee percentage (in 1/100ths of a percent, e.g., 100 = 1%)
     *      for withdrawals and transfers, based on the QuantumState.
     */
    function getStateBasedFee() public view returns (uint256) {
        if (currentState == QuantumState.Stable) {
            return 10; // 0.1% fee
        } else if (currentState == QuantumState.Volatile) {
            return 100; // 1% fee
        } else if (currentState == QuantumState.Entangled) {
             return 50; // 0.5% fee
        } else if (currentState == QuantumState.Superposition) {
             return 500; // 5% fee (high uncertainty fee)
        }
        return 0; // Fallback (should not happen)
    }


    // --- State-Conditional Delegated Action ---

    /**
     * @dev Structure for a state-conditional action signed by a user.
     *      Allows a relayer to execute an action on behalf of the user,
     *      but ONLY if the contract is in the specified requiredState.
     */
    struct ConditionalAction {
        address user;       // The address authorizing the action
        bytes32 actionType; // Identifier for the type of action (e.g., keccak256("WithdrawEth"), keccak256("TransferQFRT"))
        uint256 amount;     // Amount related to the action
        address target;     // Target address (e.g., recipient for transfer, recipient for withdrawal)
        uint256 nonce;      // User's nonce for preventing replay attacks
        uint256 deadline;   // Timestamp after which the action is invalid
        QuantumState requiredState; // The state required for execution
    }

    /**
     * @dev Executes a state-conditional action signed by `action.user`.
     *      Requires:
     *      1. Signature is valid for the action payload.
     *      2. Action nonce matches user's current nonce.
     *      3. Deadline has not passed.
     *      4. Contract's `currentState` matches `action.requiredState`.
     * @param action The ConditionalAction struct containing action details.
     * @param signature The signature produced by `action.user`.
     */
    function executeConditionalAction(ConditionalAction memory action, bytes memory signature) external {
        // 1. Verify Signature
        bytes32 actionHash = getConditionalActionHash(action);
        address signer = actionHash.toEthSignedMessageHash().recover(signature);
        require(signer == action.user, "QFR: Invalid signature");

        // 2. Verify Nonce
        require(action.nonce == userActionNonces[action.user], "QFR: Invalid nonce");

        // 3. Verify Deadline
        require(block.timestamp <= action.deadline, "QFR: Action expired");

        // 4. Verify Required State
        require(currentState == action.requiredState, "QFR: Contract not in required state");

        // Execute the action based on actionType
        if (action.actionType == keccak256("WithdrawEth")) {
            // Requires target to be the withdrawal recipient
            _executeWithdrawEth(action.user, action.amount, action.target);
        } else if (action.actionType == keccak256("TransferQFRT")) {
            // Requires target to be the transfer recipient
            _executeTransferQFRTokens(action.user, action.target, action.amount);
        }
        // Add more action types as needed (e.g., "MintQFRT", "BurnQFRT")
        // Ensure amount and target make sense for the action type.

        // Increment the user's nonce for future actions
        userActionNonces[action.user]++;

        emit ConditionalActionExecuted(action.user, actionHash, action.requiredState);
    }

    /**
     * @dev Internal helper to execute ETH withdrawal logic for a conditional action.
     *      Assumes all checks (signature, nonce, state, deadline) have passed.
     */
    function _executeWithdrawEth(address user, uint256 amount, address recipient) internal {
         require(amount > 0, "QFR: Conditional withdrawal amount must be > 0");
         require(address(this).balance >= amount, "QFR: Insufficient reserve balance for conditional withdrawal");
         require(recipient != address(0), "QFR: Conditional withdrawal recipient cannot be zero address");

         uint256 fee = amount.mul(getStateBasedFee()).div(10000);
         uint256 amountToSend = amount.sub(fee);

         require(address(this).balance >= amountToSend, "QFR: Insufficient reserve balance for conditional withdrawal after fee");

        (bool success, ) = recipient.call{value: amountToSend}("");
        require(success, "QFR: Conditional ETH withdrawal failed");

         emit EthWithdrawn(user, amount, fee); // Emit withdrawal event with original amount
    }

    /**
     * @dev Internal helper to execute QFRT transfer logic for a conditional action.
     *      Assumes all checks (signature, nonce, state, deadline) have passed.
     */
    function _executeTransferQFRTokens(address from, address to, uint256 amount) internal {
        require(amount > 0, "QFR: Conditional transfer amount must be > 0");
        require(from != address(0), "QFR: Conditional transfer from zero address");
        require(to != address(0), "QFR: Conditional transfer to zero address");
        require(qfrToken.balanceOf(from) >= amount, "QFR: Insufficient QFRToken balance for conditional transfer");

        uint256 fee = amount.mul(getStateBasedFee()).div(10000);
        uint256 amountToSend = amount.sub(fee);

        // Check state-specific transfer restrictions again (redundant if state was checked, but safe)
        _checkTransferRestrictions(from, to, amount);

        // For transferFrom scenarios using conditional actions, allowance might be needed.
        // If actionType implies transferFrom, add allowance check here or in _checkTransferRestrictions.
        // For simplicity, this assumes a basic 'transfer' or a pre-approved allowance scenario for transferFrom.
        // A more robust system would require the actionType struct to specify if it's transfer or transferFrom.
        // Assuming this executes 'transfer' from 'from' to 'to' using 'from's balance:
        QFRToken(address(qfrToken))._transfer(from, to, amountToSend);

         emit QFRTransfer(from, to, amount, fee); // Emit transfer event with original amount and fee
    }


    /**
     * @dev Calculates the EIP-712 domain separator for this contract.
     *      Used in signing conditional actions off-chain.
     */
    function getDomainSeparator() public view returns (bytes32) {
        // EIP-712 Domain Separator components:
        // typeHash = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
        // nameHash = keccak256("QuantumFluctuatingReserve")
        // versionHash = keccak256("1")
        // chainId = block.chainid
        // verifyingContract = address(this)
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256("QuantumFluctuatingReserve"),
                keccak256("1"), // Version of the signing structure
                block.chainid,
                address(this)
            )
        );
    }

    /**
     * @dev Calculates the EIP-712 type hash for the ConditionalAction struct.
     *      Used in signing conditional actions off-chain.
     */
    bytes32 public constant CONDITIONAL_ACTION_TYPEHASH = keccak256("ConditionalAction(address user,bytes32 actionType,uint256 amount,address target,uint256 nonce,uint256 deadline,uint8 requiredState)");

    /**
     * @dev Calculates the hash of a ConditionalAction struct conforming to EIP-712.
     *      This is the hash that the user needs to sign off-chain.
     * @param action The ConditionalAction struct.
     * @return The hash of the struct.
     */
    function getConditionalActionHash(ConditionalAction memory action) public view returns (bytes32) {
        return keccak256(
            abi.encode(
                CONDITIONAL_ACTION_TYPEHASH,
                action.user,
                action.actionType,
                action.amount,
                action.target,
                action.nonce,
                action.deadline,
                uint8(action.requiredState)
            )
        );
    }

     /**
     * @dev Returns the current nonce for a user's conditional actions.
     *      Users must use the correct nonce for their signed actions.
     * @param user The user's address.
     */
    function getUserActionNonce(address user) external view returns (uint256) {
        return userActionNonces[user];
    }

     /**
     * @dev Internal helper to increase the user's nonce.
     *      Called after a successful conditional action execution.
     */
    function _increaseUserActionNonce(address user) internal {
        userActionNonces[user]++;
    }


    // --- Owner/Admin Functions ---

    /**
     * @dev Owner-only function to set the address of the Chainlink Price Feed.
     * @param priceFeedAddress The address of the new AggregatorV3Interface contract.
     */
    function setOracleFeed(address priceFeedAddress) external onlyOwner {
        require(priceFeedAddress != address(0), "QFR: Invalid price feed address");
        AggregatorV3Interface newFeed = AggregatorV3Interface(priceFeedAddress);
        // Basic check if it looks like a price feed (calls a view function)
        try newFeed.latestRoundData() returns (int256, int256, uint256, uint256, uint256) {
             address oldFeed = address(priceFeed);
             priceFeed = newFeed;
             // Update last observed price immediately on feed change? Or wait for next observation?
             // Let's update to the latest from the new feed.
             (, lastObservedPrice, , , ) = priceFeed.latestRoundData();
             lastObservationTimestamp = uint48(block.timestamp); // Reset observation time

             emit OracleFeedUpdated(oldFeed, priceFeedAddress);
        } catch {
            revert("QFR: Invalid price feed interface");
        }
    }

    /**
     * @dev Owner-only function to set the cooldown period between state observations.
     * @param cooldown The new cooldown in seconds.
     */
    function setObservationCooldown(uint64 cooldown) external onlyOwner {
        require(cooldown > 0, "QFR: Cooldown must be > 0");
        uint64 oldCooldown = observationCooldown;
        observationCooldown = cooldown;
        emit ObservationCooldownUpdated(oldCooldown, cooldown);
    }

    /**
     * @dev Owner-only function to set the thresholds used in state transitions.
     * @param thresholds The new StateThresholds struct.
     */
    function setStateTransitionThresholds(StateThresholds memory thresholds) external onlyOwner {
        // Add validation for threshold values if needed
        stateTransitionThresholds = thresholds;
        emit StateTransitionThresholdsUpdated(thresholds);
    }

    /**
     * @dev Owner-only emergency function to withdraw ETH from the contract.
     *      Should be used sparingly in case of contract issues.
     * @param amount The amount of ETH to withdraw.
     */
    function emergencyWithdrawEth(uint256 amount) external onlyOwner {
        require(amount > 0, "QFR: Emergency withdrawal amount must be > 0");
        require(address(this).balance >= amount, "QFR: Insufficient balance for emergency withdrawal");
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "QFR: Emergency ETH withdrawal failed");
        emit EthWithdrawn(address(this), amount, 0); // Indicate withdrawal from contract
    }

    /**
     * @dev Owner-only emergency function to withdraw any ERC20 token stuck in the contract.
     *      Useful if random tokens are accidentally sent. Excludes the QFRToken itself.
     * @param tokenAddress The address of the ERC20 token to withdraw.
     * @param amount The amount of tokens to withdraw.
     */
    function emergencyWithdrawTokens(address tokenAddress, uint256 amount) external onlyOwner {
        require(tokenAddress != address(qfrToken), "QFR: Cannot emergency withdraw QFRToken");
        IERC20 emergencyToken = IERC20(tokenAddress);
        require(emergencyToken.balanceOf(address(this)) >= amount, "QFR: Insufficient token balance for emergency withdrawal");
        require(emergencyToken.transfer(msg.sender, amount), "QFR: Emergency token withdrawal failed");
        // Consider adding a specific event for emergency token withdrawals
    }

    // --- View Functions for Parameters ---

    /**
     * @dev Returns the current state transition thresholds.
     */
    function getStateTransitionThresholds() external view returns (StateThresholds memory) {
        return stateTransitionThresholds;
    }
}
```

**Explanation of Advanced/Creative Concepts:**

1.  **Dynamic Quantum States:** The contract exists in one of several defined `QuantumState`s (`Stable`, `Volatile`, `Entangled`, `Superposition`). This state is not static but changes based on "observations".
2.  **Oracle-Influenced State Transitions:** The `triggerObservation` function uses a Chainlink Price Feed (simulating external market data) to influence state changes. The price *change* relative to the last observation is a primary factor, but the logic includes other elements (like timestamp, balance, total supply) mixed with a hash for a pseudo-random element, making the exact state transition less perfectly predictable based *solely* on price. This mimics the probabilistic nature sometimes associated with quantum systems upon observation.
3.  **State-Dependent Functionality:** Many core functions (`withdrawEth`, `mintQFRTokens`, `burnQFRTokens`, `transferQFRTokens`) modify their behavior (fees, rates, transfer restrictions) based on the `currentState`. This makes the reserve's economy and token utility dynamic.
4.  **Internal, State-Aware ERC-20:** The `QFRToken` contract is defined *inside* the `QuantumFluctuatingReserve` contract and deployed by the constructor. The `QuantumFluctuatingReserve` contract is set as the `owner` of `QFRToken`, allowing it to call internal mint/burn/transfer methods. The `transferQFRTokens` and `transferFromQFRTokens` functions in the main contract wrap the standard ERC-20 logic, adding state-dependent checks (`_checkTransferRestrictions`) and fees *before* executing the actual token transfer via the internal `QFRToken` contract's methods.
5.  **State-Conditional Delegated Actions (Advanced Meta-Transaction Concept):** The `executeConditionalAction` function introduces a sophisticated pattern. A user can sign a message (`ConditionalAction` struct) off-chain authorizing a specific action (like withdrawing ETH or transferring tokens) *only if* the contract is in a particular `requiredState` at the moment the transaction is included on-chain. This allows users or relayers to prepare transactions in advance, but their validity is conditional on the contract's dynamic state. It uses EIP-712 hashing and ECDSA signature recovery for security and nonces to prevent replay attacks.

This contract goes beyond simple token or deposit/withdrawal functionalities by introducing a dynamic, externally influenced state machine that governs the behavior of the reserve and its associated token, plus a novel conditional execution pattern. It requires careful consideration of the state transition logic and the economic implications of the state-dependent parameters.