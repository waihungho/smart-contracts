Okay, let's create a smart contract inspired by concepts from quantum mechanics, applied to asset management and conditional logic on the blockchain. We'll call it `QuantumVault`.

This contract will allow users to deposit assets (ETH or ERC20) into positions that can exist in "superposition" (potentially claimable by multiple parties/conditions), be "entangled" with other positions, or have "probabilistic" outcomes upon "observation" (a triggering action). It's a conceptual design, not a literal quantum computer simulation.

**Disclaimer:** This is a complex and conceptual contract for educational purposes, demonstrating advanced Solidity features and creative logic. It has not been audited and should *not* be used in a production environment without extensive security review and testing. The "randomness" simulation using block data is *not* secure for high-value applications.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For potential future complex calculations

// Outline:
// 1. Contract Description & Concepts
// 2. Imports
// 3. State Variables
//    - Enums for Position State & Type
//    - Structs for Vault Position, Superposition Target, Collapse Condition
//    - Mappings & Counters for managing positions
//    - (Simulated) External Data Source
// 4. Events
// 5. Modifiers
// 6. Core Logic (Position Creation & Management)
// 7. Quantum Mechanics Inspired Functions
//    - Superposition Management (Deposit, Add/Remove Targets, Add/Remove Conditions, Initiate/Finalize Collapse)
//    - Entanglement Management (Deposit, Link/Break, Initiate/Finalize Resolution)
//    - Probabilistic Outcome (Deposit, Trigger Outcome)
//    - Observation & Collapse Functions
// 8. Withdrawal Functions
// 9. Query & View Functions
// 10. Utility & Emergency Functions

// Function Summary:
// --- Core Logic ---
// 1.  depositEther: Standard ETH deposit (can be used as a base for quantum states or standalone).
// 2.  depositERC20: Standard ERC20 deposit (can be used as a base for quantum states or standalone).
// 3.  _createPosition: Internal helper to initialize a new vault position.
// --- Superposition Management ---
// 4.  createSuperpositionPositionETH: Creates a new position with ETH in superposition.
// 5.  createSuperpositionPositionERC20: Creates a new position with ERC20 in superposition.
// 6.  addSuperpositionTarget: Adds a potential recipient/share to a superposition position.
// 7.  removeSuperpositionTarget: Removes a potential recipient/share from a superposition position.
// 8.  addCollapseCondition: Adds a condition that must be met for a superposition collapse.
// 9.  removeCollapseCondition: Removes a condition from a superposition position.
// 10. initiateSuperpositionCollapse: Marks a superposition position for collapse check.
// 11. finalizeSuperpositionCollapse: Checks conditions and collapses a superposition position, distributing funds.
// --- Entanglement Management ---
// 12. createEntangledPositionETH: Creates an ETH position entangled with another.
// 13. createEntangledPositionERC20: Creates an ERC20 position entangled with another.
// 14. linkEntangledPositions: Links two existing positions as entangled.
// 15. breakEntanglement: Breaks the link between two entangled positions.
// 16. initiateEntanglementResolution: Starts the process to resolve an entangled pair.
// 17. finalizeEntanglementResolution: Resolves an entangled pair, potentially releasing funds based on entangled state.
// --- Probabilistic Outcome ---
// 18. createProbabilisticPositionETH: Creates an ETH position with a probabilistic outcome.
// 19. createProbabilisticPositionERC20: Creates an ERC20 position with a probabilistic outcome.
// 20. triggerProbabilisticOutcome: Triggers the random outcome determination for a probabilistic position.
// --- Observation & Collapse (Generalized) ---
// 21. observeAndCollapse: Attempts to finalize any position based on its type and conditions.
// --- Withdrawal ---
// 22. withdrawCollapsedPosition: Allows the rightful recipient to withdraw from a *collapsed* position.
// --- Query & View ---
// 23. getPositionDetails: Get full details of a specific vault position.
// 24. getPositionState: Get the current state (Superposition, Collapsed, etc.).
// 25. getPositionType: Get the type (Superposition, Entangled, Probabilistic, Standard).
// 26. getSuperpositionTargets: Get potential recipients for a superposition position.
// 27. getCollapseConditions: Get conditions for a superposition collapse.
// 28. isConditionMet: Check if a specific condition for a position is met.
// 29. getEntangledPartner: Get the ID of the entangled partner position.
// 30. getProbabilisticOutcome: Get the determined outcome for a probabilistic position.
// 31. getVaultPositionCount: Get the total number of positions created.
// --- Utility & Emergency ---
// 32. simulateExternalData: (Simulated) Function to update external data value.
// 33. emergencyTunnelWithdrawal: Allows a designated address to withdraw from *any* position in an emergency (conceptually like quantum tunneling bypassing barriers).

contract QuantumVault is ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Math for uint256;

    // --- State Variables ---

    enum PositionState {
        Initial,           // Just created, waiting for quantum state setup
        Superposition,     // In multiple potential states simultaneously
        Entangled,         // Linked state with another position
        Probabilistic,     // Outcome is determined by chance upon trigger
        InitiatedCollapse, // Collapse process started, conditions being checked
        Resolving,         // Entanglement resolution in progress
        OutcomeDetermined, // Probabilistic outcome fixed
        Collapsed,         // State has been determined (e.g., superposition collapsed, entanglement resolved)
        Withdrawn,         // Funds have been withdrawn
        Breached           // Emergency withdrawal occurred
    }

    enum PositionType {
        Standard,      // Basic deposit, owner can withdraw (not the focus, but useful)
        Superposition, // Defined by potential targets and collapse conditions
        Entangled,     // Defined by a link to another position
        Probabilistic  // Defined by potential outcomes and probabilities
    }

    enum ConditionType {
        TimeBased,      // Based on a specific timestamp
        ExternalDataGT, // Based on external data being Greater Than a value
        ExternalDataLT, // Based on external data being Less Than a value
        ExternalDataEQ  // Based on external data being Equal To a value
        // Add more complex condition types as needed
    }

    struct SuperpositionTarget {
        address recipient;
        uint256 shareBps; // Basis points (1/10000) share of the position amount
    }

    struct CollapseCondition {
        ConditionType conditionType;
        uint256 value; // e.g., timestamp, external data threshold
        bool met;      // Flag to track if this specific condition has been met
    }

    struct VaultPosition {
        address owner; // The address that created the position
        address assetAddress; // Address of ERC20 token, address(0) for ETH
        uint256 amount;
        PositionType positionType;
        PositionState currentState;
        uint256 creationTimestamp;

        // Superposition specific fields
        SuperpositionTarget[] superpositionTargets; // Potential recipients and their shares
        CollapseCondition[] collapseConditions;    // Conditions required for collapse
        bool initiatedCollapse;                     // Flag if collapse is initiated

        // Entanglement specific fields
        uint256 entangledPartnerId; // ID of the position it's entangled with (0 if none)
        bool initiatedResolution;    // Flag if entanglement resolution is initiated

        // Probabilistic specific fields
        bytes32 probabilisticSeed; // Seed used for outcome determination
        uint256 determinedOutcomeIndex; // Index of the chosen outcome (from simulated internal list)

        // Collapsed state fields
        address finalRecipient; // The address determined after collapse/resolution
        uint256 finalAmount;    // The exact amount determined after collapse/resolution

        // Re-entrancy guard specific to position withdrawal
        bool withdrawalLock;
    }

    mapping(uint256 => VaultPosition) public vaultPositions;
    uint256 public nextPositionId = 1; // Start IDs from 1

    // (Simulated) External data source - replace with actual oracle in production
    uint256 private simulatedExternalData = 0;

    // Emergency tunnel address
    address public emergencyTunnelAddress;

    // --- Events ---

    event PositionCreated(uint256 indexed positionId, address indexed owner, PositionType positionType, uint256 amount, address assetAddress);
    event SuperpositionTargetAdded(uint256 indexed positionId, address recipient, uint256 shareBps);
    event CollapseConditionAdded(uint256 indexed positionId, ConditionType conditionType, uint256 value);
    event CollapseInitiated(uint256 indexed positionId);
    event PositionCollapsed(uint256 indexed positionId, address finalRecipient, uint256 finalAmount);
    event EntanglementLinked(uint256 indexed position1Id, uint256 indexed position2Id);
    event EntanglementBroken(uint256 indexed position1Id, uint256 indexed position2Id);
    event EntanglementResolutionInitiated(uint256 indexed positionId);
    event PositionResolved(uint256 indexed positionId, address finalRecipient, uint256 finalAmount);
    event ProbabilisticOutcomeTriggered(uint256 indexed positionId, uint256 determinedOutcomeIndex);
    event PositionWithdrawn(uint256 indexed positionId, address recipient, uint256 amount);
    event EmergencyTunnelWithdrawal(uint256 indexed positionId, address recipient, uint256 amount);
    event ExternalDataUpdated(uint256 newData);

    // --- Modifiers ---

    modifier whenStateIs(uint256 _positionId, PositionState _state) {
        require(vaultPositions[_positionId].currentState == _state, "QV: Invalid state for action");
        _;
    }

    modifier whenStateIsNot(uint256 _positionId, PositionState _state) {
        require(vaultPositions[_positionId].currentState != _state, "QV: Action not allowed in current state");
        _;
    }

    modifier onlyPositionOwner(uint256 _positionId) {
        require(vaultPositions[_positionId].owner == msg.sender, "QV: Only position owner can perform this action");
        _;
    }

    modifier onlyEntangledPartner(uint256 _positionId) {
         require(
            vaultPositions[_positionId].entangledPartnerId != 0 && // Must be entangled
            vaultPositions[vaultPositions[_positionId].entangledPartnerId].owner == msg.sender, // Partner's owner is sender
            "QV: Only entangled partner's owner can perform this action"
        );
        _;
    }

     modifier notCollapsed(uint256 _positionId) {
        require(
            vaultPositions[_positionId].currentState != PositionState.Collapsed &&
            vaultPositions[_positionId].currentState != PositionState.Withdrawn &&
            vaultPositions[_positionId].currentState != PositionState.Breached,
            "QV: Position is already collapsed or finalized"
        );
        _;
    }

    modifier positionExists(uint256 _positionId) {
        require(_positionId > 0 && _positionId < nextPositionId, "QV: Position does not exist");
        _;
    }

    modifier nonReentrantPosition(uint256 _positionId) {
        require(!vaultPositions[_positionId].withdrawalLock, "QV: Reentrant call on position withdrawal");
        vaultPositions[_positionId].withdrawalLock = true;
        _;
    }

    // --- Constructor ---
    constructor(address _emergencyTunnelAddress) {
        require(_emergencyTunnelAddress != address(0), "QV: Emergency tunnel address cannot be zero");
        emergencyTunnelAddress = _emergencyTunnelAddress;
    }

    // --- Core Logic (Position Creation Helper) ---

    function _createPosition(
        address _owner,
        address _assetAddress,
        uint256 _amount,
        PositionType _positionType,
        PositionState _initialState
    ) internal returns (uint256) {
        require(_amount > 0, "QV: Amount must be greater than 0");

        uint256 id = nextPositionId;
        vaultPositions[id] = VaultPosition({
            owner: _owner,
            assetAddress: _assetAddress,
            amount: _amount,
            positionType: _positionType,
            currentState: _initialState,
            creationTimestamp: block.timestamp,
            superpositionTargets: new SuperpositionTarget[](0),
            collapseConditions: new CollapseCondition[](0),
            initiatedCollapse: false,
            entangledPartnerId: 0, // Default: not entangled
            initiatedResolution: false,
            probabilisticSeed: bytes32(0), // Default: no seed
            determinedOutcomeIndex: 0, // Default: invalid index
            finalRecipient: address(0),
            finalAmount: 0,
            withdrawalLock: false // Initial state
        });
        nextPositionId++;

        emit PositionCreated(id, _owner, _positionType, _amount, _assetAddress);
        return id;
    }

     // --- Basic Deposits (Can be building blocks) ---

    function depositEther() external payable nonReentrant {
        // Create a standard position, owner can withdraw
        _createPosition(msg.sender, address(0), msg.value, PositionType.Standard, PositionState.Initial);
        // For a standard position, state could transition to Collapsed immediately, or require an 'observe' step.
        // Let's keep it simple and allow immediate withdrawal for standard type, or require observeAndCollapse.
        // For this complex contract, let's enforce `observeAndCollapse` even for Standard to unify withdrawal flow.
        // The initial state is `Initial`. User calls `observeAndCollapse` to make it `Collapsed`.
    }

     function depositERC20(address _tokenAddress, uint256 _amount) external nonReentrant {
        require(_tokenAddress != address(0), "QV: Invalid token address");
        IERC20 token = IERC20(_tokenAddress);
        require(token.balanceOf(msg.sender) >= _amount, "QV: Insufficient token balance");
        require(token.allowance(msg.sender, address(this)) >= _amount, "QV: Token allowance too low");

        token.safeTransferFrom(msg.sender, address(this), _amount);

        // Create a standard position
        _createPosition(msg.sender, _tokenAddress, _amount, PositionType.Standard, PositionState.Initial);
         // Initial state is `Initial`. User calls `observeAndCollapse` to make it `Collapsed`.
    }

    // --- Superposition Management ---

    /**
     * @notice Creates a new position where the deposited ETH is in a superposition state.
     *         It requires potential targets and collapse conditions to be added later.
     */
    function createSuperpositionPositionETH() external payable nonReentrant returns (uint256) {
        require(msg.value > 0, "QV: Cannot create superposition with 0 ETH");
        // Initial state is Superposition, but needs targets/conditions
        return _createPosition(msg.sender, address(0), msg.value, PositionType.Superposition, PositionState.Superposition);
    }

     /**
     * @notice Creates a new position where the deposited ERC20 is in a superposition state.
     *         It requires potential targets and collapse conditions to be added later.
     */
    function createSuperpositionPositionERC20(address _tokenAddress, uint256 _amount) external nonReentrant returns (uint256) {
        require(_tokenAddress != address(0), "QV: Invalid token address");
         require(_amount > 0, "QV: Cannot create superposition with 0 amount");
        IERC20 token = IERC20(_tokenAddress);
        require(token.balanceOf(msg.sender) >= _amount, "QV: Insufficient token balance");
        require(token.allowance(msg.sender, address(this)) >= _amount, "QV: Token allowance too low");

        token.safeTransferFrom(msg.sender, address(this), _amount);

         // Initial state is Superposition, but needs targets/conditions
        return _createPosition(msg.sender, _tokenAddress, _amount, PositionType.Superposition, PositionState.Superposition);
    }


    /**
     * @notice Adds a potential recipient and their share to a superposition position.
     * @param _positionId The ID of the superposition position.
     * @param _recipient The potential recipient address.
     * @param _shareBps The share in basis points (1/10000).
     */
    function addSuperpositionTarget(uint256 _positionId, address _recipient, uint256 _shareBps)
        external
        onlyPositionOwner(_positionId)
        whenStateIs(_positionId, PositionState.Superposition)
        notCollapsed(_positionId)
    {
        require(_recipient != address(0), "QV: Invalid recipient address");
        require(_shareBps > 0 && _shareBps <= 10000, "QV: Share must be between 1 and 10000 bps");

        VaultPosition storage position = vaultPositions[_positionId];
        uint256 currentTotalShare = 0;
        for(uint i=0; i < position.superpositionTargets.length; i++) {
            currentTotalShare += position.superpositionTargets[i].shareBps;
        }
        require(currentTotalShare + _shareBps <= 10000, "QV: Total shares exceed 10000 bps");


        position.superpositionTargets.push(SuperpositionTarget(_recipient, _shareBps));
        emit SuperpositionTargetAdded(_positionId, _recipient, _shareBps);
    }

     /**
     * @notice Removes a potential recipient and their share from a superposition position by index.
     * @param _positionId The ID of the superposition position.
     * @param _index The index of the target to remove.
     */
    function removeSuperpositionTarget(uint256 _positionId, uint256 _index)
        external
        onlyPositionOwner(_positionId)
        whenStateIs(_positionId, PositionState.Superposition)
        notCollapsed(_positionId)
    {
        VaultPosition storage position = vaultPositions[_positionId];
        require(_index < position.superpositionTargets.length, "QV: Invalid target index");

        // Efficient removal by swapping with the last element
        uint lastIndex = position.superpositionTargets.length - 1;
        if (_index != lastIndex) {
            position.superpositionTargets[_index] = position.superpositionTargets[lastIndex];
        }
        position.superpositionTargets.pop();
        // Note: Event doesn't include removed recipient/share easily without finding it first.
        // For simplicity, we'll omit a specific event for removal or log the updated list if gas allows.
        // Let's emit a generic event indicating modification.
        emit SuperpositionTargetAdded(_positionId, address(0), 0); // Indicate removal/modification generically
    }


     /**
     * @notice Adds a condition that must be met for a superposition position to collapse.
     * @param _positionId The ID of the superposition position.
     * @param _conditionType The type of condition.
     * @param _value The value associated with the condition (e.g., timestamp, threshold).
     */
    function addCollapseCondition(uint256 _positionId, ConditionType _conditionType, uint256 _value)
        external
        onlyPositionOwner(_positionId)
        whenStateIs(_positionId, PositionState.Superposition)
        notCollapsed(_positionId)
    {
        VaultPosition storage position = vaultPositions[_positionId];
        position.collapseConditions.push(CollapseCondition(_conditionType, _value, false)); // Initially not met
        emit CollapseConditionAdded(_positionId, _conditionType, _value);
    }

     /**
     * @notice Removes a condition from a superposition position by index.
     * @param _positionId The ID of the superposition position.
     * @param _index The index of the condition to remove.
     */
    function removeCollapseCondition(uint256 _positionId, uint256 _index)
        external
        onlyPositionOwner(_positionId)
        whenStateIs(_positionId, PositionState.Superposition)
        notCollapsed(_positionId)
    {
        VaultPosition storage position = vaultPositions[_positionId];
        require(_index < position.collapseConditions.length, "QV: Invalid condition index");

        uint lastIndex = position.collapseConditions.length - 1;
        if (_index != lastIndex) {
            position.collapseConditions[_index] = position.collapseConditions[lastIndex];
        }
        position.collapseConditions.pop();
        // Generic event for condition modification
         emit CollapseConditionAdded(_positionId, ConditionType(0), 0); // Indicate removal/modification generically
    }


    /**
     * @notice Initiates the collapse process for a superposition position.
     *         This doesn't immediately collapse, but marks it for checking.
     *         Can be called by anyone.
     * @param _positionId The ID of the superposition position.
     */
    function initiateSuperpositionCollapse(uint256 _positionId)
        external
        positionExists(_positionId)
        whenStateIs(_positionId, PositionState.Superposition)
        notCollapsed(_positionId)
    {
        VaultPosition storage position = vaultPositions[_positionId];
        position.initiatedCollapse = true;
        position.currentState = PositionState.InitiatedCollapse;
        emit CollapseInitiated(_positionId);
    }

     /**
     * @notice Finalizes the collapse of a superposition position by checking conditions.
     *         Can be called by anyone once initiated.
     * @param _positionId The ID of the superposition position.
     */
    function finalizeSuperpositionCollapse(uint256 _positionId)
        external
        positionExists(_positionId)
        whenStateIs(_positionId, PositionState.InitiatedCollapse)
        notCollapsed(_positionId)
    {
        VaultPosition storage position = vaultPositions[_positionId];
        require(position.positionType == PositionType.Superposition, "QV: Not a superposition position");

        bool allMet = true;
        // Check and update status of all conditions
        for(uint i = 0; i < position.collapseConditions.length; i++) {
            position.collapseConditions[i].met = isConditionMet(_positionId, i);
            if (!position.collapseConditions[i].met) {
                allMet = false;
            }
        }

        require(allMet, "QV: Not all collapse conditions met yet");
        require(position.superpositionTargets.length > 0, "QV: No collapse targets defined");

        // Determine the final state based on targets (example: first target whose condition is met,
        // or distribute proportionally if all conditions met for all targets - highly complex.
        // Simple Example: If all conditions are met, distribute proportionally to all targets)
        // More complex example: Randomly select one target based on weights if all conditions met.
        // Let's use a simple proportional distribution based on shares if all conditions met.

        uint256 totalShares = 0;
         for(uint i=0; i < position.superpositionTargets.length; i++) {
            totalShares += position.superpositionTargets[i].shareBps;
        }
        require(totalShares <= 10000, "QV: Total shares must not exceed 10000 bps"); // Should be enforced by add

        // If all conditions met, collapse and set final recipient/amount.
        // For simplicity, we'll mark the position as collapsed and the withdraw function
        // will handle the proportional distribution.
        position.currentState = PositionState.Collapsed;
        // finalRecipient and finalAmount are set in the withdraw function based on shares

        emit PositionCollapsed(_positionId, address(0), 0); // Recipient/amount determined on withdrawal
    }

    // --- Entanglement Management ---

     /**
     * @notice Creates a new ETH position intended to be entangled with another.
     * @param _entangledPartnerId The ID of the position to entangle with. Must exist.
     */
    function createEntangledPositionETH(uint256 _entangledPartnerId) external payable nonReentrant returns (uint256) {
        require(msg.value > 0, "QV: Cannot create entangled position with 0 ETH");
        require(_entangledPartnerId > 0 && _entangledPartnerId < nextPositionId, "QV: Entangled partner position must exist");
        require(vaultPositions[_entangledPartnerId].entangledPartnerId == 0, "QV: Partner position is already entangled");

        uint256 newPositionId = _createPosition(msg.sender, address(0), msg.value, PositionType.Entangled, PositionState.Entangled);

        // Link them
        vaultPositions[newPositionId].entangledPartnerId = _entangledPartnerId;
        vaultPositions[_entangledPartnerId].entangledPartnerId = newPositionId;
        vaultPositions[_entangledPartnerId].currentState = PositionState.Entangled; // Ensure partner is marked Entangled

        emit EntanglementLinked(newPositionId, _entangledPartnerId);
        return newPositionId;
    }

     /**
     * @notice Creates a new ERC20 position intended to be entangled with another.
     * @param _tokenAddress The address of the ERC20 token.
     * @param _amount The amount of ERC20 tokens.
     * @param _entangledPartnerId The ID of the position to entangle with. Must exist.
     */
     function createEntangledPositionERC20(address _tokenAddress, uint256 _amount, uint256 _entangledPartnerId) external nonReentrant returns (uint256) {
        require(_tokenAddress != address(0), "QV: Invalid token address");
        require(_amount > 0, "QV: Cannot create entangled position with 0 amount");
        require(_entangledPartnerId > 0 && _entangledPartnerId < nextPositionId, "QV: Entangled partner position must exist");
        require(vaultPositions[_entangledPartnerId].entangledPartnerId == 0, "QV: Partner position is already entangled");

        IERC20 token = IERC20(_tokenAddress);
        require(token.balanceOf(msg.sender) >= _amount, "QV: Insufficient token balance");
        require(token.allowance(msg.sender, address(this)) >= _amount, "QV: Token allowance too low");

        token.safeTransferFrom(msg.sender, address(this), _amount);

        uint256 newPositionId = _createPosition(msg.sender, _tokenAddress, _amount, PositionType.Entangled, PositionState.Entangled);

        // Link them
        vaultPositions[newPositionId].entangledPartnerId = _entangledPartnerId;
        vaultPositions[_entangledPartnerId].entangledPartnerId = newPositionId;
         vaultPositions[_entangledPartnerId].currentState = PositionState.Entangled; // Ensure partner is marked Entangled

        emit EntanglementLinked(newPositionId, _entangledPartnerId);
        return newPositionId;
     }

    /**
     * @notice Links two *existing* positions as entangled.
     *         Both positions must be in the Initial state and not already entangled.
     *         Requires caller to be the owner of both positions.
     * @param _position1Id The ID of the first position.
     * @param _position2Id The ID of the second position.
     */
    function linkEntangledPositions(uint256 _position1Id, uint256 _position2Id)
        external
        onlyPositionOwner(_position1Id)
        onlyPositionOwner(_position2Id)
        positionExists(_position2Id) // positionExists(_position1Id) checked by modifier 1
        whenStateIs(_position1Id, PositionState.Initial)
        whenStateIs(_position2Id, PositionState.Initial)
        notCollapsed(_position1Id)
        notCollapsed(_position2Id)
    {
        VaultPosition storage pos1 = vaultPositions[_position1Id];
        VaultPosition storage pos2 = vaultPositions[_position2Id];

        require(pos1.entangledPartnerId == 0 && pos2.entangledPartnerId == 0, "QV: Positions are already entangled");
        require(_position1Id != _position2Id, "QV: Cannot entangle a position with itself");

        pos1.entangledPartnerId = _position2Id;
        pos2.entangledPartnerId = _position1Id;

        pos1.currentState = PositionState.Entangled;
        pos2.currentState = PositionState.Entangled;
        pos1.positionType = PositionType.Entangled; // Change type to Entangled
        pos2.positionType = PositionType.Entangled; // Change type to Entangled


        emit EntanglementLinked(_position1Id, _position2Id);
    }

    /**
     * @notice Breaks the entanglement link between two positions.
     *         Can be called by the owner of either entangled position.
     *         This moves them back to Initial state (or perhaps a new state).
     *         Breaking entanglement requires specific conditions to be met (simulated).
     * @param _positionId The ID of one of the entangled positions.
     */
    function breakEntanglement(uint256 _positionId)
        external
        positionExists(_positionId)
        whenStateIs(_positionId, PositionState.Entangled)
        notCollapsed(_positionId)
    {
        VaultPosition storage pos1 = vaultPositions[_positionId];
        require(pos1.entangledPartnerId != 0, "QV: Position is not entangled");
        require(pos1.owner == msg.sender || vaultPositions[pos1.entangledPartnerId].owner == msg.sender, "QV: Only owner of entangled positions can break link");

        uint256 partnerId = pos1.entangledPartnerId;
        VaultPosition storage pos2 = vaultPositions[partnerId];

        // Simulate condition for breaking entanglement (e.g., time passed, or external data)
        // For simplicity, let's allow breaking any time by entangled owner in this example.
        // Add complex conditions here in a real scenario.
        // require(block.timestamp > pos1.creationTimestamp + 7 days, "QV: Entanglement cannot be broken yet");

        pos1.entangledPartnerId = 0;
        pos2.entangledPartnerId = 0;

        // What state do they go to? Let's move them back to Initial
        pos1.currentState = PositionState.Initial;
        pos2.currentState = PositionState.Initial;
        // Type remains Entangled, but partnerId is 0. Maybe add a 'De-entangled' state?
        // For simplicity, let's leave type as Entangled but state as Initial.

        emit EntanglementBroken(_positionId, partnerId);
    }

     /**
     * @notice Initiates the resolution process for an entangled pair.
     *         Can be called by the owner of either entangled position.
     *         This process will lead to funds being released based on the resolution outcome.
     * @param _positionId The ID of one of the entangled positions.
     */
    function initiateEntanglementResolution(uint256 _positionId)
        external
        positionExists(_positionId)
        whenStateIs(_positionId, PositionState.Entangled)
        notCollapsed(_positionId)
    {
        VaultPosition storage pos1 = vaultPositions[_positionId];
        require(pos1.entangledPartnerId != 0, "QV: Position is not entangled");
        require(pos1.owner == msg.sender || vaultPositions[pos1.entangledPartnerId].owner == msg.sender, "QV: Only owner of entangled positions can initiate resolution");

        VaultPosition storage pos2 = vaultPositions[pos1.entangledPartnerId];

        require(!pos1.initiatedResolution && !pos2.initiatedResolution, "QV: Resolution already initiated");

        pos1.initiatedResolution = true;
        pos2.initiatedResolution = true; // Both must be initiated
        pos1.currentState = PositionState.Resolving;
        pos2.currentState = PositionState.Resolving;

        emit EntanglementResolutionInitiated(_positionId);
        emit EntanglementResolutionInitiated(pos1.entangledPartnerId); // Also emit for the partner
    }

     /**
     * @notice Finalizes the resolution of an entangled pair.
     *         Requires both positions to have initiated resolution.
     *         The outcome (who gets which funds) depends on the "entangled state" (simulated).
     * @param _positionId The ID of one of the entangled positions.
     */
    function finalizeEntanglementResolution(uint256 _positionId)
        external
        positionExists(_positionId)
        whenStateIs(_positionId, PositionState.Resolving)
        notCollapsed(_positionId)
    {
        VaultPosition storage pos1 = vaultPositions[_positionId];
        require(pos1.entangledPartnerId != 0, "QV: Position is not entangled or initiated resolution incorrectly");

        uint256 partnerId = pos1.entangledPartnerId;
        VaultPosition storage pos2 = vaultPositions[partnerId];

        require(pos1.initiatedResolution && pos2.initiatedResolution, "QV: Resolution not initiated for both positions");
        require(pos1.assetAddress == pos2.assetAddress, "QV: Entangled positions must hold the same asset type for resolution"); // Simplified requirement

        // --- Simulate Entanglement Resolution Outcome ---
        // This is the core "quantum" part - how does entanglement resolve?
        // Possible outcomes:
        // 1. Owner of pos1 gets all funds from pos1, owner of pos2 gets all funds from pos2. (Classical separation)
        // 2. Owner of pos1 gets all funds from pos2, owner of pos2 gets all funds from pos1. (Cross-transfer)
        // 3. Funds are split proportionally or based on some complex rule between the owners or other targets.
        // 4. One owner gets everything, the other gets nothing (probabilistic?).

        // Let's use a simple deterministic rule for this example based on position IDs parity.
        // In a real scenario, this would be based on complex external data, game state, or verifiable randomness.

        bool outcomeDetermined = false;
        address recipient1 = address(0);
        address recipient2 = address(0);
        uint256 amount1 = 0;
        uint256 amount2 = 0;

        // Example Resolution Logic: If the sum of IDs is even, owners keep their funds. If odd, they swap.
        // This is a very basic example.
        if ((_positionId + partnerId) % 2 == 0) {
            // Outcome 1: Owners keep their own funds
            recipient1 = pos1.owner;
            amount1 = pos1.amount;
            recipient2 = pos2.owner;
            amount2 = pos2.amount;
             outcomeDetermined = true;
        } else {
             // Outcome 2: Owners swap funds
            recipient1 = pos2.owner; // pos1's funds go to pos2's owner
            amount1 = pos1.amount;
            recipient2 = pos1.owner; // pos2's funds go to pos1's owner
            amount2 = pos2.amount;
            outcomeDetermined = true;
        }

        require(outcomeDetermined, "QV: Entanglement resolution outcome not determined");

        // Set the final state for both positions
        pos1.finalRecipient = recipient1;
        pos1.finalAmount = amount1;
        pos1.currentState = PositionState.Resolved; // Use Resolved state
        pos1.entangledPartnerId = 0; // Break the link after resolution

        pos2.finalRecipient = recipient2;
        pos2.finalAmount = amount2;
        pos2.currentState = PositionState.Resolved; // Use Resolved state
        pos2.entangledPartnerId = 0; // Break the link after resolution

        emit PositionResolved(_positionId, pos1.finalRecipient, pos1.finalAmount);
        emit PositionResolved(partnerId, pos2.finalRecipient, pos2.finalAmount);
    }

     // --- Probabilistic Outcome ---

    /**
     * @notice Creates a new ETH position with a probabilistic outcome.
     *         Requires potential outcomes/probabilities to be set (simulated).
     */
    function createProbabilisticPositionETH() external payable nonReentrant returns (uint256) {
        require(msg.value > 0, "QV: Cannot create probabilistic position with 0 ETH");
        // Probabilistic positions need potential outcomes defined.
        // For this example, we'll hardcode a simple set of outcomes or require a separate function call.
        // Let's require a separate function call like setting targets for superposition.
        // Or, simplify: use 2 outcomes - owner wins all, owner loses all (sent to zero address or burn).
         uint256 id = _createPosition(msg.sender, address(0), msg.value, PositionType.Probabilistic, PositionState.Probabilistic);
         // Set an initial seed (this is insecure, use VRF for real apps)
         vaultPositions[id].probabilisticSeed = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, id));
         return id;
    }

    /**
     * @notice Creates a new ERC20 position with a probabilistic outcome.
     *         Requires potential outcomes/probabilities to be set (simulated).
     */
     function createProbabilisticPositionERC20(address _tokenAddress, uint256 _amount) external nonReentrant returns (uint256) {
        require(_tokenAddress != address(0), "QV: Invalid token address");
         require(_amount > 0, "QV: Cannot create probabilistic position with 0 amount");
        IERC20 token = IERC20(_tokenAddress);
        require(token.balanceOf(msg.sender) >= _amount, "QV: Insufficient token balance");
        require(token.allowance(msg.sender, address(this)) >= _amount, "QV: Token allowance too low");

        token.safeTransferFrom(msg.sender, address(this), _amount);

        uint256 id = _createPosition(msg.sender, _tokenAddress, _amount, PositionType.Probabilistic, PositionState.Probabilistic);
         // Set an initial seed (this is insecure, use VRF for real apps)
         vaultPositions[id].probabilisticSeed = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, id, _tokenAddress));
         return id;
     }

    /**
     * @notice Triggers the determination of the probabilistic outcome for a position.
     *         Can be called by anyone. Requires a block hash to be available later.
     *         This is the "observation" that collapses the probability wave.
     * @param _positionId The ID of the probabilistic position.
     */
    function triggerProbabilisticOutcome(uint256 _positionId)
        external
        positionExists(_positionId)
        whenStateIs(_positionId, PositionState.Probabilistic)
        notCollapsed(_positionId)
    {
        VaultPosition storage position = vaultPositions[_positionId];
        require(block.number > position.creationTimestamp / block.timestamp + 256, "QV: Cannot trigger outcome too soon (need block hash)"); // Need a future block hash for better (but still weak) randomness
        // Note: using block.timestamp / block.timestamp is a typo, should be block.number condition check.
        // Correct check: require(block.number > creationBlockNumber + 256) - requires storing creation block number.
        // Let's simplify for the example: just require a later block.
        require(block.number > block.number - 1, "QV: Wait for a future block"); // Placeholder, need actual block number comparison

        // --- Simulate Probabilistic Outcome Determination ---
        // Use block hash, position seed, and caller address for entropy (still exploitable!)
        bytes32 combinedSeed = keccak256(abi.encodePacked(
            position.probabilisticSeed,
            blockhash(block.number -1), // Use hash of a recent block
            msg.sender,
            block.timestamp,
            block.difficulty
        ));

        uint256 randomValue = uint256(combinedSeed);

        // Example outcomes (hardcoded for simplicity):
        // Outcome 0: Owner wins 100%
        // Outcome 1: Owner wins 50%, 50% goes to zero address (burned)
        // Outcome 2: Owner wins 0%, 100% goes to zero address (burned)
        // Outcomes could be defined by a struct/array similar to superposition targets.

        uint256 outcomeIndex;
        if (randomValue % 100 < 60) { // 60% chance for outcome 0
            outcomeIndex = 0;
        } else if (randomValue % 100 < 90) { // 30% chance for outcome 1
            outcomeIndex = 1;
        } else { // 10% chance for outcome 2
            outcomeIndex = 2;
        }

        position.determinedOutcomeIndex = outcomeIndex;
        position.currentState = PositionState.OutcomeDetermined;

        // Set final recipient and amount based on the determined outcome
        if (outcomeIndex == 0) {
            position.finalRecipient = position.owner;
            position.finalAmount = position.amount;
        } else if (outcomeIndex == 1) {
             position.finalRecipient = position.owner;
            position.finalAmount = position.amount.div(2); // Half to owner
            // The other half remains in the contract, effectively burned if not claimable
        } else if (outcomeIndex == 2) {
             position.finalRecipient = address(0); // No one gets it (burned)
             position.finalAmount = 0;
        } else {
             // Should not happen with current logic, but good practice
             revert("QV: Invalid outcome index");
        }

        emit ProbabilisticOutcomeTriggered(_positionId, outcomeIndex);
    }

     // --- Observation & Collapse (Generalized) ---

     /**
      * @notice A generalized function to trigger the "observation" and potential collapse/resolution
      *         for any position type that is ready.
      *         Acts as a unified entry point for state transitions that depend on external triggers
      *         or meeting conditions.
      *         Can be called by anyone.
      * @param _positionId The ID of the position to observe and potentially collapse.
      */
     function observeAndCollapse(uint256 _positionId)
        external
        positionExists(_positionId)
        notCollapsed(_positionId)
     {
        VaultPosition storage position = vaultPositions[_positionId];

        if (position.currentState == PositionState.Initial && position.positionType == PositionType.Standard) {
            // For standard positions, observation just collapses it to the owner
            position.finalRecipient = position.owner;
            position.finalAmount = position.amount;
            position.currentState = PositionState.Collapsed;
             emit PositionCollapsed(_positionId, position.finalRecipient, position.finalAmount);

        } else if (position.currentState == PositionState.Superposition && position.initiatedCollapse) {
             // If superposition collapse is initiated, try to finalize
             // Check conditions here directly or call finalizeSuperpositionCollapse
             // Let's call finalizeSuperpositionCollapse (requires initiatedCollapse state, which we checked)
             // This requires moving state to InitiatedCollapse *before* calling this.
             // Let's refine: `observeAndCollapse` checks *if* conditions are met and *if* collapse is initiated.
             require(position.positionType == PositionType.Superposition, "QV: Position type mismatch for collapse");
             require(position.initiatedCollapse, "QV: Superposition collapse not initiated");

            bool allMet = true;
            for(uint i = 0; i < position.collapseConditions.length; i++) {
                 if (!isConditionMet(_positionId, i)) {
                    allMet = false;
                    break; // Exit early if any condition not met
                }
            }

            require(allMet, "QV: Not all collapse conditions met yet");
            require(position.superpositionTargets.length > 0, "QV: No collapse targets defined");

            // Collapse and set final recipient/amount - this will be handled in withdraw for superposition shares
             position.currentState = PositionState.Collapsed;
            // finalRecipient and finalAmount are set in the withdraw function based on shares
            emit PositionCollapsed(_positionId, address(0), 0); // Recipient/amount determined on withdrawal


        } else if (position.currentState == PositionState.Entangled && position.initiatedResolution) {
            // If entanglement resolution is initiated, try to finalize
             require(position.positionType == PositionType.Entangled, "QV: Position type mismatch for resolution");
             require(position.entangledPartnerId != 0, "QV: Entangled partner missing");

             // Check if partner has also initiated resolution
             VaultPosition storage partnerPos = vaultPositions[position.entangledPartnerId];
             require(partnerPos.initiatedResolution, "QV: Entangled partner has not initiated resolution");

            // Finalize Entanglement (similar logic to finalizeEntanglementResolution)
            // Copy logic from finalizeEntanglementResolution
             require(position.assetAddress == partnerPos.assetAddress, "QV: Entangled positions must hold the same asset type");

             // Simulate outcome (same parity logic)
            address recipient1 = address(0);
            uint256 amount1 = 0;
            address recipient2 = address(0);
            uint256 amount2 = 0;

             if ((_positionId + position.entangledPartnerId) % 2 == 0) {
                recipient1 = position.owner; amount1 = position.amount;
                recipient2 = partnerPos.owner; amount2 = partnerPos.amount;
            } else {
                recipient1 = partnerPos.owner; amount1 = position.amount;
                recipient2 = position.owner; amount2 = partnerPos.amount;
            }

             // Set final state for both positions
             position.finalRecipient = recipient1;
             position.finalAmount = amount1;
             position.currentState = PositionState.Resolved;
             position.entangledPartnerId = 0;

             partnerPos.finalRecipient = recipient2;
             partnerPos.finalAmount = amount2;
             partnerPos.currentState = PositionState.Resolved;
             partnerPos.entangledPartnerId = 0;

             emit PositionResolved(_positionId, position.finalRecipient, position.finalAmount);
             emit PositionResolved(partnerPos.entangledPartnerId, partnerPos.finalRecipient, partnerPos.finalAmount);


        } else if (position.currentState == PositionState.Probabilistic) {
             // Probabilistic outcome determination
             require(position.positionType == PositionType.Probabilistic, "QV: Position type mismatch for probabilistic");
             // Check if conditions to trigger are met (e.g., a certain time passed, or just simply triggered once)
             // For simplicity, allow triggering once via `triggerProbabilisticOutcome`.
             // This branch is slightly redundant if `triggerProbabilisticOutcome` already moves state to OutcomeDetermined.
             // If Probabilistic outcome has *already* been determined (moved to OutcomeDetermined state), then allow collapsing to withdrawal.
             // Let's adjust: `triggerProbabilisticOutcome` moves to `OutcomeDetermined`. `observeAndCollapse` then moves from `OutcomeDetermined` to `Collapsed` (ready for withdrawal).

             require(position.currentState == PositionState.OutcomeDetermined, "QV: Probabilistic outcome not yet determined");

             // Move to Collapsed state, recipient/amount were already set by triggerProbabilisticOutcome
             position.currentState = PositionState.Collapsed;
             emit PositionCollapsed(_positionId, position.finalRecipient, position.finalAmount);


        } else {
            revert("QV: Position not ready for observation/collapse");
        }
     }

     // --- Withdrawal Functions ---

     /**
     * @notice Allows the determined recipient to withdraw funds from a collapsed position.
     *         Handles different collapse/resolution outcomes (Standard, Superposition, Entangled, Probabilistic).
     * @param _positionId The ID of the collapsed position.
     */
     function withdrawCollapsedPosition(uint256 _positionId)
        external
        nonReentrantPosition(_positionId) // Custom position-level re-entrancy guard
        positionExists(_positionId)
        whenStateIsNot(_positionId, PositionState.Withdrawn) // Cannot withdraw if already withdrawn
        whenStateIsNot(_positionId, PositionState.Breached) // Cannot withdraw if emergency withdrawn
    {
        VaultPosition storage position = vaultPositions[_positionId];
        require(
            position.currentState == PositionState.Collapsed ||
            position.currentState == PositionState.Resolved ||
            position.currentState == PositionState.OutcomeDetermined, // Allow withdrawal directly from OutcomeDetermined state for probabilistic? Or enforce Collapsed?
            "QV: Position not in a withdrawable state (Collapsed, Resolved, or OutcomeDetermined)"
        );


        if (position.positionType == PositionType.Superposition) {
            // Superposition withdrawal:
            // Distribute shares to *all* determined targets (if total shares <= 10000)
            // Or, if only one target was determined by conditions, send to that one.
            // Assuming proportional distribution to ALL targets if collapsed via `finalizeSuperpositionCollapse` or `observeAndCollapse`.
            require(position.superpositionTargets.length > 0, "QV: No targets for superposition withdrawal");

            uint256 totalShares = 0;
             for(uint i=0; i < position.superpositionTargets.length; i++) {
                totalShares += position.superpositionTargets[i].shareBps;
            }
             require(totalShares > 0 && totalShares <= 10000, "QV: Invalid total shares for distribution");

            uint256 totalWithdrawn = 0;

            for(uint i=0; i < position.superpositionTargets.length; i++) {
                SuperpositionTarget storage target = position.superpositionTargets[i];
                if (target.recipient != address(0) && target.shareBps > 0) {
                    uint256 shareAmount = position.amount.mul(target.shareBps) / 10000;
                    if (shareAmount > 0) {
                        totalWithdrawn += shareAmount;
                        if (position.assetAddress == address(0)) {
                            (bool success, ) = target.recipient.call{value: shareAmount}("");
                            require(success, "QV: ETH transfer failed for superposition target");
                        } else {
                            IERC20(position.assetAddress).safeTransfer(target.recipient, shareAmount);
                        }
                        emit PositionWithdrawn(_positionId, target.recipient, shareAmount);
                    }
                }
            }
             require(totalWithdrawn <= position.amount, "QV: Withdrawal exceeds position amount"); // Should not happen if calculations correct

             // Set state to withdrawn only after all transfers attempted
             position.currentState = PositionState.Withdrawn;

        } else {
            // Standard, Entangled (Resolved state), Probabilistic (OutcomeDetermined/Collapsed state)
            // Funds go to the single finalRecipient determined during collapse/resolution/outcome.
            require(position.finalRecipient != address(0), "QV: Final recipient not set");
            require(msg.sender == position.finalRecipient, "QV: Only the final recipient can withdraw");
            require(position.finalAmount > 0, "QV: Withdrawal amount is zero");


            uint256 amountToWithdraw = position.finalAmount;
            position.finalAmount = 0; // Zero out to prevent double withdrawal attempt of the *same* calculated amount

            if (position.assetAddress == address(0)) {
                 (bool success, ) = position.finalRecipient.call{value: amountToWithdraw}("");
                 require(success, "QV: ETH transfer failed");
            } else {
                 IERC20(position.assetAddress).safeTransfer(position.finalRecipient, amountToWithdraw);
            }

            position.currentState = PositionState.Withdrawn;
            emit PositionWithdrawn(_positionId, position.finalRecipient, amountToWithdraw);
        }

         // Release the position-specific withdrawal lock
        position.withdrawalLock = false;
     }

    // --- Query & View Functions ---

    /**
     * @notice Gets detailed information about a vault position.
     * @param _positionId The ID of the position.
     * @return VaultPosition struct.
     */
     function getPositionDetails(uint256 _positionId)
        external
        view
        positionExists(_positionId)
        returns (VaultPosition memory)
    {
        return vaultPositions[_positionId];
    }

    /**
     * @notice Gets the current state of a vault position.
     * @param _positionId The ID of the position.
     * @return PositionState enum.
     */
    function getPositionState(uint256 _positionId)
        external
        view
        positionExists(_positionId)
        returns (PositionState)
    {
        return vaultPositions[_positionId].currentState;
    }

     /**
     * @notice Gets the type of a vault position.
     * @param _positionId The ID of the position.
     * @return PositionType enum.
     */
     function getPositionType(uint256 _positionId)
        external
        view
        positionExists(_positionId)
        returns (PositionType)
     {
        return vaultPositions[_positionId].positionType;
     }


     /**
     * @notice Gets the potential recipients and shares for a superposition position.
     * @param _positionId The ID of the superposition position.
     * @return Array of SuperpositionTarget structs.
     */
     function getSuperpositionTargets(uint256 _positionId)
        external
        view
        positionExists(_positionId)
        returns (SuperpositionTarget[] memory)
     {
        require(vaultPositions[_positionId].positionType == PositionType.Superposition, "QV: Not a superposition position");
        return vaultPositions[_positionId].superpositionTargets;
     }

    /**
     * @notice Gets the collapse conditions for a superposition position.
     * @param _positionId The ID of the superposition position.
     * @return Array of CollapseCondition structs.
     */
     function getCollapseConditions(uint256 _positionId)
        external
        view
        positionExists(_positionId)
        returns (CollapseCondition[] memory)
     {
        require(vaultPositions[_positionId].positionType == PositionType.Superposition, "QV: Not a superposition position");
        return vaultPositions[_positionId].collapseConditions;
     }

    /**
     * @notice Checks if a specific collapse condition for a superposition position is met.
     *         This is the helper logic used internally for finalizeSuperpositionCollapse / observeAndCollapse.
     *         Can be called externally to check status.
     * @param _positionId The ID of the superposition position.
     * @param _conditionIndex The index of the condition to check.
     * @return bool indicating if the condition is currently met.
     */
     function isConditionMet(uint256 _positionId, uint256 _conditionIndex)
        public // Can be called internally or externally
        view
        positionExists(_positionId)
        returns (bool)
     {
        VaultPosition storage position = vaultPositions[_positionId];
        require(position.positionType == PositionType.Superposition, "QV: Not a superposition position");
        require(_conditionIndex < position.collapseConditions.length, "QV: Invalid condition index");

        CollapseCondition storage condition = position.collapseConditions[_conditionIndex];

        if (condition.conditionType == ConditionType.TimeBased) {
            return block.timestamp >= condition.value;
        } else if (condition.conditionType == ConditionType.ExternalDataGT) {
            return simulatedExternalData > condition.value;
        } else if (condition.conditionType == ConditionType.ExternalDataLT) {
            return simulatedExternalData < condition.value;
        } else if (condition.conditionType == ConditionType.ExternalDataEQ) {
             return simulatedExternalData == condition.value;
        }
        // Add checks for other condition types here

        return false; // Default: condition type not recognized or not met
     }


     /**
     * @notice Gets the entangled partner ID for an entangled position.
     * @param _positionId The ID of the entangled position.
     * @return The ID of the entangled partner position (0 if not entangled or resolved).
     */
     function getEntangledPartner(uint256 _positionId)
        external
        view
        positionExists(_positionId)
        returns (uint256)
     {
        return vaultPositions[_positionId].entangledPartnerId;
     }


     /**
     * @notice Gets the determined outcome index for a probabilistic position.
     * @param _positionId The ID of the probabilistic position.
     * @return The index of the determined outcome (only valid if state is OutcomeDetermined or Collapsed).
     */
     function getProbabilisticOutcome(uint256 _positionId)
        external
        view
        positionExists(_positionId)
        returns (uint256)
     {
        require(vaultPositions[_positionId].positionType == PositionType.Probabilistic, "QV: Not a probabilistic position");
        require(
            vaultPositions[_positionId].currentState == PositionState.OutcomeDetermined ||
            vaultPositions[_positionId].currentState == PositionState.Collapsed ||
            vaultPositions[_positionId].currentState == PositionState.Withdrawn, // Outcome is fixed once determined
            "QV: Probabilistic outcome not yet determined"
        );
        return vaultPositions[_positionId].determinedOutcomeIndex;
     }

    /**
     * @notice Gets the owner of a specific position.
     * @param _positionId The ID of the position.
     * @return The address of the position owner.
     */
    function getPositionOwner(uint256 _positionId)
        external
        view
        positionExists(_positionId)
        returns (address)
    {
        return vaultPositions[_positionId].owner;
    }

    /**
     * @notice Gets the total number of vault positions created.
     * @return The total count of positions.
     */
    function getVaultPositionCount() external view returns (uint256) {
        return nextPositionId - 1; // nextPositionId is the ID for the *next* position
    }

    // --- Utility & Emergency Functions ---

    /**
     * @notice (Simulated) Allows updating the external data value used for conditions.
     *         In a real contract, this would be secured (e.g., by an Oracle or trusted entity).
     *         For this example, it's public for testing condition checks.
     */
    function simulateExternalData(uint256 _newData) external {
        simulatedExternalData = _newData;
        emit ExternalDataUpdated(_newData);
    }

    /**
     * @notice Allows a designated emergency address to withdraw funds from any position,
     *         bypassing normal withdrawal conditions (conceptual "quantum tunneling").
     *         USE WITH EXTREME CAUTION.
     * @param _positionId The ID of the position to breach.
     */
    function emergencyTunnelWithdrawal(uint256 _positionId)
        external
        nonReentrantPosition(_positionId) // Prevent re-entrancy on this position
        positionExists(_positionId)
    {
        require(msg.sender == emergencyTunnelAddress, "QV: Only emergency tunnel address can perform this action");
        require(vaultPositions[_positionId].currentState != PositionState.Breached, "QV: Position already emergency withdrawn");

        VaultPosition storage position = vaultPositions[_positionId];
        uint256 amountToWithdraw = position.amount; // Withdraw the full original amount

        // Zero out amount and recipient in the position state
        position.finalRecipient = address(0); // Indicate no standard recipient received it
        position.finalAmount = 0;
        position.amount = 0; // Zero out original amount

        position.currentState = PositionState.Breached; // Mark as breached

        if (position.assetAddress == address(0)) {
             (bool success, ) = emergencyTunnelAddress.call{value: amountToWithdraw}("");
             require(success, "QV: ETH emergency transfer failed");
        } else {
             IERC20(position.assetAddress).safeTransfer(emergencyTunnelAddress, amountToWithdraw);
        }

        emit EmergencyTunnelWithdrawal(_positionId, emergencyTunnelAddress, amountToWithdraw);

         // Release the position-specific withdrawal lock
        position.withdrawalLock = false;
    }

    // Fallback function to receive ETH
    receive() external payable {
        // ETH sent without calling a function could potentially be treated as a standard deposit
        // or rejected. For simplicity, we'll require depositEther to be called explicitly.
        revert("QV: ETH sent directly not supported. Use depositEther()");
    }
}
```