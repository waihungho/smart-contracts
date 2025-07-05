Okay, here is a Solidity smart contract concept I've designed based on the idea of a "Quantum Vault". It's intended to be creative, use advanced concepts (like conditional withdrawals based on multiple factors including potential external data/randomness), and not be a direct duplicate of common open-source patterns.

The "Quantum" aspect is metaphorical, referring to assets being "locked" in a state dependent on the interplay of multiple, potentially probabilistic or time-sensitive conditions, only becoming withdrawable when the "waveform collapses" (all conditions are met simultaneously). It integrates concepts of multi-factor conditional release, state-dependent logic, and potential Oracle interaction (simulated via interfaces here, but pointing to Chainlink VRF/Data Feeds as examples).

**Disclaimer:** This is a complex concept. Implementing it securely and efficiently requires significant testing and gas optimization. Oracle interactions (like Chainlink VRF) require external subscription management and understanding their specific callback patterns, which are abstracted slightly here for conceptual clarity. **Do NOT use this code in production without a thorough security audit.**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

// --- Interfaces for external interaction (simulated/example) ---
// Example Chainlink VRF Coordinator Interface (simplified for required function)
interface IVRFCoordinatorV2Plus {
    function requestRandomWords(
        uint32 keyHash,
        uint64 subId,
        uint32 requestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords
    ) external returns (uint256 requestId);
}

// Example Chainlink Price Feed Interface (simplified)
interface IAggregatorV3 {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// --- Contract Outline ---
/*
1. State Variables: Defines the core data structures and contract state.
    - Supported tokens, balances, user deposits.
    - Quantum Conditions definitions and linking.
    - Oracle addresses and VRF request tracking.
    - Vault state variables (Entanglement Level).
2. Structs: Custom data types for Deposits, Conditions, and Condition Linkages.
3. Events: Signals important actions and state changes.
4. Modifiers: Access control and state checks (Ownable, ReentrancyGuard, Pausable).
5. Core Logic Functions:
    - Setup & Configuration (add/remove tokens, set oracles, add/update conditions).
    - Deposit Logic (deposit tokens under specific conditions).
    - Withdrawal Logic (request proof, check status, try withdraw). This is the core complex part.
    - State Management (set vault state, trigger entanglement checks - conceptual).
    - View Functions (get details, balances, status).
    - Emergency/Admin Functions (owner withdrawal, cancellation).
    - Pause/Unpause.
6. Oracle Callbacks: (Example for VRF fulfillment).
*/

// --- Function Summary ---
/*
- constructor: Deploys the contract, sets owner and initial parameters.
- addSupportedToken: Owner adds a token address that can be deposited.
- removeSupportedToken: Owner removes support for a token.
- updateOracleAddresses: Owner updates addresses for VRF/Price Feed Oracles.
- addQuantumConditionDefinition: Owner defines a new set of conditions for withdrawals.
- updateQuantumConditionDefinition: Owner modifies an existing condition definition.
- removeQuantumConditionDefinition: Owner removes a condition definition.
- addConditionLinkage: Owner links two condition definitions (e.g., condition A requires B to be true).
- removeConditionLinkage: Owner removes a linkage between conditions.
- deposit: User deposits a supported token associated with a specific condition definition ID.
- requestWithdrawalProof: User initiates the withdrawal process for a specific deposit, triggering Oracle calls (like VRF) if needed by the condition.
- fulfillRandomness: (External Callback) Called by VRF Coordinator to provide requested randomness.
- checkConditionStatus: View function for a user to check if the conditions linked to their deposit are *currently* met (based on available data/state, *not* consuming fresh Oracle requests triggered by requestWithdrawalProof yet). Provides insight into withdrawal eligibility.
- tryWithdraw: User attempts to withdraw a specific deposit. This function performs the final check against ALL required conditions, including verifying successful Oracle data retrieval (if requested via requestWithdrawalProof). This is the core complex logic gate.
- cancelDepositIfImpossible: Allows a user to cancel a deposit if its associated condition has become permanently impossible to meet (e.g., time window passed, required VRF outcome unobtainable).
- setVaultEntanglementLevel: Owner sets a global state variable that can influence condition checks (a "quantum state" metaphor).
- getVaultEntanglementLevel: View function to read the current entanglement level.
- triggerEntanglementCheck: (Conceptual) A function that could potentially update the state of linked conditions based on complex internal rules or external triggers (more advanced than simple linkage checks).
- getDepositDetails: View function to get information about a specific user deposit.
- getConditionDetails: View function to get details of a quantum condition definition.
- getConditionLinkages: View function to see how conditions are linked.
- getUserDeposits: View function to list all active deposit IDs for a user.
- getVaultTotalTokenBalance: View function for the contract's total balance of a specific token.
- getUserTotalTokenDeposit: View function for a user's total deposited amount of a specific token across all their deposits.
- emergencyWithdrawOwner: Owner can withdraw all funds (break glass). Requires careful consideration and potential timelocks/governance in a real system.
- emergencyWithdrawDeposit: Owner can withdraw a *specific* deposit (e.g., if stuck). Again, requires careful access control.
- pause: Owner pauses the contract (prevents deposits/withdrawals).
- unpause: Owner unpauses the contract.
- transferOwnership: Standard Ownable function.
*/


contract QuantumVault is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    // --- State Variables ---

    // Mapping of supported ERC20 tokens
    mapping(address => bool) private _supportedTokens;

    // Contract's total balance of each supported token
    mapping(address => uint256) private _vaultTokenBalances;

    // Struct to define a single condition set required for withdrawal
    struct QuantumConditionDefinition {
        bool exists; // True if this definition ID is active
        string name; // Human-readable name for the condition
        uint256 minTimestamp; // Timestamp after which withdrawal is possible (0 for no min)
        uint256 maxTimestamp; // Timestamp before which withdrawal is possible (type(uint256).max for no max)
        // Price-based requirements
        address priceFeedTokenAddress; // Address of the token whose price feed is checked (address(0) for none)
        int256 minPrice; // Minimum price (scaled by decimals) (int256.min for no min)
        int256 maxPrice; // Maximum price (scaled by decimals) (int256.max for no max)
        // Randomness requirement (requires VRF)
        bool requiresRandomness; // Does this condition require a VRF result?
        uint256 minRandomValue; // Minimum required random value (if requiresRandomness)
        uint256 maxRandomValue; // Maximum required random value (if requiresRandomness)
        // Internal state requirement
        uint8 requiredVaultState; // Required internal vault entanglement state (0 for any state)
        // Future: More complex requirements (e.g., linked condition must be FALSE)
        // bool requiresLinkedConditionFalse;
    }

    // Mapping from a unique condition definition ID (bytes32) to its parameters
    mapping(bytes32 => QuantumConditionDefinition) private _conditionDefinitions;

    // Struct for linking conditions (e.g., Condition A requires Condition B to be met)
    struct ConditionLinkage {
        bool exists; // True if this linkage is active
        bytes32 requiredConditionId; // The condition that needs to be checked
        bool requiredState; // True if requiredConditionId must be met, false if it must NOT be met
    }

    // Mapping from a condition ID to a list of other conditions it depends on
    mapping(bytes32 => ConditionLinkage[]) private _conditionLinkages;

    // Struct to track a user's specific deposit
    struct UserDeposit {
        bool isActive; // Is this deposit still valid/withdrawable?
        address depositor;
        address tokenAddress;
        uint256 amount;
        bytes32 conditionId; // The ID of the condition definition governing this deposit
        uint256 depositTimestamp; // Timestamp of the deposit
        bytes32 lastVrfRequestId; // Stores the VRF request ID from the latest requestWithdrawalProof call for this deposit
        bool vrfRequestFulfilled; // Flag if the last VRF request for this deposit is fulfilled
        uint256 fulfilledRandomValue; // The random value received for the last request
    }

    // Mapping from a unique deposit ID (bytes32) to the deposit details
    mapping(bytes32 => UserDeposit) private _userDeposits;

    // Keep track of deposit IDs per user (for easier retrieval)
    mapping(address => bytes32[]) private _userDepositIds;

    // Oracle Addresses (Example Chainlink)
    address public vrfCoordinatorAddress;
    uint32 public vrfKeyHash; // Example Key Hash for VRF
    address public priceFeedEthUsd; // Example Price Feed

    // VRF Subscription ID (required for Chainlink VRF V2+) - Management external to this contract example
    uint64 public vrfSubscriptionId;

    // Vault's internal "Entanglement Level" state (metaphorical)
    uint8 public vaultEntanglementLevel;

    // --- Events ---
    event SupportedTokenAdded(address indexed token);
    event SupportedTokenRemoved(address indexed token);
    event OracleAddressesUpdated(address vrfCoordinator, uint32 keyHash, address priceFeedEthUsd);
    event ConditionDefinitionAdded(bytes32 indexed conditionId, string name);
    event ConditionDefinitionUpdated(bytes32 indexed conditionId, string name);
    event ConditionDefinitionRemoved(bytes32 indexed conditionId);
    event ConditionLinkageAdded(bytes32 indexed conditionId, bytes32 indexed requiredConditionId, bool requiredState);
    event ConditionLinkageRemoved(bytes32 indexed conditionId, bytes32 indexed requiredConditionId);
    event TokenDeposited(bytes32 indexed depositId, address indexed depositor, address indexed token, uint256 amount, bytes32 conditionId);
    event WithdrawalProofRequested(bytes32 indexed depositId, bytes32 vrfRequestId);
    event VRFRandomnessFulfilled(bytes32 indexed vrfRequestId, bytes32 indexed depositId, uint256 randomValue);
    event WithdrawalSuccess(bytes32 indexed depositId, address indexed recipient, address indexed token, uint256 amount);
    event WithdrawalFailed(bytes32 indexed depositId, string reason);
    event DepositCancelled(bytes32 indexed depositId, string reason);
    event VaultEntanglementLevelSet(uint8 indexed level);
    event EntanglementCheckTriggered(); // Conceptual event

    // --- Modifiers ---
    modifier onlySupportedToken(address tokenAddress) {
        require(_supportedTokens[tokenAddress], "Token not supported");
        _;
    }

    // --- Constructor ---
    constructor(address _vrfCoordinator, uint32 _vrfKeyHash, address _priceFeedEthUsd, uint64 _vrfSubscriptionId) Ownable(msg.sender) Pausable(false) {
        vrfCoordinatorAddress = _vrfCoordinator;
        vrfKeyHash = _vrfKeyHash;
        priceFeedEthUsd = _priceFeedEthUsd;
        vrfSubscriptionId = _vrfSubscriptionId; // Requires separate subscription funding/management
        vaultEntanglementLevel = 1; // Initial state
    }

    // --- Setup & Configuration ---

    function addSupportedToken(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0), "Invalid address");
        require(!_supportedTokens[tokenAddress], "Token already supported");
        _supportedTokens[tokenAddress] = true;
        emit SupportedTokenAdded(tokenAddress);
    }

    function removeSupportedToken(address tokenAddress) external onlyOwner {
        require(_supportedTokens[tokenAddress], "Token not supported");
        // Potentially add checks here if funds are locked under this token
        _supportedTokens[tokenAddress] = false;
        emit SupportedTokenRemoved(tokenAddress);
    }

    function updateOracleAddresses(address _vrfCoordinator, uint32 _vrfKeyHash, address _priceFeedEthUsd, uint64 _vrfSubscriptionId) external onlyOwner {
         vrfCoordinatorAddress = _vrfCoordinator;
         vrfKeyHash = _vrfKeyHash;
         priceFeedEthUsd = _priceFeedEthUsd;
         vrfSubscriptionId = _vrfSubscriptionId;
         emit OracleAddressesUpdated(_vrfCoordinator, _vrfKeyHash, _priceFeedEthUsd, _vrfSubscriptionId);
    }

    // Helper to generate condition ID
    function _generateConditionId(QuantumConditionDefinition calldata definition) internal pure returns (bytes32) {
        // Hash relevant parameters to create a unique ID for the definition
        return keccak256(abi.encode(
            definition.minTimestamp,
            definition.maxTimestamp,
            definition.priceFeedTokenAddress,
            definition.minPrice,
            definition.maxPrice,
            definition.requiresRandomness,
            definition.minRandomValue,
            definition.maxRandomValue,
            definition.requiredVaultState
            // Note: name is excluded from ID generation so owner can rename without changing ID
        ));
    }

    function addQuantumConditionDefinition(QuantumConditionDefinition calldata definition) external onlyOwner {
        bytes32 conditionId = _generateConditionId(definition);
        require(!_conditionDefinitions[conditionId].exists, "Condition definition already exists");
        _conditionDefinitions[conditionId] = definition;
        _conditionDefinitions[conditionId].exists = true; // Mark as existing
        emit ConditionDefinitionAdded(conditionId, definition.name);
    }

    function updateQuantumConditionDefinition(bytes32 conditionId, QuantumConditionDefinition calldata definition) external onlyOwner {
         // Re-calculate ID to ensure the update corresponds to the original *definition* ID
         bytes32 expectedId = _generateConditionId(definition);
         require(conditionId == expectedId, "Updated parameters result in a different condition ID");
         require(_conditionDefinitions[conditionId].exists, "Condition definition does not exist");

         // Note: This completely overwrites the definition for that ID.
         // More granular updates could be added if needed.
         _conditionDefinitions[conditionId] = definition;
         _conditionDefinitions[conditionId].exists = true; // Ensure it stays marked as existing
         emit ConditionDefinitionUpdated(conditionId, definition.name);
    }

    function removeQuantumConditionDefinition(bytes32 conditionId) external onlyOwner {
        require(_conditionDefinitions[conditionId].exists, "Condition definition does not exist");
        // WARNING: Removing a definition might make existing deposits permanently stuck
        // unless there's a mechanism to re-assign or cancel them.
        // Add checks here if necessary to prevent removal if active deposits rely on it.
        delete _conditionDefinitions[conditionId];
        // Also remove all linkages involving this condition
        delete _conditionLinkages[conditionId];
        // Iterating through *all* other conditions to remove linkages *to* this condition is too gas intensive.
        // This makes removing definitions complex in reality - might require a migration or governance process.
        // For this example, we accept this limitation.

        emit ConditionDefinitionRemoved(conditionId);
    }

    function addConditionLinkage(bytes32 conditionId, bytes32 requiredConditionId, bool requiredState) external onlyOwner {
        require(_conditionDefinitions[conditionId].exists, "Base condition definition does not exist");
        require(_conditionDefinitions[requiredConditionId].exists, "Required condition definition does not exist");
        require(conditionId != requiredConditionId, "Cannot link a condition to itself");

        // Add the linkage. Check for duplicates first.
        for (uint i = 0; i < _conditionLinkages[conditionId].length; i++) {
            if (_conditionLinkages[conditionId][i].requiredConditionId == requiredConditionId) {
                require(_conditionLinkages[conditionId][i].requiredState != requiredState, "Linkage with this required state already exists");
                // Allow adding the *opposite* required state linkage, but avoid duplicates of the *exact* linkage.
                // For this example, let's keep it simple and disallow adding a linkage that already exists (regardless of state for now)
                 revert("Linkage to this required condition already exists"); // More refined logic needed for requiring true AND false? Unlikely.
            }
        }

        _conditionLinkages[conditionId].push(ConditionLinkage(true, requiredConditionId, requiredState));
        emit ConditionLinkageAdded(conditionId, requiredConditionId, requiredState);
    }

    function removeConditionLinkage(bytes32 conditionId, bytes32 requiredConditionId) external onlyOwner {
         require(_conditionDefinitions[conditionId].exists, "Base condition definition does not exist");
         // Find and remove the linkage
         bool found = false;
         for (uint i = 0; i < _conditionLinkages[conditionId].length; i++) {
             if (_conditionLinkages[conditionId][i].requiredConditionId == requiredConditionId) {
                 // Use swap-and-pop to remove efficiently
                 _conditionLinkages[conditionId][i] = _conditionLinkages[conditionId][_conditionLinkages[conditionId].length - 1];
                 _conditionLinkages[conditionId].pop();
                 found = true;
                 // Note: This removes *all* linkages between these two conditions, regardless of the requiredState flag.
                 // If different requiredStates were allowed for the same linkage, more complex removal logic is needed.
                 break;
             }
         }
         require(found, "Linkage does not exist");
         emit ConditionLinkageRemoved(conditionId, requiredConditionId);
    }


    // --- Deposit Logic ---

    function deposit(address tokenAddress, uint256 amount, bytes32 conditionId)
        external
        payable // Allow receiving native tokens for gas or future features
        whenNotPaused
        nonReentrant
        onlySupportedToken(tokenAddress)
    {
        require(amount > 0, "Amount must be > 0");
        require(_conditionDefinitions[conditionId].exists, "Invalid condition ID");

        IERC20 token = IERC20(tokenAddress);
        token.safeTransferFrom(msg.sender, address(this), amount);

        bytes32 depositId = keccak256(abi.encode(msg.sender, tokenAddress, amount, conditionId, block.timestamp, block.number));

        _userDeposits[depositId] = UserDeposit({
            isActive: true,
            depositor: msg.sender,
            tokenAddress: tokenAddress,
            amount: amount,
            conditionId: conditionId,
            depositTimestamp: block.timestamp,
            lastVrfRequestId: 0, // No request yet
            vrfRequestFulfilled: false,
            fulfilledRandomValue: 0
        });

        _userDepositIds[msg.sender].push(depositId);
        _vaultTokenBalances[tokenAddress] += amount;

        emit TokenDeposited(depositId, msg.sender, tokenAddress, amount, conditionId);
    }

    // --- Withdrawal Logic ---

    // Step 1: Request external data (currently only VRF example)
    function requestWithdrawalProof(bytes32 depositId) external whenNotPaused nonReentrant {
        UserDeposit storage deposit = _userDeposits[depositId];
        require(deposit.isActive, "Deposit not active");
        require(deposit.depositor == msg.sender, "Not your deposit");

        QuantumConditionDefinition storage condition = _conditionDefinitions[deposit.conditionId];
        require(condition.exists, "Condition definition removed"); // Should not happen if isActive implies valid condition

        if (condition.requiresRandomness) {
            IVRFCoordinatorV2Plus vrfCoordinator = IVRFCoordinatorV2Plus(vrfCoordinatorAddress);
            uint256 requestId = vrfCoordinator.requestRandomWords(
                vrfKeyHash,
                vrfSubscriptionId,
                3, // requestConfirmations - Example value
                300000, // callbackGasLimit - Example value
                1 // numWords - We only need 1 random value
            );
             // Link the request ID to this specific deposit for later lookup
            deposit.lastVrfRequestId = bytes32(uint256(requestId)); // Store as bytes32 for mapping key type consistency
            deposit.vrfRequestFulfilled = false; // Reset fulfillment status
            deposit.fulfilledRandomValue = 0;
            emit WithdrawalProofRequested(depositId, bytes32(uint256(requestId)));
        } else {
             // No proof needed, can proceed directly to tryWithdraw (if other conditions met)
             revert("This condition does not require external proof"); // Or emit event indicating no proof needed
        }
    }

    // Step 1b: VRF Callback - This function is called by the VRF Coordinator
    function fulfillRandomness(uint256 requestId, uint256[] calldata randomWords) external {
        // Check that the call came from the configured VRF Coordinator
        require(msg.sender == vrfCoordinatorAddress, "Only VRF Coordinator can fulfill");
        require(randomWords.length > 0, "No random words provided");

        // Find the deposit ID associated with this request ID
        // This requires a reverse mapping or iterating through deposits.
        // Iterating through all deposits is too expensive. A mapping from requestId => depositId is needed.
        // Let's add that mapping: mapping(bytes32 => bytes32) private _vrfRequestIdToDepositId;
        // And update requestWithdrawalProof to populate it.

        bytes32 depositId = _vrfRequestIdToDepositId[bytes32(uint256(requestId))];
        require(depositId != bytes32(0), "Unknown VRF request ID");

        UserDeposit storage deposit = _userDeposits[depositId];
        require(deposit.isActive, "Deposit not active for VRF fulfillment"); // Should be active if VRF was requested

        deposit.fulfilledRandomValue = randomWords[0]; // Store the first random value
        deposit.vrfRequestFulfilled = true;

        emit VRFRandomnessFulfilled(bytes32(uint256(requestId)), depositId, randomWords[0]);

        // Clean up the mapping if needed (optional)
        delete _vrfRequestIdToDepositId[bytes32(uint256(requestId))];
    }
     // --- Missing State Variable for VRF Linkage ---
     mapping(bytes32 => bytes32) private _vrfRequestIdToDepositId;
     // Update requestWithdrawalProof to include:
     // _vrfRequestIdToDepositId[bytes32(uint256(requestId))] = depositId;


    // Helper function to check if a single condition definition is met (recursive for linkages)
    // This function should NOT consume VRF or check fresh price feed directly, just evaluate against *available* data.
    // It's used by checkConditionStatus (view) and tryWithdraw (where VRF/Price freshness is handled).
    function _isConditionMet(bytes32 conditionId, bytes32 depositId) internal view returns (bool, string memory) {
        QuantumConditionDefinition storage condition = _conditionDefinitions[conditionId];
        if (!condition.exists) return (false, "Condition definition removed");

        UserDeposit storage deposit;
        // Only access deposit state if a depositId is provided
        if (depositId != bytes32(0)) {
            deposit = _userDeposits[depositId];
             // Basic check, but _isConditionMet is called *after* deposit is validated in tryWithdraw
             // require(deposit.isActive, "Deposit not active");
        }


        uint256 currentTimestamp = block.timestamp;
        // Check Time-based conditions
        if (currentTimestamp < condition.minTimestamp) return (false, "Time min not met");
        if (currentTimestamp > condition.maxTimestamp && condition.maxTimestamp != type(uint256).max) return (false, "Time max exceeded");

        // Check Price-based conditions
        if (condition.priceFeedTokenAddress != address(0)) {
            require(priceFeedEthUsd != address(0), "Price feed Oracle not configured"); // Using EthUsd as example for all price checks
            IAggregatorV3 priceFeed = IAggregatorV3(priceFeedEthUsd);
            (, int256 price, , uint256 updatedAt, ) = priceFeed.latestRoundData();
            // Add a check for staleness if necessary
            // require(block.timestamp - updatedAt < priceFeedStalenessTolerance, "Price feed stale");

            if (price < condition.minPrice) return (false, "Price min not met");
            if (price > condition.maxPrice && condition.maxPrice != type(int256).max) return (false, "Price max exceeded");
        }

        // Check Randomness condition (only against fulfilled value if available)
        if (condition.requiresRandomness) {
             if (depositId == bytes32(0)) return (false, "Cannot check randomness without deposit context");
             if (!deposit.vrfRequestFulfilled) return (false, "Randomness not fulfilled yet");
             uint256 randomValue = deposit.fulfilledRandomValue;
             if (randomValue < condition.minRandomValue) return (false, "Random value min not met");
             if (randomValue > condition.maxRandomValue) return (false, "Random value max exceeded");
        }

        // Check Internal State condition
        if (condition.requiredVaultState != 0 && vaultEntanglementLevel != condition.requiredVaultState) {
             return (false, "Vault state not met");
        }

        // Check Linked Conditions (Recursive/Iterative)
        ConditionLinkage[] storage linkages = _conditionLinkages[conditionId];
        for (uint i = 0; i < linkages.length; i++) {
            if (linkages[i].exists) {
                // Prevent infinite recursion/cycles by tracking checked conditions within a single call?
                // For simplicity here, we assume no malicious cycles or limit depth externally if needed.
                (bool linkedConditionMet, string memory linkedReason) = _isConditionMet(linkages[i].requiredConditionId, depositId); // Pass depositId down
                if (linkages[i].requiredState && !linkedConditionMet) return (false, string.concat("Linked condition not met: ", linkedReason));
                if (!linkages[i].requiredState && linkedConditionMet) return (false, string.concat("Linked condition unexpectedly met: ", linkedReason));
            }
        }

        // All checks passed
        return (true, "All conditions met");
    }


    // Step 2: View function to check status without attempting withdrawal
    function checkConditionStatus(bytes32 depositId) public view returns (bool isMet, string memory reason) {
        UserDeposit storage deposit = _userDeposits[depositId];
        require(deposit.isActive, "Deposit not active");
        require(deposit.depositor == msg.sender, "Not your deposit");

        QuantumConditionDefinition storage condition = _conditionDefinitions[deposit.conditionId];
        require(condition.exists, "Condition definition removed"); // Should not happen if isActive implies valid condition

        return _isConditionMet(deposit.conditionId, depositId);
    }

    // Step 3: Attempt Withdrawal
    function tryWithdraw(bytes32 depositId) external whenNotPaused nonReentrant {
        UserDeposit storage deposit = _userDeposits[depositId];
        require(deposit.isActive, "Deposit not active");
        require(deposit.depositor == msg.sender, "Not your deposit");

        QuantumConditionDefinition storage condition = _conditionDefinitions[deposit.conditionId];
        require(condition.exists, "Condition definition removed");

        // Check ALL conditions using the internal helper
        (bool allMet, string memory reason) = _isConditionMet(deposit.conditionId, depositId);

        if (!allMet) {
             emit WithdrawalFailed(depositId, reason);
             revert(string.concat("Withdrawal conditions not met: ", reason));
        }

        // If conditions require randomness, explicitly require VRF to be fulfilled for this deposit attempt
        if (condition.requiresRandomness && !deposit.vrfRequestFulfilled) {
             emit WithdrawalFailed(depositId, "Randomness required but not fulfilled");
             revert("Randomness required but not fulfilled. Request proof first.");
        }

        // All conditions met, proceed with withdrawal
        uint256 amountToWithdraw = deposit.amount; // Withdraw the full deposit amount

        // Mark the deposit as inactive BEFORE transferring tokens (to prevent reentrancy issues)
        deposit.isActive = false;

        // Remove deposit ID from user's list (optional, but good for cleanup)
        // This is gas-expensive if the user has many deposits. A better approach might be
        // to track indices or use a more advanced data structure if frequent removal is needed.
        // For simplicity, let's skip removing from _userDepositIds array here.

        _vaultTokenBalances[deposit.tokenAddress] -= amountToWithdraw;

        IERC20 token = IERC20(deposit.tokenAddress);
        token.safeTransfer(msg.sender, amountToWithdraw);

        emit WithdrawalSuccess(depositId, msg.sender, deposit.tokenAddress, amountToWithdraw);
    }

    // Allows user to cancel a deposit if the condition governing it becomes permanently impossible
    function cancelDepositIfImpossible(bytes32 depositId) external nonReentrant {
         UserDeposit storage deposit = _userDeposits[depositId];
         require(deposit.isActive, "Deposit not active");
         require(deposit.depositor == msg.sender, "Not your deposit");

         QuantumConditionDefinition storage condition = _conditionDefinitions[deposit.conditionId];
         require(condition.exists, "Condition definition removed - cannot verify impossibility");

         // Logic to determine if condition is impossible
         bool impossible = false;
         string memory impossibilityReason = "Not impossible based on current checks";

         uint256 currentTimestamp = block.timestamp;

         // Example impossibility checks:
         // 1. Time window passed (maxTimestamp is in the past)
         if (condition.maxTimestamp != type(uint256).max && currentTimestamp > condition.maxTimestamp && condition.minTimestamp <= condition.maxTimestamp) {
             impossible = true;
             impossibilityReason = "Max timestamp passed";
         }
         // 2. Required Random Value range is impossible given VRF result (if fulfilled)
         //    This is complex: VRF result is > max *or* < min. Requires VRF fulfillment happened.
         if (condition.requiresRandomness && deposit.vrfRequestFulfilled) {
             uint256 randomValue = deposit.fulfilledRandomValue;
             if (randomValue < condition.minRandomValue || randomValue > condition.maxRandomValue) {
                 impossible = true;
                 impossibilityReason = "VRF result outside required range";
             }
         }
         // More checks could be added based on other condition types

         require(impossible, impossibilityReason);

         // Condition is deemed impossible, allow cancellation
         uint256 amountToCancel = deposit.amount;
         deposit.isActive = false; // Mark as inactive BEFORE transfer

         _vaultTokenBalances[deposit.tokenAddress] -= amountToCancel;
         IERC20 token = IERC20(deposit.tokenAddress);
         token.safeTransfer(msg.sender, amountToCancel);

         emit DepositCancelled(depositId, impossibilityReason);

         // Optional: Remove from _userDepositIds (expensive)
    }


    // --- State Management ---

    function setVaultEntanglementLevel(uint8 level) external onlyOwner {
        vaultEntanglementLevel = level;
        emit VaultEntanglementLevelSet(level);
    }

    function triggerEntanglementCheck() external {
        // This function is conceptual for demonstrating state interaction.
        // A complex contract might have internal state transitions or
        // checks between linked conditions that are triggered periodically
        // or by specific external calls. For this example, it just emits an event.
        // A real implementation might re-evaluate the state of certain conditions
        // or update parameters based on global state changes.
        emit EntanglementCheckTriggered();
    }

    // --- View Functions ---

    function isSupportedToken(address tokenAddress) external view returns (bool) {
        return _supportedTokens[tokenAddress];
    }

    function getDepositDetails(bytes32 depositId) external view returns (UserDeposit memory) {
        require(_userDeposits[depositId].depositor != address(0), "Deposit ID does not exist"); // Basic check if ID exists
        return _userDeposits[depositId];
    }

    function getConditionDetails(bytes32 conditionId) external view returns (QuantumConditionDefinition memory) {
        require(_conditionDefinitions[conditionId].exists, "Condition ID does not exist");
        return _conditionDefinitions[conditionId];
    }

    function getConditionLinkages(bytes32 conditionId) external view returns (ConditionLinkage[] memory) {
         require(_conditionDefinitions[conditionId].exists, "Condition ID does not exist");
         return _conditionLinkages[conditionId];
    }

    function getUserDeposits(address user) external view returns (bytes32[] memory) {
        // Note: This returns all deposit IDs, including inactive ones.
        // Filtering isActive would require iterating, which is expensive in a view function.
        // A more efficient approach for production might store active/inactive IDs separately.
        return _userDepositIds[user];
    }

    function getVaultTotalTokenBalance(address tokenAddress) external view returns (uint256) {
        return _vaultTokenBalances[tokenAddress];
    }

    function getUserTotalTokenDeposit(address user, address tokenAddress) external view returns (uint256) {
        uint256 total = 0;
        // This iterates through all deposit IDs for the user - can be expensive
        bytes32[] memory depositIds = _userDepositIds[user];
        for (uint i = 0; i < depositIds.length; i++) {
            UserDeposit storage deposit = _userDeposits[depositIds[i]];
            if (deposit.isActive && deposit.tokenAddress == tokenAddress) {
                total += deposit.amount;
            }
        }
        return total;
    }

    // Helper view function to get the status of required external data for a deposit
    function getRequiredOracleDataStatus(bytes32 depositId) external view returns (bool vrfReady, bool priceFresh) {
        UserDeposit storage deposit = _userDeposits[depositId];
        require(deposit.isActive, "Deposit not active");
        require(deposit.depositor == msg.sender, "Not your deposit");

        QuantumConditionDefinition storage condition = _conditionDefinitions[deposit.conditionId];
        require(condition.exists, "Condition definition removed");

        vrfReady = true; // Assume true if randomness not required
        if (condition.requiresRandomness) {
            vrfReady = deposit.vrfRequestFulfilled;
        }

        priceFresh = true; // Assume true if price not required
        if (condition.priceFeedTokenAddress != address(0)) {
            require(priceFeedEthUsd != address(0), "Price feed Oracle not configured");
            IAggregatorV3 priceFeed = IAggregatorV3(priceFeedEthUsd);
            (, , , uint256 updatedAt, ) = priceFeed.latestRoundData();
            // Define a threshold for "freshness" - example 5 minutes
            priceFresh = (block.timestamp - updatedAt) <= 300; // 300 seconds = 5 minutes
             // Note: _isConditionMet check does *not* require this freshness, tryWithdraw would check the actual price against range.
             // This view is just informational about the data source.
        }

        return (vrfReady, priceFresh);
    }

    // --- Emergency / Admin ---

    function emergencyWithdrawOwner(address tokenAddress) external onlyOwner nonReentrant {
        require(_supportedTokens[tokenAddress], "Token not supported"); // Only supported tokens can be emergency withdrawn

        uint256 balance = _vaultTokenBalances[tokenAddress];
        require(balance > 0, "No balance to withdraw");

        // IMPORTANT: This bypasses all conditions and user deposits.
        // In a real system, this should likely be timelocked or require multi-sig/governance approval.
        _vaultTokenBalances[tokenAddress] = 0; // Update state BEFORE transfer

        IERC20 token = IERC20(tokenAddress);
        token.safeTransfer(msg.sender, balance);

        // Note: User deposit records remain, but vault balance is zeroed for this token.
        // A more robust emergency withdrawal might also iterate and mark user deposits as inactive.
    }

    // Allows owner to force-withdraw a specific user deposit (e.g., if stuck due to unresolvable bug)
    // Requires extreme caution and potentially off-chain justification/governance.
    function emergencyWithdrawDeposit(bytes32 depositId, address recipient) external onlyOwner nonReentrant {
         UserDeposit storage deposit = _userDeposits[depositId];
         require(deposit.isActive, "Deposit not active or already withdrawn/cancelled");
         require(recipient != address(0), "Invalid recipient address");
         require(_supportedTokens[deposit.tokenAddress], "Token not supported"); // Should already be true based on deposit logic

         uint256 amountToWithdraw = deposit.amount;
         deposit.isActive = false; // Mark as inactive BEFORE transfer

         _vaultTokenBalances[deposit.tokenAddress] -= amountToWithdraw;
         IERC20 token = IERC20(deposit.tokenAddress);
         token.safeTransfer(recipient, amountToWithdraw);

         emit WithdrawalSuccess(depositId, recipient, deposit.tokenAddress, amountToWithdraw); // Re-use event
    }


    // --- Pausable Functions ---

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // Override base pausable functions to add `whenNotPaused` modifier where applicable
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {
        super._beforeTokenTransfer(from, to, amount);
        // Additional checks specific to vault token transfers?
    }

    // NOTE: OpenZeppelin Pausable doesn't have specific hooks for external calls.
    // The `whenNotPaused` modifier is applied directly to deposit/withdrawal functions.

    // --- Standard Ownable Function ---
    // transferOwnership is inherited from Ownable

}
```