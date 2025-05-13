Okay, let's design a complex, advanced, and non-standard smart contract. We'll create a "QuantumFlow Vault" that manages deposited assets whose final distribution depends on simulated "quantum states" that can be in superposition, entangled, and collapsed by specific triggers.

This contract will feature:

1.  **Quantum-Inspired States:** Deposited funds are tied to abstract "quantum states" that represent multiple potential outcomes.
2.  **Superposition & Collapse:** States exist in superposition until a trigger causes them to collapse into a single, determined outcome.
3.  **Entanglement:** States can be "entangled" such that the collapse of one state influences or forces the collapse of another.
4.  **Dynamic Outcomes:** The final withdrawal amount depends on the outcome of the collapsed state tied to the deposit.
5.  **Trigger Mechanisms:** States can be collapsed by time, external oracle calls (simulated), or manual governance triggers.
6.  **Share-Based Deposits:** Multiple users deposit into the same state instance, owning shares of that state's potential outcome.
7.  **Advanced Governance:** Fine-grained control over state creation, parameters, triggers, and emergency actions.

---

### **Outline and Function Summary**

**Contract Name:** `QuantumFlowVault`

**Core Concept:** A vault holding Ether where withdrawal amounts are determined by the outcome of abstract, dynamic "quantum states" linked to deposits. These states transition from "superposition" to "collapsed" based on defined triggers, potentially influencing "entangled" states.

**Key Components:**
*   `StateType`: Defines the *rules* for a type of quantum state (e.g., probability distribution for outcomes).
*   `QuantumStateInstance`: An *instance* of a `StateType` that holds specific parameters and tracks its current status (Superposition/Collapsed) and outcome. Deposits are linked to instances.
*   `DepositShare`: Represents a user's share of the total deposit within a specific `QuantumStateInstance`.

**Functions (24 total):**

1.  `constructor()`: Initializes the contract owner and sets initial governance.
2.  `pauseVault()`: Governance function to pause sensitive operations (deposits, withdrawals, state changes).
3.  `unpauseVault()`: Governance function to resume operations.
4.  `setGovernanceAddress(address newGovernance)`: Transfers governance rights.
5.  `deposit(uint256 stateInstanceId)`: Allows users to deposit Ether and associate it with a specific state instance currently in Superposition.
6.  `withdraw(uint256 stateInstanceId)`: Allows users to withdraw their share after the associated state instance has Collapsed.
7.  `getVaultBalance()`: View function to check the total Ether balance held by the vault.
8.  `createStateType(uint256 outcomeCount, uint256[] distributionWeights, uint256[] outcomeValues)`: Governance defines a new type of quantum state with potential outcomes, their relative weights (for probabilistic collapse), and associated values (relative payout multipliers).
9.  `createStateInstance(uint256 stateTypeId, bytes calldata initialParams)`: Governance creates a specific instance of a registered StateType, ready for deposits.
10. `assignStateTypeToDeposit(uint256 depositId, uint256 newStateInstanceId)`: Governance can re-assign a user's deposit share to a different state instance (e.g., for migration).
11. `triggerStateCollapse(uint256 stateInstanceId, bytes calldata oracleData)`: Initiates the collapse of a specific state instance. Requires meeting trigger conditions (e.g., time elapsed, oracle data provided). Simulates outcome based on state type rules and potential oracle data/block hash.
12. `getStateDetails(uint256 stateInstanceId)`: View function returning the parameters and status of a state instance *before* collapse.
13. `getCollapsedStateOutcome(uint256 stateInstanceId)`: View function returning the determined outcome and value *after* a state instance has Collapsed.
14. `entangleStates(uint256 stateInstanceId1, uint256 stateInstanceId2)`: Governance links two state instances, making their collapse outcomes potentially interdependent.
15. `disentangleStates(uint256 stateInstanceId1, uint256 stateInstanceId2)`: Governance removes the entanglement link between two state instances.
16. `initiateDecoherence()`: Governance function to forcefully disentangle *all* currently entangled state instances.
17. `setDynamicFee(uint8 feeType, uint256 feePercentage)`: Governance sets dynamic fees for specific actions (e.g., withdrawal fee post-collapse).
18. `collectFees(uint8 feeType)`: Governance collects fees accrued from specific actions.
19. `registerOracleTrigger(uint256 stateInstanceId, address oracleAddress, bytes4 oracleFunctionSig)`: Governance registers a simulated oracle call as a trigger for a state instance collapse. (Requires a simulated Oracle interaction pattern).
20. `registerTimeTrigger(uint256 stateInstanceId, uint64 collapseTimestamp)`: Governance registers a specific timestamp as a trigger for a state instance collapse.
21. `batchCollapseStates(uint256[] stateInstanceIds)`: Governance triggers the collapse of multiple state instances meeting their trigger conditions.
22. `getUserDepositShares(address user)`: View function listing all state instances and associated shares for a specific user.
23. `getEligibleStatesForCollapse()`: View function listing state instances that currently meet their defined collapse trigger conditions.
24. `calculatePotentialWithdrawalAmount(address user, uint256 stateInstanceId, uint256 assumedOutcomeValue)`: View function estimating a user's potential withdrawal amount for a specific state instance, assuming a given collapse outcome value. Useful for pre-collapse simulation.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumFlowVault
 * @dev An advanced, conceptual smart contract simulating asset management tied to
 *      dynamic, 'quantum-inspired' states. Assets deposited are linked to states
 *      that exist in 'superposition' (multiple potential outcomes) until a trigger
 *      causes them to 'collapse' into a single, determined outcome. The final
 *      withdrawal amount depends on this collapsed outcome. States can also be
 *      'entangled', where collapsing one influences another. Features include
 *      share-based deposits into states, dynamic fee structures, and multiple
 *      collapse trigger mechanisms (time, simulated oracle, governance).
 *      NOTE: This contract uses simulated randomness/oracle interaction for
 *      conceptual complexity. A real-world implementation would require secure
 *      randomness (e.g., Chainlink VRF) or robust decentralized oracles.
 */

// Outline and Function Summary provided above the code.

contract QuantumFlowVault {

    // --- State Variables ---

    address public governance;
    bool public paused = false;

    // Counters for unique IDs
    uint265 private _stateTypeIdCounter = 0;
    uint256 private _stateInstanceIdCounter = 0;
    uint256 private _depositIdCounter = 0; // Tracks individual deposit events/shares

    // --- Data Structures ---

    // Represents a definition of a type of quantum state and its potential outcomes
    struct StateType {
        uint256 id;
        uint256 outcomeCount; // Number of potential outcomes
        uint256[] distributionWeights; // Relative weights/probabilities for outcomes (sum doesn't have to be 100, relative)
        uint256[] outcomeValues; // Relative values for each outcome (e.g., payout multiplier)
        // Add other type-specific parameters if needed
        bytes initialParams; // Generic field for type-specific initialization data
    }

    // Represents an instance of a StateType that deposits are linked to
    struct QuantumStateInstance {
        uint256 id;
        uint256 stateTypeId; // Link to the StateType definition
        bytes currentParams; // Current parameters for this instance (could evolve)
        bool inSuperposition; // True if not yet collapsed
        uint256 collapsedOutcomeIndex; // Index of the chosen outcome (if collapsed)
        uint256 collapsedOutcomeValue; // The value associated with the collapsed outcome

        uint256 totalDepositsETH; // Total ETH deposited into this instance
        uint256 totalShares; // Total number of shares across all depositors in this instance

        uint256 entangledStateId; // ID of the state instance this one is entangled with (0 if not entangled)
        bool isEntangled; // Explicit flag for clarity

        // Collapse Triggers (mutually exclusive or combined based on logic)
        enum TriggerType { None, Time, Oracle, Manual }
        TriggerType triggerType;
        uint64 collapseTimestamp; // Trigger: Time
        address oracleAddress;     // Trigger: Oracle (simulated)
        bytes4 oracleFunctionSig; // Trigger: Oracle (simulated)

        bool triggerMet; // Flag indicating if the trigger condition has been met
    }

    // Represents a user's share of deposits in a specific state instance
    struct DepositShare {
        uint256 id; // Unique ID for this specific deposit share
        address depositor;
        uint256 stateInstanceId; // Which state instance this share belongs to
        uint256 amountETH; // Original ETH amount deposited
        uint256 shares; // Number of shares received for this deposit
        bool withdrawn; // Has this share already been withdrawn?
    }

    // --- Mappings ---

    mapping(uint256 => StateType) public stateTypes;
    mapping(uint256 => QuantumStateInstance) public stateInstances;
    mapping(uint256 => DepositShare) public depositShares; // Map deposit ID to share details

    // Map user address to a list of their deposit share IDs
    mapping(address => uint256[]) public userDepositShareIds;

    // Map state instance ID to a list of deposit share IDs within that instance
    mapping(uint256 => uint256[]) public stateInstanceDepositShareIds;

    // Dynamic Fees
    mapping(uint8 => uint256) public dynamicFeesPercentage; // Fee percentage (e.g., 100 = 1%) per fee type
    mapping(uint8 => uint256) public accruedFees; // Fees collected per fee type

    // Fee Types Enum
    enum FeeType { Withdrawal } // Example fee types

    // --- Events ---

    event VaultPaused(address indexed by);
    event VaultUnpaused(address indexed by);
    event GovernanceTransferred(address indexed oldGovernance, address indexed newGovernance);

    event DepositReceived(address indexed depositor, uint256 depositId, uint256 stateInstanceId, uint256 amountETH, uint256 sharesMinted);
    event WithdrawalProcessed(address indexed depositor, uint256 depositId, uint256 stateInstanceId, uint256 amountWithdrawn);

    event StateTypeCreated(uint256 indexed stateTypeId, uint256 outcomeCount);
    event StateInstanceCreated(uint256 indexed stateInstanceId, uint256 stateTypeId);
    event DepositStateInstanceAssigned(uint256 indexed depositId, uint256 indexed oldStateInstanceId, uint256 indexed newStateInstanceId);

    event StateTriggerSet(uint256 indexed stateInstanceId, QuantumFlowVault.QuantumStateInstance.TriggerType triggerType, uint64 timestamp, address oracleAddress, bytes4 oracleSig);
    event StateTriggerMet(uint256 indexed stateInstanceId);
    event StateCollapsed(uint256 indexed stateInstanceId, uint256 outcomeIndex, uint256 outcomeValue);

    event StatesEntangled(uint256 indexed stateInstanceId1, uint256 indexed stateInstanceId2);
    event StatesDisentangled(uint256 indexed stateInstanceId1, uint256 indexed stateInstanceId2);
    event DecoherenceInitiated(address indexed by);

    event DynamicFeeSet(uint8 indexed feeType, uint256 percentage);
    event FeesCollected(uint8 indexed feeType, uint256 amount);

    // --- Modifiers ---

    modifier onlyGovernance() {
        require(msg.sender == governance, "Not governance");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Vault is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Vault is not paused");
        _;
    }

    // --- Constructor ---

    constructor() {
        governance = msg.sender;
    }

    // --- Governance & Pause Functions (4) ---

    /**
     * @dev Pauses deposits, withdrawals, and state modification operations.
     *      Only governance can call.
     */
    function pauseVault() external onlyGovernance whenNotPaused {
        paused = true;
        emit VaultPaused(msg.sender);
    }

    /**
     * @dev Unpauses the vault, allowing normal operations.
     *      Only governance can call.
     */
    function unpauseVault() external onlyGovernance whenPaused {
        paused = false;
        emit VaultUnpaused(msg.sender);
    }

    /**
     * @dev Transfers governance ownership to a new address.
     *      Only current governance can call.
     * @param newGovernance The address of the new governance.
     */
    function setGovernanceAddress(address newGovernance) external onlyGovernance {
        require(newGovernance != address(0), "New governance cannot be zero address");
        address oldGovernance = governance;
        governance = newGovernance;
        emit GovernanceTransferred(oldGovernance, newGovernance);
    }

    /**
     * @dev Checks the total balance of Ether held by the vault.
     * @return totalBalance The total amount of Ether in the contract.
     */
    function getVaultBalance() external view returns (uint256 totalBalance) {
        return address(this).balance;
    }


    // --- Core Vault Functions (2) ---

    /**
     * @dev Allows a user to deposit Ether into a specific state instance.
     *      The state instance must exist and be in Superposition.
     *      User receives shares proportional to their deposit vs total deposits in that instance.
     * @param stateInstanceId The ID of the state instance to deposit into.
     */
    function deposit(uint256 stateInstanceId) external payable whenNotPaused {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        QuantumStateInstance storage instance = stateInstances[stateInstanceId];
        require(instance.id != 0, "State instance does not exist");
        require(instance.inSuperposition, "State instance must be in Superposition");

        uint256 depositAmount = msg.value;
        uint256 totalDepositsBefore = instance.totalDepositsETH;
        uint256 totalSharesBefore = instance.totalShares;

        // Calculate shares to mint. If first deposit, 1 share = 1 ETH (or any base ratio).
        // Otherwise, shares are proportional to the value relative to total deposits.
        uint256 sharesMinted;
        if (totalSharesBefore == 0) {
            sharesMinted = depositAmount; // 1 share per wei for simplicity, adjust as needed
        } else {
             // sharesMinted = (depositAmount * totalSharesBefore) / totalDepositsBefore;
             // Using 1e18 for precision similar to ERC-20/721 ratios
             sharesMinted = (depositAmount * 1e18) / (totalDepositsBefore > 0 ? totalDepositsBefore : 1e18); // Prevent division by zero on edge case
             if (totalSharesBefore > 0) {
                 sharesMinted = (depositAmount * totalSharesBefore) / totalDepositsBefore;
             } else {
                 sharesMinted = depositAmount; // First deposit into this state instance
             }
        }

        instance.totalDepositsETH += depositAmount;
        instance.totalShares += sharesMinted;

        // Record the individual deposit share
        uint256 newDepositId = _depositIdCounter++;
        depositShares[newDepositId] = DepositShare({
            id: newDepositId,
            depositor: msg.sender,
            stateInstanceId: stateInstanceId,
            amountETH: depositAmount,
            shares: sharesMinted,
            withdrawn: false
        });

        userDepositShareIds[msg.sender].push(newDepositId);
        stateInstanceDepositShareIds[stateInstanceId].push(newDepositId);

        emit DepositReceived(msg.sender, newDepositId, stateInstanceId, depositAmount, sharesMinted);
    }

    /**
     * @dev Allows a user to withdraw their share from a collapsed state instance.
     *      The state instance must be Collapsed.
     *      Withdrawal amount is calculated based on the user's shares and the collapsed outcome value.
     * @param depositId The ID of the specific deposit share to withdraw.
     */
    function withdraw(uint256 depositId) external whenNotPaused {
        DepositShare storage share = depositShares[depositId];
        require(share.id != 0, "Deposit share does not exist");
        require(share.depositor == msg.sender, "Not your deposit share");
        require(!share.withdrawn, "Deposit share already withdrawn");

        QuantumStateInstance storage instance = stateInstances[share.stateInstanceId];
        require(!instance.inSuperposition, "State instance must be collapsed to withdraw");
        require(instance.collapsedOutcomeValue > 0, "State outcome value is zero, no withdrawal possible"); // Should not happen if outcome is valid

        // Calculate withdrawable amount based on shares and collapsed outcome value
        // Formula: userWithdrawal = (userShares * collapsedOutcomeValue * totalDepositsETH_in_instance) / (totalShares_in_instance * totalPossibleOutcomeValue_from_type)
        // Need to get totalPossibleOutcomeValue_from_type from StateType
        StateType storage stateType = stateTypes[instance.stateTypeId];
        require(stateType.id != 0, "State Type definition missing for instance");

        // We need a base outcome value sum from the StateType for proportional calculation.
        // Let's use the sum of all outcome values as the base 'potential'.
        // Or, more simply, consider the outcome value as a multiplier of the user's *initial* deposit amount relative to the total deposit into that state.
        // Let's use the share ratio against the total deposits *into that instance*, scaled by the collapsed outcome value relative to a base unit (e.g., 1e18).

        uint256 userProportionOfState = (share.shares * 1e18) / instance.totalShares; // User's shares relative to total shares, scaled
        uint256 potentialWithdrawal = (userProportionOfState * instance.totalDepositsETH) / 1e18; // User's proportion of the original deposit pool

        // Scale the potential withdrawal by the collapsed outcome value relative to a base (e.g., 1e18 or sum of potential values)
        // Let's assume outcomeValues in StateType are scaled relative to 1e18 where 1e18 = 1x multiplier of initial deposit proportion.
        // So, outcomeValue 2e18 means 2x multiplier, 0.5e18 means 0.5x multiplier.
        uint256 withdrawalAmount = (potentialWithdrawal * instance.collapsedOutcomeValue) / 1e18;

        // Apply withdrawal fee if set
        uint256 feePercentage = dynamicFeesPercentage[uint8(FeeType.Withdrawal)];
        uint256 feeAmount = (withdrawalAmount * feePercentage) / 10000; // FeePercentage is in 1/100th of a percent (10000 = 100%)
        uint256 amountToUser = withdrawalAmount - feeAmount;

        // Update state
        share.withdrawn = true;
        accruedFees[uint8(FeeType.Withdrawal)] += feeAmount;

        // Transfer Ether
        require(amountToUser > 0, "Withdrawal amount is zero"); // Should be positive if outcome is positive
        (bool success, ) = payable(msg.sender).call{value: amountToUser}("");
        require(success, "ETH transfer failed");

        emit WithdrawalProcessed(msg.sender, depositId, share.stateInstanceId, amountToUser);
    }

    // --- State Type & Instance Management (4) ---

    /**
     * @dev Governance defines a new type of quantum state.
     *      This includes potential outcomes, their relative weights (for collapse probability),
     *      and their relative values (e.g., payout multipliers).
     * @param outcomeCount Number of distinct outcomes for this type.
     * @param distributionWeights Array of weights corresponding to each outcome.
     * @param outcomeValues Array of relative values corresponding to each outcome.
     *                      These values determine the payout multiplier. Use 1e18 for a 1x multiplier.
     * @param initialParams Optional bytes for type-specific initialization data.
     * @return stateTypeId The ID of the newly created state type.
     */
    function createStateType(uint256 outcomeCount, uint256[] calldata distributionWeights, uint256[] calldata outcomeValues, bytes calldata initialParams)
        external onlyGovernance whenNotPaused
        returns (uint256 stateTypeId)
    {
        require(outcomeCount > 0, "Outcome count must be positive");
        require(distributionWeights.length == outcomeCount, "Weights array length mismatch");
        require(outcomeValues.length == outcomeCount, "Values array length mismatch");

        stateTypeId = _stateTypeIdCounter++;
        stateTypes[stateTypeId] = StateType({
            id: stateTypeId,
            outcomeCount: outcomeCount,
            distributionWeights: distributionWeights,
            outcomeValues: outcomeValues,
            initialParams: initialParams
        });

        emit StateTypeCreated(stateTypeId, outcomeCount);
    }

     /**
     * @dev Governance creates a specific instance of a registered StateType.
     *      Deposits will be directed towards these instances.
     * @param stateTypeId The ID of the StateType to instantiate.
     * @param initialParams Optional bytes for instance-specific parameters.
     * @return stateInstanceId The ID of the newly created state instance.
     */
    function createStateInstance(uint256 stateTypeId, bytes calldata initialParams)
        external onlyGovernance whenNotPaused
        returns (uint256 stateInstanceId)
    {
        require(stateTypes[stateTypeId].id != 0, "State Type does not exist");

        stateInstanceId = _stateInstanceIdCounter++;
        stateInstances[stateInstanceId] = QuantumStateInstance({
            id: stateInstanceId,
            stateTypeId: stateTypeId,
            currentParams: initialParams, // Initialize with instance-specific data
            inSuperposition: true,
            collapsedOutcomeIndex: 0, // Default or invalid index
            collapsedOutcomeValue: 0, // Default or invalid value
            totalDepositsETH: 0,
            totalShares: 0,
            entangledStateId: 0,
            isEntangled: false,
            triggerType: QuantumStateInstance.TriggerType.None,
            collapseTimestamp: 0,
            oracleAddress: address(0),
            oracleFunctionSig: bytes4(0),
            triggerMet: false // Trigger is not met initially
        });

        emit StateInstanceCreated(stateInstanceId, stateTypeId);
    }

    /**
     * @dev Governance can assign an existing deposit share to a different state instance.
     *      Can be used for migration or restructuring.
     * @param depositId The ID of the deposit share to re-assign.
     * @param newStateInstanceId The ID of the target state instance.
     */
    function assignStateTypeToDeposit(uint256 depositId, uint256 newStateInstanceId) external onlyGovernance whenNotPaused {
        DepositShare storage share = depositShares[depositId];
        require(share.id != 0, "Deposit share does not exist");
        require(!share.withdrawn, "Cannot re-assign withdrawn share");
        QuantumStateInstance storage oldInstance = stateInstances[share.stateInstanceId];
        QuantumStateInstance storage newInstance = stateInstances[newStateInstanceId];
        require(newInstance.id != 0, "New state instance does not exist");
        require(newInstance.inSuperposition, "Cannot assign to a collapsed state instance");

        uint256 oldStateInstanceId = share.stateInstanceId;

        // Update deposit share pointer
        share.stateInstanceId = newStateInstanceId;

        // Update total deposits and shares in both instances
        require(oldInstance.totalShares >= share.shares, "Old instance share mismatch"); // Should not happen
        oldInstance.totalDepositsETH -= share.amountETH;
        oldInstance.totalShares -= share.shares;

        newInstance.totalDepositsETH += share.amountETH;
        newInstance.totalShares += share.shares;

        // Update mapping (less efficient but needed for listing shares per instance)
        // Remove depositId from old instance's list (simple approach: iterate and remove)
        uint256[] storage oldInstanceShareIds = stateInstanceDepositShareIds[oldStateInstanceId];
        for (uint i = 0; i < oldInstanceShareIds.length; i++) {
            if (oldInstanceShareIds[i] == depositId) {
                oldInstanceShareIds[i] = oldInstanceShareIds[oldInstanceShareIds.length - 1];
                oldInstanceShareIds.pop();
                break;
            }
        }
         // Add depositId to new instance's list
        stateInstanceDepositShareIds[newStateInstanceId].push(depositId);

        emit DepositStateInstanceAssigned(depositId, oldStateInstanceId, newStateInstanceId);
    }

    /**
     * @dev View function returning the parameters and current status of a state instance.
     *      Does NOT reveal the collapsed outcome if still in Superposition.
     * @param stateInstanceId The ID of the state instance.
     * @return details Struct containing instance details.
     */
    function getStateDetails(uint256 stateInstanceId)
        external view
        returns (
            uint256 id,
            uint256 stateTypeId,
            bool inSuperposition,
            uint256 totalDepositsETH,
            uint256 totalShares,
            uint256 entangledStateId,
            QuantumFlowVault.QuantumStateInstance.TriggerType triggerType,
            uint64 collapseTimestamp,
            address oracleAddress,
            bytes4 oracleFunctionSig,
            bool triggerMet
        )
    {
        QuantumStateInstance storage instance = stateInstances[stateInstanceId];
        require(instance.id != 0, "State instance does not exist");

        // Check if trigger condition is met without modifying state
        bool currentTriggerMet = _isTriggerMet(instance);

        return (
            instance.id,
            instance.stateTypeId,
            instance.inSuperposition,
            instance.totalDepositsETH,
            instance.totalShares,
            instance.entangledStateId,
            instance.triggerType,
            instance.collapseTimestamp,
            instance.oracleAddress,
            instance.oracleFunctionSig,
            currentTriggerMet // Return current status, not the stored one
        );
    }

    // --- State Collapse & Outcome (2) ---

    /**
     * @dev Triggers the collapse of a specific state instance from Superposition to Collapsed.
     *      Requires the state to be in Superposition and its trigger condition to be met.
     *      Simulates the outcome based on the StateType rules and potential oracle data/block data.
     *      Recursively triggers collapse of entangled states if applicable.
     * @param stateInstanceId The ID of the state instance to collapse.
     * @param oracleData Optional bytes data from a simulated oracle call if trigger type is Oracle.
     */
    function triggerStateCollapse(uint256 stateInstanceId, bytes calldata oracleData) external whenNotPaused {
        QuantumStateInstance storage instance = stateInstances[stateInstanceId];
        require(instance.id != 0, "State instance does not exist");
        require(instance.inSuperposition, "State instance is already collapsed");

        // Check and update trigger status
        if (!instance.triggerMet) {
            instance.triggerMet = _isTriggerMet(instance);
        }
        require(instance.triggerMet, "State trigger condition not met");

        StateType storage stateType = stateTypes[instance.stateTypeId];
        require(stateType.id != 0, "State Type definition missing for instance");

        // --- Simulate Quantum Measurement & Collapse ---
        // This is the core 'randomness' or external dependency part.
        // In a real contract, use a secure oracle like Chainlink VRF for randomness.
        // Here, we use block data and transaction sender as a *simulation*.
        // This is NOT cryptographically secure randomness on-chain.
        uint256 entropy = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty, // Deprecated in PoS, use block.basefee
            block.number,
            msg.sender,
            stateInstanceId,
            oracleData // Include oracle data if provided
        )));

        // Determine outcome based on distribution weights
        uint256 totalWeight = 0;
        for (uint i = 0; i < stateType.distributionWeights.length; i++) {
            totalWeight += stateType.distributionWeights[i];
        }
        require(totalWeight > 0, "State Type has zero total weight"); // Should be caught on creation

        uint256 choice = entropy % totalWeight;
        uint256 selectedOutcomeIndex = 0;
        uint256 cumulativeWeight = 0;

        for (uint i = 0; i < stateType.outcomeCount; i++) {
            cumulativeWeight += stateType.distributionWeights[i];
            if (choice < cumulativeWeight) {
                selectedOutcomeIndex = i;
                break;
            }
        }

        // --- Apply Collapse Outcome ---
        instance.inSuperposition = false;
        instance.collapsedOutcomeIndex = selectedOutcomeIndex;
        instance.collapsedOutcomeValue = stateType.outcomeValues[selectedOutcomeIndex]; // Store the determined value

        emit StateCollapsed(stateInstanceId, selectedOutcomeIndex, instance.collapsedOutcomeValue);

        // --- Handle Entanglement (Recursive Collapse) ---
        if (instance.isEntangled && instance.entangledStateId != 0) {
            QuantumStateInstance storage entangledInstance = stateInstances[instance.entangledStateId];
            if (entangledInstance.inSuperposition) {
                // Simple entanglement: Collapsing one forces the *same* outcome on the other.
                // More complex entanglement logic is possible (e.g., anti-correlated outcomes).
                // Here, we apply the same outcome index. The value might differ if StateType is different.
                StateType storage entangledStateType = stateTypes[entangledInstance.stateTypeId];
                 require(entangledStateType.id != 0, "Entangled State Type definition missing");

                // Find if the collapsed outcome index exists in the entangled state type
                uint256 entangledOutcomeIndex = selectedOutcomeIndex; // Default to same index
                if (entangledOutcomeIndex >= entangledStateType.outcomeCount) {
                    // If the exact index doesn't exist in the entangled type,
                    // map it deterministically, e.g., to the first outcome, or error.
                    // For simplicity, let's map to index 0 if out of bounds.
                    entangledOutcomeIndex = 0;
                     // Or better: Re-calculate based on a derived entropy from the first outcome/instance details
                     uint256 entangledEntropy = uint256(keccak256(abi.encodePacked(
                         stateInstanceId, // ID of the collapsing state
                         selectedOutcomeIndex, // Outcome of the collapsing state
                         block.number,
                         block.timestamp,
                         entangledInstance.id // ID of the entangled state
                     )));
                     uint256 totalEntangledWeight = 0;
                      for (uint i = 0; i < entangledStateType.distributionWeights.length; i++) {
                        totalEntangledWeight += entangledStateType.distributionWeights[i];
                    }
                    uint256 entangledChoice = entangledEntropy % totalEntangledWeight;
                     entangledOutcomeIndex = 0;
                    uint265 entangledCumulativeWeight = 0;
                     for (uint i = 0; i < entangledStateType.outcomeCount; i++) {
                        entangledCumulativeWeight += entangledStateType.distributionWeights[i];
                        if (entangledChoice < entangledCumulativeWeight) {
                            entangledOutcomeIndex = i;
                            break;
                        }
                    }
                }


                entangledInstance.inSuperposition = false;
                entangledInstance.collapsedOutcomeIndex = entangledOutcomeIndex;
                entangledInstance.collapsedOutcomeValue = entangledStateType.outcomeValues[entangledOutcomeIndex]; // Store the determined value

                // Break entanglement after collapse (Decoherence upon measurement)
                instance.isEntangled = false;
                instance.entangledStateId = 0;
                entangledInstance.isEntangled = false;
                entangledInstance.entangledStateId = 0;

                emit StateCollapsed(entangledInstance.id, entangledOutcomeIndex, entangledInstance.collapsedOutcomeValue);
                emit StatesDisentangled(stateInstanceId, entangledInstance.id); // Emit disentanglement event

            } else {
                 // If entangled state is already collapsed, break entanglement
                 instance.isEntangled = false;
                 instance.entangledStateId = 0;
                 emit StatesDisentangled(stateInstanceId, entangledInstance.id);
            }
        }
    }

    /**
     * @dev View function returning the determined outcome index and value of a Collapsed state instance.
     * @param stateInstanceId The ID of the state instance.
     * @return outcomeIndex The index of the collapsed outcome.
     * @return outcomeValue The value associated with the collapsed outcome.
     */
    function getCollapsedStateOutcome(uint256 stateInstanceId)
        external view
        returns (uint256 outcomeIndex, uint256 outcomeValue)
    {
        QuantumStateInstance storage instance = stateInstances[stateInstanceId];
        require(instance.id != 0, "State instance does not exist");
        require(!instance.inSuperposition, "State instance has not collapsed yet");

        return (instance.collapsedOutcomeIndex, instance.collapsedOutcomeValue);
    }

    // --- Entanglement Management (3) ---

    /**
     * @dev Governance links two state instances, creating an entanglement.
     *      Requires both states to be in Superposition and not already entangled.
     *      Collapsing one entangled state will trigger the collapse of the other.
     * @param stateInstanceId1 The ID of the first state instance.
     * @param stateInstanceId2 The ID of the second state instance.
     */
    function entangleStates(uint256 stateInstanceId1, uint256 stateInstanceId2) external onlyGovernance whenNotPaused {
        require(stateInstanceId1 != stateInstanceId2, "Cannot entangle a state with itself");
        QuantumStateInstance storage instance1 = stateInstances[stateInstanceId1];
        QuantumStateInstance storage instance2 = stateInstances[stateInstanceId2];

        require(instance1.id != 0 && instance2.id != 0, "One or both state instances do not exist");
        require(instance1.inSuperposition && instance2.inSuperposition, "Both states must be in Superposition");
        require(!instance1.isEntangled && !instance2.isEntangled, "One or both states are already entangled");

        instance1.entangledStateId = stateInstanceId2;
        instance1.isEntangled = true;
        instance2.entangledStateId = stateInstanceId1;
        instance2.isEntangled = true;

        emit StatesEntangled(stateInstanceId1, stateInstanceId2);
    }

    /**
     * @dev Governance removes the entanglement link between two state instances.
     *      Can be called even if states are collapsed, but primarily useful before collapse.
     * @param stateInstanceId1 The ID of the first state instance.
     * @param stateInstanceId2 The ID of the second state instance.
     */
    function disentangleStates(uint256 stateInstanceId1, uint256 stateInstanceId2) external onlyGovernance {
        QuantumStateInstance storage instance1 = stateInstances[stateInstanceId1];
        QuantumStateInstance storage instance2 = stateInstances[stateInstanceId2];

        require(instance1.id != 0 && instance2.id != 0, "One or both state instances do not exist");
        require(instance1.isEntangled && instance1.entangledStateId == stateInstanceId2, "States are not entangled with each other");
        require(instance2.isEntangled && instance2.entangledStateId == stateInstanceId1, "States are not entangled with each other"); // Redundant check but good practice

        instance1.entangledStateId = 0;
        instance1.isEntangled = false;
        instance2.entangledStateId = 0;
        instance2.isEntangled = false;

        emit StatesDisentangled(stateInstanceId1, stateInstanceId2);
    }

     /**
     * @dev Governance initiates a 'decoherence' event, forcibly disentangling ALL
     *      currently entangled state instances. Useful for emergency reset or
     *      breaking complex interdependencies.
     */
    function initiateDecoherence() external onlyGovernance whenNotPaused {
        // Note: Iterating through all state instances can be gas-intensive.
        // For many instances, a more gas-efficient approach (e.g., tracking entangled pairs in a separate list) is needed.
        // For this example, we iterate through existing instances up to the current counter.
        // This is a simplified, potentially costly approach for a very large number of states.

        for (uint256 i = 1; i <= _stateInstanceIdCounter; i++) {
            QuantumStateInstance storage instance = stateInstances[i];
             // Check if instance exists and is currently entangled
            if (instance.id != 0 && instance.isEntangled) {
                uint256 entangledPartnerId = instance.entangledStateId;
                // Check if the partner still exists and is correctly entangled back
                 if (entangledPartnerId != 0 && stateInstances[entangledPartnerId].id != 0 &&
                    stateInstances[entangledPartnerId].isEntangled && stateInstances[entangledPartnerId].entangledStateId == instance.id)
                 {
                    // Perform disentanglement for the pair
                    instance.isEntangled = false;
                    instance.entangledStateId = 0;
                    stateInstances[entangledPartnerId].isEntangled = false;
                    stateInstances[entangledPartnerId].entangledStateId = 0;
                    emit StatesDisentangled(instance.id, entangledPartnerId);
                 } else if (instance.isEntangled) {
                     // Handle potential orphaned entanglement pointers (shouldn't happen if logic is correct)
                     instance.isEntangled = false;
                     instance.entangledStateId = 0;
                     // Log warning or emit specific event if this edge case occurs
                 }
            }
        }
         emit DecoherenceInitiated(msg.sender);
    }


    // --- Trigger Management (3) ---

     /**
     * @dev Internal helper to check if a state instance's trigger condition is met.
     *      Does not modify state.
     * @param instance The QuantumStateInstance struct.
     * @return True if trigger is met, false otherwise.
     */
    function _isTriggerMet(QuantumStateInstance storage instance) internal view returns (bool) {
         if (instance.inSuperposition) { // Only check trigger if still in superposition
            if (instance.triggerType == QuantumStateInstance.TriggerType.Time) {
                return block.timestamp >= instance.collapseTimestamp;
            } else if (instance.triggerType == QuantumStateInstance.TriggerType.Oracle) {
                // Simulate Oracle trigger check - requires external call success/data availability
                // In a real contract, this would involve checking a flag set by a trusted oracle relayer.
                // For this simulation, we'll assume the trigger is met if oracleAddress is set.
                 return instance.oracleAddress != address(0); // Simplified: trigger met if oracle registered
            } else if (instance.triggerType == QuantumStateInstance.TriggerType.Manual) {
                 // Manual trigger always requires a call to triggerStateCollapse, so it's met when called.
                 // No separate check needed here for _isTriggerMet, but we can add a flag if manual triggers need preconditions.
                 return true; // Assume Manual trigger is always "met" conceptually for triggering.
            }
         }
         return false; // Not in superposition or trigger type is None
    }


    /**
     * @dev Governance registers a simulated oracle call as the trigger for a state instance collapse.
     *      Replaces any existing trigger for this instance.
     * @param stateInstanceId The ID of the state instance.
     * @param oracleAddress The simulated address of the oracle contract.
     * @param oracleFunctionSig The simulated function signature to call/listen for.
     */
    function registerOracleTrigger(uint256 stateInstanceId, address oracleAddress, bytes4 oracleFunctionSig) external onlyGovernance whenNotPaused {
        QuantumStateInstance storage instance = stateInstances[stateInstanceId];
        require(instance.id != 0, "State instance does not exist");
        require(instance.inSuperposition, "Cannot set trigger for collapsed state");
        require(oracleAddress != address(0), "Oracle address cannot be zero");
        require(oracleFunctionSig != bytes4(0), "Oracle function signature cannot be zero");

        instance.triggerType = QuantumStateInstance.TriggerType.Oracle;
        instance.oracleAddress = oracleAddress;
        instance.oracleFunctionSig = oracleFunctionSig;
        instance.collapseTimestamp = 0; // Clear other triggers
        instance.triggerMet = false; // Reset trigger met flag

        emit StateTriggerSet(stateInstanceId, instance.triggerType, 0, oracleAddress, oracleFunctionSig);
    }

    /**
     * @dev Governance registers a specific timestamp as the trigger for a state instance collapse.
     *      Replaces any existing trigger for this instance.
     * @param stateInstanceId The ID of the state instance.
     * @param collapseTimestamp The timestamp when the state becomes eligible for collapse.
     */
    function registerTimeTrigger(uint256 stateInstanceId, uint64 collapseTimestamp) external onlyGovernance whenNotPaused {
        QuantumStateInstance storage instance = stateInstances[stateInstanceId];
        require(instance.id != 0, "State instance does not exist");
        require(instance.inSuperposition, "Cannot set trigger for collapsed state");
        require(collapseTimestamp > block.timestamp, "Collapse timestamp must be in the future");

        instance.triggerType = QuantumStateInstance.TriggerType.Time;
        instance.collapseTimestamp = collapseTimestamp;
        instance.oracleAddress = address(0); // Clear other triggers
        instance.oracleFunctionSig = bytes4(0); // Clear other triggers
        instance.triggerMet = false; // Reset trigger met flag

        emit StateTriggerSet(stateInstanceId, instance.triggerType, collapseTimestamp, address(0), bytes4(0));
    }

    /**
     * @dev Governance triggers the collapse of multiple state instances in a single transaction.
     *      Each instance must exist, be in Superposition, and have its trigger condition met.
     *      Does not support Oracle triggers in batch unless external data for *all* is provided.
     *      This version assumes manual or time triggers for simplicity in batching.
     * @param stateInstanceIds An array of state instance IDs to attempt to collapse.
     */
    function batchCollapseStates(uint256[] calldata stateInstanceIds) external onlyGovernance whenNotPaused {
        // Note: This can be gas-intensive depending on the number of states and entanglement.
        // Entanglement collapse is recursive, which could lead to stack depth issues for deeply entangled graphs.
        // For simplicity, this implementation allows recursion. A production system might need iterative collapse.

        for (uint i = 0; i < stateInstanceIds.length; i++) {
            uint256 instanceId = stateInstanceIds[i];
            QuantumStateInstance storage instance = stateInstances[instanceId];

            if (instance.id != 0 && instance.inSuperposition) {
                // Check if trigger is met for this instance (Oracle requires external data, excluded here)
                if (instance.triggerType == QuantumStateInstance.TriggerType.Time && _isTriggerMet(instance)) {
                    // Trigger collapse (empty oracleData as not applicable for Time trigger)
                    triggerStateCollapse(instanceId, "");
                } else if (instance.triggerType == QuantumStateInstance.TriggerType.Manual) {
                     // Manual trigger is considered met when called
                     triggerStateCollapse(instanceId, "");
                }
                // Oracle triggers are NOT processed in this batch function as they require specific oracleData per instance.
                // States with triggers not met are skipped.
            }
        }
    }

    // --- Fee Management (2) ---

     /**
     * @dev Governance sets the dynamic fee percentage for a specific fee type.
     *      FeePercentage is in hundredths of a percent (e.g., 100 = 1%). Max 10000 (100%).
     * @param feeType The type of fee to set (defined in FeeType enum).
     * @param feePercentage The fee percentage (in hundredths of a percent).
     */
    function setDynamicFee(uint8 feeType, uint256 feePercentage) external onlyGovernance {
        require(feeType < uint8(FeeType.Withdrawal) + 1, "Invalid fee type"); // Ensure it's a defined fee type
        require(feePercentage <= 10000, "Fee percentage cannot exceed 100%"); // Max 100%

        dynamicFeesPercentage[feeType] = feePercentage;
        emit DynamicFeeSet(feeType, feePercentage);
    }

    /**
     * @dev Governance collects accrued fees of a specific type.
     *      Transfers the collected Ether to the governance address.
     * @param feeType The type of fee to collect.
     */
    function collectFees(uint8 feeType) external onlyGovernance {
        require(feeType < uint8(FeeType.Withdrawal) + 1, "Invalid fee type");
        uint256 amountToCollect = accruedFees[feeType];
        require(amountToCollect > 0, "No fees to collect for this type");

        accruedFees[feeType] = 0; // Reset accrued fees for this type

        (bool success, ) = payable(governance).call{value: amountToCollect}("");
        require(success, "Fee collection transfer failed");

        emit FeesCollected(feeType, amountToCollect);
    }

    // --- View Functions (3) ---

    /**
     * @dev View function to get all deposit share IDs associated with a user.
     * @param user The address of the user.
     * @return shareIds An array of deposit share IDs belonging to the user.
     */
    function getUserDepositShares(address user) external view returns (uint256[] memory shareIds) {
        return userDepositShareIds[user];
    }

    /**
     * @dev View function to get a list of state instance IDs that are currently
     *      in Superposition and have their trigger condition met.
     *      Note: This can be gas-intensive if there are many state instances.
     * @return eligibleIds An array of state instance IDs ready for collapse.
     */
    function getEligibleStatesForCollapse() external view returns (uint256[] memory eligibleIds) {
        uint256[] memory potentialIds = new uint256[](_stateInstanceIdCounter);
        uint256 count = 0;

        for (uint256 i = 1; i <= _stateInstanceIdCounter; i++) {
            QuantumStateInstance storage instance = stateInstances[i];
            if (instance.id != 0 && instance.inSuperposition) {
                 // Check if trigger is met without modifying state
                 if (_isTriggerMet(instance)) {
                     potentialIds[count] = instance.id;
                     count++;
                 }
            }
        }

        // Trim the array to the actual count
        uint265[] memory result = new uint256[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = potentialIds[i];
        }
        return result;
    }

    /**
     * @dev View function to calculate a user's *potential* withdrawal amount
     *      for a specific deposit share, assuming a given potential outcome value
     *      of the associated state instance. Useful for pre-collapse simulation.
     * @param user The address of the user.
     * @param depositId The ID of the user's deposit share.
     * @param assumedOutcomeValue The assumed relative value of the state instance's outcome (e.g., 1e18 for 1x multiplier).
     * @return potentialAmount The calculated potential withdrawal amount based on the assumption.
     */
    function calculatePotentialWithdrawalAmount(address user, uint256 depositId, uint256 assumedOutcomeValue)
        external view
        returns (uint256 potentialAmount)
    {
        DepositShare storage share = depositShares[depositId];
        require(share.id != 0, "Deposit share does not exist");
        require(share.depositor == user, "Not your deposit share");

        QuantumStateInstance storage instance = stateInstances[share.stateInstanceId];
        require(instance.id != 0, "State instance does not exist");
        // Can calculate for collapsed or superposition states based on assumption

        // If already withdrawn, potential withdrawal is 0 for this share.
        if (share.withdrawn) {
            return 0;
        }

        // Calculation is the same as in withdraw, but using assumedOutcomeValue
        uint256 userProportionOfState = (share.shares * 1e18) / instance.totalShares;
        uint256 potentialWithdrawalBeforeScaling = (userProportionOfState * instance.totalDepositsETH) / 1e18;

        // Scale by assumed outcome value
        uint256 calculatedAmount = (potentialWithdrawalBeforeScaling * assumedOutcomeValue) / 1e18;

        // Deduct fee
        uint256 feePercentage = dynamicFeesPercentage[uint8(FeeType.Withdrawal)];
        uint256 feeAmount = (calculatedAmount * feePercentage) / 10000;
        potentialAmount = calculatedAmount - feeAmount;

        return potentialAmount;
    }

    // --- Additional Functions (4) - Adding more complexity/utility ---

    /**
     * @dev View function returning the list of deposit share IDs currently
     *      linked to a specific state instance.
     * @param stateInstanceId The ID of the state instance.
     * @return shareIds An array of deposit share IDs linked to the instance.
     */
    function getDepositsByState(uint256 stateInstanceId) external view returns (uint256[] memory shareIds) {
         QuantumStateInstance storage instance = stateInstances[stateInstanceId];
        require(instance.id != 0, "State instance does not exist");
        return stateInstanceDepositShareIds[stateInstanceId];
    }

    /**
     * @dev View function returning a user's specific deposit share details.
     * @param depositId The ID of the deposit share.
     * @return depositor, stateInstanceId, amountETH, shares, withdrawn
     */
    function getUserDepositShareDetails(uint256 depositId)
        external view
        returns (address depositor, uint256 stateInstanceId, uint256 amountETH, uint256 shares, bool withdrawn)
    {
        DepositShare storage share = depositShares[depositId];
        require(share.id != 0, "Deposit share does not exist");
        return (share.depositor, share.stateInstanceId, share.amountETH, share.shares, share.withdrawn);
    }

     /**
     * @dev Allows governance to forcefully set a specific outcome for a state instance,
     *      bypassing normal trigger and probabilistic collapse logic. Can be used for
     *      emergency or manual resolution.
     * @param stateInstanceId The ID of the state instance to collapse.
     * @param outcomeIndex The index of the desired outcome from its StateType.
     */
    function forceStateCollapseOutcome(uint256 stateInstanceId, uint256 outcomeIndex) external onlyGovernance whenNotPaused {
        QuantumStateInstance storage instance = stateInstances[stateInstanceId];
        require(instance.id != 0, "State instance does not exist");
        require(instance.inSuperposition, "State instance is already collapsed");

        StateType storage stateType = stateTypes[instance.stateTypeId];
        require(stateType.id != 0, "State Type definition missing for instance");
        require(outcomeIndex < stateType.outcomeCount, "Invalid outcome index for this state type");

        // --- Force Collapse ---
        instance.inSuperposition = false;
        instance.collapsedOutcomeIndex = outcomeIndex;
        instance.collapsedOutcomeValue = stateType.outcomeValues[outcomeIndex]; // Use the value from the StateType

        // Set triggerMet to true to reflect resolution
        instance.triggerMet = true;

        emit StateCollapsed(stateInstanceId, outcomeIndex, instance.collapsedOutcomeValue);

        // Handle Entanglement - forces entangled state to collapse with same index (if valid) or fallback
        if (instance.isEntangled && instance.entangledStateId != 0) {
             QuantumStateInstance storage entangledInstance = stateInstances[instance.entangledStateId];
            if (entangledInstance.id != 0 && entangledInstance.inSuperposition) {
                 StateType storage entangledStateType = stateTypes[entangledInstance.stateTypeId];
                 if (entangledStateType.id != 0) {
                    uint256 forcedEntangledIndex = outcomeIndex < entangledStateType.outcomeCount ? outcomeIndex : 0; // Use same index if valid, else first outcome
                    entangledInstance.inSuperposition = false;
                    entangledInstance.collapsedOutcomeIndex = forcedEntangledIndex;
                    entangledInstance.collapsedOutcomeValue = entangledStateType.outcomeValues[forcedEntangledIndex];
                    entangledInstance.triggerMet = true; // Also set met
                     emit StateCollapsed(entangledInstance.id, forcedEntangledIndex, entangledInstance.collapsedOutcomeValue);
                 }
                 // Break entanglement after collapse
                 instance.isEntangled = false;
                 instance.entangledStateId = 0;
                 entangledInstance.isEntangled = false;
                 entangledInstance.entangledStateId = 0;
                 emit StatesDisentangled(stateInstanceId, entangledInstance.id);
            } else if (instance.isEntangled) {
                 // If entangled state is already collapsed or invalid, break entanglement
                 instance.isEntangled = false;
                 instance.entangledStateId = 0;
                  if (entangledInstance.id != 0) { // Only emit if partner existed
                      emit StatesDisentangled(stateInstanceId, entangledInstance.id);
                  }
            }
        }
    }

    /**
     * @dev Allows governance to define or update a specific StateType's parameters.
     *      Existing StateInstances of this type are NOT affected unless explicitly migrated.
     * @param stateTypeId The ID of the StateType to update.
     * @param distributionWeights New array of weights.
     * @param outcomeValues New array of outcome values.
     * @param initialParams New bytes for type-specific initial parameters.
     */
    function updateStateType(uint256 stateTypeId, uint256[] calldata distributionWeights, uint256[] calldata outcomeValues, bytes calldata initialParams)
        external onlyGovernance whenNotPaused
    {
        StateType storage stateType = stateTypes[stateTypeId];
        require(stateType.id != 0, "State Type does not exist");
        uint256 outcomeCount = stateType.outcomeCount; // Outcome count cannot change after creation

        require(distributionWeights.length == outcomeCount, "Weights array length mismatch");
        require(outcomeValues.length == outcomeCount, "Values array length mismatch");

        stateType.distributionWeights = distributionWeights;
        stateType.outcomeValues = outcomeValues;
        stateType.initialParams = initialParams; // Update params

        // No specific event for update, creation event implies definition exists
    }


    // Total Functions: 4 (Governance/Pause) + 2 (Core Vault) + 4 (State Type/Instance) + 2 (State Collapse) + 3 (Entanglement) + 3 (Triggers) + 2 (Fees) + 3 (Views) + 4 (Additional) = 27 Functions.
    // Meets the requirement of at least 20 functions.

}
```