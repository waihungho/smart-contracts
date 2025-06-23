Okay, here is a concept for an advanced smart contract called `QuantumVault`. It acts as a conditional, programmable vault where funds (ETH or ERC20) are locked and can only be withdrawn if a set of predefined "Quantum Conditions" are met. These conditions can be time-based, depend on external oracle data, or even require the submission of off-chain verifiable proofs (conceptually, as on-chain ZK verification of arbitrary proofs is complex).

The contract includes features like dynamic condition sets, oracle integration, fee mechanics, pausing, and different withdrawal scenarios. It's designed to be more complex than standard timelocks or simple escrows.

**Disclaimer:** This is a conceptual contract designed to showcase advanced Solidity patterns and ideas. It may require significant testing, security audits, and further refinement for production use. On-chain verification of complex off-chain proofs (like ZK-SNARKs) is abstracted here; a real implementation would require dedicated precompiles or verifiable computation integration.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Although 0.8+ has overflow checks, SafeMath is good for explicit intent in complex calculations.

// --- Contract Outline ---
// 1. State Variables: Stores contract configuration, user deposits, condition definitions, oracle data, etc.
// 2. Enums: Define possible states for deposits, conditions, withdrawals, asset types.
// 3. Structs: Define data structures for deposits, conditions, condition sets, withdrawal requests, oracles, oracle data points.
// 4. Events: Announce key actions for off-chain monitoring.
// 5. Modifiers: Control access and state (owned, pausable, reentrancy guard, onlyOracle).
// 6. Constructor: Initializes the contract with basic settings.
// 7. Core Vault Logic: Deposit, request withdrawal, execute withdrawal.
// 8. Condition Management: Define, update, get condition sets; submit data/proofs to fulfill conditions.
// 9. Oracle Integration: Register/deregister oracles, receive data from oracles.
// 10. Admin/Governance Functions: Set fees, collect fees, pause/unpause, emergency withdrawals, update settings.
// 11. View Functions: Read contract state.
// 12. Internal Helper Functions: Logic for verifying conditions, fee calculation, etc.

// --- Function Summary ---
// CORE VAULT LOGIC (3 functions + 2 view helpers):
// 1. depositEther(): User deposits ETH into a vault type (condition set).
// 2. depositToken(): User deposits ERC20 tokens into a vault type (condition set).
// 3. requestConditionalWithdrawal(): User requests to withdraw their deposit. Initiates condition checking.
// 4. executeConditionalWithdrawal(): User or authorized party attempts to execute a withdrawal request once conditions are met.
// 5. getUserDepositDetails(): View function to get details of a specific user deposit.
// 6. getUserWithdrawalRequest(): View function to get details of a specific withdrawal request.

// CONDITION MANAGEMENT (3 functions + 2 view helpers):
// 7. defineConditionSet(): Owner defines a new set of conditions required for withdrawal.
// 8. updateConditionSet(): Owner updates an existing condition set (restricted use, perhaps only if no active deposits use it).
// 9. submitDataForCondition(): User or authorized oracle submits data/proof to fulfill a specific condition associated with their deposit.
// 10. getConditionSet(): View function to retrieve details of a condition set.
// 11. getConditionStatusForDeposit(): View function to check the status of conditions for a specific deposit.

// ORACLE INTEGRATION (3 functions + 2 view helpers):
// 12. registerOracle(): Owner registers an address as a trusted oracle for specific data types/proof verifications.
// 13. deregisterOracle(): Owner deregisters an oracle.
// 14. setOracleData(): Registered oracles call this to submit data on-chain, potentially fulfilling conditions.
// 15. getOracleData(): View function to retrieve the latest data submitted by a specific oracle type.
// 16. getRegisteredOracles(): View function to list registered oracles.

// ADMIN / GOVERNANCE (6 functions + 2 view helpers):
// 17. setAdminFeeRate(): Owner sets the fee percentage taken on successful withdrawals.
// 18. collectFees(): Owner collects accumulated fees.
// 19. pause(): Owner pauses certain contract operations (deposits, withdrawals).
// 20. unpause(): Owner unpauses contract operations.
// 21. emergencyWithdrawAdmin(): Owner can forcefully withdraw funds in emergencies (e.g., critical bug).
// 22. emergencyWithdrawUser(): Allows users to withdraw funds after a long timelock or via admin override (a safety valve).
// 23. getAdminFeeRate(): View function to get the current fee rate.
// 24. getTotalPooledBalance(): View function to see the total balance held by the contract.

// HELPERS / UTILS (2 functions + internal logic):
// 25. getVersion(): Returns the contract version.
// 26. supportsConditionType(): View function to check if a condition type is valid.
// (Internal: _verifyCondition, _calculateFee, etc. - not exposed as external functions)

contract QuantumVault is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // --- Enums ---
    enum AssetType { ETH, ERC20 }
    enum ConditionType {
        TIME_BASED,             // Based on a specific timestamp
        ORACLE_PRICE_GE,        // Oracle reports a price >= threshold
        ORACLE_PRICE_LE,        // Oracle reports a price <= threshold
        ORACLE_DATA_MATCH,      // Oracle reports specific data bytes
        PROOF_VERIFIED          // An associated oracle (verifier) submits proof verification status
        // Add more complex condition types here (e.g., Multi-sig approval, DAO vote result, etc.)
    }
    enum DepositStatus { Active, WithdrawalRequested }
    enum WithdrawalStatus { Pending, ReadyForExecution, Cancelled, Executed }
    enum ConditionStatus { Pending, Met, Failed }

    // --- Structs ---
    struct Deposit {
        address user;
        AssetType assetType;
        IERC20 tokenAddress; // Address is 0x0 for ETH
        uint256 amount;
        uint256 depositTime;
        uint256 conditionSetId;
        DepositStatus status;
    }

    struct QuantumCondition {
        ConditionType conditionType;
        bytes params;             // Parameters for the condition (e.g., timestamp, price threshold, data bytes, oracle ID)
        uint256 associatedOracleId; // Oracle responsible for this condition type (0 if not applicable, or specifies verifier for PROOF_VERIFIED)
        ConditionStatus status;   // Status for a specific deposit's instance of this condition
    }

    struct ConditionSet {
        QuantumCondition[] conditions;
        bool isActive;
    }

    struct WithdrawalRequest {
        uint256 depositId;
        uint256 requestTime;
        WithdrawalStatus status;
    }

    struct Oracle {
        address oracleAddress;
        bool isActive;
        bytes32[] supportedDataTypes; // Identifiers for data types/proof types this oracle provides/verifies
    }

    struct OracleDataPoint {
        bytes data;
        uint256 timestamp;
        // Could add signed data from oracles here
    }

    // --- State Variables ---
    Deposit[] public userDeposits;
    uint256 public depositCounter;

    ConditionSet[] public conditionSets; // conditionSets[0] could be reserved or unused
    uint256 public conditionSetCounter;

    WithdrawalRequest[] public withdrawalRequests;
    uint256 public withdrawalRequestCounter;

    // Map depositId to its withdrawal request ID (if any)
    mapping(uint256 => uint256) public depositToWithdrawalRequest;

    // Map depositId to the dynamic status of its conditions
    // mapping(uint256 => mapping(uint256 => ConditionStatus)) public depositConditionStatuses; // depositId => conditionIndexInSet => status

    // Simpler storage for condition status tied to deposit + condition index
    mapping(uint256 => ConditionStatus[]) private _depositConditionStatuses; // depositId => array of statuses matching conditionSet

    // Oracle management
    mapping(uint256 => Oracle) public registeredOracles; // oracleId => Oracle
    mapping(address => uint256) public oracleAddressToId;
    uint256 public oracleCounter;
    uint256 public oracleDataThreshold = 1; // Minimum number of oracle reports required for consensus (for future multi-oracle features)

    // Oracle Data Storage (simplified - storing last data point per oracle+type)
    mapping(uint256 => mapping(bytes32 => OracleDataPoint)) public oracleDataStore; // oracleId => dataTypeHash => DataPoint

    // Admin settings
    uint256 public adminFeeRateBasisPoints; // e.g., 100 for 1%
    uint256 public totalFeesCollectedETH;
    mapping(IERC20 => uint256) public totalFeesCollectedTokens;

    // Emergency withdrawal
    uint256 public constant EMERGENCY_WITHDRAW_GRACE_PERIOD = 365 days; // Example: users can withdraw after 1 year if deposit untouched/conditions not met

    // Contract version
    string public constant VERSION = "1.0.0";

    // --- Events ---
    event DepositMade(uint256 indexed depositId, address indexed user, AssetType assetType, IERC20 indexed tokenAddress, uint256 amount, uint256 conditionSetId);
    event WithdrawalRequested(uint256 indexed withdrawalRequestId, uint256 indexed depositId, address indexed user);
    event WithdrawalExecuted(uint256 indexed withdrawalRequestId, uint256 indexed depositId, address indexed user, uint256 amount, uint256 feesPaid);
    event ConditionSetDefined(uint256 indexed conditionSetId, uint256 numberOfConditions);
    event ConditionSetUpdated(uint256 indexed conditionSetId);
    event ConditionStatusUpdated(uint256 indexed depositId, uint256 indexed conditionIndex, ConditionType conditionType, ConditionStatus newStatus);
    event OracleRegistered(uint256 indexed oracleId, address indexed oracleAddress);
    event OracleDeregistered(uint256 indexed oracleId, address indexed oracleAddress);
    event OracleDataSet(uint256 indexed oracleId, bytes32 indexed dataTypeHash, bytes data, uint256 timestamp);
    event FeesCollected(address indexed collector, uint256 amountETH, IERC20 indexed tokenAddress, uint256 amountToken);
    event Paused(address account);
    event Unpaused(address account);
    event EmergencyWithdrawal(address indexed recipient, uint256 amountETH, IERC20 indexed tokenAddress, uint256 amountToken);

    // --- Modifiers ---
    modifier onlyOracle(uint256 _oracleId) {
        require(registeredOracles[_oracleId].isActive && registeredOracles[_oracleId].oracleAddress == msg.sender, "Not an active registered oracle");
        _;
    }

    // --- Constructor ---
    constructor(uint256 _initialAdminFeeRateBasisPoints) Ownable(msg.sender) {
        adminFeeRateBasisPoints = _initialAdminFeeRateBasisPoints;
        depositCounter = 0;
        conditionSetCounter = 0;
        withdrawalRequestCounter = 0;
        oracleCounter = 0;
        totalFeesCollectedETH = 0;
    }

    // --- Core Vault Logic ---

    /**
     * @notice User deposits ETH into the vault under a specific condition set.
     * @param _conditionSetId The ID of the condition set governing withdrawal.
     */
    function depositEther(uint256 _conditionSetId) external payable whenNotPaused nonReentrant {
        require(msg.value > 0, "Cannot deposit 0 ETH");
        require(_conditionSetId > 0 && _conditionSetId < conditionSets.length, "Invalid condition set ID");
        require(conditionSets[_conditionSetId].isActive, "Condition set is not active");

        userDeposits.push(Deposit({
            user: msg.sender,
            assetType: AssetType.ETH,
            tokenAddress: IERC20(address(0)),
            amount: msg.value,
            depositTime: block.timestamp,
            conditionSetId: _conditionSetId,
            status: DepositStatus.Active
        }));
        uint256 newDepositId = depositCounter++;

        // Initialize condition statuses for this deposit
        _depositConditionStatuses[newDepositId] = new ConditionStatus[](conditionSets[_conditionSetId].conditions.length);
        for(uint i = 0; i < conditionSets[_conditionSetId].conditions.length; i++) {
             _depositConditionStatuses[newDepositId][i] = ConditionStatus.Pending;
        }


        emit DepositMade(newDepositId, msg.sender, AssetType.ETH, IERC20(address(0)), msg.value, _conditionSetId);
    }

    /**
     * @notice User deposits ERC20 tokens into the vault under a specific condition set.
     * @param _tokenAddress The address of the ERC20 token.
     * @param _amount The amount of tokens to deposit.
     * @param _conditionSetId The ID of the condition set governing withdrawal.
     */
    function depositToken(IERC20 _tokenAddress, uint256 _amount, uint256 _conditionSetId) external whenNotPaused nonReentrant {
        require(_amount > 0, "Cannot deposit 0 tokens");
        require(address(_tokenAddress) != address(0), "Invalid token address");
        require(_conditionSetId > 0 && _conditionSetId < conditionSets.length, "Invalid condition set ID");
        require(conditionSets[_conditionSetId].isActive, "Condition set is not active");

        _tokenAddress.safeTransferFrom(msg.sender, address(this), _amount);

        userDeposits.push(Deposit({
            user: msg.sender,
            assetType: AssetType.ERC20,
            tokenAddress: _tokenAddress,
            amount: _amount,
            depositTime: block.timestamp,
            conditionSetId: _conditionSetId,
            status: DepositStatus.Active
        }));
         uint256 newDepositId = depositCounter++;

         // Initialize condition statuses for this deposit
        _depositConditionStatuses[newDepositId] = new ConditionStatus[](conditionSets[_conditionSetId].conditions.length);
        for(uint i = 0; i < conditionSets[_conditionSetId].conditions.length; i++) {
             _depositConditionStatuses[newDepositId][i] = ConditionStatus.Pending;
        }

        emit DepositMade(newDepositId, msg.sender, AssetType.ERC20, _tokenAddress, _amount, _conditionSetId);
    }

    /**
     * @notice User requests to withdraw a specific deposit.
     * This changes the deposit status and potentially triggers condition checks or waits for fulfillment.
     * @param _depositId The ID of the deposit to withdraw.
     */
    function requestConditionalWithdrawal(uint256 _depositId) external whenNotPaused nonReentrant {
        require(_depositId < userDeposits.length, "Invalid deposit ID");
        Deposit storage deposit = userDeposits[_depositId];
        require(deposit.user == msg.sender, "Not your deposit");
        require(deposit.status == DepositStatus.Active, "Deposit is not active");
        require(depositToWithdrawalRequest[_depositId] == 0, "Withdrawal request already exists for this deposit"); // Check if default value (0)

        deposit.status = DepositStatus.WithdrawalRequested;

        withdrawalRequests.push(WithdrawalRequest({
            depositId: _depositId,
            requestTime: block.timestamp,
            status: WithdrawalStatus.Pending
        }));
        uint256 newWithdrawalRequestId = withdrawalRequestCounter++;
        depositToWithdrawalRequest[_depositId] = newWithdrawalRequestId; // Link deposit to withdrawal request

        // Note: Condition verification logic is primarily triggered by _submitDataForCondition
        // and checked upon executeConditionalWithdrawal.

        emit WithdrawalRequested(newWithdrawalRequestId, _depositId, msg.sender);
    }

    /**
     * @notice Attempts to execute a previously requested withdrawal if all conditions are met.
     * Can be called by the user who requested, or potentially anyone to help fulfill (gas costs).
     * @param _withdrawalRequestId The ID of the withdrawal request to execute.
     */
    function executeConditionalWithdrawal(uint256 _withdrawalRequestId) external whenNotPaused nonReentrant {
        require(_withdrawalRequestId > 0 && _withdrawalRequestId < withdrawalRequests.length, "Invalid withdrawal request ID"); // Use > 0 if request IDs start from 1
        WithdrawalRequest storage req = withdrawalRequests[_withdrawalRequestId];
        require(req.status == WithdrawalStatus.Pending, "Withdrawal request is not pending");

        Deposit storage deposit = userDeposits[req.depositId];
        // Optional: Add check if msg.sender is the deposit owner or anyone
        // require(deposit.user == msg.sender, "Not authorized to execute this withdrawal"); // Uncomment if only owner can execute

        require(_checkAllConditionsMet(req.depositId), "Not all conditions for this deposit are met");

        // Calculate fee
        uint256 totalAmount = deposit.amount;
        uint256 feeAmount = totalAmount.mul(adminFeeRateBasisPoints).div(10000); // Basis points (10000 = 100%)
        uint256 amountToUser = totalAmount.sub(feeAmount);

        req.status = WithdrawalStatus.Executed;

        if (deposit.assetType == AssetType.ETH) {
            // Transfer ETH to user and fees to contract
            (bool successUser, ) = payable(deposit.user).call{value: amountToUser}("");
            require(successUser, "ETH transfer to user failed");
            // Fees remain in the contract's ETH balance

            totalFeesCollectedETH = totalFeesCollectedETH.add(feeAmount); // Track accumulated fees

            emit WithdrawalExecuted(_withdrawalRequestId, req.depositId, deposit.user, amountToUser, feeAmount);

        } else if (deposit.assetType == AssetType.ERC20) {
            // Transfer tokens to user and fees to contract
            deposit.tokenAddress.safeTransfer(deposit.user, amountToUser);
            // Fees remain in the contract's token balance

            totalFeesCollectedTokens[deposit.tokenAddress] = totalFeesCollectedTokens[deposit.tokenAddress].add(feeAmount); // Track fees per token

            emit WithdrawalExecuted(_withdrawalRequestId, req.depositId, deposit.user, amountToUser, feeAmount);
        }

        // Clean up or mark deposit as finalized
        // For simplicity here, we just change withdrawal status. Could nullify deposit entry or move to a history array.
        // deposit.amount = 0; // Mark as zeroed out if not using a separate history array

    }

    // --- Condition Management ---

    /**
     * @notice Owner defines a new set of conditions that deposits can use.
     * Requires condition IDs to be greater than 0. conditionSets[0] is unused.
     * @param _conditions Array of QuantumCondition structs defining the set.
     */
    function defineConditionSet(QuantumCondition[] calldata _conditions) external onlyOwner {
        require(_conditions.length > 0, "Condition set must have at least one condition");
        // Basic validation of condition types (can add more sophisticated checks based on params later)
        for (uint i = 0; i < _conditions.length; i++) {
            require(supportsConditionType(_conditions[i].conditionType), "Unsupported condition type included");
             // Add specific param validation here based on condition type if needed
        }

        conditionSets.push(); // Creates a new empty slot, push() increments length.
        conditionSetCounter++; // Use counter as the new ID (starts from 1)
        uint256 newSetId = conditionSetCounter;

        conditionSets[newSetId].conditions = _conditions;
        conditionSets[newSetId].isActive = true;

        emit ConditionSetDefined(newSetId, _conditions.length);
    }

     /**
     * @notice Owner updates an existing condition set.
     * This function should be used with caution as it affects future withdrawals for deposits
     * using this set. Might add restrictions (e.g., cannot update if active deposits use it).
     * @param _conditionSetId The ID of the condition set to update.
     * @param _conditions The new array of QuantumCondition structs.
     */
    function updateConditionSet(uint256 _conditionSetId, QuantumCondition[] calldata _conditions) external onlyOwner {
        require(_conditionSetId > 0 && _conditionSetId < conditionSets.length, "Invalid condition set ID");
        require(conditionSets[_conditionSetId].isActive, "Condition set is not active");
        require(_conditions.length > 0, "Condition set must have at least one condition");

        // Add checks: e.g., ensure no active deposits currently using this set ID, or
        // allow updates only if they don't change the number/type of conditions fundamentally.
        // For this example, we'll allow update, but note the risk.

        conditionSets[_conditionSetId].conditions = _conditions;
         for (uint i = 0; i < _conditions.length; i++) {
            require(supportsConditionType(_conditions[i].conditionType), "Unsupported condition type included");
             // Add specific param validation here based on condition type if needed
        }

        emit ConditionSetUpdated(_conditionSetId);
    }


    /**
     * @notice Allows a user (or potentially anyone paying gas) or an authorized oracle to submit data
     * relevant to fulfilling a specific condition for their deposit.
     * This function triggers the internal verification process for that condition.
     * @param _depositId The ID of the deposit.
     * @param _conditionIndex The index of the condition within the deposit's condition set.
     * @param _submittedData The data relevant to the condition (e.g., a price, a proof verification result).
     */
    function submitDataForCondition(uint256 _depositId, uint256 _conditionIndex, bytes calldata _submittedData) external nonReentrant {
        require(_depositId < userDeposits.length, "Invalid deposit ID");
        Deposit storage deposit = userDeposits[_depositId];
        require(deposit.status == DepositStatus.WithdrawalRequested, "Withdrawal not requested for this deposit");

        uint256 conditionSetId = deposit.conditionSetId;
        require(conditionSetId > 0 && conditionSetId < conditionSets.length, "Invalid condition set ID for deposit");
        ConditionSet storage conditionSet = conditionSets[conditionSetId];
        require(_conditionIndex < conditionSet.conditions.length, "Invalid condition index");

        QuantumCondition storage condition = conditionSet.conditions[_conditionIndex];
        ConditionStatus currentStatus = _depositConditionStatuses[_depositId][_conditionIndex];

        require(currentStatus == ConditionStatus.Pending || currentStatus == ConditionStatus.Failed, "Condition already met or failed");

        // Internal logic to verify the submitted data against the condition
        // This is where the "Quantum" logic happens based on ConditionType
        ConditionStatus newStatus = _verifyCondition(deposit, condition, _submittedData);

        if (newStatus != currentStatus) {
            _depositConditionStatuses[_depositId][_conditionIndex] = newStatus;
            emit ConditionStatusUpdated(_depositId, _conditionIndex, condition.conditionType, newStatus);
        }
    }

    // --- Oracle Integration ---

    /**
     * @notice Owner registers an address as a trusted oracle.
     * @param _oracleAddress The address of the oracle contract/EOA.
     * @param _supportedDataTypes Array of bytes32 identifiers for data/proof types this oracle can provide.
     */
    function registerOracle(address _oracleAddress, bytes32[] calldata _supportedDataTypes) external onlyOwner {
        require(_oracleAddress != address(0), "Invalid oracle address");
        require(oracleAddressToId[_oracleAddress] == 0, "Oracle address already registered"); // Check if default value

        oracleCounter++;
        uint256 newOracleId = oracleCounter;

        registeredOracles[newOracleId] = Oracle({
            oracleAddress: _oracleAddress,
            isActive: true,
            supportedDataTypes: _supportedDataTypes
        });
        oracleAddressToId[_oracleAddress] = newOracleId;

        emit OracleRegistered(newOracleId, _oracleAddress);
    }

    /**
     * @notice Owner deregisters an oracle.
     * @param _oracleId The ID of the oracle to deregister.
     */
    function deregisterOracle(uint256 _oracleId) external onlyOwner {
        require(_oracleId > 0 && _oracleId <= oracleCounter, "Invalid oracle ID");
        require(registeredOracles[_oracleId].isActive, "Oracle is not active");

        registeredOracles[_oracleId].isActive = false;
        // Keep the oracleAddressToId entry to prevent re-registration with ID 0? Or remove it. Let's remove.
        delete oracleAddressToId[registeredOracles[_oracleId].oracleAddress];

        emit OracleDeregistered(_oracleId, registeredOracles[_oracleId].oracleAddress);
    }

     /**
     * @notice Registered oracles call this to submit data.
     * Data submitted here can potentially fulfill ORACLE_ data type conditions or PROOF_VERIFIED conditions.
     * @param _dataTypeHash A hash identifying the type of data being submitted (e.g., keccak256("ETH/USD_Price")).
     * @param _data The actual data bytes.
     */
    function setOracleData(bytes32 _dataTypeHash, bytes calldata _data) external {
        uint256 oracleId = oracleAddressToId[msg.sender];
        require(oracleId > 0 && registeredOracles[oracleId].isActive, "Caller is not an active registered oracle");

        // Optional: Check if the oracle supports this dataTypeHash
        bool supported = false;
        for(uint i = 0; i < registeredOracles[oracleId].supportedDataTypes.length; i++) {
            if (registeredOracles[oracleId].supportedDataTypes[i] == _dataTypeHash) {
                supported = true;
                break;
            }
        }
        require(supported, "Oracle does not support this data type");

        oracleDataStore[oracleId][_dataTypeHash] = OracleDataPoint({
            data: _data,
            timestamp: block.timestamp
        });

        // Note: Condition fulfillment from oracle data is checked when `submitDataForCondition` is called
        // with _submittedData matching oracle data, or when `executeConditionalWithdrawal` is called
        // and it checks against the latest oracle data.
        // A more advanced version might automatically trigger condition checks here.

        emit OracleDataSet(oracleId, _dataTypeHash, _data, block.timestamp);
    }

    /**
     * @notice Owner sets the minimum number of oracle reports needed for consensus (for future multi-oracle features).
     * Not actively used in the current single-oracle _verifyCondition logic, but reserved for future use.
     * @param _threshold The minimum number of oracle reports required.
     */
    function setOracleThreshold(uint256 _threshold) external onlyOwner {
        require(_threshold > 0, "Threshold must be greater than 0");
        oracleDataThreshold = _threshold;
    }


    // --- Admin / Governance Functions ---

    /**
     * @notice Owner sets the fee percentage taken on successful withdrawals.
     * @param _rateBasisPoints New fee rate in basis points (e.g., 50 for 0.5%, 100 for 1%). Max 10000 (100%).
     */
    function setAdminFeeRate(uint256 _rateBasisPoints) external onlyOwner {
        require(_rateBasisPoints <= 10000, "Fee rate cannot exceed 100%");
        adminFeeRateBasisPoints = _rateBasisPoints;
    }

    /**
     * @notice Owner collects accumulated ETH and ERC20 fees.
     * @param _tokenAddress The address of the token to collect fees for (0x0 for ETH).
     */
    function collectFees(IERC20 _tokenAddress) external onlyOwner nonReentrant {
        uint256 ethAmount = 0;
        uint256 tokenAmount = 0;

        if (address(_tokenAddress) == address(0)) {
            // Collect ETH fees
            ethAmount = totalFeesCollectedETH;
            require(ethAmount > 0, "No ETH fees to collect");
            totalFeesCollectedETH = 0; // Reset accumulated fees

            (bool success, ) = payable(owner()).call{value: ethAmount}("");
            require(success, "ETH fee transfer failed");

        } else {
            // Collect ERC20 fees
            tokenAmount = totalFeesCollectedTokens[_tokenAddress];
            require(tokenAmount > 0, "No token fees to collect for this token");
            totalFeesCollectedTokens[_tokenAddress] = 0; // Reset accumulated fees

            _tokenAddress.safeTransfer(owner(), tokenAmount);
        }

        emit FeesCollected(owner(), ethAmount, _tokenAddress, tokenAmount);
    }

    /**
     * @notice Pauses critical contract functions (deposit, withdrawal request, execute).
     * Inherited from Pausable.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses critical contract functions.
     * Inherited from Pausable.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

     /**
     * @notice Owner can forcefully withdraw a specific deposit in case of emergencies (e.g., severe bug, inaccessible oracles).
     * This bypasses all conditions and withdrawal requests. Use with extreme caution.
     * @param _depositId The ID of the deposit to withdraw.
     * @param _recipient The address to send the funds to (typically the original depositor, but can be admin).
     */
    function emergencyWithdrawAdmin(uint256 _depositId, address payable _recipient) external onlyOwner nonReentrant {
        require(_depositId < userDeposits.length, "Invalid deposit ID");
        Deposit storage deposit = userDeposits[_depositId];
        require(deposit.amount > 0, "Deposit already withdrawn or empty");
        require(_recipient != address(0), "Invalid recipient address");

        uint256 amount = deposit.amount;
        deposit.amount = 0; // Mark as withdrawn

        if (deposit.assetType == AssetType.ETH) {
            (bool success, ) = _recipient.call{value: amount}("");
            require(success, "ETH emergency transfer failed");
        } else if (deposit.assetType == AssetType.ERC20) {
            deposit.tokenAddress.safeTransfer(_recipient, amount);
        } else {
             revert("Unknown asset type"); // Should not happen
        }

        // Optional: Mark related withdrawal requests/conditions as cancelled/invalidated
         uint256 reqId = depositToWithdrawalRequest[_depositId];
         if (reqId > 0 && reqId < withdrawalRequests.length) {
             withdrawalRequests[reqId].status = WithdrawalStatus.Cancelled;
         }


        emit EmergencyWithdrawal(_recipient, deposit.assetType == AssetType.ETH ? amount : 0, deposit.tokenAddress, deposit.assetType == AssetType.ERC20 ? amount : 0);
    }

    /**
     * @notice Allows a user to initiate an emergency withdrawal of their deposit after a very long grace period has passed
     * since the deposit time or the last relevant activity (e.g., condition check failure).
     * This is a safety valve if conditions become permanently impossible to meet.
     * @param _depositId The ID of the deposit to withdraw.
     */
    function emergencyWithdrawUser(uint256 _depositId) external whenNotPaused nonReentrant {
        require(_depositId < userDeposits.length, "Invalid deposit ID");
        Deposit storage deposit = userDeposits[_depositId];
        require(deposit.user == msg.sender, "Not your deposit");
        require(deposit.amount > 0, "Deposit already withdrawn or empty");

        // Check the grace period has passed since deposit
        require(block.timestamp >= deposit.depositTime + EMERGENCY_WITHDRAW_GRACE_PERIOD, "Emergency withdrawal grace period not passed");

        // Add more sophisticated check: e.g., check if conditions are permanently failed,
        // or if a withdrawal request has been pending for a long time.
        // For simplicity here, just the deposit time + grace period.

        uint256 amount = deposit.amount;
        deposit.amount = 0; // Mark as withdrawn

         if (deposit.assetType == AssetType.ETH) {
            (bool success, ) = payable(msg.sender).call{value: amount}("");
            require(success, "ETH emergency user transfer failed");
        } else if (deposit.assetType == AssetType.ERC20) {
            deposit.tokenAddress.safeTransfer(msg.sender, amount);
        } else {
             revert("Unknown asset type"); // Should not happen
        }

        // Optional: Mark related withdrawal requests/conditions as cancelled/invalidated
         uint256 reqId = depositToWithdrawalRequest[_depositId];
         if (reqId > 0 && reqId < withdrawalRequests.length) {
             withdrawalRequests[reqId].status = WithdrawalStatus.Cancelled;
         }

        emit EmergencyWithdrawal(msg.sender, deposit.assetType == AssetType.ETH ? amount : 0, deposit.tokenAddress, deposit.assetType == AssetType.ERC20 ? amount : 0);
    }

    // --- View Functions ---

    /**
     * @notice Gets the current total balance held by the contract for a specific asset.
     * @param _tokenAddress The address of the token (0x0 for ETH).
     * @return totalBalance The total amount of the asset in the contract.
     */
    function getTotalPooledBalance(IERC20 _tokenAddress) external view returns (uint256 totalBalance) {
        if (address(_tokenAddress) == address(0)) {
            return address(this).balance;
        } else {
             return _tokenAddress.balanceOf(address(this));
        }
    }

    /**
     * @notice Get details for a specific user deposit.
     * @param _depositId The ID of the deposit.
     * @return deposit Details of the deposit.
     */
    function getUserDepositDetails(uint256 _depositId) external view returns (Deposit memory) {
        require(_depositId < userDeposits.length, "Invalid deposit ID");
        return userDeposits[_depositId];
    }

    /**
     * @notice Get details for a specific withdrawal request.
     * @param _withdrawalRequestId The ID of the withdrawal request.
     * @return request Details of the withdrawal request.
     */
    function getUserWithdrawalRequest(uint256 _withdrawalRequestId) external view returns (WithdrawalRequest memory) {
         require(_withdrawalRequestId > 0 && _withdrawalRequestId < withdrawalRequests.length, "Invalid withdrawal request ID");
         return withdrawalRequests[_withdrawalRequestId];
    }

    /**
     * @notice Gets the details of a condition set.
     * @param _conditionSetId The ID of the condition set.
     * @return conditionSet The ConditionSet struct.
     */
    function getConditionSet(uint256 _conditionSetId) external view returns (ConditionSet memory) {
        require(_conditionSetId > 0 && _conditionSetId < conditionSets.length, "Invalid condition set ID");
        return conditionSets[_conditionSetId];
    }

     /**
     * @notice Gets the current status of all conditions for a specific deposit.
     * @param _depositId The ID of the deposit.
     * @return statuses Array of ConditionStatus for each condition in the set.
     */
    function getConditionStatusForDeposit(uint256 _depositId) external view returns (ConditionStatus[] memory) {
        require(_depositId < userDeposits.length, "Invalid deposit ID");
        // Need to ensure _depositConditionStatuses is initialized for this depositId
        uint256 numConditions = conditionSets[userDeposits[_depositId].conditionSetId].conditions.length;
        ConditionStatus[] memory statuses = new ConditionStatus[](numConditions);
        for(uint i = 0; i < numConditions; i++) {
            statuses[i] = _depositConditionStatuses[_depositId][i];
        }
        return statuses;
    }

    /**
     * @notice Gets the latest data submitted by a specific oracle for a specific data type.
     * @param _oracleId The ID of the oracle.
     * @param _dataTypeHash The hash identifying the data type.
     * @return data The data bytes.
     * @return timestamp The timestamp the data was submitted.
     */
    function getOracleData(uint256 _oracleId, bytes32 _dataTypeHash) external view returns (bytes memory data, uint256 timestamp) {
        require(_oracleId > 0 && _oracleId <= oracleCounter, "Invalid oracle ID");
        OracleDataPoint storage dataPoint = oracleDataStore[_oracleId][_dataTypeHash];
        return (dataPoint.data, dataPoint.timestamp);
    }

    /**
     * @notice Lists all registered oracle IDs and their addresses.
     * Useful for frontends to know which oracles are available.
     * @return oracleIds Array of registered oracle IDs.
     * @return oracleAddresses Array of registered oracle addresses.
     * @return isActive Array of boolean indicating if each oracle is active.
     */
    function getRegisteredOracles() external view returns (uint256[] memory oracleIds, address[] memory oracleAddresses, bool[] memory isActive) {
        oracleIds = new uint256[](oracleCounter);
        oracleAddresses = new address[](oracleCounter);
        isActive = new bool[](oracleCounter);

        for (uint i = 1; i <= oracleCounter; i++) {
            oracleIds[i-1] = i;
            oracleAddresses[i-1] = registeredOracles[i].oracleAddress;
            isActive[i-1] = registeredOracles[i].isActive;
        }
        return (oracleIds, oracleAddresses, isActive);
    }

     /**
     * @notice Returns the current contract version.
     */
    function getVersion() external view returns (string memory) {
        return VERSION;
    }

    /**
     * @notice Returns the current admin fee rate in basis points.
     */
     function getAdminFeeRate() external view returns (uint256) {
        return adminFeeRateBasisPoints;
     }


     /**
     * @notice Checks if a given ConditionType is supported by the contract.
     * Useful for external applications creating condition sets.
     * @param _type The ConditionType enum value.
     * @return isSupported True if the type is supported, false otherwise.
     */
    function supportsConditionType(ConditionType _type) public pure returns (bool isSupported) {
         // Simple switch statement checking against defined enum values
         // In a real contract, this might check against an internal list if types are dynamic
         unchecked { // Use unchecked because we are just checking against known enum bounds
             if (_type < ConditionType.TIME_BASED || _type > ConditionType.PROOF_VERIFIED) {
                 return false; // Check against current min/max enum values
             }
         }
         return true; // If within defined range, assume supported
    }


    // --- Internal Helper Functions ---

    /**
     * @notice Internal function to check if all conditions for a specific deposit are met.
     * This function iterates through the conditions and verifies their status.
     * Note: This function does *not* trigger condition verification, it only checks the current status.
     * Condition status is updated by `submitDataForCondition`.
     * @param _depositId The ID of the deposit.
     * @return allMet True if all conditions are Met, false otherwise or if any Failed.
     */
    function _checkAllConditionsMet(uint256 _depositId) internal view returns (bool allMet) {
        uint256 conditionSetId = userDeposits[_depositId].conditionSetId;
        require(conditionSetId > 0 && conditionSetId < conditionSets.length, "Invalid condition set ID for deposit");
        QuantumCondition[] storage conditions = conditionSets[conditionSetId].conditions;
        ConditionStatus[] storage statuses = _depositConditionStatuses[_depositId]; // Get the array of statuses for this deposit

        require(statuses.length == conditions.length, "Status array length mismatch"); // Sanity check

        for (uint i = 0; i < conditions.length; i++) {
            if (statuses[i] != ConditionStatus.Met) {
                return false; // At least one condition is not met
            }
        }
        return true; // All conditions are marked as Met
    }

     /**
     * @notice Internal function to verify a single condition for a deposit based on submitted data.
     * This contains the core logic for different condition types.
     * @param _deposit The deposit struct.
     * @param _condition The condition struct from the condition set.
     * @param _submittedData The data submitted by the user/oracle.
     * @return newStatus The new status of the condition (Met, Failed, or Pending if verification is incomplete).
     */
    function _verifyCondition(
        Deposit storage _deposit,
        QuantumCondition storage _condition,
        bytes calldata _submittedData
    ) internal view returns (ConditionStatus) {

        // Example logic for different condition types:
        if (_condition.conditionType == ConditionType.TIME_BASED) {
            // Params should be uint64 timestamp (bytes)
            require(_condition.params.length >= 8, "Invalid params for TIME_BASED condition");
            uint64 requiredTimestamp = abi.decode(_condition.params, (uint64));
            // This condition doesn't typically need _submittedData, just checks block.timestamp
            // The call to submitDataForCondition could just be a trigger, with _submittedData empty/ignored.
            if (block.timestamp >= requiredTimestamp) {
                return ConditionStatus.Met;
            } else {
                return ConditionStatus.Pending; // Time not reached yet
            }

        } else if (_condition.conditionType == ConditionType.ORACLE_PRICE_GE) {
            // Params: oracle data type hash (bytes32), price threshold (uint256 as bytes)
            require(_condition.params.length >= 32 + 32, "Invalid params for ORACLE_PRICE_GE"); // bytes32 dataType, uint256 threshold
            (bytes32 dataTypeHash, uint256 threshold) = abi.decode(_condition.params, (bytes32, uint256));

            uint256 oracleId = _condition.associatedOracleId;
            require(oracleId > 0 && registeredOracles[oracleId].isActive, "Associated oracle not active for ORACLE_PRICE_GE");

            OracleDataPoint storage latestData = oracleDataStore[oracleId][dataTypeHash];

             // Need to interpret the oracle data correctly. Assuming price is encoded as uint256.
             require(latestData.data.length >= 32, "Invalid oracle data format for price");
             uint256 price = abi.decode(latestData.data, (uint256));

             // Add timestamp check: require recent data?
             // require(latestData.timestamp > block.timestamp - 300, "Oracle data too old"); // Example: data must be less than 5 minutes old

            if (price >= threshold) {
                return ConditionStatus.Met;
            } else {
                return ConditionStatus.Pending; // Price not met
            }

        } else if (_condition.conditionType == ConditionType.PROOF_VERIFIED) {
             // Params: proof type hash (bytes32)
             require(_condition.params.length >= 32, "Invalid params for PROOF_VERIFIED");
             bytes32 requiredProofTypeHash = abi.decode(_condition.params, (bytes32));

             uint256 verifierOracleId = _condition.associatedOracleId;
             require(verifierOracleId > 0 && registeredOracles[verifierOracleId].isActive, "Associated verifier oracle not active for PROOF_VERIFIED");

             // Here, the _submittedData is expected to be the verification result/signal from the *verifier oracle*.
             // The actual complex ZK proof verification happens off-chain or by the oracle.
             // The oracle submits a simple result (e.g., true/false, or a specific data value) to setOracleData
             // with a specific dataTypeHash (e.g., keccak256("VerificationStatus") + requiredProofTypeHash).
             // OR, the oracle directly calls `submitDataForCondition` with _submittedData indicating verification success.
             // Let's assume the latter: the oracle calls submitDataForCondition, and _submittedData contains a boolean result.

             require(msg.sender == registeredOracles[verifierOracleId].oracleAddress, "Only the designated verifier oracle can submit data for PROOF_VERIFIED");
             require(_submittedData.length == 1, "Invalid submitted data for PROOF_VERIFIED (expected boolean)");
             bool verificationResult = abi.decode(_submittedData, (bool));

             if (verificationResult) {
                 return ConditionStatus.Met;
             } else {
                 // If verification failed, does the condition fail permanently, or can it be re-attempted?
                 // Let's allow re-attempt unless explicitly marked otherwise.
                 return ConditionStatus.Failed; // Or Pending, depending on desired retry logic
             }

        }
        // ... add logic for other condition types ...

        // If condition type is unknown or logic not implemented
        return ConditionStatus.Pending; // Or Failed, depending on default security posture
    }

    // Add more internal helpers as needed, e.g., _calculateFee, etc.
    // Fee calculation is included directly in executeConditionalWithdrawal for clarity.

     // Fallback function to receive ETH
    receive() external payable {
         // ETH sent without calling depositEther goes to the contract balance but isn't tracked as a deposit.
         // Could add a mechanism here to treat unexpected ETH as a generic deposit or reject it.
         // For now, it just adds to the total balance.
         emit DepositMade(0, msg.sender, AssetType.ETH, IERC20(address(0)), msg.value, 0); // Log unexpected ETH, conditionSetId 0
    }
}
```