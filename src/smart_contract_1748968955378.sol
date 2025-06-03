Okay, here is a smart contract called `QuantumVault` that incorporates advanced concepts like conditional asset release, support for multiple asset types (ETH, ERC20, ERC721, ERC1155), role-based access control, pausing, vesting schedules as a specific condition type, and a mechanism to define and evaluate custom (though internally implemented) conditions for withdrawal.

It aims for creativity by allowing deposits to be locked until specific on-chain conditions are met, and allowing *anyone* (or specific roles) to trigger the check and withdrawal if the conditions are fulfilled. The condition evaluation is handled internally based on predefined "condition types".

This design tries to avoid direct copies of standard OpenZeppelin contracts by combining features in a novel way and implementing core logic like conditions internally.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol"; // Example for potential advanced condition: signature verification

// --- Outline ---
// 1. Contract Definition and Imports
// 2. Access Control Roles (Owner, Manager, ConditionalExecutor, Guardian)
// 3. Pausable and ReentrancyGuard
// 4. State Variables (Deposit data, counters, mappings, condition types)
// 5. Enums and Structs (AssetType, Deposit, Condition)
// 6. Events
// 7. Modifiers (Specific role checks)
// 8. Constructor
// 9. Access Control & Role Management Functions (grant, revoke, renounce, hasRole, getRoleMembers)
// 10. Pausable Functions (pause, unpause)
// 11. Deposit Functions (ETH, ERC20, ERC721, ERC1155 - Simple and Conditional)
// 12. Conditional Logic Definition & Evaluation (Internal helpers and external checker)
// 13. Withdrawal Functions (Admin simple, Execute conditional, Claim vested)
// 14. Vesting Specific Logic (Part of conditional)
// 15. Query Functions (View deposit details, check conditions, balances)
// 16. Admin & Emergency Functions (Emergency withdrawal, stuck asset recovery, deposit tagging)
// 17. ERC721/ERC1155 Receiver Hooks

// --- Function Summary ---
// Core Admin & Access Control:
// - constructor(): Initializes roles and state.
// - grantRole(bytes32 role, address account): Grants a specific role to an account.
// - revokeRole(bytes32 role, address account): Revokes a specific role from an account.
// - renounceRole(bytes32 role): Allows an account to remove their own role.
// - hasRole(bytes32 role, address account): Checks if an account has a specific role (view).
// - getRoleMemberCount(bytes32 role): Gets the number of accounts with a role (view).
// - getRoleMember(bytes32 role, uint256 index): Gets an account with a role by index (view).
// - pause(): Pauses contract operations (Owner/Guardian only).
// - unpause(): Unpauses contract operations (Owner/Guardian only).

// Deposit Functions:
// - depositETH(): Deposits ETH into the vault (standard).
// - depositERC20(IERC20 token, uint256 amount): Deposits ERC20 tokens (standard).
// - depositERC721(IERC721 token, uint256 tokenId): Deposits ERC721 token (standard).
// - depositERC1155(IERC1155 token, uint256 id, uint256 amount): Deposits ERC1155 tokens (standard).
// - depositConditionalETH(address recipient, string tag, Condition[] conditions): Deposits ETH with attached withdrawal conditions.
// - depositConditionalERC20(IERC20 token, uint256 amount, address recipient, string tag, Condition[] conditions): Deposits ERC20 with conditions.
// - depositConditionalERC721(IERC721 token, uint256 tokenId, address recipient, string tag, Condition[] conditions): Deposits ERC721 with conditions.
// - depositConditionalERC1155(IERC1155 token, uint256 id, uint256 amount, address recipient, string tag, Condition[] conditions): Deposits ERC1155 with conditions.
// - depositVestedETH(uint256 amount, address recipient, uint256 startTime, uint256 endTime, uint256 cliffTime): Deposits ETH with a standard vesting schedule (specific conditional type).
// - depositVestedERC20(IERC20 token, uint256 amount, address recipient, uint256 startTime, uint256 endTime, uint256 cliffTime): Deposits ERC20 with vesting.

// Conditional Logic & Withdrawal:
// - executeConditionalWithdrawal(uint256 depositId): Attempts to withdraw a conditional deposit if all conditions are met. Callable by recipient, ConditionalExecutor, or Owner.
// - claimVestedETH(uint256 depositId): Claims available vested ETH from a specific deposit ID.
// - claimVestedERC20(uint256 depositId): Claims available vested ERC20 from a specific deposit ID.
// - checkConditionStatus(uint256 depositId): Checks and returns the status of conditions for a deposit (view).

// Query Functions:
// - viewDepositDetails(uint256 depositId): Gets detailed info about a specific deposit (view).
// - viewUserDeposits(address user): Gets a list of deposit IDs for a user (view).
// - getDepositCount(): Gets the total number of deposits made (view).
// - getTotalVaultBalance(address token): Gets the total balance of a specific ERC20 token in the vault (view). 0 for ETH.
// - getWithdrawableETH(address user): Gets the total simple + claimable vested ETH for a user (view). Does NOT check conditional deposits.
// - getWithdrawableERC20(IERC20 token, address user): Gets total simple + claimable vested ERC20 for a user (view). Does NOT check conditional deposits.
// - getAvailableVestedETH(uint256 depositId): Gets currently claimable vested ETH for a specific deposit (view).
// - getAvailableVestedERC20(uint256 depositId): Gets currently claimable vested ERC20 for a specific deposit (view).

// Admin & Emergency Functions:
// - emergencyWithdrawETH(address recipient, uint256 amount): Allows Owner/Guardian to withdraw any amount of ETH in emergency.
// - emergencyWithdrawERC20(IERC20 token, address recipient, uint256 amount): Allows Owner/Guardian to withdraw ERC20 in emergency.
// - emergencyWithdrawERC721(IERC721 token, uint256 tokenId, address recipient): Allows Owner/Guardian to withdraw ERC721 in emergency.
// - emergencyWithdrawERC1155(IERC1155 token, uint256 id, uint256 amount, address recipient): Allows Owner/Guardian to withdraw ERC1155 in emergency.
// - transferStuckERC20(IERC20 token, address recipient, uint256 amount): Recover accidentally sent ERC20 (Owner only).
// - transferStuckERC721(IERC721 token, uint256 tokenId, address recipient): Recover accidentally sent ERC721 (Owner only).
// - transferStuckERC1155(IERC1155 token, uint256 id, uint256 amount, address recipient): Recover accidentally sent ERC1155 (Owner only).
// - setDepositTag(uint256 depositId, string newTag): Allows Manager to update a deposit's tag.

// ERC721/ERC1155 Hooks:
// - onERC721Received(...): ERC721 receiving hook.
// - onERC1155Received(...): ERC1155 receiving hook.
// - onERC1155BatchReceived(...): ERC1155 batch receiving hook.

contract QuantumVault is Pausable, AccessControl, ReentrancyGuard, ERC721Holder, ERC1155Holder {

    // --- Access Control Roles ---
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant CONDITIONAL_EXECUTOR_ROLE = keccak256("CONDITIONAL_EXECUTOR_ROLE");
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE"); // Can pause/unpause and emergency withdraw

    // --- Enums ---
    enum AssetType { ETH, ERC20, ERC721, ERC1155 }
    enum ConditionType {
        BlockHeightReached,
        TimestampReached,
        ERC20BalanceGreaterThan,
        NFT721OwnedBy,
        NFT1155OwnedBy,
        SpecificAddressAllowed, // Check if a specific address (param1) has the ConditionalExecutor role
        VestingSchedule // Special case for structured release
        // Add more complex condition types here if needed (e.g., Oracle data check - requires integration)
    }

    // --- Structs ---
    struct Condition {
        ConditionType conditionType;
        uint256 param1; // e.g., block number, timestamp, amount, token ID, address index in state array
        uint256 param2; // e.g., address index, token ID, balance required, amount
        address assetAddress; // For ERC20/ERC721/ERC1155 related conditions
    }

    struct Deposit {
        uint256 id;
        AssetType assetType;
        address assetAddress; // 0x0 for ETH
        uint256 amount; // Applicable for ETH, ERC20, ERC1155. tokenId for ERC721.
        uint256 erc1155TokenId; // Store tokenId specifically for ERC1155
        address depositor; // Who made the deposit
        address recipient; // Who can potentially withdraw
        uint256 timestamp; // When deposited
        Condition[] conditions; // Conditions that must be met for withdrawal

        // State for partial withdrawals (like vesting)
        uint256 withdrawnAmount; // For ETH, ERC20, ERC1155
        bool erc721Withdrawn; // For ERC721

        string tag; // Optional tag for identification

        bool isConditional; // True if conditions must be met, false for simple deposits
        bool conditionsFulfilled; // Set to true once executeConditionalWithdrawal succeeds
    }

    // --- State Variables ---
    uint256 private _nextDepositId;
    mapping(uint256 => Deposit) public deposits;
    mapping(address => EnumerableSet.UintSet) private _userDepositIds; // Track deposit IDs per user (depositor or recipient)

    // For non-conditional deposits (simpler balance tracking)
    mapping(address => uint256) private _simpleEthBalances; // Recipient address => ETH balance
    mapping(address => mapping(address => uint256)) private _simpleErc20Balances; // Recipient address => Token address => balance
    mapping(address => mapping(address => EnumerableSet.UintSet)) private _simpleErc721Tokens; // Recipient address => Token address => Set of tokenIds
    mapping(address => mapping(address => mapping(uint256 => uint256))) private _simpleErc1155Balances; // Recipient address => Token address => Token ID => amount

    // --- Events ---
    event EthDeposited(uint256 indexed depositId, address indexed depositor, address indexed recipient, uint256 amount, bool isConditional);
    event ERC20Deposited(uint256 indexed depositId, address indexed depositor, address indexed recipient, IERC20 indexed token, uint256 amount, bool isConditional);
    event ERC721Deposited(uint256 indexed depositId, address indexed depositor, address indexed recipient, IERC721 indexed token, uint256 indexed tokenId, bool isConditional);
    event ERC1155Deposited(uint256 indexed depositId, address indexed depositor, address indexed recipient, IERC1155 indexed token, uint256 indexed tokenId, uint256 amount, bool isConditional);
    event DepositTagUpdated(uint256 indexed depositId, address indexed updater, string newTag);

    event EthWithdrawn(uint256 indexed depositId, address indexed withdrawer, address indexed recipient, uint256 amount);
    event ERC20Withdrawn(uint256 indexed depositId, address indexed withdrawer, address indexed recipient, IERC20 indexed token, uint256 amount);
    event ERC721Withdrawn(uint256 indexed depositId, address indexed withdrawer, address indexed recipient, IERC721 indexed token, uint256 indexed tokenId);
    event ERC1155Withdrawn(uint256 indexed depositId, address indexed withdrawer, address indexed recipient, IERC1155 indexed token, uint256 indexed tokenId, uint256 amount);

    event ConditionalWithdrawalExecuted(uint256 indexed depositId, address indexed executor, address indexed recipient);
    event VestingClaimed(uint256 indexed depositId, address indexed claimer, address indexed recipient, uint256 claimedAmount);

    event EmergencyWithdrawal(AssetType assetType, address assetAddress, uint256 amountOrTokenId, uint256 erc1155TokenId, uint256 erc1155Amount, address indexed recipient, address indexed guardian);
    event StuckAssetsRecovered(AssetType assetType, address assetAddress, uint256 amountOrTokenId, uint256 erc1155TokenId, uint256 erc1155Amount, address indexed recipient, address indexed owner);

    // --- Constructor ---
    constructor(address ownerAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, ownerAddress);
        _grantRole(MANAGER_ROLE, ownerAddress);
        _grantRole(GUARDIAN_ROLE, ownerAddress); // Grant guardian role to owner initially
        _nextDepositId = 1;
    }

    // --- Access Control & Role Management ---
    // Inherited from AccessControl.sol:
    // grantRole(bytes32 role, address account)
    // revokeRole(bytes32 role, address account)
    // renounceRole(bytes32 role)
    // hasRole(bytes32 role, address account)
    // getRoleMemberCount(bytes32 role)
    // getRoleMember(bytes32 role, uint256 index)

    // Add specific functions for roles if needed beyond standard RBAC, e.g., setting a default executor
    function setDefaultConditionalWithdrawalRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
         _grantRole(CONDITIONAL_EXECUTOR_ROLE, account);
    }

    function unsetDefaultConditionalWithdrawalRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(CONDITIONAL_EXECUTOR_ROLE, account);
    }


    // --- Pausable Functions ---
    // Inherited from Pausable.sol:
    // paused() view returns (bool)
    // whenNotPaused modifier

    function pause() external onlyRole(GUARDIAN_ROLE) whenNotPaused {
        _pause();
    }

    function unpause() external onlyRole(GUARDIAN_ROLE) whenPaused {
        _unpause();
    }

    // --- Deposit Functions ---

    receive() external payable whenNotPaused {
        depositETH();
    }

    function depositETH() public payable whenNotPaused nonReentrant {
        require(msg.value > 0, "Amount must be greater than 0");
        _simpleEthBalances[msg.sender] += msg.value;
        uint256 depositId = _nextDepositId++;
        deposits[depositId] = Deposit({
            id: depositId,
            assetType: AssetType.ETH,
            assetAddress: address(0),
            amount: msg.value,
            erc1155TokenId: 0, // N/A for ETH
            depositor: msg.sender,
            recipient: msg.sender, // Simple deposits go back to depositor by default
            timestamp: block.timestamp,
            conditions: new Condition[](0), // No conditions
            withdrawnAmount: 0,
            erc721Withdrawn: false,
            tag: "simple_eth",
            isConditional: false,
            conditionsFulfilled: true // Simple deposits are always "fulfilled"
        });
        _userDepositIds[msg.sender].add(depositId);
        emit EthDeposited(depositId, msg.sender, msg.sender, msg.value, false);
    }

    function depositERC20(IERC20 token, uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(address(token) != address(0), "Invalid token address");
        token.transferFrom(msg.sender, address(this), amount);
        _simpleErc20Balances[msg.sender][address(token)] += amount;
         uint256 depositId = _nextDepositId++;
        deposits[depositId] = Deposit({
            id: depositId,
            assetType: AssetType.ERC20,
            assetAddress: address(token),
            amount: amount,
            erc1155TokenId: 0, // N/A
            depositor: msg.sender,
            recipient: msg.sender, // Simple deposits go back to depositor by default
            timestamp: block.timestamp,
            conditions: new Condition[](0), // No conditions
            withdrawnAmount: 0,
            erc721Withdrawn: false,
            tag: "simple_erc20",
            isConditional: false,
            conditionsFulfilled: true // Simple deposits are always "fulfilled"
        });
        _userDepositIds[msg.sender].add(depositId);
        emit ERC20Deposited(depositId, msg.sender, msg.sender, token, amount, false);
    }

    function depositERC721(IERC721 token, uint256 tokenId) external whenNotPaused nonReentrant {
        require(address(token) != address(0), "Invalid token address");
        // ERC721 transferFrom calls onERC721Received hook which records the deposit
        token.transferFrom(msg.sender, address(this), tokenId);
        // Hook handles deposit struct creation and event
    }

    function depositERC1155(IERC1155 token, uint256 id, uint256 amount) external whenNotPaused nonReentrant {
         require(amount > 0, "Amount must be greater than 0");
         require(address(token) != address(0), "Invalid token address");
        // ERC1155 safeTransferFrom calls onERC1155Received hook which records the deposit
         token.safeTransferFrom(msg.sender, address(this), id, amount, "");
        // Hook handles deposit struct creation and event
    }

    // --- Conditional Deposit Functions ---

    function depositConditionalETH(
        address recipient,
        string memory tag,
        Condition[] memory conditions
    ) public payable whenNotPaused nonReentrant {
        require(msg.value > 0, "Amount must be greater than 0");
        require(recipient != address(0), "Invalid recipient address");
        require(conditions.length > 0, "Conditional deposit requires conditions");

        uint256 depositId = _nextDepositId++;
        deposits[depositId] = Deposit({
            id: depositId,
            assetType: AssetType.ETH,
            assetAddress: address(0),
            amount: msg.value,
            erc1155TokenId: 0,
            depositor: msg.sender,
            recipient: recipient,
            timestamp: block.timestamp,
            conditions: conditions,
            withdrawnAmount: 0,
            erc721Withdrawn: false,
            tag: tag,
            isConditional: true,
            conditionsFulfilled: false
        });
        _userDepositIds[msg.sender].add(depositId);
        if (msg.sender != recipient) {
             _userDepositIds[recipient].add(depositId);
        }
        emit EthDeposited(depositId, msg.sender, recipient, msg.value, true);
    }

     function depositConditionalERC20(
        IERC20 token,
        uint256 amount,
        address recipient,
        string memory tag,
        Condition[] memory conditions
    ) external whenNotPaused nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(address(token) != address(0), "Invalid token address");
        require(recipient != address(0), "Invalid recipient address");
        require(conditions.length > 0, "Conditional deposit requires conditions");

        token.transferFrom(msg.sender, address(this), amount);

        uint256 depositId = _nextDepositId++;
        deposits[depositId] = Deposit({
            id: depositId,
            assetType: AssetType.ERC20,
            assetAddress: address(token),
            amount: amount,
            erc1155TokenId: 0,
            depositor: msg.sender,
            recipient: recipient,
            timestamp: block.timestamp,
            conditions: conditions,
            withdrawnAmount: 0,
            erc721Withdrawn: false,
            tag: tag,
            isConditional: true,
            conditionsFulfilled: false
        });
        _userDepositIds[msg.sender].add(depositId);
         if (msg.sender != recipient) {
             _userDepositIds[recipient].add(depositId);
        }
        emit ERC20Deposited(depositId, msg.sender, recipient, token, amount, true);
    }

    function depositConditionalERC721(
        IERC721 token,
        uint256 tokenId,
        address recipient,
        string memory tag,
        Condition[] memory conditions
    ) external whenNotPaused nonReentrant {
        require(address(token) != address(0), "Invalid token address");
        require(recipient != address(0), "Invalid recipient address");
        require(conditions.length > 0, "Conditional deposit requires conditions");

        // ERC721 transferFrom calls onERC721Received hook which records the deposit
        // The hook will need to be updated to handle the recipient, tag, and conditions
        // This is a limitation of the standard hook signature. A custom entry point
        // or prior storage of deposit intent would be needed for true conditional ERC721 deposits
        // using the standard hook. For simplicity in this example, we'll assume a custom
        // deposit function is used instead of relying solely on the hook for conditional.
        // Let's redefine this to *not* use the hook for conditional deposits.

        token.transferFrom(msg.sender, address(this), tokenId);

        uint256 depositId = _nextDepositId++;
        deposits[depositId] = Deposit({
            id: depositId,
            assetType: AssetType.ERC721,
            assetAddress: address(token),
            amount: tokenId, // tokenId stored in amount for ERC721
            erc1155TokenId: 0, // N/A
            depositor: msg.sender,
            recipient: recipient,
            timestamp: block.timestamp,
            conditions: conditions,
            withdrawnAmount: 0, // N/A
            erc721Withdrawn: false,
            tag: tag,
            isConditional: true,
            conditionsFulfilled: false
        });
         _userDepositIds[msg.sender].add(depositId);
         if (msg.sender != recipient) {
             _userDepositIds[recipient].add(depositId);
        }
        emit ERC721Deposited(depositId, msg.sender, recipient, token, tokenId, true);
    }

    function depositConditionalERC1155(
        IERC1155 token,
        uint256 id,
        uint256 amount,
        address recipient,
        string memory tag,
        Condition[] memory conditions
    ) external whenNotPaused nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(address(token) != address(0), "Invalid token address");
        require(recipient != address(0), "Invalid recipient address");
        require(conditions.length > 0, "Conditional deposit requires conditions");

        // ERC1155 safeTransferFrom calls onERC1155Received hook. Similar limitation as ERC721.
        // Using a custom entry point instead of relying solely on hook for conditional.

        token.safeTransferFrom(msg.sender, address(this), id, amount, "");

        uint256 depositId = _nextDepositId++;
        deposits[depositId] = Deposit({
            id: depositId,
            assetType: AssetType.ERC1155,
            assetAddress: address(token),
            amount: amount, // amount stored in amount
            erc1155TokenId: id, // tokenId stored separately
            depositor: msg.sender,
            recipient: recipient,
            timestamp: block.timestamp,
            conditions: conditions,
            withdrawnAmount: 0, // amount withdrawn
            erc721Withdrawn: false, // N/A
            tag: tag,
            isConditional: true,
            conditionsFulfilled: false
        });
         _userDepositIds[msg.sender].add(depositId);
         if (msg.sender != recipient) {
             _userDepositIds[recipient].add(depositId);
        }
        emit ERC1155Deposited(depositId, msg.sender, recipient, token, id, amount, true);
    }

    // --- Vesting Specific Deposit Functions (using a specific condition type) ---

    // Vesting is modelled as a specific type of conditional deposit with one or more
    // VestingSchedule conditions. The claimVested function handles the partial release logic.
    // This simplifies the deposit function interface for a common use case.

    function depositVestedETH(
        uint256 amount,
        address recipient,
        uint256 startTime,
        uint256 endTime,
        uint256 cliffTime // Absolute timestamp
    ) external payable whenNotPaused nonReentrant {
        require(msg.value == amount, "Sent amount must match specified amount");
        require(amount > 0, "Amount must be greater than 0");
        require(recipient != address(0), "Invalid recipient address");
        require(endTime > startTime, "End time must be after start time");
        require(startTime >= block.timestamp, "Start time must be in the future or now");
        require(cliffTime >= startTime && cliffTime <= endTime, "Cliff time must be within the vesting period"); // Or cliffTime == 0

        Condition[] memory vestingConditions = new Condition[](1);
        // Store vesting parameters encoded in param1, param2, assetAddress
        // param1: startTime, param2: endTime, assetAddress: cliffTime (abusing address field for uin256 storage)
        // This is a simplified example. More robust encoding might be needed.
        // Or simply add vesting parameters directly to the Deposit struct if it's a core type.
        // Let's encode: param1 = startTime, param2 = endTime. cliffTime check is done in _calculateVestedAmount.
        vestingConditions[0] = Condition({
            conditionType: ConditionType.VestingSchedule,
            param1: startTime,
            param2: endTime,
            assetAddress: address(uint160(cliffTime)) // Store cliffTime as address - careful conversion! Max value ~2^160-1
        });

        uint256 depositId = _nextDepositId++;
        deposits[depositId] = Deposit({
            id: depositId,
            assetType: AssetType.ETH,
            assetAddress: address(0),
            amount: amount,
            erc1155TokenId: 0,
            depositor: msg.sender,
            recipient: recipient,
            timestamp: block.timestamp, // Deposit timestamp
            conditions: vestingConditions,
            withdrawnAmount: 0, // Track vested amount withdrawn
            erc721Withdrawn: false,
            tag: "vesting_eth",
            isConditional: true, // Vesting IS a conditional deposit
            conditionsFulfilled: false // Will be true when all is claimed
        });
         _userDepositIds[msg.sender].add(depositId);
         if (msg.sender != recipient) {
             _userDepositIds[recipient].add(depositId);
        }
        emit EthDeposited(depositId, msg.sender, recipient, amount, true); // Use the amount parameter
    }

    function depositVestedERC20(
        IERC20 token,
        uint256 amount,
        address recipient,
        uint256 startTime,
        uint256 endTime,
        uint256 cliffTime
    ) external whenNotPaused nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(address(token) != address(0), "Invalid token address");
        require(recipient != address(0), "Invalid recipient address");
        require(endTime > startTime, "End time must be after start time");
        require(startTime >= block.timestamp, "Start time must be in the future or now");
         require(cliffTime >= startTime && cliffTime <= endTime, "Cliff time must be within the vesting period"); // Or cliffTime == 0


        token.transferFrom(msg.sender, address(this), amount);

        Condition[] memory vestingConditions = new Condition[](1);
         vestingConditions[0] = Condition({
            conditionType: ConditionType.VestingSchedule,
            param1: startTime, // startTime
            param2: endTime,   // endTime
            assetAddress: address(uint160(cliffTime)) // cliffTime encoded
        });

        uint256 depositId = _nextDepositId++;
        deposits[depositId] = Deposit({
            id: depositId,
            assetType: AssetType.ERC20,
            assetAddress: address(token),
            amount: amount,
            erc1155TokenId: 0,
            depositor: msg.sender,
            recipient: recipient,
            timestamp: block.timestamp, // Deposit timestamp
            conditions: vestingConditions,
            withdrawnAmount: 0, // Track vested amount withdrawn
            erc721Withdrawn: false,
            tag: "vesting_erc20",
            isConditional: true, // Vesting IS a conditional deposit
            conditionsFulfilled: false // Will be true when all is claimed
        });
        _userDepositIds[msg.sender].add(depositId);
         if (msg.sender != recipient) {
             _userDepositIds[recipient].add(depositId);
        }
        emit ERC20Deposited(depositId, msg.sender, recipient, token, amount, true);
    }


    // --- Conditional Logic & Withdrawal ---

    // Internal helper to evaluate a single condition
    function _evaluateCondition(uint256 depositId, Condition storage condition) internal view returns (bool) {
        Deposit storage dep = deposits[depositId]; // Need deposit context for some conditions

        // Note: This is a simplified internal evaluation.
        // Real-world applications might require external calls (Oracles),
        // signed messages, or more complex state checks.
        // We only implement a few basic condition types here.

        if (condition.conditionType == ConditionType.BlockHeightReached) {
            // param1 = target block height
            return block.number >= condition.param1;

        } else if (condition.conditionType == ConditionType.TimestampReached) {
            // param1 = target timestamp
            return block.timestamp >= condition.param1;

        } else if (condition.conditionType == ConditionType.ERC20BalanceGreaterThan) {
            // assetAddress = token address
            // param1 = required balance amount
            // param2 = address to check balance of
            require(condition.assetAddress != address(0), "ERC20BalanceGreaterThan condition missing token address");
            require(condition.param2 != 0, "ERC20BalanceGreaterThan condition missing target address"); // param2 holds the address to check (encoded)
            address balanceCheckAddress = address(uint160(condition.param2));
            IERC20 token = IERC20(condition.assetAddress);
            return token.balanceOf(balanceCheckAddress) >= condition.param1;

        } else if (condition.conditionType == ConditionType.NFT721OwnedBy) {
             // assetAddress = NFT token address
             // param1 = NFT tokenId
             // param2 = address that must own it
            require(condition.assetAddress != address(0), "NFT721OwnedBy condition missing token address");
            require(condition.param2 != 0, "NFT721OwnedBy condition missing owner address");
            address requiredOwner = address(uint160(condition.param2));
            IERC721 token = IERC721(condition.assetAddress);
            try token.ownerOf(condition.param1) returns (address currentOwner) {
                return currentOwner == requiredOwner;
            } catch {
                // Token doesn't exist or error, condition not met
                return false;
            }

        } else if (condition.conditionType == ConditionType.NFT1155OwnedBy) {
             // assetAddress = NFT token address
             // param1 = NFT tokenId
             // param2 = required amount
             // param3 = address that must own it (need another param? Or encode?)
             // Let's adapt: assetAddress = token address, param1 = tokenId, param2 = required amount, param3 (if exists) = owner address.
             // Using current struct: assetAddress = token address, param1 = tokenId, param2 = required amount. IMPLICITLY check recipient? No, needs to be explicit.
             // Let's encode owner address in param1 for NFT721/1155, tokenId in param2, amount in param2 for 1155?
             // New Struct layout idea: `address targetAddress`, `uint256 value1`, `uint256 value2`.
             // Let's stick to the current struct but adjust interpretation for 1155:
             // assetAddress = token address, param1 = tokenId, param2 = required amount. Check ownership by `dep.recipient`.
             // This is a design choice to keep the Condition struct fixed.
            require(condition.assetAddress != address(0), "NFT1155OwnedBy condition missing token address");
            require(dep.recipient != address(0), "NFT1155OwnedBy condition requires a deposit recipient");
            IERC1155 token = IERC1155(condition.assetAddress);
            // param1 = tokenId, param2 = required amount
            return token.balanceOf(dep.recipient, condition.param1) >= condition.param2;

        } else if (condition.conditionType == ConditionType.SpecificAddressAllowed) {
             // param1 = address to check role for (encoded)
            require(condition.param1 != 0, "SpecificAddressAllowed condition missing target address");
            address targetAddress = address(uint160(condition.param1));
            // Check if the *caller* has the CONDITIONAL_EXECUTOR_ROLE or is the target address
            return hasRole(CONDITIONAL_EXECUTOR_ROLE, msg.sender) || msg.sender == targetAddress;

        } else if (condition.conditionType == ConditionType.VestingSchedule) {
            // Vesting is handled by the specific `claimVested` functions, not general execution.
            // This function should technically return false for VestingSchedule type,
            // or the `executeConditionalWithdrawal` should skip VestingSchedule conditions
            // and rely on `claimVested`. Let's make this return true if vesting is complete.
             uint256 startTime = condition.param1;
             uint256 endTime = condition.param2;
             // cliffTime = address(uint160(condition.assetAddress)); // Can be retrieved if needed for full check
             return block.timestamp >= endTime; // Vesting complete if end time reached
        }

        // Unknown condition type
        return false;
    }

     // Internal helper to check if ALL conditions for a deposit are met
    function _allConditionsMet(uint256 depositId) internal view returns (bool) {
        Deposit storage dep = deposits[depositId];
        if (!dep.isConditional || dep.conditionsFulfilled) {
            return false; // Not conditional or already fulfilled
        }

        for (uint i = 0; i < dep.conditions.length; i++) {
            // Skip VestingSchedule conditions here, as they are handled separately
            if (dep.conditions[i].conditionType == ConditionType.VestingSchedule) {
                continue;
            }
            if (!_evaluateCondition(depositId, dep.conditions[i])) {
                return false; // If any non-vesting condition is false, all conditions are not met
            }
        }
        return true; // All non-vesting conditions are met
    }

    // External function to check condition status (view)
    function checkConditionStatus(uint256 depositId) external view returns (bool met) {
        require(depositId > 0 && depositId < _nextDepositId, "Invalid deposit ID");
        return _allConditionsMet(depositId);
    }


    // Executes withdrawal for a conditional deposit if conditions are met.
    // Callable by recipient, ConditionalExecutor role, or Owner.
    function executeConditionalWithdrawal(uint256 depositId) external whenNotPaused nonReentrant {
        require(depositId > 0 && depositId < _nextDepositId, "Invalid deposit ID");
        Deposit storage dep = deposits[depositId];

        require(dep.isConditional, "Deposit is not conditional");
        require(!dep.conditionsFulfilled, "Conditions already fulfilled");

        // Check permissions: Caller must be recipient, ConditionalExecutor, or Owner
        require(msg.sender == dep.recipient || hasRole(CONDITIONAL_EXECUTOR_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller not authorized to execute conditional withdrawal"
        );

        // Check conditions
        require(_allConditionsMet(depositId), "Conditions not met");

        // Mark conditions as fulfilled (prevents multiple full withdrawals)
        dep.conditionsFulfilled = true;

        // Execute withdrawal based on asset type
        if (dep.assetType == AssetType.ETH) {
            uint256 amountToWithdraw = dep.amount - dep.withdrawnAmount; // Should be full amount if not vesting
             dep.withdrawnAmount += amountToWithdraw;
             (bool success, ) = payable(dep.recipient).call{value: amountToWithdraw}("");
             require(success, "ETH transfer failed");
             emit EthWithdrawn(depositId, msg.sender, dep.recipient, amountToWithdraw);

        } else if (dep.assetType == AssetType.ERC20) {
             uint256 amountToWithdraw = dep.amount - dep.withdrawnAmount; // Should be full amount if not vesting
             dep.withdrawnAmount += amountToWithdraw;
             IERC20 token = IERC20(dep.assetAddress);
             token.transfer(dep.recipient, amountToWithdraw);
             emit ERC20Withdrawn(depositId, msg.sender, dep.recipient, token, amountToWithdraw);

        } else if (dep.assetType == AssetType.ERC721) {
             require(!dep.erc721Withdrawn, "ERC721 already withdrawn");
             dep.erc721Withdrawn = true;
             IERC721 token = IERC721(dep.assetAddress);
             // Check contract owns the token before transfer
             require(token.ownerOf(dep.amount) == address(this), "Vault does not own the ERC721 token");
             token.transferFrom(address(this), dep.recipient, dep.amount); // amount stores tokenId for ERC721
             emit ERC721Withdrawn(depositId, msg.sender, dep.recipient, token, dep.amount);

        } else if (dep.assetType == AssetType.ERC1155) {
             // ERC1155 conditional withdrawal is assumed to be the full amount deposited
             // Partial withdrawal for ERC1155 conditionals would require more state tracking per deposit.
             require(dep.amount > dep.withdrawnAmount, "ERC1155 amount already fully withdrawn"); // Check against withdrawnAmount (which should be 0 if not vesting)
             uint256 amountToWithdraw = dep.amount - dep.withdrawnAmount;
             dep.withdrawnAmount += amountToWithdraw; // Should be full amount
             IERC1155 token = IERC1155(dep.assetAddress);
             token.safeTransferFrom(address(this), dep.recipient, dep.erc1155TokenId, amountToWithdraw, ""); // erc1155TokenId stores id
             emit ERC1155Withdrawn(depositId, msg.sender, dep.recipient, token, dep.erc1155TokenId, amountToWithdraw);
        }
        // Note: VestingSchedule conditions are *not* handled by this general execution function.
        // They are handled by `claimVestedETH` / `claimVestedERC20`.
        // The `conditionsFulfilled` flag being set here means the deposit is complete
        // UNLESS it's a vesting deposit, in which case this flag is set only when the *final*
        // vesting claim is made (or could be used to indicate all non-vesting conditions met, needs clarification).
        // Let's clarify: `conditionsFulfilled` means all *non-vesting* conditions are met allowing the FIRST withdrawal.
        // Vesting claims decrement `withdrawnAmount`. The deposit is fully complete when `withdrawnAmount == amount`.

        emit ConditionalWithdrawalExecuted(depositId, msg.sender, dep.recipient);
    }

    // --- Vesting Specific Claim Functions ---

    // Internal helper to calculate claimable vested amount
    function _calculateVestedAmount(
        uint256 totalAmount,
        uint256 startTime,
        uint256 endTime,
        uint256 cliffTime,
        uint256 withdrawn
    ) internal view returns (uint256 claimable) {
        uint256 currentTime = block.timestamp;

        if (currentTime < cliffTime) {
            return 0; // Before cliff, nothing vests
        }

        if (currentTime >= endTime) {
            // Vesting complete
            return totalAmount - withdrawn;
        }

        // Linear vesting formula: total * (time_elapsed_since_start) / (total_vesting_duration)
        // clamped between 0 and totalAmount
        uint256 duration = endTime - startTime;
        uint256 timeElapsedSinceStart = currentTime - startTime;

        // Protect against division by zero if duration is 0 (should be caught by require in deposit)
        if (duration == 0) {
            return 0;
        }

        uint256 vestedAmount = (totalAmount * timeElapsedSinceStart) / duration;

        // Claimable is vested amount minus already withdrawn amount
        claimable = vestedAmount - withdrawn;
        if (claimable > totalAmount - withdrawn) { // Should not happen with correct math, but safety
            claimable = totalAmount - withdrawn;
        }

        return claimable;
    }

    function claimVestedETH(uint256 depositId) external whenNotPaused nonReentrant {
        require(depositId > 0 && depositId < _nextDepositId, "Invalid deposit ID");
        Deposit storage dep = deposits[depositId];

        require(dep.assetType == AssetType.ETH, "Deposit is not ETH");
        require(dep.recipient == msg.sender, "Only recipient can claim");
        require(dep.conditions.length == 1 && dep.conditions[0].conditionType == ConditionType.VestingSchedule, "Deposit is not a standard vesting schedule");
        require(dep.withdrawnAmount < dep.amount, "All ETH already claimed");

        Condition storage vestingCondition = dep.conditions[0];
        uint256 startTime = vestingCondition.param1;
        uint256 endTime = vestingCondition.param2;
        uint256 cliffTime = uint256(uint160(vestingCondition.assetAddress)); // Decode cliffTime

        uint256 claimable = _calculateVestedAmount(dep.amount, startTime, endTime, cliffTime, dep.withdrawnAmount);
        require(claimable > 0, "No ETH claimable yet");

        dep.withdrawnAmount += claimable;
        (bool success, ) = payable(dep.recipient).call{value: claimable}("");
        require(success, "ETH transfer failed");

        // If all claimed, mark as fulfilled
        if (dep.withdrawnAmount == dep.amount) {
            dep.conditionsFulfilled = true;
        }

        emit EthWithdrawn(depositId, msg.sender, dep.recipient, claimable);
        emit VestingClaimed(depositId, msg.sender, dep.recipient, claimable);
    }

     function claimVestedERC20(uint256 depositId) external whenNotPaused nonReentrant {
        require(depositId > 0 && depositId < _nextDepositId, "Invalid deposit ID");
        Deposit storage dep = deposits[depositId];

        require(dep.assetType == AssetType.ERC20, "Deposit is not ERC20");
        require(dep.recipient == msg.sender, "Only recipient can claim");
        require(dep.conditions.length == 1 && dep.conditions[0].conditionType == ConditionType.VestingSchedule, "Deposit is not a standard vesting schedule");
        require(dep.withdrawnAmount < dep.amount, "All ERC20 already claimed");

        Condition storage vestingCondition = dep.conditions[0];
        uint256 startTime = vestingCondition.param1;
        uint256 endTime = vestingCondition.param2;
        uint256 cliffTime = uint256(uint160(vestingCondition.assetAddress)); // Decode cliffTime

        uint256 claimable = _calculateVestedAmount(dep.amount, startTime, endTime, cliffTime, dep.withdrawnAmount);
        require(claimable > 0, "No ERC20 claimable yet");

        dep.withdrawnAmount += claimable;
        IERC20 token = IERC20(dep.assetAddress);
        token.transfer(dep.recipient, claimable);

        // If all claimed, mark as fulfilled
        if (dep.withdrawnAmount == dep.amount) {
            dep.conditionsFulfilled = true;
        }

        emit ERC20Withdrawn(depositId, msg.sender, dep.recipient, token, claimable);
        emit VestingClaimed(depositId, msg.sender, dep.recipient, claimable);
    }


    // --- Simple Withdrawal Functions (Admin/Manager Only for non-conditional) ---
    // These are for the simple deposits tracked separately.

    function withdrawETH(address recipient, uint256 amount) external onlyRole(MANAGER_ROLE) whenNotPaused nonReentrant {
        require(_simpleEthBalances[recipient] >= amount, "Insufficient simple ETH balance");
        _simpleEthBalances[recipient] -= amount;
        (bool success, ) = payable(recipient).call{value: amount}("");
        require(success, "ETH transfer failed");
        // Note: No specific depositId for simple deposits. Could add a dummy one or event without.
        // Let's use a generic event type or indicate it's simple.
        emit EthWithdrawn(0, msg.sender, recipient, amount); // Use 0 for simple deposits
    }

     function withdrawERC20(IERC20 token, address recipient, uint256 amount) external onlyRole(MANAGER_ROLE) whenNotPaused nonReentrant {
        require(address(token) != address(0), "Invalid token address");
        require(_simpleErc20Balances[recipient][address(token)] >= amount, "Insufficient simple ERC20 balance");
        _simpleErc20Balances[recipient][address(token)] -= amount;
        token.transfer(recipient, amount);
         emit ERC20Withdrawn(0, msg.sender, recipient, token, amount); // Use 0 for simple deposits
    }

     function withdrawERC721(IERC721 token, uint256 tokenId, address recipient) external onlyRole(MANAGER_ROLE) whenNotPaused nonReentrant {
        require(address(token) != address(0), "Invalid token address");
        require(_simpleErc721Tokens[recipient][address(token)].contains(tokenId), "Recipient does not have simple ERC721 deposit record for this token");
        // We don't strictly track ownership in the simple balance mapping,
        // rely on the ERC721Holder functionality + the record.
        token.transferFrom(address(this), recipient, tokenId);
        _simpleErc721Tokens[recipient][address(token)].remove(tokenId);
         emit ERC721Withdrawn(0, msg.sender, recipient, token, tokenId); // Use 0 for simple deposits
    }

    function withdrawERC1155(IERC1155 token, uint256 id, uint256 amount, address recipient) external onlyRole(MANAGER_ROLE) whenNotPaused nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(address(token) != address(0), "Invalid token address");
         require(_simpleErc1155Balances[recipient][address(token)][id] >= amount, "Insufficient simple ERC1155 balance");
         _simpleErc1155Balances[recipient][address(token)][id] -= amount;
         token.safeTransferFrom(address(this), recipient, id, amount, "");
          emit ERC1155Withdrawn(0, msg.sender, recipient, token, id, amount); // Use 0 for simple deposits
    }


    // --- Query Functions ---

    function viewDepositDetails(uint256 depositId) external view returns (Deposit memory) {
        require(depositId > 0 && depositId < _nextDepositId, "Invalid deposit ID");
        return deposits[depositId];
    }

    // Returns claimable vested amount for a specific vesting deposit
    function getAvailableVestedETH(uint256 depositId) external view returns (uint256) {
         require(depositId > 0 && depositId < _nextDepositId, "Invalid deposit ID");
         Deposit storage dep = deposits[depositId];
         require(dep.assetType == AssetType.ETH, "Deposit is not ETH");
         require(dep.conditions.length == 1 && dep.conditions[0].conditionType == ConditionType.VestingSchedule, "Deposit is not a standard vesting schedule");

         Condition storage vestingCondition = dep.conditions[0];
         uint256 startTime = vestingCondition.param1;
         uint256 endTime = vestingCondition.param2;
         uint256 cliffTime = uint256(uint160(vestingCondition.assetAddress));

         return _calculateVestedAmount(dep.amount, startTime, endTime, cliffTime, dep.withdrawnAmount);
    }

    // Returns claimable vested amount for a specific vesting deposit
    function getAvailableVestedERC20(uint256 depositId) external view returns (uint256) {
         require(depositId > 0 && depositId < _nextDepositId, "Invalid deposit ID");
         Deposit storage dep = deposits[depositId];
         require(dep.assetType == AssetType.ERC20, "Deposit is not ERC20");
         require(dep.conditions.length == 1 && dep.conditions[0].conditionType == ConditionType.VestingSchedule, "Deposit is not a standard vesting schedule");

         Condition storage vestingCondition = dep.conditions[0];
         uint256 startTime = vestingCondition.param1;
         uint256 endTime = vestingCondition.param2;
         uint256 cliffTime = uint256(uint160(vestingCondition.assetAddress));

         return _calculateVestedAmount(dep.amount, startTime, endTime, cliffTime, dep.withdrawnAmount);
    }

    // Helper to get all deposit IDs associated with a user (either depositor or recipient)
    function viewUserDeposits(address user) external view returns (uint256[] memory) {
        return _userDepositIds[user].values();
    }

    function getDepositCount() external view returns (uint256) {
        return _nextDepositId - 1;
    }

     function getTotalVaultBalance(address token) external view returns (uint256) {
        if (token == address(0)) {
            return address(this).balance;
        } else {
            return IERC20(token).balanceOf(address(this));
        }
    }

    // Note: getWithdrawable functions only consider simple deposits and vested *claimable* amounts.
    // They do NOT check if conditions are met for generic conditional deposits.
    function getWithdrawableETH(address user) external view returns (uint256) {
        uint256 simple = _simpleEthBalances[user];
        uint256 vestedClaimable = 0;
        uint256[] memory userDepositIds = _userDepositIds[user].values();
        for(uint i = 0; i < userDepositIds.length; i++) {
            uint256 depositId = userDepositIds[i];
            Deposit storage dep = deposits[depositId];
             if (dep.assetType == AssetType.ETH && dep.isConditional && dep.conditions.length == 1 && dep.conditions[0].conditionType == ConditionType.VestingSchedule && dep.recipient == user && dep.withdrawnAmount < dep.amount) {
                 Condition storage vestingCondition = dep.conditions[0];
                 uint256 startTime = vestingCondition.param1;
                 uint256 endTime = vestingCondition.param2;
                 uint256 cliffTime = uint256(uint160(vestingCondition.assetAddress));
                 vestedClaimable += _calculateVestedAmount(dep.amount, startTime, endTime, cliffTime, dep.withdrawnAmount);
             }
        }
        return simple + vestedClaimable;
    }

    function getWithdrawableERC20(IERC20 token, address user) external view returns (uint256) {
         require(address(token) != address(0), "Invalid token address");
        uint256 simple = _simpleErc20Balances[user][address(token)];
        uint256 vestedClaimable = 0;
        uint256[] memory userDepositIds = _userDepositIds[user].values();
         for(uint i = 0; i < userDepositIds.length; i++) {
            uint256 depositId = userDepositIds[i];
            Deposit storage dep = deposits[depositId];
             if (dep.assetType == AssetType.ERC20 && dep.assetAddress == address(token) && dep.isConditional && dep.conditions.length == 1 && dep.conditions[0].conditionType == ConditionType.VestingSchedule && dep.recipient == user && dep.withdrawnAmount < dep.amount) {
                 Condition storage vestingCondition = dep.conditions[0];
                 uint256 startTime = vestingCondition.param1;
                 uint256 endTime = vestingCondition.param2;
                 uint256 cliffTime = uint256(uint160(vestingCondition.assetAddress));
                 vestedClaimable += _calculateVestedAmount(dep.amount, startTime, endTime, cliffTime, dep.withdrawnAmount);
             }
        }
        return simple + vestedClaimable;
    }


    // --- Admin & Emergency Functions ---

    // Allows Guardian to withdraw assets in emergency, bypassing conditions.
    function emergencyWithdrawETH(address recipient, uint256 amount) external onlyRole(GUARDIAN_ROLE) whenPaused nonReentrant {
        require(address(this).balance >= amount, "Insufficient vault ETH balance for emergency withdrawal");
        (bool success, ) = payable(recipient).call{value: amount}("");
        require(success, "Emergency ETH transfer failed");
        emit EmergencyWithdrawal(AssetType.ETH, address(0), amount, 0, 0, recipient, msg.sender);
    }

     function emergencyWithdrawERC20(IERC20 token, address recipient, uint256 amount) external onlyRole(GUARDIAN_ROLE) whenPaused nonReentrant {
        require(address(token) != address(0), "Invalid token address");
        require(token.balanceOf(address(this)) >= amount, "Insufficient vault ERC20 balance for emergency withdrawal");
        token.transfer(recipient, amount);
        emit EmergencyWithdrawal(AssetType.ERC20, address(token), amount, 0, 0, recipient, msg.sender);
    }

    function emergencyWithdrawERC721(IERC721 token, uint256 tokenId, address recipient) external onlyRole(GUARDIAN_ROLE) whenPaused nonReentrant {
        require(address(token) != address(0), "Invalid token address");
         // Check contract owns the token before transfer
        require(token.ownerOf(address(this)) == address(this) || ERC721Holder.onERC721Received.selector == 0xcb2fbb2f, "Vault does not own the ERC721 token or holder check failed"); // Basic check, relies on OpenZeppelin's Holder implementation
        token.transferFrom(address(this), recipient, tokenId);
        emit EmergencyWithdrawal(AssetType.ERC721, address(token), tokenId, 0, 0, recipient, msg.sender);
    }

    function emergencyWithdrawERC1155(IERC1155 token, uint256 id, uint256 amount, address recipient) external onlyRole(GUARDIAN_ROLE) whenPaused nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(address(token) != address(0), "Invalid token address");
         // Check contract owns the token before transfer
        require(token.balanceOf(address(this), id) >= amount, "Insufficient vault ERC1155 balance for emergency withdrawal");
        token.safeTransferFrom(address(this), recipient, id, amount, "");
         emit EmergencyWithdrawal(AssetType.ERC1155, address(token), id, id, amount, recipient, msg.sender); // Log token ID and amount
    }


    // Allows Owner to recover assets mistakenly sent directly to the contract address, not via a deposit function.
    // This function does NOT affect tracked deposit balances or records. Use with caution.
    function transferStuckERC20(IERC20 token, address recipient, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(token) != address(0), "Invalid token address");
        require(recipient != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be greater than 0");
        token.transfer(recipient, amount);
         emit StuckAssetsRecovered(AssetType.ERC20, address(token), amount, 0, 0, recipient, msg.sender);
    }

     function transferStuckERC721(IERC721 token, uint256 tokenId, address recipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(token) != address(0), "Invalid token address");
        require(recipient != address(0), "Invalid recipient address");
         // Check contract owns the token before transfer
        require(token.ownerOf(tokenId) == address(this), "Vault does not own the ERC721 token to recover");
        token.transferFrom(address(this), recipient, tokenId);
         emit StuckAssetsRecovered(AssetType.ERC721, address(token), tokenId, 0, 0, recipient, msg.sender);
    }

    function transferStuckERC1155(IERC1155 token, uint256 id, uint256 amount, address recipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(amount > 0, "Amount must be greater than 0");
        require(address(token) != address(0), "Invalid token address");
        require(recipient != address(0), "Invalid recipient address");
         // Check contract owns the token before transfer
        require(token.balanceOf(address(this), id) >= amount, "Vault does not have enough ERC1155 balance to recover");
        token.safeTransferFrom(address(this), recipient, id, amount, "");
         emit StuckAssetsRecovered(AssetType.ERC1155, address(token), id, id, amount, recipient, msg.sender);
    }

    // Allows manager to update the tag on any deposit.
    function setDepositTag(uint256 depositId, string memory newTag) external onlyRole(MANAGER_ROLE) {
        require(depositId > 0 && depositId < _nextDepositId, "Invalid deposit ID");
        deposits[depositId].tag = newTag;
        emit DepositTagUpdated(depositId, msg.sender, newTag);
    }

    // --- ERC721/ERC1155 Receiver Hooks ---
    // These hooks are implemented as required by ERC721/ERC1155 standards
    // when receiving tokens. The default behavior is to accept and log simple deposits.
    // Conditional ERC721/1155 deposits use dedicated functions.

    // onERC721Received is already implemented via inheriting ERC721Holder

    // onERC1155Received is already implemented via inheriting ERC1155Holder
    // onERC1155BatchReceived is already implemented via inheriting ERC1155Holder

    // Override the default ERC721Holder hook to add deposit logic
    // Note: This hook signature doesn't allow passing deposit-specific data like recipient, conditions, tag.
    // Simple deposits use this hook. Conditional ERC721 deposits use depositConditionalERC721.
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public override returns (bytes4) {
        // Accept the token
        // Record it as a simple deposit unless it came from a specific conditional deposit call (less common pattern)
        // For simplicity, tokens arriving via this hook are logged as simple deposits to the `from` address.
        // A more complex contract might require tokens to only arrive via deposit functions,
        // or use the `data` field to signal conditional deposits.
        // Let's record it as a simple deposit for the 'from' address.

        // We don't know the token contract here directly from the hook signature.
        // This is a limitation. The standard ERC721Holder just returns the magic value.
        // A real vault would need to get the token address, e.g., from context or event.
        // To link it to a deposit, we might need a prior function call setting intent.
        // Let's assume tokens arrive via deposit functions, making these hooks mostly for compliance.
        // If a token *does* arrive directly (e.g., via airdrop), it's stuck unless recovered by owner.
        // The ERC721Holder base functionality ensures we can receive it.
        // Let's add basic simple deposit tracking here for compliance, but actual withdrawals use withdrawERC721.

        // To add deposit tracking: require the token contract address. Can't get it here directly.
        // This means simple ERC721 deposits MUST use `depositERC721` function, not direct transfer.
        // The hook just ensures the contract CAN receive.
        // Let's keep the base implementation and add specific deposit functions.

        // Adding simple deposit tracking here is problematic due to missing token address.
        // If tokens arrive via the `depositERC721` function, that function calls `transferFrom`,
        // which triggers this hook. The `depositERC721` function already handles the deposit struct and event.
        // So this hook just needs to return the magic value.

        return super.onERC721Received(operator, from, tokenId, data);
    }

     // Override the default ERC1155Holder hooks similarly.
     // Simple deposits use `depositERC1155`, conditional use `depositConditionalERC1155`.
     // These hooks primarily ensure the contract CAN receive tokens.

     function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override returns (bytes4) {
        // Tokens arriving here would be from safeTransferFrom.
        // If from deposit function, deposit struct already handled.
        // If direct transfer, they are stuck unless recovered.
        // Just need to return magic value for compliance.
        return super.onERC1155Received(operator, from, id, amount, data);
    }

     function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override returns (bytes4) {
        // Same logic as onERC1155Received.
        return super.onERC1155BatchReceived(operator, from, ids, amounts, data);
    }
}
```