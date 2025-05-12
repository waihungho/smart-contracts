Okay, here is a Solidity smart contract called `QuantumVault`.

This contract aims to be a creative exploration of a novel concept inspired by quantum mechanics – managing deposited assets (ERC20 tokens) within different "Quantum States" that influence their yield, availability, and interactions with other deposits. It incorporates probabilistic transitions, "entanglement" between deposits, and requires a special "Catalyst" NFT (ERC721) to access certain high-risk/high-reward states.

**Disclaimer:** The "quantum" aspect is a metaphorical inspiration for the state machine, probabilistic outcomes, and entanglement concept. On-chain randomness is inherently insecure for high-value applications. This contract uses a simple pseudo-randomness for demonstration purposes. A real-world application would require a secure VRF (like Chainlink VRF). The yield/decay calculations are also simplified simulations.

---

**Outline:**

1.  **Contract Definition:** SPDX License, Pragma, Imports (ERC20, ERC721, Ownable).
2.  **Errors:** Custom error definitions for clearer error handling.
3.  **Events:** Events for key actions (Deposit, Withdraw, StateChange, Entangle, ResolveEntanglement, BreakEntanglement, ParametersUpdated).
4.  **Enums:** `QuantumState` enum defining the possible states of a deposit.
5.  **Structs:**
    *   `Deposit`: Stores details for each individual deposit.
    *   `QuantumParameters`: Stores global parameters influencing state transitions, yield, and decay.
    *   `AccruedEffect`: Stores the yield/decay applied to a deposit over time.
6.  **State Variables:** Mappings for deposits, user deposit lists, deposit counter, token addresses, quantum parameters, pause status, admin address.
7.  **Modifiers:** `whenNotPaused`, `onlyOwner`, `depositExists`, `isDepositOwner`, `isDepositInState`, `isDepositEntangledWith`, `isDepositNotLocked`, `canInitiateVolatile`, `canInitiateEntanglement`, `canResolveEntanglement`, `canCheckAndTransitionState`.
8.  **Constructor:** Sets up the contract with the supported tokens and initial parameters.
9.  **Core Vault Functions:**
    *   `deposit`: Users deposit the supported ERC20 token for a specific duration.
    *   `withdraw`: Users withdraw their deposited tokens after the lock period and state resolution.
10. **Quantum State Management Functions:**
    *   `initiateVolatile`: Allows user to transition a `Stable` deposit to `Volatile` (requires Catalyst NFT).
    *   `initiateEntanglement`: Allows user to entangle two of their `Stable` deposits.
    *   `resolveEntanglement`: Resolves the entangled state of two deposits probabilistically.
    *   `breakEntanglement`: Allows user to break entanglement prematurely (may have implications).
    *   `observeAndTransition`: A general function callable by anyone to check if a deposit's state should transition based on time or conditions.
    *   `_transitionState`: Internal function to handle the logic of state transitions.
11. **Yield/Decay & Effect Functions:**
    *   `calculateAccruedEffect`: View function to calculate potential yield/decay based on current state and time.
    *   `_applyStateEffect`: Internal function to calculate and apply the yield/decay gained/lost during the time spent in the *previous* state.
12. **Admin Functions (Only Owner):**
    *   `setQuantumParameters`: Update the global parameters.
    *   `setCatalystToken`: Update the required ERC721 token address.
    *   `pause`: Pause contract interactions.
    *   `unpause`: Unpause contract interactions.
    *   `withdrawFees`: Withdraw accumulated yield/decay collected by the contract (simplification: contract keeps any net gain from decays).
13. **View Functions (Querying State):** Numerous functions to inspect deposits, states, parameters, and user information.

---

**Function Summary (26+ Functions):**

1.  `constructor(address _supportedToken, address _catalystToken, QuantumParameters memory _initialParams)`: Initializes the contract.
2.  `deposit(uint256 _amount, uint256 _lockDuration)`: Deposit tokens into the vault.
3.  `withdraw(uint256 _depositId)`: Withdraw tokens from a deposit.
4.  `initiateVolatile(uint256 _depositId)`: Attempt to make a deposit Volatile (requires Catalyst NFT).
5.  `initiateEntanglement(uint256 _depositId1, uint256 _depositId2)`: Entangle two owned deposits.
6.  `resolveEntanglement(uint256 _depositId)`: Resolve an entangled pair of deposits.
7.  `breakEntanglement(uint256 _depositId)`: Break an entangled state.
8.  `observeAndTransition(uint256 _depositId)`: Check and potentially transition a deposit's state.
9.  `setQuantumParameters(QuantumParameters memory _newParams)`: Admin: Update quantum parameters.
10. `setCatalystToken(address _catalystToken)`: Admin: Update catalyst token address.
11. `pause()`: Admin: Pause the contract.
12. `unpause()`: Admin: Unpause the contract.
13. `withdrawFees()`: Admin: Withdraw net yield/decay held by the contract.
14. `getDepositInfo(uint256 _depositId)`: View: Get detailed information about a deposit.
15. `getUserDeposits(address _user)`: View: Get the list of deposit IDs for a user.
16. `getQuantumParameters()`: View: Get the current quantum parameters.
17. `getCatalystToken()`: View: Get the catalyst token address.
18. `getDepositState(uint256 _depositId)`: View: Get the current state of a deposit.
19. `getDepositLockEndTime(uint256 _depositId)`: View: Get the lock end time.
20. `getEntangledDepositId(uint256 _depositId)`: View: Get the ID of the deposit entangled with this one.
21. `isDepositLocked(uint256 _depositId)`: View: Check if a deposit is locked.
22. `isDepositEntangled(uint256 _depositId)`: View: Check if a deposit is entangled.
23. `isDepositVolatile(uint256 _depositId)`: View: Check if a deposit is Volatile.
24. `isDepositStable(uint256 _depositId)`: View: Check if a deposit is Stable.
25. `isDepositDecohering(uint256 _depositId)`: View: Check if a deposit is Decohering.
26. `calculateAccruedEffect(uint256 _depositId)`: View: Calculate potential accrued effect since last state change.
27. `canInitiateVolatile(uint256 _depositId)`: View: Check if a deposit can initiate Volatile state.
28. `canInitiateEntanglement(uint256 _depositId1, uint256 _depositId2)`: View: Check if two deposits can be entangled.
29. `canResolveEntanglement(uint256 _depositId)`: View: Check if an entangled deposit can be resolved.
30. `canCheckAndTransitionState(uint256 _depositId)`: View: Check if a deposit's state can potentially transition now.
31. `getTotalDeposits()`: View: Get the total number of deposits created.
32. `getContractTokenBalance()`: View: Get the balance of the supported token held by the contract.
33. `getDepositLastStateChangeTime(uint256 _depositId)`: View: Get the time the deposit last changed state.
34. `getDepositAmount(uint256 _depositId)`: View: Get the current amount of a deposit.

(Note: This list already exceeds 20 functions, covering the core logic, admin tasks, and various ways to query the contract state).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol"; // To potentially hold catalyst NFTs

// Outline:
// 1. Contract Definition: SPDX License, Pragma, Imports.
// 2. Errors: Custom error definitions.
// 3. Events: Events for key actions.
// 4. Enums: QuantumState definition.
// 5. Structs: Deposit, QuantumParameters, AccruedEffect.
// 6. State Variables: Mappings, counters, addresses, params, pause status.
// 7. Modifiers: whenNotPaused, onlyOwner, depositExists, etc.
// 8. Constructor: Initialize tokens and parameters.
// 9. Core Vault Functions: deposit, withdraw.
// 10. Quantum State Management Functions: initiateVolatile, initiateEntanglement, resolveEntanglement, breakEntanglement, observeAndTransition, _transitionState (internal).
// 11. Yield/Decay & Effect Functions: calculateAccruedEffect (view), _applyStateEffect (internal).
// 12. Admin Functions: setQuantumParameters, setCatalystToken, pause, unpause, withdrawFees.
// 13. View Functions: getDepositInfo, getUserDeposits, getQuantumParameters, etc.

// Function Summary:
// 1. constructor: Initializes the contract.
// 2. deposit: Deposit tokens into the vault.
// 3. withdraw: Withdraw tokens from a deposit.
// 4. initiateVolatile: Attempt to make a deposit Volatile (requires Catalyst NFT).
// 5. initiateEntanglement: Entangle two owned deposits.
// 6. resolveEntanglement: Resolve an entangled pair of deposits.
// 7. breakEntanglement: Break an entangled state.
// 8. observeAndTransition: Check and potentially transition a deposit's state.
// 9. setQuantumParameters: Admin: Update quantum parameters.
// 10. setCatalystToken: Admin: Update catalyst token address.
// 11. pause: Admin: Pause the contract.
// 12. unpause: Admin: Unpause contract interactions.
// 13. withdrawFees: Admin: Withdraw net yield/decay.
// 14. getDepositInfo: View: Get detailed info about a deposit.
// 15. getUserDeposits: View: Get user's deposit IDs.
// 16. getQuantumParameters: View: Get parameters.
// 17. getCatalystToken: View: Get catalyst token address.
// 18. getDepositState: View: Get state.
// 19. getDepositLockEndTime: View: Get lock end time.
// 20. getEntangledDepositId: View: Get entangled ID.
// 21. isDepositLocked: View: Check lock status.
// 22. isDepositEntangled: View: Check entanglement status.
// 23. isDepositVolatile: View: Check volatile status.
// 24. isDepositStable: View: Check stable status.
// 25. isDepositDecohering: View: Check decohering status.
// 26. calculateAccruedEffect: View: Calculate potential accrued effect.
// 27. canInitiateVolatile: View: Check if volatile initiation is possible.
// 28. canInitiateEntanglement: View: Check if entanglement initiation is possible.
// 29. canResolveEntanglement: View: Check if entanglement resolution is possible.
// 30. canCheckAndTransitionState: View: Check if state transition check is possible.
// 31. getTotalDeposits: View: Get total number of deposits.
// 32. getContractTokenBalance: View: Get contract token balance.
// 33. getDepositLastStateChangeTime: View: Get last state change time.
// 34. getDepositAmount: View: Get deposit amount.


contract QuantumVault is Ownable, Pausable, ERC721Holder { // Inherit ERC721Holder if contract needs to receive NFTs

    using SafeMath for uint256;

    // --- Errors ---
    error DepositNotFound(uint256 depositId);
    error NotDepositOwner(uint256 depositId, address caller);
    error DepositLocked(uint256 depositId);
    error InvalidState(uint256 depositId, QuantumState requiredState, QuantumState currentState);
    error InvalidEntanglement(uint256 depositId1, uint256 depositId2);
    error DepositAlreadyEntangled(uint256 depositId);
    error DepositsMustBeOwnedBySameUser(uint256 depositId1, uint256 depositId2);
    error MinimumLockDuration(uint256 required, uint256 provided);
    error CannotWithdrawEntangled(uint256 depositId);
    error CannotWithdrawDecohering(uint256 depositId);
    error CatalystRequired(address catalystToken);
    error InsufficientCatalyst(address owner, address catalystToken, uint256 tokenId);
    error DepositNotReadyForTransition(uint256 depositId);
    error InvalidParameters();
    error ZeroAmount();

    // --- Events ---
    event DepositMade(uint256 indexed depositId, address indexed owner, uint256 amount, uint256 lockDuration, uint256 depositTime);
    event DepositWithdrawn(uint256 indexed depositId, address indexed owner, uint256 finalAmount);
    event StateChanged(uint256 indexed depositId, QuantumState oldState, QuantumState newState, uint256 timestamp);
    event Entangled(uint256 indexed depositId1, uint256 indexed depositId2);
    event ResolvedEntanglement(uint256 indexed depositId1, uint256 indexed depositId2, bool outcomePositive);
    event BrokenEntanglement(uint256 indexed depositId1, uint256 indexed depositId2);
    event QuantumParametersUpdated(QuantumParameters params);
    event CatalystTokenUpdated(address indexed catalystToken);
    event YieldApplied(uint256 indexed depositId, int256 effectAmount, AccruedEffectType effectType);

    // --- Enums ---
    enum QuantumState { Stable, Entangled, Volatile, Decohering }
    enum AccruedEffectType { Yield, Decay, VolatileGain, VolatileDecay, EntanglementGain, EntanglementDecay, EntanglementBreakPenalty }

    // --- Structs ---
    struct Deposit {
        address owner;
        uint256 amount; // Current amount after applying effects
        uint256 initialAmount; // Initial deposited amount
        uint256 depositTime;
        uint256 lockDuration;
        QuantumState currentState;
        uint256 lastStateChangeTime; // Timestamp when the state last changed
        uint256 entangledDepositId; // ID of the deposit this one is entangled with (0 if not entangled)
    }

    struct QuantumParameters {
        uint256 stableYieldRatePerSecond; // Per second rate (e.g., 1 wei per second per 1e18 token)
        uint256 volatileYieldRatePerSecond;
        uint256 entangledYieldRatePerSecond;
        uint256 decoheringYieldRatePerSecond; // Maybe 0 or base rate

        uint256 volatileDecayChance_10000; // Chance out of 10000 for decay on resolution
        uint256 volatileDecayAmount_10000; // Amount of decay as fraction of current amount (e.g., 500 for 5%)
        uint256 volatileGainAmount_10000; // Amount of gain as fraction of current amount (e.g., 1000 for 10%)

        uint256 entanglementResolutionChance_10000; // Chance out of 10000 for positive outcome on resolution
        uint256 entanglementGainAmount_10000;
        uint256 entanglementDecayAmount_10000;

        uint256 stableToDecoheringChance_10000; // Chance for a stable deposit to spontaneously decohere over time
        uint256 decoheringDuration; // Time required in Decohering state before returning to Stable

        uint256 stateTransitionMinimumTime; // Minimum time required in a state before observeAndTransition can trigger a change
        uint256 entanglementBreakPenalty_10000; // Penalty as fraction of amount for breaking entanglement

        uint256 minimumLockDuration;
    }

    // --- State Variables ---
    mapping(uint256 => Deposit) private s_deposits; // Deposit ID => Deposit struct
    mapping(address => uint256[]) private s_userDeposits; // User address => Array of deposit IDs
    uint256 private s_nextDepositId;
    IERC20 public immutable i_supportedToken;
    IERC721 public i_catalystToken;
    QuantumParameters public s_quantumParameters;
    bool private s_paused; // Redundant with Pausable, but kept for clarity with existing state

    // --- Modifiers ---
    modifier depositExists(uint256 _depositId) {
        if (s_deposits[_depositId].owner == address(0)) {
            revert DepositNotFound(_depositId);
        }
        _;
    }

    modifier isDepositOwner(uint256 _depositId) {
        if (s_deposits[_depositId].owner != msg.sender) {
            revert NotDepositOwner(_depositId, msg.sender);
        }
        _;
    }

    modifier isDepositNotLocked(uint256 _depositId) {
        if (isDepositLocked(_depositId)) {
            revert DepositLocked(_depositId);
        }
        _;
    }

    modifier isDepositInState(uint256 _depositId, QuantumState _requiredState) {
        if (s_deposits[_depositId].currentState != _requiredState) {
            revert InvalidState(_depositId, _requiredState, s_deposits[_depositId].currentState);
        }
        _;
    }

    modifier isDepositEntangledWith(uint256 _depositId1, uint256 _depositId2) {
        if (s_deposits[_depositId1].entangledDepositId != _depositId2 || s_deposits[_depositId2].entangledDepositId != _depositId1 || _depositId1 == _depositId2) {
            revert InvalidEntanglement(_depositId1, _depositId2);
        }
        _;
    }

    modifier canInitiateVolatile(uint256 _depositId) {
         // Check state, lock, and catalyst ownership
        if (s_deposits[_depositId].currentState != QuantumState.Stable) revert InvalidState(_depositId, QuantumState.Stable, s_deposits[_depositId].currentState);
        if (isDepositLocked(_depositId)) revert DepositLocked(_depositId);
        // Check Catalyst NFT ownership - requires ERC721 interface
        // We don't transfer the NFT, just check ownership for access
        address catalystAddr = address(i_catalystToken);
        if (catalystAddr == address(0)) revert CatalystRequired(catalystAddr);
        // This is a simplification: requires owning *any* catalyst NFT.
        // A more advanced version might require a specific one or consume it.
        uint256 userNFTBalance = i_catalystToken.balanceOf(msg.sender);
        if (userNFTBalance == 0) revert InsufficientCatalyst(msg.sender, catalystAddr, 0); // Token ID is 0 as we just check balance
        _;
    }

    modifier canInitiateEntanglement(uint256 _depositId1, uint256 _depositId2) {
        if (_depositId1 == _depositId2) revert InvalidEntanglement(_depositId1, _depositId2);
        depositExists(_depositId1);
        depositExists(_depositId2);
        isDepositOwner(_depositId1); // Implies msg.sender owns both due to next check
        if (s_deposits[_depositId2].owner != msg.sender) revert DepositsMustBeOwnedBySameUser(_depositId1, _depositId2);

        if (s_deposits[_depositId1].currentState != QuantumState.Stable) revert InvalidState(_depositId1, QuantumState.Stable, s_deposits[_depositId1].currentState);
        if (s_deposits[_depositId2].currentState != QuantumState.Stable) revert InvalidState(_depositId2, QuantumState.Stable, s_deposits[_depositId2].currentState);

        if (isDepositLocked(_depositId1) || isDepositLocked(_depositId2)) revert DepositLocked(isDepositLocked(_depositId1) ? _depositId1 : _depositId2);

        if (s_deposits[_depositId1].entangledDepositId != 0) revert DepositAlreadyEntangled(_depositId1);
        if (s_deposits[_depositId2].entangledDepositId != 0) revert DepositAlreadyEntangled(_depositId2);
        _;
    }

     modifier canResolveEntanglement(uint256 _depositId) {
        depositExists(_depositId);
        isDepositOwner(_depositId);
        isDepositInState(_depositId, QuantumState.Entangled);
        uint256 entangledId = s_deposits[_depositId].entangledDepositId;
        if (entangledId == 0 || s_deposits[entangledId].entangledDepositId != _depositId) revert InvalidEntanglement(_depositId, entangledId);
        // Check if minimum time in state has passed (optional, but adds complexity)
        // if (block.timestamp < s_deposits[_depositId].lastStateChangeTime + s_quantumParameters.stateTransitionMinimumTime) revert DepositNotReadyForTransition(_depositId);
        _;
    }

     modifier canCheckAndTransitionState(uint256 _depositId) {
        depositExists(_depositId);
        // Allow anyone to trigger the check
        // isDepositOwner(_depositId); // Maybe restrict to owner? Let's allow anyone to "observe"

        // Only certain states transition automatically based on time
        QuantumState currentState = s_deposits[_depositId].currentState;
        if (currentState != QuantumState.Volatile && currentState != QuantumState.Decohering && currentState != QuantumState.Stable) {
             revert DepositNotReadyForTransition(_depositId); // Only these states have time/probabilistic transitions via this function
        }

        // Require minimum time in state before checking (prevents spam)
        if (block.timestamp < s_deposits[_depositId].lastStateChangeTime + s_quantumParameters.stateTransitionMinimumTime) {
             revert DepositNotReadyForTransition(_depositId);
        }
        _;
    }

    // --- Constructor ---
    constructor(address _supportedToken, address _catalystToken, QuantumParameters memory _initialParams)
        Ownable(msg.sender)
        Pausable()
    {
        if (_supportedToken == address(0)) revert InvalidParameters();
        i_supportedToken = IERC20(_supportedToken);
        i_catalystToken = IERC721(_catalystToken); // Can be address(0) initially if no catalyst required
        s_nextDepositId = 1;

        // Basic validation for initial parameters
        if (_initialParams.stableYieldRatePerSecond > 0 && _initialParams.stableYieldRatePerSecond > _initialParams.volatileYieldRatePerSecond) revert InvalidParameters(); // Volatile should offer higher potential
        if (_initialParams.volatileDecayChance_10000 > 10000 || _initialParams.volatileGainAmount_10000 > 10000 || _initialParams.volatileDecayAmount_10000 > 10000) revert InvalidParameters();
        if (_initialParams.entanglementResolutionChance_10000 > 10000 || _initialParams.entanglementGainAmount_10000 > 10000 || _initialParams.entanglementDecayAmount_10000 > 10000) revert InvalidParameters();
         if (_initialParams.stableToDecoheringChance_10000 > 10000) revert InvalidParameters();
        if (_initialParams.decoheringDuration == 0) revert InvalidParameters(); // Must take some time to decohere
        if (_initialParams.stateTransitionMinimumTime == 0) revert InvalidParameters(); // Prevent spam checks
        if (_initialParams.minimumLockDuration == 0) revert InvalidParameters();

        s_quantumParameters = _initialParams;

        emit QuantumParametersUpdated(s_quantumParameters);
        emit CatalystTokenUpdated(_catalystToken);
    }

    // --- Core Vault Functions ---

    /// @notice Deposits tokens into the vault in the Stable state.
    /// @param _amount The amount of tokens to deposit.
    /// @param _lockDuration The duration the deposit will be locked (in seconds).
    function deposit(uint256 _amount, uint256 _lockDuration) public payable whenNotPaused {
        if (_amount == 0) revert ZeroAmount();
        if (_lockDuration < s_quantumParameters.minimumLockDuration) revert MinimumLockDuration(s_quantumParameters.minimumLockDuration, _lockDuration);

        uint256 depositId = s_nextDepositId++;
        s_deposits[depositId] = Deposit({
            owner: msg.sender,
            amount: _amount,
            initialAmount: _amount,
            depositTime: block.timestamp,
            lockDuration: _lockDuration,
            currentState: QuantumState.Stable,
            lastStateChangeTime: block.timestamp,
            entangledDepositId: 0
        });

        s_userDeposits[msg.sender].push(depositId);

        bool success = i_supportedToken.transferFrom(msg.sender, address(this), _amount);
        require(success, "Token transfer failed");

        emit DepositMade(depositId, msg.sender, _amount, _lockDuration, block.timestamp);
        emit StateChanged(depositId, QuantumState.Stable, QuantumState.Stable, block.timestamp); // State starts as Stable
    }

    /// @notice Withdraws tokens from a deposit after the lock period has ended and the deposit is not in Entangled or Decohering state.
    /// Yield/decay from the last state is applied before withdrawal.
    /// @param _depositId The ID of the deposit to withdraw.
    function withdraw(uint256 _depositId) public payable whenNotPaused depositExists(_depositId) isDepositOwner(_depositId) isDepositNotLocked(_depositId) {
        Deposit storage deposit = s_deposits[_depositId];

        // Cannot withdraw if entangled or decohering - must resolve first
        if (deposit.currentState == QuantumState.Entangled) revert CannotWithdrawEntangled(_depositId);
        if (deposit.currentState == QuantumState.Decohering) revert CannotWithdrawDecohering(_depositId);

        // Apply yield/decay for the final duration in the current state (must be Stable or Volatile resolved to Stable)
        // Note: Volatile state effects (gain/decay) are applied on resolution, not here.
        // This applies the per-second yield for the duration in the final state.
        _applyStateEffect(_depositId, deposit.currentState, block.timestamp - deposit.lastStateChangeTime);

        uint256 finalAmount = deposit.amount;
        address owner = deposit.owner; // Store before deleting deposit data

        // Clean up deposit data
        _removeDeposit(_depositId);

        bool success = i_supportedToken.transfer(owner, finalAmount);
        require(success, "Token transfer failed");

        emit DepositWithdrawn(_depositId, owner, finalAmount);
    }

    // --- Quantum State Management Functions ---

    /// @notice Attempts to initiate the Volatile state for a Stable deposit. Requires owning a Catalyst NFT.
    /// @param _depositId The ID of the deposit to make Volatile.
    function initiateVolatile(uint256 _depositId) public payable whenNotPaused depositExists(_depositId) isDepositOwner(_depositId) canInitiateVolatile(_depositId) {
        Deposit storage deposit = s_deposits[_depositId];
        QuantumState oldState = deposit.currentState;

        // Apply effect from the duration in the previous state (Stable)
        _applyStateEffect(_depositId, oldState, block.timestamp - deposit.lastStateChangeTime);

        deposit.currentState = QuantumState.Volatile;
        deposit.lastStateChangeTime = block.timestamp;

        emit StateChanged(_depositId, oldState, QuantumState.Volatile, block.timestamp);
    }

    /// @notice Initiates entanglement between two Stable deposits owned by the caller.
    /// @param _depositId1 The ID of the first deposit.
    /// @param _depositId2 The ID of the second deposit.
    function initiateEntanglement(uint256 _depositId1, uint256 _depositId2) public payable whenNotPaused canInitiateEntanglement(_depositId1, _depositId2) {
        Deposit storage deposit1 = s_deposits[_depositId1];
        Deposit storage deposit2 = s_deposits[_depositId2];

        QuantumState oldState1 = deposit1.currentState;
        QuantumState oldState2 = deposit2.currentState;

        // Apply effects for time spent in Stable state before entanglement
        _applyStateEffect(_depositId1, oldState1, block.timestamp - deposit1.lastStateChangeTime);
        _applyStateEffect(_depositId2, oldState2, block.timestamp - deposit2.lastStateChangeTime);

        deposit1.currentState = QuantumState.Entangled;
        deposit2.currentState = QuantumState.Entangled;
        deposit1.lastStateChangeTime = block.timestamp;
        deposit2.lastStateChangeTime = block.timestamp;
        deposit1.entangledDepositId = _depositId2;
        deposit2.entangledDepositId = _depositId1;

        emit StateChanged(_depositId1, oldState1, QuantumState.Entangled, block.timestamp);
        emit StateChanged(_depositId2, oldState2, QuantumState.Entangled, block.timestamp);
        emit Entangled(_depositId1, _depositId2);
    }

    /// @notice Resolves the entangled state of two deposits. The outcome is probabilistic and affects both deposits.
    /// Can be called by the owner of either entangled deposit.
    /// @param _depositId The ID of one of the entangled deposits.
    function resolveEntanglement(uint256 _depositId) public payable whenNotPaused canResolveEntanglement(_depositId) {
        uint256 depositId1 = _depositId;
        uint256 depositId2 = s_deposits[depositId1].entangledDepositId;

        Deposit storage deposit1 = s_deposits[depositId1];
        Deposit storage deposit2 = s_deposits[depositId2];

        // Apply yield for time spent in Entangled state
        uint256 duration = block.timestamp - deposit1.lastStateChangeTime; // Duration is the same for both
        _applyStateEffect(depositId1, QuantumState.Entangled, duration);
        _applyStateEffect(depositId2, QuantumState.Entangled, duration);

        // Probabilistic outcome for the pair
        uint256 randomValue = _generatePseudoRandom(depositId1 + depositId2 + block.timestamp);
        bool outcomePositive = (randomValue % 10001) < s_quantumParameters.entanglementResolutionChance_10000;

        if (outcomePositive) {
            // Apply gain
            int256 gainAmount1 = int256(deposit1.amount.mul(s_quantumParameters.entanglementGainAmount_10000).div(10000));
            int256 gainAmount2 = int256(deposit2.amount.mul(s_quantumParameters.entanglementGainAmount_10000).div(10000));
            deposit1.amount = deposit1.amount.add(uint256(gainAmount1));
            deposit2.amount = deposit2.amount.add(uint256(gainAmount2));
             emit YieldApplied(depositId1, gainAmount1, AccruedEffectType.EntanglementGain);
             emit YieldApplied(depositId2, gainAmount2, AccruedEffectType.EntanglementGain);
        } else {
            // Apply decay
            int256 decayAmount1 = -int256(deposit1.amount.mul(s_quantumParameters.entanglementDecayAmount_10000).div(10000));
             int256 decayAmount2 = -int256(deposit2.amount.mul(s_quantumParameters.entanglementDecayAmount_10000).div(10000));
            deposit1.amount = deposit1.amount.add(uint256(int256(deposit1.amount).add(decayAmount1) < 0 ? -int256(deposit1.amount) : decayAmount1)); // Prevent amount going below zero
            deposit2.amount = deposit2.amount.add(uint256(int256(deposit2.amount).add(decayAmount2) < 0 ? -int256(deposit2.amount) : decayAmount2)); // Prevent amount going below zero
             emit YieldApplied(depositId1, decayAmount1, AccruedEffectType.EntanglementDecay);
             emit YieldApplied(depositId2, decayAmount2, AccruedEffectType.EntanglementDecay);
        }

        // Transition both back to Stable
        deposit1.currentState = QuantumState.Stable;
        deposit2.currentState = QuantumState.Stable;
        deposit1.lastStateChangeTime = block.timestamp;
        deposit2.lastStateChangeTime = block.timestamp;
        deposit1.entangledDepositId = 0;
        deposit2.entangledDepositId = 0;

        emit ResolvedEntanglement(depositId1, depositId2, outcomePositive);
        emit StateChanged(depositId1, QuantumState.Entangled, QuantumState.Stable, block.timestamp);
        emit StateChanged(depositId2, QuantumState.Entangled, QuantumState.Stable, block.timestamp);
    }

     /// @notice Allows breaking entanglement prematurely. May incur a penalty and transition to Decohering state.
     /// Can be called by the owner of either entangled deposit.
     /// @param _depositId The ID of one of the entangled deposits.
    function breakEntanglement(uint256 _depositId) public payable whenNotPaused canResolveEntanglement(_depositId) { // Using canResolveEntanglement checks as it verifies entanglement and ownership
        uint256 depositId1 = _depositId;
        uint256 depositId2 = s_deposits[depositId1].entangledDepositId;

        Deposit storage deposit1 = s_deposits[depositId1];
        Deposit storage deposit2 = s_deposits[depositId2];

         // Apply yield for time spent in Entangled state before breaking
        uint256 duration = block.timestamp - deposit1.lastStateChangeTime; // Duration is the same for both
        _applyStateEffect(depositId1, QuantumState.Entangled, duration);
        _applyStateEffect(depositId2, QuantumState.Entangled, duration);

        // Apply penalty
        int256 penaltyAmount1 = -int256(deposit1.amount.mul(s_quantumParameters.entanglementBreakPenalty_10000).div(10000));
        int256 penaltyAmount2 = -int256(deposit2.amount.mul(s_quantumParameters.entanglementBreakPenalty_10000).div(10000));
        deposit1.amount = deposit1.amount.add(uint256(int256(deposit1.amount).add(penaltyAmount1) < 0 ? -int256(deposit1.amount) : penaltyAmount1)); // Prevent amount going below zero
        deposit2.amount = deposit2.amount.add(uint256(int256(deposit2.amount).add(penaltyAmount2) < 0 ? -int256(deposit2.amount) : penaltyAmount2)); // Prevent amount going below zero

        emit YieldApplied(depositId1, penaltyAmount1, AccruedEffectType.EntanglementBreakPenalty);
        emit YieldApplied(depositId2, penaltyAmount2, AccruedEffectType.EntanglementBreakPenalty);

        // Transition both to Decohering
        deposit1.currentState = QuantumState.Decohering;
        deposit2.currentState = QuantumState.Decohering;
        deposit1.lastStateChangeTime = block.timestamp;
        deposit2.lastStateChangeTime = block.timestamp;
        deposit1.entangledDepositId = 0;
        deposit2.entangledDepositId = 0;

        emit BrokenEntanglement(depositId1, depositId2);
        emit StateChanged(depositId1, QuantumState.Entangled, QuantumState.Decohering, block.timestamp);
        emit StateChanged(depositId2, QuantumState.Entangled, QuantumState.Decohering, block.timestamp);
    }


    /// @notice Allows anyone to trigger a state transition check for a deposit if conditions are met (e.g., minimum time in state passed).
    /// Handles time-based and probabilistic transitions (Stable->Decohering, Volatile->Stable, Decohering->Stable).
    /// @param _depositId The ID of the deposit to check.
    function observeAndTransition(uint256 _depositId) public payable whenNotPaused canCheckAndTransitionState(_depositId) {
        _transitionState(_depositId);
    }

    /// @dev Internal function to handle state transition logic based on current state and time.
    /// It applies the effects (yield/decay) from the time spent in the *previous* state
    /// before transitioning to the new state.
    /// @param _depositId The ID of the deposit to transition.
    function _transitionState(uint256 _depositId) internal depositExists(_depositId) {
        Deposit storage deposit = s_deposits[_depositId];
        QuantumState oldState = deposit.currentState;
        uint256 timeInState = block.timestamp - deposit.lastStateChangeTime;

        // Apply effects for the duration in the current (about to be old) state
        _applyStateEffect(_depositId, oldState, timeInState);

        QuantumState nextState = oldState; // Assume no change by default
        uint256 randomValue = _generatePseudoRandom(_depositId + block.timestamp + uint256(keccak256(abi.encode(deposit)))); // Seed with more variables

        if (oldState == QuantumState.Stable) {
             // Possible transition to Decohering over time
             if (timeInState > s_quantumParameters.stateTransitionMinimumTime) {
                if (randomValue % 10001 < s_quantumParameters.stableToDecoheringChance_10000) {
                    nextState = QuantumState.Decohering;
                }
             }
        } else if (oldState == QuantumState.Volatile) {
            // Volatile state resolves probabilistically over time
            if (timeInState > s_quantumParameters.stateTransitionMinimumTime) {
                // 50/50 chance to resolve positively or negatively (example logic)
                 bool outcomePositive = (randomValue % 2) == 0; // Simple binary outcome

                if (outcomePositive) {
                    int256 gainAmount = int256(deposit.amount.mul(s_quantumParameters.volatileGainAmount_10000).div(10000));
                    deposit.amount = deposit.amount.add(uint256(gainAmount));
                    emit YieldApplied(_depositId, gainAmount, AccruedEffectType.VolatileGain);
                    nextState = QuantumState.Stable; // Resolve to stable
                } else {
                    // Check against volatile decay chance for negative outcome
                    if ((randomValue % 10001) < s_quantumParameters.volatileDecayChance_10000) {
                        int256 decayAmount = -int256(deposit.amount.mul(s_quantumParameters.volatileDecayAmount_10000).div(10000));
                        deposit.amount = deposit.amount.add(uint256(int256(deposit.amount).add(decayAmount) < 0 ? -int256(deposit.amount) : decayAmount)); // Prevent amount going below zero
                        emit YieldApplied(_depositId, decayAmount, AccruedEffectType.VolatileDecay);
                    }
                     // Volatile stays Volatile until a positive resolution roll (example, could transition to Stable or Decohering)
                     // Let's transition back to Stable after a minimum time, regardless of decay outcome for simplicity,
                     // but only apply decay if the random roll dictates.
                    nextState = QuantumState.Stable;
                }
            }
        } else if (oldState == QuantumState.Decohering) {
            // Decohering state resolves to Stable after a fixed duration
            if (timeInState >= s_quantumParameters.decoheringDuration) {
                nextState = QuantumState.Stable;
            }
        }
        // Entangled state transitions via resolveEntanglement or breakEntanglement only

        if (nextState != oldState) {
            deposit.currentState = nextState;
            deposit.lastStateChangeTime = block.timestamp;
            emit StateChanged(_depositId, oldState, nextState, block.timestamp);
        }
    }

    // --- Yield/Decay & Effect Functions ---

     /// @dev Internal function to calculate and apply yield/decay for time spent in a given state.
     /// This updates the deposit's amount.
     /// @param _depositId The ID of the deposit.
     /// @param _state The state that the deposit was in.
     /// @param _duration The duration spent in that state (in seconds).
     function _applyStateEffect(uint256 _depositId, QuantumState _state, uint256 _duration) internal depositExists(_depositId) {
         if (_duration == 0) return;

         Deposit storage deposit = s_deposits[_depositId];
         uint256 yieldRate;
         AccruedEffectType effectType;

         if (_state == QuantumState.Stable) {
             yieldRate = s_quantumParameters.stableYieldRatePerSecond;
             effectType = AccruedEffectType.Yield;
         } else if (_state == QuantumState.Volatile) {
             // Volatile per-second yield (separate from probabilistic gain/decay)
             yieldRate = s_quantumParameters.volatileYieldRatePerSecond;
             effectType = AccruedEffectType.Yield; // Or a specific volatile yield type
         } else if (_state == QuantumState.Entangled) {
             yieldRate = s_quantumParameters.entangledYieldRatePerSecond;
              effectType = AccruedEffectType.Yield; // Or a specific entangled yield type
         } else if (_state == QuantumState.Decohering) {
              yieldRate = s_quantumParameters.decoheringYieldRatePerSecond;
              effectType = AccruedEffectType.Yield; // Or a specific decohering yield type
         } else {
             // Should not happen
             return;
         }

         if (yieldRate > 0) {
             // Calculate yield: amount * rate * duration
             // Need to handle potential overflow if amount/rate/duration are very large.
             // Assuming rate is small (e.g., wei per second per token), direct multiplication might be okay for reasonable values.
             // A more robust method would use fixed point or handle large numbers carefully.
             // Simplification: Yield is proportional to initialAmount * rate * duration
             // int256 accruedAmount = int256(deposit.initialAmount.mul(yieldRate).mul(_duration).div(1e18)); // Assumes rate is based on 1e18 unit
              int256 accruedAmount = int256(deposit.amount.mul(yieldRate).div(1e18).mul(_duration)); // Proportional to current amount

             deposit.amount = deposit.amount.add(uint256(int256(deposit.amount).add(accruedAmount) < 0 ? -int256(deposit.amount) : accruedAmount)); // Ensure amount doesn't go negative if rate is negative or due to decay

             emit YieldApplied(_depositId, accruedAmount, effectType);
         }
          // Note: Probabilistic effects (Volatile gain/decay, Entanglement gain/decay/penalty) are applied separately
          // when the state *resolves* or breaks, not continuously like yield.
     }

    /// @notice View function to calculate potential yield/decay for a deposit based on time elapsed since last state change.
    /// This is a prediction and does not modify the deposit state or amount.
    /// @param _depositId The ID of the deposit.
    /// @return accruedEffect The potential effect amount (can be positive for yield, negative for decay/loss).
    function calculateAccruedEffect(uint256 _depositId) public view depositExists(_depositId) returns (int256 accruedEffect) {
         Deposit storage deposit = s_deposits[_depositId];
         uint256 timeInState = block.timestamp - deposit.lastStateChangeTime;
         if (timeInState == 0) return 0;

         uint256 yieldRate;
         QuantumState currentState = deposit.currentState;

         if (currentState == QuantumState.Stable) {
             yieldRate = s_quantumParameters.stableYieldRatePerSecond;
         } else if (currentState == QuantumState.Volatile) {
             yieldRate = s_quantumParameters.volatileYieldRatePerSecond;
         } else if (currentState == QuantumState.Entangled) {
             yieldRate = s_quantumParameters.entangledYieldRatePerSecond;
         } else if (currentState == QuantumState.Decohering) {
              yieldRate = s_quantumParameters.decoheringYieldRatePerSecond;
         } else {
             return 0; // Should not happen
         }

         if (yieldRate > 0) {
              // Proportional to current amount
              return int256(deposit.amount.mul(yieldRate).div(1e18).mul(timeInState));
         }
         return 0; // No yield/decay rate for this state
    }


     /// @dev Simple pseudo-random number generation. NOT cryptographically secure.
     /// For demonstration purposes only. Use Chainlink VRF or similar for secure randomness.
     /// @param _seed Additional seed value.
     /// @return A pseudo-random uint256.
    function _generatePseudoRandom(uint256 _seed) internal view returns (uint256) {
        // Using blockhash and timestamp/difficulty is standard practice for on-chain pseudo-randomness,
        // but is manipulable by miners/validators.
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.prevrandao, msg.sender, _seed)));
    }

    /// @dev Internal helper to remove a deposit's data and clean up user's deposit list.
    /// @param _depositId The ID of the deposit to remove.
    function _removeDeposit(uint256 _depositId) internal {
        Deposit storage deposit = s_deposits[_depositId];
        address owner = deposit.owner;
        uint256[] storage userDeposits = s_userDeposits[owner];

        // Find and remove depositId from user's array (simple approach, inefficient for large arrays)
        // More efficient methods involve swapping with last element and popping.
        for (uint256 i = 0; i < userDeposits.length; i++) {
            if (userDeposits[i] == _depositId) {
                userDeposits[i] = userDeposits[userDeposits.length - 1];
                userDeposits.pop();
                break;
            }
        }

        delete s_deposits[_depositId];
    }

    // --- Admin Functions (Only Owner) ---

    /// @notice Allows the owner to update the global quantum parameters.
    /// @param _newParams The new set of parameters.
    function setQuantumParameters(QuantumParameters memory _newParams) public onlyOwner whenNotPaused {
        // Add validation checks for new parameters if necessary
         if (_newParams.stableYieldRatePerSecond > _newParams.volatileYieldRatePerSecond && _newParams.volatileYieldRatePerSecond > 0) revert InvalidParameters();
         if (_newParams.volatileDecayChance_10000 > 10000 || _newParams.volatileGainAmount_10000 > 10000 || _newParams.volatileDecayAmount_10000 > 10000) revert InvalidParameters();
         if (_newParams.entanglementResolutionChance_10000 > 10000 || _newParams.entanglementGainAmount_10000 > 10000 || _newParams.entanglementDecayAmount_10000 > 10000) revert InvalidParameters();
          if (_newParams.stableToDecoheringChance_10000 > 10000) revert InvalidParameters();
         if (_newParams.decoheringDuration == 0) revert InvalidParameters();
         if (_newParams.stateTransitionMinimumTime == 0) revert InvalidParameters();
         if (_newParams.minimumLockDuration == 0) revert InvalidParameters();


        s_quantumParameters = _newParams;
        emit QuantumParametersUpdated(_newParams);
    }

    /// @notice Allows the owner to set or update the address of the required Catalyst ERC721 token.
    /// Set to address(0) to disable the catalyst requirement for Volatile state.
    /// @param _catalystToken The address of the ERC721 token.
    function setCatalystToken(address _catalystToken) public onlyOwner {
        i_catalystToken = IERC721(_catalystToken);
        emit CatalystTokenUpdated(_catalystToken);
    }

    /// @notice Pauses the contract.
    function pause() public onlyOwner {
        _pause();
        s_paused = true; // Keep internal state in sync
    }

    /// @notice Unpauses the contract.
    function unpause() public onlyOwner {
        _unpause();
         s_paused = false; // Keep internal state in sync
    }

    /// @notice Allows the owner to withdraw any tokens accumulated from net decay/penalties.
    function withdrawFees() public onlyOwner {
        uint256 balance = i_supportedToken.balanceOf(address(this));
        // Only withdraw amounts exceeding the sum of all current active deposit amounts
        // This is a simplification; a true fee withdrawal would track fees/penalties separately.
        // For this example, let's assume contract holds net gain/loss and owner can withdraw excess.
        // A safer approach would be to only allow withdrawing amounts collected *explicitly* as fees/penalties.
        // Let's just allow withdrawing the entire balance for this example contract.
         uint256 totalDepositedAmount = 0;
         for(uint256 i = 1; i < s_nextDepositId; i++) {
             if (s_deposits[i].owner != address(0)) { // Check if deposit exists
                 totalDepositedAmount = totalDepositedAmount.add(s_deposits[i].amount);
             }
         }
         uint256 withdrawable = balance.sub(totalDepositedAmount); // Amount exceeding current sum of deposits

        if (withdrawable > 0) {
            bool success = i_supportedToken.transfer(owner(), withdrawable);
            require(success, "Fee token transfer failed");
        }
    }


    // --- View Functions ---

    /// @notice Gets the current pause status of the contract.
    /// @return True if paused, false otherwise.
    function paused() public view override returns (bool) {
        return s_paused; // Use internal state mirroring Pausable's state
    }

    /// @notice Gets detailed information about a deposit.
    /// @param _depositId The ID of the deposit.
    /// @return The Deposit struct.
    function getDepositInfo(uint256 _depositId) public view depositExists(_depositId) returns (Deposit memory) {
        return s_deposits[_depositId];
    }

    /// @notice Gets the list of deposit IDs belonging to a user.
    /// @param _user The address of the user.
    /// @return An array of deposit IDs.
    function getUserDeposits(address _user) public view returns (uint256[] memory) {
        return s_userDeposits[_user];
    }

    /// @notice Gets the current global quantum parameters.
    /// @return The QuantumParameters struct.
    function getQuantumParameters() public view returns (QuantumParameters memory) {
        return s_quantumParameters;
    }

    /// @notice Gets the address of the required Catalyst ERC721 token.
    /// @return The catalyst token address.
    function getCatalystToken() public view returns (address) {
        return address(i_catalystToken);
    }

    /// @notice Gets the current state of a deposit.
    /// @param _depositId The ID of the deposit.
    /// @return The QuantumState enum value.
    function getDepositState(uint256 _depositId) public view depositExists(_depositId) returns (QuantumState) {
        return s_deposits[_depositId].currentState;
    }

    /// @notice Gets the timestamp when a deposit's lock period ends.
    /// @param _depositId The ID of the deposit.
    /// @return The lock end timestamp.
    function getDepositLockEndTime(uint256 _depositId) public view depositExists(_depositId) returns (uint256) {
        return s_deposits[_depositId].depositTime.add(s_deposits[_depositId].lockDuration);
    }

     /// @notice Checks if a deposit is currently locked.
     /// @param _depositId The ID of the deposit.
     /// @return True if locked, false otherwise.
    function isDepositLocked(uint256 _depositId) public view depositExists(_depositId) returns (bool) {
        return block.timestamp < s_deposits[_depositId].depositTime.add(s_deposits[_depositId].lockDuration);
    }

    /// @notice Gets the ID of the deposit entangled with the given deposit. Returns 0 if not entangled.
    /// @param _depositId The ID of the deposit.
    /// @return The entangled deposit ID, or 0.
    function getEntangledDepositId(uint256 _depositId) public view depositExists(_depositId) returns (uint256) {
        return s_deposits[_depositId].entangledDepositId;
    }

     /// @notice Checks if a deposit is currently in the Entangled state.
     /// @param _depositId The ID of the deposit.
     /// @return True if entangled, false otherwise.
     function isDepositEntangled(uint256 _depositId) public view depositExists(_depositId) returns (bool) {
         return s_deposits[_depositId].currentState == QuantumState.Entangled;
     }

     /// @notice Checks if a deposit is currently in the Volatile state.
     /// @param _depositId The ID of the deposit.
     /// @return True if Volatile, false otherwise.
     function isDepositVolatile(uint256 _depositId) public view depositExists(_depositId) returns (bool) {
         return s_deposits[_depositId].currentState == QuantumState.Volatile;
     }

     /// @notice Checks if a deposit is currently in the Stable state.
     /// @param _depositId The ID of the deposit.
     /// @return True if Stable, false otherwise.
     function isDepositStable(uint256 _depositId) public view depositExists(_depositId) returns (bool) {
         return s_deposits[_depositId].currentState == QuantumState.Stable;
     }

     /// @notice Checks if a deposit is currently in the Decohering state.
     /// @param _depositId The ID of the deposit.
     /// @return True if Decohering, false otherwise.
     function isDepositDecohering(uint256 _depositId) public view depositExists(_depositId) returns (bool) {
         return s_deposits[_depositId].currentState == QuantumState.Decohering;
     }


    /// @notice Gets the total number of deposits ever created.
    /// @return The next deposit ID (which is the total count + 1).
    function getTotalDeposits() public view returns (uint256) {
        return s_nextDepositId - 1;
    }

    /// @notice Gets the total balance of the supported token held by the contract.
    /// @return The token balance.
    function getContractTokenBalance() public view returns (uint256) {
        return i_supportedToken.balanceOf(address(this));
    }

     /// @notice Checks if a deposit can potentially initiate the Volatile state.
     /// @param _depositId The ID of the deposit.
     /// @return True if possible, false otherwise.
     function canInitiateVolatile(uint256 _depositId) public view depositExists(_depositId) returns (bool) {
        Deposit storage deposit = s_deposits[_depositId];
        if (deposit.currentState != QuantumState.Stable) return false;
        if (isDepositLocked(_depositId)) return false;
        address catalystAddr = address(i_catalystToken);
        if (catalystAddr == address(0)) return true; // No catalyst required
        return i_catalystToken.balanceOf(deposit.owner) > 0; // Requires owner of deposit to own a catalyst
     }

     /// @notice Checks if two deposits can potentially be entangled.
     /// @param _depositId1 The ID of the first deposit.
     /// @param _depositId2 The ID of the second deposit.
     /// @return True if possible, false otherwise.
     function canInitiateEntanglement(uint256 _depositId1, uint256 _depositId2) public view returns (bool) {
         if (_depositId1 == _depositId2) return false;
         if (s_deposits[_depositId1].owner == address(0) || s_deposits[_depositId2].owner == address(0)) return false; // Check existence
         if (s_deposits[_depositId1].owner != s_deposits[_depositId2].owner) return false; // Same owner

         Deposit storage deposit1 = s_deposits[_depositId1];
         Deposit storage deposit2 = s_deposits[_depositId2];

         if (deposit1.currentState != QuantumState.Stable || deposit2.currentState != QuantumState.Stable) return false;
         if (isDepositLocked(_depositId1) || isDepositLocked(_depositId2)) return false;
         if (deposit1.entangledDepositId != 0 || deposit2.entangledDepositId != 0) return false; // Not already entangled

         return true;
     }

     /// @notice Checks if an entangled deposit can currently be resolved.
     /// @param _depositId The ID of the entangled deposit.
     /// @return True if possible, false otherwise.
     function canResolveEntanglement(uint256 _depositId) public view depositExists(_depositId) returns (bool) {
         Deposit storage deposit = s_deposits[_depositId];
         if (deposit.currentState != QuantumState.Entangled) return false;
         uint256 entangledId = deposit.entangledDepositId;
         if (entangledId == 0 || s_deposits[entangledId].entangledDepositId != _depositId) return false; // Ensure valid entanglement
         // Check if minimum time in state has passed (optional)
         // return block.timestamp >= deposit.lastStateChangeTime + s_quantumParameters.stateTransitionMinimumTime;
         return true; // No minimum time required for resolution in this version
     }

     /// @notice Checks if a deposit's state can potentially transition now via observeAndTransition.
     /// @param _depositId The ID of the deposit.
     /// @return True if a transition check is possible, false otherwise.
     function canCheckAndTransitionState(uint256 _depositId) public view depositExists(_depositId) returns (bool) {
        QuantumState currentState = s_deposits[_depositId].currentState;
        // Only certain states transition automatically based on time
        if (currentState != QuantumState.Volatile && currentState != QuantumState.Decohering && currentState != QuantumState.Stable) {
             return false;
        }
         // Require minimum time in state before checking
        return block.timestamp >= s_deposits[_depositId].lastStateChangeTime + s_quantumParameters.stateTransitionMinimumTime;
     }

     /// @notice Gets the timestamp of the last state change for a deposit.
     /// @param _depositId The ID of the deposit.
     /// @return The timestamp.
     function getDepositLastStateChangeTime(uint256 _depositId) public view depositExists(_depositId) returns (uint256) {
         return s_deposits[_depositId].lastStateChangeTime;
     }

     /// @notice Gets the minimum time required in a state before observeAndTransition is possible.
     /// @return The minimum time in seconds.
     function getDepositStateTransitionThreshold() public view returns (uint256) {
         return s_quantumParameters.stateTransitionMinimumTime;
     }

     /// @notice Gets the current amount of a deposit.
     /// @param _depositId The ID of the deposit.
     /// @return The current amount after applied effects.
     function getDepositAmount(uint256 _depositId) public view depositExists(_depositId) returns (uint256) {
         return s_deposits[_depositId].amount;
     }

     /// @notice Gets the minimum lock duration required for new deposits.
     /// @return The minimum lock duration in seconds.
    function getMinimumLockDuration() public view returns (uint256) {
        return s_quantumParameters.minimumLockDuration;
    }

    // Required for ERC721Holder
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
        // This contract doesn't explicitly receive/hold catalyst NFTs *from users* for operations (it only checks ownership)
        // but implementing this function fulfills the interface if needed later or if admin transfers NFTs here.
        // If the contract *did* need to receive/hold the catalyst NFT from the user for `initiateVolatile`,
        // the initiateVolatile function would call safeTransferFrom user -> contract, and this function would be called.
        // Since we only check ownership, this is just boilerplate for being an ERC721Holder.
        return this.onERC721Received.selector;
    }

}
```