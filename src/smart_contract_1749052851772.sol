Okay, here is a Solidity smart contract called `QuantumVault`. The concept is a vault that holds Ether and allows deposits and withdrawals based on various complex, time-based, or condition-based rules, incorporating ideas like simulated oracle interactions for conditions, soulbound-like concepts for deposits, programmable withdrawal rules, and on-chain simulation/prediction features.

This contract is designed to showcase a variety of function types and moderately advanced concepts without relying directly on standard OpenZeppelin libraries (except implicitly for common patterns like ownership, which is implemented manually here for differentiation) or duplicating well-known protocols.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- QuantumVault Smart Contract Outline ---
// A vault for Ether with complex, conditional, and time-based deposit/withdrawal mechanics.
// Incorporates simulated external conditions, programmable withdrawal rules,
// and a basic on-chain withdrawal simulation feature.

// --- Function Summary ---
// 1. constructor(): Sets the contract owner.
// 2. receive(): Allows simple Ether deposits into the general balance.
// 3. depositConditional(bytes32 conditionHash, uint256 conditionExpiration): Deposits Ether locked until a specific external condition is met AND before its expiration.
// 4. depositTimed(uint256 unlockTimestamp): Deposits Ether locked until a specific timestamp is reached.
// 5. depositSoulbound(address user): Deposits Ether conceptually linked to a user's address, potentially restricting transferability based on future rules (conceptually soulbound within the vault context).
// 6. withdraw(uint256 amount): Allows withdrawal from the general unlocked balance.
// 7. withdrawTimed(uint256 depositId): Attempts to withdraw a timed deposit after its unlock time.
// 8. withdrawConditional(uint256 depositId): Attempts to withdraw a conditional deposit if its condition is met and not expired.
// 9. withdrawWithRule(uint256 depositId, bytes memory ruleExecutionProof): Attempts to withdraw a deposit governed by a custom rule, requiring external proof of rule satisfaction.
// 10. cancelConditionalDeposit(uint256 depositId): Allows the depositor to cancel a conditional deposit before the condition is met (optional clawback/penalty could be added).
// 11. extendTimedLock(uint256 depositId, uint256 newUnlockTimestamp): Allows the depositor to extend the unlock time of a timed deposit.
// 12. setConditionStatus(bytes32 conditionHash, bool status): (Admin/Oracle) Sets the status of a specific external condition (simulated oracle interaction).
// 13. defineWithdrawalRule(bytes32 ruleHash, bytes memory ruleLogicDefinition): (Admin) Defines a custom withdrawal rule identified by a hash, storing its conceptual logic/definition.
// 14. applyRuleToDeposit(uint256 depositId, bytes32 ruleHash): Allows the depositor to associate a previously defined rule with their specific deposit.
// 15. simulateWithdrawal(uint256 depositId, bytes memory ruleExecutionProof): (View) Simulates the execution of a withdrawal attempt for a specific deposit and rule, checking if it would succeed without altering state.
// 16. checkConditionMet(bytes32 conditionHash): (View) Checks if a specific condition has been marked as met.
// 17. getDepositDetails(uint256 depositId): (View) Retrieves details about a specific deposit.
// 18. getUserDepositIds(address user): (View) Gets a list of deposit IDs associated with a user.
// 19. getTotalVaultBalance(): (View) Gets the total Ether balance held by the contract.
// 20. getUnlockedBalance(address user): (View) Gets the user's balance available for simple withdrawal.
// 21. getConditionalLockedBalance(bytes32 conditionHash): (View) Gets the total Ether locked under a specific conditional hash.
// 22. getTimedLockedBalance(uint256 unlockTimestamp): (View) Gets the total Ether locked until a specific timestamp.
// 23. getRuleLogicDefinition(bytes32 ruleHash): (View) Retrieves the stored definition bytes for a specific withdrawal rule.
// 24. isDepositSoulbound(uint256 depositId): (View) Checks if a specific deposit was marked as soulbound.
// 25. getConditionExpiration(bytes32 conditionHash): (View) Gets the expiration timestamp for a condition.
// 26. getDepositCount(): (View) Returns the total number of deposits made.
// 27. owner: (View) Returns the contract owner.
// 28. oracleAddress: (View) Returns the address designated as the oracle (can update conditions).

contract QuantumVault {

    address public owner;
    address public oracleAddress; // Address authorized to set condition status

    // Represents different types of deposits in the vault
    enum DepositType {
        Standard,       // Simply deposited Ether, immediately withdrawable
        Timed,          // Locked until a specific timestamp
        Conditional,    // Locked until a specific external condition is met
        Soulbound       // Conceptually linked to the user, potential future rule implications
    }

    // Struct to hold details of each unique deposit
    struct Deposit {
        address payable depositor; // Use payable for potential direct refunds
        uint256 amount;
        DepositType depositType;
        uint256 unlockTimestamp; // Used for Timed deposits (0 if not Timed)
        bytes32 conditionHash;   // Used for Conditional deposits (bytes32(0) if not Conditional)
        bytes32 withdrawalRuleHash; // Optional rule applied to this deposit
        bool isActive;           // True if the deposit is still active in the vault
        bool isSoulbound;        // Flag for Soulbound deposits
    }

    // Mappings to store data
    uint256 private nextDepositId; // Counter for unique deposit IDs
    mapping(uint256 => Deposit) public deposits; // Stores deposit details by ID
    mapping(address => uint256[]) private userDepositIds; // Stores list of deposit IDs per user
    mapping(address => uint256) private unlockedBalances; // Standard balance for simple withdrawal
    mapping(bytes32 => bool) private conditionStatus; // Status of external conditions (true if met)
    mapping(bytes32 => uint256) private conditionExpirations; // Expiration timestamp for conditions
    mapping(bytes32 => bytes) private withdrawalRules; // Stores conceptual logic/definitions for withdrawal rules

    // Events for transparency
    event DepositMade(uint256 indexed depositId, address indexed depositor, uint256 amount, DepositType depositType);
    event WithdrawalMade(uint256 indexed depositId, address indexed withdrawer, uint256 amount, DepositType depositType);
    event UnlockedWithdrawal(address indexed withdrawer, uint256 amount);
    event ConditionStatusUpdated(bytes32 indexed conditionHash, bool status);
    event WithdrawalRuleDefined(bytes32 indexed ruleHash);
    event RuleAppliedToDeposit(uint256 indexed depositId, bytes32 indexed ruleHash);
    event DepositCancelled(uint256 indexed depositId);
    event TimedLockExtended(uint256 indexed depositId, uint256 newUnlockTimestamp);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress || msg.sender == owner, "Only oracle or owner can call this function");
        _;
    }

    // --- Constructor ---
    /// @dev Initializes the contract setting the owner.
    constructor() {
        owner = msg.sender;
        oracleAddress = msg.sender; // Initially set owner as oracle, can be changed
    }

    // --- Core Deposit Functions ---

    /// @dev Fallback receive function for simple Ether deposits. Adds to the user's unlocked balance.
    receive() external payable {
        unlockedBalances[msg.sender] += msg.value;
        emit DepositMade(0, msg.sender, msg.value, DepositType.Standard); // Use 0 for standard deposits
    }

    /// @dev Deposits Ether locked until a specific external condition is met and not expired.
    /// @param conditionHash A unique identifier for the external condition.
    /// @param conditionExpiration The timestamp when the condition becomes invalid/expires.
    function depositConditional(bytes32 conditionHash, uint256 conditionExpiration) external payable {
        require(msg.value > 0, "Cannot deposit 0 Ether");
        require(conditionHash != bytes32(0), "Invalid condition hash");
        require(conditionExpiration > block.timestamp, "Condition expiration must be in the future");

        uint256 depositId = nextDepositId++;
        deposits[depositId] = Deposit({
            depositor: payable(msg.sender),
            amount: msg.value,
            depositType: DepositType.Conditional,
            unlockTimestamp: 0, // Not time-locked
            conditionHash: conditionHash,
            withdrawalRuleHash: bytes32(0), // No rule applied initially
            isActive: true,
            isSoulbound: false
        });
        userDepositIds[msg.sender].push(depositId);

        // Store condition expiration if this is the first deposit for this hash or if it's an earlier expiration
        if (conditionExpirations[conditionHash] == 0 || conditionExpiration < conditionExpirations[conditionHash]) {
             conditionExpirations[conditionHash] = conditionExpiration;
        }


        emit DepositMade(depositId, msg.sender, msg.value, DepositType.Conditional);
    }

    /// @dev Deposits Ether locked until a specific timestamp.
    /// @param unlockTimestamp The timestamp when the deposit becomes withdrawable.
    function depositTimed(uint256 unlockTimestamp) external payable {
        require(msg.value > 0, "Cannot deposit 0 Ether");
        require(unlockTimestamp > block.timestamp, "Unlock time must be in the future");

        uint256 depositId = nextDepositId++;
        deposits[depositId] = Deposit({
            depositor: payable(msg.sender),
            amount: msg.value,
            depositType: DepositType.Timed,
            unlockTimestamp: unlockTimestamp,
            conditionHash: bytes32(0), // Not condition-locked
            withdrawalRuleHash: bytes32(0), // No rule applied initially
            isActive: true,
            isSoulbound: false
        });
        userDepositIds[msg.sender].push(depositId);

        emit DepositMade(depositId, msg.sender, msg.value, DepositType.Timed);
    }

    /// @dev Deposits Ether conceptually linked to the user, marked as soulbound.
    /// Requires explicit withdrawal via a function that respects this flag (e.g., withdrawWithRule).
    function depositSoulbound() external payable {
         require(msg.value > 0, "Cannot deposit 0 Ether");

        uint256 depositId = nextDepositId++;
        deposits[depositId] = Deposit({
            depositor: payable(msg.sender),
            amount: msg.value,
            depositType: DepositType.Soulbound,
            unlockTimestamp: 0,
            conditionHash: bytes32(0),
            withdrawalRuleHash: bytes32(0),
            isActive: true,
            isSoulbound: true // Marked as soulbound
        });
        userDepositIds[msg.sender].push(depositId);

        emit DepositMade(depositId, msg.sender, msg.value, DepositType.Soulbound);
    }

    // --- Core Withdrawal Functions ---

    /// @dev Withdraws Ether from the user's general unlocked balance.
    /// @param amount The amount of Ether to withdraw.
    function withdraw(uint256 amount) external {
        require(amount > 0, "Cannot withdraw 0 Ether");
        require(unlockedBalances[msg.sender] >= amount, "Insufficient unlocked balance");

        unlockedBalances[msg.sender] -= amount;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "ETH transfer failed");

        emit UnlockedWithdrawal(msg.sender, amount);
    }

    /// @dev Attempts to withdraw a Timed deposit.
    /// Requires the deposit to be active, owned by the caller, and the unlock time to have passed.
    /// @param depositId The ID of the deposit to withdraw.
    function withdrawTimed(uint256 depositId) external {
        Deposit storage deposit = deposits[depositId];
        require(deposit.isActive, "Deposit not active");
        require(deposit.depositor == msg.sender, "Not your deposit");
        require(deposit.depositType == DepositType.Timed, "Deposit is not Timed type");
        require(block.timestamp >= deposit.unlockTimestamp, "Timed lock not expired yet");

        uint256 amount = deposit.amount;
        deposit.isActive = false; // Mark as inactive
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "ETH transfer failed");

        emit WithdrawalMade(depositId, msg.sender, amount, DepositType.Timed);
    }

    /// @dev Attempts to withdraw a Conditional deposit.
    /// Requires the deposit to be active, owned by the caller, the condition to be met, and not expired.
    /// @param depositId The ID of the deposit to withdraw.
    function withdrawConditional(uint256 depositId) external {
        Deposit storage deposit = deposits[depositId];
        require(deposit.isActive, "Deposit not active");
        require(deposit.depositor == msg.sender, "Not your deposit");
        require(deposit.depositType == DepositType.Conditional, "Deposit is not Conditional type");
        require(conditionStatus[deposit.conditionHash], "Condition not met yet");
        require(block.timestamp < conditionExpirations[deposit.conditionHash], "Condition has expired");

        uint256 amount = deposit.amount;
        deposit.isActive = false; // Mark as inactive
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "ETH transfer failed");

        emit WithdrawalMade(depositId, msg.sender, amount, DepositType.Conditional);
    }

    /// @dev Attempts to withdraw a deposit governed by a specific withdrawal rule.
    /// Requires the deposit to be active, owned by the caller, have the rule applied,
    /// and assumes an external process validates the rule based on the provided proof.
    /// NOTE: The contract doesn't execute arbitrary rule logic. The `ruleExecutionProof`
    /// is conceptual; in a real system, this would involve ZK proofs, oracle calls,
    /// or complex on-chain state checks *validated* by the contract logic.
    /// Here, it requires the `conditionStatus` linked by the rule (if any) AND the proof parameter.
    /// @param depositId The ID of the deposit to withdraw.
    /// @param ruleExecutionProof Conceptual proof that the rule's requirements are met externally.
    function withdrawWithRule(uint256 depositId, bytes memory ruleExecutionProof) external {
        Deposit storage deposit = deposits[depositId];
        require(deposit.isActive, "Deposit not active");
        require(deposit.depositor == msg.sender, "Not your deposit");
        require(deposit.withdrawalRuleHash != bytes32(0), "No withdrawal rule applied to this deposit");
        // require(withdrawalRules[deposit.withdrawalRuleHash].length > 0, "Applied rule does not exist"); // Optional: check if rule definition exists

        // ### Advanced Concept Simulation ###
        // This is where complex validation based on the ruleLogicDefinition and proof would occur.
        // For this example, we'll simulate a check:
        // - If the rule implies a condition (e.g., ruleLogicDefinition indicates a linked conditionHash), check that condition status and expiration.
        // - A real implementation might verify a ZK proof against the rule logic,
        //   or require a signed message from an oracle based on the rule logic, etc.
        // - The `ruleExecutionProof` parameter serves as a placeholder for this external validation result.
        // - We'll add a simple check related to conditions if the deposit *also* had a condition hash.
        if (deposit.conditionHash != bytes32(0)) {
             require(conditionStatus[deposit.conditionHash], "Rule check failed: Linked condition not met");
             require(block.timestamp < conditionExpirations[deposit.conditionHash], "Rule check failed: Linked condition has expired");
        }
        // Add other checks based on the `ruleExecutionProof` in a real scenario.
        // require(verifyProof(ruleExecutionProof, deposit.withdrawalRuleHash, deposit.depositor), "Proof verification failed"); // Conceptual check

        // For this example, we proceed if basic checks pass and the proof is non-empty (simple placeholder)
        require(ruleExecutionProof.length > 0, "Rule execution proof is required"); // Placeholder validation


        uint256 amount = deposit.amount;
        deposit.isActive = false; // Mark as inactive
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "ETH transfer failed");

        emit WithdrawalMade(depositId, msg.sender, amount, deposit.depositType); // Use original deposit type
    }


    // --- Deposit Management Functions ---

    /// @dev Allows the depositor to cancel a Conditional deposit before the condition is met or expired.
    /// The Ether is returned to the depositor.
    /// @param depositId The ID of the conditional deposit to cancel.
    function cancelConditionalDeposit(uint256 depositId) external {
        Deposit storage deposit = deposits[depositId];
        require(deposit.isActive, "Deposit not active");
        require(deposit.depositor == msg.sender, "Not your deposit");
        require(deposit.depositType == DepositType.Conditional, "Deposit is not Conditional type");
        require(!conditionStatus[deposit.conditionHash], "Condition already met, cannot cancel");
        require(block.timestamp < conditionExpirations[deposit.conditionHash], "Condition has expired, cannot cancel");

        uint256 amount = deposit.amount;
        deposit.isActive = false; // Mark as inactive
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "ETH transfer failed");

        emit DepositCancelled(depositId);
    }

    /// @dev Allows the depositor to extend the unlock timestamp of a Timed deposit.
    /// @param depositId The ID of the timed deposit.
    /// @param newUnlockTimestamp The new timestamp, must be in the future and greater than the current unlock time.
    function extendTimedLock(uint256 depositId, uint256 newUnlockTimestamp) external {
        Deposit storage deposit = deposits[depositId];
        require(deposit.isActive, "Deposit not active");
        require(deposit.depositor == msg.sender, "Not your deposit");
        require(deposit.depositType == DepositType.Timed, "Deposit is not Timed type");
        require(newUnlockTimestamp > block.timestamp, "New unlock time must be in the future");
        require(newUnlockTimestamp > deposit.unlockTimestamp, "New unlock time must be after the current unlock time");

        deposit.unlockTimestamp = newUnlockTimestamp;
        emit TimedLockExtended(depositId, newUnlockTimestamp);
    }


    // --- Admin/Oracle Functions ---

    /// @dev Allows the owner or oracle address to set the status of an external condition.
    /// This simulates an oracle reporting the outcome of a condition.
    /// @param conditionHash The hash of the condition to update.
    /// @param status The new status of the condition (true if met).
    function setConditionStatus(bytes32 conditionHash, bool status) external onlyOracle {
        require(conditionHash != bytes32(0), "Invalid condition hash");
        // Optionally, add require(conditionExpirations[conditionHash] > block.timestamp) to prevent setting status after expiration
        conditionStatus[conditionHash] = status;
        emit ConditionStatusUpdated(conditionHash, status);
    }

    /// @dev Allows the owner to define a conceptual withdrawal rule.
    /// The `ruleLogicDefinition` is stored bytes representing the rule's requirements or logic.
    /// This is for storage and reference; the contract doesn't execute arbitrary bytes.
    /// @param ruleHash A unique identifier for the rule.
    /// @param ruleLogicDefinition Bytes representing the rule's logic or criteria.
    function defineWithdrawalRule(bytes32 ruleHash, bytes memory ruleLogicDefinition) external onlyOwner {
        require(ruleHash != bytes32(0), "Invalid rule hash");
        // require(withdrawalRules[ruleHash].length == 0, "Rule already defined"); // Prevent redefining
        withdrawalRules[ruleHash] = ruleLogicDefinition;
        emit WithdrawalRuleDefined(ruleHash);
    }

     /// @dev Allows the owner to set the address authorized to update condition statuses.
    /// @param _oracleAddress The new oracle address.
    function setOracleAddress(address _oracleAddress) external onlyOwner {
        require(_oracleAddress != address(0), "Oracle address cannot be zero");
        oracleAddress = _oracleAddress;
    }

    /// @dev Allows the owner to transfer contract ownership.
    /// @param newOwner The address of the new owner.
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address");
        owner = newOwner;
    }

    // --- Rule Management Functions ---

    /// @dev Allows a depositor to apply a previously defined withdrawal rule to their deposit.
    /// This makes the deposit potentially withdrawable via `withdrawWithRule`.
    /// @param depositId The ID of the deposit to apply the rule to.
    /// @param ruleHash The hash of the rule to apply.
    function applyRuleToDeposit(uint256 depositId, bytes32 ruleHash) external {
         Deposit storage deposit = deposits[depositId];
         require(deposit.isActive, "Deposit not active");
         require(deposit.depositor == msg.sender, "Not your deposit");
         require(deposit.withdrawalRuleHash == bytes32(0), "Rule already applied to this deposit");
         require(withdrawalRules[ruleHash].length > 0, "Rule definition does not exist"); // Rule must be defined first

         deposit.withdrawalRuleHash = ruleHash;
         emit RuleAppliedToDeposit(depositId, ruleHash);
    }


    // --- Simulation / Prediction Functions ---

    /// @dev Simulates a withdrawal attempt without changing state.
    /// Allows a user to check if `withdrawWithRule` would succeed given a deposit ID and a conceptual proof.
    /// This function replicates the checks within `withdrawWithRule`.
    /// @param depositId The ID of the deposit to simulate withdrawal for.
    /// @param ruleExecutionProof Conceptual proof used in the actual withdrawal attempt.
    /// @return success True if the withdrawal would succeed based on current state and proof, false otherwise.
    function simulateWithdrawal(uint256 depositId, bytes memory ruleExecutionProof) external view returns (bool success) {
        // Replicate checks from withdrawWithRule
        Deposit storage deposit = deposits[depositId];
        if (!deposit.isActive) return false;
        if (deposit.depositor != msg.sender) return false; // Or maybe check *any* address for simulation? Let's stick to depositor for security model consistency.
        if (deposit.withdrawalRuleHash == bytes32(0)) return false;
        // if (withdrawalRules[deposit.withdrawalRuleHash].length == 0) return false; // Check if rule definition exists

        // Simulate the complex validation part
        if (deposit.conditionHash != bytes32(0)) {
             if (!conditionStatus[deposit.conditionHash]) return false;
             if (block.timestamp >= conditionExpirations[deposit.conditionHash]) return false;
        }

        // Simulate checking the conceptual proof - here, just check if it's non-empty as a placeholder
        if (ruleExecutionProof.length == 0) return false; // Proof required

        // If all checks pass, the withdrawal would conceptually succeed
        return true;
    }


    // --- View/Query Functions (20+ functions total including these) ---

    /// @dev Checks if a specific external condition has been marked as met.
    /// @param conditionHash The hash of the condition.
    /// @return bool True if the condition is met, false otherwise.
    function checkConditionMet(bytes32 conditionHash) external view returns (bool) {
        return conditionStatus[conditionHash];
    }

    /// @dev Retrieves details about a specific deposit by its ID.
    /// @param depositId The ID of the deposit.
    /// @return Deposit struct containing all deposit information.
    function getDepositDetails(uint256 depositId) external view returns (Deposit memory) {
        // Returning a copy of the struct is safer than storage reference in view
        return deposits[depositId];
    }

    /// @dev Gets the list of deposit IDs associated with a user's address.
    /// @param user The address of the user.
    /// @return uint256[] An array of deposit IDs belonging to the user.
    function getUserDepositIds(address user) external view returns (uint256[] memory) {
        return userDepositIds[user];
    }

    /// @dev Gets the total Ether balance held by the contract.
    /// @return uint256 The total balance in wei.
    function getTotalVaultBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @dev Gets the user's balance available for simple withdrawal via the `withdraw` function.
    /// @param user The address of the user.
    /// @return uint256 The unlocked balance in wei.
    function getUnlockedBalance(address user) external view returns (uint256) {
        return unlockedBalances[user];
    }

    /// @dev Gets the total amount of Ether currently locked under a specific conditional hash.
    /// Iterates through deposits to sum up amounts for active deposits matching the condition hash.
    /// Potentially gas-intensive for many deposits.
    /// @param conditionHash The hash of the condition.
    /// @return uint256 The total locked balance for this condition in wei.
    function getConditionalLockedBalance(bytes32 conditionHash) external view returns (uint256) {
        uint256 totalLocked;
        for (uint256 i = 0; i < nextDepositId; i++) {
            Deposit storage dep = deposits[i];
            if (dep.isActive && dep.depositType == DepositType.Conditional && dep.conditionHash == conditionHash) {
                totalLocked += dep.amount;
            }
        }
        return totalLocked;
    }

     /// @dev Gets the total amount of Ether currently locked until a specific timestamp.
    /// Iterates through deposits to sum up amounts for active deposits matching the unlock timestamp.
    /// Potentially gas-intensive for many deposits.
    /// @param unlockTimestamp The timestamp.
    /// @return uint256 The total locked balance for this timestamp in wei.
    function getTimedLockedBalance(uint256 unlockTimestamp) external view returns (uint256) {
        uint256 totalLocked;
        for (uint256 i = 0; i < nextDepositId; i++) {
            Deposit storage dep = deposits[i];
            if (dep.isActive && dep.depositType == DepositType.Timed && dep.unlockTimestamp == unlockTimestamp) {
                totalLocked += dep.amount;
            }
        }
        return totalLocked;
    }

    /// @dev Retrieves the stored conceptual logic definition bytes for a specific withdrawal rule.
    /// @param ruleHash The hash of the rule.
    /// @return bytes The stored rule definition bytes.
    function getRuleLogicDefinition(bytes32 ruleHash) external view returns (bytes memory) {
        return withdrawalRules[ruleHash];
    }

    /// @dev Checks if a specific deposit was marked as soulbound upon creation.
    /// @param depositId The ID of the deposit.
    /// @return bool True if the deposit is marked as soulbound, false otherwise.
    function isDepositSoulbound(uint256 depositId) external view returns (bool) {
        // Direct check on the deposit struct's isSoulbound flag
        return deposits[depositId].isSoulbound;
    }

    /// @dev Gets the expiration timestamp for a specific condition.
    /// @param conditionHash The hash of the condition.
    /// @return uint256 The expiration timestamp.
    function getConditionExpiration(bytes32 conditionHash) external view returns (uint256) {
        return conditionExpirations[conditionHash];
    }

    /// @dev Returns the total number of deposits made to the vault (unique deposit IDs).
    /// @return uint256 The total count of deposits.
    function getDepositCount() external view returns (uint256) {
        return nextDepositId;
    }

    // Note: owner and oracleAddress are public state variables,
    // Solidity automatically creates getter functions for them (owner() and oracleAddress()).
    // This adds two more publicly accessible functions implicitly.

}
```