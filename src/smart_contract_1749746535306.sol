Okay, let's design a complex and creative smart contract focusing on unique state management, conditional actions, and a custom token mechanic, inspired by abstract physics concepts like "Quantum States" and "Potential Energy".

We will create a "Quantum Vault" where users can deposit tokens into different "states" that have varying lock-up periods, yield rates (in a custom "Potential Energy" token), and interaction rules like "Entanglement".

**Concept:**
Users deposit supported ERC20 tokens into specific `QuantumState`s within the `QuantumVault`. Each state has parameters like minimum lock duration, PE yield rate, and entanglement possibilities. Holding tokens in a state accrues a custom `PotentialEnergy` (PE) token. Users can change states (with potential costs), withdraw (collapse state, potentially with penalties), claim accrued PE, and even "Entangle" their position with another user's position in certain states for mutual benefits or dependencies.

**Outline:**

1.  **License and Pragma:** Standard Solidity headers.
2.  **Imports:** ERC20, Ownable.
3.  **Error Definitions:** Custom errors for clarity.
4.  **Event Definitions:** Events for key actions (Deposit, Withdraw, StateChange, Entanglement etc.).
5.  **Enums:** For request statuses.
6.  **Structs:**
    *   `QuantumState`: Defines the properties of a state (name, lock time, yield, penalty, entanglement rules).
    *   `VaultPosition`: Represents a user's deposit in a specific state.
    *   `EntanglementRequest`: Details of a request to entangle positions.
7.  **State Variables:**
    *   Owner address.
    *   Supported ERC20 tokens list/mapping.
    *   Potential Energy Token address.
    *   Mapping for `QuantumState` configurations.
    *   Mapping for `VaultPosition` data.
    *   Mapping to track user's position IDs.
    *   Mapping for pending/active `EntanglementRequest`s.
    *   Counters for unique IDs (position, state, request).
    *   Global PE rate factor.
    *   Emergency shutdown flag.
8.  **PotentialEnergy Token Contract (Separate but integrated):** A simple ERC20 token minted by the `QuantumVault`.
9.  **Internal/Helper Functions:**
    *   Calculate accrued PE for a position.
    *   Validate position ownership.
    *   Check state compatibility.
    *   Apply quantum fluctuation (a simplified pseudo-random factor).
10. **External/Public Functions (targeting > 20):**
    *   **Setup/Admin:**
        1.  `constructor`: Deploy PE token, set owner.
        2.  `addSupportedToken`: Whitelist an ERC20 token.
        3.  `removeSupportedToken`: Remove a whitelisted token.
        4.  `addQuantumState`: Define a new state configuration.
        5.  `updateQuantumState`: Modify an existing state.
        6.  `setGlobalPERateFactor`: Adjust the overall PE earning rate.
        7.  `toggleEmergencyShutdown`: Pause/unpause contract.
        8.  `recoverERC20Stuck`: Rescue tokens sent incorrectly (owner only).
    *   **User Actions (Core Vault Logic):**
        9.  `deposit`: Deposit ERC20 into a specified `QuantumState`.
        10. `changeQuantumState`: Move a position to a different state.
        11. `claimPotentialEnergy`: Claim accrued PE for a single position.
        12. `claimAllPotentialEnergy`: Claim accrued PE for all user positions.
        13. `withdraw` (Collapse State): Withdraw tokens and PE from a position.
    *   **Entanglement System:**
        14. `createEntanglementRequest`: Propose entangling two positions.
        15. `cancelEntanglementRequest`: Cancel an outgoing request.
        16. `acceptEntanglementRequest`: Accept an incoming request.
        17. `rejectEntanglementRequest`: Reject an incoming request.
        18. `breakEntanglement`: Dissolve an active entanglement.
    *   **View Functions (Information):**
        19. `getSupportedTokens`: Get the list of supported tokens.
        20. `getQuantumStateDetails`: Get configuration for a specific state.
        21. `getUserPositionIds`: Get all position IDs owned by a user.
        22. `getPositionDetails`: Get detailed data for a specific position.
        23. `getPotentialEnergyAccrued`: Calculate *current* accrued PE for a position.
        24. `getTotalPotentialEnergyAccruedByUser`: Calculate total accrued PE across all user positions.
        25. `getEntanglementRequestDetails`: Get details of a specific request.
        26. `isPositionEntangled`: Check if a position is currently entangled.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/erc20/IERC20.sol";
import "@openzeppelin/contracts/token/erc20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Outline:
// 1. License and Pragma
// 2. Imports (IERC20, ERC20 for the PE token, Ownable, ReentrancyGuard)
// 3. Error Definitions
// 4. Event Definitions
// 5. Enums (Entanglement status)
// 6. Structs (QuantumState, VaultPosition, EntanglementRequest)
// 7. State Variables (Owner, Tokens, PE Token, States, Positions, Requests, Counters, Factors, Flags)
// 8. PotentialEnergy Token (Simple ERC20 within this file for simplicity, could be separate)
// 9. Internal/Helper Functions (_calculatePotentialEnergy, _validatePosition, _applyFluctuation, etc.)
// 10. External/Public Functions (>20 functions covering setup, user actions, entanglement, views)

// Function Summary:
// Setup/Admin:
// constructor(): Deploys PE token, sets owner.
// addSupportedToken(IERC20 token): Whitelists an ERC20 for deposit.
// removeSupportedToken(IERC20 token): Removes an ERC20 from whitelist.
// addQuantumState(...): Defines a new type of quantum state.
// updateQuantumState(...): Modifies an existing state configuration.
// setGlobalPERateFactor(uint256 factor): Adjusts overall PE earning.
// toggleEmergencyShutdown(): Pauses/unpauses key user operations.
// recoverERC20Stuck(IERC20 token, uint256 amount): Rescues accidentally sent tokens.

// User Actions (Core Vault Logic):
// deposit(IERC20 token, uint256 amount, uint256 stateId): Deposits tokens into a state.
// changeQuantumState(uint256 positionId, uint256 newStateId): Moves a position to a new state.
// claimPotentialEnergy(uint256 positionId): Claims PE from a single position.
// claimAllPotentialEnergy(): Claims PE from all user's positions.
// withdraw(uint256 positionId): Withdraws tokens and PE from a position (state collapse).

// Entanglement System:
// createEntanglementRequest(uint256 requesterPositionId, uint256 targetPositionId): Proposes entanglement.
// cancelEntanglementRequest(uint256 requestId): Cancels own request.
// acceptEntanglementRequest(uint256 requestId): Accepts a request.
// rejectEntanglementRequest(uint256 requestId): Rejects a request.
// breakEntanglement(uint256 positionId): Breaks an active entanglement.

// View Functions (Information):
// getSupportedTokens(): Gets list of supported token addresses.
// getQuantumStateDetails(uint256 stateId): Gets configuration for a state.
// getUserPositionIds(address user): Gets all position IDs for a user.
// getPositionDetails(uint256 positionId): Gets details for a specific position.
// getPotentialEnergyAccrued(uint256 positionId): Calculates current accrued PE.
// getTotalPotentialEnergyAccruedByUser(address user): Calculates total accrued PE for a user.
// getEntanglementRequestDetails(uint256 requestId): Gets details for a request.
// isPositionEntangled(uint256 positionId): Checks entanglement status.
// getQuantumStateCount(): Gets the total number of defined states.
// getPositionCount(): Gets the total number of positions created.


// Simple ERC20 for Potential Energy Token
contract PotentialEnergyToken is ERC20, Ownable {
    constructor() ERC20("PotentialEnergy", "PE") Ownable(msg.sender) {}

    // Vault contract will mint PE tokens
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}

contract QuantumVault is Ownable, ReentrancyGuard {

    // --- Errors ---
    error Vault__TokenNotSupported();
    error Vault__InvalidQuantumState();
    error Vault__DepositAmountZero();
    error Vault__PositionNotFound();
    error Vault__NotPositionOwner();
    error Vault__PositionAlreadyCollapsed();
    error Vault__LockedPeriodNotPassed();
    error Vault__InsufficientPotentialEnergy();
    error Vault__InvalidStateTransition();
    error Vault__EntanglementNotAllowedInState();
    error Vault__CannotEntangleOwnPositions();
    error Vault__PositionAlreadyEntangled();
    error Vault__EntanglementRequestNotFound();
    error Vault__NotRequesterOrTarget();
    error Vault__RequestAlreadyHandled();
    error Vault__NotEntangled();
    error Vault__EntanglementStillActive(uint256 entangledWithPositionId);
    error Vault__EmergencyShutdownActive();
    error Vault__ZeroAddress();
    error Vault__StateStillInUse(); // If trying to remove/modify state while positions are in it
    error Vault__CannotBreakEntanglementAlone(); // Example: requires both parties or penalty
    error Vault__UnsupportedOperationDuringEntanglement(); // e.g., changing state while entangled

    // --- Events ---
    event ERC20Supported(address indexed token);
    event ERC20Unsupported(address indexed token);
    event QuantumStateAdded(uint256 indexed stateId, string name);
    event QuantumStateUpdated(uint256 indexed stateId, string name);
    event GlobalPERateFactorUpdated(uint256 factor);
    event EmergencyShutdownToggled(bool isActive);
    event TokensRecovered(address indexed token, address indexed to, uint256 amount);

    event Deposit(address indexed user, uint256 indexed positionId, address indexed token, uint256 amount, uint256 stateId);
    event StateChanged(uint256 indexed positionId, uint256 indexed oldStateId, uint256 indexed newStateId);
    event PotentialEnergyClaimed(uint256 indexed positionId, address indexed user, uint256 amount);
    event Withdrawal(uint256 indexed positionId, address indexed user, address indexed token, uint256 tokenAmount, uint256 peAmount, uint256 penaltyAmount);

    event EntanglementRequestCreated(uint256 indexed requestId, uint256 indexed requesterPositionId, uint256 indexed targetPositionId);
    event EntanglementRequestResponded(uint256 indexed requestId, bool accepted);
    event PositionsEntangled(uint256 indexed position1Id, uint256 indexed position2Id);
    event EntanglementBroken(uint256 indexed position1Id, uint256 indexed position2Id);

    // --- Enums ---
    enum EntanglementStatus {
        Pending,
        Accepted,
        Rejected,
        Canceled
    }

    // --- Structs ---
    struct QuantumState {
        string name;                // e.g., "Stable Orbit", "Volatile Flux"
        uint64 minLockDuration;     // Minimum time (in seconds) in this state
        uint64 peYieldRatePerBlock; // PE tokens per block per token deposited (scaled, e.g., 1e18)
        uint16 collapsePenaltyRate; // Percentage penalty on withdrawal if locked period not passed (0-10000, for 2 decimals)
        bool allowsEntanglement;    // Can positions in this state be entangled?
        bool yieldBoostWhenEntangled; // Does entanglement boost PE yield in this state?
        bool requiresEntanglementToChangeState; // Must be entangled to leave this state?
        uint16 stateChangeCostPE;   // Cost in PE tokens to move OUT of this state (scaled)
    }

    struct VaultPosition {
        address owner;
        address token;
        uint256 amount;
        uint256 stateId;
        uint64 depositTime;
        uint64 lastStateChangeTime; // Used for PE calculation
        uint256 potentialEnergyAccrued; // PE accumulated but not yet claimed
        bool isCollapsed;           // True if tokens have been withdrawn
        uint256 entangledWithPositionId; // 0 if not entangled, otherwise ID of partner position
        uint256 entanglementRequestId; // The request ID that created this entanglement
    }

    struct EntanglementRequest {
        uint256 requesterPositionId;
        uint256 targetPositionId;
        address requester;
        address target; // Owner of the target position at the time of request
        EntanglementStatus status;
    }

    // --- State Variables ---
    PotentialEnergyToken public peToken;

    mapping(address => bool) public supportedTokens;
    address[] private _supportedTokensList; // To retrieve the list easily

    mapping(uint256 => QuantumState) public quantumStates;
    uint256 public nextQuantumStateId = 1; // State 0 reserved or unused

    mapping(uint256 => VaultPosition) public positions;
    mapping(address => uint256[]) private _userPositions; // Maps user address to list of their active position IDs
    uint256 public nextPositionId = 1;

    mapping(uint256 => EntanglementRequest) public entanglementRequests;
    uint256 public nextEntanglementRequestId = 1;

    uint256 public globalPERateFactor = 1e18; // Base factor for PE calculation (1.0)

    bool public emergencyShutdown = false;

    // --- Constructor ---
    constructor() Ownable(msg.sender) {
        peToken = new PotentialEnergyToken();
    }

    // --- Modifier ---
    modifier onlySupportedToken(IERC20 token) {
        if (!supportedTokens[address(token)]) revert Vault__TokenNotSupported();
        _;
    }

    modifier onlyExistingState(uint256 stateId) {
        if (stateId == 0 || quantumStates[stateId].minLockDuration == 0 && quantumStates[stateId].peYieldRatePerBlock == 0 && quantumStates[stateId].collapsePenaltyRate == 0 && !quantumStates[stateId].allowsEntanglement && !quantumStates[stateId].yieldBoostWhenEntangled && !quantumStates[stateId].requiresEntanglementToChangeState && quantumStates[stateId].stateChangeCostPE == 0) revert Vault__InvalidQuantumState(); // Basic check if state exists/initialized
        _;
    }

    modifier onlyPositionOwner(uint256 positionId) {
        if (positions[positionId].owner != msg.sender) revert Vault__NotPositionOwner();
        _;
    }

     modifier onlyActivePosition(uint256 positionId) {
        if (positions[positionId].isCollapsed) revert Vault__PositionAlreadyCollapsed();
        _;
    }

     modifier notEntangled(uint256 positionId) {
         if (positions[positionId].entangledWithPositionId != 0) revert Vault__PositionAlreadyEntangled();
         _;
     }

      modifier onlyIfEntangled(uint256 positionId) {
         if (positions[positionId].entangledWithPositionId == 0) revert Vault__NotEntangled();
         _;
     }

    modifier whenNotShutdown() {
        if (emergencyShutdown) revert Vault__EmergencyShutdownActive();
        _;
    }


    // --- Internal/Helper Functions ---

    // Calculates potential energy accrued since lastStateChangeTime
    function _calculatePotentialEnergy(uint256 positionId) internal view returns (uint256 accrued) {
        VaultPosition storage pos = positions[positionId];
        QuantumState storage state = quantumStates[pos.stateId];

        if (state.peYieldRatePerBlock == 0 || pos.amount == 0) {
            return 0;
        }

        uint256 blocksSinceLastUpdate = block.number - pos.lastStateChangeTime;
        if (blocksSinceLastUpdate == 0) {
            return 0; // No new blocks, no new PE
        }

        uint256 yieldRate = state.peYieldRatePerBlock;

        // Apply yield boost if entangled and state allows/requires it
        if (pos.entangledWithPositionId != 0 && state.yieldBoostWhenEntangled) {
            // Example boost: 20% extra yield
            yieldRate = yieldRate + (yieldRate / 5); // 20% boost
        }

        // Apply a simplified 'Quantum Fluctuation' factor based on block.timestamp
        // Note: block.timestamp is predictable, use Chainlink VRF for true randomness in production
        uint256 fluctuationFactor = 1e18; // Start with 1.0
        uint256 fluctuationSeed = uint256(block.timestamp);
        if (fluctuationSeed % 100 < 5) { // 5% chance of a slight negative fluctuation
            fluctuationFactor = 99e16; // Reduce by 1%
        } else if (fluctuationSeed % 100 > 95) { // 5% chance of a slight positive fluctuation
             fluctuationFactor = 101e16; // Increase by 1%
        }
        // Apply fluctuation to yield rate
        yieldRate = (yieldRate * fluctuationFactor) / 1e18;


        // Calculate accrued PE: amount * rate * blocks / scale (1e18)
        // Use a large scale factor to handle fractions and prevent overflow early
        // Simplified: (amount * rate * blocks) / (1e18 scale for rate)
        // For better precision with large amounts and rates, consider SafeMath or a more complex fixed-point library
        // Let's assume PE yield rate is scaled by 1e18
        accrued = (pos.amount * yieldRate / 1e18) * blocksSinceLastUpdate / 1e18; // Simplified calculation, assumes amount is not scaled

         // Factor in global rate factor
        accrued = (accrued * globalPERateFactor) / 1e18;
    }

     // Updates accrued PE for a position and resets lastStateChangeTime
    function _updatePotentialEnergy(uint256 positionId) internal {
        uint256 newlyAccrued = _calculatePotentialEnergy(positionId);
        positions[positionId].potentialEnergyAccrued += newlyAccrued;
        positions[positionId].lastStateChangeTime = uint64(block.number);
    }

    // Helper to remove position ID from user's array (basic implementation, not gas efficient for large arrays)
    function _removePositionIdFromUserArray(address user, uint256 positionId) internal {
        uint256[] storage posIds = _userPositions[user];
        for (uint256 i = 0; i < posIds.length; i++) {
            if (posIds[i] == positionId) {
                posIds[i] = posIds[posIds.length - 1]; // Replace with last element
                posIds.pop(); // Remove last element
                break;
            }
        }
    }


    // --- Setup/Admin Functions ---

    /// @notice Adds a new ERC20 token to the list of supported tokens.
    /// @param token The address of the ERC20 token contract.
    function addSupportedToken(IERC20 token) external onlyOwner {
        if (address(token) == address(0)) revert Vault__ZeroAddress();
        if (!supportedTokens[address(token)]) {
            supportedTokens[address(token)] = true;
            _supportedTokensList.push(address(token));
            emit ERC20Supported(address(token));
        }
    }

    /// @notice Removes an ERC20 token from the list of supported tokens.
    /// @dev Be cautious removing tokens if positions still hold them. Does not affect existing positions.
    /// @param token The address of the ERC20 token contract.
    function removeSupportedToken(IERC20 token) external onlyOwner {
         if (address(token) == address(0)) revert Vault__ZeroAddress();
        if (supportedTokens[address(token)]) {
            supportedTokens[address(token)] = false;
             // Basic removal from list - less critical than map, can be inefficient
            for (uint256 i = 0; i < _supportedTokensList.length; i++) {
                if (_supportedTokensList[i] == address(token)) {
                    _supportedTokensList[i] = _supportedTokensList[_supportedTokensList.length - 1];
                    _supportedTokensList.pop();
                    break;
                }
            }
            emit ERC20Unsupported(address(token));
        }
    }

    /// @notice Defines a new type of quantum state for deposits.
    /// @param name Name of the state.
    /// @param minLockDuration Minimum duration in seconds.
    /// @param peYieldRatePerBlock PE tokens per block per token (scaled by 1e18).
    /// @param collapsePenaltyRate Penalty % (0-10000) for early withdrawal.
    /// @param allowsEntanglement Can positions in this state be entangled?
    /// @param yieldBoostWhenEntangled Does entanglement boost yield?
    /// @param requiresEntanglementToChangeState Must be entangled to leave this state?
    /// @param stateChangeCostPE Cost in PE to leave this state (scaled by 1e18).
    /// @return The ID of the newly created state.
    function addQuantumState(
        string memory name,
        uint64 minLockDuration,
        uint64 peYieldRatePerBlock,
        uint16 collapsePenaltyRate,
        bool allowsEntanglement,
        bool yieldBoostWhenEntangled,
        bool requiresEntanglementToChangeState,
        uint16 stateChangeCostPE
    ) external onlyOwner returns (uint256) {
        uint256 stateId = nextQuantumStateId++;
        quantumStates[stateId] = QuantumState({
            name: name,
            minLockDuration: minLockDuration,
            peYieldRatePerBlock: peYieldRatePerBlock,
            collapsePenaltyRate: collapsePenaltyRate,
            allowsEntanglement: allowsEntanglement,
            yieldBoostWhenEntangled: yieldBoostWhenEntangled,
            requiresEntanglementToChangeState: requiresEntanglementToChangeState,
            stateChangeCostPE: stateChangeCostPE
        });
        emit QuantumStateAdded(stateId, name);
        return stateId;
    }

     /// @notice Updates the configuration of an existing quantum state.
     /// @dev Be cautious updating states that currently hold positions, especially lock times or penalties.
     /// @param stateId The ID of the state to update.
     /// @param name Name of the state.
     /// @param minLockDuration Minimum duration in seconds.
     /// @param peYieldRatePerBlock PE tokens per block per token (scaled by 1e18).
     /// @param collapsePenaltyRate Penalty % (0-10000) for early withdrawal.
     /// @param allowsEntanglement Can positions in this state be entangled?
     /// @param yieldBoostWhenEntangled Does entanglement boost yield?
     /// @param requiresEntanglementToChangeState Must be entangled to leave this state?
     /// @param stateChangeCostPE Cost in PE to leave this state (scaled by 1e18).
    function updateQuantumState(
        uint256 stateId,
        string memory name,
        uint64 minLockDuration,
        uint64 peYieldRatePerBlock,
        uint16 collapsePenaltyRate,
        bool allowsEntanglement,
        bool yieldBoostWhenEntangled,
        bool requiresEntanglementToChangeState,
        uint16 stateChangeCostPE
    ) external onlyOwner onlyExistingState(stateId) {
        // Consider adding a check here if state is currently used by active positions,
        // potentially blocking updates or adding a delay/migration process.
        // For simplicity, this version allows immediate update affecting future interactions.

        quantumStates[stateId] = QuantumState({
            name: name,
            minLockDuration: minLockDuration,
            peYieldRatePerBlock: peYieldRatePerBlock,
            collapsePenaltyRate: collapsePenaltyRate,
            allowsEntanglement: allowsEntanglement,
            yieldBoostWhenEntangled: yieldBoostWhenEntangled,
            requiresEntanglementToChangeState: requiresEntanglementToChangeState,
            stateChangeCostPE: stateChangeCostPE
        });
        emit QuantumStateUpdated(stateId, name);
    }

    /// @notice Sets the global factor affecting all PE earning rates.
    /// @param factor The new global rate factor (scaled by 1e18, 1e18 is 1.0).
    function setGlobalPERateFactor(uint256 factor) external onlyOwner {
        globalPERateFactor = factor;
        emit GlobalPERateFactorUpdated(factor);
    }

    /// @notice Toggles the emergency shutdown flag. Prevents key user operations like deposit, withdraw, state change, entanglement creation/response.
    function toggleEmergencyShutdown() external onlyOwner {
        emergencyShutdown = !emergencyShutdown;
        emit EmergencyShutdownToggled(emergencyShutdown);
    }

    /// @notice Allows the owner to recover ERC20 tokens mistakenly sent directly to the contract address.
    /// @dev Can be used to recover unsupported tokens or tokens accidentally sent.
    /// @param token The address of the ERC20 token to recover.
    /// @param amount The amount to recover.
    function recoverERC20Stuck(IERC20 token, uint256 amount) external onlyOwner {
        if (address(token) == address(peToken)) revert Vault__TokenNotSupported(); // Cannot recover PE token
        if (amount == 0) return;
        IERC20(token).transfer(msg.sender, amount);
        emit TokensRecovered(address(token), msg.sender, amount);
    }

    // --- User Action Functions ---

    /// @notice Deposits a supported ERC20 token into a specified quantum state.
    /// @param token The ERC20 token to deposit.
    /// @param amount The amount to deposit.
    /// @param stateId The ID of the quantum state to deposit into.
    function deposit(IERC20 token, uint256 amount, uint256 stateId)
        external
        nonReentrant
        whenNotShutdown
        onlySupportedToken(token)
        onlyExistingState(stateId)
    {
        if (amount == 0) revert Vault__DepositAmountZero();

        // Transfer tokens from user to contract
        bool success = token.transferFrom(msg.sender, address(this), amount);
        if (!success) {
            // This should ideally not happen if approve was called correctly, but as a safeguard:
            revert("TransferFrom failed");
        }

        // Create a new position
        uint256 positionId = nextPositionId++;
        positions[positionId] = VaultPosition({
            owner: msg.sender,
            token: address(token),
            amount: amount,
            stateId: stateId,
            depositTime: uint64(block.timestamp), // Use timestamp for lock duration
            lastStateChangeTime: uint64(block.number), // Use block.number for PE calculation blocks
            potentialEnergyAccrued: 0,
            isCollapsed: false,
            entangledWithPositionId: 0,
            entanglementRequestId: 0
        });

        _userPositions[msg.sender].push(positionId);

        emit Deposit(msg.sender, positionId, address(token), amount, stateId);
    }

    /// @notice Changes the quantum state of an active position.
    /// @dev May cost PE depending on the state being left.
    /// @param positionId The ID of the position to change state for.
    /// @param newStateId The ID of the new state.
    function changeQuantumState(uint256 positionId, uint256 newStateId)
        external
        nonReentrant
        whenNotShutdown
        onlyPositionOwner(positionId)
        onlyActivePosition(positionId)
        onlyExistingState(newStateId)
    {
        VaultPosition storage pos = positions[positionId];
        uint256 oldStateId = pos.stateId;
        QuantumState storage oldState = quantumStates[oldStateId];
        QuantumState storage newState = quantumStates[newStateId];

        if (oldStateId == newStateId) return; // No change

        // Check entanglement status if required by old state
        if (oldState.requiresEntanglementToChangeState && pos.entangledWithPositionId == 0) {
             revert Vault__RequiresEntanglementToChangeState();
        }
        // Disallow state changes while entangled? Or require partner consent?
        // Simple: cannot change state while entangled, must break entanglement first.
        if (pos.entangledWithPositionId != 0) {
            revert Vault__UnsupportedOperationDuringEntanglement();
        }


        // Calculate PE accrued in the current state before changing
        _updatePotentialEnergy(positionId);

        // Apply state change cost if any
        uint256 costPE = oldState.stateChangeCostPE;
        if (costPE > 0) {
            if (pos.potentialEnergyAccrued < costPE) revert Vault__InsufficientPotentialEnergy();
            pos.potentialEnergyAccrued -= costPE;
            // Optionally burn or send costPE elsewhere
        }

        // Update state and reset PE calculation timer
        pos.stateId = newStateId;
        pos.lastStateChangeTime = uint64(block.number); // Reset timer for PE calculation in the new state

        emit StateChanged(positionId, oldStateId, newStateId);
    }

    /// @notice Claims the accrued Potential Energy for a single position.
    /// @param positionId The ID of the position to claim from.
    function claimPotentialEnergy(uint256 positionId)
        external
        nonReentrant
        whenNotShutdown
        onlyPositionOwner(positionId)
        onlyActivePosition(positionId)
    {
        VaultPosition storage pos = positions[positionId];

        // Calculate and update accrued PE
        _updatePotentialEnergy(positionId);

        uint256 amountToClaim = pos.potentialEnergyAccrued;
        if (amountToClaim == 0) return; // Nothing to claim

        pos.potentialEnergyAccrued = 0;

        // Mint and transfer PE tokens to the user
        peToken.mint(msg.sender, amountToClaim);

        emit PotentialEnergyClaimed(positionId, msg.sender, amountToClaim);
    }

    /// @notice Claims the accrued Potential Energy for all active positions owned by the sender.
    function claimAllPotentialEnergy()
        external
        nonReentrant
        whenNotShutdown
    {
        uint256[] storage posIds = _userPositions[msg.sender];
        uint256 totalClaimed = 0;

        for (uint256 i = 0; i < posIds.length; i++) {
            uint256 positionId = posIds[i];
            if (!positions[positionId].isCollapsed) {
                 // Calculate and update accrued PE for this position
                _updatePotentialEnergy(positionId);

                uint256 amountToClaim = positions[positionId].potentialEnergyAccrued;
                if (amountToClaim > 0) {
                    positions[positionId].potentialEnergyAccrued = 0;
                    totalClaimed += amountToClaim;
                    emit PotentialEnergyClaimed(positionId, msg.sender, amountToClaim); // Emit for each position
                }
            }
        }

        if (totalClaimed > 0) {
             // Mint and transfer total PE tokens to the user
            peToken.mint(msg.sender, totalClaimed);
             // Optional: emit a summary event as well
        }
    }


    /// @notice Withdraws tokens and accrued PE from a position (collapses the state).
    /// @dev May incur a penalty if the minimum lock duration has not passed.
    /// @param positionId The ID of the position to withdraw from.
    function withdraw(uint256 positionId)
        external
        nonReentrant
        whenNotShutdown
        onlyPositionOwner(positionId)
        onlyActivePosition(positionId)
    {
        VaultPosition storage pos = positions[positionId];
        QuantumState storage state = quantumStates[pos.stateId];

        // Disallow withdrawal if entangled
        if (pos.entangledWithPositionId != 0) {
            revert Vault__EntanglementStillActive(pos.entangledWithPositionId);
        }

        // Calculate and update final accrued PE
        _updatePotentialEnergy(positionId);

        uint256 tokenAmount = pos.amount;
        uint256 peAmount = pos.potentialEnergyAccrued;
        uint256 penaltyAmount = 0; // Penalty is applied to the token amount

        // Check lock period and apply penalty if necessary
        if (block.timestamp < pos.depositTime + state.minLockDuration) {
            // Calculate penalty percentage and apply it to the token amount
            uint256 penaltyBps = state.collapsePenaltyRate; // Rate is in basis points (1/100th of a percent)
            penaltyAmount = (tokenAmount * penaltyBps) / 10000; // 10000 for 100% (100 * 100)
            tokenAmount -= penaltyAmount; // Reduce withdrawal amount by penalty
            // Optional: Send penaltyAmount tokens to a treasury or burn them
        }

        // Mark position as collapsed
        pos.isCollapsed = true;
        pos.potentialEnergyAccrued = 0; // Claim all accrued PE (might be zero if claimed before)
        pos.amount = 0; // Clear amount

        // Remove position ID from user's active list (less gas efficient)
        _removePositionIdFromUserArray(msg.sender, positionId);

        // Transfer token amount back to user
        IERC20(pos.token).transfer(msg.sender, tokenAmount);

        // Mint and transfer remaining PE to user (if any)
        if (peAmount > 0) {
             peToken.mint(msg.sender, peAmount);
        }

        emit Withdrawal(positionId, msg.sender, pos.token, tokenAmount, peAmount, penaltyAmount);
    }


    // --- Entanglement System Functions ---

    /// @notice Creates a request to entangle two positions.
    /// @dev Both positions must be active, not already entangled, and in states that allow entanglement.
    /// @param requesterPositionId The ID of the position owned by the sender.
    /// @param targetPositionId The ID of the position to request entanglement with.
    /// @return The ID of the created entanglement request.
    function createEntanglementRequest(uint256 requesterPositionId, uint256 targetPositionId)
        external
        nonReentrant
        whenNotShutdown
        onlyPositionOwner(requesterPositionId)
        onlyActivePosition(requesterPositionId)
        onlyActivePosition(targetPositionId) // Target position must also be active
        notEntangled(requesterPositionId)
        notEntangled(targetPositionId) // Target position must also not be entangled
         returns (uint256)
    {
        if (requesterPositionId == targetPositionId) revert Vault__CannotEntangleOwnPositions();

        VaultPosition storage requesterPos = positions[requesterPositionId];
        VaultPosition storage targetPos = positions[targetPositionId];

        QuantumState storage requesterState = quantumStates[requesterPos.stateId];
        QuantumState storage targetState = quantumStates[targetPos.stateId];

        if (!requesterState.allowsEntanglement || !targetState.allowsEntanglement) {
            revert Vault__EntanglementNotAllowedInState();
        }

        // Check if target position exists and has an owner
        if (targetPos.owner == address(0)) revert Vault__PositionNotFound();


        uint256 requestId = nextEntanglementRequestId++;
        entanglementRequests[requestId] = EntanglementRequest({
            requesterPositionId: requesterPositionId,
            targetPositionId: targetPositionId,
            requester: msg.sender,
            target: targetPos.owner,
            status: EntanglementStatus.Pending
        });

        emit EntanglementRequestCreated(requestId, requesterPositionId, targetPositionId);
        return requestId;
    }

    /// @notice Cancels a pending entanglement request initiated by the sender.
    /// @param requestId The ID of the request to cancel.
    function cancelEntanglementRequest(uint256 requestId)
        external
        nonReentrant
        whenNotShutdown
    {
        EntanglementRequest storage req = entanglementRequests[requestId];
        if (req.requester != msg.sender) revert Vault__NotRequesterOrTarget();
        if (req.status != EntanglementStatus.Pending) revert Vault__RequestAlreadyHandled();

        req.status = EntanglementStatus.Canceled;
        emit EntanglementRequestResponded(requestId, false); // Emit as rejected/canceled response
    }


    /// @notice Responds to a pending entanglement request (accept or reject).
    /// @param requestId The ID of the request to respond to.
    /// @param accept True to accept, false to reject.
    function respondToEntanglementRequest(uint256 requestId, bool accept)
        external
        nonReentrant
        whenNotShutdown
    {
        EntanglementRequest storage req = entanglementRequests[requestId];
        if (req.target != msg.sender) revert Vault__NotRequesterOrTarget(); // Must be the target of the request
        if (req.status != EntanglementStatus.Pending) revert Vault__RequestAlreadyHandled();

        VaultPosition storage requesterPos = positions[req.requesterPositionId];
        VaultPosition storage targetPos = positions[req.targetPositionId];

        // Double check positions are still active and not entangled just in case
        if (requesterPos.isCollapsed || targetPos.isCollapsed || requesterPos.entangledWithPositionId != 0 || targetPos.entangledWithPositionId != 0) {
             req.status = EntanglementStatus.Rejected; // Auto-reject if conditions changed
             emit EntanglementRequestResponded(requestId, false);
             return; // Exit after rejecting
        }

        req.status = accept ? EntanglementStatus.Accepted : EntanglementStatus.Rejected;

        if (accept) {
            // Establish the entanglement link
            requesterPos.entangledWithPositionId = req.targetPositionId;
            requesterPos.entanglementRequestId = requestId;

            targetPos.entangledWithPositionId = req.requesterPositionId;
            targetPos.entanglementRequestId = requestId;

            // Update PE calculation timer as state might get yield boost
            _updatePotentialEnergy(req.requesterPositionId);
            _updatePotentialEnergy(req.targetPositionId);


            emit PositionsEntangled(req.requesterPositionId, req.targetPositionId);
        }

        emit EntanglementRequestResponded(requestId, accept);
    }

    /// @notice Breaks an active entanglement between two positions.
    /// @dev Can be called by either entangled party. May require mutual consent or a penalty/cost in a more complex version.
    /// @param positionId The ID of one of the entangled positions.
    function breakEntanglement(uint256 positionId)
        external
        nonReentrant
        whenNotShutdown
        onlyPositionOwner(positionId)
        onlyActivePosition(positionId)
        onlyIfEntangled(positionId)
    {
        VaultPosition storage pos1 = positions[positionId];
        uint256 pos2Id = pos1.entangledWithPositionId;
        VaultPosition storage pos2 = positions[pos2Id];

        // Ensure the linked position is also valid and entangled back
        if (pos2.owner == address(0) || pos2.isCollapsed || pos2.entangledWithPositionId != positionId) {
             // This indicates a data inconsistency, attempt to fix pos1's state
             pos1.entangledWithPositionId = 0;
             pos1.entanglementRequestId = 0;
             revert Vault__NotEntangled(); // Revert as it wasn't a valid pair
        }

        // In this simple version, either party can break it unilaterally.
        // More complex: check state rules, require partner's call, or burn PE.

        // Calculate and update PE for both positions before breaking entanglement (potentially losing yield boost)
        _updatePotentialEnergy(positionId);
        _updatePotentialEnergy(pos2Id);


        // Remove the entanglement link from both positions
        pos1.entangledWithPositionId = 0;
        pos1.entanglementRequestId = 0;

        pos2.entangledWithPositionId = 0;
        pos2.entanglementRequestId = 0;

        // Mark the request as completed/broken if it exists
        if (pos1.entanglementRequestId != 0 && entanglementRequests[pos1.entanglementRequestId].status == EntanglementStatus.Accepted) {
             entanglementRequests[pos1.entanglementRequestId].status = EntanglementStatus.Canceled; // Use canceled status to indicate completed/broken
        }


        emit EntanglementBroken(positionId, pos2Id);
    }

    // --- View Functions ---

    /// @notice Gets the list of addresses of supported ERC20 tokens.
    /// @return An array of supported token addresses.
    function getSupportedTokens() external view returns (address[] memory) {
        return _supportedTokensList;
    }

    /// @notice Gets the configuration details for a specific quantum state.
    /// @param stateId The ID of the state.
    /// @return The QuantumState struct details.
    function getQuantumStateDetails(uint256 stateId) external view onlyExistingState(stateId) returns (QuantumState memory) {
        return quantumStates[stateId];
    }

    /// @notice Gets the list of active position IDs for a specific user.
    /// @param user The address of the user.
    /// @return An array of position IDs.
    function getUserPositionIds(address user) external view returns (uint256[] memory) {
        return _userPositions[user];
    }

    /// @notice Gets the detailed information for a specific vault position.
    /// @param positionId The ID of the position.
    /// @return The VaultPosition struct details.
    function getPositionDetails(uint256 positionId) external view returns (VaultPosition memory) {
         VaultPosition storage pos = positions[positionId];
         if (pos.owner == address(0)) revert Vault__PositionNotFound(); // Check if position exists
        return pos;
    }

    /// @notice Calculates the potential energy accrued for a specific position up to the current block. Does not claim it.
    /// @param positionId The ID of the position.
    /// @return The total potential energy (current accrued + newly calculated) for the position.
    function getPotentialEnergyAccrued(uint256 positionId) external view returns (uint256) {
         VaultPosition storage pos = positions[positionId];
         if (pos.owner == address(0) || pos.isCollapsed) revert Vault__PositionNotFound();
        return pos.potentialEnergyAccrued + _calculatePotentialEnergy(positionId);
    }

     /// @notice Calculates the total potential energy accrued across all active positions for a user. Does not claim it.
     /// @param user The address of the user.
     /// @return The total potential energy accrued for the user.
    function getTotalPotentialEnergyAccruedByUser(address user) external view returns (uint256) {
        uint256[] storage posIds = _userPositions[user];
        uint256 totalAccrued = 0;
         for (uint256 i = 0; i < posIds.length; i++) {
            uint256 positionId = posIds[i];
            if (!positions[positionId].isCollapsed) {
                 totalAccrued += positions[positionId].potentialEnergyAccrued + _calculatePotentialEnergy(positionId);
            }
        }
        return totalAccrued;
    }

    /// @notice Gets the details for a specific entanglement request.
    /// @param requestId The ID of the request.
    /// @return The EntanglementRequest struct details.
    function getEntanglementRequestDetails(uint256 requestId) external view returns (EntanglementRequest memory) {
        EntanglementRequest storage req = entanglementRequests[requestId];
        if (req.requesterPositionId == 0) revert Vault__EntanglementRequestNotFound(); // Basic check if request exists
        return req;
    }

    /// @notice Checks if a position is currently entangled.
    /// @param positionId The ID of the position.
    /// @return True if entangled, false otherwise.
    function isPositionEntangled(uint256 positionId) external view returns (bool) {
        VaultPosition storage pos = positions[positionId];
        if (pos.owner == address(0)) revert Vault__PositionNotFound();
        return pos.entangledWithPositionId != 0;
    }

    /// @notice Gets the total number of quantum states defined in the contract.
    /// @return The total count of states.
    function getQuantumStateCount() external view returns (uint256) {
        return nextQuantumStateId - 1; // nextId starts at 1, so count is nextId - 1
    }

    /// @notice Gets the total number of positions ever created (including collapsed ones).
    /// @return The total count of positions.
    function getPositionCount() external view returns (uint256) {
        return nextPositionId - 1; // nextId starts at 1, so count is nextId - 1
    }
}
```

**Explanation of Advanced/Creative Concepts:**

1.  **Quantum States:** Instead of simple staking pools, users lock tokens into defined "states" with distinct parameters (`minLockDuration`, `peYieldRatePerBlock`, `collapsePenaltyRate`, `allowsEntanglement`). This abstracts the concept of different investment or storage strategies into unique, configurable states within the contract.
2.  **Potential Energy Token (PE):** A custom ERC20 token (`PotentialEnergyToken`) is minted based on the duration and *state* of a user's deposit. It represents accumulated value or yield *within* the vault system, separate from the deposited asset. This token has no inherent external value unless defined by other protocols or markets, making it a core mechanic *of this contract*.
3.  **Dynamic PE Accrual:** PE isn't fixed; it accrues based on the `peYieldRatePerBlock` of the current state, the amount staked, a `globalPERateFactor`, and a simulated `_applyFluctuation` (using block data as a simple pseudo-random source, *not* cryptographically secure randomness, which would require oracles like Chainlink VRF).
4.  **State Change Mechanics:** Users can transition between states (`changeQuantumState`), but this may incur a cost paid in the PE token accumulated within that specific position. This creates dynamic interaction costs tied to the system's internal token.
5.  **State Collapse & Penalties:** Withdrawing (`withdraw`) is termed "collapsing" the state. It releases the deposited tokens and any accrued PE. However, withdrawing before the state's `minLockDuration` passes incurs a penalty on the *principal* token amount, calculated based on the state's `collapsePenaltyRate`.
6.  **Entanglement System:** This is a key creative element. Two users' positions can be "Entangled" (`createEntanglementRequest`, `respondToEntanglementRequest`, `breakEntanglement`).
    *   Entanglement is only possible between positions in states that `allowsEntanglement`.
    *   It can provide a `yieldBoostWhenEntangled` in certain states, incentivizing linking positions.
    *   It introduces dependencies: positions cannot be withdrawn or change states (`UnsupportedOperationDuringEntanglement` error) while entangled (in this version, requiring breaking the entanglement first). A more complex version could require mutual consent for actions or distribute penalties/costs between entangled parties.
    *   The `EntanglementRequest` system adds a multi-step, stateful process for linking positions.

7.  **Conditional Logic:** Many functions have complex `require` or `revert` conditions based on the position's state, lock time, entanglement status, request status, and the user's identity.
8.  **ReentrancyGuard:** Used to prevent reentrancy attacks, particularly important with `transferFrom` and external calls.
9.  **Error Handling:** Uses custom errors (`error Vault__...`) which are more gas-efficient than `require` with strings in newer Solidity versions.
10. **View Functions:** A comprehensive set of view functions allows users and interfaces to inspect the state of the contract, positions, states, and requests.

This contract goes significantly beyond standard ERC20, staking, or simple vault patterns by introducing abstract state management, an internal token economy with dynamic accrual and costs, and a unique multi-party entanglement mechanic. It provides a framework for complex user interactions and state transitions governed by configurable rules within the contract itself.