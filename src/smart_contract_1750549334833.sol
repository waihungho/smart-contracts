Okay, here is a Solidity smart contract concept combining elements of soulbound identity, conditional vaults, multi-guardian recovery, and a basic reputation system tied to held assets. It aims for complexity and a unique use case beyond standard templates.

**Concept:** **CryptoSoulBoundVault**

A vault contract where ownership is 'soulbound' to the initial creator's address, meaning it cannot be simply transferred or sold. Assets held within the vault are subject to complex withdrawal conditions (time locks, event triggers) and can only be released to the soulbound owner or a designated successor via a multi-guardian approved process. The vault also tracks a basic reputation score derived from the assets it holds.

**Key Features:**

1.  **Soulbound Ownership:** Standard `transferOwnership` is disabled. Ownership can only change through specific, guardian-approved recovery or succession flows.
2.  **Conditional Withdrawals:** Assets (ERC20, ERC721, ERC1155) can be requested for withdrawal, but require fulfilling one or more predefined conditions (e.g., time elapsed, external event confirmed by an oracle).
3.  **Multi-Guardian Recovery:** A system where designated guardians can collectively initiate and approve a process to recover access for the soulbound owner (e.g., if keys are lost) or potentially transfer ownership/assets to a predefined recovery address.
4.  **Succession Planning:** The soulbound owner can designate a successor. Guardians can approve this successor, allowing them to claim ownership or specific assets under predefined conditions (e.g., owner inactivity, confirmed "death" event).
5.  **Asset-Based Reputation:** A simple, internal mechanism to track a reputation score for the vault owner, influenced by the types and quantity of specific assets held within the vault. This score can potentially be used by external protocols or for internal vault logic.
6.  **Oracle Integration Placeholder:** Includes a mechanism for event-based conditions that would typically rely on an external oracle or trusted third party to signal completion.

**Outline and Function Summary**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Imports (Standard, NOT Duplicated Core Logic) ---
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Used as a base, but modified heavily

// --- Outline ---
// 1. Imports
// 2. Error Definitions
// 3. Enums & Structs
//    - WithdrawalRequest (Details of an asset withdrawal request)
//    - WithdrawalCondition (Details of a single condition for withdrawal)
//    - ConditionType (Enum for time lock, event trigger)
//    - ConditionStatus (Enum for pending, fulfilled, failed)
//    - RecoveryState (Enum for recovery process stages)
//    - SuccessionState (Enum for succession process stages)
// 4. Events
//    - Lifecycle Events (Deployment, Ownership changes via recovery/succession)
//    - Asset Management Events (Deposit, Withdrawal Requested, Withdrawal Executed)
//    - Condition Events (Condition Added, Condition Fulfilled)
//    - Guardian Events (Guardian Added/Removed, Threshold Updated)
//    - Recovery Events (Recovery Initiated, Guardian Approved, Recovery Completed)
//    - Succession Events (Successor Proposed, Guardian Approved, Succession Claimed)
//    - Reputation Events (Reputation Score Updated)
// 5. Contract Definition: CryptoSoulBoundVault inheriting Ownable, ERC1155Holder
// 6. State Variables
//    - Owner (Inherited from Ownable, but modified behavior)
//    - Guardians mapping and array
//    - Guardian approval threshold
//    - Withdrawal requests mapping
//    - Conditions mapping (mapping request ID to condition details)
//    - Condition statuses mapping
//    - Oracle/Event Signaler address
//    - Recovery state variables
//    - Succession state variables
//    - Reputation score and calculation parameters
//    - Mappings to track deposited assets (for balance checks and reputation)
// 7. Constructor
// 8. Ownable Overrides (Disable standard transfer/renounce)
// 9. Modifiers (onlyOwner, onlyGuardian, onlyOracle, etc.)
// 10. Core Vault Management Functions
//    - Deposit (ERC20, ERC721, ERC1155)
//    - Withdrawal Request (ERC20, ERC721, ERC1155)
//    - Cancel Withdrawal Request
//    - Execute Withdrawal (ERC20, ERC721, ERC1155)
//    - Check Withdrawal Eligibility
// 11. Conditional Logic Functions
//    - Add Time Lock Condition
//    - Add Event Condition
//    - Fulfill Event Condition (by Oracle)
//    - Get Condition Status
// 12. Guardian Management Functions
//    - Add Guardian
//    - Remove Guardian
//    - Set Guardian Approval Threshold
//    - Get Guardians
//    - Get Guardian Threshold
// 13. Recovery Functions
//    - Initiate Recovery (by Guardian)
//    - Guardian Approve Recovery
//    - Complete Recovery (to a designated recovery address)
//    - Get Recovery Status
// 14. Succession Functions
//    - Propose Successor (by Owner)
//    - Guardian Approve Successor
//    - Claim Ownership via Succession (by proposed successor)
//    - Get Successor Proposal Status
// 15. Reputation System Functions
//    - Set Reputation Manager (address authorized to update score)
//    - Update Reputation Score (by Manager)
//    - Get Reputation Score
//    - Calculate Reputation Score (Internal/View based on holdings)
// 16. View Functions (Get balances, request details, state info)
//    - Get Vault Balance (ERC20, ERC721, ERC1155)
//    - Get Total Unique Asset Count
//    - Get Withdrawal Request Details
//    - Get Oracle Address
// 17. ERC1155Holder Required Function
//    - onERC1155Received

// --- Function Summary ---

// --- Core Vault Management ---
// depositERC20(address token, uint256 amount): Deposit ERC20 tokens into the vault.
// depositERC721(address token, uint256 tokenId): Deposit an ERC721 token into the vault.
// depositERC1155(address token, uint256 id, uint256 amount): Deposit ERC1155 tokens into the vault.
// requestWithdrawalERC20(address token, uint256 amount, uint256[] memory conditionIds): Request withdrawal of ERC20, specifying required conditions.
// requestWithdrawalERC721(address token, uint256 tokenId, uint256[] memory conditionIds): Request withdrawal of ERC721, specifying required conditions.
// requestWithdrawalERC1155(address token, uint256 id, uint256 amount, uint256[] memory conditionIds): Request withdrawal of ERC1155, specifying required conditions.
// cancelWithdrawalRequest(uint256 requestId): Cancel a pending withdrawal request.
// executeWithdrawalERC20(uint256 requestId): Execute a withdrawal request for ERC20 if all conditions are met.
// executeWithdrawalERC721(uint256 requestId): Execute a withdrawal request for ERC721 if all conditions are met.
// executeWithdrawalERC1155(uint256 requestId): Execute a withdrawal request for ERC1155 if all conditions are met.
// checkWithdrawalEligibility(uint256 requestId): Check if all conditions for a specific withdrawal request are currently met.

// --- Conditional Logic ---
// addTimeLockCondition(uint256 unlockTime): Add a time-based condition, returning its ID. (Callable by owner for setting up future conditions)
// addEventCondition(bytes32 eventIdentifier): Add an event-based condition identified by a hash, returning its ID. (Callable by owner)
// fulfillEventCondition(uint256 conditionId): Mark an event-based condition as fulfilled. (Callable by designated Oracle)
// getConditionStatus(uint256 conditionId): Get the current status of a specific condition.

// --- Guardian Management ---
// addGuardian(address guardian): Add a guardian. (Callable by owner)
// removeGuardian(address guardian): Remove a guardian. (Callable by owner)
// setGuardianThreshold(uint256 threshold): Set the minimum number of guardian approvals required for recovery/succession. (Callable by owner)
// getGuardians(): Get the list of current guardians. (View)
// getGuardianThreshold(): Get the current guardian approval threshold. (View)

// --- Recovery Process ---
// initiateRecovery(address recoveryAddress): Initiate the recovery process, specifying the address that will gain access. (Callable by Guardian)
// guardianApproveRecovery(uint256 recoveryId): Guardian approves a specific recovery initiation. (Callable by Guardian)
// completeRecovery(uint256 recoveryId): Complete the recovery process after sufficient guardian approvals. Transfers ownership or grants access to the recovery address. (Callable by the proposed recoveryAddress)
// getRecoveryStatus(uint256 recoveryId): Get the status details of a recovery attempt. (View)

// --- Succession Process ---
// proposeSuccessor(address successor): Propose an address to become the owner/beneficiary upon succession. (Callable by Owner)
// guardianApproveSuccessor(uint256 proposalId): Guardian approves a specific successor proposal. (Callable by Guardian)
// claimOwnershipViaSuccession(uint256 proposalId): Successor claims ownership or designated assets after conditions (e.g., owner inactivity period) and guardian approvals are met. (Callable by the proposed successor)
// getSuccessorProposalStatus(uint256 proposalId): Get the status details of a succession proposal. (View)

// --- Reputation System ---
// setReputationManager(address manager): Set the address authorized to update the reputation score. (Callable by owner)
// updateReputationScore(uint256 newScore): Manually update the reputation score. (Callable by ReputationManager)
// getReputationScore(): Get the current reputation score. (View)
// calculateReputationScoreBasedOnHoldings(): Calculate a potential reputation score based on current vaulted assets (Internal/View helper).

// --- View Functions ---
// getVaultBalanceERC20(address token): Get the vault's balance for a specific ERC20 token. (View)
// getVaultBalanceERC721(address token, uint256 tokenId): Check if the vault holds a specific ERC721 token. (View)
// getVaultBalanceERC1155(address token, uint256 id): Get the vault's balance for a specific ERC1155 token ID. (View)
// getTotalUniqueAssetCount(): Get the number of unique ERC20/ERC721 types held. (View)
// getWithdrawalRequestDetails(uint256 requestId): Get the details of a specific withdrawal request. (View)
// getOracleAddress(): Get the address authorized to fulfill event conditions. (View)
// isOwner(): Check if an address is the current soulbound owner. (View - implicit via Ownable's owner variable)

// --- ERC1155Holder Interface Function ---
// onERC1155Received(...) : Required by ERC1155Holder for receiving tokens.

```

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Imports ---
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// --- Error Definitions ---
error NotSoulboundOwner(); // Replaces standard Ownable errors for soulbound nature
error InvalidGuardian();
error InvalidGuardianThreshold();
error InsufficientGuardianApprovals();
error OnlyOracleAllowed();
error RequestNotFound();
error RequestNotEligible();
error RequestAlreadyExecuted();
error ConditionNotFound();
error ConditionAlreadyFulfilled();
error ConditionNotEventBased();
error ConditionNotTimeBased();
error InsufficientTokenBalance();
error ERC721NotOwned();
error ERC1155InsufficientBalance();
error InvalidSuccessor();
error SuccessionAlreadyProposed();
error SuccessionNotProposed();
error SuccessionNotApprovedByGuardians();
error SuccessionInactivePeriodNotPassed();
error RecoveryAlreadyInitiated();
error RecoveryNotInitiated();
error RecoveryAlreadyCompleted();
error RecoveryAddressMismatch();
error OnlyReputationManagerAllowed();
error StandardOwnershipTransferDisabled();

// --- Enums & Structs ---

enum ConditionType {
    TimeLock,
    EventTrigger
}

enum ConditionStatus {
    Pending,
    Fulfilled,
    Failed // Optional: for conditions that can expire or fail
}

struct WithdrawalCondition {
    ConditionType conditionType;
    uint256 value; // Timestamp for TimeLock, Condition ID for EventTrigger
    bytes32 eventIdentifier; // For EventTrigger
    ConditionStatus status;
}

enum AssetType {
    ERC20,
    ERC721,
    ERC1155
}

struct WithdrawalRequest {
    AssetType assetType;
    address tokenAddress;
    uint256 tokenId; // Used for ERC721 and ERC1155 id
    uint256 amount; // Used for ERC20 and ERC1155 amount
    address recipient;
    uint256[] requiredConditionIds;
    bool executed;
    uint256 requestTimestamp;
}

enum RecoveryState {
    Inactive,
    Initiated,
    GuardiansApproved,
    Completed
}

struct RecoveryAttempt {
    uint256 id;
    address initiator; // Guardian who initiated
    address recoveryAddress; // Address that will gain access
    uint256 initiatedTimestamp;
    RecoveryState state;
    mapping(address => bool) guardianApprovals; // Which guardians have approved
    uint256 approvalCount;
}

enum SuccessionState {
    Inactive,
    Proposed,
    GuardiansApproved,
    Claimed
}

struct SuccessionProposal {
    uint256 id;
    address proposer; // Owner who proposed
    address successorAddress;
    uint256 proposedTimestamp;
    SuccessionState state;
    mapping(address => bool) guardianApprovals; // Which guardians have approved
    uint256 approvalCount;
}

// --- Events ---

// Lifecycle Events
event VaultDeployed(address indexed owner);
event OwnershipRecovered(uint256 indexed recoveryId, address indexed newOwner, address indexed oldOwner);
event OwnershipSucceeded(uint256 indexed proposalId, address indexed newOwner, address indexed oldOwner);

// Asset Management Events
event ERC20Deposited(address indexed token, address indexed sender, uint256 amount);
event ERC721Deposited(address indexed token, address indexed sender, uint256 tokenId);
event ERC1155Deposited(address indexed token, address indexed sender, uint256 id, uint256 amount);
event WithdrawalRequested(uint256 indexed requestId, address indexed recipient, AssetType assetType, address token, uint256 tokenId, uint256 amount);
event WithdrawalCancelled(uint256 indexed requestId);
event ERC20Withdrawn(uint256 indexed requestId, address indexed recipient, address indexed token, uint256 amount);
event ERC721Withdrawn(uint256 indexed requestId, address indexed recipient, address indexed token, uint256 tokenId);
event ERC1155Withdrawn(uint256 indexed requestId, address indexed recipient, address indexed token, uint256 id, uint256 amount);

// Condition Events
event ConditionAdded(uint256 indexed conditionId, ConditionType conditionType, uint256 value, bytes32 eventIdentifier);
event ConditionFulfilled(uint256 indexed conditionId, ConditionStatus newStatus);

// Guardian Events
event GuardianAdded(address indexed guardian);
event GuardianRemoved(address indexed guardian);
event GuardianThresholdUpdated(uint256 oldThreshold, uint256 newThreshold);

// Recovery Events
event RecoveryInitiated(uint256 indexed recoveryId, address indexed initiator, address indexed recoveryAddress);
event GuardianApprovedRecovery(uint256 indexed recoveryId, address indexed guardian);
event RecoveryCompleted(uint256 indexed recoveryId, address indexed recoveredAddress);

// Succession Events
event SuccessorProposed(uint256 indexed proposalId, address indexed proposer, address indexed successor);
event GuardianApprovedSuccessor(uint256 indexed proposalId, address indexed guardian);
event SuccessionClaimed(uint256 indexed proposalId, address indexed successor);

// Reputation Events
event ReputationManagerUpdated(address indexed oldManager, address indexed newManager);
event ReputationScoreUpdated(uint256 oldScore, uint256 newScore);

// --- Contract Definition ---
contract CryptoSoulBoundVault is Ownable, ERC1155Holder {
    using SafeERC20 for IERC20;

    // --- State Variables ---

    // Soulbound Owner is managed by Ownable's _owner state variable, but modified behavior.
    address private _oracleAddress;
    address private _reputationManager;
    uint256 private _reputationScore;

    // Guardians
    mapping(address => bool) private _isGuardian;
    address[] private _guardians; // Simple array for iteration, map for quick lookup
    uint256 private _guardianThreshold;

    // Conditional Withdrawals
    uint256 private _nextConditionId = 1;
    mapping(uint256 => WithdrawalCondition) private _conditions;

    uint256 private _nextRequestId = 1;
    mapping(uint256 => WithdrawalRequest) private _withdrawalRequests;

    // Recovery
    uint256 private _nextRecoveryId = 1;
    mapping(uint256 => RecoveryAttempt) private _recoveryAttempts;
    uint256 private _activeRecoveryId = 0; // ID of the current active recovery attempt (0 if none)
    uint256 public constant RECOVERY_APPROVAL_PERIOD = 7 days; // Time window for guardians to approve recovery
    uint256 public constant RECOVERY_CLAIM_PERIOD = 7 days; // Time window for recovery address to complete recovery after approvals

    // Succession
    uint256 private _nextSuccessionProposalId = 1;
    mapping(uint256 => SuccessionProposal) private _successionProposals;
    uint256 private _activeSuccessionProposalId = 0; // ID of the current active succession proposal (0 if none)
    uint256 public constant SUCCESSION_INACTIVITY_PERIOD = 365 days; // Owner must be inactive for this long after proposal + approval
    uint256 public constant SUCCESSION_APPROVAL_PERIOD = 30 days; // Time window for guardians to approve succession proposal

    // Asset Tracking (for balances and reputation)
    mapping(address => uint256) private _erc20Balances;
    mapping(address => mapping(uint256 => bool)) private _erc721Holdings; // tokenAddress => tokenId => held
    mapping(address => mapping(uint256 => uint256)) private _erc1155Balances; // tokenAddress => id => amount

    uint256 private _uniqueERC20Count;
    uint256 private _uniqueERC721Count; // Tracks unique token *types*, not individual tokens
    uint256 private _uniqueERC1155TypeCount; // Tracks unique token *types* (address, not id)

    // Define minimums for reputation calculation (example)
    uint256 private constant MIN_ERC20_REPUTATION_AMOUNT = 1000; // Example: Need 1000 units of an ERC20 for it to count
    uint256 private constant MIN_ERC1155_REPUTATION_AMOUNT = 10; // Example: Need 10 units of an ERC1155 id for it to count

    // --- Constructor ---
    constructor(address initialGuardian, uint256 initialThreshold, address oracleAddress) Ownable(msg.sender) {
        if (initialThreshold == 0) revert InvalidGuardianThreshold();
        if (initialGuardian == address(0)) revert InvalidGuardian();
        if (oracleAddress == address(0)) revert OnlyOracleAllowed(); // Using the error name for param check clarity

        _addGuardian(initialGuardian);
        _guardianThreshold = initialThreshold;
        _oracleAddress = oracleAddress;
        _reputationManager = msg.sender; // Initially the owner is the rep manager

        emit VaultDeployed(msg.sender);
    }

    // --- Ownable Overrides (Enforce Soulbound Nature) ---

    // Disable standard transfer ownership
    function transferOwnership(address newOwner) public override(Ownable) onlyOwner {
        revert StandardOwnershipTransferDisabled();
    }

    // Disable standard renounce ownership
    function renounceOwnership() public override(Ownable) onlyOwner {
        revert StandardOwnershipTransferDisabled();
    }

    // Custom internal _transferOwnership to be used ONLY by recovery/succession flows
    function _transferOwnership(address newOwner) internal override(Ownable) {
        if (newOwner == address(0)) revert OwnableInvalidOwner(address(0));
        address oldOwner = _owner;
        _owner = newOwner; // Update the internal _owner state
        emit OwnershipTransferred(oldOwner, newOwner); // Emit the standard Ownable event
    }

    // --- Modifiers ---

    modifier onlyGuardian() {
        if (!_isGuardian[msg.sender]) revert InvalidGuardian();
        _;
    }

    modifier onlyOracle() {
        if (msg.sender != _oracleAddress) revert OnlyOracleAllowed();
        _;
    }

    modifier onlyReputationManager() {
        if (msg.sender != _reputationManager) revert OnlyReputationManagerAllowed();
        _;
    }

    // --- Core Vault Management ---

    /**
     * @notice Deposit ERC20 tokens into the vault.
     * @param token The address of the ERC20 token.
     * @param amount The amount of tokens to deposit.
     */
    function depositERC20(address token, uint256 amount) external {
        if (amount == 0) revert InsufficientTokenBalance(); // Or specific error for zero amount
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        _erc20Balances[token] += amount;

        // Update unique ERC20 count for reputation calculation if this is the first time
        if (_erc20Balances[token] == amount) {
            _uniqueERC20Count++;
        }

        emit ERC20Deposited(token, msg.sender, amount);
    }

    /**
     * @notice Deposit an ERC721 token into the vault.
     * @param token The address of the ERC721 token.
     * @param tokenId The ID of the ERC721 token.
     */
    function depositERC721(address token, uint256 tokenId) external {
         // Check if sender owns the token (standard transferFrom check might cover this, but explicit is clearer)
         // Not strictly needed due to ERC721 transferFrom standard, but good practice if not relying solely on OZ SafeTransferFrom
         // require(IERC721(token).ownerOf(tokenId) == msg.sender, "ERC721: transfer caller is not owner nor approved");

        IERC721(token).transferFrom(msg.sender, address(this), tokenId);
        _erc721Holdings[token][tokenId] = true;

        // Update unique ERC721 type count for reputation calculation if this is the first time
        // Note: This tracks *types* (contract address), not individual tokens
        if (_erc721Holdings[token][tokenId] == true && IERC721(token).balanceOf(address(this)) == 1) {
             _uniqueERC721Count++;
        }


        emit ERC721Deposited(token, msg.sender, tokenId);
    }

    /**
     * @notice Deposit ERC1155 tokens into the vault.
     * @param token The address of the ERC1155 token contract.
     * @param id The ID of the ERC1155 token type.
     * @param amount The amount of tokens to deposit.
     */
    function depositERC1155(address token, uint256 id, uint256 amount) external {
        if (amount == 0) revert ERC1155InsufficientBalance(); // Or specific error

        // ERC1155 `safeTransferFrom` is standard
        IERC1155(token).safeTransferFrom(msg.sender, address(this), id, amount, "");
        _erc1155Balances[token][id] += amount;

        // Update unique ERC1155 type count for reputation calculation if this is the first time
        if (_erc1155Balances[token][id] == amount) {
             _uniqueERC1155TypeCount++;
        }

        emit ERC1155Deposited(token, msg.sender, id, amount);
    }

    /**
     * @notice Request a withdrawal of ERC20 tokens. Requires owner to initiate.
     * @param token The address of the ERC20 token.
     * @param amount The amount to withdraw.
     * @param conditionIds An array of condition IDs that must be met for execution.
     * @return requestId The ID of the created withdrawal request.
     */
    function requestWithdrawalERC20(address token, uint256 amount, uint256[] memory conditionIds) external onlyOwner returns (uint256 requestId) {
        if (_erc20Balances[token] < amount) revert InsufficientTokenBalance();

        requestId = _nextRequestId++;
        _withdrawalRequests[requestId] = WithdrawalRequest({
            assetType: AssetType.ERC20,
            tokenAddress: token,
            tokenId: 0, // Not applicable for ERC20
            amount: amount,
            recipient: msg.sender, // Owner is requesting
            requiredConditionIds: conditionIds,
            executed: false,
            requestTimestamp: block.timestamp
        });

        emit WithdrawalRequested(requestId, msg.sender, AssetType.ERC20, token, 0, amount);
        return requestId;
    }

    /**
     * @notice Request a withdrawal of an ERC721 token. Requires owner to initiate.
     * @param token The address of the ERC721 token.
     * @param tokenId The ID of the ERC721 token.
     * @param conditionIds An array of condition IDs that must be met for execution.
     * @return requestId The ID of the created withdrawal request.
     */
    function requestWithdrawalERC721(address token, uint256 tokenId, uint256[] memory conditionIds) external onlyOwner returns (uint256 requestId) {
        if (!_erc721Holdings[token][tokenId]) revert ERC721NotOwned();
        // Double check actual holding - defense in depth
        if (IERC721(token).ownerOf(tokenId) != address(this)) revert ERC721NotOwned();


        requestId = _nextRequestId++;
        _withdrawalRequests[requestId] = WithdrawalRequest({
            assetType: AssetType.ERC721,
            tokenAddress: token,
            tokenId: tokenId,
            amount: 0, // Not applicable for ERC721
            recipient: msg.sender, // Owner is requesting
            requiredConditionIds: conditionIds,
            executed: false,
            requestTimestamp: block.timestamp
        });

        emit WithdrawalRequested(requestId, msg.sender, AssetType.ERC721, token, tokenId, 0);
        return requestId;
    }

     /**
     * @notice Request a withdrawal of ERC1155 tokens. Requires owner to initiate.
     * @param token The address of the ERC1155 token contract.
     * @param id The ID of the ERC1155 token type.
     * @param amount The amount to withdraw.
     * @param conditionIds An array of condition IDs that must be met for execution.
     * @return requestId The ID of the created withdrawal request.
     */
    function requestWithdrawalERC1155(address token, uint256 id, uint256 amount, uint256[] memory conditionIds) external onlyOwner returns (uint256 requestId) {
        if (_erc1155Balances[token][id] < amount) revert ERC1155InsufficientBalance();

        requestId = _nextRequestId++;
        _withdrawalRequests[requestId] = WithdrawalRequest({
            assetType: AssetType.ERC1155,
            tokenAddress: token,
            tokenId: id, // tokenId is used for the ID in ERC1155 context
            amount: amount,
            recipient: msg.sender, // Owner is requesting
            requiredConditionIds: conditionIds,
            executed: false,
            requestTimestamp: block.timestamp
        });

        emit WithdrawalRequested(requestId, msg.sender, AssetType.ERC1155, token, id, amount);
        return requestId;
    }


    /**
     * @notice Cancel a pending withdrawal request. Can only be done by the owner.
     * @param requestId The ID of the request to cancel.
     */
    function cancelWithdrawalRequest(uint256 requestId) external onlyOwner {
        WithdrawalRequest storage req = _withdrawalRequests[requestId];
        if (req.requestTimestamp == 0) revert RequestNotFound(); // Check if request exists
        if (req.executed) revert RequestAlreadyExecuted();

        // Simply mark as cancelled or delete. Deleting might be better for gas long-term.
        // For simplicity and state clarity, let's just remove it.
        delete _withdrawalRequests[requestId];

        // Note: This does *not* delete the conditions themselves, as they might be reused.
        // The conditions remain in storage but are no longer linked to this request.

        emit WithdrawalCancelled(requestId);
    }

    /**
     * @notice Execute a previously requested ERC20 withdrawal if all conditions are met.
     * @param requestId The ID of the request to execute.
     */
    function executeWithdrawalERC20(uint256 requestId) external {
        WithdrawalRequest storage req = _withdrawalRequests[requestId];
        if (req.requestTimestamp == 0 || req.assetType != AssetType.ERC20) revert RequestNotFound();
        if (req.executed) revert RequestAlreadyExecuted();
        if (!checkWithdrawalEligibility(requestId)) revert RequestNotEligible();
        if (_erc20Balances[req.tokenAddress] < req.amount) revert InsufficientTokenBalance(); // Double check balance

        req.executed = true;
        _erc20Balances[req.tokenAddress] -= req.amount;
        IERC20(req.tokenAddress).safeTransfer(req.recipient, req.amount);

        // Check if unique ERC20 count needs decrementing (if balance dropped to 0)
        if (_erc20Balances[req.tokenAddress] == 0) {
            _uniqueERC20Count--;
        }

        emit ERC20Withdrawn(requestId, req.recipient, req.tokenAddress, req.amount);
    }

    /**
     * @notice Execute a previously requested ERC721 withdrawal if all conditions are met.
     * @param requestId The ID of the request to execute.
     */
    function executeWithdrawalERC721(uint256 requestId) external {
        WithdrawalRequest storage req = _withdrawalRequests[requestId];
        if (req.requestTimestamp == 0 || req.assetType != AssetType.ERC721) revert RequestNotFound();
        if (req.executed) revert RequestAlreadyExecuted();
        if (!checkWithdrawalEligibility(requestId)) revert RequestNotEligible();
         if (!_erc721Holdings[req.tokenAddress][req.tokenId]) revert ERC721NotOwned(); // Double check holding

        req.executed = true;
        _erc721Holdings[req.tokenAddress][req.tokenId] = false; // Mark as no longer holding
        IERC721(req.tokenAddress).transferFrom(address(this), req.recipient, req.tokenId); // Use transferFrom from contract

        // Check if unique ERC721 type count needs decrementing (if this was the last token of this type)
        if (IERC721(req.tokenAddress).balanceOf(address(this)) == 0) {
            _uniqueERC721Count--;
        }

        emit ERC721Withdrawn(requestId, req.recipient, req.tokenAddress, req.tokenId);
    }

     /**
     * @notice Execute a previously requested ERC1155 withdrawal if all conditions are met.
     * @param requestId The ID of the request to execute.
     */
    function executeWithdrawalERC1155(uint256 requestId) external {
        WithdrawalRequest storage req = _withdrawalRequests[requestId];
        if (req.requestTimestamp == 0 || req.assetType != AssetType.ERC1155) revert RequestNotFound();
        if (req.executed) revert RequestAlreadyExecuted();
        if (!checkWithdrawalEligibility(requestId)) revert RequestNotEligible();
        if (_erc1155Balances[req.tokenAddress][req.tokenId] < req.amount) revert ERC1155InsufficientBalance(); // Double check balance

        req.executed = true;
        _erc1155Balances[req.tokenAddress][req.tokenId] -= req.amount;
        IERC1155(req.tokenAddress).safeTransferFrom(address(this), req.recipient, req.tokenId, req.amount, "");

        // Check if unique ERC1155 type count needs decrementing (if balance dropped to 0 for this ID)
        if (_erc1155Balances[req.tokenAddress][req.tokenId] == 0) {
            _uniqueERC1155TypeCount--;
        }

        emit ERC1155Withdrawn(requestId, req.recipient, req.tokenAddress, req.tokenId, req.amount);
    }

    /**
     * @notice Check if all conditions for a specific withdrawal request are met.
     * @param requestId The ID of the request.
     * @return True if eligible, false otherwise.
     */
    function checkWithdrawalEligibility(uint256 requestId) public view returns (bool) {
        WithdrawalRequest storage req = _withdrawalRequests[requestId];
        if (req.requestTimestamp == 0 || req.executed) return false;

        for (uint i = 0; i < req.requiredConditionIds.length; i++) {
            uint256 conditionId = req.requiredConditionIds[i];
            WithdrawalCondition storage condition = _conditions[conditionId];

            if (condition.status != ConditionStatus.Fulfilled) {
                 // Check if it's a time lock that has passed
                 if (condition.conditionType == ConditionType.TimeLock && block.timestamp >= condition.value) {
                     // Time lock met, continue checking other conditions.
                     // Note: We don't change the condition.status here in a pure/view function.
                 } else {
                     // Condition is not fulfilled and is not a met time lock, so eligibility fails.
                     return false;
                 }
            }
        }
        return true; // All conditions are fulfilled or time locks have passed
    }

    // --- Conditional Logic Functions ---

    /**
     * @notice Add a time-based condition.
     * @param unlockTime The Unix timestamp when the condition is met.
     * @return conditionId The ID of the created condition.
     */
    function addTimeLockCondition(uint256 unlockTime) external onlyOwner returns (uint256 conditionId) {
        conditionId = _nextConditionId++;
        _conditions[conditionId] = WithdrawalCondition({
            conditionType: ConditionType.TimeLock,
            value: unlockTime,
            eventIdentifier: bytes32(0), // Not used for time locks
            status: ConditionStatus.Pending
        });
        emit ConditionAdded(conditionId, ConditionType.TimeLock, unlockTime, bytes32(0));
        return conditionId;
    }

    /**
     * @notice Add an event-based condition. Requires an external oracle to fulfill.
     * @param eventIdentifier A unique identifier for the event (e.g., hash of description).
     * @return conditionId The ID of the created condition.
     */
    function addEventCondition(bytes32 eventIdentifier) external onlyOwner returns (uint256 conditionId) {
        conditionId = _nextConditionId++;
         _conditions[conditionId] = WithdrawalCondition({
            conditionType: ConditionType.EventTrigger,
            value: 0, // Not used for event triggers
            eventIdentifier: eventIdentifier,
            status: ConditionStatus.Pending
        });
        emit ConditionAdded(conditionId, ConditionType.EventTrigger, 0, eventIdentifier);
        return conditionId;
    }

    /**
     * @notice Mark an event-based condition as fulfilled. Only callable by the designated oracle address.
     * @param conditionId The ID of the condition to fulfill.
     */
    function fulfillEventCondition(uint256 conditionId) external onlyOracle {
        WithdrawalCondition storage condition = _conditions[conditionId];
        if (condition.conditionType != ConditionType.EventTrigger) revert ConditionNotEventBased();
        if (condition.status != ConditionStatus.Pending) revert ConditionAlreadyFulfilled(); // Or specific error if failed/unknown
        if (condition.eventIdentifier == bytes32(0)) revert ConditionNotFound(); // Sanity check

        condition.status = ConditionStatus.Fulfilled;
        emit ConditionFulfilled(conditionId, ConditionStatus.Fulfilled);
    }

    /**
     * @notice Get the status of a specific condition.
     * @param conditionId The ID of the condition.
     * @return status The status of the condition.
     */
    function getConditionStatus(uint256 conditionId) external view returns (ConditionStatus status) {
         WithdrawalCondition storage condition = _conditions[conditionId];
         if (condition.eventIdentifier == bytes32(0) && condition.value == 0) revert ConditionNotFound(); // Check if condition exists

         if (condition.conditionType == ConditionType.TimeLock) {
             return block.timestamp >= condition.value ? ConditionStatus.Fulfilled : ConditionStatus.Pending;
         } else { // EventTrigger
             return condition.status;
         }
    }

    // --- Guardian Management Functions ---

    /**
     * @notice Add a guardian.
     * @param guardian The address of the guardian to add.
     */
    function addGuardian(address guardian) external onlyOwner {
        if (guardian == address(0)) revert InvalidGuardian();
        if (!_isGuardian[guardian]) {
            _isGuardian[guardian] = true;
            _guardians.push(guardian);
            emit GuardianAdded(guardian);
        }
    }

    /**
     * @notice Remove a guardian.
     * @param guardian The address of the guardian to remove.
     */
    function removeGuardian(address guardian) external onlyOwner {
        if (_isGuardian[guardian]) {
            _isGuardian[guardian] = false;
            // Simple removal by setting to address(0) and filtering in getGuardians, or iterate and swap-remove.
            // Swap-remove is more gas efficient for reads on the array.
            for (uint i = 0; i < _guardians.length; i++) {
                if (_guardians[i] == guardian) {
                    _guardians[i] = _guardians[_guardians.length - 1];
                    _guardians.pop();
                    break; // Assuming unique guardians
                }
            }
            // Ensure threshold is not higher than remaining guardians
            if (_guardianThreshold > _guardians.length) {
                 _guardianThreshold = _guardians.length;
                 emit GuardianThresholdUpdated(_guardianThreshold + 1, _guardianThreshold); // Emit with correct old/new values
            }
            emit GuardianRemoved(guardian);
        }
    }

    /**
     * @notice Set the minimum number of guardian approvals required for recovery/succession.
     * @param threshold The new threshold.
     */
    function setGuardianThreshold(uint256 threshold) external onlyOwner {
        if (threshold == 0 || threshold > _guardians.length) revert InvalidGuardianThreshold();
        uint256 oldThreshold = _guardianThreshold;
        _guardianThreshold = threshold;
        emit GuardianThresholdUpdated(oldThreshold, _guardianThreshold);
    }

    /**
     * @notice Get the list of current guardian addresses.
     * @return A dynamic array of guardian addresses.
     */
    function getGuardians() external view returns (address[] memory) {
        return _guardians;
    }

     /**
     * @notice Get the current guardian approval threshold.
     * @return The threshold value.
     */
    function getGuardianThreshold() external view returns (uint256) {
        return _guardianThreshold;
    }


    // --- Recovery Functions ---

    /**
     * @notice A guardian initiates a recovery process for the owner.
     * @param recoveryAddress The address that will potentially gain access/ownership.
     * @return recoveryId The ID of the new recovery attempt.
     */
    function initiateRecovery(address recoveryAddress) external onlyGuardian returns (uint256 recoveryId) {
        if (recoveryAddress == address(0)) revert RecoveryAddressMismatch();
        if (_activeRecoveryId != 0 && _recoveryAttempts[_activeRecoveryId].state < RecoveryState.Completed) {
            revert RecoveryAlreadyInitiated(); // Only one active recovery at a time
        }

        recoveryId = _nextRecoveryId++;
        _recoveryAttempts[recoveryId] = RecoveryAttempt({
            id: recoveryId,
            initiator: msg.sender,
            recoveryAddress: recoveryAddress,
            initiatedTimestamp: block.timestamp,
            state: RecoveryState.Initiated,
            guardianApprovals: new mapping(address => bool),
            approvalCount: 0
        });
        _activeRecoveryId = recoveryId;

        emit RecoveryInitiated(recoveryId, msg.sender, recoveryAddress);
        return recoveryId;
    }

    /**
     * @notice A guardian approves an initiated recovery attempt.
     * @param recoveryId The ID of the recovery attempt to approve.
     */
    function guardianApproveRecovery(uint256 recoveryId) external onlyGuardian {
        RecoveryAttempt storage attempt = _recoveryAttempts[recoveryId];
        if (attempt.id == 0 || attempt.state != RecoveryState.Initiated) revert RecoveryNotInitiated();
        if (block.timestamp > attempt.initiatedTimestamp + RECOVERY_APPROVAL_PERIOD) {
            attempt.state = RecoveryState.Inactive; // Time window expired
            revert RecoveryNotInitiated(); // Treat as no longer active
        }
        if (attempt.guardianApprovals[msg.sender]) return; // Already approved

        attempt.guardianApprovals[msg.sender] = true;
        attempt.approvalCount++;

        emit GuardianApprovedRecovery(recoveryId, msg.sender);

        if (attempt.approvalCount >= _guardianThreshold) {
            attempt.state = RecoveryState.GuardiansApproved;
            // The recoveryAddress can now call completeRecovery within RECOVERY_CLAIM_PERIOD
        }
    }

    /**
     * @notice The designated recovery address completes the recovery process.
     * Transfers ownership or grants access.
     * @param recoveryId The ID of the approved recovery attempt.
     */
    function completeRecovery(uint256 recoveryId) external {
        RecoveryAttempt storage attempt = _recoveryAttempts[recoveryId];
        if (attempt.id == 0 || attempt.state != RecoveryState.GuardiansApproved) revert RecoveryNotInitiated();
        if (msg.sender != attempt.recoveryAddress) revert RecoveryAddressMismatch();
        if (attempt.state == RecoveryState.Completed) revert RecoveryAlreadyCompleted();

        // Check if claim period has expired
        if (block.timestamp > attempt.initiatedTimestamp + RECOVERY_APPROVAL_PERIOD + RECOVERY_CLAIM_PERIOD) {
            attempt.state = RecoveryState.Inactive; // Claim window expired
            revert RecoveryNotInitiated(); // Treat as no longer active
        }

        attempt.state = RecoveryState.Completed;
        _activeRecoveryId = 0; // No longer an active recovery

        // Transfer ownership to the recovery address using the internal function
        address oldOwner = _owner;
        _transferOwnership(attempt.recoveryAddress); // Use the custom internal transfer

        emit RecoveryCompleted(recoveryId, attempt.recoveryAddress);
        emit OwnershipRecovered(recoveryId, attempt.recoveryAddress, oldOwner);
    }

    /**
     * @notice Get the status of a specific recovery attempt.
     * @param recoveryId The ID of the recovery attempt.
     * @return state The current state of the recovery attempt.
     * @return initiator The address that initiated the attempt.
     * @return recoveryAddress The address designated for recovery.
     * @return initiatedTimestamp When the attempt was initiated.
     * @return approvalCount The number of guardian approvals received.
     * @return requiredApprovals The threshold of approvals required.
     */
    function getRecoveryStatus(uint256 recoveryId) external view returns (
        RecoveryState state,
        address initiator,
        address recoveryAddress,
        uint256 initiatedTimestamp,
        uint256 approvalCount,
        uint256 requiredApprovals
    ) {
        RecoveryAttempt storage attempt = _recoveryAttempts[recoveryId];
        if (attempt.id == 0) revert RecoveryNotInitiated(); // Using this error for 'not found'

        state = attempt.state;
        initiator = attempt.initiator;
        recoveryAddress = attempt.recoveryAddress;
        initiatedTimestamp = attempt.initiatedTimestamp;
        approvalCount = attempt.approvalCount;
        requiredApprovals = _guardianThreshold; // Threshold is global

        // Check if time windows have expired if state is not completed
        if (state == RecoveryState.Initiated && block.timestamp > initiatedTimestamp + RECOVERY_APPROVAL_PERIOD) {
            state = RecoveryState.Inactive; // Simulation for view function
        } else if (state == RecoveryState.GuardiansApproved && block.timestamp > initiatedTimestamp + RECOVERY_APPROVAL_PERIOD + RECOVERY_CLAIM_PERIOD) {
             state = RecoveryState.Inactive; // Simulation for view function
        }
    }


    // --- Succession Functions ---

    /**
     * @notice The current owner proposes a successor address.
     * @param successor The address proposed to become the owner/beneficiary upon succession.
     * @return proposalId The ID of the new succession proposal.
     */
    function proposeSuccessor(address successor) external onlyOwner returns (uint256 proposalId) {
        if (successor == address(0)) revert InvalidSuccessor();
        if (_activeSuccessionProposalId != 0 && _successionProposals[_activeSuccessionProposalId].state < SuccessionState.Claimed) {
            revert SuccessionAlreadyProposed(); // Only one active proposal at a time
        }

        proposalId = _nextSuccessionProposalId++;
        _successionProposals[proposalId] = SuccessionProposal({
            id: proposalId,
            proposer: msg.sender,
            successorAddress: successor,
            proposedTimestamp: block.timestamp,
            state: SuccessionState.Proposed,
            guardianApprovals: new mapping(address => bool),
            approvalCount: 0
        });
        _activeSuccessionProposalId = proposalId;

        emit SuccessorProposed(proposalId, msg.sender, successor);
        return proposalId;
    }

     /**
     * @notice A guardian approves a proposed successor.
     * @param proposalId The ID of the succession proposal to approve.
     */
    function guardianApproveSuccessor(uint256 proposalId) external onlyGuardian {
        SuccessionProposal storage proposal = _successionProposals[proposalId];
        if (proposal.id == 0 || proposal.state != SuccessionState.Proposed) revert SuccessionNotProposed();
         if (block.timestamp > proposal.proposedTimestamp + SUCCESSION_APPROVAL_PERIOD) {
            proposal.state = SuccessionState.Inactive; // Time window expired
            revert SuccessionNotProposed(); // Treat as no longer active
        }
        if (proposal.guardianApprovals[msg.sender]) return; // Already approved

        proposal.guardianApprovals[msg.sender] = true;
        proposal.approvalCount++;

        emit GuardianApprovedSuccessor(proposalId, msg.sender);

        if (proposal.approvalCount >= _guardianThreshold) {
            proposal.state = SuccessionState.GuardiansApproved;
            // The successorAddress can now call claimOwnershipViaSuccession after SUCCESSION_INACTIVITY_PERIOD
        }
    }

    /**
     * @notice The proposed successor claims ownership via the succession process.
     * Requires guardian approval and owner inactivity.
     * @param proposalId The ID of the approved succession proposal.
     */
    function claimOwnershipViaSuccession(uint256 proposalId) external {
        SuccessionProposal storage proposal = _successionProposals[proposalId];
        if (proposal.id == 0 || proposal.state != SuccessionState.GuardiansApproved) revert SuccessionNotApprovedByGuardians();
        if (msg.sender != proposal.successorAddress) revert InvalidSuccessor();
        if (proposal.state == SuccessionState.Claimed) revert SuccessionAlreadyProposed(); // Using this error for 'already claimed'

        // Check owner inactivity period - compare current time to the LAST time the *owner* interacted
        // with the contract (need to track owner activity).
        // For simplicity in this example, let's just use the proposal timestamp + inactivity period.
        // A more robust implementation would track last owner interaction timestamp.
        if (block.timestamp < proposal.proposedTimestamp + SUCCESSION_INACTIVITY_PERIOD) {
             revert SuccessionInactivePeriodNotPassed();
        }

        proposal.state = SuccessionState.Claimed;
        _activeSuccessionProposalId = 0; // No longer an active proposal

         // Transfer ownership to the successor using the internal function
        address oldOwner = _owner;
        _transferOwnership(proposal.successorAddress); // Use the custom internal transfer

        emit SuccessionClaimed(proposalId, proposal.successorAddress);
        emit OwnershipSucceeded(proposalId, proposal.successorAddress, oldOwner);
    }

    /**
     * @notice Get the status of a specific succession proposal.
     * @param proposalId The ID of the succession proposal.
     * @return state The current state of the succession proposal.
     * @return proposer The address that proposed the successor.
     * @return successorAddress The address proposed as successor.
     * @return proposedTimestamp When the proposal was made.
     * @return approvalCount The number of guardian approvals received.
     * @return requiredApprovals The threshold of approvals required.
     * @return inactivityPeriod The required owner inactivity duration.
     */
    function getSuccessorProposalStatus(uint256 proposalId) external view returns (
        SuccessionState state,
        address proposer,
        address successorAddress,
        uint256 proposedTimestamp,
        uint256 approvalCount,
        uint256 requiredApprovals,
        uint256 inactivityPeriod
    ) {
        SuccessionProposal storage proposal = _successionProposals[proposalId];
        if (proposal.id == 0) revert SuccessionNotProposed(); // Using this error for 'not found'

        state = proposal.state;
        proposer = proposal.proposer;
        successorAddress = proposal.successorAddress;
        proposedTimestamp = proposal.proposedTimestamp;
        approvalCount = proposal.approvalCount;
        requiredApprovals = _guardianThreshold;
        inactivityPeriod = SUCCESSION_INACTIVITY_PERIOD;

        // Check if time windows have expired if state is not claimed
         if (state == SuccessionState.Proposed && block.timestamp > proposedTimestamp + SUCCESSION_APPROVAL_PERIOD) {
            state = SuccessionState.Inactive; // Simulation for view function
        } else if (state == SuccessionState.GuardiansApproved && block.timestamp < proposedTimestamp + SUCCESSION_INACTIVITY_PERIOD) {
             // Owner inactivity period not yet met, state remains GuardiansApproved but claim is not possible
             // No state change simulation needed here, the claim function handles the check
        } else if (state == SuccessionState.GuardiansApproved && block.timestamp >= proposedTimestamp + SUCCESSION_INACTIVITY_PERIOD) {
            // Simulation: claim is now possible
        }
    }


    // --- Reputation System Functions ---

    /**
     * @notice Set the address authorized to manually update the reputation score.
     * @param manager The address to set as the reputation manager.
     */
    function setReputationManager(address manager) external onlyOwner {
        if (manager == address(0)) revert OnlyReputationManagerAllowed(); // Use error name for param check clarity
        address oldManager = _reputationManager;
        _reputationManager = manager;
        emit ReputationManagerUpdated(oldManager, manager);
    }

    /**
     * @notice Manually update the reputation score. Callable only by the ReputationManager.
     * Note: In a real system, this might be driven by asset value feeds, DAO votes, etc.
     * This is a simplified placeholder.
     * @param newScore The new reputation score.
     */
    function updateReputationScore(uint256 newScore) external onlyReputationManager {
        uint256 oldScore = _reputationScore;
        _reputationScore = newScore;
        emit ReputationScoreUpdated(oldScore, newScore);
    }

    /**
     * @notice Get the current manually set reputation score.
     * @return The current reputation score.
     */
    function getReputationScore() external view returns (uint256) {
        return _reputationScore;
    }

     /**
     * @notice Calculate a potential reputation score based on current vault holdings.
     * This is an example calculation and doesn't update the stored _reputationScore.
     * @return A calculated score based on holdings.
     */
    function calculateReputationScoreBasedOnHoldings() external view returns (uint256) {
        uint256 calculatedScore = 0;

        // Simple example: 1 point per unique ERC20 with sufficient balance
        // This requires iterating through all ERC20s ever deposited, which is inefficient.
        // A better way would track this continuously or have a limited set of "reputation tokens".
        // For demonstration, we'll rely on the unique counts tracked on deposit/withdraw.
        calculatedScore += _uniqueERC20Count * 5; // Example: 5 points per unique ERC20 type
        calculatedScore += _uniqueERC721Count * 10; // Example: 10 points per unique ERC721 type
        calculatedScore += _uniqueERC1155TypeCount * 3; // Example: 3 points per unique ERC1155 type

        // Could add more complex logic, e.g., based on specific high-value assets, length of holding, etc.

        return calculatedScore;
    }

    // --- View Functions ---

    /**
     * @notice Get the vault's balance for a specific ERC20 token.
     * @param token The address of the ERC20 token.
     * @return The amount of the token held.
     */
    function getVaultBalanceERC20(address token) external view returns (uint256) {
        return _erc20Balances[token];
    }

    /**
     * @notice Check if the vault holds a specific ERC721 token.
     * @param token The address of the ERC721 token.
     * @param tokenId The ID of the ERC721 token.
     * @return True if the vault holds the token, false otherwise.
     */
    function getVaultBalanceERC721(address token, uint256 tokenId) external view returns (bool) {
        return _erc721Holdings[token][tokenId];
    }

    /**
     * @notice Get the vault's balance for a specific ERC1155 token ID.
     * @param token The address of the ERC1155 token contract.
     * @param id The ID of the ERC1155 token type.
     * @return The amount of the token ID held.
     */
    function getVaultBalanceERC1155(address token, uint256 id) external view returns (uint256) {
        return _erc1155Balances[token][id];
    }

    /**
     * @notice Get the total number of unique asset types held (ERC20, ERC721 contract, ERC1155 contract).
     * Note: This counts contract addresses for 721/1155, not individual tokens/IDs.
     * @return The count of unique asset types.
     */
    function getTotalUniqueAssetCount() external view returns (uint256) {
        return _uniqueERC20Count + _uniqueERC721Count + _uniqueERC1155TypeCount;
    }

    /**
     * @notice Get the details of a specific withdrawal request.
     * @param requestId The ID of the request.
     * @return details A struct containing the request details.
     */
    function getWithdrawalRequestDetails(uint256 requestId) external view returns (WithdrawalRequest memory details) {
         WithdrawalRequest storage req = _withdrawalRequests[requestId];
         if (req.requestTimestamp == 0) revert RequestNotFound();
         return req; // Return a copy from storage
    }

    /**
     * @notice Get the address authorized as the Oracle.
     * @return The Oracle address.
     */
    function getOracleAddress() external view returns (address) {
        return _oracleAddress;
    }

     // isOwner is provided by Ownable

    // --- ERC1155Holder Required Function ---

    /**
     * @notice Called by an ERC1155 contract when tokens are transferred to this contract.
     * Required for ERC1155Holder compatibility.
     * @dev This hook is already handled by depositERC1155 which uses safeTransferFrom.
     *      However, if tokens are *sent* directly without safeTransferFrom, this function would be called.
     *      We accept the tokens but don't explicitly handle tracking here, assuming deposit is the primary method.
     *      A more robust version might update balances here as well.
     */
    function onERC1155Received(address operator, address from, uint256 id, uint256 amount, bytes memory data)
        public override(ERC1155Holder) returns (bytes4)
    {
         // Optionally update balances here if direct transfers are expected and not via deposit function
         // _erc1155Balances[msg.sender][id] += amount; // msg.sender is the ERC1155 contract address

        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address operator, address from, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public override(ERC1155Holder) returns (bytes4)
    {
        // Same as above, optionally handle batch deposits not via deposit function
        // for (uint i = 0; i < ids.length; ++i) {
        //     _erc1155Balances[msg.sender][ids[i]] += amounts[i];
        // }

        return this.onERC1155BatchReceived.selector;
    }

    // Fallback and Receive functions to accept native currency (ETH) if needed
    // (Not explicitly requested or used by current functions, but common in vaults)
    // receive() external payable {}
    // fallback() external payable {}


}
```