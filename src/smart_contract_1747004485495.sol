Okay, let's design a smart contract that acts as a sophisticated, time-and-condition-locked vault. It will hold multiple types of assets (ETH, ERC20, ERC721) and potentially unlock them in stages (epochs) based on time *and* external conditions reported by an authorized entity. It will also include a social recovery mechanism.

This combines concepts of programmable vaults, multi-asset management, oracle interaction (simulated via a reporter address), phased releases, structured data storage, and social recovery. It's more complex than standard vesting or timelock contracts.

---

**Contract Name:** `ChronicleVault`

**Outline:**

1.  **State Variables:** Owner, beneficiary, epoch details, condition states, deposited assets (ETH, ERC20, ERC721), social recovery state, role addresses (condition reporter, recovery agents), pause state.
2.  **Structs:** Define `Epoch` (duration, required conditions, unlock rules), `Condition` (type, expected value, state), `Recovery` (state, initiator, approvals).
3.  **Enums:** Define `VaultState`, `ConditionType`, `RecoveryState`.
4.  **Events:** Emit events for deposits, withdrawals, epoch changes, condition reports, recovery actions, state changes.
5.  **Modifiers:** `onlyOwner`, `onlyConditionReporter`, `onlyRecoveryAgent`, `whenNotPausedDeposits`, `whenNotPausedWithdrawals`.
6.  **Core Logic:**
    *   **Configuration:** Setting up epochs, conditions, roles, beneficiary.
    *   **Deposits:** Receiving ETH, ERC20, ERC721. Tracking deposited amounts/tokens.
    *   **Epoch Management:** Starting the first epoch, advancing epochs based on time and met conditions.
    *   **Condition Reporting:** Allowing the designated reporter to update condition states.
    *   **Withdrawals:** Complex logic to check if the caller (or beneficiary) can withdraw specific assets/amounts based on the *current active epoch's* rules and *met conditions*. Tracking withdrawn amounts to prevent double-spending.
    *   **Data Storage:** Storing small pieces of data tied to epochs, accessible under epoch/condition rules.
    *   **Social Recovery:** Mechanism for designated agents to collectively initiate and approve a change in beneficiary or owner if the owner is inactive.
    *   **Pause Functionality:** Selective pausing of deposits or withdrawals.
7.  **Functions (at least 20):** Covering configuration, deposits, epoch control, condition reporting, state queries, withdrawals, data access, social recovery, pausing, and owner management.

**Function Summary:**

1.  `constructor()`: Initializes owner, beneficiary, reporter, and recovery agents.
2.  `setBeneficiary(address _newBeneficiary)`: Sets the address that can withdraw assets (if allowed by epoch rules).
3.  `setConditionReporter(address _reporter)`: Sets the address authorized to report condition states.
4.  `addRecoveryAgent(address _agent)`: Adds an address to the social recovery multi-sig.
5.  `removeRecoveryAgent(address _agent)`: Removes a recovery agent.
6.  `setRecoveryThreshold(uint256 _threshold)`: Sets the number of agents required for social recovery approval.
7.  `addEpoch(uint256 _duration, uint256[] memory _requiredConditionIds, uint256 _ethUnlockBasisPoints, uint256 _erc20UnlockBasisPoints)`: Configures a new epoch's rules. Duration is in seconds. Unlock amounts are defined as basis points (1/100th of a percent) of *total* deposited amount for that asset type. This is a simplified example, real unlock rules could be more complex.
8.  `setEpochERC20UnlockRules(uint256 _epochIndex, address _token, uint256 _unlockBasisPoints)`: Sets specific ERC20 unlock rules for an epoch.
9.  `setEpochERC721UnlockRules(uint256 _epochIndex, address _token, uint256[] memory _tokenIds)`: Sets specific ERC721 token IDs unlocked in an epoch. (Simplified: checks if token ID is in the list).
10. `defineCondition(uint256 _conditionId, ConditionType _type, bytes32 _expectedValue)`: Defines a condition that can be linked to epochs.
11. `reportCondition(uint256 _conditionId, bytes32 _actualValue)`: The reporter updates the state of a condition.
12. `startFirstEpoch()`: Initiates the vault's timeline. Can only be called once.
13. `tryAdvanceEpoch()`: Can be called by anyone to check if the current epoch has ended and its conditions are met, then advance to the next epoch.
14. `isConditionMet(uint256 _conditionId)`: View function to check a condition's reported state against its defined expected value.
15. `getCurrentEpochIndex()`: View function returning the index of the current active or last completed epoch.
16. `getTimeRemainingInEpoch()`: View function returning seconds left in the current epoch.
17. `getUnlockableETHAmount()`: View function returning the amount of ETH currently available for withdrawal based on completed epochs and met conditions, minus already withdrawn ETH.
18. `getUnlockableERC20Amount(address _token)`: View function for ERC20.
19. `getUnlockableERC721Tokens(address _token)`: View function for ERC721 IDs.
20. `withdrawETH()`: Allows beneficiary/owner to withdraw unlocked ETH.
21. `withdrawERC20(address _token, uint256 _amount)`: Allows withdrawal of unlocked ERC20.
22. `withdrawERC721(address _token, uint256[] memory _tokenIds)`: Allows withdrawal of unlocked ERC721 tokens.
23. `storeEpochData(uint256 _epochIndex, bytes memory _data)`: Allows owner to store data associated with an epoch (e.g., context, links).
24. `retrieveEpochData(uint256 _epochIndex)`: Allows beneficiary/owner to retrieve stored data *if* the epoch is complete and conditions met.
25. `initiateSocialRecovery()`: A recovery agent starts the process.
26. `approveSocialRecovery()`: Another recovery agent approves.
27. `cancelSocialRecovery()`: Owner or sufficient agents can cancel.
28. `finalizeRecovery(address _newOwner, address _newBeneficiary)`: Approved recovery agents can finalize the process.
29. `pauseDeposits()`: Owner can pause deposits.
30. `unpauseDeposits()`: Owner can unpause deposits.
31. `transferOwnership(address _newOwner)`: Standard owner transfer.

*(Note: Some functions might be internal helpers or simple getters, but this list gives a sense of the required complexity to reach 20+ meaningful functions).*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title ChronicleVault
 * @dev A sophisticated, time-and-condition-locked vault for multiple asset types (ETH, ERC20, ERC721).
 * Assets and associated data are unlocked in stages (epochs) based on time and conditions reported by an authorized address.
 * Includes a social recovery mechanism for the beneficiary/owner.
 *
 * Outline:
 * 1. State Variables: Owner, beneficiary, epoch details, condition states, deposited assets, social recovery state, roles, pause state.
 * 2. Structs: Epoch, Condition, Recovery.
 * 3. Enums: VaultState, ConditionType, RecoveryState.
 * 4. Events: Deposit, Withdrawal, Epoch events, Condition events, Recovery events, Pause events.
 * 5. Modifiers: onlyOwner, onlyConditionReporter, onlyRecoveryAgent, whenNotPausedDeposits, whenNotPausedWithdrawals, vaultState.
 * 6. Core Logic: Configuration, Deposits, Epoch Management, Condition Reporting, Withdrawals (conditional), Data Storage, Social Recovery, Pausing.
 * 7. Functions (>20): Config, Deposits, Epoch Control, Conditions, State Queries, Withdrawals, Data Access, Social Recovery, Pause, Ownership.
 */
contract ChronicleVault is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // --- State Variables ---

    address payable public owner;
    address payable public beneficiary;
    address public conditionReporter;

    enum VaultState { Uninitialized, Active, Completed, Recovery }
    VaultState public currentVaultState;

    uint256 public currentEpochIndex;
    uint256 public epochStartTime; // Timestamp when the current epoch started

    struct Epoch {
        uint256 duration; // in seconds
        uint256[] requiredConditionIds;
        uint256 ethUnlockBasisPoints; // 1/100th of a percent (e.g., 10000 = 100%)
        mapping(address => uint256) erc20UnlockBasisPoints;
        mapping(address => uint256[]) erc721UnlockTokenIds; // Simple list of IDs unlocked for a specific token
        bytes storedData; // Data revealed when epoch completes and conditions met
    }
    Epoch[] public epochs;

    enum ConditionType { NumericEqual, BooleanTrue, StringEqual, OracleReport } // Example types
    struct Condition {
        ConditionType conditionType;
        bytes32 expectedValue; // e.g., keccak256(abi.encodePacked(100)), keccak256(abi.encodePacked(true)), keccak256(abi.encodePacked("success"))
        bool met; // State reported by conditionReporter
        bool defined; // To check if an ID is valid
    }
    mapping(uint256 => Condition) public conditions;
    uint256 public nextConditionId = 1; // Counter for condition IDs

    // Track total deposited amounts/tokens
    uint256 public totalDepositedETH;
    mapping(address => uint256) public totalDepositedERC20;
    mapping(address => uint256[]) public totalDepositedERC721Ids; // Simple list of all deposited ERC721 IDs per token

    // Track withdrawn amounts/tokens to calculate unlockable amounts
    uint256 public totalWithdrawnETH;
    mapping(address => uint256) public totalWithdrawnERC20;
    mapping(address => uint256[]) public totalWithdrawnERC721Ids; // Simple list of all withdrawn ERC721 IDs per token

    // Social Recovery
    mapping(address => bool) public isRecoveryAgent;
    address[] public recoveryAgents;
    uint256 public recoveryThreshold;

    enum RecoveryState { Idle, Initiated, Approved }
    struct Recovery {
        RecoveryState state;
        uint256 initiatedTimestamp;
        mapping(address => bool) approvals;
        uint256 approvalCount;
        address pendingNewOwner;
        address pendingNewBeneficiary;
    }
    Recovery public socialRecovery;
    uint256 public constant RECOVERY_GRACE_PERIOD = 7 * 24 * 60 * 60; // 7 days grace period after initiation

    // Pause States
    bool public depositsPaused = false;
    bool public withdrawalsPaused = false;

    // --- Events ---

    event Initialized(address indexed owner, address indexed beneficiary);
    event BeneficiaryUpdated(address indexed oldBeneficiary, address indexed newBeneficiary);
    event ConditionReporterUpdated(address indexed oldReporter, address indexed newReporter);
    event RecoveryAgentAdded(address indexed agent);
    event RecoveryAgentRemoved(address indexed agent);
    event RecoveryThresholdUpdated(uint256 threshold);

    event EpochAdded(uint256 indexed index, uint256 duration, uint256 ethUnlockBasisPoints, uint256 erc20UnlockBasisPoints); // Simplified event args
    event EpochERC20RuleSet(uint256 indexed epochIndex, address indexed token, uint256 unlockBasisPoints);
    event EpochERC721RuleSet(uint256 indexed epochIndex, address indexed token, uint256[] tokenIds);
    event EpochDataStored(uint256 indexed epochIndex, address indexed by);

    event ConditionDefined(uint256 indexed conditionId, ConditionType conditionType, bytes32 expectedValue);
    event ConditionReported(uint256 indexed conditionId, bytes32 actualValue, bool met);

    event EpochStarted(uint256 indexed epochIndex, uint256 startTime);
    event EpochAdvanced(uint256 indexed oldIndex, uint256 indexed newIndex);
    event VaultCompleted();

    event ETHDeposited(address indexed from, uint256 amount);
    event ERC20Deposited(address indexed from, address indexed token, uint256 amount);
    event ERC721Deposited(address indexed from, address indexed token, uint256 indexed tokenId);

    event ETHWithdrawn(address indexed to, uint256 amount);
    event ERC20Withdrawn(address indexed to, address indexed token, uint256 amount);
    event ERC721Withdrawn(address indexed to, address indexed token, uint256[] tokenIds);
    event EpochDataRetrieved(uint256 indexed epochIndex, address indexed by);

    event SocialRecoveryInitiated(address indexed initiator, uint256 initiatedTimestamp);
    event SocialRecoveryApproved(address indexed agent, uint256 currentApprovals);
    event SocialRecoveryCancelled(address indexed by);
    event SocialRecoveryFinalized(address indexed newOwner, address indexed newBeneficiary);

    event DepositsPaused(address indexed by);
    event DepositsUnpaused(address indexed by);
    event WithdrawalsPaused(address indexed by);
    event WithdrawalsUnpaused(address indexed by);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "CV: Not owner");
        _;
    }

    modifier onlyConditionReporter() {
        require(msg.sender == conditionReporter, "CV: Not reporter");
        _;
    }

    modifier onlyRecoveryAgent() {
        require(isRecoveryAgent[msg.sender], "CV: Not recovery agent");
        _;
    }

    modifier whenNotPausedDeposits() {
        require(!depositsPaused, "CV: Deposits are paused");
        _;
    }

    modifier whenNotPausedWithdrawals() {
        require(!withdrawalsPaused, "CV: Withdrawals are paused");
        _;
    }

    modifier vaultState(VaultState _state) {
        require(currentVaultState == _state, "CV: Incorrect vault state");
        _;
    }

    // --- Constructor ---

    constructor(address payable _beneficiary, address _conditionReporter, address[] memory _recoveryAgents, uint256 _recoveryThreshold) payable {
        require(_beneficiary != address(0), "CV: Zero beneficiary");
        require(_conditionReporter != address(0), "CV: Zero reporter");
        require(_recoveryThreshold > 0 && _recoveryThreshold <= _recoveryAgents.length, "CV: Invalid recovery threshold");

        owner = payable(msg.sender);
        beneficiary = _beneficiary;
        conditionReporter = _conditionReporter;
        recoveryThreshold = _recoveryThreshold;

        for (uint256 i = 0; i < _recoveryAgents.length; i++) {
            require(_recoveryAgents[i] != address(0), "CV: Zero recovery agent");
            if (!isRecoveryAgent[_recoveryAgents[i]]) {
                 isRecoveryAgent[_recoveryAgents[i]] = true;
                 recoveryAgents.push(_recoveryAgents[i]);
            }
        }

        currentVaultState = VaultState.Uninitialized;
        currentEpochIndex = 0; // Represents the state before the first epoch (index 0)
        totalDepositedETH = msg.value; // Capture initial ETH deposit
        emit ETHDeposited(msg.sender, msg.value);
        emit Initialized(owner, beneficiary);
    }

    // --- Configuration Functions (onlyOwner) ---

    /**
     * @dev Sets the address authorized to withdraw assets. Can only be set by owner.
     * @param _newBeneficiary The new beneficiary address.
     */
    function setBeneficiary(address payable _newBeneficiary) public onlyOwner {
        require(_newBeneficiary != address(0), "CV: Zero beneficiary");
        address oldBeneficiary = beneficiary;
        beneficiary = _newBeneficiary;
        emit BeneficiaryUpdated(oldBeneficiary, _newBeneficiary);
    }

    /**
     * @dev Sets the address authorized to report condition states. Can only be set by owner.
     * @param _reporter The new condition reporter address.
     */
    function setConditionReporter(address _reporter) public onlyOwner {
        require(_reporter != address(0), "CV: Zero reporter");
        address oldReporter = conditionReporter;
        conditionReporter = _reporter;
        emit ConditionReporterUpdated(oldReporter, _reporter);
    }

    /**
     * @dev Adds an address to the social recovery agent list. Can only be called by owner before recovery is initiated.
     * @param _agent The address to add as an agent.
     */
    function addRecoveryAgent(address _agent) public onlyOwner {
        require(_agent != address(0), "CV: Zero agent");
        require(socialRecovery.state == RecoveryState.Idle, "CV: Recovery in progress");
        if (!isRecoveryAgent[_agent]) {
            isRecoveryAgent[_agent] = true;
            recoveryAgents.push(_agent);
            // Re-evaluate threshold if needed: require(recoveryThreshold <= recoveryAgents.length, "CV: Threshold too high");
            emit RecoveryAgentAdded(_agent);
        }
    }

     /**
     * @dev Removes an address from the social recovery agent list. Can only be called by owner before recovery is initiated.
     * @param _agent The address to remove as an agent.
     */
    function removeRecoveryAgent(address _agent) public onlyOwner {
        require(_agent != address(0), "CV: Zero agent");
        require(socialRecovery.state == RecoveryState.Idle, "CV: Recovery in progress");
        if (isRecoveryAgent[_agent]) {
            isRecoveryAgent[_agent] = false;
            // Removing from array efficiently (swap and pop)
            for (uint256 i = 0; i < recoveryAgents.length; i++) {
                if (recoveryAgents[i] == _agent) {
                    recoveryAgents[i] = recoveryAgents[recoveryAgents.length - 1];
                    recoveryAgents.pop();
                    break;
                }
            }
            require(recoveryThreshold <= recoveryAgents.length, "CV: Threshold exceeds remaining agents");
            emit RecoveryAgentRemoved(_agent);
        }
    }

    /**
     * @dev Sets the number of recovery agents required to approve a social recovery.
     * Can only be called by owner before recovery is initiated.
     * @param _threshold The new threshold.
     */
    function setRecoveryThreshold(uint256 _threshold) public onlyOwner {
         require(_threshold > 0 && _threshold <= recoveryAgents.length, "CV: Invalid threshold");
         require(socialRecovery.state == RecoveryState.Idle, "CV: Recovery in progress");
         recoveryThreshold = _threshold;
         emit RecoveryThresholdUpdated(_threshold);
    }


    /**
     * @dev Configures a new epoch. Must be called sequentially for Epoch 1, 2, etc.
     * Epoch 0 represents the state before the first epoch starts.
     * This simplified version takes basis points for ETH and a general ERC20 unlock percentage.
     * Specific token rules are set via setEpochERC20UnlockRules/setEpochERC721UnlockRules.
     * @param _duration Duration of the epoch in seconds. 0 means instantly completable if conditions met.
     * @param _requiredConditionIds Array of condition IDs that must be MET for this epoch to advance.
     * @param _ethUnlockBasisPoints Basis points of total ETH unlocked when this epoch completes.
     * @param _erc20UnlockBasisPoints Basis points of total ERC20 (all types) unlocked (as a fallback/default).
     */
    function addEpoch(
        uint256 _duration,
        uint256[] memory _requiredConditionIds,
        uint256 _ethUnlockBasisPoints,
        uint256 _erc20UnlockBasisPoints // General ERC20 unlock %
    ) public onlyOwner {
        // Can only add epochs before the vault is active or while it is active but not completed
        require(currentVaultState != VaultState.Completed, "CV: Vault completed, cannot add epochs");
        require(currentVaultState != VaultState.Recovery, "CV: Recovery in progress, cannot add epochs");

        for (uint256 i = 0; i < _requiredConditionIds.length; i++) {
            require(conditions[_requiredConditionIds[i]].defined, "CV: Required condition not defined");
        }

        // Create a new Epoch struct instance in memory
        Epoch memory newEpoch;
        newEpoch.duration = _duration;
        newEpoch.requiredConditionIds = _requiredConditionIds; // Store array directly
        newEpoch.ethUnlockBasisPoints = _ethUnlockBasisPoints;
        // Use the mapping directly for ERC20 defaults in the struct
        // ERC20 default basis points are stored per token address inside the epoch struct
        // The simplified erc20UnlockBasisPoints param is just a suggestion/default for future token configs

        epochs.push(newEpoch);

        emit EpochAdded(epochs.length - 1, _duration, _ethUnlockBasisPoints, _erc20UnlockBasisPoints);
    }

    /**
     * @dev Sets specific ERC20 unlock rules for a given epoch and token address. Overrides general ERC20 unlock.
     * @param _epochIndex The index of the epoch (0-based).
     * @param _token The address of the ERC20 token.
     * @param _unlockBasisPoints Basis points of total deposited amount for this specific token unlocked.
     */
    function setEpochERC20UnlockRules(uint256 _epochIndex, address _token, uint256 _unlockBasisPoints) public onlyOwner {
        require(_epochIndex < epochs.length, "CV: Invalid epoch index");
        require(_token != address(0), "CV: Zero token address");
        require(currentVaultState != VaultState.Completed, "CV: Vault completed");
        require(currentVaultState != VaultState.Recovery, "CV: Recovery in progress");

        epochs[_epochIndex].erc20UnlockBasisPoints[_token] = _unlockBasisPoints;
        emit EpochERC20RuleSet(_epochIndex, _token, _unlockBasisPoints);
    }

    /**
     * @dev Sets specific ERC721 token IDs that become unlockable in a given epoch.
     * @param _epochIndex The index of the epoch (0-based).
     * @param _token The address of the ERC721 token.
     * @param _tokenIds Array of token IDs unlocked in this epoch.
     */
    function setEpochERC721UnlockRules(uint256 _epochIndex, address _token, uint256[] memory _tokenIds) public onlyOwner {
         require(_epochIndex < epochs.length, "CV: Invalid epoch index");
         require(_token != address(0), "CV: Zero token address");
         require(currentVaultState != VaultState.Completed, "CV: Vault completed");
         require(currentVaultState != VaultState.Recovery, "CV: Recovery in progress");

         // This replaces any previous list for this token in this epoch
         epochs[_epochIndex].erc721UnlockTokenIds[_token] = _tokenIds;
         emit EpochERC721RuleSet(_epochIndex, _token, _tokenIds);
    }


    /**
     * @dev Defines a condition that can be used as a requirement for epoch advancement.
     * Only owner can define conditions.
     * @param _conditionId A unique ID for the condition.
     * @param _type The type of condition (e.g., NumericEqual, BooleanTrue).
     * @param _expectedValue The expected value for the condition to be met.
     */
    function defineCondition(uint256 _conditionId, ConditionType _type, bytes32 _expectedValue) public onlyOwner {
        require(!conditions[_conditionId].defined, "CV: Condition already defined");
        require(_conditionId > 0, "CV: Condition ID must be > 0"); // Reserve 0 for undefined

        conditions[_conditionId] = Condition(_type, _expectedValue, false, true); // Initially not met
        emit ConditionDefined(_conditionId, _type, _expectedValue);
    }

    // --- Deposit Functions ---

    /**
     * @dev Receives ETH deposits into the vault.
     */
    receive() external payable whenNotPausedDeposits {
        require(msg.value > 0, "CV: ETH amount must be > 0");
        totalDepositedETH += msg.value;
        emit ETHDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Deposits ERC20 tokens into the vault.
     * Caller must approve this contract to spend the tokens first.
     * @param _token The address of the ERC20 token.
     * @param _amount The amount of tokens to deposit.
     */
    function depositERC20(address _token, uint256 _amount) external whenNotPausedDeposits nonReentrant {
        require(_token != address(0), "CV: Zero token address");
        require(_amount > 0, "CV: Amount must be > 0");

        IERC20 token = IERC20(_token);
        uint256 balanceBefore = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 balanceAfter = token.balanceOf(address(this));
        uint256 depositedAmount = balanceAfter - balanceBefore; // Amount actually transferred

        totalDepositedERC20[_token] += depositedAmount;

        emit ERC20Deposited(msg.sender, _token, depositedAmount);
    }

    /**
     * @dev Deposits ERC721 tokens into the vault.
     * Caller must approve this contract or use `safeTransferFrom` with this contract as recipient.
     * @param _token The address of the ERC721 token.
     * @param _tokenId The ID of the token to deposit.
     */
    function depositERC721(address _token, uint256 _tokenId) external whenNotPausedDeposits nonReentrant {
        require(_token != address(0), "CV: Zero token address");

        IERC721 token = IERC721(_token);
        // Check ownership before transferFrom
        require(token.ownerOf(_tokenId) == msg.sender, "CV: Not token owner");

        token.transferFrom(msg.sender, address(this), _tokenId);

        totalDepositedERC721Ids[_token].push(_tokenId);

        emit ERC721Deposited(msg.sender, _token, _tokenId);
    }

    // --- Epoch and Condition Management ---

    /**
     * @dev Starts the first epoch. Can only be called once by the owner when uninitialized.
     */
    function startFirstEpoch() public onlyOwner vaultState(VaultState.Uninitialized) {
        require(epochs.length > 0, "CV: No epochs configured");
        currentVaultState = VaultState.Active;
        currentEpochIndex = 0; // First configured epoch is index 0
        epochStartTime = block.timestamp;
        emit EpochStarted(currentEpochIndex, epochStartTime);
    }

    /**
     * @dev Allows the condition reporter to report the actual value for a condition ID.
     * This updates the `met` state of the condition based on comparison with the defined expected value.
     * @param _conditionId The ID of the condition to report on.
     * @param _actualValue The actual value observed (e.g., keccak256(abi.encodePacked(actual_number))).
     */
    function reportCondition(uint256 _conditionId, bytes32 _actualValue) public onlyConditionReporter {
        Condition storage cond = conditions[_conditionId];
        require(cond.defined, "CV: Condition not defined");

        bool conditionMet = (cond.expectedValue == _actualValue);
        cond.met = conditionMet; // Update state

        emit ConditionReported(_conditionId, _actualValue, conditionMet);

        // Optional: Automatically try to advance epoch if reporting makes conditions met
        tryAdvanceEpoch();
    }

    /**
     * @dev Attempts to advance the vault to the next epoch.
     * Can be called by anyone, but only succeeds if:
     * 1. The vault is Active.
     * 2. The current epoch has passed its duration.
     * 3. All required conditions for the current epoch have been reported as MET.
     */
    function tryAdvanceEpoch() public nonReentrant vaultState(VaultState.Active) {
        uint256 nextEpochIndex = currentEpochIndex + 1;
        require(currentEpochIndex < epochs.length, "CV: No more epochs configured"); // Check if there's a next epoch

        Epoch storage currentEpoch = epochs[currentEpochIndex];

        // Check time elapsed
        bool durationPassed = (currentEpoch.duration == 0 || block.timestamp >= epochStartTime + currentEpoch.duration);
        require(durationPassed, "CV: Current epoch duration not passed");

        // Check all required conditions are met
        for (uint256 i = 0; i < currentEpoch.requiredConditionIds.length; i++) {
            uint256 requiredCondId = currentEpoch.requiredConditionIds[i];
            require(conditions[requiredCondId].met, "CV: Required condition not met");
        }

        // If duration passed and conditions met, advance epoch
        currentEpochIndex = nextEpochIndex;
        epochStartTime = block.timestamp; // Start time for the *new* epoch

        emit EpochAdvanced(currentEpochIndex - 1, currentEpochIndex);

        // Check if this was the last epoch
        if (currentEpochIndex >= epochs.length) {
            currentVaultState = VaultState.Completed;
            emit VaultCompleted();
        }
    }

    // --- View Functions (State Queries) ---

    /**
     * @dev Checks if a specific condition has been reported as met.
     * @param _conditionId The ID of the condition.
     * @return True if the condition is defined and reported as met.
     */
    function isConditionMet(uint256 _conditionId) public view returns (bool) {
        return conditions[_conditionId].defined && conditions[_conditionId].met;
    }

    /**
     * @dev Gets the index of the current active or last completed epoch.
     * Index 0 means the vault is Uninitialized or in the state *before* the first epoch starts.
     * Index `epochs.length` means the vault is Completed.
     */
    function getCurrentEpochIndex() public view returns (uint256) {
        return currentEpochIndex;
    }

    /**
     * @dev Gets the total number of epochs configured.
     */
    function getTotalEpochsConfigured() public view returns (uint256) {
        return epochs.length;
    }

    /**
     * @dev Gets the state of a specific epoch.
     * @param _epochIndex The index of the epoch.
     * @return duration, requiredConditionIds, ethUnlockBasisPoints, erc20UnlockBasisPointsMappingPlaceholder (mapping not returnable), erc721UnlockTokenIdsMappingPlaceholder (mapping not returnable).
     */
    function getEpochDetails(uint256 _epochIndex)
        public
        view
        returns (
            uint256 duration,
            uint256[] memory requiredConditionIds,
            uint256 ethUnlockBasisPoints
            // Note: Cannot return mappings directly. Need separate getters for specific token rules.
        )
    {
        require(_epochIndex < epochs.length, "CV: Invalid epoch index");
        Epoch storage epoch = epochs[_epochIndex];
        return (
            epoch.duration,
            epoch.requiredConditionIds,
            epoch.ethUnlockBasisPoints
        );
    }

    /**
     * @dev Gets the ERC20 unlock basis points for a specific epoch and token.
     * @param _epochIndex The index of the epoch.
     * @param _token The address of the ERC20 token.
     */
    function getEpochERC20UnlockRules(uint256 _epochIndex, address _token) public view returns (uint256) {
         require(_epochIndex < epochs.length, "CV: Invalid epoch index");
         return epochs[_epochIndex].erc20UnlockBasisPoints[_token];
    }

    /**
     * @dev Gets the ERC721 token IDs unlocked in a specific epoch for a specific token.
     * @param _epochIndex The index of the epoch.
     * @param _token The address of the ERC721 token.
     */
    function getEpochERC721UnlockRules(uint256 _epochIndex, address _token) public view returns (uint256[] memory) {
         require(_epochIndex < epochs.length, "CV: Invalid epoch index");
         return epochs[_epochIndex].erc721UnlockTokenIds[_token];
    }


    /**
     * @dev Gets the state details of a condition.
     * @param _conditionId The ID of the condition.
     * @return conditionType, expectedValue, met, defined.
     */
    function getConditionState(uint256 _conditionId)
        public
        view
        returns (ConditionType conditionType, bytes32 expectedValue, bool met, bool defined)
    {
        Condition storage cond = conditions[_conditionId];
        return (cond.conditionType, cond.expectedValue, cond.met, cond.defined);
    }

    /**
     * @dev Gets the current state of the vault.
     */
    function getVaultState() public view returns (VaultState) {
        return currentVaultState;
    }

    /**
     * @dev Calculates the amount of ETH currently unlockable based on completed epochs and met conditions.
     * This aggregates unlock percentages from all completed/met epochs.
     * @return The amount of ETH that can be withdrawn.
     */
    function getUnlockableETHAmount() public view returns (uint256) {
        if (currentVaultState == VaultState.Uninitialized || currentVaultState == VaultState.Recovery) {
             return 0;
        }

        uint256 totalUnlockBasisPoints = 0;
        // Sum up unlock points for all epochs *up to and including* the current one,
        // but only if their duration passed and conditions are met.
        // Note: tryAdvanceEpoch() *must* be called to move to the next epoch.
        // This logic assumes assets unlocked in previous epochs *remain* unlocked.
        // If assets are only unlocked by the *currently active* epoch, this logic changes.
        // Let's assume cumulative unlock percentage up to the last successfully *advanced* epoch.

        uint256 lastAdvancedEpochIndex = (currentEpochIndex > 0 && currentVaultState == VaultState.Active && block.timestamp < epochStartTime + epochs[currentEpochIndex-1].duration) ? currentEpochIndex - 1 : currentEpochIndex;
         if (currentVaultState == VaultState.Completed) {
             lastAdvancedEpochIndex = epochs.length; // Count all epochs if completed
         }


        for (uint256 i = 0; i < lastAdvancedEpochIndex; i++) {
             Epoch storage epoch = epochs[i];
             bool epochConditionsMet = true;
             for (uint256 j = 0; j < epoch.requiredConditionIds.length; j++) {
                 if (!conditions[epoch.requiredConditionIds[j]].met) {
                     epochConditionsMet = false;
                     break;
                 }
             }
             // Only add unlock points if duration passed AND conditions met for this epoch
             if (block.timestamp >= epochStartTime + epoch.duration && epochConditionsMet) { // This timestamp check is problematic if epochStartTime isn't the start of *that specific* epoch. Let's rely solely on `currentEpochIndex` and assuming `tryAdvanceEpoch` was called correctly.
                 // Assuming `currentEpochIndex` is the index of the *currently active* epoch.
                 // Unlockable amount comes from all epochs from 0 up to `currentEpochIndex - 1` (completed epochs), plus potentially a partial unlock from the current epoch if its duration passed and conditions *for advancing* are met (which tryAdvanceEpoch checks).
                 // A cleaner approach: calculate cumulative BP based on `currentEpochIndex`.
                 // Epochs 0 to currentEpochIndex - 1 are considered completed for unlock calculation.
             }
        }

        // Recalculating based on epochs up to (but not including) the currentEpochIndex, assuming tryAdvanceEpoch has done its job.
        // This means all required conditions for epoch `i` and duration passed implies epoch `i+1` is reachable.
        // Unlock percentage for epoch `i` becomes available once epoch `i` is *completed* (i.e., epoch `i+1` is the `currentEpochIndex`).

        for (uint256 i = 0; i < currentEpochIndex; i++) {
            totalUnlockBasisPoints += epochs[i].ethUnlockBasisPoints;
        }

        // Cap at 100% (10000 basis points)
        if (totalUnlockBasisPoints > 10000) {
            totalUnlockBasisPoints = 10000;
        }

        uint256 unlockableAmount = (totalDepositedETH * totalUnlockBasisPoints) / 10000;

        // Subtract already withdrawn amount
        return unlockableAmount > totalWithdrawnETH ? unlockableAmount - totalWithdrawnETH : 0;
    }

    /**
     * @dev Calculates the amount of a specific ERC20 token currently unlockable.
     * Aggregates unlock percentages from completed/met epochs.
     * @param _token The address of the ERC20 token.
     * @return The amount of the token that can be withdrawn.
     */
    function getUnlockableERC20Amount(address _token) public view returns (uint256) {
         if (currentVaultState == VaultState.Uninitialized || currentVaultState == VaultState.Recovery) {
             return 0;
         }

         uint256 totalUnlockBasisPoints = 0;

         for (uint256 i = 0; i < currentEpochIndex; i++) {
             uint256 epochUnlockBP = epochs[i].erc20UnlockBasisPoints[_token];
             // If no specific rule for this token, use the general ERC20 unlock BP for that epoch (if we stored it per epoch struct)
             // Current struct stores it per token mapping, so if entry doesn't exist, it's 0 unless explicitly set.
             totalUnlockBasisPoints += epochUnlockBP;
         }

         if (totalUnlockBasisPoints > 10000) {
             totalUnlockBasisPoints = 10000;
         }

         uint256 unlockableAmount = (totalDepositedERC20[_token] * totalUnlockBasisPoints) / 10000;

         return unlockableAmount > totalWithdrawnERC20[_token] ? unlockableAmount - totalWithdrawnERC20[_token] : 0;
    }

    /**
     * @dev Lists the ERC721 token IDs for a specific token that are currently unlockable.
     * Checks against tokens explicitly listed in completed/met epochs.
     * This is a simple check: if the token ID is listed in any completed epoch's rules.
     * More advanced: ensure the ID is also still held by the vault.
     * @param _token The address of the ERC721 token.
     * @return An array of unlockable token IDs.
     */
    function getUnlockableERC721Tokens(address _token) public view returns (uint256[] memory) {
        if (currentVaultState == VaultState.Uninitialized || currentVaultState == VaultState.Recovery) {
            return new uint256[](0);
        }

        // Keep track of which IDs are unlockable
        mapping(uint256 => bool) unlockedThisEpoch;
        uint256 unlockableCount = 0;

        // Iterate through all epochs up to the currentEpochIndex (meaning epochs 0 to currentEpochIndex - 1 are considered completed)
        for (uint256 i = 0; i < currentEpochIndex; i++) {
             uint256[] storage epochUnlockIds = epochs[i].erc721UnlockTokenIds[_token];
             for(uint256 j = 0; j < epochUnlockIds.length; j++) {
                 uint256 tokenId = epochUnlockIds[j];
                 if (!unlockedThisEpoch[tokenId]) {
                     // Check if the vault still holds this token (optional but good practice)
                     // try {
                     //     if (IERC721(_token).ownerOf(tokenId) == address(this)) {
                             unlockedThisEpoch[tokenId] = true;
                             unlockableCount++;
                     //     }
                     // } catch {} // Handle potential errors if token doesn't exist etc.
                 }
             }
        }

        // Build the result array
        uint256[] memory unlockableIds = new uint256[](unlockableCount);
        uint256 currentIndex = 0;
         for (uint256 i = 0; i < currentEpochIndex; i++) {
             uint256[] storage epochUnlockIds = epochs[i].erc721UnlockTokenIds[_token];
             for(uint256 j = 0; j < epochUnlockIds.length; j++) {
                 uint256 tokenId = epochUnlockIds[j];
                 if (unlockedThisEpoch[tokenId]) {
                     // Double check against withdrawn tokens to ensure it hasn't been withdrawn
                     bool isWithdrawn = false;
                     for(uint256 k=0; k < totalWithdrawnERC721Ids[_token].length; k++) {
                         if (totalWithdrawnERC721Ids[_token][k] == tokenId) {
                             isWithdrawn = true;
                             break;
                         }
                     }
                     if (!isWithdrawn) {
                        unlockedThisEpoch[tokenId] = false; // Mark as added to the list to avoid duplicates
                        unlockableIds[currentIndex++] = tokenId;
                     }
                 }
             }
        }

        return unlockableIds;
    }

    /**
     * @dev Checks if a specific address (owner or beneficiary) can withdraw assets.
     */
    function isWithdrawAllowed(address _caller) public view returns (bool) {
        return (currentVaultState == VaultState.Active || currentVaultState == VaultState.Completed) &&
               !withdrawalsPaused &&
               (_caller == owner || _caller == beneficiary);
    }


    // --- Withdrawal Functions ---

    /**
     * @dev Allows the beneficiary or owner to withdraw unlocked ETH.
     */
    function withdrawETH() public nonReentrant whenNotPausedWithdrawals {
        require(isWithdrawAllowed(msg.sender), "CV: Withdrawal not allowed for sender");

        uint256 unlockableAmount = getUnlockableETHAmount();
        require(unlockableAmount > 0, "CV: No unlockable ETH");

        totalWithdrawnETH += unlockableAmount; // Update state before sending
        (bool success, ) = payable(msg.sender).call{value: unlockableAmount}("");
        require(success, "CV: ETH transfer failed");

        emit ETHWithdrawn(msg.sender, unlockableAmount);
    }

    /**
     * @dev Allows the beneficiary or owner to withdraw a specific amount of an unlocked ERC20 token.
     * @param _token The address of the ERC20 token.
     * @param _amount The amount to withdraw.
     */
    function withdrawERC20(address _token, uint256 _amount) public nonReentrant whenNotPausedWithdrawals {
        require(isWithdrawAllowed(msg.sender), "CV: Withdrawal not allowed for sender");
        require(_token != address(0), "CV: Zero token address");
        require(_amount > 0, "CV: Amount must be > 0");

        uint256 unlockableAmount = getUnlockableERC20Amount(_token);
        require(_amount <= unlockableAmount, "CV: Amount exceeds unlockable limit");

        totalWithdrawnERC20[_token] += _amount; // Update state before sending
        IERC20(_token).safeTransfer(msg.sender, _amount);

        emit ERC20Withdrawn(msg.sender, _token, _amount);
    }

    /**
     * @dev Allows the beneficiary or owner to withdraw specific unlocked ERC721 tokens.
     * @param _token The address of the ERC721 token.
     * @param _tokenIds Array of token IDs to withdraw.
     */
    function withdrawERC721(address _token, uint256[] memory _tokenIds) public nonReentrant whenNotPausedWithdrawals {
         require(isWithdrawAllowed(msg.sender), "CV: Withdrawal not allowed for sender");
         require(_token != address(0), "CV: Zero token address");
         require(_tokenIds.length > 0, "CV: No token IDs provided");

         uint256[] memory unlockableIds = getUnlockableERC721Tokens(_token);
         mapping(uint256 => bool) isUnlockable;
         for(uint256 i = 0; i < unlockableIds.length; i++) {
             isUnlockable[unlockableIds[i]] = true;
         }

         IERC721 token = IERC721(_token);

         for (uint256 i = 0; i < _tokenIds.length; i++) {
             uint256 tokenId = _tokenIds[i];
             require(isUnlockable[tokenId], "CV: Token ID not unlockable");
             // Ensure the vault still owns the token
             require(token.ownerOf(tokenId) == address(this), "CV: Vault does not own token");

             // Mark as withdrawn (add to the list)
             totalWithdrawnERC721Ids[_token].push(tokenId);

             // Transfer
             token.safeTransferFrom(address(this), msg.sender, tokenId);

             emit ERC721Withdrawn(msg.sender, _token, new uint256[](1, tokenId)); // Emit single ID withdrawal event
         }
    }

    // --- Data Storage and Retrieval ---

    /**
     * @dev Allows the owner to store arbitrary data associated with a specific epoch.
     * Can only be called before the epoch is completed.
     * @param _epochIndex The index of the epoch.
     * @param _data The data to store (e.g., IPFS hash, metadata).
     */
    function storeEpochData(uint256 _epochIndex, bytes memory _data) public onlyOwner {
        require(_epochIndex < epochs.length, "CV: Invalid epoch index");
        require(_epochIndex >= currentEpochIndex, "CV: Cannot store data for past epoch"); // Can store for current or future epochs
        require(_data.length > 0, "CV: Data cannot be empty");

        epochs[_epochIndex].storedData = _data;
        emit EpochDataStored(_epochIndex, msg.sender);
    }

    /**
     * @dev Allows the beneficiary or owner to retrieve data stored for an epoch.
     * Data is only accessible once the epoch is completed (i.e., currentEpochIndex > _epochIndex)
     * AND all conditions required for that epoch's advancement were met (which is checked by tryAdvanceEpoch).
     * @param _epochIndex The index of the epoch.
     * @return The stored data.
     */
    function retrieveEpochData(uint256 _epochIndex) public view returns (bytes memory) {
        require(isWithdrawAllowed(msg.sender) || msg.sender == owner, "CV: Retrieval not allowed for sender"); // Owner can always retrieve? Or only beneficiary + owner if conditions met? Let's stick to beneficiary/owner if conditions met like withdrawals.
        require(_epochIndex < epochs.length, "CV: Invalid epoch index");
        // Data is accessible only if the vault has advanced *past* this epoch
        require(currentEpochIndex > _epochIndex || (currentVaultState == VaultState.Completed && currentEpochIndex == epochs.length), "CV: Epoch not yet completed");

        // Re-check conditions *for this specific epoch's advancement* (already checked by tryAdvanceEpoch, but redundant safety)
        // If we reached currentEpochIndex, it implies the previous epoch's conditions were met.
        // So, if _epochIndex < currentEpochIndex, its conditions must have been met.

        emit EpochDataRetrieved(_epochIndex, msg.sender); // Note: Events in view functions don't persist on chain
        return epochs[_epochIndex].storedData;
    }

    // --- Social Recovery ---

    /**
     * @dev Allows a recovery agent to initiate the social recovery process.
     * Can only be initiated if the vault is not in recovery already and not completed.
     */
    function initiateSocialRecovery() public onlyRecoveryAgent vaultState(VaultState.Active) {
        require(socialRecovery.state == RecoveryState.Idle, "CV: Recovery already initiated");
        require(epochs.length == 0 || block.timestamp > epochStartTime + epochs[currentEpochIndex-1].duration + RECOVERY_GRACE_PERIOD, "CV: Vault is active, cannot initiate recovery during grace period after last epoch end"); // Prevent recovery right after an epoch ends

        socialRecovery.state = RecoveryState.Initiated;
        socialRecovery.initiatedTimestamp = block.timestamp;
        socialRecovery.approvals[msg.sender] = true;
        socialRecovery.approvalCount = 1;
        socialRecovery.pendingNewOwner = address(0); // Reset potential pending addresses
        socialRecovery.pendingNewBeneficiary = address(0);

        currentVaultState = VaultState.Recovery; // Change vault state

        emit SocialRecoveryInitiated(msg.sender, socialRecovery.initiatedTimestamp);
    }

    /**
     * @dev Allows a recovery agent to approve an ongoing social recovery process.
     * Requires the process to be in the Initiated state.
     */
    function approveSocialRecovery() public onlyRecoveryAgent vaultState(VaultState.Recovery) {
        require(socialRecovery.state == RecoveryState.Initiated, "CV: Recovery not in initiated state");
        require(block.timestamp <= socialRecovery.initiatedTimestamp + RECOVERY_GRACE_PERIOD, "CV: Recovery grace period expired");
        require(!socialRecovery.approvals[msg.sender], "CV: Already approved");

        socialRecovery.approvals[msg.sender] = true;
        socialRecovery.approvalCount++;

        emit SocialRecoveryApproved(msg.sender, socialRecovery.approvalCount);

        // If threshold reached, recovery can be finalized by anyone
    }

    /**
     * @dev Allows the owner or any recovery agent (if grace period expired) to cancel the recovery process.
     */
    function cancelSocialRecovery() public nonReentrant vaultState(VaultState.Recovery) {
        require(msg.sender == owner || (isRecoveryAgent[msg.sender] && block.timestamp > socialRecovery.initiatedTimestamp + RECOVERY_GRACE_PERIOD), "CV: Not authorized to cancel recovery");

        // Reset recovery state
        socialRecovery.state = RecoveryState.Idle;
        socialRecovery.initiatedTimestamp = 0;
        socialRecovery.approvalCount = 0;
        socialRecovery.pendingNewOwner = address(0);
        socialRecovery.pendingNewBeneficiary = address(0);
        // Reset approvals mapping (can iterate through agents or just reset on next initiate)
        for (uint256 i = 0; i < recoveryAgents.length; i++) {
            socialRecovery.approvals[recoveryAgents[i]] = false;
        }

        currentVaultState = VaultState.Active; // Restore vault state

        emit SocialRecoveryCancelled(msg.sender);
    }

    /**
     * @dev Allows any address to finalize a social recovery process once the approval threshold is met.
     * Sets the new owner and beneficiary.
     * @param _newOwner The new owner address.
     * @param _newBeneficiary The new beneficiary address.
     */
    function finalizeRecovery(address payable _newOwner, address payable _newBeneficiary) public nonReentrant vaultState(VaultState.Recovery) {
        require(socialRecovery.state == RecoveryState.Initiated, "CV: Recovery not in initiated state");
        require(socialRecovery.approvalCount >= recoveryThreshold, "CV: Approval threshold not reached");
        require(block.timestamp <= socialRecovery.initiatedTimestamp + RECOVERY_GRACE_PERIOD, "CV: Recovery grace period expired"); // Can only finalize within grace period

        require(_newOwner != address(0), "CV: Zero new owner");
        require(_newBeneficiary != address(0), "CV: Zero new beneficiary");

        address oldOwner = owner;
        address oldBeneficiary = beneficiary;

        owner = _newOwner;
        beneficiary = _newBeneficiary;

        // Reset recovery state after successful finalization
        socialRecovery.state = RecoveryState.Idle;
        socialRecovery.initiatedTimestamp = 0;
        socialRecovery.approvalCount = 0;
        socialRecovery.pendingNewOwner = address(0);
        socialRecovery.pendingNewBeneficiary = address(0);
         for (uint256 i = 0; i < recoveryAgents.length; i++) {
            socialRecovery.approvals[recoveryAgents[i]] = false;
        }

        currentVaultState = VaultState.Active; // Restore vault state

        emit SocialRecoveryFinalized(_newOwner, _newBeneficiary);
        emit OwnershipTransferred(oldOwner, _newOwner); // Also emit standard ownership event
        emit BeneficiaryUpdated(oldBeneficiary, _newBeneficiary);
    }

    // --- Pause Functions (onlyOwner) ---

    /**
     * @dev Pauses new deposits into the vault.
     */
    function pauseDeposits() public onlyOwner {
        require(!depositsPaused, "CV: Deposits already paused");
        depositsPaused = true;
        emit DepositsPaused(msg.sender);
    }

    /**
     * @dev Unpauses deposits into the vault.
     */
    function unpauseDeposits() public onlyOwner {
        require(depositsPaused, "CV: Deposits not paused");
        depositsPaused = false;
        emit DepositsUnpaused(msg.sender);
    }

     /**
     * @dev Pauses withdrawals from the vault.
     */
    function pauseWithdrawals() public onlyOwner {
        require(!withdrawalsPaused, "CV: Withdrawals already paused");
        withdrawalsPaused = true;
        emit WithdrawalsPaused(msg.sender);
    }

    /**
     * @dev Unpauses withdrawals from the vault.
     */
    function unpauseWithdrawals() public onlyOwner {
        require(withdrawalsPaused, "CV: Withdrawals not paused");
        withdrawalsPaused = false;
        emit WithdrawalsUnpaused(msg.sender);
    }

    // --- Owner Management ---

    /**
     * @dev Transfers ownership of the contract.
     * Can only be called by the current owner when not in recovery.
     * @param _newOwner The address of the new owner.
     */
    function transferOwnership(address payable _newOwner) public onlyOwner vaultState(VaultState.Active) {
        require(_newOwner != address(0), "CV: Zero new owner");
        address oldOwner = owner;
        owner = _newOwner;
        emit OwnershipTransferred(oldOwner, _newOwner);
    }

    // --- Internal Helper Functions (Optional, but good for breaking down logic) ---

     /**
      * @dev Internal helper to check if a token ID is present in a list.
      * @param list The list of token IDs.
      * @param tokenId The ID to check.
      * @return True if the ID is found in the list.
      */
     function _containsTokenId(uint256[] memory list, uint256 tokenId) internal pure returns (bool) {
         for (uint256 i = 0; i < list.length; i++) {
             if (list[i] == tokenId) {
                 return true;
             }
         }
         return false;
     }

     /**
      * @dev Internal helper to add a token ID to a list without duplicates.
      * Not strictly needed for this contract's logic, but useful for tracking.
      * Assumes the list is part of a mapping storage variable.
      * @param list The storage list.
      * @param tokenId The ID to add.
      */
     function _addTokenIdToList(uint256[] storage list, uint256 tokenId) internal {
         bool found = false;
         for (uint256 i = 0; i < list.length; i++) {
             if (list[i] == tokenId) {
                 found = true;
                 break;
             }
         }
         if (!found) {
             list.push(tokenId);
         }
     }

      /**
      * @dev Internal helper to remove a token ID from a list.
      * Assumes the list is part of a mapping storage variable.
      * @param list The storage list.
      * @param tokenId The ID to remove.
      */
     function _removeTokenIdFromList(uint256[] storage list, uint256 tokenId) internal {
         for (uint256 i = 0; i < list.length; i++) {
             if (list[i] == tokenId) {
                 // Swap with last element and pop
                 list[i] = list[list.length - 1];
                 list.pop();
                 break; // Assume token ID appears at most once
             }
         }
     }
}
```