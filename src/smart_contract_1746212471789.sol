Okay, let's design a smart contract inspired by the concepts of quantum mechanics, specifically superposition, measurement, collapse, and tunneling, applied metaphorically to managing assets.

The core idea is a vault where assets are deposited (Superposition state). The potential final state of these assets (who gets what) is uncertain and can be one of multiple defined possibilities (Outcomes). A "measurement" process evaluates external conditions. Once a specific condition is met, the state "collapses" into a single, determined Outcome, and assets become claimable according to that outcome. There's also a "tunneling" mechanism allowing assets to be retrieved via an alternative path if the measurement process doesn't conclude within certain parameters.

This contract will be called `QuantumVault`. It will handle ERC20 tokens.

---

## QuantumVault Smart Contract Outline

1.  **License and Pragma**
2.  **Imports:** ERC20 interface.
3.  **Enums:** Define possible states of the vault (`VaultState`).
4.  **Structs:** Define data structures for `Distribution` (recipient, percentage) and `VaultOutcome` (description, distribution list).
5.  **State Variables:** Store vault state, owner, supported tokens, deposited balances, outcomes, measurement conditions, observer roles, tunneling parameters, final outcome ID, claimed status.
6.  **Events:** Announce state changes, deposits, outcome proposals, measurement initiation/completion, collapse, claims, tunneling.
7.  **Modifiers:** Custom modifiers for access control (`onlyOwner`, `onlyObserver`) and state checks (`whenState`).
8.  **Core Logic:**
    *   `constructor`: Initialize owner and initial state.
    *   `addSupportedToken`: Define which tokens can be deposited.
    *   `depositERC20`: Allow users to deposit supported tokens into the vault.
    *   `proposeOutcome`: Define a potential distribution outcome.
    *   `activateOutcomes`: Transition from configuring to accepting deposits (Superposition).
    *   `setMeasurementConditions`: Link external conditions (represented by IDs) to specific outcomes.
    *   `addObserver`/`removeObserver`: Manage addresses allowed to report condition status.
    *   `startMeasurement`: Transition from Superposition to Measuring. Deposits are locked.
    *   `verifyCondition`: (Observer only) Report the status (met/not met) of a specific condition ID.
    *   `finalizeMeasurement`: Trigger evaluation of verified conditions. If a unique outcome condition is met, collapse the state and distribute internally.
    *   `claimAssets`: Allow recipients of the final outcome to claim their allocated assets.
    *   `pauseMeasurement`/`unpauseMeasurement`: Emergency pause/resume for the measurement process.
    *   `setTunnelingDistribution`: Define the distribution rule if tunneling occurs.
    *   `triggerTunneling`: Initiate the tunneling process based on predefined conditions (e.g., timeout, consensus).
9.  **Internal Functions:** Helper functions like `_distributeAssets` (for collapse), `_distributeTunneling` (for tunneling), state transition logic.
10. **Utility and Getter Functions:**
    *   `getCurrentState`: Get the current state of the vault.
    *   `getFinalOutcomeId`: Get the ID of the outcome chosen after collapse.
    *   `isRecipientClaimed`: Check if a recipient has claimed for a specific asset.
    *   `getPotentialRecipients`: List unique addresses potentially receiving assets.
    *   `getOutcomeDistribution`: Get the distribution details for a specific outcome ID.
    *   `getDepositedAmount`: Get the total deposited amount for a specific token.
    *   `getOutcomeCount`: Get the number of activated outcomes.
    *   `getSupportedTokens`: Get the list of supported token addresses.
    *   `getObserverStatus`: Check if an address is an observer.
    *   `getTunnelingDistribution`: Get the distribution details for tunneling.
    *   `checkConditionStatus`: Get the reported status of a specific condition ID.
    *   `getMeasurementStartTime`: Get the timestamp when measurement started.
    *   `getTunnelingTimeout`: Get the configured tunneling timeout.
    *   `getRecipientClaimableAmount`: Calculate the remaining claimable amount for a recipient for a specific token.
    *   `getRecipientTotalAllocation`: Calculate the total amount allocated to a recipient for a specific token in the final outcome.

---

## Function Summary

*   **Configuration & Setup:**
    *   `constructor()`: Initializes the contract, sets the owner, and sets the initial state to `Configuring`.
    *   `addSupportedToken(address tokenAddress)`: Allows the owner to specify ERC20 tokens that can be deposited.
    *   `proposeOutcome(string memory description, Distribution[] memory distribution)`: Allows the owner to define a potential way the vault's assets could be distributed. Distribution is specified in basis points (1/100th of a percent). Total basis points for an outcome must sum to 10000.
    *   `activateOutcomes()`: Transitions the state from `Configuring` to `Superposition`, making the proposed outcomes potentially active and enabling deposits. Requires at least one outcome to be proposed.
    *   `setMeasurementConditions(bytes32[] memory conditionIds, uint256[] memory outcomeIds)`: Links external condition identifiers to specific activated outcomes. Only one outcome can be linked per condition ID.
    *   `addObserver(address observer)`: Grants an address the `onlyObserver` role, allowing them to report condition statuses.
    *   `removeObserver(address observer)`: Revokes the `onlyObserver` role.
    *   `setTunnelingDistribution(Distribution[] memory distribution)`: Defines how assets will be distributed if the tunneling mechanism is triggered. Total basis points must sum to 10000.
*   **Deposit:**
    *   `depositERC20(address tokenAddress, uint256 amount)`: Allows users to deposit supported ERC20 tokens into the vault. Only permitted in the `Superposition` state.
*   **Measurement & Collapse:**
    *   `startMeasurement(uint256 tunnelingTimeoutSeconds)`: Transitions the state from `Superposition` to `Measuring`, locking further deposits and starting a timer for the tunneling timeout. Owner sets the timeout duration.
    *   `verifyCondition(bytes32 conditionId, bool status)`: (Observer only) Reports whether a specific condition associated with an outcome has been met (`true`) or not (`false`). Requires `Measuring` state.
    *   `finalizeMeasurement()`: Public function that checks the reported condition statuses. If exactly one condition linked to an activated outcome has been verified as `true`, the state transitions to `Collapsed`, the corresponding outcome is chosen, and the internal distribution process begins (`_distributeAssets`).
    *   `pauseMeasurement()`: (Owner only) Pauses the measurement process, preventing new condition verifications or finalization.
    *   `unpauseMeasurement()`: (Owner only) Resumes the measurement process.
*   **Distribution & Claim:**
    *   `claimAssets(address tokenAddress)`: Allows a recipient defined in the chosen `Collapsed` or `Tunneled` outcome to claim their allocated amount of a specific token.
*   **Tunneling:**
    *   `triggerTunneling()`: Callable by anyone. Checks if the tunneling conditions are met (e.g., measurement timeout elapsed *or* a sufficient number of observers have voted to tunnel - configurable). If met, transitions state to `Tunneled` and distributes assets according to `tunnelingDistribution` (`_distributeTunneling`). Requires `Measuring` state.
*   **Utility & Getters (Read-only):**
    *   `getCurrentState()`: Returns the current state enum value.
    *   `getFinalOutcomeId()`: Returns the ID of the outcome chosen after state collapse (if any).
    *   `isRecipientClaimed(address tokenAddress, address recipient)`: Checks if a specific recipient has claimed a specific token.
    *   `getPotentialRecipients()`: Returns a list of all unique addresses defined as recipients across all proposed outcomes and the tunneling distribution.
    *   `getOutcomeDistribution(uint256 outcomeId)`: Returns the distribution details for a specific outcome ID.
    *   `getDepositedAmount(address tokenAddress)`: Returns the total balance of a specific token held by the vault contract.
    *   `getOutcomeCount()`: Returns the total number of proposed outcomes.
    *   `getSupportedTokens()`: Returns the list of ERC20 token addresses supported for deposit.
    *   `getObserverStatus(address observer)`: Returns true if the address is an observer.
    *   `getTunnelingDistribution()`: Returns the distribution details defined for tunneling.
    *   `checkConditionStatus(bytes32 conditionId)`: Returns the verification status of a condition ID (unverified, true, or false).
    *   `getMeasurementStartTime()`: Returns the timestamp when `startMeasurement` was called.
    *   `getTunnelingTimeout()`: Returns the duration of the tunneling timeout.
    *   `getRecipientClaimableAmount(address tokenAddress, address recipient)`: Calculates the amount of a token a recipient can still claim based on the final state.
    *   `getRecipientTotalAllocation(address tokenAddress, address recipient)`: Calculates the total amount allocated to a recipient for a token in the final state.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

/**
 * @title QuantumVault
 * @dev A smart contract vault inspired by quantum mechanics:
 *      Assets are held in a state of 'Superposition' (multiple potential outcomes).
 *      An external 'Measurement' process evaluates conditions.
 *      If a condition is met, the state 'Collapses' to a single outcome.
 *      Assets are then claimable according to the chosen outcome.
 *      A 'Tunneling' mechanism provides an alternative exit if measurement fails or times out.
 *      Uses ERC20 tokens.
 */
contract QuantumVault {

    /*
     * --- Enums ---
     */

    enum VaultState {
        Empty,           // Initial state, nothing configured or deposited
        Configuring,     // Owner is setting up supported tokens, outcomes, conditions
        Superposition,   // Outcomes are set, deposits are open
        Measuring,       // Deposits locked, observers can verify conditions, tunneling timeout active
        Paused,          // Measurement paused by owner
        Collapsed,       // A unique outcome was determined by measurement, assets claimable
        Tunneled         // Tunneling conditions met, assets claimable via tunneling rules
    }

    enum ConditionStatus {
        Unverified, // Condition status not yet reported
        Met,        // Condition reported as true
        NotMet      // Condition reported as false
    }

    /*
     * --- Structs ---
     */

    struct Distribution {
        address recipient;
        uint16 percentageBasisPoints; // Percentage out of 10000 (100%)
    }

    struct VaultOutcome {
        uint256 id;
        string description;
        Distribution[] distribution;
        bool activated; // True when outcome is ready for selection after configuration
    }

    /*
     * --- State Variables ---
     */

    VaultState public currentState;
    address private _owner;

    // Configuration
    mapping(address => bool) public isSupportedToken;
    address[] private _supportedTokens;
    uint256 private _nextOutcomeId;
    mapping(uint256 => VaultOutcome) public outcomes; // outcomeId => Outcome
    mapping(bytes32 => uint256) public conditionOutcomeMap; // conditionId => outcomeId
    Distribution[] public tunnelingDistribution; // Distribution if tunneling occurs

    // Deposit State (Superposition / Measuring / Paused)
    mapping(address => uint256) private _totalVaultBalances; // tokenAddress => total balance

    // Measurement State (Measuring / Paused)
    mapping(address => bool) public isObserver; // observerAddress => status
    bytes32[] private _activeConditionIds; // List of condition IDs mapped to outcomes
    mapping(bytes32 => ConditionStatus) public verifiedConditions; // conditionId => status
    uint40 public measurementStartTime; // Timestamp when Measuring state began
    uint256 public tunnelingTimeoutSeconds; // Duration after which tunneling is possible

    // Final State (Collapsed / Tunneled)
    uint256 public finalOutcomeId; // The outcomeId selected after collapse (if state is Collapsed)
    mapping(address => mapping(address => uint256)) private _claimedAmounts; // tokenAddress => recipientAddress => claimed amount

    /*
     * --- Events ---
     */

    event StateChanged(VaultState newState, VaultState oldState);
    event TokenSupported(address indexed tokenAddress);
    event ERC20Deposited(address indexed tokenAddress, address indexed depositor, uint256 amount);
    event OutcomeProposed(uint256 indexed outcomeId, string description);
    event OutcomesActivated();
    event MeasurementConditionSet(bytes32 indexed conditionId, uint256 indexed outcomeId);
    event ObserverAdded(address indexed observer);
    event ObserverRemoved(address indexed observer);
    event MeasurementStarted(uint256 tunnelingTimeout);
    event ConditionVerified(bytes32 indexed conditionId, bool status);
    event StateCollapsed(uint256 indexed outcomeId);
    event AssetsClaimed(address indexed tokenAddress, address indexed recipient, uint256 amount);
    event MeasurementPaused();
    event MeasurementUnpaused();
    event TunnelingDistributionSet();
    event TunnelingTriggered();

    /*
     * --- Modifiers ---
     */

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not owner");
        _;
    }

    modifier onlyObserver() {
        require(isObserver[msg.sender], "Not observer");
        _;
    }

    modifier whenState(VaultState _state) {
        require(currentState == _state, "Invalid state");
        _;
    }

    modifier notWhenState(VaultState _state) {
        require(currentState != _state, "Invalid state");
        _;
    }

    /*
     * --- Constructor ---
     */

    constructor() {
        _owner = msg.sender;
        currentState = VaultState.Configuring;
        emit StateChanged(currentState, VaultState.Empty);
    }

    /*
     * --- Configuration & Setup Functions (State: Configuring) ---
     */

    /**
     * @dev Adds an ERC20 token address to the list of supported tokens for deposits.
     * @param tokenAddress The address of the ERC20 token.
     */
    function addSupportedToken(address tokenAddress) external onlyOwner whenState(VaultState.Configuring) {
        require(tokenAddress != address(0), "Zero address");
        require(!isSupportedToken[tokenAddress], "Token already supported");
        isSupportedToken[tokenAddress] = true;
        _supportedTokens.push(tokenAddress);
        emit TokenSupported(tokenAddress);
    }

    /**
     * @dev Proposes a potential distribution outcome for the vault assets.
     * The total percentageBasisPoints for an outcome must sum to 10000 (100%).
     * @param description A brief description of the outcome.
     * @param distribution Array of recipients and their allocated percentage in basis points.
     */
    function proposeOutcome(string memory description, Distribution[] memory distribution) external onlyOwner whenState(VaultState.Configuring) {
        require(bytes(description).length > 0, "Description required");
        require(distribution.length > 0, "Distribution cannot be empty");

        uint256 totalBasisPoints = 0;
        for (uint256 i = 0; i < distribution.length; i++) {
            require(distribution[i].recipient != address(0), "Zero address recipient");
            totalBasisPoints += distribution[i].percentageBasisPoints;
        }
        require(totalBasisPoints == 10000, "Distribution must sum to 10000 basis points");

        uint256 outcomeId = _nextOutcomeId++;
        outcomes[outcomeId] = VaultOutcome(outcomeId, description, distribution, false); // Not yet activated

        emit OutcomeProposed(outcomeId, description);
    }

    /**
     * @dev Activates the proposed outcomes, moving the vault into the Superposition state.
     * Deposits are enabled in this state. Requires at least one outcome proposed.
     */
    function activateOutcomes() external onlyOwner whenState(VaultState.Configuring) {
        require(_nextOutcomeId > 0, "No outcomes proposed");

        for(uint256 i = 0; i < _nextOutcomeId; i++) {
            outcomes[i].activated = true;
        }

        VaultState oldState = currentState;
        currentState = VaultState.Superposition;
        emit StateChanged(currentState, oldState);
        emit OutcomesActivated();
    }

    /**
     * @dev Links external condition IDs to specific activated outcomes.
     * When a condition is met, it *might* trigger the corresponding outcome upon finalization.
     * Each condition ID can only be mapped once.
     * @param conditionIds Array of unique identifiers for external conditions.
     * @param outcomeIds Array of outcome IDs corresponding to the conditionIds.
     */
    function setMeasurementConditions(bytes32[] memory conditionIds, uint256[] memory outcomeIds) external onlyOwner notWhenState(VaultState.Measuring) notWhenState(VaultState.Paused) notWhenState(VaultState.Collapsed) notWhenState(VaultState.Tunneled) {
         require(conditionIds.length == outcomeIds.length, "Arrays length mismatch");
         require(conditionIds.length > 0, "Conditions required");

         // Clear previous active conditions
         for(uint256 i = 0; i < _activeConditionIds.length; i++) {
             delete conditionOutcomeMap[_activeConditionIds[i]];
             delete verifiedConditions[_activeConditionIds[i]]; // Reset verification status
         }
         delete _activeConditionIds; // Clear the dynamic array

         for (uint256 i = 0; i < conditionIds.length; i++) {
             bytes32 conditionId = conditionIds[i];
             uint256 outcomeId = outcomeIds[i];

             require(conditionOutcomeMap[conditionId] == 0, "Condition ID already mapped"); // Ensure conditionId is unique

             require(outcomeId < _nextOutcomeId, "Outcome ID out of range");
             require(outcomes[outcomeId].activated, "Outcome not activated");

             conditionOutcomeMap[conditionId] = outcomeId;
             _activeConditionIds.push(conditionId);
             verifiedConditions[conditionId] = ConditionStatus.Unverified; // Default status
         }
    }

    /**
     * @dev Defines the distribution rules if the tunneling mechanism is triggered.
     * @param distribution Array of recipients and their allocated percentage in basis points.
     */
    function setTunnelingDistribution(Distribution[] memory distribution) external onlyOwner notWhenState(VaultState.Measuring) notWhenState(VaultState.Paused) notWhenState(VaultState.Collapsed) notWhenState(VaultState.Tunneled) {
        require(distribution.length > 0, "Distribution cannot be empty");

        uint256 totalBasisPoints = 0;
        for (uint256 i = 0; i < distribution.length; i++) {
            require(distribution[i].recipient != address(0), "Zero address recipient");
            totalBasisPoints += distribution[i].percentageBasisPoints;
        }
        require(totalBasisPoints == 10000, "Distribution must sum to 10000 basis points");

        tunnelingDistribution = distribution;
        emit TunnelingDistributionSet();
    }

    /**
     * @dev Grants an address the role of an Observer, allowing them to verify conditions.
     * @param observer The address to grant the observer role.
     */
    function addObserver(address observer) external onlyOwner notWhenState(VaultState.Measuring) notWhenState(VaultState.Paused) notWhenState(VaultState.Collapsed) notWhenState(VaultState.Tunneled) {
        require(observer != address(0), "Zero address");
        require(!isObserver[observer], "Address is already an observer");
        isObserver[observer] = true;
        emit ObserverAdded(observer);
    }

    /**
     * @dev Revokes the Observer role from an address.
     * @param observer The address to remove the observer role from.
     */
    function removeObserver(address observer) external onlyOwner notWhenState(VaultState.Measuring) notWhenState(VaultState.Paused) notWhenState(VaultState.Collapsed) notWhenState(VaultState.Tunneled) {
         require(observer != address(0), "Zero address");
         require(isObserver[observer], "Address is not an observer");
         isObserver[observer] = false;
         emit ObserverRemoved(observer);
     }

    /*
     * --- Deposit Function (State: Superposition) ---
     */

    /**
     * @dev Deposits supported ERC20 tokens into the vault.
     * Requires approval beforehand. Only allowed in Superposition state.
     * @param tokenAddress The address of the ERC20 token.
     * @param amount The amount of tokens to deposit.
     */
    function depositERC20(address tokenAddress, uint256 amount) external whenState(VaultState.Superposition) {
        require(isSupportedToken[tokenAddress], "Token not supported");
        require(amount > 0, "Amount must be > 0");

        // TransferFrom requires the contract to have allowance from msg.sender
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);

        _totalVaultBalances[tokenAddress] += amount;

        emit ERC20Deposited(tokenAddress, msg.sender, amount);
    }

    /*
     * --- Measurement & Collapse Functions (State: Superposition, Measuring, Paused) ---
     */

    /**
     * @dev Starts the measurement process, transitioning from Superposition to Measuring.
     * Locks deposits and starts the tunneling timeout timer.
     * Requires measurement conditions and tunneling distribution to be set.
     * @param _tunnelingTimeoutSeconds The duration (in seconds) before tunneling is potentially enabled.
     */
    function startMeasurement(uint256 _tunnelingTimeoutSeconds) external onlyOwner whenState(VaultState.Superposition) {
        require(_activeConditionIds.length > 0, "Measurement conditions not set");
        require(tunnelingDistribution.length > 0, "Tunneling distribution not set");
        require(_tunnelingTimeoutSeconds > 0, "Tunneling timeout must be > 0");

        VaultState oldState = currentState;
        currentState = VaultState.Measuring;
        measurementStartTime = uint40(block.timestamp);
        tunnelingTimeoutSeconds = _tunnelingTimeoutSeconds;

        emit StateChanged(currentState, oldState);
        emit MeasurementStarted(tunnelingTimeoutSeconds);
    }


    /**
     * @dev Allows an authorized observer to verify the status of a specific condition.
     * This moves the condition status from Unverified to Met or NotMet.
     * @param conditionId The ID of the condition to verify.
     * @param status The verified status (true for Met, false for NotMet).
     */
    function verifyCondition(bytes32 conditionId, bool status) external onlyObserver whenState(VaultState.Measuring) {
        require(conditionOutcomeMap[conditionId] != 0, "Condition ID not active");
        require(verifiedConditions[conditionId] == ConditionStatus.Unverified, "Condition already verified");

        verifiedConditions[conditionId] = status ? ConditionStatus.Met : ConditionStatus.NotMet;
        emit ConditionVerified(conditionId, status);
    }

    /**
     * @dev Triggers the finalization of the measurement process.
     * Checks the status of all active conditions. If exactly one condition linked
     * to an activated outcome is verified as 'Met', the state collapses to that outcome.
     * If multiple conditions are met, or none are met after a certain time,
     * this function might need external handling or tunneling might be triggered.
     * Callable by anyone.
     */
    function finalizeMeasurement() external whenState(VaultState.Measuring) {
        uint256 metCount = 0;
        uint256 winningOutcomeId = 0;

        for (uint256 i = 0; i < _activeConditionIds.length; i++) {
            bytes32 conditionId = _activeConditionIds[i];
            if (verifiedConditions[conditionId] == ConditionStatus.Met) {
                metCount++;
                winningOutcomeId = conditionOutcomeMap[conditionId]; // Store the outcomeId linked to the met condition
            }
        }

        // Collapse requires exactly one condition linked to an activated outcome to be Met
        require(metCount == 1, "Exactly one condition must be verified as Met to collapse");
        // The winning outcome must be activated (sanity check, should be due to setMeasurementConditions logic)
        require(outcomes[winningOutcomeId].activated, "Winning outcome not activated");

        VaultState oldState = currentState;
        currentState = VaultState.Collapsed;
        finalOutcomeId = winningOutcomeId; // Set the determined outcome

        _distributeAssets(outcomes[finalOutcomeId].distribution); // Perform internal distribution setup

        emit StateChanged(currentState, oldState);
        emit StateCollapsed(finalOutcomeId);
    }

    /**
     * @dev Pauses the measurement process. Prevents condition verification and finalization.
     * Can only be called by the owner while in the Measuring state.
     */
    function pauseMeasurement() external onlyOwner whenState(VaultState.Measuring) {
        VaultState oldState = currentState;
        currentState = VaultState.Paused;
        emit StateChanged(currentState, oldState);
        emit MeasurementPaused();
    }

    /**
     * @dev Unpauses the measurement process. Returns to the Measuring state.
     * Can only be called by the owner while in the Paused state.
     */
    function unpauseMeasurement() external onlyOwner whenState(VaultState.Paused) {
        VaultState oldState = currentState;
        currentState = VaultState.Measuring;
        // Note: Measurement timer continues from where it left off conceptually,
        // but we only check against block.timestamp vs measurementStartTime.
        // If precise pausing is needed, measurementStartTime would need adjustment.
        emit StateChanged(currentState, oldState);
        emit MeasurementUnpaused();
    }

    /*
     * --- Distribution & Claim Functions (State: Collapsed, Tunneled) ---
     */

     /**
      * @dev Internal function to calculate and record the total allocation per recipient
      * based on a chosen distribution. This doesn't transfer tokens yet.
      * Called after state collapse or tunneling.
      * @param distributionRules The distribution rules to apply.
      */
     function _distributeAssets(Distribution[] memory distributionRules) internal {
         // This function calculates the total amount each recipient is eligible to claim
         // for each token based on the distribution rules and current vault balances.
         // It doesn't transfer funds directly, claimAssets does that.
         // The claimedAmounts mapping is used by claimAssets to track withdrawals.
         // We don't explicitly store recipient allocations here to save gas/storage,
         // calculation is done in claimAssets based on the final distribution and total balances.
         // The claimedAmounts mapping is sufficient to prevent double claims.
     }

    /**
     * @dev Allows a recipient listed in the final outcome (Collapsed or Tunneled)
     * to claim their allocated share of a specific token.
     * @param tokenAddress The address of the token to claim.
     */
    function claimAssets(address tokenAddress) external {
        require(currentState == VaultState.Collapsed || currentState == VaultState.Tunneled, "Vault not in claimable state");
        require(isSupportedToken[tokenAddress], "Token not supported");

        address recipient = msg.sender;
        uint256 totalAllocation = getRecipientTotalAllocation(tokenAddress, recipient); // Calculate total allocation
        uint256 alreadyClaimed = _claimedAmounts[tokenAddress][recipient];
        uint256 claimableAmount = totalAllocation > alreadyClaimed ? totalAllocation - alreadyClaimed : 0;

        require(claimableAmount > 0, "No amount claimable for this token by this recipient");

        _claimedAmounts[tokenAddress][recipient] += claimableAmount; // Mark amount as claimed

        // Use low-level call or check return value for safety, depending on trust in token
        // Standard ERC20 transfer is generally safe after 0.8
        IERC20(tokenAddress).transfer(recipient, claimableAmount);

        emit AssetsClaimed(tokenAddress, recipient, claimableAmount);
    }

    /*
     * --- Tunneling Function (State: Measuring) ---
     */

    /**
     * @dev Triggers the tunneling mechanism if conditions are met.
     * Current condition: Tunneling timeout has elapsed since measurement started.
     * Future conditions could involve observer consensus.
     * Transitions state to Tunneled and allows claiming via tunneling distribution.
     * Callable by anyone.
     */
    function triggerTunneling() external whenState(VaultState.Measuring) {
        bool timeoutElapsed = block.timestamp >= measurementStartTime + tunnelingTimeoutSeconds;

        // Example: Tunneling is triggered if timeout elapsed OR (maybe) a certain percentage of observers agree
        // For now, simple timeout:
        require(timeoutElapsed, "Tunneling timeout has not elapsed");
        require(tunnelingDistribution.length > 0, "Tunneling distribution not set"); // Should be set before Measurement

        VaultState oldState = currentState;
        currentState = VaultState.Tunneled;

        _distributeAssets(tunnelingDistribution); // Use the tunneling distribution for setup

        emit StateChanged(currentState, oldState);
        emit TunnelingTriggered();
    }


    /*
     * --- Utility and Getter Functions ---
     */

    /**
     * @dev Returns the current state of the vault.
     */
    function getCurrentState() external view returns (VaultState) {
        return currentState;
    }

    /**
     * @dev Returns the ID of the outcome chosen after state collapse.
     * Only valid if currentState is Collapsed.
     */
    function getFinalOutcomeId() external view returns (uint256) {
        require(currentState == VaultState.Collapsed, "Vault not in Collapsed state");
        return finalOutcomeId;
    }

    /**
     * @dev Checks if a specific recipient has claimed assets for a given token.
     * Returns true if any amount has been claimed.
     * @param tokenAddress The address of the token.
     * @param recipient The address of the potential recipient.
     */
    function isRecipientClaimed(address tokenAddress, address recipient) external view returns (bool) {
        return _claimedAmounts[tokenAddress][recipient] > 0;
    }

    /**
     * @dev Returns a list of all unique addresses defined as potential recipients
     * across all proposed outcomes and the tunneling distribution.
     */
    function getPotentialRecipients() external view returns (address[] memory) {
        mapping(address => bool) uniqueRecipients;
        uint256 count = 0;

        // From proposed outcomes
        for(uint256 i = 0; i < _nextOutcomeId; i++) {
            for(uint256 j = 0; j < outcomes[i].distribution.length; j++) {
                 address recipient = outcomes[i].distribution[j].recipient;
                 if (!uniqueRecipients[recipient]) {
                     uniqueRecipients[recipient] = true;
                     count++;
                 }
            }
        }

        // From tunneling distribution
        for(uint256 j = 0; j < tunnelingDistribution.length; j++) {
            address recipient = tunnelingDistribution[j].recipient;
            if (!uniqueRecipients[recipient]) {
                uniqueRecipients[recipient] = true;
                count++;
            }
        }

        address[] memory recipientsArray = new address[](count);
        uint265 k = 0;
        // This re-iterates to build the array. Not efficient for very large numbers.
        // A more efficient way might require storing recipients in a dynamic array during configuration.
        for(uint256 i = 0; i < _nextOutcomeId; i++) {
             for(uint256 j = 0; j < outcomes[i].distribution.length; j++) {
                 address recipient = outcomes[i].distribution[j].recipient;
                 if (uniqueRecipients[recipient]) {
                     recipientsArray[k++] = recipient;
                     uniqueRecipients[recipient] = false; // Mark as added to array
                 }
             }
         }
        for(uint256 j = 0; j < tunnelingDistribution.length; j++) {
            address recipient = tunnelingDistribution[j].recipient;
            if (uniqueRecipients[recipient]) { // Check if still marked true
                 recipientsArray[k++] = recipient;
            }
        }


        return recipientsArray;
    }

    /**
     * @dev Returns the distribution details for a specific proposed outcome ID.
     * @param outcomeId The ID of the outcome.
     */
    function getOutcomeDistribution(uint256 outcomeId) external view returns (Distribution[] memory) {
        require(outcomeId < _nextOutcomeId, "Outcome ID out of range");
        return outcomes[outcomeId].distribution;
    }

    /**
     * @dev Returns the total deposited amount for a specific supported token.
     * @param tokenAddress The address of the token.
     */
    function getDepositedAmount(address tokenAddress) external view returns (uint256) {
        return _totalVaultBalances[tokenAddress];
    }

    /**
     * @dev Returns the total number of outcomes that have been proposed.
     */
    function getOutcomeCount() external view returns (uint256) {
        return _nextOutcomeId;
    }

    /**
     * @dev Returns the list of supported ERC20 token addresses.
     */
    function getSupportedTokens() external view returns (address[] memory) {
        return _supportedTokens;
    }

    /**
     * @dev Checks if an address has the observer role.
     * @param observer The address to check.
     */
    function getObserverStatus(address observer) external view returns (bool) {
        return isObserver[observer];
    }

     /**
     * @dev Returns the distribution rules defined for tunneling.
     */
    function getTunnelingDistribution() external view returns (Distribution[] memory) {
        return tunnelingDistribution;
    }

    /**
     * @dev Returns the current verification status of a specific condition ID.
     * @param conditionId The ID of the condition.
     */
    function checkConditionStatus(bytes32 conditionId) external view returns (ConditionStatus) {
         require(conditionOutcomeMap[conditionId] != 0, "Condition ID not active");
         return verifiedConditions[conditionId];
     }

     /**
      * @dev Returns the timestamp when the measurement state was started.
      */
     function getMeasurementStartTime() external view returns (uint40) {
         return measurementStartTime;
     }

     /**
      * @dev Returns the configured tunneling timeout duration in seconds.
      */
     function getTunnelingTimeout() external view returns (uint256) {
         return tunnelingTimeoutSeconds;
     }

    /**
     * @dev Calculates the total amount allocated to a recipient for a specific token
     * based on the final state (Collapsed or Tunneled).
     * @param tokenAddress The address of the token.
     * @param recipient The address of the recipient.
     * @return The total amount allocated to the recipient for the token.
     */
    function getRecipientTotalAllocation(address tokenAddress, address recipient) public view returns (uint256) {
        require(currentState == VaultState.Collapsed || currentState == VaultState.Tunneled, "Vault not in a final state");

        Distribution[] memory finalDistribution;
        if (currentState == VaultState.Collapsed) {
            require(finalOutcomeId < _nextOutcomeId, "Invalid final outcome ID");
            finalDistribution = outcomes[finalOutcomeId].distribution;
        } else { // currentState == VaultState.Tunneled
             finalDistribution = tunnelingDistribution;
        }

        uint265 totalBalance = _totalVaultBalances[tokenAddress];
        uint256 totalAllocation = 0;

        for (uint256 i = 0; i < finalDistribution.length; i++) {
            if (finalDistribution[i].recipient == recipient) {
                totalAllocation += (totalBalance * finalDistribution[i].percentageBasisPoints) / 10000;
            }
        }
        return totalAllocation;
    }

    /**
     * @dev Calculates the remaining amount claimable by a recipient for a specific token.
     * @param tokenAddress The address of the token.
     * @param recipient The address of the recipient.
     * @return The amount of token claimable by the recipient.
     */
    function getRecipientClaimableAmount(address tokenAddress, address recipient) external view returns (uint256) {
        if (currentState != VaultState.Collapsed && currentState != VaultState.Tunneled) {
            return 0; // No claimable amount if not in a final state
        }
        uint256 totalAllocation = getRecipientTotalAllocation(tokenAddress, recipient);
        uint256 alreadyClaimed = _claimedAmounts[tokenAddress][recipient];
        return totalAllocation > alreadyClaimed ? totalAllocation - alreadyClaimed : 0;
    }

    /**
     * @dev Changes the owner of the contract.
     * @param newOwner The address of the new owner.
     */
    function changeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner zero address");
        _owner = newOwner;
        // No event for owner change in this custom implementation, could add if needed
    }
}
```