Okay, let's design a smart contract that incorporates advanced concepts like a state machine based on external "proofs" (simulated), multi-party interaction for state transitions, conditional withdrawals based on the contract's state, and perhaps a time-based state reset mechanism, all wrapped in a "Quantum Vault" theme.

This contract won't *literally* use quantum computing, but the theme provides a framework for complex, non-linear state changes and access controls that are dependent on observing external conditions (simulated by hash proofs or timestamps) and potentially requiring multi-party consensus.

We'll avoid common open-source patterns like standard yield farming, simple staking, or typical ERC20/NFT implementations, focusing instead on novel state management and access control logic.

**Outline:**

1.  **Contract Name:** `QuantumVault`
2.  **Purpose:** A vault designed to hold various ERC20 tokens, where access (withdrawal) is governed by a complex internal state machine influenced by external inputs ("observations" / "proofs") and multi-party agreement.
3.  **Core Concepts:**
    *   **State Machine:** The vault exists in distinct states (e.g., Superposition, CollapsedAccess, EntangledState).
    *   **State Transitions:** Triggered by specific function calls (`collapseState`, `transitionToEntangledState`, `disentangleState`, `triggerSuperposition`).
    *   **External Proofs (Simulated):** State transitions and withdrawals require validation against pre-set "proof targets" (hashes). The actual proof generation/verification logic is assumed to happen off-chain or in other contracts; this contract verifies the resulting hash or simply requires a matching hash.
    *   **Observer Pattern & Threshold:** A set of designated "Observers" can initiate state transitions. Some transitions might require a minimum number of Observers to "agree" on the input within a timeframe.
    *   **Conditional Withdrawals:** Funds can only be withdrawn when the vault is in specific states (`CollapsedAccess`, `EntangledState`), and often require *additional* withdrawal-specific proofs.
    *   **Entanglement (Simulated):** A state requiring more complex conditions or proofs to enter/exit, potentially linking multiple internal or external factors.
    *   **Superposition (Simulated):** A default or reset state where withdrawals are generally locked, which can be triggered based on time.
    *   **Emergency Bypass:** A punitive withdrawal option in the `EntangledState`.
4.  **ERC20 Handling:** The contract will hold and manage specified ERC20 tokens.
5.  **Admin:** Basic ownership and configuration functions.

**Function Summary:**

*   **Admin & Setup:**
    1.  `constructor`: Initializes owner and initial state.
    2.  `transferOwnership`: Transfers contract ownership.
    3.  `setObserver`: Adds or removes an address from the list of approved Observers.
    4.  `isObserver`: Checks if an address is an Observer. (View)
    5.  `registerAllowedToken`: Owner specifies an ERC20 token address allowed in the vault.
    6.  `isAllowedToken`: Checks if a token is registered. (View)
    7.  `getRegisteredTokens`: Lists all registered tokens. (View)
*   **Vault Interaction (Deposits/Balances):**
    8.  `depositERC20`: Allows depositing registered ERC20 tokens into the vault.
    9.  `getVaultTokenBalance`: Gets the contract's balance of a specific registered token. (View)
    10. `getTotalRegisteredTokensCount`: Gets the number of unique registered tokens. (View)
*   **Quantum State Management:**
    11. `getCurrentVaultState`: Gets the current state of the vault. (View)
    12. `setCollapseProofTarget`: Owner sets the required hash for the `collapseState` transition.
    13. `getCollapseProofTarget`: Gets the current collapse proof target. (View)
    14. `collapseState`: Attempts to transition from `Superposition` to `CollapsedAccess` using a submitted proof hash. Requires Observer agreement threshold.
    15. `setEntanglementTriggerConditions`: Owner sets conditions (e.g., time lock, minimum value represented by hash) required to enter `EntangledState`.
    16. `getEntanglementTriggerConditions`: Gets the current entanglement trigger conditions. (View)
    17. `transitionToEntangledState`: Attempts to transition from `CollapsedAccess` to `EntangledState` if entanglement conditions are met. Requires Observer agreement threshold.
    18. `setDisentangleProofTarget`: Owner sets the required hash for the `disentangleState` transition.
    19. `getDisentangleProofTarget`: Gets the current disentangle proof target. (View)
    20. `disentangleState`: Attempts to transition from `EntangledState` back to `CollapsedAccess` using a submitted proof hash. Requires Observer agreement threshold.
    21. `setSuperpositionTriggerTimestamp`: Owner sets a timestamp after which `triggerSuperposition` can be called.
    22. `getSuperpositionTriggerTimestamp`: Gets the superposition trigger timestamp. (View)
    23. `triggerSuperposition`: Resets the vault state to `Superposition` if the trigger timestamp has passed. Can be called by anyone.
*   **Observer Agreement System:**
    24. `setObserverThreshold`: Owner sets the minimum number of Observer agreements needed for a specific state transition context.
    25. `getObserverThreshold`: Gets the threshold for a context. (View)
    26. `recordObserverAgreement`: Observers call this to record their agreement for a specific state transition context.
    27. `getObserverAgreementCount`: Gets the current count of agreements for a context. (View)
*   **Conditional Withdrawals:**
    28. `withdrawCollapsedAccess`: Allows withdrawal of registered tokens *only* in `CollapsedAccess` state, requiring a withdrawal-specific proof hash.
    29. `withdrawEntangledState`: Allows withdrawal of registered tokens *only* in `EntangledState` state, requiring a different type of withdrawal proof hash.
    30. `emergencyDisentangleWithdrawal`: Allows withdrawal of registered tokens *only* in `EntangledState` state without proof, but applies a penalty. Requires Observer agreement threshold *for this specific action*.
    31. `setEmergencyPenaltyAddress`: Owner sets the address to receive penalties from emergency withdrawals.
    32. `setEmergencyPenaltyPercentage`: Owner sets the percentage penalty for emergency withdrawals (e.g., 50 for 50%).
*   **Utilities:**
    33. `recoverAccidentallySentERC20`: Allows owner to recover ERC20 tokens *not* on the registered list if accidentally sent to the contract.

This structure gives us 33 functions, exceeding the requirement, and builds a creative system around state-dependent access, multi-party control, and proof-based logic.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title QuantumVault
 * @notice A creative smart contract simulating quantum-like state mechanics
 *         to control access to deposited ERC20 tokens. Access depends on
 *         state transitions triggered by "observations" (proof hashes)
 *         and potentially multi-observer consensus.
 *
 * @dev This contract uses quantum concepts metaphorically. It does not
 *      interact with actual quantum computing systems.
 *
 * Outline:
 * 1. Admin & Setup
 * 2. Vault Interaction (Deposits/Balances)
 * 3. Quantum State Management (State Machine, Transitions, Proofs)
 * 4. Observer Agreement System
 * 5. Conditional Withdrawals
 * 6. Utilities
 *
 * Function Summary:
 * - Admin & Setup: constructor, transferOwnership, setObserver, isObserver,
 *   registerAllowedToken, isAllowedToken, getRegisteredTokens.
 * - Vault Interaction: depositERC20, getVaultTokenBalance, getTotalRegisteredTokensCount.
 * - Quantum State Management: getCurrentVaultState, setCollapseProofTarget,
 *   getCollapseProofTarget, collapseState, setEntanglementTriggerConditions,
 *   getEntanglementTriggerConditions, transitionToEntangledState,
 *   setDisentangleProofTarget, getDisentangleProofTarget, disentangleState,
 *   setSuperpositionTriggerTimestamp, getSuperpositionTriggerTimestamp,
 *   triggerSuperposition.
 * - Observer Agreement System: setObserverThreshold, getObserverThreshold,
 *   recordObserverAgreement, getObserverAgreementCount.
 * - Conditional Withdrawals: withdrawCollapsedAccess, withdrawEntangledState,
 *   emergencyDisentangleWithdrawal, setEmergencyPenaltyAddress, setEmergencyPenaltyPercentage.
 * - Utilities: recoverAccidentallySentERC20.
 */
contract QuantumVault is Ownable, ReentrancyGuard {

    // --- Events ---
    event VaultStateChanged(VaultState indexed newState, address indexed triggeredBy);
    event ObserverAdded(address indexed observer);
    event ObserverRemoved(address indexed observer);
    event TokenRegistered(address indexed token);
    event TokenDeposit(address indexed token, address indexed depositor, uint256 amount);
    event TokenWithdrawal(address indexed token, address indexed recipient, uint256 amount, string withdrawalType);
    event CollapseProofTargetSet(bytes32 targetHash);
    event EntanglementTriggerConditionsSet(uint256 minTime, bytes32 minProofValueHash);
    event DisentangleProofTargetSet(bytes32 targetHash);
    event SuperpositionTriggerTimestampSet(uint256 timestamp);
    event ObserverThresholdSet(bytes32 indexed contextHash, uint256 threshold);
    event ObserverAgreed(bytes32 indexed contextHash, address indexed observer);
    event EmergencyPenaltyAddressSet(address penaltyAddress);
    event EmergencyPenaltyPercentageSet(uint256 percentage);
    event EmergencyWithdrawalPenaltyPaid(address indexed recipient, uint256 amount);
    event RecoveredERC20(address indexed token, uint256 amount, address indexed recipient);


    // --- Errors ---
    error InvalidStateTransition(VaultState currentState, VaultState targetState);
    error InvalidProof(bytes32 submittedHash, bytes32 requiredHash);
    error NotAnObserver();
    error TokenNotRegistered(address token);
    error InsufficientVaultBalance(address token, uint256 requested, uint256 available);
    error EntanglementConditionsNotMet();
    error SuperpositionTriggerNotPassed(uint256 triggerTime);
    error ObserverThresholdNotMet(bytes32 contextHash, uint256 required, uint256 current);
    error NoObserverAgreementRecorded(bytes32 contextHash, address observer);
    error AlreadyAgreed(bytes32 contextHash, address observer);
    error ContextNotFound();
    error PenaltyPercentageTooHigh();
    error ZeroAddressNotAllowed();
    error CannotRecoverRegisteredToken(address token);

    // --- State Variables ---

    // Defines the possible states of the vault
    enum VaultState {
        Superposition,        // Default state: generally locked, awaits collapse
        CollapsedAccess,      // State after 'observation', conditional withdrawal possible
        EntangledState        // State requiring complex conditions, different withdrawal rules
    }

    VaultState public currentVaultState;

    // List of allowed ERC20 tokens managed by the vault
    mapping(address => bool) public registeredTokens;
    address[] internal _registeredTokensList; // To easily list registered tokens

    // Balances of registered tokens held by this contract
    mapping(address => uint256) internal heldTokens;

    // Addresses authorized to act as Observers
    mapping(address => bool) public isObserver;

    // State transition proof targets (hashes of assumed external proofs)
    bytes32 public collapseProofTarget;
    bytes32 public disentangleProofTarget;

    // Conditions required to enter EntangledState
    struct EntanglementConditions {
        uint256 minTriggerTimestamp;
        // bytes32 minProofValueHash; // Could add more complex conditions here
        bool isSet; // Flag to indicate if conditions have been configured
    }
    EntanglementConditions public entanglementTriggerConditions;

    // Timestamp after which triggerSuperposition can be called
    uint256 public superpositionTriggerTimestamp;

    // Observer Agreement System
    // Maps context hash => observer address => bool (has agreed)
    mapping(bytes32 => mapping(address => bool)) internal _observerAgreements;
    // Maps context hash => count of agreements
    mapping(bytes32 => uint256) internal _agreementCounts;
    // Maps context hash => required threshold
    mapping(bytes32 => uint256) internal _observerThresholds;
    // Context hashes for specific state transitions
    bytes32 public constant CONTEXT_COLLAPSE_STATE = keccak256("CONTEXT_COLLAPSE_STATE");
    bytes32 public constant CONTEXT_ENTANGLE_STATE = keccak256("CONTEXT_ENTANGLE_STATE");
    bytes32 public constant CONTEXT_DISENTANGLE_STATE = keccak256("CONTEXT_DISENTANGLE_STATE");
    bytes32 public constant CONTEXT_EMERGENCY_WITHDRAW = keccak256("CONTEXT_EMERGENCY_WITHDRAW");


    // Emergency Withdrawal Penalty
    address public emergencyPenaltyAddress;
    uint256 public emergencyPenaltyPercentage; // Stored as value from 0 to 100

    // --- Modifiers ---
    modifier onlyObserver() {
        if (!isObserver[msg.sender]) {
            revert NotAnObserver();
        }
        _;
    }

    modifier onlyRegisteredToken(address _token) {
        if (!registeredTokens[_token]) {
            revert TokenNotRegistered(_token);
        }
        _;
    }

    modifier inState(VaultState _requiredState) {
        if (currentVaultState != _requiredState) {
            revert InvalidStateTransition(currentVaultState, _requiredState);
        }
        _;
    }

    modifier needsObserverThreshold(bytes32 _contextHash) {
         if (_observerThresholds[_contextHash] == 0) {
             // Threshold not set, allow if context exists
             // Or decide that threshold must be set if context exists.
             // Let's require threshold > 0 if the context hash is used for transitions.
             // If 0, implies feature is disabled or no threshold needed (single observer okay)
         } else {
             if (_agreementCounts[_contextHash] < _observerThresholds[_contextHash]) {
                revert ObserverThresholdNotMet(_contextHash, _observerThresholds[_contextHash], _agreementCounts[_contextHash]);
            }
         }
        _;
    }


    // --- Constructor ---
    constructor(address initialObserver) Ownable(msg.sender) ReentrancyGuard() {
        if (initialObserver == address(0)) revert ZeroAddressNotAllowed();
        isObserver[initialObserver] = true;
        emit ObserverAdded(initialObserver);
        currentVaultState = VaultState.Superposition; // Start in Superposition state
        emit VaultStateChanged(currentVaultState, msg.sender);

        // Set default thresholds (can be changed by owner)
        _observerThresholds[CONTEXT_COLLAPSE_STATE] = 1; // Minimum 1 observer needed to initiate collapse
        _observerThresholds[CONTEXT_ENTANGLE_STATE] = 1;
        _observerThresholds[CONTEXT_DISENTANGLE_STATE] = 1;
        _observerThresholds[CONTEXT_EMERGENCY_WITHDRAW] = 1; // Minimum 1 observer needed to approve emergency withdrawal
    }

    // --- Admin & Setup ---

    // 1. constructor - See above

    // 2. transferOwnership - Inherited from Ownable

    /**
     * @notice Adds or removes an address from the approved Observers list.
     * @param _observer The address to modify.
     * @param _isObserver Boolean indicating whether to add (true) or remove (false).
     */
    function setObserver(address _observer, bool _isObserver) external onlyOwner {
        if (_observer == address(0)) revert ZeroAddressNotAllowed();
        if (isObserver[_observer] == _isObserver) return; // No change

        isObserver[_observer] = _isObserver;
        if (_isObserver) {
            emit ObserverAdded(_observer);
        } else {
            emit ObserverRemoved(_observer);
        }
    }

    // 4. isObserver - Public state variable accessor

    /**
     * @notice Registers an ERC20 token address, allowing it to be deposited and managed.
     * @param _token The address of the ERC20 token.
     */
    function registerAllowedToken(address _token) external onlyOwner {
        if (_token == address(0)) revert ZeroAddressNotAllowed();
        if (!registeredTokens[_token]) {
            registeredTokens[_token] = true;
            _registeredTokensList.push(_token);
            emit TokenRegistered(_token);
        }
    }

    // 6. isAllowedToken - Public state variable accessor

    /**
     * @notice Gets the list of all registered ERC20 token addresses.
     * @return A dynamic array of registered token addresses.
     */
    function getRegisteredTokens() external view returns (address[] memory) {
        return _registeredTokensList;
    }

    // --- Vault Interaction ---

    /**
     * @notice Deposits a specified amount of a registered ERC20 token into the vault.
     * @param _token The address of the registered ERC20 token.
     * @param _amount The amount of tokens to deposit.
     */
    function depositERC20(address _token, uint256 _amount) external nonReentrant onlyRegisteredToken(_token) {
        if (_amount == 0) return;
        // Ensure the contract has allowance to pull the tokens
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        heldTokens[_token] += _amount;
        emit TokenDeposit(_token, msg.sender, _amount);
    }

    /**
     * @notice Gets the vault's balance for a specific registered ERC20 token.
     * @param _token The address of the registered ERC20 token.
     * @return The balance of the token held in the vault.
     */
    function getVaultTokenBalance(address _token) external view onlyRegisteredToken(_token) returns (uint256) {
        return heldTokens[_token];
    }

    /**
     * @notice Gets the total number of *types* of registered tokens held in the vault.
     * @dev This counts the number of registered tokens, not the total sum of token values.
     * @return The count of unique registered token addresses.
     */
    function getTotalRegisteredTokensCount() external view returns (uint256) {
        return _registeredTokensList.length;
    }

    // --- Quantum State Management ---

    // 11. getCurrentVaultState - Public state variable accessor

    /**
     * @notice Sets the target hash required for the `collapseState` function.
     * @param _targetHash The new target proof hash.
     */
    function setCollapseProofTarget(bytes32 _targetHash) external onlyOwner {
        collapseProofTarget = _targetHash;
        emit CollapseProofTargetSet(_targetHash);
    }

    // 13. getCollapseProofTarget - Public state variable accessor

    /**
     * @notice Attempts to transition the vault state from `Superposition` to `CollapsedAccess`.
     * @dev This simulates an "observation" that collapses the quantum state.
     *      Requires the submitted proof hash to match the `collapseProofTarget`.
     *      Requires the configured observer threshold for `CONTEXT_COLLAPSE_STATE` to be met.
     *      Calling this function *consumes* the observer agreements for this context.
     * @param _proofHash The hash of the external proof or observation data.
     */
    function collapseState(bytes32 _proofHash) external nonReentrant inState(VaultState.Superposition) needsObserverThreshold(CONTEXT_COLLAPSE_STATE) onlyObserver {
        if (_proofHash != collapseProofTarget) {
            revert InvalidProof(_proofHash, collapseProofTarget);
        }

        // Reset agreements for this context after successful transition
        delete _observerAgreements[CONTEXT_COLLAPSE_STATE];
        _agreementCounts[CONTEXT_COLLAPSE_STATE] = 0;

        currentVaultState = VaultState.CollapsedAccess;
        emit VaultStateChanged(currentVaultState, msg.sender);
    }

    /**
     * @notice Sets the conditions required for the `transitionToEntangledState` function.
     * @param _minTriggerTimestamp The minimum timestamp required to enter the entangled state.
     * @dev More complex conditions could be added here in a real-world scenario.
     */
    function setEntanglementTriggerConditions(uint256 _minTriggerTimestamp) external onlyOwner {
        entanglementTriggerConditions = EntanglementConditions({
            minTriggerTimestamp: _minTriggerTimestamp,
            isSet: true
        });
        emit EntanglementTriggerConditionsSet(_minTriggerTimestamp, bytes32(0)); // Add second param if more conditions are added
    }

     // 16. getEntanglementTriggerConditions - Public state variable accessor

    /**
     * @notice Attempts to transition the vault state from `CollapsedAccess` to `EntangledState`.
     * @dev This simulates entanglement based on pre-set conditions.
     *      Requires the configured `entanglementTriggerConditions` to be met.
     *      Requires the configured observer threshold for `CONTEXT_ENTANGLE_STATE` to be met.
     *      Calling this function *consumes* the observer agreements for this context.
     */
    function transitionToEntangledState() external nonReentrant inState(VaultState.CollapsedAccess) needsObserverThreshold(CONTEXT_ENTANGLE_STATE) onlyObserver {
        if (!entanglementTriggerConditions.isSet) {
             // Entanglement conditions must be set first
             revert ContextNotFound(); // Using this error for simplicity, indicates conditions not configured
        }
        if (block.timestamp < entanglementTriggerConditions.minTriggerTimestamp) {
            revert EntanglementConditionsNotMet();
        }
        // Add checks for other conditions if they were included (e.g., minProofValueHash)

        // Reset agreements for this context after successful transition
        delete _observerAgreements[CONTEXT_ENTANGLE_STATE];
        _agreementCounts[CONTEXT_ENTANGLE_STATE] = 0;

        currentVaultState = VaultState.EntangledState;
        emit VaultStateChanged(currentVaultState, msg.sender);
    }

    /**
     * @notice Sets the target hash required for the `disentangleState` function.
     * @param _targetHash The new target proof hash.
     */
    function setDisentangleProofTarget(bytes32 _targetHash) external onlyOwner {
        disentangleProofTarget = _targetHash;
        emit DisentangleProofTargetSet(_targetHash);
    }

    // 19. getDisentangleProofTarget - Public state variable accessor

    /**
     * @notice Attempts to transition the vault state from `EntangledState` back to `CollapsedAccess`.
     * @dev This simulates disentanglement based on a specific observation/proof.
     *      Requires the submitted proof hash to match the `disentangleProofTarget`.
     *      Requires the configured observer threshold for `CONTEXT_DISENTANGLE_STATE` to be met.
     *      Calling this function *consumes* the observer agreements for this context.
     * @param _proofHash The hash of the external proof or observation data.
     */
    function disentangleState(bytes32 _proofHash) external nonReentrant inState(VaultState.EntangledState) needsObserverThreshold(CONTEXT_DISENTANGLE_STATE) onlyObserver {
        if (_proofHash != disentangleProofTarget) {
            revert InvalidProof(_proofHash, disentangleProofTarget);
        }

        // Reset agreements for this context after successful transition
        delete _observerAgreements[CONTEXT_DISENTANGLE_STATE];
        _agreementCounts[CONTEXT_DISENTANGLE_STATE] = 0;

        currentVaultState = VaultState.CollapsedAccess;
        emit VaultStateChanged(currentVaultState, msg.sender);
    }

    /**
     * @notice Sets the timestamp after which the vault can be reset to `Superposition`.
     * @param _timestamp The future Unix timestamp. Set to 0 to disable.
     */
    function setSuperpositionTriggerTimestamp(uint256 _timestamp) external onlyOwner {
         superpositionTriggerTimestamp = _timestamp;
         emit SuperpositionTriggerTimestampSet(_timestamp);
    }

    // 22. getSuperpositionTriggerTimestamp - Public state variable accessor

    /**
     * @notice Resets the vault state to `Superposition` if the `superpositionTriggerTimestamp` has passed.
     * @dev This simulates a natural return to superposition over time. Can be called by anyone.
     */
    function triggerSuperposition() external nonReentrant {
        if (superpositionTriggerTimestamp == 0 || block.timestamp < superpositionTriggerTimestamp) {
            revert SuperpositionTriggerNotPassed(superpositionTriggerTimestamp);
        }

        // Reset state-specific variables when returning to Superposition
        // Note: Proof targets and entanglement conditions persist until explicitly reset by owner.
        // Observer agreements *could* be reset here too, depending on desired logic.
        // For simplicity, let's keep agreements tied to specific contexts.

        currentVaultState = VaultState.Superposition;
        emit VaultStateChanged(currentVaultState, msg.sender);
    }

    // --- Observer Agreement System ---

    /**
     * @notice Sets the minimum number of Observer agreements required for a specific context hash.
     * @param _contextHash The context identifier (e.g., CONTEXT_COLLAPSE_STATE).
     * @param _threshold The minimum number of distinct Observers required to call `recordObserverAgreement`. Set to 0 to disable threshold for this context.
     */
    function setObserverThreshold(bytes32 _contextHash, uint256 _threshold) external onlyOwner {
        if (_contextHash == bytes32(0)) revert ContextNotFound();
        _observerThresholds[_contextHash] = _threshold;
        emit ObserverThresholdSet(_contextHash, _threshold);
    }

    // 25. getObserverThreshold - Public state variable accessor using mapping access: _observerThresholds[_contextHash]

    /**
     * @notice An Observer calls this function to record their agreement for a specific context (state transition, emergency action, etc.).
     * @dev Requires the caller to be an Observer. An Observer can only agree once per context.
     * @param _contextHash The context identifier they are agreeing to.
     */
    function recordObserverAgreement(bytes32 _contextHash) external onlyObserver {
        if (_contextHash == bytes32(0)) revert ContextNotFound();
        if (_observerAgreements[_contextHash][msg.sender]) {
            revert AlreadyAgreed(_contextHash, msg.sender);
        }

        _observerAgreements[_contextHash][msg.sender] = true;
        _agreementCounts[_contextHash]++;
        emit ObserverAgreed(_contextHash, msg.sender);
    }

    /**
     * @notice Gets the current count of Observer agreements for a specific context.
     * @param _contextHash The context identifier.
     * @return The number of Observers who have called `recordObserverAgreement` for this context.
     */
    function getObserverAgreementCount(bytes32 _contextHash) external view returns (uint256) {
        return _agreementCounts[_contextHash];
    }


    // --- Conditional Withdrawals ---

    /**
     * @notice Allows withdrawal of registered tokens when the vault is in `CollapsedAccess` state.
     * @dev Requires a withdrawal-specific proof hash to be provided. The actual verification
     *      logic for this proof (e.g., Merkle proof) is assumed to be off-chain or verified
     *      against a different contract. This function only checks if the provided hash
     *      matches a pre-set target (which the owner/observers would update based on
     *      valid off-chain withdrawal requests/proofs). *Simplified: we'll just require a non-zero hash here.*
     * @param _token The address of the registered ERC20 token.
     * @param _amount The amount to withdraw.
     * @param _withdrawalProofHash The hash of the proof authorizing this specific withdrawal.
     */
    function withdrawCollapsedAccess(address _token, uint256 _amount, bytes32 _withdrawalProofHash) external nonReentrant inState(VaultState.CollapsedAccess) onlyRegisteredToken(_token) {
        if (_amount == 0) return;
        if (heldTokens[_token] < _amount) {
            revert InsufficientVaultBalance(_token, _amount, heldTokens[_token]);
        }
        // --- Proof Validation (Simplified) ---
        // In a real system, this would involve verifying a Merkle proof,
        // cryptographic signature, or checking against an oracle/other contract state.
        // Here, we just require a non-zero hash to represent that *a* proof was provided.
        // A more advanced version would compare this to a stored/calculated target hash.
        if (_withdrawalProofHash == bytes32(0)) {
            // Revert or handle cases where proof is mandatory
             revert InvalidProof(bytes32(0), bytes32(1)); // Indicate proof was required
        }
        // --- End Proof Validation ---

        heldTokens[_token] -= _amount;
        IERC20(_token).transfer(msg.sender, _amount);
        emit TokenWithdrawal(_token, msg.sender, _amount, "CollapsedAccess");
    }

    /**
     * @notice Allows withdrawal of registered tokens when the vault is in `EntangledState`.
     * @dev Requires a different type of withdrawal proof hash. Similar simplification
     *      as `withdrawCollapsedAccess` proof validation.
     * @param _token The address of the registered ERC20 token.
     * @param _amount The amount to withdraw.
     * @param _entanglementProofHash The hash of the proof authorizing this withdrawal in the entangled state.
     */
    function withdrawEntangledState(address _token, uint256 _amount, bytes32 _entanglementProofHash) external nonReentrant inState(VaultState.EntangledState) onlyRegisteredToken(_token) {
        if (_amount == 0) return;
         if (heldTokens[_token] < _amount) {
            revert InsufficientVaultBalance(_token, _amount, heldTokens[_token]);
        }
         // --- Proof Validation (Simplified) ---
        if (_entanglementProofHash == bytes32(0)) {
            revert InvalidProof(bytes32(0), bytes32(1)); // Indicate proof was required
        }
        // --- End Proof Validation ---

        heldTokens[_token] -= _amount;
        IERC20(_token).transfer(msg.sender, _amount);
        emit TokenWithdrawal(_token, msg.sender, _amount, "EntangledState");
    }

    /**
     * @notice Allows withdrawal from `EntangledState` *without* a specific withdrawal proof,
     *         but applies a significant penalty.
     * @dev Requires the configured observer threshold for `CONTEXT_EMERGENCY_WITHDRAW` to be met.
     *      Intended as an emergency escape valve with economic cost.
     *      Calling this function *consumes* the observer agreements for this context.
     * @param _token The address of the registered ERC20 token.
     * @param _amount The total amount requested (penalty calculated from this).
     */
    function emergencyDisentangleWithdrawal(address _token, uint256 _amount) external nonReentrant inState(VaultState.EntangledState) onlyRegisteredToken(_token) needsObserverThreshold(CONTEXT_EMERGENCY_WITHDRAW) onlyObserver {
        if (_amount == 0) return;
         if (heldTokens[_token] < _amount) {
            revert InsufficientVaultBalance(_token, _amount, heldTokens[_token]);
        }
        if (emergencyPenaltyAddress == address(0)) revert ZeroAddressNotAllowed(); // Penalty address must be set
        if (emergencyPenaltyPercentage > 100) revert PenaltyPercentageTooHigh(); // Should be set by owner, but defensive check

        uint256 penaltyAmount = (_amount * emergencyPenaltyPercentage) / 100;
        uint256 netAmount = _amount - penaltyAmount;

        // Reset agreements for this context after successful action
        delete _observerAgreements[CONTEXT_EMERGENCY_WITHDRAW];
        _agreementCounts[CONTEXT_EMERGENCY_WITHDRAW] = 0;

        heldTokens[_token] -= _amount; // Deduct the full amount from internal balance

        // Transfer net amount to withdrawer
        if (netAmount > 0) {
            IERC20(_token).transfer(msg.sender, netAmount);
            emit TokenWithdrawal(_token, msg.sender, netAmount, "Emergency");
        }

        // Transfer penalty to penalty address
        if (penaltyAmount > 0) {
             IERC20(_token).transfer(emergencyPenaltyAddress, penaltyAmount);
             emit EmergencyWithdrawalPenaltyPaid(emergencyPenaltyAddress, penaltyAmount);
        }
    }

     /**
     * @notice Sets the address to receive penalties from emergency withdrawals.
     * @param _penaltyAddress The address that receives penalty tokens.
     */
    function setEmergencyPenaltyAddress(address _penaltyAddress) external onlyOwner {
        if (_penaltyAddress == address(0)) revert ZeroAddressNotAllowed();
        emergencyPenaltyAddress = _penaltyAddress;
        emit EmergencyPenaltyAddressSet(_penaltyAddress);
    }

    /**
     * @notice Sets the percentage of the withdrawal amount taken as penalty during emergency withdrawal.
     * @param _percentage The penalty percentage (0-100).
     */
    function setEmergencyPenaltyPercentage(uint256 _percentage) external onlyOwner {
        if (_percentage > 100) revert PenaltyPercentageTooHigh();
        emergencyPenaltyPercentage = _percentage;
        emit EmergencyPenaltyPercentageSet(_percentage);
    }


    // --- Utilities ---

    /**
     * @notice Allows the owner to recover ERC20 tokens accidentally sent to the contract
     *         that are *not* on the registered list.
     * @dev Prevents draining registered tokens.
     * @param _token The address of the ERC20 token to recover.
     * @param _amount The amount to recover.
     */
    function recoverAccidentallySentERC20(address _token, uint256 _amount) external onlyOwner nonReentrant {
        if (_token == address(0)) revert ZeroAddressNotAllowed();
        if (registeredTokens[_token]) {
            revert CannotRecoverRegisteredToken(_token);
        }
        if (_amount == 0) return;

        uint256 contractTokenBalance = IERC20(_token).balanceOf(address(this));
        if (contractTokenBalance < _amount) {
             // Or just transfer the whole balance if amount is too high
             _amount = contractTokenBalance;
             if (_amount == 0) return; // Nothing to recover
        }

        IERC20(_token).transfer(msg.sender, _amount);
        emit RecoveredERC20(_token, _amount, msg.sender);
    }
}
```