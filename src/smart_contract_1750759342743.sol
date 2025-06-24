Okay, let's design a smart contract that embodies some advanced, creative, and trendy concepts without directly duplicating standard open-source implementations like ERC-20, ERC-721, basic DAOs, or simple escrow systems.

We'll create a "Quantum Vault" contract. The core idea is a vault capable of holding various assets (ETH, ERC-20, ERC-721) where the unlock conditions are dynamic, potentially probabilistic, dependent on external factors (simulated oracles), internal state, and even require simulated proofs of off-chain computation. It will also feature dynamic access control via unique, non-transferable "Access Shards" (simulated ERC-1155) and dynamic fees.

---

**Outline and Function Summary: QuantumVault**

This contract acts as a multi-asset vault (ETH, ERC-20, ERC-721) with complex, dynamic, and multi-faceted unlock conditions. Access to deposited assets is governed by a combination of time, external data (simulated oracles), internal state (puzzles), probabilistic outcomes, and requiring simulated zero-knowledge proofs. It utilizes role-based access control and issues unique "Access Shards" (ERC-1155-like) representing conditional access rights. Dynamic fees are applied to operations.

**Key Concepts:**

1.  **Multi-Asset Holding:** Can receive and track ETH, various ERC-20, and various ERC-721 tokens.
2.  **Dynamic Unlock Conditions:** A flexible system to add, update, and check multiple conditions that must ALL be met for withdrawal.
3.  **Condition Types:** Includes time locks, external data requirements (simulated oracles), internal state puzzles, probabilistic checks, and simulated proof verification.
4.  **Simulated Advanced Features:** Oracle updates, random outcomes, and ZK-proof verification are simulated for demonstration purposes. True decentralized randomness and ZK-proof verification are complex topics requiring specialized infrastructure.
5.  **Access Shards (Simulated ERC-1155):** Non-transferable tokens (`_balances` tracked internally) representing the right to attempt unlocking *if* a specific condition is met. Shards are consumed upon successful conditional withdrawal linked to that shard type.
6.  **Role-Based Access Control:** Custom roles define who can configure conditions, update oracles, trigger checks, etc.
7.  **Dynamic Fees:** Fees for certain operations can change based on contract state or external factors (simulated).
8.  **State-Dependent Logic:** Puzzles depend on contract variables, conditions can depend on other conditions or state.
9.  **Conditional Self-Destruct:** A specific condition can trigger the contract to release assets and self-destruct.

**Function Summary:**

*   **Deposit Functions:**
    1.  `depositETH()`: Receives and holds Ether.
    2.  `depositERC20(address tokenAddress, uint256 amount)`: Receives and holds ERC-20 tokens.
    3.  `depositERC721(address tokenAddress, uint256 tokenId)`: Receives and holds ERC-721 tokens.
*   **Condition Management:**
    4.  `addUnlockCondition(uint8 conditionType, bytes calldata conditionData)`: Adds a new unlock condition rule.
    5.  `updateUnlockCondition(uint256 conditionId, bytes calldata newConditionData)`: Modifies an existing unlock condition rule (restricted).
    6.  `removeUnlockCondition(uint256 conditionId)`: Removes an unlock condition rule (restricted).
    7.  `checkConditionStatus(uint256 conditionId)`: Checks if a *single* specific condition is currently met.
*   **Unlock & Withdrawal:**
    8.  `checkAllConditionsMet()`: Internal/View function to check if *all* active conditions are satisfied.
    9.  `attemptUnlock(address payable receiver, address tokenAddress, uint256 amountOrTokenId, uint8 assetType)`: Attempts to withdraw assets if all conditions are met and required Access Shards (if any) are held and burned.
*   **Condition-Specific Trigger/Update Functions:**
    10. `updateOracleData(bytes32 key, uint256 value, uint64 timestamp)`: Updates simulated oracle data points (restricted to ORACLE_UPDATER_ROLE).
    11. `submitPuzzleSolution(bytes32 solutionHash)`: Submits a hash to try and solve an internal puzzle condition (restricted to PUZZLE_MANAGER_ROLE).
    12. `triggerProbabilisticCheck()`: Initiates the simulated probabilistic outcome check (restricted to PROBABILISTIC_TRIGGER_ROLE).
    13. `verifyZkProof(bytes memory proof, bytes memory publicInputs)`: Simulates verification of an off-chain ZK-proof (restricted).
*   **Access Shard Management (Simulated ERC-1155):**
    14. `mintAccessShards(address account, uint256 conditionId, uint256 amount)`: Mints Access Shards for a specific condition ID to an account (restricted).
    15. `burnAccessShards(address account, uint256 conditionId, uint256 amount)`: Burns Access Shards from an account (used internally on successful conditional unlock).
    16. `balanceOf(address account, uint256 conditionId)`: Gets the Access Shard balance for an account and condition ID.
    17. `balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)`: Gets batch Access Shard balances.
*   **State Query Functions:**
    18. `getVaultBalanceETH()`: Returns the current ETH balance of the contract.
    19. `getVaultBalanceERC20(address tokenAddress)`: Returns the contract's balance for a specific ERC-20 token.
    20. `getVaultOwnedERC721(address tokenAddress)`: Returns a list of token IDs held for a specific ERC-721 token (returns a limited subset or count for complexity). *Let's return a count and provide a way to query specific IDs if needed.*
    21. `getConditionParameters(uint256 conditionId)`: Returns details (type, data) for a specific condition.
    22. `getDynamicFee(uint8 operationType)`: Calculates and returns the current dynamic fee for an operation.
*   **Configuration & Role Management:**
    23. `grantRole(bytes32 role, address account)`: Grants a specific role to an account.
    24. `revokeRole(bytes32 role, address account)`: Revokes a specific role from an account.
    25. `hasRole(bytes32 role, address account)`: Checks if an account has a specific role.
    26. `updateConfiguration(bytes32 key, uint256 value)`: Generic function to update various configuration parameters (restricted).
*   **Fee Management:**
    27. `withdrawCollectedFees(address payable feeCollector)`: Allows a designated role to withdraw collected dynamic fees.
*   **Self-Destruct:**
    28. `checkSelfDestructCondition()`: Checks if the specific self-destruct condition is met.
    29. `triggerSelfDestruct()`: Executes self-destruct if condition met, sending remaining assets to a pre-defined address (or stakers). *Let's send to the contract deployer for simplicity.*
*   **Emergency Withdrawal (Highly Restricted):**
    30. `emergencyWithdrawETH(address payable receiver)`: Emergency function to withdraw ETH (restricted to EMERGENCY_ADMIN_ROLE).
    31. `emergencyWithdrawERC20(address tokenAddress, address receiver)`: Emergency function to withdraw ERC-20 (restricted).
    32. `emergencyWithdrawERC721(address tokenAddress, uint256 tokenId, address receiver)`: Emergency function to withdraw ERC-721 (restricted).

This outline covers more than 20 functions and lays out the structure for the complex vault logic.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumVault
 * @dev A multi-asset vault with complex, dynamic, and conditional unlock mechanisms.
 *      This contract demonstrates advanced concepts like dynamic conditions,
 *      simulated oracle interactions, internal state puzzles, probabilistic outcomes,
 *      simulated ZK-proof verification, custom role-based access control,
 *      simulated ERC-1155 Access Shards for conditional access, and dynamic fees.
 *      NOTE: Simulations for oracles, randomness, and ZK-proofs are simplified
 *      for conceptual demonstration and are NOT cryptographically secure or truly decentralized.
 *      This contract is for educational/demonstration purposes and NOT production-ready.
 *
 * Outline:
 * 1. Imports and Interfaces
 * 2. State Variables (Assets, Conditions, State, Access Shards, Roles, Config, Fees)
 * 3. Enums and Structs
 * 4. Events
 * 5. Modifiers (Custom Role Check)
 * 6. Constructor
 * 7. Access Control Implementation (Basic)
 * 8. Configuration Functions
 * 9. Deposit Functions (ETH, ERC-20, ERC-721)
 * 10. Condition Management (Add, Update, Remove, Check Status)
 * 11. Condition-Specific Trigger/Update Functions (Oracle, Puzzle, Probabilistic, Proof)
 * 12. Unlock Logic (Check All Conditions, Attempt Withdrawal)
 * 13. Access Shard Management (Simulated ERC-1155 Mint/Burn/Balance)
 * 14. Dynamic Fee Logic
 * 15. State Query Functions
 * 16. Self-Destruct Logic
 * 17. Emergency Withdrawals
 * 18. Receive/Fallback
 *
 * Function Summary:
 * - depositETH(): Payable function to deposit Ether.
 * - depositERC20(address tokenAddress, uint256 amount): Deposits specified amount of ERC-20 tokens.
 * - depositERC721(address tokenAddress, uint256 tokenId): Deposits a specific ERC-721 token.
 * - addUnlockCondition(uint8 conditionType, bytes calldata conditionData): Adds a new unlock rule.
 * - updateUnlockCondition(uint256 conditionId, bytes calldata newConditionData): Modifies an existing rule (role-restricted).
 * - removeUnlockCondition(uint256 conditionId): Removes an existing rule (role-restricted).
 * - checkConditionStatus(uint256 conditionId): Checks if a single condition is met.
 * - checkAllConditionsMet(): Checks if all active conditions are met.
 * - attemptUnlock(address payable receiver, address tokenAddress, uint256 amountOrTokenId, uint8 assetType): Attempts asset withdrawal based on conditions and shards.
 * - updateOracleData(bytes32 key, uint256 value, uint64 timestamp): Updates simulated oracle data (role-restricted).
 * - submitPuzzleSolution(bytes32 solutionHash): Attempts to solve the internal puzzle (role-restricted).
 * - triggerProbabilisticCheck(): Initiates simulated random check (role-restricted).
 * - verifyZkProof(bytes memory proof, bytes memory publicInputs): Simulates ZK-proof verification (role-restricted).
 * - mintAccessShards(address account, uint256 conditionId, uint256 amount): Mints conditional access tokens (role-restricted).
 * - burnAccessShards(address account, uint256 conditionId, uint256 amount): Burns conditional access tokens (internal/role-restricted).
 * - balanceOf(address account, uint256 conditionId): Gets Access Shard balance.
 * - balanceOfBatch(address[] calldata accounts, uint256[] calldata ids): Gets batch Access Shard balances.
 * - getVaultBalanceETH(): Returns ETH balance.
 * - getVaultBalanceERC20(address tokenAddress): Returns ERC-20 balance.
 * - getVaultOwnedERC721(address tokenAddress): Returns count of owned ERC-721s for a token type.
 * - getConditionParameters(uint256 conditionId): Gets details of a specific condition.
 * - getDynamicFee(uint8 operationType): Calculates current fee.
 * - grantRole(bytes32 role, address account): Grants a custom role.
 * - revokeRole(bytes32 role, address account): Revokes a custom role.
 * - hasRole(bytes32 role, address account): Checks if an account has a role.
 * - updateConfiguration(bytes32 key, uint256 value): Updates contract config (role-restricted).
 * - withdrawCollectedFees(address payable feeCollector): Withdraws fees (role-restricted).
 * - checkSelfDestructCondition(): Checks if self-destruct condition is met.
 * - triggerSelfDestruct(): Executes self-destruct (role-restricted, requires condition).
 * - emergencyWithdrawETH(address payable receiver): Emergency ETH withdrawal (highly restricted).
 * - emergencyWithdrawERC20(address tokenAddress, address receiver): Emergency ERC-20 withdrawal (highly restricted).
 * - emergencyWithdrawERC721(address tokenAddress, uint256 tokenId, address receiver): Emergency ERC-721 withdrawal (highly restricted).
 * - receive(): Handles plain ETH transfers.
 * - fallback(): Catches invalid calls.
 */

// Minimal interfaces - in a real scenario, you'd import from @openzeppelin/contracts or similar
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

// Custom ERC-1155 like interface just for function signatures needed
interface IAccessShards {
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);
    // No transfer functions needed as they are non-transferable
}


contract QuantumVault {

    // --- 2. State Variables ---

    // Vault Assets
    mapping(address => uint256) private _erc20Balances;
    mapping(address => mapping(uint256 => bool)) private _erc721OwnedTokens; // tokenAddress => tokenId => owned
    mapping(address => uint256[]) private _erc721OwnedTokenIdsList; // Helper for querying owned tokens

    // Condition Management
    struct UnlockCondition {
        uint8 conditionType; // See ConditionType enum
        bytes conditionData; // Data specific to the condition type
        bool active;
    }
    mapping(uint256 => UnlockCondition) private _unlockConditions;
    uint256 private _conditionCounter; // To generate unique condition IDs
    uint256[] private _activeConditionIds; // Array of IDs for quick iteration

    // Contract State & External Data (Simulated)
    mapping(bytes32 => uint256) private _oracleData; // key => value
    mapping(bytes32 => uint64) private _oracleTimestamps; // key => timestamp
    bytes32 private _currentPuzzleHash; // Hash required to solve the puzzle condition
    uint256 private _puzzleAttemptCount; // How many times puzzle attempted
    uint256 private _lastProbabilisticCheckBlock; // Block number of the last probabilistic check
    bool private _probabilisticOutcomeMet; // Result of the last probabilistic check
    bytes32 private _requiredZkProofHash; // Simulated hash representing valid proof + public inputs
    bool private _zkProofSubmittedAndValid; // Whether a valid proof has been submitted

    // Access Shards (Simulated ERC-1155)
    mapping(address => mapping(uint256 => uint256)) private _accessShardBalances; // account => conditionId => balance
    // No approval or transfer logic for these non-transferable tokens

    // Role-Based Access Control (Basic Implementation)
    mapping(bytes32 => mapping(address => bool)) private _roles;
    bytes32 public constant DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");
    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE"); // Manages conditions, config
    bytes32 public constant ORACLE_UPDATER_ROLE = keccak256("ORACLE_UPDATER_ROLE"); // Updates simulated oracle
    bytes32 public constant PUZZLE_MANAGER_ROLE = keccak256("PUZZLE_MANAGER_ROLE"); // Triggers puzzle updates/sets
    bytes32 public constant PROBABILISTIC_TRIGGER_ROLE = keccak256("PROBABILISTIC_TRIGGER_ROLE"); // Can trigger the probabilistic check
    bytes32 public constant PROOF_VERIFIER_ROLE = keccak256("PROOF_VERIFIER_ROLE"); // Can submit simulated proof results
    bytes32 public constant SHARD_MANAGER_ROLE = keccak256("SHARD_MANAGER_ROLE"); // Mints/burns access shards
    bytes32 public constant FEE_COLLECTOR_ROLE = keccak256("FEE_COLLECTOR_ROLE"); // Can withdraw collected fees
    bytes32 public constant EMERGENCY_ADMIN_ROLE = keccak256("EMERGENCY_ADMIN_ROLE"); // Can trigger emergency withdrawals

    // Configuration Parameters
    mapping(bytes32 => uint256) private _config;
    bytes32 public constant CONFIG_MIN_PUZZLE_DIFFICULTY = keccak256("MIN_PUZZLE_DIFF"); // Min leading zeros for puzzle hash
    bytes32 public constant CONFIG_PROBABILISTIC_CHECK_COOLDOWN = keccak256("PROBABILISTIC_COOLDOWN"); // Blocks between checks
    bytes32 public constant CONFIG_UNLOCK_FEE_RATE = keccak256("UNLOCK_FEE_RATE"); // Base fee multiplier
    bytes32 public constant CONFIG_SELF_DESTRUCT_CONDITION_ID = keccak256("SELF_DESTRUCT_CONDITION_ID"); // ID of the condition that triggers self-destruct
    address public _deployerAddress; // Address for self-destruct fallback

    // Fees
    uint256 private _collectedFeesETH;

    // --- 3. Enums and Structs ---

    enum ConditionType {
        TimeElapsed,          // Data: uint64 requiredTimestamp
        OracleDataGreater,    // Data: bytes32 oracleKey, uint256 requiredValue
        OracleDataSmaller,    // Data: bytes32 oracleKey, uint256 requiredValue
        InternalPuzzleSolved, // Data: (No extra data needed, state-dependent)
        ProbabilisticOutcome, // Data: bool requiredOutcome (if a specific outcome is needed)
        ZkProofVerified,      // Data: bytes32 expectedProofHash (simulated)
        AccessShardBalanceReq // Data: uint256 requiredBalance (of the shard ID corresponding to this condition ID)
    }

    enum AssetType {
        ETH,
        ERC20,
        ERC721
    }

    enum OperationType {
        UnlockAttempt,
        ConditionUpdate,
        ConfigUpdate
    }

    // --- 4. Events ---

    event DepositedETH(address indexed account, uint256 amount);
    event DepositedERC20(address indexed account, address indexed token, uint256 amount);
    event DepositedERC721(address indexed account, address indexed token, uint256 tokenId);

    event UnlockConditionAdded(uint256 indexed conditionId, uint8 conditionType);
    event UnlockConditionUpdated(uint256 indexed conditionId, uint8 conditionType);
    event UnlockConditionRemoved(uint256 indexed conditionId);
    event ConditionStatusChecked(uint256 indexed conditionId, bool met);

    event AttemptUnlock(address indexed receiver, uint8 assetType, bool success);
    event AssetsWithdrawn(address indexed receiver, uint8 assetType, address indexed token, uint256 amountOrTokenId);

    event OracleDataUpdated(bytes32 indexed key, uint256 value, uint64 timestamp);
    event PuzzleSolutionSubmitted(address indexed account, bytes32 solutionHash, bool success);
    event ProbabilisticCheckTriggered(bool outcome);
    event ZkProofVerified(address indexed account, bytes32 indexed proofHash, bool success);

    event AccessShardsMinted(address indexed account, uint256 indexed conditionId, uint256 amount);
    event AccessShardsBurned(address indexed account, uint256 indexed conditionId, uint256 amount);

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    event ConfigurationUpdated(bytes32 indexed key, uint256 value);
    event FeeCollected(address indexed collector, uint256 amount);

    event ContractSelfDestruct(address indexed beneficiary);
    event EmergencyWithdrawal(address indexed receiver, uint8 assetType, address indexed token, uint256 amountOrTokenId);

    // --- 5. Modifiers ---

    modifier onlyRole(bytes32 role) {
        require(_roles[role][msg.sender], "QuantumVault: Caller not authorized");
        _;
    }

    // --- 6. Constructor ---

    constructor() {
        _roles[DEFAULT_ADMIN_ROLE][msg.sender] = true;
        // Grant initial roles to the deployer
        _roles[CONFIGURATOR_ROLE][msg.sender] = true;
        _roles[ORACLE_UPDATER_ROLE][msg.sender] = true;
        _roles[PUZZLE_MANAGER_ROLE][msg.sender] = true;
        _roles[PROBABILISTIC_TRIGGER_ROLE][msg.sender] = true;
        _roles[PROOF_VERIFIER_ROLE][msg.sender] = true;
        _roles[SHARD_MANAGER_ROLE][msg.sender] = true;
        _roles[FEE_COLLECTOR_ROLE][msg.sender] = true;
        _roles[EMERGENCY_ADMIN_ROLE][msg.sender] = true;

        // Set initial configuration
        _config[CONFIG_MIN_PUZZLE_DIFFICULTY] = 4; // Require hash to start with 4 zero bytes
        _config[CONFIG_PROBABILISTIC_CHECK_COOLDOWN] = 100; // Can check randomness every 100 blocks
        _config[CONFIG_UNLOCK_FEE_RATE] = 1e16; // Base fee is 0.01 ETH (1e16)
        // CONFIG_SELF_DESTRUCT_CONDITION_ID is set via updateConfiguration later
        _deployerAddress = msg.sender; // Store deployer for self-destruct
    }

    // --- 7. Access Control Implementation (Basic) ---

    function grantRole(bytes32 role, address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(account != address(0), "QuantumVault: Account is zero address");
        _roles[role][account] = true;
        emit RoleGranted(role, account, msg.sender);
    }

    function revokeRole(bytes32 role, address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(account != address(0), "QuantumVault: Account is zero address");
        require(role != DEFAULT_ADMIN_ROLE || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "QuantumVault: Can't revoke own admin role"); // Prevent locking out
        _roles[role][account] = false;
        emit RoleRevoked(role, account, msg.sender);
    }

    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role][account];
    }

    // --- 8. Configuration Functions ---

    function updateConfiguration(bytes32 key, uint256 value) external onlyRole(CONFIGURATOR_ROLE) {
        _config[key] = value;
        emit ConfigurationUpdated(key, value);
    }

    function getConfiguration(bytes32 key) public view returns (uint256) {
        return _config[key];
    }

    // --- 9. Deposit Functions ---

    // payable function to receive ETH
    receive() external payable {
        emit DepositedETH(msg.sender, msg.value);
    }

    function depositETH() external payable {
         // ETH is deposited directly via receive() or fallback(),
         // but explicit deposit function allows adding specific logic/events
         // This function is redundant if receive() is present but included for clarity based on summary
         if (msg.value > 0) {
             emit DepositedETH(msg.sender, msg.value);
         }
    }

    function depositERC20(address tokenAddress, uint256 amount) external {
        require(amount > 0, "QuantumVault: Amount must be greater than 0");
        IERC20 token = IERC20(tokenAddress);
        // ERC20 standard transferFrom pattern requires caller to have approved this contract
        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "QuantumVault: ERC20 transfer failed");
        _erc20Balances[tokenAddress] += amount; // Track balance internally
        emit DepositedERC20(msg.sender, tokenAddress, amount);
    }

    function depositERC721(address tokenAddress, uint256 tokenId) external {
        IERC721 token = IERC721(tokenAddress);
        // ERC721 standard safeTransferFrom requires caller to be owner or approved
        require(token.ownerOf(tokenId) == msg.sender, "QuantumVault: Caller is not the owner of the token");
        token.safeTransferFrom(msg.sender, address(this), tokenId);
        require(token.ownerOf(tokenId) == address(this), "QuantumVault: ERC721 transfer failed");
        _erc721OwnedTokens[tokenAddress][tokenId] = true;
        _erc721OwnedTokenIdsList[tokenAddress].push(tokenId); // Add to list (simple, inefficient for many tokens)
        emit DepositedERC721(msg.sender, tokenAddress, tokenId);
    }

    // --- 10. Condition Management ---

    function addUnlockCondition(uint8 conditionType, bytes calldata conditionData) external onlyRole(CONFIGURATOR_ROLE) {
        // Basic validation for condition data length based on type - could be more robust
        if (conditionType == uint8(ConditionType.TimeElapsed)) require(conditionData.length == 8, "QuantumVault: Invalid data for TimeElapsed"); // uint64
        if (conditionType == uint8(ConditionType.OracleDataGreater)) require(conditionData.length == 32 + 32, "QuantumVault: Invalid data for OracleGreater"); // bytes32, uint256
        if (conditionType == uint8(ConditionType.OracleDataSmaller)) require(conditionData.length == 32 + 32, "QuantumVault: Invalid data for OracleSmaller"); // bytes32, uint256
        if (conditionType == uint8(ConditionType.ProbabilisticOutcome)) require(conditionData.length == 1, "QuantumVault: Invalid data for ProbabilisticOutcome"); // bool
        if (conditionType == uint8(ConditionType.ZkProofVerified)) require(conditionData.length == 32, "QuantumVault: Invalid data for ZkProofVerified"); // bytes32 expected hash
        if (conditionType == uint8(ConditionType.AccessShardBalanceReq)) require(conditionData.length == 32, "QuantumVault: Invalid data for AccessShardBalanceReq"); // uint256 required balance


        _conditionCounter++;
        uint256 newConditionId = _conditionCounter;
        _unlockConditions[newConditionId] = UnlockCondition(conditionType, conditionData, true);
        _activeConditionIds.push(newConditionId);

        emit UnlockConditionAdded(newConditionId, conditionType);
    }

    function updateUnlockCondition(uint256 conditionId, bytes calldata newConditionData) external onlyRole(CONFIGURATOR_ROLE) {
        UnlockCondition storage condition = _unlockConditions[conditionId];
        require(condition.active, "QuantumVault: Condition not found or inactive");

        // Basic validation for condition data length based on original type
        if (condition.conditionType == uint8(ConditionType.TimeElapsed)) require(newConditionData.length == 8, "QuantumVault: Invalid new data for TimeElapsed");
        if (condition.conditionType == uint8(ConditionType.OracleDataGreater)) require(newConditionData.length == 32 + 32, "QuantumVault: Invalid new data for OracleGreater");
        if (condition.conditionType == uint8(ConditionType.OracleDataSmaller)) require(newConditionData.length == 32 + 32, "QuantumVault: Invalid new data for OracleSmaller");
        if (condition.conditionType == uint8(ConditionType.ProbabilisticOutcome)) require(newConditionData.length == 1, "QuantumVault: Invalid new data for ProbabilisticOutcome");
        if (condition.conditionType == uint8(ConditionType.ZkProofVerified)) require(newConditionData.length == 32, "QuantumVault: Invalid new data for ZkProofVerified");
         if (condition.conditionType == uint8(ConditionType.AccessShardBalanceReq)) require(newConditionData.length == 32, "QuantumVault: Invalid new data for AccessShardBalanceReq");


        condition.conditionData = newConditionData;

        emit UnlockConditionUpdated(conditionId, condition.conditionType);
    }

    function removeUnlockCondition(uint256 conditionId) external onlyRole(CONFIGURATOR_ROLE) {
        UnlockCondition storage condition = _unlockConditions[conditionId];
        require(condition.active, "QuantumVault: Condition not found or inactive");

        condition.active = false; // Deactivate rather than deleting

        // Remove from active list (simple but inefficient for large arrays)
        for (uint256 i = 0; i < _activeConditionIds.length; i++) {
            if (_activeConditionIds[i] == conditionId) {
                _activeConditionIds[i] = _activeConditionIds[_activeConditionIds.length - 1];
                _activeConditionIds.pop();
                break;
            }
        }

        emit UnlockConditionRemoved(conditionId);
    }

    function checkConditionStatus(uint256 conditionId) public view returns (bool) {
        UnlockCondition storage condition = _unlockConditions[conditionId];
        if (!condition.active) {
            return false;
        }

        bytes memory data = condition.conditionData;

        // Decode and check condition based on type
        if (condition.conditionType == uint8(ConditionType.TimeElapsed)) {
            uint64 requiredTimestamp = abi.decode(data, (uint64));
            return block.timestamp >= requiredTimestamp;
        } else if (condition.conditionType == uint8(ConditionType.OracleDataGreater)) {
            (bytes32 oracleKey, uint256 requiredValue) = abi.decode(data, (bytes32, uint256));
            // Check if oracle data exists and meets timestamp freshness requirements if needed (not implemented here)
            return _oracleData[oracleKey] > requiredValue;
        } else if (condition.conditionType == uint8(ConditionType.OracleDataSmaller)) {
            (bytes32 oracleKey, uint256 requiredValue) = abi.decode(data, (bytes32, uint256));
            return _oracleData[oracleKey] < requiredValue;
        } else if (condition.conditionType == uint8(ConditionType.InternalPuzzleSolved)) {
            // This condition is met if the puzzle has been solved successfully
            return _currentPuzzleHash == bytes32(0); // Puzzle hash is zeroed out when solved
        } else if (condition.conditionType == uint8(ConditionType.ProbabilisticOutcome)) {
             bool requiredOutcome = abi.decode(data, (bool));
             return _probabilisticOutcomeMet == requiredOutcome;
        } else if (condition.conditionType == uint8(ConditionType.ZkProofVerified)) {
             bytes32 expectedHash = abi.decode(data, (bytes32));
             return _zkProofSubmittedAndValid && _requiredZkProofHash == expectedHash;
        } else if (condition.conditionType == uint8(ConditionType.AccessShardBalanceReq)) {
             uint256 requiredBalance = abi.decode(data, (uint256));
             // The shard ID for this condition is the conditionId itself
             return _accessShardBalances[msg.sender][conditionId] >= requiredBalance;
        }
        // Default case: unknown condition type or inactive
        return false;
    }

    // --- 11. Condition-Specific Trigger/Update Functions ---

    function updateOracleData(bytes32 key, uint256 value, uint64 timestamp) external onlyRole(ORACLE_UPDATER_ROLE) {
        _oracleData[key] = value;
        _oracleTimestamps[key] = timestamp; // Could add checks for freshness here
        emit OracleDataUpdated(key, value, timestamp);
    }

    function submitPuzzleSolution(bytes32 solutionHash) external onlyRole(PUZZLE_MANAGER_ROLE) { // Or maybe anyone can submit? Restricted for demo.
        _puzzleAttemptCount++;
        // Example puzzle: Does hash(vaultState + solutionHash) start with N zeros?
        // Vault state could be keccak256(abi.encodePacked(block.number, address(this), _collectedFeesETH, _puzzleAttemptCount));
        // For simplicity, let's make it a challenge against a target hash set by a manager role.
        // A more complex puzzle would depend on various contract states.
        // Let's make it finding a hash that when combined with a secret salt (set by manager) produces a result below a certain threshold.
        // Or, finding a hash that combined with block data and current state produces a hash with leading zeros.

        // Simple Puzzle: Find a solutionHash such that keccak256(abi.encodePacked(_currentPuzzleHash, solutionHash))
        // has N leading zero *bytes* where N is _config[CONFIG_MIN_PUZZLE_DIFFICULTY].
        // This assumes _currentPuzzleHash is set previously to a non-zero value to initiate the puzzle.
        require(_currentPuzzleHash != bytes32(0), "QuantumVault: No active puzzle set");

        bytes32 puzzleTest = keccak256(abi.encodePacked(_currentPuzzleHash, solutionHash));
        uint256 requiredDifficulty = _config[CONFIG_MIN_PUZZLE_DIFFICULTY];

        bool solved = true;
        for (uint256 i = 0; i < requiredDifficulty; i++) {
            if (puzzleTest[i] != 0) {
                solved = false;
                break;
            }
        }

        if (solved) {
            _currentPuzzleHash = bytes32(0); // Mark puzzle as solved
            emit PuzzleSolutionSubmitted(msg.sender, solutionHash, true);
            // The PUZZLE_MANAGER_ROLE would need to set a *new* _currentPuzzleHash to make the condition check false again
        } else {
            emit PuzzleSolutionSubmitted(msg.sender, solutionHash, false);
        }
    }

    function triggerProbabilisticCheck() external onlyRole(PROBABILISTIC_TRIGGER_ROLE) {
        require(block.number > _lastProbabilisticCheckBlock + _config[CONFIG_PROBABILISTIC_CHECK_COOLDOWN], "QuantumVault: Probabilistic check cooldown active");

        // Simulate randomness using block data (still predictable)
        // In a real scenario, use a decentralized oracle like Chainlink VRF
        bytes32 randomSeed = keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty, // Or block.prevrandao in PoS
            block.number,
            msg.sender,
            _collectedFeesETH,
            _puzzleAttemptCount
        ));

        // Example: Outcome is true if the random number (hash as uint256) is even
        _probabilisticOutcomeMet = (uint256(randomSeed) % 2 == 0);
        _lastProbabilisticCheckBlock = block.number;

        emit ProbabilisticCheckTriggered(_probabilisticOutcomeMet);
    }

     function verifyZkProof(bytes memory proof, bytes memory publicInputs) external onlyRole(PROOF_VERIFIER_ROLE) {
        // --- SIMULATION ---
        // In a real scenario, this would involve a complex precompiled contract call
        // or an on-chain verifier contract specific to the ZK-SNARK/STARK circuit.
        // Here, we simply check if a hash of the inputs matches a required hash set by a role.
        // This means the 'verifier' role is just confirming an expected output, not actually verifying.

        bytes32 simulatedProofHash = keccak256(abi.encodePacked(proof, publicInputs));

        if (_requiredZkProofHash != bytes32(0) && simulatedProofHash == _requiredZkProofHash) {
            _zkProofSubmittedAndValid = true;
            emit ZkProofVerified(msg.sender, simulatedProofHash, true);
            // A new requiredZkProofHash would need to be set by the role to make the condition false again.
        } else {
             _zkProofSubmittedAndValid = false; // Reset if incorrect proof submitted? Maybe not, could allow re-submission.
            emit ZkProofVerified(msg.sender, simulatedProofHash, false);
        }
     }

    // Function to set the required puzzle hash or ZK proof hash
    function setRequiredStateHash(bytes32 key, bytes32 requiredHash) external onlyRole(CONFIGURATOR_ROLE) {
        // Use keys to distinguish between puzzle and zk proof requirements
        bytes32 puzzleKey = keccak256("PUZZLE_TARGET_HASH");
        bytes32 zkProofKey = keccak256("ZK_PROOF_TARGET_HASH");

        if (key == puzzleKey) {
             _currentPuzzleHash = requiredHash;
             if (requiredHash != bytes32(0)) _puzzleAttemptCount = 0; // Reset attempts for new puzzle
             // If requiredHash is bytes32(0), it means the puzzle is now considered "solved" externally set
             emit ConfigurationUpdated(puzzleKey, uint256(requiredHash)); // Log as config update
        } else if (key == zkProofKey) {
            _requiredZkProofHash = requiredHash;
             if (requiredHash != bytes32(0)) _zkProofSubmittedAndValid = false; // Reset verification status
             // If requiredHash is bytes32(0), it means the ZK proof condition is now considered "met" externally set
             emit ConfigurationUpdated(zkProofKey, uint256(requiredHash)); // Log as config update
        } else {
            revert("QuantumVault: Invalid state hash key");
        }
    }


    // --- 12. Unlock Logic ---

    function checkAllConditionsMet() public view returns (bool) {
        if (_activeConditionIds.length == 0) {
            return false; // No conditions set, cannot unlock
        }
        for (uint256 i = 0; i < _activeConditionIds.length; i++) {
            uint256 conditionId = _activeConditionIds[i];
            if (!_unlockConditions[conditionId].active) {
                continue; // Skip inactive conditions in the list
            }
            if (!checkConditionStatus(conditionId)) {
                // If any active condition is NOT met, the overall unlock fails
                return false;
            }
        }
        // If we looped through all active conditions and none returned false, they are all met
        return true;
    }

    function attemptUnlock(address payable receiver, address tokenAddress, uint256 amountOrTokenId, uint8 assetType) external payable {
        require(receiver != address(0), "QuantumVault: Receiver is zero address");
        require(checkAllConditionsMet(), "QuantumVault: Not all unlock conditions are met");

        // --- Dynamic Fee Calculation ---
        uint256 requiredFee = getDynamicFee(uint8(OperationType.UnlockAttempt));
        require(msg.value >= requiredFee, "QuantumVault: Insufficient fee provided");

        // Collect the provided fee
        _collectedFeesETH += msg.value; // We keep all sent ETH, including excess

        // --- Consume Access Shards (if required by any condition) ---
        // Find all AccessShardBalanceReq conditions and ensure sender meets requirements
        // And automatically burn the required shards upon successful unlock attempt.
        for (uint256 i = 0; i < _activeConditionIds.length; i++) {
            uint256 conditionId = _activeConditionIds[i];
             UnlockCondition storage condition = _unlockConditions[conditionId];

            if (condition.active && condition.conditionType == uint8(ConditionType.AccessShardBalanceReq)) {
                uint256 requiredBalance = abi.decode(condition.conditionData, (uint256));
                 require(_accessShardBalances[msg.sender][conditionId] >= requiredBalance, "QuantumVault: Not enough required Access Shards");
                // Burn the required number of shards
                _burnAccessShards(msg.sender, conditionId, requiredBalance);
            }
        }

        emit AttemptUnlock(receiver, assetType, true);

        // --- Perform Withdrawal based on Asset Type ---
        if (assetType == uint8(AssetType.ETH)) {
            uint256 amount = amountOrTokenId; // Here amountOrTokenId is the amount of ETH
            require(address(this).balance >= amount, "QuantumVault: Insufficient ETH balance in vault");
            (bool success, ) = receiver.call{value: amount}("");
            require(success, "QuantumVault: ETH withdrawal failed");
            // ETH balance is updated automatically
            emit AssetsWithdrawn(receiver, assetType, address(0), amount);

        } else if (assetType == uint8(AssetType.ERC20)) {
            uint256 amount = amountOrTokenId; // Here amountOrTokenId is the amount of ERC20
            require(tokenAddress != address(0), "QuantumVault: Invalid ERC20 token address");
            require(_erc20Balances[tokenAddress] >= amount, "QuantumVault: Insufficient ERC20 balance in vault");
            _erc20Balances[tokenAddress] -= amount; // Update internal balance
            IERC20 token = IERC20(tokenAddress);
            bool success = token.transfer(receiver, amount);
            require(success, "QuantumVault: ERC20 withdrawal failed");
            emit AssetsWithdrawn(receiver, assetType, tokenAddress, amount);

        } else if (assetType == uint8(AssetType.ERC721)) {
            uint256 tokenId = amountOrTokenId; // Here amountOrTokenId is the tokenId of ERC721
            require(tokenAddress != address(0), "QuantumVault: Invalid ERC721 token address");
            require(_erc721OwnedTokens[tokenAddress][tokenId], "QuantumVault: Vault does not own this ERC721 token");
            _erc721OwnedTokens[tokenAddress][tokenId] = false; // Mark as not owned
            // Note: Removing from _erc721OwnedTokenIdsList[] is complex and gas-heavy.
            // We'll leave it for simplicity, but balance check relies on the mapping.
            IERC721 token = IERC721(tokenAddress);
            token.safeTransferFrom(address(this), receiver, tokenId);
            emit AssetsWithdrawn(receiver, assetType, tokenAddress, tokenId);

        } else {
             revert("QuantumVault: Invalid asset type");
        }
    }

    // --- 13. Access Shard Management (Simulated ERC-1155) ---

    // ERC-1155 functions needed for checkConditionStatus and attemptUnlock
    // These are internal logic, not full ERC-1155 compliance for external transfer

    function balanceOf(address account, uint256 id) public view returns (uint256) {
        return _accessShardBalances[account][id];
    }

     function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory) {
        require(accounts.length == ids.length, "QuantumVault: Accounts and IDs mismatch");
        uint256[] memory balances = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; ++i) {
            balances[i] = _accessShardBalances[accounts[i]][ids[i]];
        }
        return balances;
     }

    // Internal minting - only callable by roles or contract logic
    function mintAccessShards(address account, uint256 conditionId, uint256 amount) public onlyRole(SHARD_MANAGER_ROLE) {
        require(account != address(0), "QuantumVault: Cannot mint to zero address");
        require(_unlockConditions[conditionId].active, "QuantumVault: Condition ID not active");
        require(amount > 0, "QuantumVault: Mint amount must be greater than 0");

        _accessShardBalances[account][conditionId] += amount;
        // ERC-1155 standard includes an event TransferSingle(operator, from, to, id, value);
        // operator = msg.sender, from = address(0), to = account, id = conditionId, value = amount
        // We'll emit a custom event for clarity in this specific contract context
        emit AccessShardsMinted(account, conditionId, amount);
    }

    // Internal burning - only callable by roles or contract logic (e.g. upon successful unlock)
    function _burnAccessShards(address account, uint256 conditionId, uint256 amount) internal {
         // Called internally by attemptUnlock or by SHARD_MANAGER_ROLE
        require(account != address(0), "QuantumVault: Cannot burn from zero address");
        require(amount > 0, "QuantumVault: Burn amount must be greater than 0");
        require(_accessShardBalances[account][conditionId] >= amount, "QuantumVault: Insufficient Access Shards balance");

        _accessShardBalances[account][conditionId] -= amount;
         // ERC-1155 standard includes an event TransferSingle(operator, from, to, id, value);
        // operator = msg.sender, from = account, to = address(0), id = conditionId, value = amount
        // We'll emit a custom event
        emit AccessShardsBurned(account, conditionId, amount);
    }

    // Provide a public burn function restricted by role
    function burnAccessShards(address account, uint256 conditionId, uint256 amount) external onlyRole(SHARD_MANAGER_ROLE) {
         _burnAccessShards(account, conditionId, amount);
    }


    // --- 14. Dynamic Fee Logic ---

    function getDynamicFee(uint8 operationType) public view returns (uint256) {
        uint256 baseFee = _config[CONFIG_UNLOCK_FEE_RATE]; // Base fee set in config (e.g., in wei)
        uint256 dynamicMultiplier = 1;

        if (operationType == uint8(OperationType.UnlockAttempt)) {
            // Example dynamic fee: increases slightly based on the number of active conditions
            dynamicMultiplier = dynamicMultiplier + (_activeConditionIds.length / 2); // +0.5 per condition
            // Could also increase based on recent failed unlock attempts, current gas price, etc.
            // Example: Add 1 wei per puzzle attempt (simulated complexity cost)
            baseFee = baseFee + _puzzleAttemptCount;

        } else if (operationType == uint8(OperationType.ConditionUpdate) || operationType == uint8(OperationType.ConfigUpdate)) {
            // Config/Condition updates could have a fixed higher fee or be free (role-gated implies trust)
             return 0; // Assuming config/condition updates are free for authorized roles
        }
        // More complex logic could involve oracle data, time of day, contract balance, etc.

        return baseFee * dynamicMultiplier;
    }

    function withdrawCollectedFees(address payable feeCollector) external onlyRole(FEE_COLLECTOR_ROLE) {
        require(feeCollector != address(0), "QuantumVault: Fee collector is zero address");
        uint256 amount = _collectedFeesETH;
        require(amount > 0, "QuantumVault: No fees collected");

        _collectedFeesETH = 0; // Reset balance before sending
        (bool success, ) = feeCollector.call{value: amount}("");
        require(success, "QuantumVault: Fee withdrawal failed");

        emit FeeCollected(feeCollector, amount);
    }

    // --- 15. State Query Functions ---

    function getVaultBalanceETH() public view returns (uint256) {
        return address(this).balance;
    }

    function getVaultBalanceERC20(address tokenAddress) public view returns (uint256) {
        // Note: This uses the internal balance tracking, which assumes deposits only via depositERC20.
        // A more robust check would also query the actual token contract: IERC20(tokenAddress).balanceOf(address(this));
        return _erc20Balances[tokenAddress];
    }

    // Returns the count of ERC721 tokens of a specific type owned
    function getVaultOwnedERC721Count(address tokenAddress) public view returns (uint256) {
        // Iterating mapping is not possible. Iterating the list is simple but inefficient.
        // Let's just return the *size of the list*, which might contain non-owned (burned) IDs.
        // A better implementation would use a more complex data structure or periodically clean the list.
        return _erc721OwnedTokenIdsList[tokenAddress].length;
    }

    // Returns the list of ERC721 token IDs owned for a specific type (potentially including burned)
     function getVaultOwnedERC721List(address tokenAddress) public view returns (uint256[] memory) {
         // WARNING: This list is NOT cleaned when tokens are withdrawn.
         // Check `_erc721OwnedTokens[tokenAddress][tokenId]` for definitive ownership.
         return _erc721OwnedTokenIdsList[tokenAddress];
     }

    function getConditionParameters(uint256 conditionId) public view returns (uint8 conditionType, bytes memory conditionData, bool active) {
        UnlockCondition storage condition = _unlockConditions[conditionId];
        return (condition.conditionType, condition.conditionData, condition.active);
    }

     function getActiveConditionIds() public view returns (uint256[] memory) {
         return _activeConditionIds;
     }

    function getOracleData(bytes32 key) public view returns (uint256 value, uint64 timestamp) {
        return (_oracleData[key], _oracleTimestamps[key]);
    }

    function getCurrentPuzzleState() public view returns (bytes32 currentPuzzleHash, uint256 attemptCount) {
        return (_currentPuzzleHash, _puzzleAttemptCount);
    }

    function getProbabilisticState() public view returns (bool outcome, uint256 lastCheckBlock) {
        return (_probabilisticOutcomeMet, _lastProbabilisticCheckBlock);
    }

    function getZkProofState() public view returns (bytes32 requiredHash, bool verified) {
        return (_requiredZkProofHash, _zkProofSubmittedAndValid);
    }

    function getCollectedFeesETH() public view returns (uint256) {
        return _collectedFeesETH;
    }


    // --- 16. Self-Destruct Logic ---

    function checkSelfDestructCondition() public view returns (bool) {
        uint256 selfDestructConditionId = _config[CONFIG_SELF_DESTRUCT_CONDITION_ID];
        if (selfDestructConditionId == 0) {
            return false; // Self-destruct condition not configured
        }
        // Check if the specific self-destruct condition is met
        // Note: This only checks *one* condition, not *all* unlock conditions.
        return checkConditionStatus(selfDestructConditionId);
    }

    // Allows a role to trigger self-destruct *if* the configured condition is met
    function triggerSelfDestruct() external onlyRole(DEFAULT_ADMIN_ROLE) { // Or perhaps a dedicated role
        require(checkSelfDestructCondition(), "QuantumVault: Self-destruct condition not met");

        // Transfer all remaining ETH, ERC20, ERC721 to the deployer address
        // ETH
        (bool successETH, ) = _deployerAddress.call{value: address(this).balance}("");
        require(successETH, "QuantumVault: Self-destruct ETH transfer failed"); // Should not fail if balance > 0

        // ERC20 (Inefficient: needs to know which tokens are held. Requires iterating over all possible tokens or tracking active tokens)
        // Simple demo limitation: cannot enumerate all held ERC20s easily.
        // In a real system, deposit functions would update a list/set of unique ERC20 addresses.
        // For demonstration, this part is commented out or requires prior knowledge of tokens.
        // Example if you knew tokenA and tokenB were deposited:
        // if (_erc20Balances[tokenA] > 0) { IERC20(tokenA).transfer(_deployerAddress, _erc20Balances[tokenA]); _erc20Balances[tokenA] = 0; }
        // if (_erc20Balances[tokenB] > 0) { IERC20(tokenB).transfer(_deployerAddress, _erc20Balances[tokenB]); _erc20Balances[tokenB] = 0; }

        // ERC721 (Also complex to enumerate all held tokens/IDs)
        // Similar limitation as ERC20. Needs tracking of addresses and token IDs.
        // Example if you knew tokenC and tokenID 1, 5 were deposited:
        // if (_erc721OwnedTokens[tokenC][1]) { IERC721(tokenC).safeTransferFrom(address(this), _deployerAddress, 1); _erc721OwnedTokens[tokenC][1] = false; }
        // if (_erc721OwnedTokens[tokenC][5]) { IERC721(tokenC).safeTransferFrom(address(this), _deployerAddress, 5); _erc721OwnedTokens[tokenC][5] = false; }


        emit ContractSelfDestruct(_deployerAddress);

        // Self-destruct. Sends remaining balance (should be 0 after ETH transfer)
        selfdestruct(payable(_deployerAddress));
    }

    // --- 17. Emergency Withdrawals ---

    // Emergency functions allow specific roles to bypass conditions under duress
    // This is a *highly privileged* function and should be used with extreme caution.
    function emergencyWithdrawETH(address payable receiver) external onlyRole(EMERGENCY_ADMIN_ROLE) {
         require(receiver != address(0), "QuantumVault: Receiver is zero address");
         uint256 balance = address(this).balance;
         require(balance > 0, "QuantumVault: No ETH balance to withdraw");
         (bool success, ) = receiver.call{value: balance}("");
         require(success, "QuantumVault: Emergency ETH withdrawal failed");
         emit EmergencyWithdrawal(receiver, uint8(AssetType.ETH), address(0), balance);
    }

    function emergencyWithdrawERC20(address tokenAddress, address receiver) external onlyRole(EMERGENCY_ADMIN_ROLE) {
        require(tokenAddress != address(0), "QuantumVault: Invalid ERC20 token address");
        require(receiver != address(0), "QuantumVault: Receiver is zero address");
        // Note: Uses internal balance. A robust emergency should query actual token balance.
        uint256 balance = _erc20Balances[tokenAddress];
        require(balance > 0, "QuantumVault: No ERC20 balance to withdraw");
        _erc20Balances[tokenAddress] = 0; // Reset internal balance
        IERC20 token = IERC20(tokenAddress);
        bool success = token.transfer(receiver, balance);
        require(success, "QuantumVault: Emergency ERC20 withdrawal failed");
        emit EmergencyWithdrawal(receiver, uint8(AssetType.ERC20), tokenAddress, balance);
    }

     function emergencyWithdrawERC721(address tokenAddress, uint256 tokenId, address receiver) external onlyRole(EMERGENCY_ADMIN_ROLE) {
         require(tokenAddress != address(0), "QuantumVault: Invalid ERC721 token address");
         require(receiver != address(0), "QuantumVault: Receiver is zero address");
         require(_erc721OwnedTokens[tokenAddress][tokenId], "QuantumVault: Vault does not own this ERC721 token");

         _erc721OwnedTokens[tokenAddress][tokenId] = false; // Mark as not owned
         IERC721 token = IERC721(tokenAddress);
         token.safeTransferFrom(address(this), receiver, tokenId);
         emit EmergencyWithdrawal(receiver, uint8(AssetType.ERC721), tokenAddress, tokenId);
     }


    // --- 18. Receive/Fallback ---

    fallback() external payable {
        // This catches any calls with ether but no matching function, or calls to undefined functions.
        // If ETH is sent via fallback, it's also logged by the receive() function above (which is called first).
        // If no data is sent, receive() is called. If data is sent but no function matches, fallback() is called.
        // We allow payable fallback so ETH sent to incorrect function calls is still accepted.
         if (msg.value > 0) {
            emit DepositedETH(msg.sender, msg.value);
         }
    }
}
```