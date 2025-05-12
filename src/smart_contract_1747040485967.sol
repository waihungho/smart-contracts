Okay, let's design a smart contract based on an advanced, creative, and somewhat metaphorical concept: a "Quantum Vault".

The idea is a vault that can hold funds (ETH and ERC20) where the final destination or unlock conditions of these funds are *not fixed* initially, but depend on external or internal conditions evaluated at a specific "collapse" event. Before the collapse, the vault is in a state analogous to quantum superposition, where multiple potential outcomes (beneficiaries, amounts, unlock times) exist simultaneously. The collapse "resolves" the state based on predefined rules and external inputs (simulated oracle data, time, etc.).

This avoids directly duplicating common patterns like simple staking, basic NFTs, or standard AMMs. It combines elements of conditional logic, time locks, multi-party allocation, and external data dependency in a unique state-driven flow.

---

**Quantum Vault Smart Contract**

**Outline:**

1.  **License & Pragma:** Standard Solidity header.
2.  **Imports:** `Ownable`, `ReentrancyGuard`, `IERC20`.
3.  **Enums:** Define possible states of the vault (`VaultState`), types of conditions (`ConditionType`).
4.  **Structs:**
    *   `BeneficiaryAllocation`: Details about an allocation for a specific beneficiary (address, ETH amount, ERC20 amount) *within* a potential state.
    *   `Condition`: Defines a condition (type, target value/address, comparison).
    *   `PotentialState`: Defines a possible outcome state (description, required condition outcomes, map of beneficiary allocations).
5.  **State Variables:**
    *   Owner address.
    *   Accepted ERC20 token address.
    *   Current vault state (`VaultState`).
    *   Total ETH balance.
    *   Total ERC20 balance.
    *   Mapping of defined conditions (`bytes32 => Condition`).
    *   Mapping of defined potential states (`bytes32 => PotentialState`).
    *   Mapping linking potential states to required condition outcomes (`bytes32 => mapping(bytes32 => bool)`: state ID => condition ID => required outcome).
    *   Array defining the priority order of potential states (`bytes32[]`).
    *   Mapping storing the actual outcome of conditions after collapse (`bytes32 => bool`).
    *   ID of the state that was resolved during collapse (`bytes32`).
    *   Mapping tracking if a beneficiary has claimed in the resolved state (`address => bool`).
    *   Simulated Oracle Data (for demonstration).
    *   Pause state variable.
6.  **Events:** Signal key actions: Deposit, Withdrawal, State Change, Condition Defined, Potential State Defined, Collapse Triggered, Allocation Claimed.
7.  **Modifiers:** Restrict function access based on state (`whenStateIs`), ownership (`onlyOwner`), pause status, claimed status.
8.  **Constructor:** Initialize owner, set initial state (`Setup`).
9.  **Core Vault Functionality:**
    *   Receive ETH.
    *   Deposit ERC20.
    *   Query balances (ETH, ERC20).
10. **Configuration (Owner only, State = Setup):**
    *   Set ERC20 token address.
    *   Define a condition (time, oracle-based, etc.).
    *   Define a potential state (assign an ID, description).
    *   Set beneficiary allocations *within* a potential state.
    *   Link a condition outcome (true/false) as a requirement for a potential state.
    *   Set the priority order of potential states.
11. **State Transition (Owner only):**
    *   Transition from `Setup` to `Superposition`.
    *   Transition from `Superposition` to `Collapsed` (the core `triggerCollapse` function).
12. **Collapse Logic (`triggerCollapse`):**
    *   Evaluates all defined conditions based on current reality (block.timestamp, simulated oracle data).
    *   Finds the highest-priority `PotentialState` whose required condition outcomes match the actual condition outcomes.
    *   Sets the `resolvedStateId`.
    *   Transitions state to `Collapsed`.
    *   Stores actual condition outcomes.
13. **Claiming (Beneficiaries, State = Collapsed):**
    *   Allows a beneficiary to claim their allocated amount based on the `resolvedStateId`.
14. **Query Functions (Anyone):**
    *   Query current vault state.
    *   Query details of a defined condition.
    *   Query details of a defined potential state.
    *   Query a beneficiary's *potential* allocation in a *specific* potential state (before collapse).
    *   Query a beneficiary's *final* allocation in the *resolved* state (after collapse).
    *   Query the status of a condition (met or not met based on current conditions).
    *   Query if a beneficiary has claimed.
15. **Admin & Safety:**
    *   Pause/Unpause functions.
    *   Emergency Withdraw (Owner only, maybe only when Paused or Setup).
    *   Renounce/Transfer Ownership (`Ownable`).
    *   Simulate Oracle Data (Owner only, for demonstration/testing).

**Function Summary (targeting 20+ unique functions):**

1.  `constructor(address _initialERC20Token)`: Deploys the contract, sets owner and initial state, optionally sets an ERC20 token.
2.  `receive() external payable`: Allows receiving Ether deposits when vault is in `Setup` or `Superposition`.
3.  `depositERC20(uint256 amount)`: Allows depositing the configured ERC20 token when vault is in `Setup` or `Superposition`.
4.  `setERC20Token(address _erc20)`: Owner sets the allowed ERC20 token address (only in `Setup`).
5.  `defineCondition(bytes32 conditionId, ConditionType conditionType, uint256 targetValue, address targetAddress)`: Owner defines a condition with a unique ID (only in `Setup`).
6.  `definePotentialState(bytes32 stateId, string description)`: Owner defines a potential outcome state with a unique ID and description (only in `Setup`).
7.  `setBeneficiaryAllocationInPotentialState(bytes32 stateId, address beneficiary, uint256 ethAmount, uint256 erc20Amount)`: Owner sets or updates an allocation for a beneficiary within a specific potential state (only in `Setup`).
8.  `setConditionRequirementForState(bytes32 stateId, bytes32 conditionId, bool requiredOutcomeIsMet)`: Owner links a condition's required outcome (true/false) to a potential state (only in `Setup`).
9.  `setPotentialStatePriority(bytes32[] _priorityOrder)`: Owner sets the ordered list of potential states used during collapse evaluation (only in `Setup`).
10. `transitionToSuperposition()`: Owner moves the vault state from `Setup` to `Superposition`.
11. `triggerCollapse()`: Owner triggers the state collapse based on current conditions (only in `Superposition`). Finds the highest priority state whose conditions are met and transitions to `Collapsed`.
12. `claimAllocation()`: A beneficiary claims their allocated ETH and ERC20 based on the `resolvedStateId` (only in `Collapsed`, only once).
13. `queryVaultState() public view returns (VaultState)`: Gets the current state of the vault.
14. `queryTotalBalanceETH() public view returns (uint256)`: Gets the total Ether balance held.
15. `queryTotalBalanceERC20() public view returns (uint256)`: Gets the total ERC20 balance held.
16. `queryConditionDetails(bytes32 conditionId) public view returns (Condition memory)`: Gets details of a defined condition.
17. `queryPotentialStateDetails(bytes32 stateId) public view returns (PotentialState memory)`: Gets details of a defined potential state (excluding beneficiary allocations for gas).
18. `queryBeneficiaryPotentialAllocation(bytes32 stateId, address beneficiary) public view returns (uint256 ethAmount, uint256 erc20Amount)`: Gets the allocation for a beneficiary within a *specific potential* state (before collapse).
19. `queryBeneficiaryFinalAllocation(address beneficiary) public view returns (uint256 ethAmount, uint256 erc20Amount)`: Gets the allocation for a beneficiary in the *resolved* state (after collapse).
20. `queryConditionStatus(bytes32 conditionId) public view returns (bool isMet)`: Checks if a specific condition is currently met (evaluates on the fly).
21. `queryHasClaimed(address beneficiary) public view returns (bool)`: Checks if a beneficiary has already claimed.
22. `queryResolvedStateId() public view returns (bytes32)`: Gets the ID of the state resolved during collapse.
23. `pauseVault()`: Owner pauses specific operations (deposits, collapse, claims).
24. `unpauseVault()`: Owner unpauses the vault.
25. `queryIsPaused() public view returns (bool)`: Checks if the vault is paused.
26. `emergencyWithdrawETH()`: Owner can withdraw all ETH (e.g., in `Paused` or `Setup`).
27. `emergencyWithdrawERC20()`: Owner can withdraw all ERC20 (e.g., in `Paused` or `Setup`).
28. `simulateOracleData(uint256 _data)`: Owner sets a simulated oracle data value (for testing `OracleData` conditions).
29. `querySimulatedOracleData() public view returns (uint256)`: Gets the currently simulated oracle data.
30. `getPotentialStatePriority() public view returns (bytes32[] memory)`: Gets the defined priority order of potential states.

This provides 30 distinct functions, exceeding the requirement of 20, and covers the core unique logic of the "Quantum Vault".

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// --- Quantum Vault Smart Contract ---
// Outline:
// 1. License & Pragma
// 2. Imports (Ownable, ReentrancyGuard, IERC20, Address)
// 3. Enums (VaultState, ConditionType)
// 4. Structs (BeneficiaryAllocation, Condition, PotentialState)
// 5. State Variables (Owner, ERC20, Balances, State, Conditions, States, Priority, Collapsed Outcomes, Resolved State, Claimed Status, Simulated Oracle Data, Pause)
// 6. Events
// 7. Modifiers (whenStateIs, whenNotStateIs, whenNotPaused, onlyBeneficiary)
// 8. Constructor
// 9. Core Vault Functionality (receive ETH, deposit ERC20, query balances)
// 10. Configuration (Owner only, State = Setup) - Define Conditions, States, Allocations, Requirements, Priority.
// 11. State Transition (Owner only) - Setup -> Superposition, Superposition -> Collapsed (triggerCollapse).
// 12. Collapse Logic (triggerCollapse) - Evaluates conditions, finds matching state by priority, resolves state.
// 13. Claiming (Beneficiaries, State = Collapsed) - Claim based on resolved state allocation.
// 14. Query Functions (Anyone) - State, Balances, Condition/State Details, Potential/Final Allocations, Condition Status, Claimed Status, Resolved State.
// 15. Admin & Safety (Owner only) - Pause/Unpause, Emergency Withdraw, Simulate Oracle Data, Ownable methods.

// Function Summary:
// constructor(address _initialERC20Token): Initializes the contract, sets owner, initial state (Setup), and optional ERC20 token.
// receive() external payable: Allows receiving ETH deposits in Setup or Superposition.
// depositERC20(uint256 amount): Allows depositing the configured ERC20 token in Setup or Superposition.
// setERC20Token(address _erc20): Owner sets the allowed ERC20 token address (only in Setup).
// defineCondition(bytes32 conditionId, ConditionType conditionType, uint256 targetValue, address targetAddress): Owner defines a condition with a unique ID (only in Setup).
// definePotentialState(bytes32 stateId, string description): Owner defines a potential outcome state with a unique ID and description (only in Setup).
// setBeneficiaryAllocationInPotentialState(bytes32 stateId, address beneficiary, uint256 ethAmount, uint256 erc20Amount): Owner sets or updates an allocation for a beneficiary within a specific potential state (only in Setup).
// setConditionRequirementForState(bytes32 stateId, bytes32 conditionId, bool requiredOutcomeIsMet): Owner links a condition's required outcome (true/false) as a requirement for a potential state (only in Setup).
// setPotentialStatePriority(bytes32[] _priorityOrder): Owner sets the ordered list of potential states used during collapse evaluation (only in Setup).
// transitionToSuperposition(): Owner moves the vault state from Setup to Superposition.
// triggerCollapse(): Owner triggers the state collapse based on current conditions (only in Superposition). Finds the highest priority state whose conditions are met and transitions to Collapsed.
// claimAllocation(): A beneficiary claims their allocated ETH and ERC20 based on the resolvedStateId (only in Collapsed, only once).
// queryVaultState() public view returns (VaultState): Gets the current state of the vault.
// queryTotalBalanceETH() public view returns (uint256): Gets the total Ether balance held.
// queryTotalBalanceERC20() public view returns (uint256): Gets the total ERC20 balance held.
// queryConditionDetails(bytes32 conditionId) public view returns (Condition memory): Gets details of a defined condition.
// queryPotentialStateDetails(bytes32 stateId) public view returns (PotentialState memory): Gets details of a defined potential state (excluding allocations).
// queryBeneficiaryPotentialAllocation(bytes32 stateId, address beneficiary) public view returns (uint256 ethAmount, uint256 erc20Amount): Gets the allocation for a beneficiary within a specific potential state (before collapse).
// queryBeneficiaryFinalAllocation(address beneficiary) public view returns (uint256 ethAmount, uint256 erc20Amount): Gets the allocation for a beneficiary in the resolved state (after collapse).
// queryConditionStatus(bytes32 conditionId) public view returns (bool isMet): Checks if a specific condition is currently met (evaluates on the fly).
// queryHasClaimed(address beneficiary) public view returns (bool): Checks if a beneficiary has already claimed.
// queryResolvedStateId() public view returns (bytes32): Gets the ID of the state resolved during collapse.
// pauseVault(): Owner pauses specific operations.
// unpauseVault(): Owner unpauses the vault.
// queryIsPaused() public view returns (bool): Checks if the vault is paused.
// emergencyWithdrawETH(): Owner can withdraw all ETH (e.g., in Paused or Setup).
// emergencyWithdrawERC20(): Owner can withdraw all ERC20 (e.g., in Paused or Setup).
// simulateOracleData(uint256 _data): Owner sets a simulated oracle data value (for testing OracleData conditions).
// querySimulatedOracleData() public view returns (uint256): Gets the currently simulated oracle data.
// getPotentialStatePriority() public view returns (bytes32[] memory): Gets the defined priority order of potential states.

contract QuantumVault is Ownable, ReentrancyGuard {
    using Address for address payable;

    enum VaultState {
        Setup,         // Initial state: Owner configures conditions, states, allocations, priority.
        Superposition, // Deposits allowed, configuration locked. Waiting for collapse.
        Collapsed,     // State is resolved based on conditions. Beneficiaries can claim.
        Closed         // All funds potentially claimed or emergency withdrawn.
    }

    enum ConditionType {
        TimeAfter,             // Condition met if block.timestamp >= targetValue
        TimeBefore,            // Condition met if block.timestamp < targetValue
        OracleDataGreaterThan, // Condition met if simulatedOracleData > targetValue
        OracleDataLessThan     // Condition met if simulatedOracleData < targetValue
        // Add more condition types here as needed (e.g., InternalStateEquals, ExternalContractCall)
    }

    struct BeneficiaryAllocation {
        address beneficiaryAddress;
        uint256 ethAmount;
        uint256 erc20Amount;
    }

    struct Condition {
        ConditionType conditionType;
        uint256 targetValue; // Used for time or oracle data comparison
        address targetAddress; // Future use for external calls, or link to oracle contract
        string description;
    }

    struct PotentialState {
        bytes32 stateId;
        string description;
        // Mapping beneficiary address to their specific allocation in THIS potential state
        mapping(address => BeneficiaryAllocation) beneficiaryAllocations;
        address[] beneficiaries; // List of beneficiaries in this state for iteration
    }

    VaultState public currentVaultState;
    IERC20 public acceptedERC20Token;

    uint256 private totalETHBalance;
    uint256 private totalERC20Balance;

    // Configuration storage
    mapping(bytes32 => Condition) private definedConditions;
    mapping(bytes32 => PotentialState) private definedPotentialStates;
    mapping(bytes32 => mapping(bytes32 => bool)) private potentialStateConditionRequirements; // stateId => conditionId => requiredOutcomeIsMet

    bytes32[] private potentialStatePriority; // Ordered list of stateIds

    // Collapse outcome storage
    mapping(bytes32 => bool) private collapsedConditionOutcomes; // conditionId => actualOutcomeIsMet
    bytes32 private resolvedStateId;
    bool private isStateResolved = false;

    // Claiming storage
    mapping(address => bool) private hasClaimed;

    // Simulated external data (replace with actual oracle integration like Chainlink in production)
    uint256 public simulatedOracleData;

    // Pause functionality
    bool private _paused;

    // --- Events ---
    event Deposited(address indexed account, uint256 ethAmount, uint256 erc20Amount);
    event Withdrew(address indexed account, uint256 ethAmount, uint256 erc20Amount);
    event StateChanged(VaultState oldState, VaultState newState);
    event ConditionDefined(bytes32 indexed conditionId, ConditionType conditionType);
    event PotentialStateDefined(bytes32 indexed stateId);
    event BeneficiaryAllocationSet(bytes32 indexed stateId, address indexed beneficiary, uint256 ethAmount, uint256 erc20Amount);
    event ConditionRequirementSet(bytes32 indexed stateId, bytes32 indexed conditionId, bool requiredOutcomeIsMet);
    event PotentialStatePrioritySet(bytes32[] priorityOrder);
    event CollapseTriggered(bytes32 indexed resolvedStateId, uint256 timestamp);
    event AllocationClaimed(address indexed beneficiary, uint256 ethClaimed, uint256 erc20Claimed);
    event EmergencyWithdraw(address indexed owner, uint256 ethAmount, uint256 erc20Amount);
    event Paused(address account);
    event Unpaused(address account);
    event SimulatedOracleDataSet(uint256 data);

    // --- Modifiers ---
    modifier whenStateIs(VaultState expectedState) {
        require(currentVaultState == expectedState, "Vault: Invalid state for this operation");
        _;
    }

    modifier whenNotStateIs(VaultState expectedState) {
        require(currentVaultState != expectedState, "Vault: Invalid state for this operation");
        _;
    }

     modifier whenNotPaused() {
        require(!_paused, "Vault: Paused");
        _;
    }

     modifier whenPaused() {
        require(_paused, "Vault: Not paused");
        _;
    }

    modifier onlyBeneficiary(bytes32 stateId, address beneficiary) {
        require(definedPotentialStates[stateId].beneficiaryAllocations[beneficiary].beneficiaryAddress != address(0), "Vault: Not a beneficiary in this state");
        _;
    }

    // --- Constructor ---
    constructor(address _initialERC20Token) Ownable(msg.sender) {
        currentVaultState = VaultState.Setup;
        emit StateChanged(VaultState.Setup, VaultState.Setup); // Initial state event
        if (_initialERC20Token != address(0)) {
            acceptedERC20Token = IERC20(_initialERC20Token);
        }
         _paused = false;
    }

    // --- Core Vault Functionality ---

    /// @notice Allows users to deposit Ether into the vault.
    /// @dev Only allowed in Setup or Superposition states.
    receive() external payable whenStateIs(VaultState.Setup) whenStateIs(VaultState.Superposition) whenNotPaused nonReentrant {
        require(msg.value > 0, "Vault: ETH amount must be greater than zero");
        totalETHBalance += msg.value;
        emit Deposited(msg.sender, msg.value, 0);
    }

    /// @notice Allows users to deposit the configured ERC20 token into the vault.
    /// @param amount The amount of ERC20 tokens to deposit.
    /// @dev Only allowed in Setup or Superposition states. Requires prior approval of tokens to the contract.
    function depositERC20(uint256 amount) external whenStateIs(VaultState.Setup) whenStateIs(VaultState.Superposition) whenNotPaused nonReentrant {
        require(address(acceptedERC20Token) != address(0), "Vault: ERC20 token not set");
        require(amount > 0, "Vault: ERC20 amount must be greater than zero");

        uint256 balanceBefore = acceptedERC20Token.balanceOf(address(this));
        acceptedERC20Token.transferFrom(msg.sender, address(this), amount);
        uint256 balanceAfter = acceptedERC20Token.balanceOf(address(this));
        uint256 depositedAmount = balanceAfter - balanceBefore; // Account for potential transfer fees/mechanisms

        require(depositedAmount == amount, "Vault: Transfer amount mismatch"); // Or handle partial transfers if the token allows

        totalERC20Balance += depositedAmount;
        emit Deposited(msg.sender, 0, depositedAmount);
    }

    /// @notice Gets the current total Ether balance held in the vault.
    function queryTotalBalanceETH() public view returns (uint256) {
        return totalETHBalance;
    }

    /// @notice Gets the current total ERC20 balance held in the vault.
    function queryTotalBalanceERC20() public view returns (uint256) {
        return totalERC20Balance;
    }

    // --- Configuration (Owner only, State = Setup) ---

    /// @notice Sets the allowed ERC20 token for deposits and withdrawals.
    /// @param _erc20 The address of the ERC20 token contract.
    /// @dev Only callable by the owner in the Setup state. Cannot be changed after transition.
    function setERC20Token(address _erc20) external onlyOwner whenStateIs(VaultState.Setup) {
        require(_erc20 != address(0), "Vault: Invalid ERC20 address");
        acceptedERC20Token = IERC20(_erc20);
    }

    /// @notice Defines a condition that can be evaluated during collapse.
    /// @param conditionId A unique identifier for the condition.
    /// @param conditionType The type of condition (TimeAfter, OracleDataGreaterThan, etc.).
    /// @param targetValue A value used by the condition type (e.g., timestamp, oracle threshold).
    /// @param targetAddress An optional address used by some condition types (e.g., external contract).
    /// @param description A human-readable description of the condition.
    /// @dev Only callable by the owner in the Setup state. Overwrites if ID exists.
    function defineCondition(
        bytes32 conditionId,
        ConditionType conditionType,
        uint256 targetValue,
        address targetAddress,
        string calldata description
    ) external onlyOwner whenStateIs(VaultState.Setup) {
        require(conditionId != bytes32(0), "Vault: Invalid condition ID");
        definedConditions[conditionId] = Condition(
            conditionType,
            targetValue,
            targetAddress,
            description
        );
        emit ConditionDefined(conditionId, conditionType);
    }

    /// @notice Defines a potential outcome state for the vault.
    /// @param stateId A unique identifier for the potential state.
    /// @param description A human-readable description of this state (e.g., "Scenario A", "Time Lock Expired").
    /// @dev Only callable by the owner in the Setup state. Overwrites if ID exists.
    function definePotentialState(bytes32 stateId, string calldata description) external onlyOwner whenStateIs(VaultState.Setup) {
         require(stateId != bytes32(0), "Vault: Invalid state ID");
         // Initialize a new PotentialState struct in the mapping.
         // Allocations and beneficiaries array will be empty initially.
        definedPotentialStates[stateId].stateId = stateId;
        definedPotentialStates[stateId].description = description;
        // Note: beneficiaryAllocations and beneficiaries are managed by setBeneficiaryAllocationInPotentialState
        emit PotentialStateDefined(stateId);
    }

    /// @notice Sets or updates the allocation of funds for a specific beneficiary within a potential state.
    /// @param stateId The ID of the potential state.
    /// @param beneficiary The address of the beneficiary.
    /// @param ethAmount The amount of ETH allocated in this state.
    /// @param erc20Amount The amount of ERC20 allocated in this state.
    /// @dev Only callable by the owner in the Setup state. Requires the potential state to be defined. Allocations are *per state*.
    function setBeneficiaryAllocationInPotentialState(
        bytes32 stateId,
        address beneficiary,
        uint256 ethAmount,
        uint256 erc20Amount
    ) external onlyOwner whenStateIs(VaultState.Setup) {
        require(definedPotentialStates[stateId].stateId != bytes32(0), "Vault: Potential state not defined");
        require(beneficiary != address(0), "Vault: Invalid beneficiary address");

        // Check if beneficiary is new for this state, add to list if so
        if (definedPotentialStates[stateId].beneficiaryAllocations[beneficiary].beneficiaryAddress == address(0)) {
             definedPotentialStates[stateId].beneficiaries.push(beneficiary);
        }

        definedPotentialStates[stateId].beneficiaryAllocations[beneficiary] = BeneficiaryAllocation(
            beneficiary,
            ethAmount,
            erc20Amount
        );

        emit BeneficiaryAllocationSet(stateId, beneficiary, ethAmount, erc20Amount);
    }

    /// @notice Sets the required outcome of a condition for a potential state to be considered a match during collapse.
    /// @param stateId The ID of the potential state.
    /// @param conditionId The ID of the condition.
    /// @param requiredOutcomeIsMet The required boolean outcome for the condition (true if condition must be met, false if it must NOT be met).
    /// @dev Only callable by the owner in the Setup state. Requires the state and condition to be defined.
    function setConditionRequirementForState(
        bytes32 stateId,
        bytes32 conditionId,
        bool requiredOutcomeIsMet
    ) external onlyOwner whenStateIs(VaultState.Setup) {
        require(definedPotentialStates[stateId].stateId != bytes32(0), "Vault: Potential state not defined");
        require(definedConditions[conditionId].conditionType != ConditionType(0) || conditionId == bytes32(0), "Vault: Condition not defined"); // Allow bytes32(0) as a 'no condition' state
        potentialStateConditionRequirements[stateId][conditionId] = requiredOutcomeIsMet;
        emit ConditionRequirementSet(stateId, conditionId, requiredOutcomeIsMet);
    }

     /// @notice Sets the priority order for evaluating potential states during collapse.
    /// @param _priorityOrder An array of state IDs in descending order of priority.
    /// @dev Only callable by the owner in the Setup state. All stateIds must be previously defined.
    function setPotentialStatePriority(bytes32[] calldata _priorityOrder) external onlyOwner whenStateIs(VaultState.Setup) {
        for(uint i = 0; i < _priorityOrder.length; i++) {
            require(definedPotentialStates[_priorityOrder[i]].stateId != bytes32(0), "Vault: State ID in priority list not defined");
        }
        potentialStatePriority = _priorityOrder;
        emit PotentialStatePrioritySet(_priorityOrder);
    }


    // --- State Transition ---

    /// @notice Transitions the vault state from Setup to Superposition.
    /// @dev Only callable by the owner when in the Setup state. Locks configuration.
    function transitionToSuperposition() external onlyOwner whenStateIs(VaultState.Setup) {
        // Optional: Add requirements here, e.g., minimum number of states/conditions defined
        VaultState oldState = currentVaultState;
        currentVaultState = VaultState.Superposition;
        emit StateChanged(oldState, currentVaultState);
    }

    /// @notice Evaluates conditions and resolves the vault's state.
    /// @dev Only callable by the owner when in the Superposition state. Finds the highest priority state where all required conditions match the current reality.
    function triggerCollapse() external onlyOwner whenStateIs(VaultState.Superposition) whenNotPaused nonReentrant {
        require(!isStateResolved, "Vault: State already collapsed");
        require(potentialStatePriority.length > 0, "Vault: Potential state priority not set");

        bytes32 winningStateId = bytes32(0);

        // Evaluate all conditions once
        bytes32[] memory conditionIds = new bytes32[](getDefinedConditionIds().length); // Need to iterate defined conditions
        uint256 conditionIndex = 0;
        for (bytes32 condId : getDefinedConditionIds()) { // Helper function to get defined condition keys
            conditionIds[conditionIndex] = condId;
            Condition storage cond = definedConditions[condId];
            bool outcome = false;
            if (cond.conditionType == ConditionType.TimeAfter) {
                outcome = block.timestamp >= cond.targetValue;
            } else if (cond.conditionType == ConditionType.TimeBefore) {
                outcome = block.timestamp < cond.targetValue;
            } else if (cond.conditionType == ConditionType.OracleDataGreaterThan) {
                outcome = simulatedOracleData > cond.targetValue;
            } else if (cond.conditionType == ConditionType.OracleDataLessThan) {
                 outcome = simulatedOracleData < cond.targetValue;
            }
            // Add checks for other condition types here...

            collapsedConditionOutcomes[condId] = outcome;
            conditionIndex++;
        }

        // Find the first state in priority order whose conditions are met
        for (uint i = 0; i < potentialStatePriority.length; i++) {
            bytes32 stateId = potentialStatePriority[i];
            bool allConditionsMet = true;

            // Iterate through all defined conditions and check their requirements for THIS state
            for (bytes32 condId : getDefinedConditionIds()) { // Use helper function again
                 bool requiredOutcomeIsMet = potentialStateConditionRequirements[stateId][condId]; // Default is false if not set

                 // If a requirement exists for this condition...
                 if (potentialStateConditionRequirements[stateId][condId] != collapsedConditionOutcomes[condId] && // requirement doesn't match outcome
                     potentialStateConditionRequirements[stateId][condId] == true) // and the requirement *was* that it must match
                    {
                        allConditionsMet = false;
                        break; // This state is not a match
                    }
            }
            // What about conditions required to be FALSE?
             for (bytes32 condId : getDefinedConditionIds()) {
                 bool requiredOutcomeIsMet = potentialStateConditionRequirements[stateId][condId];
                  if (potentialStateConditionRequirements[stateId][condId] != collapsedConditionOutcomes[condId] && // requirement doesn't match outcome
                      potentialStateConditionRequirements[stateId][condId] == false) // and the requirement *was* that it must NOT match
                    {
                        allConditionsMet = false;
                        break; // This state is not a match
                    }
            }


            if (allConditionsMet) {
                winningStateId = stateId;
                break; // Found the highest priority matching state
            }
        }

        // If no state matched, maybe revert or resolve to a default 'failure' state?
        // For now, require a match.
        require(winningStateId != bytes32(0), "Vault: No potential state conditions were met");

        resolvedStateId = winningStateId;
        isStateResolved = true;
        VaultState oldState = currentVaultState;
        currentVaultState = VaultState.Collapsed;

        emit StateChanged(oldState, currentVaultState);
        emit CollapseTriggered(resolvedStateId, block.timestamp);
    }

    // --- Claiming (Beneficiaries, State = Collapsed) ---

    /// @notice Allows a beneficiary to claim their allocated funds in the resolved state.
    /// @dev Only callable by the beneficiary when in the Collapsed state, and only once per beneficiary.
    function claimAllocation() external whenStateIs(VaultState.Collapsed) whenNotPaused nonReentrant {
        require(!hasClaimed[msg.sender], "Vault: Allocation already claimed");
        require(isStateResolved, "Vault: State not resolved yet");

        bytes32 finalState = resolvedStateId;
        BeneficiaryAllocation storage allocation = definedPotentialStates[finalState].beneficiaryAllocations[msg.sender];

        require(allocation.beneficiaryAddress == msg.sender, "Vault: You are not a beneficiary in the resolved state");
        require(allocation.ethAmount > 0 || allocation.erc20Amount > 0, "Vault: No allocation for you in this state");

        uint256 ethToTransfer = allocation.ethAmount;
        uint256 erc20ToTransfer = allocation.erc20Amount;

        // Ensure contract has sufficient balance (should be true if allocations don't exceed deposits)
        require(totalETHBalance >= ethToTransfer, "Vault: Insufficient ETH balance in vault");
        require(address(acceptedERC20Token) == address(0) || totalERC20Balance >= erc20ToTransfer, "Vault: Insufficient ERC20 balance in vault");


        hasClaimed[msg.sender] = true; // Mark as claimed FIRST

        totalETHBalance -= ethToTransfer;
        totalERC20Balance -= erc20ToTransfer;

        // Transfer funds
        if (ethToTransfer > 0) {
             // Use sendValue for robustness against reentrancy
            (bool success, ) = payable(msg.sender).call{value: ethToTransfer}("");
            require(success, "Vault: ETH transfer failed");
        }

        if (erc20ToTransfer > 0) {
            require(address(acceptedERC20Token) != address(0), "Vault: ERC20 token not set");
            acceptedERC20Token.transfer(msg.sender, erc20ToTransfer);
        }

        emit AllocationClaimed(msg.sender, ethToTransfer, erc20ToTransfer);
    }

    // --- Query Functions (Anyone) ---

    /// @notice Gets details of a defined condition.
    /// @param conditionId The ID of the condition.
    /// @return A struct containing the condition's details.
    function queryConditionDetails(bytes32 conditionId) public view returns (Condition memory) {
        return definedConditions[conditionId];
    }

    /// @notice Gets details of a defined potential state (excluding beneficiary allocations).
    /// @param stateId The ID of the potential state.
    /// @return The state ID and description.
    function queryPotentialStateDetails(bytes32 stateId) public view returns (bytes32, string memory) {
         require(definedPotentialStates[stateId].stateId != bytes32(0), "Vault: Potential state not defined");
        return (definedPotentialStates[stateId].stateId, definedPotentialStates[stateId].description);
    }

    /// @notice Gets the *potential* allocation for a beneficiary in a *specific* potential state.
    /// @param stateId The ID of the potential state.
    /// @param beneficiary The address of the beneficiary.
    /// @return The ETH and ERC20 amounts allocated in that specific state. Returns 0s if not defined.
    /// @dev This shows what a beneficiary *might* get if this state is resolved.
    function queryBeneficiaryPotentialAllocation(bytes32 stateId, address beneficiary) public view returns (uint256 ethAmount, uint256 erc20Amount) {
        // No require(definedPotentialStates[stateId].stateId != bytes32(0)) needed, accessing a non-existent key returns default struct (0s, address(0)).
        // We check beneficiaryAddress within the struct to confirm it was set.
        BeneficiaryAllocation storage allocation = definedPotentialStates[stateId].beneficiaryAllocations[beneficiary];
        if(allocation.beneficiaryAddress == beneficiary) {
             return (allocation.ethAmount, allocation.erc20Amount);
        }
        return (0, 0);
    }

     /// @notice Gets the *final* allocation for a beneficiary in the *resolved* state after collapse.
    /// @param beneficiary The address of the beneficiary.
    /// @return The ETH and ERC20 amounts allocated in the resolved state. Returns 0s if not resolved or beneficiary not in resolved state.
    /// @dev Only meaningful when the vault is in the Collapsed state.
    function queryBeneficiaryFinalAllocation(address beneficiary) public view returns (uint256 ethAmount, uint256 erc20Amount) {
        if (currentVaultState == VaultState.Collapsed && isStateResolved) {
            bytes32 finalState = resolvedStateId;
            BeneficiaryAllocation storage allocation = definedPotentialStates[finalState].beneficiaryAllocations[beneficiary];
             if(allocation.beneficiaryAddress == beneficiary) {
                 return (allocation.ethAmount, allocation.erc20Amount);
            }
        }
        return (0, 0);
    }


    /// @notice Checks if a specific condition is currently met based on current reality (time, simulated oracle).
    /// @param conditionId The ID of the condition.
    /// @return True if the condition is currently met, false otherwise.
    function queryConditionStatus(bytes32 conditionId) public view returns (bool isMet) {
        Condition storage cond = definedConditions[conditionId];
        require(cond.conditionType != ConditionType(0) || conditionId == bytes32(0), "Vault: Condition not defined");

        if (conditionId == bytes32(0)) return true; // Special case for 'no condition'

        if (cond.conditionType == ConditionType.TimeAfter) {
            return block.timestamp >= cond.targetValue;
        } else if (cond.conditionType == ConditionType.TimeBefore) {
            return block.timestamp < cond.targetValue;
        } else if (cond.conditionType == ConditionType.OracleDataGreaterThan) {
            return simulatedOracleData > cond.targetValue;
        } else if (cond.conditionType == ConditionType.OracleDataLessThan) {
            return simulatedOracleData < cond.targetValue;
        }
        // Add evaluation logic for other condition types here...

        return false; // Should not reach here if all types handled
    }

    /// @notice Checks if a beneficiary has already claimed their allocation in the resolved state.
    /// @param beneficiary The address of the beneficiary.
    /// @return True if the beneficiary has claimed, false otherwise.
    function queryHasClaimed(address beneficiary) public view returns (bool) {
        return hasClaimed[beneficiary];
    }

    /// @notice Gets the ID of the state that was resolved during collapse.
    /// @return The resolved state ID, or bytes32(0) if not yet collapsed.
    function queryResolvedStateId() public view returns (bytes32) {
        return resolvedStateId;
    }

    // --- Admin & Safety ---

     /// @notice Pauses contract operations like deposits, collapse, and claims.
     /// @dev Only callable by the owner.
    function pauseVault() external onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /// @notice Unpauses contract operations.
    /// @dev Only callable by the owner.
    function unpauseVault() external onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

     /// @notice Checks if the vault is currently paused.
    function queryIsPaused() public view returns (bool) {
        return _paused;
    }

    /// @notice Allows the owner to withdraw all Ether from the vault in case of emergency.
    /// @dev Only callable by the owner. Intended for emergencies or when vault is in Setup/Paused state.
    function emergencyWithdrawETH() external onlyOwner nonReentrant {
        // Optional: Add state restrictions like whenStateIs(VaultState.Setup) or whenPaused()
        uint256 balance = totalETHBalance;
        totalETHBalance = 0;
        payable(owner()).sendValue(balance);
        emit EmergencyWithdraw(msg.sender, balance, 0);
    }

     /// @notice Allows the owner to withdraw all ERC20 from the vault in case of emergency.
    /// @dev Only callable by the owner. Intended for emergencies or when vault is in Setup/Paused state.
    function emergencyWithdrawERC20() external onlyOwner nonReentrant {
        // Optional: Add state restrictions like whenStateIs(VaultState.Setup) or whenPaused()
        require(address(acceptedERC20Token) != address(0), "Vault: ERC20 token not set");
        uint256 balance = totalERC20Balance;
        totalERC20Balance = 0;
        acceptedERC20Token.transfer(owner(), balance);
        emit EmergencyWithdraw(msg.sender, 0, balance);
    }

    /// @notice Allows the owner to simulate external oracle data for testing purposes.
    /// @param _data The uint256 value to set as simulated oracle data.
    /// @dev Should be replaced with actual oracle interaction in a production system.
    function simulateOracleData(uint256 _data) external onlyOwner {
        simulatedOracleData = _data;
        emit SimulatedOracleDataSet(_data);
    }

    /// @notice Gets the current simulated oracle data value.
    function querySimulatedOracleData() public view returns (uint256) {
        return simulatedOracleData;
    }

    /// @notice Gets the currently set priority order of potential states.
    function getPotentialStatePriority() public view returns (bytes32[] memory) {
        return potentialStatePriority;
    }

    // --- Internal/Helper Functions ---

    /// @dev Helper to get all defined condition IDs.
    /// Note: Iterating keys of a mapping is not directly supported. This requires keeping a list or iterating manually.
    /// A simple implementation might store IDs in an array during definition.
    /// For this example, we'll assume we can get defined condition IDs (this is a simplification for demo code).
    /// In a real contract, you'd manage a `bytes32[] public definedConditionIds;` and push/remove from it.
    function getDefinedConditionIds() internal view returns (bytes32[] memory) {
       // This is a simplified placeholder. In a real contract,
       // you would maintain an array of defined condition IDs.
       // Mapping iteration is not possible in Solidity views.
       // Example: If you had `bytes32[] public _definedConditionIds;`
       // return _definedConditionIds;
        // Returning a fixed-size or empty array as a placeholder
       return new bytes32[](0); // Placeholder: In a real contract, manage an array of keys
    }
     /// @dev Helper to get all defined potential state IDs.
    /// Similar simplification as getDefinedConditionIds.
     function getDefinedPotentialStateIds() internal view returns (bytes32[] memory) {
       // Placeholder: In a real contract, manage an array of keys
       return new bytes32[](0);
    }

    // --- Overrides ---
    // Override transferOwnership from Ownable to emit StateChanged if owner changes in Setup state
    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        if (currentVaultState == VaultState.Setup) {
             // If in setup, changing owner might be part of initial config
            VaultState oldState = currentVaultState;
            _transferOwnership(newOwner);
             emit StateChanged(oldState, currentVaultState); // Re-emit state change if needed for clarity
        } else {
             // Otherwise, normal transfer
            _transferOwnership(newOwner);
        }
    }

    // Override renounceOwnership from Ownable
    function renounceOwnership() public override onlyOwner {
         if (currentVaultState == VaultState.Setup) {
             // If in setup, renouncing ownership effectively closes configuration
            VaultState oldState = currentVaultState;
            _renounceOwnership();
             emit StateChanged(oldState, currentVaultState); // Re-emit state change if needed for clarity
        } else {
             // Otherwise, normal renounce
            _renounceOwnership();
        }
    }
}
```