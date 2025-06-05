Okay, let's design a smart contract concept around advanced, unique storage and conditional release of multi-asset types, using abstract concepts like "entanglement," "superposition," and "observation" inspired by quantum mechanics, but implemented with deterministic blockchain logic. We'll call it the `QuantumVault`.

It will handle ERC20, ERC721, and ERC1155 tokens and link their release conditions to complex, interconnected "Entanglement States." The act of initiating a claim ("Observation") will lock the asset to a specific state pathway, collapsing its "Superposition" of potential claim conditions.

---

**QuantumVault Smart Contract Outline**

1.  **Concept:** A multi-asset vault (ERC20, ERC721, ERC1155) where deposited assets (positions) are linked to complex, user-defined conditional states ("Entanglement States"). Release requires meeting *one* linked state's conditions and initiating an "Observation" process, which finalizes the claim path ("Superposition Collapse"). Includes features like conditional "Quantum Jumps" between states and a potential "Decay" mechanism for unmanaged assets.
2.  **Key Features:**
    *   Multi-Asset Support (ERC20, ERC721, ERC1155).
    *   Vault Positions: Represents a specific deposit of assets.
    *   Entanglement States: Define complex release conditions (time-based, external data-based, inter-asset dependent, multi-party).
    *   Linking: Associate Vault Positions with multiple Entanglement States (Superposition).
    *   Observation: Initiating a claim by selecting *one* met state, collapsing the superposition and locking the claim pathway.
    *   Quantum Jump: A mechanism to conditionally change linked states for a position.
    *   Decay: Optional mechanism to penalize or reduce assets in unmanaged positions over time.
    *   Admin/Owner Control: Management of contract parameters.
3.  **Core Structures:**
    *   `EntanglementState`: Defines release conditions and type.
    *   `VaultPosition`: Defines a specific deposited asset amount/ID and linked states.
4.  **Enums:**
    *   `AssetType`: ERC20, ERC721, ERC1155.
    *   `EntanglementStateType`: TimeLock, ExternalCondition, InterAssetCondition, MultiSigCondition, QuantumJumpCondition.
    *   `PositionState`: Deposited, Observed, Claimed, Cancelled, Decayed.
5.  **Interfaces:**
    *   `IERC20`, `IERC721`, `IERC1155` (from OpenZeppelin).
    *   `IERC721Receiver`, `IERC1155Receiver` (from OpenZeppelin).
6.  **Inheritance:**
    *   `ERC721Holder`, `ERC1155Holder` (from OpenZeppelin to receive NFTs).
    *   `Ownable` (from OpenZeppelin for admin).
7.  **Events:**
    *   `DepositMade`, `EntanglementStateCreated`, `StateLinked`, `StateUnlinked`, `PositionObserved`, `WithdrawalExecuted`, `DecayApplied`, `QuantumJumpExecuted`, `PositionCancelled`, `AdminAdded`, `AdminRemoved`.
8.  **State Variables:**
    *   Mappings for positions, states, user positions/states.
    *   Counters for position/state IDs.
    *   Decay parameters.
    *   Admin addresses.
    *   External oracle addresses/interfaces (if using `ExternalCondition`).
9.  **Function Summary (20+ functions):**
    *   `constructor`: Initialize owner, decay settings.
    *   `onERC721Received`, `onERC1155Received`, `onERC1155BatchReceived`: Standard receivers for NFT deposits.
    *   `depositERC20`: Deposit ERC20, create position, optional initial state link.
    *   `depositERC721`: Deposit ERC721, create position, optional initial state link.
    *   `depositERC1155`: Deposit ERC1155, create position, optional initial state link.
    *   `createEntanglementState`: Define and store a new state with conditions.
    *   `linkStateToPosition`: Associate an existing state with a position (adds to superposition).
    *   `unlinkStateFromPosition`: Remove an association (if state type allows).
    *   `checkEntanglementStateStatus`: Internal/view helper to check if a single state's conditions are met.
    *   `checkPositionClaimableStates`: View function to find which linked states for a position are currently met.
    *   `observePosition`: Attempt to initiate withdrawal for a position by selecting *one* met linked state. Changes position state from `Deposited` to `Observed`.
    *   `executeWithdrawal`: Finalize withdrawal for an `Observed` position if the chosen state remains met. Sends assets. Changes position state to `Claimed`.
    *   `getVaultPosition`: View details of a position.
    *   `getEntanglementState`: View details of a state.
    *   `getUserPositions`: Get list of position IDs for a user.
    *   `getUserStates`: Get list of state IDs created by a user.
    *   `triggerDecay`: Callable function to apply decay logic to eligible positions.
    *   `calculateDecayAmount`: View helper for decay calculation.
    *   `proposeQuantumJump`: Propose a change in linked states for a position based on specific `QuantumJumpCondition` state type.
    *   `executeQuantumJump`: Finalize a proposed quantum jump if conditions met.
    *   `cancelPosition`: Owner or user can cancel a position (potentially with penalty or partial loss).
    *   `updateEntanglementState`: Allow updating state parameters (if state type permits mutability).
    *   `setDecayParameters`: Admin function to configure decay.
    *   `addAdmin`: Owner function.
    *   `removeAdmin`: Owner function.
    *   `renounceOwnership`: Standard Ownable function.
    *   `transferOwnership`: Standard Ownable function.
    *   `supportsInterface`: ERC165 compliance.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC165/ERC165.sol";
import "@openzeppelin/contracts/token/ERC165/IERC165.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- QuantumVault Smart Contract ---
//
// Concept: A multi-asset vault (ERC20, ERC721, ERC1155) where deposited assets
// (positions) are linked to complex, user-defined conditional states
// ("Entanglement States"). Release requires meeting *one* linked state's conditions
// and initiating an "Observation" process, which finalizes the claim path
// ("Superposition Collapse"). Includes features like conditional "Quantum Jumps"
// between states and a potential "Decay" mechanism for unmanaged assets.
//
// Key Features:
// - Multi-Asset Support (ERC20, ERC721, ERC1155).
// - Vault Positions: Represents a specific deposit of assets.
// - Entanglement States: Define complex release conditions (time-based,
//   external data-based, inter-asset dependent, multi-party).
// - Linking: Associate Vault Positions with multiple Entanglement States (Superposition).
// - Observation: Initiating a claim by selecting *one* met state, collapsing
//   the superposition and locking the claim pathway.
// - Quantum Jump: A mechanism to conditionally change linked states for a position.
// - Decay: Optional mechanism to penalize or reduce assets in unmanaged positions over time.
// - Admin/Owner Control: Management of contract parameters.
//
// Function Summary:
// constructor: Initializes owner, decay settings.
// onERC721Received, onERC1155Received, onERC1155BatchReceived: Standard receivers for NFT deposits.
// depositERC20: Deposit ERC20, create position, optional initial state link.
// depositERC721: Deposit ERC721, create position, optional initial state link.
// depositERC1155: Deposit ERC1155, create position, optional initial state link.
// createEntanglementState: Define and store a new state with conditions.
// linkStateToPosition: Associate an existing state with a position (adds to superposition).
// unlinkStateFromPosition: Remove an association (if state type allows).
// checkEntanglementStateStatus: Internal/view helper to check if a single state's conditions are met.
// checkPositionClaimableStates: View function to find which linked states for a position are currently met.
// observePosition: Attempt to initiate withdrawal for a position by selecting *one* met linked state.
// executeWithdrawal: Finalize withdrawal for an 'Observed' position if the chosen state remains met.
// getVaultPosition: View details of a position.
// getEntanglementState: View details of a state.
// getUserPositions: Get list of position IDs for a user.
// getUserStates: Get list of state IDs created by a user.
// triggerDecay: Callable function to apply decay logic to eligible positions.
// calculateDecayAmount: View helper for decay calculation.
// proposeQuantumJump: Propose a change in linked states for a position based on QuantumJumpCondition state type.
// executeQuantumJump: Finalize a proposed quantum jump if conditions met.
// cancelPosition: Owner or user can cancel a position.
// updateEntanglementState: Allow updating state parameters (if state type permits).
// setDecayParameters: Admin function to configure decay.
// addAdmin: Owner function.
// removeAdmin: Owner function.
// renounceOwnership: Standard Ownable function.
// transferOwnership: Standard Ownable function.
// supportsInterface: ERC165 compliance.

contract QuantumVault is Context, ReentrancyGuard, Ownable, ERC721Holder, ERC1155Holder, ERC165 {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    enum AssetType { ERC20, ERC721, ERC1155 }
    enum PositionState { Deposited, Observed, Claimed, Cancelled, Decayed }
    enum EntanglementStateType {
        TimeLock,               // Requires block.timestamp >= unlockTimestamp
        ExternalCondition,      // Requires external oracle data meeting criteria (placeholder)
        InterAssetCondition,    // Requires state of another specific VaultPosition (e.g., claimed, or amount)
        MultiSigCondition,      // Requires signature/call from a specific set of addresses (placeholder - requires off-chain or complex on-chain logic)
        QuantumJumpCondition    // Special state type for changing links - requires admin approval or specific criteria
    }

    struct EntanglementState {
        uint256 stateId;
        address owner; // Creator of the state
        EntanglementStateType stateType;
        bool mutableParams; // Can state parameters be updated?
        // Parameters specific to state type (generalized)
        uint256 param1; // e.g., timestamp, positionId, threshold
        address param2; // e.g., oracle address, token address, required signer
        bytes param3; // e.g., data payload for external call, multiple addresses
        bool conditionMet; // Cache or internal status (external types need oracle check)
    }

    struct VaultPosition {
        uint256 positionId;
        address owner; // Depositor
        AssetType assetType;
        address tokenAddress;
        uint256 tokenId; // 0 for ERC20
        uint256 amount; // Amount for ERC20/ERC1155, 1 for ERC721
        PositionState state;
        uint256[] entanglementStateIds; // Linked states (Superposition)
        uint256 observedStateId; // The state chosen during Observation (Superposition Collapse)
        uint256 depositTimestamp;
        uint256 lastStateChangeTimestamp; // For decay calculation
    }

    // State Variables
    uint256 private _stateCounter;
    uint256 private _positionCounter;

    mapping(uint258 => EntanglementState) public entanglementStates;
    mapping(uint256 => VaultPosition) public vaultPositions;

    mapping(address => uint256[]) public userPositions; // User -> list of position IDs
    mapping(address => uint256[]) public userStates;    // User -> list of state IDs

    // Decay Parameters (example)
    uint256 public decayInterval; // Time in seconds between decay applications
    uint256 public decayRateBPS;  // Basis points per decay interval (e.g., 10 = 0.1%)
    address[] public admins; // Additional addresses with specific admin rights

    // --- Events ---
    event DepositMade(uint256 indexed positionId, address indexed owner, AssetType assetType, address tokenAddress, uint256 tokenId, uint256 amount);
    event EntanglementStateCreated(uint256 indexed stateId, address indexed owner, EntanglementStateType stateType);
    event StateLinked(uint256 indexed positionId, uint256 indexed stateId, address indexed caller);
    event StateUnlinked(uint256 indexed positionId, uint256 indexed stateId, address indexed caller);
    event PositionObserved(uint256 indexed positionId, uint256 indexed observedStateId, address indexed observer);
    event WithdrawalExecuted(uint256 indexed positionId, address indexed recipient, uint256 amountOrId);
    event DecayApplied(uint256 indexed positionId, uint256 decayAmount, uint256 newAmount);
    event QuantumJumpExecuted(uint256 indexed positionId, uint256 indexed quantumJumpStateId, uint256[] newEntanglementStateIds);
    event PositionCancelled(uint256 indexed positionId, address indexed caller, uint256 returnAmount);
    event EntanglementStateUpdated(uint256 indexed stateId, address indexed caller);
    event DecayParametersSet(uint256 decayInterval, uint256 decayRateBPS);
    event AdminAdded(address indexed newAdmin);
    event AdminRemoved(address indexed oldAdmin);

    // --- Modifiers ---
    modifier onlyAdminOrOwner() {
        require(owner() == _msgSender() || isAdmin(_msgSender()), "Not owner or admin");
        _;
    }

    modifier whenPositionExists(uint256 _positionId) {
        require(_positionId > 0 && _positionId <= _positionCounter, "Invalid position ID");
        _;
    }

    modifier whenStateExists(uint256 _stateId) {
        require(_stateId > 0 && _stateId <= _stateCounter, "Invalid state ID");
        _;
    }

    modifier onlyPositionOwner(uint256 _positionId) {
        require(vaultPositions[_positionId].owner == _msgSender(), "Not position owner");
        _;
    }

    modifier onlyStateOwner(uint256 _stateId) {
        require(entanglementStates[_stateId].owner == _msgSender(), "Not state owner");
        _;
    }

    // --- Constructor ---
    constructor(uint256 _decayInterval, uint256 _decayRateBPS) Ownable(msg.sender) ERC165() {
        _stateCounter = 0;
        _positionCounter = 0;
        decayInterval = _decayInterval;
        decayRateBPS = _decayRateBPS;
        // Register receiver interfaces for ERC165 compliance
        _registerInterface(type(IERC721Receiver).interfaceId);
        _registerInterface(type(IERC1155Receiver).interfaceId);
        // Add owner as initial admin
        admins.push(msg.sender);
    }

    // --- ERC165 Interface Support ---
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721Receiver).interfaceId ||
               interfaceId == type(IERC1155Receiver).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    // --- ERC721 & ERC1155 Receive Hooks ---
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external override returns (bytes4)
    {
        // This function is called when ERC721 is transferred to this contract.
        // It's a mandatory hook for ERC721Receiver.
        // We handle the deposit logic via explicit deposit functions, not this hook.
        // This hook mainly serves as validation that the contract can receive ERC721.
        // The actual deposit logic should be initiated by the user calling `depositERC721`.
        // If you wanted to allow deposits *directly* via transfer, you'd add logic here
        // to create a position. For this complex vault, explicit calls are clearer.
        return this.onERC721Received.selector;
    }

     function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data)
        external override returns (bytes4)
    {
         // Same logic as onERC721Received. Explicit deposit calls are preferred.
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data)
        external override returns (bytes4)
    {
        // Same logic as onERC721Received. Explicit deposit calls are preferred.
        return this.onERC1155BatchReceived.selector;
    }

    // --- Deposit Functions ---

    /**
     * @notice Deposits ERC20 tokens into the vault, creating a new position.
     * @param _tokenAddress The address of the ERC20 token.
     * @param _amount The amount of tokens to deposit.
     * @param _initialStateId Optional ID of an entanglement state to initially link.
     */
    function depositERC20(address _tokenAddress, uint256 _amount, uint256 _initialStateId) external nonReentrant {
        require(_amount > 0, "Deposit amount must be > 0");
        IERC20 token = IERC20(_tokenAddress);
        require(token.balanceOf(_msgSender()) >= _amount, "Insufficient balance");
        require(token.allowance(_msgSender(), address(this)) >= _amount, "Insufficient allowance");

        uint256 positionId = ++_positionCounter;
        vaultPositions[positionId] = VaultPosition({
            positionId: positionId,
            owner: _msgSender(),
            assetType: AssetType.ERC20,
            tokenAddress: _tokenAddress,
            tokenId: 0, // Not applicable for ERC20
            amount: _amount,
            state: PositionState.Deposited,
            entanglementStateIds: new uint256[](0),
            observedStateId: 0,
            depositTimestamp: block.timestamp,
            lastStateChangeTimestamp: block.timestamp
        });

        userPositions[_msgSender()].push(positionId);

        token.safeTransferFrom(_msgSender(), address(this), _amount);

        if (_initialStateId > 0) {
            linkStateToPosition(positionId, _initialStateId);
        }

        emit DepositMade(positionId, _msgSender(), AssetType.ERC20, _tokenAddress, 0, _amount);
    }

    /**
     * @notice Deposits an ERC721 token into the vault, creating a new position.
     * @param _tokenAddress The address of the ERC721 token.
     * @param _tokenId The ID of the token to deposit.
     * @param _initialStateId Optional ID of an entanglement state to initially link.
     */
    function depositERC721(address _tokenAddress, uint256 _tokenId, uint256 _initialStateId) external nonReentrant {
         IERC721 token = IERC721(_tokenAddress);
         require(token.ownerOf(_tokenId) == _msgSender(), "Not token owner");
         // ERC721 requires approval *or* approval for all to the vault address
         // before calling transferFrom. Or the user can call `safeTransferFrom`
         // to the vault address directly, which triggers the onERC721Received hook.
         // We will rely on the user having granted approval.
         // require(token.isApprovedForAll(_msgSender(), address(this)) || token.getApproved(_tokenId) == address(this), "ERC721 not approved");

         uint256 positionId = ++_positionCounter;
         vaultPositions[positionId] = VaultPosition({
             positionId: positionId,
             owner: _msgSender(),
             assetType: AssetType.ERC721,
             tokenAddress: _tokenAddress,
             tokenId: _tokenId,
             amount: 1, // Amount is always 1 for ERC721
             state: PositionState.Deposited,
             entanglementStateIds: new uint256[](0),
             observedStateId: 0,
             depositTimestamp: block.timestamp,
             lastStateChangeTimestamp: block.timestamp
         });

         userPositions[_msgSender()].push(positionId);

         // Note: This requires the contract to be an ERC721Receiver, which it is.
         // The user needs to call `safeTransferFrom` from the token contract directly
         // or approve this contract and call `transferFrom` from here.
         // For this example, we assume approval and use transferFrom.
         token.transferFrom(_msgSender(), address(this), _tokenId);


         if (_initialStateId > 0) {
             linkStateToPosition(positionId, _initialStateId);
         }

         emit DepositMade(positionId, _msgSender(), AssetType.ERC721, _tokenAddress, _tokenId, 1);
    }

    /**
     * @notice Deposits ERC1155 tokens into the vault, creating a new position.
     * @param _tokenAddress The address of the ERC1155 token.
     * @param _tokenId The ID of the token type to deposit.
     * @param _amount The amount of tokens to deposit.
     * @param _initialStateId Optional ID of an entanglement state to initially link.
     */
    function depositERC1155(address _tokenAddress, uint256 _tokenId, uint256 _amount, uint256 _initialStateId) external nonReentrant {
         require(_amount > 0, "Deposit amount must be > 0");
         IERC1155 token = IERC1155(_tokenAddress);
         require(token.balanceOf(_msgSender(), _tokenId) >= _amount, "Insufficient balance");
         require(token.isApprovedForAll(_msgSender(), address(this)), "ERC1155 not approved for all");

         uint256 positionId = ++_positionCounter;
         vaultPositions[positionId] = VaultPosition({
             positionId: positionId,
             owner: _msgSender(),
             assetType: AssetType.ERC1155,
             tokenAddress: _tokenAddress,
             tokenId: _tokenId,
             amount: _amount,
             state: PositionState.Deposited,
             entanglementStateIds: new uint256[](0),
             observedStateId: 0,
             depositTimestamp: block.timestamp,
             lastStateChangeTimestamp: block.timestamp
         });

         userPositions[_msgSender()].push(positionId);

         // Note: Requires the contract to be an ERC1155Receiver, which it is.
         token.safeTransferFrom(_msgSender(), address(this), _tokenId, _amount, "");


         if (_initialStateId > 0) {
             linkStateToPosition(positionId, _initialStateId);
         }

         emit DepositMade(positionId, _msgSender(), AssetType.ERC1155, _tokenAddress, _tokenId, _amount);
    }

    // --- Entanglement State Management ---

    /**
     * @notice Creates a new entanglement state defining release conditions.
     * @param _stateType The type of entanglement state.
     * @param _mutableParams Whether parameters can be updated later.
     * @param _param1 Generic parameter 1 (e.g., timestamp, positionId).
     * @param _param2 Generic parameter 2 (e.g., oracle address, token address).
     * @param _param3 Generic parameter 3 (e.g., bytes for data).
     * @return The ID of the newly created state.
     */
    function createEntanglementState(
        EntanglementStateType _stateType,
        bool _mutableParams,
        uint256 _param1,
        address _param2,
        bytes calldata _param3
    ) external returns (uint256) {
        uint256 stateId = ++_stateCounter;
        entanglementStates[stateId] = EntanglementState({
            stateId: stateId,
            owner: _msgSender(),
            stateType: _stateType,
            mutableParams: _mutableParams,
            param1: _param1,
            param2: _param2,
            param3: _param3,
            conditionMet: false // Placeholder, needs dynamic check
        });

        userStates[_msgSender()].push(stateId);

        emit EntanglementStateCreated(stateId, _msgSender(), _stateType);
        return stateId;
    }

    /**
     * @notice Links an existing entanglement state to a vault position. Adds to superposition.
     * Callable by state owner, position owner, or admin.
     * @param _positionId The ID of the vault position.
     * @param _stateId The ID of the entanglement state.
     */
    function linkStateToPosition(uint256 _positionId, uint256 _stateId)
        public
        whenPositionExists(_positionId)
        whenStateExists(_stateId)
        nonReentrant
    {
        VaultPosition storage position = vaultPositions[_positionId];
        EntanglementState storage state = entanglementStates[_stateId];
        require(position.state == PositionState.Deposited, "Position not in Deposited state");
        require(position.owner == _msgSender() || state.owner == _msgSender() || isAdmin(_msgSender()), "Not authorized");

        // Check if already linked
        for (uint i = 0; i < position.entanglementStateIds.length; i++) {
            if (position.entanglementStateIds[i] == _stateId) {
                revert("State already linked to position");
            }
        }

        position.entanglementStateIds.push(_stateId);
        emit StateLinked(_positionId, _stateId, _msgSender());
    }

    /**
     * @notice Unlinks an entanglement state from a vault position. Reduces superposition.
     * Callable by state owner, position owner, or admin, UNLESS the state type forbids unlinking.
     * @param _positionId The ID of the vault position.
     * @param _stateId The ID of the entanglement state.
     */
    function unlinkStateFromPosition(uint256 _positionId, uint256 _stateId)
        public
        whenPositionExists(_positionId)
        whenStateExists(_stateId)
        nonReentrant
    {
        VaultPosition storage position = vaultPositions[_positionId];
        EntanglementState storage state = entanglementStates[_stateId];
        require(position.state == PositionState.Deposited, "Position not in Deposited state");
        require(position.owner == _msgSender() || state.owner == _msgSender() || isAdmin(_msgSender()), "Not authorized");

        // Find and remove the state ID
        bool found = false;
        for (uint i = 0; i < position.entanglementStateIds.length; i++) {
            if (position.entanglementStateIds[i] == _stateId) {
                 // This check is just an example. More complex states might be immutable.
                // require(state.stateType != EntanglementStateType.SomeImmutableType, "State type forbids unlinking");
                position.entanglementStateIds[i] = position.entanglementStateIds[position.entanglementStateIds.length - 1];
                position.entanglementStateIds.pop();
                found = true;
                break;
            }
        }

        require(found, "State not linked to position");
        emit StateUnlinked(_positionId, _stateId, _msgSender());
    }

    /**
     * @notice Updates parameters for a mutable entanglement state.
     * Callable only by state owner.
     * @param _stateId The ID of the state to update.
     * @param _param1 Updated generic parameter 1.
     * @param _param2 Updated generic parameter 2.
     * @param _param3 Updated generic parameter 3.
     */
    function updateEntanglementState(
        uint256 _stateId,
        uint256 _param1,
        address _param2,
        bytes calldata _param3
    ) external onlyStateOwner(_stateId) whenStateExists(_stateId) {
        EntanglementState storage state = entanglementStates[_stateId];
        require(state.mutableParams, "State parameters are immutable");

        state.param1 = _param1;
        state.param2 = _param2;
        state.param3 = _param3;

        emit EntanglementStateUpdated(_stateId, _msgSender());
    }

    // --- Condition Checking ---

    /**
     * @notice Internal helper to check if a specific entanglement state's conditions are met.
     * Note: ExternalCondition requires oracle integration (placeholder here).
     * InterAssetCondition requires checking other positions.
     * @param _stateId The ID of the state to check.
     * @param _positionId The position for which the state is being checked (needed for InterAssetCondition).
     * @return True if conditions are met, false otherwise.
     */
    function checkEntanglementStateStatus(uint256 _stateId, uint256 _positionId) internal view returns (bool) {
        if (_stateId == 0 || _stateId > _stateCounter) return false; // Invalid state ID
        EntanglementState storage state = entanglementStates[_stateId];
        VaultPosition storage currentPosition = vaultPositions[_positionId]; // Needed for InterAssetCondition

        if (state.stateType == EntanglementStateType.TimeLock) {
            // param1 is unlock timestamp
            return block.timestamp >= state.param1;
        } else if (state.stateType == EntanglementStateType.ExternalCondition) {
            // param2 is oracle address, param3 is call data/criteria
            // This is a placeholder. Real implementation needs oracle interaction.
            // Example: Check if price feed (param2) is above threshold (param1)
            // Mock check: Always true if oracle address is non-zero (for demonstration)
            return state.param2 != address(0); // Simplified mock
        } else if (state.stateType == EntanglementStateType.InterAssetCondition) {
            // param1 is targetPositionId, param2 is targetTokenType (or 0 for ERC20)
            // Example: Requires target position (param1) to be in State 'Claimed'
            uint256 targetPositionId = state.param1;
            if (targetPositionId == 0 || targetPositionId > _positionCounter) return false;
            VaultPosition storage targetPosition = vaultPositions[targetPositionId];
            // Check if target position exists and is in a specific state (e.g., Claimed)
            // Or check if its amount meets a threshold (e.g., targetPosition.amount >= state.paramX)
            // This is a simplified check requiring target position to be Claimed
            return targetPosition.state == PositionState.Claimed; // Simplified mock
        } else if (state.stateType == EntanglementStateType.MultiSigCondition) {
             // param3 contains encoded required signers or quorum info.
             // This requires complex off-chain logic or on-chain signature verification (advanced).
             // Mock check: Always false (as it's complex)
             return false; // Simplified mock - cannot be met on-chain easily without more infra
        } else if (state.stateType == EntanglementStateType.QuantumJumpCondition) {
             // Special state type - not for claiming, only for quantum jumps
             return false;
        }
        // Add more state types as needed

        return false; // Unknown state type
    }

    /**
     * @notice Checks which linked entanglement states for a position currently have their conditions met.
     * @param _positionId The ID of the vault position.
     * @return An array of state IDs for which conditions are met.
     */
    function checkPositionClaimableStates(uint256 _positionId)
        public
        view
        whenPositionExists(_positionId)
        returns (uint256[] memory metStateIds)
    {
        VaultPosition storage position = vaultPositions[_positionId];
        require(position.state == PositionState.Deposited, "Position not in Deposited state");

        uint256[] storage linkedStates = position.entanglementStateIds;
        uint256 count = 0;
        // First pass to count how many states are met
        for (uint i = 0; i < linkedStates.length; i++) {
            if (checkEntanglementStateStatus(linkedStates[i], _positionId)) {
                count++;
            }
        }

        // Second pass to populate the array
        metStateIds = new uint256[](count);
        uint256 metIndex = 0;
        for (uint i = 0; i < linkedStates.length; i++) {
            if (checkEntanglementStateStatus(linkedStates[i], _positionId)) {
                 metStateIds[metIndex] = linkedStates[i];
                 metIndex++;
            }
        }
        return metStateIds;
    }

    // --- Core Claim/Withdrawal Flow (Observation & Execution) ---

    /**
     * @notice Initiates the withdrawal process ("Observation") for a position by selecting one met state.
     * This collapses the superposition and locks the claim path to the specified state.
     * Callable only by the position owner.
     * @param _positionId The ID of the vault position.
     * @param _stateId The ID of the *met* entanglement state chosen for observation.
     */
    function observePosition(uint256 _positionId, uint256 _stateId)
        external
        onlyPositionOwner(_positionId)
        whenPositionExists(_positionId)
        whenStateExists(_stateId)
        nonReentrant
    {
        VaultPosition storage position = vaultPositions[_positionId];
        require(position.state == PositionState.Deposited, "Position not in Deposited state");

        // Check if the chosen state is actually linked and met
        bool isLinked = false;
        for (uint i = 0; i < position.entanglementStateIds.length; i++) {
            if (position.entanglementStateIds[i] == _stateId) {
                isLinked = true;
                break;
            }
        }
        require(isLinked, "Chosen state not linked to position");
        require(checkEntanglementStateStatus(_stateId, _positionId), "Chosen state conditions not met");

        // Collapse superposition: Set the observed state and change position state
        position.observedStateId = _stateId;
        position.state = PositionState.Observed;
        position.lastStateChangeTimestamp = block.timestamp; // Update timestamp for decay

        emit PositionObserved(_positionId, _stateId, _msgSender());
    }

    /**
     * @notice Executes the withdrawal for an observed position if its observed state remains met.
     * Callable only by the position owner.
     * @param _positionId The ID of the observed position.
     */
    function executeWithdrawal(uint256 _positionId)
        external
        onlyPositionOwner(_positionId)
        whenPositionExists(_positionId)
        nonReentrant
    {
        VaultPosition storage position = vaultPositions[_positionId];
        require(position.state == PositionState.Observed, "Position not in Observed state");
        require(position.observedStateId > 0, "Position has no observed state");

        // Re-check the observed state conditions just before execution
        require(checkEntanglementStateStatus(position.observedStateId, _positionId), "Observed state conditions no longer met");

        // Perform the withdrawal
        if (position.assetType == AssetType.ERC20) {
            IERC20(position.tokenAddress).safeTransfer(position.owner, position.amount);
        } else if (position.assetType == AssetType.ERC721) {
            IERC721(position.tokenAddress).safeTransferFrom(address(this), position.owner, position.tokenId);
        } else if (position.assetType == AssetType.ERC1155) {
             IERC1155(position.tokenAddress).safeTransferFrom(address(this), position.owner, position.tokenId, position.amount, "");
        } else {
            revert("Unknown asset type");
        }

        uint256 amountOrId = (position.assetType == AssetType.ERC721) ? position.tokenId : position.amount;

        // Update position state
        position.state = PositionState.Claimed;
        position.amount = 0; // Clear amount for clarity
        position.lastStateChangeTimestamp = block.timestamp;

        emit WithdrawalExecuted(_positionId, position.owner, amountOrId);
    }

    // --- Decay Mechanism (Optional) ---

    /**
     * @notice Calculates the potential decay amount for a position based on time elapsed since last state change.
     * @param _positionId The ID of the position.
     * @return The calculated decay amount for ERC20/ERC1155, or 0 for ERC721.
     */
    function calculateDecayAmount(uint256 _positionId)
        public
        view
        whenPositionExists(_positionId)
        returns (uint256)
    {
        VaultPosition storage position = vaultPositions[_positionId];
        if (position.state != PositionState.Deposited || decayInterval == 0 || decayRateBPS == 0 || position.amount == 0) {
            return 0; // No decay if not deposited, decay is zero, or amount is zero
        }
         if (position.assetType == AssetType.ERC721) {
            return 0; // Decay doesn't apply to non-fungible tokens (conceptually)
         }

        uint256 timeElapsed = block.timestamp.sub(position.lastStateChangeTimestamp);
        if (timeElapsed < decayInterval) {
            return 0; // Not enough time elapsed for decay
        }

        uint256 intervals = timeElapsed.div(decayInterval);
        // Simple cumulative decay per interval (can be compounded for more complexity)
        uint256 totalDecayPercentageBPS = intervals.mul(decayRateBPS);
        if (totalDecayPercentageBPS >= 10000) { // Cap decay at 100%
             return position.amount;
        }

        return position.amount.mul(totalDecayPercentageBPS).div(10000);
    }

    /**
     * @notice Applies decay to a specific position if eligible.
     * Can be called by anyone (permissionless decay trigger) or restricted.
     * @param _positionId The ID of the position.
     */
    function applyDecayToPosition(uint256 _positionId)
        public
        whenPositionExists(_positionId)
        nonReentrant
    {
         VaultPosition storage position = vaultPositions[_positionId];
         uint256 decayAmount = calculateDecayAmount(_positionId);

         if (decayAmount > 0) {
             position.amount = position.amount.sub(decayAmount);
             position.lastStateChangeTimestamp = block.timestamp; // Reset timer after applying decay
             position.state = (position.amount == 0) ? PositionState.Decayed : PositionState.Deposited; // Mark as Decayed if amount reaches zero

             emit DecayApplied(_positionId, decayAmount, position.amount);
         }
    }

    /**
     * @notice Triggers decay application for multiple positions.
     * Could iterate through positions, or require a list.
     * This is a basic implementation requiring a list.
     * @param _positionIds An array of position IDs to attempt to apply decay to.
     */
    function triggerDecay(uint256[] calldata _positionIds) external {
        // Could add restriction here (e.g., only keepers, or owner)
        // For permissionless trigger, remove restrictions.
        for (uint i = 0; i < _positionIds.length; i++) {
            // Use try-catch if you want to continue even if one position fails decay
             applyDecayToPosition(_positionIds[i]);
        }
    }

    // --- Quantum Jump Mechanism ---

    /**
     * @notice Proposes a "Quantum Jump" for a position, conditionally changing its linked states.
     * Requires meeting a special `QuantumJumpCondition` state.
     * Callable by position owner or admin.
     * @param _positionId The ID of the position.
     * @param _quantumJumpStateId The ID of the `QuantumJumpCondition` state that is met.
     * @param _newEntanglementStateIds The new set of state IDs to link to the position after the jump.
     */
    function proposeQuantumJump(
        uint256 _positionId,
        uint256 _quantumJumpStateId,
        uint256[] calldata _newEntanglementStateIds
    ) external
        onlyPositionOwner(_positionId) // Or allow admin?
        whenPositionExists(_positionId)
        whenStateExists(_quantumJumpStateId)
        nonReentrant
    {
        VaultPosition storage position = vaultPositions[_positionId];
        EntanglementState storage jumpState = entanglementStates[_quantumJumpStateId];

        require(position.state == PositionState.Deposited, "Position not in Deposited state");
        require(jumpState.stateType == EntanglementStateType.QuantumJumpCondition, "State is not a QuantumJumpCondition");
        require(checkEntanglementStateStatus(_quantumJumpStateId, _positionId), "Quantum Jump condition not met");

        // Note: The new links are stored temporarily or immediately applied depending on design.
        // Here we apply them immediately for simplicity, based on meeting the jump condition.
        // A more complex flow might require a separate execution step.

        // Remove old links and add new ones
        delete position.entanglementStateIds; // Clear existing array
        for (uint i = 0; i < _newEntanglementStateIds.length; i++) {
            uint256 newStateId = _newEntanglementStateIds[i];
            require(newStateId > 0 && newStateId <= _stateCounter, "Invalid new state ID");
             // Optional: Add checks here, e.g., can't link QuantumJumpCondition states
            position.entanglementStateIds.push(newStateId);
        }

        // You might also update `lastStateChangeTimestamp` or add a specific `Jumped` state.
        // For simplicity, we'll keep it `Deposited` state unless observed.

        emit QuantumJumpExecuted(_positionId, _quantumJumpStateId, _newEntanglementStateIds);
    }

    /**
     * @notice (Alternative/Simpler Quantum Jump Execution - combined with propose)
     * Executes a Quantum Jump directly if the condition is met.
     * This function assumes `proposeQuantumJump` logic is merged here for direct execution.
     * Retaining `propose/execute` separation would involve storing the proposal state.
     * Let's make `proposeQuantumJump` the single execution function for simplicity in this draft.
     */
    // function executeQuantumJump(...) external { ... } // Not needed if propose does it directly

    // --- Position Management ---

    /**
     * @notice Allows the owner to cancel their deposited position, potentially with a penalty.
     * Assets are returned to the owner, potentially less a cancellation fee/penalty.
     * @param _positionId The ID of the position to cancel.
     */
    function cancelPosition(uint256 _positionId)
        external
        onlyPositionOwner(_positionId)
        whenPositionExists(_positionId)
        nonReentrant
    {
        VaultPosition storage position = vaultPositions[_positionId];
        require(position.state == PositionState.Deposited, "Position not in Deposited state");

        uint256 returnAmount = position.amount; // Default: return full amount
        // Implement cancellation penalty logic here if desired
        // Example: 10% penalty on ERC20/ERC1155
        // if (position.assetType != AssetType.ERC721) {
        //     uint256 penaltyAmount = returnAmount.mul(1000).div(10000); // 10%
        //     returnAmount = returnAmount.sub(penaltyAmount);
        //     // Handle penalty amount (e.g., send to owner, burn, send to a fee address)
        // }


        if (position.assetType == AssetType.ERC20) {
            IERC20(position.tokenAddress).safeTransfer(position.owner, returnAmount);
        } else if (position.assetType == AssetType.ERC721) {
            // No penalty for ERC721 here, just transfer the NFT back
            IERC721(position.tokenAddress).safeTransferFrom(address(this), position.owner, position.tokenId);
            returnAmount = position.tokenId; // Event will show tokenId
        } else if (position.assetType == AssetType.ERC1155) {
             IERC1155(position.tokenAddress).safeTransferFrom(address(this), position.owner, position.tokenId, returnAmount, "");
        } else {
            revert("Unknown asset type");
        }

        // Update position state
        position.state = PositionState.Cancelled;
        position.amount = 0; // Clear amount
        position.lastStateChangeTimestamp = block.timestamp;

        // Note: The position is marked Cancelled but remains in storage.
        // To truly remove, need array manipulation or a mapping to track active vs inactive.
        // For simplicity, we leave it marked.

        emit PositionCancelled(_positionId, _msgSender(), returnAmount);
    }

    // --- View Functions ---

    /**
     * @notice Gets the details of a vault position.
     * @param _positionId The ID of the position.
     * @return VaultPosition struct details.
     */
    function getVaultPosition(uint256 _positionId)
        external
        view
        whenPositionExists(_positionId)
        returns (VaultPosition memory)
    {
        return vaultPositions[_positionId];
    }

     /**
     * @notice Gets the details of an entanglement state.
     * @param _stateId The ID of the state.
     * @return EntanglementState struct details.
     */
    function getEntanglementState(uint256 _stateId)
        external
        view
        whenStateExists(_stateId)
        returns (EntanglementState memory)
    {
        return entanglementStates[_stateId];
    }

    /**
     * @notice Gets the list of position IDs owned by a user.
     * @param _user The address of the user.
     * @return An array of position IDs.
     */
    function getUserPositions(address _user) external view returns (uint256[] memory) {
        return userPositions[_user];
    }

    /**
     * @notice Gets the list of state IDs created by a user.
     * @param _user The address of the user.
     * @return An array of state IDs.
     */
    function getUserStates(address _user) external view returns (uint256[] memory) {
        return userStates[_user];
    }

    // --- Admin Functions ---

    /**
     * @notice Sets the decay parameters. Only callable by Owner.
     * @param _decayInterval New decay interval in seconds.
     * @param _decayRateBPS New decay rate in basis points.
     */
    function setDecayParameters(uint256 _decayInterval, uint256 _decayRateBPS) external onlyOwner {
        decayInterval = _decayInterval;
        decayRateBPS = _decayRateBPS;
        emit DecayParametersSet(decayInterval, decayRateBPS);
    }

    /**
     * @notice Adds an address to the list of admins. Only callable by Owner.
     * @param _admin The address to add as admin.
     */
    function addAdmin(address _admin) external onlyOwner {
        require(_admin != address(0), "Admin address cannot be zero");
        for (uint i = 0; i < admins.length; i++) {
            require(admins[i] != _admin, "Address is already an admin");
        }
        admins.push(_admin);
        emit AdminAdded(_admin);
    }

    /**
     * @notice Removes an address from the list of admins. Only callable by Owner.
     * @param _admin The address to remove from admins.
     */
    function removeAdmin(address _admin) external onlyOwner {
        require(_admin != address(0), "Admin address cannot be zero");
        bool found = false;
        for (uint i = 0; i < admins.length; i++) {
            if (admins[i] == _admin) {
                admins[i] = admins[admins.length - 1];
                admins.pop();
                found = true;
                break;
            }
        }
        require(found, "Address is not an admin");
        emit AdminRemoved(_admin);
    }

    /**
     * @notice Checks if an address is an admin.
     * @param _address The address to check.
     * @return True if the address is an admin, false otherwise.
     */
    function isAdmin(address _address) public view returns (bool) {
        for (uint i = 0; i < admins.length; i++) {
            if (admins[i] == _address) {
                return true;
            }
        }
        return false;
    }

    // --- Fallback/Receive Functions ---
    // Although not explicitly requested, good practice to consider Ether handling.
    // Since this vault is for tokens, we won't allow Ether deposits implicitly.
    // receive() external payable { revert("Ether not accepted"); }
    // fallback() external payable { revert("Calls not accepted"); }

}
```