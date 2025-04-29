Okay, let's design a complex and multi-faceted smart contract called `QuantumVault`. The concept is a secure vault for holding various assets (ETH, ERC20, ERC721) where access, withdrawal mechanics, and potential yield generation are controlled by a dynamic state machine. This state machine transitions between different "dimensions" or "states" based on internal parameters, time, potentially external data (like a random oracle), and user interactions, introducing unpredictability and strategic complexity.

It's hard to guarantee *zero* overlap with *any* open-source project's specific *implementation detail*, but the *combination* of these concepts and the specific state-dependent logic for multiple asset types, dynamic parameters influenced by a state machine, and potential random triggers aim for a novel design rather than duplicating a standard template (like a simple ERC20, a basic vault, or a standard staking contract).

---

## Smart Contract Outline: `QuantumVault`

This contract acts as a multi-asset vault (ETH, ERC20, ERC721) governed by a dynamic state machine. Its behavior, particularly concerning withdrawals and yield, changes based on its current state.

1.  **Core State:** An `enum` defining different states (e.g., `Stable`, `Volatile`, `Restricted`, `QuantumFlux`).
2.  **Asset Management:** Mappings to track deposited ETH, ERC20 tokens, and ERC721 tokens for each user.
3.  **State Machine:** Logic to transition between states based on:
    *   Time elapsed.
    *   Thresholds (e.g., Total Value Locked - TVL).
    *   Potentially external randomness (Chainlink VRF integration).
    *   Manual admin/governance override.
4.  **Dynamic Mechanics:**
    *   Withdrawal limits/availability based on state.
    *   Dynamic withdrawal fees based on state.
    *   Simulated internal yield accrual based on state and duration.
5.  **Parameters:** Configurable parameters for state transitions, fees, and yield rates.
6.  **Permissions:** Owner/Admin roles for configuration and emergency actions.
7.  **Advanced Concepts:**
    *   State-dependent function execution.
    *   Oracle integration (Chainlink VRF for randomness).
    *   Internal "Catalyst" function that triggers complex state checks and potential effects.
    *   Delegated withdrawal permissions for specific assets.
    *   Ability to query predicted withdrawal outcomes under current conditions.

## Function Summary:

1.  `constructor()`: Initializes contract owner and allowed asset lists.
2.  `depositETH()`: Users deposit ETH into the vault.
3.  `depositERC20(IERC20 token, uint256 amount)`: Users deposit a specified ERC20 token. Requires prior approval.
4.  `depositERC721(IERC721 token, uint256 tokenId)`: Users deposit a specified ERC721 token. Requires prior approval or `setApprovalForAll`.
5.  `withdrawETH(uint256 amount)`: Users withdraw deposited ETH, subject to current vault state rules.
6.  `withdrawERC20(IERC20 token, uint256 amount)`: Users withdraw deposited ERC20, subject to current vault state rules.
7.  `withdrawERC721(IERC721 token, uint256 tokenId)`: Users withdraw deposited ERC721, subject to current vault state rules.
8.  `getCurrentVaultState()`: Returns the current state of the vault.
9.  `checkAndTransitionState()`: Checks if conditions are met for a state transition and updates the state if necessary. Can be called by anyone (e.g., keepers) to trigger transitions.
10. `manualStateTransition(VaultState newState)`: Owner/Admin can force a state transition (e.g., emergency or governance).
11. `setVaultStateParameters(...)`: Owner/Admin sets parameters governing state transitions (e.g., duration thresholds, TVL thresholds).
12. `setWithdrawalFeeParameters(...)`: Owner/Admin sets dynamic withdrawal fee percentages per state/asset.
13. `setYieldParameters(...)`: Owner/Admin sets simulated yield accrual rates per state.
14. `calculatePendingYield(address user, address tokenAddress)`: Calculates simulated yield accrued for a user's deposit of a specific token (ETH treated as token address 0).
15. `claimYield(address tokenAddress)`: Allows users to claim their calculated simulated yield for a specific token.
16. `getUserTotalDepositedETH(address user)`: Returns the total ETH deposited by a user.
17. `getUserTotalDepositedERC20(address user, IERC20 token)`: Returns the total amount of a specific ERC20 deposited by a user.
18. `getUserDepositedNFTs(address user, IERC721 token)`: Returns a list of token IDs of a specific ERC721 collection deposited by a user.
19. `getTVL_ETH()`: Returns the total ETH locked in the vault.
20. `getTVLByToken(IERC20 token)`: Returns the total amount of a specific ERC20 token locked.
21. `getNFTCountInVault(IERC721 token)`: Returns the total count of NFTs from a specific collection in the vault.
22. `predictWithdrawalAmount(address user, address tokenAddress)`: Predicts the maximum withdrawable amount for a user and asset under the *current* vault state, considering limits and fees.
23. `pauseVault(uint256 reasonCode)`: Owner can pause core vault functions (deposits/withdrawals) in an emergency.
24. `unpauseVault()`: Owner can unpause the vault.
25. `setAllowedERC20Token(IERC20 token, bool allowed)`: Owner allows/disallows deposition of a specific ERC20 token.
26. `setAllowedERC721Collection(IERC721 token, bool allowed)`: Owner allows/disallows deposition of a specific ERC721 collection.
27. `delegateWithdrawalPermission(address delegatee, address tokenAddress, uint256 amountOrTokenId, bool isNFT)`: Allows a user to grant a one-time withdrawal permission for a specific asset to another address.
28. `useDelegatedWithdrawal(address delegator, address delegatee, address tokenAddress, uint256 amountOrTokenId, bool isNFT)`: The delegatee uses the granted permission to withdraw the asset.
29. `triggerCatalystEvent()`: A complex function that checks various internal conditions (state, TVL, time, maybe random result) and potentially triggers significant internal effects or state changes based on predefined logic.
30. `sweepStuckTokens(IERC20 token, uint256 amount)`: Owner function to recover mistakenly sent ERC20 tokens (excluding allowed vault tokens).

*(Note: Chainlink VRF integration requires setting up VRFConsumerBaseV2 which adds several more functions. Including the request/fulfill pattern covers the core concept functions)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

// Outline:
// 1. State Definition (Enum)
// 2. Asset Storage (Mappings)
// 3. State Variables (Owner, parameters, state tracking, Chainlink VRF config)
// 4. Events
// 5. Modifiers (Ownership, Pausable, State Checks)
// 6. Constructor
// 7. Core Asset Deposit Functions (ETH, ERC20, ERC721)
// 8. Core Asset Withdrawal Functions (ETH, ERC20, ERC721 - State-dependent)
// 9. State Management Functions (Check, Manual Transition, Set Parameters)
// 10. Dynamic Mechanics Functions (Fee Calc, Yield Calc/Claim)
// 11. Query Functions (Balances, TVL, State, Predictions)
// 12. Admin/Configuration Functions (Pause, Set Allowed Tokens, Set Parameters)
// 13. Delegation Functions
// 14. Advanced/Complex Functions (Catalyst Trigger, VRF Integration)
// 15. Emergency Functions (Sweep, Emergency Withdrawal - simplified)

// Function Summary:
// 1. constructor()
// 2. depositETH()
// 3. depositERC20(IERC20 token, uint256 amount)
// 4. depositERC721(IERC721 token, uint256 tokenId)
// 5. withdrawETH(uint256 amount)
// 6. withdrawERC20(IERC20 token, uint256 amount)
// 7. withdrawERC721(IERC721 token, uint256 tokenId)
// 8. getCurrentVaultState()
// 9. checkAndTransitionState()
// 10. manualStateTransition(VaultState newState)
// 11. setVaultStateParameters(...)
// 12. setWithdrawalFeeParameters(...)
// 13. setYieldParameters(...)
// 14. calculatePendingYield(address user, address tokenAddress)
// 15. claimYield(address tokenAddress)
// 16. getUserTotalDepositedETH(address user)
// 17. getUserTotalDepositedERC20(address user, IERC20 token)
// 18. getUserDepositedNFTs(address user, IERC721 token)
// 19. getTVL_ETH()
// 20. getTVLByToken(IERC20 token)
// 21. getNFTCountInVault(IERC721 token)
// 22. predictWithdrawalAmount(address user, address tokenAddress)
// 23. pauseVault(uint256 reasonCode)
// 24. unpauseVault()
// 25. setAllowedERC20Token(IERC20 token, bool allowed)
// 26. setAllowedERC721Collection(IERC721 token, bool allowed)
// 27. delegateWithdrawalPermission(address delegatee, address tokenAddress, uint256 amountOrTokenId, bool isNFT)
// 28. useDelegatedWithdrawal(address delegator, address delegatee, address tokenAddress, uint256 amountOrTokenId, bool isNFT)
// 29. triggerCatalystEvent()
// 30. sweepStuckTokens(IERC20 token, uint256 amount)
// (Plus Chainlink VRF specific functions like `requestRandomWords` and `fulfillRandomWords` implicit in the VRFConsumerBaseV2 inheritance)

contract QuantumVault is Ownable, ReentrancyGuard, VRFConsumerBaseV2 {

    enum VaultState { Stable, Volatile, Restricted, QuantumFlux, Paused }

    VaultState public currentVaultState;
    uint256 public lastStateTransitionTime;
    uint256 public pauseReasonCode;

    // --- Asset Storage ---
    mapping(address => uint256) private userETHDeposits;
    mapping(address => mapping(address => uint256)) private userERC20Deposits; // user => tokenAddress => amount
    mapping(address => mapping(address => uint256[])) private userERC721Deposits; // user => collectionAddress => tokenIds

    mapping(address => bool) public allowedERC20Tokens; // tokenAddress => allowed
    mapping(address => bool) public allowedERC721Collections; // collectionAddress => allowed

    // --- State Machine Parameters ---
    struct StateParameters {
        uint256 minDuration; // Minimum time in seconds before checking for transition
        uint256 minTVL_ETH; // Minimum ETH TVL threshold
        uint256 stateSpecificParam; // A flexible parameter for state logic (e.g., volatility index threshold, max withdrawal percentage)
        uint256 yieldRatePerSecond; // Simulated yield rate per second per unit of asset
        uint256 withdrawalFeeBps; // Withdrawal fee in basis points (100 = 1%)
        bool withdrawalsEnabled; // Are standard withdrawals enabled in this state?
        bool requiresRandomness; // Does this state require a random trigger for transition?
    }

    mapping(VaultState => StateParameters) public vaultStateParameters;

    // --- Simulated Yield Tracking ---
    mapping(address => mapping(address => uint256)) private lastYieldUpdateTime; // user => tokenAddress => timestamp

    // --- Delegation ---
    // Simple one-time permission: user => tokenAddress => amountOrTokenId => delegatee => used
    mapping(address => mapping(address => mapping(uint256 => mapping(address => bool)))) public delegatedWithdrawalUsed;
    // We store the delegation details implicitly by checking the mapping state. A value of `false` means unused.

    // --- Chainlink VRF Variables ---
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    bytes32 keyHash;
    uint32 callbackGasLimit;
    uint16 requestConfirmations;
    uint32 numWords;

    uint256[] public s_randomWords;
    uint256 private s_requestId;
    address private s_lastRequester; // To track who requested the randomness

    // --- Events ---
    event ETHDeposited(address indexed user, uint256 amount);
    event ERC20Deposited(address indexed user, address indexed token, uint256 amount);
    event ERC721Deposited(address indexed user, address indexed token, uint256 tokenId);
    event ETHWithdrew(address indexed user, uint256 amount, uint256 fee);
    event ERC20Withdrew(address indexed user, address indexed token, uint256 amount, uint256 fee);
    event ERC721Withdrew(address indexed user, address indexed token, uint256 tokenId, uint256 fee);
    event StateChanged(VaultState oldState, VaultState newState, string reason);
    event ParametersUpdated(string paramType);
    event YieldClaimed(address indexed user, address indexed token, uint256 amount);
    event VaultPaused(address indexed by, uint256 reasonCode);
    event VaultUnpaused(address indexed by);
    event AllowedTokenStatusChanged(address indexed token, bool isAllowed);
    event WithdrawalPermissionDelegated(address indexed delegator, address indexed delegatee, address indexed token, uint256 amountOrTokenId, bool isNFT);
    event DelegatedWithdrawalUsed(address indexed delegator, address indexed delegatee, address indexed token, uint256 amountOrTokenId, bool isNFT);
    event CatalystEventTriggered(address indexed by, VaultState currentState, uint256 randomResult);
    event StuckTokensSwept(address indexed token, uint256 amount, address indexed to);
    event RandomnessRequested(uint256 indexed requestId, address indexed requester);
    event RandomnessFulfilled(uint256 indexed requestId, uint256[] randomWords);


    // --- Modifiers ---
    modifier whenNotPaused() {
        require(currentVaultState != VaultState.Paused, "Vault is paused");
        _;
    }

    modifier requireState(VaultState _requiredState) {
        require(currentVaultState == _requiredState, "Function not available in current state");
        _;
    }

    // --- Constructor ---
    constructor(address vrfCoordinator, uint64 subscriptionId, bytes32 _keyHash, uint32 _callbackGasLimit, uint16 _requestConfirmations, uint32 _numWords)
        Ownable(msg.sender)
        VRFConsumerBaseV2(vrfCoordinator)
    {
        currentVaultState = VaultState.Stable;
        lastStateTransitionTime = block.timestamp;
        pauseReasonCode = 0;

        // Initialize default parameters (can be updated later)
        vaultStateParameters[VaultState.Stable] = StateParameters({
            minDuration: 1 days, stateSpecificParam: 0, minTVL_ETH: 100 ether,
            yieldRatePerSecond: 1e12, // Example: 1e12 wei per second per 1 ether
            withdrawalFeeBps: 10, withdrawalsEnabled: true, requiresRandomness: false
        });
        vaultStateParameters[VaultState.Volatile] = StateParameters({
            minDuration: 1 hours, stateSpecificParam: 50, minTVL_ETH: 50 ether,
            yieldRatePerSecond: 5e11, // Lower yield
            withdrawalFeeBps: 100, withdrawalsEnabled: true, requiresRandomness: true // Higher fee, requires randomness for transition out
        });
        vaultStateParameters[VaultState.Restricted] = StateParameters({
            minDuration: 3 days, stateSpecificParam: 10, minTVL_ETH: 0,
            yieldRatePerSecond: 0, // No yield
            withdrawalFeeBps: 500, withdrawalsEnabled: false, requiresRandomness: false // High fee, withdrawals disabled
        });
         vaultStateParameters[VaultState.QuantumFlux] = StateParameters({
            minDuration: 15 minutes, stateSpecificParam: 100, minTVL_ETH: 0,
            yieldRatePerSecond: 2e12, // Higher yield potential but risky
            withdrawalFeeBps: 200, withdrawalsEnabled: true, requiresRandomness: true // Moderate fee, requires randomness
        });
         vaultStateParameters[VaultState.Paused] = StateParameters({
            minDuration: type(uint256).max, stateSpecificParam: 0, minTVL_ETH: 0,
            yieldRatePerSecond: 0, withdrawalFeeBps: 0, withdrawalsEnabled: false, requiresRandomness: false // Vault is paused, no normal ops
        });


        // Chainlink VRF Setup
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
        keyHash = _keyHash;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        numWords = _numWords;
    }

    // --- Deposit Functions ---

    receive() external payable {
        depositETH();
    }

    function depositETH() public payable nonReentrant whenNotPaused {
        require(msg.value > 0, "Cannot deposit 0 ETH");
        userETHDeposits[msg.sender] += msg.value;
        lastYieldUpdateTime[msg.sender][address(0)] = block.timestamp; // Start/update yield tracking for ETH
        emit ETHDeposited(msg.sender, msg.value);
    }

    function depositERC20(IERC20 token, uint256 amount) public nonReentrant whenNotPaused {
        require(allowedERC20Tokens[address(token)], "ERC20 token not allowed");
        require(amount > 0, "Cannot deposit 0 token");

        uint256 balanceBefore = token.balanceOf(address(this));
        require(token.transferFrom(msg.sender, address(this), amount), "ERC20 transfer failed");
        uint256 transferred = token.balanceOf(address(this)) - balanceBefore; // Actual amount transferred
        require(transferred == amount, "ERC20 transfer mismatch"); // Safety check

        userERC20Deposits[msg.sender][address(token)] += transferred;
        lastYieldUpdateTime[msg.sender][address(token)] = block.timestamp; // Start/update yield tracking for ERC20
        emit ERC20Deposited(msg.sender, address(token), transferred);
    }

    function depositERC721(IERC721 token, uint256 tokenId) public nonReentrant whenNotPaused {
        require(allowedERC721Collections[address(token)], "ERC721 collection not allowed");
        require(token.ownerOf(tokenId) == msg.sender, "Caller is not NFT owner");

        token.transferFrom(msg.sender, address(this), tokenId);

        userERC721Deposits[msg.sender][address(token)].push(tokenId);
        // NFT yield calculation might be different, leaving update time concept for fungible assets
        emit ERC721Deposited(msg.sender, address(token), tokenId);
    }

    // --- Withdrawal Functions ---

    // Internal helper to calculate fee and amount after fee
    function _calculateFeeAndAmountNet(address tokenAddress, uint256 amount) internal view returns (uint256 fee, uint256 amountNet) {
        uint256 feeBps = vaultStateParameters[currentVaultState].withdrawalFeeBps;
        if (feeBps == 0) {
            return (0, amount);
        }
        fee = (amount * feeBps) / 10000;
        amountNet = amount - fee;
        return (fee, amountNet);
    }

    function withdrawETH(uint256 amount) public nonReentrant whenNotPaused {
        StateParameters memory params = vaultStateParameters[currentVaultState];
        require(params.withdrawalsEnabled, "Withdrawals disabled in current state");
        require(userETHDeposits[msg.sender] >= amount, "Insufficient deposited ETH balance");
        require(amount > 0, "Cannot withdraw 0 ETH");

        // Implement state-specific withdrawal limits if needed, using params.stateSpecificParam
        // Example: require(amount <= userETHDeposits[msg.sender] * params.stateSpecificParam / 100, "Exceeds state withdrawal limit");

        (uint256 fee, uint256 amountNet) = _calculateFeeAndAmountNet(address(0), amount);

        // Calculate and claim pending yield before withdrawal
        _claimYield(msg.sender, address(0));

        userETHDeposits[msg.sender] -= amount;

        // Use low-level call for flexibility, checking success
        (bool success, ) = payable(msg.sender).call{value: amountNet}("");
        require(success, "ETH transfer failed");

        // Fee ETH remains in the contract
        emit ETHWithdrew(msg.sender, amount, fee);
    }

    function withdrawERC20(IERC20 token, uint256 amount) public nonReentrant whenNotPaused {
        StateParameters memory params = vaultStateParameters[currentVaultState];
        require(params.withdrawalsEnabled, "Withdrawals disabled in current state");
        require(allowedERC20Tokens[address(token)], "ERC20 token not allowed");
        require(userERC20Deposits[msg.sender][address(token)] >= amount, "Insufficient deposited ERC20 balance");
        require(amount > 0, "Cannot withdraw 0 token");

        // Implement state-specific withdrawal limits if needed, using params.stateSpecificParam

        (uint256 fee, uint256 amountNet) = _calculateFeeAndAmountNet(address(token), amount);

        // Calculate and claim pending yield before withdrawal
        _claimYield(msg.sender, address(token));

        userERC20Deposits[msg.sender][address(token)] -= amount;

        require(token.transfer(msg.sender, amountNet), "ERC20 transfer failed");

        // Fee tokens remain in the contract
        emit ERC20Withdrew(msg.sender, address(token), amount, fee);
    }

    function withdrawERC721(IERC721 token, uint256 tokenId) public nonReentrant whenNotPaused {
        StateParameters memory params = vaultStateParameters[currentVaultState];
        require(params.withdrawalsEnabled, "Withdrawals disabled in current state");
        require(allowedERC721Collections[address(token)], "ERC721 collection not allowed");

        uint256 fee = 0; // ERC721 withdrawal fees might be different logic (e.g., fixed fee, or based on state-specific param)
        // For simplicity, let's apply a fee *conceptually* but not transfer a partial NFT.
        // A real-world contract might require a separate token payment for NFT withdrawal fee.
        // Here, we just calculate and perhaps record it. Let's apply a notional fee, but transfer the whole NFT.
        // The fee calculation using _calculateFeeAndAmountNet is for fungible assets. For NFTs, let's make it a fixed cost or 0 for simplicity.
        // Option 1: No fee on NFT withdrawal
        // Option 2: Require separate token payment (more complex)
        // Let's go with Option 1 for now to keep the function signature simple.
        // fee = (1 * params.withdrawalFeeBps) / 100; // Notional fee units

        // Find the NFT in the user's deposited list and remove it
        uint256[] storage userNFTs = userERC721Deposits[msg.sender][address(token)];
        bool found = false;
        for (uint i = 0; i < userNFTs.length; i++) {
            if (userNFTs[i] == tokenId) {
                // Swap with last element and pop
                userNFTs[i] = userNFTs[userNFTs.length - 1];
                userNFTs.pop();
                found = true;
                break;
            }
        }
        require(found, "User does not have this NFT deposited");

        token.transferFrom(address(this), msg.sender, tokenId);

        emit ERC721Withdrew(msg.sender, address(token), tokenId, fee); // Emitting fee as 0 for now
    }

    // --- State Management Functions ---

    function checkAndTransitionState() public nonReentrant {
        VaultState oldState = currentVaultState;
        VaultState nextState = oldState; // Default: no change

        // Logic for state transitions (example conditions)
        // More complex logic can be added involving TVL, time, external data, etc.

        // Example 1: If in Stable and duration met, maybe transition to Volatile or Restricted based on TVL
        if (oldState == VaultState.Stable) {
             if (block.timestamp >= lastStateTransitionTime + vaultStateParameters[VaultState.Stable].minDuration) {
                uint256 currentETH_TVL = getTVL_ETH(); // Need to implement getTVL_ETH accurately
                if (currentETH_TVL < vaultStateParameters[VaultState.Stable].minTVL_ETH) {
                    nextState = VaultState.Restricted;
                } else {
                    nextState = VaultState.Volatile; // Default transition after duration if TVL okay
                }
             }
        }
        // Example 2: If in Volatile and duration met, requires randomness check
        else if (oldState == VaultState.Volatile) {
            if (block.timestamp >= lastStateTransitionTime + vaultStateParameters[VaultState.Volatile].minDuration) {
                 if (vaultStateParameters[VaultState.Volatile].requiresRandomness) {
                     // Request randomness. Transition happens in fulfillRandomWords.
                     if (s_requestId == 0 || s_randomWords.length == 0 || s_randomWords[0] == 0) { // Only request if no pending or recent randomness
                          requestRandomStateInfluence();
                     }
                     // No state change yet, waiting for randomness
                 } else {
                      // Transition out of Volatile if no randomness required or randomness already processed
                     nextState = VaultState.Stable; // Example: Revert to Stable
                 }
            }
        }
         // Example 3: If in Restricted and duration met or TVL recovered
        else if (oldState == VaultState.Restricted) {
             if (block.timestamp >= lastStateTransitionTime + vaultStateParameters[VaultState.Restricted].minDuration) {
                  uint256 currentETH_TVL = getTVL_ETH();
                  if (currentETH_TVL >= vaultStateParameters[VaultState.Stable].minTVL_ETH) { // TVL recovered
                      nextState = VaultState.Stable;
                  }
             }
        }
         // Example 4: QuantumFlux - Highly unstable, short duration, requires randomness
        else if (oldState == VaultState.QuantumFlux) {
             if (block.timestamp >= lastStateTransitionTime + vaultStateParameters[VaultState.QuantumFlux].minDuration) {
                 if (vaultStateParameters[VaultState.QuantumFlux].requiresRandomness) {
                     if (s_requestId == 0 || s_randomWords.length == 0 || s_randomWords[0] == 0) {
                          requestRandomStateInfluence();
                     }
                 } else {
                     nextState = VaultState.Stable; // Default transition out of flux
                 }
             }
        }
        // Paused state requires manual unpause

        if (nextState != oldState && nextState != VaultState.Paused) { // Don't auto-transition out of Paused
            _transitionState(nextState, "Automatic check and transition");
        }
    }

    function manualStateTransition(VaultState newState) public onlyOwner {
        require(newState != VaultState.Paused, "Use pauseVault to pause");
         require(currentVaultState != VaultState.Paused, "Cannot manually transition while paused");
        require(newState != currentVaultState, "Already in this state");
        _transitionState(newState, "Manual owner transition");
    }

    // Internal function to handle the actual state change
    function _transitionState(VaultState newState, string memory reason) internal {
        VaultState oldState = currentVaultState;
        currentVaultState = newState;
        lastStateTransitionTime = block.timestamp;

        // Update last yield update time for all users/assets to freeze yield calculation in the old state
        // This is complex and gas-intensive for many users/assets. A simpler approach is to calculate pending yield
        // based on *start time* of deposit and yield *rates per state duration*.
        // For simplicity, let's skip iterating all users here and rely on `calculatePendingYield` logic.

        emit StateChanged(oldState, newState, reason);
    }


    // --- Parameter Setting Functions (Owner Only) ---

    function setVaultStateParameters(
        VaultState state,
        uint256 minDuration,
        uint256 minTVL_ETH,
        uint256 stateSpecificParam,
        uint256 yieldRatePerSecond,
        uint256 withdrawalFeeBps,
        bool withdrawalsEnabled,
        bool requiresRandomness
    ) public onlyOwner {
        vaultStateParameters[state] = StateParameters({
            minDuration: minDuration,
            minTVL_ETH: minTVL_ETH,
            stateSpecificParam: stateSpecificParam,
            yieldRatePerSecond: yieldRatePerSecond,
            withdrawalFeeBps: withdrawalFeeBps,
            withdrawalsEnabled: withdrawalsEnabled,
            requiresRandomness: requiresRandomness
        });
        emit ParametersUpdated("VaultStateParameters");
    }

     function setWithdrawalFeeParameters(VaultState state, uint256 withdrawalFeeBps) public onlyOwner {
         vaultStateParameters[state].withdrawalFeeBps = withdrawalFeeBps;
         emit ParametersUpdated("WithdrawalFeeParameters");
     }

     function setYieldParameters(VaultState state, uint256 yieldRatePerSecond) public onlyOwner {
         vaultStateParameters[state].yieldRatePerSecond = yieldRatePerSecond;
         emit ParametersUpdated("YieldParameters");
     }

    function setAllowedERC20Token(IERC20 token, bool allowed) public onlyOwner {
        allowedERC20Tokens[address(token)] = allowed;
        emit AllowedTokenStatusChanged(address(token), allowed);
    }

    function setAllowedERC721Collection(IERC721 token, bool allowed) public onlyOwner {
        allowedERC721Collections[address(token)] = allowed;
        emit AllowedTokenStatusChanged(address(token), allowed);
    }

    // --- Simulated Yield Functions ---

    // Internal helper to calculate yield
    function _calculateYieldInternal(address user, address tokenAddress) internal view returns (uint256) {
         uint256 depositedAmount;
         if (tokenAddress == address(0)) {
             depositedAmount = userETHDeposits[user];
         } else {
             depositedAmount = userERC20Deposits[user][tokenAddress];
         }

         if (depositedAmount == 0) return 0;

         uint256 lastUpdateTime = lastYieldUpdateTime[user][tokenAddress];
         if (lastUpdateTime == 0) lastUpdateTime = block.timestamp; // Should not happen if deposit worked, but safety

         uint256 timePassed = block.timestamp - lastUpdateTime;
         // Simple yield calculation: amount * rate * time. Rate is per unit of token per second.
         // Need to adjust for decimals if token has decimals. Assuming 18 decimals for ETH/ERC20 for simplicity.
         // Rate is per 1e18 unit of token.
         uint256 yieldRate = vaultStateParameters[currentVaultState].yieldRatePerSecond;

         // Avoid overflow: (amount / 1e18) * rate * time or (amount * rate / 1e18) * time
         // Let's assume yieldRatePerSecond is rate per 1e18 unit, multiplied by 1e18 again to keep decimals in result
         // e.g., rate is 1e12 means 0.000001 ETH per second per ETH
         // Yield = amount * yieldRate * timePassed / 1e18
         // To prevent overflow and maintain precision:
         uint256 yield = (depositedAmount * yieldRate) / (1e18) * timePassed; // Simplified

         return yield;
    }


    function calculatePendingYield(address user, address tokenAddress) public view returns (uint256) {
        // Re-calculate based on time elapsed *since last claim/deposit* and *current* yield rate.
        // A more accurate model would track yield per state, but this is simpler.
        // This implementation is a *prediction* based on current state rate.
        // A true cumulative yield requires storing yield earned in previous states.
        // Let's simplify and just calculate based on time since last update and CURRENT rate.
         return _calculateYieldInternal(user, tokenAddress);
    }


    function claimYield(address tokenAddress) public nonReentrant whenNotPaused {
        require(tokenAddress == address(0) || allowedERC20Tokens[tokenAddress], "Token not allowed");

        uint256 yieldAmount = _calculateYieldInternal(msg.sender, tokenAddress);
        require(yieldAmount > 0, "No yield to claim");

         // Internal function handles the transfer
        _claimYield(msg.sender, tokenAddress);
    }

    // Internal helper for claiming yield
    function _claimYield(address user, address tokenAddress) internal {
        uint256 yieldAmount = _calculateYieldInternal(user, tokenAddress);
        if (yieldAmount == 0) return;

        lastYieldUpdateTime[user][tokenAddress] = block.timestamp; // Reset timer

        if (tokenAddress == address(0)) {
             // Send ETH yield
             (bool success, ) = payable(user).call{value: yieldAmount}("");
             require(success, "ETH yield transfer failed");
             emit YieldClaimed(user, address(0), yieldAmount);
        } else {
            // Send ERC20 yield
            IERC20 token = IERC20(tokenAddress);
            // Need to ensure the contract *has* enough of this token to pay yield.
            // In a real system, yield might come from fees, external investments, or newly minted tokens.
            // Here, we assume the contract magically has the tokens or they come from fees.
            // Let's assume fees are auto-converted or topped up, or contract is pre-funded.
            // We'll add a safety check that the contract balance is sufficient.
            require(token.balanceOf(address(this)) >= yieldAmount, "Insufficient contract balance for yield");
            require(token.transfer(user, yieldAmount), "ERC20 yield transfer failed");
             emit YieldClaimed(user, tokenAddress, yieldAmount);
        }
    }


    // --- Query Functions ---

    function getCurrentVaultState() public view returns (VaultState) {
        return currentVaultState;
    }

    function getUserTotalDepositedETH(address user) public view returns (uint256) {
        return userETHDeposits[user];
    }

    function getUserTotalDepositedERC20(address user, IERC20 token) public view returns (uint256) {
        return userERC20Deposits[user][address(token)];
    }

    function getUserDepositedNFTs(address user, IERC721 token) public view returns (uint256[] memory) {
        return userERC721Deposits[user][address(token)];
    }

    // Note: Accurate TVL calculation requires iterating through allowed tokens, which is gas-intensive for many tokens.
    // These functions provide partial TVL. A full TVL would be off-chain or require a helper contract/view function with limits.
    function getTVL_ETH() public view returns (uint256) {
        // Simply returns the contract's balance. Assumes only deposited ETH is held.
        // In a real contract with fees, this might be higher than sum of user deposits.
        return address(this).balance;
    }

    function getTVLByToken(IERC20 token) public view returns (uint256) {
         // Returns the contract's balance of a specific token.
         // Assumes only deposited tokens (plus fees) are held.
        require(allowedERC20Tokens[address(token)], "ERC20 token not allowed");
        return token.balanceOf(address(this));
    }

    function getNFTCountInVault(IERC721 token) public view returns (uint256) {
         // Returns the contract's balance of NFTs for a specific collection.
        require(allowedERC721Collections[address(token)], "ERC721 collection not allowed");
        return token.balanceOf(address(this));
    }

    function predictWithdrawalAmount(address user, address tokenAddress) public view returns (uint256 amountNet, uint256 fee) {
        StateParameters memory params = vaultStateParameters[currentVaultState];
        if (!params.withdrawalsEnabled) {
            return (0, 0);
        }

        uint256 depositedAmount;
        if (tokenAddress == address(0)) {
            depositedAmount = userETHDeposits[user];
        } else {
            depositedAmount = userERC20Deposits[user][tokenAddress];
        }

        if (depositedAmount == 0) return (0, 0);

        // Calculate max possible withdrawal based on deposit and state params (if any, e.g., percentage limit)
        uint256 maxWithdraw = depositedAmount;
        // Example limit based on state parameter (e.g., max withdrawal is stateSpecificParam % of balance)
        // if (params.stateSpecificParam > 0 && params.stateSpecificParam < 10000) { // Assuming 10000 is 100%
        //    maxWithdraw = (depositedAmount * params.stateSpecificParam) / 10000;
        // }

        return _calculateFeeAndAmountNet(tokenAddress, maxWithdraw);
    }

    // --- Admin/Configuration Functions ---

    function pauseVault(uint256 reasonCode) public onlyOwner {
        require(currentVaultState != VaultState.Paused, "Vault already paused");
        _transitionState(VaultState.Paused, "Manual pause");
        pauseReasonCode = reasonCode;
        emit VaultPaused(msg.sender, reasonCode);
    }

    function unpauseVault() public onlyOwner {
        require(currentVaultState == VaultState.Paused, "Vault is not paused");
        // Transition to Stable or previous state? Let's transition to Stable for simplicity.
        _transitionState(VaultState.Stable, "Manual unpause");
        pauseReasonCode = 0;
        emit VaultUnpaused(msg.sender);
    }

     // --- Delegation Functions ---

    function delegateWithdrawalPermission(address delegatee, address tokenAddress, uint256 amountOrTokenId, bool isNFT) public nonReentrant whenNotPaused {
        require(delegatee != address(0), "Invalid delegatee address");
        require(delegatee != msg.sender, "Cannot delegate to self");
        require(tokenAddress == address(0) || allowedERC20Tokens[tokenAddress] || allowedERC721Collections[tokenAddress], "Token not allowed");

        // Verify the user actually has the asset deposited
        if (isNFT) {
             uint256[] storage userNFTs = userERC721Deposits[msg.sender][tokenAddress];
             bool found = false;
             for (uint i = 0; i < userNFTs.length; i++) {
                 if (userNFTs[i] == amountOrTokenId) {
                     found = true;
                     break;
                 }
             }
             require(found, "Delegator does not have this NFT deposited");
        } else {
            if (tokenAddress == address(0)) {
                require(userETHDeposits[msg.sender] >= amountOrTokenId, "Delegator does not have sufficient ETH deposited");
            } else {
                require(userERC20Deposits[msg.sender][tokenAddress] >= amountOrTokenId, "Delegator does not have sufficient ERC20 deposited");
            }
             require(amountOrTokenId > 0, "Cannot delegate 0 amount");
        }

        // Check if this specific delegation slot is unused
        require(!delegatedWithdrawalUsed[msg.sender][tokenAddress][amountOrTokenId][delegatee], "Permission already used or active");

        // Mark the slot as available (value is false by default, but let's be explicit if needed for clarity, though the require above handles it)
        // We don't *set* anything here, just ensure it's currently false. The `useDelegatedWithdrawal` function will set it to true.

        emit WithdrawalPermissionDelegated(msg.sender, delegatee, tokenAddress, amountOrTokenId, isNFT);
         // Note: This function doesn't change state, it just emits the intent. The `useDelegatedWithdrawal` function performs the action.
    }


    function useDelegatedWithdrawal(address delegator, address delegatee, address tokenAddress, uint256 amountOrTokenId, bool isNFT) public nonReentrant whenNotPaused {
        require(msg.sender == delegatee, "Only the delegatee can use this permission");
        require(delegator != address(0), "Invalid delegator address");
         require(tokenAddress == address(0) || allowedERC20Tokens[tokenAddress] || allowedERC721Collections[tokenAddress], "Token not allowed");

        // Check if this specific delegation exists and hasn't been used
        // The way `delegatedWithdrawalUsed` is structured (mapping to bool), checking if it's `false` indicates it's unused/available for this combination.
        require(!delegatedWithdrawalUsed[delegator][tokenAddress][amountOrTokenId][delegatee], "Delegation permission is invalid or already used");

        // Mark the delegation as used *before* the transfer
        delegatedWithdrawalUsed[delegator][tokenAddress][amountOrTokenId][delegatee] = true;

        StateParameters memory params = vaultStateParameters[currentVaultState];
        // Delegate withdrawals can potentially bypass standard withdrawal state checks, or have different rules.
        // For this example, let's assume they *do* respect the `withdrawalsEnabled` flag, but might ignore state-specific limits
        // or fees if the delegation parameters were set differently (not implemented here for complexity).
        require(params.withdrawalsEnabled, "Withdrawals disabled in current state");


        // Perform the withdrawal on behalf of the delegator
        if (isNFT) {
             // Verify delegator still owns the NFT in the vault
             uint256[] storage delegatorNFTs = userERC721Deposits[delegator][tokenAddress];
             bool found = false;
             uint256 index = type(uint256).max;
             for (uint i = 0; i < delegatorNFTs.length; i++) {
                 if (delegatorNFTs[i] == amountOrTokenId) {
                     found = true;
                     index = i;
                     break;
                 }
             }
             require(found, "Delegator no longer has this NFT deposited");

             // Remove NFT from delegator's list
             delegatorNFTs[index] = delegatorNFTs[delegatorNFTs.length - 1];
             delegatorNFTs.pop();

             // Transfer NFT to the delegatee (or potentially another address specified in delegation?)
             // Let's transfer to the delegatee for simplicity.
             IERC721 token = IERC721(tokenAddress);
             token.transferFrom(address(this), delegatee, amountOrTokenId);

             emit DelegatedWithdrawalUsed(delegator, delegatee, tokenAddress, amountOrTokenId, true);

        } else {
            // Fungible token withdrawal
            uint256 amountToWithdraw = amountOrTokenId;
             if (tokenAddress == address(0)) {
                 require(userETHDeposits[delegator] >= amountToWithdraw, "Delegator does not have sufficient ETH deposited");
                 userETHDeposits[delegator] -= amountToWithdraw;
                 // Fees? Let's assume delegated withdrawals incur no fees for simplicity, or fees are handled differently.
                 // If fees apply, they would be deducted from the amount withdrawn.
                 (bool success, ) = payable(delegatee).call{value: amountToWithdraw}(""); // Transfer to delegatee
                 require(success, "Delegated ETH transfer failed");
                  emit DelegatedWithdrawalUsed(delegator, delegatee, address(0), amountToWithdraw, false);
             } else {
                IERC20 token = IERC20(tokenAddress);
                 require(userERC20Deposits[delegator][tokenAddress] >= amountToWithdraw, "Delegator does not have sufficient ERC20 deposited");
                 userERC20Deposits[delegator][tokenAddress] -= amountToWithdraw;
                 require(token.transfer(delegatee, amountToWithdraw), "Delegated ERC20 transfer failed"); // Transfer to delegatee
                 emit DelegatedWithdrawalUsed(delegator, delegatee, tokenAddress, amountToWithdraw, false);
             }
        }
    }

    // --- Advanced/Complex Functions ---

    // Integrates Chainlink VRF to influence state transitions or other logic
    function requestRandomStateInfluence() public nonReentrant {
        require(vaultStateParameters[currentVaultState].requiresRandomness, "Current state does not require randomness for transition");
        require(COORDINATOR != VRFCoordinatorV2Interface(address(0)), "VRF Coordinator not set");
        // Ensure there isn't a pending request already
        require(s_requestId == 0, "Randomness request already pending");

        // Will revert if subscription is not funded or other VRF issues
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_lastRequester = msg.sender; // Store who triggered the request
        s_randomWords = new uint256[](0); // Clear previous random words
        emit RandomnessRequested(s_requestId, msg.sender);
    }

    // Chainlink VRF Callback function
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        require(requestId == s_requestId, "Request ID mismatch");
        s_randomWords = randomWords;
        s_requestId = 0; // Reset request ID

        emit RandomnessFulfilled(requestId, randomWords);

        // --- Logic triggered by randomness ---
        // The randomness can be used to influence the next state or other parameters.
        // Example: Use the first random word to determine the next state if requirements are met.
        if (s_randomWords.length > 0) {
             uint256 randomResult = s_randomWords[0];

             VaultState oldState = currentVaultState;
             VaultState nextState = oldState;

             // Example Logic:
             if (oldState == VaultState.Volatile) {
                 // 50/50 chance to go Stable or QuantumFlux from Volatile if random
                 if (randomResult % 2 == 0) {
                     nextState = VaultState.Stable;
                 } else {
                     nextState = VaultState.QuantumFlux;
                 }
             } else if (oldState == VaultState.QuantumFlux) {
                  // Randomly choose between Stable or Volatile from QuantumFlux
                 if (randomResult % 3 == 0) { // ~33% chance to return Stable
                     nextState = VaultState.Stable;
                 } else { // ~66% chance to go Volatile
                     nextState = VaultState.Volatile;
                 }
             }
             // Add more state transition logic based on randomness if needed

             if (nextState != oldState) {
                 _transitionState(nextState, "Transition triggered by VRF randomness");
             }

             // Randomness could also influence other parameters dynamically here (e.g., fee factors, yield multipliers)
             // This is complex and needs careful design. For now, focusing on state transition.
        }
         s_lastRequester = address(0); // Reset requester
    }


    function triggerCatalystEvent() public nonReentrant {
        // This function represents a complex internal trigger.
        // It could be called by anyone (like a keeper), or restricted.
        // Its logic should combine multiple factors to potentially cause significant effects.
        // Example: Check if specific conditions are met AND the current state allows a 'Catalyst' action.
        // Effects could include:
        // - Forcing a state change under specific, rare conditions.
        // - Triggering a special yield distribution.
        // - Adjusting specific parameters temporarily.
        // - Interacting with an external 'Policy Engine' contract.

        // Example Conditions:
        // 1. Vault is not paused.
        // 2. Current state is either Volatile or QuantumFlux (states where flux is expected).
        // 3. Enough time has passed since the last Catalyst event (not tracked here, but could be).
        // 4. (Optional) A recent random word result is available and meets a criteria.
        // 5. (Optional) TVL is above/below a certain threshold.

        require(currentVaultState != VaultState.Paused, "Cannot trigger Catalyst while paused");
        require(currentVaultState == VaultState.Volatile || currentVaultState == VaultState.QuantumFlux, "Catalyst requires a volatile or flux state");
        // Add more complex requirements here... e.g., based on getTVL_ETH()

        // If randomness is pending, wait for it. If available, use it.
        uint256 randomInfluencer = s_randomWords.length > 0 ? s_randomWords[0] : 0;

        // Example Effect: If TVL is very high in QuantumFlux and random word is even, force transition to Stable.
        if (currentVaultState == VaultState.QuantumFlux && getTVL_ETH() > vaultStateParameters[VaultState.Stable].minTVL_ETH && randomInfluencer != 0 && randomInfluencer % 2 == 0) {
             _transitionState(VaultState.Stable, "Catalyst event forced transition");
        }
        // Add other complex, state-dependent effects here...

        emit CatalystEventTriggered(msg.sender, currentVaultState, randomInfluencer);
    }

    // --- Emergency/Cleanup Functions ---

     // Allows owner to recover tokens accidentally sent to the contract, *excluding* allowed vault tokens
     function sweepStuckTokens(IERC20 token, uint256 amount) public onlyOwner nonReentrant {
         require(!allowedERC20Tokens[address(token)], "Cannot sweep allowed vault tokens");
         require(amount > 0, "Amount must be greater than 0");
         require(token.balanceOf(address(this)) >= amount, "Insufficient token balance in contract");

         require(token.transfer(owner(), amount), "Sweep failed");
         emit StuckTokensSwept(address(token), amount, owner());
     }

     // Emergency function to withdraw all assets by owner - use with extreme caution!
     // This bypasses state checks and is intended for disaster recovery.
     // Omitted for code length/complexity, but a real contract might have this.
     // function emergencyWithdrawAll() public onlyOwner { ... }

    // --- Getter for VRF parameters (Optional, helpful for frontend/monitoring) ---
     function getChainlinkVRFConfig() public view returns (address coordinator, uint64 subId, bytes32 kh, uint32 cgl, uint16 rc, uint32 nw) {
         return (address(COORDINATOR), s_subscriptionId, keyHash, callbackGasLimit, requestConfirmations, numWords);
     }

     function getRandomRequestStatus() public view returns (uint256 requestId, address requester, uint256 randomWordCount) {
        return (s_requestId, s_lastRequester, s_randomWords.length);
     }
}
```