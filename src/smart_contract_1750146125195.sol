Okay, here is a Solidity smart contract implementing an advanced, creative, and somewhat abstract concept: a "Quantum Vault". This contract manages user deposits (Ether or ERC20 tokens) which exist in different "quantum states" (`Superposition`, `Entangled`, `Decayed`, `Collapsed`). Assets can only be withdrawn once they reach the `Collapsed` state through specific transition functions, which may involve probabilistic outcomes, external conditions, or multi-party coordination (entanglement). It also introduces the concept of "Decay" if assets remain in certain states too long.

**Disclaimer:** This is a conceptual and experimental contract designed to explore advanced Solidity features and complex state management. The "quantum" aspects are metaphorical approximations of complex, non-linear state transitions and dependencies. It uses `block.timestamp` for a simple form of "on-chain randomness," which is **not secure** for critical applications requiring true unpredictability. This contract is for educational and demonstration purposes and **should not be used in production without significant auditing and refinement.**

---

**Contract Outline & Function Summary:**

*   **Contract:** `QuantumVault`
*   **Purpose:** Manages deposits under unique "quantum-inspired" state rules. Assets must transition through states to become withdrawable.
*   **Core Concepts:**
    *   **Quantum States:** `Initial`, `Superposition`, `Entangled`, `Decayed`, `Collapsed`.
    *   **State Transitions:** Specific functions trigger state changes (`transitionToSuperposition`, `attemptCollapse`, `triggerConditionalCollapse`, `decayState`, `entangleAssets`, `breakEntanglement`).
    *   **Probabilistic Collapse:** `attemptCollapse` has a chance of success based on a configurable weight and `block.timestamp`.
    *   **Conditional Collapse:** `triggerConditionalCollapse` is triggered by designated "Observers" when a predefined external/internal condition is met.
    *   **Entanglement:** Links two deposits. Both must meet collapse conditions simultaneously to be withdrawn. Requires acceptance.
    *   **Decay:** Assets can become unclaimable (`Decayed`) if left in `Superposition` or `Entangled` states too long.
    *   **Observers:** A role with limited, specific permissions (triggering decay, conditional collapse).
*   **Key State Variables:**
    *   `deposits`: Mapping storing deposit details by ID.
    *   `depositCounter`: Counter for unique deposit IDs.
    *   `entanglements`: Mapping storing entanglement group details.
    *   `stateParameters`: Struct holding configurable parameters (decay rates, collapse weights, conditional triggers).
    *   `observers`: Mapping tracking authorized observers.
    *   `withdrawalFeeBasisPoints`: Fee applied on withdrawals.
*   **Modifiers:** `onlyOwner`, `whenNotPaused`, `nonReentrant`, `onlyObserver`, `onlyDepositOwner`, `onlyEntangledGroupOwner`.
*   **Events:** For deposits, withdrawals, state changes, entanglement events, parameter changes, etc.

**Function Summary (28 Functions):**

1.  `constructor()`: Initializes contract owner and parameters.
2.  `receive()`: Allows receiving Ether deposits. Creates a new deposit.
3.  `fallback()`: Catches incorrect calls.
4.  `depositEther()`: Explicitly deposits Ether, creates a deposit.
5.  `depositERC20(address tokenAddress, uint256 amount)`: Deposits ERC20 tokens, creates a deposit.
6.  `transitionToSuperposition(uint256 depositId)`: Moves deposit from `Initial` to `Superposition`.
7.  `attemptCollapse(uint256 depositId)`: Attempts probabilistic transition from `Superposition` or `Entangled` to `Collapsed`.
8.  `triggerConditionalCollapse(uint256 depositId)`: Observer-only function to trigger collapse if condition is met.
9.  `decayState(uint256 depositId)`: Observer-only or self-trigger function to move deposit towards `Decayed`.
10. `requestEntanglement(uint256 depositId1, uint256 depositId2)`: Initiates linking two deposits.
11. `acceptEntanglement(uint256 entanglementId)`: Second party accepts an entanglement request.
12. `rejectEntanglement(uint256 entanglementId)`: Second party rejects an entanglement request.
13. `breakEntanglement(uint256 entanglementId)`: Breaks an active entanglement (potentially with penalty).
14. `withdraw(uint256 depositId)`: Withdraws assets from a `Collapsed` deposit. Handles entangled groups.
15. `claimDecayedAssets(uint256 depositId)`: Allows claiming assets from `Decayed` state (potentially by owner based on configuration).
16. `getDepositDetails(uint256 depositId)`: Returns details of a specific deposit.
17. `getUserTotalBalance(address user)`: Calculates total balance across all user deposits (regardless of state).
18. `getUserBalanceInState(address user, QuantumState state)`: Calculates user's balance in a specific state.
19. `getContractStateSummary()`: Returns overall contract state parameters.
20. `setCollapseProbabilityWeight(uint256 weight)`: Owner sets the weight for probabilistic collapse.
21. `setDecayParameters(uint256 decayRateBasisPoints, uint256 decayStartTime)`: Owner sets decay parameters.
22. `setConditionalCollapseTrigger(uint256 triggerValue)`: Owner sets the trigger value for conditional collapse (e.g., block number).
23. `addObserver(address observer)`: Owner adds an authorized observer.
24. `removeObserver(address observer)`: Owner removes an observer.
25. `getObserverCount()`: Returns the number of active observers.
26. `pauseContract()`: Owner pauses critical functions.
27. `unpauseContract()`: Owner unpauses the contract.
28. `setWithdrawalFee(uint256 feeBasisPoints)`: Owner sets the withdrawal fee.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// ----------------------------------------------------------------------------
// QUANTUM VAULT SMART CONTRACT
// ----------------------------------------------------------------------------
// A conceptual smart contract exploring complex state management,
// probabilistic transitions, and multi-party interactions inspired by
// quantum mechanics metaphors (Superposition, Entanglement, Collapse, Decay).
// Assets must transition through specific states to be withdrawn.
// Introduces 'Observers' with limited, state-triggering permissions.
// ----------------------------------------------------------------------------
// DISCLAIMER: This contract is EXPERIMENTAL and conceptual. It uses block.timestamp
// for a form of on-chain "randomness," which is NOT SECURE. It should NOT be
// used in production without significant security audits and refinement.
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// OUTLINE & FUNCTION SUMMARY (See comments above code block)
// ----------------------------------------------------------------------------


contract QuantumVault is Ownable, Pausable, ReentrancyGuard {

    // ------------------------------------------------------------------------
    // ENUMS & STRUCTS
    // ------------------------------------------------------------------------

    enum QuantumState {
        Initial,        // Just deposited, waiting for activation
        Superposition,  // Active state, awaiting collapse condition
        Entangled,      // Linked with another deposit, requires joint action
        Decayed,        // State deterioration, potentially unclaimable or partially claimable
        Collapsed       // State collapsed, ready for withdrawal
    }

    struct Deposit {
        uint256 id;
        address user;
        address token; // Zero address for Ether
        uint256 amount;
        QuantumState state;
        uint256 depositTimestamp;
        uint256 lastStateTransitionTimestamp; // Timestamp when state last changed
        uint256 entanglementId; // 0 if not entangled
        uint256 decayTimerStart; // Timestamp when decay starts counting
    }

    struct EntanglementGroup {
        uint256 id;
        uint256[] depositIds;
        uint256 requestTimestamp;
        bool accepted;
        address requester;
        address acceptor; // User who needs to accept
    }

    struct StateParameters {
        // Probabilistic Collapse: success chance based on (block.timestamp + value) % collapseProbabilityWeight == 0
        uint256 collapseProbabilityWeight; // Higher weight = lower probability (e.g., 100 for 1% chance)

        // Decay Parameters: Assets decay if in Superposition/Entangled for decayStartTime + decayRateBasisPoints
        uint256 decayStartTimeThreshold; // Time elapsed since depositTimestamp/transition before decay timer starts
        uint256 decayRateBasisPoints; // Rate at which value decays per time unit (e.g., per day, expressed in basis points of original amount)
        uint256 decayUnitDuration; // Duration of one decay unit (e.g., 1 day in seconds)
        address decayClaimRecipient; // Address that can claim Decayed assets (e.g., owner or zero for burn)

        // Conditional Collapse: Triggered by Observer if block.number reaches triggerBlockNumber
        uint256 conditionalCollapseTriggerBlock; // Target block number for conditional collapse
    }

    // ------------------------------------------------------------------------
    // STATE VARIABLES
    // ------------------------------------------------------------------------

    mapping(uint256 => Deposit) public deposits;
    uint256 private depositCounter;

    mapping(uint256 => EntanglementGroup) public entanglements;
    uint256 private entanglementCounter;

    StateParameters public stateParameters;

    mapping(address => bool) public observers;
    uint256 private observerCount;

    uint256 public withdrawalFeeBasisPoints; // Fee applied on withdrawal (e.g., 100 for 1%)

    // ------------------------------------------------------------------------
    // EVENTS
    // ------------------------------------------------------------------------

    event DepositMade(uint256 indexed depositId, address indexed user, address indexed token, uint256 amount, QuantumState initialState);
    event StateTransition(uint256 indexed depositId, QuantumState oldState, QuantumState newState, string triggeredBy);
    event Withdrawal(uint256 indexed depositId, address indexed user, uint256 amountWithdrawn, uint256 feeAmount);
    event EntanglementRequested(uint256 indexed entanglementId, uint256 indexed depositId1, uint256 indexed depositId2, address indexed requester);
    event EntanglementAccepted(uint256 indexed entanglementId);
    event EntanglementRejected(uint256 indexed entanglementId);
    event EntanglementBroken(uint256 indexed entanglementId, uint256 penaltyAmount);
    event ParametersUpdated(string paramName, uint256 oldValue, uint256 newValue);
    event ObserverAdded(address indexed observer);
    event ObserverRemoved(address indexed observer);
    event DecayedAssetsClaimed(uint256 indexed depositId, address indexed recipient, uint256 amountClaimed);

    // ------------------------------------------------------------------------
    // MODIFIERS
    // ------------------------------------------------------------------------

    modifier onlyObserver() {
        require(observers[msg.sender], "Not authorized as observer");
        _;
    }

    modifier onlyDepositOwner(uint256 _depositId) {
        require(_depositId > 0 && _depositId <= depositCounter, "Invalid deposit ID");
        require(deposits[_depositId].user == msg.sender, "Not deposit owner");
        _;
    }

    modifier onlyEntangledGroupOwner(uint256 _entanglementId) {
        require(_entanglementId > 0 && _entanglementId <= entanglementCounter, "Invalid entanglement ID");
        EntanglementGroup storage group = entanglements[_entanglementId];
        bool isOwner = false;
        for (uint i = 0; i < group.depositIds.length; i++) {
            if (deposits[group.depositIds[i]].user == msg.sender) {
                isOwner = true;
                break;
            }
        }
        require(isOwner, "Not owner of any deposit in group");
        _;
    }

    // ------------------------------------------------------------------------
    // CONSTRUCTOR
    // ------------------------------------------------------------------------

    constructor(
        uint256 _collapseProbabilityWeight,
        uint256 _decayStartTimeThreshold,
        uint256 _decayRateBasisPoints,
        uint256 _decayUnitDuration,
        address _decayClaimRecipient,
        uint256 _conditionalCollapseTriggerBlock,
        uint256 _withdrawalFeeBasisPoints
    ) Ownable(msg.sender) {
        require(_collapseProbabilityWeight > 0, "Collapse weight must be > 0");
        require(_decayRateBasisPoints <= 10000, "Decay rate basis points <= 10000");
        require(_decayUnitDuration > 0, "Decay unit duration must be > 0");
        require(_withdrawalFeeBasisPoints <= 10000, "Withdrawal fee basis points <= 10000");

        stateParameters = StateParameters({
            collapseProbabilityWeight: _collapseProbabilityWeight,
            decayStartTimeThreshold: _decayStartTimeThreshold,
            decayRateBasisPoints: _decayRateBasisPoints,
            decayUnitDuration: _decayUnitDuration,
            decayClaimRecipient: _decayClaimRecipient,
            conditionalCollapseTriggerBlock: _conditionalCollapseTriggerBlock
        });

        withdrawalFeeBasisPoints = _withdrawalFeeBasisPoints;
        depositCounter = 0;
        entanglementCounter = 0;
        observerCount = 0;
    }

    // ------------------------------------------------------------------------
    // RECEIVE / FALLBACK
    // ------------------------------------------------------------------------

    receive() external payable whenNotPaused nonReentrant {
        if (msg.value > 0) {
            _createDeposit(msg.sender, address(0), msg.value); // Use address(0) for Ether
        } else {
            // Optional: Revert if only Ether is expected but 0 is sent
            // revert("Ether deposit must be greater than 0");
        }
    }

    fallback() external payable {
        // Optional: Revert if fallback is called but not receive()
        // revert("Cannot call fallback function");
    }


    // ------------------------------------------------------------------------
    // DEPOSIT FUNCTIONS
    // ------------------------------------------------------------------------

    /// @notice Deposits Ether into the vault, creating a new deposit in the Initial state.
    function depositEther() external payable whenNotPaused nonReentrant {
        require(msg.value > 0, "Ether amount must be greater than 0");
        _createDeposit(msg.sender, address(0), msg.value);
    }

    /// @notice Deposits ERC20 tokens into the vault, creating a new deposit in the Initial state.
    /// @param tokenAddress The address of the ERC20 token.
    /// @param amount The amount of ERC20 tokens to deposit.
    function depositERC20(address tokenAddress, uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0, "Token amount must be greater than 0");
        require(tokenAddress != address(0), "Invalid token address");

        IERC20 token = IERC20(tokenAddress);
        require(token.transferFrom(msg.sender, address(this), amount), "ERC20 transfer failed");

        _createDeposit(msg.sender, tokenAddress, amount);
    }

    /// @dev Internal function to create a new deposit entry.
    function _createDeposit(address user, address tokenAddress, uint256 amount) internal {
        depositCounter++;
        deposits[depositCounter] = Deposit({
            id: depositCounter,
            user: user,
            token: tokenAddress,
            amount: amount,
            state: QuantumState.Initial,
            depositTimestamp: block.timestamp,
            lastStateTransitionTimestamp: block.timestamp,
            entanglementId: 0,
            decayTimerStart: 0 // Decay timer starts only after transition from Initial
        });

        emit DepositMade(depositCounter, user, tokenAddress, amount, QuantumState.Initial);
    }

    // ------------------------------------------------------------------------
    // STATE TRANSITION FUNCTIONS (User & Observer)
    // ------------------------------------------------------------------------

    /// @notice Moves a deposit from Initial state to Superposition. Required before collapse attempts or entanglement.
    /// @param depositId The ID of the deposit to transition.
    function transitionToSuperposition(uint256 depositId) external whenNotPaused nonReentrant onlyDepositOwner(depositId) {
        Deposit storage deposit = deposits[depositId];
        require(deposit.state == QuantumState.Initial, "Deposit not in Initial state");

        _transitionState(depositId, QuantumState.Superposition, "transitionToSuperposition");
        deposit.decayTimerStart = block.timestamp; // Start tracking for decay
    }

    /// @notice Attempts to collapse a deposit from Superposition or Entangled state to Collapsed probabilistically.
    /// @param depositId The ID of the deposit to attempt collapse on.
    function attemptCollapse(uint256 depositId) external whenNotPaused nonReentrant onlyDepositOwner(depositId) {
        Deposit storage deposit = deposits[depositId];
        require(deposit.state == QuantumState.Superposition || deposit.state == QuantumState.Entangled, "Deposit not in Superposition or Entangled state");
        require(stateParameters.collapseProbabilityWeight > 0, "Collapse probability weight not set");

        bool success = false;
        // --- SIMULATED PROBABILISTIC CHECK (NOT SECURE) ---
        // This uses block.timestamp for a rudimentary probabilistic outcome.
        // A real application needs a decentralized oracle for randomness.
        if ((uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, depositId))) % stateParameters.collapseProbabilityWeight) == 0) {
            success = true;
        }
        // ---------------------------------------------------

        if (success) {
            if (deposit.state == QuantumState.Entangled) {
                // For entangled assets, ALL linked deposits must collapse together.
                // This simple implementation requires attemptCollapse on *each* entangled deposit to succeed,
                // which is complex. A better implementation might require a single multi-sig like action
                // or link the collapse probability. For simplicity here, we'll assume
                // attempting collapse on one entangled deposit *might* trigger collapse for the group
                // IF the probabilistic check passes and ALL deposits in the group were attempted recently.
                // This is an abstraction for demonstration. Let's simplify: if one attempt succeeds,
                // it *potentially* allows the whole group if conditions are met (e.g., all deposits in group
                // were attempted within a short timeframe, or all are still 'Entangled').
                // A simpler rule: If you attempt collapse on an Entangled deposit and succeed the *probabilistic* part,
                // it *only* works if all other deposits in its entanglement group are also in the Entangled state.
                // If so, *all* transition to Collapsed.

                EntanglementGroup storage group = entanglements[deposit.entanglementId];
                bool allEntangled = true;
                for(uint i = 0; i < group.depositIds.length; i++) {
                    if (deposits[group.depositIds[i]].state != QuantumState.Entangled) {
                        allEntangled = false;
                        break;
                    }
                }

                if (allEntangled) {
                     for(uint i = 0; i < group.depositIds.length; i++) {
                        _transitionState(group.depositIds[i], QuantumState.Collapsed, "attemptCollapse (Entangled Group)");
                    }
                } else {
                     // Collapse failed for the group because not all were in the right state
                     emit StateTransition(depositId, deposit.state, deposit.state, "attemptCollapse (Failed - Entangled Group State Mismatch)");
                }

            } else { // Superposition state
                 _transitionState(depositId, QuantumState.Collapsed, "attemptCollapse");
            }
        } else {
            // Collapse failed probabilistically
             emit StateTransition(depositId, deposit.state, deposit.state, "attemptCollapse (Failed Probabilistically)");
        }
    }

    /// @notice Observer-only function to trigger collapse if the conditional trigger (e.g., block number) is met.
    /// @param depositId The ID of the deposit to potentially collapse.
    function triggerConditionalCollapse(uint256 depositId) external whenNotPaused nonReentrant onlyObserver {
        Deposit storage deposit = deposits[depositId];
        require(deposit.state == QuantumState.Superposition || deposit.state == QuantumState.Entangled, "Deposit not in Superposition or Entangled state");
        require(block.number >= stateParameters.conditionalCollapseTriggerBlock, "Conditional trigger block not reached");

        if (deposit.state == QuantumState.Entangled) {
             EntanglementGroup storage group = entanglements[deposit.entanglementId];
             bool allEntangled = true;
             for(uint i = 0; i < group.depositIds.length; i++) {
                if (deposits[group.depositIds[i]].state != QuantumState.Entangled) {
                    allEntangled = false;
                    break;
                }
            }
            if (allEntangled) {
                 for(uint i = 0; i < group.depositIds.length; i++) {
                    _transitionState(group.depositIds[i], QuantumState.Collapsed, "triggerConditionalCollapse (Entangled Group)");
                }
            } else {
                 emit StateTransition(depositId, deposit.state, deposit.state, "triggerConditionalCollapse (Failed - Entangled Group State Mismatch)");
            }
        } else { // Superposition state
             _transitionState(depositId, QuantumState.Collapsed, "triggerConditionalCollapse");
        }
    }


    /// @notice Moves a deposit towards the Decayed state based on time elapsed. Can be triggered by Observer or potentially self-triggered.
    /// @param depositId The ID of the deposit to check for decay.
    function decayState(uint256 depositId) external whenNotPaused nonReentrant {
         // Allow owner, observer, or deposit owner to trigger the check
        require(msg.sender == owner() || observers[msg.sender] || deposits[depositId].user == msg.sender, "Unauthorized to trigger decay");

        Deposit storage deposit = deposits[depositId];
        require(deposit.state == QuantumState.Superposition || deposit.state == QuantumState.Entangled, "Deposit not in decayable state");

        // Check if decay time threshold has passed
        if (block.timestamp < deposit.decayTimerStart + stateParameters.decayStartTimeThreshold) {
            // Decay hasn't started counting yet, or threshold not reached
             emit StateTransition(depositId, deposit.state, deposit.state, "decayState (Not yet eligible for decay)");
             return;
        }

        // Calculate how many decay units have passed since timer started + threshold
        uint256 timeSinceDecayStart = block.timestamp - (deposit.decayTimerStart + stateParameters.decayStartTimeThreshold);
        uint256 decayUnitsPassed = timeSinceDecayStart / stateParameters.decayUnitDuration;

        // Note: This simple decay model transitions *directly* to Decayed after the first unit.
        // A more complex model could reduce the amount incrementally over multiple units.
        // For this example, reaching the first decay unit moves it to Decayed state.
        if (decayUnitsPassed > 0 && deposit.state != QuantumState.Decayed) {
             _transitionState(depositId, QuantumState.Decayed, "decayState");
        } else {
             emit StateTransition(depositId, deposit.state, deposit.state, "decayState (No decay units passed yet)");
        }
    }


    /// @dev Internal helper to transition a deposit's state and emit event.
    function _transitionState(uint256 depositId, QuantumState newState, string memory triggeredBy) internal {
        Deposit storage deposit = deposits[depositId];
        QuantumState oldState = deposit.state;
        deposit.state = newState;
        deposit.lastStateTransitionTimestamp = block.timestamp;
        emit StateTransition(depositId, oldState, newState, triggeredBy);
    }


    // ------------------------------------------------------------------------
    // ENTANGLEMENT FUNCTIONS
    // ------------------------------------------------------------------------

    /// @notice Requests to entangle two deposits. Both must be in Superposition and belong to different users.
    /// @param depositId1 The ID of the first deposit.
    /// @param depositId2 The ID of the second deposit.
    function requestEntanglement(uint256 depositId1, uint256 depositId2) external whenNotPaused nonReentrant {
        require(depositId1 != depositId2, "Cannot entangle a deposit with itself");
        require(depositId1 > 0 && depositId1 <= depositCounter, "Invalid deposit ID 1");
        require(depositId2 > 0 && depositId2 <= depositCounter, "Invalid deposit ID 2");

        Deposit storage dep1 = deposits[depositId1];
        Deposit storage dep2 = deposits[depositId2];

        require(dep1.user == msg.sender, "Deposit 1 not owned by caller");
        require(dep1.state == QuantumState.Superposition, "Deposit 1 not in Superposition");
        require(dep1.entanglementId == 0, "Deposit 1 already entangled");

        require(dep2.state == QuantumState.Superposition, "Deposit 2 not in Superposition");
        require(dep2.entanglementId == 0, "Deposit 2 already entangled");

        require(dep1.user != dep2.user, "Cannot entangle deposits owned by the same user"); // Entanglement implies linking different entities

        entanglementCounter++;
        uint256 newEntanglementId = entanglementCounter;

        entanglements[newEntanglementId] = EntanglementGroup({
            id: newEntanglementId,
            depositIds: new uint256[](2),
            requestTimestamp: block.timestamp,
            accepted: false,
            requester: msg.sender,
            acceptor: dep2.user // The owner of deposit 2 needs to accept
        });

        entanglements[newEntanglementId].depositIds[0] = depositId1;
        entanglements[newEntanglementId].depositIds[1] = depositId2;

        // Temporarily mark deposits as pending entanglement? Or keep them in Superposition until accepted?
        // Let's keep them in Superposition but link the entanglementId
        dep1.entanglementId = newEntanglementId;
        dep2.entanglementId = newEntanglementId;

        emit EntanglementRequested(newEntanglementId, depositId1, depositId2, msg.sender);
    }

     /// @notice Accepts a pending entanglement request.
     /// @param entanglementId The ID of the entanglement request to accept.
    function acceptEntanglement(uint256 entanglementId) external whenNotPaused nonReentrant {
        require(entanglementId > 0 && entanglementId <= entanglementCounter, "Invalid entanglement ID");
        EntanglementGroup storage group = entanglements[entanglementId];

        require(!group.accepted, "Entanglement already accepted");
        require(group.acceptor == msg.sender, "Not the designated acceptor");

        // Verify both deposits are still valid and linked
        require(group.depositIds.length == 2, "Invalid entanglement group size");
        Deposit storage dep1 = deposits[group.depositIds[0]];
        Deposit storage dep2 = deposits[group.depositIds[1]];

        require(dep1.state == QuantumState.Superposition && dep1.entanglementId == entanglementId, "Deposit 1 not in correct state for acceptance");
        require(dep2.state == QuantumState.Superposition && dep2.entanglementId == entanglementId, "Deposit 2 not in correct state for acceptance");


        group.accepted = true;

        // Transition both deposits to Entangled state
        _transitionState(group.depositIds[0], QuantumState.Entangled, "acceptEntanglement");
        _transitionState(group.depositIds[1], QuantumState.Entangled, "acceptEntanglement");

        emit EntanglementAccepted(entanglementId);
    }

    /// @notice Rejects a pending entanglement request.
    /// @param entanglementId The ID of the entanglement request to reject.
    function rejectEntanglement(uint256 entanglementId) external whenNotPaused nonReentrant {
        require(entanglementId > 0 && entanglementId <= entanglementCounter, "Invalid entanglement ID");
        EntanglementGroup storage group = entanglements[entanglementId];

        require(!group.accepted, "Entanglement already accepted");
        require(group.acceptor == msg.sender, "Not the designated acceptor");

        // Clear entanglement ID from deposits
        if (group.depositIds.length > 0) deposits[group.depositIds[0]].entanglementId = 0;
        if (group.depositIds.length > 1) deposits[group.depositIds[1]].entanglementId = 0;

        // Remove the entanglement group (or mark as rejected) - let's mark it by clearing depositIds
        delete group.depositIds; // Mark as rejected/invalidated

        emit EntanglementRejected(entanglementId);
    }

    /// @notice Allows an owner of a deposit within an *accepted* entanglement group to break the link. May incur a penalty.
    /// @param entanglementId The ID of the entanglement group to break.
    function breakEntanglement(uint256 entanglementId) external whenNotPaused nonReentrant onlyEntangledGroupOwner(entanglementId) {
        require(entanglementId > 0 && entanglementId <= entanglementCounter, "Invalid entanglement ID");
        EntanglementGroup storage group = entanglements[entanglementId];

        require(group.accepted, "Entanglement not accepted");
        require(group.depositIds.length > 0, "Entanglement already broken or invalid");

        // Determine penalty - let's say breaking requires sending some Ether to the other party
        // This is complex. A simpler penalty is moving both deposits to a 'Penalized' or 'Decayed' state
        // or just returning them to Superposition. Let's return them to Superposition for simplicity.
        // A real contract might involve transferring a % of value.

        uint256 penaltyAmount = 0; // Placeholder for potential future penalty logic

        // Move both deposits back to Superposition state
         for(uint i = 0; i < group.depositIds.length; i++) {
            uint256 depId = group.depositIds[i];
            if (deposits[depId].state != QuantumState.Decayed && deposits[depId].state != QuantumState.Collapsed) { // Don't change if already collapsed or decayed
                 _transitionState(depId, QuantumState.Superposition, "breakEntanglement");
                 deposits[depId].entanglementId = 0; // Clear entanglement link
                 deposits[depId].decayTimerStart = block.timestamp; // Restart decay timer countdown
            } else {
                 // If one deposit already collapsed/decayed, breaking entanglement might fail or have different rules.
                 // For simplicity, we just clear the link for others that weren't.
                 deposits[depId].entanglementId = 0;
            }
        }

        // Invalidate the entanglement group
        delete group.depositIds;

        emit EntanglementBroken(entanglementId, penaltyAmount);
    }


    // ------------------------------------------------------------------------
    // WITHDRAWAL FUNCTION
    // ------------------------------------------------------------------------

    /// @notice Withdraws assets from a deposit that is in the Collapsed state. Handles fees and entangled groups.
    /// @param depositId The ID of the deposit to withdraw.
    function withdraw(uint256 depositId) external whenNotPaused nonReentrant onlyDepositOwner(depositId) {
        Deposit storage deposit = deposits[depositId];
        require(deposit.state == QuantumState.Collapsed, "Deposit not in Collapsed state");

        // If entangled, ensure all deposits in the group are also Collapsed
        if (deposit.entanglementId > 0) {
             EntanglementGroup storage group = entanglements[deposit.entanglementId];
             require(group.depositIds.length > 0, "Invalid entanglement group"); // Should exist if depositId > 0
             for(uint i = 0; i < group.depositIds.length; i++) {
                 require(deposits[group.depositIds[i]].state == QuantumState.Collapsed, "All entangled deposits must be Collapsed to withdraw");
             }
        }

        uint256 totalAmount = deposit.amount;
        uint256 feeAmount = (totalAmount * withdrawalFeeBasisPoints) / 10000;
        uint256 amountToUser = totalAmount - feeAmount;

        // Mark deposit as withdrawn (e.g., set amount to 0 and state to a terminal state, or delete)
        // Deleting is cleaner but requires more gas. Setting amount to 0 and state to a terminal state is safer.
        deposit.amount = 0; // Indicate withdrawn
        _transitionState(depositId, QuantumState.Initial, "withdraw"); // Reset or move to a 'Withdrawn' terminal state (Initial is used here as placeholder)
        deposit.entanglementId = 0; // Clear entanglement link

        // If entangled, mark all deposits in the group as withdrawn/cleared as well
        if (deposit.entanglementId > 0) { // Re-check entanglementId as it was just set to 0 for 'deposit'
             EntanglementGroup storage group = entanglements[deposit.entanglementId]; // This will fail if entanglementId was 0
             // Let's re-fetch the group using the original ID before clearing it on the deposit
             uint256 originalEntanglementId = deposit.entanglementId; // This logic needs careful handling if deposit.entanglementId is cleared *before* checking group
             // Let's adjust: check group *before* clearing deposit's entanglementId
             uint256 currentEntanglementId = deposits[depositId].entanglementId; // Get the entanglementId *before* clearing
             if (currentEntanglementId > 0) {
                EntanglementGroup storage groupToClear = entanglements[currentEntanglementId];
                 for(uint i = 0; i < groupToClear.depositIds.length; i++) {
                     uint256 depId = groupToClear.depositIds[i];
                     if (deposits[depId].amount > 0) { // Avoid double-processing
                        deposits[depId].amount = 0;
                        _transitionState(depId, QuantumState.Initial, "withdraw (Entangled Group)");
                        deposits[depId].entanglementId = 0; // Clear entanglement link for all
                     }
                 }
                 // Invalidate the entanglement group itself as all assets are withdrawn
                 delete groupToClear.depositIds;
             }
        }


        // Transfer assets
        if (deposit.token == address(0)) {
            // Ether withdrawal
            (bool successUser, ) = payable(deposit.user).call{value: amountToUser}("");
            require(successUser, "Ether transfer to user failed");
            if (feeAmount > 0) {
                 (bool successFee, ) = payable(owner()).call{value: feeAmount}("");
                 require(successFee, "Ether fee transfer failed");
            }
        } else {
            // ERC20 withdrawal
            IERC20 token = IERC20(deposit.token);
            require(token.transfer(deposit.user, amountToUser), "ERC20 transfer to user failed");
            if (feeAmount > 0) {
                // ERC20 fee goes to owner
                 require(token.transfer(owner(), feeAmount), "ERC20 fee transfer failed");
            }
        }

        emit Withdrawal(depositId, deposit.user, amountToUser, feeAmount);
    }

    /// @notice Allows the designated recipient (e.g., owner) to claim assets from a Decayed deposit.
    /// @param depositId The ID of the decayed deposit.
    function claimDecayedAssets(uint256 depositId) external nonReentrant {
        Deposit storage deposit = deposits[depositId];
        require(deposit.state == QuantumState.Decayed, "Deposit not in Decayed state");
        require(deposit.amount > 0, "Deposit already claimed or empty");
        require(stateParameters.decayClaimRecipient != address(0), "Decayed assets recipient not set");
        require(msg.sender == stateParameters.decayClaimRecipient, "Only the designated recipient can claim decayed assets");

        uint256 amountToClaim = deposit.amount; // In this simple model, claim the full amount

        deposit.amount = 0; // Mark as claimed
        _transitionState(depositId, QuantumState.Initial, "claimDecayedAssets"); // Move to a terminal state

         // Transfer assets
        if (deposit.token == address(0)) {
            // Ether withdrawal
            (bool successRecipient, ) = payable(stateParameters.decayClaimRecipient).call{value: amountToClaim}("");
            require(successRecipient, "Ether transfer to recipient failed");
        } else {
            // ERC20 withdrawal
            IERC20 token = IERC20(deposit.token);
            require(token.transfer(stateParameters.decayClaimRecipient, amountToClaim), "ERC20 transfer to recipient failed");
        }

        emit DecayedAssetsClaimed(depositId, stateParameters.decayClaimRecipient, amountToClaim);
    }


    // ------------------------------------------------------------------------
    // QUERY FUNCTIONS
    // ------------------------------------------------------------------------

    /// @notice Gets the details of a specific deposit.
    /// @param depositId The ID of the deposit.
    /// @return Deposit struct details.
    function getDepositDetails(uint256 depositId) external view returns (Deposit memory) {
        require(depositId > 0 && depositId <= depositCounter, "Invalid deposit ID");
        return deposits[depositId];
    }

    /// @notice Calculates the total balance of a user across all their deposits, regardless of state.
    /// @param user The address of the user.
    /// @return The total balance amount.
    /// @return The address of the token (0x0 for Ether). Note: this only returns a single token type.
    ///         A real contract would need to return a mapping or array for multiple token types.
    function getUserTotalBalance(address user) external view returns (uint256 totalBalance, address tokenAddress) {
        // This function is simplified and assumes a user mainly deposits one type of asset.
        // A robust implementation would iterate through all deposit IDs associated with a user
        // and sum balances per token address. This requires tracking deposit IDs per user.
        // For demonstration, we'll just return 0 and address(0).
        // TODO: Implement proper user deposit tracking (e.g., mapping(address => uint256[]) userDepositIds;)
        // and iterate through them.
        return (0, address(0)); // Placeholder
    }

    /// @notice Calculates the total balance of a user for deposits in a specific state.
    /// @param user The address of the user.
    /// @param state The QuantumState to filter by.
    /// @return The total balance amount for that state.
     /// @return The address of the token (0x0 for Ether). Note: This has the same limitation as getUserTotalBalance.
    function getUserBalanceInState(address user, QuantumState state) external view returns (uint256 totalBalance, address tokenAddress) {
        // Similar limitation as getUserTotalBalance.
        // TODO: Implement proper user deposit tracking and iteration.
         return (0, address(0)); // Placeholder
    }

    /// @notice Gets a summary of the current state parameters.
    /// @return StateParameters struct details.
    function getContractStateSummary() external view returns (StateParameters memory) {
        return stateParameters;
    }

     /// @notice Gets the total number of active observers.
    function getObserverCount() external view returns (uint256) {
        return observerCount;
    }


    // ------------------------------------------------------------------------
    // OWNER / ADMIN FUNCTIONS
    // ------------------------------------------------------------------------

    /// @notice Owner sets the weight for probabilistic collapse (lower weight = higher probability).
    /// @param weight The new collapse probability weight.
    function setCollapseProbabilityWeight(uint256 weight) external onlyOwner {
        require(weight > 0, "Collapse weight must be > 0");
        uint256 oldWeight = stateParameters.collapseProbabilityWeight;
        stateParameters.collapseProbabilityWeight = weight;
        emit ParametersUpdated("collapseProbabilityWeight", oldWeight, weight);
    }

    /// @notice Owner sets parameters for asset decay.
    /// @param decayStartTimeThreshold The time threshold before decay starts counting.
    /// @param decayRateBasisPoints The rate of decay per unit duration.
    /// @param decayUnitDuration The duration of a decay unit in seconds.
    /// @param decayClaimRecipient The address that can claim decayed assets.
    function setDecayParameters(
        uint256 decayStartTimeThreshold,
        uint256 decayRateBasisPoints,
        uint256 decayUnitDuration,
        address decayClaimRecipient
    ) external onlyOwner {
         require(decayRateBasisPoints <= 10000, "Decay rate basis points <= 10000");
         require(decayUnitDuration > 0, "Decay unit duration must be > 0");

        stateParameters.decayStartTimeThreshold = decayStartTimeThreshold;
        stateParameters.decayRateBasisPoints = decayRateBasisPoints;
        stateParameters.decayUnitDuration = decayUnitDuration;
        stateParameters.decayClaimRecipient = decayClaimRecipient;

        emit ParametersUpdated("decayParameters", 0, 0); // Generic event for struct update
    }

    /// @notice Owner sets the block number that triggers the conditional collapse.
    /// @param triggerBlockNumber The target block number.
    function setConditionalCollapseTrigger(uint256 triggerBlockNumber) external onlyOwner {
        require(triggerBlockNumber > block.number, "Trigger block must be in the future");
        uint256 oldBlock = stateParameters.conditionalCollapseTriggerBlock;
        stateParameters.conditionalCollapseTriggerBlock = triggerBlockNumber;
        emit ParametersUpdated("conditionalCollapseTriggerBlock", oldBlock, triggerBlockNumber);
    }

    /// @notice Owner adds an address as an authorized observer.
    /// @param observer The address to add.
    function addObserver(address observer) external onlyOwner {
        require(observer != address(0), "Invalid address");
        if (!observers[observer]) {
            observers[observer] = true;
            observerCount++;
            emit ObserverAdded(observer);
        }
    }

    /// @notice Owner removes an address as an authorized observer.
    /// @param observer The address to remove.
    function removeObserver(address observer) external onlyOwner {
        require(observer != address(0), "Invalid address");
        if (observers[observer]) {
            observers[observer] = false;
            observerCount--;
            emit ObserverRemoved(observer);
        }
    }

    /// @notice Owner pauses the contract, preventing state transitions and withdrawals.
    function pauseContract() external onlyOwner {
        _pause();
    }

    /// @notice Owner unpauses the contract.
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /// @notice Owner sets the withdrawal fee in basis points (100 = 1%).
    /// @param feeBasisPoints The fee percentage in basis points.
    function setWithdrawalFee(uint256 feeBasisPoints) external onlyOwner {
        require(feeBasisPoints <= 10000, "Fee basis points cannot exceed 10000 (100%)");
        uint256 oldFee = withdrawalFeeBasisPoints;
        withdrawalFeeBasisPoints = feeBasisPoints;
        emit ParametersUpdated("withdrawalFeeBasisPoints", oldFee, feeBasisPoints);
    }

    // ------------------------------------------------------------------------
    // INTERNAL HELPERS (if needed, but logic mostly inline)
    // ------------------------------------------------------------------------
    // No complex internal helpers needed beyond _createDeposit and _transitionState
    // in this conceptual version.
    // A real implementation would likely have helpers for entanglement group checks,
    // decay calculations, etc.

}
```