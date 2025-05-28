Okay, let's create a smart contract concept focused on managing "temporal assets" and "scheduled actions" tied to various complex trigger conditions. We'll call it `ChronoSphere`.

This contract will allow users to lock assets (Ether or ERC20) and define actions (transfers, contract calls) that can only be executed when specific "temporal anchors" are triggered. Temporal anchors can be triggered by time, manual intervention (permissioned), dependencies on other anchors, or even pseudo-probabilistic conditions derived from block data.

This combines elements of timed locks, conditional execution, and event-driven logic in a non-standard way, aiming for the "interesting, advanced, creative, and trendy" aspects without duplicating common patterns like standard vesting, simple timelocks, or basic NFTs/DeFi primitives.

---

## ChronoSphere Smart Contract

**Outline:**

1.  **Introduction:** A contract to manage and trigger assets/actions based on diverse temporal and conditional anchors. Users can lock funds and schedule operations to occur upon complex trigger conditions being met.
2.  **Core Components:**
    *   **Temporal Anchors:** Unique points or conditions in time/state that act as triggers.
    *   **Trigger Types:** Different mechanisms to trigger an anchor (Time, Manual, Dependency, Probabilistic).
    *   **Locked Assets:** Ether or ERC20 tokens locked within the contract, associated with specific anchors.
    *   **Scheduled Actions:** Defined operations (transfers, contract calls) linked to anchors, executed only after the anchor is triggered.
3.  **Modules:**
    *   **Admin/Ownership:** Management of contract state, pausing, ownership.
    *   **Anchor Management:** Creation and definition of different types of temporal anchors.
    *   **Asset Management:** Deposit, tracking, and claiming of locked assets.
    *   **Action Scheduling:** Defining and linking actions to anchors.
    *   **Triggering Mechanism:** Functions to check trigger conditions and mark anchors as triggered.
    *   **Execution/Claiming:** Functions for users/callers to claim unlocked assets or execute scheduled actions post-trigger.
    *   **Querying:** View functions to retrieve contract state, anchor details, locked balances, etc.

**Function Summary (28 Functions):**

1.  `constructor()`: Initializes the contract owner.
2.  `transferOwnership(address newOwner)`: Transfers contract ownership (Admin).
3.  `pause()`: Pauses the contract (Admin).
4.  `unpause()`: Unpauses the contract (Admin).
5.  `createTimeAnchor(uint256 triggerTimestamp)`: Creates an anchor triggered at a specific timestamp.
6.  `createManualAnchor()`: Creates an anchor that can only be triggered manually by the owner/permissioned role.
7.  `createDependencyAnchor(uint256 requiredAnchorId)`: Creates an anchor triggered when another specific anchor is triggered.
8.  `createProbabilisticAnchor(uint256 probabilityBasis)`: Creates an anchor that triggers based on a block data pseudo-random check (e.g., `block.timestamp % probabilityBasis == 0`). `probabilityBasis` of 1 means always triggers, higher numbers mean lower probability.
9.  `depositEtherForAnchor(uint256 anchorId)`: Deposits Ether, locking it to a specific anchor.
10. `depositERC20ForAnchor(uint256 anchorId, address tokenAddress, uint256 amount)`: Deposits ERC20 tokens, locking them to a specific anchor.
11. `scheduleEtherTransfer(uint256 anchorId, address recipient, uint256 amount)`: Schedules an Ether transfer action linked to an anchor.
12. `scheduleERC20Transfer(uint256 anchorId, address tokenAddress, address recipient, uint256 amount)`: Schedules an ERC20 transfer action linked to an anchor.
13. `scheduleContractCall(uint256 anchorId, address target, uint256 value, bytes memory callData)`: Schedules a generic contract call action linked to an anchor.
14. `checkAndTriggerAnchor(uint256 anchorId)`: Anyone can call to check if an anchor's conditions are met and trigger it if so.
15. `triggerManualAnchor(uint256 anchorId)`: Owner/Permissioned function to trigger a manual anchor.
16. `claimUnlockedEther(uint256 anchorId)`: User claims Ether locked to a triggered anchor.
17. `claimUnlockedERC20(uint256 anchorId, address tokenAddress)`: User claims ERC20 locked to a triggered anchor.
18. `executeScheduledActions(uint256 anchorId)`: Executes all pending scheduled actions for a triggered anchor.
19. `getAnchorDetails(uint256 anchorId)`: View function to get details of an anchor.
20. `getAnchorStatus(uint256 anchorId)`: View function to check if an anchor is triggered.
21. `getUserLockedBalanceEther(address user, uint256 anchorId)`: View function for user's locked Ether for a specific anchor.
22. `getUserLockedBalanceERC20(address user, uint256 anchorId, address tokenAddress)`: View function for user's locked ERC20 for a specific anchor and token.
23. `getAnchorScheduledActions(uint256 anchorId)`: View function to get the list of scheduled actions for an anchor.
24. `isScheduledActionExecuted(uint256 anchorId, uint256 actionIndex)`: View function to check if a specific scheduled action was executed.
25. `getAnchorCount()`: View function for the total number of created anchors.
26. `getContractETHBalance()`: View function for the contract's total ETH balance.
27. `getContractERC20Balance(address tokenAddress)`: View function for the contract's total balance of a specific ERC20 token.
28. `getAssociatedLockedAssets(uint256 anchorId)`: View function to list all token addresses and total ETH locked against an anchor.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @title ChronoSphere
/// @dev A smart contract for managing temporal assets and scheduled actions tied to various complex trigger conditions.
/// Users can lock funds (ETH or ERC20) and define actions (transfers, contract calls) that can only be executed
/// when specific "temporal anchors" are triggered. Anchors can be triggered by time, manual intervention,
/// dependencies on other anchors, or pseudo-probabilistic conditions derived from block data.
contract ChronoSphere is Ownable, Pausable {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    // --- State Variables ---
    Counters.Counter private _anchorIds;

    enum TriggerType {
        Time,       // Triggered at a specific timestamp
        Manual,     // Triggered manually by permissioned address
        Dependency, // Triggered when another specific anchor triggers
        Probabilistic // Triggered based on block data pseudo-randomness
    }

    struct TriggerCondition {
        TriggerType triggerType;
        uint256 triggerTimestamp; // For TriggerType.Time
        uint256 requiredAnchorId; // For TriggerType.Dependency
        uint256 probabilityBasis; // For TriggerType.Probabilistic (e.g., timestamp % basis == 0)
    }

    struct TemporalAnchor {
        uint256 id;
        address creator;
        TriggerCondition condition;
        bool isTriggered;
        uint256 createdAt;
        uint256 triggeredAt; // Timestamp when it was actually triggered
    }

    struct ScheduledAction {
        address target;
        uint256 value; // For ETH transfer or value in callData
        bytes callData; // Data for contract call, 0x for simple transfers
        address tokenAddress; // For ERC20 transfers, address(0) for ETH/contract calls
        bool executed;
    }

    // Mapping from anchor ID to TemporalAnchor details
    mapping(uint256 => TemporalAnchor) public anchors;

    // Mapping from user address to anchor ID to token address to locked amount
    mapping(address => mapping(uint256 => mapping(address => uint256))) private _lockedBalances;

    // Mapping from anchor ID to list of scheduled actions
    mapping(uint256 => ScheduledAction[]) private _scheduledActions;

    // Mapping from anchor ID to a list of token addresses locked against it (for easier querying)
    mapping(uint256 => address[]) private _anchorLockedTokens;
    // Helper to track if a token address has already been added to the list for an anchor
    mapping(uint256 => mapping(address => bool)) private _anchorTokenAdded;


    // --- Events ---
    event AnchorCreated(uint256 indexed anchorId, address indexed creator, TriggerType triggerType);
    event AnchorTriggered(uint256 indexed anchorId, uint256 triggeredAt);
    event AssetsLocked(uint256 indexed anchorId, address indexed user, address indexed tokenAddress, uint256 amount);
    event ActionScheduled(uint256 indexed anchorId, uint256 actionIndex, address target, uint256 value, address tokenAddress);
    event AssetsClaimed(uint256 indexed anchorId, address indexed user, address indexed tokenAddress, uint256 amount);
    event ActionExecuted(uint256 indexed anchorId, uint256 indexed actionIndex);
    event ManualAnchorTriggered(uint256 indexed anchorId, address indexed triggerer);

    // --- Modifiers ---
    modifier whenAnchorExists(uint256 anchorId) {
        require(anchorId > 0 && anchorId <= _anchorIds.current(), "ChronoSphere: Invalid anchor ID");
        _;
    }

    modifier whenAnchorNotTriggered(uint256 anchorId) {
         require(!anchors[anchorId].isTriggered, "ChronoSphere: Anchor already triggered");
         _;
    }

    modifier whenAnchorIsTriggered(uint256 anchorId) {
         require(anchors[anchorId].isTriggered, "ChronoSphere: Anchor not triggered");
         _;
    }

    // --- Constructor ---
    constructor(address initialOwner) Ownable(initialOwner) Pausable(initialOwner) {}

    // --- Admin/Ownership Functions ---
    // Inherits transferOwnership, pause, unpause from Ownable and Pausable

    // --- Anchor Management Functions (5-8) ---

    /// @dev Creates a time-based temporal anchor.
    /// @param triggerTimestamp The timestamp at which the anchor should be triggered.
    /// @return The ID of the newly created anchor.
    function createTimeAnchor(uint256 triggerTimestamp) external whenNotPaused returns (uint256) {
        require(triggerTimestamp > block.timestamp, "ChronoSphere: Trigger timestamp must be in the future");
        _anchorIds.increment();
        uint256 newId = _anchorIds.current();
        anchors[newId] = TemporalAnchor({
            id: newId,
            creator: msg.sender,
            condition: TriggerCondition({
                triggerType: TriggerType.Time,
                triggerTimestamp: triggerTimestamp,
                requiredAnchorId: 0, // N/A
                probabilityBasis: 0 // N/A
            }),
            isTriggered: false,
            createdAt: block.timestamp,
            triggeredAt: 0 // Not triggered yet
        });
        emit AnchorCreated(newId, msg.sender, TriggerType.Time);
        return newId;
    }

    /// @dev Creates a manual temporal anchor that can only be triggered by the owner.
    /// @return The ID of the newly created anchor.
    function createManualAnchor() external whenNotPaused returns (uint256) {
        _anchorIds.increment();
        uint256 newId = _anchorIds.current();
         anchors[newId] = TemporalAnchor({
            id: newId,
            creator: msg.sender,
            condition: TriggerCondition({
                triggerType: TriggerType.Manual,
                triggerTimestamp: 0, // N/A
                requiredAnchorId: 0, // N/A
                probabilityBasis: 0 // N/A
            }),
            isTriggered: false,
            createdAt: block.timestamp,
            triggeredAt: 0 // Not triggered yet
        });
        emit AnchorCreated(newId, msg.sender, TriggerType.Manual);
        return newId;
    }

    /// @dev Creates a temporal anchor that triggers when a specific prerequisite anchor is triggered.
    /// @param requiredAnchorId The ID of the anchor that must be triggered first.
    /// @return The ID of the newly created anchor.
    function createDependencyAnchor(uint256 requiredAnchorId) external whenNotPaused whenAnchorExists(requiredAnchorId) returns (uint256) {
        require(requiredAnchorId != 0, "ChronoSphere: Required anchor ID must be non-zero");
        // Avoid circular dependencies? This is hard to check on-chain efficiently.
        // For simplicity, we don't enforce non-circularity here, which is a potential griefing vector.
        // A more robust implementation might use graph traversal, but it's gas intensive.

        _anchorIds.increment();
        uint256 newId = _anchorIds.current();
         anchors[newId] = TemporalAnchor({
            id: newId,
            creator: msg.sender,
            condition: TriggerCondition({
                triggerType: TriggerType.Dependency,
                triggerTimestamp: 0, // N/A
                requiredAnchorId: requiredAnchorId,
                probabilityBasis: 0 // N/A
            }),
            isTriggered: false,
            createdAt: block.timestamp,
            triggeredAt: 0 // Not triggered yet
        });
        emit AnchorCreated(newId, msg.sender, TriggerType.Dependency);
        return newId;
    }

     /// @dev Creates a temporal anchor that triggers based on a pseudo-random check using block data.
     /// Note: Block data pseudo-randomness can be influenced by miners to a limited extent.
     /// @param probabilityBasis A number. The anchor triggers if (block.timestamp + block.difficulty) % probabilityBasis == 0.
     ///                         Use 1 for always true, higher numbers for lower probability. Must be > 0.
     /// @return The ID of the newly created anchor.
    function createProbabilisticAnchor(uint256 probabilityBasis) external whenNotPaused returns (uint256) {
        require(probabilityBasis > 0, "ChronoSphere: Probability basis must be greater than 0");
         _anchorIds.increment();
        uint256 newId = _anchorIds.current();
         anchors[newId] = TemporalAnchor({
            id: newId,
            creator: msg.sender,
            condition: TriggerCondition({
                triggerType: TriggerType.Probabilistic,
                triggerTimestamp: 0, // N/A
                requiredAnchorId: 0, // N/A
                probabilityBasis: probabilityBasis
            }),
            isTriggered: false,
            createdAt: block.timestamp,
            triggeredAt: 0 // Not triggered yet
        });
        emit AnchorCreated(newId, msg.sender, TriggerType.Probabilistic);
        return newId;
    }

    // --- Asset Deposit/Lock Functions (3-4) ---

    /// @dev Deposits Ether to be locked against a specific anchor.
    /// @param anchorId The ID of the anchor to lock assets against.
    function depositEtherForAnchor(uint256 anchorId) external payable whenNotPaused whenAnchorExists(anchorId) whenAnchorNotTriggered(anchorId) {
        require(msg.value > 0, "ChronoSphere: Cannot deposit 0 Ether");
        _lockedBalances[msg.sender][anchorId][address(0)] += msg.value;
        // Add ETH (address(0)) to the list of associated tokens if not already there
        if (!_anchorTokenAdded[anchorId][address(0)]) {
            _anchorLockedTokens[anchorId].push(address(0));
            _anchorTokenAdded[anchorId][address(0)] = true;
        }
        emit AssetsLocked(anchorId, msg.sender, address(0), msg.value);
    }

    /// @dev Deposits ERC20 tokens to be locked against a specific anchor.
    /// Requires prior approval of the token amount to this contract.
    /// @param anchorId The ID of the anchor to lock assets against.
    /// @param tokenAddress The address of the ERC20 token.
    /// @param amount The amount of tokens to deposit.
    function depositERC20ForAnchor(uint256 anchorId, address tokenAddress, uint256 amount) external whenNotPaused whenAnchorExists(anchorId) whenAnchorNotTriggered(anchorId) {
        require(tokenAddress != address(0), "ChronoSphere: Invalid token address");
        require(amount > 0, "ChronoSphere: Cannot deposit 0 tokens");
        IERC20 token = IERC20(tokenAddress);
        token.safeTransferFrom(msg.sender, address(this), amount);
        _lockedBalances[msg.sender][anchorId][tokenAddress] += amount;

        // Add token address to the list of associated tokens if not already there
         if (!_anchorTokenAdded[anchorId][tokenAddress]) {
            _anchorLockedTokens[anchorId].push(tokenAddress);
            _anchorTokenAdded[anchorId][tokenAddress] = true;
        }
        emit AssetsLocked(anchorId, msg.sender, tokenAddress, amount);
    }

    // --- Action Scheduling Functions (3-4) ---

    /// @dev Schedules an Ether transfer action to be executed when the anchor triggers.
    /// @param anchorId The ID of the anchor this action is tied to.
    /// @param recipient The address to send Ether to.
    /// @param amount The amount of Ether to send.
    function scheduleEtherTransfer(uint256 anchorId, address recipient, uint256 amount) external whenNotPaused whenAnchorExists(anchorId) whenAnchorNotTriggered(anchorId) {
        require(recipient != address(0), "ChronoSphere: Invalid recipient address");
        // Note: This function only schedules the action. The Ether must be available in the contract
        // either from deposits or other sources when the action is executed.
        _scheduledActions[anchorId].push(ScheduledAction({
            target: recipient,
            value: amount,
            callData: bytes(""), // Indicate simple ETH transfer
            tokenAddress: address(0), // Indicate ETH transfer
            executed: false
        }));
        emit ActionScheduled(anchorId, _scheduledActions[anchorId].length - 1, recipient, amount, address(0));
    }

    /// @dev Schedules an ERC20 transfer action to be executed when the anchor triggers.
    /// @param anchorId The ID of the anchor this action is tied to.
    /// @param tokenAddress The address of the ERC20 token.
    /// @param recipient The address to send tokens to.
    /// @param amount The amount of tokens to send.
    function scheduleERC20Transfer(uint255 anchorId, address tokenAddress, address recipient, uint255 amount) external whenNotPaused whenAnchorExists(anchorId) whenAnchorNotTriggered(anchorId) {
        require(tokenAddress != address(0), "ChronoSphere: Invalid token address");
        require(recipient != address(0), "ChronoSphere: Invalid recipient address");
         // Note: This function only schedules the action. The tokens must be available in the contract
        // either from deposits or other sources when the action is executed.
        _scheduledActions[anchorId].push(ScheduledAction({
            target: recipient,
            value: amount, // For ERC20, value is the amount
            callData: bytes(""), // Indicate simple ERC20 transfer
            tokenAddress: tokenAddress,
            executed: false
        }));
        emit ActionScheduled(anchorId, _scheduledActions[anchorId].length - 1, recipient, amount, tokenAddress);
    }

    /// @dev Schedules a generic contract call action to be executed when the anchor triggers.
    /// @param anchorId The ID of the anchor this action is tied to.
    /// @param target The address of the contract to call.
    /// @param value The amount of Ether (if any) to send with the call.
    /// @param callData The data payload for the contract call.
    function scheduleContractCall(uint256 anchorId, address target, uint256 value, bytes memory callData) external whenNotPaused whenAnchorExists(anchorId) whenAnchorNotTriggered(anchorId) {
         require(target != address(0), "ChronoSphere: Invalid target address");
        _scheduledActions[anchorId].push(ScheduledAction({
            target: target,
            value: value,
            callData: callData,
            tokenAddress: address(0), // Not applicable for generic call
            executed: false
        }));
        emit ActionScheduled(anchorId, _scheduledActions[anchorId].length - 1, target, value, address(0));
    }

     // --- Triggering Functions (2-3) ---

    /// @dev Checks if an anchor's trigger conditions are met and triggers it. Callable by anyone.
    /// This incentivizes checking and triggering potentially complex anchors.
    /// @param anchorId The ID of the anchor to check and trigger.
    function checkAndTriggerAnchor(uint256 anchorId) external whenNotPaused whenAnchorExists(anchorId) whenAnchorNotTriggered(anchorId) {
        TemporalAnchor storage anchor = anchors[anchorId];
        bool triggered = false;

        if (anchor.condition.triggerType == TriggerType.Time) {
            if (block.timestamp >= anchor.condition.triggerTimestamp) {
                triggered = true;
            }
        } else if (anchor.condition.triggerType == TriggerType.Dependency) {
            // Check if the required anchor exists and is triggered
            uint256 requiredId = anchor.condition.requiredAnchorId;
            if (requiredId > 0 && requiredId <= _anchorIds.current() && anchors[requiredId].isTriggered) {
                 triggered = true;
            }
             // Note: This does *not* prevent circular dependencies from potentially locking funds.
        } else if (anchor.condition.triggerType == TriggerType.Probabilistic) {
            // Pseudo-random check based on block data.
            // Using difficulty adds a tiny bit more variability than timestamp alone, but still deterministic.
            // Miners could potentially influence this slightly.
            uint256 entropy = block.timestamp + block.difficulty;
            uint256 basis = anchor.condition.probabilityBasis;
            if (basis > 0 && entropy % basis == 0) {
                triggered = true;
            }
        }
        // Manual triggers are only done via triggerManualAnchor

        if (triggered) {
            anchor.isTriggered = true;
            anchor.triggeredAt = block.timestamp;
            emit AnchorTriggered(anchorId, block.timestamp);
        } else {
            // If not triggered, perhaps add a more specific error or just let it revert implicitly?
            // Let's revert to indicate the check failed.
             if (anchor.condition.triggerType == TriggerType.Time && block.timestamp < anchor.condition.triggerTimestamp) {
                revert("ChronoSphere: Time condition not met");
            } else if (anchor.condition.triggerType == TriggerType.Dependency) {
                 uint256 requiredId = anchor.condition.requiredAnchorId;
                 require(requiredId > 0 && requiredId <= _anchorIds.current(), "ChronoSphere: Dependency anchor invalid");
                 require(anchors[requiredId].isTriggered, "ChronoSphere: Dependency anchor not triggered");
            } else if (anchor.condition.triggerType == TriggerType.Probabilistic) {
                 uint224 entropy = uint224(block.timestamp) + uint224(block.difficulty); // Cast to prevent overflow if using larger types later
                 uint256 basis = anchor.condition.probabilityBasis;
                 require(basis > 0, "ChronoSphere: Invalid probability basis");
                 require(entropy % basis == 0, "ChronoSphere: Probabilistic condition not met");
            } else {
                 revert("ChronoSphere: Anchor condition not met"); // Should not happen for non-manual types
            }
        }
    }

    /// @dev Triggers a manual anchor. Only callable by the owner.
    /// @param anchorId The ID of the manual anchor to trigger.
    function triggerManualAnchor(uint256 anchorId) external onlyOwner whenNotPaused whenAnchorExists(anchorId) whenAnchorNotTriggered(anchorId) {
        TemporalAnchor storage anchor = anchors[anchorId];
        require(anchor.condition.triggerType == TriggerType.Manual, "ChronoSphere: Anchor is not a manual type");

        anchor.isTriggered = true;
        anchor.triggeredAt = block.timestamp;
        emit ManualAnchorTriggered(anchorId, msg.sender);
        emit AnchorTriggered(anchorId, block.timestamp);
    }

    // --- Execution/Claiming Functions (3-4) ---

    /// @dev Allows a user to claim their locked Ether for a triggered anchor.
    /// @param anchorId The ID of the triggered anchor.
    function claimUnlockedEther(uint256 anchorId) external whenNotPaused whenAnchorExists(anchorId) whenAnchorIsTriggered(anchorId) {
        uint256 amount = _lockedBalances[msg.sender][anchorId][address(0)];
        require(amount > 0, "ChronoSphere: No unlocked Ether to claim for this anchor");

        _lockedBalances[msg.sender][anchorId][address(0)] = 0; // Clear balance before transfer

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "ChronoSphere: ETH transfer failed");

        emit AssetsClaimed(anchorId, msg.sender, address(0), amount);
    }

     /// @dev Allows a user to claim their locked ERC20 tokens for a triggered anchor.
     /// @param anchorId The ID of the triggered anchor.
     /// @param tokenAddress The address of the ERC20 token to claim.
    function claimUnlockedERC20(uint256 anchorId, address tokenAddress) external whenNotPaused whenAnchorExists(anchorId) whenAnchorIsTriggered(anchorId) {
        require(tokenAddress != address(0), "ChronoSphere: Invalid token address");
        uint256 amount = _lockedBalances[msg.sender][anchorId][tokenAddress];
        require(amount > 0, "ChronoSphere: No unlocked tokens to claim for this anchor");

        _lockedBalances[msg.sender][anchorId][tokenAddress] = 0; // Clear balance before transfer

        IERC20(tokenAddress).safeTransfer(msg.sender, amount);

        emit AssetsClaimed(anchorId, msg.sender, tokenAddress, amount);
    }

    /// @dev Executes all pending scheduled actions for a triggered anchor. Callable by anyone.
    /// This function can be called multiple times, but each action is executed only once.
    /// @param anchorId The ID of the triggered anchor.
    function executeScheduledActions(uint256 anchorId) external whenNotPaused whenAnchorExists(anchorId) whenAnchorIsTriggered(anchorId) {
        ScheduledAction[] storage actions = _scheduledActions[anchorId];

        for (uint i = 0; i < actions.length; i++) {
            if (!actions[i].executed) {
                bool success = false;
                // Handle ETH transfer actions
                if (actions[i].tokenAddress == address(0) && actions[i].callData.length == 0) {
                     (success, ) = actions[i].target.call{value: actions[i].value}("");
                 }
                 // Handle ERC20 transfer actions
                 else if (actions[i].tokenAddress != address(0) && actions[i].callData.length == 0) {
                     // Use SafeERC20 to handle potential transfer issues
                     IERC20 token = IERC20(actions[i].tokenAddress);
                     try token.safeTransfer(actions[i].target, actions[i].value) {
                         success = true;
                     } catch {
                         success = false; // Transfer failed
                     }
                 }
                 // Handle generic contract call actions
                 else {
                      (success, ) = actions[i].target.call{value: actions[i].value}(actions[i].callData);
                 }

                 // Mark as executed regardless of success to prevent re-attempting failing actions
                 actions[i].executed = true;

                 if (success) {
                    emit ActionExecuted(anchorId, i);
                 }
                 // Note: We could add an event for failed execution if needed for monitoring.
            }
        }
    }

    // --- Query Functions (5+ functions) ---

    /// @dev Gets the details of a specific temporal anchor.
    /// @param anchorId The ID of the anchor.
    /// @return The TemporalAnchor struct.
    function getAnchorDetails(uint256 anchorId) external view whenAnchorExists(anchorId) returns (TemporalAnchor memory) {
        return anchors[anchorId];
    }

    /// @dev Checks if a specific temporal anchor has been triggered.
    /// @param anchorId The ID of the anchor.
    /// @return True if triggered, false otherwise.
    function getAnchorStatus(uint256 anchorId) external view whenAnchorExists(anchorId) returns (bool) {
        return anchors[anchorId].isTriggered;
    }

    /// @dev Gets the amount of Ether locked by a user for a specific anchor.
    /// @param user The address of the user.
    /// @param anchorId The ID of the anchor.
    /// @return The amount of Ether locked.
    function getUserLockedBalanceEther(address user, uint256 anchorId) external view whenAnchorExists(anchorId) returns (uint256) {
        return _lockedBalances[user][anchorId][address(0)];
    }

     /// @dev Gets the amount of ERC20 tokens locked by a user for a specific anchor and token.
     /// @param user The address of the user.
     /// @param anchorId The ID of the anchor.
     /// @param tokenAddress The address of the ERC20 token.
     /// @return The amount of tokens locked.
    function getUserLockedBalanceERC20(address user, uint256 anchorId, address tokenAddress) external view whenAnchorExists(anchorId) returns (uint256) {
         require(tokenAddress != address(0), "ChronoSphere: Invalid token address");
        return _lockedBalances[user][anchorId][tokenAddress];
    }

     /// @dev Gets the list of scheduled actions for a specific anchor.
     /// @param anchorId The ID of the anchor.
     /// @return An array of ScheduledAction structs.
    function getAnchorScheduledActions(uint256 anchorId) external view whenAnchorExists(anchorId) returns (ScheduledAction[] memory) {
        return _scheduledActions[anchorId];
    }

    /// @dev Checks if a specific scheduled action for an anchor has been executed.
    /// @param anchorId The ID of the anchor.
    /// @param actionIndex The index of the action in the scheduled list.
    /// @return True if executed, false otherwise.
    function isScheduledActionExecuted(uint256 anchorId, uint256 actionIndex) external view whenAnchorExists(anchorId) returns (bool) {
        require(actionIndex < _scheduledActions[anchorId].length, "ChronoSphere: Invalid action index");
        return _scheduledActions[anchorId][actionIndex].executed;
    }

    /// @dev Gets the total number of temporal anchors created.
    /// @return The total count of anchors.
    function getAnchorCount() external view returns (uint256) {
        return _anchorIds.current();
    }

    /// @dev Gets the contract's current ETH balance.
    /// @return The ETH balance of the contract.
    function getContractETHBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @dev Gets the contract's current balance of a specific ERC20 token.
    /// @param tokenAddress The address of the ERC20 token.
    /// @return The token balance of the contract.
    function getContractERC20Balance(address tokenAddress) external view returns (uint256) {
        require(tokenAddress != address(0), "ChronoSphere: Invalid token address");
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    /// @dev Gets a list of all token addresses (including address(0) for ETH) that have assets locked against an anchor.
    /// @param anchorId The ID of the anchor.
    /// @return An array of token addresses.
    function getAssociatedLockedAssets(uint256 anchorId) external view whenAnchorExists(anchorId) returns (address[] memory) {
        return _anchorLockedTokens[anchorId];
    }

    // Fallback function to receive Ether, primarily for scheduled ETH transfers
    receive() external payable {}
}
```

---

**Explanation of Concepts and Features:**

1.  **Temporal Anchors:** Instead of just a single timelock or event, the contract manages distinct `TemporalAnchor` entities, each with its own ID and trigger condition. This allows for multiple independent or dependent timed/conditional releases/actions within a single contract instance.
2.  **Diverse Trigger Types:**
    *   `Time`: Standard timelock.
    *   `Manual`: Controlled triggering by a specific address (owner in this case). Useful for events that happen off-chain but need on-chain effect.
    *   `Dependency`: A creative concept where one anchor's trigger depends on another having been triggered. This allows for sequences or prerequisite conditions for asset/action release.
    *   `Probabilistic`: Uses block data (`block.timestamp` and `block.difficulty`) to create a condition that is met based on a pseudo-random outcome derived deterministically from block information. While not truly random, it's unpredictable to a degree before the block is mined and adds an interesting non-standard trigger type.
3.  **Separation of Concerns (Triggering vs. Execution):** The `checkAndTriggerAnchor` function is callable by *anyone*. This is a common pattern to incentivize users or bots to pay the gas cost for checking conditions and triggering events, rather than the contract needing to actively monitor (which is impossible on-chain). Once an anchor is triggered, separate functions (`claimUnlockedEther`, `claimUnlockedERC20`, `executeScheduledActions`) are used to access the effects. This allows users to claim their specific assets and others (or the original scheduler) to trigger the batch execution of scheduled actions.
4.  **Flexible Asset Locking:** Supports both native Ether and any ERC20 token via `SafeERC20`. Locked assets are tracked per user, per anchor, per token.
5.  **Scheduled Actions:** Allows defining arbitrary actions (transfers, contract calls) linked to anchors. This makes the contract versatile – it's not just for releasing locked funds but can be used to trigger other on-chain events or interact with other protocols based on the `ChronoSphere`'s temporal logic.
6.  **Non-Duplication:** While using standard libraries like OpenZeppelin (SafeERC20, Ownable, Pausable), the core logic of combining diverse, named temporal anchors with linked asset locks and scheduled actions based on dependency or probabilistic triggers is not a standard, widely available open-source contract pattern. Most open-source solutions focus on single-condition timelocks, vesting, or simple event triggers.

This contract provides a framework for building more complex temporal logic into dApps, enabling use cases beyond simple token releases, such as scheduled contract interactions, multi-stage releases dependent on prior events, or even game mechanics influenced by on-chain "time" or pseudo-random triggers.