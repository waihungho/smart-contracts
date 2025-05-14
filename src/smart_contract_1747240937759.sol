Okay, let's design an interesting, advanced, and creative smart contract focusing on *Temporal Asset Management* with complex release conditions and granular roles. We'll call it `ChronoVault`.

The core idea is a vault that can hold various assets (ETH, ERC20, ERC721) and release them to recipients based on sophisticated, time-dependent rules, potentially involving periodic releases, emergency overrides, and rule management by specific roles.

This contract goes beyond basic time locks or vesting schedules by allowing multiple rules per asset, different asset types, flexible rule parameters (start, release, expiry, duration, interval), role-based rule management, and emergency release capabilities.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IERC20.sol"; // Assume standard ERC20 interface
import "./interfaces/IERC721.sol"; // Assume standard ERC721 interface

// --- ChronoVault Smart Contract ---
// Purpose: Manages assets (ETH, ERC20, ERC721) held in escrow with complex, time-based release rules.
// Allows for single release times, periodic vesting-like schedules, rule management by specific roles,
// and emergency release capabilities.

// --- Outline ---
// 1. State Variables & Data Structures
//    - Enums for Asset Types and Roles
//    - Struct for defining Release Rules
//    - Mappings for storing rules, asset balances, roles
//    - Counter for unique rule IDs
// 2. Events
//    - Notifications for Rule creation, updates, cancellation, deposits, claims, role changes.
// 3. Modifiers
//    - Access control based on roles.
// 4. Constructor
//    - Initializes the contract owner.
// 5. Role Management Functions
//    - Grant, revoke, renounce roles.
// 6. Rule Management Functions
//    - Create, update, cancel, activate, deactivate rules.
// 7. Deposit Functions
//    - Deposit ETH, ERC20, ERC721 linked to specific rules (new or existing).
// 8. Claiming Functions
//    - Claim assets based on rule conditions. Handles single and periodic releases.
// 9. Emergency & Override Functions
//    - Functions for specific roles to bypass standard time rules.
// 10. View Functions
//    - Get rule details, asset balances, claimable amounts, role information.

// --- Function Summary ---
// 1.  constructor() - Deploys the contract and sets the initial owner.
// 2.  grantRole(Role role, address account) - Grants a specific role to an address (Owner only).
// 3.  revokeRole(Role role, address account) - Revokes a specific role from an address (Owner only).
// 4.  renounceRole(Role role) - Allows an address to remove its own role.
// 5.  getRole(address account) - Returns the primary role of an address (view).
// 6.  createRule(AssetType assetType, address assetAddress, uint256 assetId, uint256 amount, address payable recipient, uint256 startTime, uint256 releaseTime, uint256 expiryTime, bool isPeriodic, uint256 duration, uint256 interval, bool isEmergencyReleasePermitted) - Creates a new release rule (Requires RULE_MANAGER).
// 7.  updateRule(uint256 ruleId, uint256 newReleaseTime, uint256 newExpiryTime, bool newIsActive, bool newIsEmergencyReleasePermitted) - Updates parameters of an existing rule (Requires RULE_MANAGER). Only updates certain fields to maintain integrity.
// 8.  cancelRule(uint256 ruleId) - Cancels a rule and returns associated assets to the depositor (Requires RULE_MANAGER).
// 9.  activateRule(uint256 ruleId) - Marks a rule as active (Requires RULE_MANAGER).
// 10. deactivateRule(uint256 ruleId) - Marks a rule as inactive (Requires RULE_MANAGER).
// 11. depositETH(uint256 ruleId) - Deposits Ether and links it to an existing rule (Requires DEPOSITOR role).
// 12. depositERC20(uint256 ruleId, address tokenAddress, uint256 amount) - Deposits ERC20 tokens and links to a rule (Requires DEPOSITOR role, requires external token approval).
// 13. depositERC721(uint256 ruleId, address tokenAddress, uint256 tokenId) - Deposits an ERC721 token and links to a rule (Requires DEPOSITOR role, requires external token approval/setApprovalForAll).
// 14. depositETHWithNewRule(...) - Creates a new rule and deposits Ether in a single transaction (Requires DEPOSITOR). Combines createRule and depositETH logic.
// 15. depositERC20WithNewRule(...) - Creates a new rule and deposits ERC20 in a single transaction (Requires DEPOSITOR).
// 16. depositERC721WithNewRule(...) - Creates a new rule and deposits ERC721 in a single transaction (Requires DEPOSITOR).
// 17. claimAssets(uint256 ruleId) - Attempts to claim assets based on the specified rule's conditions (Anyone can call, but only recipient benefits).
// 18. emergencyRelease(uint256 ruleId) - Immediately releases assets for a rule, bypassing time locks (Requires EMERGENCY_RELEASER role, and rule must permit emergency release).
// 19. accelerateRule(uint256 ruleId, uint256 newReleaseTime) - Sets a new, earlier release time for a rule (Requires RULE_MANAGER).
// 20. getRuleDetails(uint256 ruleId) - Returns the full details of a rule (view).
// 21. getDepositedEthForRule(uint256 ruleId) - Returns the ETH balance linked to a specific rule (view).
// 22. getDepositedErc20ForRule(uint256 ruleId, address tokenAddress) - Returns the ERC20 balance of a specific token linked to a rule (view).
// 23. getDepositedErc721ForRule(uint256 ruleId, address tokenAddress, uint256 tokenId) - Checks if a specific ERC721 token is linked to a rule (view).
// 24. getClaimableAmount(uint256 ruleId) - Calculates the amount of assets currently claimable for a rule based on time and previous claims (view).
// 25. getRecipientRules(address recipient) - (Helper, not stored directly) - Would require iterating all rules or storing recipient index, too gas intensive. Let's skip this view for on-chain optimization, or simulate off-chain. *Alternative View:* `getRuleIdsByDepositor` or `getRuleIdsByRecipient` if indexed events are sufficient. Let's add a basic view that returns the count and maybe a paginated list if needed in a real scenario, but for this example, we'll just have the count or simplify. Let's add `getRuleCount` and `getRuleIdByIndex`.
// 25. getRuleCount() - Returns the total number of rules created (view).
// 26. getRuleIdByIndex(uint256 index) - Returns the rule ID at a given index (view - potentially inefficient for large numbers of rules).
// 27. isRuleClaimable(uint256 ruleId) - Checks if a non-periodic rule is claimable (view).
// 28. isPeriodicRuleClaimable(uint256 ruleId) - Checks if *any* amount of a periodic rule is currently claimable (view).

contract ChronoVault {

    // --- 1. State Variables & Data Structures ---

    enum AssetType { ETH, ERC20, ERC721 }
    enum Role { NONE, OWNER, RULE_MANAGER, DEPOSITOR, EMERGENCY_RELEASER } // Using single primary role for simplicity

    struct Rule {
        uint256 id;
        AssetType assetType;
        address assetAddress;       // Address of ERC20/ERC721 contract (0x0 for ETH)
        uint256 assetId;            // Specific token ID for ERC721 (0 for ETH/ERC20)
        uint256 amount;             // Total amount for ETH/ERC20, or count for ERC721 (typically 1 per rule)
        address payable recipient;  // Address to receive assets
        address depositor;          // Address that deposited assets for this rule
        uint256 creationTime;
        uint256 startTime;          // Time when vesting/lock starts (claimable AFTER this if periodic)
        uint256 releaseTime;        // Time when single release unlocks (claimable AFTER this)
        uint256 expiryTime;         // Time after which rule is invalid (optional, 0 for no expiry)
        bool isPeriodic;            // True for vesting-like releases
        uint256 duration;           // Total duration for periodic release (from startTime)
        uint256 interval;           // Interval for periodic releases (e.g., weekly)
        uint256 claimedAmountOrCount; // Amount/count already claimed for periodic rules
        bool isActive;              // Can be deactivated by admin
        bool isEmergencyReleasePermitted; // Can be released early by EMERGENCY_RELEASER
    }

    mapping(uint256 => Rule) public rules;
    uint256 private nextRuleId = 1;
    uint256[] private ruleIds; // Store rule IDs for iteration (less efficient, but needed for getRuleIdByIndex)

    // Track deposited assets linked to rules
    mapping(uint256 => uint256) private depositedEth; // ruleId => balance
    mapping(uint256 => mapping(address => uint256)) private depositedErc20; // ruleId => tokenAddress => balance
    mapping(uint256 => mapping(address => mapping(uint256 => bool))) private depositedErc721; // ruleId => tokenAddress => tokenId => isLinked

    // Role management
    mapping(address => Role) private roles;
    address public owner; // Separate owner state variable for clarity and standard practice

    // --- 2. Events ---

    event RuleCreated(uint256 indexed ruleId, address indexed recipient, AssetType assetType, uint256 amount, uint256 releaseTime, bool isPeriodic);
    event RuleUpdated(uint256 indexed ruleId, uint256 newReleaseTime, uint256 newExpiryTime, bool newIsActive, bool newIsEmergencyReleasePermitted);
    event RuleCancelled(uint256 indexed ruleId, address indexed recipient, uint256 returnAmount); // Emits return amount for ETH/ERC20
    event AssetsDeposited(uint256 indexed ruleId, address indexed depositor, AssetType assetType, address assetAddress, uint256 amountOrId);
    event AssetsClaimed(uint256 indexed ruleId, address indexed recipient, AssetType assetType, address assetAddress, uint256 amountOrIdClaimed, uint256 remainingClaimable);
    event RoleGranted(Role indexed role, address indexed account, address indexed sender);
    event RoleRevoked(Role indexed role, address indexed account, address indexed sender);
    event EmergencyReleaseTriggered(uint256 indexed ruleId, address indexed releaser);
    event RuleAccelerated(uint256 indexed ruleId, address indexed accelerator, uint256 newReleaseTime);

    // --- 3. Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyRole(Role requiredRole) {
        require(roles[msg.sender] == requiredRole || roles[msg.sender] == Role.OWNER, "Access denied: Insufficient role");
        _;
    }

    modifier ruleExists(uint256 ruleId) {
        require(rules[ruleId].id != 0, "Rule does not exist");
        _;
    }

    modifier ruleIsActive(uint256 ruleId) {
        require(rules[ruleId].isActive, "Rule is not active");
        _;
    }

    // --- 4. Constructor ---

    constructor() {
        owner = msg.sender;
        roles[msg.sender] = Role.OWNER; // Grant initial owner role
        emit RoleGranted(Role.OWNER, msg.sender, address(0)); // Use address(0) for contract creation
    }

    // --- 5. Role Management Functions ---

    function grantRole(Role role, address account) external onlyOwner {
        require(account != address(0), "Account cannot be zero address");
        require(role != Role.NONE && role != Role.OWNER, "Cannot grant NONE or OWNER role via this function");
        require(roles[account] == Role.NONE, "Account already has a role"); // Simple model: one role per address

        roles[account] = role;
        emit RoleGranted(role, account, msg.sender);
    }

    function revokeRole(Role role, address account) external onlyOwner {
        require(account != address(0), "Account cannot be zero address");
        require(role != Role.NONE && role != Role.OWNER, "Cannot revoke NONE or OWNER role via this function");
        require(roles[account] == role, "Account does not have this role");

        roles[account] = Role.NONE;
        emit RoleRevoked(role, account, msg.sender);
    }

    function renounceRole(Role role) external {
        require(msg.sender != owner, "Owner cannot renounce roles via this function");
        require(roles[msg.sender] == role, "You do not have this role");
        require(role != Role.OWNER, "Cannot renounce OWNER role via this function");

        roles[msg.sender] = Role.NONE;
        emit RoleRevoked(role, msg.sender, msg.sender);
    }

    function getRole(address account) external view returns (Role) {
        if (account == owner) return Role.OWNER;
        return roles[account];
    }

    // --- 6. Rule Management Functions ---

    // 6. createRule - Creates a new release rule
    function createRule(
        AssetType assetType,
        address assetAddress,
        uint256 assetId, // Used for ERC721
        uint256 amount,    // Used for ETH/ERC20, or count for ERC721 (usually 1)
        address payable recipient,
        uint256 startTime,
        uint256 releaseTime,
        uint256 expiryTime,
        bool isPeriodic,
        uint256 duration,
        uint256 interval,
        bool isEmergencyReleasePermitted
    ) external onlyRole(Role.RULE_MANAGER) returns (uint256 ruleId) {
        require(recipient != address(0), "Recipient cannot be zero address");
        if (assetType == AssetType.ERC20 || assetType == AssetType.ERC721) {
            require(assetAddress != address(0), "Asset address required for ERC20/ERC721");
        }
        if (isPeriodic) {
             require(duration > 0 && interval > 0, "Periodic rules require duration and interval > 0");
             require(duration >= interval, "Duration must be >= interval");
             require(startTime <= releaseTime, "Start time must be <= release time (or first interval)"); // Simplistic check, can be refined
        } else {
             require(releaseTime >= startTime, "Release time must be >= start time");
             require(duration == 0 && interval == 0, "Non-periodic rules should not have duration/interval");
        }
         if (expiryTime > 0) {
             require(expiryTime > releaseTime, "Expiry time must be after release time");
         }
        if (assetType == AssetType.ERC721) {
            require(assetId > 0, "ERC721 rules require assetId > 0");
            require(amount == 1, "ERC721 rules should have amount 1");
        } else {
             require(amount > 0, "Amount must be greater than zero for ETH/ERC20");
             require(assetId == 0, "assetId must be 0 for ETH/ERC20");
        }


        ruleId = nextRuleId++;
        rules[ruleId] = Rule({
            id: ruleId,
            assetType: assetType,
            assetAddress: assetAddress,
            assetId: assetId,
            amount: amount,
            recipient: recipient,
            depositor: address(0), // Depositor set on deposit
            creationTime: block.timestamp,
            startTime: startTime,
            releaseTime: releaseTime,
            expiryTime: expiryTime,
            isPeriodic: isPeriodic,
            duration: duration,
            interval: interval,
            claimedAmountOrCount: 0,
            isActive: true, // Start active, requires deposit
            isEmergencyReleasePermitted: isEmergencyReleasePermitted
        });
        ruleIds.push(ruleId); // Store ID for enumeration

        emit RuleCreated(ruleId, recipient, assetType, amount, releaseTime, isPeriodic);
        return ruleId;
    }

    // 7. updateRule - Updates parameters of an existing rule (limited fields)
    function updateRule(
        uint256 ruleId,
        uint256 newReleaseTime,
        uint256 newExpiryTime,
        bool newIsActive,
        bool newIsEmergencyReleasePermitted
    ) external onlyRole(Role.RULE_MANAGER) ruleExists(ruleId) {
        Rule storage rule = rules[ruleId];
        require(newReleaseTime >= block.timestamp || newReleaseTime == 0, "New release time cannot be in the past (unless 0 to signify immediate)");
        if (newExpiryTime > 0) {
             require(newExpiryTime > newReleaseTime, "New expiry time must be after new release time");
         }


        rule.releaseTime = newReleaseTime;
        rule.expiryTime = newExpiryTime;
        rule.isActive = newIsActive;
        rule.isEmergencyReleasePermitted = newIsEmergencyReleasePermitted;

        emit RuleUpdated(ruleId, newReleaseTime, newExpiryTime, newIsActive, newIsEmergencyReleasePermitted);
    }

    // 8. cancelRule - Cancels a rule and returns assets to depositor
    function cancelRule(uint256 ruleId) external onlyRole(Role.RULE_MANAGER) ruleExists(ruleId) {
        Rule storage rule = rules[ruleId];
        require(rule.depositor != address(0), "No depositor set for this rule, nothing to return");
        require(rule.claimedAmountOrCount == 0, "Cannot cancel rule if assets have already been claimed"); // Prevent partial claims then cancel

        address payable originalDepositor = payable(rule.depositor);
        uint256 returnAmount = 0;

        if (rule.assetType == AssetType.ETH) {
            returnAmount = depositedEth[ruleId];
            depositedEth[ruleId] = 0;
            if (returnAmount > 0) {
                 (bool success, ) = originalDepositor.call{value: returnAmount}("");
                 require(success, "ETH transfer failed");
            }
        } else if (rule.assetType == AssetType.ERC20) {
            returnAmount = depositedErc20[ruleId][rule.assetAddress];
            depositedErc20[ruleId][rule.assetAddress] = 0;
            if (returnAmount > 0) {
                 IERC20(rule.assetAddress).transfer(originalDepositor, returnAmount);
            }
        } else if (rule.assetType == AssetType.ERC721) {
            // For ERC721, the rule is for a single token. Return it if linked.
             if (depositedErc721[ruleId][rule.assetAddress][rule.assetId]) {
                 depositedErc721[ruleId][rule.assetAddress][rule.assetId] = false; // Unlink the token
                 IERC721(rule.assetAddress).safeTransferFrom(address(this), originalDepositor, rule.assetId);
                 returnAmount = 1; // Indicate 1 token returned
             }
        }

        // Invalidate the rule entry
        delete rules[ruleId]; // Removes the rule struct from storage
        // Removing from ruleIds array is inefficient, can leave it or implement complex shifting/swapping

        emit RuleCancelled(ruleId, rule.recipient, returnAmount);
    }

    // 9. activateRule - Marks a rule as active
    function activateRule(uint256 ruleId) external onlyRole(Role.RULE_MANAGER) ruleExists(ruleId) {
        rules[ruleId].isActive = true;
        emit RuleUpdated(ruleId, rules[ruleId].releaseTime, rules[ruleId].expiryTime, true, rules[ruleId].isEmergencyReleasePermitted);
    }

    // 10. deactivateRule - Marks a rule as inactive
    function deactivateRule(uint256 ruleId) external onlyRole(Role.RULE_MANAGER) ruleExists(ruleId) {
        rules[ruleId].isActive = false;
        emit RuleUpdated(ruleId, rules[ruleId].releaseTime, rules[ruleId].expiryTime, false, rules[ruleId].isEmergencyReleasePermitted);
    }


    // --- 7. Deposit Functions ---

    // 11. depositETH - Deposits Ether and links it to an existing rule
    function depositETH(uint256 ruleId) external payable onlyRole(Role.DEPOSITOR) ruleExists(ruleId) ruleIsActive(ruleId) {
        Rule storage rule = rules[ruleId];
        require(rule.assetType == AssetType.ETH, "Rule is not for ETH");
        require(rule.amount == msg.value, "Deposited ETH amount does not match rule amount");
        require(depositedEth[ruleId] == 0, "ETH already deposited for this rule"); // Single deposit per rule

        depositedEth[ruleId] = msg.value;
        rule.depositor = msg.sender; // Set depositor
        emit AssetsDeposited(ruleId, msg.sender, AssetType.ETH, address(0), msg.value);
    }

    // 12. depositERC20 - Deposits ERC20 and links to a rule (requires external approval)
    function depositERC20(uint256 ruleId, address tokenAddress, uint256 amount) external onlyRole(Role.DEPOSITOR) ruleExists(ruleId) ruleIsActive(ruleId) {
        Rule storage rule = rules[ruleId];
        require(rule.assetType == AssetType.ERC20, "Rule is not for ERC20");
        require(rule.assetAddress == tokenAddress, "Token address mismatch for rule");
        require(rule.amount == amount, "Deposited ERC20 amount does not match rule amount");
        require(depositedErc20[ruleId][tokenAddress] == 0, "ERC20 already deposited for this rule"); // Single deposit

        // TransferFrom requires allowance to be set by the depositor BEFORE calling this
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);

        depositedErc20[ruleId][tokenAddress] = amount;
        rule.depositor = msg.sender; // Set depositor
        emit AssetsDeposited(ruleId, msg.sender, AssetType.ERC20, tokenAddress, amount);
    }

    // 13. depositERC721 - Deposits an ERC721 token and links to a rule (requires external approval)
    function depositERC721(uint256 ruleId, address tokenAddress, uint256 tokenId) external onlyRole(Role.DEPOSITOR) ruleExists(ruleId) ruleIsActive(ruleId) {
        Rule storage rule = rules[ruleId];
        require(rule.assetType == AssetType.ERC721, "Rule is not for ERC721");
        require(rule.assetAddress == tokenAddress, "Token address mismatch for rule");
        require(rule.assetId == tokenId, "Token ID mismatch for rule");
        require(!depositedErc721[ruleId][tokenAddress][tokenId], "ERC721 token already deposited for this rule"); // Ensure unique deposit

        // safeTransferFrom requires approval or setApprovalForAll by the depositor
        IERC721(tokenAddress).safeTransferFrom(msg.sender, address(this), tokenId);

        depositedErc721[ruleId][tokenAddress][tokenId] = true; // Mark as linked/deposited
        rule.depositor = msg.sender; // Set depositor
        emit AssetsDeposited(ruleId, msg.sender, AssetType.ERC721, tokenAddress, tokenId);
    }

     // 14-16. Combined deposit and new rule creation (Wrapper functions)

    function depositETHWithNewRule(
        address payable recipient,
        uint256 startTime,
        uint256 releaseTime,
        uint256 expiryTime,
        bool isPeriodic,
        uint256 duration,
        uint256 interval,
        bool isEmergencyReleasePermitted
    ) external payable onlyRole(Role.DEPOSITOR) returns (uint256 ruleId) {
        // Amount is msg.value for ETH
        ruleId = createRule(
            AssetType.ETH,
            address(0), // Asset address is zero for ETH
            0,          // Asset ID is zero for ETH
            msg.value,
            recipient,
            startTime,
            releaseTime,
            expiryTime,
            isPeriodic,
            duration,
            interval,
            isEmergencyReleasePermitted
        );
        // Now deposit
        depositedEth[ruleId] = msg.value;
        rules[ruleId].depositor = msg.sender; // Set depositor in the rule just created

        emit AssetsDeposited(ruleId, msg.sender, AssetType.ETH, address(0), msg.value);
        return ruleId;
    }

     function depositERC20WithNewRule(
        address tokenAddress,
        uint256 amount,
        address payable recipient,
        uint256 startTime,
        uint256 releaseTime,
        uint256 expiryTime,
        bool isPeriodic,
        uint256 duration,
        uint256 interval,
        bool isEmergencyReleasePermitted
    ) external onlyRole(Role.DEPOSITOR) returns (uint256 ruleId) {
        ruleId = createRule(
            AssetType.ERC20,
            tokenAddress,
            0, // Asset ID is zero for ERC20
            amount,
            recipient,
            startTime,
            releaseTime,
            expiryTime,
            isPeriodic,
            duration,
            interval,
            isEmergencyReleasePermitted
        );
         // TransferFrom requires allowance
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        // Now deposit
        depositedErc20[ruleId][tokenAddress] = amount;
        rules[ruleId].depositor = msg.sender; // Set depositor

        emit AssetsDeposited(ruleId, msg.sender, AssetType.ERC20, tokenAddress, amount);
        return ruleId;
    }

    function depositERC721WithNewRule(
        address tokenAddress,
        uint256 tokenId,
        address payable recipient,
        uint256 startTime,
        uint256 releaseTime,
        uint256 expiryTime,
        bool isEmergencyReleasePermitted // Periodic doesn't make sense for single NFT, duration/interval are 0
    ) external onlyRole(Role.DEPOSITOR) returns (uint256 ruleId) {
        // Amount is 1 for ERC721
        ruleId = createRule(
            AssetType.ERC721,
            tokenAddress,
            tokenId,
            1, // Amount is 1 for single NFT
            recipient,
            startTime,
            releaseTime,
            expiryTime,
            false, // ERC721 rules are not periodic in this model
            0,
            0,
            isEmergencyReleasePermitted
        );
        // safeTransferFrom requires approval
        IERC721(tokenAddress).safeTransferFrom(msg.sender, address(this), tokenId);
        // Now deposit
        depositedErc721[ruleId][tokenAddress][tokenId] = true; // Mark as linked/deposited
        rules[ruleId].depositor = msg.sender; // Set depositor

        emit AssetsDeposited(ruleId, msg.sender, AssetType.ERC721, tokenAddress, tokenId);
        return ruleId;
    }


    // --- 8. Claiming Functions ---

    // 17. claimAssets - Attempts to claim assets based on the specified rule's conditions
    function claimAssets(uint256 ruleId) external ruleExists(ruleId) ruleIsActive(ruleId) {
        Rule storage rule = rules[ruleId];
        require(msg.sender == rule.recipient, "Only the rule recipient can claim");
        require(rule.depositor != address(0), "Assets not yet deposited for this rule"); // Must be deposited first
        require(rule.expiryTime == 0 || block.timestamp <= rule.expiryTime, "Rule has expired"); // Check expiry

        uint256 totalClaimableNow = getClaimableAmount(ruleId); // Uses view function to calculate

        require(totalClaimableNow > 0, "No assets currently claimable for this rule");

        uint256 amountToClaim = totalClaimableNow;

        if (rule.assetType == AssetType.ETH) {
            uint256 remainingEth = depositedEth[ruleId] - rule.claimedAmountOrCount;
            amountToClaim = totalClaimableNow > remainingEth ? remainingEth : totalClaimableNow; // Claim up to remaining
            require(amountToClaim > 0, "No ETH remaining to claim for this rule");

            rule.claimedAmountOrCount += amountToClaim;
            (bool success, ) = rule.recipient.call{value: amountToClaim}("");
            require(success, "ETH transfer failed");

        } else if (rule.assetType == AssetType.ERC20) {
             uint256 remainingErc20 = depositedErc20[ruleId][rule.assetAddress] - rule.claimedAmountOrCount;
             amountToClaim = totalClaimableNow > remainingErc20 ? remainingErc20 : totalClaimableNow; // Claim up to remaining
             require(amountToClaim > 0, "No ERC20 remaining to claim for this rule");

             rule.claimedAmountOrCount += amountToClaim;
             IERC20(rule.assetAddress).transfer(rule.recipient, amountToClaim);

        } else if (rule.assetType == AssetType.ERC721) {
             // ERC721 is not periodic in this model, amount is 1.
             // getClaimableAmount will return 1 if single claim conditions met and not claimed.
             require(totalClaimableNow == 1, "ERC721 rule is not claimable");
             require(rule.claimedAmountOrCount == 0, "ERC721 token already claimed for this rule");
             require(depositedErc721[ruleId][rule.assetAddress][rule.assetId], "ERC721 token not deposited or unlinked");

             rule.claimedAmountOrCount = 1; // Mark as claimed
             // Unlink the token from the rule
             depositedErc721[ruleId][rule.assetAddress][rule.assetId] = false;
             IERC721(rule.assetAddress).safeTransferFrom(address(this), rule.recipient, rule.assetId);
             amountToClaim = 1; // Indicate 1 token claimed
        } else {
            revert("Unsupported asset type"); // Should not happen with enum
        }

        emit AssetsClaimed(ruleId, rule.recipient, rule.assetType, rule.assetAddress, amountToClaim, rule.amount - rule.claimedAmountOrCount);
    }


    // --- 9. Emergency & Override Functions ---

    // 18. emergencyRelease - Immediately releases assets for a rule, bypassing time locks
    function emergencyRelease(uint256 ruleId) external onlyRole(Role.EMERGENCY_RELEASER) ruleExists(ruleId) ruleIsActive(ruleId) {
        Rule storage rule = rules[ruleId];
        require(rule.isEmergencyReleasePermitted, "Emergency release not permitted for this rule");
        require(rule.depositor != address(0), "Assets not yet deposited for this rule");

        uint256 totalAmount = rule.amount; // For ETH/ERC20, this is the total amount
        if (rule.assetType != AssetType.ERC721) {
            // For ETH/ERC20, release the remaining balance
            if (rule.assetType == AssetType.ETH) {
                totalAmount = depositedEth[ruleId];
            } else if (rule.assetType == AssetType.ERC20) {
                 totalAmount = depositedErc20[ruleId][rule.assetAddress];
            }
            // If periodic, need to check if anything is left to claim based on what was deposited
            require(totalAmount > rule.claimedAmountOrCount, "No assets remaining to emergency release");
            totalAmount -= rule.claimedAmountOrCount; // Release only the remaining
            rule.claimedAmountOrCount = rule.amount; // Mark rule as fully claimed (assuming total deposited matches rule.amount)

        } else {
            // For ERC721, release the single token if linked and not claimed
            require(rule.claimedAmountOrCount == 0, "ERC721 token already claimed");
            require(depositedErc721[ruleId][rule.assetAddress][rule.assetId], "ERC721 token not deposited or unlinked");

            rule.claimedAmountOrCount = 1; // Mark as claimed
            // Unlink the token
            depositedErc721[ruleId][rule.assetAddress][rule.assetId] = false;
            IERC721(rule.assetAddress).safeTransferFrom(address(this), rule.recipient, rule.assetId);
            totalAmount = 1; // Indicate 1 token released
        }

        if (rule.assetType == AssetType.ETH) {
            (bool success, ) = rule.recipient.call{value: totalAmount}("");
             require(success, "ETH transfer failed");
        } else if (rule.assetType == AssetType.ERC20) {
            IERC20(rule.assetAddress).transfer(rule.recipient, totalAmount);
        } // ERC721 handled above

        emit EmergencyReleaseTriggered(ruleId, msg.sender);
        emit AssetsClaimed(ruleId, rule.recipient, rule.assetType, rule.assetAddress, totalAmount, 0); // Emit claim event as well
    }

    // 19. accelerateRule - Sets a new, earlier release time for a rule (non-periodic)
    function accelerateRule(uint256 ruleId, uint256 newReleaseTime) external onlyRole(Role.RULE_MANAGER) ruleExists(ruleId) {
        Rule storage rule = rules[ruleId];
        require(!rule.isPeriodic, "Cannot accelerate periodic rules this way");
        require(newReleaseTime < rule.releaseTime, "New release time must be earlier");
        require(newReleaseTime >= block.timestamp, "New release time cannot be in the past");
        require(newReleaseTime >= rule.startTime, "New release time must be after start time");

        rule.releaseTime = newReleaseTime;
        emit RuleAccelerated(ruleId, msg.sender, newReleaseTime);
        emit RuleUpdated(ruleId, newReleaseTime, rule.expiryTime, rule.isActive, rule.isEmergencyReleasePermitted); // Also emit update event
    }


    // --- 10. View Functions ---

    // 20. getRuleDetails - Returns the full details of a rule
    function getRuleDetails(uint256 ruleId) external view ruleExists(ruleId) returns (Rule memory) {
        return rules[ruleId];
    }

    // 21. getDepositedEthForRule - Returns the ETH balance linked to a specific rule
    function getDepositedEthForRule(uint256 ruleId) external view ruleExists(ruleId) returns (uint256) {
        return depositedEth[ruleId];
    }

    // 22. getDepositedErc20ForRule - Returns the ERC20 balance of a specific token linked to a rule
    function getDepositedErc20ForRule(uint256 ruleId, address tokenAddress) external view ruleExists(ruleId) returns (uint256) {
        return depositedErc20[ruleId][tokenAddress];
    }

    // 23. getDepositedErc721ForRule - Checks if a specific ERC721 token is linked to a rule
    function getDepositedErc721ForRule(uint256 ruleId, address tokenAddress, uint256 tokenId) external view ruleExists(ruleId) returns (bool) {
         return depositedErc721[ruleId][tokenAddress][tokenId];
    }

    // Internal helper to calculate total claimable amount based on periodic rules up to a given time
    function _calculatePeriodicClaimable(uint256 ruleId, uint256 currentTime) internal view returns (uint256) {
        Rule storage rule = rules[ruleId];
        if (!rule.isPeriodic || currentTime < rule.startTime || rule.duration == 0) {
            return 0; // Not periodic, or before start time, or duration is zero
        }

        // Ensure we don't exceed the total duration
        uint256 elapsedTime = currentTime - rule.startTime;
        if (elapsedTime >= rule.duration) {
             return rule.amount; // All vested
        }

        // Calculate the portion vested up to now
        // Use fixed point or careful integer division
        // Total claimable = (Total Amount * Elapsed Time) / Total Duration
        // To avoid precision issues with division, do multiplication first:
        // totalClaimable = (rule.amount * elapsedTime) / rule.duration
        uint256 totalClaimable = (rule.amount * elapsedTime) / rule.duration;

        return totalClaimable;
    }


    // 24. getClaimableAmount - Calculates the amount of assets currently claimable for a rule
    function getClaimableAmount(uint256 ruleId) public view ruleExists(ruleId) returns (uint256) {
        Rule storage rule = rules[ruleId];
        if (!rule.isActive || rule.depositor == address(0)) {
             return 0; // Not active or assets not deposited
        }
         if (rule.expiryTime > 0 && block.timestamp > rule.expiryTime) {
             return 0; // Rule expired
         }

        if (rule.assetType == AssetType.ERC721) {
            // ERC721 is not periodic in this model
            // Claimable if release time passed AND not already claimed AND token is linked
            if (block.timestamp >= rule.releaseTime && rule.claimedAmountOrCount == 0 && depositedErc721[ruleId][rule.assetAddress][rule.assetId]) {
                return 1; // 1 token is claimable
            } else {
                return 0;
            }
        }

        // For ETH and ERC20
        uint256 totalClaimableUpToNow;
        if (rule.isPeriodic) {
            totalClaimableUpToNow = _calculatePeriodicClaimable(ruleId, block.timestamp);
        } else {
            // Non-periodic: Claimable if release time has passed
            if (block.timestamp >= rule.releaseTime && block.timestamp >= rule.startTime) { // startTime should also be considered for the lock
                totalClaimableUpToNow = rule.amount; // Full amount claimable
            } else {
                totalClaimableUpToNow = 0;
            }
        }

        // Calculate the amount not yet claimed
        if (totalClaimableUpToNow <= rule.claimedAmountOrCount) {
            return 0; // Nothing new is claimable
        } else {
            uint256 amountNotYetClaimed = totalClaimableUpToNow - rule.claimedAmountOrCount;
            // Ensure we don't promise more than what was deposited
            uint256 depositedTotal = 0;
            if (rule.assetType == AssetType.ETH) {
                depositedTotal = depositedEth[ruleId];
            } else if (rule.assetType == AssetType.ERC20) {
                 depositedTotal = depositedErc20[ruleId][rule.assetAddress];
            }
            uint256 remainingDeposited = depositedTotal - rule.claimedAmountOrCount;
             return amountNotYetClaimed > remainingDeposited ? remainingDeposited : amountNotYetClaimed;

        }
    }

     // 25. getRuleCount - Returns the total number of rules created
    function getRuleCount() external view returns (uint256) {
        return ruleIds.length;
    }

    // 26. getRuleIdByIndex - Returns the rule ID at a given index (use cautiously with many rules)
    function getRuleIdByIndex(uint256 index) external view returns (uint256) {
         require(index < ruleIds.length, "Index out of bounds");
         return ruleIds[index];
    }

     // 27. isRuleClaimable - Checks if a non-periodic rule is claimable (helper view)
     function isRuleClaimable(uint256 ruleId) external view ruleExists(ruleId) returns (bool) {
        Rule storage rule = rules[ruleId];
        if (rule.isPeriodic) return false; // Not for periodic rules
         if (rule.assetType == AssetType.ERC721) {
            return block.timestamp >= rule.releaseTime && rule.claimedAmountOrCount == 0 && depositedErc721[ruleId][rule.assetAddress][rule.assetId];
        } else {
            return block.timestamp >= rule.releaseTime && block.timestamp >= rule.startTime && rule.claimedAmountOrCount < rule.amount;
        }
     }

     // 28. isPeriodicRuleClaimable - Checks if *any* amount of a periodic rule is currently claimable (helper view)
     function isPeriodicRuleClaimable(uint256 ruleId) external view ruleExists(ruleId) returns (bool) {
        Rule storage rule = rules[ruleId];
        if (!rule.isPeriodic) return false; // Not for non-periodic rules
        return getClaimableAmount(ruleId) > 0;
     }


    // Fallback function to receive ETH
    receive() external payable {
        // ETH sent directly without calling depositETH will be held in the contract
        // but not linked to any specific rule, making it potentially unclaimable
        // unless emergencyRelease is used by the owner or specific logic is added.
        // Consider emitting an event here for clarity if direct sends are allowed.
        // Or revert if direct sends are not intended.
        // For this contract, we will allow it but it won't be tied to a rule.
        // Acknowledge receipt but no rule linkage:
        // emit ReceivedETH(msg.sender, msg.value); // Need to define this event if used.
    }
}

// Dummy Interfaces (Replace with actual paths if using OpenZeppelin or other libraries)
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function ownerOf(uint256 tokenId) external view returns (address owner);
}
```

**Explanation of Advanced/Creative/Trendy Concepts:**

1.  **Multi-Asset Vault:** Supports ETH, ERC20, and ERC721 within the same contract under different rules. This requires careful handling of each asset type during deposits, claims, and balance tracking.
2.  **Complex Temporal Rules:**
    *   Beyond simple time locks (`releaseTime`), rules can have a `startTime` (assets are locked until then, even if `releaseTime` is earlier conceptually, though in this model `releaseTime >= startTime` is enforced for non-periodic) and `expiryTime` (after which the rule becomes invalid).
    *   **Periodic Releases (Vesting):** Rules can be marked `isPeriodic` with a `duration` and `interval`. The `getClaimableAmount` function calculates the vested amount linearly over time, allowing recipients to claim increments rather than waiting for a single unlock. This is a common but implemented custom here.
    *   **Dynamic Rule State:** Rules can be `isActive` (controlled by `RULE_MANAGER`) and have an `isEmergencyReleasePermitted` flag.
3.  **Granular Role-Based Access Control:** Instead of just an `owner`, we introduce distinct roles (`RULE_MANAGER`, `DEPOSITOR`, `EMERGENCY_RELEASER`) with specific permissions, managed by the `OWNER`. This allows for distributed responsibilities. (Note: A more complex system might use bitmasks for multiple roles per address, but this simple enum model meets the requirement).
4.  **Linked Deposits:** Assets are not just dumped into the contract; they are explicitly linked to a specific `ruleId` upon deposit. This ensures that when a rule is claimed or cancelled, the correct, intended assets are moved. The `depositor` address is also recorded per rule.
5.  **Emergency Override:** The `EMERGENCY_RELEASER` role can bypass time locks for rules explicitly allowing it (`isEmergencyReleasePermitted`), providing a mechanism for unforeseen circumstances.
6.  **Rule Acceleration:** `RULE_MANAGER` can potentially `accelerateRule` (bring the release time earlier) for non-periodic rules, adding flexibility.
7.  **State Tracking:** The `claimedAmountOrCount` in the `Rule` struct is crucial for tracking progress on periodic claims and ensuring non-periodic or ERC721 claims only happen once. Mappings track deposited assets per rule ID.
8.  **Separation of Concerns:** Rule creation/management is separate from deposit and claiming, allowing for pre-configuration of release schedules.
9.  **Comprehensive View Functions:** Includes functions to inspect rule details, deposited amounts per rule, and crucially, calculate *currently* claimable amounts dynamically based on the current time and rule parameters.

This contract provides a flexible framework for managing assets with diverse and dynamic temporal conditions, suitable for scenarios like token vesting, staged fund releases, conditional bounties, or time-locked digital art distribution. It demonstrates the use of enums, structs, multiple mappings, role-based access control, and custom logic for complex financial/temporal calculations on-chain.