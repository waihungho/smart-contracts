Okay, this is an exciting challenge! Let's design a smart contract concept that incorporates several advanced ideas: conditional release based on multiple factors, integration points for ZK proofs, oracles providing complex data (like simulated quantum randomness or external event outcomes), and dynamic state based on external contract interactions.

Let's call it the "Quantum Entanglement Vault". The core idea is that funds/tokens are locked and can *only* be withdrawn when a set of "entanglement conditions" are met. These conditions can be time-based, oracle-driven, verifiable via ZK proofs, or even depend on the state of other smart contracts. The "quantum entanglement" is a metaphor for the interconnected, multi-factor dependency of the withdrawal state.

---

## Quantum Entanglement Vault Smart Contract

**Concept:** A secure vault allowing users to deposit assets (ETH or ERC20) with complex, multi-factor release conditions. These "entanglement conditions" can include time locks, oracle-reported data points (like simulated quantum randomness or external event outcomes), verification of Zero-Knowledge proofs, or checks on the state of other registered smart contracts.

**Advanced Concepts Used:**
*   **Complex Conditional Logic:** Combining multiple conditions with AND/OR logic (simulated via condition segments).
*   **Oracle Integration:** Relying on trusted external data feeds for non-deterministic or real-world inputs.
*   **Zero-Knowledge Proofs Integration:** Allowing withdrawal based on verifiable off-chain computation/proofs without revealing the underlying data.
*   **Inter-Contract Dependency:** Withdrawal conditions can depend on the state of other contracts (simulating "entanglement").
*   **Role-Based Access Control:** Granular permissions for managing oracles and condition types.
*   **Pausability & Emergency Measures:** Standard safety features for complex contracts.

**Disclaimer:** This is a complex concept designed for illustrative purposes. Implementing such a contract for production requires rigorous security audits, careful oracle management strategies, and robust ZK proof integration mechanisms. The "quantum" aspect is metaphorical, leveraging advanced computational and data concepts.

---

**Outline:**

1.  **Pragma & Imports:** Specify Solidity version and import necessary OpenZeppelin libraries.
2.  **Error Handling:** Define custom errors for clarity.
3.  **Enums:** Define states for deposits, condition types, and condition statuses.
4.  **Structs:** Define data structures for deposits and condition segments.
5.  **State Variables:** Store contract owner, administrators, registered oracles, supported condition types, deposit data, condition data, and fees.
6.  **Events:** Log important actions like deposits, withdrawals, condition updates, oracle registration, etc.
7.  **Modifiers:** Access control modifiers (`onlyOwner`, `onlyAdmin`, `onlyOracle`).
8.  **Constructor:** Initialize the contract with the owner.
9.  **Pausable Functionality:** Implement pausing mechanisms.
10. **Access Control Functions:** Manage owner and administrator roles.
11. **Oracle Management:** Register, deregister, and manage trusted data sources.
12. **Condition Type Management:** Define and manage the types of conditions the vault supports.
13. **Oracle Data Feeding:** Function for registered oracles to provide data updates.
14. **Core Vault Operations:** Deposit ETH and ERC20 tokens.
15. **Entanglement Condition Management:** Define, add, update, and remove conditions linked to a deposit.
16. **Condition Checking Logic:** Internal and external functions to evaluate if conditions are met.
17. **Advanced Condition Implementations:** Specific functions for ZK proof verification results, setting dependent vault addresses, handling random numbers, hash preimages, and external contract state checks.
18. **Withdrawal Function:** Trigger the withdrawal process based on met conditions.
19. **Fee Management:** Set and withdraw protocol fees.
20. **Emergency Functions:** Owner-controlled emergency measures (with caveats).
21. **View Functions:** Retrieve contract state information.

---

**Function Summary (Approx. 25+ functions):**

1.  `constructor()`: Initializes the contract, setting the owner.
2.  `pause()`: Owner pauses core contract operations (deposits, withdrawals).
3.  `unpause()`: Owner unpauses the contract.
4.  `addAdmin(address _admin)`: Owner adds an administrator with limited privileges.
5.  `removeAdmin(address _admin)`: Owner removes an administrator.
6.  `transferOwnership(address newOwner)`: Owner transfers contract ownership.
7.  `registerOracle(address _oracle, string memory _description)`: Owner/Admin registers a trusted oracle address.
8.  `deregisterOracle(address _oracle)`: Owner/Admin deregisters an oracle.
9.  `addSupportedConditionType(bytes32 _type, string memory _description)`: Owner defines a new type of condition the vault can use (e.g., HASH_PREIMAGE, ZK_PROOF_VERIFIED, PRICE_GTE).
10. `removeSupportedConditionType(bytes32 _type)`: Owner removes a supported condition type.
11. `setOracleData(bytes32 _dataType, bytes32 _dataKey, bytes memory _dataValue)`: **Only Oracle** - Pushes data onto the contract (e.g., price for a key, ZK verification result for a key, random number).
12. `depositETH()`: User deposits Ether into the vault, receiving a deposit ID.
13. `depositERC20(address _token, uint256 _amount)`: User deposits ERC20 tokens into the vault.
14. `defineEntanglementConditions(uint256 _depositId, ConditionSegmentInput[] memory _conditions)`: User (depositor) sets the initial array of condition segments for their deposit.
15. `addConditionSegment(uint256 _depositId, ConditionSegmentInput memory _condition)`: User adds a *new* condition segment to an existing deposit's requirement list.
16. `updateConditionSegment(uint256 _depositId, uint256 _conditionSegmentIndex, ConditionSegmentInput memory _newCondition)`: User updates an *existing* condition segment (e.g., changing a target price). May have restrictions.
17. `removeConditionSegment(uint256 _depositId, uint256 _conditionSegmentIndex)`: User removes a condition segment from a deposit's requirement list.
18. `checkEntanglementStatus(uint256 _depositId)`: **View Function** - Evaluates if *all* condition segments for a specific deposit are currently met based on the contract's state and oracle data.
19. `checkConditionSegmentStatus(uint256 _conditionSegmentId)`: **View Function** - Checks the status of a *single* condition segment.
20. `provideZKProofVerificationResult(bytes32 _conditionDataKey, bool _isVerified)`: Allows an authorized ZK Verifier (could be an oracle or special role) to signal that a proof associated with a specific condition key has been verified off-chain. Updates internal state checked by `checkConditionSegmentStatus`.
21. `setDependentVaultAddress(uint256 _conditionSegmentId, address _vaultAddress)`: Allows associating a condition segment (pre-defined type) with another contract address to check its state.
22. `provideHashPreimage(uint256 _conditionSegmentId, bytes memory _preimage)`: User provides the preimage for a `HASH_PREIMAGE` condition type to fulfill it.
23. `triggerWithdrawal(uint256 _depositId)`: User attempts to withdraw their deposit. Calls `checkEntanglementStatus` internally. If true, transfers funds, applies fees, and updates deposit state.
24. `setWithdrawalFee(uint256 _feePercentage)`: Owner sets a percentage-based fee on successful withdrawals.
25. `withdrawFees(address _token)`: Owner withdraws accumulated fees for a specific token (or ETH).
26. `emergencyWithdraw(uint256 _depositId)`: **Owner Only** - Allows the owner to forcefully withdraw a deposit. This should ideally have a timelock or other safeguard in a real system, but included for complexity. May send funds to the owner or back to the depositor depending on policy.
27. `getDepositDetails(uint256 _depositId)`: **View Function** - Get all details about a specific deposit.
28. `getUserDeposits(address _user)`: **View Function** - Get a list of all deposit IDs belonging to a user.
29. `getConditionSegmentDetails(uint256 _conditionSegmentId)`: **View Function** - Get details about a specific condition segment.
30. `getOracleData(bytes32 _dataType, bytes32 _dataKey)`: **View Function** - Retrieve the latest data reported by an oracle for a specific type and key.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @title Quantum Entanglement Vault
/// @author Your Name/Handle (Placeholder)
/// @notice A vault contract allowing users to deposit assets with complex, multi-factor release conditions.
/// These conditions can be time-based, oracle-driven, verifiable via ZK proofs, or depend on the state of other contracts.
/// The "quantum entanglement" is a metaphor for the interconnected, multi-factor dependency of the withdrawal state.
/// Disclaimer: This is a complex concept for illustrative purposes and requires extensive auditing for production use.

// --- Outline ---
// 1. Pragma & Imports
// 2. Error Handling
// 3. Enums
// 4. Structs
// 5. State Variables
// 6. Events
// 7. Modifiers
// 8. Constructor
// 9. Pausable Functionality
// 10. Access Control Functions
// 11. Oracle Management
// 12. Condition Type Management
// 13. Oracle Data Feeding
// 14. Core Vault Operations (Deposit ETH/ERC20)
// 15. Entanglement Condition Management (Define, Add, Update, Remove)
// 16. Condition Checking Logic (Internal/External evaluation)
// 17. Advanced Condition Implementations (ZK Proof, Dependent Vault, Hash Preimage, etc.)
// 18. Withdrawal Function
// 19. Fee Management
// 20. Emergency Functions
// 21. View Functions

// --- Function Summary ---
// 1. constructor() -> Initializes the contract.
// 2. pause() -> Owner pauses core operations.
// 3. unpause() -> Owner unpauses operations.
// 4. addAdmin(address _admin) -> Owner adds an admin.
// 5. removeAdmin(address _admin) -> Owner removes an admin.
// 6. transferOwnership(address newOwner) -> Owner transfers ownership.
// 7. registerOracle(address _oracle, string memory _description) -> Owner/Admin registers an oracle.
// 8. deregisterOracle(address _oracle) -> Owner/Admin deregisters an oracle.
// 9. addSupportedConditionType(bytes32 _type, string memory _description) -> Owner defines a new condition type.
// 10. removeSupportedConditionType(bytes32 _type) -> Owner removes a condition type.
// 11. setOracleData(bytes32 _dataType, bytes32 _dataKey, bytes memory _dataValue) -> Oracle pushes data.
// 12. depositETH() -> User deposits Ether.
// 13. depositERC20(address _token, uint256 _amount) -> User deposits ERC20.
// 14. defineEntanglementConditions(uint256 _depositId, ConditionSegmentInput[] memory _conditions) -> User defines initial conditions.
// 15. addConditionSegment(uint256 _depositId, ConditionSegmentInput memory _condition) -> User adds a condition segment.
// 16. updateConditionSegment(uint256 _depositId, uint256 _conditionSegmentIndex, ConditionSegmentInput memory _newCondition) -> User updates a condition segment.
// 17. removeConditionSegment(uint256 _depositId, uint256 _conditionSegmentIndex) -> User removes a condition segment.
// 18. checkEntanglementStatus(uint256 _depositId) -> View: Checks if all conditions for a deposit are met.
// 19. checkConditionSegmentStatus(uint256 _conditionSegmentId) -> View: Checks status of a single condition segment.
// 20. provideZKProofVerificationResult(bytes32 _conditionDataKey, bool _isVerified) -> Authorized entity signals ZK proof verification status.
// 21. setDependentVaultAddress(uint256 _conditionSegmentId, address _vaultAddress) -> Associates a condition with another contract.
// 22. provideHashPreimage(uint256 _conditionSegmentId, bytes memory _preimage) -> User provides preimage for a hash condition.
// 23. triggerWithdrawal(uint256 _depositId) -> User attempts withdrawal if conditions met.
// 24. setWithdrawalFee(uint256 _feePercentage) -> Owner sets withdrawal fee.
// 25. withdrawFees(address _token) -> Owner withdraws collected fees.
// 26. emergencyWithdraw(uint256 _depositId) -> Owner performs emergency withdrawal.
// 27. getDepositDetails(uint256 _depositId) -> View: Gets details of a deposit.
// 28. getUserDeposits(address _user) -> View: Gets deposit IDs for a user.
// 29. getConditionSegmentDetails(uint256 _conditionSegmentId) -> View: Gets details of a condition segment.
// 30. getOracleData(bytes32 _dataType, bytes32 _dataKey) -> View: Retrieves stored oracle data.

contract QuantumEntanglementVault is Ownable, Pausable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address payable;

    // --- 2. Error Handling ---
    error QEV__DepositNotFound(uint256 depositId);
    error QEV__NotDepositOwner(uint256 depositId);
    error QEV__DepositStateInvalid(uint256 depositId, DepositState expectedState, DepositState currentState);
    error QEV__ConditionSegmentNotFound(uint256 conditionSegmentId);
    error QEV__ConditionSegmentIndexOutOfRange(uint256 depositId, uint256 index);
    error QEV__ConditionTypeNotSupported(bytes32 conditionType);
    error QEV__ConditionParametersMismatch(bytes32 conditionType); // Parameters don't match expected format for type
    error QEV__InvalidOracleAddress(address oracle);
    error QEV__InvalidAdminAddress(address admin);
    error QEV__InvalidOracleDataKey(bytes32 dataKey); // e.g. oracle data for this key not set
    error QEV__InvalidOracleDataType(bytes32 dataType); // e.g. oracle data type not recognized/handled
    error QEV__ConditionNotYetMet(uint256 depositId);
    error QEV__WithdrawalFeeTooHigh(uint256 feePercentage);
    error QEV__ERC20TransferFailed();
    error QEV__ETHTransferFailed();
    error QEV__ConditionSegmentWrongType(uint256 conditionSegmentId, bytes32 expectedType, bytes32 actualType);
    error QEV__PreimageMismatch(uint256 conditionSegmentId);
    error QEV__DependentVaultCheckFailed(uint256 conditionSegmentId);
    error QEV__ZKProofNotVerified(bytes32 conditionDataKey);
    error QEV__AlreadyVerified(bytes32 conditionDataKey);
    error QEV__WithdrawalAlreadyProcessed(uint256 depositId);

    // --- 3. Enums ---
    enum DepositState { Locked, ConditionsMet, Withdrawn, EmergencyWithdrawn }
    enum ConditionStatus { Pending, Met, Failed } // Note: Failed might be used for future extensions like expiring conditions

    // Predefined Condition Types (using bytes32 for efficiency)
    bytes32 public constant CONDITION_TYPE_TIMELOCK = keccak256("TIMELOCK"); // Param: uint256 timestamp
    bytes32 public constant CONDITION_TYPE_PRICE_GTE = keccak256("PRICE_GTE"); // Params: bytes32 assetKey, uint256 targetPrice (scaled), address oracleDataTypeSource
    bytes32 public constant CONDITION_TYPE_EXTERNAL_EVENT = keccak256("EXTERNAL_EVENT"); // Params: bytes32 eventKey, bytes32 expectedValue, address oracleDataTypeSource
    bytes32 public constant CONDITION_TYPE_RANDOM_RANGE = keccak256("RANDOM_RANGE"); // Params: uint256 min, uint256 max, address oracleDataTypeSource
    bytes32 public constant CONDITION_TYPE_ZK_PROOF_VERIFIED = keccak256("ZK_PROOF_VERIFIED"); // Params: bytes32 verificationKey
    bytes32 public constant CONDITION_TYPE_HASH_PREIMAGE = keccak256("HASH_PREIMAGE"); // Params: bytes32 hash
    bytes32 public constant CONDITION_TYPE_DEPENDENT_VAULT_STATE = keccak256("DEPENDENT_VAULT_STATE"); // Params: address dependentVault, bytes4 functionSelector, bytes expectedValue (ABI encoded)
    bytes32 public constant CONDITION_TYPE_ERC721_OWNERSHIP = keccak256("ERC721_OWNERSHIP"); // Params: address nftContract, uint256 tokenId, address requiredOwner (0x0 for depositor)
    bytes32 public constant CONDITION_TYPE_ERC1155_OWNERSHIP = keccak256("ERC1155_OWNERSHIP"); // Params: address nftContract, uint256 tokenId, uint256 requiredAmount, address requiredOwner (0x0 for depositor)

    // --- 4. Structs ---
    struct Deposit {
        address payable depositor;
        address token; // address(0) for ETH
        uint256 amount;
        uint256[] conditionSegmentIds; // List of condition segment IDs that ALL must be met
        DepositState state;
        uint256 depositTime;
    }

    struct ConditionSegment {
        uint256 id;
        uint256 depositId;
        bytes32 conditionType;
        bytes params; // ABI encoded parameters specific to the condition type
        ConditionStatus status;
    }

    struct SupportedCondition {
        bytes32 conditionType;
        string description;
        bool isSupported;
    }

    // Input struct for defining/adding conditions
    struct ConditionSegmentInput {
        bytes32 conditionType;
        bytes params; // ABI encoded parameters
    }

    // --- 5. State Variables ---
    uint256 private _depositCounter;
    mapping(uint256 => Deposit) public deposits;
    mapping(address => uint256[]) private _userDeposits; // Store deposit IDs per user

    uint256 private _conditionSegmentCounter;
    mapping(uint256 => ConditionSegment) public conditionSegments; // Store condition segments globally

    mapping(address => bool) private _admins;
    EnumerableSet.AddressSet private _oracles;

    mapping(bytes32 => SupportedCondition) private _supportedConditions; // Map bytes32 type to details
    EnumerableSet.Bytes32Set private _supportedConditionTypes; // Keep track of active types

    // Oracle Data Storage: dataType => dataKey => dataValue
    // Example: PRICE => ETH_USD => ABI_ENCODED_PRICE
    // Example: ZK_PROOF_VERIFIED => proofHash => ABI_ENCODED_BOOL (true/false)
    // Example: RANDOM_RANGE => requestId => ABI_ENCODED_RANDOM_NUMBER
    mapping(bytes32 => mapping(bytes32 => bytes)) private _oracleData;

    uint256 public withdrawalFeePercentage = 0; // Basis points (e.g., 100 = 1%)
    mapping(address => uint256) public collectedFees; // Token address => amount (address(0) for ETH)

    // Specific state for some condition types
    mapping(bytes32 => bool) private _zkProofVerifiedStatus; // conditionDataKey => isVerified

    // --- 6. Events ---
    event DepositMade(uint256 indexed depositId, address indexed depositor, address indexed token, uint256 amount, uint256 depositTime);
    event ConditionsDefined(uint256 indexed depositId, uint256[] conditionSegmentIds);
    event ConditionSegmentAdded(uint256 indexed depositId, uint256 indexed conditionSegmentId, uint256 index);
    event ConditionSegmentUpdated(uint256 indexed depositId, uint256 indexed conditionSegmentId, uint256 index);
    event ConditionSegmentRemoved(uint256 indexed depositId, uint256 indexed conditionSegmentId, uint256 index);
    event ConditionStatusUpdated(uint256 indexed conditionSegmentId, ConditionStatus newStatus);
    event WithdrawalTriggered(uint256 indexed depositId, address indexed recipient, uint256 amount, uint256 feeAmount);
    event EmergencyWithdrawal(uint256 indexed depositId, address indexed recipient, uint256 amount);
    event OracleRegistered(address indexed oracle, string description);
    event OracleDeregistered(address indexed oracle);
    event SupportedConditionTypeAdded(bytes32 indexed conditionType, string description);
    event SupportedConditionTypeRemoved(bytes32 indexed conditionType);
    event OracleDataReceived(bytes32 indexed dataType, bytes32 indexed dataKey, bytes dataValue);
    event ZKProofVerificationStatus(bytes32 indexed conditionDataKey, bool isVerified);
    event HashPreimageProvided(uint256 indexed conditionSegmentId);
    event WithdrawalFeeSet(uint256 feePercentage);
    event FeesWithdrawn(address indexed token, address indexed recipient, uint256 amount);

    // --- 7. Modifiers ---
    modifier onlyAdmin() {
        if (!_admins[msg.sender] && msg.sender != owner()) {
            revert QEV__InvalidAdminAddress(msg.sender);
        }
        _;
    }

    modifier onlyOracle() {
        if (!_oracles.contains(msg.sender)) {
            revert QEV__InvalidOracleAddress(msg.sender);
        }
        _;
    }

    // --- 8. Constructor ---
    constructor() Ownable(msg.sender) Pausable() {
        _depositCounter = 0;
        _conditionSegmentCounter = 0;

        // Add default supported condition types
        _addSupportedConditionType(CONDITION_TYPE_TIMELOCK, "Requires current timestamp >= target timestamp.");
        _addSupportedConditionType(CONDITION_TYPE_PRICE_GTE, "Requires oracle price data for a key >= target price.");
        _addSupportedConditionType(CONDITION_TYPE_EXTERNAL_EVENT, "Requires oracle event data for a key == expected value.");
        _addSupportedConditionType(CONDITION_TYPE_RANDOM_RANGE, "Requires oracle random number data for a key within min/max range.");
        _addSupportedConditionType(CONDITION_TYPE_ZK_PROOF_VERIFIED, "Requires off-chain ZK proof verification status for a key to be true.");
        _addSupportedConditionType(CONDITION_TYPE_HASH_PREIMAGE, "Requires depositor to reveal preimage of a hash.");
        _addSupportedConditionType(CONDITION_TYPE_DEPENDENT_VAULT_STATE, "Requires calling a view function on another contract and checking its return value.");
        _addSupportedConditionType(CONDITION_TYPE_ERC721_OWNERSHIP, "Requires a specific address to own a specific ERC721 token.");
        _addSupportedConditionType(CONDITION_TYPE_ERC1155_OWNERSHIP, "Requires a specific address to own a specific amount of a specific ERC1155 token.");
    }

    // --- 9. Pausable Functionality ---
    // pause() and unpause() inherited from Pausable.

    // --- 10. Access Control Functions ---
    // transferOwnership() inherited from Ownable.

    /// @notice Allows the owner to add an administrator who can manage oracles and condition types.
    /// @param _admin The address to grant admin privileges.
    function addAdmin(address _admin) public onlyOwner {
        _admins[_admin] = true;
        emit RoleGranted(keccak256("ADMIN"), _admin, msg.sender); // Standard OpenZeppelin RoleGranted event
    }

    /// @notice Allows the owner to remove an administrator.
    /// @param _admin The address to revoke admin privileges from.
    function removeAdmin(address _admin) public onlyOwner {
        _admins[_admin] = false;
        emit RoleRevoked(keccak256("ADMIN"), _admin, msg.sender); // Standard OpenZeppelin RoleRevoked event
    }

    /// @notice Check if an address is an admin or the owner.
    /// @param _address The address to check.
    /// @return True if the address is an admin or the owner.
    function isAdmin(address _address) public view returns (bool) {
        return _admins[_address] || _address == owner();
    }

    // --- 11. Oracle Management ---

    /// @notice Registers a trusted oracle address. Only Owner or Admin can call.
    /// @param _oracle The address of the oracle contract or account.
    /// @param _description A brief description of the oracle's function.
    function registerOracle(address _oracle, string memory _description) public onlyAdmin {
        require(_oracle != address(0), "Zero address not allowed");
        _oracles.add(_oracle);
        emit OracleRegistered(_oracle, _description);
    }

    /// @notice Deregisters an oracle address. Only Owner or Admin can call.
    /// @param _oracle The address of the oracle to deregister.
    function deregisterOracle(address _oracle) public onlyAdmin {
        require(_oracles.contains(_oracle), QEV__InvalidOracleAddress(_oracle));
        _oracles.remove(_oracle);
        emit OracleDeregistered(_oracle);
    }

    /// @notice Check if an address is a registered oracle.
    /// @param _oracle The address to check.
    /// @return True if the address is a registered oracle.
    function isRegisteredOracle(address _oracle) public view returns (bool) {
        return _oracles.contains(_oracle);
    }

    // --- 12. Condition Type Management ---

    /// @notice Adds a new supported condition type that can be used for deposit conditions. Only Owner can call.
    /// @param _type The bytes32 identifier for the condition type.
    /// @param _description A brief description of what this condition type checks.
    function addSupportedConditionType(bytes32 _type, string memory _description) public onlyOwner {
        require(!_supportedConditions[_type].isSupported, "Condition type already supported");
        _addSupportedConditionType(_type, _description);
        emit SupportedConditionTypeAdded(_type, _description);
    }

    // Internal helper for adding supported condition types (used in constructor too)
    function _addSupportedConditionType(bytes32 _type, string memory _description) internal {
         _supportedConditions[_type] = SupportedCondition({
            conditionType: _type,
            description: _description,
            isSupported: true
        });
        _supportedConditionTypes.add(_type);
    }

    /// @notice Removes a supported condition type. Deposits already using this type will still rely on it. Only Owner can call.
    /// @param _type The bytes32 identifier for the condition type to remove.
    function removeSupportedConditionType(bytes32 _type) public onlyOwner {
        require(_supportedConditions[_type].isSupported, QEV__ConditionTypeNotSupported(_type));
        _supportedConditions[_type].isSupported = false; // Mark as unsupported, don't delete config immediately
        _supportedConditionTypes.remove(_type);
        emit SupportedConditionTypeRemoved(_type);
    }

    /// @notice Check if a condition type is supported for *new* conditions.
    /// @param _type The bytes32 identifier for the condition type.
    /// @return True if the condition type is currently supported for new conditions.
    function isConditionTypeSupported(bytes32 _type) public view returns (bool) {
        return _supportedConditions[_type].isSupported;
    }

    /// @notice Get details about a supported condition type.
    /// @param _type The bytes32 identifier.
    /// @return The description and support status.
    function getSupportedConditionTypeDetails(bytes32 _type) public view returns (string memory description, bool isSupported) {
         require(_supportedConditionTypes.contains(_type), QEV__ConditionTypeNotSupported(_type)); // Check if it ever existed
         SupportedCondition storage cond = _supportedConditions[_type];
         return (cond.description, cond.isSupported);
    }

    /// @notice Get the list of all supported condition types.
    /// @return An array of bytes32 identifiers for all supported condition types.
    function getAllSupportedConditionTypes() public view returns (bytes32[] memory) {
        return _supportedConditionTypes.values();
    }

    // --- 13. Oracle Data Feeding ---

    /// @notice Allows a registered oracle to provide data. Data is stored mapping dataType => dataKey => dataValue.
    /// This is a generic interface; specific condition types interpret `_dataType`, `_dataKey`, and `_dataValue`.
    /// @param _dataType A bytes32 identifier for the type of data (e.g., keccak256("PRICE"), keccak256("RANDOMNESS")).
    /// @param _dataKey A bytes32 identifier for the specific data point (e.g., keccak256("ETH_USD"), keccak256("latest_random_seed")).
    /// @param _dataValue The ABI-encoded value of the data.
    function setOracleData(bytes32 _dataType, bytes32 _dataKey, bytes memory _dataValue) public onlyOracle {
        require(_dataKey != bytes32(0), QEV__InvalidOracleDataKey(_dataKey)); // Disallow zero key
        _oracleData[_dataType][_dataKey] = _dataValue;
        emit OracleDataReceived(_dataType, _dataKey, _dataValue);
    }

    /// @notice Allows an authorized ZK Verifier (could be a specific oracle role or separate admin) to signal
    /// that a ZK proof, referenced by `_conditionDataKey`, has been successfully verified off-chain.
    /// This updates the internal state checked by `CONDITION_TYPE_ZK_PROOF_VERIFIED`.
    /// @param _conditionDataKey The bytes32 key referencing the specific proof verification task.
    /// @param _isVerified The verification result (true if valid, false if invalid).
    function provideZKProofVerificationResult(bytes32 _conditionDataKey, bool _isVerified) public onlyOracle { // Could also be onlyAdmin or a specific verifier role
        require(_conditionDataKey != bytes32(0), QEV__InvalidOracleDataKey(_conditionDataKey));
        require(!_zkProofVerifiedStatus[_conditionDataKey], QEV__AlreadyVerified(_conditionDataKey)); // Prevent multiple verifications for the same key (depends on use case)
        _zkProofVerifiedStatus[_conditionDataKey] = _isVerified;
        emit ZKProofVerificationStatus(_conditionDataKey, _isVerified);
    }

    /// @notice Allows a user (or anyone knowing the preimage) to provide the preimage for a HASH_PREIMAGE condition.
    /// This fulfills the condition segment.
    /// @param _conditionSegmentId The ID of the HASH_PREIMAGE condition segment.
    /// @param _preimage The original data that hashes to the stored hash.
    function provideHashPreimage(uint256 _conditionSegmentId, bytes memory _preimage) public nonReentrant {
        ConditionSegment storage condition = conditionSegments[_conditionSegmentId];
        if (condition.id == 0) revert QEV__ConditionSegmentNotFound(_conditionSegmentId); // Check existence
        if (condition.conditionType != CONDITION_TYPE_HASH_PREIMAGE) revert QEV__ConditionSegmentWrongType(_conditionSegmentId, CONDITION_TYPE_HASH_PREIMAGE, condition.conditionType);
        if (condition.status != ConditionStatus.Pending) return; // Already met or failed

        bytes32 storedHash;
        // Decode bytes params: expect bytes32 hash
        (storedHash) = abi.decode(condition.params, (bytes32));

        if (keccak256(_preimage) != storedHash) {
            revert QEV__PreimageMismatch(_conditionSegmentId);
        }

        condition.status = ConditionStatus.Met;
        emit ConditionStatusUpdated(_conditionSegmentId, ConditionStatus.Met);

        // Optional: Automatically check deposit status if this was the last pending condition
        Deposit storage deposit = deposits[condition.depositId];
        if (deposit.state == DepositState.Locked && checkEntanglementStatus(condition.depositId)) {
             deposit.state = DepositState.ConditionsMet;
             emit ConditionStatusUpdated(deposit.depositId, DepositState.ConditionsMet); // Re-emit deposit state change as status update
        }
    }

    // --- 14. Core Vault Operations ---

    /// @notice Deposits Ether into the vault.
    /// @dev Requires conditions to be defined later using defineEntanglementConditions or addConditionSegment.
    function depositETH() public payable whenNotPaused nonReentrant returns (uint256 depositId) {
        require(msg.value > 0, "Cannot deposit 0 ETH");

        _depositCounter++;
        depositId = _depositCounter;

        deposits[depositId] = Deposit({
            depositor: payable(msg.sender),
            token: address(0), // address(0) signifies ETH
            amount: msg.value,
            conditionSegmentIds: new uint256[](0), // Start with no conditions
            state: DepositState.Locked,
            depositTime: block.timestamp
        });

        _userDeposits[msg.sender].push(depositId);

        emit DepositMade(depositId, msg.sender, address(0), msg.value, block.timestamp);
    }

    /// @notice Deposits ERC20 tokens into the vault.
    /// @dev Requires conditions to be defined later. Requires caller to have approved this contract.
    /// @param _token The address of the ERC20 token.
    /// @param _amount The amount of tokens to deposit.
    function depositERC20(address _token, uint256 _amount) public whenNotPaused nonReentrant returns (uint256 depositId) {
        require(_token != address(0), "Cannot deposit from zero address");
        require(_amount > 0, "Cannot deposit 0 tokens");
        require(_token != address(this), "Cannot deposit vault's own tokens"); // Prevent locking vault's balance

        _depositCounter++;
        depositId = _depositCounter;

        // Use transferFrom to pull tokens from the user
        IERC20 tokenContract = IERC20(_token);
        uint256 initialBalance = tokenContract.balanceOf(address(this));
        bool success = tokenContract.transferFrom(msg.sender, address(this), _amount);
        if (!success) revert QEV__ERC20TransferFailed();
        uint256 receivedAmount = tokenContract.balanceOf(address(this)) - initialBalance;
        require(receivedAmount == _amount, QEV__ERC20TransferFailed()); // Check exact amount received

        deposits[depositId] = Deposit({
            depositor: payable(msg.sender),
            token: _token,
            amount: receivedAmount,
            conditionSegmentIds: new uint256[](0),
            state: DepositState.Locked,
            depositTime: block.timestamp
        });

        _userDeposits[msg.sender].push(depositId);

        emit DepositMade(depositId, msg.sender, _token, receivedAmount, block.timestamp);
    }

    // --- 15. Entanglement Condition Management ---

    /// @notice Defines the initial set of entanglement conditions for a deposit. Can only be called once for a deposit.
    /// @param _depositId The ID of the deposit.
    /// @param _conditions An array of condition segments to define.
    function defineEntanglementConditions(uint256 _depositId, ConditionSegmentInput[] memory _conditions) public nonReentrant {
        Deposit storage deposit = deposits[_depositId];
        if (deposit.depositId == 0) revert QEV__DepositNotFound(_depositId);
        if (deposit.depositor != msg.sender) revert QEV__NotDepositOwner(_depositId);
        if (deposit.conditionSegmentIds.length > 0) revert QEV__DepositStateInvalid(_depositId, DepositState.Locked, deposit.state); // Conditions already defined

        uint256[] memory newConditionIds = new uint256[](_conditions.length);
        for (uint i = 0; i < _conditions.length; i++) {
            _conditionSegmentCounter++;
            uint256 segmentId = _conditionSegmentCounter;
            newConditionIds[i] = segmentId;

            // Basic check if type is supported (more detailed validation based on params happens in checkConditionSegmentStatus)
            require(_supportedConditions[_conditions[i].conditionType].isSupported, QEV__ConditionTypeNotSupported(_conditions[i].conditionType));

            conditionSegments[segmentId] = ConditionSegment({
                id: segmentId,
                depositId: _depositId,
                conditionType: _conditions[i].conditionType,
                params: _conditions[i].params,
                status: ConditionStatus.Pending
            });
        }

        deposit.conditionSegmentIds = newConditionIds;
        emit ConditionsDefined(_depositId, newConditionIds);
    }

     /// @notice Adds a new condition segment to an existing deposit's requirements.
     /// @param _depositId The ID of the deposit.
     /// @param _condition The condition segment to add.
    function addConditionSegment(uint256 _depositId, ConditionSegmentInput memory _condition) public nonReentrant {
        Deposit storage deposit = deposits[_depositId];
        if (deposit.depositId == 0) revert QEV__DepositNotFound(_depositId);
        if (deposit.depositor != msg.sender) revert QEV__NotDepositOwner(_depositId);
        // Allow adding conditions even after initial definition

        _conditionSegmentCounter++;
        uint256 segmentId = _conditionSegmentCounter;

         require(_supportedConditions[_condition.conditionType].isSupported, QEV__ConditionTypeNotSupported(_condition.conditionType));

        conditionSegments[segmentId] = ConditionSegment({
            id: segmentId,
            depositId: _depositId,
            conditionType: _condition.conditionType,
            params: _condition.params,
            status: ConditionStatus.Pending
        });

        uint256 newIndex = deposit.conditionSegmentIds.length;
        deposit.conditionSegmentIds.push(segmentId);

        emit ConditionSegmentAdded(_depositId, segmentId, newIndex);

        // Optional: Automatically check deposit status if adding this condition results in all being met
        if (deposit.state == DepositState.Locked && checkEntanglementStatus(_depositId)) {
             deposit.state = DepositState.ConditionsMet;
             emit ConditionStatusUpdated(_depositId, DepositState.ConditionsMet); // Re-emit deposit state change as status update
        }
    }

    /// @notice Updates an existing condition segment for a deposit. May have restrictions based on condition type or state.
    /// @param _depositId The ID of the deposit.
    /// @param _conditionSegmentIndex The index of the condition segment in the deposit's array.
    /// @param _newCondition The updated condition segment data.
    function updateConditionSegment(uint256 _depositId, uint256 _conditionSegmentIndex, ConditionSegmentInput memory _newCondition) public nonReentrant {
        Deposit storage deposit = deposits[_depositId];
        if (deposit.depositId == 0) revert QEV__DepositNotFound(_depositId);
        if (deposit.depositor != msg.sender) revert QEV__NotDepositOwner(_depositId);
        if (_conditionSegmentIndex >= deposit.conditionSegmentIds.length) revert QEV__ConditionSegmentIndexOutOfRange(_depositId, _conditionSegmentIndex);

        uint256 segmentId = deposit.conditionSegmentIds[_conditionSegmentIndex];
        ConditionSegment storage condition = conditionSegments[segmentId];

         require(_supportedConditions[_newCondition.conditionType].isSupported, QEV__ConditionTypeNotSupported(_newCondition.conditionType));

        // Prevent updating once already met (depending on desired logic, might allow minor updates)
        if (condition.status != ConditionStatus.Pending) {
             // Depending on design, maybe only params can be updated if status is Failed?
             revert("Cannot update non-pending condition segment");
        }

        // Note: If the condition type changes, the old condition's status might become irrelevant.
        // This simple implementation just replaces the data. A more robust system might require
        // complex state transitions or disallow type changes.
        condition.conditionType = _newCondition.conditionType;
        condition.params = _newCondition.params;
        condition.status = ConditionStatus.Pending; // Reset status on update

        emit ConditionSegmentUpdated(_depositId, segmentId, _conditionSegmentIndex);

        // Optional: Re-check deposit status
        if (deposit.state == DepositState.Locked && checkEntanglementStatus(_depositId)) {
             deposit.state = DepositState.ConditionsMet;
             emit ConditionStatusUpdated(_depositId, DepositState.ConditionsMet);
        }
    }

    /// @notice Removes a condition segment from a deposit's requirements.
    /// @param _depositId The ID of the deposit.
    /// @param _conditionSegmentIndex The index of the condition segment in the deposit's array.
    function removeConditionSegment(uint256 _depositId, uint256 _conditionSegmentIndex) public nonReentrant {
        Deposit storage deposit = deposits[_depositId];
        if (deposit.depositId == 0) revert QEV__DepositNotFound(_depositId);
        if (deposit.depositor != msg.sender) revert QEV__NotDepositOwner(_depositId);
        if (_conditionSegmentIndex >= deposit.conditionSegmentIds.length) revert QEV__ConditionSegmentIndexOutOfRange(_depositId, _conditionSegmentIndex);

        uint256 segmentIdToRemove = deposit.conditionSegmentIds[_conditionSegmentIndex];

        // Shift elements in the array to remove the element at the index
        for (uint i = _conditionSegmentIndex; i < deposit.conditionSegmentIds.length - 1; i++) {
            deposit.conditionSegmentIds[i] = deposit.conditionSegmentIds[i+1];
        }
        deposit.conditionSegmentIds.pop(); // Remove the last element (which is now a duplicate)

        // Mark the condition segment as removed/inactive internally (optional, could just leave it)
        // For simplicity here, we just remove the reference from the deposit.
        // The conditionSegments mapping still holds the data by ID.

        emit ConditionSegmentRemoved(_depositId, segmentIdToRemove, _conditionSegmentIndex);

        // Optional: Re-check deposit status
        if (deposit.state == DepositState.Locked && checkEntanglementStatus(_depositId)) {
             deposit.state = DepositState.ConditionsMet;
             emit ConditionStatusUpdated(_depositId, DepositState.ConditionsMet);
        }
    }


    // --- 16. Condition Checking Logic ---

    /// @notice Checks if all condition segments for a specific deposit are met.
    /// @dev This is a view function. It does NOT change state (except maybe internal caches depending on implementation).
    /// To trigger state changes based on conditions (like updating a segment's status), use triggerWithdrawal or a dedicated update function.
    /// @param _depositId The ID of the deposit to check.
    /// @return True if ALL associated condition segments are currently met.
    function checkEntanglementStatus(uint256 _depositId) public view returns (bool) {
        Deposit storage deposit = deposits[_depositId];
         // No check for deposit existence needed if accessed internally after validating depositId
        // if (deposit.depositId == 0) revert QEV__DepositNotFound(_depositId); // Only needed for public access

        if (deposit.conditionSegmentIds.length == 0) {
            // If no conditions defined, it's immediately withdrawable (though defineConditions might be required)
            return true;
        }

        bool allMet = true;
        for (uint i = 0; i < deposit.conditionSegmentIds.length; i++) {
            uint256 segmentId = deposit.conditionSegmentIds[i];
            // If any segment is NOT met, the whole entanglement is not met
            if (checkConditionSegmentStatus(segmentId) != ConditionStatus.Met) {
                allMet = false;
                break;
            }
        }
        return allMet;
    }

    /// @notice Checks the status of a single condition segment. This function contains the logic
    /// for interpreting different condition types and their parameters.
    /// @dev This is a view function and relies on stored oracle data, block.timestamp, etc.
    /// It does NOT update the `status` field within the `ConditionSegment` struct.
    /// Call `triggerWithdrawal` or `provide...` functions to trigger status updates.
    /// @param _conditionSegmentId The ID of the condition segment to check.
    /// @return The current status (Pending, Met, Failed) of the condition segment.
    function checkConditionSegmentStatus(uint256 _conditionSegmentId) public view returns (ConditionStatus) {
        ConditionSegment storage condition = conditionSegments[_conditionSegmentId];
        if (condition.id == 0) return ConditionStatus.Failed; // Should not happen if called with valid ID from deposit

        if (condition.status == ConditionStatus.Met) return ConditionStatus.Met; // Once met, always met
        // if (condition.status == ConditionStatus.Failed) return ConditionStatus.Failed; // If a condition can fail permanently

        // Evaluate based on type and parameters
        bytes32 condType = condition.conditionType;
        bytes memory params = condition.params;

        if (condType == CONDITION_TYPE_TIMELOCK) {
            uint256 unlockTimestamp;
            // Decode bytes params: expect uint256 timestamp
            (unlockTimestamp) = abi.decode(params, (uint256));
            return block.timestamp >= unlockTimestamp ? ConditionStatus.Met : ConditionStatus.Pending;

        } else if (condType == CONDITION_TYPE_PRICE_GTE) {
            bytes32 assetKey;
            uint256 targetPrice; // Scaled value
            address oracleDataTypeSource; // The oracle address expected to provide this data type
            // Decode bytes params: expect bytes32 key, uint256 price, address oracleSource
             (assetKey, targetPrice, oracleDataTypeSource) = abi.decode(params, (bytes32, uint256, address));

             // Check if oracle data is available
             bytes memory priceData = _oracleData[keccak256("PRICE")][assetKey];
             if (priceData.length == 0) return ConditionStatus.Pending; // Data not available yet

             uint256 currentPrice;
             // Decode oracle data: expect uint256 price
             (currentPrice) = abi.decode(priceData, (uint256));

             return currentPrice >= targetPrice ? ConditionStatus.Met : ConditionStatus.Pending;

        } else if (condType == CONDITION_TYPE_EXTERNAL_EVENT) {
             bytes32 eventKey;
             bytes32 expectedValue; // Expected value for the event key (e.g., keccak256("ElectionResult"), keccak256("CandidateA_Wins"))
             address oracleDataTypeSource;
             // Decode bytes params: expect bytes32 key, bytes32 value, address oracleSource
             (eventKey, expectedValue, oracleDataTypeSource) = abi.decode(params, (bytes32, bytes32, address));

             // Check if oracle data is available
             bytes memory eventData = _oracleData[keccak256("EVENT")][eventKey];
             if (eventData.length == 0) return ConditionStatus.Pending; // Data not available yet

             bytes32 currentEventValue;
              // Decode oracle data: expect bytes32 value
             (currentEventValue) = abi.decode(eventData, (bytes32));

             return currentEventValue == expectedValue ? ConditionStatus.Met : ConditionStatus.Pending;

        } else if (condType == CONDITION_TYPE_RANDOM_RANGE) {
            uint256 min;
            uint256 max;
            address oracleDataTypeSource; // The oracle address expected to provide randomness
            bytes32 randomKey; // Identifier for the randomness request/value
            // Decode bytes params: expect uint256 min, uint256 max, address oracleSource, bytes32 randomKey
            (min, max, oracleDataTypeSource, randomKey) = abi.decode(params, (uint256, uint256, address, bytes32));

             // Check if oracle data is available
             bytes memory randomData = _oracleData[keccak256("RANDOMNESS")][randomKey];
             if (randomData.length == 0) return ConditionStatus.Pending; // Data not available yet

             uint256 randomNumber;
             // Decode oracle data: expect uint256 random number
             (randomNumber) = abi.decode(randomData, (uint256));

             return (randomNumber >= min && randomNumber <= max) ? ConditionStatus.Met : ConditionStatus.Pending; // Or Failed if it falls outside and should never be met

        } else if (condType == CONDITION_TYPE_ZK_PROOF_VERIFIED) {
            bytes32 verificationKey; // Key provided off-chain to signal verification status
            // Decode bytes params: expect bytes32 verificationKey
            (verificationKey) = abi.decode(params, (bytes32));

            // Check the internal verification status set by provideZKProofVerificationResult
            return _zkProofVerifiedStatus[verificationKey] ? ConditionStatus.Met : ConditionStatus.Pending;

        } else if (condType == CONDITION_TYPE_HASH_PREIMAGE) {
             // Status is updated directly by provideHashPreimage
            return condition.status; // Will be Pending or Met

        } else if (condType == CONDITION_TYPE_DEPENDENT_VAULT_STATE) {
            address dependentVault;
            bytes4 functionSelector; // Selector of the view function to call on the dependent vault
            bytes memory expectedValue; // ABI-encoded expected return value
             // Decode bytes params: expect address vault, bytes4 selector, bytes expected
            (dependentVault, functionSelector, expectedValue) = abi.decode(params, (address, bytes4, bytes));

            (bool success, bytes memory returnData) = dependentVault.staticcall(abi.encodePacked(functionSelector));

            if (!success) {
                // The call failed (e.g., contract doesn't exist, function doesn't exist). Treat as Pending or Failed?
                // Treat as Pending assuming it might become available, or Failed if it indicates a permanent issue.
                // Let's treat as Pending for now.
                return ConditionStatus.Pending;
            }

            // Compare the actual return data with the expected value
            return keccak256(returnData) == keccak256(expectedValue) ? ConditionStatus.Met : ConditionStatus.Pending;

        } else if (condType == CONDITION_TYPE_ERC721_OWNERSHIP) {
             address nftContract;
             uint256 tokenId;
             address requiredOwner; // 0x0 means depositor
             // Decode bytes params: expect address nft, uint256 id, address owner
            (nftContract, tokenId, requiredOwner) = abi.decode(params, (address, uint256, address));

            address ownerToCheck = (requiredOwner == address(0)) ? deposits[condition.depositId].depositor : requiredOwner;

            try IERC721(nftContract).ownerOf(tokenId) returns (address currentOwner) {
                return currentOwner == ownerToCheck ? ConditionStatus.Met : ConditionStatus.Pending;
            } catch {
                 // If the call reverts (e.g., token does not exist), treat as Pending or Failed
                 return ConditionStatus.Pending; // Assuming token might be minted or transferred later
            }

        } else if (condType == CONDITION_TYPE_ERC1155_OWNERSHIP) {
            address nftContract;
            uint256 tokenId;
            uint256 requiredAmount;
            address requiredOwner; // 0x0 means depositor
             // Decode bytes params: expect address nft, uint256 id, uint256 amount, address owner
            (nftContract, tokenId, requiredAmount, requiredOwner) = abi.decode(params, (address, uint256, uint256, address));

             address ownerToCheck = (requiredOwner == address(0)) ? deposits[condition.depositId].depositor : requiredOwner;

             try IERC1155(nftContract).balanceOf(ownerToCheck, tokenId) returns (uint256 currentBalance) {
                 return currentBalance >= requiredAmount ? ConditionStatus.Met : ConditionStatus.Pending;
             } catch {
                 // If the call reverts, treat as Pending or Failed
                 return ConditionStatus.Pending; // Assuming balance might change
             }

        } else {
            // Unknown or unsupported condition type
            return ConditionStatus.Failed; // Or handle this differently
        }
    }


     // --- 17. Advanced Condition Implementations ---
     // Most advanced condition logic is within checkConditionSegmentStatus and dedicated setters like provideZKProofVerificationResult, provideHashPreimage.
     // setDependentVaultAddress is a helper for CONDITION_TYPE_DEPENDENT_VAULT_STATE params.

     /// @notice Helper function to associate a CONDITION_TYPE_DEPENDENT_VAULT_STATE segment with a vault address.
     /// This is just a way to store the address; the actual check happens in checkConditionSegmentStatus.
     /// The params for this condition type should already contain the selector and expected value.
     /// @param _conditionSegmentId The ID of the CONDITION_TYPE_DEPENDENT_VAULT_STATE segment.
     /// @param _vaultAddress The address of the dependent contract.
     function setDependentVaultAddress(uint256 _conditionSegmentId, address _vaultAddress) public nonReentrant {
        // This function assumes the condition segment already exists and is of the correct type,
        // and its params *already* contain placeholders or the full expected data structure
        // *minus* the vault address itself. This is just an example helper to link them post-creation.
        // A real implementation would likely encode the vault address *within* the params during define/add.
        // For simplicity, let's just add a check and assume the params *already* specify the call and expected result.
        // This function's utility is limited without modifying the condition's params, which isn't done here.
        // Let's make this function redundant and require the vault address in the initial params for the condition type.
        // Removing this function as it doesn't add much value without modifying `params`, which is complex.
        // Retaining the concept logic within `checkConditionSegmentStatus`.
        revert("This function is currently disabled. Dependent vault address must be included in condition params.");
     }


    // --- 18. Withdrawal Function ---

    /// @notice Allows a user to withdraw their deposit if all entanglement conditions are met.
    /// Updates the status of conditions and the deposit state.
    /// @param _depositId The ID of the deposit to withdraw.
    function triggerWithdrawal(uint256 _depositId) public nonReentrant whenNotPaused {
        Deposit storage deposit = deposits[_depositId];
        if (deposit.depositId == 0) revert QEV__DepositNotFound(_depositId);
        if (deposit.depositor != msg.sender) revert QEV__NotDepositOwner(_depositId);
        if (deposit.state != DepositState.Locked && deposit.state != DepositState.ConditionsMet) revert QEV__DepositStateInvalid(_depositId, DepositState.Locked, deposit.state); // Can withdraw if Locked (means 0 conditions) or ConditionsMet
        if (deposit.state == DepositState.Withdrawn || deposit.state == DepositState.EmergencyWithdrawn) revert QEV__WithdrawalAlreadyProcessed(_depositId);

        // Re-check and update condition statuses before final check
        bool allConditionsNowMet = true;
        for (uint i = 0; i < deposit.conditionSegmentIds.length; i++) {
             uint256 segmentId = deposit.conditionSegmentIds[i];
             ConditionSegment storage condition = conditionSegments[segmentId];

             // Only check/update status if it's still pending
             if (condition.status == ConditionStatus.Pending) {
                ConditionStatus currentCheckStatus = checkConditionSegmentStatus(segmentId);
                if (currentCheckStatus != ConditionStatus.Pending) { // Status changed from Pending
                    condition.status = currentCheckStatus;
                    emit ConditionStatusUpdated(segmentId, currentCheckStatus);
                }
             }

             if (condition.status != ConditionStatus.Met) {
                 allConditionsNowMet = false;
                 // No need to check others if one is not met
                 break;
             }
        }

        if (!allConditionsNowMet) {
             revert QEV__ConditionNotYetMet(_depositId);
        }

        // If we reach here, all conditions are met (or there were none)
        deposit.state = DepositState.ConditionsMet; // Ensure state is ConditionsMet if withdrawal is possible

        uint256 totalAmount = deposit.amount;
        uint256 feeAmount = (totalAmount * withdrawalFeePercentage) / 10000; // withdrawalFeePercentage is in basis points
        uint256 amountToSend = totalAmount - feeAmount;

        // Transfer funds
        if (deposit.token == address(0)) { // ETH
            (bool success, ) = deposit.depositor.call{value: amountToSend}("");
            if (!success) revert QEV__ETHTransferFailed();
             collectedFees[address(0)] += feeAmount; // Collect ETH fee
        } else { // ERC20
            IERC20 tokenContract = IERC20(deposit.token);
            bool success = tokenContract.transfer(deposit.depositor, amountToSend);
            if (!success) revert QEV__ERC20TransferFailed();
             success = tokenContract.transfer(address(this), feeAmount); // Send fee back to vault address
             if (!success) revert QEV__ERC20TransferFailed(); // Should not fail if previous transfer succeeded
             collectedFees[deposit.token] += feeAmount; // Collect ERC20 fee
        }

        deposit.state = DepositState.Withdrawn;
        emit WithdrawalTriggered(_depositId, deposit.depositor, amountToSend, feeAmount);
    }

    // --- 19. Fee Management ---

    /// @notice Allows the owner to set the withdrawal fee percentage.
    /// @param _feePercentage The fee percentage in basis points (e.g., 100 = 1%). Max 10%.
    function setWithdrawalFee(uint256 _feePercentage) public onlyOwner {
        require(_feePercentage <= 1000, QEV__WithdrawalFeeTooHigh(_feePercentage)); // Max 10%
        withdrawalFeePercentage = _feePercentage;
        emit WithdrawalFeeSet(_feePercentage);
    }

    /// @notice Allows the owner to withdraw collected fees for a specific token or ETH.
    /// @param _token The address of the token to withdraw fees for (address(0) for ETH).
    function withdrawFees(address _token) public onlyOwner nonReentrant {
        uint256 feeAmount = collectedFees[_token];
        require(feeAmount > 0, "No fees collected for this token");

        collectedFees[_token] = 0; // Reset collected fees before transfer

        if (_token == address(0)) { // ETH
            (bool success, ) = payable(owner()).call{value: feeAmount}("");
            if (!success) {
                // If transfer fails, revert and ideally log, but reverting is safer
                collectedFees[_token] = feeAmount; // Restore balance on failure
                revert QEV__ETHTransferFailed();
            }
        } else { // ERC20
            IERC20 tokenContract = IERC20(_token);
            bool success = tokenContract.transfer(owner(), feeAmount);
            if (!success) {
                // If transfer fails, revert
                collectedFees[_token] = feeAmount; // Restore balance on failure
                revert QEV__ERC20TransferFailed();
            }
        }

        emit FeesWithdrawn(_token, owner(), feeAmount);
    }

    // --- 20. Emergency Functions ---

    /// @notice Allows the owner to forcefully withdraw a deposit in case of emergencies.
    /// WARNING: This bypasses all conditions. Should be used with extreme caution and transparency.
    /// Consider adding a timelock or requiring community governance approval in a real system.
    /// @param _depositId The ID of the deposit to emergency withdraw.
    function emergencyWithdraw(uint256 _depositId) public onlyOwner nonReentrant {
         Deposit storage deposit = deposits[_depositId];
        if (deposit.depositId == 0) revert QEV__DepositNotFound(_depositId);
        if (deposit.state == DepositState.Withdrawn || deposit.state == DepositState.EmergencyWithdrawn) revert QEV__WithdrawalAlreadyProcessed(_depositId);

        uint256 totalAmount = deposit.amount;
        // Note: Emergency withdrawal might not incur fees, or has its own fee structure.
        // For simplicity here, no fee on emergency withdrawal.

        // Transfer funds - could send back to depositor or owner depending on policy
        // Sending back to the depositor seems less controversial for a "vault"
        if (deposit.token == address(0)) { // ETH
            (bool success, ) = deposit.depositor.call{value: totalAmount}("");
            if (!success) revert QEV__ETHTransferFailed();
        } else { // ERC20
            IERC20 tokenContract = IERC20(deposit.token);
            bool success = tokenContract.transfer(deposit.depositor, totalAmount);
            if (!success) revert QEV__ERC20TransferFailed();
        }

        deposit.state = DepositState.EmergencyWithdrawn;
        emit EmergencyWithdrawal(_depositId, deposit.depositor, totalAmount);
    }

    // --- 21. View Functions ---

    /// @notice Gets the list of deposit IDs for a specific user.
    /// @param _user The address of the user.
    /// @return An array of deposit IDs.
    function getUserDeposits(address _user) public view returns (uint256[] memory) {
        return _userDeposits[_user];
    }

    /// @notice Get details about a specific deposit.
    /// @param _depositId The ID of the deposit.
    /// @return The deposit struct.
    function getDepositDetails(uint256 _depositId) public view returns (Deposit memory) {
         // Note: Cannot return storage pointer from public view functions
        Deposit storage dep = deposits[_depositId];
        if (dep.depositId == 0) {
             // Return empty/default struct if not found
             return Deposit({
                 depositor: payable(address(0)),
                 token: address(0),
                 amount: 0,
                 conditionSegmentIds: new uint256[](0),
                 state: DepositState.Locked,
                 depositTime: 0
             });
        }
        return dep;
    }

    /// @notice Get details about a specific condition segment.
    /// @param _conditionSegmentId The ID of the condition segment.
    /// @return The condition segment struct.
    function getConditionSegmentDetails(uint256 _conditionSegmentId) public view returns (ConditionSegment memory) {
         ConditionSegment storage cond = conditionSegments[_conditionSegmentId];
          if (cond.id == 0) {
             // Return empty/default struct if not found
             return ConditionSegment({
                 id: 0,
                 depositId: 0,
                 conditionType: bytes32(0),
                 params: "",
                 status: ConditionStatus.Pending
             });
          }
         return cond;
    }

     /// @notice Retrieves the latest data reported by an oracle for a specific type and key.
     /// @param _dataType The bytes32 identifier for the data type.
     /// @param _dataKey The bytes32 identifier for the specific data point.
     /// @return The ABI-encoded data value. Returns empty bytes if data is not found.
    function getOracleData(bytes32 _dataType, bytes32 _dataKey) public view returns (bytes memory) {
        return _oracleData[_dataType][_dataKey];
    }

    /// @notice Gets the current ZK proof verification status for a specific key.
    /// @param _conditionDataKey The bytes32 key referencing the verification task.
    /// @return True if the proof has been marked as verified, false otherwise.
    function getZKProofVerificationStatus(bytes32 _conditionDataKey) public view returns (bool) {
        return _zkProofVerifiedStatus[_conditionDataKey];
    }
}

// Dummy interfaces for demonstration
interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface IERC1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);
}
```