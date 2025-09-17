Here's a Solidity smart contract for an "Adaptive Legacy Protocol" that incorporates advanced concepts like dynamic rule execution based on oracle data (simulating AI influence, market conditions, events, and time), multi-party guardian governance, and flexible asset management. It aims for uniqueness by combining these elements into a novel "future-proofing" mechanism.

The contract includes **30 distinct functions**, exceeding the minimum requirement, and is structured with an outline and function summary for clarity.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title IOracle
 * @dev Interface for a generic oracle contract.
 *      Used to fetch external data (uint256 or bool) to trigger vault rules.
 */
interface IOracle {
    function getUint256(string calldata key) external view returns (uint256);
    function getBool(string calldata key) external view returns (bool);
}

/**
 * @title AdaptiveLegacyProtocol
 * @dev A decentralized protocol for creating and managing "Adaptive Legacy Vaults."
 *      These vaults dynamically adjust payouts and rules based on on-chain and off-chain events
 *      via oracle integration and multi-party guardian governance.
 *      It allows users to establish "future-proof" trusts or legacies that react to external conditions.
 */
contract AdaptiveLegacyProtocol is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // --- Outline ---
    // 1. Core State Management: Protocol ownership, pausing, fees, oracle integration.
    // 2. Data Structures: LegacyVault, VaultRule, GuardianVote, GuardianStatus.
    // 3. Vault Creation & Funding: Functions to create new vaults and deposit assets (Native & ERC20).
    // 4. Vault Rule & Action Management: Add, update, execute rules; propose and vote on vault-specific actions.
    // 5. Rule Execution & Automation: Mechanisms for evaluating and triggering rules based on conditions.
    // 6. Guardian & Beneficiary Management: Staking mechanism for protocol guardians, adding/removing vault guardians, and beneficiary claims.
    // 7. Protocol Fee & Admin Management: Withdraw fees, manage protocol-level admin.
    // 8. Advanced & Utility: Emergency withdrawals, vault ownership transfer, detailed view functions.

    // --- Function Summary ---
    // -- Protocol & Admin (Functions 1-8) --
    // 1. constructor: Initializes the contract with an admin, a default oracle, and initial fee settings.
    // 2. setProtocolFeeRecipient: Sets the address to which protocol fees are sent. (Owner-only)
    // 3. setProtocolFeePercentage: Sets the percentage fee for certain vault operations. (Owner-only)
    // 4. pause: Pauses protocol-wide operations, preventing most state-changing functions. (Owner-only)
    // 5. unpause: Unpauses protocol-wide operations. (Owner-only)
    // 6. withdrawProtocolFees: Allows the designated fee recipient to withdraw accumulated native currency protocol fees.
    // 7. updateOracleAddress: Sets the address of the trusted IOracle contract. (Owner-only)
    // 8. updateGuardianStakeRequirement: Sets the native currency amount required to stake as a protocol guardian. (Owner-only)

    // -- Legacy Vault Creation & Funding (Functions 9-11) --
    // 9. createLegacyVault: Creates a new legacy vault, deposits initial native currency, sets founder, beneficiaries, guardians, and initial rules.
    // 10. depositERC20ToVault: Allows depositing ERC20 tokens into an existing vault. (Founder/Vault Guardian)
    // 11. depositNativeToVault: Allows depositing native currency (ETH) into an existing vault. (Founder/Vault Guardian)

    // -- Vault Rule & Action Management (Functions 12-17) --
    // 12. addVaultRule: Adds a new rule to an existing vault. (Founder-only)
    // 13. updateVaultRule: Modifies an existing rule within a vault. (Founder-only)
    // 14. removeVaultRule: Removes (deactivates) an existing rule from a vault. (Founder-only)
    // 15. proposeVaultAction: Guardians or founder can propose various actions for a vault (e.g., add beneficiary, remove guardian).
    // 16. voteOnVaultAction: Guardians vote on proposed vault actions.
    // 17. executeVaultAction: Executes a vault action once it passes its voting threshold. (Callable by anyone)

    // -- Rule Execution & Automation (Functions 18-21) --
    // 18. checkAndTriggerRules: An external function callable by anyone (e.g., a keeper bot) to check and trigger *multiple* applicable rules across all vaults efficiently.
    // 19. triggerSpecificRule: Allows a specific rule of a specific vault to be triggered if its conditions are met, useful for targeted execution.
    // 20. getOracleUint256Value: Fetches a uint256 value from the set oracle. (View)
    // 21. getOracleBoolValue: Fetches a bool value from the set oracle. (View)

    // -- Guardian & Beneficiary Management (Functions 22-24) --
    // 22. stakeAsGuardian: Allows an address to stake native currency to become an eligible protocol guardian.
    // 23. unstakeAsGuardian: Allows a guardian to unstake their tokens and remove themselves from protocol guardian duties.
    // 24. claimBeneficiaryPayout: Allows a beneficiary to claim funds that have been released to them by vault rules.

    // -- Advanced & Utility (Functions 25-30) --
    // 25. getVaultDetails: A view function to retrieve high-level details of a specific vault.
    // 26. getVaultRules: A view function to retrieve details of all rules associated with a specific vault.
    // 27. getVaultActionDetails: A view function to retrieve details of a pending vault action proposal.
    // 28. withdrawVaultEmergency: Allows a vault founder to withdraw a portion of funds in emergency, with a protocol penalty.
    // 29. transferVaultOwnership: Allows a vault founder to transfer management rights of their vault to another address.
    // 30. removeGuardian: Allows founder or protocol admin to remove a guardian from a specific vault (e.g., for misconduct).

    // --- Events ---
    event ProtocolFeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);
    event ProtocolFeePercentageUpdated(uint256 indexed oldPercentage, uint256 indexed newPercentage);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);
    event OracleAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event GuardianStakeRequirementUpdated(uint256 indexed newRequirement);

    event VaultCreated(uint256 indexed vaultId, address indexed founder, uint256 initialDeposit);
    event VaultDeposit(uint256 indexed vaultId, address indexed depositor, address token, uint256 amount);
    event VaultEmergencyWithdrawal(uint256 indexed vaultId, address indexed founder, uint256 amount);
    event VaultOwnershipTransferred(uint256 indexed vaultId, address indexed oldOwner, address indexed newOwner);

    event VaultRuleAdded(uint256 indexed vaultId, uint256 indexed ruleId, address indexed creator);
    event VaultRuleUpdated(uint256 indexed vaultId, uint256 indexed ruleId, address indexed updater);
    event VaultRuleRemoved(uint256 indexed vaultId, uint256 indexed ruleId, address indexed remover);
    event VaultRuleTriggered(uint256 indexed vaultId, uint256 indexed ruleId, RuleType ruleType, address indexed beneficiary, uint256 amount);

    event VaultActionProposed(uint256 indexed vaultId, uint256 indexed actionId, ActionType actionType, address indexed proposer);
    event VaultActionVoted(uint256 indexed vaultId, uint256 indexed actionId, address indexed voter, bool support);
    event VaultActionExecuted(uint256 indexed vaultId, uint256 indexed actionId, ActionType actionType, address indexed executor);

    event GuardianStaked(address indexed guardian, uint256 amount);
    event GuardianUnstaked(address indexed guardian, uint256 amount);
    event GuardianRemoved(address indexed guardian, address indexed remover); // For vault-specific guardian removal
    event BeneficiaryClaimed(uint256 indexed vaultId, address indexed beneficiary, uint256 amount);

    // --- State Variables ---
    IOracle public oracle;
    address public protocolFeeRecipient;
    uint256 public protocolFeePercentage; // e.g., 100 = 1%, 50 = 0.5% (multiplied by 10,000 for percentage points)
    uint256 public totalProtocolFeesCollected; // Only tracks native currency fees

    uint256 public nextVaultId;
    mapping(uint256 => LegacyVault) public legacyVaults;
    mapping(uint256 => uint256[]) public vaultRules; // vaultId => array of ruleIds
    mapping(uint256 => VaultRule) public rules; // ruleId => VaultRule struct
    uint256 public nextRuleId;

    mapping(address => bool) public isProtocolGuardian; // Protocol-level guardian status (staked)
    mapping(address => uint256) public guardianStakes;
    uint256 public guardianStakeRequirement; // Minimum native currency required to stake as a guardian

    uint256 public nextActionId;
    mapping(uint256 => VaultAction) public vaultActions; // actionId => VaultAction struct

    uint256 public constant DENOMINATOR = 10_000; // For percentage calculations (1% = 100 points)
    uint256 public constant MIN_GUARDIAN_STAKE_ETH = 1 ether; // Initial guardian stake requirement

    // --- Enums ---
    enum RuleType {
        TimeLock,            // Release at a specific timestamp
        EventTrigger,        // Release based on an oracle boolean event
        MarketCondition,     // Release based on an oracle uint256 value (e.g., price, volume)
        AIPrediction,        // Release based on an "AI score" from oracle (uint256)
        BeneficiaryAge       // Release when beneficiary reaches a certain age (via oracle for DOB/current age)
    }

    enum ActionType {
        AddBeneficiary,
        RemoveBeneficiary,
        AddVaultGuardian,    // Add a guardian specifically to this vault
        RemoveVaultGuardian, // Remove a guardian specifically from this vault
        EarlyReleaseFunds,
        UpdateVotingThreshold
    }

    // --- Structs ---
    struct LegacyVault {
        address founder;
        uint256 creationTime;
        uint256 totalNativeAssets; // Tracks native currency balance
        mapping(address => uint256) erc20Balances; // ERC20 balances by token address
        mapping(address => uint256) beneficiaryAllocations; // Funds released by rules, ready for claim
        bool isActive; // Can be paused by founder/governance
        uint256 lastRuleCheckTime; // Timestamp of the last time rules were checked for this vault
        address[] currentVaultGuardians; // Addresses of guardians specifically for this vault (must be protocol guardians)
        mapping(address => bool) isVaultGuardian; // Quick check for vault-specific guardians
        uint256 vaultGuardianCount;
        uint256 votingThreshold; // Percentage threshold for guardian votes (e.g., 50 for 50%)
    }

    struct VaultRule {
        RuleType ruleType;
        uint256 vaultId;
        bool isActive;
        bool isExecuted;
        uint252 ruleCreationTimestamp; // Max 2^252 - 1, sufficient for timestamp
        uint252 executionTimestamp;    // When it was executed

        // Conditions
        uint256 targetTimestamp; // For TimeLock
        string oracleKey;        // For EventTrigger, MarketCondition, AIPrediction, BeneficiaryAge
        uint256 triggerValue;    // For MarketCondition, AIPrediction (e.g., price threshold, AI score)
        bool triggerBool;        // For EventTrigger (true/false)
        uint256 beneficiaryAge;  // For BeneficiaryAge, interpreted as target age in years

        // Actions (what happens when rule triggers)
        address targetBeneficiary; // Who receives funds (0x0 if not direct payout)
        address targetToken;       // Which token to payout (0x0 for native)
        uint256 amountPercentage;  // Percentage of remaining vault balance (e.g., 1000 for 10%)
        uint256 absoluteAmount;    // Absolute amount in wei/token units
        bytes dataPayload;         // Generic data for complex actions or future extensions
    }

    struct VaultAction {
        uint256 vaultId;
        ActionType actionType;
        address proposer;
        uint256 proposalTimestamp;
        uint256 approvalThreshold; // e.g., 50 (for 50% approval) of vault guardians
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks if a guardian has voted
        bool isExecuted;
        bool isCancelled; // Can be cancelled if expired or by founder/admin

        // Action-specific data (ABI-encoded)
        bytes data;
    }

    // --- Constructor (Function 1) ---
    /// @dev Initializes the contract with an admin, a default oracle, and initial fee settings.
    /// @param initialOracleAddress The address of the trusted IOracle contract.
    /// @param initialFeeRecipient The address to which protocol fees will be sent.
    constructor(address initialOracleAddress, address initialFeeRecipient)
        Ownable(msg.sender)
        Pausable()
    {
        require(initialOracleAddress != address(0), "Oracle address cannot be zero");
        require(initialFeeRecipient != address(0), "Fee recipient cannot be zero");
        oracle = IOracle(initialOracleAddress);
        protocolFeeRecipient = initialFeeRecipient;
        protocolFeePercentage = 50; // Default 0.5% fee (50 / 10,000)
        guardianStakeRequirement = MIN_GUARDIAN_STAKE_ETH;
        nextVaultId = 1;
        nextRuleId = 1;
        nextActionId = 1;
    }

    // --- Protocol & Admin Functions (2-8) ---

    /// @dev Sets the address to which protocol fees are sent.
    /// @param _newRecipient The new address for protocol fee collection.
    function setProtocolFeeRecipient(address _newRecipient) external onlyOwner { // Function 2
        require(_newRecipient != address(0), "New recipient cannot be zero address");
        emit ProtocolFeeRecipientUpdated(protocolFeeRecipient, _newRecipient);
        protocolFeeRecipient = _newRecipient;
    }

    /// @dev Sets the percentage fee for certain vault operations.
    /// @param _newPercentage The new fee percentage (e.g., 100 for 1%, 50 for 0.5%). Max 1000 (10%).
    function setProtocolFeePercentage(uint256 _newPercentage) external onlyOwner { // Function 3
        require(_newPercentage <= 1000, "Fee percentage too high (max 10%)");
        emit ProtocolFeePercentageUpdated(protocolFeePercentage, _newPercentage);
        protocolFeePercentage = _newPercentage;
    }

    /// @dev Pauses protocol-wide operations. Only callable by the protocol admin.
    function pause() public onlyOwner { // Function 4
        _pause();
    }

    /// @dev Unpauses protocol-wide operations. Only callable by the protocol admin.
    function unpause() public onlyOwner { // Function 5
        _unpause();
    }

    /// @dev Allows the designated fee recipient to withdraw accumulated native currency protocol fees.
    function withdrawProtocolFees() external nonReentrant { // Function 6
        require(msg.sender == protocolFeeRecipient, "Only fee recipient can withdraw");
        uint256 amountToWithdraw = totalProtocolFeesCollected;
        totalProtocolFeesCollected = 0; // Reset
        (bool success, ) = payable(protocolFeeRecipient).call{value: amountToWithdraw}("");
        require(success, "Failed to withdraw native fees");
        emit ProtocolFeesWithdrawn(protocolFeeRecipient, amountToWithdraw);
    }

    /// @dev Updates the address of the trusted IOracle contract.
    /// @param _newOracleAddress The new address for the oracle.
    function updateOracleAddress(address _newOracleAddress) external onlyOwner { // Function 7
        require(_newOracleAddress != address(0), "New oracle address cannot be zero");
        emit OracleAddressUpdated(address(oracle), _newOracleAddress);
        oracle = IOracle(_newOracleAddress);
    }

    /// @dev Sets the amount of native currency required to stake as a protocol guardian.
    /// @param _newRequirement The new minimum stake amount for protocol guardians.
    function updateGuardianStakeRequirement(uint256 _newRequirement) external onlyOwner { // Function 8
        require(_newRequirement > 0, "Stake requirement must be positive");
        emit GuardianStakeRequirementUpdated(_newRequirement);
        guardianStakeRequirement = _newRequirement;
    }

    // --- Legacy Vault Creation & Funding (9-11) ---

    /// @dev Creates a new legacy vault, specifying founder, initial beneficiaries, vault guardians, and initial rules.
    ///      Deposits initial native currency to the vault. A protocol fee is applied.
    /// @param _beneficiaries Initial addresses of beneficiaries.
    /// @param _initialRules Initial rules for the vault.
    /// @param _vaultGuardians Addresses of initial vault-specific guardians. Must be staked protocol guardians.
    /// @param _votingThreshold Percentage threshold for guardian votes (e.g., 50 for 50% approval).
    /// @return vaultId The ID of the newly created vault.
    function createLegacyVault( // Function 9
        address[] calldata _beneficiaries,
        VaultRule[] calldata _initialRules,
        address[] calldata _vaultGuardians,
        uint256 _votingThreshold
    ) external payable nonReentrant whenNotPaused returns (uint256 vaultId) {
        require(msg.value > 0, "Initial deposit required");
        require(_votingThreshold > 0 && _votingThreshold <= 100, "Invalid voting threshold (0-100)");
        require(_vaultGuardians.length > 0, "At least one guardian required for the vault");

        uint256 feeAmount = (msg.value * protocolFeePercentage) / DENOMINATOR;
        require(msg.value >= feeAmount, "Deposit too small to cover fee"); // Ensure enough to cover fee
        totalProtocolFeesCollected += feeAmount;
        uint256 vaultBalance = msg.value - feeAmount;

        vaultId = nextVaultId++;
        LegacyVault storage newVault = legacyVaults[vaultId];
        newVault.founder = msg.sender;
        newVault.creationTime = block.timestamp;
        newVault.totalNativeAssets = vaultBalance;
        newVault.isActive = true;
        newVault.votingThreshold = _votingThreshold;

        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            require(_beneficiaries[i] != address(0), "Beneficiary cannot be zero address");
            newVault.beneficiaryAllocations[_beneficiaries[i]] = 0;
        }

        for (uint256 i = 0; i < _vaultGuardians.length; i++) {
            require(_vaultGuardians[i] != address(0), "Guardian cannot be zero address");
            require(isProtocolGuardian[_vaultGuardians[i]], "Guardian must be a staked protocol guardian");
            newVault.currentVaultGuardians.push(_vaultGuardians[i]);
            newVault.isVaultGuardian[_vaultGuardians[i]] = true;
            newVault.vaultGuardianCount++;
        }

        for (uint256 i = 0; i < _initialRules.length; i++) {
            VaultRule memory rule = _initialRules[i];
            rule.vaultId = vaultId;
            rule.isActive = true;
            rule.ruleCreationTimestamp = uint252(block.timestamp);
            rules[nextRuleId] = rule;
            vaultRules[vaultId].push(nextRuleId);
            emit VaultRuleAdded(vaultId, nextRuleId, msg.sender);
            nextRuleId++;
        }

        emit VaultCreated(vaultId, msg.sender, vaultBalance);
    }

    /// @dev Allows depositing ERC20 tokens into an existing vault.
    /// @param _vaultId The ID of the target vault.
    /// @param _token The address of the ERC20 token to deposit.
    /// @param _amount The amount of ERC20 tokens to deposit.
    function depositERC20ToVault(uint256 _vaultId, address _token, uint256 _amount) // Function 10
        external
        whenNotPaused
        nonReentrant
    {
        LegacyVault storage vault = legacyVaults[_vaultId];
        require(vault.founder != address(0), "Vault does not exist");
        require(msg.sender == vault.founder || vault.isVaultGuardian[msg.sender], "Not authorized to deposit");
        require(_token != address(0), "Token address cannot be zero");
        require(_amount > 0, "Deposit amount must be positive");

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        vault.erc20Balances[_token] += _amount;
        emit VaultDeposit(_vaultId, msg.sender, _token, _amount);
    }

    /// @dev Allows depositing native currency (ETH) into an existing vault.
    /// @param _vaultId The ID of the target vault.
    function depositNativeToVault(uint256 _vaultId) external payable whenNotPaused nonReentrant { // Function 11
        LegacyVault storage vault = legacyVaults[_vaultId];
        require(vault.founder != address(0), "Vault does not exist");
        require(msg.sender == vault.founder || vault.isVaultGuardian[msg.sender], "Not authorized to deposit");
        require(msg.value > 0, "Deposit amount must be positive");

        vault.totalNativeAssets += msg.value;
        emit VaultDeposit(_vaultId, msg.sender, address(0), msg.value);
    }

    // --- Vault Rule & Action Management (12-17) ---

    /// @dev Adds a new rule to an existing vault. Callable by founder. For guardian approval, use `proposeVaultAction`.
    /// @param _vaultId The ID of the target vault.
    /// @param _rule The new rule to add.
    function addVaultRule(uint256 _vaultId, VaultRule calldata _rule) external whenNotPaused { // Function 12
        LegacyVault storage vault = legacyVaults[_vaultId];
        require(vault.founder != address(0), "Vault does not exist");
        require(msg.sender == vault.founder, "Only founder can add rules directly");

        uint256 ruleId = nextRuleId++;
        rules[ruleId] = _rule;
        rules[ruleId].vaultId = _vaultId;
        rules[ruleId].isActive = true;
        rules[ruleId].ruleCreationTimestamp = uint252(block.timestamp);
        vaultRules[_vaultId].push(ruleId);
        emit VaultRuleAdded(_vaultId, ruleId, msg.sender);
    }

    /// @dev Modifies an existing rule within a vault. Callable by founder. For guardian approval, use `proposeVaultAction`.
    /// @param _vaultId The ID of the target vault.
    /// @param _ruleId The ID of the rule to update.
    /// @param _updatedRule The new rule definition.
    function updateVaultRule(uint256 _vaultId, uint256 _ruleId, VaultRule calldata _updatedRule) external whenNotPaused { // Function 13
        LegacyVault storage vault = legacyVaults[_vaultId];
        require(vault.founder != address(0), "Vault does not exist");
        require(msg.sender == vault.founder, "Only founder can update rules directly");
        require(rules[_ruleId].vaultId == _vaultId, "Rule not associated with this vault");
        require(!rules[_ruleId].isExecuted, "Cannot update an already executed rule");

        VaultRule storage existingRule = rules[_ruleId];
        existingRule.ruleType = _updatedRule.ruleType;
        existingRule.isActive = _updatedRule.isActive;
        existingRule.targetTimestamp = _updatedRule.targetTimestamp;
        existingRule.oracleKey = _updatedRule.oracleKey;
        existingRule.triggerValue = _updatedRule.triggerValue;
        existingRule.triggerBool = _updatedRule.triggerBool;
        existingRule.beneficiaryAge = _updatedRule.beneficiaryAge;
        existingRule.targetBeneficiary = _updatedRule.targetBeneficiary;
        existingRule.targetToken = _updatedRule.targetToken;
        existingRule.amountPercentage = _updatedRule.amountPercentage;
        existingRule.absoluteAmount = _updatedRule.absoluteAmount;
        existingRule.dataPayload = _updatedRule.dataPayload;

        emit VaultRuleUpdated(_vaultId, _ruleId, msg.sender);
    }

    /// @dev Removes (deactivates) an existing rule from a vault. Callable by founder. For guardian approval, use `proposeVaultAction`.
    /// @param _vaultId The ID of the target vault.
    /// @param _ruleId The ID of the rule to remove.
    function removeVaultRule(uint256 _vaultId, uint256 _ruleId) external whenNotPaused { // Function 14
        LegacyVault storage vault = legacyVaults[_vaultId];
        require(vault.founder != address(0), "Vault does not exist");
        require(msg.sender == vault.founder, "Only founder can remove rules directly");
        require(rules[_ruleId].vaultId == _vaultId, "Rule not associated with this vault");
        require(rules[_ruleId].isActive, "Rule is already inactive or executed");

        rules[_ruleId].isActive = false; // Mark as inactive to preserve history
        emit VaultRuleRemoved(_vaultId, _ruleId, msg.sender);
    }

    /// @dev Guardians or founder can propose various actions for a vault.
    /// @param _vaultId The ID of the target vault.
    /// @param _actionType The type of action being proposed.
    /// @param _data ABI-encoded data specific to the action type.
    function proposeVaultAction(uint256 _vaultId, ActionType _actionType, bytes calldata _data) // Function 15
        external
        whenNotPaused
    {
        LegacyVault storage vault = legacyVaults[_vaultId];
        require(vault.founder != address(0), "Vault does not exist");
        require(msg.sender == vault.founder || vault.isVaultGuardian[msg.sender], "Not authorized to propose actions");

        uint256 actionId = nextActionId++;
        VaultAction storage newAction = vaultActions[actionId];
        newAction.vaultId = _vaultId;
        newAction.actionType = _actionType;
        newAction.proposer = msg.sender;
        newAction.proposalTimestamp = block.timestamp;
        newAction.approvalThreshold = vault.votingThreshold; // Use vault's voting threshold
        newAction.data = _data;

        emit VaultActionProposed(_vaultId, actionId, _actionType, msg.sender);
    }

    /// @dev Guardians vote on proposed vault actions.
    /// @param _actionId The ID of the action to vote on.
    /// @param _support True for 'for', false for 'against'.
    function voteOnVaultAction(uint256 _actionId, bool _support) external whenNotPaused { // Function 16
        VaultAction storage action = vaultActions[_actionId];
        require(action.vaultId != 0, "Action does not exist");
        LegacyVault storage vault = legacyVaults[action.vaultId];
        require(vault.founder != address(0), "Vault does not exist");
        require(vault.isVaultGuardian[msg.sender], "Only vault guardian can vote");
        require(!action.hasVoted[msg.sender], "Guardian already voted");
        require(!action.isExecuted, "Action already executed");
        require(!action.isCancelled, "Action cancelled");

        action.hasVoted[msg.sender] = true;
        if (_support) {
            action.votesFor++;
        } else {
            action.votesAgainst++;
        }
        emit VaultActionVoted(action.vaultId, _actionId, msg.sender, _support);
    }

    /// @dev Executes a vault action once it passes its voting threshold. Callable by anyone after conditions met.
    /// @param _actionId The ID of the action to execute.
    function executeVaultAction(uint256 _actionId) external nonReentrant whenNotPaused { // Function 17
        VaultAction storage action = vaultActions[_actionId];
        require(action.vaultId != 0, "Action does not exist");
        LegacyVault storage vault = legacyVaults[action.vaultId];
        require(vault.founder != address(0), "Vault does not exist");
        require(!action.isExecuted, "Action already executed");
        require(!action.isCancelled, "Action cancelled");
        require(vault.vaultGuardianCount > 0, "No guardians to vote, action cannot be executed");

        uint256 totalVotesCast = action.votesFor + action.votesAgainst;
        require(totalVotesCast * 100 >= vault.vaultGuardianCount * action.approvalThreshold, "Not enough votes cast to meet quorum threshold");
        require(action.votesFor > action.votesAgainst, "Action did not pass vote (majority for required)");

        bytes memory data = action.data;
        if (action.actionType == ActionType.AddBeneficiary) {
            address newBeneficiary = abi.decode(data, (address));
            require(newBeneficiary != address(0), "New beneficiary cannot be zero address");
            require(vault.beneficiaryAllocations[newBeneficiary] == 0, "Beneficiary already exists");
            vault.beneficiaryAllocations[newBeneficiary] = 0;
        } else if (action.actionType == ActionType.RemoveBeneficiary) {
            address beneficiaryToRemove = abi.decode(data, (address));
            require(vault.beneficiaryAllocations[beneficiaryToRemove] == 0, "Beneficiary still has pending allocations");
            delete vault.beneficiaryAllocations[beneficiaryToRemove];
        } else if (action.actionType == ActionType.AddVaultGuardian) {
            address newGuardian = abi.decode(data, (address));
            require(newGuardian != address(0), "New guardian cannot be zero address");
            require(isProtocolGuardian[newGuardian], "New guardian must be a staked protocol guardian");
            require(!vault.isVaultGuardian[newGuardian], "Guardian already added to vault");
            vault.currentVaultGuardians.push(newGuardian);
            vault.isVaultGuardian[newGuardian] = true;
            vault.vaultGuardianCount++;
        } else if (action.actionType == ActionType.RemoveVaultGuardian) {
            address guardianToRemove = abi.decode(data, (address));
            require(vault.isVaultGuardian[guardianToRemove], "Guardian not part of this vault");
            vault.isVaultGuardian[guardianToRemove] = false;
            vault.vaultGuardianCount--;
            for (uint256 i = 0; i < vault.currentVaultGuardians.length; i++) {
                if (vault.currentVaultGuardians[i] == guardianToRemove) {
                    vault.currentVaultGuardians[i] = vault.currentVaultGuardians[vault.currentVaultGuardians.length - 1];
                    vault.currentVaultGuardians.pop();
                    break;
                }
            }
            emit GuardianRemoved(guardianToRemove, action.proposer);
        } else if (action.actionType == ActionType.EarlyReleaseFunds) {
            (address beneficiary, address token, uint256 amount) = abi.decode(data, (address, address, uint256));
            _transferVaultAssets(vault, beneficiary, token, amount);
        } else if (action.actionType == ActionType.UpdateVotingThreshold) {
            uint256 newThreshold = abi.decode(data, (uint256));
            require(newThreshold > 0 && newThreshold <= 100, "Invalid new voting threshold");
            vault.votingThreshold = newThreshold;
        } else {
            revert("Unsupported action type");
        }

        action.isExecuted = true;
        emit VaultActionExecuted(action.vaultId, _actionId, action.actionType, msg.sender);
    }

    // --- Rule Execution & Automation (18-21) ---

    /// @dev Checks and triggers all applicable rules across all active vaults.
    ///      Can be called by anyone (e.g., a keeper bot). Includes a simple gas limit to prevent revert.
    /// @param _maxRulesToProcess Maximum number of rules to attempt to process in this transaction.
    function checkAndTriggerRules(uint256 _maxRulesToProcess) external nonReentrant whenNotPaused { // Function 18
        uint256 rulesProcessed = 0;
        uint256 currentVaultId = 1;

        // Iterate through vaults
        while (currentVaultId < nextVaultId && rulesProcessed < _maxRulesToProcess) {
            LegacyVault storage vault = legacyVaults[currentVaultId];
            if (vault.founder != address(0) && vault.isActive) {
                for (uint256 i = 0; i < vaultRules[currentVaultId].length && rulesProcessed < _maxRulesToProcess; i++) {
                    uint256 ruleId = vaultRules[currentVaultId][i];
                    VaultRule storage rule = rules[ruleId];

                    if (rule.isActive && !rule.isExecuted) {
                        _evaluateAndExecuteRule(currentVaultId, ruleId, rule);
                        rulesProcessed++;
                    }
                }
            }
            currentVaultId++;
        }
    }

    /// @dev Allows a specific rule of a specific vault to be triggered if its conditions are met.
    ///      Useful for targeted execution or when batch processing is too gas-intensive.
    /// @param _vaultId The ID of the vault containing the rule.
    /// @param _ruleId The ID of the rule to trigger.
    function triggerSpecificRule(uint256 _vaultId, uint256 _ruleId) external nonReentrant whenNotPaused { // Function 19
        LegacyVault storage vault = legacyVaults[_vaultId];
        require(vault.founder != address(0), "Vault does not exist");
        require(vault.isActive, "Vault is not active");
        require(rules[_ruleId].vaultId == _vaultId, "Rule not associated with this vault");

        VaultRule storage rule = rules[_ruleId];
        require(rule.isActive, "Rule is not active");
        require(!rule.isExecuted, "Rule already executed");

        _evaluateAndExecuteRule(_vaultId, _ruleId, rule);
    }

    /// @dev Internal function to evaluate a rule's conditions and execute its action if met.
    function _evaluateAndExecuteRule(uint256 _vaultId, uint256 _ruleId, VaultRule storage _rule) internal {
        LegacyVault storage vault = legacyVaults[_vaultId];
        bool conditionMet = false;

        if (_rule.ruleType == RuleType.TimeLock) {
            conditionMet = (block.timestamp >= _rule.targetTimestamp);
        } else if (_rule.ruleType == RuleType.EventTrigger) {
            conditionMet = oracle.getBool(_rule.oracleKey) == _rule.triggerBool;
        } else if (_rule.ruleType == RuleType.MarketCondition) {
            conditionMet = (oracle.getUint256(_rule.oracleKey) >= _rule.triggerValue); // Example: price >= triggerValue
        } else if (_rule.ruleType == RuleType.AIPrediction) {
            conditionMet = (oracle.getUint256(_rule.oracleKey) >= _rule.triggerValue); // Example: AI score >= triggerValue
        } else if (_rule.ruleType == RuleType.BeneficiaryAge) {
            // Assume oracleKey returns beneficiary's current age in years (e.g., "age_alice" -> 30)
            conditionMet = (oracle.getUint256(_rule.oracleKey) >= _rule.beneficiaryAge);
        }

        if (conditionMet) {
            _rule.isExecuted = true;
            _rule.executionTimestamp = uint252(block.timestamp);

            uint256 amountToPayout = 0;
            if (_rule.amountPercentage > 0) {
                uint256 totalAvailable = (_rule.targetToken == address(0))
                    ? vault.totalNativeAssets
                    : vault.erc20Balances[_rule.targetToken];
                amountToPayout = (totalAvailable * _rule.amountPercentage) / DENOMINATOR; // Use DENOMINATOR for percentages
            } else if (_rule.absoluteAmount > 0) {
                amountToPayout = _rule.absoluteAmount;
            }

            if (amountToPayout > 0 && _rule.targetBeneficiary != address(0)) {
                vault.beneficiaryAllocations[_rule.targetBeneficiary] += amountToPayout;
                emit VaultRuleTriggered(_vaultId, _ruleId, _rule.ruleType, _rule.targetBeneficiary, amountToPayout);
            }
        }
    }

    /// @dev Fetches a uint256 value from the set oracle, for use in rule evaluation or external queries.
    /// @param _key The key for the data to retrieve from the oracle.
    /// @return The uint256 value returned by the oracle.
    function getOracleUint256Value(string calldata _key) external view returns (uint256) { // Function 20
        return oracle.getUint256(_key);
    }

    /// @dev Fetches a bool value from the set oracle, for use in rule evaluation or external queries.
    /// @param _key The key for the data to retrieve from the oracle.
    /// @return The bool value returned by the oracle.
    function getOracleBoolValue(string calldata _key) external view returns (bool) { // Function 21
        return oracle.getBool(_key);
    }

    // --- Guardian & Beneficiary Management (22-24) ---

    /// @dev Allows an address to stake native currency to become an eligible protocol guardian.
    function stakeAsGuardian() external payable whenNotPaused nonReentrant { // Function 22
        require(msg.value >= guardianStakeRequirement, "Insufficient stake amount");
        require(!isProtocolGuardian[msg.sender], "Already a protocol guardian");

        guardianStakes[msg.sender] += msg.value;
        isProtocolGuardian[msg.sender] = true;
        emit GuardianStaked(msg.sender, msg.value);
    }

    /// @dev Allows a guardian to unstake their tokens and remove themselves from protocol guardian duties.
    ///      This currently has no checks for active votes. In a real system, it would prevent unstaking
    ///      if the guardian is involved in active proposals or locked due to misconduct.
    function unstakeAsGuardian() external nonReentrant whenNotPaused { // Function 23
        require(isProtocolGuardian[msg.sender], "Not a protocol guardian");
        require(guardianStakes[msg.sender] > 0, "No stake to withdraw");

        uint256 amount = guardianStakes[msg.sender];
        delete guardianStakes[msg.sender];
        delete isProtocolGuardian[msg.sender];

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Failed to send native currency");
        emit GuardianUnstaked(msg.sender, amount);
    }

    /// @dev Allows a beneficiary to claim funds that have been released to them by vault rules.
    /// @param _vaultId The ID of the vault from which to claim.
    /// @param _token The token to claim (address(0) for native currency).
    function claimBeneficiaryPayout(uint256 _vaultId, address _token) external nonReentrant { // Function 24
        LegacyVault storage vault = legacyVaults[_vaultId];
        require(vault.founder != address(0), "Vault does not exist");
        require(vault.beneficiaryAllocations[msg.sender] > 0, "No funds allocated to this address");

        uint256 amountToClaim = vault.beneficiaryAllocations[msg.sender];
        require(amountToClaim > 0, "No funds available to claim");

        _transferVaultAssets(vault, msg.sender, _token, amountToClaim);
        vault.beneficiaryAllocations[msg.sender] = 0; // Reset allocation
        emit BeneficiaryClaimed(_vaultId, msg.sender, amountToClaim);
    }

    // --- Advanced & Utility (25-30) ---

    /// @dev A view function to retrieve high-level details of a specific vault.
    /// @param _vaultId The ID of the vault to query.
    /// @return A tuple containing vault details.
    function getVaultDetails(uint256 _vaultId) // Function 25
        external
        view
        returns (
            address founder,
            uint256 creationTime,
            uint256 totalNativeAssets,
            bool isActive,
            uint256 lastRuleCheckTime,
            address[] memory currentVaultGuardians,
            uint256 vaultGuardianCount,
            uint256 votingThreshold
        )
    {
        LegacyVault storage vault = legacyVaults[_vaultId];
        require(vault.founder != address(0), "Vault does not exist");

        founder = vault.founder;
        creationTime = vault.creationTime;
        totalNativeAssets = vault.totalNativeAssets;
        isActive = vault.isActive;
        lastRuleCheckTime = vault.lastRuleCheckTime;
        currentVaultGuardians = vault.currentVaultGuardians;
        vaultGuardianCount = vault.vaultGuardianCount;
        votingThreshold = vault.votingThreshold;
    }

    /// @dev A view function to retrieve details of all rules associated with a specific vault.
    /// @param _vaultId The ID of the vault to query.
    /// @return An array of VaultRule structs.
    function getVaultRules(uint256 _vaultId) external view returns (VaultRule[] memory) { // Function 26
        require(legacyVaults[_vaultId].founder != address(0), "Vault does not exist");
        uint256[] memory ruleIds = vaultRules[_vaultId];
        VaultRule[] memory _rules = new VaultRule[](ruleIds.length);
        for (uint256 i = 0; i < ruleIds.length; i++) {
            _rules[i] = rules[ruleIds[i]];
        }
        return _rules;
    }

    /// @dev A view function to retrieve details of a pending vault action proposal.
    /// @param _actionId The ID of the action to query.
    /// @return A tuple containing action details.
    function getVaultActionDetails(uint256 _actionId) // Function 27
        external
        view
        returns (
            uint256 vaultId,
            ActionType actionType,
            address proposer,
            uint256 proposalTimestamp,
            uint256 approvalThreshold,
            uint256 votesFor,
            uint256 votesAgainst,
            bool isExecuted,
            bool isCancelled,
            bytes memory data
        )
    {
        VaultAction storage action = vaultActions[_actionId];
        require(action.vaultId != 0, "Action does not exist");

        vaultId = action.vaultId;
        actionType = action.actionType;
        proposer = action.proposer;
        proposalTimestamp = action.proposalTimestamp;
        approvalThreshold = action.approvalThreshold;
        votesFor = action.votesFor;
        votesAgainst = action.votesAgainst;
        isExecuted = action.isExecuted;
        isCancelled = action.isCancelled;
        data = action.data;
    }

    /// @dev Allows a vault founder to withdraw a portion of funds in emergency,
    ///      with a penalty applied, which is collected as protocol fees.
    /// @param _vaultId The ID of the vault.
    /// @param _token The token to withdraw (address(0) for native currency).
    /// @param _amount The amount to withdraw.
    function withdrawVaultEmergency(uint256 _vaultId, address _token, uint256 _amount) // Function 28
        external
        nonReentrant
        whenNotPaused
    {
        LegacyVault storage vault = legacyVaults[_vaultId];
        require(vault.founder != address(0), "Vault does not exist");
        require(msg.sender == vault.founder, "Only current founder can initiate emergency withdrawal");
        require(_amount > 0, "Withdrawal amount must be positive");

        uint256 penaltyPercentage = 1000; // 10% penalty for emergency withdrawal (1000 / 10,000)
        uint256 penaltyAmount = (_amount * penaltyPercentage) / DENOMINATOR;
        uint256 netAmount = _amount - penaltyAmount;

        _transferVaultAssets(vault, msg.sender, _token, netAmount);

        totalProtocolFeesCollected += penaltyAmount; // Penalty collected as protocol fees
        emit VaultEmergencyWithdrawal(_vaultId, msg.sender, netAmount);
        emit ProtocolFeesWithdrawn(protocolFeeRecipient, penaltyAmount);
    }

    /// @dev Allows a vault founder to transfer management rights of their vault to another address.
    /// @param _vaultId The ID of the vault.
    /// @param _newOwner The new address to become the founder of the vault.
    function transferVaultOwnership(uint256 _vaultId, address _newOwner) external whenNotPaused { // Function 29
        LegacyVault storage vault = legacyVaults[_vaultId];
        require(vault.founder != address(0), "Vault does not exist");
        require(msg.sender == vault.founder, "Only current founder can transfer ownership");
        require(_newOwner != address(0), "New owner cannot be zero address");

        address oldOwner = vault.founder;
        vault.founder = _newOwner;
        emit VaultOwnershipTransferred(_vaultId, oldOwner, _newOwner);
    }

    /// @dev Allows founder or protocol admin to remove a guardian from a specific vault.
    ///      This is distinct from `unstakeAsGuardian` which is self-removal.
    ///      This function is for removal (e.g., for misconduct, after a separate governance vote).
    /// @param _vaultId The ID of the vault.
    /// @param _guardianToRemove The address of the guardian to remove.
    function removeGuardian(uint256 _vaultId, address _guardianToRemove) external whenNotPaused { // Function 30
        LegacyVault storage vault = legacyVaults[_vaultId];
        require(vault.founder != address(0), "Vault does not exist");
        require(msg.sender == vault.founder || owner() == msg.sender, "Only founder or protocol admin can remove guardian");
        require(vault.isVaultGuardian[_guardianToRemove], "Guardian is not part of this vault");
        require(_guardianToRemove != address(0), "Cannot remove zero address");

        vault.isVaultGuardian[_guardianToRemove] = false;
        vault.vaultGuardianCount--;
        // Remove from dynamic array
        for (uint256 i = 0; i < vault.currentVaultGuardians.length; i++) {
            if (vault.currentVaultGuardians[i] == _guardianToRemove) {
                vault.currentVaultGuardians[i] = vault.currentVaultGuardians[vault.currentVaultGuardians.length - 1];
                vault.currentVaultGuardians.pop();
                break;
            }
        }
        emit GuardianRemoved(_guardianToRemove, msg.sender);
    }

    // --- Internal Helpers ---

    /// @dev Internal function to safely transfer assets from a vault.
    function _transferVaultAssets(LegacyVault storage _vault, address _recipient, address _token, uint256 _amount) internal {
        if (_token == address(0)) {
            require(_vault.totalNativeAssets >= _amount, "Insufficient native assets in vault");
            _vault.totalNativeAssets -= _amount;
            (bool success, ) = payable(_recipient).call{value: _amount}("");
            require(success, "Failed to send native currency");
        } else {
            require(_vault.erc20Balances[_token] >= _amount, "Insufficient ERC20 assets in vault");
            _vault.erc20Balances[_token] -= _amount;
            IERC20(_token).safeTransfer(_recipient, _amount);
        }
    }

    // --- Receive and Fallback Functions ---

    /// @dev Allows receiving native currency directly into the contract.
    ///      Any direct transfers to the contract without calling a specific function
    ///      will increase `totalProtocolFeesCollected` by default, or could be configured
    ///      to be unallocated funds. For simplicity here, it's considered unallocated and
    ///      requires explicit withdrawal mechanism.
    receive() external payable {
        // Unallocated funds could be claimed by admin or require special rules.
        // For simplicity, direct sends are not explicitly managed here for vaults,
        // and explicit deposit functions should be used.
        // If meant for fees: totalProtocolFeesCollected += msg.value;
    }

    /// @dev Fallback function to catch calls to non-existent functions.
    fallback() external payable {
        revert("Fallback function called: unknown function or direct send to contract without explicit method.");
    }
}
```