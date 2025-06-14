Okay, let's create a smart contract concept that's interesting, advanced, and not a direct copy of common open-source templates like standard ERC-20/721 implementations, DEXs, or lending protocols.

We'll design a "Chronicle Sentinel Protocol" contract. This contract will manage unique, non-standard "Sentinel" NFTs. These Sentinels are partially soulbound, gain experience (Chronicle Points - CP) by performing on-chain "Tasks", level up based on CP, and develop "Capabilities" that change their behavior or utility within the protocol or potentially interacting protocols. They have complex transfer restrictions and a delegation mechanism.

**Concept:**

A protocol centered around earning non-transferable points (CP) via interactive "Tasks" using unique "Sentinel" NFTs. Sentinels level up, gaining capabilities, but are generally bound to the owner with specific, restricted transfer conditions.

**Key Advanced/Interesting Features:**

1.  **Dynamic State NFTs:** Sentinels have evolving stats (CP, Level, Capabilities).
2.  **Partial Soulbound / Restricted Transfer:** Sentinels are *not* freely transferable like standard ERC-721s. Transfers are gated by conditions (e.g., cooldowns, owner-initiated unlock for a single transfer).
3.  **Task-Based Progression:** Users interact with the contract by "completing tasks" which are defined protocol mechanics rewarding CP. Tasks can have varying requirements and cooldowns.
4.  **Leveling System:** CP accumulates to level up Sentinels based on a configurable curve.
5.  **Capabilities:** Leveling grants or improves Capabilities (abstract stats like Strength, Intellect, etc.) which can influence future task completion, delegation effectiveness, or interact with other systems.
6.  **Delegation:** Owners can delegate the right to complete tasks *using* their Sentinel to another address, without transferring ownership.
7.  **Discovery/Minting with Cost:** A specific function to "discover" (mint) a new Sentinel, potentially requiring payment.
8.  **Configurable Parameters:** Core aspects like task rewards, leveling curve, capability growth, transfer cooldowns, and discovery costs are owner-configurable.
9.  **Internal ERC721 Implementation:** Instead of inheriting a standard library like OpenZeppelin for the *entire* ERC721 logic, we will implement the necessary ERC721 functions manually, ensuring the custom transfer logic is deeply integrated, thus avoiding direct duplication of the standard library *pattern*.

---

**Contract Outline:**

1.  **SPDX License and Pragma**
2.  **Error Definitions**
3.  **Interfaces** (ERC721 - for clarity, though implemented internally)
4.  **Structs:**
    *   `Capabilities`: Represents Sentinel stats.
    *   `Sentinel`: Core state of a Sentinel (CP, level, owner, status, etc.).
    *   `Task`: Definition of a task (reward, cooldown, requirements, etc.).
    *   `CapabilitiesGrowthRate`: How capabilities increase per level.
5.  **Enums:** `SentinelStatus`, `TaskStatus`.
6.  **Events:** Signal key actions (Mint, Level Up, Task Completed, Delegation, Transfer Restricted, etc.).
7.  **State Variables:** Mappings for Sentinels, Tasks, task history, ownership, approvals, balances, delegates, transfer restrictions, configuration parameters. Counters for IDs and total supply.
8.  **Modifiers:** `onlyOwner`.
9.  **Internal Helper Functions:** For ERC721 transfers, checking transfer restrictions, calculating CP needed, updating capabilities.
10. **Core ERC721 Functions (Custom Implementation):** `balanceOf`, `ownerOf`, `tokenURI`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, `transferFrom`, `safeTransferFrom`. These will call internal helpers that enforce custom logic.
11. **Sentinel Management Functions:**
    *   `discoverSentinel` (Minting)
    *   `getSentinelDetails`
    *   `getSentinelCapabilities`
    *   `getSentinelStatus`
    *   `getLevelForCP` (Helper view)
    *   `getCpNeededForNextLevel` (Helper view)
    *   `getTotalSentinels` (Helper view)
12. **Task Management Functions (Owner Only):**
    *   `defineTask`
    *   `updateTask`
    *   `deactivateTask`
    *   `setTaskCooldown`
    *   `setTaskCpReward`
    *   `setTaskRequiredLevel`
    *   `setTaskRequiredEth`
13. **Task Interaction Functions:**
    *   `getTaskDetails` (View)
    *   `getTaskCount` (View)
    *   `canCompleteTask` (View - checks requirements)
    *   `completeTask` (User interaction to earn CP)
    *   `getSentinelTaskCompletionCount` (View)
    *   `getLastTaskCompletionTime` (View)
14. **Delegation Functions:**
    *   `delegateTaskExecution`
    *   `clearDelegate`
    *   `getDelegate` (View)
15. **Transfer Restriction Functions:**
    *   `setSentinelTransferable` (Owner/Conditional, initiates cooldown)
    *   `getSentinelTransferableStatus` (View)
    *   `getTransferCooldownUntil` (View)
    *   `setTransferCooldownDuration` (Owner)
16. **Retirement/Burning Function:**
    *   `retireSentinel`
17. **Configuration Functions (Owner Only):**
    *   `setBaseURI`
    *   `setDiscoveryCost`
    *   `setBaseCPPerLevel`
    *   `setLevelCPMultiplier`
    *   `setCapabilitiesGrowthRate`
    *   `withdrawEth`
18. **View Functions for Configuration:**
    *   `getBaseURI`
    *   `getDiscoveryCost`
    *   `getBaseCPPerLevel`
    *   `getLevelCPMultiplier`
    *   `getCapabilitiesGrowthRate`
    *   `getContractBalance`

**Total Functions (Including ERC721 required ones):** ~40+, well over the 20 requested.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// --- Contract Outline ---
// 1. SPDX License and Pragma
// 2. Error Definitions
// 3. Interfaces (ERC721 - for clarity, core logic implemented internally)
// 4. Structs: Capabilities, Sentinel, Task, CapabilitiesGrowthRate
// 5. Enums: SentinelStatus, TaskStatus
// 6. Events: Signal state changes (Mint, Level Up, Task Completed, Delegation, Transfer Restricted, etc.)
// 7. State Variables: Mappings for Sentinels, Tasks, task history, ownership, approvals, balances, delegates, transfer restrictions, configuration parameters. Counters for IDs and total supply.
// 8. Modifiers: onlyOwner
// 9. Internal Helper Functions: _transfer, _safeTransfer, _checkTransferRestriction, _addCP, _checkLevelUp, _updateCapabilities, _calculateNextLevelCP, _exists, _isApprovedOrOwner, _msgSenderERC721
// 10. Core ERC721 Functions (Custom Implementation): balanceOf, ownerOf, tokenURI, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom (These enforce custom rules)
// 11. Sentinel Management Functions: discoverSentinel, getSentinelDetails, getSentinelCapabilities, getSentinelStatus, getLevelForCP, getCpNeededForNextLevel, getTotalSentinels
// 12. Task Management Functions (Owner Only): defineTask, updateTask, deactivateTask, setTaskCooldown, setTaskCpReward, setTaskRequiredLevel, setTaskRequiredEth
// 13. Task Interaction Functions: getTaskDetails, getTaskCount, canCompleteTask, completeTask, getSentinelTaskCompletionCount, getLastTaskCompletionTime
// 14. Delegation Functions: delegateTaskExecution, clearDelegate, getDelegate
// 15. Transfer Restriction Functions: setSentinelTransferable, getSentinelTransferableStatus, getTransferCooldownUntil, setTransferCooldownDuration
// 16. Retirement/Burning Function: retireSentinel
// 17. Configuration Functions (Owner Only): setBaseURI, setDiscoveryCost, setBaseCPPerLevel, setLevelCPMultiplier, setCapabilitiesGrowthRate, withdrawEth
// 18. View Functions for Configuration: getBaseURI, getDiscoveryCost, getBaseCPPerLevel, getLevelCPMultiplier, getCapabilitiesGrowthRate, getContractBalance

// --- Function Summary ---
// constructor(): Initializes the contract owner.
// discoverSentinel(): Mints a new Sentinel NFT upon payment of discoveryCost. Assigns initial state.
// getSentinelDetails(uint256 tokenId): Returns the full state of a Sentinel.
// getSentinelCapabilities(uint256 tokenId): Returns the capabilities of a Sentinel.
// getSentinelStatus(uint256 tokenId): Returns the current status (Active, Resting, Retired) of a Sentinel.
// getLevelForCP(uint256 cp): Calculates and returns the level corresponding to a given CP amount based on the current curve.
// getCpNeededForNextLevel(uint256 currentLevel): Calculates CP required to reach the next level.
// getTotalSentinels(): Returns the total number of Sentinels ever discovered.
// defineTask(string memory name, string memory description, uint256 requiredLevel, uint256 cpReward, uint256 cooldownDuration, uint256 requiredEth): Owner function to add a new task type.
// updateTask(uint256 taskId, string memory name, string memory description, uint256 requiredLevel, uint256 cpReward, uint256 cooldownDuration, uint256 requiredEth): Owner function to modify an existing task.
// deactivateTask(uint256 taskId, bool active): Owner function to toggle task availability.
// setTaskCooldown(uint256 taskId, uint256 duration): Owner function to set cooldown for a specific task.
// setTaskCpReward(uint256 taskId, uint256 reward): Owner function to set CP reward for a task.
// setTaskRequiredLevel(uint256 taskId, uint256 level): Owner function to set level requirement for a task.
// setTaskRequiredEth(uint256 taskId, uint256 ethAmount): Owner function to set required ETH payment for a task.
// getTaskDetails(uint256 taskId): Returns the details of a specific task.
// getTaskCount(): Returns the total number of defined task types.
// canCompleteTask(uint256 tokenId, uint256 taskId): Checks if a Sentinel meets the requirements and is off cooldown for a task.
// completeTask(uint256 tokenId, uint256 taskId): Executes a task for a Sentinel, awards CP, checks for level ups, enforces cooldowns and requirements. Payable if task requires ETH.
// getSentinelTaskCompletionCount(uint256 tokenId, uint256 taskId): Returns how many times a Sentinel completed a specific task.
// getLastTaskCompletionTime(uint256 tokenId, uint256 taskId): Returns the timestamp of the last time a Sentinel completed a specific task.
// delegateTaskExecution(uint256 tokenId, address delegatee): Allows the owner to set an address that can complete tasks for the Sentinel.
// clearDelegate(uint256 tokenId): Removes the delegate for a Sentinel.
// getDelegate(uint256 tokenId): Returns the current delegate for a Sentinel.
// setSentinelTransferable(uint256 tokenId, bool transferable): Owner function to flag a specific Sentinel as temporarily transferable. Sets a cooldown after transfer.
// getSentinelTransferableStatus(uint256 tokenId): Returns whether a Sentinel is currently flagged as transferable.
// getTransferCooldownUntil(uint256 tokenId): Returns the timestamp until which a Sentinel cannot be transferred after a restricted transfer.
// setTransferCooldownDuration(uint256 duration): Owner function to set the protocol-wide cooldown after a restricted transfer.
// retireSentinel(uint256 tokenId): Marks a Sentinel as retired (burned) and performs the ERC721 transfer to address(0).
// setBaseURI(string memory baseURI_): Owner function to set the base URI for metadata.
// setDiscoveryCost(uint256 cost): Owner function to set the ETH cost for discovering a Sentinel.
// setBaseCPPerLevel(uint256 base): Owner function to configure the base CP needed for level 1.
// setLevelCPMultiplier(uint256 multiplier): Owner function to configure the multiplier for CP needed per subsequent level.
// setCapabilitiesGrowthRate(uint256 strength, uint256 intellect, uint256 agility, uint256 stamina): Owner function to configure how much each capability increases per level.
// withdrawEth(address payable recipient): Owner function to withdraw ETH held in the contract.
// getBaseURI(): View function to get the current base URI.
// getDiscoveryCost(): View function to get the current discovery cost.
// getBaseCPPerLevel(): View function.
// getLevelCPMultiplier(): View function.
// getCapabilitiesGrowthRate(): View function.
// getContractBalance(): View function to get the contract's ETH balance.
// --- Custom ERC721 Implementations (Required by ERC721 Standard, but custom logic applied) ---
// ownerOf(uint256 tokenId): Returns owner or reverts if not found.
// balanceOf(address owner): Returns count of owned tokens.
// approve(address to, uint256 tokenId): Approves an address for a specific token (subject to restrictions).
// getApproved(uint256 tokenId): Returns the approved address for a token.
// setApprovalForAll(address operator, bool approved): Approves/disapproves an operator for all tokens (subject to restrictions).
// isApprovedForAll(address owner, address operator): Checks operator approval status.
// transferFrom(address from, address to, uint256 tokenId): Transfers token, enforcing custom transfer restrictions.
// safeTransferFrom(address from, address to, uint256 tokenId): Transfers token safely, enforcing custom transfer restrictions.

// --- Error Definitions ---
error NotOwner();
error NotApprovedOrOwner();
error TokenDoesNotExist();
error TokenAlreadyExists();
error InvalidRecipient();
error TransferRestricted();
error TransferCooldownActive(uint256 until);
error TaskDoesNotExist();
error TaskInactive();
error SentinelInsufficientLevel(uint256 required, uint256 current);
error TaskCooldownActive(uint256 until);
error InsufficientEthForTask(uint256 required, uint256 sent);
error InvalidTaskCompletion();
error DiscoveryCostNotMet(uint256 required, uint256 sent);
error SentinelAlreadyRetired();
error InvalidOwner();
error InvalidOperator();
error ERC721InvalidRecipient(); // Standard ERC721 Error

// --- Interfaces ---
// Define a minimal ERC721 interface for clarity,
// even though we implement the functions directly.
interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint255 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address approved);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// Minimal ERC721Receiver interface for safeTransferFrom
interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}


contract ChronicleSentinelProtocol is IERC721 { // Inherit interface for standard compatibility markers

    // --- Structs ---
    struct Capabilities {
        uint256 strength;
        uint256 intellect;
        uint256 agility;
        uint256 stamina;
    }

    struct Sentinel {
        uint256 tokenId;
        address owner; // Redundant with _owners, but useful for struct lookup
        uint256 chroniclePoints;
        uint256 level;
        Capabilities capabilities;
        uint256 discoveryTime;
        SentinelStatus status;
        address delegatee; // Address allowed to complete tasks for this sentinel
    }

    struct Task {
        uint256 taskId;
        string name;
        string description;
        uint256 requiredLevel;
        uint256 cpReward;
        uint256 cooldownDuration; // In seconds
        uint256 requiredEth; // ETH needed to complete this task
        TaskStatus status;
    }

    struct CapabilitiesGrowthRate {
         uint256 strengthPerLevel;
         uint256 intellectPerLevel;
         uint256 agilityPerLevel;
         uint256 staminaPerLevel;
    }

    // --- Enums ---
    enum SentinelStatus {
        Active,
        Resting, // Placeholder for potential future rest mechanics
        Retired // Effectively burned
    }

    enum TaskStatus {
        Inactive,
        Active
    }

    // --- Events ---
    event SentinelDiscovered(uint256 indexed tokenId, address indexed owner, uint256 discoveryTime);
    event ChroniclePointsGained(uint256 indexed tokenId, uint256 amount, uint256 newTotalCP);
    event SentinelLeveledUp(uint256 indexed tokenId, uint256 newLevel, uint256 newCapabilitiesHash); // Use hash to represent capabilities change
    event SentinelCapabilitiesUpdated(uint256 indexed tokenId, Capabilities newCapabilities);
    event TaskDefined(uint256 indexed taskId, string name);
    event TaskUpdated(uint256 indexed taskId, string name);
    event TaskCompleted(uint256 indexed tokenId, uint256 indexed taskId, address indexed caller, uint256 cpAwarded);
    event DelegationSet(uint256 indexed tokenId, address indexed delegator, address indexed delegatee);
    event DelegationCleared(uint256 indexed tokenId, address indexed delegator);
    event SentinelTransferabilityChanged(uint256 indexed tokenId, bool isTransferable, uint256 cooldownUntil);
    event SentinelRetired(uint256 indexed tokenId, address indexed owner);

    // --- State Variables ---
    address private _owner;
    uint256 private _tokenSupply;
    uint256 private _nextTaskId;

    // --- ERC721 Standard Mappings (Custom Implementation) ---
    mapping(uint256 => address) private _owners; // Token ID to Owner Address
    mapping(address => uint256) private _balances; // Owner Address to Token Count
    mapping(uint256 => address) private _tokenApprovals; // Token ID to Approved Address
    mapping(address => mapping(address => bool)) private _operatorApprovals; // Owner Address to Operator Address to Approval Status

    // --- Protocol Specific Mappings ---
    mapping(uint256 => Sentinel) private _sentinels; // Token ID to Sentinel struct
    mapping(uint256 => Task) private _tasks; // Task ID to Task struct
    mapping(uint256 => mapping(uint256 => uint256)) private _sentinelTaskHistory; // tokenId => taskId => completionCount
    mapping(uint256 => mapping(uint256 => uint256)) private _lastTaskCompletion; // tokenId => taskId => timestamp

    // --- Transfer Restrictions ---
    mapping(uint256 => bool) private _isSentinelTransferable; // Explicitly allowed to be transferred (e.g., once)
    mapping(uint256 => uint256) private _transferCooldown; // Timestamp until transfer is restricted after a transfer
    uint256 private _transferCooldownDuration = 365 days; // Default cooldown after restricted transfer

    // --- Configuration Parameters ---
    string private _baseURI;
    uint256 private _discoveryCost = 0.01 ether; // Default cost to mint
    uint256 private _baseCPPerLevel = 100; // CP needed for level 1
    uint256 private _levelCPMultiplier = 50; // Additional CP needed per level after level 1
    CapabilitiesGrowthRate private _capabilitiesGrowthRate = CapabilitiesGrowthRate({
        strengthPerLevel: 1,
        intellectPerLevel: 1,
        agilityPerLevel: 1,
        staminaPerLevel: 1
    });

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != _owner) revert NotOwner();
        _;
    }

    // --- Constructor ---
    constructor() {
        _owner = msg.sender;
        _tokenSupply = 0;
        _nextTaskId = 1; // Start task IDs from 1
    }

    // --- Internal ERC721 Helpers ---

    // Helper to check if token exists and is not address(0) owner
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    // Helper to get the owner or revert
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert TokenDoesNotExist();
        return owner;
    }

     // Helper to check if sender is owner or approved
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address tokenOwner = ownerOf(tokenId); // Reverts if token doesn't exist
        return (spender == tokenOwner || getApproved(tokenId) == spender || isApprovedForAll(tokenOwner, spender));
    }

    // ERC721 _transfer implementation including custom restrictions
    function _transfer(address from, address to, uint256 tokenId) internal {
        if (ownerOf(tokenId) != from) revert InvalidOwner(); // Reverts if token doesn't exist
        if (to == address(0)) revert ERC721InvalidRecipient(); // Cannot transfer to zero address except for burn

        // --- Custom Transfer Restriction Logic ---
        if (!_isSentinelTransferable[tokenId]) {
             revert TransferRestricted();
        }
        if (_transferCooldown[tokenId] > block.timestamp) {
            revert TransferCooldownActive(_transferCooldown[tokenId]);
        }
        // --- End Custom Logic ---

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        // Update ERC721 state
        _balances[from]--;
        _owners[tokenId] = to;
        _balances[to]++;

        // Update Sentinel struct owner (redundant but ensures consistency)
        _sentinels[tokenId].owner = to;

        // Reset transferability status and set cooldown AFTER a successful transfer
        _isSentinelTransferable[tokenId] = false;
        _transferCooldown[tokenId] = block.timestamp + _transferCooldownDuration;

        emit Transfer(from, to, tokenId);
    }

    // --- ERC721 Required Functions (Overridden) ---

    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert InvalidOwner();
        return _balances[owner];
    }

    function approve(address to, uint256 tokenId) public override {
        // ERC721 standard check: sender must be owner or operator
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert NotApprovedOrOwner();
        // Custom: Cannot approve if transfer is restricted, unless sender is owner
        // This prevents delegate/operator from granting approvals if transfer is locked.
        if (!_isSentinelTransferable[tokenId] && msg.sender != ownerOf(tokenId)) revert TransferRestricted();

        _approve(to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal {
         _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override {
         if (operator == msg.sender) revert InvalidOperator(); // Cannot approve self as operator

        // Custom: Cannot grant operator rights if transfer is restricted
        // This prevents locking assets by approving operators then restricting transfers.
        // This check applies to the *owner* granting approval.
        // We'll handle the restriction check in the transfer functions themselves.

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        // Basic ERC721 checks
        if (_isApprovedOrOwner(msg.sender, tokenId)) {
             // Custom: _transfer contains the core restriction logic
            _transfer(from, to, tokenId);
        } else {
            revert NotApprovedOrOwner();
        }
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        transferFrom(from, to, tokenId); // Uses our custom transfer logic
        // Standard safeTransferFrom checks receiver
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) revert ERC721InvalidRecipient();
            } catch (bytes memory reason) {
                 // Handle potential revert reason from receiver
                 if (reason.length > 0) {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                 } else {
                     revert ERC721InvalidRecipient();
                 }
            }
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        // Basic implementation assuming metadata is hosted off-chain at _baseURI + tokenId
        return string(abi.encodePacked(_baseURI, Strings.toString(tokenId)));
    }


    // --- Sentinel Management Functions ---

    function discoverSentinel() public payable returns (uint256 tokenId) {
        if (msg.value < _discoveryCost) revert DiscoveryCostNotMet(_discoveryCost, msg.value);
        if (msg.sender == address(0)) revert InvalidRecipient();

        _tokenSupply++;
        tokenId = _tokenSupply;

        _owners[tokenId] = msg.sender;
        _balances[msg.sender]++;

        _sentinels[tokenId] = Sentinel({
            tokenId: tokenId,
            owner: msg.sender,
            chroniclePoints: 0,
            level: 1, // Start at level 1
            capabilities: Capabilities({ strength: _capabilitiesGrowthRate.strengthPerLevel, intellect: _capabilitiesGrowthRate.intellectPerLevel, agility: _capabilitiesGrowthRate.agilityPerLevel, stamina: _capabilitiesGrowthRate.staminaPerLevel }),
            discoveryTime: block.timestamp,
            status: SentinelStatus.Active,
            delegatee: address(0)
        });

        // Initially not transferable, requires owner action
        _isSentinelTransferable[tokenId] = false;
        _transferCooldown[tokenId] = 0; // No cooldown initially

        emit SentinelDiscovered(tokenId, msg.sender, block.timestamp);
        emit Transfer(address(0), msg.sender, tokenId); // ERC721 Mint event

        return tokenId;
    }

    function getSentinelDetails(uint256 tokenId) public view returns (Sentinel memory) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        return _sentinels[tokenId];
    }

    function getSentinelCapabilities(uint256 tokenId) public view returns (Capabilities memory) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        return _sentinels[tokenId].capabilities;
    }

    function getSentinelStatus(uint256 tokenId) public view returns (SentinelStatus) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        return _sentinels[tokenId].status;
    }

    // Helper function to calculate level from CP based on current curve
    function getLevelForCP(uint256 cp) public view returns (uint256) {
        uint256 currentLevel = 1;
        uint256 cpNeeded = _baseCPPerLevel;

        while (cp >= cpNeeded) {
            cp -= cpNeeded;
            currentLevel++;
            cpNeeded = _baseCPPerLevel + (currentLevel - 1) * _levelCPMultiplier;
            if (cpNeeded == 0) break; // Prevent infinite loop if multiplier is zero
        }
        return currentLevel;
    }

    // Helper function to get CP needed for the next level
    function getCpNeededForNextLevel(uint256 currentLevel) public view returns (uint256) {
         // CP needed to reach level X from level X-1
         return _baseCPPerLevel + (currentLevel - 1) * _levelCPMultiplier;
    }

    function getTotalSentinels() public view returns (uint256) {
        return _tokenSupply;
    }

    // --- Task Management Functions (Owner Only) ---

    function defineTask(
        string memory name,
        string memory description,
        uint256 requiredLevel,
        uint256 cpReward,
        uint256 cooldownDuration,
        uint256 requiredEth
    ) public onlyOwner returns (uint256 taskId) {
        taskId = _nextTaskId;
        _tasks[taskId] = Task({
            taskId: taskId,
            name: name,
            description: description,
            requiredLevel: requiredLevel,
            cpReward: cpReward,
            cooldownDuration: cooldownDuration,
            requiredEth: requiredEth,
            status: TaskStatus.Active
        });
        _nextTaskId++;
        emit TaskDefined(taskId, name);
        return taskId;
    }

    function updateTask(
        uint256 taskId,
        string memory name,
        string memory description,
        uint256 requiredLevel,
        uint256 cpReward,
        uint256 cooldownDuration,
        uint256 requiredEth
    ) public onlyOwner {
        if (_tasks[taskId].taskId == 0) revert TaskDoesNotExist(); // Check if task ID exists
        Task storage task = _tasks[taskId];
        task.name = name;
        task.description = description;
        task.requiredLevel = requiredLevel;
        task.cpReward = cpReward;
        task.cooldownDuration = cooldownDuration;
        task.requiredEth = requiredEth;
        // Status is updated via deactivateTask
        emit TaskUpdated(taskId, name);
    }

    function deactivateTask(uint256 taskId, bool active) public onlyOwner {
        if (_tasks[taskId].taskId == 0) revert TaskDoesNotExist();
        _tasks[taskId].status = active ? TaskStatus.Active : TaskStatus.Inactive;
        emit TaskUpdated(taskId, _tasks[taskId].name); // Reuse event
    }

    function setTaskCooldown(uint256 taskId, uint256 duration) public onlyOwner {
         if (_tasks[taskId].taskId == 0) revert TaskDoesNotExist();
        _tasks[taskId].cooldownDuration = duration;
    }

     function setTaskCpReward(uint256 taskId, uint256 reward) public onlyOwner {
        if (_tasks[taskId].taskId == 0) revert TaskDoesNotExist();
        _tasks[taskId].cpReward = reward;
    }

     function setTaskRequiredLevel(uint256 taskId, uint256 level) public onlyOwner {
        if (_tasks[taskId].taskId == 0) revert TaskDoesNotExist();
        _tasks[taskId].requiredLevel = level;
    }

     function setTaskRequiredEth(uint256 taskId, uint256 ethAmount) public onlyOwner {
        if (_tasks[taskId].taskId == 0) revert TaskDoesNotExist();
        _tasks[taskId].requiredEth = ethAmount;
    }


    // --- Task Interaction Functions ---

    function getTaskDetails(uint256 taskId) public view returns (Task memory) {
        if (_tasks[taskId].taskId == 0) revert TaskDoesNotExist();
        return _tasks[taskId];
    }

    function getTaskCount() public view returns (uint256) {
        return _nextTaskId - 1; // Since taskId starts at 1
    }

    function canCompleteTask(uint256 tokenId, uint256 taskId) public view returns (bool, string memory) {
        if (!_exists(tokenId)) return (false, "Sentinel does not exist");
        if (_tasks[taskId].taskId == 0) return (false, "Task does not exist");

        Sentinel storage sentinel = _sentinels[tokenId];
        Task storage task = _tasks[taskId];

        if (task.status != TaskStatus.Active) return (false, "Task is inactive");
        if (sentinel.status != SentinelStatus.Active) return (false, "Sentinel is not active");
        if (sentinel.level < task.requiredLevel) return (false, string(abi.encodePacked("Level too low, requires ", Strings.toString(task.requiredLevel))));
        if (_lastTaskCompletion[tokenId][taskId] + task.cooldownDuration > block.timestamp) {
            return (false, string(abi.encodePacked("Task on cooldown, available after ", Strings.toString(_lastTaskCompletion[tokenId][taskId] + task.cooldownDuration))));
        }
        // Note: Does not check ETH requirement here, that's a runtime check in completeTask
        return (true, "Ready");
    }


    function completeTask(uint256 tokenId, uint256 taskId) public payable {
        // Check if sender is owner or delegate
        address tokenOwner = ownerOf(tokenId);
        if (msg.sender != tokenOwner && msg.sender != _sentinels[tokenId].delegatee) {
            revert InvalidTaskCompletion(); // Only owner or delegate can complete tasks
        }

        if (!_exists(tokenId)) revert TokenDoesNotExist();
        if (_tasks[taskId].taskId == 0) revert TaskDoesNotExist();

        Sentinel storage sentinel = _sentinels[tokenId];
        Task storage task = _tasks[taskId];

        if (task.status != TaskStatus.Active) revert TaskInactive();
        if (sentinel.status != SentinelStatus.Active) revert SentinelAlreadyRetired(); // Reusing error, maybe add SentinelInactive/Resting
        if (sentinel.level < task.requiredLevel) revert SentinelInsufficientLevel(task.requiredLevel, sentinel.level);

        uint256 lastCompletion = _lastTaskCompletion[tokenId][taskId];
        if (lastCompletion + task.cooldownDuration > block.timestamp) {
            revert TaskCooldownActive(lastCompletion + task.cooldownDuration);
        }

        if (msg.value < task.requiredEth) revert InsufficientEthForTask(task.requiredEth, msg.value);

        // Process task completion
        _sentinelTaskHistory[tokenId][taskId]++;
        _lastTaskCompletion[tokenId][taskId] = block.timestamp;

        // Grant CP and check for level up
        _addCP(tokenId, task.cpReward);

        emit TaskCompleted(tokenId, taskId, msg.sender, task.cpReward);
    }

    function getSentinelTaskCompletionCount(uint256 tokenId, uint256 taskId) public view returns (uint256) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        if (_tasks[taskId].taskId == 0) revert TaskDoesNotExist();
        return _sentinelTaskHistory[tokenId][taskId];
    }

     function getLastTaskCompletionTime(uint256 tokenId, uint256 taskId) public view returns (uint256) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        if (_tasks[taskId].taskId == 0) revert TaskDoesNotExist();
        return _lastTaskCompletion[tokenId][taskId];
    }


    // Internal CP/Leveling Helpers
    function _addCP(uint256 tokenId, uint256 amount) internal {
        if (amount == 0) return; // No CP to add

        Sentinel storage sentinel = _sentinels[tokenId];
        sentinel.chroniclePoints += amount;

        emit ChroniclePointsGained(tokenId, amount, sentinel.chroniclePoints);

        _checkLevelUp(tokenId);
    }

    function _checkLevelUp(uint256 tokenId) internal {
        Sentinel storage sentinel = _sentinels[tokenId];
        uint256 currentLevel = sentinel.level;
        uint256 cp = sentinel.chroniclePoints;

        uint256 nextLevel = currentLevel + 1;
        uint256 cpNeededForNextLevel = getCpNeededForNextLevel(currentLevel); // CP needed to reach current level + 1

        // Loop while current CP is sufficient for the next level
        // Note: This handles multiple level ups from a single task completion
        while (cp >= cpNeededForNextLevel) {
            // Subtract CP needed for this level
            cp -= cpNeededForNextLevel; // CP rolls over for the next level threshold

            // Level up!
            currentLevel = nextLevel;
            sentinel.level = currentLevel;
            sentinel.chroniclePoints = cp; // Update remaining CP after leveling

            // Update capabilities based on the new level
            _updateCapabilities(tokenId);

            // Calculate CP needed for the *next* next level
            nextLevel = currentLevel + 1;
            cpNeededForNextLevel = getCpNeededForNextLevel(currentLevel);

            // Emit event *after* capabilities are updated
             // Simple hash approximation for capabilities change
            uint256 capabilitiesHash = sentinel.capabilities.strength +
                                      sentinel.capabilities.intellect +
                                      sentinel.capabilities.agility +
                                      sentinel.capabilities.stamina;
            emit SentinelLeveledUp(tokenId, currentLevel, capabilitiesHash);

             // Safety break for ridiculously high CP or zero multiplier
             if (cpNeededForNextLevel == 0 || currentLevel >= 1000) break; // Arbitrary max level or zero multiplier break
        }
        // Update remaining CP *if* it wasn't set in the loop (i.e., didn't level up fully or at all)
         if(sentinel.level == currentLevel) { // Check if level didn't change in the loop condition
             sentinel.chroniclePoints = cp; // Ensure final CP is stored
         }

    }

    function _updateCapabilities(uint256 tokenId) internal {
        Sentinel storage sentinel = _sentinels[tokenId];
        // Capabilities are calculated cumulatively based on level and growth rate
        // For simplicity, let's assume growth rate is *per level gain* rather than total level
        // This function is called *after* a level up, so we add the growth rate once.
        sentinel.capabilities.strength += _capabilitiesGrowthRate.strengthPerLevel;
        sentinel.capabilities.intellect += _capabilitiesGrowthRate.intellectPerLevel;
        sentinel.capabilities.agility += _capabilitiesGrowthRate.agilityPerLevel;
        sentinel.capabilities.stamina += _capabilitiesGrowthRate.staminaPerLevel;

        emit SentinelCapabilitiesUpdated(tokenId, sentinel.capabilities);
    }


    // --- Delegation Functions ---

    function delegateTaskExecution(uint256 tokenId, address delegatee) public {
        if (msg.sender != ownerOf(tokenId)) revert NotOwner(); // Only owner can delegate
        if (!_exists(tokenId)) revert TokenDoesNotExist();

        _sentinels[tokenId].delegatee = delegatee;
        emit DelegationSet(tokenId, msg.sender, delegatee);
    }

    function clearDelegate(uint256 tokenId) public {
         if (msg.sender != ownerOf(tokenId)) revert NotOwner(); // Only owner can clear delegate
         if (!_exists(tokenId)) revert TokenDoesNotExist();

        _sentinels[tokenId].delegatee = address(0);
        emit DelegationCleared(tokenId, msg.sender);
    }

    function getDelegate(uint256 tokenId) public view returns (address) {
         if (!_exists(tokenId)) revert TokenDoesNotExist();
         return _sentinels[tokenId].delegatee;
    }

    // --- Transfer Restriction Functions ---

    // Owner can temporarily enable transferability for a specific token.
    // A successful transfer then triggers a cooldown period where it cannot be transferred again.
    function setSentinelTransferable(uint256 tokenId, bool transferable) public onlyOwner {
         if (!_exists(tokenId)) revert TokenDoesNotExist();
         // Cannot set transferable if already in cooldown
         if (transferable && _transferCooldown[tokenId] > block.timestamp) {
             revert TransferCooldownActive(_transferCooldown[tokenId]);
         }

        _isSentinelTransferable[tokenId] = transferable;
        // If setting to transferable, clear any existing cooldown just in case (shouldn't happen due to check above)
        if (transferable) {
             _transferCooldown[tokenId] = 0;
        }
        emit SentinelTransferabilityChanged(tokenId, transferable, _transferCooldown[tokenId]);
    }

    function getSentinelTransferableStatus(uint256 tokenId) public view returns (bool) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        // Status is true ONLY if explicitly set AND not in cooldown
        return _isSentinelTransferable[tokenId] && _transferCooldown[tokenId] <= block.timestamp;
    }

     function getTransferCooldownUntil(uint256 tokenId) public view returns (uint256) {
         if (!_exists(tokenId)) revert TokenDoesNotExist();
         return _transferCooldown[tokenId];
     }

    function setTransferCooldownDuration(uint256 duration) public onlyOwner {
        _transferCooldownDuration = duration;
    }


    // --- Retirement/Burning Function ---
    function retireSentinel(uint256 tokenId) public {
        if (msg.sender != ownerOf(tokenId)) revert NotOwner();
        if (!_exists(tokenId)) revert TokenDoesNotExist();

        Sentinel storage sentinel = _sentinels[tokenId];
        if (sentinel.status == SentinelStatus.Retired) revert SentinelAlreadyRetired();

        sentinel.status = SentinelStatus.Retired;
        sentinel.delegatee = address(0); // Clear delegate upon retirement

        // Perform ERC721 burn (transfer to address(0))
        address from = ownerOf(tokenId);
        _approve(address(0), tokenId); // Clear approvals
        _balances[from]--;
        _owners[tokenId] = address(0); // Set owner to zero address
        // Note: _tokenSupply is not decreased, it represents total ever minted.

        emit SentinelRetired(tokenId, from);
        emit Transfer(from, address(0), tokenId); // ERC721 Burn event
    }

    // --- Configuration Functions (Owner Only) ---

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseURI = baseURI_;
    }

    function setDiscoveryCost(uint256 cost) public onlyOwner {
        _discoveryCost = cost;
    }

    function setBaseCPPerLevel(uint256 base) public onlyOwner {
        _baseCPPerLevel = base;
    }

    function setLevelCPMultiplier(uint256 multiplier) public onlyOwner {
        _levelCPMultiplier = multiplier;
    }

    function setCapabilitiesGrowthRate(uint256 strength, uint256 intellect, uint256 agility, uint256 stamina) public onlyOwner {
        _capabilitiesGrowthRate = CapabilitiesGrowthRate({
            strengthPerLevel: strength,
            intellectPerLevel: intellect,
            agilityPerLevel: agility,
            staminaPerLevel: stamina
        });
    }

    function withdrawEth(address payable recipient) public onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success, ) = recipient.call{value: balance}("");
            require(success, "ETH withdrawal failed");
        }
    }

    // --- View Functions for Configuration ---

    function getBaseURI() public view returns (string memory) {
        return _baseURI;
    }

    function getDiscoveryCost() public view returns (uint256) {
        return _discoveryCost;
    }

    function getBaseCPPerLevel() public view returns (uint256) {
        return _baseCPPerLevel;
    }

    function getLevelCPMultiplier() public view returns (uint256) {
        return _levelCPMultiplier;
    }

     function getCapabilitiesGrowthRate() public view returns (CapabilitiesGrowthRate memory) {
        return _capabilitiesGrowthRate;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // --- Library for String Conversion (Helper for tokenURI and error messages) ---
    library Strings {
        function toString(uint256 value) internal pure returns (string memory) {
            if (value == 0) {
                return "0";
            }
            uint256 temp = value;
            uint256 digits;
            while (temp != 0) {
                digits++;
                temp /= 10;
            }
            bytes memory buffer = new bytes(digits);
            while (value != 0) {
                digits -= 1;
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
            }
            return string(buffer);
        }
    }
}
```