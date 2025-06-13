Okay, here is a Solidity smart contract demonstrating several advanced, creative, and potentially trendy concepts without directly duplicating common open-source templates like standard ERC20/ERC721 factories, basic staking, or simple minting.

It combines time-based mechanics, dynamic NFTs, resource management, scheduled actions, upgradeability (via UUPS proxy pattern), and access control.

**Concept:** **ChronoForge** - A system where users can forge and refine time-sensitive "Artifacts" (ERC721 NFTs) using "Time Crystals" (an associated ERC20 token). Artifacts have properties that can evolve over time or through refinement processes. Actions like forging and refining take time, and some actions can even be scheduled for future execution by automated keepers.

**Outline:**

1.  **License and Pragma**
2.  **Imports:** OpenZeppelin contracts for ERC721, ERC20 (as a placeholder), AccessControl, Pausable, UUPS Upgradeability.
3.  **Custom Errors:** Define specific error conditions.
4.  **State Variables:**
    *   Roles (Admin, Pauser, Keeper).
    *   Contract state (paused status).
    *   Artifact data (mapping from token ID to struct).
    *   Token counters (next artifact ID).
    *   Pending processes (forging, refining).
    *   Time Vault data (user deposits with lock times).
    *   Scheduled actions data.
    *   Address of the associated Time Crystal ERC20 contract.
5.  **Structs:**
    *   `Artifact`: Defines properties like creation time, level, rarity, last refined time, and evolution deadline.
    *   `PendingProcess`: Tracks forging/refining start time, duration, target ID, and user.
    *   `TimeVaultEntry`: Tracks deposited amount, deposit time, and unlock time.
    *   `ScheduledAction`: Tracks action type, target ID, execution time, parameters, and owner.
6.  **Events:** Log significant actions (Forged, Refined, Scheduled, Executed, Paused, Upgraded, etc.).
7.  **Modifiers:** (e.g., `onlyKeeper` if using a specific keeper role, though `hasRole` is used directly).
8.  **Initializer (`initialize`):** Replaces the constructor for UUPS, sets up roles, etc.
9.  **Access Control & Pausability:** Inherited functions, plus admin functions to manage roles and pause/unpause.
10. **UUPS Upgradeability:** Override `_authorizeUpgrade`.
11. **Time Crystal Interaction:** Functions for depositing and withdrawing Time Crystals from a time-locked vault. (Assumes Time Crystal contract exists and handles transfers).
12. **Artifact Forging:**
    *   `forgeArtifact`: Start a forging process (requires TC, takes time).
    *   `claimForgedArtifact`: Claim a newly forged artifact after the time elapses.
13. **Artifact Refining:**
    *   `refineArtifact`: Start a refining process for an existing artifact (requires TC, takes time).
    *   `claimRefinedArtifact`: Claim a refined artifact after the time elapses, potentially updating stats.
14. **Process Management:**
    *   `speedUpProcess`: Use more Time Crystals to reduce the remaining time for a pending process.
15. **Scheduled Actions:**
    *   `scheduleRefineAction`: Schedule a *future* refining process for an artifact (requires TC upfront, specifies execution time).
    *   `cancelScheduledRefineAction`: Cancel a scheduled action before it executes (potential partial TC refund).
    *   `executeScheduledAction`: Called by a designated "Keeper" role *at or after* the scheduled time to trigger the action (e.g., start the scheduled refine process).
16. **View Functions:**
    *   Get artifact details.
    *   Get forging/refining status.
    *   Get Time Vault entry details.
    *   Get scheduled action details.
    *   Check process completion status.
17. **ERC721 Required Functions:** Implement `tokenURI` to generate metadata dynamically based on artifact state.

**Function Summary:**

1.  `initialize(address initialAdmin, address initialTimeCrystal)`: Initializes the contract, sets admin, pauser, and keeper roles, and sets the Time Crystal contract address. (Public, External)
2.  `pause()`: Pauses contract functionality (Admin role). (Public, External)
3.  `unpause()`: Unpauses contract functionality (Admin role). (Public, External)
4.  `grantRole(bytes32 role, address account)`: Grants a role (Admin role). (Public, External, Inherited)
5.  `revokeRole(bytes32 role, address account)`: Revokes a role (Admin role). (Public, External, Inherited)
6.  `renounceRole(bytes32 role, address account)`: Renounces a role (Any user for their own role). (Public, External, Inherited)
7.  `setTimeCrystalContract(address timeCrystalAddress)`: Sets the address of the Time Crystal ERC20 contract (Admin role). (Public, External)
8.  `depositTimeCrystals(uint256 amount, uint256 lockDuration)`: Deposits Time Crystals into a time-locked vault. Requires approval for the contract to spend TC. (Public, External)
9.  `withdrawTimeCrystals(uint256 amount)`: Withdraws Time Crystals from the vault after their lock duration has passed. (Public, External)
10. `forgeArtifact()`: Starts a forging process for a new artifact. Costs Time Crystals and takes time. (Public, External)
11. `claimForgedArtifact()`: Claims the newly forged artifact after the forging time is complete. (Public, External)
12. `refineArtifact(uint256 artifactId)`: Starts a refinement process for an existing artifact. Costs Time Crystals and takes time. (Public, External)
13. `claimRefinedArtifact(uint256 artifactId)`: Claims the refined artifact after the refinement time is complete. May update artifact properties. (Public, External)
14. `speedUpProcess(uint256 processId, uint256 processType, uint256 crystalsToSpend)`: Uses Time Crystals to reduce the remaining time on a pending forging or refining process. (Public, External)
15. `scheduleRefineAction(uint256 artifactId, uint256 executionTimestamp, bytes data)`: Schedules a future refining action for an artifact at a specific timestamp. Costs Time Crystals upfront. `data` could contain refinement parameters. (Public, External)
16. `cancelScheduledRefineAction(uint256 actionId)`: Cancels a pending scheduled action. May refund some Time Crystals. (Public, External)
17. `executeScheduledAction(uint256 actionId)`: Executed by a Keeper role to trigger a scheduled action at or after its execution time. (Public, External, Keeper role)
18. `getArtifactDetails(uint256 artifactId)`: Returns the details of an artifact. (Public, View)
19. `getForgingStatus()`: Returns the details of the current pending forging process for the caller. (Public, View)
20. `getRefiningStatus(uint256 artifactId)`: Returns the details of the pending refining process for a specific artifact. (Public, View)
21. `getTimeVaultDetails(address user)`: Returns the details of a user's Time Vault deposits. (Public, View)
22. `getScheduledActionDetails(uint256 actionId)`: Returns the details of a scheduled action. (Public, View)
23. `isProcessComplete(uint256 startTime, uint256 duration)`: Helper view function to check if a time-based process is complete. (Public, Pure)
24. `tokenURI(uint256 tokenId)`: Returns the metadata URI for an artifact, potentially dynamic based on its properties. (Public, View, Override)
25. `_authorizeUpgrade(address newImplementation)`: Override for UUPS to restrict upgrade calls to the admin. (Internal, Override)

**(Note:** The contract will also inherit standard ERC721, ERC20 (for the *interface* via SafeERC20), AccessControl, and Pausable functions like `balanceOf`, `ownerOf`, `transferFrom`, `paused`, `hasRole`, etc., making the total number of callable functions significantly higher than 25).

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol"; // Might be useful for time calculations

// ChronoForge: A smart contract for forging, refining, and managing time-sensitive Artifact NFTs
// using Time Crystal ERC20 tokens, featuring scheduled actions and upgradeability.

// Outline:
// 1. License and Pragma
// 2. Imports (OpenZeppelin)
// 3. Custom Errors
// 4. State Variables (Roles, Counters, Contract Addresses, Data Mappings)
// 5. Struct Definitions (Artifact, PendingProcess, TimeVaultEntry, ScheduledAction)
// 6. Event Definitions
// 7. Constants
// 8. Initializer (for UUPS)
// 9. Access Control & Pausability (Inherited + Custom Mgmt)
// 10. UUPS Upgradeability Hook
// 11. Time Crystal Interaction (Vault)
// 12. Artifact Forging Logic
// 13. Artifact Refining Logic
// 14. Process Management (Speed Up)
// 15. Scheduled Actions Logic (Schedule, Cancel, Execute)
// 16. View Functions
// 17. ERC721 Metadata Implementation (tokenURI)

// Function Summary:
// - initialize: Setup contract (roles, TC address).
// - pause/unpause: Control contract state (Admin).
// - grant/revoke/renounceRole: Manage access control (Admin).
// - setTimeCrystalContract: Set Time Crystal address (Admin).
// - depositTimeCrystals: Deposit TC into time-locked vault.
// - withdrawTimeCrystals: Withdraw TC from vault after lock.
// - forgeArtifact: Start crafting a new artifact.
// - claimForgedArtifact: Finish crafting and claim artifact.
// - refineArtifact: Start improving an existing artifact.
// - claimRefinedArtifact: Finish improving and claim artifact.
// - speedUpProcess: Use TC to reduce process time.
// - scheduleRefineAction: Queue a future refinement.
// - cancelScheduledRefineAction: Remove a scheduled action.
// - executeScheduledAction: Trigger a scheduled action (Keeper).
// - getArtifactDetails: View artifact stats.
// - getForgingStatus: View caller's forging process.
// - getRefiningStatus: View artifact's refining process.
// - getTimeVaultDetails: View user's vault status.
// - getScheduledActionDetails: View a specific scheduled action.
// - isProcessComplete: Helper to check time completion.
// - tokenURI: Generate dynamic metadata URI.
// - _authorizeUpgrade: UUPS upgrade protection.

contract ChronoForge is ERC721Upgradeable, AccessControlUpgradeable, PausableUpgradeable, UUPSUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256; // Add SafeMath for time calculations potentially

    // --- State Variables ---

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");

    enum ProcessType { None, Forging, Refining }

    struct Artifact {
        uint256 creationTime;
        uint256 level; // Can increase with refinement/evolution
        uint256 rarity; // Maybe set at forge time
        uint256 lastRefinedTime; // Timestamp of last refinement completion
        uint256 evolutionDeadline; // Time when artifact might "evolve" or gain property
        // Add more dynamic properties here
    }

    struct PendingProcess {
        ProcessType processType;
        uint256 startTime;
        uint256 duration;
        uint256 targetId; // TokenId for Refining, unique ID for Forging
        address user; // Owner of the process/artifact
    }

    struct TimeVaultEntry {
        uint256 amount;
        uint256 depositTime;
        uint256 unlockTime;
    }

    // Scheduled actions could be generic, but let's type them for simplicity
    enum ScheduledActionType { None, RefineArtifact }

    struct ScheduledAction {
        ScheduledActionType actionType;
        uint256 targetId; // Artifact ID for refining
        uint256 executionTimestamp; // The time the action *can* be executed
        address owner; // User who scheduled the action
        bool executed; // Has this action been triggered?
        bytes data; // Optional data for the action (e.g., refinement parameters)
        // Add more fields as needed
    }

    CountersUpgradeable.Counter private _artifactIds;
    CountersUpgradeable.Counter private _processIds; // Separate counter for forging processes
    CountersUpgradeable.Counter private _scheduledActionIds;

    mapping(uint256 => Artifact) private _artifacts;
    mapping(address => uint256) private _userPendingForgeProcess; // Maps user to their pending forging process ID
    mapping(uint256 => PendingProcess) private _pendingProcesses; // Maps process ID to PendingProcess struct
    mapping(uint256 => uint256) private _artifactPendingRefineProcess; // Maps artifact ID to pending refining process ID

    mapping(address => TimeVaultEntry[]) private _timeVault; // User can have multiple vault entries

    mapping(uint256 => ScheduledAction) private _scheduledActions; // Maps action ID to struct

    IERC20Upgradeable private _timeCrystal;

    // --- Custom Errors ---
    error InvalidRole();
    error ZeroAddress();
    error ProcessNotFound();
    error ProcessAlreadyActive(ProcessType currentType);
    error ProcessNotComplete(uint256 remainingTime);
    error InvalidProcessType();
    error TimeCrystalContractNotSet();
    error InsufficientTimeCrystals(uint256 required, uint256 available);
    error TransferFailed();
    error VaultEntryNotFound();
    error VaultEntryLocked(uint256 remainingTime);
    error NothingToWithdraw();
    error ArtifactNotFound();
    error CannotRefineDuringProcess();
    error ScheduledActionNotFound();
    error ScheduledActionAlreadyExecuted();
    error ScheduledActionNotReady(uint256 timeUntilReady);
    error OnlyKeeperCanExecute();

    // --- Events ---
    event Initialized(uint8 version);
    event Paused(address account);
    event Unpaused(address account);
    event RoleGranted(bytes32 role, address account, address sender);
    event RoleRevoked(bytes32 role, address account, address sender);
    event TimeCrystalContractSet(address timeCrystalAddress);
    event TimeCrystalsDeposited(address user, uint256 amount, uint256 lockDuration);
    event TimeCrystalsWithdrawn(address user, uint256 amount);
    event ForgingProcessStarted(uint256 processId, address user, uint256 duration);
    event ArtifactForged(uint256 artifactId, uint256 processId, address owner);
    event RefiningProcessStarted(uint256 processId, address user, uint256 artifactId, uint256 duration);
    event ArtifactRefined(uint256 artifactId, uint256 processId, address owner, uint256 newLevel); // Example property change
    event ProcessTimeAccelerated(uint256 processId, uint256 processType, address user, uint256 timeReduced, uint256 crystalsSpent);
    event ActionScheduled(uint256 actionId, ScheduledActionType actionType, uint256 targetId, uint256 executionTimestamp, address owner);
    event ActionCancelled(uint256 actionId, address owner);
    event ActionExecuted(uint256 actionId, address executor);
    event Upgrade(address indexed implementation);

    // --- Initializer ---
    function initialize(address initialAdmin, address initialTimeCrystal) public initializer {
        if (initialAdmin == address(0) || initialTimeCrystal == address(0)) {
            revert ZeroAddress();
        }

        __ERC721_init("ChronoForge Artifact", "CFA");
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        _grantRole(PAUSER_ROLE, initialAdmin); // Admin is also initially the pauser
        // KEEPER_ROLE is initially not granted to admin unless specified.
        // Granting KEEPER_ROLE requires a separate call by the admin.

        _timeCrystal = IERC20Upgradeable(initialTimeCrystal);
        emit TimeCrystalContractSet(initialTimeCrystal);

        emit Initialized(1); // Version 1
    }

    // --- Access Control ---
    // Overrides for AccessControlUpgradeable
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Inherits grantRole, revokeRole, renounceRole, hasRole

    function setKeeperRole(address account, bool grant) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (grant) {
            grantRole(KEEPER_ROLE, account);
        } else {
            revokeRole(KEEPER_ROLE, account);
        }
    }

    // --- Pausability ---
    // Inherits pause, unpause, paused

    // --- UUPS Upgradeability ---
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    // --- Time Crystal Interaction (Vault) ---
    function depositTimeCrystals(uint256 amount, uint256 lockDuration) external whenNotPaused {
        if (address(_timeCrystal) == address(0)) revert TimeCrystalContractNotSet();
        if (amount == 0) revert InsufficientTimeCrystals(1, 0); // Or specific error for zero amount

        // Transfer Time Crystals from user to this contract
        _timeCrystal.safeTransferFrom(msg.sender, address(this), amount);

        // Record the deposit in the user's vault entries
        uint256 unlockTime = block.timestamp.add(lockDuration);
        _timeVault[msg.sender].push(TimeVaultEntry({
            amount: amount,
            depositTime: block.timestamp,
            unlockTime: unlockTime
        }));

        emit TimeCrystalsDeposited(msg.sender, amount, lockDuration);
    }

    function withdrawTimeCrystals(uint256 entryIndex, uint256 amount) external whenNotPaused {
        if (address(_timeCrystal) == address(0)) revert TimeCrystalContractNotSet();
        if (entryIndex >= _timeVault[msg.sender].length) revert VaultEntryNotFound();
        if (amount == 0) revert NothingToWithdraw();

        TimeVaultEntry storage entry = _timeVault[msg.sender][entryIndex];

        if (block.timestamp < entry.unlockTime) {
            revert VaultEntryLocked(entry.unlockTime.sub(block.timestamp));
        }

        if (amount > entry.amount) revert InsufficientTimeCrystals(amount, entry.amount);

        entry.amount = entry.amount.sub(amount);

        // Transfer Time Crystals from this contract back to user
        _timeCrystal.safeTransfer(msg.sender, amount);

        // If entry is fully withdrawn, could remove it or mark as zero.
        // Leaving zero entries simplifies index management but increases storage slightly.
        // For this example, we leave it and just reduce amount.

        emit TimeCrystalsWithdrawn(msg.sender, amount);
    }

    // --- Artifact Forging Logic ---
    uint256 public FORGE_COST = 100 ether; // Example cost
    uint256 public FORGE_DURATION = 1 days; // Example duration

    function forgeArtifact() external whenNotPaused {
        if (address(_timeCrystal) == address(0)) revert TimeCrystalContractNotSet();
        if (_userPendingForgeProcess[msg.sender] != 0) revert ProcessAlreadyActive(ProcessType.Forging);

        // Require Time Crystals
        _timeCrystal.safeTransferFrom(msg.sender, address(this), FORGE_COST);

        // Create a new process ID
        _processIds.increment();
        uint256 processId = _processIds.current();

        // Store the pending forging process
        _pendingProcesses[processId] = PendingProcess({
            processType: ProcessType.Forging,
            startTime: block.timestamp,
            duration: FORGE_DURATION,
            targetId: 0, // No artifact ID yet for forging
            user: msg.sender
        });

        // Link the user to this process
        _userPendingForgeProcess[msg.sender] = processId;

        emit ForgingProcessStarted(processId, msg.sender, FORGE_DURATION);
    }

    function claimForgedArtifact() external whenNotPaused {
        uint256 processId = _userPendingForgeProcess[msg.sender];
        if (processId == 0) revert ProcessNotFound();

        PendingProcess storage process = _pendingProcesses[processId];
        if (process.processType != ProcessType.Forging || process.user != msg.sender) revert ProcessNotFound(); // Double check ownership/type

        uint256 completionTime = process.startTime.add(process.duration);
        if (block.timestamp < completionTime) {
            revert ProcessNotComplete(completionTime.sub(block.timestamp));
        }

        // Mint the new artifact
        _artifactIds.increment();
        uint256 newArtifactId = _artifactIds.current();

        _mintArtifact(msg.sender, newArtifactId);

        // Define initial artifact properties (can be simple or based on time/randomness)
        _artifacts[newArtifactId] = Artifact({
            creationTime: block.timestamp,
            level: 1,
            rarity: 1, // Example: Could be randomized
            lastRefinedTime: 0,
            evolutionDeadline: block.timestamp.add(365 days) // Example: Evolves after a year
        });

        // Clean up the pending process
        delete _pendingProcesses[processId];
        delete _userPendingForgeProcess[msg.sender];

        emit ArtifactForged(newArtifactId, processId, msg.sender);
    }

    // Internal helper for minting, separates logic from forging flow
    function _mintArtifact(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId);
    }

    // --- Artifact Refining Logic ---
    uint256 public REFINE_COST_PER_LEVEL = 50 ether; // Example cost scaling
    uint256 public REFINE_DURATION_PER_LEVEL = 12 hours; // Example duration scaling

    function refineArtifact(uint256 artifactId) external whenNotPaused {
        if (address(_timeCrystal) == address(0)) revert TimeCrystalContractNotSet();

        address owner = ownerOf(artifactId);
        if (owner != msg.sender) revert ERC721AccessControl(msg.sender, artifactId); // Check artifact ownership

        if (_artifactPendingRefineProcess[artifactId] != 0) revert ProcessAlreadyActive(ProcessType.Refining);

        Artifact storage artifact = _artifacts[artifactId];
        uint256 cost = REFINE_COST_PER_LEVEL.mul(artifact.level);
        uint256 duration = REFINE_DURATION_PER_LEVEL.mul(artifact.level); // Refining takes longer as level increases

        // Require Time Crystals
        _timeCrystal.safeTransferFrom(msg.sender, address(this), cost);

        // Create a new process ID
        _processIds.increment();
        uint256 processId = _processIds.current();

        // Store the pending refining process
        _pendingProcesses[processId] = PendingProcess({
            processType: ProcessType.Refining,
            startTime: block.timestamp,
            duration: duration,
            targetId: artifactId,
            user: msg.sender
        });

        // Link the artifact to this process
        _artifactPendingRefineProcess[artifactId] = processId;

        // Mark the artifact as being refined (optional state in struct)

        emit RefiningProcessStarted(processId, msg.sender, artifactId, duration);
    }

    function claimRefinedArtifact(uint256 artifactId) external whenNotPaused {
        address owner = ownerOf(artifactId); // Checks artifact existence implicitly
        if (owner != msg.sender) revert ERC721AccessControl(msg.sender, artifactId);

        uint256 processId = _artifactPendingRefineProcess[artifactId];
        if (processId == 0) revert ProcessNotFound();

        PendingProcess storage process = _pendingProcesses[processId];
        if (process.processType != ProcessType.Refining || process.targetId != artifactId || process.user != msg.sender) revert ProcessNotFound();

        uint256 completionTime = process.startTime.add(process.duration);
        if (block.timestamp < completionTime) {
            revert ProcessNotComplete(completionTime.sub(block.timestamp));
        }

        Artifact storage artifact = _artifacts[artifactId];

        // Apply refinement effects (example: increase level)
        artifact.level = artifact.level.add(1);
        artifact.lastRefinedTime = block.timestamp;

        // Clean up the pending process
        delete _pendingProcesses[processId];
        delete _artifactPendingRefineProcess[artifactId];

        // No token transfer needed, state update is sufficient for dynamic NFTs

        emit ArtifactRefined(artifactId, processId, msg.sender, artifact.level);
    }

    // --- Process Management ---
    function speedUpProcess(uint256 processId, uint256 crystalsToSpend) external whenNotPaused {
         if (address(_timeCrystal) == address(0)) revert TimeCrystalContractNotSet();
         if (crystalsToSpend == 0) revert InsufficientTimeCrystals(1, 0); // Or specific error

         PendingProcess storage process = _pendingProcesses[processId];
         if (process.processType == ProcessType.None) revert ProcessNotFound();
         if (process.user != msg.sender) revert ERC721AccessControl(msg.sender, processId); // Using ERC721 error code pattern

         uint256 timeElapsed = block.timestamp.sub(process.startTime);
         uint256 timeRemaining = process.duration > timeElapsed ? process.duration.sub(timeElapsed) : 0;

         if (timeRemaining == 0) revert ProcessNotComplete(0);

         // Example logic: 1 Crystal reduces time by N seconds
         uint256 timeReductionRate = 60; // 1 crystal = 60 seconds reduction
         uint256 maxTimeReductionPossible = crystalsToSpend.mul(timeReductionRate);
         uint256 actualTimeReduced = timeRemaining > maxTimeReductionPossible ? maxTimeReductionPossible : timeRemaining;
         uint256 actualCrystalsSpent = actualTimeReduced > 0 ? actualTimeReduced.div(timeReductionRate) : 0;

         if (actualCrystalsSpent > 0) {
            // Transfer Time Crystals from user to this contract
            _timeCrystal.safeTransferFrom(msg.sender, address(this), actualCrystalsSpent);

            // Effectively "speed up" by advancing the start time
            process.startTime = process.startTime.add(actualTimeReduced);

            emit ProcessTimeAccelerated(processId, process.processType, msg.sender, actualTimeReduced, actualCrystalsSpent);
         } else {
             // Maybe revert if 0 time reduced, or let it pass if crystalsToSpend > 0
             // Current logic requires actualCrystalsSpent > 0 due to transfer.
         }
    }


    // --- Scheduled Actions Logic ---
    // Action ID for scheduled actions.

    function scheduleRefineAction(uint256 artifactId, uint256 executionTimestamp, bytes calldata data) external whenNotPaused {
        if (address(_timeCrystal) == address(0)) revert TimeCrystalContractNotSet();

        address owner = ownerOf(artifactId);
        if (owner != msg.sender) revert ERC721AccessControl(msg.sender, artifactId);

        if (executionTimestamp <= block.timestamp) revert ScheduledActionNotReady(executionTimestamp.sub(block.timestamp)); // Must be in the future

        // Example cost for scheduling - could be fixed or variable
        uint256 schedulingCost = REFINE_COST_PER_LEVEL.mul(_artifacts[artifactId].level).div(2); // Half cost upfront? Example

        // Require Time Crystals upfront
        _timeCrystal.safeTransferFrom(msg.sender, address(this), schedulingCost);

        _scheduledActionIds.increment();
        uint256 actionId = _scheduledActionIds.current();

        _scheduledActions[actionId] = ScheduledAction({
            actionType: ScheduledActionType.RefineArtifact,
            targetId: artifactId,
            executionTimestamp: executionTimestamp,
            owner: msg.sender,
            executed: false,
            data: data // Store any extra data needed for the action
        });

        emit ActionScheduled(actionId, ScheduledActionType.RefineArtifact, artifactId, executionTimestamp, msg.sender);
    }

    function cancelScheduledRefineAction(uint256 actionId) external whenNotPaused {
        ScheduledAction storage action = _scheduledActions[actionId];

        if (action.actionType == ScheduledActionType.None) revert ScheduledActionNotFound();
        if (action.owner != msg.sender) revert ERC721AccessControl(msg.sender, actionId); // Check ownership of scheduled action
        if (action.executed) revert ScheduledActionAlreadyExecuted();
        if (action.executionTimestamp <= block.timestamp) revert ScheduledActionNotReady(0); // Cannot cancel if already eligible for execution

        // Refund logic example: refund a percentage of the cost
        uint256 refundAmount = REFINE_COST_PER_LEVEL.mul(_artifacts[action.targetId].level).div(4); // Example: Refund 25%

        if (refundAmount > 0) {
            // Transfer refund to user
            _timeCrystal.safeTransfer(msg.sender, refundAmount);
        }

        // Mark as cancelled (or delete, but marking is safer for history)
        delete _scheduledActions[actionId]; // Simple delete for this example

        emit ActionCancelled(actionId, msg.sender);
    }

    // This function is intended to be called by automated "Keeper" bots or a dedicated service.
    // It must check the execution time and role.
    function executeScheduledAction(uint256 actionId) external whenNotPaused onlyRole(KEEPER_ROLE) {
        ScheduledAction storage action = _scheduledActions[actionId];

        if (action.actionType == ScheduledActionType.None) revert ScheduledActionNotFound();
        if (action.executed) revert ScheduledActionAlreadyExecuted();
        if (block.timestamp < action.executionTimestamp) {
            revert ScheduledActionNotReady(action.executionTimestamp.sub(block.timestamp));
        }

        // Mark as executed BEFORE attempting the action to prevent re-entrancy/double execution
        action.executed = true;

        // Execute the specific action based on type
        if (action.actionType == ScheduledActionType.RefineArtifact) {
            // Ensure artifact exists and is owned by the scheduler (or is not owned, depending on logic)
            // Here, we assume the artifact must still be owned by the user who scheduled it
            // or transfer it to a temp holding during refinement. Simpler approach: check owner.
             address artifactOwner = ownerOf(action.targetId);
             if (artifactOwner != action.owner) {
                 // Action fails if owner changed. Log and handle.
                 // Could implement more complex logic like transferring to contract, then back.
                 // For simplicity, we just mark as executed but don't proceed with refinement.
                 emit ActionExecuted(actionId, msg.sender);
                 // Maybe add an event ActionExecutionFailed?
                 return; // Exit without executing the refinement
             }

             // Check if artifact is currently undergoing manual refinement
             if (_artifactPendingRefineProcess[action.targetId] != 0) {
                  // Artifact is busy. Mark as executed but don't proceed.
                  emit ActionExecuted(actionId, msg.sender);
                  return;
             }

            // --- Execute Refinement Logic ---
            // This mirrors the start of manual refineArtifact but is triggered by the keeper
            // The cost was paid upfront during scheduling.
            // The duration and level increase logic is the same.

             Artifact storage artifact = _artifacts[action.targetId];
             uint256 duration = REFINE_DURATION_PER_LEVEL.mul(artifact.level); // Use current level

             // Create a new process ID for this keeper-triggered refinement
            _processIds.increment();
            uint256 processId = _processIds.current();

            // Store the pending refining process
            _pendingProcesses[processId] = PendingProcess({
                processType: ProcessType.Refining,
                startTime: block.timestamp,
                duration: duration,
                targetId: action.targetId,
                user: action.owner // The user who scheduled it is the 'owner' of this process
            });

            // Link the artifact to this process
            _artifactPendingRefineProcess[action.targetId] = processId;

            // Note: The user (action.owner) will still need to call claimRefinedArtifact later
            // to complete the process and apply effects. Keepers only *start* the process.

            emit RefiningProcessStarted(processId, action.owner, action.targetId, duration); // Log as if user started it, but include keeper
        }

        emit ActionExecuted(actionId, msg.sender);
        // Scheduled action data could be deleted here if not needed for history
    }

    // --- View Functions ---

    function getArtifactDetails(uint256 artifactId) public view returns (Artifact memory) {
        if (!_exists(artifactId)) revert ArtifactNotFound(); // ERC721 exists check
        return _artifacts[artifactId];
    }

    function getForgingStatus() public view returns (PendingProcess memory) {
        uint256 processId = _userPendingForgeProcess[msg.sender];
        if (processId == 0) return PendingProcess({ processType: ProcessType.None, startTime: 0, duration: 0, targetId: 0, user: address(0) });
        return _pendingProcesses[processId];
    }

    function getRefiningStatus(uint256 artifactId) public view returns (PendingProcess memory) {
        // No need to check artifact ownership here, just status
        uint256 processId = _artifactPendingRefineProcess[artifactId];
        if (processId == 0) return PendingProcess({ processType: ProcessType.None, startTime: 0, duration: 0, targetId: 0, user: address(0) });
        return _pendingProcesses[processId];
    }

    function getTimeVaultDetails(address user) public view returns (TimeVaultEntry[] memory) {
        return _timeVault[user];
    }

     function getScheduledActionDetails(uint256 actionId) public view returns (ScheduledAction memory) {
        return _scheduledActions[actionId]; // Returns zero-struct if not found
    }

    function isProcessComplete(uint256 startTime, uint256 duration) public view returns (bool) {
        if (startTime == 0) return false; // Process wasn't started properly
        return block.timestamp >= startTime.add(duration);
    }

    // --- ERC721 Metadata Implementation ---
    // This is crucial for Dynamic NFTs. The URI should point to a service
    // that generates metadata based on the artifact's current state queried from this contract.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert ERC721NonexistentToken(tokenId);

        // Example: Construct a URL pointing to an off-chain metadata service
        // The service would query this contract using getArtifactDetails(tokenId)
        // and format the JSON metadata.
        string memory baseURI = "https://chronoforge.example.com/metadata/";
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    // --- Fallback/Receive (Optional but good practice for receiving ETH) ---
    // receive() external payable {}
    // fallback() external payable {}

    // --- Internal Helper for _paused ---
    // This is needed for `whenNotPaused` modifier compatibility with UUPS
    function _paused() internal view override returns (bool) {
        return super._paused();
    }
}
```

**Explanation of Advanced/Creative Concepts:**

1.  **UUPS Upgradeability:** The contract uses the UUPS proxy pattern (`UUPSUpgradeable`), allowing the logic contract to be replaced while maintaining state in the proxy contract. This is a standard but advanced pattern for enabling future feature additions or bug fixes.
2.  **Dynamic NFTs (Artifacts):** The `Artifact` struct includes properties (`level`, `lastRefinedTime`, `evolutionDeadline`) that change based on interactions within the contract (`refineArtifact`, `claimRefinedArtifact`). The `tokenURI` function is designed to point to an off-chain service that can read these on-chain properties and generate dynamic metadata (image, stats, etc.) reflecting the artifact's current state.
3.  **Resource Management (Time Crystals):** Introduces a fungible token (`IERC20Upgradeable`) as a core resource required for actions like forging, refining, and speeding up processes. Requires standard ERC20 approval/transfer patterns.
4.  **Time-Locked Vault:** The `TimeVault` feature allows users to deposit Time Crystals for a minimum duration. Withdrawals are only possible after the `unlockTime`. This is a form of staking/locking mechanism integrated into the resource system.
5.  **Time-Based Processes:** Forging and Refining are not instant. They require a specific duration (`FORGE_DURATION`, `REFINE_DURATION`). Users start a process and must wait (or speed it up) before claiming the result. This adds strategic depth and prevents instant gratification.
6.  **Process Acceleration (`speedUpProcess`):** Users can spend additional Time Crystals to reduce the remaining time on a pending forging or refining process, adding a "pay-to-skip" or "pay-to-accelerate" mechanic common in games.
7.  **Scheduled Actions:** The `scheduleRefineAction` allows a user to pay upfront to queue a future action (like refining) to occur at a specific time. This action is then triggered by a separate entity (a "Keeper" role) via `executeScheduledAction`. This pattern is useful for offloading time-sensitive execution to dedicated bots or services, ensuring actions happen even if the original user is offline, and it's a crucial pattern for building complex automated systems on-chain.
8.  **Access Control for Keepers:** The `KEEPER_ROLE` demonstrates a clear separation of concerns, allowing only authorized addresses to trigger scheduled actions, preventing arbitrary calls.
9.  **Custom Errors:** Using `revert CustomError(...)` provides more gas-efficient and informative error messages compared to simple strings, which is a best practice in modern Solidity.
10. **Structs for Complex State:** Using structs (`Artifact`, `PendingProcess`, `TimeVaultEntry`, `ScheduledAction`) organizes related data cleanly within mappings.
11. **Use of OpenZeppelin Libraries:** Leverages battle-tested standards for ERC721, AccessControl, Pausability, and UUPS, focusing the custom code on the unique game/system mechanics.
12. **Explicit Process Tracking:** Separate mappings track pending processes (`_userPendingForgeProcess`, `_artifactPendingRefineProcess`, `_pendingProcesses`) to manage concurrent activities for users and artifacts.

This contract provides a foundation for a sophisticated on-chain system with evolving assets and time-sensitive interactions, going beyond typical simple token or NFT contracts. Remember that a real-world implementation would also need significant off-chain components (like the metadata service, the Time Crystal ERC20 contract, and keeper bots) to function fully.