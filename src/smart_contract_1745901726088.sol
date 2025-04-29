Okay, here is a concept for a "Smart Crypto Vault" with advanced features, including scheduled and conditional releases, delegated management with granular permissions, multi-asset handling (ERC-20 and ERC-721), and emergency functions. It aims to be creative by combining these features in one contract, going beyond standard multi-sigs or simple time-locks.

It includes:
1.  **Multi-Asset Support:** Handles both ERC-20 tokens and ERC-721 NFTs.
2.  **Advanced Access Control:** Owner and delegated Managers with specific, configurable permissions.
3.  **Scheduled Releases:** Time-based automatic distribution of assets to recipients.
4.  **Conditional Releases:** Distribution triggered by an external (or on-chain) condition checker contract (simulating oracle-like triggers or complex logic).
5.  **Panic/Emergency Features:** Mechanisms to halt operations or emergency withdraw assets.
6.  **Configuration:** Ability to whitelist allowed tokens/NFT collections, set manager permissions.

It requires standard ERC-20 and ERC-721 interfaces, and introduces a custom `IConditionChecker` interface.

---

**Outline and Function Summary**

**Contract Name:** SmartCryptoVault

**Description:** A versatile smart contract designed to securely store and manage the distribution of various digital assets (ERC-20 tokens and ERC-721 NFTs) with advanced features like time-based scheduling, condition-based triggers, delegated management with granular permissions, and emergency controls.

**Key Features:**
*   Store ERC-20 and ERC-721 assets.
*   Define allowed assets to restrict deposits.
*   Set up time-locked releases for both token types.
*   Set up releases contingent on external contract conditions.
*   Delegate management roles with specific permissions (e.g., permission to only schedule releases).
*   Emergency mechanisms to lock the vault or withdraw funds.

**Function Categories:**

1.  **Vault Management & Ownership:**
    *   `constructor`: Initializes the contract with the owner.
    *   `transferOwnership`: Transfers ownership of the contract (from Ownable).

2.  **Asset Configuration:**
    *   `addAllowedToken`: Whitelists an ERC-20 token address for deposits.
    *   `removeAllowedToken`: Removes an ERC-20 token from the whitelist.
    *   `addAllowedNFTCollection`: Whitelists an ERC-721 collection address for deposits.
    *   `removeAllowedNFTCollection`: Removes an ERC-721 collection from the whitelist.

3.  **Deposits:**
    *   `depositERC20`: Allows users to deposit whitelisted ERC-20 tokens (requires prior allowance).
    *   `depositERC721`: Allows users to deposit whitelisted ERC-721 NFTs (requires prior approval).

4.  **Access Control & Management:**
    *   `addManager`: Adds a new address as a manager.
    *   `removeManager`: Removes an address as a manager.
    *   `setManagerPermissions`: Configures specific permissions for a manager.
    *   `getManagerPermissions`: Retrieves the permission settings for a manager.
    *   `isManager`: Checks if an address is a manager.

5.  **Scheduled Releases:**
    *   `scheduleERC20Release`: Schedules a future time-based release of ERC-20 tokens.
    *   `scheduleERC721Release`: Schedules a future time-based release of an ERC-721 NFT.
    *   `executeScheduledRelease`: Executed (externally, e.g., by a keeper) to trigger overdue scheduled releases.
    *   `cancelScheduledRelease`: Cancels a pending scheduled release.

6.  **Conditional Releases:**
    *   `scheduleConditionalERC20Release`: Schedules a release contingent on a condition checker contract.
    *   `scheduleConditionalERC721Release`: Schedules an NFT release contingent on a condition checker contract.
    *   `checkAndExecuteConditionalRelease`: Executed (externally) to check the condition and trigger the release if true and not executed.
    *   `cancelConditionalRelease`: Cancels a pending conditional release.

7.  **Emergency & Panic:**
    *   `panicLockVault`: Immediately halts all scheduled and conditional release executions.
    *   `panicUnlockVault`: Resumes scheduled and conditional release executions.
    *   `emergencyWithdrawERC20`: Allows the owner to withdraw a specific ERC-20 token instantly in an emergency.
    *   `emergencyWithdrawERC721`: Allows the owner to withdraw a specific ERC-721 NFT instantly in an emergency.

8.  **Information Retrieval:**
    *   `getERC20Balance`: Get the vault's balance of a specific ERC-20 token.
    *   `getERC721Balance`: Get the vault's balance of a specific ERC-721 collection (count).
    *   `getERC721TokensOfOwner`: Get list of token IDs for a collection held by the vault.
    *   `getAllowedTokens`: Get the list of allowed ERC-20 token addresses.
    *   `getAllowedNFTCollections`: Get the list of allowed ERC-721 collection addresses.
    *   `getScheduledReleaseDetails`: Get details for a specific scheduled release.
    *   `getConditionalReleaseDetails`: Get details for a specific conditional release.
    *   `getScheduledReleaseCount`: Get the total number of scheduled releases.
    *   `getConditionalReleaseCount`: Get the total number of conditional releases.
    *   `isPanicLocked`: Check the current panic lock status.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// --- Outline and Function Summary Above ---

/**
 * @title SmartCryptoVault
 * @dev A versatile smart contract for storing and managing the distribution of ERC-20 and ERC-721 assets
 *      with advanced features like scheduled/conditional releases, delegated management, and emergency controls.
 */
contract SmartCryptoVault is Ownable, ERC721Holder, ReentrancyGuard {
    using Address for address;

    // --- Events ---
    event ERC20Deposited(address indexed token, address indexed depositor, uint256 amount);
    event ERC721Deposited(address indexed collection, address indexed depositor, uint256 tokenId);
    event AllowedTokenAdded(address indexed token);
    event AllowedTokenRemoved(address indexed token);
    event AllowedNFTCollectionAdded(address indexed collection);
    event AllowedNFTCollectionRemoved(address indexed collection);
    event ManagerAdded(address indexed manager);
    event ManagerRemoved(address indexed manager);
    event ManagerPermissionsUpdated(address indexed manager, uint256 permissions);
    event ScheduledERC20ReleaseCreated(uint256 indexed releaseId, address indexed token, address indexed recipient, uint256 amount, uint256 releaseTime);
    event ScheduledERC721ReleaseCreated(uint256 indexed releaseId, address indexed collection, address indexed recipient, uint256 tokenId, uint256 releaseTime);
    event ScheduledReleaseExecuted(uint256 indexed releaseId);
    event ScheduledReleaseCancelled(uint256 indexed releaseId);
    event ConditionalERC20ReleaseCreated(uint256 indexed releaseId, address indexed token, address indexed recipient, uint256 amount, address indexed conditionChecker);
    event ConditionalERC721ReleaseCreated(uint256 indexed releaseId, address indexed collection, address indexed recipient, uint256 tokenId, address indexed conditionChecker);
    event ConditionalReleaseExecuted(uint256 indexed releaseId);
    event ConditionalReleaseCancelled(uint256 indexed releaseId);
    event VaultPanicLocked();
    event VaultPanicUnlocked();
    event EmergencyERC20Withdrawn(address indexed token, address indexed owner, uint256 amount);
    event EmergencyERC721Withdrawn(address indexed collection, address indexed owner, uint256 tokenId);


    // --- Data Structures ---

    struct ManagerPermissions {
        bool canAddRemoveManagers;
        bool canSetManagerPermissions;
        bool canAddRemoveAllowedAssets;
        bool canScheduleReleases;
        bool canCancelReleases;
        // Add more specific permissions as needed
    }

    struct ScheduledRelease {
        address token; // Address of ERC20 or ERC721
        bool isERC721;
        uint256 amountOrTokenId; // Amount for ERC20, tokenId for ERC721
        address recipient;
        uint256 releaseTime;
        bool executed;
        bool cancelled;
    }

    struct ConditionalRelease {
        address token; // Address of ERC20 or ERC721
        bool isERC721;
        uint256 amountOrTokenId; // Amount for ERC20, tokenId for ERC721
        address recipient;
        IConditionChecker conditionChecker;
        bool executed;
        bool cancelled;
        bool conditionMet; // Stores the last check result to avoid re-checking unnecessarily
    }

    // --- State Variables ---

    mapping(address => bool) private _allowedTokens;
    mapping(address => bool) private _allowedNFTCollections;

    mapping(address => bool) private _isManager;
    mapping(address => ManagerPermissions) private _managerPermissions;

    mapping(uint256 => ScheduledRelease) private _scheduledReleases;
    uint256 private _scheduledReleaseCounter;

    mapping(uint256 => ConditionalRelease) private _conditionalReleases;
    uint256 private _conditionalReleaseCounter;

    bool private _isPanicLocked;

    // --- Interfaces ---

    /**
     * @dev Interface for external contracts that check conditions.
     *      Implementations should return true if the condition is met.
     */
    interface IConditionChecker {
        function checkCondition() external view returns (bool);
    }

    // --- Modifiers ---

    modifier onlyManager() {
        require(_isManager[msg.sender], "SmartCryptoVault: Not a manager");
        _;
    }

    modifier onlyOwnerOrManager() {
        require(owner() == msg.sender || _isManager[msg.sender], "SmartCryptoVault: Not owner or manager");
        _;
    }

    modifier onlyManagerWithPermission(uint256 permissionFlag) {
        // A more robust implementation would use a bitmask or enum for flags.
        // For this example, we'll use simple checks on the struct fields.
        require(_isManager[msg.sender], "SmartCryptoVault: Not a manager");
        ManagerPermissions storage perms = _managerPermissions[msg.sender];
        if (permissionFlag == 1) require(perms.canAddRemoveManagers, "SmartCryptoVault: Missing add/remove manager permission");
        if (permissionFlag == 2) require(perms.canSetManagerPermissions, "SmartCryptoVault: Missing set manager permission");
        if (permissionFlag == 3) require(perms.canAddRemoveAllowedAssets, "SmartCryptoVault: Missing add/remove asset permission");
        if (permissionFlag == 4) require(perms.canScheduleReleases, "SmartCryptoVault: Missing schedule release permission");
        if (permissionFlag == 5) require(perms.canCancelReleases, "SmartCryptoVault: Missing cancel release permission");
        // Add more flags here...
        _;
    }

    // --- Constructor ---

    constructor(address initialOwner) Ownable(initialOwner) {
        _scheduledReleaseCounter = 0;
        _conditionalReleaseCounter = 0;
        _isPanicLocked = false;
    }

    // --- Vault Management & Ownership (Ownable functions are inherited) ---

    // `transferOwnership` is inherited from Ownable

    // --- Asset Configuration (Only Owner or Manager with permission 3) ---

    /**
     * @dev Whitelists an ERC-20 token address allowing it to be deposited.
     * @param token The address of the ERC-20 token contract.
     */
    function addAllowedToken(address token) external onlyOwnerOrManager {
        if (_isManager[msg.sender]) {
            require(_managerPermissions[msg.sender].canAddRemoveAllowedAssets, "SmartCryptoVault: Manager lacks permission");
        }
        require(token != address(0), "SmartCryptoVault: Zero address");
        _allowedTokens[token] = true;
        emit AllowedTokenAdded(token);
    }

    /**
     * @dev Removes an ERC-20 token address from the whitelist.
     * @param token The address of the ERC-20 token contract.
     */
    function removeAllowedToken(address token) external onlyOwnerOrManager {
        if (_isManager[msg.sender]) {
            require(_managerPermissions[msg.sender].canAddRemoveAllowedAssets, "SmartCryptoVault: Manager lacks permission");
        }
        require(token != address(0), "SmartCryptoVault: Zero address");
        _allowedTokens[token] = false;
        emit AllowedTokenRemoved(token);
    }

    /**
     * @dev Whitelists an ERC-721 collection address allowing its NFTs to be deposited.
     * @param collection The address of the ERC-721 collection contract.
     */
    function addAllowedNFTCollection(address collection) external onlyOwnerOrManager {
         if (_isManager[msg.sender]) {
            require(_managerPermissions[msg.sender].canAddRemoveAllowedAssets, "SmartCryptoVault: Manager lacks permission");
        }
        require(collection != address(0), "SmartCryptoVault: Zero address");
        _allowedNFTCollections[collection] = true;
        emit AllowedNFTCollectionAdded(collection);
    }

    /**
     * @dev Removes an ERC-721 collection address from the whitelist.
     * @param collection The address of the ERC-721 collection contract.
     */
    function removeAllowedNFTCollection(address collection) external onlyOwnerOrManager {
        if (_isManager[msg.sender]) {
            require(_managerPermissions[msg.sender].canAddRemoveAllowedAssets, "SmartCryptoVault: Manager lacks permission");
        }
        require(collection != address(0), "SmartCryptoVault: Zero address");
        _allowedNFTCollections[collection] = false;
        emit AllowedNFTCollectionRemoved(collection);
    }

    // --- Deposits ---

    /**
     * @dev Receives ERC-20 tokens. Requires the user to approve the vault first.
     * @param token The address of the ERC-20 token.
     * @param amount The amount of tokens to deposit.
     */
    function depositERC20(address token, uint256 amount) external nonReentrant {
        require(_allowedTokens[token], "SmartCryptoVault: Token not allowed");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        emit ERC20Deposited(token, msg.sender, amount);
    }

     /**
     * @dev Receives ERC-721 NFTs. Requires the user to approve or set approval for all first.
     *      Uses `onERC721Received` from ERC721Holder internally for safety.
     * @param collection The address of the ERC-721 collection.
     * @param tokenId The ID of the NFT to deposit.
     */
    function depositERC721(address collection, uint256 tokenId) external nonReentrant {
        require(_allowedNFTCollections[collection], "SmartCryptoVault: NFT Collection not allowed");
         // The sender must have approved the vault or setApprovalForAll
         IERC721(collection).safeTransferFrom(msg.sender, address(this), tokenId);
         // ERC721Holder's onERC721Received will be called automatically
         emit ERC721Deposited(collection, msg.sender, tokenId);
    }

    // ERC721Holder receives NFTs securely
    // Override this if needed for custom logic, but default is usually sufficient
    // function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) public override returns (bytes4) {
    //    return super.onERC721Received(operator, from, tokenId, data);
    // }


    // --- Access Control & Management (Only Owner or Manager with specific permissions) ---

    /**
     * @dev Adds an address as a manager. Owner or manager with permission 1 can call.
     * @param manager The address to add as a manager.
     */
    function addManager(address manager) external onlyOwnerOrManager {
         if (_isManager[msg.sender]) {
            require(_managerPermissions[msg.sender].canAddRemoveManagers, "SmartCryptoVault: Manager lacks permission");
        }
        require(manager != address(0), "SmartCryptoVault: Zero address");
        require(manager != owner(), "SmartCryptoVault: Cannot add owner as manager");
        _isManager[manager] = true;
        // Initialize default permissions (e.g., all false initially)
        _managerPermissions[manager] = ManagerPermissions(false, false, false, false, false);
        emit ManagerAdded(manager);
    }

    /**
     * @dev Removes an address as a manager. Owner or manager with permission 1 can call.
     * @param manager The address to remove.
     */
    function removeManager(address manager) external onlyOwnerOrManager {
        if (_isManager[msg.sender]) {
            require(_managerPermissions[msg.sender].canAddRemoveManagers, "SmartCryptoVault: Manager lacks permission");
        }
        require(manager != address(0), "SmartCryptoVault: Zero address");
        require(_isManager[manager], "SmartCryptoVault: Address is not a manager");
        _isManager[manager] = false;
        // Clear permissions
        delete _managerPermissions[manager];
        emit ManagerRemoved(manager);
    }

    /**
     * @dev Sets specific permissions for a manager. Owner or manager with permission 2 can call.
     * @param manager The manager address.
     * @param perms The ManagerPermissions struct with desired settings.
     */
    function setManagerPermissions(address manager, ManagerPermissions calldata perms) external onlyOwnerOrManager {
        if (_isManager[msg.sender]) {
            require(_managerPermissions[msg.sender].canSetManagerPermissions, "SmartCryptoVault: Manager lacks permission");
        }
        require(_isManager[manager], "SmartCryptoVault: Address is not a manager");
        _managerPermissions[manager] = perms;
        // Note: Emitting a single value for permissions for simplicity in event signature
        // In a real contract, you might use a bitmask or encode permissions differently.
        emit ManagerPermissionsUpdated(manager, 0); // Dummy value, actual perms are in state
    }

    /**
     * @dev Retrieves the permission settings for a manager.
     * @param manager The manager address.
     * @return ManagerPermissions struct.
     */
    function getManagerPermissions(address manager) external view returns (ManagerPermissions memory) {
        require(_isManager[manager], "SmartCryptoVault: Address is not a manager");
        return _managerPermissions[manager];
    }

    /**
     * @dev Checks if an address is currently a manager.
     * @param account The address to check.
     * @return bool True if the account is a manager, false otherwise.
     */
    function isManager(address account) external view returns (bool) {
        return _isManager[account];
    }


    // --- Scheduled Releases (Only Owner or Manager with permission 4/5) ---

    /**
     * @dev Schedules a future release of ERC-20 tokens to a recipient. Owner or manager with permission 4 can call.
     * @param token The ERC-20 token address.
     * @param recipient The address to receive the tokens.
     * @param amount The amount of tokens to release.
     * @param releaseTime The Unix timestamp when the tokens can be released. Must be in the future.
     * @return releaseId The ID of the scheduled release.
     */
    function scheduleERC20Release(
        address token,
        address recipient,
        uint256 amount,
        uint256 releaseTime
    ) external onlyOwnerOrManager returns (uint256) {
        if (_isManager[msg.sender]) {
            require(_managerPermissions[msg.sender].canScheduleReleases, "SmartCryptoVault: Manager lacks permission");
        }
        require(token != address(0), "SmartCryptoVault: Token zero address");
        require(recipient != address(0), "SmartCryptoVault: Recipient zero address");
        require(amount > 0, "SmartCryptoVault: Amount must be greater than 0");
        require(releaseTime > block.timestamp, "SmartCryptoVault: Release time must be in the future");
        require(_allowedTokens[token], "SmartCryptoVault: Token not allowed for scheduling");

        uint256 id = _scheduledReleaseCounter++;
        _scheduledReleases[id] = ScheduledRelease({
            token: token,
            isERC721: false,
            amountOrTokenId: amount,
            recipient: recipient,
            releaseTime: releaseTime,
            executed: false,
            cancelled: false
        });

        emit ScheduledERC20ReleaseCreated(id, token, recipient, amount, releaseTime);
        return id;
    }

     /**
     * @dev Schedules a future release of an ERC-721 NFT to a recipient. Owner or manager with permission 4 can call.
     * @param collection The ERC-721 collection address.
     * @param recipient The address to receive the NFT.
     * @param tokenId The ID of the NFT to release.
     * @param releaseTime The Unix timestamp when the NFT can be released. Must be in the future.
     * @return releaseId The ID of the scheduled release.
     */
    function scheduleERC721Release(
        address collection,
        address recipient,
        uint256 tokenId,
        uint256 releaseTime
    ) external onlyOwnerOrManager returns (uint256) {
        if (_isManager[msg.sender]) {
            require(_managerPermissions[msg.sender].canScheduleReleases, "SmartCryptoVault: Manager lacks permission");
        }
        require(collection != address(0), "SmartCryptoVault: Collection zero address");
        require(recipient != address(0), "SmartCryptoVault: Recipient zero address");
        require(releaseTime > block.timestamp, "SmartCryptoVault: Release time must be in the future");
         require(_allowedNFTCollections[collection], "SmartCryptoVault: NFT Collection not allowed for scheduling");
        // Optional: Add check that the vault owns the token ID? Might be deposited after scheduling.

        uint256 id = _scheduledReleaseCounter++;
        _scheduledReleases[id] = ScheduledRelease({
            token: collection, // Using token field for collection address
            isERC721: true,
            amountOrTokenId: tokenId,
            recipient: recipient,
            releaseTime: releaseTime,
            executed: false,
            cancelled: false
        });

        emit ScheduledERC721ReleaseCreated(id, collection, recipient, tokenId, releaseTime);
        return id;
    }

    /**
     * @dev Executes a scheduled release if the release time has passed,
     *      the vault is not panic locked, and the release hasn't been executed or cancelled.
     *      Can be called by anyone (incentivize with gas?). NonReentrant guard is crucial here.
     * @param releaseId The ID of the scheduled release to execute.
     */
    function executeScheduledRelease(uint256 releaseId) external nonReentrant {
        ScheduledRelease storage release = _scheduledReleases[releaseId];
        require(release.recipient != address(0), "SmartCryptoVault: Release does not exist"); // Check if struct is initialized
        require(!_isPanicLocked, "SmartCryptoVault: Vault is panic locked");
        require(!release.executed, "SmartCryptoVault: Release already executed");
        require(!release.cancelled, "SmartCryptoVault: Release cancelled");
        require(block.timestamp >= release.releaseTime, "SmartCryptoVault: Release time not reached");

        release.executed = true; // Mark executed BEFORE transfer

        if (release.isERC721) {
             // Check ownership just before transfer
             require(IERC721(release.token).ownerOf(release.amountOrTokenId) == address(this), "SmartCryptoVault: Vault does not own NFT");
             IERC721(release.token).safeTransferFrom(address(this), release.recipient, release.amountOrTokenId);
        } else {
            // Check balance just before transfer (optional but good practice)
            require(IERC20(release.token).balanceOf(address(this)) >= release.amountOrTokenId, "SmartCryptoVault: Insufficient ERC20 balance for release");
            IERC20(release.token).transfer(release.recipient, release.amountOrTokenId);
        }

        emit ScheduledReleaseExecuted(releaseId);
    }

    /**
     * @dev Cancels a scheduled release before it is executed. Owner or manager with permission 5 can call.
     * @param releaseId The ID of the scheduled release to cancel.
     */
    function cancelScheduledRelease(uint256 releaseId) external onlyOwnerOrManager {
        if (_isManager[msg.sender]) {
            require(_managerPermissions[msg.sender].canCancelReleases, "SmartCryptoVault: Manager lacks permission");
        }
        ScheduledRelease storage release = _scheduledReleases[releaseId];
        require(release.recipient != address(0), "SmartCryptoVault: Release does not exist");
        require(!release.executed, "SmartCryptoVault: Release already executed");
        require(!release.cancelled, "SmartCryptoVault: Release already cancelled");

        release.cancelled = true;
        emit ScheduledReleaseCancelled(releaseId);
    }

    // --- Conditional Releases (Only Owner or Manager with permission 4/5) ---

     /**
     * @dev Schedules a release of ERC-20 tokens contingent on an external condition checker contract. Owner or manager with permission 4 can call.
     * @param token The ERC-20 token address.
     * @param recipient The address to receive the tokens.
     * @param amount The amount of tokens to release.
     * @param conditionChecker The address of the contract implementing IConditionChecker.
     * @return releaseId The ID of the conditional release.
     */
    function scheduleConditionalERC20Release(
        address token,
        address recipient,
        uint256 amount,
        address conditionChecker
    ) external onlyOwnerOrManager returns (uint256) {
         if (_isManager[msg.sender]) {
            require(_managerPermissions[msg.sender].canScheduleReleases, "SmartCryptoVault: Manager lacks permission");
        }
        require(token != address(0), "SmartCryptoVault: Token zero address");
        require(recipient != address(0), "SmartCryptoVault: Recipient zero address");
        require(amount > 0, "SmartCryptoVault: Amount must be greater than 0");
        require(conditionChecker.isContract(), "SmartCryptoVault: Condition checker must be a contract");
        require(_allowedTokens[token], "SmartCryptoVault: Token not allowed for scheduling");

        uint256 id = _conditionalReleaseCounter++;
        _conditionalReleases[id] = ConditionalRelease({
            token: token,
            isERC721: false,
            amountOrTokenId: amount,
            recipient: recipient,
            conditionChecker: IConditionChecker(conditionChecker),
            executed: false,
            cancelled: false,
            conditionMet: false // Initialize as false
        });

        emit ConditionalERC20ReleaseCreated(id, token, recipient, amount, conditionChecker);
        return id;
    }

    /**
     * @dev Schedules a release of an ERC-721 NFT contingent on an external condition checker contract. Owner or manager with permission 4 can call.
     * @param collection The ERC-721 collection address.
     * @param recipient The address to receive the NFT.
     * @param tokenId The ID of the NFT to release.
     * @param conditionChecker The address of the contract implementing IConditionChecker.
     * @return releaseId The ID of the conditional release.
     */
    function scheduleConditionalERC721Release(
        address collection,
        address recipient,
        uint256 tokenId,
        address conditionChecker
    ) external onlyOwnerOrManager returns (uint256) {
         if (_isManager[msg.sender]) {
            require(_managerPermissions[msg.sender].canScheduleReleases, "SmartCryptoVault: Manager lacks permission");
        }
        require(collection != address(0), "SmartCryptoVault: Collection zero address");
        require(recipient != address(0), "SmartCryptoVault: Recipient zero address");
        require(conditionChecker.isContract(), "SmartCryptoVault: Condition checker must be a contract");
        require(_allowedNFTCollections[collection], "SmartCryptoVault: NFT Collection not allowed for scheduling");
        // Optional: Add check that the vault owns the token ID?

        uint256 id = _conditionalReleaseCounter++;
        _conditionalReleases[id] = ConditionalRelease({
            token: collection, // Using token field for collection address
            isERC721: true,
            amountOrTokenId: tokenId,
            recipient: recipient,
            conditionChecker: IConditionChecker(conditionChecker),
            executed: false,
            cancelled: false,
            conditionMet: false // Initialize as false
        });

        emit ConditionalERC721ReleaseCreated(id, collection, recipient, tokenId, conditionChecker);
        return id;
    }


    /**
     * @dev Checks the condition for a conditional release and executes it if the condition is met,
     *      the vault is not panic locked, and the release hasn't been executed or cancelled.
     *      Can be called by anyone (incentivize with gas?). NonReentrant guard is crucial here.
     * @param releaseId The ID of the conditional release to check and execute.
     */
    function checkAndExecuteConditionalRelease(uint256 releaseId) external nonReentrant {
        ConditionalRelease storage release = _conditionalReleases[releaseId];
        require(release.recipient != address(0), "SmartCryptoVault: Release does not exist"); // Check if struct is initialized
        require(!_isPanicLocked, "SmartCryptoVault: Vault is panic locked");
        require(!release.executed, "SmartCryptoVault: Release already executed");
        require(!release.cancelled, "SmartCryptoVault: Release cancelled");

        // Check the condition if not already met
        if (!release.conditionMet) {
             release.conditionMet = release.conditionChecker.checkCondition();
        }

        require(release.conditionMet, "SmartCryptoVault: Condition not met");

        release.executed = true; // Mark executed BEFORE transfer

        if (release.isERC721) {
            // Check ownership just before transfer
             require(IERC721(release.token).ownerOf(release.amountOrTokenId) == address(this), "SmartCryptoVault: Vault does not own NFT");
             IERC721(release.token).safeTransferFrom(address(this), release.recipient, release.amountOrTokenId);
        } else {
            // Check balance just before transfer (optional but good practice)
             require(IERC20(release.token).balanceOf(address(this)) >= release.amountOrTokenId, "SmartCryptoVault: Insufficient ERC20 balance for release");
             IERC20(release.token).transfer(release.recipient, release.amountOrTokenId);
        }

        emit ConditionalReleaseExecuted(releaseId);
    }

     /**
     * @dev Cancels a conditional release before it is executed. Owner or manager with permission 5 can call.
     * @param releaseId The ID of the conditional release to cancel.
     */
    function cancelConditionalRelease(uint256 releaseId) external onlyOwnerOrManager {
         if (_isManager[msg.sender]) {
            require(_managerPermissions[msg.sender].canCancelReleases, "SmartCryptoVault: Manager lacks permission");
        }
        ConditionalRelease storage release = _conditionalReleases[releaseId];
        require(release.recipient != address(0), "SmartCryptoVault: Release does not exist");
        require(!release.executed, "SmartCryptoVault: Release already executed");
        require(!release.cancelled, "SmartCryptoVault: Release already cancelled");

        release.cancelled = true;
        emit ConditionalReleaseCancelled(releaseId);
    }

    // --- Emergency & Panic (Only Owner) ---

    /**
     * @dev Puts the vault into a panic state, preventing execution of
     *      any scheduled or conditional releases. Only Owner can call.
     */
    function panicLockVault() external onlyOwner {
        require(!_isPanicLocked, "SmartCryptoVault: Vault is already panic locked");
        _isPanicLocked = true;
        emit VaultPanicLocked();
    }

    /**
     * @dev Removes the panic lock, allowing scheduled and conditional
     *      releases to be executed again. Only Owner can call.
     */
    function panicUnlockVault() external onlyOwner {
        require(_isPanicLocked, "SmartCryptoVault: Vault is not panic locked");
        _isPanicLocked = false;
        emit VaultPanicUnlocked();
    }

    /**
     * @dev Allows the owner to withdraw a specific amount of an ERC-20 token
     *      from the vault immediately in an emergency. Only Owner can call.
     * @param token The ERC-20 token address.
     * @param amount The amount to withdraw.
     */
    function emergencyWithdrawERC20(address token, uint256 amount) external onlyOwner nonReentrant {
        require(token != address(0), "SmartCryptoVault: Zero address");
        require(amount > 0, "SmartCryptoVault: Amount must be greater than 0");
        IERC20(token).transfer(owner(), amount);
        emit EmergencyERC20Withdrawn(token, owner(), amount);
    }

    /**
     * @dev Allows the owner to withdraw a specific ERC-721 NFT
     *      from the vault immediately in an emergency. Only Owner can call.
     * @param collection The ERC-721 collection address.
     * @param tokenId The ID of the NFT to withdraw.
     */
    function emergencyWithdrawERC721(address collection, uint256 tokenId) external onlyOwner nonReentrant {
        require(collection != address(0), "SmartCryptoVault: Zero address");
         // Check ownership just before transfer
        require(IERC721(collection).ownerOf(tokenId) == address(this), "SmartCryptoVault: Vault does not own NFT");
        IERC721(collection).safeTransferFrom(address(this), owner(), tokenId);
        emit EmergencyERC721Withdrawn(collection, owner(), tokenId);
    }

    // --- Information Retrieval ---

    /**
     * @dev Gets the current balance of a specific ERC-20 token held by the vault.
     * @param token The ERC-20 token address.
     * @return uint256 The balance.
     */
    function getERC20Balance(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    /**
     * @dev Gets the number of NFTs from a specific collection held by the vault.
     * @param collection The ERC-721 collection address.
     * @return uint256 The count of NFTs.
     */
     function getERC721Balance(address collection) external view returns (uint256) {
         return IERC721(collection).balanceOf(address(this));
     }

    /**
     * @dev Gets the list of token IDs for a specific ERC-721 collection held by the vault.
     *      NOTE: Iterating over token IDs is inefficient for large collections.
     *      A better approach for large collections would be event-based tracking off-chain.
     *      This function is included for demonstration/small collections.
     * @param collection The ERC-721 collection address.
     * @return uint256[] Array of token IDs.
     */
     function getERC721TokensOfOwner(address collection) external view returns (uint256[] memory) {
        // This is a placeholder. Proper implementation often requires tracking token IDs
        // explicitly via mappings or external off-chain indexing due to gas costs of iteration.
        // Returning an empty array or throwing is safer if not implemented fully.
        // For a simple example, let's pretend we can iterate, but be aware of limitations.
        // A realistic implementation would involve iterating through a list of owned tokens
        // maintained by the contract or relying on external indexers.
        // As a placeholder, returning a dummy array or revert:
        // revert("SmartCryptoVault: Direct retrieval of all token IDs is not supported for efficiency");
        // Or return empty:
        return new uint256[](0);
     }


    /**
     * @dev Checks if an ERC-20 token is allowed for deposit/scheduling.
     * @param token The ERC-20 token address.
     * @return bool True if allowed, false otherwise.
     */
    function isAllowedToken(address token) external view returns (bool) {
        return _allowedTokens[token];
    }

     /**
     * @dev Checks if an ERC-721 collection is allowed for deposit/scheduling.
     * @param collection The ERC-721 collection address.
     * @return bool True if allowed, false otherwise.
     */
    function isAllowedNFTCollection(address collection) external view returns (bool) {
        return _allowedNFTCollections[collection];
    }


    /**
     * @dev Retrieves details for a specific scheduled release.
     * @param releaseId The ID of the scheduled release.
     * @return ScheduledRelease struct details.
     */
    function getScheduledReleaseDetails(uint256 releaseId) external view returns (ScheduledRelease memory) {
        require(releaseId < _scheduledReleaseCounter, "SmartCryptoVault: Invalid scheduled release ID");
        return _scheduledReleases[releaseId];
    }

    /**
     * @dev Retrieves details for a specific conditional release.
     * @param releaseId The ID of the conditional release.
     * @return ConditionalRelease struct details (excluding interface address).
     */
    function getConditionalReleaseDetails(uint256 releaseId) external view returns (address token, bool isERC721, uint256 amountOrTokenId, address recipient, address conditionCheckerAddr, bool executed, bool cancelled, bool conditionMet) {
        require(releaseId < _conditionalReleaseCounter, "SmartCryptoVault: Invalid conditional release ID");
         ConditionalRelease storage release = _conditionalReleases[releaseId];
        return (
            release.token,
            release.isERC721,
            release.amountOrTokenId,
            release.recipient,
            address(release.conditionChecker),
            release.executed,
            release.cancelled,
            release.conditionMet
        );
    }

    /**
     * @dev Gets the total number of scheduled releases created.
     * @return uint256 The count.
     */
    function getScheduledReleaseCount() external view returns (uint256) {
        return _scheduledReleaseCounter;
    }

    /**
     * @dev Gets the total number of conditional releases created.
     * @return uint256 The count.
     */
    function getConditionalReleaseCount() external view returns (uint256) {
        return _conditionalReleaseCounter;
    }

    /**
     * @dev Checks if the vault is currently panic locked.
     * @return bool True if locked, false otherwise.
     */
    function isPanicLocked() external view returns (bool) {
        return _isPanicLocked;
    }

    // Dummy functions for demonstrating allowed/disallowed tokens (implementation would involve iterating through mappings)
    // Getting all keys from a mapping is not standard Solidity.
    // A more robust solution would track allowed addresses in a dynamic array alongside the mapping.

    /**
     * @dev Gets the list of allowed ERC-20 token addresses.
     *      NOTE: This is a placeholder. Getting all keys from a mapping is not efficient.
     *      A real implementation needs to track allowed addresses in an array.
     * @return address[] Array of allowed token addresses.
     */
    function getAllowedTokens() external view returns (address[] memory) {
         // Revert or return empty as iterating mapping keys is not supported
        revert("SmartCryptoVault: Retrieval of all allowed tokens is not directly supported for efficiency. Track off-chain or use events.");
         // return new address[](0); // Alternatively, return empty
    }

    /**
     * @dev Gets the list of allowed ERC-721 collection addresses.
     *      NOTE: This is a placeholder. Getting all keys from a mapping is not efficient.
     *      A real implementation needs to track allowed addresses in an array.
     * @return address[] Array of allowed collection addresses.
     */
    function getAllowedNFTCollections() external view returns (address[] memory) {
        // Revert or return empty as iterating mapping keys is not supported
         revert("SmartCryptoVault: Retrieval of all allowed NFT collections is not directly supported for efficiency. Track off-chain or use events.");
         // return new address[](0); // Alternatively, return empty
    }

    // Fallback to receive Ether (optional, if contract should hold ETH)
    // receive() external payable {}
    // fallback() external payable {} // Add if you want to handle calls with data


    // Total functions implemented:
    // 1. constructor
    // 2. transferOwnership (from Ownable)
    // 3. addAllowedToken
    // 4. removeAllowedToken
    // 5. addAllowedNFTCollection
    // 6. removeAllowedNFTCollection
    // 7. depositERC20
    // 8. depositERC721
    // 9. addManager
    // 10. removeManager
    // 11. setManagerPermissions
    // 12. getManagerPermissions
    // 13. isManager
    // 14. scheduleERC20Release
    // 15. scheduleERC721Release
    // 16. executeScheduledRelease
    // 17. cancelScheduledRelease
    // 18. scheduleConditionalERC20Release
    // 19. scheduleConditionalERC721Release
    // 20. checkAndExecuteConditionalRelease
    // 21. cancelConditionalRelease
    // 22. panicLockVault
    // 23. panicUnlockVault
    // 24. emergencyWithdrawERC20
    // 25. emergencyWithdrawERC721
    // 26. getERC20Balance
    // 27. getERC721Balance
    // 28. getERC721TokensOfOwner (placeholder)
    // 29. isAllowedToken
    // 30. isAllowedNFTCollection
    // 31. getScheduledReleaseDetails
    // 32. getConditionalReleaseDetails
    // 33. getScheduledReleaseCount
    // 34. getConditionalReleaseCount
    // 35. isPanicLocked
    // 36. getAllowedTokens (placeholder)
    // 37. getAllowedNFTCollections (placeholder)
    // Total = 37 functions (including inherited and placeholders), well over 20.
}
```

**Explanation of Advanced Concepts and Design Choices:**

1.  **Multi-Asset Handling (ERC-20 & ERC-721):** Instead of just one token type, the vault can handle both, requiring separate functions for deposits, scheduling, and emergency withdrawals. `ERC721Holder` is used for secure NFT reception.
2.  **Granular Delegated Management:** The contract uses a `ManagerPermissions` struct and associated modifier/functions (`addManager`, `removeManager`, `setManagerPermissions`) to allow the owner to grant specific, limited capabilities to other addresses. This goes beyond simple multi-sig or a single admin role.
3.  **Scheduled Releases:** Introduces time-based vesting/distribution logic directly in the contract (`scheduleERC20Release`, `scheduleERC721Release`, `executeScheduledRelease`). This is a common need (e.g., token unlocks), but implemented generically for any allowed asset. Requires external "keepers" or automation to call `executeScheduledRelease` when the time is due.
4.  **Conditional Releases:** This is a more advanced concept. It relies on an external `IConditionChecker` contract. This allows the release logic to be triggered by arbitrary on-chain or off-chain (via oracle) conditions (e.g., "execute if LINK price is above X", "execute if a specific event happens in another contract"). This requires an external contract implementing the interface and external callers (keepers) to `checkAndExecuteConditionalRelease`.
5.  **Panic Functionality:** `panicLockVault` and `panicUnlockVault` provide an immediate emergency stop for automated releases, giving the owner time to assess a situation without distributions continuing. Emergency withdrawals (`emergencyWithdrawERC20`, `emergencyWithdrawERC721`) allow the owner to rescue funds.
6.  **Whitelist for Assets:** `_allowedTokens` and `_allowedNFTCollections` prevent the vault from accidentally holding unwanted or potentially malicious tokens/NFTs.
7.  **NonReentrancyGuard:** Crucial for functions that perform external calls (`executeScheduledRelease`, `checkAndExecuteConditionalRelease`, emergency withdrawals) to prevent reentrancy attacks, especially important when transferring assets.
8.  **Information Retrieval:** Numerous `view` functions allow inspecting the vault's state, balances, configuration, and scheduled/conditional releases. Note the placeholder functions for getting *all* allowed addresses or NFT token IDs, highlighting a common challenge in Solidity regarding efficient mapping iteration.

This contract structure provides a flexible foundation for various use cases, such as vesting contracts, escrow with conditions, complex distribution mechanisms, or enhanced personal vaults, showcasing several intermediate to advanced Solidity patterns and concepts.