Okay, let's design a smart contract incorporating several advanced concepts like Zero-Knowledge Proof (ZK-Proof) verification for conditional logic and confidentiality, time-based locks, multi-party access control (beyond simple ownership), and a dynamic fee structure.

We'll call this contract `QuantumVault`. The "Quantum" aspect is a metaphor for the confidential state hidden by ZK proofs until conditions are met ("state collapse"). It will allow users to deposit funds confidentially using commitments and withdraw them only if they can provide a valid ZK proof satisfying certain predefined, verifiable conditions (e.g., proving age, location, identity without revealing specifics) and a valid nullifier. It also includes time-locked withdrawals and role-based access for management and observation.

**Disclaimer:** This contract is a complex example demonstrating advanced concepts. Implementing a production-ready ZK-based system requires significant expertise in cryptography, circuit design, and secure oracle integration (if conditions rely on off-chain data). The ZK proof verification part here assumes the existence of a separate, trusted verifier contract or precompile; the logic focuses on how the *vault* interacts with the verification result.

---

### **QuantumVault Smart Contract**

**Outline:**

1.  **State Variables:** Storage for deposits, nullifiers, condition types, fees, access control roles, pause status, etc.
2.  **Events:** Signify key actions like deposits, withdrawals, condition type management, role changes, state changes.
3.  **Modifiers:** Access control (`onlyOwner`, `onlyManager`, `onlyObserver`), state control (`whenNotPaused`, `whenPaused`).
4.  **Structs:** Define structures for `ConditionType` and `DepositInfo`.
5.  **Constructor:** Initialize owner, potentially set up initial condition types or verifiers.
6.  **Access Control & Roles:** Functions to manage Owner, Managers (can manage condition types, fees, pause), and Observers (can view certain stats even when paused).
7.  **Pause Mechanism:** Functions to pause/unpause core operations.
8.  **Deposit Functions:**
    *   Confidential deposit (ETH/Token) with commitment.
    *   Confidential deposit (ETH/Token) with commitment and time-based lock.
9.  **Withdrawal Functions:**
    *   Execute conditional withdrawal (requires ZK proof, nullifier, public inputs).
    *   Execute time-locked withdrawal (requires ZK proof, nullifier, public inputs, and checks time lock).
10. **ZK Condition Type Management:**
    *   Add, remove, and update definitions for different ZK-provable conditions, linking them to specific verifier contracts.
11. **Fee Management:**
    *   Set and withdraw fees collected from operations.
12. **Query Functions (View):**
    *   Check nullifier status.
    *   Get total deposited amounts.
    *   Get deposit information (non-confidential parts like lock time, status).
    *   Get condition type details.
    *   Check role status.
13. **Emergency Functions:**
    *   Admin-controlled emergency withdrawal of trapped funds (use with extreme caution).

**Function Summary:**

1.  `constructor()`: Initializes contract owner.
2.  `deposit(bytes32 commitment)`: Deposit ETH linked to a unique commitment.
3.  `depositToken(address token, uint256 amount, bytes32 commitment)`: Deposit ERC20 tokens linked to a commitment.
4.  `depositWithLock(bytes32 commitment, uint64 unlockTimestamp)`: Deposit ETH with a time-lock before withdrawal is possible.
5.  `depositTokenWithLock(address token, uint256 amount, bytes32 commitment, uint64 unlockTimestamp)`: Deposit ERC20 tokens with a time-lock.
6.  `addConditionType(uint256 conditionTypeId, address verifierContract, bytes32 conditionIdentifierHash, string memory description)`: Add a new type of ZK-provable condition, linked to a verifier contract and a unique identifier/description.
7.  `removeConditionType(uint256 conditionTypeId)`: Remove an existing condition type.
8.  `updateConditionVerifier(uint256 conditionTypeId, address newVerifierContract)`: Update the ZK verifier contract for a specific condition type.
9.  `executeConditionalWithdrawal(bytes32 nullifier, address recipient, uint256 amount, uint256 conditionTypeId, bytes proofData, uint256[] publicInputs)`: Execute a withdrawal for a specified amount and recipient, requiring a ZK proof that satisfies the condition type and verifies public inputs including nullifier, recipient, amount (or hash/range), etc.
10. `executeLockedWithdrawal(bytes32 nullifier, address recipient, uint256 amount, bytes proofData, uint256[] publicInputs)`: Execute a withdrawal for a time-locked deposit, requiring a ZK proof and ensuring the unlock time has passed (verified via public inputs in proof).
11. `setWithdrawalFee(uint256 fee)`: Set the fee amount charged for each successful withdrawal.
12. `withdrawFees(address token, address recipient)`: Allow manager to withdraw collected fees for a specific token or ETH.
13. `pauseContract()`: Owner can pause core deposit and withdrawal functions.
14. `unpauseContract()`: Owner can unpause the contract.
15. `addManager(address manager)`: Owner adds an address to the Manager role.
16. `removeManager(address manager)`: Owner removes an address from the Manager role.
17. `addObserver(address observer)`: Manager adds an address to the Observer role.
18. `removeObserver(address observer)`: Manager removes an address from the Observer role.
19. `emergencyWithdrawal(address token, uint256 amount, address recipient)`: Owner can withdraw stuck funds (use with caution).
20. `transferOwnership(address newOwner)`: Owner transfers ownership of the contract.
21. `renounceOwnership()`: Owner renounces ownership (sets owner to zero address).
22. `isNullifierUsed(bytes32 nullifier)`: View function to check if a nullifier has been spent.
23. `getTotalDeposited(address token)`: View function to get the total balance held by the vault for a specific token (or address(0) for ETH).
24. `getConditionType(uint256 conditionTypeId)`: View function to retrieve details of a condition type.
25. `isManager(address account)`: View function to check if an address is a Manager.
26. `isObserver(address account)`: View function to check if an address is an Observer.
27. `getDepositInfo(uint256 depositIndex)`: View non-confidential info about a deposit (e.g., unlock time, token, amount range maybe, nullifier status). *Note: Commitment itself is not exposed.*
28. `getCurrentDepositIndex()`: View the next available deposit index.
29. `getWithdrawalFee()`: View the current withdrawal fee.
30. `setMinimumDeposit(uint256 minAmount)`: Set a minimum amount required for deposits.
31. `getMinimumDeposit()`: View the current minimum deposit amount.
32. `withdrawToken(address token, uint256 amount, address recipient)`: Internal helper for token withdrawals.
33. `withdrawETH(uint256 amount, address recipient)`: Internal helper for ETH withdrawals.
34. `_verifyProof(bytes proofData, uint256[] publicInputs, address verifier)`: Internal function to call the external ZK verifier contract.
35. `_processWithdrawal(bytes32 nullifier, address recipient, uint256 amount, address token)`: Internal function to mark nullifier and transfer funds.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Assume a generic interface for a ZK Proof Verifier contract
// In a real implementation, this would match your specific ZK system (e.g., Groth16, Plonk)
// The publicInputs must contain verifiable data like nullifier, recipient, amount/hash, etc.
interface IVerifier {
    function verifyProof(bytes calldata proofData, uint256[] calldata publicInputs) external view returns (bool);
}

contract QuantumVault is ReentrancyGuard {
    using SafeMath for uint256;

    // --- State Variables ---

    address private _owner;
    mapping(address => bool) private _managers;
    mapping(address => bool) private _observers;

    bool public paused = false;
    uint256 public withdrawalFee = 0; // Fee in base units (e.g., wei for ETH, min units for token)
    uint256 public minimumDeposit = 0; // Minimum deposit amount in base units

    // Confidentiality: Map nullifiers to true once used.
    mapping(bytes32 => bool) public usedNullifiers;

    // ZK Condition Types: Define different proof requirements
    struct ConditionType {
        address verifierContract;
        bytes32 conditionIdentifierHash; // A unique hash representing the specific circuit/condition logic
        string description;
        bool exists; // To check if a condition type ID is valid
    }
    mapping(uint256 => ConditionType) public conditionTypes;
    uint256 public nextConditionTypeId = 1; // Start ID from 1

    // Deposit Tracking (Partial, non-confidential info)
    struct DepositInfo {
        address token; // address(0) for ETH
        uint64 unlockTimestamp; // 0 if not time-locked
        bool isNullified; // True if withdrawn using any method
    }
    DepositInfo[] private deposits; // Store minimal info in an array for indexing

    // Total balances (for public viewing)
    mapping(address => uint256) public totalDepositedETH; // address(0) => ETH
    mapping(address => mapping(address => uint256)) public totalDepositedTokens; // tokenAddress => address(0) => amount

    // Fee collection
    mapping(address => uint256) private _collectedFees; // tokenAddress => amount

    // Deposit index counter
    uint256 public depositCounter = 0; // Acts as the next deposit index


    // --- Events ---

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ManagerAdded(address indexed account);
    event ManagerRemoved(address indexed account);
    event ObserverAdded(address indexed account);
    event ObserverRemoved(address indexed account);
    event ContractPaused();
    event ContractUnpaused();
    event Deposit(address indexed token, uint256 amount, bytes32 commitment, uint64 unlockTimestamp, uint256 indexed depositIndex);
    event WithdrawalExecuted(bytes32 indexed nullifier, address indexed recipient, address indexed token, uint256 amount, uint256 conditionTypeId);
    event LockedWithdrawalExecuted(bytes32 indexed nullifier, address indexed recipient, address indexed token, uint256 amount, uint64 unlockTimestamp);
    event ConditionTypeAdded(uint256 indexed conditionTypeId, address indexed verifierContract, bytes32 conditionIdentifierHash);
    event ConditionTypeRemoved(uint256 indexed conditionTypeId);
    event ConditionVerifierUpdated(uint256 indexed conditionTypeId, address indexed oldVerifier, address indexed newVerifier);
    event WithdrawalFeeSet(uint256 oldFee, uint256 newFee);
    event FeesWithdrawn(address indexed token, address indexed recipient, uint256 amount);
    event MinimumDepositSet(uint256 oldMin, uint256 newMin);
    event EmergencyWithdrawal(address indexed token, address indexed recipient, uint256 amount);


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == _owner, "QV: Only owner");
        _;
    }

    modifier onlyManager() {
        require(_managers[msg.sender] || msg.sender == _owner, "QV: Only manager or owner");
        _;
    }

    modifier onlyObserver() {
        require(_observers[msg.sender] || _managers[msg.sender] || msg.sender == _owner, "QV: Only observer, manager, or owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "QV: Paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "QV: Not paused");
        _;
    }


    // --- Constructor ---

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }


    // --- Access Control & Roles ---

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "QV: New owner is zero address");
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function renounceOwnership() external onlyOwner {
        address oldOwner = _owner;
        _owner = address(0);
        emit OwnershipTransferred(oldOwner, address(0));
    }

    function addManager(address account) external onlyOwner {
        require(account != address(0), "QV: Account is zero address");
        require(!_managers[account], "QV: Account is already a manager");
        _managers[account] = true;
        emit ManagerAdded(account);
    }

    function removeManager(address account) external onlyOwner {
        require(account != address(0), "QV: Account is zero address");
        require(_managers[account], "QV: Account is not a manager");
        _managers[account] = false;
        emit ManagerRemoved(account);
    }

    function addObserver(address account) external onlyManager {
        require(account != address(0), "QV: Account is zero address");
        require(!_observers[account], "QV: Account is already an observer");
        _observers[account] = true;
        emit ObserverAdded(account);
    }

    function removeObserver(address account) external onlyManager {
        require(account != address(0), "QV: Account is zero address");
        require(_observers[account], "QV: Account is not an observer");
        _observers[account] = false;
        emit ObserverRemoved(account);
    }


    // --- Pause Mechanism ---

    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }


    // --- Deposit Functions ---

    function deposit(bytes32 commitment) external payable nonReentrant whenNotPaused {
        require(msg.value >= minimumDeposit, "QV: Deposit amount below minimum");

        uint256 index = depositCounter++;
        deposits.push(DepositInfo({
            token: address(0),
            unlockTimestamp: 0, // Not time-locked by default deposit
            isNullified: false
        }));
        // Link commitment (off-chain knowledge) to index (on-chain) if needed, but NOT stored publicly
        // The ZK proof later proves knowledge of commitment and its index

        totalDepositedETH[address(0)] = totalDepositedETH[address(0)].add(msg.value);

        emit Deposit(address(0), msg.value, commitment, 0, index);
    }

    function depositToken(address token, uint256 amount, bytes32 commitment) external nonReentrant whenNotPaused {
        require(token != address(0), "QV: Invalid token address");
        require(amount >= minimumDeposit, "QV: Deposit amount below minimum");
        require(token != address(this), "QV: Cannot deposit vault token"); // Prevent self-locking
        require(amount > 0, "QV: Deposit amount must be greater than 0");

        uint256 index = depositCounter++;
        deposits.push(DepositInfo({
            token: token,
            unlockTimestamp: 0, // Not time-locked
            isNullified: false
        }));

        IERC20 erc20Token = IERC20(token);
        require(erc20Token.transferFrom(msg.sender, address(this), amount), "QV: Token transfer failed");

        totalDepositedTokens[token][address(0)] = totalDepositedTokens[token][address(0)].add(amount);

        emit Deposit(token, amount, commitment, 0, index);
    }

    function depositWithLock(bytes32 commitment, uint64 unlockTimestamp) external payable nonReentrant whenNotPaused {
        require(msg.value >= minimumDeposit, "QV: Deposit amount below minimum");
        require(unlockTimestamp > block.timestamp, "QV: Unlock time must be in the future");

        uint256 index = depositCounter++;
        deposits.push(DepositInfo({
            token: address(0),
            unlockTimestamp: unlockTimestamp,
            isNullified: false
        }));

        totalDepositedETH[address(0)] = totalDepositedETH[address(0)].add(msg.value);

        emit Deposit(address(0), msg.value, commitment, unlockTimestamp, index);
    }

    function depositTokenWithLock(address token, uint256 amount, bytes32 commitment, uint64 unlockTimestamp) external nonReentrant whenNotPaused {
        require(token != address(0), "QV: Invalid token address");
        require(amount >= minimumDeposit, "QV: Deposit amount below minimum");
        require(token != address(this), "QV: Cannot deposit vault token");
        require(amount > 0, "QV: Deposit amount must be greater than 0");
        require(unlockTimestamp > block.timestamp, "QV: Unlock time must be in the future");

        uint256 index = depositCounter++;
        deposits.push(DepositInfo({
            token: token,
            unlockTimestamp: unlockTimestamp,
            isNullified: false
        }));

        IERC20 erc20Token = IERC20(token);
        require(erc20Token.transferFrom(msg.sender, address(this), amount), "QV: Token transfer failed");

        totalDepositedTokens[token][address(0)] = totalDepositedTokens[token][address(0)].add(amount);

        emit Deposit(token, amount, commitment, unlockTimestamp, index);
    }


    // --- Withdrawal Functions ---

    // The ZK proof must prove knowledge of a valid commitment, its associated deposit index,
    // and that the public inputs (nullifier, recipient, amount, condition type ID, conditionIdentifierHash)
    // are derived correctly from the private data.
    // It also must prove the specific condition logic is met.
    function executeConditionalWithdrawal(
        bytes32 nullifier,
        address recipient,
        uint256 amount,
        uint256 conditionTypeId,
        bytes calldata proofData,
        uint256[] calldata publicInputs
    ) external nonReentrant whenNotPaused {
        require(recipient != address(0), "QV: Invalid recipient");
        require(!usedNullifiers[nullifier], "QV: Nullifier already used");

        ConditionType storage condition = conditionTypes[conditionTypeId];
        require(condition.exists, "QV: Invalid condition type");
        require(condition.verifierContract != address(0), "QV: Condition verifier not set");

        // The ZK proof MUST verify that the provided public inputs are consistent
        // with the *private* commitment and condition fulfillment.
        // The public inputs MUST include the nullifier, recipient, amount (or a hash/range of it),
        // the conditionTypeId, and the conditionIdentifierHash from the ConditionType struct
        // to bind the proof to this specific condition logic registered in the contract.
        // A typical ZK proof public input structure for this might be:
        // [ nullifier, hash(recipient, amount), conditionTypeId, uint256(conditionIdentifierHash) ]
        // The exact structure depends on the ZK circuit design.

        require(_verifyProof(proofData, publicInputs, condition.verifierContract), "QV: Invalid ZK proof");

        // The contract doesn't know *which* deposit index corresponds to this withdrawal,
        // only that a valid ZK proof *for some deposit* with this nullifier was provided.
        // We mark the nullifier as used and transfer funds.
        // The ZK proof should ensure that the amount being withdrawn is valid for the proven commitment.

        // Note: This simplistic approach doesn't track which *specific* deposit entry (by index) is being withdrawn.
        // A more complex system might require the ZK proof to also verify knowledge of the deposit index,
        // and potentially update the `deposits[index].isNullified` flag. This adds complexity to the ZK circuit.
        // For this example, we rely solely on the nullifier preventing double spends from the *same commitment*.
        // The proof must also verify the correct deposit type (ETH/Token) and ensure the amount matches.

        uint256 amountAfterFee = amount;
        if (withdrawalFee > 0) {
            amountAfterFee = amount.sub(withdrawalFee, "QV: Amount less than fee");
            _collectedFees[condition.token] = _collectedFees[condition.token].add(withdrawalFee); // Assuming condition struct knows token, or it's encoded in proof/publicInputs
            // Refinement: Token/ETH type should be encoded in the ZK proof public inputs
            // Let's assume publicInputs includes `tokenType` (0 for ETH, address for ERC20) and `actualAmount`
            address tokenType = publicInputs[/* index for token type */]; // Needs definition based on circuit
             _collectedFees[tokenType] = _collectedFees[tokenType].add(withdrawalFee);
        }
        require(amountAfterFee > 0, "QV: Amount after fee is zero or negative");

        _processWithdrawal(nullifier, recipient, amountAfterFee, /* token from public inputs */ address(0) /* Placeholder */); // Pass token from public inputs


        emit WithdrawalExecuted(nullifier, recipient, address(0) /* Placeholder */, amountAfterFee, conditionTypeId); // Emit correct token
    }

     // The ZK proof for locked withdrawals must additionally prove that the deposit's
     // unlock timestamp (from deposit info linked privately via index/commitment) <= block.timestamp.
     // Public inputs must include the nullifier, recipient, amount/hash, and the unlock timestamp.
    function executeLockedWithdrawal(
        bytes32 nullifier,
        address recipient,
        uint256 amount,
        bytes calldata proofData,
        uint256[] calldata publicInputs // MUST include unlock timestamp and token type
    ) external nonReentrant whenNotPaused {
        require(recipient != address(0), "QV: Invalid recipient");
        require(!usedNullifiers[nullifier], "QV: Nullifier already used");

        // Assuming publicInputs structure includes:
        // [ nullifier, hash(recipient, amount), tokenType (0 for ETH, address for ERC20), unlockTimestamp ]
        // The ZK proof verifies these are consistent with private deposit data AND the condition logic.

        // Find the index of the unlockTimestamp and token type in publicInputs based on your circuit
        // Example indices (replace with actual circuit structure):
        // uint256 unlockTimestampFromProof = publicInputs[/* index for unlock timestamp */];
        // address tokenTypeFromProof = address(uint160(publicInputs[/* index for token type */]));

        // require(unlockTimestampFromProof <= block.timestamp, "QV: Deposit is still locked");
        // This check should ideally happen *inside* the ZK proof for enhanced privacy,
        // proving `privateUnlockTimestamp <= publicBlockTimestamp`.
        // If the proof proves this, we only need to verify the proof itself.
        // If the proof *outputs* the unlock timestamp as a public input, the contract must check it.
        // Let's assume the proof VERIFIES the timestamp privately and the output publicInputs
        // structure is just [ nullifier, hash(recipient, amount), tokenType ].
        // In this case, the ZK proof circuit MUST incorporate the time check.
        // If the unlock timestamp IS a public input, the circuit must verify privateTimestamp == publicTimestamp AND publicTimestamp <= block.timestamp.
        // Let's assume the simpler case where the proof just proves it was withdrawable *now*.

        // We need a generic verifier or a specific one for locked withdrawals.
        // Let's assume a specific condition type ID 0 is reserved for generic locked withdrawals.
        uint265 conditionTypeId = 0; // Reserved ID for generic time-locked withdrawal
        ConditionType storage condition = conditionTypes[conditionTypeId];
        require(condition.exists && condition.verifierContract != address(0), "QV: Locked withdrawal condition type not set");

        // The ZK proof for locked withdrawal MUST verify knowledge of a locked deposit with the nullifier,
        // prove privateUnlockTimestamp <= block.timestamp (passed as public input or internal to proof),
        // and verify public inputs (nullifier, recipient, amount/hash, tokenType).

        require(_verifyProof(proofData, publicInputs, condition.verifierContract), "QV: Invalid ZK proof");

        uint256 amountAfterFee = amount;
        // Get token type from public inputs (needs indexing based on circuit)
        address tokenTypeFromProof = address(0); // Placeholder, get from publicInputs

        if (withdrawalFee > 0) {
             amountAfterFee = amount.sub(withdrawalFee, "QV: Amount less than fee");
             _collectedFees[tokenTypeFromProof] = _collectedFees[tokenTypeFromProof].add(withdrawalFee);
        }
         require(amountAfterFee > 0, "QV: Amount after fee is zero or negative");

        _processWithdrawal(nullifier, recipient, amountAfterFee, tokenTypeFromProof);

         // Get unlock timestamp from public inputs if it was included
        uint64 unlockTimestampFromProof = 0; // Placeholder, get from publicInputs if available

        emit LockedWithdrawalExecuted(nullifier, recipient, tokenTypeFromProof, amountAfterFee, unlockTimestampFromProof);
    }


    // --- ZK Condition Type Management ---

    function addConditionType(uint256 conditionTypeId, address verifierContract, bytes32 conditionIdentifierHash, string memory description) external onlyManager {
        require(conditionTypeId > 0, "QV: Condition ID 0 is reserved");
        require(!conditionTypes[conditionTypeId].exists, "QV: Condition type ID already exists");
        require(verifierContract != address(0), "QV: Verifier address is zero");
        // require identifierHash is unique? Could add a mapping for this.

        conditionTypes[conditionTypeId] = ConditionType({
            verifierContract: verifierContract,
            conditionIdentifierHash: conditionIdentifierHash,
            description: description,
            exists: true
        });

        // Ensure reserved type 0 exists for locked withdrawals if not manually added
        if (conditionTypeId == 0 && !conditionTypes[0].exists) {
             conditionTypes[0] = ConditionType({ // Placeholder for generic locked withdrawal verifier
                verifierContract: address(0), // Needs to be set separately
                conditionIdentifierHash: bytes32(0),
                description: "Reserved: Generic Time-Locked Withdrawal",
                exists: true
            });
        }


        emit ConditionTypeAdded(conditionTypeId, verifierContract, conditionIdentifierHash);
    }

    function removeConditionType(uint256 conditionTypeId) external onlyManager {
        require(conditionTypeId > 0, "QV: Cannot remove reserved ID 0");
        require(conditionTypes[conditionTypeId].exists, "QV: Condition type ID does not exist");

        delete conditionTypes[conditionTypeId]; // Reset struct to default values
        // Note: existing deposits linked conceptually to this condition can no longer be withdrawn conditionally via this type.

        emit ConditionTypeRemoved(conditionTypeId);
    }

     function updateConditionVerifier(uint256 conditionTypeId, address newVerifierContract) external onlyManager {
        require(conditionTypes[conditionTypeId].exists, "QV: Condition type ID does not exist");
        require(newVerifierContract != address(0), "QV: New verifier address is zero");
        require(conditionTypes[conditionTypeId].verifierContract != newVerifierContract, "QV: New verifier is same as current");

        address oldVerifier = conditionTypes[conditionTypeId].verifierContract;
        conditionTypes[conditionTypeId].verifierContract = newVerifierContract;

        emit ConditionVerifierUpdated(conditionTypeId, oldVerifier, newVerifierContract);
    }


    // --- Fee Management ---

    function setWithdrawalFee(uint256 fee) external onlyManager {
        require(fee >= 0, "QV: Fee cannot be negative"); // uint256 prevents negative, good practice check
        uint256 oldFee = withdrawalFee;
        withdrawalFee = fee;
        emit WithdrawalFeeSet(oldFee, fee);
    }

    function withdrawFees(address token, address recipient) external onlyManager nonReentrant {
        require(recipient != address(0), "QV: Invalid recipient");
        uint256 amount = _collectedFees[token];
        require(amount > 0, "QV: No fees collected for this token");

        _collectedFees[token] = 0; // Reset collected fees for this token

        if (token == address(0)) {
            // Withdraw ETH
            _withdrawETH(amount, recipient);
        } else {
            // Withdraw ERC20
            _withdrawToken(token, amount, recipient);
        }

        emit FeesWithdrawn(token, recipient, amount);
    }


    // --- General Settings ---

     function setMinimumDeposit(uint256 minAmount) external onlyManager {
        uint256 oldMin = minimumDeposit;
        minimumDeposit = minAmount;
        emit MinimumDepositSet(oldMin, minAmount);
     }


    // --- Emergency Functions ---

    function emergencyWithdrawal(address token, uint256 amount, address recipient) external onlyOwner nonReentrant {
        require(recipient != address(0), "QV: Invalid recipient");
        require(amount > 0, "QV: Withdrawal amount must be > 0");

        if (token == address(0)) {
             require(amount <= address(this).balance, "QV: Insufficient ETH balance for emergency withdrawal");
             _withdrawETH(amount, recipient);
             // Note: This doesn't update totalDepositedETH, as it's an emergency
        } else {
            IERC20 erc20Token = IERC20(token);
            require(amount <= erc20Token.balanceOf(address(this)), "QV: Insufficient token balance for emergency withdrawal");
            _withdrawToken(token, amount, recipient);
             // Note: This doesn't update totalDepositedTokens, as it's an emergency
        }

        emit EmergencyWithdrawal(token, recipient, amount);
    }


    // --- Query Functions (View) ---

    function isNullifierUsed(bytes32 nullifier) external view returns (bool) {
        return usedNullifiers[nullifier];
    }

    // This function is public, but only Observers+ can query it if paused
    function getTotalDeposited(address token) external view onlyObserver returns (uint256) {
         if (token == address(0)) {
            return totalDepositedETH[address(0)];
        } else {
            return totalDepositedTokens[token][address(0)];
        }
    }

    function getConditionType(uint256 conditionTypeId) external view returns (ConditionType memory) {
        return conditionTypes[conditionTypeId];
    }

    function isManager(address account) external view returns (bool) {
        return _managers[account];
    }

    function isObserver(address account) external view returns (bool) {
        return _observers[account];
    }

    // Provides non-confidential information about a specific deposit index.
    // Users need to know their deposit index off-chain, or find it from the Deposit event.
    // Commitment itself is NOT retrievable here.
    function getDepositInfo(uint256 depositIndex) external view returns (DepositInfo memory) {
        require(depositIndex < deposits.length, "QV: Invalid deposit index");
        return deposits[depositIndex];
    }

     function getCurrentDepositIndex() external view returns (uint256) {
        return depositCounter;
     }

     function getWithdrawalFee() external view returns (uint256) {
        return withdrawalFee;
     }

      function getMinimumDeposit() external view returns (uint256) {
        return minimumDeposit;
     }


    // --- Internal Helper Functions ---

    // Internal function to verify the ZK proof by calling an external verifier contract
    // This assumes the verifier contract exposes a standard interface
    function _verifyProof(bytes calldata proofData, uint256[] calldata publicInputs, address verifier) internal view returns (bool) {
        require(verifier != address(0), "QV: Verifier address is zero");
        IVerifier verifierContract = IVerifier(verifier);
        return verifierContract.verifyProof(proofData, publicInputs);
    }

    // Internal function to mark nullifier as used and transfer funds
    function _processWithdrawal(bytes32 nullifier, address recipient, uint256 amount, address token) internal {
         usedNullifiers[nullifier] = true; // Mark nullifier as spent

         // Note: This doesn't update totalDeposited based on *which* specific deposit was spent.
         // The ZK proof circuit must ensure the total amount withdrawn via nullifiers
         // does not exceed the total amount deposited with corresponding commitments.
         // More advanced circuits or off-chain tracking might be needed for precise balance tracking.
         // For simplicity here, we just ensure the contract HAS the balance.

        if (token == address(0)) {
            _withdrawETH(amount, recipient);
        } else {
            _withdrawToken(token, amount, recipient);
        }

         // Optional: Update deposit status if deposit index was verified in the proof and passed publicly
         // For this design, we assume the nullifier is sufficient to prevent double-spending from the *same private commitment*.
         // If the proof included depositIndex as public input, you could do:
         // uint256 depositIndexFromProof = publicInputs[/* index */];
         // require(depositIndexFromProof < deposits.length, "QV: Invalid deposit index from proof");
         // require(!deposits[depositIndexFromProof].isNullified, "QV: Deposit already nullified");
         // deposits[depositIndexFromProof].isNullified = true;
         // This adds complexity to the ZK circuit and public inputs.

    }

    // Safely withdraw ETH
    function _withdrawETH(uint256 amount, address recipient) internal {
        (bool success, ) = payable(recipient).call{value: amount}("");
        require(success, "QV: ETH withdrawal failed");
    }

    // Safely withdraw ERC20 tokens
    function _withdrawToken(address token, uint256 amount, address recipient) internal {
         IERC20 erc20Token = IERC20(token);
         require(erc20Token.transfer(recipient, amount), "QV: Token withdrawal failed");
    }

    // Fallback and Receive to accept ETH deposits
    receive() external payable {
        // Can potentially link received ETH to a deposit function call
        // For simplicity, require explicit deposit calls or handle here generically
        // Adding a requirement here forces explicit deposits:
        revert("QV: ETH received without calling deposit");
    }

    fallback() external payable {
        revert("QV: Call to non-existent function or unsolicited ETH");
    }

}
```