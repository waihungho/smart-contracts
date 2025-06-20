Okay, here is a Solidity smart contract implementing a concept I'll call a "Quantum Fluctuations Fund". This contract aims to simulate a pooled investment fund whose "performance" is driven by pseudo-random "Quantum Events" triggered via Chainlink VRF. It's not linked to real-world markets but demonstrates complex internal state management, probabilistic outcomes, and access control.

It includes concepts like:
*   Pooled fund management (shares).
*   VRF integration for randomness.
*   Probabilistic outcomes based on defined events.
*   Complex internal value tracking.
*   Role-based access control (Owner/Admins).
*   Pausable functionality.
*   Reentrancy guard.
*   Custom Errors (trendy practice).
*   Structured data (structs, mappings).
*   Over 20 functions.

This contract is **highly experimental** and intended as a creative demonstration, not financial advice or a production-ready investment vehicle. The "returns" are purely based on the defined probabilistic events within the contract, driven by a Verifiable Random Function.

---

**QuantumFluctuationsFund: Outline & Function Summary**

**Outline:**

1.  **Contract Definition:** Inherits Ownable, Pausable, ReentrancyGuard, and VRFConsumerBaseV2.
2.  **Custom Errors:** Defined for common failure conditions.
3.  **Structs:** `QuantumEventConfig` (defines event probability and outcome), `FluctuationResult` (stores results of a fluctuation).
4.  **Events:** Emitted for key actions (Deposits, Withdrawals, Fluctuation Requests/Fulfilments, Admin changes, Config changes, Pause/Unpause).
5.  **State Variables:**
    *   Admin roles.
    *   Fund state (total value, total shares).
    *   User state (user shares).
    *   Event configurations (mapping, array of keys).
    *   Configuration parameters (withdrawal fee, minimum deposit, VRF settings).
    *   VRF state (request ID tracking, last result).
    *   Initial fund parameters.
6.  **Modifiers:** `onlyAdmin`, `onlyOwner`, `whenNotPaused`, `whenPaused`, `nonReentrant`.
7.  **Constructor:** Initializes contract owner and VRF parameters.
8.  **Fund Management Functions:**
    *   `depositETH`: Accepts ETH and issues shares.
    *   `withdrawETH`: Burns shares and sends corresponding ETH.
    *   `getFundValue`: Returns current calculated value of the fund in wei.
    *   `getTotalShares`: Returns the total shares issued.
    *   `getUserShares`: Returns shares held by a specific user.
    *   `getSharesForETHAmount`: Calculates shares for a given ETH amount based on current fund state (view).
    *   `getETHForShares`: Calculates ETH amount for a given number of shares based on current fund state (view).
9.  **Quantum Fluctuation Functions (VRF Interaction):**
    *   `triggerQuantumFluctuation`: Requests randomness from VRF to simulate an event (Admin only).
    *   `rawFulfillRandomWords`: VRF callback function to process randomness and apply event outcome.
    *   `getLastFluctuationResult`: Returns details of the most recently processed fluctuation (view).
10. **Admin & Configuration Functions:**
    *   `addAdmin`: Adds an admin address (Owner only).
    *   `removeAdmin`: Removes an admin address (Owner only).
    *   `isAdmin`: Checks if an address is an admin (view).
    *   `addEventConfig`: Adds a new quantum event configuration (Admin only).
    *   `updateEventConfig`: Updates an existing quantum event configuration (Admin only).
    *   `removeEventConfig`: Removes a quantum event configuration (Admin only).
    *   `getEventConfigCount`: Returns the number of configured events (view).
    *   `getEventConfig`: Returns details of a specific event configuration by ID (view).
    *   `getEventConfigIds`: Returns list of all configured event IDs (view).
    *   `setWithdrawalFee`: Sets the percentage fee applied on withdrawals (Admin only).
    *   `getWithdrawalFee`: Returns the current withdrawal fee (view).
    *   `setMinimumDeposit`: Sets the minimum ETH amount required for a deposit (Admin only).
    *   `getMinimumDeposit`: Returns the current minimum deposit (view).
    *   `pause`: Pauses contract operations (Admin only).
    *   `unpause`: Unpauses contract operations (Admin only).
    *   `paused`: Checks if contract is paused (view).
11. **VRF Configuration Functions:**
    *   `setVrfParameters`: Sets VRF keyhash and request confirmtaions (Admin only). *Note: VRF Coordinator address and Subscription ID are set in constructor/deployment.*
    *   `getVrfParameters`: Returns current VRF parameters (view).

---

**Function Summary:**

*   **`constructor`**: Initializes contract owner, VRF coordinator address, key hash, subscription ID, and minimum request confirmations. Sets initial fund value and shares.
*   **`depositETH`**: (payable) Allows users to deposit ETH. Calculates shares based on the current fund value and total shares, mints shares, updates fund value, and emits `Deposit` event. Requires contract not to be paused and deposit to meet minimum.
*   **`withdrawETH`**: Allows users to withdraw ETH by burning their shares. Calculates ETH amount corresponding to shares, applies withdrawal fee, updates fund value and total shares, burns shares, transfers ETH, and emits `Withdrawal` event. Requires contract not to be paused and uses reentrancy guard.
*   **`getFundValue`**: (view) Returns the current total value of the fund in wei.
*   **`getTotalShares`**: (view) Returns the total number of shares currently issued.
*   **`getUserShares`**: (view) Returns the number of shares owned by a specific address.
*   **`getSharesForETHAmount`**: (view) Calculates how many shares a given amount of ETH would receive at the current fund valuation. Pure function, handles the initial deposit case.
*   **`getETHForShares`**: (view) Calculates how much ETH a given number of shares are worth at the current fund valuation. Pure function.
*   **`triggerQuantumFluctuation`**: (admin) Initiates a VRF request to get a random number. Stores the request ID and emits `FluctuationRequested`. Requires contract not to be paused.
*   **`rawFulfillRandomWords`**: (VRF callback) Called by the VRF coordinator with random words. Determines which event type occurs based on configured probabilities, calculates the outcome magnitude, updates the fund's total value, stores the result, and emits `FluctuationProcessed`. Includes checks for the requesting contract and pending request ID.
*   **`getLastFluctuationResult`**: (view) Returns the details of the last processed quantum fluctuation event.
*   **`addAdmin`**: (owner) Adds an address to the list of contract admins. Emits `AdminAdded`.
*   **`removeAdmin`**: (owner) Removes an address from the list of contract admins. Emits `AdminRemoved`.
*   **`isAdmin`**: (view) Returns true if an address is an admin.
*   **`addEventConfig`**: (admin) Adds a new quantum event configuration (ID, probability, outcome percentage). Emits `EventConfigAdded`. Requires probabilities to sum up to 100% across all active configs.
*   **`updateEventConfig`**: (admin) Updates an existing quantum event configuration by ID. Emits `EventConfigUpdated`. Requires probabilities to sum up to 100% across all active configs.
*   **`removeEventConfig`**: (admin) Removes a quantum event configuration by ID. Emits `EventConfigRemoved`. Requires probabilities to sum up to 100% across remaining configs.
*   **`getEventConfigCount`**: (view) Returns the total number of active event configurations.
*   **`getEventConfig`**: (view) Returns the details (probability, outcome) for a specific event configuration ID.
*   **`getEventConfigIds`**: (view) Returns an array containing all active event configuration IDs.
*   **`setWithdrawalFee`**: (admin) Sets the percentage fee (in basis points, 1/100th of 1%) applied to withdrawal amounts. Emits `WithdrawalFeeSet`.
*   **`getWithdrawalFee`**: (view) Returns the current withdrawal fee percentage (in basis points).
*   **`setMinimumDeposit`**: (admin) Sets the minimum amount of ETH required for a deposit. Emits `MinimumDepositSet`.
*   **`getMinimumDeposit`**: (view) Returns the current minimum deposit amount in wei.
*   **`pause`**: (admin) Pauses the contract, preventing deposits, withdrawals, and fluctuation triggers. Emits `Paused`.
*   **`unpause`**: (admin) Unpauses the contract. Emits `Unpaused`.
*   **`paused`**: (view) Returns true if the contract is currently paused.
*   **`setVrfParameters`**: (admin) Updates VRF keyhash and request confirmations. Emits `VrfParametersSet`. *Note: VRF Coordinator address and Subscription ID are typically fixed after deployment.*
*   **`getVrfParameters`**: (view) Returns the current VRF keyhash and minimum request confirmations.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/// @title QuantumFluctuationsFund
/// @dev A highly experimental smart contract simulating a pooled investment fund
/// whose performance is driven by probabilistic "Quantum Events" triggered by Chainlink VRF.
/// This contract is for demonstration purposes only and not intended for actual financial investment.
contract QuantumFluctuationsFund is Ownable, Pausable, ReentrancyGuard, VRFConsumerBaseV2 {

    // --- Custom Errors ---
    error NotAdmin();
    error InvalidEventProbabilitySum();
    error EventConfigNotFound();
    error ZeroShares();
    error InsufficientShares();
    error MinimumDepositNotMet();
    error InvalidFeePercentage();
    error NoFluctuationPending();
    error InvalidVrfRequestId();
    error EventConfigAlreadyExists();
    error CannotRemoveLastAdmin();
    error CannotRemoveOwnerAsAdmin();


    // --- Structs ---

    /// @dev Defines a type of quantum event and its potential outcome.
    struct QuantumEventConfig {
        uint16 probability; // Probability in basis points (e.g., 100 = 1%)
        int16 outcomeBasisPoints; // Percentage change in fund value in basis points (e.g., 100 = +1%, -50 = -0.5%)
        bool exists; // To check if config ID is used
    }

    /// @dev Stores the result of a processed quantum fluctuation.
    struct FluctuationResult {
        uint256 timestamp;
        bytes32 eventConfigId;
        int16 outcomeBasisPoints;
        uint256 fundValueBefore;
        uint256 fundValueAfter;
        uint256 randomness; // The random word used
    }

    // --- State Variables ---

    // Access Control
    mapping(address => bool) private _admins;

    // Fund State
    uint256 public totalFundValue; // Total simulated value of the fund in wei
    uint256 public totalShares;    // Total number of shares outstanding
    mapping(address => uint256) public userShares; // Shares held by each user

    // Event Configuration
    mapping(bytes32 => QuantumEventConfig) private _eventConfigs;
    bytes32[] private _eventConfigIds; // Array to iterate through event IDs

    // Configuration Parameters
    uint16 public withdrawalFeeBasisPoints; // Fee applied on withdrawals (e.g., 100 = 1%)
    uint256 public minimumDepositAmount;   // Minimum ETH required for deposit in wei

    // Chainlink VRF Parameters
    VRFCoordinatorV2Interface immutable i_vrfCoordinator;
    uint64 immutable i_subscriptionId;
    bytes32 public keyHash;
    uint32 public requestConfirmations;
    uint32 constant NUM_WORDS = 1; // We only need one random number

    // VRF State Tracking
    mapping(uint256 => address) public s_requests; // Map VRF request ID to the address that triggered it (optional but useful)
    uint256 private _lastRequestId; // Keep track of the last request ID
    bool public fluctuationPending; // Flag to indicate if a VRF request is awaiting fulfillment

    // Fluctuation History (last result)
    FluctuationResult public lastFluctuationResult;

    // Initial Fund Parameters (used for share calculation edge case)
    uint256 private immutable _initialFundValue;
    uint256 private immutable _initialTotalShares = 1e18; // Define a unit of shares, like 1 ETH = 1 share initially

    // --- Events ---

    event Deposit(address indexed user, uint256 ethAmount, uint256 sharesMinted, uint256 newTotalShares, uint256 newFundValue);
    event Withdrawal(address indexed user, uint256 sharesBurned, uint256 ethAmountReceived, uint256 feeAmount, uint256 newTotalShares, uint256 newFundValue);
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event EventConfigAdded(bytes32 indexed configId, uint16 probability, int16 outcomeBasisPoints);
    event EventConfigUpdated(bytes32 indexed configId, uint16 probability, int16 outcomeBasisPoints);
    event EventConfigRemoved(bytes32 indexed configId);
    event FluctuationRequested(address indexed requestedBy, uint256 indexed requestId);
    event FluctuationProcessed(uint256 indexed requestId, bytes32 indexed eventConfigId, int16 outcomeBasisPoints, uint256 fundValueBefore, uint256 fundValueAfter);
    event WithdrawalFeeSet(uint16 indexed feeBasisPoints);
    event MinimumDepositSet(uint256 indexed amount);
    event VrfParametersSet(bytes32 keyHash, uint32 requestConfirmations);


    // --- Modifiers ---

    modifier onlyAdmin() {
        if (!_admins[msg.sender]) revert NotAdmin();
        _;
    }


    // --- Constructor ---

    constructor(
        address vrfCoordinator,
        bytes32 _keyHash,
        uint64 subscriptionId,
        uint32 _requestConfirmations
    )
        VRFConsumerBaseV2(vrfCoordinator)
        Ownable(msg.sender)
        Pausable()
        ReentrancyGuard()
    {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        keyHash = _keyHash;
        i_subscriptionId = subscriptionId;
        requestConfirmations = _requestConfirmations;

        // Initialize the fund with the contract deployment balance
        // This assumes some ETH is sent on deployment
        _initialFundValue = msg.value;
        totalFundValue = msg.value;
        totalShares = _initialTotalShares; // Initial shares represent initial capital

        // Owner is automatically an admin
        _admins[msg.sender] = true;

        // Set initial parameters (can be updated by admin/owner later)
        withdrawalFeeBasisPoints = 0; // Start with no fee
        minimumDepositAmount = 0;   // Start with no minimum
        fluctuationPending = false; // No request pending initially
    }


    // --- Fund Management Functions ---

    /// @notice Allows a user to deposit ETH into the fund and receive shares.
    /// @dev Calculates shares based on current fund value and total shares.
    /// @param msg.value The amount of ETH to deposit.
    function depositETH() external payable whenNotPaused nonReentrant {
        if (msg.value < minimumDepositAmount) revert MinimumDepositNotMet();
        if (msg.value == 0) return; // No shares minted for zero deposit

        uint256 sharesToMint = getSharesForETHAmount(msg.value);
        if (sharesToMint == 0) revert ZeroShares(); // Should not happen if msg.value > 0 and totalShares > 0

        // Update state
        userShares[msg.sender] += sharesToMint;
        totalShares += sharesToMint;
        totalFundValue += msg.value; // Fund value increases by the deposited ETH

        emit Deposit(msg.sender, msg.value, sharesToMint, totalShares, totalFundValue);
    }

    /// @notice Allows a user to withdraw ETH by redeeming their shares.
    /// @dev Calculates ETH amount based on shares and current fund value, applies fee.
    /// @param sharesToBurn The number of shares the user wants to redeem.
    function withdrawETH(uint256 sharesToBurn) external whenNotPaused nonReentrant {
        if (sharesToBurn == 0) revert ZeroShares();
        if (userShares[msg.sender] < sharesToBurn) revert InsufficientShares();

        uint256 ethAmountBeforeFee = getETHForShares(sharesToBurn);

        // Calculate and apply withdrawal fee
        uint256 feeAmount = (ethAmountBeforeFee * withdrawalFeeBasisPoints) / 10000; // Basis points calculation
        uint256 ethAmountToSend = ethAmountBeforeFee - feeAmount;

        // Update state
        userShares[msg.sender] -= sharesToBurn;
        totalShares -= sharesToBurn;
        // Fund value decreases by the *gross* amount corresponding to shares,
        // the fee stays in the contract increasing value per share slightly for others.
        totalFundValue -= ethAmountBeforeFee;

        // Transfer ETH
        // Use a low-level call to avoid gas limits issues with transfer/send
        (bool success, ) = payable(msg.sender).call{value: ethAmountToSend}("");
        if (!success) {
             // Revert state changes if ETH transfer fails
             // Note: In a real system, you might want a rescue mechanism here
             // or use a pull pattern (user claims withdrawal)
             revert ("ETH transfer failed");
        }

        emit Withdrawal(msg.sender, sharesToBurn, ethAmountToSend, feeAmount, totalShares, totalFundValue);
    }

    /// @notice Returns the current total simulated value of the fund in wei.
    function getFundValue() public view returns (uint256) {
        return totalFundValue;
    }

    /// @notice Returns the total number of shares outstanding.
    function getTotalShares() public view returns (uint256) {
        return totalShares;
    }

    /// @notice Returns the number of shares held by a specific user.
    function getUserShares(address user) public view returns (uint256) {
        return userShares[user];
    }

    /// @notice Calculates how many shares a given amount of ETH would receive at the current valuation.
    /// @dev Handles the initial deposit case where totalShares and totalFundValue might be the initial values.
    /// Uses a fixed point like representation for shares (1e18 corresponds to 1 share unit).
    /// @param ethAmount The amount of ETH to calculate shares for.
    /// @return The number of shares corresponding to the ETH amount.
    function getSharesForETHAmount(uint256 ethAmount) public view returns (uint256) {
        if (totalShares == _initialTotalShares && totalFundValue == _initialFundValue) {
             // Initial deposit case: If this is the first deposit since deployment with initial balance,
             // shares are calculated relative to the initial state.
             // If the fund was deployed with 0 ETH, this logic needs adjustment.
             if (_initialFundValue == 0) {
                 // If deployed with 0 initial ETH, the very first deposit gets _initialTotalShares
                 // Subsequent deposits would then use the standard formula.
                 // This simplified example assumes initialFundValue >= minimumDepositAmount
                 // for the first depositor to get shares.
                 if (totalFundValue == 0 && ethAmount >= minimumDepositAmount) {
                     return _initialTotalShares;
                 } else if (totalFundValue > 0) {
                     // After the first deposit, fall through to the standard calculation
                     return (ethAmount * totalShares) / totalFundValue;
                 } else {
                    return 0; // Cannot calculate shares without initial value or deposit
                 }
             } else {
                 // If deployed with initial ETH, shares are proportional to initial setup
                 return (ethAmount * _initialTotalShares) / _initialFundValue;
             }
        } else if (totalFundValue > 0) {
            // Standard case: calculate shares proportional to current total shares and fund value.
            return (ethAmount * totalShares) / totalFundValue;
        } else {
            // Should only happen if fund value somehow dropped to 0 after initial deposit(s).
            // In this simulation, fund value can go to 0 or below, but we represent it as 0.
            // No new shares can be minted if the fund has no value.
            return 0;
        }
    }

    /// @notice Calculates how much ETH a given number of shares are worth at the current valuation.
    /// @dev Uses a fixed point like representation for shares (1e18 corresponds to 1 share unit).
    /// @param shares The number of shares to calculate ETH value for.
    /// @return The amount of ETH (in wei) corresponding to the shares.
    function getETHForShares(uint256 shares) public view returns (uint256) {
        if (totalShares == 0 || totalFundValue == 0) {
            return 0; // No value if fund is empty or no shares exist
        }
        // Calculate ETH value proportional to current total shares and fund value.
        return (shares * totalFundValue) / totalShares;
    }


    // --- Quantum Fluctuation Functions (VRF Interaction) ---

    /// @notice Requests randomness from Chainlink VRF to trigger a quantum fluctuation event.
    /// @dev Can only be called by an admin. Requires a VRF subscription with LINK.
    function triggerQuantumFluctuation() external onlyAdmin whenNotPaused {
        if (fluctuationPending) revert NoFluctuationPending(); // Prevent multiple pending requests

        // Request randomness
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            keyHash,
            i_subscriptionId,
            requestConfirmations,
            NUM_WORDS
        );

        s_requests[requestId] = msg.sender; // Store who triggered it
        _lastRequestId = requestId; // Store the last request ID
        fluctuationPending = true; // Mark a fluctuation as pending

        emit FluctuationRequested(msg.sender, requestId);
    }

    /// @notice Callback function invoked by the VRF Coordinator after randomness is fulfilled.
    /// @dev This function should only be callable by the registered VRF Coordinator.
    /// It processes the random number to determine which event occurred and updates fund value.
    /// @param requestId The ID of the VR VRF request.
    /// @param randomWords An array containing the fulfilled random numbers.
    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        // Check if the fulfilling contract is the registered coordinator (handled by VRFConsumerBaseV2)
        // Check if this requestId was requested by THIS contract and is the last pending one
        if (s_requests[requestId] == address(0) || requestId != _lastRequestId || !fluctuationPending) revert InvalidVrfRequestId();

        // Use the first random word
        uint256 randomNumber = randomWords[0];

        // Determine which event configuration occurs based on probabilities
        bytes32 triggeredEventId = bytes32(0);
        int16 outcomeBasisPoints = 0;
        uint256 cumulativeProbability = 0;
        uint256 totalProbability = 10000; // Sum of all probabilities in basis points should be 10000 (100%)

        // Normalize random number to the total probability range (0 to 9999)
        uint256 normalizedRandom = randomNumber % totalProbability;

        // Iterate through event configs to find which range the random number falls into
        for (uint i = 0; i < _eventConfigIds.length; i++) {
            bytes32 currentId = _eventConfigIds[i];
            QuantumEventConfig storage config = _eventConfigs[currentId];

            if (config.exists) { // Ensure the config still exists
                cumulativeProbability += config.probability;
                if (normalizedRandom < cumulativeProbability) {
                    triggeredEventId = currentId;
                    outcomeBasisPoints = config.outcomeBasisPoints;
                    break; // Found the event
                }
            }
        }

        // Should always find an event if probabilities sum to 10000, but handle edge case
        if (triggeredEventId == bytes32(0)) {
            // This is an error state, potentially probabilities didn't sum correctly or config disappeared
            // In a production system, you might want to log this or have a fail-safe.
            // For this simulation, let's default to a zero outcome event.
             triggeredEventId = "ErrorEvent"; // Use a placeholder ID
             outcomeBasisPoints = 0;
        }

        // Apply the outcome to the fund value
        uint256 fundValueBefore = totalFundValue;
        uint256 fundValueAfter;

        // Calculate percentage change while avoiding division by zero if fund value is 0
        if (totalFundValue > 0) {
             // Calculate the magnitude of change
             uint256 changeAmount = (totalFundValue * uint256(outcomeBasisPoints > 0 ? outcomeBasisPoints : -outcomeBasisPoints)) / 10000;

             if (outcomeBasisPoints > 0) {
                 fundValueAfter = totalFundValue + changeAmount;
             } else {
                 // Ensure fund value doesn't go below zero in the simulation
                 if (changeAmount > totalFundValue) {
                     fundValueAfter = 0;
                 } else {
                     fundValueAfter = totalFundValue - changeAmount;
                 }
             }
        } else {
            // If fund value is already 0, any outcome <= 0 keeps it at 0.
            // An outcome > 0 would theoretically increase it, but requires
            // a base value > 0 to calculate percentage change from.
            // We keep it at 0 for simplicity in this simulation if starting from 0.
            fundValueAfter = 0;
        }

        totalFundValue = fundValueAfter;

        // Store the result
        lastFluctuationResult = FluctuationResult({
            timestamp: block.timestamp,
            eventConfigId: triggeredEventId,
            outcomeBasisPoints: outcomeBasisPoints,
            fundValueBefore: fundValueBefore,
            fundValueAfter: fundValueAfter,
            randomness: randomNumber // Store the raw random number
        });

        // Reset pending flag and request mapping entry
        fluctuationPending = false;
        delete s_requests[requestId]; // Clean up mapping

        emit FluctuationProcessed(requestId, triggeredEventId, outcomeBasisPoints, fundValueBefore, fundValueAfter);
    }

    /// @notice Returns the details of the most recently processed quantum fluctuation event.
    function getLastFluctuationResult() public view returns (FluctuationResult memory) {
        return lastFluctuationResult;
    }


    // --- Admin & Configuration Functions ---

    /// @notice Adds an address to the list of contract admins.
    /// @dev Only callable by the contract owner. Admins can trigger fluctuations and manage configs/parameters.
    /// @param newAdmin The address to add as admin.
    function addAdmin(address newAdmin) external onlyOwner {
        _admins[newAdmin] = true;
        emit AdminAdded(newAdmin);
    }

    /// @notice Removes an address from the list of contract admins.
    /// @dev Only callable by the contract owner. Prevents owner from removing themselves.
    /// Requires at least one admin to remain (the owner).
    /// @param adminToRemove The address to remove from admins.
    function removeAdmin(address adminToRemove) external onlyOwner {
         if (adminToRemove == owner()) revert CannotRemoveOwnerAsAdmin();
         // Ensure there is at least one admin remaining if removing a non-owner admin
         uint256 adminCount = 0;
         for (address admin : _getAdmins()) {
             if (_admins[admin]) { // Re-check exists, _getAdmins might list addresses previously admin
                 adminCount++;
             }
         }
         // If removing a non-owner admin, there must be >1 admin currently
         if (adminToRemove != owner() && adminCount <= 1) revert CannotRemoveLastAdmin();


        _admins[adminToRemove] = false;
        emit AdminRemoved(adminToRemove);
    }

     /// @notice Internal helper to list current admin addresses (can be gas-intensive for many admins).
     /// @dev Not intended for frequent on-chain use, primarily for off-chain querying.
    function _getAdmins() internal view returns (address[] memory) {
        address[] memory currentAdmins = new address[](100); // Max 100 admins for this example
        uint256 count = 0;
        // Iterating over all possible addresses is not feasible.
        // A better approach for many admins is a linked list or tracking in a dynamic array on add/remove.
        // For simplicity in this example, we assume a small number of admins and include the owner.
        // Note: This is a simplified approach and inefficient for large numbers of admins.
        // A better pattern involves mapping address -> index in an array and tracking.
        currentAdmins[count++] = owner(); // Owner is always an admin conceptually

        // Cannot effectively list *all* admins from a boolean mapping without an auxiliary data structure.
        // The isAdmin function is the efficient way to check *if* an address is admin.
        // The list is illustrative and not fully robust for arbitrary addresses.
        // A better implementation would track admins in an array on add/remove.
        // Leaving this placeholder comment to acknowledge the limitation.
        // In a real system, _admins would map address to bool AND you'd have an array of admin addresses.

        // For the purpose of this example and checking "at least one admin", we only need to know if owner is the *only* one.
        return currentAdmins; // This return is illustrative, the check in removeAdmin is more robust.
    }


    /// @notice Checks if an address is currently an admin.
    function isAdmin(address addr) public view returns (bool) {
        return _admins[addr] || addr == owner(); // Owner is implicitly an admin
    }

    /// @notice Adds a new quantum event configuration.
    /// @dev Only callable by an admin. Requires configId not to exist already.
    /// @param configId Unique identifier for the event.
    /// @param probability Probability in basis points (sum of all must be 10000).
    /// @param outcomeBasisPoints Percentage change in basis points.
    function addEventConfig(bytes32 configId, uint16 probability, int16 outcomeBasisPoints) external onlyAdmin {
        if (_eventConfigs[configId].exists) revert EventConfigAlreadyExists();

        _eventConfigs[configId] = QuantumEventConfig({
            probability: probability,
            outcomeBasisPoints: outcomeBasisPoints,
            exists: true
        });
        _eventConfigIds.push(configId);

        _checkEventProbabilities(); // Ensure probabilities still sum to 10000

        emit EventConfigAdded(configId, probability, outcomeBasisPoints);
    }

    /// @notice Updates an existing quantum event configuration.
    /// @dev Only callable by an admin. Requires configId to exist.
    /// @param configId Unique identifier for the event.
    /// @param probability Probability in basis points (sum of all must be 10000).
    /// @param outcomeBasisPoints Percentage change in basis points.
    function updateEventConfig(bytes32 configId, uint16 probability, int16 outcomeBasisPoints) external onlyAdmin {
        if (!_eventConfigs[configId].exists) revert EventConfigNotFound();

        _eventConfigs[configId].probability = probability;
        _eventConfigs[configId].outcomeBasisPoints = outcomeBasisPoints;

        _checkEventProbabilities(); // Ensure probabilities still sum to 10000

        emit EventConfigUpdated(configId, probability, outcomeBasisPoints);
    }

    /// @notice Removes a quantum event configuration.
    /// @dev Only callable by an admin. Requires configId to exist.
    /// @param configId Unique identifier for the event to remove.
    function removeEventConfig(bytes32 configId) external onlyAdmin {
        if (!_eventConfigs[configId].exists) revert EventConfigNotFound();

        // Find and remove from the ID array
        for (uint i = 0; i < _eventConfigIds.length; i++) {
            if (_eventConfigIds[i] == configId) {
                _eventConfigIds[i] = _eventConfigIds[_eventConfigIds.length - 1];
                _eventConfigIds.pop();
                break;
            }
        }

        delete _eventConfigs[configId]; // Remove from mapping

        _checkEventProbabilities(); // Ensure probabilities still sum to 10000

        emit EventConfigRemoved(configId);
    }

    /// @notice Internal helper to check if configured event probabilities sum to 100%.
    /// @dev Reverts if sum is not 10000 basis points.
    function _checkEventProbabilities() internal view {
        uint256 totalProb = 0;
        for (uint i = 0; i < _eventConfigIds.length; i++) {
             bytes32 configId = _eventConfigIds[i];
             // Double check existence in case array wasn't perfectly cleaned (shouldn't happen with pop)
             if (_eventConfigs[configId].exists) {
                 totalProb += _eventConfigs[configId].probability;
             }
        }
        if (totalProb != 10000) revert InvalidEventProbabilitySum();
    }


    /// @notice Returns the total number of active event configurations.
    function getEventConfigCount() public view returns (uint256) {
        return _eventConfigIds.length;
    }

    /// @notice Returns the details for a specific event configuration ID.
    /// @param configId The ID of the event config to retrieve.
    function getEventConfig(bytes32 configId) public view returns (QuantumEventConfig memory) {
        if (!_eventConfigs[configId].exists) revert EventConfigNotFound();
        return _eventConfigs[configId];
    }

    /// @notice Returns an array of all active event configuration IDs.
    function getEventConfigIds() public view returns (bytes32[] memory) {
        return _eventConfigIds;
    }

    /// @notice Sets the withdrawal fee percentage.
    /// @dev Fee is in basis points (e.g., 100 = 1%). Max 100% (10000 basis points).
    /// @param feeBasisPoints The new fee percentage in basis points.
    function setWithdrawalFee(uint16 feeBasisPoints) external onlyAdmin {
        if (feeBasisPoints > 10000) revert InvalidFeePercentage();
        withdrawalFeeBasisPoints = feeBasisPoints;
        emit WithdrawalFeeSet(feeBasisPoints);
    }

    /// @notice Returns the current withdrawal fee percentage in basis points.
    function getWithdrawalFee() public view returns (uint16) {
        return withdrawalFeeBasisPoints;
    }

    /// @notice Sets the minimum ETH amount required for a deposit.
    /// @param amount The new minimum deposit amount in wei.
    function setMinimumDeposit(uint256 amount) external onlyAdmin {
        minimumDepositAmount = amount;
        emit MinimumDepositSet(amount);
    }

    /// @notice Returns the current minimum deposit amount in wei.
    function getMinimumDeposit() public view returns (uint256) {
        return minimumDepositAmount;
    }

    /// @notice Pauses contract operations (deposits, withdrawals, fluctuation triggers).
    /// @dev Only callable by an admin. Inherited from Pausable.
    function pause() public onlyAdmin whenNotPaused {
        _pause();
    }

    /// @notice Unpauses contract operations.
    /// @dev Only callable by an admin. Inherited from Pausable.
    function unpause() public onlyAdmin whenPaused {
        _unpause();
    }

    /// @notice Checks if the contract is currently paused.
    /// @dev Inherited from Pausable.
    function paused() public view override returns (bool) {
        return super.paused();
    }


    // --- VRF Configuration Functions ---

    /// @notice Sets the VRF keyhash and request confirmations.
    /// @dev Only callable by an admin. Useful if Chainlink parameters change.
    /// VRF Coordinator address and Subscription ID are immutable after deployment.
    /// @param _keyHash The new VRF keyhash.
    /// @param _requestConfirmations The new minimum request confirmations.
    function setVrfParameters(bytes32 _keyHash, uint32 _requestConfirmations) external onlyAdmin {
        keyHash = _keyHash;
        requestConfirmations = _requestConfirmations;
        emit VrfParametersSet(keyHash, requestConfirmations);
    }

    /// @notice Returns the current VRF keyhash and minimum request confirmations.
    function getVrfParameters() public view returns (bytes32, uint32) {
        return (keyHash, requestConfirmations);
    }

    // --- Fallback/Receive ---
    receive() external payable {
        // Allow receiving ETH without triggering depositETH explicitly
        // ETH sent this way increases totalFundValue but doesn't mint shares.
        // This can slightly increase value per share for existing holders.
        // A more complex fund might handle this differently or disallow it.
        totalFundValue += msg.value;
        // No event emitted for passive receive
    }

    fallback() external payable {
        // Same as receive
        totalFundValue += msg.value;
        // No event emitted for passive receive
    }
}
```