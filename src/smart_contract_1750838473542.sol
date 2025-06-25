Okay, this is an ambitious request! Creating a truly novel concept that isn't inspired by *any* open-source project is challenging in a mature ecosystem like Solidity. However, we can combine and extend concepts in a creative way.

Let's create a token contract called `QuantumEntangledToken`. The core concept will be that tokens held by an address exist in one of two states: "Superposed" or "Decoherent". The state affects how the tokens behave, fees applied, and what special functions are available. State transitions will be triggered by actions, time, and potentially probabilistic events.

**Concept:**

**QuantumEntangledToken (QET)**: An ERC-20-like token where the state of the tokens held by an address (`Superposed` or `Decoherent`) determines their properties and available interactions.

*   **Superposed State**: The initial, special state. Tokens in this state might have lower transfer fees, be eligible for special functions ("Quantum Leap", "Superposition Split"), and potentially earn yield ("Quantum Yield"). This state is fragile.
*   **Decoherent State**: The default, less special state. Tokens enter this state through "observation" (like transfers, or decay over time) or failed entanglement attempts. Tokens in this state behave more like standard ERC-20 tokens, might have higher fees, and cannot access special "Quantum" functions.
*   **State Transitions**:
    *   Minting initially creates `Superposed` tokens for the recipient.
    *   Transferring `Superposed` tokens can cause the *sender's remaining* balance to collapse into the `Decoherent` state (partial collapse). The *recipient* always receives tokens in the `Decoherent` state.
    *   `Decoherent` tokens can decay into the `Decoherent` state further over time (Decoherence Decay).
    *   Users can `attemptEntanglement` to move their `Decoherent` tokens back into the `Superposed` state, but this costs a fee and is **probabilistic**. Success depends on a pseudo-random outcome.
    *   `Superposition Split` allows a user to intentionally convert some of their `Superposed` tokens into `Decoherent` tokens within their own balance.
*   **Quantum Yield**: `Superposed` tokens passively earn yield over time, claimable by the holder.
*   **Fees**: Different transfer fees apply based on the *sender's* state. Fees are collected by the contract.
*   **Supply Tracking**: The contract will track the total supply, as well as the supply currently in the `Superposed` and `Decoherent` states across all holders.
*   **Owner Controls**: The contract owner can set parameters like probabilities, fees, decay rates, and the yield rate.

**Outline and Function Summary:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumEntangledToken (QET)
 * @dev An ERC-20 inspired token with novel state mechanics: Superposed and Decoherent.
 *      The state of tokens held by an address affects fees, capabilities, and yield.
 *      State transitions are influenced by actions, time, and probability.
 *
 * Outline:
 * 1. State Variables & Constants: Token details, balances, allowances, total supply, state tracking, owner, parameters.
 * 2. Enums & Events: Define token states and signal key actions/transitions.
 * 3. Modifiers: Access control (onlyOwner), state checks (whenSuperposed, whenDecoherent).
 * 4. Constructor: Initialize token details and owner.
 * 5. Core ERC-20 Implementation (Modified): Basic token functions with state logic integrated into transfers.
 * 6. State Management Functions: Functions to check, attempt, and force state changes.
 * 7. Quantum Mechanics Functions: Special actions available based on state (yield, split, leap).
 * 8. Parameter Management: Owner functions to adjust contract parameters.
 * 9. Utility & View Functions: Get info about state, progress, supply distribution, etc.
 */

/**
 * Function Summary:
 *
 * ERC-20 Standard Interface (Modified Behavior):
 * 1.  name(): Returns the token name.
 * 2.  symbol(): Returns the token symbol.
 * 3.  decimals(): Returns the number of decimals.
 * 4.  totalSupply(): Returns the total supply of tokens.
 * 5.  balanceOf(address account): Returns the balance of an account.
 * 6.  transfer(address recipient, uint256 amount): Transfers tokens, applies fees based on sender state, and may trigger sender state collapse. Recipient receives Decoherent tokens.
 * 7.  approve(address spender, uint256 amount): Sets allowance for a spender.
 * 8.  transferFrom(address sender, address recipient, uint256 amount): Transfers tokens using allowance, applies fees based on sender state, and may trigger sender state collapse. Recipient receives Decoherent tokens.
 * 9.  allowance(address owner, address spender): Returns the allowance amount.
 *
 * State Management:
 * 10. observeState(address account): Returns the current state (Superposed or Decoherent) of an account's tokens. (View)
 * 11. attemptEntanglement(): Allows a user with Decoherent tokens to attempt to convert them back to Superposed state. Requires a fee and is probabilistic.
 * 12. applyQuantumPulse(address account, TokenState newState): Owner function to force a state change for an account.
 * 13. processDecay(address account): Internal/Helper function to check and apply decoherence decay based on time. Called before state-dependent actions.
 *
 * Quantum Mechanics (Special Functions):
 * 14. claimQuantumYield(): Allows a user with Superposed tokens to claim yield earned over time. Yield is minted as Decoherent tokens.
 * 15. superpositionSplit(uint256 amountToSplit): Allows a user to convert a specific amount of their Superposed tokens into Decoherent tokens within their own balance.
 * 16. quantumLeap(address recipient, uint256 amount): A special transfer function available for Superposed tokens, potentially with different state transition effects or fees than standard transfer. (Sender's state is stable, recipient gets Decoherent).
 *
 * Parameter Management (Owner Only):
 * 17. setEntanglementProbability(uint8 probability): Sets the success probability (0-100) for attemptEntanglement.
 * 18. setDecoherenceDecayRate(uint256 rate): Sets the rate at which Superposed tokens decay into Decoherent state (e.g., time duration for full decay).
 * 19. setTransferFees(uint256 superposedFee, uint256 decoherentFee): Sets transfer fees based on the sender's state. Fees are collected by the contract.
 * 20. setEntanglementAttemptFee(uint256 fee): Sets the fee required to attempt entanglement.
 * 21. setQuantumYieldRate(uint256 rate): Sets the rate at which Superposed tokens generate yield (e.g., tokens per second per token).
 * 22. pauseEntanglementAttempts(bool paused): Pauses or unpauses the attemptEntanglement function.
 *
 * Utility & View Functions:
 * 23. getDecoherenceProgress(address account): Calculates how much time has passed since the last state change relative to the decay rate. (View)
 * 24. getCumulativeYield(address account): Calculates the potential yield available for a Superposed account. (View)
 * 25. getTotalSuperposedSupply(): Returns the total supply of tokens currently in the Superposed state across all holders. (View)
 * 26. getTotalDecoherentSupply(): Returns the total supply of tokens currently in the Decoherent state across all holders. (View)
 * 27. getContractBalance(): Returns the total amount of QET held by the contract address (collected fees). (View)
 * 28. rescueFunds(address tokenAddress, uint256 amount): Owner function to recover accidentally sent tokens (non-QET).
 * 29. isEntanglementAttemptPaused(): Checks if entanglement attempts are paused. (View)
 * 30. owner(): Returns the contract owner address. (View)
 */
```

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Good practice, though 0.8+ has checks

// Implementing a basic ERC20 without inheriting directly to allow full override flexibility
// and avoid direct duplication of OZ's ERC20 *implementation* details, focusing on the state logic.

interface IQuantumEntangledToken is IERC20, IERC20Metadata {
    enum TokenState { Superposed, Decoherent }

    function observeState(address account) external view returns (TokenState);
    function attemptEntanglement() external payable;
    function applyQuantumPulse(address account, TokenState newState) external;
    function claimQuantumYield() external;
    function superpositionSplit(uint256 amountToSplit) external;
    function quantumLeap(address recipient, uint256 amount) external;

    function setEntanglementProbability(uint8 probability) external;
    function setDecoherenceDecayRate(uint256 rate) external;
    function setTransferFees(uint256 superposedFee, uint256 decoherentFee) external;
    function setEntanglementAttemptFee(uint256 fee) external;
    function setQuantumYieldRate(uint256 rate) external;
    function pauseEntanglementAttempts(bool paused) external;

    function getDecoherenceProgress(address account) external view returns (uint256 timeElapsed, uint256 decayRate);
    function getCumulativeYield(address account) external view returns (uint256 yieldAmount);
    function getTotalSuperposedSupply() external view returns (uint256);
    function getTotalDecoherentSupply() external view returns (uint256);
    function getContractBalance() external view returns (uint256);
    function rescueFunds(address tokenAddress, uint256 amount) external;
    function isEntanglementAttemptPaused() external view returns (bool);
}


contract QuantumEntangledToken is Context, Ownable, IQuantumEntangledToken {
    using SafeMath for uint256;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;

    enum TokenState { Superposed, Decoherent }
    mapping(address => TokenState) private _tokenStates;
    mapping(address => uint256) private _lastStateChangeTime;

    uint256 private _totalSuperposedSupply;
    uint256 private _totalDecoherentSupply;

    // Parameters (Owner configurable)
    uint8 public entanglementProbability = 50; // Percentage 0-100
    uint256 public decoherenceDecayRate = 365 days; // Time for full decay if untouched
    uint256 public superposedTransferFee = 1e17; // 0.1 token (example)
    uint256 public decoherentTransferFee = 5e17; // 0.5 token (example)
    uint256 public entanglementAttemptFee = 1 ether; // ETH fee (example)
    uint256 public quantumYieldRate = 1e15; // Yield per token per second (example: 1e15 = 0.001e18)

    bool public entanglementAttemptsPaused = false;

    // Constants
    uint256 private constant MAX_UINT256 = type(uint256).max;

    // Events
    event StateChanged(address indexed account, TokenState oldState, TokenState newState);
    event EntanglementAttempt(address indexed account, bool success, uint256 feePaid);
    event QuantumYieldClaimed(address indexed account, uint256 yieldAmount);
    event SuperpositionSplit(address indexed account, uint256 amountSuperposedRemoved, uint256 amountDecoherentAdded);
    event QuantumLeapExecuted(address indexed sender, address indexed recipient, uint256 amount);
    event TransferFeeApplied(address indexed sender, uint256 feeAmount, TokenState senderState);
    event ParametersUpdated(address indexed owner, string paramName, uint256 newValue);


    modifier whenSuperposed(address account) {
        require(_tokenStates[account] == TokenState.Superposed, "QET: Account must be Superposed");
        _;
    }

    modifier whenDecoherent(address account) {
        require(_tokenStates[account] == TokenState.Decoherent, "QET: Account must be Decoherent");
        _;
    }

    modifier onlyStateAffected(address account) {
        require(account != address(0), "QET: Zero address");
        // Ensure decay is processed before state-dependent logic
        _processDecay(account);
        _;
    }

    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 initialSupply_)
        Ownable(msg.sender)
    {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;

        // Mint initial supply to the deployer in Superposed state
        _mint(msg.sender, initialSupply_);
    }

    // --- ERC-20 Standard Functions (Modified) ---

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "QET: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance.sub(amount));
        _transfer(sender, recipient, amount);
        return true;
    }

    // --- Internal Transfer Logic ---

    function _transfer(address sender, address recipient, uint256 amount) internal onlyStateAffected(sender) {
        require(sender != address(0), "QET: transfer from the zero address");
        require(recipient != address(0), "QET: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "QET: transfer amount exceeds balance");

        TokenState senderState = _tokenStates[sender];
        uint256 fee = (senderState == TokenState.Superposed) ? superposedTransferFee : decoherentTransferFee;
        uint256 amountAfterFee = amount;

        if (fee > 0) {
            require(amountAfterFee > fee, "QET: amount too small to cover fee");
            amountAfterFee = amountAfterFee.sub(fee);

            // Collect fee by sending to the contract address
            _balances[address(this)] = _balances[address(this)].add(fee);
             emit Transfer(sender, address(this), fee);
             emit TransferFeeApplied(sender, fee, senderState);
        }


        // Update balances
        _balances[sender] = senderBalance.sub(amount); // Amount sent includes fee
        _balances[recipient] = _balances[recipient].add(amountAfterFee);

        // State transition logic for sender: Superposed sender might collapse
        // A simple rule: if sending >= 50% of balance, sender's state collapses.
        // This makes large transfers costly in terms of state.
        if (senderState == TokenState.Superposed && amount >= senderBalance.div(2)) {
            _changeState(sender, TokenState.Decoherent);
        } else {
             // Even if state doesn't collapse, interaction resets state timer
            _lastStateChangeTime[sender] = block.timestamp;
        }


        // State transition logic for recipient: Recipients *always* receive tokens in Decoherent state
        if (_tokenStates[recipient] == TokenState.Superposed) {
             // If recipient was Superposed, their current balance remains S, but new tokens are added as D.
             // We need to update total supply counts accurately. This requires tracking split balances,
             // which is complex. Simplification: Receiving tokens *always* collapses the recipient's
             // entire balance to Decoherent state to manage state tracking per address simply.
             // Alternative: Recipient receives as Decoherent, doesn't affect their existing state.
             // Let's go with the simpler approach: Recipient's state does NOT change on receiving.
             // The received tokens are *conceptually* Decoherent, and our total supply counters
             // need to reflect this.

             // Update total supply counters based on the *amount transferred* and the *sender's* state change,
             // and the *recipient's* state after receiving (which is always D for the received amount).
             // This requires careful calculation. Let's simplify total supply counters:
             // We'll track total tokens in S state and D state globally, based on the _tokenStates map.
             // If account A has state S, their *entire* balance is counted towards totalSuperposedSupply.
             // If account A has state D, their *entire* balance is counted towards totalDecoherentSupply.
             // This makes the state tracking per address much simpler and the counters consistent.
             // The implication: if a Superposed user receives tokens, their *entire* balance
             // (old Superposed + new Decoherent) is now considered Decoherent for the purpose
             // of state-based functions and the global counters. This aligns receiving with "observation causing collapse".
             // Let's implement this simpler rule: Receiving tokens collapses recipient state.
             _changeState(recipient, TokenState.Decoherent); // Receiving tokens collapses recipient state
        } else {
            // Recipient was already Decoherent, receiving doesn't change state, but resets timer?
            // No, receiving shouldn't reset the recipient's timer unless their state changes.
        }

        // Emit Transfer event for the net amount received by recipient
        emit Transfer(sender, recipient, amountAfterFee);
        // Emit event for the fee collected
        // (Transfer event for fee is emitted above)
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "QET: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);

        // Newly minted tokens are initially in the Superposed state
        _changeState(account, TokenState.Superposed);

        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal onlyStateAffected(account) {
         require(account != address(0), "QET: burn from the zero address");
         require(_balances[account] >= amount, "QET: burn amount exceeds balance");
         require(_tokenStates[account] == TokenState.Decoherent, "QET: Can only burn Decoherent tokens"); // Restriction

         TokenState oldState = _tokenStates[account]; // Should be Decoherent based on require
         uint256 oldBalance = _balances[account];

         _balances[account] = oldBalance.sub(amount);
         _totalSupply = _totalSupply.sub(amount);

         // Update total supply counters based on state
         if (oldState == TokenState.Superposed) {
             // This shouldn't happen due to the require check, but for completeness:
             _totalSuperposedSupply = _totalSuperposedSupply.sub(amount);
         } else { // Decoherent
             _totalDecoherentSupply = _totalDecoherentSupply.sub(amount);
         }

         emit Transfer(account, address(0), amount);

         // If balance becomes zero, state is irrelevant, but we can set to Decoherent default
         if (_balances[account] == 0) {
             _tokenStates[account] = TokenState.Decoherent; // Default state for zero balance
             _lastStateChangeTime[account] = block.timestamp; // Reset time
             // StateChanged event might be noisy for zero balance transitions, maybe skip
         } else {
            // Burning doesn't change the *remaining* balance state, but resets the state timer?
            // Let's not reset timer on burn, it reflects time *since* the last state change.
         }
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "QET: approve from the zero address");
        require(spender != address(0), "QET: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // --- State Management ---

    function observeState(address account) public view override returns (TokenState) {
        // This is a view function, it doesn't cause collapse.
        // The act of calling state-dependent functions or transfer causes collapse.
        // decay is processed implicitly by onlyStateAffected modifier where used.
        return _tokenStates[account];
    }

    function attemptEntanglement() public payable override whenDecoherent(_msgSender()) {
        require(!entanglementAttemptsPaused, "QET: Entanglement attempts are paused");
        require(msg.value >= entanglementAttemptFee, "QET: Insufficient ETH fee for entanglement attempt");
        require(_balances[_msgSender()] > 0, "QET: Account must have tokens to attempt entanglement");

        // Pay the fee
        // Transfer ETH fee to the contract owner
        (bool successFeeTransfer, ) = payable(owner()).call{value: entanglementAttemptFee}("");
        require(successFeeTransfer, "QET: ETH fee transfer failed");

        // Probabilistic success check
        // WARNING: On-chain randomness is pseudo-random and exploitable.
        // This is for demonstration/novelty, not for high-security scenarios.
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, _msgSender(), _balances[_msgSender()], _lastStateChangeTime[_msgSender()])));
        uint8 successRoll = uint8(randomNumber % 101); // Roll between 0 and 100

        bool success = successRoll < entanglementProbability;

        if (success) {
            _changeState(_msgSender(), TokenState.Superposed);
            emit EntanglementAttempt(_msgSender(), true, entanglementAttemptFee);
        } else {
            // Failed attempt still resets the state timer (represents interaction)
            _lastStateChangeTime[_msgSender()] = block.timestamp;
            emit EntanglementAttempt(_msgSender(), false, entanglementAttemptFee);
        }
    }

    function applyQuantumPulse(address account, TokenState newState) public override onlyOwner onlyStateAffected(account) {
        require(_balances[account] > 0, "QET: Cannot apply pulse to zero balance account");
        _changeState(account, newState);
        // Note: This bypasses decay logic if called after decay, but it's an admin override.
    }

    function _changeState(address account, TokenState newState) internal {
        if (_tokenStates[account] != newState) {
            TokenState oldState = _tokenStates[account];
            uint256 accountBalance = _balances[account];

            // Update total supply counters based on the balance changing state
            if (accountBalance > 0) { // Only update counters if the account has tokens
                if (oldState == TokenState.Superposed) {
                     _totalSuperposedSupply = _totalSuperposedSupply.sub(accountBalance);
                } else { // Decoherent or initial zero state
                    _totalDecoherentSupply = _totalDecoherentSupply.sub(accountBalance);
                }

                if (newState == TokenState.Superposed) {
                    _totalSuperposedSupply = _totalSuperposedSupply.add(accountBalance);
                } else { // Decoherent
                    _totalDecoherentSupply = _totalDecoherentSupply.add(accountBalance);
                }
            }

            _tokenStates[account] = newState;
            _lastStateChangeTime[account] = block.timestamp;
            emit StateChanged(account, oldState, newState);
        }
        // If state is the same, just reset the timer
        _lastStateChangeTime[account] = block.timestamp;
    }

    // Processes time-based decoherence decay
    function _processDecay(address account) internal {
        if (_tokenStates[account] == TokenState.Superposed && _balances[account] > 0) {
            uint256 timeElapsed = block.timestamp - _lastStateChangeTime[account];
            // If decay rate is 0, decay is disabled
            if (decoherenceDecayRate > 0 && timeElapsed >= decoherenceDecayRate) {
                _changeState(account, TokenState.Decoherent);
            }
        }
    }

    // --- Quantum Mechanics (Special Functions) ---

    function claimQuantumYield() public override whenSuperposed(_msgSender()) onlyStateAffected(_msgSender()) {
        uint256 account = _msgSender();
        uint256 yieldAmount = getCumulativeYield(account);

        require(yieldAmount > 0, "QET: No yield accumulated");

        // Calculate time since last claim/state change to reset timer accurately
        uint256 timeElapsed = block.timestamp - _lastStateChangeTime[account];

        // Reset state timer *before* minting yield to prevent earning yield on new tokens immediately
        // and to mark the point yield was claimed up to.
         _lastStateChangeTime[account] = block.timestamp; // Reset timer

        // Mint yield amount directly to the user. Yielded tokens are always Decoherent.
        _totalSupply = _totalSupply.add(yieldAmount);
        _balances[account] = _balances[account].add(yieldAmount);

        // Yield tokens are added as Decoherent to the account's balance.
        // Since the user's *state* is still Superposed, this requires careful handling of counters
        // if we want to track yield separately or if receiving tokens didn't collapse state.
        // Given our simpler rule (receiving collapses state or adding balance via mint updates totals based on *current* state),
        // if the user is Superposed and receives yield, their *entire* balance including yield is Superposed for counter purposes
        // until their state changes.
        // Alternative (more logical): Yielded tokens are added to the *Decoherent* supply count, even if the user is Superposed.
        // This means a Superposed user has a "logical" split balance: Superposed for old tokens, Decoherent for yield.
        // This makes counter management complex per address.
        // Let's stick to the simple rule: user state determines the state of their *entire* balance for counters.
        // So, since the user is Superposed when claiming, the minted yield adds to totalSuperposedSupply initially,
        // but the act of minting *could* be considered an interaction that triggers decay immediately after calculation?
        // No, that complicates things. Let's just mint and add to totals based on the user's state *at the time of minting*.
        // Simpler approach 2: Yield is minted as Decoherent tokens. The recipient's state (Superposed) doesn't change immediately from receiving.
        // This requires adding `yieldAmount` to `_totalDecoherentSupply`.
        _totalDecoherentSupply = _totalDecoherentSupply.add(yieldAmount);


        emit Transfer(address(0), account, yieldAmount); // Emit transfer from address(0) for minting
        emit QuantumYieldClaimed(account, yieldAmount);
    }

    function superpositionSplit(uint256 amountToSplit) public override whenSuperposed(_msgSender()) onlyStateAffected(_msgSender()) {
        uint256 account = _msgSender();
        uint256 currentBalance = _balances[account];

        require(amountToSplit > 0, "QET: Split amount must be positive");
        require(currentBalance >= amountToSplit, "QET: Split amount exceeds balance");

        // The account's state remains Superposed, but a portion of their balance
        // is conceptually moved to the Decoherent category *within their own holdings* for tracking purposes.
        // This doesn't change their _balances[account] value.
        // It only affects the global counters _totalSuperposedSupply and _totalDecoherentSupply.

        // Update total supply counters: Decrease Superposed supply, Increase Decoherent supply
        // by the amount split for this specific account.
        // Note: This assumes the user's *entire* balance is tracked by their state.
        // If a user splits, their balance `B` consists of `B - amountToSplit` Superposed and `amountToSplit` Decoherent.
        // We need to adjust the global counters accordingly.
        _totalSuperposedSupply = _totalSuperposedSupply.sub(amountToSplit);
        _totalDecoherentSupply = _totalDecoherentSupply.add(amountToSplit);

        // The account's state remains Superposed, but the lastStateChangeTime should be reset
        // as this is a significant interaction.
        _lastStateChangeTime[account] = block.timestamp;

        emit SuperpositionSplit(account, amountToSplit, amountToSplit);
        // Note: No Transfer event here as tokens don't leave the account, only their internal state logic changes for counters.
    }

    function quantumLeap(address recipient, uint256 amount) public override whenSuperposed(_msgSender()) onlyStateAffected(_msgSender()) {
        uint256 sender = _msgSender();
        require(recipient != address(0), "QET: transfer to the zero address");
        require(_balances[sender] >= amount, "QET: quantum leap amount exceeds balance");
        require(sender != recipient, "QET: Cannot leap to self"); // Prevent self-leaping

        // Unlike standard transfer, Quantum Leap does NOT necessarily collapse the sender's state,
        // unless a specific condition is met (e.g., transferring 100% of balance), but let's make it stable for the sender.
        // The state timer for the sender *is* reset due to the interaction.
        _lastStateChangeTime[sender] = block.timestamp; // Reset timer

        // Fees for Quantum Leap can be different. Let's use the Superposed fee for simplicity, or define a new one.
        uint256 fee = superposedTransferFee; // Using Superposed fee for Leap
        uint256 amountAfterFee = amount;

         if (fee > 0) {
            require(amountAfterFee > fee, "QET: amount too small to cover fee");
            amountAfterFee = amountAfterFee.sub(fee);
            // Collect fee by sending to the contract address
            _balances[address(this)] = _balances[address(this)].add(fee);
            emit Transfer(sender, address(this), fee);
            emit TransferFeeApplied(sender, fee, _tokenStates[sender]); // Should be Superposed
        }

        // Update balances
        _balances[sender] = _balances[sender].sub(amount); // Amount sent includes fee
        _balances[recipient] = _balances[recipient].add(amountAfterFee);

        // Recipient *always* receives tokens in Decoherent state.
        // This will trigger a state change for the recipient if they were Superposed,
        // collapsing their entire balance to Decoherent state (based on our simplified rule).
        _changeState(recipient, TokenState.Decoherent); // Recipient state collapses or stays Decoherent

        // Emit Transfer event for the net amount received
        emit Transfer(sender, recipient, amountAfterFee);
        emit QuantumLeapExecuted(sender, recipient, amount);
    }


    // --- Parameter Management (Owner Only) ---

    function setEntanglementProbability(uint8 probability) public override onlyOwner {
        require(probability <= 100, "QET: Probability must be 0-100");
        entanglementProbability = probability;
        emit ParametersUpdated(msg.sender, "entanglementProbability", probability);
    }

    function setDecoherenceDecayRate(uint256 rate) public override onlyOwner {
        decoherenceDecayRate = rate; // Can set to 0 to disable decay
        emit ParametersUpdated(msg.sender, "decoherenceDecayRate", rate);
    }

    function setTransferFees(uint256 superposedFee, uint256 decoherentFee) public override onlyOwner {
        superposedTransferFee = superposedFee;
        decoherentTransferFee = decoherentFee;
        emit ParametersUpdated(msg.sender, "superposedTransferFee", superposedFee);
        emit ParametersUpdated(msg.sender, "decoherentTransferFee", decoherentFee);
    }

     function setEntanglementAttemptFee(uint256 fee) public override onlyOwner {
        entanglementAttemptFee = fee;
        emit ParametersUpdated(msg.sender, "entanglementAttemptFee", fee);
    }

    function setQuantumYieldRate(uint256 rate) public override onlyOwner {
        quantumYieldRate = rate; // Yield per token per second
        emit ParametersUpdated(msg.sender, "quantumYieldRate", rate);
    }

    function pauseEntanglementAttempts(bool paused) public override onlyOwner {
        entanglementAttemptsPaused = paused;
        emit ParametersUpdated(msg.sender, "entanglementAttemptsPaused", paused ? 1 : 0); // Using 1/0 for bool
    }


    // --- Utility & View Functions ---

    function getDecoherenceProgress(address account) public view override returns (uint256 timeElapsed, uint256 decayRate) {
         // Decay only applies to Superposed tokens with > 0 balance
         if (_tokenStates[account] == TokenState.Superposed && _balances[account] > 0 && decoherenceDecayRate > 0) {
            timeElapsed = block.timestamp - _lastStateChangeTime[account];
            decayRate = decoherenceDecayRate;
            // If timeElapsed >= decayRate, decay has occurred. The _processDecay modifier
            // would handle the state change when an action is attempted. This view just shows potential.
         } else {
             timeElapsed = 0; // No progress if not Superposed or decay is disabled/zero balance
             decayRate = decoherenceDecayRate; // Still return the rate parameter
         }
    }

    function getCumulativeYield(address account) public view override returns (uint256 yieldAmount) {
        // Calculate yield only for Superposed accounts with > 0 balance
        if (_tokenStates[account] == TokenState.Superposed && _balances[account] > 0 && quantumYieldRate > 0) {
            uint256 timeInState = block.timestamp - _lastStateChangeTime[account];
            // Yield = balance * rate * time
            // Using SafeMath, check for potential overflow before multiplication, although yield rate should be small
            // Simple calculation (can be refined for precision if needed)
            // This assumes yield accumulates linearly.
             yieldAmount = _balances[account].mul(quantumYieldRate).mul(timeInState) / (1e18); // Scale down rate if needed based on its definition
             // Let's adjust quantumYieldRate definition: it's yield amount per token per second scaled by 1e18 for precision
             // E.g., 1 token per year per token -> rate = 1e18 / (365*24*60*60)
             // yield = balance * rate * timeElapsed / 1e18
             yieldAmount = _balances[account].mul(quantumYieldRate).div(1e18).mul(timeInState);


        } else {
            yieldAmount = 0;
        }
    }

    function getTotalSuperposedSupply() public view override returns (uint256) {
        return _totalSuperposedSupply;
    }

    function getTotalDecoherentSupply() public view override returns (uint256) {
        return _totalDecoherentSupply;
    }

     function getContractBalance() public view override returns (uint256) {
         return _balances[address(this)];
     }

     function rescueFunds(address tokenAddress, uint256 amount) public override onlyOwner {
         require(tokenAddress != address(this), "QET: Cannot rescue contract's own tokens via this function");
         IERC20 rescueToken = IERC20(tokenAddress);
         require(rescueToken.balanceOf(address(this)) >= amount, "QET: Contract does not have enough tokens to rescue");
         rescueToken.transfer(owner(), amount);
     }

     function isEntanglementAttemptPaused() public view override returns (bool) {
         return entanglementAttemptsPaused;
     }

     // Expose owner from Ownable
    function owner() public view override returns (address) {
        return Ownable.owner();
    }
}
```

**Explanation of Novel/Advanced Concepts:**

1.  **State-Dependent Token Behavior:** The core novelty is that token behavior (fees, functions) depends on the holder's state (`Superposed` vs `Decoherent`), not just the standard ERC-20 properties.
2.  **Probabilistic State Transition (`attemptEntanglement`):** Introducing controlled on-chain pseudo-randomness for a core game-like mechanic (regaining `Superposed` state) is a creative use, acknowledging the limitations of on-chain randomness by not using it for high-value security decisions.
3.  **Time-Based Decay (`decoherenceDecayRate`, `_processDecay`):** `Superposed` state isn't permanent. Inactivity (time passing without interaction) can cause decay to `Decoherent`, encouraging participation. The `_processDecay` modifier ensures decay is checked before key actions.
4.  **State-Influenced Fees:** Different transfer fees based on the sender's state add an economic incentive to maintain `Superposed` state. Fees collected by the contract could be used later (e.g., for yield, burning).
5.  **State Collapse Mechanics:** Specific actions like large transfers or receiving tokens (`_transfer`, `quantumLeap`) are defined as "observations" that can collapse a `Superposed` state to `Decoherent`.
6.  **Yield Based on State (`claimQuantumYield`, `getCumulativeYield`):** Only `Superposed` tokens earn yield, creating a benefit tied directly to maintaining that state. The yield is minted, increasing total supply, but added as `Decoherent` tokens to the user's balance, adding another layer of state interaction.
7.  **Specialized Functions (`superpositionSplit`, `quantumLeap`):** These functions offer unique interactions only available to `Superposed` holders, providing utility beyond standard transfers. `superpositionSplit` allows controlled conversion of state within a balance, affecting global counters. `quantumLeap` is an alternative transfer with different state transition rules.
8.  **Global State Tracking (`_totalSuperposedSupply`, `_totalDecoherentSupply`):** Explicitly tracking the distribution of tokens across states adds a unique view metric for the token's ecosystem health or "quantum energy". Keeping these counters accurate across all state-changing functions (`_mint`, `_burn`, `_transfer`, `_changeState`, `superpositionSplit`, `claimQuantumYield`) is a non-trivial implementation detail. (Note: The implementation presented uses a simplified model where an address's state determines the state category for their *entire* balance, which simplifies counter updates significantly).

This contract goes significantly beyond standard ERC-20 by introducing complex state logic, time-based mechanics, and probabilistic elements tied to core token functionalities, aiming for a creative and novel design. It avoids directly copying common patterns found in staking, farming, or simple utility tokens by making the *state* of the token the central, dynamic element.