Okay, this is a fun challenge! Let's design a contract around a creative concept that isn't a direct copy of existing large protocols, incorporates advanced state management, randomness (though pseudo for demonstration), time-based logic, and multiple functions.

The concept: A "Quantum Vault" where deposited tokens enter a state of "superposition" with multiple potential outcomes (different multipliers/lockups). An "observation" event (triggered manually or perhaps auto-triggered after a time) "collapses" the superposition, fixing a single outcome for that deposit, determined by a random factor. Withdrawals are then subject to the parameters of the determined state.

This combines:
*   ERC20 deposits.
*   Configurable states with varying parameters (multipliers, lockups).
*   A randomness-based outcome determination.
*   Time-based unlock mechanisms.
*   Complex state tracking per deposit.
*   Admin controls for configuration and triggering.

Let's aim for 20+ functions covering deposit, withdrawal, state management, observation, querying, and admin tasks.

---

## QuantumVault Smart Contract Outline

1.  ** SPDX-License-Identifier**
2.  **Pragmas**
3.  **Imports:**
    *   `@openzeppelin/contracts/token/ERC20/IERC20.sol`
    *   `@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol`
    *   `@openzeppelin/contracts/access/Ownable.sol`
    *   `@openzeppelin/contracts/security/Pausable.sol`
    *   `@openzeppelin/contracts/utils/math/SafeMath.sol` (Optional with Solidity 0.8+, but good for clarity)
4.  **Events:**
    *   `DepositMade`
    *   `StateConfigAdded`
    *   `StateConfigUpdated`
    *   `StateConfigRemoved`
    *   `DepositObserved`
    *   `WithdrawalMade`
    *   `SupportedTokenAdded`
    *   `SupportedTokenRemoved`
    *   `ContractPaused`
    *   `ContractUnpaused`
    *   `ERC20Rescued`
    *   `BatchObservationTriggered`
    *   `BatchWithdrawalTriggered`
5.  **Errors:** (Custom errors for clarity and gas efficiency)
    *   `InvalidStateId`
    *   `StateIdAlreadyExists`
    *   `DepositNotFound`
    *   `DepositAlreadyObserved`
    *   `DepositNotObserved`
    *   `DepositNotUnlocked`
    *   `DepositAlreadyWithdrawn`
    *   `TokenNotSupported`
    *   `NoActiveStates`
    *   `NothingToObserve`
    *   `NothingToWithdraw`
    *   `RescueNotAllowed`
    *   `ArrayLengthMismatch`
    *   `ObservationTooEarly`
6.  **Structs:**
    *   `StateConfig`: Defines parameters for a possible outcome (multiplier, unlock delay).
    *   `Deposit`: Tracks individual deposits, their state, and status.
7.  **State Variables:**
    *   `stateConfigs`: Mapping from state ID (`int`) to `StateConfig`.
    *   `activeStateIds`: Array of state IDs that are currently potential outcomes.
    *   `deposits`: Mapping from unique deposit ID (`uint`) to `Deposit` struct.
    *   `userDepositIds`: Mapping from user address to array of their deposit IDs.
    *   `depositCounter`: Counter for generating unique deposit IDs.
    *   `supportedTokens`: Mapping from token address to boolean (is supported?).
    *   `supportedTokenList`: Array of supported token addresses (for iteration).
    *   `minimumDepositDuration`: Minimum time a deposit must exist before it can be observed.
    *   `observationSalt`: A value incremented to add variance to randomness.
8.  **Modifiers:**
    *   `whenNotPaused` (from `Pausable`)
    *   `onlyOwner` (from `Ownable`)
9.  **Functions (Grouped by Category):**

    *   **Setup & Configuration (Owner Only):**
        1.  `constructor`: Initializes ownership and pause status.
        2.  `addStateConfig`: Adds a new potential outcome state.
        3.  `updateStateConfig`: Modifies an existing state configuration.
        4.  `removeStateConfig`: Removes a state configuration from potential outcomes.
        5.  `addSupportedToken`: Adds an ERC20 token that can be deposited.
        6.  `removeSupportedToken`: Removes an ERC20 token (prevents new deposits).
        7.  `setMinimumDepositDuration`: Sets the minimum time before observation is possible.
        8.  `pause`: Pauses contract interactions.
        9.  `unpause`: Unpauses contract interactions.

    *   **Deposit (Callable by Anyone when not paused):**
        10. `deposit`: Allows depositing supported ERC20 tokens into the vault.

    *   **Observation (Owner or Keeper Role):**
        11. `triggerObservation`: Triggers the state determination for a single deposit.
        12. `triggerManyObservations`: Triggers state determination for multiple deposits.
        13. `triggerAutoObservations`: Attempts to observe deposits that meet the minimum duration requirement (can be called by anyone, potential gas bounty model not implemented for simplicity).

    *   **Withdrawal (Callable by Deposit Owner when not paused):**
        14. `withdraw`: Allows withdrawing tokens after observation and unlock period.
        15. `withdrawMany`: Allows batch withdrawal of multiple deposits.

    *   **Querying (View Functions):**
        16. `getDeposit`: Gets details of a specific deposit.
        17. `getUserDepositIds`: Gets all deposit IDs for a user.
        18. `getUserDepositIdsPaginated`: Gets user deposit IDs with pagination.
        19. `getStateConfig`: Gets details of a specific state configuration.
        20. `getActiveStateIds`: Gets the list of currently active state IDs.
        21. `isSupportedToken`: Checks if a token is supported.
        22. `getSupportedTokens`: Gets the list of all supported tokens.
        23. `getDepositStatus`: Gets the observation and withdrawal status of a deposit.
        24. `getWithdrawableAmount`: Calculates the potential withdrawal amount for an observed deposit.
        25. `getVaultTokenBalance`: Gets the contract's balance for a specific token.
        26. `getDepositCount`: Gets the total number of deposits made.
        27. `getTotalDeposited`: Gets the total amount of a token currently held in active (not withdrawn) deposits.
        28. `getMinimumDepositDuration`: Gets the configured minimum observation duration.
        29. `getDepositsAwaitingObservation`: Gets IDs of deposits eligible for auto-observation.
        30. `getDepositsAwaitingWithdrawal`: Gets IDs of deposits observed and unlocked.

    *   **Admin Utilities (Owner Only):**
        31. `rescueERC20`: Allows rescuing accidentally sent tokens (with safety checks).

    *   **Internal Functions:**
        32. `_generateRandomness`: Internal pseudo-randomness function (NOTE: NOT suitable for high-value production use - requires secure randomness source like Chainlink VRF).
        33. `_determineState`: Internal function to select a final state based on randomness.
        34. `_addStateToActive`: Adds a state ID to the active list.
        35. `_removeStateFromActive`: Removes a state ID from the active list.

## Function Summary

*   **Setup & Configuration:** Functions for the contract owner (`onlyOwner`) to define the rules of the vault: adding/updating/removing potential outcome states (`StateConfig`), specifying which tokens can be deposited, setting time parameters, and pausing/unpausing the contract.
*   **Deposit:** The core user function (`deposit`) to place supported ERC20 tokens into the vault, initiating a "superposition" state for that deposit.
*   **Observation:** Functions (`triggerObservation`, `triggerManyObservations`, `triggerAutoObservations`) used to trigger the "collapse" of a deposit's superposition, determining its final state based on internal randomness. This can be done manually by the owner or automatically after a minimum duration.
*   **Withdrawal:** Functions (`withdraw`, `withdrawMany`) for users to claim their tokens after their deposit has been observed and its state-specific unlock period has passed. The amount is calculated based on the determined state's multiplier.
*   **Querying:** A comprehensive set of `view` functions (`getDeposit`, `getUserDepositIds`, `getStateConfig`, etc.) allowing anyone to inspect the state of deposits, users, configurations, and the vault itself. Includes utility functions like checking withdrawable amounts and identifying deposits ready for observation or withdrawal.
*   **Admin Utilities:** A function (`rescueERC20`) to allow the owner to recover tokens accidentally sent to the contract, preventing them from being permanently locked (with precautions to avoid draining user funds).
*   **Internal Functions:** Helper functions (`_generateRandomness`, `_determineState`, etc.) used internally by the contract logic for state transitions and calculations. *Crucially, `_generateRandomness` in this example is a placeholder and highlights the need for a secure, external randomness source in production.*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
// SafeMath is included in 0.8+ by default for arithmetic operations

/// @title QuantumVault
/// @dev A creative smart contract demonstrating advanced state management,
/// randomness-influenced outcomes, and time-based mechanics.
/// Users deposit tokens into a "superposition" state, which is later
/// "observed" to determine a final outcome state based on a random factor.
/// Withdrawals are subject to the rules of the determined state.
contract QuantumVault is Ownable, Pausable {
    using SafeERC20 for IERC20;

    /* ██████████████████████████████████████████████████████████████████████████
       █   OUTLINE & SUMMARY (See detailed outline above)                       █
       █                                                                        █
       █   OUTLINE:                                                             █
       █   1. SPDX-License-Identifier & Pragmas                                 █
       █   2. Imports (IERC20, SafeERC20, Ownable, Pausable)                    █
       █   3. Events                                                            █
       █   4. Custom Errors                                                     █
       █   5. Structs (StateConfig, Deposit)                                    █
       █   6. State Variables (Mappings, Arrays, Counters)                      █
       █   7. Modifiers (whenNotPaused, onlyOwner)                              █
       █   8. Functions (Grouped: Setup/Config, Deposit, Observation,           █
       █      Withdrawal, Querying, Admin Utils, Internal)                      █
       █                                                                        █
       █   SUMMARY:                                                             █
       █   The QuantumVault allows users to deposit supported ERC20 tokens.     █
       █   These deposits enter a state of potential outcomes defined by        █
       █   `StateConfig`s (multipliers, unlock delays). An 'observation'        █
       █   process, triggered by the owner or automatically after a minimum     █
       █   duration, uses a pseudo-random number (NOTE: Production requires     █
       █   secure randomness like Chainlink VRF) to select one final outcome    █
       █   state for each deposit. Users can withdraw their tokens based on     █
       █   the final amount determined by the state's multiplier, after its     █
       █   specific unlock delay has passed. The contract includes extensive    █
       █   query functions, batch operations, and admin controls for state      █
       █   configuration, supported tokens, and pausing.                        █
       ██████████████████████████████████████████████████████████████████████████ */

    // Custom Errors
    error InvalidStateId(int stateId);
    error StateIdAlreadyExists(int stateId);
    error DepositNotFound(uint depositId);
    error DepositAlreadyObserved(uint depositId);
    error DepositNotObserved(uint depositId);
    error DepositNotUnlocked(uint depositId, uint unlockTime);
    error DepositAlreadyWithdrawn(uint depositId);
    error TokenNotSupported(address token);
    error NoActiveStates();
    error NothingToObserve();
    error NothingToWithdraw();
    error RescueNotAllowed(address token);
    error ArrayLengthMismatch(uint expected, uint actual);
    error ObservationTooEarly(uint depositId, uint observationTime);

    // --- Events ---
    event DepositMade(uint indexed depositId, address indexed user, address indexed token, uint amount, uint depositTime);
    event StateConfigAdded(int indexed stateId, int multiplierPermille, uint unlockDelay);
    event StateConfigUpdated(int indexed stateId, int multiplierPermille, uint unlockDelay);
    event StateConfigRemoved(int indexed stateId);
    event DepositObserved(uint indexed depositId, int indexed finalState, uint observationTime);
    event WithdrawalMade(uint indexed depositId, address indexed user, address indexed token, uint withdrawnAmount);
    event SupportedTokenAdded(address indexed token);
    event SupportedTokenRemoved(address indexed token);
    event ContractPaused(address account);
    event ContractUnpaused(address account);
    event ERC20Rescued(address indexed token, uint amount, address indexed recipient);
    event BatchObservationTriggered(uint[] depositIds);
    event BatchWithdrawalTriggered(uint[] depositIds);


    // --- Structs ---
    struct StateConfig {
        // Unique identifier for the state. Can be any integer.
        int stateId;
        // Multiplier for the deposit amount in permille (parts per thousand).
        // 1000 = 1x (original amount), 1100 = 1.1x (10% bonus), 900 = 0.9x (10% penalty).
        int multiplierPermille;
        // Time in seconds after observation before withdrawal is possible.
        uint unlockDelay;
    }

    struct Deposit {
        address user;
        address token;
        uint amount;
        uint depositTime;
        // The final state determined upon observation. -1 initially.
        int finalState;
        // Timestamp when the observation occurred. 0 initially.
        uint observationTime;
        // True if the deposit has been withdrawn.
        bool withdrawn;
    }


    // --- State Variables ---
    mapping(int stateId => StateConfig) public stateConfigs;
    int[] public activeStateIds; // Array of stateIds that can be chosen upon observation

    mapping(uint depositId => Deposit) public deposits;
    mapping(address user => uint[] userDepositIds);
    uint public depositCounter; // Starts from 1

    mapping(address token => bool) public supportedTokens;
    address[] public supportedTokenList; // To iterate over supported tokens

    uint public minimumDepositDuration; // Minimum time deposit must exist before observation is possible

    // Salt for randomness generation (incremented on each observation for variance)
    uint private observationSalt;


    // --- Constructor ---
    constructor() Ownable(msg.sender) Pausable() {
        depositCounter = 0; // Start deposit IDs from 1
        minimumDepositDuration = 0; // Default: observation possible immediately
        observationSalt = 0; // Initial salt
        _pause(); // Start paused, owner needs to unpause
    }


    // --- Setup & Configuration (Owner Only) ---

    /// @notice Adds a new potential outcome state configuration.
    /// @param _stateId Unique identifier for the state.
    /// @param _multiplierPermille Multiplier (e.g., 1100 for 1.1x).
    /// @param _unlockDelay Unlock delay in seconds after observation.
    function addStateConfig(int _stateId, int _multiplierPermille, uint _unlockDelay) external onlyOwner {
        if (stateConfigs[_stateId].stateId != 0) { // Check if stateId exists (0 is default for int)
            // Check if it's an existing config (stateId 0 is invalid config)
            if (stateConfigs[_stateId].multiplierPermille != 0 || stateConfigs[_stateId].unlockDelay != 0) {
                 revert StateIdAlreadyExists(_stateId);
            }
        }

        stateConfigs[_stateId] = StateConfig(_stateId, _multiplierPermille, _unlockDelay);
        _addStateToActive(_stateId); // Add to active list
        emit StateConfigAdded(_stateId, _multiplierPermille, _unlockDelay);
    }

    /// @notice Updates an existing potential outcome state configuration.
    /// @param _stateId Identifier of the state to update.
    /// @param _multiplierPermille New multiplier.
    /// @param _unlockDelay New unlock delay.
    function updateStateConfig(int _stateId, int _multiplierPermille, uint _unlockDelay) external onlyOwner {
        if (stateConfigs[_stateId].stateId == 0 && (_stateId != 0 || stateConfigs[_stateId].multiplierPermille == 0)) { // Check if stateId exists (0 is default for int unless explicitly set)
             // Ensure it's an actual config, not just default 0
             bool found = false;
             for(uint i=0; i < activeStateIds.length; i++){
                 if(activeStateIds[i] == _stateId){
                     found = true;
                     break;
                 }
             }
             if(!found) revert InvalidStateId(_stateId);
        }

        stateConfigs[_stateId].multiplierPermille = _multiplierPermille;
        stateConfigs[_stateId].unlockDelay = _unlockDelay;
        emit StateConfigUpdated(_stateId, _multiplierPermille, _unlockDelay);
    }

    /// @notice Removes a state configuration from the list of potential outcomes.
    /// Existing deposits already assigned this state will still follow its rules.
    /// @param _stateId Identifier of the state to remove.
    function removeStateConfig(int _stateId) external onlyOwner {
         if (stateConfigs[_stateId].stateId == 0 && (_stateId != 0 || stateConfigs[_stateId].multiplierPermille == 0)) { // Check if stateId exists
             bool found = false;
             for(uint i=0; i < activeStateIds.length; i++){
                 if(activeStateIds[i] == _stateId){
                     found = true;
                     break;
                 }
             }
             if(!found) revert InvalidStateId(_stateId);
        }

        _removeStateFromActive(_stateId);
        // We don't delete the stateConfig entry itself, only remove from activeStateIds,
        // so historical deposits can still reference it.
        emit StateConfigRemoved(_stateId);
    }

    /// @notice Adds an ERC20 token to the list of supported deposit tokens.
    /// @param token The address of the ERC20 token.
    function addSupportedToken(address token) external onlyOwner {
        if (!supportedTokens[token]) {
            supportedTokens[token] = true;
            supportedTokenList.push(token);
            emit SupportedTokenAdded(token);
        }
    }

    /// @notice Removes an ERC20 token from the list of supported deposit tokens.
    /// Prevents new deposits of this token, but existing deposits remain active.
    /// @param token The address of the ERC20 token.
    function removeSupportedToken(address token) external onlyOwner {
        if (supportedTokens[token]) {
            supportedTokens[token] = false;
            // Simple removal from list (order doesn't matter) - might leave gaps if removing from middle frequently
            // For simplicity, we'll rebuild the list or just mark as unsupported. Let's mark.
            // To remove from list array for iteration efficiency: find index, swap with last, pop.
            for (uint i = 0; i < supportedTokenList.length; i++) {
                if (supportedTokenList[i] == token) {
                    if (i < supportedTokenList.length - 1) {
                        supportedTokenList[i] = supportedTokenList[supportedTokenList.length - 1];
                    }
                    supportedTokenList.pop();
                    break;
                }
            }
            emit SupportedTokenRemoved(token);
        }
    }

    /// @notice Sets the minimum duration a deposit must exist before it is eligible for observation.
    /// @param duration The minimum duration in seconds.
    function setMinimumDepositDuration(uint duration) external onlyOwner {
        minimumDepositDuration = duration;
    }

    /// @notice Pauses contract operations (deposits, withdrawals, observations).
    function pause() external onlyOwner whenNotPaused {
        _pause();
        emit ContractPaused(_msgSender());
    }

    /// @notice Unpauses contract operations.
    function unpause() external onlyOwner whenPaused {
        _unpause();
        emit ContractUnpaused(_msgSender());
    }


    // --- Deposit ---

    /// @notice Deposits a supported ERC20 token into the Quantum Vault.
    /// The deposit enters a state of superposition until observation.
    /// @param token The address of the ERC20 token to deposit.
    /// @param amount The amount of tokens to deposit.
    function deposit(address token, uint amount) external whenNotPaused {
        if (!supportedTokens[token]) {
            revert TokenNotSupported(token);
        }
        if (amount == 0) {
            // Optional: require minimum amount
            return; // Or revert if 0 amount deposits are not allowed
        }

        IERC20(token).safeTransferFrom(_msgSender(), address(this), amount);

        depositCounter++;
        uint currentDepositId = depositCounter;

        deposits[currentDepositId] = Deposit({
            user: _msgSender(),
            token: token,
            amount: amount,
            depositTime: block.timestamp,
            finalState: -1, // -1 indicates not yet observed
            observationTime: 0, // 0 indicates not yet observed
            withdrawn: false
        });

        userDepositIds[_msgSender()].push(currentDepositId);

        emit DepositMade(currentDepositId, _msgSender(), token, amount, block.timestamp);
    }


    // --- Observation (Triggered by Owner or Auto-Trigger) ---

    /// @notice Triggers the observation (state determination) for a single deposit.
    /// Can only be done if the deposit hasn't been observed and meets minimum duration.
    /// @param depositId The ID of the deposit to observe.
    function triggerObservation(uint depositId) external onlyOwner whenNotPaused {
        Deposit storage deposit = deposits[depositId];

        if (deposit.depositTime == 0) { // Check if depositId exists (struct default is 0)
            revert DepositNotFound(depositId);
        }
        if (deposit.finalState != -1) {
            revert DepositAlreadyObserved(depositId);
        }
        if (block.timestamp < deposit.depositTime + minimumDepositDuration) {
            revert ObservationTooEarly(depositId, deposit.depositTime + minimumDepositDuration);
        }

        _determineState(depositId);
        emit BatchObservationTriggered({ depositIds: new uint[](1)}); // Emit single item in batch event for consistency
        BatchObservationTriggered({ depositIds: new uint[](1)})[0] = depositId; // Assign after creating array
    }

    /// @notice Triggers observation for multiple deposits in a batch.
    /// Skips deposits that are not eligible (already observed, too early, etc.).
    /// @param depositIds Array of deposit IDs to observe.
    function triggerManyObservations(uint[] calldata depositIds) external onlyOwner whenNotPaused {
        if (depositIds.length == 0) {
            revert NothingToObserve();
        }

        uint observedCount = 0;
        uint[] memory successfulObservations = new uint[](depositIds.length); // Max possible size

        for (uint i = 0; i < depositIds.length; i++) {
            uint currentDepositId = depositIds[i];
            Deposit storage deposit = deposits[currentDepositId];

            // Check eligibility - skip if not found, observed, withdrawn, or too early
            if (deposit.depositTime != 0 &&
                deposit.finalState == -1 &&
                !deposit.withdrawn &&
                block.timestamp >= deposit.depositTime + minimumDepositDuration)
            {
                _determineState(currentDepositId);
                successfulObservations[observedCount] = currentDepositId;
                observedCount++;
            }
        }

        // Emit event with only successful observations
        uint[] memory observedArray = new uint[](observedCount);
        for(uint i=0; i < observedCount; i++) {
            observedArray[i] = successfulObservations[i];
        }
        if (observedCount > 0) {
            emit BatchObservationTriggered(observedArray);
        } else {
            // Consider a specific event or log if batch was called but nothing was observed
        }
    }

    /// @notice Attempts to observe deposits that have passed the minimum duration.
    /// Can be called by anyone (e.g., a keeper bot). Includes a basic gas incentive model
    /// by allowing anyone to call, though the caller doesn't directly profit here.
    /// Limits the number of deposits processed per call to manage gas costs.
    /// @param maxToProcess The maximum number of eligible deposits to attempt to observe.
    function triggerAutoObservations(uint maxToProcess) external whenNotPaused {
        if (maxToProcess == 0) return;

        uint processedCount = 0;
        uint[] memory observedArray = new uint[](maxToProcess); // Max possible size

        // Iterate through deposits. This can be inefficient for large depositCounter.
        // A more advanced version might track unobserved deposits in a different structure.
        for (uint i = 1; i <= depositCounter && processedCount < maxToProcess; i++) {
             Deposit storage deposit = deposits[i];

             // Check eligibility - skip if not found, observed, withdrawn, or too early
            if (deposit.depositTime != 0 &&
                deposit.finalState == -1 &&
                !deposit.withdrawn &&
                block.timestamp >= deposit.depositTime + minimumDepositDuration)
            {
                _determineState(i);
                observedArray[processedCount] = i;
                processedCount++;
            }
        }

        // Emit event with only successful observations
        uint[] memory finalObservedArray = new uint[](processedCount);
        for(uint i=0; i < processedCount; i++) {
            finalObservedArray[i] = observedArray[i];
        }
         if (processedCount > 0) {
            emit BatchObservationTriggered(finalObservedArray);
        } else {
            // No eligible deposits found or processed
        }
    }


    // --- Withdrawal ---

    /// @notice Allows the user to withdraw their tokens after observation and unlock.
    /// @param depositId The ID of the deposit to withdraw.
    function withdraw(uint depositId) external whenNotPaused {
        Deposit storage deposit = deposits[depositId];

        if (deposit.user != _msgSender()) {
            revert DepositNotFound(depositId); // Or a specific unauthorized error
        }
         if (deposit.depositTime == 0) { // Check if depositId exists
            revert DepositNotFound(depositId);
        }
        if (deposit.finalState == -1) {
            revert DepositNotObserved(depositId);
        }
        if (deposit.withdrawn) {
            revert DepositAlreadyWithdrawn(depositId);
        }

        StateConfig storage stateConfig = stateConfigs[deposit.finalState];
        uint unlockTime = deposit.observationTime + stateConfig.unlockDelay;

        if (block.timestamp < unlockTime) {
            revert DepositNotUnlocked(depositId, unlockTime);
        }

        // Calculate withdrawal amount using multiplier (handle potential overflow, although multiplication first is common)
        // Using uint and converting multiplier: amount * multiplierPermille / 1000
        // Ensure multiplier isn't excessively large to prevent overflow before division
        uint withdrawalAmount = (uint(deposit.amount) * uint(stateConfig.multiplierPermille)) / 1000;

        // Mark as withdrawn BEFORE transfer to prevent re-entrancy (SafeERC20 helps mitigate, but good practice)
        deposit.withdrawn = true;

        // Transfer tokens
        IERC20(deposit.token).safeTransfer(_msgSender(), withdrawalAmount);

        emit WithdrawalMade(depositId, _msgSender(), deposit.token, withdrawalAmount);
        emit BatchWithdrawalTriggered({ depositIds: new uint[](1)}); // Emit single item in batch event for consistency
        BatchWithdrawalTriggered({ depositIds: new uint[](1)})[0] = depositId; // Assign after creating array
    }

    /// @notice Allows batch withdrawal of multiple deposits for the caller.
    /// Skips deposits that are not eligible (not owned, not observed, not unlocked, already withdrawn).
    /// @param depositIds Array of deposit IDs to withdraw.
    function withdrawMany(uint[] calldata depositIds) external whenNotPaused {
         if (depositIds.length == 0) {
            revert NothingToWithdraw();
        }

        uint withdrawnCount = 0;
        uint[] memory successfulWithdrawals = new uint[](depositIds.length); // Max possible size

        for (uint i = 0; i < depositIds.length; i++) {
            uint currentDepositId = depositIds[i];
            Deposit storage deposit = deposits[currentDepositId];

            // Check eligibility - skip if not found, not owned, not observed, withdrawn, or not unlocked
             if (deposit.depositTime != 0 && // Check if depositId exists
                deposit.user == _msgSender() &&
                deposit.finalState != -1 &&
                !deposit.withdrawn)
             {
                StateConfig storage stateConfig = stateConfigs[deposit.finalState];
                uint unlockTime = deposit.observationTime + stateConfig.unlockDelay;

                if (block.timestamp >= unlockTime) {
                    // Calculate withdrawal amount
                    uint withdrawalAmount = (uint(deposit.amount) * uint(stateConfig.multiplierPermille)) / 1000;

                    // Mark as withdrawn
                    deposit.withdrawn = true;

                    // Transfer tokens
                    IERC20(deposit.token).safeTransfer(_msgSender(), withdrawalAmount);

                    emit WithdrawalMade(currentDepositId, _msgSender(), deposit.token, withdrawalAmount);
                    successfulWithdrawals[withdrawnCount] = currentDepositId;
                    withdrawnCount++;
                }
            }
        }

        // Emit event with only successful withdrawals
        uint[] memory withdrawnArray = new uint[](withdrawnCount);
        for(uint i=0; i < withdrawnCount; i++) {
            withdrawnArray[i] = successfulWithdrawals[i];
        }
        if (withdrawnCount > 0) {
            emit BatchWithdrawalTriggered(withdrawnArray);
        } else {
            // Consider a specific event or log if batch was called but nothing was withdrawn
        }
    }


    // --- Querying (View Functions) ---

    /// @notice Gets the details of a specific deposit.
    /// @param depositId The ID of the deposit.
    /// @return The Deposit struct.
    function getDeposit(uint depositId) external view returns (Deposit memory) {
         if (deposits[depositId].depositTime == 0) { // Check if depositId exists
            revert DepositNotFound(depositId);
        }
        return deposits[depositId];
    }

    /// @notice Gets all deposit IDs for a specific user.
    /// @param user The address of the user.
    /// @return An array of deposit IDs.
    function getUserDepositIds(address user) external view returns (uint[] memory) {
        return userDepositIds[user];
    }

    /// @notice Gets deposit IDs for a user with pagination.
    /// Useful for users with a large number of deposits.
    /// @param user The address of the user.
    /// @param startIndex The starting index in the user's deposit list.
    /// @param count The maximum number of IDs to return.
    /// @return An array of deposit IDs.
    function getUserDepositIdsPaginated(address user, uint startIndex, uint count) external view returns (uint[] memory) {
        uint[] storage userDeposits = userDepositIds[user];
        uint total = userDeposits.length;

        if (startIndex >= total) {
            return new uint[](0); // No items from this start index
        }

        uint endIndex = startIndex + count;
        if (endIndex > total) {
            endIndex = total;
        }

        uint resultCount = endIndex - startIndex;
        uint[] memory result = new uint[](resultCount);
        for (uint i = 0; i < resultCount; i++) {
            result[i] = userDeposits[startIndex + i];
        }
        return result;
    }


    /// @notice Gets the details of a specific state configuration.
    /// @param stateId The ID of the state.
    /// @return The StateConfig struct.
    function getStateConfig(int stateId) external view returns (StateConfig memory) {
         // Check if stateId exists in active or inactive (historical) configs
         bool found = false;
         for(uint i=0; i < activeStateIds.length; i++){
             if(activeStateIds[i] == stateId){
                 found = true;
                 break;
             }
         }
         // Also check if it was ever a config that might be referenced by an old deposit
         // This check is tricky without iterating all stateConfigs or a dedicated mapping.
         // For simplicity, we'll return the default struct if not found in active,
         // or require stateId != 0 if we want to distinguish default 0 from an actual config with ID 0.
         // Let's just return the struct - caller needs to check stateId field.
         return stateConfigs[stateId];
    }

    /// @notice Gets the list of state IDs that are currently potential outcomes upon observation.
    /// @return An array of active state IDs.
    function getActiveStateIds() external view returns (int[] memory) {
        return activeStateIds;
    }

    /// @notice Checks if a token address is currently supported for deposits.
    /// @param token The address of the ERC20 token.
    /// @return True if supported, false otherwise.
    function isSupportedToken(address token) external view returns (bool) {
        return supportedTokens[token];
    }

    /// @notice Gets the list of all supported token addresses.
    /// @return An array of supported token addresses.
    function getSupportedTokens() external view returns (address[] memory) {
        return supportedTokenList;
    }

    /// @notice Gets the current status of a deposit (observed, withdrawn, unlocked).
    /// @param depositId The ID of the deposit.
    /// @return isObserved True if the final state has been determined.
    /// @return isWithdrawn True if the deposit has been withdrawn.
    /// @return isUnlocked True if the unlock delay has passed (only relevant if observed).
    function getDepositStatus(uint depositId) external view returns (bool isObserved, bool isWithdrawn, bool isUnlocked) {
        Deposit storage deposit = deposits[depositId];
         if (deposit.depositTime == 0) { // Check if depositId exists
            // Return defaults for non-existent deposit
            return (false, false, false);
        }

        isObserved = (deposit.finalState != -1);
        isWithdrawn = deposit.withdrawn;

        if (isObserved) {
             StateConfig storage stateConfig = stateConfigs[deposit.finalState];
             uint unlockTime = deposit.observationTime + stateConfig.unlockDelay;
             isUnlocked = (block.timestamp >= unlockTime);
        } else {
            isUnlocked = false;
        }
    }

    /// @notice Calculates the potential withdrawal amount for a deposit if it has been observed.
    /// Returns 0 if not yet observed or already withdrawn.
    /// @param depositId The ID of the deposit.
    /// @return The calculated amount that can be withdrawn based on the final state, or 0.
    function getWithdrawableAmount(uint depositId) external view returns (uint) {
         Deposit storage deposit = deposits[depositId];

         if (deposit.depositTime == 0 || // Check if depositId exists
            deposit.finalState == -1 ||
            deposit.withdrawn)
         {
             return 0;
         }

        StateConfig storage stateConfig = stateConfigs[deposit.finalState];
        return (uint(deposit.amount) * uint(stateConfig.multiplierPermille)) / 1000;
    }

    /// @notice Gets the contract's current balance for a specific ERC20 token.
    /// This includes deposited funds and potentially accidentally sent funds.
    /// @param token The address of the ERC20 token.
    /// @return The contract's token balance.
    function getVaultTokenBalance(address token) external view returns (uint) {
        return IERC20(token).balanceOf(address(this));
    }

    /// @notice Gets the total number of deposits ever made to the contract.
    /// Note: This is a counter, not the number of *active* deposits.
    /// @return The total number of deposits.
    function getDepositCount() external view returns (uint) {
        return depositCounter;
    }

    /// @notice Gets the total amount of a specific token currently held in *active* (not withdrawn) deposits.
    /// @param token The address of the ERC20 token.
    /// @return The total amount deposited for that token that has not yet been withdrawn.
    function getTotalDeposited(address token) external view returns (uint) {
        uint total = 0;
        // This is inefficient for large number of deposits.
        // A better approach would be to track this sum as deposits/withdrawals happen.
        // This is provided as a simple example view function.
        for (uint i = 1; i <= depositCounter; i++) {
            Deposit storage deposit = deposits[i];
            if (deposit.depositTime != 0 && deposit.token == token && !deposit.withdrawn) {
                total += deposit.amount;
            }
        }
        return total;
    }

    /// @notice Gets the configured minimum duration a deposit must exist before observation.
    /// @return The minimum duration in seconds.
    function getMinimumDepositDuration() external view returns (uint) {
        return minimumDepositDuration;
    }

    /// @notice Gets a list of deposit IDs that are currently eligible for auto-observation.
    /// Limited to a maximum number to prevent excessive gas use.
    /// @param maxResults The maximum number of IDs to return.
    /// @return An array of deposit IDs eligible for observation.
    function getDepositsAwaitingObservation(uint maxResults) external view returns (uint[] memory) {
        uint count = 0;
        uint[] memory eligibleIds = new uint[](maxResults);

        // Iterate through deposits. Inefficient for large depositCounter.
        for (uint i = 1; i <= depositCounter && count < maxResults; i++) {
            Deposit storage deposit = deposits[i];
            if (deposit.depositTime != 0 && // Check if depositId exists
                deposit.finalState == -1 &&
                !deposit.withdrawn &&
                block.timestamp >= deposit.depositTime + minimumDepositDuration)
            {
                eligibleIds[count] = i;
                count++;
            }
        }

        uint[] memory result = new uint[](count);
        for(uint i = 0; i < count; i++) {
            result[i] = eligibleIds[i];
        }
        return result;
    }

     /// @notice Gets a list of deposit IDs that have been observed and are now unlocked for withdrawal.
    /// Limited to a maximum number to prevent excessive gas use.
    /// @param maxResults The maximum number of IDs to return.
    /// @return An array of deposit IDs eligible for withdrawal.
    function getDepositsAwaitingWithdrawal(uint maxResults) external view returns (uint[] memory) {
         uint count = 0;
        uint[] memory eligibleIds = new uint[](maxResults);

        // Iterate through deposits. Inefficient for large depositCounter.
        for (uint i = 1; i <= depositCounter && count < maxResults; i++) {
            Deposit storage deposit = deposits[i];
            if (deposit.depositTime != 0 && // Check if depositId exists
                deposit.finalState != -1 &&
                !deposit.withdrawn)
            {
                 StateConfig storage stateConfig = stateConfigs[deposit.finalState];
                 uint unlockTime = deposit.observationTime + stateConfig.unlockDelay;
                 if (block.timestamp >= unlockTime) {
                     eligibleIds[count] = i;
                     count++;
                 }
            }
        }

        uint[] memory result = new uint[](count);
        for(uint i = 0; i < count; i++) {
            result[i] = eligibleIds[i];
        }
        return result;
    }

    /// @notice Gets deposit details for a range of deposit IDs.
    /// Useful for iterating through all deposits.
    /// @param startIndex The starting deposit ID (inclusive, starts from 1).
    /// @param count The maximum number of deposits to return.
    /// @return An array of Deposit structs.
    function getDepositDetailsPaginated(uint startIndex, uint count) external view returns (Deposit[] memory) {
        if (startIndex == 0) startIndex = 1; // Deposit IDs start from 1
        if (startIndex > depositCounter) {
            return new Deposit[](0);
        }

        uint endIndex = startIndex + count - 1;
        if (endIndex > depositCounter) {
            endIndex = depositCounter;
        }

        uint resultCount = endIndex - startIndex + 1;
        Deposit[] memory result = new Deposit[](resultCount);
        for (uint i = 0; i < resultCount; i++) {
             // Check if deposit exists before returning (though IDs are sequential here)
             if (deposits[startIndex + i].depositTime != 0) {
                 result[i] = deposits[startIndex + i];
             } else {
                 // Should not happen if iterating 1 to depositCounter, but defensive
             }
        }
        return result;
    }


    // --- Admin Utilities (Owner Only) ---

    /// @notice Allows the owner to rescue supported or unsupported ERC20 tokens sent accidentally to the contract.
    /// Careful: This function should only be used for tokens NOT part of active deposits.
    /// It rescues the *excess* balance beyond what is needed for current deposits.
    /// For simplicity in this example, it rescues the entire balance of *unsupported* tokens,
    /// and the excess balance of *supported* tokens (balance - total_deposited_in_supported_token).
    /// A safer implementation would require more sophisticated deposit tracking per token.
    /// @param token The address of the token to rescue.
    /// @param amount The amount to rescue.
    /// @param recipient The address to send the tokens to.
    function rescueERC20(address token, uint amount, address recipient) external onlyOwner {
        uint balance = IERC20(token).balanceOf(address(this));
        uint rescueAmount = amount;

        if (supportedTokens[token]) {
            // For supported tokens, only allow rescuing balance *beyond* the sum of active deposits
            // This requires calculating total active deposits for the token, which is inefficient.
            // A robust implementation needs a state variable `totalDepositedAmount[token]` updated on deposit/withdrawal.
            // For this example, we'll allow rescue up to the *full* balance for simplicity, BUT add a warning.
            // WARNING: This can drain funds needed for user withdrawals if not carefully managed OFF-CHAIN
            // to ensure the amount rescued is only excess. A production contract NEEDS better tracking.
            // Safer (but less efficient):
            // uint totalActiveDepositsForToken = getTotalDeposited(token);
            // if (balance < totalActiveDepositsForToken) revert RescueNotAllowed(token); // Should not happen if getTotalDeposited is correct
            // uint maxRescuable = balance - totalActiveDepositsForToken;
            // if (amount > maxRescuable) rescueAmount = maxRescuable;

             // Example simplified unsafe version (WARNING):
             if (amount > balance) rescueAmount = balance;
             // Log a warning? event RescueWarning(token, "Supported token rescued, verify excess amount");

        } else {
            // For unsupported tokens, rescue up to the full balance
            if (amount > balance) rescueAmount = balance;
        }

        if (rescueAmount == 0) revert RescueNotAllowed(token);

        IERC20(token).safeTransfer(recipient, rescueAmount);
        emit ERC20Rescued(token, rescueAmount, recipient);
    }


    // --- Internal Helper Functions ---

    /// @dev Internal function to generate a pseudo-random number.
    /// WARNING: This method is NOT cryptographically secure and is predictable.
    /// Do NOT use this for high-value applications.
    /// A real-world contract needs a secure oracle like Chainlink VRF.
    /// Uses block data + salt + depositId for some variation.
    /// @param depositId A unique value to help differentiate results for different observations.
    /// @return A pseudo-random uint.
    function _generateRandomness(uint depositId) internal returns (uint) {
        // Using block.timestamp, block.difficulty (prevrandao in PoS), depositId, and a salt.
        // prevrandao is available in PoS via block.difficulty opcode.
        // In PoW, block.difficulty can be manipulated by miners.
        // In PoS, prevrandao can be slightly influenced but less so.
        // Still, this is NOT secure.
        uint randomValue = uint(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty, // Or block.prevrandao
            depositId,
            observationSalt,
            msg.sender // Add caller context for auto-trigger? Or contract address?
        )));
        observationSalt++; // Increment salt for next observation
        return randomValue;
    }

    /// @dev Internal function to determine the final state for a deposit using randomness.
    /// Requires activeStateIds to be non-empty.
    /// @param depositId The ID of the deposit to determine the state for.
    function _determineState(uint depositId) internal {
        if (activeStateIds.length == 0) {
            revert NoActiveStates();
        }

        uint randomValue = _generateRandomness(depositId);

        // Select an index from the activeStateIds array based on randomness
        uint chosenIndex = randomValue % activeStateIds.length;
        int finalStateId = activeStateIds[chosenIndex];

        // Check if the chosen state config actually exists (should always if picked from activeStateIds)
        // Redundant check but safe.
         if (stateConfigs[finalStateId].stateId == 0 && (finalStateId != 0 || stateConfigs[finalStateId].multiplierPermille == 0)) {
             // This case indicates a logic error or timing issue with removing states from activeStateIds
             // Revert or pick a default state? Revert for now.
              revert InvalidStateId(finalStateId); // Should not happen if activeStateIds is correct
         }

        Deposit storage deposit = deposits[depositId];
        deposit.finalState = finalStateId;
        deposit.observationTime = block.timestamp;

        emit DepositObserved(depositId, finalStateId, block.timestamp);
    }

     /// @dev Internal helper to add a state ID to the active list if not already present.
    function _addStateToActive(int stateId) internal {
        for (uint i = 0; i < activeStateIds.length; i++) {
            if (activeStateIds[i] == stateId) {
                return; // Already active
            }
        }
        activeStateIds.push(stateId);
    }

    /// @dev Internal helper to remove a state ID from the active list.
    function _removeStateFromActive(int stateId) internal {
        for (uint i = 0; i < activeStateIds.length; i++) {
            if (activeStateIds[i] == stateId) {
                // Swap with last element and pop
                if (i < activeStateIds.length - 1) {
                    activeStateIds[i] = activeStateIds[activeStateIds.length - 1];
                }
                activeStateIds.pop();
                return;
            }
        }
        // State ID not found in active list - ok, nothing to remove.
    }
}
```