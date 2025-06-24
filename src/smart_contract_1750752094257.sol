Okay, let's design a creative, advanced, and potentially "trendy" (in a speculative sense) smart contract concept that avoids duplicating standard open-source patterns. We'll build a "Quantum Vault" – not implementing actual quantum computing (impossible on-chain) but using concepts like superposition, entanglement, and conditional state transitions as inspiration for complex asset management logic.

It will hold various assets (ETH, ERC20, ERC721) in structured "positions," each with unique properties, states, and access controls.

Here is the outline and function summary, followed by the Solidity code.

---

## QuantumVault Smart Contract

**Concept:** A multi-asset vault managing positions with complex, "quantum-inspired" states and interactions. Assets are stored in structured "positions" that can be in states like 'Available', 'Locked', 'Superposition', or 'Entangled'.

**Key Features:**
*   **Position-Based Management:** Assets are tracked via unique position IDs, not just user balances.
*   **Complex States:** Positions can enter states like 'Locked' (with conditions), 'Superposition' (probabilistic/oracle-determined state), and 'Entangled' (linked fate).
*   **Dynamic Access Control:** Fine-grained permissions and delegation per position or asset type.
*   **Scheduled Operations:** Plan future withdrawals or actions.
*   **Oracle Interaction:** Simulate external influence ('Quantum State') affecting position outcomes.
*   **Basic Governance:** Simple proposal/voting for parameter changes.

**Outline:**

1.  **Pragma & Imports:** Solidity version and necessary interfaces (IERC20, IERC721, IOracle).
2.  **Interfaces:** Define necessary external interfaces.
3.  **Errors:** Custom error types.
4.  **State Variables:** Store owner, pause status, position data, state data, governance data.
5.  **Structs:** Define data structures for Positions, Permissions, Scheduled actions, Entangled Pairs, Superposition states, and Governance Proposals.
6.  **Enums:** Define states and asset types.
7.  **Events:** Announce key actions.
8.  **Modifiers:** Access control and state checks.
9.  **Constructor:** Initialize the contract.
10. **Core Vault Operations:** Deposit and withdraw various asset types.
11. **Position Management:** Internal transfers, consolidation, locking, releasing, scheduling, canceling.
12. **"Quantum" Mechanics:** Entangling/Disentangling, Superposition creation/resolution, Oracle update simulation.
13. **Access & Permissions:** Granting, revoking permissions, delegation.
14. **Rewards:** Claiming accrued rewards from special positions.
15. **Governance:** Proposing, voting on, and executing changes.
16. **System Controls:** Pausing/Unpausing.
17. **Helper/View Functions:** Retrieve state and position data.

**Function Summary (25 Functions):**

1.  `constructor(address initialOracle)`: Initializes the contract with an owner and oracle address.
2.  `pauseContract()`: Owner can pause contract interactions (except unpausing).
3.  `unpauseContract()`: Owner can unpause the contract.
4.  `depositETH()`: Deposits ETH into the vault, creating a new 'Available' position.
5.  `depositERC20(IERC20 token, uint256 amount)`: Deposits a specified amount of an ERC20 token, creating a new 'Available' position.
6.  `depositERC721(IERC721 token, uint256 tokenId)`: Deposits a specified ERC721 token, creating a new 'Available' position.
7.  `withdrawPosition(uint256 positionId)`: Withdraws an entire position if it is 'Available' and the caller has permission.
8.  `internalTransferPosition(uint256 positionId, address recipient)`: Transfers ownership of a position *within* the vault to another address.
9.  `consolidateUserERC20Positions(IERC20 token, uint256[] positionIds)`: Combines multiple 'Available' ERC20 positions of the *same* token owned by the caller into a single new position.
10. `lockPositionConditional(uint256 positionId, uint64 unlockTime, string condition)`: Locks a position until a specified time *and* an off-chain condition (represented by a string description) is met and verified by a delegate/owner.
11. `releaseLockedPosition(uint256 positionId)`: Releases a locked position if the unlock time has passed *and* the condition is marked as met (requires separate mechanism or owner action to verify/mark condition).
12. `scheduleFutureWithdrawal(uint256 positionId, uint64 withdrawalTime)`: Schedules a position for automatic withdrawal at a future time. The position state changes.
13. `cancelScheduledWithdrawal(uint256 positionId)`: Cancels a previously scheduled withdrawal, returning the position to an 'Available' state.
14. `entangleNFTs(uint256 positionId1, uint256 positionId2)`: Links two ERC721 positions (must be owned by the caller). Adds constraints or effects to withdrawal/transfer (logic added within `_canWithdrawPosition`).
15. `disentangleNFTs(uint256 entangledPairId)`: Breaks the link between two entangled NFT positions.
16. `createSuperpositionPosition(uint256 positionId, uint64 duration)`: Puts an 'Available' position into a 'Superposition' state for a duration. This state accrues special rewards based on the 'Quantum State'.
17. `resolveSuperposition(uint256 positionId)`: Resolves a Superposition state. If duration passed, it becomes 'Available'. If resolved early, potential penalties or partial rewards (logic simplified for example).
18. `updateQuantumState(uint256 newState)`: Callable by the oracle address to update the simulated 'Quantum State' variable, influencing rewards or other logic.
19. `claimRewards(uint256[] positionIds)`: Allows users to claim rewards accrued by their positions (e.g., from Superposition).
20. `grantSpecificPermission(uint256 positionId, address delegate, uint8 permissionType)`: Grants a delegate a specific permission (e.g., withdraw, transfer) for a single position.
21. `revokeSpecificPermission(uint256 positionId, address delegate, uint8 permissionType)`: Revokes a previously granted permission.
22. `delegatePositionManagement(uint256 positionId, address delegate)`: Delegates full management (excluding withdrawal unless specifically permitted) of a position to another address.
23. `proposeParameterChange(address target, uint256 value, bytes signature, bytes calldata data, string description)`: Allows owner or potentially specific role to propose a contract configuration change or action via a low-level call.
24. `voteOnProposal(uint256 proposalId, bool support)`: Vote for or against a proposal (simple 1 address = 1 vote).
25. `executeProposal(uint256 proposalId)`: Executes a proposal that has passed the voting threshold.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Minimal Interfaces - avoiding direct inheritance from OpenZeppelin to meet constraint
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool); // Added for completeness, not strictly used in deposit logic
}

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function setApprovalForAll(address operator, bool approved) external; // Added for completeness
    function isApprovedForAll(address owner, address operator) external view returns (bool); // Added for completeness
}

interface IOracle {
    // Represents an external oracle contract providing the "Quantum State"
    // In a real scenario, this would likely return data via a specific function
    // For this example, we'll just define a function the Vault *calls*
    // A real oracle interaction is complex (Chainlink, etc.) and involves callbacks.
    // Here, we simplify: the Vault calls the oracle to get *a* state update.
    // A more realistic model would have the oracle CALL the Vault with data.
    // Let's make it the Oracle *updates* the Vault directly for simplicity here.
    // So this interface might not be strictly needed if the Oracle calls the Vault.
    // Let's remove the interface and assume the Oracle address is just allowed to call `updateQuantumState`.
    // Or, let's make the oracle call `updateQuantumState` on *this* contract.
    // We'll stick with the model where a trusted `oracleAddress` calls a function.
    // No interface needed for this specific update pattern.
}


/// @custom:error UnauthorizedCaller Error thrown when a function is called by an unauthorized address.
error UnauthorizedCaller(address caller);

/// @custom:error ContractPaused Error thrown when a function is called while the contract is paused.
error ContractPaused();

/// @custom:error ContractNotPaused Error thrown when a function is called while the contract is not paused.
error ContractNotPaused();

/// @custom:error InvalidPosition Error thrown when a position ID does not exist.
error InvalidPosition(uint256 positionId);

/// @custom:error InvalidPositionState Error thrown when a position is in an unexpected state.
error InvalidPositionState(uint256 positionId, uint8 currentState, uint8 expectedState);

/// @custom:error PermissionDenied Error thrown when an action requires specific permission not held by the caller.
error PermissionDenied(address caller, uint256 positionId, uint8 requiredPermission);

/// @custom:error ConditionNotMet Error thrown when a locked position's condition hasn't been met.
error ConditionNotMet(uint256 positionId);

/// @custom:error UnlockTimeNotPassed Error thrown when a locked position's unlock time hasn't passed.
error UnlockTimeNotPassed(uint256 positionId);

/// @custom:error PositionsNotOwnedByUser Error thrown when attempting to consolidate positions not owned by the caller.
error PositionsNotOwnedByUser();

/// @custom:error IncompatiblePositions Error thrown when attempting to consolidate or entangle incompatible positions.
error IncompatiblePositions(uint256 positionId1, uint256 positionId2);

/// @custom:error EntangledPairNotFound Error thrown when an entangled pair ID does not exist.
error EntangledPairNotFound(uint256 pairId);

/// @custom:error SuperpositionDurationNotPassed Error thrown when attempting to resolve superposition before duration ends (if early resolution requires this).
error SuperpositionDurationNotPassed(uint256 positionId);

/// @custom:error NoRewardsClaimable Error thrown when claiming rewards but none are available.
error NoRewardsClaimable(address caller);

/// @custom:error ProposalNotFound Error thrown when a proposal ID does not exist.
error ProposalNotFound(uint256 proposalId);

/// @custom:error ProposalAlreadyVoted Error thrown when attempting to vote on a proposal multiple times.
error ProposalAlreadyVoted(uint256 proposalId, address voter);

/// @custom:error ProposalNotExecutable Error thrown when attempting to execute a proposal that hasn't passed or is already executed.
error ProposalNotExecutable(uint256 proposalId);


contract QuantumVault {

    // --- Enums ---
    enum AssetType { ETH, ERC20, ERC721 }
    enum PositionState { Available, Locked, Scheduled, Superposition, Entangled }
    enum PermissionType { Withdraw, TransferInternal, DelegateManagement, EntangleDisentangle, SuperpositionControl } // Define granular permissions

    // --- State Variables ---
    address private immutable i_owner;
    bool private s_paused;
    uint256 private s_nextPositionId = 1;
    uint256 private s_nextEntangledPairId = 1;
    uint256 private s_nextProposalId = 1;

    // Core position storage: positionId => Position struct
    mapping(uint256 => Position) private s_positions;

    // User's list of position IDs (index for retrieval)
    mapping(address => uint256[]) private s_userPositions;

    // Position state specific data (indexed by position ID)
    mapping(uint256 => LockedPosition) private s_lockedPositions;
    mapping(uint256 => ScheduledWithdrawal) private s_scheduledWithdrawals;
    mapping(uint256 => SuperpositionState) private s_superpositionStates;

    // Entanglement data
    mapping(uint256 => EntangledPair) private s_entangledPairs; // pairId => EntangledPair
    mapping(uint256 => uint256) private s_positionToEntangledPairId; // positionId => pairId

    // Permission data: positionId => delegate => permissionType => bool
    mapping(uint256 => mapping(address => mapping(uint8 => bool))) private s_positionPermissions;

    // Delegation data: positionId => delegate address
    mapping(uint256 => address) private s_positionDelegates;

    // Simulated external "Quantum State" - influenced by oracle
    uint256 public s_quantumState = 0; // Start at a baseline

    // Reward tracking: user => amount (cumulative)
    mapping(address => uint256) private s_accruedRewards;
    // Mapping to track reward basis for superposition positions (posId => total time spent in state, or similar)
    mapping(uint256 => uint256) private s_superpositionRewardBasis;
    mapping(uint256 => uint64) private s_superpositionStartTime;


    // Governance data
    mapping(uint256 => Proposal) private s_proposals;
    mapping(uint256 => mapping(address => bool)) private s_proposalVotes; // proposalId => voter => hasVoted

    // Address allowed to update the quantum state (simulating oracle)
    address private s_oracleAddress;

    // --- Structs ---

    struct Position {
        AssetType assetType;
        address tokenAddress; // Address for ERC20 or ERC721 contract
        uint256 tokenId;      // Token ID for ERC721
        uint256 amount;       // Amount for ETH or ERC20
        address owner;
        PositionState state;
        uint256 createdTime;
        // Could add more metadata
    }

    struct LockedPosition {
        uint64 unlockTime;
        string conditionDescription; // Description of the off-chain condition
        bool conditionMet;           // Must be set externally (e.g., by owner/trusted role)
    }

    struct ScheduledWithdrawal {
        uint64 withdrawalTime;
        // Could add recipient if different from owner
    }

    struct SuperpositionState {
        uint64 endTime;
        // Represents parameters influencing reward calculation in this state
        // e.g., uint256 baseRewardRate; uint256 quantumFactor;
        // For simplicity, rewards based on time * s_quantumState
    }

    struct EntangledPair {
        uint256 positionId1;
        uint256 positionId2;
        // Rules for entanglement (e.g., must be withdrawn together, transferring one affects the other)
        // Logic implemented in relevant functions
    }

    struct Proposal {
        address target;       // Contract address to call (this contract)
        uint256 value;        // ETH to send with the call
        bytes signature;      // Function signature (e.g., "setQuantumState(uint256)")
        bytes calldata data;  // Encoded parameters for the function call
        string description;   // Human-readable description
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        // Could add voting deadline, minimum participation, etc.
    }


    // --- Events ---
    event PositionCreated(uint256 indexed positionId, address indexed owner, AssetType assetType, address tokenAddress, uint256 tokenIdOrAmount, PositionState initialState);
    event PositionStateChanged(uint256 indexed positionId, PositionState oldState, PositionState newState);
    event PositionWithdrawn(uint256 indexed positionId, address indexed recipient, AssetType assetType, address tokenAddress, uint256 tokenIdOrAmount);
    event PositionTransferredInternal(uint256 indexed positionId, address indexed from, address indexed to);
    event PositionsConsolidated(address indexed owner, IERC20 indexed token, uint256[] oldPositionIds, uint256 newPositionId, uint256 totalAmount);
    event PositionLocked(uint256 indexed positionId, uint64 unlockTime, string condition);
    event LockedConditionMet(uint256 indexed positionId); // Event when condition is marked met
    event PositionReleased(uint256 indexed positionId);
    event WithdrawalScheduled(uint256 indexed positionId, uint64 withdrawalTime);
    event ScheduledWithdrawalCancelled(uint256 indexed positionId);
    event NFTsEntangled(uint256 indexed pairId, uint256 indexed positionId1, uint256 indexed positionId2);
    event NFTsDisentangled(uint256 indexed pairId);
    event SuperpositionCreated(uint256 indexed positionId, uint64 endTime);
    event SuperpositionResolved(uint256 indexed positionId, PositionState finalState);
    event QuantumStateUpdated(uint256 oldState, uint256 newState);
    event RewardsClaimed(address indexed user, uint256 amount);
    event PermissionGranted(uint256 indexed positionId, address indexed delegate, uint8 indexed permissionType);
    event PermissionRevoked(uint256 indexed positionId, address indexed delegate, uint8 indexed permissionType);
    event PositionDelegated(uint256 indexed positionId, address indexed delegate);
    event ProposalCreated(uint256 indexed proposalId, string description, address indexed proposer);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event Paused(address account);
    event Unpaused(address account);

    // --- Modifiers ---

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert UnauthorizedCaller(msg.sender);
        }
        _;
    }

    modifier whenNotPaused() {
        if (s_paused) {
            revert ContractPaused();
        }
        _;
    }

    modifier whenPaused() {
        if (!s_paused) {
            revert ContractNotPaused();
        }
        _;
    }

    modifier positionExists(uint256 positionId) {
        if (s_positions[positionId].owner == address(0)) { // Check if owner is zero address to indicate existence
            revert InvalidPosition(positionId);
        }
        _;
    }

    modifier onlyPositionOwnerOrDelegate(uint256 positionId) {
        if (msg.sender != s_positions[positionId].owner && msg.sender != s_positionDelegates[positionId]) {
             revert UnauthorizedCaller(msg.sender); // Or a more specific error
        }
        _;
    }

    modifier onlyPositionOwnerOrDelegateOrPermitted(uint256 positionId, PermissionType permissionType) {
         bool isOwner = msg.sender == s_positions[positionId].owner;
         bool isDelegate = msg.sender == s_positionDelegates[positionId];
         bool hasPermission = s_positionPermissions[positionId][msg.sender][uint8(permissionType)];

         if (!isOwner && !isDelegate && !hasPermission) {
             revert PermissionDenied(msg.sender, positionId, uint8(permissionType));
         }
         _;
    }


    // --- Constructor ---
    constructor(address initialOracle) {
        i_owner = msg.sender;
        s_oracleAddress = initialOracle;
        s_paused = false;
    }

    // --- System Controls ---

    /// @notice Pauses the contract, preventing most interactions. Only owner can call.
    function pauseContract() external onlyOwner whenNotPaused {
        s_paused = true;
        emit Paused(msg.sender);
    }

    /// @notice Unpauses the contract, allowing interactions again. Only owner can call.
    function unpauseContract() external onlyOwner whenPaused {
        s_paused = false;
        emit Unpaused(msg.sender);
    }

    // --- Internal Position Management Helpers ---

    /// @dev Creates a new position and adds it to storage.
    function _createPosition(AssetType assetType, address tokenAddress, uint256 tokenId, uint256 amount, address owner, PositionState initialState) internal returns (uint256) {
        uint256 newPositionId = s_nextPositionId++;
        s_positions[newPositionId] = Position({
            assetType: assetType,
            tokenAddress: tokenAddress,
            tokenId: tokenId,
            amount: amount,
            owner: owner,
            state: initialState,
            createdTime: uint64(block.timestamp)
        });
        s_userPositions[owner].push(newPositionId);

        // Initialize state-specific storage if needed
        if (initialState == PositionState.Superposition) {
            s_superpositionRewardBasis[newPositionId] = 0; // Initialize reward basis
            s_superpositionStartTime[newPositionId] = uint64(block.timestamp);
        }

        emit PositionCreated(newPositionId, owner, assetType, tokenAddress, (assetType == AssetType.ERC721 ? tokenId : amount), initialState);
        return newPositionId;
    }

    /// @dev Updates the state of a position. Handles state-specific cleanup/initialization.
    function _updatePositionState(uint256 positionId, PositionState newState) internal {
        Position storage pos = s_positions[positionId];
        if (pos.state == newState) return;

        PositionState oldState = pos.state;

        // Clean up old state data
        if (oldState == PositionState.Locked) {
            delete s_lockedPositions[positionId];
        } else if (oldState == PositionState.Scheduled) {
            delete s_scheduledWithdrawals[positionId];
        } else if (oldState == PositionState.Superposition) {
             // Accrue final rewards upon leaving superposition state
            _updateSuperpositionRewardBasis(positionId);
            delete s_superpositionStartTime[positionId];
             // Don't delete s_superpositionRewardBasis here, it's needed for claiming
        } else if (oldState == PositionState.Entangled) {
             // Logic needed if disentangling is implicit on state change (it's explicit here)
        }

        pos.state = newState;

        // Initialize new state data if needed happens in the calling function

        emit PositionStateChanged(positionId, oldState, newState);
    }

     /// @dev Checks if a position can be withdrawn based on its state, time, conditions, and entanglement.
     function _canWithdrawPosition(uint256 positionId) internal view returns (bool) {
         Position storage pos = s_positions[positionId];
         if (pos.owner == address(0)) return false; // Position doesn't exist

         PositionState currentState = pos.state;

         if (currentState == PositionState.Available) {
             return true;
         } else if (currentState == PositionState.Locked) {
             LockedPosition storage lockedPos = s_lockedPositions[positionId];
             return lockedPos.conditionMet && block.timestamp >= lockedPos.unlockTime;
         } else if (currentState == PositionState.Scheduled) {
              // Scheduled positions can only be withdrawn by the scheduled withdrawal mechanism or cancelled
             return false;
         } else if (currentState == PositionState.Superposition) {
              // Superposition positions might only be withdrawable *after* resolution
             return false; // Assume resolution is required first
         } else if (currentState == PositionState.Entangled) {
             // Entangled positions might have complex withdrawal rules
             uint256 pairId = s_positionToEntangledPairId[positionId];
             if (pairId != 0) {
                 EntangledPair storage pair = s_entangledPairs[pairId];
                 // Example rule: Both must be released/available simultaneously?
                 // This is complex. For simplicity, require explicit disentanglement first.
                 return false; // Entangled positions cannot be withdrawn directly
             }
              // Should not happen if state is Entangled but no pairId
             return false;
         }

         return false; // Default: Unknown state cannot be withdrawn
     }


    /// @dev Transfers the actual asset out of the contract. Handles ETH, ERC20, ERC721.
    function _transferAssetOut(Position storage pos, address recipient) internal {
        if (pos.assetType == AssetType.ETH) {
            (bool success, ) = recipient.call{value: pos.amount}("");
            require(success, "ETH transfer failed");
        } else if (pos.assetType == AssetType.ERC20) {
            IERC20 token = IERC20(pos.tokenAddress);
            require(token.transferFrom(address(this), recipient, pos.amount), "ERC20 transfer failed");
        } else if (pos.assetType == AssetType.ERC721) {
             IERC721 token = IERC721(pos.tokenAddress);
             // Ensure contract has approval - requires `isApprovedForAll` check or relying on user approving this contract prior
             // For simplicity in this example, assume contract is approved or owner is calling.
             // A production contract needs robust approval handling.
            token.safeTransferFrom(address(this), recipient, pos.tokenId);
        }
    }

    /// @dev Removes a position struct and cleans up user's position list.
    function _deletePosition(uint256 positionId) internal {
        Position storage pos = s_positions[positionId];
        address owner = pos.owner;

        // Remove from user's list - simple linear search for example, optimize for production
        uint256[] storage userPosIds = s_userPositions[owner];
        for (uint i = 0; i < userPosIds.length; i++) {
            if (userPosIds[i] == positionId) {
                userPosIds[i] = userPosIds[userPosIds.length - 1];
                userPosIds.pop();
                break;
            }
        }

        // Clean up state-specific data if not already done by _updatePositionState
        delete s_lockedPositions[positionId];
        delete s_scheduledWithdrawals[positionId];
        delete s_superpositionStates[positionId];
        delete s_superpositionRewardBasis[positionId];
        delete s_superpositionStartTime[positionId];

        // Clean up entanglement mapping
        delete s_positionToEntangledPairId[positionId]; // EntangledPair struct is deleted by disentangle

        // Clean up permissions and delegations
        delete s_positionPermissions[positionId]; // Clears the mapping for this posId
        delete s_positionDelegates[positionId];

        // Delete the position struct itself
        delete s_positions[positionId];
    }

    /// @dev Updates the reward basis for a superposition position based on time spent in the state.
    function _updateSuperpositionRewardBasis(uint256 positionId) internal {
        SuperpositionState storage superPos = s_superpositionStates[positionId];
        uint64 startTime = s_superpositionStartTime[positionId];
        uint64 currentTime = uint64(block.timestamp);

        // Prevent negative time or updates before start
        if (currentTime <= startTime) return;

        // Calculate elapsed time since last update or start
        uint66 timeDelta = currentTime - startTime; // Use uint66 to avoid intermediate overflow if needed
        s_superpositionStartTime[positionId] = currentTime; // Update start time for next calculation

        // Accrue reward basis: time spent * quantumState (simplified)
        // RewardBasis represents "units" of reward, actual token amount calculated in claimRewards
        s_superpositionRewardBasis[positionId] += uint256(timeDelta) * s_quantumState;
    }


    // --- Core Vault Operations ---

    /// @notice Deposits ETH into the vault, creating a new available position.
    function depositETH() external payable whenNotPaused returns (uint256 positionId) {
        if (msg.value == 0) revert("ETH amount must be > 0");
        positionId = _createPosition(AssetType.ETH, address(0), 0, msg.value, msg.sender, PositionState.Available);
    }

    /// @notice Deposits ERC20 tokens into the vault, creating a new available position.
    /// @param token The address of the ERC20 token contract.
    /// @param amount The amount of tokens to deposit.
    /// @dev Requires caller to have approved this contract to spend the tokens via `IERC20(token).approve()`.
    function depositERC20(IERC20 token, uint256 amount) external whenNotPaused returns (uint256 positionId) {
        if (amount == 0) revert("ERC20 amount must be > 0");
        require(token.transferFrom(msg.sender, address(this), amount), "ERC20 transfer failed");
        positionId = _createPosition(AssetType.ERC20, address(token), 0, amount, msg.sender, PositionState.Available);
    }

    /// @notice Deposits an ERC721 token into the vault, creating a new available position.
    /// @param token The address of the ERC721 token contract.
    /// @param tokenId The ID of the token to deposit.
    /// @dev Requires caller to have approved this contract to transfer the token via `IERC721(token).approve()` or `setApprovalForAll()`.
    function depositERC721(IERC721 token, uint256 tokenId) external whenNotPaused returns (uint256 positionId) {
         // Ensure caller owns the token
         require(token.ownerOf(tokenId) == msg.sender, "Caller does not own token");
         // Transfer the token (requires prior approval or setApprovalForAll)
         token.safeTransferFrom(msg.sender, address(this), tokenId);
         positionId = _createPosition(AssetType.ERC721, address(token), tokenId, 0, msg.sender, PositionState.Available);
    }

    /// @notice Withdraws an entire position if its state allows and the caller has permission.
    /// @param positionId The ID of the position to withdraw.
    function withdrawPosition(uint256 positionId)
        external
        whenNotPaused
        positionExists(positionId)
    {
        Position storage pos = s_positions[positionId];
        address originalOwner = pos.owner; // Store before potential deletion

        // Check if the caller has permission to withdraw this specific position OR is the owner
        bool isOwner = msg.sender == pos.owner;
        bool hasPermission = s_positionPermissions[positionId][msg.sender][uint8(PermissionType.Withdraw)];

        if (!isOwner && !hasPermission) {
            revert PermissionDenied(msg.sender, positionId, uint8(PermissionType.Withdraw));
        }

        // Check if the position state allows withdrawal
        if (!_canWithdrawPosition(positionId)) {
            revert InvalidPositionState(positionId, uint8(pos.state), uint8(PositionState.Available)); // Or a more specific reason
        }

        // If it was in Superposition, update rewards before withdrawing
        if (pos.state == PositionState.Superposition) {
             _updateSuperpositionRewardBasis(positionId);
        }

        // Transfer the asset out
        _transferAssetOut(pos, originalOwner); // Withdraw to the original owner

        // Emit event before deleting position
        emit PositionWithdrawn(positionId, originalOwner, pos.assetType, pos.tokenAddress, (pos.assetType == AssetType.ERC721 ? pos.tokenId : pos.amount));

        // Delete the position and clean up
        _deletePosition(positionId);
    }


    // --- Position Management ---

    /// @notice Transfers ownership of a position within the vault to another address.
    /// @param positionId The ID of the position to transfer.
    /// @param recipient The address to transfer the position to.
    /// @dev Requires caller to be the owner or have `TransferInternal` permission or be the delegate.
    function internalTransferPosition(uint256 positionId, address recipient)
        external
        whenNotPaused
        positionExists(positionId)
        onlyPositionOwnerOrDelegateOrPermitted(positionId, PermissionType.TransferInternal)
    {
        Position storage pos = s_positions[positionId];
        if (pos.state != PositionState.Available) {
            revert InvalidPositionState(positionId, uint8(pos.state), uint8(PositionState.Available));
        }
        if (recipient == address(0)) revert("Invalid recipient address");

        address oldOwner = pos.owner;

        // Remove from old owner's list (simplified removal)
        uint256[] storage oldUserPosIds = s_userPositions[oldOwner];
         for (uint i = 0; i < oldUserPosIds.length; i++) {
            if (oldUserPosIds[i] == positionId) {
                oldUserPosIds[i] = oldUserPosIds[oldUserPosIds.length - 1];
                oldUserPosIds.pop();
                break;
            }
        }

        // Update owner and add to new owner's list
        pos.owner = recipient;
        s_userPositions[recipient].push(positionId);

        // Clear any position-specific permissions/delegations upon transfer for security
        delete s_positionPermissions[positionId];
        delete s_positionDelegates[positionId];

        emit PositionTransferredInternal(positionId, oldOwner, recipient);
    }

     /// @notice Consolidates multiple 'Available' ERC20 positions of the same token owned by the caller into a single new position.
     /// @param token The address of the ERC20 token.
     /// @param positionIds An array of position IDs to consolidate. Must all be owned by caller, be 'Available', and for the specified token.
     function consolidateUserERC20Positions(IERC20 token, uint256[] calldata positionIds)
        external
        whenNotPaused
     {
         if (positionIds.length <= 1) revert("Need at least 2 positions to consolidate");

         uint256 totalAmount = 0;
         address expectedTokenAddress = address(token);
         address caller = msg.sender;

         // Validate positions and sum amounts
         for (uint i = 0; i < positionIds.length; i++) {
             uint256 posId = positionIds[i];
             Position storage pos = s_positions[posId];

             if (pos.owner == address(0) || pos.owner != caller) {
                  revert PositionsNotOwnedByUser(); // Or InvalidPosition(posId)
             }
             if (pos.state != PositionState.Available) {
                 revert InvalidPositionState(posId, uint8(pos.state), uint8(PositionState.Available));
             }
             if (pos.assetType != AssetType.ERC20 || pos.tokenAddress != expectedTokenAddress) {
                 revert IncompatiblePositions(posId, 0); // Use 0 for the second ID to indicate type mismatch
             }
             totalAmount += pos.amount;
         }

         // Create the new consolidated position
         uint256 newPositionId = _createPosition(AssetType.ERC20, expectedTokenAddress, 0, totalAmount, caller, PositionState.Available);

         // Delete the old positions
         for (uint i = 0; i < positionIds.length; i++) {
             _deletePosition(positionIds[i]);
         }

         emit PositionsConsolidated(caller, token, positionIds, newPositionId, totalAmount);
     }


    /// @notice Locks a position, preventing withdrawal, until a specified time and condition are met.
    /// @param positionId The ID of the position to lock.
    /// @param unlockTime The timestamp after which the position can potentially be unlocked.
    /// @param condition A string describing the off-chain condition required for release (e.g., "Proof of identity submitted").
    /// @dev Requires caller to be the owner or have `LockUnlock` permission or be the delegate. The condition must be marked as met separately.
    function lockPositionConditional(uint256 positionId, uint64 unlockTime, string calldata condition)
        external
        whenNotPaused
        positionExists(positionId)
        onlyPositionOwnerOrDelegate(positionId) // Locking is typically owner/delegate action
    {
        Position storage pos = s_positions[positionId];
        if (pos.state != PositionState.Available) {
            revert InvalidPositionState(positionId, uint8(pos.state), uint8(PositionState.Available));
        }
        if (unlockTime <= block.timestamp) revert("Unlock time must be in the future");

        _updatePositionState(positionId, PositionState.Locked);
        s_lockedPositions[positionId] = LockedPosition({
            unlockTime: unlockTime,
            conditionDescription: condition,
            conditionMet: false // Condition starts as not met
        });

        emit PositionLocked(positionId, unlockTime, condition);
    }

    /// @notice Marks the off-chain condition for a locked position as met.
    /// @param positionId The ID of the locked position.
    /// @dev This function simulates an external process verifying the condition. In a real system, this might be callable only by a trusted oracle, multi-sig, or after complex off-chain verification.
    /// For this example, only the owner can mark conditions met.
    function markLockedConditionMet(uint256 positionId) external onlyOwner positionExists(positionId) {
         Position storage pos = s_positions[positionId];
         if (pos.state != PositionState.Locked) {
             revert InvalidPositionState(positionId, uint8(pos.state), uint8(PositionState.Locked));
         }
         s_lockedPositions[positionId].conditionMet = true;
         emit LockedConditionMet(positionId);
    }


    /// @notice Releases a locked position, changing its state back to 'Available'.
    /// @param positionId The ID of the locked position.
    /// @dev Requires caller to be the owner or have `LockUnlock` permission or be the delegate. Requires unlock time passed and condition met.
    function releaseLockedPosition(uint256 positionId)
        external
        whenNotPaused
        positionExists(positionId)
        onlyPositionOwnerOrDelegate(positionId) // Releasing is typically owner/delegate action
    {
        Position storage pos = s_positions[positionId];
        if (pos.state != PositionState.Locked) {
            revert InvalidPositionState(positionId, uint8(pos.state), uint8(PositionState.Locked));
        }

        LockedPosition storage lockedPos = s_lockedPositions[positionId];
        if (block.timestamp < lockedPos.unlockTime) {
            revert UnlockTimeNotPassed(positionId);
        }
        if (!lockedPos.conditionMet) {
            revert ConditionNotMet(positionId);
        }

        _updatePositionState(positionId, PositionState.Available);
        emit PositionReleased(positionId);
    }


    /// @notice Schedules a position for automatic withdrawal at a future time.
    /// @param positionId The ID of the position to schedule.
    /// @param withdrawalTime The timestamp when the withdrawal should occur.
    /// @dev Requires caller to be the owner or delegate. A separate mechanism (e.g., keeper network calling an external `processScheduledWithdrawals` function - not included here for brevity) would trigger the actual withdrawal.
    function scheduleFutureWithdrawal(uint256 positionId, uint64 withdrawalTime)
        external
        whenNotPaused
        positionExists(positionId)
        onlyPositionOwnerOrDelegate(positionId) // Scheduling is typically owner/delegate action
    {
        Position storage pos = s_positions[positionId];
         if (pos.state != PositionState.Available) {
            revert InvalidPositionState(positionId, uint8(pos.state), uint8(PositionState.Available));
        }
        if (withdrawalTime <= block.timestamp) revert("Withdrawal time must be in the future");

        _updatePositionState(positionId, PositionState.Scheduled);
        s_scheduledWithdrawals[positionId] = ScheduledWithdrawal({
            withdrawalTime: withdrawalTime
        });

        emit WithdrawalScheduled(positionId, withdrawalTime);
    }

     /// @notice Cancels a previously scheduled withdrawal, returning the position to 'Available'.
     /// @param positionId The ID of the scheduled position.
     /// @dev Requires caller to be the owner or delegate.
    function cancelScheduledWithdrawal(uint256 positionId)
        external
        whenNotPaused
        positionExists(positionId)
        onlyPositionOwnerOrDelegate(positionId)
     {
        Position storage pos = s_positions[positionId];
        if (pos.state != PositionState.Scheduled) {
             revert InvalidPositionState(positionId, uint8(pos.state), uint8(PositionState.Scheduled));
         }

         _updatePositionState(positionId, PositionState.Available);
         emit ScheduledWithdrawalCancelled(positionId);
     }


    // --- "Quantum" Mechanics ---

    /// @notice Entangles two ERC721 positions owned by the caller.
    /// @param positionId1 The ID of the first ERC721 position.
    /// @param positionId2 The ID of the second ERC721 position.
    /// @dev Both positions must be ERC721, owned by the caller, and 'Available'. Entangled positions cannot be withdrawn/transferred internally individually.
    function entangleNFTs(uint256 positionId1, uint256 positionId2)
        external
        whenNotPaused
        positionExists(positionId1)
        positionExists(positionId2)
    {
        if (positionId1 == positionId2) revert("Cannot entangle a position with itself");
        Position storage pos1 = s_positions[positionId1];
        Position storage pos2 = s_positions[positionId2];

        if (pos1.owner != msg.sender || pos2.owner != msg.sender) revert("Caller must own both positions");
        if (pos1.state != PositionState.Available || pos2.state != PositionState.Available) {
            revert IncompatiblePositions(positionId1, positionId2); // Use this error for state issues too
        }
        if (pos1.assetType != AssetType.ERC721 || pos2.assetType != AssetType.ERC721) {
             revert IncompatiblePositions(positionId1, positionId2);
        }

        // Create the entangled pair
        uint256 pairId = s_nextEntangledPairId++;
        s_entangledPairs[pairId] = EntangledPair({
            positionId1: positionId1,
            positionId2: positionId2
        });

        // Update position states and link them to the pair
        _updatePositionState(positionId1, PositionState.Entangled);
        _updatePositionState(positionId2, PositionState.Entangled);
        s_positionToEntangledPairId[positionId1] = pairId;
        s_positionToEntangledPairId[positionId2] = pairId;

        emit NFTsEntangled(pairId, positionId1, positionId2);
    }

    /// @notice Disentangles a pair of ERC721 positions.
    /// @param entangledPairId The ID of the entangled pair.
    /// @dev Requires caller to own *both* positions in the pair (implicitly checked by requiring ownership of positionId1).
    function disentangleNFTs(uint256 entangledPairId)
        external
        whenNotPaused
    {
        EntangledPair storage pair = s_entangledPairs[entangledPairId];
        if (pair.positionId1 == 0) revert EntangledPairNotFound(entangledPairId); // Check if pair exists

        uint256 posId1 = pair.positionId1;
        uint256 posId2 = pair.positionId2;

        Position storage pos1 = s_positions[posId1];
        Position storage pos2 = s_positions[posId2];

        // Ensure positions still exist and are owned by caller
        if (pos1.owner == address(0) || pos2.owner == address(0) || pos1.owner != msg.sender || pos2.owner != msg.sender) {
             revert UnauthorizedCaller(msg.sender); // Caller must own both to disentangle
        }
         // Ensure they are still in the Entangled state linked to this pair
        if (pos1.state != PositionState.Entangled || s_positionToEntangledPairId[posId1] != entangledPairId ||
            pos2.state != PositionState.Entangled || s_positionToEntangledPairId[posId2] != entangledPairId) {
             revert InvalidPositionState(entangledPairId, 0, uint8(PositionState.Entangled)); // Use pairId for error context
         }

        // Update position states back to Available
        _updatePositionState(posId1, PositionState.Available);
        _updatePositionState(posId2, PositionState.Available);

        // Remove mapping links
        delete s_positionToEntangledPairId[posId1];
        delete s_positionToEntangledPairId[posId2];

        // Delete the entangled pair
        delete s_entangledPairs[entangledPairId];

        emit NFTsDisentangled(entangledPairId);
    }


    /// @notice Puts an 'Available' position into a 'Superposition' state for a duration.
    /// @param positionId The ID of the position to put into superposition.
    /// @param duration The duration (in seconds) the position will be in the superposition state.
    /// @dev Positions in superposition accrue special rewards based on the `s_quantumState`. Requires caller to be owner/delegate/permitted.
    function createSuperpositionPosition(uint256 positionId, uint64 duration)
        external
        whenNotPaused
        positionExists(positionId)
        onlyPositionOwnerOrDelegateOrPermitted(positionId, PermissionType.SuperpositionControl)
    {
        Position storage pos = s_positions[positionId];
        if (pos.state != PositionState.Available) {
            revert InvalidPositionState(positionId, uint8(pos.state), uint8(PositionState.Available));
        }
        if (duration == 0) revert("Duration must be > 0");

        _updatePositionState(positionId, PositionState.Superposition); // Handles cleanup of previous state data
        s_superpositionStates[positionId] = SuperpositionState({ endTime: uint64(block.timestamp) + duration });
        s_superpositionStartTime[positionId] = uint64(block.timestamp); // Initialize start time for rewards

        emit SuperpositionCreated(positionId, s_superpositionStates[positionId].endTime);
    }

    /// @notice Resolves a Superposition state. If duration passed, returns to Available.
    /// @param positionId The ID of the superposition position.
    /// @dev Can be called by anyone after the duration ends to resolve the state. Owner/delegate/permitted can potentially call earlier (logic for penalties/partial rewards needed for early exit).
    function resolveSuperposition(uint256 positionId)
        external
        whenNotPaused // Can potentially be called when paused if state logic is critical? Decide security model. Keep whenNotPaused for now.
        positionExists(positionId)
    {
        Position storage pos = s_positions[positionId];
        if (pos.state != PositionState.Superposition) {
            revert InvalidPositionState(positionId, uint8(pos.state), uint8(PositionState.Superposition));
        }
        SuperpositionState storage superPos = s_superpositionStates[positionId];

        // Update reward basis before resolving
        _updateSuperpositionRewardBasis(positionId);

        PositionState finalState;
        if (block.timestamp >= superPos.endTime) {
            // Duration passed, resolve to Available
            finalState = PositionState.Available;
        } else {
            // Early resolution - requires permission. Example: only owner/delegate/permitted can resolve early.
             bool isOwner = msg.sender == pos.owner;
             bool isDelegate = msg.sender == s_positionDelegates[positionId];
             bool hasPermission = s_positionPermissions[positionId][msg.sender][uint8(PermissionType.SuperpositionControl)];

             if (!isOwner && !isDelegate && !hasPermission) {
                  revert UnauthorizedCaller(msg.sender); // Or specific error for early resolution
             }
            // Implement early exit logic if needed (e.g., penalty, reduced rewards)
            // For this example, early exit just moves to Available without penalty
            finalState = PositionState.Available;
        }

        _updatePositionState(positionId, finalState);
        emit SuperpositionResolved(positionId, finalState);
    }

    /// @notice Allows the designated oracle address to update the simulated 'Quantum State'.
    /// @param newState The new value for the quantum state.
    /// @dev This function represents an integration point with an oracle delivering external data.
    function updateQuantumState(uint256 newState) external {
        if (msg.sender != s_oracleAddress) {
            revert UnauthorizedCaller(msg.sender);
        }
        uint256 oldState = s_quantumState;
        s_quantumState = newState;
        emit QuantumStateUpdated(oldState, newState);
    }

    // --- Rewards ---

    /// @notice Claims accrued rewards for the caller's positions.
    /// @param positionIds An array of position IDs to calculate/claim rewards from.
    /// @dev Reward calculation is based on the `s_superpositionRewardBasis` which is updated when positions enter/leave or are resolved from Superposition state.
    function claimRewards(uint256[] calldata positionIds) external whenNotPaused {
        address caller = msg.sender;
        uint256 totalClaimable = 0;

        for (uint i = 0; i < positionIds.length; i++) {
             uint256 posId = positionIds[i];
             Position storage pos = s_positions[posId];

             // Only claim for caller's positions
             if (pos.owner != caller) continue; // Skip if not owned by caller

             // Update basis if position is currently in superposition
             if (pos.state == PositionState.Superposition) {
                  _updateSuperpositionRewardBasis(posId);
             }

             // Add accrued basis to claimable amount
             // The basis is time * quantumState. We need a conversion factor to ETH/tokens.
             // For simplicity, let's say 1 unit of basis = 1 wei of reward.
             // A real system would need a defined reward token and calculation logic.
             uint256 rewardBasis = s_superpositionRewardBasis[posId];
             totalClaimable += rewardBasis;
             s_superpositionRewardBasis[posId] = 0; // Reset basis after claiming
        }

        if (totalClaimable == 0) revert NoRewardsClaimable(caller);

        // Transfer rewards (Assuming rewards are paid in ETH from contract balance for simplicity)
        (bool success, ) = caller.call{value: totalClaimable}("");
        require(success, "Reward transfer failed");

        emit RewardsClaimed(caller, totalClaimable);
    }


    // --- Access & Permissions ---

    /// @notice Grants a specific permission for a single position to a delegate address.
    /// @param positionId The ID of the position.
    /// @param delegate The address to grant the permission to.
    /// @param permissionType The type of permission to grant (uint8 representation of PermissionType enum).
    /// @dev Only the position owner can grant permissions. Overrides any existing permission for this type/delegate.
    function grantSpecificPermission(uint256 positionId, address delegate, uint8 permissionType)
        external
        whenNotPaused
        positionExists(positionId)
    {
         Position storage pos = s_positions[positionId];
         if (pos.owner != msg.sender) revert UnauthorizedCaller(msg.sender); // Only owner can grant permission
         if (delegate == address(0)) revert("Invalid delegate address");
         if (permissionType > uint8(type(PermissionType).max)) revert("Invalid permission type");

         s_positionPermissions[positionId][delegate][permissionType] = true;
         emit PermissionGranted(positionId, delegate, permissionType);
    }

     /// @notice Revokes a specific permission for a single position from a delegate address.
     /// @param positionId The ID of the position.
     /// @param delegate The address to revoke the permission from.
     /// @param permissionType The type of permission to revoke (uint8 representation of PermissionType enum).
     /// @dev Only the position owner can revoke permissions.
    function revokeSpecificPermission(uint256 positionId, address delegate, uint8 permissionType)
        external
        whenNotPaused
        positionExists(positionId)
     {
        Position storage pos = s_positions[positionId];
        if (pos.owner != msg.sender) revert UnauthorizedCaller(msg.sender); // Only owner can revoke permission
        if (delegate == address(0)) revert("Invalid delegate address");
        if (permissionType > uint8(type(PermissionType).max)) revert("Invalid permission type");

        s_positionPermissions[positionId][delegate][permissionType] = false;
        emit PermissionRevoked(positionId, delegate, permissionType);
     }

     /// @notice Delegates full management (excluding withdrawal by default) of a position to another address.
     /// @param positionId The ID of the position.
     /// @param delegate The address to delegate management to (address(0) to clear delegation).
     /// @dev Only the position owner can delegate management. This overrides any specific permissions for the delegate on this position.
    function delegatePositionManagement(uint256 positionId, address delegate)
        external
        whenNotPaused
        positionExists(positionId)
     {
        Position storage pos = s_positions[positionId];
        if (pos.owner != msg.sender) revert UnauthorizedCaller(msg.sender); // Only owner can delegate

        // Clear specific permissions for this position/delegate combination upon delegation change
        delete s_positionPermissions[positionId][delegate]; // Clear permissions for the *new* delegate
        delete s_positionPermissions[positionId][s_positionDelegates[positionId]]; // Clear permissions for the *old* delegate

        s_positionDelegates[positionId] = delegate;
        emit PositionDelegated(positionId, delegate);
     }


    // --- Governance (Simplified) ---

    /// @notice Proposes a parameter change or action for the contract.
    /// @param target The target contract address (usually `address(this)`).
    /// @param value ETH value to send with the call.
    /// @param signature Function signature, e.g., "setQuantumState(uint256)".
    /// @param data Encoded function parameters.
    /// @param description Human-readable description of the proposal.
    /// @dev In this simple example, only the owner can create proposals.
    function proposeParameterChange(
        address target,
        uint256 value,
        bytes calldata signature,
        bytes calldata data,
        string calldata description
    ) external onlyOwner whenNotPaused returns (uint256 proposalId) {
        proposalId = s_nextProposalId++;
        s_proposals[proposalId] = Proposal({
            target: target,
            value: value,
            signature: signature,
            data: data,
            description: description,
            votesFor: 0,
            votesAgainst: 0,
            executed: false
        });
        // Owner implicitly votes yes? Or require separate vote. Let's require separate vote.

        emit ProposalCreated(proposalId, description, msg.sender);
    }

    /// @notice Votes on an active proposal.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param support True for Yes, False for No.
    /// @dev Simple 1 address = 1 vote model. Cannot vote multiple times.
    function voteOnProposal(uint256 proposalId, bool support) external whenNotPaused {
        Proposal storage proposal = s_proposals[proposalId];
        if (proposal.target == address(0)) revert ProposalNotFound(proposalId); // Check if proposal exists
        if (proposal.executed) revert ProposalNotExecutable(proposalId); // Cannot vote on executed proposals
        if (s_proposalVotes[proposalId][msg.sender]) revert ProposalAlreadyVoted(proposalId, msg.sender); // Cannot vote twice

        s_proposalVotes[proposalId][msg.sender] = true;
        if (support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        // Add voting deadline logic in a real system

        emit Voted(proposalId, msg.sender, support);
    }

    /// @notice Executes a proposal that has passed the voting threshold.
    /// @param proposalId The ID of the proposal to execute.
    /// @dev In this simple example, the threshold is `votesFor > votesAgainst` and called by anyone. A real system needs a defined threshold, quorum, and execution window.
    function executeProposal(uint256 proposalId) external whenNotPaused {
        Proposal storage proposal = s_proposals[proposalId];
        if (proposal.target == address(0)) revert ProposalNotFound(proposalId);
        if (proposal.executed) revert ProposalNotExecutable(proposalId);

        // Simple threshold: More Yes votes than No votes
        if (proposal.votesFor <= proposal.votesAgainst) {
             revert ProposalNotExecutable(proposalId); // Not enough support
        }

        proposal.executed = true;

        // Execute the low-level call
        // Build the full calldata
        bytes memory fullCalldata = abi.encodePacked(proposal.signature, proposal.data);

        (bool success, ) = proposal.target.call{value: proposal.value}(fullCalldata);
        // Note: Reverting on execution failure is standard for governance
        require(success, "Proposal execution failed");

        emit ProposalExecuted(proposalId);
    }


    // --- Helper/View Functions ---

    /// @notice Gets the details of a specific position.
    /// @param positionId The ID of the position.
    /// @return A tuple containing position details.
    function getPositionDetails(uint256 positionId)
        external
        view
        positionExists(positionId)
        returns (
            uint256 id,
            AssetType assetType,
            address tokenAddress,
            uint256 tokenId,
            uint256 amount,
            address owner,
            PositionState state,
            uint256 createdTime
        )
    {
        Position storage pos = s_positions[positionId];
        return (
            positionId,
            pos.assetType,
            pos.tokenAddress,
            pos.tokenId,
            pos.amount,
            pos.owner,
            pos.state,
            pos.createdTime
        );
    }

    /// @notice Gets the list of position IDs owned by a specific address.
    /// @param user The address of the user.
    /// @return An array of position IDs.
    function getUserPositions(address user) external view returns (uint256[] memory) {
        return s_userPositions[user];
    }

    /// @notice Gets the current simulated quantum state.
    /// @return The current quantum state value.
    function getQuantumState() external view returns (uint256) {
        return s_quantumState;
    }

    /// @notice Gets the details of a locked position.
    /// @param positionId The ID of the locked position.
    /// @return A tuple containing unlock time, condition description, and whether condition is met.
    function getLockedPositionDetails(uint256 positionId) external view positionExists(positionId) returns (uint64 unlockTime, string memory conditionDescription, bool conditionMet) {
        if (s_positions[positionId].state != PositionState.Locked) revert InvalidPositionState(positionId, uint8(s_positions[positionId].state), uint8(PositionState.Locked));
        LockedPosition storage lockedPos = s_lockedPositions[positionId];
        return (lockedPos.unlockTime, lockedPos.conditionDescription, lockedPos.conditionMet);
    }

    /// @notice Gets the currently accrued reward basis for a specific position.
    /// @param positionId The ID of the position.
    /// @return The total reward basis accrued.
    /// @dev Basis needs to be converted to actual reward tokens/ETH in `claimRewards`.
    function getPositionRewardBasis(uint256 positionId) external view positionExists(positionId) returns (uint256) {
         // If currently in superposition, calculate potential new basis before returning
         if (s_positions[positionId].state == PositionState.Superposition) {
             uint64 startTime = s_superpositionStartTime[positionId];
             uint64 currentTime = uint64(block.timestamp);
             if (currentTime > startTime) {
                 uint256 timeDelta = currentTime - startTime;
                 return s_superpositionRewardBasis[positionId] + (timeDelta * s_quantumState);
             }
         }
        return s_superpositionRewardBasis[positionId];
    }

    /// @notice Gets the reward basis accrued by a user across all their positions.
    /// @param user The user's address.
    /// @return The total reward basis for the user.
     function getUserTotalRewardBasis(address user) external view returns (uint256) {
         uint256 totalBasis = 0;
         uint256[] memory posIds = s_userPositions[user];
         for (uint i = 0; i < posIds.length; i++) {
             totalBasis += getPositionRewardBasis(posIds[i]);
         }
         return totalBasis;
     }

     /// @notice Checks if a delegate has a specific permission for a position.
     /// @param positionId The ID of the position.
     /// @param delegate The delegate address.
     /// @param permissionType The type of permission (uint8).
     /// @return True if the delegate has the permission, false otherwise.
    function hasPositionPermission(uint256 positionId, address delegate, uint8 permissionType) external view positionExists(positionId) returns (bool) {
        if (permissionType > uint8(type(PermissionType).max)) return false;
        return s_positionPermissions[positionId][delegate][permissionType];
    }

    // Fallback to receive ETH deposits
    receive() external payable {
        depositETH();
    }
}
```

**Explanation and Considerations:**

1.  **No OpenZeppelin Inheritance:** This contract implements basic access control (`onlyOwner`, `s_paused` state) and ERC20/ERC721 interaction (`IERC20`, `IERC721` interfaces) manually rather than inheriting from OpenZeppelin base contracts like `Ownable`, `Pausable`, or `ERC20/ERC721` implementations. This fulfills the non-duplication constraint at a basic level.
2.  **Position System:** Assets aren't just balances in a mapping; they are structured `Position` objects with IDs, owners, and states. This allows complex state transitions and metadata per asset.
3.  **States:** The `PositionState` enum introduces concepts like `Locked`, `Scheduled`, `Superposition`, and `Entangled`, moving beyond a simple 'owned' or 'staked' state.
4.  **"Quantum" Concepts:**
    *   **Superposition:** Simulated by a `SuperpositionState` where positions accrue `s_superpositionRewardBasis` based on time and the external `s_quantumState`. Resolution (`resolveSuperposition`) is required to exit this state. This is a *metaphor* for a state with dynamic outcomes/properties.
    *   **Entanglement:** Simulated by linking two ERC721 positions (`EntangledPair`). The `_canWithdrawPosition` helper includes logic that prevents withdrawing individual entangled NFTs, requiring them to be "disentangled" first. This is a *metaphor* for linked fate.
    *   **Quantum State:** A single `s_quantumState` variable that can be updated by a designated oracle address. This external factor influences the reward rate in the "Superposition" state, simulating environmental influence.
5.  **Permissions & Delegation:** Beyond basic ownership, specific `PermissionType` flags can be granted per position to delegates, allowing fine-grained control without transferring ownership. Delegation (`delegatePositionManagement`) provides broader, but still revocable, control.
6.  **Scheduled Withdrawals:** A function to mark a position for future withdrawal, requiring a separate trigger mechanism (like a bot or keeper calling a future function, not fully implemented here) to execute.
7.  **Conditional Locks:** Positions can be locked based on time *and* an off-chain condition, which requires separate confirmation (`markLockedConditionMet`).
8.  **Consolidation:** A practical function allowing users to merge multiple small ERC20 positions of the same token into one, simplifying management.
9.  **Simplified Governance:** A basic proposal/vote/execute mechanism is included. It uses simple majority and assumes the target is the contract itself for parameter changes (`updateQuantumState` could be called this way). A real DAO is far more complex.
10. **Reward Basis:** Rewards from Superposition are tracked as an abstract "basis" (`s_superpositionRewardBasis`) which is converted to actual tokens (simulated as ETH here) upon claiming. The conversion factor (`s_quantumState`) makes the reward rate dynamic.
11. **Complexity:** This contract is significantly more complex than a standard token or simple vault. It manages multiple data structures and state transitions. This increases development effort, auditing complexity, and gas costs.
12. **External Dependencies:** It relies on the existence of standard ERC20/ERC721 tokens and assumes a trusted `s_oracleAddress` exists to update the `s_quantumState`.
13. **Missing Features/Simplifications:** A production contract would need:
    *   More robust error handling and input validation.
    *   Optimized storage and gas usage (e.g., packed structs, avoiding storage writes in loops).
    *   A defined reward token and distribution mechanism (not just ETH).
    *   A keeper network or external trigger for scheduled withdrawals and potentially resolving superposition automatically.
    *   A more secure oracle integration pattern (Chainlink, etc.).
    *   A more sophisticated governance system (voting power based on tokens, quorum, voting period, proposal types, execution timelocks).
    *   Proper handling of ERC721 approvals (`safeTransferFrom` requires prior approval).
    *   Handling edge cases like position deletion impacting active schedules, permissions, etc. (basic cleanup is included).

This contract provides a conceptual framework for a highly dynamic, state-aware asset management system using abstract concepts for unique features. It definitely meets the criteria of being non-standard and incorporating creative/advanced ideas within the limits of Solidity.