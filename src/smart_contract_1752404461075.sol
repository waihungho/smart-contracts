Okay, here is a Solidity smart contract concept called "Quantum Vault". It's designed around the idea of a vault that holds ERC20 and ERC721 tokens, but unlocks and changes its withdrawal rules based on a multi-stage state machine triggered by time and the deposit/presence of specific "catalyst" tokens/NFTs. It also includes conditional penalties and whitelisting.

It uses OpenZeppelin libraries for standard patterns (Ownable, Pausable, SafeERC20, ERC721) but the core state machine logic and withdrawal conditions are custom to this concept.

**Outline and Function Summary**

**Contract Name:** `QuantumVault`

**Concept:** A multi-state vault for ERC20 and ERC721 tokens. The vault progresses through distinct states (`InitialLocked`, `TemporalPhase`, `CatalyticPhase`, `EntropicPhase`, `FinalUnlocked`). Each state modifies withdrawal conditions and available functions. State transitions are triggered by meeting conditions related to time, the presence of specific "required catalyst" tokens/NFTs deposited into the vault, or by withdrawing required catalysts prematurely. Optional "modifier" tokens/NFTs can unlock additional privileges within certain states.

**States:**
1.  `InitialLocked`: Vault is locked. Only deposits and admin functions are allowed.
2.  `TemporalPhase`: Reached after a specific time passes since deployment (or admin setting). Basic conditional withdrawals may become possible, potentially requiring modifier tokens.
3.  `CatalyticPhase`: Reached from `TemporalPhase` if all predefined "required catalyst" tokens and NFTs have been deposited into the vault. Unlocks more flexible withdrawal options.
4.  `EntropicPhase`: A penalty state. Can be triggered by withdrawing a "required catalyst" while in `CatalyticPhase`. Withdrawal penalties (a percentage burn/fee) apply in this state.
5.  `FinalUnlocked`: Reached from `CatalyticPhase` after a further time period, or forcibly by the owner from `EntropicPhase`. All restrictions and penalties are lifted.

**Function Categories:**

1.  **Core Vault Operations:**
    *   `depositERC20`: Deposit ERC20 tokens into the vault.
    *   `depositERC721`: Deposit ERC721 tokens into the vault.
    *   `withdrawERC20`: Withdraw ERC20 tokens, subject to state-specific conditions and whitelisting.
    *   `withdrawERC721`: Withdraw ERC721 tokens, subject to state-specific conditions and whitelisting.
    *   `emergencyWithdraw`: Owner-only function to withdraw *any* asset in emergencies (bypasses state).

2.  **State Management:**
    *   `attemptStateTransition`: Public function that checks if conditions for the next state are met and transitions the vault. Can be called by anyone to push the state forward.
    *   `forceFinalUnlockFromEntropic`: Owner-only function to move from `EntropicPhase` directly to `FinalUnlocked`.

3.  **Configuration (Owner Only):**
    *   `setTemporalUnlockTimestamp`: Set the timestamp for the `TemporalPhase` transition.
    *   `setFinalUnlockTimestampAfterCatalytic`: Set the timestamp for the `FinalUnlocked` transition *after* `CatalyticPhase` is reached.
    *   `addRequiredCatalystERC20`: Add a specific ERC20 token and amount required to reach `CatalyticPhase`.
    *   `removeRequiredCatalystERC20`: Remove an ERC20 from the required list.
    *   `addRequiredCatalystERC721`: Add a specific ERC721 token contract and ID required to reach `CatalyticPhase`.
    *   `removeRequiredCatalystERC721`: Remove an ERC721 from the required list.
    *   `addOptionalModifierERC20`: Add an ERC20 token that grants special withdrawal privileges if held *by the withdrawing user*.
    *   `removeOptionalModifierERC20`: Remove an optional modifier ERC20.
    *   `addOptionalModifierERC721`: Add an ERC721 token that grants special withdrawal privileges if held *by the withdrawing user*.
    *   `removeOptionalModifierERC721`: Remove an optional modifier ERC721.
    *   `setEntropicPenaltyRate`: Set the penalty percentage applied to withdrawals in `EntropicPhase`.
    *   `addWithdrawalWhitelist`: Whitelist an address and token (ERC20 or ERC721) allowing withdrawals in states where general withdrawal is restricted.
    *   `removeWithdrawalWhitelist`: Remove an address/token from the whitelist.

4.  **Utility & View Functions:**
    *   `getCurrentState`: Get the current state of the vault.
    *   `getContractERC20Balance`: Get the vault's balance of a specific ERC20 token.
    *   `getContractERC721TokenCount`: Get the number of a specific ERC721 token held by the vault (for a given ID).
    *   `holdsERC721`: Check if the vault holds a specific ERC721 token by contract and ID.
    *   `getRequiredCatalystsERC20`: Get the list of required ERC20 catalysts and their amounts.
    *   `getRequiredCatalystsERC721`: Get the list of required ERC721 catalysts (contract and ID).
    *   `getOptionalModifiersERC20`: Get the list of optional modifier ERC20s.
    *   `getOptionalModifiersERC721`: Get the list of optional modifier ERC721s.
    *   `getTemporalUnlockTimestamp`: Get the timestamp for `TemporalPhase`.
    *   `getFinalUnlockTimestampAfterCatalytic`: Get the timestamp for `FinalUnlocked` (after Catalytic).
    *   `getEntropicPenaltyRate`: Get the current entropic penalty rate.
    *   `isWhitelistedForWithdrawal`: Check if an address/token pair is whitelisted.
    *   `canWithdrawERC20`: Simulate withdrawal eligibility for a specific ERC20.
    *   `canWithdrawERC721`: Simulate withdrawal eligibility for a specific ERC721.

5.  **Standard & Hook Functions:**
    *   `onERC721Received`: ERC721 receiving hook (required for `safeTransferFrom`).
    *   `pause`: Pause the contract (Owner).
    *   `unpause`: Unpause the contract (Owner).
    *   `transferOwnership`: Transfer ownership (Owner).
    *   `renounceOwnership`: Renounce ownership (Owner).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// --- Outline and Function Summary ---
//
// Contract Name: QuantumVault
//
// Concept: A multi-state vault for ERC20 and ERC721 tokens. The vault progresses
// through distinct states based on time and the presence of specific "catalyst"
// tokens/NFTs. Each state modifies withdrawal conditions and available functions.
// Optional "modifier" tokens/NFTs can unlock additional privileges. Includes
// conditional penalties and whitelisting.
//
// States:
// 1. InitialLocked: Vault locked, only deposits and admin.
// 2. TemporalPhase: Unlocked by time. Basic conditional withdrawals possible.
// 3. CatalyticPhase: Unlocked by holding all required catalysts. More flexible withdrawals.
// 4. EntropicPhase: Penalty state, triggered by withdrawing required catalysts from CatalyticPhase. Penalties apply.
// 5. FinalUnlocked: Fully unlocked by time (from Catalytic) or owner action (from Entropic).
//
// Function Categories:
// 1. Core Vault Operations: depositERC20, depositERC721, withdrawERC20, withdrawERC721, emergencyWithdraw
// 2. State Management: attemptStateTransition, forceFinalUnlockFromEntropic
// 3. Configuration (Owner Only): setTemporalUnlockTimestamp, setFinalUnlockTimestampAfterCatalytic,
//    addRequiredCatalystERC20, removeRequiredCatalystERC20, addRequiredCatalystERC721, removeRequiredCatalystERC721,
//    addOptionalModifierERC20, removeOptionalModifierERC20, addOptionalModifierERC721, removeOptionalModifierERC721,
//    setEntropicPenaltyRate, addWithdrawalWhitelist, removeWithdrawalWhitelist
// 4. Utility & View Functions: getCurrentState, getContractERC20Balance, getContractERC721TokenCount, holdsERC721,
//    getRequiredCatalystsERC20, getRequiredCatalystsERC721, getOptionalModifiersERC20, getOptionalModifiersERC721,
//    getTemporalUnlockTimestamp, getFinalUnlockTimestampAfterCatalytic, getEntropicPenaltyRate, isWhitelistedForWithdrawal,
//    canWithdrawERC20, canWithdrawERC721
// 5. Standard & Hook Functions: onERC721Received, pause, unpause, transferOwnership, renounceOwnership
//
// --- End Outline and Function Summary ---

contract QuantumVault is Ownable, Pausable, IERC721Receiver {
    using SafeERC20 for IERC20;
    using Address for address;

    // --- State Management ---
    enum State {
        InitialLocked,
        TemporalPhase,
        CatalyticPhase,
        EntropicPhase,
        FinalUnlocked
    }

    State public currentState;

    uint256 public temporalUnlockTimestamp; // Timestamp to transition to TemporalPhase
    uint256 public finalUnlockTimestampAfterCatalytic; // Timestamp to transition from CatalyticPhase to FinalUnlocked

    // --- Catalysts & Modifiers ---
    // Required catalysts for CatalyticPhase (Contract holds these)
    mapping(address => uint256) private requiredCatalystERC20; // token => amount
    mapping(address => mapping(uint256 => bool)) private requiredCatalystERC721; // token => tokenId => isRequired

    // Keep track of required catalysts for view functions (can become large)
    address[] private requiredCatalystERC20List;
    address[] private requiredCatalystERC721ContractsList;
    mapping(address => uint256[]) private requiredCatalystERC721IdsList;

    // Optional modifiers granting withdrawal privileges (User holds these)
    mapping(address => bool) private optionalModifierERC20; // token => true if optional
    mapping(address => mapping(uint256 => bool)) private optionalModifierERC721; // token => tokenId => true if optional

    // Keep track of optional modifiers for view functions
    address[] private optionalModifierERC20List;
    address[] private optionalModifierERC721ContractsList;
    mapping(address => uint256[]) private optionalModifierERC721IdsList;

    // --- Withdrawal Whitelisting ---
    mapping(address => mapping(address => bool)) private withdrawalWhitelistERC20; // user => token => whitelisted
    mapping(address => mapping(address => mapping(uint256 => bool))) private withdrawalWhitelistERC721; // user => token => tokenId => whitelisted

    // --- Entropic Penalty ---
    uint256 public entropicPenaltyRate = 0; // Percentage, e.g., 5 = 5% penalty

    // --- ERC721 Tracking (simplified) ---
    // We track ownership internally simply by whether the contract holds it.
    // To prevent infinite token ID lists, we just track *if* a token ID is held
    // rather than listing all of them for view functions, except for required/optional.
    mapping(address => mapping(uint256 => bool)) private heldERC721Tokens; // token => tokenId => heldByContract

    // --- Events ---
    event ERC20Deposited(address indexed token, address indexed user, uint256 amount);
    event ERC721Deposited(address indexed token, address indexed user, uint256 tokenId);
    event ERC20Withdrawed(address indexed token, address indexed user, uint256 amount);
    event ERC721Withdrawed(address indexed token, address indexed user, uint256 tokenId);
    event StateTransitioned(State oldState, State newState);
    event RequiredCatalystAddedERC20(address indexed token, uint256 amount);
    event RequiredCatalystRemovedERC20(address indexed token);
    event RequiredCatalystAddedERC721(address indexed token, uint256 indexed tokenId);
    event RequiredCatalystRemovedERC721(address indexed token, uint256 indexed tokenId);
    event OptionalModifierAddedERC20(address indexed token);
    event OptionalModifierRemovedERC20(address indexed token);
    event OptionalModifierAddedERC721(address indexed token, uint256 indexed tokenId);
    event OptionalModifierRemovedERC721(address indexed token, uint256 indexed tokenId);
    event EntropicPenaltyRateUpdated(uint256 newRate);
    event WithdrawalWhitelistedERC20(address indexed user, address indexed token);
    event WithdrawalUnwhitelistedERC20(address indexed user, address indexed token);
    event WithdrawalWhitelistedERC721(address indexed user, address indexed token, uint256 indexed tokenId);
    event WithdrawalUnwhitelistedERC721(address indexed user, address indexed token, uint256 indexed tokenId);

    // --- Errors ---
    error NotInAllowedState(State currentState, State[] allowedStates);
    error InvalidStateTransition(State currentState, State attemptedState);
    error RequiredCatalystsNotMet();
    error WithdrawalNotAllowedInCurrentState();
    error WithdrawalRequiresModifier();
    error UserDoesNotHoldModifier();
    error InsufficientBalance();
    error TokenNotHeldByVault();
    error AmountCannotBeZero();
    error PenaltyRateInvalid(uint256 rate);
    error TimestampMustBeInFuture(uint256 timestamp);
    error InvalidRequirement(address token, uint256 amountOrId);

    // --- Modifiers ---
    modifier inState(State targetState) {
        if (currentState != targetState) {
             revert NotInAllowedState(currentState, new State[](1).push(targetState));
        }
        _;
    }

    modifier notInState(State targetState) {
         if (currentState == targetState) {
             revert NotInAllowedState(currentState, new State[](1).push(targetState));
        }
        _;
    }

    modifier onlyAllowedStates(State[] calldata allowedStates) {
        bool found = false;
        for (uint i = 0; i < allowedStates.length; i++) {
            if (currentState == allowedStates[i]) {
                found = true;
                break;
            }
        }
        if (!found) {
            revert NotInAllowedState(currentState, allowedStates);
        }
        _;
    }


    // --- Constructor ---
    constructor(uint256 _temporalUnlockDelay) Ownable(msg.sender) Pausable(false) {
        currentState = State.InitialLocked;
        temporalUnlockTimestamp = block.timestamp + _temporalUnlockDelay; // Set initial temporal unlock
    }

    // --- Core Vault Operations ---

    /**
     * @dev Deposits ERC20 tokens into the vault.
     * @param token Address of the ERC20 token.
     * @param amount Amount of tokens to deposit.
     */
    function depositERC20(address token, uint256 amount) external whenNotPaused {
        if (amount == 0) revert AmountCannotBeZero();
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        emit ERC20Deposited(token, msg.sender, amount);
    }

    /**
     * @dev Deposits ERC721 tokens into the vault.
     * @param token Address of the ERC721 token.
     * @param tokenId ID of the token to deposit.
     */
    function depositERC721(address token, uint256 tokenId) external whenNotPaused {
        IERC721(token).safeTransferFrom(msg.sender, address(this), tokenId);
        // ERC721Receiver hook handles setting heldERC721Tokens state
        emit ERC721Deposited(token, msg.sender, tokenId);
    }

    /**
     * @dev Withdraws ERC20 tokens from the vault based on current state and conditions.
     * Applies penalty if in EntropicPhase.
     * @param token Address of the ERC20 token.
     * @param amount Amount of tokens to withdraw.
     * @param requiresModifier Flag indicating if this specific withdrawal requires the user to hold *any* optional modifier token/NFT.
     */
    function withdrawERC20(address token, uint256 amount, bool requiresModifier)
        external
        whenNotPaused
    {
        if (amount == 0) revert AmountCannotBeZero();
        if (IERC20(token).balanceOf(address(this)) < amount) revert InsufficientBalance();

        _checkWithdrawalEligibility(msg.sender, token, 0, requiresModifier); // 0 for token ID indicates ERC20

        uint256 withdrawalAmount = amount;
        if (currentState == State.EntropicPhase) {
            uint256 penaltyAmount = (amount * entropicPenaltyRate) / 100;
            withdrawalAmount = amount - penaltyAmount;
            // Penalty amount could be sent to a dead address (burn) or owner
            // For simplicity, we'll just 'burn' it by not transferring the penalty portion
        }

        // Check if withdrawing a required catalyst while in CatalyticPhase
        if (currentState == State.CatalyticPhase && requiredCatalystERC20[token] > 0) {
            // Check if this withdrawal would drop the balance below the requirement
            // Note: This simple check assumes withdrawal is from the required balance.
            // A more complex system might track which specific tokens were deposited as catalysts.
            // For this contract, we check if the *remaining* balance after withdrawal
            // would be less than the requirement. If so, it triggers Entropic.
            if (IERC20(token).balanceOf(address(this)) - amount < requiredCatalystERC20[token]) {
                 _transitionState(State.EntropicPhase);
            }
        }

        IERC20(token).safeTransfer(msg.sender, withdrawalAmount);
        emit ERC20Withdrawal(token, msg.sender, withdrawalAmount);
        if (currentState == State.EntropicPhase && withdrawalAmount < amount) {
             // Optional: emit a Penalty event
        }
    }

    /**
     * @dev Withdraws ERC721 tokens from the vault based on current state and conditions.
     * Applies penalty if in EntropicPhase (note: penalties for NFTs might be different,
     * here we just prevent withdrawal or apply logic).
     * @param token Address of the ERC721 token.
     * @param tokenId ID of the token to withdraw.
     * @param requiresModifier Flag indicating if this specific withdrawal requires the user to hold *any* optional modifier token/NFT.
     */
    function withdrawERC721(address token, uint256 tokenId, bool requiresModifier)
        external
        whenNotPaused
    {
        if (!heldERC721Tokens[token][tokenId]) revert TokenNotHeldByVault();

        _checkWithdrawalEligibility(msg.sender, token, tokenId, requiresModifier);

        // Check if withdrawing a required catalyst while in CatalyticPhase
        if (currentState == State.CatalyticPhase && requiredCatalystERC721[token][tokenId]) {
             _transitionState(State.EntropicPhase); // Withdrawing a required catalyst triggers EntropicPhase
        }

        IERC721(token).safeTransferFrom(address(this), msg.sender, tokenId);
        heldERC721Tokens[token][tokenId] = false; // Update internal tracking
        emit ERC721Withdrawed(token, msg.sender, tokenId);

        // Note: ERC721 penalty in EntropicPhase is handled by _checkWithdrawalEligibility preventing withdrawal unless whitelisted
    }

    /**
     * @dev Owner can withdraw any token in case of emergency. Bypasses state checks.
     * @param token Address of the token (ERC20 or ERC721).
     * @param tokenId ID for ERC721, 0 for ERC20.
     * @param amount Amount for ERC20, 0 for ERC721.
     */
    function emergencyWithdraw(address token, uint256 tokenId, uint256 amount) external onlyOwner whenNotPaused {
        if (tokenId == 0 && amount > 0) { // Assume ERC20
            if (IERC20(token).balanceOf(address(this)) < amount) revert InsufficientBalance();
            IERC20(token).safeTransfer(msg.sender, amount);
            emit ERC20Withdrawal(token, msg.sender, amount); // Use withdrawal event
        } else if (tokenId > 0 && amount == 0) { // Assume ERC721
             if (!heldERC721Tokens[token][tokenId]) revert TokenNotHeldByVault();
             IERC721(token).safeTransferFrom(address(this), msg.sender, tokenId);
             heldERC721Tokens[token][tokenId] = false; // Update internal tracking
             emit ERC721Withdrawed(token, msg.sender, tokenId); // Use withdrawal event
        } else {
            revert InvalidRequirement(token, tokenId == 0 ? amount : tokenId);
        }
    }


    // --- Internal Withdrawal Eligibility Check ---
    function _checkWithdrawalEligibility(address user, address token, uint256 tokenId, bool requiresModifier) internal view {
        // Check state-based restrictions
        if (currentState == State.InitialLocked) {
             // Allow if explicitly whitelisted
             if (!(tokenId == 0 ? withdrawalWhitelistERC20[user][token] : withdrawalWhitelistERC721[user][token][tokenId])) {
                 revert WithdrawalNotAllowedInCurrentState();
             }
        } else if (currentState == State.TemporalPhase) {
            // Allow if whitelisted OR (does not require modifier OR user holds modifier)
            if (!(tokenId == 0 ? withdrawalWhitelistERC20[user][token] : withdrawalWhitelistERC721[user][token][tokenId])) {
                if (requiresModifier) {
                    // Check if user holds any optional modifier ERC20 or ERC721
                    bool userHoldsAnyModifier = false;
                    for(uint i = 0; i < optionalModifierERC20List.length; i++) {
                         if (IERC20(optionalModifierERC20List[i]).balanceOf(user) > 0) {
                              userHoldsAnyModifier = true; break;
                         }
                    }
                    if (!userHoldsAnyModifier) {
                         for(uint i = 0; i < optionalModifierERC721ContractsList.length; i++) {
                              address modContract = optionalModifierERC721ContractsList[i];
                              uint256[] storage modIds = optionalModifierERC721IdsList[modContract];
                              for(uint j = 0; j < modIds.length; j++) {
                                   if (IERC721(modContract).ownerOf(modIds[j]) == user) {
                                        userHoldsAnyModifier = true; break;
                                   }
                              }
                              if (userHoldsAnyModifier) break;
                         }
                    }
                    if (!userHoldsAnyModifier) revert UserDoesNotHoldModifier();
                }
                // No other restrictions beyond modifier check in TemporalPhase (unless whitelisted)
            }

        } else if (currentState == State.CatalyticPhase) {
            // Generally allowed, but check modifier requirement if specified
            if (requiresModifier) {
                 bool userHoldsAnyModifier = false;
                    for(uint i = 0; i < optionalModifierERC20List.length; i++) {
                         if (IERC20(optionalModifierERC20List[i]).balanceOf(user) > 0) {
                              userHoldsAnyModifier = true; break;
                         }
                    }
                    if (!userHoldsAnyModifier) {
                         for(uint i = 0; i < optionalModifierERC721ContractsList.length; i++) {
                              address modContract = optionalModifierERC721ContractsList[i];
                              uint256[] storage modIds = optionalModifierERC721IdsList[modContract];
                              for(uint j = 0; j < modIds.length; j++) {
                                   if (IERC721(modContract).ownerOf(modIds[j]) == user) {
                                        userHoldsAnyModifier = true; break;
                                   }
                              }
                              if (userHoldsAnyModifier) break;
                         }
                    }
                    if (!userHoldsAnyModifier) revert UserDoesNotHoldModifier();
            }

        } else if (currentState == State.EntropicPhase) {
            // Only allow if explicitly whitelisted
             if (!(tokenId == 0 ? withdrawalWhitelistERC20[user][token] : withdrawalWhitelistERC721[user][token][tokenId])) {
                 revert WithdrawalNotAllowedInCurrentState();
             }
             // Penalties are applied in the withdraw function itself, not here.

        } else if (currentState == State.FinalUnlocked) {
            // All withdrawals allowed
        }
    }


    // --- State Management ---

    /**
     * @dev Attempts to transition the state of the vault based on conditions.
     * Can be called by anyone to push the state forward once conditions are met.
     */
    function attemptStateTransition() external whenNotPaused {
        State oldState = currentState;
        State nextState = oldState;

        if (currentState == State.InitialLocked && block.timestamp >= temporalUnlockTimestamp) {
            nextState = State.TemporalPhase;
        } else if (currentState == State.TemporalPhase && _checkCatalyticConditionsMet()) {
            nextState = State.CatalyticPhase;
            // Optionally set finalUnlockTimestampAfterCatalytic here if it wasn't set before
            // if (finalUnlockTimestampAfterCatalytic == 0) { finalUnlockTimestampAfterCatalytic = block.timestamp + SOME_DEFAULT_DELAY; }
        } else if (currentState == State.CatalyticPhase && block.timestamp >= finalUnlockTimestampAfterCatalytic && finalUnlockTimestampAfterCatalytic > 0) {
             nextState = State.FinalUnlocked;
        }
        // Entropic -> FinalUnlocked transition is owner-only

        if (nextState != oldState) {
            _transitionState(nextState);
        }
    }

    /**
     * @dev Internal function to check if all required catalysts are held by the contract.
     */
    function _checkCatalyticConditionsMet() internal view returns (bool) {
        for (uint i = 0; i < requiredCatalystERC20List.length; i++) {
            address token = requiredCatalystERC20List[i];
            uint256 requiredAmount = requiredCatalystERC20[token];
            if (IERC20(token).balanceOf(address(this)) < requiredAmount) {
                return false;
            }
        }

        for (uint i = 0; i < requiredCatalystERC721ContractsList.length; i++) {
            address token = requiredCatalystERC721ContractsList[i];
            uint256[] storage requiredIds = requiredCatalystERC721IdsList[token];
            for (uint j = 0; j < requiredIds.length; j++) {
                 uint256 tokenId = requiredIds[j];
                 // Check if the specific token ID is held by this contract
                 // Requires trusting the internal heldERC721Tokens state,
                 // or calling ownerOf (more gas, might revert).
                 // Let's use internal state for efficiency, assuming deposits update it correctly.
                 if (!heldERC721Tokens[token][tokenId]) {
                     return false;
                 }
            }
        }
        return true;
    }


    /**
     * @dev Internal function to perform state transition.
     * @param nextState The state to transition to.
     */
    function _transitionState(State nextState) internal {
        emit StateTransitioned(currentState, nextState);
        currentState = nextState;
    }

    /**
     * @dev Owner function to force transition from EntropicPhase to FinalUnlocked.
     */
    function forceFinalUnlockFromEntropic() external onlyOwner inState(State.EntropicPhase) {
        _transitionState(State.FinalUnlocked);
    }

    // --- Configuration (Owner Only) ---

    /**
     * @dev Set the timestamp for the TemporalPhase transition. Must be in the future.
     * @param timestamp The new timestamp.
     */
    function setTemporalUnlockTimestamp(uint256 timestamp) external onlyOwner {
        if (timestamp <= block.timestamp) revert TimestampMustBeInFuture(timestamp);
        temporalUnlockTimestamp = timestamp;
    }

     /**
     * @dev Set the timestamp for the FinalUnlocked transition after CatalyticPhase. Must be in the future or 0 (disabled).
     * @param timestamp The new timestamp.
     */
    function setFinalUnlockTimestampAfterCatalytic(uint256 timestamp) external onlyOwner {
         if (timestamp != 0 && timestamp <= block.timestamp) revert TimestampMustBeInFuture(timestamp);
        finalUnlockTimestampAfterCatalytic = timestamp;
    }

    /**
     * @dev Add an ERC20 token and amount as a required catalyst for CatalyticPhase.
     * @param token Address of the ERC20 token.
     * @param amount Required amount.
     */
    function addRequiredCatalystERC20(address token, uint256 amount) external onlyOwner {
        if (amount == 0) revert InvalidRequirement(token, amount);
        if (requiredCatalystERC20[token] == 0) {
            requiredCatalystERC20List.push(token);
        }
        requiredCatalystERC20[token] = amount;
        emit RequiredCatalystAddedERC20(token, amount);
    }

    /**
     * @dev Remove an ERC20 token from the required catalyst list.
     * @param token Address of the ERC20 token.
     */
    function removeRequiredCatalystERC20(address token) external onlyOwner {
        if (requiredCatalystERC20[token] > 0) {
            requiredCatalystERC20[token] = 0;
            // Simple removal from list (O(N)) - sufficient for typical use cases
            for (uint i = 0; i < requiredCatalystERC20List.length; i++) {
                if (requiredCatalystERC20List[i] == token) {
                    requiredCatalystERC20List[i] = requiredCatalystERC20List[requiredCatalystERC20List.length - 1];
                    requiredCatalystERC20List.pop();
                    break;
                }
            }
            emit RequiredCatalystRemovedERC20(token);
        }
    }

    /**
     * @dev Add an ERC721 token contract and ID as a required catalyst for CatalyticPhase.
     * @param token Address of the ERC721 token contract.
     * @param tokenId Required token ID.
     */
    function addRequiredCatalystERC721(address token, uint256 tokenId) external onlyOwner {
        if (requiredCatalystERC721[token][tokenId]) revert InvalidRequirement(token, tokenId);
        requiredCatalystERC721[token][tokenId] = true;

        bool contractExists = false;
        for(uint i=0; i<requiredCatalystERC721ContractsList.length; i++) {
             if(requiredCatalystERC721ContractsList[i] == token) {
                  contractExists = true; break;
             }
        }
        if (!contractExists) {
             requiredCatalystERC721ContractsList.push(token);
        }
        requiredCatalystERC721IdsList[token].push(tokenId);

        emit RequiredCatalystAddedERC721(token, tokenId);
    }

    /**
     * @dev Remove an ERC721 token from the required catalyst list.
     * @param token Address of the ERC721 token contract.
     * @param tokenId Token ID to remove.
     */
    function removeRequiredCatalystERC721(address token, uint256 tokenId) external onlyOwner {
        if (!requiredCatalystERC721[token][tokenId]) revert InvalidRequirement(token, tokenId);
        requiredCatalystERC721[token][tokenId] = false;

        // Remove from list (O(N)) - sufficient for typical use cases
        uint265[] storage ids = requiredCatalystERC721IdsList[token];
        for(uint i = 0; i < ids.length; i++) {
             if (ids[i] == tokenId) {
                 ids[i] = ids[ids.length - 1];
                 ids.pop();
                 break;
             }
        }
        // Optionally clean up requiredCatalystERC721ContractsList if the last ID for a contract is removed

        emit RequiredCatalystRemovedERC721(token, tokenId);
    }


    /**
     * @dev Add an ERC20 token as an optional modifier granting withdrawal privileges.
     * @param token Address of the ERC20 token.
     */
    function addOptionalModifierERC20(address token) external onlyOwner {
        if (!optionalModifierERC20[token]) {
            optionalModifierERC20[token] = true;
            optionalModifierERC20List.push(token);
            emit OptionalModifierAddedERC20(token);
        }
    }

    /**
     * @dev Remove an ERC20 token from the optional modifier list.
     * @param token Address of the ERC20 token.
     */
    function removeOptionalModifierERC20(address token) external onlyOwner {
         if (optionalModifierERC20[token]) {
            optionalModifierERC20[token] = false;
            // Simple removal from list (O(N))
             for (uint i = 0; i < optionalModifierERC20List.length; i++) {
                if (optionalModifierERC20List[i] == token) {
                    optionalModifierERC20List[i] = optionalModifierERC20List[optionalModifierERC20List.length - 1];
                    optionalModifierERC20List.pop();
                    break;
                }
            }
            emit OptionalModifierRemovedERC20(token);
        }
    }

    /**
     * @dev Add an ERC721 token as an optional modifier granting withdrawal privileges.
     * @param token Address of the ERC721 token contract.
     * @param tokenId Optional token ID (0 means any ID of this contract is a modifier).
     * Note: Using tokenId 0 for "any ID" adds complexity to user holding check. Let's require specific IDs.
     */
    function addOptionalModifierERC721(address token, uint256 tokenId) external onlyOwner {
         if (tokenId == 0) revert InvalidRequirement(token, tokenId); // Must be specific ID
         if (!optionalModifierERC721[token][tokenId]) {
            optionalModifierERC721[token][tokenId] = true;

            bool contractExists = false;
            for(uint i=0; i<optionalModifierERC721ContractsList.length; i++) {
                 if(optionalModifierERC721ContractsList[i] == token) {
                      contractExists = true; break;
                 }
            }
            if (!contractExists) {
                 optionalModifierERC721ContractsList.push(token);
            }
            optionalModifierERC721IdsList[token].push(tokenId);

            emit OptionalModifierAddedERC721(token, tokenId);
        }
    }

     /**
     * @dev Remove an ERC721 token from the optional modifier list.
     * @param token Address of the ERC721 token contract.
     * @param tokenId Token ID to remove.
     */
    function removeOptionalModifierERC721(address token, uint256 tokenId) external onlyOwner {
        if (optionalModifierERC721[token][tokenId]) {
            optionalModifierERC721[token][tokenId] = false;

            // Remove from list (O(N))
            uint265[] storage ids = optionalModifierERC721IdsList[token];
            for(uint i = 0; i < ids.length; i++) {
                 if (ids[i] == tokenId) {
                     ids[i] = ids[ids.length - 1];
                     ids.pop();
                     break;
                 }
            }
            // Optionally clean up optionalModifierERC721ContractsList if the last ID for a contract is removed

            emit OptionalModifierRemovedERC721(token, tokenId);
        }
    }


    /**
     * @dev Set the penalty rate for withdrawals in EntropicPhase. Max 100%.
     * @param rate The penalty rate (0-100).
     */
    function setEntropicPenaltyRate(uint256 rate) external onlyOwner {
        if (rate > 100) revert PenaltyRateInvalid(rate);
        entropicPenaltyRate = rate;
        emit EntropicPenaltyRateUpdated(rate);
    }

    /**
     * @dev Whitelist an address to allow withdrawal of a specific ERC20 token, bypassing some state restrictions.
     * @param user Address to whitelist.
     * @param token Address of the ERC20 token.
     */
    function addWithdrawalWhitelist(address user, address token) external onlyOwner {
        if (!withdrawalWhitelistERC20[user][token]) {
            withdrawalWhitelistERC20[user][token] = true;
            emit WithdrawalWhitelistedERC20(user, token);
        }
    }

     /**
     * @dev Whitelist an address to allow withdrawal of a specific ERC721 token, bypassing some state restrictions.
     * @param user Address to whitelist.
     * @param token Address of the ERC721 token contract.
     * @param tokenId Token ID to whitelist.
     */
    function addWithdrawalWhitelist(address user, address token, uint256 tokenId) external onlyOwner {
        if (!withdrawalWhitelistERC721[user][token][tokenId]) {
            withdrawalWhitelistERC721[user][token][tokenId] = true;
            emit WithdrawalWhitelistedERC721(user, token, tokenId);
        }
    }

    /**
     * @dev Remove an address/ERC20 pair from the whitelist.
     * @param user Address to remove.
     * @param token Address of the ERC20 token.
     */
    function removeWithdrawalWhitelist(address user, address token) external onlyOwner {
        if (withdrawalWhitelistERC20[user][token]) {
            withdrawalWhitelistERC20[user][token] = false;
            emit WithdrawalUnwhitelistedERC20(user, token);
        }
    }

     /**
     * @dev Remove an address/ERC721 pair from the whitelist.
     * @param user Address to remove.
     * @param token Address of the ERC721 token contract.
     * @param tokenId Token ID to remove.
     */
    function removeWithdrawalWhitelist(address user, address token, uint256 tokenId) external onlyOwner {
        if (withdrawalWhitelistERC721[user][token][tokenId]) {
            withdrawalWhitelistERC721[user][token][tokenId] = false;
            emit WithdrawalUnwhitelistedERC721(user, token, tokenId);
        }
    }


    // --- Utility & View Functions ---

    /**
     * @dev Returns the current state of the vault.
     */
    function getCurrentState() external view returns (State) {
        return currentState;
    }

     /**
     * @dev Returns the vault's balance of a specific ERC20 token.
     * @param token Address of the ERC20 token.
     */
    function getContractERC20Balance(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    /**
     * @dev Checks if the vault holds a specific ERC721 token by contract and ID.
     * @param token Address of the ERC721 contract.
     * @param tokenId ID of the token.
     */
    function holdsERC721(address token, uint256 tokenId) external view returns (bool) {
        return heldERC721Tokens[token][tokenId];
    }

    /**
     * @dev Gets the list of required ERC20 catalyst tokens.
     * @return An array of required ERC20 token addresses.
     */
    function getRequiredCatalystsERC20() external view returns (address[] memory) {
        return requiredCatalystERC20List;
    }

     /**
     * @dev Gets the required amount for a specific ERC20 catalyst.
     * @param token Address of the ERC20 token.
     * @return The required amount.
     */
    function getRequiredCatalystERC20Amount(address token) external view returns (uint256) {
        return requiredCatalystERC20[token];
    }

    /**
     * @dev Gets the list of required ERC721 catalyst token contracts.
     * @return An array of required ERC721 token contract addresses.
     */
    function getRequiredCatalystsERC721Contracts() external view returns (address[] memory) {
        return requiredCatalystERC721ContractsList;
    }

     /**
     * @dev Gets the list of required ERC721 token IDs for a specific contract.
     * Note: This view function could be expensive if a contract has many required IDs.
     * @param token Address of the ERC721 contract.
     * @return An array of required token IDs.
     */
    function getRequiredCatalystsERC721Ids(address token) external view returns (uint256[] memory) {
        return requiredCatalystERC721IdsList[token];
    }

    /**
     * @dev Gets the list of optional modifier ERC20 tokens.
     * @return An array of optional modifier ERC20 token addresses.
     */
    function getOptionalModifiersERC20() external view returns (address[] memory) {
        return optionalModifierERC20List;
    }

     /**
     * @dev Gets the list of optional modifier ERC721 token contracts.
     * @return An array of optional modifier ERC721 token contract addresses.
     */
    function getOptionalModifiersERC721Contracts() external view returns (address[] memory) {
        return optionalModifierERC721ContractsList;
    }

    /**
     * @dev Gets the list of optional modifier ERC721 token IDs for a specific contract.
     * Note: This view function could be expensive if a contract has many optional IDs.
     * @param token Address of the ERC721 contract.
     * @return An array of optional token IDs.
     */
    function getOptionalModifiersERC721Ids(address token) external view returns (uint256[] memory) {
        return optionalModifierERC721IdsList[token];
    }

    /**
     * @dev Gets the timestamp for the TemporalPhase transition.
     */
    function getTemporalUnlockTimestamp() external view returns (uint256) {
        return temporalUnlockTimestamp;
    }

     /**
     * @dev Gets the timestamp for the FinalUnlocked transition after CatalyticPhase.
     */
    function getFinalUnlockTimestampAfterCatalytic() external view returns (uint256) {
        return finalUnlockTimestampAfterCatalytic;
    }

    /**
     * @dev Gets the current entropic penalty rate (0-100).
     */
    function getEntropicPenaltyRate() external view returns (uint256) {
        return entropicPenaltyRate;
    }

    /**
     * @dev Checks if an address/ERC20 pair is whitelisted for withdrawal.
     * @param user Address to check.
     * @param token Address of the ERC20 token.
     */
    function isWhitelistedForWithdrawal(address user, address token) external view returns (bool) {
        return withdrawalWhitelistERC20[user][token];
    }

     /**
     * @dev Checks if an address/ERC721 pair is whitelisted for withdrawal.
     * @param user Address to check.
     * @param token Address of the ERC721 token contract.
     * @param tokenId Token ID to check.
     */
     function isWhitelistedForWithdrawal(address user, address token, uint256 tokenId) external view returns (bool) {
        return withdrawalWhitelistERC721[user][token][tokenId];
     }

    /**
     * @dev Simulates withdrawal eligibility for a specific ERC20 token for a user.
     * Does *not* check amount or user balance of modifiers, only state and whitelist.
     * @param user Address of the user.
     * @param token Address of the ERC20 token.
     * @param requiresModifier Flag indicating if this check assumes the withdrawal requires a modifier.
     * @return True if withdrawal *might* be possible based on state and whitelist, false otherwise.
     */
    function canWithdrawERC20(address user, address token, bool requiresModifier) external view returns (bool) {
        // This is a simplified check and doesn't guarantee withdrawal success (e.g. insufficient balance, lack of modifier held by user)
         try this._checkWithdrawalEligibility(user, token, 0, requiresModifier) {} catch { return false; }
         return true;
    }

    /**
     * @dev Simulates withdrawal eligibility for a specific ERC721 token for a user.
     * Does *not* check if vault holds token or user balance of modifiers, only state and whitelist.
     * @param user Address of the user.
     * @param token Address of the ERC721 token contract.
     * @param tokenId ID of the token.
     * @param requiresModifier Flag indicating if this check assumes the withdrawal requires a modifier.
     * @return True if withdrawal *might* be possible based on state and whitelist, false otherwise.
     */
     function canWithdrawERC721(address user, address token, uint256 tokenId, bool requiresModifier) external view returns (bool) {
        // This is a simplified check and doesn't guarantee withdrawal success (e.g. token not held by vault, lack of modifier held by user)
        // It also doesn't check heldERC721Tokens[token][tokenId] to keep the view pure from potential state side-effects check if the contract actually *has* the token.
         try this._checkWithdrawalEligibility(user, token, tokenId, requiresModifier) {} catch { return false; }
         return true;
     }


    // --- Standard & Hook Functions ---

    /**
     * @dev Hook that is called when an ERC721 token is transferred to the contract.
     * Used by ERC721 `safeTransferFrom`.
     */
    function onERC721Received(address, address from, uint256 tokenId, bytes calldata)
        external
        returns (bytes4)
    {
        // We record the token ID as held by the contract
        heldERC721Tokens[msg.sender][tokenId] = true; // msg.sender is the token contract address
        // Note: 'from' is the original owner, not necessarily msg.sender who initiated safeTransferFrom
        // If you need to track the depositor, you'd need a deposit function wrapper.
        return this.onERC721Received.selector;
    }

    // Override Pausable functions to ensure correct access control
    function pause() public override onlyOwner {
        _pause();
    }

    function unpause() public override onlyOwner {
        _unpause();
    }
}
```