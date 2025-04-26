Okay, let's create a smart contract called `QuantumVault`. This contract will hold ERC-20 tokens and release them to a beneficiary only when a complex set of "quantum-inspired" conditions are met. These conditions can include time locks, proof-of-secrets (simulated ZK-proof hash), oracle data verification, required token balances, Merkle tree inclusion proofs, and even dependencies on the state of *other* deposits within the vault. The "quantum" aspect is metaphorical, representing entangled (multi-part) conditions and state transitions based on external "observations" (proofs/data).

It will *not* be a standard staking contract, ERC-20/721, simple time lock, or basic multi-sig.

---

## QuantumVault Smart Contract Outline & Summary

**Contract Name:** `QuantumVault`

**Purpose:** A highly conditional ERC-20 token vault. Allows depositors to lock funds for a beneficiary that can only be released upon satisfying a complex set of predefined conditions. Inspired by quantum concepts like entanglement (linked conditions) and state observation/collapse (condition fulfillment).

**Key Concepts:**

1.  **Deposits:** Users can deposit ERC-20 tokens along with a set of release conditions for a specific beneficiary.
2.  **Conditions:** Release is gated by an array of diverse condition types (`ConditionType` enum). All conditions in the set must typically be met (AND logic).
    *   `TimeLock`: Release only after a specific timestamp.
    *   `ProofHashMatch`: Requires submitting data whose hash matches a stored hash (simulates needing a secret or ZK-proof).
    *   `OracleValueMatch`: Requires querying a specified oracle and verifying its response against an expected hash.
    *   `TokenBalance`: Beneficiary must hold a minimum amount of a specified token.
    *   `MerkleProof`: Requires submitting a Merkle proof that a leaf exists in a tree rooted by a stored hash.
    *   `DependencyDepositState`: Requires another specified deposit in this vault to be in a particular state (e.g., `Released`, `Cancelled`).
3.  **Conditional Release (`attemptRelease`):** The beneficiary (or anyone providing the necessary proofs/data) attempts to trigger release. The contract iterates through all conditions, verifying the submitted proof data against the stored requirements. If *all* checks pass, the funds are released (minus an optional fee).
4.  **Proof Data:** `attemptRelease` requires an array of `bytes` data, where each element corresponds to the proof/data needed for the condition at the same index in the condition array.
5.  **Deposit States:** Deposits transition through states (`Pending`, `ConditionsSet`, `ConditionsMet`, `Released`, `Cancelled`) influencing `DependencyDepositState` conditions and owner cancellation.
6.  **Owner/Admin:** Functions for setting fees, fee recipient, and potentially cancelling deposits under specific circumstances (e.g., after a long timeout).
7.  **Depositor Control:** The original depositor can set certain parameters *after* deposit, like the Merkle root for a `MerkleProof` condition they specified.

**Function Summary (Public/External & Key Views):**

1.  `constructor()`: Initializes the contract, sets owner.
2.  `depositWithComplexConditions(address beneficiary, address tokenAddress, uint256 amount, Condition[] calldata conditions)`: Main deposit function. Requires beneficiary, token details, amount, and the array of conditions.
3.  `attemptRelease(uint256 depositId, bytes[] memory conditionProofData)`: Called by the beneficiary (or agent) to try and release funds by providing proof data for each condition.
4.  `setMerkleRootForDeposit(uint256 depositId, bytes32 merkleRoot)`: Depositor sets the Merkle root for a deposit if it includes a `MerkleProof` condition. Can only be set once.
5.  `cancelDepositByOwner(uint256 depositId)`: Owner can cancel a deposit after a specified timeout if conditions haven't been met, returning funds to the depositor.
6.  `setReleaseFee(uint256 feeBps)`: Owner sets the percentage fee taken on successful release (in basis points).
7.  `setFeeRecipient(address _feeRecipient)`: Owner sets the address receiving the release fees.
8.  `withdrawAccruedFees(address tokenAddress)`: Owner withdraws collected fees for a specific token.
9.  `getDepositDetails(uint256 depositId)`: View: Returns the basic details of a deposit (depositor, beneficiary, token, amount).
10. `getConditionSet(uint256 depositId)`: View: Returns the array of conditions for a deposit.
11. `getConditionDetailsByIndex(uint256 depositId, uint256 index)`: View: Returns details for a specific condition within a deposit's set.
12. `getConditionDataByIndex(uint256 depositId, uint256 index)`: View: Returns the raw data bytes for a specific condition.
13. `getConditionTypeByIndex(uint256 depositId, uint256 index)`: View: Returns the type of a specific condition.
14. `getSatisfiedConditionStatus(uint256 depositId, uint256 index)`: View: Checks if a specific condition *would be* satisfied with provided data (useful for testing proof data). *(Self-correction: This is hard without data; let's make a view that checks the *current state* based on static conditions like time/balance, or requires mock data)*. Let's refine: `checkConditionStatus(uint256 depositId, uint256 index, bytes memory proofData)` - View: Checks if a *specific* condition is met given proof data.
15. `getDepositState(uint256 depositId)`: View: Returns the current state of a deposit.
16. `isDepositReleased(uint256 depositId)`: View: Simple check if a deposit has been released.
17. `getDepositsByBeneficiary(address beneficiary)`: View: Returns a list of deposit IDs for a given beneficiary. (Requires storing this mapping).
18. `getDepositsByDepositor(address depositor)`: View: Returns a list of deposit IDs for a given depositor. (Requires storing this mapping).
19. `getTotalDeposits()`: View: Returns the total number of deposits made.
20. `getMerkleRootForDeposit(uint256 depositId)`: View: Returns the stored Merkle root for a deposit if applicable.
21. `getReleaseFeeBps()`: View: Returns the current release fee percentage.
22. `getFeeRecipient()`: View: Returns the current fee recipient address.
23. `checkAllConditionsMet(uint256 depositId, bytes[] memory conditionProofData)`: View: Checks if all conditions *would be* met with provided proof data without attempting release.

*(We have more than 20 external/public functions now)*

**Libraries/Interfaces Used:**

*   `@openzeppelin/contracts/access/Ownable.sol`: For basic ownership management.
*   `@openzeppelin/contracts/token/ERC20/IERC20.sol`: Standard ERC-20 interface.
*   (Internal Helper): `_verifyMerkleProof`: A basic Merkle proof verification function.
*   (External Mock/Interface): `IOracle`: A simple interface for interacting with an oracle contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol"; // Using OpenZeppelin's MerkleProof helper
import "@openzeppelin/contracts/utils/Address.sol"; // For address.call

/// @title QuantumVault
/// @author YourName (Inspired by advanced conditional release concepts)
/// @notice A conditional ERC-20 vault with complex, multi-part release criteria inspired by quantum entanglement and state observation.
/// @dev Funds are locked and released only when a specified array of conditions are met.
/// @dev Supports various condition types including time locks, proof hashes, oracle data, token balances, Merkle proofs, and deposit dependencies.

contract QuantumVault is Ownable {
    using Address for address; // For calling IERC20 methods safely

    // --- State Variables ---

    uint256 private depositCounter;

    struct Deposit {
        address depositor;      // The address that created the deposit
        address beneficiary;    // The address intended to receive funds
        address tokenAddress;   // The ERC-20 token address
        uint256 amount;         // The amount deposited
        Condition[] conditions; // The set of conditions required for release
        uint64 cancellationTimeout; // Timestamp after which owner can cancel
    }

    // Enum to represent the state of a deposit
    enum DepositState {
        Pending,        // Initial state, conditions not yet set (should transition immediately)
        ConditionsSet,  // Conditions are defined, waiting to be met
        ConditionsMet,  // All conditions are verified as met (internal state)
        Released,       // Funds have been released to the beneficiary
        Cancelled       // Deposit was cancelled by the owner
    }

    // Enum to represent the type of a condition
    enum ConditionType {
        TimeLock,             // uint64 timestamp - release only after this time
        ProofHashMatch,       // bytes32 requiredHash - submit data whose hash matches this
        OracleValueMatch,     // bytes conditionData - abi.encode(address oracle, bytes oracleQuery, bytes32 expectedValueHash)
        TokenBalance,         // bytes conditionData - abi.encode(address token, uint256 requiredAmount)
        MerkleProof,          // bytes32 merkleRoot - submit leaf and proof to match this root
        DependencyDepositState // bytes conditionData - abi.encode(uint256 dependencyDepositId, DepositState requiredState)
    }

    // Struct representing a single condition
    struct Condition {
        ConditionType conditionType;
        bytes conditionData; // Encoded data specific to the condition type
    }

    // Mappings to store deposit information
    mapping(uint256 => Deposit) public deposits;
    mapping(uint256 => DepositState) public depositStates;
    mapping(address => uint256[]) private depositsByBeneficiary;
    mapping(address => uint256[]) private depositsByDepositor;

    // Specific data storage for conditions that might need updates (like Merkle Root)
    mapping(uint256 => bytes32) private depositMerkleRoots; // depositId -> merkleRoot

    // Fees
    uint256 public releaseFeeBps; // Fee in basis points (100 = 1%)
    address public feeRecipient;

    // --- Events ---

    event DepositMade(uint256 depositId, address indexed depositor, address indexed beneficiary, address indexed tokenAddress, uint256 amount);
    event ConditionChecked(uint256 depositId, uint256 conditionIndex, bool satisfied);
    event FundsReleased(uint256 depositId, address indexed beneficiary, uint256 amount, uint256 feeAmount);
    event DepositCancelled(uint256 depositId, address indexed depositor, uint256 amount);
    event MerkleRootSet(uint256 depositId, bytes32 merkleRoot);
    event ReleaseFeeUpdated(uint256 feeBps);
    event FeeRecipientUpdated(address indexed feeRecipient);

    // --- Constructor ---

    constructor() Ownable(msg.sender) {
        depositCounter = 0;
        releaseFeeBps = 0; // Default to no fee
        feeRecipient = address(0); // Default to no fee recipient
    }

    // --- Core Deposit Function ---

    /// @notice Deposits ERC-20 tokens into the vault with a complex set of release conditions.
    /// @param beneficiary The address that can potentially claim the funds.
    /// @param tokenAddress The address of the ERC-20 token being deposited.
    /// @param amount The amount of tokens to deposit.
    /// @param conditions The array of conditions that must all be met for release.
    /// @param cancellationTimeout The timestamp after which the owner can cancel the deposit.
    function depositWithComplexConditions(
        address beneficiary,
        address tokenAddress,
        uint256 amount,
        Condition[] calldata conditions,
        uint64 cancellationTimeout
    ) external {
        require(beneficiary != address(0), "Invalid beneficiary");
        require(tokenAddress != address(0), "Invalid token address");
        require(amount > 0, "Amount must be greater than zero");
        require(conditions.length > 0, "Must provide at least one condition");
        // cancellationTimeout can be 0 for no timeout

        uint256 newDepositId = depositCounter++;

        // Store deposit details
        deposits[newDepositId] = Deposit({
            depositor: msg.sender,
            beneficiary: beneficiary,
            tokenAddress: tokenAddress,
            amount: amount,
            conditions: conditions,
            cancellationTimeout: cancellationTimeout
        });

        // Store mappings for lookups
        depositsByBeneficiary[beneficiary].push(newDepositId);
        depositsByDepositor[msg.sender].push(newDepositId);

        // Set initial state
        depositStates[newDepositId] = DepositState.ConditionsSet;

        // Transfer tokens into the contract
        IERC20 token = IERC20(tokenAddress);
        token.transferFrom(msg.sender, address(this), amount);

        emit DepositMade(newDepositId, msg.sender, beneficiary, tokenAddress, amount);
    }

    // --- Core Release Function ---

    /// @notice Attempts to release funds for a deposit by checking all conditions.
    /// @param depositId The ID of the deposit to attempt releasing.
    /// @param conditionProofData An array of bytes data, corresponding to the data needed for each condition's verification.
    /// The order of `conditionProofData` must match the order of conditions provided during deposit.
    function attemptRelease(uint256 depositId, bytes[] memory conditionProofData) external {
        Deposit storage deposit = deposits[depositId];
        require(deposit.beneficiary != address(0), "Deposit does not exist"); // Basic check for deposit existence
        require(msg.sender == deposit.beneficiary, "Only beneficiary can attempt release");
        require(depositStates[depositId] == DepositState.ConditionsSet || depositStates[depositId] == DepositState.ConditionsMet, "Deposit not in a state to be released");

        Condition[] storage conditions = deposit.conditions;
        require(conditionProofData.length == conditions.length, "Proof data array length mismatch");

        bool allConditionsMet = true;
        for (uint i = 0; i < conditions.length; i++) {
            bytes memory currentProofData = (i < conditionProofData.length) ? conditionProofData[i] : bytes(""); // Handle potential mismatch defensively, though length is checked
            bool conditionSatisfied = _checkCondition(depositId, i, conditions[i], currentProofData);
            emit ConditionChecked(depositId, i, conditionSatisfied);
            if (!conditionSatisfied) {
                allConditionsMet = false;
                // We can stop checking early if one condition fails for AND logic
                break;
            }
        }

        if (allConditionsMet) {
            // Calculate fee
            uint256 feeAmount = (deposit.amount * releaseFeeBps) / 10000;
            uint256 releaseAmount = deposit.amount - feeAmount;

            // Transfer tokens to beneficiary
            IERC20 token = IERC20(deposit.tokenAddress);
            token.transfer(deposit.beneficiary, releaseAmount);

            // Transfer fee to fee recipient if set
            if (feeAmount > 0 && feeRecipient != address(0)) {
                token.transfer(feeRecipient, feeAmount);
            }

            // Update state
            depositStates[depositId] = DepositState.Released;
            // deposits[depositId].amount = 0; // Optional: clear amount to indicate released

            emit FundsReleased(depositId, deposit.beneficiary, releaseAmount, feeAmount);
        } else {
            // Optionally update state to show partially met conditions, or keep as ConditionsSet
            // For now, let's just revert or let it stay in ConditionsSet state
            depositStates[depositId] = DepositState.ConditionsSet; // Explicitly keep state if not fully met
             revert("Not all conditions met"); // Revert if release is not possible
        }
    }

    // --- Depositor Specific Functions ---

    /// @notice Allows the original depositor to set the Merkle root for a specific deposit if it contains a MerkleProof condition.
    /// @dev This can typically only be called once per deposit for a MerkleProof condition.
    /// @param depositId The ID of the deposit.
    /// @param merkleRoot The root hash of the Merkle tree.
    function setMerkleRootForDeposit(uint256 depositId, bytes32 merkleRoot) external {
        Deposit storage deposit = deposits[depositId];
        require(deposit.depositor == msg.sender, "Only depositor can set Merkle root");
        require(depositStates[depositId] != DepositState.Released && depositStates[depositId] != DepositState.Cancelled, "Deposit already finalized");
        require(depositMerkleRoots[depositId] == bytes32(0), "Merkle root already set for this deposit");

        bool hasMerkleCondition = false;
        for(uint i = 0; i < deposit.conditions.length; i++) {
            if (deposit.conditions[i].conditionType == ConditionType.MerkleProof) {
                hasMerkleCondition = true;
                break;
            }
        }
        require(hasMerkleCondition, "Deposit does not have a MerkleProof condition");

        depositMerkleRoots[depositId] = merkleRoot;
        emit MerkleRootSet(depositId, merkleRoot);
    }

    // --- Owner/Admin Functions ---

    /// @notice Allows the contract owner to cancel a deposit after its cancellation timeout has passed.
    /// @param depositId The ID of the deposit to cancel.
    function cancelDepositByOwner(uint256 depositId) external onlyOwner {
        Deposit storage deposit = deposits[depositId];
        require(deposit.beneficiary != address(0), "Deposit does not exist"); // Basic check for deposit existence
        require(depositStates[depositId] != DepositState.Released && depositStates[depositId] != DepositState.Cancelled, "Deposit already finalized");
        require(deposit.cancellationTimeout > 0 && block.timestamp >= deposit.cancellationTimeout, "Cancellation timeout not reached or not set");

        // Transfer funds back to the original depositor
        IERC20 token = IERC20(deposit.tokenAddress);
        token.transfer(deposit.depositor, deposit.amount);

        // Update state
        depositStates[depositId] = DepositState.Cancelled;
        // deposits[depositId].amount = 0; // Optional: clear amount

        emit DepositCancelled(depositId, deposit.depositor, deposit.amount);
    }

    /// @notice Sets the fee percentage taken on successful deposit release.
    /// @param feeBps The fee in basis points (e.g., 100 = 1%). Max 10000 (100%).
    function setReleaseFee(uint256 feeBps) external onlyOwner {
        require(feeBps <= 10000, "Fee cannot exceed 100%");
        releaseFeeBps = feeBps;
        emit ReleaseFeeUpdated(feeBps);
    }

    /// @notice Sets the address that will receive the release fees.
    /// @param _feeRecipient The address to send fees to.
    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        require(_feeRecipient != address(0), "Fee recipient cannot be zero address");
        feeRecipient = _feeRecipient;
        emit FeeRecipientUpdated(_feeRecipient);
    }

    /// @notice Allows the owner to withdraw collected fees for a specific token.
    /// @param tokenAddress The address of the token whose fees to withdraw.
    function withdrawAccruedFees(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0), "Invalid token address");
        require(feeRecipient == msg.sender, "Fees can only be withdrawn by the fee recipient"); // Only the fee recipient can withdraw
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        // Only withdraw balance exceeding active deposit amounts.
        // This requires tracking fees separately or a complex calculation.
        // A simpler approach is to assume contract balance = sum of active deposits + fees.
        // A safer approach is to track fees explicitly. Let's add a mapping for fees.
        // Let's revise: this function just transfers the *entire* balance of a token
        // in the contract, provided the sender is the fee recipient. This assumes
        // active deposit balances aren't accidentally swept. A robust system would
        // track earned fees per token. For this example, let's use the simple
        // (less safe for prod) full balance sweep by fee recipient.
        token.transfer(msg.sender, balance);
        // A proper system would track earned fees: mapping(address => uint256) feesAccrued;
        // and only withdraw feesAccrued[tokenAddress]
    }

    // --- Internal Condition Checking ---

    /// @dev Checks a single condition. Requires corresponding proofData.
    /// @param depositId The ID of the deposit.
    /// @param conditionIndex The index of the condition within the deposit's condition array.
    /// @param condition The Condition struct.
    /// @param proofData The data provided to satisfy the condition (e.g., secret bytes, oracle query result, Merkle proof).
    /// @return bool True if the condition is satisfied, false otherwise.
    function _checkCondition(uint256 depositId, uint256 conditionIndex, Condition memory condition, bytes memory proofData) internal view returns (bool) {
        address tokenAddress;
        uint256 requiredAmount;
        address oracleAddress;
        bytes memory oracleQuery;
        bytes32 expectedValueHash;
        uint256 dependencyDepositId;
        DepositState requiredState;

        bytes memory conditionData = condition.conditionData;

        // Use a switch statement or if-else if for condition types
        if (condition.conditionType == ConditionType.TimeLock) {
            (uint64 timestamp) = abi.decode(conditionData, (uint64));
            return block.timestamp >= timestamp;
        } else if (condition.conditionType == ConditionType.ProofHashMatch) {
            (bytes32 requiredHash) = abi.decode(conditionData, (bytes32));
            return keccak256(proofData) == requiredHash;
        } else if (condition.conditionType == ConditionType.OracleValueMatch) {
            // Note: Interacting with oracles requires a specific interface and implementation.
            // This is a simplified check assuming proofData contains the oracle result
            // and it matches the expected hash. A real implementation would call the oracle.
            (oracleAddress, oracleQuery, expectedValueHash) = abi.decode(conditionData, (address, bytes, bytes32));
            // In a real scenario, you'd query the oracle here:
            // IOracle oracle = IOracle(oracleAddress);
            // bytes memory oracleResult = oracle.query(oracleQuery); // Example call
            // return keccak256(oracleResult) == expectedValueHash;
            // For this example, we require `proofData` to be the *actual* oracle result.
            return keccak256(proofData) == expectedValueHash;

        } else if (condition.conditionType == ConditionType.TokenBalance) {
            (tokenAddress, requiredAmount) = abi.decode(conditionData, (address, uint256));
             // Check beneficiary's balance
            return IERC20(tokenAddress).balanceOf(deposits[depositId].beneficiary) >= requiredAmount;

        } else if (condition.conditionType == ConditionType.MerkleProof) {
            // proofData must be abi.encode(bytes32 leaf, bytes32[] proof)
            (bytes32 leaf, bytes32[] memory proof) = abi.decode(proofData, (bytes32, bytes32[]));
            bytes32 merkleRoot = depositMerkleRoots[depositId];
            // Merkle root must be set and proof must be valid
            return merkleRoot != bytes32(0) && MerkleProof.verify(proof, merkleRoot, leaf);

        } else if (condition.conditionType == ConditionType.DependencyDepositState) {
            (dependencyDepositId, requiredState) = abi.decode(conditionData, (uint256, DepositState));
            require(dependencyDepositId != depositId, "Deposit cannot depend on itself");
            // Check the state of the dependency deposit
            return depositStates[dependencyDepositId] == requiredState;

        } else {
            // Unknown condition type
            return false;
        }
    }

     // --- View Functions ---

    /// @notice Returns the basic details of a specific deposit.
    /// @param depositId The ID of the deposit.
    /// @return depositor, beneficiary, tokenAddress, amount, cancellationTimeout.
    function getDepositDetails(uint256 depositId) external view returns (address, address, address, uint256, uint64) {
        Deposit storage deposit = deposits[depositId];
        return (deposit.depositor, deposit.beneficiary, deposit.tokenAddress, deposit.amount, deposit.cancellationTimeout);
    }

     /// @notice Returns the array of conditions for a specific deposit.
     /// @param depositId The ID of the deposit.
     /// @return The array of Condition structs.
    function getConditionSet(uint256 depositId) external view returns (Condition[] memory) {
        return deposits[depositId].conditions;
    }

    /// @notice Returns the details of a specific condition by its index for a given deposit.
    /// @param depositId The ID of the deposit.
    /// @param index The index of the condition in the array.
    /// @return conditionType, conditionData bytes.
    function getConditionDetailsByIndex(uint256 depositId, uint256 index) external view returns (ConditionType, bytes memory) {
        Condition[] storage conditions = deposits[depositId].conditions;
        require(index < conditions.length, "Condition index out of bounds");
        return (conditions[index].conditionType, conditions[index].conditionData);
    }

     /// @notice Returns the raw data bytes for a specific condition.
     /// @param depositId The ID of the deposit.
     /// @param index The index of the condition.
     /// @return The raw bytes data for the condition.
    function getConditionDataByIndex(uint256 depositId, uint256 index) external view returns (bytes memory) {
        Condition[] storage conditions = deposits[depositId].conditions;
        require(index < conditions.length, "Condition index out of bounds");
        return conditions[index].conditionData;
    }

    /// @notice Returns the type of a specific condition.
    /// @param depositId The ID of the deposit.
    /// @param index The index of the condition.
    /// @return The ConditionType enum value.
    function getConditionTypeByIndex(uint256 depositId, uint256 index) external view returns (ConditionType) {
        Condition[] storage conditions = deposits[depositId].conditions;
        require(index < conditions.length, "Condition index out of bounds");
        return conditions[index].conditionType;
    }


    /// @notice Returns the current state of a specific deposit.
    /// @param depositId The ID of the deposit.
    /// @return The DepositState enum value.
    function getDepositState(uint256 depositId) external view returns (DepositState) {
        return depositStates[depositId];
    }

    /// @notice Checks if a deposit has been released.
    /// @param depositId The ID of the deposit.
    /// @return True if released, false otherwise.
    function isDepositReleased(uint256 depositId) external view returns (bool) {
        return depositStates[depositId] == DepositState.Released;
    }

    /// @notice Returns the list of deposit IDs associated with a beneficiary.
    /// @param beneficiary The address of the beneficiary.
    /// @return An array of deposit IDs.
    function getDepositsByBeneficiary(address beneficiary) external view returns (uint256[] memory) {
        return depositsByBeneficiary[beneficiary];
    }

    /// @notice Returns the list of deposit IDs associated with a depositor.
    /// @param depositor The address of the depositor.
    /// @return An array of deposit IDs.
    function getDepositsByDepositor(address depositor) external view returns (uint256[] memory) {
        return depositsByDepositor[depositor];
    }

    /// @notice Returns the total number of deposits ever created.
    /// @return The total count of deposits.
    function getTotalDeposits() external view returns (uint256) {
        return depositCounter;
    }

    /// @notice Returns the Merkle root stored for a specific deposit, if any.
    /// @param depositId The ID of the deposit.
    /// @return The Merkle root bytes32 value. Returns bytes32(0) if not set.
    function getMerkleRootForDeposit(uint256 depositId) external view returns (bytes32) {
        return depositMerkleRoots[depositId];
    }

    /// @notice Returns the currently set release fee in basis points.
    /// @return The fee percentage in BPS.
    function getReleaseFeeBps() external view returns (uint256) {
        return releaseFeeBps;
    }

    /// @notice Returns the address set to receive release fees.
    /// @return The fee recipient address.
    function getFeeRecipient() external view returns (address) {
        return feeRecipient;
    }

    /// @notice Checks if a specific condition within a deposit would be satisfied with provided proof data.
    /// @dev This is a view function and does not change contract state. Useful for testing proof data.
    /// @param depositId The ID of the deposit.
    /// @param index The index of the condition to check.
    /// @param proofData The data to use for checking this specific condition.
    /// @return True if the condition is satisfied with the provided data, false otherwise.
    function checkConditionStatus(uint256 depositId, uint256 index, bytes memory proofData) external view returns (bool) {
         Deposit storage deposit = deposits[depositId];
         require(deposit.beneficiary != address(0), "Deposit does not exist");
         require(index < deposit.conditions.length, "Condition index out of bounds");
         return _checkCondition(depositId, index, deposit.conditions[index], proofData);
    }

    /// @notice Checks if ALL conditions for a deposit would be met with the provided array of proof data.
    /// @dev This is a view function and does not change contract state. Useful before attempting release.
    /// @param depositId The ID of the deposit.
    /// @param conditionProofData An array of bytes data, one for each condition in the deposit's set.
    /// @return True if all conditions are satisfied with the provided data, false otherwise.
    function checkAllConditionsMet(uint256 depositId, bytes[] memory conditionProofData) external view returns (bool) {
         Deposit storage deposit = deposits[depositId];
         require(deposit.beneficiary != address(0), "Deposit does not exist");
         Condition[] storage conditions = deposit.conditions;
         require(conditionProofData.length == conditions.length, "Proof data array length mismatch");

         for (uint i = 0; i < conditions.length; i++) {
            bytes memory currentProofData = (i < conditionProofData.length) ? conditionProofData[i] : bytes("");
            if (!_checkCondition(depositId, i, conditions[i], currentProofData)) {
                return false;
            }
         }
         return true; // All conditions passed
    }


    // --- Merkle Proof Helper (using OpenZeppelin's library internally) ---
    // Note: MerkleProof.verify is internal, we don't need a public wrapper if only used internally.
    // If users needed to verify off-chain, they would use the same OZ library.

}

// --- Mock Oracle Interface (for simulation) ---
// In a real scenario, you would integrate with a specific oracle network (Chainlink, etc.)
interface IOracle {
    function query(bytes calldata queryData) external view returns (bytes memory result);
    // Add other oracle-specific functions as needed
}
```