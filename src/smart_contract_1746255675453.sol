Okay, let's design a complex and creative smart contract. Instead of a standard token, DeFi primitive, or simple game, let's create something based on dynamic state changes driven potentially by external data, requiring multiple specific conditions to align for a key action to occur – like a metaphorical "quantum state collapse" unlocking something.

We'll call it the `QuantumTreasureVault`. It holds a special token (`QuantumEssence`) that can only be claimed when a set of dynamically defined "Quantum Entanglement Conditions" are simultaneously met. These conditions can be based on time, external data fed by oracles, or specific contract states. Users "attempt" to unlock the vault by staking, and if the conditions are met at that exact moment, they become eligible to claim a reward.

This avoids duplicating common patterns like ERC20/721 standards directly (though it interacts with a token), simple staking/farming, ICOs, or basic vaults. The complexity comes from managing dynamic, multi-factor, simultaneously checked conditions.

---

### **QuantumTreasureVault Smart Contract**

**Outline:**

1.  **License and Pragma:** SPDX License Identifier and Solidity version.
2.  **Errors:** Custom error definitions for clarity and gas efficiency.
3.  **Interfaces:** Define interfaces for the `QuantumEssence` token and potential Oracle interaction.
4.  **State Variables:**
    *   Roles (Owner, Weaver, Oracle addresses).
    *   `QuantumEssence` token address.
    *   Mappings/Arrays to store Quantum Conditions (structs).
    *   Mapping to store Oracle Data per condition ID.
    *   Mapping to store User Attempt States (structs: staked status, claimable amount).
    *   Vault parameters (required stake amount, reward rate).
5.  **Enums and Structs:**
    *   `ConditionType` enum (e.g., TimeWindow, OracleValueThreshold, SpecificAddressState).
    *   `QuantumCondition` struct (ID, Type, Parameters, isActive).
    *   `UserAttemptState` struct (isStaked, stakedAmount, canClaim, claimableAmount, lastAttemptBlock).
6.  **Events:** Log significant actions (role changes, condition updates, stake, attempt, claim).
7.  **Modifiers:** Access control modifiers (`onlyOwner`, `onlyWeaver`, `onlyOracle`).
8.  **Constructor:** Initialize roles and `QuantumEssence` token address.
9.  **Role Management:** Functions to transfer/set roles.
10. **Emergency Withdrawals:** Safeguards for the owner.
11. **`QuantumEssence` Interaction:** Functions to deposit tokens into the vault and check balance.
12. **Condition Management (Weaver Role):**
    *   Add, update, remove conditions.
    *   View condition parameters.
    *   List active conditions.
13. **Oracle Interaction:**
    *   Authorize/Deauthorize oracles.
    *   Function for authorized oracles to submit data for specific conditions.
    *   Function to retrieve stored oracle data.
14. **Internal Condition Checking:** Helper functions to evaluate individual condition types based on current state, time, or stored oracle data.
15. **Core "Quantum Entanglement" Check:** An internal function to check if *all* active conditions are met *simultaneously*.
16. **User Interaction (Unlock Process):**
    *   Stake tokens required for an unlock attempt.
    *   Attempt the quantum unlock: This function triggers the simultaneous condition check. If successful, user becomes eligible to claim.
    *   Claim `QuantumEssence` rewards if eligible.
    *   Withdraw stake if the unlock attempt failed or conditions changed.
17. **Parameter Settings (Weaver Role):** Set required stake amount and reward rate.
18. **View Functions:** Check current unlock status, user-specific status, available rewards, required stake.

**Function Summary:**

1.  `constructor(address initialWeaver, address initialOracle, address quantumEssenceTokenAddress)`: Deploys the contract, setting initial roles and the KE token address.
2.  `transferOwnership(address newOwner)`: Transfers contract ownership. (Owner)
3.  `transferWeaverRole(address newWeaver)`: Transfers the Weaver role. (Owner)
4.  `addAuthorizedOracle(address oracleAddress)`: Authorizes an address to submit oracle data. (Owner)
5.  `removeAuthorizedOracle(address oracleAddress)`: Deauthorizes an oracle address. (Owner)
6.  `isOracleAuthorized(address oracleAddress) public view returns (bool)`: Checks if an address is an authorized oracle.
7.  `emergencyWithdrawTokens(address tokenAddress, uint256 amount)`: Allows owner to withdraw arbitrary tokens in emergencies. (Owner)
8.  `emergencyWithdrawEther(uint256 amount)`: Allows owner to withdraw Ether in emergencies. (Owner)
9.  `depositQuantumEssence(uint256 amount)`: Allows anyone to deposit KE tokens into the vault. Requires token approval. (External)
10. `getTotalQuantumEssence() public view returns (uint256)`: Returns the total KE balance held by the vault.
11. `addQuantumCondition(ConditionType conditionType, bytes conditionParameters)`: Adds a new entanglement condition. (Weaver)
12. `updateQuantumConditionParameters(uint256 conditionId, bytes newParameters)`: Updates parameters for an existing condition. (Weaver)
13. `removeQuantumCondition(uint256 conditionId)`: Deactivates a condition. (Weaver)
14. `getConditionParameters(uint256 conditionId) public view returns (ConditionType conditionType, bool isActive, bytes parameters)`: Gets details of a specific condition.
15. `listActiveConditions() public view returns (uint256[] memory)`: Returns IDs of all currently active conditions.
16. `submitOracleData(uint256 conditionId, bytes data)`: Authorized oracles submit data for a specific condition. (Oracle)
17. `getOracleData(uint256 conditionId) public view returns (bytes memory)`: Retrieves the latest oracle data for a condition.
18. `setUnlockAttemptStakeAmount(uint256 amount)`: Sets the required KE stake for an unlock attempt. (Weaver)
19. `setSuccessRewardRate(uint256 rate)`: Sets the rate (e.g., basis points) for calculating rewards from the staked pool upon successful unlock. (Weaver)
20. `stakeForUnlockAttempt(uint256 amount)`: Stakes KE tokens to be eligible to attempt unlocking. Requires token approval. (External)
21. `attemptQuantumUnlock()`: Triggers the simultaneous check of all active conditions. If met, updates user status to `canClaim`. (External)
22. `claimQuantumEssence()`: Allows users whose `attemptQuantumUnlock` was successful to claim their calculated KE reward. (External)
23. `withdrawStake()`: Allows users to withdraw their staked KE if they are not currently eligible to claim. (External)
24. `getUnlockStatus() public view returns (bool areConditionsMet)`: Checks if all active conditions are currently met at the moment of the view call.
25. `getUserAttemptStatus(address user) public view returns (bool isStaked, uint256 stakedAmount, bool canClaim, uint256 claimableAmount)`: Gets the specific user's status.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumTreasureVault
 * @dev A smart contract that holds QuantumEssence tokens which can only be claimed
 *      when a set of dynamic "Quantum Entanglement Conditions" are simultaneously met.
 *      These conditions can be based on time, external oracle data, or contract state.
 *      Users stake QuantumEssence to attempt unlocking and claim rewards if successful.
 */

// --- Errors ---
error NotOwner();
error NotWeaver();
error NotAuthorizedOracle();
error QuantumEssenceDepositFailed();
error QuantumEssenceTransferFailed();
error EtherTransferFailed();
error ConditionNotFound(uint256 conditionId);
error ConditionNotActive(uint256 conditionId);
error ConditionAlreadyExists(uint256 conditionId);
error ConditionTypeNotSupported(uint8 conditionType); // Using uint8 for type as enum implicitly converts
error ConditionParametersInvalid(uint256 conditionId);
error OracleDataNotFound(uint256 conditionId);
error OracleDataNotApplicable(uint256 conditionId);
error StakeAmountTooLow(uint256 requiredAmount);
error AlreadyStaked(uint256 currentStake);
error NotStaked();
error ConditionsNotMet();
error NotEligibleForClaim();
error NoClaimableAmount();
error CannotWithdrawWhileClaimable();
error RewardRateTooHigh(); // Rate > 10000 basis points (100%)

// --- Interfaces ---
interface IQuantumEssence {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

// --- Enums and Structs ---
/**
 * @dev Enum defining types of entanglement conditions.
 *      More types can be added for increased complexity.
 */
enum ConditionType {
    TimeWindow,            // Requires current block.timestamp to be within a [start, end] range
    OracleValueThreshold,  // Requires oracle data (uint256) to be >= a threshold
    OracleBoolState,       // Requires oracle data (bool) to be true
    SpecificAddressHoldsKE // Requires a specific address to hold at least a threshold of KE tokens
}

/**
 * @dev Struct representing a single quantum entanglement condition.
 *      Parameters are stored in bytes and interpreted based on conditionType.
 */
struct QuantumCondition {
    uint256 id;
    ConditionType conditionType;
    bytes parameters; // Encoded parameters (e.g., abi.encode(startTime, endTime) for TimeWindow)
    bool isActive;
}

/**
 * @dev Struct tracking a user's attempt state for unlocking the vault.
 */
struct UserAttemptState {
    bool isStaked;
    uint256 stakedAmount;
    bool canClaim; // True if the last attemptQuantumUnlock call was successful
    uint256 claimableAmount; // Amount calculated at the time of successful attempt
    uint40 lastAttemptBlock; // Block number of the last attempt
}

// --- Contract Definition ---
contract QuantumTreasureVault {
    // --- State Variables ---
    address private immutable i_owner;
    address private i_weaver;
    address private i_quantumEssenceToken;

    mapping(address => bool) private s_authorizedOracles;
    address[] private s_authorizedOracleList; // To easily iterate/list oracles if needed

    uint256 private s_nextConditionId = 1;
    mapping(uint256 => QuantumCondition) private s_conditions;
    uint256[] private s_activeConditionIds; // List of IDs for active conditions

    mapping(uint256 => bytes) private s_oracleData; // Latest data submitted by oracle per condition ID

    mapping(address => UserAttemptState) private s_userAttemptStates;

    uint256 private s_unlockAttemptStakeAmount; // Required KE to stake for an attempt
    uint256 private s_successRewardRate; // Basis points (e.g., 100 = 1%, 10000 = 100%)

    // --- Events ---
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event WeaverRoleTransferred(address indexed previousWeaver, address indexed newWeaver);
    event OracleAuthorized(address indexed oracle);
    event OracleDeauthorized(address indexed oracle);
    event QuantumEssenceDeposited(address indexed depositor, uint256 amount);
    event ConditionAdded(uint256 indexed conditionId, ConditionType conditionType, bool isActive);
    event ConditionUpdated(uint256 indexed conditionId, bytes newParameters);
    event ConditionRemoved(uint256 indexed conditionId);
    event OracleDataSubmitted(uint256 indexed conditionId, address indexed oracle, bytes data);
    event UnlockAttemptStakeSet(uint256 amount);
    event SuccessRewardRateSet(uint256 rate);
    event StakeForUnlockAttempt(address indexed user, uint256 amount);
    event QuantumUnlockAttempt(address indexed user, bool success);
    event QuantumEssenceClaimed(address indexed user, uint256 amount);
    event StakeWithdrawn(address indexed user, uint256 amount);

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    modifier onlyWeaver() {
        if (msg.sender != i_weaver) {
            revert NotWeaver();
        }
        _;
    }

    modifier onlyAuthorizedOracle() {
        if (!s_authorizedOracles[msg.sender]) {
            revert NotAuthorizedOracle();
        }
        _;
    }

    // --- Constructor ---
    constructor(address initialWeaver, address initialOracle, address quantumEssenceTokenAddress) {
        i_owner = msg.sender;
        i_weaver = initialWeaver;
        i_quantumEssenceToken = quantumEssenceTokenAddress;

        if (initialOracle != address(0)) {
             s_authorizedOracles[initialOracle] = true;
             s_authorizedOracleList.push(initialOracle);
             emit OracleAuthorized(initialOracle);
        }

        emit OwnershipTransferred(address(0), msg.sender);
        emit WeaverRoleTransferred(address(0), initialWeaver);
    }

    // --- Role Management ---
    /**
     * @dev Transfers ownership of the contract to a new address.
     *      Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(i_owner, newOwner);
        // Note: In this simple model, i_owner is immutable. A proxy pattern would be needed for true transferability.
        // This function serves as a placeholder/demonstration. For a real contract, make i_owner mutable or use proxies.
        // If keeping i_owner immutable, this function should revert or be removed.
        // Let's keep i_owner immutable for simplicity and security demonstration without upgradeability.
        revert("Owner is immutable in this contract version.");
        // If owner was mutable: i_owner = newOwner;
    }

     /**
     * @dev Transfers the Weaver role to a new address.
     *      Can only be called by the current owner.
     */
    function transferWeaverRole(address newWeaver) external onlyOwner {
        require(newWeaver != address(0), "New weaver is the zero address");
        address oldWeaver = i_weaver;
        i_weaver = newWeaver;
        emit WeaverRoleTransferred(oldWeaver, newWeaver);
    }

    /**
     * @dev Authorizes an address to submit oracle data.
     *      Can only be called by the owner.
     * @param oracleAddress The address to authorize.
     */
    function addAuthorizedOracle(address oracleAddress) external onlyOwner {
        require(oracleAddress != address(0), "Zero address not allowed");
        if (!s_authorizedOracles[oracleAddress]) {
            s_authorizedOracles[oracleAddress] = true;
            s_authorizedOracleList.push(oracleAddress);
            emit OracleAuthorized(oracleAddress);
        }
    }

    /**
     * @dev Deauthorizes an address from submitting oracle data.
     *      Can only be called by the owner.
     * @param oracleAddress The address to deauthorize.
     */
    function removeAuthorizedOracle(address oracleAddress) external onlyOwner {
         if (s_authorizedOracles[oracleAddress]) {
            s_authorizedOracles[oracleAddress] = false;
            // Note: Removing from s_authorizedOracleList is more complex (requires shifting).
            // For this example, we'll rely on the mapping check s_authorizedOracles[msg.sender].
            // A more robust implementation might rebuild the list periodically or use a more complex data structure.
            emit OracleDeauthorized(oracleAddress);
        }
    }

    /**
     * @dev Checks if an address is currently authorized to submit oracle data.
     * @param oracleAddress The address to check.
     * @return True if authorized, false otherwise.
     */
    function isOracleAuthorized(address oracleAddress) public view returns (bool) {
        return s_authorizedOracles[oracleAddress];
    }

    // --- Emergency Withdrawals ---
    /**
     * @dev Allows the owner to withdraw specified amount of any ERC20 token in case of emergency.
     * @param tokenAddress The address of the token to withdraw.
     * @param amount The amount of tokens to withdraw.
     */
    function emergencyWithdrawTokens(address tokenAddress, uint256 amount) external onlyOwner {
        require(tokenAddress != i_quantumEssenceToken, "Cannot use emergency withdraw for QuantumEssence");
        IQuantumEssence token = IQuantumEssence(tokenAddress);
        if (!token.transfer(i_owner, amount)) {
             revert QuantumEssenceTransferFailed(); // Reusing error, could be TokenTransferFailed
        }
    }

    /**
     * @dev Allows the owner to withdraw specified amount of Ether in case of emergency.
     * @param amount The amount of Ether to withdraw in wei.
     */
    function emergencyWithdrawEther(uint256 amount) external onlyOwner {
        (bool success, ) = i_owner.call{value: amount}("");
        if (!success) {
            revert EtherTransferFailed();
        }
    }

    // --- QuantumEssence Interaction ---
    /**
     * @dev Allows users to deposit QuantumEssence tokens into the vault.
     *      Requires the user to have approved the contract to spend the tokens first.
     * @param amount The amount of QuantumEssence tokens to deposit.
     */
    function depositQuantumEssence(uint256 amount) external {
        IQuantumEssence keToken = IQuantumEssence(i_quantumEssenceToken);
        if (!keToken.transferFrom(msg.sender, address(this), amount)) {
            revert QuantumEssenceDepositFailed();
        }
        emit QuantumEssenceDeposited(msg.sender, amount);
    }

    /**
     * @dev Returns the total balance of QuantumEssence tokens held by the vault.
     * @return The total KE balance.
     */
    function getTotalQuantumEssence() public view returns (uint256) {
        IQuantumEssence keToken = IQuantumEssence(i_quantumEssenceToken);
        return keToken.balanceOf(address(this));
    }

    // --- Condition Management (Weaver Role) ---
    /**
     * @dev Adds a new quantum entanglement condition.
     *      Only callable by the Weaver.
     * @param conditionType The type of condition.
     * @param conditionParameters Encoded parameters specific to the condition type.
     * @return The ID of the newly added condition.
     */
    function addQuantumCondition(ConditionType conditionType, bytes calldata conditionParameters) external onlyWeaver returns (uint256) {
        uint256 newId = s_nextConditionId++;
        s_conditions[newId] = QuantumCondition({
            id: newId,
            conditionType: conditionType,
            parameters: conditionParameters,
            isActive: true
        });
        s_activeConditionIds.push(newId); // Add to active list
        emit ConditionAdded(newId, conditionType, true);
        return newId;
    }

    /**
     * @dev Updates the parameters of an existing quantum entanglement condition.
     *      Only callable by the Weaver.
     * @param conditionId The ID of the condition to update.
     * @param newParameters New encoded parameters for the condition.
     */
    function updateQuantumConditionParameters(uint256 conditionId, bytes calldata newParameters) external onlyWeaver {
        QuantumCondition storage condition = s_conditions[conditionId];
        if (condition.id == 0) { // Check if condition exists (default id is 0)
            revert ConditionNotFound(conditionId);
        }
        condition.parameters = newParameters;
        emit ConditionUpdated(conditionId, newParameters);
    }

     /**
     * @dev Deactivates a quantum entanglement condition. It remains stored but is not checked.
     *      Only callable by the Weaver.
     * @param conditionId The ID of the condition to remove (deactivate).
     */
    function removeQuantumCondition(uint256 conditionId) external onlyWeaver {
        QuantumCondition storage condition = s_conditions[conditionId];
         if (condition.id == 0) {
            revert ConditionNotFound(conditionId);
        }
        if (!condition.isActive) {
            revert ConditionNotActive(conditionId); // Already inactive
        }
        condition.isActive = false;

        // Remove from active list
        uint256 len = s_activeConditionIds.length;
        for (uint256 i = 0; i < len; i++) {
            if (s_activeConditionIds[i] == conditionId) {
                // Swap with last element and pop
                s_activeConditionIds[i] = s_activeConditionIds[len - 1];
                s_activeConditionIds.pop();
                break; // Found and removed, exit loop
            }
        }

        emit ConditionRemoved(conditionId);
    }

    /**
     * @dev Gets the details of a specific quantum entanglement condition.
     * @param conditionId The ID of the condition.
     * @return The condition type, active status, and parameters.
     */
    function getConditionParameters(uint256 conditionId) public view returns (ConditionType conditionType, bool isActive, bytes memory parameters) {
         QuantumCondition storage condition = s_conditions[conditionId];
         if (condition.id == 0) {
            revert ConditionNotFound(conditionId);
        }
        return (condition.conditionType, condition.isActive, condition.parameters);
    }

    /**
     * @dev Returns the IDs of all currently active quantum entanglement conditions.
     * @return An array of active condition IDs.
     */
    function listActiveConditions() public view returns (uint256[] memory) {
        return s_activeConditionIds;
    }

    // --- Oracle Interaction ---
    /**
     * @dev Allows an authorized oracle to submit data for a specific condition.
     *      The format of the data (bytes) depends on the condition type.
     * @param conditionId The ID of the condition the data relates to.
     * @param data The encoded oracle data.
     */
    function submitOracleData(uint256 conditionId, bytes calldata data) external onlyAuthorizedOracle {
        QuantumCondition storage condition = s_conditions[conditionId];
         if (condition.id == 0 || !condition.isActive) {
            revert ConditionNotFound(conditionId); // Data only relevant for active conditions
        }
        // No deep validation of 'data' format here for flexibility, condition check logic handles it.
        s_oracleData[conditionId] = data;
        emit OracleDataSubmitted(conditionId, msg.sender, data);
    }

     /**
     * @dev Retrieves the latest oracle data submitted for a specific condition.
     * @param conditionId The ID of the condition.
     * @return The latest submitted data.
     */
    function getOracleData(uint256 conditionId) public view returns (bytes memory) {
        return s_oracleData[conditionId];
    }


    // --- Internal Condition Checking ---
    /**
     * @dev Internal function to check if a single condition is met based on its type and parameters.
     * @param condition The QuantumCondition struct.
     * @return True if the condition is met, false otherwise.
     */
    function _checkCondition(QuantumCondition memory condition) internal view returns (bool) {
        if (!condition.isActive) return false; // Only check active conditions

        bytes memory params = condition.parameters;

        // Decode oracle data if needed
        bytes memory oracleDataBytes = s_oracleData[condition.id];

        // Use unchecked for safe enum conversion in switch/if
        unchecked {
            if (uint8(condition.conditionType) == uint8(ConditionType.TimeWindow)) {
                // Parameters: abi.encode(uint256 startTime, uint256 endTime)
                if (params.length != 64) revert ConditionParametersInvalid(condition.id);
                (uint256 startTime, uint256 endTime) = abi.decode(params, (uint256, uint256));
                uint256 currentTime = block.timestamp;
                return currentTime >= startTime && currentTime <= endTime;

            } else if (uint8(condition.conditionType) == uint8(ConditionType.OracleValueThreshold)) {
                // Parameters: abi.encode(uint256 threshold)
                // Oracle Data: abi.encode(uint256 value)
                if (params.length != 32) revert ConditionParametersInvalid(condition.id);
                if (oracleDataBytes.length != 32) revert OracleDataNotFound(condition.id); // Data must exist
                uint256 threshold = abi.decode(params, (uint256));
                uint256 oracleValue = abi.decode(oracleDataBytes, (uint256));
                return oracleValue >= threshold;

            } else if (uint8(condition.conditionType) == uint8(ConditionType.OracleBoolState)) {
                 // Parameters: abi.encode(bool requiredState) - often just true, but can be dynamic
                 // Oracle Data: abi.encode(bool state)
                if (params.length != 32) revert ConditionParametersInvalid(condition.id); // bool is 32 bytes when encoded
                if (oracleDataBytes.length != 32) revert OracleDataNotFound(condition.id);
                bool requiredState = abi.decode(params, (bool));
                bool oracleState = abi.decode(oracleDataBytes, (bool));
                return oracleState == requiredState;

            } else if (uint8(condition.conditionType) == uint8(ConditionType.SpecificAddressHoldsKE)) {
                 // Parameters: abi.encode(address targetAddress, uint256 requiredAmount)
                 // No specific oracle data needed, checks on-chain state
                 if (params.length != 64) revert ConditionParametersInvalid(condition.id);
                 (address targetAddress, uint256 requiredAmount) = abi.decode(params, (address, uint256));
                 IQuantumEssence keToken = IQuantumEssence(i_quantumEssenceToken);
                 return keToken.balanceOf(targetAddress) >= requiredAmount;

            } else {
                // Unknown condition type
                 revert ConditionTypeNotSupported(uint8(condition.conditionType));
            }
        }
    }

    /**
     * @dev Internal function to check if ALL currently active quantum entanglement conditions are met.
     *      This represents the "Quantum Entanglement Collapse" moment.
     * @return True if all active conditions are met, false otherwise.
     */
    function _checkAllConditions() internal view returns (bool) {
        if (s_activeConditionIds.length == 0) {
            // If no conditions are set, maybe it's always unlockable, or never.
            // Let's say if no conditions are active, it's not considered "entangled", thus not unlockable.
            return false;
        }

        // Use unchecked for loop bounds as s_activeConditionIds.length is from contract state
        unchecked {
             for (uint256 i = 0; i < s_activeConditionIds.length; i++) {
                 uint256 conditionId = s_activeConditionIds[i];
                 QuantumCondition storage condition = s_conditions[conditionId];
                 // Check isActive again just in case (though s_activeConditionIds should only contain active ones)
                 if (!condition.isActive || !_checkCondition(condition)) {
                     return false; // As soon as one condition fails, the entanglement is broken
                 }
             }
        }
        return true; // All active conditions were met
    }

    // --- User Interaction (Unlock Process) ---
    /**
     * @dev Stakes QuantumEssence tokens required to be eligible to attempt unlocking.
     *      User must approve the contract to spend the tokens first.
     * @param amount The amount of KE tokens to stake. Must be >= s_unlockAttemptStakeAmount.
     */
    function stakeForUnlockAttempt(uint256 amount) external {
        UserAttemptState storage userState = s_userAttemptStates[msg.sender];

        if (userState.isStaked) {
            revert AlreadyStaked(userState.stakedAmount);
        }
        if (amount < s_unlockAttemptStakeAmount) {
            revert StakeAmountTooLow(s_unlockAttemptStakeAmount);
        }

        IQuantumEssence keToken = IQuantumEssence(i_quantumEssenceToken);
        if (!keToken.transferFrom(msg.sender, address(this), amount)) {
            revert QuantumEssenceTransferFailed();
        }

        userState.isStaked = true;
        userState.stakedAmount = amount;
        userState.canClaim = false; // Reset claim status on new stake
        userState.claimableAmount = 0; // Reset claimable amount
        // Don't reset lastAttemptBlock here, only on actual attempt

        emit StakeForUnlockAttempt(msg.sender, amount);
    }

    /**
     * @dev Attempts to perform the quantum unlock. Checks if ALL active entanglement conditions
     *      are met *at the exact moment this function is called*.
     *      Requires the user to have staked the required amount.
     *      If successful, the user becomes eligible to claim a reward later.
     */
    function attemptQuantumUnlock() external {
        UserAttemptState storage userState = s_userAttemptStates[msg.sender];

        if (!userState.isStaked) {
            revert NotStaked();
        }
        if (userState.stakedAmount < s_unlockAttemptStakeAmount) {
             revert StakeAmountTooLow(s_unlockAttemptStakeAmount); // Should not happen if staking enforced, but safeguard
        }

        userState.lastAttemptBlock = uint40(block.number); // Record attempt block (max block ~2^40)

        bool conditionsMet = _checkAllConditions();

        if (conditionsMet) {
            userState.canClaim = true;
            // Calculate potential claimable amount (basic example: fraction of total KE based on stake ratio and reward rate)
            // A more complex model could involve time staked, number of participants, etc.
            uint256 totalEssenceInVault = getTotalQuantumEssence();
            uint256 totalStakedAmount = s_unlockAttemptStakeAmount; // Assuming all stakers meet requirement

            // Avoid division by zero if no one has staked the required amount (unlikely if staking enforced)
            uint256 claimPotential = (userState.stakedAmount * totalEssenceInVault) / (totalStakedAmount > 0 ? totalStakedAmount : 1);

            // Apply reward rate (in basis points)
            userState.claimableAmount = (claimPotential * s_successRewardRate) / 10000; // 10000 basis points = 100%

             // Ensure claimable amount doesn't exceed actual vault balance after calculation
            if (userState.claimableAmount > totalEssenceInVault) {
                userState.claimableAmount = totalEssenceInVault;
            }


            emit QuantumUnlockAttempt(msg.sender, true);
        } else {
            userState.canClaim = false;
            userState.claimableAmount = 0;
            emit QuantumUnlockAttempt(msg.sender, false);
        }
    }

    /**
     * @dev Allows a user who successfully attempted the quantum unlock to claim their
     *      calculated QuantumEssence reward. Resets their claim eligibility.
     *      The staked amount remains staked unless withdrawn.
     */
    function claimQuantumEssence() external {
        UserAttemptState storage userState = s_userAttemptStates[msg.sender];

        if (!userState.canClaim) {
            revert NotEligibleForClaim();
        }
        if (userState.claimableAmount == 0) {
            revert NoClaimableAmount(); // Should not happen if canClaim is true and logic correct, but safeguard
        }

        uint256 amountToClaim = userState.claimableAmount;

        // Reset state BEFORE transferring to prevent reentrancy (though standard ERC20 transfer is safe)
        userState.canClaim = false;
        userState.claimableAmount = 0;

        IQuantumEssence keToken = IQuantumEssence(i_quantumEssenceToken);
        // Check contract balance before transfer
        if (amountToClaim > keToken.balanceOf(address(this))) {
             // This is a safeguard. Ideally, the calculation prevents this.
             // If it happens, claim the remaining balance rather than failing entirely.
             amountToClaim = keToken.balanceOf(address(this));
             if (amountToClaim == 0) revert NoClaimableAmount(); // No KE left
        }

        if (!keToken.transfer(msg.sender, amountToClaim)) {
             // Transfer failed, maybe re-set state or have a recovery mechanism.
             // For simplicity, we revert after attempting state reset.
             // A production contract might queue for manual intervention or retry.
             // Reverting here leaves the user state marked as not claimable,
             // which is harsh but prevents loss of funds in the vault.
             revert QuantumEssenceTransferFailed();
        }

        emit QuantumEssenceClaimed(msg.sender, amountToClaim);
    }

    /**
     * @dev Allows a user to withdraw their staked QuantumEssence tokens.
     *      Cannot be withdrawn if the user is currently eligible to claim a reward
     *      (must claim first or attemptUnlock must fail).
     */
    function withdrawStake() external {
        UserAttemptState storage userState = s_userAttemptStates[msg.sender];

        if (!userState.isStaked) {
            revert NotStaked();
        }
        if (userState.canClaim) {
             revert CannotWithdrawWhileClaimable(); // Must claim first
        }

        uint256 amountToWithdraw = userState.stakedAmount;

        // Reset state BEFORE transfer
        userState.isStaked = false;
        userState.stakedAmount = 0;
        // userState.canClaim and claimableAmount should already be false/0 if we got here

        IQuantumEssence keToken = IQuantumEssence(i_quantumEssenceToken);
         if (!keToken.transfer(msg.sender, amountToWithdraw)) {
            // Transfer failed. This leaves user state reset but tokens stuck.
            // A production contract needs a recovery mechanism or retry logic.
             revert QuantumEssenceTransferFailed();
        }

        emit StakeWithdrawn(msg.sender, amountToWithdraw);
    }


    // --- Parameter Settings (Weaver Role) ---
    /**
     * @dev Sets the required amount of QuantumEssence tokens a user must stake
     *      to be eligible for an unlock attempt.
     *      Only callable by the Weaver.
     * @param amount The required stake amount.
     */
    function setUnlockAttemptStakeAmount(uint256 amount) external onlyWeaver {
        s_unlockAttemptStakeAmount = amount;
        emit UnlockAttemptStakeSet(amount);
    }

    /**
     * @dev Sets the reward rate (in basis points, 0-10000) used to calculate
     *      the claimable amount upon a successful unlock attempt.
     *      E.g., 100 = 1%, 5000 = 50%, 10000 = 100%.
     *      Only callable by the Weaver.
     * @param rate The reward rate in basis points (0-10000).
     */
    function setSuccessRewardRate(uint256 rate) external onlyWeaver {
        if (rate > 10000) {
            revert RewardRateTooHigh();
        }
        s_successRewardRate = rate;
        emit SuccessRewardRateSet(rate);
    }

    // --- View Functions ---
    /**
     * @dev Checks if all active quantum entanglement conditions are currently met.
     *      This is a view function and the state can change immediately after.
     *      For a guaranteed check for unlocking, use `attemptQuantumUnlock`.
     * @return True if all active conditions are met, false otherwise.
     */
    function getUnlockStatus() public view returns (bool areConditionsMet) {
        return _checkAllConditions();
    }

    /**
     * @dev Gets the current attempt status for a specific user.
     * @param user The address of the user to check.
     * @return isStaked, stakedAmount, canClaim, claimableAmount.
     */
    function getUserAttemptStatus(address user) public view returns (bool isStaked, uint256 stakedAmount, bool canClaim, uint256 claimableAmount) {
        UserAttemptState storage userState = s_userAttemptStates[user];
        return (userState.isStaked, userState.stakedAmount, userState.canClaim, userState.claimableAmount);
    }

     /**
     * @dev Gets the currently required stake amount for an unlock attempt.
     * @return The required stake amount.
     */
    function getRequiredStake() public view returns (uint256) {
        return s_unlockAttemptStakeAmount;
    }

     /**
     * @dev Gets the current success reward rate in basis points.
     * @return The reward rate.
     */
    function getSuccessRewardRate() public view returns (uint256) {
        return s_successRewardRate;
    }

    // Helper function to get a list of authorized oracles (optional)
    function getAuthorizedOracles() public view returns (address[] memory) {
        // Note: This returns the list as it was added. Removing an oracle
        // only flips the mapping flag, it doesn't remove from this list in this simple version.
        // A more complex list management or checking the mapping in a loop would be needed for an exact current list.
        return s_authorizedOracleList;
    }
}
```

**Explanation and Considerations:**

1.  **Quantum Metaphor:** The "quantum entanglement" is the simultaneous requirement of multiple distinct conditions being true at the exact moment of calling `attemptQuantumUnlock`. The "collapse" is the result – either successful eligibility for claiming (like a state observation) or not.
2.  **Quantum Essence Token:** A separate ERC20-like token contract (`IQuantumEssence`) is assumed. This vault holds and distributes it.
3.  **Roles:** `Owner` has full control (though immutable in this code for simplicity, typical pattern uses upgradeable proxies). `Weaver` defines and manages the entanglement `Conditions` and vault parameters (stake, reward rate). `Oracle` submits external data required by some conditions. This separation of concerns adds complexity.
4.  **Dynamic Conditions:** Conditions are not hardcoded. The `Weaver` can add, update, and remove them via `addQuantumCondition`, `updateQuantumConditionParameters`, and `removeQuantumCondition`.
5.  **Condition Types:** A few basic types are implemented (`TimeWindow`, `OracleValueThreshold`, `OracleBoolState`, `SpecificAddressHoldsKE`). This can be extended. Parameters for each type are encoded into `bytes` and decoded in the `_checkCondition` function. This allows for dynamic condition logic without changing the core contract structure, though the `_checkCondition` function needs updates for each new `ConditionType`.
6.  **Oracle Integration:** The contract includes functions for `AuthorizedOracles` to `submitOracleData`. The `_checkCondition` logic then uses this stored data. This makes the contract dependent on external information, a common advanced pattern but also a point of centralization/trust in the oracles.
7.  **Simultaneous Check:** The core `attemptQuantumUnlock` function calls `_checkAllConditions`, which iterates through the *active* conditions and calls `_checkCondition` for each. *All* must return `true` at that moment for the attempt to succeed.
8.  **Unlock Process:** Users first `stakeForUnlockAttempt`, locking their KE. Then they call `attemptQuantumUnlock`. If successful, their state is updated (`canClaim` becomes true, `claimableAmount` is calculated). They must then call `claimQuantumEssence` to receive the reward. If `attemptQuantumUnlock` fails, or if the conditions change *after* a successful attempt but *before* claiming, the user might need to `withdrawStake` (if not claimable) or try `attemptQuantumUnlock` again.
9.  **Reward Calculation:** A simple model is used (`stakedAmount / totalRequiredStake * totalVaultKE * rewardRate`). More complex, fairer distribution mechanisms are possible but add significant complexity.
10. **Error Handling:** Uses custom errors for better clarity and gas efficiency compared to `require` strings.
11. **View Functions:** Provide transparency into the state of conditions, oracle data, and user status. `getUnlockStatus` is a live check, while `attemptQuantumUnlock` is the actual state-changing check.
12. **Non-Duplication:** This contract's combination of dynamic, multi-type, oracle-dependent, simultaneously-checked conditions for state-based unlock, combined with a staking-to-attempt mechanism, is not a direct copy of standard open-source templates like OpenZeppelin ERCs, basic vaults, or typical staking/farming contracts.

**Potential Extensions (Adding More Complexity):**

*   More `ConditionType` options (e.g., based on historical block data, results of other contract calls, aggregate oracle data).
*   More sophisticated reward calculation (e.g., proportional to time staked, quadratic staking, lottery elements).
*   Penalties for failed unlock attempts (e.g., slashing a small portion of stake).
*   Governance for the `Weaver` and `Oracle` roles, or even for adding/removing conditions.
*   Allowing users to propose new condition types or parameters.
*   Handling multiple stakers competing for the same unlocked pool in a single block.
*   Integrating with verifiable random functions (VRF) as a condition type or for reward distribution.
*   Using events to signal condition state changes off-chain.

This contract provides a foundation for a complex, multi-variable system on chain, illustrating how logic can depend on external data, dynamic configuration, and the precise alignment of multiple factors at a given moment.