```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/erc20/IERC20.sol";
import "@openzeppelin/contracts/token/erc721/IERC721.sol";
import "@openzeppelin/contracts/token/erc721/utils/ERC721Holder.sol"; // To receive ERC721 tokens
import "@openzeppelin/contracts/token/erc1155/IERC1155Receiver.sol"; // To receive ERC1155 tokens (optional, but good practice for completeness)
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For safer math operations (less critical in 0.8+, but good habit)
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; // To prevent reentrancy attacks

// --- CONTRACT OUTLINE ---
// Contract Name: QuantumVault
// Core Concept: A vault that stores various assets (ETH, ERC20, ERC721) in unique "Quantum Slots".
//              Each slot has dynamic states and can be conditionally unlocked based on time,
//              external conditions, or even "entanglement" with other slots.
// Key Features:
// - Supports depositing/withdrawing ETH, ERC20, ERC721.
// - Assets are stored in unique, tokenized "Quantum Slots".
// - Each slot has a dynamic state: Stable, Superposed, Entangled, Decohered, Voided.
// - Time-locked withdrawals.
// - Conditional withdrawals based on external data/hashes ("Superposition Resolution").
// - "Entanglement": Linking the state/unlocking of two slots.
// - Staking of Quantum Slots for potential future rewards (placeholder mechanism).
// - Transferable slot ownership (effectively transferring the contained asset plus conditions).
// - Admin functions for rewards distribution and voiding slots.
// - More than 20 functions for diverse interactions.

// --- FUNCTION SUMMARY ---
// --- Core Deposit Functions ---
// 1. depositETH: Creates a new slot holding ETH with specified unlock time and potential superposition condition.
// 2. depositERC20: Creates a new slot holding ERC20 tokens with specified unlock time and potential superposition condition.
// 3. depositERC721: Creates a new slot holding an ERC721 token with specified unlock time and potential superposition condition.
// --- Core Withdrawal & State Resolution Functions ---
// 4. withdraw: Attempts to withdraw assets from a slot. Requires specific slot state, time elapsed, and potential entanglement/superposition conditions met.
// 5. resolveSuperposition: Attempts to move a slot from 'Superposed' to 'Stable' or 'Decohered' by providing data that matches the condition hash.
// 6. decohereSlot: Attempts to move an 'Entangled' slot back to a determined state ('Stable' or 'Superposed') or 'Decohered' based on rules.
// --- Quantum Interaction Functions ---
// 7. entangleSlots: Links two slots, changing their state to 'Entangled'. Requires specific initial states and ownership.
// --- Slot Management Functions ---
// 8. transferSlotOwnership: Transfers ownership of a slot (and its contents/conditions) to another address.
// 9. updateUnlockTime: Allows slot owner to extend the time-lock duration.
// 10. updateSuperpositionCondition: Allows slot owner to update the hash requirement for 'Superposed' state resolution.
// 11. stakeSlot: Marks a slot as staked (placeholder for staking mechanics).
// 12. unstakeSlot: Unmarks a slot as staked.
// 13. renounceSlotOwnership: Allows slot owner to give up ownership, potentially voiding the slot or transferring to contract owner.
// --- Rewards & Admin Functions ---
// 14. distributeRewards: (Owner Only) Adds a reward amount to a specific slot. Placeholder for a reward system.
// 15. claimStakingRewards: Allows a slot owner to claim accumulated rewards (placeholder).
// 16. voidSlot: (Owner Only) Invalidates a slot, potentially making contents inaccessible or claimable by owner.
// --- View & Utility Functions ---
// 17. getSlotDetails: Retrieves detailed information about a specific slot.
// 18. getSlotState: Retrieves just the current state of a slot.
// 19. getOwnerSlots: Retrieves all slot IDs owned by a given address (gas-inefficient for many slots, better for off-chain indexing).
// 20. getEntangledSlots: Retrieves the list of slots entangled with a given slot.
// 21. isSlotStaked: Checks if a slot is currently staked.
// 22. checkCondition: Checks if the time-lock condition for a slot has passed. Does NOT check superposition hash.
// 23. getActiveSlotCount: Gets the total number of non-voided slots.
// 24. owner: (Inherited/Simple) Gets the contract owner.

contract QuantumVault is ERC721Holder, IERC1155Receiver, ReentrancyGuard {
    using SafeMath for uint256;

    // --- State Variables ---
    address private _owner; // Basic owner for admin functions
    uint256 private _nextSlotId; // Counter for unique slot IDs
    mapping(uint256 => QuantumSlot) private _slots; // Storage for all quantum slots
    mapping(address => uint256[]) private _ownerSlots; // Mapping owner address to list of their slot IDs (simplified for example)
    mapping(uint256 => bool) private _isSlotStaked; // Tracks which slots are staked

    // --- Enums ---
    enum SlotState {
        Stable,       // Normal state, time-lock applies
        Superposed,   // Requires conditional resolution (via hash)
        Entangled,    // Linked to other slots, state/unlocking is coupled
        Decohered,    // Terminal state, asset potentially lost or claimable by owner
        Voided        // Invalidated state (admin or specific condition)
    }

    enum AssetType {
        ETH,
        ERC20,
        ERC721
        // ERC1155 could be added
    }

    // --- Structs ---
    struct QuantumSlot {
        address owner;          // Current owner of the slot
        AssetType assetType;    // Type of asset held
        address assetAddress;   // Address of ERC20/ERC721 contract (0x0 for ETH)
        uint256 tokenId;        // Token ID for ERC721 (0 for ETH/ERC20)
        uint256 amount;         // Amount for ETH/ERC20 (1 for ERC721)
        SlotState state;        // Current state of the slot
        uint256 unlockTime;     // Timestamp after which withdrawal is possible (if state allows)
        bytes32 conditionHash;  // Hash required to resolve 'Superposed' state
        uint256[] entangledSlots; // List of slot IDs entangled with this one
        uint256 rewardAmount;   // Accumulated rewards for this slot (placeholder)
    }

    // --- Events ---
    event SlotCreated(uint256 indexed slotId, address indexed owner, AssetType assetType, address assetAddress, uint256 tokenId, uint256 amount, uint256 unlockTime, bytes32 conditionHash);
    event StateChanged(uint256 indexed slotId, SlotState oldState, SlotState newState);
    event AssetWithdrawn(uint256 indexed slotId, address indexed recipient, AssetType assetType, address assetAddress, uint256 tokenId, uint256 amount);
    event SlotOwnershipTransferred(uint256 indexed slotId, address indexed from, address indexed to);
    event SlotsEntangled(uint256 indexed slotId1, uint256 indexed slotId2);
    event SlotDecohered(uint256 indexed slotId);
    event SuperpositionResolved(uint256 indexed slotId, bool success, SlotState resultingState);
    event SlotStaked(uint256 indexed slotId);
    event SlotUnstaked(uint256 indexed slotId);
    event RewardsDistributed(uint256 indexed slotId, uint256 amount);
    event RewardsClaimed(uint256 indexed slotId, address indexed owner, uint256 amount);
    event SlotVoided(uint256 indexed slotId);

    // --- Constructor ---
    constructor() {
        _owner = msg.sender;
        _nextSlotId = 1; // Start slot IDs from 1
    }

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == _owner, "Not the contract owner");
        _;
    }

    modifier onlySlotOwner(uint256 _slotId) {
        require(_slots[_slotId].owner == msg.sender, "Not the slot owner");
        require(_slots[_slotId].state != SlotState.Voided, "Slot is voided");
        _;
    }

    // --- Receive ETH Function ---
    receive() external payable nonReentrant {} // Allow receiving ETH

    // --- Core Deposit Functions ---

    /**
     * @dev Creates a new slot holding ETH.
     * @param _unlockTime Timestamp after which the slot can potentially be unlocked.
     * @param _conditionHash Hash required to resolve 'Superposed' state (bytes32(0) for no hash condition).
     */
    function depositETH(uint256 _unlockTime, bytes32 _conditionHash) external payable nonReentrant {
        require(msg.value > 0, "Must deposit ETH");
        _createSlot(msg.sender, AssetType.ETH, address(0), 0, msg.value, _unlockTime, _conditionHash);
    }

    /**
     * @dev Creates a new slot holding ERC20 tokens.
     * Requires caller to approve this contract to spend the tokens beforehand.
     * @param _tokenAddress Address of the ERC20 token contract.
     * @param _amount Amount of ERC20 tokens to deposit.
     * @param _unlockTime Timestamp after which the slot can potentially be unlocked.
     * @param _conditionHash Hash required to resolve 'Superposed' state (bytes32(0) for no hash condition).
     */
    function depositERC20(address _tokenAddress, uint256 _amount, uint256 _unlockTime, bytes32 _conditionHash) external nonReentrant {
        require(_tokenAddress != address(0), "Invalid token address");
        require(_amount > 0, "Must deposit non-zero amount");

        IERC20 token = IERC20(_tokenAddress);
        require(token.transferFrom(msg.sender, address(this), _amount), "ERC20 transfer failed");

        _createSlot(msg.sender, AssetType.ERC20, _tokenAddress, 0, _amount, _unlockTime, _conditionHash);
    }

    /**
     * @dev Creates a new slot holding an ERC721 token.
     * Requires caller to approve this contract or setApprovalForAll beforehand.
     * @param _tokenAddress Address of the ERC721 token contract.
     * @param _tokenId Token ID of the ERC721 token to deposit.
     * @param _unlockTime Timestamp after which the slot can potentially be unlocked.
     * @param _conditionHash Hash required to resolve 'Superposed' state (bytes32(0) for no hash condition).
     */
    function depositERC721(address _tokenAddress, uint256 _tokenId, uint256 _unlockTime, bytes32 _conditionHash) external nonReentrant {
        require(_tokenAddress != address(0), "Invalid token address");

        IERC721 token = IERC721(_tokenAddress);
        require(token.ownerOf(_tokenId) == msg.sender, "Caller must own the token");

        // ERC721Holder handles the transfer logic when `onERC721Received` is called by the token contract
        token.safeTransferFrom(msg.sender, address(this), _tokenId);

        // Slot creation is handled after the token is received in onERC721Received
        // We store parameters temporarily or trust the ERC721 standard flow.
        // For simplicity in this example, let's call _createSlot directly here, assuming transfer success.
        // A more robust implementation might link the transfer event to slot creation.
        _createSlot(msg.sender, AssetType.ERC721, _tokenAddress, _tokenId, 1, _unlockTime, _conditionHash);
    }

    // --- Core Withdrawal & State Resolution Functions ---

    /**
     * @dev Attempts to withdraw assets from a slot.
     * Requires the slot to be in a 'Stable' state, time-lock passed,
     * and not currently staked or involved in active entanglement needing resolution.
     * Assets are sent to the slot owner.
     * @param _slotId The ID of the slot to withdraw from.
     */
    function withdraw(uint256 _slotId) external nonReentrant onlySlotOwner(_slotId) {
        QuantumSlot storage slot = _slots[_slotId];

        require(slot.state == SlotState.Stable, "Slot state is not Stable");
        require(block.timestamp >= slot.unlockTime, "Slot is time-locked");
        require(!_isSlotStaked[_slotId], "Slot is staked");
        require(slot.entangledSlots.length == 0, "Slot is entangled, must be decohered first");

        // Perform the withdrawal based on asset type
        _performWithdrawal(_slotId, msg.sender);

        // Void the slot after successful withdrawal
        _voidSlot(_slotId);
        emit StateChanged(_slotId, slot.state, SlotState.Voided);
    }

    /**
     * @dev Attempts to resolve a 'Superposed' slot.
     * Provides data whose hash must match the slot's conditionHash.
     * Successfully resolving moves state to 'Stable'. Failure or incorrect data moves to 'Decohered'.
     * @param _slotId The ID of the slot to resolve.
     * @param _data The data used to check against the condition hash.
     */
    function resolveSuperposition(uint256 _slotId, bytes calldata _data) external nonReentrant onlySlotOwner(_slotId) {
        QuantumSlot storage slot = _slots[_slotId];
        require(slot.state == SlotState.Superposed, "Slot is not Superposed");

        SlotState oldState = slot.state;
        bytes32 dataHash = keccak256(_data);

        if (dataHash == slot.conditionHash) {
            // Successfully resolved
            slot.state = SlotState.Stable;
            emit StateChanged(_slotId, oldState, slot.state);
            emit SuperpositionResolved(_slotId, true, slot.state);
        } else {
            // Failed resolution - collapses to Decohered state
            slot.state = SlotState.Decohered;
            emit StateChanged(_slotId, oldState, slot.state);
            emit SuperpositionResolved(_slotId, false, slot.state);
            // Note: Asset is now stuck or claimable by owner in Decohered state (see voidSlot for example)
        }
    }

    /**
     * @dev Attempts to decohere an 'Entangled' slot.
     * Breaks the entanglement links. The slot and its entangled partners may transition
     * back to their previous state ('Stable' or 'Superposed') or collapse to 'Decohered'
     * if entanglement requires specific conditions (not fully implemented here, simplified).
     * This simplified version just breaks links and returns the slot to 'Stable'.
     * @param _slotId The ID of the slot to decohere.
     */
    function decohereSlot(uint256 _slotId) external nonReentrant onlySlotOwner(_slotId) {
        QuantumSlot storage slot = _slots[_slotId];
        require(slot.state == SlotState.Entangled, "Slot is not Entangled");

        SlotState oldState = slot.state;

        // Break links with entangled slots
        for (uint i = 0; i < slot.entangledSlots.length; i++) {
            uint256 entangledSlotId = slot.entangledSlots[i];
            QuantumSlot storage entangledSlot = _slots[entangledSlotId];

            // Find and remove _slotId from entangledSlot's list
            for (uint j = 0; j < entangledSlot.entangledSlots.length; j++) {
                if (entangledSlot.entangledSlots[j] == _slotId) {
                    entangledSlot.entangledSlots[j] = entangledSlot.entangledSlots[entangledSlot.entangledSlots.length - 1];
                    entangledSlot.entangledSlots.pop();
                    break; // Assumes no duplicate entanglement entries
                }
            }

            // Transition entangled slot state (simplified: just back to Stable)
            if (entangledSlot.state == SlotState.Entangled) {
                 entangledSlot.state = SlotState.Stable; // Could transition back to Superposed if it was before
                 emit StateChanged(entangledSlotId, SlotState.Entangled, entangledSlot.state);
            }
        }

        // Clear entanglement list for the current slot
        delete slot.entangledSlots; // Resets array to empty

        // Transition current slot state (simplified: back to Stable)
        slot.state = SlotState.Stable; // Could transition back to Superposed if it was before
        emit StateChanged(_slotId, oldState, slot.state);
        emit SlotDecohered(_slotId);
    }

    // --- Quantum Interaction Functions ---

    /**
     * @dev Entangles two slots. Both slots must be 'Stable' or 'Superposed' and owned by the caller.
     * Changes both slots' state to 'Entangled' and links them.
     * @param _slotId1 The ID of the first slot.
     * @param _slotId2 The ID of the second slot.
     */
    function entangleSlots(uint256 _slotId1, uint256 _slotId2) external nonReentrant {
        require(_slotId1 != _slotId2, "Cannot entangle a slot with itself");
        require(_slots[_slotId1].owner == msg.sender && _slots[_slotId2].owner == msg.sender, "Caller must own both slots");
        require(_slots[_slotId1].state != SlotState.Voided && _slots[_slotId2].state != SlotState.Voided, "Slots must not be voided");

        QuantumSlot storage slot1 = _slots[_slotId1];
        QuantumSlot storage slot2 = _slots[_slotId2];

        require(slot1.state == SlotState.Stable || slot1.state == SlotState.Superposed, "Slot 1 must be Stable or Superposed");
        require(slot2.state == SlotState.Stable || slot2.state == SlotState.Superposed, "Slot 2 must be Stable or Superposed");

        // Check if already entangled with each other (basic check)
        bool alreadyEntangled = false;
        for(uint i=0; i<slot1.entangledSlots.length; i++) {
            if (slot1.entangledSlots[i] == _slotId2) {
                alreadyEntangled = true;
                break;
            }
        }
        require(!alreadyEntangled, "Slots are already entangled");

        // Add entanglement links
        slot1.entangledSlots.push(_slotId2);
        slot2.entangledSlots.push(_slotId1);

        // Change states to Entangled
        SlotState oldState1 = slot1.state;
        SlotState oldState2 = slot2.state;
        slot1.state = SlotState.Entangled;
        slot2.state = SlotState.Entangled;

        emit StateChanged(_slotId1, oldState1, slot1.state);
        emit StateChanged(_slotId2, oldState2, slot2.state);
        emit SlotsEntangled(_slotId1, _slotId2);
    }

    // --- Slot Management Functions ---

    /**
     * @dev Transfers ownership of a quantum slot to another address.
     * The new owner inherits the slot's asset, state, and conditions.
     * Cannot transfer if the slot is voided.
     * @param _slotId The ID of the slot to transfer.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferSlotOwnership(uint256 _slotId, address _newOwner) external nonReentrant onlySlotOwner(_slotId) {
        require(_newOwner != address(0), "New owner cannot be the zero address");
        require(_newOwner != msg.sender, "Cannot transfer to self");

        QuantumSlot storage slot = _slots[_slotId];
        address oldOwner = slot.owner;

        // Remove from old owner's list (gas-inefficient, optimize off-chain if needed)
        uint256[] storage oldOwnerSlots = _ownerSlots[oldOwner];
        for(uint i = 0; i < oldOwnerSlots.length; i++) {
            if (oldOwnerSlots[i] == _slotId) {
                oldOwnerSlots[i] = oldOwnerSlots[oldOwnerSlots.length - 1];
                oldOwnerSlots.pop();
                break;
            }
        }

        // Add to new owner's list
        _ownerSlots[_newOwner].push(_slotId);

        // Update owner
        slot.owner = _newOwner;

        emit SlotOwnershipTransferred(_slotId, oldOwner, _newOwner);
    }

    /**
     * @dev Allows the slot owner to extend the time-lock of a slot.
     * Can only extend, not shorten, the unlock time.
     * Cannot update if the slot is voided or decohered.
     * @param _slotId The ID of the slot to update.
     * @param _newUnlockTime The new timestamp for unlocking.
     */
    function updateUnlockTime(uint256 _slotId, uint256 _newUnlockTime) external nonReentrant onlySlotOwner(_slotId) {
        QuantumSlot storage slot = _slots[_slotId];
        require(slot.state != SlotState.Decohered, "Cannot update Decohered slot");
        require(_newUnlockTime > slot.unlockTime, "New unlock time must be after current unlock time");

        slot.unlockTime = _newUnlockTime;
        // No specific event for this, but state change could imply update.
    }

    /**
     * @dev Allows the slot owner to update the hash requirement for 'Superposed' state resolution.
     * Can only update if the slot is in 'Superposed' or 'Stable' state.
     * Cannot update if the slot is Voided, Decohered, or Entangled.
     * @param _slotId The ID of the slot to update.
     * @param _newConditionHash The new hash required for resolution.
     */
    function updateSuperpositionCondition(uint256 _slotId, bytes32 _newConditionHash) external nonReentrant onlySlotOwner(_slotId) {
        QuantumSlot storage slot = _slots[_slotId];
        require(slot.state == SlotState.Stable || slot.state == SlotState.Superposed, "Slot must be Stable or Superposed to update condition");

        slot.conditionHash = _newConditionHash;
        // No specific event for this.
    }

    /**
     * @dev Marks a slot as staked. Placeholder function for staking mechanics.
     * Cannot stake Voided or Decohered slots.
     * @param _slotId The ID of the slot to stake.
     */
    function stakeSlot(uint256 _slotId) external nonReentrant onlySlotOwner(_slotId) {
        QuantumSlot storage slot = _slots[_slotId];
        require(slot.state != SlotState.Decohered && slot.state != SlotState.Voided, "Cannot stake Decohered or Voided slots");
        require(!_isSlotStaked[_slotId], "Slot is already staked");

        _isSlotStaked[_slotId] = true;
        emit SlotStaked(_slotId);
        // In a real system, this would likely involve state changes or adding to a staking pool.
    }

    /**
     * @dev Unmarks a slot as staked. Placeholder function.
     * @param _slotId The ID of the slot to unstake.
     */
    function unstakeSlot(uint256 _slotId) external nonReentrant onlySlotOwner(_slotId) {
        require(_isSlotStaked[_slotId], "Slot is not staked");

        _isSlotStaked[_slotId] = false;
        emit SlotUnstaked(_slotId);
        // In a real system, this might require time or conditions met.
    }

    /**
     * @dev Allows a slot owner to give up ownership of a slot.
     * This typically voids the slot, making the asset potentially claimable by the contract owner.
     * @param _slotId The ID of the slot to renounce ownership of.
     */
    function renounceSlotOwnership(uint256 _slotId) external nonReentrant onlySlotOwner(_slotId) {
         QuantumSlot storage slot = _slots[_slotId];
         address oldOwner = slot.owner;

         // Remove from old owner's list
         uint256[] storage oldOwnerSlots = _ownerSlots[oldOwner];
         for(uint i = 0; i < oldOwnerSlots.length; i++) {
             if (oldOwnerSlots[i] == _slotId) {
                 oldOwnerSlots[i] = oldOwnerSlots[oldOwnerSlots.length - 1];
                 oldOwnerSlots.pop();
                 break;
             }
         }

         // Set owner to zero address (or a designated void address)
         slot.owner = address(0); // Indicates no owner

         // Void the slot as it has no owner
         _voidSlot(_slotId);
         emit SlotOwnershipTransferred(_slotId, oldOwner, address(0));
         emit StateChanged(_slotId, slot.state, SlotState.Voided);
    }


    // --- Rewards & Admin Functions ---

    /**
     * @dev (Owner Only) Distributes a placeholder reward amount to a specific slot.
     * In a real system, rewards logic would be more complex (e.g., time-based, external oracle).
     * @param _slotId The ID of the slot to distribute rewards to.
     * @param _amount The amount of reward to add (in native token or a designated reward token).
     */
    function distributeRewards(uint256 _slotId, uint256 _amount) external onlyOwner nonReentrant {
        QuantumSlot storage slot = _slots[_slotId];
        require(slot.owner != address(0) && slot.state != SlotState.Voided, "Cannot distribute rewards to voided/unowned slot");
        require(_amount > 0, "Reward amount must be positive");

        slot.rewardAmount = slot.rewardAmount.add(_amount);
        emit RewardsDistributed(_slotId, _amount);
    }

    /**
     * @dev Allows a slot owner to claim accumulated rewards for their slot.
     * Placeholder function. In a real system, claiming might require the slot to be staked,
     * unstaked, or in a specific state. This simple version just requires ownership.
     * @param _slotId The ID of the slot to claim rewards from.
     */
    function claimStakingRewards(uint256 _slotId) external nonReentrant onlySlotOwner(_slotId) {
        QuantumSlot storage slot = _slots[_slotId];
        uint256 rewards = slot.rewardAmount;
        require(rewards > 0, "No rewards to claim");

        slot.rewardAmount = 0; // Reset rewards for this slot

        // Send rewards (assuming native token for simplicity)
        // In a real system, this could be an ERC20 reward token held by the contract.
        (bool success, ) = payable(msg.sender).call{value: rewards}("");
        require(success, "Reward transfer failed");

        emit RewardsClaimed(_slotId, msg.sender, rewards);
    }

    /**
     * @dev (Owner Only) Forcibly voids a slot. This makes the slot unusable and its assets potentially
     * inaccessible or claimable by the contract owner depending on implementation.
     * This simulates a critical collapse or failure mode.
     * @param _slotId The ID of the slot to void.
     */
    function voidSlot(uint256 _slotId) external onlyOwner nonReentrant {
        QuantumSlot storage slot = _slots[_slotId];
        require(slot.state != SlotState.Voided, "Slot is already voided");

        SlotState oldState = slot.state;
        slot.state = SlotState.Voided; // Mark as voided

        // Assets remain in the contract, now associated with a voided slot.
        // Contract owner could potentially claim them later via a separate function if designed.
        // For this example, they are effectively trapped unless an admin function is added.
        // Let's add a simple admin claim function for voided slots for completeness.

        emit StateChanged(_slotId, oldState, SlotState.Voided);
        emit SlotVoided(_slotId);
    }

    /**
     * @dev (Owner Only) Allows the contract owner to claim assets from a voided slot.
     * This represents the asset collapsing to the contract owner after a failure.
     * @param _slotId The ID of the voided slot.
     */
    function claimVoidedAsset(uint256 _slotId) external onlyOwner nonReentrant {
        QuantumSlot storage slot = _slots[_slotId];
        require(slot.state == SlotState.Voided, "Slot is not voided");
        require(slot.amount > 0, "Voided slot has no assets"); // Check if amount > 0 before claiming

        // Perform the withdrawal to the contract owner
        _performWithdrawal(_slotId, msg.sender);

        // Clear asset details from the slot struct after claiming
        slot.assetType = AssetType.ETH; // Default or invalid type
        slot.assetAddress = address(0);
        slot.tokenId = 0;
        slot.amount = 0;
        // State remains Voided
    }


    // --- View & Utility Functions ---

    /**
     * @dev Gets detailed information about a specific quantum slot.
     * @param _slotId The ID of the slot.
     * @return QuantumSlot struct containing all details.
     */
    function getSlotDetails(uint256 _slotId) external view returns (QuantumSlot memory) {
        require(_slots[_slotId].owner != address(0), "Slot does not exist"); // Basic check for existence
        return _slots[_slotId];
    }

     /**
     * @dev Gets the current state of a specific quantum slot.
     * @param _slotId The ID of the slot.
     * @return The SlotState enum value.
     */
    function getSlotState(uint256 _slotId) external view returns (SlotState) {
        require(_slots[_slotId].owner != address(0), "Slot does not exist"); // Basic check for existence
        return _slots[_slotId].state;
    }

    /**
     * @dev Gets the list of slot IDs owned by a given address.
     * Note: This function can be gas-intensive for owners with many slots.
     * Off-chain indexing (e.g., using a subgraph) is recommended for production.
     * @param _ownerAddress The address of the owner.
     * @return An array of slot IDs owned by the address.
     */
    function getOwnerSlots(address _ownerAddress) external view returns (uint256[] memory) {
        return _ownerSlots[_ownerAddress];
    }

    /**
     * @dev Gets the list of slot IDs that a specific slot is entangled with.
     * @param _slotId The ID of the slot.
     * @return An array of entangled slot IDs.
     */
    function getEntangledSlots(uint256 _slotId) external view returns (uint256[] memory) {
        require(_slots[_slotId].owner != address(0), "Slot does not exist");
        return _slots[_slotId].entangledSlots;
    }

    /**
     * @dev Checks if a specific slot is currently marked as staked.
     * @param _slotId The ID of the slot.
     * @return True if staked, false otherwise.
     */
    function isSlotStaked(uint256 _slotId) external view returns (bool) {
        require(_slots[_slotId].owner != address(0), "Slot does not exist");
        return _isSlotStaked[_slotId];
    }

    /**
     * @dev Checks if the time-lock condition for a slot has passed.
     * Does NOT check superposition hash condition.
     * @param _slotId The ID of the slot.
     * @return True if unlockTime is in the past or present, false otherwise.
     */
    function checkCondition(uint256 _slotId) external view returns (bool) {
        require(_slots[_slotId].owner != address(0), "Slot does not exist");
        return block.timestamp >= _slots[_slotId].unlockTime;
    }

    /**
     * @dev Gets the total number of non-voided slots.
     * Note: This requires iterating through all potential slot IDs up to the max created,
     * which is highly gas-inefficient if there are many historical slots.
     * A mapping `uint256 => bool isVoided` and a counter updated on void/create would be better.
     * For demonstration, we'll loop up to the max created ID.
     * @return The count of active (non-voided) slots.
     */
    function getActiveSlotCount() external view returns (uint256) {
        uint256 count = 0;
        // This loop is inefficient for large _nextSlotId
        for (uint256 i = 1; i < _nextSlotId; i++) {
            if (_slots[i].state != SlotState.Voided) {
                 // Check if the slot exists (owner not address(0)) before counting
                if (_slots[i].owner != address(0) || _slots[i].state != SlotState.Voided) {
                     count++;
                } else if (_slots[i].state != SlotState.Voided) {
                     // Edge case: if owner was renounced to address(0) but not yet voided
                     count++;
                }
            }
        }
        return count;
    }

    /**
     * @dev Returns the address of the contract owner.
     */
    function owner() external view returns (address) {
        return _owner;
    }


    // --- Internal Helper Functions ---

    /**
     * @dev Internal function to create a new Quantum Slot.
     */
    function _createSlot(address _ownerAddress, AssetType _assetType, address _assetAddress, uint256 _tokenId, uint256 _amount, uint256 _unlockTime, bytes32 _conditionHash) internal {
        uint256 slotId = _nextSlotId;
        _nextSlotId++;

        QuantumSlot storage newSlot = _slots[slotId];
        newSlot.owner = _ownerAddress;
        newSlot.assetType = _assetType;
        newSlot.assetAddress = _assetAddress;
        newSlot.tokenId = _tokenId;
        newSlot.amount = _amount;
        newSlot.state = (_conditionHash != bytes32(0)) ? SlotState.Superposed : SlotState.Stable; // Start Superposed if condition hash exists
        newSlot.unlockTime = _unlockTime;
        newSlot.conditionHash = _conditionHash;
        // entangledSlots initializes as empty array
        newSlot.rewardAmount = 0;

        // Add slot ID to owner's list
        _ownerSlots[_ownerAddress].push(slotId);

        emit SlotCreated(slotId, _ownerAddress, _assetType, _assetAddress, _tokenId, _amount, _unlockTime, _conditionHash);
        emit StateChanged(slotId, SlotState(0), newSlot.state); // Emit state change from a dummy state to the initial one
    }

     /**
     * @dev Internal function to perform asset withdrawal from a slot.
     * Handles ETH, ERC20, ERC721 transfers.
     * Does NOT handle state checks or permissions.
     * @param _slotId The ID of the slot.
     * @param _recipient The address to send the assets to.
     */
    function _performWithdrawal(uint256 _slotId, address _recipient) internal {
         QuantumSlot storage slot = _slots[_slotId];

         // Store details before potential deletion/reset
         AssetType assetType = slot.assetType;
         address assetAddress = slot.assetAddress;
         uint256 tokenId = slot.tokenId;
         uint256 amount = slot.amount;

         require(amount > 0 || assetType == AssetType.ERC721, "No assets in slot"); // ERC721 amount is always 1

         // Reset slot asset info immediately to prevent double-withdrawal attempts
         slot.assetType = AssetType.ETH; // Reset to a default/invalid type
         slot.assetAddress = address(0);
         slot.tokenId = 0;
         slot.amount = 0;


         if (assetType == AssetType.ETH) {
             (bool success, ) = payable(_recipient).call{value: amount}("");
             require(success, "ETH transfer failed");
         } else if (assetType == AssetType.ERC20) {
             IERC20 token = IERC20(assetAddress);
             require(token.transfer(_recipient, amount), "ERC20 transfer failed");
         } else if (assetType == AssetType.ERC721) {
             IERC721 token = IERC721(assetAddress);
             token.safeTransferFrom(address(this), _recipient, tokenId); // Safe transfer handles ERC721Holder callback
         } else {
             revert("Unknown asset type");
         }

         emit AssetWithdrawn(_slotId, _recipient, assetType, assetAddress, tokenId, amount);
    }

    /**
     * @dev Internal function to mark a slot as voided and clean up owner's list.
     * @param _slotId The ID of the slot to void.
     */
    function _voidSlot(uint256 _slotId) internal {
         QuantumSlot storage slot = _slots[_slotId];
         require(slot.state != SlotState.Voided, "Slot already voided");

         // Remove from owner's list if it still has an owner
         if (slot.owner != address(0)) {
             uint256[] storage ownerSlots = _ownerSlots[slot.owner];
             for(uint i = 0; i < ownerSlots.length; i++) {
                 if (ownerSlots[i] == _slotId) {
                     ownerSlots[i] = ownerSlots[ownerSlots.length - 1];
                     ownerSlots.pop();
                     break;
                 }
             }
         }

         SlotState oldState = slot.state;
         slot.state = SlotState.Voided; // Mark as voided
         slot.owner = address(0); // Clear owner

         // Clear entanglement links (if any)
         for (uint i = 0; i < slot.entangledSlots.length; i++) {
             uint256 entangledSlotId = slot.entangledSlots[i];
             QuantumSlot storage entangledSlot = _slots[entangledSlotId];

             // Find and remove _slotId from entangledSlot's list
             for (uint j = 0; j < entangledSlot.entangledSlots.length; j++) {
                 if (entangledSlot.entangledSlots[j] == _slotId) {
                     entangledSlot.entangledSlots[j] = entangledSlot.entangledSlots[entangledSlot.entangledSlots.length - 1];
                     entangledSlot.entangledSlots.pop();
                     break;
                 }
             }
             // Note: Voiding doesn't necessarily change the *state* of the entangled slot here,
             // but attempting to interact with a slot entangled with a voided one might fail.
             // A more complex system could auto-decohere or penalize.
         }
         delete slot.entangledSlots; // Clear entanglement list for the voided slot


         // Clear staked status
         _isSlotStaked[_slotId] = false;
         // Rewards remain, but are now claimable by owner (via claimVoidedAsset if implemented) or lost.

         emit StateChanged(_slotId, oldState, SlotState.Voided);
         emit SlotVoided(_slotId);
    }


    // --- ERC721Holder and IERC1155Receiver callbacks ---
    // These are required interfaces to receive tokens.

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
        // This function is called by ERC721 tokens when they are transferred to this contract.
        // We've already called _createSlot in depositERC721 assuming success.
        // A more robust system might use this callback to trigger the _createSlot logic
        // after verifying the sender (`from`), operator, and token details.
        // For this example, we'll just return the required magic value.
        require(msg.sender == ERC721(data).address, "Called by non-ERC721 contract"); // Basic security check
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external override returns (bytes4) {
         // Basic implementation for ERC1155 support if added later.
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external override returns (bytes4) {
         // Basic implementation for ERC1155 support if added later.
        return this.onERC1155BatchReceived.selector;
    }

    // Fallback function to reject accidental calls
    fallback() external payable {
        revert("Fallback not allowed");
    }
}
```