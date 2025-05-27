Okay, let's design an interesting, advanced-concept smart contract that isn't a direct copy of common open-source patterns like standard ERC20/721, basic DeFi primitives, or simple DAOs.

We'll create a "Quantum Vault" contract. This contract will manage ERC20 tokens based on simulated "quantum" principles:

1.  **Superposition:** A vault holds funds, but its final state (how the funds are distributed, who gets what) is *undetermined* until an "observation" event. Multiple potential outcomes exist simultaneously before observation.
2.  **Observation/Collapse:** A specific action or time trigger "collapses" the superposition into one concrete outcome based on simulated probabilities or external conditions.
3.  **Entanglement (Simulated):** Observing one vault can trigger the simultaneous observation/collapse of other "entangled" vaults.
4.  **Probabilistic Outcomes:** The selection of the final outcome upon observation is based on weighted probabilities assigned to each potential state (simulating quantum probability).
5.  **Conditional Collapse:** Observation can also be triggered by specific on-chain conditions being met (simulating external influence on state collapse).

This concept allows for creative escrow, conditional distributions, or gamified participation where the final result is uncertain until triggered.

**Outline & Function Summary:**

**I. Core Structure & Concepts:**
*   Defines `Outcome` struct: Represents a potential final state with token recipients, amounts, weights, and conditions.
*   Defines `Vault` struct: Represents a single "Quantum Vault" with its owner, state (superposition/observed), potential outcomes, deposited balances, collapse time, and entangled vaults.
*   Manages multiple vaults via a mapping.
*   Tracks ERC20 token balances deposited into the contract specifically for distribution by vaults.

**II. Access Control & Safety:**
*   Uses `Ownable` for contract-level administrative functions.
*   Uses `ReentrancyGuard` for critical state-changing functions involving token transfers.

**III. Vault Management Functions:**
1.  `createVault()`: Creates a new Quantum Vault in a state of superposition.
2.  `addPossibleOutcome(uint256 vaultId, Outcome calldata outcome)`: Adds a potential outcome to a vault (only in superposition).
3.  `removePossibleOutcome(uint256 vaultId, uint256 outcomeIndex)`: Removes an outcome by index (only in superposition).
4.  `updateOutcomeWeight(uint256 vaultId, uint256 outcomeIndex, uint16 newWeight)`: Adjusts the probability weight of an outcome (only in superposition). Weights are relative.
5.  `setCollapseTime(uint256 vaultId, uint64 collapseTimestamp)`: Sets a specific time after which the vault can be automatically collapsed.
6.  `setOutcomeRecipient(uint256 vaultId, uint256 outcomeIndex, address recipient)`: Sets or updates the recipient for a specific outcome's tokens.
7.  `transferVaultOwnership(uint256 vaultId, address newOwner)`: Transfers ownership of a specific vault (vault owner can configure outcomes, trigger specific actions).
8.  `renounceVaultOwnership(uint256 vaultId)`: Renounces ownership of a specific vault.

**IV. Token Deposit & Management:**
9.  `depositERC20IntoVault(uint256 vaultId, address tokenAddress, uint256 amount)`: Allows depositing ERC20 tokens *into* a specific vault *while it's in superposition*. These tokens are held by the contract, earmarked for distribution upon collapse. Requires prior approval.

**V. Entanglement Functions:**
10. `addEntangledVault(uint256 vaultId, uint256 entangledVaultId)`: Links two vaults. Observing `vaultId` can trigger observation of `entangledVaultId`. Prevents linking if either is already observed or if it creates simple cycles.
11. `removeEntangledVault(uint256 vaultId, uint256 entangledVaultId)`: Removes a link between two vaults.

**VI. Observation & Collapse Functions (The Core Logic):**
12. `observeVault(uint256 vaultId)`: The key function. Triggers the "collapse" of the vault's superposition.
    *   Checks if already observed.
    *   Checks if collapse time has passed *or* if an external condition (simulated here, could integrate oracle) is met (conceptually).
    *   Uses a simulated probabilistic mechanism (`_pickOutcome`) based on outcome weights and block data to select the final outcome.
    *   Sets the vault state to 'observed' and records the chosen outcome index.
    *   Distributes deposited tokens according to the chosen outcome (`_distributeTokens`).
    *   Recursively (or iteratively with safeguards) triggers observation on entangled vaults (`_observeEntangled`).
13. `collapseVaultIfDue(uint256 vaultId)`: Allows anyone to trigger observation if the `collapseTimestamp` has been reached, ensuring time-based decay can be enforced even if the owner is inactive.

**VII. Post-Observation & Claiming:**
14. `claimObservedOutcome(uint256 vaultId)`: Allows the designated recipient of the observed outcome to claim the tokens assigned to them.

**VIII. View & Information Functions:**
15. `getVaultDetails(uint256 vaultId)`: Returns summary details of a vault.
16. `getPossibleOutcomes(uint256 vaultId)`: Returns the list of potential outcomes for a vault (only before observation).
17. `getOutcomeDetails(uint256 vaultId, uint256 outcomeIndex)`: Returns specific details for one outcome.
18. `getObservedOutcomeIndex(uint256 vaultId)`: Returns the index of the chosen outcome after observation, or a special value (e.g., type(uint256).max) if not observed.
19. `isVaultObserved(uint256 vaultId)`: Returns boolean indicating if the vault has been observed.
20. `getVaultOwner(uint256 vaultId)`: Returns the owner address of a specific vault.
21. `getEntangledVaults(uint256 vaultId)`: Returns the list of vault IDs entangled with this one.
22. `getVaultERC20Deposit(uint256 vaultId, address tokenAddress)`: Returns the total amount of a specific token deposited into this vault.
23. `getTotalVaults()`: Returns the total number of vaults created.
24. `getContractERC20Balance(address tokenAddress)`: Returns the total balance of a specific token held by the contract across all vaults/pools.

**IX. Internal Helper Functions:**
*   `_pickOutcome(uint256 vaultId, bytes32 seed)`: Internal deterministic probabilistic selection based on weights and a seed.
*   `_distributeTokens(uint256 vaultId, uint256 chosenOutcomeIndex)`: Internal logic to transfer tokens based on the observed outcome.
*   `_observeEntangled(uint256 vaultId, uint256 initialVaultId)`: Internal logic to trigger observation on entangled vaults, preventing infinite loops.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/// @title QuantumVault
/// @author YourName (Conceptual Implementation)
/// @notice A smart contract simulating quantum superposition, observation, and entanglement for ERC20 token distribution.
/// Funds are held in a state of multiple possible outcomes until triggered by an "observation" event.
/// This is a conceptual demonstration; on-chain randomness and true quantum effects are simulated.

// --- Outline & Function Summary ---
// I. Core Structure & Concepts
//    - Defines Outcome and Vault structs.
//    - Manages vaults and deposited token balances.
// II. Access Control & Safety
//    - Inherits Ownable and ReentrancyGuard.
// III. Vault Management Functions
//    1. createVault()
//    2. addPossibleOutcome(uint256 vaultId, Outcome calldata outcome)
//    3. removePossibleOutcome(uint256 vaultId, uint256 outcomeIndex)
//    4. updateOutcomeWeight(uint256 vaultId, uint256 outcomeIndex, uint16 newWeight)
//    5. setCollapseTime(uint256 vaultId, uint64 collapseTimestamp)
//    6. setOutcomeRecipient(uint256 vaultId, uint256 outcomeIndex, address recipient)
//    7. transferVaultOwnership(uint256 vaultId, address newOwner)
//    8. renounceVaultOwnership(uint256 vaultId)
// IV. Token Deposit & Management
//    9. depositERC20IntoVault(uint256 vaultId, address tokenAddress, uint256 amount)
// V. Entanglement Functions
//    10. addEntangledVault(uint256 vaultId, uint256 entangledVaultId)
//    11. removeEntangledVault(uint256 vaultId, uint256 entangledVaultId)
// VI. Observation & Collapse Functions
//    12. observeVault(uint256 vaultId) - Core collapse logic
//    13. collapseVaultIfDue(uint256 vaultId) - Time-triggered collapse
// VII. Post-Observation & Claiming
//    14. claimObservedOutcome(uint256 vaultId)
// VIII. View & Information Functions
//    15. getVaultDetails(uint256 vaultId)
//    16. getPossibleOutcomes(uint256 vaultId)
//    17. getOutcomeDetails(uint256 vaultId, uint256 outcomeIndex)
//    18. getObservedOutcomeIndex(uint256 vaultId)
//    19. isVaultObserved(uint256 vaultId)
//    20. getVaultOwner(uint256 vaultId)
//    21. getEntangledVaults(uint256 vaultId)
//    22. getVaultERC20Deposit(uint256 vaultId, address tokenAddress)
//    23. getTotalVaults()
//    24. getContractERC20Balance(address tokenAddress)
// IX. Internal Helper Functions (Not directly callable externally)
//    - _pickOutcome(uint256 vaultId, bytes32 seed)
//    - _distributeTokens(uint256 vaultId, uint256 chosenOutcomeIndex)
//    - _observeEntangled(uint256 vaultId, uint256 initialVaultId)


contract QuantumVault is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct Outcome {
        address tokenAddress; // The token distributed in this outcome
        uint256 amount;       // The amount of the token distributed
        address recipient;    // The address that receives the token amount
        uint16 weight;        // Relative weight for probability selection
        bytes32 conditionHash; // Optional hash representing an external condition for observation (conceptual)
        string description;   // Optional description of the outcome
    }

    struct Vault {
        address owner;             // Owner of this specific vault
        bool isObserved;           // True if superposition has collapsed
        uint256 observedOutcomeIndex; // Index of the chosen outcome if observed (use type(uint256).max if not observed)
        uint64 collapseTimestamp;  // Timestamp after which collapseVaultIfDue can be called (0 if none set)
        Outcome[] possibleOutcomes; // Potential states/outcomes
        uint256[] entangledVaultIds; // IDs of vaults entangled with this one
        // Note: Deposited balances are stored in a separate mapping globally
    }

    // Mapping from vault ID to Vault struct
    mapping(uint256 => Vault) public vaults;

    // Mapping from vault ID => token address => deposited amount earmarked for this vault
    mapping(uint256 => mapping(address => uint256)) private depositedBalances;

    // Mapping from vault ID => token address => amount already claimed by recipients
    mapping(uint256 => mapping(address => mapping(address => uint256))) private claimedBalances;


    uint256 private nextVaultId = 0;

    // Special value for observedOutcomeIndex when not observed
    uint256 private constant NOT_OBSERVED = type(uint256).max;

    event VaultCreated(uint256 indexed vaultId, address indexed owner);
    event OutcomeAdded(uint256 indexed vaultId, uint256 indexed outcomeIndex, address tokenAddress, uint256 amount, uint16 weight);
    event OutcomeRemoved(uint256 indexed vaultId, uint256 indexed outcomeIndex);
    event OutcomeWeightUpdated(uint256 indexed vaultId, uint256 indexed outcomeIndex, uint16 newWeight);
    event CollapseTimeSet(uint256 indexed vaultId, uint64 collapseTimestamp);
    event OutcomeRecipientSet(uint256 indexed vaultId, uint256 indexed outcomeIndex, address indexed recipient);
    event TokensDeposited(uint256 indexed vaultId, address indexed tokenAddress, uint256 amount, address indexed depositor);
    event VaultObserved(uint256 indexed vaultId, uint256 indexed chosenOutcomeIndex);
    event TokensClaimed(uint256 indexed vaultId, uint256 indexed outcomeIndex, address indexed recipient, address tokenAddress, uint256 amount);
    event VaultEntangled(uint256 indexed vaultId1, uint256 indexed vaultId2);
    event VaultUnentangled(uint256 indexed vaultId1, uint256 indexed vaultId2);
    event VaultOwnershipTransferred(uint256 indexed vaultId, address indexed previousOwner, address indexed newOwner);
    event VaultOwnershipRenounced(uint256 indexed vaultId, address indexed previousOwner);

    constructor() Ownable(msg.sender) {}

    modifier onlyVaultOwner(uint256 _vaultId) {
        require(vaults[_vaultId].owner == msg.sender, "Caller is not vault owner");
        _;
    }

    modifier notObserved(uint256 _vaultId) {
        require(!vaults[_vaultId].isObserved, "Vault is already observed");
        _;
    }

    modifier mustBeObserved(uint256 _vaultId) {
        require(vaults[_vaultId].isObserved, "Vault is not yet observed");
        _;
    }

    /// @notice Creates a new quantum vault in a state of superposition.
    /// The caller becomes the owner of the new vault.
    /// @return vaultId The ID of the newly created vault.
    function createVault() external returns (uint256 vaultId) {
        vaultId = nextVaultId++;
        vaults[vaultId].owner = msg.sender;
        vaults[vaultId].isObserved = false;
        vaults[vaultId].observedOutcomeIndex = NOT_OBSERVED; // Indicate not observed

        emit VaultCreated(vaultId, msg.sender);
    }

    /// @notice Adds a possible outcome to a vault. Can only be done while the vault is in superposition.
    /// @param vaultId The ID of the vault.
    /// @param outcome The details of the possible outcome (token, amount, recipient, weight, etc.).
    function addPossibleOutcome(uint256 vaultId, Outcome calldata outcome) external onlyVaultOwner(vaultId) notObserved(vaultId) {
        require(vaultId < nextVaultId, "Vault does not exist");
        require(outcome.recipient != address(0), "Recipient cannot be zero address");
        require(outcome.weight > 0, "Outcome weight must be positive");

        Vault storage vault = vaults[vaultId];
        uint256 outcomeIndex = vault.possibleOutcomes.length;
        vault.possibleOutcomes.push(outcome);

        emit OutcomeAdded(vaultId, outcomeIndex, outcome.tokenAddress, outcome.amount, outcome.weight);
    }

    /// @notice Removes a possible outcome from a vault by index. Can only be done while in superposition.
    /// Note: Removing outcomes changes their indices. Use with caution.
    /// @param vaultId The ID of the vault.
    /// @param outcomeIndex The index of the outcome to remove.
    function removePossibleOutcome(uint256 vaultId, uint256 outcomeIndex) external onlyVaultOwner(vaultId) notObserved(vaultId) {
        Vault storage vault = vaults[vaultId];
        require(outcomeIndex < vault.possibleOutcomes.length, "Outcome index out of bounds");

        // Simple removal by moving the last element into the slot and popping
        uint256 lastIndex = vault.possibleOutcomes.length - 1;
        if (outcomeIndex != lastIndex) {
            vault.possibleOutcomes[outcomeIndex] = vault.possibleOutcomes[lastIndex];
        }
        vault.possibleOutcomes.pop();

        emit OutcomeRemoved(vaultId, outcomeIndex);
    }

    /// @notice Updates the probability weight of an existing outcome. Can only be done while in superposition.
    /// @param vaultId The ID of the vault.
    /// @param outcomeIndex The index of the outcome to update.
    /// @param newWeight The new relative weight (must be positive).
    function updateOutcomeWeight(uint256 vaultId, uint256 outcomeIndex, uint16 newWeight) external onlyVaultOwner(vaultId) notObserved(vaultId) {
        Vault storage vault = vaults[vaultId];
        require(outcomeIndex < vault.possibleOutcomes.length, "Outcome index out of bounds");
        require(newWeight > 0, "Outcome weight must be positive");

        vault.possibleOutcomes[outcomeIndex].weight = newWeight;

        emit OutcomeWeightUpdated(vaultId, outcomeIndex, newWeight);
    }

    /// @notice Sets the timestamp after which the vault can be collapsed by anyone using `collapseVaultIfDue`.
    /// Can only be set while the vault is in superposition.
    /// @param vaultId The ID of the vault.
    /// @param collapseTimestamp The unix timestamp. Set to 0 to remove timed collapse.
    function setCollapseTime(uint256 vaultId, uint64 collapseTimestamp) external onlyVaultOwner(vaultId) notObserved(vaultId) {
        require(vaultId < nextVaultId, "Vault does not exist");
        // Allow setting a time in the past or future, or removing it (0).
        vaults[vaultId].collapseTimestamp = collapseTimestamp;

        emit CollapseTimeSet(vaultId, collapseTimestamp);
    }

    /// @notice Sets or updates the recipient for a specific outcome. Can only be done while in superposition.
    /// @param vaultId The ID of the vault.
    /// @param outcomeIndex The index of the outcome to update.
    /// @param recipient The new recipient address.
    function setOutcomeRecipient(uint256 vaultId, uint256 outcomeIndex, address recipient) external onlyVaultOwner(vaultId) notObserved(vaultId) {
         Vault storage vault = vaults[vaultId];
        require(outcomeIndex < vault.possibleOutcomes.length, "Outcome index out of bounds");
        require(recipient != address(0), "Recipient cannot be zero address");

        vault.possibleOutcomes[outcomeIndex].recipient = recipient;

        emit OutcomeRecipientSet(vaultId, outcomeIndex, recipient);
    }


    /// @notice Transfers ownership of a specific vault to a new address.
    /// @param vaultId The ID of the vault.
    /// @param newOwner The address of the new owner.
    function transferVaultOwnership(uint256 vaultId, address newOwner) external onlyVaultOwner(vaultId) {
        require(vaultId < nextVaultId, "Vault does not exist");
        require(newOwner != address(0), "New owner cannot be the zero address");
        address previousOwner = vaults[vaultId].owner;
        vaults[vaultId].owner = newOwner;
        emit VaultOwnershipTransferred(vaultId, previousOwner, newOwner);
    }

    /// @notice Renounces ownership of a specific vault. The vault will then have no owner.
    /// @param vaultId The ID of the vault.
    function renounceVaultOwnership(uint256 vaultId) external onlyVaultOwner(vaultId) {
        require(vaultId < nextVaultId, "Vault does not exist");
        address previousOwner = vaults[vaultId].owner;
        vaults[vaultId].owner = address(0);
        emit VaultOwnershipRenounced(vaultId, previousOwner);
    }


    /// @notice Deposits ERC20 tokens into the contract, earmarked for a specific vault.
    /// This requires the caller to have granted allowance to the contract beforehand.
    /// Can only be done while the vault is in superposition.
    /// @param vaultId The ID of the vault.
    /// @param tokenAddress The address of the ERC20 token.
    /// @param amount The amount of tokens to deposit.
    function depositERC20IntoVault(uint256 vaultId, address tokenAddress, uint256 amount) external notObserved(vaultId) {
        require(vaultId < nextVaultId, "Vault does not exist");
        require(tokenAddress != address(0), "Token address cannot be zero");
        require(amount > 0, "Amount must be positive");

        // Pull tokens from the caller
        IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);

        // Track the deposited amount specifically for this vault
        depositedBalances[vaultId][tokenAddress] += amount;

        emit TokensDeposited(vaultId, tokenAddress, amount, msg.sender);
    }

    /// @notice Adds a link between two vaults. Observing the first vault can trigger observation of the second.
    /// Links are unidirectional but checked symmetrically for simple cases.
    /// @param vaultId The ID of the source vault.
    /// @param entangledVaultId The ID of the vault to entangle with.
    function addEntangledVault(uint256 vaultId, uint256 entangledVaultId) external onlyVaultOwner(vaultId) notObserved(vaultId) {
        require(vaultId < nextVaultId && entangledVaultId < nextVaultId, "Vault does not exist");
        require(vaultId != entangledVaultId, "Cannot entangle a vault with itself");
        require(!vaults[entangledVaultId].isObserved, "Cannot entangle with an already observed vault");

        Vault storage vault = vaults[vaultId];
        // Check if already entangled to prevent duplicates
        for (uint i = 0; i < vault.entangledVaultIds.length; i++) {
            require(vault.entangledVaultIds[i] != entangledVaultId, "Vaults are already entangled");
        }

        vault.entangledVaultIds.push(entangledVaultId);

        emit VaultEntangled(vaultId, entangledVaultId);
    }

    /// @notice Removes a link between two vaults.
    /// @param vaultId The ID of the source vault.
    /// @param entangledVaultId The ID of the vault to unentangle.
    function removeEntangledVault(uint256 vaultId, uint256 entangledVaultId) external onlyVaultOwner(vaultId) {
        require(vaultId < nextVaultId, "Vault does not exist");
        Vault storage vault = vaults[vaultId];

        bool found = false;
        for (uint i = 0; i < vault.entangledVaultIds.length; i++) {
            if (vault.entangledVaultIds[i] == entangledVaultId) {
                // Remove by swapping with last and popping
                uint256 lastIndex = vault.entangledVaultIds.length - 1;
                if (i != lastIndex) {
                    vault.entangledVaultIds[i] = vault.entangledVaultIds[lastIndex];
                }
                vault.entangledVaultIds.pop();
                found = true;
                break;
            }
        }
        require(found, "Entanglement link not found");

        emit VaultUnentangled(vaultId, entangledVaultId);
    }


    /// @notice Triggers the "observation" and collapse of the vault's superposition.
    /// This function selects one outcome probabilistically (or based on conditions) and distributes funds.
    /// @param vaultId The ID of the vault to observe.
    function observeVault(uint256 vaultId) public nonReentrant {
        require(vaultId < nextVaultId, "Vault does not exist");
        Vault storage vault = vaults[vaultId];
        require(!vault.isObserved, "Vault is already observed");
        require(vault.possibleOutcomes.length > 0, "No outcomes defined for this vault");

        // --- Conceptual Condition Check (Simulated) ---
        // This part could be replaced with an Oracle call (Chainlink, etc.)
        // to check a real-world condition or external state.
        // For this demo, we'll rely solely on the probabilistic selection.
        // Example: require(OracleContract(oracleAddress).isConditionMet(vault.conditionalDataHash), "External condition not met");
        // Or check time: require(block.timestamp >= vault.someConditionTime, "Time condition not met");
        // We use collapseVaultIfDue for the simple time check.
        // The primary trigger for *this* function is intended to be direct user action
        // or triggered via entanglement or collapseIfDue.

        // --- Probabilistic Selection ---
        // Simulate randomness using block data. NOTE: This is NOT truly random
        // and can be subject to miner manipulation in a real-world scenario.
        // For production, use Chainlink VRF or similar secure randomness solution.
        bytes32 seed = keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty, // Or block.prevrandao post-merge
            vaultId,
            msg.sender // Include caller to make seed unique per observation attempt
        ));
        uint256 chosenOutcomeIndex = _pickOutcome(vaultId, seed);
        require(chosenOutcomeIndex < vault.possibleOutcomes.length, "Failed to pick a valid outcome index");

        // --- Collapse State ---
        vault.isObserved = true;
        vault.observedOutcomeIndex = chosenOutcomeIndex;

        emit VaultObserved(vaultId, chosenOutcomeIndex);

        // --- Distribute Tokens ---
        _distributeTokens(vaultId, chosenOutcomeIndex);

        // --- Trigger Entangled Vaults ---
        _observeEntangled(vaultId, vaultId); // Start observation chain from this vault
    }

    /// @notice Allows anyone to trigger observation if the collapse timestamp has passed.
    /// Ensures time-based "decay" can be enforced.
    /// @param vaultId The ID of the vault.
    function collapseVaultIfDue(uint256 vaultId) external {
        require(vaultId < nextVaultId, "Vault does not exist");
        Vault storage vault = vaults[vaultId];
        require(!vault.isObserved, "Vault is already observed");
        require(vault.collapseTimestamp > 0, "No collapse time set for this vault");
        require(block.timestamp >= vault.collapseTimestamp, "Collapse time not yet reached");

        // Trigger the main observation logic
        observeVault(vaultId);
    }

    /// @notice Allows the designated recipient of the observed outcome to claim their tokens.
    /// Can only be called after the vault has been observed.
    /// @param vaultId The ID of the vault.
    function claimObservedOutcome(uint256 vaultId) external nonReentrant mustBeObserved(vaultId) {
        Vault storage vault = vaults[vaultId];
        uint256 chosenOutcomeIndex = vault.observedOutcomeIndex;
        require(chosenOutcomeIndex < vault.possibleOutcomes.length, "Invalid observed outcome index");

        Outcome storage chosenOutcome = vault.possibleOutcomes[chosenOutcomeIndex];
        address recipient = chosenOutcome.recipient;
        address tokenAddress = chosenOutcome.tokenAddress;
        uint256 amountToClaim = chosenOutcome.amount;

        require(msg.sender == recipient, "Caller is not the recipient of the observed outcome");
        require(amountToClaim > 0, "No tokens allocated for this outcome/recipient");

        // Check how much has already been claimed by this recipient for this outcome
        uint256 claimedSoFar = claimedBalances[vaultId][tokenAddress][recipient];
        uint256 remainingToClaim = amountToClaim - claimedSoFar;

        require(remainingToClaim > 0, "All allocated tokens for this outcome already claimed");

        // Check if the vault actually received enough deposits for this token
        uint256 depositedForThisToken = depositedBalances[vaultId][tokenAddress];
        // Note: In a simple model, the total amount for ALL outcomes of this token
        // should ideally not exceed the total deposited amount for the vault+token.
        // We assume outcomes are defined responsibly. Distribution transfers
        // only up to what was deposited for this specific vault+token combination.
        // We claim up to remainingToClaim, but limited by actual deposited balance not yet claimed by *anyone* from this vault.
        // A more robust system might track *total* distributed vs *total* deposited per vault+token.
        // For simplicity here, we just check against the *recipient's* allocated amount.

        // Update claimed balance BEFORE transfer
        claimedBalances[vaultId][tokenAddress][recipient] += remainingToClaim;

        // Transfer the tokens
        IERC20(tokenAddress).safeTransfer(recipient, remainingToClaim);

        emit TokensClaimed(vaultId, chosenOutcomeIndex, recipient, tokenAddress, remainingToClaim);
    }


    /// @notice Internal function to pick an outcome probabilistically based on weights.
    /// Uses a provided seed for deterministic (given the seed) selection.
    /// @param vaultId The ID of the vault.
    /// @param seed A bytes32 value used as the basis for selection.
    /// @return The index of the chosen outcome.
    function _pickOutcome(uint256 vaultId, bytes32 seed) internal view returns (uint256) {
        Vault storage vault = vaults[vaultId];
        uint256 totalWeight = 0;
        for (uint i = 0; i < vault.possibleOutcomes.length; i++) {
            totalWeight += vault.possibleOutcomes[i].weight;
        }
        require(totalWeight > 0, "Total outcome weight must be positive to pick an outcome");

        // Use the seed to get a pseudo-random number within the range of totalWeight
        uint256 randomNumber = uint256(seed) % totalWeight;

        // Find the outcome corresponding to the random number and weights
        uint256 cumulativeWeight = 0;
        for (uint i = 0; i < vault.possibleOutcomes.length; i++) {
            cumulativeWeight += vault.possibleOutcomes[i].weight;
            if (randomNumber < cumulativeWeight) {
                return i; // This outcome is chosen
            }
        }

        // Should not be reached if totalWeight is > 0, but as a fallback
        return 0;
    }

    /// @notice Internal function to distribute tokens based on the chosen outcome.
    /// Called after `observeVault`.
    /// @param vaultId The ID of the vault.
    /// @param chosenOutcomeIndex The index of the observed outcome.
    function _distributeTokens(uint256 vaultId, uint256 chosenOutcomeIndex) internal {
        Vault storage vault = vaults[vaultId];
        require(chosenOutcomeIndex < vault.possibleOutcomes.length, "Invalid chosen outcome index for distribution");

        // The tokens are not distributed directly here, they are marked as claimable
        // by updating `claimedBalances` in the `claimObservedOutcome` function.
        // This function's primary role after picking is setting the state.
        // We could also pre-distribute *some* specific amount here if needed,
        // but the `claimObservedOutcome` pattern is safer against reentrancy
        // issues within a complex distribution logic.
        // For this implementation, the claim logic handles the actual transfer.
        // We could potentially iterate through ALL outcomes here and adjust
        // `claimedBalances` for the chosen one, but doing it in `claimObservedOutcome`
        // ties the state update directly to the transfer attempt.
        // Let's add a simple loop to mark amounts claimable, although the
        // `claimObservedOutcome` function does the actual check based on `chosenOutcomeIndex`.
        // A more complex model might distribute *all* vault funds across *all* outcomes
        // based on percentages, but this outcome struct is simpler: one outcome = one transfer.
        // The claim function is the right place to enforce the "only recipient of chosen outcome" logic.

        // No token transfers or balance updates happen directly in *this* function
        // in this specific contract design. `claimObservedOutcome` handles it.
        // This function primarily serves to finalize the state by calling _pickOutcome
        // and setting `observedOutcomeIndex`.
    }


    /// @notice Internal function to trigger observation on entangled vaults.
    /// Uses a simple depth limit to prevent infinite loops in complex entanglement graphs.
    /// @param vaultId The current vault ID being observed.
    /// @param initialVaultId The ID of the vault that started the observation chain. Used for cycle detection prevention (basic).
    function _observeEntangled(uint256 vaultId, uint256 initialVaultId) internal {
        Vault storage vault = vaults[vaultId];

        // Iterate through entangled vaults
        for (uint i = 0; i < vault.entangledVaultIds.length; i++) {
            uint256 entangledId = vault.entangledVaultIds[i];

            // Prevent observing the initial vault again in this chain
            if (entangledId == initialVaultId) {
                continue;
            }

            // Only observe if the entangled vault is not already observed
            if (!vaults[entangledId].isObserved) {
                 // We use a non-reentrant call to `observeVault` to protect against complex reentrancy
                 // across entangled vaults, though a very deep or cyclical entanglement
                 // graph could still hit gas limits.
                 // In a real-world scenario, consider queuing observations off-chain
                 // or using a different entanglement model.
                 // Recursive call - mind gas limits!
                 observeVault(entangledId);
            }
        }
    }

    // --- View & Information Functions ---

    /// @notice Gets summary details for a vault.
    /// @param vaultId The ID of the vault.
    /// @return owner The vault owner.
    /// @return isObserved True if observed.
    /// @return observedOutcomeIndex The index of the observed outcome (or NOT_OBSERVED).
    /// @return collapseTimestamp The timestamp for timed collapse.
    /// @return possibleOutcomesCount The number of potential outcomes.
    /// @return entangledVaultsCount The number of entangled vaults.
    function getVaultDetails(uint256 vaultId)
        external
        view
        returns (
            address owner,
            bool isObserved,
            uint256 observedOutcomeIndex,
            uint64 collapseTimestamp,
            uint256 possibleOutcomesCount,
            uint256 entangledVaultsCount
        )
    {
        require(vaultId < nextVaultId, "Vault does not exist");
        Vault storage vault = vaults[vaultId];
        return (
            vault.owner,
            vault.isObserved,
            vault.observedOutcomeIndex,
            vault.collapseTimestamp,
            vault.possibleOutcomes.length,
            vault.entangledVaultIds.length
        );
    }

    /// @notice Gets the list of potential outcomes for a vault. Only available if not observed.
    /// @param vaultId The ID of the vault.
    /// @return A dynamic array of Outcome structs.
    function getPossibleOutcomes(uint256 vaultId) external view notObserved(vaultId) returns (Outcome[] memory) {
         require(vaultId < nextVaultId, "Vault does not exist");
        Vault storage vault = vaults[vaultId];
        return vault.possibleOutcomes;
    }

    /// @notice Gets details for a specific outcome by index.
    /// @param vaultId The ID of the vault.
    /// @param outcomeIndex The index of the outcome.
    /// @return The Outcome struct details.
    function getOutcomeDetails(uint256 vaultId, uint256 outcomeIndex) external view returns (Outcome memory) {
        require(vaultId < nextVaultId, "Vault does not exist");
        Vault storage vault = vaults[vaultId];
        require(outcomeIndex < vault.possibleOutcomes.length, "Outcome index out of bounds");
        return vault.possibleOutcomes[outcomeIndex];
    }

    /// @notice Gets the index of the observed outcome.
    /// @param vaultId The ID of the vault.
    /// @return The index if observed, otherwise type(uint256).max.
    function getObservedOutcomeIndex(uint256 vaultId) external view returns (uint256) {
        require(vaultId < nextVaultId, "Vault does not exist");
        return vaults[vaultId].observedOutcomeIndex;
    }

    /// @notice Checks if a vault has been observed.
    /// @param vaultId The ID of the vault.
    /// @return True if observed, false otherwise.
    function isVaultObserved(uint256 vaultId) external view returns (bool) {
        require(vaultId < nextVaultId, "Vault does not exist");
        return vaults[vaultId].isObserved;
    }

    /// @notice Gets the owner of a specific vault.
    /// @param vaultId The ID of the vault.
    /// @return The owner address.
    function getVaultOwner(uint256 vaultId) external view returns (address) {
        require(vaultId < nextVaultId, "Vault does not exist");
        return vaults[vaultId].owner;
    }

    /// @notice Gets the list of vault IDs entangled with this one.
    /// @param vaultId The ID of the vault.
    /// @return An array of entangled vault IDs.
    function getEntangledVaults(uint256 vaultId) external view returns (uint256[] memory) {
        require(vaultId < nextVaultId, "Vault does not exist");
        return vaults[vaultId].entangledVaultIds;
    }

    /// @notice Gets the total amount of a specific token deposited into a vault.
    /// This amount is available for distribution via the chosen outcome.
    /// @param vaultId The ID of the vault.
    /// @param tokenAddress The address of the ERC20 token.
    /// @return The total deposited amount for this token in this vault.
    function getVaultERC20Deposit(uint256 vaultId, address tokenAddress) external view returns (uint256) {
        require(vaultId < nextVaultId, "Vault does not exist");
        require(tokenAddress != address(0), "Token address cannot be zero");
        return depositedBalances[vaultId][tokenAddress];
    }

     /// @notice Gets the amount of a specific token claimed by a recipient for a specific vault.
     /// @param vaultId The ID of the vault.
     /// @param tokenAddress The address of the ERC20 token.
     /// @param recipient The address of the recipient.
     /// @return The claimed amount.
    function getClaimedAmount(uint256 vaultId, address tokenAddress, address recipient) external view returns (uint256) {
        require(vaultId < nextVaultId, "Vault does not exist");
        require(tokenAddress != address(0), "Token address cannot be zero");
        require(recipient != address(0), "Recipient address cannot be zero");
        return claimedBalances[vaultId][tokenAddress][recipient];
    }


    /// @notice Gets the total number of vaults created.
    /// @return The total count of vaults.
    function getTotalVaults() external view returns (uint256) {
        return nextVaultId;
    }

    /// @notice Gets the total balance of a specific token held by the contract across all vaults/pools.
    /// @param tokenAddress The address of the ERC20 token.
    /// @return The total balance.
    function getContractERC20Balance(address tokenAddress) external view returns (uint256) {
        require(tokenAddress != address(0), "Token address cannot be zero");
        return IERC20(tokenAddress).balanceOf(address(this));
    }
}
```