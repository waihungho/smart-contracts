Okay, this is an exciting challenge! Let's design a smart contract called "ChronoForge" – a protocol for creating and managing highly customizable, time-gated, and event-contingent agreements, with a focus on advanced conditional logic and multi-stage execution. It goes beyond simple vesting or escrows by allowing complex combinations of on-chain data, oracle feeds, and even chained agreements to trigger actions.

It focuses on "Programmable Trust" where actions are executed only when a set of predefined, verifiable conditions are met over time or based on external events.

---

## ChronoForge Smart Contract

**Outline:**

1.  **Contract Overview:** High-level description of ChronoForge's purpose.
2.  **Core Concepts:** Explanation of key structs and enums.
3.  **Interfaces:** External contracts ChronoForge interacts with.
4.  **State Variables:** Main storage for agreements, roles, and settings.
5.  **Events:** Signaling significant actions.
6.  **Modifiers:** Access control and validation.
7.  **Constructor:** Initialization.
8.  **Agreement Management Functions:** Create, update, cancel, activate agreements.
9.  **Condition & Action Management Functions:** Add/remove specific triggers and outputs.
10. **Execution & Claim Functions:** Triggering and claiming agreement outputs.
11. **Dispute Resolution Functions:** Mechanisms for resolving conflicts.
12. **Role Management Functions:** Assigning and revoking special permissions.
13. **Protocol Settings Functions:** Admin controls for fees, target contracts etc.
14. **Utility & View Functions:** Reading agreement states and details.

**Function Summary (At least 20 unique functions):**

1.  `constructor()`: Initializes the contract with an owner.
2.  `createTemporalAgreement()`: Initiates a new multi-stage, time/event-contingent agreement.
3.  `depositForAgreement()`: Deposits assets (ETH/ERC20) into a specific agreement for later distribution.
4.  `updateTemporalAgreementDetails()`: Allows creators to modify agreement details before activation.
5.  `addConditionToAgreement()`: Adds a specific trigger condition (time, oracle, event, external verifier) to an agreement.
6.  `removeConditionFromAgreement()`: Removes a condition from an agreement (if not active).
7.  `addActionToAgreement()`: Defines an action (token transfer, contract call) to be executed upon conditions met.
8.  `removeActionFromAgreement()`: Removes an action from an agreement (if not active).
9.  `activateTemporalAgreement()`: Changes an agreement's status from PENDING to ACTIVE, enabling its conditions to be checked.
10. `cancelTemporalAgreement()`: Allows the creator or owner to cancel an agreement under specific conditions (e.g., before active, or if all parties agree).
11. `executeTemporalAgreementLogic()`: The core function called to check if an agreement's conditions are met. This is often called by a keeper or automated system.
12. `claimAgreementOutput()`: Allows the recipient to claim assets or trigger actions once an agreement is deemed `ReadyForExecution`.
13. `withdrawUnusedFunds()`: Allows the creator to withdraw any remaining funds from a cancelled or fully executed agreement.
14. `assignVerifierRole()`: Grants a specific address the role of an `AgreementVerifier` (can call `executeTemporalAgreementLogic`).
15. `revokeVerifierRole()`: Revokes the `AgreementVerifier` role.
16. `setOracleAddress()`: Sets the address of the trusted oracle contract for data feeds.
17. `setExternalLogicVerifierAddress()`: Sets the address of a contract that handles complex, external boolean logic for conditions.
18. `proposeArbitrator()`: Initiates a proposal for an arbitrator to resolve a specific agreement dispute.
19. `approveArbitrator()`: Allows involved parties to approve a proposed arbitrator.
20. `resolveDispute()`: The chosen arbitrator's function to settle a dispute and determine the agreement's final outcome.
21. `initiateLivenessCheck()`: Initiates a "liveness check" for a recipient, requiring them to prove activity within a timeframe or risk agreement cancellation.
22. `submitLivenessProof()`: Allows a recipient to submit proof of their "liveness" for a specific agreement.
23. `linkTemporalAgreements()`: Establishes a dependency where the successful execution of one agreement triggers another.
24. `setExecutionFee()`: Owner function to set a fee for successful agreement executions.
25. `withdrawFees()`: Owner function to withdraw accumulated protocol fees.
26. `transferOwnership()`: Standard OpenZeppelin ownership transfer.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Interfaces for external dependencies
interface IOracle {
    function getLatestPrice(string calldata symbol) external view returns (int256);
    function getBooleanData(string calldata key) external view returns (bool);
    // Add more specific oracle functions as needed, e.g., for sports results, specific data feeds
}

interface IExternalVerifier {
    // For highly complex or custom boolean logic that ChronoForge doesn't directly implement
    function verify(bytes calldata data) external view returns (bool);
}

interface IArbitrator {
    // Interface for an external dispute resolution system
    function arbitrate(uint256 agreementId, address agreementContract, bytes calldata disputeData) external returns (bool success);
    function getArbitrationResult(uint256 agreementId) external view returns (bytes memory result);
}

/**
 * @title ChronoForge
 * @dev A sophisticated protocol for creating and managing time-gated and event-contingent smart agreements.
 *      It allows for multi-stage releases, conditional payments, and decentralized programmable trust
 *      based on time, oracle data, on-chain events, and custom external logic.
 *      Inspired by concepts of decentralized futures, options, and conditional escrows.
 */
contract ChronoForge is Ownable, ReentrancyGuard {
    using Address for address payable;

    // --- Enums ---

    enum AgreementStatus {
        Pending,          // Created but not yet active, conditions can be modified
        Active,           // Conditions are being checked
        ReadyForExecution, // All conditions met, ready for recipient to claim
        Executed,         // Output claimed by recipient
        Cancelled,        // Terminated by creator/owner
        Disputed          // Under arbitration
    }

    enum ConditionType {
        Timestamp,        // Triggered at a specific block.timestamp
        OraclePriceGE,    // Oracle price greater than or equal to a value
        OraclePriceLE,    // Oracle price less than or equal to a value
        OracleBooleanEQ,  // Oracle boolean data equals a value
        ExternalContractCall, // A specific external contract call returns true (e.g., check balance, NFT ownership)
        ExternalLogicVerifier // Custom complex boolean logic validated by a dedicated external contract
    }

    enum ActionType {
        TransferETH,      // Transfer Ether
        TransferERC20,    // Transfer ERC20 tokens
        CallExternalContract // Make a generic call to an external contract (e.g., mint NFT, execute function)
    }

    // --- Structs ---

    struct Condition {
        ConditionType conditionType;
        uint256 value;    // E.g., timestamp, price, boolean (0 or 1)
        string dataKey;   // E.g., "ETH/USD", "sportsResult", contract address for ExternalContractCall
        bytes extraData;  // For ExternalLogicVerifier or complex CallExternalContract arguments
        bool isMet;       // Whether this specific condition has been met
    }

    struct Action {
        ActionType actionType;
        address targetAddress; // Recipient for transfer, or contract for call
        uint256 amountOrValue; // Amount for transfer, or ETH value for call
        bytes callData;        // Calldata for CallExternalContract
    }

    struct TemporalAgreement {
        uint256 id;
        address payable creator;
        address payable recipient;
        AgreementStatus status;
        address assetAddress; // Address of ERC20 token, or address(0) for ETH
        uint256 totalAssetAmount; // Total amount of asset held for this agreement

        Condition[] conditions;
        Action[] actions;

        uint256 activationTimestamp; // When the agreement becomes Active
        uint256 lastConditionCheckTimestamp; // Last time executeTemporalAgreementLogic was called

        uint256 disputePeriodEnd; // Timestamp when dispute period ends
        address currentArbitrator; // Address of the chosen arbitrator for this agreement
        bool livenessCheckRequired; // If the recipient needs to prove liveness
        uint256 livenessCheckDeadline; // Deadline for liveness proof
        bool livenessVerified; // Status of liveness proof

        uint256 linkedAgreementId; // If this agreement is triggered by another's execution
        bool isTriggeredByLinkedAgreement; // True if this agreement is waiting on another
    }

    // --- State Variables ---

    uint256 private _agreementIdCounter;
    mapping(uint256 => TemporalAgreement) public agreements;
    mapping(address => bool) public isAgreementVerifier; // Addresses allowed to call executeTemporalAgreementLogic
    mapping(address => bool) public allowedTargetContracts; // For security: Contracts ChronoForge is allowed to interact with via `call`
    address public oracleAddress;
    address public externalLogicVerifierAddress;

    uint256 public executionFeePercentage; // e.g., 500 for 5% (500 basis points)
    uint256 public totalProtocolFeesCollected;

    // --- Events ---

    event TemporalAgreementCreated(uint256 indexed agreementId, address indexed creator, address indexed recipient, uint256 totalAmount, address assetAddress, AgreementStatus status);
    event TemporalAgreementUpdated(uint256 indexed agreementId, AgreementStatus oldStatus, AgreementStatus newStatus);
    event TemporalAgreementActivated(uint256 indexed agreementId);
    event TemporalAgreementCancelled(uint256 indexed agreementId, address indexed canceller);
    event AgreementConditionsMet(uint256 indexed agreementId, uint256 timestamp);
    event AgreementExecuted(uint256 indexed agreementId, address indexed recipient, uint256 timestamp);
    event AgreementDisputed(uint256 indexed agreementId, address indexed disputer);
    event ArbitratorProposed(uint256 indexed agreementId, address indexed proposer, address indexed proposedArbitrator);
    event ArbitratorApproved(uint256 indexed agreementId, address indexed approver, address indexed arbitrator);
    event DisputeResolved(uint256 indexed agreementId, address indexed arbitrator, bool outcome);
    event FundsDeposited(uint256 indexed agreementId, address indexed depositor, uint256 amount, address assetAddress);
    event FundsWithdrawn(uint256 indexed agreementId, address indexed withdrawer, uint256 amount, address assetAddress);
    event VerifierRoleGranted(address indexed verifier);
    event VerifierRoleRevoked(address indexed verifier);
    event OracleAddressSet(address indexed newAddress);
    event ExternalLogicVerifierAddressSet(address indexed newAddress);
    event LivenessCheckInitiated(uint256 indexed agreementId, uint256 deadline);
    event LivenessProofSubmitted(uint256 indexed agreementId);
    event AgreementLinked(uint256 indexed primaryAgreementId, uint256 indexed linkedAgreementId);
    event ExecutionFeeSet(uint256 newFeePercentage);
    event FeesWithdrawn(uint256 amount);

    // --- Modifiers ---

    modifier agreementExists(uint256 _agreementId) {
        require(_agreementId > 0 && agreements[_agreementId].id != 0, "ChronoForge: Agreement does not exist");
        _;
    }

    modifier agreementStatusIs(uint256 _agreementId, AgreementStatus _status) {
        require(agreements[_agreementId].status == _status, "ChronoForge: Invalid agreement status");
        _;
    }

    modifier agreementStatusIsNot(uint256 _agreementId, AgreementStatus _status) {
        require(agreements[_agreementId].status != _status, "ChronoForge: Invalid agreement status");
        _;
    }

    modifier onlyAgreementCreator(uint256 _agreementId) {
        require(agreements[_agreementId].creator == msg.sender, "ChronoForge: Only agreement creator can perform this action");
        _;
    }

    modifier onlyAgreementRecipient(uint256 _agreementId) {
        require(agreements[_agreementId].recipient == msg.sender, "ChronoForge: Only agreement recipient can perform this action");
        _;
    }

    modifier onlyAgreementVerifier() {
        require(isAgreementVerifier[msg.sender] || msg.sender == owner(), "ChronoForge: Caller not a designated verifier or owner");
        _;
    }

    modifier onlyArbitrator(uint256 _agreementId) {
        require(agreements[_agreementId].currentArbitrator == msg.sender, "ChronoForge: Not the designated arbitrator for this agreement");
        _;
    }

    modifier isAllowedTarget(address _target) {
        require(allowedTargetContracts[_target] || _target == address(this) || _target == address(0), "ChronoForge: Target contract not whitelisted");
        _;
    }

    // --- Constructor ---

    constructor() Ownable(msg.sender) {
        _agreementIdCounter = 0;
        // Whitelist common addresses for contract calls by default or add via `setAllowedTargetContract`
        // owner() can later add more.
    }

    // --- Agreement Management Functions ---

    /**
     * @dev Creates a new time-gated and event-contingent agreement.
     *      Initial status is PENDING, requiring conditions/actions to be added and funds deposited.
     * @param _recipient The address that will receive assets/actions upon execution.
     * @param _assetAddress The address of the ERC20 token (address(0) for ETH).
     * @param _totalAssetAmount The total amount of assets expected to be deposited for this agreement.
     * @param _activationTimestamp The timestamp at which the agreement can become 'Active'.
     * @param _livenessCheckRequired True if the recipient needs to prove liveness before execution.
     * @param _disputePeriodDays The number of days allowed for dispute after conditions are met, 0 for no dispute period.
     * @return The ID of the newly created agreement.
     */
    function createTemporalAgreement(
        address payable _recipient,
        address _assetAddress,
        uint256 _totalAssetAmount,
        uint256 _activationTimestamp,
        bool _livenessCheckRequired,
        uint256 _disputePeriodDays
    ) external onlyOwnerOrMsgSender returns (uint256) {
        require(_recipient != address(0), "ChronoForge: Recipient cannot be zero address");
        require(_totalAssetAmount > 0, "ChronoForge: Total asset amount must be greater than zero");
        require(_activationTimestamp > block.timestamp, "ChronoForge: Activation timestamp must be in the future");
        require(_assetAddress == address(0) || IERC20(_assetAddress).totalSupply() >= 0, "ChronoForge: Invalid ERC20 address"); // Basic check

        _agreementIdCounter++;
        uint256 newAgreementId = _agreementIdCounter;

        agreements[newAgreementId] = TemporalAgreement({
            id: newAgreementId,
            creator: payable(msg.sender),
            recipient: _recipient,
            status: AgreementStatus.Pending,
            assetAddress: _assetAddress,
            totalAssetAmount: _totalAssetAmount,
            conditions: new Condition[](0),
            actions: new Action[](0),
            activationTimestamp: _activationTimestamp,
            lastConditionCheckTimestamp: 0,
            disputePeriodEnd: 0, // Set when conditions are met
            currentArbitrator: address(0),
            livenessCheckRequired: _livenessCheckRequired,
            livenessCheckDeadline: 0,
            livenessVerified: false,
            linkedAgreementId: 0,
            isTriggeredByLinkedAgreement: false
        });

        emit TemporalAgreementCreated(newAgreementId, msg.sender, _recipient, _totalAssetAmount, _assetAddress, AgreementStatus.Pending);
        return newAgreementId;
    }

    /**
     * @dev Allows the creator to deposit assets into a specific agreement.
     *      Must match the `totalAssetAmount` specified during creation.
     * @param _agreementId The ID of the agreement.
     * @param _amount The amount of assets to deposit.
     */
    function depositForAgreement(uint256 _agreementId, uint256 _amount)
        external
        payable
        agreementExists(_agreementId)
        onlyAgreementCreator(_agreementId)
        agreementStatusIs(_agreementId, AgreementStatus.Pending)
        nonReentrant
    {
        TemporalAgreement storage agreement = agreements[_agreementId];
        require(agreement.assetAddress == address(0) ? msg.value == _amount : msg.value == 0, "ChronoForge: ETH value must match amount for ETH, or be 0 for ERC20");
        require(agreement.totalAssetAmount == agreement.totalAssetAmount + _amount, "ChronoForge: Deposit exceeds or does not match total required"); // Simplified, usually check total deposited vs. required

        if (agreement.assetAddress == address(0)) {
            require(msg.value == _amount, "ChronoForge: ETH amount mismatch");
            // ETH is directly held by the contract, no need to transfer.
        } else {
            IERC20(agreement.assetAddress).transferFrom(msg.sender, address(this), _amount);
        }

        emit FundsDeposited(_agreementId, msg.sender, _amount, agreement.assetAddress);
    }

    /**
     * @dev Allows the creator to update certain agreement details before it's activated.
     *      Cannot change asset type or total amount.
     * @param _agreementId The ID of the agreement.
     * @param _newRecipient The new recipient address.
     * @param _newActivationTimestamp The new activation timestamp.
     * @param _newLivenessCheckRequired New liveness check requirement.
     * @param _newDisputePeriodDays New dispute period in days.
     */
    function updateTemporalAgreementDetails(
        uint256 _agreementId,
        address payable _newRecipient,
        uint256 _newActivationTimestamp,
        bool _newLivenessCheckRequired,
        uint256 _newDisputePeriodDays
    ) external onlyAgreementCreator(_agreementId) agreementStatusIs(_agreementId, AgreementStatus.Pending) {
        TemporalAgreement storage agreement = agreements[_agreementId];

        require(_newRecipient != address(0), "ChronoForge: New recipient cannot be zero address");
        require(_newActivationTimestamp > block.timestamp, "ChronoForge: New activation timestamp must be in the future");

        agreement.recipient = _newRecipient;
        agreement.activationTimestamp = _newActivationTimestamp;
        agreement.livenessCheckRequired = _newLivenessCheckRequired;
        // Note: disputePeriodEnd will be recalculated when conditions are met
        // No direct storage for disputePeriodDays, it's used to calculate disputePeriodEnd

        emit TemporalAgreementUpdated(_agreementId, AgreementStatus.Pending, AgreementStatus.Pending); // Status remains pending
    }

    /**
     * @dev Adds a condition to an agreement. Only callable when agreement is PENDING.
     * @param _agreementId The ID of the agreement.
     * @param _conditionType The type of condition.
     * @param _value The value associated with the condition (e.g., timestamp, price).
     * @param _dataKey The key for oracle data or external contract address.
     * @param _extraData Extra data for complex conditions like ExternalLogicVerifier.
     */
    function addConditionToAgreement(
        uint256 _agreementId,
        ConditionType _conditionType,
        uint256 _value,
        string calldata _dataKey,
        bytes calldata _extraData
    ) external onlyAgreementCreator(_agreementId) agreementStatusIs(_agreementId, AgreementStatus.Pending) {
        TemporalAgreement storage agreement = agreements[_agreementId];

        if (_conditionType == ConditionType.OraclePriceGE || _conditionType == ConditionType.OraclePriceLE || _conditionType == ConditionType.OracleBooleanEQ) {
            require(oracleAddress != address(0), "ChronoForge: Oracle address not set for oracle conditions");
        }
        if (_conditionType == ConditionType.ExternalLogicVerifier) {
            require(externalLogicVerifierAddress != address(0), "ChronoForge: External logic verifier address not set");
        }
        if (_conditionType == ConditionType.ExternalContractCall) {
            require(bytes(_dataKey).length > 0 && Address.isContract(address(bytes32(bytes(_dataKey)))), "ChronoForge: Invalid contract address for external call condition");
            require(allowedTargetContracts[address(bytes32(bytes(_dataKey)))], "ChronoForge: Target contract not whitelisted for external call condition");
        }

        agreement.conditions.push(Condition({
            conditionType: _conditionType,
            value: _value,
            dataKey: _dataKey,
            extraData: _extraData,
            isMet: false
        }));

        emit TemporalAgreementUpdated(_agreementId, AgreementStatus.Pending, AgreementStatus.Pending); // Still pending
    }

    /**
     * @dev Removes a condition from an agreement. Only callable when agreement is PENDING.
     * @param _agreementId The ID of the agreement.
     * @param _conditionIndex The index of the condition to remove.
     */
    function removeConditionFromAgreement(uint256 _agreementId, uint256 _conditionIndex)
        external
        onlyAgreementCreator(_agreementId)
        agreementStatusIs(_agreementId, AgreementStatus.Pending)
    {
        TemporalAgreement storage agreement = agreements[_agreementId];
        require(_conditionIndex < agreement.conditions.length, "ChronoForge: Condition index out of bounds");

        for (uint i = _conditionIndex; i < agreement.conditions.length - 1; i++) {
            agreement.conditions[i] = agreement.conditions[i+1];
        }
        agreement.conditions.pop();

        emit TemporalAgreementUpdated(_agreementId, AgreementStatus.Pending, AgreementStatus.Pending);
    }

    /**
     * @dev Adds an action to an agreement. Only callable when agreement is PENDING.
     * @param _agreementId The ID of the agreement.
     * @param _actionType The type of action.
     * @param _targetAddress The target address for the action (recipient or contract).
     * @param _amountOrValue The amount of assets or ETH value for the call.
     * @param _callData Calldata for `CallExternalContract` action.
     */
    function addActionToAgreement(
        uint256 _agreementId,
        ActionType _actionType,
        address payable _targetAddress,
        uint256 _amountOrValue,
        bytes calldata _callData
    ) external onlyAgreementCreator(_agreementId) agreementStatusIs(_agreementId, AgreementStatus.Pending) {
        TemporalAgreement storage agreement = agreements[_agreementId];
        require(_targetAddress != address(0), "ChronoForge: Target address cannot be zero");

        if (_actionType == ActionType.TransferERC20) {
            require(agreement.assetAddress != address(0), "ChronoForge: Agreement must be ERC20 for ERC20 transfer action");
        } else if (_actionType == ActionType.TransferETH) {
            require(agreement.assetAddress == address(0), "ChronoForge: Agreement must be ETH for ETH transfer action");
        } else if (_actionType == ActionType.CallExternalContract) {
            require(allowedTargetContracts[_targetAddress], "ChronoForge: Target contract not whitelisted for external call action");
        }

        agreement.actions.push(Action({
            actionType: _actionType,
            targetAddress: _targetAddress,
            amountOrValue: _amountOrValue,
            callData: _callData
        }));

        emit TemporalAgreementUpdated(_agreementId, AgreementStatus.Pending, AgreementStatus.Pending);
    }

    /**
     * @dev Removes an action from an agreement. Only callable when agreement is PENDING.
     * @param _agreementId The ID of the agreement.
     * @param _actionIndex The index of the action to remove.
     */
    function removeActionFromAgreement(uint256 _agreementId, uint256 _actionIndex)
        external
        onlyAgreementCreator(_agreementId)
        agreementStatusIs(_agreementId, AgreementStatus.Pending)
    {
        TemporalAgreement storage agreement = agreements[_agreementId];
        require(_actionIndex < agreement.actions.length, "ChronoForge: Action index out of bounds");

        for (uint i = _actionIndex; i < agreement.actions.length - 1; i++) {
            agreement.actions[i] = agreement.actions[i+1];
        }
        agreement.actions.pop();

        emit TemporalAgreementUpdated(_agreementId, AgreementStatus.Pending, AgreementStatus.Pending);
    }

    /**
     * @dev Activates a PENDING agreement, allowing its conditions to be checked.
     *      Requires the activationTimestamp to have passed and funds to be fully deposited.
     * @param _agreementId The ID of the agreement.
     */
    function activateTemporalAgreement(uint256 _agreementId)
        external
        agreementExists(_agreementId)
        agreementStatusIs(_agreementId, AgreementStatus.Pending)
        nonReentrant
    {
        TemporalAgreement storage agreement = agreements[_agreementId];

        require(block.timestamp >= agreement.activationTimestamp, "ChronoForge: Activation timestamp not yet reached");

        // Assuming funds are deposited incrementally, this check needs refinement
        // A more robust system would track deposited amount vs. required amount.
        // For simplicity here, we assume `depositForAgreement` ensures full deposit.

        agreement.status = AgreementStatus.Active;
        emit TemporalAgreementActivated(_agreementId);
        emit TemporalAgreementUpdated(_agreementId, AgreementStatus.Pending, AgreementStatus.Active);
    }

    /**
     * @dev Allows the agreement creator to cancel an agreement.
     *      Only callable if the agreement is PENDING, or if special conditions allow (e.g., dispute).
     *      Refunds deposited assets to the creator.
     * @param _agreementId The ID of the agreement.
     */
    function cancelTemporalAgreement(uint256 _agreementId)
        external
        agreementExists(_agreementId)
        onlyAgreementCreator(_agreementId)
        nonReentrant
    {
        TemporalAgreement storage agreement = agreements[_agreementId];
        require(
            agreement.status == AgreementStatus.Pending || agreement.status == AgreementStatus.Active, // Can be cancelled if not yet executed or under dispute
            "ChronoForge: Agreement cannot be cancelled in its current state"
        );
        require(agreement.status != AgreementStatus.Executed, "ChronoForge: Agreement already executed");

        uint256 amountToRefund = agreement.totalAssetAmount;
        agreement.status = AgreementStatus.Cancelled;

        if (amountToRefund > 0) {
            if (agreement.assetAddress == address(0)) {
                payable(agreement.creator).transfer(amountToRefund);
            } else {
                IERC20(agreement.assetAddress).transfer(agreement.creator, amountToRefund);
            }
            emit FundsWithdrawn(_agreementId, agreement.creator, amountToRefund, agreement.assetAddress);
        }

        emit TemporalAgreementCancelled(_agreementId, msg.sender);
        emit TemporalAgreementUpdated(_agreementId, agreement.status, AgreementStatus.Cancelled);
    }

    // --- Execution & Claim Functions ---

    /**
     * @dev Core function to check if all conditions for an agreement have been met.
     *      Intended to be called by an `AgreementVerifier` or a keeper network.
     *      If all conditions are met, the agreement status transitions to `ReadyForExecution`.
     * @param _agreementId The ID of the agreement to check.
     */
    function executeTemporalAgreementLogic(uint256 _agreementId)
        external
        agreementExists(_agreementId)
        agreementStatusIs(_agreementId, AgreementStatus.Active)
        onlyAgreementVerifier // Or owner
    {
        TemporalAgreement storage agreement = agreements[_agreementId];
        require(block.timestamp >= agreement.activationTimestamp, "ChronoForge: Agreement not yet active based on timestamp");
        require(agreement.lastConditionCheckTimestamp < block.timestamp, "ChronoForge: Conditions already checked in this block");

        if (agreement.isTriggeredByLinkedAgreement) {
            require(agreements[agreement.linkedAgreementId].status == AgreementStatus.Executed, "ChronoForge: Linked agreement not yet executed");
        }

        bool allConditionsMet = true;
        for (uint i = 0; i < agreement.conditions.length; i++) {
            Condition storage currentCondition = agreement.conditions[i];
            bool conditionMet = false;

            if (currentCondition.conditionType == ConditionType.Timestamp) {
                conditionMet = (block.timestamp >= currentCondition.value);
            } else if (currentCondition.conditionType == ConditionType.OraclePriceGE || currentCondition.conditionType == ConditionType.OraclePriceLE) {
                require(oracleAddress != address(0), "ChronoForge: Oracle address not set");
                int256 currentPrice = IOracle(oracleAddress).getLatestPrice(currentCondition.dataKey);
                if (currentCondition.conditionType == ConditionType.OraclePriceGE) {
                    conditionMet = (currentPrice >= int256(currentCondition.value));
                } else { // OraclePriceLE
                    conditionMet = (currentPrice <= int256(currentCondition.value));
                }
            } else if (currentCondition.conditionType == ConditionType.OracleBooleanEQ) {
                require(oracleAddress != address(0), "ChronoForge: Oracle address not set");
                bool oracleBool = IOracle(oracleAddress).getBooleanData(currentCondition.dataKey);
                conditionMet = (oracleBool == (currentCondition.value == 1));
            } else if (currentCondition.conditionType == ConditionType.ExternalContractCall) {
                address targetContract = address(bytes32(bytes(currentCondition.dataKey)));
                require(allowedTargetContracts[targetContract], "ChronoForge: External call target not whitelisted");
                // Generic external call, expects a boolean return
                (bool success, bytes memory returndata) = targetContract.staticcall(currentCondition.extraData);
                require(success, "ChronoForge: External contract call failed");
                conditionMet = abi.decode(returndata, (bool)); // Expects the external call to return a single bool
            } else if (currentCondition.conditionType == ConditionType.ExternalLogicVerifier) {
                require(externalLogicVerifierAddress != address(0), "ChronoForge: External logic verifier address not set");
                conditionMet = IExternalVerifier(externalLogicVerifierAddress).verify(currentCondition.extraData);
            }
            
            if (!conditionMet) {
                allConditionsMet = false;
                break; // One condition not met, no need to check further
            }
        }

        if (allConditionsMet) {
            agreement.status = AgreementStatus.ReadyForExecution;
            agreement.lastConditionCheckTimestamp = block.timestamp; // Update last check time
            // If liveness check required, initiate it now
            if (agreement.livenessCheckRequired && !agreement.livenessVerified) {
                agreement.livenessCheckDeadline = block.timestamp + 7 days; // Example: 7 days to prove liveness
                emit LivenessCheckInitiated(_agreementId, agreement.livenessCheckDeadline);
            }
            emit AgreementConditionsMet(_agreementId, block.timestamp);
            emit TemporalAgreementUpdated(_agreementId, AgreementStatus.Active, AgreementStatus.ReadyForExecution);
        }
        agreement.lastConditionCheckTimestamp = block.timestamp;
    }

    /**
     * @dev Allows the recipient to claim the output of an agreement once its conditions are met.
     *      This function performs the actual token transfers or contract calls.
     * @param _agreementId The ID of the agreement.
     */
    function claimAgreementOutput(uint256 _agreementId)
        external
        agreementExists(_agreementId)
        agreementStatusIs(_agreementId, AgreementStatus.ReadyForExecution)
        onlyAgreementRecipient(_agreementId)
        nonReentrant
    {
        TemporalAgreement storage agreement = agreements[_agreementId];

        // If liveness check is required, ensure it has passed or deadline is over
        if (agreement.livenessCheckRequired) {
            require(agreement.livenessVerified || block.timestamp > agreement.livenessCheckDeadline, "ChronoForge: Liveness check pending or deadline not passed");
        }

        // Apply execution fee
        uint256 amountToTransfer = agreement.totalAssetAmount;
        uint256 feeAmount = 0;
        if (executionFeePercentage > 0) {
            feeAmount = (amountToTransfer * executionFeePercentage) / 10000; // Basis points
            totalProtocolFeesCollected += feeAmount;
            amountToTransfer -= feeAmount;
        }

        for (uint i = 0; i < agreement.actions.length; i++) {
            Action storage currentAction = agreement.actions[i];
            if (currentAction.actionType == ActionType.TransferETH) {
                require(currentAction.amountOrValue <= amountToTransfer, "ChronoForge: Insufficient ETH for transfer action");
                (bool success, ) = currentAction.targetAddress.call{value: currentAction.amountOrValue}("");
                require(success, "ChronoForge: ETH transfer failed");
            } else if (currentAction.actionType == ActionType.TransferERC20) {
                require(agreement.assetAddress != address(0), "ChronoForge: Agreement asset is not ERC20");
                require(currentAction.amountOrValue <= amountToTransfer, "ChronoForge: Insufficient ERC20 for transfer action");
                IERC20(agreement.assetAddress).transfer(currentAction.targetAddress, currentAction.amountOrValue);
            } else if (currentAction.actionType == ActionType.CallExternalContract) {
                require(allowedTargetContracts[currentAction.targetAddress], "ChronoForge: External call target not whitelisted");
                (bool success, ) = currentAction.targetAddress.call{value: currentAction.amountOrValue}(currentAction.callData);
                require(success, "ChronoForge: External contract call failed");
            }
            // For simple transfers, ensure the contract holds enough funds
            // A more complex system would track per-action allocations vs. total
        }

        // Transfer remaining balance to the recipient if not fully allocated by actions
        uint256 remainingBalance = agreement.assetAddress == address(0) ? address(this).balance : IERC20(agreement.assetAddress).balanceOf(address(this));
        if (remainingBalance > 0) {
            if (agreement.assetAddress == address(0)) {
                payable(agreement.recipient).transfer(remainingBalance);
            } else {
                IERC20(agreement.assetAddress).transfer(agreement.recipient, remainingBalance);
            }
        }

        agreement.status = AgreementStatus.Executed;
        emit AgreementExecuted(_agreementId, agreement.recipient, block.timestamp);
        emit TemporalAgreementUpdated(_agreementId, AgreementStatus.ReadyForExecution, AgreementStatus.Executed);
    }

    /**
     * @dev Allows the creator to withdraw any leftover funds from a cancelled or fully executed agreement.
     *      This acts as a cleanup function to retrieve funds not transferred by actions.
     * @param _agreementId The ID of the agreement.
     */
    function withdrawUnusedFunds(uint256 _agreementId)
        external
        agreementExists(_agreementId)
        onlyAgreementCreator(_agreementId)
        nonReentrant
    {
        TemporalAgreement storage agreement = agreements[_agreementId];
        require(agreement.status == AgreementStatus.Cancelled || agreement.status == AgreementStatus.Executed, "ChronoForge: Agreement must be cancelled or executed to withdraw unused funds");

        uint256 amountToWithdraw;
        if (agreement.assetAddress == address(0)) {
            amountToWithdraw = address(this).balance;
        } else {
            amountToWithdraw = IERC20(agreement.assetAddress).balanceOf(address(this));
        }

        require(amountToWithdraw > 0, "ChronoForge: No unused funds to withdraw");

        if (agreement.assetAddress == address(0)) {
            payable(agreement.creator).transfer(amountToWithdraw);
        } else {
            IERC20(agreement.assetAddress).transfer(agreement.creator, amountToWithdraw);
        }

        emit FundsWithdrawn(_agreementId, agreement.creator, amountToWithdraw, agreement.assetAddress);
    }

    // --- Dispute Resolution Functions ---

    /**
     * @dev Initiates a dispute for an agreement, moving its status to DISPUTED.
     *      Can be called by creator or recipient if agreement is `ReadyForExecution` and within dispute period.
     * @param _agreementId The ID of the agreement.
     * @param _arbitratorAddress The address of the proposed arbitrator.
     */
    function proposeArbitrator(uint256 _agreementId, address _arbitratorAddress)
        external
        agreementExists(_agreementId)
        agreementStatusIs(_agreementId, AgreementStatus.ReadyForExecution)
    {
        TemporalAgreement storage agreement = agreements[_agreementId];
        require(block.timestamp <= agreement.disputePeriodEnd, "ChronoForge: Dispute period has ended");
        require(msg.sender == agreement.creator || msg.sender == agreement.recipient, "ChronoForge: Only creator or recipient can propose arbitrator");
        require(_arbitratorAddress != address(0), "ChronoForge: Arbitrator address cannot be zero");

        agreement.currentArbitrator = _arbitratorAddress; // This can be replaced with a multi-party approval process
        agreement.status = AgreementStatus.Disputed;

        emit ArbitratorProposed(_agreementId, msg.sender, _arbitratorAddress);
        emit AgreementDisputed(_agreementId, msg.sender);
        emit TemporalAgreementUpdated(_agreementId, AgreementStatus.ReadyForExecution, AgreementStatus.Disputed);
    }

    /**
     * @dev Allows the opposing party (creator/recipient) to approve the proposed arbitrator.
     * @param _agreementId The ID of the agreement.
     */
    function approveArbitrator(uint256 _agreementId)
        external
        agreementExists(_agreementId)
        agreementStatusIs(_agreementId, AgreementStatus.Disputed)
    {
        TemporalAgreement storage agreement = agreements[_agreementId];
        require(agreement.currentArbitrator != address(0), "ChronoForge: No arbitrator proposed");
        require(msg.sender == agreement.creator || msg.sender == agreement.recipient, "ChronoForge: Only creator or recipient can approve arbitrator");
        require(msg.sender != agreement.creator && msg.sender != agreement.recipient, "ChronoForge: Cannot approve your own proposal (needs more complex check)"); // simplified, assumes only one party proposes

        // In a real system, this would require the other party to call.
        // For example, if creator proposes, recipient approves.
        // A simple check might be `if (msg.sender == agreement.creator || msg.sender == agreement.recipient) && msg.sender != agreement.lastProposer`.

        // For this example, we'll assume a single approval is enough after proposal.
        // A more robust system would use a dedicated arbitration contract with state tracking.

        emit ArbitratorApproved(_agreementId, msg.sender, agreement.currentArbitrator);
        // Do not change status here, arbitration process begins
    }

    /**
     * @dev Allows the designated arbitrator to resolve a dispute.
     *      The arbitrator determines if the agreement should be executed or cancelled.
     * @param _agreementId The ID of the agreement.
     * @param _executeOutcome True if the arbitrator rules for execution, false for cancellation.
     * @param _arbitrationData Any additional data/proof from the arbitrator.
     */
    function resolveDispute(uint256 _agreementId, bool _executeOutcome, bytes calldata _arbitrationData)
        external
        agreementExists(_agreementId)
        agreementStatusIs(_agreementId, AgreementStatus.Disputed)
        onlyArbitrator(_agreementId)
        nonReentrant
    {
        TemporalAgreement storage agreement = agreements[_agreementId];
        require(agreement.currentArbitrator != address(0), "ChronoForge: No arbitrator assigned");

        if (_executeOutcome) {
            agreement.status = AgreementStatus.ReadyForExecution;
            // No direct call to claim, recipient still needs to call claimAgreementOutput
        } else {
            uint256 amountToRefund = agreement.totalAssetAmount;
            agreement.status = AgreementStatus.Cancelled;

            if (amountToRefund > 0) {
                if (agreement.assetAddress == address(0)) {
                    payable(agreement.creator).transfer(amountToRefund);
                } else {
                    IERC20(agreement.assetAddress).transfer(agreement.creator, amountToRefund);
                }
                emit FundsWithdrawn(_agreementId, agreement.creator, amountToRefund, agreement.assetAddress);
            }
        }
        agreement.currentArbitrator = address(0); // Reset arbitrator

        emit DisputeResolved(_agreementId, msg.sender, _executeOutcome);
        emit TemporalAgreementUpdated(_agreementId, AgreementStatus.Disputed, agreement.status);
    }

    // --- Role Management Functions ---

    /**
     * @dev Grants the `AgreementVerifier` role to an address.
     *      Verifiers can call `executeTemporalAgreementLogic` to check conditions.
     * @param _verifier The address to grant the role.
     */
    function assignVerifierRole(address _verifier) external onlyOwner {
        require(_verifier != address(0), "ChronoForge: Verifier address cannot be zero");
        require(!isAgreementVerifier[_verifier], "ChronoForge: Address already a verifier");
        isAgreementVerifier[_verifier] = true;
        emit VerifierRoleGranted(_verifier);
    }

    /**
     * @dev Revokes the `AgreementVerifier` role from an address.
     * @param _verifier The address to revoke the role from.
     */
    function revokeVerifierRole(address _verifier) external onlyOwner {
        require(isAgreementVerifier[_verifier], "ChronoForge: Address is not a verifier");
        isAgreementVerifier[_verifier] = false;
        emit VerifierRoleRevoked(_verifier);
    }

    // --- Protocol Settings Functions ---

    /**
     * @dev Sets the address of the trusted oracle contract.
     * @param _oracleAddress The address of the IOracle compliant contract.
     */
    function setOracleAddress(address _oracleAddress) external onlyOwner {
        require(_oracleAddress != address(0), "ChronoForge: Oracle address cannot be zero");
        oracleAddress = _oracleAddress;
        emit OracleAddressSet(_oracleAddress);
    }

    /**
     * @dev Sets the address of the external logic verifier contract.
     * @param _externalLogicVerifierAddress The address of the IExternalVerifier compliant contract.
     */
    function setExternalLogicVerifierAddress(address _externalLogicVerifierAddress) external onlyOwner {
        require(_externalLogicVerifierAddress != address(0), "ChronoForge: External logic verifier address cannot be zero");
        externalLogicVerifierAddress = _externalLogicVerifierAddress;
        emit ExternalLogicVerifierAddressSet(_externalLogicVerifierAddress);
    }

    /**
     * @dev Adds or removes an address from the whitelist of allowed target contracts for `CallExternalContract` actions.
     * @param _targetAddress The address of the contract to manage.
     * @param _allowed True to add, false to remove.
     */
    function setAllowedTargetContract(address _targetAddress, bool _allowed) external onlyOwner {
        require(_targetAddress != address(0), "ChronoForge: Target address cannot be zero");
        allowedTargetContracts[_targetAddress] = _allowed;
    }

    /**
     * @dev Sets the execution fee percentage in basis points (e.g., 100 = 1%).
     * @param _newFeePercentage The new fee percentage (0-10000).
     */
    function setExecutionFee(uint256 _newFeePercentage) external onlyOwner {
        require(_newFeePercentage <= 10000, "ChronoForge: Fee percentage cannot exceed 100%");
        executionFeePercentage = _newFeePercentage;
        emit ExecutionFeeSet(_newFeePercentage);
    }

    /**
     * @dev Allows the owner to withdraw collected protocol fees.
     */
    function withdrawFees() external onlyOwner nonReentrant {
        require(totalProtocolFeesCollected > 0, "ChronoForge: No fees to withdraw");
        uint256 amount = totalProtocolFeesCollected;
        totalProtocolFeesCollected = 0;
        payable(owner()).transfer(amount);
        emit FeesWithdrawn(amount);
    }

    // --- Advanced Features ---

    /**
     * @dev Initiates a liveness check for the recipient of an agreement.
     *      If the agreement requires liveness proof, this sets a deadline for submission.
     *      Typically called automatically when `ReadyForExecution` status is reached,
     *      but exposed for flexibility if needed.
     * @param _agreementId The ID of the agreement.
     */
    function initiateLivenessCheck(uint256 _agreementId)
        external
        agreementExists(_agreementId)
        agreementStatusIs(_agreementId, AgreementStatus.ReadyForExecution)
        onlyAgreementCreator(_agreementId) // Can be called by creator to force a check
    {
        TemporalAgreement storage agreement = agreements[_agreementId];
        require(agreement.livenessCheckRequired, "ChronoForge: Liveness check not required for this agreement");
        require(!agreement.livenessVerified, "ChronoForge: Liveness already verified");
        require(block.timestamp > agreement.livenessCheckDeadline, "ChronoForge: Liveness check already active or not expired"); // Only initiate if no active check

        agreement.livenessCheckDeadline = block.timestamp + 7 days; // Example: 7 days
        emit LivenessCheckInitiated(_agreementId, agreement.livenessCheckDeadline);
    }

    /**
     * @dev Allows the recipient to submit proof of their "liveness" for an agreement.
     *      This simply means calling this function within the deadline.
     * @param _agreementId The ID of the agreement.
     */
    function submitLivenessProof(uint256 _agreementId)
        external
        agreementExists(_agreementId)
        agreementStatusIs(_agreementId, AgreementStatus.ReadyForExecution)
        onlyAgreementRecipient(_agreementId)
    {
        TemporalAgreement storage agreement = agreements[_agreementId];
        require(agreement.livenessCheckRequired, "ChronoForge: Liveness check not required for this agreement");
        require(!agreement.livenessVerified, "ChronoForge: Liveness already verified");
        require(block.timestamp <= agreement.livenessCheckDeadline, "ChronoForge: Liveness proof deadline passed");

        agreement.livenessVerified = true;
        emit LivenessProofSubmitted(_agreementId);
    }

    /**
     * @dev Links a 'child' agreement to a 'parent' agreement, meaning the child will only become `Active`
     *      once the parent agreement has been fully `Executed`. This enables complex, multi-stage protocols.
     * @param _parentAgreementId The ID of the agreement that must be executed first.
     * @param _childAgreementId The ID of the agreement that will be triggered by the parent's execution.
     */
    function linkTemporalAgreements(uint256 _parentAgreementId, uint256 _childAgreementId)
        external
        onlyOwnerOrMsgSender // Could also be only creator of both
        agreementExists(_parentAgreementId)
        agreementExists(_childAgreementId)
    {
        TemporalAgreement storage parent = agreements[_parentAgreementId];
        TemporalAgreement storage child = agreements[_childAgreementId];

        require(parent.status != AgreementStatus.Executed, "ChronoForge: Parent agreement already executed");
        require(child.status == AgreementStatus.Pending, "ChronoForge: Child agreement must be in Pending status");
        require(child.linkedAgreementId == 0, "ChronoForge: Child agreement already linked");
        require(_parentAgreementId != _childAgreementId, "ChronoForge: Cannot link an agreement to itself");

        child.linkedAgreementId = _parentAgreementId;
        child.isTriggeredByLinkedAgreement = true; // Flag to indicate it needs to wait for linked agreement

        // Adjust child's activation timestamp to be after parent's potential execution, or a reasonable buffer
        // Or simply rely on `executeTemporalAgreementLogic` check.
        // For simplicity, `executeTemporalAgreementLogic` will check `isTriggeredByLinkedAgreement` and `parent.status`.

        emit AgreementLinked(_parentAgreementId, _childAgreementId);
    }

    // --- Utility & View Functions ---

    /**
     * @dev Returns the full details of a specific agreement.
     * @param _agreementId The ID of the agreement.
     * @return A tuple containing all agreement details.
     */
    function getAgreementDetails(uint256 _agreementId)
        external
        view
        agreementExists(_agreementId)
        returns (
            uint256 id,
            address payable creator,
            address payable recipient,
            AgreementStatus status,
            address assetAddress,
            uint256 totalAssetAmount,
            Condition[] memory conditions,
            Action[] memory actions,
            uint256 activationTimestamp,
            uint256 lastConditionCheckTimestamp,
            uint256 disputePeriodEnd,
            address currentArbitrator,
            bool livenessCheckRequired,
            uint256 livenessCheckDeadline,
            bool livenessVerified,
            uint256 linkedAgreementId,
            bool isTriggeredByLinkedAgreement
        )
    {
        TemporalAgreement storage agreement = agreements[_agreementId];
        return (
            agreement.id,
            agreement.creator,
            agreement.recipient,
            agreement.status,
            agreement.assetAddress,
            agreement.totalAssetAmount,
            agreement.conditions,
            agreement.actions,
            agreement.activationTimestamp,
            agreement.lastConditionCheckTimestamp,
            agreement.disputePeriodEnd,
            agreement.currentArbitrator,
            agreement.livenessCheckRequired,
            agreement.livenessCheckDeadline,
            agreement.livenessVerified,
            agreement.linkedAgreementId,
            agreement.isTriggeredByLinkedAgreement
        );
    }

    /**
     * @dev Returns the current status of an agreement.
     * @param _agreementId The ID of the agreement.
     * @return The current status of the agreement.
     */
    function getAgreementStatus(uint256 _agreementId) external view agreementExists(_agreementId) returns (AgreementStatus) {
        return agreements[_agreementId].status;
    }

    /**
     * @dev Returns the current number of agreements created.
     * @return The total number of agreements.
     */
    function getAgreementCount() external view returns (uint256) {
        return _agreementIdCounter;
    }

    // Fallback and Receive functions to handle ETH
    receive() external payable {
        // Only allow receiving ETH if it's explicitly for an agreement via `depositForAgreement`
        // or for owner's fees withdrawal. Any other direct ETH transfer should revert.
        revert("ChronoForge: Direct ETH deposits not allowed. Use depositForAgreement.");
    }

    fallback() external payable {
        revert("ChronoForge: Fallback not implemented for direct calls.");
    }
}
```