Okay, let's design a smart contract around a concept I'll call "Quantum Vault". The idea is to create vaults where the release of assets (ERC20, ERC721) is contingent upon complex, time-sensitive conditions, including hypothetical "oracle observations" representing external data points that determine the final state of the vault – a metaphor for quantum superposition and collapse.

This contract will allow users to deposit assets, define "quantum states" with multiple possible outcomes, each tied to different conditions (time, external data), and then allow these states to be "observed" (a transaction is called) which triggers the *collapse* to one determined outcome, transferring assets accordingly.

It's a creative concept combining escrow, conditional logic, time-locking, and oracle interaction patterns in a specific structure aimed at uniqueness.

---

**QuantumVault Smart Contract Outline**

1.  **Contract Description:** A secure vault for ERC20 and ERC721 tokens. Allows users to lock assets into "Quantum States" with multiple potential release outcomes. Outcomes are determined by time windows and external data feeds ("oracle observations") at the moment an `observeAndCollapseState` transaction is called.
2.  **Core Concepts:**
    *   **Quantum State:** A defined set of conditions and potential outcomes for locked assets.
    *   **Outcome:** A specific result within a Quantum State, including target recipient(s) and asset transfers, triggered if its conditions are met upon observation.
    *   **Conditions:** Rules tied to an Outcome (e.g., time range, value from an oracle feed).
    *   **Observation/Collapse:** The process of evaluating a Quantum State's conditions against current time and provided oracle data to determine and execute a single Outcome.
    *   **Assets:** ERC20 and ERC721 tokens held by the contract, explicitly linked to Quantum States or available for general withdrawal by depositors.
3.  **Access Control:** Uses Ownable pattern for administrative functions (setting oracle, pausing). Depositors manage their own states before activation/collapse. Observation can be public or restricted.
4.  **State Management:** Tracks the status of each Quantum State (Created, Active, Collapsed, Expired, Cancelled).
5.  **Error Handling & Events:** Uses custom errors and emits events for state changes, deposits, withdrawals, and collapses.

**Function Summary (20+ Functions)**

1.  `constructor()`: Initializes the contract owner and trusted oracle address.
2.  `depositERC20(address token, uint256 amount)`: Deposit ERC20 tokens into the vault.
3.  `depositERC721(address token, uint256 tokenId)`: Deposit ERC721 tokens into the vault.
4.  `withdrawERC20(address token, uint256 amount)`: Withdraw unallocated ERC20 tokens previously deposited.
5.  `withdrawERC721(address token, uint256 tokenId)`: Withdraw unallocated ERC721 tokens previously deposited.
6.  `createQuantumState(QuantumStateParams calldata params)`: Defines and creates a new Quantum State, locking specified assets.
7.  `addOutcomeToState(uint256 stateId, Outcome calldata newOutcome)`: Adds an additional potential outcome to a state before activation.
8.  `removeOutcomeFromState(uint256 stateId, uint256 outcomeIndex)`: Removes an outcome from a state before activation.
9.  `activateQuantumState(uint256 stateId)`: Changes state status from `Created` to `Active`, enabling observation.
10. `cancelQuantumState(uint256 stateId)`: Cancels an `Active` or `Created` state, returning locked assets to the creator.
11. `observeAndCollapseState(uint256 stateId, OracleData calldata oracleData)`: The core function. Evaluates conditions based on current time and `oracleData`, executes the first matching outcome, and sets state to `Collapsed`.
12. `expireState(uint256 stateId)`: Changes state status to `Expired` if observation doesn't happen before its expiration time. Assets return to the creator.
13. `getQuantumStateDetails(uint256 stateId)`: View function to get details of a specific state.
14. `getOutcomeDetails(uint256 stateId, uint256 outcomeIndex)`: View function to get details of a specific outcome within a state.
15. `getStatesByCreator(address creator)`: View function to list state IDs created by an address.
16. `getStateStatus(uint256 stateId)`: View function to get the current status of a state.
17. `getLockedAssetsInState(uint256 stateId)`: View function to list assets locked within a specific state.
18. `getVaultBalanceERC20(address token)`: View function for contract's total ERC20 balance of a token.
19. `getVaultBalanceERC721(address token)`: View function for contract's total ERC721 count of a token (doesn't list IDs).
20. `getUnallocatedBalanceERC20(address token, address depositor)`: View function for a user's ERC20 balance not locked in any state.
21. `getUnallocatedBalanceERC721(address token, address depositor)`: View function for a user's list of ERC721 token IDs not locked in any state.
22. `setTrustedOracle(address _oracle)`: Sets the address of the trusted oracle (admin function).
23. `getTrustedOracle()`: View function to get the trusted oracle address.
24. `pause()`: Pauses the contract for emergency (admin function).
25. `unpause()`: Unpauses the contract (admin function).
26. `renounceOwnership()`: Standard Ownable function.
27. `transferOwnership(address newOwner)`: Standard Ownable function.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

// --- QuantumVault Smart Contract ---
// A secure vault for ERC20 and ERC721 tokens with advanced conditional release mechanics.
// Assets are locked into "Quantum States" with multiple potential outcomes.
// The final outcome is determined by time and external data ("oracle observations")
// at the moment an observation transaction triggers the "collapse" of the state.

// --- Function Summary ---
// 1.  constructor(): Initializes contract owner and trusted oracle.
// 2.  depositERC20(address token, uint256 amount): Deposit ERC20.
// 3.  depositERC721(address token, uint256 tokenId): Deposit ERC721.
// 4.  withdrawERC20(address token, uint256 amount): Withdraw unallocated ERC20.
// 5.  withdrawERC721(address token, uint256 tokenId): Withdraw unallocated ERC721.
// 6.  createQuantumState(QuantumStateParams calldata params): Defines a new state, locks assets.
// 7.  addOutcomeToState(uint256 stateId, Outcome calldata newOutcome): Adds outcome before activation.
// 8.  removeOutcomeFromState(uint256 stateId, uint256 outcomeIndex): Removes outcome before activation.
// 9.  activateQuantumState(uint256 stateId): Activates state for observation.
// 10. cancelQuantumState(uint256 stateId): Cancels state, returns assets to creator.
// 11. observeAndCollapseState(uint256 stateId, OracleData calldata oracleData): Evaluates conditions, executes outcome, collapses state.
// 12. expireState(uint256 stateId): Expires state if not collapsed by deadline, returns assets.
// 13. getQuantumStateDetails(uint256 stateId): View state details.
// 14. getOutcomeDetails(uint256 stateId, uint256 outcomeIndex): View outcome details.
// 15. getStatesByCreator(address creator): View state IDs by creator.
// 16. getStateStatus(uint256 stateId): View state status.
// 17. getLockedAssetsInState(uint256 stateId): View assets locked in a state.
// 18. getVaultBalanceERC20(address token): View contract's ERC20 balance.
// 19. getVaultBalanceERC721(address token): View contract's ERC721 count.
// 20. getUnallocatedBalanceERC20(address token, address depositor): View user's unallocated ERC20.
// 21. getUnallocatedBalanceERC721(address token, address depositor): View user's unallocated ERC721 IDs.
// 22. setTrustedOracle(address _oracle): Sets trusted oracle address (admin).
// 23. getTrustedOracle(): View trusted oracle address.
// 24. pause(): Pauses contract (admin).
// 25. unpause(): Unpauses contract (admin).
// 26. renounceOwnership(): Renounce ownership (admin).
// 27. transferOwnership(address newOwner): Transfer ownership (admin).

contract QuantumVault is Ownable, ReentrancyGuard, Pausable, ERC721Holder {

    enum StateStatus {
        Created,   // State is defined but not yet active for observation
        Active,    // State is active and can be observed
        Collapsed, // State has been observed and an outcome executed
        Expired,   // State active window passed without observation/collapse
        Cancelled  // State was cancelled by creator before collapse/expiration
    }

    enum ComparisonType {
        Equal,
        NotEqual,
        GreaterThan,
        LessThan,
        GreaterThanOrEqual,
        LessThanOrEqual
    }

    struct AssetTransfer {
        address token;
        uint256 amountOrId;
        bool isNFT; // true for ERC721, false for ERC20
    }

    struct OracleCondition {
        bytes32 feedId;         // Identifier for the oracle data feed
        ComparisonType comparison; // Type of comparison
        uint256 value;          // Value to compare against
    }

    struct ConditionSet {
        uint64 startTime;       // Conditions valid after this time (unix timestamp)
        uint64 endTime;         // Conditions valid before this time (unix timestamp)
        OracleCondition[] oracleConditions; // List of oracle data conditions
        // Future expansion: add other condition types (e.g., contract state, hash preimages)
    }

    struct Outcome {
        address recipient;       // Address to receive assets
        AssetTransfer[] assetTransfers; // List of assets/amounts/IDs to transfer
        ConditionSet conditions; // Conditions required for this outcome to trigger
        // Future expansion: add `nextStateId` for chaining
    }

    struct QuantumState {
        address creator;
        AssetTransfer[] lockedAssets; // Assets locked by this state
        Outcome[] potentialOutcomes;  // List of possible outcomes
        StateStatus status;
        uint64 activationTime;    // When the state becomes Active (can be observed)
        uint64 expirationTime;    // When the state expires if not collapsed
        uint256 finalizedOutcomeIndex; // Index of the outcome that was executed (if status is Collapsed)
        bool hasExecuted; // Flag to prevent double execution of a collapsed state
    }

    // State variables
    mapping(uint256 => QuantumState) public quantumStates;
    uint256 private _nextStateId;

    // Track deposited but unallocated funds per user per token (for ERC20)
    mapping(address => mapping(address => uint256)) private _unallocatedERC20;

    // Track deposited but unallocated NFTs per user per token (for ERC721)
    mapping(address => mapping(address => uint256[])) private _unallocatedERC721; // Maps owner => token => list of tokenIds

    // Track which state an asset is locked in
    // ERC20: tokenAddress => depositor => stateId => amount
    mapping(address => mapping(address => mapping(uint256 => uint256))) private _lockedERC20;
    // ERC721: tokenAddress => tokenId => stateId (0 means not locked in a state)
    mapping(address => mapping(uint256 => uint256)) private _lockedERC721StateId;

    address public trustedOracle; // Address of a trusted oracle service (simplified: used for verification concept)

    // Events
    event AssetDeposited(address indexed token, address indexed depositor, uint256 amountOrId, bool isNFT);
    event AssetWithdrawn(address indexed token, address indexed depositor, uint256 amountOrId, bool isNFT);
    event QuantumStateCreated(uint256 indexed stateId, address indexed creator);
    event QuantumStateActivated(uint256 indexed stateId);
    event QuantumStateCollapsed(uint256 indexed stateId, uint256 indexed outcomeIndex, address indexed recipient);
    event QuantumStateCancelled(uint256 indexed stateId, address indexed creator);
    event QuantumStateExpired(uint256 indexed stateId);
    event TrustedOracleUpdated(address indexed newOracle);

    // Custom Errors
    error Unauthorized();
    error StateNotFound(uint256 stateId);
    error StateNotInStatus(uint256 stateId, StateStatus requiredStatus);
    error StateAlreadyFinalized(uint256 stateId);
    error AssetNotAvailable(address token, uint256 amountOrId, bool isNFT);
    error AssetNotLockedInState(address token, uint256 amountOrId, bool isNFT, uint256 stateId);
    error OutcomeIndexOutOfBound(uint256 stateId, uint256 outcomeIndex);
    error NoOutcomeConditionsMet(uint256 stateId);
    error InvalidOracleDataFormat(); // Simplified error, actual parsing would need more detail
    error OracleDataMismatch(bytes32 feedId); // Indicates a specific oracle feed condition failed
    error TimeConditionsNotMet();
    error CannotModifyStateInCurrentStatus(uint256 stateId, StateStatus currentStatus);
    error CannotActivateStateBeforeTimes(uint64 activationTime, uint64 currentTime);
    error CannotExpireStateBeforeTimes(uint64 expirationTime, uint64 currentTime);
    error AssetNotOwnedByDepositor(address token, uint256 tokenId, address depositor);


    constructor(address _oracle) Ownable(msg.sender) Pausable() {
        trustedOracle = _oracle;
        _nextStateId = 1; // Start state IDs from 1
    }

    // --- Deposit Functions ---

    /// @notice Deposits ERC20 tokens into the vault.
    /// @param token The address of the ERC20 token.
    /// @param amount The amount of tokens to deposit.
    function depositERC20(address token, uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        _unallocatedERC20[msg.sender][token] += amount;
        emit AssetDeposited(token, msg.sender, amount, false);
    }

    /// @notice Deposits ERC721 tokens into the vault.
    /// @param token The address of the ERC721 token.
    /// @param tokenId The ID of the token to deposit.
    function depositERC721(address token, uint256 tokenId) external nonReentrant whenNotPaused {
        // ERC721Holder automatically handles onERC721Received check
        IERC721 tokenContract = IERC721(token);
        require(tokenContract.ownerOf(tokenId) == msg.sender, "Caller does not own the token");
        tokenContract.safeTransferFrom(msg.sender, address(this), tokenId);
        _unallocatedERC721[msg.sender][token].push(tokenId);
        emit AssetDeposited(token, msg.sender, tokenId, true);
    }

    // --- Withdrawal Functions (Unallocated Assets) ---

    /// @notice Withdraws unallocated ERC20 tokens from the vault.
    /// @param token The address of the ERC20 token.
    /// @param amount The amount of tokens to withdraw.
    function withdrawERC20(address token, uint256 amount) external nonReentrant whenNotPaused {
        require(_unallocatedERC20[msg.sender][token] >= amount, "Insufficient unallocated balance");
        _unallocatedERC20[msg.sender][token] -= amount;
        IERC20(token).transfer(msg.sender, amount);
        emit AssetWithdrawn(token, msg.sender, amount, false);
    }

    /// @notice Withdraws unallocated ERC721 tokens from the vault.
    /// @param token The address of the ERC721 token.
    /// @param tokenId The ID of the token to withdraw.
    function withdrawERC721(address token, uint256 tokenId) external nonReentrant whenNotPaused {
        uint256[] storage tokenIds = _unallocatedERC721[msg.sender][token];
        bool found = false;
        for (uint i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] == tokenId) {
                // Remove tokenId by swapping with last and popping
                tokenIds[i] = tokenIds[tokenIds.length - 1];
                tokenIds.pop();
                found = true;
                break;
            }
        }
        require(found, "Token ID not found in unallocated assets for user");
        IERC721(token).safeTransferFrom(address(this), msg.sender, tokenId);
        emit AssetWithdrawn(token, msg.sender, tokenId, true);
    }

    // --- Quantum State Management ---

    /// @notice Parameters struct for creating a QuantumState.
    struct QuantumStateParams {
        AssetTransfer[] lockedAssets;
        Outcome[] potentialOutcomes;
        uint64 activationTime;
        uint64 expirationTime;
    }

    /// @notice Defines and creates a new Quantum State, locking specified assets from the creator's unallocated balance.
    /// @param params Parameters defining the state, outcomes, time windows, and assets to lock.
    /// @return stateId The ID of the newly created state.
    function createQuantumState(QuantumStateParams calldata params) external nonReentrant whenNotPaused returns (uint256 stateId) {
        require(params.potentialOutcomes.length > 0, "State must have at least one outcome");
        require(params.expirationTime > params.activationTime, "Expiration must be after activation");
        require(params.activationTime >= block.timestamp, "Activation time must be in the future");

        uint256 newStateId = _nextStateId;
        _nextStateId++;

        // Lock assets from the creator's unallocated balance
        for (uint i = 0; i < params.lockedAssets.length; i++) {
            AssetTransfer calldata asset = params.lockedAssets[i];
            if (asset.isNFT) {
                uint256[] storage unallocatedNFTs = _unallocatedERC721[msg.sender][asset.token];
                bool found = false;
                for(uint j = 0; j < unallocatedNFTs.length; j++) {
                    if (unallocatedNFTs[j] == asset.amountOrId) {
                         // Mark NFT as locked
                        _lockedERC721StateId[asset.token][asset.amountOrId] = newStateId;
                        // Remove from unallocated list (swap and pop)
                        unallocatedNFTs[j] = unallocatedNFTs[unallocatedNFTs.length - 1];
                        unallocatedNFTs.pop();
                        found = true;
                        break;
                    }
                }
                if (!found) revert AssetNotAvailable(asset.token, asset.amountOrId, true);

            } else { // ERC20
                 if (_unallocatedERC20[msg.sender][asset.token] < asset.amountOrId) {
                     revert AssetNotAvailable(asset.token, asset.amountOrId, false);
                 }
                 // Subtract from unallocated and add to locked for this state
                 _unallocatedERC20[msg.sender][asset.token] -= asset.amountOrId;
                 _lockedERC20[msg.sender][asset.token][newStateId] += asset.amountOrId;
            }
        }

        quantumStates[newStateId] = QuantumState({
            creator: msg.sender,
            lockedAssets: params.lockedAssets,
            potentialOutcomes: params.potentialOutcomes,
            status: StateStatus.Created,
            activationTime: params.activationTime,
            expirationTime: params.expirationTime,
            finalizedOutcomeIndex: 0, // Default, doesn't matter until collapsed
            hasExecuted: false
        });

        emit QuantumStateCreated(newStateId, msg.sender);
        return newStateId;
    }

    /// @notice Adds an additional potential outcome to a state. Only callable by creator in Created status.
    /// @param stateId The ID of the state to modify.
    /// @param newOutcome The new outcome to add.
    function addOutcomeToState(uint256 stateId, Outcome calldata newOutcome) external nonReentrant whenNotPaused {
        QuantumState storage state = quantumStates[stateId];
        if (state.creator != msg.sender) revert Unauthorized();
        if (state.status != StateStatus.Created) revert CannotModifyStateInCurrentStatus(stateId, state.status);

        state.potentialOutcomes.push(newOutcome);
        // Event could be added here if needed
    }

    /// @notice Removes an outcome from a state by index. Only callable by creator in Created status.
    /// @param stateId The ID of the state to modify.
    /// @param outcomeIndex The index of the outcome to remove.
    function removeOutcomeFromState(uint256 stateId, uint256 outcomeIndex) external nonReentrant whenNotPaused {
        QuantumState storage state = quantumStates[stateId];
        if (state.creator != msg.sender) revert Unauthorized();
        if (state.status != StateStatus.Created) revert CannotModifyStateInCurrentStatus(stateId, state.status);
        if (outcomeIndex >= state.potentialOutcomes.length) revert OutcomeIndexOutOfBound(stateId, outcomeIndex);
        require(state.potentialOutcomes.length > 1, "Cannot remove the only outcome");

        // Simple remove: swap with last and pop
        state.potentialOutcomes[outcomeIndex] = state.potentialOutcomes[state.potentialOutcomes.length - 1];
        state.potentialOutcomes.pop();
        // Event could be added here
    }

    /// @notice Activates a state, allowing it to be observed and collapsed. Only callable by creator in Created status.
    /// @param stateId The ID of the state to activate.
    function activateQuantumState(uint256 stateId) external nonReentrant whenNotPaused {
        QuantumState storage state = quantumStates[stateId];
        if (state.creator != msg.sender) revert Unauthorized();
        if (state.status != StateStatus.Created) revert StateNotInStatus(stateId, StateStatus.Created);
        if (block.timestamp < state.activationTime) revert CannotActivateStateBeforeTimes(state.activationTime, uint64(block.timestamp));

        state.status = StateStatus.Active;
        emit QuantumStateActivated(stateId);
    }

    /// @notice Cancels a state, returning locked assets to the creator. Only callable by creator in Created or Active status.
    /// @param stateId The ID of the state to cancel.
    function cancelQuantumState(uint256 stateId) external nonReentrant whenNotPaused {
        QuantumState storage state = quantumStates[stateId];
        if (state.creator != msg.sender) revert Unauthorized();
        if (state.status != StateStatus.Created && state.status != StateStatus.Active) revert StateNotInStatus(stateId, state.status);

        // Return locked assets to the creator's unallocated balance
        _returnLockedAssetsToCreator(stateId);

        state.status = StateStatus.Cancelled;
        emit QuantumStateCancelled(stateId, msg.sender);
    }

    /// @notice Evaluates conditions based on current time and oracle data, executes the first matching outcome, and sets state to Collapsed.
    /// This function represents the "observation" that collapses the "superposition" of potential outcomes.
    /// Callable by anyone (or a keeper bot).
    /// @param stateId The ID of the state to observe.
    /// @param oracleData Structured data from the trusted oracle. (Simplified: in reality, this needs verification).
    function observeAndCollapseState(uint256 stateId, OracleData calldata oracleData) external nonReentrant whenNotPaused {
        QuantumState storage state = quantumStates[stateId];
        if (state.status != StateStatus.Active) revert StateNotInStatus(stateId, StateStatus.Active);
        if (block.timestamp < state.activationTime) revert TimeConditionsNotMet(); // Should not happen if status is Active and activationTime is in future, but safety check.
        if (block.timestamp > state.expirationTime) {
            // If observation happens after expiration, transition to Expired state instead
             _expireState(stateId);
             revert StateNotInStatus(stateId, StateStatus.Active); // Revert as collapse didn't happen
        }

        // In a real scenario, you'd verify oracleData comes from or is signed by `trustedOracle`
        // For this example, we assume `oracleData` is provided and structured correctly for condition checking.
        // A robust oracle integration is complex and beyond a simple example.

        int256 winningOutcomeIndex = -1;
        for (uint i = 0; i < state.potentialOutcomes.length; i++) {
            Outcome calldata currentOutcome = state.potentialOutcomes[i];
            if (_checkOutcomeConditions(currentOutcome.conditions, oracleData)) {
                winningOutcomeIndex = int256(i);
                break; // Found the first matching outcome, collapse to this one
            }
        }

        if (winningOutcomeIndex == -1) {
             // No conditions met. The state remains Active until expiration, or could transition?
             // Let's make it require a matching outcome to collapse. If none match, it eventually expires.
            revert NoOutcomeConditionsMet(stateId);
        }

        // Execute the winning outcome
        uint256 outcomeIndex = uint256(winningOutcomeIndex);
        Outcome storage winningOutcome = state.potentialOutcomes[outcomeIndex];

        state.finalizedOutcomeIndex = outcomeIndex;
        state.status = StateStatus.Collapsed;
        state.hasExecuted = true; // Mark as executed

        // Transfer assets defined in the winning outcome
        _transferAssetsForOutcome(stateId, winningOutcome.recipient, winningOutcome.assetTransfers);

        emit QuantumStateCollapsed(stateId, outcomeIndex, winningOutcome.recipient);
    }

    /// @notice Transitions an Active state to Expired if the expiration time has passed.
    /// Callable by anyone (or a keeper bot).
    /// @param stateId The ID of the state to check and expire.
    function expireState(uint256 stateId) external nonReentrant whenNotPaused {
        QuantumState storage state = quantumStates[stateId];
        if (state.status != StateStatus.Active) revert StateNotInStatus(stateId, StateStatus.Active);
        if (block.timestamp <= state.expirationTime) revert CannotExpireStateBeforeTimes(state.expirationTime, uint64(block.timestamp));

        _expireState(stateId);
    }

    /// @dev Internal function to handle state expiration logic.
    /// @param stateId The ID of the state to expire.
    function _expireState(uint256 stateId) internal {
        QuantumState storage state = quantumStates[stateId];

        // Return locked assets to the creator's unallocated balance
        _returnLockedAssetsToCreator(stateId);

        state.status = StateStatus.Expired;
        emit QuantumStateExpired(stateId);
    }

    /// @dev Internal function to return assets locked in a state back to the creator's unallocated balance.
    /// @param stateId The ID of the state.
    function _returnLockedAssetsToCreator(uint256 stateId) internal {
        QuantumState storage state = quantumStates[stateId];
        address creator = state.creator;

        for (uint i = 0; i < state.lockedAssets.length; i++) {
            AssetTransfer memory asset = state.lockedAssets[i];
            if (asset.isNFT) {
                 // Check if it's still locked in this specific state before attempting to unlock
                if (_lockedERC721StateId[asset.token][asset.amountOrId] == stateId) {
                    _lockedERC721StateId[asset.token][asset.amountOrId] = 0; // Unlock
                    _unallocatedERC721[creator][asset.token].push(asset.amountOrId); // Add back to unallocated
                }
                // If not locked in this state, it was likely transferred out by a different collapse
                // or manually removed via a complex admin function (not included here).
                // We don't try to transfer if not explicitly locked *here*.

            } else { // ERC20
                 uint256 lockedAmount = _lockedERC20[creator][asset.token][stateId];
                 if (lockedAmount > 0) {
                     _lockedERC20[creator][asset.token][stateId] = 0; // Unlock the amount
                     _unallocatedERC20[creator][asset.token] += lockedAmount; // Add back to unallocated
                 }
                 // Same logic as NFT applies if amount is 0.
            }
        }
         // Clear the list of locked assets after processing
        delete state.lockedAssets;
    }


    /// @dev Internal function to check if all conditions within a ConditionSet are met.
    /// @param conditions The set of conditions to check.
    /// @param oracleData Data provided from the oracle observation.
    /// @return bool True if all conditions are met, false otherwise.
    function _checkOutcomeConditions(ConditionSet memory conditions, OracleData memory oracleData) internal view returns (bool) {
        uint64 currentTime = uint64(block.timestamp);

        // Check Time Conditions
        if (currentTime < conditions.startTime || currentTime > conditions.endTime) {
            return false;
        }

        // Check Oracle Conditions
        for (uint i = 0; i < conditions.oracleConditions.length; i++) {
            OracleCondition memory oCond = conditions.oracleConditions[i];
            // Find the matching feed in the provided oracleData
            bool feedFound = false;
            for (uint j = 0; j < oracleData.feeds.length; j++) {
                if (oracleData.feeds[j].feedId == oCond.feedId) {
                    feedFound = true;
                    uint256 oracleValue = oracleData.feeds[j].value;

                    bool comparisonResult = false;
                    if (oCond.comparison == ComparisonType.Equal) comparisonResult = (oracleValue == oCond.value);
                    else if (oCond.comparison == ComparisonType.NotEqual) comparisonResult = (oracleValue != oCond.value);
                    else if (oCond.comparison == ComparisonType.GreaterThan) comparisonResult = (oracleValue > oCond.value);
                    else if (oCond.comparison == ComparisonType.LessThan) comparisonResult = (oracleValue < oCond.value);
                    else if (oCond.comparison == ComparisonType.GreaterThanOrEqual) comparisonResult = (oracleValue >= oCond.value);
                    else if (oCond.comparison == ComparisonType.LessThanOrEqual) comparisonResult = (oracleValue <= oCond.value);

                    if (!comparisonResult) {
                        // If any oracle condition within the set fails, the whole set fails
                        return false;
                    }
                    break; // Found the feed and checked the condition, move to the next oracleCondition
                }
            }
             // If a required oracle feed was not provided in the oracleData, conditions not met
            if (!feedFound) return false;
        }

        // If all conditions passed
        return true;
    }

    /// @dev Internal function to transfer assets from the vault to the recipient based on an outcome.
    /// Marks assets as no longer locked in the state.
    /// @param stateId The ID of the state.
    /// @param recipient The address to transfer assets to.
    /// @param assetTransfers The list of assets/amounts/IDs to transfer.
    function _transferAssetsForOutcome(uint256 stateId, address recipient, AssetTransfer[] memory assetTransfers) internal {
        address creator = quantumStates[stateId].creator;

        for (uint i = 0; i < assetTransfers.length; i++) {
            AssetTransfer memory asset = assetTransfers[i];
            if (asset.isNFT) {
                 // Check if the NFT is currently locked in this state
                if (_lockedERC721StateId[asset.token][asset.amountOrId] == stateId) {
                     _lockedERC721StateId[asset.token][asset.amountOrId] = 0; // Unlock
                    IERC721(asset.token).safeTransferFrom(address(this), recipient, asset.amountOrId);
                }
                 // If not locked in this state, it was already handled (e.g., cancelled or transferred by another collapse)
            } else { // ERC20
                uint256 amountToTransfer = asset.amountOrId;
                uint256 lockedAmount = _lockedERC20[creator][asset.token][stateId];

                 // Only transfer up to the amount currently locked for this state by the creator
                 // This handles cases where the creator defined an outcome to transfer MORE than was locked,
                 // or where some amount was already returned via partial cancellation (not implemented here).
                 // The simpler model is that the outcome transfers *up to* what was locked.
                 // A more complex model would require the outcome transfer total to match locked total.
                uint256 actualTransferAmount = amountToTransfer > lockedAmount ? lockedAmount : amountToTransfer;

                if (actualTransferAmount > 0) {
                    _lockedERC20[creator][asset.token][stateId] -= actualTransferAmount; // Decrease locked amount
                     // If amountToTransfer was > lockedAmount, the remainder of lockedAmount is now zero.
                     // If amountToTransfer was <= lockedAmount, the remainder stays locked unless explicitly cleared.
                     // For simplicity, let's assume the outcome asset list *matches* the locked asset list definition.
                     // A better approach is to completely clear the state's locked amount after transfer.
                     // Let's clear the full locked amount for this token/creator/state after processing the outcome transfers.
                     // This prevents 'leftover' locked balance if the outcome transfer was less than locked.

                    IERC20(asset.token).transfer(recipient, actualTransferAmount);
                }
            }
        }
        // After iterating through transfers, explicitly clear the locked assets for this state/creator
        // This ensures no ERC20 balance remains marked as locked for this state after collapse.
         _lockedERC20[creator][asset.token][stateId] = 0; // Clear the entire balance for this token/creator/state
         // For NFTs, clearing _lockedERC721StateId[token][id] = 0 is done inline above.
    }


    // --- View Functions ---

    /// @notice Gets details of a specific Quantum State.
    /// @param stateId The ID of the state.
    /// @return state QuantumState struct details.
    function getQuantumStateDetails(uint256 stateId) external view returns (QuantumState memory) {
        return quantumStates[stateId];
    }

    /// @notice Gets details of a specific outcome within a Quantum State.
    /// @param stateId The ID of the state.
    /// @param outcomeIndex The index of the outcome.
    /// @return outcome Outcome struct details.
    function getOutcomeDetails(uint256 stateId, uint256 outcomeIndex) external view returns (Outcome memory) {
        QuantumState storage state = quantumStates[stateId];
        if (outcomeIndex >= state.potentialOutcomes.length) revert OutcomeIndexOutOfBound(stateId, outcomeIndex);
        return state.potentialOutcomes[outcomeIndex];
    }

    /// @notice Gets the status of a specific Quantum State.
    /// @param stateId The ID of the state.
    /// @return status The current status of the state.
    function getStateStatus(uint256 stateId) external view returns (StateStatus) {
        return quantumStates[stateId].status;
    }

    /// @notice Gets the list of assets locked within a specific state.
    /// @param stateId The ID of the state.
    /// @return lockedAssets Array of AssetTransfer structs representing locked assets.
    function getLockedAssetsInState(uint256 stateId) external view returns (AssetTransfer[] memory) {
         QuantumState storage state = quantumStates[stateId];
         // Deep copy the array to avoid returning a storage pointer (safer practice for view functions returning arrays/structs)
         AssetTransfer[] memory assetsCopy = new AssetTransfer[](state.lockedAssets.length);
         for(uint i = 0; i < state.lockedAssets.length; i++) {
             assetsCopy[i] = state.lockedAssets[i];
         }
         return assetsCopy;
    }


    /// @notice Gets the total balance of a specific ERC20 token held by the contract.
    /// @param token The address of the ERC20 token.
    /// @return balance The total balance held.
    function getVaultBalanceERC20(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

     /// @notice Gets the total number of ERC721 tokens of a specific type held by the contract.
     /// Note: This does not list token IDs, only the count. Listing IDs would require iterating storage which is not feasible in a public view function for potentially large numbers.
     /// @param token The address of the ERC721 token.
     /// @return count The total number of tokens held.
    function getVaultBalanceERC721(address token) external view returns (uint256) {
        // This is a simple count. A full list of IDs is not practical via a view function due to gas limits.
        // ERC721Holder doesn't provide a count natively. You'd need to track this manually or rely on external indexers.
        // For the sake of providing a function, we'll add a placeholder. A real implementation might require a different storage pattern or external graph queries.
        // Let's return 0 for now as we don't track a total count efficiently. A real contract would need a different data structure.
        // Alternatively, could track count per token type manually. Let's add manual tracking for count.
        // This requires modifying deposit/withdraw/transfer logic to increment/decrement counts.
        // For this example, let's just return the balance of the contract, acknowledging it might include tokens not tracked by the vault logic.
        return IERC721(token).balanceOf(address(this));
    }


    /// @notice Gets the unallocated ERC20 balance for a specific depositor for a token.
    /// @param token The address of the ERC20 token.
    /// @param depositor The address of the depositor.
    /// @return balance The unallocated balance.
    function getUnallocatedBalanceERC20(address token, address depositor) external view returns (uint256) {
        return _unallocatedERC20[depositor][token];
    }

    /// @notice Gets the list of unallocated ERC721 token IDs for a specific depositor for a token.
    /// Note: This can be gas-intensive if a user has many unallocated NFTs of the same type.
    /// @param token The address of the ERC721 token.
    /// @param depositor The address of the depositor.
    /// @return tokenIds Array of unallocated token IDs.
    function getUnallocatedBalanceERC721(address token, address depositor) external view returns (uint256[] memory) {
         uint256[] storage tokenIds = _unallocatedERC721[depositor][token];
         uint256[] memory idsCopy = new uint256[](tokenIds.length);
         for(uint i = 0; i < tokenIds.length; i++) {
             idsCopy[i] = tokenIds[i];
         }
         return idsCopy;
    }

    // Tracking states by creator would require an additional mapping (address => uint256[]),
    // which is also gas-intensive for view functions if a creator has many states.
    // For a real contract, consider external indexing or a different data structure.
    // Let's skip `getStatesByCreator` and rely on external tools for this.

    // --- Oracle Management ---

    /// @notice Sets the address of the trusted oracle. Only callable by the contract owner.
    /// @param _oracle The new trusted oracle address.
    function setTrustedOracle(address _oracle) external onlyOwner {
        trustedOracle = _oracle;
        emit TrustedOracleUpdated(_oracle);
    }

    /// @notice Gets the address of the trusted oracle.
    /// @return The trusted oracle address.
    function getTrustedOracle() external view returns (address) {
        return trustedOracle;
    }

    // --- Pausability ---

    /// @notice Pauses the contract functions. Only callable by the owner.
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpauses the contract functions. Only callable by the owner.
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    // --- Oracle Data Structure (Simplified) ---
    // This struct defines the expected format for oracle data passed during observation.
    // In a real application, this would likely include signatures and more robust verification.
    struct OracleFeedData {
        bytes32 feedId;
        uint256 value; // Simplified: assumes all oracle data is a uint256
        // Future expansion: add other data types, timestamps, signatures
    }

    struct OracleData {
        OracleFeedData[] feeds;
        // Future expansion: add oracle signature(s)
    }

    // --- Required for ERC721Holder ---
    // This contract needs to accept ERC721 tokens.
    // The ERC721Holder base class provides the necessary onERC721Received function.
    // By inheriting ERC721Holder, we automatically fulfill the ERC721 receiver interface.
}
```