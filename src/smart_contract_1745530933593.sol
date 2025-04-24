Okay, here is a smart contract concept called "QuantumFusionVault". It's designed with inspiration from quantum mechanics concepts like superposition, entanglement (metaphorically), and measurement/collapse, applied to asset management and state transitions within a vault.

It features:

*   **Deposit States (Superposition):** Deposits have numerical "Quantum Properties" that can evolve.
*   **Fusion (Entanglement/Interaction):** A process where two deposits' properties interact, potentially leading to a new combined state or outcome.
*   **Fluctuation:** Ability to introduce controlled randomness (simulated) to a deposit's properties.
*   **Measurement (Withdrawal):** The act of withdrawal finalizes the state and determines the outcome based on the final properties.
*   **Dynamic Outcomes:** Withdrawal amounts/tokens can depend on the final state/properties.

This contract uses custom errors, events, access control (Ownable, Pausable), SafeERC20, and structs to manage state. It includes over 25 functions covering deposit, withdrawal, fusion mechanics, state inspection, and configuration.

**Disclaimer:** The "Quantum" aspects are metaphorical and implemented using standard deterministic (or pseudo-random with external input) blockchain logic. This contract is complex and intended as a creative example, not audited production code. The pseudo-randomness relies on a user-provided nonce for demonstration. A real-world application needing secure randomness would integrate Chainlink VRF or similar.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title QuantumFusionVault
 * @author YourName (or Pseudonym)
 * @dev An experimental vault inspired by quantum mechanics concepts.
 * Deposits have mutable 'quantum properties'. Properties interact via 'fusion'.
 * The final withdrawal outcome depends on the deposit's properties at 'measurement' time.
 */

// --- Outline ---
// 1. Libraries & Imports
// 2. Custom Errors
// 3. Events
// 4. Structs
// 5. Enums
// 6. State Variables
// 7. Modifiers
// 8. Constructor
// 9. Pausability Functions
// 10. Ownership Functions
// 11. Core Vault Functions (Deposit, Withdraw)
// 12. Quantum Property & State Functions
// 13. Fusion Mechanism Functions
// 14. Configuration Functions
// 15. View & Helper Functions
// 16. Internal Helper Functions

// --- Function Summary ---
// Core Vault Functions:
// - depositEth(uint256[] initialProperties): Deposit ETH with initial properties.
// - depositToken(address tokenAddress, uint256 amount, uint256[] initialProperties): Deposit ERC20 with initial properties.
// - withdraw(uint256 depositId): Withdraw assets based on the final state of a deposit.

// Quantum Property & State Functions:
// - addPropertyToDeposit(uint256 depositId, uint256 propertyValue): Add a new quantum property strand to a deposit.
// - mutateProperty(uint256 depositId, uint256 propertyIndex, uint256 newValue): Change a specific quantum property value (if allowed by rules).
// - triggerQuantumFluctuation(uint256 depositId, bytes32 randomnessSeed): Introduce controlled randomness to a deposit's properties using a seed.

// Fusion Mechanism Functions:
// - initiateFusion(uint256 deposit1Id, uint256 deposit2Id): Propose a fusion attempt between two deposits.
// - finalizeFusion(uint256 attemptId, bytes32 quantumNonce): Finalize a fusion attempt. Outcome depends on properties, nonce, and rules.
// - cancelFusionAttempt(uint256 attemptId): Cancel a pending fusion attempt.

// Configuration Functions (Owner Only):
// - setApprovedToken(address tokenAddress, bool approved): Set whether an ERC20 token is allowed for deposit.
// - setFusionRulesHash(bytes32 newRulesHash): Update a hash representing the current fusion rules logic (actual rules are in code/external).
// - setFusionResultToken(uint256 propertyThreshold, address resultToken): Configure which token is potentially yielded upon withdrawal if properties exceed a threshold.
// - setPropertyMutationAllowed(bool allowed): Enable/disable user-initiated property mutation.
// - setFluctuationEnabled(bool enabled): Enable/disable user-initiated fluctuation trigger.

// View & Helper Functions:
// - getDepositState(uint256 depositId): Get the full state details of a deposit.
// - getUserDeposits(address user): Get a list of deposit IDs owned by a user.
// - getTotalValueLocked(address tokenAddress): Get the total amount of a specific token held in the vault.
// - getTotalDepositsCount(): Get the total number of deposits ever created.
// - getFusionAttemptState(uint256 attemptId): Get the state details of a fusion attempt.
// - getFusionRulesHash(): Get the current hash representing fusion rules.
// - getApprovedTokens(): Get the list of approved ERC20 tokens.
// - getDepositOwner(uint256 depositId): Get the owner address of a specific deposit.
// - getUserDepositCount(address user): Get the number of active deposits for a user.
// - predictWithdrawalOutcome(uint256 depositId): Simulate the *potential* withdrawal outcome based on current properties (pure/view).
// - getPropertyValue(uint256 depositId, uint256 propertyIndex): Get a specific property value for a deposit.
// - isPropertyMutationAllowed(): Check if property mutation is currently allowed.
// - isFluctuationEnabled(): Check if fluctuation triggering is enabled.
// - getFusionResultToken(uint256 propertyThreshold): Get the configured result token for a given threshold.
// - isDepositActive(uint256 depositId): Check if a deposit is active (not fused away or withdrawn).

contract QuantumFusionVault is Ownable, Pausable {
    using SafeERC20 for IERC20;

    // --- Custom Errors ---
    error InvalidDepositId();
    error DepositNotActive();
    error DepositNotFound();
    error DepositNotEmpty(uint256 amount);
    error ERC20TransferFailed();
    error DepositTokenNotApproved();
    error InsufficientTokenAmount();
    error InvalidFusionAttemptId();
    error FusionAttemptNotInProgress();
    error FusionAttemptAlreadyFinalized();
    error FusionAttemptCancelled();
    error InvalidPropertyIndex();
    error PropertyMutationNotAllowed();
    error FluctuationNotEnabled();
    error DepositAlreadyFused();
    error DepositHasPendingFusion();

    // --- Events ---
    event EthDeposited(address indexed user, uint256 indexed depositId, uint256 amount, uint256[] initialProperties);
    event TokenDeposited(address indexed user, uint256 indexed depositId, address indexed tokenAddress, uint256 amount, uint256[] initialProperties);
    event Withdrawn(address indexed user, uint256 indexed depositId, address indexed tokenAddress, uint256 amount);
    event PropertyAdded(uint256 indexed depositId, uint256 newPropertyIndex, uint256 propertyValue);
    event PropertyMutated(uint256 indexed depositId, uint256 indexed propertyIndex, uint256 oldValue, uint256 newValue);
    event FluctuationTriggered(uint256 indexed depositId, bytes32 randomnessSeed, uint256[] oldProperties, uint256[] newProperties);
    event FusionAttemptInitiated(address indexed initiator, uint256 indexed attemptId, uint256 deposit1Id, uint256 deposit2Id, uint256 startTime);
    event FusionAttemptFinalized(uint256 indexed attemptId, bool success, uint256 resultingDepositId, string outcomeDetails);
    event FusionAttemptCancelled(uint256 indexed attemptId);
    event ApprovedTokenSet(address indexed tokenAddress, bool approved);
    event FusionRulesHashUpdated(bytes32 newHash);
    event FusionResultTokenSet(uint256 indexed propertyThreshold, address indexed resultToken);
    event PropertyMutationAllowanceSet(bool allowed);
    event FluctuationEnabledSet(bool enabled);

    // --- Structs ---
    struct Deposit {
        address owner;
        address tokenAddress; // Address of the deposited token (ETH represented by address(0))
        uint256 initialAmount; // Original amount deposited
        uint256 currentAmount; // Amount associated with this deposit ID (can change post-fusion/withdrawal)
        uint256[] initialProperties; // Properties at deposit time
        uint256[] currentProperties; // Properties after mutations/fluctuations/fusions
        bool isActive; // True if deposit exists and hasn't been withdrawn or fused into another
        uint256 pendingFusionAttemptId; // 0 if no pending attempt, otherwise the attempt ID
    }

    struct FusionAttempt {
        address initiator;
        uint256 deposit1Id;
        uint256 deposit2Id;
        FusionStatus status;
        uint256 startTime;
        uint256 endTime;
        uint256 resultingDepositId; // New deposit ID if fusion is successful and creates one
        string outcomeDetails;
    }

    // --- Enums ---
    enum FusionStatus {
        Pending,
        FinalizedSuccess,
        FinalizedFailure,
        Cancelled
    }

    // --- State Variables ---
    uint256 private _depositCounter;
    uint256 private _fusionAttemptCounter;

    mapping(uint256 => Deposit) public deposits;
    mapping(address => uint256[]) private userDeposits; // Stores deposit IDs for each user
    mapping(address => uint256) private totalValueLocked; // TVL per token
    mapping(address => bool) private approvedTokens; // ERC20 tokens allowed

    mapping(uint256 => FusionAttempt) public fusionAttempts;

    bytes32 private _fusionRulesHash; // Represents the current logic/rules for fusion outcomes (off-chain or complex on-chain logic)
    mapping(uint256 => address) private _fusionResultTokens; // propertyThreshold => resultToken (0 address for original token)

    bool private _propertyMutationAllowed;
    bool private _fluctuationEnabled;

    // Constants/Config (can be state variables and settable by owner for more dynamism)
    uint256 public constant PROPERTY_MUTATION_COST = 0; // Example: cost in ETH or internal token
    uint256 public constant FLUCTUATION_COST = 0; // Example: cost in ETH or internal token
    uint256 public constant MIN_PROPERTIES = 1; // Minimum initial properties required
    uint256 public constant MAX_PROPERTIES = 10; // Maximum property strands

    // --- Modifiers ---
    modifier onlyDepositOwner(uint256 depositId) {
        if (deposits[depositId].owner != msg.sender) {
            revert OwnableUnauthorizedAccount(msg.sender); // Use Ownable's error for consistency
        }
        _;
    }

    modifier onlyActiveDeposit(uint256 depositId) {
        if (!deposits[depositId].isActive) {
            revert DepositNotActive();
        }
        _;
    }

    modifier onlyPendingFusion(uint256 attemptId) {
        if (fusionAttempts[attemptId].status != FusionStatus.Pending) {
            revert FusionAttemptNotInProgress();
        }
        _;
    }

    // --- Constructor ---
    constructor(bytes32 initialFusionRulesHash) Ownable(msg.sender) Pausable() {
        _fusionRulesHash = initialFusionRulesHash;
        _propertyMutationAllowed = true; // Default to allowed
        _fluctuationEnabled = true; // Default to enabled

        // Approve ETH representation (address(0))
        approvedTokens[address(0)] = true;
    }

    // --- Pausability Functions ---
    /// @dev Pauses the contract, disallowing most state-changing operations.
    function pauseContract() external onlyOwner {
        _pause();
    }

    /// @dev Unpauses the contract, allowing operations to resume.
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    // --- Ownership Functions ---
    // transferOwnership is inherited from Ownable

    /// @dev Allows owner to rescue ERC20 tokens accidentally sent to the contract,
    /// excluding those part of active deposits.
    /// @param tokenAddress The address of the token to rescue.
    /// @param amount The amount of tokens to rescue.
    function rescueTokens(address tokenAddress, uint256 amount) external onlyOwner whenNotPaused {
        // Basic check to prevent rescuing deposited tokens (can be made more robust)
        // This assumes totalValueLocked tracks *all* tokens meant to be in deposits.
        // A more robust check would iterate deposits or use a dedicated balance tracker.
        if (totalValueLocked[tokenAddress] < IERC20(tokenAddress).balanceOf(address(this))) {
            uint256 available = IERC20(tokenAddress).balanceOf(address(this)) - totalValueLocked[tokenAddress];
            uint256 rescueAmount = amount > available ? available : amount;
            IERC20(tokenAddress).safeTransfer(owner(), rescueAmount);
        } else if (tokenAddress == address(0) && address(this).balance > totalValueLocked[address(0)]) {
             uint256 available = address(this).balance - totalValueLocked[address(0)];
             uint256 rescueAmount = amount > available ? available : amount;
             payable(owner()).transfer(rescueAmount);
        } else {
             // No excess tokens to rescue, or attempting to rescue deposited tokens.
             // Decide whether to revert or just do nothing. Doing nothing for now.
        }
    }


    // --- Core Vault Functions ---

    /// @dev Deposits ETH into the vault, creating a new deposit with initial properties.
    /// @param initialProperties The initial quantum properties for the deposit.
    function depositEth(uint256[] calldata initialProperties) external payable whenNotPaused {
        if (initialProperties.length == 0 || initialProperties.length > MAX_PROPERTIES) {
            revert InvalidPropertyIndex(); // Using this error for property count validation
        }
        if (!approvedTokens[address(0)]) {
            revert DepositTokenNotApproved();
        }
        if (msg.value == 0) {
            revert InsufficientTokenAmount();
        }

        _depositCounter++;
        uint256 newDepositId = _depositCounter;

        deposits[newDepositId] = Deposit({
            owner: msg.sender,
            tokenAddress: address(0), // ETH
            initialAmount: msg.value,
            currentAmount: msg.value, // Starts equal to initial
            initialProperties: initialProperties,
            currentProperties: initialProperties, // Starts equal to initial
            isActive: true,
            pendingFusionAttemptId: 0
        });

        userDeposits[msg.sender].push(newDepositId);
        totalValueLocked[address(0)] += msg.value;

        emit EthDeposited(msg.sender, newDepositId, msg.value, initialProperties);
    }

    /// @dev Deposits ERC20 tokens into the vault, creating a new deposit with initial properties.
    /// Requires prior approval for the contract to spend the tokens.
    /// @param tokenAddress The address of the ERC20 token.
    /// @param amount The amount of tokens to deposit.
    /// @param initialProperties The initial quantum properties for the deposit.
    function depositToken(address tokenAddress, uint256 amount, uint256[] calldata initialProperties) external whenNotPaused {
         if (initialProperties.length == 0 || initialProperties.length > MAX_PROPERTIES) {
            revert InvalidPropertyIndex();
        }
        if (!approvedTokens[tokenAddress]) {
            revert DepositTokenNotApproved();
        }
        if (amount == 0) {
            revert InsufficientTokenAmount();
        }
        if (tokenAddress == address(0)) {
            revert InvalidDepositToken(); // Custom error for depositing 0 address via token function
        }

        _depositCounter++;
        uint256 newDepositId = _depositCounter;

        IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);

        deposits[newDepositId] = Deposit({
            owner: msg.sender,
            tokenAddress: tokenAddress,
            initialAmount: amount,
            currentAmount: amount,
            initialProperties: initialProperties,
            currentProperties: initialProperties,
            isActive: true,
            pendingFusionAttemptId: 0
        });

        userDeposits[msg.sender].push(newDepositId);
        totalValueLocked[tokenAddress] += amount;

        emit TokenDeposited(msg.sender, newDepositId, tokenAddress, amount, initialProperties);
    }

    /// @dev Withdraws assets from a deposit based on its current state and properties.
    /// This acts as the 'measurement' that collapses the state.
    /// @param depositId The ID of the deposit to withdraw.
    function withdraw(uint256 depositId) external onlyDepositOwner(depositId) onlyActiveDeposit(depositId) whenNotPaused {
        Deposit storage deposit = deposits[depositId];

        // Prevent withdrawal if part of a pending fusion
        if (deposit.pendingFusionAttemptId != 0) {
            revert DepositHasPendingFusion();
        }

        address tokenToWithdraw = deposit.tokenAddress;
        uint256 amountToWithdraw = deposit.currentAmount; // Start with the current amount

        // --- Quantum Measurement Outcome Logic (Simplified Example) ---
        // This is where properties influence the outcome.
        // Example 1: Property value acts as a multiplier
        if (deposit.currentProperties.length > 0) {
            // Use the first property as a simple multiplier basis
            uint256 propertyFactor = deposit.currentProperties[0];
            // Avoid division by zero if 0 is a possible property value
            if (propertyFactor > 0) {
                // Simple example: amount can increase based on property
                 amountToWithdraw = (amountToWithdraw * propertyFactor) / (MIN_PROPERTIES > 0 ? MIN_PROPERTIES : 1); // Scale by initial min property base
            } else {
                // If propertyFactor is 0, maybe withdrawal is reduced or blocked?
                 amountToWithdraw = amountToWithdraw / 2; // Example penalty
            }

            // Example 2: Property threshold determines result token
            uint256 totalPropertiesSum = 0;
            for(uint i = 0; i < deposit.currentProperties.length; i++) {
                totalPropertiesSum += deposit.currentProperties[i];
            }

            address configuredResultToken = address(0);
            // Find the highest threshold met
            uint256 bestThreshold = 0;
            for (uint256 threshold = 0; threshold < 1000; threshold += 10) { // Example: Check thresholds 0, 10, 20...
                 if (_fusionResultTokens[threshold] != address(0) && totalPropertiesSum >= threshold) {
                     bestThreshold = threshold;
                 }
            }

            if (bestThreshold > 0) {
                 configuredResultToken = _fusionResultTokens[bestThreshold];
                 // If a result token is configured and not the original, switch token
                 if (configuredResultToken != address(0) && configuredResultToken != deposit.tokenAddress) {
                    // In a real contract, you'd need a mechanism for the contract to *acquire* these result tokens.
                    // For this example, we'll assume the contract somehow has them or they represent a conversion.
                    // A more complex version might burn the original and mint/transfer the new.
                    // Here, we just change the address for the transfer, assuming the balance exists.
                    tokenToWithdraw = configuredResultToken;
                    // The amount might also be scaled or determined differently based on the result token
                    amountToWithdraw = amountToWithdraw; // Keep original amount for simplicity
                 } else {
                     // Result token is configured but is the original token, or address(0). Keep original.
                     tokenToWithdraw = deposit.tokenAddress;
                     // Amount might still be scaled by propertyFactor as above.
                 }
            } else {
                 // No threshold met, keep original token and scaled amount.
                 tokenToWithdraw = deposit.tokenAddress;
                 // Amount scaled by propertyFactor as above.
            }
        }
        // --- End Quantum Measurement Outcome Logic ---

        // Mark deposit as inactive
        deposit.isActive = false;
        deposit.currentAmount = 0; // Clear the amount for this deposit ID

        // Update TVL - this is tricky if the token changes.
        // A simple approach: reduce TVL for the *original* token by the *initial* amount.
        // A more complex system would track value, not just token counts.
        totalValueLocked[deposit.tokenAddress] -= deposit.initialAmount;

        // Perform the transfer
        if (tokenToWithdraw == address(0)) {
            // Transfer ETH
            (bool success, ) = payable(msg.sender).call{value: amountToWithdraw}("");
            if (!success) {
                revert EthTransferFailed(); // Need a custom error for ETH transfer
            }
        } else {
            // Transfer ERC20
            IERC20(tokenToWithdraw).safeTransfer(msg.sender, amountToWithdraw);
        }


        emit Withdrawn(msg.sender, depositId, tokenToWithdraw, amountToWithdraw);
    }

    // --- Quantum Property & State Functions ---

    /// @dev Adds a new quantum property strand to a deposit.
    /// @param depositId The ID of the deposit.
    /// @param propertyValue The value of the new property.
    function addPropertyToDeposit(uint256 depositId, uint256 propertyValue) external onlyDepositOwner(depositId) onlyActiveDeposit(depositId) whenNotPaused {
        Deposit storage deposit = deposits[depositId];
         if (deposit.currentProperties.length >= MAX_PROPERTIES) {
            revert InvalidPropertyIndex(); // Using this error for max properties limit
        }
        deposit.currentProperties.push(propertyValue);
        emit PropertyAdded(depositId, deposit.currentProperties.length - 1, propertyValue);
    }

    /// @dev Mutates a specific quantum property of a deposit. Requires `_propertyMutationAllowed`.
    /// @param depositId The ID of the deposit.
    /// @param propertyIndex The index of the property to mutate.
    /// @param newValue The new value for the property.
    function mutateProperty(uint256 depositId, uint256 propertyIndex, uint256 newValue) external onlyDepositOwner(depositId) onlyActiveDeposit(depositId) whenNotPaused {
        if (!_propertyMutationAllowed) {
            revert PropertyMutationNotAllowed();
        }
        Deposit storage deposit = deposits[depositId];
        if (propertyIndex >= deposit.currentProperties.length) {
            revert InvalidPropertyIndex();
        }
        uint256 oldValue = deposit.currentProperties[propertyIndex];
        deposit.currentProperties[propertyIndex] = newValue;
        emit PropertyMutated(depositId, propertyIndex, oldValue, newValue);
    }

    /// @dev Triggers a 'quantum fluctuation', introducing controlled randomness to properties.
    /// Requires `_fluctuationEnabled`. The outcome depends on the `randomnessSeed`.
    /// In a real contract, this seed would come from a secure oracle like Chainlink VRF.
    /// @param depositId The ID of the deposit.
    /// @param randomnessSeed A seed used to generate pseudo-randomness (e.g., from VRF).
    function triggerQuantumFluctuation(uint256 depositId, bytes32 randomnessSeed) external onlyDepositOwner(depositId) onlyActiveDeposit(depositId) whenNotPaused {
        if (!_fluctuationEnabled) {
            revert FluctuationNotEnabled();
        }
        Deposit storage deposit = deposits[depositId];
        uint256[] memory oldProperties = new uint256[](deposit.currentProperties.length);
        for(uint i = 0; i < deposit.currentProperties.length; i++) {
            oldProperties[i] = deposit.currentProperties[i];
        }

        // --- Pseudo-random Property Mutation Logic (Example) ---
        // Use the seed to perturb properties
        uint256 seedValue = uint256(randomnessSeed);
        for(uint i = 0; i < deposit.currentProperties.length; i++) {
            uint256 currentProp = deposit.currentProperties[i];
            // Simple pseudo-random mutation: add/subtract based on hash
            uint256 mutationFactor = uint256(keccak256(abi.encodePacked(seedValue, depositId, i))) % 10; // Random factor 0-9
            if (seedValue % 2 == 0) {
                // Add mutationFactor, avoid overflow (simplified)
                deposit.currentProperties[i] = currentProp + mutationFactor;
            } else {
                // Subtract mutationFactor, avoid underflow (simplified)
                if (currentProp > mutationFactor) {
                    deposit.currentProperties[i] = currentProp - mutationFactor;
                } else {
                    deposit.currentProperties[i] = 0;
                }
            }
             seedValue = uint256(keccak256(abi.encodePacked(seedValue, i))); // Update seed for next iteration
        }
        // --- End Pseudo-random Logic ---

        emit FluctuationTriggered(depositId, randomnessSeed, oldProperties, deposit.currentProperties);
    }

    // --- Fusion Mechanism Functions ---

    /// @dev Initiates a fusion attempt between two active deposits owned by the caller.
    /// Puts deposits in a 'pending' state. Requires later finalization.
    /// @param deposit1Id The ID of the first deposit.
    /// @param deposit2Id The ID of the second deposit.
    function initiateFusion(uint256 deposit1Id, uint256 deposit2Id) external whenNotPaused {
        if (deposit1Id == deposit2Id) revert InvalidDepositId(); // Cannot fuse with self
        if (deposits[deposit1Id].owner != msg.sender || deposits[deposit2Id].owner != msg.sender) {
             revert OwnableUnauthorizedAccount(msg.sender); // Both must be owned by caller
        }
        onlyActiveDeposit(deposit1Id);
        onlyActiveDeposit(deposit2Id);

        // Ensure neither deposit is already part of a pending fusion
        if (deposits[deposit1Id].pendingFusionAttemptId != 0) revert DepositHasPendingFusion();
        if (deposits[deposit2Id].pendingFusionAttemptId != 0) revert DepositHasPendingFusion();

        _fusionAttemptCounter++;
        uint256 newAttemptId = _fusionAttemptCounter;

        fusionAttempts[newAttemptId] = FusionAttempt({
            initiator: msg.sender,
            deposit1Id: deposit1Id,
            deposit2Id: deposit2Id,
            status: FusionStatus.Pending,
            startTime: block.timestamp,
            endTime: 0,
            resultingDepositId: 0,
            outcomeDetails: ""
        });

        // Link deposits to the pending attempt
        deposits[deposit1Id].pendingFusionAttemptId = newAttemptId;
        deposits[deposit2Id].pendingFusionAttemptId = newAttemptId;

        emit FusionAttemptInitiated(msg.sender, newAttemptId, deposit1Id, deposit2Id, block.timestamp);
    }

    /// @dev Finalizes a pending fusion attempt. The outcome (success/failure, new properties, new deposit)
    /// is determined by the fusion rules, deposit properties, and the quantum nonce.
    /// Requires the caller to be the initiator.
    /// @param attemptId The ID of the fusion attempt.
    /// @param quantumNonce A unique nonce provided by the user, used in the outcome calculation.
    function finalizeFusion(uint256 attemptId, bytes32 quantumNonce) external onlyPendingFusion(attemptId) whenNotPaused {
        FusionAttempt storage attempt = fusionAttempts[attemptId];
        if (attempt.initiator != msg.sender) {
            revert OwnableUnauthorizedAccount(msg.sender); // Only initiator can finalize
        }

        Deposit storage dep1 = deposits[attempt.deposit1Id];
        Deposit storage dep2 = deposits[attempt.deposit2Id];

        // Ensure deposits are still active before finalizing
        if (!dep1.isActive || !dep2.isActive) {
             attempt.status = FusionStatus.FinalizedFailure; // Fusion failed because one deposit is gone
             attempt.endTime = block.timestamp;
             attempt.outcomeDetails = "One deposit became inactive before finalization.";
             emit FusionAttemptFinalized(attemptId, false, 0, attempt.outcomeDetails);

             // Unlink the attempt from deposits (even if failed)
             dep1.pendingFusionAttemptId = 0;
             dep2.pendingFusionAttemptId = 0;
             return;
        }


        // --- Fusion Outcome Logic (Complex/Pseudo-random Example) ---
        bool success = false;
        string memory outcomeDetails = "Fusion failed.";
        uint256 newDepositId = 0;

        // Example Rule: Success probability/outcome depends on property sums and nonce
        uint256 sumProps1 = 0;
        for(uint i = 0; i < dep1.currentProperties.length; i++) sumProps1 += dep1.currentProperties[i];
        uint256 sumProps2 = 0;
        for(uint i = 0; i < dep2.currentProperties.length; i++) sumProps2 += dep2.currentProperties[i];

        uint256 fusionEntropy = uint256(keccak256(abi.encodePacked(attemptId, sumProps1, sumProps2, quantumNonce, block.timestamp)));

        if (fusionEntropy % 100 < 70) { // 70% chance of success based on 'entropy'
            success = true;
            outcomeDetails = "Fusion successful!";

            // Create a new fused deposit
            _depositCounter++;
            newDepositId = _depositCounter;

            // --- Determine Fused Properties and Amount ---
            uint224 newPropertiesLength = uint224(dep1.currentProperties.length + dep2.currentProperties.length);
            if (newPropertiesLength > MAX_PROPERTIES) newPropertiesLength = MAX_PROPERTIES; // Cap property count

            uint256[] memory fusedProperties = new uint256[](newPropertiesLength);
            for(uint i = 0; i < newPropertiesLength; i++) {
                 // Simple combination: alternate properties, or average, or sum/split
                 if (i < dep1.currentProperties.length) {
                     fusedProperties[i] = dep1.currentProperties[i];
                 } else {
                     fusedProperties[i] = dep2.currentProperties[i - dep1.currentProperties.length];
                 }
                 // Introduce interaction based on index and entropy
                 fusedProperties[i] = (fusedProperties[i] + (fusionEntropy % 20)) % 1000; // Example interaction
                 fusionEntropy = uint256(keccak256(abi.encodePacked(fusionEntropy, i))); // Update entropy
            }

            // Determine fused amount and token. Example: sum amounts, token of deposit1, maybe bonus/penalty
            uint256 fusedAmount = dep1.currentAmount + dep2.currentAmount;
            address fusedTokenAddress = dep1.tokenAddress; // Assume token of deposit 1 for simplicity

            // In a real system, token combination is complex (e.g., require same token, or AMM logic)
            // For this example, we require same token type for successful fusion value transfer.
            if (dep1.tokenAddress != dep2.tokenAddress) {
                 // Fusion fails if tokens don't match for simple value transfer
                 success = false;
                 outcomeDetails = "Fusion failed: Token mismatch.";
                 newDepositId = 0; // No new deposit created
            } else {
                 // Create the new deposit representing the fused state
                 deposits[newDepositId] = Deposit({
                     owner: msg.sender, // New deposit owned by initiator
                     tokenAddress: fusedTokenAddress,
                     initialAmount: fusedAmount, // Initial for *this* fused deposit
                     currentAmount: fusedAmount,
                     initialProperties: fusedProperties, // Initial for *this* fused deposit
                     currentProperties: fusedProperties,
                     isActive: true,
                     pendingFusionAttemptId: 0
                 });
                 userDeposits[msg.sender].push(newDepositId);
                 // TVL update already handled implicitly as original deposits initial amounts don't change,
                 // but they become inactive. The value conceptually transfers to the new ID.
                 // This model assumes value is linked to the deposit ID's initial amount.
            }

            // --- End Fused Properties and Amount ---

        } else {
            // Fusion failed
            outcomeDetails = "Fusion attempt failed.";
            // Optionally, properties might still be slightly mutated by the failed attempt
            // Example:
            if (dep1.currentProperties.length > 0) dep1.currentProperties[0] = (dep1.currentProperties[0] + 1) % 100;
            if (dep2.currentProperties.length > 0) dep2.currentProperties[0] = (dep2.currentProperties[0] + 1) % 100;
        }
        // --- End Fusion Outcome Logic ---

        // Update fusion attempt state
        attempt.status = success ? FusionStatus.FinalizedSuccess : FusionStatus.FinalizedFailure;
        attempt.endTime = block.timestamp;
        attempt.resultingDepositId = newDepositId;
        attempt.outcomeDetails = outcomeDetails;

        // Mark original deposits as inactive if fusion was successful
        if (success && newDepositId != 0) {
             dep1.isActive = false;
             dep1.currentAmount = 0; // Clear amount associated with old ID
             dep2.isActive = false;
             dep2.currentAmount = 0; // Clear amount associated with old ID
             // Note: Original initialAmount is kept for TVL tracking logic reference
        }

        // Unlink the attempt from deposits
        dep1.pendingFusionAttemptId = 0;
        dep2.pendingFusionAttemptId = 0;

        emit FusionAttemptFinalized(attemptId, success, newDepositId, outcomeDetails);
    }

    /// @dev Cancels a pending fusion attempt. Requires the caller to be the initiator.
    /// The deposits are released from the pending state.
    /// @param attemptId The ID of the fusion attempt.
    function cancelFusionAttempt(uint256 attemptId) external onlyPendingFusion(attemptId) whenNotPaused {
         FusionAttempt storage attempt = fusionAttempts[attemptId];
         if (attempt.initiator != msg.sender) {
            revert OwnableUnauthorizedAccount(msg.sender);
         }

         // Release deposits
         deposits[attempt.deposit1Id].pendingFusionAttemptId = 0;
         deposits[attempt.deposit2Id].pendingFusionAttemptId = 0;

         // Mark attempt as cancelled
         attempt.status = FusionStatus.Cancelled;
         attempt.endTime = block.timestamp;
         attempt.outcomeDetails = "Cancelled by initiator.";

         emit FusionAttemptCancelled(attemptId);
    }

    // --- Configuration Functions (Owner Only) ---

    /// @dev Sets whether a specific ERC20 token is approved for deposits.
    /// @param tokenAddress The address of the token.
    /// @param approved Whether the token should be approved.
    function setApprovedToken(address tokenAddress, bool approved) external onlyOwner {
        if (tokenAddress == address(0)) {
            // Cannot unapprove ETH via this function if it's the primary deposit method
            // Decide if ETH should be configurable or hardcoded as approved.
            // Assuming hardcoded approved for address(0) for now.
            revert InvalidDepositToken(); // Or a specific error like CannotModifyEthApproval
        }
        approvedTokens[tokenAddress] = approved;
        emit ApprovedTokenSet(tokenAddress, approved);
    }

    /// @dev Sets a hash representing the current fusion rules logic. This can be used
    /// to signal changes to clients or decentralized frontends about how fusion works.
    /// The actual on-chain logic in finalizeFusion must correspond to these rules.
    /// @param newRulesHash The new hash of the fusion rules.
    function setFusionRulesHash(bytes32 newRulesHash) external onlyOwner {
        _fusionRulesHash = newRulesHash;
        emit FusionRulesHashUpdated(newRulesHash);
    }

    /// @dev Configures a potential result token for withdrawal if a deposit's
    /// total property value exceeds a certain threshold upon measurement.
    /// Setting resultToken to address(0) means no specific result token for this threshold.
    /// @param propertyThreshold The minimum sum of properties to trigger this result token.
    /// @param resultToken The token address potentially yielded (0 address for original token).
    function setFusionResultToken(uint256 propertyThreshold, address resultToken) external onlyOwner {
         _fusionResultTokens[propertyThreshold] = resultToken;
         emit FusionResultTokenSet(propertyThreshold, resultToken);
    }

    /// @dev Allows the owner to enable or disable user-initiated property mutation.
    /// @param allowed Whether property mutation is allowed.
    function setPropertyMutationAllowed(bool allowed) external onlyOwner {
         _propertyMutationAllowed = allowed;
         emit PropertyMutationAllowanceSet(allowed);
    }

    /// @dev Allows the owner to enable or disable user-initiated fluctuation triggering.
    /// @param enabled Whether fluctuation triggering is enabled.
    function setFluctuationEnabled(bool enabled) external onlyOwner {
         _fluctuationEnabled = enabled;
         emit FluctuationEnabledSet(enabled);
    }

    // --- View & Helper Functions ---

    /// @dev Gets the full state details of a specific deposit.
    /// @param depositId The ID of the deposit.
    /// @return A tuple containing all deposit struct fields.
    function getDepositState(uint256 depositId) external view returns (Deposit memory) {
         if (depositId == 0 || depositId > _depositCounter) {
             revert InvalidDepositId();
         }
         return deposits[depositId];
    }

    /// @dev Gets the list of deposit IDs owned by a specific user.
    /// @param user The address of the user.
    /// @return An array of deposit IDs.
    function getUserDeposits(address user) external view returns (uint256[] memory) {
        return userDeposits[user];
    }

    /// @dev Gets the total value locked in the vault for a specific token.
    /// @param tokenAddress The address of the token (0 for ETH).
    /// @return The total amount of the token held in active deposits.
    function getTotalValueLocked(address tokenAddress) external view returns (uint256) {
        return totalValueLocked[tokenAddress];
    }

    /// @dev Gets the total number of deposits ever created.
    /// @return The total deposit count.
    function getTotalDepositsCount() external view returns (uint256) {
        return _depositCounter;
    }

    /// @dev Gets the state details of a specific fusion attempt.
    /// @param attemptId The ID of the fusion attempt.
    /// @return A tuple containing all fusion attempt struct fields.
    function getFusionAttemptState(uint256 attemptId) external view returns (FusionAttempt memory) {
        if (attemptId == 0 || attemptId > _fusionAttemptCounter) {
             revert InvalidFusionAttemptId();
         }
        return fusionAttempts[attemptId];
    }

    /// @dev Gets the current hash representing the fusion rules logic.
    /// @return The fusion rules hash.
    function getFusionRulesHash() external view returns (bytes32) {
        return _fusionRulesHash;
    }

    /// @dev Gets the list of currently approved ERC20 tokens for deposit.
    /// Note: This is inefficient for a large number of tokens. A real contract
    /// might store approved tokens in an iterable structure or use events to track.
    /// For this example, it checks a predefined range or relies on external tracking.
    /// This implementation would need an array state variable to store approved tokens
    /// explicitly if we want to list them. The current mapping only allows checking individual status.
    /// Let's add a placeholder or just keep the check function.
    /// Keeping it simple: you can check `approvedTokens[address]`. A list view is complex with just a mapping.
    /// Let's add a function to check if *a* token is approved.
    function isTokenApproved(address tokenAddress) external view returns (bool) {
         return approvedTokens[tokenAddress];
    }

    /// @dev Gets the owner address of a specific deposit.
    /// @param depositId The ID of the deposit.
    /// @return The owner's address.
    function getDepositOwner(uint256 depositId) external view returns (address) {
        if (depositId == 0 || depositId > _depositCounter) {
             revert InvalidDepositId();
         }
        return deposits[depositId].owner;
    }

    /// @dev Gets the number of active deposits for a specific user.
    /// Note: This iterates through the user's deposit IDs. Can be inefficient if a user has many deposits.
    /// A more efficient way would be to track active count in userDeposits mapping.
    /// @param user The address of the user.
    /// @return The count of active deposits.
    function getUserDepositCount(address user) external view returns (uint256) {
        uint256 count = 0;
        uint256[] memory userDepIds = userDeposits[user];
        for(uint i = 0; i < userDepIds.length; i++) {
             if (deposits[userDepIds[i]].isActive) {
                 count++;
             }
        }
        return count;
    }

    /// @dev Predicts the *potential* withdrawal outcome (token and amount)
    /// based on the deposit's *current* properties and configured rules.
    /// This is a simulation and does not account for state changes during withdrawal.
    /// @param depositId The ID of the deposit.
    /// @return tokenToWithdraw The address of the token predicted to be withdrawn.
    /// @return predictedAmount The predicted amount to be withdrawn.
    function predictWithdrawalOutcome(uint256 depositId) external view returns (address tokenToWithdraw, uint256 predictedAmount) {
        if (depositId == 0 || depositId > _depositCounter || !deposits[depositId].isActive) {
             revert InvalidDepositId(); // Or DepositNotActive
         }
        Deposit storage deposit = deposits[depositId];

        tokenToWithdraw = deposit.tokenAddress;
        predictedAmount = deposit.currentAmount;

        // --- Simulate Quantum Measurement Outcome Logic (Matches withdraw function) ---
        if (deposit.currentProperties.length > 0) {
            uint256 propertyFactor = deposit.currentProperties[0];
            if (propertyFactor > 0) {
                predictedAmount = (predictedAmount * propertyFactor) / (MIN_PROPERTIES > 0 ? MIN_PROPERTIES : 1);
            } else {
                predictedAmount = predictedAmount / 2; // Example penalty
            }

            uint256 totalPropertiesSum = 0;
            for(uint i = 0; i < deposit.currentProperties.length; i++) {
                totalPropertiesSum += deposit.currentProperties[i];
            }

            address configuredResultToken = address(0);
            uint256 bestThreshold = 0;
             for (uint256 threshold = 0; threshold < 1000; threshold += 10) { // Example: Check thresholds 0, 10, 20...
                 if (_fusionResultTokens[threshold] != address(0) && totalPropertiesSum >= threshold) {
                     bestThreshold = threshold;
                 }
            }

            if (bestThreshold > 0) {
                 configuredResultToken = _fusionResultTokens[bestThreshold];
                 if (configuredResultToken != address(0) && configuredResultToken != deposit.tokenAddress) {
                    tokenToWithdraw = configuredResultToken;
                    // Keep amount same for simplicity in prediction
                 } else {
                    tokenToWithdraw = deposit.tokenAddress;
                 }
            } else {
                tokenToWithdraw = deposit.tokenAddress;
            }
        }
        // --- End Simulation ---

        return (tokenToWithdraw, predictedAmount);
    }

    /// @dev Gets the value of a specific quantum property for a deposit.
    /// @param depositId The ID of the deposit.
    /// @param propertyIndex The index of the property.
    /// @return The property value.
    function getPropertyValue(uint256 depositId, uint256 propertyIndex) external view returns (uint256) {
        if (depositId == 0 || depositId > _depositCounter) {
             revert InvalidDepositId();
         }
        Deposit storage deposit = deposits[depositId];
        if (propertyIndex >= deposit.currentProperties.length) {
            revert InvalidPropertyIndex();
        }
        return deposit.currentProperties[propertyIndex];
    }

     /// @dev Checks if user-initiated property mutation is currently allowed.
    function isPropertyMutationAllowed() external view returns (bool) {
         return _propertyMutationAllowed;
    }

    /// @dev Checks if user-initiated fluctuation triggering is currently enabled.
    function isFluctuationEnabled() external view returns (bool) {
         return _fluctuationEnabled;
    }

    /// @dev Gets the configured result token for a specific property threshold.
    /// @param propertyThreshold The property threshold to check.
    /// @return The configured result token address (0 if none set or set to 0).
    function getFusionResultToken(uint256 propertyThreshold) external view returns (address) {
         return _fusionResultTokens[propertyThreshold];
    }

    /// @dev Checks if a deposit is currently active (not withdrawn or fused).
    /// @param depositId The ID of the deposit.
    /// @return True if the deposit is active, false otherwise.
    function isDepositActive(uint256 depositId) external view returns (bool) {
        if (depositId == 0 || depositId > _depositCounter) {
             return false; // Invalid ID is not active
         }
         return deposits[depositId].isActive;
    }


    // --- Internal Helper Functions ---

    // No complex internal helpers needed beyond the logic embedded in the functions above for this example.
    // e.g., _calculateFusionOutcome(uint256 d1_props, uint256 d2_props, bytes32 nonce) could be one.
    // _applyFluctuation(uint256[] storage props, bytes32 seed) could be another.
    // Keeping logic inline for clarity in this example.

     // Custom error for attempting to use address(0) where a valid token is expected
    error InvalidDepositToken();
    // Custom error for ETH transfer failure
    error EthTransferFailed();
}
```